#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	UserSettingsModified = False;

	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.GoodsRegisteredRecords.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageWeight1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("ProductsInTurnoverCells.Package", "ProductsInTurnoverCells.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageVolume1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("ProductsInTurnoverCells.Package", "ProductsInTurnoverCells.Products"));

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageWeight2", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("RecalculationOfGoods.Package", "RecalculationOfGoods.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackageVolume2", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("RecalculationOfGoods.Package", "RecalculationOfGoods.Products"));

	DataCompositionSchema.DataSets.GoodsRegisteredRecords.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "ParameterOperationKindAcceptance", NStr("vi = 'Nhập kho';
																										|ru = 'Приемка';
																										|en = 'Receiving'; fa = 'دریافت';
																										|it = 'Accettazione';
																										|pl = 'Receiving';
																										|tr = 'Kabul'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "ParameterOperationKindControl", NStr("vi = 'Kiểm soát';
																									|ru = 'Контроль';
																									|en = 'Control'; fa = 'کنترل';
																									|it = 'Controllo';
																									|pl = 'Control';
																									|tr = 'Kontrol'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "ParameterOperationKindRecalculation", NStr("vi = 'Tính lại';
																											|ru = 'Пересчет';
																											|en = 'Recalculate'; fa = 'محاسبه مجدد';
																											|it = 'Ricalcolo';
																											|pl = 'Recalculate';
																											|tr = 'Yeniden hesaplama'"));
	
EndProcedure

#EndRegion

#Region Private

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

#EndRegion

#EndIf