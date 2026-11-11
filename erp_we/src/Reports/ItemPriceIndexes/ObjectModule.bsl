#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the layout for the transmitted series
// 
// Parameters:
//	Series - ChartSeries - changeable chart series.
//
Procedure InstallExtendedSeriesDesign(Series) Export
	
	If StrFind(Series.Text, NStr("vi = 'Chỉ mục đơn giá bán';
								|ru = 'Индекс цены продажи';
								|en = 'Selling price index'; fa = 'Selling price index';
								|it = 'Indice prezzi di vendita';
								|pl = 'Indeks ceny sprzedaży';
								|tr = 'Satış fiyat endeksi'")) Then
		Series.Line = New Line(ChartLineType.Dashed, 2);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	SetPrivilegedMode(True);
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);

	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument, ChartParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	DataCompositionServer.SetUpDynamicPeriod(DataCompositionSchema, SettingsComposer, True);
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

Function ChartParameters()
	
	// Redefine and add chart parameters
	ChartParameters = DataCompositionServer.ChartParameters(SettingsComposer);
	
	ChartParameters.Insert("Report", ThisObject);
	ChartParameters.Insert("ExtendedSeriesDesign", True);
	
	Return ChartParameters;
	
EndFunction

#EndRegion

#EndIf