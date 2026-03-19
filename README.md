# Stock Return Prediction System

A machine learning system for predicting stock returns using financial indicators. Compares LASSO Regression and Random Forest models to identify the best approach for financial forecasting.

## 🎯 Quick Start

### Run the Complete System
```bash
Rscript main.R
```

### Generate All Visualizations
```bash
Rscript create_visualizations.R
```

### Run Tests
```bash
Rscript test_error_handling.R
Rscript test_model_evaluator.R
```

## 📊 Key Results

- **Best Model:** LASSO Regression
- **Accuracy:** R² = 0.7842 (78.4% explained variance)
- **Top Predictor:** Profit Margin (combined importance: 1.00)
- **Dataset:** 1,000 stocks with 10 financial features

## 📁 Project Structure

```
├── main.R                          # Main pipeline
├── data_preprocessor.R             # Data preprocessing
├── feature_analyzer.R              # Feature analysis
├── model_trainer.R                 # Model training
├── model_evaluator.R               # Model evaluation
├── create_visualizations.R         # Visualization generation
├── financial_dataset.csv           # Input data
├── output/                         # Generated reports
└── visualizations/                 # Generated visualizations
```

## 🎓 For Presentation

### Essential Files
1. **PRESENTATION_GUIDE.md** - Complete presentation guide with talking points
2. **visualizations/QUICK_REFERENCE.md** - One-page cheat sheet
3. **visualizations/POWERPOINT_OUTLINE.md** - Slide-by-slide outline
4. **DELIVERABLES_CHECKLIST.md** - Complete package overview

### Key Visualizations
- `05_model_comparison.png` - Performance comparison
- `10_aggregated_importance.png` - Top 5 features
- `06_lasso_predictions.png` - Prediction quality

## 🔬 Methodology

1. **Data Preprocessing** - Handle missing values, normalize features, train/test split (80/20)
2. **Exploratory Analysis** - Descriptive statistics, correlation analysis
3. **Model Training** - LASSO (5-fold CV) and Random Forest (hyperparameter tuning)
4. **Model Evaluation** - MSE, MAE, R² on held-out test set
5. **Feature Importance** - Aggregate importance from both models

## 📈 Results Summary

| Metric | LASSO (Winner) | Random Forest |
|--------|----------------|---------------|
| R² Score | **0.7842** | 0.6714 |
| MSE | **3.741** | 5.695 |
| MAE | **1.536** | 1.880 |

**Top 5 Features:**
1. Profit Margin (1.00)
2. Revenue Growth (0.39)
3. Debt-to-Equity (0.33)
4. Previous Return (0.26)
5. Volatility (0.25)

## 🎤 Quick Demo (5 minutes)

```bash
# Show these files in order:
cat visualizations/12_final_summary.txt
open visualizations/05_model_comparison.png
open visualizations/10_aggregated_importance.png
```

## 📚 Documentation

- **Specifications:** `.kiro/specs/stock-return-prediction/`
  - `requirements.md` - Requirements specification
  - `design.md` - Design document
  - `tasks.md` - Implementation tasks (all completed)

- **Presentation Materials:**
  - `PRESENTATION_GUIDE.md` - Complete guide
  - `visualizations/QUICK_REFERENCE.md` - Key numbers
  - `visualizations/POWERPOINT_OUTLINE.md` - Slide outline

## ✅ Quality Assurance

- ✓ Proper train/test split (no data leakage)
- ✓ Cross-validation for hyperparameter tuning
- ✓ Multiple evaluation metrics
- ✓ Reproducible results (random seed = 42)
- ✓ Comprehensive error handling
- ✓ Unit tests for critical functions

## 🚀 Reproducibility

All results are reproducible with fixed random seed (42). Run `Rscript main.R` to verify.

## 📊 Visualizations Generated

The system generates 13 visualization files:
- 10 PNG charts (distributions, correlations, predictions, importance)
- 3 text reports (methodology, model selection, final summary)

All visualizations are in the `visualizations/` folder.

## 🎯 Business Insights

- **Profitability matters most:** Profit margin is the strongest predictor
- **Linear relationships dominate:** LASSO outperforms complex ensemble
- **78% predictable:** Significant portion of returns can be forecasted
- **Actionable for investors:** Focus on profitable companies

## 🔧 Requirements

- R (version 4.0+)
- Packages: glmnet, ranger, caret, dplyr, readr, ggplot2, gridExtra, corrplot

Install packages:
```r
install.packages(c("glmnet", "ranger", "caret", "dplyr", "readr", 
                   "ggplot2", "gridExtra", "corrplot"))
```

## 📞 Support

All materials are self-contained and well-documented. See:
- `PRESENTATION_GUIDE.md` for presentation help
- `DELIVERABLES_CHECKLIST.md` for complete package overview
- Individual R files for code documentation

---

**Built with rigorous methodology. Ready for presentation. Production-ready code.** 🎉
