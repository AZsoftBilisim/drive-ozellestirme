#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetConditionalAppearance();
	
	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
	EndIf;
	
	VisibilityManagement();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnCreatReadAtServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	TypesOfContactInformationEmptyLink = Catalogs.ContactInformationKinds.EmptyRef();
	
	If (Not Object.SendToCustomer) Or (Not DesignedForSMSMessage) Then
		CurrentObject.PartnerContactDetailsKindForSMSMessage   = TypesOfContactInformationEmptyLink;
	EndIf;
	
	If (Not Object.SendToCustomer) Or (Not DesignedForEmails) Then
		CurrentObject.PartnerContactDetailsKindForMails = TypesOfContactInformationEmptyLink;
	EndIf;
	
	If (Not Object.SendToAContactPersonOfANotificationObject) Or (Not DesignedForSMSMessage) Then
		CurrentObject.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage   = TypesOfContactInformationEmptyLink;
	EndIf;
	
	If (Not Object.SendToAContactPersonOfANotificationObject) Or (Not DesignedForEmails) Then
		CurrentObject.ContactPersonContactDetailsKindOfNotificationObjectForMails = TypesOfContactInformationEmptyLink;
	EndIf;
	
	If (Not DesignedForEmails) Or (Not DesignedForSMSMessage) Then
		For Each ContactPerson In CurrentObject.ContactPersons Do
			If Not DesignedForEmails Then
				ContactPerson.ContactDetailsKindForMails = TypesOfContactInformationEmptyLink;
			EndIf;
			If Not DesignedForSMSMessage Then
				ContactPerson.ContactDetailsKindForSMSMessage   = TypesOfContactInformationEmptyLink;
			EndIf;
		EndDo;
	EndIf;
	
	If Not SendMessagesToContactPersons Then
		CurrentObject.ContactPersons.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SendMessagesToContactPersons = Object.ContactPersons.Count() > 0;
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("Subscriber", Object.Owner);
	WriteParameters.Insert("GroupOfMailoutsAndNotifications", Object.GroupOfMailoutsAndNotifications);
	Notify("Write_SubscriptionsToCustomerMailoutsAndNotifications", WriteParameters, ThisObject); 
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubscriptionIsValidOnChange(Item)
	
	Object.SubscriptionIsValid = ?(SubscriptionIsValid = 1, True, False);
	
EndProcedure

&AtClient
Procedure SendToCustomerOnChange(Item)
	
	FillInDefaultKiTypes(ThisObject);
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure SendToAContactPersonOfANotificationObjectOnChange(Item)
	
	FillInDefaultKiTypes(ThisObject);
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDefaultKiTypes(Form)

	If Form.Object.SendToCustomer Then
		If Form.DesignedForSMSMessage And Form.Object.PartnerContactDetailsKindForSMSMessage.IsEmpty() Then
			Form.Object.PartnerContactDetailsKindForSMSMessage = Form.PartnerSContactDetailsKindForSMSMessage;
		EndIf;
		If Form.DesignedForEmails And Form.Object.PartnerContactDetailsKindForMails.IsEmpty() Then
			Form.Object.PartnerContactDetailsKindForMails = Form.PartnerSContactDetailsKindForEmails;
		EndIf;
	EndIf;
	
	If Form.Object.SendToAContactPersonOfANotificationObject Then
		If Form.DesignedForSMSMessage And Form.Object.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage.IsEmpty() Then
			Form.Object.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage = Form.ContactPersonSContactDetailsKindForSMSMessage;
		EndIf;
		If Form.DesignedForEmails And Form.Object.ContactPersonContactDetailsKindOfNotificationObjectForMails.IsEmpty() Then
			Form.Object.ContactPersonContactDetailsKindOfNotificationObjectForMails = Form.ContactPersonSContactDetailsKindForEmails;
		EndIf;
	EndIf;
	
	For Each ContactPerson In Form.Object.ContactPersons Do
		
		If Form.DesignedForSMSMessage And ContactPerson.ContactDetailsKindForSMSMessage.IsEmpty() Then
			ContactPerson.ContactDetailsKindForSMSMessage = Form.ContactPersonSContactDetailsKindForSMSMessage;
		EndIf;
		
		If Form.DesignedForEmails And ContactPerson.ContactDetailsKindForMails.IsEmpty() Then
			ContactPerson.ContactDetailsKindForMails = Form.ContactPersonSContactDetailsKindForEmails;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SendMessagesToContactPersonsOnChange(Item)
	
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsContactPersons

&AtClient
Procedure ContactPersonsOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.NotNewRow Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.ContactDetailsKindForSMSMessage) And DesignedForSMSMessage  Then
		CurrentData.ContactDetailsKindForSMSMessage = ContactPersonSContactDetailsKindForSMSMessage;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.ContactDetailsKindForMails) And DesignedForEmails Then
		CurrentData.ContactDetailsKindForMails = ContactPersonSContactDetailsKindForEmails;
	EndIf;
	
	CurrentData.NotNewRow = True;
	
EndProcedure

&AtClient
Procedure ContactPersonsOnChange(Item)
	
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()

	Items.DecorationContactPersonOfTheNotificationObjectExplanation.Title = 
	                 MailoutsAndNotificationsToCustomers.ExplanationTextContactPersonOfNotificationObject();
	SendMessagesToContactPersons = Object.ContactPersons.Count() > 0;
	FillInListsForSelectingTypeOfCI();
	SubscriptionIsValid = ?(Object.SubscriptionIsValid, 1, 0);
	
	MailoutsAndNotificationsToCustomers.FillInFormDetailsForMailingAndNotificationGroup(ThisObject, Object.GroupOfMailoutsAndNotifications);
	FillInDefaultKiTypes(ThisObject);
	Items.AvailableWaysToSendAnExplanation.Title = ExplanationTextAvailableSendingMethods();
	
	AvailabilityControl(ThisForm);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// It is not intended for SMS and the type of contact information for SMS of the contact person is not filled in.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContactPersonsTypeOfContactPersonForSMS.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DesignedForSMSMessage");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ContactPersons.ContactDetailsKindForSMSMessage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Enabled", False);
	
	// It is not intended for letters and the type of contact information for the letters of the contact person is not filled in.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContactPersonsTypeOfContactPersonForEmails.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DesignedForEmails");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ContactPersons.ContactDetailsKindForMails");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không cần>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Enabled", False);

EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	If Not ValueIsFilled(Form.Object.Owner) 
		Or Not ValueIsFilled(Form.Object.GroupOfMailoutsAndNotifications) Then
		Form.ReadOnly = True;
	EndIf;
	
	Form.NumberOfAdditionalAddressees = Form.Object.ContactPersons.Count();
	
	InfluentialFormDetailsSelected = Not Form.Object.Owner.IsEmpty() 
	                                And Not Form.Object.GroupOfMailoutsAndNotifications.IsEmpty();
	
	Form.Items.GroupPartner.Enabled                         = InfluentialFormDetailsSelected;
	Form.Items.GroupContactPersonOfTheNotificationObject.Enabled = InfluentialFormDetailsSelected;
	Form.Items.GroupContactPersons.Enabled                  = InfluentialFormDetailsSelected;

	Form.Items.GroupPartnerContactInformation.Enabled        = Form.Object.SendToCustomer;
	Form.Items.GroupContactInformationOfTheContactPerson.Enabled = Form.Object.SendToAContactPersonOfANotificationObject;
	
	Form.Items.PartnerContactDetailsKindForMails.Enabled  = Form.DesignedForEmails;
	Form.Items.PartnerContactDetailsKindForSMSMessage.Enabled    = Form.DesignedForSMSMessage;
	
	Form.Items.ContactPersonContactDetailsKindOfNotificationObjectForMails.Enabled  = Form.DesignedForEmails;
	Form.Items.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage.Enabled    = Form.DesignedForSMSMessage;
	
	Form.Items.ContactPersons.Enabled = Form.SendMessagesToContactPersons;

EndProcedure

&AtServer
Function ExplanationTextAvailableSendingMethods()
	
	If DesignedForEmails And DesignedForSMSMessage Then
		ExplanationText = NStr("vi = 'Sẽ gửi E-mail và SMS';
								|ru = 'Будут отправляться Email и SMS';
								|en = 'Email and SMS message will be sent'; fa = 'Email and SMS message will be sent';
								|it = 'Email e SMS verranno inviati';
								|pl = 'Będą wysyłane wiadomości E-mail i SMS';
								|tr = 'E-posta ve SMS gönderilecek'");
	ElsIf DesignedForEmails Then
		ExplanationText = NStr("vi = 'Sẽ gửi E-mail';
								|ru = 'Будут отправляться Email';
								|en = 'Email will be sent'; fa = 'Email will be sent';
								|it = 'Email verranno inviati';
								|pl = 'Będą wysyłane wiadomości E-mail';
								|tr = 'E-posta gönderilecek'");
	Else
		ExplanationText = NStr("vi = 'Sẽ gửi SMS';
								|ru = 'Будут отправляться SMS';
								|en = 'SMS message will be sent'; fa = 'SMS message will be sent';
								|it = 'SMS verranno inviati';
								|pl = 'Będą wysyłane wiadomości SMS';
								|tr = 'SMS gönderilecek'");
	EndIf;
	
	Return ExplanationText;
	
EndFunction

&AtServer
Function FillInListsForSelectingTypeOfCI()
	
	StructureOfSelectionLists = MailoutsAndNotificationsToCustomers.StructureOfKiSelectionLists();
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	                    Items.PartnerContactDetailsKindForMails.ChoiceList,
	                    StructureOfSelectionLists.PartnersEmailAddress);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	                    Items.PartnerContactDetailsKindForSMSMessage.ChoiceList,
	                    StructureOfSelectionLists.PartnersPhoneNumber_);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	                    Items.ContactPersonContactDetailsKindOfNotificationObjectForMails.ChoiceList,
	                    StructureOfSelectionLists.ContactPersonsEmailAddress);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	                    Items.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage.ChoiceList,
	                    StructureOfSelectionLists.ContactPersonsPhone);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	                    Items.ContactPersonsTypeOfContactPersonForEmails.ChoiceList,
	                    StructureOfSelectionLists.ContactPersonsEmailAddress);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	                    Items.ContactPersonsTypeOfContactPersonForSMS.ChoiceList,
	                    StructureOfSelectionLists.ContactPersonsPhone);

EndFunction

&AtServer
Procedure VisibilityManagement()

	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		Items.Owner.Visible = False;
	EndIf;

EndProcedure

#EndRegion




