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
Var CurrentContext;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	If DataSeparationEnabled Then
		Items.InformationDetails.Title = NStr("vi = 'Người quản trị ứng dụng tùy chỉnh thành phần sửa lỗi.';
												|ru = 'Состав исправлений настраивается администратором приложения.';
												|en = 'Patches are configured by the application administrator.'; fa = 'Patches are configured by the application administrator.';
												|it = 'Composizione delle correzione è configurata dall''amministratore dell''applicazione.';
												|pl = 'Zestaw korekt jest ustawiany przez administratora aplikacji.';
												|tr = 'Düzeltmelerin bileşimi, uygulama yöneticisi tarafından ayarlanır.'");
	ElsIf Parameters.OnUpdate Then
		Items.InformationDetails.Title = NStr("vi = 'Các bản sửa lỗi đã cài đặt sẽ có hiệu lực sau khi khởi động lại ứng dụng.';
												|ru = 'Установленные исправления вступят в силу после перезапуска приложения.';
												|en = 'Installed patches will be applied after the application restart.'; fa = 'Installed patches will be applied after the application restart.';
												|it = 'Установленные исправления вступят в силу после перезапуска приложения.';
												|pl = 'Installed patches will be applied after the application restart.';
												|tr = 'Kurulu düzeltmeler, uygulama yeniden başlatıldıktan sonra geçerli olacaktır.'");
	ElsIf Not Common.IsWindowsClient() Then
		Items.InformationPages.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.Corrections) Then
		If TypeOf(Parameters.Corrections) = Type("ValueList") Then
			Filter = Parameters.Corrections;
		ElsIf TypeOf(Parameters.Corrections) = Type("Array") Then
			Filter.LoadValues(Parameters.Corrections);
		EndIf;
	EndIf;
	
	OnUpdate = Parameters.OnUpdate;
	Items.InstalledPatchesClose.Visible = OnUpdate;
	
	If DataSeparationEnabled
		Or Not Common.IsWindowsClient()
		Or Parameters.OnUpdate Then
		Items.FormInstallPatch.Visible = False;
		Items.FormDeletePatch.Visible    = False;
		Items.InstalledPatchesExportAttachedPatches.Visible = False;
		Items.InstalledPatchesContextMenuAdd.Visible = False;
		Items.InstalledPatchesContextMenuDelete.Visible  = False;
		Items.InstalledPatchesAttach.Visible = False;
	EndIf;
	
	RefreshPatchesList();
	
	Items.InstalledPatchesApplicableTo.Visible = False;
	
	IsWebClient = Common.IsWebClient() Or Common.ClientConnectedOverWebServer();
	Items.FindAndInstallUpdates.Visible = Not IsWebClient
		And Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationEventLogClick(Item)
	EventsArray = New Array;
	EventsArray.Add(NStr("vi = 'Sửa lỗi.Cài đặt';
						|ru = 'Исправления.Установка';
						|en = 'Patch.Install'; fa = 'Patch.Install';
						|it = 'Rettifiche.Installazione';
						|pl = 'Patch.Install';
						|tr = 'Düzeltmeler.Kurulum'"));
	EventsArray.Add(NStr("vi = 'Sửa lỗi.Thay đổi';
						|ru = 'Исправления.Изменение';
						|en = 'Patch.Modify'; fa = 'Patch.Modify';
						|it = 'Correzioni.Modifica';
						|pl = 'Patch.Modify';
						|tr = 'Düzeltme.Değişiklik'"));
	EventsArray.Add(NStr("vi = 'Sửa lỗi.Xóa';
						|ru = 'Исправления.Удаление';
						|en = 'Patch.Delete'; fa = 'Patch.Delete';
						|it = 'Correzioni.Rimozione';
						|pl = 'Patch.Delete';
						|tr = 'Düzeltmeler.Silme'"));
	SelectionOfLogEvents = New Structure("EventLogEvent", EventsArray);
	EventLogClient.OpenEventLog(SelectionOfLogEvents);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInstalledPatches

&AtClient
Procedure InstalledPatchesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	If Not DataSeparationEnabled Then
		DeleteExtensions(Item.SelectedRows);
	EndIf;
EndProcedure

&AtClient
Procedure InstalledPatchesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
	If Not DataSeparationEnabled Then
		Notification = New CallbackDescription("AfterInstallUpdates", ThisObject);
		OpenForm("DataProcessor.InstallUpdates.Form",,,,,, Notification);
	EndIf;
EndProcedure

&AtClient
Procedure InstalledPatchesAttachOnChange(Item)
	CurrentData = Items.InstalledPatches.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("RowID", CurrentData.GetID());
	
	ShowTimeConsumingOperation();
	AttachIdleHandler("InstalledPatchesAttachOnChangeCompletion", 0.1, True);
EndProcedure

&AtClient
Procedure InstalledPatchesAttachOnChangeCompletion()
	
	Try
		AttachInstalledPatchesOnChangeAtServer(Context.RowID);
	Except
		ErrorInfo = ErrorInfo();
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	HideTimeConsumingOperation();
	
EndProcedure

&AtServer
Procedure AttachInstalledPatchesOnChangeAtServer(RowID)
	
	ListLine = InstalledPatches.FindByID(RowID);
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	CurrentUsage = ListLine.Attach;
	Try
		Catalogs.ExtensionsVersions.ToggleExtensionUsage(ListLine.ExtensionID, CurrentUsage);
	Except
		ListLine.Attach = Not ListLine.Attach;
		RefreshPatchesList();
		
		Raise;
	EndTry;
	
	RefreshPatchesList();
	
EndProcedure

&AtClient
Procedure ShowTimeConsumingOperation()
	
	Items.InformationPages.CurrentPage= Items.TimeConsumingOperationPage;
	ReadOnly = True;
	
EndProcedure

&AtClient
Procedure HideTimeConsumingOperation()
	
	Items.InformationPages.CurrentPage = Items.InformationPage;
	ReadOnly = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveAs(Command)
	SavePatches();
EndProcedure

&AtClient
Procedure ExportAttachedPatches(Command)
	SavePatches(True);
EndProcedure

&AtClient
Procedure FindAndInstallUpdates(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.UpdateProgram();
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RefreshPatchesList()
	
	InstalledPatches.Clear();
	Items.InstalledPatchesPathToFile.Visible = False;
	
	SetPrivilegedMode(True);
	Extensions = ConfigurationExtensions.Get();
	SetPrivilegedMode(False);
	
	PatchesDetails = DescriptionOfInstalledFixes();
	
	For Each Extension In Extensions Do
		
		If Not ConfigurationUpdate.IsPatch(Extension) Then
			Continue;
		EndIf;
		
		If Filter.Count() <> 0 And Filter.FindByValue(Extension.Name) = Undefined Then
			Continue;
		EndIf;
		
		PatchProperties = ConfigurationUpdate.PatchProperties(Extension.Name);
		
		Patch = InstalledPatches.Add();
		Patch.Name = Extension.Name;
		Patch.Checksum = Base64String(Extension.HashSum);
		Patch.ExtensionID = Extension.UUID;
		Patch.Attach = Extension.Active;
		Patch.Version = Extension.Version;
		If PatchProperties = "ReadingError" Then
			Patch.Status = 0;
		ElsIf PatchProperties <> Undefined Then
			Patch.Status = 0;
			Patch.LongDesc = PatchProperties.Description;
			Patch.ApplicableTo = ApplicabilityForConfigurations(PatchProperties);
		Else
			LongDesc = PatchesDetails[Extension.Name];
			Patch.Status = 1;
			Patch.LongDesc = LongDesc;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function DescriptionOfInstalledFixes()
	
	If Not OnUpdate Then
		Return New Map;
	EndIf;
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	MethodParameters = New Array;
	MethodParameters.Add(StorageAddress);
	MethodParameters.Add(Filter.UnloadValues());
	MethodParameters.Add(True);
	BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
		"ConfigurationUpdate.NewPatchesDetails1",
		MethodParameters);
	BackgroundJob.WaitForExecutionCompletion(Undefined);
	
	NewPatchesDetails = GetFromTempStorage(StorageAddress);
	If TypeOf(NewPatchesDetails) <> Type("Map") Then
		NewPatchesDetails = New Map;
	EndIf;
	
	Return NewPatchesDetails;
	
EndFunction

&AtServer
Function ApplicabilityForConfigurations(PatchProperties)
	
	ConfigurationsNames = New Array;
	For Each ConfigurationName In PatchProperties.AppliedFor Do
		ConfigurationsNames.Add(ConfigurationName.ConfigurationName);
	EndDo;
	
	Return StrConcat(ConfigurationsNames, Chars.LF);
	
EndFunction

&AtClient
Procedure DeleteExtensions(SelectedRows)
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ExtensionsIDs = New Array;
	For Each RowID In SelectedRows Do
		PatchString = InstalledPatches.FindByID(RowID);
		ExtensionsIDs.Add(PatchString.ExtensionID);
	EndDo;
	
	Context = New Structure;
	Context.Insert("ExtensionsIDs", ExtensionsIDs);
	
	Notification = New CallbackDescription("DeleteExtensionAfterConfirmation", ThisObject, Context);
	If ExtensionsIDs.Count() > 1 Then
		QueryText = NStr("vi = 'Xóa các bản sửa lỗi đã chọn?';
						|ru = 'Удалить выделенные исправления?';
						|en = 'Do you want to delete the selected patches?'; fa = 'Do you want to delete the selected patches?';
						|it = 'Cancellare le correzioni evidenziate?';
						|pl = 'Usunąć zaznaczone korekty?';
						|tr = 'Seçili düzeltmeler silinsin mi?'");
	Else
		QueryText = NStr("vi = 'Xóa bản sửa lỗi?';
						|ru = 'Удалить исправление?';
						|en = 'Do you want to delete the patch?'; fa = 'Do you want to delete the patch?';
						|it = 'Cancellare la correzione';
						|pl = 'Usun poprawkę?';
						|tr = 'Düzeltmeleri sil?'");
	EndIf;
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DeleteExtensionAfterConfirmation(Result, Context) Export
	
	If Result = DialogReturnCode.Yes Then
		
		Handler = New CallbackDescription("DeleteExtensionFollowUp", ThisObject, Context);
		
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			Queries = RequestsToRevokeExternalModuleUsagePermissions(Context.ExtensionsIDs);
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, Handler);
		Else
			RunCallback(Handler, DialogReturnCode.OK);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExtensionFollowUp(Result, Context) Export
	
	If Result = DialogReturnCode.OK Then
		CurrentContext = Context;
		AttachIdleHandler("DeleteExtensionCompletion", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExtensionCompletion()
	
	Context = CurrentContext;
	
	Try
		DeleteExtensionsAtServer(Context.ExtensionsIDs);
	Except
		ErrorInfo = ErrorInfo();
		StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	EndTry;
	
EndProcedure

&AtServer
Procedure DeleteExtensionsAtServer(ExtensionsIDs)
	
	ErrorText = "";
	Catalogs.ExtensionsVersions.DeleteExtensions(ExtensionsIDs, ErrorText);
	
	RefreshPatchesList();
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

&AtServer
Function RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs)
	
	Return Catalogs.ExtensionsVersions.RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs);
	
EndFunction

&AtClient
Procedure AfterInstallUpdates(Result, AdditionalParameters) Export
	RefreshPatchesList();
EndProcedure

&AtClient
Procedure SaveAsCompletion(PathToDirectory, SelectedRows) Export
	
	FilesToSave = SaveAtServer(SelectedRows, PathToDirectory);
	
	If FilesToSave.Count() = 0 Then
		Return;
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Interactively     = False;
	
	FileSystemClient.SaveFiles(Undefined, FilesToSave, SavingParameters);
	
EndProcedure

&AtClient
Procedure SavePatches(OnlyAttachedOnes = False)
	
	If OnlyAttachedOnes Then
		SelectedRows = AttachedPatchesIDs();
	Else
		SelectedRows = Items.InstalledPatches.SelectedRows;
	EndIf;
	
	CallbackDescription = New CallbackDescription("SaveAsCompletion", ThisObject, SelectedRows);
	
	If SelectedRows.Count() = 0 Then
		If OnlyAttachedOnes Then
			ShowMessageBox(, NStr("vi = 'Không có bản vá được kết nối.';
									|ru = 'Нет подключенных исправлений.';
									|en = 'No attached patches.'; fa = 'No attached patches.';
									|it = 'Нет подключенных исправлений.';
									|pl = 'No attached patches.';
									|tr = 'Bağlı olmayan yama.'"));
		EndIf;
		Return;
	ElsIf Not OnlyAttachedOnes And SelectedRows.Count() = 1 Then
		FilesToSave = SaveAtServer(SelectedRows);
	Else
		Title = NStr("vi = 'Chọn thư mục để lưu các bản vá cấu hình';
					|ru = 'Выберите каталог для сохранения исправлений конфигурации';
					|en = 'Choose a directory to save the patch'; fa = 'Choose a directory to save the patch';
					|it = 'Selezionate un catalogo per il salvataggio delle rettifiche di configurazione.';
					|pl = 'Wybierz katalog do zapisu korekt konfiguracji';
					|tr = 'Yapılandırmada düzeltmeleri kaydetmek için bir katalog seçin'");
		FileSystemClient.SelectDirectory(CallbackDescription, Title);
		Return;
	EndIf;
	
	If FilesToSave.Count() = 0 Then
		Return;
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("vi = 'Chọn tệp để lưu các bản vá cấu hình';
										|ru = 'Выберите файл для сохранения исправления конфигурации';
										|en = 'Choose a file to save the patch'; fa = 'Choose a file to save the patch';
										|it = 'Selezionate un file per il salvataggio della rettifica di configurazione';
										|pl = 'Wybierz plik do zapisywania korekt konfiguracji';
										|tr = 'Yapılandırmada düzeltmeleri kaydetmek için bir dosya seçin'");
	SavingParameters.Dialog.Filter    = NStr("vi = 'Tệp vá cấu hình (*.cfe)|*.cfe ';
											|ru = 'Файлы исправлений конфигурации (*.cfe)|*.cfe';
											|en = '1C:Enterprise patch files (*.cfe)|*.cfe'; fa = '1C:Enterprise patch files (*.cfe)|*.cfe';
											|it = 'Файлы исправлений конфигурации (*.cfe)|*.cfe';
											|pl = '1C:Enterprise patch files (*.cfe)|*.cfe';
											|tr = 'Konfigürasyon yaması dosyaları (*.cfe)|*.cfe'") + "|" 
		+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																		|ru = 'Все файлы (%1)|%1';
																		|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																		|it = 'Все файлы (%1)|%1';
																		|pl = 'All files (%1)|%1';
																		|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	
	FileSystemClient.SaveFiles(Undefined, FilesToSave, SavingParameters);
	
EndProcedure 

&AtClient
Function AttachedPatchesIDs()
	
	ConnectedNow = New Array;
	For Each Patch In InstalledPatches Do
		If Not Patch.Attach Then
			Continue;
		EndIf;
		
		ConnectedNow.Add(Patch.GetID());
	EndDo;
	
	Return ConnectedNow;
EndFunction

&AtServer
Function SaveAtServer(RowsIDs, PathToDirectory = "")
	
	FilesToSave = New Array;
	For Each RowID In RowsIDs Do
		ListLine = InstalledPatches.FindByID(RowID);
		ExtensionID = ListLine.ExtensionID;
		Extension = FindExtension(ExtensionID);
	
		If Extension <> Undefined Then
			If ValueIsFilled(PathToDirectory) Then
				Prefix = PathToDirectory + GetPathSeparator();
			Else
				Prefix = "";
			EndIf;
			Name = Prefix + Extension.Name + "_" + Extension.Version + ".cfe";
			Location = PutToTempStorage(Extension.GetData(), UUID);
			TransferableFileDescription = New TransferableFileDescription(Name, Location);
			FilesToSave.Add(TransferableFileDescription);
		EndIf;
	EndDo;
	
	Return FilesToSave;
	
EndFunction

&AtServerNoContext
Function FindExtension(ExtensionID)
	
	Return Catalogs.ExtensionsVersions.FindExtension(ExtensionID);
	
EndFunction

#EndRegion