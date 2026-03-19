# Package Installation and Verification Script
# This script installs and loads all required R packages for the Stock Return Prediction System

# List of required packages
required_packages <- c(
  "glmnet",      # LASSO regression
  "ranger",      # Random Forest (alternative: randomForest)
  "caret",       # Unified ML interface
  "dplyr",       # Data manipulation
  "readr",       # CSV reading
  "testthat",    # Unit testing
  "hedgehog"     # Property-based testing
)

# Function to install missing packages
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat(sprintf("Installing package: %s\n", pkg))
      install.packages(pkg, repos = "https://cloud.r-project.org/")
    } else {
      cat(sprintf("Package already installed: %s\n", pkg))
    }
  }
}

# Install missing packages
cat("Checking and installing required packages...\n")
install_if_missing(required_packages)

# Load all packages and verify
cat("\nLoading and verifying packages...\n")
success <- TRUE
for (pkg in required_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("✓ %s loaded successfully\n", pkg))
  } else {
    cat(sprintf("✗ Failed to load %s\n", pkg))
    success <- FALSE
  }
}

if (success) {
  cat("\n✓ All required packages are installed and loaded successfully!\n")
} else {
  cat("\n✗ Some packages failed to load. Please check the errors above.\n")
}
