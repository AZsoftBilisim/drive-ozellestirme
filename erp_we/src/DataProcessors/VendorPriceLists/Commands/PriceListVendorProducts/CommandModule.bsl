
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PartnersProductsClient.OpenSupplierSPriceList(CommandParameter, CommandExecuteParameters);

EndProcedure

#EndRegion