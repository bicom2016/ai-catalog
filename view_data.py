"""
Streamlit app to view and analyze PostgreSQL data
Run with: streamlit run view_data.py
"""

import streamlit as st
import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv
import plotly.express as px

# Load environment variables
load_dotenv()

# Page config
st.set_page_config(
    page_title="AI-Catalog Data Viewer",
    page_icon="📊",
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

@st.cache_data
def load_products(_conn):
    """Load all products from database"""
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
    return pd.read_sql(query, _conn)

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
    return pd.read_sql(query, _conn)

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
    return pd.read_sql(query, _conn)

def main():
    st.title("🤖 AI-Catalog Data Viewer")
    st.markdown("View and analyze product classification results from PostgreSQL")
    
    # Connect to database
    conn = get_connection()
    if not conn:
        st.stop()
    
    # Load data
    with st.spinner("Loading data from PostgreSQL..."):
        try:
            products_df = load_products(conn)
            duplicates_df = load_duplicate_groups(conn)
            stats_df = load_processing_stats(conn)
        except Exception as e:
            st.error(f"Error loading data: {e}")
            st.stop()
    
    # Sidebar filters
    st.sidebar.header("🔍 Filters")
    
    # Category filter
    if not products_df.empty:
        categories = ["All"] + sorted(products_df['category_name'].dropna().unique().tolist())
        selected_category = st.sidebar.selectbox("Category", categories)
        
        # Confidence filter
        min_confidence = st.sidebar.slider(
            "Minimum Confidence",
            0.0, 1.0, 0.0, 0.05
        )
        
        # Review filter
        show_needs_review = st.sidebar.checkbox("Only show items needing review")
        
        # Master records filter
        show_only_masters = st.sidebar.checkbox("Only show master records")
        
        # Apply filters
        filtered_df = products_df.copy()
        
        if selected_category != "All":
            filtered_df = filtered_df[filtered_df['category_name'] == selected_category]
        
        if min_confidence > 0:
            filtered_df = filtered_df[filtered_df['classification_confidence'] >= min_confidence]
        
        if show_needs_review:
            filtered_df = filtered_df[filtered_df['needs_review'] == True]
        
        if show_only_masters:
            filtered_df = filtered_df[filtered_df['is_master'] == True]
    
    # Main tabs
    tab1, tab2, tab3, tab4, tab5 = st.tabs([
        "📋 Products", "🔄 Duplicates", "📊 Analytics", "⚙️ Processing Stats", "🔍 Search"
    ])
    
    with tab1:
        st.header("Product Classifications")
        
        if not filtered_df.empty:
            st.write(f"Showing {len(filtered_df)} of {len(products_df)} products")
            
            # Display options
            col1, col2, col3 = st.columns(3)
            with col1:
                show_columns = st.multiselect(
                    "Show columns",
                    filtered_df.columns.tolist(),
                    default=['id', 'original_name', 'normalized_name', 'category_name', 
                            'subcategory_name', 'classification_confidence', 'duplicate_group_id']
                )
            with col2:
                sort_by = st.selectbox("Sort by", show_columns)
            with col3:
                sort_order = st.radio("Order", ["Descending", "Ascending"])
            
            # Sort data
            sorted_df = filtered_df.sort_values(
                sort_by, 
                ascending=(sort_order == "Ascending"),
                na_position='last'
            )
            
            # Display data
            st.dataframe(
                sorted_df[show_columns],
                use_container_width=True,
                height=600
            )
            
            # Export button
            csv = sorted_df[show_columns].to_csv(index=False)
            st.download_button(
                "📥 Download CSV",
                csv,
                "products_export.csv",
                "text/csv"
            )
        else:
            st.info("No products found")
    
    with tab2:
        st.header("Duplicate Groups")
        
        if not duplicates_df.empty:
            st.write(f"Found {len(duplicates_df)} duplicate groups")
            
            # Show duplicate groups
            for idx, row in duplicates_df.iterrows():
                with st.expander(f"Group {row['group_id']} - {row['product_count']} products"):
                    st.write(f"**Master Name:** {row['normalized_master_name']}")
                    
                    # Get all products in this group
                    group_products = products_df[
                        products_df['duplicate_group_id'] == row['group_id']
                    ][['original_name', 'normalized_name', 'is_master', 'similarity_score']]
                    
                    st.dataframe(group_products, use_container_width=True)
        else:
            st.info("No duplicate groups found")
    
    with tab3:
        st.header("Analytics Dashboard")
        
        if not products_df.empty:
            # Summary metrics
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                st.metric("Total Products", len(products_df))
            with col2:
                unique_products = products_df['duplicate_group_id'].nunique()
                st.metric("Unique Products", unique_products)
            with col3:
                avg_confidence = products_df['classification_confidence'].mean()
                st.metric("Avg Confidence", f"{avg_confidence:.3f}")
            with col4:
                needs_review = products_df['needs_review'].sum()
                st.metric("Needs Review", needs_review)
            
            st.markdown("---")
            
            # Charts
            col1, col2 = st.columns(2)
            
            with col1:
                # Category distribution
                st.subheader("Category Distribution")
                cat_counts = products_df['category_name'].value_counts().reset_index()
                cat_counts.columns = ['Category', 'Count']
                
                fig = px.bar(cat_counts, x='Category', y='Count', 
                            title="Products by Category")
                fig.update_xaxis(tickangle=-45)
                st.plotly_chart(fig, use_container_width=True)
            
            with col2:
                # Confidence distribution
                st.subheader("Confidence Distribution")
                fig = px.histogram(products_df, x='classification_confidence',
                                 nbins=20, title="Classification Confidence Distribution")
                st.plotly_chart(fig, use_container_width=True)
            
            # Subcategory treemap
            st.subheader("Category-Subcategory Distribution")
            tree_data = products_df.groupby(['category_name', 'subcategory_name']).size().reset_index(name='count')
            
            if not tree_data.empty:
                fig = px.treemap(tree_data, path=['category_name', 'subcategory_name'], 
                               values='count', title="Product Distribution Treemap")
                st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No data for analytics")
    
    with tab4:
        st.header("Processing Statistics")
        
        if not stats_df.empty:
            # Summary
            col1, col2, col3 = st.columns(3)
            with col1:
                st.metric("Total Batches", len(stats_df))
            with col2:
                total_cost = stats_df['api_cost_estimate'].sum()
                st.metric("Total API Cost", f"${total_cost:.2f}")
            with col3:
                total_time = stats_df['processing_time_seconds'].sum()
                st.metric("Total Time", f"{total_time:.1f}s")
            
            # Batch details
            st.subheader("Batch Processing Details")
            st.dataframe(stats_df, use_container_width=True)
            
            # Processing chart
            fig = px.line(stats_df, x='batch_number', y='processing_time_seconds',
                         title="Processing Time by Batch", markers=True)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No processing statistics available")
    
    with tab5:
        st.header("Search Products")
        
        search_term = st.text_input("Search in product names (original or normalized)")
        
        if search_term:
            search_results = products_df[
                products_df['original_name'].str.contains(search_term, case=False, na=False) |
                products_df['normalized_name'].str.contains(search_term, case=False, na=False)
            ]
            
            st.write(f"Found {len(search_results)} results")
            
            if not search_results.empty:
                st.dataframe(
                    search_results[['id', 'original_name', 'normalized_name', 
                                  'category_name', 'subcategory_name', 
                                  'classification_confidence', 'duplicate_group_id']],
                    use_container_width=True
                )
    
    # Footer
    st.markdown("---")
    st.markdown("AI-Catalog Data Viewer | Advanced AI Classification")

if __name__ == "__main__":
    main()