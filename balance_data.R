# load packages
library(caret)
library(C50)
library(e1071)
library(plyr)
library(gbm)
library(pROC)
library(ROSE)

# clear environment
rm(list=ls())

# read the data taken from kaggle.com 
diabetes <- read.csv('diabetes.csv')
# set variable headers all to lower case letters
names(diabetes) <- tolower(names(diabetes))
# check the data
head(diabetes)
str(diabetes)

# turn variavle 'outcome' as a dependet/respond variable 
# to factor & set '0' & '1' into 'No' & 'Yes'
diabetes$outcome <- factor(ifelse(diabetes$outcome == 0, 'No', 'Yes'))

# check the structure of the data
# make sure that variable 'outcome' is now a factor variable
str(diabetes)

# over sampling using 'ROSE'
balanced_data <- ovun.sample(outcome ~ ., data = diabetes, method = "over", 
                             seed = 1, N = 990)$data
table(balanced_data$outcome)
# split data into train validation & test set (the ideal way)
# you can choose to just split the data into train and test set
indices <- sample(3, nrow(balanced_data), replace = TRUE, prob = c(0.6, 0.2, 0.2))
train_x <- balanced_data[indices == 1,]
valid_set <- balanced_data[indices == 2,]
test_y <- balanced_data[indices == 3,]

cvCont <- trainControl(method = "repeatedcv", number = 5,
                       summaryFunction = twoClassSummary, 
                       classProbs = TRUE)

grid <- expand.grid(model = "tree",
                    trials = c(1:100),
                    winnow = FALSE)
# set seed for reproducibility
set.seed(1)

# train the first model
c50_model <- train(x = train_x[, -9],
                   y = train_x[, 9],
                   method = "C5.0",
                   tuneLength = 3,
                   preProc = c("center", "scale"),
                   tuneGrid = grid,
                   metric = "ROC",
                   trControl = cvCont)
# check model
c50_model
summary(c50_model)

# plot of the c50_model
plot(c50_model, transform.x = log10, 
     xlab = expression(log[10](gamma)), 
     ylab = "cost")

# predict valid_set using trained model
valid_set$pred <- predict(c50_model, newdata = valid_set[,-9], type = 'raw')
confusionMatrix(valid_set$outcome, valid_set$pred)

# plot roc 
p <- predict(c50_model, newdata = valid_set, type = 'prob')[,2]
plot.roc(valid_set$outcome, p, percent=TRUE, print.auc=TRUE)

# let's train the second model. It shares same trControl
# with first model, but method now is 'svmLinearWeights'.
svm_model <- train(x = train_x[, -9],
                   y = train_x[, 9],
                   metric = "ROC",
                   tuneLength = 3,
                   trControl = cvCont,
                   method = "svmLinearWeights",
                   preProc = c("center", "scale"))
# check model
svm_model
summary(svm_model)

plot(svm_model, transform.x = log10, 
     xlab = expression(log[10](gamma)), 
     ylab = "cost")

# run valid set again
valid_set <- balanced_data[indices == 2,]
# predict test data using trained model
valid_set$pred_2nd <- predict(svm_model, newdata = valid_set[,-9], 
                              type = 'raw')
confusionMatrix(valid_set$outcome, valid_set$pred_2nd)

# run valid set again, if not will show an error
valid_set <- balanced_data[indices == 2,]
# plot roc for SVM model_two
p2 <- predict(svm_model, newdata = valid_set[-9], type = 'prob')[,2]
plot.roc(valid_set$outcome, p2, percent=TRUE, print.auc=TRUE)

# gbm model
gbmFit <- train(x = train_x[, -9],
                y = train_x[, 9],
                method="gbm", 
                metric = 'ROC',
                trControl = cvCont, 
                preProc = c("center", "scale"),
                bag.fraction = 0.4,
                tuneLength = 5)

# check the model
gbmFit
summary(gbmFit)

plot(gbmFit, transform.x = log10, 
     xlab = expression(log[10](gamma)), 
     ylab = "cost")

# predict test data using trained model
valid_set$pred_3rd <- predict(gbmFit, newdata = valid_set[,-9], type = 'raw')
confusionMatrix(valid_set$outcome, valid_set$pred_3rd)

# run valid set again, if not will show an error
valid_set <- balanced_data[indices == 2,]
# plot roc for gbm model
p3 <- predict(gbmFit, newdata = valid_set[-9], type = 'prob')[,2]
plot.roc(valid_set$outcome, p3, percent=TRUE, print.auc=TRUE)

# test best trained model on the test set.
test_pred <- predict(c50_model, newdata = test_y[,-9], type = 'raw')
confusionMatrix(test_y$outcome, test_pred)

# calculating F1 score for the test set
precision <- posPredValue(test_pred, test_y$outcome)
recall <- sensitivity(test_pred, test_y$outcome)
F1 <- (2 * precision * recall) / (precision + recall)
F1

# check accuracy
accuracy <- table(Actual = test_y$outcome, Pred = test_pred)
# accuracy for each group in percentage
addmargins(round(prop.table(accuracy, 1), 3) * 100)

