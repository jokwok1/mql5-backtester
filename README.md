# mql5-backtester
This Expert Advisor attempt to create a Simple Backtester on Metatrader 5 with a MACD EMA strategy, allowing for automated backtesting and optimisation of FOREX strategies. 

**Strategy**
This is a discretionary startegy that relies on the MACD and EMA as entry signals. 
//----Long Entry----//
1) MACD line crosses above Signal Line and both lines are below the zero line
2) EMA line acts as confirmation indicator where candle must close above EMA line
3) If there is a long entry, first check if there are any trades open, if there is a short trade, close short trade and enter new trade. If there is a long trade, this long entry is considered invalid
4) Exit when MACD lines crosses below the signal Line 

//----Short Entry----//
1) MACD line crosses below Signal Line and both lines are above the zero line
2) EMA line acts as confirmation indicator where candle must close below EMA line
3) If there is a short entry, first check if there are any trades open, if there is a long trade, close long trade and enter new trade. If there is a short trade, this short entry is considered invalid
4) Exit when MACD lines crosses above the signal Line 

//----Trade Management----//
1) 2 Trades are entered when entry condition are met. User can choose between Static or Trailing Stop Loss
2) In the static option, a fixed risk to reward was of 2:1 will be used
3) In the trailing option, 1 Trade will be will be entered with a 2:1 risk to reward ratio, while the other trade has no trade profit. When the take profit of the first trade is Hit, the Stop Loss of the second trade will be moved to break even price and a 1x ATR trailing Stop loss will be implemented 

//----Risk Management----//
ATR based stop loss is used, where the stop loss is 1x ATR below entry price for long trades and 1x ATR above entry price for short trade. A 1:2 risk to reward ratio is used. By default a 2% risk per trade is used 

//----Features----//
1) Risk per trade tool: Set max loss per trade in base currency, adapted to work for JPY forex pairs
2) Compounding vs Fixed lot size
3) Variable Stop Loss / Take Profit multiplier
4) Parameters of MACD / EMA can be varied
5) Trade is entered at the start of a new candle

//----Notes----//
1) Trade is entered when a the previous candle closes and the new candle opens. Depending on your broker, the trading window is different from the candle opening time. This may cause an invalid trade entry when market is closed. A timer is added in the EA which can be adjust based on the difference in timing of candle open and trading Open.
2) Trade can be entered immediately after a trade is exited
