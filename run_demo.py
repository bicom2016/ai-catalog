#!/usr/bin/env python3
"""
Demo script to classify a limited number of MRO products
"""

import psycopg2
from database_mro import MRODatabase
from batch_processor import BatchProcessor
import time

def run_demo(limit=50):
    """Run classification on limited products for demo"""
    print("\n" + "="*60)
    print("MRO CLASSIFICATION DEMO")
    print("="*60)
    
    # First, limit the pending products
    db = MRODatabase()
    if not db.connect():
        print("[ERROR] Failed to connect to database")
        return
    
    try:
        # Get current stats
        stats = db.get_classification_stats()
        print(f"\nCurrent Status:")
        print(f"  Total products: {stats.get('total', 0)}")
        print(f"  Already completed: {stats.get('completed', 0)}")
        print(f"  Pending: {stats.get('pending', 0)}")
        
        completed = stats.get('completed', 0)
        if completed >= limit:
            print(f"\n[INFO] Already classified {completed} products (limit: {limit})")
            print("[INFO] Demo complete!")
            return
        
        # Calculate how many more to process
        to_process = limit - completed
        print(f"\n[INFO] Will process {to_process} more products to reach {limit} total")
        
        # Mark products beyond limit as 'skipped' temporarily
        db.cursor.execute(f"""
            UPDATE mro_products 
            SET processing_status = 'skipped'
            WHERE processing_status = 'pending' 
            AND id > (
                SELECT MIN(id) + {to_process - 1}
                FROM (
                    SELECT id FROM mro_products 
                    WHERE processing_status = 'pending'
                    ORDER BY id
                    LIMIT {to_process}
                ) sub
            )
        """)
        db.conn.commit()
        
    finally:
        db.close()
    
    # Run batch processor
    print(f"\n[START] Processing {to_process} products...")
    processor = BatchProcessor(batch_size=5, delay_between_batches=1.0)
    results = processor.process_all_pending()
    
    # Restore skipped products back to pending
    db = MRODatabase()
    if db.connect():
        try:
            db.cursor.execute("""
                UPDATE mro_products 
                SET processing_status = 'pending'
                WHERE processing_status = 'skipped'
            """)
            db.conn.commit()
            
            # Get final stats
            final_stats = db.get_classification_stats()
            print("\n" + "="*60)
            print("DEMO RESULTS")
            print("="*60)
            print(f"Total products in database: {final_stats.get('total', 0)}")
            print(f"Successfully classified: {final_stats.get('completed', 0)}")
            print(f"Remaining to classify: {final_stats.get('pending', 0)}")
            print(f"Average confidence: {final_stats.get('avg_confidence', 0):.2%}")
            
            # Show sample classifications
            print("\n" + "="*60)
            print("SAMPLE CLASSIFICATIONS")
            print("="*60)
            
            db.cursor.execute("""
                SELECT 
                    product_name,
                    old_category,
                    new_category_name,
                    new_subcategory_name,
                    confidence_score
                FROM mro_products
                WHERE processing_status = 'completed'
                ORDER BY id DESC
                LIMIT 5
            """)
            
            samples = db.cursor.fetchall()
            for sample in samples:
                print(f"\nProduct: {sample['product_name'][:50]}")
                print(f"  Old Category: {sample['old_category']}")
                print(f"  New Category: {sample['new_category_name']}")
                print(f"  New Subcategory: {sample['new_subcategory_name']}")
                print(f"  Confidence: {sample['confidence_score']:.2%}")
            
        finally:
            db.close()
    
    print("\n[SUCCESS] Demo completed successfully!")
    print("\nTo classify ALL products, run:")
    print("  python classify_mro.py --classify")
    print("\nTo generate a full report, run:")
    print("  python classify_mro.py --report")

if __name__ == '__main__':
    # Run demo for 50 products
    run_demo(limit=50)