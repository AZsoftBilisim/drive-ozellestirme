#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then 
		Return; 
	EndIf;
	
	Cancel = ExchangePlans.MasterNode() <> Undefined;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

#EndIf