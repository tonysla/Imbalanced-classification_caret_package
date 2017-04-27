# Imbalanced classification
Comparing results of a classification model between imbalanced data with balanced data using `ROSE` package. I am using package `C50` for both cases to train the model. This is my third dataset balancing the data for classification and in one case this method did not make any difference. 

## Method 

I am using the same tunning parameters for both methods to have the ability to compare the difference between the imbalanced with balanced version. I chose package `C50` to train the models for no particular reason, it can be any package that performs classification. I also use `caret` package because I find it faster to train the models. The main package that plays the major role in balancing the data in this repo is `ROSE` package. I have to say that `ROSE` is not the only package or method to use to balance the data. I have used before another package, called `DMwR`. There are other ways to balance data in addition to `ROSE` & `DMwR` packages. 

* I am using kaggle.com [Pima Indians Diabetes Database](https://www.kaggle.com/uciml/pima-indians-diabetes-database) dataset.
* Class variable (0, 1) `outcome` classifies into non-diabetic (0) and diabetic (1). People classified as non-diabetic result to be a total of `500 people` and as diabetic result to be `268 people`. So, non-diabetic are overall almost double of diabetic people. 
* I train the first model based on the above data, & for the second one I balance non-diabetic with diabetic (500 = 500 or almost 500). 
* As metric I am using `pROC` to messure auc, confusion matrix & F1 score. 

## Packages used

    install.packages("C50")
    install.packages("caret")
    install.packages("plyr")
    install.packages("pROC")
    install.packages("ROSE")
    
## Results to compare

I am jumping into the results and not going through the steps of training the models. 

Confusion matrix for imbalanced version

              Reference
    Prediction No Yes
           No  90  15
           Yes 19  33
     
 Accuracy, sensitivity & specificity for the imbalanced version
        
        Accuracy : 0.7834
        Sensitivity : 0.8257          
        Specificity : 0.6875 

Confusion matrix for balanced version

              Reference
     Prediction No Yes
            No  84  21
            Yes 13  80

Accuracy, sensitivity & specificity for the balanced version

        Accuracy : 0.8283
        Sensitivity : 0.8660          
        Specificity : 0.7921 

There are less false negative predicted in the balanced version, eventhough the test set is larger than in the imbalanced version. That is why the sensitivity scores higher in the balanced version. Achiving a high score in sensitivity is more important than scoring a high result in total accuracy.

Comparing ROC chart for the imbalanced & balanced version

![imbalanced](https://cloud.githubusercontent.com/assets/22155935/25368216/e53b08ae-2948-11e7-9de7-9c2b878bda94.png)

ROC chart for the balanced version

![balanced](https://cloud.githubusercontent.com/assets/22155935/25467669/e85e8178-2add-11e7-981d-33143d87bb6d.png)


