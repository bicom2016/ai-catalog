"""
MRO Taxonomy extracted from old-code.py
Complete hierarchy: Department -> Category -> Subcategory
"""

# Department (only D03 for MRO)
DEPARTMENTS = {
    "D03": "MRO: MATERIAL, REPARO E OPERAÇÃO"
}

# Level 2: Categories for D03 (16 categories)
CATEGORIES = {
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

# Level 3: Subcategories by category (170 total)
SUBCATEGORIES = {
    "S09": {  # BARRAS E CHAPAS (6 subcategorias)
        "C037": "Barras de aço",
        "C060": "Chapas",
        "C114": "Ferros Chatos",
        "C190": "Formas",
        "C201": "Hastes",
        "C229": "Tarugos"
    },
    "S17": {  # BATERIAS (4 subcategorias)
        "C001": "Baterias lítio",
        "C056": "Baterias níquel",
        "C110": "Baterias tracionárias",
        "C187": "Outras baterias"
    },
    "S25": {  # BOMBAS E MOTORES (10 subcategorias)
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
    "S36": {  # CORRENTES METÁLICAS E ENGRENAGENS (7 subcategorias)
        "C042": "Correntes",
        "C095": "Emendas",
        "C145": "Engrenagens",
        "C175": "Manilhas",
        "C221": "Olhal",
        "C247": "Outras correntes e engrenagens",
        "C268": "Engates"
    },
    "S39": {  # ELEMENTOS DE FIXAÇÃO E VEDAÇÃO (11 subcategorias)
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
    "S41": {  # FERRAMENTAS (22 subcategorias)
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
    "S43": {  # MATERIAIS DIVERSOS (3 subcategorias)
        "C028": "Lonas e toldos",
        "C082": "Outros materiais MRO",
        "C772": "Adubos e fertilizantes"
    },
    "S46": {  # MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS (19 subcategorias)
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
    "S47": {  # MATERIAIS ELÉTRICOS E ELETRÔNICOS (21 subcategorias)
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
    "S49": {  # LUBRIFICANTES (4 subcategorias)
        "C048": "Aditivos",
        "C103": "Graxas",
        "C150": "Óleos lubrificantes",
        "C183": "Outros fluidos"
    },
    "S51": {  # PARTES MECÂNICAS, ROLAMENTOS E CORREIAS (10 subcategorias)
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
    "S54": {  # TUBOS E CONEXÕES (7 subcategorias)
        "C051": "Conexões",
        "C097": "Cotovelos",
        "C152": "Joelhos",
        "C178": "Luvas",
        "C224": "Niples PVC",
        "C249": "Tubos",
        "C278": "União"
    },
    "S71": {  # AUTOMAÇÃO INDUSTRIAL (8 subcategorias)
        "C716": "Conexões",
        "C717": "Engates",
        "C718": "Esteira",
        "C719": "Filtros",
        "C720": "Mangueiras",
        "C721": "Outros materiais de automação industrial",
        "C722": "Válvulas",
        "C723": "Ventosas"
    },
    "S72": {  # EMBALAGENS (15 subcategorias)
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
    "S73": {  # ILUMINAÇÃO (17 subcategorias)
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
    "S74": {  # QUÍMICOS INDUSTRIAIS (7 subcategorias)
        "C782": "Ácidos",
        "C783": "Gases",
        "C784": "Metais químicos",
        "C785": "Químicos inorgânicos",
        "C786": "Químicos orgânicos",
        "C787": "Reagentes químicos",
        "C788": "Solventes"
    }
}

def get_taxonomy_summary():
    """Get summary statistics of the taxonomy"""
    total_subcategories = sum(len(subs) for subs in SUBCATEGORIES.values())
    
    return {
        "departments": len(DEPARTMENTS),
        "categories": len(CATEGORIES),
        "subcategories": total_subcategories,
        "avg_subcategories_per_category": total_subcategories / len(CATEGORIES),
        "max_subcategories": max(len(subs) for subs in SUBCATEGORIES.values()),
        "min_subcategories": min(len(subs) for subs in SUBCATEGORIES.values())
    }

def get_category_by_subcategory(subcategory_code: str) -> str:
    """Find which category a subcategory belongs to"""
    for cat_code, subcats in SUBCATEGORIES.items():
        if subcategory_code in subcats:
            return cat_code
    return None

def get_full_classification(category_code: str, subcategory_code: str) -> dict:
    """Get complete classification details"""
    return {
        "department_code": "D03",
        "department_name": DEPARTMENTS["D03"],
        "category_code": category_code,
        "category_name": CATEGORIES.get(category_code, "Unknown"),
        "subcategory_code": subcategory_code,
        "subcategory_name": SUBCATEGORIES.get(category_code, {}).get(subcategory_code, "Unknown")
    }

# Export for easy access
__all__ = [
    'DEPARTMENTS',
    'CATEGORIES', 
    'SUBCATEGORIES',
    'get_taxonomy_summary',
    'get_category_by_subcategory',
    'get_full_classification'
]