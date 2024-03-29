---
title: "Smart_beta"
author: "Sailung Yeung"
date: "4/16/2019"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Dataset parsing



```{r}
library(quantmod)

##Data was pull from website on 4/16/2019



nasdaq_1 = c("AAL","AAPL","ADBE","ADI","ADP","ADSK","AKAM","ALGN","ALTR","ALXN","AMAT","AMD","AMGN","AMZN","ASML","ATVI","AVGO","BBBY","BIDU","BIIB","BKNG","BMRN","CDNS","CELG","CERN","CHKP","CHRW","CHTR","CMCSA","COST","CSCO","CSX","CTAS","CTRP","CTSH","CTXS","DISCA","DISCK","DISH","DLTR","DTV","EA","EBAY","ENDP","EQIX","EXPD","EXPE","FAST","FB","FISV","FOX","FOXA","GILD","GOOG","GOOGL","GRMN","HAS","HOLX","HSIC","IDXX","ILMN","INCY","INTC","INTU","ISRG","JBHT","JD","KHC","KLAC","LBTYA","LBTYK","LILA","LILAK","LRCX","LULU","MAR","MAT","MCHP","MDLZ","MELI","MNST","MSFT","MU","MXIM","MYL","NCLH","NFLX","NTAP","NTES","NVDA","NXPI","ORLY","PAYX","PCAR","PEP","PYPL","QCOM","QRTEA","REGN","ROST","SBAC","SBUX","SIRI","SNPS","SRCL","STX","SWKS","SYMC","TMUS","TRIP","TSCO","TSLA","TTWO","TXN","UAL","ULTA","VIAB","VOD","VRSK","VRTX","WBA","WDAY","WDC","WLTW","WYNN","XEL","XLNX","XRAY","VRSN","VIA","BATRA","BATRK","FFIV","LSXMB","PRGO","ORCL","BMC","DELL","GOLD","FOSL","NUAN","SHLDQ","FSLR","TEVA","INFY","FLEX","MRVL","FLIR","NIHD","QGEN","URBN","TLAB","AMLN","LAMR","LEAP","FMCN","JNPR","IAC","RYAAY","STLD","LOGI","PDCO","ERIC","PTEN","CMVT","LNCR","CHIR")
nasdaq <- nasdaq_1

nasdaq_2018 = c('ATVI','ADBE','AMD','ALXN','ALGN','GOOG','GOOGL','AMZN','AAL','AMGN','ADI','AAPL','AMAT','ASML','ADSK','ADP','BIDU','BIIB','BMRN','BKNG','AVGO','CDNS','CELG','CERN','CHTR','CHKP','CTAS','CSCO','CTXS','CTSH','CMCSA','COST','CSX','CTRP','DLTR','EBAY','EA','EXPE','FB','FAST','FISV','FOX','FOXA','GILD','HAS','HSIC','IDXX','ILMN','INCY','INTC','INTU','ISRG','JBHT','JD','KLAC','LRCX','LBTYA','LBTYK','LULU','MAR','MXIM','MELI','MCHP','MU','MSFT','MDLZ','MNST','MYL','NTAP','NTES','NFLX','NVDA','NXPI','ORLY','PCAR','PAYX','PYPL','PEP','QCOM','REGN','ROST','SIRI','SWKS','SBUX','SYMC','SNPS','TMUS','TTWO','TSLA','TXN','KHC','ULTA','UAL','VRSN','VRSK','VRTX','WBA','WDC','WLTW','WDAY','WYNN','XEL','XLNX')
nasdaq <- nasdaq_2018



## parse data from Yahoo finance with one stock symbol
daily_nas <- data.frame()
for (i in 1:length(nasdaq)){
  raw_data <- getSymbols(nasdaq[i], auto.assign = F, from = "2006-01-01", to = "2019-01-01")
  daily_nas <- cbind(daily_nas, dailyReturn(raw_data))
}
daily_nas <- replace(daily_nas, is.na(daily_nas), 0)
write.csv(daily_nas, file = "./nasdaq.csv")
## get monthly return
#monthlyReturn(GS)
## export monthly return data


## parse close price from yahoo finance with all stock symbols in Nasdaq 100
## there maybe NA values because at that time the stock has not been released yet
nasdaq_return <- data.frame()
for (i in 1:length(nasdaq)){
  raw_data <- getSymbols(nasdaq[i], auto.assign = F, from = "2006-01-01", to = "2019-01-01")
  nasdaq_return <- cbind(nasdaq_return, monthlyReturn(raw_data))
}
colnames(nasdaq_return) <- nasdaq
nasdaq_return <- na.fill(nasdaq_return, 0)
dim(nasdaq_return)
write.csv(cumprod(1+nasdaq_return), file = "./nasdaq_return.csv")
### data adjustment has to be total of 155 rows
library(lubridate)
row_remove = c()
for (rows in 1:(nrow(nasdaq_return)-1)){
  if (month(index(nasdaq_return)[rows]) == month(index(nasdaq_return)[rows+1]))
    {
    nasdaq_return[(rows+1), ] <- apply(nasdaq_return[rows:(rows+1),], 2, sum)
    row_remove <- c(rows, row_remove)
  }
}
nasdaq_return <- nasdaq_return[-row_remove]
dim(nasdaq_return)
```


