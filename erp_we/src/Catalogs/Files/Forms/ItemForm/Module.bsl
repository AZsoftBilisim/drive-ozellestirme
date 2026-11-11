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
	
	FilesOperationsInternal.ItemFormOnCreateAtServer(
		ThisObject, Cancel, StandardProcessing, Parameters, ReadOnly);
		
	SendOptions = ?(ValueIsFilled(Parameters.SendOptions),
		Parameters.SendOptions, FilesOperationsInternal.PrepareSendingParametersStructure());
		
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
		AdditionalParameters.Insert("Object", Object);
		AdditionalParameters.Insert("DeferredInitialization", True);
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	EndIf;
	// End StandardSubsystems.Properties
	
	IsFileTransferredToArchive = FileArchiveManagementServer.IsFileTransferredToFileArchive(Object.CurrentVersion);

	SetButtonsAvailability(ThisObject, Items);
	
	PrintWithStampAvailable = Common.SubsystemExists("StandardSubsystems.DigitalSignature")
		And (Lower(Object.Extension) = "mxl" Or Lower(Object.Extension) = "docx")
		And Object.SignedWithDS;
	
	Items.PrintWithStamp.Visible = PrintWithStampAvailable;
	If Not PrintWithStampAvailable Then
		Items.PrintSubmenu.Type = FormGroupType.ButtonGroup;
		Items.Print.Title = NStr("vi = 'In';
								|ru = 'Печать';
								|en = 'Print'; fa = 'چاپ';
								|it = 'Stampa';
								|pl = 'Print';
								|tr = 'Yazdır'");
	EndIf;
	
	Items.FormDelete.Visible = (Object.Author = Users.AuthorizedUser());
	
	RefreshTitle();
	RefreshFullPath();
	UpdateCloudServiceNote(Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands

	If Common.IsMobileClient() Then
		
		Items.LongDesc.Height = 0;
		Items.Description.TitleLocation = FormItemTitleLocation.Top;
		Items.InfoGroupPart1.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.InfoGroupPart2.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.FileCharacteristicsGroup.ItemsAndTitlesAlign =
			ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		
	EndIf;
	
	SSLSubsystemsIntegration.OnCreateFilesItemForm(ThisObject);
	FilesOperationsOverridable.OnCreateFilesItemForm(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DescriptionBeforeWrite = Object.Description;
	
	SetAvaliabilityOfDSCommandsList();
	SetAvaliabilityOfEncryptionList();
	
	FilesOperationsInternalClient.ReadSignaturesCertificates(ThisObject);
	DisplayAdditionalDataTabs();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	UnlockObject(Object.Ref, UUID);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_ConstantsSet") And (Upper(Source) = Upper("UseDigitalSignature")
		Or Upper(Source) = Upper("UseEncryption")) Then
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.3, True);
	EndIf;
	
	If EventName = "Write_File" And Source = Object.Ref And Not Modified Then
		UpdateObject();
	EndIf;
	
	If EventName = "Write_Signature" Then
		OnGetSignatures(Undefined, Undefined);
	EndIf;
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	
	If CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		If Upper(EventName) = Upper("MRLOACheckResultChanged") And Source = Object.Ref Then
			
			Found4 = DigitalSignatures.FindRows(New Structure("ResultOfSignatureVerificationByMRLOA", Parameter));
			If Found4.Count() = 0 Then
				Return;
			EndIf;
			
			DetermineIfModified();
			
			ModuleMachineReadableLettersOfAuthorityFTSInternalClient = CommonClient.CommonModule(
				"MachineReadableLettersOfAuthorityFTSInternalClient");
			MRLOAInformation = ModuleMachineReadableLettersOfAuthorityFTSInternalClient.MRLOAInformation(Parameter);
			FillPropertyValues(Found4[0], MRLOAInformation);
			
		EndIf;
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		If ModulePropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
			DisplayAdditionalDataTabs();
		EndIf;
	EndIf;
	// End StandardSubsystems.Properties
	
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

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	CurrentUser = Users.AuthorizedUser();
	
	FilesOperationsInternal.FillSignatureList(ThisObject);
	FilesOperationsInternal.FillEncryptionList(ThisObject);
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	FilesModification = Users.IsFullUser();
	SetButtonsAvailability(ThisObject, Items);
	RefreshTitle();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CopyingValue) Then
		
		FilesOperationsInternal.MoveSignaturesCheckResults(DigitalSignatures, CopyingValue);
		
		If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
			
			SourceCertificates = ModuleDigitalSignature.EncryptionCertificates(CopyingValue);
			ModuleDigitalSignature.WriteEncryptionCertificates(CurrentObject, SourceCertificates);
			
			ObjectSignatures = ModuleDigitalSignature.ObjectSignatures(CopyingValue);
			ModuleDigitalSignature.AddSignature(CurrentObject, ObjectSignatures);
		EndIf;
		
	Else
		FilesOperationsInternal.MoveSignaturesCheckResults(DigitalSignatures, CurrentObject.Ref);
	EndIf;
	
	If DescriptionBeforeWrite <> CurrentObject.Description Then
		
		FileStorageType = Common.ObjectAttributeValue(CurrentObject.CurrentVersion, "FileStorageType");
		
		If FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			FilesOperationsInVolumesInternal.RenameFile(CurrentObject.CurrentVersion,
				CurrentObject.Description, DescriptionBeforeWrite, UUID);
		EndIf;
			
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	If ValueIsFilled(CopyingValue) Then
		CreateVersionCopy(CurrentObject.Ref, CopyingValue);
		CopyingValue = Catalogs[CatalogName].EmptyRef();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	If TypeOf(Object.FileOwner) = Type("CatalogRef.FilesFolders") Then
		RefreshFullPath();
	EndIf;
	
	OwnerType = TypeOf(Object.FileOwner);
	Items.FileOwner.Title = OwnerType;
	
EndProcedure

