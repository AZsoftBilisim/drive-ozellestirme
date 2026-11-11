

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.CustomerShoppingCart",
	 			,
				CommandExecuteParameters.Source, 
				CommandExecuteParameters.Uniqueness,
				CommandExecuteParameters.Window);
				
EndProcedure

#EndRegion

