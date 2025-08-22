#!/usr/bin/env python3
"""
Normalize products by subcategory with prompt caching and dictionary building
Creates reusable normalization patterns for future use
"""

import anthropic
import json
import time
import os
import re
from datetime import datetime
from typing import Dict, List, Optional
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

load_dotenv()

class SubcategoryNormalizer:
    def __init__(self):
        # Initialize Claude client
        api_key = os.getenv('CLAUDE_API_KEY')
        if not api_key:
            raise ValueError("CLAUDE_API_KEY not found in .env file")
        
        self.client = anthropic.Anthropic(api_key=api_key)
        
        # Initialize database
        self.database_url = os.getenv('DATABASE_URL')
        if not self.database_url:
            raise ValueError("DATABASE_URL not found in .env file")
        
        self.conn = None
        self.cursor = None
        self.connect_db()
        
        # Create dictionary tables if they don't exist
        self.setup_dictionary_tables()
        
        # Cache for normalization patterns
        self.local_cache = {}
        self.cache_stats = {
            'api_calls': 0,
            'cache_hits': 0,
            'dictionary_hits': 0,
            'tokens_cached': 0,
            'tokens_saved': 0,
            'patterns_learned': 0
        }
    
    def connect_db(self):
        """Connect to PostgreSQL database"""
        try:
            self.conn = psycopg2.connect(self.database_url)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            print("[OK] Connected to database")
            return True
        except Exception as e:
            print(f"[ERROR] Database connection failed: {e}")
            return False
    
    def setup_dictionary_tables(self):
        """Create dictionary tables for storing normalization patterns"""
        try:
            # Create normalization dictionary table
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS normalization_dictionary (
                    id SERIAL PRIMARY KEY,
                    subcategory_code VARCHAR(10),
                    original_pattern TEXT,
                    normalized_form TEXT,
                    pattern_type VARCHAR(50) DEFAULT 'exact',
                    confidence FLOAT DEFAULT 1.0,
                    usage_count INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    source VARCHAR(50) DEFAULT 'claude',
                    UNIQUE(subcategory_code, original_pattern)
                );
                
                CREATE INDEX IF NOT EXISTS idx_dict_subcategory 
                ON normalization_dictionary(subcategory_code);
                
                CREATE INDEX IF NOT EXISTS idx_dict_pattern 
                ON normalization_dictionary(original_pattern);
            """)
            
            # Create cache table for prompt contexts
            self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS normalization_cache (
                    id SERIAL PRIMARY KEY,
                    subcategory_code VARCHAR(10) UNIQUE,
                    cached_context TEXT,
                    example_products TEXT,
                    token_count INTEGER,
                    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            
            self.conn.commit()
            print("[OK] Dictionary tables ready")
            
        except Exception as e:
            print(f"[ERROR] Failed to create dictionary tables: {e}")
            self.conn.rollback()
    
    def get_products_by_subcategory(self) -> Dict[str, List]:
        """Group all completed products by subcategory"""
        try:
            self.cursor.execute("""
                SELECT 
                    new_subcategory_code as subcategory,
                    new_subcategory_name as subcategory_name,
                    COUNT(*) as product_count,
                    array_agg(
                        json_build_object(
                            'id', id,
                            'product_name', product_name,
                            'brand', brand,
                            'model', model
                        )
                    ) as products
                FROM mro_products
                WHERE processing_status = 'completed'
                    AND new_subcategory_code IS NOT NULL
                GROUP BY new_subcategory_code, new_subcategory_name
                ORDER BY product_count DESC
            """)
            
            results = {}
            for row in self.cursor.fetchall():
                results[row['subcategory']] = {
                    'name': row['subcategory_name'],
                    'count': row['product_count'],
                    'products': row['products']
                }
            
            return results
            
        except Exception as e:
            print(f"[ERROR] Failed to get products by subcategory: {e}")
            return {}
    
    def check_dictionary(self, product_name: str, subcategory: str) -> Optional[str]:
        """Check if product exists in dictionary"""
        try:
            # First check local cache
            cache_key = f"{subcategory}:{product_name}"
            if cache_key in self.local_cache:
                self.cache_stats['cache_hits'] += 1
                return self.local_cache[cache_key]
            
            # Check database dictionary
            self.cursor.execute("""
                SELECT normalized_form, confidence
                FROM normalization_dictionary
                WHERE subcategory_code = %s 
                    AND original_pattern = %s
                ORDER BY confidence DESC
                LIMIT 1
            """, (subcategory, product_name))
            
            result = self.cursor.fetchone()
            if result:
                # Update usage count
                self.cursor.execute("""
                    UPDATE normalization_dictionary
                    SET usage_count = usage_count + 1,
                        last_used = CURRENT_TIMESTAMP
                    WHERE subcategory_code = %s AND original_pattern = %s
                """, (subcategory, product_name))
                self.conn.commit()
                
                # Cache locally
                self.local_cache[cache_key] = result['normalized_form']
                self.cache_stats['dictionary_hits'] += 1
                
                return result['normalized_form']
            
            return None
            
        except Exception as e:
            print(f"[ERROR] Dictionary lookup failed: {e}")
            return None
    
    def save_to_dictionary(self, subcategory: str, patterns: List[Dict]):
        """Save normalization patterns to dictionary"""
        try:
            for pattern in patterns:
                self.cursor.execute("""
                    INSERT INTO normalization_dictionary 
                    (subcategory_code, original_pattern, normalized_form, confidence, source)
                    VALUES (%s, %s, %s, %s, 'claude')
                    ON CONFLICT (subcategory_code, original_pattern) 
                    DO UPDATE SET
                        normalized_form = EXCLUDED.normalized_form,
                        confidence = EXCLUDED.confidence,
                        usage_count = normalization_dictionary.usage_count + 1,
                        last_used = CURRENT_TIMESTAMP
                """, (
                    subcategory,
                    pattern['original'],
                    pattern['normalized'],
                    pattern.get('confidence', 0.95)
                ))
                
                # Update local cache
                cache_key = f"{subcategory}:{pattern['original']}"
                self.local_cache[cache_key] = pattern['normalized']
            
            self.conn.commit()
            self.cache_stats['patterns_learned'] += len(patterns)
            print(f"  [OK] Saved {len(patterns)} patterns to dictionary")
            
        except Exception as e:
            print(f"  [ERROR] Failed to save patterns: {e}")
            self.conn.rollback()
    
    def normalize_subcategory_batch(self, subcategory: str, products: List[Dict]) -> List[Dict]:
        """Normalize all products in a subcategory using prompt caching"""
        
        print(f"\n[NORMALIZE] Processing subcategory {subcategory}")
        print(f"  Products to normalize: {len(products)}")
        
        # Check dictionary first
        normalized_results = []
        products_needing_api = []
        
        for product in products:
            product_name = product['product_name']
            
            # Check if already in dictionary
            normalized = self.check_dictionary(product_name, subcategory)
            if normalized:
                normalized_results.append({
                    'id': product['id'],
                    'original': product_name,
                    'normalized': normalized,
                    'source': 'dictionary'
                })
            else:
                products_needing_api.append(product)
        
        print(f"  Dictionary hits: {len(normalized_results)}")
        print(f"  Need API normalization: {len(products_needing_api)}")
        
        # Process remaining products with API
        if products_needing_api:
            api_results = self.normalize_with_claude_cache(subcategory, products_needing_api)
            normalized_results.extend(api_results)
        
        return normalized_results
    
    def normalize_with_claude_cache(self, subcategory: str, products: List[Dict]) -> List[Dict]:
        """Normalize products using Claude with prompt caching"""
        
        # Build context with all products for better pattern recognition
        product_list = "\n".join([
            f"{i+1}. {p['product_name']}" + 
            (f" (Brand: {p['brand']})" if p.get('brand') else "")
            for i, p in enumerate(products)
        ])
        
        # Get existing patterns from dictionary for context
        self.cursor.execute("""
            SELECT DISTINCT normalized_form
            FROM normalization_dictionary
            WHERE subcategory_code = %s
            ORDER BY usage_count DESC
            LIMIT 10
        """, (subcategory,))
        
        existing_patterns = [row['normalized_form'] for row in self.cursor.fetchall()]
        patterns_context = "\n".join(existing_patterns) if existing_patterns else "No existing patterns"
        
        start_time = time.time()
        
        try:
            # Create message with caching
            message = self.client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=2000,
                temperature=0.1,
                system=[
                    {
                        "type": "text",
                        "text": f"""You are a product normalization expert for MRO (Maintenance, Repair, Operations) products.
                        
Subcategory: {subcategory}

Existing normalized patterns in this subcategory:
{patterns_context}

Your task is to normalize product names by:
1. Standardizing units (mm, cm, m, pol, etc.)
2. Fixing typos and abbreviations
3. Removing redundant information
4. Maintaining consistent format
5. Preserving essential technical specifications

Focus on creating consistent, reusable patterns.""",
                        "cache_control": {"type": "ephemeral"}
                    }
                ],
                messages=[
                    {
                        "role": "user",
                        "content": f"""Normalize these product names. Group duplicates together.

Products:
{product_list}

Return JSON with:
1. Normalized names
2. Duplicate groups (products that are essentially the same)
3. Confidence scores

Format:
{{
  "normalizations": [
    {{
      "product_number": 1,
      "original": "original name",
      "normalized": "normalized name",
      "duplicate_group": 1,
      "confidence": 0.95
    }}
  ],
  "patterns_discovered": [
    {{
      "pattern": "DISJUNTOR MOTOR*",
      "normalized_form": "Disjuntor Motor"
    }}
  ]
}}"""
                    }
                ],
                extra_headers={"anthropic-beta": "prompt-caching-2024-07-31"}
            )
            
            elapsed_time = time.time() - start_time
            self.cache_stats['api_calls'] += 1
            
            # Parse response
            response_text = message.content[0].text
            json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
            
            if json_match:
                result_data = json.loads(json_match.group())
                normalizations = result_data.get('normalizations', [])
                patterns = result_data.get('patterns_discovered', [])
                
                # Process normalizations
                results = []
                patterns_to_save = []
                
                for norm in normalizations:
                    product_idx = norm.get('product_number', 1) - 1
                    if product_idx < len(products):
                        product = products[product_idx]
                        
                        results.append({
                            'id': product['id'],
                            'original': product['product_name'],
                            'normalized': norm.get('normalized', product['product_name']),
                            'duplicate_group': norm.get('duplicate_group'),
                            'confidence': norm.get('confidence', 0.9),
                            'source': 'api'
                        })
                        
                        # Prepare pattern for dictionary
                        patterns_to_save.append({
                            'original': product['product_name'],
                            'normalized': norm.get('normalized', product['product_name']),
                            'confidence': norm.get('confidence', 0.9)
                        })
                
                # Save patterns to dictionary
                if patterns_to_save:
                    self.save_to_dictionary(subcategory, patterns_to_save)
                
                # Update cache statistics
                if hasattr(message.usage, 'cache_read_input_tokens'):
                    cache_read = message.usage.cache_read_input_tokens
                    self.cache_stats['tokens_saved'] += cache_read
                    
                    total_input = message.usage.input_tokens
                    cache_percentage = (cache_read / total_input * 100) if total_input else 0
                    print(f"  [CACHE] {cache_percentage:.1f}% of tokens from cache")
                
                print(f"  [OK] Normalized {len(results)} products in {elapsed_time:.2f}s")
                
                return results
            
            return []
            
        except Exception as e:
            print(f"  [ERROR] API normalization failed: {e}")
            return []
    
    def update_mro_products(self, normalizations: List[Dict]):
        """Update MRO products table with normalized names"""
        try:
            for norm in normalizations:
                self.cursor.execute("""
                    UPDATE mro_products
                    SET normalized_name = %s,
                        duplicate_group_id = %s,
                        normalization_confidence = %s,
                        normalized_at = CURRENT_TIMESTAMP
                    WHERE id = %s
                """, (
                    norm['normalized'],
                    norm.get('duplicate_group'),
                    norm.get('confidence', 0.9),
                    norm['id']
                ))
            
            self.conn.commit()
            print(f"  [OK] Updated {len(normalizations)} products in database")
            
        except Exception as e:
            print(f"  [ERROR] Failed to update products: {e}")
            self.conn.rollback()
    
    def print_statistics(self):
        """Print normalization statistics"""
        print("\n" + "="*70)
        print("NORMALIZATION STATISTICS")
        print("="*70)
        print(f"API Calls: {self.cache_stats['api_calls']}")
        print(f"Dictionary Hits: {self.cache_stats['dictionary_hits']}")
        print(f"Local Cache Hits: {self.cache_stats['cache_hits']}")
        print(f"Patterns Learned: {self.cache_stats['patterns_learned']}")
        print(f"Tokens Saved by Caching: {self.cache_stats['tokens_saved']:,}")
        
        # Calculate efficiency
        total_lookups = (
            self.cache_stats['dictionary_hits'] + 
            self.cache_stats['cache_hits'] + 
            self.cache_stats['api_calls']
        )
        
        if total_lookups > 0:
            cache_efficiency = (
                (self.cache_stats['dictionary_hits'] + self.cache_stats['cache_hits']) 
                / total_lookups * 100
            )
            print(f"Cache Efficiency: {cache_efficiency:.1f}%")
        
        # Show dictionary size
        self.cursor.execute("SELECT COUNT(*) as total FROM normalization_dictionary")
        dict_size = self.cursor.fetchone()['total']
        print(f"Dictionary Size: {dict_size} patterns")
    
    def run_normalization(self):
        """Main normalization process"""
        print("\n" + "="*70)
        print("SUBCATEGORY-BASED NORMALIZATION WITH CACHING")
        print("="*70)
        
        # Get products grouped by subcategory
        subcategories = self.get_products_by_subcategory()
        
        if not subcategories:
            print("[INFO] No classified products found for normalization")
            return
        
        print(f"\nFound {len(subcategories)} subcategories to process")
        
        total_products = sum(s['count'] for s in subcategories.values())
        print(f"Total products to normalize: {total_products}")
        
        # Add normalized_name column if it doesn't exist
        try:
            self.cursor.execute("""
                ALTER TABLE mro_products 
                ADD COLUMN IF NOT EXISTS normalized_name TEXT,
                ADD COLUMN IF NOT EXISTS duplicate_group_id INTEGER,
                ADD COLUMN IF NOT EXISTS normalization_confidence FLOAT,
                ADD COLUMN IF NOT EXISTS normalized_at TIMESTAMP
            """)
            self.conn.commit()
        except:
            self.conn.rollback()
        
        # Process each subcategory
        start_time = time.time()
        processed_count = 0
        
        for subcategory_code, subcategory_data in subcategories.items():
            products = subcategory_data['products']
            
            # Normalize this subcategory
            normalizations = self.normalize_subcategory_batch(subcategory_code, products)
            
            # Update database
            if normalizations:
                self.update_mro_products(normalizations)
            
            processed_count += len(products)
            print(f"  Progress: {processed_count}/{total_products} products")
            
            # Small delay between subcategories
            time.sleep(0.5)
        
        elapsed_time = time.time() - start_time
        
        # Print final statistics
        self.print_statistics()
        
        print(f"\nTotal time: {elapsed_time:.2f} seconds")
        print(f"Average time per product: {elapsed_time/total_products:.3f} seconds")
        
        print("\n[SUCCESS] Normalization complete!")

def main():
    """Main entry point"""
    print("\n[START] Starting Subcategory-Based Normalization")
    print("This will normalize product names using learned patterns and caching")
    
    # Confirm before proceeding
    response = input("\nProceed with normalization? (yes/no): ")
    if response.lower() != 'yes':
        print("Normalization cancelled")
        return
    
    # Run normalization
    normalizer = SubcategoryNormalizer()
    normalizer.run_normalization()
    
    print("\n[SUCCESS] Process complete!")
    print("\nNext steps:")
    print("1. View results in dashboard: python -m streamlit run streamlit_app.py")
    print("2. Export dictionary: python export_dictionary.py")
    print("3. Test on new products: python test_normalization.py")

if __name__ == '__main__':
    main()