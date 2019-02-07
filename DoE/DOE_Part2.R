library(gmodels)
library(vcd)
library(smbinning)
library(dplyr)
library(car)
require(pedometrics)
require(ggplot2)
require(geosphere)
library(tidyverse)
library(MASS)
library(ROCR)
library(DescTools)
library(Hmisc)

indir = '/Users/bxp151/Documents/MSA 2019/040 DOE/HW02/'

original = read.csv(paste0(indir, 'survey.csv'))
modified = read.csv(paste0(indir, 'modified.csv'))

# select the ID and distance columns
# modified = modified[,c(2,14)]

# merge in the euclidean distance
# original = merge(original, modified)

# calculated distances from locations to each person
distm(c(original$LONG[1], original$LAT[1]), c(-78.878130, 35.89314), fun = distHaversine)
distm(c(-78.57391, 35.79098), c(-78.878130, 35.89314), fun = distHaversine)

locations = data.frame(Location = c(1,2,3,4,5)
                       , LONG2 = c(-78.878130,
                                   -78.875880,
                                   -78.676540,
                                   -79.054280,
                                   -78.575981), 
                       LAT2 = c(35.89314,
                                35.74628,
                                35.7724,
                                35.90535,
                                35.86696))

original = merge(original, locations)

for (i in 1: nrow(original)) {
  original$distance[i] = distm(c(original$LONG[i], original$LAT[i]), 
                               c(original$LONG2[i], original$LAT2[i]), 
                               fun = distHaversine) / 1000
}


# drop unecessary columns
original = subset(original, select=-c(X,ID, LONG, LAT, LONG2, LAT2))

# convert columns to factor
original[,c(1,3:8)] = lapply(original[,c(1,3:8)], factor) 

# convert will_attend to numeric for IV
original$will_attend = as.numeric(original$will_attend)

# Create Training and Validation #
set.seed(12345)
train_id <- sample(seq_len(nrow(original)), size = floor(0.75*nrow(original)))
train <- original[train_id, ]
test <- original[-train_id, ]

table(train$will_attend)
table(test$will_attend)

# Fit Full model and check for multicollinearity - none
fit1 = glm(will_attend ~ ., family = binomial(logit), data = train)
stepVIF(fit1, threshold = 10, verbose = FALSE)

# Check linearity assumption 

termplot(fit1, terms = "ages", partial.resid = TRUE, se = TRUE, smooth = panel.smooth)
crPlot(fit1, "ages") #violates linearity assumptions
termplot(fit1, terms = "distance", partial.resid = TRUE, se = TRUE, smooth = panel.smooth)
crPlot(fit1, "distance") #violates linearity assumptions

##########################################################################################
#  transforming age into binned variable
##########################################################################################

num_names <- names(train)[sapply(train, is.numeric)] # numeric variables in data #

result_all_sig <- list() # Creating empty list to store all results #

check_res <- smbinning(df = train, y = "will_attend", x = num_names[1])
result_all_sig[[num_names[1]]] <- check_res
check_res <- smbinning(df = train, y = "will_attend", x = num_names[3])
result_all_sig[[num_names[3]]] <- check_res


for(i in 1:length(result_all_sig)) {
  train <- smbinning.gen(df = train, 
                         ivout = result_all_sig[[i]], 
                         chrname = paste(result_all_sig[[i]]$x, "_bin", sep = ""))
  test <- smbinning.gen(df = test, 
                        ivout = result_all_sig[[i]], 
                        chrname = paste(result_all_sig[[i]]$x, "_bin", sep = ""))
  
}
# removing ages and distance variable
train$ages = NULL
train$distance = NULL
test$ages = NULL
test$distance = NULL

# fitting new model
fit2 = glm(will_attend ~ ., family = binomial(logit), data = train)

# Information Value for Each Variable #
iv_summary <- smbinning.sumiv(df = train, y = "will_attend")
smbinning.sumiv.plot(iv_summary)
iv_summary

# dropping the weak variables - race sex income
train = subset(train, select=-c(race,sex,income))
test = subset(test, select=-c(race,sex,income))

# Fit model after selecting variables
fit3 = glm(will_attend ~ ., family = binomial(logit), data = train)

# Reduced model is no different from full model 
anova(fit2, fit3, test = "LRT")

summary(fit3)

# dropping price, reduced model is no different from full 
fit4 = glm(will_attend ~ Location + Experience + Other + ages_bin + 
             distance_bin, binomial(logit), data = train)

anova(fit3,fit4, test = 'LRT')

summary(fit4)

# build data / odds  from from summary results
fit4summary = summary(fit4)
fit4results = data.frame(round(fit4summary$coefficients,5))
fit4results$Exp = round(exp(fit4results$Estimate),5)
fit4results = fit4results[,c(1,5,2,3,4)]



### ROC curves TRAINING DATA ###
# the predicted probabilities go first, the actual outcomes (as a factor) second
pred <- prediction(fitted(fit4), factor(fit4$y))
# then in performance, "measure" is the y-axis, and "x.measure" is the x-axis
# for a roc curve, we want tpr vs. fpr. "sens" and "spec" also work
perf <- performance(pred, measure = "tpr", x.measure = "fpr")
# then we can plot
plot(perf, colorize = TRUE)
# add 45-degree line (random guessing)
abline(a = 0, b = 1, lty = 2)
# AUC
auc <- performance(pred, measure = "auc")@y.values
auc


# binding test and train sets and exporting
export = rbind(train, test)
write.csv(export, '/Users/bxp151/Documents/MSA 2019/040 DOE/HW02/hw2-final.csv')
