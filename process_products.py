"""
Main processing script for AI-Catalog
Processes CSV directly to PostgreSQL with GPT-5 classification and duplicate detection
"""

import pandas as pd
import time
import uuid
from datetime import datetime
import json
from typing import List, Dict
import sys
from pathlib import Path

from database import DatabaseManager, DUPLICATE_DETECTION_CONFIG
from classify import GPT5HybridClassifier
from taxonomy import get_taxonomy_summary

def load_products_from_csv(filepath: str = 'data/CategoriaD03-Produtos.csv') -> List[str]:
    """Load products from CSV file"""
    try:
        # Try different encodings
        try:
            df = pd.read_csv(filepath, encoding='utf-8')
        except:
            df = pd.read_csv(filepath, encoding='latin-1')
        
        # Get the first column (product descriptions)
        product_column = df.columns[0]
        products = df[product_column].dropna().tolist()
        
        print(f"✅ Loaded {len(products)} products from {filepath}")
        return products
    except Exception as e:
        print(f"❌ Error loading CSV: {e}")
        return []

def process_batch(classifier: GPT5HybridClassifier, 
                 db: DatabaseManager,
                 products: List[str],
                 batch_number: int,
                 batch_id: uuid.UUID) -> Dict:
    """Process a single batch of products"""
    
    start_time = time.time()
    stats = {
        'batch_number': batch_number,
        'total_products': len(products),
        'new_products': 0,
        'duplicates_found': 0,
        'low_confidence_count': 0,
        'api_tokens': 0,
        'cost_estimate': 0
    }
    
    print(f"\n📦 Processing batch {batch_number} ({len(products)} products)...")
    
    # Step 1: Classify with GPT-5
    print("  🤖 Calling GPT-5 with high reasoning...")
    classified = classifier.classify_batch(products, batch_number)
    
    # Step 2: Detect duplicates using dictionary
    print("  🔍 Checking for duplicates...")
    with_duplicates = classifier.detect_duplicates(classified)
    
    # Step 3: Save to database
    print("  💾 Saving to PostgreSQL...")
    for position, product in enumerate(with_duplicates):
        # Save product
        product_id = db.save_product(product, batch_id, position)
        
        # Register hash keys if it's a new product (master)
        if product.get('is_master', False):
            db.register_product_keys(
                product_id,
                product['hash_keys'],
                product['duplicate_group_id'],
                classifier.config['key_weights']
            )
            stats['new_products'] += 1
        else:
            stats['duplicates_found'] += 1
        
        # Track low confidence
        if product.get('confidence', 0) < 0.8:
            stats['low_confidence_count'] += 1
    
    # Calculate statistics
    stats['processing_time'] = time.time() - start_time
    
    # Estimate tokens and cost (rough estimate)
    avg_tokens_per_product = 150  # Estimate
    stats['api_tokens'] = len(products) * avg_tokens_per_product
    stats['cost_estimate'] = classifier.estimate_api_cost(
        stats['api_tokens'] * 0.6,  # Input tokens
        stats['api_tokens'] * 0.4   # Output tokens
    )
    
    # Save batch statistics
    db.save_batch_stats(batch_id, stats)
    
    print(f"  ✅ Batch {batch_number} complete:")
    print(f"     - New products: {stats['new_products']}")
    print(f"     - Duplicates found: {stats['duplicates_found']}")
    print(f"     - Processing time: {stats['processing_time']:.2f}s")
    print(f"     - Estimated cost: ${stats['cost_estimate']:.2f}")
    
    return stats

def main():
    """Main processing pipeline"""
    
    print("=" * 70)
    print("🚀 AI-CATALOG PROCESSING PIPELINE")
    print("=" * 70)
    
    # Show taxonomy summary
    taxonomy = get_taxonomy_summary()
    print(f"\n📊 Taxonomy loaded:")
    print(f"   - Categories: {taxonomy['categories']}")
    print(f"   - Subcategories: {taxonomy['subcategories']}")
    
    # Initialize database
    print("\n🔌 Connecting to PostgreSQL...")
    db = DatabaseManager()
    
    # Initialize classifier
    print("🤖 Initializing GPT-5 classifier...")
    classifier = GPT5HybridClassifier(db)
    
    # Load products
    print("\n📂 Loading products from CSV...")
    products = load_products_from_csv('CategoriaD03-Produtos.csv')
    
    if not products:
        print("❌ No products found to process")
        return
    
    # Process configuration
    batch_size = DUPLICATE_DETECTION_CONFIG['batch_size']  # 10 products per batch
    total_batches = (len(products) + batch_size - 1) // batch_size
    
    print(f"\n📋 Processing configuration:")
    print(f"   - Total products: {len(products)}")
    print(f"   - Batch size: {batch_size}")
    print(f"   - Total batches: {total_batches}")
    print(f"   - Model: GPT-5 with high reasoning")
    print(f"   - Duplicate detection: 6-key strategy")
    
    # Estimate total cost
    estimated_total_cost = (len(products) * 150 * 0.075) / 1000  # Rough estimate
    print(f"   - Estimated total cost: ${estimated_total_cost:.2f}")
    
    # Confirm processing
    response = input("\n⚠️  Ready to process? (yes/no): ")
    if response.lower() != 'yes':
        print("Processing cancelled")
        return
    
    # Process in batches
    print("\n" + "=" * 70)
    print("STARTING BATCH PROCESSING")
    print("=" * 70)
    
    overall_stats = {
        'total_products': 0,
        'new_products': 0,
        'duplicates_found': 0,
        'low_confidence': 0,
        'total_cost': 0,
        'total_time': 0
    }
    
    for batch_num in range(total_batches):
        # Create batch
        start_idx = batch_num * batch_size
        end_idx = min(start_idx + batch_size, len(products))
        batch_products = products[start_idx:end_idx]
        
        # Generate batch ID
        batch_id = uuid.uuid4()
        
        # Process batch
        try:
            batch_stats = process_batch(
                classifier,
                db,
                batch_products,
                batch_num + 1,
                batch_id
            )
            
            # Update overall statistics
            overall_stats['total_products'] += batch_stats['total_products']
            overall_stats['new_products'] += batch_stats['new_products']
            overall_stats['duplicates_found'] += batch_stats['duplicates_found']
            overall_stats['low_confidence'] += batch_stats['low_confidence_count']
            overall_stats['total_cost'] += batch_stats['cost_estimate']
            overall_stats['total_time'] += batch_stats['processing_time']
            
            # Progress update
            progress = ((batch_num + 1) / total_batches) * 100
            print(f"\n📊 Overall progress: {progress:.1f}% ({batch_num + 1}/{total_batches} batches)")
            print(f"   Unique products so far: {overall_stats['new_products']}")
            print(f"   Duplicates detected: {overall_stats['duplicates_found']}")
            
            # Rate limiting between batches
            if batch_num < total_batches - 1:
                time.sleep(DUPLICATE_DETECTION_CONFIG.get('retry_delay', 2))
                
        except Exception as e:
            print(f"❌ Error processing batch {batch_num + 1}: {e}")
            continue
    
    # Final summary
    print("\n" + "=" * 70)
    print("✅ PROCESSING COMPLETE")
    print("=" * 70)
    
    # Get final statistics from database
    summary = db.get_processing_summary()
    
    print(f"\n📊 Final Statistics:")
    print(f"   - Total products processed: {overall_stats['total_products']}")
    print(f"   - Unique products: {overall_stats['new_products']}")
    print(f"   - Duplicates found: {overall_stats['duplicates_found']}")
    print(f"   - Duplicate rate: {(overall_stats['duplicates_found']/overall_stats['total_products']*100):.1f}%")
    print(f"   - Products needing review: {overall_stats['low_confidence']}")
    print(f"   - Total processing time: {overall_stats['total_time']:.2f} seconds")
    print(f"   - Total API cost: ${overall_stats['total_cost']:.2f}")
    
    if summary['overall']:
        print(f"\n📈 Database Summary:")
        print(f"   - Average confidence: {summary['overall']['avg_confidence']:.3f}")
        print(f"   - Total batches: {summary['overall']['total_batches']}")
    
    if summary['top_categories']:
        print(f"\n🏷️ Top Categories:")
        for cat in summary['top_categories'][:5]:
            print(f"   - {cat['category_name']}: {cat['product_count']} products")
    
    # Generate report file
    report_file = f"processing_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump({
            'processing_stats': overall_stats,
            'database_summary': summary,
            'timestamp': datetime.now().isoformat()
        }, f, indent=2, default=str)
    
    print(f"\n📄 Report saved to: {report_file}")
    
    # Close database connection
    db.close()
    
    print("\n✨ Processing pipeline completed successfully!")

if __name__ == "__main__":
    main()