# Predicting Success in Online Learning: What Makes Students Complete MOOCs?

## The Problem

The Massive Open Online Courses (MOOCs) have gained popularity as flexible, accessible platforms for global learning. Platforms like HarvardX and MITx attract hundreds of thousands of learners annually. However, despite high enrollment rates, certification rates remain strikingly low. As someone who's enrolled in multiple online courses but only mananged to finish a few of them, I was curious: what actually separates the students who earn certificates from those who don't? With MOOC completion rates hovering around 2-3%, understanding these patterns could help millions of learners achieve their educational goals.

## What I Found

After analyzing over 260,000 student records from Harvard and MIT's first year of online courses, the answer was surprisingly clear: **it's not about who you are, it's about what you do.**

### Key Insights

**Engagement beats demographics every time**
- Number of active days in the course was the strongest predictor
- How many chapters students accessed came in second
- Gender, education level, and age? Barely mattered

**The "exploration effect"**
- Students who moved beyond just watching videos to actively exploring course materials were dramatically more likely to succeed
- This suggests that passive consumption isn't enough - learners need to engage with the content

**Early patterns predict final outcomes**
- We could identify likely completers within the first few weeks based on their activity patterns
- This opens opportunities for early intervention to support struggling students

## The Data Story

I worked with Harvard and MIT's inaugural online course data from 2012-2013, covering 5 courses across computer science, humanities, and public health. The dataset was messy and skewed (typical of real-world educational data), requiring significant cleaning and feature engineering to extract meaningful patterns.

The biggest challenge? Extreme class imbalance - only 2.5% of students actually earned certificates. This meant traditional accuracy metrics were misleading, pushing me to focus on precision-recall analysis instead.

## Technical Approach

I tested six different machine learning models to see which could best identify potential completers:
- Random Forest (winner)
- XGBoost (close second) 
- Ridge/Lasso Regression
- Support Vector Machine
- K-Nearest Neighbors

Random Forest emerged as the clear winner with an F1-score of 0.737, successfully identifying about 79% of students who would earn certificates while keeping false alarms manageable:

![alt text](prc_combined.png)


## Real-World Impact

These findings have practical implications for online education:

**For course designers**: Focus on creating engaging, interactive content rather than just video lectures

**For student support**: Monitor early engagement patterns to identify at-risk learners before they drop out

**For platforms**: Build features that encourage active exploration of course materials, not just passive viewing

## What's Next

This analysis raises fascinating questions: What specific types of engagement matter most? How do these patterns differ across subjects? Could we design interventions that actually improve completion rates?

I'd love to explore how these insights could be applied to more recent online learning platforms, especially in the post-pandemic world where online education and courses has gained substantial popularity.

---

## Repository Structure
```
├── README.md                 # You're here!
├── notebooks/
│   ├── data_cleaning.R       # Data preprocessing and feature engineering  
│   ├── model_training.R      # Random Forest and model comparison
│   └── analysis_results.R    # Precision-recall analysis and insights
├── docs/
│   ├── final_report.pdf      # Complete academic analysis
│   └── methodology.md        # Technical details
└── results/
    ├── model_comparison.png   # Performance across all 6 models
    └── feature_importance.png # What drives course completion
```

## Getting Started

The analysis is written in R using standard data science packages (tidyverse, caret, pROC). Run the scripts in order: data cleaning → model training → results analysis.

**Note**: Original Harvard data requires institutional access, but the methodology can be applied to any educational dataset with similar engagement metrics.
