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
	Settings.Events.BeforeLoadVariantAtServer = True;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// Get an external data source
	ConfiguringReportPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportPeriod").Value; //StandardPeriod
	SettingReportFrequency = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	
	If ConfiguringReportPeriod.EndDate > CurrentSessionDate() Then
		EndDate = CurrentSessionDate();
	Else
		EndDate = ConfiguringReportPeriod.EndDate;
	EndIf;
	
	PeriodsTable = TargetValueMonitoring.PeriodsWithEndDate(ConfiguringReportPeriod.StartDate,
		EndDate,
		SettingReportFrequency.Value);
		
	If PeriodsTable.Count() Then
		PeriodsTable[PeriodsTable.Count() - 1].DateOfCalculation = EndDate;
	EndIf;
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("PeriodsTable", PeriodsTable);
	
	// Generate a report
	MainCircuitSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ARAPAccountingServer.DisplayWarningAboutEndOfOfflinePaymentSupport(ResultDocument);
	
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)

	SetReportPeriod(SettingsComposer, UserSettingsModified);
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	
EndProcedure

Procedure SetReportPeriod(Var_SettingsComposer, UserSettingsModified)
	
	ConfiguringReportPeriod = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "ReportPeriod").Value; // StandardPeriod
	If TypeOf(ConfiguringReportPeriod) = Type("StandardPeriod") Then
		If Not ValueIsFilled(ConfiguringReportPeriod.StartDate) Then
			ConfiguringReportPeriod.StartDate = BegOfYear(CurrentSessionDate());
			
			UserSettingsModified = True;
		EndIf;
		If Not ValueIsFilled(ConfiguringReportPeriod.EndDate) Then
			ConfiguringReportPeriod.EndDate = EndOfYear(CurrentSessionDate());
			
			UserSettingsModified = True;
		EndIf;
	Else
		If Not ValueIsFilled(ConfiguringReportPeriod) Then
			PeriodThisYear = New StandardPeriod(StandardPeriodVariant.ThisYear);
			DataCompositionClientServer.SetParameter(Var_SettingsComposer, "ReportPeriod", PeriodThisYear);
			
			UserSettingsModified = True;
		EndIf;
	EndIf;
	
	SettingReportFrequency = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "Periodicity");
	If Not ValueIsFilled(SettingReportFrequency.Value) Then
		DataCompositionClientServer.SetParameter(Var_SettingsComposer, "Periodicity", Enums.Periodicity.Month);
		
		UserSettingsModified = True;
	EndIf;
	
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Organization");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf