############################################################
# 🎯 CUSTOMER CHURN PREDICTION & BUSINESS DECISION SYSTEM
# Complete End-to-End Pipeline in Single File
# Author: AI Assistant | Date: Mar 1, 2026
############################################################

# ============================================================
# 1️⃣ INSTALL & LOAD REQUIRED LIBRARIES
# ============================================================

cat("\n📦 Installing and loading required packages...\n")

packages <- c("randomForest", "caret", "ggplot2")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

cat("✅ All packages loaded successfully!\n")

# ============================================================
# 2️⃣ LOAD DATASET
# ============================================================

cat("\n📥 Loading Telco Customer Churn dataset...\n")

data <- read.csv("C:/Users/lahar/Desktop/customer churn/Customer-Churn-R/data/Telco-Customer-Churn.csv",
                 stringsAsFactors = TRUE, fill = TRUE)

cat("✅ Dataset loaded!\n")
cat("   Rows:", nrow(data), "\n")
cat("   Columns:", ncol(data), "\n")

# ============================================================
# 3️⃣ CLEAN COLUMN NAMES (Remove Spaces)
# ============================================================

cat("\n🧹 Cleaning column names...\n")

colnames(data) <- make.names(colnames(data))

cat("✅ Column names cleaned (spaces → dots)\n")
cat("   Sample columns:", paste(head(colnames(data), 5), collapse=", "), "\n")

# ============================================================
# 4️⃣ SELECT IMPORTANT FEATURES
# ============================================================

cat("\n🎯 Selecting important features for model...\n")

data2 <- data[, c("Gender",
                  "Senior.Citizen",
                  "Tenure.in.Months",
                  "Contract",
                  "Monthly.Charge",
                  "Total.Charges",
                  "Internet.Service",
                  "Payment.Method",
                  "Churn.Label")]

cat("✅ Features selected: ", ncol(data2), " columns\n")

# Remove missing values
data2 <- na.omit(data2)

cat("✅ Missing values removed\n")
cat("   Remaining rows:", nrow(data2), "\n")

# Convert target to factor
data2$Churn.Label <- factor(data2$Churn.Label)

cat("✅ Target variable converted to factor\n")
cat("   Churn distribution:\n")
print(table(data2$Churn.Label))

# ============================================================
# 5️⃣ TRAIN-TEST SPLIT (70-30)
# ============================================================

cat("\n📊 Splitting data into train-test sets...\n")

set.seed(123)  # For reproducibility

index <- createDataPartition(data2$Churn.Label, p = 0.7, list = FALSE)
train <- data2[index, ]
test  <- data2[-index, ]

cat("✅ Data split completed!\n")
cat("   Training set:", nrow(train), "rows (70%)\n")
cat("   Test set:", nrow(test), "rows (30%)\n")

# ============================================================
# 6️⃣ TRAIN RANDOM FOREST MODEL
# ============================================================

cat("\n🌲 Training Random Forest Model...\n")
cat("   Parameters: ntree=200, importance=TRUE\n")

rf_model <- randomForest(Churn.Label ~ ., 
                         data = train, 
                         ntree = 200,
                         importance = TRUE)

cat("✅ Model trained successfully!\n\n")
print(rf_model)

# ============================================================
# 7️⃣ MAKE PREDICTIONS WITH PROBABILITY
# ============================================================

cat("\n🔮 Making predictions on test set...\n")

# Get class predictions
pred <- predict(rf_model, test)

# Get probability predictions
prob <- predict(rf_model, test, type = "prob")
test$Churn_Probability <- prob[, "Yes"]

cat("✅ Predictions completed!\n")
cat("   Predicted Churn (Yes):", sum(pred == "Yes"), "customers\n")
cat("   Predicted No Churn (No):", sum(pred == "No"), "customers\n")

# ============================================================
# 8️⃣ MODEL EVALUATION
# ============================================================

cat("\n📈 Model Performance Metrics\n")
cat("============================================\n")

cm <- confusionMatrix(pred, test$Churn.Label)
print(cm)

