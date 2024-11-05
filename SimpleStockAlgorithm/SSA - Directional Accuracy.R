# -----------------------------------------------------------------------
# In this file, we will observe the directional accuracy of the simple
# stock algorithm. We will also do a hypothesis test to compare our results
# with the average results.
# -----------------------------------------------------------------------

# Libraries and Data:
library(ggplot2)
library(quantmod)
library(roll)
library(lmtest)
library(tidyr)
library(readxl)
library(kableExtra)

ford.df <- getSymbols('F',src='yahoo',auto.assign = F)

# Model and Graph

# Create a MSE Function:
mse.stock <- function(data){
  return(mean(data$Error^2))
}

# Create Optimized Model:
sample <- c(runif(1,0,350),runif(1,351,1000),runif(1,1001,1500))
left <- sample(sample,1)
right <- round(runif(1,1501,length(ford.df$F.Close)))
print(right - left)

data <- ford.df$F.Close # Data for Model
ford.original <- simple.algo(data,1,left,right) # Original Model with Omega = 1
omega <- gradient.descent(ford.original) # Calculate Optimized Omega
cat("Omega:",omega)

ford.optimized <- simple.algo(data,omega,left,right) # Optimized Model

# Compare MSE Values:
og.mse <- mse.stock(ford.original)
opt.mse <- mse.stock(ford.optimized)
cat("Origiinal MSE: ",og.mse,
    "\n",
    "Optimized MSE: ",opt.mse)

# Graph the Models:
# Graph Models
x = c(1:length(ford.optimized$Prices))
ggplot(data = ford.optimized)+
  geom_line(aes(x=x,y=ford.optimized$Prices),col="red")+
  geom_line(aes(x=x,y=ford.optimized$Func),col="blue")+
  geom_line(aes(x=x,y=ford.original$Func),col="black")

# ------------------------------------------------------------------------------
# --------------------------- Directional Accuracy Test ------------------------
# ------------------------------------------------------------------------------
direction.comparison <- function(data){
  # Retrieve Data
  prices <- data$Prices
  model <- data$Func
  
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

# For function we need data, iterations
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

accuracy.check <- acc.func(ford.optimized,omega,500)

# ------------------------------------------------------------------------
# -------------------- Analysis of findings ------------------------------
# ------------------------------------------------------------------------

# Calculate Accuracy for One Sample:
p.hat.vec <- acc.func(ford.optimized,omega,1)
p.hat <- p.hat.vec$accuracy
p0 <- 0.5
cat("P Hat: ",p.hat,"\n")

# Calculate Z-Statistic:
z <- (p.hat - p0)/(sqrt((p0*(1-p0))/(length(ford.optimized$Prices))))
cat("Z-Value: ",z,"\n")

# Calculate p-value
p.value <- pnorm(z,0,1,lower.tail = F)
cat("P-Value: ",p.value,"\n")



