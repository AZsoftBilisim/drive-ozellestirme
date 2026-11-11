
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	// Configuring the report.
	ExternalSets = New Structure;
	FillExternalSets(ReportSettings, ExternalSets);
	
	// Layout and output.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillExternalSets(ReportSettings, ExternalSets)
	
	LayoutParameter = New DataCompositionParameter("ReferenceOrder");
	ParameterValue = ReportSettings.DataParameters.FindParameterValue(LayoutParameter);
	If ParameterValue = Undefined Then
		Raise NStr("vi = 'Thiếu tham số ""Lệnh""';
					|ru = 'Отсутствует обязательный параметр ""Распоряжение""';
					|en = 'Missing required parameter: ""Reference""'; fa = 'Missing required parameter: ""Reference""';
					|it = 'Opzione obbligatoria ""Disposizione"" mancante';
					|pl = 'Brak wymaganego parametru ""Zamówienie""';
					|tr = 'Zorunlu ""Talimat"" parametresi bulunmamaktadır'");
	EndIf;
	ReferenceOrder = ParameterValue.Value;
	Data = Reports.EquipmentLoadAccordingToProductionScheduleModel.LoadingByModelAndIntervalFormat(ReferenceOrder);
	
	ExternalSets.Insert("LoadingEquipment", Data.LoadingEquipment);
	
	CustomizeAppearanceOfIntervalField(ReportSettings, Data.IntervalFormat);
	
EndProcedure

Procedure CustomizeAppearanceOfIntervalField(ReportSettings, Format)
	
	Item = ReportSettings.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Interval");
	
	Item.Appearance.SetParameterValue("Format", Format);
	
EndProcedure

#EndRegion

#EndIf