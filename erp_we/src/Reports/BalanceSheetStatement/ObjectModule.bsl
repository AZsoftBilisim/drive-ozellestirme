#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Setting default values
	ConfigureDefaultSelectionParameters(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	// Check that at least one report grouping is enabled
	If CompositionTemplate.DataSets.Count() = 0 Then
		Raise NStr("vi = 'Chưa lập báo cáo. Hãy bật ít nhất một gom nhóm hoặc bảng.';
					|ru = 'Отчет не сформирован. Включите хотя бы одну группировку или таблицу.';
					|en = 'Report is not generated. Enable at least one grouping or table.'; fa = 'Report is not generated. Enable at least one grouping or table.';
					|it = 'Report non generato. Includi almeno un raggruppamento o una tabella.';
					|pl = 'Raport nie został wygenerowany. Dodaj, co najmniej, jedną grupę lub tabelę.';
					|tr = 'Rapor oluşturulmadı. En az bir gruplamayı veya tabloyu dahil edin.'");
	EndIf;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	#Region CheckingReportSRelevance
	Reports.BalanceSheetStatement.DisplayReportRelevance(ReportSettings, ResultDocument);
	#EndRegion

	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	PeriodicityParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	If Not ValueIsFilled(PeriodicityParameter.Value)
		Or TypeOf(PeriodicityParameter.Value) = Type("String") Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "Periodicity", Enums.Periodicity.Month);
		UserSettingsModified = True;
	EndIf;
	
	DataCompositionServer.SetUpDynamicPeriod(DataCompositionSchema, SettingsComposer);
	
	PeriodicityParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	SearchField = DataCompositionSchema.CalculatedFields.Find("DynamicPeriod");
	SearchField.Expression = FinancialReportingClientServer.PeriodStrings(PeriodicityParameter.Value).Period;
	SearchField.PresentationExpression = "FinancialReportingServer.IntervalPresentation("+SearchField.Expression+",&Periodicity)";
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "Tab", Chars.Tab);
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	ParameterCurrencyOfManagementAccounting = DataCompositionClientServer.GetParameter(SettingsComposer, "ManagementAccountingCurrency");
	If ParameterCurrencyOfManagementAccounting <> Undefined 
		And Not (ValueIsFilled(ParameterCurrencyOfManagementAccounting.Value)
			Or TypeOf(ParameterCurrencyOfManagementAccounting.Value) = Type("String")) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ManagementAccountingCurrency", ManagementAccountingCurrency);
		
		UserSettingsModified = True;
	EndIf;
	
	ReportCurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportCurrency");
	If ReportCurrencyParameter <> Undefined 
		And (Not ValueIsFilled(ReportCurrencyParameter.Value)
			Or TypeOf(ReportCurrencyParameter.Value) = Type("String")) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ReportCurrency", ManagementAccountingCurrency);
		
		UserSettingsModified = True;
	EndIf;
	
	GroupParameterAP = DataCompositionClientServer.GetParameter(SettingsComposer, "GroupByAssetsLiabilities");
	If SettingsComposer.Settings.Structure.Count() > 0 Then
		Table = SettingsComposer.Settings.Structure[0];
		If TypeOf(Table) = Type("DataCompositionTable") Then
			If Table.Name = "ByPeriods" Or Table.Name = "ByDirections" Or Table.Name = "ByCompanies" Then
				TableRows = SettingsComposer.Settings.Structure[0].Rows;
				MetricTypeGrouping = FinancialReportingServer.FindGroup1(TableRows, "IndicatorType");
				GroupingIndicator = FinancialReportingServer.FindGroup1(TableRows, "Factor");
				If MetricTypeGrouping <> Undefined And GroupingIndicator <> Undefined Then
					MetricTypeGrouping.Use = GroupParameterAP.Value;
					GroupingIndicator.Use = Not GroupParameterAP.Value;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("Periodicity");
	AuxiliaryParameters.Add("DisplayTurnoverByArticle_");
	AuxiliaryParameters.Add("GroupByAssetsLiabilities");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;
EndFunction

Procedure ConfigureDefaultSelectionParameters(FormSettingsComposer, UserSettings = False)
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	Parameter = ParameterSetting(FormSettingsComposer, "ReportCurrency", UserSettings);
	If Parameter <> Undefined Then
		Parameter.Use = True;
		If Not ValueIsFilled(Parameter.Value) Then
			Parameter.Value = ManagementAccountingCurrency;
		EndIf;
	EndIf;
	
EndProcedure


// LongDesc
// 
// Parameters:
// 	FormSettingsComposer - DataCompositionSettingsComposer - 
// 	ParameterName - String - LongDesc
// 	Custom - Boolean - LongDesc
// Returns:
// 	Undefined, DataCompositionParameter - LongDesc
//
Function ParameterSetting(FormSettingsComposer, ParameterName, Custom = False)
	
	DataParameter = FormSettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		CustomSettingParameter = FormSettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If Custom And CustomSettingParameter <> Undefined Then
			Return CustomSettingParameter;
		Else
			Return DataParameter;
		EndIf;
	EndIf;
	Return Undefined;
	
EndFunction

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandParameter;
		ThisForm.ParametersForm.Filter.Insert("Factor", Parameters.CommandParameter);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf