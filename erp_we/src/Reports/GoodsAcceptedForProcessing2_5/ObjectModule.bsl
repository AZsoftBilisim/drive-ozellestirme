#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer	= New DataCompositionTemplateComposer;
	ReportSettings		= SettingsComposer.GetSettings();
	CompositionTemplate		= TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(FieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema,
																SettingsComposer,
																ResultDocument,
																AuxiliaryReportParameters());
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//	Form - ClientApplicationForm - report form.
//	VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//	Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer.
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

#EndRegion

#Region Private

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

Function FieldHeaders()
	
	Return DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	
EndFunction

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

#EndRegion

#EndIf