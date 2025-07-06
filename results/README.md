# Results

Model outputs and performance visualizations.

## Files

- **`model_performance_comparison.csv`** - Performance metrics for all 6 models
- **`precision_recall_curves.png`** - Visual comparison of model performance
- **`feature_importance.png`** - Top predictors of course completion
- **`threshold_analysis.png`** - F1-score optimization results

## Key Findings

- **Best Model**: Random Forest (F1-score: 0.737)
- **Top Predictor**: Number of active days in course
- **Insight**: Engagement behavior beats demographics for predicting success

## Model Performance Summary

| Model | F1-Score | PR-AUC | Key Strength |
|-------|----------|--------|--------------|
| Random Forest | 0.737 | 0.780 | Overall best performance |
| XGBoost | 0.700 | 0.761 | Close second, good interpretability |
| Lasso | 0.667 | 0.722 | Simple and interpretable |
