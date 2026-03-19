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
  
  # Check if file exists before attempting to load
  if (!file.exists(file_path)) {
    stop(sprintf("Dataset file does not exist: '%s'", file_path))
  }
  
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
  
  # Validate dataset is not empty
  if (nrow(data) == 0) {
    stop("Dataset is empty (contains zero rows)")
  }
  
  # Validate column types - all required columns must be numeric
  non_numeric_cols <- character(0)
  for (col in required_cols) {
    if (!is.numeric(data[[col]])) {
      non_numeric_cols <- c(non_numeric_cols, col)
    }
  }
  
  if (length(non_numeric_cols) > 0) {
    stop(sprintf("Non-numeric columns detected (all columns must be numeric): %s", 
                 paste(non_numeric_cols, collapse = ", ")))
  }
  
  return(data)
}

#' Handle missing values in dataset
#'
#' @param data Input data.frame
#' @return List containing cleaned_data and removed_count
handle_missing_values <- function(data) {
  # Validate input
  if (nrow(data) == 0) {
    stop("Cannot handle missing values: input dataset is empty")
  }
  
  # Identify complete rows
  complete_rows <- complete.cases(data)
  
  # Count removed rows
  removed_count <- sum(!complete_rows)
  
  # Remove incomplete rows
  cleaned_data <- data[complete_rows, ]
  
  # Check if all rows were removed
  if (nrow(cleaned_data) == 0) {
    stop("All rows removed due to missing values. Dataset is empty after cleaning.")
  }
  
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
  # Validate input dataset
  if (nrow(data) == 0) {
    stop("Cannot split dataset: input dataset is empty")
  }
  
  # Validate train_ratio
  if (!is.numeric(train_ratio) || train_ratio <= 0 || train_ratio >= 1) {
    stop(sprintf("Invalid train_ratio: %.2f. Must be between 0 and 1 (exclusive)", train_ratio))
  }
  
  # Check if dataset has enough rows for meaningful split
  n <- nrow(data)
  n_train <- floor(n * train_ratio)
  n_test <- n - n_train
  
  if (n_train < 1) {
    stop(sprintf("Train set would be empty with train_ratio=%.2f and %d rows. Increase train_ratio or dataset size.", 
                 train_ratio, n))
  }
  
  if (n_test < 1) {
    stop(sprintf("Test set would be empty with train_ratio=%.2f and %d rows. Decrease train_ratio or dataset size.", 
                 train_ratio, n))
  }
  
  # Set random seed for reproducibility
  set.seed(seed)
  
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
  # Validate inputs
  if (nrow(train_data) == 0) {
    stop("Cannot normalize features: training dataset is empty")
  }
  
  if (nrow(test_data) == 0) {
    stop("Cannot normalize features: test dataset is empty")
  }
  
  if (!target_col %in% colnames(train_data)) {
    stop(sprintf("Target column '%s' not found in training data", target_col))
  }
  
  if (!target_col %in% colnames(test_data)) {
    stop(sprintf("Target column '%s' not found in test data", target_col))
  }
  
  # Identify feature columns (exclude target)
  feature_cols <- setdiff(colnames(train_data), target_col)
  
  if (length(feature_cols) == 0) {
    stop("No feature columns found for normalization (only target column present)")
  }
  
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
