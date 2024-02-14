# mql5-backtester
This Expert Advisor attempt to create a Simple Backtester on Metatrader 5 with a MACD EMA strategy, allowing for automated backtesting and optimisation. 

**Strategy**
This is a discretionary startegy that relies on the MACD and EMA as entry signals. 
//----Long Entry----//
1) MACD line crosses above Signal Line and both lines are below the zero line
2) EMA line acts as confirmation indicator where candle must close above EMA line

//----Short Entry----//
1) MACD line crosses below Signal Line and both lines are above the zero line
2) EMA line acts as confirmation indicator where candle must close below EMA line

//----Risk Management----//
ATR based stop loss is used, where the stop loss is 1x ATR below entry price for long trades and 1x ATR above entry price for short trade. A 1:2 risk to reward ratio is used. By default a 2% risk per trade is used 

//----Features----//
