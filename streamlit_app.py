"""
Enhanced Streamlit app to view both normalization and MRO classification results
Run with: streamlit run streamlit_app.py
"""

import streamlit as st
import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv
import plotly.express as px
from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode, DataReturnMode

# Load environment variables
load_dotenv()

# Page config
st.set_page_config(
    page_title="AI-Catalog Complete Viewer",
    page_icon="🤖",
    layout="wide"
)

@st.cache_resource
def get_connection():
    """Create database connection"""
    try:
        conn = psycopg2.connect(os.getenv("DATABASE_URL"))
        return conn
    except Exception as e:
        st.error(f"Database connection failed: {e}")
        return None

# ============= NORMALIZATION DATA FUNCTIONS =============
@st.cache_data
def load_products(_conn):
    """Load all products from normalization table"""
    query = """
    SELECT 
        id,
        original_name,
        normalized_name,
        category_code,
        category_name,
        subcategory_code,
        subcategory_name,
        duplicate_group_id,
        is_master,
        similarity_score,
        classification_confidence,
        needs_review,
        reasoning_notes,
        processed_at,
        processing_batch_id
    FROM products_enhanced
    ORDER BY id DESC
    """
    try:
        return pd.read_sql(query, _conn)
    except:
        return pd.DataFrame()

@st.cache_data
def load_duplicate_groups(_conn):
    """Load duplicate group summary"""
    query = """
    SELECT 
        group_id,
        normalized_master_name,
        product_count,
        variations,
        confidence_avg,
        created_at
    FROM duplicate_groups
    WHERE product_count > 1
    ORDER BY product_count DESC
    """
    try:
        return pd.read_sql(query, _conn)
    except:
        return pd.DataFrame()

@st.cache_data
def load_processing_stats(_conn):
    """Load processing statistics"""
    query = """
    SELECT 
        batch_number,
        total_products,
        new_products,
        duplicates_found,
        low_confidence_count,
        processing_time_seconds,
        api_cost_estimate,
        created_at
    FROM processing_stats
    ORDER BY batch_number
    """
    try:
        return pd.read_sql(query, _conn)
    except:
        return pd.DataFrame()

# ============= MRO CLASSIFICATION DATA FUNCTIONS =============
@st.cache_data
def load_mro_products(_conn):
    """Load all products from MRO classification table"""
    query = """
    SELECT 
        id,
        product_name,
        brand,
        model,
        original_category,
        old_department,
        old_category,
        old_subcategory,
        new_department_code,
        new_department_name,
        new_category_code,
        new_category_name,
        new_subcategory_code,
        new_subcategory_name,
        confidence_score,
        classification_timestamp,
        batch_id,
        processing_status,
        error_message
    FROM mro_products
    ORDER BY id DESC
    """
    try:
        return pd.read_sql(query, _conn)
    except Exception as e:
        st.error(f"Error loading MRO data: {e}")
        return pd.DataFrame()

@st.cache_data
def get_mro_comparison(_conn):
    """Get comparison between old and new classifications"""
    query = """
    SELECT 
        id,
        product_name,
        brand,
        old_category,
        old_subcategory,
        new_category_name,
        new_subcategory_name,
        confidence_score,
        CASE 
            WHEN old_category != new_category_name THEN 'Changed'
            WHEN old_category = new_category_name AND old_subcategory != new_subcategory_name THEN 'Refined'
            ELSE 'Same'
        END as classification_change,
        processing_status
    FROM mro_products
    WHERE processing_status = 'completed'
    ORDER BY confidence_score DESC
    """
    try:
        return pd.read_sql(query, _conn)
    except:
        return pd.DataFrame()

@st.cache_data
def get_mro_statistics(_conn):
    """Get MRO classification statistics"""
    query = """
    SELECT 
        COUNT(*) as total_products,
        COUNT(CASE WHEN processing_status = 'completed' THEN 1 END) as completed,
        COUNT(CASE WHEN processing_status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN processing_status = 'error' THEN 1 END) as errors,
        AVG(CASE WHEN confidence_score IS NOT NULL THEN confidence_score END) as avg_confidence,
        COUNT(DISTINCT new_category_code) as unique_categories,
        COUNT(DISTINCT new_subcategory_code) as unique_subcategories
    FROM mro_products
    """
    try:
        cursor = _conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(query)
        return cursor.fetchone()
    except:
        return {}

def create_aggrid_table(df, key, selection_mode='single', height=400):
    """Create an AgGrid table with configuration"""
    gb = GridOptionsBuilder.from_dataframe(df)
    gb.configure_default_column(
        resizable=True,
        filterable=True,
        sortable=True,
        editable=False
    )
    
    # Configure specific columns
    if 'confidence_score' in df.columns:
        gb.configure_column(
            'confidence_score',
            type=["numericColumn", "numberColumnFilter"],
            precision=2,
            header_name="Confidence"
        )
    
    if 'product_name' in df.columns:
        gb.configure_column('product_name', min_width=200)
    
    # Enable selection
    gb.configure_selection(
        selection_mode=selection_mode,
        use_checkbox=True if selection_mode == 'multiple' else False
    )
    
    gb.configure_pagination(enabled=True, paginationAutoPageSize=True)
    
    gridOptions = gb.build()
    
    return AgGrid(
        df,
        gridOptions=gridOptions,
        data_return_mode=DataReturnMode.FILTERED_AND_SORTED,
        update_mode=GridUpdateMode.MODEL_CHANGED,
        fit_columns_on_grid_load=False,
        height=height,
        key=key,
        theme='streamlit'
    )

def main():
    st.title("🤖 AI-Catalog Complete Data Viewer")
    st.markdown("View normalization results and MRO classification comparisons")
    
    # Connect to database
    conn = get_connection()
    if not conn:
        st.stop()
    
    # Main navigation
    main_tab = st.sidebar.radio(
        "Select View",
        ["📊 Normalization Results", "🔧 MRO Classification"]
    )
    
    if main_tab == "📊 Normalization Results":
        st.header("Product Normalization & Deduplication")
        
        # Load normalization data
        with st.spinner("Loading normalization data..."):
            products_df = load_products(conn)
            duplicates_df = load_duplicate_groups(conn)
            stats_df = load_processing_stats(conn)
        
        if products_df.empty:
            st.info("No normalization data available. Run the normalization process first.")
        else:
            # Display normalization tabs
            norm_tabs = st.tabs(["📋 Products", "🔄 Duplicates", "📊 Analytics", "⚙️ Stats"])
            
            with norm_tabs[0]:
                st.subheader("Normalized Products")
                st.write(f"Total products: {len(products_df)}")
                
                # Filters
                col1, col2 = st.columns(2)
                with col1:
                    category_filter = st.selectbox(
                        "Filter by Category",
                        ["All"] + sorted(products_df['category_name'].dropna().unique().tolist())
                    )
                with col2:
                    show_masters_only = st.checkbox("Show master records only")
                
                filtered = products_df.copy()
                if category_filter != "All":
                    filtered = filtered[filtered['category_name'] == category_filter]
                if show_masters_only:
                    filtered = filtered[filtered['is_master'] == True]
                
                # Display with AgGrid
                selected = create_aggrid_table(
                    filtered[['id', 'original_name', 'normalized_name', 'category_name', 
                             'subcategory_name', 'duplicate_group_id', 'classification_confidence']],
                    key="norm_products_grid"
                )
            
            with norm_tabs[1]:
                st.subheader("Duplicate Groups")
                if not duplicates_df.empty:
                    st.write(f"Found {len(duplicates_df)} duplicate groups")
                    create_aggrid_table(duplicates_df, key="duplicates_grid")
                else:
                    st.info("No duplicate groups found")
            
            with norm_tabs[2]:
                st.subheader("Analytics")
                col1, col2, col3 = st.columns(3)
                with col1:
                    st.metric("Total Products", len(products_df))
                with col2:
                    st.metric("Unique Products", products_df['duplicate_group_id'].nunique())
                with col3:
                    avg_conf = products_df['classification_confidence'].mean()
                    st.metric("Avg Confidence", f"{avg_conf:.2%}")
                
                # Category distribution chart
                cat_dist = products_df['category_name'].value_counts().reset_index()
                cat_dist.columns = ['Category', 'Count']
                fig = px.bar(cat_dist, x='Category', y='Count', title="Category Distribution")
                st.plotly_chart(fig, use_container_width=True)
            
            with norm_tabs[3]:
                st.subheader("Processing Statistics")
                if not stats_df.empty:
                    st.dataframe(stats_df, use_container_width=True)
                else:
                    st.info("No processing statistics available")
    
    else:  # MRO Classification
        st.header("🔧 MRO Product Classification Analysis")
        
        # Load MRO data
        with st.spinner("Loading MRO classification data..."):
            mro_df = load_mro_products(conn)
            comparison_df = get_mro_comparison(conn)
            mro_stats = get_mro_statistics(conn)
        
        if mro_df.empty:
            st.info("No MRO classification data available. Run classify_mro.py first.")
        else:
            # Display statistics
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Total Products", mro_stats.get('total_products', 0))
            with col2:
                st.metric("Completed", mro_stats.get('completed', 0))
            with col3:
                st.metric("Pending", mro_stats.get('pending', 0))
            with col4:
                avg_conf = mro_stats.get('avg_confidence', 0)
                st.metric("Avg Confidence", f"{avg_conf:.2%}")
            
            # MRO tabs
            mro_tabs = st.tabs([
                "🔍 Classification Comparison", 
                "📊 Category Analysis", 
                "🔄 Changed Classifications",
                "📋 All Products",
                "❌ Errors"
            ])
            
            with mro_tabs[0]:
                st.subheader("Old vs New Classification Comparison")
                
                if not comparison_df.empty:
                    # Filter options
                    col1, col2, col3 = st.columns(3)
                    with col1:
                        change_filter = st.selectbox(
                            "Classification Change",
                            ["All", "Changed", "Refined", "Same"]
                        )
                    with col2:
                        min_confidence = st.slider("Min Confidence", 0.0, 1.0, 0.0)
                    with col3:
                        search_term = st.text_input("Search product name")
                    
                    # Apply filters
                    filtered_comp = comparison_df.copy()
                    if change_filter != "All":
                        filtered_comp = filtered_comp[filtered_comp['classification_change'] == change_filter]
                    if min_confidence > 0:
                        filtered_comp = filtered_comp[filtered_comp['confidence_score'] >= min_confidence]
                    if search_term:
                        filtered_comp = filtered_comp[
                            filtered_comp['product_name'].str.contains(search_term, case=False, na=False)
                        ]
                    
                    st.write(f"Showing {len(filtered_comp)} of {len(comparison_df)} products")
                    
                    # Display comparison table with AgGrid
                    display_cols = ['product_name', 'brand', 'old_category', 'old_subcategory',
                                  'new_category_name', 'new_subcategory_name', 
                                  'confidence_score', 'classification_change']
                    
                    selected_comparison = create_aggrid_table(
                        filtered_comp[display_cols],
                        key="comparison_grid",
                        height=500
                    )
                    
                    # Export button
                    csv = filtered_comp.to_csv(index=False)
                    st.download_button(
                        "📥 Download Comparison CSV",
                        csv,
                        "mro_classification_comparison.csv",
                        "text/csv"
                    )
                else:
                    st.info("No completed classifications for comparison")
            
            with mro_tabs[1]:
                st.subheader("Category Distribution Analysis")
                
                completed_df = mro_df[mro_df['processing_status'] == 'completed']
                
                if not completed_df.empty:
                    # Old vs New category comparison
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.write("**Old Categories Distribution**")
                        old_cats = completed_df['old_category'].value_counts().head(15)
                        fig1 = px.bar(
                            x=old_cats.values, 
                            y=old_cats.index,
                            orientation='h',
                            title="Top 15 Old Categories",
                            labels={'x': 'Count', 'y': 'Category'}
                        )
                        st.plotly_chart(fig1, use_container_width=True)
                    
                    with col2:
                        st.write("**New Categories Distribution**")
                        new_cats = completed_df['new_category_name'].value_counts().head(15)
                        fig2 = px.bar(
                            x=new_cats.values,
                            y=new_cats.index,
                            orientation='h',
                            title="Top 15 New Categories",
                            labels={'x': 'Count', 'y': 'Category'}
                        )
                        st.plotly_chart(fig2, use_container_width=True)
                    
                    # Migration matrix
                    st.write("**Category Migration Matrix**")
                    migration = pd.crosstab(
                        completed_df['old_category'],
                        completed_df['new_category_name'],
                        margins=True
                    )
                    
                    # Show top migrations
                    st.dataframe(migration, use_container_width=True)
                    
                    # Confidence by category
                    st.write("**Average Confidence by New Category**")
                    conf_by_cat = completed_df.groupby('new_category_name')['confidence_score'].agg(['mean', 'count'])
                    conf_by_cat = conf_by_cat.sort_values('count', ascending=False).head(10)
                    
                    fig3 = px.bar(
                        conf_by_cat,
                        y=conf_by_cat.index,
                        x='mean',
                        orientation='h',
                        title="Confidence Score by Category (Top 10)",
                        labels={'mean': 'Average Confidence', 'y': 'Category'}
                    )
                    st.plotly_chart(fig3, use_container_width=True)
                else:
                    st.info("No completed classifications for analysis")
            
            with mro_tabs[2]:
                st.subheader("Changed Classifications")
                
                changed_df = comparison_df[comparison_df['classification_change'].isin(['Changed', 'Refined'])]
                
                if not changed_df.empty:
                    st.write(f"Found {len(changed_df)} products with changed classifications")
                    
                    # Group by type of change
                    change_summary = changed_df['classification_change'].value_counts()
                    col1, col2 = st.columns(2)
                    with col1:
                        st.metric("Category Changed", change_summary.get('Changed', 0))
                    with col2:
                        st.metric("Subcategory Refined", change_summary.get('Refined', 0))
                    
                    # Show changed products
                    st.write("**Products with Classification Changes:**")
                    
                    for _, row in changed_df.head(20).iterrows():
                        with st.expander(f"{row['product_name'][:60]}..."):
                            col1, col2 = st.columns(2)
                            with col1:
                                st.write("**Old Classification:**")
                                st.write(f"- Category: {row['old_category']}")
                                st.write(f"- Subcategory: {row['old_subcategory']}")
                            with col2:
                                st.write("**New Classification:**")
                                st.write(f"- Category: {row['new_category_name']}")
                                st.write(f"- Subcategory: {row['new_subcategory_name']}")
                            st.write(f"**Confidence:** {row['confidence_score']:.2%}")
                            st.write(f"**Change Type:** {row['classification_change']}")
                else:
                    st.info("No classification changes found")
            
            with mro_tabs[3]:
                st.subheader("All MRO Products")
                
                # Status filter
                status_filter = st.selectbox(
                    "Filter by Status",
                    ["All", "completed", "pending", "error"]
                )
                
                filtered_mro = mro_df.copy()
                if status_filter != "All":
                    filtered_mro = filtered_mro[filtered_mro['processing_status'] == status_filter]
                
                st.write(f"Showing {len(filtered_mro)} products")
                
                # Display all products
                display_cols = ['id', 'product_name', 'brand', 'model',
                              'new_category_name', 'new_subcategory_name',
                              'confidence_score', 'processing_status']
                
                create_aggrid_table(
                    filtered_mro[display_cols],
                    key="all_mro_grid",
                    selection_mode='multiple',
                    height=500
                )
            
            with mro_tabs[4]:
                st.subheader("Classification Errors")
                
                error_df = mro_df[mro_df['processing_status'] == 'error']
                
                if not error_df.empty:
                    st.write(f"Found {len(error_df)} products with errors")
                    
                    for _, row in error_df.iterrows():
                        with st.expander(f"Error: {row['product_name'][:60]}..."):
                            st.write(f"**Product ID:** {row['id']}")
                            st.write(f"**Product Name:** {row['product_name']}")
                            st.write(f"**Error Message:** {row['error_message']}")
                    
                    if st.button("🔄 Reprocess Error Products"):
                        st.info("Run 'python classify_mro.py --reprocess-errors' in terminal to retry")
                else:
                    st.success("No errors found!")
    
    # Footer
    st.markdown("---")
    st.markdown("AI-Catalog Complete Viewer | Advanced Classification System")

if __name__ == "__main__":
    main()