
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("GroupOfMailoutsAndNotifications", CommandParameter);
	OpenForm("Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Form.FormSubscribersAndAddresseesOfGroup",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window,
	             CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
