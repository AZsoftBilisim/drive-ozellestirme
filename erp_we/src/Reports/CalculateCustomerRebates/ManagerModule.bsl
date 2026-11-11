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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CalculateCustomerRebates);
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
//   VariantKey - String -
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddCalculationOfCustomerRebatesCommand(ReportsCommands, VariantKey = "") Export
	
	If AccessRight("View", Metadata.Reports.CalculateCustomerRebates) Then
		
		ReportCommand = ReportsCommands.Add();
		
		Presentation = NStr("vi = 'Tính thưởng lũy kế cho khách hàng';
							|ru = 'Расчет ретро-бонусов клиентов';
							|en = 'Calculate customer rebates'; fa = 'محاسبه تخفیف‌های حجمی مشتری';
							|it = 'Расчет ретро-бонусов клиентов';
							|pl = 'Calculate customer rebates';
							|tr = 'Müşterilerin retro-bonuslarının hesaplanması'");
		ReportCommand.Manager = Metadata.Reports.CalculateCustomerRebates.FullName();
		ReportCommand.Presentation = Presentation;
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		If ValueIsFilled(VariantKey) Then
			ReportCommand.VariantKey = VariantKey;
		EndIf;
		
		ReportCommand.Handler = "RebatesClient.CalculateCustomerRebates";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesForCustomers
//  OptionParameters - See RebatesCalculation.NewOptionParameters
// 
// Returns:
//  String - Query text
//
Function QueryText(RebateConditionsParameters, OptionParameters) Export
	
	GoodsIndicator = RebateConditionsParameters.GoodsIndicator;
	IndicatorsKinds = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	QueriesTexts = New Array; // Array of String
	
	If GoodsIndicator = IndicatorsKinds.NotUsed Then
		
		GenerateQueryTextsWithoutTargetIndicator(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.Sum Then
		
		GenerateQueryTextsBasedOnTargetIndicatorAmount(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.Count Then
		
		GenerateQueryTextsBasedOnTargetIndicatorNumber(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.QuantityTotal Then
		
		GenerateQueryTextsBasedOnTargetIndicatorNumberInAggregate(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.BatchOffer Then
		
		GenerateQueryTextsBasedOnTargetIndicatorPackageOffer(
			RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf GoodsIndicator = IndicatorsKinds.EmptyRef() Then
		
		ErrorTemplate = NStr("vi = 'Chưa điền chỉ tiêu bán hàng đối với chứng từ ""%1""';
							|ru = 'Не заполнен целевой показатель продаж для документа ""%1""';
							|en = 'The target sales indicator is not filled for the ""%1"" document'; fa = 'The target sales indicator is not filled for the ""%1"" document';
							|it = 'Не заполнен целевой показатель продаж для документа ""%1""';
							|pl = 'The target sales indicator is not filled for the ""%1"" document';
							|tr = '“%1” belgesi için satış hedefi doldurulmamış'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Không thể xác định chỉ tiêu bán hàng (""%1"") đối với chứng từ ""%2""';
							|ru = 'Не удалось определить целевой показатель продаж (""%1"") для документа ""%2""';
							|en = 'Cannot determine the target sales indicator (""%1"") for the ""%2"" document'; fa = 'Cannot determine the target sales indicator (""%1"") for the ""%2"" document';
							|it = 'Не удалось определить целевой показатель продаж (""%1"") для документа ""%2""';
							|pl = 'Cannot determine the target sales indicator (""%1"") for the ""%2"" document';
							|tr = '“%2“ belgesi için bir satış hedefi (”%1"") tanımlanamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			RebateConditionsParameters.GoodsIndicatorPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	QueryBatchSeparator = Common.QueryBatchSeparator();
	QueryText = StrConcat(QueriesTexts, QueryBatchSeparator);
	
	Return QueryText;
	
EndFunction

// Returns a table of calculated retro-bonuses of customers under the specified conditions with details up to the sales document.
// 
// Parameters:
//  CalculationParameters - See RebatesCalculationParameters
//  InPrivilegedMode - Boolean
// 
// Returns:
//  ValueTable - Calculated retro-bonuses under the specified conditions
//  
Function RebatesForPeriodAccordingToSalesDocuments(CalculationParameters, InPrivilegedMode = True) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Report.CalculateCustomerRebates.ManagerModule.RebatesForPeriodAccordingToSalesDocuments");
	
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
	ConditionParameters_ = RebatesCalculation.ParametersOfTermsOfRebatesForCustomers(SourceDocument_);
	
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
		Or (ConditionParameters_.ContentOfGoods = Enums.RebatesItems.ProductSegments)
		Or (ConditionParameters_.PartyList = Enums.RebatesParticipants.PartnersSegments);
	
	If SegmentsOrPropertiesAreUsed
	   And Not ConditionParameters_.RecordingIsCompleted Then
		
		ExceptionText = NStr("vi = 'Chưa ghi nhận thành phần hàng hóa và thành phần chứng từ điều kiện.';
							|ru = 'Не зафиксирован состав товаров и участников документа условий.';
							|en = 'The condition document items and participants are not recorded.'; fa = 'The condition document items and participants are not recorded.';
							|it = 'The condition document items and participants are not recorded.';
							|pl = 'The condition document items and participants are not recorded.';
							|tr = 'Şartlar belgesi katılımcılarının ve ürünlerin içeriği sabitlenmedi.'");
		Raise ExceptionText;
		
	EndIf;
	
	// adjustment of the calculation period according to the period of validity of the conditions
	
	DateEmpty = '00010101';
	
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
	
	OptionParameters = RebatesCalculation.NewOptionParameters();
	OptionParameters.VariantKey = "AccrualsForDocuments";
	OptionParameters.ThisIsTheTranscript = True;
	OptionParameters.ThisIsTranscriptOfDocuments = True;
	
	DataCompositionSchema = GetTemplate("MainDataCompositionSchema");
	
	QueryText = QueryText(ConditionParameters_, OptionParameters);
	DataCompositionSchema.DataSets.CalculateCustomerRebates.Query = QueryText;
	
	CompositeVersionOfReport = DataCompositionSchema.SettingVariants[OptionParameters.VariantKey];
	
	ComposerOfSettingsByOption = New DataCompositionSettingsComposer;
	ComposerOfSettingsByOption.LoadSettings(CompositeVersionOfReport.Settings);
	SourceOfAvailableCDSettings = New DataCompositionAvailableSettingsSource(DataCompositionSchema);
	ComposerOfSettingsByOption.Initialize(SourceOfAvailableCDSettings);
	ReportSettings = ComposerOfSettingsByOption.GetSettings();
	
	ParametersToBeSpecified = New Map;
	ParametersToBeSpecified.Insert("DocumentTermsOfRetroBonuses", CalculationParameters.TermDocument);
	ParametersToBeSpecified.Insert("SourceDocument_", SourceDocument_);
	ParametersToBeSpecified.Insert("Organization", CalculationParameters.Organization);
	ParametersToBeSpecified.Insert("StartDate", CalculationParameters.StartDate);
	ParametersToBeSpecified.Insert("EndDate", EndOfDay(CalculationParameters.EndDate));
	ParametersToBeSpecified.Insert("Counterparty", CalculationParameters.Counterparty);
	ParametersToBeSpecified.Insert("Partner", CalculationParameters.Partner);
	ExcludedBusinessOfOperations = Reports.CalculateCustomerRebates.ExcludedBusinessOfOperations();
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ExcludedBusinessOfOperations", ExcludedBusinessOfOperations);
	ExcludedSettingsOfBTransaction = Reports.CalculateCustomerRebates.ExcludedSettingsOfBusinessTransaction();
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ExcludedSettingsOfBusinessTransaction", ExcludedSettingsOfBTransaction);
	
	DataCompositionClientServer.SetCollectionOfParameters(ReportSettings, ParametersToBeSpecified);
	
	If ValueIsFilled(CalculationParameters.Currency) Then
		
		DataCompositionClientServer.AddFilter(ReportSettings, "Currency", CalculationParameters.Currency);
		
	EndIf;
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 1, "Setting");
	
	If InPrivilegedMode Then
		SetPrivilegedMode(True);
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	
	DataCompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, ReportSettings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	ResultTable1 = New ValueTable;
	OutputProcessor.SetObject(ResultTable1);
	OutputProcessor.Output(DataCompositionProcessor);
	
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, ResultTable1.Count(), "Layout");
	
	// additional fields for participants
	
	PartyCountDetails = ConditionParameters_.PartyCountDetails;
	DetailsOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If PartyCountDetails <> DetailsOfParticipants.ByCounterpartyAndCustomer Then
		
		SalesDocumentsAll = TMCommonUse.UniqueValuesFromTableColumn(
			ResultTable1, "DocumentSales");
		ParticipantsAccordingToSalesDocuments = Common.ObjectsAttributesValues(
			SalesDocumentsAll, "Counterparty, Partner");
		
		For Each TableRow In ResultTable1 Do
			
			DocumentParticipants = ParticipantsAccordingToSalesDocuments[TableRow.DocumentSales];
			FillPropertyValues(TableRow, DocumentParticipants);
			
		EndDo;
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1, "FillingInParticipants");
	
	Return ResultTable1;
	
EndFunction

// Parameters for calculating retro bonuses.
// 
// Returns:
//  Structure:
//  * TermDocument - DocumentRef.ConditionsOfCustomerRebates -
//  * Organization - CatalogRef.Companies -
//  * DocumentsCreationDate - Date - The beginning of the bonus calculation period
//  * StartDate - Date - The beginning of the bonus calculation period
//  * EndDate - Date - The end of the bonus calculation period
//  * Counterparty - CatalogRef.Counterparties - Selection by counterparty
//  * Partner - CatalogRef.Partners - Selection by client
//  * Currency - CatalogRef.Currencies - Currency Selection
// 
Function RebatesCalculationParameters() Export
	
	DateEmpty = Date(1, 1, 1);
	
	Parameters = New Structure;
	Parameters.Insert("TermDocument", Documents.ConditionsOfCustomerRebates.EmptyRef());
	Parameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	Parameters.Insert("DocumentsCreationDate", DateEmpty);
	Parameters.Insert("StartDate", DateEmpty);
	Parameters.Insert("EndDate", DateEmpty);
	Parameters.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Parameters.Insert("Partner", Catalogs.Partners.EmptyRef());
	Parameters.Insert("Currency", Catalogs.Currencies.EmptyRef());
	
	Return Parameters;
	
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

#EndRegion

#Region Private

#Region QueryText

Procedure GenerateQueryTextsWithoutTargetIndicator(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextSummaryDataWithoutTarget(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsBasedOnTargetIndicatorAmount(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	CalculationWithDistribution = (RebateConditionsParameters.RestrictAccrualOverPlan
		Or RebateConditionsParameters.CalculationScaleByRanges);
	
	If CalculationWithDistribution
	   And RebateConditionsParameters.ProportionalDistribution Then
		
		GenerateQueryTextsBasedOnTargetIndicatorAmountProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf CalculationWithDistribution
	        And RebateConditionsParameters.DistributionByFIFO Then
		
		GenerateQueryTextsBasedOnTargetIndicatorAmountFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		GenerateQueryTextsBasedOnTargetIndicatorAmountWithoutProhibitionOfExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsBasedOnTargetIndicatorAmountWithoutProhibitionOfExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.ProgressiveCalculationScale Then
		
		RebatesCalculation.AddQueryTextCalculationScale(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextCalculationScaleMinimumPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsBasedOnTargetIndicatorAmountProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
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
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsBasedOnTargetIndicatorAmountFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
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
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfSaleWithoutSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddSalesQueryTextWithSelectionByCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
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
		RebatesCalculation.AddQueryTextBonusTotalsByRangeWidth(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextFinalFIFODistributionByRanges(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		RebatesCalculation.AddQueryTextOfMinimumPriorityForExecutionOfPlanByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextDataForDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextToRoundingPriority(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextRoundingDistributionByFIFO(RebateConditionsParameters, OptionParameters, QueriesTexts);
		RebatesCalculation.AddQueryTextFinalFIFODistributionByAmount(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextSummaryData(RebateConditionsParameters, OptionParameters, QueriesTexts);
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsBasedOnTargetIndicatorNumber(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	CalculationWithDistribution = (RebateConditionsParameters.RestrictAccrualOverPlan
		Or RebateConditionsParameters.CalculationScaleByRanges);
	
	If CalculationWithDistribution
	   And RebateConditionsParameters.ProportionalDistribution Then
		
		GenerateQueryTextsQuantityProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	ElsIf CalculationWithDistribution
	        And RebateConditionsParameters.DistributionByFIFO Then
		
		GenerateQueryTextsQuantityFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		GenerateQueryTextsQuantityWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsQuantityWithoutProhibitingExceeding(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfGoodsMinimumPackingPlan(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextMinimumParametersByPosition(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsQuantityProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
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
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextDiscountPercentageWithoutDimensions(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextTurnoverByPeriod(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddQueryTextExceedingLimitTotal(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsQuantityFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
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
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	RebatesCalculation.AddSalesQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsBasedOnTargetIndicatorNumberInAggregate(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsBasedOnTargetIndicatorPackageOffer(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	If RebateConditionsParameters.DistributionByFIFO Then
		
		GenerateQueryTextsBatchOfferFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	Else
		
		GenerateQueryTextsBatchOfferProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
EndProcedure

Procedure GenerateQueryTextsBatchOfferProportionalDistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure GenerateQueryTextsBatchOfferFIFODistribution(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextForGoods(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextOfInventoryLocationAttributeSVAnalytics(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.Terms1 Then
		
		AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts);
		AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts);
		
	EndIf;
	
	RebatesCalculation.AddQueryTextOfParticipantsInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextPartnersCounterparties(RebateConditionsParameters, OptionParameters, QueriesTexts);
	RebatesCalculation.AddQueryTextAnalyticsForPartners(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
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
	AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts);
	
EndProcedure

Procedure AddQueryTextRBParameters(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	CustomerRebatesConditions.TermDocument AS ConditionOfRebateBonusIs,
	|	CustomerRebatesConditions.ValidOnDate AS StartDate,
	|	ENDOFPERIOD(CustomerRebatesConditions.ValidTo, DAY) AS EndDate,
	|	CustomerRebatesConditions.ConsiderVAT AS ConsiderVAT,
	|	CustomerRebatesConditions.Currency AS Currency,
	|	CustomerRebatesConditions.Kind.SalesCalculationBase AS BaseOfCalculation,
	|	CustomerRebatesConditions.Kind.GoodsIndicator AS GoodsIndicator,
	|	CustomerRebatesConditions.PartyCountDetails AS PartyCountDetails,
	|	CustomerRebatesConditions.AccrualFrequency AS AccrualFrequency,
	|	CustomerRebatesConditions.ConditionFrequency AS ConditionFrequency,
	|	CustomerRebatesConditions.BonusPercent AS BonusPercent,
	|	CustomerRebatesConditions.SumPlan AS SumPlan,
	|	CustomerRebatesConditions.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	(CustomerRebatesConditions.Kind.AllocationProcedure = VALUE(Enum.RebatesAllocationProcedures.FIFO)) AS FIFODistribution,
	|	(CustomerRebatesConditions.Goods = VALUE(Enum.RebatesLists.Selected_)) AS SelectionOfGoodsSelected,
	|	(CustomerRebatesConditions.Goods = VALUE(Enum.RebatesLists.ExceptForSelectedOnes)) AS SelectionOfGoodsOtherThanSelected,
	|	(CustomerRebatesConditions.Goods = VALUE(Enum.RebatesLists.ALL)) AS SelectionOfGoodsWithoutRestrictions,
	|	CustomerRebatesConditions.Kind.PartyList = VALUE(Enum.RebatesParticipants.TIN) AS FilterByInn,
	|	(CustomerRebatesConditions.Kind.PartyList = VALUE(Enum.RebatesParticipants.Customers)
	|		OR CustomerRebatesConditions.Kind.PartyList = VALUE(Enum.RebatesParticipants.Counterparties)
	|		OR CustomerRebatesConditions.Kind.PartyList = VALUE(Enum.RebatesParticipants.PartnersSegments)) AS SelectionByCounterpartyPartner,
	|	(CustomerRebatesConditions.Attendees = VALUE(Enum.RebatesLists.Selected_)) AS SelectionOfParticipantsSelected,
	|	(CustomerRebatesConditions.Attendees = VALUE(Enum.RebatesLists.ExceptForSelectedOnes)) AS SelectionOfParticipantsExceptSelected,
	|	(CustomerRebatesConditions.Attendees = VALUE(Enum.RebatesLists.ALL)) AS SelectionOfParticipantsWithoutRestrictions
	|INTO VT_RBParameters
	|FROM
	|	InformationRegister.CustomerRebatesConditions AS CustomerRebatesConditions
	|WHERE
	|	CustomerRebatesConditions.TermDocument = &SourceDocument_";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextOfAgreementInAdvance(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	CustomerRebatesContractsTermsOfSales.TermDocument AS TermsAndConditionsOfRebates,
	|	CustomerRebatesContractsTermsOfSales.Terms AS Terms,
	|	CustomerRebatesContractsTermsOfSales.ValidOnDate AS ValidOnDate,
	|	CustomerRebatesContractsTermsOfSales.ValidTo AS ValidTo,
	|	CustomerRebatesContractsTermsOfSales.SumPlan AS SumPlan,
	|	CustomerRebatesContractsTermsOfSales.IncludeSalesBySpecialTermsOfSales AS IncludeSalesBySpecialTermsOfSales,
	|	CustomerRebatesContractsTermsOfSales.Terms.Standard_ AS ModelAgreement,
	|	CustomerRebatesContractsTermsOfSales.Terms.Partner AS Partner
	|INTO VT_AgreementsInAdvance
	|FROM
	|	InformationRegister.CustomerRebatesContractsTermsOfSales AS CustomerRebatesContractsTermsOfSales
	|WHERE
	|	CustomerRebatesContractsTermsOfSales.TermDocument = &SourceDocument_
	|	AND CustomerRebatesContractsTermsOfSales.Terms <> VALUE(Catalog.TermsOfSale.EmptyRef)
	|
	|INDEX BY
	|	Terms,
	|	ModelAgreement,
	|	IncludeSalesBySpecialTermsOfSales";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddAgreementQueryText(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	VT_AgreementsInAdvance.TermsAndConditionsOfRebates AS TermsAndConditionsOfRebates,
	|	VT_AgreementsInAdvance.Terms AS Terms,
	|	VT_AgreementsInAdvance.ValidOnDate AS ValidOnDate,
	|	VT_AgreementsInAdvance.ValidTo AS ValidTo,
	|	VT_AgreementsInAdvance.SumPlan AS SumPlan,
	|	VT_AgreementsInAdvance.ModelAgreement AS ModelAgreement,
	|	VT_AgreementsInAdvance.Partner AS Partner
	|INTO TT_Terms1
	|FROM
	|	VT_AgreementsInAdvance AS VT_AgreementsInAdvance
	|
	|UNION ALL
	|
	|SELECT
	|	VT_AgreementsInAdvance.TermsAndConditionsOfRebates AS TermsAndConditionsOfRebates,
	|	TermsOfSale.Ref AS Terms,
	|	VT_AgreementsInAdvance.ValidOnDate AS ValidOnDate,
	|	VT_AgreementsInAdvance.ValidTo AS ValidTo,
	|	VT_AgreementsInAdvance.SumPlan AS SumPlan,
	|	TermsOfSale.Standard_ AS ModelAgreement,
	|	TermsOfSale.Partner AS Partner
	|FROM
	|	VT_AgreementsInAdvance AS VT_AgreementsInAdvance
	|		INNER JOIN Catalog.TermsOfSale AS TermsOfSale
	|		ON VT_AgreementsInAdvance.Terms = TermsOfSale.Terms
	|		LEFT JOIN VT_AgreementsInAdvance AS IndividualAgreementsSpecifiedDirectly
	|		ON TermsOfSale.Ref = IndividualAgreementsSpecifiedDirectly.Terms
	|		AND IndividualAgreementsSpecifiedDirectly.ModelAgreement = FALSE
	|WHERE
	|	VT_AgreementsInAdvance.ModelAgreement
	|	AND VT_AgreementsInAdvance.IncludeSalesBySpecialTermsOfSales
	|	AND IndividualAgreementsSpecifiedDirectly.Terms IS NULL
	|
	|INDEX BY
	|	Terms,
	|	Partner,
	|	ModelAgreement";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextAnalyticsForPartnersForStandardAgreements(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT DISTINCT
	|	RevenueAndCOGS.AccountingDimensionByPartners AS DimensionKey,
	|	RS__AccountingDimensionByPartners.Organization AS Organization,
	|	RS__AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	RS__AccountingDimensionByPartners.Partner AS Partner,
	|	RevenueAndCOGS.Terms AS Terms
	|INTO VT_AnalyticsForPartnersUnderStandardAgreements
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS RS__AccountingDimensionByPartners
	|		ON RevenueAndCOGS.AccountingDimensionByPartners = RS__AccountingDimensionByPartners.DimensionKey
	|WHERE
	|	RevenueAndCOGS.Period BETWEEN &StartDate AND &EndDate
	|	AND RevenueAndCOGS.Terms IN
	|		(SELECT
	|			TT_Terms1.Terms AS Terms
	|		FROM
	|			TT_Terms1 AS TT_Terms1
	|		WHERE
	|			TT_Terms1.ModelAgreement)
	|	AND RS__AccountingDimensionByPartners.Organization IN (&Organization)
	|	AND &SelectionConditionByCounterparty
	|	AND &PartnerSelectionCriteria
	|	AND RevenueAndCOGS.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	AND RevenueAndCOGS.BusinessOperation NOT IN (&ExcludedBusinessOfOperations)
	|
	|INDEX BY
	|	Terms";
	
	If OptionParameters.ThisIsTheTranscript Then
		
		SelectionConditionByCounterparty =
		"CASE
		|	WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
		|		OR &Counterparty = UNDEFINED
		|	THEN TRUE
		|	ELSE RS__AccountingDimensionByPartners.Counterparty = &Counterparty
		|END";
		PartnerSelectionCriteria =
		"CASE
		|	WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
		|		OR &Partner = UNDEFINED
		|	THEN TRUE
		|	ELSE RS__AccountingDimensionByPartners.Partner = &Partner
		|END";
		
	Else
		
		SelectionConditionByCounterparty = "TRUE";
		PartnerSelectionCriteria = "TRUE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionConditionByCounterparty", SelectionConditionByCounterparty);
	QueryText = StrReplace(QueryText, "&PartnerSelectionCriteria", PartnerSelectionCriteria);
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

Procedure AddQueryTextOfDataSample(RebateConditionsParameters, OptionParameters, QueriesTexts)
	
	QueryText =
	"SELECT
	|	SummaryData.Period AS Period,
	|	SummaryData.CalculationPeriod AS CalculationPeriod,
	|	SummaryData.ConditionOfRebateBonusIs AS ConditionOfRebateBonusIs,
	|	SummaryData.GoodsIndicator AS GoodsIndicator,
	|	SummaryData.PartyCountDetails AS PartyCountDetails,
	|	SummaryData.AccrualFrequency AS AccrualFrequency,
	|	SummaryData.ConditionFrequency AS ConditionFrequency,
	|	SummaryData.RestrictAccrualOverPlan AS RestrictAccrualOverPlan,
	|	SummaryData.PlanIsFulfilled AS PlanIsFulfilled,
	|	SummaryData.DocumentRecorder AS DocumentSales,
	|	SummaryData.Organization AS Organization,
	|	SummaryData.Counterparty AS Counterparty,
	|	SummaryData.Partner AS Partner,
	|	SummaryData.Contract AS Contract,
	|	SummaryData.Terms AS Terms,
	|	SummaryData.Products AS Products,
	|	SummaryData.UnitOfMeasure AS UnitOfMeasure,
	|	SummaryData.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	SummaryData.CharacteristicsOfSalesPurchases AS CharacteristicsOfSalesPurchases,
	|	SummaryData.Characteristic AS Characteristic,
	|	SummaryData.PropertyValue AS PropertyValue,
	|	SummaryData.RangeNumber AS RangeNumber,
	|	SummaryData.PresentationOfRangeUnit AS PresentationOfRangeUnit,
	|	SummaryData.RangeFrom AS RangeFrom,
	|	SummaryData.RangeBy AS RangeBy,
	|	SummaryData.Count AS QuantitySales,
	|	SummaryData.Currency AS Currency,
	|	SummaryData.SalesAmount AS SalesAmount,
	|	SummaryData.AmountOfTurnoverWithVAT AS RevenueAmount,
	|	SummaryData.AmountOfTurnoverExcludingVAT AS RevenueAmountExcludingVAT,
	|	SummaryData.BasePrice AS BasePrice,
	|	CAST(SummaryData.Count * SummaryData.BasePrice AS NUMBER(31, 2)) AS AmountInBasePrices,
	|	SummaryData.BonusPercent AS PercentageBonus,
	|	SummaryData.SumPlan AS SumPlan,
	|	SummaryData.CountPlan AS CountPlan,
	|	SummaryData.CalculationBase AS CalculationBase,
	|	SummaryData.AmountToCalculateBonus AS AmountToCalculateBonus,
	|	SummaryData.AmountBonus AS AmountBonus,
	|	SummaryData.NumberOfPackages_ AS PackagesSold
	|{SELECT
	|	ConditionOfRebateBonusIs.*,
	|	Period,
	|	CalculationPeriod,
	|	RestrictAccrualOverPlan,
	|	AccrualFrequency,
	|	ConditionFrequency,
	|	PartyCountDetails,
	|	GoodsIndicator,
	|	DocumentSales.*,
	|	Organization.*,
	|	Counterparty.*,
	|	Partner.*,
	|	Contract.*,
	|	Terms.*,
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
	|	PercentageBonus,
	|	QuantitySales,
	|	Currency,
	|	BasePrice,
	|	SalesAmount,
	|	RevenueAmount,
	|	RevenueAmountExcludingVAT,
	|	AmountInBasePrices,
	|	AmountBonus,
	|	SumPlan,
	|	CountPlan,
	|	CalculationBase,
	|	PackagesSold}
	|FROM
	|	TT_SummaryData AS SummaryData
	|{WHERE
	|	SummaryData.DocumentRecorder.*,
	|	SummaryData.Organization.*,
	|	SummaryData.Currency.*,
	|	SummaryData.Counterparty.*,
	|	SummaryData.Contract.*,
	|	SummaryData.Terms.*,
	|	SummaryData.CalculationPeriod,
	|	SummaryData.Products.*,
	|	SummaryData.Characteristic.*,
	|	SummaryData.PropertyValue,
	|	SummaryData.Partner.*}";
	
	QueriesTexts.Add(QueryText);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf