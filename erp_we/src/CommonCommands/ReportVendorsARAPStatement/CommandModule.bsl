#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("VariantKey", "SettlementsWithSuppliersBasic");

	OpenForm("Report.VendorsARAPStatement.Form", 
			FormParameters, 
			CommandExecuteParameters.Source, 
			CommandExecuteParameters.Uniqueness, 
			CommandExecuteParameters.Window, 
			CommandExecuteParameters.URL);
EndProcedure

#EndRegion 