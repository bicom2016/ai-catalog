#!/usr/bin/env python3
"""
MRO Product Classification System
Classifies MRO products using Claude API and stores results in PostgreSQL
"""

import sys
import argparse
import pandas as pd
from datetime import datetime
from database_mro import MRODatabase
from batch_processor import BatchProcessor
from mro_classifier import MROClassifier

def setup_database(csv_path: str = None):
    """Initialize database and optionally import CSV data"""
    print("\n[SETUP] Setting up database...")
    db = MRODatabase()
    
    if not db.connect():
        print("[ERROR] Failed to connect to database")
        return False
    
    try:
        # Create tables
        if db.create_tables():
            print("[OK] Database tables created successfully")
        
        # Import CSV if provided
        if csv_path:
            print(f"\n[IMPORT] Importing data from {csv_path}...")
            records = db.import_csv_data(csv_path)
            if records > 0:
                print(f"[OK] Successfully imported {records} products")
            else:
                print("[ERROR] Failed to import CSV data")
                return False
        
        return True
        
    finally:
        db.close()

def run_classification(batch_size: int = 10, delay: float = 2.0):
    """Run the classification process"""
    print("\n[CLASSIFY] Starting MRO classification process...")
    print(f"   Batch size: {batch_size} products")
    print(f"   Delay between batches: {delay} seconds")
    
    processor = BatchProcessor(batch_size=batch_size, delay_between_batches=delay)
    results = processor.process_all_pending()
    
    if 'error' in results:
        print(f"\n[ERROR] Classification failed: {results['error']}")
        return False
    
    return True

def generate_report():
    """Generate classification comparison report"""
    print("\n[REPORT] Generating classification report...")
    
    db = MRODatabase()
    if not db.connect():
        print("[ERROR] Failed to connect to database")
        return
    
    try:
        # Get statistics
        stats = db.get_classification_stats()
        print("\n" + "="*60)
        print("CLASSIFICATION STATISTICS")
        print("="*60)
        print(f"Total products: {stats.get('total', 0)}")
        print(f"Completed: {stats.get('completed', 0)}")
        print(f"Pending: {stats.get('pending', 0)}")
        print(f"Errors: {stats.get('errors', 0)}")
        if stats.get('avg_confidence'):
            print(f"Average confidence: {stats['avg_confidence']:.2%}")
        
        # Get comparison data
        comparison_df = db.get_category_comparison()
        
        if not comparison_df.empty:
            print("\n" + "="*60)
            print("CATEGORY COMPARISON (Top 20)")
            print("="*60)
            
            # Show products where categories differ
            different_cats = comparison_df[
                comparison_df['old_category'] != comparison_df['new_category_name']
            ].head(20)
            
            if not different_cats.empty:
                print("\nProducts with different categories:")
                for _, row in different_cats.iterrows():
                    print(f"\nProduct: {row['product_name'][:60]}")
                    print(f"  Old: {row['old_category']} > {row['old_subcategory']}")
                    print(f"  New: {row['new_category_name']} > {row['new_subcategory_name']}")
                    print(f"  Confidence: {row['confidence_score']:.2%}")
            
            # Category distribution
            print("\n" + "="*60)
            print("NEW CATEGORY DISTRIBUTION")
            print("="*60)
            
            db.cursor.execute("""
                SELECT 
                    new_category_code,
                    new_category_name,
                    COUNT(*) as count,
                    AVG(confidence_score) as avg_confidence
                FROM mro_products
                WHERE processing_status = 'completed'
                GROUP BY new_category_code, new_category_name
                ORDER BY count DESC
                LIMIT 15
            """)
            
            categories = db.cursor.fetchall()
            for cat in categories:
                print(f"{cat['new_category_code']} - {cat['new_category_name']}: {cat['count']} products (confidence: {cat['avg_confidence']:.2%})")
            
            # Export to CSV
            export_path = f"mro_classification_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            comparison_df.to_csv(export_path, index=False)
            print(f"\n[OK] Full report exported to: {export_path}")
        
    finally:
        db.close()

def test_single_product(product_name: str):
    """Test classification for a single product"""
    print(f"\n[TEST] Testing classification for: {product_name}")
    
    classifier = MROClassifier()
    result = classifier.classify_product(product_name)
    
    print("\nClassification Result:")
    print(f"  Department: {result.get('dept_code')} - {result.get('dept_name')}")
    print(f"  Category: {result.get('cat_code')} - {result.get('cat_name')}")
    print(f"  Subcategory: {result.get('sub_code')} - {result.get('sub_name')}")
    print(f"  Confidence: {result.get('confidence', 0):.2%}")
    
    if 'error' in result:
        print(f"  Error: {result['error']}")

def main():
    parser = argparse.ArgumentParser(description='MRO Product Classification System')
    parser.add_argument('--setup', action='store_true', help='Setup database tables')
    parser.add_argument('--import-csv', type=str, help='Path to CSV file to import')
    parser.add_argument('--classify', action='store_true', help='Run classification process')
    parser.add_argument('--batch-size', type=int, default=10, help='Batch size for processing (default: 10)')
    parser.add_argument('--delay', type=float, default=2.0, help='Delay between batches in seconds (default: 2.0)')
    parser.add_argument('--report', action='store_true', help='Generate classification report')
    parser.add_argument('--test', type=str, help='Test classification for a single product')
    parser.add_argument('--reprocess-errors', action='store_true', help='Reprocess products with errors')
    
    args = parser.parse_args()
    
    # If no arguments provided, show help
    if len(sys.argv) == 1:
        parser.print_help()
        return
    
    # Setup database
    if args.setup or args.import_csv:
        if not setup_database(args.import_csv):
            sys.exit(1)
    
    # Test single product
    if args.test:
        test_single_product(args.test)
        return
    
    # Reprocess errors
    if args.reprocess_errors:
        print("\n[REPROCESS] Reprocessing products with errors...")
        processor = BatchProcessor(batch_size=args.batch_size, delay_between_batches=args.delay)
        processor.reprocess_errors()
        return
    
    # Run classification
    if args.classify:
        if not run_classification(batch_size=args.batch_size, delay=args.delay):
            sys.exit(1)
    
    # Generate report
    if args.report:
        generate_report()

if __name__ == '__main__':
    main()