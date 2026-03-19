# Design Document: Stock Return Prediction System

## Overview

The Stock Return Prediction System is an R-based machine learning application that predicts future stock returns using two complementary modeling approaches: LASSO Regression for interpretable feature selection and Random Forest for capturing nonlinear relationships. The system implements a complete ML pipeline including data loading, preprocessing, feature analysis, model training, and comprehensive evaluation.

### Design Goals

1. **Reproducibility**: Fixed random seeds and deterministic preprocessing ensure consistent results
2. **Modularity**: Separate components for data preprocessing, feature analysis, model training, and evaluation
3. **Interpretability**: Feature importance analysis and coefficient extraction for both models
4. **Performance**: Efficient R implementations using established packages (glmnet, ranger/randomForest)
5. **Robustness**: Comprehensive error handling for missing files, invalid data, and training failures

### Technology Stack

- **Language**: R (version 4.0+)
- **IDE**: RStudio
- **Core Packages**:
  - `glmnet`: LASSO regression with cross-validation
  - `ranger` or `randomForest`: Random Forest implementation
  - `caret`: Unified interface for model training and tuning
  - `dplyr`: Data manipulation
  - `readr`: CSV file reading
  - `corrplot` or `ggcorrplot`: Correlation visualization (optional)

## Architecture

### System Components

The system follows a pipeline architecture with four main components:

1. **Data Preprocessor**: Handles data loading, validation, cleaning, normalization, and train/test splitting
2. **Feature Analyzer**: Computes descriptive statistics, correlation matrices, and feature importance aggregation
3. **Model Trainer**: Encapsulates LASSO and Random Forest training logic with hyperparameter tuning
4. **Model Evaluator**: Calculates performance metrics and generates comparison reports

### Data Flow

```
financial_dataset.csv
        ↓
[Data Preprocessor]
  - Load & Validate
  - Handle Missing Values
  - Train/Test Split (80/20)
  - Normalize Features
        ↓
[Feature Analyzer]
  - Descriptive Statistics
  - Correlation Analysis
        ↓
[Model Trainer]
  ├─→ [LASSO Model]
  │     - Cross-validation
  │     - Feature Selection
  └─→ [Random Forest Model]
        - Hyperparameter Tuning
        - Feature Importance
        ↓
[Model Evaluator]
  - Calculate MSE, MAE, R²
  - Compare Models
  - Identify Best Model
        ↓
[Feature Analyzer]
  - Aggregate Feature Importance
  - Identify Top 5 Features
        ↓
Results & Reports
```

### Execution Flow

The main script (`main.R`) orchestrates the pipeline:

1. Initialize environment and load libraries
2. Execute data preprocessing pipeline
3. Generate descriptive statistics and correlations
4. Train LASSO model with cross-validation
5. Train Random Forest model with hyperparameter tuning
6. Evaluate both models on test set
7. Compare model performance
8. Analyze feature selection and importance
9. Output comprehensive results

## Components and Interfaces

### 1. Data Preprocessor Module (`data_preprocessor.R`)

#### `load_dataset(file_path)`
**Purpose**: Load and validate the financial dataset

**Parameters**:
- `file_path`: Character string path to CSV file

**Returns**: 
- `data.frame` with validated columns
- Throws error if file missing or columns invalid

**Behavior**:
- Uses `readr::read_csv()` for efficient loading
- Validates presence of all 10 features and target variable
- Returns detailed error messages for missing columns

#### `handle_missing_values(data)`
**Purpose**: Remove rows with missing values and log the count

**Parameters**:
- `data`: Input data.frame

**Returns**: 
- List containing:
  - `cleaned_data`: data.frame without missing values
  - `removed_count`: Integer count of removed rows

**Behavior**:
- Uses `complete.cases()` to identify complete rows
- Logs removal count to console
- Preserves all columns

#### `split_dataset(data, train_ratio = 0.8, seed = 42)`
**Purpose**: Split data into training and test sets with reproducibility

**Parameters**:
- `data`: Input data.frame
- `train_ratio`: Proportion for training (default 0.8)
- `seed`: Random seed for reproducibility (default 42)

**Returns**: 
- List containing:
  - `train`: Training set data.frame
  - `test`: Test set data.frame

**Behavior**:
- Sets random seed using `set.seed()`
- Uses `sample()` for random row selection
- Ensures both sets contain all columns

#### `normalize_features(train_data, test_data, target_col = "future_return")`
**Purpose**: Normalize features to zero mean and unit variance

**Parameters**:
- `train_data`: Training set data.frame
- `test_data`: Test set data.frame
- `target_col`: Name of target variable to exclude from normalization

**Returns**: 
- List containing:
  - `train_normalized`: Normalized training set
  - `test_normalized`: Normalized test set
  - `normalization_params`: List with means and standard deviations

**Behavior**:
- Calculates mean and sd from training set only
- Applies same transformation to test set (prevents data leakage)
- Uses `scale()` function or manual calculation
- Preserves target variable unchanged

### 2. Feature Analyzer Module (`feature_analyzer.R`)

#### `compute_descriptive_statistics(data, target_col = "future_return")`
**Purpose**: Calculate summary statistics for all variables

**Parameters**:
- `data`: Input data.frame
- `target_col`: Name of target variable

**Returns**: 
- data.frame with columns: variable, mean, median, sd, min, max

**Behavior**:
- Uses `summary()` and custom calculations
- Processes features and target separately
- Formats output as readable table

#### `compute_correlation_matrix(data)`
**Purpose**: Calculate pairwise correlations between all variables

**Parameters**:
- `data`: Input data.frame

**Returns**: 
- Correlation matrix (matrix object)

**Behavior**:
- Uses `cor()` function with method="pearson"
- Handles all numeric columns
- Returns symmetric matrix

#### `extract_target_correlations(correlation_matrix, target_col = "future_return")`
**Purpose**: Extract correlations between features and target

**Parameters**:
- `correlation_matrix`: Correlation matrix from `compute_correlation_matrix()`
- `target_col`: Name of target variable

**Returns**: 
- Named numeric vector of feature-target correlations sorted by absolute value

**Behavior**:
- Extracts target column/row from matrix
- Sorts by absolute correlation strength
- Excludes target's self-correlation

#### `aggregate_feature_importance(lasso_coefficients, rf_importance)`
**Purpose**: Combine feature importance from both models

**Parameters**:
- `lasso_coefficients`: Named numeric vector of LASSO coefficients
- `rf_importance`: Named numeric vector of Random Forest importance scores

**Returns**: 
- data.frame with columns: feature, lasso_importance, rf_importance, combined_score
- Sorted by combined_score in descending order

**Behavior**:
- Normalizes both importance measures to [0, 1] scale
- Uses absolute values for LASSO coefficients
- Computes combined score as average of normalized values
- Returns top 5 features

### 3. Model Trainer Module (`model_trainer.R`)

#### `train_lasso_model(train_data, target_col = "future_return", nfolds = 5, seed = 42)`
**Purpose**: Train LASSO regression with cross-validated regularization parameter

**Parameters**:
- `train_data`: Training set data.frame
- `target_col`: Name of target variable
- `nfolds`: Number of cross-validation folds (default 5)
- `seed`: Random seed for reproducibility

**Returns**: 
- List containing:
  - `model`: Fitted glmnet model object
  - `lambda_optimal`: Selected lambda value
  - `coefficients`: Named vector of non-zero coefficients
  - `selected_features`: Character vector of feature names with non-zero coefficients

**Behavior**:
- Prepares design matrix using `model.matrix()`
- Uses `glmnet::cv.glmnet()` with alpha=1 (LASSO)
- Selects lambda.min (minimum cross-validation error)
- Extracts coefficients using `coef()`
- Identifies features with non-zero coefficients

#### `train_random_forest_model(train_data, target_col = "future_return", seed = 42)`
**Purpose**: Train Random Forest with hyperparameter tuning

**Parameters**:
- `train_data`: Training set data.frame
- `target_col`: Name of target variable
- `seed`: Random seed for reproducibility

**Returns**: 
- List containing:
  - `model`: Fitted ranger or randomForest model object
  - `best_params`: List of optimal hyperparameters (ntree, max_depth)
  - `feature_importance`: Named vector of importance scores sorted descending

