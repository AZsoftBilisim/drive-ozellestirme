#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not SendToCustomer Then
		
		NotCheckedAttributeArray.Add("PartnerContactDetailsKindForMails");
		NotCheckedAttributeArray.Add("PartnerContactDetailsKindForSMSMessage");

	EndIf;
	
	If Not SendToAContactPersonOfANotificationObject Then
		
		NotCheckedAttributeArray.Add("ContactPersonContactDetailsKindOfNotificationObjectForMails");
		NotCheckedAttributeArray.Add("ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage");
		
	EndIf;
	
	GroupDetails_ = Common.ObjectAttributesValues(GroupOfMailoutsAndNotifications,
	                                                              "DesignedForEmails, DesignedForSMSMessage");
	
	If Not GroupDetails_.DesignedForEmails Then
		
		NotCheckedAttributeArray.Add("ContactPersonContactDetailsKindOfNotificationObjectForMails");
		NotCheckedAttributeArray.Add("PartnerContactDetailsKindForMails");
		NotCheckedAttributeArray.Add("ContactPersons.ContactDetailsKindForMails");
		
	EndIf;
	
	If Not GroupDetails_.DesignedForSMSMessage Then
		
		NotCheckedAttributeArray.Add("ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage");
		NotCheckedAttributeArray.Add("PartnerContactDetailsKindForSMSMessage");
		NotCheckedAttributeArray.Add("ContactPersons.ContactDetailsKindForSMSMessage");
		
	EndIf;
	
	If SubscriptionIsValid And (Not SendToCustomer And Not SendToAContactPersonOfANotificationObject And ContactPersons.Count() = 0) Then
		
		ErrorText = NStr("vi = 'Đăng ký có hiệu lực, nhưng chưa chỉ ra người nhận nào.';
						|ru = 'Подписка действует, но не указан ни один адресат.';
						|en = 'The subscription is valid but no address is specified.'; fa = 'The subscription is valid but no address is specified.';
						|it = 'La sottoscrizione è valida, ma nessun destinatario è specificato.';
						|pl = 'Subskrypcja jest aktywna ale nie wskazano ani jednego adresata.';
						|tr = 'Abonelik etkin, ancak alıcı belirtilmedi.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"SendToCustomer",
			,
			Cancel);
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);

EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	NumberOfAddresseesContactPersons = ContactPersons.Count();
	DescriptionTemplate = NStr("vi = 'Đối với ""%1"" đến ""%2""';
								|ru = 'Для ""%1"" по ""%2""';
								|en = 'For ""%1"" by ""%2""'; fa = 'For ""%1"" by ""%2""';
								|it = 'Per ""%1"" al ""%2""';
								|pl = 'Dla ""%1"" do ""%2""';
								|tr = '""%2"" ile ""%1"" için'");
	DescriptionTemplate = StringFunctionsClientServer.SubstituteParametersToString(DescriptionTemplate,
	                                                                       String(Owner),
	                                                                       String(GroupOfMailoutsAndNotifications));
	
	If StrLen(DescriptionTemplate) > 150 Then
		Description = Left(DescriptionTemplate, 147) + "...";
	Else
		Description = DescriptionTemplate;
	EndIf;
	
	ContactPersons.GroupBy("ContactPerson, ContactDetailsKindForMails, ContactDetailsKindForSMSMessage");
	
EndProcedure

#EndRegion

#EndIf
