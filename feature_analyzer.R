# Feature Analysis Module for Stock Return Prediction System

# This module handles descriptive statistics, correlation analysis,
# and feature importance aggregation

#' Compute Descriptive Statistics
#'
#' Calculate summary statistics for all variables in the dataset
#'
#' @param data Input data.frame
#' @param target_col Name of target variable (default: "future_return")
#' @return data.frame with columns: variable, mean, median, sd, min, max
#' @export
compute_descriptive_statistics <- function(data, target_col = "future_return") {
  # Get all column names
  all_cols <- colnames(data)
  
  # Initialize result data frame
  stats_list <- lapply(all_cols, function(col) {
    values <- data[[col]]
    data.frame(
      variable = col,
      mean = mean(values, na.rm = TRUE),
      median = median(values, na.rm = TRUE),
      sd = sd(values, na.rm = TRUE),
      min = min(values, na.rm = TRUE),
      max = max(values, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  
  # Combine all statistics into single data frame
  stats_df <- do.call(rbind, stats_list)
  
  return(stats_df)
}

#' Compute Correlation Matrix
#'
#' Calculate pairwise correlations between all variables
#'
#' @param data Input data.frame
#' @return Correlation matrix (matrix object)
#' @export
compute_correlation_matrix <- function(data) {
  # Calculate Pearson correlation for all numeric columns
  cor_matrix <- cor(data, method = "pearson", use = "complete.obs")
  
  return(cor_matrix)
}

#' Extract Target Correlations
#'
#' Extract correlations between features and target variable
#'
#' @param correlation_matrix Correlation matrix from compute_correlation_matrix()
#' @param target_col Name of target variable (default: "future_return")
#' @return Named numeric vector of feature-target correlations sorted by absolute value
#' @export
extract_target_correlations <- function(correlation_matrix, target_col = "future_return") {
  # Extract target column from correlation matrix
  target_cors <- correlation_matrix[, target_col]
  
  # Remove target's self-correlation
  target_cors <- target_cors[names(target_cors) != target_col]
  
  # Sort by absolute correlation strength (descending)
  target_cors <- target_cors[order(abs(target_cors), decreasing = TRUE)]
  
  return(target_cors)
}

#' Aggregate Feature Importance
#'
#' Combine feature importance from LASSO and Random Forest models
#'
#' @param lasso_coefficients Named numeric vector of LASSO coefficients
#' @param rf_importance Named numeric vector of Random Forest importance scores
#' @return data.frame with columns: feature, lasso_importance, rf_importance, combined_score
#'         Sorted by combined_score in descending order, top 5 features only
#' @export
aggregate_feature_importance <- function(lasso_coefficients, rf_importance) {
  # Get all unique feature names from both models
  all_features <- unique(c(names(lasso_coefficients), names(rf_importance)))
  
  # Initialize vectors for normalized importance
  lasso_norm <- numeric(length(all_features))
  rf_norm <- numeric(length(all_features))
  names(lasso_norm) <- all_features
  names(rf_norm) <- all_features
  
  # Normalize LASSO coefficients (absolute values) to [0,1] scale
  if (length(lasso_coefficients) > 0) {
    lasso_abs <- abs(lasso_coefficients)
    if (max(lasso_abs) > 0) {
      lasso_normalized <- lasso_abs / max(lasso_abs)
      lasso_norm[names(lasso_normalized)] <- lasso_normalized
    }
  }
  
  # Normalize RF importance to [0,1] scale
  if (length(rf_importance) > 0) {
    if (max(rf_importance) > 0) {
      rf_normalized <- rf_importance / max(rf_importance)
      rf_norm[names(rf_normalized)] <- rf_normalized
    }
  }
  
  # Compute combined score as average of normalized values
  combined_scores <- (lasso_norm + rf_norm) / 2
  
  # Create result data frame
  result_df <- data.frame(
    feature = all_features,
    lasso_importance = lasso_norm,
    rf_importance = rf_norm,
    combined_score = combined_scores,
    stringsAsFactors = FALSE
  )
  
  # Sort by combined score (descending) and return top 5
  result_df <- result_df[order(result_df$combined_score, decreasing = TRUE), ]
  result_df <- head(result_df, 5)
  
  return(result_df)
}
