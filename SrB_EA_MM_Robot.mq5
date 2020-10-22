//+------------------------------------------------------------------+
//|                                              SrB_EA_MM_Robot.mq5 |
//|                                           Sandro Roger Boschetti |
//|                      https://www.linkedin.com/in/sandroboschetti |
//|                           http://lattes.cnpq.br/9930983261299053 |
//|                                                 2020-10-20 20:23 |
//+------------------------------------------------------------------+
#property   copyright "Sandro Roger Boschetti"
#property        link "https://github.com/sandrorb/SrB_MM_robot"
#property     version "0.4"
#property description "Trade Max/Min Setup."
#property description "CAUTION: this is a pre-operational version"
#property description "Intended to be used in 15 minutes timeframe of"
#property description "small index Bovespa (Brasil) from 9am to 12pm"

#include <Trade/Trade.mqh>

CTrade trade;

//Atenção: o horário da B3 para o mercado futuro é de 9h às 18h,
//enquanto o à vista é de 10h às 17h. No entanto, se se operar o
//futuro de índice Bovespa (ex.: win) por uma corretora de fora do
//país, como a Activtrades, há o fuso horário a ser considerado.
//No caso da Activtrades, há uma diferença de 5h e acho que isso
//pode depender da época do ano por conta de horário de verão etc.

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
input int hourBegin =  9;     //Hour to start operations (0 to 24 for non stop)
input int   hourEnd = 12;     //Hour to  stop operations (0 to 24 for non stop)

//Acho que se for B3 deve ser inteiro e não double.
//A ser definido no OnInit()
//input double    lot = 1.00;   //Lots to operate
double    lot = 1.00;   //Lots to operate. Changed in OnInit()

double lotMin;

//low and high prices of the last closed. Buy at low and sell at 
//high or at close of the current candle
double  lowPrice;
double highPrice;

MqlTick lastTick;

//Normalized prices for use in the buy and sell operations.
//PRC = buy (or sell) price, STL = stop loss e TKP = take profit
double PRC;
double STL;
double TKP;

bool isThereOpenPosition = false;
bool isTherePendingOrder = false;

//To be defined at OnInit()
ulong magicNum;

MqlDateTime dt_struct;


//+------------------------------------------------------------------+
//| FUNCTION TO OBTAIN THE MAGIC NUMBER BASED ON TICKER              |
//+------------------------------------------------------------------+
ulong magicNumFactory(){
   char chararray[];
   string name = Symbol();
   StringToUpper(name);
   StringToCharArray(name,chararray,0,6);
   string MagicString;
   for(int i=0;i<6;i++){
      StringAdd(MagicString,(string)chararray[i]);
   }
   
   return (ulong)MagicString;
}


///////////////////////////////////////////////////////////////////////
void test(){
   datetime dtBegin;
   datetime dtEnd;
   MqlDateTime dt, dt2;
   TimeCurrent(dt);
   //SymbolInfoSessionQuote(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, 0, dtBegin, dtEnd);
   SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, 0, dtBegin, dtEnd);
   TimeToStruct(dtBegin, dt);
   TimeToStruct(dtEnd, dt2);
   printf("SrB: o pregão vai de %02d:%02d às %02d:%02d (dias úteis)", dt.hour, dt.min, dt2.hour, dt2.min);
}
///////////////////////////////////////////////////////////////////////


//+------------------------------------------------------------------+
//| OnInit() Routine                                                 |
//+------------------------------------------------------------------+
int OnInit(){

   magicNum = magicNumFactory();
   trade.SetExpertMagicNumber(magicNum);
   Print("SrB: Magic number defined to be: ",magicNum, " for the Symbol: ", Symbol());
   
//--- create a timer with a 1 second period
   EventSetTimer(1);   

    lowPrice = 0.00;
   highPrice = 0.00;
   
   lotMin = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   
   //Trading the minimum lot
   lot = lotMin;
   
   Print("SrB: Symbol is: ", _Symbol, " minimum lot is: ", lotMin, " and the lot been used is: ", lot);
   
   Print("SrB: Operações pela corretora ", AccountInfoString(ACCOUNT_COMPANY));
   
   return(INIT_SUCCEEDED); 
}


//int OnDeInit(){ return(INIT_SUCCEEDED); }


