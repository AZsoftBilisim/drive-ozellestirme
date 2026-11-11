

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer.ListForm",
	             New Structure("SubjectOf", CommandParameter),
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
