# Add all Functions and Libraries
# Libraries:

library(ggplot2)
library(quantmod)
library(roll)
library(lmtest)
library(tidyr)
library(readxl)
library(kableExtra)

# --------------------------------------------------------------------------
# ------------------- Simple Stock Algorithm Function ----------------------
# Functions:
simple.algo <<- function(data,omega,min,max){
  prices <- data[min:max]
  # 3-day MA
  moving.average <- stats::filter(prices,rep(1/3, 3), sides = 1)
  # 3-day MSD
  moving.standard.d <- roll_sd(prices,3)
  # 3-day MA + 3-day MSD
  func <- moving.average + omega * moving.standard.d 
  # error
  error <- prices - func
  
  # Remove NA values
  prices <- prices[!is.na(moving.average)]
  moving.average <- moving.average[!is.na(moving.average)]
  moving.standard.d <- moving.standard.d[!is.na(moving.standard.d)]
  func <- func[!is.na(func)]
  error <- round(error[!is.na(error)],3)
  
  
  #Let us Make a new dataframe with all of the values:
  new.df <- as.data.frame(cbind(prices,
                                moving.average,
                                moving.standard.d,
                                func,
                                error))
  
  colnames(new.df) <- c("Prices",
                        "MovingAverage",
                        "MovingStandardDev",
                        "Func",
                        "Error")
  
  return(new.df)
}

# ------------------------------------------------------------------------
# -------------------- Gradient Descent Function -------------------------

gradient.descent <- function(data,learning.rate=0.01,iterations=1000){
  # Naming Variables
  price <- data$Price
  moving.average <- data$MovingAverage
  moving.standard.d <- data$MovingStandardDev
  
  # Number of Training Examples:
  m <- length(price)
  
  # Initiate omega
  omega <- 0
  
  omega.values <- numeric(iterations)
  
  # Gradient Descent Loop:
  for(i in 1:iterations){
    #print(omega)
    # Compute the Predictions Based on Current Data:
    predictions <- moving.average + omega * moving.standard.d
    
    # Calculate the Error:
    error <- predictions - price
    
    # Compute Gradient:
    gradient <- (1/m) * sum(error * moving.standard.d)
    #cat("Gradient: ",gradient)
    
    # Update Omega
    omega <- omega - learning.rate * gradient
    
    omega.values[i] <- omega
  }
  # Return Optimized Values:
  return(omega)
}

# -------------------------------------------------------------------------

mse.stock <- function(data){
  return(mean(data$Error^2))
}

# --------------------------------------------------------------------------
# ----------------------- Directional Accuracy Function --------------------
# -- ** This is a directional accuracy function through random windows ** --
acc.func <- function(data,omega,iterations){
  
  omega <- omega
  data <- data
  
  # Initialize Empty Vectors:
  window <- c() # Initialized Window Vector
  accuracy <- c() # Initialized 
  
  iterations <- iterations # For loop iterations
  
  middle <- round(length(data$Prices)/2) # For runif
  
  # Loop
  i = 0
  time.a <- proc.time()[3]
  for(i in 1:iterations){
    # 1. Create Bounds:
    left <- round(runif(1,0,middle))
    #print(left)
    right <- round(runif(1,middle+1,length(data$Prices)))
    #print(right)
    #cat(left,right)
    # 2. Create Models:
    model <- simple.algo(data$Prices,omega,left,right)
    #print(2)
    # 3. Run Accuracy Function
    acc <- direction.comparison(model)
    #print(4)
    # 4. Append Vectors
    window <- append(window,right-left)
    accuracy <- append(accuracy,acc)
    #print(5)
  }
  time.b <- proc.time()[3]
  
  #print(time.b - time.a) # Prints time to complete algorithm
  #print(summary(window)) # Prints range of window
  
  df <- data.frame(window,accuracy)
  return(df)
}

# ----------------------------------------------------------------------------
# ----------------- Direction Comparison Function ----------------------------

direction.comparison <- function(data,min = 0,max = length(data$Prices)){
  # Retrieve Data
  prices <- data$Prices[min:max]
  model <- data$Func[min:max]
  
  # Convert to Binary Vectors
  prices.bin <- ifelse(diff(prices) > 0,1,0) 
  model.bin <- ifelse(diff(model) > 0,1,0) 
  
  # Discard NA's
  prices.bin <- prices.bin[!is.na(prices.bin)]
  model.bin <- model.bin[!is.na(model.bin)]
  
  # Check for Congruence:
  check <- ifelse(prices.bin == model.bin,1,0)
  
  # Accuracy Percentage:
  acc <- sum(check)/length(check)
  
  return(acc)
}

# -------------------------------------------------------------------------------
# ------------------ Directional Accuracy Through Random Windows ----------------
# -------------------------------------------------------------------------------

# We are using time series cross validation to see where the 
# directional accuracy converges

# Data
stock.df <- getSymbols('DDD',src='yahoo',auto.assign = F)

# Create the Model
model1 <- simple.algo(stock.df$DDD.Close,1,0,length(stock.df$DDD.Close))
#view(model1)
# Optimize Model
omega <- gradient.descent(model1)
#omega
# Create Optimized Model:
model2 <- simple.algo(stock.df$DDD.Close,omega,0,length(stock.df$DDD.Close))
#view(model2)

# Check MSE
cat("Model 1 Error",mse.stock(model1),"\n","Model 2 Error",mse.stock(model2))

# Check the convergence of the optimized model's directional accuracy:
conv <- acc.func(model2,omega,1000)
plot(conv$window,conv$accuracy,xlab="Window",ylab="Directional Accuracy")

# -------------------------------------------------------------------------------
# ---------------- Slightly More Rigorous Convergence Test ---------------------
# --------------------------------------------------------------------------------

# Window Sizes: Create a sequence of window sizes that get larger by a factor. 
sizes <- c(seq(400,4000,50))
# Directional Accuracy Over Each Size:

# Directional Accuracy Function for Fixed Length
## **Note: This code is extremely slow because of the nested for loop.**
fixedDirectionalAccuracy <- function(data,sizes){
  time.a <- proc.time()[3]
  window.max <- c()
  window.min <- c()
  window.range <- c()
  window.sd <- c()
  for(l in 1:length(sizes)){
    # Shifts our window one unit to the right and computes the directional accuracy
    window <- sizes[l]
    window.vec <- c()
    min.vec <- c()
    max.vec <- c()
    range.vec <- c()
    
    for(i in 1:4000){
      min <- i
      max <- i + window
      direction <- direction.comparison(data,min = min,max = max)
      window.vec <- append(window.vec,direction)
    }
    
    df.min <- min(window.vec) # Minimum Accuracy
    df.max <- max(window.vec) # Maximum Accuracy
    df.sd <- sd(window.vec)
    df.range <- df.max - df.min # Acuracy Range
    
    
    window.max <- append(window.max,df.max)
    window.min <- append(window.min,df.min)
    window.sd <- append(window.sd,df.sd)
    window.range <- append(window.range,df.range)
  }
  
  accuracy.df <- data.frame(window.max,window.min,window.range,window.sd)
  time.b <- proc.time()[3]
  cat("Seconds: ",time.b - time.a)
  return(accuracy.df)
}

test <- fixedDirectionalAccuracy(model2,sizes)

# Plot the Results:
plot(test$window.sd,
     xlab="Index",
     ylab="Directional Accuracy Range",
     main="Directional Accuracy Standard Deviation as the Window Gets Larger")

# Plot the max and minimum of each window's directional accuracy test.
x <- 1:length(test$window.max)
ggplot(data = test)+
  geom_point(aes(x=x,y=test$window.max),col = "blue")+
  geom_point(aes(x=x,y=test$window.min), col = "red")+
  xlab("Index")+
  ylab("Directional Accuracy")