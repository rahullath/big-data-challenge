# Data Preprocessing Module for Stock Return Prediction System

# This module handles data loading, validation, cleaning, normalization,
# and train/test splitting

library(readr)

#' Load and validate financial dataset
#'
#' @param file_path Character string path to CSV file
#' @return data.frame with validated columns
#' @throws Error if file missing or columns invalid
load_dataset <- function(file_path) {
  # Define required columns
  required_cols <- c(
    "revenue_growth", "profit_margin", "debt_to_equity", 
    "pe_ratio", "volatility", "market_cap", "interest_rate",
    "inflation_rate", "sector_score", "previous_return", 
    "future_return"
  )
  
  # Load CSV file with error handling
  data <- tryCatch({
    readr::read_csv(file_path, show_col_types = FALSE)
  }, error = function(e) {
    stop(sprintf("Failed to load dataset from '%s': %s", file_path, e$message))
  })
  
  # Validate presence of all required columns
  missing_cols <- setdiff(required_cols, colnames(data))
  if (length(missing_cols) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
  }
  
  return(data)
}

#' Handle missing values in dataset
#'
#' @param data Input data.frame
#' @return List containing cleaned_data and removed_count
handle_missing_values <- function(data) {
  # Identify complete rows
  complete_rows <- complete.cases(data)
  
  # Count removed rows
  removed_count <- sum(!complete_rows)
  
  # Remove incomplete rows
  cleaned_data <- data[complete_rows, ]
  
  # Log removal count
  if (removed_count > 0) {
    message(sprintf("Removed %d rows with missing values", removed_count))
  }
  
  return(list(
    cleaned_data = cleaned_data,
    removed_count = removed_count
  ))
}

#' Split dataset into training and test sets
#'
#' @param data Input data.frame
#' @param train_ratio Proportion for training (default 0.8)
#' @param seed Random seed for reproducibility (default 42)
#' @return List containing train and test data.frames
split_dataset <- function(data, train_ratio = 0.8, seed = 42) {
  # Set random seed for reproducibility
  set.seed(seed)
  
  # Calculate number of training samples
  n <- nrow(data)
  n_train <- floor(n * train_ratio)
  
  # Randomly sample training indices
  train_indices <- sample(1:n, n_train)
  
  # Split data
  train <- data[train_indices, ]
  test <- data[-train_indices, ]
  
  return(list(
    train = train,
    test = test
  ))
}

#' Normalize features to zero mean and unit variance
#'
#' @param train_data Training set data.frame
#' @param test_data Test set data.frame
#' @param target_col Name of target variable to exclude from normalization
#' @return List containing train_normalized, test_normalized, and normalization_params
normalize_features <- function(train_data, test_data, target_col = "future_return") {
  # Identify feature columns (exclude target)
  feature_cols <- setdiff(colnames(train_data), target_col)
  
  # Calculate mean and standard deviation from training set only
  means <- sapply(train_data[, feature_cols], mean)
  sds <- sapply(train_data[, feature_cols], sd)
  
  # Check for zero variance features
  zero_var_features <- names(sds[sds == 0])
  if (length(zero_var_features) > 0) {
    warning(sprintf("Features with zero variance (will not be normalized): %s", 
                    paste(zero_var_features, collapse = ", ")))
    # Set sd to 1 for zero variance features to avoid division by zero
    sds[sds == 0] <- 1
  }
  
  # Normalize training set
  train_normalized <- train_data
  for (col in feature_cols) {
    train_normalized[[col]] <- (train_data[[col]] - means[col]) / sds[col]
  }
  
  # Normalize test set using training parameters
  test_normalized <- test_data
  for (col in feature_cols) {
    test_normalized[[col]] <- (test_data[[col]] - means[col]) / sds[col]
  }
  
  # Store normalization parameters
  normalization_params <- list(
    means = means,
    sds = sds
  )
  
  return(list(
    train_normalized = train_normalized,
    test_normalized = test_normalized,
    normalization_params = normalization_params
  ))
}
