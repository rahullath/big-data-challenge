# Test script for Model Evaluator module

# Source required modules
source("utils.R")
source("data_preprocessor.R")
source("model_trainer.R")
source("model_evaluator.R")

# Load required libraries
library(glmnet)
library(ranger)

# Set seed for reproducibility
set.seed(42)

log_message("Starting Model Evaluator test...")

# Load and preprocess data
log_message("Loading dataset...")
data <- load_dataset("financial_dataset.csv")

log_message("Handling missing values...")
cleaned <- handle_missing_values(data)
data_clean <- cleaned$cleaned_data

log_message("Splitting dataset...")
split_data <- split_dataset(data_clean, train_ratio = 0.8, seed = 42)

log_message("Normalizing features...")
normalized <- normalize_features(split_data$train, split_data$test)
train_data <- normalized$train_normalized
test_data <- normalized$test_normalized

# Train models
log_message("\n=== Training Models ===")
lasso_model <- train_lasso_model(train_data, nfolds = 5, seed = 42)
rf_model <- train_random_forest_model(train_data, seed = 42)

# Test predict_model function
log_message("\n=== Testing predict_model() ===")
lasso_predictions <- predict_model(
  model = lasso_model$model,
  test_data = test_data,
  model_type = "lasso",
  lambda_optimal = lasso_model$lambda_optimal
)
log_message(sprintf("LASSO predictions generated: %d values", length(lasso_predictions)))
log_message(sprintf("Sample predictions: %.4f, %.4f, %.4f", 
                    lasso_predictions[1], lasso_predictions[2], lasso_predictions[3]))

rf_predictions <- predict_model(
  model = rf_model$model,
  test_data = test_data,
  model_type = "rf"
)
log_message(sprintf("RF predictions generated: %d values", length(rf_predictions)))
log_message(sprintf("Sample predictions: %.4f, %.4f, %.4f", 
                    rf_predictions[1], rf_predictions[2], rf_predictions[3]))

# Test calculate_metrics function
log_message("\n=== Testing calculate_metrics() ===")
actual <- test_data$future_return
lasso_metrics <- calculate_metrics(actual, lasso_predictions)
log_message(sprintf("LASSO - MSE: %.6f, MAE: %.6f, R²: %.6f",
                    lasso_metrics$mse, lasso_metrics$mae, lasso_metrics$r_squared))

rf_metrics <- calculate_metrics(actual, rf_predictions)
log_message(sprintf("RF - MSE: %.6f, MAE: %.6f, R²: %.6f",
                    rf_metrics$mse, rf_metrics$mae, rf_metrics$r_squared))

# Test evaluate_model function
log_message("\n=== Testing evaluate_model() ===")
lasso_eval <- evaluate_model(
  model = lasso_model$model,
  test_data = test_data,
  model_type = "lasso",
  lambda_optimal = lasso_model$lambda_optimal
)

rf_eval <- evaluate_model(
  model = rf_model$model,
  test_data = test_data,
  model_type = "rf"
)

# Test compare_models function
log_message("\n=== Testing compare_models() ===")
comparison <- compare_models(lasso_eval, rf_eval)

log_message("\n=== Comparison Table ===")
print(comparison$comparison_table)

log_message("\n=== All tests completed successfully! ===")
