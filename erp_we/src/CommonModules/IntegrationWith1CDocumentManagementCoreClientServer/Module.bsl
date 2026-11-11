////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentworkbazovaya functionality Clientserver: client, server
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region GeneralProceduresAndFunctions

// Constructor of the structure describing the key data of the integration rule.
//
// Returns:
//  Structure:
//     * Ref - CatalogRef.RulesForIntegrationWith1CDocumentManagement - the rule.
//              - Undefined
//     * ObjectPresentationDM - String - representation of the object BEFORE.
//     * ObjectPresentationIS - String - representation of the IP object.
//     * ObjectTypeDM - String - the object type is UP TO.
//     * ObjectTypeIS - String - the type of IP object.
//     * PresentationOfTheDocumentType - String - Presentation of the document type BEFORE.
//     * IDOfDocumentType - String - id of the document type BEFORE.
//     * TypeOfDocumentType - String - the type of document type BEFORE.
//
Function TheseIntegrationRules() Export
	
	Result = New Structure;
	
	Result.Insert("Ref", Undefined);
	Result.Insert("ObjectTypeIS", "");
	Result.Insert("ObjectTypeDM", "");
	Result.Insert("ObjectPresentationIS", "");
	Result.Insert("ObjectPresentationDM", "");
	Result.Insert("PresentationOfTheDocumentType", "");
	Result.Insert("IDOfDocumentType", "");
	Result.Insert("TypeOfDocumentType", "");
	
	Return Result;
	
EndFunction

// Constructor of the structure that describes the Attributes of the object BEFORE.
//
// Returns:
//  Structure:
//     * Name - String
//     * Type - String
//     * Presentation - String
//     * IsAdditionalAttributeDM - Boolean
//     * AdditionalAttributeDMID - String
//     * AdditionalAttributeDMType - String
//     * ThisIsTable - Boolean
//     * Table - String
//
Function AttributeData() Export
	
	AttributeData = New Structure;
	AttributeData.Insert("Name", "");
	AttributeData.Insert("Type", "");
	AttributeData.Insert("Presentation", "");
	AttributeData.Insert("IsAdditionalAttributeDM", False);
	AttributeData.Insert("AdditionalAttributeDMID", "");
	AttributeData.Insert("AdditionalAttributeDMType", "");
	AttributeData.Insert("ThisIsTable", False);
	AttributeData.Insert("Table", "");
	
	Return AttributeData;
	
EndFunction

// returns the 1C object data structure:Document flow of the reference type.
//
// Parameters:
//   ID - String - the ID of the object BEFORE.
//   Type - String - type of the XDTO object.
//   Description - String - the name of the object BEFORE.
//   Presentation - String - representation of the object BEFORE.
//   URL - String - navigation link to the object BEFORE.
//
// Returns:
//   Structure - signature owner data:
//     * ID - String - the ID of the object BEFORE.
//     * Type - String - type of the XDTO object.
//     * Description - String - the name of the object BEFORE.
//     * Presentation - String - representation of the object BEFORE.
//     * URL - String - navigation link to the object BEFORE.
//
Function ReferenceObjectDataDM(ID, Type, Description = "", Presentation = "", URL = "") Export
	
	ObjectData = New Structure;
	ObjectData.Insert("ID", ID);
	ObjectData.Insert("Type", Type);
	ObjectData.Insert("Description", Description);
	ObjectData.Insert("Presentation", Presentation);
	ObjectData.Insert("URL", URL);
	
	Return ObjectData;
	
EndFunction

// Returns the data structure of the file.
//
// Parameters:
//   Description - String - the name of the object BEFORE.
//   ID - String - the ID of the object BEFORE.
//   Type - String - type of the XDTO object.
//   Extension - String - file extension.
//   FileRoleID - String - the role of the file.
//
// Returns:
//   Structure - signature owner data:
//     * Description - String - the name of the object BEFORE.
//     * ID - String - the ID of the object BEFORE.
//     * Type - String - type of the XDTO object.
//     * Extension - String - file extension.
//     * FileRoleID - String - the role of the file.
//                   - Undefined
//     * RefToBinaryFileData - String - The address of the file data in the temporary storage.
//     * LongDesc - String - description of the file.
//     * Size - Number - file size.
//     * ModificationDate - Date - file modification date.
//     * UniversalModificationDate - Date - the file modification date is universal.
//     * FileName - String - name of the file with the extension.
//     * Text - String - The text of the file.
//     * Encrypted - Boolean - type of the XDTO object.
//
Function FileData(Description, ID, Type, Extension = "", FileRoleID = Undefined) Export
	
	FileData = New Structure;
	FileData.Insert("Description", Description);
	FileData.Insert("ID", ID);
	FileData.Insert("Type", Type);
	FileData.Insert("Extension", Extension);
	FileData.Insert("FileRoleID", FileRoleID);
	FileData.Insert("RefToBinaryFileData", "");
	FileData.Insert("LongDesc", "");
	FileData.Insert("Size", 0);
	FileData.Insert("ModificationDate", Date(1,1,1));
	FileData.Insert("UniversalModificationDate", Date(1,1,1));
	FileData.Insert("FileName", FileNameWithExtension(Description, Extension));
	FileData.Insert("Text", "");
	FileData.Insert("Encrypted", False);
	
	Return FileData;
	
EndFunction

// Constructor of the structure describing the event that occurred with the file, as well as the forms that you want
// to inform about this event.
//
// Returns:
//   Structure:
//     * WritingFile - Boolean
//     * ChangingActiveVersionOfFile - Boolean
//     * ChangingFileRole - Boolean
//     * AddingItemInstanceFile - Boolean
//     * DeletingItemInstanceFile - Boolean
//     * SigningDocumentWithFiles - Boolean
//     * EditingFile - Boolean
//     * FileEditingIsComplete - Boolean
//     * CreatingFile - Boolean
//     * DeleteFile - Boolean
//     * InformFormOfFile - Boolean - it is necessary to inform the file form.
//     * InformFileListForm - Boolean - it is necessary to inform the form containing the list of files, for example,
//         the forms attached files, tasknot, Task.
//
Function FileOperation() Export
	
	FileOperation = New Structure;
	// An event that occurred with the file.
	FileOperation.Insert("WritingFile", False);
	FileOperation.Insert("ChangingActiveVersionOfFile", False);
	FileOperation.Insert("ChangingFileRole", False);
	FileOperation.Insert("AddingItemInstanceFile", False);
	FileOperation.Insert("DeletingItemInstanceFile", False);
	FileOperation.Insert("SigningDocumentWithFiles", False);
	FileOperation.Insert("EditingFile", False);
	FileOperation.Insert("FileEditingIsComplete", False);
	FileOperation.Insert("CreatingFile", False);
	FileOperation.Insert("DeleteFile", False);
	// Forms that need to be informed.
	FileOperation.Insert("InformFormOfFile", False);
	FileOperation.Insert("InformFileListForm", False);
	
	Return FileOperation;
	
EndFunction

// Extract text from the OpenDocument file and return it as a string.
//
// Parameters:
//   PathToFile - String - full file name.
//   Cancel - Boolean - Refusal.
//
// Returns:
//   String - The extracted text.
//
Function ExtractOpenDocumentText(PathToFile, Cancel) Export
	
	ExtractedText = "";
	
#If Not WebClient Then
	
	TemporaryFolderForUnzipping = GetTempFileName();
	TemporaryZIPFile = GetTempFileName("zip");
	
	CopyFile(PathToFile, TemporaryZIPFile);
	File = New File(TemporaryZIPFile);
	File.SetReadOnly(False);

	Try
		Archive = New ZipFileReader();
		Archive.Open(TemporaryZIPFile);
		Archive.ExtractAll(TemporaryFolderForUnzipping, ZIPRestoreFilePathsMode.Restore);
		Archive.Close();
		XMLReader = New XMLReader();
		
		XMLReader.OpenFile(TemporaryFolderForUnzipping + "/content.xml");
		ExtractedText = ExtractTextFromXMLContent(XMLReader);
		XMLReader.Close();
	Except
		// We do not consider it a mistake, because for example, the OTF extension can be both OpenDocument and OpenType font.
		Archive = Undefined;
		XMLReader = Undefined;
		Cancel = True;
		ExtractedText = "";
	EndTry;
	
	DeleteFiles(TemporaryFolderForUnzipping);
	DeleteFiles(TemporaryZIPFile);
	
#EndIf
	
	Return ExtractedText;
	
EndFunction

// Extracts text according to the encoding.
// If the encoding is not set, it calculates the encoding itself.
//
// Parameters:
//   FullFileName - String - full file name.
//   Encoding - String - Encoding.
//   Cancel - Boolean - Refusal.
//
// Returns:
//   String - The extracted text.
//
Function ExtractTextFromTextFile(FullFileName, Encoding, Cancel) Export
	
	ExtractedText = "";
	
#If Not WebClient Then
	
	// Definition of encoding.
	If Not ValueIsFilled(Encoding) Then
		Encoding = Undefined;
	EndIf;
	
	Try
		EncodingForRead = ?(Encoding = "utf-8_WithoutBOM", "utf-8", Encoding);
		TextReader = New TextReader(FullFileName, EncodingForRead);
		ExtractedText = TextReader.Read();
	Except
		Cancel = True;
		ExtractedText = "";
	EndTry;
	
#EndIf
	
	Return ExtractedText;
	
EndFunction

// Generates a type name from the full name of the metadata object.
//
// Parameters:
//   FullName - String - full name of the metadata object.
//   IsReference - Boolean - you need to get the link type or object type.
//   RaiseException1 - Boolean - raise an exception if an incorrect full name is passed.
//
// Returns:
//   String - type name.
//
Function TypeNameFromFullName(FullName, IsReference = True, RaiseException1 = True) Export
	
	NameContent = StrSplit(FullName, ".");
	If NameContent.Count() < 2
			Or (NameContent[0] <> "Catalog"
				And NameContent[0] <> "Document"
				And NameContent[0] <> "ChartOfAccounts"
				And NameContent[0] <> "ChartOfCalculationTypes"
				And NameContent[0] <> "ChartOfCharacteristicTypes"
				And NameContent[0] <> "BusinessProcess"
				And NameContent[0] <> "Task") Then
		If RaiseException1 Then
			Raise StrTemplate(NStr("vi = 'Không thể xác định tên kiểu từ dòng ""%1""';
									|ru = 'Не удалось определить имя типа из строки ""%1""';
									|en = 'Cannot identify the type name from the ""%1"" string'; fa = 'Cannot identify the type name from the ""%1"" string';
									|it = 'Не удалось определить имя типа из строки ""%1""';
									|pl = 'Cannot identify the type name from the ""%1"" string';
									|tr = '""%1"" satırındaki türün adı belirlenemedi'"), FullName);
		Else
			Return "";
		EndIf;
	EndIf;
	
	If IsReference Then
		Supplement = "Ref";
	Else
		Supplement = "Object";
	EndIf;
	
	Return StrTemplate("%1%2.%3", NameContent[0], Supplement, NameContent[1]);
	
EndFunction

// Gets the file name with the extension (if the extension is empty, just the name).
//
// Parameters:
//   FullDescr - String - full name of the file.
//   Extension - String - file extension.
//
// Returns:
//   String - Name with extension. If the extension is empty, only the name.
//
Function FileNameWithExtension(FullDescr, Extension) Export
	
	NameWithExtension = FullDescr;
	
	If Extension <> "" Then
		NameWithExtension = StrTemplate("%1.%2", NameWithExtension, Extension);
	EndIf;
	
	Return NameWithExtension;
	
EndFunction

// Gets the index of the file icon - the index in the image of the collection of pictogram files.
//
// Parameters:
//   FileExtention - String - file extension.
//
// Returns:
//   Number
//
Function IndexOfFileIcon(Val FileExtention) Export
	
	If TypeOf(FileExtention) <> Type("String") Or IsBlankString(FileExtention) Then
		Return 0;
	EndIf;
	
	FileExtention = CommonClientServer.ExtensionWithoutPoint(FileExtention);
	
	Extension = "." + Lower(FileExtention) + ";";
	
	If StrFind(".dt;.1cd;.cf;.cfu;", Extension) <> 0 Then
		Return 6; // 1C files.
		
	ElsIf Extension = ".mxl;" Then
		Return 8; // Table File.
		
	ElsIf StrFind(".txt;.log;.ini;", Extension) <> 0 Then
		Return 10; // A Text File.
		
	ElsIf Extension = ".epf;" Then
		Return 12; // External processing.
		
	ElsIf StrFind(".ico;.wmf;.emf;",Extension) <> 0 Then
		Return 14; // Pictures.
		
	ElsIf StrFind(".htm;.html;.url;.mht;.mhtml;",Extension) <> 0 Then
		Return 16; // HTML.
		
	ElsIf StrFind(".doc;.dot;.rtf;",Extension) <> 0 Then
		Return 18; // Microsoft Word file.
		
	ElsIf StrFind(".xls;.xlw;",Extension) <> 0 Then
		Return 20; // Microsoft Excel file.
		
	ElsIf StrFind(".ppt;.pps;",Extension) <> 0 Then
		Return 22; // Microsoft PowerPoint file.
		
	ElsIf StrFind(".vsd;",Extension) <> 0 Then
		Return 24; // Microsoft Visio file.
		
	ElsIf StrFind(".mpp;",Extension) <> 0 Then
		Return 26; // Microsoft Visio file.
		
	ElsIf StrFind(".mdb;.adp;.mda;.mde;.ade;",Extension) <> 0 Then
		Return 28; // Microsoft Access database.
		
	ElsIf StrFind(".xml;",Extension) <> 0 Then
		Return 30; // xml.
		
	ElsIf StrFind(".msg;.eml;",Extension) <> 0 Then
		Return 32; // An email message.
		
	ElsIf StrFind(".zip;.rar;.arj;.cab;.lzh;.ace;",Extension) <> 0 Then
		Return 34; // Archives.
		
	ElsIf StrFind(".exe;.com;.bat;.cmd;",Extension) <> 0 Then
		Return 36; // Executable files.
		
	ElsIf StrFind(".grs;",Extension) <> 0 Then
		Return 38; // Graphic diagram.
		
	ElsIf StrFind(".geo;",Extension) <> 0 Then
		Return 40; // Geographical scheme.
		
	ElsIf StrFind(".jpg;.jpeg;.jp2;.jpe;",Extension) <> 0 Then
		Return 42; // jpg.
		
	ElsIf StrFind(".bmp;.dib;",Extension) <> 0 Then
		Return 44; // bmp.
		
	ElsIf StrFind(".tif;.tiff;",Extension) <> 0 Then
		Return 46; // tif.
		
	ElsIf StrFind(".gif;",Extension) <> 0 Then
		Return 48; // gif.
		
	ElsIf StrFind(".png;",Extension) <> 0 Then
		Return 50; // png.
		
	ElsIf StrFind(".pdf;",Extension) <> 0 Then
		Return 52; // pdf.
		
	ElsIf StrFind(".odt;",Extension) <> 0 Then
		Return 54; // Open Office writer.
		
	ElsIf StrFind(".odf;",Extension) <> 0 Then
		Return 56; // Open Office math.
		
	ElsIf StrFind(".odp;",Extension) <> 0 Then
		Return 58; // Open Office Impress.
		
	ElsIf StrFind(".odg;",Extension) <> 0 Then
		Return 60; // Open Office draw.
		
	ElsIf StrFind(".ods;",Extension) <> 0 Then
		Return 62; // Open Office calc.
		
	ElsIf StrFind(".mp3;",Extension) <> 0 Then
		Return 64;
		
	ElsIf StrFind(".erf;",Extension) <> 0 Then
		Return 66; // External reports.
		
	ElsIf StrFind(".docx;",Extension) <> 0 Then
		Return 68; // Microsoft Word docx file.
		
	ElsIf StrFind(".xlsx;",Extension) <> 0 Then
		Return 70; // Microsoft Excel xlsx file.
		
	ElsIf StrFind(".pptx;",Extension) <> 0 Then
		Return 72; // Microsoft PowerPoint pptx file.
		
	ElsIf StrFind(".p7s;",Extension) <> 0 Then
		Return 74; // signature file.
		
	ElsIf StrFind(".p7m;",Extension) <> 0 Then
		Return 76; // encrypted message.
	Else
		Return 4;
	EndIf;
	
EndFunction

// Returns a string with the file size in a concise and easy-to-read format.
//
// Parameters:
//   Size - Number - file size in bytes.
//
// Returns:
//   String - file size as 123.4 KB
//
Function BriefSizePresentation(Val Size) Export
	
	If Size = 0 Then
		Return "-";
		
	ElsIf Size < 1024 * 10 Then // < 10 KB.
		Return StrTemplate(NStr("vi = '%1 Kb';
								|ru = '%1 Кб';
								|en = '%1 KB'; fa = '%1 KB';
								|it = '%1 KB';
								|pl = '%1 Kb';
								|tr = '%1 Kb'"), Format(SizeInKb(Size), "NG=0"));
		
	ElsIf Size < 1024 * 1024 Then // < 1 MB.
		Return StrTemplate(NStr("vi = '%1 Kb';
								|ru = '%1 Кб';
								|en = '%1 KB'; fa = '%1 KB';
								|it = '%1 KB';
								|pl = '%1 Kb';
								|tr = '%1 Kb'"), Format(SizeInKb(Size), "NG=0"));
		
	ElsIf Size < 1024 * 1024 * 10 Then // < 10 MB.
		Return StrTemplate(NStr("vi = '%1 Mb';
								|ru = '%1 Мб';
								|en = '%1 MB'; fa = '%1 MB';
								|it = '%1 MB';
								|pl = '%1 Mb';
								|tr = '%1 Mb'"), Format(SizeInMB(Size), "NG=0"));
		
	Else // >= 10 MB.
		Return StrTemplate(NStr("vi = '%1 Mb';
								|ru = '%1 Мб';
								|en = '%1 MB'; fa = '%1 MB';
								|it = '%1 MB';
								|pl = '%1 Mb';
								|tr = '%1 Mb'"), Format(SizeInMB(Size), "NG=0"));
		
	EndIf;
	
EndFunction

// Configures the parameters of the Form element.
//
// Parameters:
//   InputField - FormField - form element.
//   TypeDetails - TypeDescription - description of the value type in the input field.
//
Procedure ConfigureInputFieldByType(InputField, TypeDetails) Export
	
	FirstType = TypeDetails.Types()[0];
	If FirstType = Type("Date") Then
		InputField.SpinButton = True;
	ElsIf FirstType = Type("Number") Then
		InputField.SpinButton = True;
		NumberQualifiers = TypeDetails.NumberQualifiers;
		InputField.MaxValue =
			(Pow(10, NumberQualifiers.Digits) -1) / Pow(10, NumberQualifiers.FractionDigits);
		If NumberQualifiers.AllowedSign = AllowedSign.Nonnegative Then
			InputField.MinValue = 0;
		Else
			InputField.MinValue = 0 - InputField.MaxValue;
		EndIf;
	EndIf;
	
EndProcedure

// Constructor of the structure that describes the configuration of communication between objects BEFORE.
//
// Parameters:
//   LinkFrom - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   RefTo - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//   LinkType - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
// Returns:
//  Structure:
//     * LinkFrom - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * RefTo - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * LinkType - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * TypeOfLinkComment - String
//
Function SettingUpConnectionOfObjectsTO(LinkFrom, RefTo, LinkType) Export
	
	SettingUpConnectionOfObjectsTO = New Structure;
	SettingUpConnectionOfObjectsTO.Insert("LinkFrom", LinkFrom);
	SettingUpConnectionOfObjectsTO.Insert("RefTo", RefTo);
	SettingUpConnectionOfObjectsTO.Insert("LinkType", LinkType);
	SettingUpConnectionOfObjectsTO.Insert("TypeOfLinkComment", "");
	
	Return SettingUpConnectionOfObjectsTO;
	
EndFunction

// Constructor of the structure describing the authorization settings in 1C:Document management.
//
// Returns:
//  Structure:
//     * UserName - String - user name BEFORE, or
//                       - Undefined - indicates whether it is necessary to get the name stored in the session parameters.
//     * Password - String - the user's password BEFORE, or
//              - Undefined - a sign of the need to get a password saved in the session parameters.
//     * PasswordIsSaved - Boolean - True if the password is saved by the user.
//     * OSAuthenticationIsUsed - Boolean - True if operating system authentication is used.
//     * JWTAuthenticationIsUsed - Boolean - True if authentication via JWT tokens is used.
//     * Use_Cache - Boolean - The proxy will be obtained from the data recorded in the session parameters.
//
Function AuthorizationSettingsIn1CDocumentManagement() Export
	
	AuthorizationSettings = New Structure;
	AuthorizationSettings.Insert("UserName", Undefined);
	AuthorizationSettings.Insert("Password", Undefined);
	AuthorizationSettings.Insert("PasswordIsSaved", False);
	AuthorizationSettings.Insert("OSAuthenticationIsUsed", False);
	AuthorizationSettings.Insert("JWTAuthenticationIsUsed", False);
	AuthorizationSettings.Insert("Use_Cache", True);
	
	Return AuthorizationSettings;
	
EndFunction

// Returns empty parameters for creating a file to call
// integration1sdocumentobase function of the server call.Create a file in Document management.
//
// Parameters:
//   CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
// Returns:
//   Structure:
//     * CurrentFile - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//     * TempFileStorageAddress - Undefined
//     * Owner - Undefined
//     * IsScannedCopy - Boolean
//     * TemplateID - String
//     * ExternalObject - Structure:
//       ** ID - String
//       ** type - String
//       ** name - String
//
Function NewFileCreationOptions(CurrentFile) Export
	
	CreationParameters = New Structure;
	CreationParameters.Insert("CurrentFile", CurrentFile);
	CreationParameters.Insert("TempFileStorageAddress", Undefined);
	CreationParameters.Insert("Owner", Undefined);
	CreationParameters.Insert("IsScannedCopy", False);
	CreationParameters.Insert("TemplateID", "");
	CreationParameters.Insert("ExternalObject", New Structure("ID, type, name"));
	
	Return CreationParameters;
	
EndFunction

// Returns the data of the BEFORE object that was passed to the IP object form when it was created.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the IP object.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//
Function ObjectDMFromFormData(Form) Export
	
	If Form = Undefined Then
		Return ReferenceObjectDataDM("", "");
	EndIf;
	
	FormData1 = New Structure(
		"IntegrationWith1CDocumentManagement_ObjectIdentifierDM, IntegrationWith1CDocumentManagement_ObjectTypeDM");
	FillPropertyValues(FormData1, Form);
	
	// The command is used to pass the object ID TO when creating on the basis of.
	CommandID_ = Form.Commands.Find("ObjectIDDM");
	If CommandID_ <> Undefined Then
		FormData1.IntegrationWith1CDocumentManagement_ObjectIdentifierDM = CommandID_.Action;
	EndIf;
	
	Return ReferenceObjectDataDM(
		FormData1.IntegrationWith1CDocumentManagement_ObjectIdentifierDM,
		FormData1.IntegrationWith1CDocumentManagement_ObjectTypeDM);
	
EndFunction

// Constructor for the structure of notification parameters for receiving an HTML preview of an object.
//
// Returns:
//   Structure:
//     * ID - String - the ID of the object BEFORE.
//     * Type - String - type of the XDTO object.
//     * Extension - String - file extension.
//     * PresentationHTML - String - HTMLPresentation.
//     * PreviewCut - Boolean - indicates a stripped-down preview.
//     * BinaryData - BinaryData, Undefined - binary data of the file.
//
Function NotificationParametersReceivedHTMLObjectPreview() Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ID", "");
	NotificationParameters.Insert("Type", "");
	NotificationParameters.Insert("Extension", "");
	NotificationParameters.Insert("PresentationHTML", "");
	NotificationParameters.Insert("PreviewCut", False);
	NotificationParameters.Insert("BinaryData", Undefined);
	
	Return NotificationParameters;
	
EndFunction

// Returns a string with the file size in an easy-to-read format indicating the number of bytes.
//
// Parameters:
//   Size - Number - file size in bytes.
//
// Returns:
//   String - file size in the form of 123.4 KB (123 456 bytes)
//
Function DetailedSizePresentation(Val Size) Export
	
	If Size = 0 Then
		Return "-";
	EndIf;
	
	Return StrTemplate(NStr("vi = '%1 (%2 byte)';
							|ru = '%1 (%2 байт)';
							|en = '%1 (%2 bytes)'; fa = '%1 (%2 bytes)';
							|it = '%1 (%2 байт)';
							|pl = '%1 (%2 bytes)';
							|tr = '%1 (%2 bayt)'"),
		BriefSizePresentation(Size),
		Format(Size, "NFD=; NGS=' '; NG=3,0"));
	
EndFunction

// Get a string with a representation of the file size - for example, to display the State when transferring a file.
//
// Parameters:
//   SizeInMB - Number - Size in MB.
//
// Returns:
//   String - file size.
//
Function GetStringWithFileSize(Val SizeInMB) Export
	
	If SizeInMB < 0.1 Then
		SizeInMB = 0.1;
	EndIf;
	
	If SizeInMB >= 1 Then
		FormatString = "NFD=0";
	Else
		FormatString = "NFD=1; NZ=0";
	EndIf;
	
	Return Format(SizeInMB, FormatString);
	
EndFunction

// Returns the Presentation of the task participant BEFORE.
//
// Parameters:
//   Performer - String - Presentation of the performer. Role or employee.
//   MainAddressingObject - String - Presentation of the main addressing object.
//   AdditionalAddressingObject - String - Presentation of an additional addressing object.
//
// Returns:
//   String
//
Function PresentationOfTaskParticipant(Performer, MainAddressingObject, AdditionalAddressingObject) Export
	
	RowsArray = New Array;
	If ValueIsFilled(Performer) Then
		RowsArray.Add(Performer);
	EndIf;
	If ValueIsFilled(MainAddressingObject) Then
		RowsArray.Add(MainAddressingObject);
	EndIf;
	If ValueIsFilled(AdditionalAddressingObject) Then
		RowsArray.Add(AdditionalAddressingObject);
	EndIf;
	
	Return StrConcat(RowsArray, ", ");
	
EndFunction

// Splits the password into two independent parts for subsequent recovery by the function of a fellow password.
//
// Parameters:
//   Password - String - shared password.
//
// Returns:
//   Array of String - an array of two strings containing a hexadecimal representation of the password.
//
Function SplitPassword(Password) Export
	
	Result = New Array;
	Result.Add("");
	Result.Add("");
	Generator = Undefined;
	
	// Decompose the password into an array of numbers in pairs.
	ArrayOfNumbers = New Array;
	IndexOf = 1;
	While IndexOf <= StrLen(Password) Do
		Number = CharCode(Password, IndexOf);
		IndexOf = IndexOf + 1;
		If IndexOf <= StrLen(Password) Then
			Number = Number * 65536 + CharCode(Password, IndexOf);
			IndexOf = IndexOf + 1;
		EndIf;
		ArrayOfNumbers.Add(Number);
	EndDo;
	
	// Divide each of the resulting numbers.
	For Each Number In ArrayOfNumbers Do
		SplitNumber = DivideNumber(Number, Generator); // ((1, NNN), (2, MMM))
		Result[0] = Result[0] + HexadecimalPresentationOfNumber(SplitNumber[0][1], 8);
		Result[1] = Result[1] + HexadecimalPresentationOfNumber(SplitNumber[1][1], 8);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the file size in kilobytes.
//
// Parameters:
//   Size - Number - file size in bytes.
//
// Returns:
//   Number - file size in Kb.
//
Function SizeInKb(Val Size) Export
	
	If Size = 0 Then
		Return 0;
		
	ElsIf Size < 1024 * 10 Then // < 10 KB
		Return Max(1, Round(Size / 1024, 1, 1));
		
	Else
		Return Int(Size / 1024);
		
	EndIf;
	
EndFunction

// Returns the file size in megabytes.
//
// Parameters:
//   Size - Number - file size in bytes.
//
// Returns:
//   Number - file size in MB.
//
Function SizeInMB(Val Size) Export
	
	If Size = 0 Then
		Return 0;
		
	ElsIf Size < 1024 * 1024 * 10 Then // < 10 MB.
		Return Round(Size / 1024 / 1024, 1, 1);
		
	Else // >= 10 MB.
		Return Int(Size / 1024 / 1024);
		
	EndIf;
	
EndFunction

// Checks the file size against the maximum allowed size set in the integration settings.
//
// Parameters:
//   MaxFileSize1 - Number - the maximum allowed file size.
//   Size - Number - file size in bytes.
//   FileName - String - file name.
//   RaiseException1 - Boolean - raise an exception if the maximum size is exceeded.
//   MessageText - String - an implicitly returned value, the text of the message to the user.
//
// Returns:
//   Boolean - the file size exceeds the maximum allowed.
//
Function FileSizeExceedsMaximumAllowed(MaxFileSize1, Size, FileName,
		RaiseException1 = True, MessageText = "") Export
	
	If Size > MaxFileSize1 Then
		MessageText = StrTemplate(
			NStr("vi = 'Dung lượng tệp ""%1"" (%2) vượt quá dung lượng cho phép tối đa (%3).';
				|ru = 'Размер файла ""%1"" (%2) превышает максимально допустимый (%3).';
				|en = 'The size of file ""%1"" (%2) exceeds the maximum allowable size (%3).'; fa = 'The size of file ""%1"" (%2) exceeds the maximum allowable size (%3).';
				|it = 'La dimensione del file ""%1"" (%2) supera il limite consentito (%3).';
				|pl = 'Rozmiar pliku ""%1"" (%2) przekracza maksymalnie dopuszczalny (%3).';
				|tr = '""%1"" (%2) dosya boyutu izin verilen maksimum değeri aşıyor(%3).'"),
			FileName,
			BriefSizePresentation(Size),
			BriefSizePresentation(MaxFileSize1));
		If RaiseException1 Then
			Raise MessageText;
		Else
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Returns True if the file with this extension is in the list of extensions.
//
// Parameters:
//   ExtensionsList - String - List of extensions.
//   FileExtention - String - file extension.
//
// Returns:
//   Boolean
//
Function FileExtensionInList(ExtensionsList, FileExtention) Export
	
	FileExtentionWithoutDot = CommonClientServer.ExtensionWithoutPoint(FileExtention);
	
	ExtensionsArray = StrSplit(Lower(ExtensionsList), " ", False);
	
	If ExtensionsArray.Find(FileExtentionWithoutDot) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Constructor of the structure describing the file properties.
//
// Returns:
//   Structure:
//     * FileID - String - file id in 1C:Document flow.
//                          - Undefined
//     * FileName - String - file name.
//                - Undefined
//     * FileDetails - String - description of the file.
//                     - Undefined
//     * IsBeingEdited - Boolean - the file is currently being edited.
//                     - Undefined
//     * Encrypted - Boolean - the file is encrypted.
//                  - Undefined
//     * FileSignatureData - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//                           - Undefined
//     * FormUniqueID - UUID - ID of the calling form.
//                                    - Undefined
//     * FileOwner - String - id of the file owner in 1C:Document flow.
//                     - Undefined
//
Function FileProperties() Export
	
	FileProperties = New Structure;
	FileProperties.Insert("FileID", Undefined);
	FileProperties.Insert("FileName", Undefined);
	FileProperties.Insert("FileDetails", Undefined);
	FileProperties.Insert("IsBeingEdited", Undefined);
	FileProperties.Insert("Encrypted", Undefined);
	FileProperties.Insert("FileSignatureData", Undefined);
	FileProperties.Insert("FormUniqueID", Undefined);
	FileProperties.Insert("FileOwner", Undefined);
	
	Return FileProperties;
	
EndFunction

// Constructor of a structure that describes the missing relationship between objects BEFORE.
//
// Returns:
//  Structure:
//     * RefTo - String
//     * RefToID - String
//     * RefToType - String
//     * LinkTypeID - String
//     * Comment - String
//
Function ConnectionToCreation() Export
	
	ConnectionToCreation = New Structure;
	ConnectionToCreation.Insert("RefTo", "");
	ConnectionToCreation.Insert("RefToID", "");
	ConnectionToCreation.Insert("RefToType", "");
	ConnectionToCreation.Insert("LinkTypeID", "");
	ConnectionToCreation.Insert("Comment", "");
	
	Return ConnectionToCreation;
	
EndFunction

// Determines the availability of the service UP to by version number.
//
// Parameters:
//   ServiceVersion - String - service version BEFORE.
//
// Returns:
//   Boolean
//
Function ServiceIsAvailable(ServiceVersion) Export
	
	Return ServiceVersion <> "" And ServiceVersion <> "0.0.0.0";
	
EndFunction

// Collects the password from two parts previously separated by the Split Password function.
// In case of string corruption, returns Undefined.
//
// Parameters:
//   SeparatedPassword - Array of String - two lines containing a split password.
//
// Returns:
//   String - the collected password or
//   Undefined - if the lines are corrupted.
//
Function CollectPassword(Val SeparatedPassword) Export
	
	If SeparatedPassword.Count() <> 2 Then
		Return Undefined;
	EndIf;
	SeparatedPassword[0] = TrimAll(SeparatedPassword[0]);
	SeparatedPassword[1] = TrimAll(SeparatedPassword[1]);
	If StrLen(SeparatedPassword[0]) <> StrLen(SeparatedPassword[1]) Then
		Return Undefined;
	EndIf;
	If StrLen(SeparatedPassword[0]) % 8 <> 0 Then
		Return Undefined;
	EndIf;
	Result = "";
	Numbers_ = Int(StrLen(SeparatedPassword[0])) / 8;
	For NNumbers = 1 To Numbers_ Do
		SplitNumber = New Array;
		For NParts = 0 To 1 Do
			Pair = New Array;
			Pair.Add(NParts + 1);
			Presentation = Mid(SeparatedPassword[NParts], 1 + (NNumbers - 1) * 8, 8);
			Pair.Add(NumberFromHexadecimalPresentation(Presentation));
			SplitNumber.Add(Pair);
		EndDo;
		CollectedNumber = CollectNumber(SplitNumber);
		If CollectedNumber >= 65536 Then
			Result = Result + Char(Int(CollectedNumber / 65536));
		EndIf;
		Result = Result + Char(CollectedNumber % 65536);
	EndDo;
	
	Return Result;
	
EndFunction

// Displays the message in an HTML representation that will be displayed in the preview area.
//
// Parameters:
//   Message - String - a message for the preview area.
//   TitleOfMessageInPreviewArea - String - the header containing the message output settings.
//
// Returns:
//   String - HTML representation of the message.
//
Function PreviewMessage(Val Message, TitleOfMessageInPreviewArea) Export
	
	Result = New Array;
	Result.Add("<html>");
	Result.Add(TitleOfMessageInPreviewArea);
	Result.Add("<div class=""block"">");
	
	Message = StrReplace(Message, Chars.LF, "<br>");
	Result.Add(Message);
	
	Result.Add(
		"</div>
		|</body>
		|</html>");
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

// Displays a message that there is no HTML representation of the file.
//
// Parameters:
//   TitleOfMessageInPreviewArea - String - the header containing the message output settings.
//
// Returns:
//   String
//
Function MessageAboutAbsenceOfPreview(TitleOfMessageInPreviewArea) Export
	
	Return PreviewMessage(
		NStr("vi = 'Không có dữ liệu xem trước';
			|ru = 'Данные предпросмотра отсутствуют';
			|en = 'No preview data'; fa = 'No preview data';
			|it = 'No preview data';
			|pl = 'No preview data';
			|tr = 'Önizleme verisi mevcut değil'"), TitleOfMessageInPreviewArea);
	
EndFunction

// Displays a message about getting a preview.
//
// Returns:
//   String
//
Function DownloadMessage() Export
	
	Result = New Array;
	
	Result.Add(
		"<html><head><meta content=""text/html"" http-equiv=""Content-Type""></head><style>
		|.center {
		|	display: flex;
		|	align-items: center;
		|	position: absolute;
		|	top: 50%;
		|	left: 50%;
		|	transform: translate(-50%, -50%);}
		|</style><body><div class=""center""><img src=""data:image/gif;base64,
		|R0lGODlhMAAwAOMAAPzeNPzqfPzmVPzulPziRPzypPziNPzujPzqbPzynPzuhPzm
		|XPzunPziTPziPP3xpSH/C05FVFNDQVBFMi4wAwEAAAAh+QQJCQAPACwAAAAAMAAw
		|AAAE/vDJSessjA0mAwpHYo1keQ3HESgK9ywA4DhCMJj4mAxg0B+3V2woWwRzpoJq
		|+Qu4FgZAVBozGJGjAo/JbUlgVWLMEShgTwpu0/mdhqPwhfnMUHNVT6pbDJCfH1pN
		|anlDcHoyR0kDIg8agj9BUFR8iBIYJUogLpl3QC4HCA0Oh1EOQUqJFQw/Lo4qAxtZ
		|qwRuppYqXhYJd5soDHMmq6O2gFwuFGqaEhl/DFcPu02pBYJLx3+At4/ADwMKTd8p
		|2Kpb1RMJj9bjFJzby2mP1+uN6WwPdiAH3PN16QfF6eTNaxROUIZ6+wb2s5OhIJNU
		|AyWkiOfNDsSI5bhsgAVLgwZG0REpZNhIUmDIkyjHaeDIEiTKlSw7eutR0OTAmYMY
		|OOxxcSA+Tz9tjmtnjBo+odhW4TOT8Ye+k0SdvnuUC2M9F9GWRqzzE1jThxGjLvl3
		|rmtIV0322TmwCakFLYzQvnrLa5m3XzkaKgOU0aTSvY7C4R2R4YDDTeqybOkFLsUi
		|uyl2puj1lIQWxI96uOAhmZUltxcmBpVYDxfbP2IFBfn6qCcJuelWlwYxICEODD9p
		|S2A9NtY62Ew21/Md9msu0ZBAo+aqmfRYZikt/Pq4LAP0PxEAACH5BAkJAA8ALAAA
		|AAAwADAAg/zeNPzqdPzulPzmVPziTPzuhPzypPziNPzynPzqbPzqfPzunPzmXPzu
		|jPziPP3xpQT+8MlJ6zRriSX1QpwljqRkCE2jFEXYFIoqCEZpi4gQK3sjSAKYatio
		|3WyGYW/nKihVsUboWDktny3gdbkwUh8n5xYaCo53tO9j8byqXGflT21tK8vCOOJ4
		|2q91djFzQYFDIRgkSTGHdikbHSiBj2ADDF4VCz0hGmiTFhlPUiYEAAcKOKGHKF03
		|oIsdAwCyDlMTba9rtTcnh7GlsgxVbrhqVaQHsr9zQHkqQg3FmL6yyKXBEghxusUG
		|Dr/Us3MLYm3b0QrV1ckBEoVF0Z8E6sjIA2CF5vAK4MkAtJmBLsGbsMDbL3oApDRD
		|M1CEAXkAIkoEoIDQlWUNKSSIiBBZAg3UMzaI9JORQoMECRikXHmqpMuXJUGGDEny
		|pcyZIvPkyTfQTLlxWzC6LLQBH0xFdrqc4VkM4JYagNwIhIfUTYeFzphSiVoOWyEF
		|U9WwKeSF6xKh3NxRQEA2plkVAhsd0lpFgB9OcixUTbEpCCsbGYSo0iTCqag/KxaF
		|zfWC8D1idXHV2eHEx91IWA+feDeCl4lATLRgdYyITwpt7eKsOExl75hBqmWIfXtR
		|y1cfixOxiQPbnaemtN/YDkp319ssD04/+e0Sg3IFcIhkgFkYg90OGaYXiwAAIfkE
		|CQkADwAsAAAAADAAMACD/N40/Op0/O6U/OZU/OJM/O6E/PKk/OI0/PKc/Ops/Op8
		|/O6c/OZc/O6M/OI8/fGlBP7wyUnrNGuJJfVCnCWOpGQITaMURdgUiioIRmmLiBAr
		|eyNIAphq2KjdbIZhb+cqKFWxRuhYOS2fLeB1uTBSHyfnFhoKjne072PxvKpcZ+VP
		|bW0ry8I44njar3V2MXNBgUMhGCRJMYd2KRsdKIGPYCgkCz0hGmiTFhlPUiZDcxUI
		|n4coXTeei5CYFm2sa1N8k3VoVW6xalWBXg9mSkINuxWajRMIcbPEir0dYm3LxGtn
		|cI2+039jw81X0tkLeU8ZZ9jZa4UZ4rfnr4Ea0D2j7ROAVxszMx4CfvQTGfgCfvNH
		|sCAVDfkS9iPYIIHDhw4VAFvBxOCDBAAyaswYINyWecv0FhDYuFEBmzEDiSEYSRLA
		|gSLVCipwSfNARgcc7H0yx4zlRpsDnm3JQk+BzaMbA0goVa7dAgckjx6YonMJyF0G
		|CCDdyIACUzs81SwYkBHpywqNDqUU0acD2Y1BefUA9adFWArqYq2U+u2SoVZCUonw
		|JC7TW6VsAZ1a4sSHHw0p1qUwzODuCUZbKv6imM7EWgpJCsUSrcLJZ7mkB8Vhd7Cq
		|HdWp747AkFpLIR+nRxjbUuYMp3O2hhBNcS/3F9p3JJgyPq2LhscZMhCLAAAh+QQJ
		|CQAPACwAAAAAMAAwAAAE/vDJSessjA0mNUucJY6kVAzHEShKeCiBOgxFaYvJEAf7
		|MUgDmGp4qN1shWFv51IoVbFD6Fg5LZ8t4HXJMFIfJ+cWGgqOd7Tvg/G8qlxn5U9t
		|bSvLwnjieNqvdXYxc0GBQyEYJEkxh3YpGx0ogY9gKCQMPSEaaJMWGU9SJkNzFQmf
		|hyhdN56LkJgWbaxrU3yTdWhVbrFqVYFeD2ZKQge7FZqNEwlxs8SKvR1ibcvEa2dw
		|jb7Tf2PDzVfS2Qx5Txln2NlrhRnit+evgRrQPaPtE4BXGzMzHgN+9BMZ+AJ+80ew
		|IBUN+RL2I4gwoT5gK5gY/LXuTbgt8/wV2pCuYLdxzAWqFbzkzN4nc8wKDVtTccVA
		|NSa5SChVrh2bQl5iymn3scfKmTjBmdAZAFujQy9FMFgwxxg7Ch9B/WmBslgAAgAI
		|zPn4jWQsTUJSdbokwAAAAAa0tpJqoc6pJU58+DmAoAHWs2bPqqVUJFGtQBIfLMCL
		|9mzhrE2rtk2hTMJgw4QJO8iIpJA8x2YzG857doHiTkSfzHkMmbMBAwsW8mETZ7Rm
		|02gDJC3hNJpjyJEFUGamM4vg12h1T8TA+M1ttA4EBNg9EgM/CQEQ6PoSAQAh+QQJ
		|CQAOACwAAAAAMAAwAIP83jT86nz85lT87pT84kz88qT84jT87oz86mz88pz87oT8
		|5lz87pz84jz98aUAAAAE/tDJSessjA0mNUucJY6kVAzHEShKeCiBOgxFaYvJEAf7
		|MUgDmGp4qN1shWFv51IoVbFD6Fg5LZ8t4HXJMFIdJ+cWGgqOd7Svg/G8qlxn5U9t
		|bSvLwnjieNqvdXYxc0GBQyEYJEkxh3YpGx0ogY9gKCQMPSEaaJMWGU9SJkNzFQmf
		|hyhdN56LkJgWbaxrU3yTdWhVbrFqVYFeDmZKQge7FZqNEwlxs8SKvR1ibcvEa2dw
		|jb7Tf2PDzVfS2Qx5Txln2NlrhRnit+evgRrQPaPtE4BXGzMzHgN+9BMZ+AJ+80ew
		|IBUN+RL2I4gwoT5gK5gY/LXuTbgt8/wV2pCuYLdxyQWqFbzkzN4nc8wKDVtTccVA
		|NSa5SChVrh2bQl5iymn3scfKmTjpGVuCrdGhlyKSGBkqw8JHUGsENAiAsthFqLag
		|FnO1ZgEAAAYIBEjViY04RrqqADokAOxXsA0IIJijIUVFrCiqUjpE4K1bvwEkKNkS
		|C9GRBG0N/P2q2EDgX3EM0enrd/HXx4WWZESyoIFbxZ/BYs4sQ++IkJ4ZVwaAOU4A
		|ENkGLADd2G1rSUipyAb91rFgO2kMXhJgAPRtQRkmklKBYKWH5LsiAAAh+QQJCQAQ
		|ACwAAAAAMAAwAIT83jT86nT85lT87pT84kT87oT88qT84jT86mz88pz86nz85lz8
		|7pz84kz87oz84jz98aUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		|AAAAAAAAAAAAAAAF/iAkjmQ5GgwzMKLKJKwpz7RoDI6jFEXsFArdYGCoGWWJQVCx
		|dAxEA6Bu6igejYZpc+kraHVBR+xaum2/Peh5y7CSITfvGhyLzpfEN4TxPet8d1pP
		|emZ9WnVSgQlXN4t7SoZBg1GRUzEoNFlBl4Y5Ky04kZ9wODQMTTEqeKMmKV9iNlOD
		|JQmvlzhtR66boKgmfbx7Y4yjhXhlfsF6ZZFuEHZaUg7LJaqdIwmBw9SazS1yfdvU
		|e3eAnc7jj3PT3Wfi6QyJXyl36Ol7lSnyx/e/kSrgmszqNwLSmRVDhrgY4IjgiBQI
		|I75zSLEimQIIMmrMOM2iioQgGSAAQLIkSQQW0p/t+6PApEkBE8cZ/ILDZckHMZcZ
		|qMfgwQEAP4MCUFAx3hwWAmwCbWCPW6WOAYBK/QmUKMGZbFpQtYmzX611YxZMHbug
		|KRlrfkgM2GrywcBxxrSgEyv0gFsbOU006iXIxIAHbQdpymVEX7C47xQEvQtnnllX
		|8jgpKyOWMZ8tXpw4UpFjJSxSVWgkWDAIrRYualb6gpNXcqdglZZ4yVsGK7A6gfid
		|te1ORI7ceQhdzuc7kBizR+JmfXaH1b0bhsxtCV6UM2rmslKkrIaCIagUtE2EAAAh
		|+QQJCQAQACwAAAAAMAAwAIT83jT86nT85lT87pT84kT87oT88qT84jT86mz88pz8
		|6nz85lz87pz84kz87oz84jz98aUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		|AAAAAAAAAAAAAAAAAAAAAAAF/iAkjmQ5GgwzMKLKJKwpz7RoDI6jFEXsFArdYGCo
		|GWWJQVCxdAxEA6Bu6igejYZpc+kraHVBR+xaum2/Peh5y7CSITfvGhyLzpfEN4Tx
		|Pet8d1pPV1YqgQp1UoEJhAuDWYGDUX1fMSg0BgsABIOGXzkrLTiUCqFwODQKAKuc
		|NkpCpiYpn5ZTgyUDDwAHu617OG1Hs0ExnsQmmqvKvil6N5aveLi81LsAD7d6JJB9
		|bhDJyuEL3trGnyMMD9XVD2PaNoExAeHhBwHvsopfgwLW6wTk8PEh9SQdPWX38Mm6
		|k8WfvwPuFNogJUbVQQACIkqEQJEBAoe8ACDYaALHmigI11IuQLASgQOSJVSsGCJT
		|I8ybON/IHMJzAKOcO3vOVKTIpkQ7fVLok5aT4oqOOLmdaXPH6DsGDCFE+xTwndRz
		|e5bqSENyKxsRCSgq6Kozxxw3ZgVt/Nrk5Yi0b0maW0KOkhgbVmXc+Lk328S6xaIE
		|M6L02KkmNrFOSbyDGNtZ+mo5NmHm72MtXpwQHiXW840qmEzRBfNHjVjIgMlkUeuZ
		|9g7Psm07UWPbMOO4ZyQdcsIWE59IvOc4CVxjr5Y6d2JJ7NyErNt9zLWhuI5IBK3s
		|EtuoIJyimbYQACH5BAkJAA4ALAAAAAAwADAAg/zeNPzqfPzmVPzulPziTPzypPzi
		|NPzujPzqbPzynPzuhPzmXPzunPziPP3xpQAAAAT+0MlJ60wnBCXZYAljjWQ5MYHQ
		|AGwgHUqQDUNh3uOwrCxgAC4HTEY8HGy4m+7XYwJfmWjxIEpaCgGer7cNDqUZIgNp
		|dRQWTdbP6VWAZTFYrexgCLbctLfIz8QGdHV3W2tcbX19VTcFAwkdg1yFXm9gVBIF
		|ildRVQUEhWoECIB1NIhGVR6jIyibj6ABISOYlagDMZkXtI8NsDgMDK2kcQq4Qnwy
		|VbFljJwDfKqXfcGBFAWUAWQOtnxxB9QUHqbeEgmmyN8T1uZIDG6IxdSs7y/i2ejh
		|lN7qlPDf7aa/1qGzAAzgvzfQBk4w8s4WpYQKtZn6QIOGBw+OIoK7aNGixo/FIAem
		|qlgxI8iRJCnG2SAmpLaVUn7BJAJR4bUDH272o7YvEZZrOwPJe2PDWT5733pW6jDT
		|T1ArRuc5wCBQJENKZKIiVKh0CgWqWCPi42MvH6enFRhlHDtD05RaxJASPNisCLyh
		|tVhSkVsHGExO09IarSvFDc61A4w0tWQmMd/GgBG1lNjU7iW0l64CpHdzA2MrXR9K
		|0GquZgm2E0ebizKHzqzVo0hX+nBP9mTbMzAvkk0MSh/aIWfF5CyDim5/mBp1+PWL
		|WgQAO3NvM09ISGQyakJ4YUNGZ3RmVm9mbU5Ib3BSTDZ4WEw2eWhSOWNrZHBQVEFJ
		|Z2JlT2oxUEVxWDBTVnFFUXJsUDA="" width=""48"" height=""48""/>
		|<p style=""padding-left: 10px"">");
	Result.Add(NStr("ru = 'Получение предпросмотра';
					|vi = 'Get preview';
					|en = 'Get preview'; fa = 'Get preview';
					|it = 'Get preview';
					|pl = 'Get preview';
					|tr = 'Önizleme alınıyor'"));
	Result.Add("...</p></div></body></html>");
	
	Return StrConcat(Result);
	
EndFunction

// Displays a message about editing the file.
//
// Parameters:
//   TitleOfMessageInPreviewArea - String - the header containing the message output settings.
//
// Returns:
//   String
//
Function MessageAboutEditing(TitleOfMessageInPreviewArea) Export
	
	Return PreviewMessage(
		StrTemplate("%1<br>
			|<font color=""#006699""><a href = ""OpenForEdit"">%2</a></font>",
			NStr("vi = 'Bạn đã chiếm tệp này để soạn';
				|ru = 'Данный файл занят вами на редактирование';
				|en = 'You locked this file for editing'; fa = 'You locked this file for editing';
				|it = 'Данный файл занят вами на редактирование';
				|pl = 'You locked this file for editing';
				|tr = 'Bu dosya, düzenlenmek için tarafınızca alınmıştır'"),
			NStr("vi = 'Mở';
				|ru = 'Открыть';
				|en = 'Open'; fa = 'باز';
				|it = 'Открыть';
				|pl = 'Open';
				|tr = 'Aç'")),
		TitleOfMessageInPreviewArea);
	
EndFunction

// Retrieves a link from the client application form to an object that integrates with the software.
//
// Parameters:
//   Form - ClientApplicationForm - the form in which the link is searched.
//   AttributeName - String - the name of the Attribute that contains a link to the integrated with 1C:Document management object.
//   TypeOfIntegratedObject - Type - the type of link you want to find on the form.
//
// Returns:
//   AnyRef - reference to the object being integrated.
//
Function ReferenceToIntegratedObjectFromForm(Form, AttributeName = "", TypeOfIntegratedObject = Undefined) Export
	
	ReferenceToObjectBeingIntegrated = Undefined;
	
	FormAttributeValues = FormOfIntegratedObject();
	FillPropertyValues(FormAttributeValues, Form);
	
	// If the method was called in the event of the Attachment form in the server
	// Integration1sdocumentobase functionality.If you add a name to the server, the name of the Attribute containing
	// the object reference will be taken from the Attribute of the form. The name of the requesiteobject will be integrated into the document Flow.
	If ValueIsFilled(AttributeName) Then
		ReferenceToObjectBeingIntegrated = Form;
		For Each Attribute In StrSplit(AttributeName, ".") Do
			ReferenceToObjectBeingIntegrated = ReferenceToObjectBeingIntegrated[Attribute];
		EndDo;
	EndIf;
	
	// In other cases, we will check the Attributes of the Parameters form.Key and Object, if any.
	If ReferenceToObjectBeingIntegrated = Undefined
			And (TypeOf(FormAttributeValues.Parameters) = Type("FormDataStructure")
				Or TypeOf(FormAttributeValues.Parameters) = Type("Structure"))
			And FormAttributeValues.Parameters.Property("Key")
			And (TypeOfIntegratedObject = Undefined
				Or TypeOf(FormAttributeValues.Parameters.Key) = TypeOfIntegratedObject) Then
		ReferenceToObjectBeingIntegrated = FormAttributeValues.Parameters.Key;
	EndIf;
	If ReferenceToObjectBeingIntegrated = Undefined
			And (TypeOf(FormAttributeValues.Object) = Type("FormDataStructure")
				Or TypeOf(FormAttributeValues.Object) = Type("Structure"))
			And FormAttributeValues.Object.Property("Ref")
			And (TypeOfIntegratedObject = Undefined
				Or TypeOf(FormAttributeValues.Object.Ref) = TypeOfIntegratedObject) Then
		ReferenceToObjectBeingIntegrated = FormAttributeValues.Object.Ref;
	EndIf;
	
	Return ReferenceToObjectBeingIntegrated;
	
EndFunction

// Returns a message String indicating that the encrypted file cannot be signed.
//
// Parameters:
//   FileRef - AnyRef - file reference.
//
// Returns:
//   String
//
Function EncryptedFileCannotBeSignedMessageString(FileRef = Undefined) Export
	
	If FileRef = Undefined Then
		Return NStr("vi = 'Không thể ký tên tệp đã mã hóa.';
					|ru = 'Нельзя подписать зашифрованный файл.';
					|en = 'Cannot sign the file because it is encrypted.'; fa = 'Cannot sign the file because it is encrypted.';
					|it = 'Non si può firmare un file cifrato.';
					|pl = 'Nie można podpisać zaszyfrowany plik.';
					|tr = 'Şifrelenmiş dosya imzalanamıyor.'");
	Else
		Return StrTemplate(NStr("vi = 'Không thể ký tên tệp đã mã hóa: %1.';
								|ru = 'Нельзя подписать зашифрованный файл: %1.';
								|en = 'Cannot sign the file %1 because it is encrypted.'; fa = 'Cannot sign the file %1 because it is encrypted.';
								|it = 'Non si può firmare il file cifrato: %1.';
								|pl = 'Nie można podpisać zaszyfrowany plik: %1.';
								|tr = 'Şifrelenmiş dosya imzalanamıyor: %1.'"), FileRef);
	EndIf;
	
EndFunction

// Constructor of a structure that describes the type of operation on the task.
//
// Returns:
//   Structure:
//     * PerformTaskAction - Boolean
//     * TakeToWork - Boolean
//     * CancelTakingToWork - Boolean
//     * Forward - Boolean
//     * SetFlag - Boolean
//     * PerformConnectedTaskAction - Boolean
//     * PerformTemplateTaskAction - Boolean
//     * SelectTemplateForTask - Boolean
//     * CancelExecution - Boolean
//
Function TypeOfOperationOnTask() Export
	
	OperationType = New Structure;
	OperationType.Insert("PerformTaskAction", False);
	OperationType.Insert("TakeToWork", False);
	OperationType.Insert("CancelTakingToWork", False);
	OperationType.Insert("SetFlag", False);
	OperationType.Insert("Forward", False);
	OperationType.Insert("PerformConnectedTaskAction", False);
	OperationType.Insert("PerformTemplateTaskAction", False);
	OperationType.Insert("SelectTemplateForTask", False);
	OperationType.Insert("CancelExecution", False);
	
	Return OperationType;
	
EndFunction

// Processes the exception text for display to the user. Removes technical information from the text.
// The full text of the error should be placed in the registration Log.
//
// Parameters:
//   ErrorText - String - the exception text.
//
// Returns:
//   String
//
Function DeleteThoseInformationFromErrorText(Val ErrorText) Export
	
	ArrayOfErrorLines = StrSplit(ErrorText, Chars.LF);
	RowsCount = ArrayOfErrorLines.Count();
	For LineNumber = 1 To RowsCount Do
		RowIndex = RowsCount - LineNumber;
		ErrorString = ArrayOfErrorLines[RowIndex];
		If StrFind(ErrorString, "{CommonModule.") = 1
				Or StrFind(ErrorString, "{Catalog.") = 1
				Or StrFind(ErrorString, "{Document.") = 1
				Or StrFind(ErrorString, "{WebService.") = 1
				Or StrFind(ErrorString, "[ScriptRuntimeError") = 1
				Or (LineNumber > 1 And IsBlankString(ErrorString) And NextLineIsEmpty(ArrayOfErrorLines, RowIndex)) Then
			ArrayOfErrorLines.Delete(RowIndex);
		EndIf;
	EndDo;
	ArrayOfErrorLines.Add("");
	ArrayOfErrorLines.Add("-----");
	ArrayOfErrorLines.Add(NStr("vi = 'Chi tiết xem trong nhật ký sự kiện.';
								|ru = 'Подробности см. в журнале регистрации.';
								|en = 'See the Event log for details.'; fa = 'See the Event log for details.';
								|it = 'Vedere il registro per i dettagli.';
								|pl = 'Szczegóły zob. w dzienniku rejestracji.';
								|tr = 'Ayrıntılar için olay günlüğüne bakın.'"));
	
	Return StrConcat(ArrayOfErrorLines, Chars.LF);
	
EndFunction

// Constructor of the structure describing the form of the client application of the IP object.
//
// Returns:
//   Structure:
//     * FormName - String
//     * Parameters - Undefined
//     * Object - Undefined
//     * UseIntegrationBefore2 - Boolean
//     * UseIntegrationBefore3 - Boolean
//     * UseAttachedFiles1CDocumentManagement - Boolean
//     * NameOfAttributeOfObjectIntegratedWith1CDocumentManagement - String
//     * IntegrationWith1CDocumentManagement_ObjectTypeDM - String
//     * IntegrationWith1CDocumentManagement_ObjectIdentifierDM - String
//
Function FormOfIntegratedObject() Export
	
	Form = New Structure;
	Form.Insert("FormName", "");
	Form.Insert("Parameters", Undefined);
	Form.Insert("Object", Undefined);
	Form.Insert("UseIntegrationBefore2", False);
	Form.Insert("UseIntegrationBefore3", False);
	Form.Insert("UseAttachedFiles1CDocumentManagement", False);
	Form.Insert("NameOfAttributeOfObjectIntegratedWith1CDocumentManagement", "");
	Form.Insert("IntegrationWith1CDocumentManagement_ObjectTypeDM", "");
	Form.Insert("IntegrationWith1CDocumentManagement_ObjectIdentifierDM", "");
	
	Return Form;
	
EndFunction

// Checks whether the passed parameter is the structure of the notification parameters for receiving an HTML preview of the object.
//
// Parameters:
//   Parameter - See IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview
//
// Returns:
//   Boolean
//
Function TheseAreNotificationParametersHTMLObjectPreviewReceived(Parameter) Export
	
	If TypeOf(Parameter) <> Type("Structure") Then
		Return False;
	EndIf;
	
	For Each Item In NotificationParametersReceivedHTMLObjectPreview() Do
		If Not Parameter.Property(Item.Key) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Checks whether the transmitted value is an extension of the scanned copy.
//
// Parameters:
//   Extension - String - file extension.
//   ListOfExtensionsOfScannedCopiesOfOriginals - String - list of scan copy extensions.
//
// Returns:
//   Boolean - True if the passed value is an extension of the scanned copy.
//
Function ThisIsExtensionOfScannedCopy(Extension, Val ListOfExtensionsOfScannedCopiesOfOriginals) Export
	
	ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(Extension);
	
	ListOfExtensionsOfScannedCopiesOfOriginals = StrReplace(ListOfExtensionsOfScannedCopiesOfOriginals, " ", ",");
	ListOfExtensionsOfScannedCopiesOfOriginals = StrReplace(ListOfExtensionsOfScannedCopiesOfOriginals, ";", ",");
	ArrayOfScannedCopyExtensions = StrSplit(ListOfExtensionsOfScannedCopiesOfOriginals, ",", False);
	
	// If the scan copy extensions are not specified, then we do not automatically mark the scan copy.
	NumberOfScanCopyExtensions = ArrayOfScannedCopyExtensions.Count();
	If NumberOfScanCopyExtensions = 0 Then
		Return False;
	Else
		Return ArrayOfScannedCopyExtensions.Find(ExtensionWithoutPoint) <> Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region ASBS

// Adds State-based availability settings fields to the data structure.
//
// Parameters:
//   StructureOfData - Structure, ClientApplicationForm - an arbitrary structure that needs
//     to be supplemented with NDPS values.
//   InitialValue - Boolean - the initial value that you want to set.
//
Procedure AddPersonalData(StructureOfData, InitialValue = True) Export
	
	For Each Field In ASBSFields() Do
		StructureOfData.Insert(Field.Value);
	EndDo;
	
	If InitialValue <> Undefined Then
		SetValuesOfAllNDPSFields(StructureOfData, InitialValue);
	EndIf;
	
EndProcedure

// Checks the presence of a property in the structure or the presence of Attributes in the Form.
//
// Parameters:
//   StructureOfData - Structure, ClientApplicationForm - arbitrary structure.
//   PropertyName - String - name of the property to check for.
//
// Returns:
//   Boolean
//
Function ThereIsProperty(StructureOfData, PropertyName) Export
	
	If TypeOf(StructureOfData) = Type("Structure") Then
		Return StructureOfData.Property(PropertyName);
	Else
		FieldsInStructure = New Structure;
		AddPersonalData(FieldsInStructure, Undefined);
		FillPropertyValues(FieldsInStructure, StructureOfData);
		Return FieldsInStructure[PropertyName] <> Undefined;
	EndIf;
	
EndFunction

// Fills in the data structure with the State-based accessibility settings values from the source structure.
//
// Parameters:
//   ReceiverStructure - Structure, ClientApplicationForm - an arbitrary structure that needs
//     to be supplemented with NDPS values.
//   SourceStructure - Structure, ClientApplicationForm - an arbitrary structure that contains
//     the NDPS values.
//
Procedure FillInNDPOfPpeStructure(ReceiverStructure, SourceStructure) Export
	
	For Each Field In ASBSFields() Do
		If ThereIsProperty(ReceiverStructure, Field.Value) And ThereIsProperty(SourceStructure, Field.Value) Then
			ReceiverStructure[Field.Value] = SourceStructure[Field.Value];
		EndIf;
	EndDo;
	
EndProcedure

// Returns the correspondence of State availability settings fields stored in BID form Attributes
// to the names of XDTO properties.
// We do not use verification of the service version BEFORE, because checking for the presence of Attributes of forms is performed in the filling methods.
//
// Returns:
//   Map of KeyAndValue - The selection parameters:
//     * Key - String - the name of the XDTO property.
//     * Value - String - name of the BID Form Attributes.
//
Function ASBSFields() Export
	
	FieldsMap = New Map;
	FieldsMap["addfile"] = "StateAllowsFileAddition";
	FieldsMap["deletefile"] = "StateAllowsFileDeletion";
	FieldsMap["editfile"] = "StateAllowsFileEditing";
	FieldsMap["addscannedcopy"] = "StateAllowsAddingScannedCopy";
	FieldsMap["signatures"] = "StateAllowsChangesToItemInstance";
	FieldsMap["stateAllowsStartAndTerminateProcessing"] = "StateAllowsProcessingToBegin";
	FieldsMap["stateAllowsStopAndContinueProcessing"] = "StateAllowsYouToStopProcessing";
	FieldsMap["stateAllowsRestartProcessing"] = "StateAllowsYouToRestartProcessing";
	
	Return FieldsMap;
	
EndFunction

// Sets a specific value for all NDPS fields.
//
// Parameters:
//   StructureOfData - Structure, ClientApplicationForm - an arbitrary structure in which you want
//     to set the NDPS values.
//   Value - Boolean - the value that you want to install.
//
Procedure SetValuesOfAllNDPSFields(StructureOfData, Value) Export
	
	For Each Field In ASBSFields() Do
		If ThereIsProperty(StructureOfData, Field.Value) Then
			StructureOfData[Field.Value] = Value;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region DigitalSignatures

// The constructor of the structure intended for Transferring the address of the document impression and the addresses of the binary data of the files.
//
// Parameters:
//   FormUniqueID - UUID - ID of the calling form.
//   AddressOfDocumentImpression - String - the address of the temporary storage of binary data of the workflow document.
//
// Returns:
//   Structure:
//     * FormUniqueID - UUID - ID of the calling form.
//     * AddressOfDocumentImpression - String
//     * AddressesOfBinaryDataFiles - Map of KeyAndValue:
//       ** Key - String - file identifier.
//       ** Value - String - the address of the temporary binary data storage of the file.
//
Function AddressOfObjectSBinaryData(FormUniqueID, AddressOfDocumentImpression = "") Export
	
	AddressOfObjectSBinaryData = New Structure;
	AddressOfObjectSBinaryData.Insert("FormUniqueID", FormUniqueID);
	AddressOfObjectSBinaryData.Insert("AddressOfDocumentImpression", AddressOfDocumentImpression);
	AddressOfObjectSBinaryData.Insert("AddressesOfBinaryDataFiles", New Map);
	
	Return AddressOfObjectSBinaryData;
	
EndFunction

// Returns the signature owner's data structure.
//
// Parameters:
//   Description - String - the name of the object BEFORE.
//   ID - String - the ID of the object BEFORE.
//   Type - String - type of the XDTO object.
//   Encrypted - Boolean - the owner of the signature is encrypted.
//   SignaturesArray - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
// Returns:
//   Structure - signature owner data:
//     * Description - String - the name of the object BEFORE.
//     * ID - String - the ID of the object BEFORE.
//     * Type - String - type of the XDTO object.
//     * Encrypted - Boolean - the owner of the signature is encrypted.
//     * SignaturesArray - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//                      - Undefined
//
Function SignatureOwnerSDetails(Description, ID, Type, Encrypted, SignaturesArray = Undefined) Export
	
	If SignaturesArray = Undefined Then
		SignaturesArray = New Array;
	EndIf;
	
	SignatureOwnerSDetails = New Structure;
	SignatureOwnerSDetails.Insert("Description", Description);
	SignatureOwnerSDetails.Insert("ID", ID);
	SignatureOwnerSDetails.Insert("Type", Type);
	SignatureOwnerSDetails.Insert("Encrypted", Encrypted);
	SignatureOwnerSDetails.Insert("SignaturesArray", SignaturesArray);
	
	Return SignatureOwnerSDetails;
	
EndFunction

// Returns the data from which the XDTO DMSignature object will be generated for transmission to the DO.
//
// Parameters:
//   Signature - BinaryData - binary signature data.
//   CertificateBinaryData - BinaryData - binary data of the certificate.
//   SignatureProperties - Structure - There may be either a signature property structure that the BSP returns when
//     adding a new signature, or a signature table row if it is already an existing signature on the side BEFORE.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignature
//
Function SignatureData(Signature, CertificateBinaryData, SignatureProperties) Export
	
	SignatureData = StructureOfSignature();
	SignatureData.Signature = Signature;
	SignatureData.CertificateBinaryData = CertificateBinaryData;
	SignatureData.Thumbprint = SignatureProperties.Thumbprint;
	SignatureData.SignatureDate = SignatureProperties.SignatureDate;
	SignatureData.Comment = SignatureProperties.Comment;
	SignatureData.SignatureFileName = SignatureProperties.SignatureFileName;
	SignatureData.CertificateOwner = SignatureProperties.CertificateOwner;
	SignatureData.SignatureSetBy = String(SignatureProperties.SignatureSetBy);
	
	// If the signature already exists on the side BEFORE - the signerid will be filled in.
	// If this is a new signature that was generated on the IP client, we will transfer the ID of the IP user
	// who installed the signature.
	// If there is no user on the DO side using the transmitted identifier
	// , the current DO user under whom the connection to the DO was made through seamless integration will be considered the signatory.
	If SignatureProperties.Property("SignatureSetByID") Then
		SignatureData.SignatureSetByID = SignatureProperties.SignatureSetByID;
	Else
		SignatureData.SignatureSetByID = String(SignatureProperties.SignatureSetBy.UUID());
	EndIf;
	
	If TypeOf(SignatureProperties.SignatureType) = Type("String") Then
		SignatureData.SignatureType = SignatureProperties.SignatureType;
	Else
		MatchingCryptographySignatureTypesToXDTOEnumeration = MatchingCryptographySignatureTypesToXDTOEnumeration();
		SignatureData.SignatureType = MatchingCryptographySignatureTypesToXDTOEnumeration[SignatureProperties.SignatureType];
	EndIf;
	
	Return SignatureData;
	
EndFunction

// Complements the correspondence of object signatures.
//
// Parameters:
//   ObjectsSignatures - Map of KeyAndValue:
//     * Key - String - ID of the DO object that owns the signature.
//     * Value - See IntegrationWith1CDocumentManagementCoreClientServer.SignatureOwnerSDetails
//   Description - String - the name of the object BEFORE.
//   ID - String - the ID of the object BEFORE.
//   Type - String - type of the XDTO object.
//   Encrypted - Boolean - the owner of the signature is encrypted.
//   SignaturesArray - Array of See IntegrationWith1CDocumentManagementCoreClientServer.SignatureData
//
Procedure AddObjectCaptions(ObjectsSignatures, Description, ID, Type, Encrypted,
		SignaturesArray = Undefined) Export
	
	SignatureOwnerSDetails = ObjectsSignatures[ID];
	
	If SignatureOwnerSDetails = Undefined Then
		ObjectsSignatures.Insert(
			ID,
			SignatureOwnerSDetails(Description, ID, Type, Encrypted, SignaturesArray));
		
	ElsIf SignaturesArray <> Undefined Then
		CommonClientServer.SupplementArray(SignatureOwnerSDetails.SignaturesArray, SignaturesArray);
		
	EndIf;
	
EndProcedure

// Returns the structure of parameters for verifying a digital signature.
//
// Parameters:
//   RowData - FormDataTreeItem - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   MatchingObjectIDAndBinaryData - Map of KeyAndValue:
//     * Key - String - object identifier.
//     * Value - BinaryData - binary object data.
//   AddressOfObjectSBinaryData - See IntegrationWith1CDocumentManagementCoreClientServer.AddressOfObjectSBinaryData
//
// Returns:
//   Structure:
//     * FormatOfVerificationDate - String
//     * BinaryObjectData - BinaryData
//                             - Undefined
//     * Signature - BinaryData
//               - Undefined
//
Function DSVerificationParameters(RowData, MatchingObjectIDAndBinaryData, AddressOfObjectSBinaryData) Export
	
	DSVerificationParameters = New Structure;
	DSVerificationParameters.Insert("FormatOfVerificationDate", "");
	DSVerificationParameters.Insert("BinaryObjectData", Undefined);
	DSVerificationParameters.Insert("Signature", Undefined);
	
	If RowData.Encrypted Then
		RowData.History = False;
		RowData.SignatureCorrect = False;
		RowData.Status =
			NStr("vi = 'Chỉ có thể kiểm tra chữ ký tệp đã mã hóa trong 1C:Document management';
				|ru = 'Проверка подписи зашифрованного файла доступна только на стороне 1С:Документооборот';
				|en = 'You can check the signature of the encrypted file only in 1C:Document Management'; fa = 'You can check the signature of the encrypted file only in 1C:Document Management';
				|it = 'Проверка подписи зашифрованного файла доступна только на стороне 1С:Документооборот';
				|pl = 'You can check the signature of the encrypted file only in 1C:Document Management';
				|tr = 'Şifrelenmiş dosyanın imzasının doğrulanması yalnızca 1C:Document Management tarafında mevcuttur'");
		RowData.WhoReceivedCertificateAndStatus =
			RowData.CertificateOwner
			+ Chars.LF
			+ RowData.Status;
		Return DSVerificationParameters;
	EndIf;
	
	DSVerificationParameters.Signature = GetFromTempStorage(RowData.SignatureAddress); // BinaryData
	
	DSVerificationParameters.BinaryObjectData = MatchingObjectIDAndBinaryData[RowData.ObjectID];
	
	If DSVerificationParameters.BinaryObjectData = Undefined Then
		
		If RowData.ObjectType = "DMFile" Then
			FileBinaryDataAddress = AddressOfObjectSBinaryData.AddressesOfBinaryDataFiles[RowData.ObjectID];
			If IsTempStorageURL(FileBinaryDataAddress) Then
				DSVerificationParameters.BinaryObjectData = GetFromTempStorage(FileBinaryDataAddress); // BinaryData
			Else
				DSVerificationParameters.BinaryObjectData =
					IntegrationWith1CDocumentManagementCoreServerCall.FileBinaryData(
						RowData.ObjectID,
						False);
			EndIf;
		Else
			DSVerificationParameters.BinaryObjectData = GetFromTempStorage(AddressOfObjectSBinaryData.AddressOfDocumentImpression); // BinaryData
		EndIf;
		
		MatchingObjectIDAndBinaryData[RowData.ObjectID] = DSVerificationParameters.BinaryObjectData;
	EndIf;
	
	//@skip-check module-nstr-camelcase
	DSVerificationParameters.FormatOfVerificationDate = NStr("vi = 'DF=""dd.MM.yyyy HH:mm""';
															|ru = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
															|en = 'DF=""MM/dd/yyyy HH:mm""'; fa = 'DF=""MM/dd/yyyy HH:mm""';
															|it = 'ДФ=""дд.ММ.гггг ЧЧ:мм""';
															|pl = 'DF=""MM/dd/yyyy HH:mm""';
															|tr = 'DF=""dd.MM.yyyy HH:mm""'");
	
	Return DSVerificationParameters;
	
EndFunction

// Determines whether the signature is highlighted in the transmitted row data lines from the signature table.
//
// Parameters:
//   SelectedSignatures - See IntegrationWith1CDocumentManagementCoreClient.SelectedSignatures
//   RowData - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//
// Returns:
//   Boolean
//
Function SignatureHighlighted(SelectedSignatures, RowData) Export
	
	SignatureHighlighted = False;
	If TypeOf(SelectedSignatures) = Type("Array") Then
		For Each SelectedSignatureLine In SelectedSignatures Do
			If SelectedSignatureLine.ObjectID = RowData.ObjectID
					And SelectedSignatureLine.LineNumber = RowData.LineNumber Then
				SignatureHighlighted = True;
				Break;
			EndIf;
		EndDo;
	Else
		// You need to bypass all signatures
		SignatureHighlighted = True;
	EndIf;
	
	Return SignatureHighlighted;
	
EndFunction

// Returns the correspondence of the values of the enumeration type under the cryptography signature to the values of the type XDTO DMSignatureType.
//
// Returns:
//   Map of KeyAndValue - The selection parameters:
//     * Key - EnumRef.CryptographySignatureTypes
//     * Value - String
//
Function MatchingCryptographySignatureTypesToXDTOEnumeration() Export
	
	MapTypes = New Map;
	
	Try
		SignatureType = "Enum.CryptographySignatureTypes.NormalCMS";
		MapTypes.Insert(PredefinedValue(SignatureType), "CMS");
		
		SignatureType = "Enum.CryptographySignatureTypes.BasicCAdESBES";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESBES");
		
		SignatureType = "Enum.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESC");
		
		SignatureType = "Enum.CryptographySignatureTypes.WithTimeCAdEST";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdEST");
		
		SignatureType = "Enum.CryptographySignatureTypes.CAdESXLong";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESXLong");
		
		SignatureType = "Enum.CryptographySignatureTypes.CAdESXType1";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESXType1");
		
		SignatureType = "Enum.CryptographySignatureTypes.CAdESXType2";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESXType2");
		
		SignatureType = "Enum.CryptographySignatureTypes.CAdESXLongType1";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESXLongType1");
		
		SignatureType = "Enum.CryptographySignatureTypes.ExtendedLongCAdESXLongType2";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESXLongType2");
		
		SignatureType = "Enum.CryptographySignatureTypes.CAdESAv2";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESAv2");
		
		SignatureType = "Enum.CryptographySignatureTypes.ArchivalCAdESAv3";
		MapTypes.Insert(PredefinedValue(SignatureType), "CAdESAv3");
		
		SignatureType = "Enum.CryptographySignatureTypes.Undefined";
		MapTypes.Insert(PredefinedValue(SignatureType), "NotDefined");
	Except
		Raise NStr("vi = 'Không có phân hệ chuẩn ""Chữ ký điện tử"".';
					|ru = 'Отсутствует стандартная подсистема ""Электронная подпись"".';
					|en = 'The standard ""Digital signature"" subsystem is missing.'; fa = 'The standard ""Digital signature"" subsystem is missing.';
					|it = 'Отсутствует стандартная подсистема ""Электронная подпись"".';
					|pl = 'The standard ""Digital signature"" subsystem is missing.';
					|tr = 'Standart bir ""Elektronik İmza"" alt sistemi eksiktir.'");
	EndTry;
	
	Return MapTypes;
	
EndFunction

// Generates the Status of an electronic digital signature.
//
// Parameters:
//   History - Boolean - indicates that the digital signature is invalid.
//   ErrorDescription - String - contains a description of the digital signature verification error.
//
// Returns:
//   String
//
Function ItemInstanceStatus(History, ErrorDescription) Export
	
	Return ?(History,
		StrTemplate(NStr("ru = 'Подпись недействительна: %1';
						|vi = 'Invalid signature: %1';
						|en = 'Invalid signature: %1'; fa = 'Invalid signature: %1';
						|it = 'Invalid signature: %1';
						|pl = 'Invalid signature: %1';
						|tr = 'İmza geçersiz: %1'"), ErrorDescription),
		NStr("ru = 'Подпись действительна';
			|vi = 'Signature is valid';
			|en = 'Signature is valid'; fa = 'Signature is valid';
			|it = 'Signature is valid';
			|pl = 'Signature is valid';
			|tr = 'İmza geçerli'"));
	
EndFunction

// Returns a message String that indicates that a busy file cannot be signed.
//
// Parameters:
//   FileRef - AnyRef - file reference.
//
// Returns:
//   String
//
Function FileUsedByAnotherProcessCannotBeSignedMessageString(FileRef = Undefined) Export
	
	If FileRef = Undefined Then
		Return NStr("vi = 'Không thể ký tên tệp đã bị chiếm.';
					|ru = 'Нельзя подписать занятый файл.';
					|en = 'Cannot sign the file because it is locked.'; fa = 'Cannot sign the file because it is locked.';
					|it = 'Non si può firmare un file occupato.';
					|pl = 'Nie można podpisać zajęty plik.';
					|tr = 'Kilitli dosya imzalanamıyor.'");
	Else
		Return StrTemplate(NStr("vi = 'Không thể ký tên tệp đã bị chiếm: %1.';
								|ru = 'Нельзя подписать занятый файл: %1.';
								|en = 'Cannot sign the file %1 because it is locked.'; fa = 'Cannot sign the file %1 because it is locked.';
								|it = 'Non si può firmare il file occupato: %1.';
								|pl = 'Nie można podpisać zajęty plik: %1.';
								|tr = 'Kilitli dosya imzalanamıyor: %1.'"), FileRef);
	EndIf;
	
EndFunction

// Constructor of the structure describing the electronic signature data.
//
// Returns:
//   Structure:
//     * Signature - BinaryData
//               - Undefined
//     * SignatureSetBy - String
//                           - Undefined
//     * SignatureSetByID - String
//                             - Undefined
//     * Comment - String
//                   - Undefined
//     * SignatureFileName - String
//                       - Undefined
//     * SignatureDate - Date
//                   - Undefined
//     * SignatureValidationDate - Date
//                           - Undefined
//     * SignatureCorrect - Boolean
//                    - Undefined
//     * SignedObject - AnyRef
//                         - Undefined
//     * SequenceNumber - Number
//                       - Undefined
//     * IsVerificationRequired - Boolean
//                         - Undefined
//     * Certificate - ValueStorage
//                  - Undefined
//     * CertificateBinaryData - BinaryData
//                                 - Undefined
//     * Thumbprint - String
//                 - Undefined
//     * CertificateOwner - String
//                           - Undefined
//     * SignatureType - String
//                  - Undefined
//     * DateActionLastTimestamp - Date
//                                         - Undefined
//     * CertificateDetails - Structure
//                           - Undefined
//     * IsErrorOccurredDuringAutomaticRenewal - Boolean
//                                        - Undefined
//     * SignatureID - UUID
//                            - Undefined
//     * ResultOfSignatureVerificationByMRLOA - Array of Structure
//                                     - Structure
//                                     - Undefined
//
Function StructureOfSignature() Export
	
	SignatureData = New Structure;
	SignatureData.Insert("Signature", Undefined);
	SignatureData.Insert("SignatureSetBy", Undefined);
	SignatureData.Insert("SignatureSetByID", Undefined);
	SignatureData.Insert("Comment", Undefined);
	SignatureData.Insert("SignatureFileName", Undefined);
	SignatureData.Insert("SignatureDate", Undefined);
	SignatureData.Insert("SignatureValidationDate", Undefined);
	SignatureData.Insert("SignatureCorrect", Undefined);
	SignatureData.Insert("SignedObject", Undefined);
	SignatureData.Insert("SequenceNumber", Undefined);
	SignatureData.Insert("IsVerificationRequired", Undefined);
	
	SignatureData.Insert("Certificate", Undefined);
	SignatureData.Insert("CertificateBinaryData", Undefined);
	SignatureData.Insert("Thumbprint", Undefined);
	SignatureData.Insert("CertificateOwner", Undefined);
	SignatureData.Insert("SignatureType", Undefined);
	SignatureData.Insert("DateActionLastTimestamp", Undefined);
	
	SignatureData.Insert("CertificateDetails", Undefined);
	
	SignatureData.Insert("IsErrorOccurredDuringAutomaticRenewal", Undefined);
	SignatureData.Insert("SignatureID", Undefined);
	SignatureData.Insert("ResultOfSignatureVerificationByMRLOA", Undefined);
	
	Return SignatureData;
	
EndFunction

// Constructor of a structure describing a line in the signature tree.
//
// Parameters:
//   SignatureTreeString - FormDataTreeItem - Signature Tree String:
//     * SignatureAddress - String
//     * CertificateAddress - String
//     * SignatureDate - Date
//     * SignatureDateAndComment - String
//     * SignatureValidationDate - Date
//     * Encrypted - Boolean
//     * SignatureFileName - String
//     * Comment - String
//     * CertificateOwner - String
//     * WhoReceivedCertificateAndStatus - String
//     * History - Boolean
//     * LineNumber - Number
//     * Object - String
//     * ObjectID - String
//     * Object_Name - String
//     * ObjectType - String
//     * Thumbprint - String
//     * SignatureCorrect - Boolean
//     * Status - String
//     * SignatureType - String
//     * SignatureSetBy - String
//     * SignatureSetByID - String
//
// Returns:
//   Structure:
//     * SignatureAddress - String
//     * CertificateAddress - String
//     * SignatureDate - Date
//     * SignatureDateAndComment - String
//     * SignatureValidationDate - Date
//     * Encrypted - Boolean
//     * SignatureFileName - String
//     * Comment - String
//     * CertificateOwner - String
//     * WhoReceivedCertificateAndStatus - String
//     * History - Boolean
//     * LineNumber - Number
//     * Object - String
//     * ObjectID - String
//     * Object_Name - String
//     * ObjectType - String
//     * Thumbprint - String
//     * SignatureCorrect - Boolean
//     * Status - String
//     * SignatureType - EnumRef.CryptographySignatureTypes
//                  - Undefined
//     * SignatureSetBy - String
//     * SignatureSetByID - String
//
Function StructureOfSignatureTreeString(SignatureTreeString) Export
	
	StringStructure = New Structure;
	StringStructure.Insert("SignatureAddress", SignatureTreeString.SignatureAddress);
	StringStructure.Insert("CertificateAddress", SignatureTreeString.CertificateAddress);
	StringStructure.Insert("SignatureDate", SignatureTreeString.SignatureDate);
	StringStructure.Insert("SignatureDateAndComment", SignatureTreeString.SignatureDateAndComment);
	StringStructure.Insert("SignatureValidationDate", SignatureTreeString.SignatureValidationDate);
	StringStructure.Insert("Encrypted", SignatureTreeString.Encrypted);
	StringStructure.Insert("SignatureFileName", SignatureTreeString.SignatureFileName);
	StringStructure.Insert("Comment", SignatureTreeString.Comment);
	StringStructure.Insert("CertificateOwner", SignatureTreeString.CertificateOwner);
	StringStructure.Insert("WhoReceivedCertificateAndStatus", SignatureTreeString.WhoReceivedCertificateAndStatus);
	StringStructure.Insert("History", SignatureTreeString.History);
	StringStructure.Insert("LineNumber", SignatureTreeString.LineNumber);
	StringStructure.Insert("Object", SignatureTreeString.Object);
	StringStructure.Insert("ObjectID", SignatureTreeString.ObjectID);
	StringStructure.Insert("Object_Name", SignatureTreeString.Object_Name);
	StringStructure.Insert("ObjectType", SignatureTreeString.ObjectType);
	StringStructure.Insert("Thumbprint", SignatureTreeString.Thumbprint);
	StringStructure.Insert("SignatureCorrect", SignatureTreeString.SignatureCorrect);
	StringStructure.Insert("Status", SignatureTreeString.Status);
	StringStructure.Insert("SignatureSetBy", SignatureTreeString.SignatureSetBy);
	StringStructure.Insert("SignatureSetByID", SignatureTreeString.SignatureSetByID);
	
	StringStructure.Insert("SignatureType", Undefined);
	For Each Item In MatchingCryptographySignatureTypesToXDTOEnumeration() Do
		If Item.Value = SignatureTreeString.SignatureType Then
			StringStructure.SignatureType = Item.Key;
			Break;
		EndIf;
	EndDo;
	
	Return StringStructure;
	
EndFunction

// Converts a 2-level tree into an array.
//
// Parameters:
//   SignatureTree - FormDataTree - See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//   SelectedRows - Array of Number - selected lines in the signature tree.
//   ObjectID - String - filled in if you need to get signatures of a specific object.
//
// Returns:
//   Array of See IntegrationWith1CDocumentManagementCoreClientServer.StructureOfSignatureTreeString
//
Function SignatureTable(SignatureTree, SelectedRows = Undefined, ObjectID = Undefined) Export
	
	SignatureTable = New Array;
	
	If SelectedRows = Undefined Then
		
		FirstLevelElements = SignatureTree.GetItems();
		For Each RowLevelOne In FirstLevelElements Do
			SecondLevelElements = RowLevelOne.GetItems();
			For Each String In SecondLevelElements Do
				FitsByID = True;
				If ObjectID <> Undefined Then
					FitsByID = (String.ObjectID = ObjectID);
				EndIf;
				If Not IsBlankString(String.Object) And FitsByID Then
					SignatureTable.Add(StructureOfSignatureTreeString(String));
				EndIf;
			EndDo;
		EndDo;
		
	Else
		
		For Each Item In SelectedRows Do
			String = SignatureTree.FindByID(Item);
			FitsByID = True;
			If ObjectID <> Undefined Then
				FitsByID = (String.ObjectID = ObjectID);
			EndIf;
			If Not IsBlankString(String.Object) And FitsByID Then
				SignatureTable.Add(StructureOfSignatureTreeString(String));
			EndIf;
		EndDo;
		
	EndIf;
	
	Return SignatureTable;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Extract text from the ReadXml object (read from the OpenDocument file).
//
Function ExtractTextFromXMLContent(XMLReader)
	
	ExtractedText = "";
	LastTagName = "";
	
#If Not WebClient Then
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			LastTagName = XMLReader.Name;
			
			If XMLReader.Name = "text:p" Then
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.LF;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:line-break" Then
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.LF;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:tab" Then
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.Tab;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:s" Then
				
				AdditionString = " "; // Whitespace
				
				If XMLReader.AttributeCount() > 0 Then
					While XMLReader.ReadAttribute() Do
						If XMLReader.Name = "text:c" Then
							SpaceCount = Number(XMLReader.Value);
							AdditionString = "";
							For IndexOf = 0 To SpaceCount - 1 Do
								AdditionString = AdditionString + " "; // Whitespace
							EndDo;
						EndIf;
					EndDo
				EndIf;
				
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + AdditionString;
				EndIf;
			EndIf;
			
		EndIf;
		
		If XMLReader.NodeType = XMLNodeType.Text Then
			
			If StrFind(LastTagName, "text:") <> 0 Then
				ExtractedText = ExtractedText + XMLReader.Value;
			EndIf;
			
		EndIf;
		
	EndDo;
	
#EndIf
	
	Return ExtractedText;
	
EndFunction

// Returns a large prime number used as a module of the residue class ring.
// Must be greater than any of the encoded numbers.
//
// Returns:
//   Number
//
Function ModulusOfResidueRing()
	
	Return 4294967291; // more than any of the possible combinations of two password characters.
	
EndFunction

// Calculates the inverse module.
//
// Parameters:
//   Number_K - Number
//
// Returns:
//   Number - such that (Numerok * Inverse module(numerok)) % Modulus = 1 for all
//     positive numbers < Modulus.
//
Function ReverseModule(Val Number_K)
	
	Module = ModulusOfResidueRing();
	Number_K = Number_K % Module;
	
	If Number_K < 0 Then
		Decomposition = DecomposeNode(Module, -Number_K);
		Factorization = -Decomposition[2];
	Else
		Decomposition = DecomposeNode(Module, Number_K);
		Factorization = Decomposition[2];
	EndIf;
	
	Return (Module + Factorization) % Module;
	
EndFunction

// Divides the secret number into the specified number of parts according to Shamir's algorithm.
//
// Parameters:
//   Number - Number - a separable number, from 0 to 2^32 - 1.
//   Generator - RandomNumberGenerator - a random number generator, it is advisable to save it between calls.
//   Parts_ - Number - the number of parts into which the number is divided.
//   Mandatory - Number - the number of parts required for restoration.
//
// Returns:
//   Array of Number - array of pairs of numbers of the form (1, 123), (2, 234), (3, 345), necessary for recovery.
//
Function DivideNumber(Number, Generator = Undefined, Parts_ = 2, Mandatory = 2)
	
#If Not WebClient Then
	
	If Generator = Undefined Then
		Generator = New RandomNumberGenerator(CurrentDate() - Date(1, 1, 1)); // The use is justified: RNG.
	EndIf;
	Module = ModulusOfResidueRing();
	
	While True Do
		Result = New Array;
		Coefficients = New Array;
		Coefficients.Add(Number);
		Coefficients.Add(Int(Generator.RandomNumber(0, Module - 1)));
		Coefficients.Add(Int(Generator.RandomNumber(0, Module - 1)));
		For Term = 1 To Parts_ Do
			Value = Number;
			For Power = 1 To Mandatory - 1 Do
				Value = (Value + (Coefficients[Power] * (Pow(Term, Power) % Module)) % Module) % Module;
			EndDo;
			Pair = New Array;
			Pair.Add(Term);
			Pair.Add(Value);
			Result.Add(Pair);
		EndDo;
		If CollectNumber(Result) = Number Then
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
#Else
	
	Raise NStr("vi = 'Chức năng không được hỗ trợ trong Web-client.';
				|ru = 'Функция не поддерживается в веб-клиенте.';
				|en = 'Function is not supported in web client.'; fa = 'Function is not supported in web client.';
				|it = 'La funzione non è supportata nel client web.';
				|pl = 'Funkcja nie jest obsługiwana w kliencie webowym.';
				|tr = 'Bu fonksiyon, web istemcisinde desteklenmiyor.'");
	
#EndIf
	
EndFunction

// Performs the decomposition of the greatest common divisor of a pair of numbers A and B.
//
// Parameters:
//   Number_A - Number
//   NumberIn - Number
//
// Returns:
//   Array of Number - array (X, Y, Z) such that:
//     X is the greatest common divisor of NumerA and NumerA,
//     X = Numeral A * Y + Numeral * Z.
//
Function DecomposeNode(Val Number_A, Val NumberIn)
	
	Result = New Array;
	
	If NumberIn = 0 Then
		Result.Add(Number_A);
		Result.Add(1);
		Result.Add(0);
	Else
		Quotient = Int(Number_A / NumberIn);
		Module = Number_A % NumberIn;
		Decomposition = DecomposeNode(NumberIn, Module);
		Result.Add(Decomposition[0]);
		Result.Add(Decomposition[2]);
		Result.Add(Decomposition[1] - Decomposition[2] * Quotient);
	EndIf;
	
	Return Result;
	
EndFunction

// Checks if the row following the Cur row index is empty.
//
// Parameters:
//   RowsArray - Array of String - array of strings.
//   CurrentRowIndex - Number - index of the current row.
//
// Returns:
//   Boolean
//
Function NextLineIsEmpty(RowsArray, CurrentRowIndex)
	
	If CurrentRowIndex >= RowsArray.UBound() Then
		Return True;
	Else
		Return IsBlankString(RowsArray[CurrentRowIndex + 1])
	EndIf;
	
EndFunction

// Collects a number divided by Shamir's algorithm into parts by the Divide Number function.
//
// Parameters:
//   SplitNumber - Array of Number - array of pairs of numbers of the form (1, 123), (2, 234), ...
//
// Returns:
//   Number - original number.
//
Function CollectNumber(SplitNumber)
	
	Result = 0;
	Module = ModulusOfResidueRing();
	For String = 0 To SplitNumber.Count() - 1 Do
		Numerator = 1;
		Divisor = 1;
		For Column = 0 To SplitNumber.Count() - 1 Do
			If String = Column Then
				Continue;
			EndIf;
			dated = SplitNumber[String][0];
			Before = SplitNumber[Column][0];
			Numerator = (Numerator * -Before) % Module;
			Divisor = (Divisor * (dated - Before)) % Module;
		EndDo;
		Value = SplitNumber[String][1];
		Result = (Module + Result + (Value * Numerator * ReverseModule(Divisor))) % Module;
	EndDo;
	
	Return Result;
	
EndFunction

// Gets a number from its hexadecimal representation. May cause an exception.
//
// Parameters:
//   Presentation - String - hexadecimal number.
//
// Returns:
//   Number - the converted number.
//
Function NumberFromHexadecimalPresentation(Val Presentation)
	
	If Presentation = "" Then
		Return 0;
	EndIf;
	Presentation = Upper(Presentation);
	
	Result = 0;
	While Presentation <> "" Do
		Digit = Left(Presentation, 1);
		Presentation = Mid(Presentation, 2);
		If Digit >= "0" And Digit <= "9" Then
			Result = Result * 16 + CharCode(Digit, 1) - CharCode("0");
		ElsIf Digit >= "A" And Digit <= "F" Then
			Result = Result * 16 + 10 + CharCode(Digit, 1) - CharCode("A");
		Else
			Raise NStr("vi = 'Ký tự lỗi trong chuỗi thập lục phân.';
						|ru = 'Ошибочный символ в шестнадцатеричной строке.';
						|en = 'Invalid character in hexadecimal string.'; fa = 'Invalid character in hexadecimal string.';
						|it = 'Carattere non valido nella riga esadecimale.';
						|pl = 'Błędny symbol w wierszu szesnastkowym.';
						|tr = 'Onaltılı satırda geçersiz karakter.'");
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the hexadecimal representation of a number.
//
// Parameters:
//   Number - Number - integer.
//   Discharges - Number - the minimum width of the result.
//            - Undefined - do not add zeros.
//
// Returns:
//   String - hexadecimal representation of a number, possibly
//   padded with zeros up to the specified number of digits.
//
Function HexadecimalPresentationOfNumber(Val Number, Discharges = Undefined)
	
	If Number = 0 And Discharges = Undefined Then
		Return "0";
	EndIf;
	
	Result = "";
	NDischarge = 0;
	While True Do
		NDischarge = NDischarge + 1;
		If Number = 0 Then // It may need to be supplemented to the specified number of digits.
			If Discharges = Undefined Then
				Break;
			ElsIf NDischarge > Discharges Then
				Break;
			EndIf;
		EndIf;
		RightDischarge = Number % 16;
		Number = Int(Number / 16);
		If RightDischarge > 9 Then
			Result = Char(CharCode("A") + RightDischarge - 10) + Result;
		Else
			Result = Char(CharCode("0") + RightDischarge) + Result;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion