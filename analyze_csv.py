import pandas as pd
import os

def analyze_csv_files():
    # Define file paths
    csv_files = {
        'Lista de categorias': 'Lista-de-categorias.csv',
        'Dep_Cat_Sub': 'Dep_Cat_Sub.csv',
        'CategoriaD03-Produtos': 'CategoriaD03-Produtos.csv'
    }
    
    dataframes = {}
    
    # Analyze each CSV file
    for name, filename in csv_files.items():
        print(f"\n{'='*70}")
        print(f"Analyzing: {name}")
        print('='*70)
        
        try:
            # Try different encodings
            try:
                df = pd.read_csv(filename, encoding='utf-8')
            except:
                df = pd.read_csv(filename, encoding='latin-1')
            
            dataframes[name] = df
            
            print(f"Successfully loaded")
            print(f"Shape: {df.shape[0]} rows x {df.shape[1]} columns")
            print(f"\nColumn names:")
            for i, col in enumerate(df.columns, 1):
                print(f"   {i}. {col}")
            
            print(f"\nData types:")
            for col, dtype in df.dtypes.items():
                print(f"   - {col}: {dtype}")
            
            print(f"\nMissing values:")
            null_counts = df.isnull().sum()
            if null_counts.sum() == 0:
                print("   No missing values found")
            else:
                for col, count in null_counts[null_counts > 0].items():
                    print(f"   - {col}: {count} ({count/len(df)*100:.1f}%)")
            
            print(f"\nSample data (first 3 rows):")
            print(df.head(3).to_string())
            
        except Exception as e:
            print(f"Error reading {name}: {str(e)}")
    
    # Detailed analysis for each file
    print(f"\n{'='*70}")
    print("DETAILED ANALYSIS")
    print('='*70)
    
    # Analyze Dep_Cat_Sub (hierarchy structure)
    if 'Dep_Cat_Sub' in dataframes:
        df = dataframes['Dep_Cat_Sub']
        print("\nDep_Cat_Sub - Hierarchy Analysis:")
        print(f"   - Unique Departments: {df['ID Departamento'].nunique()}")
        print(f"   - Unique Categories: {df['ID Categoria'].nunique()}")
        print(f"   - Unique Subcategories: {df['ID subcategoria'].nunique()}")
        
        # Show department distribution
        dept_counts = df.groupby('Departamento').size()
        print(f"\n   Department distribution:")
        for dept, count in dept_counts.items():
            print(f"      - {dept}: {count} subcategories")
        
        # Most common categories
        cat_counts = df.groupby('Categoria').size().sort_values(ascending=False).head(5)
        print(f"\n   Top 5 Categories by subcategory count:")
        for cat, count in cat_counts.items():
            print(f"      - {cat}: {count} subcategories")
    
    # Analyze Lista de categorias
    if 'Lista de categorias' in dataframes:
        df = dataframes['Lista de categorias']
        print("\nLista de categorias - Structure Analysis:")
        
        # Count non-null values in each level
        dept_count = df['ID Departamento'].notna().sum()
        cat_count = df['ID Categoria'].notna().sum()
        subcat_count = df['ID subcategoria'].notna().sum()
        prod_count = df['Produto'].notna().sum()
        
        print(f"   - Entries with Department ID: {dept_count}")
        print(f"   - Entries with Category ID: {cat_count}")
        print(f"   - Entries with Subcategory ID: {subcat_count}")
        print(f"   - Entries with Product: {prod_count}")
        
        # Check if it's a sparse hierarchical structure
        if dept_count < len(df):
            print(f"\n   Note: This appears to be a sparse/hierarchical format")
            print(f"   where not all rows have all fields filled.")
    
    # Analyze products file
    if 'CategoriaD03-Produtos' in dataframes:
        df = dataframes['CategoriaD03-Produtos']
        print("\nCategoriaD03-Produtos - Product Analysis:")
        print(f"   - Total products: {len(df)}")
        
        # Analyze product descriptions
        if 'Descrição' in df.columns:
            # Sample of product descriptions
            print(f"\n   Sample product descriptions:")
            for i, desc in enumerate(df['Descrição'].head(5), 1):
                if pd.notna(desc):
                    # Truncate long descriptions
                    desc_display = desc[:80] + "..." if len(str(desc)) > 80 else desc
                    print(f"      {i}. {desc_display}")
            
            # Check for patterns in descriptions
            df['desc_length'] = df['Descrição'].astype(str).str.len()
            print(f"\n   Description statistics:")
            print(f"      - Average length: {df['desc_length'].mean():.0f} characters")
            print(f"      - Min length: {df['desc_length'].min():.0f} characters")
            print(f"      - Max length: {df['desc_length'].max():.0f} characters")
    
    # Cross-file analysis
    print(f"\n{'='*70}")
    print("CROSS-FILE RELATIONSHIPS")
    print('='*70)
    
    if 'Dep_Cat_Sub' in dataframes and 'Lista de categorias' in dataframes:
        df1 = dataframes['Dep_Cat_Sub']
        df2 = dataframes['Lista de categorias']
        
        # Check common subcategory IDs
        subcat1 = set(df1['ID subcategoria'].dropna())
        subcat2 = set(df2['ID subcategoria'].dropna())
        common = subcat1.intersection(subcat2)
        
        print(f"\nComparison between Dep_Cat_Sub and Lista de categorias:")
        print(f"   - Subcategories in Dep_Cat_Sub: {len(subcat1)}")
        print(f"   - Subcategories in Lista de categorias: {len(subcat2)}")
        print(f"   - Common subcategories: {len(common)}")
        
        if len(common) > 0:
            print(f"   - Overlap percentage: {len(common)/len(subcat1)*100:.1f}%")
    
    print(f"\n{'='*70}")
    print("Analysis complete!")
    print('='*70)
    
    return dataframes

if __name__ == "__main__":
    try:
        dataframes = analyze_csv_files()
    except Exception as e:
        print(f"Fatal error: {e}")