///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Intended for changing formats and set pictures.
// For details about changing formats, See ReportMailing.SetFormatsParameters.
//
// Parameters:
//   FormatsList - ValueList:
//       * Value      - EnumRef.ReportSaveFormats - a format reference.
//       * Presentation - String - a format presentation.
//       * Check       - Boolean - flag showing that the format is used by default.
//       * Picture      - Picture - a picture of the format.
//
// Example:
//	ReportMailing.SetFormatParameters(FormatsList, HTML, , False).
//	ReportMailing.SetFormatParameters(FormatsList, XLS, , True).
//
Procedure OverrideFormatsParameters(FormatsList) Export
	
	
	
EndProcedure

// Intended for adding the details of cross-object links of types for recipients.
// To register type parameters,  See ReportMailing.AddItemToRecipientsTypesTable.
// For other usage examples, see ReportMailingCached.RecipientsTypesTable.
// NOTE:
//   Use this mechanism only if you need to:
//   1. Describe and present several types as one (as in the Users and UserGroups catalog).
//   2. Change the type representation without changing the metadata synonym.
//   3.Specify the type of email contact information by default.
//   4. Define a group of contact information.
//   
//
// Parameters:
//   TypesTable  - ValueTable - type details table.
//   AvailableTypes - Array - available types.
//
// Example:
//	Settings = New Structure;
//	Settings.Insert(MainType, Type(CatalogRef.Counterparties)).
//	Settings.Insert(CIKind, ContactsManager.ContactInformationKindByName(CounterpartyEmail));
//	ReportMailing.AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, Settings).
//
Procedure OverrideRecipientsTypesTable(TypesTable, AvailableTypes) Export
	
	ReportMailingLocalization.WhenOverridingRecipientTypeTable(TypesTable, AvailableTypes);
	PartnersAndCounterparties.WhenRedefiningTableOfTypesOfRecipientsOfMailingReports(TypesTable, AvailableTypes);
	
EndProcedure

// Allows you to define a handler for saving a spreadsheet document to a format.
// Important:
//   If non-standard processing is used (StandardProcessing is changed to False),
//   then FullFileName must contain the full file name with extension.
//
// Parameters:
//   StandardProcessing - Boolean - a flag of standard subsystem mechanisms usage for saving to a format.
//   SpreadsheetDocument    - SpreadsheetDocument - a spreadsheet document to be saved.
//   Format               - EnumRef.ReportSaveFormats - a format for saving the spreadsheet
//                                                                        document.
//   FullFileName       - String - a full file name.
//       Passed without an extension if the format was added in the applied configuration.
//
// Example:
//	If Format = Enums.ReportSaveFormats.HTML Then
//		StandardProcessing = False;
//		FullFileName = FullFileName +".html";
//		SpreadsheetDocument.Write(FullFileName, SpreadsheetDocumentFileType.HTML5);
//	EndIf;
//
Procedure BeforeSaveSpreadsheetDocumentToFormat(StandardProcessing, SpreadsheetDocument, Format, FullFileName) Export
	
	
	
EndProcedure

// Intended for overriding the list of report distribution recipients.
// If StandardProcessing = True, the recipient list is generated as follows:
// - If the distribution is personal, the list contains only the distribution author.
// - If the recipients is a hierarchical catalog, and a parent item is passed, 
//   all its child items are also included in the distribution (except for groups).
// - Recipients marked as excluded or marked for deletion are excluded from the distribution.
// - If recipients are users, than service and inactive users are excluded from the distribution.
// - Email addresses of the recipients are taken from RecipientsEmailAddressKind 
//   of the RecipientsParameters parameter.
//
// Parameters:
//   RecipientsParameters - CatalogRef.ReportMailings
//                        - Structure - Parameters for generating a recipient list.
//   Query - Query - Query to be executed if StandardProcessing = True.
//   StandardProcessing - Boolean - Set to False if the result must be populated by this handler.
//   Result - Map of KeyAndValue - Return value.
//                                               If StandardProcessing = True, populate the list with recipients and their addresses.:
//       * Key     - CatalogRef - Distribution recipient. For example, a user or a counterparty.
//       * Value - String - Semicolon-delimited email addresses. For example: "email@server.com; email2@server2.com".
// 
Procedure BeforeGenerateMailingRecipientsList(RecipientsParameters, Query, StandardProcessing, Result) Export
	
	If RecipientsParameters.Personal Then
		
		RecipientsType = TypeOf(RecipientsParameters.Author);
		
	Else
		
		RecipientsType = Common.ObjectAttributeValue(RecipientsParameters.MailingRecipientType, "MetadataObjectKey").Get();
		
	EndIf;
	
	If RecipientsType = Type("CatalogRef.Partners") Then
		
		Query.Text = StrReplace(Query.Text, "IN HIERARCHY", "In");
		
	EndIf;
	
