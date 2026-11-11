#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	UserSettingsModified = False;
	StandardProcessing = False;
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	TotalsCurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "TotalCurrency");
	If TotalsCurrencyParameter <> Undefined Then
		If Not ValueIsFilled(TotalsCurrencyParameter.Value) Then
			TotalsCurrencyParameter.Value = Constants.ManagementAccountingCurrency.Get();
		EndIf;
	EndIf;
	
	// We will prepare and output a report.
	TemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionSettings = SettingsComposer.GetSettings();
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(CompositionProcessor, True);
	OutputProcessor.EndOutput();
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#EndIf