///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var CurrentWriteParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AttachableCommands
		If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
			ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
			ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		Object.FillOrder = FindMaxOrder() + 1;

		DisplayingWarning = WarningOnEditRepresentation.DontShow;
		Items.FilesStorageMethod.WarningOnEditRepresentation		= DisplayingWarning;
		Items.BinaryDataStorageName.WarningOnEditRepresentation	= DisplayingWarning;
	Else
		
		Items.FullPathLinux.WarningOnEditRepresentation
			= WarningOnEditRepresentation.Show;
		
		Items.FullPathWindows.WarningOnEditRepresentation
			= WarningOnEditRepresentation.Show;
		
		CurrentSizeInBytes = FilesOperationsInVolumesInternal.VolumeSize(Object.Ref);
			
		ActualSize = CurrentSizeInBytes / (1024 * 1024);
		If ActualSize = 0 And CurrentSizeInBytes <> 0 Then
			ActualSize = 1;
		EndIf;
		
	EndIf;
	
	If Common.IsWindowsServer() Then 
		
		Items.FullPathWindows.AutoMarkIncomplete = True;
	Else
		Items.FullPathLinux.AutoMarkIncomplete = True;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.Description.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	Items.FormCheckVolumeIntegrity.Visible = Not Common.SubsystemExists("StandardSubsystems.AttachableCommands")

		Or Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Or Not Common.SeparatedDataUsageAvailable();

	FileArchiveManagementServer.FilesStorageMethodFillChoiceList(Items.FilesStorageMethod.ChoiceList, Object.StorageVolumeType);
	FillBinaryDataStorageNamesChoiceList(Items.BinaryDataStorageName.ChoiceList);
	RefreshVisibilityAtServer();
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseNotification", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not WriteParameters.Property("ExternalResourcesAllowed") Then
		Cancel = True;
		CurrentWriteParameters = WriteParameters;
		AttachIdleHandler("AllowExternalResourceBeginning", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(RefToNew) And CurrentObject.IsNew() Then
		CurrentObject.SetNewObjectRef(RefToNew);
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
	
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	RefreshFormTitle();

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CurrentObject = FormAttributeToValue("Object");
	
	If FillCheckAlreadyExecuted Then
		FillCheckAlreadyExecuted = False;
		CurrentObject.AdditionalProperties.Insert("SkipBasicFillingCheck");
	Else
		CurrentObject.AdditionalProperties.Insert("SkipDirectoryAccessCheck");
	EndIf;
	
	CheckedAttributes.Clear();
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FullPathWindowsOnChange(Item)
	
	// Delete extra spaces and add a slash at the end (unless it is already there).
	If Not IsBlankString(Object.FullPathWindows) Then
		
		If StrStartsWith(Object.FullPathWindows, " ") Or StrEndsWith(Object.FullPathWindows, " ") Then
			Object.FullPathWindows = TrimAll(Object.FullPathWindows);
		EndIf;
		
		If Not StrEndsWith(Object.FullPathWindows, "\") Then
			Object.FullPathWindows = Object.FullPathWindows + "\";
		EndIf;
		
		If StrEndsWith(Object.FullPathWindows, "\\") Then
			Object.FullPathWindows = Left(Object.FullPathWindows, StrLen(Object.FullPathWindows) - 1);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FullPathLinuxOnChange(Item)
	
	// Delete extra spaces and add a slash at the end (unless it is already there).
	If Not IsBlankString(Object.FullPathLinux) Then
		
		If StrStartsWith(Object.FullPathLinux, " ") Or StrEndsWith(Object.FullPathLinux, " ") Then
			Object.FullPathLinux = TrimAll(Object.FullPathLinux);
		EndIf;
		
		If Not StrEndsWith(Object.FullPathLinux, "/") Then
			Object.FullPathLinux = Object.FullPathLinux + "/";
		EndIf;
		
		If StrEndsWith(Object.FullPathLinux, "//") Then
			Object.FullPathLinux = Left(Object.FullPathLinux, StrLen(Object.FullPathLinux) - 1);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilesStorageMethodOnChange(Item)

	AttributesVisibilityByFilesStorageMethod = GetAttributesVisibilityByFilesStorageMethod(Object.FilesStorageMethod);
	FileArchiveManagementClientServer.RefreshFilesStorageVolumeAttributesVisibility(ThisObject, AttributesVisibilityByFilesStorageMethod);

EndProcedure
#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

&AtClient
Procedure CheckVolumeIntegrity(Command)

	If Not IsStorageVolumeOnDisks(Object.Ref) Then
		ShowMessageBox(,NStr("ru = 'Проверка целостности предусмотрена только для томов со способом хранения ""В сетевых каталогах""';
							|vi = 'Integrity check is only supported for volumes that store files in network directories';
							|en = 'Integrity check is only supported for volumes that store files in network directories'; fa = 'Integrity check is only supported for volumes that store files in network directories';
							|it = 'Integrity check is only supported for volumes that store files in network directories';
							|pl = 'Integrity check is only supported for volumes that store files in network directories';
							|tr = 'Bütünlük kontrolü sadece saklama yöntemi ""Ağ dizinlerinde"" olan birimler için öngörülmüştür'"));
		Return;
	EndIf;	

	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
			QueryText = NStr("vi = 'Để thực hiện kiểm tra tính toàn vẹn, hãy ghi lại thông tin về quyển.
					|Ghi lại?';
					|ru = 'Для выполнения проверки целостности запишите сведения о томе.
					|Записать?';
					|en = 'To proceed with the integrity check, save the volume data.
					|Do you want to save the data?'; fa = 'To proceed with the integrity check, save the volume data.
					|Do you want to save the data?';
					|it = 'Per eseguire un controllo di integrità, registrare le informazioni sul volume.
					|Registrarle?';
					|pl = 'Dla weryfikacji integralności zapisz informacje o woluminie.
					|Zapisać?';
					|tr = 'Bütünlük denetimi yapmak için birim bilgilerini not edin.
					|Kayıt?'");
			Notification = New CallbackDescription("WriteFormRequiredToCheckVolumeIntegrity", ThisObject);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	Else
		RunVolumeIntegrityCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteUnnecessaryFiles(Command)

	If Not IsStorageVolumeOnDisks(Object.Ref) Then
		ShowMessageBox(,NStr("ru = 'Удаление лишних файлов предусмотрено только для томов со способом хранения ""В сетевых каталогах""';
							|vi = 'File clean-up is only supported for volumes that store files in network directories';
							|en = 'File clean-up is only supported for volumes that store files in network directories'; fa = 'File clean-up is only supported for volumes that store files in network directories';
							|it = 'File clean-up is only supported for volumes that store files in network directories';
							|pl = 'File clean-up is only supported for volumes that store files in network directories';
							|tr = 'Gereksiz dosyaların silinmesi sadece saklama yöntemi ""Ağ dizinlerinde"" olan birimler için öngörülmüştür'"));
		Return;
	EndIf;	

	OpeningParameters = New Structure("FileStorageVolume", Object.Ref);
	OpenForm("Catalog.FileStorageVolumes.Form.DeleteUnnecessaryFilesFromVolume", OpeningParameters, ThisObject);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
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
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Procedure WriteFormRequiredToCheckVolumeIntegrity(Write, AdditionalParameters) Export
	
	If Write = DialogReturnCode.Yes Then
		WriteAtServer();
		RunVolumeIntegrityCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure RunVolumeIntegrityCheck()
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", New Structure("Volume", Object.Ref));
	
	OpenForm("Report.VolumeIntegrityCheck.ObjectForm", ReportParameters);

EndProcedure

&AtClient
Procedure WriteAndCloseNotification(Result, Context) Export
	
	Write(New Structure("WriteAndClose"));
	
EndProcedure

// Finds maximum order among the volumes.
&AtServer
Function FindMaxOrder()

	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Volumes.FillOrder) AS MaxNumber
	|FROM
	|	Catalog.FileStorageVolumes AS Volumes
	|WHERE
	|	Volumes.StorageVolumeType = &StorageVolumeType";

	Query.SetParameter("StorageVolumeType", Object.StorageVolumeType);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If Selection.MaxNumber = Null Then
			Return 0;
		Else
			Return Number(Selection.MaxNumber);
		EndIf;
	EndIf;

	Return 0;

EndFunction

&AtClient
Procedure AllowExternalResourceBeginning()
	
	ClosingNotification1 = New CallbackDescription(
		"AllowExternalResourceCompletion", ThisObject, CurrentWriteParameters);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		ExternalResourceQueries = New Array;
		If Not CheckFillingAtServer(ExternalResourceQueries) Then
			Return;
		EndIf;
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(ExternalResourceQueries, ThisObject, ClosingNotification1);
		
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtServer
Function CheckFillingAtServer(ExternalResourceQueries)
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	FillCheckAlreadyExecuted = True;
	
	If ValueIsFilled(Object.Ref) Then
		ObjectReference = Object.Ref;
	Else
		If Not ValueIsFilled(RefToNew) Then
			RefToNew = Catalogs.FileStorageVolumes.GetRef();
		EndIf;
		ObjectReference = RefToNew;
	EndIf;
	
	ExternalResourceQueries.Add(
		Catalogs.FileStorageVolumes.RequestToUseExternalResourcesForVolume(
			ObjectReference, Object.FullPathWindows, Object.FullPathLinux));
	
	Return True;
	
EndFunction

&AtClient
Procedure AllowExternalResourceCompletion(Result, WriteParameters) Export
	
	If Result = DialogReturnCode.OK Then
		WriteParameters.Insert("ExternalResourcesAllowed");
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteAtServer()
	Write();
EndProcedure

&AtServer
Procedure RefreshVisibilityAtServer()

	FilesStorageMethodGroupVisibility = FileArchiveManagementServer.AreBinaryDataStoragesAvailable();

	Items.FilesStorageMethodGroup.Visible = FilesStorageMethodGroupVisibility;

	If FilesStorageMethodGroupVisibility Then

		AttributesVisibilityByFilesStorageMethod = GetAttributesVisibilityByFilesStorageMethod(Object.FilesStorageMethod);

		FileArchiveManagementClientServer.RefreshFilesStorageVolumeAttributesVisibility(ThisObject, AttributesVisibilityByFilesStorageMethod);

	EndIf;

EndProcedure

&AtServerNoContext
Function GetAttributesVisibilityByFilesStorageMethod(Val FilesStorageMethod)

	DirectoriesVisibility		= FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories;
	StorageNameVisibility	= Not DirectoriesVisibility And FilesStorageMethod = Enums.FileStorageOption.S3ExternalStorage;

	Result = FileArchiveManagementClientServer.AttributesVisibilityParametersByFilesStorageMethod();
	Result.VisibilityPathGroup					= DirectoriesVisibility;
	Result.VisibilityBinaryDataStorageName	= StorageNameVisibility;

	Return Result;

EndFunction

&AtServerNoContext
Procedure FillBinaryDataStorageNamesChoiceList(ChoiceList)

	For Each ExternalBDSManager In BinaryDataExternalStorages Do
		ChoiceList.Add(ExternalBDSManager.Name);
	EndDo;

EndProcedure 

&AtServerNoContext
Function IsStorageVolumeOnDisks(Val StorageVolumeLink)

	Return Catalogs.FileStorageVolumes.IsStorageVolumeOnDisks(StorageVolumeLink);

EndFunction

&AtServer
Procedure RefreshFormTitle()

	If Not ValueIsFilled(Object.Ref) Then
		If FileArchiveManagementServer.UseFileArchive() Then
			AutoTitle = False;
			ObjectPresentation = Object.Ref.Metadata().ObjectPresentation;

			Title = NStr(StringFunctionsClientServer.SubstituteParametersToString("ru = '%1 (%2) (Создание)';
																					|vi = '%1 (%2) (Create)';
																					|en = '%1 (%2) (Create)';
																					|it = '%1 (%2) (Create)';
																					|pl = '%1 (%2) (Create)';
																					|tr = '%1(%2)(Oluşturma)'", ObjectPresentation, Object.StorageVolumeType));
		EndIf;
	ElsIf Not AutoTitle Then

		Title		= "";
		AutoTitle	= True;

	EndIf;

EndProcedure

#EndRegion
