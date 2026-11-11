#Region Variables

&AtClient
Var IdleHandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.BudgetingModel) Or Not ValueIsFilled(Parameters.BudgetProfile) Then
		Raise NStr("vi = 'Chỉ có thể mở báo cáo từ 
								| - biểu mẫu danh mục ""Dạng ngân sách"" 
								| - chỗ làm việc ""Báo cáo ngân sách""';
								|ru = 'Открытие отчета возможно только из 
								| - формы справочника ""Вид бюджета"" 
								| - рабочего места ""Бюджетные отчеты""';
								|en = 'The report can be opened only from 
								|- the ""Budget profile"" catalog form
								|- the ""Budget reports"" workplace'; fa = 'The report can be opened only from 
								|- the ""Budget profile"" catalog form
								|- the ""Budget reports"" workplace';
								|it = 'È possibile aprire il report solo tramite 
								| - il modulo del catalogo ""Tipologia di budget"" 
								| - la postazione di lavoro - ""Report di budget""';
								|pl = 'Otwieranie raportu możliwe jest tylko z 
								| - formularza katalogu ""Rodzaj budżetu"" 
								| - miejsca pracy ""Raporty budżetowe""';
								|tr = 'Raporun açılması sadece 
								| kaynağından mümkündür. Katalog formu ""Bütçe profili"" 
								| Çalışma alanı ""Bütçe raporu""'");
	EndIf;
	
	BudgetingModel = Parameters.BudgetingModel;
	BudgetProfile = Parameters.BudgetProfile;
	
	If Parameters.Property("CurDatePeriod")
	And Parameters.Property("Periodicity") Then
		ReportPeriod = CurrentSessionDate();
		BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(ReportPeriod, Parameters.Periodicity);
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(ReportPeriod, Parameters.Periodicity);
	EndIf;
	
	If Parameters.Property("Period") Then
		PeriodParameters = Parameters.Period; // StandardPeriod - 
		BeginOfPeriod = PeriodParameters.StartDate;
		EndOfPeriod = PeriodParameters.EndDate;
	EndIf;
	
	If Parameters.Property("GenerateBudgetReportWhenOpening") Then
		GenerateReport = Parameters.GenerateBudgetReportWhenOpening;
		
		DataStillUpdating = BudgetingServer.DataForBudgetReportIsStillUpdated();
		If DataStillUpdating Then
			GenerateReport = False;
			Common.MessageToUser(ReportsOptions.DataIsBeingUpdatedMessage());
		EndIf;
	EndIf;
	
	If Parameters.Property("Scenario") Then
		Scenario = Parameters.Scenario;
	EndIf;
	
	If Parameters.Property("Organization") Then
		Organization = Parameters.Organization;
		If Organization.Count() > 0 Then
			ToUseASelectionOrganization = True;
		EndIf;
	EndIf;
	
	If Parameters.Property("Department") Then
		Department = Parameters.Department;
		If Department.Count() > 0 Then
			UseSelectionByDivision = True;
		EndIf;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetProfilesHeaderDimensions.LineNumber AS LineNumber,
		|	BudgetProfilesHeaderDimensions.DimensionKind,
		|	BudgetProfilesHeaderDimensions.DimensionKind.ValueType AS ValueType,
		|	BudgetProfilesHeaderDimensions.DimensionKind.Description AS Description
		|FROM
		|	Catalog.BudgetProfiles.HeaderDimensions AS BudgetProfilesHeaderDimensions
		|WHERE
		|	BudgetProfilesHeaderDimensions.Ref = &BudgetProfile";
		
	Query.SetParameter("BudgetProfile", BudgetProfile);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	BooleanType = New TypeDescription("Boolean");
	TypeList = New TypeDescription("ValueList");
	AttributesArray = New Array;
	
	HeaderDimensionList.Clear();
	
	While Selection.Next() Do
		
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Selection.DimensionKind);
		Attribute = New FormAttribute(FieldName, TypeList, , Selection.Description);
		AttributesArray.Add(Attribute);
		
		Attribute = New FormAttribute("UseSelectionBy" + FieldName, BooleanType, , Selection.Description);
		AttributesArray.Add(Attribute);
		
		HeaderDimensionList.Add(Selection.DimensionKind);
		
	EndDo;
	
	ChangeAttributes(AttributesArray);
	
	Selection.Reset();
	While Selection.Next() Do
		
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Selection.DimensionKind);
		
		ThisObject[FieldName].ValueType = Selection.ValueType;
		
		Var_Group = Items.Add("Group" + FieldName, Type("FormGroup"), Items.Filterdata_);
		Var_Group.Type = FormGroupType.UsualGroup;
		Var_Group.Group = ChildFormItemsGroup.Horizontal;
		Var_Group.Representation = UsualGroupRepresentation.None;
		Var_Group.ShowTitle = False;
		
		Item = Items.Add("UseSelectionBy" + FieldName, Type("FormField"), Var_Group);
		Item.Type = FormFieldType.CheckBoxField;
		Item.DataPath = "UseSelectionBy" + FieldName;
		Item.TitleLocation = FormItemTitleLocation.Right;
		
		Item = Items.Add(FieldName, Type("FormField"), Var_Group);
		Item.Type = FormFieldType.InputField;
		Item.DataPath = FieldName;
		Item.TitleLocation = FormItemTitleLocation.None;
		Item.SetAction("OnChange", "Attachable_ListOfSelectionsWhenChanging");
		
	EndDo;
	
	If Parameters.Property("DataForConfirmation") Then
		DataForConfirmation = Parameters.DataForConfirmation;
	EndIf;
	If Parameters.Property("DataUnderDevelopment") Then
		DataUnderDevelopment = Parameters.DataUnderDevelopment;
	EndIf;
	
	ShowSetupBar = True;
	If Parameters.Property("ShowSetupBar") Then
		ShowSetupBar = Parameters.ShowSetupBar;
	EndIf;
	
	If Not ValueIsFilled(ReportCurrency) Then
		ReportCurrency = Constants.ManagementAccountingCurrency.Get();
	EndIf;
	
	MultiplierOfAmounts = Enums.NumberPresentationKinds.Unchanged;
	
	UpdateDate = EndOfDay(CurrentSessionDate());
	CurrentDateDate = UpdateDate;
	DateOfRelevanceComparison = UpdateDate;
	
	ChoiceParameters = Reports.BudgetReport.SelectionAvailabilityParameters(BudgetProfile);
	YouCanSelectCompany = ChoiceParameters.YouCanSelectCompany;
	YouCanSelectADepartment = ChoiceParameters.YouCanSelectADepartment;
	YouCanSelectScenario = ChoiceParameters.YouCanSelectScenario;
	
	CurrentSessionDate = CurrentSessionDate();
	BeginOfPeriod = CurrentSessionDate;
	EndOfPeriod = CurrentSessionDate;
	
	AlignPeriods();
	
	FormControl();
	EditMeasurementFilterValues();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTitleText(ThisObject);
	If GenerateReport Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");
		AttachIdleHandler("FormDirectly", 0.1, True);
	EndIf;
	
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);
	CalculateIndicators(MainIndicator);
EndProcedure

&AtClient
Procedure OnReopen()
	
	FormDirectly();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit = True Then
    	Return;	
	EndIf;

	CancelJobExecution();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	BudgetKindSettings = Common.CommonSettingsStorageLoad("BudgetReport_" + XMLString(BudgetProfile),
		"Settings");
	If TypeOf(BudgetKindSettings) = Type("Map") Then
		Settings.Clear();
		For Each KeyAndValue In BudgetKindSettings Do
			Settings.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndIf;
	
	If Parameters.NotUseSavedSettings Then
		Settings.Clear();
	EndIf;
	
	If Not GetFormFunctionalOption("GenerateBudgetsByCompanies") Then
		Settings.Delete("ToUseASelectionOrganization");
		Settings.Delete("Organization");
	EndIf;
	
	If Not GetFormFunctionalOption("GenerateBudgetsByBusinessUnits") Then
		Settings.Delete("UseSelectionByDivision");
		Settings.Delete("Department");
	EndIf;
	
	PrintSettings = Common.CommonSettingsStorageLoad("BudgetReport_" + XMLString(BudgetProfile), "PrintSettings");
	If TypeOf(PrintSettings) <> Type("Structure") Then
		PrintSettings = New Structure(SpreadsheetDocumentPropertiesToCopy());
		FillPropertyValues(PrintSettings, Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	If Parameters.NotUseSavedSettings Then
		Settings.Clear();
	EndIf;
	
	Common.CommonSettingsStorageSave("BudgetReport_" + XMLString(BudgetProfile), "Settings", Settings);
	
	If TypeOf(PrintSettings) = Type("Structure") Then
		FillPropertyValues(PrintSettings, Result);
	EndIf;
	Common.CommonSettingsStorageSave("BudgetReport_" + XMLString(BudgetProfile), "PrintSettings", PrintSettings);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetVisibilityOfSettingsPanel(ThisObject);
	EditMeasurementFilterValues();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	If Not YouCanSelectScenario Then
		AttributesNotToCheck.Add("Scenario");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	// Let's check the correctness of the structure settings
	If Not Catalogs.BudgetProfiles.BudgetViewIsFilledInCorrectly(BudgetProfile) Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ListOfSelectionsWhenChanging(Item)
	
	If Item.Name = "Organization" Then
		ToUseASelectionOrganization = Organization.Count();
	ElsIf Item.Name = "Department" Then
		UseSelectionByDivision = Department.Count();
	ElsIf Item.Name = "Currency" Then
		UseFilterByCurrency = Currency.Count();
	EndIf;
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportCurrencyOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure DateWhenTheDataIsUpToDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CurrentDateDate = UpdateDate;
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOfDataRelevanceDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Not BegOfDay(UpdateDate) = CurrentDateDate Then
		UpdateDate = EndOfDay(CurrentDateDate);
	EndIf;
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOfRelevanceComparisonOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
EndProcedure

&AtClient
Procedure BasedOnDataForApprovalOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure BasedOnDataInPreparationOnChange(Item)
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure ActualDataLimitClick(Item)
	
	FormParameters = New Structure("BudgetProfile, BeginOfPeriod, ActualDataLimit", BudgetProfile, BeginOfPeriod, ActualDataLimit);
	CallbackDescription = New CallbackDescription("SetFactBoundary", ThisObject);
	OpenForm("CommonForm.ConfigureActualDataLimit", FormParameters,,,,,
						CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CompareOnDifferentDatesOnChange(Item)
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	
	SetVisibilityOfBudgetComparisonDetails(ThisObject);
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EndOfPeriod = ?(BeginOfPeriod > EndOfPeriod, BeginOfPeriod, EndOfPeriod);
	AlignPeriods();
	
	UpdateTitleText(ThisObject);
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	BeginOfPeriod = ?(BeginOfPeriod > EndOfPeriod, EndOfPeriod, BeginOfPeriod);
	AlignPeriods();
	
	UpdateTitleText(ThisObject);
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultSelection(Item, Area, StandardProcessing)

	If Area.Text = NStr("vi = 'Hiển thị';
						|ru = 'Отразить';
						|en = 'Record'; fa = 'ثبت';
						|it = 'Отразить';
						|pl = 'Record';
						|tr = 'Отразить'") Then
		BudgetReportingServerCall.StartBackgroundTaskOfReflectionInBudgeting(BeginOfPeriod, EndOfPeriod);
		Area.Text = "";
	EndIf;

EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, IndexDecryption, StandardProcessing)

	StandardProcessing = False;
	
	Details = BudgetReportingServerCall.DetailsValue(IndexDecryption, DetailsDataAddress);
	If TypeOf(Details) = Type("Structure") Then
		If Details.Property("DataLineIndex") And
				Details.DataLineIndex <> Undefined Then
			
			OpeningParameters = ParametersForOpeningDecryptionReport(Details);
			BudgetReportingClient.OpenReportForm(OpeningParameters, ThisObject);
			
		ElsIf Details.Property("Value") And 
				Details.Value <> Undefined Then
			
			ShowValue(Undefined, Details.Value);
			
		Else
			
			WarningText = NStr("vi = 'Không có dữ liệu để giải mã';
								|ru = 'Нет данных для расшифровки';
								|en = 'No data to drill down'; fa = 'No data to drill down';
								|it = 'Non ci sono dati per la decodifica';
								|pl = 'Brak danych do odszyfrowania';
								|tr = 'Çözümleme için veri yok'");
			ShowMessageBox(, WarningText);
			
		EndIf;
	Else
		WarningText = NStr("vi = 'Không có dữ liệu để giải mã';
							|ru = 'Нет данных для расшифровки';
							|en = 'No data to drill down'; fa = 'No data to drill down';
							|it = 'Non ci sono dati per la decodifica';
							|pl = 'Brak danych do odszyfrowania';
							|tr = 'Çözümleme için veri yok'");
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultComparisonDetailProcessing(Item, IndexDecryption, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;
	
	Details = BudgetReportingServerCall.DetailsValue(IndexDecryption, AddressOfDecryptionDataComparison);
	If TypeOf(Details) = Type("Structure") Then
		If Details.Property("DataLineIndex")
			And Details.DataLineIndex <> Undefined Then
			
			OpeningParameters = ParametersForOpeningDecryptionReport(Details, True);
			BudgetReportingClient.OpenReportForm(OpeningParameters, ThisObject);
			
		ElsIf Details.Property("Value")
			And Details.Value <> Undefined Then
			
			ShowValue(Undefined, Details.Value);
			
		Else
			
			WarningText = NStr("vi = 'Không có dữ liệu để giải mã';
								|ru = 'Нет данных для расшифровки';
								|en = 'No data to drill down'; fa = 'No data to drill down';
								|it = 'Non ci sono dati per la decodifica';
								|pl = 'Brak danych do rozszyfrowania';
								|tr = 'Çözümleme için veri yok'");
			ShowMessageBox(, WarningText);
			
		EndIf;
	Else
		WarningText = NStr("vi = 'Không có dữ liệu để giải mã';
							|ru = 'Нет данных для расшифровки';
							|en = 'No data to drill down'; fa = 'No data to drill down';
							|it = 'Non ci sono dati per la decodifica';
							|pl = 'Brak danych do rozszyfrowania';
							|tr = 'Çözümleme için veri yok'");
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultBeforePrint(Item, PrintDialogueBox, Cancel)
	If TypeOf(PrintSettings) = Type("Structure") Then
		FillPropertyValues(PrintSettings, Result);
	EndIf;
EndProcedure

&AtClient
Procedure ResultOnActivate(Item)

	AttachIdleHandler("CalculateIndicatorsDynamically", 0.2, True);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectPeriod(Command)
	
	PeriodParameter_ = New StandardPeriod;
	PeriodParameter_.StartDate = BeginOfPeriod;
	PeriodParameter_.EndDate = EndOfPeriod;
	
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = PeriodParameter_;
	Dialog.Show(New CallbackDescription("SelectPeriodCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure GenerateReport(Command)
	
	Generate();
	
EndProcedure

&AtClient
Procedure SettingsPanel(Command)
	
	ShowSetupBar = Not ShowSetupBar;
	SetVisibilityOfSettingsPanel(ThisObject);
	
EndProcedure

&AtClient
Procedure SendEmail(Command)
	
	NameOfReportType = String(BudgetProfile);
	StatePresentation = Items.Result.StatePresentation;
	If StatePresentation.Visible = True
		And StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance Then
		
		QueryText = NStr("vi = 'Chưa lập báo cáo. Lập báo cáo?';
						|ru = 'Отчет не сформирован. Сформировать?';
						|en = 'Report not generated. Generate?'; fa = 'Report not generated. Generate?';
						|it = 'Report non generato. Generarlo?';
						|pl = 'Raport nie został wygenerowany. Chcesz utworzyć?';
						|tr = 'Rapor oluşturulmadı. Oluşturulsun mu?'");
		
		ShowQueryBox(
			New CallbackDescription("SendEmailCompletion",
			ThisObject,
			New Structure("NameOfReportType", NameOfReportType)),
			QueryText, 
			QuestionDialogMode.YesNo,
			60, 
			DialogReturnCode.Yes);
			
		Return;
	EndIf;
	
	ShowSendEmailDialog(NameOfReportType);
EndProcedure

&AtClient
Procedure SendEmailCompletion(QuestionResult, AdditionalParameters) Export
	NameOfReportType = AdditionalParameters.NameOfReportType;
	
	Response = QuestionResult;
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	FormDirectly();
	
	ShowSendEmailDialog(NameOfReportType);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers of indicator calculation commands.

&AtClient
Procedure SelectIndicatorClick(Item)

	Menu = MenuOfIndicatorTypes(Items.IndicatorsKindsCommands);
	ShowChooseFromMenu(New CallbackDescription("AfterSelectingTheIndicator", ThisObject), Menu, Item);

EndProcedure

&AtClient
Procedure CalculateAmount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateCount(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAverage(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMin(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateMax(Command)
	CalculateIndicators(Command.Name);
EndProcedure

&AtClient
Procedure CalculateAllIndicators(Command)
	ExpandIndicatorsArea = Not Items.CalculateAllIndicators.Check;
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);
EndProcedure

&AtClient
Procedure CollapseIndicators(Command)
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Generate()
	
	// Function call during direct formation, and in case of re-reflection of documents in budgeting.
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Report.BudgetReport.ReportForm.Command.GenerateReport",,
		True);
	
	ClearMessages();
	FormDirectly();
	
EndProcedure

&AtServer
Procedure AlignPeriods()
	
	Catalogs.BudgetProfiles.AlignDatesByBudgetFrequency(BudgetProfile, BeginOfPeriod, EndOfPeriod);
	ActualDataLimit = Catalogs.BudgetProfiles.BorderOfActualDataByBudgetType(BudgetProfile, BeginOfPeriod);
	
	Catalogs.BudgetProfiles.ConfigureGroupOfPeriodElements(BudgetProfile, Items, ActualDataLimit);
	
EndProcedure

&AtServer
Function ParametersForOpeningDecryptionReport(Details, Comparison = False)

	ReportParameters = PrepareReportParameters();
	If Comparison Then
		DateComparison = ReportParameters.DateOfRelevanceComparison;
		ReportParameters.DateOfRelevanceComparison = ReportParameters.UpdateDate;
		ReportParameters.UpdateDate = DateComparison;
		
		DetailsParameters = BudgetReportingServerCall.ParametersForOpeningDecryptionReport(ReportParameters,
				Details,
				AddressOfTheDataCellsComparison);
	Else
		DetailsParameters = BudgetReportingServerCall.ParametersForOpeningDecryptionReport(ReportParameters,
				Details,
				AddressOfCellData);
	EndIf;
	
	Return DetailsParameters;
	
EndFunction

&AtServer
Procedure EditMeasurementFilterValues()
	
	If Not GetFormFunctionalOption("GenerateBudgetsByCompanies") Then
		ToUseASelectionOrganization = False;
		Organization = Undefined;
	EndIf;
	
	If Not GetFormFunctionalOption("GenerateBudgetsByBusinessUnits") Then
		UseSelectionByDivision = False;
		Department = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure FormDirectly()
	
	ExecutionResult = GenerateReportServer();
	If Not ExecutionResult.Status = "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UploadPreparedAlertData", ThisObject);
	
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");
		
		TimeConsumingOperationsClient.WaitCompletion(
			ExecutionResult, CallbackOnCompletion, IdleParameters);
		
	Else
		ReportsERPClientOverridable.AfterGenerationOnClient(ThisObject);
		CheckIfReportsNeedToBeCompared();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckIfReportsNeedToBeCompared()
	If CompareOnDifferentDates = 1 Then
		
		DefaultLanguageCode = CommonClient.DefaultLanguageCode();
		PeriodAsString = TMReportFunctionsClientServer.GetPeriodPresentation(BeginOfPeriod, EndOfPeriod);
		If ValueIsFilled(BudgetProfile) Then
			Title = String(BudgetProfile);
		Else
			Title = NStr("vi = 'Báo cáo theo thiết lập các chỉ tiêu báo cáo ngân sách';
						|ru = 'Отчет по виду бюджета';
						|en = 'Budget profile report'; fa = 'Budget profile report';
						|it = 'Report secondo la tipologia di budget';
						|pl = 'Raport wg rodzaju budżetu';
						|tr = 'Bütçe profiline göre rapor'", DefaultLanguageCode);
		EndIf;
		DatePresentationOption = ?(BegOfDay(UpdateDate) = BegOfDay(DateOfRelevanceComparison),
					"DLF=DT", "DLF=D");
		Title = StringFunctionsClientServer.SubstituteParametersToString("%1 %2", Title, PeriodAsString);
		TitleContinued = NStr("vi = 'vào ngày phù hợp %1';
								|ru = 'на дату актуальности %1';
								|en = 'as of the date of relevance %1'; fa = 'as of the date of relevance %1';
								|it = 'alla data di rilevanza %1';
								|pl = 'w dniu aktualności %1';
								|tr = 'güncel tarihe %1'", DefaultLanguageCode);
		TitleLeft  = Title + " " + StringFunctionsClientServer.SubstituteParametersToString(
			TitleContinued, Format(UpdateDate, DatePresentationOption));
		TitleRight = Title + " " + StringFunctionsClientServer.SubstituteParametersToString(
			TitleContinued, Format(DateOfRelevanceComparison, DatePresentationOption));
		
		SpreadsheetDocumentsStructure1 = New Structure;
		SpreadsheetDocumentsStructure1.Insert("Left_1",  PutToTempStorage(Result, UUID));
		SpreadsheetDocumentsStructure1.Insert("Right", PutToTempStorage(ResultComparison, UUID));
		SpreadsheetDocumentsAddress = PutToTempStorage(SpreadsheetDocumentsStructure1, UUID);
		
		FormOpenParameters = New Structure("SpreadsheetDocumentsAddress, TitleLeft, TitleRight", 
			SpreadsheetDocumentsAddress, TitleLeft, TitleRight);
		
		OpenForm("CommonForm.CompareSpreadsheetDocuments",
			FormOpenParameters, ThisObject, New UUID);
		
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfSettingsPanel(Form)
	
	Form.Items.TheGroupSettingsPanel.Visible = Form.ShowSetupBar;
	Form.Items.SettingsPanel.Check = Form.ShowSetupBar;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfBudgetComparisonDetails(Form)
	
	Form.Items.DateOfRelevanceComparison.Visible = Form.CompareOnDifferentDates = 1;
	Form.Items.DateWhenTheDataIsUpToDate.Visible = Form.CompareOnDifferentDates = 1;
	Form.Items.DateOfDataRelevanceDate.Visible = Form.CompareOnDifferentDates = 0;
	
EndProcedure

&AtServer
Function PrepareReportParameters()
	
	DateOfRelevanceParameter = ?(CompareOnDifferentDates = 1, UpdateDate, EndOfDay(UpdateDate));
	
	ReportParameters = New Structure;
	ReportParameters.Insert("BudgetProfile",    BudgetProfile);
	ReportParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	ReportParameters.Insert("EndOfPeriod",  EndOfPeriod);
	ReportParameters.Insert("UpdateDate", DateOfRelevanceParameter);
	ReportParameters.Insert("ActualDataLimit", ActualDataLimit);
	ReportParameters.Insert("Scenario", ?(YouCanSelectScenario, Scenario, Undefined));
	
	ReportParameters.Insert("CompareOnDifferentRelevanceDates", CompareOnDifferentDates = 1);
	ReportParameters.Insert("DateOfRelevanceComparison", DateOfRelevanceComparison);
	
	If ToUseASelectionOrganization Then
		ReportParameters.Insert("Organization", Organization);
	EndIf;
	If UseSelectionByDivision Then
		ReportParameters.Insert("Department", Department);
	EndIf;
	If UseFilterByCurrency Then
		ReportParameters.Insert("Currency", Currency);
	EndIf;
	
	BudgetTypeData = Common.ObjectAttributesValues(BudgetProfile, "Owner, UseToEnterPlan");
	
	DataStatuses = New ValueList;
	DataStatuses.Add(Enums.PlanStatuses.Upholded);
	If GetFunctionalOption("UseBudgetConfirmation", 
		New Structure("BudgetingModel", BudgetTypeData.Owner)) Then
		If DataForConfirmation Then
			DataStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
		EndIf;
		If DataUnderDevelopment Then
			DataStatuses.Add(Enums.PlanStatuses.UnderPreparation);
		EndIf;
	Else
		DataStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
		DataStatuses.Add(Enums.PlanStatuses.UnderPreparation);
	EndIf;
	ReportParameters.Insert("Status", DataStatuses);
	ReportParameters.Insert("ReportCurrency", ReportCurrency);
	ReportParameters.Insert("GenerationMode", Enums.ModesOfBudgetReportGeneration.Report);
	
	If ValueIsFilled(BudgetingModel) Then
		ReportParameters.Insert("FunctionalCurrency",
			Common.ObjectAttributeValue(BudgetingModel, "FunctionalCurrency"));
	EndIf;
	
	AdditionalFiltersForAnalytics = New Structure;
	For Each DimensionKind In HeaderDimensionList Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind.Value);
		AdditionalFiltersForAnalytics.Insert(FieldName);
		If ThisObject["UseSelectionBy" + FieldName] Then
			ReportParameters.Insert(FieldName, ThisObject[FieldName]);
		EndIf;
	EndDo;
	
	ReportParameters.Insert("AdditionalFiltersForAnalytics", AdditionalFiltersForAnalytics);
	ReportParameters.Insert("ShowItemHierarchy", True);
	ReportParameters.Insert("ConsiderAdditionalSelectionByHierarchy", Not BudgetTypeData.UseToEnterPlan);
	ReportParameters.Insert("QueryTextDocumentTables", "");
	
	If MultiplierOfAmounts = Enums.NumberPresentationKinds.InThousands Then
		ReportParameters.Insert("SumShiftFormat", "NS=3");
	ElsIf MultiplierOfAmounts = Enums.NumberPresentationKinds.InMillions Then
		ReportParameters.Insert("SumShiftFormat", "NS=6");
	EndIf;

	Return ReportParameters;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateTitleText(Form)

	PeriodAsString = TMReportFunctionsClientServer.GetPeriodPresentation(Form.BeginOfPeriod, Form.EndOfPeriod);
	
	If ValueIsFilled(Form.BudgetProfile) Then
		ReportHeader = String(Form.BudgetProfile);
	Else
		ReportHeader = NStr("vi = 'Báo cáo theo thiết lập các chỉ tiêu báo cáo ngân sách';
							|ru = 'Отчет по виду бюджета';
							|en = 'Budget profile report'; fa = 'Budget profile report';
							|it = 'Report secondo la tipologia di budget';
							|pl = 'Raport wg rodzaju budżetu';
							|tr = 'Bütçe profiline göre rapor'");
	EndIf;
	
	Form.Title = StringFunctionsClientServer.SubstituteParametersToString("%1 %2", ReportHeader, PeriodAsString);
	
EndProcedure

&AtServer
Function GenerateReportServer()
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	If Not CheckFilling() Then
		
		StatePresentation = Items.Result.StatePresentation;
		Result.Clear();
		StatePresentation.Visible = True;
		StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
		StatePresentation.Picture = New Picture;
		StatePresentation.Text  = NStr("vi = 'Lỗi loại ngân sách';
										|ru = 'Ошибки в виде бюджета';
										|en = 'Errors in the budget profile'; fa = 'Errors in the budget profile';
										|it = 'Errore nella tipologia di budget';
										|pl = 'Błędy w rodzaju budżetu';
										|tr = 'Bütçe profilinde hatalar'", DefaultLanguageCode);
		
		Return New Structure("Status", "Completed2");
	EndIf;
	If Not ValueIsFilled(UpdateDate) Then
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Trường ""Ngày phù hợp"" không được điền';
							|ru = 'Не заполнено поле ""Дата актуальности""';
							|en = '""Relevance date"" is not filled in'; fa = '""Relevance date"" is not filled in';
							|it = 'Il campo ""Data di rilevanza"" non è compilato';
							|pl = 'Pole ""Data aktualności"" nie jest wypełnione';
							|tr = '""Geçerlilik tarihi"" alanı doldurulmamış'", DefaultLanguageCode);
		Message.Field = ?(CompareOnDifferentDates = 1, "DateWhenTheDataIsUpToDate", "DateOfDataRelevanceDate");
		Message.Message(); 
	EndIf;
	If Not ValueIsFilled(DateOfRelevanceComparison) Then
		Message = New UserMessage;
		Message.Text = NStr("vi = 'Chưa điền trường ""Ngày liên quan (để so sánh)""';
							|ru = 'Не заполнено поле ""Дата актуальности (для сравнения)""';
							|en = '""Relevance date (to compare)"" is not filled in'; fa = '""Relevance date (to compare)"" is not filled in';
							|it = 'Il campo ""Data di rilevanza (per il confronto)"" non è compilato';
							|pl = 'Pole ""Data aktualności (do porównania)"" nie jest wypełnione';
							|tr = '""Geçerlilik tarihi (karşılaştırma için)"" alanı doldurulmamış'", DefaultLanguageCode);
		Message.Field = "DateOfRelevanceComparison";
		Message.Message(); 
	EndIf;
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
	JobID = Undefined;
	
	ReportParameters = PrepareReportParameters();

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunNotInBackground1 = Common.FileInfobase();
	ExecutionParameters.BackgroundJobDescription =
		TMReportFunctionsClientServer.GetNameOfReportExecutionTask(ThisObject);
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"BudgetReportingDisplayServer.PutDataForBudgetReportInStorage",
		ReportParameters,
		ExecutionParameters);
		
	StorageAddress       = ExecutionResult.ResultAddress;
	JobID = ExecutionResult.JobID;
	
	DataStillUpdating = BudgetingServer.DataForBudgetReportIsStillUpdated();
	If DataStillUpdating Then
		MessageText = NStr("vi = 'Báo cáo có thể chứa dữ liệu không chính xác, vì chưa kết thúc chuyển đổi sang phiên bản chương trình mới. Nếu báo cáo đã lâu không sử dụng được, cần liên hệ với người quản trị.';
							|ru = 'Отчет может содержать некорректные данные, так как не завершен переход на новую версию программы. Если отчет долгое время недоступен, необходимо обратиться к администратору.';
							|en = 'The report might contain invalid data since migration to the new version is not completed. If the report is not available for a while, contact the administrator.'; fa = 'The report might contain invalid data since migration to the new version is not completed. If the report is not available for a while, contact the administrator.';
							|it = 'Il report potrebbe contenere dati non corretti, poiché la transizione alla nuova versione del programma non è stata completata. Se il report non è disponibile per un lungo periodo, è necessario contattare l''amministratore.';
							|pl = 'Raport może zawierać niepoprawne dane, ponieważ nie zakończono przejścia na nową wersję programu. Jeżeli raport jest niedostępny przez długi czas, należy zwrócić się do administratora.';
							|tr = 'Rapor, programın yeni sürümüne henüz geçiş yapılmadığı için hatalı veriler içerebilir. Rapor uzun süre kullanılamıyorsa yöneticiye başvurmanız gereklidir.'");
		Common.MessageToUser(MessageText);
	EndIf;
	
	If ExecutionResult.Status = "Completed2" Then
		LoadPreparedData(GetFromTempStorage(ExecutionResult.ResultAddress));
	Else
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");
	EndIf;
	
	If HideSettingsWhenGeneratingReport Then
		ShowSetupBar = False;
		SetVisibilityOfSettingsPanel(ThisObject);
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

&AtServer
Procedure FormControl()
	
	OptionsParameters = New Structure("BudgetingModel", BudgetingModel);
	SetFormFunctionalOptionParameters(OptionsParameters);
	
	Items.Scenario.Visible = YouCanSelectScenario;
	Items.GroupFilterByCompanies.Visible = YouCanSelectCompany;
	Items.GroupSelectionByDivision.Visible = YouCanSelectADepartment;
	
	SetVisibilityOfSettingsPanel(ThisObject);
	SetVisibilityOfBudgetComparisonDetails(ThisObject);
	
	Catalogs.BudgetProfiles.ConfigureGroupOfPeriodElements(BudgetProfile, Items, ActualDataLimit);
	
EndProcedure

&AtServer
Procedure LoadPreparedData(Val ExecutionResult = Undefined)
	DocumentsCount = Undefined;
	
	If ExecutionResult = Undefined Then
		ExecutionResult = GetFromTempStorage(StorageAddress);
	EndIf;
	Result = ExecutionResult.Result;
	CellData_ = ExecutionResult.CellData_;
	DetailsData = ExecutionResult.DetailsData;
	
	AddressOfCellData = PutToTempStorage(CellData_, UUID);
	DetailsDataAddress = PutToTempStorage(DetailsData, UUID);
	
	If CompareOnDifferentDates = 1
		And ExecutionResult.Property("CellDataComparison")
		And ExecutionResult.Property("DecryptionDataComparison")
		And ExecutionResult.Property("ResultComparison") Then
		ResultComparison = ExecutionResult.ResultComparison;
		
		CellDataComparison       = ExecutionResult.CellDataComparison;
		DecryptionDataComparison = ExecutionResult.DecryptionDataComparison;
		
		AddressOfTheDataCellsComparison  = PutToTempStorage(CellDataComparison, UUID);
		AddressOfDecryptionDataComparison = PutToTempStorage(DecryptionDataComparison, UUID);
	Else
		ResultComparison.Clear();
		If IsTempStorageURL(AddressOfTheDataCellsComparison) Then
			DeleteFromTempStorage(AddressOfTheDataCellsComparison);
		EndIf;
		If IsTempStorageURL(AddressOfDecryptionDataComparison) Then
			DeleteFromTempStorage(AddressOfDecryptionDataComparison);
		EndIf;
		AddressOfTheDataCellsComparison = "";
		AddressOfDecryptionDataComparison = "";
	EndIf;
	
	JobID = Undefined;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "DontUse");
	
	#Region StartBackgroundReflectionOfDocumentsInBudgeting
		AuxProperties = Report.SettingsComposer.UserSettings.AdditionalProperties;
		
		AuxProperties.Delete("NumberOfDocumentsToBeReflectedInBudgeting");
		StartBackgroundTask = False;
		If InformationRegisters.JobsForPostingInBudgeting.RequiredReflectionInBudgetingForReportForPeriod(
		BeginOfPeriod, EndOfPeriod, DocumentsCount, StartBackgroundTask) Then
			
			If StartBackgroundTask Then
				ActualBudgetingDataServer.ReflectDocumentsAsBackgroundTask(BeginOfPeriod, EndOfPeriod);
			EndIf;
			AuxProperties.Insert("NumberOfDocumentsToBeReflectedInBudgeting", DocumentsCount);
			AuxProperties.Insert("BeginOfPeriod", BeginOfPeriod);
			AuxProperties.Insert("EndOfPeriod", EndOfPeriod);
			
			AuxProperties.Insert("CheckingStoredRulesBudgetView", BudgetProfile);
			
		EndIf;
	#EndRegion
	
	ActualBudgetingDataServer.DeduceRelevanceOfReflectionOfActualData(Result, AuxProperties,
		StartBackgroundTask);
	If CompareOnDifferentDates = 1 Then
		ActualBudgetingDataServer.DeduceRelevanceOfReflectionOfActualData(ResultComparison,
			AuxProperties, StartBackgroundTask);
		
		DatePresentationOption = ?(BegOfDay(UpdateDate) = BegOfDay(DateOfRelevanceComparison),
					"DLF=DT", "DLF=D");
		Items.ReportsTables.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.ReportAsOfTheFirstDateOfRelevance.Title = Format(UpdateDate, DatePresentationOption);
		Items.ReportAsOfTheSecondDateOfRelevance.Title = Format(DateOfRelevanceComparison, DatePresentationOption);
		Items.ReportAsOfTheSecondDateOfRelevance.Visible = True;
		Items.ReportsTables.CurrentPage = Items.ReportAsOfTheFirstDateOfRelevance;
	Else
		Items.ReportsTables.PagesRepresentation = FormPagesRepresentation.None;
		Items.ReportAsOfTheSecondDateOfRelevance.Visible = False;
		Items.ReportsTables.CurrentPage = Items.ReportAsOfTheFirstDateOfRelevance;
	EndIf;
	
	If TypeOf(PrintSettings) = Type("Structure") Then
		FillPropertyValues(Result, PrintSettings);
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadPreparedAlertData(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		Try
			LoadPreparedData();
			ReportsTMClientOverridable.AfterGenerationOnClient(ThisObject);
			CheckIfReportsNeedToBeCompared();
		Except
			CommonClientServer.SetSpreadsheetDocumentFieldState(
				Items.Result, "DontUse");
			Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelJobExecution()
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

// End of period selection
// 
// Parameters:
// 	SelectionResult - Undefined, StandardPeriod - 
// 	AddlParameters - Structure - 
&AtClient
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	BeginOfPeriod = SelectionResult.StartDate;
	EndOfPeriod  = SelectionResult.EndDate;
	BeginOfPeriod = ?(BeginOfPeriod > EndOfPeriod, EndOfPeriod, BeginOfPeriod);
	
	AlignPeriods();
	
	UpdateTitleText(ThisObject); 
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
	EndIf;

EndProcedure

&AtClient
Procedure SetFactBoundary(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ActualDataLimit = Result;
		If Not ValueIsFilled(JobID) Then
			CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
			CommonClientServer.SetSpreadsheetDocumentFieldState(Items.ResultComparison, "Irrelevance");
		EndIf;
		FormControl();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowSendEmailDialog(NameOfReportType)
	Attachment = New Structure;
	Attachment.Insert("AddressInTempStorage", PutToTempStorage(Result, UUID));
	Attachment.Insert("Presentation", NameOfReportType);
	
	AttachmentsList = CommonClientServer.ValueInArray(Attachment);
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		SendOptions = ModuleEmailOperationsClient.EmailSendOptions();
		SendOptions.Subject = NameOfReportType;
		SendOptions.Attachments = AttachmentsList;
		ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	EndIf;
EndProcedure

#Region IndicatorsCalculation

// Parameters:
//  Parent - FormGroup
//  Menu - Undefined
//       - ValueList of String
// 
// Returns:
//  - Undefined
//  - ValueList of String
//
&AtClient
Function MenuOfIndicatorTypes(Parent, Menu = Undefined)

	If Menu = Undefined Then
		Menu = New ValueList;
	EndIf;

	MenuItems = Parent.ChildItems; // FormItems

	For Each Item In MenuItems Do

		If TypeOf(Item) <> Type("FormGroup") Then
			Menu.Add(Item.Name, Item.Title, MainIndicator = Item.Name);
		Else
			MenuOfIndicatorTypes(Item, Menu);
		EndIf;

	EndDo;

	MenuItem = Menu.FindByValue(Items.CalculateAllIndicators.Name);

	If MenuItem <> Undefined Then
		MenuItem.Check = ExpandIndicatorsArea;
	EndIf;

	Return Menu;

EndFunction

&AtClient
Procedure AfterSelectingTheIndicator(TheSelectedIndicator, AdditionalParameters) Export

	If TypeOf(TheSelectedIndicator) <> Type("ValueListItem") Then
		Return;
	EndIf;

	If TheSelectedIndicator.Value = Items.CalculateAllIndicators.Name Then

		ExpandIndicatorsArea = Not Items.CalculateAllIndicators.Check;
		CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);

	Else
		CalculateIndicators(TheSelectedIndicator.Value);
	EndIf;

EndProcedure

// Performs calculation and output of indicators of the selected area of cells.
// See event handler reportabledocumentactivation of the area.
//
&AtClient
Procedure CalculateIndicatorsDynamically()

	CalculateIndicators();

EndProcedure

&AtClient
Procedure CalculateIndicators(CurrentCommand = "")

	Factor = "";
	CommonInternalClient.CalculateIndicators(ThisObject, "Result", CurrentCommand, 2);

EndProcedure

&AtServer
Function SpreadsheetDocumentPropertiesToCopy()
	Return "PrintParametersKey,FitToPage,Output,PageHeight,DuplexPrinting,Protection,PrinterName,LanguageCode,
	|Copies,PrintScale,FirstPageNumber,PageOrientation,TopMargin,LeftMargin,
	|BottomMargin,RightMargin,Collate,HeaderSize,FooterSize,PageSize,
	|PrintAccuracy,BackgroundPicture,BlackAndWhite,PageWidth,PerPage";
EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_UpdateDate" Then
		DateWhenTheDataIsUpToDateOnChange(Items.DateWhenTheDataIsUpToDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_CurrentDateDate" Then
		DateOfDataRelevanceDateOnChange(Items.DateOfDataRelevanceDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_DateOfRelevanceComparison" Then
		DateOfRelevanceComparisonOnChange(Items.DateOfRelevanceComparison);
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