**Behavior**:
- Uses `caret::train()` or manual grid search for hyperparameter tuning
- Tunes: number of trees (ntree: 100, 300, 500) and max depth (maxnodes or max.depth)
- Uses out-of-bag error or cross-validation for selection
- Extracts feature importance using `importance()` or `$variable.importance`
- Sorts features by importance

### 4. Model Evaluator Module (`model_evaluator.R`)

#### `predict_model(model, test_data, model_type = c("lasso", "rf"))`
**Purpose**: Generate predictions from trained model

**Parameters**:
- `model`: Trained model object
- `test_data`: Test set data.frame
- `model_type`: Type of model ("lasso" or "rf")

**Returns**: 
- Numeric vector of predictions

**Behavior**:
- For LASSO: uses `predict.glmnet()` with s=lambda_optimal
- For Random Forest: uses `predict.ranger()` or `predict.randomForest()`
- Returns predictions as numeric vector

#### `calculate_metrics(actual, predicted)`
**Purpose**: Calculate MSE, MAE, and R² score

**Parameters**:
- `actual`: Numeric vector of actual values
- `predicted`: Numeric vector of predicted values

**Returns**: 
- List containing:
  - `mse`: Mean Squared Error
  - `mae`: Mean Absolute Error
  - `r_squared`: R² Score

**Behavior**:
- MSE: `mean((actual - predicted)^2)`
- MAE: `mean(abs(actual - predicted))`
- R²: `1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)`

#### `evaluate_model(model, test_data, target_col = "future_return", model_type)`
**Purpose**: Complete evaluation pipeline for a single model

**Parameters**:
- `model`: Trained model object
- `test_data`: Test set data.frame
- `target_col`: Name of target variable
- `model_type`: Type of model ("lasso" or "rf")

**Returns**: 
- List containing:
  - `predictions`: Numeric vector of predictions
  - `metrics`: List with mse, mae, r_squared

**Behavior**:
- Generates predictions using `predict_model()`
- Calculates metrics using `calculate_metrics()`
- Returns comprehensive evaluation results

#### `compare_models(lasso_results, rf_results)`
**Purpose**: Compare performance of both models and identify best

**Parameters**:
- `lasso_results`: Evaluation results from LASSO model
- `rf_results`: Evaluation results from Random Forest model

**Returns**: 
- List containing:
  - `comparison_table`: data.frame with metrics for both models
  - `best_by_r2`: Model name with highest R²
  - `best_by_mse`: Model name with lowest MSE
  - `best_by_mae`: Model name with lowest MAE
  - `overall_best`: Model name with best overall performance

**Behavior**:
- Creates comparison table with all metrics
- Ranks models by each metric
- Determines overall best (prioritizes R² as primary metric)
- Formats output for readable display

## Data Models

### Input Data Structure

**File**: `financial_dataset.csv`

**Schema**:
```
Column Name         | Type    | Description
--------------------|---------|------------------------------------------
revenue_growth      | numeric | Year-over-year revenue growth percentage
profit_margin       | numeric | Net profit margin percentage
debt_to_equity      | numeric | Debt-to-equity ratio
pe_ratio            | numeric | Price-to-earnings ratio
volatility          | numeric | Stock price volatility measure
market_cap          | numeric | Market capitalization (in millions)
interest_rate       | numeric | Current interest rate percentage
inflation_rate      | numeric | Current inflation rate percentage
sector_score        | numeric | Sector performance score
previous_return     | numeric | Previous year's stock return percentage
future_return       | numeric | Target: Next year's stock return percentage
```

**Constraints**:
- All columns must be numeric
- No categorical variables (or pre-encoded)
- Missing values handled by removal
- 11 total columns (10 features + 1 target)

### Internal Data Structures

#### Preprocessed Data
```r
# After preprocessing
list(
  train = data.frame(
    # 10 normalized feature columns
    # 1 unnormalized target column
    # ~80% of original rows
  ),
  test = data.frame(
    # Same structure as train
    # ~20% of original rows
  ),
  normalization_params = list(
    means = named_vector,      # Feature means from training set
    sds = named_vector         # Feature standard deviations from training set
  )
)
```

#### LASSO Model Output
```r
list(
  model = cv.glmnet_object,
  lambda_optimal = numeric(1),
  coefficients = named_numeric_vector,  # Non-zero coefficients only
  selected_features = character_vector  # Names of selected features
)
```

#### Random Forest Model Output
```r
list(
  model = ranger_or_randomForest_object,
  best_params = list(
    ntree = integer(1),
    max_depth = integer(1)
  ),
  feature_importance = named_numeric_vector  # Sorted descending
)
```

#### Evaluation Results
```r
list(
  predictions = numeric_vector,
  metrics = list(
    mse = numeric(1),
    mae = numeric(1),
    r_squared = numeric(1)
  )
)
```

#### Model Comparison Output
```r
list(
  comparison_table = data.frame(
    Model = c("LASSO", "Random Forest"),
    MSE = numeric(2),
    MAE = numeric(2),
    R_Squared = numeric(2)
  ),
  best_by_r2 = character(1),
  best_by_mse = character(1),
  best_by_mae = character(1),
  overall_best = character(1)
)
```

### File Organization

```
project_root/
├── main.R                      # Main execution script
├── data_preprocessor.R         # Data preprocessing functions
├── feature_analyzer.R          # Feature analysis functions
├── model_trainer.R             # Model training functions
├── model_evaluator.R           # Model evaluation functions
├── utils.R                     # Utility functions (logging, formatting)
├── financial_dataset.csv       # Input data
└── output/                     # Generated outputs
    ├── descriptive_stats.txt
    ├── correlation_matrix.txt
    ├── lasso_results.txt
    ├── rf_results.txt
    ├── model_comparison.txt
    └── feature_importance.txt
```


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Column Validation Completeness

For any dataset loaded by the system, if required columns are missing, the validation SHALL detect all missing columns and include them in the error message.

**Validates: Requirements 1.3, 1.4**

### Property 2: Missing Value Removal Completeness

For any dataset with missing values, after preprocessing, the resulting dataset SHALL contain zero rows with any missing values, and the count of removed rows SHALL equal the number of originally incomplete rows.

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 3: Feature Normalization Mathematical Correctness

For any dataset after normalization, all feature columns (excluding the target variable) SHALL have a mean approximately equal to 0 (within numerical tolerance) and standard deviation approximately equal to 1 (within numerical tolerance).

**Validates: Requirements 3.1**

### Property 4: Normalization Parameter Consistency

For any train/test split, the test set normalization SHALL use the mean and standard deviation calculated from the training set only, not from the test set itself.

**Validates: Requirements 3.2**

### Property 5: Target Variable Preservation

For any dataset before and after normalization, the target variable values SHALL remain identical (no transformation applied).

**Validates: Requirements 3.3**

### Property 6: Descriptive Statistics Completeness

For any dataset, the descriptive statistics output SHALL include mean, median, standard deviation, minimum, and maximum for all features and the target variable.

**Validates: Requirements 4.1, 4.2, 4.3**

### Property 7: Correlation Matrix Completeness

For any dataset, the correlation matrix SHALL contain correlation coefficients for all pairs of variables (features and target), resulting in an (n+1) × (n+1) symmetric matrix where n is the number of features.

**Validates: Requirements 5.1, 5.2, 5.3**

### Property 8: Train/Test Split Proportion

For any dataset split with an 80/20 ratio, the training set SHALL contain approximately 80% of the rows (within ±1 row for rounding) and the test set SHALL contain the remaining rows.

**Validates: Requirements 6.1**

### Property 9: Split Reproducibility

For any dataset, splitting with the same random seed twice SHALL produce identical train/test splits, while splitting with different seeds SHALL produce different splits.

**Validates: Requirements 6.2**

### Property 10: Split Column Preservation

For any dataset split, both the training set and test set SHALL contain all original feature columns and the target variable column.

**Validates: Requirements 6.3**

### Property 11: LASSO Training Completion

For any valid training dataset, LASSO training with cross-validation SHALL complete successfully and return an optimal lambda value and a set of coefficients.

