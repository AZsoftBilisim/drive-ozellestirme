///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// It is called to get contacts (members) by the specified interaction subject.
// It is used if at least one interaction subject is determined in the configuration.
//
// Parameters:
//  ContactsTableName   - String - an interaction subject table name, where search is required.
//                                   For example, "Documents.CustomerOrder".
//  QueryTextForSearch - String - This parameter takes the sought for query fragment. When executing the query, 
//                                   the query parameter "&Subject" is replaced with a reference to the interaction topic.
//
Procedure OnSearchForContacts(Val ContactsTableName, QueryTextForSearch) Export
	
	QueryTextForSearch = "
	| UNION
	|
	|SELECT DISTINCT
	|	TablePartnersAndContactPersons.Partner AS Contact
	|FROM
	|	&CatalogName AS TablePartnersAndContactPersons
	|WHERE
	|	TablePartnersAndContactPersons.Ref = &SubjectOf
	|	AND (NOT TablePartnersAndContactPersons.Partner IS NULL )
	|
	|UNION
	|
	|SELECT DISTINCT
	|	TablePartnersAndContactPersons.ContactPerson
	|FROM
	|	&CatalogName AS TablePartnersAndContactPersons
	|WHERE
	|	TablePartnersAndContactPersons.Ref = &SubjectOf
	|	AND (NOT TablePartnersAndContactPersons.ContactPerson IS NULL )"; //@Query-part
	
	QueryTextForSearch = StrReplace(QueryTextForSearch, "&CatalogName", ContactsTableName + ".PartnersAndContactPersons");	
	
EndProcedure	

// Allows to override an attachment owner for writing.
// This can be required, for example, in case of bulk mail, when it makes sense 
// to store all attachments together and not to replicate them to all bulk emails.
//
// Parameters:
//  MailMessage - DocumentRef.IncomingEmail
//         - DocumentRef.OutgoingEmail - Email message whose attachments must be received. 
//           
//  AttachedFiles - Structure - specify information on files attached to an email:
//    * FilesOwner                     - DefinedType.AttachedFile - Attachment owner.
//    * AttachedFilesCatalogName - String - an attached file metadata object name.
//
Procedure OnReceiveAttachedFiles(MailMessage, AttachedFiles) Export

	If InteractionsClientServer.IsInteraction(MailMessage) Then
		EmailAttributes = Common.ObjectAttributesValues(MailMessage, "InteractionBasis");
		If TypeOf(EmailAttributes.InteractionBasis) = Type("DocumentRef.MailoutToCustomers") Then
			AttachedFiles = New Structure ("FilesOwner, AttachedFilesCatalogName",
			                         EmailAttributes.InteractionBasis, "MailoutToCustomersAttachedFiles"); 
		EndIf;
	ElsIf TypeOf(MailMessage) = Type("CatalogRef.MessageTemplates") Then
		AttachedFiles = New Structure("FilesOwner, AttachedFilesCatalogName",
			                         MailMessage, "MessageTemplatesAttachedFiles");
	ElsIf TypeOf(MailMessage) = Type("DocumentObject.OutgoingEmail")
		      And TypeOf(MailMessage.InteractionBasis) = Type("DocumentRef.MailoutToCustomers") Then
		AttachedFiles = New Structure("FilesOwner, AttachedFilesCatalogName",
		                         MailMessage.InteractionBasis, "MailoutToCustomersAttachedFiles");
	Else
		If TypeOf(MailMessage) =Type("DocumentRef.MailoutToCustomers") Then
			AttachedFiles = New Structure("FilesOwner, AttachedFilesCatalogName",
			                         MailMessage, "MailoutToCustomersAttachedFiles"); 
		EndIf;
	EndIf;
	
EndProcedure

// It is called to set logic of interaction access restriction.
// For the example of filling access value sets, see comments
// to AccessManagement.FillAccessValuesSets.
//
// Parameters:
//  Object - DocumentObject.Meeting
//         - DocumentObject.PlannedInteraction
//         - DocumentObject.SMSMessage
//         - DocumentObject.PhoneCall
//         - DocumentObject.IncomingEmail
//         - DocumentObject.OutgoingEmail - Object whose sets must be populated.
//  Table - See AccessManagement.AccessValuesSetsTable
//
Procedure OnFillingAccessValuesSets(Object, Table) Export
	
	SetPrivilegedMode(True);
	
	// The logic of the restriction is as follows: the object is available if "Author" or "Account" or "Responsible" is available.
	// The logic of "OR" is implemented through different set numbers.
	
	// Restriction on "Responsible".
	SetNumber = 1;
	
	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.EmployeeResponsible;

	// Restriction by "Author".
	If TypeOf(Object) <> Type("DocumentObject.IncomingEmail") Then
		SetNumber = SetNumber + 1;
		
		TabRow = Table.Add();
		TabRow.SetNumber     = SetNumber;
		TabRow.AccessValue = Object.Author;
	EndIf;

	// Restriction on the "Electronic Mail account".
	If TypeOf(Object) = Type("DocumentObject.IncomingEmail") Or 
			TypeOf(Object) = Type("DocumentObject.OutgoingEmail") Then
		SetNumber = SetNumber + 1;
			
		TabRow = Table.Add();
		TabRow.SetNumber     = SetNumber;
		TabRow.AccessValue = Object.Account;			
	EndIf;
		
	If TypeOf(Object) = Type("DocumentObject.PhoneCall") Then
		If ValueIsFilled(Object.SubscriberContact) Then

			If TypeOf(Object.SubscriberContact) = Type("CatalogRef.Partners") Then

				SetNumber = SetNumber + 1;

				TabRow = Table.Add();
				TabRow.SetNumber     = SetNumber;
				TabRow.AccessValue = Object.SubscriberContact;

			ElsIf TypeOf(Object.SubscriberContact) = Type("CatalogRef.ContactPersonsForPartners") Then

				Query = New Query(
				"SELECT DISTINCT
				|	ContactPersonsForPartners.Owner AS Partner
				|FROM
				|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|WHERE
				|	ContactPersonsForPartners.Ref =&SubscriberContact
				|");
				Query.SetParameter("SubscriberContact", Object.SubscriberContact);
				Selection = Query.Execute().Select();

				While Selection.Next() Do

					SetNumber = SetNumber + 1;

					TabRow = Table.Add();
					TabRow.SetNumber     = SetNumber;
					TabRow.AccessValue = Selection.Partner;

				EndDo;
			EndIf;
		EndIf;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.IncomingEmail") Then
		ArrayOfContactPersons = New Array;

		TabularSectionsArray = New Array;
		TabularSectionsArray.Add("EmailRecipients");
		TabularSectionsArray.Add("CCRecipients");
		TabularSectionsArray.Add("ReplyRecipients");
		For Each TabularSection In TabularSectionsArray Do

			For Each TableRow In Object[TabularSection] Do

				If Not ValueIsFilled(TableRow.Contact) Then
					Continue;
				EndIf;

				If TypeOf(TableRow.Contact) = Type("CatalogRef.Partners") Then

					SetNumber = SetNumber + 1;

					TabRow = Table.Add();
					TabRow.SetNumber     = SetNumber;
					TabRow.AccessValue = TableRow.Contact;

				ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef.ContactPersonsForPartners") Then

					ArrayOfContactPersons.Add(TableRow.Contact);

				EndIf;

			EndDo;
		EndDo;

		If ArrayOfContactPersons.Count() > 0 Then

			Query = New Query(
			"SELECT DISTINCT
			|	ContactPersonsForPartners.Owner AS Partner
			|FROM
			|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|WHERE
			|	ContactPersonsForPartners.Ref IN(&ArrayOfContactPersons)
			|");
			Query.SetParameter("ArrayOfContactPersons", ArrayOfContactPersons);
			Selection = Query.Execute().Select();

			While Selection.Next() Do

				SetNumber = SetNumber + 1;

				TabRow = Table.Add();
				TabRow.SetNumber     = SetNumber;
				TabRow.AccessValue = Selection.Partner;

			EndDo;

		EndIf;
		
	ElsIf TypeOf(Object) = Type("DocumentObject.OutgoingEmail") Then
		ArrayOfContactPersons = New Array;

		TabularSectionsArray = New Array;
		TabularSectionsArray.Add("EmailRecipients");
		TabularSectionsArray.Add("CCRecipients");
		TabularSectionsArray.Add("ReplyRecipients");
		TabularSectionsArray.Add("BccRecipients");
		For Each TabularSection In TabularSectionsArray Do

			For Each TableRow In Object[TabularSection] Do

				If Not ValueIsFilled(TableRow.Contact) Then
					Continue;
				EndIf;

				If TypeOf(TableRow.Contact) = Type("CatalogRef.Partners") Then

					SetNumber = SetNumber + 1;

					TabRow = Table.Add();
					TabRow.SetNumber     = SetNumber;
					TabRow.AccessValue = TableRow.Contact;

				ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef.ContactPersonsForPartners") Then

					ArrayOfContactPersons.Add(TableRow.Contact);

				EndIf;

			EndDo;
		EndDo;

		If ArrayOfContactPersons.Count() > 0 Then

			Query = New Query(
			"SELECT DISTINCT
			|	ContactPersonsForPartners.Owner AS Partner
			|FROM
			|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|WHERE
			|	ContactPersonsForPartners.Ref IN(&ArrayOfContactPersons)
			|");
			Query.SetParameter("ArrayOfContactPersons", ArrayOfContactPersons);
			Selection = Query.Execute().Select();

			While Selection.Next() Do

				SetNumber = SetNumber + 1;

				TabRow = Table.Add();
				TabRow.SetNumber     = SetNumber;
				TabRow.AccessValue = Selection.Partner;

			EndDo;

		EndIf;
		
	Else
		
		ArrayOfContactPersons = New Array;
		If TypeOf(Object) = Type("DocumentObject.SMSMessage") Then
			TSName = Object.Recipients;
		Else
			TSName = Object.Attendees;
		EndIf;
		
		For Each TableRow In TSName Do

			If Not ValueIsFilled(TableRow.Contact) Then
				Continue;
			EndIf;

			If TypeOf(TableRow.Contact) = Type("CatalogRef.Partners") Then

				SetNumber = SetNumber + 1;

				TabRow = Table.Add();
				TabRow.SetNumber     = SetNumber;
				TabRow.AccessValue = TableRow.Contact;

			ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef.ContactPersonsForPartners") Then

				ArrayOfContactPersons.Add(TableRow.Contact);

			EndIf;

		EndDo;

		If ArrayOfContactPersons.Count() > 0 Then

			Query = New Query(
			"SELECT DISTINCT
			|	ContactPersonsForPartners.Owner AS Partner
			|FROM
			|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|WHERE
			|	ContactPersonsForPartners.Ref IN(&ArrayOfContactPersons)
			|");
			Query.SetParameter("ArrayOfContactPersons", ArrayOfContactPersons);
			Selection = Query.Execute().Select();

			While Selection.Next() Do
				
				SetNumber = SetNumber + 1;
				
				TabRow = Table.Add();
				TabRow.SetNumber     = SetNumber;
				TabRow.AccessValue = Selection.Partner;
			
			EndDo;
		
		EndIf;
		
	EndIf;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Obsolete. Use InteractionsOverridable.OnSearchForContacts.
// Returns a query text that filters interaction subject contacts (members).
// It is used if at least one interaction subject is determined in the configuration.
//
// Parameters:
//  DeletePutInTempTable - Boolean - always False.
//  TableName                        - String - an interaction subject table name, where search will be performed.
//  DeleteMerge                 - Boolean - always True.
//
// Returns:
//  String - Query text.
//
Function QueryTextContactsSearchBySubject(DeletePutInTempTable, TableName, DeleteMerge = False) Export
	
	PutInTempTable = DeletePutInTempTable;
	Union = DeleteMerge;
	
	PostfixToChoose = ?(Union,"DISTINCT","DISTINCT ALLOWED");
	
	QueryText =" 
	|SELECT &PostfixToChoose,
	|	TablePartnersAndContactPersons.Partner AS Contact
	|INTO TabContacts
	|FROM
	|	&TableName AS TablePartnersAndContactPersons
	|WHERE
	|	TablePartnersAndContactPersons.Ref = &SubjectOf
	|	AND (NOT TablePartnersAndContactPersons.Partner IS NULL )
	|
	|UNION
	|
	|SELECT &PostfixIsDifferent,
	|	TablePartnersAndContactPersons.ContactPerson
	|FROM
	|	&TableName AS TablePartnersAndContactPersons
	|WHERE
	|	TablePartnersAndContactPersons.Ref = &SubjectOf
	|	AND (NOT TablePartnersAndContactPersons.ContactPerson IS NULL )";
	
	QueryText = StrReplace(QueryText,"&PostfixToChoose,",   PostfixToChoose);
	QueryText = StrReplace(QueryText,"&PostfixIsDifferent,", "DISTINCT");
	QueryText = StrReplace(QueryText,"&TableName",          TableName + ".PartnersAndContactPersons");
	
	If Not PutInTempTable Then
		QueryText = StrReplace(QueryText,"INTO TabContacts","");
	EndIf;
	
	If Union Then
		
		QueryText = "
		| UNION
		|" + QueryText;
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Deprecated. Obsolete. Use InteractionsOverridable.OnGetAttachedFiles.
// The ability to override an attachment owner for writing.
// This can be required, for example, in case of bulk mail. Here it makes sense 
// to store all attachments together and not to replicate them to all bulk emails.
//
// Parameters:
//  MailMessage  - DocumentRef
//          - DocumentObject - Email message whose attachments must be received.
//
// Returns:
//  Structure, Undefined  - - Undefined if the attachments are stored in the message.
//                             Otherwise, Structure:
//                              * Owner - DefinedType.AttachedFile - Attachment owner.
//                              * CatalogNameAttachedFiles - String - an attached file metadata object name.
//
Function AttachedEmailFilesMetadataObjectData(MailMessage) Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
