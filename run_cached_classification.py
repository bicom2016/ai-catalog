#!/usr/bin/env python3
"""
Run MRO Classification with Prompt Caching
Optimized for the remaining 320 products
"""

import sys
import time
from datetime import datetime
from database_mro import MRODatabase
from mro_classifier_cached import CachedMROClassifier

def run_cached_classification():
    """Run classification with prompt caching"""
    
    print("\n" + "="*70)
    print("MRO CLASSIFICATION WITH PROMPT CACHING")
    print("="*70)
    
    # Initialize components
    db = MRODatabase()
    classifier = CachedMROClassifier()
    
    if not db.connect():
        print("[ERROR] Failed to connect to database")
        return False
    
    try:
        # Get current statistics
        stats = db.get_classification_stats()
        print(f"\nCurrent Database Status:")
        print(f"  Total products: {stats.get('total', 0)}")
        print(f"  Completed: {stats.get('completed', 0)}")
        print(f"  Pending: {stats.get('pending', 0)}")
        print(f"  Errors: {stats.get('errors', 0)}")
        
        # Get pending products
        pending_products = db.get_pending_products()
        
        if not pending_products:
            print("\n[INFO] No pending products to classify")
            return True
        
        print(f"\n[INFO] Found {len(pending_products)} pending products")
        
        # Start classification with caching
        start_time = time.time()
        
        # Use larger batches for better caching efficiency
        batch_size = 20  # Process 20 products at once
        
        print(f"\n[INFO] Starting classification with batch size: {batch_size}")
        print("[INFO] Using prompt caching for efficiency")
        
        # Classify all pending products
        results = classifier.classify_batch_with_cache(
            pending_products,
            batch_size=batch_size
        )
        
        # Update database with results
        print(f"\n[INFO] Updating database with {len(results)} results...")
        
        successful = 0
        failed = 0
        
        for result in results:
            product_id = result['id']
            
            if 'error' in result:
                db.mark_as_error(product_id, result['error'])
                failed += 1
            else:
                success = db.update_classification(product_id, result)
                if success:
                    successful += 1
                else:
                    failed += 1
        
        elapsed_time = time.time() - start_time
        
        # Print final summary
        print("\n" + "="*70)
        print("CLASSIFICATION COMPLETE")
        print("="*70)
        print(f"Products processed: {len(results)}")
        print(f"Successful: {successful}")
        print(f"Failed: {failed}")
        print(f"Total time: {elapsed_time:.2f} seconds")
        print(f"Average time per product: {elapsed_time/len(results):.2f} seconds")
        
        # Get updated statistics
        final_stats = db.get_classification_stats()
        print(f"\nFinal Database Status:")
        print(f"  Total products: {final_stats.get('total', 0)}")
        print(f"  Completed: {final_stats.get('completed', 0)}")
        print(f"  Pending: {final_stats.get('pending', 0)}")
        print(f"  Average confidence: {final_stats.get('avg_confidence', 0):.2%}")
        
        return True
        
    except Exception as e:
        print(f"\n[ERROR] Classification failed: {e}")
        return False
        
    finally:
        db.close()

def main():
    """Main entry point"""
    print("\n[START] Starting MRO Classification with Prompt Caching")
    print("This will classify all remaining products efficiently using Claude's cache")
    
    # Confirm before proceeding
    response = input("\nProceed with classification? (yes/no): ")
    if response.lower() != 'yes':
        print("Classification cancelled")
        return
    
    # Run classification
    success = run_cached_classification()
    
    if success:
        print("\n[SUCCESS] Classification completed successfully!")
        print("\nNext steps:")
        print("1. Run normalization by subcategory: python normalize_subcategories.py")
        print("2. View results in dashboard: python -m streamlit run streamlit_app.py")
        print("3. Generate report: python classify_mro.py --report")
    else:
        print("\n[ERROR] Classification failed. Check logs for details.")

if __name__ == '__main__':
    main()