#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	ResultDocument.Clear();

	ReportSettings = SettingsComposer.GetSettings();

	PeriodParameter = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("ReportPeriod"));

	If PeriodParameter <> Undefined Then
		BeginOfPeriod = PeriodParameter.Value["StartDate"];
		EndOfPeriod = PeriodParameter.Value["EndDate"];

		PeriodParameter.Use = True;
	Else
		BeginOfPeriod = BegOfMonth(CurrentSessionDate());
		EndOfPeriod = EndOfMonth(CurrentSessionDate());

		PeriodParameter = ReportSettings.DataParameters.Items.Add();
		PeriodParameter.Value = New StandardPeriod;
		PeriodParameter.Value["StartDate"] = BeginOfPeriod;
		PeriodParameter.Value["EndDate"] = EndOfPeriod;
		PeriodParameter.Use = True;
	EndIf;

	ReportDateParameter = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("Period"));
	If ReportDateParameter = Undefined Then
		ReportDate = CurrentSessionDate();
		ReportDateParameter = ReportSettings.DataParameters.Items.Add();
		ReportDateParameter.Use = True;
		ReportDateParameter.Value = ReportDate;
	Else
		ReportDateParameter.Use = True;
		If ValueIsFilled(ReportDateParameter.Value) Then
			If TypeOf(ReportDateParameter.Value) = Type("StandardBeginningDate") Then
				ReportDate = ReportDateParameter.Value.Date;
			Else
				ReportDate = ReportDateParameter.Value;
			EndIf;
		Else
			ReportDate = CurrentSessionDate();
			ReportDateParameter.Value = ReportDate;
		EndIf;
	EndIf;

	StartOfPeriodParameter = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("BeginOfPeriod"));
	If StartOfPeriodParameter = Undefined Then
		StartOfPeriodParameter = ReportSettings.DataParameters.Items.Add();
		StartOfPeriodParameter.Use = True;
		StartOfPeriodParameter.Value = BeginOfPeriod;
	Else
		StartOfPeriodParameter.Use = True;
		If Not ValueIsFilled(StartOfPeriodParameter.Value) Then
			StartOfPeriodParameter.Value = BeginOfPeriod;
		EndIf;
	EndIf;

	EndOfPeriodParameter = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("EndOfPeriod"));
	If EndOfPeriodParameter = Undefined Then
		EndOfPeriodParameter = ReportSettings.DataParameters.Items.Add();
		EndOfPeriodParameter.Use = True;
		EndOfPeriodParameter.Value = BeginOfPeriod;
	Else
		EndOfPeriodParameter.Use = True;
		If Not ValueIsFilled(EndOfPeriodParameter.Value) Then
			EndOfPeriodParameter.Value = EndOfPeriod;
		EndIf;
	EndIf;

	ResponsibleParameter = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("EmployeeResponsible"));
	If ResponsibleParameter = Undefined Then
		ResponsibleParameter = ReportSettings.DataParameters.Items.Add();
	EndIf;

	ReportParameters = New Structure;
	ReportParameters.Insert("EmployeeResponsible", "");
	ReportParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	ReportParameters.Insert("EndOfPeriod",  EndOfPeriod);

	If ValueIsFilled(ResponsibleParameter.Value) And ResponsibleParameter.Use Then
		ReportParameters.Insert("EmployeeResponsible", ResponsibleParameter.Value);
	EndIf;

	StandardProcessing = False;
		
	// Document parameters
	ResultDocument.ReadOnly = True;
	ResultDocument.PrintParametersKey = "PRINTPARAMETERS_Timesheet_Timesheet_PrintingTimesheet";
	ResultDocument.PageOrientation = PageOrientation.Landscape;

	CompositionTemplate = DataCompositionServer.GetLayoutTemplate(DataCompositionSchema, ReportSettings);
		
	// Let's create and initialize the layout processor.
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , , True);

	DataOnTime = New ValueTree;
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(DataOnTime);
		
	// Denote the beginning of the output
	OutputProcessor.Output(CompositionProcessor, True);
	ToOutputTemplate(DataOnTime, ReportParameters, ResultDocument);
	AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
	AuxProperties.Insert("ReportIsBlank", DataOnTime.Rows.Count() = 0);

EndProcedure

#EndRegion

#Region Private

Procedure ToOutputTemplate(OrganizationData, ReportParameters, SpreadsheetDocument = Undefined)

	BeginOfPeriod = ReportParameters.BeginOfPeriod;
	EndOfPeriod  = ReportParameters.EndOfPeriod;

	If SpreadsheetDocument = Undefined Then
		SpreadsheetDocument = New SpreadsheetDocument;
	EndIf;

	EmptyRows = New Array;
	For Each OrganizationData_1 In OrganizationData.Rows Do
		If OrganizationData_1.Rows.Count() = 0 Then
			EmptyRows.Add(OrganizationData_1);
		EndIf;
	EndDo;
	For Each IsBlankString In EmptyRows Do
		OrganizationData.Rows.Delete(IsBlankString);
	EndDo;

	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersKey = "PRINTPARAMETERS_Timesheet_Timesheet_PrintingTimesheet";
	Template = PrintManagement.PrintFormTemplate(
		"Document.TimesheetHR.TimesheetByDay");

	TablePeriods = TimeTrackingServer.CreateSeparatePeriodTable(BeginOfPeriod, EndOfPeriod);

	AccountsOfCompanies = 0;
	For Each DataOnTime In OrganizationData.Rows Do
		AccountsOfCompanies = AccountsOfCompanies + 1;
		If DataOnTime.Rows.Count() = 0 Then
			Continue;
		EndIf;

		HeaderStructure_ = New Structure("Organization", DataOnTime.Organization);
		FillPropertyValues(HeaderStructure_, DataOnTime);
		HeaderStructure_.Insert("DocumentDate", Format(CurrentSessionDate(), "DLF=D"));
		HeaderStructure_.Insert("BeginOfPeriod", Format(BeginOfPeriod, "DLF=D"));
		HeaderStructure_.Insert("PeriodEnding", Format(EndOfPeriod, "DLF=D"));

		Area = Template.GetArea("Header");
		FillPropertyValues(Area.Parameters, HeaderStructure_);
		SpreadsheetDocument.Put(Area);

		TimeTrackingServer.OutputTimesheetDataToTabularDocument(
			TablePeriods, DataOnTime, SpreadsheetDocument, Template);

		Area = Template.GetArea("Footer");
		If ValueIsFilled(ReportParameters.EmployeeResponsible) Then
			BasementData = New Structure;
			BasementData.Insert("Approved_1", PersonsTM.IndividualShortName(ReportParameters.EmployeeResponsible,
				CurrentSessionDate()));
			BasementData.Insert("ApprovedJobTitle", TimeTrackingServer.DetermineJobTitleOfIndividual(
				ReportParameters.EmployeeResponsible, DataOnTime.Organization, CurrentSessionDate()).Presentation);
			FillPropertyValues(Area.Parameters, BasementData);
		EndIf;

		SpreadsheetDocument.Put(Area);
		If Not AccountsOfCompanies = OrganizationData.Rows.Count() Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
	EndDo;

EndProcedure

// For the General "report Form" form of the "report Options" subsystem.
// Parameters:
//   Form - ClientApplicationForm - Report form
//   VariantKey - String - Report variant key
//   Settings - Structure - Report Form Settings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export

	Settings.Print.PageOrientation = PageOrientation.Landscape;
	Settings.Events.BeforeImportSettingsToComposer = True;

EndProcedure
	
// Called before loading new data layout settings. 
// Used to change the layout scheme.
//
// Parameters:
//   Context - ClientApplicationForm - The context of the Settings Composer
//   SchemaKey - String - Data Layout Schema key
//   VariantKey - String - The key of the data layout settings option
//   NewDCSettings - DataCompositionSettings - New data layout settings
//   NewDCUserSettings - DataCompositionUserSettings - New custom data layout settings
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings,
	NewDCUserSettings) Export

	If SchemaKey <> VariantKey Then

		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);

		SchemaKey = VariantKey;

	EndIf;

EndProcedure

#EndRegion

#EndIf