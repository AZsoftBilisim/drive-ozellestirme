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
Var AdministrationParameters;

&AtClient
Var PatchesFiles; // Array of TransferableFileDescription

&AtClient
Var FirstOpeningOfForm; // Boolean

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ConfigurationUpdate.HasRightsToInstallUpdate() Then
		Raise(NStr("vi = 'Không đủ quyền để cập nhật cấu hình. Hãy liên hệ với người quản trị.';
					|ru = 'Недостаточно прав для обновления приложения. Обратитесь к администратору.';
					|en = 'Insufficient rights to update the application. Please contact the administrator.'; fa = 'Insufficient rights to update the application. Please contact the administrator.';
					|it = 'Недостаточно прав для обновления приложения. Обратитесь к администратору.';
					|pl = 'Insufficient rights to update the application. Please contact the administrator.';
					|tr = 'Yapılandırmayı güncellemek için yetersiz haklar. Yöneticinize başvurun.'"),
			ErrorCategory.AccessViolation);
	ElsIf Users.IsExternalUserSession() Then
		Raise(NStr("vi = 'Không đủ quyền truy cập.';
					|ru = 'Недостаточно прав доступа.';
					|en = 'Insufficient access rights.'; fa = 'حقوق دسترسی ناکافی.';
					|it = 'Diritti di accesso insufficienti.';
					|pl = 'Niewystarczające uprawnienia dostępu.';
					|tr = 'Yetersiz erişim hakı.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	If Not Common.IsWindowsClient() Then
		Return; // Cancel is set in OnOpen().
	EndIf;
	
	IsFileInfobase = Common.FileInfobase();
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	
	// If it is the first start after a configuration update, storing and resetting status.
	Object.UpdateResult = ConfigurationUpdate.ConfigurationUpdateSuccessful(ScriptDirectory);
	If Object.UpdateResult <> Undefined Then
		ConfigurationUpdate.ResetConfigurationUpdateStatus();
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		Items.EmailPanel.Visible = False;
	EndIf;
	
	UncompletedHandlersStatus = InfobaseUpdateInternal.UncompletedHandlersStatus();
	Items.LabelUnfinishedHandlers.Visible = ValueIsFilled(UncompletedHandlersStatus);
	
	Items.IssuesDiscoveredLabel.Visible = SystemCheckIssues();
	Items.ExtensionsAvailableLabel.Visible     = ConfigurationUpdate.WarnAboutExistingExtensions();
	
	Items.WarningsPanel.Visible = Items.IssuesDiscoveredLabel.Visible
		Or Items.ExtensionsAvailableLabel.Visible;
	
	// Checking every time the wizard is opened.
	ConfigurationChanged = ConfigurationChanged();
	LoadExtensions = LoadExtensionsThatChangeDataStructure();
	IsWebClient = Common.IsWebClient() Or Common.ClientConnectedOverWebServer();
	UpdateFileRequired = ?((ConfigurationChanged Or LoadExtensions) And Not IsWebClient, 0, 1);
	
	If Parameters.ShouldExitApp Then
		Items.UpdateRadioButtonsFile.Visible = False;
		Items.UpdateRadioButtonsServer.Visible = False;
		Items.UpdateDateTimeField.Visible = False;
		Items.ClickNextLabel.Visible = True;
	EndIf;
	
	If Parameters.IsConfigurationUpdateReceived Then
		Items.UpdateMethodFilePages.CurrentPage = Items.UpdateReceivedFromApplicationFilePage;
	EndIf;
	
	Items.ConfigurationIsUpdatedDuringDataExchangeWithMainNodeLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.ConfigurationIsUpdatedDuringDataExchangeWithMainNodeLabel.Title, ExchangePlans.MasterNode());
	
	SetPrivilegedMode(True);
	
	If IsBlankString(Parameters.SelectedFiles) Then 
		RestoreConfigurationUpdateSettings();
	Else 
		SelectedFiles = Parameters.SelectedFiles;
		ShowInstalledPatches = True;
	EndIf;
	
	If IsFileInfobase And Object.UpdateMode > 1 Or Parameters.ShouldExitApp Then
		Object.UpdateMode = 0;
	EndIf;
	
	Items.FindAndInstallUpdates.Visible = Common.SubsystemExists("OnlineUserSupport.GetApplicationUpdates");
	
	If IsWebClient Or IsSubordinateDIBNode Then
		SelectionOptionTitle = NStr("vi = 'Hãy chỉ ra tệp sửa lỗi:';
									|ru = 'Укажите файл исправлений:';
									|en = 'Specify a patch file:'; fa = 'Specify a patch file:';
									|it = 'Specificare il file di patch:';
									|pl = 'Określ plik korekt:';
									|tr = 'Düzeltme dosyasını belirtin:'");
		Items.UpdateFileRequiredRadioButtons.ChoiceList[1].Presentation = SelectionOptionTitle;
	EndIf;
	
	FillInformationPanel();
	
	NotificationInterval = 5;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Result = ConfigurationUpdateClient.UpdatesInstallationSupported();
	If Not Result.Supported
		And Not Result.InstallationOfPatchesIsSupported Then
		
		Items.PageGroupMain.CurrentPage = Items.PageUnavailable;
		Items.FormClose.Visible = True;
		Items.LabelUnavailable.Title = Result.ErrorDescription;
		Return;
	EndIf;
	
	FirstOpeningOfForm = True;
	
	DescriptionOfTheSelectedFiles = ?(ValueIsFilled(PatchesFilesAsString), PatchesFilesAsString, SelectedFiles);
	InitializePatchFiles(DescriptionOfTheSelectedFiles);
	
	If Parameters.RunUpdate Then
		ProceedToUpdateModeSelection();
		Return;
	EndIf;
	
	Pages    = Items.WizardPages.ChildItems;
	PageName = Pages.UpdateFile.Name;
	
	If IsSubordinateDIBNode Then
		If ConfigurationChanged Or LoadExtensions Then
			ProceedToUpdateModeSelection();
			Return;
		EndIf;
	EndIf;
	
	BeforeOpenPage(Pages[PageName]);
	Items.WizardPages.CurrentPage = Pages[PageName];
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.ActiveUsers.Form.ActiveUsers") Then
		UpdateConnectionsInformation();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "LegitimateSoftware" And Not Parameter Then
		HandleBackButtonClick();
	ElsIf EventName = "AccountingAuditSuccessfulCheck" Then
		FillInformationPanel();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EventLogClient.WriteEventsToEventLog();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region UpdateFilePage

&AtClient
Procedure UpdateFileRequiredRadioButtonsOnChange(Item)
	BeforeOpenPage();
EndProcedure

&AtClient
Procedure UpdateFileFieldStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	AttachIdleHandler("SelectUpdateFile", 0.1, True);
	
EndProcedure

#EndRegion

#Region AfterInstallUpdatesPage

&AtClient
Procedure ActiveUsersDecorationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure PatchInstallationErrorLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	LogFilter = New Structure;
	LogFilter.Insert("EventLogEvent", NStr("vi = 'Chỉnh sửa.Thiết lập';
											|ru = 'Исправления.Установка';
											|en = 'Patch.Install'; fa = 'Patch.Install';
											|it = 'Rettifiche.Installazione';
											|pl = 'Patch.Install';
											|tr = 'Düzeltmeler.Kurulum'"));
	EventLogClient.OpenEventLog(LogFilter);
EndProcedure

#EndRegion

#Region SelectUpdateModePageFile

&AtClient
Procedure ActionsListLabelClick(Item)
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure ActionsListLabel1Click(Item)
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure ActionsListLabel3Click(Item)
	ShowActiveUsers();
EndProcedure

&AtClient
Procedure BackupLabelClick(Item)
	
	BackupParameters = New Structure;
	BackupParameters.Insert("CreateDataBackup",           Object.CreateDataBackup);
	BackupParameters.Insert("IBBackupDirectoryName",       Object.IBBackupDirectoryName);
	BackupParameters.Insert("RestoreInfobase", Object.RestoreInfobase);
	
	CallbackDescription = New CallbackDescription("AfterCloseBackupForm", ThisObject);
	ConfigurationUpdateClient.ShowBackup(BackupParameters, CallbackDescription);
	
EndProcedure

&AtClient
Procedure AfterCloseBackupForm(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		FillPropertyValues(Object, Result);
		Items.BackupFileLabel.Title = ConfigurationUpdateClient.BackupCreationTitle(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectUpdateModePageServer

&AtClient
Procedure UpdateRadioButtonsOnChange(Item)
	BeforeOpenPage();
EndProcedure

&AtClient
Procedure EmailReportOnChange(Item)
	BeforeOpenPage();
EndProcedure

&AtClient
Procedure DeferredHandlersLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	InfobaseUpdateClient.ShowUpdateResults();
	
EndProcedure

&AtClient
Procedure IssuesDiscoveredLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternalClient = CommonClient.CommonModule("AccountingAuditInternalClient");
		ModuleAccountingAuditInternalClient.OpenIssuesReportFromUpdateProcessing(ThisObject, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If CommonClient.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternalClient = CommonClient.CommonModule("AccountingAuditInternalClient");
		ModuleAccountingAuditInternalClient.OpenAccountingChecksList();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtensionsAvailableLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	OpenForm("CommonForm.Extensions");
EndProcedure

&AtServer
Function SystemCheckIssues()
	
	If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternal = Common.CommonModule("AccountingAuditInternal");
		Return ModuleAccountingAuditInternal.SystemCheckIssues();
	EndIf;
	Return False;
	
EndFunction

&AtClient
Procedure RestartApplicationOnChange(Item)
	
	If RestartApplication Then
		Items.NextButton.Title = NStr("vi = 'Khởi động lại';
										|ru = 'Перезапустить';
										|en = 'Restart'; fa = 'راه‌اندازی مجدد';
										|it = 'Перезапустить';
										|pl = 'Restart';
										|tr = 'Yeniden başlat'");
	Else
		Items.NextButton.Title = NStr("vi = 'Đồng ý';
										|ru = 'Готово';
										|en = 'Finish'; fa = 'پایان';
										|it = 'Готово';
										|pl = 'Finish';
										|tr = 'Bitti'");
	EndIf;

EndProcedure

&AtClient
Procedure DecorationNotifyUsersURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	ChoiceList = New ValueList;
	ChoiceList.Add("5", NStr("vi = '5 phút';
							|ru = '5 минут';
							|en = '5 minutes'; fa = '5 دقیقه';
							|it = '5 minuti';
							|pl = '5 minut';
							|tr = '5 dakika'"));
	ChoiceList.Add("10", NStr("vi = '10 phút';
								|ru = '10 минут';
								|en = '10 minutes'; fa = '10 دقیقه';
								|it = '10 minuti';
								|pl = '10 minut';
								|tr = '10 dakika'"));
	ChoiceList.Add("15", NStr("vi = '15 phút';
								|ru = '15 минут';
								|en = '15 minutes'; fa = '15 دقیقه';
								|it = '15 minuti';
								|pl = '15 minut';
								|tr = '15 dakika'"));
	ChoiceList.Add("30", NStr("vi = '30 phút';
								|ru = '30 минут';
								|en = '30 minutes'; fa = '30 دقیقه';
								|it = '30 minuti';
								|pl = '30 minut';
								|tr = '30 dakika'"));
	
	Notification = New CallbackDescription("AfterNotificationIntervalSelected", ThisObject);
	ShowChooseFromMenu(Notification, ChoiceList, Items.DecorationForSubmenu);
EndProcedure

&AtClient
Procedure ShouldNotifyUsersOnChange(Item)
	Items.DecorationNotifyUsers.Enabled = ShouldNotifyUsers;
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure BackButtonClick(Command)
	HandleBackButtonClick();
EndProcedure

&AtClient
Procedure NextButtonClick(Command)
	HandleNextButtonClick();
EndProcedure

&AtClient
Procedure FindAndInstallUpdates(Command)
	
	If CommonClient.SubsystemExists("OnlineUserSupport.GetApplicationUpdates") Then
		Close();
		ModuleGetApplicationUpdatesClient = CommonClient.CommonModule("GetApplicationUpdatesClient");
		ModuleGetApplicationUpdatesClient.UpdateProgram();
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInformationPanel()
	
	Visible = False;
	If Common.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditInternal = Common.CommonModule("AccountingAuditInternal");
		Information = ModuleAccountingAuditInternal.AccountingSystemChecksInformation();
		If Information.WarnSecondCheckRequired Then
			If ValueIsFilled(Information.LastCheckDate) Then
				ToolTip = NStr("vi = 'Kiểm tra hệ thống lần cuối được thực hiện trên %1.';
								|ru = 'Последняя системная проверка выполнялась %1.';
								|en = 'Last system check was on %1.'; fa = 'Last system check was on %1.';
								|it = 'L''ultima verifica di sistema è stata eseguita %1.';
								|pl = 'Ostatnia weryfikacja systemowa była wykonywana %1.';
								|tr = 'Son sistem kontrolü yapıldı%1.'");
				ToolTip = StringFunctionsClientServer.SubstituteParametersToString(ToolTip, 
					Format(Information.LastCheckDate, "DLF=D"));
			Else
				ToolTip = "";
			EndIf;
			Items.InformationLabel.ExtendedTooltip.Title = ToolTip;
			Visible = True;
		EndIf;
	EndIf;
	Items.InformationPanel.Visible = Visible;
EndProcedure

&AtClient
Procedure BeforeOpenPage(Val NewPage = Undefined)
	
	ParameterName = "StandardSubsystems.MessagesForEventLog";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Array);
	EndIf;
	
	Pages = Items.WizardPages.ChildItems;
	If NewPage = Undefined Then
		NewPage = Items.WizardPages.CurrentPage;
	EndIf;
	
	BackButtonAvailable = True;
	NextButtonAvailable = True;
	CloseButtonAvailable = True;
	NextButtonFunction = True; // True means "Next", False means "Ready".
	CloseButtonFunction = True; // True means "Cancel", False means "Close".
	
	Items.NextButton.Representation = ButtonRepresentation.Text;
	
	If NewPage = Pages.NoUpdatesFound Then
		
		NextButtonFunction = False;
		CloseButtonFunction = False;
		NextButtonAvailable = False;
		CurrentConfigurationDetails = StandardSubsystemsClient.ClientRunParameters().ConfigurationSynonym;
		CurrentConfigurationVersion = StandardSubsystemsClient.ClientRunParameters().ConfigurationVersion;
		
		If IsSubordinateDIBNode Then
			BackButtonAvailable = False;
		EndIf;
		
	ElsIf NewPage = Pages.SelectUpdateModeFile Then
		
		NextButtonFunction = (Object.UpdateMode = 0);// If no updating now, than done.
		
		UpdateConnectionsInformation(Pages.SelectUpdateModeFile);
		
		If Object.CreateDataBackup = 2 Then
			Object.RestoreInfobase = True;
		ElsIf Object.CreateDataBackup = 0 Then
			Object.RestoreInfobase = False;
		EndIf;
		
		Items.BackupFileLabel.Title = ConfigurationUpdateClient.BackupCreationTitle(Object);
		
		If IsSubordinateDIBNode Then
			BackButtonAvailable = False;
		EndIf;
	ElsIf NewPage = Pages.UpdateModeSelectionServer Then
		
		NextButtonFunction = (Object.UpdateMode = 0);// If no updating now, than done.
		Object.RestoreInfobase = False;
		
		RestartInformationPanelPages = Items.RestartInformationPages.ChildItems;
		Items.RestartInformationPages.CurrentPage = ?(Object.UpdateMode = 0,
			RestartInformationPanelPages.RestartNowPage,
			RestartInformationPanelPages.ScheduledRestartPage);
		
		UpdateConnectionsInformation(Pages.UpdateModeSelectionServer);
		
		Items.UpdateDateTimeField.Enabled = (Object.UpdateMode = 2);
		Items.PanelNotifyUsers.Visible = (Object.UpdateMode = 2);
		Items.Email.Enabled   = Object.EmailReport;
		
		If IsSubordinateDIBNode Then
			BackButtonAvailable = False;
		EndIf;
		
		If Object.UpdateMode = 2 Then
			Items.NextButton.Representation = ButtonRepresentation.PictureAndText;
		EndIf;
		
	ElsIf NewPage = Pages.UpdateFile Then
		
		BackButtonAvailable = False;
		If UpdateFileRequired = 0 Then
			If ConfigurationChanged Or LoadExtensions Then
				Items.PagesUpdateFile.CurrentPage = Items.HasChanges;
			Else
				Items.PagesUpdateFile.CurrentPage = Items.NoChanges;
				NextButtonAvailable = False;
			EndIf;
		ElsIf UpdateFileRequired = 1 Then
			CurrentItem = Items.UpdateFileField;
			ThisIsATestClient = StrFind(CommonInternalClient.EnterpriseStartupParametersFromScript(), "TestClient") > 0;
			If FirstOpeningOfForm And IsBlankString(SelectedFiles) And Not ThisIsATestClient Then
				AttachIdleHandler("SelectUpdateFile", 0.1, True);
			EndIf;
		EndIf;
		Items.UpdateFromMainConfigurationPanel.Visible = UpdateFileRequired = 0;
		Items.UpdateFileField.Enabled                   = UpdateFileRequired = 1;
		Items.UpdateFileField.AutoMarkIncomplete     = UpdateFileRequired = 1;
		Items.UpdateFileRequiredRadioButtons.Enabled     = Not IsWebClient();
		Items.FindAndInstallUpdatesGroup.Visible        = Not IsWebClient();
		
	EndIf;
	
	EventLogClient.WriteEventsToEventLog();
	
	NextButton = Items.NextButton;
	CloseButton = Items.CloseButton;
	Items.BackButton.Enabled = BackButtonAvailable;
	NextButton.Enabled   = NextButtonAvailable;
	CloseButton.Enabled = CloseButtonAvailable;
	If NextButtonAvailable Then
		If Not NextButton.DefaultButton Then
			NextButton.DefaultButton = True;
		EndIf;
	ElsIf CloseButtonAvailable Then
		If Not CloseButton.DefaultButton Then
			CloseButton.DefaultButton = True;
		EndIf;
	EndIf;
	
	NextButton.Title = ?(NextButtonFunction, NStr("vi = 'Tiếp theo >';
													|ru = 'Далее >';
													|en = 'Next >'; fa = 'بعدی >';
													|it = 'Avanti >';
													|pl = 'Dalej >';
													|tr = 'İleri >'"), NStr("vi = 'Đồng ý';
																		|ru = 'Готово';
																		|en = 'Finish'; fa = 'پایان';
																		|it = 'Fine';
																		|pl = 'Gotowe';
																		|tr = 'Bitiş'"));
	CloseButton.Title = ?(CloseButtonFunction, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"), NStr("vi = 'Đóng';
																			|ru = 'Закрыть';
																			|en = 'Close'; fa = 'بستن';
																			|it = 'Chiudere';
																			|pl = 'Zamknij';
																			|tr = 'Kapat'"));
	FirstOpeningOfForm = False;
	
EndProcedure

&AtClient
Procedure SelectUpdateFile()
	
	Items.UpdateFileField.ReadOnly = True;
	Items.NextButton.Enabled = False;
	Items.UpdateFromMainConfigurationPanel.Visible = True;
	Items.PagesUpdateFile.CurrentPage = Items.WaitForFileChoice;
	
	DialogProperties = PropertiesOfTheUpdateFileSelectionDialog();
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Dialog.Title = DialogProperties.Title;
	ImportParameters.Dialog.Filter = DialogProperties.Filter;
	ImportParameters.Dialog.Directory = TheDirectoryOfTheUpdateFile(Items.UpdateFileField.EditText);
	
	FileSystemClient.ImportFiles(
		New CallbackDescription("AfterSelectingTheUpdateFiles", ThisObject),
		ImportParameters);
	
EndProcedure

&AtClient
Function PropertiesOfTheUpdateFileSelectionDialog()
	
	Properties = New Structure("Filter, Title");
	
#If WebClient Then
	
	Properties.Title = NStr("vi = 'Chọn tệp sửa lỗi';
							|ru = 'Выбор исправлений';
							|en = 'Select patches'; fa = 'Select patches';
							|it = 'Selezione di patch';
							|pl = 'Wybór korekt';
							|tr = 'Düzeltmelerin seçimi'");
	Properties.Filter = NStr("vi = 'Tệp sửa lỗi (*.cfe*;*.zip)|*.cfe*;*.zip';
							|ru = 'Файлы исправлений (*.cfe*;*.zip)|*.cfe*;*.zip';
							|en = 'Patch files (*.cfe*;*.zip)|*.cfe*;*.zip'; fa = 'Patch files (*.cfe*;*.zip)|*.cfe*;*.zip';
							|it = 'File di patch (*.cfe*;*.zip)|*.cfe*;*.zip';
							|pl = 'Pliki korekt (*.cfe*;*.zip)|*.cfe*;*.zip';
							|tr = 'Düzeltme dosyası (*.cfe*;*.zip)|*.cfe*;*.zip'");
	
#Else
	
	If CommonClient.ClientConnectedOverWebServer() Or IsSubordinateDIBNode Then 
		
		Properties.Title = NStr("vi = 'Chọn tệp sửa lỗi';
								|ru = 'Выбор исправлений';
								|en = 'Select patches'; fa = 'Select patches';
								|it = 'Selezione di patch';
								|pl = 'Wybór korekt';
								|tr = 'Düzeltmelerin seçimi'");
		Properties.Filter = NStr("vi = 'Tệp sửa lỗi (*.cfe*;*.zip)|*.cfe*;*.zip';
								|ru = 'Файлы исправлений (*.cfe*;*.zip)|*.cfe*;*.zip';
								|en = 'Patch files (*.cfe*;*.zip)|*.cfe*;*.zip'; fa = 'Patch files (*.cfe*;*.zip)|*.cfe*;*.zip';
								|it = 'File di patch (*.cfe*;*.zip)|*.cfe*;*.zip';
								|pl = 'Pliki korekt (*.cfe*;*.zip)|*.cfe*;*.zip';
								|tr = 'Düzeltme dosyası (*.cfe*;*.zip)|*.cfe*;*.zip'");
		
	Else
		
		Properties.Title = NStr("vi = 'Chọn bản đóng gói của bản cập nhật cấu hình';
								|ru = 'Выбор поставки обновления конфигурации';
								|en = 'Select configuration updates'; fa = 'Select configuration updates';
								|it = 'Selezione di consegna aggiornamento della configurazione';
								|pl = 'Wybór dostawy aktualizacji konfiguracji';
								|tr = 'Bir yapılandırma güncellemesi teslimatı seçin'");
		
		DescriptionOfTheDialogFilter = New Array;
		
		DescriptionOfTheDialogFilter.Add(NStr("vi = 'Tệp cài đặt cấu hình (*.cf)|*.cf';
												|ru = 'Файлы поставки конфигурации (*.cf)|*.cf';
												|en = 'Configuration files (*.cf)|*.cf'; fa = 'Configuration files (*.cf)|*.cf';
												|it = 'File della consegna di configurazione (*.cf)|*.cf';
												|pl = 'Pliki dostawy konfiguracji (*.cf)|*.cf';
												|tr = 'Yapılandırma techizat dosyaları (*.cf)|*.cf'"));
		DescriptionOfTheDialogFilter.Add(NStr("vi = 'Tệp cài đặt bản cập nhật cấu hình (*.cfu)|*.cfu';
												|ru = 'Файлы поставки обновления конфигурации(*.cfu)|*.cfu';
												|en = 'Update files(*.cfu)|*.cfu'; fa = 'Update files(*.cfu)|*.cfu';
												|it = 'File della consegna di aggiornamenti della configurazione (*.cfu)|*.cfu';
												|pl = 'Pliki dostawy aktualizacji konfiguracji (*.cfu)|*.cfu';
												|tr = 'Yapılandırma techizat dosyaları (*.cfu)|*.cfu'"));
		
		DescriptionOfTheDialogFilter.Insert(0, NStr("vi = 'Tất cả tệp (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip';
													|ru = 'Все файлы (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip';
													|en = 'All files (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip'; fa = 'All files (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip';
													|it = 'Tutti i file (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip';
													|pl = 'Wszystkie pliki (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip';
													|tr = 'Tüm dosyalar (*.cf*;*.cfu;*.cfe;*.zip)|*.cf*;*.cfu;*.cfe;*.zip'"));
		DescriptionOfTheDialogFilter.Add(NStr("vi = 'Tệp sửa lỗi (*.cfe*;*.zip)|*.cfe*;*.zip';
												|ru = 'Файлы исправлений (*.cfe*;*.zip)|*.cfe*;*.zip';
												|en = 'Patch files (*.cfe*;*.zip)|*.cfe*;*.zip'; fa = 'Patch files (*.cfe*;*.zip)|*.cfe*;*.zip';
												|it = 'File patch (*.cfe*;*.zip)|*.cfe*;*.zip';
												|pl = 'Pliki korekt (*.cfe*;*.zip)|*.cfe*;*.zip';
												|tr = 'Düzeltme dosyası (*.cfe*;*.zip)|*.cfe*;*.zip'"));
		
		Properties.Filter = StrConcat(DescriptionOfTheDialogFilter, "|");
		
	EndIf;
	
#EndIf
	
	Return Properties;
	
EndFunction

&AtClient
Procedure AfterSelectingTheUpdateFiles(DescriptionOfTheSelectedFiles, AdditionalParameters) Export 
	
	If TypeOf(DescriptionOfTheSelectedFiles) = Type("Array") Then 
		ProcessUpdateFiles(DescriptionOfTheSelectedFiles);
	EndIf;

	Items.UpdateFileField.ReadOnly = False;
	Items.NextButton.Enabled = True;
	BeforeOpenPage();
	
EndProcedure

// Parameters:
//  DescriptionOfTheSelectedFiles - Array of Structure:
//    * Location - String
//    * Name - String 
//    * FileName - String
//
&AtClient
Procedure ProcessUpdateFiles(DescriptionOfTheSelectedFiles)
	
	InitializePatchFiles(DescriptionOfTheSelectedFiles, True);
	
	PatchesFilesNames = New Array;
	UpdateFileNames = New Array;
	
	For Each DescriptionOfTheSelectedFile In DescriptionOfTheSelectedFiles Do 
		
		If ThisIsTheFixFile(DescriptionOfTheSelectedFile.Name) Then 
			PatchesFilesNames.Add(DescriptionOfTheSelectedFile.Name);
		Else
			UpdateFileNames.Add(DescriptionOfTheSelectedFile.Name);
		EndIf;
		
	EndDo;
	
	FilesNames = CommonClient.CopyRecursive(PatchesFilesNames);
	
	If UpdateFileNames.Count() > 0 Then 
		FilesNames.Insert(0, UpdateFileNames[0]);
	EndIf;
	
	SelectedFiles = StrConcat(FilesNames, ",");
	
EndProcedure

// Parameters:
//  FilesDetails - String
//                 - Array of Structure:
//                     * Location - String
//                     * Name - String
//                     * FileName - String
//  Reinitialize - Boolean
//
&AtClient
Procedure InitializePatchFiles(FilesDetails, Reinitialize = False)
	
	If TypeOf(PatchesFiles) = Type("Array") And Not Reinitialize Then 
		Return;
	EndIf;
	
	PatchesFiles = New Array;
	If TypeOf(FilesDetails) = Type("Array") Then 
		For Each FileDetails In FilesDetails Do 
			If ThisIsTheFixFile(FileDetails.FileName) Then 
				PatchesFiles.Add(New TransferableFileDescription(FileDetails.Name, FileDetails.Location));
			EndIf;
		EndDo;
	ElsIf TypeOf(FilesDetails) = Type("String") Then 
		FilesNames = StrSplit(FilesDetails, ",");
		For Each FileName In FilesNames Do
			If ThisIsTheFixFile(FileName) Then
				PatchesFiles.Add(New TransferableFileDescription(FileName));
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Function ThisIsTheFixFile(FileName)
	
	Return StrEndsWith(FileName, ".cfe") Or StrEndsWith(FileName, ".zip");
	
EndFunction

&AtClient
Function IsWebClient()
	
#If WebClient Then
	Return True;
#Else
	Return CommonClient.ClientConnectedOverWebServer();
#EndIf
	
EndFunction

&AtClient
Function PatchesFilesNames()
	
	PatchesFilesNames = New Array;
	
	For Each PatchFile In PatchesFiles Do 
		PatchesFilesNames.Add(PatchFile.Name);
	EndDo;
	
	Return PatchesFilesNames;
	
EndFunction

&AtClient
Procedure UpdateConnectionsInformation(CurrentPage = Undefined)
	
	If CurrentPage = Undefined Then
		CurrentPage = Items.WizardPages.CurrentPage;
	EndIf;
	
	ParameterName = "StandardSubsystems.MessagesForEventLog";
	If CurrentPage = Items.SelectUpdateModeFile Then
		
		ConnectionsInfo = IBConnectionsServerCall.ConnectionsInformation(False, ApplicationParameters[ParameterName]);
		Items.ConnectionsGroup.Visible = ConnectionsInfo.HasActiveConnections;
		
		If ConnectionsInfo.HasActiveConnections Then
			AllPages = Items.ActiveUsersPanel.ChildItems;
			If ConnectionsInfo.HasCOMConnections Then
				Items.ActiveUsersPanel.CurrentPage = AllPages.ActiveConnections;
			ElsIf ConnectionsInfo.HasDesignerConnection Then
				Items.ActiveUsersPanel.CurrentPage = AllPages.DesignerConnection;
			Else
				Items.ActiveUsersPanel.CurrentPage = AllPages.ActiveUsers;
			EndIf;
		EndIf;
		
	ElsIf CurrentPage = Items.UpdateModeSelectionServer Then
		
		PageSetup = SelectUpdateModePageParametersServer(ApplicationParameters[ParameterName]);
		
		ConnectionsInfo = PageSetup.ConnectionsInformation;
		ConnectionsPresent = ConnectionsInfo.HasActiveConnections And Object.UpdateMode = 0;
		Items.ConnectionsGroup1.Visible = ConnectionsPresent;
		If ConnectionsPresent Then
			AllPages = Items.ActiveUsersPanel1.ChildItems;
			Items.ActiveUsersPanel1.CurrentPage = ? (ConnectionsInfo.HasCOMConnections, 
				AllPages.ActiveConnections1, AllPages.ActiveUsers1);
		EndIf;
		
	ElsIf CurrentPage = Items.AfterInstallUpdates Then
		
		ConnectionsInfo = IBConnectionsServerCall.ConnectionsInformation(False, ApplicationParameters[ParameterName]);
		Items.ActiveUsersDecoration.Visible = ConnectionsInfo.HasActiveConnections;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallUpdate()
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("UpdateMode");
	ParametersOfUpdate.Insert("UpdateDateTime");
	ParametersOfUpdate.Insert("EmailReport");
	ParametersOfUpdate.Insert("Email");
	ParametersOfUpdate.Insert("SchedulerTaskCode");
	ParametersOfUpdate.Insert("CreateDataBackup");
	ParametersOfUpdate.Insert("IBBackupDirectoryName");
	ParametersOfUpdate.Insert("RestoreInfobase");
	ParametersOfUpdate.Insert("UpdateFileName");
	
	FillPropertyValues(ParametersOfUpdate, Object);
	ParametersOfUpdate.Insert("ShouldExitApp", Parameters.ShouldExitApp);
	ParametersOfUpdate.Insert("UpdateFileRequired", Boolean(UpdateFileRequired));
	ParametersOfUpdate.Insert("PatchesFiles", PatchesFilesNames());
	
	ParametersOfUpdate.Insert("ConfigurationChanged", ConfigurationChanged);
	ParametersOfUpdate.Insert("LoadExtensions", LoadExtensions);
	
	If ShouldNotifyUsers Then
		ParametersOfUpdate.Insert("UserNotificationInterval", NotificationInterval);
	Else
		ParametersOfUpdate.Insert("UserNotificationInterval", 0);
	EndIf;
	
	ConfigurationUpdateClient.InstallUpdate(ThisObject, ParametersOfUpdate, AdministrationParameters);
	
EndProcedure

&AtClient
Procedure HandleNextButtonClick()
	
	ClearMessages();
	CurrentPage = Items.WizardPages.CurrentPage;
	Pages = Items.WizardPages.ChildItems;
	
	If CurrentPage = Pages.UpdateFile Then
		NavigateFromUpdateFilePage();
	ElsIf CurrentPage = Pages.SelectUpdateModeFile
		Or CurrentPage = Pages.UpdateModeSelectionServer Then
		InstallUpdate();
	ElsIf CurrentPage = Pages.AfterInstallUpdates And RestartApplication Then
		Exit(True, True);
	Else
		Close();
		If ShowInstalledPatches Then
			ConfigurationUpdateClient.ShowInstalledPatches();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure HandleBackButtonClick()
	
	Pages = Items.WizardPages.ChildItems;
	CurrentPage = Items.WizardPages.CurrentPage;
	NewCurrentPage = CurrentPage;
	
	If CurrentPage = Pages.SelectUpdateModeFile
		Or CurrentPage = Pages.UpdateModeSelectionServer Then
		NewCurrentPage = Pages.UpdateFile;
	EndIf;
	
	BeforeOpenPage(NewCurrentPage);
	Items.WizardPages.CurrentPage = NewCurrentPage;
	
EndProcedure

&AtClient
Procedure NavigateFromUpdateFilePage()
	
	InitializePatchFiles(SelectedFiles);
	
	Object.UpdateFileName = "";
	If Not IsBlankString(SourceConfigurations) Then
		DeleteFromTempStorage(SourceConfigurations);
		SourceConfigurations = "";
	EndIf;	
	
	SelectedFilesNames = StrSplit(SelectedFiles, ",");
	For Each FileName In SelectedFilesNames Do
		If Not ThisIsTheFixFile(FileName) Then
			If Not IsBlankString(Object.UpdateFileName) Then
				Raise NStr("vi = 'Cho phép chọn chỉ một tệp cập nhật.';
							|ru = 'Допустимо выбирать только один файл обновления.';
							|en = 'Please select a single update file.'; fa = 'Please select a single update file.';
							|it = 'È consentito selezionare solo un file di aggiornamento.';
							|pl = 'Dostępne jest wybieranie tylko jednego pliku aktualizacji.';
							|tr = 'Yalnızca bir güncelleme dosyası seçebilirsiniz.'");
			EndIf;
			Object.UpdateFileName = FileName;
		EndIf;
	EndDo;
	
	If UpdateFileRequired = 1 Then
		If Not ValueIsFilled(SelectedFiles) Then
			CommonClient.MessageToUser(NStr("vi = 'Hãy chỉ ra tệp cài đặt bản cập nhật cấu hình.';
											|ru = 'Укажите файл поставки обновления конфигурации.';
											|en = 'Please select an update file.'; fa = 'Please select an update file.';
											|it = 'Specificare il file di consegna dell''aggiornamento della configurazione.';
											|pl = 'Wskaż plik dostawy aktualizacji konfiguracji.';
											|tr = 'Bir yapılandırma güncelleme teslim dosyası belirtin.'"),,"Object.UpdateFileName");
			CurrentItem = Items.UpdateFileField;
			Return;
		EndIf;
		If Not IsBlankString(Object.UpdateFileName) Then
			File = New File(Object.UpdateFileName);
			If Not File.Exists() Or Not File.IsFile() Then
				CommonClient.MessageToUser(NStr("vi = 'Không tìm thấy tệp cài đặt bản cập nhật cấu hình.';
												|ru = 'Файл поставки обновления конфигурации не найден.';
												|en = 'The update file is not found.'; fa = 'The update file is not found.';
												|it = 'File di consegna dell''aggiornamento della configurazione non è stato trovato.';
												|pl = 'Nie znaleziono pliku dostawy aktualizacji konfiguracji.';
												|tr = 'Yapılandırma güncellemesinin teslim dosyası bulunamadı.'"),,"Object.UpdateFileName");
				CurrentItem = Items.UpdateFileField;
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	Handler = New CallbackDescription("CheckUpdateFilesApplicability", ThisObject);
	UsersInternalClient.ShowSecurityWarning(Handler,
		UsersInternalClientServer.SecurityWarningKinds().BeforeSelectUpdateFile);
	
EndProcedure

&AtClient
Procedure CheckUpdateFilesApplicability(Result, AdditionalParameters) Export
	
	If Result <> "Continue" Then
		Return;
	EndIf;

	If IsBlankString(Object.UpdateFileName) Then
		If UpdateFileRequired = 1 Then
			ProceedToPatchesInstallation();
		Else
			OnUpdateLegalityCheck();			
		EndIf;
		Return;
	EndIf;
	
	// Check applicability of update files only in a file infobase.
	If Not CommonClient.FileInfobase() Then
		OnUpdateLegalityCheck();
		Return;
	EndIf;	
		
	If Not IsConfigurationUpdateDeliveryFile(Object.UpdateFileName) Then
		OnUpdateLegalityCheck();
		Return;
	EndIf;
	
	Status(NStr("vi = 'Xác thực ...';
				|ru = 'Проверка применимости...';
				|en = 'Checking applicability…'; fa = 'Checking applicability…';
				|it = 'Verifica di applicabilità...';
				|pl = 'Weryfikacja przydatności...';
				|tr = 'Uygulama kontrolü.'"), 75);
	UpdateInfo = CheckUpdateFileApplicability(Object.UpdateFileName, UUID);
	If Not IsBlankString(UpdateInfo.ErrorText) Then
		OnUpdateLegalityCheck();
		Return; // Cannot complete the check; the file is probably corrupted.
	EndIf;	
	
	If UpdateInfo.Compatible Then
		DeleteFromTempStorage(UpdateInfo.SourceConfigurations);
		OnUpdateLegalityCheck();
		Return;
	EndIf;
	
	SourceConfigurations = UpdateInfo.SourceConfigurations;
	OpenForm("DataProcessor.InstallUpdates.Form.IncompatibleUpdate",
	 	New Structure("SourceConfigurations", SourceConfigurations));
	
EndProcedure

&AtClient
Function IsConfigurationUpdateDeliveryFile(Val FileName)
	Return StrCompare(CommonClientServer.GetFileNameExtension(FileName), "cfu") = 0;
EndFunction	

&AtServerNoContext
Function CheckUpdateFileApplicability(Val FileName, Val FormIdentifier)
	Result = ConfigurationUpdate.UpdateInfo(FileName);
	Result.SourceConfigurations = PutToTempStorage(Result.SourceConfigurations, FormIdentifier);
	Return Result;	
EndFunction

&AtClient
Procedure ProceedToPatchesInstallation()
	
	CallbackDescription = New CallbackDescription("ContinueInstallUpdates", ThisObject);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Interactively = False;
	
	FilesToUpload = CommonClient.CopyRecursive(PatchesFiles);
	
	FileSystemClient.ImportFiles(CallbackDescription, ImportParameters, FilesToUpload);
	
EndProcedure

&AtClient
Procedure ContinueInstallUpdates(PlacedFiles, AdditionalParameters) Export
	
	InstallPatchesAtServer(PlacedFiles);
	
	Items.WizardPages.CurrentPage = Items.AfterInstallUpdates;
	Items.NextButton.Title = NStr("vi = 'Đồng ý';
									|ru = 'Готово';
									|en = 'Finish'; fa = 'پایان';
									|it = 'Fine';
									|pl = 'Gotowe';
									|tr = 'Bitiş'");
	Items.CloseButton.Title = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Закрыть';
									|pl = 'Close';
									|tr = 'Kapat'");
	
EndProcedure

&AtServer
Procedure InstallPatchesAtServer(PlacedFiles)
	
	ConnectionsInfo = IBConnectionsServerCall.ConnectionsInformation(False);
	Items.ActiveUsersDecoration.Visible = ConnectionsInfo.HasActiveConnections;
	
	Corrections = New Structure;
	Corrections.Insert("Set", PlacedFiles);
	PatchesInstallationParameters = ConfigurationUpdate.PatchesInstallationParameters();
	PatchesInstallationParameters.InBackground = False;
	PatchesInstallationParameters.UpdateExtensionParameters = True;
	PatchesInstallationParameters.ShouldCheckApplicabilityByManifest = True;

	Result = ConfigurationUpdate.InstallAndDeletePatches(Corrections, PatchesInstallationParameters);
	HasErrors = (Result.Unspecified <> 0);
	PatchesInstalled1 = Result.Installed.Count();
	Items.PatchInstallationError.Visible = HasErrors;
	Items.WarningsPanel.Visible = False;
	Items.InformationPanel.Visible     = False;
	
	If HasErrors Then
		If PatchesInstalled1 > 0 Then
			LabelText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các bản sửa lỗi được cài đặt: %1 trong %2, các thay đổi sẽ có hiệu lực sau khi khởi động lại ứng dụng';
					|ru = 'Установлено исправлений: %1 из %2, изменения вступят в силу после перезапуска приложения';
					|en = 'Patches installed: %1 out of %2. The changes will be applied after you restart the application.'; fa = 'وصله‌های نصب‌شده: %1 از %2. تغییرات پس از راه‌اندازی مجدد برنامه اعمال خواهند شد.';
					|it = 'Установлено исправлений: %1 из %2, изменения вступят в силу после перезапуска приложения';
					|pl = 'Patches installed: %1 out of %2. The changes will be applied after you restart the application.';
					|tr = 'Yüklenen düzeltmeler: %1 itibaren %2, değişiklikler uygulamayı yeniden başlattıktan sonra yürürlüğe girecek'"),
				PatchesInstalled1,
				PlacedFiles.Count());
			Items.PatchesInstalledDecoration.Title = LabelText;
			Items.DecorationPatchesInstalled.Visible = False;
		Else
			Items.PatchesInstalled.Visible = False;
			Items.PatchesInstalledDecoration.Visible = False;
			Return;
		EndIf;
	Else
		If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
			OperationName = "StandardSubsystems.ConfigurationUpdate.Patches1.ManualPatchInstallation";
			ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
			ModuleMonitoringCenter.WriteBusinessStatisticsOperation(OperationName, 1);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProceedToUpdateModeSelection(IsMoveNext = False)
	
	If AdministrationParameters = Undefined Then
		
		CallbackDescription = New CallbackDescription("AfterGetAdministrationParameters", ThisObject, IsMoveNext);
		FormCaption = NStr("vi = 'Cài đặt bản cập nhật';
							|ru = 'Установка обновления';
							|en = 'Install update'; fa = 'نصب به‌روزرسانی';
							|it = 'Installazione dell''aggiornamento';
							|pl = 'Instalacja aktualizacji';
							|tr = 'Güncelleme kurulumu'");
		If IsFileInfobase Then
			NoteLabel = NStr("vi = 'Để cài đặt bản cập nhật, hãy nhập
				|tham số quản trị cơ sở thông tin';
				|ru = 'Для установки обновления введите
				|параметры администрирования информационной базы';
				|en = 'To install the update, enter
				|the infobase administration parameters'; fa = 'To install the update, enter
				|the infobase administration parameters';
				|it = 'Per installare l''aggiornamento, inserire
				|i parametri di amministrazione dell''infobase';
				|pl = 'Aby zainstalować aktualizację wprowadź
				|parametry administrowania bazy informacyjnej';
				|tr = 'Güncellemeyi kurmak için infobase yönetim parametrelerini girin
				|'");
			PromptForClusterAdministrationParameters = False;
		Else
			NoteLabel = NStr("vi = 'Để cài đặt bản cập nhật, hãy nhập các tham số
				|quản trị cụm máy chủ và cơ sở thông tin';
				|ru = 'Для установки обновления введите параметры
				|администрирования кластера серверов и информационной базы';
				|en = 'To install the update, enter
				|the server cluster and infobase administration parameters'; fa = 'To install the update, enter
				|the server cluster and infobase administration parameters';
				|it = 'Per installare l''aggiornamento, inserire i parametri
				|di amministrazione del cluster di server e infobase';
				|pl = 'Aby zainstalować aktualizację wprowadź parametry
				|administrowania klastera serwerów i bazy informacyjnej';
				|tr = 'Güncellemeyi kurmak için sunucu kümesini ve infobase yönetim parametrelerini 
				|girin'");
			PromptForClusterAdministrationParameters = True;
		EndIf;
		
		IBConnectionsClient.ShowAdministrationParameters(CallbackDescription, True, PromptForClusterAdministrationParameters,
			AdministrationParameters, FormCaption, NoteLabel);
		
	Else
		
		AfterGetAdministrationParameters(AdministrationParameters, IsMoveNext);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnUpdateLegalityCheck()
	
	If UpdateFileRequired = 1 Then
		If CommonClient.SubsystemExists("StandardSubsystems.SoftwareLicenseCheck") Then
			Notification = New CallbackDescription("OnUpdateLegalityCheckCompletion", ThisObject);
			ModuleSoftwareLicenseCheckClient = CommonClient.CommonModule("SoftwareLicenseCheckClient");
			ModuleSoftwareLicenseCheckClient.ShowLegitimateSoftwareCheck(Notification);
			Return;
		EndIf;
	EndIf;
	OnUpdateLegalityCheckCompletion(True, Undefined);
	
EndProcedure

&AtClient
Procedure OnUpdateLegalityCheckCompletion(UpdateAcquiredLegally, AdditionalParameters) Export
	
	If UpdateAcquiredLegally = True Then
		ProceedToUpdateModeSelection(True);
	Else
		HandleBackButtonClick();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterGetAdministrationParameters(Result, IsMoveNext) Export
	
	If IsMoveNext Then
		Items.WizardPages.CurrentPage.Enabled = True;
	EndIf;
	
	If Result <> Undefined Then
		
		AdministrationParameters = Result;
		Pages = Items.WizardPages.ChildItems;
		NewCurrentPage = ?(IsFileInfobase, Pages.SelectUpdateModeFile, Pages.UpdateModeSelectionServer);
		SetAdministratorPassword(AdministrationParameters);
		
		BeforeOpenPage(NewCurrentPage);
		Items.WizardPages.CurrentPage = NewCurrentPage;
		
	Else
		
		WarningText = NStr("vi = 'Để cài đặt bản cập nhật, hãy nhập tham số quản trị hệ thống.';
							|ru = 'Для установки обновления введите параметры администрирования.';
							|en = 'To install the update, enter the administration parameters.'; fa = 'To install the update, enter the administration parameters.';
							|it = 'Per installare l''aggiornamento, inserire i parametri di amministrazione.';
							|pl = 'Aby zainstalować aktualizację wprowadź parametry administrowania.';
							|tr = 'Güncellemeyi kurmak için yönetim parametrelerini girin.'");
		ShowMessageBox(, WarningText);
		
		MessageText = NStr("vi = 'Không thể cài đặt được bản cập nhật ứng dụng vì bạn đã nhập sai mật khẩu hoặc tên quản trị viên
			| (hoặc các tham số khác để quản trị cơ sở thông tin client-server).';
			|ru = 'Не удалось установить обновление приложения, т.к. введены неправильные имя или пароль администратора 
			|(или другие параметры администрирования клиент-серверной информационной базы).';
			|en = 'Cannot install the application update as the specified administrator name or password is invalid
			|(or other client/server infobase administration parameters are invalid).'; fa = 'Cannot install the application update as the specified administrator name or password is invalid
			|(or other client/server infobase administration parameters are invalid).';
			|it = 'Не удалось установить обновление приложения, т.к. введены неправильные имя или пароль администратора 
			|(или другие параметры администрирования клиент-серверной информационной базы).';
			|pl = 'Cannot install the application update as the specified administrator name or password is invalid
			|(or other client/server infobase administration parameters are invalid).';
			|tr = 'Uygulama güncellemesi kurulamadı çünkü yanlış yönetici adı veya parolası 
			| (veya istemci-sunucu infobase''ni yönetmek için diğer parametreler) girildi.'");
		EventLogClient.AddMessageForEventLog(ConfigurationUpdateClient.EventLogEvent(), "Error", MessageText);
		
	EndIf;
	
	EventLogClient.WriteEventsToEventLog();
	
EndProcedure

&AtClient
Procedure ShowActiveUsers()
	
	FormParameters = New Structure;
	FormParameters.Insert("NotifyOnClose", True);
	StandardSubsystemsClient.OpenActiveUserList(FormParameters, ThisObject);
	
EndProcedure

&AtServer
Function SelectUpdateModePageParametersServer(MessagesForEventLog)
	
	PageSetup = New Structure;
	PageSetup.Insert("ConnectionsInformation", IBConnections.ConnectionsInformation(False, MessagesForEventLog));
	Return PageSetup;
	
EndFunction

#Region SchedulingUpdateAtGivenTime

// Returns a file directory (a partial path without a file name).
//
// Parameters:
//  PathToFile  - String - File path.
//
// Returns:
//   String   - a file directory
//
&AtClient
Function TheDirectoryOfTheUpdateFile(Val PathToFile)
	
	CharPosition = StrFind(PathToFile, GetPathSeparator(), SearchDirection.FromEnd);
	
	If CharPosition > 1 Then
		Return Mid(PathToFile, 1, CharPosition - 1); 
	Else
		Return "";
	EndIf;
	
EndFunction

&AtServer
Procedure RestoreConfigurationUpdateSettings()
	
	Settings = ConfigurationUpdate.ConfigurationUpdateSettings();
	FillPropertyValues(Object, Settings);
	PatchesFilesAsString = StrConcat(Settings.PatchesFiles, ",");
	If ValueIsFilled(PatchesFilesAsString) Then
		SelectedFiles = Settings.UpdateFileName + "," + PatchesFilesAsString;
	Else
		SelectedFiles = Settings.UpdateFileName;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAdministratorPassword(AdministrationParameters)
	
	IBAdministrator = InfoBaseUsers.FindByName(AdministrationParameters.InfobaseAdministratorName);
	
	If Not IBAdministrator.StandardAuthentication Then
		
		IBAdministrator.StandardAuthentication = True;
		IBAdministrator.Password = AdministrationParameters.InfobaseAdministratorPassword;
		IBAdministrator.Write();
		
	EndIf;
	
EndProcedure

&AtServer
Function LoadExtensionsThatChangeDataStructure()

	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		ModuleDataExchangeInternal = Common.CommonModule("DataExchangeInternal");
		Return ModuleDataExchangeInternal.LoadExtensionsThatChangeDataStructure();
		
	Else
			
		Return False;
		
	EndIf;	

EndFunction

&AtClient
Procedure AfterNotificationIntervalSelected(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	TitleTemplate1 = NStr("vi = 'Thông báo cho người sử dụng về cập nhật dự tính trong <a href=""Ссылка"">%1 phút</a>';
							|ru = 'Уведомлять пользователей о планируемом обновлении за <a href=""Ссылка"">%1 минут</a>';
							|en = 'Notify users about an update <a href=""Ссылка"">%1 minutes</a> in advance'; fa = 'Notify users about an update <a href=""Ссылка"">%1 minutes</a> in advance';
							|it = 'Уведомлять пользователей о планируемом обновлении за <a href=""Ссылка"">%1 минут</a>';
							|pl = 'Notify users about an update <a href=""Ссылка"">%1 minutes</a> in advance';
							|tr = 'Planlanan güncelleme hakkında kullanıcıları <a href=""Ссылка"">%1 dakika </a>önceden bilgilendirin'");
	Items.DecorationNotifyUsers.Title = StringFunctionsClient.FormattedString(TitleTemplate1, Result.Value);
	
#If Not WebClient Then
	NotificationInterval = XMLValue(Type("Number"), Result.Value);
#EndIf
EndProcedure

#EndRegion

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
