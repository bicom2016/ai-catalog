import psycopg2
import pandas as pd
from psycopg2.extras import RealDictCursor
from datetime import datetime
import os
from dotenv import load_dotenv
from typing import List, Dict, Optional

load_dotenv()

class MRODatabase:
    def __init__(self):
        self.database_url = os.getenv('DATABASE_URL')
        if not self.database_url:
            raise ValueError("DATABASE_URL not found in .env file")
        self.conn = None
        self.cursor = None
        
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = psycopg2.connect(self.database_url)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            print("[OK] Connected to PostgreSQL database")
            return True
        except Exception as e:
            print(f"[ERROR] Failed to connect to database: {e}")
            return False
    
    def create_tables(self):
        """Create MRO products and classifications table"""
        try:
            # Drop existing table if needed (for fresh start)
            self.cursor.execute("""
                DROP TABLE IF EXISTS mro_products CASCADE;
            """)
            
            # Create comprehensive MRO products table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS mro_products (
                    id SERIAL PRIMARY KEY,
                    -- Original data from CSV
                    product_name TEXT NOT NULL,
                    brand VARCHAR(255),
                    model VARCHAR(255),
                    original_category TEXT,
                    
                    -- Old classification (from existing categories in CSV)
                    old_department VARCHAR(255),
                    old_category VARCHAR(255),
                    old_subcategory VARCHAR(255),
                    
                    -- New AI classification
                    new_department_code VARCHAR(10),
                    new_department_name VARCHAR(255),
                    new_category_code VARCHAR(10),
                    new_category_name VARCHAR(255),
                    new_subcategory_code VARCHAR(10),
                    new_subcategory_name VARCHAR(255),
                    
                    -- Metadata
                    confidence_score FLOAT,
                    classification_timestamp TIMESTAMP,
                    batch_id INTEGER,
                    processing_status VARCHAR(50) DEFAULT 'pending',
                    error_message TEXT,
                    
                    -- Indexes for performance
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            
            # Create indexes for better query performance
            self.cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_product_name ON mro_products(product_name);
                CREATE INDEX IF NOT EXISTS idx_new_category ON mro_products(new_category_code);
                CREATE INDEX IF NOT EXISTS idx_new_subcategory ON mro_products(new_subcategory_code);
                CREATE INDEX IF NOT EXISTS idx_processing_status ON mro_products(processing_status);
                CREATE INDEX IF NOT EXISTS idx_batch_id ON mro_products(batch_id);
            """)
            
            self.conn.commit()
            print("[OK] Created mro_products table with all fields")
            return True
            
        except Exception as e:
            print(f"[ERROR] Failed to create tables: {e}")
            self.conn.rollback()
            return False
    
    def import_csv_data(self, csv_path: str) -> int:
        """Import MRO products from CSV file"""
        try:
            # Read CSV file
            df = pd.read_csv(csv_path, encoding='utf-8')
            print(f"[INFO] Read {len(df)} products from CSV")
            
            # Parse original category structure
            records_inserted = 0
            for _, row in df.iterrows():
                product = row.get('Produto', '')
                brand = row.get('Marca', '')
                model = row.get('Modelo', '')
                original_category = row.get('Categoria', '')
                
                # Parse old category structure (MRO: MATERIAL, REPARO E OPERAÇÃO > CATEGORY > SUBCATEGORY)
                old_parts = original_category.split(' > ') if original_category else []
                old_department = old_parts[0] if len(old_parts) > 0 else None
                old_category = old_parts[1] if len(old_parts) > 1 else None
                old_subcategory = old_parts[2] if len(old_parts) > 2 else None
                
                # Insert into database
                self.cursor.execute("""
                    INSERT INTO mro_products (
                        product_name, brand, model, original_category,
                        old_department, old_category, old_subcategory,
                        processing_status
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending')
                    """, (
                        product, brand, model, original_category,
                        old_department, old_category, old_subcategory
                    ))
                records_inserted += 1
                
            self.conn.commit()
            print(f"[OK] Imported {records_inserted} products to database")
            return records_inserted
            
        except Exception as e:
            print(f"[ERROR] Failed to import CSV: {e}")
            self.conn.rollback()
            return 0
    
    def get_pending_products(self, limit: int = None) -> List[Dict]:
        """Get products that haven't been classified yet"""
        try:
            query = """
                SELECT id, product_name, brand, model 
                FROM mro_products 
                WHERE processing_status = 'pending'
                ORDER BY id
            """
            if limit:
                query += f" LIMIT {limit}"
                
            self.cursor.execute(query)
            return self.cursor.fetchall()
            
        except Exception as e:
            print(f"[ERROR] Failed to get pending products: {e}")
            return []
    
    def update_classification(self, product_id: int, classification: Dict) -> bool:
        """Update product with new AI classification"""
        try:
            self.cursor.execute("""
                UPDATE mro_products SET
                    new_department_code = %s,
                    new_department_name = %s,
                    new_category_code = %s,
                    new_category_name = %s,
                    new_subcategory_code = %s,
                    new_subcategory_name = %s,
                    confidence_score = %s,
                    classification_timestamp = %s,
                    batch_id = %s,
                    processing_status = 'completed',
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                """, (
                    classification.get('dept_code'),
                    classification.get('dept_name'),
                    classification.get('cat_code'),
                    classification.get('cat_name'),
                    classification.get('sub_code'),
                    classification.get('sub_name'),
                    classification.get('confidence', 0.0),
                    datetime.now(),
                    classification.get('batch_id'),
                    product_id
                ))
            self.conn.commit()
            return True
            
        except Exception as e:
            print(f"[ERROR] Failed to update classification for product {product_id}: {e}")
            self.conn.rollback()
            return False
    
    def mark_as_error(self, product_id: int, error_message: str) -> bool:
        """Mark product as having an error during classification"""
        try:
            self.cursor.execute("""
                UPDATE mro_products SET
                    processing_status = 'error',
                    error_message = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                """, (error_message, product_id))
            self.conn.commit()
            return True
            
        except Exception as e:
            print(f"[ERROR] Failed to mark product {product_id} as error: {e}")
            self.conn.rollback()
            return False
    
    def get_classification_stats(self) -> Dict:
        """Get statistics about classification progress"""
        try:
            self.cursor.execute("""
                SELECT 
                    COUNT(*) as total,
                    COUNT(CASE WHEN processing_status = 'completed' THEN 1 END) as completed,
                    COUNT(CASE WHEN processing_status = 'pending' THEN 1 END) as pending,
                    COUNT(CASE WHEN processing_status = 'error' THEN 1 END) as errors,
                    AVG(CASE WHEN confidence_score IS NOT NULL THEN confidence_score END) as avg_confidence
                FROM mro_products
            """)
            return dict(self.cursor.fetchone())
            
        except Exception as e:
            print(f"[ERROR] Failed to get stats: {e}")
            return {}
    
    def get_category_comparison(self) -> pd.DataFrame:
        """Get comparison between old and new categories"""
        try:
            query = """
                SELECT 
                    product_name,
                    old_category,
                    old_subcategory,
                    new_category_name,
                    new_subcategory_name,
                    confidence_score
                FROM mro_products
                WHERE processing_status = 'completed'
                ORDER BY confidence_score DESC
            """
            return pd.read_sql(query, self.conn)
            
        except Exception as e:
            print(f"[ERROR] Failed to get comparison: {e}")
            return pd.DataFrame()
    
    def close(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("[INFO] Database connection closed")