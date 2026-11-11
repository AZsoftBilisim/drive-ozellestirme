#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the code of the payment type at the terminal
// 
// 
// Returns:
//  Map
//                  
Function PaymentTypeCodeAtTerminal() Export
	
	Result = New Map(); 
	Result.Insert(PredefinedValue("Enum.PaymentKindOnTerminal.Map")  , 0);
	Result.Insert(PredefinedValue("Enum.PaymentKindOnTerminal.FPSQR")  , 1);
	Result.Insert(PredefinedValue("Enum.PaymentKindOnTerminal.PayQR"), 2);
	Return Result;
	
EndFunction

// Returns the type of payment at the terminal by code.
// 
// 
// Returns:
//  Map
//
Function TypeOfPaymentAtTerminalByCode() Export
	
	Result = New Map();   
	Result.Insert(0, PredefinedValue("Enum.PaymentKindOnTerminal.Map"));
	Result.Insert(1, PredefinedValue("Enum.PaymentKindOnTerminal.FPSQR"));
	Result.Insert(2, PredefinedValue("Enum.PaymentKindOnTerminal.PayQR"));
	Return Result;
	
EndFunction

#EndRegion


#EndIf