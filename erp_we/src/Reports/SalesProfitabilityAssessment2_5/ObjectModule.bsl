#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		Parameters.PurposeUseKey = Parameters.VariantKey + "=" + String(Parameters.CommandParameter);
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.PurposeUseKey;
		ThisForm.PurposeUseKey = Parameters.PurposeUseKey;
		
		ThisForm.ParametersForm.Filter.Insert("Document", Parameters.CommandParameter);
		
	EndIf;
	
	If IsBlankString(ThisForm.PurposeUseKey) Then
		Cancel = True;
		Raise NStr("vi = 'Báo cáo được dùng chỉ để mở trong chứng từ ""Báo giá"", ""Đơn hàng của khách"" và ""Giao hàng và cung cấp dịch vụ"".';
					|ru = 'Отчет предназначен только для открытия в документах ""Коммерческое предложение"", ""Заказ клиента"" и ""Реализация товаров и услуг"".';
					|en = 'The report is only intended for use in documents ""Sales quotation"", ""Sales order"", and ""Customer invoice"".'; fa = 'The report is only intended for use in documents ""Sales quotation"", ""Sales order"", and ""Customer invoice"".';
					|it = 'Il report è inteso solo per l''apertura nei documenti di ""Offerta commerciale"", ""Ordine cliente"" e ""Vendite di beni e servizi"".';
					|pl = 'Raport przeznaczony jest wyłącznie do otwarcia w dokumentach ""Oferta handlowa"", ""Zamówienie klienta"" i ""Sprzedaż towarów i usług"".';
					|tr = 'Rapor sadece ""Satış teklifi"", ""Satış siparişi"" ve ""Müşteri faturası"" belgelerinde açılmak üzere tasarlanmıştır.'") ;
	EndIf;

EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	ConfigureSelectionParametersByCallContext(ThisForm,FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

// Called in the report form handler of the same name after executing the form code.
// adds a preload handler to
// the server Option used to adjust previously saved user settings for the report
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCSettings) Export
	
	BeforeLoadVariantAtServer(ThisForm, NewDCSettings);
	
EndProcedure

Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	BeforeLoadVariantAtServer(ThisForm, NewDCSettings);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);

	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	SetPrivilegedMode(True);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	
	QueryText = DataCompositionSchema.DataSets.DocumentData.Query;
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor1", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(DocumentGoods.Package AS Catalog.PackagesAndUnitsOfMeasure)", 
			"DocumentGoods.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor2", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PlannedPrices_.Package", 
			"PlannedPrices_.Products"));
			
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor3", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SalesPrices.Package", 
			"SalesPrices.Products"));
			
	DataCompositionSchema.DataSets.DocumentData.Query = QueryText;
	
	QueryText = DataCompositionSchema.DataSets.SummaryCalculation.Query;
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor1", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(DocumentGoods.Package AS Catalog.PackagesAndUnitsOfMeasure)", 
			"DocumentGoods.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor2", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PlannedPrices_.Package", 
			"PlannedPrices_.Products"));
			
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor3", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SalesPrices.Package", 
			"SalesPrices.Products"));
			
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor4", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(CustomerOrderGoods.Package AS Catalog.PackagesAndUnitsOfMeasure)", 
			"CustomerOrderGoods.Products"));
			
	DataCompositionSchema.DataSets.SummaryCalculation.Query = QueryText;
	
	TextAndDocumentData = "";
	AddendumTextSummaryCalculation   = "";
	Sales.AddDocumentDataToQueryTextsReturnOnSalesReport(
		TextAndDocumentData,
		AddendumTextSummaryCalculation);
		
	DataCompositionSchema.DataSets.DocumentData.Query = StrReplace(
		DataCompositionSchema.DataSets.DocumentData.Query,
		"AND &SubstitutionOfTextOfLocalizationDocumentRequest",
		TextAndDocumentData);
	
	DataCompositionSchema.DataSets.SummaryCalculation.Query = StrReplace(
		DataCompositionSchema.DataSets.SummaryCalculation.Query,
		"AND &SubstitutionOfTextOfLocalizationDocumentRequest",
		AddendumTextSummaryCalculation);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings);

	// Check that at least one report grouping is enabled
	If CompositionTemplate.DataSets.Count() = 0 Then
		Raise NStr("vi = 'Báo cáo không được tạo. Bao gồm ít nhất một nhóm trong các thành phần thiết kế và nhóm.';
					|ru = 'Отчет не сформирован. Включите хотя бы одну группировку в ""Элементы оформления и группировки"".';
					|en = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".'; fa = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".';
					|it = 'Report non generato. Includere almeno un raggruppamento in ""Elementi di progettazione e raggruppamento"".';
					|pl = 'Raport nie został wygenerowany. Dodaj, co najmniej, jedno grupowanie ""Elementy sporządzenia i grupowania"".';
					|tr = 'Rapor oluşturulmamıştır. ""Düzenleme öğeleri ve gruplandırmalar"" bölümüne en az bir gruplandırma ekleyin.'") ;
	EndIf;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , , True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	SetPrivilegedMode(False);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	DocumentParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Document");
	If Not ValueIsFilled(DocumentParameter.Value) Then
		DocumentParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Document");
	EndIf;
	If TypeOf(DocumentParameter.Value) = Type("DocumentRef.CustomerInvoice") Then
		If ValueIsFilled(DocumentParameter.Value.SalesOrder) Then
			DataCompositionClientServer.SetParameter(SettingsComposer, "SalesOrder", DocumentParameter.Value.SalesOrder);
		ElsIf DocumentParameter.Value.OrderSales Then
			OrdersTable = DocumentParameter.Value.Goods.Unload(, "SalesOrder");
			OrdersTable.GroupBy("SalesOrder");
			DataCompositionClientServer.SetParameter(SettingsComposer, "SalesOrder", OrdersTable.UnloadColumn("SalesOrder"));
		Else
			DataCompositionClientServer.SetParameter(SettingsComposer, "SalesOrder", DocumentParameter.Value);
		EndIf;
	ElsIf TypeOf(DocumentParameter.Value) = Type("DocumentRef.SalesOrder") Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "SalesOrder", DocumentParameter.Value);
	EndIf;
	
	DocumentDateParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "DocumentDate");
	If DocumentDateParameter <> Undefined 
		And Not ValueIsFilled(DocumentDateParameter.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "DocumentDate", DocumentParameter.Value.Date);
	EndIf;
	
	ParameterOrganization = DataCompositionClientServer.GetParameter(SettingsComposer, "Organization");
	If ParameterOrganization <> Undefined 
		And Not ValueIsFilled(ParameterOrganization.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "Organization", DocumentParameter.Value.Organization);
	EndIf;
	
	ManagerParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Manager");
	If ManagerParameter <> Undefined 
		And Not ValueIsFilled(ManagerParameter.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "Manager", DocumentParameter.Value.Manager);
	EndIf;
	
	CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	If CurrencyParameter <> Undefined 
		And Not ValueIsFilled(CurrencyParameter.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "Currency", DocumentParameter.Value.Currency);
	EndIf;
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	ParameterCurrencyOfManagementAccounting = DataCompositionClientServer.GetParameter(SettingsComposer, "ManagementAccountingCurrency");
	If ParameterCurrencyOfManagementAccounting <> Undefined 
		And Not ValueIsFilled(ParameterCurrencyOfManagementAccounting.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ManagementAccountingCurrency", ManagementAccountingCurrency);
	EndIf;
	
	PriceParameterIncludesVAT = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceIncludesVAT");
	If PriceParameterIncludesVAT <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "PriceIncludesVAT", DocumentParameter.Value.PriceIncludesVAT);
	EndIf;
	
	ParameterModeForCalculatingCostOfGoods = DataCompositionClientServer.GetParameter(SettingsComposer, "ModeForCalculatingCostOfGoods");
	If ParameterModeForCalculatingCostOfGoods <> Undefined Then
		GoodsCostWhenEvaluatingSalesProfitability = Constants.GoodsCostWhenEvaluatingSalesProfitability.Get();
		StandardPriceType = Constants.StandardPriceType.Get();
		
		If GoodsCostWhenEvaluatingSalesProfitability = Enums.GoodsCostWhenEvaluatingSalesProfitability.ByEstimatedCost Then
			CostCalculationParameters = CostCalculationParameters(ParameterOrganization.Value);
			ModeString = NStr("vi = 'Theo giá vốn đã tính';
								|ru = 'По расчетной себестоимости';
								|en = 'By estimated cost'; fa = 'بر اساس بهای برآوردی';
								|it = 'A costo stimato';
								|pl = 'Wg szacowanych kosztów własnych';
								|tr = 'Hesaplanan üretim maliyetine göre'");
			EvaluationMethod = CostCalculationParameters.EvaluationMethod;
			PreliminaryCalculation = CostCalculationParameters.PreliminaryCalculation;
			If EvaluationMethod <> Undefined Then
				ModeString = ModeString + " (" + ?(PreliminaryCalculation, NStr("vi = 'Tính sơ bộ';
																				|ru = 'Предварительный расчет';
																				|en = 'Preliminary calculation'; fa = 'محاسبه مقدماتی';
																				|it = 'Calcolo preliminare';
																				|pl = 'Szacunkowe obliczenie';
																				|tr = 'Ön hesaplama'"), NStr("vi = 'Tính toán thực tế';
																														|ru = 'Фактический расчет';
																														|en = 'Actual calculation'; fa = 'Actual calculation';
																														|it = 'Calcolo effettivo';
																														|pl = 'Faktyczne obliczenie';
																														|tr = 'Gerçek hesaplama'")) + ", " + EvaluationMethod + "). " + 
					NStr("vi = 'Cập nhật tại ngày';
						|ru = 'Актуальна на дату';
						|en = 'Relevant as of the date'; fa = 'Relevant as of the date';
						|it = 'Effettivo in data';
						|pl = 'Aktualne na datę';
						|tr = 'Şu tarih itibariyle geçerlidir'") + ": " + Format(CostCalculationParameters.Date, "DLF=DT");
			EndIf;
		Else
			ModeString = NStr("vi = 'Theo dạng giá định mức';
								|ru = 'По нормативному виду цен';
								|en = 'By a standard price type'; fa = 'بر اساس نوع قیمت استاندارد';
								|it = 'Secondo il tipo standard di prezzi';
								|pl = 'Wg normatywnego rodzaju cen';
								|tr = 'Normatif fiyat türüne göre'") + " - """ + StandardPriceType + """";
		EndIf;
	
		DataCompositionClientServer.SetParameter(SettingsComposer, "ModeForCalculatingCostOfGoods", ModeString);
	EndIf;
		
	SellingPriceParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "SalePrices");
	PriceViewParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
	DataCompositionClientServer.SetParameter(SettingsComposer, "SalePrices", 1 + Number(PriceViewParameter.Use));
	
	CostOfGoodsParameterWhenEvaluatingProfitabilityOfSales = DataCompositionClientServer.GetParameter(SettingsComposer, 
		"GoodsCostWhenEvaluatingSalesProfitability");
	If CostOfGoodsParameterWhenEvaluatingProfitabilityOfSales <> Undefined 
		And Not ValueIsFilled(CostOfGoodsParameterWhenEvaluatingProfitabilityOfSales.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "GoodsCostWhenEvaluatingSalesProfitability", 
			Constants.GoodsCostWhenEvaluatingSalesProfitability.Get());
	EndIf;
		
	ParameterNormativeTypeOfPrices = DataCompositionClientServer.GetParameter(SettingsComposer, "StandardPriceType");
	If ParameterNormativeTypeOfPrices <> Undefined 
		And Not ValueIsFilled(ParameterNormativeTypeOfPrices.Value) Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "StandardPriceType", Constants.StandardPriceType.Get());
	EndIf;
	
EndProcedure

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	CurrentVariantKey = "";
	If SettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey", CurrentVariantKey) Then
		If CurrentVariantKey = "EvaluationOfReturnOnSalesContext" Then
			AuxiliaryParameters.Add("SalePrices");
			AuxiliaryParameters.Add("PriceKind");
		EndIf;
	EndIf;
	
	Return AuxiliaryParameters;
EndFunction

Function CostCalculationParameters(Organization)
	CostCalculationParameters = New Structure("EvaluationMethod, PreliminaryCalculation, Date");
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	               |	InventoryCostCalculation.PreliminaryCalculation,
	               |	InventoryCostCalculation.EvaluationMethod,
	               |	InventoryCostCalculation.Date AS Date
	               |FROM
	               |	Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	               |		INNER JOIN Document.InventoryCostCalculation AS InventoryCostCalculation
	               |		ON InventoryCostCalculationCompanies.Ref = InventoryCostCalculation.Ref
	               |WHERE
	               |	InventoryCostCalculation.Posted
	               |	AND InventoryCostCalculationCompanies.Organization = &Organization
	               |
	               |ORDER BY
	               |	Date DESC";
	Query.SetParameter("Organization", Organization);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(CostCalculationParameters, Selection);
	EndIf;
	
	Return CostCalculationParameters;

EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseSalesOrders") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "FutureSales");
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralPriceTypes") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "PriceKind");
	EndIf;
	
	If Not GetFunctionalOption("UseDiscountAdjustmentsInSales") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "ChangingVolumeOfManualDiscounts");
	EndIf;
	
EndProcedure

Procedure ConfigureSelectionParametersByCallContext(ThisForm,FormSettingsComposer)
	
	Sales.WhenSettingSelectionParametersByCallContext(ThisForm, FormSettingsComposer);
	
EndProcedure

#EndRegion

#EndIf