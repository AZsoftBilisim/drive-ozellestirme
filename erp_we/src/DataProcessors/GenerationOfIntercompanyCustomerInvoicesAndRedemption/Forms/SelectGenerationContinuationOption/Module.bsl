
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ActionWithTransferPrices = "ExcludeProductsWithoutPrices";
	
EndProcedure

#EndRegion


#Region EventHandlersForTableElementsSelectedSenders

&AtClient
Procedure OK(Command)
	Close(ActionWithTransferPrices);
EndProcedure

#EndRegion
