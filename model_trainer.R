# Model Training Module for Stock Return Prediction System

# This module handles LASSO and Random Forest model training
# with hyperparameter tuning

#' Train LASSO Regression Model with Cross-Validation
#'
#' Trains a LASSO regression model using cross-validation to select the optimal
#' regularization parameter. Identifies features with non-zero coefficients.
#'
#' @param train_data Training dataset (data.frame)
#' @param target_col Name of the target variable column (default: "future_return")
#' @param nfolds Number of cross-validation folds (default: 5)
#' @param seed Random seed for reproducibility (default: 42)
#'
#' @return List containing:
#'   - model: Fitted cv.glmnet model object
#'   - lambda_optimal: Selected lambda.min value
#'   - coefficients: Named vector of non-zero coefficients
#'   - selected_features: Character vector of feature names with non-zero coefficients
#'
#' @examples
#' lasso_result <- train_lasso_model(train_data, target_col = "future_return", nfolds = 5)
train_lasso_model <- function(train_data, target_col = "future_return", nfolds = 5, seed = 42) {
  # Load required library
  if (!require(glmnet)) {
    stop("Package 'glmnet' is required but not installed.")
  }
  
  # Set random seed for reproducibility
  set.seed(seed)
  
  # Validate inputs
  if (nrow(train_data) == 0) {
    stop("Cannot train LASSO model: training dataset is empty")
  }
  
  if (!target_col %in% colnames(train_data)) {
    stop(sprintf("Target column '%s' not found in training data.", target_col))
  }
  
  if (nfolds < 2) {
    stop(sprintf("Invalid nfolds: %d. Must be at least 2 for cross-validation.", nfolds))
  }
  
  if (nrow(train_data) < nfolds) {
    stop(sprintf("Training data has %d rows but %d folds requested. Reduce nfolds.", 
                 nrow(train_data), nfolds))
  }
  
  # Prepare feature matrix and target vector
  feature_cols <- setdiff(colnames(train_data), target_col)
  
  if (length(feature_cols) == 0) {
    stop("No feature columns found in training data (only target column present)")
  }
  
  # Check for sufficient training data relative to features
  if (nrow(train_data) < length(feature_cols)) {
    warning(sprintf("Training data has fewer samples (%d) than features (%d). Model may overfit.", 
                    nrow(train_data), length(feature_cols)))
  }
  
  # Create design matrix (excluding intercept as glmnet adds it automatically)
  X <- as.matrix(train_data[, feature_cols])
  y <- train_data[[target_col]]
  
  # Train LASSO model with cross-validation
  # alpha = 1 specifies LASSO (L1 regularization)
  tryCatch({
    cv_model <- glmnet::cv.glmnet(
      x = X,
      y = y,
      alpha = 1,           # LASSO penalty
      nfolds = nfolds,     # Number of CV folds
      standardize = FALSE  # Features already normalized
    )
  }, error = function(e) {
    stop(sprintf("LASSO cross-validation failed: %s", e$message))
  })
  
  # Validate that optimal lambda was selected
  if (is.null(cv_model$lambda.min)) {
    stop("LASSO cross-validation failed to select optimal lambda")
  }
  
  # Extract optimal lambda (lambda.min minimizes CV error)
  lambda_optimal <- cv_model$lambda.min
  
  # Extract coefficients at optimal lambda
  coef_matrix <- coef(cv_model, s = lambda_optimal)
  coef_vector <- as.vector(coef_matrix)
  names(coef_vector) <- rownames(coef_matrix)
  
  # Identify non-zero coefficients (excluding intercept)
  non_zero_idx <- which(coef_vector != 0)
  non_zero_coefs <- coef_vector[non_zero_idx]
  
  # Remove intercept from coefficients if present
  if ("(Intercept)" %in% names(non_zero_coefs)) {
    non_zero_coefs <- non_zero_coefs[names(non_zero_coefs) != "(Intercept)"]
  }
  
  # Extract selected feature names
  selected_features <- names(non_zero_coefs)
  
  # Log results
  log_message(sprintf("LASSO training completed with %d-fold CV", nfolds))
  log_message(sprintf("Optimal lambda: %.6f", lambda_optimal))
  log_message(sprintf("Selected %d out of %d features", 
                      length(selected_features), length(feature_cols)))
  
  # Return results
  return(list(
    model = cv_model,
    lambda_optimal = lambda_optimal,
    coefficients = non_zero_coefs,
    selected_features = selected_features
  ))
}


#' Train Random Forest Model with Hyperparameter Tuning
#'
#' Trains a Random Forest regression model with hyperparameter tuning for
#' number of trees and maximum tree depth. Extracts feature importance scores.
#'
#' @param train_data Training dataset (data.frame)
#' @param target_col Name of the target variable column (default: "future_return")
#' @param seed Random seed for reproducibility (default: 42)
#'
#' @return List containing:
#'   - model: Fitted ranger or randomForest model object
#'   - best_params: List of optimal hyperparameters (ntree, max_depth)
#'   - feature_importance: Named vector of importance scores sorted descending
#'
#' @examples
#' rf_result <- train_random_forest_model(train_data, target_col = "future_return")
train_random_forest_model <- function(train_data, target_col = "future_return", seed = 42) {
  # Load required libraries
  if (!require(ranger)) {
    if (!require(randomForest)) {
      stop("Either 'ranger' or 'randomForest' package is required but neither is installed.")
    }
    use_ranger <- FALSE
  } else {
    use_ranger <- TRUE
  }
  
  # Set random seed for reproducibility
  set.seed(seed)
  
  # Validate inputs
  if (nrow(train_data) == 0) {
    stop("Cannot train Random Forest model: training dataset is empty")
  }
  
  if (!target_col %in% colnames(train_data)) {
    stop(sprintf("Target column '%s' not found in training data.", target_col))
  }
  
  # Prepare feature columns and target
  feature_cols <- setdiff(colnames(train_data), target_col)
  
  if (length(feature_cols) == 0) {
    stop("No feature columns found in training data (only target column present)")
  }
  
  # Check for sufficient training data
  if (nrow(train_data) < 10) {
    warning(sprintf("Training data has only %d rows. Random Forest may not perform well with very small datasets.", 
                    nrow(train_data)))
  }
  
  # Define hyperparameter grid for tuning
  ntree_values <- c(100, 300, 500)
  max_depth_values <- c(5, 10, 15)  # Reasonable depth values
  
  # Initialize variables to track best model
  best_model <- NULL
  best_oob_error <- Inf
  best_ntree <- NULL
  best_max_depth <- NULL
  
  log_message("Starting Random Forest hyperparameter tuning...")
  
  # Manual grid search for hyperparameter tuning
  for (ntree in ntree_values) {
    for (max_depth in max_depth_values) {
      
      tryCatch({
        if (use_ranger) {
          # Use ranger (faster implementation)
          model <- ranger::ranger(
            formula = as.formula(paste(target_col, "~ .")),
            data = train_data,
            num.trees = ntree,
            max.depth = max_depth,
            importance = "impurity",  # Calculate feature importance
            seed = seed
          )
          oob_error <- model$prediction.error
        } else {
          # Use randomForest
          model <- randomForest::randomForest(
            formula = as.formula(paste(target_col, "~ .")),
            data = train_data,
            ntree = ntree,
            maxnodes = 2^max_depth,  # Approximate max depth control
            importance = TRUE,
            seed = seed
          )
          oob_error <- tail(model$mse, 1)  # Final OOB MSE
        }
        
        # Update best model if this one is better
        if (oob_error < best_oob_error) {
          best_oob_error <- oob_error
          best_model <- model
          best_ntree <- ntree
          best_max_depth <- max_depth
        }
        
        log_message(sprintf("  ntree=%d, max_depth=%d, OOB_error=%.6f", 
                            ntree, max_depth, oob_error))
        
      }, error = function(e) {
        warning(sprintf("Failed to train RF with ntree=%d, max_depth=%d: %s", 
                        ntree, max_depth, e$message))
      })
    }
  }
  
  # Validate that a model was successfully trained
  if (is.null(best_model)) {
    stop("Random Forest hyperparameter tuning failed: no model could be trained")
  }
  
  # Extract feature importance
  if (use_ranger) {
    importance_scores <- best_model$variable.importance
  } else {
    # For randomForest, use %IncMSE (increase in MSE when variable is permuted)
    importance_scores <- randomForest::importance(best_model)[, "%IncMSE"]
  }
  
  # Sort feature importance in descending order
  importance_sorted <- sort(importance_scores, decreasing = TRUE)
  
  # Log results
  log_message(sprintf("Random Forest training completed"))
  log_message(sprintf("Best parameters: ntree=%d, max_depth=%d", best_ntree, best_max_depth))
  log_message(sprintf("Best OOB error: %.6f", best_oob_error))
  log_message(sprintf("Top 3 important features: %s", 
                      paste(names(importance_sorted)[1:min(3, length(importance_sorted))], 
                            collapse=", ")))
  
  # Return results
  return(list(
    model = best_model,
    best_params = list(
      ntree = best_ntree,
      max_depth = best_max_depth
    ),
    feature_importance = importance_sorted
  ))
}
