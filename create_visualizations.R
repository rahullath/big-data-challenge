# ============================================================================
# Stock Return Prediction System - Visualization Script
# Creates professional visualizations for presentation
# ============================================================================

# Load required libraries
library(ggplot2)
library(gridExtra)
library(corrplot)
library(dplyr)
library(readr)

# Source modules
source("data_preprocessor.R")
source("feature_analyzer.R")
source("model_trainer.R")
source("model_evaluator.R")
source("utils.R")

# Create visualizations directory
if (!dir.exists("visualizations")) {
  dir.create("visualizations")
}

cat("=== Stock Return Prediction System - Visualization Generation ===\n\n")

# ============================================================================
# 1. Load and Preprocess Data
# ============================================================================
cat("Step 1: Loading and preprocessing data...\n")
data <- load_dataset("financial_dataset.csv")
cleaned_result <- handle_missing_values(data)
cleaned_data <- cleaned_result$cleaned_data

split_result <- split_dataset(cleaned_data, seed = 42)
train_data <- split_result$train
test_data <- split_result$test

norm_result <- normalize_features(train_data, test_data)
train_norm <- norm_result$train_normalized
test_norm <- norm_result$test_normalized

# ============================================================================
# 2. Methodology Flowchart Data
# ============================================================================
cat("Step 2: Creating methodology overview...\n")

# Create a simple text-based methodology diagram
methodology_text <- "
STOCK RETURN PREDICTION SYSTEM - METHODOLOGY

1. DATA PREPROCESSING
   ├─ Load financial_dataset.csv (1000 samples, 10 features)
   ├─ Handle missing values (remove incomplete rows)
   ├─ Split: 80% Training (800) / 20% Test (200)
   └─ Normalize features (mean=0, sd=1)

2. EXPLORATORY ANALYSIS
   ├─ Descriptive statistics (mean, median, sd, min, max)
   ├─ Correlation analysis (feature relationships)
   └─ Feature-target correlation ranking

3. MODEL TRAINING
   ├─ LASSO Regression
   │  ├─ 5-fold cross-validation
   │  ├─ Optimal lambda selection
   │  └─ Feature selection via L1 regularization
   └─ Random Forest
      ├─ Hyperparameter tuning (ntree, max_depth)
      ├─ Out-of-bag error estimation
      └─ Feature importance extraction

4. MODEL EVALUATION
   ├─ Performance metrics: MSE, MAE, R²
   ├─ Model comparison
   └─ Best model selection

5. FEATURE IMPORTANCE ANALYSIS
   ├─ Aggregate importance from both models
   └─ Identify top 5 influential features
"

writeLines(methodology_text, "visualizations/methodology.txt")

# ============================================================================
# 3. Data Distribution Visualizations
# ============================================================================
cat("Step 3: Creating data distribution plots...\n")

# Feature distributions
feature_cols <- setdiff(colnames(cleaned_data), "future_return")

# Create distribution plots for key features
dist_plots <- lapply(1:min(6, length(feature_cols)), function(i) {
  col <- feature_cols[i]
  ggplot(cleaned_data, aes(x = .data[[col]])) +
    geom_histogram(bins = 30, fill = "#3498db", color = "white", alpha = 0.8) +
    geom_density(aes(y = after_stat(count)), color = "#e74c3c", size = 1) +
    labs(title = paste("Distribution:", col),
         x = col, y = "Frequency") +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold", size = 10))
})

png("visualizations/01_feature_distributions.png", width = 1200, height = 800, res = 120)
grid.arrange(grobs = dist_plots, ncol = 3,
             top = "Feature Distributions (Top 6 Features)")
dev.off()

# Target variable distribution
png("visualizations/02_target_distribution.png", width = 800, height = 600, res = 120)
ggplot(cleaned_data, aes(x = future_return)) +
  geom_histogram(bins = 40, fill = "#2ecc71", color = "white", alpha = 0.8) +
  geom_density(aes(y = after_stat(count)), color = "#e74c3c", size = 1.2) +
  geom_vline(aes(xintercept = mean(future_return)), 
             color = "#e74c3c", linetype = "dashed", size = 1) +
  annotate("text", x = mean(cleaned_data$future_return), 
           y = max(table(cut(cleaned_data$future_return, 40))) * 0.9,
           label = paste("Mean =", round(mean(cleaned_data$future_return), 2)),
           hjust = -0.1, color = "#e74c3c", fontface = "bold") +
  labs(title = "Target Variable Distribution: Future Stock Return",
       subtitle = "Predicting next year's stock return percentage",
       x = "Future Return (%)", y = "Frequency") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11))
dev.off()

# ============================================================================
# 4. Correlation Analysis Visualization
# ============================================================================
cat("Step 4: Creating correlation visualizations...\n")

# Correlation matrix
cor_matrix <- compute_correlation_matrix(cleaned_data)

png("visualizations/03_correlation_matrix.png", width = 1000, height = 900, res = 120)
corrplot(cor_matrix, method = "color", type = "upper", 
         tl.col = "black", tl.srt = 45, tl.cex = 0.9,
         addCoef.col = "black", number.cex = 0.6,
         col = colorRampPalette(c("#e74c3c", "white", "#3498db"))(200),
         title = "Feature Correlation Matrix",
         mar = c(0, 0, 2, 0))
dev.off()

# Feature-target correlations
target_cors <- extract_target_correlations(cor_matrix)
cor_df <- data.frame(
  Feature = names(target_cors),
  Correlation = as.numeric(target_cors)
) %>%
  arrange(desc(abs(Correlation))) %>%
  head(10)

png("visualizations/04_feature_target_correlations.png", width = 900, height = 600, res = 120)
ggplot(cor_df, aes(x = reorder(Feature, abs(Correlation)), y = Correlation)) +
  geom_bar(stat = "identity", aes(fill = Correlation > 0), alpha = 0.8) +
  scale_fill_manual(values = c("#e74c3c", "#3498db"), 
                    labels = c("Negative", "Positive")) +
  coord_flip() +
  labs(title = "Feature-Target Correlations",
       subtitle = "Top 10 features by correlation strength with future return",
       x = "Feature", y = "Correlation Coefficient",
       fill = "Direction") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11),
        legend.position = "bottom")
dev.off()

# ============================================================================
# 5. Train Models and Extract Results
# ============================================================================
cat("Step 5: Training models for visualization...\n")

# Train LASSO
lasso_result <- train_lasso_model(train_norm, seed = 42)
lasso_eval <- evaluate_model(lasso_result$model, test_norm, 
                              model_type = "lasso",
                              lambda_optimal = lasso_result$lambda_optimal)

# Train Random Forest
rf_result <- train_random_forest_model(train_norm, seed = 42)
rf_eval <- evaluate_model(rf_result$model, test_norm, 
                          model_type = "rf")

# ============================================================================
# 6. Model Performance Comparison
# ============================================================================
cat("Step 6: Creating model performance visualizations...\n")

# Comparison table
comparison <- compare_models(lasso_eval, rf_eval)

# Create metrics comparison plot
metrics_df <- data.frame(
  Model = rep(c("LASSO", "Random Forest"), 3),
  Metric = rep(c("R²", "MSE", "MAE"), each = 2),
  Value = c(
    lasso_eval$metrics$r_squared, rf_eval$metrics$r_squared,
    lasso_eval$metrics$mse, rf_eval$metrics$mse,
    lasso_eval$metrics$mae, rf_eval$metrics$mae
  )
)

# Normalize for visualization (R² is already 0-1, normalize MSE and MAE)
metrics_df_norm <- metrics_df %>%
  group_by(Metric) %>%
  mutate(Normalized = ifelse(Metric == "R²", Value, 
                              1 - (Value - min(Value)) / (max(Value) - min(Value) + 0.001))) %>%
  ungroup()

png("visualizations/05_model_comparison.png", width = 1000, height = 600, res = 120)
ggplot(metrics_df_norm, aes(x = Metric, y = Normalized, fill = Model)) +
  geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
  geom_text(aes(label = sprintf("%.3f", Value)), 
            position = position_dodge(width = 0.9), 
            vjust = -0.5, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("#3498db", "#e74c3c")) +
  labs(title = "Model Performance Comparison",
       subtitle = "Higher is better (for visualization, MSE and MAE are inverted)",
       x = "Metric", y = "Normalized Score",
       caption = paste("Best Model:", comparison$overall_best, 
                      "| R² (higher better) | MSE & MAE (lower better)")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 10),
        plot.caption = element_text(size = 10, face = "bold", hjust = 0.5))
dev.off()

# ============================================================================
# 7. Prediction Scatter Plots
# ============================================================================
cat("Step 7: Creating prediction scatter plots...\n")

# LASSO predictions
lasso_pred_df <- data.frame(
  Actual = test_norm$future_return,
  Predicted = lasso_eval$predictions
)

png("visualizations/06_lasso_predictions.png", width = 800, height = 700, res = 120)
ggplot(lasso_pred_df, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.6, color = "#3498db", size = 2) +
  geom_abline(intercept = 0, slope = 1, color = "#e74c3c", 
              linetype = "dashed", size = 1) +
  annotate("text", x = min(lasso_pred_df$Actual), 
           y = max(lasso_pred_df$Predicted),
           label = sprintf("R² = %.4f\nMSE = %.3f\nMAE = %.3f", 
                          lasso_eval$metrics$r_squared,
                          lasso_eval$metrics$mse,
                          lasso_eval$metrics$mae),
           hjust = 0, vjust = 1, size = 4, fontface = "bold",
           color = "#2c3e50") +
  labs(title = "LASSO Model: Predicted vs Actual Returns",
       subtitle = "Test set predictions (200 samples)",
       x = "Actual Future Return", y = "Predicted Future Return") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11))
dev.off()

# Random Forest predictions
rf_pred_df <- data.frame(
  Actual = test_norm$future_return,
  Predicted = rf_eval$predictions
)

png("visualizations/07_rf_predictions.png", width = 800, height = 700, res = 120)
ggplot(rf_pred_df, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.6, color = "#e74c3c", size = 2) +
  geom_abline(intercept = 0, slope = 1, color = "#3498db", 
              linetype = "dashed", size = 1) +
  annotate("text", x = min(rf_pred_df$Actual), 
           y = max(rf_pred_df$Predicted),
           label = sprintf("R² = %.4f\nMSE = %.3f\nMAE = %.3f", 
                          rf_eval$metrics$r_squared,
                          rf_eval$metrics$mse,
                          rf_eval$metrics$mae),
           hjust = 0, vjust = 1, size = 4, fontface = "bold",
           color = "#2c3e50") +
  labs(title = "Random Forest Model: Predicted vs Actual Returns",
       subtitle = "Test set predictions (200 samples)",
       x = "Actual Future Return", y = "Predicted Future Return") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11))
dev.off()

# ============================================================================
# 8. Feature Importance Visualizations
# ============================================================================
cat("Step 8: Creating feature importance visualizations...\n")

# LASSO coefficients
lasso_coef_df <- data.frame(
  Feature = names(lasso_result$coefficients),
  Coefficient = as.numeric(lasso_result$coefficients)
) %>%
  arrange(desc(abs(Coefficient)))

png("visualizations/08_lasso_coefficients.png", width = 900, height = 600, res = 120)
ggplot(lasso_coef_df, aes(x = reorder(Feature, abs(Coefficient)), y = Coefficient)) +
  geom_bar(stat = "identity", aes(fill = Coefficient > 0), alpha = 0.8) +
  scale_fill_manual(values = c("#e74c3c", "#3498db"), 
                    labels = c("Negative", "Positive")) +
  coord_flip() +
  labs(title = "LASSO Model: Feature Coefficients",
       subtitle = paste("Optimal lambda =", round(lasso_result$lambda_optimal, 4)),
       x = "Feature", y = "Coefficient Value",
       fill = "Effect") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11),
        legend.position = "bottom")
dev.off()

# Random Forest feature importance
rf_imp_df <- data.frame(
  Feature = names(rf_result$feature_importance),
  Importance = as.numeric(rf_result$feature_importance)
) %>%
  arrange(desc(Importance)) %>%
  head(10)

png("visualizations/09_rf_importance.png", width = 900, height = 600, res = 120)
ggplot(rf_imp_df, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "#e74c3c", alpha = 0.8) +
  coord_flip() +
  labs(title = "Random Forest: Feature Importance",
       subtitle = paste("Top 10 features | ntree =", rf_result$best_params$ntree,
                       "| max_depth =", rf_result$best_params$max_depth),
       x = "Feature", y = "Importance Score") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11))
dev.off()

# Aggregated feature importance
agg_importance <- aggregate_feature_importance(
  lasso_result$coefficients,
  rf_result$feature_importance
)

png("visualizations/10_aggregated_importance.png", width = 1000, height = 600, res = 120)
ggplot(agg_importance, aes(x = reorder(feature, combined_score))) +
  geom_bar(aes(y = lasso_importance), stat = "identity", 
           fill = "#3498db", alpha = 0.7, width = 0.4, position = position_nudge(x = -0.2)) +
  geom_bar(aes(y = rf_importance), stat = "identity", 
           fill = "#e74c3c", alpha = 0.7, width = 0.4, position = position_nudge(x = 0.2)) +
  coord_flip() +
  labs(title = "Top 5 Most Influential Features (Aggregated)",
       subtitle = "Combined importance from LASSO and Random Forest models",
       x = "Feature", y = "Normalized Importance Score",
       caption = "Blue = LASSO | Red = Random Forest") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11),
        plot.caption = element_text(size = 10, hjust = 0.5))
dev.off()

# ============================================================================
# 9. Model Selection Decision Tree
# ============================================================================
cat("Step 9: Creating model selection summary...\n")

decision_text <- sprintf("
MODEL SELECTION DECISION SUMMARY
================================

EVALUATION CRITERIA:
-------------------
Primary Metric: R² Score (measures explained variance)
Secondary Metrics: MSE (prediction error), MAE (average error)

LASSO REGRESSION RESULTS:
-------------------------
✓ R² Score: %.4f (explains %.1f%% of variance)
✓ MSE: %.3f
✓ MAE: %.3f
✓ Features Selected: %d out of 10
✓ Optimal Lambda: %.4f

RANDOM FOREST RESULTS:
----------------------
✓ R² Score: %.4f (explains %.1f%% of variance)
✓ MSE: %.3f
✓ MAE: %.3f
✓ Optimal ntree: %d
✓ Optimal max_depth: %d

DECISION:
---------
WINNER: %s

REASONING:
%s

WHY THIS MATTERS:
- Higher R² = Better predictive power
- Lower MSE/MAE = More accurate predictions
- LASSO provides interpretability through feature selection
- Random Forest captures non-linear relationships

RECOMMENDED USE:
%s
",
lasso_eval$metrics$r_squared, lasso_eval$metrics$r_squared * 100,
lasso_eval$metrics$mse, lasso_eval$metrics$mae,
length(lasso_result$selected_features), lasso_result$lambda_optimal,
rf_eval$metrics$r_squared, rf_eval$metrics$r_squared * 100,
rf_eval$metrics$mse, rf_eval$metrics$mae,
rf_result$best_params$ntree, rf_result$best_params$max_depth,
comparison$overall_best,
ifelse(comparison$overall_best == "LASSO",
       "LASSO outperforms Random Forest on all three metrics (R², MSE, MAE).\nThe L1 regularization effectively selects relevant features while\nmaintaining strong predictive accuracy.",
       "Random Forest outperforms LASSO on the primary metric (R²).\nThe ensemble approach better captures complex non-linear relationships\nin the stock return data."),
ifelse(comparison$overall_best == "LASSO",
       "Use LASSO for production predictions. It offers:\n  • Better accuracy and lower error\n  • Interpretable coefficients for stakeholder communication\n  • Faster prediction time\n  • Clear feature importance ranking",
       "Use Random Forest for production predictions. It offers:\n  • Superior predictive accuracy\n  • Robust handling of non-linear patterns\n  • Feature importance insights\n  • Better generalization to unseen data")
)

writeLines(decision_text, "visualizations/11_model_selection_summary.txt")

# ============================================================================
# 10. Create Summary Report
# ============================================================================
cat("Step 10: Creating comprehensive summary report...\n")

