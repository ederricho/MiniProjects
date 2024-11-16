# Simple Stock Algorithm

The Simple Stock Algorithm is a prediction algorithm utilizing the three-day moving average and a coefficient $\omega$ multiplied by the three-day moving standard deviation. The equation is: $$p(t) = \mu_{3}(t)+\omega\sigma_{3}(t)$$. Using gradient descent to optimize the coefficient $\omega$, we will be able to minimize the mean squared error of the residuals of the model. The graph below shows the results:
![](AdditionalFiles/ssa_vs_price.png)

# Chosing the Equation
The objective of this project is to choose a simple, easy to emplement algorithm that only needs the input of the stock price. There are several several other possible models that could have been used, however a model based on the moving average allows for a predicted price that will remain relatively close to the previous price. By doing so, we will create a sort of 'smoothing' function. This will also aide in resistance of spikes and dips in the price that do not reflect the overall trend.  

# Optimizing the coefficient $\omega$
To optimize $\omega$ we use the gradient descent algorithm. Gradient descent will ###.

# Insights and Conclusions
Prediction Graph
While the model does an excelent job in detecting trends and ignoring sudden price changes that do not reflec these trends, the prediction capabilities of the algorithm leave much to be desired **(see graph above)**. The mean squared error of the algrithm with $\omega = 1$ was #### while the mean squared error of the algorithm with the optimized $\omega$ was ####. To create a better model, it would be necessary to observe the error of the SSA vs. the price and run a machine learning algorithm perhaps a **gradient booster** algorithm to predict the error. This will perhaps yield a better mean squared error and a more generalized model. **This could also lead to overfitting, especially if outliers are not handled correctly.**</br>
Look below to see a table of the price, SSA prediction, and the error.
Table Here
