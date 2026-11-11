
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	OpenForm("Document.PaymentRequest.Form.FormOfListOfRequestsForApproval",,,,
		CommandExecuteParameters.Window);
	
EndProcedure