EndProcedure

// Allows you to exclude reports that are not ready for integration with mailing.
//   Specified reports are used as a filter when selecting reports.
//
// Parameters:
//   ReportsToExclude - Array - a list of reports in the form of objects with the Report type of the MetadataObject
//                       connected to the ReportsOptions storage but not supporting integration with mailings.
//
Procedure DetermineReportsToExclude(ReportsToExclude) Export

	ReportMailingLocalization.DetermineReportsToExclude(ReportsToExclude);
	
	ReportsToExclude.Add(Metadata.Reports.EventCalendar);
	ReportsToExclude.Add(Metadata.Reports.ContactInformation);
	ReportsToExclude.Add(Metadata.Reports.ComparativeAnalysisOfManagerPerformanceIndicators);
	
EndProcedure

// Allows overriding the report generation parameters.
//
// Parameters:
//  GenerationParameters - Structure:
//    * DCUserSettings - DataCompositionUserSettings - report settings
//                                    for the corresponding distribution.
//  AdditionalParameters - Structure:
//    * Report - CatalogRef.ReportsOptions - a reference to the report option settings storage.
//    * Object - ReportObject - an object of the report to be sent.
//    * DCS - Boolean - indicates whether a report is created by the data composition system.
//    * DCSettingsComposer - DataCompositionSettingsComposer - a report settings composer.
//
Procedure OnPrepareReportGenerationParameters(GenerationParameters, AdditionalParameters) Export 
	
	
	
EndProcedure

// Intended for adding additional parameters required for generating the distribution subject and body.
// Use together with OnReceiveEmailTextParameters.
// 
// Parameters:
//   BulkEmailType - String - Report distribution kind. Valid values: Shared3, Personalized, Personal.
//   MailingRecipientType        - TypeDescription
//                                 - Undefined - If BulkEmailType = Personal
//   AdditionalTextParameters - Structure - Details of additional parameters of the subject and body:
//     * Key     - String - Parameter name.
//     * Value - String - a parameter presentation.
//
//  Example:
//	If BulkEmailType = "Personalized" And MailingRecipientType
//		= New TypeDescription("CatalogRef.Individuals") Then
//		AdditionalTextParameters.Insert("Name", NStr("ru='Name'"));
//		AdditionalTextParameters.Insert("MiddleName", NStr("ru='Middle name'"));
//	EndIf;
//
Procedure OnDefineEmailTextParameters(BulkEmailType, MailingRecipientType, AdditionalTextParameters) Export
	
	
	
EndProcedure

// Intended for setting arbitrary values for additional parameters to generate distribution subject and body.
// Use together with OnDefineEmailTextParameters.
// 
// Parameters:
//   BulkEmailType - String - Report distribution kind. Valid values: Shared3, Personalized, Personal.
//   MailingRecipientType - TypeDescription
//   Recipient - DefinedType.BulkEmailRecipient - If BulkEmailType is "Personalized".
//              - Undefined - If BulkEmailType is "Personal" or "Shared3".
//   AdditionalTextParameters - Structure - Details of additional parameters of the topic and body:
//     * Key     - String - Parameter name.
//     * Value - String - a parameter presentation.
// 
// Example:
//	If BulkEmailType = "Personalized" And MailingRecipientType
//		= New TypeDescription("CatalogRef.Individuals") And Recipient <> Undefined Then
//		AttributesOfIndividual = Common.ObjectAttributesValues(Recipient, "Name, MiddleName");
//		AdditionalTextParameters.Name = AttributesOfIndividual.Name;
//		AdditionalTextParameters.MiddleName = AttributesOfIndividual.MiddleName;
//	EndIf;
//
Procedure OnReceiveEmailTextParameters(BulkEmailType, MailingRecipientType, Recipient, AdditionalTextParameters) Export
	
	
	
EndProcedure

#EndRegion
