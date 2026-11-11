

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	AuthorizationObjectData = PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser();
	Subscriber = AuthorizationObjectData.Partner;
	
	If Subscriber = Undefined Or Subscriber.IsEmpty() Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Subscriber", Subscriber);
	OpenForm("Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Form.ListFormOfSubscriber",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window,
	             CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion

