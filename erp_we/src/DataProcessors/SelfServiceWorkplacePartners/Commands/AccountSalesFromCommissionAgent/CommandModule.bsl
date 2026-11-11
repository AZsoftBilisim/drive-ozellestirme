

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("Document.ConsignmentReportFromCustomer.Form.SelfServiceWorkplaceListForm",
				,
				CommandExecuteParameters.Source,
				CommandExecuteParameters.Uniqueness,
				CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

