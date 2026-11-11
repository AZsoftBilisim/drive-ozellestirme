#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter = New Structure("LineOfBusiness", CommandParameter);
	FormParameters = New Structure("Filter", Filter);
	OpenForm("Catalog.LinesOfBusiness.Form.ListOfLinkedContracts",
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window,
					CommandExecuteParameters.URL);

EndProcedure

#EndRegion
