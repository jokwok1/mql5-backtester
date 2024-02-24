//+------------------------------------------------------------------+
//|                                                MACD EMA Strategy |
//|                                                        Tan Jacky |
//|                                       https://github.com/jokwok1 |
//+------------------------------------------------------------------+
//|                                                  Version Notes 1 |
//| Skeleton of trading Strategy                                     |
//| Fixing risk lots as JPY didn't enter                             |
//| relook the KAMA for more accurate entries                        |
//|                                                                  |
//+------------------------------------------------------------------+
//|                                                    Patch Notes 1 |
//|MACD crosses above signal line when MACD<0, Close>EMA for long    |
//|Opposite for shorts                                               |
//|2x ATR Take Profit, 1x ATR Stop Loss                              |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Tan Jacky"
#property link      "https://www.mql5.com"
#property version   "1.00"

//Include Functions
#include <Trade\Trade.mqh> //Include MQL trade object functions
CTrade   *Trade;           //Declaire Trade as pointer to CTrade class

//Setup Variables
input int                InpMagicNumber  = 2000001;     //Unique identifier for this expert advisor
input string             InpTradeComment = __FILE__;    //Optional comment for trades
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; //Applied price for indicators
input int                MinDelay        = 4;           //Delay in minutes of trade open and candle open

//Global Variables
string          IndicatorMetrics    = "";
int             TicksReceivedCount  = 0; //Counts the number of ticks from oninit function
int             TicksProcessedCount = 0; //Counts the number of ticks proceeded from oninit function based off candle opens only
static datetime TimeLastTickProcessed;   //Stores the last time a tick was processed based off candle opens only

//Store Position Ticket Number
ulong  TicketNumber = 0;
ulong  TicketNumber2 = 0;

// Magic No. for Multiple trades
int Magic1 = 0;
int Magic2 = 0;

//Risk Metrics
input bool   TslCheck          = true;   //Use Trailing Stop Loss?
input bool   RiskCompounding   = false;  //Use Compounded Risk Method?
double       StartingEquity    = 0.0;    //Starting Equity
double       CurrentEquityRisk = 0.0;    //Equity that will be risked per trade
input double MaxLossPrc        = 0.02;   //Percent Risk Per Trade
input double AtrProfitMulti    = 2.0;    //ATR Profit Multiple
input double AtrLossMulti      = 1.0;    //ATR Loss Multiple

//ATR Handle and Variables
int HandleAtr;
int AtrPeriod  = 14;

//MACD Handle and Variables
input bool   C1_Check_Conf = true;   //|--- MACD Check ---| 
int HandleMacd;
input int    MacdFast      = 12;
input int    MacdSlow      = 26;
input int    MacdSignal    = 9;
// C1 Buffer Numbers 
const string C1Name        = "MACD"; 
bool         C1_L_Exit     = false;    
bool         C1_S_Exit     = false; 

