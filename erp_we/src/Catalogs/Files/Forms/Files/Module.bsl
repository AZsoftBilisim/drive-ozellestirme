///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	ConditionalAppearance.Items.Clear();
	FilesOperationsInternal.FillConditionalAppearanceOfFilesList(List);
	FilesOperationsInternal.FillConditionalAppearanceOfFoldersList(Folders);
	FilesOperationsInternal.AddFiltersToFilesList(List);
	
	Items.ShowServiceFiles.Visible = Users.IsFullUser();
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		IsAccessRightsSetupCommandAvailable = ModuleAccessManagementInternal.IsAccessRightsSetupCommandAvailable();
	Else
		IsAccessRightsSetupCommandAvailable = False;
	EndIf;
	
	If Not Parameters.Folder.IsEmpty() Then
		InitialFolder = Parameters.Folder;
	Else
		InitialFolder = Common.FormDataSettingsStorageLoad("Files", "CurrentFolder");
		If InitialFolder = Undefined Then // An attempt to import settings, saved in the previous versions.
			InitialFolder = Common.FormDataSettingsStorageLoad("FileRepository", "CurrentFolder");
		EndIf;
	EndIf;
	
	If InitialFolder = Catalogs.FilesFolders.EmptyRef() Or InitialFolder = Undefined Then
		InitialFolder = Catalogs.FilesFolders.Templates;
	EndIf;
	
	SendOptions = ?(Parameters.SendOptions <> Undefined, Parameters.SendOptions,
		FilesOperationsInternal.PrepareSendingParametersStructure());
	Items.Folders.CurrentRow = InitialFolder;
	FilesStorageCatalogName = "Files";
	FileOwner = InitialFolder;
	
	CurrentUser = Users.AuthorizedUser();
	If TypeOf(CurrentUser) = Type("CatalogRef.ExternalUsers") Then
		FilesOperationsInternal.ChangeFormForExternalUser(ThisObject, True);
	EndIf;
	
	List.Parameters.SetParameterValue("Owner", InitialFolder);
	List.Parameters.SetParameterValue("CurrentUser", CurrentUser);
		
	EmptyUsers = New Array;
	EmptyUsers.Add(Undefined);
	EmptyUsers.Add(Catalogs.Users.EmptyRef());
	EmptyUsers.Add(Catalogs.ExternalUsers.EmptyRef());
	EmptyUsers.Add(Catalogs.FileSynchronizationAccounts.EmptyRef());
	List.Parameters.SetParameterValue("EmptyUsers",  EmptyUsers);

	Items.ListCurrentVersionSize.Visible = FilesOperationsInternal.ShowSizeColumn();
	
	UseHierarchy = True;
	SetHierarchy(UseHierarchy);
	
	OnChangeUseSignOrEncryptionAtServer();
	
	FileArchiveManagementServer.IsArchivePictureNumberListFieldVisibility(Items.ListIsPictureNumberArchive);
	
	FillPropertyValues(ThisObject, FolderRightsSettings(Items.Folders.CurrentRow));
	
	UsePreview1 = Common.CommonSettingsStorageLoad("Files", "Preview");
	If UsePreview1 <> Undefined Then
		Preview = UsePreview1;
		Items.FileDataURL.Visible = UsePreview1;
		Items.Preview.Check = UsePreview1;
	EndIf;
	PreviewEnabledExtensions = FilesOperationsInternal.ExtensionsListForPreview();
	
	Items.CloudServiceNoteGroup.Visible = False;
	UseFileSync = GetFunctionalOption("UseFileSync");

	HasDigitalSignature = Common.SubsystemExists("StandardSubsystems.DigitalSignature");
	Items.PrintWithStamp.Visible = HasDigitalSignature;
	
	Items.FoldersContextMenuSyncSettings.Visible = 
		AccessRight("Edit", Metadata.Catalogs.FileSynchronizationAccounts);
	Items.Compare.Visible = Not Common.IsLinuxClient()
		And Not Common.IsWebClient();
	Items.Send.Visible = Common.SubsystemExists("StandardSubsystems.EmailOperations");
	
	UniversalDate = CurrentSessionDate();
	List.Parameters.SetParameterValue("SecondsToLocalTime",
		ToLocalTime(UniversalDate, SessionTimeZone()) - UniversalDate);
	
	If Common.IsMobileClient() Then
		Items.Folders.TitleLocation = FormItemTitleLocation.Auto;
		Items.FormCreateSubmenu.Representation = ButtonRepresentation.Picture;
		Items.FormCreateFromScanner.Title = NStr("vi = 'Từ camera thiết bị...';
												|ru = 'С камеры устройства...';
												|en = 'From device camera…'; fa = 'From device camera…';
												|it = 'Dalla cella del dispositivo...';
												|pl = 'Z kamery urządzenia...';
												|tr = 'Cihazın kamerasından...'");
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	SSLSubsystemsIntegration.OnCreateFilesListForm(ThisObject);
	FilesOperationsOverridable.OnCreateFilesListForm(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.FormCreateFromScanner.Visible = FilesOperationsInternalClient.ScanAvailable();
	
	SetFileCommandsAvailability();
	
#If MobileClient Then
	SetFoldersTreeTitle();
#EndIf
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_ConstantsSet")
		And (Upper(Source) = Upper("UseDigitalSignature")
		Or Upper(Source) = Upper("UseEncryption")) Then
		
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.3, True);
		Return;
	ElsIf EventName = "Write_FilesFolders" Then
		Items.Folders.Refresh();
		Items.List.Refresh();
		
		If Source <> Undefined Then
			Items.Folders.CurrentRow = Source;
		EndIf;
	ElsIf EventName = "Write_File"
		And TypeOf(Source) <> Type("Array") Then
		
		Items.List.Refresh();
		If ValueIsFilled(Parameter.File) Then
			Items.List.CurrentRow = Parameter.File;
		ElsIf TypeOf(Source) = Type("CatalogRef.Files") Then
			Items.List.CurrentRow = Source;
		ElsIf Items.List.CurrentData <> Undefined Then
			Items.List.CurrentRow = Items.List.CurrentData.Ref;
		EndIf;
		
	EndIf;
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.FilesFolders.Form.ChoiceForm") Then
		
		If ValueSelected = Undefined Then
			Return;
		EndIf;
		
		SelectedRows = Items.List.SelectedRows;
		FilesOperationsInternalClient.MoveFilesToFolder(SelectedRows, ValueSelected);
		
		For Each SelectedRow In SelectedRows Do
			FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters("FileDataChanged");
			Notify("Write_File", FileWriteNotificationParameters, SelectedRow);
		EndDo;
		
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetHierarchy(Settings["UseHierarchy"]);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationSyncDateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "OpenJournal" Then
		
		StandardProcessing = False;
		FilterParameters      = EventLogFilterData(Items.Folders.CurrentData.Account);
		EventLogClient.OpenEventLog(FilterParameters, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	If TypeOf(RowSelected) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	HowToOpen = FilesOperationsInternalClient.PersonalFilesOperationsSettings().ActionOnDoubleClick;
	
	If HowToOpen = "OpenCard" Then
		ShowValue(, RowSelected);
		Return;
	EndIf;

	CurrentData = Item.CurrentData;
	
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("SelectModeAndEditFile");
	FileGettingParameters.AttachedFile				= RowSelected;
	FileGettingParameters.OwnerForm					= ThisObject;
	FileGettingParameters.CheckForFileInArchive	= False;
	FileGettingParameters.FileInArchive						= CurrentData.IsPictureNumberArchive = 0;

	FileGettingParameters.MethodParameters.FilePreviousURL = FilePreviousURL;
	
	ActionParameters = FileGettingParameters.ActionParameters;
	ActionParameters.OwnerForm						= ThisObject;
	ActionParameters.CommandEditAvailability	= Items.FormEdit.Enabled;

	FilesOperationsClient.OpenFile(FileGettingParameters);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Items.Folders.CurrentRow = Undefined Then
		Cancel = True;
		Return;
	EndIf; 
	
	If Items.Folders.CurrentRow.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf; 
	
	FileOwner = Items.Folders.CurrentRow;
	BasisFile = Items.List.CurrentRow;
	
	Cancel = True;
	
	If Copy Then
		If Item.CurrentData.IsPictureNumberArchive = 0 Then
			Return;
		EndIf;		
		FilesOperationsClient.CopyAttachedFile(FileOwner, BasisFile);
	Else
		FilesOperationsInternalClient.AppendFile(Undefined, FileOwner, ThisObject, 2, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	If FilesBeingEditedInCloudService Then
		DragParameters.Action = DragAction.Cancel;
		DragParameters.Value = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
	DragToFolder(Undefined, DragParameters.Value, DragParameters.Action);
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	If StandardSubsystemsClient.IsDynamicListItem(Items.List) Then
		URL = GetURL(Items.List.CurrentData.Ref);
	EndIf;
	IdleHandlerSetFileCommandsAccessibility();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters("FileDataChanged");
	Notify("Write_File", FileWriteNotificationParameters, Item.SelectedRows);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFolders

&AtClient
Procedure FoldersOnActivateRow(Item)
	
	AttachIdleHandler("SetCommandsAvailabilityOnChangeFolder", 0.1, True);
	
	If UseFileSync Then
		AttachIdleHandler("SetFilesSynchronizationNoteVisibility", 0.1, True);
	EndIf;
	
#If MobileClient Then
	AttachIdleHandler("SetFoldersTreeTitle", 0.1, True);
	CurrentItem = Items.List;
#EndIf
	
EndProcedure

&AtClient
Procedure FoldersDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure FoldersDrag(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
	DragToFolder(String, DragParameters.Value, DragParameters.Action);
EndProcedure

&AtClient
Procedure FoldersOnChange(Item)
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FilesImportExecute()
	
	Handler = New CallbackDescription("ImportFilesAfterExtensionInstalled", ThisObject);
	FilesOperationsInternalClient.ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

&AtClient
Procedure FolderImport(Command)
	
	Handler = New CallbackDescription("ImportFolderAfterExtensionInstalled", ThisObject);
	FilesOperationsInternalClient.ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

&AtClient
Procedure FolderExportExecute()
	
	FormParameters = New Structure;
	FormParameters.Insert("ExportFolder", Items.Folders.CurrentRow);
	
	Handler = New CallbackDescription("ExportFolderAfterInstallExtension", ThisObject, FormParameters);
	FilesOperationsInternalClient.ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

&AtClient
Procedure AppendFile(Command)
	
	FilesOperationsInternalClient.AddFileFromFileSystem(Items.Folders.CurrentRow, ThisObject);
	
EndProcedure

&AtClient
Procedure AddFileByTemplate(Command)
	
	AddingOptions = New Structure;
	AddingOptions.Insert("HandlerResults_1",                    Undefined);
	AddingOptions.Insert("FileOwner",                           Items.Folders.CurrentRow);
	AddingOptions.Insert("OwnerForm",                           ThisObject);
	AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
	FilesOperationsInternalClient.AddBasedOnTemplate(AddingOptions);
	
EndProcedure

&AtClient
Procedure AddFileFromScanner(Command)
	
	AddingOptions = FilesOperationsClient.AddingFromScannerParameters();
	AddingOptions.FileOwner  = Items.Folders.CurrentRow;
	AddingOptions.OwnerForm = ThisObject;
	FilesOperationsClient.AddFromScanner(AddingOptions);
	
EndProcedure

&AtClient
Procedure CreateCatalogExecute()
	
	NewFolderParameters = New Structure("Parent", Items.Folders.CurrentRow);
	OpenForm("Catalog.FilesFolders.ObjectForm", NewFolderParameters, Items.Folders);
	
EndProcedure

&AtClient
Procedure UseHierarchy(Command)
	
	UseHierarchy = Not UseHierarchy;
	If UseHierarchy And (Items.List.CurrentData <> Undefined) Then 
		CurrentRow = Undefined;
		Items.List.CurrentData.Property("FileOwner", CurrentRow); 
		Items.Folders.CurrentRow = CurrentRow;
		List.Parameters.SetParameterValue("Owner", CurrentRow);
	EndIf;	
	SetHierarchy(UseHierarchy);
	
EndProcedure

&AtClient
Procedure OpenFileExecute()
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;

	CurrentData = Items.List.CurrentData;

	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("OpenFile");
	FileGettingParameters.AttachedFile				= CurrentData.Ref;
	FileGettingParameters.OwnerForm					= ThisObject;
	FileGettingParameters.CheckForFileInArchive	= False;
	FileGettingParameters.FileInArchive						= CurrentData.IsPictureNumberArchive = 0;

	FileGettingParameters.MethodParameters.FilePreviousURL = FilePreviousURL;

	FilesOperationsClient.OpenFile(FileGettingParameters);

EndProcedure

&AtClient
Procedure Edit(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject);
	FilesOperationsInternalClient.EditWithNotification(Handler, Items.List.CurrentRow);
	
EndProcedure

&AtClient
Function FileCommandsAvailable()
	
	Return FilesOperationsInternalClient.FileCommandsAvailable(Items);
	
EndFunction

&AtClient
Procedure EndEdit(Command)
	
	FilesArray = New Array;
	For Each ListItem In Items.List.SelectedRows Do
		RowData = Items.List.RowData(ListItem);
		
		If Not RowData.FileBeingEdited
			Or Not RowData.CurrentUserEditsFile Then
			Continue;
		EndIf;
		FilesArray.Add(RowData.Ref);
	EndDo;
	
	If FilesArray.Count() > 1 Then
		FormParameters = New Structure;
		FormParameters.Insert("FilesArray",                     FilesArray);
		FormParameters.Insert("CanCreateFileVersions", True);
		FormParameters.Insert("BeingEditedBy",                      RowData.BeingEditedBy);
		
		OpenForm("DataProcessor.FilesOperations.Form.FinishingEditing", FormParameters, ThisObject);
	ElsIf FilesArray.Count() = 1 Then
		Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject);
		FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(Handler, RowData.Ref, UUID);
		FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Lock(Command)
	
	If Not FileCommandsAvailable() Then
		Return;
	EndIf;
	
	FilesCount = Items.List.SelectedRows.Count();
	
	If FilesCount = 1 Then
		Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject);
		FilesOperationsInternalClient.LockWithNotification(Handler, Items.List.CurrentRow);
	ElsIf FilesCount > 1 Then
		FilesArray = New Array;
		For Each ListItem In Items.List.SelectedRows Do
			RowData = Items.List.RowData(ListItem);
			
			If ValueIsFilled(RowData.BeingEditedBy) Then
				Continue;
			EndIf;
			FilesArray.Add(RowData.Ref);
		EndDo;
		Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject, FilesArray);
		FilesOperationsInternalClient.LockWithNotification(Handler, FilesArray);
	EndIf;
	
EndProcedure

&AtClient
Procedure Release(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FilesOperationsInternalClient.UnlockFiles(Items.List);
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure SaveChanges(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	Handler = New CallbackDescription("SetFileCommandsAvailability", ThisObject);
	
	FilesOperationsInternalClient.SaveFileChangesWithNotification(
		Handler,
		Items.List.CurrentRow,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenFileDirectory(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(Items.List.CurrentRow,
		Undefined, UUID, Undefined, FilePreviousURL);
	FilesOperationsClient.OpenFileDirectory(FileData);
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("SaveAs", "FilesOperationsInternal.FileDataToSaveAsync");
	FileGettingParameters.AttachedFile				= CurrentData.Ref;
	FileGettingParameters.OwnerForm					= ThisObject;
	FileGettingParameters.CheckForFileInArchive	= False;
	FileGettingParameters.FileInArchive						= CurrentData.IsPictureNumberArchive = 0;
	
	FileGettingParameters.ActionParameters.UUID = UUID;
	
	FilesOperationsClient.SaveFileAs(FileGettingParameters);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(Items.List.CurrentRow);
	FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(Undefined, FileData, UUID);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	Cancel = True;
	
	FormOpenParameters = New Structure("Key, SendOptions", Item.CurrentRow, SendOptions);
	OpenForm("Catalog.Files.ObjectForm", FormOpenParameters);
	
EndProcedure

&AtClient
Procedure MoveToFolder(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Title",    NStr("vi = 'Chọn thư mục';
											|ru = 'Выбор папки';
											|en = 'Select folder'; fa = 'انتخاب پوشه';
											|it = 'Scelta della cartella';
											|pl = 'Wybór folderu';
											|tr = 'Klasör seçimi'"));
	FormParameters.Insert("CurrentFolder", Items.Folders.CurrentRow);
	FormParameters.Insert("ChoiceMode",  True);
	
	OpenForm("Catalog.FilesFolders.ChoiceForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Sign(Command)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	CallbackDescription      = New CallbackDescription("SignCompletion", ThisObject);
	AdditionalParameters = New Structure("ResultProcessing", CallbackDescription);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SigningParameters = ModuleDigitalSignatureClient.NewSignatureType();
	SigningParameters.CanSelectLetterOfAuthority = True;
	SigningParameters.AllowSendingForSigning = True;

	FilesOperationsClient.SignFile(Items.List.SelectedRows, UUID, AdditionalParameters,
		SigningParameters);
	
EndProcedure
	
&AtClient
Procedure SendForSigning(Command)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	CallbackDescription      = New CallbackDescription("SignCompletion", ThisObject);
	AdditionalParameters = New Structure("ResultProcessing", CallbackDescription);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SigningParameters = ModuleDigitalSignatureClient.NewSignatureType();
	SigningParameters.CanSelectLetterOfAuthority = True;

	FilesOperationsClient.SendFileForSigning(Items.List.SelectedRows, UUID, AdditionalParameters,
		SigningParameters);
		
EndProcedure

&AtClient
Procedure Encrypt(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	ObjectRef = Items.List.CurrentRow;
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(ObjectRef);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	Handler = New CallbackDescription("EncryptAfterEncryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Encrypt(Handler, FileData, UUID);
	
EndProcedure

&AtClient
Procedure Decrypt(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	ObjectRef = Items.List.CurrentRow;
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(ObjectRef);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	Handler = New CallbackDescription("DecryptAfterDecryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Decrypt(
		Handler,
		FileData.Ref,
		UUID,
		FileData);
	
EndProcedure

&AtClient
Procedure AddSignatureFromFile(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FilesOperationsInternalClient.AddSignatureFromFile(
		Items.List.CurrentRow,
		UUID,
		New CallbackDescription("SetFileCommandsAvailability", ThisObject));
	
EndProcedure

&AtClient
Procedure SaveWithSignature(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	FilesOperationsInternalClient.SaveFileWithSignature(
		Items.List.CurrentRow, UUID);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	Items.Folders.Refresh();
	Items.List.Refresh();
	
	AttachIdleHandler("SetCommandsAvailabilityOnChangeFolder", 0.1, True);
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	CurrentData = Items.Folders.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OnSendFilesViaEmail(SendOptions, Items.List.SelectedRows, CurrentData.Ref, 
		UUID);
	FilesOperationsInternalClient.SendFilesViaEmail(
		Items.List.SelectedRows, UUID, SendOptions, True);
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	If Not FileCommandsAvailable() Then 
		Return;
	EndIf;
	
	SelectedRows = Items.List.SelectedRows;
	If SelectedRows.Count() > 0 Then
		FilesOperationsClient.PrintFiles(SelectedRows, UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintWithStamp(Command)

	CurrentData = CurrentData();
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FilesOperationsInternalClient.DoPrintFileWithStamp(CurrentData.Ref, UUID);

EndProcedure

&AtClient
Procedure Preview(Command)
	
	Preview = Not Preview;
	Items.Preview.Check = Preview;
	SetPreviewVisibility(Preview);
	SavePreviewOption("Files", Preview);
	
#If WebClient Then
	UpdatePreview1();
#EndIf
	
EndProcedure

&AtClient
Procedure SyncSettings(Command)
	
	SyncSetup = SynchronizationSettingsParameters(Items.Folders.CurrentData.Ref);
	
	If ValueIsFilled(SyncSetup.Account) Then
		ValueType = Type("InformationRegisterRecordKey.FileSynchronizationSettings");
		WriteParameters = New Array(1);
		WriteParameters[0] = SyncSetup;
		
		RecordKey = New(ValueType, WriteParameters);
	
		WriteParameters = New Structure;
		WriteParameters.Insert("Key", RecordKey);
	Else
		SyncSetup.Insert("IsFile", True);
		WriteParameters = SyncSetup;
	EndIf;
	
	OpenForm("InformationRegister.FileSynchronizationSettings.Form.SimpleRecordFormSettings", WriteParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Compare(Command)

	If Items.List.SelectedRows.Count() <> 2 Then
		Return;
	EndIf;

	FirstFile = Items.List.SelectedRows[0];
	SecondFile = Items.List.SelectedRows[1];
	Extension = Lower(Items.List.CurrentData.Extension);
	FilesOperationsInternalClient.CompareFiles(UUID, FirstFile, SecondFile, Extension);
	
EndProcedure

&AtClient
Procedure ShowServiceFiles(Command)
	
	Items.ShowServiceFiles.Check = 
		FilesOperationsInternalClient.ShowServiceFilesClick(List);
	
EndProcedure

&AtClient
Procedure Delete(Command)
	
	SelectedRows = SelectedRows();
	
	CallbackDescription = New CallbackDescription("AfterDeleteData", ThisObject);
	FilesOperationsInternalClient.DeleteFilesData(CallbackDescription, SelectedRows, UUID);
	
EndProcedure

&AtClient
Procedure ShowMarkedFiles(Command)
	
	FilesOperationsInternalClient.ChangeFilterByDeletionMark(List.Filter, Items.ShowMarkedFiles);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportFilesAfterExtensionInstalled(Result, ExecutionParameters) Export
	If Not Result Then
		FilesOperationsInternalClient.Show1CEnterpriseExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																							|ru = 'Все файлы (%1)|%1';
																							|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																							|it = 'Все файлы (%1)|%1';
																							|pl = 'All files (%1)|%1';
																							|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	OpenFileDialog.Multiselect = True;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn tệp';
								|ru = 'Выберите файлы';
								|en = 'Select files'; fa = 'انتخاب فایل‌ها';
								|it = 'Scegliete i file';
								|pl = 'Wybierz pliki';
								|tr = 'Dosyaları seçin'");
	If Not OpenFileDialog.Choose() Then
		Return;
	EndIf;
	
	FileNamesArray = New Array;
	For Each FileName In OpenFileDialog.SelectedFiles Do
		FileNamesArray.Add(FileName);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", Items.Folders.CurrentRow);
	FormParameters.Insert("FileNamesArray",   FileNamesArray);
	
	OpenForm("DataProcessor.FilesOperations.Form.LoadFiles", FormParameters);
EndProcedure

&AtClient
Procedure ImportFolderAfterExtensionInstalled(Result, ExecutionParameters) Export
	
	If Not Result Then
		FilesOperationsInternalClient.Show1CEnterpriseExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																							|ru = 'Все файлы (%1)|%1';
																							|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																							|it = 'Все файлы (%1)|%1';
																							|pl = 'All files (%1)|%1';
																							|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn thư mục';
								|ru = 'Выберите каталог';
								|en = 'Select directory'; fa = 'Select directory';
								|it = 'Scegliete la directory';
								|pl = 'Wybierz katalog';
								|tr = 'Dizini seçin'");
	If Not OpenFileDialog.Choose() Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", Items.Folders.CurrentRow);
	FormParameters.Insert("DirectoryOnHardDrive",     OpenFileDialog.Directory);
	
	OpenForm("DataProcessor.FilesOperations.Form.ImportingFolder", FormParameters);

EndProcedure

&AtClient
Procedure ExportFolderAfterInstallExtension(Result, FormParameters) Export
	
	If Not Result Then
		FilesOperationsInternalClient.Show1CEnterpriseExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	OpenForm("DataProcessor.FilesOperations.Form.SavingFolder", FormParameters);
	
EndProcedure

&AtClient
Procedure DragToFolder(FolderForAdding, DragValue, Action)
	If FolderForAdding = Undefined Then
		FolderForAdding = Items.Folders.CurrentRow;
		If FolderForAdding = Undefined Then
			Return;
		EndIf;
	EndIf;
	
	ValueType = TypeOf(DragValue);
	If ValueType = Type("File") Then
		If FolderForAdding.IsEmpty() Then
			Return;
		EndIf;
		If DragValue.IsFile() Then
			AddingOptions = New Structure;
			AddingOptions.Insert("HandlerResults_1", Undefined);
			AddingOptions.Insert("FullFileName", DragValue.FullName);
			AddingOptions.Insert("FileOwner", FolderForAdding);
			AddingOptions.Insert("OwnerForm", ThisObject);
			AddingOptions.Insert("NameOfFileToCreate", Undefined);
			AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
			FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
		Else
			FileNamesArray = New Array;
			FileNamesArray.Add(DragValue.FullName);
			FilesOperationsInternalClient.OpenDragFormFromOutside(FolderForAdding, FileNamesArray);
		EndIf;
	ElsIf TypeOf(DragValue) = Type("Array") Then
		FolderIndex = DragValue.Find(FolderForAdding);
		If FolderIndex <> Undefined Then
			DragValue.Delete(FolderIndex);
		EndIf;
		
		If DragValue.Count() = 0 Then
			Return;
		EndIf;
		
		ValueType = TypeOf(DragValue[0]);
		If ValueType = Type("File") Then
			If FolderForAdding.IsEmpty() Then
				Return;
			EndIf;
			
			FileNamesArray = New Array;
			For Each ReceivedFile1 In DragValue Do
				FileNamesArray.Add(ReceivedFile1.FullName);
			EndDo;
			FilesOperationsInternalClient.OpenDragFormFromOutside(FolderForAdding, FileNamesArray);
			
		ElsIf ValueType = Type("CatalogRef.Files") Then
			If FolderForAdding.IsEmpty() Then
				Return;
			EndIf;
			If Action = DragAction.Copy Then
				
				FilesOperationsInternalServerCall.DoCopyAttachedFiles(DragValue, FolderForAdding);
				
				Items.Folders.Refresh();
				Items.List.Refresh();
				
				If DragValue.Count() = 1 Then
					NotificationTitle1 = NStr("vi = 'Đã sao chép tệp.';
												|ru = 'Файл скопирован.';
												|en = 'File copied.'; fa = 'File copied.';
												|it = 'Il file è stato copiato.';
												|pl = 'Plik został skopiowany.';
												|tr = 'Dosya kopyalandı.'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tệp ""%1""
						           |đã sao chép vào thư mục ""%2""';
						           |ru = 'Файл ""%1""
						           |скопирован в папку ""%2""';
						           |en = 'File ""%1"" 
						           |is copied to folder ""%2"".'; fa = 'File ""%1"" 
						           |is copied to folder ""%2"".';
						           |it = 'Il file ""%1""
						           |è stato copiato nella cartella ""%2""';
						           |pl = 'Plik ""%1""
						           |został skopiowany do folderu ""%2""';
						           |tr = '""%1""
						           |dosya ""%2"" klasöre kopyalandı'"),
						DragValue[0],
						String(FolderForAdding));
				Else
					NotificationTitle1 = NStr("vi = 'Đã sao chép tệp.';
												|ru = 'Файлы скопированы.';
												|en = 'Files copied.'; fa = 'Files copied.';
												|it = 'I file sono stati copiati.';
												|pl = 'Pliki zostały skopiowane.';
												|tr = 'Dosyalar kopyalandı.'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tệp (%1) đã được sao chép vào thư mục ""%2""';
							|ru = 'Файлы (%1 шт.) скопированы в папку ""%2""';
							|en = '%1 files are copied to folder ""%2.""'; fa = '%1 files are copied to folder ""%2.""';
							|it = 'I file (%1 elementi) sono stati copiati nella cartella ""%2""';
							|pl = 'Pliki (%1 szt.) zostały skopiowane do folderu ""%2""';
							|tr = 'Dosyalar (%1 adet) ""%2"" klasörüne kopyalandı'"),
						DragValue.Count(),
						String(FolderForAdding));
				EndIf;
				ShowUserNotification(NotificationTitle1, , NotificationText, PictureLib.DialogInformation);
			Else
				
				OwnerIsSet = FilesOperationsInternalServerCall.SetFileOwner(DragValue, FolderForAdding);
				If OwnerIsSet <> True Then
					Return;
				EndIf;
				
				Items.Folders.Refresh();
				Items.List.Refresh();
				
				If DragValue.Count() = 1 Then
					NotificationTitle1 = NStr("vi = 'Đã chuyển tệp.';
												|ru = 'Файл перенесен.';
												|en = 'File moved.'; fa = 'File moved.';
												|it = 'Il file è stato trasferito.';
												|pl = 'Plik został przeniesiony.';
												|tr = 'Dosya taşındı'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đã chuyển tệp ""%1""
						           |vào thư mục ""%2""';
						           |ru = 'Файл ""%1""
						           |перенесен в папку ""%2""';
						           |en = 'File ""%1"" 
						           |is moved to folder ""%2.""'; fa = 'File ""%1"" 
						           |is moved to folder ""%2.""';
						           |it = 'Il file ""%1""
						           | è stato trasferito nella cartella ""%2""';
						           |pl = 'Plik ""%1""
						           | został przeniesiony do folderu ""%2""';
						           |tr = '""%1""
						           |dosya ""%2"" klasöre taşındı'"),
						String(DragValue[0]),
						String(FolderForAdding));
				Else
					NotificationTitle1 = NStr("vi = 'Đã chuyển các tệp.';
												|ru = 'Файлы перенесены.';
												|en = 'Files moved.'; fa = 'Files moved.';
												|it = 'I file sono stati trasferiti.';
												|pl = 'Pliki zostały przeniesione.';
												|tr = 'Dosyalar taşındı.'");
					NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đã chuyển tệp (%1) vào thư mục ""%2""';
							|ru = 'Файлы (%1 шт.) перенесены в папку ""%2""';
							|en = '%1 files are moved to folder ""%2.""'; fa = '%1 files are moved to folder ""%2.""';
							|it = 'I file (%1 elementi) sono stati trasferiti nella cartella ""%2""';
							|pl = 'Pliki (%1 szt.) zostały przeniesione do folderu ""%2""';
							|tr = 'Dosyalar (%1 adet) ""%2"" klasörüne taşındı'"),
						String(DragValue.Count()),
						String(FolderForAdding));
				EndIf;
				ShowUserNotification(NotificationTitle1, , NotificationText, PictureLib.DialogInformation);
			EndIf;
			
		ElsIf ValueType = Type("CatalogRef.FilesFolders") Then
			LoopFound = False;
			ParentChanged = FilesOperationsInternalServerCall.ChangeFoldersParent(DragValue, FolderForAdding, LoopFound);
			If ParentChanged <> True Then
				If LoopFound = True Then
					If DragValue.Count() = 1 Then
						MessageText = NStr("vi = 'Không thể di chuyển.
							|Thư mục ""%1"" là con của thư mục di chuyển ""%2"".';
							|ru = 'Перемещение невозможно.
							|Папка ""%1"" является дочерней для перемещаемой папки ""%2"".';
							|en = 'Cannot move the folder.
							|The ""%1"" folder is subordinate to the ""%2"" folder that you want to move.'; fa = 'Cannot move the folder.
							|The ""%1"" folder is subordinate to the ""%2"" folder that you want to move.';
							|it = 'Il trasferimento non è possibile.
							|La cartella ""%1"" risulta essere figlia della cartella che si sta cercando di trasferire ""%2"".';
							|pl = 'Przemieszczenie nie jest możliwe.
							|Folder ""%1"" jest podrzędny w stosunku do przemieszczanego folderu ""%2"".';
							|tr = 'Taşınamaz.
							|Klasör ""%1"" taşınan ""%2"" klasörün alt klasörüdür.'");
					Else
						MessageText = NStr("vi = 'Không thể di chuyển.
							|Thư mục ""%1"" là con của một trong các thư mục di chuyển.';
							|ru = 'Перемещение невозможно.
							|Папка ""%1"" является дочерней для одной из перемещаемых папок.';
							|en = 'Cannot move the folder.
							|The ""%1"" folder is subordinate to one of the folders that you want to move.'; fa = 'Cannot move the folder.
							|The ""%1"" folder is subordinate to one of the folders that you want to move.';
							|it = 'Il trasferimento non è possibile.
							|La cartella ""%1"" risulta essere figlia di una delle cartelle che si sta cercando di trasferire.';
							|pl = 'Przemieszczenie nie jest możliwe.
							|Folder ""%1"" jest podrzędny w stosunku do jednego z przemieszczanych folderów.';
							|tr = 'Taşınamaz.
							|Klasör ""%1"" taşınan klasörlerden birinin alt klasörüdür.'");
					EndIf;
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, FolderForAdding, DragValue[0]);
					ShowMessageBox(, MessageText);
				EndIf;
				Return;
			EndIf;
			
			Items.Folders.Refresh();
			Items.List.Refresh();
			
			If DragValue.Count() = 1 Then
				Items.Folders.CurrentRow = DragValue[0];
				NotificationTitle1 = NStr("vi = 'Thư mục đã chuyển.';
											|ru = 'Папка перенесена.';
											|en = 'Folder moved.'; fa = 'Folder moved.';
											|it = 'La cartella è stata trasferita.';
											|pl = 'Folder został przeniesiony.';
											|tr = 'Klasör taşındı.'");
				NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thư mục ""%1""
					           |đã chuyển vào thư mục ""%2""';
					           |ru = 'Папка ""%1""
					           |перенесена в папку ""%2""';
					           |en = 'Folder ""%1""
					           |is moved to folder ""%2.""'; fa = 'Folder ""%1""
					           |is moved to folder ""%2.""';
					           |it = 'La cartella ""%1""
					           |è stata trasferita nella cartella ""%2""';
					           |pl = 'Folder ""%1""
					           |został przeniesiony do folderu ""%2""';
					           |tr = '""%1""
					           |klasör ""%2"" klasöre taşındı'"),
					String(DragValue[0]),
					String(FolderForAdding));
			Else
				NotificationTitle1 = NStr("vi = 'Thư mục đã chuyển.';
											|ru = 'Папки перенесены.';
											|en = 'Folders moved.'; fa = 'Folders moved.';
											|it = 'Le cartelle sono state trasferite.';
											|pl = 'Foldery zostały przeniesione.';
											|tr = 'Klasörler taşındı.'");
				NotificationText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thư mục ""%1"" đã chuyển sang thư mục ""%2""';
						|ru = 'Папки (%1 шт.) перенесены в папку ""%2""';
						|en = '%1 folders are moved to folder ""%2.""'; fa = '%1 folders are moved to folder ""%2.""';
						|it = 'Le cartelle (%1 elementi) sono state trasferite nella cartella ""%2""';
						|pl = 'Foldery (%1 szt.) zostały przeniesione do folderu ""%2""';
						|tr = 'Klasörler (%1 adet) ""%2"" klasörüne taşındı'"),
					String(DragValue.Count()),
					String(FolderForAdding));
			EndIf;
			ShowUserNotification(NotificationTitle1, , NotificationText, PictureLib.DialogInformation);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure EncryptAfterEncryptAtClient(Result, ExecutionParameters) Export
	If Not Result.Success Then
		Return;
	EndIf;
	
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	FilesArrayInWorkingDirectoryToDelete = New Array;
	
	EncryptServer(
		Result.DataArrayToStoreInDatabase,
		Result.ThumbprintsArray,
		FilesArrayInWorkingDirectoryToDelete,
		WorkingDirectoryName,
		ExecutionParameters.ObjectRef);
	
	FilesOperationsInternalClient.InformOfEncryption(
		FilesArrayInWorkingDirectoryToDelete,
		ExecutionParameters.FileData.Owner,
		ExecutionParameters.ObjectRef);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure AfterDeleteData(Result, AdditionalParameters) Export
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure EncryptServer(Val DataArrayToStoreInDatabase, Val ThumbprintsArray, 
	Val FilesArrayInWorkingDirectoryToDelete, Val WorkingDirectoryName, Val ObjectRef)
	
	EncryptionInformationWriteParameters = FilesOperationsInternal.EncryptionInformationWriteParameters();
	EncryptionInformationWriteParameters.WorkingDirectoryName = WorkingDirectoryName;
	EncryptionInformationWriteParameters.DataArrayToStoreInDatabase = DataArrayToStoreInDatabase;
	EncryptionInformationWriteParameters.ThumbprintsArray = ThumbprintsArray;
	EncryptionInformationWriteParameters.FilesArrayInWorkingDirectoryToDelete = FilesArrayInWorkingDirectoryToDelete;
		
	FilesOperationsInternal.WriteEncryptionInformation(
		ObjectRef, EncryptionInformationWriteParameters);
	
EndProcedure

&AtClient
Procedure DecryptAfterDecryptAtClient(Result, ExecutionParameters) Export
	
	If Result = False Or Not Result.Success Then
		Return;
	EndIf;
	
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	DecryptServer(
		Result.DataArrayToStoreInDatabase,
		WorkingDirectoryName,
		ExecutionParameters.ObjectRef);
	
	FilesOperationsInternalClient.InformOfDecryption(
		ExecutionParameters.FileData.Owner,
		ExecutionParameters.ObjectRef);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtServer
Procedure DecryptServer(DataArrayToStoreInDatabase, 
	WorkingDirectoryName, ObjectRef)
	
	EncryptionInformationWriteParameters = FilesOperationsInternal.EncryptionInformationWriteParameters();
	EncryptionInformationWriteParameters.Encrypt = False;
	EncryptionInformationWriteParameters.WorkingDirectoryName = WorkingDirectoryName;
	EncryptionInformationWriteParameters.DataArrayToStoreInDatabase = DataArrayToStoreInDatabase;
	
	FilesOperationsInternal.WriteEncryptionInformation(
		ObjectRef, EncryptionInformationWriteParameters);
	
EndProcedure

&AtClient
Procedure SignCompletion(Result, ExecutionParameters) Export
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure SetCommandsAvailabilityOnChangeFolder()
	
	If Items.Folders.CurrentRow = Undefined Or Items.Folders.CurrentRow.IsEmpty() Then
		
		Items.FormCreateSubmenu.Enabled = False;
		Items.FormCreateFromFile.Enabled = False;
		Items.FormCreateFromTemplate.Enabled = False;
		Items.FormCreateFromScanner.Enabled = False;
		
		Items.FormCopy.Enabled = False;
		Items.ListContextMenuCopy.Enabled = False;
		
		Items.FormSetDeletionMark.Enabled = False;
		Items.ListContextMenuSetDeletionMark.Enabled = False;
		
		Items.ListContextMenuCreate.Enabled = False;
		
		Items.FormFilesImport.Enabled = False;
		Items.ListContextMenuFilesImport.Enabled = False;
		
		Items.FoldersContextMenuFolderImport.Enabled = False;
		
		Items.FoldersContextMenuCopy.Enabled = False;
		Items.FoldersContextMenuLevelUp.Enabled = False;
		Items.FoldersContextMenuMoveItem.Enabled = False;
		Items.FoldersContextMenuFolderExport.Enabled = False;
		Items.FoldersContextMenuSyncSettings.Enabled = False;
		If IsAccessRightsSetupCommandAvailable Then
			Items.FoldersContextMenuSetRights.Enabled = False;
		EndIf;
	Else
		If Items.Folders.CurrentRow <> CurrentFolder Then
			CurrentFolder = Items.Folders.CurrentRow;
			FillPropertyValues(ThisObject, FolderRightsSettings(Items.Folders.CurrentRow));
			Items.FormCreateCatalog.Enabled = FoldersModification;
			Items.FoldersContextMenuCreate.Enabled = FoldersModification;
			Items.FoldersContextMenuCopy.Enabled = FoldersModification;
			Items.FoldersContextMenuSetDeletionMark.Enabled = FoldersModification;
			Items.FoldersContextMenuMoveItem.Enabled = FoldersModification;
			If IsAccessRightsSetupCommandAvailable Then
				Items.FoldersContextMenuSetRights.Enabled = RightsManagement;
			EndIf;
		EndIf;
		
		Items.FormCreateSubmenu.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.FormCreateFromFile.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.FormCreateFromTemplate.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.FormCreateFromScanner.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.ListContextMenuCreate.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		
		Items.FormCreateCatalog.Enabled = Not FilesBeingEditedInCloudService;
		Items.FormFolderImport.Enabled = Not FilesBeingEditedInCloudService;
		Items.FormMoveToFolder.Enabled = Not FilesBeingEditedInCloudService;
		Items.FormRelease.Enabled = Not FilesBeingEditedInCloudService;
		Items.ListContextMenuMoveToFolder.Enabled = Not FilesBeingEditedInCloudService;
		Items.ListContextMenuRelease.Enabled = Not FilesBeingEditedInCloudService;
		
		Items.FormCopy.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.FoldersContextMenuCopy.Enabled = Items.FormCopy.Enabled;
	
		Items.ListContextMenuSetDeletionMark.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.FormSetDeletionMark.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		
		Items.FormCopy.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.ListContextMenuCopy.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		
		Items.FormSetDeletionMark.Enabled = FilesDeletionMark And Not FilesBeingEditedInCloudService;
		Items.ListContextMenuSetDeletionMark.Enabled = FilesDeletionMark And Not FilesBeingEditedInCloudService;
		
		Items.FormFilesImport.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.ListContextMenuFilesImport.Enabled = AddFilesAllowed  And Not FilesBeingEditedInCloudService;
		
		Items.FoldersContextMenuFolderImport.Enabled = AddFilesAllowed And Not FilesBeingEditedInCloudService;
		Items.FoldersContextMenuLevelUp.Enabled = True;
		Items.FoldersContextMenuFolderExport.Enabled = True;
		Items.FoldersContextMenuSyncSettings.Enabled = True;
		
	EndIf;
	
	If Items.Folders.CurrentRow <> Undefined Then
		AttachIdleHandler("FolderIdleHandlerOnActivateRow", 0.2, True);
	EndIf; 
	
EndProcedure

&AtClient
Procedure SetFilesSynchronizationNoteVisibility()
	
	FilesBeingEditedInCloudService = False;
	If Items.Folders.CurrentData = Undefined Or Items.Folders.CurrentRow.IsEmpty() Then
		Items.CloudServiceNoteGroup.Visible = False;
		Return;
	EndIf;
		
	Items.CloudServiceNoteGroup.Visible = Items.Folders.CurrentData.FolderSynchronizationEnabled;
	FilesBeingEditedInCloudService = Items.Folders.CurrentData.FolderSynchronizationEnabled;
	
	If Items.Folders.CurrentData.FolderSynchronizationEnabled Then
		
		SynchronizationInfo = SynchronizationInfo(Items.Folders.CurrentData.Ref);
		If SynchronizationInfo <> Undefined Then
		
			Items.DecorationNote.Title = StringFunctionsClient.FormattedString(
				NStr("vi = 'Các tệp được quản lý trong dịch vụ đám mây <a href=""%1"">%2</a>.';
					|ru = 'Работа с файлами ведется в облачном сервисе <a href=""%1"">%2</a>.';
					|en = 'The files are stored in cloud service <a href=""%1"">%2</a>.'; fa = 'The files are stored in cloud service <a href=""%1"">%2</a>.';
					|it = 'Работа с файлами ведется в облачном сервисе <a href=""%1"">%2</a>.';
					|pl = 'The files are stored in cloud service <a href=""%1"">%2</a>.';
					|tr = 'Dosyalarla çalışma bulut hizmetinde yürütülüyor <a href=""%1"">%2</a>.'"),
				SynchronizationInfo.FolderAddressInCloudService, SynchronizationInfo.AccountDescription1);
		
			Items.DecorationPictureSyncSettings.Visible  = Not SynchronizationInfo.IsSynchronized;
			Items.DecorationSyncDate.ToolTipRepresentation = ?(SynchronizationInfo.IsSynchronized, 
				ToolTipRepresentation.None, ToolTipRepresentation.Button);
			Items.DecorationSyncDate.Visible            = True;
			
			Items.DecorationSyncDate.Title = StringFunctionsClient.FormattedString(
				NStr("vi = 'Đã đồng bộ: <a href=""%1"">%2</a>';
					|ru = 'Синхронизировано: <a href=""%1"">%2</a>';
					|en = 'Synchronized on: <a href=""%1"">%2</a>'; fa = 'Synchronized on: <a href=""%1"">%2</a>';
					|it = 'Синхронизировано: <a href=""%1"">%2</a>';
					|pl = 'Synchronized on: <a href=""%1"">%2</a>';
					|tr = 'Senkronize edildi: <a href=""%1"">%2</a>'"),
				"OpenJournal", Format(SynchronizationInfo.SynchronizationDate, "DLF=DD"));
			
		Else
			
			Items.DecorationNote.Title = 
				NStr("vi = 'Làm việc với tệp trong dịch vụ đám mây.';
					|ru = 'Работа с файлами ведется в облачном сервисе.';
					|en = 'The files are stored in cloud service.'; fa = 'The files are stored in cloud service.';
					|it = 'Il lavoro con i file viene effettuato nel servizio cloud.';
					|pl = 'The files are stored in cloud service.';
					|tr = 'Dosya yönetimi bulut hizmetinde gerçekleştirilir.'");
				
			Items.DecorationPictureSyncSettings.Visible  = False;
			Items.DecorationSyncDate.ToolTipRepresentation = ToolTipRepresentation.None;
			Items.DecorationSyncDate.Visible            = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFoldersTreeTitle()
	
	Items.Folders.Title = ?(Items.Folders.CurrentData = Undefined, "",
		Items.Folders.CurrentData.Description);
	
EndProcedure

&AtServerNoContext
Function SynchronizationInfo(Val FilesOwner)
	
	Return FilesOperationsInternal.SynchronizationInfo(FilesOwner);
	
EndFunction

&AtClient
Procedure FolderIdleHandlerOnActivateRow()
	
	If Items.Folders.CurrentRow <> List.Parameters.Items.Find("Owner").Value Then
		UpdateAndSaveFilesListParameters();
	Else
		IdleHandlerSetFileCommandsAccessibility();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FolderRightsSettings(Folder)
	
	RightsSettings = New Structure;
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Value = ValueIsFilled(Folder);
		RightsSettings.Insert("FoldersModification", True);
		RightsSettings.Insert("FilesModification", Value);
		RightsSettings.Insert("AddFilesAllowed", Value);
		RightsSettings.Insert("FilesDeletionMark", Value);
		RightsSettings.Insert("RightsManagement", Value);
		Return RightsSettings;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	RightsSettings.Insert("FoldersModification",
		ModuleAccessManagement.HasRight("FoldersModification", Folder));
	
	RightsSettings.Insert("FilesModification",
		ModuleAccessManagement.HasRight("FilesModification", Folder));
	
	RightsSettings.Insert("AddFilesAllowed",
		ModuleAccessManagement.HasRight("AddFilesAllowed", Folder));
	
	RightsSettings.Insert("FilesDeletionMark",
		ModuleAccessManagement.HasRight("FilesDeletionMark", Folder));
		
	RightsSettings.Insert("RightsManagement",
		ModuleAccessManagement.HasRight("RightsManagement", Folder));
	
	Return RightsSettings;
	
EndFunction

&AtServerNoContext
Function FileData(Val AttachedFile, Val FormIdentifier = Undefined, Val GetBinaryDataRef = True)
	
	Return FilesOperations.FileData(AttachedFile, FormIdentifier, GetBinaryDataRef);
	
EndFunction

&AtClient
Procedure IdleHandlerSetFileCommandsAccessibility()
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure SetFileCommandsAvailability(Result = Undefined, ExecutionParameters = Undefined) Export
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined And Items.List.CurrentRow <> Undefined
		And TypeOf(Items.List.CurrentRow) <> Type("DynamicListGroupRow") Then
		SetCommandsAvailability(CurrentData, Items.List.SelectedRows.Count() > 1);
	Else
		MakeCommandsUnavailable();
	EndIf;
	
	AttachIdleHandler("UpdatePreview1", 0.1, True);
	
EndProcedure

&AtClient
Procedure MakeCommandsUnavailable()
	
	Items.FormEndEdit.Enabled = False;
	Items.ListContextMenuEndEdit.Enabled = False;
	
	Items.FormSaveChanges.Enabled = False;
	Items.ListContextMenuSaveChanges.Enabled = False;
	
	Items.FormRelease.Enabled = False;
	Items.ListContextMenuRelease.Enabled = False;
	
	Items.FormLock.Enabled = False;
	Items.ListContextMenuLock.Enabled = False;
	
	Items.FormEdit.Enabled = False;
	Items.ListContextMenuEdit.Enabled = False;
	
	Items.FormMoveToFolder.Enabled = False;
	Items.ListContextMenuMoveToFolder.Enabled = False;
	
	Items.FormSign.Enabled = False;
	Items.ListContextMenuSign.Enabled = False;
	
	Items.FormSendForSigning.Enabled = False;
	Items.ListContextMenuSendForSigning.Enabled = False;
	
	Items.FormSaveWithSignature.Enabled = False;
	Items.ListContextMenuSaveWithSignature.Enabled = False;
	
	Items.FormEncrypt.Enabled = False;
	Items.ListContextMenuEncrypt.Enabled = False;
	
	Items.FormDecrypt.Enabled = False;
	Items.ListContextMenuDecrypt.Enabled = False;
	
	Items.FormAddSignatureFromFile.Enabled = False;
	Items.ListContextMenuAddSignatureFromFile.Enabled = False;
	
	Items.FormUpdateFromFileOnHardDrive.Enabled = False;
	Items.ListContextMenuUpdateFromFileOnHardDrive.Enabled = False;
	
	Items.FormSaveAs.Enabled = False;
	Items.ListContextMenuSaveAs.Enabled = False;
	
	Items.FormOpenFileDirectory.Enabled = False;
	Items.ListContextMenuOpenFileDirectory.Enabled = False;
	
	Items.FormOpen.Enabled = False;
	Items.ListContextMenuOpen.Enabled = False;
	
	Items.Print.Enabled = False;
	Items.ListContextMenuPrint.Enabled = False;
	
	Items.Send.Enabled = False;
	
	Items.FormSetDeletionMark.Enabled = False;
	Items.ListContextMenuSetDeletionMark.Enabled = False;
	
	Items.FormDelete.Enabled = False;
	Items.ListContextMenuDelete.Enabled = False;
	
	Items.ListContextMenuCompare.Visible = False;	
	
EndProcedure

&AtClient
Procedure SetCommandsAvailability(Val CommandsData, Val SeveralLinesAreHighlighted)
	
	IsInternal   = CommandsData.IsInternal;
	Encrypted  = CommandsData.Encrypted;
	SignedWithDS  = CommandsData.SignedWithDS;
	BeingEditedBy = CommandsData.BeingEditedBy;
	IsFileTransferredToArchive = CommandsData.IsPictureNumberArchive = 0;
	
	CurrentUserIsAuthor = CommandsData.Author = UsersClient.AuthorizedUser();
	EditedByCurrentUser = CommandsData.CurrentUserEditsFile;
	
	EditedByAnother = ValueIsFilled(BeingEditedBy) And Not EditedByCurrentUser;
	
	Items.FormEndEdit.Enabled                 = FilesModification And EditedByCurrentUser And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuEndEdit.Enabled = FilesModification And EditedByCurrentUser And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormSaveChanges.Enabled                 = FilesModification And EditedByCurrentUser And Not IsFileTransferredToArchive;
	Items.ListContextMenuSaveChanges.Enabled = FilesModification And EditedByCurrentUser And Not IsFileTransferredToArchive;
	
	Items.FormRelease.Enabled                 = FilesModification And ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuRelease.Enabled = FilesModification And ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormLock.Enabled                 = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not SignedWithDS And Not IsInternal And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuLock.Enabled = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not SignedWithDS And Not IsInternal And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormEdit.Enabled                 = FilesModification And Not SignedWithDS And Not EditedByAnother And Not IsInternal And Not IsFileTransferredToArchive;
	Items.ListContextMenuEdit.Enabled = FilesModification And Not SignedWithDS And Not EditedByAnother And Not IsInternal And Not IsFileTransferredToArchive;

	Items.FormMoveToFolder.Enabled                 = FilesModification And Not SignedWithDS And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuMoveToFolder.Enabled = FilesModification And Not SignedWithDS And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormSign.Enabled                 = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuSign.Enabled = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormSendForSigning.Enabled                 = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuSendForSigning.Enabled = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormSaveWithSignature.Enabled                 = SignedWithDS And Not IsFileTransferredToArchive;
	Items.ListContextMenuSaveWithSignature.Enabled = SignedWithDS And Not IsFileTransferredToArchive;
	
	Items.FormEncrypt.Enabled                 = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not Encrypted And Not IsInternal And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuEncrypt.Enabled = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not Encrypted And Not IsInternal And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormDecrypt.Enabled                 = FilesModification And Encrypted And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuDecrypt.Enabled = FilesModification And Encrypted And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormAddSignatureFromFile.Enabled                 = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuAddSignatureFromFile.Enabled = FilesModification And Not ValueIsFilled(BeingEditedBy) And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormUpdateFromFileOnHardDrive.Enabled                 = FilesModification And Not SignedWithDS And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	Items.ListContextMenuUpdateFromFileOnHardDrive.Enabled = FilesModification And Not SignedWithDS And Not FilesBeingEditedInCloudService And Not IsFileTransferredToArchive;
	
	Items.FormSaveAs.Enabled                 = True;
	Items.ListContextMenuSaveAs.Enabled = True;
	
	Items.FormOpenFileDirectory.Enabled                 = True;
	Items.ListContextMenuOpenFileDirectory.Enabled = True;
	
	Items.FormOpen.Enabled                 = True;
	Items.ListContextMenuOpen.Enabled = True;
	
	Items.Print.Enabled                      = Not IsFileTransferredToArchive;
	Items.ListContextMenuPrint.Enabled = Not IsFileTransferredToArchive;

	Items.PrintWithStamp.Visible = HasDigitalSignature
		And (CommandsData.Extension = "mxl") Or (CommandsData.Extension = "docx")
		And CommandsData.SignedWithDS;

 	Items.PrintWithStamp.Enabled = Not IsFileTransferredToArchive;
		
	Items.Send.Enabled                      = Not IsFileTransferredToArchive;
	Items.ListContextMenuSend.Enabled = Not IsFileTransferredToArchive;
	
	Items.FormSetDeletionMark.Enabled = FilesModification;
	Items.ListContextMenuSetDeletionMark.Enabled = FilesModification;
	
	Items.FormDelete.Enabled = FilesModification
		And CurrentUserIsAuthor
		And Not ValueIsFilled(BeingEditedBy)
		And Not FilesBeingEditedInCloudService;
		
	Items.ListContextMenuDelete.Enabled = FilesModification
		And CurrentUserIsAuthor
		And Not ValueIsFilled(BeingEditedBy)
		And Not FilesBeingEditedInCloudService;
		
	Items.ListContextMenuCompare.Visible = SeveralLinesAreHighlighted;
	
EndProcedure

&AtServer
Procedure SetHierarchy(Mark)
	
	If Mark = Undefined Then 
		Return;
	EndIf;
	
	Items.FormUseHierarchy.Check = Mark;
	If Mark = True Then 
		Items.Folders.Visible = True;
	Else
		Items.Folders.Visible = False;
	EndIf;
	List.Parameters.SetParameterValue("UseHierarchy", Mark);
	
EndProcedure

&AtClient
Procedure ListSelectionAfterEditModeChoice(Result, ExecutionParameters) Export
	If Result = "Edit" Then
		Handler = New CallbackDescription("SelectionListAfterEditFile", ThisObject, ExecutionParameters);
		FilesOperationsInternalClient.EditFile(Handler, ExecutionParameters.FileData);
	ElsIf Result = "Open" Then
		FilesOperationsClient.OpenFile(ExecutionParameters.FileData, False);
	EndIf;
EndProcedure

// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperations.FileData
//
&AtClient
Procedure SelectionListAfterEditFile(Result, ExecutionParameters) Export
	
	NotifyChanged(ExecutionParameters.FileData.Ref);
	
	SetFileCommandsAvailability();
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	OnChangeUseSignOrEncryptionAtServer();
	
EndProcedure

&AtServer
Procedure OnChangeUseSignOrEncryptionAtServer()
	
	FilesOperationsInternal.CryptographyOnCreateFormAtServer(ThisObject);
	
EndProcedure

&AtServerNoContext
Procedure SavePreviewOption(FileCatalogType, Preview)
	Common.CommonSettingsStorageSave(FileCatalogType, "Preview", Preview);
EndProcedure

&AtServerNoContext
Procedure OnSendFilesViaEmail(SendOptions, Val FilesToSend, Val FilesOwner, Val UUID)
	SSLSubsystemsIntegration.OnSendFilesViaEmail(SendOptions, FilesToSend, FilesOwner, UUID);
	FilesOperationsOverridable.OnSendFilesViaEmail(SendOptions, FilesToSend, FilesOwner, UUID);
EndProcedure

&AtClient
Procedure SetPreviewVisibility(UsePreview1)
	
	Items.FileDataURL.Visible = UsePreview1;
	Items.Preview.Check = UsePreview1;
	
EndProcedure

&AtClient
Procedure UpdatePreview1()
	
	If Not Preview Then
		Return;
	EndIf;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined And PreviewEnabledExtensions.FindByValue(CurrentData.Extension) <> Undefined Then
		
		Try
			FileData = FilesOperationsInternalServerCall.FileDataToOpen(CurrentData.Ref, Undefined, UUID,, FileDataURL);
			FileDataURL = FileData.RefToBinaryFileData;
		Except
			// If the file does not exist, an exception will be called.
			FileDataURL         = Undefined;
			NonselectedPictureText = NStr("vi = 'Xem trước không được phép theo nguyên nhân:';
											|ru = 'Предварительный просмотр недоступен по причине:';
											|en = 'Preview is not available. Reason:'; fa = 'Preview is not available. Reason:';
											|it = 'L''anteprima non è disponibile a causa di:';
											|pl = 'Podgląd jest niedostępny z powodu:';
											|tr = 'Ön izleme aşağıdaki nedenle imkansız:'") + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
	Else
		
		FileDataURL         = Undefined;
		NonselectedPictureText = NStr("vi = 'Không có dữ liệu để xem trước';
										|ru = 'Нет данных для предварительного просмотра';
										|en = 'No data to preview'; fa = 'No data to preview';
										|it = 'Non ci sono dati per un''anteprima';
										|pl = 'Brak danych do podglądu';
										|tr = 'Ön gösterilecek veri yok'");
		
	EndIf;
	
	If Not ValueIsFilled(FileDataURL) Then
		Items.FileDataURL.NonselectedPictureText = NonselectedPictureText;
	EndIf;
	
EndProcedure

&AtServer
Function SynchronizationSettingsParameters(FilesOwner)
	
	FileOwnerType = Common.MetadataObjectID(Type("CatalogRef.Files"));
	
	Filter = New Structure(
	"FileOwner, FileOwnerType, Account",
		FilesOwner,
		FileOwnerType,
		Catalogs.FileSynchronizationAccounts.EmptyRef());
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FileSynchronizationSettings.FileOwner,
		|	FileSynchronizationSettings.FileOwnerType,
		|	FileSynchronizationSettings.Account
		|FROM
		|	InformationRegister.FileSynchronizationSettings AS FileSynchronizationSettings
		|WHERE
		|	FileSynchronizationSettings.FileOwner = &FileOwner
		|	AND FileSynchronizationSettings.FileOwnerType = &FileOwnerType";
	
	Query.SetParameter("FileOwner", FilesOwner);
	Query.SetParameter("FileOwnerType", FileOwnerType);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Count() = 1 Then
		While SelectionDetailRecords.Next() Do
			Filter.Account = SelectionDetailRecords.Account;
		EndDo;
	EndIf;
	
	Return Filter;
	
EndFunction

&AtServer
Procedure UpdateAndSaveFilesListParameters()
	
	Common.FormDataSettingsStorageSave(
		"Files", 
		"CurrentFolder", 
		Items.Folders.CurrentRow);
	
	List.Parameters.SetParameterValue("Owner", Items.Folders.CurrentRow);
	
EndProcedure

&AtServerNoContext
Function EventLogFilterData(AccountService)
	Return FilesOperationsInternal.EventLogFilterData(AccountService);
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtClient
Function CurrentData()
	Result = Undefined;
	If Not StandardSubsystemsClient.IsDynamicListItem(Items.List) Then
	ElsIf Items.List.CurrentData.FileOwner = CurrentFolder Then
		Result = Items.List.CurrentData;
	EndIf;
	Return Result;
EndFunction

&AtClient
Function SelectedRows()
	SelectedRows = New Array;
	
	For Each SelectedRow In Items.List.SelectedRows Do
		If TypeOf(SelectedRow) <> Type("DynamicListGroupRow") Then
			SelectedRows.Add(SelectedRow);
		EndIf;
	EndDo;
	
	Return SelectedRows
	
EndFunction

#EndRegion
