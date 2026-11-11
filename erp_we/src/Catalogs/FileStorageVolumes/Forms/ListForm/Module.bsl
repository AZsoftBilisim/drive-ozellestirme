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
	
	If Common.IsMobileClient() Then
		Items.ListComment.Visible = False;
		Items.ListMaximumSize.Visible = False;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	Items.CheckIntegrity.Visible = Not Common.SubsystemExists("StandardSubsystems.AttachableCommands")
		Or Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Or Not Common.SeparatedDataUsageAvailable();

	FilesStorageVolumeProcessedKind = Parameters.FilterValueByFilesStorageVolumeKind;
	If Not ValueIsFilled(FilesStorageVolumeProcessedKind) Then
		FilesStorageVolumeProcessedKind = Enums.StorageKinds.OperationalStorage;
		Parameters.Filter.Insert("StorageVolumeType", FilesStorageVolumeProcessedKind);
	EndIf;

	Items.MoveAllFilesToVolumes.Visible = FilesStorageVolumeProcessedKind = Enums.StorageKinds.OperationalStorage;

	Items.ListStorageVolumeType.Visible = Not ValueIsFilled(FilesStorageVolumeProcessedKind);
	
	Items.GroupBinaryDataStorageManagement.Visible = FileArchiveManagementServer.AreBinaryDataStoragesAvailable();
	
	If FileArchiveManagementServer.UseFileArchive() Then
		Title = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", Title, FilesStorageVolumeProcessedKind);
	EndIf

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetClearDeletionMark(Command)
	
	If Items.List.CurrentData = Undefined Then
		Return;
	EndIf;
	
	StartDeletionMarkChange(Items.List.CurrentData);
	
EndProcedure

&AtClient
Procedure MoveFiles(Command)
	
	FilesOperationsInternalClient.MoveFiles();
	
EndProcedure

&AtClient
Procedure CheckIntegrity(Command)
	
	CurrentData = Items.List.CurrentData;
	If Not StandardSubsystemsClient.IsDynamicListItem(CurrentData) Then
		Return;
	EndIf;
	
	If Not VolumeIntegrityCheckIsAvailable(CurrentData.Ref) Then
		Return;
	EndIf;
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", New Structure("Volume", CurrentData.Ref));
	
	OpenForm("Report.VolumeIntegrityCheck.ObjectForm", ReportParameters);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		If Command.Name = "SubmenuReportsNormal__VolumeIntegrityCheck" Then
			CurrentData = Items.List.CurrentData;
			If CurrentData <> Undefined And Not VolumeIntegrityCheckIsAvailable(CurrentData.Ref) Then
				Return;
			EndIf;			
		EndIf;
		
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	EndIf;
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ConfigureBinaryDataStorage(Command)

	OpenForm("DataProcessor.ManageBinaryDataStorage.Form.StoragesList", , ThisObject,,,,,FormWindowOpeningMode.LockWholeInterface);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartDeletionMarkChange(CurrentData)
	
	If CurrentData.DeletionMark Then
		QueryText = NStr("vi = 'Bỏ dấu xóa ""%1""?';
						|ru = 'Снять с ""%1"" пометку на удаление?';
						|en = 'Do you want to clear the deletion mark from ""%1""?'; fa = 'Do you want to clear the deletion mark from ""%1""?';
						|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
						|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
						|tr = '""%1"" için silme işareti kaldırılsın mı?'");
	Else
		QueryText = NStr("vi = 'Đặt dấu xóa ""%1""?';
						|ru = 'Пометить ""%1"" на удаление?';
						|en = 'Do you want to mark ""%1"" for deletion?'; fa = 'Do you want to mark ""%1"" for deletion?';
						|it = 'Contrassegnare ""%1"" per cancellazione?';
						|pl = 'Zaznaczyć ""%1"" do usunięcia?';
						|tr = '""%1"" silinmek üzere işaretlensin mi?'");
	EndIf;
	
	ShowQueryBox(New CallbackDescription("ContinueDeletionMarkChange", ThisObject, CurrentData),
		StringFunctionsClientServer.SubstituteParametersToString(QueryText, CurrentData.Description),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ContinueDeletionMarkChange(Response, CurrentData) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Volume = Items.List.CurrentData.Ref;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Volume", Items.List.CurrentData.Ref);
	AdditionalParameters.Insert("DeletionMark", Undefined);
	AdditionalParameters.Insert("Queries", New Array());
	AdditionalParameters.Insert("FormIdentifier", UUID);
	
	PrepareSetClearDeletionMark(Volume, AdditionalParameters);
	
	ContinuationNotification = New CallbackDescription(
		"ContinueSetClearDeletionMark", ThisObject, AdditionalParameters);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			AdditionalParameters.Queries, ThisObject, ContinuationNotification);
	Else
		RunCallback(ContinuationNotification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure PrepareSetClearDeletionMark(Volume, AdditionalParameters)
	
	LockDataForEdit(Volume, , AdditionalParameters.FormIdentifier);
	
	VolumeProperties = Common.ObjectAttributesValues(
		Volume, "DeletionMark,FullPathWindows,FullPathLinux");
	
	AdditionalParameters.DeletionMark = VolumeProperties.DeletionMark;
	
	If AdditionalParameters.DeletionMark Then
		// Clear the deletion mark as it's required.
		
		Query = Catalogs.FileStorageVolumes.RequestToUseExternalResourcesForVolume(
			Volume, VolumeProperties.FullPathWindows, VolumeProperties.FullPathLinux);
	Else
		// Set a deletion mark as it's required.
		If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
			Query = ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(Volume)
		EndIf;
	EndIf;
	
	AdditionalParameters.Queries.Add(Query);
	
EndProcedure

&AtClient
Procedure ContinueSetClearDeletionMark(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		EndSetClearDeletionMark(AdditionalParameters);
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure EndSetClearDeletionMark(AdditionalParameters)
	
	BeginTransaction();
	Try
	
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(Metadata.Catalogs.FileStorageVolumes.FullName());
		DataLockItem.SetValue("Ref", AdditionalParameters.Volume);
		DataLock.Lock();
		
		Object = AdditionalParameters.Volume.GetObject();
		Object.SetDeletionMark(Not AdditionalParameters.DeletionMark);
		Object.Write();
		
		UnlockDataForEdit(
		AdditionalParameters.Volume, AdditionalParameters.FormIdentifier);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServerNoContext
Function IsStorageVolumeOnDisks(Val StorageVolumeLink)

	Return Catalogs.FileStorageVolumes.IsStorageVolumeOnDisks(StorageVolumeLink);

EndFunction

&AtClient
Function VolumeIntegrityCheckIsAvailable(FileStorageVolumeLink)

	Result = IsStorageVolumeOnDisks(FileStorageVolumeLink);
	
	If Not Result Then
		ShowMessageBox(,NStr("ru = 'Проверка целостности предусмотрена только для томов со способом хранения ""В сетевых каталогах""';
							|vi = 'Integrity check is only supported for volumes that store files in network directories';
							|en = 'Integrity check is only supported for volumes that store files in network directories'; fa = 'Integrity check is only supported for volumes that store files in network directories';
							|it = 'Integrity check is only supported for volumes that store files in network directories';
							|pl = 'Integrity check is only supported for volumes that store files in network directories';
							|tr = 'Bütünlük kontrolü sadece saklama yöntemi ""Ağ dizinlerinde"" olan birimler için öngörülmüştür'"));
	EndIf;
	
	Return Result;

EndFunction

#EndRegion