"""
View results from test_local.py or processing pipeline
"""

import json
import pandas as pd
from pathlib import Path
import os

def view_test_results():
    """Display test results in a formatted way"""
    
    print("=" * 70)
    print("AI-CATALOG RESULTS VIEWER")
    print("=" * 70)
    
    # Check for test results file
    if os.path.exists('test_results.json'):
        print("\nFound test_results.json")
        
        with open('test_results.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        products = data.get('products', [])
        
        if products:
            print(f"\nTotal products processed: {len(products)}")
            print(f"Unique groups: {data.get('unique_groups', 0)}")
            print(f"Dictionary size: {data.get('duplicate_registry_size', 0)}")
            
            # Convert to DataFrame for better display
            df = pd.DataFrame(products)
            
            # Display summary
            print("\n" + "=" * 70)
            print("CLASSIFICATION SUMMARY")
            print("=" * 70)
            
            if 'category_name' in df.columns:
                print("\nCategories distribution:")
                category_counts = df['category_name'].value_counts()
                for cat, count in category_counts.items():
                    print(f"  - {cat}: {count} products")
            
            if 'duplicate_group_id' in df.columns:
                print("\nDuplicate analysis:")
                duplicate_groups = df.groupby('duplicate_group_id').size()
                duplicates = duplicate_groups[duplicate_groups > 1]
                print(f"  - Unique products: {len(duplicate_groups)}")
                print(f"  - Duplicate groups: {len(duplicates)}")
                if len(duplicates) > 0:
                    print(f"  - Average duplicates per group: {duplicates.mean():.1f}")
            
            if 'confidence' in df.columns:
                print("\nConfidence analysis:")
                print(f"  - Average confidence: {df['confidence'].mean():.3f}")
                print(f"  - Min confidence: {df['confidence'].min():.3f}")
                print(f"  - Max confidence: {df['confidence'].max():.3f}")
                low_confidence = df[df['confidence'] < 0.8]
                print(f"  - Products needing review (<0.8): {len(low_confidence)}")
            
            # Show sample products
            print("\n" + "=" * 70)
            print("SAMPLE PRODUCTS")
            print("=" * 70)
            
            sample_size = min(10, len(df))
            for i, row in df.head(sample_size).iterrows():
                print(f"\n{i+1}. {row.get('original_name', 'N/A')[:60]}...")
                print(f"   Normalized: {row.get('normalized_name', 'N/A')[:60]}...")
                print(f"   Category: {row.get('category_code', '')} - {row.get('category_name', 'N/A')}")
                print(f"   Subcategory: {row.get('subcategory_code', '')} - {row.get('subcategory_name', 'N/A')}")
                if 'confidence' in row:
                    print(f"   Confidence: {row.get('confidence', 0):.2f}")
                if 'duplicate_group_id' in row:
                    print(f"   Duplicate Group: {row.get('duplicate_group_id', 'N/A')}")
            
            # Export to CSV option
            print("\n" + "=" * 70)
            response = input("\nExport results to CSV? (yes/no): ")
            if response.lower() == 'yes':
                csv_file = 'classification_results.csv'
                df.to_csv(csv_file, index=False, encoding='utf-8')
                print(f"Results exported to {csv_file}")
        else:
            print("No products found in results")
    else:
        print("\nNo test_results.json found. Run test_local.py first.")
    
    # Check for processing reports
    print("\n" + "=" * 70)
    print("PROCESSING REPORTS")
    print("=" * 70)
    
    reports = list(Path('.').glob('processing_report_*.json'))
    if reports:
        print(f"\nFound {len(reports)} processing reports:")
        for report in sorted(reports):
            print(f"  - {report.name}")
            
            with open(report, 'r', encoding='utf-8') as f:
                report_data = json.load(f)
            
            stats = report_data.get('processing_stats', {})
            if stats:
                print(f"      Total products: {stats.get('total_products', 0)}")
                print(f"      Unique products: {stats.get('new_products', 0)}")
                print(f"      Duplicates: {stats.get('duplicates_found', 0)}")
                print(f"      Cost: ${stats.get('total_cost', 0):.2f}")
    else:
        print("\nNo processing reports found.")
    
    print("\n" + "=" * 70)
    print("Results viewing complete!")

if __name__ == "__main__":
    view_results()