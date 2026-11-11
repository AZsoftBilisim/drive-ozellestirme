///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Initializes a structure of parameters for getting file data. See FilesOperations.FileData.
//
// Returns:
//  Structure:
//    * FormIdentifier             - UUID - a form UUID. The method puts the file to the temporary storage
//                                     of this form and returns the address in the RefToBinaryFileData property.
//                                     The default value is Undefined.
//    * GetBinaryDataRef - Boolean - if False, reference to the binary data in the RefToBinaryFileData
//                                     is not received thus significantly speeding up execution for large binary data.
//                                     The default value is True.
//    * ForEditing              - Boolean - if you specify True, a file will be locked for editing.
//                                     The default value is False.
//    * RaiseException1             - Boolean - if you specify False, the function will not raise
//                                     exceptions in exceptional situations and will return Undefined. The default value is True.
//    * FileGettingParameters		   - See FilesOperationsClientServer.FileGettingParameters. 
//    								   Default is Undefined.
//
Function FileDataParameters() Export
	
	DataParameters = New Structure;
	DataParameters.Insert("ForEditing",              False);
	DataParameters.Insert("FormIdentifier",             Undefined);
	DataParameters.Insert("RaiseException1",             True);
	DataParameters.Insert("GetBinaryDataRef", True);
	DataParameters.Insert("FileGettingParameters",		   Undefined);
	Return DataParameters;
	
EndFunction

// Initializes a structure of parameters for getting file data. See FilesOperationsInternalServerCall.FileDataToSave.
//
// Returns:
//  Structure:
//    * FileVersion             - CatalogRef.FilesVersions - a file version.
//    * FormIdentifier      - UUID - a form UUID.
//    * OwnerWorkingDirectory	- String - a working directory of the file owner.
//    * FileGettingParameters	- See FilesOperationsClientServer.FileGettingParameters
//
Function AdditionalParametersFileDataForSave() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FileVersion"				,Undefined);
	AdditionalParameters.Insert("FormIdentifier"		,Undefined);
	AdditionalParameters.Insert("OwnerWorkingDirectory"	,Undefined);
	AdditionalParameters.Insert("FileGettingParameters"	,Undefined);
	
	Return AdditionalParameters;
	
EndFunction

