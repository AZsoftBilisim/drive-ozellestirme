
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ThisIsCA = GetFunctionalOption("ComplexAutomation");
	UseBudgetProcess = GetFunctionalOption("UseBudgetProcess");
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExecutedImportStatus = False;
	// Setting the current transition table
	ScriptTransitions();
	// Positioning ourselves at the first step of the assistant
	SetNavigationNumber(1);
	
	Items.PageStagesOfBudgetPreparation.Visible = UseBudgetProcess;

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ModelFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription(
		"ModelFileNameExtensionEnabled",
		ThisObject);
	
	FileSystemClient.AttachFileOperationsExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure BudgetProfilesFlagOnChange(Item)
	
	CurrentData = Items.BudgetProfiles.CurrentData;
	SetSubordinateMarks(CurrentData, "Flag");
	SetParentMarks(CurrentData, "Flag");
	
EndProcedure

&AtClient
Procedure BudgetingStepsFlagOnChange(Item)
	
	CurrentData = Items.BudgetingSteps.CurrentData;
	SetSubordinateMarks(CurrentData, "Flag");
	SetParentMarks(CurrentData, "Flag");
	
EndProcedure

&AtClient
Procedure BudgetingModelOnChange(Item)
	
	ChangingBudgetingModel();
	
EndProcedure

&AtClient
Procedure DetailedInformationClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("Data", SynonymOfProcessing());
	
	FilterByLevel = New ValueList;
	FilterByLevel.Add("Error", "Error");
	FormParameters.Insert("Level", FilterByLevel);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	If ValueIsFilled(JobID) Then
		CompleteBackgroundTask(JobID);
	EndIf;
	
	Close();
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	Tree = Undefined;
	If Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageTypesOfBudgets Then
		Tree = BudgetProfiles;
	ElsIf  Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageStagesOfBudgetPreparation Then
		Tree = BudgetingSteps;
	Else
		Return;
	EndIf;
	
	For Each String In Tree.GetItems() Do
		String.Flag = True;
		SetSubordinateMarks(String, "Flag");
	EndDo;
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	Tree = Undefined;
	If Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageTypesOfBudgets Then
		Tree = BudgetProfiles;
	ElsIf  Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageStagesOfBudgetPreparation Then
		Tree = BudgetingSteps;
	Else
		Return;
	EndIf;
	
	For Each String In Tree.GetItems() Do
		String.Flag = False;
		SetSubordinateMarks(String, "Flag");
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region SectionInitializingTransitionsInAssistant

// Transition parameters.
// 
// Returns:
//  Structure - Transition Parameters:
// * NavigationNumber - Number -
// * MainPageName - String -
// * NavigationPageName - String -
// * DecorationPageName - String -
// * OnOpenHandlerName - String -
// * NameOfTheHandlerAfterOpening - String -
// * OnNavigationToNextPageHandlerName - String -
// * OnSwitchToPreviousPageHandlerName - String -
&AtClient
Function MigrationParameters()
	
	MigrationParameters = New Structure;
	MigrationParameters.Insert("NavigationNumber", 0);
	MigrationParameters.Insert("MainPageName", "");
	MigrationParameters.Insert("NavigationPageName", "");
	MigrationParameters.Insert("DecorationPageName", "");
	MigrationParameters.Insert("OnOpenHandlerName", "");
	MigrationParameters.Insert("NameOfTheHandlerAfterOpening", "");
	MigrationParameters.Insert("OnNavigationToNextPageHandlerName", "");
	MigrationParameters.Insert("OnSwitchToPreviousPageHandlerName", "");
	
	Return MigrationParameters;
	
EndFunction

