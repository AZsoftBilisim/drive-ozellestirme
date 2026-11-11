#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	FilterProducts = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Products").Value;
	FilterSeries = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Series").Value;
	
	If Not ValueIsFilled(FilterProducts)
		And Not ValueIsFilled(FilterSeries) Then
		
		MessageText = NStr("vi = 'Hãy thiết lập bộ lọc theo mặt hàng hoặc sê-ri.';
							|ru = 'Установите отбор по номенклатуре или серии.';
							|en = 'Set the filter by item or batch.'; fa = 'Set the filter by item or batch.';
							|it = 'Set the filter by item or batch.';
							|pl = 'Set the filter by item or batch.';
							|tr = 'Filtreyi öğeye veya partiye göre ayarlayın.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#EndIf