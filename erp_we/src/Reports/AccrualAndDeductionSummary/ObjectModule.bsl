#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
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
	
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion 

#Region Private

// Defines the settings of the report Form "Analysis of Accruals and HR Deductions" for the "Report Options" subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - Report form
//   VariantKey - String - Report variant key
//   Settings - Structure - Report Form Settings
// For the general Form "Report Form" of the subsystem "Report Options".
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

#EndRegion

#EndIf