&AtClient
Procedure ScriptTransitions()
	
	Transitions.Clear();
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 1;
	MigrationParameters.MainPageName = "PageGreeting";
	MigrationParameters.NavigationPageName = "NavigationStartPage";
	MigrationParameters.DecorationPageName = "DecorationPageStart";
	MigrationParameters.OnOpenHandlerName = "PageGreeting_OnOpen";
	MigrationParameters.OnNavigationToNextPageHandlerName = "PageGreeting_OnOpenNext";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 2;
	MigrationParameters.MainPageName = "PageFilters";
	MigrationParameters.NavigationPageName = "NavigationPageBackNext";
	MigrationParameters.DecorationPageName = "NavigationPageBackNext";
	MigrationParameters.OnOpenHandlerName = "PageFilters_WhenOpening";
	MigrationParameters.OnNavigationToNextPageHandlerName = "PageFilters_WhenGoingNext";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 3;
	MigrationParameters.MainPageName = "WaitingPage";
	MigrationParameters.NavigationPageName = "NavigationWaitPage";
	MigrationParameters.DecorationPageName = "PageSceneryWaiting";
	MigrationParameters.OnOpenHandlerName = "WaitingPage_OnOpen";
	MigrationParameters.NameOfTheHandlerAfterOpening = "WaitingPage_AfterOpen";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 4;
	MigrationParameters.MainPageName = "PageCompletion";
	MigrationParameters.NavigationPageName = "NavigationEndPage";
	MigrationParameters.DecorationPageName = "DecorationPageEnd";
	MigrationParameters.OnOpenHandlerName = "PageCompletion_OnOpen";
	AddTransition(MigrationParameters);
	
EndProcedure

&AtServer
Procedure AddTransition(MigrationParameters)
	
	NewRow = Transitions.Add();
	
	NewRow.NavigationNumber = MigrationParameters.NavigationNumber;
	NewRow.MainPageName     = MigrationParameters.MainPageName;
	NewRow.DecorationPageName    = MigrationParameters.DecorationPageName;
	NewRow.NavigationPageName    = MigrationParameters.NavigationPageName;
	
	NewRow.OnNavigationToNextPageHandlerName = MigrationParameters.OnNavigationToNextPageHandlerName;
	NewRow.OnSwitchToPreviousPageHandlerName = MigrationParameters.OnSwitchToPreviousPageHandlerName;
	NewRow.OnOpenHandlerName      = MigrationParameters.OnOpenHandlerName;
	NewRow.NameOfTheHandlerAfterOpening    = MigrationParameters.NameOfTheHandlerAfterOpening;
	
EndProcedure

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
	
	// Click event handlers
	If IsMoveNext Then
		
		NavigationRows = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// The handler is later
		If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName) Then
			
			ProcedureName = "Attachable_[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
			
			Cancel = False;
			
			Result = Eval(ProcedureName);
			
			If Cancel Then
				SetNavigationNumber(NavigationNumber - 1);
				Return;
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;
		
		NavigationRow = NavigationRows[0];
		
		// The handler is pre-transitioned
		If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName) Then
			
			ProcedureName = "Attachable_[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
			
			Cancel = False;
			
			Result = Eval(ProcedureName);
			
			If Cancel Then
				SetNavigationNumber(NavigationNumber + 1);
				Return;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Return;
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// handler for opening
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);

		Cancel = False;
		SkipPage = False;
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			SetNavigationNumber(NavigationNumber - 1);
			Return;
		ElsIf SkipPage Then
			If IsMoveNext Then
				SetNavigationNumber(NavigationNumber + 1);
				Return;
			Else
				SetNavigationNumber(NavigationNumber - 1);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	// Setting the current page display
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	AttachIdleHandler("ExecuteHandlerAfterOpening", 0.1, True);
	
EndProcedure

&AtClient
Procedure ExecuteHandlerAfterOpening()
	
	NavigationRowsCurrent = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Return;
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// Post-opening handler
	If Not IsBlankString(NavigationRowCurrent.NameOfTheHandlerAfterOpening) Then
		
		ProcedureName = "Attachable_[HandlerName]()";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.NameOfTheHandlerAfterOpening);
		
		Result = Eval(ProcedureName);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region TransitionEventHandlersSection

