AI-Catalog Quick Deployment (GPT-5 High Reasoning)
Immediate Goal
Deploy in 1 hour to classify 3200 products with maximum accuracy using GPT-5 high reasoning
Quick Setup
1. Required Files Structure (Minimal)
ai-catalog/
├── app.py                  # Main Streamlit app
├── requirements.txt        # Dependencies
├── .env                   # API keys
├── classify.py            # GPT-5 classifier
├── database.py           # Database setup
└── data/
    ├── products.csv      # Your 3200 products
    └── taxonomy.json     # From old-code.py
2. requirements.txt
txtstreamlit==1.32.0
openai==1.35.0
pandas==2.2.0
psycopg2-binary==2.9.9
python-dotenv==1.0.0
streamlit-aggrid==0.3.4




Core Implementation
classify.py - GPT-5 High Reasoning Classifier
pythonimport openai
import json
import pandas as pd
from typing import List, Dict
import time

class GPT5Classifier:
    def __init__(self, api_key: str):
        self.client = openai.OpenAI(api_key=api_key)
        self.load_taxonomy()
    
    def load_taxonomy(self):
        """Load taxonomy from old-code.py structure"""
        # Copy directly from old-code.py
        self.departments = {"D03": "MRO: MATERIAL, REPARO E OPERAÇÃO"}
        
        self.categories = {
            "S09": "BARRAS E CHAPAS",
            "S17": "BATERIAS",
            "S25": "BOMBAS E MOTORES",
            # ... copy all 16 categories from old-code.py
        }
        
        self.subcategories = {
            "S09": {
                "C037": "Barras de aço",
                # ... copy all subcategories from old-code.py
            },
            # ... all other subcategory mappings
        }
    
    def classify_batch(self, products: List[str], batch_size: int = 20) -> List[Dict]:
        """
        Classify products in batches with GPT-5 high reasoning
        Process 20 products at a time for optimal speed/accuracy
        """
        results = []
        total = len(products)
        
        for i in range(0, total, batch_size):
            batch = products[i:i + batch_size]
            print(f"Processing batch {i//batch_size + 1}/{(total//batch_size) + 1}...")
            
            prompt = f"""
            Classify these MRO products AND detect duplicates.
            
            Products:
            {json.dumps([{"id": i+j, "name": p} for j, p in enumerate(batch)], indent=2)}
            
            Categories: {json.dumps(self.categories, indent=2)}
            Subcategories: {json.dumps(self.subcategories, indent=2)}
            
            For EACH product provide:
            1. Category code (SXX)
            2. Subcategory code (CXXX)
            3. Normalized name (standardized units, fixed typos)
            4. Duplicate group (products that are the same)
            5. Confidence (0-1)
            
            Detect duplicates by recognizing:
            - Same product with different units (100mm = 10cm)
            - Typos and abbreviations
            - Different word orders
            
            Return JSON:
            {{
                "classifications": [
                    {{
                        "id": 0,
                        "original_name": "product name",
                        "normalized_name": "standardized name",
                        "category": "SXX",
                        "subcategory": "CXXX",
                        "confidence": 0.95,
                        "duplicate_group": 1
                    }}
                ]
            }}
            """
            
            response = self.client.chat.completions.create(
                model="gpt-5",
                messages=[
                    {"role": "system", "content": "You are an MRO expert. Classify accurately."},
                    {"role": "user", "content": prompt}
                ],
                reasoning_effort="high",
                response_format={"type": "json_object"},
                temperature=0.1
            )
            
            batch_results = json.loads(response.choices[0].message.content)
            results.extend(batch_results['classifications'])
            
            # Rate limiting
            time.sleep(1)
        
        return results
database.py - Simple Database Setup
pythonimport psycopg2
import pandas as pd
from datetime import datetime

def create_tables(conn):
    """Create necessary tables"""
    cur = conn.cursor()
    
    cur.execute("""
    CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        product_name TEXT,
        normalized_name TEXT,
        category_code VARCHAR(3),
        subcategory_code VARCHAR(4),
        confidence FLOAT,
        duplicate_group INTEGER,
        processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    conn.commit()

def save_results(conn, results: List[Dict]):
    """Save classification results to database"""
    cur = conn.cursor()
    
    for r in results:
        cur.execute("""
        INSERT INTO products (
            product_name, normalized_name, category_code, 
            subcategory_code, confidence, duplicate_group
        ) VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            r['original_name'],
            r['normalized_name'],
            r['category'],
            r['subcategory'],
            r['confidence'],
            r.get('duplicate_group')
        ))
    
    conn.commit()
app.py - Streamlit Interface
pythonimport streamlit as st
import pandas as pd
import os
from classify import GPT5Classifier
from database import create_tables, save_results
import psycopg2
from streamlit_aggrid import AgGrid
from dotenv import load_dotenv

load_dotenv()

st.set_page_config(page_title="AI-Catalog", layout="wide")
st.title("🤖 AI-Catalog - GPT-5 MRO Classifier")

# Database connection
@st.cache_resource
def get_db():
    conn = psycopg2.connect(os.getenv("DATABASE_URL"))
    create_tables(conn)
    return conn

# Classifier
@st.cache_resource
def get_classifier():
    return GPT5Classifier(os.getenv("OPENAI_API_KEY"))

# Sidebar
with st.sidebar:
    st.header("📊 Quick Stats")
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM products")
    total = cur.fetchone()[0]
    st.metric("Products Processed", total)
    
    cur.execute("SELECT COUNT(DISTINCT duplicate_group) FROM products WHERE duplicate_group IS NOT NULL")
    dup_groups = cur.fetchone()[0] or 0
    st.metric("Duplicate Groups", dup_groups)

# Main tabs
tab1, tab2, tab3 = st.tabs(["🚀 Classify", "📊 View Results", "🔍 Duplicates"])

with tab1:
    st.header("Classify Products")
    
    uploaded_file = st.file_uploader("Upload CSV", type=['csv'])
    
    if uploaded_file:
        df = pd.read_csv(uploaded_file)
        st.write(f"Found {len(df)} products")
        
        # Assume first column is product names
        product_column = df.columns[0]
        products = df[product_column].tolist()
        
        # Show sample
        st.write("Sample products:")
        st.dataframe(df.head())
        
        if st.button("🚀 Start Classification (GPT-5 High Reasoning)", type="primary"):
            classifier = get_classifier()
            conn = get_db()
            
            # Process with progress bar
            progress = st.progress(0)
            status = st.empty()
            
            with st.spinner("Processing with GPT-5 high reasoning..."):
                results = classifier.classify_batch(products, batch_size=20)
                
                # Save to database
                save_results(conn, results)
                
            st.success(f"✅ Classified {len(results)} products!")
            
            # Show results
            results_df = pd.DataFrame(results)
            st.dataframe(results_df)
            
            # Download results
            csv = results_df.to_csv(index=False)
            st.download_button(
                "📥 Download Results",
                csv,
                "classification_results.csv",
                "text/csv"
            )

with tab2:
    st.header("View Products")
    
    conn = get_db()
    query = """
    SELECT 
        product_name,
        normalized_name,
        category_code,
        subcategory_code,
        confidence,
        duplicate_group,
        processed_at
    FROM products
    ORDER BY processed_at DESC
    """
    
    df = pd.read_sql(query, conn)
    
    if not df.empty:
        # Filter options
        col1, col2 = st.columns(2)
        with col1:
            category_filter = st.selectbox(
                "Filter by Category",
                ["All"] + df['category_code'].unique().tolist()
            )
        with col2:
            min_confidence = st.slider("Min Confidence", 0.0, 1.0, 0.8)
        
        # Apply filters
        filtered_df = df
        if category_filter != "All":
            filtered_df = filtered_df[filtered_df['category_code'] == category_filter]
        filtered_df = filtered_df[filtered_df['confidence'] >= min_confidence]
        
        # Show table
        AgGrid(
            filtered_df,
            pagination=True,
            paginationAutoPageSize=True,
            use_checkbox=True
        )
    else:
        st.info("No products classified yet")

with tab3:
    st.header("Duplicate Groups")
    
    conn = get_db()
    query = """
    SELECT 
        duplicate_group,
        COUNT(*) as count,
        STRING_AGG(product_name, ' | ') as products,
        MAX(normalized_name) as normalized
    FROM products
    WHERE duplicate_group IS NOT NULL
    GROUP BY duplicate_group
    HAVING COUNT(*) > 1
    ORDER BY count DESC
    """
    
    duplicates_df = pd.read_sql(query, conn)
    
    if not duplicates_df.empty:
        for _, row in duplicates_df.iterrows():
            with st.expander(f"Group {row['duplicate_group']} ({row['count']} items)"):
                st.write(f"**Normalized:** {row['normalized']}")
                st.write("**Products:**")
                for product in row['products'].split(' | '):
                    st.write(f"- {product}")
    else:
        st.info("No duplicates found yet")
