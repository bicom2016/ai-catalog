# MRO Product Classification System

## Overview
This system classifies MRO (Maintenance, Repair, and Operations) products using Claude AI API and stores results in a PostgreSQL database. It compares existing classifications with new AI-generated classifications for better accuracy.

## Features
- **Database Integration**: Stores all products and classifications in PostgreSQL
- **Batch Processing**: Processes products in configurable batches to respect API limits
- **Comparison Analysis**: Compares old vs new classifications
- **Progress Tracking**: Real-time progress monitoring and resumable processing
- **Error Handling**: Automatic retry logic and error tracking
- **Reporting**: Generates detailed classification reports

## System Components

### 1. `database_mro.py`
- Database connection and table management
- Import CSV data
- Track classification progress
- Store both old and new classifications

### 2. `mro_classifier.py`
- Claude AI integration
- MRO taxonomy (16 categories, 170 subcategories)
- Intelligent classification with fallbacks
- Confidence scoring

### 3. `batch_processor.py`
- Batch processing logic
- Rate limiting
- Error recovery
- Progress tracking

### 4. `classify_mro.py`
- Main orchestration script
- Command-line interface
- Report generation

## Installation

1. Install dependencies:
```bash
pip install psycopg2-binary pandas python-dotenv anthropic
```

2. Configure `.env` file:
```
DATABASE_URL=postgresql://user:pass@host:port/dbname
CLAUDE_API_KEY=your_claude_api_key
```

## Usage

### Initial Setup
```bash
# Create database tables and import CSV
python classify_mro.py --setup --import-csv "21-8-25-MRO.csv"
```

### Run Classification
```bash
# Classify all pending products
python classify_mro.py --classify

# With custom batch size and delay
python classify_mro.py --classify --batch-size 10 --delay 2.0
```

### Generate Report
```bash
# Generate comparison report
python classify_mro.py --report
```

### Test Single Product
```bash
# Test classification for a single product
python classify_mro.py --test "DISJUNTOR MOTOR 3P 30-36A"
```

### Reprocess Errors
```bash
# Retry failed classifications
python classify_mro.py --reprocess-errors
```

## Database Schema

### Table: `mro_products`
- **Original Data**: product_name, brand, model, original_category
- **Old Classification**: old_department, old_category, old_subcategory
- **New Classification**: new_department_code/name, new_category_code/name, new_subcategory_code/name
- **Metadata**: confidence_score, classification_timestamp, processing_status, error_message

## MRO Taxonomy

### 16 Main Categories:
- S09: BARRAS E CHAPAS
- S17: BATERIAS
- S25: BOMBAS E MOTORES
- S36: CORRENTES METÁLICAS E ENGRENAGENS
- S39: ELEMENTOS DE FIXAÇÃO E VEDAÇÃO
- S41: FERRAMENTAS
- S43: MATERIAIS DIVERSOS
- S46: MATERIAIS HIDRÁULICOS, PNEUMÁTICOS, FILTROS E VÁLVULAS
- S47: MATERIAIS ELÉTRICOS E ELETRÔNICOS
- S49: LUBRIFICANTES
- S51: PARTES MECÂNICAS, ROLAMENTOS E CORREIAS
- S54: TUBOS E CONEXÕES
- S71: AUTOMAÇÃO INDUSTRIAL
- S72: EMBALAGENS
- S73: ILUMINAÇÃO
- S74: QUÍMICOS INDUSTRIAIS

### 170 Subcategories
Each category has specific subcategories for detailed classification.

## Results Summary

From the test run on 36 products:
- **Average Confidence**: 100%
- **Most Common Categories**: 
  - MATERIAIS ELÉTRICOS E ELETRÔNICOS (39%)
  - AUTOMAÇÃO INDUSTRIAL (33%)
  - FERRAMENTAS (11%)
- **Key Improvements**: Better granularity in electrical/electronic components classification

## Performance

- **Processing Speed**: ~2-3 seconds per product
- **Batch Size**: Configurable (recommended: 5-10)
- **API Rate Limiting**: Handled automatically

## Troubleshooting

1. **Database Connection Issues**: Check DATABASE_URL in .env
2. **API Rate Limits**: Reduce batch size or increase delay
3. **Classification Errors**: Check Claude API key and network connection
4. **Unicode Errors**: System uses ASCII-compatible output for Windows compatibility

## Future Enhancements

- Web interface for real-time monitoring
- Machine learning model training from classifications
- Bulk export/import capabilities
- Multi-language support
- Duplicate detection algorithms