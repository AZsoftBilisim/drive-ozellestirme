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
	
	ErrorTitle = NStr("vi = 'Không thể mở danh sách tệp đính kèm.';
						|ru = 'Невозможно открыть список присоединенных файлов.';
						|en = 'Unable to open the attachment list.'; fa = 'Unable to open the attachment list.';
						|it = 'Unable to open the attachment list.';
						|pl = 'Unable to open the attachment list.';
						|tr = 'Ekli dosyalar listesi açılamıyor.'");
	FileOwner = Common.ObjectAttributeValue(Parameters.File, "FileOwner");
	FileVersionsStorageCatalogName = FilesOperationsInternal.FilesVersionsStorageCatalogName(
		FileOwner, "", ErrorTitle);
		
	If Not IsBlankString(FileVersionsStorageCatalogName) Then
		SetUpDynamicList(FileVersionsStorageCatalogName);
	EndIf;
	
	CommandCompareVisibility = 
		Not Common.IsLinuxClient() And Not Common.IsWebClient();
	Items.FormCompare.Visible = CommandCompareVisibility;
	Items.ContextMenuListCompare.Visible = CommandCompareVisibility;
	
	FileCardUUID = Parameters.FileCardUUID;
	
	List.Parameters.SetParameterValue("Owner", Parameters.File);
	VersionOwner = Parameters.File;
	
	FilesOperationsInternal.SetFilterByDeletionMark(List.Filter);
	
	If Common.IsMobileClient() Then
		
		Items.FormOpenVersion.Picture = PictureLib.InputFieldOpen;
		Items.FormOpenVersion.Representation = ButtonRepresentation.Picture;
		Items.ListComment.Visible = False;
		
	EndIf;

	FileArchiveManagementServer.IsArchivePictureNumberListFieldVisibility(Items.ListIsPictureNumberArchive);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MakeActiveExecute()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	NewActiveVersion = CurrentData.Ref;
	
	FileDataParameters = FilesOperationsClientServer.FileDataParameters();
	FileDataParameters.GetBinaryDataRef = False;
	
	FileData = FilesOperationsInternalServerCall.FileData(CurrentData.Owner, CurrentData.Ref, FileDataParameters);
	
	If ValueIsFilled(FileData.BeingEditedBy) Then
		ShowMessageBox(, NStr("vi = 'Cho phép thay đổi phiên bản hiện tại chỉ đối với tệp chưa bị chiếm.';
								|ru = 'Смена активной версии разрешена только для незанятых файлов.';
								|en = 'Cannot change the active version because the file is locked.'; fa = 'Cannot change the active version because the file is locked.';
								|it = 'La modifica della versione attiva è consentita solo per i file liberi.';
								|pl = 'Zmiana aktywnej wersji jest dozwolona tylko dla nieużywanych plików.';
								|tr = 'Aktif sürüm sadece kilitlenmeyen dosyalar için değiştirilebilir.'"));
	ElsIf FileData.SignedWithDS Then
		ShowMessageBox(, NStr("vi = 'Cho phép thay đổi phiên bản hiện tại chỉ đối với tệp chưa ký.';
								|ru = 'Смена активной версии разрешена только для неподписанных файлов.';
								|en = 'Cannot change the active version because the file is signed.'; fa = 'Cannot change the active version because the file is signed.';
								|it = 'La modifica della versione attiva è consentita solo per i file non sottoscritti.';
								|pl = 'Zmiana aktywnej wersji jest dozwolone tylko dla niepodpisanych plików.';
								|tr = 'Aktif sürüm sadece imzalanmayan dosyalar için değiştirilebilir.'"));
	Else
		ChangeActiveFileVersion(NewActiveVersion);
		FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters("ActiveVersionChanged");
		Notify("Write_File", FileWriteNotificationParameters, Parameters.File);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_File"
		And (Parameter.Event = "EditFinished"
		Or Parameter.Event = "VersionSaved"
		Or Parameter.Event = "AreFilesChangedWhenUsingArchive") Then
		
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenFileVersion();
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then 
		
		Version = CurrentData.Ref;
		
		FormOpenParameters = New Structure("Key", Version);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFileVersion", FormOpenParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	If Items.List.CurrentRow <> Undefined Then
		ChangeCommandsAvailability();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenCard(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then 
		
		Version = CurrentData.Ref;
		
		FormOpenParameters = New Structure("Key", Version);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFileVersion", FormOpenParameters);
		
	EndIf;
	
EndProcedure

// Compare the two selected versions. 
&AtClient
Procedure Compare(Command)
	
	SelectedRowsCount = Items.List.SelectedRows.Count();
	If SelectedRowsCount <> 2 And SelectedRowsCount <> 1 Then
		ShowMessageBox(, NStr("vi = 'Để xem sự khác biệt, hãy chọn hai phiên bản tệp.';
								|ru = 'Для просмотра отличий выберите две версии файла.';
								|en = 'To view the differences, select two file versions.'; fa = 'To view the differences, select two file versions.';
								|it = 'Per visualizzare le differenze, selezionare due versioni del file.';
								|pl = 'Aby przejrzeć różnice wybierz dwie wersje pliku.';
								|tr = 'Farklılıkları görüntülemek için dosyanın iki sürümü seçilmelidir.'"));
		Return;
	EndIf;
		
	If SelectedRowsCount = 2 Then
		FirstFile = Items.List.SelectedRows[0];
		SecondFile = Items.List.SelectedRows[1];
	ElsIf SelectedRowsCount = 1 Then
		FirstFile = Items.List.CurrentData.Ref;
		SecondFile = Items.List.CurrentData.ParentVersion;
	EndIf;
	
	Extension = Lower(Items.List.CurrentData.Extension);
	FilesOperationsInternalClient.CompareFiles(UUID, FirstFile, SecondFile, Extension, VersionOwner);
	
EndProcedure

&AtClient
Procedure OpenVersion(Command)
	
	OpenFileVersion();
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("SaveAs", "FilesOperationsInternal.FileDataToSaveAsync");
	FileGettingParameters.AttachedFile				= CurrentData.Owner;
	FileGettingParameters.VersionRef					= CurrentData.Ref;
	FileGettingParameters.OwnerForm					= ThisObject;
	FileGettingParameters.CheckForFileInArchive	= False;
	FileGettingParameters.FileInArchive						= CurrentData.IsPictureNumberArchive = 0;
	
	FileGettingParameters.ActionParameters.UUID = UUID;
	
	FilesOperationsClient.SaveFileAs(FileGettingParameters);
	
EndProcedure

&AtClient
Procedure Delete(Command)
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FilesOperationsInternalClient.DeleteData(
		New CallbackDescription("AfterDeleteData", ThisObject),
		Items.List.CurrentData.Ref, UUID);
	
EndProcedure

&AtClient
Procedure ShowMarkedFiles(Command)
	
	FilesOperationsInternalClient.ChangeFilterByDeletionMark(List.Filter, Items.ShowMarkedFiles);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeCommandsAvailability()
	
	CurrentUserIsAuthor =
		Items.List.CurrentData.Author = UsersClient.AuthorizedUser();
	
	Items.FormDelete.Enabled = CurrentUserIsAuthor;
	Items.ListContextMenuDelete.Enabled = CurrentUserIsAuthor;
	
EndProcedure

&AtClient
Procedure AfterDeleteData(Result, AdditionalParameters) Export
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure ChangeActiveFileVersion(Version)
	
	BeginTransaction();
	Try
		
		VersionLock = New DataLock;
		
		DataLockItem = VersionLock.Add(Metadata.FindByType(TypeOf(Version)).FullName());
		DataLockItem.SetValue("Ref", Version);
		DataLockItem.Mode = DataLockMode.Shared;
		
		VersionLock.Lock();
		
		NewVersionAttributes = Common.ObjectAttributesValues(Version, "Owner, TextStorage");
		
		Block = New DataLock;
		
		DataLockItem = Block.Add(Metadata.FindByType(TypeOf(NewVersionAttributes.Owner)).FullName());
		DataLockItem.SetValue("Ref", NewVersionAttributes.Owner);
		
		Block.Lock();
		
		LockDataForEdit(NewVersionAttributes.Owner, , FileCardUUID);
		LockDataForEdit(Version, , FileCardUUID);
		
		FileObject1 = NewVersionAttributes.Owner.GetObject();
		If FileObject1.SignedWithDS Then
			Raise NStr("vi = 'Trong tệp đã ký, không thể thay đổi phiên bản hiện tại.';
						|ru = 'У подписанного файла нельзя изменять активную версию.';
						|en = 'Cannot change the active version because the file is signed.'; fa = 'Cannot change the active version because the file is signed.';
						|it = 'Non si può cambiare la versione attiva per il file sottoscritto.';
						|pl = 'U podpisanego pliku nie można zmieniać aktywną wersję.';
						|tr = 'İmzalanan dosyanın aktif versiyonu değiştirilemez.'");
		EndIf;
		FileObject1.CurrentVersion = Version;
		FileObject1.TextStorage = NewVersionAttributes.TextStorage;
		FileObject1.Write();
		
		VersionObject = Version.GetObject();
		VersionObject.Write();
		
		UnlockDataForEdit(FileObject1.Ref, FileCardUUID);
		UnlockDataForEdit(Version, FileCardUUID);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Procedure SetUpDynamicList(FileVersionsStorageCatalogName)
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = 
		"SELECT ALLOWED
		|	FilesVersions.Code AS Code,
		|	FilesVersions.Size AS Size,
		|	FilesVersions.Comment AS Comment,
		|	FilesVersions.Author AS Author,
		|	FilesVersions.CreationDate AS CreationDate,
		|	FilesVersions.Description AS FullDescr,
		|	FilesVersions.ParentVersion AS ParentVersion,
		|	CASE
		|		WHEN FilesVersions.DeletionMark
		|			THEN FilesVersions.PictureIndex + 1
		|		ELSE FilesVersions.PictureIndex
		|	END AS PictureIndex,
		|	FilesVersions.DeletionMark AS DeletionMark,
		|	FilesVersions.Owner AS Owner,
		|	FilesVersions.Ref AS Ref,
		|	CASE
		|		WHEN FilesVersions.Owner.CurrentVersion = FilesVersions.Ref
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS IsCurrent,
		|	FilesVersions.Extension AS Extension,
		|	FilesVersions.VersionNumber AS VersionNumber,
		|	CASE
		|		WHEN FilesVersions.ArchivingDate = DATETIME(1, 1, 1)
		|	THEN -1
		|		ELSE 0
		|	END AS IsPictureNumberArchive		
		|FROM
		|	&CatalogName AS FilesVersions
		|WHERE
		|	FilesVersions.Owner = &Owner";
	
	FullCatalogName = "Catalog." + FileVersionsStorageCatalogName;
	QueryText = StrReplace(QueryText, "&CatalogName", FullCatalogName);
	
	ListProperties.MainTable  = FullCatalogName;
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

&AtClient
Procedure OpenFileVersion()

	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("OpenFileVersion");
	FileGettingParameters.AttachedFile				= CurrentData.Owner;
	FileGettingParameters.VersionRef					= CurrentData.Ref;
	FileGettingParameters.OwnerForm					= ThisObject;
	FileGettingParameters.CheckForFileInArchive	= False;
	FileGettingParameters.FileInArchive						= CurrentData.IsPictureNumberArchive = 0;

	FileGettingParameters.ActionParameters.UUID = UUID;
	
	FilesOperationsClient.OpenFile(FileGettingParameters);

EndProcedure

#EndRegion