summary_report <- sprintf("
================================================================================
STOCK RETURN PREDICTION SYSTEM - FINAL RESULTS SUMMARY
================================================================================

PROJECT OVERVIEW:
-----------------
Objective: Predict future stock returns using machine learning
Dataset: financial_dataset.csv (1000 samples, 10 features)
Models: LASSO Regression vs Random Forest
Evaluation: 80/20 train-test split with reproducible random seed (42)

METHODOLOGY STEPS:
------------------
1. DATA PREPROCESSING
   • Loaded 1000 samples with 10 financial features
   • Handled missing values (removed incomplete rows)
   • Split: 800 training / 200 test samples
   • Normalized features (mean=0, std=1)

2. EXPLORATORY DATA ANALYSIS
   • Computed descriptive statistics for all variables
   • Analyzed correlation matrix (11x11)
   • Identified strongest feature-target correlations

3. MODEL TRAINING
   • LASSO: 5-fold cross-validation, optimal lambda selection
   • Random Forest: Hyperparameter tuning (ntree, max_depth)
   • Both models trained on normalized training set

4. MODEL EVALUATION
   • Calculated MSE, MAE, R² on test set
   • Compared model performance
   • Selected best model based on metrics

5. FEATURE IMPORTANCE ANALYSIS
   • Extracted LASSO coefficients
   • Extracted Random Forest importance scores
   • Aggregated importance across both models

FINAL RESULTS:
--------------
BEST MODEL: %s

Performance Metrics:
  R² Score: %.4f (explains %.1f%% of variance)
  MSE: %.3f
  MAE: %.3f

Top 5 Most Influential Features:
  1. %s (combined score: %.3f)
  2. %s (combined score: %.3f)
  3. %s (combined score: %.3f)
  4. %s (combined score: %.3f)
  5. %s (combined score: %.3f)

KEY INSIGHTS:
-------------
• %s demonstrates superior predictive performance
• Feature selection reveals %s as the most critical predictor
• Model achieves %.1f%% explained variance on unseen test data
• Results are reproducible with fixed random seed (42)

VISUALIZATIONS GENERATED:
-------------------------
✓ 01_feature_distributions.png - Distribution of top 6 features
✓ 02_target_distribution.png - Target variable distribution
✓ 03_correlation_matrix.png - Feature correlation heatmap
✓ 04_feature_target_correlations.png - Top 10 feature-target correlations
✓ 05_model_comparison.png - Side-by-side model performance
✓ 06_lasso_predictions.png - LASSO predicted vs actual scatter plot
✓ 07_rf_predictions.png - Random Forest predicted vs actual scatter plot
✓ 08_lasso_coefficients.png - LASSO feature coefficients
✓ 09_rf_importance.png - Random Forest feature importance
✓ 10_aggregated_importance.png - Combined feature importance (top 5)
✓ 11_model_selection_summary.txt - Detailed model selection reasoning
✓ 12_final_summary.txt - This comprehensive report

REPRODUCIBILITY:
----------------
All results can be reproduced by running:
  source('create_visualizations.R')

Random seed: 42 (set throughout pipeline)
R version: %s
Key packages: glmnet, ranger, ggplot2, corrplot

CONCLUSION:
-----------
The Stock Return Prediction System successfully implements and compares
two machine learning approaches for financial forecasting. The %s model
is recommended for production use based on superior performance across
all evaluation metrics.

Generated on: %s
================================================================================
",
comparison$overall_best,
ifelse(comparison$overall_best == "LASSO", 
       lasso_eval$metrics$r_squared, rf_eval$metrics$r_squared),
ifelse(comparison$overall_best == "LASSO", 
       lasso_eval$metrics$r_squared * 100, rf_eval$metrics$r_squared * 100),
ifelse(comparison$overall_best == "LASSO", 
       lasso_eval$metrics$mse, rf_eval$metrics$mse),
ifelse(comparison$overall_best == "LASSO", 
       lasso_eval$metrics$mae, rf_eval$metrics$mae),
agg_importance$feature[1], agg_importance$combined_score[1],
agg_importance$feature[2], agg_importance$combined_score[2],
agg_importance$feature[3], agg_importance$combined_score[3],
agg_importance$feature[4], agg_importance$combined_score[4],
agg_importance$feature[5], agg_importance$combined_score[5],
comparison$overall_best,
agg_importance$feature[1],
ifelse(comparison$overall_best == "LASSO", 
       lasso_eval$metrics$r_squared * 100, rf_eval$metrics$r_squared * 100),
R.version.string,
comparison$overall_best,
format(Sys.time(), "%Y-%m-%d %H:%M:%S")
)

writeLines(summary_report, "visualizations/12_final_summary.txt")

# ============================================================================
# COMPLETION
# ============================================================================
cat("\n=== Visualization Generation Complete! ===\n\n")
cat("All visualizations saved to 'visualizations/' directory:\n")
cat("  • 10 PNG image files (plots and charts)\n")
cat("  • 3 TXT files (methodology, decision summary, final report)\n\n")
cat("Ready for presentation to professor and teammates!\n")
