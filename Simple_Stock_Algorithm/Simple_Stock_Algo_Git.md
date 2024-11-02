Simple Prediction Algorithm
================
Edgar Derricho

# Problem Statement and Motivation

When studying optimization methods like gradient descent, one might find
it intreaging to tackle a relevant question. As someone who enjoys
predictive modeling, the stock market is a natural place for me to go to
try my new data science skills. This brings us to the problem statement.
Is there a simple stock prediction algorithm that is easy to implement,
but allows us to use gradient descent and confidence intervals?

# Methodology

To implement optimization algorithms to predict, we will observe stock
prices and the opportunity for simple models to show us how simple
prediction can be.

Important Aspects of this Project:</br>

1.  Gradient Descent</br>
2.  Confidence Intervals</br>

We will use the following function for the predicted price:
$$p(t+1)=\mu(t)+\sigma(t)$$

Where: </br> $\mu(t)=$ moving average</br> $\sigma(t)=$moving standard
deviation</br>

``` r
# Define the Prediction Function
pred.price <- function(moving.avg,moving.sd,a = 1){
  return(moving.avg + a * moving.sd)
}
```

When using gradient descent, it is important to define a loss function.
In our case, we will use the mean sum squares function.

$$MSE = \frac{1}{n}\sum^{n}_{i=1}(\mu_{t}-x_{pred})^2$$

``` r
# Loss Function:

# We will use the sum squares error:
loss.function <- function(a,prices,moving.avg,moving.standard.d){
  #error <- prices - moving.avg
  
  # Predict future Prices
  pred.prices <- moving.avg + moving.standard.d
  
  # Calculate the sum of squared errors (SSE)
  sse <- sum((prices - pred.prices)^2)
  
  return(sse)
}
```

Now, let us upload the stock data and implement our algorithm using a
three-day moving average and a three-day moving standard deviation:

``` r
left <- 3800
right <- 3900
prices <- apple_df$AAPL.Close[left:right]


simple.algo <- function(data,omega){
  prices <- data
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
  
  return(new.df)
}

origional <- simple.algo(prices,1)
```

Let’s observe the error

    ## Error Mean:  -3.004646

    ## Error Standard Deviation:  3.223653

    ## Mean Squares of Error:  19.31487

# Gradient Descent

Let us add a coefficient ($\omega$) to our model and use gradient
descent to optimize it. Our new model is:

$$price = \mu(t)+\omega \sigma(t)$$ Explanation of Gradient Descent:
Link

Let us use gradient descent to optimize this coefficient:

Gradient Descent Code:

``` r
gradient.descent <- function(data,learning.rate=0.01,iterations=1000){
  # Naming Variables
  price <- data$AAPL.Close
  moving.average <- data$moving.average
  moving.standard.d <- data$AAPL.Close.1
  
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
```

Let us implement Gradient Descent, we will output the coefficient
$\omega$ and the time it takes for the algorithm to complete:

``` r
# GD Function
time.a <- proc.time()[3]
omega <- gradient.descent(origional,0.01,100)
time.b <- proc.time()[3]

# Time and Coefficient:
cat("Time to Complete: ",time.b - time.a,"\n",
    "Coefficient: ",omega)
```

    ## Time to Complete:  0.02 
    ##  Coefficient:  -0.2417677

Let us use our new omega with our algorithm:

``` r
# New Model
optim.df <- simple.algo(prices,omega)
```

MSE for the Original and Optimized Model:

    ## Origional Model MSE:  19.31487 
    ##  Optimized Model MSE:  6.396852

# Iterative Gradient Descent

Let us see if we can get a better MSE by using an iterative gradient
descent method where we update beta in an iterative manner, therefore,
instead of one $\omega$, we will have a vector of $\omega$ that could
prove to minimize error further.

Iterative Gradient Descent Method with an update after every 3
iterations:

``` r
# This will return a list of omega values for each iteration of our model:
iterative.gradient.descent <- function(data,learning.rate=0.01,iterations=1000){
  # Naming Variables
  price <- data$AAPL.Close
  moving.average <- data$moving.average
  moving.standard.d <- data$AAPL.Close.1
  
  # Omega Values:
  omega.vals <- numeric(length(price))
  
  # Initiate omega (parameters) as a Vector of Zeros
  omega <- 0
  
  # Gradient Descent Loop:
  for(t in 1:length(price)){
    #print(omega)
    # Compute the Predictions Based on Current Data:
    predictions <- moving.average[t] + omega * moving.standard.d[t]
    
    # Calculate the Error:
    error <- predictions - price[t]
    
    # Compute Gradient:
    gradient <- error * moving.standard.d
    #cat("Gradient: ",gradient)
    
    # Update Omega every n iterations:
    n = 3
    if(t %% n == 0){
      omega <- omega - learning.rate * gradient
    }else{
      omega <- omega
    }
    
    
  }
  # Return Optimized Values:
  return(omega)
}
```

Implement Iterative Gradient Descent on our Data and observe the first
six values of our $\omega$ vector:

``` r
# GD
time.a <- proc.time()[3]
iter.omega <- iterative.gradient.descent(origional)
time.b <- proc.time()[3]
it.time <- time.b - time.a

# Observe Omega Values
head(iter.omega)
```

    ## [1] -0.002187386  0.040415442  0.081665739  0.066460247  0.170187510
    ## [6]  0.056521271

``` r
# Final Omega Value:
f.omega <- iter.omega[length(iter.omega)]
```

Asses the Models:

    ## Origional Model MSE:  19.31487 
    ##  Optimized Model MSE:  6.396852 
    ##  Iterative Optimized Model MSE:  7.444044

**Note:** The iterative optimized model is programmed to change the
parameter $\omega$ after 3 iterations.</br>

The model with the smallest MSE is the optimized model. Therefore, we
will do more analysis on this model.

# Error Analysis

Let us quickly do an analysis on our error distribution of the Optimized
Model:

![](Simple_Stock_Algo_Git_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->

![](Simple_Stock_Algo_Git_files/figure-gfm/unnamed-chunk-14-1.png)<!-- -->

We can also implement a Shapiro-Wilk test for normality:

``` r
shapiro.test(optim.df$error)
```

    ## 
    ##  Shapiro-Wilk normality test
    ## 
    ## data:  optim.df$error
    ## W = 0.97066, p-value = 0.02598

We can see from the q-q plot and the Shapiro-Wilk test, that the error
is not normally distributed. In order to find confidence intervals, we
will bootstrap to find the mean and standard deviation. We will use the
“boot” package.

# Confidence Interval

``` r
library(boot)
error <- iter.model2$error

# Define a function for the statistic of interest:
mean.stat <- function(data,indices){
  d <- data[indices]
  return(mean(abs(d))) # Return Mean Absolute Error
}

# Bootstrap Loop:
bootstrap.results <- boot(error,statistic = mean.stat,R = 1000)
cat("Bootstrap Mean: ",mean(bootstrap.results$t),"\n","Sample Mean",mean(error),"\n")
```

    ## Bootstrap Mean:  2.301497 
    ##  Sample Mean -0.6095152

``` r
cat()

# Calculate CI:
ci <-boot.ci(bootstrap.results, type = "perc", conf = 0.95) # Using Percentile Method
ci
```

    ## BOOTSTRAP CONFIDENCE INTERVAL CALCULATIONS
    ## Based on 1000 bootstrap replicates
    ## 
    ## CALL : 
    ## boot.ci(boot.out = bootstrap.results, conf = 0.95, type = "perc")
    ## 
    ## Intervals : 
    ## Level     Percentile     
    ## 95%   ( 2.007,  2.588 )  
    ## Calculations and Intervals on Original Scale

# Confidence Error Visualization

**Note: We will use absolute error since our confidence interval is in
absolute error.**

``` r
# Retrieve Bootstrap Mean and Confidence Intervals:
ci.lower <- ci$percent[4] # 2.5th Percentile for 95% ci
ci.upper <- ci$percent[5] # 97.5th percentile for 95% ci
bootstrap.mean <- mean(bootstrap.results$t)
data <- abs(error)

# Plot the Data and Confidence Band:
plot(data, main = "Data with Bootstrap Confidence Interval for the Mean", 
     ylab = "Value", xlab = "Index", col = "blue", pch = 16, ylim = c(min(data) - 5, max(data) + 5))
abline(h = bootstrap.mean, col = "red", lwd = 2, lty = 2)  # Bootstrapped mean line
abline(h = ci.lower, col = "darkgreen", lwd = 2, lty = 2)  # Lower CI
abline(h = ci.upper, col = "darkgreen", lwd = 2, lty = 2)  # Upper CI
polygon(c(1, length(data), length(data), 1), c(ci.lower, ci.lower, ci.upper, ci.upper), 
        col = rgb(0.1, 0.9, 0.1, 0.2), border = NA)  # Shaded confidence band
legend("topright", legend = c("Bootstrap Mean", "95% CI"), col = c("red", "darkgreen"), 
       lty = 2, lwd = 2, bty = "n")
```

![](Simple_Stock_Algo_Git_files/figure-gfm/unnamed-chunk-17-1.png)<!-- -->

# Prediction interval for price

Quick Background on Prediction Intervals:

Note: We do not need to know the distribution of the prices for the
prediction interval, merely the distribution of the error. By
bootstrapping the standard deviation, we are effectively estimating the
uncertainty around the predictions without making strong assumptions
about the underlying distribution of the prices.

Steps to Construct a Prediction Interval:</br> </br> 1. Calculate
Predicted Prices</br> 2. Bootstrap the Standard Deviation of Prediction
Errors</br> 3. Define Critical Value: We will use a t-distribution of
the sample size is small, normal (z) if the sample size is large enough
(\>30)</br> 4. Construct a Prediction Interval</br>

Prediction Interval Formula:</br>

Prediction Interval = Prediction Price $\pm$ t $\cdot$ Standard
Deviation of Prediction Error

Mathematically:
$$[\hat{y}_{low},\hat{y}_{high}]=f(t)_{pred}\text{ }\pm\text{ }z_{\frac{\alpha}{2}}\cdot\sigma_{pred}$$

``` r
# We will use the best model's error to bootstrap: Optimized Model
error <- optim.df$error

# Define a function for the statistic of interest:
sd.stat <- function(data,indices){
  d <- data[indices]
  return(sd(d)) # Return Mean Absolute Error
}

# Bootstrap Loop:
bootstrap.sd <- boot(error,statistic = sd.stat,R = 1000)
bs.sd <- sd(bootstrap.sd$t)


# Critical Value for 95% Confidence Interval
alpha <- 0.05
z <- qnorm(1 - alpha/2)

# Construct Confidence Interval for Predicted Prices
lower.ci <- optim.df$func - z * bs.sd
upper.ci <- optim.df$func + z * bs.sd

# Display Results:
pred.int <- data.frame(origional$func,optim.df$AAPL.Close,optim.df$func,lower.ci,upper.ci)

cat("Bootstrap Standard Deviation: ",bs.sd,"\n",
    "Sample Standard Deviation",sd(error),"\n")
```

    ## Bootstrap Standard Deviation:  0.1431925 
    ##  Sample Standard Deviation 2.524018

``` r
head(pred.int)
```

    ##   origional.func optim.df.AAPL.Close optim.df.func lower.ci upper.ci
    ## 1       172.9399              171.66      172.1660 171.8853 172.4466
    ## 2       174.6201              174.83      172.5586 172.2780 172.8393
    ## 3       176.6194              176.28      173.6854 173.4048 173.9661
    ## 4       176.5216              172.12      173.8995 173.6188 174.1801
    ## 5       176.1717              168.64      171.4219 171.1412 171.7025
    ## 6       171.8236              168.88      169.4101 169.1294 169.6908

Plot Prediction Interval:

``` r
# Load necessary library
library(ggplot2)

# Assuming `predicted`, `lower_pi`, and `upper_pi` are vectors with the same length
# and you have a data frame `data` containing the actual prices (for context)

# Create a data frame for plotting
plot_data <- data.frame(
  Actual = pred.int$optim.df.AAPL.Close,         # Actual prices
  Original = pred.int$origional.func, # Original Model
  Predicted = pred.int$optim.df.func,   # Predicted prices from your model
  Lower_PI = pred.int$lower.ci,     # Lower bound of the prediction interval
  Upper_PI = pred.int$upper.ci      # Upper bound of the prediction interval
)

# Plot
ggplot(plot_data, aes(x = 1:nrow(plot_data))) + 
  geom_line(aes(y = Actual), color = "red", size = 1, linetype = "dashed") +  # Actual prices
  geom_line(aes(y = Predicted), color = "blue", size = 1) +
  #geom_line(aes(y = Original), color = "gray", size = 1)+ # Original Model
  # Predicted prices
  geom_ribbon(aes(ymin = Lower_PI, ymax = Upper_PI), fill = "lightgrey", alpha = 0.5) +  # Prediction interval
  labs(title = "Prediction Interval for Stock Prices",
       x = "Time",
       y = "Price") +
  theme_minimal() +
  scale_x_continuous(breaks = seq(1, nrow(plot_data), by = 20)) +  # Adjust x-axis for better visibility
  theme(legend.position = "none")
```

![](Simple_Stock_Algo_Git_files/figure-gfm/unnamed-chunk-19-1.png)<!-- -->

# Final Analysis and Thoughts

<mark>**Note: The tables below are not dynamic. The values below are for
the data set window $[3800:3900]$ to recreate this table, you must use
the code to retrieve the $\omega$ and MSE values.**</mark>

After further analysis, the iterative model sometimes gives better MSE
values than the optimized model depending on the sample size and the
iterations. We will use a table to show our results of the analysis:

Model Equation:</br> price = $\mu(t)+\omega\cdot\sigma(t)$
<table>
<caption>
Omega and MSE Values for Different Sample Sizes
</caption>
<thead>
<tr>
<th style="text-align:left;">
Model
</th>
<th style="text-align:right;">
Omega(50)
</th>
<th style="text-align:right;">
MSE(50)
</th>
<th style="text-align:right;">
Omega(500)
</th>
<th style="text-align:right;">
MSE(500)
</th>
<th style="text-align:right;">
Omega(1000)
</th>
<th style="text-align:right;">
MSE(1000)
</th>
<th style="text-align:right;">
Omega(Full Data Set)
</th>
<th style="text-align:right;">
MSE(Full Data Set)
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
Origional Model
</td>
<td style="text-align:right;">
1.00000
</td>
<td style="text-align:right;">
1.54405
</td>
<td style="text-align:right;">
1.000000
</td>
<td style="text-align:right;">
3.57646
</td>
<td style="text-align:right;">
1.00000
</td>
<td style="text-align:right;">
6.56491
</td>
<td style="text-align:right;">
1.00000
</td>
<td style="text-align:right;">
2.42637
</td>
</tr>
<tr>
<td style="text-align:left;">
Optimized Model
</td>
<td style="text-align:right;">
-0.08414
</td>
<td style="text-align:right;">
0.56448
</td>
<td style="text-align:right;">
0.068690
</td>
<td style="text-align:right;">
1.71234
</td>
<td style="text-align:right;">
0.03687
</td>
<td style="text-align:right;">
3.07273
</td>
<td style="text-align:right;">
0.03999
</td>
<td style="text-align:right;">
1.16414
</td>
</tr>
<tr>
<td style="text-align:left;">
Iterative Model: n=3
</td>
<td style="text-align:right;">
-0.01983
</td>
<td style="text-align:right;">
0.56822
</td>
<td style="text-align:right;">
0.045140
</td>
<td style="text-align:right;">
1.64484
</td>
<td style="text-align:right;">
0.07156
</td>
<td style="text-align:right;">
3.20574
</td>
<td style="text-align:right;">
0.12408
</td>
<td style="text-align:right;">
1.18825
</td>
</tr>
<tr>
<td style="text-align:left;">
Iterative Model: n=5
</td>
<td style="text-align:right;">
-0.00259
</td>
<td style="text-align:right;">
0.57786
</td>
<td style="text-align:right;">
0.061603
</td>
<td style="text-align:right;">
1.73541
</td>
<td style="text-align:right;">
0.16873
</td>
<td style="text-align:right;">
3.28375
</td>
<td style="text-align:right;">
0.02614
</td>
<td style="text-align:right;">
1.16207
</td>
</tr>
</tbody>
</table>
<table>
<caption>
Best Models Per Sample Size
</caption>
<thead>
<tr>
<th style="text-align:left;">
Sample Size
</th>
<th style="text-align:left;">
Best Model
</th>
<th style="text-align:right;">
MSE
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
50
</td>
<td style="text-align:left;">
Optimized Model
</td>
<td style="text-align:right;">
0.56448
</td>
</tr>
<tr>
<td style="text-align:left;">
500
</td>
<td style="text-align:left;">
Iterative Model: n=3
</td>
<td style="text-align:right;">
1.64484
</td>
</tr>
<tr>
<td style="text-align:left;">
1000
</td>
<td style="text-align:left;">
Optimized Model
</td>
<td style="text-align:right;">
3.07273
</td>
</tr>
<tr>
<td style="text-align:left;">
Full Data
</td>
<td style="text-align:left;">
Iterative Model: n=5
</td>
<td style="text-align:right;">
1.16207
</td>
</tr>
</tbody>
</table>

This project is great as an introduction to gradient descent and
confidence intervals.