**Validates: Requirements 7.1**

### Property 12: LASSO Feature Selection Output

For any trained LASSO model, the output SHALL include both the list of selected features (those with non-zero coefficients) and their corresponding coefficient values.

**Validates: Requirements 7.3, 7.4**

### Property 13: Random Forest Training Completion

For any valid training dataset, Random Forest training with hyperparameter tuning SHALL complete successfully and return optimal hyperparameters and a trained model.

**Validates: Requirements 8.1**

### Property 14: Random Forest Feature Importance Output

For any trained Random Forest model, the output SHALL include importance scores for all features, sorted in descending order of importance.

**Validates: Requirements 8.3, 8.4**

### Property 15: MSE Calculation

For any trained model evaluated on a test set, the evaluation SHALL calculate and return the Mean Squared Error (MSE).

**Validates: Requirements 9.1**

### Property 16: MAE Calculation

For any trained model evaluated on a test set, the evaluation SHALL calculate and return the Mean Absolute Error (MAE).

**Validates: Requirements 9.2**

### Property 17: R² Calculation

For any trained model evaluated on a test set, the evaluation SHALL calculate and return the R² Score.

**Validates: Requirements 9.3**

### Property 18: Comparison Table Completeness

For any two evaluated models, the comparison output SHALL include a table containing MSE, MAE, and R² values for both models.

**Validates: Requirements 9.4**

### Property 19: R² Ranking Correctness

For any two model evaluation results, the model with the higher R² score SHALL be ranked first when sorting by R² in descending order.

**Validates: Requirements 10.1**

### Property 20: MSE Best Model Identification

For any two model evaluation results, the system SHALL correctly identify the model with the lower MSE value as best by MSE.

**Validates: Requirements 10.2**

### Property 21: MAE Best Model Identification

For any two model evaluation results, the system SHALL correctly identify the model with the lower MAE value as best by MAE.

**Validates: Requirements 10.3**

### Property 22: Overall Best Model Designation

For any two model evaluation results, the system SHALL designate an overall best model and include this in the output summary.

**Validates: Requirements 10.4**

### Property 23: LASSO Zero Coefficient Identification

For any trained LASSO model, the feature analyzer SHALL correctly identify all features with zero coefficients as eliminated features.

**Validates: Requirements 11.1, 11.2**

### Property 24: Feature Selection Count Accuracy

For any trained LASSO model, the output SHALL include an accurate count of selected features and total features, where selected + eliminated = total.

**Validates: Requirements 11.3**

### Property 25: Feature Importance Aggregation Completeness

For any pair of trained models (LASSO and Random Forest), the aggregated feature importance SHALL include contributions from both the Random Forest importance scores and the absolute LASSO coefficient values for selected features.

**Validates: Requirements 12.1, 12.2**

### Property 26: Top 5 Features Output

For any aggregated feature importance ranking, the output SHALL contain exactly the top 5 features sorted by their combined importance scores in descending order.

**Validates: Requirements 12.3**

## Error Handling

### Error Categories

1. **File System Errors**
   - Missing dataset file
   - Insufficient read permissions
   - Corrupted CSV format

2. **Data Validation Errors**
   - Missing required columns
   - Non-numeric data in numeric columns
   - Empty dataset after loading

3. **Preprocessing Errors**
   - All rows removed due to missing values (empty dataset)
   - Normalization failure (zero variance features)
   - Invalid train/test split ratio

4. **Model Training Errors**
   - LASSO cross-validation failure
   - Random Forest hyperparameter tuning failure
   - Insufficient training data

5. **Evaluation Errors**
   - Prediction generation failure
   - Metric calculation errors (e.g., division by zero in R²)

### Error Handling Strategy

#### Fail-Fast Approach
The system uses a fail-fast approach where errors are detected early and execution stops with informative error messages. This prevents cascading failures and makes debugging easier.

#### Error Detection and Reporting

**File Loading** (`load_dataset`):
```r
tryCatch({
  data <- readr::read_csv(file_path)
}, error = function(e) {
  stop(sprintf("Failed to load dataset from '%s': %s", file_path, e$message))
})
```

