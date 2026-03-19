# Test Error Handling for Stock Return Prediction System
# This script tests the error handling added in Task 13

# Source required modules
source("data_preprocessor.R")
source("model_trainer.R")
source("model_evaluator.R")
source("utils.R")

library(testthat)

cat("Testing Error Handling Implementation\n")
cat("======================================\n\n")

# Test 13.1: load_dataset() error handling
cat("Test 13.1: load_dataset() error handling\n")
cat("-----------------------------------------\n")

# Test 1: Missing file
test_that("load_dataset() handles missing file", {
  expect_error(
    load_dataset("nonexistent_file.csv"),
    "Dataset file does not exist"
  )
})
cat("✓ Missing file error handling works\n")

# Test 2: Empty dataset (we'll create a temporary empty CSV with correct columns)
temp_empty <- tempfile(fileext = ".csv")
empty_data <- data.frame(
  revenue_growth = numeric(0),
  profit_margin = numeric(0),
  debt_to_equity = numeric(0),
  pe_ratio = numeric(0),
  volatility = numeric(0),
  market_cap = numeric(0),
  interest_rate = numeric(0),
  inflation_rate = numeric(0),
  sector_score = numeric(0),
  previous_return = numeric(0),
  future_return = numeric(0)
)
write.csv(empty_data, temp_empty, row.names = FALSE)
test_that("load_dataset() handles empty dataset", {
  expect_error(
    load_dataset(temp_empty),
    "Dataset is empty"
  )
})
unlink(temp_empty)
cat("✓ Empty dataset error handling works\n")

# Test 3: Missing columns
temp_missing_cols <- tempfile(fileext = ".csv")
write.csv(data.frame(col1 = 1:5, col2 = 1:5), temp_missing_cols, row.names = FALSE)
test_that("load_dataset() handles missing columns", {
  expect_error(
    load_dataset(temp_missing_cols),
    "Missing required columns"
  )
})
unlink(temp_missing_cols)
cat("✓ Missing columns error handling works\n")

# Test 4: Non-numeric columns
temp_non_numeric <- tempfile(fileext = ".csv")
test_data <- data.frame(
  revenue_growth = c("a", "b", "c"),
  profit_margin = 1:3,
  debt_to_equity = 1:3,
  pe_ratio = 1:3,
  volatility = 1:3,
  market_cap = 1:3,
  interest_rate = 1:3,
  inflation_rate = 1:3,
  sector_score = 1:3,
  previous_return = 1:3,
  future_return = 1:3
)
write.csv(test_data, temp_non_numeric, row.names = FALSE)
test_that("load_dataset() handles non-numeric columns", {
  expect_error(
    load_dataset(temp_non_numeric),
    "Non-numeric columns detected"
  )
})
unlink(temp_non_numeric)
cat("✓ Non-numeric columns error handling works\n\n")

# Test 13.2: Preprocessing functions error handling
cat("Test 13.2: Preprocessing functions error handling\n")
cat("--------------------------------------------------\n")

# Test 1: Empty dataset in handle_missing_values
test_that("handle_missing_values() handles empty dataset", {
  empty_df <- data.frame()
  expect_error(
    handle_missing_values(empty_df),
    "input dataset is empty"
  )
})
cat("✓ Empty dataset in handle_missing_values works\n")

# Test 2: All rows removed due to missing values
test_that("handle_missing_values() handles all rows with missing values", {
  all_na_df <- data.frame(a = c(NA, NA), b = c(NA, NA))
  expect_error(
    handle_missing_values(all_na_df),
    "All rows removed due to missing values"
  )
})
cat("✓ All rows removed error handling works\n")

# Test 3: Invalid train_ratio in split_dataset
test_that("split_dataset() handles invalid train_ratio", {
  test_df <- data.frame(a = 1:10, b = 1:10)
  expect_error(
    split_dataset(test_df, train_ratio = 1.5),
    "Invalid train_ratio"
  )
  expect_error(
    split_dataset(test_df, train_ratio = 0),
    "Invalid train_ratio"
  )
})
cat("✓ Invalid train_ratio error handling works\n")

# Test 4: Empty dataset in split_dataset
test_that("split_dataset() handles empty dataset", {
  empty_df <- data.frame()
  expect_error(
    split_dataset(empty_df),
    "input dataset is empty"
  )
})
cat("✓ Empty dataset in split_dataset works\n")

