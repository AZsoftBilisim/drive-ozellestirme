#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.GroupOfMailoutsAndNotifications) Then
		Cancel = True;
		Return;
	EndIf;
	
	EditRight = AccessRight("Update", Metadata.Catalogs.SubscriptionsToCustomerMailoutsAndNotifications);
	ItemArray = New Array;
	ItemArray.Add("ListPartnersByFilter");
	ItemArray.Add("ListSign");
	ItemArray.Add("ListUnsubscribe");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", EditRight);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	      ThisObject, "ListSendToCustomer", NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Controparte';
												|pl = 'Counterparty';
												|tr = 'Cari hesap'"));
	
	GroupOfMailoutsAndNotifications = Parameters.GroupOfMailoutsAndNotifications;
	MailoutsAndNotificationsToCustomers.FillInFormDetailsForMailingAndNotificationGroup(ThisObject, GroupOfMailoutsAndNotifications);
	CommonClientServer.SetDynamicListParameter(
	          List,
	          "GroupOfMailoutsAndNotifications",
	          GroupOfMailoutsAndNotifications);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.Partners")
		And Not ValueSelected.IsEmpty() Then
		
		MailoutsAndNotificationsToCustomersClient.OpenSubscriptionForm(ValueSelected, GroupOfMailoutsAndNotifications, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SubscriptionsToCustomerMailoutsAndNotifications"
		And Parameter.Property("GroupOfMailoutsAndNotifications")
		And Parameter.Subscriber = GroupOfMailoutsAndNotifications Then
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Settings.Get("ShowSuspended") <> Undefined Then
		ShowSuspended = Settings.Get("ShowSuspended");
		SettingsAreProcessed = True;
		SetFilter(ThisObject);
		Settings.Delete("ShowSuspended");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not SettingsAreProcessed Then
		SetFilter(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Copy Then
		Return;
	EndIf;
	
	OpenForm("Catalog.Partners.ChoiceForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure ShowSuspendedOnChange(Item)
	
	SetFilter(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure Sign(Command)
	
	SignUnsubscribe(True);
	
EndProcedure

&AtClient
Procedure Unsubscribe(Command)
	
	SignUnsubscribe(False);
	
EndProcedure

&AtClient
Procedure AddByFilter(Command)
	
	FormParameters = MailoutsAndNotificationsToCustomersClient.SelectionFormParametersBySelection(ThisObject);
	
	OnCloseNotifyHandler = New CallbackDescription("SelectionOfSelectionPartnersAtClosing", ThisObject);
	
	OpenForm(
		"DataProcessor.SelectPartnersByFilter.Form.Form",
		FormParameters,
		ThisForm,
		UUID,
		,,
		OnCloseNotifyHandler);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

EndProcedure

&AtClientAtServerNoContext
Procedure SetFilter(Form)

	CommonClientServer.SetDynamicListFilterItem(
	      Form.List,
	      "SubscriptionIsValid",
	      True,
	      ,
	      ,
	      ?(Form.ShowSuspended, False, True));

EndProcedure

&AtClient
Procedure SignUnsubscribe(Sign)
	
	SelectedRows          = Items.List.SelectedRows;
	NumberOfRowsToProcess_ = SelectedRows.Count();
	ArrayOfSubscriptionsToChanges  = New Array;
	
	For Each SelectedRow In SelectedRows Do
		
		RowData = Items.List.RowData(SelectedRow);
		If RowData.SubscriptionIsValid <> Sign  Then
			ArrayOfSubscriptionsToChanges.Add(SelectedRow);
		EndIf;
		
	EndDo;
	
	If ArrayOfSubscriptionsToChanges.Count() > 0 Then
		
		CancelSetSubscriptionForArrayOfSubscriptions(ArrayOfSubscriptionsToChanges, Sign);
		
		If Sign Then
			NotificationText1 = NStr("vi = 'Đăng ký';
									|ru = 'Оформление подписки';
									|en = 'Register subscription'; fa = 'Register subscription';
									|it = 'Iscrizione all''abbonamento';
									|pl = 'Subskrypcja';
									|tr = 'Aboneliğinin kaydı'");
		Else
			NotificationText1 = NStr("vi = 'Hủy đăng ký';
									|ru = 'Отмена подписки';
									|en = 'Cancel subscription'; fa = 'Cancel subscription';
									|it = 'Annullamento di abbonamento';
									|pl = 'Anulowanie subskrypcji';
									|tr = 'Aboneliğinin iptali'");
		EndIf;
		
		ExplanationText = NStr("vi = 'Đăng ký %1 đối với %2 / %3 bạn hàng.';
								|ru = 'Подписка %1 для %2 из %3 партнеров.';
								|en = 'Subscription %1 for %2 out of %3 partners.'; fa = 'Subscription %1 for %2 out of %3 partners.';
								|it = 'Abbonamento %1 per %2 da %3 partner.';
								|pl = 'Subskrypcja %1 dla %2 z %3 partnerów';
								|tr = '%3 iş ortaklarından %2 için %1 abonelik'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
		               ExplanationText,
		               ?(Sign, NStr("vi = 'đã thực hiện';
									|ru = 'выполнена';
									|en = 'completed'; fa = 'تکمیل‌شده';
									|it = 'completata';
									|pl = 'wykonana';
									|tr = 'tamamlandı'"), NStr("vi = 'đã hủy';
																|ru = 'отменена';
																|en = 'canceled'; fa = 'canceled';
																|it = 'annullata';
																|pl = 'anulowana';
																|tr = 'iptal edildi'")),
		               ArrayOfSubscriptionsToChanges.Count(),
		               NumberOfRowsToProcess_);
		
	Else
		
		NotificationText1 = NStr("vi = 'Chưa điền thay đổi đăng ký';
								|ru = 'Изменение подписок не выполнено';
								|en = 'Subscriptions are not changed'; fa = 'Subscriptions are not changed';
								|it = 'Modifica dell''abbonamento fallita';
								|pl = 'Zmiana subskrypcji nie została wykonana';
								|tr = 'Aboneliğin değiştirilmesi gerçekleştirilmedi'");
		ExplanationText  = NStr("vi = 'Không có bạn hàng mà cần thay đổi đăng ký.';
								|ru = 'Нет партнеров, для которых необходимо изменить подписку.';
								|en = 'There are not partners for whom the subscription should be changed.'; fa = 'There are not partners for whom the subscription should be changed.';
								|it = 'Non ci sono partner per i quali è necessario modificare l''abbonamento.';
								|pl = 'Brak partnerów, dla których należy zmienić subskrypcję.';
								|tr = 'Aboneliği değiştirmek için gerekli iş ortağı yok.'");
		
	EndIf;
	
	ShowUserNotification(NotificationText1, , ExplanationText);
	
EndProcedure

&AtServer
Procedure CancelSetSubscriptionForArrayOfSubscriptions(ArrayOfSubscriptions, Sign)

	If Sign Then
		Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.SubscribeToArrayOfExistingAndNewSubscriptions(ArrayOfSubscriptions);
	Else
		Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.UnsubscribeForArray(ArrayOfSubscriptions);
	EndIf;
	
	Items.List.Refresh();

EndProcedure

&AtServer
Procedure AddSelectionPartnersOnServer(AddressInTempStorage)

	MailoutsAndNotificationsToCustomers.AddSubscribersBySelection(AddressInTempStorage, GroupOfMailoutsAndNotifications,
	                                                        DesignedForSMSMessage, DesignedForEmails);
	Items.List.Refresh();

EndProcedure

&AtClient
Procedure SelectionOfSelectionPartnersAtClosing(AddressInTempStorage, AdditionalParameters) Export

	If ValueIsFilled(AddressInTempStorage) Then
		AddSelectionPartnersOnServer(AddressInTempStorage);
	EndIf;

EndProcedure

#EndRegion