&AtClient
Function Attachable_PageGreeting_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	Items.NextCommand.DefaultButton = True;
	Title = NStr("vi = 'Kết xuất mô hình ngân sách.';
				|ru = 'Выгрузка модели бюджетирования.';
				|en = 'Budgeting model export.'; fa = 'Budgeting model export.';
				|it = 'Upload dei modelli di budgeting.';
				|pl = 'Ładowanie modelu budżetowania.';
				|tr = 'Bütçeleme modellerinin dışa aktarımı.'");
		
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageGreeting_OnOpenNext(Cancel)
	
	ClearMessages();
	
	If Not ValueIsFilled(BudgetingModel) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra Mô hình lập ngân sách';
				|ru = 'Не указана Модель бюджетирования';
				|en = 'Budgeting model is not specified'; fa = 'Budgeting model is not specified';
				|it = 'Non è stato indicato il modello di budgeting';
				|pl = 'Nie podano modelu budżetowania';
				|tr = 'Bütçeleme modeli belirtilmedi'"), , "BudgetingModel", "BudgetingModel", Cancel);
	EndIf;
	
	If Not ValueIsFilled(TrimAll(Object.ModelFileName)) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra đường dẫn đến tệp dữ liệu';
				|ru = 'Не указан путь к файлу с данными';
				|en = 'Path to the file with data is not specified'; fa = 'Path to the file with data is not specified';
				|it = 'Non è stato specificato il percorso al file dei dati';
				|pl = 'Nie jest podana ścieżka do pliku z danymi';
				|tr = 'Veri dosyasının yolu belirtilmemiş'"), , "ModelFileName", "ModelFileName", Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageFilters_WhenOpening(Cancel, SkipPage, Val IsMoveNext)
	
	Items.NextCommand.DefaultButton = True;
	Title = NStr("vi = 'Chọn dạng ngân sách và các giai đoạn chuẩn bị ngân sách được kết xuất.';
				|ru = 'Выбор выгружаемых видов бюджетов и этапов подготовки бюджетов.';
				|en = 'Select exported budget kinds and budgeting steps.'; fa = 'Select exported budget kinds and budgeting steps.';
				|it = 'Selezione di tipologie di bilancio da caricare (upload) e fasi di preparazione dei bilanci.';
				|pl = 'Wybór ładowanych rodzajów budżetów i etapów przygotowania budżetów.';
				|tr = 'Yüklenen bütçe profilinin seçimi ve bütçe hazırlama aşamaları.'");
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageFilters_WhenGoingNext(Cancel)
	
	ClearMessages();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageCompletion_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	Items.DoneCommand.DefaultButton = True;
	Items.DownloadStatusLabel.Title =
		?(ExecutedImportStatus,
			NStr("vi = 'Đã kết xuất thành công';
				|ru = 'Выгрузка успешно завершена';
				|en = 'Successfully imported'; fa = 'Successfully imported';
				|it = 'Upload terminato cono successo';
				|pl = 'Ładowanie zostało pomyślnie ukończone';
				|tr = 'Yükleme işlemi başarıyla tamamlandı'"),
			NStr("vi = 'Chưa kết xuất';
				|ru = 'Выгрузка не выполнена';
				|en = 'Export failed'; fa = 'Export failed';
				|it = 'Upload non completato';
				|pl = 'Nie wykonano eksportu';
				|tr = 'Yükleme işlemi gerçekleştirilmedi'"));
			
	Items.LabelOfContinuationOptions.Title = 
		?(ExecutedImportStatus,
			NStr("vi = 'Hãy nhấn nút ""Đồng ý"" để thoát khỏi trợ giúp.';
				|ru = 'Нажмите кнопку ""Готово"" для выхода из помощника.';
				|en = 'Click ""Finish"" to exit the wizard.'; fa = 'برای خروج از ویزارد روی «پایان» کلیک کنید.';
				|it = 'Cliccare il pulsante ""Completato"" per uscire dall''assistente.';
				|pl = 'Wciśnij przycisk ""Gotowe"", aby wyjść z asystenta.';
				|tr = 'Sihirbazdan çıkmak için ""Bitti"" butonuna tıklayın.'"),
			NStr("vi = 'Để thử kết nhập lần nữa, hãy nhấn nút ""Tiếp theo"" để thoát khỏi trợ giúp, hãy nhấn nút ""Đồng ý""';
				|ru = 'Для того чтобы попробовать загрузить еще раз, нажмите ""Назад"", для выхода из помощника, нажимите ""Готово""';
				|en = 'To try to import again, click ""Back""; click ""Finish"" to exit the wizard'; fa = 'To try to import again, click ""Back""; click ""Finish"" to exit the wizard';
				|it = 'Per riprovare premere ""Indietro"", per uscire dall''assistente premere ""Fine""';
				|pl = 'Aby spróbować pobrać jeszcze raz, naciśnij przycisk ""Wstecz"", aby wyjść z kreatora, kliknij przycisk ""Zakończ""';
				|tr = 'Tekrar indirmeyi denemek için ""Geri""ye basın, sihirbazdan çıkmak için ""Tamam""a basın'"));
	
	FillInSummaryInformation();
	
	Title = NStr("vi = 'Kết xuất mô hình ngân sách.';
				|ru = 'Выгрузка модели бюджетирования.';
				|en = 'Budgeting model export.'; fa = 'Budgeting model export.';
				|it = 'Upload dei modelli di budgeting.';
				|pl = 'Ładowanie modelu budżetowania.';
				|tr = 'Bütçeleme modellerinin dışa aktarımı.'");
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPage_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	If Not IsMoveNext Then
		
		SkipPage = True;
		
	EndIf;
	
	Title = NStr("vi = 'Kết xuất mô hình ngân sách.';
				|ru = 'Выгрузка модели бюджетирования.';
				|en = 'Budgeting model export.'; fa = 'Budgeting model export.';
				|it = 'Upload dei modelli di budgeting.';
				|pl = 'Ładowanie modelu budżetowania.';
				|tr = 'Bütçeleme modellerinin dışa aktarımı.'");
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPage_AfterOpen()
	
	TimeConsumingOperation = UploadToServer();
	
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("RecordResult", ThisObject, StorageAddress);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Function UploadToServer()
	
	UploadData_0 = ExportImportOfFinancialAccountingAndBudgetingModels.UnloadingDataTable();
	
	MetadataObjectsList = Metadata.Catalogs.BudgetingModels;
	ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetingModel, ValueToArray(BudgetingModel));
	
	MetadataObjectsList = Metadata.Catalogs.BudgetingLimits;
	ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetingModel, ValueToArray(BudgetingModel), "Owner");
	
	SelectedBudgetTypes = GetSelectedSelectionItems(BudgetProfiles, "Ref");
	For Each BudgetProfile In SelectedBudgetTypes Do
		
		MetadataObjectsList = Metadata.Catalogs.BudgetProfiles;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetProfile, ValueToArray(BudgetProfile));
		
		MetadataObjectsList = Metadata.Catalogs.FinancialReportItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetProfile, ValueToArray(BudgetProfile), "Owner");

		UploadedBudgetIndicators = UploadedBudgetIndicators(BudgetProfile);
		
		MetadataObjectsList = Metadata.Catalogs.ActualDataQueryRulesByBudgetBalanceItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetProfile, UploadedBudgetIndicators, "BudgetBalanceItem");

		MetadataObjectsList = Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetProfile, UploadedBudgetIndicators, "Receiver");
		
		UnloadedBudgetItems = UnloadedBudgetItems(BudgetProfile);
		
		MetadataObjectsList = Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetProfile, UnloadedBudgetItems, "BudgetFlowItem");

		MetadataObjectsList = Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetProfile, UnloadedBudgetItems, "Source");
		
		DownloadableTemplatesForEnteringNonFinancialIndicators = DownloadableTemplatesForEnteringNonFinancialIndicators(BudgetProfile);
		MetadataObjectsList = Metadata.Catalogs.NonFinancialItemProfiles;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetProfile, DownloadableTemplatesForEnteringNonFinancialIndicators);

	EndDo;
	SelectedStagesOfBudgetPreparation = GetSelectedSelectionItems(BudgetingSteps, "Ref");
	For Each BudgetPreparationStage In SelectedStagesOfBudgetPreparation Do
		MetadataObjectsList = Metadata.Catalogs.BudgetingSteps;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, BudgetPreparationStage, ValueToArray(BudgetPreparationStage));
	EndDo;
	JobParameters = New Structure;
	JobParameters.Insert("UploadData_0", UploadData_0);
	JobParameters.Insert("ThisIsBudgetingModel", True);
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	JobParameters.Insert("StorageAddress", StorageAddress);
	
	MethodName = "ExportImportOfFinancialAccountingAndBudgetingModels.ExportAccountingModel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = SynonymOfProcessing();
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Procedure FillInSummaryInformation()
	
	HasErrors = Not ExecutedImportStatus;
	
	Items.DetailedInformation.Visible = HasErrors;
	Items.Information.Visible = HasErrors;
	If HasErrors Then
		Information =  NStr("vi = 'Lỗi:';
							|ru = 'Ошибка:';
							|en = 'Error:'; fa = 'Error:';
							|it = 'Errore:';
							|pl = 'Błąd:';
							|tr = 'Hata:'") + Chars.LF + ExchangeProtocol.GetText();
	EndIf;
	
EndProcedure

&AtServer
Procedure CompleteBackgroundTask(JobID)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	If BackgroundJob <> Undefined Then
		BackgroundJob.Cancel();
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordResult(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				ExecutedImportStatus = False;
				ExchangeProtocol.SetText(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				ExecutedImportStatus = True;
				FileSystemClient.SaveFile(Undefined, AdditionalParameters, Object.ModelFileName);
			EndIf;
			ChangeNavigationNumber(+1);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ModelFileNameExtensionEnabled(Result, AdditionalParameters) Export 
	
	OpenFileDialog = New FileDialog(FileDialogMode.Save);
	OpenFileDialog.Filter =  NStr("vi = 'Tệp kết xuất';
									|ru = 'Файл выгрузки';
									|en = 'Export file'; fa = 'فایل خروج';
									|it = 'File di upload';
									|pl = 'Plik przesyłania';
									|tr = 'Dışa aktarma dosyası'") + "(*.xml)|*.xml";
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn đường dẫn đến tệp kết xuất mô hình kế toán';
								|ru = 'Выберите путь к файлу выгрузки модели учета';
								|en = 'Select a path to the file of accounting model export'; fa = 'Select a path to the file of accounting model export';
								|it = 'Seleziona il percorso del file di caricamento del modello di bilancio';
								|pl = 'Wybierz ścieżkę do pliku ładowania modelu ewidencji';
								|tr = 'Muhasebe modeli yükleme dosyasının yolunu seçin'");
	
	CallbackDescription = New CallbackDescription(
		"ModelFileNameShowCompletionDialog",
		ThisObject);
		
	OpenFileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure ModelFileNameShowCompletionDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Object.ModelFileName = SelectedFiles[0];
	
EndProcedure

&AtClient
Procedure ChangingBudgetingModel()
	
	FillInTreeOfBudgetTypes();
	If Not ThisIsCA Then
		FillInTreeStagesOfBudgetPreparation();
	EndIf;
	
	// Let's open the top level of the tree
	TreeItems = BudgetProfiles.GetItems();
	For Each TreeItem In TreeItems Do
		Items.BudgetProfiles.Expand(TreeItem.GetID());
	EndDo;
	TreeItems = BudgetingSteps.GetItems();
	For Each TreeItem In TreeItems Do
		Items.BudgetingSteps.Expand(TreeItem.GetID());
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTreeOfBudgetTypes()
	
	Layout = DataProcessors.BudgetingModelExportImportWizard.GetTemplate("BudgetProfiles");
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Layout));
	SettingsComposer.LoadSettings(Layout.DefaultSettings);
	
	FinancialReportingServer.SetLayoutParameter(SettingsComposer.Settings, "Owner", BudgetingModel);
	
	ResultTree_ = FinancialReportingServer.UploadDCSResults(Layout,SettingsComposer.Settings,, True);
	
	ValueToFormAttribute(ResultTree_, "BudgetProfiles");
	
EndProcedure

&AtServer
Procedure FillInTreeStagesOfBudgetPreparation()
	
	If Not UseBudgetProcess Then
		Return;
	EndIf;
	
	Layout = DataProcessors.BudgetingModelExportImportWizard.GetTemplate("BudgetingSteps");
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Layout));
	SettingsComposer.LoadSettings(Layout.DefaultSettings);
	
	FinancialReportingServer.SetLayoutParameter(SettingsComposer.Settings, "Owner", BudgetingModel);
	
	ResultTree_ = FinancialReportingServer.UploadDCSResults(Layout,SettingsComposer.Settings,, True);
	
	ValueToFormAttribute(ResultTree_, "BudgetingSteps");
	
EndProcedure

// Sets the marking state for subordinate rows of the value tree
// row, depending on the marking of the current row.
//
// Parameters:
//  CurRow - ValueTreeRow - Tree Line
//  CheckBoxName - String - Name of the tree column
// 
&AtClient
Procedure SetSubordinateMarks(CurRow, CheckBoxName)
	
	SubordinateItems = CurRow.GetItems();
	
	If SubordinateItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In SubordinateItems Do
		
		String[CheckBoxName] = CurRow[CheckBoxName];
		
		SetSubordinateMarks(String, CheckBoxName);
		
	EndDo;
	
EndProcedure

// Sets the marking state for parent rows of the value tree
// row, depending on the marking of the current row.
//
// Parameters:
//  CurRow - ValueTreeRow - Tree Line
//  CheckBoxName - String - Name of the tree column
// 
&AtClient
Procedure SetParentMarks(CurRow, CheckBoxName)
	
	Parent = CurRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf; 
	
	CurState = Parent[CheckBoxName];
	
	EnabledItemsFound  = False;
	DisabledItemsFound = False;
	
	For Each String In Parent.GetItems() Do
		If String[CheckBoxName] = 0 Then
			DisabledItemsFound = True;
		ElsIf String[CheckBoxName] = 1
			Or String[CheckBoxName] = 2 Then
			EnabledItemsFound  = True;
		EndIf; 
		If EnabledItemsFound And DisabledItemsFound Then
			Break;
		EndIf; 
	EndDo;
	
	If EnabledItemsFound And DisabledItemsFound Then
		Enable = 2;
	ElsIf EnabledItemsFound And (Not DisabledItemsFound) Then
		Enable = 1;
	ElsIf (Not EnabledItemsFound) And DisabledItemsFound Then
		Enable = 0;
	ElsIf (Not EnabledItemsFound) And (Not DisabledItemsFound) Then
		Enable = 2;
	EndIf;
	
	If Enable = CurState Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentMarks(Parent, CheckBoxName);
	EndIf; 
	
