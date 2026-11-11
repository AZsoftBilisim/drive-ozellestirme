
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
		
	If Parameters.Property("BudgetingModel") Then
		Object.BudgetingModel = Parameters.BudgetingModel;
	EndIf;
	
	If Parameters.Property("GenerateOnOpen") And Parameters.GenerateOnOpen <> Undefined 
		And Parameters.GenerateOnOpen Then	
		GenerateOnOpen = True;
	EndIf;

	Object.BudgetingModel = Catalogs.BudgetingModels.DefaultBudgetingModel();
	
	Groups = "Variant1";
	
	CurrentDate = CurrentSessionDate(); 
	BeginOfPeriod = CurrentDate;
	EndOfPeriod = CurrentDate;
	
	RestoreCurSettingKey();
	If Not CurrentSettingKey = Undefined Then
		RestoreSetting(CurrentSettingKey);
	EndIf;
		
	FormControl();
			
	Result.ShowLegend = False;
	Result.ShowTitle = False;
	
	Result.PlotArea.Right = 1;
	
	FillInSavedSettingsSelectionCommands();
		
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Object.BudgetingModel) Then
		Settings.Delete("Object.BudgetingModel");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
		
	If ValueIsFilled(Object.BudgetingModel) And GenerateOnOpen Then
		AttachIdleHandler("Generate", 0.1, True);
	Else
		SetStateReportNotGenerated();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PeriodStartChoiceCompletion", ThisObject);
	
	TMCommonUseClient.SelectPeriodFromList(
				ThisForm,
				Item,
				PeriodType,
				BeginOfPeriod,
				CallbackDescription);
									
EndProcedure
					
