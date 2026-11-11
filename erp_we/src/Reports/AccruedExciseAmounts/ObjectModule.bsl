#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	// Disable standard processing, because we will generate the report "manually".
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	DataSelectionValues = GetDataSelectionValues(ReportSettings);
	Reports.AccruedExciseAmounts.AddInformationalMessageToHeader(ResultDocument, DataSelectionValues);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Function GetDataSelectionValues(MainCircuitSettings)

	FilterItems1 = MainCircuitSettings.Filter.Items;
	
	DataSelectionValues = New Structure("CompaniesList, Period");
	
	DataSelectionValues.CompaniesList = TMReportsServer.FilterValue("Organization", FilterItems1);
	Period = TMReportsServer.ParameterValue(MainCircuitSettings, "EndOfPeriod");
	DataSelectionValues.Period = ?(ValueIsFilled(Period), Period, '00010101');
	
	Return DataSelectionValues;
	
EndFunction

#EndRegion

#EndIf