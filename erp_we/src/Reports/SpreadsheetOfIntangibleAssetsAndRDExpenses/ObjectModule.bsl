
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	SetReportParameters(MainCircuitSettings);
	
	ImpairmentFAServer.EstablishVisibilityOfImpairmentDataInReport(MainCircuitSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);	
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, Undefined, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);	
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	CreateReportHeader(ResultDocument);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure - may contain properties:
//				** CommandParameter - CatalogRef.IntangibleAssets -
//				** CommandDetails - Structure - may contain properties:
//					*** AdditionalParameters - Structure - 
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		Parameters.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		
		If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.IntangibleAssets") Then
			ThisForm.ParametersForm.Filter.Insert("IntangibleAsset", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region ReportGeneration
 
Procedure CreateReportHeader(TabDoc)
	
	ListOfCellGroups = New Array;
	ListOfCellGroups.Add(NStr("vi = 'Chỉ tiêu';
								|ru = 'Показатели';
								|en = 'Indicators'; fa = 'شاخص‌ها';
								|it = 'Indici';
								|pl = 'Indicators';
								|tr = 'Göstergeler'"));
	ListOfCellGroups.Add(NStr("vi = 'Ngày chấp nhận';
								|ru = 'Дата принятия к учету';
								|en = 'Date of recognition'; fa = 'تاریخ شناسایی';
								|it = 'Data di accettazione';
								|pl = 'Data przyjęcia do ewidencji';
								|tr = 'Muhasebeleştirme tarihi'"));
	ListOfCellGroups.Add(NStr("vi = 'Nguyên giá';
								|ru = 'Первоначальная стоимость';
								|en = 'Initial cost'; fa = 'بهای تمام‌شده اولیه';
								|it = 'Costo iniziale';
								|pl = 'Wartość początkowa';
								|tr = 'Başlangıç değeri'"));
	
	ListOfCellGroups.Add(NStr("vi = 'Giá trị';
								|ru = 'Стоимость';
								|en = 'Cost'; fa = 'بهای تمام‌شده';
								|it = 'Costo';
								|pl = 'Wartość';
								|tr = 'Maliyet'"));
	ListOfCellGroups.Add(NStr("vi = 'Khấu hao';
								|ru = 'Амортизация';
								|en = 'Amortization'; fa = 'استهلاک دارایی نامشهود';
								|it = 'Ammortamento';
								|pl = 'Amortyzacja';
								|tr = 'Amortisman'"));
	ListOfCellGroups.Add(NStr("vi = 'Giá trị còn lại';
								|ru = 'Остаточная стоимость';
								|en = 'Net book value'; fa = 'ارزش دفتری خالص';
								|it = 'Il valore residuo';
								|pl = 'Wartość rezydualna';
								|tr = 'Net defter değeri'"));
	
	ListOfCellGroups.Add(NStr("vi = 'Tăng giá trị';
								|ru = 'Увеличение стоимости';
								|en = 'Cost increase'; fa = 'افزایش بهای تمام‌شده';
								|it = 'Aumento del prezzo';
								|pl = 'Wzrost wartości';
								|tr = 'Maliyet artışı'"));
	ListOfCellGroups.Add(NStr("vi = 'Tính khấu hao';
								|ru = 'Начисление амортизации';
								|en = 'Amortization charge'; fa = 'محاسبه استهلاک دارایی نامشهود';
								|it = 'Ammortamento maturato';
								|pl = 'Naliczanie amortyzacji';
								|tr = 'Amortisman tahakkuku'"));
	ListOfCellGroups.Add(NStr("vi = 'Giảm giá trị';
								|ru = 'Уменьшение стоимости';
								|en = 'Cost reduction'; fa = 'Cost reduction';
								|it = 'Diminuzione del prezzo';
								|pl = 'Zmniejszenie kosztów';
								|tr = 'Maliyet düşüşü'"));
	ListOfCellGroups.Add(NStr("vi = 'Ghi giảm khấu hao';
								|ru = 'Списание амортизации';
								|en = 'Amortization write-off'; fa = 'برگشت استهلاک دارایی نامشهود';
								|it = 'Cancellazione dell''ammortamento';
								|pl = 'Spisanie amortyzacji';
								|tr = 'Amortisman gider yazılması'"));
	
	ListOfCellGroups.Add(NStr("vi = 'Giảm giá';
								|ru = 'Обесценение';
								|en = 'Impairment'; fa = 'کاهش ارزش';
								|it = 'Svalutazione';
								|pl = 'Utrata wartości';
								|tr = 'Değer kaybı'"));
	
	ListOfSubordinateCells = New Array;
	ListOfSubordinateCells.Add(NStr("vi = 'KTDN';
									|ru = 'БУ';
									|en = 'LA'; fa = 'محلی';
									|it = 'Contabilità civilistica';
									|pl = 'EK';
									|tr = 'Genel Muhasebe'"));
	ListOfSubordinateCells.Add(NStr("vi = 'QT';
									|ru = 'УУ';
									|en = 'MA'; fa = 'مدیریت';
									|it = 'Contabilità Gestionale';
									|pl = 'EZ';
									|tr = 'Yönetim Muhasebesi'"));
	
	NonCurrentAssetsInternal.MergeSubordinateCells(TabDoc, ListOfCellGroups, ListOfSubordinateCells);
	
EndProcedure

Procedure SetReportParameters(MainCircuitSettings)

	DataCompositionClientServer.SetParameter(MainCircuitSettings, "IndicatorAccounting", NStr("vi = 'KTDN';
																								|ru = 'БУ';
																								|en = 'LA'; fa = 'محلی';
																								|it = 'Contabilità civilistica';
																								|pl = 'EK';
																								|tr = 'Genel Muhasebe'"));
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "MAIndicator", NStr("vi = 'QT';
																						|ru = 'УУ';
																						|en = 'MA'; fa = 'مدیریت';
																						|it = 'Contabilità Gestionale';
																						|pl = 'EZ';
																						|tr = 'Yönetim Muhasebesi'"));
	
	// TypesOfDocumentsDepreciationWriteOff
	DocumentTypes = New ValueList;
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsInitialRecognition2_4"));
	DocumentTypes.Add(Type("DocumentRef.IARevaluation2_4"));
	DocumentTypes.Add(Type("DocumentRef.DisposeIntangibleAssets2_4"));
	DocumentTypes.Add(Type("DocumentRef.RegisterAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.PreparingForIntangibleAssetSale2_4"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "TypesOfDocumentsDepreciationWriteOff", DocumentTypes);
	
	// DocumentsTypesDepreciationAccrual
	DocumentTypes = New ValueList;
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsInitialRecognition2_4"));
	DocumentTypes.Add(Type("DocumentRef.EntryOfCapitalAssetsBalance2_4"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsAmortizationCharge2_4"));
	DocumentTypes.Add(Type("DocumentRef.IARevaluation2_4"));
	DocumentTypes.Add(Type("DocumentRef.VATAllocation"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.RegisterAdjustment"));
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "DocumentsTypesDepreciationAccrual", DocumentTypes);
	
	// DocumentsTypesCostIncrease
	DocumentTypes = New ValueList;
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsInitialRecognition2_4"));
	DocumentTypes.Add(Type("DocumentRef.EntryOfCapitalAssetsBalance2_4"));
	DocumentTypes.Add(Type("DocumentRef.IARevaluation2_4"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetImprovement"));
	DocumentTypes.Add(Type("DocumentRef.VATAllocation"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetImprovement"));
	DocumentTypes.Add(Type("DocumentRef.RegisterAdjustment"));
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "DocumentsTypesCostIncrease", DocumentTypes);
	
	// DocumentsTypesCostDecrease
	DocumentTypes = New ValueList;
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsAmortizationCharge2_4"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsInitialRecognition2_4"));
	DocumentTypes.Add(Type("DocumentRef.IARevaluation2_4"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetImprovement"));
	DocumentTypes.Add(Type("DocumentRef.DisposeIntangibleAssets2_4"));
	DocumentTypes.Add(Type("DocumentRef.PreparingForIntangibleAssetSale2_4"));
	DocumentTypes.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	DocumentTypes.Add(Type("DocumentRef.VATAllocation"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.IntangibleAssetImprovement"));
	DocumentTypes.Add(Type("DocumentRef.RegisterAdjustment"));
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "DocumentsTypesCostDecrease", DocumentTypes);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf