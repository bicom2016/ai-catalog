"""
Local test script for AI-Catalog
Tests the classification and duplicate detection logic without database
"""

import pandas as pd
from classify import GPT5HybridClassifier
from taxonomy import get_taxonomy_summary, CATEGORIES, SUBCATEGORIES
import json

class MockDatabaseManager:
    """Mock database for local testing"""
    def __init__(self):
        self.products = []
        self.duplicate_registry = {}
        self.next_group_id = 1
        print("Using mock database (no PostgreSQL connection)")
    
    def check_duplicate_by_keys(self, hash_keys, key_weights):
        """Check for duplicates in memory"""
        for key_type, hash_key in hash_keys.items():
            if hash_key in self.duplicate_registry:
                return (self.duplicate_registry[hash_key], 0.95)
        return None
    
    def get_next_group_id(self):
        """Get next group ID"""
        group_id = self.next_group_id
        self.next_group_id += 1
        return group_id
    
    def register_product_keys(self, product_id, hash_keys, duplicate_group_id, key_weights):
        """Register keys in memory"""
        for key_type, hash_key in hash_keys.items():
            self.duplicate_registry[hash_key] = duplicate_group_id
    
    def save_product(self, product_data, batch_id, position):
        """Save product to memory"""
        product_data['id'] = len(self.products) + 1
        self.products.append(product_data)
        return product_data['id']
    
    def close(self):
        pass

def test_classification():
    """Test the classification system locally"""
    
    print("=" * 70)
    print("AI-CATALOG LOCAL TEST")
    print("=" * 70)
    
    # Show taxonomy
    taxonomy = get_taxonomy_summary()
    print(f"\nTaxonomy loaded:")
    print(f"  - Categories: {taxonomy['categories']}")
    print(f"  - Subcategories: {taxonomy['subcategories']}")
    
    # Load sample products
    print("\nLoading products from CSV...")
    try:
        df = pd.read_csv('CategoriaD03-Produtos.csv', encoding='latin-1')
        product_column = df.columns[0]
        all_products = df[product_column].dropna().tolist()
        print(f"  Found {len(all_products)} products")
        
        # Take first 10 for testing
        test_products = all_products[:10]
        print(f"\nTesting with first {len(test_products)} products:")
        for i, p in enumerate(test_products, 1):
            print(f"  {i}. {p[:80]}...")
        
    except Exception as e:
        print(f"Error loading CSV: {e}")
        return
    
    # Initialize mock database and classifier
    print("\nInitializing classifier...")
    mock_db = MockDatabaseManager()
    classifier = GPT5HybridClassifier(mock_db)
    
    # Test hash key generation
    print("\n" + "=" * 70)
    print("TESTING HASH KEY GENERATION")
    print("=" * 70)
    
    test_name = "PARAFUSO SEXT 1/2 POL INOX"
    print(f"\nTest product: {test_name}")
    hash_keys = classifier.generate_hash_keys(test_name.lower(), test_name)
    print("\nGenerated hash keys:")
    for key_type, key_value in hash_keys.items():
        print(f"  {key_type:8} -> {key_value}")
    
    # Test duplicate detection logic
    print("\n" + "=" * 70)
    print("TESTING DUPLICATE DETECTION")
    print("=" * 70)
    
    similar_products = [
        "PARAFUSO SEXT 1/2 POL INOX",
        "Parafuso Sext. 1/2\" INOX",
        "PARAFUSO SEXTAVADO 12,7MM INOX",
        "PARAFUSO ALLEN 1/2 POL"
    ]
    
    print("\nSimilar products test:")
    for product in similar_products:
        keys = classifier.generate_hash_keys(product.lower(), product)
        print(f"\n{product}")
        print(f"  exact: {keys['exact'][:50]}")
        print(f"  alpha: {keys['alpha'][:50]}")
        print(f"  sorted: {keys['sorted'][:50]}")
    
    # Ask user if they want to test with real API
    print("\n" + "=" * 70)
    print("API CLASSIFICATION TEST")
    print("=" * 70)
    
    response = input("\nDo you want to test with real OpenAI API? (yes/no): ")
    if response.lower() == 'yes':
        print("\nClassifying products with GPT-5...")
        print("NOTE: This will use your OpenAI API credits")
        
        # Classify batch
        results = classifier.classify_batch(test_products[:3], batch_number=1)
        
        print("\nClassification Results:")
        for i, result in enumerate(results, 1):
            print(f"\n{i}. {result.get('original_name', 'N/A')}")
            print(f"   Normalized: {result.get('normalized_name', 'N/A')}")
            print(f"   Category: {result.get('category_code', 'N/A')} - {result.get('category_name', 'N/A')}")
            print(f"   Subcategory: {result.get('subcategory_code', 'N/A')} - {result.get('subcategory_name', 'N/A')}")
            print(f"   Confidence: {result.get('confidence', 0):.2f}")
            print(f"   Reasoning: {result.get('reasoning', 'N/A')[:100]}...")
        
        # Test duplicate detection
        print("\nChecking for duplicates...")
        with_duplicates = classifier.detect_duplicates(results)
        
        duplicate_groups = {}
        for product in with_duplicates:
            group_id = product.get('duplicate_group_id')
            if group_id not in duplicate_groups:
                duplicate_groups[group_id] = []
            duplicate_groups[group_id].append(product['normalized_name'])
        
        print("\nDuplicate Groups Found:")
        for group_id, products in duplicate_groups.items():
            print(f"  Group {group_id}: {len(products)} products")
            for p in products:
                print(f"    - {p}")
    
    # Save test results
    print("\n" + "=" * 70)
    print("TEST COMPLETE")
    print("=" * 70)
    
    if mock_db.products:
        with open('test_results.json', 'w', encoding='utf-8') as f:
            json.dump({
                'products': mock_db.products,
                'duplicate_registry_size': len(mock_db.duplicate_registry),
                'unique_groups': mock_db.next_group_id - 1
            }, f, indent=2, ensure_ascii=False)
        print("\nTest results saved to test_results.json")
    
    print("\nLocal test completed successfully!")
    print("\nNote: For production use, deploy to Railway where the database is accessible.")

if __name__ == "__main__":
    test_classification()