# load packages
library(caret)
library(C50)
library(pROC)
library(ROSE)

# read the data
diabetes <- read.csv('../input/diabetes.csv', header = TRUE)
# set all variable headers to lower case letters
names(diabetes) <- tolower(names(diabetes))

# check the data
head(diabetes)
str(diabetes)

# turn variavle 'outcome' as a dependet/respond variable 
# to factor & set '0' & '1' into 'No' & 'Yes'
diabetes$outcome <- factor(ifelse(diabetes$outcome == 0, 'No', 'Yes'))

# check nr of 'yes' & 'no' in the 'outcome' variable
table(diabetes$outcome)

# split data into train & test set 
indices <- sample(2, nrow(diabetes), replace = TRUE, 
                  prob = c(0.8, 0.2))
train_x <- diabetes[indices == 1,]
test_y <- diabetes[indices == 2,]

cvCont <- trainControl(method = "repeatedcv", number = 5,
                       summaryFunction = twoClassSummary, 
                       classProbs = TRUE)

grid <- expand.grid(model = "tree",
                    trials = 1:10,
                    winnow = FALSE)

# set seed for reproducibility
set.seed(1)

# train the model using C5.0 package
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

# test the model on the test set, 
test_pred <- predict(c50_model, newdata = test_y[,-9], type = 'raw')
confusionMatrix(test_y$outcome, test_pred)

# plot roc for the test set
auc_p <- predict(c50_model, newdata = test_y, type = 'prob')[,2]
plot.roc(test_y$outcome, auc_p, percent=TRUE, 
         print.auc=TRUE, main = 'Test set')

# calculating F1 score
precision <- posPredValue(test_pred, test_y$outcome)
recall <- sensitivity(test_pred, test_y$outcome)
F1 <- (2 * precision * recall) / (precision + recall)
F1

# check accuracy
accuracy <- table(Actual = test_y$outcome, Pred = test_pred)
accuracy
# accuracy for each group in percentage
addmargins(round(prop.table(accuracy, 1), 3) * 100)

# check which variables/columns are most important
varImpact <- varImp(c50_model, scale = FALSE)
varImpact
# plot top 20 most important variables
plot(varImpact, 8, main = "Variable impact")

# Balanced version
# Balancing the data using ROSE package. 

# read the data
diabetes <- read.csv('../input/diabetes.csv', header = TRUE)
# set all variable headers to lower case letters
names(diabetes) <- tolower(names(diabetes))

# check the data
head(diabetes)
str(diabetes)

# turn variavle 'outcome' as a dependet/respond variable 
# to factor & set '0' & '1' into 'No' & 'Yes'
diabetes$outcome <- factor(ifelse(diabetes$outcome == 0, 'No', 'Yes'))

# Now we get almost equal number of 'No' & 'Yes'
# over sampling using 'ROSE'
df_balanced <- ovun.sample(outcome ~ ., data = diabetes, method = "over", 
                           seed = 1, N = 990)$data
table(df_balanced$outcome)

# Split balanced data into train and test set
# split data into train & test set 
indices <- sample(2, nrow(df_balanced), replace = TRUE, 
                  prob = c(0.8, 0.2))
train <- df_balanced[indices == 1,]
test <- df_balanced[indices == 2,]

# Using the same exact model as in the first version

cvCont <- trainControl(method = "repeatedcv", number = 5,
                       summaryFunction = twoClassSummary, 
                       classProbs = TRUE)

grid <- expand.grid(model = "tree",
                    trials = 1:10,
                    winnow = FALSE)

# set seed for reproducibility
set.seed(1)

# train the model using C5.0 package
c50_2nd <- train(x = train[, -9],
                 y = train[, 9],
                 method = "C5.0",
                 tuneLength = 3,
                 preProc = c("center", "scale"),
                 tuneGrid = grid,
                 metric = "ROC",
                 trControl = cvCont)

# check model
c50_2nd
summary(c50_2nd)

# plot of the c50_model
plot(c50_2nd, transform.x = log10, 
     xlab = expression(log[10](gamma)), 
     ylab = "cost")

# test trained model on the test set, 
t_pred <- predict(c50_2nd, newdata = test[,-9], type = 'raw')
confusionMatrix(test$outcome, t_pred)

# plot roc for the test set
auc_2nd <- predict(c50_2nd, newdata = test, type = 'prob')[,2]
plot.roc(test$outcome, auc_2nd, percent=TRUE, 
         print.auc=TRUE, main = 'Test balanced')

# calculating F1 score
precision <- posPredValue(t_pred, test$outcome)
recall <- sensitivity(t_pred, test$outcome)
F1 <- (2 * precision * recall) / (precision + recall)
F1

# check accuracy
accuracy <- table(Actual = test$outcome, Pred = t_pred)
accuracy
# accuracy for each group in percentage
addmargins(round(prop.table(accuracy, 1), 3) * 100)

# check which variables/columns are most important
varImpact <- varImp(c50_2nd, scale = FALSE)
varImpact
# plot top 20 most important variables
plot(varImpact, 8, main = "Variable impact")

