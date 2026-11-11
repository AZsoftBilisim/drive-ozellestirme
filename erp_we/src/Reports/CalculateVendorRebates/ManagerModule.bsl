//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CalculateVendorRebates);
	DescriptionOfReport.DefaultVisibility = True;
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, False);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
//   ValueTableRow - description of the created team.
//
Function AddCommandToCalculateSuppliersRebates(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.CalculateVendorRebates) Then
		
		ReportCommand = ReportsCommands.Add();
		
		Presentation = NStr("vi = 'Tính thưởng lũy kế của nhà cung cấp';
							|ru = 'Расчет ретро-бонусов поставщика';
							|en = 'Calculate vendor rebates'; fa = 'محاسبه تخفیف‌های حجمی فروشنده';
							|it = 'Расчет ретро-бонусов поставщика';
							|pl = 'Calculate vendor rebates';
							|tr = 'Tedarikçi retro bonuslarının muhasebesi'");
		ReportCommand.Manager = Metadata.Reports.CalculateVendorRebates.FullName();
		ReportCommand.Presentation = Presentation;
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "CalculationOfVendorRebatesContext";
		
		ReportCommand.Handler = "RebatesClient.CalculateVendorRebates";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters for calculating retro bonuses.
// 
// Returns:
//  Structure:
//  * TermDocument - DocumentRef.ConditionsOfVendorRebates
//  * StartDate - Date - The beginning of the bonus calculation period
//  * EndDate - Date - The end of the bonus calculation period
//  * DateOfRemainingGoods - Date - Balance date (only for bonus type Balance)
//  * Currency - CatalogRef.Currencies - Currency Selection
// 
Function RebatesCalculationParameters() Export
	
	DateEmpty = Date(1, 1, 1);
	
	Parameters = New Structure;
	Parameters.Insert("TermDocument", Documents.ConditionsOfVendorRebates.EmptyRef());
	Parameters.Insert("StartDate", DateEmpty);
	Parameters.Insert("EndDate", DateEmpty);
	Parameters.Insert("DateOfRemainingGoods", DateEmpty);
	Parameters.Insert("Currency", Catalogs.Currencies.EmptyRef());
	
	Return Parameters;
	
EndFunction

// Returns a table of calculated retro-bonuses of suppliers for filling out the accrual documents.
// 
// Parameters:
//  CalculationParameters - See RebatesCalculationParameters
//  InPrivilegedMode - Boolean
// 
// Returns:
//  ValueTable - Calculated retro-bonuses under the specified conditions:
//   * Organization - CatalogRef.Companies
//   * Currency - CatalogRef.Currencies
//   * CounterpartyCustomer - CatalogRef.Counterparties
//   * SumPlan - Number
//   * AmountInBasePrices - Number
//   * AmountOfTurnoverExcludingVAT - Number
//   * AmountOfTurnoverWithVAT - Number
//   * CalculationBase - Number
//   * AmountBonus - Number
//  
Function CalculationOfRebatesForPeriod(CalculationParameters, InPrivilegedMode = True) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Report.CalculateVendorRebates.ManagerModule.CalculationOfRebatesForPeriod");
	
	Attributes = "Posted, WithoutCalculation, Status, Patch, CorrectedDocument";
	AttributesValues = Common.ObjectAttributesValues(CalculationParameters.TermDocument, Attributes);
	
	If Not AttributesValues.Posted Then
		
		ExceptionText = NStr("vi = 'Chưa kết chuyển chứng từ điều kiện.';
							|ru = 'Документ условий не проведен.';
							|en = 'The condition document is not posted.'; fa = 'The condition document is not posted.';
							|it = 'Документ условий не проведен.';
							|pl = 'The condition document is not posted.';
							|tr = 'Şartlar belgesi kaydedilmedi.'");
		Raise ExceptionText;
		
	EndIf;
	
	If AttributesValues.Patch = True Then
		SourceDocument_ = AttributesValues.CorrectedDocument;
	Else
		SourceDocument_ = CalculationParameters.TermDocument;
	EndIf;
	ConditionParameters_ = RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers(SourceDocument_);
	
	If ConditionParameters_.Count() = 0 Then
		
		ExceptionText = NStr("vi = 'Chưa thống nhất chứng từ điều kiện.';
							|ru = 'Документ условий не согласован.';
							|en = 'The condition document is not approved.'; fa = 'The condition document is not approved.';
							|it = 'Документ условий не согласован.';
							|pl = 'The condition document is not approved.';
							|tr = 'Şartlar belgesi kabul edilmedi.'");
		Raise ExceptionText;
		
	EndIf;
	
	SegmentsOrPropertiesAreUsed = ConditionParameters_.CalculationByProperties
		Or (ConditionParameters_.ContentOfGoods = Enums.RebatesItems.ProductSegments);
	
	If SegmentsOrPropertiesAreUsed
	   And Not ConditionParameters_.RecordingIsCompleted Then
		
		ExceptionText = NStr("vi = 'Chưa ghi nhận thành phần hàng hóa của chứng từ điều kiện.';
							|ru = 'Не зафиксирован состав товаров документа условий.';
							|en = 'The condition document items are not recorded.'; fa = 'The condition document items are not recorded.';
							|it = 'The condition document items are not recorded.';
							|pl = 'The condition document items are not recorded.';
							|tr = 'Şartlar belgesi ürünlerinin içeriği sabitlenmedi.'");
		Raise ExceptionText;
		
	EndIf;
	
	// adjustment of the calculation period according to the period of validity of the conditions
	
	DateEmpty = '00010101';
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	If ConditionParameters_.BonusType <> TypesOfBonuses.Balance Then
		
		If CalculationParameters.StartDate = DateEmpty
		 Or CalculationParameters.StartDate < ConditionParameters_.ValidOnDate
		 Or CalculationParameters.StartDate > ConditionParameters_.ValidTo Then
			
			CalculationParameters.StartDate = ConditionParameters_.ValidOnDate;
			
		EndIf;
		
		If CalculationParameters.EndDate = DateEmpty
		 Or CalculationParameters.EndDate < ConditionParameters_.ValidOnDate
		 Or CalculationParameters.EndDate > EndOfDay(ConditionParameters_.ValidTo) Then
			
			CalculationParameters.EndDate = ConditionParameters_.ValidTo;
			
		EndIf;
		
	EndIf;
	
	OptionParameters = RebatesCalculation.NewOptionParameters();
	OptionParameters.ThisIsTheTranscript = True;
	OptionParameters.ThisIsTranscriptOfDocuments = True;
	
	If ConditionParameters_.BonusType = TypesOfBonuses.Sales Then
		
		OptionParameters.VariantKey = "SalesAccruals";
		
	ElsIf ConditionParameters_.BonusType = TypesOfBonuses.Purchases Then
		
		OptionParameters.VariantKey = "PurchasesAccruals";
		
	ElsIf ConditionParameters_.BonusType = TypesOfBonuses.Balance Then
		
		OptionParameters.VariantKey = "AccrualBalances";
		
	Else
		
		ExceptionPattern = NStr("vi = 'Loại thưởng không được hỗ trợ ""%1"".';
								|ru = 'Неподдерживаемый тип бонуса ""%1"".';
								|en = 'Unsupported rebate type: %1'; fa = 'Unsupported rebate type: %1';
								|it = 'Неподдерживаемый тип бонуса ""%1"".';
								|pl = 'Unsupported rebate type: %1';
								|tr = '""%1"" bonus türü desteklenmiyor.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionPattern, String(ConditionParameters_.BonusType));
		Raise ExceptionText;
		
	EndIf;
	
	DataCompositionSchema = GetTemplate("MainDataCompositionSchema");
	
	If InPrivilegedMode Then
		SetPrivilegedMode(True);
	EndIf;
	
	VendorTable = Reports.CalculateVendorRebates.PreliminaryTableOfVendors(SourceDocument_);
	
	QueryText = QueryText(ConditionParameters_, OptionParameters, VendorTable);
	DataCompositionSchema.DataSets.CalculateVendorRebates.Query = QueryText;
	
	CompositeVersionOfReport = DataCompositionSchema.SettingVariants[OptionParameters.VariantKey];
	
	ComposerOfSettingsByOption = New DataCompositionSettingsComposer;
	ComposerOfSettingsByOption.LoadSettings(CompositeVersionOfReport.Settings);
	SourceOfAvailableCDSettings = New DataCompositionAvailableSettingsSource(DataCompositionSchema);
	ComposerOfSettingsByOption.Initialize(SourceOfAvailableCDSettings);
	ReportSettings = ComposerOfSettingsByOption.GetSettings();
	
	ParametersToBeSpecified = New Map;
	ParametersToBeSpecified.Insert("DocumentTermsOfRetroBonuses", CalculationParameters.TermDocument);
	ParametersToBeSpecified.Insert("SourceDocument_", SourceDocument_);
	ParametersToBeSpecified.Insert("Organization", ConditionParameters_.Organization);
	
	ParametersToBeSpecified.Insert("StartDate", CalculationParameters.StartDate);
	ParametersToBeSpecified.Insert("EndDate", EndOfDay(CalculationParameters.EndDate));
	ReportPeriod = New StandardPeriod(CalculationParameters.StartDate, CalculationParameters.EndDate);
	ParametersToBeSpecified.Insert("ReportPeriod", ReportPeriod);
	ParametersToBeSpecified.Insert("DateOfRemainingGoods", CalculationParameters.DateOfRemainingGoods);
	
	ParametersToBeSpecified.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	ParametersToBeSpecified.Insert("Partner", Catalogs.Partners.EmptyRef());
	ExcludedBusinessOfOperations = Reports.CalculateVendorRebates.ExcludedBusinessOfOperations();
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ExcludedBusinessOfOperations", ExcludedBusinessOfOperations);
	ExcludedSettingsOfBTransaction = Reports.CalculateVendorRebates.ExcludedSettingsOfBusinessTransaction();
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ExcludedSettingsOfBusinessTransaction", ExcludedSettingsOfBTransaction);
	
	DataCompositionClientServer.SetCollectionOfParameters(ReportSettings, ParametersToBeSpecified);
	
	If ValueIsFilled(CalculationParameters.Currency) Then
		
		DataCompositionClientServer.AddFilter(ReportSettings, "Currency", CalculationParameters.Currency);
		
	EndIf;
	
	If ConditionParameters_.BonusType = Enums.VendorRebateTypes.Purchases Then
		
		Query = New Query;
		TempTableManager = New TempTablesManager();
		Query.TempTablesManager = TempTableManager;
		Query.SetParameter("VendorTable", VendorTable);
		
		QueryText =
		"SELECT
		|	*
		|INTO VT_SuppliersInAdvance
		|FROM
		|	&VendorTable AS VendorTable";
		Query.Text = QueryText;
		
		Query.Execute();
		
	Else
		
		TempTableManager = Undefined;
		
	EndIf;
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 1, "Setting");
	
	TemplateComposer = New DataCompositionTemplateComposer;
	
	DataCompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, ReportSettings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate,,, True,, TempTableManager);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	ResultTable1 = New ValueTable;
	OutputProcessor.SetObject(ResultTable1);
	OutputProcessor.Output(DataCompositionProcessor);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ResultTable1.Count(), "Layout");
	
	Return ResultTable1;
	
EndFunction

Function ExcludedBusinessOfOperations() Export
	
	Result = New Array; // Array of EnumRef.BusinessTransactions
	Result.Add(Enums.BusinessTransactions.SalesViaCommissionAgent);
	Result.Add(Enums.BusinessTransactions.ConsignmentReportFromCustomer);
	Return Result;
	
EndFunction

Function ExcludedSettingsOfBusinessTransaction() Export
	
	Result = New Array; // Array of CatalogRef.BusinessTransactionsSettings
	Result.Add(Catalogs.BusinessTransactionsSettings.SalesViaCommissionAgent);
	Return Result;
	
EndFunction

Function TypesOfPurchaseSampleRegistrars() Export
	
	Result = New Array; // Array of MetadataObjectDocument
	
	Result.Add(Metadata.Documents.ReturnOfGoodsToVendor);
	Result.Add(Metadata.Documents.RedemptionOfGoodsFromStorage);
	Result.Add(Metadata.Documents.PurchaseAdjustment);
	Result.Add(Metadata.Documents.VendorInvoice);
	
	Return Result;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers
//  OptionParameters - See RebatesCalculation.NewOptionParameters
//  VendorTable - ValueTable
// 
// Returns:
//  String - Query text
//
Function QueryText(RebateConditionsParameters, OptionParameters, VendorTable) Export
	
	BonusType = RebateConditionsParameters.BonusType;
	TypesOfBonus = Enums.VendorRebateTypes;
	QueriesTexts = New Array; // Array of String
	
	If BonusType = TypesOfBonus.Sales Then
		
		GenerateQueryTextsForSales(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf BonusType = TypesOfBonus.Purchases Then
		
		GenerateQueryTextsForPurchases(RebateConditionsParameters, OptionParameters, QueriesTexts, VendorTable);
		
	ElsIf BonusType = TypesOfBonus.Balance Then
		
		GenerateQueryTextsBasedOnBalances(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf BonusType = TypesOfBonus.EmptyRef() Then
		
		ErrorTemplate = NStr("vi = 'Chưa điền loại thưởng cho chứng từ ""%1""';
							|ru = 'Не заполнен тип бонуса для документа ""%1""';
							|en = 'Rebate type for the %1 document is not filled in'; fa = 'Rebate type for the %1 document is not filled in';
							|it = 'Не заполнен тип бонуса для документа ""%1""';
							|pl = 'Rebate type for the %1 document is not filled in';
							|tr = '""%1"" için bonus türü doldurulmamış'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Sai loại thưởng ""%1"" cho chứng từ ""%2""';
							|ru = 'Некорректный тип бонуса ""%1"" для документа ""%2""';
							|en = 'Incorrect rebate type (%1) for the %2 document'; fa = 'Incorrect rebate type (%1) for the %2 document';
							|it = 'Некорректный тип бонуса ""%1"" для документа ""%2""';
							|pl = 'Incorrect rebate type (%1) for the %2 document';
							|tr = '""%2"" belgesi için ""%1"" bonus türü yanlış'");
		BonusTypeByString = String(BonusType);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			BonusTypeByString,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	QueryBatchSeparator = Common.QueryBatchSeparator();
	QueryText = StrConcat(QueriesTexts, QueryBatchSeparator);
	
	Return QueryText;
	
EndFunction

// Parameters:
//  SourceDocument_ - DocumentRef.ConditionsOfVendorRebates
// 
// Returns:
//  ValueTable:
//  * Counterparty - CatalogRef.Counterparties
//  * Partner - CatalogRef.Partners
//  * Contract - CatalogRef.CounterpartyContracts
//  * Terms - CatalogRef.TermsOfPurchaseFromVendors
//
Function PreliminaryTableOfVendors(SourceDocument_) Export
	
	Query = New Query;
	Query.SetParameter("SourceDocument_", SourceDocument_);
	
	QueryText =
	"SELECT
	|	VendorRebatesVendors.Counterparty AS Counterparty,
	|	VendorRebatesVendors.Partner AS Partner,
	|	VendorRebatesVendors.Contract AS Contract,
	|	VendorRebatesVendors.Terms AS Terms,
	|	VendorRebatesVendors.ValidOnDate AS ValidOnDate,
	|	VendorRebatesVendors.ValidTo AS ValidTo
	|FROM
	|	InformationRegister.VendorRebatesVendors AS VendorRebatesVendors
	|WHERE
	|	VendorRebatesVendors.TermDocument = &SourceDocument_";
	
	Query.Text = QueryText;
	VendorTable = Query.Execute().Unload();
	Return VendorTable;
	
EndFunction

#EndRegion

#Region Private

#Region QueryText

#Region Sales

Procedure GenerateQueryTextsForSales(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	GoodsIndicator = RebateConditionsParameters.GoodsIndicator;
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If GoodsIndicator = IndicatorsKinds.NotUsed Then
		
		GenerateSalesQueryTextsWithoutTargetIndicator(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.Sum Then
		
		GenerateQueryTextsForSalesAmount(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.Count Then
		
		GenerateQueryTextsForSalesQuantity(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.QuantityTotal Then
		
		GenerateQueryTextsOfSalesQuantityInAggregate(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		GenerateQueryTextsForSalesPackageOffer(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.EmptyRef() Then
		
		ErrorTemplate = NStr("vi = 'Chưa điền chỉ tiêu hàng hóa đối với chứng từ ""%1""';
							|ru = 'Не заполнен показатель товаров для документа ""%1""';
							|en = 'The goods indicator is not filled for the %1 document'; fa = 'The goods indicator is not filled for the %1 document';
							|it = 'Не заполнен показатель товаров для документа ""%1""';
							|pl = 'The goods indicator is not filled for the %1 document';
							|tr = '""%1"" belgesi için satış hedefi doldurulmamış'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Chưa xác định chỉ tiêu hàng hóa (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить показатель товаров (""%1"") для документа ""%2""';
							|en = 'Cannot determine the goods indicator (%1) for the %2 document'; fa = 'Cannot determine the goods indicator (%1) for the %2 document';
							|it = 'Не удалось определить показатель товаров (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the goods indicator (%1) for the %2 document';
							|tr = 'Belge ""%2"" için satış hedefi (""%1"") tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.GoodsIndicatorPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

Procedure GenerateSalesQueryTextsWithoutTargetIndicator(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryDataWithoutTarget(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsForSalesAmount(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	CalculationWithDistribution = (RebateConditionsParameters.RestrictAccrualOverPlan
		Or RebateConditionsParameters.CalculationScaleByRanges);
	
	If CalculationWithDistribution Then
		
		GenerateQueryTextsForSalesAmountProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		GenerateQueryTextsForSalesAmountWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsForSalesAmountWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextCalculationScale(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextCalculationScaleMinimumPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfSaleWithoutSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddSalesQueryTextWithSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodDefinitionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextPreparedAmountData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsForSalesAmountProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale
	 Or RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextCalculationScale(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextCalculationScaleMinimumPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfSaleWithoutSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddSalesQueryTextWithSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodDefinitionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByRange(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedAmountData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataForProportionalDistributionByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextRoundingProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfFinalProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTotalsByScaleRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextErrorCorrectionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsForSalesQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	CalculationWithDistribution = (RebateConditionsParameters.RestrictAccrualOverPlan
		Or RebateConditionsParameters.CalculationScaleByRanges);
	
	If CalculationWithDistribution Then
		
		GenerateQueryTextsForSalesQuantityProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		GenerateQueryTextsForSalesQuantityWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsForSalesQuantityWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfGoodsMinimumPackingPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMinimumParametersByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataPlanDefinition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedQuantityData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsForSalesQuantityProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextOfGoodsMinimumPackingPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextMinimumParametersByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextGoodsRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByRangeByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPreparedDataByQuantityByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		RebatesCalculation.AddQueryTextPreparedDataPlanDefinition(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPreparedQuantityData(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataForProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextBaseOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCalculationOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextProportionalDistributionByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextRoundingProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfFinalProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTotalsByScaleRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextErrorCorrectionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsOfSalesQuantityInAggregate(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocuments(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsAllGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsGoodsSold(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMissingPackageContents(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithPackageData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriodPackageConditionsNotMet(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriodPackageConditionsAreMet(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataByQuantityInAggregate(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsForSalesPackageOffer(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocuments(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsAllGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsGoodsSold(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMissingPackageContents(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithPackageData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMultiplicityOfGoodsPackage(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextNumberOfGoodsPackages(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataForPackageOffer(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataForProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextBaseOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCalculationOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextProportionalDistributionByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextRoundingProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfFinalProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure AddQueryTextPartnersStub(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	&SourceDocument_ AS TermsAndConditionsOfRebates,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	DATETIME(1, 1, 1) AS StartDate,
	|	DATETIME(1, 1, 1) AS EndDate,
	|	0 AS SumPlan
	|INTO TT_Partners
	|WHERE
	|	FALSE";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextPartnersCounterpartiesStub(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	&SourceDocument_ AS TermsAndConditionsOfRebates,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	DATETIME(1, 1, 1) AS StartDate,
	|	DATETIME(1, 1, 1) AS EndDate,
	|	0 AS SumPlan
	|INTO TT_CounterpartyPartners
	|WHERE
	|	FALSE";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextOfSalesMerge(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	PartyCountDetails = RebateConditionsParameters.PartyCountDetails;
	DetailsOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	QueryText =
	"SELECT
	|	SummaryData.Period AS Period,
	|	SummaryData.CalculationPeriod AS CalculationPeriod,
	|	SummaryData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SummaryData.GoodsIndicator AS GoodsIndicator,
	|	SummaryData.PartyCountDetails AS PartyCountDetails,
	|	SummaryData.ConditionFrequency AS ConditionFrequency,
	|	ISNULL(VendorRebatesVendors.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) AS CounterpartySupplier,
	|	ISNULL(VendorRebatesVendors.Partner, VALUE(Catalog.Partners.EmptyRef)) AS PartnerVendor,
	|	ISNULL(VendorRebatesVendors.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS SupplierAgreement,
	|	ISNULL(VendorRebatesVendors.Terms, VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)) AS SupplierTerms,
	|	SummaryData.DocumentRecorder AS DocumentRecorder,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	SummaryData.Organization AS Organization,
	|	&ExpressionCounterpartyCustomer AS CounterpartyCustomer,
	|	SummaryData.Products AS Products,
	|	SummaryData.UnitOfMeasure AS UnitOfMeasure,
	|	SummaryData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	SummaryData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	SummaryData.Characteristic AS Characteristic,
	|	SummaryData.PropertyValue AS PropertyValue,
	|	SummaryData.PresentationOfRangeUnit AS PresentationOfRangeUnit,
	|	SummaryData.RangeNumber AS RangeNumber,
	|	SummaryData.RangeFrom AS RangeFrom,
	|	SummaryData.RangeBy AS RangeBy,
	|	SummaryData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	SummaryData.PlanIsFulfilled AS PlanIsFulfilled,
	|	SummaryData.Count AS CountTurnover,
	|	0 AS CountBalance,
	|	SummaryData.Currency AS Currency,
	|	SummaryData.BasePrice AS BasePrice,
	|	SummaryData.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	SummaryData.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	CAST(SummaryData.Count * SummaryData.BasePrice AS NUMBER(31, 2)) AS AmountInBasePrices,
	|	SummaryData.BonusPercent AS BonusPercent,
	|	SummaryData.SumPlan AS SumPlan,
	|	SummaryData.CountPlan AS CountPlan,
	|	SummaryData.CalculationBase AS CalculationBase,
	|	SummaryData.AmountBonus AS AmountBonus,
	|	SummaryData.NumberOfPackages_ AS NumberOfPackages_,
	|	0 AS BonusAmountPerUnit
	|INTO TT_Merging
	|FROM
	|	TT_SummaryData AS SummaryData
	|	LEFT JOIN InformationRegister.VendorRebatesVendors AS VendorRebatesVendors
	|	ON VendorRebatesVendors.TermDocument = &SourceDocument_
	|	LEFT JOIN TT_DiscountPercentage AS TT_DiscountPercentage
	|	ON SummaryData.DocumentRecorder = TT_DiscountPercentage.DocumentRecorder
	|		AND SummaryData.LineNumber = TT_DiscountPercentage.LineNumber";
	
	If PartyCountDetails = DetailsOfParticipants.EmptyRef() Then
		
		ExpressionCounterpartyCustomer = "ISNULL(TT_DiscountPercentage.Counterparty, VALUE(Catalog.Counterparties.EmptyRef))";
		
	Else
		
		ExpressionCounterpartyCustomer = "SummaryData.Counterparty";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&ExpressionCounterpartyCustomer", ExpressionCounterpartyCustomer);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

#EndRegion

#Region Purchases

Procedure GenerateQueryTextsForPurchases(RebateConditionsParameters, OptionParameters, QueriesTexts, VendorTable)
	
	CombinationsOfSuppliers = CombinationsOfSupplierFields(VendorTable);
	
	GoodsIndicator = RebateConditionsParameters.GoodsIndicator;
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If GoodsIndicator = IndicatorsKinds.NotUsed Then
		
		GenerateQueryTextsForPurchasesWithoutTargetIndicator(
			RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	ElsIf GoodsIndicator = IndicatorsKinds.Sum Then
		
		GenerateQueryTextsForPurchaseAmount(
			RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	ElsIf GoodsIndicator = IndicatorsKinds.Count Then
		
		GeneratePurchaseQueryTextsQuantity(
			RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	ElsIf GoodsIndicator = IndicatorsKinds.QuantityTotal Then
		
		GeneratePurchaseQueryTextsQuantityInAggregate(
			RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	ElsIf GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		GeneratePurchaseQueryTextsPackageOffer(
			RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	ElsIf GoodsIndicator = IndicatorsKinds.EmptyRef() Then
		
		ErrorTemplate = NStr("vi = 'Chưa điền chỉ tiêu hàng hóa cho chứng từ ""%1""';
							|ru = 'Не заполнен показатель товаров для документа ""%1""';
							|en = 'The goods indicator is not filled for the %1 document'; fa = 'The goods indicator is not filled for the %1 document';
							|it = 'Не заполнен показатель товаров для документа ""%1""';
							|pl = 'The goods indicator is not filled for the %1 document';
							|tr = '""%1"" belgesi için satış hedefi doldurulmamış'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Chưa xác định chỉ tiêu hàng hóa (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить показатель товаров (""%1"") для документа ""%2""';
							|en = 'Cannot determine the goods indicator (%1) for the %2 document'; fa = 'Cannot determine the goods indicator (%1) for the %2 document';
							|it = 'Не удалось определить показатель товаров (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the goods indicator (%1) for the %2 document';
							|tr = 'Belge ""%2"" için satış hedefi (""%1"") tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.GoodsIndicatorPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsForPurchasesWithoutTargetIndicator(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextSummaryDataWithoutTarget(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsForPurchaseAmount(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	CalculationWithDistribution = (RebateConditionsParameters.RestrictAccrualOverPlan
		Or RebateConditionsParameters.CalculationScaleByRanges);
	
	If CalculationWithDistribution
	   And RebateConditionsParameters.ProportionalDistribution Then
		
		GeneratePurchaseQueryTextsAmountProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	ElsIf CalculationWithDistribution
	        And RebateConditionsParameters.DistributionByFIFO Then
		
		GenerateQueryTextsPurchasesAmountDistributionFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	Else
		
		GenerateQueryTextsForPurchaseAmountWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsForPurchaseAmountWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextCalculationScale(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextCalculationScaleMinimumPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodDefinitionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextPreparedAmountData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GeneratePurchaseQueryTextsAmountProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale
	 Or RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextCalculationScale(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextCalculationScaleMinimumPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodDefinitionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByRange(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedAmountData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataForProportionalDistributionByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextRoundingProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfFinalProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTotalsByScaleRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextErrorCorrectionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsPurchasesAmountDistributionFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale
	 Or RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextCalculationScale(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextCalculationScaleMinimumPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodDefinitionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedAmountData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverByPortions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPortionsCumulativeTotal(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_TurnoverByPortions",
		"VT_TurnoverByPortionsCumulativeTotal",
		True);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextPortionOfExceedingRangeLimit(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverByPortionsCumulativeTotal",
			"VT_PortionExceedingLimit");
		
	Else
		
		RebatesCalculation.AddQueryTextPortionOfLimitExceeded(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverByPortionsCumulativeTotal",
			"VT_PortionExceedingLimit");
			
	EndIf;
	
	RebatesCalculation.AddQueryTextPreviousPortionBeforeLimitWasExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverUntilLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverBySubPortions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPortionsCumulativeTotal(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_RevolutionsBySubPortions",
		"VT_TurnoverBySubPortionsCumulativeTotal");
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextPortionOfExceedingRangeLimit(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverBySubPortionsCumulativeTotal",
			"VT_SubPortionOfExceedingLimit");
		
	Else
		
		RebatesCalculation.AddQueryTextPortionOfLimitExceeded(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverBySubPortionsCumulativeTotal",
			"VT_SubPortionOfExceedingLimit");
			
	EndIf;
	
	RebatesCalculation.AddQueryTextSubPortionOfExceedingLimitRevolutionsPerServing(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreviousSubPortionBeforeLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextSubPortionOfExceedingLimitTurnoverToSubPortion(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverPerPortionExceedingLimit(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_SubPortionOfExceedingLimitRevolutionsToSubPortion",
		"VT_TurnoverPerSubPortionExceedingLimit",
		RebatesCalculation.SubPortionOfCumulativeTotal());
	
	RebatesCalculation.AddQueryTextExceedingLimitCumulativeTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextLinesOnBordersOfRangesByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPrioritiesOnRangeBoundaries(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPrioritiesBalancesOnRangeBoundaries(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextDistributionOfRowsByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextFinalFIFODistributionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		RebatesCalculation.AddQueryTextOfMinimumPriorityForExecutionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextDataForDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextRoundingDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextFinalFIFODistributionByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GeneratePurchaseQueryTextsQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	CalculationWithDistribution = (RebateConditionsParameters.RestrictAccrualOverPlan
		Or RebateConditionsParameters.CalculationScaleByRanges);
	
	If CalculationWithDistribution
	   And RebateConditionsParameters.ProportionalDistribution Then
		
		GeneratePurchaseQueryTextsQuantityProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	ElsIf CalculationWithDistribution
	        And RebateConditionsParameters.DistributionByFIFO Then
		
		GenerateQueryTextsPurchasesQuantityFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	Else
		
		GeneratePurchaseQueryTextsQuantityWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	EndIf;
	
EndProcedure

Procedure GeneratePurchaseQueryTextsQuantityWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfGoodsMinimumPackingPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMinimumParametersByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataPlanDefinition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedQuantityData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GeneratePurchaseQueryTextsQuantityProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextOfGoodsMinimumPackingPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextMinimumParametersByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextGoodsRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTurnoverByPeriodBonusPercentageByRangeByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPreparedDataByQuantityByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		RebatesCalculation.AddQueryTextPreparedDataPlanDefinition(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPreparedQuantityData(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataForProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextBaseOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCalculationOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextProportionalDistributionByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextRoundingProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfFinalProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextTotalsByScaleRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextErrorCorrectionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsPurchasesQuantityFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextOfGoodsMinimumPackingPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextMinimumParametersByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextGoodsRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataPlanDefinition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		RebatesCalculation.AddQueryTextPreparedQuantityDataByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
	Else
		RebatesCalculation.AddQueryTextPreparedQuantityData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	EndIf;
	
	RebatesCalculation.AddQueryTextTurnoverByPortions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPortionsCumulativeTotal(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_TurnoverByPortions",
		"VT_TurnoverByPortionsCumulativeTotal",
		True);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextPortionOfExceedingRangeLimit(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverByPortionsCumulativeTotal",
			"VT_PortionExceedingLimit");
		
	Else
		
		RebatesCalculation.AddQueryTextPortionOfLimitExceeded(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverByPortionsCumulativeTotal",
			"VT_PortionExceedingLimit");
		
	EndIf;
	
	RebatesCalculation.AddQueryTextPreviousPortionBeforeLimitWasExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverUntilLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverBySubPortions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPortionsCumulativeTotal(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_RevolutionsBySubPortions",
		"VT_TurnoverBySubPortionsCumulativeTotal");
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextPortionOfExceedingRangeLimit(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverBySubPortionsCumulativeTotal",
			"VT_SubPortionOfExceedingLimit");
		
	Else
		
		RebatesCalculation.AddQueryTextPortionOfLimitExceeded(
			RebateConditionsParameters,
			OptionParameters,
			QueriesTexts,
			"VT_TurnoverBySubPortionsCumulativeTotal",
			"VT_SubPortionOfExceedingLimit");
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSubPortionOfExceedingLimitRevolutionsPerServing(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreviousSubPortionBeforeLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextSubPortionOfExceedingLimitTurnoverToSubPortion(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverPerPortionExceedingLimit(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_SubPortionOfExceedingLimitRevolutionsToSubPortion",
		"VT_TurnoverPerSubPortionExceedingLimit",
		RebatesCalculation.SubPortionOfCumulativeTotal());
	
	RebatesCalculation.AddQueryTextExceedingLimitCumulativeTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		RebatesCalculation.AddQueryTextLinesAtBoundariesOfRangesByNumber(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPrioritiesOnRangeBoundaries(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextPrioritiesBalancesOnRangeBoundaries(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
		RebatesCalculation.AddQueryTextDistributionOfRowsByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextTotalsOfDatabaseByWidthOfRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextCorrectionOfBaseErrorByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextBalancesOfDatabaseByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
		RebatesCalculation.AddQueryTextDataForBonusDistributionByFIFORanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextBonusTotalsByRangeWidth(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextFinalFIFODistributionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		RebatesCalculation.AddQueryTextMinimumPriorityOfPlanExecutionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextDataForDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextDataForDistributionByFIFOBonusAmountByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextRoundingDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextFinalFIFODistributionByNumber(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GeneratePurchaseQueryTextsQuantityInAggregate(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocuments(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsAllGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsGoodsSold(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMissingPackageContents(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithPackageData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriodPackageConditionsNotMet(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPeriodPackageConditionsAreMet(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataByQuantityInAggregate(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GeneratePurchaseQueryTextsPackageOffer(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	If RebateConditionsParameters.DistributionByFIFO Then
		
		GenerateQueryTextsPurchasesPackageOfferFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	Else
		
		GeneratePurchaseQueryTextsPackageOfferProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsPurchasesPackageOfferFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocuments(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsAllGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsGoodsSold(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMissingPackageContents(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithPackageData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMultiplicityOfGoodsPackage(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextNumberOfGoodsPackages(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataForPackageOffer(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverByPortions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPortionsCumulativeTotal(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_TurnoverByPortions",
		"VT_TurnoverByPortionsCumulativeTotal",
		True);
	RebatesCalculation.AddQueryTextPortionOfLimitExceeded(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_TurnoverByPortionsCumulativeTotal",
		"VT_PortionExceedingLimit");
	RebatesCalculation.AddQueryTextPreviousPortionBeforeLimitWasExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverUntilLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverBySubPortions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverByPortionsCumulativeTotal(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_RevolutionsBySubPortions",
		"VT_TurnoverBySubPortionsCumulativeTotal");
	RebatesCalculation.AddQueryTextPortionOfLimitExceeded(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_TurnoverBySubPortionsCumulativeTotal",
		"VT_SubPortionOfExceedingLimit");
	RebatesCalculation.AddQueryTextSubPortionOfExceedingLimitRevolutionsPerServing(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreviousSubPortionBeforeLimitIsExceeded(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextSubPortionOfExceedingLimitTurnoverToSubPortion(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextTurnoverPerPortionExceedingLimit(
		RebateConditionsParameters,
		OptionParameters,
		QueriesTexts,
		"VT_SubPortionOfExceedingLimitRevolutionsToSubPortion",
		"VT_TurnoverPerSubPortionExceedingLimit",
		RebatesCalculation.SubPortionOfCumulativeTotal());
	
	RebatesCalculation.AddQueryTextExceedingLimitCumulativeTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMinimumPriorityOfPlanExecutionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataForDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataForDistributionByFIFOBonusAmountByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextRoundingDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextFinalFIFODistributionByNumber(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GeneratePurchaseQueryTextsPackageOfferProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers);
	
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocuments(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsAllGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextParticipantsPeriodsDocumentsGoodsSold(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMissingPackageContents(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithPackageData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMultiplicityOfGoodsPackage(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextNumberOfGoodsPackages(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPreparedDataForPackageOffer(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDataTakingIntoAccountExceedingLimit(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextDataForProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextBaseOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCalculationOfProportionalDistributionByQuantity(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextProportionalDistributionByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextRoundingProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfFinalProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure AddQueryTextSuppliers(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	// The table VT-Deliverer will preferably be transferred to the data processor via the manager of the time tables
	
	QueryText =
	"SELECT
	|	Vendors.Counterparty AS Counterparty,
	|	Vendors.Partner AS Partner,
	|	Vendors.Contract AS Contract,
	|	Vendors.Terms AS Terms,
	|	Vendors.ValidOnDate AS ValidOnDate,
	|	ENDOFPERIOD(Vendors.ValidTo, DAY) AS ValidTo,
	|	&PriorityExpression AS Priority
	|INTO TT_Vendors
	|FROM
	|	VT_SuppliersInAdvance AS Vendors";
	
	PriorityExpression =
	"CASE
	|		WHEN Vendors.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN 1
	|		ELSE 0
	|	END + CASE
	|		WHEN Vendors.Partner = VALUE(Catalog.Partners.EmptyRef)
	|			THEN 1
	|		ELSE 0
	|	END + CASE
	|		WHEN Vendors.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN 1
	|		ELSE 0
	|	END + CASE
	|		WHEN Vendors.Terms = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|			THEN 1
	|		ELSE 0
	|	END";
	QueryText = StrReplace(QueryText, "&PriorityExpression", PriorityExpression);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

// Parameters:
//  VendorTable - ValueTable
// 
// Returns:
//  ValueTable - In all columns, True means a filled supplier field, False means an empty one:
//  * Counterparty - Boolean
//  * Partner - Boolean
//  * Contract - Boolean
//  * Terms - Boolean
//
Function CombinationsOfSupplierFields(VendorTable)
	
	Combinations = New ValueTable;
	Combinations.Columns.Add("Priority", Common.TypeDescriptionNumber(1, 0, AllowedSign.Nonnegative));
	
	ColumnsNames = New Array; // Array of String
	ColumnsNames.Add("Counterparty");
	ColumnsNames.Add("Partner");
	ColumnsNames.Add("Contract");
	ColumnsNames.Add("Terms");
	
	For Each ColumnName In ColumnsNames Do
		Combinations.Columns.Add(ColumnName, New TypeDescription("Boolean"));
	EndDo;
	
	For Each SupplierString In VendorTable Do
		
		StringOfCombinations = Combinations.Add();
		For Each ColumnName In ColumnsNames Do
			
			StringOfCombinations[ColumnName] = ValueIsFilled(SupplierString[ColumnName]);
			If Not StringOfCombinations[ColumnName] Then
				StringOfCombinations.Priority = StringOfCombinations.Priority + 1;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ColumnsNames.Add("Priority");
	Combinations.GroupBy(StrConcat(ColumnsNames, ","));
	Combinations.Sort("Priority Asc");
	Combinations.Columns.Delete("Priority");
	
	Return Combinations;
	
EndFunction

Procedure AddPurchaseQueryTextInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	QueryTemplate =
	"SELECT
	|	Purchases.Period AS Period,
	|	&ExpressionPeriod AS CalculationPeriod,
	|	Purchases.LineNumber AS LineNumber,
	|	&ExpressionDocumentLogger AS DocumentRecorder,
	|	Purchases.Organization AS Organization,
	|	Purchases.Counterparty AS Counterparty,
	|	Purchases.Partner AS Partner,
	|	Purchases.Contract AS Contract,
	|	Purchases.Terms AS Terms,
	|	Purchases.Warehouse AS Warehouse,
	|	RS_InventoryAccountingAnalytics.Products AS Products,
	|	RS_InventoryAccountingAnalytics.Characteristic AS Characteristic,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * Purchases.Count AS Count,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * Purchases.Sum AS AmountOfTurnoverOfMansWithVAT,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * Purchases.SumCompl AS AmountOfTurnoverOfLocalWithVAT,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * Purchases.AmountInARAPCurrency AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * Purchases.AmountExcludingVAT AS ManSTurnoverAmountExcludingVAT,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * Purchases.LocalAmountExcludingVAT AS AmountOfTurnoverIsLocalWithoutVAT,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * Purchases.AmountExcludingVATInARAPCurrency AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * CASE
	|		WHEN VT_RBParameters.ConsiderVAT
	|			THEN Purchases.Sum
	|		ELSE Purchases.AmountExcludingVAT
	|	END AS Sum,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * CASE
	|		WHEN VT_RBParameters.ConsiderVAT
	|			THEN Purchases.SumCompl
	|		ELSE Purchases.LocalAmountExcludingVAT
	|	END AS SumCompl,
	|	CASE
	|		WHEN Purchases.Recorder REFS Document.ReturnOfGoodsToVendor
	|			AND Purchases.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN -1
	|		ELSE 1
	|	END * CASE
	|		WHEN VT_RBParameters.ConsiderVAT
	|			THEN Purchases.AmountInARAPCurrency
	|		ELSE Purchases.AmountExcludingVATInARAPCurrency
	|	END AS AmountInARAPCurrency,
	|	VT_RBParameters.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_RBParameters.BonusPercent AS BonusPercent,
	|	VT_RBParameters.GoodsIndicator AS GoodsIndicator,
	|	VT_RBParameters.PartyCountDetails AS PartyCountDetails,
	|	VT_RBParameters.ConditionFrequency AS ConditionFrequency,
	|	VT_RBParameters.AccrualFrequency AS AccrualFrequency,
	|	VT_RBParameters.ConsiderVAT AS ConsiderVAT,
	|	VT_RBParameters.Currency AS CurrencyOfConditions,
	|	Purchases.ARAPCurrency AS ARAPCurrency,
	|	VT_RBParameters.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_RBParameters.FIFODistribution AS FIFODistribution,
	|	VT_RBParameters.SumPlan AS SumPlan,
	|	VT_RBParameters.BaseOfCalculation AS BaseOfCalculation,
	|	VT_RBParameters.SelectionOfGoodsSelected AS SelectionOfGoodsSelected,
	|	VT_RBParameters.SelectionOfGoodsOtherThanSelected AS SelectionOfGoodsOtherThanSelected,
	|	VT_RBParameters.SelectionOfGoodsWithoutRestrictions AS SelectionOfGoodsWithoutRestrictions,
	|	VT_RBParameters.SelectionOfParticipantsSelected AS SelectionOfParticipantsSelected,
	|	VT_RBParameters.SelectionOfParticipantsExceptSelected AS SelectionOfParticipantsExceptSelected,
	|	&ExpressionSupplierPriority AS SupplierPriority
	|INTO VT_PurchasesInAdvance
	|FROM
	|	AccumulationRegister.Purchases AS Purchases
	|		LEFT JOIN VT_RBParameters AS VT_RBParameters
	|		ON TRUE
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS RS_InventoryAccountingAnalytics
	|		ON Purchases.ItemsLocationAttributes = RS_InventoryAccountingAnalytics.DimensionKey
	|		LEFT JOIN &TT_Vendors AS TT_Vendors ON TRUE
	|WHERE
	|	&SelectionConditionByDocumentTypeHouseholdOfOperation
	|	AND Purchases.Period BETWEEN &StartDate AND &EndDate
	|	AND Purchases.Organization IN (&Organization)
	|	AND &SelectionCriteriaForVendors
	|	AND &ConditionOfSelectionOfGoods
	|	AND Purchases.InventoryType <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND &CurrencySelectionCriteria
	|	AND &SelectionConditionByCounterparty
	|	AND &PartnerSelectionCriteria";
	
	If RebateConditionsParameters.Goods = Enums.RebatesLists.Selected_ Then
		
		ConditionOfSelectionOfGoods =
		"Purchases.ItemsLocationAttributes IN
		|			(SELECT
		|				TT_ItemsLocationAttributes.DimensionKey
		|			FROM
		|				TT_ItemsLocationAttributes AS TT_ItemsLocationAttributes)";
		
	ElsIf RebateConditionsParameters.Goods = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		ConditionOfSelectionOfGoods =
		"NOT Purchases.ItemsLocationAttributes IN
		|			(SELECT
		|				TT_ItemsLocationAttributes.DimensionKey
		|			FROM
		|				TT_ItemsLocationAttributes AS TT_ItemsLocationAttributes)";
		
	Else
		
		ConditionOfSelectionOfGoods = "TRUE";
		
	EndIf;
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionByCounterparty =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE Purchases.Counterparty = &Counterparty
		|END";
		PartnerSelectionCriteria =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE Purchases.Partner = &Partner
		|END";
		
	Else
		
		SelectionConditionByCounterparty = "TRUE";
		PartnerSelectionCriteria = "TRUE";
		
	EndIf;
	
	If RebateConditionsParameters.GoodsIndicator = Enums.TargetSalesIndicatorsOfRebatesByGoods.Sum
	   And RebateConditionsParameters.BaseOfCalculation = Enums.RebateCalculationBases.PurchaseAmountARAPAccounting Then
		
		CurrencySelectionCriteria = "Purchases.ARAPCurrency = VT_RBParameters.Currency"; // @query-part
		
	Else
		
		CurrencySelectionCriteria = "TRUE";
		
	EndIf;
	
	ExpressionPeriod = RebatesCalculation.ExpressionCalculationPeriod(RebateConditionsParameters, True);
	
	ConnectionsWithVendors = ConnectionsToVendorTableForAllFieldCombinations(CombinationsOfSuppliers, "Purchases");
	SelectionCriteriaForVendors = ConditionsForSelectingPurchasesBasedOnCombinationsOfSupplierFields(CombinationsOfSuppliers);
	ExpressionSupplierPriority = ExpressionSupplierPriorityByCombinationsOfSupplierFields(CombinationsOfSuppliers);
	
	TypesOfLoggers = TypesOfPurchaseSampleRegistrars();
	SubqueryTexts_ = New Array; // Array of String
	SubqueryNumber = 1;
	
	For DocumentTypeIndex = 0 To TypesOfLoggers.UBound() Do
		
		DocumentType = TypesOfLoggers[DocumentTypeIndex];
		ExpressionDocumentLogger = "CAST(Purchases.Recorder AS " + DocumentType.FullName() +")";
		SelectionConditionByDocumentTypeHouseholdOfOperation = ProcurementSelectionCriteriaByDocumentTypeHouseholdOfOperation(DocumentType);
		
		QueryText = QueryTemplate;
		
		QueryText = StrReplace(QueryText, "&ExpressionPeriod", ExpressionPeriod);
		QueryText = StrReplace(QueryText, "&ExpressionDocumentLogger", ExpressionDocumentLogger);
		QueryText = StrReplace(QueryText, "&ExpressionSupplierPriority", ExpressionSupplierPriority);
		
		QueryText = StrReplace(
			QueryText, "LEFT JOIN &TT_Vendors AS TT_Vendors ON TRUE", ConnectionsWithVendors);
		
		QueryText = StrReplace(
			QueryText, "&SelectionConditionByDocumentTypeHouseholdOfOperation", SelectionConditionByDocumentTypeHouseholdOfOperation);
		QueryText = StrReplace(QueryText, "&ConditionOfSelectionOfGoods", ConditionOfSelectionOfGoods);
		QueryText = StrReplace(QueryText, "&CurrencySelectionCriteria", CurrencySelectionCriteria);
		QueryText = StrReplace(QueryText, "&SelectionConditionByCounterparty", SelectionConditionByCounterparty);
		QueryText = StrReplace(QueryText, "&PartnerSelectionCriteria", PartnerSelectionCriteria);
		QueryText = StrReplace(QueryText, "&SelectionCriteriaForVendors", SelectionCriteriaForVendors);
		
		If SubqueryNumber > 1 Then
			
			QueryText = StrReplace(QueryText, "INTO VT_PurchasesInAdvance", "");
			
		EndIf;
		
		SubqueryTexts_.Add(QueryText);
		SubqueryNumber = SubqueryNumber + 1;
		
	EndDo;
	
	SubquerySeparator_ = RebatesCalculation.SubquerySeparator_();
	QueryText = StrConcat(SubqueryTexts_, SubquerySeparator_);
	QueriesTexts.Add(QueryText);
	
EndProcedure

Function ProcurementSelectionCriteriaByDocumentTypeHouseholdOfOperation(DocumentType)
	
	BusinessTransactions = New Array; // Array of EnumRef.BusinessTransactions
	
	If DocumentType = Metadata.Documents.ReturnOfGoodsToVendor Then
		
		BusinessTransactions.Add(Enums.BusinessTransactions.ReturnOfGoodsToVendor);
		
	ElsIf DocumentType = Metadata.Documents.RedemptionOfGoodsFromStorage Then
		
		BusinessTransactions.Add(Enums.BusinessTransactions.RedemptionOfGoodsFromStorage);
		
	ElsIf DocumentType = Metadata.Documents.PurchaseAdjustment Then
		
		BusinessTransactions.Clear(); // Everything is BT
		
	ElsIf DocumentType = Metadata.Documents.VendorInvoice Then
		
		BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEU);
		BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorLocal);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseByImport);
		BusinessTransactions.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		
	Else
		
		DocumentTypeByString = String(DocumentType);
		ErrorTemplate = NStr("vi = 'Sai kiểu chứng từ mua hàng ""%1""';
							|ru = 'Некорректный тип документа закупок ""%1""';
							|en = 'Incorrect purchase document type: %1'; fa = 'Incorrect purchase document type: %1';
							|it = 'Некорректный тип документа закупок ""%1""';
							|pl = 'Incorrect purchase document type: %1';
							|tr = '""%1"" satın alma belge türü yanlış'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate, DocumentTypeByString);
		Raise ErrorText;
		
	EndIf;
	
	ConditionText = "Purchases.Recorder Ref " + DocumentType.FullName();
	
	If BusinessTransactions.Count() > 0 Then
		
		BusinessOfOperationsValueStrings = New Array; // Array of String
		For Each BusinessOperation In BusinessTransactions Do
			
			ValueRow = "VALUE(" + GetPredefinedValueFullName(BusinessOperation) + ")";
			BusinessOfOperationsValueStrings.Add(ValueRow);
			
		EndDo;
		
		BusinessOperationsOfOperationsArrayString = StrConcat(BusinessOfOperationsValueStrings, "," + Chars.LF);
		ConditionText = ConditionText + Chars.LF + " AND Purchases.BusinessOperation IN ("
			+ Chars.LF + BusinessOperationsOfOperationsArrayString + ")";
		
	EndIf;
	
	Return ConditionText;
	
EndFunction

Function ConnectionsToVendorTableForAllFieldCombinations(CombinationsOfSuppliers, Left_Table, AddConditionByPriority = False)
	
	BlankValues = New Map;
	BlankValues.Insert("Counterparty", "VALUE(Catalog.Counterparties.EmptyRef)");
	BlankValues.Insert("Partner", "VALUE(Catalog.Partners.EmptyRef)");
	BlankValues.Insert("Contract", "VALUE(Catalog.CounterpartyContracts.EmptyRef)");
	BlankValues.Insert("Terms", "VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)");
	
	CombinationTexts = New Array; // Array of String
	
	For CombinationIndex = 0 To CombinationsOfSuppliers.Count() - 1 Do
		
		FieldCombinationString = CombinationsOfSuppliers[CombinationIndex];
		CombinationNumberByString = String(CombinationIndex + 1);
		
		CombinationText = "LEFT JOIN TT_Vendors AS TT_SuppliersCombination&CombinationNumber
		|ON ";
		CombinationText = StrReplace(CombinationText, "&CombinationNumber", CombinationNumberByString);
		
		StringsWithCondition = New Array; // Array of String
		
		If AddConditionByPriority Then
			
			ConditionString = "&Left_Table.SupplierPriority = TT_SuppliersCombination&CombinationNumber.Priority";
			ConditionString = StrReplace(ConditionString, "&Left_Table", Left_Table);
			ConditionString = StrReplace(ConditionString, "&CombinationNumber", CombinationNumberByString);
			StringsWithCondition.Add(ConditionString);
			
		EndIf;
		
		For Each Column In CombinationsOfSuppliers.Columns Do
			
			If FieldCombinationString[Column.Name] Then
				
				ConditionString = "&Left_Table.&ColumnName = TT_SuppliersCombination&CombinationNumber.&ColumnName";
				ConditionString = StrReplace(ConditionString, "&Left_Table", Left_Table);
				ConditionString = StrReplace(ConditionString, "&ColumnName", Column.Name);
				ConditionString = StrReplace(ConditionString, "&CombinationNumber", CombinationNumberByString);
				StringsWithCondition.Add(ConditionString);
				
				ConditionString = "TT_SuppliersCombination&CombinationNumber.&ColumnName <> &EmptyColumnValue";
				EmptyColumnValue = BlankValues[Column.Name];
				ConditionString = StrReplace(ConditionString, "&EmptyColumnValue", EmptyColumnValue);
				ConditionString = StrReplace(ConditionString, "&ColumnName", Column.Name);
				ConditionString = StrReplace(ConditionString, "&CombinationNumber", CombinationNumberByString);
				StringsWithCondition.Add(ConditionString);
				
			Else
				
				ConditionString = "TT_SuppliersCombination&CombinationNumber.&ColumnName = &EmptyColumnValue";
				EmptyColumnValue = BlankValues[Column.Name];
				ConditionString = StrReplace(ConditionString, "&EmptyColumnValue", EmptyColumnValue);
				ConditionString = StrReplace(ConditionString, "&ColumnName", Column.Name);
				ConditionString = StrReplace(ConditionString, "&CombinationNumber", CombinationNumberByString);
				StringsWithCondition.Add(ConditionString);
				
			EndIf;
			
		EndDo;
		
		CombinationText = CombinationText + StrConcat(StringsWithCondition, Chars.LF + "And ");
		
		CombinationTexts.Add(CombinationText);
		
	EndDo;
	
	QueryText = StrConcat(CombinationTexts, Chars.LF + Chars.LF) + Chars.LF;
	
	Return QueryText;
	
EndFunction

Function ConditionsForSelectingPurchasesBasedOnCombinationsOfSupplierFields(CombinationsOfSuppliers)
	
	CombinationTexts = New Array; // Array of String
	
	For CombinationIndex = 0 To CombinationsOfSuppliers.Count() - 1 Do
		
		CombinationNumberByString = String(CombinationIndex + 1);
		CombinationText = "TT_SuppliersCombination&CombinationNumber.Priority IS NOT NULL";
		CombinationText = StrReplace(CombinationText, "&CombinationNumber", CombinationNumberByString);
		CombinationTexts.Add(CombinationText);
		
	EndDo;
	
	QueryText = "(" + StrConcat(CombinationTexts, Chars.LF + "OR ") + ")";
	
	Return QueryText;
	
EndFunction

Function ExpressionSupplierPriorityByCombinationsOfSupplierFields(CombinationsOfSuppliers)
	
	CombinationTexts = New Array; // Array of String
	
	For CombinationIndex = 0 To CombinationsOfSuppliers.Count() - 1 Do
		
		CombinationNumberByString = String(CombinationIndex + 1);
		CombinationText = "WHEN TT_SuppliersCombination&CombinationNumber.Priority IS NOT NULL
		|	THEN TT_SuppliersCombination&CombinationNumber.Priority";
		CombinationText = StrReplace(CombinationText, "&CombinationNumber", CombinationNumberByString);
		CombinationTexts.Add(CombinationText);
		
	EndDo;
	
	QueryText =
		"CASE
		|"
		+ StrConcat(CombinationTexts, Chars.LF)
		+ "
		|END";
	
	Return QueryText;
	
EndFunction

Procedure AddQueryTextOfPurchaseWithSelectionBySupplier(RebateConditionsParameters, OptionParameters, QueriesTexts, CombinationsOfSuppliers)
	
	QueryText =
	"SELECT DISTINCT
	|	VT_PurchasesInAdvance.Period AS Period,
	|	VT_PurchasesInAdvance.CalculationPeriod AS CalculationPeriod,
	|	VT_PurchasesInAdvance.DocumentRecorder AS DocumentRecorder,
	|	VT_PurchasesInAdvance.Organization AS Organization,
	|	VT_PurchasesInAdvance.Counterparty AS Counterparty,
	|	VT_PurchasesInAdvance.Partner AS Partner,
	|	VT_PurchasesInAdvance.Contract AS Contract,
	|	VT_PurchasesInAdvance.Terms AS Terms,
	|	VT_PurchasesInAdvance.Warehouse AS Warehouse,
	|	VT_PurchasesInAdvance.Products AS Products,
	|	VT_PurchasesInAdvance.Characteristic AS Characteristic,
	|	SUM(VT_PurchasesInAdvance.Count) AS Count,
	|	SUM(VT_PurchasesInAdvance.AmountOfTurnoverOfMansWithVAT) AS AmountOfTurnoverOfMansWithVAT,
	|	SUM(VT_PurchasesInAdvance.AmountOfTurnoverOfLocalWithVAT) AS AmountOfTurnoverOfLocalWithVAT,
	|	SUM(VT_PurchasesInAdvance.AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT) AS AmountOfTurnoverInCurrencyOfMutualSettlementsWithVAT,
	|	SUM(VT_PurchasesInAdvance.ManSTurnoverAmountExcludingVAT) AS ManSTurnoverAmountExcludingVAT,
	|	SUM(VT_PurchasesInAdvance.AmountOfTurnoverIsLocalWithoutVAT) AS AmountOfTurnoverIsLocalWithoutVAT,
	|	SUM(VT_PurchasesInAdvance.AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT) AS AmountOfTurnoverInCurrencyOfMutualSettlementsExcludingVAT,
	|	SUM(VT_PurchasesInAdvance.Sum) AS Sum,
	|	SUM(VT_PurchasesInAdvance.SumCompl) AS SumCompl,
	|	SUM(VT_PurchasesInAdvance.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	VT_PurchasesInAdvance.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_PurchasesInAdvance.BonusPercent AS BonusPercent,
	|	VT_PurchasesInAdvance.GoodsIndicator AS GoodsIndicator,
	|	VT_PurchasesInAdvance.PartyCountDetails AS PartyCountDetails,
	|	VT_PurchasesInAdvance.ConditionFrequency AS ConditionFrequency,
	|	VT_PurchasesInAdvance.AccrualFrequency AS AccrualFrequency,
	|	VT_PurchasesInAdvance.ConsiderVAT AS ConsiderVAT,
	|	VT_PurchasesInAdvance.CurrencyOfConditions AS CurrencyOfConditions,
	|	VT_PurchasesInAdvance.ARAPCurrency AS ARAPCurrency,
	|	VT_PurchasesInAdvance.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	VT_PurchasesInAdvance.FIFODistribution AS FIFODistribution,
	|	VT_PurchasesInAdvance.SumPlan AS SumPlan,
	|	VT_PurchasesInAdvance.BaseOfCalculation AS BaseOfCalculation,
	|	VT_PurchasesInAdvance.SelectionOfGoodsSelected AS SelectionOfGoodsSelected,
	|	VT_PurchasesInAdvance.SelectionOfGoodsOtherThanSelected AS SelectionOfGoodsOtherThanSelected,
	|	VT_PurchasesInAdvance.SelectionOfGoodsWithoutRestrictions AS SelectionOfGoodsWithoutRestrictions,
	|	VT_PurchasesInAdvance.SelectionOfParticipantsSelected AS SelectionOfParticipantsSelected,
	|	VT_PurchasesInAdvance.SelectionOfParticipantsExceptSelected AS SelectionOfParticipantsExceptSelected
	|INTO TT_SalesPurchases
	|FROM
	|	VT_PurchasesInAdvance AS VT_PurchasesInAdvance
	|	LEFT JOIN &TT_Vendors AS TT_Vendors ON TRUE
	|WHERE
	|	&ConditionForVendorSPeriod
	|
	|GROUP BY
	|	VT_PurchasesInAdvance.Period,
	|	VT_PurchasesInAdvance.CalculationPeriod,
	|	VT_PurchasesInAdvance.DocumentRecorder,
	|	VT_PurchasesInAdvance.Organization,
	|	VT_PurchasesInAdvance.Counterparty,
	|	VT_PurchasesInAdvance.Partner,
	|	VT_PurchasesInAdvance.Contract,
	|	VT_PurchasesInAdvance.Terms,
	|	VT_PurchasesInAdvance.Warehouse,
	|	VT_PurchasesInAdvance.Products,
	|	VT_PurchasesInAdvance.Characteristic,
	|	VT_PurchasesInAdvance.ConditionOfRebateBonusIs,
	|	VT_PurchasesInAdvance.BonusPercent,
	|	VT_PurchasesInAdvance.GoodsIndicator,
	|	VT_PurchasesInAdvance.PartyCountDetails,
	|	VT_PurchasesInAdvance.ConditionFrequency,
	|	VT_PurchasesInAdvance.AccrualFrequency,
	|	VT_PurchasesInAdvance.ConsiderVAT,
	|	VT_PurchasesInAdvance.CurrencyOfConditions,
	|	VT_PurchasesInAdvance.ARAPCurrency,
	|	VT_PurchasesInAdvance.RestrictAccrualOverPlan,
	|	VT_PurchasesInAdvance.FIFODistribution,
	|	VT_PurchasesInAdvance.SumPlan,
	|	VT_PurchasesInAdvance.BaseOfCalculation,
	|	VT_PurchasesInAdvance.SelectionOfGoodsSelected,
	|	VT_PurchasesInAdvance.SelectionOfGoodsOtherThanSelected,
	|	VT_PurchasesInAdvance.SelectionOfGoodsWithoutRestrictions,
	|	VT_PurchasesInAdvance.SelectionOfParticipantsSelected,
	|	VT_PurchasesInAdvance.SelectionOfParticipantsExceptSelected";
	
	ConnectionsWithVendors = ConnectionsToVendorTableForAllFieldCombinations(
		CombinationsOfSuppliers, "VT_PurchasesInAdvance", True);
	
	ConditionForVendorSPeriod = ProcurementSelectionCriteriaForVendorSPeriod(CombinationsOfSuppliers);
	
	QueryText = StrReplace(
		QueryText, "LEFT JOIN &TT_Vendors AS TT_Vendors ON TRUE", ConnectionsWithVendors);
	QueryText = StrReplace(QueryText, "&ConditionForVendorSPeriod", ConditionForVendorSPeriod);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Function ProcurementSelectionCriteriaForVendorSPeriod(CombinationsOfSuppliers)
	
	CombinationTexts = New Array; // Array of String
	
	For CombinationIndex = 0 To CombinationsOfSuppliers.Count() - 1 Do
		
		CombinationNumberByString = String(CombinationIndex + 1);
		CombinationText = "TT_SuppliersCombination&CombinationNumber.Priority IS NOT NULL
		|	AND (VT_PurchasesInAdvance.Period BETWEEN TT_SuppliersCombination&CombinationNumber.ValidOnDate
		|		AND TT_SuppliersCombination&CombinationNumber.ValidTo)";
		CombinationText = StrReplace(CombinationText, "&CombinationNumber", CombinationNumberByString);
		CombinationTexts.Add(CombinationText);
		
	EndDo;
	
	QueryText = "(" + StrConcat(CombinationTexts,  Chars.LF + "OR ") + ")";
	
	Return QueryText;
	
EndFunction

Procedure AddQueryTextOfPurchaseMerger(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	SummaryData.Period AS Period,
	|	SummaryData.CalculationPeriod AS CalculationPeriod,
	|	SummaryData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SummaryData.GoodsIndicator AS GoodsIndicator,
	|	SummaryData.PartyCountDetails AS PartyCountDetails,
	|	SummaryData.ConditionFrequency AS ConditionFrequency,
	|	TT_DiscountPercentage.Counterparty AS CounterpartySupplier,
	|	TT_DiscountPercentage.Partner AS PartnerVendor,
	|	TT_DiscountPercentage.Contract AS SupplierAgreement,
	|	TT_DiscountPercentage.Terms AS SupplierTerms,
	|	SummaryData.DocumentRecorder AS DocumentRecorder,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	SummaryData.Organization AS Organization,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS CounterpartyCustomer,
	|	SummaryData.Products AS Products,
	|	SummaryData.UnitOfMeasure AS UnitOfMeasure,
	|	SummaryData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	SummaryData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	SummaryData.Characteristic AS Characteristic,
	|	SummaryData.PropertyValue AS PropertyValue,
	|	SummaryData.PresentationOfRangeUnit AS PresentationOfRangeUnit,
	|	SummaryData.RangeNumber AS RangeNumber,
	|	SummaryData.RangeFrom AS RangeFrom,
	|	SummaryData.RangeBy AS RangeBy,
	|	SummaryData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	SummaryData.PlanIsFulfilled AS PlanIsFulfilled,
	|	SummaryData.Count AS CountTurnover,
	|	0 AS CountBalance,
	|	SummaryData.Currency AS Currency,
	|	SummaryData.BasePrice AS BasePrice,
	|	SummaryData.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	SummaryData.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	CAST(SummaryData.Count * SummaryData.BasePrice AS NUMBER(31, 2)) AS AmountInBasePrices,
	|	SummaryData.BonusPercent AS BonusPercent,
	|	SummaryData.SumPlan AS SumPlan,
	|	SummaryData.CountPlan AS CountPlan,
	|	SummaryData.CalculationBase AS CalculationBase,
	|	SummaryData.AmountBonus AS AmountBonus,
	|	SummaryData.NumberOfPackages_ AS NumberOfPackages_,
	|	0 AS BonusAmountPerUnit
	|INTO TT_Merging
	|FROM
	|	TT_SummaryData AS SummaryData
	|	LEFT JOIN TT_DiscountPercentage AS TT_DiscountPercentage
	|	ON SummaryData.DocumentRecorder = TT_DiscountPercentage.DocumentRecorder
	|		AND SummaryData.LineNumber = TT_DiscountPercentage.LineNumber";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

#EndRegion

#Region Balance

Procedure GenerateQueryTextsBasedOnBalances(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfInventoryInventoryLocationAttributeByWarehouse(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextBalance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextBalancesByItem(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextGoodsWithoutBalance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextMergeByBalance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure AddQueryTextOfInventoryInventoryLocationAttributeByWarehouse(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	ItemsLocationAttributes.DimensionKey AS DimensionKey
	|INTO TT_ItemsLocationAttributes
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
	|		INNER JOIN TT_Goods AS TT_Goods
	|		ON ItemsLocationAttributes.Products = TT_Goods.Products
	|		AND ItemsLocationAttributes.Characteristic = TT_Goods.Characteristic
	|WHERE
	|	&SelectionConditionsForWarehouses";
	
	If RebateConditionsParameters.Warehouses = Enums.RebatesLists.Selected_ Then
		
		SelectionConditionsForWarehouses =
		"ItemsLocationAttributes.StorageLocation IN
		|		(SELECT
		|			VendorRebatesWarehouses.Warehouse AS Warehouse
		|		FROM
		|			InformationRegister.VendorRebatesWarehouses AS VendorRebatesWarehouses
		|		WHERE
		|			VendorRebatesWarehouses.TermDocument = &SourceDocument_)";
		
	ElsIf RebateConditionsParameters.Warehouses = Enums.RebatesLists.ExceptForSelectedOnes Then
		
		SelectionConditionsForWarehouses =
		"ItemsLocationAttributes.StorageLocation NOT IN
		|		(SELECT
		|			VendorRebatesWarehouses.Warehouse AS Warehouse
		|		FROM
		|			InformationRegister.VendorRebatesWarehouses AS VendorRebatesWarehouses
		|		WHERE
		|			VendorRebatesWarehouses.TermDocument = &SourceDocument_)";
		
	Else
		
		SelectionConditionsForWarehouses = "TRUE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionConditionsForWarehouses", SelectionConditionsForWarehouses);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextBalance(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	CompanyGoodsBalance.Organization AS Organization,
	|	RS_InventoryAccountingAnalytics.StorageLocation AS Warehouse,
	|	RS_InventoryAccountingAnalytics.Products AS Products,
	|	RS_InventoryAccountingAnalytics.Characteristic AS Characteristic,
	|	CompanyGoodsBalance.CountBalance AS CountBalance
	|INTO TT_Balance
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			&BalanceDateBorder,
	|			ItemsLocationAttributes IN
	|					(SELECT
	|						TT_ItemsLocationAttributes.DimensionKey
	|					FROM
	|						TT_ItemsLocationAttributes AS TT_ItemsLocationAttributes)
	|				AND Organization IN (&Organization)
	|				AND InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)) AS CompanyGoodsBalance
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS RS_InventoryAccountingAnalytics
	|		ON CompanyGoodsBalance.ItemsLocationAttributes = RS_InventoryAccountingAnalytics.DimensionKey
	|
	|INDEX BY
	|	Products,
	|	Characteristic";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextBalancesByItem(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	TT_Balance.Products AS Products,
	|	TT_Balance.Characteristic AS Characteristic,
	|	SUM(TT_Balance.CountBalance) AS QuantityBalanceTotal
	|INTO TT_BalancesByPositions
	|FROM
	|	TT_Balance AS TT_Balance
	|
	|GROUP BY
	|	TT_Balance.Products,
	|	TT_Balance.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextGoodsWithoutBalance(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	TT_Goods.Products AS Products,
	|	CAST(TT_Goods.Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
	|	TT_Goods.Characteristic AS Characteristic,
	|	TT_Goods.BonusPercent AS BonusPercent,
	|	TT_Goods.CountPlan AS CountPlan,
	|	TT_Goods.BonusPerUnit AS BonusPerUnit
	|INTO VT_GoodsWithoutBalance
	|FROM
	|	TT_Goods AS TT_Goods
	|	LEFT JOIN TT_Balance AS TT_Balance
	|		ON TT_Goods.Products = TT_Balance.Products
	|			AND TT_Goods.Characteristic = TT_Balance.Characteristic
	|WHERE
	|	TT_Balance.CountBalance IS NULL";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextMergeByBalance(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	&DateOfRemainingGoods AS Period,
	|	&DateOfRemainingGoods AS CalculationPeriod,
	|	VT_RBParameters.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_RBParameters.GoodsIndicator AS GoodsIndicator,
	|	VT_RBParameters.PartyCountDetails AS PartyCountDetails,
	|	VT_RBParameters.ConditionFrequency AS ConditionFrequency,
	|	ISNULL(VendorRebatesVendors.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) AS CounterpartySupplier,
	|	ISNULL(VendorRebatesVendors.Partner, VALUE(Catalog.Partners.EmptyRef)) AS PartnerVendor,
	|	ISNULL(VendorRebatesVendors.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS SupplierAgreement,
	|	ISNULL(VendorRebatesVendors.Terms, VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)) AS SupplierTerms,
	|	NULL AS DocumentRecorder,
	|	TT_Balance.Organization AS Organization,
	|	TT_Balance.Warehouse AS Warehouse,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS CounterpartyCustomer,
	|	TT_Balance.Products AS Products,
	|	CAST(TT_Balance.Products AS Catalog.Products).UnitOfMeasure AS UnitOfMeasure,
	|	FALSE AS ItemVariantsAreUsed,
	|	TT_Balance.Characteristic AS CharacteristicsOfSalesPurchases,
	|	TT_Balance.Characteristic AS Characteristic,
	|	UNDEFINED AS PropertyValue,
	|	"""" AS PresentationOfRangeUnit,
	|	0 AS RangeNumber,
	|	0 AS RangeFrom,
	|	0 AS RangeBy,
	|	FALSE AS RestrictAccrualOverPlan,
	|	TT_Balance.CountBalance >= TT_Goods.CountPlan AS PlanIsFulfilled,
	|	0 AS CountTurnover,
	|	TT_Balance.CountBalance AS CountBalance,
	|	VT_RBParameters.Currency AS Currency,
	|	0 AS BasePrice,
	|	0 AS AmountOfTurnoverWithVAT,
	|	0 AS AmountOfTurnoverExcludingVAT,
	|	0 AS AmountInBasePrices,
	|	TT_Goods.BonusPercent AS BonusPercent,
	|	0 AS SumPlan,
	|	TT_Goods.CountPlan AS CountPlan,
	|	0 AS CalculationBase,
	|	CASE
	|		WHEN ISNULL(TT_BalancesByPositions.QuantityBalanceTotal, 0) >= TT_Goods.CountPlan
	|			THEN CAST(TT_Balance.CountBalance * TT_Goods.BonusPerUnit AS NUMBER(31, 2))
	|		ELSE 0
	|	END AS AmountBonus,
	|	0 AS NumberOfPackages_,
	|	TT_Goods.BonusPerUnit AS BonusAmountPerUnit
	|INTO TT_Merging
	|FROM
	|	TT_Balance AS TT_Balance
	|		INNER JOIN VT_RBParameters AS VT_RBParameters
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.VendorRebatesVendors AS VendorRebatesVendors
	|		ON (VendorRebatesVendors.TermDocument = &SourceDocument_)
	|		INNER JOIN TT_Goods AS TT_Goods
	|		ON TT_Balance.Products = TT_Goods.Products
	|			AND TT_Balance.Characteristic = TT_Goods.Characteristic
	|		LEFT JOIN TT_BalancesByPositions AS TT_BalancesByPositions
	|		ON TT_Balance.Products = TT_BalancesByPositions.Products
	|			AND TT_Balance.Characteristic = TT_BalancesByPositions.Characteristic
	|
	|UNION ALL
	|
	|SELECT
	|	&DateOfRemainingGoods AS Period,
	|	&DateOfRemainingGoods AS CalculationPeriod,
	|	VT_RBParameters.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	VT_RBParameters.GoodsIndicator AS GoodsIndicator,
	|	VT_RBParameters.PartyCountDetails AS PartyCountDetails,
	|	VT_RBParameters.ConditionFrequency AS ConditionFrequency,
	|	ISNULL(VendorRebatesVendors.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) AS CounterpartySupplier,
	|	ISNULL(VendorRebatesVendors.Partner, VALUE(Catalog.Partners.EmptyRef)) AS PartnerVendor,
	|	ISNULL(VendorRebatesVendors.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS SupplierAgreement,
	|	ISNULL(VendorRebatesVendors.Terms, VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)) AS SupplierTerms,
	|	NULL AS DocumentRecorder,
	|	VT_RBParameters.Organization AS Organization,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS CounterpartyCustomer,
	|	VT_GoodsWithoutBalance.Products AS Products,
	|	VT_GoodsWithoutBalance.UnitOfMeasure AS UnitOfMeasure,
	|	FALSE AS ItemVariantsAreUsed,
	|	VT_GoodsWithoutBalance.Characteristic AS CharacteristicsOfSalesPurchases,
	|	VT_GoodsWithoutBalance.Characteristic AS Characteristic,
	|	UNDEFINED AS PropertyValue,
	|	"""" AS PresentationOfRangeUnit,
	|	0 AS RangeNumber,
	|	0 AS RangeFrom,
	|	0 AS RangeBy,
	|	FALSE AS RestrictAccrualOverPlan,
	|	FALSE AS PlanIsFulfilled,
	|	0 AS CountTurnover,
	|	0 AS CountBalance,
	|	VT_RBParameters.Currency AS Currency,
	|	0 AS BasePrice,
	|	0 AS AmountOfTurnoverWithVAT,
	|	0 AS AmountOfTurnoverExcludingVAT,
	|	0 AS AmountInBasePrices,
	|	VT_GoodsWithoutBalance.BonusPercent AS BonusPercent,
	|	0 AS SumPlan,
	|	VT_GoodsWithoutBalance.CountPlan AS CountPlan,
	|	0 AS CalculationBase,
	|	0 AS AmountBonus,
	|	0 AS NumberOfPackages_,
	|	VT_GoodsWithoutBalance.BonusPerUnit AS BonusAmountPerUnit
	|FROM
	|	VT_GoodsWithoutBalance AS VT_GoodsWithoutBalance
	|		INNER JOIN VT_RBParameters AS VT_RBParameters
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.VendorRebatesVendors AS VendorRebatesVendors
	|		ON (VendorRebatesVendors.TermDocument = &SourceDocument_)";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

#EndRegion

Procedure AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	VendorRebatesConditions.TermDocument AS ConditionOfRebateBonusIs,
	|	VendorRebatesConditions.Organization AS Organization,
	|	VendorRebatesConditions.ValidOnDate AS StartDate,
	|	ENDOFPERIOD(VendorRebatesConditions.ValidTo, DAY) AS EndDate,
	|	VendorRebatesConditions.ConsiderVAT AS ConsiderVAT,
	|	VendorRebatesConditions.Currency AS Currency,
	|	VendorRebatesConditions.Kind.BaseOfCalculation AS BaseOfCalculation,
	|	VendorRebatesConditions.Kind.GoodsIndicator AS GoodsIndicator,
	|	CASE
	|		WHEN VendorRebatesConditions.Kind.FulfilConditionsByCustomers
	|			THEN VALUE(Enum.ARAPAccountingDrilldownsOfRebatesParticipants.ByCounterparty)
	|		ELSE VALUE(Enum.ARAPAccountingDrilldownsOfRebatesParticipants.EmptyRef)
	|	END AS PartyCountDetails,
	|	VendorRebatesConditions.AccrualFrequency AS AccrualFrequency,
	|	VendorRebatesConditions.ConditionFrequency AS ConditionFrequency,
	|	VendorRebatesConditions.BonusPercent AS BonusPercent,
	|	VendorRebatesConditions.SumPlan AS SumPlan,
	|	VendorRebatesConditions.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	(VendorRebatesConditions.Kind.AllocationProcedure = VALUE(Enum.RebatesAllocationProcedures.FIFO)) AS FIFODistribution,
	|	(VendorRebatesConditions.Goods = VALUE(Enum.RebatesLists.Selected_)) AS SelectionOfGoodsSelected,
	|	(VendorRebatesConditions.Goods = VALUE(Enum.RebatesLists.ExceptForSelectedOnes)) AS SelectionOfGoodsOtherThanSelected,
	|	(VendorRebatesConditions.Goods = VALUE(Enum.RebatesLists.ALL)) AS SelectionOfGoodsWithoutRestrictions,
	|	VendorRebatesConditions.Kind.PartyList = VALUE(Enum.RebatesParticipants.TIN) AS FilterByInn,
	|	(VendorRebatesConditions.Kind.PartyList = VALUE(Enum.RebatesParticipants.Counterparties)) AS SelectionByCounterpartyPartner,
	|	(VendorRebatesConditions.Attendees = VALUE(Enum.RebatesLists.Selected_)) AS SelectionOfParticipantsSelected,
	|	(VendorRebatesConditions.Attendees = VALUE(Enum.RebatesLists.ExceptForSelectedOnes)) AS SelectionOfParticipantsExceptSelected,
	|	(VendorRebatesConditions.Attendees = VALUE(Enum.RebatesLists.ALL)) AS SelectionOfParticipantsWithoutRestrictions
	|INTO VT_RBParameters
	|FROM
	|	InformationRegister.VendorRebatesConditions AS VendorRebatesConditions
	|WHERE
	|	VendorRebatesConditions.TermDocument = &SourceDocument_";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	//@skip-check bsl-ql-hub - the selected layout fields are refined by replacing the query text
	QueryText =
	"SELECT
	|	TT_Merging.Period AS Period,
	|	TT_Merging.CalculationPeriod AS CalculationPeriod,
	|	TT_Merging.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	TT_Merging.GoodsIndicator AS GoodsIndicator,
	|	TT_Merging.PartyCountDetails AS PartyCountDetails,
	|	TT_Merging.ConditionFrequency AS ConditionFrequency,
	|	TT_Merging.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	TT_Merging.PlanIsFulfilled AS PlanIsFulfilled,
	|	TT_Merging.CounterpartySupplier AS CounterpartySupplier,
	|	TT_Merging.PartnerVendor AS PartnerVendor,
	|	TT_Merging.SupplierAgreement AS SupplierAgreement,
	|	TT_Merging.SupplierTerms AS SupplierTerms,
	|	TT_Merging.DocumentRecorder AS DocumentRecorder,
	|	TT_Merging.Warehouse AS Warehouse,
	|	TT_Merging.Organization AS Organization,
	|	TT_Merging.CounterpartyCustomer AS CounterpartyCustomer,
	|	TT_Merging.Products AS Products,
	|	TT_Merging.UnitOfMeasure AS UnitOfMeasure,
	|	TT_Merging.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	TT_Merging.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	TT_Merging.Characteristic AS Characteristic,
	|	TT_Merging.PropertyValue AS PropertyValue,
	|	TT_Merging.PresentationOfRangeUnit AS PresentationOfRangeUnit,
	|	TT_Merging.RangeNumber AS RangeNumber,
	|	TT_Merging.RangeFrom AS RangeFrom,
	|	TT_Merging.RangeBy AS RangeBy,
	|	TT_Merging.CountTurnover AS CountTurnover,
	|	TT_Merging.CountBalance AS CountBalance,
	|	TT_Merging.Currency AS Currency,
	|	TT_Merging.AmountOfTurnoverWithVAT AS AmountOfTurnoverWithVAT,
	|	TT_Merging.AmountOfTurnoverExcludingVAT AS AmountOfTurnoverExcludingVAT,
	|	TT_Merging.BasePrice AS BasePrice,
	|	TT_Merging.AmountInBasePrices AS AmountInBasePrices,
	|	TT_Merging.BonusPercent AS BonusPercent,
	|	TT_Merging.SumPlan AS SumPlan,
	|	TT_Merging.CountPlan AS CountPlan,
	|	TT_Merging.CalculationBase AS CalculationBase,
	|	TT_Merging.AmountBonus AS AmountBonus,
	|	TT_Merging.NumberOfPackages_ AS NumberOfPackages_,
	|	TT_Merging.BonusAmountPerUnit AS BonusAmountPerUnit
	|{SELECT
	|	ConditionOfRebateBonusIs.*,
	|	Period,
	|	CalculationPeriod,
	|	RestrictAccrualOverPlan,
	|	ConditionFrequency,
	|	PartyCountDetails,
	|	GoodsIndicator,
	|	DocumentRecorder.*,
	|	Warehouse.*,
	|	Organization.*,
	|	CounterpartySupplier.*,
	|	PartnerVendor.*,
	|	CounterpartyCustomer.*,
	|	Products.*,
	|	UnitOfMeasure.*,
	|	ItemVariantsAreUsed,
	|	CharacteristicsOfSalesPurchases.*,
	|	Characteristic.*,
	|	PropertyValue,
	|	RangeNumber,
	|	PresentationOfRangeUnit,
	|	RangeFrom,
	|	RangeBy,
	|	PlanIsFulfilled,
	|	BonusPercent,
	|	CountTurnover,
	|	CountBalance,
	|	Currency,
	|	BasePrice,
	|	AmountOfTurnoverWithVAT,
	|	AmountOfTurnoverExcludingVAT,
	|	AmountInBasePrices,
	|	AmountBonus,
	|	SumPlan,
	|	CountPlan,
	|	CalculationBase,
	|	NumberOfPackages_,
	|	BonusAmountPerUnit,
	|	SupplierTerms.*,
	|	SupplierAgreement.*}
	|FROM
	|	TT_Merging AS TT_Merging
	|{WHERE
	|	TT_Merging.DocumentRecorder.*,
	|	TT_Merging.Warehouse.*,
	|	TT_Merging.Organization.*,
	|	TT_Merging.Currency.*,
	|	TT_Merging.CounterpartySupplier.*,
	|	TT_Merging.PartnerVendor.*,
	|	TT_Merging.CounterpartyCustomer.*,
	|	TT_Merging.CalculationPeriod,
	|	TT_Merging.Products.*,
	|	TT_Merging.Characteristic.*,
	|	TT_Merging.PropertyValue,
	|	TT_Merging.SupplierAgreement.*,
	|	TT_Merging.SupplierTerms.*}";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf