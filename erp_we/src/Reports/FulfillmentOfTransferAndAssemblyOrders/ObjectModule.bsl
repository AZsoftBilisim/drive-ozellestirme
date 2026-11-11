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
	
	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.DataSet1.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("Table.Products.UnitOfMeasure", "Table.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("Table.Products.UnitOfMeasure", "Table.Products"));

	DataCompositionSchema.DataSets.DataSet1.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(
		DataCompositionServer.UnitFieldHeaders(SettingsComposer), CompositionTemplate);
	
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

#Region Private
	
Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "SourceWarehouse");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "DestinationWarehouse");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf