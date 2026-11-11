#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	SetValuesForReportParameters(ReportSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - Structure of See ReportsClientServer.DefaultReportSettings.
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean -passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If MonthEndTransactionsServer.ThisFormIsOpenedFromMonthClosingForm(ThisForm) Then
		
		ThisForm.PurposeUseKey = "ContextClosingOfMonth";
		ParametersForm = ThisForm.ParametersForm;
		
		ParametersForm.PurposeUseKey = ThisForm.PurposeUseKey;
		
		ParametersForm.Filter.Clear();
		ParametersForm.Filter.Insert("ReportPeriod", EndOfMonth(Parameters.RegistrationPeriod));
		If Not Parameters.AllCompanies Then
			ParametersForm.Filter.Insert("Organization", Parameters.CompanyArray);
		EndIf;
		
	ElsIf Parameters.Property("CommandParameter") And Parameters.CommandParameter.Count() <> 0 Then
		
		ReserveCalculationDocument = Parameters.CommandParameter[0];
		PaymentAttributes = Common.ObjectAttributesValues(ReserveCalculationDocument, "Date,Organization");
		ParametersForm = ThisForm.ParametersForm;
		ParametersForm.Filter.Clear();
		ParametersForm.Filter.Insert("ReportPeriod", EndOfMonth(PaymentAttributes.Date));
		CompanyArray = New Array;
		CompanyArray.Add(PaymentAttributes.Organization);
		ParametersForm.Filter.Insert("Organization", CompanyArray);
		
	EndIf;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportDataParameter(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetValuesForReportParameters(ReportSettings)
	
	DataParameters = ReportSettings.DataParameters;
	
	DataParameters.SetParameterValue("BatchAccountingVersion22", CalculationOfCostCached.BatchAccountingVersion22());
	DataParameters.SetParameterValue("DateOfMigrationToBatchAccounting22", CalculationOfCostCached.DateOfMigrationToBatchAccounting22());
	
	HouseholdRelocationOperations = CostCalculationAppliedAlgorithms.EconomicOperationsOfMovements();
	DataParameters.SetParameterValue("HouseholdRelocationOperations", HouseholdRelocationOperations);
	
EndProcedure

// Configure the report data parameter.
// 
// Parameters:
//  ReportSettings						- DataCompositionSettings					- the report settings.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//
Procedure ConfigureReportDataParameter(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("ReportData");

	ChoiceList = New ValueList;
	
	If CalculationOfCostCached.CompanyManagementAccounting() Then
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị';
								|ru = 'В валюте упр. учета';
								|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
								|it = 'In valuta della contabilità gestionale';
								|pl = 'W walucie ewidencji zarządczej';
								|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
	EndIf;
		
	ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán tài chính';
							|ru = 'В валюте регл. учета';
							|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
							|it = 'In valuta della contabilità regolamentata';
							|pl = 'W walucie ewidencji reglamentowanej';
							|tr = 'Yerel muhasebe para birimi cinsinden'"));
		
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("ReportData"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf