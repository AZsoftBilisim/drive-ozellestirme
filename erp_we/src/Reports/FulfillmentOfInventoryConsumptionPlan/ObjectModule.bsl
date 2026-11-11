#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	ScenarioParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Scenario");
	
	If Not ValueIsFilled(ScenarioParameter.Value) Then
		Raise NStr("vi = 'Chưa điền giá trị tham số ""Kịch bản"".';
					|ru = 'Не заполнено значение параметра ""Сценарий"".';
					|en = 'Parameter ""Scenario"" is not filled in.'; fa = 'Parameter ""Scenario"" is not filled in.';
					|it = 'Il valore del parametro ""Scenario"" non è compilato.';
					|pl = 'Wartość parametru ""Scenariusz"" nie jest wypełniona.';
					|tr = '""Senaryo"" parametresinin değeri doldurulmamış.'");
	EndIf;
	
	StructureOfValues = Common.ObjectAttributesValues(ScenarioParameter.Value, "Periodicity, PlanningByAssignments");
	Periodicity = StructureOfValues.Periodicity;
	SpecifyTargets = StructureOfValues.PlanningByAssignments;
	DataCompositionClientServer.SetParameter(SettingsComposer, "SpecifyTargets", SpecifyTargets);
	
	Period = DataCompositionClientServer.GetParameter(SettingsComposer, "ConsumptionPeriod").Value; // StandardPeriod - 
	
	EndDate = PlanningClientServer.CalculatePeriodEndDate(Period.StartDate, Periodicity);
	
	If EndDate < Period.EndDate Then
		UseTotals = True;
	Else
		UseTotals = False;
	EndIf;
	
	For Each Group In SettingsComposer.Settings.Structure Do
		SetOtherSettings(Group, UseTotals);
	EndDo;

	NestedSchemaByDivision = DataCompositionSchema.NestedDataCompositionSchema.ByBusinessUnits; //NestedDataCompositionSchema -
	QueryText = NestedSchemaByDivision.Schema.DataSets.DataSet1.Query;
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"DomesticConsumptionPlanFact.Products.UnitOfMeasure", "DomesticConsumptionPlanFact.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"DomesticConsumptionPlanFact.Products.UnitOfMeasure", "DomesticConsumptionPlanFact.Products"));

	NestedSchemaByDivision.Schema.DataSets.DataSet1.Query = ProcessRequest(QueryText);

	NestedSchemaForWarehouses = DataCompositionSchema.NestedDataCompositionSchema.ByWarehouses; //NestedDataCompositionSchema -
	QueryText = NestedSchemaForWarehouses.Schema.DataSets.DataSet1.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"DomesticConsumptionPlanFact.Products.UnitOfMeasure", "DomesticConsumptionPlanFact.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"DomesticConsumptionPlanFact.Products.UnitOfMeasure", "DomesticConsumptionPlanFact.Products"));

	NestedSchemaForWarehouses.Schema.DataSets.DataSet1.Query = ProcessRequest(QueryText);

	Planning.ExecutionOfPlansInLayoutOfResult(DataCompositionSchema, SettingsComposer, 
		ResultDocument, DetailsData, StandardProcessing);

	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CollectionOfStructureElements = ReportSettings.Structure[0].Settings.Structure;
	
	If TypeOf(CollectionOfStructureElements[0]) = Type("DataCompositionTable") Then
		
		If CollectionOfStructureElements[0].Columns[0].Name = "Details" Then
			StructureElementName = CollectionOfStructureElements[0].Columns[0].Name;
			StructureElementGroupingField = CollectionOfStructureElements[0].Columns[0].GroupFields.Items[0].Field;
		Else
			StructureElementName = CollectionOfStructureElements[0].Rows[0].Name;
			StructureElementGroupingField = CollectionOfStructureElements[0].Rows[0].GroupFields.Items[0].Field;
		EndIf;
		
	Else
		
		StructureElementName = CollectionOfStructureElements[0].Name;
		StructureElementGroupingField = CollectionOfStructureElements[0].GroupFields.Items[0].Field;
		
	EndIf;
	
	// Redefining the structure of the report when decrypting by the Registrar field
	If StructureElementName = "Details" Then
		
		LoggerField_ = New DataCompositionField("Recorder");
		
		If StructureElementGroupingField = LoggerField_ Then
			
			Planning.OverrideReportDecryptionSettings(DataCompositionSchema, SettingsComposer, DetailsData);
			
			ReportSettings = DetailsData.Settings;
			CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
			
		EndIf;
	EndIf;

	FieldHeaders_ = ParameterizableFieldHeaders();
	
	DataCompositionServer.SetLayoutTemplateHeaders(FieldHeaders_, CompositionTemplate);
	
	For Each Template In CompositionTemplate.Body Do
		If TypeOf(Template) = Type("DataCompositionTemplateNestedObject") Then
			DataCompositionServer.SetLayoutTemplateHeaders(FieldHeaders_, Template.DataComposition);
		EndIf;
	EndDo;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Planning.ExecutionOfPlansProcessingFillInChecks(SettingsComposer, Cancel);
	
EndProcedure

#EndRegion

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
	Settings.Events.OnLoadVariantAtServer = True;
	
EndProcedure

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
	
	// Additional command
	ReportSettings = ThisForm.ReportSettings;
	
	If Parameters.Property("Details")
	   And Parameters.Details <> Undefined Then
		
		// Correction of the report version during decryption
		If IsTempStorageURL(Parameters.Details.Data) Then
			
			DetailsData = GetFromTempStorage(Parameters.Details.Data);
			
			If Parameters.Property("VariantKey") And Parameters.VariantKey = Undefined Then
				Parameters.VariantKey = DetailsData.Settings.AdditionalProperties.VariantKey;
			EndIf;
			
			ThisForm.CurrentVariantKey = DetailsData.Settings.AdditionalProperties.VariantKey;
			
		EndIf;
		
		ReportSettings.OptionRef = ReportsOptions.ReportVariant(ReportSettings.ReportRef, ThisForm.CurrentVariantKey);
		
	EndIf;
	
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

// Called in the report form handler of the same name after executing the form code.
//
//  See Synthax -assistant "Extension of the managed form for the report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Parameters = ThisForm["Parameters"];
	
	If Parameters.Property("Details")
	   And Parameters.Details <> Undefined Then
		
		If IsTempStorageURL(Parameters.Details.Data) Then
			
			PermissibleDeviationsOfQuantity = DataCompositionClientServer.GetParameter(SettingsComposer, "AcceptableDeviationsPercentage");
			If PermissibleDeviationsOfQuantity <> Undefined Then
				PermissibleDeviationsOfQuantity.Use = False;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetOtherSettings(NestedReport, UseTotals)
	
	Parameter = New DataCompositionParameter("HorizontalOverallPlacement");
	ParameterHorizontalArrangementOfTotals = NestedReport.Settings.OutputParameters.Items.Find(Parameter);
	
	If UseTotals Then
		ParameterHorizontalArrangementOfTotals.Value = DataCompositionTotalPlacement.End;
	Else
		ParameterHorizontalArrangementOfTotals.Value = DataCompositionTotalPlacement.None;
	EndIf;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(NestedReport);
	
EndProcedure

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

Function ProcessRequest(QueryText)
	
	Return StrReplace(
				QueryText,
				"DomesticConsumptionPlanFact.Products.UnitOfMeasure",
				"CAST(DomesticConsumptionPlanFact.Products.UnitOfMeasure AS Catalog.PackagesAndUnitsOfMeasure)");
	
EndFunction

#EndRegion

#EndIf