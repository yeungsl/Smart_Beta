
risk_free <- 0.02
benchmark <- monthlyReturn(na.approx(getSymbols("^IXIC", auto.assign = F, from = "2006-01-01", to = "2019-01-01")))
weights <- rep(0,ncol(nasdaq_return))
camp.return <- rep(0,length(13:156))


#判断long/short
trend<-function(month){
  if(mean(benchmark[(month-12):(month-1)]) >=0){
    sign <- 1
  }
  else {
    sign <- -1
  }
  return (sign)
}
#i 从第13个月
weights_recorded = matrix(0, nrow=144, ncol=ncol(nasdaq_return))
for(i in 13:156){
  for(j in 1:103){
    if (all(nasdaq_return[(i-12):(i-1),j] == 0)){
      weights[j] <- 0
    }else{
      j_f <- nasdaq_return[(i-12):(i-1),j]-risk_free
      m_f <- benchmark[(i-12):(i-1)]-risk_free
      model <- lm(j_f~m_f-1)
      weights[j]<-lm(j_f~m_f-1)$coefficients
    }
  }
  #get beta
  order.weights <- weights[order(abs(weights))]
  #index of specific beta
  order.index <- order(abs(weights))[94:103]
  #rescale weight
  re.weight <- order.weights[94:103] / sum(order.weights[94:103])
  #re.weight <- (order.weights[94:103] - mean(order.weights[94:103]))/sd(order.weights[94:103])+0.1
  #re.weight <- re.weight/portfolio_risk[i-34]*0.09
  #weights_recorded[i-12, order.index] <- re.weight
  #Get return of beta strategy
  camp.return[i-12]<-sum(trend(i)*nasdaq_return[i,order.index] * re.weight)
}



library(ggplot2)
simple_return_plot <- data.frame(portfolio_return = camp.return, date = index(benchmark[13:156,]),index_return = as.numeric(benchmark[13:156]))

ggplot(simple_return_plot, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "portfolio")) +
  geom_line(aes(y = index_return, color="benchmark")) +
  xlab('data') +
  ylab('simple return') + scale_colour_discrete(name="")

cum_camp <- cumprod(1+camp.return)
cum_bench <- cumprod(1+benchmark[13:156])

cum_return_plot <- data.frame(portfolio_return = cum_camp, date = index(benchmark[13:156,]),index_return = cumprod(1+benchmark[13:156]))

ggplot(cum_return_plot, aes(x=date))+
  geom_line(aes(y = portfolio_return, color = "CAPM")) +
  geom_line(aes(y = cum_bench, color="benchmark")) +
  xlab('Date') +
  ylab('Cumulative return') + scale_colour_discrete(name="")


