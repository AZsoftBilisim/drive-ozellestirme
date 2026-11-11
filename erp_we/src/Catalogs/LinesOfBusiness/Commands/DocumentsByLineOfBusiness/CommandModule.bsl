#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Ref", CommandParameter);
	OpenForm("Catalog.LinesOfBusiness.Form.ListOfLinkedDocuments",
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window,
					CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion

