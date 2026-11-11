#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Document.CommercialProposalForCustomer.ObjectForm",
		Undefined,
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);

EndProcedure

#EndRegion