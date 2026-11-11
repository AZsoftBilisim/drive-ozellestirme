#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	// Check that at least one report grouping is enabled
	If CompositionTemplate.DataSets.Count() = 0 Then
		Raise NStr("vi = 'Chưa lập báo cáo. Bao gồm ít nhất một gom nhóm trong ""Cấu trúc báo cáo"".';
					|ru = 'Отчет не сформирован. Включите хотя бы одну группировку в ""Структуре отчета"".';
					|en = 'The report is not generated. Enable at least one grouping in the ""Report structure"".'; fa = 'The report is not generated. Enable at least one grouping in the ""Report structure"".';
					|it = 'Report non generato. Includi almeno un raggruppamento in ""Struttura del report"".';
					|pl = 'Raport nie został wygenerowany. Dodaj, co najmniej, jedne grupowanie w ""Strukturze raportu"".';
					|tr = 'Rapor oluşturulmadı. ""Rapor Yapısına"" en az bir gruplandırma dahil edin.'") ;
	EndIf;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	
EndProcedure

#EndRegion

#EndIf