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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	// Checking for the correctness of user-defined periods
	ConfiguringReportPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportPeriod");
	SettingReportPeriodValue = ConfiguringReportPeriod.Value; // StandardPeriod
	ConfiguringStepByStepReportComparison = DataCompositionClientServer.GetParameter(SettingsComposer, "ComparisonPeriodStep");	
	If ValueIsFilled(SettingReportPeriodValue) 
		And ValueIsFilled(ConfiguringStepByStepReportComparison.Value) Then
		If Not PeriodSettingIsSetCorrectly(SettingReportPeriodValue.StartDate,
			SettingReportPeriodValue.EndDate,
			ConfiguringStepByStepReportComparison.Value) Then
			
			CommonClientServer.MessageToUser(NStr("vi = 'Thời lượng các bước trong kỳ so sánh không được nhỏ hơn kỳ báo cáo.';
													|ru = 'Длительность шага периодов сравнения не должна быть меньше периода отчета.';
													|en = 'Length of the comparison period step should not be less than the report period.'; fa = 'Length of the comparison period step should not be less than the report period.';
													|it = 'La durata della fase dei periodi di confronto non deve essere inferiore al periodo del report';
													|pl = 'Czas trwania okresów porównywania nie powinien być krótszy, niż okres raportu.';
													|tr = 'Karşılaştırma dönemlerinin adım uzunluğu raporlama döneminden daha kısa olmamalıdır.'"), , , , Cancel);
		EndIf;
	EndIf;
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// Get an external data source
	ConfiguringReportPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportPeriod");
	SettingReportPeriodValue = ConfiguringReportPeriod.Value; // StandardPeriod
	ConfiguringStepByStepReportComparison = DataCompositionClientServer.GetParameter(SettingsComposer, "ComparisonPeriodStep");
	SettingNumberOfReportPeriods = DataCompositionClientServer.GetParameter(SettingsComposer, "NumberOfPeriods");
	
	PeriodsTable = TargetValueMonitoring.PeriodsComparedToSimilarPeriodsInPast(
		SettingReportPeriodValue.StartDate,
		SettingReportPeriodValue.EndDate,
		ConfiguringStepByStepReportComparison.Value,
		SettingNumberOfReportPeriods.Value);
	
	If PeriodsTable.Count() Then
		Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "StartingYear");
		Parameter.Value = Year(PeriodsTable[PeriodsTable.Count()-1].SettlementStartDate);
		Parameter.Use = True;
		
		Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportPeriodStartDate");
		Parameter.Value = PeriodsTable[0].SettlementStartDate;
		Parameter.Use = True;
	EndIf;
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("PeriodsTable", PeriodsTable);
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	// Add periods
	AddPeriodsParameter = MainCircuitSettings.DataParameters.Items.Find("AddPeriods");
	If AddPeriodsParameter <> Undefined
		And AddPeriodsParameter.Value Then
		
		LayoutParameterStepOfComparisonPeriods = MainCircuitSettings.DataParameters.Items.Find("ComparisonPeriodStep");
		If LayoutParameterStepOfComparisonPeriods <> Undefined Then
			ComparisonPeriodStep = LayoutParameterStepOfComparisonPeriods.Value;
		Else
			ComparisonPeriodStep = Enums.Periodicity.Year;
		EndIf;
		
		If ComparisonPeriodStep = Undefined 
			Or ComparisonPeriodStep = Enums.Periodicity.EmptyRef() Then
			ExtensionPeriodName = "Year";
		Else
			ExtensionPeriodName = Common.EnumerationValueName(ComparisonPeriodStep);
		EndIf;
		
		PeriodAddition = DataCompositionPeriodAdditionType[ExtensionPeriodName];
		
		GroupingCalculationStartDate = MainCircuitSettings.GroupAvailableFields.Items.Find("SettlementStartDate");
		If GroupingCalculationStartDate <> Undefined Then
			ReportDimensions = DataCompositionClientServer.GetGroupings(MainCircuitSettings);
			For Each ReportGrouping In ReportDimensions Do
				GroupFields = ReportGrouping.Value.GroupFields; // DataCompositionGroupFields
				If GroupFields.Items.Count() = 1
					And GroupFields.Items[0].Field = GroupingCalculationStartDate.Field Then
					GroupingForAdditions = GroupFields.Items[0];
					GroupingForAdditions.AdditionType = PeriodAddition;
					GroupingForAdditions.BeginOfPeriod = PeriodsTable[PeriodsTable.Count()-1].SettlementStartDate;
					GroupingForAdditions.EndOfPeriod = PeriodsTable[0].SettlementEndDate;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	QueryText = DataCompositionSchema.DataSets.Sales.Query;

	QueryText = StrReplace(
		QueryText,
		"&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"RevenueAndCOGS.ItemsLocationAttributes.Products.UnitOfMeasure", 
			"RevenueAndCOGS.ItemsLocationAttributes.Products"));
		
	QueryText = StrReplace(
		QueryText,
		"&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"RevenueAndCOGS.ItemsLocationAttributes.Products.UnitOfMeasure", 
			"RevenueAndCOGS.ItemsLocationAttributes.Products"));

	DataCompositionSchema.DataSets.Sales.Query = QueryText;
	
	// Generate a report
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfFieldHeaders(), CompositionTemplate);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument);
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)

	// Fill in the period settings
	ConfiguringReportPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportPeriod");
	If Not ValueIsFilled(ConfiguringReportPeriod.Value) Then
		StandardPeriodYear = New StandardPeriod(StandardPeriodVariant.ThisYear);
		DataCompositionClientServer.SetParameter(SettingsComposer, "ReportPeriod", StandardPeriodYear);
		
		UserSettingsModified = True;
	EndIf;
	
	ConfiguringStepByStepReportComparison = DataCompositionClientServer.GetParameter(SettingsComposer, "ComparisonPeriodStep");
	If Not ValueIsFilled(ConfiguringStepByStepReportComparison.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ComparisonPeriodStep", Enums.Periodicity.Year);
		
		UserSettingsModified = True;
	EndIf;
	
	SettingNumberOfReportPeriods = DataCompositionClientServer.GetParameter(SettingsComposer, "NumberOfPeriods");
	If Not ValueIsFilled(SettingNumberOfReportPeriods.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "NumberOfPeriods", 3);
		
		UserSettingsModified = True;
	EndIf;
	
	ShowSalesParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ShowSales_");
	If ShowSalesParameter <> Undefined 
		And ShowSalesParameter.Value = Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ShowSales_", 1);
		
		UserSettingsModified = True;
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Function AddPeriod(LayoutStructure_, ExtensionField)
	For Each StructureItem In LayoutStructure_ Do
		If TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			If StructureItem.GroupFields.Items.Count() = 1
				And StructureItem.GroupFields.Items[0].Field = ExtensionField Then
				
				Item = StructureItem.GroupFields.Items[0];
			EndIf;
			
			AddPeriod(StructureItem.Structure, ExtensionField);
		EndIf;
	EndDo;
EndFunction

Function PeriodSettingIsSetCorrectly(StartDate, EndDate, Periodicity)
	
	SecondsPerMinute = 60;
	MinutesPerHour = 60;
	HoursPerDay = 24;
	DaysPerWeek = 7;
	DaysInDecade = 10;
	DaysPerMonth = 31;
	DaysPerQuarter = 92;
	DaysInHalfYear = 184;
	DaysYear = 366;
	
	Number_Of_DaysInPeriod = (EndDate + 1 - StartDate) / (SecondsPerMinute * MinutesPerHour * HoursPerDay);
	
	If Periodicity = Enums.Periodicity.Year Then
		Return Number_Of_DaysInPeriod <= DaysYear;
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Return Number_Of_DaysInPeriod <= DaysInHalfYear;
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Return Number_Of_DaysInPeriod <= DaysPerQuarter;
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Return Number_Of_DaysInPeriod <= DaysPerMonth;
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		Return Number_Of_DaysInPeriod <= DaysInDecade;
	ElsIf Periodicity = Enums.Periodicity.Week Then
		Return Number_Of_DaysInPeriod <= DaysPerWeek;
	ElsIf Periodicity = Enums.Periodicity.Day Then
		Return Number_Of_DaysInPeriod <= 1;
	Else
		Return False;
	EndIf;
	
EndFunction

Function StructureOfFieldHeaders()
	StructureOfFieldHeaders = New Structure;
	
	StructureOfUnitFieldHeaders_ = DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	CommonClientServer.SupplementStructure(StructureOfFieldHeaders, StructureOfUnitFieldHeaders_, False);
	
	Return StructureOfFieldHeaders;
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Organization");
	EndIf;
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf