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
  
  # Validate inputs
  if (is.null(model)) {
    stop("Model object is NULL. Cannot generate predictions.")
  }
  
  if (nrow(test_data) == 0) {
    stop("Cannot generate predictions: test dataset is empty")
  }
  
  # Prepare feature matrix (exclude target column)
  feature_cols <- setdiff(colnames(test_data), target_col)
  
  if (length(feature_cols) == 0) {
    stop("No feature columns found in test data for prediction")
  }
  
  # Generate predictions based on model type
  predictions <- tryCatch({
    if (model_type == "lasso") {
      # LASSO predictions using glmnet
      if (is.null(lambda_optimal)) {
        stop("lambda_optimal is required for LASSO predictions")
      }
      
      # Prepare design matrix
      X_test <- as.matrix(test_data[, feature_cols])
      
      # Generate predictions at optimal lambda
      as.vector(predict(model, newx = X_test, s = lambda_optimal))
      
    } else if (model_type == "rf") {
      # Random Forest predictions
      # Check if model is ranger or randomForest
      if (inherits(model, "ranger")) {
        # Use ranger predict
        pred_result <- predict(model, data = test_data)
        pred_result$predictions
      } else if (inherits(model, "randomForest")) {
        # Use randomForest predict
        predict(model, newdata = test_data)
      } else {
        stop("Unknown Random Forest model type. Expected 'ranger' or 'randomForest' object.")
      }
    }
  }, error = function(e) {
    stop(sprintf("Prediction generation failed for %s model: %s", 
                 toupper(model_type), e$message))
  })
  
  # Ensure predictions are numeric vector
  predictions <- as.numeric(predictions)
  
  # Validate predictions were generated
  if (length(predictions) == 0) {
    stop("Prediction generation failed: no predictions returned")
  }
  
  if (length(predictions) != nrow(test_data)) {
    stop(sprintf("Prediction count mismatch: expected %d predictions, got %d", 
                 nrow(test_data), length(predictions)))
  }
  
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
    stop(sprintf("Length mismatch: actual has %d values, predicted has %d values", 
                 length(actual), length(predicted)))
  }
  
  if (length(actual) == 0) {
    stop("Cannot calculate metrics on empty vectors")
  }
  
  if (!is.numeric(actual) || !is.numeric(predicted)) {
    stop("Both actual and predicted values must be numeric")
  }
  
  # Check for NA or infinite values
  if (any(is.na(actual)) || any(is.na(predicted))) {
    stop("Cannot calculate metrics: NA values detected in actual or predicted values")
  }
  
  if (any(is.infinite(actual)) || any(is.infinite(predicted))) {
    stop("Cannot calculate metrics: infinite values detected in actual or predicted values")
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
  
  # Handle edge case where all actual values are the same (zero variance)
  if (ss_tot == 0) {
    warning("All actual values are identical (zero variance). R² is undefined, returning NA.")
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
  
  # Validate inputs
  if (is.null(model)) {
    stop("Model object is NULL. Cannot evaluate model.")
  }
  
  if (nrow(test_data) == 0) {
    stop("Cannot evaluate model: test dataset is empty")
  }
  
  # Validate that target column exists
  if (!target_col %in% colnames(test_data)) {
    stop(sprintf("Target column '%s' not found in test data", target_col))
  }
  
  # Extract actual values
  actual <- test_data[[target_col]]
  
  # Validate actual values
  if (any(is.na(actual))) {
    stop("Target column contains NA values in test data")
  }
  
  # Generate predictions using predict_model()
  predictions <- tryCatch({
    predict_model(
      model = model,
      test_data = test_data,
      model_type = model_type,
      lambda_optimal = lambda_optimal,
      target_col = target_col
    )
  }, error = function(e) {
    stop(sprintf("Model evaluation failed during prediction: %s", e$message))
  })
  
  # Calculate metrics using calculate_metrics()
  metrics <- tryCatch({
    calculate_metrics(actual, predictions)
  }, error = function(e) {
    stop(sprintf("Model evaluation failed during metric calculation: %s", e$message))
  })
  
  # Log evaluation results
  log_message(sprintf("%s model evaluation completed", 
                      ifelse(model_type == "lasso", "LASSO", "Random Forest")))
  log_message(sprintf("  MSE: %.6f", metrics$mse))
  log_message(sprintf("  MAE: %.6f", metrics$mae))
  if (!is.na(metrics$r_squared)) {
    log_message(sprintf("  R²: %.6f", metrics$r_squared))
  } else {
    log_message("  R²: NA (zero variance in actual values)")
  }
  
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