EndProcedure

&AtServer
Function GetSelectedSelectionItems(SelectionTree_,ColumnName)
	
	SelectedValues = New Array;
	TreeItems = SelectionTree_.GetItems();
	For Each TreeItems In TreeItems Do
		If TreeItems.Flag Then
			SelectedValues.Add(TreeItems[ColumnName]);
			SubordinateValues = GetSelectedSelectionItems(TreeItems,ColumnName);
			For Each Value In SubordinateValues Do
				SelectedValues.Add(Value);
			EndDo;
		EndIf;
	EndDo;
	
	Return SelectedValues;
	
EndFunction

&AtServer
Function UploadedBudgetIndicators(BudgetProfile)
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	BudgetProfilesItemAndIndicatorCache.ItemIndicator AS BudgetIndicator
		|FROM
		|	Catalog.BudgetProfiles.ItemAndIndicatorCache AS BudgetProfilesItemAndIndicatorCache
		|WHERE
		|	BudgetProfilesItemAndIndicatorCache.Ref = &BudgetProfile
		|	AND BudgetProfilesItemAndIndicatorCache.ItemIndicator REFS Catalog.BudgetBalanceItems";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	
	BudgetBalanceItems = Query.Execute().Unload().UnloadColumn("BudgetIndicator");
	
	Return BudgetBalanceItems;
	
