
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("GroupOfMailoutsAndNotifications", CommandParameter);
	OpenForm("Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Form.ListFormOfGroup",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window,
	             CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
