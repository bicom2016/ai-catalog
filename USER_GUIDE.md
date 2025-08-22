# AI-Catalog User Guide

## Overview
The AI-Catalog system provides advanced product classification and normalization capabilities with a comprehensive web-based dashboard for viewing and analyzing results.

## Accessing the Dashboard

1. **Launch the Application**
   ```bash
   python -m streamlit run streamlit_app.py
   ```

2. **Open in Browser**
   - Navigate to: http://localhost:8502
   - The dashboard will load automatically

## Dashboard Features

### Navigation
Use the sidebar to switch between two main views:
- **📊 Normalization Results** - Product normalization and deduplication
- **🔧 MRO Classification** - MRO product classification analysis

## Normalization Results View

### Products Tab
- View all normalized products
- Filter by category
- Show master records only option
- Export results to CSV

### Duplicates Tab
- See grouped duplicate products
- View product variations
- Analyze similarity scores

### Analytics Tab
- Total products count
- Unique products after deduplication
- Average confidence scores
- Category distribution charts

### Stats Tab
- Processing statistics
- Batch processing details
- Time and cost metrics

## MRO Classification View

### Classification Comparison Tab
**Purpose**: Compare original classifications with new AI-enhanced classifications

**Features**:
- Filter by classification change type:
  - **Changed**: Products moved to different category
  - **Refined**: Same category, improved subcategory
  - **Same**: No change needed
- Set minimum confidence threshold
- Search products by name
- Export comparison results

**Understanding the Table**:
- **Product Name**: Original product description
- **Brand/Model**: Manufacturer information
- **Old Category/Subcategory**: Previous classification
- **New Category/Subcategory**: Improved classification
- **Confidence Score**: Classification certainty (0-100%)
- **Classification Change**: Type of improvement

### Category Analysis Tab
**Purpose**: Visualize classification improvements

**Charts**:
1. **Old vs New Distribution**: Side-by-side category comparisons
2. **Migration Matrix**: Shows how products moved between categories
3. **Confidence by Category**: Average confidence scores per category

**Key Metrics**:
- Top categories before and after
- Products per category
- Classification accuracy

### Changed Classifications Tab
**Purpose**: Focus on products with classification improvements

**Information Displayed**:
- Products with category changes
- Products with refined subcategories
- Detailed before/after comparison
- Confidence scores for each change

### All Products Tab
**Purpose**: Complete product inventory

**Features**:
- Filter by processing status
- View all product details
- Multi-select for bulk operations
- Export full dataset

### Errors Tab
**Purpose**: Monitor and resolve classification issues

**Features**:
- List of products with errors
- Error messages and details
- Reprocessing instructions

## Using Filters

### Category Filter
- Select "All" to view everything
- Choose specific category to focus

### Confidence Filter
- Slide to set minimum confidence
- Higher values = more certain classifications

### Search
- Type product name or part of it
- Searches in both original and normalized names

### Status Filter
- **Completed**: Successfully classified
- **Pending**: Awaiting processing
- **Error**: Classification failed

## Interpreting Results

### Confidence Scores
- **90-100%**: High confidence, reliable classification
- **70-89%**: Good confidence, review recommended
- **Below 70%**: Low confidence, manual review needed

### Classification Changes
- **Changed**: Significant improvement, different category
- **Refined**: Minor improvement, better subcategory
- **Same**: Original classification was correct

## Exporting Data

### CSV Export
1. Apply desired filters
2. Click "📥 Download CSV" button
3. File saves to Downloads folder

### Available Exports
- Filtered product lists
- Classification comparisons
- Category analysis
- Error reports

## Best Practices

### Regular Review
1. Check dashboard weekly
2. Review low-confidence items
3. Export reports for records

### Data Quality
1. Monitor error rates
2. Review changed classifications
3. Validate improvements

### Performance Tracking
1. Track classification accuracy
2. Monitor processing times
3. Review confidence trends

## Common Tasks

### Finding Misclassified Products
1. Go to "Changed Classifications" tab
2. Review products with "Changed" status
3. Verify improvements are correct

### Analyzing Category Distribution
1. Open "Category Analysis" tab
2. Compare old vs new distributions
3. Identify major shifts

### Checking Processing Status
1. View statistics at top of dashboard
2. Check "All Products" tab
3. Filter by "pending" status

## Troubleshooting

### Dashboard Not Loading
- Ensure application is running
- Check browser compatibility
- Clear browser cache

### Data Not Updating
- Refresh browser page
- Check database connection
- Verify processing completed

### Export Issues
- Check browser download settings
- Ensure sufficient disk space
- Try different browser

## Support

For technical assistance:
1. Check error messages in dashboard
2. Review processing logs
3. Contact system administrator

## Tips

- Use filters to focus on specific areas
- Export data regularly for backup
- Review confidence scores for quality control
- Monitor classification changes for insights

---

**Dashboard URL**: http://localhost:8502  
**Best viewed in**: Chrome, Firefox, or Edge  
**Recommended resolution**: 1920x1080 or higher