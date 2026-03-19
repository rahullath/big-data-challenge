# Utility Functions for Stock Return Prediction System

#' Log a message with timestamp and level
#'
#' @param message Character string message to log
#' @param level Character string log level (default: "INFO")
#' @return NULL (prints to console)
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", timestamp, level, message))
}
