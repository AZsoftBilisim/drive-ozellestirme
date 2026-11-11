&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("BusinessProcess.PriceApproval.ListForm",
	             New Structure("SubjectOf", CommandParameter),
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window);
	
EndProcedure
