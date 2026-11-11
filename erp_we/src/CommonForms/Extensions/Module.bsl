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
	
	SetConditionalAppearance();
	
	URL = "e1cib/app/CommonForm.Extensions";
	
	If Not AccessRight("Administration", Metadata) Then
		Items.ExtensionsListSafeModeFlag.ReadOnly = True;
	EndIf;
	
	Items.FormInstalledPatches.Visible = 
		Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate");
	
	If Not AccessRight("ConfigurationExtensionsAdministration", Metadata) Then
		Items.ExtensionsListUpdate.LocationInCommandBar = ButtonLocationInCommandBar.InCommandBar;
		Items.ExtensionsList.ReadOnly = True;
		Items.ExtensionsListAdd.Visible = False;
		Items.ExtensionsListDelete.Visible = False;
		Items.ExtensionsListUpdateFromFile.Visible = False;
		Items.ExtensionsListSaveAs.Visible = False;
		Items.ExtensionsListContextMenuAdd.Visible = False;
		Items.ExtensionsListContextMenuDelete.Visible = False;
		Items.ExtensionsListContextMenuUpdateFromFile.Visible = False;
		Items.ExtensionsListContextMenuSaveAs.Visible = False;
		Items.FormInstalledPatches.Visible = False;
		Items.CheckIfAllExtensionsCanBeApplied.Visible = False;
		Items.SubmenuEnableExtensions.Visible = False;
		Items.SubmenuTransferToSubordinateDIBNodes.Visible = False;
		Items.SubmenuSafeMode.Visible = False;
		Items.SetEmployeeResponsible.Visible = False;
		Items.ExtensionsListEmployeeResponsible.Visible = False;
		Items.ExtensionsListHasComment.Visible = False;
		Items.ExtensionsListComment.Visible = False;
	EndIf;
	
	Items.ExtensionsListCommon.Visible = Common.DataSeparationEnabled() And AccessRight("Administration", Metadata);
	Items.ExtensionsListReceivedFromMasterDIBNode.Visible = Common.IsSubordinateDIBNode();
	Items.ExtensionsListPassToSubordinateDIBNodes.Visible = Common.IsDistributedInfobase();
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetCommandBarButtonAvailability()
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "LoggedOffFromDataArea" 
		Or EventName = "LoggedOnToDataArea" Then
		
		AttachIdleHandler("UpdateListIdleHandler", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarningDetailsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	Exit(False, True);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExtensionsList

&AtClient
Procedure ExtensionsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name="ExtensionsListHasComment" Then
		CurrentItem = Items.ExtensionsListComment;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtensionsListOnActivateRow(Item)
	
	SetCommandBarButtonAvailability();
	
EndProcedure

&AtClient
Procedure ExtensionsListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	LoadExtension(Undefined, True);
	
EndProcedure

&AtClient
Procedure ExtensionsListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	DeleteExtensions(Item.SelectedRows);
	
EndProcedure

&AtClient
Procedure ExtensionsListSafeModeFlagOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("RowID", CurrentExtension.GetID());
	
	ShowTimeConsumingOperation();
	CurrentContext = Context;
	AttachIdleHandler("ExtensionsListSafeModeFlagOnChangeCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure ExtensionsListAttachOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("RowID", CurrentExtension.GetID());
	
	If Not CurrentExtension.Attach
	   And IsExtensionWithData(CurrentExtension.ExtensionID) Then
		
		Notification = New CallbackDescription("DetachExtensionAfterConfirmation", ThisObject, Context);
		UsersInternalClient.ShowSecurityWarning(Notification,
			UsersInternalClientServer.SecurityWarningKinds().BeforeDisableExtensionWithData);
	Else
		ExtensionsListAttachOnChangeContinued(Context);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtensionsListPassToSubordinateDIBNodesOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	ExtensionsListSendToSubordinateDIBNodesOnChangeAtServer(CurrentExtension.GetID());
	
EndProcedure

&AtClient
Procedure ExtensionsListEmployeeResponsibleOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	SaveExtensionsProperties(CurrentExtension.ExtensionID, ExtensionProperties(CurrentExtension));
	
EndProcedure

&AtClient
Procedure ExtensionsListCommentOnChange(Item)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	CurrentExtension.HasComment = ValueIsFilled(CurrentExtension.Comment);
	SaveExtensionsProperties(CurrentExtension.ExtensionID, ExtensionProperties(CurrentExtension));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	SelectedRows = Items.ExtensionsList.SelectedRows;
	CallbackDescription = New CallbackDescription("SaveAsCompletion", ThisObject, SelectedRows);
	
	If SelectedRows.Count() = 0 Then
		Return;
	ElsIf SelectedRows.Count() = 1 Then
		FilesToSave = SaveAtServer(SelectedRows);
	Else
		Title = NStr("vi = 'Chọn thư mục để lưu phần mở rộng cấu hình';
					|ru = 'Выберите каталог для сохранения расширений конфигурации';
					|en = 'Select directory'; fa = 'Select directory';
					|it = 'Selezionate un catalogo per il salvataggio delle estensioni di configurazione';
					|pl = 'Wybierz katalog do zapisu rozszerzeń konfiguracji';
					|tr = 'Yapılandırma uzantılarını kaydetmek için katalog seçin'");
		FileSystemClient.SelectDirectory(CallbackDescription, Title);
		Return;
	EndIf;
	
	If FilesToSave.Count() = 0 Then
		Return;
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp để lưu phần mở rộng cấu hình';
										|ru = 'Выберите файл для сохранения расширения конфигурации';
										|en = 'Select file'; fa = 'انتخاب فایل';
										|it = 'Scegliete un file per il salvataggio dell''estensione della configurazione';
										|pl = 'Wybierz plik do zapisu rozszerzenia konfiguracji';
										|tr = 'Yapılandırmanın kaydedileceği dosyayı seçin'");
	SavingParameters.Dialog.Filter    = NStr("vi = 'Tệp phần mở rộng cấu hình (*.cfe)|*.cfe ';
											|ru = 'Файлы расширений конфигурации (*.cfe)|*.cfe';
											|en = 'Configuration extension files (*.cfe)|*.cfe'; fa = 'Configuration extension files (*.cfe)|*.cfe';
											|it = 'Файлы расширений конфигурации (*.cfe)|*.cfe';
											|pl = 'Configuration extension files (*.cfe)|*.cfe';
											|tr = 'Konfigürasyon uzantısı dosyaları (*.cfe)|*.cfe'") + "|"
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	
	FileSystemClient.SaveFiles(Undefined, FilesToSave, SavingParameters);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	CurrentExtension = Items.ExtensionsList.CurrentData;
	
	If CurrentExtension = Undefined Then
		Return;
	EndIf;
	
	LoadExtension(Items.ExtensionsList.SelectedRows);
	
EndProcedure

&AtClient
Procedure ShowEventsBackgroundUpdateSettingsExtensionsJob(Command)
	
	EventFilter = New Structure;
	EventFilter.Insert("EventLogEvent", ParameterFillingEventName());
	
	EventLogClient.OpenEventLog(EventFilter, ThisObject);
	
EndProcedure

&AtClient
Procedure RunUpdateSettingsExtensionsWorkInBackground(Command)
	
	WarningText = "";
	RunUpdateSettingsExtensionsWorkInBackgroundOnServer(WarningText);
	
	ShowMessageBox(, WarningText);
	
EndProcedure

&AtClient
Procedure DeleteObsoleteParametersWorkExtensions(Command)
	
	DeleteDeprecatedSettingsExtensionsWorkOnServer();
	ShowMessageBox(, NStr("vi = 'Đã xóa phiên bản cũ trong tham số làm việc của phần mở rộng.';
							|ru = 'Выполнено удаление устаревших версий параметров работы расширений.';
							|en = 'Obsolete versions of extension parameters are deleted.'; fa = 'Obsolete versions of extension parameters are deleted.';
							|it = 'Rimosse le versioni obsolete dei parametri operativi delle estensioni.';
							|pl = 'Usunięto przestarzałe wersje parametrów działania rozszerzeń.';
							|tr = 'Uzantı ayarları eski sürümleri kaldırıldı.'"));
	
EndProcedure

&AtClient
Procedure InstalledPatches(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.ShowInstalledPatches();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckIfAllExtensionsCanBeApplied(Command)
	
	Result = ResultOfAllExtensionsApplicabilityCheck();
	
	If Result.IssuesCount = 0 Then
		QuestionFormParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionFormParameters.Picture = PictureLib.DialogInformation;
		QuestionFormParameters.PromptDontAskAgain = False;
		QuestionFormParameters.Title = NStr("vi = 'Kết quả kiểm tra khả năng áp dụng tất cả phần mở rộng';
											|ru = 'Результат проверки возможности применения всех расширений';
											|en = 'Result of extensions applicability check'; fa = 'Result of extensions applicability check';
											|it = 'Результат проверки возможности применения всех расширений';
											|pl = 'Result of extensions applicability check';
											|tr = 'Tüm uzantıları kullanma olasılığını kontrol etmenin sonucu'");
		StandardSubsystemsClient.ShowQuestionToUser(Undefined,
			NStr("vi = 'Đã xác minh thành công tất cả phần mở rộng.';
				|ru = 'Проверка возможности применения всех расширений пройдена успешно.';
				|en = 'The extensions applicability check is passed.'; fa = 'The extensions applicability check is passed.';
				|it = 'Проверка возможности применения всех расширений пройдена успешно.';
				|pl = 'The extensions applicability check is passed.';
				|tr = 'Tüm uzantıların kullanımı başarıyla doğrulandı.'"),
			QuestionDialogMode.OK,
			QuestionFormParameters);
	Else
		Result.InfoOnIssues.Show(NStr("vi = 'Kết quả kiểm tra phần mở rộng.';
										|ru = 'Результат проверки расширений.';
										|en = 'The extension check result.'; fa = 'The extension check result.';
										|it = 'Результат проверки расширений.';
										|pl = 'The extension check result.';
										|tr = 'Uzantıların doğrulama sonucu'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableExtensions(Command)
	
	ShowTimeConsumingOperation();
	AttachIdleHandler("EnableAttachExtensions", 0.1, True);
	
EndProcedure

&AtClient
Procedure DisableExtensions(Command)
	
	ShowTimeConsumingOperation();
	AttachIdleHandler("DisableAttachExtensions", 0.1, True);
	
EndProcedure

&AtClient
Procedure EnableTransferToSubordinateDIBNodes(Command)
	
	ShowTimeConsumingOperation();
	AttachIdleHandler("EnableTransferToSubordinateDIBNodesCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure DisableTransferToSubordinateDIBNodes(Command)
	
	ShowTimeConsumingOperation();
	AttachIdleHandler("DisableTransferToSubordinateDIBNodesCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure EnableSafeMode(Command)
	
	ShowTimeConsumingOperation();
	AttachIdleHandler("EnableSafeModeCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure DisableSafeMode(Command)
		
	ShowTimeConsumingOperation();
	AttachIdleHandler("DisableSafeModeCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure SetEmployeeResponsible(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", True);
	FormParameters.Insert("MultipleChoice", False);
	FormParameters.Insert("AdvancedPick", False);
	
	Notification = New CallbackDescription("SetAssigneeAfterSelection", ThisObject);
	
	OpenForm("Catalog.Users.ChoiceForm", FormParameters, ThisObject,,,, Notification,
		FormWindowOpeningMode.LockOwnerWindow);	

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateListIdleHandler()
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure UpdateList(AfterAdd = False)
	
	If AfterAdd Then
		CurrentRowIndex = ExtensionsList.Count();
	Else
		CurrentRowIndex = 0;
		CurrentRowID = Items.ExtensionsList.CurrentRow;
		If CurrentRowID <> Undefined Then
			String = ExtensionsList.FindByID(CurrentRowID);
			If String <> Undefined Then
				CurrentRowIndex = ExtensionsList.IndexOf(String);
			EndIf;
		EndIf;
	EndIf;
	
	ExtensionsList.Clear();
	
	SetPrivilegedMode(True);
	Extensions = ConfigurationExtensions.Get();
	AttachedExtensions = ExtensionsIDs(ConfigurationExtensionsSource.SessionApplied);
	DetachedExtensions  = ExtensionsIDs(ConfigurationExtensionsSource.SessionDisabled);
	SetPrivilegedMode(False);
	
	ModuleConfigurationUpdate = Undefined;
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then 
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
	EndIf;
	
	DontOutputCommonExtensions = Common.DataSeparationEnabled() And Not AccessRight("Administration", Metadata);
	SerialNumber = 1;
	For Each Extension In Extensions Do
		
		If DontOutputCommonExtensions 
			And (Extension.Scope = ConfigurationExtensionScope.InfoBase) Then
			Continue;
		EndIf;
			
		If ModuleConfigurationUpdate <> Undefined And ModuleConfigurationUpdate.IsPatch(Extension) Then 
			Continue;
		EndIf;
			
		ExtensionItem = ExtensionsList.Add();
		ExtensionItem.ExtensionID = Extension.UUID;
		ExtensionItem.Name = Extension.Name;
		ExtensionItem.Version = Extension.Version;
		ExtensionItem.Checksum = Base64String(Extension.HashSum);
		ExtensionItem.Synonym = Extension.Synonym;
		ExtensionItem.Purpose = Extension.Purpose;
		ExtensionItem.SafeMode = Extension.SafeMode;
		ExtensionItem.Attach = Extension.Active;
		ExtensionItem.ReceivedFromMasterDIBNode = Extension.MasterNode <> Undefined;
		ExtensionItem.PassToSubordinateDIBNodes = Extension.UsedInDistributedInfoBase;
		ExtensionItem.SerialNumber = SerialNumber;
		
		ExtensionItem.Common = (Extension.Scope = ConfigurationExtensionScope.InfoBase);
		
		ExtensionItem.AssignmentPriority =
			?(Extension.Purpose = Metadata.ObjectProperties.ConfigurationExtensionPurpose.Patch, 1,
			?(Extension.Purpose = Metadata.ObjectProperties.ConfigurationExtensionPurpose.Customization, 2, 3));
		
		ExtensionKey = Extension.Name + Extension.HashSum + Extension.Scope;	
		If AttachedExtensions[ExtensionKey] <> Undefined Then
			ExtensionItem.Attached = 0;
			ExtensionItem.ActivationState = NStr("vi = 'Đã kết nối';
												|ru = 'Подключено';
												|en = 'Attached'; fa = 'متصل‌شده';
												|it = 'Collegato';
												|pl = 'Attached';
												|tr = 'Bağlı'");
		ElsIf DetachedExtensions[ExtensionKey] <> Undefined Then
			ExtensionItem.Attached = 2;
			ExtensionItem.ActivationState = NStr("vi = 'Ngắt bỏ';
												|ru = 'Отключено';
												|en = 'Detached'; fa = 'جداشده';
												|it = 'Disabilitato';
												|pl = 'Detached';
												|tr = 'Devre dışı'");
		Else
			ExtensionItem.Attached = 1;
			ExtensionItem.ActivationState = NStr("vi = 'Cần khởi động lại';
												|ru = 'Требуется перезапуск';
												|en = 'Restart required'; fa = 'Restart required';
												|it = 'È necessario riavviare';
												|pl = 'Wymagane ponowne uruchomienie';
												|tr = 'Yeniden başlatma gerekiyor'");
		EndIf;	
			
		If IsBlankString(ExtensionItem.Synonym) Then
			ExtensionItem.Synonym = ExtensionItem.Name;
		EndIf;
		
		If TypeOf(Extension.SafeMode) = Type("Boolean") Then
			ExtensionItem.SafeModeFlag = Extension.SafeMode;
		Else
			ExtensionItem.SafeModeFlag = True;
		EndIf;
		SerialNumber = SerialNumber + 1;
	EndDo;
	ExtensionsList.Sort("ReceivedFromMasterDIBNode DESC, AssignmentPriority, Common DESC, SerialNumber");
	
	If CurrentRowIndex >= ExtensionsList.Count() Then
		CurrentRowIndex = ExtensionsList.Count() - 1;
	EndIf;
	If CurrentRowIndex >= 0 Then
		Items.ExtensionsList.CurrentRow = ExtensionsList.Get(
			CurrentRowIndex).GetID();
	EndIf;
	
	SetPrivilegedMode(True);
	InstalledExtensions = Catalogs.ExtensionsVersions.InstalledExtensions();
	ExtensionsStateChanged = 
		(SessionParameters.InstalledExtensions.MainState <> InstalledExtensions.MainState);
	Items.WarningGroup.Visible = ExtensionsStateChanged;
	SetPrivilegedMode(False);
	
	// Updating the form attribute for conditional formatting.
	IsSharedUserInArea = IsSharedUserInArea();
	
	Items.WarningDetails.Visible = Not IsSharedUserInArea;
	Items.WarningDetails2.Visible = IsSharedUserInArea;
	
	UpdateExtensionsPropertiesInList();
	
EndProcedure

&AtServer
Function ExtensionsIDs(ExtensionSource)
	
	Extensions = ConfigurationExtensions.Get(, ExtensionSource);
	IDs = New Map;
	
	For Each Extension In Extensions Do
		IDs.Insert(Extension.Name + Extension.HashSum + Extension.Scope, True);
	EndDo;
	
	Return IDs;
	
EndFunction

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

&AtServer
Function SaveAtServer(RowsIDs, PathToDirectory = "")
	
	FilesToSave = New Array;
	For Each RowID In RowsIDs Do
		ListLine = ExtensionsList.FindByID(RowID);
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

&AtServer
Procedure RunUpdateSettingsExtensionsWorkInBackgroundOnServer(WarningText)
	
	SetPrivilegedMode(True);
	
	InformationRegisters.ExtensionVersionParameters.EnableFillingExtensionsWorkParameters();
	
	WarningText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '1. Đã bật và khởi động nhiệm vụ thường kỳ
		           |""%1"".
		           |
		           |2. Kết quả làm việc xem trong nhật ký sự kiện trong các sự kiện
		           |""%2"",
		           |ví dụ, lệnh 
		           |""%3"" trong menu Hơn nữa.';
		           |ru = '1. Включено и запущено регламентное задание
		           |""%1"".
		           |
		           |2. Результат работы см. в журнале регистрации в событиях
		           |""%2"",
		           |например, с помощью команды в меню Еще
		           |""%3"".';
		           |en = '1. Scheduled job
		           |""%1"" is enabled and started.
		           |
		           |2. See the result in the event log in the events
		           |""%2"",
		           |for example, by clicking
		           |""%3"" in the More menu.'; fa = '1. Scheduled job
		           |""%1"" is enabled and started.
		           |
		           |2. See the result in the event log in the events
		           |""%2"",
		           |for example, by clicking
		           |""%3"" in the More menu.';
		           |it = '1. Attivato e avviato il compito regolamentato 
		           | ""%1"".
		           |
		           |2. Risultato del lavoro vedere nel registro degli eventi negli eventi 
		           | ""%2"",
		           | ad esempio, tramite il comando nel menu Altro
		           | ""%3"".';
		           |pl = '1. Włączono i uruchomiono zadanie reglamentowane
		           |""%1"".
		           |
		           |2. Wynik pracy patrz w dzienniku rejestracji w wydarzeniach
		           |""%2"",
		           |na przykład, za pomocą polecenia w menu Więcej
		           |""%3"".';
		           |tr = '1. Planlanmış iş etkin ve çalışıyor
		           |""%1"".
		           |
		           |2. Çalışmanın sonucunu
		           |""%2"", 
		           |örneğin Diğer menüsündeki komutu kullanarak olay kaydında görün
		           | ""%3"".'"),
		InformationRegisters.ExtensionVersionParameters.TaskNameFillingParameters(),
		InformationRegisters.ExtensionVersionParameters.ParameterFillingEventName(),
		Commands.Find("RunUpdateSettingsExtensionsWorkInBackground").Title);
		
EndProcedure

&AtServer
Procedure DeleteDeprecatedSettingsExtensionsWorkOnServer()
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.DeleteObsoleteParametersVersions();
	
EndProcedure

&AtClient
Procedure DeleteExtensions(SelectedRows)
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ExtensionsIDs = New Array;
	RowsToSkip = New Array;
	
	For Each RowID In SelectedRows Do
		ExtensionRow = ExtensionsList.FindByID(RowID);
		
		If ExtensionRow.Common
		   And IsSharedUserInArea
		 Or ExtensionRow.ReceivedFromMasterDIBNode Then
			
			RowsToSkip.Add(RowID);
			Continue;
		EndIf;
		ExtensionsIDs.Add(ExtensionRow.ExtensionID);
	EndDo;
	
	For Each RowID In RowsToSkip Do
		SelectedRows.Delete(SelectedRows.Find(RowID));
	EndDo;
	
	If ExtensionsIDs.Count() = 0 Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("ExtensionsIDs", ExtensionsIDs);
	
	Notification = New CallbackDescription("DeleteExtensionAfterConfirmation", ThisObject, Context);
	WarningKind = ?(HasExtensionWithData(ExtensionsIDs),
		UsersInternalClientServer.SecurityWarningKinds().BeforeDeleteExtensionWithData,
		UsersInternalClientServer.SecurityWarningKinds().BeforeDeleteExtensionWithoutData);
	
	UsersInternalClient.ShowSecurityWarning(Notification,
		WarningKind, ExtensionsIDs.Count() > 1);
	
EndProcedure

&AtClient
Procedure DeleteExtensionAfterConfirmation(Result, Context) Export
	
	If Result <> "Continue" Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("DeleteExtensionFollowUp", ThisObject, Context);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = RequestsToRevokeExternalModuleUsagePermissions(Context.ExtensionsIDs);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, Notification);
	Else
		RunCallback(Notification, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExtensionFollowUp(Result, Context) Export
	
	If Result = DialogReturnCode.OK Then
		ShowTimeConsumingOperation();
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
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
		Return;
	EndTry;
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	
EndProcedure

&AtServer
Procedure DeleteExtensionsAtServer(ExtensionsIDs)
	
	ErrorText = "";
	Catalogs.ExtensionsVersions.DeleteExtensions(ExtensionsIDs, ErrorText);
	
	UpdateList();
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

&AtClient
Procedure DetachExtensionAfterConfirmation(Result, Context) Export
	
	If Result <> "Continue" Then
		
		ListLine = ExtensionsList.FindByID(Context.RowID);
		If ListLine = Undefined Then
			Return;
		EndIf;
		
		ListLine.Attach = Not ListLine.Attach;
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		Return;
	EndIf;
	
	ExtensionsListAttachOnChangeContinued(Context);
	
EndProcedure

&AtClient
Procedure ExtensionsListAttachOnChangeContinued(Context)
	
	ShowTimeConsumingOperation();
	CurrentContext = Context;
	AttachIdleHandler("ExtensionsListAttachOnChangeCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure ExtensionsListAttachOnChangeCompletion()
	
	Context = CurrentContext;
	
	Try
		ExtensionsListAttachOnChangeAtServer(Context.RowID);
	Except
		ErrorInfo = ErrorInfo();
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return;
	EndTry;
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	
EndProcedure

&AtClient
Procedure ExtensionsListSafeModeFlagOnChangeCompletion()
	
	Context = CurrentContext;
	
	Try
		ExtensionListSafeModeFlagOnChangeAtServer(Context.RowID);
	Except
		ErrorInfo = ErrorInfo();
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return;
	EndTry;
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	
EndProcedure

&AtServer
Function RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs)
	
	Return Catalogs.ExtensionsVersions.RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs);
	
EndFunction

&AtClient
Procedure ShowTimeConsumingOperation()
	
	Items.RefreshPages.CurrentPage = Items.TimeConsumingOperationPage;
	SetCommandBarButtonAvailability();
	
EndProcedure

&AtClient
Procedure HideTimeConsumingOperation()
	
	Items.RefreshPages.CurrentPage = Items.ExtensionsListPage;
	SetCommandBarButtonAvailability();
	
EndProcedure

&AtClient
Procedure LoadExtension(Val ExtensionID, MultipleChoice = False)
	
	Context = New Structure;
	Context.Insert("ExtensionID", ExtensionID);
	Context.Insert("MultipleChoice", MultipleChoice);
	Context.Insert("SelectedRows", ExtensionID);
	
	Notification = New CallbackDescription("LoadExtensionAfterConfirmation", ThisObject, Context);
	UsersInternalClient.ShowSecurityWarning(Notification,
		UsersInternalClientServer.SecurityWarningKinds().BeforeAddExtensions);
	
EndProcedure

&AtClient
Procedure LoadExtensionAfterConfirmation(Response, Context) Export
	If Response <> "Continue" Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("LoadExtensionAfterPutFiles", ThisObject, Context);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("vi = 'Phần mở rộng cấu hình';
											|ru = 'Расширение конфигурации';
											|en = 'Configuration extensions'; fa = 'افزونه‌های پیکربندی';
											|it = 'Estensione di configurazione';
											|pl = 'Rozszerzenie konfiguracji';
											|tr = 'Yapılandırmanın uzantısı'")+ " (*.cfe)|*.cfe";
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp mở rộng cấu hình';
										|ru = 'Выберите файл расширения конфигурации';
										|en = 'Select configuration extension file'; fa = 'Select configuration extension file';
										|it = 'Selezionate il file di estensione di configurazione';
										|pl = 'Wybierz plik rozszerzenia konfiguracji';
										|tr = 'Yapılandırma uzantı dosyasını seçin'");
	ImportParameters.Dialog.CheckFileExistence = True;
	
	ImportParameters.FormIdentifier = UUID;
	FileSystemClient.ImportFiles(Notification, ImportParameters);
	
EndProcedure

&AtClient
Procedure LoadExtensionAfterPutFiles(PlacedFiles, Context) Export
	
	If PlacedFiles = Undefined
	 Or PlacedFiles.Count() = 0 Then
		
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		
		If SelectedFilesContainOnlyPatches(PlacedFiles, ModuleConfigurationUpdateClient) Then 
			
			BackupParameters = New Structure;
			BackupParameters.Insert("SelectedFiles", SelectedFilesByDetails(PlacedFiles));
			ModuleConfigurationUpdateClient.ShowUpdateSearchAndInstallation(BackupParameters);
			Return;
			
		ElsIf SelectedFilesContainPatches(PlacedFiles, ModuleConfigurationUpdateClient) Then 
			ShowMessageBox(,
				NStr("vi = 'Tệp đã chọn không được có cả bản sửa lỗi (vá lỗi) và các dạng mở rộng khác.';
					|ru = 'Выбранные файлы не должны одновременно содержать исправления (патчи) и другие виды расширений.';
					|en = 'The selected files cannot contain both patches and extensions of other types.'; fa = 'The selected files cannot contain both patches and extensions of other types.';
					|it = 'I file selezionati non dovrebbero contenere simultaneamente correzioni (patch) e altri tipi di estensioni.';
					|pl = 'Wybrane pliki nie powinny jednocześnie zawierać korekt (łat) i innych rodzajów rozszerzeń.';
					|tr = 'Seçilen dosyalar aynı anda düzeltmeler (yamalar) ve diğer uzantı türlerini içermemelidir.'"));
			Return;
		EndIf;
	EndIf;
	
	Context.Insert("PlacedFiles", PlacedFiles);
	
	ClosingNotification1 = New CallbackDescription(
		"LoadExtensionContinued", ThisObject, Context);
	
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		PermissionsRequests = New Array;
		Try
			AddPermissionRequest(PermissionsRequests, PlacedFiles, Context.ExtensionID);
		Except
			ErrorInfo = ErrorInfo();
			ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Return;
		EndTry;
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			PermissionsRequests, ThisObject, ClosingNotification1);
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

// Parameters:
//  PlacedFiles - Array of TransferredFileDescription
//  ModuleConfigurationUpdateClient - CommonModule
//
// Returns:
//  Boolean
//
&AtClient
Function SelectedFilesContainPatches(PlacedFiles, ModuleConfigurationUpdateClient)
	
	For Each FileThatWasPut In PlacedFiles Do 
		File = New File(FileThatWasPut.Name);
		If ModuleConfigurationUpdateClient.IsPatch(File.Name) Then 
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Parameters:
//  PlacedFiles - Array of TransferredFileDescription
//  ModuleConfigurationUpdateClient - CommonModule
//
// Returns:
//  Boolean
//
&AtClient
Function SelectedFilesContainOnlyPatches(PlacedFiles, ModuleConfigurationUpdateClient)
	
	For Each FileThatWasPut In PlacedFiles Do 
		File = New File(FileThatWasPut.Name);
		If Not ModuleConfigurationUpdateClient.IsPatch(File.Name) Then 
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Parameters:
//   PlacedFiles - Array of TransferredFileDescription
//
// Returns:
//  String
//
&AtClient
Function SelectedFilesByDetails(PlacedFiles)
	
	ListOfFiles = New Array;
	
	For Each FileThatWasPut In PlacedFiles Do 
		File = New File(FileThatWasPut.Name);
		ListOfFiles.Add(File.FullName);
	EndDo;
	
	Return StrConcat(ListOfFiles, ", ");
	
EndFunction

&AtClient
Procedure LoadExtensionContinued(Result, Context) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	ShowTimeConsumingOperation();
	CurrentContext = Context;
	AttachIdleHandler("LoadExtensionCompletion", 0.1, True);
	
EndProcedure

&AtClient
Procedure LoadExtensionCompletion()
	
	Context = CurrentContext;
	
	UnattachedExtensions = "";
	ExtensionsChanged = False;
	If Context.Property("NameReplacementConfirmed") Then
		NameReplacementConfirmation = Undefined;
	Else
		NameReplacementConfirmation = New Structure("OldName, NewName", "", "");
	EndIf;
	Try
		ChangeExtensionsAtServer(Context.PlacedFiles,
			Context.SelectedRows, UnattachedExtensions, ExtensionsChanged, NameReplacementConfirmation);
		If ExtensionsToReAdd.Count() > 0 Then
			ToOpenTheFormCompleteTheUserExperience();
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return;
	EndTry;
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	
	If Not Context.Property("NameReplacementConfirmed")
	   And ValueIsFilled(NameReplacementConfirmation.OldName) Then
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phần mở rộng có tên ""%1"" sẽ được thay thế bởi phần mở rộng có tên ""%2"".
			           |
			           |Nếu phần mở rộng ""%2"" không phải là bản cập nhật phần mở rộng ""%1"",
			           |thì cần từ chối thay thế và thêm phần mở rộng ""%2"", như là mới.
			           |Ví dụ: nếu không thể thêm phần mở rộng ""%2"" do phần mở rộng ""%1"",
			           |thì ban đầu cần xóa phần mở rộng ""%1"", sau đó thêm ""%2"".';
			           |ru = 'Расширение с именем ""%1"" будет заменено на расширение с именем ""%2"".
			           |
			           |Если расширение ""%2"" не является обновлением расширения ""%1"",
			           |тогда следует отказаться от замены и добавить расширение ""%2"", как новое.
			           |Прим.: если расширение ""%2"" не удается добавить из-за расширения ""%1"",
			           |тогда следует сначала удалить расширение ""%1"", а затем добавить ""%2"".';
			           |en = 'Extension ""%1"" will be replaced with extension ""%2"".
			           |
			           |If extension ""%2"" is not an update for extension ""%1"",
			           |refuse to replace it and add extension ""%2"" as a new one.
			           |Note: if you cannot add extension ""%2"" because of extension ""%1"",
			           |delete extension ""%1"" before adding extension ""%2"".'; fa = 'Extension ""%1"" will be replaced with extension ""%2"".
			           |
			           |If extension ""%2"" is not an update for extension ""%1"",
			           |refuse to replace it and add extension ""%2"" as a new one.
			           |Note: if you cannot add extension ""%2"" because of extension ""%1"",
			           |delete extension ""%1"" before adding extension ""%2"".';
			           |it = 'L''estensione con nome ""%1"" sarà sostituita con l''estensione con nome ""%2"".
			           |
			           |Se l''estensione ""%2"" non è un aggiornamento dell''estensione ""%1"", 
			           |è necessario rinunciare alla sostituzione e aggiungere l''estensione ""%2"" come nuova.
			           |Esempio: se l''estensione ""%2"" non può essere aggiunta a causa dell''estensione ""%1"", 
			           |è necessario all''inizio eliminare l''estensione ""%1"", e poi aggiungere ""%2"".';
			           |pl = 'Rozszerzenie z nazwą ""%1"" zostanie zastąpione na rozszerzenie z nazwą ""%2"".
			           |
			           |Jeśli rozszerzenie ""%2"" nie jest aktualizacją rozszerzenia ""%1"",
			           |to należy odmówić zmiany i dodać rozszerzenie ""%2"", jako nowe.
			           |Uwaga: jeśli rozszerzenie ""%2"" nie można dodać rozszerzenia ""%1"",
			           |to należy usunąć rozszerzenie ""%1"", a zatem dodać ""%2"".';
			           |tr = '""%1"" adlı uzantı, ""%2adlı uzantıyla değiştirilecektir.
			           |
			           | ""%2"" uzantısı, ""%1"" 
			           |uzantısının bir güncellemesi değilse, o zaman yenisini atmalı ve ""%2"" uzantısını yeni olarak eklemelisiniz.
			           | Not: ""%2"" uzantısı ""%1"" uzantısı nedeniyle eklenemiyorsa, 
			           |önce ""%1"" uzantısını kaldırmalı ve ardından ""%2"" eklemelisiniz.'"),
			NameReplacementConfirmation.OldName,
			NameReplacementConfirmation.NewName);
			
		CompletionHandler = New CallbackDescription(
			"LoadExtensionAfterQuestionNameReplacement", ThisObject, Context);
		
		Buttons = New ValueList;
		Buttons.Add("Replace",   NStr("vi = 'Thay thế';
										|ru = 'Заменить';
										|en = 'Replace'; fa = 'جایگزینی';
										|it = 'Sostituire';
										|pl = 'Replace';
										|tr = 'Değiştir'"));
		Buttons.Add("NotReplace", NStr("vi = 'Không thay thế';
										|ru = 'Не заменять';
										|en = 'Do not replace'; fa = 'Do not replace';
										|it = 'Non sostituire';
										|pl = 'Nie zastępuj';
										|tr = 'Değiştirmemek'"));
		
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.DefaultButton = "NotReplace";
		QuestionParameters.PromptDontAskAgain = False;
		
		StandardSubsystemsClient.ShowQuestionToUser(CompletionHandler,
			QueryText, Buttons, QuestionParameters);
		Return;
	EndIf;
	
	If Not ExtensionsChanged Then
		Return;
	EndIf;
	
	If Context.ExtensionID = Undefined Then
		If Context.PlacedFiles.Count() > 1 Then
			NotificationText1 = NStr("vi = 'Đã thêm phần mở rộng cấu hình';
									|ru = 'Расширения конфигурации добавлены';
									|en = 'Configuration extensions added'; fa = 'Configuration extensions added';
									|it = 'Estensioni di configurazione aggiunte';
									|pl = 'Rozszerzenia konfiguracji zostały dodane';
									|tr = 'Yapılandırma uzantıları eklendi'");
		Else
			NotificationText1 = NStr("vi = 'Đã thêm phần mở rộng cấu hình';
									|ru = 'Расширение конфигурации добавлено';
									|en = 'Configuration extension added'; fa = 'Configuration extension added';
									|it = 'Estensione di configurazione aggiunta';
									|pl = 'Rozszerzenie konfiguracji zostało dodane';
									|tr = 'Yapılandırma uzantıları eklenmiştir'");
		EndIf;
	Else
		NotificationText1 = NStr("vi = 'Đã cập nhật phần mở rộng cấu hình';
								|ru = 'Расширение конфигурации обновлено';
								|en = 'Configuration extension updated'; fa = 'Configuration extension updated';
								|it = 'Estensione di configurazione aggiornata';
								|pl = 'Rozszerzenie konfiguracji zostało zaktualizowane';
								|tr = 'Yapılandırma uzantıları eklenmiştir'");
	EndIf;
	
	ShowUserNotification(NotificationText1);
	
	If Not ValueIsFilled(UnattachedExtensions) Then
		Return;
	EndIf;
	
	If Context.PlacedFiles.Count() > 1 Then
		If StrFind(UnattachedExtensions, ",") > 0 Then
			WarningText = NStr("vi = 'Nhiều phần mở rộng không được kết nối:';
								|ru = 'Некоторые расширения не подключаются:';
								|en = 'Cannot attach the following extensions:'; fa = 'Cannot attach the following extensions:';
								|it = 'Alcune estensioni non vengono connesse:';
								|pl = 'Niektóre rozszerzenia nie podłączają się:';
								|tr = 'Bazı uzantılar bağlanamadı:'");
		Else
			WarningText = NStr("vi = 'Một phần mở rộng không được kết nối:';
								|ru = 'Одно расширение не подключается:';
								|en = 'Cannot attach the extension:'; fa = 'Cannot attach the extension:';
								|it = 'Un estensione non viene connessa:';
								|pl = 'Jedno rozszerzenie nie podłącza się:';
								|tr = 'Bir uzantı bağlanamadı:'");
		EndIf;
		WarningText = WarningText + " " + UnattachedExtensions;
	Else
		WarningText = NStr("vi = 'Chưa kết nối phần mở rộng.';
							|ru = 'Расширение не подключается.';
							|en = 'Cannot attach an extension.'; fa = 'Cannot attach an extension.';
							|it = 'L''estensione non viene connessa.';
							|pl = 'Rozszerzenie nie podłącza się.';
							|tr = 'Uzantı bağlanmıyor.'");
	EndIf;
	
	ShowMessageBox(, WarningText);
	
EndProcedure

&AtClient
Procedure LoadExtensionAfterQuestionNameReplacement(Result, Context) Export
	
	If Result = Undefined
	 Or Result.Value <> "Replace" Then
		Return;
	EndIf;
	
	Context.Insert("NameReplacementConfirmed");
	
	ShowTimeConsumingOperation();
	CurrentContext = Context;
	AttachIdleHandler("LoadExtensionCompletion", 0.1, True);
	
EndProcedure

&AtServer
Procedure ChangeExtensionsAtServer(PlacedFiles, RowsIDs,
			UnattachedExtensions, ExtensionsChanged, NameReplacementConfirmation)
			
	ExtensionsToReAdd.Clear();
	Extension = Undefined;
	
	SelectedExtensions = New Structure;
	If RowsIDs <> Undefined Then
		For Each FileThatWasPut In PlacedFiles Do
			BinaryData = GetFromTempStorage(FileThatWasPut.Location);
			ExtensionDetails = New ConfigurationDescription(BinaryData);
			SelectedExtensions.Insert(ExtensionDetails.Name, BinaryData);
		EndDo;
	EndIf;
	
	ExtensionsToCheck = New Map;
	AddedExtensions = New Array;
	SourceExtensions    = New Map;
	
	ErrorText = "";
	AddedExtensionFileName = Undefined;
	Try
		If RowsIDs <> Undefined Then
			For Each RowID In RowsIDs Do
				TableRow = ExtensionsList.FindByID(RowID);
				ExtensionID = TableRow.ExtensionID;
				Extension = FindExtension(ExtensionID);
				If Extension = Undefined Then
					Continue;
				EndIf;
				
				PreviousExtensionName = Extension.Name;
				NewExtensionName = PreviousExtensionName;
				
				If Not SelectedExtensions.Property(PreviousExtensionName) Then
					If RowsIDs.Count() <> 1 Then
						Continue;
					ElsIf NameReplacementConfirmation <> Undefined Then
						NameReplacementConfirmation.OldName = PreviousExtensionName;
						NameReplacementConfirmation.NewName = ExtensionDetails.Name;
						Return;
					Else
						NewExtensionName = ExtensionDetails.Name;
					EndIf;
				EndIf;
				
				ExtensionData = Extension.GetData();
				SourceExtensions.Insert(PreviousExtensionName, ExtensionData);
				
				DisableSecurityWarnings(Extension);
				DisableMainRolesUsageForAllUsers(Extension);
				NewBinaryData = SelectedExtensions[NewExtensionName];
				Errors = Extension.CheckCanApply(NewBinaryData, False);
				For Each Error In Errors Do
					If Error.Severity <> ConfigurationExtensionApplicationIssueSeverity.Critical Then
						Continue;
					EndIf;
					ErrorText = ErrorText + Chars.LF + Error.Description;
				EndDo;
				
				If ValueIsFilled(ErrorText) Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể áp dụng phần mở rộng mới do nguyên nhân:
						           |%1';
						           |ru = 'Новое расширение не может быть применено по причине:
						           |%1';
						           |en = 'Cannot apply the extension. Reason:
						           |%1'; fa = 'Cannot apply the extension. Reason:
						           |%1';
						           |it = 'La nuova estensione non può essere applicata a causa di:
						           |%1';
						           |pl = 'Nowe rozszerzenie nie może być zastosowane z powodu:
						           |%1';
						           |tr = 'Yeni uzantı 
						           |%1 nedeniyle uygulanamaz'"),
						ErrorText);
					Break;
				Else
					Extension.Write(NewBinaryData);
					Extension = FindExtension(ExtensionID);
					ExtensionsToCheck.Insert(Extension.Name, Extension.Synonym);
				EndIf;
			EndDo;
		Else
			For Each FileThatWasPut In PlacedFiles Do
				FileBinaryData = GetFromTempStorage(FileThatWasPut.Location);
				ExtensionDetails = New ConfigurationDescription(FileBinaryData);
				Filter = New Structure("Name", ExtensionDetails.Name);
				Extensions = ConfigurationExtensions.Get(Filter);
				If Extensions.Count() > 0 Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể thêm phần mở rộng ""%1""
						           |từ tệp ""%2"",
						           |vì đã tồn tại phần mở rộng có tên gọi như vậy.';
						           |ru = 'Нельзя добавить расширение ""%1""
						           |из файла ""%2"",
						           |так как расширение с таким именем уже существует.';
						           |en = 'Cannot add extension ""%1""
						           | from file %2, 
						           |as an extension with this name already exists.'; fa = 'Cannot add extension ""%1""
						           | from file %2, 
						           |as an extension with this name already exists.';
						           |it = 'Impossibile aggiungere l''estensione ""%1""
						           | dal file ""%2"",
						           | perché l''estensione con questo nome esiste già.';
						           |pl = 'Nie można dodać rozszerzenia ""%1""
						           |z pliku ""%2"",
						           |ponieważ rozszerzenie o takiej nazwie już istnieje.';
						           |tr = '""%2"" 
						           |dosyasından ""%1"" 
						           |uzantısı eklenemiyor çünkü bu ada sahip bir uzantı artık var.'"),
						ExtensionDetails.Name,
						FileThatWasPut.Name);
					Break;
				EndIf;
			EndDo;
			If Not ValueIsFilled(ErrorText) Then
				For Each FileThatWasPut In PlacedFiles Do
					FileBinaryData = GetFromTempStorage(FileThatWasPut.Location);
					ExtensionDetails = New ConfigurationDescription(FileBinaryData);
					Extension = ConfigurationExtensions.Create();
					DisableSecurityWarnings(Extension);
					DisableMainRolesUsageForAllUsers(Extension);
					AddedExtensionFileName = FileThatWasPut.Name;
					Extension.Write(FileBinaryData);
					AddedExtensionFileName = Undefined;
					Extension = FindExtension(String(Extension.UUID));
					AddedExtensions.Insert(0, Extension);
					ExtensionsToCheck.Insert(Extension.Name, Extension.Synonym);
				EndDo;
			EndIf;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		If RowsIDs <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể cập nhật phần mở rộng do nguyên nhân:
				           |%1';
				           |ru = 'Не удалось обновить расширение по причине:
				           |%1';
				           |en = 'Cannot update the extension. Reason:
				           |%1'; fa = 'Cannot update the extension. Reason:
				           |%1';
				           |it = 'Non è stato possibile aggiornare l''estensione a causa di:
				           |%1';
				           |pl = 'Nie udało się aktualizować rozszerzenie z powodu:
				           |%1';
				           |tr = 'Uzantı şu nedenle güncellenemedi:
				           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
			
		ElsIf ValueIsFilled(AddedExtensionFileName) Then
			BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
			If IsInfobaseExclusiveLockError(BriefErrorDescription) Then
				
				IndexOfFirstExtensionFailedToAdd = PlacedFiles.Find(FileThatWasPut);
				If IndexOfFirstExtensionFailedToAdd <> Undefined Then
					ExtensionsToReAdd.Clear();
					For IndexOf = IndexOfFirstExtensionFailedToAdd To PlacedFiles.UBound() Do
						ExtensionsToReAdd.Add(PlacedFiles.Get(IndexOf));
					EndDo;
				EndIf;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể thêm phần mở rộng ""%1""
					           |từ tệp ""%2"" do nguyên nhân:
					           |%3';
					           |ru = 'Не удалось добавить расширение ""%1""
					           |из файла ""%2"" по причине:
					           |%3';
					           |en = 'Cannot add extension ""%1""
					           | from file %2. Reason:
					           |%3'; fa = 'Cannot add extension ""%1""
					           | from file %2. Reason:
					           |%3';
					           |it = 'Non è stato possibile aggiungere l''estensione ""%1""
					           | dal file ""%2"" a causa di: 
					           |%3';
					           |pl = 'Nie udało się dodać rozszerzenia ""%1""
					           |z pliku ""%2"" z powodu:
					           |%3';
					           |tr = '%3 nedeniyle ""%2"" 
					           |dosyasından ""%1"" 
					           |uzantısı eklenemedi:'"),
					ExtensionDetails.Name,
					AddedExtensionFileName,
					BriefErrorDescription);
			EndIf;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thêm do nguyên nhân:
				           |%1';
				           |ru = 'Не удалось добавить по причине:
				           |%1';
				           |en = 'Cannot add the extension. Reason:
				           |%1'; fa = 'Cannot add the extension. Reason:
				           |%1';
				           |it = 'Non è stato possibile aggiungere a causa di:
				           |%1';
				           |pl = 'Nie udało się dodać z powodu:
				           |%1';
				           |tr = '%1 nedeniyle eklenmedi:
				           |'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndIf;
	EndTry;
	
	If Not ValueIsFilled(ErrorText) Then
		Try
			InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters(ExtensionsToCheck, UnattachedExtensions);
			ExtensionsChanged = True;
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra tình huống không mong muốn khi chuẩn bị phần mở rộng để làm việc:
				           |%1';
				           |ru = 'Возникла непредвиденная ситуация при подготовке добавленных расширений к работе:
				           |%1';
				           |en = 'An unexpected error occurred while preparing the added extensions:
				           |%1'; fa = 'An unexpected error occurred while preparing the added extensions:
				           |%1';
				           |it = 'Возникла непредвиденная ситуация при подготовке добавленных расширений к работе:
				           |%1';
				           |pl = 'An unexpected error occurred while preparing the added extensions:
				           |%1';
				           |tr = 'Eklenen uzantıları işlem için hazırlarken beklenmedik bir durum yaşandı:
				           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		RecoveryPerformed = False;
		Try
			If RowsIDs <> Undefined Then
				For Each ExtensionToCheck In ExtensionsToCheck Do
					ExtensionData = SourceExtensions[ExtensionToCheck.Key];
					Extension = FindExtension(ExtensionID);
					If Extension = Undefined Then
						Extension = ConfigurationExtensions.Create();
					EndIf;
					DisableSecurityWarnings(Extension);
					DisableMainRolesUsageForAllUsers(Extension);
					Extension.Write(ExtensionData);
				EndDo;
				RecoveryPerformed = True;
			Else
				For Each AddedExtension In AddedExtensions Do
					Filter = New Structure("Name", AddedExtension.Name);
					Extensions = ConfigurationExtensions.Get(Filter);
					For Each Extension In Extensions Do
						If Extension.HashSum = AddedExtension.HashSum Then
							Extension.Delete();
							RecoveryPerformed = True;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		Except
			RecoveryErrorInformation = ErrorInfo();
			If RowsIDs <> Undefined Then
				ErrorText = ErrorText + Chars.LF + Chars.LF
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đã xảy ra tình huống không mong muốn khi thử khôi phục phần mở rộng được thay đổi:
						           |%1';
						           |ru = 'Возникла непредвиденная ситуация при попытке восстановить измененное расширение:
						           |%1';
						           |en = 'An unexpected error occurred while restoring the changed extension:
						           |%1'; fa = 'An unexpected error occurred while restoring the changed extension:
						           |%1';
						           |it = 'Возникла непредвиденная ситуация при попытке восстановить измененное расширение:
						           |%1';
						           |pl = 'An unexpected error occurred while restoring the changed extension:
						           |%1';
						           |tr = 'Değişen uzantıları yeniden kurmaya çalışırken beklenmedik bir durum yaşandı:
						           |%1'"), ErrorProcessing.BriefErrorDescription(RecoveryErrorInformation));
			Else
				ErrorText = ErrorText + Chars.LF + Chars.LF
					+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đã xảy ra tình huống không mong muốn khi thử khôi phục phần mở rộng được thêm:
						           |%1';
						           |ru = 'Возникла непредвиденная ситуация при попытке удалить добавленные расширения:
						           |%1';
						           |en = 'An unexpected error occurred while trying to delete the added extensions:
						           |%1'; fa = 'An unexpected error occurred while trying to delete the added extensions:
						           |%1';
						           |it = 'Возникла непредвиденная ситуация при попытке удалить добавленные расширения:
						           |%1';
						           |pl = 'An unexpected error occurred while trying to delete the added extensions:
						           |%1';
						           |tr = 'Eklenen uzantıları silmeye çalışırken beklenmedik bir durum yaşandı:
						           |%1'"), ErrorProcessing.BriefErrorDescription(RecoveryErrorInformation));
			EndIf;
		EndTry;
		If RecoveryPerformed
		   And RecoveryErrorInformation = Undefined Then
			
			If RowsIDs <> Undefined Then
				If ExtensionsToCheck.Count() > 0 Then
					ErrorText = ErrorText + Chars.LF + Chars.LF
						+ NStr("vi = 'Đã khôi phục phần mở rộng được thay đổi.';
								|ru = 'Измененное расширение было восстановлено.';
								|en = 'The modified extension is restored.'; fa = 'The modified extension is restored.';
								|it = 'L''estensione modificata è stata ripristinata.';
								|pl = 'Zmienione rozszerzenie zowstało odzyskane.';
								|tr = 'Değişmiş uzantı geri yüklendi.'");
				Else
					ErrorText = ErrorText + Chars.LF + Chars.LF
						+ NStr("vi = 'Chưa thay đổi phần mở rộng.';
								|ru = 'Расширение не было изменено.';
								|en = 'The extension is not modified.'; fa = 'The extension is not modified.';
								|it = 'L''estensione non è stata modificata.';
								|pl = 'Rozszerzenie nie zostało zmienione.';
								|tr = 'Uzantı değiştirilmedi.'");
				EndIf;
			Else
				ErrorText = ErrorText + Chars.LF + Chars.LF
					+ NStr("vi = 'Đã xóa phần mở rộng bổ sung.';
							|ru = 'Добавленные расширения были удалены.';
							|en = 'The added extensions are deleted.'; fa = 'The added extensions are deleted.';
							|it = 'Le estensioni aggiunte sono state eliminate.';
							|pl = 'Dodane rozszerzenia zostaną usunięte.';
							|tr = 'Eklenen uzantılar silindi.'");
			EndIf;
		EndIf;
	EndIf;
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	UpdateList(ExtensionID = Undefined);
	
EndProcedure

&AtServer
Procedure ExtensionListSafeModeFlagOnChangeAtServer(RowID)
	
	ListLine = ExtensionsList.FindByID(RowID);
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	Extension = FindExtension(ListLine.ExtensionID);
	
	If Extension = Undefined
	 Or Extension.SafeMode = ListLine.SafeModeFlag Then
		
		UpdateList();
		Return;
	EndIf;
	
	Extension.SafeMode = ListLine.SafeModeFlag;
	DisableSecurityWarnings(Extension);
	DisableMainRolesUsageForAllUsers(Extension);
	Try
		Extension.Write();
	Except
		ListLine.SafeModeFlag = Not ListLine.SafeModeFlag;
		Raise;
	EndTry;
	
	Try
		InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
	Except
		ErrorInfo = ErrorInfo();
		If Extension.SafeMode Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra tình huống không mong muốn khi chuẩn bị phần mở rộng để làm việc (sau khi bật sử dụng chế độ an toàn):
				           |%1';
				           |ru = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после включения безопасного режима):
				           |%1';
				           |en = 'An unexpected error occurred while preparing the extensions (after enabling the safe mode):
				           |%1'; fa = 'An unexpected error occurred while preparing the extensions (after enabling the safe mode):
				           |%1';
				           |it = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после включения безопасного режима):
				           |%1';
				           |pl = 'An unexpected error occurred while preparing the extensions (after enabling the safe mode):
				           |%1';
				           |tr = 'Uzantıları işlem için hazırlarken beklenmedik bir durum yaşandı (güvenli modun etkinleştirilmesinden sonra):
				           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra tình huống không mong muốn khi chuẩn bị phần mở rộng để làm việc (sau khi tắt sử dụng chế độ an toàn):
				           |%1';
				           |ru = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после отключения безопасного режима):
				           |%1';
				           |en = 'An unexpected error occurred while preparing the extensions (after disabling the safe mode):
				           |%1'; fa = 'An unexpected error occurred while preparing the extensions (after disabling the safe mode):
				           |%1';
				           |it = 'Возникла непредвиденная ситуация при подготовке расширений к работе (после отключения безопасного режима):
				           |%1';
				           |pl = 'An unexpected error occurred while preparing the extensions (after disabling the safe mode):
				           |%1';
				           |tr = 'Uzantıları işlem için hazırlarken beklenmedik bir durum yaşandı (güvenli modun kapatılmasından sonra):
				           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndIf;
	EndTry;
	
	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		Try
			Extension.SafeMode = Not Extension.SafeMode;
			Extension.Write();
		Except
			RecoveryErrorInformation = ErrorInfo();
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã xảy ra tình huống không mong muốn khi thử hủy thay đổi hộp kiểm chế độ bảo mật phần mở rộng:
					           |%1';
					           |ru = 'Возникла непредвиденная ситуация при попытке отменить изменение флажка безопасного режима расширения:
					           |%1';
					           |en = 'An unexpected error occurred when trying to cancel the change of the safe extension mode check box:
					           |%1'; fa = 'An unexpected error occurred when trying to cancel the change of the safe extension mode check box:
					           |%1';
					           |it = 'Возникла непредвиденная ситуация при попытке отменить изменение флажка безопасного режима расширения:
					           |%1';
					           |pl = 'An unexpected error occurred when trying to cancel the change of the safe extension mode check box:
					           |%1';
					           |tr = 'Uzantının güvenli mod onay kutusu değişimini iptal etme denemesinde beklenmedik bir durum yaşandı:
					           |%1'"), ErrorProcessing.BriefErrorDescription(RecoveryErrorInformation));
		EndTry;
		If RecoveryErrorInformation = Undefined Then
			ListLine.SafeModeFlag = Extension.SafeMode;
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ NStr("vi = 'Đã hủy thay đổi hộp kiểm chế độ mở rộng an toàn.';
						|ru = 'Отменено изменение флажка безопасного режима расширения.';
						|en = 'The change of the ""Safe mode"" extension parameter is canceled.'; fa = 'The change of the ""Safe mode"" extension parameter is canceled.';
						|it = 'Flag della modalità sicura dell''estensione annullato.';
						|pl = 'Anulowano zmianę pola trybu awaryjnego rozszerzenia.';
						|tr = 'Uzantının güvenli mod onay kutusu değişimi iptal edildi.'");
		EndIf;
	EndIf;
	
	UpdateList();
	
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function HasExtensionWithData(ExtensionsIDs)
	
	For Each ExtensionID In ExtensionsIDs Do
		If IsExtensionWithData(ExtensionID) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function IsExtensionWithData(ExtensionID)
	
	Extension = FindExtension(ExtensionID);
	
	If Extension = Undefined Then
		Return False;
	EndIf;
	
	Return Extension.ModifiesDataStructure();
	
EndFunction

&AtServer
Procedure ExtensionsListAttachOnChangeAtServer(RowID)
	
	ListLine = ExtensionsList.FindByID(RowID);
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	CurrentUsage = ListLine.Attach;
	Try
		Catalogs.ExtensionsVersions.ToggleExtensionUsage(ListLine.ExtensionID, CurrentUsage);
	Except
		ListLine.Attach = Not ListLine.Attach;
		UpdateList();
		
		Raise;
	EndTry;
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure ExtensionsListSendToSubordinateDIBNodesOnChangeAtServer(RowID)
	
	ListLine = ExtensionsList.FindByID(RowID);
	
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	Extension = FindExtension(ListLine.ExtensionID);
	
	If Extension <> Undefined Then
	
		If Extension.UsedInDistributedInfoBase <> ListLine.PassToSubordinateDIBNodes Then
			Extension.UsedInDistributedInfoBase = ListLine.PassToSubordinateDIBNodes;
			
			DisableSecurityWarnings(Extension);
			DisableMainRolesUsageForAllUsers(Extension);
			Try
				Extension.Write();
			Except
				ListLine.PassToSubordinateDIBNodes = Not ListLine.PassToSubordinateDIBNodes;
				Raise;
			EndTry;
		EndIf;
		
	EndIf;
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure AddPermissionRequest(PermissionsRequests, PlacedFiles, ExtensionID = Undefined)
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not ModuleSafeModeManager.UseSecurityProfiles() Then
		Return;
	EndIf;
	Permissions = New Array;
	
	For Each FileThatWasPut In PlacedFiles Do
		UpdatedExtensionData = Undefined;
		RecoveryRequired = False;
		Try
			If ExtensionID = Undefined Then
				TemporaryExtension = ConfigurationExtensions.Create();
			Else
				TemporaryExtension = FindExtension(ExtensionID);
				If TemporaryExtension = Undefined Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Phần mở rộng với tên định danh %1 không tồn tại trong ứng dụng, có thể đã xóa nó trong phiên làm việc khác.';
							|ru = 'Расширение с идентификатором %1 не существует в приложении, возможно оно было удалено в другом сеансе.';
							|en = 'The app does not have extensions with the id ""%1"". Probably, the extension was deleted by another user.'; fa = 'The app does not have extensions with the id ""%1"". Probably, the extension was deleted by another user.';
							|it = 'Расширение с идентификатором %1 не существует в приложении, возможно оно было удалено в другом сеансе.';
							|pl = 'The app does not have extensions with the id ""%1"". Probably, the extension was deleted by another user.';
							|tr = '%1 kimliğiyle bir uzantı uygulamada mevcut değil, başka bir oturumda silinmiş olabilir.'"),
						ExtensionID);
				EndIf;
				UpdatedExtensionData = TemporaryExtension.GetData();
			EndIf;
			DisableSecurityWarnings(TemporaryExtension);
			DisableMainRolesUsageForAllUsers(TemporaryExtension);
			ExtensionData = GetFromTempStorage(FileThatWasPut.Location);
			TemporaryExtension.Write(ExtensionData);
			RecoveryRequired = True;
			TemporaryExtension = FindExtension(String(TemporaryExtension.UUID));
			TemporaryExtensionProperties = New Structure;
			TemporaryExtensionProperties.Insert("Name",      TemporaryExtension.Name);
			TemporaryExtensionProperties.Insert("HashSum", TemporaryExtension.HashSum);
			If ExtensionID = Undefined Then
				TemporaryExtension.Delete();
			Else
				TemporaryExtension = FindExtension(ExtensionID);
				If TemporaryExtension = Undefined Then
					TemporaryExtension = ConfigurationExtensions.Create();
				EndIf;
				DisableSecurityWarnings(TemporaryExtension);
				DisableMainRolesUsageForAllUsers(TemporaryExtension);
				TemporaryExtension.Write(UpdatedExtensionData);
			EndIf;
			RecoveryRequired = False;
			
			Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
				TemporaryExtensionProperties.Name, Base64String(TemporaryExtensionProperties.HashSum)));
				
		Except
			ErrorInfo = ErrorInfo();
			If ExtensionID = Undefined Then
				If PlacedFiles.Count() > 1 Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Khi nhận phần mở rộng, không thể thêm phần mở rộng từ tệp
							           |""%1""
							           |do:
							           |%2';
							           |ru = 'При получении разрешений не удалось добавить расширение из файла
							           |""%1""
							           |по причине:
							           |%2';
							           |en = 'Cannot add extensions from the file
							           |""%1""
							           |when receiving permissions due to:
							           |%2'; fa = 'Cannot add extensions from the file
							           |""%1""
							           |when receiving permissions due to:
							           |%2';
							           |it = 'При получении разрешений не удалось добавить расширение из файла
							           |""%1""
							           |по причине:
							           |%2';
							           |pl = 'Cannot add extensions from the file
							           |""%1""
							           |when receiving permissions due to:
							           |%2';
							           |tr = 'Uzantı alınırken, 
							           |""%1""
							           | dosyasından 
							           |%2 nedeniyle uzantı eklenemedi'"),
							FileThatWasPut.Name,
							ErrorProcessing.BriefErrorDescription(ErrorInfo));
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Khi nhận quyền được phép, không thể thêm phần mở rộng do nguyên nhân:
							           |%1';
							           |ru = 'При получении разрешений не удалось добавить расширение по причине:
							           |%1';
							           |en = 'Cannot add the extension when receiving permissions due to:
							           |%1'; fa = 'Cannot add the extension when receiving permissions due to:
							           |%1';
							           |it = 'При получении разрешений не удалось добавить расширение по причине:
							           |%1';
							           |pl = 'Cannot add the extension when receiving permissions due to:
							           |%1';
							           |tr = 'Uzantı izninin sağlanmasında şu sebeple eklenemedi:
							           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
				EndIf;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Khi nhận quyền được phép, không thể cập nhật phần mở rộng do nguyên nhân:
						           |%1';
						           |ru = 'При получении разрешений не удалось обновить расширение по причине:
						           |%1';
						           |en = 'Cannot update the extension when receiving permissions due to:
						           |%1'; fa = 'Cannot update the extension when receiving permissions due to:
						           |%1';
						           |it = 'При получении разрешений не удалось обновить расширение по причине:
						           |%1';
						           |pl = 'Cannot update the extension when receiving permissions due to:
						           |%1';
						           |tr = 'Uzantı izninin sağlanmasında şu sebeple güncellenemedi:
						           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
			EndIf;
			If RecoveryRequired Then
				Try
					If ExtensionID = Undefined Then
						TemporaryExtension.Delete();
					Else
						TemporaryExtension = FindExtension(ExtensionID);
						If TemporaryExtension = Undefined Then
							TemporaryExtension = ConfigurationExtensions.Create();
						EndIf;
						DisableSecurityWarnings(TemporaryExtension);
						DisableMainRolesUsageForAllUsers(TemporaryExtension);
						TemporaryExtension.Write(UpdatedExtensionData);
					EndIf;
				Except
					ErrorInfo = ErrorInfo();
					If ExtensionID = Undefined Then 
						If PlacedFiles.Count() > 1 Then
							ErrorText = ErrorText + Chars.LF + Chars.LF
								+ StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Khi nhận quyền được phép, không thể xóa phần mở rộng đã thêm từ tệp
									           |%1
									           |do nguyên nhân:
									           |%2';
									           |ru = 'При получении разрешений добавленное расширение из файла не было удалено
									           |%1
									           |по причине:
									           |%2';
									           |en = 'Cannot delete the added extension from the file when receiving permissions
									           |%1
									           |due to:
									           |%2'; fa = 'Cannot delete the added extension from the file when receiving permissions
									           |%1
									           |due to:
									           |%2';
									           |it = 'При получении разрешений добавленное расширение из файла не было удалено
									           |%1
									           |по причине:
									           |%2';
									           |pl = 'Cannot delete the added extension from the file when receiving permissions
									           |%1
									           |due to:
									           |%2';
									           |tr = 'Dosyadan uzantı eklenmesi izninin sağlanmasında şu sebeple 
									           |%1
									           |eklenemedi:
									           |%2'"),
									FileThatWasPut.Name,
									ErrorProcessing.BriefErrorDescription(ErrorInfo));
						Else
							ErrorText = ErrorText + Chars.LF + Chars.LF
								+ StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Đã xảy ra tình huống bất thường khi thử xóa phần mở rộng đã thêm tạm thời:
									           |%1';
									           |ru = 'Возникла непредвиденная ситуация при попытке удалить временно добавленное расширение:
									           |%1';
									           |en = 'An unexpected error occurred when trying to delete the temporarily added extension:
									           |%1'; fa = 'An unexpected error occurred when trying to delete the temporarily added extension:
									           |%1';
									           |it = 'Возникла непредвиденная ситуация при попытке удалить временно добавленное расширение:
									           |%1';
									           |pl = 'An unexpected error occurred when trying to delete the temporarily added extension:
									           |%1';
									           |tr = 'Geçici olarak eklenen uzantıları silmeye çalışırken beklenmedik bir durum yaşandı:
									           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
						EndIf;
					Else
						ErrorText = ErrorText + Chars.LF + Chars.LF
							+ StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Đã xảy ra tình huống bất thường khi thử khôi phục phần mở rộng đã thêm tạm thời:
								           |%1';
								           |ru = 'Возникла непредвиденная ситуация при попытке восстановить временно измененное расширение:
								           |%1';
								           |en = 'An unexpected error occurred when trying to restore the temporarily changed extension:
								           |%1'; fa = 'An unexpected error occurred when trying to restore the temporarily changed extension:
								           |%1';
								           |it = 'Возникла непредвиденная ситуация при попытке восстановить временно измененное расширение:
								           |%1';
								           |pl = 'An unexpected error occurred when trying to restore the temporarily changed extension:
								           |%1';
								           |tr = 'Geçici olarak değişen uzantıları yeniden kurmaya çalışırken beklenmedik bir durum yaşandı:
								           |%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
					EndIf;
				EndTry;
			EndIf;
			Raise ErrorText;
		EndTry;
	EndDo;
	
	InstalledExtensions = ConfigurationExtensions.Get();
	For Each Extension In InstalledExtensions Do
		Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
			Extension.Name, Base64String(Extension.HashSum)));
	EndDo;
	
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(Permissions,
		Common.MetadataObjectID("InformationRegister.ExtensionVersionParameters")));
	
EndProcedure

&AtServer
Procedure DisableSecurityWarnings(Extension)
	
	Catalogs.ExtensionsVersions.DisableSecurityWarnings(Extension);
	
EndProcedure

&AtServer
Procedure DisableMainRolesUsageForAllUsers(Extension)
	
	Catalogs.ExtensionsVersions.DisableMainRolesUsageForAllUsers(Extension);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting ReadOnly appearance parameter for common extensions and extensions passed from the master node to the subordinate DIB node.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExtensionsListAttach.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExtensionsListSafeModeFlag.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExtensionsListPassToSubordinateDIBNodes.Name);
	
	FilterItemsGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterItemGroupCommon = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemGroupCommon.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterItemGroupCommon.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtensionsList.Common");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterItemGroupCommon.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IsSharedUserInArea");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExtensionsList.ReceivedFromMasterDIBNode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtClient
Procedure SetCommandBarButtonAvailability()
	
	If Items.RefreshPages.CurrentPage = Items.TimeConsumingOperationPage Then 
		
		Items.ExtensionsListAdd.Enabled = False;
		Items.ExtensionsListDelete.Enabled = False;
		Items.ExtensionsListUpdateFromFile.Enabled = False;
		
		Items.ExtensionsListContextMenuAdd.Enabled = False;
		Items.ExtensionsListContextMenuDelete.Enabled = False;
		Items.ExtensionsListContextMenuUpdateFromFile.Enabled = False;
		
	ElsIf Items.RefreshPages.CurrentPage = Items.ExtensionsListPage Then 
		
		OneRowSelected = Items.ExtensionsList.SelectedRows.Count() = 1;
		
		CanEdit1 = True;
		If OneRowSelected Then 
			CurrentExtension = Items.ExtensionsList.CurrentData;
			
			CanEdit1 = (Not CurrentExtension.Common 
				Or Not IsSharedUserInArea())
				And Not CurrentExtension.ReceivedFromMasterDIBNode;
		EndIf;
		
		Items.ExtensionsListAdd.Enabled = True;
		Items.ExtensionsListDelete.Enabled = CanEdit1;
		Items.ExtensionsListUpdateFromFile.Enabled = CanEdit1;
		
		Items.ExtensionsListContextMenuAdd.Enabled = True;
		Items.ExtensionsListContextMenuDelete.Enabled = CanEdit1;
		Items.ExtensionsListContextMenuUpdateFromFile.Enabled = OneRowSelected And CanEdit1;
		
		AttachIdleHandler("SetTitleToCommentItem", 0.1, True);

	EndIf;
	
EndProcedure

&AtServerNoContext
Function IsSharedUserInArea()
	
	Return StandardSubsystemsServer.ThisIsSplitSessionModeWithNoDelimiters();
		
EndFunction

&AtServerNoContext
Function ParameterFillingEventName()
	
	Return InformationRegisters.ExtensionVersionParameters.ParameterFillingEventName();
	
EndFunction

&AtServerNoContext
Function ResultOfAllExtensionsApplicabilityCheck()
	
	InfoOnApplyingIssues = ConfigurationExtensions.CheckCanApplyAll();
	
	Result = New Structure;
	Result.Insert("IssuesCount", InfoOnApplyingIssues.Count());
	Result.Insert("InfoOnIssues", New TextDocument);

	If InfoOnApplyingIssues.Count() = 0 Then
		Return Result;
	EndIf;
	
	ProblematicExtensions = New Map;
	
	For Each Issue1 In InfoOnApplyingIssues Do
		InfoOnIssue = ProblematicExtensions.Get(Issue1.Extension);
		If InfoOnIssue = Undefined Then
			Text = Issue1.Extension.Synonym;
		Else
			Text = InfoOnIssue;
		EndIf;
		Text = Text + Chars.LF + Chars.Tab + "(" + String(Issue1.Severity) + ")" + " " + Issue1.Description;
		ProblematicExtensions.Insert(Issue1.Extension, Text);
	EndDo;
	
	For Each Extension In ProblematicExtensions Do
		Result.InfoOnIssues.AddLine(Extension.Value);
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure EnableSafeModeCompletion()
	
	ExtensionsModificationErrors = New Array;
	ToggleSafeModeForSelectedExtensions(True, ExtensionsModificationErrors);
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors);
	
EndProcedure

&AtClient
Procedure DisableSafeModeCompletion()
	
	ExtensionsModificationErrors = New Array;
	ToggleSafeModeForSelectedExtensions(False, ExtensionsModificationErrors);
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors);
	
EndProcedure

&AtServer
Procedure ToggleSafeModeForSelectedExtensions(Value, ExtensionsModificationErrors)
	
	For Each RowID In Items.ExtensionsList.SelectedRows Do
		ListLine = ExtensionsList.FindByID(RowID);
		If ListLine = Undefined Then
			Continue;
		EndIf;
		
		ListLine.SafeModeFlag = Value;
		
		Extension = FindExtension(ListLine.ExtensionID);
		
		If Extension = Undefined
			Or Extension.SafeMode = ListLine.SafeModeFlag Then
			Continue;
		EndIf;
		
		Extension.SafeMode = ListLine.SafeModeFlag;
		DisableSecurityWarnings(Extension);
		DisableMainRolesUsageForAllUsers(Extension);
		Try
			Extension.Write();
		Except
			ListLine.SafeModeFlag = Not ListLine.SafeModeFlag;
			IssueDetails = ListLine.Synonym + ": " + ErrorProcessing.BriefErrorDescription(ErrorInfo());
			ExtensionsModificationErrors.Add(IssueDetails);
		EndTry;
		
	EndDo;
	
	InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
	
EndProcedure

&AtClient
Procedure OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors)
	If ExtensionsModificationErrors.Count() = 0 Then
		Return;
	EndIf;
	
	ErrorInformation_ = "";
	For Each StringError In ExtensionsModificationErrors Do
		ErrorInformation_ = ?(ValueIsFilled(ErrorInformation_), ErrorInformation_ + Chars.LF + Chars.LF + StringError, StringError);
	EndDo;
	
	QuestionFormParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionFormParameters.Picture = PictureLib.DialogExclamation;
	QuestionFormParameters.PromptDontAskAgain = False;
	QuestionFormParameters.Title = NStr("vi = 'Không phải tất cả các phần mở rộng đều có thể được cấu hình lại';
										|ru = 'Не все расширения удалось перенастроить';
										|en = 'Failed to reconfigure some extensions'; fa = 'Failed to reconfigure some extensions';
										|it = 'Не все расширения удалось перенастроить';
										|pl = 'Failed to reconfigure some extensions';
										|tr = 'Tüm uzantılar yeniden yapılandırılamadı'");
	StandardSubsystemsClient.ShowQuestionToUser(Undefined,
		ErrorInformation_,
		QuestionDialogMode.OK,
		QuestionFormParameters);
	
EndProcedure

&AtClient
Procedure EnableTransferToSubordinateDIBNodesCompletion()
	
	ExtensionsModificationErrors = New Array;
	ToggleTransferToSubordinateDIBNodes(True, ExtensionsModificationErrors);
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors);
	
EndProcedure

&AtClient
Procedure DisableTransferToSubordinateDIBNodesCompletion()
	
	ExtensionsModificationErrors = New Array;
	ToggleTransferToSubordinateDIBNodes(False, ExtensionsModificationErrors);
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors);
	
EndProcedure

&AtServer
Procedure ToggleTransferToSubordinateDIBNodes(Value, ExtensionsModificationErrors)
	
	For Each RowID In Items.ExtensionsList.SelectedRows Do
		ListLine = ExtensionsList.FindByID(RowID);
		If ListLine = Undefined Then
			Continue;
		EndIf;
		
		ListLine.PassToSubordinateDIBNodes = Value;
		
		Extension = FindExtension(ListLine.ExtensionID);
		
		If Extension = Undefined
			Or Extension.UsedInDistributedInfoBase = ListLine.PassToSubordinateDIBNodes Then
			Continue;
		EndIf;
		
		Extension.UsedInDistributedInfoBase = ListLine.PassToSubordinateDIBNodes;
		DisableSecurityWarnings(Extension);
		DisableMainRolesUsageForAllUsers(Extension);
		Try
			Extension.Write();
		Except
			ListLine.PassToSubordinateDIBNodes = Not ListLine.PassToSubordinateDIBNodes;
			IssueDetails = ListLine.Synonym + ": " + ErrorProcessing.BriefErrorDescription(ErrorInfo());
			ExtensionsModificationErrors.Add(IssueDetails);
		EndTry;
		
	EndDo;
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure EnableAttachExtensions()
	
	ExtensionsModificationErrors = New Array;
	ToggleAttachExtensions(True, ExtensionsModificationErrors);
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors);
	
EndProcedure

&AtClient
Procedure DisableAttachExtensions()
	
	ExtensionsSynonyms = ExtensionsSynonymsSelectedExtensionsToDisable();
	If ExtensionsSynonyms.WithData.Count() = 1 And ExtensionsSynonyms.NoData.Count() = 0 Then
		
		CurrentExtension = Items.ExtensionsList.CurrentData;
		If CurrentExtension = Undefined Then
			Return;
		EndIf;
		CurrentExtension.Attach = False;
		Context = New Structure;
		Context.Insert("RowID", CurrentExtension.GetID());
	
		Notification = New CallbackDescription("DetachExtensionAfterConfirmation", ThisObject, Context);
		UsersInternalClient.ShowSecurityWarning(Notification,
			UsersInternalClientServer.SecurityWarningKinds().BeforeDisableExtensionWithData);

	ElsIf ExtensionsSynonyms.WithData.Count() > 0 Then
		
		If ExtensionsSynonyms.WithData.Count() = 1 Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong số các phần mở rộng bị vô hiệu hóa có một phần mở rộng lưu trữ dữ liệu trong ứng dụng mà sẽ không thể truy cập được.
				           |Ngoài ra, một số dữ liệu của chính ứng dụng cũng có thể không thể thay đổi được.
				           |
				           |Phần mở rộng có dữ liệu:
				           | - %1';
				           |ru = 'Среди отключаемых расширений есть расширение, хранящее данные в приложении, которые станут недоступными.
				           |Кроме того, некоторые данные самого приложения могут тоже стать недоступными для изменения.
				           |
				           |Расширение с данными:
				           | - %1';
				           |en = 'One of the selected extensions stores its data in the application. This data will become unavailable.
				           |The related application data might become unchangeable.
				           |
				           |The extension with data:
				           | - %1'; fa = 'One of the selected extensions stores its data in the application. This data will become unavailable.
				           |The related application data might become unchangeable.
				           |
				           |The extension with data:
				           | - %1';
				           |it = 'Среди отключаемых расширений есть расширение, хранящее данные в приложении, которые станут недоступными.
				           |Кроме того, некоторые данные самого приложения могут тоже стать недоступными для изменения.
				           |
				           |Расширение с данными:
				           | - %1';
				           |pl = 'One of the selected extensions stores its data in the application. This data will become unavailable.
				           |The related application data might become unchangeable.
				           |
				           |The extension with data:
				           | - %1';
				           |tr = 'Devre dışı bırakılan uzantılar arasında, uygulamada veri saklayan ve erişilemez hale gelecek bir uzantı bulunmaktadır.
				           |Ayrıca uygulamanın kendisine ait bazı veriler de değişiklik için kullanılamayabilir.
				           |
				           |Veri içeren uzantı:
				           | - %1'"),
				ExtensionsSynonyms.WithData[0]);
		Else
			ExtensionsWithDataText = StrConcat(ExtensionsSynonyms.WithData, Chars.LF + " - ");
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong số các phần mở rộng bị vô hiệu hóa có một phần mở rộng lưu trữ dữ liệu trong ứng dụng mà sẽ không thể truy cập được.
				           |Ngoài ra, một số dữ liệu của chính ứng dụng cũng có thể không thể thay đổi được.
				           |
				           |Phần mở rộng có dữ liệu:
				           | - %1';
				           |ru = 'Среди отключаемых расширений есть расширения, хранящие данные в приложении, которые станут недоступными.
				           |Кроме того, некоторые данные самого приложения могут тоже стать недоступными для изменения.
				           |
				           |Расширения с данными:
				           | - %1';
				           |en = 'Some selected extensions store their data in the application. This data will become unavailable.
				           |The related application data might become unchangeable.
				           |
				           |Extensions with data:
				           | - %1'; fa = 'Some selected extensions store their data in the application. This data will become unavailable.
				           |The related application data might become unchangeable.
				           |
				           |Extensions with data:
				           | - %1';
				           |it = 'Среди отключаемых расширений есть расширения, хранящие данные в приложении, которые станут недоступными.
				           |Кроме того, некоторые данные самого приложения могут тоже стать недоступными для изменения.
				           |
				           |Расширения с данными:
				           | - %1';
				           |pl = 'Some selected extensions store their data in the application. This data will become unavailable.
				           |The related application data might become unchangeable.
				           |
				           |Extensions with data:
				           | - %1';
				           |tr = 'Devre dışı bırakılan uzantılar arasında, uygulamada veri depolayan ve erişilemez hale gelecek uzantılar vardır.
				           |Ayrıca uygulamanın kendi verileri de değişiklik için kullanılamaz hale gelebilir.
				           |
				           |Veri içeren uzantılar:
				           | - %1'"),
				ExtensionsWithDataText);
		EndIf;
			
		CompletionHandler = New CallbackDescription(
			"DisableExtensionsAfterQuestion", ThisObject);
		
		Buttons = New ValueList;
		If ExtensionsSynonyms.NoData.Count() > 0 Then
			Buttons.Add("TurnOffExtensionsWithoutData", NStr("vi = 'Tắt sử dụng chỉ phần mở rộng không có dữ liệu';
															|ru = 'Отключить только расширения без данных';
															|en = 'Disabled only extensions without stored data'; fa = 'Disabled only extensions without stored data';
															|it = 'Отключить только расширения без данных';
															|pl = 'Disabled only extensions without stored data';
															|tr = 'Yalnızca veri içermeyen uzantıları devre dışı bırak'"));
			
			If ExtensionsSynonyms.NoData.Count() = 1 Then
				ExtensionsWithoutDataText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Phần mở rộng không có dữ liệu:
			           | - %1';
			           |ru = 'Расширение без данных:
			           | - %1';
			           |en = 'An extension without stored data:
			           | - %1'; fa = 'An extension without stored data:
			           | - %1';
			           |it = 'Расширение без данных:
			           | - %1';
			           |pl = 'An extension without stored data:
			           | - %1';
			           |tr = 'Veri içermeyen uzantı:
			           | - %1'"),
					ExtensionsSynonyms.NoData[0]);
			Else
				ExtensionsWithoutDataText = StrConcat(ExtensionsSynonyms.NoData, Chars.LF + " - ");
				ExtensionsWithoutDataText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Phần mở rộng không có dữ liệu:
			           | - %1';
			           |ru = 'Расширения без данных:
			           | - %1';
			           |en = 'Extensions without stored data:
			           | - %1'; fa = 'Extensions without stored data:
			           | - %1';
			           |it = 'Расширения без данных:
			           | - %1';
			           |pl = 'Extensions without stored data:
			           | - %1';
			           |tr = 'Veri içermeyen uzantılar:
			           | - %1'"), 
					ExtensionsWithoutDataText);
			EndIf;
			QueryText = QueryText + Chars.LF + Chars.LF + ExtensionsWithoutDataText;
		EndIf;
		Buttons.Add("TurnOffAll", NStr("vi = 'Tắt sử dụng tất cả';
										|ru = 'Отключить все';
										|en = 'Disable all'; fa = 'غیرفعال کردن همه';
										|it = 'Отключить все';
										|pl = 'Disable all';
										|tr = 'Hepsini devre dışı bırak'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Отмена';
									|pl = 'Cancel';
									|tr = 'İptal'"));
		
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.Title = NStr("vi = 'Cảnh báo';
										|ru = 'Предупреждение';
										|en = 'Warning'; fa = 'هشدار';
										|it = 'Предупреждение';
										|pl = 'Warning';
										|tr = 'Uyarı'");
		QuestionParameters.Picture = PictureLib.DialogExclamation;
		QuestionParameters.DefaultButton = "TurnOffExtensionsWithoutData";
		QuestionParameters.PromptDontAskAgain = False;
		
		StandardSubsystemsClient.ShowQuestionToUser(CompletionHandler,
			QueryText, Buttons, QuestionParameters);
			
	Else
		ExtensionsModificationErrors = New Array;
		ToggleAttachExtensions(False, ExtensionsModificationErrors);
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors);
	EndIf;
	
EndProcedure

&AtServer
Procedure ToggleAttachExtensions(Value, ExtensionsModificationErrors, ShouldHandleExtensionsContainingData = True)
	
	For Each RowID In Items.ExtensionsList.SelectedRows Do
		ListLine = ExtensionsList.FindByID(RowID);
		If ListLine = Undefined Then
			Continue;
		EndIf;
		
		If Not ShouldHandleExtensionsContainingData And IsExtensionWithData(ListLine.ExtensionID) Then
			Continue;
		EndIf;
		
		ListLine.Attach = Value;
		
	Try
		Catalogs.ExtensionsVersions.ToggleExtensionUsage(ListLine.ExtensionID, Value);
	Except
		ListLine.Attach = Not ListLine.Attach;
		IssueDetails = ListLine.Synonym + ": " + ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ExtensionsModificationErrors.Add(IssueDetails);
	EndTry;
		
	EndDo;
	
	UpdateList();
	
EndProcedure

&AtServer
Function ExtensionsSynonymsSelectedExtensionsToDisable()
	
	WithData = New Array;
	NoData = New Array;
	
	For Each RowID In Items.ExtensionsList.SelectedRows Do
		ListLine = ExtensionsList.FindByID(RowID);
		If ListLine = Undefined And ListLine.Attach Then
			Continue;
		EndIf;
		If IsExtensionWithData(ListLine.ExtensionID) Then
			WithData.Add(ListLine.Synonym);
		Else
			NoData.Add(ListLine.Synonym);
		EndIf;
	EndDo;
	
	ExtensionsSynonyms = New Structure;
	ExtensionsSynonyms.Insert("WithData", WithData);
	ExtensionsSynonyms.Insert("NoData", NoData);
	
	Return ExtensionsSynonyms;
	
EndFunction

&AtClient
Procedure DisableExtensionsAfterQuestion(Result, Context) Export
	
	If Result = Undefined Or Result.Value = "Cancel" Then
		AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
		Return;
	ElsIf Result.Value = "TurnOffExtensionsWithoutData" Then
		ShouldHandleExtensionsContainingData = False;
	ElsIf Result.Value = "TurnOffAll" Then
		ShouldHandleExtensionsContainingData = True;
	EndIf;
		
	ExtensionsModificationErrors = New Array;
	ToggleAttachExtensions(False, ExtensionsModificationErrors, ShouldHandleExtensionsContainingData);
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	OutputErrorsInfoOnExtensionsReconfiguration(ExtensionsModificationErrors);
	
EndProcedure

&AtServerNoContext
Procedure SaveExtensionsProperties(ExtensionID, ExtensionProperties)
	InformationRegisters.ExtensionProperties.SaveExtensionsProperties(ExtensionID, ExtensionProperties);
EndProcedure

&AtClientAtServerNoContext
Function ExtensionProperties(CurrentExtension)
	
	Properties = New Structure;
	Properties.Insert("EmployeeResponsible", CurrentExtension.EmployeeResponsible);
	Properties.Insert("Comment", CurrentExtension.Comment);
	
	Return Properties;
	
EndFunction

&AtServer
Procedure UpdateExtensionsPropertiesInList()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Extensions.ExtensionID AS ExtensionID
		|INTO ExtensionsIDs
		|FROM
		|	&ExtensionsList AS Extensions
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ExtensionProperties.EmployeeResponsible AS EmployeeResponsible,
		|	ExtensionProperties.Comment AS Comment,
		|	ExtensionsIDs.ExtensionID AS ExtensionID
		|FROM
		|	ExtensionsIDs AS ExtensionsIDs
		|		INNER JOIN InformationRegister.ExtensionProperties AS ExtensionProperties
		|		ON ExtensionsIDs.ExtensionID = ExtensionProperties.ExtensionID";
	
	Query.SetParameter("ExtensionsList", ExtensionsList.Unload());
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		StructureForSearch = New Structure;
		StructureForSearch.Insert("ExtensionID", Selection.ExtensionID);
		ExtensionsStrings = ExtensionsList.FindRows(StructureForSearch);
		FillPropertyValues(ExtensionsStrings[0], Selection);
		ExtensionsStrings[0].HasComment = ValueIsFilled(ExtensionsStrings[0].Comment);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetTitleToCommentItem()
	
	If Items.ExtensionsList.CurrentData = Undefined Then
		 Return;
	EndIf;
	
	Items.ExtensionsListComment.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ghi chú đối với %1';
			|ru = 'Комментарий для %1';
			|en = 'Comment for %1'; fa = 'Comment for %1';
			|it = 'Комментарий для %1';
			|pl = 'Comment for %1';
			|tr = '%1 için yorum'"), Items.ExtensionsList.CurrentData.Synonym);
		
EndProcedure

&AtClient
Procedure SetAssigneeAfterSelection(EmployeeResponsible, AdditionalParameters) Export
	
	If EmployeeResponsible = Undefined Then
		Return;
	EndIf;
	
	SetAssigneeOnSelectedExtensions(EmployeeResponsible);
	
EndProcedure

&AtServer
Procedure SetAssigneeOnSelectedExtensions(EmployeeResponsible)
	
	For Each RowID In Items.ExtensionsList.SelectedRows Do
		ListLine = ExtensionsList.FindByID(RowID);
		If ListLine = Undefined Then
			Continue;
		EndIf;
		ListLine.EmployeeResponsible = EmployeeResponsible;
		SaveExtensionsProperties(ListLine.ExtensionID, ExtensionProperties(ListLine));
	EndDo;
	
EndProcedure

&AtServerNoContext
Function IsInfobaseExclusiveLockError(ErrorText)
	ExclusiveLockErrorText = NStr("vi = 'Lỗi phong tỏa ngoại lệ cơ sở thông tin';
									|ru = 'Ошибка исключительной блокировки информационной базы';
									|en = 'Error setting an exclusive lock'; fa = 'Error setting an exclusive lock';
									|it = 'Ошибка исключительной блокировки информационной базы';
									|pl = 'Error setting an exclusive lock';
									|tr = 'İnfobase''i özel kilitleme hatası'");
	Return (StrFind(ErrorText, ExclusiveLockErrorText) <> 0);
EndFunction

&AtClient
Procedure ToOpenTheFormCompleteTheUserExperience()

	If ExtensionsToReAdd.Count() = 0 Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
		Notification = New CallbackDescription("AfterSettingTheExclusiveMode", ThisObject);
		ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");

		FormParameters = ModuleIBConnectionsClient.ExclusiveModeSetErrorFormOpenParameters();
		ItemsToImportCount = ExtensionsToReAdd.Count();
		FormParameters.Title = ?(ItemsToImportCount = 1,
			NStr("vi = 'Không thể thêm phần mở rộng';
				|ru = 'Не удалось добавить расширение';
				|en = 'Couldn''t add extension'; fa = 'Couldn''t add extension';
				|it = 'Не удалось добавить расширение';
				|pl = 'Couldn''t add extension';
				|tr = 'Uzantı eklenemedi'"), NStr("vi = 'Không thể thêm phần mở rộng';
														|ru = 'Не удалось добавить расширения';
														|en = 'Couldn''t add extensions'; fa = 'Couldn''t add extensions';
														|it = 'Не удалось добавить расширения';
														|pl = 'Couldn''t add extensions';
														|tr = 'Uzantılar eklenemedi'"));
		FormParameters.ErrorMessageText = ?(ItemsToImportCount = 1, 
			NStr("vi = 'Không thể thêm phần mở rộng, bởi vì người sử dụng đang làm việc với ứng dụng.';
				|ru = 'Не удалось добавить расширение, т.к. с приложением работают пользователи.';
				|en = 'Couldn''t add extension: active users detected'; fa = 'Couldn''t add extension: active users detected';
				|it = 'Не удалось добавить расширение, т.к. с приложением работают пользователи.';
				|pl = 'Couldn''t add extension: active users detected';
				|tr = 'Uzantı eklenemedi çünkü... Kullanıcılar uygulamayla çalışmaktadır.'"),
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thêm phần mở rộng (%1), bởi vì người sử dụng đang làm việc với ứng dụng.';
				|ru = 'Не удалось добавить расширения (%1), т.к. с приложением работают пользователи.';
				|en = 'Couldn''t add extensions (%1): active users detected'; fa = 'Couldn''t add extensions (%1): active users detected';
				|it = 'Не удалось добавить расширения (%1), т.к. с приложением работают пользователи.';
				|pl = 'Couldn''t add extensions (%1): active users detected';
				|tr = 'Uzantılar (%1) eklenemedi çünkü kullanıcılar uygulamayla çalışmaktadır.'"), ItemsToImportCount));
		FormParameters.ErrorTextExitFailed = ?(ItemsToImportCount = 1, 
			NStr("vi = 'Không thể thực hiện thêm phần mở rộng, bởi vì không thể kết thúc công việc của người sử dụng:';
				|ru = 'Невозможно выполнить добавление расширения, т.к. не удалось завершить работу пользователей:';
				|en = 'Couldn''t add extensions. Failed to terminate the user sessions:'; fa = 'Couldn''t add extensions. Failed to terminate the user sessions:';
				|it = 'Невозможно выполнить добавление расширения, т.к. не удалось завершить работу пользователей:';
				|pl = 'Couldn''t add extensions. Failed to terminate the user sessions:';
				|tr = 'Kullanıcılar sonlandırılamadığı için uzantı eklenemiyor:'"),
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thực hiện thêm phần mở rộng (%1), bởi vì không thể kết thúc công việc của người sử dụng:';
				|ru = 'Невозможно выполнить добавление расширений (%1), т.к. не удалось завершить работу пользователей:';
				|en = 'Couldn''t add extensions (%1). Failed to terminate the user sessions:'; fa = 'Couldn''t add extensions (%1). Failed to terminate the user sessions:';
				|it = 'Невозможно выполнить добавление расширений (%1), т.к. не удалось завершить работу пользователей:';
				|pl = 'Couldn''t add extensions (%1). Failed to terminate the user sessions:';
				|tr = 'Kullanıcılar sonlandırılamadığı için uzantılar(%1) eklenemiyor:'"), ItemsToImportCount));
		FormParameters.LoginMessage = NStr("vi = 'Đã phong tỏa ứng dụng để thêm phần mở rộng.';
											|ru = 'Приложение заблокировано для добавления расширения.';
											|en = 'Cannot add extensions while the app is being used.'; fa = 'Cannot add extensions while the app is being used.';
											|it = 'Приложение заблокировано для добавления расширения.';
											|pl = 'Cannot add extensions while the app is being used.';
											|tr = 'Uygulamanın uzantı eklemesi engellendi.'");
		FormParameters.ShouldCloseAllSessionsButCurrent = True;
		FormParameters.ShouldCloseDesignerSession = True;
		FormParameters.BlockingPeriod = 60;
		
		ModuleIBConnectionsClient.OnOpenExclusiveModeSetErrorForm(Notification, FormParameters);
	Else
		StandardSubsystemsClient.OpenActiveUserList();
	EndIf;

EndProcedure

&AtClient
Procedure AfterSettingTheExclusiveMode(Result, AdditionalParameters) Export
	If Result = False Then // The exclusive mode is set.
		ShowTimeConsumingOperation();
		AttachIdleHandler("ReAddExtensionWithData", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure ReAddExtensionWithData()
	
	If ExtensionsToReAdd = Undefined Then
		Return;
	EndIf;
	
	UnattachedExtensions = "";
	ExtensionsChanged = False;
	NameReplacementConfirmation = New Structure("OldName, NewName", "", "");
	ChangeExtensionsAtServer(ExtensionsToReAdd.UnloadValues(), Undefined, UnattachedExtensions,
		ExtensionsChanged, NameReplacementConfirmation);
		
	AttachIdleHandler("HideTimeConsumingOperation", 0.1, True);
	If ExtensionsToReAdd.Count() > 0 Then
		ToOpenTheFormCompleteTheUserExperience();
	EndIf;
	
EndProcedure

#EndRegion