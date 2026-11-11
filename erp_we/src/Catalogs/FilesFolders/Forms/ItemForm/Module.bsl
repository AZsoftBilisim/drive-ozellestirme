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
	
	If ValueIsFilled(Parameters.Parent) Then
		Object.Parent = Parameters.Parent;
	EndIf;
	
	UpdateCommandsAvailabilityByRightsSetting();
	
	WorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(Object.Ref);
	
	If Object.Ref = PredefinedValue("Catalog.FilesFolders.Templates") Then
		Items.Parent.Visible = False;
	EndIf;
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	RefreshFullPath();
	
	UpdateCloudServiceNote();
	Items.FormSyncSettings.Visible = AccessRight("Edit", Metadata.Catalogs.FileSynchronizationAccounts);
	Items.EmployeeResponsible.Visible = TypeOf(Users.AuthorizedUser()) <> Type("CatalogRef.ExternalUsers");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		If ModulePropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	EndIf;
	// End StandardSubsystems.Properties
	
	If EventName = "Write_ObjectsRightsSettings" Then
		UpdateCommandsAvailabilityByRightsSetting();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject)
	
	CurrentObject.AdditionalProperties.Insert("WorkingDirectory", WorkingDirectory);
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	WorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(Object.Ref);
	
	UpdateCommandsAvailabilityByRightsSetting();
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ParentOnChange(Item)
	
	RefreshFullPath();
	
EndProcedure

&AtClient
Procedure OwnerWorkingDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	Handler = New CallbackDescription("FileSystemExtensionAttachedOwnerWorkingDirectorySelectionStartFollowUp", ThisObject);
	FilesOperationsInternalClient.ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

&AtClient
Procedure OwnerWorkingDirectoryClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	WorkingDirectory = OwnerWorkingDirectoryClearingAtServer(Object.Ref, Object.Parent, Object.Description);
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SyncSettings(Command)
	
	SyncSetup = SynchronizationSettingsParameters(Object.Ref);
	
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

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtClient
Procedure FileSystemExtensionAttachedOwnerWorkingDirectorySelectionStartFollowUp(Result, AdditionalParameters) Export
	
	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		FilesOperationsInternalClient.Show1CEnterpriseExtensionRequiredMessageBox(Undefined);
		Return;
	EndIf;
	
	ClearMessages();
	
	Mode = FileDialogMode.ChooseDirectory;
	
	OpenFileDialog = New FileDialog(Mode);
	OpenFileDialog.Directory = WorkingDirectory;
	OpenFileDialog.FullFileName = "";
	Filter = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Chọn thư mục';
								|ru = 'Выберите папку';
								|en = 'Select folder'; fa = 'انتخاب پوشه';
								|it = 'Selezionare cartella';
								|pl = 'Wybierz folder';
								|tr = 'Klasör seçiniz'");
	If OpenFileDialog.Choose() Then
		
		DirectoryName = OpenFileDialog.Directory;
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
		
		// Create a directory for files
		Try
			CreateDirectory(DirectoryName);
			TestDirectoryName = DirectoryName + "CheckAccess\";
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			// Insufficient rights to create a directory, or this path does not exist.
			
			ErrorText =
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Sai đường dẫn hoặc không có quyền ghi vào thư mục ""%1""';
																				|ru = 'Неверный путь или отсутствуют права на запись в папку ""%1""';
																				|en = 'Invalid path or insufficient rights to save to folder ""%1""'; fa = 'Invalid path or insufficient rights to save to folder ""%1""';
																				|it = 'Percorso errato oppure diritti mancanti per la registrazione nella cartella ""%1""';
																				|pl = 'Niepoprawna ścieżka lub jest brak uprawnień do zapisywania do folderu ""%1""';
																				|tr = 'Dizin yanlış veya ""%1"" klasörüne yazma hakları yok'"), DirectoryName);
			
			CommonClient.MessageToUser(ErrorText, , "WorkingDirectory");
			Return;
		EndTry;
		
		WorkingDirectory = DirectoryName;
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshFullPath()
	
	FolderParent = Common.ObjectAttributeValue(Object.Ref, "Parent");
	
	If ValueIsFilled(FolderParent) Then
	
		FullPath = "";
		While ValueIsFilled(FolderParent) Do
			
			FullPath = String(FolderParent) + "\" + FullPath;
			FolderParent = Common.ObjectAttributeValue(FolderParent, "Parent");
			If Not ValueIsFilled(FolderParent) Then
				Break;
			EndIf;
			
		EndDo;
		
		FullPath = FullPath + String(Object.Ref);
		
		If Not IsBlankString(FullPath) Then
			FullPath = """" + FullPath + """";
		EndIf;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCommandsAvailabilityByRightsSetting()
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement")
	 Or Items.Find("FormCommonCommandSetRights") = Undefined Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	If ValueIsFilled(Object.Ref)
	   And Not ModuleAccessManagement.HasRight("FoldersModification", Object.Ref) Then
		
		ReadOnly = True;
	EndIf;
	
	RightsManagement = ValueIsFilled(Object.Ref)
		And ModuleAccessManagement.HasRight("RightsManagement", Object.Ref);
		
	If Items.FormCommonCommandSetRights.Visible <> RightsManagement Then
		Items.FormCommonCommandSetRights.Visible = RightsManagement;
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Function SynchronizationSettingsParameters(Val FileOwner)
	
	FileOwnerType = Common.MetadataObjectID(Type("CatalogRef.Files"));
	
	Filter = New Structure(
	"FileOwner, FileOwnerType, Account",
		FileOwner,
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
	
	Query.SetParameter("FileOwner", FileOwner);
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
Procedure UpdateCloudServiceNote()
	
	NoteVisibility = False;
	
	If GetFunctionalOption("UseFileSync") Then
	
		SynchronizationInfo = FilesOperationsInternal.SynchronizationInfo(Object.Ref);
		If SynchronizationInfo <> Undefined Then
			NoteVisibility = True;
			Items.DecorationNote.Title = StringFunctions.FormattedString(
				NStr("vi = 'Làm việc với tệp trong dịch vụ đám mây <a href=""%1"">%2</a>';
					|ru = 'Работа с файлами ведется в облачном сервисе <a href=""%1"">%2</a>';
					|en = 'The files are stored in cloud service <a href=""%1"">%2</a>.'; fa = 'The files are stored in cloud service <a href=""%1"">%2</a>.';
					|it = 'Работа с файлами ведется в облачном сервисе <a href=""%1"">%2</a>';
					|pl = 'The files are stored in cloud service <a href=""%1"">%2</a>.';
					|tr = 'Dosyalarla çalışma <a href=""%1"">%2</a> bulut hizmetinde yürütülüyor'"),
				SynchronizationInfo.FolderAddressInCloudService, SynchronizationInfo.AccountDescription1);
		EndIf;
		
	EndIf;
	
	Items.CloudServiceNoteGroup.Visible = NoteVisibility;
	
EndProcedure

&AtServerNoContext
Function OwnerWorkingDirectoryClearingAtServer(Val Ref, Val ParentReference, Val Description)
	
	ParentWorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(ParentReference);
	
	InheritedFolderWorkingDirectory = ParentWorkingDirectory
		+ Description + GetPathSeparator();
	
	If IsBlankString(ParentWorkingDirectory) Then
		
		WorkingDirectory = ""; // Folder's new working directory.
		
	Else
		
		WorkingDirectory = InheritedFolderWorkingDirectory; // Folder's new working directory.
		
	EndIf;
	
	Return WorkingDirectory;
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
