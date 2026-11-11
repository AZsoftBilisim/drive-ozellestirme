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
	
	SetConditionalAppearance();
	
	DataExchangeServer.CheckExchangeManagementRights();
	
	SetPrivilegedMode(True);
	
	DataExchangeSaaS.OnCreateStandaloneWorkstation();
	
	DataExchangeSaaSOverridable.OnCreateStandaloneWorkstation();
	
	ExchangePlanName = StandaloneModeInternal.StandaloneModeExchangePlan();
	
	// Getting default values for the exchange plan	
	NodeFiltersSetting = DataExchangeServer.NodeFiltersSetting(ExchangePlanName, "");
	
	Items.DataTransferRestrictionsDetails.Title = DataTransferRestrictionsDetails(ExchangePlanName, NodeFiltersSetting);
	
	StandaloneWorkstationSetupInstruction = StandaloneModeInternal.InstructionTextFromTemplate("SWSetupInstruction");
	
	Items.PlatformVersionHelpLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để làm việc độc lập trên máy tính của bạn, cần cài đặt
		|nền tảng ""1C:Enterprise"" phiên bản %1.';
		|ru = 'Для автономной работы на Вашем компьютере должна быть установлена
		|платформа ""1С:Предприятие"" версии %1.';
		|en = 'To run applications in a standalone mode, install 
		|1C:Enterprise platform %1.'; fa = 'To run applications in a standalone mode, install 
		|1C:Enterprise platform %1.';
		|it = 'Per il lavoro autonomo il computer deve disporre della versione %1 della piattaforma 
		| ""1C:Enterprise"".';
		|pl = 'Do pracy offline na Twoim komputerze musi być zainstalowana
		|platforma ""1C:Enterprise"" wersji%1.';
		|tr = 'Tek başına mod için bilgisayarınızda ""1C:Enterprise"" platformu
		| sürüm %1 yüklü olmalıdır.'"),
		DataExchangeSaaS.RequiredPlatformVersion());
	
	Object.StandaloneWorkstationDescription = StandaloneModeInternal.GenerateDefaultStandaloneWorkstationDescription();
	
	// Setting the current navigation table
	StandaloneWorkstationCreatingScript();
	
	ForceCloseForm = False;
	
	StandaloneWorkstationCreationEventLogMessageText = StandaloneModeInternal.StandaloneWorkstationCreationEventLogMessageText();
	
	BigFilesTransferSupported = StandaloneModeInternal.BigFilesTransferSupported();
	
	// Granting user rights for data synchronization
	
	Items.UserRightsSettings.Visible = False;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		SynchronizationUsers.Load(SynchronizationUsers());
		
		Items.UserRightsSettings.Visible = SynchronizationUsers.Count() > 1;
		
	EndIf;
	
	// Thin client tooltip
	ThinClientSetupGuideAddress = DataExchangeSaaS.ThinClientSetupGuideAddress();
	If IsBlankString(ThinClientSetupGuideAddress) Then
		Items.CopyInitialImageToUserComputer.ToolTipRepresentation = ToolTipRepresentation.None;
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Object.WebServiceURL = OnlineApplicationAddress();
	
	// Selecting the first wizard step
	NavigationNumber = 1;	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Items.PanelMain.CurrentPage = Items.Ending Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("CancelStandaloneWorkstationGeneration", ThisObject);
	
	WarningText = NStr("vi = 'Hủy tạo chỗ làm việc độc lập?';
						|ru = 'Отменить создание автономного рабочего места?';
						|en = 'Do you want to cancel creation of a standalone workstation?'; fa = 'Do you want to cancel creation of a standalone workstation?';
						|it = 'Annullare la creazione della postazione di lavoro autonomo?';
						|pl = 'Anulować tworzenie miejsca pracy w trybie offline?';
						|tr = 'Çevrimdışı çalışma alanı oluşturma işlemi geri alınsın mı?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm", CallbackDescription);
	
EndProcedure

// Wait handlers

&AtClient
Procedure TimeConsumingOperationIdleHandler()
	
	Try
		
		If JobCompleted(JobID) Then
			
			TimeConsumingOperation = False;
			TimeConsumingOperationCompleted = True;
			JobID = Undefined;
			
			GoToNext();
			
		Else
			AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
		EndIf;
		
	Except
		TimeConsumingOperation = False;
		GoToTheErrorPage();
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện giao dịch.';
								|ru = 'Не удалось выполнить операцию.';
								|en = 'Cannot perform the operation.'; fa = 'Cannot perform the operation.';
								|it = 'Impossibile eseguire l''operazione.';
								|pl = 'Operacja nie powiodła się.';
								|tr = 'İşlem yapılamıyor.'"));
		
		ExecutionErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	
		WriteErrorToEventLog(
			ExecutionErrorText,
			StandaloneWorkstationCreationEventLogMessageText);
	EndTry;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StandaloneWorkstationSetupInstructionDocumentComplete(Item)
	
	// Print command visibility.
	If Not Item.Document.queryCommandSupported("Print") Then
		Items.StandaloneWorkstationSetupGuidePrintGuide.Visible = False;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Supplied part

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	
	ForceCloseForm = True;
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

// The overridable part

&AtClient
Procedure SetUpDataTransferRestrictions(Command)
	
	NodeSettingFormName = "ExchangePlan.[ExchangePlanName].Form.NodeConfigurationForm";
	NodeSettingFormName = StrReplace(NodeSettingFormName, "[ExchangePlanName]", ExchangePlanName);
	
	FormParameters = New Structure("NodeFiltersSetting, CorrespondentVersion", NodeFiltersSetting, "");
	Handler = New CallbackDescription("SetUpDataTransferRestrictionsCompletion", ThisObject);
	Mode = FormWindowOpeningMode.LockOwnerWindow;
	
	OpenForm(NodeSettingFormName, FormParameters, ThisObject,,,,Handler, Mode);
	
EndProcedure

&AtClient
Procedure SetUpDataTransferRestrictionsCompletion(OpeningResult, AdditionalParameters) Export
	
	If OpeningResult <> Undefined Then
		
		For Each FilterSettings In NodeFiltersSetting Do
			
			NodeFiltersSetting[FilterSettings.Key] = OpeningResult[FilterSettings.Key];
			
		EndDo;
		
		Items.DataTransferRestrictionsDetails.Title = DataTransferRestrictionsDetails(ExchangePlanName, NodeFiltersSetting);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyInitialImageToUserComputer(Command)
	
	If BigFilesTransferSupported Then
		FileData = GetFromTempStorage(InitialImageTempStorageAddress);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("InstallationPackageFileID", FileData.InstallationPackageFileID);
		
		CallbackDescriptionOnCompletion = New CallbackDescription(
			"CopyInitialImageToUserComputerCompletion",
			ThisObject,
			AdditionalParameters);
		
		ModuleNameCTLFilesClient = "FilesCTLClient";	
		ModuleCTLFilesClient    = CommonClient.CommonModule(ModuleNameCTLFilesClient);
		
		FileGettingParameters = ModuleCTLFilesClient.FileGettingParameters();
		FileGettingParameters.FileNameOrAddress = FileData.FileNameOrAddress;
		FileGettingParameters.WindowsFilePath = FileData.WindowsFilePath;
		FileGettingParameters.LinuxFilePath   = FileData.LinuxFilePath;
		FileGettingParameters.BlockedForm = ThisObject;
		
		FileGettingParameters.TitleOfSaveDialog = NStr("vi = 'Lưu lại gói cài đặt';
														|ru = 'Сохранение пакета установки';
														|en = 'Saving installation package'; fa = 'Saving installation package';
														|it = 'Salvataggio del pacchetto di installazione';
														|pl = 'Zapisywanie pakietu instalacji';
														|tr = 'Kurulum paketini kaydet'");
		FileGettingParameters.FilterSaveDialog    = NStr("vi = 'Tệp nén ZIP (*.zip)|*.zip';
														|ru = 'Архивы ZIP (*.zip)|*.zip';
														|en = 'ZIP archive (*.zip)|*.zip'; fa = 'ZIP archive (*.zip)|*.zip';
														|it = 'Archivi ZIP (*.zip)|*.zip';
														|pl = 'Archiwa ZIP (*.zip)|*.zip';
														|tr = 'ZIP arşivleri (*.zip)|*.zip'");
		FileGettingParameters.FileNameOfSaveDialog  = InstallPackageFileName;
		
		FileGettingParameters.CallbackDescriptionOnCompletion = CallbackDescriptionOnCompletion;
		
		ModuleCTLFilesClient.GetFileInteractively(FileGettingParameters);
		
	Else
		FileToReceive = New Structure;
		FileToReceive.Insert("Name",      InstallPackageFileName);
		FileToReceive.Insert("Location", InitialImageTempStorageAddress);
		
		DialogParameters = New Structure;
		DialogParameters.Insert("Filter", NStr("vi = 'Tệp nén ZIP (*.zip)|*.zip';
												|ru = 'Архивы ZIP (*.zip)|*.zip';
												|en = 'ZIP archive (*.zip)|*.zip'; fa = 'ZIP archive (*.zip)|*.zip';
												|it = 'Archivi ZIP (*.zip)|*.zip';
												|pl = 'Archiwa ZIP (*.zip)|*.zip';
												|tr = 'ZIP arşivleri (*.zip)|*.zip'"));
		
		DataExchangeClient.SelectAndSaveFileAtClient(FileToReceive, DialogParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure HowToInstallOrUpdate1CEnterprisePlatfomVersion(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("TemplateName", "HowToInstallOrUpdate1CEnterprisePlatfomVersion");
	FormParameters.Insert("Title", NStr("vi = 'Làm thế nào để cài đặt hoặc cập nhật phiên bản nền tảng 1C:Enterprise';
										|ru = 'Как установить или обновить версию платформы 1С:Предприятие';
										|en = 'How to install or update 1C:Enterprise platform'; fa = 'نحوه نصب یا به‌روزرسانی پلتفرم 1C:Enterprise';
										|it = 'Come impostare o aggiornare la versione della piattaforma 1C:Enterprise';
										|pl = 'Jak zainstalować lub zaktualizować wersję platformy 1C:Enterprise';
										|tr = '1C:Enterprise platformunun sürümü nasıl yüklenir veya güncellenir'"));
	
	OpenForm("DataProcessor.StandaloneWorkstationCreationWizard.Form.AdditionalDetails", FormParameters, ThisObject, "HowToInstallOrUpdate1CEnterprisePlatfomVersion");
	
EndProcedure

&AtClient
Procedure PrintGuide(Command)
	
	Items.StandaloneWorkstationSetupInstruction.Document.execCommand("Print");
	
EndProcedure

&AtClient
Procedure SaveGuideAs(Command)
	
	FileToReceive = New Structure;
	FileToReceive.Insert("Name",      NStr("vi = 'Hướng dẫn tùy chỉnh chỗ làm việc độc lập.html';
											|ru = 'Инструкция по настройке автономного рабочего места.html';
											|en = 'How to set up standalone workstations.html'; fa = 'How to set up standalone workstations.html';
											|it = 'Istruzioni per le impostazioni della postazione di lavoro autonoma.html';
											|pl = 'Instrukcja konfiguracji miejsca pracy w trybie offline.html';
											|tr = 'Çevrimdışı çalışma alanı ayarı için talimatlar.html'"));
	FileToReceive.Insert("Location", GetTemplate());
	
	DialogParameters = New Structure;
	DialogParameters.Insert("Filter", NStr("vi = 'Trang web, chỉ HTML (*.html)|*.html';
											|ru = 'Веб-страница, только HTML (*.html)|*.html';
											|en = 'Web page, only HTML (*.html)|*.html'; fa = 'Web page, only HTML (*.html)|*.html';
											|it = 'Pagina web, solo HTML (*.html)|*.html';
											|pl = 'Strona internetowa, tylko HTML (*.html)|*.html';
											|tr = 'Web sayfası, yalnızca HTML (*.html)|*.html'"));
	
	DataExchangeClient.SelectAndSaveFileAtClient(FileToReceive, DialogParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CopyInitialImageToUserComputerCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		DeleteInstallationPackageFile(AdditionalParameters.InstallationPackageFileID);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeleteInstallationPackageFile(InstallationPackageFileID)
	
	Try
		InstallPackageFileName = DataExchangeServer.GetFileFromStorage(InstallationPackageFileID);
		InstallationPackageFile = New File(InstallPackageFileName);
		If InstallationPackageFile.Exists() Then
			DeleteFiles(InstallPackageFileName);
		EndIf;
	Except
		WriteLogEvent(
			StandaloneModeInternal.StandaloneWorkstationCreationEventLogMessageText(),
			EventLogLevel.Error,
			,
			,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsersPermitDataSynchronization.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SynchronizationUsers.DataSynchronizationPermitted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Procedure CopyInitialImageToUserComputerExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "ThinClientSetupGuideAddress" Then
		StandardProcessing = False;
		FileSystemClient.OpenURL(ThinClientSetupGuideAddress);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ExtensionsThatChangeDataStructure()
	
	ExtensionsThatChangeDataStructure = New Array;
	
	SetPrivilegedMode(True);
	ScopeExtensions = ConfigurationExtensions.Get();
	
	For Each Extension In ScopeExtensions Do
		
		If Not Extension.ModifiesDataStructure() Then
			Continue;
		EndIf;
		
		ExtensionsThatChangeDataStructure.Add(Extension.Synonym);
		
	EndDo;
	
	Return ExtensionsThatChangeDataStructure;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Supplied part

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	
	NavigationNumber = Value;
	
	If NavigationNumber < 0 Then
		
		NavigationNumber = 0;
		
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Run navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Set up page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	// Set the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If ConfirmButton <> Undefined Then
			
			ConfirmButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
	If IsMoveNext And NavigationRowCurrent.TimeConsumingOperation Then
		
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// OnNavigationToNextPage handler.
		If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
			And Not NavigationRow.TimeConsumingOperation Then
			
			ProcedureName = "[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
			
			Cancel = False;
			
			CalculationResult = Eval(ProcedureName);
			
			If Cancel Then
				
				SetNavigationNumber(NavigationNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// OnNavigationToPreviousPage handler.
		If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
			And Not NavigationRow.TimeConsumingOperation Then
			
			ProcedureName = "[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
			
			Cancel = False;
			
			CalculationResult = Eval(ProcedureName);
			
			If Cancel Then
				
				SetNavigationNumber(NavigationNumber + 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(NavigationNumber - 1);
			
			Return;
			
		ElsIf SkipPage Then
			
			IsMoveNext = True;	
			SetNavigationNumber(NavigationNumber + 1);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationHandler handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			GoToTheErrorPage();
			
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(NavigationNumber + 1);
			
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(NavigationNumber + 1);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Function NavigationTableNewRow(MainPageName, NavigationPageName, DecorationPageName = "")
	
	NewRow = NavigationTable.Add();
	
	NewRow.NavigationNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	NewRow.DecorationPageName    = DecorationPageName;
	NewRow.NavigationPageName    = NavigationPageName;
	
	Return NewRow;
	
EndFunction

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			And StrFind(Item.CommandName, CommandName) > 0 Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServer
Function GetTemplate()
	
	TempFileName = GetTempFileName();
	TextDocument = New TextDocument;
	TextDocument.SetText(StandaloneWorkstationSetupInstruction);
	TextDocument.Write(TempFileName);
	BinaryData = New BinaryData(TempFileName);
	DeleteFiles(TempFileName);
	
	Return PutToTempStorage(BinaryData, UUID);
	
EndFunction

&AtClient
Procedure CancelStandaloneWorkstationGeneration(Result, AdditionalParameters) Export
	
	If ValueIsFilled(JobID) Then
		
		ExchangeNode = CancelJobExecution(JobID, Object.StandaloneWorkstation);
		If ValueIsFilled(ExchangeNode) Then
			Object.StandaloneWorkstation = ExchangeNode;
		EndIf;
		
	EndIf;
	
	If Object.StandaloneWorkstation <> Undefined Then
		DataExchangeServerCall.DeleteSynchronizationSetting(Object.StandaloneWorkstation);
		Notify("DeleteStandaloneWorkstation");
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Redefined part - Service procedures and functions

&AtServer
Procedure CreateStandaloneWorkstationInitialImageAtServer(Cancel)
	
	Filter = New Structure("DataSynchronizationPermitted, PermitDataSynchronization", False, True);
	SelectedSynchronizationUsers = SynchronizationUsers.Unload(Filter, "User").UnloadColumn("User");
	
	WizardContext = New Structure(
		"WebServiceURL, StandaloneWorkstationDescription, StandaloneWorkstation");
	FillPropertyValues(WizardContext, Object);
	
	WizardContext.Insert("NodeFiltersSetting", NodeFiltersSetting);
	WizardContext.Insert("SelectedSynchronizationUsers", SelectedSynchronizationUsers);
	
	Try
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo ảnh ban đầu của chỗ làm việc độc lập';
															|ru = 'Создание начального образа автономного рабочего места';
															|en = 'Create initial image of standalone workstation'; fa = 'Create initial image of standalone workstation';
															|it = 'Creazione dell''immagine iniziale della postazione di lavoro autonoma';
															|pl = 'Tworzenie początkowego obrazu miejsca pracy w trybie offline';
															|tr = 'Çevrimdışı çalışma alanı ilk görünümünü oluştur'");
		ExecutionParameters.AdditionalResult = True;
		ExecutionParameters.RunNotInBackground1 = False;
		
		BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
			"StandaloneModeInternal.CreateStandaloneWorkstationInitialImage",
			WizardContext,
			ExecutionParameters);
		
		InitialImageTempStorageAddress           = BackgroundJob.ResultAddress;
		InstallationPackageInformationTempStorageAddress = BackgroundJob.AdditionalResultAddress;
		
		If BackgroundJob.Status = "Running" Then
			TimeConsumingOperation = True;
			JobID = BackgroundJob.JobID;
		ElsIf BackgroundJob.Status = "Completed2" Then
			InstallPackageInformation = GetFromTempStorage(InstallationPackageInformationTempStorageAddress);
			InstallPackageFileSize = InstallPackageInformation.InstallPackageFileSize;
			InstallPackageFileName    = InstallPackageInformation.InstallPackageFileName;
		Else
			ErrorMessage = BackgroundJob.BriefErrorDescription;
			If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
				ErrorMessage = BackgroundJob.DetailErrorDescription;
			EndIf;
			
			Raise ErrorMessage;
		EndIf;
		
	Except
		Cancel = True;
		
		ExecutionErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteErrorToEventLog(
			ExecutionErrorText,
			StandaloneWorkstationCreationEventLogMessageText);
		Return;
	EndTry;
	
EndProcedure

&AtServerNoContext
Function DataTransferRestrictionsDetails(Val ExchangePlanName, NodeFiltersSetting)
	
	Return DataExchangeServer.DataTransferRestrictionsDetails(ExchangePlanName, NodeFiltersSetting, "");
	
EndFunction

&AtClient
Function OnlineApplicationAddress()
	
	ConnectionParameters = StringFunctionsClientServer.ParametersFromString(InfoBaseConnectionString());
	
	If Not ConnectionParameters.Property("ws") Then
		Raise NStr("vi = 'Chỉ có thể tạo chỗ làm việc độc lập ở chế độ Web-client.';
					|ru = 'Создать автономное рабочее место можно только в режиме веб-клиента.';
					|en = 'Standalone workstation creation is available in web client only.'; fa = 'Standalone workstation creation is available in web client only.';
					|it = 'È possibile creare una postazione di lavoro autonoma solo in modalità web-client.';
					|pl = 'Utworzyć miejsca pracy w trybie offline można tylko w trybie klienta sieci internetowej.';
					|tr = 'Çevrimdışı çalışma alanı yalnızca web istemcisi modunda oluşturulabilir.'");
	EndIf;
	
	Return ConnectionParameters.ws;
EndFunction

&AtClient
Procedure GoToNext()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure GoToTheErrorPage()
	
	// Assign NavigationNumber with a value to skip handlers that handle the previous steps.
	NavigationNumber = NavigationTable.Count();
	SetNavigationNumber(NavigationTable.Count());
	
EndProcedure

&AtServerNoContext
Procedure WriteErrorToEventLog(ErrorMessageString, Event)
	
	WriteLogEvent(Event, EventLogLevel.Error,,, ErrorMessageString);
	
EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

&AtServerNoContext
Function CancelJobExecution(Val JobID, Val ExchangeNode)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
	If Not ValueIsFilled(ExchangeNode) Then
		
		ExchangePlanName = StandaloneModeInternal.StandaloneModeExchangePlan();
		ExchangeNode = ExchangePlans[ExchangePlanName].FindByCode(String(JobID));
		
	EndIf;
	
	If ValueIsFilled(ExchangeNode) Then
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleCommonCTL = Common.CommonModule("CommonCTL");
			ModuleCommonCTL.Pause(2);
		EndIf;
		
		StandaloneModeInternal.DeleteObsoleteExchangeMessages(ExchangeNode);
		
	EndIf;
	
	Return ExchangeNode;
	
EndFunction

&AtServer
Function SynchronizationUsers()
	
	Result = New ValueTable;
	Result.Columns.Add("User"); // Type: CatalogRef.Users
	Result.Columns.Add("DataSynchronizationPermitted", New TypeDescription("Boolean"));
	Result.Columns.Add("PermitDataSynchronization", New TypeDescription("Boolean"));
	
	QueryText =
	"SELECT
	|	Users.Ref AS User,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	NOT Users.DeletionMark
	|	AND NOT Users.Invalid
	|	AND NOT Users.IsInternal
	|
	|ORDER BY
	|	Users.Description";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.IBUserID) Then
			
			IBUser = InfoBaseUsers.FindByUUID(Selection.IBUserID);
			
			If IBUser <> Undefined Then
				
				UserSettings = Result.Add();
				UserSettings.User = Selection.User;
				UserSettings.DataSynchronizationPermitted = DataExchangeServer.DataSynchronizationPermitted(IBUser);
				UserSettings.PermitDataSynchronization = UserSettings.DataSynchronizationPermitted;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// The redefined part is Transition event Handlers

&AtClient
Function Attachable_ExportSettingsOnGoNext(Cancel)
	
	If IsBlankString(Object.StandaloneWorkstationDescription) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa đặt tên gọi chỗ làm việc độc lập.';
										|ru = 'Не задано наименование автономного рабочего места.';
										|en = 'Standalone workstation description is not specified.'; fa = 'Standalone workstation description is not specified.';
										|it = 'Non è stato assegnato nessun nome alla postazione di lavoro autonoma.';
										|pl = 'Nie określono nazwy miejsca pracy w trybie offline.';
										|tr = 'Çevrimdışı çalışma alanı tanımı belirlenmedi.'"),
			, "Object.StandaloneWorkstationDescription", , Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_InitialImageCreationWaitingTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	TimeConsumingOperation = False;
	TimeConsumingOperationCompleted = False;
	JobID = Undefined;
	
	CreateStandaloneWorkstationInitialImageAtServer(Cancel);
	
	If Cancel Then
		
		//
		
	ElsIf Not TimeConsumingOperation Then
		
		Notify("CreateStandaloneWorkstation");
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_InitialImageCreationWaitingTimeConsumingOperationTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If TimeConsumingOperation Then
		
		GoToNext = False;
		
		AttachIdleHandler("TimeConsumingOperationIdleHandler", 5, True);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_InitialImageCreationWaitingTimeConsumingOperationCompletionTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If TimeConsumingOperationCompleted Then
		
		InstallPackageInformation = GetFromTempStorage(InstallationPackageInformationTempStorageAddress);
		InstallPackageFileSize = InstallPackageInformation.InstallPackageFileSize;
		InstallPackageFileName    = InstallPackageInformation.InstallPackageFileName;
		
		Notify("CreateStandaloneWorkstation");
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_EndOnOpen(Cancel, SkipPage, IsMoveNext)
	
	ItemTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 (%2 MB)';
			|ru = '%1 (%2 МБ)';
			|en = '%1 (%2 MB)'; fa = '%1 (%2 MB)';
			|it = '%1 (%2 MB)';
			|pl = '%1 (%2 MB)';
			|tr = '%1 (%2 MB)'"),
		InstallPackageFileName,
		Format(Round(InstallPackageFileSize / (1024 * 1024), 1), "NFD=1; NG=3,0"));
	Items.CopyInitialImageToUserComputer.Title = ItemTitle;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PresenceOfExtensionsThatChangeDataStructure_WhenOpened(Cancel, SkipPage, IsMoveNext)
	
	Extensions = ExtensionsThatChangeDataStructure();
	SkipPage = Extensions.Count() = 0;
	
	ExtensionsThatChangeDataStructure.LoadValues(Extensions);
	
	Return Undefined;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// The redefined part is Initialization of assistant transitions

&AtServer
Procedure StandaloneWorkstationCreatingScript()
	
	NavigationTable.Clear();
	
	NewNavigation = NavigationTableNewRow("HasExtensionsThatChangeDataStructure", "NavigationEndPage");
	NewNavigation.OnOpenHandlerName = "Attachable_PresenceOfExtensionsThatChangeDataStructure_WhenOpened";
	
	NewNavigation = NavigationTableNewRow("Begin", "NavigationStartPage");
	
	NewNavigation = NavigationTableNewRow("ExportSetting", "NavigationPageFollowUp");
	NewNavigation.OnNavigationToNextPageHandlerName = "Attachable_ExportSettingsOnGoNext";
	
	NewNavigation = NavigationTableNewRow("InitialImageCreationWaiting", "NavigationWaitPage");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_InitialImageCreationWaitingTimeConsumingOperationProcessing";
	
	NewNavigation = NavigationTableNewRow("InitialImageCreationWaiting", "NavigationWaitPage");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_InitialImageCreationWaitingTimeConsumingOperationTimeConsumingOperationProcessing";
	
	NewNavigation = NavigationTableNewRow("InitialImageCreationWaiting", "NavigationWaitPage");
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_InitialImageCreationWaitingTimeConsumingOperationCompletionTimeConsumingOperationProcessing";
	
	NewNavigation = NavigationTableNewRow("Ending", "NavigationEndPage");
	NewNavigation.OnOpenHandlerName = "Attachable_EndOnOpen";
	
	NewNavigation = NavigationTableNewRow("ExecutionError", "NavigationEndPage");
	
EndProcedure

#EndRegion