## Strategy 1: Rebalancing according to empirical data
1. For each stock’s monthly return calculate the covariance matrix
2. Assign weights according to the covariance matrix

```{r}
## calculate the optimal weight to each stock, according to 12-month return
 momentum_cal <- function(r){
   mom <- rep(0, length(r)-11)
  for(i in 12:length(r)){
    monthly_momentum <- as.numeric(r[i-1])/as.numeric(r[i-11]) - 1
    if (is.na(monthly_momentum)){
      monthly_momentum <- 0
    }
    if (is.infinite(monthly_momentum)){
      monthly_momentum <- 0
    }
    mom[i-11] <- monthly_momentum
  }
   return(mom)
 }

nasdaq_momentum <- apply(nasdaq_return, 2, momentum_cal)

## calcualte weights
weight_cal <- function(m){
  return(m/sum(m))
}

weights <- t(apply(nasdaq_momentum, 1, weight_cal))
dim(weights)

## calculate annualized covariance matrix, because same time horizon for 12-month momentum
portfolio_risk <- rep(0, nrow(nasdaq_return) - 36 + 1)
for (i in 36: nrow(nasdaq_return)){
  r <- nasdaq_return[(i-35):i, ]
  cov_mat <- cov(r)*(nrow(nasdaq_return)-1)/nrow(nasdaq_return) * 12
  ## remove NA values
  cov_mat <- replace(cov_mat,is.na(cov_mat), 0)
  weight <- t(as.matrix(as.numeric(weights[i - 11,])))
  portfolio_risk[i-35] <- weight %*% cov_mat %*% t(weight)
}

## sacle to 1% risk
scale_weight <- function(w, c){
  return(w/portfolio_risk * c)
}
final_port<- apply(weights[25:nrow(weights),], 2, scale_weight, c=0.05)

## calculate portfolio return
port_return <- rep(0, nrow(final_port))
for (i in 36: nrow(nasdaq_return)){
  port_return[i-35] <- sum(final_port[i-35,] * nasdaq_return[i,])
}

## benchmark
benchmark <- monthlyReturn(na.approx(getSymbols("^IXIC", auto.assign = F, from = "2006-01-01", to = "2019-01-01")))
dim(benchmark)
library(ggplot2)
simple_return_plot <- data.frame(portfolio_return = port_return, date = index(benchmark[36:nrow(benchmark),]),index_return = as.numeric(benchmark[36:nrow(benchmark)]))

## simple return comparison
ggplot(simple_return_plot, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "portfolio")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('data') +
  ylab('simple return') + scale_colour_discrete(name="")

## cumulative return comparison
cum_port <- cumprod(1+port_return)
cum_bench <- cumprod(1+benchmark[36:nrow(benchmark)])

cum_return_plot <- data.frame(portfolio_return = cum_port, date = index(benchmark[36:nrow(benchmark),]),index_return = cum_bench)
                              

ggplot(cum_return_plot, aes(x=date))+
  geom_line(aes(y = cum_port, color = "Momentum")) +
  geom_line(aes(y = cum_bench, color="Benchmark")) +
  #geom_line(aes(y = capm_return, color="CAMP"))+
  xlab('Date') +
  ylab('Cumulative return') + scale_colour_discrete(name="")
```

## Strategy 1 MK-II
1. Order all the stock(Max momentum, Min variance) only choose the subset of 100 stocks
2. Scale according to covariance matrix
```{r}
number_of_stock <- 10

select_sym <- function(m,amount){
  w <- rep(0, length(m))
  ordered_index <- order(m, decreasing = TRUE)
  w[ordered_index[1:amount]] <- m[ordered_index[1:amount]]
  return(w)
}

selected_mom <- t(apply(nasdaq_momentum, 1, select_sym, amount = number_of_stock))

selected_weight_cal <- function(w) {
  w <- replace(w, which(w==0), NA)
  w <- w/sum(w, na.rm = TRUE)
  #w <- (w - mean(w, na.rm = TRUE))/sd(w, na.rm = TRUE) +0.1
  return(replace(w, is.na(w), 0))
}

selected_weight <- t(apply(selected_mom, 1, selected_weight_cal))

selected_port<- apply(selected_weight[25:nrow(selected_weight),], 2, scale_weight, c=0.05)

selected_port_return <- rep(0, nrow(selected_port))
for (i in 36: nrow(nasdaq_return)){
  selected_port_return[i-35] <- sum(selected_port[i-35,] * nasdaq_return[i,])
}

library(ggplot2)
simple_return_plot_2 <- data.frame(portfolio_return = port_return, 
                                 date = index(benchmark[36:nrow(benchmark),]),
                                 index_return = as.numeric(benchmark[36:nrow(benchmark)]),
                                 selected_return = selected_port_return)
## simple return comparison
ggplot(simple_return_plot_2, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "portfolio")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  geom_line(aes(y = selected_return, color="selected"))+
  xlab('data') +
  ylab('simple return') + scale_colour_discrete(name="")
  
  
## cumulative return comparison
cum_selected <- cumprod(1+ selected_port_return)
cum_return_plot_2 <- data.frame(date = index(benchmark[36:nrow(benchmark),]),
                              bench_return = cumprod(1+benchmark[36:nrow(benchmark)]),
                              selected_return = cum_selected)

ggplot(cum_return_plot_2, aes(x=date))+
  #geom_line(aes(y = portfolio_return, color = "portfolio")) +
  geom_line(aes(y = monthly.returns, color="benchmark")) +
  geom_line(aes(y = selected_return, color="selected"))+
  xlab('data') +
  ylab('cumulative return') + scale_colour_discrete(name="")
```



```{r}
cum_port
```


## Trying to build weights from LSTM prediction

```{r}
LSTM_returns <- read.table("./weights.txt", header = FALSE, sep = ",")
dim(LSTM_returns)
nrow(daily_nas)
nrow(daily_nas) - dim(LSTM_returns)[1]
length(2045:3271)

LSTM_xts <- reclass(LSTM_returns[,-168], daily_nas[2045:3271])
dim(LSTM_xts)
LSTM_xts[,2]
library(xts)
return_cal <- function(x){
  return(prod(1+x) -1 )
}
monthly_LSTM <- matrix(0, nrow = 59, ncol = ncol(LSTM_xts))
for(i in 1:ncol(LSTM_xts)){
  monthly_LSTM[,i] <- apply.monthly(LSTM_xts[,i], return_cal)
}

weight_selection <- function(x){
  weights <- 2*(x - min(x))/(max(x)- min(x)) - 1
  return(weights/sum(weights))
}

LSTM_weights <- t(apply(monthly_LSTM, 1, weight_selection))

LSTM_port_return <- rep(0,nrow(LSTM_weights))
for (i in 98:156){
  LSTM_port_return[i-97] <- sum(nasdaq_return[i, ] * LSTM_weights[i-97,])
}

LSTM_port_return <- replace(LSTM_port_return, is.na(LSTM_port_return), 0)

library(ggplot2)
simple_return_plot_lstm <- data.frame(portfolio_return = LSTM_port_return, 
                                 date = index(benchmark[98:nrow(benchmark),]),
                                 index_return = as.numeric(benchmark[98:nrow(benchmark)])
                                 )
## simple return comparison
ggplot(simple_return_plot_lstm, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "portfolio")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('data') +
  ylab('simple return') + scale_colour_discrete(name="")

cum_lstm <- cumprod(1+ LSTM_port_return)
cum_return_plot_lstm <- data.frame(portfolio_return = cum_lstm, 
                              date = index(benchmark[98:nrow(benchmark),]),
                              index_return = cumprod(1+as.numeric(benchmark[98:nrow(benchmark)]))
                              )

ggplot(cum_return_plot_lstm, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "portfolio")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('data') +
  ylab('cumulative return') + scale_colour_discrete(name="")
```

```{r}
cum_return_plot_lstm <- data.frame(lstm_return = cumprod(1+ LSTM_port_return_103[12:59]), 
                              date = index(benchmark[109:nrow(benchmark),]),
                              index_return = cumprod(1+as.numeric(benchmark[109:nrow(benchmark)])),
                              camp_return = cumprod(1+camp.return[97:144]),
                              momentum_return = cumprod(1+port_return[74:121])
                              )

ggplot(cum_return_plot_lstm, aes(x=date))+
  geom_line(aes(y = lstm_return, color = "LSTM")) +
  geom_line(aes(y = index_return, color="Benchmark")) +
  geom_line(aes(y = camp_return, color="CAPM"))+
  geom_line(aes(y = momentum_return, color="Momentum"))+
  xlab('Date') +
  ylab('Cumulative return') + scale_colour_discrete(name="")
```

```{r}
LSTM_103 <- read.table("./weights_103.txt", header = FALSE, sep = ",")
dim(LSTM_103)
nrow(daily_nas)
nrow(daily_nas) - dim(LSTM_returns)[1]
length(2045:3271)
```



```{r}
LSTM_xts_103 <- reclass(LSTM_103, daily_nas[2045:3271])
dim(LSTM_xts_103)
library(xts)
return_cal <- function(x){
  return(prod(1+x) -1 )
}
monthly_LSTM_103 <- matrix(0, nrow = 59, ncol = ncol(LSTM_xts_103))
for(i in 1:ncol(LSTM_xts_103)){
  monthly_LSTM_103[,i] <- apply.monthly(LSTM_xts_103[,i], return_cal)
}

weight_selection <- function(x){
  weights <- 2*(x - min(x))/(max(x)- min(x)) - 1
  return(weights/sum(weights))
}

LSTM_weights_103 <- t(apply(monthly_LSTM_103, 1, weight_selection))

LSTM_port_return_103 <- rep(0,nrow(LSTM_weights_103))
for (i in 98:156){
  LSTM_port_return_103[i-97] <- sum(nasdaq_return[i, ] * LSTM_weights_103[i-97,])
}

LSTM_port_return_103 <- replace(LSTM_port_return_103, is.na(LSTM_port_return_103), 0)

cum_return_plot_lstm <- data.frame(portfolio_return = cumprod(1+ LSTM_port_return_103[12:59]), 
                              date = index(benchmark[109:nrow(benchmark),]),
                              index_return = cumprod(1+as.numeric(benchmark[109:nrow(benchmark)]))
                              )

ggplot(cum_return_plot_lstm, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "LSTM")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('Date') +
  ylab('Cumulative return') + scale_colour_discrete(name="")
```


```{r}
install.packages("fTrading")
library("fTrading")
momentum.return <- port_return
momentum.cum <- cumprod(port_return)
lstm.return <- LSTM_port_return_103  
lstm.cum <- cumprod(LSTM_port_return_103)     
camp.cum <- cum_camp
camp.return
max.drawdown <- function(cum.return){
  return(maxDrawDown(cum.return))
}
std <- function(sim.return){
  return(var(sim.return))
}
max.drawdown(momentum.return)
max.drawdown(camp.return)
max.drawdown(lstm.return[12:59])
max.drawdown(benchmark[36:156])
max.drawdown(benchmark[13:156])
max.drawdown(benchmark[109:156])
std(momentum.return[12:59])
std(camp.return)
std(lstm.return)
std(benchmark[36:156])
std(benchmark[13:156])
std(benchmark[109:156])


ann <- function(r){
  years <- round(length(r)/12)
  return(prod(1+r)^(1/years)-1)
}

ann(momentum.return)
ann(camp.return)
ann(lstm.return[12:59])
ann(benchmark[36:156])
ann(benchmark[13:156])
ann(benchmark[109:156])


max.drawdown(momentum.return[74:121])
std(momentum.return[74:121])
ann(momentum.return[74:121])
max.drawdown(camp.return[97:144])
std(camp.return[97:144])
ann(camp.return[97:144])


```

## K-fold corss validation
```{r}
K_fold_1 <- read.table("./weights(0).txt", header = FALSE, sep = ",")
K_fold_2 <- read.table("./weights(1).txt", header = FALSE, sep = ",")
K_fold_3 <- read.table("./weights(2).txt", header = FALSE, sep = ",")

benchmark <- monthlyReturn(na.approx(getSymbols("^IXIC", auto.assign = F, from = "2006-01-01", to = "2019-01-01")))
dim(benchmark)

nrow(daily_nas)

return_1 <- reclass(K_fold_1, daily_nas[80:1089])
return_2 <- reclass(K_fold_2, daily_nas[1169:2178])
return_3 <- reclass(K_fold_3, daily_nas[2262:3271])
dim(return_1)
dim(return_2)
dim(return_3)
```


```{r}
month_return_1 <- matrix(0, nrow = 49, ncol = 103)
month_return_2 <- matrix(0, nrow = 49, ncol = 103)
month_return_3 <- matrix(0, nrow = 49, ncol = 103)
for(i in 1:ncol(return_1)){
  month_return_1[,i] <- apply.monthly(return_1[,i], return_cal)
  month_return_2[,i] <- apply.monthly(return_2[,i], return_cal)
  month_return_3[,i] <- apply.monthly(return_3[,i], return_cal)
}

month_weights_1 <- t(apply(month_return_1, 1, weight_selection))
month_weights_2 <- t(apply(month_return_2, 1, weight_selection))
month_weights_3 <- t(apply(month_return_3, 1, weight_selection))

LSTM_CV_return_1 <- rep(0,nrow(month_weights_1))
LSTM_CV_return_2 <- rep(0,nrow(month_weights_2))
LSTM_CV_return_3 <- rep(0,nrow(month_weights_3))

## weight 1 2006-4 to 2010-4
for (i in 4:52){
  LSTM_CV_return_1[i-3] <- sum(nasdaq_return[i, ] * month_weights_1[i-3,])
}

## weight 2 2010-8 to 2014-8
for (i in 56:104){
  LSTM_CV_return_2[i-55] <- sum(nasdaq_return[i, ] * month_weights_2[i-55,])
}

## weight 3 2014-12 to 2018-12
for (i in 108:156){
  LSTM_CV_return_3[i-107] <- sum(nasdaq_return[i, ] * month_weights_3[i-107,])
}

library(ggplot2)
library(gridExtra)
cv_plot1 <- data.frame(portfolio_return = cumprod(1+ LSTM_CV_return_1), 
                              date = index(benchmark[4:52]),
                              index_return = cumprod(1+as.numeric(benchmark[4:52]))
                              )

p1 <- ggplot(cv_plot1, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "LSTM")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('Date') +
  ylab('Cumulative return') + scale_colour_discrete(name="") + ggtitle("2006 - 2010")

cv_plot2 <- data.frame(portfolio_return = cumprod(1+ LSTM_CV_return_2), 
                              date = index(benchmark[56:104]),
                              index_return = cumprod(1+as.numeric(benchmark[56:104]))
                              )

p2 <- ggplot(cv_plot2, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "LSTM")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('Date') +
  ylab('Cumulative return') + scale_colour_discrete(name="") + ggtitle("2010 - 2014")

cv_plot3 <- data.frame(portfolio_return = cumprod(1+ LSTM_CV_return_3), 
                              date = index(benchmark[108:156]),
                              index_return = cumprod(1+as.numeric(benchmark[108:156]))
                              )

p3 <- ggplot(cv_plot3, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "LSTM")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('Date') +
  ylab('Cumulative return') + scale_colour_discrete(name="") + ggtitle("2014 - 2018")

grid.arrange(p1,p2,p3)
```

```{r}
p3
```