&AtClient
Procedure DecorationSyncDateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "OpenJournal" Then
		
		StandardProcessing = False;
		FilterParameters      = EventLogFilterData(Account);
		EventLogClient.OpenEventLog(FilterParameters, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDigitalSignatures

&AtClient
Procedure DigitalSignaturesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	CurrentData = Items.DigitalSignatures.CurrentData;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	If Field.Name = "DigitalSignaturesBriefCheckResult"
		And ValueIsFilled(CurrentData.CheckResult)
		And (ValueIsFilled(CurrentData.CheckResult.AdditionalAttributesCheckError)
		Or ValueIsFilled(CurrentData.CheckResult.SignatureMathValidationError)) Then
		
		AdditionalParameters = New Structure;
		If ValueIsFilled(CurrentData.SignatureAddress) Then
			AdditionalParameters.Insert("SignatureData",
				CurrentData.SignatureAddress);
		Else
			ModuleDigitalSignatureClient.OpenSignature(CurrentData);
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("vi = 'Kiểm tra chữ ký';
													|ru = 'Проверка подписи';
													|en = 'Signature verification'; fa = 'Signature verification';
													|it = 'Проверка подписи';
													|pl = 'Sprawdzenie podpisu';
													|tr = 'Oluşturulan imzanın kontrolü'"));
		FormParameters.Insert("ErrorTextClient", ?(ValueIsFilled(CurrentData.CheckResult.SignatureMathValidationError),
			CurrentData.CheckResult.SignatureMathValidationError,
			CurrentData.CheckResult.AdditionalAttributesCheckError));
		FormParameters.Insert("ShowNeedHelp", True);
		FormParameters.Insert("ShowInstruction", True);
		
		If ValueIsFilled(CurrentData.CertificateAddress) Then
			AdditionalParameters.Insert("CertificateData",
			CurrentData.CertificateAddress);
		EndIf;
		
		FormParameters.Insert("AdditionalData", AdditionalParameters);
		
		ModuleDigitalSignatureClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);
		Return;
	EndIf;
	ModuleDigitalSignatureClient.OpenSignature(CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEncryptionCertificates

&AtClient
Procedure EncryptionCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenEncryptionCertificate(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region FileCommandHandlers

&AtClient
Procedure ShowInList(Command)
	
	FormObject = ThisObject["Object"]; // DefinedType.AttachedFileObject
	StandardSubsystemsClient.ShowInList(FormObject.Ref, Undefined);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	If IsNew()
		Or Object.Encrypted
		Or Object.SignedWithDS
		Or ValueIsFilled(Object.BeingEditedBy) Then
		Return;
	EndIf;
	
	FileData = FileData(Object.Ref, UUID, "ServerCall");
	Handler = New CallbackDescription("UpdateFromFileOnHardDriveCompletion", ThisObject);
	FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(Handler, FileData, UUID);
	
EndProcedure

&AtClient
Procedure StandardSaveAndClose(Command)
	
	If HandleFileRecordCommand() Then
		
		Result = New Structure();
		Result.Insert("ErrorText", "");
		Result.Insert("FileAdded", True);
		Result.Insert("FileRef", Object.Ref);
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StandardWrite(Command)
	
	HandleFileRecordCommand();
	
EndProcedure

&AtClient
Procedure StandardSetDeletionMark(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If Modified Then
		If Object.DeletionMark Then
			QueryText = NStr(
				"vi = 'Để thực hiện thao tác, cần ghi lại các thay đổi của tệp.
				      |Ghi lại các thay đổi và bỏ dấu xóa tệp
				      |""%1""?';
				      |ru = 'Для выполнения действия запишите изменения файла.
				      |Записать изменения и снять пометку на удаление с файла
				      |""%1""?';
				      |en = 'To proceed, save the file changes.
				      |Save the changes and clear the deletion mark from file
				      |""%1""?'; fa = 'To proceed, save the file changes.
				      |Save the changes and clear the deletion mark from file
				      |""%1""?';
				      |it = 'Per completare le azioni, registrare le modifiche del file.
				      |Registrare le modifiche e rimuovere il contrassegno per l''eliminazione dal file
				      |""%1""?';
				      |pl = 'Aby wykonać działanie, zapisz zmiany pliku.
				      |Zapisać zmiany i usunąć zaznaczenie do usunięcia z pliku
				      |""%1""?';
				      |tr = 'Eylemin gerçekleştirilmesi için dosyanın değişikliklerini kaydedin.
				      |Değişiklikler kaydedilip 
				      |""%1"" dosyasından silme işareti kaldırılsın mı?'");
		Else
			QueryText = NStr(
				"vi = 'Để thực hiện thao tác, cần ghi lại các thay đổi của tệp.
				      |Ghi lại các thay đổi và bỏ dấu xóa tệp
				      |""%1""?';
				      |ru = 'Для выполнения действия запишите изменения файла.
				      |Записать изменения и пометить на удаление файл
				      |""%1""?';
				      |en = 'To proceed, you need to save the file changes.
				      |Save the changes and mark the
				      |""%1"" file for deletion?'; fa = 'To proceed, you need to save the file changes.
				      |Save the changes and mark the
				      |""%1"" file for deletion?';
				      |it = 'Per completare le azioni, registrare le modifiche del file.
				      |Registrare le modifiche e contrassegnare per l''eliminazione il file
				      |""%1""?';
				      |pl = 'Aby wykonać działanie, zapisz zmiany pliku.
				      |Zapisać zmiany i zaznaczyć plik
				      |""%1"" do usunięcia?';
				      |tr = 'Eylemin gerçekleştirilmesi için dosyanın değişikliklerini kaydedin.
				      |Değişiklikler kaydedilip 
				      |""%1"" dosyası silinmek üzere işaretlensin mi?'");
		EndIf;
	Else
		If Object.DeletionMark Then
			QueryText = NStr("vi = 'Bỏ chọn tệp để xóa 
			                          |""%1""?';
			                          |ru = 'Снять пометку на удаление с файла
			                          |""%1""?';
			                          |en = 'Deletion mark will be cleared from %1.
			                          |Continue?'; fa = 'Deletion mark will be cleared from %1.
			                          |Continue?';
			                          |it = 'Rimuovere il contrassegno per la cancellazione dal file
			                          |""%1""?';
			                          |pl = 'Usunąć zaznaczenie do usunięcia z pliku
			                          |""%1""?';
			                          |tr = '%1 öğesinden silme işareti kaldırılacak.
			                          |Devam edilsin mi?'");
		Else
			QueryText = NStr("vi = 'Đánh dấu tệp để xóa
			                          |""%1""?';
			                          |ru = 'Пометить на удаление файл
			                          |""%1""?';
			                          |en = '%1 will be marked for deletion.
			                          |Continue?'; fa = '%1 will be marked for deletion.
			                          |Continue?';
			                          |it = 'Contrassegnare per la cancellazione il file
			                          |""%1""?';
			                          |pl = 'Zaznaczyć plik
			                          |""%1"" do usunięcia?';
			                          |tr = '%1 silinmek üzere işaretlenecek.
			                          |Devam edilsin mi?'");
		EndIf;
	EndIf;
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		QueryText, Object.Ref);
		
	CallbackDescription = New CallbackDescription("StandardSetDeletionMarkAnswerReceived", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure StandardSetDeletionMarkAnswerReceived(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Object.DeletionMark = Not Object.DeletionMark;
		HandleFileRecordCommand();
	EndIf;
	
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

#Region DigitalSignatureAndEncryptionCommandHandlers

&AtClient
Procedure SendForSigning(Command)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature")
		// StandardSubsystems.MobileSignatureService
		Or Not CommonClient.SubsystemExists("StandardSubsystems.MobileSignatureService")
		// End StandardSubsystems.MobileSignatureService
		Then
		Return;
	EndIf;
	
	If IsNew()
		Or ValueIsFilled(Object.BeingEditedBy)
		Or Object.Encrypted Then
		Return;
	EndIf;
	
	If Modified Then
		Write();
	EndIf;
	
	CallbackDescription      = New CallbackDescription("OnGetSignature", ThisObject);
	AdditionalParameters = New Structure("ResultProcessing", CallbackDescription);
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SigningParameters = ModuleDigitalSignatureClient.NewSignatureType();
	SigningParameters.CanSelectLetterOfAuthority = True;
	FilesOperationsClient.SendFileForSigning(Object.Ref, UUID, AdditionalParameters, SigningParameters);

EndProcedure

&AtClient
Procedure Sign(Command)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	If IsNew()
		Or ValueIsFilled(Object.BeingEditedBy)
		Or Object.Encrypted Then
		Return;
	EndIf;
	
	If Modified Then
		Write();
	EndIf;
	
	CallbackDescription      = New CallbackDescription("OnGetSignature", ThisObject);
	AdditionalParameters = New Structure("ResultProcessing", CallbackDescription);
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SigningParameters = ModuleDigitalSignatureClient.NewSignatureType();
	SigningParameters.AllowSendingForSigning = True;
	SigningParameters.CanSelectLetterOfAuthority = True;
	FilesOperationsClient.SignFile(Object.Ref, UUID, AdditionalParameters, SigningParameters);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	If IsNew()
		Or ValueIsFilled(Object.BeingEditedBy)
		Or Object.Encrypted Then
		Return;
	EndIf;
	
	AttachedFile = Object.Ref;
	FilesOperationsInternalClient.AddSignatureFromFile(
		AttachedFile,
		UUID,
		New CallbackDescription("OnGetSignatures", ThisObject));
	
EndProcedure

&AtClient
Procedure SaveWithDigitalSignature(Command)
	
	If IsNew()
		Or ValueIsFilled(Object.BeingEditedBy)
		Or Object.Encrypted Then
		Return;
	EndIf;
	
	FilesOperationsClient.SaveWithDigitalSignature(
		Object.Ref,
		UUID);
	
EndProcedure

&AtClient
Procedure Encrypt(Command)
	
	If IsNew() Or ValueIsFilled(Object.BeingEditedBy) Or Object.Encrypted Then
		Return;
	EndIf;
	
	If Modified Then
		Write();
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(Object.Ref);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	Handler = New CallbackDescription("EncryptAfterEncryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Encrypt(
		Handler,
		FileData,
		UUID);
		
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
		WorkingDirectoryName);
	
	FilesOperationsInternalClient.InformOfEncryption(
		FilesArrayInWorkingDirectoryToDelete,
		ExecutionParameters.FileData.Owner,
		Object.Ref);
		
	NotifyChanged(Object.Ref);
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
	Notify("Write_File", FileWriteNotificationParameters, Object.Ref);
	
	SetAvaliabilityOfEncryptionList();
	
EndProcedure

&AtClient
Procedure Decrypt(Command)
	
	If IsNew() Or Not Object.Encrypted Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.GetFileDataAndVersionsCount(Object.Ref);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("FileData", FileData);
	Handler = New CallbackDescription("DecryptAfterDecryptAtClient", ThisObject, HandlerParameters);
	
	FilesOperationsInternalClient.Decrypt(
		Handler,
		FileData.Ref,
		UUID,
		FileData);
	
EndProcedure

&AtClient
Procedure DecryptAfterDecryptAtClient(Result, ExecutionParameters) Export
	
	If Not Result.Success Then
		Return;
	EndIf;
	WorkingDirectoryName = FilesOperationsInternalClient.UserWorkingDirectory();
	
	DecryptServer(Result.DataArrayToStoreInDatabase, WorkingDirectoryName);
	
	FilesOperationsInternalClient.InformOfDecryption(
		ExecutionParameters.FileData.Owner,
		Object.Ref);
	
	FillEncryptionListAtServer();
	SetAvaliabilityOfEncryptionList();
	
EndProcedure

&AtServer
Procedure FillEncryptionListAtServer()
	FilesOperationsInternal.FillEncryptionList(ThisObject);
EndProcedure

&AtClient
Procedure DigitalSignatureCommandListOpenSignature(Command)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.OpenSignature(Items.DigitalSignatures.CurrentData);
	
EndProcedure

&AtClient
Procedure VerifyDigitalSignature(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If Items.DigitalSignatures.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	FileData = FileData(Object.Ref, UUID);
	
	FilesOperationsInternalClient.VerifySignatures(ThisObject,
		FileData.RefToBinaryFileData,
		Items.DigitalSignatures.SelectedRows);
	
	DetermineIfModified();
		
EndProcedure

&AtClient
Procedure CheckEverything(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	FileData = FileData(Object.Ref, UUID);
	FilesOperationsInternalClient.VerifySignatures(ThisObject, FileData.RefToBinaryFileData);
	DetermineIfModified();
	
EndProcedure

&AtClient
Procedure DetermineIfModified()
	If Items.FormWriteAndClose.Visible And Items.FormWriteAndClose.Enabled Then
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Procedure ExtendActionSignatures(Command)
	
	FollowUpHandler = New CallbackDescription("OnGetSignatures", ThisObject);
	
	RenewalOptions = New Structure;
	
	Structure = New Structure;
	Structure.Insert("SignedObject", Parameters.Key);
	Structure.Insert("SequenceNumber", Undefined);
	RenewalOptions.Insert("Signature", Structure);
	
	FilesOperationsInternalClient.ExtendActionSignatures(ThisObject, RenewalOptions, FollowUpHandler);
	
EndProcedure

&AtClient
Procedure MarkAsManuallyVerified(Command)
	
	If Items.DigitalSignatures.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	If IsFileTransferredToArchive Then
		Return;
	EndIf;
	
	ClosingNotification1 = New CallbackDescription("AfterSignatureAuthenticityJustificationEntered",
		ThisObject);
		
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.EnterSignatureAuthenticityJustification(ThisObject, ClosingNotification1);
	
EndProcedure

&AtClient
Procedure SaveSignature(Command)
	
	If Items.DigitalSignatures.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.DigitalSignatures.CurrentData;
	
	If CurrentData.Object = Undefined Or CurrentData.Object.IsEmpty() Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	SignatureFileName = CurrentData.SignatureFileName;
	If Not ValueIsFilled(SignatureFileName) Then
	
		SignatureFilesExtension = ModuleDigitalSignatureClient.PersonalSettings().SignatureFilesExtension;
		ModuleDigitalSignatureInternalClientServer = CommonClient.CommonModule("DigitalSignatureInternalClientServer");
		SignatureFileName = ModuleDigitalSignatureInternalClientServer.SignatureFileName(Object.Description,
				CurrentData.CertificateOwner, SignatureFilesExtension);
	EndIf;
	
	ModuleDigitalSignatureClient.SaveSignature(CurrentData.SignatureAddress, SignatureFileName);
	
EndProcedure

&AtClient
Procedure DeleteDS(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("DeleteDigitalSignatureAnswerReceived", ThisObject);
	ShowQueryBox(CallbackDescription, NStr("vi = 'Xóa chữ ký đã chọn?';
											|ru = 'Удалить выделенные подписи?';
											|en = 'Do you want to delete the selected signatures?'; fa = 'Do you want to delete the selected signatures?';
											|it = 'Eliminare le firme evidenziate?';
											|pl = 'Usunąć zaznaczone podpisy?';
											|tr = 'Seçilen imzalar silinsin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DeleteDigitalSignatureAnswerReceived(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Write();
	DeleteFromSignatureListAndWriteFile();
	NotifyChanged(Object.Ref);
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
	Notify("Write_File", FileWriteNotificationParameters, Object.Ref);
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

&AtClient
Procedure OpenEncryptionCertificate(Command)
	
	CurrentData = Items.EncryptionCertificates.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If IsBlankString(CurrentData.CertificateAddress) Then
		ModuleDigitalSignatureClient.OpenCertificate(CurrentData.Thumbprint);
	Else
		ModuleDigitalSignatureClient.OpenCertificate(CurrentData.CertificateAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvaliabilityOfDSCommandsList()
	
	FilesOperationsInternalClient.SetCommandsAvailabilityOfDigitalSignaturesList(ThisObject, IsNew());
	
EndProcedure

&AtClient
Procedure SetAvaliabilityOfEncryptionList()
	
	FilesOperationsInternalClient.SetCommandsAvailabilityOfEncryptionCertificatesList(ThisObject);
	
EndProcedure

#EndRegion

#Region CommandHandlersToSupportCollaborativeFileManagement

&AtClient
Procedure Lock(Command)
	
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	Handler = New CallbackDescription("ReadAndSetFormItemsAvailability", ThisObject);
	FilesOperationsInternalClient.LockWithNotification(Handler, Object.Ref, UUID);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.BeingEditedBy)
	   And Object.BeingEditedBy <> CurrentUser Then
		Return;
	EndIf;
	
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	FileData = FileData(Object.Ref, UUID, "ToOpen");
	FileBeingEdited = ValueIsFilled(Object.BeingEditedBy);
	FilesOperationsInternalClient.EditFile(Undefined, FileData, UUID);
	If Not FileBeingEdited Then
		UpdateObject();
		NotifyChanged(Object.Ref);
		FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
		Notify("Write_File", FileWriteNotificationParameters, Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	If IsNew()
		Or Not ValueIsFilled(Object.BeingEditedBy)
		Or Object.BeingEditedBy <> CurrentUser Then
			Return;
	EndIf;
	
	FileData = FileData(Object.Ref, UUID, "ServerCall");
	CallbackDescription = New CallbackDescription("EndEditingPuttingCompleted", ThisObject);
	FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(CallbackDescription, FileData.Ref, UUID);
	FileUpdateParameters.StoreVersions = FileData.StoreVersions;
	If Not CanCreateFileVersions Then
		FileUpdateParameters.Insert("CreateNewVersion", False);
	EndIf;
	FileUpdateParameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
	FileUpdateParameters.BeingEditedBy = FileData.BeingEditedBy;
	FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	
EndProcedure

&AtClient
Procedure EndEditingPuttingCompleted(FileInfo, AdditionalParameters) Export
	
	UpdateObject();
	
	NotifyChanged(Object.Ref);
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
	Notify("Write_File", FileWriteNotificationParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure Release(Command)
	
	If IsNew()
		Or Not ValueIsFilled(Object.BeingEditedBy)
		Or Object.BeingEditedBy <> CurrentUser Then
		Return;
	EndIf;

	ReleaseCompletion = New CallbackDescription("ReleaseCompletion", ThisObject);
	If Modified Then
		ShowQueryBox(ReleaseCompletion,
			NStr("vi = 'Khi hủy chỉnh sửa, những thay đổi đã nhập vào sẽ bị mất. Tiếp tục?';
				|ru = 'При отмене редактирования внесенные изменения будут утеряны. Продолжить?';
				|en = 'If editing is canceled, changes made will be lost. Continue?'; fa = 'If editing is canceled, changes made will be lost. Continue?';
				|it = 'Annullando la modifica, le correzioni apportate andranno perse. Continuare?';
				|pl = 'Podczas anulowania edytowania wprowadzone zmiany zostaną utracone. Kontynuować?';
				|tr = 'Düzenleme iptal edildiğinde yapılan değişiklikler kaybolacaktır. Devam edilsin mi?'"),
			QuestionDialogMode.YesNo);
	Else
		RunCallback(ReleaseCompletion, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReleaseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
		
	UnlockFile();
	NotifyChanged(Object.Ref);
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters("EditCanceled");
	Notify("Write_File", FileWriteNotificationParameters, Object.Ref);
	FilesOperationsInternalClient.ChangeLockedFilesCount();
	
EndProcedure

&AtClient
Procedure SaveChanges(Command)
	
	If Modified Then
		Write();
	EndIf;
	
	Handler = New CallbackDescription("ReadAndSetFormItemsAvailability", ThisObject);	
	FilesOperationsInternalClient.SaveFileChangesWithNotification(Handler,
		Object.Ref, UUID);
	
EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillAdditionalAttributesInForm(ThisObject);
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

&AtClient
Procedure Send(Command)
	
	If ValueIsFilled(Object.Ref) Or Write() Then
		Files = CommonClientServer.ValueInArray(Object.Ref);
		OnSendFilesViaEmail(SendOptions, Files, Object.FileOwner, UUID);
		FilesOperationsInternalClient.SendFilesViaEmail(Files, UUID, SendOptions, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	If ValueIsFilled(Object.Ref) Or Write() Then
		Files = CommonClientServer.ValueInArray(Object.Ref);
		FilesOperationsClient.PrintFiles(Files, UUID);
	EndIf;

EndProcedure

&AtClient
Procedure PrintWithStamp(Command)
	
	If ValueIsFilled(Object.Ref) Or Write() Then
		
		FilesOperationsInternalClient.DoPrintFileWithStamp(Object.Ref, UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Delete(Command)
	
	FilesOperationsInternalClient.DeleteData(
		New CallbackDescription("AfterDeleteData", ThisObject),
		Object.Ref, UUID);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure RefreshTitle()
	
	If TypeOf(Object.FileOwner) = Type("CatalogRef.FilesFolders") Then
		FileType = NStr("vi = 'Tệp';
						|ru = 'Файл';
						|en = 'File'; fa = 'فایل';
						|it = 'File';
						|pl = 'Plik';
						|tr = 'Dosya'");
	Else
		FileType = NStr("vi = 'Tệp đính kèm';
						|ru = 'Присоединенный файл';
						|en = 'Attachment'; fa = 'پیوست';
						|it = 'File allegato';
						|pl = 'Załączony plik';
						|tr = 'Ekli dosya'");
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2)';
				|ru = '%1 (%2)';
				|en = '%1 (%2)'; fa = '%1 (%2)';
				|it = '%1 (%2)';
				|pl = '%1 (%2)';
				|tr = '%1 (%2)'"), String(Object.Ref), FileType);
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (Tạo mới)';
				|ru = '%1 (Создание)';
				|en = '%1 (Create)'; fa = '%1 (Create)';
				|it = '%1 (creazione)';
				|pl = '%1 (utworzenie)';
				|tr = '%1 (Oluştur)'"), FileType);
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayAdditionalDataTabs()
	
	If Items.GroupAdditionalAttributes.ChildItems.Count() > 0 Then
		BlankDecoration = Items.Find("PropertiesEmptyDecoration");
		If BlankDecoration <> Undefined Then
			AdditionalAttributesVisibility = BlankDecoration.Visible;
		Else
			AdditionalAttributesVisibility = True;
		EndIf;
	Else
		AdditionalAttributesVisibility = False;
	EndIf;
	
	UseTabs = AdditionalAttributesVisibility Or Items.DigitalSignaturesGroup.Visible Or Items.EncryptionCertificatesGroup.Visible;
	Items.AdditionalPageDataGroup.PagesRepresentation =
		?(UseTabs , FormPagesRepresentation.TabsOnTop, FormPagesRepresentation.None);

EndProcedure

&AtServerNoContext
Function FileData(Val AttachedFile, Val FormIdentifier = Undefined, Val Mode = "")
	
	UnlockObject(AttachedFile, FormIdentifier);
	If Mode = "ToOpen" Then
		Return FilesOperationsInternalServerCall.FileDataToOpen(
			AttachedFile, Undefined, FormIdentifier);
	ElsIf Mode = "ServerCall" Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.FormIdentifier = FormIdentifier;
		Return FilesOperationsInternalServerCall.FileData(AttachedFile,, FileDataParameters);
	Else
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = True;
		FileDataParameters.FormIdentifier = FormIdentifier;
		Return FilesOperations.FileData(AttachedFile, FileDataParameters);
	EndIf;
EndFunction

&AtClient
Procedure OpenFileForViewing()
	
	If IsNew() Then
		Return;
	EndIf;

	FileBeingEdited = ValueIsFilled(Object.BeingEditedBy) And Object.BeingEditedBy = CurrentUser;	

	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("OpenFile");
	FileGettingParameters.AttachedFile				= Object.Ref;
	FileGettingParameters.OwnerForm					= ThisObject;
	
	FileGettingParameters.ActionParameters.FileBeingEdited = FileBeingEdited;
	
	FilesOperationsClient.OpenFile(FileGettingParameters);	
	
EndProcedure

&AtClient
Procedure OpenFileDirectory()
	
	If IsNew()
		Or Object.Encrypted Then
		Return;
	EndIf;
	
	FileData = FileData(Object.Ref, UUID, "ToOpen");
	FilesOperationsClient.OpenFileDirectory(FileData);
	
EndProcedure

&AtClient
Procedure SaveAs()
	
	If IsNew() Then
		Return;
	EndIf;
	
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("SaveAs", "FilesOperationsInternal.FileDataToSaveAsync");
	FileGettingParameters.AttachedFile				= Object.Ref;
	FileGettingParameters.OwnerForm					= ThisObject;
	
	FilesOperationsClient.SaveFileAs(FileGettingParameters);	
	
EndProcedure

&AtClient
Procedure AfterDeleteData(Result, AdditionalParameters) Export
	
	Close();
	
EndProcedure

&AtServer
Procedure DeleteFromSignatureListAndWriteFile()
	
	If Not Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
	
	RowIndexes = New Array;
	
	For Each SelectedRowNumber In Items.DigitalSignatures.SelectedRows Do
		RowToDelete = DigitalSignatures.FindByID(SelectedRowNumber);
		If ValueIsFilled(RowToDelete.SequenceNumber) Then
			RowIndexes.Add(RowToDelete.SequenceNumber);
		Else
			RowIndexes.Add(RowToDelete.SignatureID);
		EndIf;
	EndDo;
	
	ModuleDigitalSignature.DeleteSignature(Object.Ref, RowIndexes, UUID);
	UpdateObject();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetButtonsAvailability(Form, Items)
	
	AllCommandNames = AllFormCommandsNames();
	AvailableCommandsNames = AvailableFormCommands(Form);
		
	If Form.DigitalSignatures.Count() = 0 Then
		MakeCommandUnavailable(AvailableCommandsNames, "OpenSignature");
		Form.Items.FormSaveWithSignature.Visible = False;
	Else
		Form.Items.FormSaveWithSignature.Visible = True;
	EndIf;
	
	For Each FormItem In Items Do
		If TypeOf(FormItem) <> Type("FormButton") Then
			Continue;
		EndIf;
		If AllCommandNames.Find(FormItem.CommandName) <> Undefined Then
			FormItem.Enabled = False;
		EndIf;
	EndDo;
	
	For Each FormItem In Items Do
		If TypeOf(FormItem) <> Type("FormButton") Then
			Continue;
		EndIf;
		If AvailableCommandsNames.Find(FormItem.CommandName) <> Undefined Then
			FormItem.Enabled = True;
		EndIf;
	EndDo;
	
	If AvailableCommandsNames.Find("Edit") <> Undefined Then
		Items.LongDesc.InputHint = NStr("vi = 'Giải thích ngắn gọn. Ngày soạn nội dung tệp, hãy nhấn nút Soạn.';
										|ru = 'Краткое пояснение. Для редактирования содержимого файла нажмите кнопку Редактировать.';
										|en = 'A brief description. To edit the file, click Edit.'; fa = 'شرح مختصر. برای ویرایش فایل، روی «ویرایش» کلیک کنید.';
										|it = 'Breve spiegazione. Per modificare il contenuto del file, cliccate Modificare.';
										|pl = 'Krótki komentarz. W celu edycji zawartości pliku naciśnij przycisk Edytuj.';
										|tr = 'Kısa not. Dosya içeriğini düzenlemek için Düzenle''ye tıklayın.'");
	Else
		Items.LongDesc.InputHint = NStr("vi = 'Giải thích ngắn gọn. Để xem nội dung tệp, hãy nhấn nút Xem.';
										|ru = 'Краткое пояснение. Для просмотра содержимого файла нажмите кнопку Просмотреть.';
										|en = 'A brief description. To view the file, click View.'; fa = 'A brief description. To view the file, click View.';
										|it = 'Краткое пояснение. Для просмотра содержимого файла нажмите кнопку Просмотреть.';
										|pl = 'A brief description. To view the file, click View.';
										|tr = 'Kısa açıklama. Dosya içeriğini gözden geçirmek için Gözden Geçir''e tıklayın.'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function AllFormCommandsNames()
	
	CommandsNames = FileChangeCommandsNames();
	CommonClientServer.SupplementArray(CommandsNames, OtherCommandsNames()); 
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Function OtherCommandsNames()
	
	CommandsNames = New Array;
	
	// Simple commands that are available to any user that reads the files
	CommandsNames.Add("SaveWithDigitalSignature");
	
	CommandsNames.Add("OpenCertificate");
	CommandsNames.Add("OpenSignature");
	CommandsNames.Add("VerifyDigitalSignature");
	CommandsNames.Add("CheckEverything");
	CommandsNames.Add("SaveSignature");
	
	CommandsNames.Add("OpenFileDirectory");
	CommandsNames.Add("OpenFileForViewing");
	CommandsNames.Add("SaveAs");
	
	CommandsNames.Add("Print");
	CommandsNames.Add("PrintWithStamp");
	CommandsNames.Add("Send");
	
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Function FileChangeCommandsNames()
	
	CommandsNames = New Array;
	
	CommandsNames.Add("Sign");
	CommandsNames.Add("AddDSFromFile");
	CommandsNames.Add("SendForSigning");
	
	CommandsNames.Add("DeleteDS");
	
	CommandsNames.Add("Edit");
	CommandsNames.Add("Lock");
	CommandsNames.Add("EndEdit");
	CommandsNames.Add("Release");
	CommandsNames.Add("SaveChanges");
	
	CommandsNames.Add("Encrypt");
	CommandsNames.Add("Decrypt");
	
	CommandsNames.Add("StandardCommandsCopy");
	CommandsNames.Add("UpdateFromFileOnHardDrive");
	
	CommandsNames.Add("StandardWrite");
	CommandsNames.Add("StandardSaveAndClose");
	CommandsNames.Add("StandardSetDeletionMark");
	
	CommandsNames.Add("Copy");
	
	
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Function AvailableFormCommands(Form)
	
	IsNewFile = Form.Object.Ref.IsEmpty();
	
	If IsNewFile Then
		CommandsNames = New Array;
		CommandsNames.Add("StandardWrite");
		CommandsNames.Add("StandardSaveAndClose");
		Return CommandsNames;
	EndIf;
	
	CommandsNames = AllFormCommandsNames();
	
	FileToEditInCloud = Form.FileToEditInCloud;
	FileBeingEdited = ValueIsFilled(Form.Object.BeingEditedBy) Or FileToEditInCloud;
	CurrentUserEditsFile = Form.Object.BeingEditedBy = Form.CurrentUser;
	FileSigned = Form.Object.SignedWithDS;
	FileEncrypted = Form.Object.Encrypted;
	
	If FileBeingEdited Then
		If CurrentUserEditsFile Then
			MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
		Else
			MakeCommandUnavailable(CommandsNames, "EndEdit");
			MakeCommandUnavailable(CommandsNames, "Edit");
			
			If Not Form.FilesModification Then
				MakeCommandUnavailable(CommandsNames, "Release");
			EndIf;
			
		EndIf;
		MakeCommandUnavailable(CommandsNames, "Lock");
		
		MakeDSCommandsUnavailable(CommandsNames);
		
		MakeCommandUnavailable(CommandsNames, "Encrypt");
		MakeCommandUnavailable(CommandsNames, "Decrypt");
	Else
		MakeCommandUnavailable(CommandsNames, "EndEdit");
		MakeCommandUnavailable(CommandsNames, "SaveChanges");
		
		If Not Form.FilesModification Then
			MakeCommandUnavailable(CommandsNames, "Release");
		EndIf;
	EndIf;
	
	If FileSigned Then
		MakeCommandUnavailable(CommandsNames, "EndEdit");
		MakeCommandUnavailable(CommandsNames, "Release");
		MakeCommandUnavailable(CommandsNames, "Edit");
		MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
	Else
		MakeCommandUnavailable(CommandsNames, "OpenCertificate");
		MakeCommandUnavailable(CommandsNames, "OpenSignature");
		MakeCommandUnavailable(CommandsNames, "VerifyDigitalSignature");
		MakeCommandUnavailable(CommandsNames, "CheckEverything");
		MakeCommandUnavailable(CommandsNames, "SaveSignature");
		MakeCommandUnavailable(CommandsNames, "DeleteDS");
		MakeCommandUnavailable(CommandsNames, "SaveWithDigitalSignature");
	EndIf;
	
	If FileEncrypted Then
		MakeDSCommandsUnavailable(CommandsNames);
		If Not FileBeingEdited Then
			MakeCommandUnavailable(CommandsNames, "Release");
			MakeCommandUnavailable(CommandsNames, "EndEdit");
		EndIf;
		
		MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
		MakeCommandUnavailable(CommandsNames, "Encrypt");
		MakeCommandUnavailable(CommandsNames, "OpenFileDirectory");
		MakeCommandUnavailable(CommandsNames, "Sign");
	Else
		MakeCommandUnavailable(CommandsNames, "Decrypt");
	EndIf;
	
	If FileToEditInCloud Then
		MakeCommandUnavailable(CommandsNames, "StandardCommandsCopy");
		MakeCommandUnavailable(CommandsNames, "StandardSetDeletionMark");
		
		MakeCommandUnavailable(CommandsNames, "StandardSaveAndClose");
		MakeCommandUnavailable(CommandsNames, "StandardWrite");
		MakeCommandUnavailable(CommandsNames, "Copy");
		MakeCommandUnavailable(CommandsNames, "SaveChanges");
		MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
		
	EndIf;
	
	IsFilePlacedInArchive = Form.IsFileTransferredToArchive;
	If IsFilePlacedInArchive Then

		MakeDSCommandsUnavailable(CommandsNames);
		MakeCommandUnavailable(CommandsNames, "UpdateFromFileOnHardDrive");
		MakeCommandUnavailable(CommandsNames, "EndEdit");
		MakeCommandUnavailable(CommandsNames, "Edit");
		MakeCommandUnavailable(CommandsNames, "Release");
		MakeCommandUnavailable(CommandsNames, "Lock");
		MakeCommandUnavailable(CommandsNames, "Encrypt");
		MakeCommandUnavailable(CommandsNames, "Decrypt");
		MakeCommandUnavailable(CommandsNames, "SaveChanges");

		MakeCommandUnavailable(CommandsNames, "OpenCertificate");
		MakeCommandUnavailable(CommandsNames, "OpenSignature");
		MakeCommandUnavailable(CommandsNames, "VerifyDigitalSignature");
		MakeCommandUnavailable(CommandsNames, "CheckEverything");
		MakeCommandUnavailable(CommandsNames, "SaveSignature");
		MakeCommandUnavailable(CommandsNames, "DeleteDS");
		MakeCommandUnavailable(CommandsNames, "SaveWithDigitalSignature");

		MakeCommandUnavailable(CommandsNames, "Sign");
		
		MakeCommandUnavailable(CommandsNames, "Send");
		
		MakeCommandUnavailable(CommandsNames, "Print");
		MakeCommandUnavailable(CommandsNames, "PrintWithStamp");

		MakeCommandUnavailable(CommandsNames, "MarkAsManuallyVerified");

	EndIf;
	
	If Form.ReadOnly Then
		MakeDSCommandsUnavailable(CommandsNames);
	EndIf;
	
	Return CommandsNames;
	
EndFunction

&AtClientAtServerNoContext
Procedure MakeDSCommandsUnavailable(Val CommandsNames)
	
	MakeCommandUnavailable(CommandsNames, "Sign");
	MakeCommandUnavailable(CommandsNames, "AddDSFromFile");
	MakeCommandUnavailable(CommandsNames, "SaveWithDigitalSignature");
	
EndProcedure

&AtClientAtServerNoContext
Procedure MakeCommandUnavailable(CommandsNames, CommandName)
	
	CommonClientServer.DeleteValueFromArray(CommandsNames, CommandName);
	
EndProcedure

&AtServer
Procedure EncryptServer(DataArrayToStoreInDatabase,
                            ThumbprintsArray,
                            FilesArrayInWorkingDirectoryToDelete,
                            WorkingDirectoryName)
	
	EncryptionInformationWriteParameters = FilesOperationsInternal.EncryptionInformationWriteParameters();
	EncryptionInformationWriteParameters.WorkingDirectoryName = WorkingDirectoryName;
	EncryptionInformationWriteParameters.DataArrayToStoreInDatabase = DataArrayToStoreInDatabase;
	EncryptionInformationWriteParameters.ThumbprintsArray = ThumbprintsArray;
	EncryptionInformationWriteParameters.FilesArrayInWorkingDirectoryToDelete = FilesArrayInWorkingDirectoryToDelete;
	EncryptionInformationWriteParameters.UUID = UUID;
		
	FilesOperationsInternal.WriteEncryptionInformation(
		Object.Ref, EncryptionInformationWriteParameters);
		
	UpdateInfoOfObjectCertificates();
	
EndProcedure

&AtServer
Procedure DecryptServer(DataArrayToStoreInDatabase,
                             WorkingDirectoryName)
	
	EncryptionInformationWriteParameters = FilesOperationsInternal.EncryptionInformationWriteParameters();
	EncryptionInformationWriteParameters.Encrypt = False;
	EncryptionInformationWriteParameters.WorkingDirectoryName = WorkingDirectoryName;
	EncryptionInformationWriteParameters.DataArrayToStoreInDatabase = DataArrayToStoreInDatabase;
	EncryptionInformationWriteParameters.UUID = UUID;
	
	FilesOperationsInternal.WriteEncryptionInformation(
		Object.Ref, EncryptionInformationWriteParameters);
		
	UpdateInfoOfObjectCertificates();
	
EndProcedure

&AtServer
Procedure UpdateObject()
	
	Read();
	ModificationDate = ToLocalTime(Object.UniversalModificationDate);
	SetButtonsAvailability(ThisObject, Items);
	
EndProcedure

&AtServer
Procedure UnlockFile()
	
	ObjectToWrite = FormAttributeToValue("Object");
	FilesOperationsInternal.UnlockFile(ObjectToWrite);
	ValueToFormAttribute(ObjectToWrite, "Object");
	
EndProcedure

&AtClient
Function HandleFileRecordCommand()
	
	If IsBlankString(Object.Description) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Để tiếp tục, hãy chỉ ra tên tệp.';
				|ru = 'Для продолжения укажите имя файла.';
				|en = 'To proceed, please provide the file name.'; fa = 'To proceed, please provide the file name.';
				|it = 'Per continuare indicate il nome del file.';
				|pl = 'Aby kontynuować, wskaż nazwę pliku.';
				|tr = 'Devam etmek için dosya adını belirtin.'"), , "Description", "Object");
		Return False;
	EndIf;
	
	Try
		FilesOperationsInternalClient.CorrectFileName(Object.Description);
	Except
		CommonClient.MessageToUser(
			ErrorProcessing.BriefErrorDescription(ErrorInfo()), ,"Description", "Object");
		Return False;
	EndTry;
	
	Write();

	Modified = False;
	RepresentDataChange(Object.Ref, DataChangeType.Update);
	NotifyChanged(Object.Ref);
	NotifyChanged(Object.FileOwner);
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
	FileWriteNotificationParameters.IsNew = FileCreated;
	Notify("Write_File", FileWriteNotificationParameters, Object.Ref);
	
	SetAvaliabilityOfDSCommandsList();
	SetAvaliabilityOfEncryptionList();
	
	If DescriptionBeforeWrite <> Object.Description Then
		// update file in cache
		If ValueIsFilled(Object.CurrentVersion) Then
			FilesOperationsInternalClient.RefreshInformationInWorkingDirectory(
				Object.CurrentVersion, Object.Description);
		Else
			FilesOperationsInternalClient.RefreshInformationInWorkingDirectory(
				Object.Ref, Object.Description);
		EndIf;
		
		DescriptionBeforeWrite = Object.Description;
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Procedure UnlockObject(Val Ref, Val UUID)
	
	UnlockDataForEdit(Ref, UUID);
	
EndProcedure

// Continue the SignDSFile procedure.
// It is called from the DigitalSignature subsystem after signing data for non-standard
// way of adding a signature to the object.
//
&AtClient
Procedure OnGetSignature(ExecutionParameters, Context) Export
	
	UpdateInfoOfObjectSignature();
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

// Continue the SignDSFile procedure.
// It is called from the DigitalSignature subsystem after preparing signatures from files
// for non-standard way of adding a signature to the object.
//
&AtClient
Procedure OnGetSignatures(ExecutionParameters, Context) Export
	
	UpdateInfoOfObjectSignature();
	SetAvaliabilityOfDSCommandsList();
	
EndProcedure

&AtServer
Procedure UpdateInfoOfObjectSignature()
	
	FileObject1 = Object.Ref.GetObject();
	ValueToFormAttribute(FileObject1, "Object");
	FilesOperationsInternal.FillSignatureList(ThisObject);
	SetButtonsAvailability(ThisObject, Items);
	
EndProcedure

&AtServer
Procedure UpdateInfoOfObjectCertificates()
	
	FileObject1 = Object.Ref.GetObject();
	ValueToFormAttribute(FileObject1, "Object");
	FilesOperationsInternal.FillEncryptionList(ThisObject);
	SetButtonsAvailability(ThisObject, Items);
	
EndProcedure

&AtClient
Procedure ReadAndSetFormItemsAvailability(Result, AdditionalParameters) Export
	
	UpdateObject();
	
EndProcedure

&AtClient
Function IsNew()
	
	Return Object.Ref.IsEmpty();
	
EndFunction

&AtClient
Procedure UpdateFromFileOnHardDriveCompletion(Result, ExecutionParameters) Export
	
	UpdateObject();
	NotifyChanged(Object.Ref);
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
	Notify("Write_File", FileWriteNotificationParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	OnChangeUseSignOrEncryptionAtServer();
	DisplayAdditionalDataTabs();
	
EndProcedure

&AtServer
Procedure OnChangeUseSignOrEncryptionAtServer()
	
	FilesOperationsInternal.CryptographyOnCreateFormAtServer(ThisObject, False);
	
EndProcedure

&AtClient
Procedure AdditionalPageDataGroupOnCurrentPageChange(Item, CurrentPage)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties")
		And CurrentPage.Name = "GroupAdditionalAttributes"
		And Not PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshFullPath()
	If TypeOf(Object.FileOwner) = Type("CatalogRef.FilesFolders") Then
		
		FolderParent = Object.FileOwner;
		
		If ValueIsFilled(FolderParent) Then
			
			FullPath = "";
			
			While ValueIsFilled(FolderParent) Do
				
				If Not IsBlankString(FullPath) Then
					FullPath = "\" + FullPath;
				EndIf;
				
				FullPath = String(FolderParent) + FullPath;
				
				FolderParent = Common.ObjectAttributeValue(FolderParent, "Parent");
				If Not ValueIsFilled(FolderParent) Then
					Break;
				EndIf;
				
			EndDo;
			
			Items.FileOwner.ToolTip = FullPath;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateVersionCopy(Receiver, Source)
	
	SourceAttributes = Common.ObjectAttributesValues(Source, 
		"CurrentVersion,Encrypted,UniversalModificationDate");
	
	If SourceAttributes.CurrentVersion.IsEmpty() Then
		Return;
	EndIf;
		
	FileStorage1 = Undefined;
	CurrentVersionAttributes = Common.ObjectAttributesValues(SourceAttributes.CurrentVersion, 
		"FileStorageType,Size,Extension,TextStorage");

	If FileManagementInBinaryDataStorageInternal.StorageTypeDoesNotUseDisks(CurrentVersionAttributes.FileStorageType) Then
		FileStorage1 = FilesOperations.FileFromInfobaseStorage(SourceAttributes.CurrentVersion);
	EndIf;
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
	FileInfo1.BaseName = Object.Description;
	FileInfo1.Size = CurrentVersionAttributes.Size;
	FileInfo1.ExtensionWithoutPoint = CurrentVersionAttributes.Extension;
	FileInfo1.TempFileStorageAddress = FileStorage1;
	FileInfo1.TempTextStorageAddress = CurrentVersionAttributes.TextStorage;
	FileInfo1.RefToVersionSource = SourceAttributes.CurrentVersion;
	FileInfo1.Encrypted = SourceAttributes.Encrypted;
	FileInfo1.ModificationTimeUniversal = SourceAttributes.UniversalModificationDate;
	FileInfo1.Modified = ModificationDate;
	
	Version = FilesOperationsInternal.CreateVersion(Receiver, FileInfo1);
	FilesOperationsInternal.UpdateVersionInFile(
		Receiver, Version, CurrentVersionAttributes.TextStorage, UUID);
	UpdateObject();
	
EndProcedure

&AtServer
Procedure UpdateCloudServiceNote(AttachedFile)
	
	NoteVisibility = False;
	
	If GetFunctionalOption("UseFileSync") Then
		
		SynchronizationInfo = FilesOperationsInternal.SynchronizationInfo(Object.FileOwner);
		If SynchronizationInfo <> Undefined Then
			
			Account = SynchronizationInfo.Account;
			NoteVisibility = True;
			
			Items.DecorationNote.Title = StringFunctions.FormattedString(
				NStr("vi = 'Tệp chỉ khả dụng để xem, hoạt động với Được tiến hành trong dịch vụ đám mây <a href=""%1""> %2 </a>.';
					|ru = 'Файл доступен только для просмотра, работа с ним ведется в облачном сервисе <a href=""%1"">%2</a>.';
					|en = 'This is a read-only file. It is stored in cloud service <a href=""%1"">%2</a>.'; fa = 'This is a read-only file. It is stored in cloud service <a href=""%1"">%2</a>.';
					|it = 'Файл доступен только для просмотра, работа с ним ведется в облачном сервисе <a href=""%1"">%2</a>.';
					|pl = 'This is a read-only file. It is stored in cloud service <a href=""%1"">%2</a>.';
					|tr = 'Dosya sadece görüntülenebilir. Dosya işlemleri <a href=""%1"">%2</a> bulut hizmetinde yürütülür.'"),
				SynchronizationInfo.FolderAddressInCloudService, SynchronizationInfo.AccountDescription1);
			Items.DecorationPictureSyncStatus.Visible = Not SynchronizationInfo.IsSynchronized;
			Items.DecorationSyncDate.Title = StringFunctions.FormattedString(
				NStr("vi = 'Đã đồng bộ: <a href=""%1"">%2</a>';
					|ru = 'Синхронизирован: <a href=""%1"">%2</a>';
					|en = 'Synchronized on: <a href=""%1"">%2</a>'; fa = 'Synchronized on: <a href=""%1"">%2</a>';
					|it = 'Синхронизирован: <a href=""%1"">%2</a>';
					|pl = 'Synchronized on: <a href=""%1"">%2</a>';
					|tr = 'Senkronize edildi: <a href=""%1"">%2</a>'"),
				"OpenJournal", Format(SynchronizationInfo.SynchronizationDate, "DLF=DD"));
			
		EndIf;
		
	EndIf;
	
	Items.CloudServiceNoteGroup.Visible = NoteVisibility;
	
EndProcedure

&AtServerNoContext
Function EventLogFilterData(Account)
	Return FilesOperationsInternal.EventLogFilterData(Account);
EndFunction

&AtClient
Procedure AfterSignatureAuthenticityJustificationEntered(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ModuleDigitalSignatureClientServer = CommonClient.CommonModule("DigitalSignatureClientServer");
	
	For Each ListLine In Items.DigitalSignatures.SelectedRows Do
		
		CurrentRow = DigitalSignatures.FindByID(ListLine);
		If CurrentRow.SignatureCorrect And CurrentRow.CheckResult.IsAdditionalAttributesCheckedManually <> True
			Or ValueIsFilled(CurrentRow.CheckResult.SignatureMathValidationError) Then
			Continue;
		EndIf;

		FillPropertyValues(CurrentRow, Result);
		FillPropertyValues(CurrentRow.CheckResult, Result);
		ModuleDigitalSignatureClientServer.FillSignatureStatus(CurrentRow, CommonClient.SessionDate());
		
	EndDo;
	
	DetermineIfModified();
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtServerNoContext
Procedure OnSendFilesViaEmail(SendOptions, Val FilesToSend, FilesOwner, UUID)
	SSLSubsystemsIntegration.OnSendFilesViaEmail(SendOptions, FilesToSend, FilesOwner, UUID);
	FilesOperationsOverridable.OnSendFilesViaEmail(SendOptions, FilesToSend, FilesOwner, UUID);
EndProcedure

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
