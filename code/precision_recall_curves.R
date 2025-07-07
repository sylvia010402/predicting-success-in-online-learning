library(PRROC)

# 1. Get binary labels
labels <- ifelse(test$certified == "Yes", 1, 0)

# 2. Get scores for each model
probs_rf     <- rf_probs$Yes
probs_lasso  <- lasso_probs$Yes
probs_xgboost    <- xgboost_probs$Yes
probs_ridge <- ridge_probs$Yes
probs_svm    <- svm_probs$Yes
probs_knn   <- knn_probs$Yes

# 3. Compute PR curves
pr_rf     <- pr.curve(scores.class0 = probs_rf, weights.class0 = labels, curve = TRUE)
pr_lasso  <- pr.curve(scores.class0 = probs_lasso, weights.class0 = labels, curve = TRUE)
pr_xgboost    <- pr.curve(scores.class0 = probs_xgboost, weights.class0 = labels, curve = TRUE)
pr_ridge <- pr.curve(scores.class0 = probs_ridge, weights.class0 = labels, curve = TRUE)
pr_svm    <- pr.curve(scores.class0 = probs_svm, weights.class0 = labels, curve = TRUE)
pr_knn   <- pr.curve(scores.class0 = probs_knn, weights.class0 = labels, curve = TRUE)

# 4. Plot all on same graph
plot(pr_rf, col = "green", main = "Precision-Recall Curves", lwd = 2, auc.main = FALSE)
lines(pr_lasso$curve[,1:2], col = "hotpink", lwd = 2)
lines(pr_xgboost$curve[,1:2], col = "red", lwd = 2)
lines(pr_ridge$curve[,1:2], col = "orange", lwd = 2)
lines(pr_svm$curve[,1:2], col = "blue", lwd = 2)
lines(pr_knn$curve[,1:2], col = "purple", lwd = 2)

# 5. Add legend
legend("bottomleft", legend = c("RF", "Lasso", "XGBoost", "Ridge", "SVM", "KNN"),
       col = c("green", "hotpink", "red", "orange", "blue", "purple"), lwd = 2)
