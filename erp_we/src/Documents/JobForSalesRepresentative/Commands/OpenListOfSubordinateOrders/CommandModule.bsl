#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure();
	FormParameters.Insert("Filter", New Structure("DocumentBasis", CommandParameter));
	
	OpenForm("Document.SalesOrder.Form.ListForm",
				FormParameters,
				CommandExecuteParameters.Source,
				CommandExecuteParameters.Uniqueness,
				CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
