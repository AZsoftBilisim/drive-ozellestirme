
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters) 

		OpenForm("Document.RegisterAdjustment.Form.ListForm",
			, // Form parametersreferences,
			CommandExecuteParameters.Source,
			CommandExecuteParameters.Uniqueness,
			CommandExecuteParameters.Window);


EndProcedure

#EndRegion
