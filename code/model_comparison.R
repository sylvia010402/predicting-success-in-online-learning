# ===============================================================================
# MOOC Certification Prediction: Complete Model Comparison
# Comparing 6 ML algorithms for predicting online course completion
# ===============================================================================

# Load required libraries
library(tidyverse)
library(caret)
library(pROC)
library(PRROC)
library(doParallel)
library(kernlab)
library(xgboost)

# ===============================================================================
# 1. DATA LOADING AND PREPROCESSING
# ===============================================================================

# Load cleaned data (assumes data_cleaning.R has been run)
cat("Loading cleaned MOOC data...\n")
MOOC_cleaned <- read_csv("data/MOOC_cleaned.csv")

# Feature engineering
MOOC_cleaned <- MOOC_cleaned %>%
  mutate(semester = str_extract(course_id, "\\d{4}.*$")) %>%
  mutate(across(where(is.character), as.factor)) %>%
  select(-c("userid_DI", "start_time_DI", "last_event_DI", "grade_log"))

# Recode course names for clarity
MOOC_cleaned <- MOOC_cleaned %>% 
  mutate(course_id = recode(course_id, 
                            "HarvardX/CB22x/2013_Spring" = "CB22x", 
                            "HarvardX/CS50x/2012" = "CS50x",
                            "HarvardX/ER22x/2013_Spring" = "ER22x",
                            "HarvardX/PH207x/2012_Fall" = "Ph207x",
                            "HarvardX/PH278x/2013_Spring" = "PH278x"))

# Prepare target variable
MOOC_cleaned$viewed <- as.factor(MOOC_cleaned$viewed)
MOOC_cleaned$explored <- as.factor(MOOC_cleaned$explored)
MOOC_cleaned$certified <- factor(MOOC_cleaned$certified, 
                                 levels = c(0, 1), 
                                 labels = c("No", "Yes"))

cat("Data preprocessing complete.\n")
cat("Dataset dimensions:", dim(MOOC_cleaned), "\n")
cat("Certification rate:", round(mean(MOOC_cleaned$certified == "Yes") * 100, 2), "%\n")

# ===============================================================================
# 2. TRAIN/TEST SPLIT
# ===============================================================================

set.seed(420)
train_index <- createDataPartition(MOOC_cleaned$certified, p = 0.8, list = FALSE)

# Full datasets
train_full <- MOOC_cleaned[train_index, ]
test_full <- MOOC_cleaned[-train_index, ]

# Create subset for computationally intensive models
set.seed(420)
n_subset <- 20000
train_subset <- train_full %>% slice_sample(n = min(n_subset, nrow(train_full)))

cat("Training set (full):", nrow(train_full), "observations\n")
cat("Training set (subset):", nrow(train_subset), "observations\n")
cat("Test set:", nrow(test_full), "observations\n")

# ===============================================================================
# 3. CROSS-VALIDATION SETUP
# ===============================================================================

# Standard control for most models
ctrl_standard <- trainControl(
  method = "cv",
  number = 5,
  summaryFunction = twoClassSummary,
  classProbs = TRUE,
  savePredictions = "final"
)

# Control for models needing parallel processing
ctrl_parallel <- trainControl(
  method = "cv",
  number = 5,
  summaryFunction = twoClassSummary,
  classProbs = TRUE,
  savePredictions = "final",
  allowParallel = TRUE
)

# ===============================================================================
# 4. MODEL TRAINING FUNCTIONS
# ===============================================================================

train_random_forest <- function(train_data, ctrl) {
  cat("Training Random Forest...\n")
  set.seed(420)
  rf_model <- train(
    certified ~ .,
    data = train_data,
    method = "rf",
    metric = "ROC",
    trControl = ctrl,
    tuneLength = 5,
    ntree = 100
  )
  return(rf_model)
}

train_lasso <- function(train_data, ctrl) {
  cat("Training Lasso Regression...\n")
  set.seed(420)
  lasso_model <- train(
    certified ~ .,
    data = train_data,
    method = "glmnet",
    metric = "ROC",
    trControl = ctrl,
    preProcess = c("center", "scale"),
    tuneGrid = data.frame(alpha = 1, lambda = seq(0.001, 0.1, length = 20))
  )
  return(lasso_model)
}

train_ridge <- function(train_data, ctrl) {
  cat("Training Ridge Regression...\n")
  set.seed(420)
  ridge_model <- train(
    certified ~ .,
    data = train_data,
    method = "glmnet",
    metric = "ROC",
    trControl = ctrl,
    preProcess = c("center", "scale"),
    tuneGrid = data.frame(alpha = 0, lambda = seq(0.001, 0.1, length = 20))
  )
  return(ridge_model)
}

train_knn <- function(train_data, ctrl) {
  cat("Training K-Nearest Neighbors...\n")
  
  # Convert to numeric for KNN
  dummy_obj <- dummyVars(certified ~ ., data = train_data, fullRank = FALSE)
  train_numeric <- as.data.frame(predict(dummy_obj, newdata = train_data))
  train_numeric$certified <- train_data$certified
  
  set.seed(420)
  knn_model <- train(
    certified ~ .,
    data = train_numeric,
    method = "knn",
    metric = "ROC",
    trControl = ctrl,
    preProcess = c("center", "scale"),
    tuneLength = 5
  )
  
  # Store dummy object for later predictions
  knn_model$dummy_obj <- dummy_obj
  return(knn_model)
}

train_svm <- function(train_data, ctrl) {
  cat("Training Support Vector Machine...\n")
  set.seed(420)
  svm_model <- train(
    certified ~ .,
    data = train_data,
    method = "svmRadial",
    metric = "ROC",
    trControl = ctrl,
    preProcess = c("center", "scale"),
    tuneGrid = expand.grid(C = c(0.1, 1, 10), sigma = c(0.01, 0.1, 1))
  )
  return(svm_model)
}

train_xgboost <- function(train_data, ctrl) {
  cat("Training XGBoost...\n")
  set.seed(420)
  xgb_model <- train(
    certified ~ .,
    data = train_data,
    method = "xgbTree",
    metric = "ROC",
    trControl = ctrl,
    tuneLength = 3,  # Reduced for efficiency
    verbose = FALSE
  )
  return(xgb_model)
}

# ===============================================================================
# 5. PARALLEL PROCESSING SETUP
# ===============================================================================

setup_parallel <- function() {
  num_cores <- detectCores() - 1
  if (num_cores < 1) num_cores <- 1
  cl <- makePSOCKcluster(num_cores)
  registerDoParallel(cl)
  cat("Parallel processing setup with", num_cores, "cores\n")
  return(cl)
}

stop_parallel <- function(cl) {
  stopCluster(cl)
  registerDoSEQ()
  cat("Parallel processing stopped\n")
}

# ===============================================================================
# 6. TRAIN ALL MODELS
# ===============================================================================

cat("\n=== TRAINING ALL MODELS ===\n")

# Train models that can handle full dataset
models <- list()

models$rf <- train_random_forest(train_full, ctrl_standard)
models$lasso <- train_lasso(train_subset, ctrl_standard)  # Use subset for consistency
models$ridge <- train_ridge(train_subset, ctrl_standard)  # Use subset for consistency

# Setup parallel processing for intensive models
cl <- setup_parallel()

models$knn <- train_knn(train_subset, ctrl_parallel)
models$svm <- train_svm(train_subset, ctrl_parallel)
models$xgboost <- train_xgboost(train_subset, ctrl_parallel)

stop_parallel(cl)

cat("\nAll models trained successfully!\n")

# ===============================================================================
# 7. MODEL EVALUATION FUNCTIONS
# ===============================================================================

make_predictions <- function(model, test_data, model_name) {
  if (model_name == "knn") {
    # Special handling for KNN (needs numeric data)
    test_numeric <- as.data.frame(predict(model$dummy_obj, newdata = test_data))
    test_numeric$certified <- test_data$certified
    preds <- predict(model, newdata = test_numeric)
    probs <- predict(model, newdata = test_numeric, type = "prob")
  } else {
    preds <- predict(model, newdata = test_data)
    probs <- predict(model, newdata = test_data, type = "prob")
  }
  
  return(list(predictions = preds, probabilities = probs))
}

evaluate_model <- function(model, test_data, model_name) {
  # Get predictions
  results <- make_predictions(model, test_data, model_name)
  preds <- results$predictions
  probs <- results$probabilities
  
  # Confusion matrix
  cm <- confusionMatrix(preds, test_data$certified, positive = "Yes")
  
  # ROC analysis
  roc_obj <- roc(test_data$certified, probs[, "Yes"])
  roc_auc <- auc(roc_obj)
  
  # Precision-Recall analysis
  labels <- ifelse(test_data$certified == "Yes", 1, 0)
  pr_obj <- pr.curve(scores.class0 = probs[, "Yes"], weights.class0 = labels)
  pr_auc <- pr_obj$auc.integral
  
  # Extract key metrics
  metrics <- data.frame(
    Model = model_name,
    Sensitivity = cm$byClass["Sensitivity"],
    Specificity = cm$byClass["Specificity"],
    Precision = cm$byClass["Precision"],
    F1_Score = cm$byClass["F1"],
    ROC_AUC = as.numeric(roc_auc),
    PR_AUC = pr_auc,
    stringsAsFactors = FALSE
  )
  
  return(list(
    metrics = metrics,
    roc = roc_obj,
    pr = pr_obj,
    probabilities = probs[, "Yes"]
  ))
}

# ===============================================================================
# 8. EVALUATE ALL MODELS
# ===============================================================================

cat("\n=== EVALUATING ALL MODELS ===\n")

model_names <- c("Random Forest", "Lasso", "Ridge", "KNN", "SVM", "XGBoost")
names(model_names) <- c("rf", "lasso", "ridge", "knn", "svm", "xgboost")

evaluations <- list()
all_metrics <- data.frame()

for (i in seq_along(models)) {
  model_key <- names(models)[i]
  model_name <- model_names[model_key]
  
  cat("Evaluating", model_name, "...\n")
  
  eval_result <- evaluate_model(models[[model_key]], test_full, model_name)
  evaluations[[model_key]] <- eval_result
  all_metrics <- rbind(all_metrics, eval_result$metrics)
}

# ===============================================================================
# 9. RESULTS VISUALIZATION
# ===============================================================================

# Display performance table
cat("\n=== MODEL PERFORMANCE COMPARISON ===\n")
print(round(all_metrics[, -1], 3))  # Exclude model name column for cleaner display

# Create Precision-Recall comparison plot
create_pr_comparison <- function(evaluations, model_names) {
  colors <- c("green", "hotpink", "orange", "purple", "blue", "red")
  
  # Start with first model
  first_key <- names(evaluations)[1]
  plot(evaluations[[first_key]]$pr, 
       col = colors[1], 
       main = "Precision-Recall Curves - Model Comparison",
       lwd = 2, 
       auc.main = FALSE)
  
  # Add other models
  for (i in 2:length(evaluations)) {
    model_key <- names(evaluations)[i]
    lines(evaluations[[model_key]]$pr$curve[,1:2], 
          col = colors[i], 
          lwd = 2)
  }
  
  # Add legend
  legend("bottomleft", 
         legend = model_names, 
         col = colors[1:length(model_names)], 
         lwd = 2,
         cex = 0.8)
}

# Create the comparison plot
create_pr_comparison(evaluations, model_names)

# Find best model
best_model_idx <- which.max(all_metrics$F1_Score)
best_model <- all_metrics$Model[best_model_idx]
best_f1 <- round(all_metrics$F1_Score[best_model_idx], 3)

cat("\n=== RESULTS SUMMARY ===\n")
cat("Best performing model:", best_model, "\n")
cat("Best F1-Score:", best_f1, "\n")
cat("Best PR-AUC:", round(all_metrics$PR_AUC[best_model_idx], 3), "\n")

# ===============================================================================
# 10. FEATURE IMPORTANCE (for best model)
# ===============================================================================

if (best_model == "Random Forest") {
  cat("\n=== FEATURE IMPORTANCE ===\n")
  
  rf_imp <- varImp(models$rf, scale = FALSE)$importance %>%
    rownames_to_column("Feature") %>%
    arrange(desc(Overall)) %>%
    slice_head(n = 10)
  
  print(rf_imp)
  
  # Create feature importance plot
  ggplot(rf_imp, aes(x = reorder(Feature, Overall), y = Overall, fill = Overall)) +
    geom_col() +
    coord_flip() +
    scale_fill_distiller(palette = "Greens", direction = 1) +
    labs(title = "Top 10 Most Important Features",
         x = "Feature", y = "Importance Score") +
    theme_minimal() +
    theme(legend.position = "none")
}

# ===============================================================================
# 11. SAVE RESULTS
# ===============================================================================

# Save all models
cat("\n=== SAVING MODELS AND RESULTS ===\n")

for (i in seq_along(models)) {
  model_key <- names(models)[i]
  filename <- paste0("models/", model_key, "_model.rds")
  saveRDS(models[[model_key]], filename)
  cat("Saved:", filename, "\n")
}

# Save performance metrics
write_csv(all_metrics, "results/model_performance_comparison.csv")
cat("Saved: results/model_performance_comparison.csv\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Check the 'models/' and 'results/' directories for saved outputs.\n")