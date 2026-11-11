#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("BulkEmail") 
		Or Not TypeOf(Parameters.BulkEmail) = Type("DocumentRef.MailoutToCustomers")
		Or Parameters.BulkEmail.IsEmpty() Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	// If there is no access right to the "Interaction" subsystem, then there is nothing to show.
	If Not AccessRight("View", Metadata.DocumentJournals.Interactions) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Bạn không có quyền xem báo cáo về các chứng từ đã tạo để gửi hàng loạt.';
												|ru = 'У вас нет прав на просмотр отчета по созданным документам рассылки.';
												|en = 'You are not authorized to view the report on the created mailout documents.'; fa = 'You are not authorized to view the report on the created mailout documents.';
												|it = 'Non avete il diritto di consultare il report sui documenti di mailing creati.';
												|pl = 'Nie masz uprawnień do wyświetlania raportu na temat utworzonych dokumentów newslettera.';
												|tr = 'Oluşturulan dağıtım belgeleriyle ilgili raporu görüntüleme yetkiniz bulunmamaktadır.'"));
		Cancel = True;
		Return;
	EndIf;
	
	BulkEmail = Parameters.BulkEmail;

	GenerateReport();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	GenerateReport();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessRequestTextMailingRecipients(MailingData, Query, ThereIsSelectionOnLayout)

	TextUnion =" 
	|
	|UNION
	|";
		
	TheTextToPut = "INTO Recipients";
		
	If MailingData.Forced Then
		
		QueryTextPartners = "";
		QueryTextContactPersons = "";
		
		If MailingData.SendToCustomer Then
			
			QueryTextPartners = "
			|SELECT DISTINCT
			|	Partners.Ref AS Recipient,
			|	ISNULL(PartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
			|	&TypeOfPartnerContactInformation AS ContactInformationKind,
			|	Partners.DescriptionFull AS RecipientPresentation1
			|	,&TheTextToPut
			|FROM
			|	Catalog.Partners AS Partners
			|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
			|		ON (PartnersContactInformation.Ref = Partners.Ref)
			|			AND (PartnersContactInformation.Kind = &TypeOfPartnerContactInformation)
			|		AND &SelectionConnection
			|WHERE
			|	NOT Partners.DeletionMark";
			
			If ThereIsSelectionOnLayout Then
				SelectionGuideText ="INNER JOIN PartnerFilter AS PartnerFilter
				                         |ON Partners.Ref = PartnerFilter.Partner";
			Else
				SelectionGuideText = "";
			EndIf;
			
			QueryTextPartners = StrReplace(QueryTextPartners, "AND &SelectionConnection", SelectionGuideText);
			QueryTextPartners = StrReplace(QueryTextPartners, ",&TheTextToPut", TheTextToPut);
			
			Query.SetParameter("TypeOfPartnerContactInformation",
			                           ?(MailingData.DesignedForEmails,
			                             MailingData.PartnerSContactDetailsKindForEmails,
			                             MailingData.PartnerSContactDetailsKindForSMSMessage));
			
		EndIf;
		
		If MailingData.SendToRoleContactPersons Then
			
			QueryTextContactPersons ="
			|SELECT DISTINCT
			|	ContactPersonsForPartners.Ref AS Recipient,
			|	ISNULL(ContactPersonsOfPartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
			|	&TypeOfContactInformationOfContactPerson AS ContactInformationKind,
			|	ContactPersonsForPartners.Description AS RecipientPresentation1
			|	,&TheTextToPut
			|FROM
			|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
			|		ON (ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref)
			|			AND (ContactPersonsOfPartnersContactInformation.Kind = &TypeOfContactInformationOfContactPerson)
			|		INNER JOIN Catalog.ContactPersonsForPartners.ContactPersonRoles AS ContactPersonsOfPartnersRoleOfContactPerson
			|		ON ContactPersonsForPartners.Ref = ContactPersonsOfPartnersRoleOfContactPerson.Ref
			|			AND (ContactPersonsOfPartnersRoleOfContactPerson.ContactRole = &ContactRole)
			|		AND &SelectionConnection
			|WHERE
			|	NOT ContactPersonsForPartners.DeletionMark";
			
			If ThereIsSelectionOnLayout Then
				SelectionGuideText ="INNER JOIN PartnerFilter AS PartnerFilter
				                         |ON ContactPersonsForPartners.Owner = PartnerFilter.Partner";
			Else
				SelectionGuideText = "";
			EndIf;
			
			QueryTextContactPersons = StrReplace(QueryTextContactPersons, "AND &SelectionConnection", SelectionGuideText);
			If MailingData.SendToCustomer Then
				QueryTextContactPersons = StrReplace(QueryTextContactPersons, ",&TheTextToPut", "");
			Else
				QueryTextContactPersons = StrReplace(QueryTextContactPersons, ",&TheTextToPut", TheTextToPut);
			EndIf;
			
			Query.SetParameter("TypeOfContactInformationOfContactPerson",
			                          ?(MailingData.DesignedForEmails,
			                            MailingData.ContactPersonSContactDetailsKindForEmails,
			                            MailingData.ContactPersonSContactDetailsKindForSMSMessage));
			Query.SetParameter("ContactRole", MailingData.ContactRole);
			
		EndIf;
		
		If (Not MailingData.SendToCustomer) And (Not MailingData.SendToRoleContactPersons) Then
			Query.Text = "";
		Else
			TextIsNeeded = MailingData.SendToCustomer And MailingData.SendToRoleContactPersons;
			Query.Text = Query.Text + QueryTextPartners + ?(TextIsNeeded, TextUnion, "") + QueryTextContactPersons;
		EndIf;
		
	Else // By subscriptions
		
		QueryTextSubscribers = "
		|SELECT
		|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS Recipient,
		|	ISNULL(PartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
		|	CASE
		|		WHEN &DesignedForLetters
		|			THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails
		|			ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage
		|	END AS ContactInformationKind,
		|	Partners.DescriptionFull AS RecipientPresentation1
		|INTO Recipients
		|FROM
		|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = Partners.Ref
		|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
		|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnersContactInformation.Ref
		|			AND (CASE
		|				WHEN &DesignedForLetters
		|					THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails = PartnersContactInformation.Kind
		|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage = PartnersContactInformation.Kind
		|			END)
		|		AND &SelectionConnection
		|WHERE
		|	SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|	AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson,
		|	ISNULL(ContactPersonsOfPartnersContactInformation.Presentation, """"),
		|	CASE
		|		WHEN &DesignedForLetters
		|		THEN SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForMails
		|			ELSE SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForSMSMessage
		|	END AS ContactInformationKind,
		|	ContactPersonsForPartners.Description
		|FROM
		|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications.ContactPersons AS SubscriptionsToCustomerMailoutsAndNotificationsContactPersons
		|		LEFT JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.Ref = SubscriptionsToCustomerMailoutsAndNotifications.Ref
		|		AND &SelectionConnection
		|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
		|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson = ContactPersonsOfPartnersContactInformation.Ref
		|			AND (CASE
		|				WHEN &DesignedForLetters
		|					THEN SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForMails = ContactPersonsOfPartnersContactInformation.Kind
		|				ELSE SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForSMSMessage = ContactPersonsOfPartnersContactInformation.Kind
		|			END)
		|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson = ContactPersonsForPartners.Ref
		|WHERE
		|	NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications";
		
		Query.SetParameter("GroupOfMailoutsAndNotifications", MailingData.GroupOfMailoutsAndNotifications);
		
		If ThereIsSelectionOnLayout Then
			SelectionGuideText ="INNER JOIN PartnerFilter AS PartnerFilter
			                         |ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnerFilter.Partner";
		Else
			SelectionGuideText = "";
		EndIf;
		
		QueryTextSubscribers = StrReplace(QueryTextSubscribers, "AND &SelectionConnection", SelectionGuideText);
		Query.Text = Query.Text + QueryTextSubscribers;
		
	EndIf;
	
	QueryTextAdditionalRecipients = "
	|SELECT DISTINCT
	|	MailoutToCustomersAdditionalRecipients.Contact AS Recipient,
	|	MailoutToCustomersAdditionalRecipients.ContactInformation AS ContactInformationPresentation,
	|	VALUE(Catalog.ContactInformationKinds.EmptyRef) AS ContactInformationKind,
	|	CASE
	|		WHEN MailoutToCustomersAdditionalRecipients.Contact REFS Catalog.Partners
	|			THEN ISNULL(Partners.DescriptionFull, """")
	|		ELSE ISNULL(ContactPersonsForPartners.Description, """")
	|	END AS RecipientPresentation1
	|	,&TheTextToPut
	|FROM
	|	Document.MailoutToCustomers.AdditionalRecipients AS MailoutToCustomersAdditionalRecipients
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON MailoutToCustomersAdditionalRecipients.Contact = Partners.Ref
	|		LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|		ON MailoutToCustomersAdditionalRecipients.Contact = ContactPersonsForPartners.Ref
	|WHERE
	|	MailoutToCustomersAdditionalRecipients.Ref = &MailoutToCustomers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	If IsBlankString(Query.Text) Then
		QueryTextAdditionalRecipients = StrReplace(QueryTextAdditionalRecipients, ",&TheTextToPut", TheTextToPut);
	Else
		QueryTextAdditionalRecipients = StrReplace(QueryTextAdditionalRecipients, ",&TheTextToPut", "");
	EndIf;
	
	Query.Text = Query.Text + ?(IsBlankString(Query.Text), "", TextUnion) + QueryTextAdditionalRecipients;
	
EndProcedure

&AtServer
Procedure ProcessRequestTextMailingListAddresseesSurveyAssignments(Data, TheseGrounds, Query, ThereIsSelectionOnLayout)
	
	If Data.Forced Then
		
		If TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.Partners") And Data.SendToCustomer Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents = "
				|SELECT DISTINCT ALLOWED
				|	Partners.Ref AS Recipient,
				|	ISNULL(PartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	&TypeOfPartnerContactInformation AS ContactInformationKind,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Catalog.Partners AS Partners 
				|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		ON PartnersContactInformation.Ref = Partners.Ref
				|			AND (PartnersContactInformation.Kind = &TypeOfPartnerContactInformation)
				|			AND (NOT Partners.DeletionMark)
				|		AND &SelectionConnection";
				
			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT ALLOWED
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	ISNULL(PartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	&TypeOfPartnerContactInformation AS ContactInformationKind,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		ON PollPurposeRespondents.Respondent = PartnersContactInformation.Ref
				|			AND (PartnersContactInformation.Kind = &TypeOfPartnerContactInformation)
				|		AND &SelectionConnection
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON PollPurposeRespondents.Respondent = Partners.Ref
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose"
				
			EndIf;
			
			MailoutsAndNotificationsToCustomers.ProcessRequestTextForDistributionPartners(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);
			
		ElsIf TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.ContactPersonsForPartners") And Data.SendToAContactPersonOfANotificationObject Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents ="
				|SELECT DISTINCT ALLOWED
				|	ContactPersonsForPartners.Ref AS Recipient,
				|	ISNULL(ContactPersonsOfPartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	&TypeOfContactInformationOfContactPerson AS ContactInformationKind,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		ON ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref
				|			AND (ContactPersonsOfPartnersContactInformation.Kind = &TypeOfContactInformationOfContactPerson)
				|			AND (NOT ContactPersonsForPartners.DeletionMark)
				|		AND &SelectionConnection
				|";
				
			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT ALLOWED
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	ISNULL(ContactPersonsOfPartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	&TypeOfContactInformationOfContactPerson AS ContactInformationKind,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		ON PollPurposeRespondents.Respondent = ContactPersonsOfPartnersContactInformation.Ref
				|			AND (ContactPersonsOfPartnersContactInformation.Kind = &TypeOfContactInformationOfContactPerson)
				|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		ON PollPurposeRespondents.Respondent = ContactPersonsForPartners.Ref
				|		AND &SelectionConnection
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON ContactPersonsForPartners.Owner = Partners.Ref
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose";
				
			EndIf;
			
			MailoutsAndNotificationsToCustomers.ProcessRequestTextByMailingContactPersons(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);
			
		EndIf;
		
	Else
		
		Query.SetParameter("GroupOfMailoutsAndNotifications", Data.GroupOfMailoutsAndNotifications);
		
		If TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.Partners")  Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents = "
				|SELECT DISTINCT ALLOWED
				|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS Recipient,
				|	ISNULL(PartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails 
				|			ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage 
				|	END AS ContactInformationKind,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = Partners.Ref
				|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnersContactInformation.Ref
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails = PartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage = PartnersContactInformation.Kind
				|			END)
				|		AND &SelectionConnection
				|WHERE
				|	SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
				|	AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications";
				
			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT ALLOWED
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	ISNULL(PartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails 
				|			ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage 
				|	END AS ContactInformationKind,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|			ON PollPurposeRespondents.Respondent = SubscriptionsToCustomerMailoutsAndNotifications.Owner
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
				|				AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications			
				|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		ON PollPurposeRespondents.Respondent = PartnersContactInformation.Ref
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails = PartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage = PartnersContactInformation.Kind
				|			END)
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON PollPurposeRespondents.Respondent = Partners.Ref
				|		AND &SelectionConnection
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose"
				
			EndIf;
			
			MailoutsAndNotificationsToCustomers.ProcessRequestTextForDistributionPartners(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);
			
		ElsIf TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.ContactPersonsForPartners") Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents = "
				|SELECT DISTINCT ALLOWED
				|	ContactPersonsForPartners.Ref AS Recipient,
				|	ISNULL(ContactPersonsOfPartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails
				|			ELSE SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage
				|	END AS ContactInformationKind,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|		INNER JOIN Catalog.Partners AS CatalogPartners
				|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = CatalogPartners.Ref
				|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		ON (CatalogPartners.Ref = ContactPersonsForPartners.Owner)
				|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		ON (ContactPersonsForPartners.Ref = ContactPersonsOfPartnersContactInformation.Ref)
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails = ContactPersonsOfPartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage = ContactPersonsOfPartnersContactInformation.Kind
				|			END)
				|		AND &SelectionConnection
				|WHERE
				|	NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications";

			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT ALLOWED
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	ISNULL(ContactPersonsOfPartnersContactInformation.Presentation, """") AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails
				|			ELSE SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage
				|	END AS ContactInformationKind,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|INTO Recipients
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|	INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		ON PollPurposeRespondents.Respondent = ContactPersonsForPartners.Ref
				|	INNER JOIN Catalog.Partners AS Partners
				|		ON ContactPersonsForPartners.Owner = Partners.Ref
				|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|			ON Partners.Ref = SubscriptionsToCustomerMailoutsAndNotifications.Owner
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
				|				AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
				|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		ON ContactPersonsForPartners.Ref = ContactPersonsOfPartnersContactInformation.Ref
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails = ContactPersonsOfPartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage = ContactPersonsOfPartnersContactInformation.Kind
				|			END)
				|		AND &SelectionConnection
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose"
				
			EndIf;
			
			MailoutsAndNotificationsToCustomers.ProcessRequestTextByMailingContactPersons(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);
		
		EndIf;
		
	EndIf;
	
	Query.Text = Query.Text + QueryTextRespondents;
	Query.Text = Query.Text + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	Query.SetParameter("PollPurpose", TheseGrounds.Ref); 
	
EndProcedure

&AtServer
Procedure GenerateReport()
	
	MailingData = MailingDataToClients(BulkEmail);
	
	ReportTable.Clear();
	ReportTable.FitToPage = True;
	Template = Documents.MailoutToCustomers.GetTemplate("MailoutStatus");
	
	EmptyStringArea = Template.GetArea("IsBlankString");
	ReportTable.Put(EmptyStringArea);
	
	ReportTable.StartRowGroup("Legend");
	
	// Legend Output
	AreaLegend = Template.GetArea("StringLegend");
	AreaLegend.Parameters.LegendText = LegendText(MailingData);
	ReportTable.Put(AreaLegend);
	
	ReportTable.EndRowGroup();
	
	// The output caps
	SectionHeader = Template.GetArea("StringHeader1");
	If MailingData.DesignedForEmails Then
		SectionHeader.Parameters.ContactInformation = NStr("vi = 'Địa chỉ E-mail';
															|ru = 'Адреса электронной почты';
															|en = 'Email addresses'; fa = 'Email addresses';
															|it = 'Indirizzi di posta elettronica';
															|pl = 'Adresy poczty elektronicznej';
															|tr = 'E-postalar'");
	Else
		SectionHeader.Parameters.ContactInformation = NStr("vi = 'Điện thoại';
															|ru = 'Телефоны';
															|en = 'Phones'; fa = 'تلفن‌ها';
															|it = 'Numeri di telefono';
															|pl = 'Phones';
															|tr = 'Telefonlar'");
	EndIf;
	
	ReportTable.Put(SectionHeader);
	
	If TypeOf(MailingData.Basis) = Type("DocumentRef.PollPurpose") And ValueIsFilled(MailingData.Basis) Then
		TheseGrounds = MailoutsAndNotificationsToCustomers.DataAndPurposeOfSurveys(MailingData.Basis);
		If TheseGrounds.RespondentsType = Catalogs.Users.EmptyRef() Then
			Raise NStr("vi = 'Trong ""Mục đích khảo sát"" đã chỉ định sai kiểu người được khảo sát. Đối với người sử dụng không thể sử dụng gửi hàng loạt cho khách hàng.';
						|ru = 'В ""Назначении опросов"" указан некорректный тип респондентов. Для пользователей не может использоваться рассылка клиентам.';
						|en = 'There is wrong type of respondents indicated in the ""Purpose of survey"". For users, mailout to customers cannot be used.'; fa = 'There is wrong type of respondents indicated in the ""Purpose of survey"". For users, mailout to customers cannot be used.';
						|it = 'Nel campo ""Scopo dei sondaggi"" è indicato il tipo di intervistati scorretto. Per gli utenti non può essere utilizzato il mailing ai clienti.';
						|pl = 'W ""Przeznaczeniu ankiet"" podano nieprawidłowy rodzaj respondentów. Dla użytkowników nie może być wykorzystywana rozsyłka klientom.';
						|tr = '""Anketlerin Atanması"" bölümünde yanlış yanıtlayıcı türü belirtildi. Kullanıcılar için müşterilere dağıtım kullanılamaz.'");
		EndIf
	Else
		TheseGrounds = Undefined;
	EndIf;
	
	// Request formation
	SelectionOnBasisOf_ = False;
	Query = MailoutsAndNotificationsToCustomers.RequestSelectionByLayout(MailingData, SelectionOnBasisOf_);
	ThereIsSelectionOnLayout = Not IsBlankString(Query.Text);
	
	If TheseGrounds <> Undefined And SelectionOnBasisOf_ Then
		
		If TypeOf(TheseGrounds.Ref) = Type("DocumentRef.PollPurpose") Then
			
			ProcessRequestTextMailingListAddresseesSurveyAssignments(MailingData, TheseGrounds, Query, ThereIsSelectionOnLayout);
			
		EndIf;
		
	Else
		
		ProcessRequestTextMailingRecipients(MailingData, Query, ThereIsSelectionOnLayout);
		
	EndIf;
	
	Query.SetParameter("DesignedForLetters", MailingData.DesignedForEmails);
	Query.SetParameter("MailoutToCustomers", MailingData.BulkEmail);
	
	If MailingData.DesignedForEmails Then
		
		RequestTextInteractionDocuments = "
		|SELECT
		|	Recipients.Recipient AS Recipient,
		|	Recipients.ContactInformationPresentation,
		|	Recipients.ContactInformationKind,
		|	Recipients.RecipientPresentation1,
		|	ISNULL(InteractionsContacts.Interaction, UNDEFINED) AS Interaction,
		|	ISNULL(Interactions.OutgoingEmailStatus, UNDEFINED) AS State,
		|	ISNULL(Interactions.Date, UNDEFINED) AS DocumentDate,
		|	ISNULL(Interactions.Number, UNDEFINED) AS DocumentNumber
		|FROM
		|	Recipients AS Recipients
		|		LEFT JOIN InformationRegister.InteractionsContacts AS InteractionsContacts
		|			INNER JOIN DocumentJournal.Interactions AS Interactions
		|			ON InteractionsContacts.Interaction = Interactions.Ref
		|				AND (Interactions.InteractionBasis = &MailoutToCustomers)
		|				AND (NOT Interactions.DeletionMark)
		|		ON Recipients.Recipient = InteractionsContacts.Contact
		|TOTALS BY
		|	Recipient";
		
	Else
		
		RequestTextInteractionDocuments = "
		|SELECT
		|	MailingRecipients.Recipient AS Recipient,
		|	MailingRecipients.ContactInformationPresentation,
		|	MailingRecipients.ContactInformationKind,
		|	MailingRecipients.RecipientPresentation1,
		|	ISNULL(SMSMessageRecipients.Ref, UNDEFINED) AS Interaction,
		|	ISNULL(SMSMessageRecipients.MessageState, UNDEFINED) AS State,
		|	ISNULL(SMSMessageRecipients.Ref.Date, UNDEFINED) AS DocumentDate,
		|	ISNULL(SMSMessageRecipients.Ref.Number, UNDEFINED) AS DocumentNumber
		|FROM
		|	Recipients AS MailingRecipients
		|		LEFT JOIN Document.SMSMessage.Recipients AS SMSMessageRecipients
		|		ON MailingRecipients.Recipient = SMSMessageRecipients.Contact
		|			AND MailingRecipients.ContactInformationPresentation = SMSMessageRecipients.HowToContact
		|			AND SMSMessageRecipients.Ref.InteractionBasis = &MailoutToCustomers
		|TOTALS BY
		|	Recipient";
		
	EndIf;
		
	Query.Text = Query.Text + RequestTextInteractionDocuments;
		
	AddresseeSelection = Query.Execute().Select(QueryResultIteration.ByGroups);
	LineNumber = 1;
	
	KIArray      = New Array;
	ArrayOfKiTypes = New Array;
	SubscriberArea = Template.GetArea("SubscriberLine");

	While AddresseeSelection.Next() Do
		
		KIArray.Clear();
		ArrayOfKiTypes.Clear();
		
		DetailsSelection = AddresseeSelection.Select();
		While DetailsSelection.Next() Do
			
			MailoutsAndNotificationsToCustomers.AddToArray(KIArray, DetailsSelection.ContactInformationPresentation);
			MailoutsAndNotificationsToCustomers.AddToArray(ArrayOfKiTypes, DetailsSelection.ContactInformationKind);
			Interaction = ?(ValueIsFilled(Interaction), Interaction,DetailsSelection.Interaction);
			DocumentDate  = ?(ValueIsFilled(DocumentDate), DocumentDate, DetailsSelection.DocumentDate);
			DocumentNumber = ?(ValueIsFilled(DocumentNumber), DocumentNumber, DetailsSelection.DocumentNumber);
			State      = DetailsSelection.State;
			
		EndDo;
		
		SubscriberArea.Parameters.LineNumber                 = LineNumber;
		SubscriberArea.Parameters.Subscriber                   = AddresseeSelection.Recipient;
		SubscriberArea.Parameters.ContactInformationKind     = MailoutsAndNotificationsToCustomers.AddressStringFromArray(ArrayOfKiTypes, Chars.LF);;
		SubscriberArea.Parameters.InteractionsDocument      = Interaction;
		SubscriberArea.Parameters.InteractionPresentation = InteractionPresentation(Interaction, DocumentNumber, DocumentDate);
		SubscriberArea.Parameters.State                   = State;
		
		ContactInformation  = MailoutsAndNotificationsToCustomers.AddressStringFromArray(KIArray, Chars.LF);
		If IsBlankString(ContactInformation) Then
			SubscriberArea.Areas.SubscriberContactInformation["TextColor"] = StyleColors.ErrorNoteText;
			ContactInformation = NStr("vi = 'chưa chỉ ra';
										|ru = 'не указан';
										|en = 'not specified'; fa = 'مشخص نشده';
										|it = 'non specificato';
										|pl = 'nie określony';
										|tr = 'belirtilmedi'");
		Else
			SubscriberArea.Areas.SubscriberContactInformation["TextColor"] = SubscriberArea.Areas.Subscriber["TextColor"];
		EndIf;
		
		SubscriberArea.Parameters.ContactInformation    = ContactInformation;
		ReportTable.Put(SubscriberArea);
		
		LineNumber    = LineNumber + 1;
		Interaction = Undefined;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function MailingDataToClients(MailoutToCustomers)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	MailoutToCustomers.Ref AS BulkEmail,
	|	MailoutToCustomers.MailingDate,
	|	MailoutToCustomers.UpdateDate,
	|	MailoutToCustomers.Basis,
	|	MailoutToCustomers.GroupOfMailoutsAndNotifications,
	|	MailoutToCustomers.DesignedForEmails,
	|	MailoutToCustomers.DesignedForSMSMessage,
	|	MailoutToCustomers.AddresseeFilter,
	|	MailoutToCustomers.Status,
	|	MailoutToCustomers.EmployeeResponsible,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.ContactPersonSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.ContactPersonSContactDetailsKindForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons,
	|	GroupsOfMailoutsAndNotifications.ContactRole,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
	|FROM
	|	Document.MailoutToCustomers AS MailoutToCustomers
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON MailoutToCustomers.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	MailoutToCustomers.Ref = &BulkEmail";
	
	Query.SetParameter("BulkEmail", MailoutToCustomers);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Selection;

EndFunction

&AtServerNoContext
Function InteractionPresentation(Interaction, DocumentNumber, DocumentDate)
	
	If Interaction = Undefined Then
		Return "";
	EndIf;

	Presentation = NStr("vi = '%1 số %2 ngày %3.';
						|ru = '%1 № %2 от %3.';
						|en = '%1 No. %2 from %3.'; fa = '%1 No. %2 from %3.';
						|it = '%1 № %2 del %3.';
						|pl = '%1 nr %2 z dnia %3.';
						|tr = '%3 tarihli %2 numaralı %1.'");
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
	                Presentation,
	                ?(TypeOf(Interaction) = Type("DocumentRef.SMSMessage"), 
	                                                 NStr("vi = 'Tin nhắn SMS';
															|ru = 'Сообщение SMS';
															|en = 'SMS message'; fa = 'SMS message';
															|it = 'Messaggio SMS';
															|pl = 'Wiadomość SMS';
															|tr = 'SMS'"),
	                                                 NStr("vi = 'E-mail đi';
															|ru = 'Исходящее письмо';
															|en = 'Outgoing email'; fa = 'ایمیل خروجی';
															|it = 'Messaggio in uscita';
															|pl = 'List wychodzący';
															|tr = 'Giden e-posta'")),
	                ObjectsPrefixesClientServer.NumberForPrinting(DocumentNumber),
	                Format(DocumentDate, "DLF=DDT"));
	
	Return Presentation;

EndFunction

&AtServerNoContext
Function LegendText(MailingData)

	LegendText = "";
	
	If MailingData.Status = Enums.CustomerMailoutStatuses.Draft Then
		
		LegendText = NStr("vi = 'Gửi hàng loạt đang có trạng thái ""Bản nháp"". Báo cáo hiển thị người nhận hàng loạt có thể và thông tin liên hệ của họ.
		                           |Nếu thông tin liên hệ chưa được chỉ định hoặc sai định dạng thì sẽ không gửi hàng loạt cho những người nhận này
		                           |. Bạn có thể thay đổi thông tin liên hệ cần thiết bằng cách ""nhấp đúp"" vào người nhận hàng loạt.';
		                           |ru = 'Рассылка находится в статусе ""Черновик"". В отчет выведены возможные адресаты рассылки и их контактная информация.
		                           |В случае если контактная информация не указана или указана в некорректном формате, рассылка данным адресатам 
		                           |выполнена не будет. Вы может изменить необходимую контактную информацию, выполнив ""двойной клик"" на получателе рассылки.';
		                           |en = 'The mailout is in the ""Draft"" status. Available mailout recipients and their contact details are displayed in the report.
		                           |If contact details are not specified or specified incorrectly, mailout to these recipients
		                           |will not be sent. You can change the required contact details by double-clicking a mailout recipient.'; fa = 'The mailout is in the ""Draft"" status. Available mailout recipients and their contact details are displayed in the report.
		                           |If contact details are not specified or specified incorrectly, mailout to these recipients
		                           |will not be sent. You can change the required contact details by double-clicking a mailout recipient.';
		                           |it = 'la posta elettronica in blocco ha lo status ""Bozza"". Nel report sono visualizzati i possibili destinatari e i loro dati di contatto. 
		                           |Se i dati di contatto non sono indicati oppure sono in formato scorretto, l''invio a questi destinatari 
		                           |non verrà effettuato. Potete modificare i dati di contatto necessari facendo un doppio clic sul destinatario dell''invio.';
		                           |pl = 'Newsletter ma status ""Wersja robocza"". w raporcie wyświetlane są potencjalni odbiorcy i ich dane kontaktowe.
		                           |Jeżeli dane kontaktowe nie są podane lub mają niepoprawny format, newsletter nie zostanie wysłany do tych odbiorców 
		                           |. Możesz zmienić niezbędne informacje kontaktowe, wykonując ""podwójne kliknięcie"" na adresacie wiadomości.';
		                           |tr = 'Bülten ""Taslak"" durumundadır. Rapora, olası bülten alıcıları ve iletişim bilgileri girildi.
		                           |İletişim bilgileri belirtilmezse veya yanlış biçimde belirtilirse, bu alıcılara 
		                           |bülten gönderilmez. Haber bülteninin alıcısına ""çift tıklayarak"" gerekli iletişim bilgilerini değiştirebilirsiniz.'");
		
	ElsIf MailingData.Status = Enums.CustomerMailoutStatuses.ForDispatch Then
		
		LegendText = NStr("vi = 'Gửi hàng loạt đang có trạng thái ""Cần gửi"" và dự tính %1
		                          |Báo cáo hiển thị những người nhận hợp lệ và thông tin liên hệ của họ.
		                          |Nếu chưa chỉ ra thông tin liên hệ hoặc sai định dạng thì sẽ không 
		                          |gửi hàng loạt cho những người nhận này. Bạn vẫn có thể thay đổi thông tin liên hệ có dạng cần thiết bằng cách ""nhấp đúp"" vào người nhận hàng loạt.';
		                          |ru = 'Рассылка находится в статусе ""К отправке"" и запланирована %1
		                          |В отчет выведены возможные адресаты рассылки и их контактная информация.
		                          |В случае если контактная информация не указана или указана в некорректном формате, рассылка данным адресатам 
		                          |выполнена не будет. Вы еще можете изменить  контактную информацию необходимого вида, выполнив ""двойной клик"" на получателе рассылки.';
		                          |en = 'Mailout has the ""For dispatch"" status and is scheduled for %1 ""
		                          |""The report contains available recipients and their contact details.
		                          |If contact details are not specified or specified incorrectly, mailout to these recipients
		                          |will not be performed. You still can change the contact details of the required kind by double-clicking a mailout recipient.'; fa = 'Mailout has the ""For dispatch"" status and is scheduled for %1 ""
		                          |""The report contains available recipients and their contact details.
		                          |If contact details are not specified or specified incorrectly, mailout to these recipients
		                          |will not be performed. You still can change the contact details of the required kind by double-clicking a mailout recipient.';
		                          |it = 'La posta elettronica in blocco ha lo status ""Da inviare"" ed è prevista %1
		                          |Nel report sono visualizzati i possibili destinatari e i loro dati di contatto.
		                          |Se i dati di contatto mancano oppure sono in formato scorretto, l''invio a questi destinatari 
		                          |non verrà effettuato. È possibile ancora modificare i dati di contatto del tipo necessario facendo un doppio clic sul destinatario dell''invio.';
		                          |pl = 'Newsletter ma status ""Do wysłania"" i jest zaplanowany na %1
		                          |. w raporcie wyświetlane są potencjalni odbiorcy i ich dane kontaktowe.
		                          |Jeżeli dane kontaktowe nie są podane lub mają niepoprawny format, newsletter nie zostanie wysłany do tych odbiorców 
		                          |. Możesz zmienić niezbędne informacje kontaktowe, wykonując ""podwójne kliknięcie"" na adresacie wiadomości.';
		                          |tr = 'Bülten, ""Gönderilecek"" durumunda ve planlandı %1
		                          |Rapora, olası bülten alıcıları ve iletişim bilgileri girildi.
		                          |İletişim bilgileri belirtilmezse veya yanlış biçimde belirtilirse, bu alıcılara 
		                          |bülten gönderilmez. Haber bülteninin alıcısına ""çift tıklayarak"" gerekli iletişim bilgilerini değiştirebilirsiniz.'");
		
		If MailingData.UpdateDate = Date(1, 1, 1) Then
			TextPeriod = NStr("vi = 'vào';
								|ru = 'на';
								|en = 'to'; fa = 'تا';
								|it = 'per';
								|pl = 'na';
								|tr = 'ilişkin'") + " " + Format(MailingData.MailingDate,"DLF=DD");
		Else
			
			If MailingData.UpdateDate < CurrentSessionDate() Then
				LegendText = NStr("vi = 'Gửi hàng loạt đang có trạng thái ""Cần gửi"" và đã dự tính %1
				                  |Ngày cập nhật gửi hàng loạt đã quá hạn và sẽ không thực hiện.
				                  |Báo cáo hiển thị những người nhận có thể và thông tin liên hệ của họ.';
				                  |ru = 'Рассылка находится в статусе ""К отправке"" и была запланирована %1
				                  |Дата актуальности рассылки истекла и выполнена не будет.
				                  |В отчет выведены возможные адресаты рассылки и их контактная информация.';
				                  |en = 'The mailout has the ""For dispatch"" status, and was scheduled for %1
				                  |This date has expired and the mailout will not be performed.
				                  |Available mailout recipients and their contact details are displayed in the report.'; fa = 'The mailout has the ""For dispatch"" status, and was scheduled for %1
				                  |This date has expired and the mailout will not be performed.
				                  |Available mailout recipients and their contact details are displayed in the report.';
				                  |it = 'La posta elettronica in blocco ha lo status ""Da inviare"" ed è prevista %1
				                  |La data di attualità di invio è scaduta e l''invio non verrà effettuato.
				                  |Nel report sono visualizzati i possibili destinatari e i loro dati di contatto.';
				                  |pl = 'Newsletter ma status ""Do wysłania"" i była zaplanowany na %1
				                  |. Data aktualności newslettera wygasła i on nie zostanie wysłany. 
				                  |w raporcie wyświetlane są potencjalni odbiorcy i ich dane kontaktowe.';
				                  |tr = 'Bülten, ""Gönderilecek"" durumunda ve planlandı %1
				                  |Bülten tarihi doldu ve yürütülmeyecek.
				                  |Rapora, olası bülten alıcıları ve iletişim bilgileri girildi.'");
			EndIf;
			
			TextPeriod = NStr("vi = 'trong kỳ từ %1 đến hết %2';
								|ru = 'на период с %1 по %2';
								|en = 'for period from %1 to %2'; fa = 'for period from %1 to %2';
								|it = 'per il periodo da %1 a %2';
								|pl = 'na okres od %1 do %2';
								|tr = '%1 ile %2 arası bir dönem için'");
			TextPeriod = StringFunctionsClientServer.SubstituteParametersToString(TextPeriod, 
		                                                                          Format(MailingData.MailingDate,"DLF=DD"),
		                                                                          Format(MailingData.UpdateDate,"DLF=DD"));
		EndIf;
		
		LegendText = StringFunctionsClientServer.SubstituteParametersToString(LegendText, TextPeriod);
		
	ElsIf MailingData.Status = Enums.CustomerMailoutStatuses.InProcessing Then
		
		LegendText = NStr("vi = 'Gửi hàng loạt đang có trạng thái ""Đang xử lý"". Hiện tại đang tạo tin nhắn cho người nhận hàng loạt.
		                           |Báo cáo hiển thị người nhận hợp lệ và thông tin liên hệ của họ. Nếu chưa chỉ ra
		                           |thông tin liên hệ hoặc sai định dạng thì sẽ không tạo tin nhắn cho những người nhận này.';
		                           |ru = 'Рассылка находится в статусе ""Обрабатывается"". В данный момент создаются сообщения адресатам рассылки.
		                           |В отчет выведены возможные адресаты рассылки и их контактная информация. В случае если контактная информация не
		                           |указана или указана в некорректном формате, сообщения данным адресатам созданы не будут.';
		                           |en = 'The mailout has the ""In progress"" status. Messages to mailout recipients are being created.
		                           |Available mailout recipients and their contact details are displayed in the report. If contact details are not specified
		                           |or specified incorrectly, messages to these recipients will not be created.'; fa = 'The mailout has the ""In progress"" status. Messages to mailout recipients are being created.
		                           |Available mailout recipients and their contact details are displayed in the report. If contact details are not specified
		                           |or specified incorrectly, messages to these recipients will not be created.';
		                           |it = 'La posta elettronica in blocco ha lo status ""In elaborazione"". In questo momento vengono generati i messaggi per i destinatari dell''invio. 
		                           |Nel report sono visualizzati i possibili destinatari e i loro dati di contatto. Se i dati di contatto non sono
		                           |indicati oppure sono in formato scorretto, i messaggi verso questi destinatari non verranno generati.';
		                           |pl = 'Newsletter ma status ""Przetwarzanie"". W tej chwili są tworzone wiadomości dla adresatów newslettera.  
		                           |W raporcie wyświetlane są potencjalni odbiorcy i ich dane kontaktowe. Jeżeli dane kontaktowe nie
		                           |są podane lub mają niepoprawny format, newsletter nie zostanie wysłany do tych odbiorców.';
		                           |tr = 'Bülten, ""İşleniyor"" durumundadır. Şu anda bülten alıcılarına mesajlar oluşturulmaktadır.
		                           |Rapora, olası bülten alıcıları ve iletişim bilgileri girildi. İletişim bilgileri belirtilmez
		                           |ise veya yanlış biçimde belirtilirse, bu alıcılara bülten oluşturulmaz.'");
		
	ElsIf MailingData.Status = Enums.CustomerMailoutStatuses.Executed Then
		
		LegendText = NStr("vi = 'Gửi hàng loạt đang có trạng thái ""Đã thực hiện"". Đã tạo tất cả tin nhắn hợp lệ.
		                           |Không tạo thư, nếu chưa chỉ ra thông tin liên hệ hoặc sai định dạng.
		                           |Tin nhắn đã tạo có thể không có trong báo cáo này, nếu đã quá hạn lưu thư này.';
		                           |ru = 'Рассылка находится в статусе ""Выполнена"". Все возможные сообщения созданы.
		                           |Сообщения не создавались если контактная информация была не указана или указана в некорректном формате.
		                           |Созданные сообщения могут отсутствовать в данном отчете, если истек срок хранения данных сообщений.';
		                           |en = 'The mailout has the ""Completed"" status. All messages are created.
		                           |Messages were not created if contact details were not specified or were specified incorrectly.
		                           |The report may not contain the created messages if the message retention period has expired.'; fa = 'The mailout has the ""Completed"" status. All messages are created.
		                           |Messages were not created if contact details were not specified or were specified incorrectly.
		                           |The report may not contain the created messages if the message retention period has expired.';
		                           |it = 'La posta elettronica in blocco ha lo status ""Eseguito"". Tutti i messaggi possibili sono stati generati.
		                           |I messaggi non venivano generati se i dati di contatto non erano indicati oppure erano in un formato scorretto.
		                           |I messaggi generati possono non essere visualizzati in questo report se il loro termine di archiviazione è scaduto.';
		                           |pl = 'Newsletter ma status ""Wykonana"". Wszystkie wiadomości zostały utworzone.
		                           | Wiadomości nie zostały utworzone, jeżeli dane kontaktowe nie były podane lub miały niepoprawny format.
		                           |Utworzone wiadomości mogą nie być obecne w tym raporcie, jeśli upłynął okres przechowywania tych wiadomości.';
		                           |tr = 'Bülten, ""Tamamlandı"" durumundadır. Olası tüm mesajlar oluşturuldu.
		                           |İletişim bilgileri belirtilmediyse veya yanlış biçimde belirtildiyse mesajlar oluşturulmadı.
		                           |Mesaj verilerinin saklama süresi dolduysa, oluşturulan mesajlar bu rapora dahil edilmeyebilir.'");
		
	EndIf;
	
	Return LegendText;

EndFunction 

#EndRegion


