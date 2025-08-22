"""
MRO Classifier with Claude Prompt Caching
Optimized for batch processing with cached taxonomy
"""

import anthropic
import re
import time
import os
import json
from typing import Dict, List, Optional, Tuple
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

class CachedMROClassifier:
    def __init__(self):
        api_key = os.getenv('CLAUDE_API_KEY')
        if not api_key:
            raise ValueError("CLAUDE_API_KEY not found in .env file")
        
        self.client = anthropic.Anthropic(api_key=api_key)
        self.setup_taxonomy()
        self.cache_stats = {
            'cache_writes': 0,
            'cache_reads': 0,
            'tokens_cached': 0,
            'tokens_saved': 0,
            'api_calls': 0,
            'total_time': 0
        }
        
    def setup_taxonomy(self):
        """Initialize MRO taxonomy from old-code.py"""
        # Departments (apenas D03 para MRO)
        self.departments = {
            "D03": "MRO: MATERIAL, REPARO E OPERAÇÃO"
        }
        
        # Level 2: Categories for D03 (16 categorias)
        self.categories_by_dept = {
            "D03": {
                "S09": "BARRAS E CHAPAS",
                "S17": "BATERIAS",
                "S25": "BOMBAS E MOTORES",
                "S36": "CORRENTES METÁLICAS E ENGRENAGENS",
                "S39": "ELEMENTOS DE FIXAÇÃO E VEDAÇÃO",
                "S41": "FERRAMENTAS",
                "S43": "MATERIAIS DIVERSOS",
                "S46": "MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS",
                "S47": "MATERIAIS ELÉTRICOS E ELETRÔNICOS",
                "S49": "LUBRIFICANTES",
                "S51": "PARTES MECÂNICAS, ROLAMENTOS E CORREIAS",
                "S54": "TUBOS E CONEXÕES",
                "S71": "AUTOMAÇÃO INDUSTRIAL",
                "S72": "EMBALAGENS",
                "S73": "ILUMINAÇÃO",
                "S74": "QUÍMICOS INDUSTRIAIS"
            }
        }
        
        # Level 3: Subcategories (170 subcategorias) - Full taxonomy
        self.subcategories_by_cat = {
            "S09": {
                "C037": "Barras de aço",
                "C060": "Chapas",
                "C114": "Ferros Chatos",
                "C190": "Formas",
                "C201": "Hastes",
                "C229": "Tarugos"
            },
            "S17": {
                "C001": "Baterias lítio",
                "C056": "Baterias níquel",
                "C110": "Baterias tracionárias",
                "C187": "Outras baterias"
            },
            "S25": {
                "C002": "Bombas",
                "C057": "Chaves e compressores",
                "C111": "Hélices",
                "C188": "Juntas para bomba",
                "C199": "Motobombas",
                "C228": "Motores",
                "C274": "Motovibradores",
                "C293": "Outros componentes bombas e motores",
                "C311": "Rotores",
                "C326": "Servomotores"
            },
            "S36": {
                "C042": "Correntes",
                "C095": "Emendas",
                "C145": "Engrenagens",
                "C175": "Manilhas",
                "C221": "Olhal",
                "C247": "Outras correntes e engrenagens",
                "C268": "Engates"
            },
            "S39": {
                "C026": "Acoplamentos",
                "C080": "Adesivos e fitas",
                "C133": "Anéis elásticos",
                "C164": "Chumbadores",
                "C215": "Eletrodos de soldas",
                "C241": "Gaxetas",
                "C270": "Juntas de vedação",
                "C291": "Outros elementos de fixação e vedação",
                "C297": "Retentores",
                "C308": "Parafusos, pregos, porcas, buchas e arruelas",
                "C325": "Rebites e pinos"
            },
            "S41": {
                "C027": "Abrasivos",
                "C081": "Ferramentas de corte e desbaste",
                "C134": "Outras ferramentas manuais",
                "C165": "Ferramentas para construção civil",
                "C216": "Ferramentas perfuradoras",
                "C739": "Acessórios e consumíveis para ferramentas",
                "C740": "Alicates",
                "C741": "Chave allen/hexagonal",
                "C742": "Chave biela",
                "C743": "Chave combinada",
                "C744": "Chave de fenda e Phillips",
                "C745": "Ferramentas a bateria",
                "C746": "Ferramentas automotivas",
                "C747": "Ferramentas de medição",
                "C748": "Ferramentas elétricas",
                "C749": "Ferramentas para jardim",
                "C750": "Ferramentas para pintura",
                "C751": "Ferramentas para solda",
                "C752": "Jogos de chave combinada",
                "C753": "Jogos de ferramentas",
                "C754": "Jogos de soquetes",
                "C755": "Torquímetro"
            },
            "S43": {
                "C028": "Lonas e toldos",
                "C082": "Outros materiais MRO",
                "C772": "Adubos e fertilizantes"
            },
            "S46": {
                "C029": "Adaptadores, conexões e terminais",
                "C083": "Amortecedor",
                "C135": "Atuador pneumático",
                "C166": "Balancin",
                "C217": "Cilindros",
                "C242": "Eletroválvulas",
                "C289": "Engates rápidos",
                "C307": "Filtros de água",
                "C324": "Filtros de ar",
                "C337": "Filtros de gás",
                "C346": "Filtros industriais",
                "C358": "Flanges",
                "C366": "Luvas hidráulicas",
                "C377": "Mangueiras hidráulicas e industriais",
                "C390": "Outros materiais hidráulicos ou pneumáticos",
                "C395": "União",
                "C400": "Válvulas",
                "C719": "Filtros",
                "C722": "Válvulas"
            },
            "S47": {
                "C025": "Amplificadores",
                "C079": "Conduletes",
                "C132": "Fontes de energia",
                "C163": "Fusíveis e disjuntores",
                "C240": "Módulos",
                "C269": "Outros componentes eletrônicos",
                "C290": "Outros materiais elétricos",
                "C314": "Plugs e adaptadores",
                "C329": "Resistências",
                "C340": "Terminais",
                "C350": "Tomadas e interruptores",
                "C360": "Transformadores",
                "C773": "Cabos e fios elétricos",
                "C774": "Chaves magnéticas",
                "C775": "Contatores",
                "C776": "Energia solar",
                "C777": "Extensões elétricas e filtros de linha",
                "C778": "Ferramentas de eletricista",
                "C779": "Quadros e caixas elétricas",
                "C780": "Reatores e soquetes",
                "C781": "Tubos e eletrodutos"
            },
            "S49": {
                "C048": "Aditivos",
                "C103": "Graxas",
                "C150": "Óleos lubrificantes",
                "C183": "Outros fluidos"
            },
            "S51": {
                "C049": "Amortecedores",
                "C104": "Antiderrapantes para correias",
                "C151": "Correias e componentes",
                "C184": "Mancal",
                "C223": "Molas",
                "C253": "Outros componentes de partes mecânicas",
                "C275": "Polias",
                "C315": "Rolamentos",
                "C330": "Tensores de correias",
                "C382": "Molas"
            },
            "S54": {
                "C051": "Conexões",
                "C097": "Cotovelos",
                "C152": "Joelhos",
                "C178": "Luvas",
                "C224": "Niples PVC",
                "C249": "Tubos",
                "C278": "União"
            },
            "S71": {
                "C716": "Conexões",
                "C717": "Engates",
                "C718": "Esteira",
                "C719": "Filtros",
                "C720": "Mangueiras",
                "C721": "Outros materiais de automação industrial",
                "C722": "Válvulas",
                "C723": "Ventosas"
            },
            "S72": {
                "C724": "Bobinas kraft ou semi kraft",
                "C725": "Caixas de papelão",
                "C726": "Embalagens descartáveis",
                "C727": "Embalagens para delivery",
                "C728": "Envelopes de segurança",
                "C729": "Etiquetas e tags",
                "C730": "Filme stretch",
                "C731": "Fitas adesivas",
                "C732": "Fitas, laços e cordões",
                "C733": "Lacres",
                "C734": "Latas",
                "C735": "Pallets",
                "C736": "Potes e vidros",
                "C737": "Sacos e sacolas kraft",
                "C738": "Sacos e sacolas plásticas"
            },
            "S73": {
                "C214": "Outros objetos de iluminação",
                "C756": "Abajures e cúpulas",
                "C757": "Cordões de luz",
                "C758": "Fitas de LED",
                "C759": "Kits de lâmpadas",
                "C760": "Lâmpadas de LED",
                "C761": "Lâmpadas fluorescentes",
                "C762": "Lâmpadas halógenas",
                "C763": "Lâmpadas incandescentes",
                "C764": "Lâmpadas inteligentes",
                "C765": "Luminárias",
                "C766": "Lustres e pendentes",
                "C767": "Outros tipos de lâmpadas",
                "C768": "Painel de LED",
                "C769": "Refletores",
                "C770": "Soquetes para lâmpadas",
                "C771": "Spots"
            },
            "S74": {
                "C782": "Ácidos",
                "C783": "Gases",
                "C784": "Metais químicos",
                "C785": "Químicos inorgânicos",
                "C786": "Químicos orgânicos",
                "C787": "Reagentes químicos",
                "C788": "Solventes"
            }
        }
    
    def get_taxonomy_context(self) -> str:
        """Build complete taxonomy context for caching"""
        context = "MRO TAXONOMY REFERENCE:\n\n"
        
        # Add categories
        context += "CATEGORIES:\n"
        for code, name in self.categories_by_dept["D03"].items():
            context += f"{code}: {name}\n"
            
        context += "\nSUBCATEGORIES BY CATEGORY:\n"
        for cat_code, subcats in self.subcategories_by_cat.items():
            cat_name = self.categories_by_dept["D03"].get(cat_code, "")
            context += f"\n{cat_code} - {cat_name}:\n"
            for sub_code, sub_name in subcats.items():
                context += f"  {sub_code}: {sub_name}\n"
        
        return context
    
    def classify_batch_with_cache(self, products: List[Dict], batch_size: int = 10) -> List[Dict]:
        """
        Classify products in batches using prompt caching
        """
        results = []
        total_products = len(products)
        taxonomy_context = self.get_taxonomy_context()
        
        print(f"\n[CACHE] Starting batch classification with prompt caching")
        print(f"[CACHE] Total products to classify: {total_products}")
        print(f"[CACHE] Batch size: {batch_size}")
        
        for i in range(0, total_products, batch_size):
            batch = products[i:i + batch_size]
            batch_num = (i // batch_size) + 1
            total_batches = (total_products + batch_size - 1) // batch_size
            
            print(f"\n[CACHE] Processing batch {batch_num}/{total_batches}")
            
            # Prepare batch for classification
            product_list = "\n".join([
                f"{j+1}. {p['product_name']}" 
                for j, p in enumerate(batch)
            ])
            
            start_time = time.time()
            
            try:
                # Make API call with caching
                message = self.client.messages.create(
                    model="claude-sonnet-4-20250514",
                    max_tokens=1500,
                    temperature=0.1,
                    system=[
                        {
                            "type": "text",
                            "text": taxonomy_context,
                            "cache_control": {"type": "ephemeral"}  # Cache the taxonomy
                        }
                    ],
                    messages=[
                        {
                            "role": "user",
                            "content": f"""Classify these MRO products using the taxonomy provided.

Products to classify:
{product_list}

For each product, provide:
1. Category code (SXX format)
2. Category name
3. Subcategory code (CXXX format)
4. Subcategory name
5. Confidence (0.0-1.0)

Return as JSON array:
[
  {{
    "product_number": 1,
    "category_code": "SXX",
    "category_name": "...",
    "subcategory_code": "CXXX",
    "subcategory_name": "...",
    "confidence": 0.95
  }},
  ...
]"""
                        }
                    ],
                    extra_headers={"anthropic-beta": "prompt-caching-2024-07-31"}
                )
                
                elapsed_time = time.time() - start_time
                
                # Parse response
                response_text = message.content[0].text
                
                # Extract JSON from response
                json_match = re.search(r'\[.*\]', response_text, re.DOTALL)
                if json_match:
                    classifications = json.loads(json_match.group())
                    
                    # Map classifications back to products
                    for j, classification in enumerate(classifications):
                        if j < len(batch):
                            product = batch[j]
                            results.append({
                                'id': product['id'],
                                'product_name': product['product_name'],
                                'dept_code': 'D03',
                                'dept_name': self.departments['D03'],
                                'cat_code': classification.get('category_code', ''),
                                'cat_name': classification.get('category_name', ''),
                                'sub_code': classification.get('subcategory_code', ''),
                                'sub_name': classification.get('subcategory_name', ''),
                                'confidence': classification.get('confidence', 0.8),
                                'batch_id': batch_num
                            })
                
                # Update cache statistics
                self.cache_stats['api_calls'] += 1
                self.cache_stats['total_time'] += elapsed_time
                
                # Check cache usage
                if hasattr(message.usage, 'cache_creation_input_tokens'):
                    cache_write = message.usage.cache_creation_input_tokens
                    self.cache_stats['cache_writes'] += 1 if cache_write > 0 else 0
                    self.cache_stats['tokens_cached'] += cache_write
                    
                if hasattr(message.usage, 'cache_read_input_tokens'):
                    cache_read = message.usage.cache_read_input_tokens
                    self.cache_stats['cache_reads'] += 1 if cache_read > 0 else 0
                    self.cache_stats['tokens_saved'] += cache_read
                
                # Calculate cache efficiency
                total_input = message.usage.input_tokens
                cache_percentage = (cache_read / total_input * 100) if cache_read and total_input else 0
                
                print(f"  [OK] Batch {batch_num} completed in {elapsed_time:.2f}s")
                print(f"    Cache hit: {cache_percentage:.1f}% of input tokens")
                print(f"    Products classified: {len(batch)}")
                
            except Exception as e:
                print(f"  [ERROR] Error in batch {batch_num}: {e}")
                # Add error results for this batch
                for product in batch:
                    results.append({
                        'id': product['id'],
                        'product_name': product['product_name'],
                        'error': str(e)
                    })
            
            # Rate limiting
            if i + batch_size < total_products:
                time.sleep(1)
        
        # Print final statistics
        self.print_cache_statistics()
        
        return results
    
    def print_cache_statistics(self):
        """Print cache usage statistics"""
        print("\n" + "="*60)
        print("CACHE STATISTICS")
        print("="*60)
        print(f"API Calls: {self.cache_stats['api_calls']}")
        print(f"Cache Writes: {self.cache_stats['cache_writes']}")
        print(f"Cache Reads: {self.cache_stats['cache_reads']}")
        print(f"Tokens Cached: {self.cache_stats['tokens_cached']:,}")
        print(f"Tokens Saved: {self.cache_stats['tokens_saved']:,}")
        print(f"Total Time: {self.cache_stats['total_time']:.2f}s")
        
        if self.cache_stats['api_calls'] > 0:
            avg_time = self.cache_stats['total_time'] / self.cache_stats['api_calls']
            print(f"Average Time per Call: {avg_time:.2f}s")
        
        # Estimate cost savings
        if self.cache_stats['tokens_saved'] > 0:
            # Claude Sonnet pricing (approximate)
            regular_cost = (self.cache_stats['tokens_cached'] + self.cache_stats['tokens_saved']) * 0.003 / 1000
            cached_cost = self.cache_stats['tokens_cached'] * 0.003 / 1000 + self.cache_stats['tokens_saved'] * 0.0003 / 1000
            savings = regular_cost - cached_cost
            savings_percentage = (savings / regular_cost * 100) if regular_cost > 0 else 0
            
            print(f"\nCost Analysis:")
            print(f"  Regular Cost: ${regular_cost:.4f}")
            print(f"  Cached Cost: ${cached_cost:.4f}")
            print(f"  Savings: ${savings:.4f} ({savings_percentage:.1f}%)")