EndFunction

&AtServer
Function UnloadedBudgetItems(BudgetProfile)
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	BudgetProfilesItemAndIndicatorCache.ItemIndicator AS BudgetFlowOrBalanceItem
		|FROM
		|	Catalog.BudgetProfiles.ItemAndIndicatorCache AS BudgetProfilesItemAndIndicatorCache
		|WHERE
		|	BudgetProfilesItemAndIndicatorCache.Ref = &BudgetProfile
		|	AND BudgetProfilesItemAndIndicatorCache.ItemIndicator REFS Catalog.BudgetFlowItems";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	
	UnloadedBudgetItems = Query.Execute().Unload().UnloadColumn("BudgetFlowOrBalanceItem");
	
	Return UnloadedBudgetItems;
	
EndFunction

&AtServer
Function DownloadableTemplatesForEnteringNonFinancialIndicators(BudgetProfile)

	Query = New Query;
	Query.Text = "SELECT DISTINCT
	               |	BudgetProfilesItemAndIndicatorCache.ItemIndicator AS NonFinancialBudgetIndicator
	               |INTO NonFinancialItemsOfBudgets
	               |FROM
	               |	Catalog.BudgetProfiles.ItemAndIndicatorCache AS BudgetProfilesItemAndIndicatorCache
	               |WHERE
	               |	BudgetProfilesItemAndIndicatorCache.Ref = &BudgetProfile
	               |	AND BudgetProfilesItemAndIndicatorCache.ItemIndicator REFS Catalog.NonFinancialItemsOfBudgets
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT DISTINCT
	               |	TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.Ref AS TemplateForEnteringNonFinancialIndicators
	               |FROM
	               |	NonFinancialItemsOfBudgets AS NonFinancialItemsOfBudgets
	               |		LEFT JOIN Catalog.NonFinancialItemProfiles.TemplateIndicators AS TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators
	               |		ON NonFinancialItemsOfBudgets.NonFinancialBudgetIndicator.Ref = TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.Factor
	               |WHERE
	               |	NOT TemplatesForEnteringNonFinancialIndicatorsTemplateIndicators.Ref IS NULL";
	
	Query.SetParameter("BudgetProfile", BudgetProfile);
	
	BudgetBalanceItems = Query.Execute().Unload().UnloadColumn("TemplateForEnteringNonFinancialIndicators");
	
	Return BudgetBalanceItems;
	
EndFunction

&AtServer
Function SynonymOfProcessing()
	Return Metadata.DataProcessors.BudgetingModelExportImportWizard.Synonym;
EndFunction

&AtServer
Function ValueToArray(Value)

	Array = New Array;
	Array.Add(Value);
	Return Array;

EndFunction
#EndRegion

#EndRegion
