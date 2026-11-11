
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormName = "Document.ProductionStage2_2.Form.ProductionStageDispatching";
	FormParameters = New Structure("", );
	
	OpenForm(FormName, FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window, CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
