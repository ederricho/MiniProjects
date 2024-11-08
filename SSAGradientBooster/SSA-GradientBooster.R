#----------------------------------------------------------------------
# ------------------------- Introduction ------------------------------
# The simple stock algorithm can be used when analyzing other time series 
# data. We will observe how error can be predicted using gradient boosting. 
# We will use the economics dataset in r. It is a dataset with 6 variables
# and 478 observations. It contains information on population, unemployment,
# and personal consumption with respect to the year and month. This dataset
# was produced from US economic time series data available from the Federal
# Reserve Bank of St. Louis.
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------

# Libraries and Data
library(tidyverse)
library(tinytex)
library(knitr)
library(xgboost)
library(roll)
library(kableExtra)


data1 <- economics

# ---------------------------------------------------------------------
# Personal Savings Rate Plot
plot(data1$psavert, ylab="psavert")

# ---------------------------------------------------------------------
# ----------------------- Algorithm -----------------------------------
# ---------------------------------------------------------------------

# Our Simple Algorithm
simple.algo <- function(data){
  #data <- data
  #data <- data$pce
  data <- data$psavert
  # ---------- Feature Engineering ---------------
  mov.avg <- roll_mean(data,3)
  mov.sd <- roll_sd(data,3)
  # ------------- Remove NAs ---------------------  
  data <- data[!is.na(mov.avg)] 
  mov.avg <-mov.avg[!is.na(mov.avg)]
  mov.sd <- mov.sd[!is.na(mov.sd)]
  model <- mov.avg + mov.sd
  # ------------- Error -----------------------
  error <- data - model
  df <- data.frame(data,mov.avg,mov.sd,model,error)
  return(df)
}

model <- simple.algo(data1) # <- New Model 

# Training And Testing Indexes
#n <- length(data1$date) # Full length of rows
n <- length(data1$psavert) # Full length of rows
n.train <- round((4*n)/5)
n.test <-  n - n.train

model.train <- model[c(1:n.train),] # Training Dataset
model.test <- model[n.train:n-2,] # Testing Dataset

cat("Model MSE: ", mean(model$error^2))

# ----------------------------------------------------------------------
# ------------------------ Gradient Boosting ---------------------------
# ----------------------------------------------------------------------

X <- as.matrix(model.train[,-5]) # All columns except error 
y <- model.train$error # Residuals/Error

# Prepare Data for Gradient Boosting
dtrain <- xgb.DMatrix(data = X, label = y)

# Set Parameters:
params <- list(
  objective = "reg:squarederror",
  eta = 0.01,  # Learning Rate (good rate = 0.01, for n=50-60)
  max_depth = 5 # Depth of Each Tree (good depth = 5, for n=50-60)
)

# Train the Gradient Booster on Model Results:
nrounds <- 1000
boosting_model <- xgboost(data = dtrain, params = params, nrounds = nrounds, verbose = 0)

# Predict Residuals:
R <- as.matrix(model.test[,-5])
resid.pred <- predict(boosting_model, R)

# Create new Dataframe:
model.testAdded <- model.test
model.testAdded$gradBoostError <- resid.pred

# Graph the Errors:
x <- c(1:length(model.testAdded$data))
ggplot(data = model.testAdded)+
  geom_line(aes(x=x,y=error),col="red")+
  geom_point(aes(x=x,y=gradBoostError),col="blue")

# ------------------------------------------------------------------
# ----------------------------- Analasys ---------------------------
# ------------------------------------------------------------------

# MSE of Error Prediction
mse.prediction <- mean((model.test$error - model.testAdded$gradBoostError)^2)
mse.prediction

# Metrics on the gradient booster error vs the model error
master.error <- abs(model.testAdded$error - model.testAdded$gradBoostError) 
summary(master.error)
cat("\nMaster Error Standard Deviation: ",sd(master.error))

# Add gradient boosted prediction:
grad.prediction <- model.testAdded$model + model.testAdded$gradBoostError

# Add this to a dataframe for plotting:
plot.df <- model.testAdded
plot.df$grad.prediction <- grad.prediction

# Plot Results
x <- c(1:length(plot.df$data))# x index
ggplot(data = plot.df)+
  geom_line(aes(x=x,y=data),col="red")+ # <- Origional Data
  geom_point(aes(x=x,y=grad.prediction),col="blue")+ # <- Gradient Boost Prediction
  geom_point(aes(x=x,y=model),col="gray") # <- Original Model Prediction