**Column Validation**:
```r
required_cols <- c("revenue_growth", "profit_margin", "debt_to_equity", 
                   "pe_ratio", "volatility", "market_cap", "interest_rate",
                   "inflation_rate", "sector_score", "previous_return", 
                   "future_return")
missing_cols <- setdiff(required_cols, colnames(data))
if (length(missing_cols) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse=", ")))
}
```

**Empty Dataset Check**:
```r
if (nrow(cleaned_data) == 0) {
  stop("All rows removed due to missing values. Dataset is empty.")
}
```

**Normalization Validation**:
```r
zero_var_features <- names(which(apply(train_data[, features], 2, sd) == 0))
if (length(zero_var_features) > 0) {
  warning(sprintf("Features with zero variance (will not be normalized): %s", 
                  paste(zero_var_features, collapse=", ")))
}
```

**Model Training Validation**:
```r
if (is.null(lasso_model$lambda.min)) {
  stop("LASSO cross-validation failed to select optimal lambda")
}
```

#### Logging Strategy

The system implements informative logging at key stages:

1. **Data Loading**: Log number of rows and columns loaded
2. **Missing Value Handling**: Log count of rows removed
3. **Train/Test Split**: Log sizes of resulting sets
4. **Normalization**: Log normalization parameters
5. **Model Training**: Log training progress and selected hyperparameters
6. **Evaluation**: Log all calculated metrics

**Logging Implementation**:
```r
# Utility function in utils.R
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", timestamp, level, message))
}
```

#### Graceful Degradation

For non-critical failures, the system continues with warnings:

- **Zero variance features**: Warn but continue (exclude from normalization)
- **Perfect correlations**: Warn but continue (may affect model training)
- **Hyperparameter tuning suboptimal**: Warn but use best available parameters

## Testing Strategy

### Dual Testing Approach

The testing strategy employs both unit tests and property-based tests to ensure comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property-based tests**: Verify universal properties across randomly generated inputs

This dual approach is complementary and necessary: unit tests catch concrete bugs and validate specific scenarios, while property-based tests verify general correctness across a wide input space.

### Property-Based Testing Framework