// FormGetProcessing event subscription handler for overriding the file form.
//
// Parameters:
//  Source                 - CatalogManager - the *AttachedFiles catalog manager.
//  FormType                 - String - a standard form name.
//  Parameters                - Structure - form parameters.
//  SelectedForm           - String - a name or metadata object of the form to open.
//  AdditionalInformation - Structure - additional information of the form opening.
//  StandardProcessing     - Boolean - indicates whether standard (system) event processing is executed.
//
Procedure DetermineAttachedFileForm(Source, FormType, Parameters,
	SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	FilesOperationsInternalServerCall.DetermineAttachedFileForm(
		Source,
		FormType,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
		
EndProcedure

// Returns user scanning settings.
// 
// Returns:
//  Structure:
//   * ShowScannerDialog - Boolean
//   * DeviceName - String - NameOfScanner
//   * ScannedImageFormat - EnumRef.ScannedImageFormats
//   * ShouldSaveAsPDF - Boolean
//   * MultipageStorageFormat - EnumRef.MultipageFileStorageFormats 
//   * Resolution - EnumRef.ScannedImageResolutions
//   * Chromaticity - EnumRef.ImageColorDepths
//   * Rotation - EnumRef.PictureRotationOptions
//   * PaperSize - EnumRef.PaperSizes
//   * DuplexScanning - Boolean
//   * DocumentAutoFeeder - Boolean
//   * UseImageMagickToConvertToPDF - Boolean
//   * JPGQuality - Number
//   * TIFFDeflation - EnumRef.TIFFCompressionTypes
//   * PathToConverterApplication - String
//
Function UserScanSettings() Export
	Result = New Structure;
	Result.Insert("ShowScannerDialog", False);
	Result.Insert("DeviceName", "");
	Result.Insert("ScannedImageFormat");
	Result.Insert("ShouldSaveAsPDF", False);
	Result.Insert("MultipageStorageFormat");
	Result.Insert("Resolution");
	Result.Insert("Chromaticity");
	Result.Insert("Rotation");
	Result.Insert("PaperSize");
	Result.Insert("DuplexScanning", False);
	Result.Insert("DocumentAutoFeeder", False);
	Result.Insert("UseImageMagickToConvertToPDF", False);
	Result.Insert("JPGQuality", 0);
	Result.Insert("TIFFDeflation");
	Result.Insert("PathToConverterApplication", "");
	Result.Insert("ScanLogCatalog");
	Result.Insert("UseScanLogDirectory", False);
	Return Result;
EndFunction

#EndRegion

#Region Internal

// Initializes the structure with file data.
//
// Parameters:
//   Mode        - String - File or FileWithVersion.
//   SourceFile - File   - the file on whose basis the structure properties are filled.
//
// Returns:
//   Structure:
//    * BaseName             - String - File name without the extension.
//    * ExtensionWithoutPoint           - String - a file extension.
//    * Modified               - Date   - date and time of file modification.
//    * ModificationTimeUniversal  - Date   - a date and a time of file modification (UTC).
//    * Size                       - Number  - File size in bytes.
//    * TempFileStorageAddress  - String
//                                     - ValueStorage - address in the temporary storage with binary data of the file
//                                       or binary data of the file.
//    * TempTextStorageAddress - String
//                                     - ValueStorage - address in the temporary storage with an extracted text
//                                       for the full-text search or data with the text.
//    * IsWebClient                 - Boolean - True if a call comes from the web client.
//    * Author                        - CatalogRef.Users - a file author. If Undefined, a current
//                                                                     user.
//    * Comment                  - String - a comment to the file.
//    * WriteToHistory             - Boolean - write to user work history.
//    * StoreVersions                - Boolean - allow storing file versions in the infobase.
//                                              When creating a new version, create a new version, or modify an
//                                              existing one (False).
//    * Encrypted                   - Boolean - the file is encrypted.
//
Function FileInfo1(Val Mode, Val SourceFile = Undefined) Export
	
	Result = New Structure;
	Result.Insert("BaseName");
	Result.Insert("Comment", "");
	Result.Insert("TempTextStorageAddress");
	Result.Insert("Author");
	Result.Insert("FilesStorageCatalogName", "Files");
	Result.Insert("TempFileStorageAddress");
	Result.Insert("ExtensionWithoutPoint");
	Result.Insert("Modified", Date('00010101'));
	Result.Insert("ModificationTimeUniversal", Date('00010101'));
	Result.Insert("Size", 0);
	Result.Insert("Encrypted");
	Result.Insert("WriteToHistory", False);
	Result.Insert("Encoding");
	Result.Insert("NewTextExtractionStatus");
	If Mode = "FileWithVersion" Then
		Result.Insert("StoreVersions", True);
		Result.Insert("RefToVersionSource");
		Result.Insert("NewVersionCreationDate");
		Result.Insert("NewVersionAuthor");
		Result.Insert("NewVersionComment");
		Result.Insert("NewVersionVersionNumber");
	Else
		Result.Insert("StoreVersions", False);
	EndIf;
	
	If SourceFile <> Undefined Then
		Result.BaseName            = SourceFile.BaseName;
		Result.ExtensionWithoutPoint          = CommonClientServer.ExtensionWithoutPoint(SourceFile.Extension);
		Result.Modified              = SourceFile.GetModificationTime();
		Result.ModificationTimeUniversal = SourceFile.GetModificationUniversalTime();
		Result.Size                      = SourceFile.Size();
	EndIf;
	Return Result;
	
EndFunction

Function FileGettingParameters() Export

	Result = New Structure;
	Result.Insert("AddressInParentSession");
	Result.Insert("CurrentVersionAddressInParentSession");
	Result.Insert("CheckForFileInArchive"			, True);
	Result.Insert("FileInArchive"							, False);

	Return Result;

EndFunction

// Returns a flag indicating whether files can be stored in disk volumes.
//
// Returns:
//  Boolean
//
Function ShouldStoreFilesInVolumes(FilesStorageMethod) Export

	Return FilesStorageMethod = "InVolumesOnHardDrive" Or FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive";

EndFunction

#EndRegion

#Region Private

// Determine whether the file can be locked. If not, generate error text.
//
// Parameters:
//  FileData  - Structure - a structure with file data.
//  MessageText - String - Return value.
//                            If failed to locked the file, contains error description.
//
// Returns:
//  Boolean - if True, the current user can lock the file
//           or the file is already locked by the current user.
//
Function WhetherPossibleLockFile(FileData, MessageText = "") Export
	
	If FileData.DeletionMark Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể soạn tệp ""%1"",
				|bởi vì nó đã bị đặt dấu xóa.';
				|ru = 'Невозможно отредактировать файл ""%1"",
				|т.к. он помечен на удаление.';
				|en = 'Cannot edit file ""%1""
				|as it is marked for deletion.'; fa = 'Cannot edit file ""%1""
				|as it is marked for deletion.';
				|it = 'Impossibile modificare il file ""%1"",
				|poiché è contrassegnato per l''eliminazione.';
				|pl = 'Nie można edytować pliku ""%1"",
				|ponieważ jest on zaznaczony do usunięcia.';
				|tr = '""%1"" dosyası silinmek üzere işaretlendiğinden
				| düzenlenemez.'"),
			String(FileData.Ref));
		Return False;
	EndIf;
	
	If FileData.IsInternal Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể soạn tệp hệ thống ""%1"".';
				|ru = 'Невозможно отредактировать служебный файл ""%1"".';
				|en = 'Cannot edit service file ""%1"".'; fa = 'Cannot edit service file ""%1"".';
				|it = 'Impossibile modificare il file di sistema ""%1"".';
				|pl = 'Nie można edytować pliku serwisowego ""%1"".';
				|tr = '""%1"" servis dosyası düzenlenemez.'"),
			String(FileData.Ref));
		Return False;
	EndIf;

	Result = Not ValueIsFilled(FileData.BeingEditedBy) Or FileData.CurrentUserEditsFile;  
	If Not Result Then
		If ValueIsFilled(FileData.LockedDate) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tệp ""%1""
					|đã bị người sử dụng ""%2"" chiếm để soạn từ %3.';
					|ru = 'Файл ""%1""
					|уже занят для редактирования пользователем ""%2"" с %3.';
					|en = 'File ""%1""
					| is locked for editing by user ""%2"" on %3.'; fa = 'File ""%1""
					| is locked for editing by user ""%2"" on %3.';
					|it = 'Il file ""%1"" 
					|è già utilizzato per la modifica da parte dell''utente ""%2"" con %3.';
					|pl = 'Plik ""%1""
					|jest już zajęty do edycji przez użytkownika ""%2"" od %3.';
					|tr = '""%1""
					| dosyası zaten düzenleme için ""%2"" kullanıcı tarafından %3 ile kilitlendi.'"),
				String(FileData.Ref), String(FileData.BeingEditedBy), Format(FileData.LockedDate, "DLF=DT"));
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tệp ""%1""
					|đã bị người sử dụng
					|""%2"" chiếm để soạn.';
					|ru = 'Файл ""%1""
					|уже занят для редактирования пользователем
					|""%2"".';
					|en = 'File ""%1""
					| is locked for editing by user
					|""%2"".'; fa = 'File ""%1""
					| is locked for editing by user
					|""%2"".';
					|it = 'Il file ""%1"" 
					|è già in modifica da parte dell''utente 
					|""%2"".';
					|pl = 'Plik ""%1""
					|jest już zajęty do edycji przez użytkownika
					|""%2"".';
					|tr = '""%1""
					| dosyası zaten düzenleme için 
					|""%2"" kullanıcısı tarafından kilitlendi.'"),
				String(FileData.Ref), String(FileData.BeingEditedBy));
		EndIf;
	EndIf;
		
	Return Result;
	
EndFunction

Function OneFileOnlyText() Export
	Return "OneFileOnly";
EndFunction

Function CommandsPrefix() Export
	Return "AttachedFilesManagement";
EndFunction

Function ImportFileCommandName() Export
	Return "ImportFile_";
EndFunction

Function CreateFromTemplateCommandName() Export
	Return "CreateByTemplate";
EndFunction

Function ScanCommandName() Export
	Return "Scan";
EndFunction

Function OpenListCommandName() Export
	Return "OpenList";
EndFunction

Function SelectFileCommandName() Export
	Return "SelectFile";
EndFunction

Function ViewFileCommandName() Export
	Return "ViewFile1";
EndFunction

Function ClearCommandName() Export
	Return "Clear";
EndFunction

Function OpenFormCommandName() Export
	Return "OpenForm";
EndFunction

Function EditFileCommandName() Export
	Return "EditFile";
EndFunction

Function PutFileCommandName() Export
	Return "PutFile";
EndFunction

Function CancelEditCommandName() Export
	Return "CancelEdit";
EndFunction

Function NameOfAdditionalCommandFromContextMenu() Export
	Return "FromContextMenu";
EndFunction

#EndRegion