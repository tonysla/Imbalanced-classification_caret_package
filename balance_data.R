# load packages
library(caret)
library(C50)
library(e1071)
library(plyr)
library(gbm)
library(pROC)
library(ROSE)

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
data_over <- ovun.sample(outcome ~ ., data = diabetes, method = "over", 
                         seed = 1, N = 956)$data
table(data_over$outcome)
# split data into train validation & test set (the ideal way)
# you can choose to just split the data into train and test set
indices <- sample(3, nrow(data_over), replace = TRUE, prob = c(0.6, 0.2, 0.2))
train_x <- data_over[indices == 1,]
valid_set <- data_over[indices == 2,]
test_y <- data_over[indices == 3,]

cvCont <- trainControl(method = "repeatedcv", number = 5,
                       summaryFunction = twoClassSummary, 
                       classProbs = TRUE)

grid <- expand.grid(model = "tree",
                    trials = 1:100,
                    winnow = FALSE)
# set seed for reproducibility
set.seed(1)

# now let's train the first model
model_one <- train(x = train_x[, -9],
                   y = train_x[, 9],
                   method = "C5.0",
                   tuneLength = 3,
                   preProc = c("center", "scale"),
                   tuneGrid = grid,
                   metric = "ROC",
                   trControl = cvCont)
# check model
model_one
summary(model_one)

plot(model_one, transform.x = log10, 
     xlab = expression(log[10](gamma)), 
     ylab = "cost")

# predict test data using trained model
valid_set$pred <- predict(model_one, newdata = valid_set[,-9], type = 'raw')
confusionMatrix(valid_set$outcome, valid_set$pred)

# plot roc 
p <- predict(model_one, newdata = valid_set, type = 'prob')[,2]
plot.roc(valid_set$outcome, p, percent=TRUE, print.auc=TRUE)

# let's train the second model. It shares same trControl
# with first model, but method now is 'svmLinearWeights'.
model_two <- train(x = train_x[, -9],
                   y = train_x[, 9],
                   metric = "ROC",
                   tuneLength = 3,
                   trControl = cvCont,
                   method = "svmLinearWeights",
                   #tuneGrid = ex_gr,
                   preProc = c("center", "scale"))
# check model
model_two
summary(model_two)
plot(model_two, transform.x = log10, 
     xlab = expression(log[10](gamma)), 
     ylab = "cost")

# run valid set again
valid_set <- data_over[indices == 2,]
# predict test data using trained model
valid_set$pred_2nd <- predict(model_two, newdata = valid_set[,-9], type = 'raw')
confusionMatrix(valid_set$outcome, valid_set$pred_2nd)

# plot roc for SVM model_two
p2 <- predict(model_two, newdata = valid_set[-9], type = 'prob')[,2]
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

# plot roc for SVM model_two
p3 <- predict(gbmFit, newdata = valid_set[-9], type = 'prob')[,2]
plot.roc(valid_set$outcome, p3, percent=TRUE, print.auc=TRUE)

# test best trained model on the test set.
# Usually models under perform on test set. 
test_pred <- predict(model_one, newdata = test_y[,-9], type = 'raw')
confusionMatrix(test_y$outcome, test_pred)

# check accuracy
accuracy <- table(Actual = test_y$outcome, Pred = test_pred)
accuracy

# accuracy for each group in percentage
addmargins(round(prop.table(accuracy, 1), 3) * 100)

# check which variables/columns are most important
varImpact <- varImp(model_one, scale = FALSE)
varImpact
# plot top 20 most important variables
plot(varImpact, 8, main = "svm Radial")

# plot the actual/known result
plot(test_y$outcome, main = 'Actual')$actual
# plot matrix of predicted accuracy
plot(accuracy, main = 'Accuracy')
# plot predicted from the model
plot(test_pred, main = 'Predicted')

# use the below function to clear environment
rm(list=ls())
