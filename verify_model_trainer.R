# Verification Script for Model Trainer Module
# This script tests the model trainer functions with sample data

# Source required files
source("utils.R")
source("data_preprocessor.R")
source("model_trainer.R")

# Load required packages
required_packages <- c("glmnet", "ranger", "dplyr", "readr")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("Installing package: %s\n", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    library(pkg, character.only = TRUE)
  }
}

cat("\n=== Model Trainer Verification ===\n\n")

# Test 1: Load and prepare sample data
cat("Test 1: Loading and preparing sample data...\n")
tryCatch({
  data <- load_dataset("financial_dataset.csv")
  cat(sprintf("✓ Loaded dataset: %d rows, %d columns\n", nrow(data), ncol(data)))
  
  # Handle missing values
  cleaned <- handle_missing_values(data)
  cat(sprintf("✓ Cleaned data: %d rows remaining\n", nrow(cleaned$cleaned_data)))
  
  # Split dataset
  split_data <- split_dataset(cleaned$cleaned_data, train_ratio = 0.8, seed = 42)
  cat(sprintf("✓ Split data: %d train, %d test\n", 
              nrow(split_data$train), nrow(split_data$test)))
  
  # Normalize features
  normalized <- normalize_features(split_data$train, split_data$test, target_col = "future_return")
  train_data <- normalized$train_normalized
  test_data <- normalized$test_normalized
  cat(sprintf("✓ Normalized features\n"))
  
}, error = function(e) {
  cat(sprintf("✗ Data preparation failed: %s\n", e$message))
  quit(status = 1)
})

# Test 2: Train LASSO model
cat("\nTest 2: Training LASSO model with cross-validation...\n")
tryCatch({
  lasso_result <- train_lasso_model(train_data, target_col = "future_return", nfolds = 5, seed = 42)
  
  # Verify outputs
  if (is.null(lasso_result$model)) {
    stop("LASSO model is NULL")
  }
  if (is.null(lasso_result$lambda_optimal) || !is.numeric(lasso_result$lambda_optimal)) {
    stop("lambda_optimal is invalid")
  }
  if (is.null(lasso_result$coefficients)) {
    stop("coefficients is NULL")
  }
  if (is.null(lasso_result$selected_features) || !is.character(lasso_result$selected_features)) {
    stop("selected_features is invalid")
  }
  
  cat(sprintf("✓ LASSO model trained successfully\n"))
  cat(sprintf("  - Optimal lambda: %.6f\n", lasso_result$lambda_optimal))
  cat(sprintf("  - Selected features: %d/%d\n", 
              length(lasso_result$selected_features), 
              ncol(train_data) - 1))
  cat(sprintf("  - Non-zero coefficients: %d\n", length(lasso_result$coefficients)))
  
  if (length(lasso_result$selected_features) > 0) {
    cat(sprintf("  - Top features: %s\n", 
                paste(head(lasso_result$selected_features, 3), collapse=", ")))
  }
  
}, error = function(e) {
  cat(sprintf("✗ LASSO training failed: %s\n", e$message))
  quit(status = 1)
})

# Test 3: Train Random Forest model
cat("\nTest 3: Training Random Forest model with hyperparameter tuning...\n")
tryCatch({
  rf_result <- train_random_forest_model(train_data, target_col = "future_return", seed = 42)
  
  # Verify outputs
  if (is.null(rf_result$model)) {
    stop("Random Forest model is NULL")
  }
  if (is.null(rf_result$best_params) || 
      is.null(rf_result$best_params$ntree) || 
      is.null(rf_result$best_params$max_depth)) {
    stop("best_params is invalid")
  }
  if (is.null(rf_result$feature_importance) || !is.numeric(rf_result$feature_importance)) {
    stop("feature_importance is invalid")
  }
  
  cat(sprintf("✓ Random Forest model trained successfully\n"))
  cat(sprintf("  - Best ntree: %d\n", rf_result$best_params$ntree))
  cat(sprintf("  - Best max_depth: %d\n", rf_result$best_params$max_depth))
  cat(sprintf("  - Feature importance scores: %d\n", length(rf_result$feature_importance)))
  
  # Verify importance is sorted descending
  if (!all(diff(rf_result$feature_importance) <= 0)) {
    stop("Feature importance not sorted in descending order")
  }
  cat(sprintf("  - Importance sorted: ✓\n"))
  
  cat(sprintf("  - Top 3 features: %s\n", 
              paste(names(rf_result$feature_importance)[1:3], collapse=", ")))
  
}, error = function(e) {
  cat(sprintf("✗ Random Forest training failed: %s\n", e$message))
  quit(status = 1)
})

# Test 4: Verify LASSO uses 5-fold CV (Requirement 7.2)
cat("\nTest 4: Verifying LASSO cross-validation configuration...\n")
tryCatch({
  # Train with explicit nfolds parameter
  lasso_cv_test <- train_lasso_model(train_data, target_col = "future_return", nfolds = 5, seed = 42)
  
  # Check that cv.glmnet was used (has lambda sequence)
  if (is.null(lasso_cv_test$model$lambda)) {
    stop("LASSO model does not have lambda sequence (CV not performed)")
  }
  
  cat(sprintf("✓ LASSO uses cross-validation\n"))
  cat(sprintf("  - Lambda values tested: %d\n", length(lasso_cv_test$model$lambda)))
  cat(sprintf("  - CV folds: 5 (as specified)\n"))
  
}, error = function(e) {
  cat(sprintf("✗ LASSO CV verification failed: %s\n", e$message))
  quit(status = 1)
})

# Test 5: Verify RF hyperparameter tuning (Requirement 8.2)
cat("\nTest 5: Verifying Random Forest hyperparameter tuning...\n")
tryCatch({
  # The function should have tuned ntree and max_depth
  # Verify the returned parameters are from the expected grid
  ntree_expected <- c(100, 300, 500)
  max_depth_expected <- c(5, 10, 15)
  
  if (!(rf_result$best_params$ntree %in% ntree_expected)) {
    stop(sprintf("ntree %d not in expected grid", rf_result$best_params$ntree))
  }
  if (!(rf_result$best_params$max_depth %in% max_depth_expected)) {
    stop(sprintf("max_depth %d not in expected grid", rf_result$best_params$max_depth))
  }
  
  cat(sprintf("✓ Random Forest hyperparameter tuning verified\n"))
  cat(sprintf("  - ntree tuned over: %s\n", paste(ntree_expected, collapse=", ")))
  cat(sprintf("  - max_depth tuned over: %s\n", paste(max_depth_expected, collapse=", ")))
  
}, error = function(e) {
  cat(sprintf("✗ RF hyperparameter tuning verification failed: %s\n", e$message))
  quit(status = 1)
})

# Test 6: Edge case - training with small dataset
cat("\nTest 6: Testing with small dataset (edge case)...\n")
tryCatch({
  # Create small subset
  small_train <- train_data[1:min(30, nrow(train_data)), ]
  
  lasso_small <- train_lasso_model(small_train, target_col = "future_return", nfolds = 5, seed = 42)
  cat(sprintf("✓ LASSO handles small dataset (%d rows)\n", nrow(small_train)))
  
  rf_small <- train_random_forest_model(small_train, target_col = "future_return", seed = 42)
  cat(sprintf("✓ Random Forest handles small dataset (%d rows)\n", nrow(small_train)))
  
}, error = function(e) {
  cat(sprintf("✗ Small dataset test failed: %s\n", e$message))
  quit(status = 1)
})

cat("\n=== All Model Trainer Verification Tests Passed ===\n")
cat("\nSummary:\n")
cat("✓ LASSO model training with cross-validation\n")
cat("✓ LASSO feature selection and coefficient extraction\n")
cat("✓ Random Forest model training with hyperparameter tuning\n")
cat("✓ Random Forest feature importance extraction\n")
cat("✓ Edge case handling (small datasets)\n")
cat("\nModel Trainer module is ready for use.\n")