//EMA Handle and Variables
input bool   C2_Check_Conf = true;   //|--- C2 CHECK ---| 
int HandleEma;
input int    EmaPeriod     = 20;
bool         C2_L_Check    = false;    
bool         C2_S_Check    = false;  
const string C2Name        = "EMA"; 


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //Declare magic number for all trades
   Trade = new CTrade();

   //Store starting equity onInit
   StartingEquity  = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Set up handle for ATR indicator on the initialisation of expert
   HandleAtr = iATR(Symbol(),Period(),AtrPeriod);
   Print("Handle for ATR /", Symbol()," / ", EnumToString(Period()),"successfully created");
   
   //Set up handle for macd indicator on the oninit
   HandleMacd = iMACD(Symbol(),Period(),MacdFast,MacdSlow,MacdSignal,InpAppliedPrice); 
   Print("Handle for Macd /", Symbol()," / ", EnumToString(Period()),"successfully created");
   
   //Set up handle for EMA indicator on the oninit
   HandleEma = iMA(Symbol(),Period(),EmaPeriod,0,MODE_EMA,InpAppliedPrice);
   Print("Handle for EMA /", Symbol()," / ", EnumToString(Period()),"successfully created");
   
   return(INIT_SUCCEEDED);
   
   Magic1 = InpMagicNumber;
   Magic2 = Magic1 + 1;

  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //Remove indicator handle from Metatrader Cache
   IndicatorRelease(HandleAtr);
   IndicatorRelease(HandleMacd);
   IndicatorRelease(HandleEma);
   Print("Handle released");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Counts the number of ticks received  
   TicksReceivedCount++; 
   
   //Checks for new candle
   bool IsNewCandle = false;
   if(TimeLastTickProcessed != iTime(Symbol(),Period(),0))
   {
      IsNewCandle = true;
      TimeLastTickProcessed=iTime(Symbol(),Period(),0);
   }
   
   //If there is a new candle, process any trades
   if(IsNewCandle == true)
   {
      //Counts the number of ticks processed
      TicksProcessedCount++;

      //Check if position is still open. If not open, return 0.
      if (!PositionSelectByTicket(TicketNumber) && !PositionSelectByTicket(TicketNumber2)) {
         TicketNumber = 0;
         TicketNumber2 = 0;
      } 
   
      //Initiate String for indicatorMetrics Variable. This will reset variable each time OnTick function runs.
      IndicatorMetrics ="";  
      StringConcatenate(IndicatorMetrics,Symbol()," | Last Processed: ",TimeLastTickProcessed," | Open Ticket: ", TicketNumber);

      //Money Management - ATR
      double CurrentAtr = GetATRValue(); //Gets ATR value double using custom function - convert double to string as per symbol digits
      StringConcatenate(IndicatorMetrics, IndicatorMetrics, " | ATR: ", CurrentAtr);

      //Strategy Trigger - MACD
      string OpenSignalMacd = GetMacdOpenSignal(); //Variable will return Long or Short Bias only on a trigger/cross event 
      StringConcatenate(IndicatorMetrics, IndicatorMetrics, " | MACD Bias: ", OpenSignalMacd); //Concatenate indicator values to output comment for user   
   
      //Strategy Filter - EMA
      string OpenSignalEma = GetEmaOpenSignal(); //Variable will return long or short bias if close is above or below EMA.
      StringConcatenate(IndicatorMetrics, IndicatorMetrics, " | EMA Bias: ", OpenSignalEma); //Concatenate indicator values to output comment for user
   
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Custom function                                                  |
//+------------------------------------------------------------------+
//Custom Function to get ATR value
double GetATRValue()
{
   //Set symbol string and indicator buffers
   string    CurrentSymbol   = Symbol();
   const int StartCandle     = 0;
   const int RequiredCandles = 3; //How many candles are required to be stored in Expert 

   //Indicator Variables and Buffers
   const int IndexAtr        = 0; //ATR Value
   double    BufferAtr[];         //[prior,current confirmed,not confirmed] 

   //Populate buffers for ATR Value; check errors
   bool FillAtr = CopyBuffer(HandleAtr,IndexAtr,StartCandle,RequiredCandles,BufferAtr); //Copy buffer uses oldest as 0 (reversed)
   if(FillAtr==false)return(0);

   //Find ATR Value for Candle '1' Only
   double CurrentAtr   = NormalizeDouble(BufferAtr[1],5);

   //Return ATR Value
   return(CurrentAtr);
}

//Custom Function to get MACD signals
string GetMacdOpenSignal()
{
   //Set symbol string and indicator buffers
   string    CurrentSymbol    = Symbol();
   const int StartCandle      = 0;
   const int RequiredCandles  = 3; //How many candles are required to be stored in Expert 
   
   //Indicator Variables and Buffers
   const int IndexMacd        = 0; //Macd Line
   const int IndexSignal      = 1; //Signal Line
   double    BufferMacd[];         //[prior,current confirmed,not confirmed]    
   double    BufferSignal[];       //[prior,current confirmed,not confirmed]       
   
   //Define Macd and Signal lines, from not confirmed candle 0, for 3 candles, and store results 
   bool      FillMacd   = CopyBuffer(HandleMacd,IndexMacd,  StartCandle,RequiredCandles,BufferMacd);
   bool      FillSignal = CopyBuffer(HandleMacd,IndexSignal,StartCandle,RequiredCandles,BufferSignal);
   if(FillMacd==false || FillSignal==false) 
      return "Buffer Not Full MACD"; // If buffers are not completely filled, return to end onTick

   //Find required Macd signal lines and normalize to 10 places to prevent rounding errors in crossovers
   double    CurrentMacd   = NormalizeDouble(BufferMacd[1],10);
   double    CurrentSignal = NormalizeDouble(BufferSignal[1],10);
   double    PriorMacd     = NormalizeDouble(BufferMacd[0],10);
   double    PriorSignal   = NormalizeDouble(BufferSignal[0],10);
   double    PriorClose = NormalizeDouble(iClose(Symbol(),Period(),2), 10);
   double    CurrentClose = NormalizeDouble(iClose(Symbol(),Period(),1), 10);
 
   // MAIN ERROR OF OCR is that they are reentering trades at the same time
   //Submit Macd Long and Short Trades
   //If MACD cross over Signal Line and cross occurs below 0 line - Long                                    // Code for one candle rule
   if((PriorMacd <= PriorSignal && CurrentMacd > CurrentSignal && CurrentMacd < 0 && CurrentSignal < 0) || (OCRMacd <= OCRSignal && PriorMacd > PriorSignal && PriorMacd < 0 && PriorSignal < 0 && CurrentClose <= PriorClose))
      return   "Long";
   //If MACD cross under Signal Line and cross occurs above 0 line- Short
   else if((PriorMacd >= PriorSignal && CurrentMacd < CurrentSignal && CurrentMacd > 0 && CurrentSignal > 0) || (OCRMacd >= OCRSignal && PriorMacd < PriorSignal && PriorMacd > 0 && PriorSignal > 0 && CurrentClose >= PriorClose))
      return   "Short";
   else
   //If no cross of MACD and Signal Line - No Trades
      return   "No Trade";
}

//Custom function that returns long and short signals based off EMA and Close price.
string GetEmaOpenSignal()
{
   //Set symbol string and indicator buffers
   string    CurrentSymbol    = Symbol();
   const int StartCandle      = 0;
   const int RequiredCandles  = 2; //How many candles are required to be stored in Expert 
   
   //Indicator Variables and Buffers
   const int IndexEma         = 0; //EMA Line
   double    BufferEma [];         //[current confirmed,not confirmed]    

   //Define EMA, from not confirmed candle 0, for 2 candles, and store results 
   bool      FillEma   = CopyBuffer(HandleEma,IndexEma,  StartCandle,RequiredCandles,BufferEma);
   if(FillEma==false) 
      return "Buffer Not Full Ema"; //If buffers are not completely filled, return to end onTick

   //Gets the current confirmed EMA value
   double CurrentEma   = NormalizeDouble(BufferEma[0],10);
   double CurrentClose = NormalizeDouble(iClose(Symbol(),Period(),1), 10);

   //Submit Ema Long and Short Trades
   if(CurrentClose > CurrentEma)
      return("Long");
   else if (CurrentClose < CurrentEma)
      return("Short");
   else
      return("No Trade");
}