&AtClient
Procedure PeriodTypeOnChange(Item)
	
	EnterPeriodValue(PeriodType);
	
	SetStateReportNotGenerated();
	
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	If TypeOf(Decryptions) = Type("String") Then
		ShowMessageBox(, Decryptions);
		StandardProcessing = False;
		Return;
	EndIf;
	
	StandardProcessing = TypeOf(Decryptions) <> Type("Array");
	If Not StandardProcessing Then
		ResultingList = New ValueList;
		For Each Details In Decryptions Do
			If TypeOf(Details) = Type("ValueList") Then
				For Each Item In Details Do
					FillPropertyValues(ResultingList.Add(), Item);
				EndDo;
			EndIf;
		EndDo;
		If ResultingList.Count() = 1 Then
			ShowValue(Undefined, ResultingList[0].Value);
		ElsIf ResultingList.Count() Then
			CallbackDescription = New CallbackDescription("ResultDetailProcessingCompletion", ThisObject);
			ResultingList.ShowChooseItem(
				CallbackDescription,
				NStr("vi = 'Chi tiết bước xử lý';
					|ru = 'Сведения о шаге процесса';
					|en = 'Process step details'; fa = 'Process step details';
					|it = 'Informazioni sul passo del processo';
					|pl = 'Informacja o kroku procesu';
					|tr = 'Süreç adımı bilgileri'"));
		Else
			ShowMessageBox(,NStr("vi = 'Không có dữ liệu để diễn giải!';
								|ru = 'Нет данных для расшифровки!';
								|en = 'No data to drill down.'; fa = 'No data to drill down.';
								|it = 'Nessun dato per la trascrizione!';
								|pl = 'Brak danych do rozszyfrowania!';
								|tr = 'Çözümleme için veri yok!'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultDetailProcessingCompletion(SelectedElement, AdditionalParameters) Export
    
    ValueSelected = SelectedElement;
    If ValueSelected <> Undefined Then
        ShowValue(Undefined, ValueSelected.Value);
    EndIf;

EndProcedure

&AtClient
Procedure CurrentOutstandingTasksClick(Item)
	
	FixedSettings = New DataCompositionSettings;
	
	FilterElement = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("BudgetingModel");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Object.BudgetingModel;
	FilterElement.Use = True;
	
	Couples = New Structure;
	Couples.Insert("VariantKey", "CurTasksDecryption");
	Couples.Insert("GenerateOnOpen", True);
	Couples.Insert("FixedSettings", FixedSettings);
	Couples.Insert("ReportOptionsCommandsVisibility", False);
	OpenForm("Report.PerformanceOfBudgetProcessTasks.Form", Couples);
	
EndProcedure

&AtClient
Procedure ReportTypeOnChange(Item)
	
	FormControl();	
	SetStateReportNotGenerated();
	
EndProcedure

&AtClient
Procedure ShowProcessExecutionPlanOnChange(Item)
	
	SetStateReportNotGenerated();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Commands

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)
	
	Generate();	
	
EndProcedure

&AtClient
Procedure Generate()
	
	Var Errors;
	
	ClearMessages();
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.BudgetingModel) Then
	
		CommonClientServer.AddUserError(Errors,
			"BudgetingModel",
			NStr("vi = 'Mô hình ngân sách không được chỉ định';
				|ru = 'Не указана модель бюджетирования';
				|en = 'Budgeting model is not specified'; fa = 'Budgeting model is not specified';
				|it = 'Non è stato indicato il modello di budgeting';
				|pl = 'Nie podano modelu budżetowania';
				|tr = 'Bütçeleme modeli belirtilmedi'"), "");

		Cancel = True;
			
	EndIf;
		
	If Not ValueIsFilled(EndOfPeriod) Then
			
		CommonClientServer.AddUserError(Errors,
			"PeriodType",
			NStr("vi = 'Ngày kết thúc báo cáo không được chỉ định';
				|ru = 'Не указана дата окончания отчета';
				|en = 'Report end date is not specified'; fa = 'Report end date is not specified';
				|it = 'Non è indicata la data di fine del report';
				|pl = 'Brak daty zakończenia raportu';
				|tr = 'Rapor bitiş tarihi belirtilmedi'"), "");
			
		Cancel = True;
		
	EndIf;
	
	If Not ValueIsFilled(Groups) Then
			
		CommonClientServer.AddUserError(Errors,
			"Groups",
			NStr("vi = 'Nhóm báo cáo không được chỉ định';
				|ru = 'Не указаны группировки отчета';
				|en = 'Report groupings are not specified'; fa = 'Report groupings are not specified';
				|it = 'Non sono indicati i raggruppamenti del report';
				|pl = 'Nie wymienione grupowania raportu';
				|tr = 'Rapor gruplaması belirtilmedi'"), "");
			
		Cancel = True;
		
	EndIf;
	
	If Not Cancel Then
		FormInBackground();
	Else
		CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	EndIf;

EndProcedure

&AtClient
Procedure SettingsPanel(Command)
		
	ParametersList = New Structure();
	ParametersList.Insert("BudgetingModel", Object.BudgetingModel);
	ParametersList.Insert("Groups", Groups); 
	ParametersList.Insert("ResponsiblePersonValue", ResponsiblePersonValue); 
	ParametersList.Insert("EmployeeResponsibleFlag", EmployeeResponsibleFlag);
	ParametersList.Insert("PeriodType", PeriodType);
	ParametersList.Insert("Period", Period);
	ParametersList.Insert("ReportType", ReportType);
	ParametersList.Insert("ShowProcessExecutionPlan", ShowProcessExecutionPlan);
	ParametersList.Insert("BeginOfPeriod", BeginOfPeriod);
	ParametersList.Insert("EndOfPeriod", EndOfPeriod);
		
	Notification = New CallbackDescription("OpenSettingsPanelEnd", ThisObject);

	OpenForm("Report.BudgetingProcessmonitor.Form.SettingsForm", ParametersList, ThisForm,,,, Notification);
	
EndProcedure

&AtClient
Procedure ShouldSaveSettings(Command)
	
	Settings = New Structure("ReportType, BudgetingModel, Groups, 
			|ResponsiblePersonValue, EmployeeResponsibleFlag, 
			|ShowProcessExecutionPlan");
	FillPropertyValues(Settings, ThisForm);
	Settings.BudgetingModel = Object.BudgetingModel;
	
	ParametersList = New Structure("ObjectKey,CurrentSettingKey,Settings"
			,"Report.BudgetingProcessmonitor",CurrentSettingKey,Settings);
	Notification = New CallbackDescription("OpenSavingReportSettingsEnd", ThisObject);
	OpenForm("Report.BudgetingProcessmonitor.Form.SaveReportSettings", ParametersList, ThisForm,,,, Notification);
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// PlugIns


// Plug-in method. Command to load report settings.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_DownloadReportSetup(Command)
	
	FoundItems = AddedSettings.FindRows(New Structure("CommandName", Command.Name));
	If FoundItems.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không tìm thấy phương án báo cáo.';
								|ru = 'Вариант отчета не найден.';
								|en = 'Report option was not found.'; fa = 'Report option was not found.';
								|it = 'Variante del report non trovata.';
								|pl = 'Nie znaleziono wariantu raportu.';
								|tr = 'Rapor seçeneği bulunmadı.'"));
		Return;
	EndIf;
	FormSettingsItem = FoundItems[0];
	RestoreSetting(FormSettingsItem.SettingsKey);
	CurrentSettingKey = FormSettingsItem.SettingsKey;
	FormControl();
	FillInSavedSettingsSelectionCommands();
	If GenerateOnOpen Then
		AttachIdleHandler("Generate", 0.1, True);
	Else
		Items.Pages.CurrentPage = Items.PageState;
		StatePresentation = Items.State.StatePresentation;
		StatePresentation.Visible = True;
		StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
		StatePresentation.Picture  = PictureLib.Information32;
		StatePresentation.Text     = NStr("vi = 'Đã chọn phương án báo cáo khác. Hãy nhấn ""Lập báo cáo"" để nhận báo cáo.';
											|ru = 'Выбран другой вариант отчета. Нажмите ""Сформировать"" для получения отчета.';
											|en = 'Another report option is selected. To generate report, click ""Generate"".'; fa = 'Another report option is selected. To generate report, click ""Generate"".';
											|it = 'È stata selezionata una variante del report diversa. Fai clic su ""Genera"" per generare un report.';
											|pl = 'Wybrano inną opcję raportu. Kliknij ""Generuj"", aby wygenerować raport.';
											|tr = 'Başka bir rapor seçeneği seçildi. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'");

	EndIf;
	
	SaveCurSettingKey();
	
EndProcedure

#EndRegion


////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

#Region Private

&AtServer
Procedure FormControl()
	
	Model = Object.BudgetingModel;
	
	If Groups = "Variant1" 
		And ValueIsFilled(Model) Then
		
		PeriodicityOfModel = Common.ObjectAttributeValue(Model, "Periodicity");
		If ValueIsFilled(PeriodicityOfModel) Then
			PeriodicityName = Common.EnumerationValueName(PeriodicityOfModel);
			NewKindOfPeriod  = Enums.AvailableReportPeriods[PeriodicityName];
		Else
			NewKindOfPeriod  = Enums.AvailableReportPeriods.EmptyRef();
		EndIf;
		If PeriodType <> NewKindOfPeriod Then
			PeriodType = NewKindOfPeriod;
			EnterPeriodValue(PeriodType);
		EndIf;
	EndIf;
	
	Items.PeriodType.Enabled = Groups <> "Variant1";
	Items.ShowProcessExecutionPlan.Visible = ReportType > 0;
	
	// Heading.
	Title = Metadata.Reports.BudgetingProcessmonitor.Synonym;
	If ValueIsFilled(CurrentSettingKey) Then
		Title = Title + " (" + CurrentSettingKey + ")";;
	EndIf;
		
EndProcedure

&AtClient
Procedure FormInBackground()
	
	Items.Pages.CurrentPage = Items.PageState;
	StatePresentation = Items.State.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	StatePresentation.Picture = PictureLib.TimeConsumingOperation48;
	StatePresentation.Text = NStr("vi = 'Đang lập báo cáo...';
									|ru = 'Отчет формируется...';
									|en = 'Generating report...'; fa = 'در حال تولید گزارش...';
									|it = 'Il report è in fase di generazione...';
									|pl = 'Raport tworzenie...';
									|tr = 'Rapor oluşturuluyor...'");

	
	TimeConsumingOperation = FillInChartInBackground();
	
	If TimeConsumingOperation <> Undefined Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.Interval = 0; 
		CallbackOnCompletion = New CallbackDescription("FillInChartInBackgroundCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	Else
		Result = Undefined;
		SetStateReportNotGenerated();
	EndIf;

	Items.CurrentOutstandingTasks.Title = NStr("vi = 'Nhận dữ liệu...';
												|ru = 'Получение данных...';
												|en = 'Getting data...'; fa = 'Getting data...';
												|it = 'Acquisizione dati...';
												|pl = 'Pobieranie danych...';
												|tr = 'Veri alımı...'");
	TimeConsumingOperation1 = GetInformationAboutIssuesInBackground();
	
	If TimeConsumingOperation1 <> Undefined Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.Interval = 0; 
		CallbackOnCompletion = New CallbackDescription("GetInformationAboutIssuesInBackgroundCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation1, CallbackOnCompletion, IdleParameters);
	EndIf;
   	
EndProcedure

&AtClient
Procedure FillInChartInBackgroundCompletion(BackgroundJobResult,AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	Items.Pages.CurrentPage = Items.ResultPage;

	If BackgroundJobResult = Undefined Then
		Result = Undefined;
		Return;
	ElsIf BackgroundJobResult.Status = "Error" Then
		Result = Undefined;
		Raise BackgroundJobResult.BriefErrorDescription;
	ElsIf BackgroundJobResult.Status = "Completed2" Then
		Result = GetFromTempStorage(BackgroundJobResult.ResultAddress);
		Result.ShowLegend = False;
		Result.ShowTitle = False;	
		Result.PlotArea.Right = 1;
	EndIf;

EndProcedure

&AtClient
Procedure GetInformationAboutIssuesInBackgroundCompletion(BackgroundJobResult,AdditionalParameters) Export
	
	TimeConsumingOperation1 = Undefined;

	If BackgroundJobResult = Undefined Then
		Items.CurrentOutstandingTasks.Title = NStr("vi = 'Lỗi nhận dữ liệu';
													|ru = 'Ошибка получения данных';
													|en = 'Data receiving error'; fa = 'Data receiving error';
													|it = 'Errore di acquisizione dati';
													|pl = 'Błąd podczas pobierania danych';
													|tr = 'Verileri alma hatası'");
		Return;
	ElsIf BackgroundJobResult.Status = "Error" Then
		Items.CurrentOutstandingTasks.Title = NStr("vi = 'Lỗi nhận dữ liệu';
													|ru = 'Ошибка получения данных';
													|en = 'Data receiving error'; fa = 'Data receiving error';
													|it = 'Errore di acquisizione dati';
													|pl = 'Błąd podczas pobierania danych';
													|tr = 'Verileri alma hatası'");
		Raise BackgroundJobResult.BriefErrorDescription;
	ElsIf BackgroundJobResult.Status = "Completed2" Then
		Items.CurrentOutstandingTasks.Title = GetFromTempStorage(BackgroundJobResult.ResultAddress);
	EndIf;

EndProcedure

&AtServer
Procedure EnterPeriodValue(PeriodType)
	
	BeginOfPeriod = TMCommonUseClientServer.BeginningOfReportPeriod(PeriodType, BeginOfPeriod);
	EndOfPeriod =  TMCommonUseClientServer.EndOfReportPeriod(PeriodType, BeginOfPeriod);
	
	PeriodsList = TMCommonUseClientServer.AvailablePeriodValuesByPeriodType(BeginOfPeriod, PeriodType);
	ListItem = PeriodsList.FindByValue(BeginOfPeriod);
	
	If ListItem = Undefined Then
		Period = "";
	Else
		Period = ListItem.Presentation;
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export

	If SelectedPeriod <> Undefined Then
		
		Period = SelectedPeriod.Presentation;
		
		BeginOfPeriod = SelectedPeriod.Value;
		EndOfPeriod = TMCommonUseClientServer.EndOfReportPeriod(PeriodType, SelectedPeriod.Value);		
		
	EndIf; 
	
	SetStateReportNotGenerated();
	
EndProcedure

&AtClient
Procedure OpenSettingsPanelEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
    	Return;
	EndIf;
	
	SettingsChanged_1 = False;
	If TypeOf(Result) = Type("Structure") Then
		For Each KeyValue In Result Do
			If KeyValue.Key = "BudgetingModel" Then				
				If Object.BudgetingModel <> KeyValue.Value Then
					SettingsChanged_1 = True;
				EndIf;
				Object.BudgetingModel  = KeyValue.Value;
				Continue;	
			ElsIf KeyValue.Key = "Generate" Then 
				Continue;
			EndIf;
			If ThisForm[KeyValue.Key] <> KeyValue.Value Then
				SettingsChanged_1 = True;
			EndIf;
			ThisForm[KeyValue.Key] = KeyValue.Value;	  	
      	EndDo;
  	EndIf;
  
  	FormControl();
	
	If SettingsChanged_1 Then
		SetStateReportNotGenerated();
	EndIf;
	
	If Result.Property("Generate") And Result.Generate Then
		AttachIdleHandler("Generate", 0.1, True);	
	EndIf;

EndProcedure

&AtServer
Function FillInChartInBackground()
		
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	AddlParameters = New Structure();
	AddlParameters.Insert("ExecutionPlan", 		ShowProcessExecutionPlan);
	AddlParameters.Insert("FlagPerformer", 		EmployeeResponsibleFlag);
	AddlParameters.Insert("ArtistValue", 	ResponsiblePersonValue);

	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("BudgetingModel", Object.BudgetingModel);
	ProcessingParameters.Insert("Result", Result);
	ProcessingParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	ProcessingParameters.Insert("EndOfPeriod", EndOfPeriod);
	ProcessingParameters.Insert("ReportType", ReportType);
	ProcessingParameters.Insert("Groups", Groups);
	ProcessingParameters.Insert("AddlParameters", AddlParameters);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0; // launch immediately
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Màn hình quy trình ngân sách, điền biểu đồ';
														|ru = 'Монитор бюджетных процессов, заполнение диаграммы';
														|en = 'Budgeting process schedule, filling chart'; fa = 'Budgeting process schedule, filling chart';
														|it = 'Pannello di controllo dei processi di budget, compilazione del diagramma';
														|pl = 'Monitor procesów budżetowych, wypełnienie diagramu';
														|tr = 'Bütçeleme süreci programı, doldurulan grafikler'");
		
	BackgroundJobResult = TimeConsumingOperations.ExecuteInBackground("Reports.BudgetingProcessmonitor.FillDiagram",
		ProcessingParameters, ExecutionParameters);
		

	Return BackgroundJobResult;
	
EndFunction

&AtServer
Function GetInformationAboutIssuesInBackground()
		
	If TimeConsumingOperation1 <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation1.JobID);
	EndIf;
	

	ProcessingParameters = New Structure;
	ProcessingParameters.Insert("BudgetingModel", Object.BudgetingModel);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0; // launch immediately
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Giám sát các quy trình ngân sách, thu thập thông tin về các nhiệm vụ';
														|ru = 'Монитор бюджетных процессов, получение сведений о задачах';
														|en = 'Budgeting process schedule, receiving task information'; fa = 'Budgeting process schedule, receiving task information';
														|it = 'Pannello di controllo dei processi di budget, acquisizione delle informazioni sugli obiettivi';
														|pl = 'Monitor procesów budżetowych, uzyskiwanie informacji o zadaniach';
														|tr = 'Bütçeleme süreci programı,görev hakkında bilgi kaydetme'");
		
	BackgroundJobResult = TimeConsumingOperations.ExecuteInBackground("Reports.BudgetingProcessmonitor.GetInformationAboutIssues",
		ProcessingParameters, ExecutionParameters);

	Return BackgroundJobResult;
	
EndFunction

&AtClient
Procedure OpenSavingReportSettingsEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Or TypeOf(Result) <> Type("String") Then 
		Return
	EndIf;
	CurrentSettingKey = Result;
	FillInSavedSettingsSelectionCommands();
	
EndProcedure

&AtServer
Procedure SaveCurSettingKey()

	SettingName = "CurrentSettingKey";

	Common.CommonSettingsStorageSave("Report.BudgetingProcessmonitor", SettingName, CurrentSettingKey); 

EndProcedure

&AtServer
Procedure RestoreCurSettingKey()

	SettingName = "CurrentSettingKey";
	CurrentSettingKey = Common.CommonSettingsStorageLoad(
		"Report.BudgetingProcessmonitor", SettingName);

EndProcedure

&AtServer
Procedure RestoreSetting(SettingsKey)

	SettingsValue = Common.SystemSettingsStorageLoad(
		"Report.BudgetingProcessmonitor", SettingsKey);

	If TypeOf(SettingsValue) = Type("Structure") Then

		FillPropertyValues(ThisForm, SettingsValue);
		If SettingsValue.Property("BudgetingModel") Then
			Object.BudgetingModel = SettingsValue.BudgetingModel;
		EndIf;

	EndIf;

EndProcedure

&AtServer
Procedure FillInSavedSettingsSelectionCommands()
	
	FormSettings = FormAttributeToValue("AddedSettings");
	FormSettings.Columns.Add("Found", New TypeDescription("Boolean"));
	
	SettingsList = SystemSettingsStorage.GetList("Report.BudgetingProcessmonitor");
	SettingsList.SortByValue(SortDirection.Asc);
	
	Var_Group = Items.ReportOptions;
	LastIndex = FormSettings.Count() - 1;
	For Each Page1 In SettingsList Do
		
		FoundItems = FormSettings.FindRows(New Structure("SettingsKey, Found", Page1.Value, False));
		If FoundItems.Count() = 1 Then
			FormSettingsItem = FoundItems[0];
			FormSettingsItem.Found = True;
			Button = Items.Find(FormSettingsItem.CommandName);
			Button.Visible = True;
			Button.Title = Page1.Value;
			Items.Move(Button, Var_Group);
		Else
			LastIndex = LastIndex + 1;
			FormSettingsItem = FormSettings.Add();
			FormSettingsItem.SettingsKey = Page1.Value;
			FormSettingsItem.Found = True;
			FormSettingsItem.CommandName = "SelectSetting_" + Format(LastIndex, "NZ=0; NG=");
			
			Command = Commands.Add(FormSettingsItem.CommandName);
			Command.Action = "Attachable_DownloadReportSetup";
			
			Button = Items.Add(FormSettingsItem.CommandName, Type("FormButton"), Var_Group);
			Button.Type = FormButtonType.CommandBarButton;
			Button.CommandName = FormSettingsItem.CommandName;
			Button.Title = Page1.Value;
			
			ConstantCommands.Add(FormSettingsItem.CommandName);
		EndIf;
		Button.Check = (CurrentSettingKey = Page1.Value);
	EndDo;
	
	FoundItems = FormSettings.FindRows(New Structure("Found", False));
	For Each FormSettingsItem In FoundItems Do
		Button = Items.Find(FormSettingsItem.CommandName);
		Button.Visible = False;
	EndDo;
	
	FormSettings.Columns.Delete("Found");
	ValueToFormAttribute(FormSettings, "AddedSettings");
	
EndProcedure

&AtClient
Procedure SetStateReportNotGenerated()
	
	Items.Pages.CurrentPage = Items.PageState;
	StatePresentation = Items.State.StatePresentation;
	StatePresentation.Visible = True;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	StatePresentation.Picture  = PictureLib.Information32;
	StatePresentation.Text = NStr("vi = 'Chưa lập báo cáo. Hãy nhấn nút ""Lập báo cáo"" để nhận báo cáo.';
									|ru = 'Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.';
									|en = 'Report is not generated. To generate the report, click ""Generate"".'; fa = 'Report is not generated. To generate the report, click ""Generate"".';
									|it = 'Il report non è stato creato. Fate clic su ""Crea"" per ricevere il rapporto.';
									|pl = 'Raport nie został wygenerowany. Kliknij ""Utwórz"", aby wygenerować raport.';
									|tr = 'Rapor oluşturulmadı. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'");
	
EndProcedure

#EndRegion
