///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function ListPresentation(Collection, ColumnName = "", MaxChars = 60) Export
	Result = New Structure;
	Result.Insert("Total", 0);
	Result.Insert("LengthOfFull", 0);
	Result.Insert("LengthOfShort", 0);
	Result.Insert("Short", "");
	Result.Insert("Full", "");
	Result.Insert("MaximumExceeded", False);
	For Each Object In Collection Do
		ValuePresentation = String(?(ColumnName = "", Object, Object[ColumnName]));
		If IsBlankString(ValuePresentation) Then
			Continue;
		EndIf;
		If Result.Total = 0 Then
			Result.Total        = 1;
			Result.Full       = ValuePresentation;
			Result.LengthOfFull = StrLen(ValuePresentation);
		Else
			Full       = Result.Full + ", " + ValuePresentation;
			LengthOfFull = Result.LengthOfFull + 2 + StrLen(ValuePresentation);
			If Not Result.MaximumExceeded And LengthOfFull > MaxChars Then
				Result.Short          = Result.Full;
				Result.LengthOfShort    = Result.LengthOfFull;
				Result.MaximumExceeded = True;
			EndIf;
			Result.Total        = Result.Total + 1;
			Result.Full       = Full;
			Result.LengthOfFull = LengthOfFull;
		EndIf;
	EndDo;
	If Result.Total > 0 And Not Result.MaximumExceeded Then
		Result.Short       = Result.Full;
		Result.LengthOfShort = Result.LengthOfFull;
		Result.MaximumExceeded = Result.LengthOfFull > MaxChars;
	EndIf;
	Return Result;
EndFunction

// Returns the default subject template for delivery by email.
Function SubjectTemplate(AllParametersOfFilesAndEmailText = Undefined) Export
	If AllParametersOfFilesAndEmailText <> Undefined Then 
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 từ %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[" + AllParametersOfFilesAndEmailText.MailingDescription + "]",
			"[" + AllParametersOfFilesAndEmailText.ExecutionDate + "(DLF='D')]");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 từ %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[MailingDescription]", "[ExecutionDate(DLF='D')]");
	EndIf;
EndFunction

// Returns the default archive description template.
Function ArchivePatternName(AllParametersOfFilesAndEmailText = Undefined) Export
	If AllParametersOfFilesAndEmailText <> Undefined Then
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 từ %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[" + AllParametersOfFilesAndEmailText.MailingDescription + "]",
			"[" + AllParametersOfFilesAndEmailText.ExecutionDate + "(DF='yyyy-MM-dd')]");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 từ %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[MailingDescription]", "[ExecutionDate(DF='yyyy-MM-dd')]");
	EndIf;
EndFunction

// The constructor for the DeliveryParameters parameter value of the ExecuteBulkEmail function.
//
// Returns:
//   Structure - Report delivery method settings. The list of properties depends on the delivery method.
//     Common properties::
//       * Author - CatalogRef.Users - a mailing author.
//       * UseFolder            - Boolean - deliver reports to the "Stored files" subsystem folder.
//       * UseNetworkDirectory   - Boolean - deliver reports to the file system folder.
//       * UseFTPResource        - Boolean - deliver reports to the FTP.
//       * UseEmail - Boolean - Deliver reports via email.
//
//     If UseFolder = True, the following properties are used:
//       * Folder - CatalogRef.FilesFolders - Folder of the "File Management" subsystem.
//
//     If UseNetworkDirectory = True, the following properties are used:
//       * NetworkDirectoryWindows - String - a file system directory (local at server or network).
//       * NetworkDirectoryLinux   - String - a file system directory (local on the server or network).
//
//     If UseFTPResource = True, the following properties are used:
//       * Owner            - CatalogRef.ReportMailings
//       * Server              - String - an FTP server name.
//       * Port                - Number  - an FTP server port.
//       * Login               - String - an FTP server user name.
//       * Password              - String - an FTP server user password.
//       * Directory             - String - a path to the directory at the FTP server.
//       * PassiveConnection - Boolean - Use passive connection.
//
//     If UseEmail = True, the following properties are used:
//       * Account - CatalogRef.EmailAccounts - to send an email message.
//       * Recipients - Map of KeyAndValue - List of recipients and their email addresses:
//           ** Key - CatalogRef - a recipient.
//           ** Value - String - Recipient's comma-delimited email addresses.
//
//     Additional properties:
//       * Archive - Boolean - archive all generated reports into one archive.
//                                 Archiving can be required, for example, when mailing schedules in html format.
//       * ArchiveName    - String - an archive name.
//       * ArchivePassword - String - an archive password.
//       * TransliterateFileNames - Boolean - Flag indicating whether to convert Cyrillic filenames to Latin.
//       * CertificateToEncrypt - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - if the DigitalSignature
//           subsystem is integrated, Undefined.
//       * MailingRecipientType - TypeDescription
//                                - Undefined
//
//     If UseEmail = True, the following optional properties are used:
//       * Personalized - Boolean - Personalized report distribution.
//           By default, False.
//           If True, each recipient receives an individual report.
//           To do this, in reports, set the [Recipient] filter by the attribute that matches the recipient type.
//           Applies only to email distributions,
//           so setting to True disables other distribution methods.
//       * NotifyOnly - Boolean - False - send notifications only (do not attach generated reports).
//       * BCCs    - Boolean - False - if True, when sending fill BCCs instead of To.
//       * SubjectTemplate      - String -       an email subject.
//       * TextTemplate1    - String -       an email body.
//       * FormatsParameters - Map of KeyAndValue:
//           ** Key - EnumRef.ReportSaveFormats
//           ** Value - Structure:
//                *** Extension - String
//                *** FileType - SpreadsheetDocumentFileType
//                *** Name - String
//       * EmailParameters - See EmailSendOptions
//       * ShouldInsertReportsIntoEmailBody - Boolean
//       * ShouldAttachReports - Boolean
//       * ShouldSetPasswordsAndEncrypt - Boolean
//       * ReportsForEmailText - Array of Map
//
Function DeliveryParameters() Export
	
	DeliveryParameters = New Structure;
	DeliveryParameters.Insert("ExecutionDate", Undefined);
	DeliveryParameters.Insert("Join", Undefined);
	DeliveryParameters.Insert("StartCommitted", False);
	DeliveryParameters.Insert("Author", Undefined);
	DeliveryParameters.Insert("EmailParameters", EmailSendOptions());
	
	DeliveryParameters.Insert("RecipientsSettings", New Map);
	DeliveryParameters.Insert("Recipients", Undefined);
	DeliveryParameters.Insert("Account", Undefined);
	DeliveryParameters.Insert("BulkEmail", "");
	
	DeliveryParameters.Insert("HTMLFormatEmail", False);
	DeliveryParameters.Insert("Personalized", False);
	DeliveryParameters.Insert("TransliterateFileNames", False);
	DeliveryParameters.Insert("NotifyOnly", False);
	DeliveryParameters.Insert("BCCs", False);
	
	DeliveryParameters.Insert("UseEmail", False);
	DeliveryParameters.Insert("UseFolder", False);
	DeliveryParameters.Insert("UseNetworkDirectory", False);
	DeliveryParameters.Insert("UseFTPResource", False);
	
	DeliveryParameters.Insert("Directory", Undefined);
	DeliveryParameters.Insert("NetworkDirectoryWindows", Undefined);
	DeliveryParameters.Insert("NetworkDirectoryLinux", Undefined);
	DeliveryParameters.Insert("TempFilesDir", "");
	
	DeliveryParameters.Insert("Owner", Undefined);
	DeliveryParameters.Insert("Server", Undefined);
	DeliveryParameters.Insert("Port", Undefined);
	DeliveryParameters.Insert("PassiveConnection", False);
	DeliveryParameters.Insert("Login", Undefined);
	DeliveryParameters.Insert("Password", Undefined);
	
	DeliveryParameters.Insert("Folder", Undefined);
	DeliveryParameters.Insert("Archive", False);
	DeliveryParameters.Insert("ArchiveName", ArchivePatternName());
	DeliveryParameters.Insert("ArchivePassword", Undefined);
	DeliveryParameters.Insert("CertificateToEncrypt", Undefined);
		
	DeliveryParameters.Insert("FillRecipientInSubjectTemplate", False);
	DeliveryParameters.Insert("FillRecipientInMessageTemplate", False);
	DeliveryParameters.Insert("FillGeneratedReportsInMessageTemplate", False);
	DeliveryParameters.Insert("FillDeliveryMethodInMessageTemplate", False);
	DeliveryParameters.Insert("RecipientReportsPresentation", "");
	DeliveryParameters.Insert("SubjectTemplate", SubjectTemplate());
	DeliveryParameters.Insert("TextTemplate1", "");
	
	DeliveryParameters.Insert("FormatsParameters", New Map);
	DeliveryParameters.Insert("TransliterateFileNames", False);
	DeliveryParameters.Insert("GeneralReportsRow", Undefined);
	DeliveryParameters.Insert("AddReferences", "");
	
	DeliveryParameters.Insert("TestMode", False);
	DeliveryParameters.Insert("HadErrors", False);
	DeliveryParameters.Insert("HasWarnings", False);
	DeliveryParameters.Insert("ExecutedToFolder", False);
	DeliveryParameters.Insert("ExecutedToNetworkDirectory", False);
	DeliveryParameters.Insert("ExecutedAtFTP", False);
	DeliveryParameters.Insert("ExecutedByEmail", False);
	DeliveryParameters.Insert("ExecutedPublicationMethods", "");
	DeliveryParameters.Insert("Recipient", Undefined);
	DeliveryParameters.Insert("Images", New Structure);
	DeliveryParameters.Insert("Personal", False);
	DeliveryParameters.Insert("MailingRecipientType", Undefined);
	DeliveryParameters.Insert("ShouldInsertReportsIntoEmailBody", True);
	DeliveryParameters.Insert("ShouldAttachReports", False);
	DeliveryParameters.Insert("ShouldSetPasswordsAndEncrypt", False);
	DeliveryParameters.Insert("ReportsForEmailText", New Map);
	DeliveryParameters.Insert("ReportsTree", Undefined);
	DeliveryParameters.Insert("ResultAddress", Undefined);
	
	Return DeliveryParameters;
	
EndFunction

// Constructor of the structure containing mail-out parameters.
//
// Returns:
//   Structure - Contains all email details:
//     * Whom - Array
//            - String - Recipients' email addresses and presentation.
//            - Array - Collection of address structures:
//                * Address         - String - an email address (required).
//                * Presentation - String - a recipient's name.
//            - String - Semicolon-delimited recipient addresses.
//
//     * MessageRecipients - Array - Array of structures describing recipients:
//       ** Address - String - an email recipient address.
//       ** Presentation - String - Addressee presentation.
//
//     * Cc        - Array
//                    - String - Email addresses of the CC recipients. See the "To" field.
//
//     * BCCs - Array
//                    - String - Email addresses of the BCC recipients. See the "To" field.
//
//     * Subject       - String - (mandatory) an email subject.
//     * Body       - String - (mandatory) an email text (plain text, win1251 encoded).
//
//     * Attachments - Array - Files to be attached (as structures):
//       ** Presentation - String - an attachment file name;
//       ** AddressInTempStorage - String - a binary data address of an attachment in a temporary storage.
//       ** Encoding - String - an attachment encoding (used if it differs from the message encoding).
//       ** Id - String - (optional) used to store images displayed in the message body.
//
//     * ReplyToAddress - String - Reply-to email address.
//     * BasisIDs - String - IDs of the message basis objects.
//     * ProcessTexts  - Boolean - shows whether message text processing is required on sending.
//     * RequestDeliveryReceipt  - Boolean - shows whether a delivery notification is required.
//     * RequestReadReceipt - Boolean - shows whether a read notification is required.
//     * TextType - String
//                 - EnumRef.EmailTextTypes
//                 - InternetMailTextType - Determines the type of the passed text.
//                   Valid values::
//                   HTML/EmailTextTypes.HTML - HTML text.
//                   PlainText/EmailTextTypes.PlainText - Plain text.
//                                                 By default, display "as is".
//                   MarkedUpText/EmailTextTypes.MarkedUpText - Reach text.
//                                                 
//     * Importance  - InternetMailMessageImportance
//
Function EmailSendOptions() Export
	
	EmailParameters = New Structure;
	EmailParameters.Insert("Whom", New Array);
	EmailParameters.Insert("MessageRecipients", New Array);
	EmailParameters.Insert("Cc", New Array);
	EmailParameters.Insert("BCCs", New Array);
	EmailParameters.Insert("Subject", "");
	EmailParameters.Insert("Body", "");
	EmailParameters.Insert("Attachments", New Map);
	EmailParameters.Insert("ReplyToAddress", "");
	EmailParameters.Insert("BasisIDs", "");
	EmailParameters.Insert("ProcessTexts", False);
	EmailParameters.Insert("RequestDeliveryReceipt", False);
	EmailParameters.Insert("RequestReadReceipt", False);
	EmailParameters.Insert("TextType", "PlainText");
	EmailParameters.Insert("Importance", "");
	
	Return EmailParameters;
	
EndFunction

// Constructor of the structure containing recipient parameters.
//
// Returns:
//   Structure - Contains all details about the distribution recipients.:
//     * Ref - CatalogRef.ReportMailings
//     * Author - CatalogRef.Users
//     * RecipientsEmailAddressKind - CatalogRef.ContactInformationKinds
//     * Personal - Boolean
//     * Recipients - CatalogTabularSection.ReportMailings.Recipients
//                    - ValueTable:
//                      ** Recipient - DefinedType.BulkEmailRecipient
//                      ** Excluded - Boolean
//     * MailingRecipientType - CatalogRef.MetadataObjectIDs
//                              - CatalogRef.ExtensionObjectIDs
//
Function RecipientsParameters() Export
	
	RecipientsParameters = New Structure;
	RecipientsParameters.Insert("Ref", PredefinedValue("Catalog.ReportMailings.EmptyRef"));
	RecipientsParameters.Insert("Author", PredefinedValue("Catalog.Users.EmptyRef"));
	RecipientsParameters.Insert("RecipientsEmailAddressKind", PredefinedValue("Catalog.ContactInformationKinds.EmptyRef"));
	RecipientsParameters.Insert("Personal", False);
	RecipientsParameters.Insert("Recipients", Undefined);
	RecipientsParameters.Insert("MailingRecipientType", Undefined);
	
	Return RecipientsParameters;
	
EndFunction

#EndRegion