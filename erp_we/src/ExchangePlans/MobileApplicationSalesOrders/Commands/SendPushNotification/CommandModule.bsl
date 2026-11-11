
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Recipients = New Array;
	RecipientsAreSpecified = False;
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then
		If CommandExecuteParameters.Source.FormName = "ExchangePlan.MobileApplicationSalesOrders.Form.ListForm" Then
			For Each Item In CommandExecuteParameters.Source.ChildItems.List.SelectedRows Do
				Recipients.Add(Item);
			EndDo;
			RecipientsAreSpecified = True;
		ElsIf CommandExecuteParameters.Source.FormName = "ExchangePlan.MobileApplicationSalesOrders.Form.NodeForm" Then
			ExchangePlanObject = CommandExecuteParameters.Source.Object;//ExchangePlanObject -  
			Recipients.Add(ExchangePlanObject.Ref);
			RecipientsAreSpecified = True;
		EndIf;
	EndIf;
	If RecipientsAreSpecified And Recipients.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy chỉ ra người nhận thông báo đẩy';
								|ru = 'Укажите получателей уведомления';
								|en = 'Specify notification recipients'; fa = 'Specify notification recipients';
								|it = 'Specificare i destinatari delle notifiche';
								|pl = 'Podaj odbiorców powiadomień';
								|tr = 'Bildirim alıcılarını belirtin'"),, NStr("vi = 'Thông báo đẩy';
																				|ru = 'Push - уведомление';
																				|en = 'Push notification'; fa = 'Push notification';
																				|it = 'Notifica push';
																				|pl = 'Powiadomienie push';
																				|tr = 'Anlık bildirim'"));
		Return;
	EndIf;
	SendPushNotificationToUsers(CommandExecuteParameters.Source, Recipients, RecipientsAreSpecified);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ConfiguredPushNotifications()
	
	Return ExchangePlans.MobileApplicationSalesOrders.ExchangePlanUsesSendingPushNotifications();
EndFunction

&AtClient
Procedure SendPushNotificationToUsers(OwnerForm, Recipients, RecipientsAreSpecified)
	
	If ConfiguredPushNotifications() Then
		FormParameters = New Structure("Recipients, RecipientsAreSpecified", Recipients, RecipientsAreSpecified);
		OpenForm("ExchangePlan.MobileApplicationSalesOrders.Form.PushNotificationSubmissionForm", FormParameters, OwnerForm);
	Else
		AdditionalParameters = New Structure("OwnerForm, NotificationRecipients, RecipientsAreSpecified", OwnerForm, Recipients, RecipientsAreSpecified);
		CallbackDescription = New CallbackDescription("AfterConfiguringUseOfPushNotifications", ThisObject, AdditionalParameters);
		OpenForm("ExchangePlan.MobileApplicationSalesOrders.Form.MainNodeForm",, OwnerForm,,,, CallbackDescription);
	EndIf;
EndProcedure

&AtClient
Procedure AfterConfiguringUseOfPushNotifications(Val Results_1, Val AdditionalParameters) Export
	
	If ConfiguredPushNotifications() Then
		SendPushNotificationToUsers(AdditionalParameters.OwnerForm,
			AdditionalParameters.NotificationRecipients, AdditionalParameters.RecipientsAreSpecified);
	EndIf;
EndProcedure

#EndRegion
