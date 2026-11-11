#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If Not Parameters.Property("GroupOfMailoutsAndNotifications") 
		Or Not TypeOf(Parameters.GroupOfMailoutsAndNotifications) = Type("CatalogRef.GroupsOfMailoutsAndNotifications")
		Or Parameters.GroupOfMailoutsAndNotifications.IsEmpty() Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	GroupOfMailoutsAndNotifications = Parameters.GroupOfMailoutsAndNotifications;
	MailoutsAndNotificationsToCustomers.FillInFormDetailsForMailingAndNotificationGroup(ThisObject, GroupOfMailoutsAndNotifications);
	If Forced Then
		Cancel = True;
		Return;
	EndIf;
	
	EditRight = AccessRight("Update", Metadata.Catalogs.SubscriptionsToCustomerMailoutsAndNotifications);
	ItemArray = New Array;
	ItemArray.Add("FormAdd");
	ItemArray.Add("FormAddByFilter");
	ItemArray.Add("Unsubscribe");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", EditRight);
	
	GenerateReport();

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SubscriptionsToCustomerMailoutsAndNotifications"
		And Parameter.Property("GroupOfMailoutsAndNotifications")
		And Parameter.GroupOfMailoutsAndNotifications = GroupOfMailoutsAndNotifications Then
		GenerateReport();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.Partners")
		And Not ValueSelected.IsEmpty() Then
		
		MailoutsAndNotificationsToCustomersClient.OpenSubscriptionForm(ValueSelected, GroupOfMailoutsAndNotifications, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportTableDetailProcessing(Item, Details, StandardProcessing)
	
	StandardProcessing = False;

	ShowValue(, Details);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Add(Command)
	
	OpenForm("Catalog.Partners.ChoiceForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure Pause(Command)
	
	ArrayOfDecryptions = New Array;
	SelectedAreas = ReportTable.SelectedAreas;
	
	For Each Area In SelectedAreas Do
		For String = Area.Top To Area.Bottom Do
			For Column5 = 1 To 5 Do
				Details = ReportTable.Area("R" + Format(String, "NG=0") + "C" + Column5).Details;
				
				If TypeOf(Details) = Type("CatalogRef.SubscriptionsToCustomerMailoutsAndNotifications") Then
					ArrayOfDecryptions.Add(Details);
					Break;
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
	NumberOfSubscriptionsToCancel = ArrayOfDecryptions.Count();
	If NumberOfSubscriptionsToCancel > 0 Then
		
		SuspendSubscriptions(ArrayOfDecryptions);
		
		NotificationText1 = NStr("vi = 'Hủy đăng ký';
								|ru = 'Отмена подписки';
								|en = 'Cancel subscription'; fa = 'Cancel subscription';
								|it = 'Annullamento di abbonamento';
								|pl = 'Anulowanie subskrypcji';
								|tr = 'Aboneliğinin iptali'");
		
		ExplanationText = NStr("vi = 'Đã hủy đăng ký đối với %1 bạn hàng.';
								|ru = 'Подписка отменена для %1 партнеров.';
								|en = 'Subscription is canceled for %1 partners.'; fa = 'Subscription is canceled for %1 partners.';
								|it = 'L''abbonamento è annullato per %1 partner.';
								|pl = 'Subskrypcja została anulowana dla %1 partnerów.';
								|tr = '%1 iş ortakları için aboneliğin iptali'");
		ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
		               ExplanationText,
		               NumberOfSubscriptionsToCancel);
		ShowUserNotification(NotificationText1, , ExplanationText);
		
	EndIf;

EndProcedure

&AtClient
Procedure AddByFilter(Command)
	
	FormParameters = MailoutsAndNotificationsToCustomersClient.SelectionFormParametersBySelection(ThisObject);
	
	OnCloseNotifyHandler = New CallbackDescription("SelectionOfSelectionPartnersAtClosing", ThisObject);
	
	OpenForm("DataProcessor.SelectPartnersByFilter.Form.Form",
	             FormParameters,
	             ThisForm,
	             UUID,
	             ,,
	             OnCloseNotifyHandler);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	GenerateReport();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	ReportTable.FitToPage = True;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS Subscriber,
	|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS SubscriptionRecipient,
	|	SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails AS ContactDetailsKindForEmails,
	|	SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage AS ContactDetailsKindForSMSMessage,
	|	ISNULL(PartnersContactInformationEmail.Presentation, """") AS EMAddress,
	|	ISNULL(PartnersContactInformationSMS.Presentation, """") AS PhoneNumber,
	|	0 AS OrderingValue,
	|	SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons AS NumberOfAdditionalAddressees_,
	|	SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer,
	|	SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject,
	|	SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails,
	|	SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage,
	|	SubscriptionsToCustomerMailoutsAndNotifications.Ref AS Subscription,
	|	Partners.Description AS SubscriberName
	|FROM
	|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformationEmail
	|		ON SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails = PartnersContactInformationEmail.Kind
	|			AND SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnersContactInformationEmail.Ref
	|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer)
	|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformationSMS
	|		ON SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage = PartnersContactInformationSMS.Kind
	|			AND SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnersContactInformationSMS.Ref
	|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer)
	|		INNER JOIN Catalog.Partners AS Partners
	|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = Partners.Ref
	|WHERE
	|	NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
	|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
	|	AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
	|
	|UNION ALL
	|
	|SELECT
	|	SubscriptionsToCustomerMailoutsAndNotifications.Owner,
	|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson,
	|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForMails,
	|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForSMSMessage,
	|	ISNULL(ContactPersonsOfPartnersContactInformationEmail.Presentation, """"),
	|	ISNULL(ContactPersonsOfPartnersContactInformationSMS.Presentation, """"),
	|	1,
	|	0,
	|	FALSE,
	|	FALSE,
	|	VALUE(Catalog.ContactInformationKinds.EmptyRef),
	|	VALUE(Catalog.ContactInformationKinds.EmptyRef),
	|	SubscriptionsToCustomerMailoutsAndNotifications.Ref,
	|	Partners.Description
	|FROM
	|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications.ContactPersons AS SubscriptionsToCustomerMailoutsAndNotificationsContactPersons
	|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|			INNER JOIN Catalog.Partners AS Partners
	|			ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = Partners.Ref
	|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.Ref = SubscriptionsToCustomerMailoutsAndNotifications.Ref
	|			AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications)
	|			AND (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
	|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid)
	|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformationSMS
	|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForSMSMessage = ContactPersonsOfPartnersContactInformationSMS.Kind
	|			AND SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson = ContactPersonsOfPartnersContactInformationSMS.Ref
	|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformationEmail
	|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson = ContactPersonsOfPartnersContactInformationEmail.Ref
	|			AND SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForMails = ContactPersonsOfPartnersContactInformationEmail.Kind
	|
	|ORDER BY
	|	SubscriberName,
	|	OrderingValue
	|TOTALS BY
	|	Subscriber,
	|	SubscriptionRecipient";
	
	Query.SetParameter("GroupOfMailoutsAndNotifications", GroupOfMailoutsAndNotifications);
	
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	Template = Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.GetTemplate("SubscribersAndAddresseesOfGroup");
	
	// The output caps
	ReportTable.Put(Template.GetArea("StringHeader1|Common"));
	If DesignedForEmails Then
		ReportTable.Join(Template.GetArea("StringHeader1|Email"));
	EndIf;
	If DesignedForSMSMessage Then
		ReportTable.Join(Template.GetArea("StringHeader1|Phone"));
	EndIf;
	
	ScopeStringSubscriberGeneral = Template.GetArea("SubscriberLine|Common");
	AreaStringDestinationGeneral   = Template.GetArea("AddresseeRow|Common");
	
	If DesignedForSMSMessage Then
		AreaLineSubscriberPhone = Template.GetArea("SubscriberLine|Phone");
		AreaStringAddresseePhoneNumber   = Template.GetArea("AddresseeRow|Phone");
	EndIf;
	If DesignedForEmails Then
		ScopeStringSubscriberEmail = Template.GetArea("SubscriberLine|Email");
		ScopeStringAddresseeEmail   = Template.GetArea("AddresseeRow|Email");
	EndIf;
	
	LineNumber = 1;
	DSAddressesArray        = New Array;
	ArrayOfPhoneNumbers_ = New Array;
	ArrayOfKiTypesForEmails  = New Array;
	ArrayOfKiTypesForSMS    = New Array;
	
	While SampleResults.Next() Do
		
		ScopeStringSubscriberGeneral.Parameters.LineNumber  = LineNumber;
		ScopeStringSubscriberGeneral.Parameters.Subscriber    = SampleResults.Subscriber;
		
		AddresseeSelection = SampleResults.Select(QueryResultIteration.ByGroups);
		While AddresseeSelection.Next() Do
			
			DSAddressesArray.Clear();
			ArrayOfPhoneNumbers_.Clear();
			ArrayOfKiTypesForEmails.Clear();
			ArrayOfKiTypesForSMS.Clear();
			
			DetailsSelection = AddresseeSelection.Select();
			
			While DetailsSelection.Next() Do
				
				If DesignedForEmails Then
					MailoutsAndNotificationsToCustomers.AddToArray(DSAddressesArray, DetailsSelection.EMAddress);
					MailoutsAndNotificationsToCustomers.AddToArray(ArrayOfKiTypesForEmails, DetailsSelection.ContactDetailsKindForEmails);
				EndIf;
				If DesignedForSMSMessage Then
					MailoutsAndNotificationsToCustomers.AddToArray(ArrayOfPhoneNumbers_, DetailsSelection.PhoneNumber);
					MailoutsAndNotificationsToCustomers.AddToArray(ArrayOfKiTypesForSMS, DetailsSelection.ContactDetailsKindForSMSMessage);
				EndIf;
				
				If AddresseeSelection.SubscriptionRecipient = AddresseeSelection.Subscriber Then
					TextTo =  MailoutsAndNotificationsToCustomers.TextToWhomMessagesWillBeSent(DetailsSelection);
				EndIf;
				
				SendToCustomer = DetailsSelection.SendToCustomer;
				Subscription = DetailsSelection.Subscription;
				
			EndDo;
			
			If AddresseeSelection.SubscriptionRecipient <> AddresseeSelection.Subscriber Then
				
				AreaStringDestinationGeneral.Parameters.Addressee     = AddresseeSelection.SubscriptionRecipient;
				AreaStringDestinationGeneral.Parameters.Details = Subscription;
				
				ReportTable.Put(AreaStringDestinationGeneral,2);
				
				If DesignedForEmails Then
					Email = MailoutsAndNotificationsToCustomers.AddressStringFromArray(DSAddressesArray, Chars.LF);
					If IsBlankString(Email) Then
							TableArea = ScopeStringAddresseeEmail.Areas.EmailAddressee; // SpreadsheetDocumentRange
							TableArea.TextColor = StyleColors.ErrorNoteText;
							Email = NStr("vi = 'chưa chỉ ra';
										|ru = 'не указаны';
										|en = 'not specified'; fa = 'مشخص نشده';
										|it = 'non indicate';
										|pl = 'nie określone';
										|tr = 'belirtilmedi'");
					Else
							AddresseeEmailTableArea = ScopeStringAddresseeEmail.Areas.EmailAddressee; // SpreadsheetDocumentRange
							SubscriberTableArea    = ScopeStringSubscriberGeneral.Areas.Subscriber; // SpreadsheetDocumentRange
							TableArea.TextColor  = SubscriberTableArea.TextColor;
					EndIf;
					ScopeStringAddresseeEmail.Parameters.Email = Email;
					ScopeStringAddresseeEmail.Parameters.ContactDetailsKindForEmails =
					                      MailoutsAndNotificationsToCustomers.AddressStringFromArray(ArrayOfKiTypesForEmails, Chars.LF);
					ScopeStringAddresseeEmail.Parameters.Details = AddresseeSelection.SubscriptionRecipient;
					ReportTable.Join(ScopeStringAddresseeEmail);
				EndIf;
			
				If DesignedForSMSMessage Then
					Phone = MailoutsAndNotificationsToCustomers.AddressStringFromArray(ArrayOfPhoneNumbers_, Chars.LF);
					If IsBlankString(Phone) Then
						
						AreaOfAddresseePhoneTable = AreaStringAddresseePhoneNumber.Areas.AddresseePhone; // SpreadsheetDocumentRange
						AreaOfAddresseePhoneTable.TextColor = StyleColors.ErrorNoteText;
						Phone = NStr("vi = 'chưa chỉ ra';
									|ru = 'не указаны';
									|en = 'not specified'; fa = 'مشخص نشده';
									|it = 'non indicate';
									|pl = 'nie określone';
									|tr = 'belirtilmedi'");
						
					Else
						AreaOfAddresseePhoneTable = AreaStringAddresseePhoneNumber.Areas.AddresseePhone; // SpreadsheetDocumentRange
						SubscriberTableArea      = ScopeStringSubscriberGeneral.Areas.Subscriber; // SpreadsheetDocumentRange
						AreaOfAddresseePhoneTable.TextColor = SubscriberTableArea.TextColor;
					EndIf;
					
					AreaStringAddresseePhoneNumber.Parameters.Phone = Phone;
					AreaStringAddresseePhoneNumber.Parameters.ContactDetailsKindForSMSMessage =
					                     MailoutsAndNotificationsToCustomers.AddressStringFromArray(ArrayOfKiTypesForSMS, Chars.LF);
					AreaStringAddresseePhoneNumber.Parameters.Details = AddresseeSelection.SubscriptionRecipient;
					ReportTable.Join(AreaStringAddresseePhoneNumber);
				EndIf;
				
			Else
				
				ScopeStringSubscriberGeneral.Parameters.ToWhomMessagesWillBeSent = TextTo;
				ScopeStringSubscriberGeneral.Parameters.Details = Subscription;
				ReportTable.Put(ScopeStringSubscriberGeneral, 1);
				
				If DesignedForEmails Then
					
					EmailSubscriberTableArea = ScopeStringSubscriberEmail.Areas.EmailSubscriber; // SpreadsheetDocumentRange
					SubscriberGeneralTableArea = ScopeStringSubscriberGeneral.Areas.Subscriber; // SpreadsheetDocumentRange
					Email = MailoutsAndNotificationsToCustomers.AddressStringFromArray(DSAddressesArray, Chars.LF);
					If IsBlankString(Email) Then
						If SendToCustomer Then
							EmailSubscriberTableArea.TextColor = StyleColors.ErrorNoteText;
							Email = NStr("vi = 'chưa chỉ ra';
										|ru = 'не указаны';
										|en = 'not specified'; fa = 'مشخص نشده';
										|it = 'non indicate';
										|pl = 'nie określone';
										|tr = 'belirtilmedi'");
						Else
							EmailSubscriberTableArea.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
							Email = NStr("vi = '<không cần>';
										|ru = '<не требуется>';
										|en = '<not required>'; fa = '<الزامی نیست>';
										|it = '<non richiesto>';
										|pl = '<nie jest wymagane>';
										|tr = '<gerekli değil>'");
						EndIf;
					Else
						EmailSubscriberTableArea.TextColor = SubscriberGeneralTableArea.TextColor;
					EndIf;
					
					ScopeStringSubscriberEmail.Parameters.Email = Email;
					
					TableViewAreaForEmails = ScopeStringSubscriberEmail.Areas.SubscriberEmailType; // SpreadsheetDocumentRange
					If SendToCustomer Then
						TableViewAreaForEmails.TextColor = SubscriberGeneralTableArea.TextColor;
						CIKinds = MailoutsAndNotificationsToCustomers.AddressStringFromArray(ArrayOfKiTypesForEmails, Chars.LF);
					Else
						TableViewAreaForEmails.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
						CIKinds = NStr("vi = '<không cần>';
										|ru = '<не требуется>';
										|en = '<not required>'; fa = '<الزامی نیست>';
										|it = '<non richiesto>';
										|pl = '<nie jest wymagane>';
										|tr = '<gerekli değil>'");
					EndIf;
					
					ScopeStringSubscriberEmail.Parameters.ContactDetailsKindForEmails = CIKinds;
					ScopeStringSubscriberEmail.Parameters.Details = AddresseeSelection.SubscriptionRecipient;
					ReportTable.Join(ScopeStringSubscriberEmail);
					
				EndIf;
				If DesignedForSMSMessage Then
					
					SubscriberPhoneTableArea = AreaLineSubscriberPhone.Areas.SubscriberPhoneNumber; // SpreadsheetDocumentRange
					SubscriberGeneralTableArea = ScopeStringSubscriberGeneral.Areas.Subscriber; // SpreadsheetDocumentRange
					Phone = MailoutsAndNotificationsToCustomers.AddressStringFromArray(ArrayOfPhoneNumbers_, Chars.LF);
					If IsBlankString(Phone) Then
						If SendToCustomer Then
							SubscriberPhoneTableArea.TextColor = StyleColors.ErrorNoteText;
							Phone = NStr("vi = 'chưa chỉ ra';
										|ru = 'не указаны';
										|en = 'not specified'; fa = 'مشخص نشده';
										|it = 'non indicate';
										|pl = 'nie określone';
										|tr = 'belirtilmedi'");
						Else
							SubscriberPhoneTableArea.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
							Phone = NStr("vi = '<không cần>';
										|ru = '<не требуется>';
										|en = '<not required>'; fa = '<الزامی نیست>';
										|it = '<non richiesto>';
										|pl = '<nie jest wymagane>';
										|tr = '<gerekli değil>'");
						EndIf;
					Else
						SubscriberPhoneTableArea.TextColor = SubscriberGeneralTableArea.TextColor;
					EndIf;
					
					AreaLineSubscriberPhone.Parameters.Phone = Phone;
					
					AreaOfSubscriberTableViewKiForSMS = AreaLineSubscriberPhone.Areas.SubscriberTypeOfKIForSMS; // SpreadsheetDocumentRange
					SubscriberGeneralTableArea = ScopeStringSubscriberGeneral.Areas.Subscriber; // SpreadsheetDocumentRange
					
					If SendToCustomer Then
						AreaOfSubscriberTableViewKiForSMS.TextColor = SubscriberGeneralTableArea.TextColor;
						CIKinds = MailoutsAndNotificationsToCustomers.AddressStringFromArray(ArrayOfKiTypesForSMS, Chars.LF);
					Else
						AreaOfSubscriberTableViewKiForSMS.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
					EndIf;
					
					AreaLineSubscriberPhone.Parameters.ContactDetailsKindForSMSMessage = CIKinds;
					AreaLineSubscriberPhone.Parameters.Details = AddresseeSelection.SubscriptionRecipient;
					ReportTable.Join(AreaLineSubscriberPhone);
					
				EndIf;
				
				ReportTable.StartRowGroup("Subscriber", False);
				
			EndIf;
			
		EndDo;
		
		ReportTable.EndRowGroup();
		LineNumber = LineNumber + 1;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SuspendSubscriptions(ArrayOfSubscriptions)
	
	Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.UnsubscribeForArray(ArrayOfSubscriptions);
	GenerateReport();
	
EndProcedure

&AtClient
Procedure SelectionOfSelectionPartnersAtClosing(AddressInTempStorage, AdditionalParameters) Export
	
	If ValueIsFilled(AddressInTempStorage) Then
		AddSelectionPartnersOnServer(AddressInTempStorage);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddSelectionPartnersOnServer(AddressInTempStorage)
	
	MailoutsAndNotificationsToCustomers.AddSubscribersBySelection(AddressInTempStorage, GroupOfMailoutsAndNotifications,
	                                                        DesignedForSMSMessage, DesignedForEmails);
	GenerateReport();
	
EndProcedure


#EndRegion