**Library**: `hedgehog` (R port of Haskell's Hedgehog library) or `quickcheck` for R

**Configuration**:
- Minimum 100 iterations per property test (due to randomization)
- Each property test references its design document property
- Tag format: `# Feature: stock-return-prediction, Property {number}: {property_text}`

**Example Property Test Structure**:
```r
library(hedgehog)

test_that("Property 3: Feature Normalization Mathematical Correctness", {
  # Feature: stock-return-prediction, Property 3: Feature normalization mathematical correctness
  
  forall(gen_dataset(nrows = 50:200, nfeatures = 10), function(data) {
    # Normalize the dataset
    normalized <- normalize_features(data, data, target_col = "future_return")
    
    # Check all features have mean ≈ 0 and sd ≈ 1
    feature_cols <- setdiff(colnames(data), "future_return")
    means <- apply(normalized$train_normalized[, feature_cols], 2, mean)
    sds <- apply(normalized$train_normalized[, feature_cols], 2, sd)
    
    all(abs(means) < 1e-10) && all(abs(sds - 1) < 1e-10)
  })
})
```

### Unit Testing Framework

**Library**: `testthat` (standard R testing framework)

**Test Organization**:
```
tests/
├── testthat/
│   ├── test_data_preprocessor.R
│   ├── test_feature_analyzer.R
│   ├── test_model_trainer.R
│   ├── test_model_evaluator.R
│   └── test_integration.R
└── testthat.R
```

### Test Coverage by Component

#### Data Preprocessor Tests

**Unit Tests**:
- Load valid dataset successfully (example)
- Error on missing file (example)
- Error on missing columns with correct message (example)
- Handle empty dataset after missing value removal (edge case)
- Normalize dataset with zero-variance features (edge case)

**Property Tests**:
- Property 1: Column validation completeness
- Property 2: Missing value removal completeness
- Property 3: Feature normalization mathematical correctness
- Property 4: Normalization parameter consistency
- Property 5: Target variable preservation
- Property 8: Train/test split proportion
- Property 9: Split reproducibility
- Property 10: Split column preservation

#### Feature Analyzer Tests

**Unit Tests**:
- Calculate statistics for small dataset (example)
- Handle single-row dataset (edge case)
- Compute correlation for perfectly correlated features (edge case)

**Property Tests**:
- Property 6: Descriptive statistics completeness
- Property 7: Correlation matrix completeness
- Property 23: LASSO zero coefficient identification
- Property 24: Feature selection count accuracy
- Property 25: Feature importance aggregation completeness
- Property 26: Top 5 features output

#### Model Trainer Tests

**Unit Tests**:
- Train LASSO with 5-fold CV (example - validates Requirement 7.2)
- Train Random Forest with ntree and max_depth tuning (example - validates Requirement 8.2)
- Handle training set with fewer samples than features (edge case)

**Property Tests**:
- Property 11: LASSO training completion
- Property 12: LASSO feature selection output
- Property 13: Random Forest training completion
- Property 14: Random Forest feature importance output

#### Model Evaluator Tests

**Unit Tests**:
- Evaluate model with perfect predictions (edge case)
- Evaluate model with constant predictions (edge case)
- Compare models with identical performance (edge case)

**Property Tests**:
- Property 15: MSE calculation
- Property 16: MAE calculation
- Property 17: R² calculation
- Property 18: Comparison table completeness
- Property 19: R² ranking correctness
- Property 20: MSE best model identification
- Property 21: MAE best model identification
- Property 22: Overall best model designation

#### Integration Tests

**Unit Tests**:
- End-to-end pipeline with sample dataset (example)
- Pipeline with dataset requiring significant preprocessing (example)
- Pipeline with highly correlated features (edge case)

### Test Data Generators for Property-Based Testing

**Random Dataset Generator**:
```r
gen_dataset <- function(nrows, nfeatures, missing_prob = 0) {
  gen.and_then(
    gen.element(nrows),
    function(n) {
      gen.and_then(
        gen.element(nfeatures),
        function(p) {
          # Generate random numeric matrix
          gen.map(
            gen.list(gen.element(n * (p + 1)), gen.double()),
            function(values) {
              mat <- matrix(values, nrow = n, ncol = p + 1)
              df <- as.data.frame(mat)
              colnames(df) <- c(paste0("feature_", 1:p), "future_return")
              
              # Introduce missing values if requested
              if (missing_prob > 0) {
                mask <- matrix(runif(n * (p + 1)) < missing_prob, nrow = n)
                df[mask] <- NA
              }
              
              df
            }
          )
        }
      )
    }
  )
}
```

**Random Model Results Generator**:
```r
gen_model_results <- function() {
  gen.map(
    gen.list(3, gen.double(from = 0, to = 100)),
    function(metrics) {
      list(
        metrics = list(
          mse = metrics[[1]],
          mae = metrics[[2]],
          r_squared = min(metrics[[3]] / 100, 1)  # R² bounded by 1
        )
      )
    }
  )
}
```

### Testing Best Practices

1. **Isolation**: Each test should be independent and not rely on external state
2. **Reproducibility**: Use fixed random seeds for tests that involve randomness
3. **Clear Assertions**: Each test should have clear, specific assertions
4. **Fast Execution**: Unit tests should run quickly; property tests may take longer
5. **Comprehensive Coverage**: Aim for >90% code coverage with combination of unit and property tests
6. **Documentation**: Each test should clearly indicate what requirement/property it validates

### Continuous Testing

**Pre-commit Checks**:
- Run all unit tests (fast feedback)
- Run linting and style checks

**CI/CD Pipeline**:
- Run all unit tests
- Run all property-based tests (100 iterations each)
- Generate coverage report
- Fail build if coverage drops below threshold

### Manual Testing Checklist

Before release, manually verify:
1. System runs end-to-end with provided financial_dataset.csv
2. Output files are generated in correct format
3. Error messages are clear and actionable
4. Performance is acceptable for typical dataset sizes (1000-10000 rows)
5. Results are reproducible across multiple runs with same seed

