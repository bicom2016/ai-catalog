"""
GPT-5 High Reasoning Classifier with 6-Key Hash Strategy
Hybrid approach: GPT-5 for intelligence, Dictionary for scale
"""

import openai
import json
import re
import unicodedata
import hashlib
from typing import List, Dict, Tuple, Optional
import time
from dotenv import load_dotenv
import os
from taxonomy import CATEGORIES, SUBCATEGORIES
from database import DatabaseManager, DUPLICATE_DETECTION_CONFIG

load_dotenv()

class GPT5HybridClassifier:
    def __init__(self, db_manager: DatabaseManager):
        """Initialize with GPT-5 and database connection"""
        # Set API key directly
        os.environ["OPENAI_API_KEY"] = os.getenv("OPEN_AI_API_KEY")
        
        # Initialize client without proxy issues
        from openai import OpenAI
        self.client = OpenAI()
        
        self.db = db_manager
        self.config = DUPLICATE_DETECTION_CONFIG
        # Using GPT-5 with high reasoning
        self.model = "gpt-5"  # GPT-5 model
        self.reasoning_effort = "high"  # Maximum reasoning capability for best accuracy
        
    def generate_hash_keys(self, normalized_name: str, original_name: str = "") -> Dict[str, str]:
        """
        Generate 6 different hash keys for duplicate detection
        Each key type has different matching characteristics
        """
        keys = {}
        
        # 1. EXACT: Exact normalized match (weight: 1.0)
        keys['exact'] = normalized_name.lower().strip()
        
        # 2. ALPHA: Alphanumeric only, no spaces (weight: 0.95)
        alpha_only = re.sub(r'[^a-z0-9]', '', normalized_name.lower())
        keys['alpha'] = alpha_only
        
        # 3. SORTED: Sorted words for order variation (weight: 0.90)
        words = normalized_name.lower().split()
        sorted_words = sorted(words)
        keys['sorted'] = '_'.join(sorted_words)
        
        # 4. CORE: Core product features extraction (weight: 0.85)
        # Extract key terms: dimensions, types, materials
        core_terms = self._extract_core_terms(normalized_name)
        keys['core'] = '_'.join(sorted(core_terms))
        
        # 5. DIM: Dimension pattern extraction (weight: 0.85)
        dimensions = self._extract_dimensions(normalized_name)
        keys['dim'] = '_'.join(dimensions) if dimensions else hashlib.md5(normalized_name.encode()).hexdigest()[:10]
        
        # 6. PHON: Phonetic/typo resistance using first chars (weight: 0.75)
        # Use first 3 chars of each significant word
        significant_words = [w for w in words if len(w) > 2][:4]
        phon_key = ''.join([w[:3] for w in significant_words])
        keys['phon'] = phon_key if phon_key else normalized_name[:10].lower()
        
        return keys
    
    def _extract_core_terms(self, text: str) -> List[str]:
        """Extract core product terms for matching"""
        core_patterns = [
            r'\b(parafuso|porca|arruela|chave|ferramenta|oleo|graxa|filtro|valvula|bomba|motor)\b',
            r'\b(sextavado|allen|phillips|fenda|torx)\b',
            r'\b(aco|inox|ferro|aluminio|plastico|borracha)\b',
            r'\b(mm|cm|m|pol|polegada|litro|kg|g)\b'
        ]
        
        core_terms = []
        text_lower = text.lower()
        
        for pattern in core_patterns:
            matches = re.findall(pattern, text_lower)
            core_terms.extend(matches)
        
        return list(set(core_terms))  # Remove duplicates
    
    def _extract_dimensions(self, text: str) -> List[str]:
        """Extract and normalize dimensions from product name"""
        dimensions = []
        
        # Pattern for dimensions with units
        dim_patterns = [
            r'(\d+(?:[.,]\d+)?)\s*(mm|cm|m|pol|")',
            r'(\d+(?:[.,]\d+)?)\s*x\s*(\d+(?:[.,]\d+)?)',
            r'M(\d+)',  # Metric threads
            r'(\d+/\d+)',  # Fractions
        ]
        
        for pattern in dim_patterns:
            matches = re.findall(pattern, text.lower())
            if matches:
                if isinstance(matches[0], tuple):
                    dimensions.extend([str(m) for m in matches[0] if m])
                else:
                    dimensions.extend([str(m) for m in matches])
        
        # Normalize dimensions to mm
        normalized_dims = []
        for dim in dimensions:
            if '/' in dim:  # Fraction to decimal
                try:
                    parts = dim.split('/')
                    decimal = float(parts[0]) / float(parts[1])
                    normalized_dims.append(f"{decimal:.2f}")
                except:
                    normalized_dims.append(dim)
            elif 'pol' in dim or '"' in dim:  # Inches to mm
                try:
                    value = float(re.sub(r'[^\d.]', '', dim))
                    mm_value = value * 25.4
                    normalized_dims.append(f"{mm_value:.1f}")
                except:
                    normalized_dims.append(dim)
            else:
                normalized_dims.append(dim)
        
        return normalized_dims
    
    def classify_batch(self, products: List[str], batch_number: int = 1) -> List[Dict]:
        """
        Classify products using GPT-5 high reasoning
        Returns classified products with duplicate detection
        """
        
        # Build prompt with taxonomy context
        taxonomy_context = self._build_taxonomy_context()
        
        prompt = f"""You are an expert MRO product classifier with deep reasoning capabilities.
        
TASK: Classify and normalize these MRO products with maximum accuracy.

PRODUCTS TO CLASSIFY:
{json.dumps([{"id": i, "name": p} for i, p in enumerate(products)], indent=2, ensure_ascii=False)}

AVAILABLE TAXONOMY:
{taxonomy_context}

FOR EACH PRODUCT, APPLY DEEP REASONING TO:

1. CLASSIFICATION:
   - Identify the most appropriate category and subcategory
   - Consider product function, materials, and application
   - Use the exact codes from the taxonomy provided

2. NORMALIZATION (Critical for duplicate detection):
   - Convert to lowercase
   - Standardize units: 1/2" → 12.7mm, 1 pol → 25.4mm
   - Remove brand names (TRAMONTINA, GEDORE, SKF, etc.)
   - Fix common typos and abbreviations
   - Standardize terms: SEXT → sextavado, CHAV → chave
   - Order: [type] [specification] [dimension] [material]
   Example: "PARAFUSO SEXT 1/2 POL INOX" → "parafuso sextavado 12.7mm inox"

3. CONFIDENCE SCORING:
   - 1.0: Perfect match with clear category
   - 0.9-0.99: High confidence, minor ambiguity
   - 0.8-0.89: Good match, some uncertainty
   - Below 0.8: Needs review

4. REASONING:
   - Explain your classification decision
   - Note any normalization changes made
   - Identify potential issues or ambiguities

RETURN JSON FORMAT:
{{
    "classifications": [
        {{
            "id": 0,
            "original_name": "exact original text",
            "normalized_name": "standardized lowercase name",
            "category_code": "SXX",
            "category_name": "Category Name",
            "subcategory_code": "CXXX",
            "subcategory_name": "Subcategory Name",
            "confidence": 0.95,
            "reasoning": "Classified as X because Y. Normalized: converted 1/2 pol to 12.7mm, removed brand."
        }}
    ]
}}

IMPORTANT:
- Use ONLY the category and subcategory codes from the provided taxonomy
- Apply all normalization rules consistently
- Provide detailed reasoning for each classification
"""

        try:
            # Using GPT-5 with reasoning API
            response = self.client.responses.create(
                model=self.model,
                reasoning={"effort": self.reasoning_effort},  # High reasoning for maximum accuracy
                input=[
                    {
                        "role": "system", 
                        "content": "You are an MRO expert with deep knowledge of industrial products. Use high reasoning to ensure accurate classification and normalization. Always return valid JSON."
                    },
                    {"role": "user", "content": prompt}
                ]
            )
            
            # Parse the GPT-5 response
            result = json.loads(response.output_text)
            classifications = result.get('classifications', [])
            
            # Generate hash keys for each product
            for item in classifications:
                hash_keys = self.generate_hash_keys(
                    item['normalized_name'],
                    item['original_name']
                )
                item['hash_keys'] = hash_keys
            
            return classifications
            
        except Exception as e:
            print(f"Error in GPT-5 classification: {e}")
            # Return basic structure on error
            return [{
                "id": i,
                "original_name": name,
                "normalized_name": name.lower(),
                "error": str(e),
                "confidence": 0.0,
                "needs_review": True
            } for i, name in enumerate(products)]
    
    def _build_taxonomy_context(self) -> str:
        """Build a concise taxonomy context for the prompt"""
        context = "CATEGORIES:\n"
        
        for cat_code, cat_name in CATEGORIES.items():
            context += f"{cat_code}: {cat_name}\n"
            
            # Add subcategories for this category
            if cat_code in SUBCATEGORIES:
                context += "  Subcategories:\n"
                for subcat_code, subcat_name in SUBCATEGORIES[cat_code].items():
                    context += f"    {subcat_code}: {subcat_name}\n"
        
        return context
    
    def detect_duplicates(self, classified_products: List[Dict]) -> List[Dict]:
        """
        Check for duplicates using the 6-key strategy with PostgreSQL dictionary
        """
        for product in classified_products:
            # Check if duplicate exists in database
            duplicate_result = self.db.check_duplicate_by_keys(
                product['hash_keys'],
                self.config['key_weights']
            )
            
            if duplicate_result:
                # Found duplicate
                group_id, similarity = duplicate_result
                product['duplicate_group_id'] = group_id
                product['similarity_score'] = similarity
                product['is_master'] = False
            else:
                # New unique product
                new_group_id = self.db.get_next_group_id()
                product['duplicate_group_id'] = new_group_id
                product['similarity_score'] = 1.0
                product['is_master'] = True
        
        return classified_products
    
    def estimate_api_cost(self, input_tokens: int, output_tokens: int) -> float:
        """Estimate GPT-5 API cost"""
        # GPT-5 pricing with high reasoning (based on documentation)
        input_cost_per_1k = 0.015  # $15 per 1M input tokens
        output_cost_per_1k = 0.060  # $60 per 1M output tokens
        
        total_cost = (input_tokens / 1000 * input_cost_per_1k) + \
                    (output_tokens / 1000 * output_cost_per_1k)
        
        return round(total_cost, 4)

# Normalization utilities from old-code.py
def normalize_product_name(name: str) -> str:
    """
    Apply normalization rules from old-code.py
    This is a fallback for when GPT-5 normalization needs validation
    """
    normalized = name.lower()
    
    # Remove accents
    normalized = ''.join(
        c for c in unicodedata.normalize('NFD', normalized)
        if unicodedata.category(c) != 'Mn'
    )
    
    # Common replacements
    replacements = {
        'pol': 'mm',
        'polegada': 'mm',
        '"': 'mm',
        '1/2': '12.7',
        '1/4': '6.35',
        '3/4': '19.05',
        '3/8': '9.525',
        '5/8': '15.875',
        'sext': 'sextavado',
        'chav': 'chave',
        'p/': 'para'
    }
    
    for old, new in replacements.items():
        normalized = normalized.replace(old, new)
    
    # Remove multiple spaces
    normalized = ' '.join(normalized.split())
    
    return normalized