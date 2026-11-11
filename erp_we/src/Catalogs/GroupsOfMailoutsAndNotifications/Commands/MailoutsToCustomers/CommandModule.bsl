
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter          = New Structure("GroupOfMailoutsAndNotifications", CommandParameter);
	FormParameters = New Structure("Filter", Filter);
	
	OpenForm("Document.MailoutToCustomers.Form.ListForm",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window,
	             CommandExecuteParameters.URL);

EndProcedure

#EndRegion