# Test 5: Empty dataset in normalize_features
test_that("normalize_features() handles empty datasets", {
  empty_df <- data.frame()
  expect_error(
    normalize_features(empty_df, empty_df),
    "training dataset is empty"
  )
})
cat("✓ Empty dataset in normalize_features works\n")

# Test 6: Missing target column in normalize_features
test_that("normalize_features() handles missing target column", {
  test_df <- data.frame(a = 1:10, b = 1:10)
  expect_error(
    normalize_features(test_df, test_df, target_col = "nonexistent"),
    "Target column 'nonexistent' not found"
  )
})
cat("✓ Missing target column error handling works\n\n")

# Test 13.3: Model training error handling
cat("Test 13.3: Model training error handling\n")
cat("-----------------------------------------\n")

# Test 1: Empty dataset in train_lasso_model
test_that("train_lasso_model() handles empty dataset", {
  empty_df <- data.frame()
  expect_error(
    train_lasso_model(empty_df),
    "training dataset is empty"
  )
})
cat("✓ Empty dataset in train_lasso_model works\n")

# Test 2: Missing target column in train_lasso_model
test_that("train_lasso_model() handles missing target column", {
  test_df <- data.frame(a = 1:10, b = 1:10)
  expect_error(
    train_lasso_model(test_df, target_col = "nonexistent"),
    "Target column 'nonexistent' not found"
  )
})
cat("✓ Missing target column in train_lasso_model works\n")

# Test 3: Invalid nfolds in train_lasso_model
test_that("train_lasso_model() handles invalid nfolds", {
  test_df <- data.frame(a = 1:10, b = 1:10, future_return = 1:10)
  expect_error(
    train_lasso_model(test_df, nfolds = 1),
    "Invalid nfolds"
  )
})
cat("✓ Invalid nfolds error handling works\n")

# Test 4: Empty dataset in train_random_forest_model
test_that("train_random_forest_model() handles empty dataset", {
  empty_df <- data.frame()
  expect_error(
    train_random_forest_model(empty_df),
    "training dataset is empty"
  )
})
cat("✓ Empty dataset in train_random_forest_model works\n\n")

# Test 13.4: Model evaluation error handling
cat("Test 13.4: Model evaluation error handling\n")
cat("-------------------------------------------\n")

# Test 1: Empty dataset in predict_model
test_that("predict_model() handles empty dataset", {
  # Create a minimal model (we'll use NULL to test NULL model handling)
  expect_error(
    predict_model(NULL, data.frame(), "lasso"),
    "Model object is NULL"
  )
})
cat("✓ NULL model in predict_model works\n")

# Test 2: Length mismatch in calculate_metrics
test_that("calculate_metrics() handles length mismatch", {
  expect_error(
    calculate_metrics(c(1, 2, 3), c(1, 2)),
    "Length mismatch"
  )
})
cat("✓ Length mismatch in calculate_metrics works\n")

# Test 3: Empty vectors in calculate_metrics
test_that("calculate_metrics() handles empty vectors", {
  expect_error(
    calculate_metrics(numeric(0), numeric(0)),
    "Cannot calculate metrics on empty vectors"
  )
})
cat("✓ Empty vectors in calculate_metrics works\n")

# Test 4: NA values in calculate_metrics
test_that("calculate_metrics() handles NA values", {
  expect_error(
    calculate_metrics(c(1, 2, NA), c(1, 2, 3)),
    "NA values detected"
  )
})
cat("✓ NA values in calculate_metrics works\n")

# Test 5: Infinite values in calculate_metrics
test_that("calculate_metrics() handles infinite values", {
  expect_error(
    calculate_metrics(c(1, 2, Inf), c(1, 2, 3)),
    "infinite values detected"
  )
})
cat("✓ Infinite values in calculate_metrics works\n")

# Test 6: Zero variance in calculate_metrics (should warn, not error)
test_that("calculate_metrics() handles zero variance", {
  expect_warning(
    result <- calculate_metrics(c(5, 5, 5), c(1, 2, 3)),
    "zero variance"
  )
  expect_true(is.na(result$r_squared))
})
cat("✓ Zero variance warning in calculate_metrics works\n")

cat("\n======================================\n")
cat("All error handling tests passed! ✓\n")
cat("======================================\n")
