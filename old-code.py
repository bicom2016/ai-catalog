# Classificador Hierárquico MRO - Versão com Claude API
!pip install -q -U anthropic gspread oauth2client

from google.colab import auth
import gspread
from google.auth import default
import json
import time
import re
import anthropic
from google.colab import userdata

# Imports para tratamento de exceções da API
import requests

# Autentica no Google Sheets
auth.authenticate_user()
creds, _ = default()
gc = gspread.authorize(creds)

# Abra sua planilha MRO
SPREADSHEET_ID = '111KAtipHv5azxsIKLkyJ1K3xw_XIdwwcUjS8LDYwZxA'

try:
    spreadsheet = gc.open_by_key(SPREADSHEET_ID)
    worksheet = spreadsheet.get_worksheet(0)  # Primeira aba
    print(f"✅ Planilha MRO '{SPREADSHEET_ID}' aberta com sucesso.")
except Exception as e:
    print(f"❌ ERRO ao abrir a planilha: {e}")
    raise

# Carrega a API key do Colab Secrets
CLAUDE_API_KEY = userdata.get('CLAUDE_API_KEY')

if not CLAUDE_API_KEY:
    print("❌ ERRO: CLAUDE_API_KEY não encontrada nas secrets do Colab.")
    print("💡 Para configurar: Vá em Secrets (🔑) no painel lateral e adicione:")
    print("   Nome: CLAUDE_API_KEY")
    print("   Valor: sua_api_key_do_claude")
    raise ValueError("API Key não configurada.")

# Inicializar cliente Claude
try:
    client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)
    print(f"✅ Cliente Claude inicializado com sucesso.")
except Exception as e:
    print(f"❌ ERRO ao inicializar cliente Claude: {e}")
    raise

# -----------------------------
# MRO Taxonomy Mappings
# -----------------------------

# Departments (apenas D03 para MRO)
departments = {
    "D03": "MRO: MATERIAL, REPARO E OPERAÇÃO"
}

# Level 2: Categories for D03 (16 categorias)
categories_by_dept = {
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

# Level 3: Subcategories por categoria (170 subcategorias organizadas)
subcategories_by_cat = {
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
    "S39": {  # ELEMENTOS DE FIXAÇÃO E VEDAÇÃO (10 subcategorias)
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

# -----------------------------
# Generic Claude API call with retries
# -----------------------------
def claude_classify(prompt: str, pattern: str, max_retries: int = 5) -> str:
    """Chama Claude API com retry exponencial em caso de rate limits ou erros de conexão"""
    backoff = 1

    for attempt in range(1, max_retries + 1):
        try:
            print(f"[DEBUG] Tentativa {attempt}/{max_retries}")

            # Chamada para Claude API
            message = client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=100,  # Resposta curta, apenas o código
                temperature=0.1,  # Baixa criatividade para consistência
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            )

            text = message.content[0].text.strip()
            print(f"[DEBUG] Resposta bruta: {text}")

            # Extrair código usando regex
            m = re.search(pattern, text)
            if m and m.group():
                extracted_code = m.group()
                print(f"[DEBUG] Código extraído: {extracted_code}")
                return extracted_code
            else:
                print(f"[AVISO] Não foi possível extrair código da resposta: {text}")
                return None

        except anthropic.RateLimitError as e:
            print(f"⚠️ Tentativa {attempt}/{max_retries} falhou (Rate Limit), aguardando {backoff}s...")
            time.sleep(backoff)
            backoff *= 2

        except (requests.exceptions.RequestException, ConnectionError) as e:
            print(f"⚠️ Tentativa {attempt}/{max_retries} falhou (Conexão: {type(e).__name__}), aguardando {backoff}s...")
            time.sleep(backoff)
            backoff *= 2

        except anthropic.APIError as e:
            print(f"⚠️ Tentativa {attempt}/{max_retries} falhou (API Error: {e}), aguardando {backoff}s...")
            time.sleep(backoff)
            backoff *= 2

        except Exception as e:
            print(f"❌ Erro inesperado na tentativa {attempt}/{max_retries}: {e}")
            if attempt == max_retries:
                return None
            time.sleep(backoff)
            backoff *= 2

    print(f"❌ Esgotadas todas as {max_retries} tentativas")
    return None

# -----------------------------
# MRO-specific classification functions
# -----------------------------

def classify_department(product: str) -> str:
    """Para MRO, sempre retorna D03, mas podemos manter a validação"""
    # Como só temos D03, sempre retornamos ele
    # Mas mantemos a função para consistência e futuras expansões
    return 'D03'


def classify_category(product: str, dept: str) -> str:
    """Classifica o produto em uma das 16 categorias MRO"""
    cats = categories_by_dept.get(dept, {})
    if not cats:
        print(f"[INFO] Departamento {dept} não tem categorias mapeadas.")
        return ''

    choices = "\n".join(f"- {code}: {name}" for code, name in cats.items())

    prompt = f"""Classifique este produto MRO em UMA categoria. Responda APENAS o código da categoria (formato SXX).

PRODUTO: {product}
DEPARTAMENTO: D03 - MRO: MATERIAL, REPARO E OPERAÇÃO

CATEGORIAS DISPONÍVEIS:
{choices}

GUIA DE CLASSIFICAÇÃO MRO:
- S09 (BARRAS E CHAPAS): Materiais estruturais em metal - barras, chapas, perfis
- S17 (BATERIAS): Baterias de todos os tipos - lítio, níquel, tracionárias
- S25 (BOMBAS E MOTORES): Equipamentos de bombeamento e motores elétricos
- S36 (CORRENTES METÁLICAS E ENGRENAGENS): Transmissão mecânica - correntes, engrenagens
- S39 (ELEMENTOS DE FIXAÇÃO E VEDAÇÃO): Parafusos, juntas, vedações, elementos de união
- S41 (FERRAMENTAS): Ferramentas manuais e elétricas de todos os tipos
- S43 (MATERIAIS DIVERSOS): Materiais que não se encaixam nas outras categorias
- S46 (MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS): Sistemas hidráulicos/pneumáticos
- S47 (MATERIAIS ELÉTRICOS E ELETRÔNICOS): Componentes elétricos e eletrônicos
- S49 (LUBRIFICANTES): Óleos, graxas e fluidos lubrificantes
- S51 (PARTES MECÂNICAS, ROLAMENTOS E CORREIAS): Componentes mecânicos de transmissão
- S54 (TUBOS E CONEXÕES): Tubulações e conexões para fluidos
- S71 (AUTOMAÇÃO INDUSTRIAL): Equipamentos de automação e controle
- S72 (EMBALAGENS): Materiais de embalagem e acondicionamento
- S73 (ILUMINAÇÃO): Lâmpadas, luminárias e sistemas de iluminação
- S74 (QUÍMICOS INDUSTRIAIS): Produtos químicos para uso industrial

EXEMPLOS:
- "Parafuso sextavado M8" → S39
- "Furadeira elétrica 500W" → S41
- "Óleo hidráulico ISO 46" → S49
- "Lâmpada LED 12V" → S73

Responda APENAS o código (exemplo: S41):"""

    cat = claude_classify(prompt, r"S\d{2}")

    if cat and cat in cats:
        return cat
    else:
        print(f"[FALLBACK] Categoria inválida ou não encontrada. Usando fallback inteligente.")
        # Fallback inteligente baseado em palavras-chave
        product_lower = product.lower()

        # Mapeamento de palavras-chave para categorias
        if any(word in product_lower for word in ['parafuso', 'porca', 'junta', 'vedação', 'gaxeta']):
            return 'S39'  # ELEMENTOS DE FIXAÇÃO E VEDAÇÃO
        elif any(word in product_lower for word in ['ferramenta', 'chave', 'furadeira', 'martelo']):
            return 'S41'  # FERRAMENTAS
        elif any(word in product_lower for word in ['óleo', 'graxa', 'lubrificante']):
            return 'S49'  # LUBRIFICANTES
        elif any(word in product_lower for word in ['lâmpada', 'led', 'luminária']):
            return 'S73'  # ILUMINAÇÃO
        elif any(word in product_lower for word in ['tubo', 'conexão', 'cotovelo']):
            return 'S54'  # TUBOS E CONEXÕES
        else:
            return 'S43'  # MATERIAIS DIVERSOS (fallback genérico)


def classify_subcategoria(product: str, cat: str) -> str:
    """Classifica o produto em uma subcategoria da categoria MRO"""
    subs = subcategories_by_cat.get(cat, {})
    if not subs:
        print(f"[INFO] Categoria {cat} não tem subcategorias mapeadas.")
        return ''

    choices = "\n".join(f"- {code}: {name}" for code, name in subs.items())
    cat_name = categories_by_dept.get('D03', {}).get(cat, cat)

    prompt = f"""O produto MRO foi classificado na categoria {cat} - {cat_name}.

PRODUTO: {product}
CATEGORIA: {cat} - {cat_name}

Escolha a subcategoria mais específica. Responda APENAS o código da subcategoria (formato CXXX).

SUBCATEGORIAS DISPONÍVEIS:
{choices}

INSTRUÇÕES PARA MRO:
- Analise o produto considerando erros de digitação e abreviações comuns
- Foque na função principal do produto, não apenas no nome
- Se o produto tem múltiplas funções, escolha a função primária
- Considere o contexto de manutenção, reparo e operação industrial

EXEMPLOS ESPECÍFICOS POR CATEGORIA:
- Parafusos, porcas, arruelas → C308
- Ferramentas de medição como trenas, calibres → C747
- Óleos para máquinas → C150
- Lâmpadas LED para iluminação → C760
- Conexões hidráulicas → C029

Responda APENAS o código (exemplo: C308):"""

    sub = claude_classify(prompt, r"C\d{3}")

    if sub and sub in subs:
        return sub
    else:
        print(f"[FALLBACK] Subcategoria inválida ou não encontrada. Usando fallback inteligente.")

        # Fallback inteligente baseado na categoria e produto
        product_lower = product.lower()

        # Fallbacks específicos por categoria
        fallback_map = {
            'S39': 'C291',  # Outros elementos de fixação e vedação
            'S41': 'C134',  # Outras ferramentas manuais
            'S43': 'C082',  # Outros materiais MRO
            'S46': 'C390',  # Outros materiais hidráulicos ou pneumáticos
            'S47': 'C290',  # Outros materiais elétricos
            'S49': 'C183',  # Outros fluidos
            'S51': 'C253',  # Outros componentes de partes mecânicas
            'S71': 'C721',  # Outros materiais de automação industrial
            'S73': 'C214',  # Outros objetos de iluminação
        }

        return fallback_map.get(cat, list(subs.keys())[0] if subs else '')

# -----------------------------
# Main processing
# -----------------------------
def main():
    print("🚀 Iniciando processamento dos produtos MRO com Claude API...")

    # Ler produtos da planilha
    try:
        products = worksheet.col_values(1)[1:]  # Pular cabeçalho
        products = [p for p in products if p.strip()]  # Filtrar vazios
        print(f"📊 Total de produtos MRO encontrados: {len(products)}")
    except Exception as e:
        print(f"❌ Erro ao ler produtos: {e}")
        return

    results = []

    for idx, product in enumerate(products):
        print(f"\n{'='*80}")
        print(f"PROCESSANDO PRODUTO MRO {idx+1}/{len(products)}: {product}")
        print(f"{'='*80}")

        # 1ª Classificação: Departamento (sempre D03 para MRO)
        print("🔍 1ª ETAPA: Classificando departamento...")
        dept = classify_department(product)
        dept_name = departments.get(dept, '')
        print(f"✅ Departamento: {dept} - {dept_name}")

        # 2ª Classificação: Categoria
        print("\n🔍 2ª ETAPA: Classificando categoria...")
        cat = classify_category(product, dept)
        cat_name = categories_by_dept.get(dept, {}).get(cat, '') if cat else ''
        if cat:
            print(f"✅ Categoria: {cat} - {cat_name}")
        else:
            print("ℹ️  Sem categoria mapeada para este departamento")

        # 3ª Classificação: Subcategoria
        print("\n🔍 3ª ETAPA: Classificando subcategoria...")
        sub = classify_subcategoria(product, cat) if cat else ''
        sub_name = subcategories_by_cat.get(cat, {}).get(sub, '') if sub else ''
        if sub:
            print(f"✅ Subcategoria: {sub} - {sub_name}")
        else:
            print("ℹ️  Sem subcategoria mapeada para esta categoria")

        # Preparar linha de resultado com IDs e nomes
        result_row = [
            dept, dept_name,  # Colunas B, C
            cat, cat_name,    # Colunas D, E
            sub, sub_name     # Colunas F, G
        ]
        results.append(result_row)

        print(f"\n📝 RESULTADO: {dept} → {cat} → {sub}")

        # Pausa entre produtos para evitar rate limit
        time.sleep(1)  # Claude tem rate limits mais generosos que Gemini

    # Atualização em massa da planilha
    print(f"\n{'='*80}")
    print("💾 ATUALIZANDO PLANILHA...")
    print(f"{'='*80}")

    try:
        # Atualizar colunas B até G (ID Departamento até Subcategoria)
        update_range = f"B2:G{len(results) + 1}"
        worksheet.update(values=results, range_name=update_range)
        print("✅ Planilha atualizada com sucesso!")

        # Estatísticas MRO
        print(f"\n📈 ESTATÍSTICAS MRO:")

        # Contar departamentos, categorias e subcategorias
        dept_counts = {}
        cat_counts = {}
        sub_counts = {}

        for row in results:
            dept_id = row[0]
            cat_id = row[2] if len(row) > 2 else ''
            sub_id = row[4] if len(row) > 4 else ''

            if dept_id:
                dept_counts[dept_id] = dept_counts.get(dept_id, 0) + 1
            if cat_id:
                cat_counts[cat_id] = cat_counts.get(cat_id, 0) + 1
            if sub_id:
                sub_counts[sub_id] = sub_counts.get(sub_id, 0) + 1

        print(f"\n🏢 DEPARTAMENTO:")
        for dept_id, count in sorted(dept_counts.items()):
            dept_name = departments.get(dept_id, 'Desconhecido')
            pct = (count / len(results)) * 100
            print(f"  {dept_id} ({dept_name}): {count} produtos ({pct:.1f}%)")

        if cat_counts:
            print(f"\n📂 TOP 10 CATEGORIAS MRO:")
            sorted_cats = sorted(cat_counts.items(), key=lambda x: x[1], reverse=True)[:10]
            for cat_id, count in sorted_cats:
                cat_name = categories_by_dept.get('D03', {}).get(cat_id, 'Desconhecida')
                pct = (count / len(results)) * 100
                print(f"  {cat_id} ({cat_name}): {count} produtos ({pct:.1f}%)")

        if sub_counts:
            print(f"\n📁 TOP 15 SUBCATEGORIAS MRO:")
            sorted_subs = sorted(sub_counts.items(), key=lambda x: x[1], reverse=True)[:15]
            for sub_id, count in sorted_subs:
                # Encontrar nome da subcategoria
                sub_name = 'Desconhecida'
                for cat_subs in subcategories_by_cat.values():
                    if sub_id in cat_subs:
                        sub_name = cat_subs[sub_id]
                        break
                pct = (count / len(results)) * 100
                print(f"  {sub_id} ({sub_name}): {count} produtos ({pct:.1f}%)")

        # Estatísticas específicas para MRO
        print(f"\n🔧 ANÁLISE POR CATEGORIA MRO:")
        mro_analysis = {}
        for cat_id, count in cat_counts.items():
            cat_name = categories_by_dept.get('D03', {}).get(cat_id, 'Desconhecida')
            subcats_count = len([sub for sub in sub_counts.keys()
                               if any(sub in subcategories_by_cat.get(cat_id, {})
                                     for cat_id in categories_by_dept.get('D03', {}).keys())])
            mro_analysis[cat_id] = {
                'name': cat_name,
                'products': count,
                'percentage': (count / len(results)) * 100
            }

        # Mostrar categorias mais utilizadas
        top_categories = sorted(mro_analysis.items(),
                              key=lambda x: x[1]['products'], reverse=True)[:5]

        print(f"\n🏆 TOP 5 CATEGORIAS MRO MAIS UTILIZADAS:")
        for cat_id, data in top_categories:
            print(f"  {cat_id}: {data['name']} - {data['products']} produtos ({data['percentage']:.1f}%)")

        # Análise de diversidade
        total_categories_used = len(cat_counts)
        total_subcategories_used = len(sub_counts)
        print(f"\n📊 DIVERSIDADE MRO:")
        print(f"  Categorias utilizadas: {total_categories_used}/16 ({(total_categories_used/16)*100:.1f}%)")
        print(f"  Subcategorias utilizadas: {total_subcategories_used}/170 ({(total_subcategories_used/170)*100:.1f}%)")

    except Exception as e:
        print(f"❌ Erro ao atualizar planilha: {e}")
        return

    print(f"\n🎉 PROCESSAMENTO MRO CONCLUÍDO COM SUCESSO!")
    print(f"Total de produtos MRO processados: {len(results)}")
    print(f"Departamento: D03 - MRO: MATERIAL, REPARO E OPERAÇÃO")
    print(f"Categorias disponíveis: 16")
    print(f"Subcategorias disponíveis: 170")

# -----------------------------
# Função adicional para validação das combinações
# -----------------------------
def validate_classification(cat: str, sub: str) -> bool:
    """Valida se a combinação categoria-subcategoria é válida segundo nossa taxonomia"""
    if cat not in subcategories_by_cat:
        return False
    return sub in subcategories_by_cat[cat]

def get_valid_subcategories_for_category(cat: str) -> dict:
    """Retorna todas as subcategorias válidas para uma categoria específica"""
    return subcategories_by_cat.get(cat, {})

def print_mro_taxonomy_summary():
    """Imprime um resumo da taxonomia MRO para referência"""
    print("\n📋 RESUMO DA TAXONOMIA MRO:")
    print("="*60)

    total_subcats = 0
    for cat_id, cat_name in categories_by_dept['D03'].items():
        subcats = subcategories_by_cat.get(cat_id, {})
        subcat_count = len(subcats)
        total_subcats += subcat_count
        print(f"\n{cat_id}: {cat_name} ({subcat_count} subcategorias)")

        # Mostrar algumas subcategorias como exemplo
        if subcats:
            example_subs = list(subcats.items())[:3]
            for sub_id, sub_name in example_subs:
                print(f"  └─ {sub_id}: {sub_name}")
            if len(subcats) > 3:
                print(f"  └─ ... e mais {len(subcats) - 3} subcategorias")

    print(f"\n📊 TOTAIS:")
    print(f"  • 1 Departamento: D03")
    print(f"  • 16 Categorias: S09-S74")
    print(f"  • {total_subcats} Subcategorias: C001-C788")

# -----------------------------
# Executar processamento
# -----------------------------
if __name__ == '__main__':
    # Mostrar resumo da taxonomia antes de começar
    print_mro_taxonomy_summary()

    # Executar processamento principal
    main()