//+------------------------------------------------------------------+
//| THIS IS THE MAIN PART OF THE EA                                  |
//+------------------------------------------------------------------+
void OnTick() {

   MqlDateTime dtAux;
   TimeToStruct(TimeCurrent(),dtAux);
   //---------------------------------------------------
   //Time interval restriction on operations
   if( (dtAux.hour >= hourBegin) && (dtAux.hour < hourEnd) ){
   //---------------------------------------------------

      //Get the low and high price of the last candle closed
      //The "1" argument in the functions iLow and iHigh means last candle closed
       lowPrice = NormalizeDouble( iLow( Symbol(), Period(), 1), _Digits);
      highPrice = NormalizeDouble(iHigh( Symbol(), Period(), 1), _Digits);
   
   //Setting up the Limit Order
      if(!isThereOpenPosition() && !isTherePendingOrder()){
         PRC = NormalizeDouble(lowPrice, _Digits);
         STL = NormalizeDouble(0.00, _Digits); // 0.00 is no stop loss
         TKP = NormalizeDouble(highPrice, _Digits);
         if(!trade.BuyLimit(lot,PRC,_Symbol,STL,TKP,ORDER_TIME_GTC,0,NULL)){
            Print("BuyLimit() method failed. Return code=",trade.ResultRetcode(),
                  ". Code description: ",trade.ResultRetcodeDescription());
         }else{
            Print("BuyLimit() method executed successfully. Return code=",trade.ResultRetcode(),
                  " (",trade.ResultRetcodeDescription(),")");
         }
      } 
      
      //printOnScreen("Time to go: " + secondsRemaining() + " seconds", 0, 35);
      
   }//End of time interval of trading
   
   if(isNewBar()){
      closeAllPendingOrder();
      closeAllPositions();
   }   
   
}//End of OnTick()



//trade.BuyLimit(lot,102000,_Symbol,0.00,0.00,ORDER_TIME_GTC,0,NULL);

void printOnScreen(string msg, int x, int y, string label){
   ObjectCreate(_Symbol,label,OBJ_LABEL,0,0,0);
   ObjectSetString(0,label,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,label,OBJPROP_FONTSIZE,12);
   ObjectSetInteger(0,label,OBJPROP_COLOR,clrAquamarine);
   ObjectSetString(_Symbol, label,OBJPROP_TEXT,0,msg);
   ObjectSetInteger(0,label,OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0,label,OBJPROP_YDISTANCE, y);   
}


void OnTimer(){
   //Comment(TimeCurrent());
   printOnScreen(TimeCurrent(), 0, 15, "Label1");
   printOnScreen("Time to go: " + secondsRemaining() + " seconds", 0, 35, "Label2");
}

int secondsRemaining(){
   datetime duracao = TimeCurrent() - iTime(_Symbol,PERIOD_CURRENT,0);
   uint tempoGrafico = PeriodSeconds(PERIOD_CURRENT);
   return tempoGrafico - duracao;
}


//+------------------------------------------------------------------+
//| CHECK IF THERE IS ANY OPEN POSITION                              |
//+------------------------------------------------------------------+
bool isThereOpenPosition(){

   int o_total = PositionsTotal();
   
   for(int j=o_total-1; j>=0; j--) {
      ulong o_ticket = PositionGetTicket(j);
      PositionSelect(o_ticket);
      string mySymbol = PositionGetSymbol(j);
      ulong  myMagicNum = PositionGetInteger(POSITION_MAGIC);
      
      if(mySymbol == _Symbol && myMagicNum == magicNum){
         return true;
      }
      
   }
   
   return false;

}

//+------------------------------------------------------------------+
//| CLOSE ALL OPEN POSITIONS                                         |
//+------------------------------------------------------------------+
void closeAllPositions(){
   int n_positions = PositionsTotal();
   
   for(int i=n_positions-1; i>=0; i--){
   
      string mySymbol = PositionGetSymbol(i);
      ulong  myMagicNum = PositionGetInteger(POSITION_MAGIC);
      Print("SrB: mySymbol = ", mySymbol, " e myMagicNum = ", myMagicNum);
      
      if(mySymbol == _Symbol && myMagicNum == magicNum){
         trade.PositionClose(mySymbol);
      }
   }
}


//+------------------------------------------------------------------+
//| CHECK IF THERE IS ANY OPEN ORDER                                 |
//+------------------------------------------------------------------+
bool isTherePendingOrder(){

   int o_total = OrdersTotal();
   
   for(int j=o_total-1; j>=0; j--) {
      ulong o_ticket = OrderGetTicket(j);
      OrderSelect(o_ticket);
      string mySymbol = OrderGetString(ORDER_SYMBOL);
      ulong  myMagicNum = OrderGetInteger(ORDER_MAGIC);
      
      if(mySymbol == _Symbol && myMagicNum == magicNum){
         return true;
      }
      
   }
   
   return false;

}


//+------------------------------------------------------------------+
//| CLOSE ALL OPEN ORDERS                                            |
//+------------------------------------------------------------------+
void closeAllPendingOrder(){

   int o_total = OrdersTotal();
   
   for(int j=o_total-1; j>=0; j--) {
      ulong o_ticket = OrderGetTicket(j);
      OrderSelect(o_ticket);
      string mySymbol = OrderGetString(ORDER_SYMBOL);
      ulong  myMagicNum = OrderGetInteger(ORDER_MAGIC);
      
      if(mySymbol == _Symbol && myMagicNum == magicNum){
         trade.OrderDelete(o_ticket);
      }
      
   }

}


bool isNewBar(){
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   //Print(lastbar_time);

//--- if it is the first call of the function
   if(last_time==0)
     {
      //--- set the time and exit
      last_time=lastbar_time;
      return(false);
     }

//--- if the time differs
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
}

