#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	ExternalSets = New Structure;
	
	Reports.DemandForMaterialsAccordingToProductionScheduleModel.ConfigureDatasets(
		DataCompositionSchema, ReportSettings, ExternalSets);
	
	// Layout and output.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Function ParameterizableFieldHeaders()
	
	FieldHeaders = New Map;
	
	WeightUnit = String(Constants.UnitOfMeasureForWeight.Get());
	VolumeUnit = String(Constants.UnitOfMeasureForVolume.Get());
	
	QuantityUnitParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "QuantityUnits");
	
	If QuantityUnitParameter <> Undefined
		And QuantityUnitParameter.Value = 0 Then
		TitleEd = NStr("vi = 'Tổng số nguyên vật liệu theo đơn vị lưu kho';
						|ru = 'Итого материалов в единицах хранения';
						|en = 'Total materials in stock UOM'; fa = 'Total materials in stock UOM';
						|it = 'Totali dei materiali in unità di stoccaggio';
						|pl = 'Łącznie materiałów w jednostkach przechowywania';
						|tr = 'Stok ölçü birimlerindeki toplam malzemeler'");
	Else
		TitleEd = NStr("vi = 'Tổng số nguyên vật liệu theo đơn vị báo cáo';
						|ru = 'Итого материалов в единицах для отчетов';
						|en = 'Total materials in units for reports'; fa = 'Total materials in units for reports';
						|it = 'Totale dei materiali in unità di misura per il report';
						|pl = 'Łącznie materiałów w jednostkach dla raportów';
						|tr = 'Rapor birimlerindeki toplam malzemeler'");
	EndIf;
	
	FieldHeaders.Insert("12", WeightUnit); // WeightUnit
	FieldHeaders.Insert("13", VolumeUnit); // VolumeUnit
	FieldHeaders.Insert("11", TitleEd); // HeadingOfEDDimension
	
	Return FieldHeaders;
	
EndFunction

#EndRegion

#EndIf
