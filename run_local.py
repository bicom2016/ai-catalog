"""
Local runner for AI-Catalog with control and visibility
Processes products in small batches with review capability
"""

import pandas as pd
import time
import uuid
from datetime import datetime
import json
import sys
from pathlib import Path
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import our modules
from database import DatabaseManager, DUPLICATE_DETECTION_CONFIG
from classify import GPT5HybridClassifier
from taxonomy import get_taxonomy_summary

def process_batch_with_review(classifier, db, products, batch_number, batch_id):
    """Process a batch and show results before saving"""
    
    print(f"\n{'='*70}")
    print(f"BATCH {batch_number} - Processing {len(products)} products")
    print('='*70)
    
    # Show products to be processed
    print("\nProducts in this batch:")
    for i, p in enumerate(products, 1):
        print(f"  {i}. {p[:80]}...")
    
    # Classify with GPT-5
    print("\nCalling GPT-5 with high reasoning...")
    start_time = time.time()
    
    try:
        classified = classifier.classify_batch(products, batch_number)
        
        # Detect duplicates
        print("Checking for duplicates...")
        with_duplicates = classifier.detect_duplicates(classified)
        
        # Show results
        print(f"\n{'='*70}")
        print("CLASSIFICATION RESULTS")
        print('='*70)
        
        results_df = pd.DataFrame(with_duplicates)
        
        # Display results nicely
        for idx, row in results_df.iterrows():
            print(f"\n{idx+1}. ORIGINAL: {row.get('original_name', 'N/A')[:60]}")
            print(f"   NORMALIZED: {row.get('normalized_name', 'N/A')[:60]}")
            print(f"   CATEGORY: {row.get('category_code', '')} - {row.get('category_name', 'N/A')}")
            print(f"   SUBCATEGORY: {row.get('subcategory_code', '')} - {row.get('subcategory_name', 'N/A')}")
            print(f"   CONFIDENCE: {row.get('confidence', 0):.2f}")
            print(f"   DUPLICATE GROUP: {row.get('duplicate_group_id', 'N/A')}")
            if row.get('is_master'):
                print("   STATUS: MASTER RECORD")
            reasoning = row.get('reasoning', 'N/A')[:100]
            # Remove problematic unicode characters
            reasoning = reasoning.encode('ascii', 'replace').decode('ascii')
            print(f"   REASONING: {reasoning}")
        
        # Statistics
        processing_time = time.time() - start_time
        unique_products = len(results_df[results_df['is_master'] == True])
        duplicates = len(results_df[results_df['is_master'] == False])
        avg_confidence = results_df['confidence'].mean() if 'confidence' in results_df else 0
        
        print(f"\n{'='*70}")
        print("BATCH STATISTICS")
        print('='*70)
        print(f"Processing time: {processing_time:.2f} seconds")
        print(f"Unique products: {unique_products}")
        print(f"Duplicates found: {duplicates}")
        print(f"Average confidence: {avg_confidence:.3f}")
        
        # Ask for confirmation
        print(f"\n{'='*70}")
        response = input("Save these results to database? (yes/no/quit): ").lower()
        
        if response == 'quit':
            return 'quit'
        elif response == 'yes':
            # Save to database
            print("Saving to PostgreSQL...")
            saved_count = 0
            for position, product in enumerate(with_duplicates):
                product_id = db.save_product(product, batch_id, position)
                
                if product.get('is_master', False):
                    db.register_product_keys(
                        product_id,
                        product['hash_keys'],
                        product['duplicate_group_id'],
                        classifier.config['key_weights']
                    )
                saved_count += 1
            
            print(f"Saved {saved_count} products to database")
            
            # Save batch stats
            stats = {
                'batch_number': batch_number,
                'total_products': len(products),
                'new_products': unique_products,
                'duplicates_found': duplicates,
                'low_confidence_count': len(results_df[results_df.get('confidence', 1) < 0.8]) if 'confidence' in results_df else 0,
                'processing_time': processing_time,
                'api_tokens': len(products) * 150,  # Estimate
                'cost_estimate': (len(products) * 150 * 0.075) / 1000
            }
            db.save_batch_stats(batch_id, stats)
            
            return 'continue'
        else:
            print("Skipping batch (not saved)")
            return 'skip'
            
    except Exception as e:
        print(f"Error processing batch: {e}")
        return 'error'

