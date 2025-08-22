import anthropic
import re
import time
import os
from typing import Dict, Optional, Tuple
from dotenv import load_dotenv

load_dotenv()

class MROClassifier:
    def __init__(self):
        api_key = os.getenv('CLAUDE_API_KEY')
        if not api_key:
            raise ValueError("CLAUDE_API_KEY not found in .env file")
        
        self.client = anthropic.Anthropic(api_key=api_key)
        self.setup_taxonomy()
        
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
        
        # Level 3: Subcategories (170 subcategorias)
        self.subcategories_by_cat = {
            "S09": {  # BARRAS E CHAPAS
                "C037": "Barras de aço",
                "C060": "Chapas",
                "C114": "Ferros Chatos",
                "C190": "Formas",
                "C201": "Hastes",
                "C229": "Tarugos"
            },
            "S17": {  # BATERIAS
                "C001": "Baterias lítio",
                "C056": "Baterias níquel",
                "C110": "Baterias tracionárias",
                "C187": "Outras baterias"
            },
            "S25": {  # BOMBAS E MOTORES
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
            "S36": {  # CORRENTES METÁLICAS E ENGRENAGENS
                "C042": "Correntes",
                "C095": "Emendas",
                "C145": "Engrenagens",
                "C175": "Manilhas",
                "C221": "Olhal",
                "C247": "Outras correntes e engrenagens",
                "C268": "Engates"
            },
            "S39": {  # ELEMENTOS DE FIXAÇÃO E VEDAÇÃO
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
            "S41": {  # FERRAMENTAS
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
            "S43": {  # MATERIAIS DIVERSOS
                "C028": "Lonas e toldos",
                "C082": "Outros materiais MRO",
                "C772": "Adubos e fertilizantes"
            },
            "S46": {  # MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS
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
            "S47": {  # MATERIAIS ELÉTRICOS E ELETRÔNICOS
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
            "S49": {  # LUBRIFICANTES
                "C048": "Aditivos",
                "C103": "Graxas",
                "C150": "Óleos lubrificantes",
                "C183": "Outros fluidos"
            },
            "S51": {  # PARTES MECÂNICAS, ROLAMENTOS E CORREIAS
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
            "S54": {  # TUBOS E CONEXÕES
                "C051": "Conexões",
                "C097": "Cotovelos",
                "C152": "Joelhos",
                "C178": "Luvas",
                "C224": "Niples PVC",
                "C249": "Tubos",
                "C278": "União"
            },
            "S71": {  # AUTOMAÇÃO INDUSTRIAL
                "C716": "Conexões",
                "C717": "Engates",
                "C718": "Esteira",
                "C719": "Filtros",
                "C720": "Mangueiras",
                "C721": "Outros materiais de automação industrial",
                "C722": "Válvulas",
                "C723": "Ventosas"
            },
            "S72": {  # EMBALAGENS
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
            "S73": {  # ILUMINAÇÃO
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
            "S74": {  # QUÍMICOS INDUSTRIAIS
                "C782": "Ácidos",
                "C783": "Gases",
                "C784": "Metais químicos",
                "C785": "Químicos inorgânicos",
                "C786": "Químicos orgânicos",
                "C787": "Reagentes químicos",
                "C788": "Solventes"
            }
        }
    
    def claude_classify(self, prompt: str, pattern: str, max_retries: int = 5) -> str:
        """Call Claude API with exponential backoff retry"""
        backoff = 1
        
        for attempt in range(1, max_retries + 1):
            try:
                # Call Claude API
                message = self.client.messages.create(
                    model="claude-sonnet-4-20250514",  # Using Claude Sonnet 4
                    max_tokens=100,
                    temperature=0.1,
                    messages=[
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ]
                )
                
                text = message.content[0].text.strip()
                
                # Extract code using regex
                m = re.search(pattern, text)
                if m and m.group():
                    return m.group()
                else:
                    return None
                    
            except anthropic.RateLimitError:
                print(f"[WARNING] Rate limit hit, attempt {attempt}/{max_retries}, waiting {backoff}s...")
                time.sleep(backoff)
                backoff *= 2
                
            except Exception as e:
                print(f"[WARNING] Error in attempt {attempt}/{max_retries}: {e}")
                if attempt == max_retries:
                    return None
                time.sleep(backoff)
                backoff *= 2
        
        return None
    
    def classify_department(self, product: str) -> Tuple[str, str]:
        """For MRO, always returns D03"""
        return 'D03', self.departments['D03']
    
    def classify_category(self, product: str, dept: str) -> Tuple[str, str]:
        """Classify product into one of 16 MRO categories"""
        cats = self.categories_by_dept.get(dept, {})
        if not cats:
            return '', ''
        
        choices = "\n".join(f"- {code}: {name}" for code, name in cats.items())
        
        prompt = f"""Classifique este produto MRO em UMA categoria. Responda APENAS o código da categoria (formato SXX).

PRODUTO: {product}
DEPARTAMENTO: D03 - MRO: MATERIAL, REPARO E OPERAÇÃO

CATEGORIAS DISPONÍVEIS:
{choices}

GUIA DE CLASSIFICAÇÃO MRO:
- S09 (BARRAS E CHAPAS): Materiais estruturais em metal
- S17 (BATERIAS): Baterias de todos os tipos
- S25 (BOMBAS E MOTORES): Equipamentos de bombeamento e motores
- S36 (CORRENTES METÁLICAS E ENGRENAGENS): Transmissão mecânica
- S39 (ELEMENTOS DE FIXAÇÃO E VEDAÇÃO): Parafusos, juntas, vedações
- S41 (FERRAMENTAS): Ferramentas manuais e elétricas
- S43 (MATERIAIS DIVERSOS): Materiais que não se encaixam nas outras
- S46 (MATERIAIS HIDRÁULICOS, PNEUMÁTICOS): Sistemas hidráulicos/pneumáticos
- S47 (MATERIAIS ELÉTRICOS E ELETRÔNICOS): Componentes elétricos
- S49 (LUBRIFICANTES): Óleos, graxas e fluidos
- S51 (PARTES MECÂNICAS, ROLAMENTOS): Componentes mecânicos
- S54 (TUBOS E CONEXÕES): Tubulações e conexões
- S71 (AUTOMAÇÃO INDUSTRIAL): Equipamentos de automação
- S72 (EMBALAGENS): Materiais de embalagem
- S73 (ILUMINAÇÃO): Lâmpadas e luminárias
- S74 (QUÍMICOS INDUSTRIAIS): Produtos químicos

Responda APENAS o código (exemplo: S41):"""
        
        cat = self.claude_classify(prompt, r"S\d{2}")
        
        if cat and cat in cats:
            return cat, cats[cat]
        else:
            # Intelligent fallback based on keywords
            product_lower = product.lower()
            
            if any(word in product_lower for word in ['parafuso', 'porca', 'junta', 'vedação']):
                return 'S39', cats.get('S39', '')
            elif any(word in product_lower for word in ['ferramenta', 'chave', 'furadeira']):
                return 'S41', cats.get('S41', '')
            elif any(word in product_lower for word in ['disjuntor', 'rele', 'contator', 'modulo']):
                return 'S47', cats.get('S47', '')
            elif any(word in product_lower for word in ['automação', 'clp', 'simatic']):
                return 'S71', cats.get('S71', '')
            else:
                return 'S43', cats.get('S43', '')
    
    def classify_subcategory(self, product: str, cat: str) -> Tuple[str, str]:
        """Classify product into subcategory"""
        subs = self.subcategories_by_cat.get(cat, {})
        if not subs:
            return '', ''
        
        choices = "\n".join(f"- {code}: {name}" for code, name in subs.items())
        cat_name = self.categories_by_dept.get('D03', {}).get(cat, cat)
        
        prompt = f"""O produto MRO foi classificado na categoria {cat} - {cat_name}.

PRODUTO: {product}
CATEGORIA: {cat} - {cat_name}

Escolha a subcategoria mais específica. Responda APENAS o código (formato CXXX).

SUBCATEGORIAS DISPONÍVEIS:
{choices}

Analise o produto considerando:
- Erros de digitação e abreviações
- Função principal do produto
- Contexto de manutenção industrial

Responda APENAS o código (exemplo: C308):"""
        
        sub = self.claude_classify(prompt, r"C\d{3}")
        
        if sub and sub in subs:
            return sub, subs[sub]
        else:
            # Fallback to "Others" subcategory for the category
            fallback_map = {
                'S39': 'C291',  # Outros elementos de fixação
                'S41': 'C134',  # Outras ferramentas manuais
                'S43': 'C082',  # Outros materiais MRO
                'S46': 'C390',  # Outros materiais hidráulicos
                'S47': 'C290',  # Outros materiais elétricos
                'S49': 'C183',  # Outros fluidos
                'S51': 'C253',  # Outros componentes mecânicos
                'S71': 'C721',  # Outros materiais de automação
                'S73': 'C214',  # Outros objetos de iluminação
            }
            
            fallback_code = fallback_map.get(cat, list(subs.keys())[0] if subs else '')
            return fallback_code, subs.get(fallback_code, '')
    
    def classify_product(self, product_name: str, batch_id: int = None) -> Dict:
        """Complete classification pipeline for a single product"""
        result = {
            'product_name': product_name,
            'batch_id': batch_id,
            'confidence': 0.0
        }
        
        try:
            # Step 1: Department (always D03 for MRO)
            dept_code, dept_name = self.classify_department(product_name)
            result['dept_code'] = dept_code
            result['dept_name'] = dept_name
            
            # Step 2: Category
            cat_code, cat_name = self.classify_category(product_name, dept_code)
            result['cat_code'] = cat_code
            result['cat_name'] = cat_name
            
            # Step 3: Subcategory
            if cat_code:
                sub_code, sub_name = self.classify_subcategory(product_name, cat_code)
                result['sub_code'] = sub_code
                result['sub_name'] = sub_name
            else:
                result['sub_code'] = ''
                result['sub_name'] = ''
            
            # Calculate confidence based on successful classifications
            confidence = 0.33  # Base for department
            if cat_code:
                confidence += 0.33
            if result['sub_code']:
                confidence += 0.34
            result['confidence'] = confidence
            
            return result
            
        except Exception as e:
            print(f"[ERROR] Error classifying product '{product_name}': {e}")
            result['error'] = str(e)
            return result