# ----------------------- Trend Detection R File ------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# This is the trend detection R file. This fule contains all of the steps in the
# .rmd file in the repo. Run this file in chunks to get the proper outputs. This
# code uses an ensemble method to detect trend in time series graphs (specifically
# apple stock data). This uses a regression coefficient and the normalized sum of
# differences between prices (tau). Feel free to download and edit this file.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# ------------------------------ Libraries ------------------------------------
library(quantmod)
library(ggplot2)
library(knitr)
library(kableExtra)

# -----------------------------------------------------------------------------
# --------------------------- Retrieve Data -----------------------------------
# -----------------------------------------------------------------------------
# Gather the Data
apple_df <- getSymbols('AAPL',src='yahoo',auto.assign = F)

# ----------------------------- Tau Function ----------------------------------
# Tau Function
tau.fun <- function(data,min,max,window=5,alpha=0.05,output=0){
  # -------------- Tau Calculation ------------------------------------
  #graph_data <- data[(min-window):(max+window)] # the window is for graphing
  data <- data[min:max]
  n <- max - min # Calculate n
  difference <- diff(data[1:n]) # Calculate Difference
  difference <- difference[2:length(difference)] # Eliminate NA
  sd_difference <- sd(difference)
  sum_difference <- mean(difference)/sd(data) # Sum of Difference (Tau)
  t <- sum_difference/(sd(difference)/sqrt(n-1)) # t-value
  p_value <- 2 * pt(q=abs(t),df=n-2,lower.tail = F) # p-value
  # ------------------- Linear Regression Model ------------------------
  index <- c(1:length(data))
  mod <- lm(data ~ index)
  coef <- mod$coefficients[2]
  sum <- summary(mod)
  reg_pVal <- sum$coefficients[2,4]
  tau_significance <- ifelse(p_value > alpha,"fail to reject","reject")
  reg_significance <- ifelse(reg_pVal > alpha,"fail to reject","reject")
  direction_tau <- ifelse(sum_difference>0,"positive","negative")
  direction_reg <- ifelse(coef>0,"positive","negative")
  # ---------------- Data Frame of Results -----------------------------
  df <- data.frame(#data,
    min,
    max,
    sum_difference,
    sd_difference,
    p_value,
    coef,
    reg_pVal,
    tau_significance,
    reg_significance,
    direction_tau,
    direction_reg)
  colnames(df) <- c(#"Price",
    "Min",
    "Max",
    "Sum of Difference",
    "St.Dev. of Difference",
    "Tau p-value",
    "Regression Coef",
    "Regression p-value",
    "Null Tau",
    "Null Regression",
    "Tau Direction",
    "Regression Direction")

  # ------------------ Create the plot ------------------------------
  x <- c(1:length(data))

  # Change min and max for graph
  min <- window
  max <- length(data) - window-1
  mid <- (max - min)/2

# -----------------------------------------------------------------------------
# --------------------------- Plot Tau and Beta ------------------------------
# -----------------------------------------------------------------------------
  # Plot
  plot <- ggplot(data.frame(data), aes(x = x, y = data)) +
    geom_line(color = "blue", size = 1.2) +  # Line plot
    geom_rect(aes(xmin = min, xmax = max,   # Rectangle
                  ymin = -Inf, ymax = Inf),
              fill = "red", alpha = 0.01) + # Highlight color with transparency
    labs(title = "Highlight a Window in ggplot2") +
    theme_minimal()

  #print(plot) # Optional Print Plot

  # ---------------------- Model Output: ----------------------------------
  if(output == 1){
    cat("--------- Summary ---------","\n",
        "Tau p-value: ",p_value,"\n",
        "Regression p-value: ", reg_pVal,"\n",
        "----------- Diff ----------","\n",
        "Sum of Differences: ", sum_difference,"\n",
        "SD of Differences: ", sd_difference,"\n",
        "---------------------------")
  }
  return(df)
}

test <- tau.fun(apple_df$AAPL.Close,min = 6,max = 10)# <--- Use the Function Here

# -----------------------------------------------------------------------------
# ------------------------ For Loop for Rolling Tests -------------------------
# -----------------------------------------------------------------------------
n <- 10# Window of regression
min <- 1 # Minimum Index
max <- 500 # Maximum index
results <- data.frame()
data <- apple_df$AAPL.Close
for(i in min:max){
  left <- i
  right <- i + n
  res <- tau.fun(data,left,right,window=0)
  results <- rbind(results,res)
  if(i == max - n){ # Break for last n values
    break
  }
}

# -----------------------------------------------------------------------------
# ----------------------------- Plot of Tau and Beta --------------------------
# -----------------------------------------------------------------------------
# Tau p-value vs Beta p-value
x<-c(1:length(results$Min))
ggplot(data = results)+
  geom_line(aes(x=x,y=results$`Regression Coef`),col="red")+
  geom_line(aes(x=x,y=results$`Sum of Difference`),col="blue")+
  labs(
    title = "Rolling Tau vs. Rolling Regression Coefficient",
    x = "Index",
    y = "Coefficient"
  )


# -----------------------------------------------------------------------------
# --------------------- Plot Ensemble, Tau, and Regression Results ------------
# -----------------------------------------------------------------------------
# Put Indexes where both results are the same into a data frame
p_value_df <- data.frame(apple_df$AAPL.Close[min:(max-n)],
                         results$`Null Tau`[min:(max-n)],
                         results$`Null Regression`[min:(max-n)],
                         results$`Tau Direction`[min:(max-n)],
                         results$`Regression Direction`[min:(max-n)])

# ------------------------- Color Code Data -------------------------------------------
x <- c(1:length(p_value_df$AAPL.Close)) # X-values

# Color Group Ensemble
p_value_df$color_group_ensemble <- ifelse(p_value_df$results..Null.Tau. == p_value_df$results..Null.Regression., ifelse(p_value_df$results..Tau.Direction..min..max...n..==p_value_df$results..Regression.Direction..min..max...n..,ifelse(p_value_df$results..Tau.Direction..min..max...n..=="positive","red","blue"),"black"), "black") # Color the data

# Color Group Tau
p_value_df$color_group_tau <- ifelse(p_value_df$results..Null.Tau. == "reject", ifelse(p_value_df$results..Tau.Direction..min..max...n..=="positive","red","blue"), "black")

# Color Group Regression
p_value_df$color_group_reg <- ifelse(p_value_df$results..Null.Regression..min..max...n.. == "reject", ifelse(p_value_df$results..Regression.Direction..min..max...n..=="positive","red","blue"), "black")

# ---------------------------------- Plot Data -------------------------------------
# Plot Ensemble
ggplot(data = p_value_df)+
  geom_line(aes(x=x,y=p_value_df$AAPL.Close),color=p_value_df$color_group_ensemble)+
  labs(
    title = "Ensemble Method Graph where n=10",
    x = "Index",
    y = "Price",
    subtitle = "Red: Upward Trend, Blue: Downward Trend"
  )+
  theme(legend.position = "bottom")

# Plot Tau
ggplot(data = p_value_df)+
  geom_line(aes(x=x,y=p_value_df$AAPL.Close),color=p_value_df$color_group_tau)+
  labs(
    title = "Tau Method Graph where n=10",
    x = "Index",
    y = "Price",
    color = "Color Legend",
    subtitle = "Red: Upward Trend, Blue: Downward Trend"
  )

# Plot Regression
ggplot(data = p_value_df)+
  geom_line(aes(x=x,y=p_value_df$AAPL.Close),color=p_value_df$color_group_reg)+
  labs(
    title = "Regression Method Graph where n=10",
    x = "Index",
    y = "Price",
    subtitle = "Red: Upward Trend, Blue: Downward Trend"
  )

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
