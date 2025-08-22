import time
from typing import List, Dict
from datetime import datetime
from database_mro import MRODatabase
from mro_classifier import MROClassifier

class BatchProcessor:
    def __init__(self, batch_size: int = 10, delay_between_batches: float = 2.0):
        """
        Initialize batch processor
        
        Args:
            batch_size: Number of products to process in each batch
            delay_between_batches: Seconds to wait between batches (for API rate limiting)
        """
        self.batch_size = batch_size
        self.delay_between_batches = delay_between_batches
        self.db = MRODatabase()
        self.classifier = MROClassifier()
        self.current_batch_id = int(datetime.now().timestamp())
        
    def process_all_pending(self) -> Dict:
        """Process all pending products in batches"""
        if not self.db.connect():
            return {"error": "Failed to connect to database"}
        
        stats = {
            'total_processed': 0,
            'successful': 0,
            'failed': 0,
            'batches_processed': 0,
            'start_time': datetime.now()
        }
        
        try:
            # Get initial statistics
            db_stats = self.db.get_classification_stats()
            print(f"\n[STATS] Database Statistics:")
            print(f"   Total products: {db_stats.get('total', 0)}")
            print(f"   Pending: {db_stats.get('pending', 0)}")
            print(f"   Completed: {db_stats.get('completed', 0)}")
            print(f"   Errors: {db_stats.get('errors', 0)}")
            
            # Process in batches
            while True:
                # Get next batch of pending products
                pending_products = self.db.get_pending_products(limit=self.batch_size)
                
                if not pending_products:
                    print("\n[OK] No more pending products to process")
                    break
                
                print(f"\n[BATCH] Processing batch {stats['batches_processed'] + 1} ({len(pending_products)} products)...")
                
                # Process each product in the batch
                for product in pending_products:
                    product_id = product['id']
                    product_name = product['product_name']
                    
                    print(f"   Processing: {product_name[:60]}...")
                    
                    # Classify the product
                    classification = self.classifier.classify_product(
                        product_name, 
                        batch_id=self.current_batch_id
                    )
                    
                    # Update database with classification
                    if 'error' in classification:
                        self.db.mark_as_error(product_id, classification['error'])
                        stats['failed'] += 1
                        print(f"      [ERROR] {classification['error']}")
                    else:
                        success = self.db.update_classification(product_id, classification)
                        if success:
                            stats['successful'] += 1
                            print(f"      [OK] Classified: {classification['cat_code']} > {classification['sub_code']}")
                        else:
                            stats['failed'] += 1
                            print(f"      [ERROR] Failed to update database")
                    
                    stats['total_processed'] += 1
                    
                    # Small delay between products to avoid overwhelming API
                    time.sleep(0.5)
                
                stats['batches_processed'] += 1
                self.current_batch_id += 1
                
                # Progress update
                print(f"\n[PROGRESS] {stats['total_processed']} products processed")
                print(f"   Successful: {stats['successful']}")
                print(f"   Failed: {stats['failed']}")
                
                # Delay between batches
                if pending_products and len(pending_products) == self.batch_size:
                    print(f"[WAIT] Waiting {self.delay_between_batches}s before next batch...")
                    time.sleep(self.delay_between_batches)
            
            # Final statistics
            stats['end_time'] = datetime.now()
            stats['duration'] = (stats['end_time'] - stats['start_time']).total_seconds()
            
            print("\n" + "="*60)
            print("[COMPLETED] BATCH PROCESSING COMPLETED")
            print("="*60)
            print(f"Total products processed: {stats['total_processed']}")
            print(f"Successful classifications: {stats['successful']}")
            print(f"Failed classifications: {stats['failed']}")
            print(f"Batches processed: {stats['batches_processed']}")
            print(f"Total time: {stats['duration']:.2f} seconds")
            print(f"Average time per product: {stats['duration']/max(stats['total_processed'], 1):.2f} seconds")
            
            # Get final database statistics
            final_stats = self.db.get_classification_stats()
            if final_stats.get('avg_confidence'):
                print(f"Average confidence score: {final_stats['avg_confidence']:.2f}")
            
            return stats
            
        except Exception as e:
            print(f"[ERROR] Batch processing error: {e}")
            return {**stats, 'error': str(e)}
        
        finally:
            self.db.close()
    
    def process_specific_products(self, product_ids: List[int]) -> Dict:
        """Process specific products by their IDs"""
        if not self.db.connect():
            return {"error": "Failed to connect to database"}
        
        stats = {
            'total_processed': 0,
            'successful': 0,
            'failed': 0
        }
        
        try:
            for product_id in product_ids:
                # Get product details
                self.db.cursor.execute(
                    "SELECT * FROM mro_products WHERE id = %s",
                    (product_id,)
                )
                product = self.db.cursor.fetchone()
                
                if not product:
                    print(f"[ERROR] Product ID {product_id} not found")
                    stats['failed'] += 1
                    continue
                
                product_name = product['product_name']
                print(f"Processing: {product_name}")
                
                # Classify the product
                classification = self.classifier.classify_product(
                    product_name,
                    batch_id=self.current_batch_id
                )
                
                # Update database
                if 'error' in classification:
                    self.db.mark_as_error(product_id, classification['error'])
                    stats['failed'] += 1
                else:
                    success = self.db.update_classification(product_id, classification)
                    if success:
                        stats['successful'] += 1
                    else:
                        stats['failed'] += 1
                
                stats['total_processed'] += 1
                time.sleep(0.5)  # Rate limiting
            
            return stats
            
        except Exception as e:
            print(f"[ERROR] Error processing specific products: {e}")
            return {**stats, 'error': str(e)}
        
        finally:
            self.db.close()
    
    def reprocess_errors(self) -> Dict:
        """Reprocess all products that had errors"""
        if not self.db.connect():
            return {"error": "Failed to connect to database"}
        
        try:
            # Get all products with errors
            self.db.cursor.execute("""
                SELECT id, product_name 
                FROM mro_products 
                WHERE processing_status = 'error'
                ORDER BY id
            """)
            error_products = self.db.cursor.fetchall()
            
            if not error_products:
                print("No products with errors to reprocess")
                return {'total_processed': 0}
            
            print(f"Found {len(error_products)} products with errors to reprocess")
            
            # Reset their status to pending
            for product in error_products:
                self.db.cursor.execute("""
                    UPDATE mro_products 
                    SET processing_status = 'pending', error_message = NULL 
                    WHERE id = %s
                """, (product['id'],))
            self.db.conn.commit()
            
            # Now process them normally
            return self.process_all_pending()
            
        except Exception as e:
            print(f"[ERROR] Error reprocessing failed products: {e}")
            return {'error': str(e)}
        
        finally:
            self.db.close()