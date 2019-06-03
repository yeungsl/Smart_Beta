# Smart_Beta
Implemented three strategies to Rebalance monthly portfolio in Nasdaq Index

# Description
This project used three startegies to creat monthly rebalancing protfolio by assigning different monthly weights to stocks selected by the strategies. The benchmark is the Nasdaq Index from 2007 - 2018. Three strategies are based on:

1. __Momentum factor selection__ : we get the momentum factors of all the stocks in the Nasdaq and assign weights according to the momentums of each stocks.
2. __CAPM prediction__ : we ran CAPM model on indiviual stocks to select the ones that are most related to the Market and assigned weights on those stocks
3. __LSTM prediction__ : we ran a LSTM(long term short term neural network) model on the stock data and try to prediction the future return of the stocks. Then assign weights based on the predicted returns.

Below is a graph for cumulative returns of those strategies.
![results](https://github.com/yeungsl/Smart_Beta/blob/master/results.png)
The detailed report can be found in this [link](https://drive.google.com/file/d/1av_TdTz6Q1Fd3Cv25wKCEthJWZV4uJKa/view?usp=sharing)

# Usage

* `Samrt_beta.R` contains codes about momentum factor are all the calculation about graph and restuls
* `Beta-copy.R` contains codes about CAPM strategy
* `LSTM_stock_price_prediciont.ipyng` contains python codes of LSTM network implemented with Tensorflow

# Requirements

* R
* quantmod
* Tensorflow 2.0
* python 3.6
* pandas
