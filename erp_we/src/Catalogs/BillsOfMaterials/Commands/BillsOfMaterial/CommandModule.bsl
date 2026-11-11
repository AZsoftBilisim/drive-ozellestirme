
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Product", CommandParameter);
	
	OpenForm("Catalog.BillsOfMaterials.ListForm", 
					FormParameters, 
					CommandExecuteParameters.Source, 
					CommandExecuteParameters.Uniqueness, 
					CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion