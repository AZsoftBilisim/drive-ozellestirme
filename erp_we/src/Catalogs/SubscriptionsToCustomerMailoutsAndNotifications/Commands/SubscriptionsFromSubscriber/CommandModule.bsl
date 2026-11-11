

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Subscriber", CommandParameter);
	OpenForm("Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Form.ListFormOfSubscriber",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window,
	             CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
