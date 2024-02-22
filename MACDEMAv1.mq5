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
   
  }
//+------------------------------------------------------------------+
