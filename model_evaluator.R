# Model Evaluation Module for Stock Return Prediction System

# This module handles model prediction, metric calculation,
# and model comparison

#' Generate Predictions from Trained Model
#'
#' Generates predictions from a trained LASSO or Random Forest model on test data.
#'
#' @param model Trained model object (cv.glmnet for LASSO, ranger/randomForest for RF)
#' @param test_data Test dataset (data.frame)
#' @param model_type Type of model: "lasso" or "rf"
#' @param lambda_optimal Optimal lambda value (required for LASSO models)
#' @param target_col Name of target variable to exclude from features (default: "future_return")
#'
#' @return Numeric vector of predictions
#'
#' @examples
#' predictions <- predict_model(lasso_model$model, test_data, "lasso", 
#'                               lambda_optimal = lasso_model$lambda_optimal)
predict_model <- function(model, test_data, model_type = c("lasso", "rf"), 
                          lambda_optimal = NULL, target_col = "future_return") {
  # Validate model_type
  model_type <- match.arg(model_type)
  
  # Prepare feature matrix (exclude target column)
  feature_cols <- setdiff(colnames(test_data), target_col)
  
  # Generate predictions based on model type
  if (model_type == "lasso") {
    # LASSO predictions using glmnet
    if (is.null(lambda_optimal)) {
      stop("lambda_optimal is required for LASSO predictions")
    }
    
    # Prepare design matrix
    X_test <- as.matrix(test_data[, feature_cols])
    
    # Generate predictions at optimal lambda
    predictions <- as.vector(predict(model, newx = X_test, s = lambda_optimal))
    
  } else if (model_type == "rf") {
    # Random Forest predictions
    # Check if model is ranger or randomForest
    if (inherits(model, "ranger")) {
      # Use ranger predict
      pred_result <- predict(model, data = test_data)
      predictions <- pred_result$predictions
    } else if (inherits(model, "randomForest")) {
      # Use randomForest predict
      predictions <- predict(model, newdata = test_data)
    } else {
      stop("Unknown Random Forest model type. Expected 'ranger' or 'randomForest' object.")
    }
  }
  
  # Ensure predictions are numeric vector
  predictions <- as.numeric(predictions)
  
  return(predictions)
}


#' Calculate Performance Metrics
#'
#' Calculates Mean Squared Error (MSE), Mean Absolute Error (MAE), and R² Score
#' for model predictions.
#'
#' @param actual Numeric vector of actual values
#' @param predicted Numeric vector of predicted values
#'
#' @return List containing:
#'   - mse: Mean Squared Error
#'   - mae: Mean Absolute Error
#'   - r_squared: R² Score
#'
#' @examples
#' metrics <- calculate_metrics(test_data$future_return, predictions)
calculate_metrics <- function(actual, predicted) {
  # Validate inputs
  if (length(actual) != length(predicted)) {
    stop("Length of actual and predicted vectors must match")
  }
  
  if (length(actual) == 0) {
    stop("Cannot calculate metrics on empty vectors")
  }
  
  # Calculate Mean Squared Error
  mse <- mean((actual - predicted)^2)
  
  # Calculate Mean Absolute Error
  mae <- mean(abs(actual - predicted))
  
  # Calculate R² Score
  # R² = 1 - (SS_res / SS_tot)
  # where SS_res = sum of squared residuals
  #       SS_tot = total sum of squares
  ss_res <- sum((actual - predicted)^2)
  ss_tot <- sum((actual - mean(actual))^2)
  
  # Handle edge case where all actual values are the same
  if (ss_tot == 0) {
    warning("All actual values are identical. R² is undefined, returning NA.")
    r_squared <- NA
  } else {
    r_squared <- 1 - (ss_res / ss_tot)
  }
  
  # Return metrics as list
  return(list(
    mse = mse,
    mae = mae,
    r_squared = r_squared
  ))
}


#' Evaluate Model Performance
#'
#' Complete evaluation pipeline for a single model. Generates predictions and
#' calculates performance metrics.
#'
#' @param model Trained model object
#' @param test_data Test dataset (data.frame)
#' @param target_col Name of target variable (default: "future_return")
#' @param model_type Type of model: "lasso" or "rf"
#' @param lambda_optimal Optimal lambda value (required for LASSO models)
#'
#' @return List containing:
#'   - predictions: Numeric vector of predictions
#'   - metrics: List with mse, mae, r_squared
#'
#' @examples
#' lasso_eval <- evaluate_model(lasso_model$model, test_data, 
#'                               model_type = "lasso", 
#'                               lambda_optimal = lasso_model$lambda_optimal)
evaluate_model <- function(model, test_data, target_col = "future_return", 
                           model_type = c("lasso", "rf"), lambda_optimal = NULL) {
  # Validate model_type
  model_type <- match.arg(model_type)
  
  # Validate that target column exists
  if (!target_col %in% colnames(test_data)) {
    stop(sprintf("Target column '%s' not found in test data", target_col))
  }
  
  # Extract actual values
  actual <- test_data[[target_col]]
  
  # Generate predictions using predict_model()
  predictions <- predict_model(
    model = model,
    test_data = test_data,
    model_type = model_type,
    lambda_optimal = lambda_optimal,
    target_col = target_col
  )
  
  # Calculate metrics using calculate_metrics()
  metrics <- calculate_metrics(actual, predictions)
  
  # Log evaluation results
  log_message(sprintf("%s model evaluation completed", 
                      ifelse(model_type == "lasso", "LASSO", "Random Forest")))
  log_message(sprintf("  MSE: %.6f", metrics$mse))
  log_message(sprintf("  MAE: %.6f", metrics$mae))
  log_message(sprintf("  R²: %.6f", metrics$r_squared))
  
  # Return predictions and metrics
  return(list(
    predictions = predictions,
    metrics = metrics
  ))
}


#' Compare Model Performance
#'
#' Compares performance of LASSO and Random Forest models side-by-side.
#' Identifies the best model by each metric and determines overall best model.
#'
#' @param lasso_results Evaluation results from LASSO model (from evaluate_model())
#' @param rf_results Evaluation results from Random Forest model (from evaluate_model())
#'
#' @return List containing:
#'   - comparison_table: data.frame with metrics for both models
#'   - best_by_r2: Model name with highest R²
#'   - best_by_mse: Model name with lowest MSE
#'   - best_by_mae: Model name with lowest MAE
#'   - overall_best: Model name with best overall performance
#'
#' @examples
#' comparison <- compare_models(lasso_eval, rf_eval)
compare_models <- function(lasso_results, rf_results) {
  # Validate inputs
  if (!all(c("metrics") %in% names(lasso_results))) {
    stop("lasso_results must contain 'metrics' element")
  }
  if (!all(c("metrics") %in% names(rf_results))) {
    stop("rf_results must contain 'metrics' element")
  }
  
  # Extract metrics
  lasso_metrics <- lasso_results$metrics
  rf_metrics <- rf_results$metrics
  
  # Create comparison table
  comparison_table <- data.frame(
    Model = c("LASSO", "Random Forest"),
    MSE = c(lasso_metrics$mse, rf_metrics$mse),
    MAE = c(lasso_metrics$mae, rf_metrics$mae),
    R_Squared = c(lasso_metrics$r_squared, rf_metrics$r_squared),
    stringsAsFactors = FALSE
  )
  
  # Identify best model by each metric
  # R² - higher is better
  best_by_r2 <- comparison_table$Model[which.max(comparison_table$R_Squared)]
  
  # MSE - lower is better
  best_by_mse <- comparison_table$Model[which.min(comparison_table$MSE)]
  
  # MAE - lower is better
  best_by_mae <- comparison_table$Model[which.min(comparison_table$MAE)]
  
  # Determine overall best model
  # Prioritize R² as primary metric (as specified in design)
  # If R² is close (within 0.01), use MSE as tiebreaker
  r2_diff <- abs(comparison_table$R_Squared[1] - comparison_table$R_Squared[2])
  
  if (r2_diff > 0.01) {
    # Clear winner by R²
    overall_best <- best_by_r2
  } else {
    # R² values are close, use MSE as tiebreaker
    overall_best <- best_by_mse
  }
  
  # Log comparison results
  log_message("Model Comparison Results:")
  log_message(paste(rep("=", 60), collapse = ""))
  log_message(sprintf("%-20s %12s %12s %12s", "Model", "MSE", "MAE", "R²"))
  log_message(paste(rep("-", 60), collapse = ""))
  log_message(sprintf("%-20s %12.6f %12.6f %12.6f", 
                      "LASSO", lasso_metrics$mse, lasso_metrics$mae, lasso_metrics$r_squared))
  log_message(sprintf("%-20s %12.6f %12.6f %12.6f", 
                      "Random Forest", rf_metrics$mse, rf_metrics$mae, rf_metrics$r_squared))
  log_message(paste(rep("=", 60), collapse = ""))
  log_message(sprintf("Best by R²: %s", best_by_r2))
  log_message(sprintf("Best by MSE: %s", best_by_mse))
  log_message(sprintf("Best by MAE: %s", best_by_mae))
  log_message(sprintf("Overall Best Model: %s", overall_best))
  
  # Return comparison results
  return(list(
    comparison_table = comparison_table,
    best_by_r2 = best_by_r2,
    best_by_mse = best_by_mse,
    best_by_mae = best_by_mae,
    overall_best = overall_best
  ))
}
