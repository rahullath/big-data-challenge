# Main Execution Script for Stock Return Prediction System

# Load required libraries
library(glmnet)
library(ranger)
library(caret)
library(dplyr)
library(readr)

# Source component modules
source("utils.R")
source("data_preprocessor.R")
source("feature_analyzer.R")
source("model_trainer.R")
source("model_evaluator.R")

# Main execution function
main <- function() {
  log_message("Starting Stock Return Prediction System")
  log_message(paste(rep("=", 80), collapse = ""))
  
  # ============================================================================
  # STEP 1: Load and Preprocess Data
  # ============================================================================
  log_message("STEP 1: Loading and preprocessing data")
  log_message(paste(rep("-", 80), collapse = ""))
  
  # Load dataset
  log_message("Loading financial_dataset.csv...")
  data <- load_dataset("financial_dataset.csv")
  log_message(sprintf("Dataset loaded: %d rows, %d columns", nrow(data), ncol(data)))
  
  # Handle missing values
  log_message("Handling missing values...")
  missing_result <- handle_missing_values(data)
  data_clean <- missing_result$cleaned_data
  log_message(sprintf("Rows removed due to missing values: %d", missing_result$removed_count))
  log_message(sprintf("Remaining rows: %d", nrow(data_clean)))
  
  # Split dataset into train and test sets
  log_message("Splitting dataset (80% train, 20% test)...")
  split_result <- split_dataset(data_clean, train_ratio = 0.8, seed = 42)
  train_data <- split_result$train
  test_data <- split_result$test
  log_message(sprintf("Training set size: %d rows", nrow(train_data)))
  log_message(sprintf("Test set size: %d rows", nrow(test_data)))
  
  # Normalize features
  log_message("Normalizing features...")
  norm_result <- normalize_features(train_data, test_data, target_col = "future_return")
  train_normalized <- norm_result$train_normalized
  test_normalized <- norm_result$test_normalized
  norm_params <- norm_result$normalization_params
  log_message("Feature normalization completed")
  log_message(sprintf("Normalization parameters calculated for %d features", 
                      length(norm_params$means)))
  
  # ============================================================================
  # STEP 2: Feature Analysis
  # ============================================================================
  log_message("")
  log_message("STEP 2: Analyzing features")
  log_message(paste(rep("-", 80), collapse = ""))
  
  # Compute descriptive statistics
  log_message("Computing descriptive statistics...")
  desc_stats <- compute_descriptive_statistics(train_normalized)
  log_message("Descriptive Statistics:")
  print(desc_stats)
  
  # Compute correlation matrix
  log_message("Computing correlation matrix...")
  cor_matrix <- compute_correlation_matrix(train_normalized)
  log_message("Correlation Matrix:")
  print(round(cor_matrix, 3))
  
  # Extract feature-target correlations
  log_message("Extracting feature-target correlations...")
  target_cors <- extract_target_correlations(cor_matrix, target_col = "future_return")
  log_message("Feature-Target Correlations (sorted by absolute value):")
  print(round(target_cors, 3))
  
  # ============================================================================
  # STEP 3: Model Training
  # ============================================================================
  log_message("")
  log_message("STEP 3: Training models")
  log_message(paste(rep("-", 80), collapse = ""))
  
  # Train LASSO model
  log_message("Training LASSO Regression model with cross-validation...")
  lasso_result <- train_lasso_model(train_normalized, target_col = "future_return", 
                                     nfolds = 5, seed = 42)
  log_message("LASSO Model Results:")
  log_message(sprintf("  Optimal Lambda: %.6f", lasso_result$lambda_optimal))
  log_message(sprintf("  Selected Features: %d out of %d", 
                      length(lasso_result$selected_features), 
                      ncol(train_normalized) - 1))
  log_message(sprintf("  Selected Feature Names: %s", 
                      paste(lasso_result$selected_features, collapse = ", ")))
  log_message("  Coefficients:")
  print(round(lasso_result$coefficients, 4))
  
  # Train Random Forest model
  log_message("")
  log_message("Training Random Forest model with hyperparameter tuning...")
  rf_result <- train_random_forest_model(train_normalized, target_col = "future_return", 
                                         seed = 42)
  log_message("Random Forest Model Results:")
  log_message(sprintf("  Best Parameters: ntree=%d, max_depth=%d", 
                      rf_result$best_params$ntree, 
                      rf_result$best_params$max_depth))
  log_message("  Feature Importance (top 5):")
  print(round(head(rf_result$feature_importance, 5), 4))
  
  # ============================================================================
  # STEP 4: Model Evaluation
  # ============================================================================
  log_message("")
  log_message("STEP 4: Evaluating models")
  log_message(paste(rep("-", 80), collapse = ""))
  
  # Evaluate LASSO model
  log_message("Evaluating LASSO model on test set...")
  lasso_eval <- evaluate_model(lasso_result$model, test_normalized, 
                                target_col = "future_return", 
                                model_type = "lasso", 
                                lambda_optimal = lasso_result$lambda_optimal)
  
  # Evaluate Random Forest model
  log_message("")
  log_message("Evaluating Random Forest model on test set...")
  rf_eval <- evaluate_model(rf_result$model, test_normalized, 
                             target_col = "future_return", 
                             model_type = "rf")
  
  # Compare models
  log_message("")
  log_message("Comparing model performance...")
  comparison <- compare_models(lasso_eval, rf_eval)
  
  # ============================================================================
  # STEP 5: Feature Importance Analysis
  # ============================================================================
  log_message("")
  log_message("STEP 5: Analyzing feature importance")
  log_message(paste(rep("-", 80), collapse = ""))
  
  # Identify LASSO eliminated features
  all_features <- setdiff(colnames(train_normalized), "future_return")
  eliminated_features <- setdiff(all_features, lasso_result$selected_features)
  log_message(sprintf("LASSO Feature Selection: %d selected, %d eliminated out of %d total", 
                      length(lasso_result$selected_features), 
                      length(eliminated_features), 
                      length(all_features)))
  if (length(eliminated_features) > 0) {
    log_message(sprintf("Eliminated Features: %s", paste(eliminated_features, collapse = ", ")))
  }
  
  # Aggregate feature importance from both models
  log_message("")
  log_message("Aggregating feature importance from both models...")
  aggregated_importance <- aggregate_feature_importance(lasso_result$coefficients, 
                                                        rf_result$feature_importance)
  log_message("Top 5 Most Influential Features:")
  print(aggregated_importance)
  
  # ============================================================================
  # STEP 6: Generate Output Files
  # ============================================================================
  log_message("")
  log_message("STEP 6: Generating output files")
  log_message(paste(rep("-", 80), collapse = ""))
  
  # Create output directory if it doesn't exist
  if (!dir.exists("output")) {
    dir.create("output")
    log_message("Created output/ directory")
  }
  
  # Write descriptive statistics
  log_message("Writing descriptive_stats.txt...")
  sink("output/descriptive_stats.txt")
  cat("Descriptive Statistics for Stock Return Prediction Dataset\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  print(desc_stats)
  sink()
  
  # Write correlation matrix
  log_message("Writing correlation_matrix.txt...")
  sink("output/correlation_matrix.txt")
  cat("Correlation Matrix\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  print(round(cor_matrix, 3))
  cat("\n\nFeature-Target Correlations (sorted by absolute value):\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")
  print(round(target_cors, 3))
  sink()
  
  # Write LASSO results
  log_message("Writing lasso_results.txt...")
  sink("output/lasso_results.txt")
  cat("LASSO Regression Model Results\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat(sprintf("Optimal Lambda: %.6f\n", lasso_result$lambda_optimal))
  cat(sprintf("Selected Features: %d out of %d\n\n", 
              length(lasso_result$selected_features), 
              length(all_features)))
  cat("Selected Feature Names:\n")
  cat(paste(lasso_result$selected_features, collapse = ", "), "\n\n")
  cat("Coefficients:\n")
  print(round(lasso_result$coefficients, 4))
  cat("\n\nEliminated Features:\n")
  if (length(eliminated_features) > 0) {
    cat(paste(eliminated_features, collapse = ", "), "\n")
  } else {
    cat("None (all features selected)\n")
  }
  cat("\n\nTest Set Performance:\n")
  cat(sprintf("  MSE: %.6f\n", lasso_eval$metrics$mse))
  cat(sprintf("  MAE: %.6f\n", lasso_eval$metrics$mae))
  cat(sprintf("  R²: %.6f\n", lasso_eval$metrics$r_squared))
  sink()
  
  # Write Random Forest results
  log_message("Writing rf_results.txt...")
  sink("output/rf_results.txt")
  cat("Random Forest Model Results\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat(sprintf("Best Parameters:\n"))
  cat(sprintf("  Number of Trees: %d\n", rf_result$best_params$ntree))
  cat(sprintf("  Maximum Depth: %d\n\n", rf_result$best_params$max_depth))
  cat("Feature Importance (all features):\n")
  print(round(rf_result$feature_importance, 4))
  cat("\n\nTest Set Performance:\n")
  cat(sprintf("  MSE: %.6f\n", rf_eval$metrics$mse))
  cat(sprintf("  MAE: %.6f\n", rf_eval$metrics$mae))
  cat(sprintf("  R²: %.6f\n", rf_eval$metrics$r_squared))
  sink()
  
  # Write model comparison
  log_message("Writing model_comparison.txt...")
  sink("output/model_comparison.txt")
  cat("Model Performance Comparison\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  print(comparison$comparison_table)
  cat("\n\nBest Model by Metric:\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")
  cat(sprintf("Best by R²: %s\n", comparison$best_by_r2))
  cat(sprintf("Best by MSE: %s\n", comparison$best_by_mse))
  cat(sprintf("Best by MAE: %s\n", comparison$best_by_mae))
  cat(sprintf("\nOverall Best Model: %s\n", comparison$overall_best))
  sink()
  
  # Write feature importance
  log_message("Writing feature_importance.txt...")
  sink("output/feature_importance.txt")
  cat("Feature Importance Analysis\n")
  cat(paste(rep("=", 80), collapse = ""), "\n\n")
  cat("LASSO Feature Selection:\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")
  cat(sprintf("Selected: %d features\n", length(lasso_result$selected_features)))
  cat(sprintf("Eliminated: %d features\n\n", length(eliminated_features)))
  cat("Top 5 Most Influential Features (aggregated from both models):\n")
  cat(paste(rep("-", 80), collapse = ""), "\n")
  print(aggregated_importance)
  sink()
  
  log_message("All output files generated successfully in output/ directory")
  
  # ============================================================================
  # Summary
  # ============================================================================
  log_message("")
  log_message(paste(rep("=", 80), collapse = ""))
  log_message("EXECUTION SUMMARY")
  log_message(paste(rep("=", 80), collapse = ""))
  log_message(sprintf("Dataset: %d rows processed", nrow(data_clean)))
  log_message(sprintf("Training set: %d rows | Test set: %d rows", 
                      nrow(train_normalized), nrow(test_normalized)))
  log_message(sprintf("LASSO: %d features selected, R²=%.4f", 
                      length(lasso_result$selected_features), 
                      lasso_eval$metrics$r_squared))
  log_message(sprintf("Random Forest: ntree=%d, max_depth=%d, R²=%.4f", 
                      rf_result$best_params$ntree, 
                      rf_result$best_params$max_depth, 
                      rf_eval$metrics$r_squared))
  log_message(sprintf("Overall Best Model: %s", comparison$overall_best))
  log_message(paste(rep("=", 80), collapse = ""))
  log_message("Stock Return Prediction System execution completed successfully!")
}

# Run main function if script is executed directly
if (sys.nframe() == 0) {
  main()
}
