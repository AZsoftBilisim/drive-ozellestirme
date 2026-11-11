#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	ReportParameters = GetReportParameters(ReportSettings);
	
	If Not ValueIsFilled(ReportParameters.Rule) Then
		Return;
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	CreateTemporaryTableForDCS(TempTablesManager, ReportParameters);
	
	// Let's compose and output the query result into a tabular document
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData,,, TempTablesManager);

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
	
	If Parameters.Property("CommandParameter") And Parameters.CommandParameter.Count() <> 0 Then
		
		Rule = Parameters.CommandParameter[0];
		ParametersForm = ThisForm.ParametersForm;
		ParametersForm.Filter.Clear();
		ParametersForm.Filter.Insert("Rule", Rule);
		
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

Function GetReportParameters(ReportSettings)
	
	ParametersStructure = New Structure("Rule,Period");
	
	DataParameters = ReportSettings.DataParameters;
	RuleParameter = DataParameters.FindParameterValue(New DataCompositionParameter("Rule"));
	PeriodParameter = DataParameters.FindParameterValue(New DataCompositionParameter("ReportPeriod"));
	
	If Not ValueIsFilled(RuleParameter.Value) Then
		ParametersStructure.Rule = PredefinedValue("Catalog.RulesForCalculationOfInventoryImpairmentProvision.EmptyRef");
	Else
		ParametersStructure.Rule = RuleParameter.Value;
	EndIf;
	
	If Not ValueIsFilled(PeriodParameter.Value) Then
		ParametersStructure.Period = New Boundary(EndOfMonth(CurrentSessionDate()), BoundaryType.Including);
	Else
		ParametersStructure.Period = New Boundary(EndOfMonth(PeriodParameter.Value), BoundaryType.Including);
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

Procedure CreateTemporaryTableForDCS(TempTablesManager, ReportParameters)

	ReportParameters.Insert("BatchAccountingVersion22", CalculationOfCostCached.BatchAccountingVersion22());
	ReportParameters.Insert("DateOfMigrationToBatchAccounting22", CalculationOfCostCached.DateOfMigrationToBatchAccounting22());
	TableOfReserves = Catalogs.RulesForCalculationOfInventoryImpairmentProvision.CreateTableOfBalancesAccordingToRule(ReportParameters.Rule, False, ReportParameters);
	
	PutParameters = New Structure;
	PutParameters.Insert("TempTableName", "BalanceTable");
	PutParameters.Insert("CalculationOfReserves", True);
	Catalogs.RulesForCalculationOfInventoryImpairmentProvision.PutTableOfBalancesInTemporaryTable(TableOfReserves, TempTablesManager, PutParameters);
	
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
		
	ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán pháp quy';
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
