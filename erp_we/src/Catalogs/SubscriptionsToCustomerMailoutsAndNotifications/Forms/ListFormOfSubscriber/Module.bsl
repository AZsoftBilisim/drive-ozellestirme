
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not ValueIsFilled(Parameters.Subscriber) Then
		Cancel = True;
		Return;
	EndIf;
	
	If TypeOf(Parameters.Subscriber) = Type("CatalogRef.Partners") Then
		Subscriber = Parameters.Subscriber;
	Else
		
		Cancel = True;
		Return;
		
	EndIf;
	
	EditRight = AccessRight("Update", Metadata.Catalogs.SubscriptionsToCustomerMailoutsAndNotifications);
	ItemArray = New Array;
	ItemArray.Add("SubscriptionTableSubscribe");
	ItemArray.Add("SubscriptionTableCancelYourSubscription");
	ItemArray.Add("SubscriptionTableEdit");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", EditRight);
	
	GroupsOfMailoutsAndNotifications.LoadValues(Parameters.GroupsOfMailoutsAndNotifications.UnloadValues());
	
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	VisibilityManagement();
	
	FillInSubscriptionTable();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SubscriptionsToCustomerMailoutsAndNotifications"
		And Parameter.Property("Subscriber")
		And Parameter.Subscriber = Subscriber Then
		FillInSubscriptionTable();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForTablePartSubscriptionTable

&AtClient
Procedure SubscriptionTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = SubscriptionTable.FindByID(RowSelected);
		
	EditSubscription(CurrentData);
	
EndProcedure

&AtClient
Procedure EditSubscription(CurrentData)

	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Forced Then
		WarningText = NStr("vi = 'Chưa tùy chỉnh đối với nhóm buộc gửi thông báo đăng ký.';
							|ru = 'Для принудительных групп рассылок и оповещений подписки не настраиваются.';
							|en = 'Subscriptions are not configured for forced groups of mailouts and notifications.'; fa = 'Subscriptions are not configured for forced groups of mailouts and notifications.';
							|it = 'Per gruppi di avvisi e notifiche di default, gli abbonamenti non vengono configurati.';
							|pl = 'Dla przymusowych grup subskrypcji i powiadomień subskrypcje nie są konfigurowane.';
							|tr = 'Abonelikler, zorunlu bildirim dağıtım grupları ve uyarılar için ayarlanmıyor.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	MailoutsAndNotificationsToCustomersClient.EditSubscription(CurrentData.SubscriptionRef,
	                                                        Subscriber,
	                                                        CurrentData.GroupOfMailoutsAndNotifications,
	                                                        ThisObject,
	                                                        False);
	
EndProcedure

&AtClient
Procedure SubscriptionTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SubscriptionTableBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Subscribe(Command)
	
	RequestForSubscription = New Array;
	SelectedRows = Items.SubscriptionTable.SelectedRows;
	SubscriptionRequirements = SelectedRows.Count();
	
	For Each SelectedRow In SelectedRows Do
		
		CurrentData = SubscriptionTable.FindByID(SelectedRow);
		If CurrentData = Undefined Then
			Continue;
		EndIf;
		
		
		If (Not CurrentData.Signed) And Not CurrentData.Forced Then
			If CurrentData.SubscriptionRef.IsEmpty() Then
				
				RequestForSubscription.Add(New Structure("Subscriber, GroupOfMailoutsAndNotifications",
				                                         Subscriber,
				                                         CurrentData.GroupOfMailoutsAndNotifications));
				
			Else
				RequestForSubscription.Add(CurrentData.SubscriptionRef);
			EndIf;
		EndIf;
		
	EndDo;
	
	If RequestForSubscription.Count() > 0 Then
		
		SubscribeToArray(RequestForSubscription);
		
		NotificationText1 = NStr("vi = 'Đăng ký';
								|ru = 'Подписка';
								|en = 'Subscription'; fa = 'اشتراک';
								|it = 'Sottoscrizione';
								|pl = 'Subskrypcja';
								|tr = 'Abonelik'");
		ExplanationText  = NStr("vi = 'Đã thực hiện đăng ký đối với %1 / %2 nhóm gửi thông báo.';
								|ru = 'Подписка выполнена для %1 из %2 групп рассылок и оповещений.';
								|en = 'Subscription is set for %1 of %2 groups of mailouts and notifications.'; fa = 'Subscription is set for %1 of %2 groups of mailouts and notifications.';
								|it = 'La sottoscrizione effettuata per %1 da %2 gruppi di avvisi e notifiche.';
								|pl = 'Subskrypcja została wykonana dla %1 z %2 grup subskrypcji i powiadomień.';
								|tr = '%2 dağıtım ve bildirim gruplarından abonelik %1 için gerçekleştirildi.'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText,
		                                                                         RequestForSubscription.Count(),
		                                                                         SubscriptionRequirements);
		
	Else
		
		NotificationText1 = NStr("vi = 'Chưa đăng ký';
								|ru = 'Подписки не выполнены';
								|en = 'Subscriptions are not executed'; fa = 'Subscriptions are not executed';
								|it = 'Sottoscrizioni non eseguite';
								|pl = 'Subskrypcje nie zostały wykonane';
								|tr = 'Abonelikler gerçekleştirilmedi'");
		ExplanationText  = NStr("vi = 'Không có nhóm gửi thông báo mà cần đăng ký';
								|ru = 'Нет групп рассылок и оповещений для которых необходимо выполнить подписку';
								|en = 'There are no groups of mailouts and notifications for which the subscription should be set'; fa = 'There are no groups of mailouts and notifications for which the subscription should be set';
								|it = 'Non ci sono gruppi di avvisi e notifiche per le quali è necessario abbonarsi';
								|pl = 'Brak grup subskrypcji i powiadomień, dla których należy wykonać subskrypcję';
								|tr = 'Aboneliği gerçekleştirilecek dağıtım grubu ve bildirim yok'");
		
	EndIf;
	
	ShowUserNotification(NotificationText1, , ExplanationText);
	
EndProcedure

&AtClient
Procedure CancelYourSubscription(Command)
	
	ReadyToUnsubscribe = New Array;
	
	SelectedRows = Items.SubscriptionTable.SelectedRows;
	NumberOfSubscriptionsToCancel_ = SelectedRows.Count();
	
	For Each SelectedRow In SelectedRows Do
		
		CurrentData = SubscriptionTable.FindByID(SelectedRow);
		If CurrentData = Undefined Then
			Continue;
		EndIf;
		
		
		If CurrentData.Signed And (Not CurrentData.Forced) Then
			ReadyToUnsubscribe.Add(CurrentData.SubscriptionRef);
		EndIf;
		
	EndDo;
	
	If ReadyToUnsubscribe.Count() > 0 Then
		
		UnsubscribeForArray(ReadyToUnsubscribe);
		
		NotificationText1 = NStr("vi = 'Hủy đăng ký';
								|ru = 'Отмена подписок';
								|en = 'Cancel subscriptions'; fa = 'Cancel subscriptions';
								|it = 'Annullamento iscrizioni';
								|pl = 'Anulowanie subskrypcji';
								|tr = 'Aboneliğin iptali'");
		ExplanationText  = NStr("vi = 'Đã hủy đăng ký đối với %1 / %2 nhóm gửi thông báo.';
								|ru = 'Подписка отменена для %1 из %2 групп рассылок и оповещений.';
								|en = 'Subscription is canceled for %1 of %2 groups of mailouts and notifications.'; fa = 'Subscription is canceled for %1 of %2 groups of mailouts and notifications.';
								|it = 'La sottoscrizione annullata per %1 da %2 gruppi di avvisi e notifiche.';
								|pl = 'Subskrypcja została anulowana dla %1 z %2 grup subskrypcji i powiadomień.';
								|tr = '%2 dağıtım grubu ve bildirimden %1 için abonelik iptal edildi.'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(ExplanationText,
		                                                                         ReadyToUnsubscribe.Count(),
		                                                                         NumberOfSubscriptionsToCancel_);
		
	Else
		
		NotificationText1 = NStr("vi = 'Không hủy đăng ký';
								|ru = 'Подписки не отменены';
								|en = 'Subscriptions are not canceled'; fa = 'Subscriptions are not canceled';
								|it = 'Sottoscrizioni non annullate';
								|pl = 'Subskrypcje nie zostały anulowane';
								|tr = 'Abonelikler iptal edilmedi'");
		ExplanationText  = NStr("vi = 'Không có nhóm gửi thông báo mà cần hủy đăng ký';
								|ru = 'Нет групп рассылок и оповещений для которых необходимо отменять подписку';
								|en = 'There are no groups of mailouts and notifications for which the subscription should be canceled'; fa = 'There are no groups of mailouts and notifications for which the subscription should be canceled';
								|it = 'Non ci sono gruppi di avvisi e notifiche per le quali è necessario annullare iscrizione';
								|pl = 'Brak grup subskrypcji i powiadomień, dla których należy wykonać anulowanie subskrypcji';
								|tr = 'Aboneliklerin iptali gereken dağıtım grubu ve uyarı yok'");
		
	EndIf;
		
	ShowUserNotification(NotificationText1, , ExplanationText);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillInSubscriptionTable();
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	CurrentData = Items.SubscriptionTable.CurrentData;
	EditSubscription(CurrentData);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// Forced and addressees are not configured
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubscriptionTableRecipients.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SubscriptionTable.Forced");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("SubscriptionTable.Recipients");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

&AtServer
Procedure FillInSubscriptionTable()

	SubscriptionTable.Clear();
	
	Query = New Query;
	
	QueryTextSubscriptions = "
	|SELECT ALLOWED
	|	GroupsOfMailoutsAndNotifications.Ref AS GroupOfMailoutsAndNotifications,
	|	CASE
	|		WHEN ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid, FALSE) = TRUE
	|			THEN &Valid
	|		ELSE &Suspended_
	|	END AS Subscription,
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons, 0) AS NumberOfAdditionalAddressees_,
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer, FALSE) AS SendToCustomer,
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject, FALSE) AS SendToAContactPersonOfANotificationObject,
	|	FALSE AS PoisoningContactPersonRoles,
	|	"""" AS NameOfContactPersonRole,
	|	CASE
	|		WHEN GroupsOfMailoutsAndNotifications.DesignedForEmails
	|				AND GroupsOfMailoutsAndNotifications.DesignedForSMSMessage
	|			THEN &ForEmailsAndSMS
	|		ELSE CASE
	|				WHEN GroupsOfMailoutsAndNotifications.DesignedForEmails
	|					THEN &ForEmails_2
	|				ELSE &ForSMS
	|			END
	|	END AS SendingMethod,
	|	GroupsOfMailoutsAndNotifications.Description AS Description,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.Ref, VALUE(Catalog.SubscriptionsToCustomerMailoutsAndNotifications.EmptyRef)) AS SubscriptionRef,
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid, FALSE) AS Signed,
	|	GroupsOfMailoutsAndNotifications.LongDesc
	|FROM
	|	Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		LEFT JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|		ON (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref)
	|			AND (SubscriptionsToCustomerMailoutsAndNotifications.Owner = &Subscriber)
	|			AND (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
	|WHERE
	|	NOT GroupsOfMailoutsAndNotifications.Forced
	|	AND NOT GroupsOfMailoutsAndNotifications.DeletionMark";
	
	TextUnion = "
	|
	|UNION ALL
	|";
	
	RequestTextForced = "
	|SELECT
	|	GroupsOfMailoutsAndNotifications.Ref,
	|	&Forced,
	|	0 AS NumberOfAdditionalAddressees_,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToAContactPersonOfANotificationObject,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons,
	|	ISNULL(RolesOfPartnerContactPersons.Description, """") AS NameOfContactPersonRole,
	|	CASE
	|		WHEN GroupsOfMailoutsAndNotifications.DesignedForEmails
	|				AND GroupsOfMailoutsAndNotifications.DesignedForSMSMessage
	|			THEN &ForEmailsAndSMS
	|		ELSE CASE
	|				WHEN GroupsOfMailoutsAndNotifications.DesignedForEmails
	|					THEN &ForEmails_2
	|				ELSE &ForSMS
	|			END
	|	END AS SendingMethod,
	|	GroupsOfMailoutsAndNotifications.Description,
	|	GroupsOfMailoutsAndNotifications.Forced AS Forced,
	|	VALUE(Catalog.SubscriptionsToCustomerMailoutsAndNotifications.EmptyRef) AS SubscriptionRef,
	|	FALSE AS Signed,
	|	GroupsOfMailoutsAndNotifications.LongDesc
	|FROM
	|	Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		LEFT JOIN Catalog.RolesOfPartnerContactPersons AS RolesOfPartnerContactPersons
	|		ON GroupsOfMailoutsAndNotifications.ContactRole = RolesOfPartnerContactPersons.Ref
	|WHERE
	|	GroupsOfMailoutsAndNotifications.Forced
	|	AND NOT GroupsOfMailoutsAndNotifications.DeletionMark
	|
	|ORDER BY
	|	GroupsOfMailoutsAndNotifications.Description";
	
	Query.Text = QueryTextSubscriptions;
	If Not AnExternalUserIsAuthorized Then
		Query.Text = Query.Text + TextUnion + RequestTextForced;
	EndIf;
	
	Query.SetParameter("Subscriber", Subscriber);
	Query.SetParameter("Valid",      NStr("vi = 'Có hiệu lực';
											|ru = 'Действует';
											|en = 'Valid'; fa = 'معتبر';
											|it = 'In vigore';
											|pl = 'Valid';
											|tr = 'Aktif'"));
	Query.SetParameter("Forced", NStr("vi = 'Buộc';
										|ru = 'Принудительно';
										|en = 'Forcibly'; fa = 'Forcibly';
										|it = 'Forzatamente';
										|pl = 'Forcibly';
										|tr = 'Mecburi'"));
	Query.SetParameter("Suspended_", NStr("vi = 'Đã dừng';
											|ru = 'Приостановлена';
											|en = 'Suspended'; fa = 'معلق';
											|it = 'Sospesa';
											|pl = 'Suspended';
											|tr = 'Askıya alındı'"));
	Query.SetParameter("ForEmailsAndSMS",   NStr("vi = 'E-mail và SMS';
												|ru = 'Email и SMS';
												|en = 'Email and SMS message'; fa = 'Email and SMS message';
												|it = 'Email e SMS';
												|pl = 'E-mail i SMS';
												|tr = 'E-posta ve SMS'"));
	Query.SetParameter("ForEmails_2",       NStr("vi = 'Email';
												|ru = 'Email';
												|en = 'Email'; fa = 'ایمیل';
												|it = 'Email';
												|pl = 'Email';
												|tr = 'Email'"));
	Query.SetParameter("ForSMS",         NStr("vi = 'SMS';
												|ru = 'SMS';
												|en = 'SMS'; fa = 'پیامک';
												|it = 'SMS';
												|pl = 'SMS';
												|tr = 'SMS'"));
	
	Selection= Query.Execute().Select();
	While Selection.Next() Do
	
		If GroupsOfMailoutsAndNotifications.Count() > 0
			And GroupsOfMailoutsAndNotifications.FindByValue(Selection.GroupOfMailoutsAndNotifications) = Undefined Then
			
			Continue;
			
		EndIf;
		
		NewRow = SubscriptionTable.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.Recipients = MailoutsAndNotificationsToCustomers.TextToWhomMessagesWillBeSent(Selection, Selection.Forced);
		
	EndDo;

EndProcedure

&AtServer
Procedure UnsubscribeForArray(ArrayOfSubscriptions)

	If AnExternalUserIsAuthorized Then
		SetPrivilegedMode(True);
	EndIf;
	
	Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.UnsubscribeForArray(ArrayOfSubscriptions);
	
	FillInSubscriptionTable();

EndProcedure

&AtServer
Procedure SubscribeToArray(ArrayOfSubscriptions)
	
	If AnExternalUserIsAuthorized Then
		SetPrivilegedMode(True);
	EndIf;
	
	Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.SubscribeToArrayOfExistingAndNewSubscriptions(ArrayOfSubscriptions);
	
	FillInSubscriptionTable();
	
EndProcedure

&AtServer
Procedure VisibilityManagement()

	If AnExternalUserIsAuthorized Then
		Items.SubscriptionTableSubscription.Visible                  = False;
		Items.SubscriptionTableGroupOfMailoutsAndNotifications.Title = NStr("vi = 'Đăng ký';
																			|ru = 'Подписка';
																			|en = 'Subscription'; fa = 'اشتراک';
																			|it = 'Sottoscrizione';
																			|pl = 'Subscription';
																			|tr = 'Abonelik'");
	Else
		Items.SubscriptionTableSigned.Visible        = False;
	EndIf;

EndProcedure


#EndRegion


