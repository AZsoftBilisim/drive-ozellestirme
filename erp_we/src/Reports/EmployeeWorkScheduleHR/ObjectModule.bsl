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

	EndOfPeriodParameter  = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("EndOfPeriod"));
	If EndOfPeriodParameter = Undefined Then
		EndOfPeriodParameter = ReportSettings.DataParameters.Items.Add();
		EndOfPeriodParameter.Use = True;
		EndOfPeriodParameter.Value = EndOfPeriod;
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
	ReportParameters.Insert("EndOfPeriod", EndOfPeriod);
	ReportParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	If ValueIsFilled(ResponsibleParameter.Value) And ResponsibleParameter.Use Then
		ReportParameters.Insert("EmployeeResponsible", ResponsibleParameter.Value);
	EndIf;
	FilterDepartment = CommonClientServer.FindFilterItemsAndGroups(ReportSettings.Filter, "Department");
	If FilterDepartment.Count() > 0 Then
		ReportParameters.Insert("Department", FilterDepartment[0].RightValue);
	EndIf;

	VariantKey = SettingsComposer.UserSettings.AdditionalProperties.VariantKey;
	ParameterValue = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("VariantKey"));
	If ParameterValue <> Undefined And ParameterValue.Use And ValueIsFilled(
			ParameterValue.Value) Then
		VariantKey = ParameterValue.Value;
	EndIf;

	If VariantKey = "ByDays" Or VariantKey = "ByShifts" Then
		StandardProcessing = False;
		ReportParameters.Insert("ByDays", ?(VariantKey = "ByDays", True, False));

		ResultDocument.ReadOnly = True;
		ResultDocument.PrintParametersKey = "PRINTPARAMETERS_ShiftScheduleZIK_ShiftScheduleHRPrinting";
		ResultDocument.PageOrientation = PageOrientation.Landscape;

		CompositionTemplate = DataCompositionServer.GetLayoutTemplate(DataCompositionSchema, ReportSettings);

		CompositionProcessor = New DataCompositionProcessor;
		CompositionProcessor.Initialize(CompositionTemplate, , , True);

		MultipleOrganizationsAreUsed = GetFunctionalOption("UseMultipleCompanies");
		If MultipleOrganizationsAreUsed Then
			DataOnTime = New ValueTree;
		Else
			DataOnTime = New ValueTable;
		EndIf;
		OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
		OutputProcessor.SetObject(DataOnTime);

		OutputProcessor.Output(CompositionProcessor, True);
		ReportIsBlank = False;
		If MultipleOrganizationsAreUsed Then
			ReportIsBlank = DataOnTime.Rows.Count() = 0;
		Else
			ReportIsBlank = DataOnTime.Count() = 0;
		EndIf;
		If ReportIsBlank Then
			ErrorText = NStr("ru = 'Не обнаружены данные за выбранный период.
							   |Проверьте наличие документов ""Сменный график"" и заполнение видов времени в выбранных сменах.';
							   |vi = 'No data is found for the selected period.
							   |Check the availability of the ""Shift schedule"" documents and ensure that work time types are filled in for the selected shifts.';
							   |en = 'No data is found for the selected period.
							   |Check the availability of the ""Shift schedule"" documents and ensure that work time types are filled in for the selected shifts.'; fa = 'No data is found for the selected period.
							   |Check the availability of the ""Shift schedule"" documents and ensure that work time types are filled in for the selected shifts.';
							   |it = 'No data is found for the selected period.
							   |Check the availability of the ""Shift schedule"" documents and ensure that work time types are filled in for the selected shifts.';
							   |pl = 'No data is found for the selected period.
							   |Check the availability of the ""Shift schedule"" documents and ensure that work time types are filled in for the selected shifts.';
							   |tr = 'Seçilen dönem için veri bulunamadı. 
							   | ""Vardiyalı program"" belgelerinin varlığını ve seçilen vardiyalardaki zaman türlerinin doldurulup doldurulmadığını kontrol edin.'");
			Raise ErrorText;
		EndIf;

		ResultDocument.ReadOnly = True;
		ResultDocument.PageOrientation = PageOrientation.Landscape;
		ResultDocument.FitToPage = True;
		ResultDocument.PrintParametersKey = "PRINTPARAMETERS_ShiftScheduleZIK_ShiftScheduleHRPrinting";
		Template = PrintManagement.PrintFormTemplate(
			"Document.ShiftScheduleHR.PF_MXL_ShiftScheduleHR");
		ReportParameters.Insert("Template", Template);

		TablePeriods = TimeTrackingServer.CreateSeparatePeriodTable(
			ReportParameters.BeginOfPeriod, ReportParameters.EndOfPeriod);
		ReportParameters.Insert("TablePeriods", TablePeriods);
		ReportParameters.Insert("CurrentSessionDate", CurrentSessionDate());

		If MultipleOrganizationsAreUsed Then

			AccountsOfCompanies = 0;
			For Each OrganizationData_1 In DataOnTime.Rows Do
				AccountsOfCompanies = AccountsOfCompanies + 1;
				ReportParameters.Insert("Organization", OrganizationData_1.Organization);
				CreatePrintedFormOfScheduleForOrganization(OrganizationData_1, ResultDocument, ReportParameters);
				If Not AccountsOfCompanies = DataOnTime.Rows.Count() Then
					ResultDocument.PutHorizontalPageBreak();
				EndIf;
			EndDo;
		Else
			DataOnTime.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
			ReportParameters.Insert("Organization", Catalogs.Companies.EmptyRef());
			CreatePrintedFormOfScheduleForOrganization(DataOnTime, ResultDocument, ReportParameters);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region Private

Procedure CreatePrintedFormOfScheduleForOrganization(DataOnTime, SpreadsheetDocument, ReportParameters)

	ApprovedJobTitle = TimeTrackingServer.DetermineJobTitleOfIndividual(ReportParameters.EmployeeResponsible,
		ReportParameters.Organization, ReportParameters.CurrentSessionDate).Presentation;
	HeaderStructure_ = New Structure("Organization, Department");
	FillPropertyValues(HeaderStructure_, DataOnTime);
	HeaderStructure_.Insert("DocumentNumber", "");
	HeaderStructure_.Insert("DocumentDate", Format(CurrentSessionDate(), "DLF=D"));
	HeaderStructure_.Insert("Organization", ReportParameters.Organization);
	HeaderStructure_.Insert("Department", ReportParameters.Department);
	HeaderStructure_.Insert("Approved_1", PersonsClientServer.InitialsAndLastName(ReportParameters.EmployeeResponsible));
	HeaderStructure_.Insert("ApprovedJobTitle", ApprovedJobTitle);
	HeaderStructure_.Insert("PeriodAsString", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'На период с %1 по %2';
			|vi = 'For period from %1 to %2';
			|en = 'For period from %1 to %2'; fa = 'For period from %1 to %2';
			|it = 'For period from %1 to %2';
			|pl = 'For period from %1 to %2';
			|tr = '%1- %2 dönemi için'"), Format(ReportParameters.BeginOfPeriod, "DLF=D"), Format(
		ReportParameters.EndOfPeriod, "DLF=D")));

	Area = ReportParameters.Template.GetArea("Header");
	FillPropertyValues(Area.Parameters, HeaderStructure_);
	SpreadsheetDocument.Put(Area);

	HeaderStructure_.Insert("Period", EndOfDay(ReportParameters.EndOfPeriod));
	HeaderStructure_.Insert("TablePeriods", ReportParameters.TablePeriods);
	HeaderStructure_.Insert("ByDays", ReportParameters.ByDays);
	HeaderStructure_.Insert("IsReport", True);

	TimeTrackingServer.OutputShiftScheduleDataToTabularDocument(HeaderStructure_, DataOnTime,
		SpreadsheetDocument, ReportParameters.Template);

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