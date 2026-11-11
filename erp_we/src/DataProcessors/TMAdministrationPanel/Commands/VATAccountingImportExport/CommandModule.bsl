
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FullFormName = ?(GeneralPurposeTMServerCall.ValueOfFunctionOption("LocalizationRFService"), 
		"DataProcessor.TMAdministrationPanel.Form.VATAccountingImportExportOfRussianFederation",
		"DataProcessor.TMAdministrationPanel.Form.VATAccountingImportExport");
	
	OpenForm(
		FullFormName,
		New Structure,
		CommandExecuteParameters.Source,
		FullFormName + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
