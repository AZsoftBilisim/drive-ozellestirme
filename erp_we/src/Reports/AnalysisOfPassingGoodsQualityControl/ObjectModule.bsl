#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	QueryText = DataCompositionSchema.DataSets.DataSet.Query;
	QueryTextItemWeight = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"Table.Products.UnitOfMeasure",
		"Table.Products");
		
	QueryTextTheVolumeOfTheItem = Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"Table.Products.UnitOfMeasure",
		"Table.Products");
		
	QueryText = StrReplace(QueryText, "&QueryTextItemWeight", QueryTextItemWeight);
	QueryText = StrReplace(QueryText, "&QueryTextTheVolumeOfTheItem", QueryTextTheVolumeOfTheItem);
	
	TextOfQuantityUnit =
		"CASE
		|	WHEN &QuantityUnits = 0
		|		THEN 1
		|	WHEN &QuantityUnits = 1
		|		THEN
		|			CASE
		|				WHEN Table.Products.UnitFactorForReports <> 0
		|					THEN 1 / Table.Products.UnitFactorForReports
		|				ELSE 0
		|			END
		|END";
	QueryText = StrReplace(QueryText, "&TextOfQuantityUnit", TextOfQuantityUnit);
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
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
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	
EndProcedure

#EndRegion

#Region Private

// Called in the report form handler of the same name after executing the form code.
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;

	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);

EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

#EndRegion

#EndIf