"""
PostgreSQL Database Manager with Integrated Dictionary Storage
Handles product classification, duplicate detection, and hash key management
"""

import psycopg2
from psycopg2.extras import RealDictCursor, Json
import os
from datetime import datetime
from typing import List, Dict, Optional, Tuple
import uuid
from dotenv import load_dotenv

load_dotenv()

class DatabaseManager:
    def __init__(self):
        self.conn = None
        self.connect()
        self.create_tables()
    
    def connect(self):
        """Establish PostgreSQL connection using Railway DATABASE_URL"""
        try:
            self.conn = psycopg2.connect(os.getenv("DATABASE_URL"))
            print("✅ Connected to PostgreSQL on Railway")
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            raise
    
    def create_tables(self):
        """Create all necessary tables including dictionary storage"""
        with self.conn.cursor() as cur:
            # Main products table with enhanced schema
            cur.execute("""
                CREATE TABLE IF NOT EXISTS products_enhanced (
                    id SERIAL PRIMARY KEY,
                    
                    -- Original data
                    original_name TEXT NOT NULL,
                    
                    -- GPT-5 Classification Results
                    normalized_name TEXT,
                    category_code VARCHAR(3),
                    category_name TEXT,
                    subcategory_code VARCHAR(4),
                    subcategory_name TEXT,
                    
                    -- Duplicate Detection
                    duplicate_group_id INTEGER,
                    is_master BOOLEAN DEFAULT FALSE,
                    similarity_score FLOAT,
                    duplicate_count INTEGER DEFAULT 1,
                    
                    -- Quality Metrics
                    classification_confidence FLOAT,
                    needs_review BOOLEAN DEFAULT FALSE,
                    review_notes TEXT,
                    gpt5_reasoning TEXT,
                    
                    -- Metadata
                    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    processing_model VARCHAR(50) DEFAULT 'gpt-5-high-reasoning',
                    processing_batch_id UUID,
                    batch_position INTEGER
                )
            """)
            
            # Dictionary storage for duplicate detection (PostgreSQL integrated)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS duplicate_dictionary (
                    hash_key VARCHAR(255) PRIMARY KEY,
                    duplicate_group_id INTEGER NOT NULL,
                    key_type VARCHAR(20) NOT NULL, -- exact, alpha, sorted, core, dim, phon
                    confidence_weight FLOAT NOT NULL,
                    master_product_id INTEGER REFERENCES products_enhanced(id),
                    normalized_form TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    hit_count INTEGER DEFAULT 0
                )
            """)
            
            # Index for faster lookups
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_duplicate_group 
                ON duplicate_dictionary(duplicate_group_id)
            """)
            
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_key_type 
                ON duplicate_dictionary(key_type)
            """)
            
            # Duplicate groups summary
            cur.execute("""
                CREATE TABLE IF NOT EXISTS duplicate_groups (
                    group_id SERIAL PRIMARY KEY,
                    master_product_id INTEGER REFERENCES products_enhanced(id),
                    normalized_master_name TEXT,
                    product_count INTEGER DEFAULT 1,
                    variations JSONB, -- Store all variations as JSON
                    confidence_avg FLOAT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Processing statistics
            cur.execute("""
                CREATE TABLE IF NOT EXISTS processing_stats (
                    batch_id UUID PRIMARY KEY,
                    batch_number INTEGER,
                    total_products INTEGER,
                    new_products INTEGER,
                    duplicates_found INTEGER,
                    low_confidence_count INTEGER,
                    processing_time_seconds FLOAT,
                    api_tokens_used INTEGER,
                    gpt5_cost_estimate FLOAT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Hash key generation log (for debugging and optimization)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS hash_key_log (
                    id SERIAL PRIMARY KEY,
                    product_id INTEGER REFERENCES products_enhanced(id),
                    original_name TEXT,
                    normalized_name TEXT,
                    hash_keys JSONB, -- All 6 keys with their types
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            self.conn.commit()
            print("✅ Database tables created successfully")
    
    def check_duplicate_by_keys(self, hash_keys: Dict[str, str], 
                               key_weights: Dict[str, float]) -> Optional[Tuple[int, float]]:
        """
        Check if product exists using hash keys
        Returns: (duplicate_group_id, confidence_score) or None
        """
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            best_match = None
            best_score = 0.0
            
            for key_type, hash_key in hash_keys.items():
                cur.execute("""
                    SELECT duplicate_group_id, confidence_weight
                    FROM duplicate_dictionary
                    WHERE hash_key = %s AND key_type = %s
                """, (hash_key, key_type))
                
                result = cur.fetchone()
                if result:
                    score = key_weights.get(key_type, 0.5)
                    if score > best_score:
                        best_score = score
                        best_match = result['duplicate_group_id']
                    
                    # Update hit count for analytics
                    cur.execute("""
                        UPDATE duplicate_dictionary 
                        SET hit_count = hit_count + 1 
                        WHERE hash_key = %s
                    """, (hash_key,))
            
            if best_match and best_score >= 0.85:  # Duplicate threshold
                return (best_match, best_score)
            return None
    
    def register_product_keys(self, product_id: int, hash_keys: Dict[str, str], 
                            duplicate_group_id: int, key_weights: Dict[str, float]):
        """Register all hash keys for a product in the dictionary"""
        with self.conn.cursor() as cur:
            for key_type, hash_key in hash_keys.items():
                cur.execute("""
                    INSERT INTO duplicate_dictionary 
                    (hash_key, duplicate_group_id, key_type, confidence_weight, master_product_id)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (hash_key) DO UPDATE
                    SET hit_count = duplicate_dictionary.hit_count + 1
                """, (hash_key, duplicate_group_id, key_type, 
                     key_weights.get(key_type, 0.5), product_id))
            
            # Log hash keys for debugging
            cur.execute("""
                INSERT INTO hash_key_log (product_id, hash_keys)
                VALUES (%s, %s)
            """, (product_id, Json(hash_keys)))
            
            self.conn.commit()
    
    def save_product(self, product_data: Dict, batch_id: uuid.UUID, position: int) -> int:
        """Save a single product and return its ID"""
        with self.conn.cursor() as cur:
            cur.execute("""
                INSERT INTO products_enhanced (
                    original_name, normalized_name, category_code, category_name,
                    subcategory_code, subcategory_name, duplicate_group_id,
                    is_master, similarity_score, classification_confidence,
                    needs_review, gpt5_reasoning, processing_batch_id, batch_position
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                ) RETURNING id
            """, (
                product_data['original_name'],
                product_data['normalized_name'],
                product_data.get('category_code'),
                product_data.get('category_name'),
                product_data.get('subcategory_code'),
                product_data.get('subcategory_name'),
                product_data.get('duplicate_group_id'),
                product_data.get('is_master', False),
                product_data.get('similarity_score', 1.0),
                product_data.get('confidence', 0.0),
                product_data.get('confidence', 0.0) < 0.8,  # needs_review if confidence < 0.8
                product_data.get('reasoning'),
                str(batch_id),
                position
            ))
            
            product_id = cur.fetchone()[0]
            self.conn.commit()
            return product_id
    
    def update_duplicate_group(self, group_id: int, master_id: int, 
                             master_name: str, variations: List[str]):
        """Update or create duplicate group summary"""
        with self.conn.cursor() as cur:
            cur.execute("""
                INSERT INTO duplicate_groups 
                (group_id, master_product_id, normalized_master_name, product_count, variations)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (group_id) DO UPDATE
                SET product_count = duplicate_groups.product_count + 1,
                    variations = %s,
                    updated_at = CURRENT_TIMESTAMP
            """, (group_id, master_id, master_name, len(variations), 
                 Json(variations), Json(variations)))
            
            self.conn.commit()
    
    def save_batch_stats(self, batch_id: uuid.UUID, stats: Dict):
        """Save processing statistics for a batch"""
        with self.conn.cursor() as cur:
            cur.execute("""
                INSERT INTO processing_stats (
                    batch_id, batch_number, total_products, new_products,
                    duplicates_found, low_confidence_count, processing_time_seconds,
                    api_tokens_used, gpt5_cost_estimate
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                str(batch_id),
                stats['batch_number'],
                stats['total_products'],
                stats['new_products'],
                stats['duplicates_found'],
                stats['low_confidence_count'],
                stats['processing_time'],
                stats['api_tokens'],
                stats['cost_estimate']
            ))
            
            self.conn.commit()
    
    def get_next_group_id(self) -> int:
        """Get the next available duplicate group ID"""
        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT COALESCE(MAX(duplicate_group_id), 0) + 1 
                FROM products_enhanced
            """)
            return cur.fetchone()[0]
    
    def get_processing_summary(self) -> Dict:
        """Get overall processing statistics"""
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            # Overall stats
            cur.execute("""
                SELECT 
                    COUNT(*) as total_products,
                    COUNT(DISTINCT duplicate_group_id) as unique_products,
                    COUNT(CASE WHEN is_master THEN 1 END) as master_products,
                    COUNT(CASE WHEN needs_review THEN 1 END) as needs_review,
                    AVG(classification_confidence) as avg_confidence,
                    COUNT(DISTINCT processing_batch_id) as total_batches
                FROM products_enhanced
            """)
            overall = cur.fetchone()
            
            # Duplicate statistics
            cur.execute("""
                SELECT 
                    AVG(product_count) as avg_duplicates_per_group,
                    MAX(product_count) as max_duplicates_in_group,
                    COUNT(*) as total_duplicate_groups
                FROM duplicate_groups
                WHERE product_count > 1
            """)
            duplicates = cur.fetchone()
            
            # Category distribution
            cur.execute("""
                SELECT 
                    category_name, 
                    COUNT(*) as product_count,
                    AVG(classification_confidence) as avg_confidence
                FROM products_enhanced
                WHERE category_name IS NOT NULL
                GROUP BY category_name
                ORDER BY product_count DESC
                LIMIT 10
            """)
            categories = cur.fetchall()
            
            return {
                'overall': overall,
                'duplicates': duplicates,
                'top_categories': categories
            }
    
    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
            print("Database connection closed")

# Configuration for duplicate detection
DUPLICATE_DETECTION_CONFIG = {
    # Number of hash keys per product
    "max_keys_per_product": 6,  # Balance between accuracy and memory
    
    # Fuzzy matching threshold
    "duplicate_threshold": 0.85,  # 85% confidence = duplicate
    
    # Key type weights (importance)
    "key_weights": {
        "exact": 1.0,   # Perfect match
        "alpha": 0.95,  # No spaces/special chars
        "sorted": 0.90, # Word order variation
        "core": 0.85,   # Core product features
        "dim": 0.85,    # Dimension patterns
        "phon": 0.75    # Typo resistance
    },
    
    # Batch configuration
    "batch_size": 10,  # Optimal for GPT-5 with detailed reasoning
    "max_retries": 3,
    "retry_delay": 2  # seconds
}