cat("\n📊 KEY METRICS:\n")
cat("   Overall Accuracy:", round(cm$overall['Accuracy'] * 100, 2), "%\n")
cat("   Sensitivity (Recall):", round(cm$byClass['Sensitivity'] * 100, 2), "%\n")
cat("   Specificity:", round(cm$byClass['Specificity'] * 100, 2), "%\n")
cat("   Precision:", round(cm$byClass['Precision'] * 100, 2), "%\n")

# ============================================================
# 9️⃣ FEATURE IMPORTANCE ANALYSIS
# ============================================================

cat("\n⭐ TOP 10 IMPORTANT FEATURES\n")
cat("============================================\n")

importance_values <- importance(rf_model)
importance_df <- data.frame(
  Feature = rownames(importance_values),
  Importance = as.numeric(importance_values[, "MeanDecreaseGini"])
)
importance_df <- importance_df[order(-importance_df$Importance), ]

print(head(importance_df, 10))

# ============================================================
# 🔟 CREATE RISK LEVELS (Business Decision System)
# ============================================================

cat("\n⚠️ Creating Risk Segmentation...\n")

test$Risk_Level <- ifelse(test$Churn_Probability > 0.75, "High Risk",
                    ifelse(test$Churn_Probability > 0.50, "Medium Risk",
                           "Low Risk"))

cat("✅ Risk levels assigned!\n")
cat("   Distribution:\n")
print(table(test$Risk_Level))

# ============================================================
# 1️⃣1️⃣ CREATE BUSINESS ACTION PLAN
# ============================================================

cat("\n💼 Assigning Retention Actions...\n")

test$Retention_Action <- ifelse(test$Risk_Level == "High Risk",
                                "Give 20% Discount + Call Customer",
                         ifelse(test$Risk_Level == "Medium Risk",
                                "Send Promotional Offer",
                                "No Action"))

cat("✅ Action plan created!\n")
cat("   Action distribution:\n")
print(table(test$Retention_Action))

# ============================================================
# 1️⃣2️⃣ REVENUE ANALYSIS
# ============================================================

cat("\n💰 REVENUE ANALYSIS BY RISK SEGMENT\n")
cat("============================================\n")

total_rev <- sum(test$Monthly.Charge)

rev_table <- aggregate(Monthly.Charge ~ Risk_Level, data=test, sum)
rev_table$Revenue_Percentage <- round((rev_table$Monthly.Charge / total_rev) * 100, 2)
rev_table$Customer_Count <- as.numeric(table(test$Risk_Level)[rev_table$Risk_Level])
rev_table$Avg_Monthly_Charge <- round(rev_table$Monthly.Charge / rev_table$Customer_Count, 2)

cat("\nRevenue by Risk Level:\n")
print(rev_table)

cat("\n📌 KEY INSIGHTS:\n")
cat("   Total Monthly Revenue at Risk:", paste0("$", round(sum(rev_table$Monthly.Charge), 2)), "\n")
cat("   High Risk Revenue:", paste0("$", round(rev_table$Monthly.Charge[rev_table$Risk_Level == "High Risk"], 2)), 
    " (", rev_table$Revenue_Percentage[rev_table$Risk_Level == "High Risk"], "%)\n")

# ============================================================
# 1️⃣3️⃣ CUSTOMER DISTRIBUTION
# ============================================================

cat("\n👥 CUSTOMER DISTRIBUTION BY RISK LEVEL\n")
cat("============================================\n")

cust_percent <- round(prop.table(table(test$Risk_Level)) * 100, 2)
print(cust_percent)

cust_df <- data.frame(
  Risk_Level = names(cust_percent),
  Customer_Percentage = as.numeric(cust_percent)
)

cat("\n📌 KEY INSIGHTS:\n")
cat("   Total Customers Analyzed:", nrow(test), "\n")
cat("   High Risk Customers:", cust_percent["High Risk"], "% (", 
    length(test$Risk_Level[test$Risk_Level == "High Risk"]), " customers)\n")

# ============================================================
# 1️⃣4️⃣ VISUALIZATION 1: Revenue at Risk by Segment
# ============================================================

cat("\n📊 Generating Revenue Visualization...\n")

p1 <- ggplot(rev_table, aes(x=reorder(Risk_Level, -Revenue_Percentage), 
                             y=Revenue_Percentage, 
                             fill=Risk_Level)) +
  geom_bar(stat="identity", width=0.7) +
  geom_text(aes(label=paste0(Revenue_Percentage,"%")), 
            vjust=-0.5, fontface="bold", size=5) +
  scale_fill_manual(values=c("High Risk"="#d32f2f", 
                             "Medium Risk"="#fdd835", 
                             "Low Risk"="#43a047")) +
  labs(title="💰 Revenue at Risk by Customer Segment",
       x="Risk Level",
       y="Revenue Percentage (%)",
       subtitle="Monthly recurring revenue exposure") +
  theme_minimal() +
  theme(plot.title = element_text(face="bold", size=14),
        axis.text = element_text(size=11),
        legend.position = "bottom")

print(p1)

# Save to file
png("Customer-Churn-R/revenue_risk_analysis.png", width=800, height=600, res=100)
print(p1)
dev.off()
cat("✅ Saved: revenue_risk_analysis.png\n")

# ============================================================
# 1️⃣5️⃣ VISUALIZATION 2: Customer Distribution by Risk
# ============================================================

cat("\n📊 Generating Customer Distribution Visualization...\n")

p2 <- ggplot(cust_df, aes(x=reorder(Risk_Level, -Customer_Percentage), 
                           y=Customer_Percentage, 
                           fill=Risk_Level)) +
  geom_bar(stat="identity", width=0.7) +
  geom_text(aes(label=paste0(Customer_Percentage,"%")), 
            vjust=-0.5, fontface="bold", size=5) +
  scale_fill_manual(values=c("High Risk"="#d32f2f", 
                             "Medium Risk"="#fdd835", 
                             "Low Risk"="#43a047")) +
  labs(title="👥 Customer Distribution by Risk Level",
       x="Risk Level",
       y="Customer Percentage (%)",
       subtitle="Proportion of customer base in each risk category") +
  theme_minimal() +
  theme(plot.title = element_text(face="bold", size=14),
        axis.text = element_text(size=11),
        legend.position = "bottom")

print(p2)

# Save to file
png("Customer-Churn-R/customer_distribution.png", width=800, height=600, res=100)
print(p2)
dev.off()
cat("✅ Saved: customer_distribution.png\n")

# ============================================================
# 1️⃣6️⃣ VISUALIZATION 3: Feature Importance Top 10
# ============================================================

cat("\n📊 Generating Feature Importance Visualization...\n")

p3 <- ggplot(head(importance_df, 10), 
             aes(x=reorder(Feature, Importance), y=Importance, fill=Importance)) +
  geom_bar(stat="identity") +
  geom_text(aes(label=round(Importance, 2)), hjust=-0.3, fontface="bold") +
  scale_fill_gradient(low="#1976d2", high="#d32f2f") +
  coord_flip() +
  labs(title="⭐ Top 10 Feature Importance",
       x="Features",
       y="Mean Decrease in Gini",
       subtitle="Which factors drive churn prediction") +
  theme_minimal() +
  theme(plot.title = element_text(face="bold", size=14),
        axis.text = element_text(size=11))

print(p3)

# Save to file
png("Customer-Churn-R/feature_importance.png", width=800, height=600, res=100)
print(p3)
dev.off()
cat("✅ Saved: feature_importance.png\n")

# ============================================================
# 1️⃣7️⃣ SAVE RESULTS TO CSV
# ============================================================

cat("\n💾 Exporting Results to CSV...\n")

# Detailed results with all predictions
results_df <- test[, c("Gender", "Senior.Citizen", "Tenure.in.Months", 
                        "Contract", "Monthly.Charge", "Internet.Service",
                        "Churn.Label", "Churn_Probability", 
                        "Risk_Level", "Retention_Action")]

write.csv(results_df, "Customer-Churn-R/churn_predictions_results.csv", row.names=FALSE)
cat("✅ Saved: churn_predictions_results.csv\n")

# Revenue summary
write.csv(rev_table, "Customer-Churn-R/revenue_analysis.csv", row.names=FALSE)
cat("✅ Saved: revenue_analysis.csv\n")

# Feature importance
write.csv(importance_df, "Customer-Churn-R/feature_importance.csv", row.names=FALSE)
cat("✅ Saved: feature_importance.csv\n")

# ============================================================
# 1️⃣8️⃣ FINAL BUSINESS SUMMARY REPORT
# ============================================================

cat("\n")
cat("════════════════════════════════════════════════════════════════\n")
cat("           📋 FINAL BUSINESS SUMMARY REPORT\n")
cat("════════════════════════════════════════════════════════════════\n\n")

cat("🎯 BUSINESS METRICS\n")
cat("────────────────────────────────────────────────────────────────\n")
cat("✓ Model Accuracy:", round(cm$overall['Accuracy'] * 100, 2), "%\n")
cat("✓ Churn Detection Rate:", round(cm$byClass['Sensitivity'] * 100, 2), "%\n")
cat("✓ Specificity (No-Churn Detection):", round(cm$byClass['Specificity'] * 100, 2), "%\n\n")

cat("💰 REVENUE IMPACT ANALYSIS\n")
cat("────────────────────────────────────────────────────────────────\n")
cat("✓ Total Monthly Revenue:", paste0("$", round(total_rev, 2)), "\n")
cat("✓ High Risk Revenue Exposure:", 
    paste0("$", round(rev_table$Monthly.Charge[rev_table$Risk_Level == "High Risk"], 2)), "\n")
cat("✓ At-Risk Revenue Percentage:", 
    rev_table$Revenue_Percentage[rev_table$Risk_Level == "High Risk"], "%\n\n")

cat("👥 CUSTOMER SEGMENTATION\n")
cat("────────────────────────────────────────────────────────────────\n")
cat("✓ High Risk Customers:", cust_percent["High Risk"], "% (", 
    length(test$Risk_Level[test$Risk_Level == "High Risk"]), " customers)\n")
cat("✓ Medium Risk Customers:", cust_percent["Medium Risk"], "% (", 
    length(test$Risk_Level[test$Risk_Level == "Medium Risk"]), " customers)\n")
cat("✓ Low Risk Customers:", cust_percent["Low Risk"], "% (", 
    length(test$Risk_Level[test$Risk_Level == "Low Risk"]), " customers)\n\n")

cat("🎯 TOP 3 CHURN DRIVERS\n")
cat("────────────────────────────────────────────────────────────────\n")
for (i in 1:3) {
  cat(paste0(i, ". ", importance_df$Feature[i], 
             " (Importance: ", round(importance_df$Importance[i], 2), ")\n"))
}

cat("\n📌 RECOMMENDED ACTIONS\n")
cat("────────────────────────────────────────────────────────────────\n")
cat("1. HIGH RISK SEGMENT:\n")
cat("   • Provide 20% discount offer\n")
cat("   • Call customer personally\n")
cat("   • Action Priority: IMMEDIATE\n")
cat("   • Potential Revenue Recovery:", 
    paste0("$", round(rev_table$Monthly.Charge[rev_table$Risk_Level == "High Risk"], 2)), "\n\n")

cat("2. MEDIUM RISK SEGMENT:\n")
cat("   • Send promotional offers\n")
cat("   • Offer service upgrades\n")
cat("   • Action Priority: THIS WEEK\n\n")

cat("3. LOW RISK SEGMENT:\n")
cat("   • Maintain relationship\n")
cat("   • Monitor for changes\n")
cat("   • Action Priority: ROUTINE\n\n")

cat("════════════════════════════════════════════════════════════════\n\n")

cat("✅ Pipeline execution completed successfully!\n")
cat("📁 Results saved to Customer-Churn-R/ folder:\n")
cat("   • churn_predictions_results.csv\n")
cat("   • revenue_analysis.csv\n")
cat("   • feature_importance.csv\n")
cat("   • revenue_risk_analysis.png\n")
cat("   • customer_distribution.png\n")
cat("   • feature_importance.png\n\n")

cat("🚀 Ready for business decision-making!\n")

############################################################
# END OF PRODUCTION PIPELINE
############################################################
