
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
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
Procedure DimensionKindsOnActivateRow(Item)

	DisplayControlPageReplaceValues();

EndProcedure

&AtClient
Procedure BudgetProfilesFlagOnChange(Item)
	
	CurrentData = Items.BudgetProfiles.CurrentData;
	SetSubordinateMarks(CurrentData, "Flag");
	SetParentMarks(CurrentData, "Flag");
	
EndProcedure

&AtClient
Procedure StagesOfBudgetsFlagOnChange(Item)
	
	CurrentData = Items.BudgetingSteps.CurrentData;
	SetSubordinateMarks(CurrentData, "Flag");
	SetParentMarks(CurrentData, "Flag");
	
EndProcedure

&AtClient
Procedure ReplaceDimensionValuesDimensiondbOnChange(Item)
	
	TypesOfAnalystToCalculate(Items.ReplaceDimensionValues.CurrentData.Type);
	
EndProcedure

&AtClient
Procedure DisplayAllDimensionsOnChange(Item)

	DisplayControlPageReplaceValues();

EndProcedure

&AtClient
Procedure BudgetProfilesRefreshOnChange(Item)
	
	CurrentData = Items.BudgetProfiles.CurrentData;
	SetUpdateTypesOfBudgetMilestonesFlag(CurrentData);
	
EndProcedure

&AtClient
Procedure BudgetingStepsRefreshOnChange(Item)
	
	CurrentData = Items.BudgetingSteps.CurrentData;
	SetUpdateTypesOfBudgetMilestonesFlag(CurrentData);
	
EndProcedure

&AtClient
Procedure UpdateModelOnChange(Item)
	
	FlagForUpdateModelWhenChanging();
	
EndProcedure

&AtClient
Procedure BudgetProfilesRefreshStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.BudgetProfiles.CurrentData;
	Item.ChoiceList.Clear();
	ChoiceList = AvailableAction(CurrentData);
	For Each Page1 In ChoiceList Do
		NewRow = Item.ChoiceList.Add();
		FillPropertyValues(NewRow,Page1);
	EndDo;
	
EndProcedure

&AtClient
Procedure BudgetingStepsRefreshStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.BudgetingSteps.CurrentData;
	Item.ChoiceList.Clear();
	ChoiceList = AvailableAction(CurrentData);
	For Each Page1 In ChoiceList Do
		NewRow = Item.ChoiceList.Add();
		FillPropertyValues(NewRow,Page1);
	EndDo;
	
EndProcedure

&AtClient
Procedure BudgetProfilesDescriptionOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.BudgetProfiles.CurrentData;
	If ValueIsFilled(CurrentData.Ref) Then
		ShowValue(,CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure TheStagesOfTheBudgetNameOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.BudgetingSteps.CurrentData;
	If ValueIsFilled(CurrentData.Ref) Then
		ShowValue(,CurrentData.Ref);
	EndIf;

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
	MigrationParameters.DecorationPageName = "SceneryPageBackNext";
	MigrationParameters.OnOpenHandlerName = "PageFilters_WhenOpening";
	MigrationParameters.OnNavigationToNextPageHandlerName = "PageFilters_WhenGoingNext";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 3;
	MigrationParameters.MainPageName = "PageReplaceValues";
	MigrationParameters.NavigationPageName = "NavigationPageBackNext";
	MigrationParameters.DecorationPageName = "SceneryPageBackNext";
	MigrationParameters.OnOpenHandlerName = "PageReplacing_ValuesWhenOpened";
	MigrationParameters.OnNavigationToNextPageHandlerName = "PageReplacing_ValuesWhenGoingNext";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 4;
	MigrationParameters.MainPageName = "WaitingPage";
	MigrationParameters.NavigationPageName = "NavigationWaitPage";
	MigrationParameters.DecorationPageName = "PageSceneryWaiting";
	MigrationParameters.OnOpenHandlerName = "WaitingPage_OnOpen";
	MigrationParameters.NameOfTheHandlerAfterOpening = "WaitingPage_AfterOpen";
	AddTransition(MigrationParameters);
	
	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 5;
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
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageGreeting_OnOpenNext(Cancel)
	
	ClearMessages();
	
	If IsBlankString(Object.ModelFileName) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra đường dẫn đến tệp dữ liệu';
				|ru = 'Не указан путь к файлу с данными';
				|en = 'Path to the file with data is not specified'; fa = 'Path to the file with data is not specified';
				|it = 'Non è stato specificato il percorso al file dei dati';
				|pl = 'Nie jest podana ścieżka do pliku z danymi';
				|tr = 'Veri dosyasının yolu belirtilmemiş'"), , "ModelFileName", "ModelFileName", Cancel);
		Return Undefined;
	EndIf;
	
	Handler = New CallbackDescription("PuttingFileOnServerEnds", ThisForm);
	BeginPutFileToServer(Handler, , , StorageAddress, Object.ModelFileName, UUID);
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageFilters_WhenOpening(Cancel, SkipPage, Val IsMoveNext)
	
	Items.NextCommand.DefaultButton = True;
	Title = NStr("vi = 'Chọn dạng ngân sách và các giai đoạn chuẩn bị ngân sách được kết nhập.';
				|ru = 'Выбор загружаемых видов бюджетов и этапов подготовки бюджетов.';
				|en = 'Select budget profiles to import and budgeting steps.'; fa = 'Select budget profiles to import and budgeting steps.';
				|it = 'Выбор загружаемых видов бюджетов и этапов подготовки бюджетов.';
				|pl = 'Select budget profiles to import and budgeting steps.';
				|tr = 'İndirilen bütçe profilinin seçimi ve bütçe hazırlama aşamaları.'");
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageFilters_WhenGoingNext(Cancel)
	
	ClearMessages();
	PerformActionsBeforeUploadingToServer();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageReplacing_ValuesWhenOpened(Cancel, SkipPage, Val IsMoveNext)
	
	DisplayAllDimensions = True;
	Title = NStr("vi = 'So sánh giá trị đã kết nhập';
				|ru = 'Сопоставление загружаемых значений';
				|en = 'Map values to import'; fa = 'Map values to import';
				|it = 'Сопоставление загружаемых значений';
				|pl = 'Map values to import';
				|tr = 'İndirilen değerin eşleştirme'");
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageReplacing_ValuesWhenGoingNext(Cancel)
	
	ClearMessages();
	CheckingAnalyticsContentBeforeUploading(Cancel);
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	Title = NStr("vi = 'Kết nhập mô hình ngân sách.';
				|ru = 'Загрузка модели бюджетирования.';
				|en = 'Import a budgeting model.'; fa = 'Import a budgeting model.';
				|it = 'Загрузка модели бюджетирования.';
				|pl = 'Import a budgeting model.';
				|tr = 'Bütçeleme modellerinin indirilmesi.'");
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPage_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	If Not IsMoveNext Then
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPage_AfterOpen()
	
	LoadModel();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageCompletion_OnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	Items.DoneCommand.DefaultButton = True;
	Items.DownloadStatusLabel.Title = 
		?(ExecutedImportStatus,
			NStr("vi = 'Đã kết nhập thành công';
				|ru = 'Загрузка успешно завершена';
				|en = 'Imported successfully'; fa = 'Imported successfully';
				|it = 'Download terminato con successo';
				|pl = 'Pobieranie zostało zakończone powodzeniem';
				|tr = 'İndirme işlemi başarıyla tamamlandı'"),
			NStr("vi = 'Chưa kết nhập';
				|ru = 'Загрузка не выполнена';
				|en = 'Import failed'; fa = 'ورود اطلاعات ناموفق بود';
				|it = 'Download non completato';
				|pl = 'Nie wykonano importu';
				|tr = 'İndirme işlemi tamamlanmadı'"));
	
	Items.LabelOfContinuationOptions.Title = 
		?(ExecutedImportStatus,
		NStr("vi = 'Hãy nhấn nút ""Đồng ý"" để thoát khỏi trợ giúp';
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
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure LoadModel()
	
	TimeConsumingOperation = UploadToServer_1();
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("ImportIsCompleted", ThisObject);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtClient
Procedure PuttingFileOnServerEnds(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Lỗi xử lý tệp';
										|ru = 'Ошибка обработки файла';
										|en = 'File processing error'; fa = 'File processing error';
										|it = 'Errore elaborazione file';
										|pl = 'Błąd przetwarzania pliku';
										|tr = 'Dosyanın veri işlemesinde hata'"));
		Return;
	EndIf;
	
	StorageAddress = Result.Address;
	If Not ValueIsFilled(StorageAddress) Then
		CommonClient.MessageToUser(NStr("vi = 'Lỗi xử lý tệp';
										|ru = 'Ошибка обработки файла';
										|en = 'File processing error'; fa = 'File processing error';
										|it = 'Errore elaborazione file';
										|pl = 'Błąd przetwarzania pliku';
										|tr = 'Dosyanın veri işlemesinde hata'"));
		Return;
	EndIf;
	
	StorageAddress = Result.Address;
	
	FillFiltersBasedOnXMLData();
	FlagForUpdateModelWhenChanging();
	ExpandTopLevelOfShapeTree(BudgetProfiles,"BudgetProfiles");
	ExpandTopLevelOfShapeTree(BudgetingSteps,"BudgetingSteps");
	Items.StateGroup.Visible = False;
	Items.BudgetProfiles.Visible = True;
	
EndProcedure

&AtServer
Function UploadToServer_1()

	ReplaceableUIN = ReplaceableUIN();
	
	JobParameters = New Structure;
	JobParameters.Insert("BinaryData", GetFromTempStorage(StorageAddress));
	JobParameters.Insert("ThisIsBudgetingModel", True);
	JobParameters.Insert("SelectedBudgetTypes", GetSelectedSelectionItems(BudgetProfiles,"WIN"));

	JobParameters.Insert("ReplaceableUIN", ReplaceableUIN);
	JobParameters.Insert("DownloadableUIN", ArrayOfUploadedUINs(ReplaceableUIN));
	JobParameters.Insert("ReplaceDimensionValues", ReplaceDimensionValues.Unload(,"PaymentIDFileDimension,Dimensiondb,SourceReference"));
	
	JobParameters.Insert("UseSourceCodesOfDownloadedData", UseSourceCodesOfDownloadedData);

	MethodName = "ExportImportOfFinancialAccountingAndBudgetingModels.ImportAccountingModel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = SynonymOfProcessing();
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function ReplaceableUIN()
	
	UploadingFilter = New ValueTable;
	UploadingFilter.Columns.Add("ObjectFileUIN", New TypeDescription("String"));
	UploadingFilter.Columns.Add("Refresh", New TypeDescription("Boolean"));
	UploadingFilter.Columns.Add("ObjectNewUIN", New TypeDescription("String"));
	
	NewFilter1 = UploadingFilter.Add();
	NewFilter1.ObjectFileUIN = UINBudgetingModel;
	NewFilter1.Refresh = UpdateModel;
	If ValueIsFilled(BudgetingModelLink) And Not UpdateModel Then
		NewFilter1.ObjectNewUIN = XMLString(New UUID);
	Else
		NewFilter1.ObjectNewUIN = UINBudgetingModel;
	EndIf;
	
	AddSelectedSelectionElements(UploadingFilter, BudgetProfiles); 
	AddSelectedSelectionElements(UploadingFilter, BudgetingSteps);
	
	ReplaceableUIN = New ValueTable;
	ReplaceableUIN.Columns.Add("SearchRef", New TypeDescription("String"));
	ReplaceableUIN.Columns.Add("ReplacementLink", New TypeDescription("String"));
	ReplaceableUIN.Columns.Add("ThisIsReplacementAnalyst", New TypeDescription("Boolean"));
	
	For Each String In UploadingFilter Do
		If String.ObjectFileUIN <> String.ObjectNewUIN Then
			NewRow = ReplaceableUIN.Add();
			NewRow.SearchRef = String.ObjectFileUIN;
			NewRow.ReplacementLink = String.ObjectNewUIN;
		EndIf;
	EndDo;
	
	For Each String In ReplaceDimensionValues Do
		String.AnalyticsBDUIN = XMLString(String.Dimensiondb);
		If String.PaymentIDFileDimension <> String.AnalyticsBDUIN Then
			NewRow = ReplaceableUIN.Add();
			NewRow.SearchRef = String.PaymentIDFileDimension;
			NewRow.ReplacementLink = String.AnalyticsBDUIN;
			NewRow.ThisIsReplacementAnalyst = True;
		EndIf;
	EndDo;
	
	If ValueIsFilled(BudgetingModelLink) And Not UpdateModel Then
		AdditionalTypesToReplace = AdditionalTypesOfModelCompositionReferencesToReplace();
		For Each FileElement In FileElements Do
			If AdditionalTypesToReplace.Find(FileElement.Type) <> Undefined Then
				NewRow = ReplaceableUIN.Add();
				NewRow.SearchRef = FileElement.WIN;
				NewRow.ReplacementLink = XMLString(New UUID);
			EndIf;
		EndDo;
	EndIf;
	
	Return ReplaceableUIN;
	
EndFunction

&AtServer
Function ArrayOfUploadedUINs(ReplaceableUIN)
	
	IndexOf = DownloadableUIN.Count() - 1;
	While IndexOf >= 0 Do
		Item = DownloadableUIN[IndexOf];
		ReplacementString = ReplaceableUIN.Find(Item.Value, "SearchRef");
		If ReplacementString <> Undefined Then
			If ReplacementString.ThisIsReplacementAnalyst Then
				DownloadableUIN.Delete(Item);
			Else
				Item.Value = ReplacementString.ReplacementLink;
			EndIf;
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return TMCommonUse.DeleteDuplicateElementsFromArray(DownloadableUIN.UnloadValues());
	
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
							|tr = 'Hata:'") + Chars.LF+ ExchangeProtocol.GetText();
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportIsCompleted(Result, AdditionalParameters) Export
	
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
			EndIf;
			FillInSummaryInformation();
			ChangeNavigationNumber(+1);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ModelFileNameExtensionEnabled(Result, AdditionalParameters) Export 
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
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

&AtServer
Function SynonymOfProcessing()
	Return Metadata.DataProcessors.BudgetingModelExportImportWizard.Synonym;
EndFunction

&AtServer
Procedure FillFiltersBasedOnXMLData()
	
	TempDataFileName = GetTempFileName("xml");
	BinaryData = GetFromTempStorage(StorageAddress);
	BinaryData.Write(TempDataFileName);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(TempDataFileName); 
	DOMBuilder = New DOMBuilder;
	DOMDocument  = DOMBuilder.Read(XMLReader);
	
	TypesOfBudgetsTree = FormAttributeToValue("BudgetProfiles");
	TypesOfBudgetsTree.Rows.Clear();
	StagesOfBudgetPreparationTree = FormAttributeToValue("BudgetingSteps");
	StagesOfBudgetPreparationTree.Rows.Clear();
	FileElements.Clear();
	
	TypesOfBudgetStagesUsed = New Array();
	
	DataBlock = DOMDocument.GetElementByTagName("Data");
	
	For Each Data In DataBlock Do
		For Each DataElement In Data.ChildNodes Do
			
			ElementTypeString = DataElement.LocalName;
			
			ReadingResult = New Structure;	
			
			ObjectAttributes = DataElement.ChildNodes;
			For Each Attribute In ObjectAttributes Do 
				If Attribute.LocalName = "Description" Then
					ReadingResult.Insert("Description",Attribute.TextContent);
				ElsIf Attribute.LocalName = "Code" Then
					ReadingResult.Insert("Code",Attribute.TextContent);
				ElsIf Attribute.LocalName = "Ref" Then
					ReadingResult.Insert("WIN",Attribute.TextContent);
				ElsIf Attribute.LocalName = "Parent" Then
					ReadingResult.Insert("PaymentIDParent",Attribute.TextContent);
				ElsIf Attribute.LocalName = "IsFolder" Then
					IsFolder  = Boolean(Attribute.TextContent);
					ReadingResult.Insert("IsFolder", IsFolder);
					ReadingResult.Insert("PictureIndex",Not IsFolder);
				ElsIf Attribute.LocalName = "TIN" Then
					ReadingResult.Insert("TIN",Attribute.TextContent);
				ElsIf Attribute.LocalName = "CRTR" Then
					ReadingResult.Insert("CRTR",Attribute.TextContent);
				EndIf;
			EndDo;
			
			If ElementTypeString = "CatalogObject.BudgetingModels" Then
				
				UINBudgetingModel = ReadingResult.WIN;
				UID = New UUID(ReadingResult.WIN);
				FoundModel = Catalogs.BudgetingModels.GetRef(UID);
				If ValueIsFilled(Common.ObjectAttributeValue(FoundModel, "Description")) Then
					BudgetingModelLink = FoundModel;
					TypesOfBudgetStagesUsed = GetUsedTypesOfBudgetStages(BudgetingModelLink); 
					UpdateModel = True;
				Else
					UpdateModel = False;
				EndIf;
				
			ElsIf ElementTypeString = "CatalogObject.BudgetProfiles" Then
				
				Nw = TypesOfBudgetsTree.Rows.Add();
				FillPropertyValues(Nw,ReadingResult);
				UID = New UUID(Nw.WIN);
				BudgetTypeFound = Catalogs.BudgetProfiles.GetRef(UID);
				If ValueIsFilled(Common.ObjectAttributeValue(BudgetTypeFound, "Description")) Then
					Nw.Ref = BudgetTypeFound;
					If Not TypesOfBudgetStagesUsed.Find(BudgetTypeFound) = Undefined Then
						Nw.Used = True;
					EndIf;
				EndIf;
			ElsIf ElementTypeString = "CatalogObject.BudgetingSteps" Then
				
				Nw = StagesOfBudgetPreparationTree.Rows.Add();
				FillPropertyValues(Nw,ReadingResult);
				UID = New UUID(Nw.WIN);
				FoundBudgetStage = Catalogs.BudgetingSteps.GetRef(UID);
				AttributesOfBudgetStage = Common.ObjectAttributesValues(FoundBudgetStage, "Description, Code");
				If ValueIsFilled(AttributesOfBudgetStage.Description) Or ValueIsFilled(AttributesOfBudgetStage.Code) Then
					Nw.Ref = FoundBudgetStage;
					If Not TypesOfBudgetStagesUsed.Find(FoundBudgetStage) = Undefined Then
						Nw.Used = True;
					EndIf;
				EndIf;                                                                          
			EndIf;

			If StrFind(ElementTypeString, "InformationRegisterRecordSet") <> 0 Then
				Continue;
			EndIf;

			ElementTypeString = StrReplace(ElementTypeString, "CatalogObject", "CatalogRef");
			ElementTypeString = StrReplace(ElementTypeString, "ChartOfCharacteristicTypesObject", "ChartOfCharacteristicTypesRef");
			ElementTypeString = StrReplace(ElementTypeString, "ChartOfAccountsObject", "ChartOfAccountsRef");
			
			NewRow = FileElements.Add();
			TypesArray = New Array;
			TypesArray.Add(Type(ElementTypeString));
			DescriptionOfTypesOfAnilytics = New TypeDescription(TypesArray);
			NewRow.Type = DescriptionOfTypesOfAnilytics;
			NewRow.StringType = ElementTypeString;
			If ReadingResult.Property("Description") Then
				NewRow.Description = ReadingResult.Description;
			EndIf;
			If ReadingResult.Property("Code") Then
				NewRow.Code = ReadingResult.Description;
			EndIf;
			If ReadingResult.Property("IsFolder") And ReadingResult.IsFolder Then
				NewRow.IsFolder = True;
			EndIf;
			If ReadingResult.Property("WIN") Then
				NewRow.WIN = ReadingResult.WIN;
			EndIf;
			If ReadingResult.Property("TIN") Then
				NewRow.TIN = ReadingResult.TIN;
			EndIf;
			If ReadingResult.Property("CRTR") Then
				NewRow.CRTR = ReadingResult.CRTR;
			EndIf;
			
		EndDo;
	EndDo;
	
	RestoreFilterTreeHierarchy(TypesOfBudgetsTree);
	ValueToFormAttribute(TypesOfBudgetsTree,"BudgetProfiles");
	RestoreFilterTreeHierarchy(StagesOfBudgetPreparationTree);
	ValueToFormAttribute(StagesOfBudgetPreparationTree,"BudgetingSteps");
	XMLReader.Close();
	DeleteFiles(TempDataFileName);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReplaceDimensionValuesDimensiondb.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplaceDimensionValues.EntryHelpOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "ValueNotFound";
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplaceDimensionValues.Dimensiondb");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplaceDimensionValues.NSITovarnogoPlanning");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("Text",      NStr("vi = '<Không tìm thấy giá trị của đối tượng phân tích.>';
																	|ru = '<Значение аналитики не найдено.>';
																	|en = '<Dimension value is not found.>'; fa = '<Dimension value is not found.>';
																	|it = '<Значение аналитики не найдено.>';
																	|pl = '<Dimension value is not found.>';
																	|tr = '<Boyut değeri bulunamadı.>'"));
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReplaceDimensionValuesDimensiondb.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplaceDimensionValues.EntryHelpOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "ValueNotFound";
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplaceDimensionValues.Dimensiondb");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplaceDimensionValues.NSITovarnogoPlanning");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	AppearanceItem.Appearance.SetParameterValue("Text",      NStr("vi = '<Hãy chọn tương ứng.>';
																	|ru = '<Выбирите соответствие.>';
																	|en = '<Select a mapping.>'; fa = '<Select a mapping.>';
																	|it = '<Выбирите соответствие.>';
																	|pl = '<Select a mapping.>';
																	|tr = '<Uygunluk seçiniz.>'"));
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReplaceDimensionValuesDimensiondb.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplaceDimensionValues.EntryHelpOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NoRightsToMapItem";
	
	AppearanceItem.Appearance.SetParameterValue("Text",      NStr("vi = '<Giá trị tìm thấy không hợp lệ đối với người sử dụng hiện tại do hạn chế theo bản ghi. Hãy liên hệ với người quản trị.>';
																	|ru = '<Найденное значение недоступно для текущего пользователя из-за ограничений по записям. Обратитесь к администратору базы.>';
																	|en = '<The found value is unavailable to the current user due to the record limit. Contact the database administrator.>'; fa = '<The found value is unavailable to the current user due to the record limit. Contact the database administrator.>';
																	|it = '<Найденное значение недоступно для текущего пользователя из-за ограничений по записям. Обратитесь к администратору базы.>';
																	|pl = '<The found value is unavailable to the current user due to the record limit. Contact the database administrator.>';
																	|tr = '<Bulunan değer, kayıtlara göre gerçekleştirilen kısıtlamalar sebebiyle mevcut kullanıcının kullanımına müsait değil. Taban yöneticisine ulaşınız.>'"));
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
EndProcedure

&AtServer
Procedure PerformActionsBeforeUploadingToServer()
	
	If Not CheckingBeforeLoading() Then
		Return;
	EndIf;
	
	FillInUploadedUINBasedOnXMLData();
	CompleteReplacementOfAnalystValuesByXMLData();
	
EndProcedure

&AtServer
Procedure CheckingAnalyticsContentBeforeUploading(Cancel)
	
	For Each AnalyticsReplacementString In ReplaceDimensionValues Do
	
		If Not ValueIsFilled(AnalyticsReplacementString.Dimensiondb) Then
			
			Cancel = True;
			
			MessageText = NStr("vi = 'Chưa điền giá trị đối tượng phân tích: %1. Không thể kết nhập mô hình, hãy chọn giá trị đối tượng phân tích.';
								|ru = 'Не заполнено значение аналитики: %1. Загрузка модели не может быть выполнена, выберите значение аналитики.';
								|en = 'A dimension value is not filled: %1. Cannot import the model. Select a dimension value.'; fa = 'A dimension value is not filled: %1. Cannot import the model. Select a dimension value.';
								|it = 'Не заполнено значение аналитики: %1. Загрузка модели не может быть выполнена, выберите значение аналитики.';
								|pl = 'A dimension value is not filled: %1. Cannot import the model. Select a dimension value.';
								|tr = 'Boyut değerleri doldurulmamış: %1. Modellerin indirilmesi gerçekleştirilemez, bir boyut değeri seçiniz.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, AnalyticsReplacementString.DimensionFile_);
			Common.MessageToUser(MessageText);
			
		EndIf;
	
	EndDo;
	
EndProcedure

&AtServer
Function CheckingBeforeLoading()
	CheckPassed = True;
	
	Search = New Structure("IsFolder", False);
	TypesOfDataToLoad = FileElements.Unload(Search, "StringType").UnloadColumn("StringType");
	TypesOfDataToLoad = CommonClientServer.CollapseArray(TypesOfDataToLoad);
	TypesOfAnalystValues = BudgetingServer.AllTypesOfAnalytics().Types();
	
	For Each DataType In TypesOfDataToLoad Do
		If TypesOfAnalystValues.Find(Type(DataType)) = Undefined Then
			Continue;
		EndIf;
		
		MetadataObject = Metadata.FindByType(Type(DataType));
		If Not AccessRight("Read", MetadataObject) Then
			CheckPassed = False;
			
			MessageText = NStr("vi = 'Người sử dụng hiện tại không có quyền đọc bảng %1 cần thiết để kết nhập dữ liệu theo mô hình. Sẽ ngắt kết nhập. Hãy liên hệ với người quản trị.';
								|ru = 'У текущего пользователя нет прав на чтение таблицы %1, необходимой для загрузки данных по модели. Загрузка будет прервана. Обратитесь к администратору базы.';
								|en = 'The current user does not have the rights to read the %1 table required to import model data. The import will be stopped. Contact the database administrator.'; fa = 'The current user does not have the rights to read the %1 table required to import model data. The import will be stopped. Contact the database administrator.';
								|it = 'У текущего пользователя нет прав на чтение таблицы %1, необходимой для загрузки данных по модели. Загрузка будет прервана. Обратитесь к администратору базы.';
								|pl = 'The current user does not have the rights to read the %1 table required to import model data. The import will be stopped. Contact the database administrator.';
								|tr = 'Mevcut kullanıcı, %1 tablolarının okunmasında verilerin modellere göre indirilmesi için gereken yetkiye sahip değil. İndirme kesintiye uğradı. Taban yöneticisine ulaşınız.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
				MetadataObject.FullName());
			
			Common.MessageToUser(MessageText);
		EndIf;
	EndDo;
	
	Return CheckPassed;
EndFunction

&AtServer
Procedure CompleteReplacementOfAnalystValuesByXMLData()
	
	DimensionKinds.Clear();
	ReplaceDimensionValues.Clear();
	TypesOfEstablishedMatches = BudgetingServer.AllTypesOfAnalytics().Types();
	
	TypesOfEstablishedMatches.Add(Type("CatalogRef.SalesOperationsPlanningScenarios"));
	TypesOfEstablishedMatches.Add(Type("CatalogRef.PlanProfiles"));
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TypeOfCommodityPlanningScenario",
		New TypeDescription("CatalogRef.SalesOperationsPlanningScenarios"));
	AdditionalParameters.Insert("TypeTypesOfPlans",
		New TypeDescription("CatalogRef.PlanProfiles"));
	
	For Each FileElement In FileElements Do
		If TypesOfEstablishedMatches.Find(Type(FileElement.StringType)) = Undefined
		 Or FileElement.IsFolder Then
			Continue;
		EndIf;
		
		If Not DownloadableUIN.FindByValue(FileElement.WIN) = Undefined Then
			AddReplacementOfAnalystValues(FileElement, AdditionalParameters);
		EndIf;
	EndDo;
	
	TypesOfAnalystToCalculate();
	
EndProcedure

&AtServer
Procedure RestoreFilterTreeHierarchy(Tree)
	
	If Tree.Rows.Count() = 0 Then
		Return;
	EndIf;
	
	VT = Tree.Copy();
	Tree.Rows.Clear();
	
	For Each SpecificationRow In VT.Rows Do
		
		If Not ValueIsFilled(SpecificationRow.PaymentIDParent) Then
			TreeRow = Tree.Rows.Add();
			FillPropertyValues(TreeRow,SpecificationRow);
		Else
			RowParent = Tree.Rows.Find(SpecificationRow.PaymentIDParent,"WIN",True);
			If Not RowParent = Undefined Then
				TreeRow = RowParent.Rows.Add();
				FillPropertyValues(TreeRow,SpecificationRow);
			Else
				TreeRow = Tree.Rows.Add();
				FillPropertyValues(TreeRow,SpecificationRow);
			EndIf;
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure ExpandTopLevelOfShapeTree(FormTree,TagName)
	
	TreeItems = FormTree.GetItems();
	For Each TreeItem In TreeItems Do
		Items[TagName].Expand(TreeItem.GetID());
	EndDo;
	
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
Procedure AddSelectedSelectionElements(UploadFilters, SelectionTree_)
	
	TreeItems = SelectionTree_.GetItems();
	For Each TreeItems In TreeItems Do
		If TreeItems.Flag Then
			NewFilter1 = UploadFilters.Add();
			NewFilter1.ObjectFileUIN = TreeItems.WIN;
			NewFilter1.Refresh = TreeItems.Refresh;

			If ValueIsFilled(TreeItems.Ref) And Not TreeItems.Refresh Then
				NewFilter1.ObjectNewUIN = XMLString(New UUID);
			Else
				NewFilter1.ObjectNewUIN = TreeItems.WIN;
			EndIf;

			AddSelectedSelectionElements(UploadFilters, TreeItems);
		EndIf;
	EndDo;
	
EndProcedure
&AtServer
Procedure AddReplacementOfAnalystValues(Dimension, AdditionalParameters)
	
	NewRow = ReplaceDimensionValues.Add();
	FillPropertyValues(NewRow,Dimension);
	NewRow.DimensionFile_ = Dimension.Description;
	If Not ValueIsFilled(Dimension.Description)
	   And ValueIsFilled(Dimension.Number)
	   And ValueIsFilled(Dimension.Date) Then
		TypeOfAnalytics = Dimension.Type.Types()[0];
		ObjectMetadata = Metadata.FindByType(TypeOfAnalytics);
		ObjectPresentation = NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'");
		NewRow.DimensionFile_ = StringFunctionsClientServer.SubstituteParametersToString(ObjectPresentation,
		                                                                                     ObjectMetadata.Synonym,
		                                                                                     Dimension.Number,
		                                                                                     Dimension.Date);
	EndIf;
	If Dimension.Type = AdditionalParameters.TypeOfCommodityPlanningScenario Then
		NewRow.NSITovarnogoPlanning = True;
		
		FileAnalyticsPresentation = NStr("vi = '%1 (Tiền tệ %2, Định kỳ %3)';
										|ru = '%1 (Валюта %2, Периодичность %3)';
										|en = '%1 (Currency %2, Frequency %3)'; fa = '%1 (Currency %2, Frequency %3)';
										|it = '%1 (Валюта %2, Периодичность %3)';
										|pl = '%1 (Currency %2, Frequency %3)';
										|tr = '%1 (Para birimi %2, Sıklık %3)'");
		NewRow.DimensionFile_ = StringFunctionsClientServer.SubstituteParametersToString(
			FileAnalyticsPresentation,
			Dimension.Description,
			Dimension.CurrencyOfSalesOperationsPlanningScenario,
			Dimension.FrequencyOfSalesOperationsPlanningScenario);
	ElsIf Dimension.Type = AdditionalParameters.TypeTypesOfPlans Then
		NewRow.NSITovarnogoPlanning = True;
		
		FileAnalyticsPresentation = NStr("vi = '%1 (Kịch bản %2, Kiểu kế hoạch %3)';
										|ru = '%1 (Сценарий %2, Тип плана %3)';
										|en = '%1 (Scenario %2, Plan type %3)'; fa = '%1 (Scenario %2, Plan type %3)';
										|it = '%1 (Сценарий %2, Тип плана %3)';
										|pl = '%1 (Scenario %2, Plan type %3)';
										|tr = '%1 (Senaryo %2, Plan türü %3)'");
		NewRow.DimensionFile_ = StringFunctionsClientServer.SubstituteParametersToString(
			FileAnalyticsPresentation,
			Dimension.Description,
			Dimension.ScenarioOfSalesOperationsPlanningOfPlanProfile,
			Dimension.PlanTypeOfPlanProfile);
	EndIf;
	NewRow.PaymentIDFileDimension = Dimension.WIN;
	
	SearchResult = FindDBAnalytics(Dimension);
	NewRow.Dimensiondb = SearchResult.Value;
	
	If ValueIsFilled(NewRow.Dimensiondb) Then
		NewRow.AnalyticsBDUIN = XMLString(NewRow.Dimensiondb);
	EndIf;
	
	NewRow.SourceReference = SearchResult.SourceReference;
	NewRow.EntryHelpOption = SearchResult.EntryHelpOption;
	If Not ValueIsFilled(NewRow.Dimensiondb) Then
		NewRow.RequiresAttention = True;
	EndIf;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Type",Dimension.Type);
	TypesOfAnalyticsLines = DimensionKinds.FindRows(SearchParameters);
	If TypesOfAnalyticsLines.Count() = 0 Then
		NewRow = DimensionKinds.Add();
		NewRow.Type = Dimension.Type;
		NewRow.Presentation = String(Dimension.Type);
	EndIf;
	
EndProcedure

&AtServer
Procedure TypesOfAnalystToCalculate(Type=Undefined)
	
	For Each Page1 In DimensionKinds Do
		If Type <> Undefined And Page1.Type <> Type Then
			Continue;
		EndIf;
		SearchParameters = New Structure;
		SearchParameters.Insert("Type",Page1.Type);
		ReplacingStringValues = ReplaceDimensionValues.FindRows(SearchParameters);
		Page1.Total = ReplacingStringValues.Count();
		Cnt = 0;
		For Each String In ReplacingStringValues Do
			If Not ValueIsFilled(String.Dimensiondb) Then
				String.RequiresAttention = True;
				Cnt = Cnt + 1;
			EndIf;
		EndDo;
		Page1.NotFilled = Cnt;
		Page1.RequiresAttention = Cnt > 0;
	EndDo;
	
EndProcedure

&AtServer
Function FindDBAnalytics(Dimension)
	
	Dimensiondb = Undefined;
	ObjectName = Mid(Dimension.StringType,StrFind(Dimension.StringType, ".") + 1);
	ObjectKind = Common.ObjectKindByType(Type(Dimension.StringType));
	AnalyticsSearchResult = New Structure("Value, EntryHelpOption, SourceReference", Dimensiondb, "", Undefined);
	
	SearchRequestTexts = New Array;
	RequestSeparator = "
	|
	|UNION ALL
	|
	|";
	
	Query = New Query;
	
	// 1. Link search
	UID = New UUID(Dimension.WIN);
	ObjectManager = Common.ObjectManagerByFullName(ObjectKind + "."+ ObjectName);
	Dimensiondb = ObjectManager.GetRef(UID);
	AnalyticsSearchResult.SourceReference = Dimensiondb;
	
	QueryText = 
	"SELECT
		|	Table.Ref AS Ref,
		|	1 AS Priority
		|FROM
		|	&Table AS Table
		|WHERE
		|	Table.Ref = &Ref";
	
	QueryText = StrReplace(QueryText, "&Table", ObjectKind + "."+ ObjectName);
	SearchRequestTexts.Add(QueryText);
	
	Query.SetParameter("Ref", Dimensiondb);
	
	// 2. Search by code + name
	If ValueIsFilled(Dimension.Code) And ValueIsFilled(Dimension.Description) Then
		QueryText = 
		"SELECT
			|	Table.Ref AS Ref,
			|	2 AS Priority
			|FROM
			|	&Table AS Table
			|WHERE
			|	Table.Code = &Code
			|	AND Table.Description = &Description";
		
		QueryText = StrReplace(QueryText, "&Table", ObjectKind + "."+ ObjectName);
		SearchRequestTexts.Add(QueryText);
		
		Query.SetParameter("Code",Dimension.Code);
		Query.SetParameter("Description",Dimension.Description);
	EndIf;
	
	// 3. for contractors and organizations by TIN + kpp, for individuals only by TIN
	
	If ValueIsFilled(Dimension.TIN) Then
		
		QueryText = 
		"SELECT
			|	Table.Ref AS Ref,
			|	3 AS Priority
			|FROM
			|	&Table AS Table
			|WHERE
			|	Table.TIN = &TIN
			|	AND &ConditionForCheckpoint";
		
		QueryText = StrReplace(QueryText, "&Table", ObjectKind + "."+ ObjectName);
		
		If ValueIsFilled(Dimension.CRTR) Then
			QueryText = StrReplace(QueryText, "&ConditionForCheckpoint", "Table.CRTR = &CRTR");
		Else
			QueryText = StrReplace(QueryText, "&ConditionForCheckpoint", "TRUE");
		EndIf;
		
		SearchRequestTexts.Add(QueryText);
		
		Query.SetParameter("TIN",Dimension.TIN);
		Query.SetParameter("CRTR",Dimension.CRTR);
		
	EndIf;
	
	// 4. Search by name
	If ValueIsFilled(Dimension.Description) Then
		
		QueryText = 
		"SELECT
			|	Table.Ref AS Ref,
			|	4 AS Priority
			|FROM
			|	&Table AS Table
			|WHERE
			|	Table.Description = &Description";
		
		QueryText = StrReplace(QueryText, "&Table", ObjectKind + "."+ ObjectName);
		SearchRequestTexts.Add(QueryText);
		
		Query.SetParameter("Description", Dimension.Description);
	EndIf;
	
	Query.Text = StrConcat(SearchRequestTexts, RequestSeparator) + "
	|
	|ORDER BY
	|	Priority";
	
	SetPrivilegedMode(True);
	LinksWithoutRLS = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	If LinksWithoutRLS.Count() > 0 Then
		
		SearchRule = LinksWithoutRLS[0].Priority;
		
		Query = RequestSchemes.SetSelectionOfAllowedRecords(Query, True);
		AllowedLinks = Query.Execute().Unload();
		
		If AllowedLinks.Count() = 0 Then
			Dimensiondb = Undefined;
			AnalyticsSearchResult.Value = Dimensiondb;
			AnalyticsSearchResult.EntryHelpOption = "NoRightsToMapItem";
		ElsIf AllowedLinks[0].Priority > SearchRule Then
			Dimensiondb = Undefined;
			AnalyticsSearchResult.Value = Dimensiondb;
			AnalyticsSearchResult.EntryHelpOption = "NoRightsToMapItem";
		Else
			Dimensiondb = AllowedLinks[0].Ref;
			AnalyticsSearchResult.Value = Dimensiondb;
			AnalyticsSearchResult.EntryHelpOption = "";
		EndIf;
	Else
		Dimensiondb = Undefined;
		AnalyticsSearchResult.Value = Dimensiondb;
		AnalyticsSearchResult.EntryHelpOption = "ValueNotFound";
	EndIf;
	
	Return AnalyticsSearchResult;

EndFunction

&AtClient
Procedure DisplayControlPageReplaceValues()
	
	TypesOfAnalystCurData = Items.DimensionKinds.CurrentData;
	
	If  DisplayAllDimensions Then
		Items.DimensionKinds.RowFilter = Undefined;
		Items.ReplaceDimensionValues.RowFilter = New FixedStructure("Type",
			?(Not TypesOfAnalystCurData = Undefined,TypesOfAnalystCurData.Type,Undefined));
	Else
		Items.DimensionKinds.RowFilter = New FixedStructure("RequiresAttention",True);
		Items.ReplaceDimensionValues.RowFilter = New FixedStructure("RequiresAttention,Type",
			True, ?(Not TypesOfAnalystCurData = Undefined,TypesOfAnalystCurData.Type,Undefined));
	EndIf;
	
EndProcedure

&AtServer
Function GetUsedTypesOfBudgetStages(Model)
	
	SetPrivilegedMode(True);
	
	TypesOfBudgetStagesUsed = New Array();
	
	Query = New Query;
	Query.Text = "SELECT
	|	BudgetProfiles.Ref
	|INTO BudgetProfiles
	|FROM
	|	Catalog.BudgetProfiles AS BudgetProfiles
	|WHERE
	|	BudgetProfiles.Owner = &Model
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetingSteps.Ref
	|INTO StagesOfBudgets
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Owner = &Model
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BudgetEntryForm.BudgetProfile AS Ref
	|FROM
	|	Document.BudgetEntryForm AS BudgetEntryForm
	|WHERE
	|	BudgetEntryForm.BudgetProfile IN
	|			(SELECT
	|				A.Ref
	|			FROM
	|				BudgetProfiles AS A)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BudgetTask.BudgetingStep
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	BudgetTask.BudgetingStep IN
	|			(SELECT
	|				A.Ref
	|			FROM
	|				StagesOfBudgets AS A)
	|";
	
	Query.SetParameter("Model",Model);
	
	QueryResult = Query.Execute().Unload();
	
	If QueryResult.Count() > 0 Then
		TypesOfBudgetStagesUsed = QueryResult.UnloadColumn("Ref");
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return TypesOfBudgetStagesUsed;
	
EndFunction

&AtServer
Procedure FillInUploadedUINBasedOnXMLData()
	
	TempDataFileName = GetTempFileName("xml");
	BinaryData = GetFromTempStorage(StorageAddress);
	BinaryData.Write(TempDataFileName);

	DownloadableUIN.Clear();
	
	DownloadableUIN.Add(UINBudgetingModel);
	
	SelectedBudgetTypes = GetSelectedSelectionItems(BudgetProfiles,"WIN");
	For Each Page1 In SelectedBudgetTypes Do
		DownloadableUIN.Add(Page1);
	EndDo;
	
	SelectedStagesOfBudgetPreparation = GetSelectedSelectionItems(BudgetingSteps,"WIN");
	For Each Page1 In SelectedStagesOfBudgetPreparation Do
		DownloadableUIN.Add(Page1);
	EndDo;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(TempDataFileName); 
	DOMBuilder = New DOMBuilder;
	DOMDocument  = DOMBuilder.Read(XMLReader);
	
	Objects = DOMDocument.GetElementByTagName("itemFilterData");
	For Each Item In Objects Do
		
		WEEDIsOwner = Item.Attributes.GetNamedItem("OwnerRef").Value;
		UIDElement = Item.Attributes.GetNamedItem("Ref").Value;
		
		If DownloadableUIN.FindByValue(WEEDIsOwner) <> Undefined Then
			DownloadableUIN.Add(UIDElement);
		EndIf;
		
	EndDo;
	
	XMLReader.Close();
	DeleteFiles(TempDataFileName);
	
EndProcedure

&AtClient
Procedure FlagForUpdateModelWhenChanging()
	
	Tree = BudgetProfiles;
	For Each String In Tree.GetItems() Do
		String.Refresh = UpdateModel And ValueIsFilled(String.Ref);
		If UpdateModel And ValueIsFilled(String.Ref) Then
			If String.Used Then
				String.Refresh = False;
			Else
				String.Refresh = True;
			EndIf;
		EndIf;
		
		SetUpdateTypesOfBudgetMilestonesFlag(String);
	EndDo;
	Tree = BudgetingSteps;
	For Each String In Tree.GetItems() Do
		String.Refresh = UpdateModel And ValueIsFilled(String.Ref);
		If UpdateModel And ValueIsFilled(String.Ref) Then
			If String.Used Then
				String.Refresh = False;
			Else
				String.Refresh = True;
			EndIf;
		EndIf;
		
		SetUpdateTypesOfBudgetMilestonesFlag(String);
		
	EndDo;
	If Not ValueIsFilled(BudgetingModelLink) Then
		Items.ModelInformationGroup.Visible = False;
	EndIf;
	If Not UpdateModel Then
		Items.BudgetProfilesRefresh.Visible = False;
		Items.BudgetingStepsRefresh.Visible = False;
	Else
		Items.BudgetProfilesRefresh.Visible = True;
		Items.BudgetingStepsRefresh.Visible = True;
	EndIf;
	ItIsForbiddenToChangeStagesOfBudgets = UpdateModel And ItIsForbiddenToChangeStagesOfBudgets(BudgetingModelLink);
	
	If ItIsForbiddenToChangeStagesOfBudgets Then
		Items.BudgetingSteps.ReadOnly = True;
		Items.BudgetingStepsCheckAll.Enabled = False;
		Items.BudgetingStepsUncheckAll.Enabled = False;
	Else
		Items.BudgetingSteps.ReadOnly = False;
		Items.BudgetingStepsCheckAll.Enabled = True;
		Items.BudgetingStepsUncheckAll.Enabled = True;
	EndIf;
EndProcedure

&AtServer
Function ItIsForbiddenToChangeStagesOfBudgets(Model)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	BudgetTask.Ref
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	BudgetTask.BudgetingModel = &BudgetingModel";
	
	Query.SetParameter("BudgetingModel",Model);
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	
	Return Selection.Count() > 0;
	
EndFunction
&AtServer
Function AdditionalTypesOfModelCompositionReferencesToReplace()
	
	Array = New Array;
	Array.Add(New TypeDescription("CatalogRef.FinancialReportItems"));
	
	Return Array;
		
EndFunction

&AtClient
Procedure SetUpdateTypesOfBudgetMilestonesFlag(CurRow)
	
	If Not UpdateModel Then
		CurRow.Refresh = False;
	EndIf;
	
	SubordinateItems = CurRow.GetItems();
	
	If SubordinateItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In SubordinateItems Do
		
		String.Refresh = CurRow.Refresh;
		If CurRow.Refresh And ValueIsFilled(String.Ref) Then
			If String.Used Then
				String.Refresh = False;
			Else
				String.Refresh = True;
			EndIf;
		EndIf;
		
		SetUpdateTypesOfBudgetMilestonesFlag(String);
		
	EndDo;
	
EndProcedure

&AtClient
Function AvailableAction(CurrentRow)
	
	ListOfActions = New ValueList;
	ListOfActions.Add(False,NStr("vi = 'kết nhập mới';
								|ru = 'загрузить новый';
								|en = 'import a new one'; fa = 'import a new one';
								|it = 'загрузить новый';
								|pl = 'import a new one';
								|tr = 'yenisini indir'"));
	
	ForbiddingUpdates = False;
	Parent = CurrentRow.GetParent();
	If Parent <> Undefined Then
		If Not Parent.Refresh Then
			ForbiddingUpdates = True;
		EndIf;
	EndIf;
	
	If Not ForbiddingUpdates And ValueIsFilled(CurrentRow.Ref) And Not CurrentRow.Used Then
		ListOfActions.Add(True,NStr("vi = 'cập nhật sẵn có';
									|ru = 'обновить существующий';
									|en = 'update the existing one'; fa = 'update the existing one';
									|it = 'обновить существующий';
									|pl = 'update the existing one';
									|tr = 'mevcut değerleri güncelle'"));
	EndIf;
	
	Return ListOfActions;
	
EndFunction

#EndRegion

#EndRegion
