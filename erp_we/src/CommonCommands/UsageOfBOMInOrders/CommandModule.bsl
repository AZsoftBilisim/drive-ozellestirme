
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	FormParameters = New Structure;
	FormParameters.Insert("BillOfMaterials", CommandParameter);
	
	FormName = "Catalog.BillsOfMaterials.Form.BOMUsageInOrders";
	
	OpenForm(FormName,
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window,
					CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
