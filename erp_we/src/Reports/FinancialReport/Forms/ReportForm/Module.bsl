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
	
	// The report is only available for contextual call
	If Not Parameters.Property("GenerateReport") Then
		Cancel = True;
		Raise NStr("vi = 'Báo cáo không có ý định được chạy thủ công.';
					|ru = 'Отчет не предназначен для ручного запуска.';
					|en = 'The report is not designed for manual launch.'; fa = 'The report is not designed for manual launch.';
					|it = 'Il report non è destinato all''avvio manuale.';
					|pl = 'Raport nie jest przeznaczony do ręcznego startu.';
					|tr = 'Rapor, manuel olarak çalıştırılmak için amaçlanmamıştır.'");
	EndIf;
	
	Items.GroupSelectionInTheDirectionOf.Visible = Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed();
	
	Report.MultiplierOfAmounts = Enums.NumberPresentationKinds.Unchanged;
	If Parameters.Property("Filter") Then
		
		FillPropertyValues(Report, Parameters.Filter);
		
	EndIf;
	
	If Parameters.Property("StorageAddress") Then
		
		StorageAddress = Parameters.StorageAddress;
		LoadPreparedData();
		
	EndIf;
	
	If Parameters.GenerateReport Then
		
		GenerateReport = Parameters.GenerateReport;
		
	EndIf;
	
	If Parameters.Property("DetailsParameters") Then
		DetailsParameters = Parameters.DetailsParameters; //Structure
		FillPropertyValues(Report, DetailsParameters);
		FillPropertyValues(Report, DetailsParameters.Filter);
		If DetailsParameters.Filter.Property("Organization") And ValueIsFilled(DetailsParameters.Filter.Organization) Then
			UseFilterByCompanies = True;
			If TypeOf(DetailsParameters.Filter.Organization) = Type("Array") Then
				ArrayOrganization = DetailsParameters.Filter.Organization;
			Else
				ArrayOrganization = CommonClientServer.ValueInArray(DetailsParameters.Filter.Organization);
			EndIf;
			Companies.LoadValues(ArrayOrganization);
			DetailsParameters.Delete("Organization");
		EndIf;
		If DetailsParameters.Filter.Property("Department") And ValueIsFilled(DetailsParameters.Filter.Department) Then
			UseFilterByDepartments = True;
			If TypeOf(DetailsParameters.Filter.Department) = Type("Array") Then
				ArrayOfDivisions = DetailsParameters.Filter.Department;
			Else
				ArrayOfDivisions = CommonClientServer.ValueInArray(DetailsParameters.Filter.Department);
			EndIf;
			Departments.LoadValues(ArrayOfDivisions);
			DetailsParameters.Delete("Department");
		EndIf;
		If DetailsParameters.Filter.Property("LineOfBusiness") And ValueIsFilled(DetailsParameters.Filter.LineOfBusiness) Then
			UseSelectionByDirection = True;
			If TypeOf(DetailsParameters.Filter.LineOfBusiness) = Type("Array") Then
				ArrayOfActivities = DetailsParameters.Filter.LineOfBusiness;
			Else
				ArrayOfActivities = CommonClientServer.ValueInArray(DetailsParameters.Filter.LineOfBusiness);
			EndIf;
			Directions.LoadValues(ArrayOfActivities);
			DetailsParameters.Delete("LineOfBusiness");
		EndIf;
		DetailsParameters.Factor.Insert("Filter", DetailsParameters.Filter);
		If DetailsParameters.Property("ExtDimensionType") Then
			DetailsParameters.Factor.Insert("ExtDimensionType", DetailsParameters.ExtDimensionType);
		EndIf;
		ReportPeriod = DetailsParameters.ReportPeriod; // StandardPeriod - 
		Report.BeginOfPeriod = ReportPeriod.StartDate;
		Report.EndOfPeriod = ReportPeriod.EndDate;
		Resource = DetailsParameters.Resource;
		IndicatorData = PutToTempStorage(DetailsParameters.Factor, UUID);
		DecryptionRate = DetailsParameters.Factor; // Structure -  
		DerivedItem = DecryptionRate.Ref;
		Title = NStr("vi = 'Giải thích về chỉ số:';
					|ru = 'Расшифровка показателя:';
					|en = 'Indicator drill-down:'; fa = 'Indicator drill-down:';
					|it = 'Trascrizione dell''indice:';
					|pl = 'Szczegóły wskaźnika:';
					|tr = 'Göstergenin transkripti:'")+ " " + DecryptionRate.NameForPrinting;
		
		Items.AdditionalCommandPanelGroup.Visible = False;
	EndIf;
	
	FillInReportResource();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	If Not ValueIsFilled(DerivedItem) Then
		UpdateTitleText(ThisForm);
	EndIf;
	
	If ValueIsFilled(DerivedItem) Then
		SetVisibilityOfSettingsPanel(False);
	EndIf;
	
	If GenerateReport Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");
		AttachIdleHandler("FormDirectly", 0.1, True);
	EndIf;
	
	If ValueIsFilled(StorageAddress) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	EndIf;
	Items.SettingsPanel.Check = Items.TheGroupSettingsPanel.Visible;
	
	CommonInternalClient.SetIndicatorsPanelVisibiility(Items, ExpandIndicatorsArea);
	CalculateIndicators(MainIndicator);
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)

	VariantModified					= False;
	UserSettingsModified = True;

EndProcedure

&AtClient
Procedure OnClose(Exit)

	If Exit Then
		Return;
	EndIf;

EndProcedure

&AtServer
Procedure OnSaveUserSettingsAtServer(Settings)

	ReportData = New Structure;
	ReportData.Insert("ReportKind", Report.ReportKind);
	ReportData.Insert("BeginOfPeriod", Report.BeginOfPeriod);
	ReportData.Insert("EndOfPeriod", Report.EndOfPeriod);
	ReportData.Insert("MultiplierOfAmounts", Report.MultiplierOfAmounts);
	ReportData.Insert("HideSettingsWhenGeneratingReport", HideSettingsWhenGeneratingReport);
	ReportData.Insert("Companies", Companies.UnloadValues());
	ReportData.Insert("Departments", Departments.UnloadValues());
	
	Settings.AdditionalProperties.Insert("ReportData", ReportData);

EndProcedure

&AtServer
Procedure OnLoadUserSettingsAtServer(Settings)

	ReportKind = Report.ReportKind;
	ReportingSet = Report.ReportingSet;
	
	If Not Parameters.Property("DetailsParameters") Then
		If Settings <> Undefined And Settings.AdditionalProperties.Property("ReportData") Then
			ReportData = Settings.AdditionalProperties.ReportData;
			If TypeOf(ReportData) = Type("Structure") Then
				FillPropertyValues(ThisForm, ReportData);
				FillPropertyValues(Report, ReportData);
				Companies.ValueType = New TypeDescription("CatalogRef.Companies");
				Companies.LoadValues(ReportData.Companies);
				Departments.ValueType = New TypeDescription("CatalogRef.BusinessStructure");
				Departments.LoadValues(ReportData.Departments);
				UseFilterByCompanies = Companies.Count();
				UseFilterByDepartments = Departments.Count();
			EndIf;
		EndIf;
	EndIf;
	Items.SettingsPanel.Title = NStr("vi = 'Tùy chỉnh nhanh';
									|ru = 'Быстрые настройки';
									|en = 'Quick settings'; fa = 'تنظیمات سریع';
									|it = 'Impostazioni veloci';
									|pl = 'Szybkie ustawienia';
									|tr = 'Hızlı ayarlar'");
	
	If ValueIsFilled(ReportKind) Then
		Report.ReportKind = ReportKind;
	EndIf;
	
	If ValueIsFilled(ReportingSet) Then
		Report.ReportingSet = ReportingSet;
	EndIf;
	
	If Not Parameters.Property("DetailsParameters") Then
		UpdateTitleText(ThisForm);
	EndIf;
	
	SetCurYearToEmptyPeriod();
	
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)

	FormDirectly();

EndProcedure

&AtClient
Procedure SettingsPanel(Command)

	SetVisibilityOfSettingsPanel(Not Items.TheGroupSettingsPanel.Visible);

EndProcedure

&AtClient
Procedure SendEmail(Command)
	
	NameOfReportType = String(Report.ReportKind);
	StatePresentation = Items.Result.StatePresentation;
	If StatePresentation.Visible = True
		And StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance Then
		
		QueryText = NStr("vi = 'Chưa lập báo cáo. Lập báo cáo?';
						|ru = 'Отчет не сформирован. Сформировать?';
						|en = 'Report not generated. Generate?'; fa = 'Report not generated. Generate?';
						|it = 'Report non generato. Generarlo?';
						|pl = 'Raport nie został wygenerowany. Chcesz utworzyć?';
						|tr = 'Rapor oluşturulmadı. Oluşturulsun mu?'");

		ShowQueryBox(New CallbackDescription("SendEmailCompletion", ThisObject, New Structure("NameOfReportType", NameOfReportType)), QueryText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes);
		Return;
	EndIf;
	
	EmailSnippet(NameOfReportType);
EndProcedure

&AtClient
Procedure SendEmailCompletion(QuestionResult, AdditionalParameters) Export
	
	NameOfReportType = AdditionalParameters.NameOfReportType;
	
	
	Response = QuestionResult;
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	FormDirectly();
	
	EmailSnippet(NameOfReportType);

EndProcedure

&AtClient
Procedure EmailSnippet(Val NameOfReportType)
	
	Attachment = New Structure;
	Attachment.Insert("AddressInTempStorage", PutToTempStorage(ThisForm.Result, UUID));
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

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectPeriod(Command)

	ChoiceParameters = New Structure("BeginOfPeriod,EndOfPeriod", Report.BeginOfPeriod, Report.EndOfPeriod);
	CallbackDescription = New CallbackDescription("SelectPeriodCompletion", ThisObject);
	OpenForm("CommonForm.SelectAStandardPeriod", ChoiceParameters, Items.SelectPeriod, , , , CallbackDescription);

EndProcedure

&AtClient
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	FillPropertyValues(Report, SelectionResult, "BeginOfPeriod,EndOfPeriod");
	
	UpdatePeriodDates(); 
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;

EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	
	UpdatePeriodDates();
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	
	UpdatePeriodDates();
	If Not ValueIsFilled(JobID) Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportingSetOnChange(Item)
	
	ReportingSetOnChangeServer();
	
EndProcedure

&AtServer
Procedure ReportingSetOnChangeServer()
	
	ReportsList = Items.ReportKind.ChoiceList;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ReportsKinds.FinancialReportType AS FinancialReportType
	|FROM
	|	Catalog.FinancialReportSets.ReportsKinds AS ReportsKinds
	|WHERE
	|	ReportsKinds.Ref = &Ref";
	Query.SetParameter("Ref", Report.ReportingSet);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ReportsList.Add(Selection.FinancialReportType);
	EndDo;
	
	If ReportsList.Count() > 0 Then
		Report.ReportKind = ReportsList[0].Value;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReportParameterWhenChanging(Item)
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	Modified = False;
	
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)

	StandardProcessing = False;
	InternationalReportingClient.ProcessingReportDecryption(ThisForm, Item, Details);

EndProcedure

&AtClient
Procedure ResultAdditionalDetailProcessing(Item, Details, StandardProcessing)

	// We will not process clicking on the right mouse button.
	// Let's show the standard context menu of a tabular document cell.
	Details = Undefined;

EndProcedure

&AtClient
Procedure ResultWhenTheAreaIsActivated(Item)
	
	If TypeOf(Result.SelectedAreas) = Type("SpreadsheetDocumentSelectedAreas") Then
		AttachIdleHandler("CalculateIndicatorsDynamically", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FormDirectly()
	
	ClearMessages();
	
	ExecutionResult = GenerateReportServer();
	If Not ExecutionResult.Status = "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("GenerateAlertReport", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(ExecutionResult, CallbackOnCompletion, IdleParameters);
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");

	EndIf;
	
EndProcedure


&AtClient
Procedure GenerateAlertReport(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		LoadPreparedData();
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfSettingsPanel(Show)
	
	Items.TheGroupSettingsPanel.Visible = Show;
	Items.SettingsPanel.Check = Items.TheGroupSettingsPanel.Visible;
	
EndProcedure

&AtServer
Function PrepareReportParameters()

	FilterReport_ = New Structure;
	If UseFilterByCompanies Then
		FilterReport_.Insert("Organization", Companies.UnloadValues());
	EndIf;
	If UseFilterByDepartments Then
		FilterReport_.Insert("Department", Departments.UnloadValues());
	EndIf;
	If UseSelectionByDirection Then
		FilterReport_.Insert("LineOfBusiness", Directions.UnloadValues());
	EndIf;
	
	Attributes = GeneralPurposeTMServerCall.ObjectAttributesValues(Report.ReportKind, 
							"DisplayRowCode,DisplayNoteInReport,RowCodeHeader,CommentHeader,ReportLanguage");
	ReportParameters = New Structure;
	ReportParameters.Insert("DisplayRowCode",         Attributes.DisplayRowCode);
	ReportParameters.Insert("DisplayNoteInReport",        Attributes.DisplayNoteInReport);
	ReportParameters.Insert("RowCodeHeader",       Attributes.RowCodeHeader);
	ReportParameters.Insert("CommentHeader",       Attributes.CommentHeader);
	ReportParameters.Insert("ReportLanguage",                Attributes.ReportLanguage);
	ReportParameters.Insert("ReportPeriod",              InternationalReportingServer.ReportPeriod(
												Report.BeginOfPeriod, EndOfDay(Report.EndOfPeriod)));
	ReportParameters.Insert("Filter",                     FilterReport_);
	ReportParameters.Insert("ReportingSet",        Report.ReportingSet);
	ReportParameters.Insert("ReportKind",                 Report.ReportKind);
	ReportParameters.Insert("Resource",                    Resource);
	ReportParameters.Insert("DetailsData",         PutToTempStorage(Undefined, UUID));
	ReportParameters.Insert("IDOfTheReportForm",  UUID);
	ReportParameters.Insert("MultiplierOfAmounts",             Report.MultiplierOfAmounts);
	If Not DerivedItem.IsEmpty() Then
		DecryptionRate = GetFromTempStorage(IndicatorData);
		ReportParameters.Insert("IndicatorData",      DecryptionRate);
		ReportParameters.Insert("AddressOfIndicatorData", IndicatorData);
	EndIf;
	ReportParameters.Insert("DateReportWasGenerated", CurrentSessionDate());
	
	Return ReportParameters;

EndFunction

&AtClient
Procedure UpdatePeriodDates()

	If ValueIsFilled(Report.BeginOfPeriod) Then
		Report.BeginOfPeriod = BegOfMonth(Report.BeginOfPeriod);
	EndIf;
	
	If ValueIsFilled(Report.EndOfPeriod) Then
		Report.EndOfPeriod = EndOfMonth(Report.EndOfPeriod);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTitleText(Form)

	Report = Form.Report;
	ReportHeader = NStr("vi = 'Báo cáo quốc tế';
						|ru = 'Международный отчет';
						|en = 'Financial report'; fa = 'گزارش مالی';
						|it = 'Report internazionale';
						|pl = 'Raport międzynarodowy';
						|tr = 'Uluslararası rapor'");
	If ValueIsFilled(Report.ReportKind) Then
		ReportHeader = String(Report.ReportKind);
	EndIf;
	
	Form.Title = ReportHeader;

EndProcedure

&AtServer
Procedure SetCurYearToEmptyPeriod()
	
	If Not ValueIsFilled(Report.BeginOfPeriod) Then
		Report.BeginOfPeriod = BegOfYear(CurrentSessionDate());
		Report.EndOfPeriod = EndOfYear(CurrentSessionDate());
	EndIf;
	
EndProcedure

&AtServer
Function GenerateReportServer()

	SetCurYearToEmptyPeriod();
	
	If Not CheckFilling() Then
		Return New Structure("Status", "Completed2");
	EndIf;
	
	TimeConsumingOperations.CancelJobExecution(JobID);

	JobID = Undefined;

	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	
	Report.SettingsComposer.Settings.AdditionalProperties.Insert("TitleOutput", TitleOutput);
	Report.SettingsComposer.Settings.AdditionalProperties.Insert("OutputTheBasement"   , OutputTheBasement);

	ReportParameters = PrepareReportParameters();
		
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
		
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"InternationalReportingServer.GenerateReport",
		ReportParameters,
		ExecutionParameters);
	
	StorageAddress = ExecutionResult.ResultAddress;
	JobID = ExecutionResult.JobID;
	
	If ExecutionResult.Status = "Completed2" Then
		LoadPreparedData(True);
	EndIf;
	
	InternationalReportingClientServer.HideSettingsWhenGeneratingReport(ThisForm);
	Modified = False;
	
	Return ExecutionResult;

EndFunction

&AtServer
Procedure LoadPreparedData(FileIB = Undefined)

	ExecutionResult = GetFromTempStorage(StorageAddress);
	Result = ExecutionResult.Result;

	If FileIB = Undefined Then
		FileIB = Common.FileInfobase();
	EndIf;
	
	If Not FileIB And ExecutionResult.Property("ErrorsMessages") Then
		For Each Message In ExecutionResult.ErrorsMessages Do
			Message.Message();
		EndDo;
	EndIf;
	
	JobID = Undefined;

	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	If Not ValueIsFilled(Report.ReportKind) Then
		FillPropertyValues(Report, ExecutionResult);
	EndIf;
	
	If Parameters.Property("UserSettings") Then
		If Parameters.UserSettings.AdditionalProperties.Property("ReportData") Then
			ReportData = Parameters.UserSettings.AdditionalProperties.ReportData;
			If TypeOf(ReportData) = Type("ValueStorage") Then
				ReportData = ReportData.Get();
				FillPropertyValues(Report, ReportData);
				Resource = ReportData.Resource;
				Companies.LoadValues(ReportData.Companies.UnloadValues());
				UseFilterByCompanies = Companies.Count() > 0;
				Departments.LoadValues(ReportData.Departments.UnloadValues());
				UseFilterByDepartments = Departments.Count() > 0;
			EndIf;
		EndIf;
	EndIf;
	FillInReportResource();

EndProcedure

&AtServer
Procedure FillInReportResource()
	
	If ValueIsFilled(Report.ReportKind) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	TableOfAccountPlans.ChartOfAccounts AS ChartOfAccounts
		|FROM
		|	Catalog.FinancialReportTypes.ChartsOfAccounts AS TableOfAccountPlans
		|WHERE
		|	TableOfAccountPlans.Ref = &ReportKind";
		Query.SetParameter("ReportKind", Report.ReportKind);
		ReportAccountPlans = Query.Execute().Unload().UnloadColumn("ChartOfAccounts");
		
		InternationalReportingServer.FillInListOfReportResources(Items.Resource, ResourceCurrencies, ReportAccountPlans);
		
		If Items.Resource.ChoiceList.Count() > 0
			And (Resource = "" Or Items.Resource.ChoiceList.FindByValue(Resource) = Undefined) Then
			Resource = Items.Resource.ChoiceList[0].Value;
		EndIf;
		
		Items.Resource.Visible =  Items.Resource.ChoiceList.Count() > 0;
		
	EndIf;
	
EndProcedure

#Region IndicatorsCalculation

// Parameters:
//  Parent - FormGroup
//  Menu - Undefined
//       - ValueList
// 
// Returns:
//  - Undefined
//  - ValueList
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

#EndRegion

#EndRegion