def main():
    """Main local runner with control"""
    
    print("="*70)
    print("AI-CATALOG LOCAL RUNNER")
    print("="*70)
    
    # Check environment variables
    if not os.getenv("OPEN_AI_API_KEY"):
        print("ERROR: OPEN_AI_API_KEY not found in .env")
        return
    
    if not os.getenv("DATABASE_URL"):
        print("ERROR: DATABASE_URL not found in .env")
        return
    
    print("\nEnvironment variables loaded:")
    print("  - OpenAI API Key: ***" + os.getenv("OPEN_AI_API_KEY")[-4:])
    print("  - Database URL: " + os.getenv("DATABASE_URL")[:30] + "...")
    
    # Show taxonomy
    taxonomy = get_taxonomy_summary()
    print(f"\nTaxonomy loaded:")
    print(f"  - Categories: {taxonomy['categories']}")
    print(f"  - Subcategories: {taxonomy['subcategories']}")
    
    # Initialize database
    print("\nConnecting to PostgreSQL...")
    try:
        db = DatabaseManager()
        print("Database connected successfully")
    except Exception as e:
        print(f"Database connection failed: {e}")
        print("\nMake sure your DATABASE_URL is accessible from local machine.")
        print("Railway internal URLs (.railway.internal) won't work locally.")
        return
    
    # Initialize classifier
    print("Initializing GPT-5 classifier...")
    classifier = GPT5HybridClassifier(db)
    
    # Load products
    print("\nLoading products from CSV...")
    try:
        df = pd.read_csv('CategoriaD03-Produtos.csv', encoding='latin-1')
        product_column = df.columns[0]
        all_products = df[product_column].dropna().tolist()
        print(f"Found {len(all_products)} total products")
    except Exception as e:
        print(f"Error loading CSV: {e}")
        return
    
    # Configuration
    print(f"\n{'='*70}")
    print("PROCESSING CONFIGURATION")
    print('='*70)
    
    # Ask for number of products
    num_products = input(f"How many products to process? (1-{len(all_products)}, default=20): ")
    try:
        num_products = int(num_products) if num_products else 20
        num_products = min(max(1, num_products), len(all_products))
    except:
        num_products = 20
    
    batch_size = input("Batch size? (1-20, default=5): ")
    try:
        batch_size = int(batch_size) if batch_size else 5
        batch_size = min(max(1, batch_size), 20)
    except:
        batch_size = 5
    
    # Select products
    products_to_process = all_products[:num_products]
    total_batches = (len(products_to_process) + batch_size - 1) // batch_size
    
    print(f"\nWill process:")
    print(f"  - {num_products} products")
    print(f"  - {batch_size} products per batch")
    print(f"  - {total_batches} total batches")
    
    estimated_cost = (num_products * 150 * 0.075) / 1000
    print(f"  - Estimated cost: ${estimated_cost:.2f}")
    
    response = input("\nProceed? (yes/no): ")
    if response.lower() != 'yes':
        print("Cancelled")
        return
    
    # Process batches
    for batch_num in range(total_batches):
        start_idx = batch_num * batch_size
        end_idx = min(start_idx + batch_size, len(products_to_process))
        batch_products = products_to_process[start_idx:end_idx]
        
        batch_id = uuid.uuid4()
        
        result = process_batch_with_review(
            classifier, db, batch_products, batch_num + 1, batch_id
        )
        
        if result == 'quit':
            print("\nProcessing stopped by user")
            break
        elif result == 'error':
            print("\nError occurred, stopping")
            break
        
        if batch_num < total_batches - 1:
            print(f"\nCompleted batch {batch_num + 1} of {total_batches}")
            cont = input("Continue to next batch? (yes/no): ")
            if cont.lower() != 'yes':
                print("Processing stopped")
                break
    
    # Final summary
    print(f"\n{'='*70}")
    print("PROCESSING COMPLETE")
    print('='*70)
    
    try:
        summary = db.get_processing_summary()
        if summary['overall']:
            print(f"\nDatabase summary:")
            print(f"  - Total products: {summary['overall']['total_products']}")
            print(f"  - Unique products: {summary['overall']['unique_products']}")
            print(f"  - Products needing review: {summary['overall']['needs_review']}")
    except:
        pass
    
    db.close()
    print("\nUse 'py view_data.py' to explore the results in detail")

if __name__ == "__main__":
    main()