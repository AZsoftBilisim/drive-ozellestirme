#Region Public

#Region DescriptionOfStageTree

#Region DescriptionOfStageGroups

// Filling in the table of groups of monthly closing stages.
// The elements in this table are the top-level elements in the stage tree in the month close form.
//
// Parameters:
// TableOfStageGroups - See DataProcessors.MonthEndClosingOperations.InitializeStageGroupDescriptionTable 
//
Procedure FillInDescriptionOfGroupsOfStagesForClosingMonth(TableOfStageGroups) Export
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IDOfManualOperationsGroup();
	NewRow.Description = NStr("vi = 'Các thao tác này phải được thực hiện thủ công';
								|ru = 'Данные операции требуется выполнить вручную';
								|en = 'These operations must be performed manually'; fa = 'These operations must be performed manually';
								|it = 'Queste operazioni devono essere eseguite manualmente';
								|pl = 'Dane operacje należy wykonać ręcznie';
								|tr = 'Bu işlemlerin manuel olarak yapılması gerekiyor'");
	NewRow.InternationalDescription = "vi = 'Các thao tác này phải được thực hiện thủ công';
										|ru = 'Данные операции требуется выполнить вручную';
										|en = 'These operations must be performed manually';
										|it = 'Queste operazioni devono essere eseguite manualmente';
										|pl = 'Dane operacje należy wykonać ręcznie';
										|tr = 'Bu işlemlerin manuel olarak yapılması gerekiyor'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IdOfNonOperationalTaskQueueGroup();
	NewRow.Description = NStr("vi = 'Kết chuyển bổ sung chứng từ';
								|ru = 'Допроведение документов';
								|en = 'Additional document posting'; fa = 'ثبت قطعی تکمیلی سند';
								|it = 'Additional document posting';
								|pl = 'Additional document posting';
								|tr = 'Ek belge düzenlemesi'");
	NewRow.InternationalDescription = "vi = 'Kết chuyển bổ sung chứng từ';
										|ru = 'Допроведение документов';
										|en = 'Additional document posting';
										|it = 'Additional document posting';
										|pl = 'Additional document posting';
										|tr = 'Ek belge düzenlemesi'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IDOfSettlementsGroup();
	NewRow.Description = NStr("vi = 'Đối trừ và đánh giá lại ngoại tệ';
								|ru = 'Взаиморасчеты и переоценка валютных средств';
								|en = 'AR/AP accounting and currency revaluation'; fa = 'AR/AP accounting and currency revaluation';
								|it = 'Regolazioni reciproche dei conti e rivalutazione dei fondi monetari';
								|pl = 'Rozliczenia wzajemne i przeszacowanie środków walutowych';
								|tr = 'Mutabakatlar ve döviz varlıklarının yeniden değerlenmesi'");
	NewRow.InternationalDescription = "vi = 'Đối trừ và đánh giá lại ngoại tệ';
										|ru = 'Взаиморасчеты и переоценка валютных средств';
										|en = 'AR/AP accounting and currency revaluation';
										|it = 'Regolazioni reciproche dei conti e rivalutazione dei fondi monetari';
										|pl = 'Rozliczenia wzajemne i przeszacowanie środków walutowych';
										|tr = 'Mutabakatlar ve döviz varlıklarının yeniden değerlenmesi'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IDOfCostGenerationGroup();
	NewRow.Description = NStr("vi = 'Lập chi phí';
								|ru = 'Формирование затрат';
								|en = 'Generate costs'; fa = 'Generate costs';
								|it = 'Generazione delle spese';
								|pl = 'Tworzenie kosztów';
								|tr = 'Gider oluşturma'");
	NewRow.InternationalDescription = "vi = 'Lập chi phí';
										|ru = 'Формирование затрат';
										|en = 'Generate costs';
										|it = 'Generazione delle spese';
										|pl = 'Tworzenie kosztów';
										|tr = 'Gider oluşturma'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IDOfProductionCostsGroup();
	NewRow.Description = NStr("vi = 'Phân bổ chi phí sản xuất';
								|ru = 'Распределение производственных затрат';
								|en = 'Production cost allocation'; fa = 'Production cost allocation';
								|it = 'Ripartizione delle spese di produzione';
								|pl = 'Podział kosztów produkcji';
								|tr = 'Üretim maliyetleri dağıtımı'");
	NewRow.InternationalDescription = "vi = 'Phân bổ chi phí sản xuất';
										|ru = 'Распределение производственных затрат';
										|en = 'Production cost allocation';
										|it = 'Ripartizione delle spese di produzione';
										|pl = 'Podział kosztów produkcji';
										|tr = 'Üretim maliyetleri dağıtımı'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IDOfCostGroup();
	NewRow.Description = NStr("vi = 'Tính giá vốn';
								|ru = 'Расчет себестоимости';
								|en = 'Cost calculation'; fa = 'محاسبه بهای تمام‌شده';
								|it = 'Calcolo del costo di produzione';
								|pl = 'Kalkulacja wartości własnej';
								|tr = 'Maliyet hesaplaması'");
	NewRow.InternationalDescription = "vi = 'Tính giá vốn';
										|ru = 'Расчет себестоимости';
										|en = 'Cost calculation';
										|it = 'Calcolo del costo di produzione';
										|pl = 'Kalkulacja wartości własnej';
										|tr = 'Maliyet hesaplaması'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IDOfFinancialResultGenerationGroup();
	NewRow.Description = NStr("vi = 'Lập báo cáo kết quả kinh doanh';
								|ru = 'Формирование финансового результата';
								|en = 'Profitability & cost generation'; fa = 'ایجاد سودآوری و بهای تمام‌شده';
								|it = 'Generazione del risultato finanziario';
								|pl = 'Tworzenie rezultatu finansowego';
								|tr = 'Kârlılık ve maliyet oluşturma'");
	NewRow.InternationalDescription = "vi = 'Lập báo cáo kết quả kinh doanh';
										|ru = 'Формирование финансового результата';
										|en = 'Profitability & cost generation';
										|it = 'Generazione del risultato finanziario';
										|pl = 'Tworzenie rezultatu finansowego';
										|tr = 'Kârlılık ve maliyet oluşturma'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = GroupIDRegulatedAccounting();
	NewRow.Description = NStr("vi = 'Kế toán tài chính';
								|ru = 'Регламентированный учет';
								|en = 'Local accounting'; fa = 'حسابداری محلی';
								|it = 'Contabilità di regolamentazione';
								|pl = 'Księgowość';
								|tr = 'Yerel muhasebe'");
	NewRow.InternationalDescription = "vi = 'Kế toán tài chính';
										|ru = 'Регламентированный учет';
										|en = 'Local accounting';
										|it = 'Contabilità di regolamentazione';
										|pl = 'Księgowość';
										|tr = 'Yerel muhasebe'";
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IDOfInternationalAccountingGroup();
	NewRow.Description = NStr("vi = 'Kế toán IFRS';
								|ru = 'Международный учет';
								|en = 'Financial accounting'; fa = 'حسابداری مالی';
								|it = 'Contabilità internazionale';
								|pl = 'Rachunkowość międzynarodowa';
								|tr = 'Uluslararası muhasebe'");
	NewRow.InternationalDescription = "vi = 'Kế toán quốc tế';
										|ru = 'Международный учет';
										|en = 'Financial accounting';
										|it = 'Contabilità internazionale';
										|pl = 'Rachunkowość międzynarodowa';
										|tr = 'Uluslararası muhasebe'";
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IdOfGroupReflectsRegisteredRecordsOfManBalance();
	NewRow.Description = NStr("vi = 'Bảng cân đối kế toán quản trị';
								|ru = 'Управленческий баланс';
								|en = 'Balance sheet statement'; fa = 'صورت وضعیت مالی';
								|it = 'Bilancio gestionale';
								|pl = 'Bilans zarządczy';
								|tr = 'Yönetim bilançosu'");
	NewRow.InternationalDescription = "vi = 'Bảng cân đối kế toán quản trị';
										|ru = 'Управленческий баланс';
										|en = 'Balance sheet statement';
										|it = 'Bilancio gestionale';
										|pl = 'Bilans zarządczy';
										|tr = 'Yönetim bilançosu'";
	
	NewRow = TableOfStageGroups.Add();
	NewRow.Code = IdOfChangeBlockingGroup();
	NewRow.Description = NStr("vi = 'Phong tỏa các thay đổi';
								|ru = 'Блокировка от изменений';
								|en = 'Lock from changes'; fa = 'قفل در برابر تغییرات';
								|it = 'Блокировка от изменений';
								|pl = 'Lock from changes';
								|tr = 'Değişikliklerden kilit'");
	NewRow.InternationalDescription = "vi = 'Phong tỏa tránh các thay đổi';
										|ru = 'Блокировка от изменений';
										|en = 'Lock from changes';
										|it = 'Блокировка от изменений';
										|pl = 'Lock from changes';
										|tr = 'Değişikliklerden kilit'";
	
	MonthEndTransactionsLocalization.AddDescriptionOfGroupsOfStagesForClosingMonth(TableOfStageGroups);
	
EndProcedure

#Region StageGroupIDs

// In this area, the identifiers of the groups of the closing stages of the month are located.
// String identifiers are used for stage groups, because there is no need for reference identifiers for them.

// ID of the manual operations group.
// 
// Returns:
//  String - ID Of The Manual Operations Group
Function IDOfManualOperationsGroup() Export
	Return "ManualOperations";
EndFunction

// ID of the settlements group.
// 
// Returns:
//  String - ID Of The Settlements Group
Function IDOfSettlementsGroup() Export
	Return "ARAPAccounting";
EndFunction

// ID of the cost generation group.
// 
// Returns:
//  String - ID Of The Cost Generation Group
Function IDOfCostGenerationGroup() Export
	Return "CostGeneration";
EndFunction

// ID of the production costs group.
// 
// Returns:
//  String - ID Of The Production Costs Group
Function IDOfProductionCostsGroup() Export
	Return "ProductionCosts";
EndFunction

// ID of the cost group.
// 
// Returns:
//  String - ID Of The Cost Group
Function IDOfCostGroup() Export
	Return "Cost_";
EndFunction

// ID of the Financial result generation group.
// 
// Returns:
//  String - ID Of The Financial Result Generation Group
Function IDOfFinancialResultGenerationGroup() Export
	Return "FinancialResultGenerationGroup";
EndFunction

// ID of the regulated accounting group.
// 
// Returns:
//  String - Group ID Regulated Accounting
Function GroupIDRegulatedAccounting() Export
	Return "LocalAccounting";
EndFunction

// ID of the international accounting group.
// 
// Returns:
//  String - ID Of The International Accounting Group
Function IDOfInternationalAccountingGroup() Export
	Return "FinancialAccounting";
EndFunction

// ID of the change blocking group.
// 
// Returns:
//  String - Id Of The Change Blocking Group
Function IdOfChangeBlockingGroup() Export
	Return "BlockingFromChanges";
EndFunction

// ID of the non-operational document verification group.
// 
// Returns:
//  String - ID of the non-operational document verification group
Function IdOfNonOperationalTaskQueueGroup() Export
	Return "BackdateJobQueue";
EndFunction

// ID of the group of non-operational additional verification of documents (reflection of Registered Records of documents on the Upr.balance)
// 
// Returns:
//  String - ID of the group reflecting Registered Records of documents on the management balance sheet
Function IdOfGroupReflectsRegisteredRecordsOfManBalance() Export
	Return "RecordBalanceSheetStatementRegisterRecords";
EndFunction
#EndRegion

#EndRegion

#Region DescriptionOfStages

// Filling in the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
//
Procedure FillInDescriptionOfClosingStagesOfMonth(StepsTable) Export

	#Region Group_ManualOperations
	
	CurrentParent = IDOfManualOperationsGroup();
	
	// Transition to new accounting modes.
	AddStage_TransitionToNewModesOfOperation(StepsTable, CurrentParent);
	
	// Errors in the data.
	CostCalculationCostAdjustment.AddStage_ClearingPostingsWithDisabledCostAccounting(StepsTable, CurrentParent);
	InventoriesServer.AddStage_CorrectDuplicatesOfInventoryOwnerAttributes(StepsTable, CurrentParent);
	AddStage_CorrectErrorsInInitialData(StepsTable, CurrentParent);
	
	// Unfulfilled routine operations.
	InventoriesServer.AddStage_CorrectNegativeStockBalanceOfCompanyGoods(StepsTable,CurrentParent);
	IncomeAndExpensesServer.AddStage_DeferredExpensesAllocation(StepsTable, CurrentParent);
	FutureExpenseCommitments.AddStage_FutureExpenseCommitmentsAccrualWriteOff(StepsTable, CurrentParent);
	ProductionServer.AddStage_RegisterBackflushProduction(StepsTable, CurrentParent);
	ProductionServer.AddStage_AcceptInternalWorks(StepsTable, CurrentParent);
	ProcessingByThirdParties.AddStage_RequirementsForProcessingProcessorsReports(StepsTable, CurrentParent);
	TollingScheme.AddStage_BalancesForReportingToGivers(StepsTable, CurrentParent);
	InternalSubcontractingServer.AddStage_BalancesForReportingToGivers(StepsTable, CurrentParent);
	ProductionManagement.AddStage_ProductionPlanningProductsWithoutBOM(StepsTable,CurrentParent);
	CostsServer.AddStage_AllocationOfMaterialsAndWorksToProductsCost22(StepsTable,CurrentParent);
	CostsServer.AddStage_ConfigureIndicatorsForCostAllocationToProductCost(StepsTable, CurrentParent);
	CostsServer.AddStage_ConfigureIndicatorsForExpensesAllocationBetweenExpenseObjects(StepsTable, CurrentParent);
	InventoriesServer.AddStage_RegisterGoodsTransfers(StepsTable,CurrentParent);
	InventoriesServer.AddStage_RegisterGoodsStockToTransfer(StepsTable,CurrentParent);
	InventoriesServer.AddStage_RegisterGoodsRedemption(StepsTable,CurrentParent);
	InventoriesServer.AddStage_RegistrationOfCommissionReportsIntercompany(StepsTable,CurrentParent);
	InventoriesServer.AddStage_RegisterWriteOffReportsToConsignors(StepsTable,CurrentParent);
	FinancialInstruments.AddStage_LoansDepositsAndBorrowingsIssuedInterestCharge(StepsTable,CurrentParent);
	NonCurrentAssets.AddStage_FillInActualCostOfFixedAssetsWithDisabledCostAccounting(StepsTable,CurrentParent);
	CashServer.AddStage_CheckOffsetRatesInExpenseReports(StepsTable, CurrentParent);
	#EndRegion
	
	#Region Group_NonOperationalTaskQueue
	CurrentParent = IdOfNonOperationalTaskQueueGroup();
	BackdateJobQueue.AddStage_CalculationOfDocumentAmountsInAccountingCurrenciesAndRepostingFinancialRegisters(StepsTable,CurrentParent);
	#EndRegion
	
	#Region Group_Settlements
	
	CurrentParent = IDOfSettlementsGroup();
	
	ARAPAccountingServer.AddStage_PostingToPartnersARAPAccountingAndARAPRevaluation(StepsTable,CurrentParent);
	
	Documents.CalculationOfDiscountInterestExpenses.AddStage_CalculationOfDiscountInterestExpenses(StepsTable, CurrentParent);
	LeasedAssetAccounting.AddStage_AccrueProfitableRentalInterest(StepsTable, CurrentParent);
	Documents.ExchangeDifferenceCalculation.AddStage_RevaluationOfCashAndFinancialInstruments(StepsTable,CurrentParent);
	
	Documents.ExchangeDifferenceCalculation.AddStage_RevaluationOfSettlementsWithCommitteeCommissionAgent(StepsTable,CurrentParent);
	//++ WE
	Documents.ExchangeDifferenceCalculation.AddStage_PayrollCalculationRevaluation(StepsTable,CurrentParent);
	//-- WE
	#EndRegion
	
	#Region Group_CostGeneration
	
	CurrentParent = IDOfCostGenerationGroup();
	ProductionServer.AddStage_RegisterWorkOutput(StepsTable, CurrentParent);
	DeferredFARecordGeneration.AddStage_UpdatingFARecordsBeforeCalculatingDepreciation(StepsTable,CurrentParent);
	FixedAssetDepreciationCalculation.AddStage(StepsTable, CurrentParent);
	IntangibleAssetAmortizationCalculation.AddStage(StepsTable, CurrentParent);
	LeasedAssetAccounting.AddStage_AccrualOfLeaseInterest(StepsTable, CurrentParent);
	DeferredFARecordGeneration.AddStage(StepsTable,CurrentParent);
	ClosingExpensesFromDisposalOfFixedAssets.AddStage(StepsTable, CurrentParent);
	Documents.ExchangeDifferenceCalculation.AddStage_RevaluationOfLeases(StepsTable,CurrentParent);
	AccrualAndWriteOffOfBadDebtAlowancesServer.AddStage_GenerateLossAllowance(StepsTable,
		CurrentParent);
	#EndRegion

	#Region Group_ProductionCosts
	
	CurrentParent = IDOfProductionCostsGroup();
	CostsServer.AddStage_ConfigureCostAllocation(StepsTable, CurrentParent);
	CostsServer.AddStage_ConfigureExpensesAllocationThatRequireManualInput(StepsTable, CurrentParent);
	
	#EndRegion
	
	#Region Group_CostOfSales
	
	CurrentParent = IDOfCostGroup();
	
	CostCalculationCostAdjustment.AddStage_LotsAndCostCalculation(StepsTable, CurrentParent);
	VATAccountingERP.AddStage_VATAllocation(StepsTable,CurrentParent);
	RDExpensesAccounting.AddStage_RDExpenseRecognition(StepsTable, CurrentParent);
	FACostCalculation.AddStage(StepsTable, CurrentParent);
	FACostCalculation.AddStage_UpdatingRecordsOfFixedAssetsAndIntangibleAssets(StepsTable, CurrentParent);
	CalculateRentalInvestmentCost.AddStage(StepsTable, CurrentParent);
	#EndRegion
	
	#Region Group_FormationOfFinancialResult
	
	CurrentParent = IDOfFinancialResultGenerationGroup();
	ImpairmentFAServer.AddStage_FormationOfRegisteredRecordsOnDevaluationOfVNA(StepsTable, CurrentParent);
	VATAccountingERP.AddStage_PostingGenerationInVATAccounting(StepsTable, CurrentParent);
	Documents.CalculationOfInventoryImpairmentProvision.AddStage_AccualOfInventoryImpairmentProvision(
		StepsTable,
		CurrentParent);
	Documents.AllocationOfOtherCosts.AddStage_RegistrationOfCostAllocationDocuments(
		StepsTable,
		CurrentParent);
		
	Documents.AllocationOfOtherCosts.AddStage_AllocationOfExpensesByLinesOfBusiness(
		StepsTable,
		CurrentParent);
	
	Documents.AllocationOfIncomeByLinesOfBusiness.AddStage_AllocationOfIncomeByLinesOfBusiness(
		StepsTable,
		CurrentParent);

	#EndRegion
	#Region Group_InternationalAccounting
	CurrentParent = IDOfInternationalAccountingGroup();
	FinancialAccountingOfMonthEndClosing.AddStage_DocumentPostingInFinancialAccounting(StepsTable, CurrentParent);
	FinancialAccountingOfMonthEndClosing.AddStage_ReclassificationOfLongTermAssetsAndLiabilities(StepsTable, CurrentParent);
	FinancialAccountingOfMonthEndClosing.AddStage_ExchangeDifferenceCalculationInFunctionalCurrency(StepsTable, CurrentParent);
	FinancialAccountingOfMonthEndClosing.AddStage_ClosingOfGLAccountsOfIncomeAndExpensesFinancialAcconting(StepsTable, CurrentParent);
	FinancialAccountingOfMonthEndClosing.AddStage_ExchangeDifferenceCalculationInPresentationCurrency(StepsTable, CurrentParent);
	FinancialAccountingOfMonthEndClosing.AddStage_SettingOfClosingDateForPostingInFinancialAccounting(StepsTable,CurrentParent);
	#EndRegion
	#Region Group_ReflectsRegisteredRecordsOfDocumentsOnManagementBalanceSheet
	CurrentParent = IdOfGroupReflectsRegisteredRecordsOfManBalance();
	BackdateJobQueue.AddStage_PostingDocumentRegisteredRecordsInBalanceSheetStatement(StepsTable,CurrentParent);
	#EndRegion
	
	#Region Group_BlockingFromChanges
	
	CurrentParent = IdOfChangeBlockingGroup();
	
	AddStage_LockFromChanges(StepsTable, CurrentParent);
	
	#EndRegion
	
	MonthEndTransactionsLocalization.AddDescriptionOfClosingStagesOfMonth(StepsTable);
	
EndProcedure

#EndRegion

#EndRegion

#Region HandlersForMonthClosingStages

// In this area there are:
// 1. The texts of the procedures-handlers of the events of the closing stages of the month.
// The steps themselves are described in the Fill-in description of the Closing steps of the month().
// 2. Description of system health checks related to the closing stages of the month.
// The descriptions of the checks are used in the fill-in check for registration().
// 3. The texts of the procedures for checking the status of accounting.

#Region Group_ManualOperations

#Region TransitionToNewModesOfOperation

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
//	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
//
Procedure AddStage_TransitionToNewModesOfOperation(StepsTable, CurrentParent) Export
	
	NewRow = AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.TransitionToNewAccountingModes);
	
	NewRow.MultilingualName = "ru = 'Требуется осуществить переход на новые режимы учета';
								|vi = 'Migrate to new accounting modes';
								|en = 'Migrate to new accounting modes';
								|it = 'Migrate to new accounting modes';
								|pl = 'Migrate to new accounting modes';
								|tr = 'Yeni muhasebe modlarına geçiş yapılması gerekiyor'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.informational = True;
	NewRow.ReadMoreText     = DefaultDetailsText();
	NewRow.ActionUse = ActionDescription_ServerProcedure(
		"MonthEndTransactionsServer.Use_SwitchToNewOperatingModes");
	NewRow.ActionMoreDetails  = ActionDescription_OpenObjectHelp(
		Metadata.DataProcessors.MonthEndClosingOperations.Forms.FormOfHelpTransitionToNewModes);
	
EndProcedure

// The use of information about the transition to new accounting regimes.
// 
// Parameters:
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
//
Procedure Use_SwitchToNewOperatingModes(HandlerParameters) Export
	
	// When closing the current and previous month, we increase the importance of the problem.
	If BegOfMonth(HandlerParameters.CalculationParameters.Period) >= AddMonth(BegOfMonth(CurrentSessionDate()), -1) Then
		DefaultStatus = Enums.AccountingIssueSeverity.ImportantInformation;
	Else
		DefaultStatus = Enums.AccountingIssueSeverity.Warning;
		HandlerParameters.Data_Stage.Description = NStr("ru = 'Рекомендуется осуществить переход на новые режимы учета';
														|vi = 'It is recommended to migrate to new accounting modes.';
														|en = 'It is recommended to migrate to new accounting modes.'; fa = 'توصیه می‌شود به حالت‌های حسابداری جدید مهاجرت کنید.';
														|it = 'It is recommended to migrate to new accounting modes.';
														|pl = 'It is recommended to migrate to new accounting modes.';
														|tr = 'Yeni muhasebe modlarına geçiş önerilmektedir'");
	EndIf;
	DefaultHyperlinkText = NStr("vi = 'Chuyển đến';
								|ru = 'Перейти';
								|en = 'Navigate'; fa = 'پیمایش';
								|it = 'Vai a';
								|pl = 'Przejdź';
								|tr = 'Git'", Common.DefaultLanguageCode());
	
	
	// Mutual settlements.
	If Not GetFunctionalOption("BaseVersion") And Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("vi = 'Đối trừ (trực tuyến)';
				|ru = 'Взаиморасчеты (онлайн)';
				|en = 'Mutual settlements (online)'; fa = 'Mutual settlements (online)';
				|it = 'Conti reciproci (on-line)';
				|pl = 'Rozliczenia wzajemne (online)';
				|tr = 'Mutabakatlar (çevrim içi)'", Common.DefaultLanguageCode()),
			DefaultHyperlinkText,
			ActionDescription_OpenForm(Metadata.DataProcessors.TMAdministrationPanel.Forms.TreasuryAndARAPAccounting.FullName()),
			DefaultStatus);
		
	EndIf;
	
	
	// Transfer to recycling.
	
	// Non-current assets.
	If GetFunctionalOption("UseNonCurrentAssets2_2")
	 And Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		
		SetStateExecutedWithErrors(
			HandlerParameters,
			NStr("vi = 'Kế toán tài sản dài hạn (phiên bản 2.4)';
				|ru = 'Учет внеоборотных активов (версия 2.4)';
				|en = 'Fixed and intangible assets (version 2.4)'; fa = 'Fixed and intangible assets (version 2.4)';
				|it = 'Contabilità degli attivi non circolanti (versione 2.4)';
				|pl = 'Ewidencja aktywów pozaobrotowych (wersji 2.2)';
				|tr = 'Duran varlıklar hesabı (sürüm 2.4)'", Common.DefaultLanguageCode()),
			DefaultHyperlinkText,
			ActionDescription_OpenForm(Metadata.DataProcessors.CAAdministrationPanel.Forms.NonCurrentAssets.FullName()),
			DefaultStatus);
		
	EndIf;
	
	
	// Accounting policies: a method of estimating the value of FIFO (weighted).
	If CalculationOfCostCached.BatchAccountingVersion22() Then
		TextTemplate1 = NStr("vi = 'Đối với doanh nghiệp ""%1"", hãy sử dụng phương pháp tính giá theo tỷ lệ (điểm số)';
							|ru = 'Для организации ""%1"" использовать метод оценки стоимости ""ФИФО (скользящая оценка)""';
							|en = 'For the ""%1"" company, use the ""FIFO (rolling valuation)"" method of valuation'; fa = 'For the ""%1"" company, use the ""FIFO (rolling valuation)"" method of valuation';
							|it = 'Per l''azienda ""%1"" utilizzare metodo di valutaizone del prezzo ""FIFO (valutazione flessibile)""';
							|pl = 'Dla firmy ""%1"" użyj metodę oceny kosztów ""FIFO (ruchoma ocena)""';
							|tr = '""%1"" iş yeri için ""FIFO (hareketli değerleme)"" değerleme yöntemini kullan'", Common.DefaultLanguageCode());
	Else
		TextTemplate1 = NStr("vi = 'Đối với doanh nghiệp  %1, sử dụng Phương pháp ước tính chi phí trung bình hàng tháng';
							|ru = 'Для организации ""%1"" использовать метод оценки стоимости ""Средняя за месяц""';
							|en = 'For the ""%1"" company, use the ""Average per month"" method of valuation'; fa = 'For the ""%1"" company, use the ""Average per month"" method of valuation';
							|it = 'Per l''azienda ""%1"" utilizzare metodo di valutazione del prezzo ""Media mensile""';
							|pl = 'Dla firmy „%1"" użyj metodę wyceny wartości ""średnia za miesiąc""';
							|tr = '""%1"" iş yeri için ""Aylık ortalama"" değerleme yöntemini kullan'", Common.DefaultLanguageCode());
	EndIf;
	
	Query = New Query;
	TempTablesManager = New TempTablesManager();
	AccountingPoliciesTaxSettings.AddParentOrganizationsToTemporaryTableManager(TempTablesManager, 
		HandlerParameters.CalculationParameters.CompanyArray);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CompanyArray", HandlerParameters.CalculationParameters.CompanyArray);
	
	Query.Text =
	"SELECT DISTINCT
	|	ParentOrganizations.BranchOffice AS Organization
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(, Organization IN
	|			(SELECT
	|				ParentOrganizations.Organization
	|			FROM
	|				TTParentOrganizations AS ParentOrganizations)) AS T
	|		ON ParentOrganizations.Organization = T.Organization
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.FIFOWeightedEstimate)
	|
	|ORDER BY
	|	Organization";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ActionDetails = ActionDescription_OpenForm(Metadata.Catalogs.Companies.Forms.ItemForm.FullName());
		ActionDetails.FormParameters.Insert("Key", Selection.Organization);
		
		SetStateExecutedWithErrors(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, Selection.Organization),
			DefaultHyperlinkText,
			ActionDetails,
			DefaultStatus);
		
	EndDo;
	
	If Not StageStateDefined(HandlerParameters.Data_Stage) Then
		
		NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Chế độ hoạt động lỗi thời không được sử dụng.';
				|ru = 'Устаревшие режимы работы не используются.';
				|en = 'Obsolete operation modes are not used.'; fa = 'Obsolete operation modes are not used.';
				|it = 'Le modalità di funzionamento obsolete non sono utilizzate.';
				|pl = 'Nieaktualne tryby działania nie są używane.';
				|tr = 'Eski iş modları kullanılmıyor.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CorrectErrorsInInitialData

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
//	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
//
Procedure AddStage_CorrectErrorsInInitialData(StepsTable, CurrentParent) Export
	
	NewRow = AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData);
		
	NewRow.MultilingualName = "vi = 'Sửa lỗi trong dữ liệu nguồn';
								|ru = 'Исправление ошибок в исходных данных';
								|en = 'Correct errors in the initial data';
								|it = 'Correzione degli errori nei dati iniziali';
								|pl = 'Korekta błędów w danych źródłowych';
								|tr = 'Kaynak verilerdeki hataların düzeltilmesi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ReadMoreText     = DefaultDetailsText();
	NewRow.ActionMoreDetails  = ActionDescription_OpenVerificationResults(,, NewRow.Code);
	
EndProcedure

Procedure DescriptionOfChecks_CorrectionOfErrorsInSourceData(TableOfChecks)
	
	// Correctness of the implementation specified in the return.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"CorrectnessOfImplementationSpecifiedInReturn",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"InventoriesServer.CheckingCorrectnessOfImplementationSpecifiedInReturn");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tính đúng đắn của việc thực hiện được quy định trong tờ khai.';
			|ru = 'Корректность реализации, указанной в возврате.';
			|en = 'Whether the sale specified in the return is correct.'; fa = 'Whether the sale specified in the return is correct.';
			|it = 'Correttezza dell''implementazione specificata nel reso.';
			|pl = 'Poprawność realizacji, wskazanej  w zwrocie.';
			|tr = 'İadede belirtilen satışın doğruluğu.'"),
		NStr("vi = 'Nếu thay đổi ngày trở về trước của chứng từ bán hàng thì thành phần hàng hóa của chứng từ nhận hàng bán trả lại từ khách hàng có thể không được đồng bộ với chứng từ bán hàng.
			|Trong trường hợp này, trong chứng từ trả lại cần chỉ ra chứng từ bán hàng chính xác hoặc không cần chỉ ra chứng từ bán hàng.';
			|ru = 'При изменении задним числом документа реализации товарный состав документа возврата от клиента может рассинхронизироваться с реализацией.
			|В этом случае в документе возврата необходимо или указать корректный документ реализации или вообще не указывать его.';
			|en = 'If sales document is changed post factum, goods content of customer return document can be different from the sale. 
			|In this case, specify correct document in the return document or do not specify it at all.'; fa = 'If sales document is changed post factum, goods content of customer return document can be different from the sale. 
			|In this case, specify correct document in the return document or do not specify it at all.';
			|it = 'Quando un documento retrodatato cambia, la composizione della merce del documento di reso dal cliente può non essere più sincronizzata con il realizzo.
			|In questo caso il documento di ritorno deve indicare il documento di realizzo corretto o non indicarlo affatto.';
			|pl = 'W przypadku zmiany z datą wsteczną dokumentu sprzedaży skład towarowy dokumentu zwrotu od klienta może desynchronizować się ze sprzedażą.
			|W tym przypadku w dokumencie zwrotu należy albo wskazać poprawny dokument sprzedaży albo wcale nie wskazywać go.';
			|tr = 'Satış belgesi geriye dönük olarak değiştirilirse, müşteriden gelen iade belgesinin ürün bileşimi satışı ile uyumsuz olabilir.
			|Bu durumda, iade belgesi ya doğru satış belgesini belirtmeli ya da hiç belirtmemelidir.'"));
	
	// The correctness of the transfer specified in the return.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"CorrectnessOfTransferSpecifiedInReturn",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"MonthEndTransactionsServer.CheckingCorrectnessOfTransferSpecifiedInReturn");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tính đúng đắn của việc thực hiện được quy định trong tờ khai.';
			|ru = 'Корректность реализации, указанной в возврате.';
			|en = 'Whether the sale specified in the return is correct.'; fa = 'Whether the sale specified in the return is correct.';
			|it = 'Correttezza dell''implementazione specificata nel reso.';
			|pl = 'Poprawność realizacji, wskazanej  w zwrocie.';
			|tr = 'İadede belirtilen satışın doğruluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Nếu thay đổi ngày trở về trước của chứng từ bán hàng thì thành phần hàng hóa của chứng từ nhận hàng bán trả lại từ khách hàng có thể không được đồng bộ với chứng từ bán hàng.
			|Trong trường hợp này, trong chứng từ trả lại cần chỉ ra chứng từ bán hàng chính xác hoặc không cần chỉ ra chứng từ bán hàng.';
			|ru = 'При изменении задним числом документа реализации товарный состав документа возврата от клиента может рассинхронизироваться с реализацией.
			|В этом случае в документе возврата необходимо или указать корректный документ реализации или вообще не указывать его.';
			|en = 'If sales document is changed post factum, goods content of customer return document can be different from the sale. 
			|In this case, specify correct document in the return document or do not specify it at all.'; fa = 'If sales document is changed post factum, goods content of customer return document can be different from the sale. 
			|In this case, specify correct document in the return document or do not specify it at all.';
			|it = 'Quando un documento retrodatato cambia, la composizione della merce del documento di reso dal cliente può non essere più sincronizzata con il realizzo.
			|In questo caso il documento di ritorno deve indicare il documento di realizzo corretto o non indicarlo affatto.';
			|pl = 'W przypadku zmiany z datą wsteczną dokumentu sprzedaży skład towarowy dokumentu zwrotu od klienta może desynchronizować się ze sprzedażą.
			|W tym przypadku w dokumencie zwrotu należy albo wskazać poprawny dokument sprzedaży albo wcale nie wskazywać go.';
			|tr = 'Satış belgesi geriye dönük olarak değiştirilirse, müşteriden gelen iade belgesinin ürün bileşimi satışı ile uyumsuz olabilir.
			|Bu durumda, iade belgesi ya doğru satış belgesini belirtmeli ya da hiç belirtmemelidir.'", Common.DefaultLanguageCode()));
		
	// Filling in GTD numbers in refunds.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"CorrectnessOfFillingInGTDNumbersInRefunds",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"MonthEndTransactionsServer.CheckingCorrectnessOfFillingInGTDNumbersInRefunds");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tính chính xác của dấu hiệu của các số TKHQ được chỉ ra trong phần hoàn trả.';
			|ru = 'Корректность указания номеров ГТД, указанных в возврате.';
			|en = 'Correctness of indication of CFD numbers specified in the return.'; fa = 'Correctness of indication of CFD numbers specified in the return.';
			|it = 'La correttezza di specificare i numeri della dichiarazione doganale indicati nella restituzione.';
			|pl = 'Poprawność podania numerów ŁDC, podanych w zwrocie.';
			|tr = 'İadede belirtilen Gümrük Kargo Beyannamesi numaralarının belirtme doğruluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đã lập chứng từ trả lại những mặt hàng có ghi nhận theo tờ khai hải quan, nhưng vẫn chưa chỉ ra số tờ khai hải quan.
			|Trong trường hợp này, trong chứng từ trả lại, cần chỉ ra số tờ khai hải quan.';
			|ru = 'Были оформлены возвраты товаров, для которых включен учет по номерам ГТД, но номера ГТД не были указаны.
			|В этом случае в документе возврата необходимо указать номера ГТД.';
			|en = 'Returns of goods for which accounting upon CFD numbers is enabled were registered, but CFD numbers were not specified.
			|In this case you should specify CFD numbers in documents of return.'; fa = 'Returns of goods for which accounting upon CFD numbers is enabled were registered, but CFD numbers were not specified.
			|In this case you should specify CFD numbers in documents of return.';
			|it = 'Sono state formalizzate le restituzioni delle merci per le quali era inclusa la contabilità per numeri di dichiarazioni doganali, ma i numeri delle dichiarazioni doganali non sono stati indicati.
			| In tal caso nel documento di restituzione è necessario indicare il numero di dichiarazione doganale.';
			|pl = 'Zostały sporządzone zwroty towarów, dla których włączono ewidencję według numerów ŁDC, ale numery ŁDC nie zostały podane.
			|W tym przypadku w dokumencie zwrotu należy podać numery ŁDC.';
			|tr = 'GKB numarasına göre muhasebeleştirmenin etkinleştirildiği ancak GKB numarası belirtilmeyen ürünler iade edildi.
			|Bu durumda GKB numarasının iade belgesinde belirtilmesi gerekir.'", Common.DefaultLanguageCode()));
	
	// Obsolete types of stocks with leftovers.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"ObsoleteInventoryTypesWithBalancesUpdateRecords",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"InventoriesServer.ObsoleteInventoryTypesWithBalancesUpdateRecords");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Cập nhật sổ đăng ký thông tin ""Các loại cổ phiếu lỗi thời có số dư""';
			|ru = 'Актуализация регистра сведений ""Устаревшие виды запасов с остатками""';
			|en = 'Update the ""Obsolete inventory owner attributes with balance"" information register'; fa = 'Update the ""Obsolete inventory owner attributes with balance"" information register';
			|it = 'Attualizzazione del registro di informazioni ""Tipi obsoleti delle provviste con rimanenze""';
			|pl = 'Aktualizacja rejestru informacji ""Устаревшие виды запасов с остатками""';
			|tr = '""Bakiyeli eski stok türleri"" bilgi kaydının güncellenmesi'", Common.DefaultLanguageCode()),
		NStr("vi = 'Biểu ghi thông tin chứa danh sách các dạng vật tư đã cũ,
		|theo đó vẫn còn số dư trong biểu ghi ""Hàng trong doanh nghiệp"" và cần được ghi giảm vào chi phí.';
		|ru = 'Регистр сведений содержит список устаревших видов запасов,
		|по которым еще есть остатки в регистре ""Товары организаций"" и которые должны быть списаны при расходе.';
		|en = 'Information register contains a list of obsolete inventory owner attributes
		|by which there is balance in the ""Company goods"" register and which should be written off at release.'; fa = 'Information register contains a list of obsolete inventory owner attributes
		|by which there is balance in the ""Company goods"" register and which should be written off at release.';
		|it = 'Il registro delle informazioni contiene un elenco di tipi obsoleti delle provviste
		|per le quali ci sono ancora rimanenze nel registro ""Merci delle organizzazioni"" e che devono essere stornate durante l''uscita.';
		|pl = 'Rejestr informacji zawiera listę przestarzałych rodzajów zapasów,
		|wg których jeszcze są pozostałości w rejestrze ""Товары организаций"" i które powinny być wyksięgowane przy rozchodach.';
		|tr = 'Bilgi kaydı, ""İş yeri ürünler"" kaydında hala bakiyeleri bulunan ve tüketildiğinde silinmesi gereken
		|eski stok türlerinin bir listesini içerir.'", Common.DefaultLanguageCode()));
	
	
	// Issue at a fixed cost without issue at the estimated in the report of the processor 2.5
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"SideIssueWithoutMainOneInReportOfProcessor25",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"ProcessingByThirdParties.CheckingForSecondaryReleaseWithoutMainOneInProcessorSReport25");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Có bảng kê hàng hóa của bên nhận gia công có xuất xưởng giá trị cố định mà không xuất xưởng theo giá trị ước tính';
			|ru = 'Наличие отчетов переработчика с выпуском по фиксированной стоимости без выпуска по расчетной';
			|en = 'Availability of subcontracting services notifications received with release at the fixed cost without release at the estimated cost'; fa = 'Availability of subcontracting services notifications received with release at the fixed cost without release at the estimated cost';
			|it = 'Наличие отчетов переработчика с выпуском по фиксированной стоимости без выпуска по расчетной';
			|pl = 'Availability of subcontracting services notifications received with release at the fixed cost without release at the estimated cost';
			|tr = 'Tahmini maliyetle ürün çıkışı olmadan sabit maliyetle ürün çıkışlı fason üretici hizmetleri bildirimlerinin mevcudiyeti'", Common.DefaultLanguageCode()),
		NStr("vi = 'Không xuất xưởng theo giá trị ước tính trong SSDD, có thể còn các chi phí chưa được kết chuyển.';
			|ru = 'Без выпуска по расчетной стоимости в НЗП могут остаться незакрытые суммы затрат.';
			|en = 'Without release at the estimated cost, unclosed cost amounts might remain in WIP.'; fa = 'Without release at the estimated cost, unclosed cost amounts might remain in WIP.';
			|it = 'Без выпуска по расчетной стоимости в НЗП могут остаться незакрытые суммы затрат.';
			|pl = 'Without release at the estimated cost, unclosed cost amounts might remain in WIP.';
			|tr = 'Tahmini maliyete göre ürün çıkışı olmadan, TMÜ kapsamında kapatılmamış maliyet tutarları kalabilir.'", Common.DefaultLanguageCode()));

	// The reversed production documents without an order are indicated in the cost allocation documents.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"CorrectnessOfIndicationOfProductionBatches",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"CostsServer.CheckingCorrectnessOfIndicationOfProductionBatches");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tính chính xác khi chỉ ra chứng từ sản xuất mà không có đơn hàng trong các chứng từ phân bổ chi phí.';
			|ru = 'Корректность указания документов производства без заказов в документах распределения расходов.';
			|en = 'Accuracy of backflush production documents specification in the expenses allocation documents.'; fa = 'Accuracy of backflush production documents specification in the expenses allocation documents.';
			|it = 'Correttezza dell''indicazione di documenti di produzione senza ordini nei documenti di allocazione delle spese.';
			|pl = 'Poprawność wskazania dokumentów produkcji bez zamówień w dokumentach przydzielenia rozchodów.';
			|tr = 'Gider dağıtım belgelerinde siparişsiz üretim belgelerinin belirtilmesinin doğruluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đã chỉ định chứng từ sản xuất không có đơn hàng mà có nhập đảo ngược hoặc chỉnh sửa.';
			|ru = 'Указаны документы производства без заказов для которых введено сторно или исправление.';
			|en = 'Specifies backflush production documents with storno or correction.'; fa = 'Specifies backflush production documents with storno or correction.';
			|it = 'Specifies backflush production documents with storno or correction.';
			|pl = 'Specifies backflush production documents with storno or correction.';
			|tr = 'Listelenen belgeler, iptal veya düzeltme girişi yapılmış, geriye dönük üretim belgeleridir.'", Common.DefaultLanguageCode())); 	
		
	// Outdated production batches are indicated in the cost allocation documents.

	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"RelevanceOfSpecifiedProductionBatches",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"CostsServer.CheckingRelevanceOfSpecifiedProductionBatches");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tính chính xác khi chỉ ra lô hàng sản xuất trong chứng từ phân bổ chi phí.';
			|ru = 'Корректность указания партий производства в документах распределения расходов.';
			|en = 'Correctness of specification of production lots in the expense allocation documents.'; fa = 'Correctness of specification of production lots in the expense allocation documents.';
			|it = 'Correttezza nell''indicare lotti di produzione nei documenti di ripartizione delle spese.';
			|pl = 'Poprawność wskazania partii produkcji w dokumentach podziału rozchodów.';
			|tr = 'Giderlerin dağıtım belgelerinde üretim lotlarının belirtilmesinin doğruluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đã chỉ ra lô hàng sản xuất không tương ứng với chứng từ ""Sản xuất không theo đơn đặt hàng""...';
			|ru = 'Указаны партии производства, не соответствуюшие документам ""Производство без заказа""..';
			|en = 'You have specified production lots that do not correspond to the ""Backflush production"" documents.'; fa = 'You have specified production lots that do not correspond to the ""Backflush production"" documents.';
			|it = 'Sono indicati lotti di produzione non corrispondenti ai documenti ""Produzione senza ordine"".';
			|pl = 'Podano partie produkcji, nie odpowiadające dokumentom ""Produkcja bez zamówienia""..';
			|tr = 'Üretim lotları belirtilmiştir, ""Geriye dönük üretim"" belgelerine karşılık gelmezler..'", Common.DefaultLanguageCode()));
		
	// The same articles of culculation for materials and side output at a fixed cost are indicated.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"CorrectnessOfSpecifyingCalculationArticlesForSideOutput",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"CostsServer.CheckingWhetherCalculationArticlesForSideOutputAreSpecifiedCorrectly");
		
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tính chính xác khi chỉ ra các dạng tính giá thành đối với các sản phẩm phụ.';
			|ru = 'Корректность указания статей калькуляций для побочных изделий.';
			|en = 'Accuracy of product cost element for by-products.'; fa = 'Accuracy of product cost element for by-products.';
			|it = 'Correttezza di indicazione delle voci di calcolo per i sottoprodotti.';
			|pl = 'Poprawność podania pozycji kalkulacji dla wyrobów ubocznych.';
			|tr = 'Yan nihai ürünler için ürün maliyet öğelerinin belirtilmesinin doğruluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đã chỉ ra các dạng tính giá thành giống nhau đối với nguyên vật liệu và sản lượng phụ theo giá trị cố định.';
			|ru = 'Указаны одинаковые статьи кулькуляции для материалов и побочного выхода по фиксированной стоимости.';
			|en = 'Identical product cost elements are specified for materials and side products at a fixed cost.'; fa = 'Identical product cost elements are specified for materials and side products at a fixed cost.';
			|it = 'Sono specificate le stesse voci di calcolo per i materiali e per i prodotti secondari a prezzo fisso.';
			|pl = 'Podano jednakowe pozycje kalkulacji dla materiałów i produkcji ubocznej wg stałej wartości.';
			|tr = 'Aynı ürün maliyet öğeleri, sabit bir maliyetle malzemeler ve yan çıktılar için belirtilmiştir.'", Common.DefaultLanguageCode())); 	
	
	// Product groups are indicated in batches, despite the disabled option of accounting by groups
	If Not GetFunctionalOption("AnalyticalAccountingByProductsGroups") Then
		VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
			"CorrectnessOfSpecifyingProductGroupsInProductionBatches",
			Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
			Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
			"CostsServer.CheckingCorrectnessOfIndicationOfProductGroupsInProductionBatches");
			
		FillInPresentationOfNewCheck(VerificationDescription,
			NStr("vi = 'Tính chính xác khi chỉ ra nhóm sản phẩm trong lô hàng sản xuất.';
				|ru = 'Корректность указания групп продукции в партиях производства.';
				|en = 'Correctness of specifying manufactured product groups in production lots.'; fa = 'Correctness of specifying manufactured product groups in production lots.';
				|it = 'Correttezza dell''indicazione dei gruppi di produzione in lotti di produzione.';
				|pl = 'Poprawność wskazania grup produkcji w partiach produkcji.';
				|tr = 'Üretim lotlarındaki imal edilen ürün gruplarının belirtme doğruluğu.'", Common.DefaultLanguageCode()),
			NStr("vi = 'Trong lô hàng sản xuất có sử dụng nhóm sản phẩm, mặc dù đã tắt tùy chọn kế toán theo nhóm sản phẩm.';
				|ru = 'В партиях производства используются группы продукции, несмотря на отключенную опцию учета по группам продукции.';
				|en = 'Manufactured product groups are disabled but still manufactured product groups are used in production lots. '; fa = 'Manufactured product groups are disabled but still manufactured product groups are used in production lots. ';
				|it = 'Nei lotti di produzione sono utilizzati gruppi di produzione indipendentemente dall''opzione disabilitata di contabilità per gruppi di produzione.';
				|pl = 'W partiach produkcji są używane grupy produkcji, chociaż opcja ewidencji według produkcji jest wyłączona.';
				|tr = 'İmal edilen ürün grubuna göre hesap oluşturma seçeneği devre dışı bırakılmış olsa bile, üretim lotları imal edilen ürün gruplarını kullanır.'", Common.DefaultLanguageCode())); 	
	EndIf;
	
	// Compliance of the processor's report and adjustments to the recycling report.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"ComplianceOfProcessorReportAndAdjustmentsOfProcessorReport",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"CostsServer.VerifyComplianceOfProcessorReportAndAdjustmentsOfProcessorReport");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'So sánh bảng kê của bên nhận gia công và điều chỉnh bảng kê của bên nhận gia công.';
			|ru = 'Соответствие отчета переработчика и корректировки отчета переработчика.';
			|en = 'Mapping of the ""Subcontracting services notification received"" and the adjustment of ""Subcontracting services notification received"".'; fa = 'Mapping of the ""Subcontracting services notification received"" and the adjustment of ""Subcontracting services notification received"".';
			|it = 'Corrispondenza del report dell''elaboratore e rettifica del report dell''elaboratore.';
			|pl = 'Zgodność raportu przetwórcy i korekty raportu przetwórcy.';
			|tr = '""Alınan fason hizmetleri bildirimi""ni ""Alınan fason hizmetleri bildirimini düzeltme"" ile eşleştirme.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần so sánh khi điền điều chỉnh bảng kê của bên nhận gia công với bảng kê của bên nhận gia công.';
			|ru = 'Заполнение корректировки отчета переработчика должно соответствовать отчету переработчика.';
			|en = 'Filling of the adjustment of ""Subcontracting services notification received"" must correspond to the ""Subcontracting services notification received"".'; fa = 'Filling of the adjustment of ""Subcontracting services notification received"" must correspond to the ""Subcontracting services notification received"".';
			|it = 'La compilazione di rettifica di report dell''elaboratore deve corrispondere al report dell''elaboratore.';
			|pl = 'Wypełnienie korekty raportu przetwórcy powinno być zgodne z raportem przetwórcy.';
			|tr = '""Alınan fason hizmetleri bildirimini düzeltme""nin doldurulması, ""Alınan fason hizmetleri bildirimi""ne karşılık gelmelidir.'", Common.DefaultLanguageCode())); 	
	// Filling in summary indicators in commission reports between organizations.
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"CorrectnessOfFillingInAmountsInCommissionReportsBetweenOrganizations",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"InventoriesServer.CheckingCorrectnessOfFillingInAmountsInCommissionReportsBetweenOrganizations");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tính chính xác của việc điền vào các chỉ số tổng trong chứng từ ""Báo cáo về hoa hồng giữa các doanh nghiệp"".';
			|ru = 'Корректность заполнения суммовых показателей в документе ""Отчет по комиссии между организациями"".';
			|en = 'Correctness of filling sum indicators in the ""Commission sales report — Intercompany"".'; fa = 'Correctness of filling sum indicators in the ""Commission sales report — Intercompany"".';
			|it = 'La correttezza della compilazione di importi totali nel documento ""Report di commissione tra le aziende"".';
			|pl = 'Poprawność wypełnienia zsumowanych wskaźników w dokumencie ""Raport według prowizji między firmami"".';
			|tr = '""İşyerleri arası komisyon satış raporu"" belgesindeki toplam göstergeleri doldurmanın doğruluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đã lập bảng kê ký gửi giữa các doanh nghiệp có các chỉ tiêu số tiền của phần bảng ""Hàng hóa"" không tương ứng với dữ liệu của phần bảng ""Dạng vật tư"".
			|Đây là thể hiện lỗi đã sửa trước đó số 00-00190359.
			|Cần kết chuyển lại các chứng từ bị lỗi, sau đó có thể là, cần đóng lại kỳ.';
			|ru = 'Оформлены отчеты по комиссии между организациями, у которых суммовые показатели табличной части ""Товары"" не соответствуют данным табличной части ""Виды запасов"".
			|Это проявление ранее исправленной ошибки № 00-00190359.
			|Проблемные документы необходимо перепровести, после этого, возможно, потребуется повторно выполнить закрытие периода.';
			|en = '""Commission reports — Intercompany"" are generated. Sum indicators of the ""Goods"" table do not match the data in the ""Inventory owner attributes"" table.
			|This is due to error No. 00-00190359 that was fixed earlier.
			|To fix this issue, you need to repost the problem documents and afterwards close the period again.'; fa = '""Commission reports — Intercompany"" are generated. Sum indicators of the ""Goods"" table do not match the data in the ""Inventory owner attributes"" table.
			|This is due to error No. 00-00190359 that was fixed earlier.
			|To fix this issue, you need to repost the problem documents and afterwards close the period again.';
			|it = 'Redatti report di commissione tra le aziende, di cui importi totali della parte tabellare ""Merci"" non corrispondono ai dati della parte tabellare ""Tipi di scorte"". 
			| è una manifestazione dell''errore № 00-00190359 corretto precedentemente. 
			| I documenti problematici devono essere registrati nuovamente, in seguito è possibile che sarà necessario ripetere la chiusura del periodo.';
			|pl = 'Sporządzone raporty według prowizji między firmami, u których zsumowane wskaźniki części tabelarycznej ""Wiersze pozycji"" nie są zgodne z danymi części tabelarycznej ""Rodzaje zapasów"".
			|Jest to przejaw wcześniej poprawionego błędu № 00-00190359.
			|Problematyczne dokumenty należy zatwierdzić ponownie, po tym, być może, trzeba będzie ponownie wykonać zamknięcie okresu.';
			|tr = '""Ürünler"" tablo bölümündeki toplamları ""Stok türleri"" tablo bölümündeki verilere karşılık gelmeyen komisyon raporu - şirketler arası düzenlendi.
			|Bu, önceden düzeltilmiş 00-00190359 numaralı hatanın göstergesidir.
			|Sorunlu belgelerin yeniden kaydı gerekir, bundan sonra dönem sonu kapanışının yeniden yapılması gerekebilir.'", Common.DefaultLanguageCode()));
	
	// Matching of organization/division pairs in documents and HIA
	VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
		"ComplianceOfOrganizationDivisionWithHIAData",
		Catalogs.MonthEndClosingOperations.CorrectErrorsInInitialData,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"CostsServer.VerificationOfComplianceOfOrganizationDivisionWithHIAData");
	
	FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Tương ứng giữa doanh nghiệp và bộ phận trong chứng từ gốc và tùy chỉnh đối tượng phát sinh chi phí.';
			|ru = 'Соответствие организации и подразделения в первичных документах и настройках объектов возникновения затрат.';
			|en = 'Correspondence of the company and business unit in the source documents and settings of cost centers.'; fa = 'Correspondence of the company and business unit in the source documents and settings of cost centers.';
			|it = 'Corrispondenza dell''azienda e del reparto nei documenti primari e nelle impostazioni dei centri di costo.';
			|pl = 'Zgodność firmy i działu w dokumentach podstawowych i ustawieniach obiektów tworzenia się rozchodów.';
			|tr = 'Birincil belgelerde ve gider nesnelerinin ayarlarında iş yeri ve departman uygunluğu.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Trong chứng từ ghi nhận chi phí và đối tượng phát sinh chi phí đã chỉ ra cần đặt trùng doanh nghiệp và bộ phận.';
			|ru = 'В документе регистрации расхода и указанном объекте возникновения затрат должны совпадать организация и подразделение.';
			|en = 'The company and business unit must match in the expense record document and the specified cost center.'; fa = 'The company and business unit must match in the expense record document and the specified cost center.';
			|it = 'Nel documento di registrazione della spese e nel centro di costo l''azienda e il reparto devono coincidere.';
			|pl = 'W dokumencie rejestracji rozchodu i wskazanym obiekcie tworzenia się rozchodów powinny być zgodne firma i dział.';
			|tr = 'İş yeri ve departman, gider kayıt belgesinde ve belirtilen gider nesnesinde eşleşmelidir.'", Common.DefaultLanguageCode()));
EndProcedure

// Checks whether the documents for the transfer of goods between organizations of returned goods are correctly specified
// in the documents for the return of goods between organizations.
//
// Parameters:
//	CheckParameters - Structure - verification parameters, See AuditOfSystemState.InitializeVerificationParameters.
//
Procedure CheckingCorrectnessOfTransferSpecifiedInReturn(CheckParameters) Export
	
	QueryText =
	"SELECT DISTINCT
	|	Returns.Organization AS Organization,
	|	T.Recorder AS Return,
	|	T.DocumentSource AS Transfer_,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributesShipment,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttributeShipment,
	|	T.CorItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTAllMotionReturns
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|		INNER JOIN Document.IntercompanyGoodsReturn AS Returns
	|		ON T.Recorder = Returns.Ref
	|WHERE
	|	&BatchAccountingVersion22
	|	AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Returns.Organization IN(&CompanyArray)
	|	AND T.Organization = Returns.CompanyRecipient
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.Return AS Return,
	|	T.Transfer_ AS Transfer_,
	|	T.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	T.InventoryOwnerAttributeShipment AS InventoryOwnerAttributeShipment,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTMovementOfRefunds
	|FROM
	|	TTAllMotionReturns AS T
	|		INNER JOIN Document.CustomerInvoiceIntercompany AS Transfers_
	|		ON T.Transfer_ = Transfers_.Ref
	|		INNER JOIN Document.IntercompanyGoodsReturn.InventoryKinds AS Returns
	|		ON T.Return = Returns.Ref
	|			AND T.ItemsLocationAttributes = Returns.ItemsLocationAttributes
	|			AND T.InventoryOwnerAttribute = Returns.InventoryOwnerAttribute
	|WHERE
	|	Returns.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument)
	|
	|INDEX BY
	|	Organization,
	|	Transfer_,
	|	ItemsLocationAttributesShipment,
	|	InventoryOwnerAttributeShipment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Transfer_ AS Transfer_,
	|	T.Organization AS Organization
	|INTO TTTransfers
	|FROM
	|	TTMovementOfRefunds AS T
	|
	|INDEX BY
	|	T.Transfer_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Transfers_.Organization AS Organization,
	|	T.Recorder AS Transfer_,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTTransferRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|		INNER JOIN TTTransfers AS Transfers_
	|		ON T.Recorder = Transfers_.Transfer_
	|			AND T.Organization <> Transfers_.Organization
	|WHERE
	|	&BatchAccountingVersion22
	|	AND T.Period <= &EndOfPeriod
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|
	|INDEX BY
	|	Organization,
	|	Transfer_,
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Returns.Organization AS Organization,
	|	Returns.Return AS Return,
	|	Returns.Transfer_ AS Transfer_,
	|	Returns.ItemsLocationAttributesShipment AS ItemsLocationAttributes,
	|	Returns.InventoryOwnerAttributeShipment AS InventoryOwnerAttribute,
	|	Transfers_.ItemsLocationAttributes AS A1,
	|	Transfers_.InventoryOwnerAttribute AS In1
	|INTO TTRefundDiscrepancies
	|FROM
	|	TTMovementOfRefunds AS Returns
	|		LEFT JOIN TTTransferRegisteredRecords AS Transfers_
	|		ON Returns.Organization = Transfers_.Organization
	|			AND Returns.Transfer_ = Transfers_.Transfer_
	|			AND Returns.ItemsLocationAttributesShipment = Transfers_.ItemsLocationAttributes
	|			AND Returns.InventoryOwnerAttributeShipment = Transfers_.InventoryOwnerAttribute
	|WHERE
	|	Transfers_.Transfer_ IS NULL";
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 				NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Return",						NStr("vi = 'Chứng từ trả lại';
														|ru = 'Документ возврата';
														|en = 'Returns document'; fa = 'سند برگشت‌ها';
														|it = 'Documento di reso';
														|pl = 'Dokument zwrotu';
														|tr = 'İade belgesi'", Common.DefaultLanguageCode()));
	FieldList.Add("Transfer_",					NStr("vi = 'Chứng từ chuyển nhượng sản phẩm';
														|ru = 'Документ передачи продукции';
														|en = 'Product transfer document'; fa = 'Product transfer document';
														|it = 'Documento di trasferimento dei prodotti';
														|pl = 'Dokument przekazania produkcji';
														|tr = 'İmal edilen ürün transfer belgesi'", Common.DefaultLanguageCode()));
	FieldList.Add("ItemsLocationAttributes",	NStr("vi = 'Chỉ số mặt hàng';
													|ru = 'Аналитика номенклатуры';
													|en = 'Item dimension'; fa = 'Item dimension';
													|it = 'Analitica degli articoli';
													|pl = 'Analityka wykazu towarów';
													|tr = 'Öğe boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("InventoryOwnerAttribute",					NStr("vi = 'Dạng hàng tồn kho';
																	|ru = 'Вид запасов';
																	|en = 'Inventory owner attributes'; fa = 'ویژگی‌های مالک موجودی';
																	|it = 'Tipologia di scorte';
																	|pl = 'Rodzaj pozycji';
																	|tr = 'Stok sahibinin öznitelikleri'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = InitializeRegistrationAndVerificationParameters(
		"TTRefundDiscrepancies",
		NStr("vi = 'Các mặt hàng được trả lại từ doanh nghiệp ""%1""được tìm thấy không có trong chứng từ chuyển hàng';
			|ru = 'Обнаружены возвращенные от организации ""%1"" товары, отсутствующие в документе передачи товаров';
			|en = 'The products returned from the company ""%1"" were found that were absent in the product transfer document'; fa = 'The products returned from the company ""%1"" were found that were absent in the product transfer document';
			|it = 'Sono stati rilevati prodotti restituiti dall''azienda ""%1"", i quali sono mancanti nel documento di trasferimento dei prodotti';
			|pl = 'Wykryto zwrócone od firmy ""%1"" wiersze pozycji, których brakuje w dokumencie przekazania towarów';
			|tr = 'Ürün transfer belgesinde olmayan ""%1"" iş yerinden iade edilen öğeler bulundu'", Common.DefaultLanguageCode()),
		FieldList,
		"Return");
	
	RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters,
		QueryText);
	
EndProcedure

// Checks whether the GTD numbers of returned goods are correctly specified in the documents for returning goods
// between organizations.
//
// Parameters:
//	CheckParameters - Structure - verification parameters, See AuditOfSystemState.InitializeVerificationParameters.
//
Procedure CheckingCorrectnessOfFillingInGTDNumbersInRefunds(CheckParameters) Export
	
	QueryText = 
	"SELECT DISTINCT
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Ref AS Return
	|INTO BlankGTDNumbersInReturnDocuments
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS DocumentGoods
	|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN Catalog.Products CatalogProducts
	|		ON DocumentGoods.Products = CatalogProducts.Ref
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND HeaderData_.Organization IN(&CompanyArray)
	|	AND HeaderData_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND HeaderData_.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND DocumentGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND ((CatalogProducts.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting
	|			AND BEGINOFPERIOD(HeaderData_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart)
	|		OR (CatalogProducts.KeepRecordsByCCD
	|			AND &RestrictGoodsReceiptWithoutCCDNumbers)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Ref AS Return
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS DocumentGoods
	|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.TermsOfSale AS CatalogTerms1
	|		ON HeaderData_.Terms = CatalogTerms1.Ref
	|		
	|		INNER JOIN Catalog.Products CatalogProducts
	|		ON DocumentGoods.Products = CatalogProducts.Ref
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND HeaderData_.Organization IN(&CompanyArray)
	|	AND HeaderData_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND DocumentGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND CatalogProducts.TracedGoods
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND BEGINOFPERIOD(HeaderData_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|	AND ISNULL(CatalogTerms1.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Ref AS Return
	|FROM
	|	Document.IntercompanyGoodsReturn.Goods AS DocumentGoods
	|		INNER JOIN Document.IntercompanyGoodsReturn AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN Catalog.Products CatalogProducts
	|		ON DocumentGoods.Products = CatalogProducts.Ref
	|WHERE
	|	HeaderData_.Posted
	|	AND HeaderData_.Organization IN(&CompanyArray)
	|	AND HeaderData_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DocumentGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND ((CatalogProducts.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting
	|			AND BEGINOFPERIOD(HeaderData_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart)
	|		OR (CatalogProducts.KeepRecordsByCCD
	|			AND &RestrictGoodsReceiptWithoutCCDNumbers)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Ref AS Return
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS DocumentGoods
	|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN Catalog.Products CatalogProducts
	|		ON DocumentGoods.Products = CatalogProducts.Ref
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND HeaderData_.Organization IN(&CompanyArray)
	|	AND HeaderData_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND NOT HeaderData_.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|			VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5),
	|			VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			)
	|	AND DocumentGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND ((CatalogProducts.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting
	|			AND BEGINOFPERIOD(HeaderData_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart)
	|		OR (CatalogProducts.KeepRecordsByCCD
	|			AND &RestrictGoodsReceiptWithoutCCDNumbers)
	|		)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Ref AS Return
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS DocumentGoods
	|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.TermsOfSale AS CatalogTerms1
	|		ON HeaderData_.Terms = CatalogTerms1.Ref
	|		
	|		INNER JOIN Catalog.Products CatalogProducts
	|		ON DocumentGoods.Products = CatalogProducts.Ref
	|
	|WHERE
	|	HeaderData_.Posted
	|	AND HeaderData_.Organization IN(&CompanyArray)
	|	AND HeaderData_.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND DocumentGoods.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND CatalogProducts.TracedGoods
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND BEGINOFPERIOD(HeaderData_.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|	AND ISNULL(CatalogTerms1.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|";
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Return", 	NStr("vi = 'Chứng từ trả lại';
									|ru = 'Документ возврата';
									|en = 'Returns document'; fa = 'سند برگشت‌ها';
									|it = 'Documento di reso';
									|pl = 'Dokument zwrotu';
									|tr = 'İade belgesi'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = InitializeRegistrationAndVerificationParameters(
		"BlankGTDNumbersInReturnDocuments",
		NStr("vi = 'Đã tìm thấy các mặt hàng trả lại mà không có số tờ khai hải quan trong doanh nghiệp 
			|""%1""';
			|ru = 'Обнаружены возвращенные товары без номеров ГТД в организацию 
			|""%1""';
			|en = 'The products returned in the company 
			|""%1"" were found without CFD numbers'; fa = 'The products returned in the company 
			|""%1"" were found without CFD numbers';
			|it = 'Sono stati rilevati prodotti restituiti senza numero di dichiarazione doganale nell''azienda 
			|""%1""';
			|pl = 'Wykryto zwrócone wiersze pozycji bez numerów ŁDC do firmy 
			|""%1""';
			|tr = '
			|""%1"" iş yerine gümrük kergo beyannamesi numarası olmadan iade edilen ürünler bulundu'", Common.DefaultLanguageCode()),
		FieldList,
		"Return");
		
	AdditionalRequestParameters_ = New Structure;
	AdditionalRequestParameters_.Insert(
		"RestrictGoodsReceiptWithoutCCDNumbers",
		Constants.RestrictGoodsReceiptWithoutCCDNumbers.Get());
	AdditionalRequestParameters_.Insert(
		"DateOfTraceableImportedGoodsAccountingStart",
		AccountingForTraceableGoodsLocalization.DateOfTraceableImportedGoodsAccountingStart());
	AdditionalRequestParameters_.Insert(
		"UseTraceableImportedGoodsAccounting",
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1, 1, 1)));
	
	RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters,
		QueryText,
		AdditionalRequestParameters_);
	
EndProcedure

#EndRegion

#EndRegion

#Region Group_BlockingFromChanges

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
//	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group ID.
//
Procedure AddStage_LockFromChanges(StepsTable, CurrentParent) Export
	
	NewRow = AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.LockFromChanges);
		
	NewRow.MultilingualName = "vi = 'Phong tỏa tránh các thay đổi';
								|ru = 'Заблокировать от изменений';
								|en = 'Lock from changes';
								|it = 'Lock from changes';
								|pl = 'Lock from changes';
								|tr = 'Değişikliklere karşı kilitle'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.informational = True;
	NewRow.PerformedAtPreliminaryClosingOfMonth = False;
	NewRow.ReadMoreText = NStr("vi = 'Phong tỏa';
								|ru = 'Заблокировать';
								|en = 'Lock'; fa = 'قفل';
								|it = 'Заблокировать';
								|pl = 'Lock';
								|tr = 'Kilitle'");

	NewRow.ActionUse = ActionDescription_ServerProcedure(
		"MonthEndTransactionsServer.Using_BlockFromChanges");
	NewRow.ActionMoreDetails  = ActionDescription_OpenForm(
		Metadata.InformationRegisters.SetUpLockFromChanges.Forms.FormSettings.FullName(),, True);
	
EndProcedure

// Usage is blocked from changes.
// 
// Parameters:
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure Using_BlockFromChanges(HandlerParameters) Export
	
	Lock_Settings = InformationRegisters.SetUpLockFromChanges.InformationAboutBlockingChanges(
		HandlerParameters.CalculationParameters.CompanyArray,
		HandlerParameters.CalculationParameters.RegistrationPeriod);
	
	If Not Lock_Settings.UseMechanismToBlockChanges Then
		
		NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không sử dụng phong tỏa thay đổi.';
				|ru = 'Механизм блокировки изменений не используется.';
				|en = 'Lock from changes is not used.'; fa = 'Lock from changes is not used.';
				|it = 'Механизм блокировки изменений не используется.';
				|pl = 'Lock from changes is not used.';
				|tr = 'Değişiklik kilit mekanizması kullanılmıyor.'"));
			
	ElsIf Lock_Settings.PeriodCanBeBlocked Then
		
		If YouHaveRightToManageBlockingOfPeriod() Then
			SetStateExecutedWithErrors(
				HandlerParameters,
				NStr("vi = 'Đã thực hiện các giao dịch chính đóng tháng, có thể phong tỏa kỳ khỏi các thay đổi.';
					|ru = 'Основные операции закрытия месяца выполнены, период можно заблокировать от изменений.';
					|en = 'Main month-end closing operations are completed. You can lock the period from changes.'; fa = 'Main month-end closing operations are completed. You can lock the period from changes.';
					|it = 'Основные операции закрытия месяца выполнены, период можно заблокировать от изменений.';
					|pl = 'Main month-end closing operations are completed. You can lock the period from changes.';
					|tr = 'Ay sonu kapanışının ana işlemleri tamamlandı, dönem değişikliklerinden kilitlenebilir.'", Common.DefaultLanguageCode()),
				,
				,
				Enums.AccountingIssueSeverity.Information);
		Else
			NoNeedToSetState(
				HandlerParameters,
				NStr("vi = 'Không đủ quyền để quản lý phong tỏa kỳ.';
					|ru = 'Нет прав на управление блокировкой периодов.';
					|en = 'No rights to manage the period lock.'; fa = 'No rights to manage the period lock.';
					|it = 'Нет прав на управление блокировкой периодов.';
					|pl = 'No rights to manage the period lock.';
					|tr = 'Dönem kilit yönetimi yetkisi yoktur.'"));
		EndIf;
		
	Else
		
		NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Có các giao dịch chưa thực hiện, không thể phong tỏa.';
				|ru = 'Есть невыполненные операции, блокировка невозможна.';
				|en = 'There are uncompleted operations. The lock is unavailable.'; fa = 'There are uncompleted operations. The lock is unavailable.';
				|it = 'Есть невыполненные операции, блокировка невозможна.';
				|pl = 'There are uncompleted operations. The lock is unavailable.';
				|tr = 'Gerçekleştirilmeyen işlemler mevcut, kilit mümkün değil.'"));
			
	EndIf;
		
EndProcedure

#EndRegion

#EndRegion

#Region MethodsForDescribingSystemStateChecks

// Adds a new system health check to the check table and fills in its key fields.
//
// Parameters:
//	TableOfChecks              - See AuditOfSystemState.SystemStateCheckTable
//	Id 				 - String - unique string ID (code) of the check
//	AccountingChecksContext 			 - CatalogRef.MonthEndClosingOperations - the month closing stage (owner) that the check belongs to
//	AccountingCheckContextClarification - EnumRef.TimeOfStartingMonthEndClosingOperationCheck - when to perform a check
//	Handler 					 - String - full name of the export handler procedure that is called to perform the check
//	IssueSeverity 					 - EnumRef.AccountingIssueSeverity - default status for verification results.
// 
// Returns:
//	ValueTableRow - added row of the verification table.
//
Function AddDescriptionOfNewCheck(TableOfChecks, Id, AccountingChecksContext,
			AccountingCheckContextClarification, Handler, IssueSeverity = Undefined) Export
	
	VerificationDescription = TableOfChecks.Add();
	
	VerificationDescription.Id 				  = Id;
	VerificationDescription.ParentID 		 = "Group" + "_" + Catalogs.MonthEndClosingOperations.GetPredefinedItemName(AccountingChecksContext);
	VerificationDescription.AccountingChecksContext 		  = AccountingChecksContext;
	VerificationDescription.AccountingCheckContextClarification = AccountingCheckContextClarification;
	VerificationDescription.Handler 				  = Handler;
	VerificationDescription.IssueSeverity 					  =
		?(ValueIsFilled(IssueSeverity), IssueSeverity, Enums.AccountingIssueSeverity.Error);
		
	VerificationDescription.ExecutedOnlyInContext = False;
	VerificationDescription.CanEditImportance   = True;
	
	VerificationDescription.DetailsByCompany    = True;
	VerificationDescription.DetailsByPeriod        = True;
	VerificationDescription.Use			     = False;
	
	Return VerificationDescription;
	
EndFunction

// Fills in the text fields describing the system health check.
//
// Parameters:
//	VerificationDescription - ValueTableRow - a row in the verification table that was added to adddescription of a new Check()
//	Description 	 - String - custom validation view
//	Comment 	 - String - detailed description of the check.
//
Procedure FillInPresentationOfNewCheck(VerificationDescription, Description, Comment = "") Export
	
	VerificationDescription.Description = Description;
	VerificationDescription.Reasons = Comment;
	
EndProcedure

// Returns the name of the form to display the results of the specified check.
// By default, the results of all checks are displayed using the Processing form.Operations for closing the month.Shapes.Resultativity
// If you need to provide non-standard behavior when displaying results, then you need to specify the name of your
// special form in this function.
//
// Parameters:
//	Validation - CatalogRef.AccountingCheckRules - check the status of the system.
//
// Returns:
//	String, Undefined - the redefined name of the form to check; if the form is not redefined, it is returned Undefined.
//
Function NameOfVerificationResultsDecryptionForm(Validation) Export
	
	FormName = Undefined;
	
	// For verification, you can override the form that opens by default.
	
	Return FormName;
	
EndFunction

#EndRegion

#Region MethodsForDescribingStages

// Adds a row to the stage table.
//
// Parameters:
//	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
//	Parent - String - ID of the group this stage belongs to, see the functions of the Group ID view...
//	Stage - CatalogRef.MonthEndClosingOperations - the added step of closing the month
//	OperationalAccounting - Boolean - indicates whether the stage belongs to operational accounting
//	LocalAccounting - Boolean - indicates whether the stage belongs to regulated accounting
//	FinancialAccounting - Boolean - indicates whether the stage belongs to international accounting.
//	PreviousStage_ - CatalogRef.MonthEndClosingOperations - the previous stage of closing the month for ordering purposes.
//
// Returns:
//	ValueTableRow - added a row of the stage table with columns:
//	* PreviousStages_ - ValueTable
//
Function AddStageToTable(StepsTable, Parent, Stage, OperationalAccounting = True,
			LocalAccounting = False, FinancialAccounting = False, PreviousStage_ = Undefined) Export
	
	NewRow = StepsTable.Add();
	
	NewRow.Parent 		  		= Parent;
	NewRow.Code 			  		= Stage;
	NewRow.FollowsStage			= PreviousStage_;
	NewRow.OperationalAccounting 		= OperationalAccounting;
	NewRow.LocalAccounting  = LocalAccounting;
	NewRow.FinancialAccounting 		= FinancialAccounting;
	
	Return NewRow;
	
EndFunction

#Region DescriptionsOfPossibleActions

// Description of templates for event handlers of the month closing stage.
// Used for the "Action..." properties of the month closing stage.

// Description of the "Execute specified custom procedure" action.
//
// Parameters:
//	Handler - String - full path to the export procedure of the action handler.
//
// Returns:
// See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_ServerProcedure(Handler) Export
	
	LongDesc = StructureOfActionDescription();
	
	LongDesc.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.ExecuteProcedureOnServer;
	LongDesc.Handler  = Handler;
	LongDesc.AtServer   = True;
	
	Return LongDesc;
	
EndFunction

// Description of the "Execute specified custom procedure" action.
//
// Parameters:
//	Handler - String - the full path to the action handler export function.
//
// Returns:
// See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_ClientProcedure(Handler) Export
	
	LongDesc = StructureOfActionDescription();
	
	LongDesc.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.ExecuteProcedureOnClient;
	LongDesc.Handler  = Handler;
	LongDesc.AtClient   = True;
	
	Return LongDesc;
	
EndFunction

// Description of the "perform stage calculation" action.
//
// Parameters:
//	Handler - String - full path to the export procedure of the action handler.
//
// Returns:
// See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_PerformCalculation(Handler) Export
	
	LongDesc = StructureOfActionDescription();
	
	LongDesc.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.PerformTheCalculation;
	LongDesc.Handler  = Handler;
	LongDesc.AtServer   = True;
	
	Return LongDesc;
	
EndFunction

// Description of the "Open object help" action.
//
// Parameters:
//	MetadataObject - String - full name of the metadata object to open the help for
//
// Returns:
// See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_OpenObjectHelp(MetadataObject) Export
	
	LongDesc = StructureOfActionDescription();
	
	LongDesc.ActionKind 		  = Enums.DrillDownActionKindsForMonthEndOperations.OpenObjectHelp;
	LongDesc.MetadataObjectName = MetadataObject.FullName();
	LongDesc.AtClient   		  = True;
	
	Return LongDesc;
	
EndFunction

// Description of the "Open verification results for the specified stage" action.
//
// Parameters:
//	Validation 		   - CatalogRef.AccountingCheckRules - system status check; if omitted, the results of all checks are displayed
//	Issue1 		   - UUID - the problem found by the check; if not specified, all problems are displayed
//	AccountingChecksContext - CatalogRef.MonthEndClosingOperations - the closing stage of the month (owner) that the check belongs to.
//
// Returns:
// See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_OpenVerificationResults(Validation = Undefined, Issue1 = Undefined, AccountingChecksContext = Undefined) Export
	Var FormName;
	
	LongDesc = StructureOfActionDescription();
	
	If ValueIsFilled(Validation) Then
		FormName = NameOfVerificationResultsDecryptionForm(Validation);
	EndIf;
	
	If Not ValueIsFilled(FormName) Then
		FormName = Metadata.DataProcessors.MonthEndClosingOperations.Forms.CheckResults.FullName();
	EndIf;
	
	LongDesc.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.OpenCheckResults;
	LongDesc.FormName    = FormName;
	LongDesc.AtClient   = True;
	
	LongDesc.FormParameters.Insert("Validation", 		   Validation);
	LongDesc.FormParameters.Insert("Issue1", 		   TMCommonUseClientServer.Array(Issue1));
	LongDesc.FormParameters.Insert("AccountingChecksContext", AccountingChecksContext);
	
	Return LongDesc;
	
EndFunction

// Description of the "Open custom form" action.
//
// Parameters:
//	FormName 				 - String - name of the form to open 
//	ParametersInSelectionStructure - Boolean - indicates that the parameters of the form to open should be passed inside the Selection parameter with the Structure type.
//	OpenFormWithBlocking - Boolean - open a Form with the owner blocked
//
// Returns:
// See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_OpenForm(FormName, ParametersInSelectionStructure = False, OpenFormWithBlocking = False) Export
	
	LongDesc = StructureOfActionDescription();
	
	LongDesc.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.OpenForm;
	LongDesc.FormName    = FormName;
	LongDesc.AtClient   = True;
	
	LongDesc.OpenFormWithBlocking = OpenFormWithBlocking;
	
	FormParameterFields = "Organization, CompanyArray, RegistrationPeriod, Period, BeginOfPeriod, EndOfPeriod, EndingDateOfPeriod";
	If ParametersInSelectionStructure Then
		LongDesc.FormParameters.Insert("Filter", New Structure(FormParameterFields));
	Else
		LongDesc.Insert("FormParameters", New Structure(FormParameterFields));
	EndIf;
	
	LongDesc.FormParameters.Insert(MonthEndTransactionsClientServer.NameOfServicePropertyOfFormsToOpen(), True);
	
	Return LongDesc;
	
EndFunction

// Description of the "Show errors of the specified stage in the log" action.
//
// Parameters:
//	CalculatedStage - CatalogRef.MonthEndClosingOperations - the closing stage of the month.
//
// Returns:
// See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_OpenLog(CalculatedStage) Export
	
	LongDesc = StructureOfActionDescription();
	
	LongDesc.ActionKind = Enums.DrillDownActionKindsForMonthEndOperations.OpenEventLog;
	LongDesc.FormName    = Metadata.DataProcessors.EventLog.Forms.EventLog.FullName();
	LongDesc.AtClient   = True;
	
	FilterByLevel = New ValueList;
	FilterByLevel.Add("Error", "Error");
	
	LogEvents = New Array;
	LogEvents.Add(EventLogEventName(Catalogs.MonthEndClosingOperations.GetPredefinedItemName(CalculatedStage)));
	
	LongDesc.FormParameters.Insert("StartDate");
	LongDesc.FormParameters.Insert("EndDate");
	LongDesc.FormParameters.Insert("Level", FilterByLevel);
	LongDesc.FormParameters.Insert("EventLogEvent", LogEvents);
	
	Return LongDesc;
	
EndFunction

#EndRegion

#EndRegion


#Region MethodsForCheckingStateOfStagesAndExecutingStages

#Region HandlingRequests

// Sets General parameters and a temporary table Manager for queries used in the month closing mechanism.
//
// Parameters:
//	Query 									- Query - request used
//	HandlerParametersOrCalculationParameters - Structure - the parameters of the event handler stage, or a parameter calculation stage.
//
// Returns:
//	Boolean - indicates that a temporary table manager has been passed in the handler parameter;
//		if the manager was not passed, it will be added to the handler parameters for use in the following handlers.
//
Function InitializeRequest(Query, HandlerParametersOrCalculationParameters) Export
	
	TheseAreHandlerParameters = HandlerParametersOrCalculationParameters.Property("CalculationParameters");
	
	If TheseAreHandlerParameters Then
		CalculationParameters = HandlerParametersOrCalculationParameters.CalculationParameters;
	Else
		CalculationParameters = HandlerParametersOrCalculationParameters;
	EndIf;
	
	If CalculationParameters.Property("BeginOfPeriod") Then
		BeginOfPeriod = CalculationParameters.BeginOfPeriod;
		EndOfPeriod  = CalculationParameters.EndOfPeriod;
	Else
		BeginOfPeriod = BegOfMonth(CalculationParameters.RegistrationPeriod);
		EndOfPeriod  = EndOfMonth(CalculationParameters.RegistrationPeriod);
	EndIf;
	
	// General request parameters.
	Query.SetParameter("BeginOfPeriod",				  	BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",				  	EndOfPeriod);
	Query.SetParameter("BeginningOfPreviousPeriod",	  	BegOfMonth(BeginOfPeriod - 1));
	Query.SetParameter("EndOfPreviousPeriod",	  	BeginOfPeriod - 1);
	Query.SetParameter("BeginningOfNextPeriod",	  	EndOfPeriod + 1);
	
	Query.SetParameter("BorderStartOfPeriod",		  	New Boundary(BeginOfPeriod, BoundaryType.Excluding));
	Query.SetParameter("BorderEndOfPeriod",		  	New Boundary(EndOfPeriod, BoundaryType.Including));
	Query.SetParameter("BorderEndOfPreviousPeriod",	New Boundary(BeginOfPeriod - 1, BoundaryType.Including));
	
	Query.SetParameter("CompanyArray",			  	CalculationParameters.CompanyArray);
	Query.SetParameter("SFIFOOrganizationsSliding",		CalculationOfCostCached.OrganizationsWithFIFOAssessmentMethod(BeginOfPeriod));
	Query.SetParameter("OrganizationsBySecondarySchool",			CalculationOfCostCached.OrganizationsWithAverageValuationMethod(BeginOfPeriod));
	Query.SetParameter("CompaniesWithDetailedCosts",	CalculationOfCostCached.CompaniesWithCostDetailsInCostPrice(BeginOfPeriod));
	
	// Parameters are the values of functional options.
	Query.SetParameter("BatchAccountingNotUsed",
		CalculationOfCostCached.BatchAccountingNotUsed(BeginOfPeriod));
	Query.SetParameter("BatchAccountingVersion21",
		CalculationOfCostCached.BatchAccountingVersion21(BeginOfPeriod));
	Query.SetParameter("BatchAccountingVersion22",
		CalculationOfCostCached.BatchAccountingVersion22(BeginOfPeriod));
	Query.SetParameter("DateOfMigrationToBatchAccounting22",
		CalculationOfCostCached.DateOfMigrationToBatchAccounting22());
	Query.SetParameter("UseLocal", 
		GetFunctionalOption("UseLocal"));
	Query.SetParameter("UseProductionManagement2_2", GetFunctionalOption("UseProductionManagement2_2"));
	// temporary table manager.
	DataInitialized = TheseAreHandlerParameters And HandlerParametersOrCalculationParameters.Property("TempTablesManager");
	
	If DataInitialized Then
		
		Query.TempTablesManager = HandlerParametersOrCalculationParameters.TempTablesManager;
		
	ElsIf TheseAreHandlerParameters Then
		
		HandlerParametersOrCalculationParameters.Insert("TempTablesManager", New TempTablesManager);
		
		Query.TempTablesManager = HandlerParametersOrCalculationParameters.TempTablesManager;
		
	Else
		
		Query.TempTablesManager = New TempTablesManager;
		
	EndIf;
	
	Return DataInitialized;
	
EndFunction

#EndRegion

#Region UniversalChecks

// Checks whether there are tasks in the data register of the "task ..." type.
//
// Parameters:
//	HandlerParameters 		- Structure - parameters of the stage event handler
//	PerformFromEarliest 	- Boolean - indicates that the recalculation should be performed from the very first task to the calculated period
//									if False, only the presence of tasks in the calculated period is analyzed
//	NameOfOrganizationSelectionTable - String - name of the temporary table for selecting the task register for organizations
//									organizations in the specified table must be in the field named "Link"
//									if the table is not specified, then all organizations are selected from the array of Organizations property
//	TaskRegisterName 			- String - name of the data register with tasks to be recalculated
//									if no register is specified, the data of the task register is selected for the month's Closure.
//	ActionMoreDetails 	 		- String - see functions of the form "Action description_..."
//	
// Returns:
//	Boolean - indicates whether there are register entries.
//
Function CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, PerformFromEarliest,
			NameOfOrganizationSelectionTable = "", TaskRegisterName = "", ActionMoreDetails = Undefined) Export
	
	Query = New Query;
	InitializeRequest(Query, HandlerParameters);
	
	If Not ValueIsFilled(NameOfOrganizationSelectionTable) Then
		
		// Verification for all calculated organizations.
		Query.Text =
		"SELECT
		|	Companies.Ref
		|INTO TTOrganizations
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref IN(&CompanyArray)";
		
		Query.Execute();
		
	EndIf;
	
	Query.Text =
	"SELECT
	|	Jobs.Organization,
	|	BEGINOFPERIOD(MIN(Jobs.Month), Month) AS Month
	|INTO TTOrganizationsWithTasksForEndOfMonth
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|	INNER JOIN TTOrganizations AS Companies
	|		ON Jobs.Organization = Companies.Ref
	|WHERE
	|	&TextConditionPeriod
	|	AND (Jobs.Organization IN (&CompanyArray)
	|	  OR NOT Jobs.Organization.DeletionMark)
	|	AND &TextSelectionCondition
	|
	|GROUP BY
	|	Jobs.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MIN(Jobs.Month), UNDEFINED) AS Month
	|FROM
	|	TTOrganizationsWithTasksForEndOfMonth AS Jobs";
	
	If Not ValueIsFilled(TaskRegisterName) Then
		
		// We check the register of the task for the closing of the month 
		Query.Text = StrReplace(Query.Text, "&TextSelectionCondition", "Jobs.Operation = &CalculatedStage");
		Query.Text = StrReplace(Query.Text, "TTOrganizations", ?(ValueIsFilled(NameOfOrganizationSelectionTable), NameOfOrganizationSelectionTable, "TTOrganizations"));
		
		Query.SetParameter("CalculatedStage", HandlerParameters.Data_Stage.Code);
		
	Else
		
		// Check the specified register
		Query.Text = StrReplace(Query.Text, "JobsForMonthEndClosing", TaskRegisterName);
		Query.Text = StrReplace(Query.Text, "&TextSelectionCondition", "TRUE");
		Query.Text = StrReplace(Query.Text, "TTOrganizations", ?(ValueIsFilled(NameOfOrganizationSelectionTable), NameOfOrganizationSelectionTable, "TTOrganizations"));
		
	EndIf;
	
	If Not PerformFromEarliest Then
		Query.Text = StrReplace(Query.Text, "&TextConditionPeriod", "Jobs.Month BETWEEN &BeginOfPeriod AND &EndOfPeriod")
	Else
		Query.Text = StrReplace(Query.Text, "&TextConditionPeriod", "Jobs.Month <= &EndOfPeriod")
	EndIf;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query,
		"TTOrganizationsWithTasksForEndOfMonth"
			+ ?(Not ValueIsFilled(NameOfOrganizationSelectionTable), ", TTOrganizations", ""));
	
	If ValueIsFilled(Selection.Month) Then
		
		HandlerParameters.Data_Stage.SettlementStartDate = Selection.Month;
		
		SetStateFailed(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tính toán lại giao dịch %1 %2 yêu cầu';
					|ru = 'Требуется пересчет операции %1 %2';
					|en = 'Recalculation of the %1 %2 operation is required'; fa = 'Recalculation of the %1 %2 operation is required';
					|it = 'È necessario un ricalcolo dell''operazione %1 %2';
					|pl = 'Potrzebne jest przeliczenie operacji %1 %2';
					|tr = '%1 %2 işleminin yeniden hesaplanması gerekli'", Common.DefaultLanguageCode()),
				?(PerformFromEarliest, NStr("vi = 'bắt đầu từ kỳ';
											|ru = 'начиная с периода';
											|en = 'starting from the period'; fa = 'starting from the period';
											|it = 'iniziando dal periodo';
											|pl = 'zaczynając od okresu';
											|tr = 'döneminden başlayarak'", Common.DefaultLanguageCode()), NStr("vi = 'trong kỳ';
																													|ru = 'за период';
																													|en = 'over period'; fa = 'over period';
																													|it = 'per periodo';
																													|pl = 'za okres';
																													|tr = 'dönem içerisinde'", Common.DefaultLanguageCode())),
				CostCalculationProtocol.PresentationOfCalculationPeriod(Selection.Month)),
				?(ValueIsFilled(ActionMoreDetails),DefaultDetailsText(),""),
				ActionMoreDetails);
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

// Checks whether there is a regulatory document of the specified type.
//
// Parameters:
//	HandlerParameters 		- Structure - parameters of the stage event handler
//	DocumentName 				- String - name of the regulatory document as specified in the metadata
//	NameOfOrganizationSelectionTable - String - the name of the temporary table for selecting documents for organizations
//									organizations in the specified table must be in the field named "Link"
//									if the table is not specified, then all organizations are selected from the array of Organizations property.
//	
// Returns:
//	Boolean - a sign of the availability of documents.
//
Function CheckAvailabilityOfRegulatoryDocumentOfClosingStageOfMonth(HandlerParameters, DocumentName, NameOfOrganizationSelectionTable = "") Export
	
	DocumentsCount = NumberOfRegulatoryDocumentsOfClosingStageOfMonth(
		HandlerParameters, DocumentName, NameOfOrganizationSelectionTable);
	
	IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, DocumentsCount);
	
	If DocumentsCount = 0 Then
		
		NoNeedToSetState(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với kỳ %1, không có nhiệm vụ tính toán thao tác này và không có chứng từ ""%2"".';
					|ru = 'За период %1 нет заданий для расчета данной операции и отсутствуют документы ""%2"".';
					|en = 'No jobs for calculating this operation and no ""%2"" documents for period %1.'; fa = 'No jobs for calculating this operation and no ""%2"" documents for period %1.';
					|it = 'Per il periodo %1 non ci sono task per la contabilizzazione dell''operazione corrente e mancano i documenti ""%2"".';
					|pl = 'Za okres %1 brak zadań do obliczania danej operacji i brakują dokumenty ""%2"".';
					|tr = '%1 dönemi için bu işlemin kapatılması için görev yok ve ""%2"" belgeleri eksik.'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod),
				Metadata.Documents[DocumentName].Synonym));
		
	EndIf;
	
	Return DocumentsCount <> 0;
	
EndFunction

// Determines the number of regulatory documents of the specified type.
//
// Parameters:
//	HandlerParameters 		- Structure - parameters of the stage event handler
//	DocumentName 				- String - name of the regulatory document as specified in the metadata
//	NameOfOrganizationSelectionTable - String - the name of the temporary table for selecting documents for organizations
//									organizations in the specified table must be in the field named "Link"
//									if the table is not specified, then all organizations are selected from the array of Organizations property.
//	
// Returns:
//	Number - number of documents.
//
Function NumberOfRegulatoryDocumentsOfClosingStageOfMonth(HandlerParameters, DocumentName, NameOfOrganizationSelectionTable = "") Export
	
	Query = New Query;
	InitializeRequest(Query, HandlerParameters);
	
	If Not ValueIsFilled(NameOfOrganizationSelectionTable) Then
		
		// Verification for all calculated organizations.
		Query.Text =
		"SELECT
		|	Companies.Ref
		|INTO TTOrganizations
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref IN(&CompanyArray)";
		
		Query.Execute();
		
	EndIf;
	
	Query.Text =
	"SELECT DISTINCT
	|	Companies.Ref AS Organization
	|FROM
	|	TTOrganizations AS Companies
	|	INNER JOIN DocumentTable AS T
	|		ON Companies.Ref = T.Organization
	|			AND (T.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|			AND (T.Posted)
	|			AND &AddlCondition";
	
	If ValueIsFilled(NameOfOrganizationSelectionTable) Then
		Query.Text = StrReplace(Query.Text, "TTOrganizations", NameOfOrganizationSelectionTable);
	EndIf;

	Query.Text = StrReplace(Query.Text, "DocumentTable", "Document." + DocumentName);
	
	If DocumentName = "VATAllocation" Then 
		Query.Text = StrReplace(Query.Text, "&AddlCondition", "NOT T.Patch");
	Else 
		Query.Text = StrReplace(Query.Text, "&AddlCondition", "TRUE");
	EndIf;
	
	QueryResult = Query.Execute();
	
	If Not ValueIsFilled(NameOfOrganizationSelectionTable) Then
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "TTOrganizations");
	EndIf;
	
	Return QueryResult.Unload().Count();
	
EndFunction

// Checks the use of regulated accounting in the calculated period.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler.
//	ChangeStageState - Boolean -
//	
// Returns:
//	Boolean - a sign of the use of regulated accounting.
//
Function CheckUseOfRegulatedAccounting(HandlerParameters, ChangeStageState = True) Export
	
	Result = MonthEndTransactionsLocalization.CheckUseOfRegulatedAccounting(HandlerParameters, ChangeStageState);
	
	Return Result;
	
EndFunction

// Checks the availability of "Routine operation" documents.
//
// Parameters:
//	HandlerParameters 			   - Structure - parameters of the stage event handler
//	OperationType - Undefined, EnumRef - The type of routine operation of the document (types of routine operations)
//											if not specified, then the types of operations from the Types of routine operations property of this stage are analyzed.
//	NameOfOrganizationSelectionTable 	   - String - the name of the temporary table for selecting documents for organizations
//											organizations in the specified table must be in the field named "Link"
//											if the table is not specified, then all organizations are selected from the array of Organizations property.
//	TaskRegisterIsUsedForStage - Boolean - indicates that one of the "task ..." registers is used for this stage.
//	
// Returns:
//	Boolean - a sign of the availability of documents.
//
Function CheckAvailabilityOfDocumentRoutineOperation(HandlerParameters, Val OperationType = Undefined,
			NameOfOrganizationSelectionTable = "", TaskRegisterIsUsedForStage = True) Export
	
	Result = MonthEndTransactionsLocalization.CheckAvailabilityOfDocumentRoutineOperation(HandlerParameters, 
		OperationType,
		NameOfOrganizationSelectionTable,
		TaskRegisterIsUsedForStage);
	
	Return Result
EndFunction
#EndRegion

#Region DefiningAndSettingStateOfStages

// Sets the state of the "not required" stage.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	Explanation 			 - String - explanation text for the set state
//	ReadMoreText 		 - String - Read more hyperlink text instead of the default text
//	ActionMoreDetails 	 - String - see functions of the form "Action description_..."
//	State 			 - EnumRef.AccountingIssueSeverity - status explanation the default is "Info".
//
Procedure NoNeedToSetState(HandlerParameters, Explanation = "", ReadMoreText = "", ActionMoreDetails = Undefined, State = Undefined) Export
	
	If HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted
	 Or HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.DoneWithErrors Then
		Return; // if problems have been diagnosed, then the stage requires recalculation
	EndIf;
	
	HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotRequired;
	
	If ValueIsFilled(Explanation) Then
		AddExplanatoryInformationToStep(HandlerParameters, Explanation, ReadMoreText, ActionMoreDetails, State);
	EndIf;
	
EndProcedure

// Sets the status of the "Disabled" stage.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	Explanation 			 - String - explanation text for the set state
//	ReadMoreText 		 - String - Read more hyperlink text instead of the default text
//	ActionMoreDetails 	 - String - see functions of the form "Action description_..."
//	State 			 - EnumRef.AccountingIssueSeverity - status explanation the default is "Info".
//
Procedure SetStateDisabled(HandlerParameters, Explanation = "", ReadMoreText = "", ActionMoreDetails = Undefined, State = Undefined) Export
	
	HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotRequired;
	HandlerParameters.Data_Stage.Disabled = True;
	
	If ValueIsFilled(Explanation) Then
		AddExplanatoryInformationToStep(HandlerParameters, Explanation, ReadMoreText, ActionMoreDetails, State);
	EndIf;
	
EndProcedure

// Sets the status of the "Failed" stage.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	Explanation 			 - String - explanation text for the set state
//	ReadMoreText 		 - String - Read more hyperlink text instead of the default text
//	ActionMoreDetails 	 - String - see functions of the form "Action description_..."
//	State 			 - EnumRef.AccountingIssueSeverity - status explanation the default is "Error".
//
Procedure SetStateFailed(HandlerParameters, Explanation = "", ReadMoreText = "", ActionMoreDetails = Undefined, State = Undefined) Export
	
	HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted;
	
	If ValueIsFilled(Explanation) Then
		
		If Not ValueIsFilled(State) Then
			State = Enums.AccountingIssueSeverity.Error;
		EndIf;
		
		AddExplanatoryInformationToStep(HandlerParameters, Explanation, ReadMoreText, ActionMoreDetails, State);
		
	EndIf;
	
EndProcedure

// Sets the status of the "Completed with errors" stage.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	Explanation 			 - String - explanation text for the set state
//	ReadMoreText 		 - String - Read more hyperlink text instead of the default text
//	ActionMoreDetails 	 - String - see functions of the form "Action description_..."
//	State 			 - EnumRef.AccountingIssueSeverity - explanation status, default "Warning".
//
Procedure SetStateExecutedWithErrors(HandlerParameters, Explanation = "", ReadMoreText = "", ActionMoreDetails = Undefined, State = Undefined) Export
	
	If HandlerParameters.Data_Stage.State <> Enums.StatesOfMonthEndClosingOperations.NotCompleted Then
		HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.DoneWithErrors;
	EndIf;
	
	If ValueIsFilled(Explanation) Then
		
		If Not ValueIsFilled(State) Then
			State = Enums.AccountingIssueSeverity.Warning;
		EndIf;
		
		AddExplanatoryInformationToStep(HandlerParameters, Explanation, ReadMoreText, ActionMoreDetails, State);
		
	EndIf;
	
EndProcedure


// Checks that the stage state is different from the default blank state.
//
// Parameters:
//	Data_Stage - ValueTableRow - a row in the stage table.
//
// Returns:
//	Boolean - indicates that the stage status is different from "Undefined".
//
Function StageStateDefined(Data_Stage) Export
	
	Return Data_Stage.State <> Enums.StatesOfMonthEndClosingOperations.Undefined;
	
EndFunction

// Checks that the stage status is different from " Completed successfully "and"not required".
//
// Parameters:
//	Data_Stage - ValueTableRow - a row in the stage table.
//
// Returns:
//	Boolean - indicates whether the stage needs to be recalculated.
//
Function StageRecalculationIsRequired(Data_Stage) Export
	
	Return Data_Stage.State <> Enums.StatesOfMonthEndClosingOperations.ExecutedSuccessfully
		And Data_Stage.State <> Enums.StatesOfMonthEndClosingOperations.NotRequired;
	
EndFunction

// Checks that the stage state is "not required".
//
// Parameters:
//	Data_Stage - ValueTableRow - a row in the stage table.
//
// Returns:
//	Boolean - a sign of a stage whose calculation is not required.
//
Function StageCalculationIsNotRequired(Data_Stage) Export
	
	Return Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotRequired;
	
EndFunction


// Adds explanatory information to the stage.
// In the month closing operations tree, it is displayed on the third level.
//
// Parameters:
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
//	Explanation 			 - String - explanation text for the set state
//	ReadMoreText 		 - String - Read more hyperlink text instead of the default text
//	ActionMoreDetails 	 - String - see functions of the form "Action description_..."
//	State 			 - EnumRef.AccountingIssueSeverity - status explanation the default is "Info".
//
Procedure AddExplanatoryInformationToStep(HandlerParameters, Explanation,
			ReadMoreText = "", ActionMoreDetails = Undefined, State = Undefined) Export
	
	ExplanationDescription = HandlerParameters.ExplanationTable_.Add();
	
	ExplanationDescription.Code 				= New UUID;
	ExplanationDescription.State	 		= ?(ValueIsFilled(State),
		State,
		Enums.AccountingIssueSeverity.Information);
	ExplanationDescription.Parent 			= HandlerParameters.Data_Stage.Code;
	
	ExplanationDescription.Description 		= Explanation;
	ExplanationDescription.ReadMoreText 	= ReadMoreText;
	ExplanationDescription.ActionMoreDetails = ActionMoreDetails;
	
EndProcedure

// Sets the state of the stage based on the data from the specified temporary table.
//
// Parameters:
//	HandlerParameters 		 - Structure - parameters of the stage event handler
//	TextTemplate1 		 		 - String - template for the explanation text generated for each row in the temporary table;
//									in the template, the %1 parameter is replaced with the organization, and %2-with the calculated period
//	Query 				 		 - Query - query with the temporary table Manager
//	TempTableName  		 - String - name of the temporary table for setting the stage state;
//									the required column in the temporary table is " Organization"
//	ForCalculatedOrganizations - Boolean - flag for selecting temporary table rows by organization from the array of Organizations property
//	IsError 			 		 - Boolean - indicates that the rows in the specified temporary table contain errors;
//									if True, the state of the stage will be set to "failed", otherwise - "not required".
//
Procedure CaptureUsageHandlerResultsForOrganizations(HandlerParameters, TextTemplate1, Query,
			TempTableName, ForCalculatedOrganizations, IsError = False) Export
	
	Query.Text = 
	"SELECT DISTINCT
	|	T.Ref AS Organization
	|FROM
	|	Catalog.Companies AS T
	|		LEFT JOIN TempTableName AS CheckResult
	|		ON T.Ref = CheckResult.Organization
	|WHERE
	|	T.Ref IN(&CompanyArray)
	|	AND CASE WHEN CheckResult.Organization IS NULL
	|		THEN TRUE
	|		ELSE FALSE
	|	  END = &ForCalculatedOrganizations
	|
	|ORDER BY
	|	Organization";
	
	Query.Text = StrReplace(Query.Text, "TempTableName", TempTableName);
	
	Query.SetParameter("ForCalculatedOrganizations", ForCalculatedOrganizations);
	
	Selection = Query.Execute().Select();
	
	IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, Selection.Count());
	
	While Selection.Next() Do
		
		ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
			TextTemplate1,
			Selection.Organization,
			CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod));
		
		If IsError Then
			SetStateFailed(HandlerParameters, ResultingText);
		Else
			NoNeedToSetState(HandlerParameters, ResultingText);
		EndIf;
		
	EndDo;
	
EndProcedure


// Determines the status of the specified month closing stages.
//
// Parameters:
//  Stages 							  - CatalogRef.MonthEndClosingOperations, Array - month closing operations
//	Period 							  - Date - calculated period
//	CompanyArray 				  - CatalogRef.Companies, Array - calculated organizations
//	AccountingForStateOfPreviousStages - Boolean - consider the status of previous stages that the specified stages depend on
//	PerformChecksBeforeStage 		  - Boolean - perform system health checks related to this stage.
//	UpdateOnlyOneStage			  - CatalogRef.MonthEndClosingOperations - Express check of the state of the specified stage only
//										 . it does not check the determination of the state of previous stages that affect the specified stage
//
// Returns:
//	Map
//		Key - Reference link.The month-closing operation is a stage
//		Value - Enum link.Operationstates of the month - the State of the stage
//	If one stage is passed to the Stages parameter, it returns not a match, but a value with the Link enumeration type.The state of the month's closing operations.
//
Function DetermineStateOfCalculationSteps(Stages, Period, CompanyArray = Undefined,
			AccountingForStateOfPreviousStages = True, PerformChecksBeforeStage = False, UpdateOnlyOneStage = Undefined) Export
	
	// Fill in the states of the stages.
	StructureOfData = DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState(
		BegOfMonth(Period),
		CompanyArray);
	
	ParametersForTriggeringStateUpdates =
		DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState(StructureOfData,, UpdateOnlyOneStage);
	
	ParametersForTriggeringStateUpdates.AccountingForStateOfPreviousStages = AccountingForStateOfPreviousStages;
	ParametersForTriggeringStateUpdates.PerformChecksBeforeStage 		  = PerformChecksBeforeStage;
	
	ParametersForTriggeringStateUpdates.UpdatedStages = TMCommonUseClientServer.Array(Stages);
	If ValueIsFilled(UpdateOnlyOneStage) Then
		TMCommonUseClientServer.AddNewValueToArray(ParametersForTriggeringStateUpdates.UpdatedStages, UpdateOnlyOneStage);
	EndIf;
	
	DataProcessors.MonthEndClosingOperations.FillInStatesOfStages(ParametersForTriggeringStateUpdates);
	
	// We will return the state of the required stages.
	ArrayOfStages = ParametersForTriggeringStateUpdates.UpdatedStages;
	StatesOfStages = New Map;
	
	For Each Stage In ArrayOfStages Do
		
		StageString_ = StructureOfData.TableStages.Find(Stage, "Code");
		
		If StageString_ <> Undefined Then
			StatesOfStages.Insert(Stage, StageString_.State);
		Else
			StatesOfStages.Insert(Stage, Enums.StatesOfMonthEndClosingOperations.NotRequired);
		EndIf;
		
	EndDo;
	
	If ArrayOfStages.Count() = 1 Then
		Return StatesOfStages[ArrayOfStages[0]];
	EndIf;
	
	Return StatesOfStages;
	
EndFunction

#EndRegion

#Region DataExchangeBetweenStageHandlers

// Sets an additional property of the stage handler for passing it to the next stage handlers.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	PropertyName 		 - String - additional property key
//	PropertyValue 	 - Arbitrary - value of the additional property.
//
Procedure SetAdditionalHandlerProperty(HandlerParameters, PropertyName, PropertyValue = Undefined) Export
	
	HandlerParameters.Data_Stage.AdditionalProperties.Insert(PropertyName, PropertyValue);
	
EndProcedure

// Returns an additional property of the stage handler that was set in previous stage handlers.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	PropertyName 		 - String - additional property key
//	DefaultValue  - Arbitrary - return value if an additional property with the specified name does not exist.
//
// Returns:
//	Arbitrary -
Function GetAdditionalHandlerProperty(HandlerParameters, PropertyName, DefaultValue = Undefined) Export
	
	If Not HandlerParameters.Data_Stage.AdditionalProperties.Property(PropertyName) Then
		Return DefaultValue;
	EndIf;
	
	Return HandlerParameters.Data_Stage.AdditionalProperties[PropertyName];
	
EndFunction

#EndRegion

#Region BackgroundTasksThatRunInStages

// Run a subordinate background task of the calculation stage.
// 
// Parameters:
//  CalculationID - UUID - calculation ID
//  MethodName - String - Method name
//  TaskHandlerParameters - Array of Arbitrary -  Task Handler Parameters
//  JobKey - String, Undefined -  task key
//  Description - String -  Description
// 
// Returns:
//  BackgroundJob -  subordinate background task of the calculation stage
Function StartSubordinateBackgroundTaskOfCalculationStage(CalculationID, MethodName, TaskHandlerParameters = Undefined,
			JobKey = Undefined, Description = "") Export

	Job = BackgroundJobs.Execute(
		MethodName,
		TaskHandlerParameters,
		JobKey,
		Description);
	
	SubordinateBackgroundTaskOfCalculationStageHasBeenStarted(CalculationID, Job.UUID);
	
	Return Job;
	
EndFunction

// A subordinate background task of the calculation stage has been started.
// 
// Parameters:
//  CalculationID - UUID -  calculation ID
//  JobID - UUID -  Task ID
Procedure SubordinateBackgroundTaskOfCalculationStageHasBeenStarted(CalculationID, JobID) Export

	If ValueIsFilled(CalculationID) Then
		
		RegisterRecord = InformationRegisters.LaunchedBackgroundJobsOfMonthEndClosingStages.CreateRecordManager();
		RegisterRecord.CalculationID = CalculationID;
		RegisterRecord.BackgroundJobIdentifier = JobID;
		RegisterRecord.StartDate = CurrentSessionDate();
		
		RegisterRecord.Write(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region MethodsForDealingWithSystemStateProblems

#Region RegistrationOfProblemsDetectedDuringSystemStateCheck

// Generates a description of the data that should be used to register the problems found.
//
// Parameters:
//	TempTableName 	  - String - name of the temporary table that stores information about problems found
//								required field - " Organization"
//	ErrorTextTemplate  	  - String - template for the problem description text
//								in the template, the %1 parameter is replaced with the organization, and %2 is replaced with the calculated period
//	FieldList 			  - ValueList - the list of fields in the temporary table; the Value is the field name, the View (optional) - representation of the field
//	ObjectFieldName 			  - String - name of the field that stores the object to decrypt the problem
//	RegisterNameToDecrypt - String - name of the register where the problem is fixed
//
// Returns:
//	Array - array of problem descriptions, see the code to add the Registration parametersproblemproblems
//
Function InitializeRegistrationAndVerificationParameters(TempTableName, ErrorTextTemplate, FieldList, ObjectFieldName = "", RegisterNameToDecrypt = "") Export
	
	RegistrationParameters = New Array;
	
	AddRegistrationAndVerificationParameters(RegistrationParameters, TempTableName, ErrorTextTemplate, FieldList, ObjectFieldName, RegisterNameToDecrypt);
	
	Return RegistrationParameters;
	
EndFunction

// Adds new data to the previously generated description, based on which you need to register the problems found.
//
// Parameters:
//	RegistrationParameters 	  - Array - result of the function Initializationregistrationparametersproblemproverts()
//	TempTableName  	  - String - similarly to the parameter of the same name Initializationregistrationparametersproblemprovery()
//	ErrorTextTemplate   	  - String - similarly to the parameter of the same name Initializationregistrationparametersproblemprovery()
//	FieldList 		 	  - ValueList - similarly to the parameter of the same name Initializationregistrationparametersproblemprovery()
//	ObjectFieldName 		 	  - String - similarly to the parameter of the same name Initializationregistrationparametersproblemprovery()
//	RegisterNameToDecrypt - String - similarly to the parameter of the same name Initializationregistrationparametersproblemprovery()
//
Procedure AddRegistrationAndVerificationParameters(RegistrationParameters, TempTableName, ErrorTextTemplate, FieldList, ObjectFieldName = "", RegisterNameToDecrypt = "") Export
	
	// Description of the error registration.
	RegistrationDetails = New Structure;
	RegistrationDetails.Insert("TempTableName", 	  TempTableName);
	RegistrationDetails.Insert("ErrorTextTemplate",  	  ErrorTextTemplate);
	RegistrationDetails.Insert("FieldList", 			  FieldList);
	RegistrationDetails.Insert("ObjectFieldName", 	 		  ObjectFieldName);
	RegistrationDetails.Insert("RegisterNameToDecrypt", RegisterNameToDecrypt);
	RegistrationDetails.Insert("QueryTextSamples", 	  "");
	
	// The text of the request for data sampling.
	RequestFieldText = "";
	For Each ListItem In FieldList Do
		RequestFieldText = RequestFieldText + ?(RequestFieldText = "", "", ",
			|	") + "T." + ListItem.Value;
	EndDo;
	
	QueryTextSamples =
	"SELECT
	|	&FieldText
	|FROM
	|	TableName AS T
	|
	|ORDER BY
	|	&FieldText
	|
	|TOTALS BY
	|	Organization";
	
	QueryTextSamples = StrReplace(QueryTextSamples, "&FieldText", RequestFieldText);
	QueryTextSamples = StrReplace(QueryTextSamples, "TableName", TempTableName);
	
	RegistrationDetails.QueryTextSamples = QueryTextSamples;
	
	RegistrationParameters.Add(RegistrationDetails);
	
EndProcedure

// Writes information to the IB about the problem that was diagnosed when checking the month closing stage.
//
// Parameters:
//	CheckParameters 			   - See AuditOfSystemState.InitializeVerificationParameters
//	RegistrationParameters 		   - Array - result of the function Initializationregistrationparametersproblemproverts()
//	TextOfTableGenerationRequest - String - request text for creating a temporary table with information about problems found
//	AdditionalRequestParameters_ - Structure - additional parameters for the request for creating a temporary table that are only used in this check.
//	IssueSeverity	 	  	   - EnumRef.AccountingIssueSeverity - the status of the issue; the default is "Error"
//
Procedure RegisterValidationIssues(CheckParameters, RegistrationParameters,
			TextOfTableGenerationRequest = "", AdditionalRequestParameters_ = Undefined, IssueSeverity = Undefined) Export
	
	CheckingBeforeCalculation    = ValueOfAdditionalVerificationParameter(CheckParameters, "CheckingBeforeCalculation",    False);
	CheckingAfterCalculation = ValueOfAdditionalVerificationParameter(CheckParameters, "CheckingAfterCalculation", False);
	
	If CheckingBeforeCalculation Or CheckingAfterCalculation Then
		
		HandlerParameters = InitializeParametersOfMonthClosingStageHandlerForVerification(CheckParameters);
		
		If CheckingBeforeCalculation And StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
			Return;
		EndIf;
		
		CalculationParameters = HandlerParameters.CalculationParameters;
		
	Else
		
		CalculationParameters = InitializeCalculationParametersForVerification(CheckParameters);
		
	EndIf;
	
	MaxNumberOfErrors = NumberOfRegisteredErrorsOfSameType();
	
	Query = New Query;
	
	InitializeRequest(
		Query,
		?(CheckingBeforeCalculation Or CheckingAfterCalculation, HandlerParameters, CalculationParameters)); // get the manager of the time tables
	
	TMCommonUse.SetRequestParameters(
		Query,
		AdditionalRequestParameters_); // we will set unique additional parameters for verification
	
	If ValueIsFilled(TextOfTableGenerationRequest) Then
		
		// The data table is not formed in the procedure for checking the use of the stage - we will form it here.
		Query.Text = TextOfTableGenerationRequest;
		Query.Execute();
		
	EndIf;
	
	For Each RegistrationDetails In RegistrationParameters Do
		
		Query.Text = RegistrationDetails.QueryTextSamples;
		
		SelectionOfOrganizations = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		While SelectionOfOrganizations.Next() Do
			
			// Let's register the problem.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				RegistrationDetails.ErrorTextTemplate,
				SelectionOfOrganizations.Organization,
				CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod));
			
			AuditOfSystemState.AddRowToProblemTable(
				CheckParameters,
				SelectionOfOrganizations.Organization,
				CalculationParameters.RegistrationPeriod,
				ErrorText,
				IssueSeverity);
			
			Selection = SelectionOfOrganizations.Select();
			
			ErrorNumber = 0;
			
			While Selection.Next() Do
				
				ErrorNumber = ErrorNumber + 1;
				
				If MaxNumberOfErrors > 0 And ErrorNumber > MaxNumberOfErrors Then
					
					NumberOfUnregistered = Selection.Count() - MaxNumberOfErrors;
					
					AddInformationAboutUnregisteredObjectsToFixedIssue(
						CheckParameters,
						ErrorText,
						NumberOfUnregistered);
					
					Break;
					
				EndIf;
					
				// Let's add an explanation of the problem by objects.
				If ValueIsFilled(RegistrationDetails.ObjectFieldName) Then
					
					AddObjectToFixedProblem(
						CheckParameters,
						Selection,
						ErrorText,
						RegistrationDetails.FieldList,
						RegistrationDetails.ObjectFieldName);
					
				Else
					
					AddCompositeObjectToFixedProblem(
						CheckParameters,
						Selection,
						ErrorText,
						RegistrationDetails.FieldList,
						RegistrationDetails.RegisterNameToDecrypt);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Returns additional validation parameters passed to it by the month closing mechanism.
//
// Parameters:
//	CheckParameters - Structure - parameter of the verification handler procedure, See AuditOfSystemState.InitializeVerificationParameters.
//
// Returns:
//	Structure: 
// 	* Period - StandardPeriod - structure of additional parameters for running the check; if the check is called outside the month closing mechanism, an empty structure is returned.
//
Function AdditionalVerificationParameters_(CheckParameters) Export
	
	If TypeOf(CheckParameters.AdditionalParameters) <> Type("Structure")
	 And TypeOf(CheckParameters.AdditionalParameters) <> Type("FixedStructure") Then
		Return New Structure;
	EndIf;
	
	Return CheckParameters.AdditionalParameters;
	
EndFunction

// Returns the value of the specified additional validation parameter passed to it by the month closing mechanism.
// If there is no parameter with this name, the default value of the parameter is returned.
//
// Parameters:
//	CheckParameters - Structure - parameter of the verification handler procedure, See AuditOfSystemState.InitializeVerificationParameters
//	ParameterName - String - key for the structure of additional parameters
//	DefaultValue - Arbitrary - the value returned by the function if there is no additional parameter with the specified name.
//
// Returns:
//	Arbitrary - the value of the additional verification parameter.
//
Function ValueOfAdditionalVerificationParameter(CheckParameters, ParameterName, DefaultValue = Undefined) Export
	
	AdditionalParameters = AdditionalVerificationParameters_(CheckParameters);
	
	If AdditionalParameters.Property(ParameterName) Then
		Return AdditionalParameters[ParameterName];
	EndIf;
	
	Return DefaultValue;
	
EndFunction

// Returns a flag indicating that the check was triggered by the month closing mechanism.
//
// Parameters:
//	CheckParameters - Structure - parameter of the verification handler procedure, See AuditOfSystemState.InitializeVerificationParameters.
//
// Returns:
//	Boolean - the check is called from Processing.Closing operations of the month.Perform a test of the step().
//
Function VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Export
	
	Return ValueOfAdditionalVerificationParameter(CheckParameters, "State", Null) <> Null;
	
EndFunction

// Initializes the parameters of the handler for the month closing stage for verification
//
// Parameters:
//	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
// Returns:
//  Structure - Contains:
//   * CalculationParameters        - Structure - The calculation parameters.
//   * Data_Stage - Structure - Contains:
//      ** Description - String - damienomenii.
//   * ExplanationTable_        - See DataProcessors.MonthEndClosingOperations.InitializeStepExplanationTable
//   * TempTablesManager - TempTablesManager - temporary table manager.
//
Function InitializeParametersOfMonthClosingStageHandlerForVerification(CheckParameters) Export
	
	CalculationParameters = InitializeCalculationParametersForVerification(CheckParameters);
	
	AdditionalParameters = AdditionalVerificationParameters_(CheckParameters);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("CalculationParameters", CalculationParameters);
	HandlerParameters.Insert("Data_Stage",	  GenerateDescriptionOfStageData(CheckParameters.AccountingChecksContext));
	HandlerParameters.Insert("ExplanationTable_", DataProcessors.MonthEndClosingOperations.InitializeStepExplanationTable());
	
	If AdditionalParameters.Property("TempTablesManager") Then
		// The data for verification has already been prepared - it must be performed unconditionally.
		HandlerParameters.Insert("TempTablesManager", AdditionalParameters.TempTablesManager);
	Else
		If AdditionalParameters.Property("State")
		 And StageStateDefined(AdditionalParameters) And StageRecalculationIsRequired(AdditionalParameters) Then
			// It is no longer necessary to check the status - it is known (a recalculation of the stage is required)
		Else
			// We will check the use of the calculation stage (the need for verification)
			// and at the same time prepare the necessary data for verification in the procedure for verifying the use of the stage.
			DataProcessors.MonthEndClosingOperations.CheckStageUsage(HandlerParameters);
		EndIf;
	EndIf;
	 
	Return HandlerParameters;
	
EndFunction

#EndRegion

#Region RegistrationOfProblemsDetectedDuringCalculationOfStage

// Adds information about the problem diagnosed during the calculation to the General list of problems in the stage calculation.
// Information about problems from this list will be recorded centrally by the month closing mechanism itself, after
// the stage calculation is completed. You should use this procedure if
// the universal parameter of the calculation handler-the handler Parameters-is available at the location of the problem.
// If this parameter is not available when calculating a stage, the stage calculation algorithm
// must register the problem itself, using the register problem of calculation Completion().
//
// Parameters:
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
//	Text_Details 		 - String - a detailed description of the problem; displayed in the form of a problem transcript from the month closing form
//	Organization 		 - CatalogRef.Companies, Array - organizations that this error applies to; if not specified, the error applies to each of the calculated organizations
//	Period 				 - Date - the period to which the error belongs; if omitted, the error belongs to the calculation period
//	IssueSeverity	 - EnumRef.AccountingIssueSeverity - the status of the issue; the default is "Error"
//	Object 				 - Arbitrary - object for decoding the problem.
//	
Procedure FixProblemWhenPerformingCalculation(HandlerParameters, Text_Details,
			Organization = Undefined, Period = Undefined, IssueSeverity = Undefined, Object = Undefined) Export
	
	ErrorDescription = HandlerParameters.ExplanationTable_.Add();
	
	ErrorDescription.Parent 		 = HandlerParameters.Data_Stage.Code;
	ErrorDescription.Description 	 = Text_Details;
	ErrorDescription.State 		 = IssueSeverity;
	ErrorDescription.Organization 		 = Organization;
	ErrorDescription.Period 			 = Period;
	ErrorDescription.DecodingError = Object;
	
EndProcedure

// Generates a description of the data that should be used to register the problem of performing the calculation.
//
// Parameters:
//  CalculationStage	- CatalogRef.MonthEndClosingOperations - the closing stage of the month.
//	Organization - CatalogRef.Companies, Array - organizations that this issue applies to
//					if not specified, the problem applies to each of the calculated organizations
//  Period		- Date - the period of calculation.
//
// Returns:
//	Structure - parameters of registration of the calculation problem.
//
Function InitializeParametersForRegisteringCalculationProblem(CalculationStage, Organization, Period) Export
	
	RegistrationParameters = New Structure;
	RegistrationParameters.Insert("CalculationStage", CalculationStage);
	RegistrationParameters.Insert("Organization", Organization);
	RegistrationParameters.Insert("Period", 	 Period);
	
	Return RegistrationParameters;
	
EndFunction

// Records information about the problem diagnosed during the calculation of the month closing stage in the IB.
// You should use this procedure if
// the universal parameter of the calculation handler-the handler Parameters-is not available at the location of the problem.
// If this parameter is available when calculating a stage, then the stage calculation algorithm
// should transmit information about the problem to the month closing mechanism via Fixingnalyproblemyprofillingaccount().
//
// Parameters:
//	RegistrationParameters - Structure - result of the function initializationregistrationparametersproblems of Calculation()
//	TextBriefly 		 - String - brief information about the problem; displayed in the form of closing the month
//	IssueSeverity 			 - EnumRef.AccountingIssueSeverity - the status of the issue; the default is "Error"
//	Text_Details 		 - String - detailed description of the problem; problems in the form of closing the month are grouped by text briefly + The importance of the problem, and this text is displayed in the form of a decoding of the problems
//	Object 				 - Arbitrary - object for decoding the problem.
//	
Procedure RegisterCalculationExecutionProblem(RegistrationParameters, TextBriefly,
			IssueSeverity = Undefined, Text_Details = "", Object = Undefined) Export
	
	If Not PrivilegedMode() Then		
		SetPrivilegedMode(True);
	EndIf;
	
	If Not ValueIsFilled(RegistrationParameters.Organization) Then
		CompanyArray = Catalogs.Companies.AvailableCompanies();
	Else			
		CompanyArray = TMCommonUseClientServer.Array(RegistrationParameters.Organization);
	EndIf;
	
	Validation = ServiceStageCheck(RegistrationParameters.CalculationStage);
	
	If Not ValueIsFilled(IssueSeverity) Then
		IssueSeverity = Common.ObjectAttributeValue(Validation, "IssueSeverity");
	EndIf;
	
	ObjectCompany = Undefined;
	MetadataObject = Metadata.FindByType(TypeOf(Object));
	If MetadataObject <> Undefined
		And Common.IsDocument(MetadataObject) Then 
		
		Query = New Query;
		Query.SetParameter("Object", Object);
		Query.Text = 
		"SELECT DISTINCT
		|	DocumentsRegistry.Organization AS Organization
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.Ref = &Object";
		
		ObjectCompany = Query.Execute().Unload().UnloadColumn("Organization");
		
	EndIf;
	
	For Each CurrentCompany In CompanyArray Do
		
		If ValueIsFilled(ObjectCompany)
			And ObjectCompany.Find(CurrentCompany) = Undefined Then
			Continue;
		EndIf;
		
		IssueText = StringFunctionsClientServer.SubstituteParametersToString(
			TextBriefly,
			TrimAll(CurrentCompany),
			CostCalculationProtocol.PresentationOfCalculationPeriod(RegistrationParameters.Period));
		
		IssueDetails = AuditOfSystemState.GenerateProblemDescription(
			IssueText,
			IssueSeverity,
			Text_Details,
			Object);
		
		AuditOfSystemState.RegisterProblem(
			Validation,
			CurrentCompany,
			BegOfDay(RegistrationParameters.Period),
			IssueDetails);
			
		If ValueIsFilled(Text_Details) Then
			DuplicateToLog(
				RegistrationParameters.CalculationStage,
				IssueSeverity,
				IssueText + ":" + Chars.LF + Text_Details);
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks for errors registered during the calculation of the specified month closing stage.
//
// Parameters:
//  CalculationStage	 	  - CatalogRef.MonthEndClosingOperations - the closing stage of the month.
//  CompanyArray - CatalogRef.Companies, Array - organizations being checked.
//  Period		 	  - Date - the period of calculation.
// 
// Returns:
//  Boolean - a sign of the presence of calculation errors.
//
Function ThereAreErrorsInPerformingCalculation(CalculationStage, CompanyArray, Period) Export
	
	Query = New Query;
	
	Query.Text = 
	"SELECT TOP 1
	|	1 AS Count
	|FROM
	|	InformationRegister.SystemStatusIssues AS Issues
	|WHERE
	|	Issues.Validation = &Validation
	|	AND Issues.Organization IN(&CompanyArray)
	|	AND BEGINOFPERIOD(Issues.CheckedPeriod, MONTH) = &Period
	|	AND Issues.Importance = VALUE(Enum.AccountingIssueSeverity.Error)";
	
	Query.SetParameter("Validation", 	 	   ServiceStageCheck(CalculationStage));
	Query.SetParameter("CompanyArray", TMCommonUseClientServer.Array(CompanyArray));
	Query.SetParameter("Period", 	 	   BegOfMonth(Period));
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

// Clear calculation execution problems.
// 
// Parameters:
//  CalculationStage - CatalogRef.MonthEndClosingOperations - Calculation Stage
//  CompanyArray - Array of CatalogRef.Companies - array of organizations
//  BeginOfPeriod - Date - Beginning of the period
//  EndOfPeriod - Date, Undefined - End of the period
Procedure ClearCalculationExecutionProblems(CalculationStage, CompanyArray, BeginOfPeriod, EndOfPeriod = Undefined) Export
	
	TableOfChecks = AuditOfSystemState.TableOfChecksByContext(
		CalculationStage,
		Undefined,
		True); // all contextual checks
		
	AuditOfSystemState.ClearInspectionResults(
		TableOfChecks.UnloadColumn("Validation"),
		CompanyArray,
		BegOfMonth(BeginOfPeriod),
		EndOfMonth(?(ValueIsFilled(EndOfPeriod), EndOfPeriod, BeginOfPeriod)));
	
EndProcedure

#EndRegion

#Region LogEntry

Function DuplicateFoundIssuesInLog()
	
	ParameterValues = CalculationOfCostCached.ValuesOfTechnologicalParameters(
		Catalogs.MonthEndClosingOperations.EmptyRef());
		
	Return ParameterValues.DuplicateFoundIssuesInLog;
	
EndFunction

Procedure DuplicateToLog(CalculationStage, SourceOfDeterminingImportanceOfProblem, ErrorText) Export
	
	If Not ValueIsFilled(ErrorText) Then
		Return;
	ElsIf Not DuplicateFoundIssuesInLog() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(SourceOfDeterminingImportanceOfProblem) Then
		IssueSeverity = Enums.AccountingIssueSeverity.Error;
	ElsIf TypeOf(SourceOfDeterminingImportanceOfProblem) = Type("EnumRef.AccountingIssueSeverity") Then
		IssueSeverity = SourceOfDeterminingImportanceOfProblem;
	Else
		IssueSeverity = CalculationOfCostCached.ImportanceOfCheckingSystemState(SourceOfDeterminingImportanceOfProblem);
	EndIf;
	
	If IssueSeverity = Enums.AccountingIssueSeverity.Error Then
		ELLevel = EventLogLevel.Error;
	ElsIf IssueSeverity = Enums.AccountingIssueSeverity.Warning
	 Or IssueSeverity = Enums.AccountingIssueSeverity.ImportantInformation Then
		ELLevel = EventLogLevel.Warning;
	Else
		ELLevel = EventLogLevel.Information;
	EndIf;
	
	WriteLogEvent(
		EventLogEventName(Catalogs.MonthEndClosingOperations.GetPredefinedItemName(CalculationStage)),
		ELLevel,
		,
		,
		ErrorText);
	
EndProcedure

#EndRegion

#EndRegion


#Region MethodsForWorkingWithTasksByEndOfMonth

// Returns the current value of the constant " Tasknumber...".
//
// Parameters:
//	ConstantName - String - the name of the constant the job number; if not specified, the "Nominatingcommittee".
//
// Returns:
//	Number - the value of the constant "Task number of the closing month". Determines the current number of the task for which the calculation will be performed.
//		All subsequent actions of the users of the information base in order to update the calculations will be written under a higher task number.
//
Function CurTaskNumber(Val ConstantName = "") Export
	
	If Not ValueIsFilled(ConstantName) Then
		ConstantName = Metadata.Constants.NumberOfJobForMonthEndClosing.Name;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Return Constants[ConstantName].Get();
	
EndFunction

// Increases the value of the constant "Task number...".
//
// Parameters:
//	ConstantName - String - the name of the constant the job number; if not specified, the "Nominatingcommittee".
//	StepUp - Number - how much should I increase the value of the constant
//
// Returns:
//	Number - the original task number.
//
Function IncreaseTaskNumber(Val ConstantName = "", StepUp = 1) Export
	
	NumberBeforeSettlement = 0;
	
	If Not ValueIsFilled(ConstantName) Then
		ConstantName = Metadata.Constants.NumberOfJobForMonthEndClosing.Name;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Constant." + ConstantName);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();		
		
		NumberBeforeSettlement = CurTaskNumber(ConstantName);
		ManagerOfConstant = Constants[ConstantName]; // ConstantManager.NumberOfJobForMonthEndClosing
		ManagerOfConstant.Set(NumberBeforeSettlement + StepUp);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = DetailErrorDescription(ErrorInfo())
			+ " " + NStr("vi = 'Giá trị không đổi';
						|ru = 'Значение константы';
						|en = 'Constant value'; fa = 'مقدار ثابت';
						|it = 'Valore della costante';
						|pl = 'Wartość konstanty';
						|tr = 'Sabit değer'") + " " + ConstantName + " = " + NumberBeforeSettlement;
		
		WriteLogEvent(
		    EventLogEventName(NStr("vi = 'Tăng số lượng công việc để tính toán';
									|ru = 'Увеличение номера задания для расчета';
									|en = 'Increase the number of job for calculation'; fa = 'Increase the number of job for calculation';
									|it = 'Aumento del numero del task per il calcolo';
									|pl = 'Zwiększenie numeru zadania do obliczania';
									|tr = 'Hesaplama için görev sayısını artırma'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			ErrorInfo);
			
		Raise ErrorInfo;
		
	EndTry;
	
	Return NumberBeforeSettlement;
	
EndFunction

// Returns the period from which data becomes irrelevant for this month closing operation.
//
// Parameters:
//	CalculationOperation   - CatalogRef.MonthEndClosingOperations - month closing stage
//	CalculationEnd 	  - Date - The end of the month for which you need to monitor the relevance of the calculation.
//	JobNumber 	  - Number - The number of the task that is used to control the relevance of entries in the task register.
//						Only records that do not exceed the specified task number are selected.
//	CompanyArray - Array - Array of organizations that are monitored for relevance.
//
// Returns:
//	Date - The beginning of the month for which the closing of the month is irrelevant. If the sequence is relevant in
//			the settlement period, the beginning of the next month for the settlement period will be returned.
//
Function CalculationStart(CalculationOperation, CalculationEnd, JobNumber = Undefined, CompanyArray = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MIN(Jobs.Month) AS CalculationStart
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|WHERE
	|	(Jobs.Month <= &CalculationEnd
	|		OR &CalculationEnd = DATETIME(1,1,1))
	|	AND Jobs.Operation = &CalculationOperation
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND (Jobs.Organization IN (&CompanyArray)
	|		OR &ByAllCompanies)
	|HAVING 
	|	NOT (MIN(Jobs.Month) IS NULL)";
	
	Query.SetParameter("CalculationEnd", 	    CalculationEnd);
	Query.SetParameter("CalculationOperation", 	CalculationOperation);
	Query.SetParameter("CompanyArray",  CompanyArray);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(CompanyArray));
	
	If Not ValueIsFilled(JobNumber) Then
		Query.SetParameter("JobNumber", CurTaskNumber());
	Else
		Query.SetParameter("JobNumber", JobNumber);
	EndIf;
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.CalculationStart;
	ElsIf CalculationEnd <> '000101010000' Then
		Return EndOfMonth(CalculationEnd) + 1;
	Else
		Return '000101010000';
	EndIf;
	
EndFunction

// Checks the correspondence of the task number constant with the month's closure and entries in the register of the task with the month's closure.
// In some cases, the entries in the register may have a number larger than the one stored in the constant.
// Because of this, the Calculation Start() function may return an incorrect result.
Procedure CheckTaskNumber() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Jobs.JobNumber) AS JobNumber
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|WHERE
	|	Jobs.JobNumber > &JobNumber
	|";
	
	Query.SetParameter("JobNumber", CurTaskNumber());
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() And ValueIsFilled(Selection.JobNumber) Then
		IncreaseTaskNumber(, Selection.JobNumber - Query.Parameters.JobNumber);
	EndIf;
	
EndProcedure

// Records a successful recalculation. Called when a recalculation is performed to clear records that indicate that a recalculation is necessary.
//
// Parameters:
//	NextMonth - Date - specifies the month at the beginning of which the need to update the calculation data will be recorded;
//	CalculationOperation - CatalogRef.MonthEndClosingOperations - operation for which the calculation was performed;
//	TemporaryTable - TempTablesManager - Contains a table of cache Borders.
//
Procedure FixCalculation(NextMonth, CalculationOperation, TemporaryTable) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Jobs.Month,
	|	Jobs.Operation,
	|	Jobs.Organization,
	|	Jobs.JobNumber,
	|	Jobs.Document
	|FROM
	|	BorderCache AS Jobs
	|;
	|/////////////////////////////////////////////
	|SELECT DISTINCT
	|	&NextMonth                   AS Month,
	|	Boundaries.Operation                  AS Operation,
	|	Boundaries.Organization               AS Organization,
	|	MAX(Boundaries.JobNumber)    AS JobNumber,
	|	UNDEFINED                      AS Document
	|FROM
	|	BorderCache AS Boundaries
	|
	|	LEFT JOIN InformationRegister.JobsForMonthEndClosing AS Jobs
	|	ON &NextMonth = Jobs.Month
	|		AND Boundaries.Operation = Jobs.Operation
	|		AND Boundaries.Organization = Jobs.Organization
	|		AND Boundaries.JobNumber = Jobs.JobNumber
	|		AND UNDEFINED = Jobs.Document
	|WHERE
	|	Jobs.Month IS NULL
	|
	|GROUP BY
	|	Boundaries.Operation,
	|	Boundaries.Organization";
	
	Query.TempTablesManager = TemporaryTable;
	Query.SetParameter("NextMonth", NextMonth);
	
	Result = Query.ExecuteBatch(); 
	Selection = Result.Get(0).Select();
	While Selection.Next() Do
		Set = InformationRegisters.JobsForMonthEndClosing.CreateRecordSet();
		Set.Filter.Month.Set(Selection.Month);
		Set.Filter.Operation.Set(Selection.Operation);
		Set.Filter.Organization.Set(Selection.Organization);
		Set.Filter.JobNumber.Set(Selection.JobNumber);
		Set.Filter.Document.Set(Selection.Document);
		Set.Write(); // Cleared calculated analysts in the last period
	EndDo;
	
	If ValueIsFilled(NextMonth) Then
		Selection = Result.Get(1).Select();
		While Selection.Next() Do
			Set = InformationRegisters.JobsForMonthEndClosing.CreateRecordSet();
			Set.Filter.Month.Set(Selection.Month);
			Set.Filter.Operation.Set(Selection.Operation);
			Set.Filter.Organization.Set(Selection.Organization);
			Set.Filter.JobNumber.Set(Selection.JobNumber);
			Set.Filter.Document.Set(Selection.Document);
			SetRow = Set.Add();
			FillPropertyValues(SetRow, Selection);
			Set.Write(True); // Moved calculated analytics to a new period
		EndDo;
	EndIf;
	
EndProcedure

// Blocks the "Tasks to close the month" register for the specified Analytics.
//
// Parameters:
//	TaskNumberBeforeCalculation - Number - Task number from the "task Number to close the month" constant.
//	Companies 		  - CatalogRef.Companies, Array of CatalogRef.Companies - List of organizations to be blocked.
//	Operation 			  - CatalogRef.MonthEndClosingOperations - Operation that blocks the task register.
//  Document              - DocumentRef - The document according to which the entry was made in the PC of the assignment of the closing month. If 
//								the parameter is not passed, then the lock is set of Operation as a whole. 
Procedure BlockTaskRegister(TaskNumberBeforeCalculation, Companies, Operation, Document = Undefined) Export
	
	If Common.FileInfobase() Then
		Return;
	EndIf;
	
	Block = New DataLock;
	
	RegisterName = "InformationRegister.JobsForMonthEndClosing";
	LockItem = Block.Add(RegisterName);
	LockItem.SetValue("JobNumber", New Range(Undefined, TaskNumberBeforeCalculation));
	
	LockItem.SetValue("Operation", Operation);
	If ValueIsFilled(Document) Then
		LockItem.SetValue("Document", Document);
	EndIf;
	
	LockSource = New ValueTable;
	LockSource.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	
	If TypeOf(Companies) = Type("Array") Then
		RowsCount = Companies.Count();
		If RowsCount <> 0 Then
			Counter = 0;
			While Counter < RowsCount Do
				LockSource.Add();
				Counter = Counter + 1;
			EndDo;
			LockSource.LoadColumn(Companies, "Organization");
			LockItem.DataSource = LockSource;
			LockItem.UseFromDataSource("Organization", "Organization");
		EndIf;
		// if the array is empty, then the lock is placed on all organizations.
	ElsIf TypeOf(Companies) = Type("CatalogRef.Companies")
		And ValueIsFilled(Companies) Then
		LockString = LockSource.Add();
		LockString.Organization = Companies;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("Organization", "Organization");
	EndIf;
	
	LockItem.Mode = DataLockMode.Exclusive;
	
	Block.Lock();
	
EndProcedure

// Reads entries in the "Tasks to close the month" register to the temporary table for the specified selection period.
//
// Parameters:
//	BeginOfPeriod - Date - Start of the data sampling period.
//	EndOfPeriod  - Date - End of the data sampling period.
//	JobNumber  - Number - The number of the task that is used to control the relevance of entries in the task register.
//							Only records that do not exceed the specified task number are selected.
//	Companies   - Array of CatalogRef.Companies - Filter by organization.
//	Operation 	  - CatalogRef.MonthEndClosingOperations - Filter by type of operation.
//	Document      - DocumentRef - 
//
// Returns:
//	Structure:
//		* Organization - Array of CatalogRef.Companies - An array of organizations that are not relevant in the specified period.
//		* TemporaryTable - TempTablesManager - Contains a temporary table of cache Borders.
//		* JobNumber - Number - The number of the task by which the relevance of entries in the task register is monitored.
//		* CalculationPeriod - Date - The beginning of the period for which we create tasks.
//
Function MonthlyTasks(BeginOfPeriod, EndOfPeriod, JobNumber, Companies, Operation, Document = Undefined) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text =
	"SELECT
	|	Jobs.Month,
	|	Jobs.Operation,
	|	Jobs.Organization,
	|	Jobs.JobNumber,
	|	Jobs.Document
	|INTO BorderCache
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|WHERE
	|	(Jobs.Month >= &BeginOfPeriod
	|		 OR &BeginOfPeriod = DATETIME(1,1,1))
	|	AND (Jobs.Month <= &EndOfPeriod
	|		 OR &EndOfPeriod = DATETIME(1,1,1))
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND Jobs.Operation = &Operation
	|	AND (Jobs.Organization IN (&Companies) OR &ByAllCompanies)
	|	AND (Jobs.Document IN (&Document) OR &AccordingToAllDocuments)
	|;
	|//////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BorderCache.Organization
	|FROM
	|	BorderCache AS BorderCache";
	
	Query.SetParameter("BeginOfPeriod", 		BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  		EndOfPeriod);
	Query.SetParameter("JobNumber",  		JobNumber);
	Query.SetParameter("Operation", 	   		Operation);
	Query.SetParameter("Companies",   		Companies);
	Query.SetParameter("ByAllCompanies",	Not ValueIsFilled(Companies));
	Query.SetParameter("Document",      		Document);
	Query.SetParameter("AccordingToAllDocuments", 	Not ValueIsFilled(Document));

	Result = Query.ExecuteBatch();
	
	RawData = New Structure;
	RawData.Insert("Organization", 		Result[1].Unload().UnloadColumn("Organization"));
	RawData.Insert("TemporaryTable", Query.TempTablesManager);
	RawData.Insert("JobNumber", 	JobNumber);
	RawData.Insert("CalculationPeriod", 	BeginOfPeriod);
	
	Return RawData;
	
EndFunction

// Generates entries in the task register by the end of the month, when the entries in the registers are changed.
//
// Parameters:
//	SourceOfDocumentProperties - DocumentObject, Structure - the document being conducted or the result of the document execution function.Document emulation() for batch generation of tasks
//  TempTablesManager - TempTablesManager - a temporary table Manager that contains tables of register changes.
//
Procedure ReflectTasksByEndOfMonth(SourceOfDocumentProperties, TempTablesManager) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then // tasks are installed only in the main node.
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactionsServer.ReflectTasksByEndOfMonth");

	UndoPosting = DocumentsPosting.DocumentProperties(SourceOfDocumentProperties).WriteMode = DocumentWriteMode.UndoPosting;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Parameters.Insert("ControlRegisterTables", New Structure);
	
	QueryTemplate = "
	|SELECT DISTINCT
	|	Table.Month        AS Month,
	|	Table.Operation     AS Operation,
	|	Table.Organization  AS Organization,
	|	Table.Document     AS Document
	|FROM
	|	&DataCollection AS Table
	|;
	|";
	
	TheTextOfASubquery = "";
	TempTablesQueryText = "";
	TemporaryTableNames = "";
	
	VATAccountingERP.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames,
		SourceOfDocumentProperties);
	
	ARAPAccountingServer.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames);
	AccrualAndWriteOffOfBadDebtAlowancesServer.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames,
		UndoPosting);
	Documents.ExchangeDifferenceCalculation.AddTextOfRequestForTasksByEndOfMonth(Query, 
		TheTextOfASubquery, 
		TempTablesQueryText,
		TemporaryTableNames);
	FutureExpenseCommitments.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames);
	MonthEndTransactionsLocalization.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames);
	RDExpensesAccounting.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames);

	ImpairmentFAServer.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames,
		SourceOfDocumentProperties);
	FinancialAccountingOfMonthEndClosing.AddTextOfRequestForTasksByEndOfMonth(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames);

	TextDestroyW = TemporaryTableDestructionQueryTest(TemporaryTableNames);
	
	If ValueIsFilled(TheTextOfASubquery) Then // there is at least one control register.
		
		
		Query.Text = TempTablesQueryText
			+ StrReplace(QueryTemplate, "&DataCollection", "(" + TheTextOfASubquery + ")")
			+ TextDestroyW;
			
		Selection = Query.Execute().Select();
		
		InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntriesBasedOnSampleData(Selection);
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

// Returns the task date for the current period, depending on the operation.
// 
// Parameters:
// 	Operation - CatalogRef.MonthEndClosingOperations - the operation of closing the month.
// 	Organization - CatalogRef.Companies - link to the organization.
// 	DocumentJobs - DocumentRef - task document.
// 	Period - Date - date of the task.
// Returns:
// 	Date - Date of the task
//
Function TaskDateForCurPeriod(Operation, Organization, DocumentJobs, Val Period) Export
	
	Month = BegOfMonth(Period);
	Month = MonthEndTransactionsLocalization.TaskDateForCurPeriod(Operation, Organization, DocumentJobs, Month);
	Return Month
EndFunction

// Returns the task date for the next period, depending on the operation.
// 
// Parameters:
// 	Operation - CatalogRef.MonthEndClosingOperations - the operation of closing the month.
// 	Organization - CatalogRef.Companies - link to the organization.
// 	DocumentJobs - DocumentRef - task document.
// 	NextMonth - Date - date of the task.
// Returns:
// 	Date - Date of the task
//
Function TaskDateForNextPeriod(Operation, Organization, DocumentJobs, Val NextMonth) Export
	
	TaskDate_ = MonthEndTransactionsLocalization.TaskDateForNextPeriod(Operation, Organization, DocumentJobs, NextMonth);
	If Operation = Catalogs.MonthEndClosingOperations.GenerateLossAllowance Then
		
		TaskDate_ = Documents.AccrualAndWriteOffOfBadDebtAlowances.PeriodOfCalculationOfProvisionsForDoubtfulDebts(Organization, NextMonth);
				
	ElsIf Operation = Catalogs.MonthEndClosingOperations.AccrualOfLeaseInterest Then
		
		TaskDate_ = Documents.AccrualOfLeaseInterest.LeaseInterestAccrualPeriod(Organization, NextMonth);
				
	ElsIf Operation = Catalogs.MonthEndClosingOperations.AccrueProfitableRentalInterest Then
		
		TaskDate_ = Documents.AccrualOfLeaseInterest.PeriodOfAccrualOfInterestOnProfitableLeases(Organization, NextMonth);
				
	ElsIf Operation = Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets Then
		
		TaskDate_ = ClosingExpensesFromDisposalOfFixedAssets.NextPeriodOfOperation(Organization, NextMonth);
				
	ElsIf Operation = Catalogs.MonthEndClosingOperations.CalculateRentalInvestmentCost Then
		
		TaskDate_ = CalculateRentalInvestmentCost.NextPeriodOfOperation(Organization, NextMonth);
				
	EndIf;
	Return TaskDate_
	
EndFunction

// Complements the text of the request for creating tasks.
// 
// Parameters:
// 	TableName - String - name of the table to search in the temporary table Manager.
// 	QueriesTexts - See InitializeStructureOfQueryTexts
// 	Tables - TempTablesManager - Manager of temporary query tables.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
//
Procedure AddTaskRequestText(TableName, QueriesTexts, Tables, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	If Tables.Find(TableName) <> Undefined Then
		If ValueIsFilled(QueryText) Then
			QueryText = QueryText + "
			|
			|UNION ALL
			|";
		EndIf;
		QueryText = QueryText + QueriesTexts.QueryText;
		TempTablesQueryText = TempTablesQueryText + QueriesTexts.TempTablesQueryText;
		If ValueIsFilled(QueriesTexts.TemporaryTableNames) Then
			TemporaryTableNames = TemporaryTableNames + ", " + QueriesTexts.TemporaryTableNames;
		EndIf;
	EndIf;
EndProcedure

// Complements the information about the temporary tables used.
// 
// Parameters:
//  Query - Query - Query
//  TableName - String - table name
Procedure AddTableNamesForTasks(Query, TableName) Export
	
	If Query.Parameters.Property("ControlRegisterTables") Then
		Query.Parameters.ControlRegisterTables.Insert(TableName);
	EndIf;
	
EndProcedure

// Generates the text of a request to destroy temporary tables.
// 
// Parameters:
// 	TemporaryTableNames - String - names of temporary tables to be destroyed, separated by commas.
//
// Returns:
// 	String - query text.
//
Function TemporaryTableDestructionQueryTest(TemporaryTableNames) Export
	
	Tables = StrConcat(StrSplit(TemporaryTableNames, ",", False), ",");
	Tables = New Structure(Tables);
	QueryTest = "";
	QueryTemplate = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP %1;
	|";
	
	For Each KeyAndValue In Tables Do
		QueryTest = QueryTest + StrTemplate(QueryTemplate, KeyAndValue.Key);
	EndDo;
	
	Return QueryTest;
	
EndFunction

// Initializes the structure of query texts
// 
// Parameters:
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
// Returns:
// 	Structure - LongDesc:
// * QueryText - String - a string with the request text.
// * TempTablesQueryText - String - a string containing the text of a temporary table query.
// * TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
//
Function InitializeStructureOfQueryTexts(QueryText, TempTablesQueryText = "", TemporaryTableNames = "") Export
	StructureOfQueryTexts_ = New Structure("QueryText, TempTablesQueryText, TemporaryTableNames",
		QueryText,
		TempTablesQueryText,
		TemporaryTableNames);
	Return StructureOfQueryTexts_
EndFunction

// Deletes tasks for calculating the month's closing for the period specified in the handler.
//
// Parameters:
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters 
//	DataForCalculation - See MonthlyTasks.
//	Document - DocumentRef - if the value is filled in, jobs will be cleared only by the passed value
//	
Procedure DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, DataForCalculation = Undefined, Document = Undefined) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	AvailableCompanies = CompaniesAvailableForSettlement(CalculationParameters.EndOfPeriod, CalculationParameters.CompanyArray);
	
	BeginTransaction();
	
	Try
		
		JobNumber = ?(DataForCalculation = Undefined, IncreaseTaskNumber(), DataForCalculation.JobNumber);
	
		BlockTaskRegister(
			JobNumber,
			AvailableCompanies,
			HandlerParameters.Data_Stage.Code,
			Document);
		
		If DataForCalculation = Undefined Then
			DataForCalculation = MonthlyTasks(
				CalculationParameters.BeginOfPeriod,
				CalculationParameters.EndOfPeriod,
				JobNumber,
				AvailableCompanies,
				HandlerParameters.Data_Stage.Code,
				Document);
		EndIf;
		
		FixCalculation(Undefined, HandlerParameters.Data_Stage.Code, DataForCalculation.TemporaryTable);
		
		ToCreateTasksForNextPeriod = True;
		MonthEndTransactionsLocalization.CheckNeedToGenerateTasksForNextPeriod(ToCreateTasksForNextPeriod, HandlerParameters);
		If ToCreateTasksForNextPeriod Then
			InformationRegisters.JobsForMonthEndClosing.CreateTasksForNextPeriod(
				DataForCalculation.TemporaryTable,
				EndOfMonth(DataForCalculation.CalculationPeriod) + 1);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		PresentationOfCalculationPeriod = CostCalculationProtocol.PresentationOfCalculationPeriod(DataForCalculation.CalculationPeriod);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi thực hiện hạch toán trong kỳ %1, đã xảy ra lỗi:
				|%2';
				|ru = 'При выполнении расчета за период %1 произошла ошибка:
				|%2';
				|en = 'An error occurred when calculating for the %1 period:
				|%2'; fa = 'An error occurred when calculating for the %1 period:
				|%2';
				|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
				|%2';
				|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
				|%2';
				|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
				|%2'", Common.DefaultLanguageCode()),
			PresentationOfCalculationPeriod,
			DetailErrorDescription(ErrorInfo()));
		
		FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText,
			AvailableCompanies,
			DataForCalculation.CalculationPeriod);
		
	EndTry;
	
EndProcedure

// Receives data for calculation, along with blocking the register of tasks, in a transaction and using an attempt
//
//	Parameters:
//		Parameters - Structure - See InitializeJobHandlingProperties()
//
//	Returns:
//		Structure:
//		* Organization - Array of CatalogRef.Companies - An array of organizations that are not relevant in the specified period.
//		* TemporaryTable - TempTablesManager - Contains a temporary table of cache Borders.
//		* JobNumber - Number - The number of the task by which the relevance of entries in the task register is monitored.
//		* CalculationPeriod - Date - The beginning of the period for which we create tasks.
//
Function DataForCalculation(Parameters) Export
	
	BeginTransaction();
	Try
		BlockTaskRegister(Parameters.JobNumber, Parameters.Companies, Parameters.Operation);
		Result = MonthlyTasks(Parameters.BeginOfPeriod, Parameters.EndOfPeriod, Parameters.JobNumber,
			Parameters.Companies, Parameters.Operation);
		CommitTransaction();
	Except
		RollbackTransaction();
		MessageText = NStr("ru = 'Не удалось заблокировать регистр заданий по причине: %ErrorReason%';
							|vi = 'Cannot lock the job register due to: %ErrorReason%';
							|en = 'Cannot lock the job register due to: %ErrorReason%'; fa = 'Cannot lock the job register due to: %ErrorReason%';
							|it = 'Cannot lock the job register due to: %ErrorReason%';
							|pl = 'Cannot lock the job register due to: %ErrorReason%';
							|tr = 'Görev kaydı şu nedenle kilitlenemedi: %ErrorReason%'");
		MessageText = StrReplace(MessageText, "%ErrorReason%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(String(Parameters.Operation), Common.DefaultLanguageCode(),
			EventLogLevel.Error, , , MessageText);
		Parameters.Cancel = True;
	EndTry;
		
	Return Result;
		
EndFunction

// Fixes the calculation, along with locking the job register, in the transaction and using the attempt
//
//	Parameters:
//		Parameters - Structure - See InitializeJobHandlingProperties()
//		DataForCalculation - Structure - See MonthlyTasks()
//
Procedure CommitSettlementTransaction(Parameters, DataForCalculation) Export
	
	If Parameters.Cancel Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		BlockTaskRegister(Parameters.JobNumber, Parameters.Companies, Parameters.Operation);
		NextPeriod = TaskDateForNextPeriod(Parameters.Operation, Parameters.Companies.Get(0), Undefined, Parameters.EndOfPeriod + 1);
		FixCalculation(NextPeriod, Parameters.Operation, DataForCalculation.TemporaryTable);
		CommitTransaction();
	Except
		RollbackTransaction();
		MessageText = NStr("ru = 'Не удалось зафиксировать расчет в регистре заданий по причине: %ErrorReason%';
							|vi = 'Cannot register calculation in the job register due to: %ErrorReason%';
							|en = 'Cannot register calculation in the job register due to: %ErrorReason%'; fa = 'Cannot register calculation in the job register due to: %ErrorReason%';
							|it = 'Cannot register calculation in the job register due to: %ErrorReason%';
							|pl = 'Cannot register calculation in the job register due to: %ErrorReason%';
							|tr = 'Hesaplama şu nedenle görev kaydına işlenemedi: %ErrorReason%'");
		MessageText = StrReplace(MessageText, "%ErrorReason%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(String(Parameters.Operation), Common.DefaultLanguageCode(),
			EventLogLevel.Error, , , MessageText);
		Parameters.Cancel = True;
	EndTry;
	
EndProcedure

//	Returns a set of properties for working with month-closing tasks (getting data for calculation, fixing calculation)
//	. When called, it immediately increases the task number.
//	
//	Parameters:
//		IncreaseNumber - Boolean - if true, the task number is set immediately (the "Increase number" method is called), the default value is False.
//
//	Returns:
//		Structure:
//		* JobNumber - Number - Task number from the constant "Task number by the end of the month"
//		* Operation - CatalogRef.MonthEndClosingOperations - the Operation for which the calculation is performed
//		* Companies - Array of CatalogRef.Companies - array of organizations for which the calculation is carried out
//		* BeginOfPeriod - Date - Start Of Settlement Period
//		* EndOfPeriod - Date - End Of Settlement Period
//		* Cancel - Boolean - Indicates the presence of errors.
//
Function InitializeJobHandlingProperties(IncreaseNumber = False) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("JobNumber", 0);
	ReturnStructure.Insert("Operation", Catalogs.MonthEndClosingOperations.EmptyRef());
	ReturnStructure.Insert("Companies", New Array);
	ReturnStructure.Insert("BeginOfPeriod", '00010101');
	ReturnStructure.Insert("EndOfPeriod", '00010101');
	ReturnStructure.Insert("Cancel", False);
	
	If IncreaseNumber Then
		ReturnStructure.JobNumber = IncreaseTaskNumber();
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

#Region MethodsForSettingSelectionsInOpenableForms

// Checks the mode of opening the form-opened from the processing of the "month closing Operation" or not from it.
//
// Parameters:
//	Form - ClientApplicationForm - form of list of documents.
//
// Returns:
//	Boolean - a sign of the opening of the form from the month closing mechanism.
//
Function ThisFormIsOpenedFromMonthClosingForm(Form) Export
	
	Return Form.Parameters.Property(MonthEndTransactionsClientServer.NameOfServicePropertyOfFormsToOpen());
	
EndFunction

// Sets selections in the forms of regulatory documents of regulated and international accounting
// that are opened from the month closing operations form.
//
// Parameters:
//	Form 					  - ClientApplicationForm - form of list of documents
//	List 					  - DynamicList - list of documents in this form
//	NameOfFieldToSelectByPeriod - String - name of the field to select by period, by default "date".
//
// Returns:
//	Boolean - a sign of the selection setting; True if the form was opened from the month closing mechanism.
//
Function EstablishSelectionsInFormOfListOfRegulatoryDocuments(Form, List, NameOfFieldToSelectByPeriod = "Date") Export
	
	If Not ThisFormIsOpenedFromMonthClosingForm(Form) Then
		Return False;
	EndIf;
	
	List.SettingsComposer.Settings.Filter.Items.Clear();
	
	Form.Parameters.Filter.Clear();
	
	// Selection by organization.
	If List.Parameters.Items.Find("CompanyArray") <> Undefined Then
		
		List.Parameters.SetParameterValue("CompanyArray", Form.Parameters.CompanyArray);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Organization",
			Form.Parameters.CompanyArray,
			DataCompositionComparisonType.InList,
			,
			True,
			DataCompositionSettingsItemViewMode.Normal,
			"ClosingOfMonth_Organization");
		
	EndIf;
	
	// selection by period.
	CommonClientServer.SetDynamicListFilterItem(
		List,
		NameOfFieldToSelectByPeriod,
		BegOfMonth(Form.Parameters.RegistrationPeriod),
		DataCompositionComparisonType.GreaterOrEqual,
		,
		True,
		DataCompositionSettingsItemViewMode.Normal,
		"ClosingOfMonth_BeginningOfPeriod");
		
	CommonClientServer.AddCompositionItem(
		List.SettingsComposer.Settings.Filter,
		NameOfFieldToSelectByPeriod,
		DataCompositionComparisonType.LessOrEqual,
		EndOfMonth(Form.Parameters.RegistrationPeriod),
		,
		True,
		DataCompositionSettingsItemViewMode.Normal,
		"ClosingMonth_EndOfPeriod");
	
	// Selection by type of operation.
	If Form.Parameters.Property("OperationType") Then
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"OperationType",
			Form.Parameters.OperationType,
			DataCompositionComparisonType.InList,
			,
			True,
			DataCompositionSettingsItemViewMode.Normal,
			"ClosingOfMonth_TypeOfOperation");
	EndIf;
	
	Return True;
	
EndFunction

// Clears previously set selections in the forms of regulatory documents of regulated and international accounting
// that are opened from the month closing operations form.
//
// Parameters:
//	Form     - ClientApplicationForm - form of list of documents
//	List    - DynamicList - list of documents in this form
//	Settings - DataCompositionUserSettings - parameter of the procedure for preloading the user settings on the Server.
//
// Returns:
//	Boolean - a sign of the selection setting; True if the form was opened from the month closing mechanism.
//
Function ClearPreviouslyEstablishedSelectionsInFormOfListOfRegulatoryDocuments(Form, List, Settings) Export
	
	If Not ThisFormIsOpenedFromMonthClosingForm(Form) Then
		Return False;
	EndIf;
	
	SavingSettings = New Structure; // For names, see To install the collection of the form of regulatory documents
	SavingSettings.Insert("ClosingOfMonth_Organization");
	SavingSettings.Insert("ClosingOfMonth_BeginningOfPeriod");
	SavingSettings.Insert("ClosingMonth_EndOfPeriod");
	SavingSettings.Insert("ClosingOfMonth_TypeOfOperation");
	
	For Each KeyAndValue In SavingSettings Do
		
		CompositionFilter = Settings.Items.Find(KeyAndValue.Key);
		
		If CompositionFilter <> Undefined Then
			CompositionFilter.Use = False;
			CompositionFilter.UserSettingID = "";
			CompositionFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction


// Sets selections in the forms of register lists opened from the form of errors found during verification.
//
// Parameters:
//	Form 					  - ClientApplicationForm - the list form of the register
//	List 					  - DynamicList - register entries in this form
//
// Returns:
//	Boolean - a sign of the selection setting; True if the form was opened from the month closing mechanism
//
Function SetSelectionsInRegisterListForm(Form, List) Export
	
	If Not ThisFormIsOpenedFromMonthClosingForm(Form) Then
		Return False;
	EndIf;
	
	List.SettingsComposer.Settings.Filter.Items.Clear();
	
	Form.Parameters.Filter.Clear();
	
	FilterToDecrypt = Form.Parameters.FilterToDecrypt;
	
	// selection by period.
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Period",
		BegOfMonth(FilterToDecrypt.Period),
		DataCompositionComparisonType.GreaterOrEqual,
		,
		True,
		DataCompositionSettingsItemViewMode.Normal,
		TrimAll(New UUID));
		
	CommonClientServer.AddCompositionItem(
		List.SettingsComposer.Settings.Filter,
		"Period",
		DataCompositionComparisonType.LessOrEqual,
		EndOfMonth(FilterToDecrypt.Period),
		,
		True,
		DataCompositionSettingsItemViewMode.Normal,
		TrimAll(New UUID));
	
	// Selection by the remaining decryption fields.
	For Each KeyAndValue In FilterToDecrypt Do
		
		If Lower(KeyAndValue.Key) = Lower("Period") Then
			Continue; // this selection has already been established
		ElsIf List.SettingsComposer.Settings.FilterAvailableFields.Items.Find(KeyAndValue.Key) = Undefined Then
			Continue; // there is no such field in the list
		EndIf;
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			KeyAndValue.Key,
			KeyAndValue.Value,
			DataCompositionComparisonType.Equal,
			,
			True,
			DataCompositionSettingsItemViewMode.Normal,
			TrimAll(New UUID));
		
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion


#Region GeneralQueryTexts

// Returns the text of the query to determine the status of the reflection of documents in regulatory accounting.
//
// Returns:
//	String - the text of the request to determine the status of the reflection of documents.
//
Function RequestTextDocumentReflectionState() Export

	Return MonthEndTransactionsLocalization.RequestTextDocumentReflectionState();
	
EndFunction
// Returns query texts for getting a table of changes to the accumulation register record set when it is written.
// The request is drawn up on the basis of the metadata registry: dimensions resources and information.
//
// Parameters:
//	RegisterMetadata - MetadataObjectAccumulationRegister - metadata of the register for which the change table is compiled;
//	Filter - Structure -
//	AdditionalParameters - See Testing.AdditionalParametersForFormingComparisonRequest 
//
// Returns:
//	Structure - LongDesc:
//	* InitialDataSampleText - String - request to execute in the "pre-Write" event of the accumulation register data set.
//		Generates current register entries and saves them to the temporary table " initial Entries";
//	* SampleTextOfChangeTable - String - request for a summary table of changes. Executed in the "Recording" event.
//		It is compiled by combining the initial Record table and the new register record table. Only records for which there are differences are displayed (the sum of resources is not equal to 0).
//
Function QueryTextsForCaseChangeTable(RegisterMetadata, Filter, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = Testing.AdditionalParametersForFormingComparisonRequest();
	EndIf;
	
	RegisterTable = RegisterMetadata.FullName();
	IsAccountingRegister = Common.BaseTypeNameByMetadataObject(RegisterMetadata) = "AccountingRegisters";
	
	If IsAccountingRegister Then
		
		RegisterTable = RegisterTable + ".RecordsWithExtDimensions(, , Recorder = &Recorder, , )";
		
	EndIf;
	
	RequestTextForSelectionOfInitialRecords =
	"SELECT
	|	&SelectingFields
	|INTO #InitialEntries
	|FROM
	|	#RegisterTable AS Records
	|WHERE
	|	&ConditionsForRegisterSelection
	|INDEX BY
	|	&SelectingIndexes";
	
	TextOfChangeSelectionRequest =
	"SELECT
	|	&SelectingChangeTableFields
	|INTO #ChangesTable
	|FROM
	|	(SELECT
	|		&SelectingFieldsOfInitialRecords
	|	FROM
	|		#InitialEntries AS InitialEntries
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&SelectingFieldsForNewRecords
	|	FROM
	|		#RegisterTable AS Records
	|	WHERE
	|		&ConditionsForRegisterSelection) AS Table
	|
	|GROUP BY
	|	&SelectingDimensionFields";
	
	SelectingFields = New Array;
	SelectingChangeTableFields = New Array;
	SelectingFieldsOfInitialRecords = New Array;
	SelectingFieldsForNewRecords = New Array;
	SelectingDimensionFields = New Array;
	SelectingFilterFields = New Array;
	SelectionOfSelectionConditionsByRegister = New Array;
	
	TempTableName = "ChangesTable"+RegisterMetadata.Name;
	
	CollectionFields = Testing.StructureOfCollectionFields(RegisterMetadata, AdditionalParameters);
	FieldArray = New Array;
	CommonClientServer.SupplementArray(FieldArray, CollectionFields.Dimensions, True);
	CommonClientServer.SupplementArray(FieldArray, CollectionFields.Resources, True);	
	CommonClientServer.SupplementArray(FieldArray, CollectionFields.Attributes, True);
	ArrayOfResources = CollectionFields.NumericFields;
	ArrayOfIndexFields = CollectionFields.Dimensions;
	
	For Each Field In FieldArray Do
		
		FieldText = "." + Field + " AS " + Field;
		
		SelectingFields.Add("Records" + FieldText);
		SelectingChangeTableFields.Add("Table" + FieldText); 
		SelectingFieldsOfInitialRecords.Add("InitialEntries" + FieldText);
		SelectingFieldsForNewRecords.Add("Records" + FieldText);
		SelectingDimensionFields.Add("Table." + Field);
		
	EndDo;
	
	For Each Resource In ArrayOfResources Do
		
		FieldText = "." + Resource + " AS " + Resource;
		
		SelectingFields.Add("Records" + FieldText);
		SelectingChangeTableFields.Add("SUM(Table." + Resource + ") AS " + Resource); 
		SelectingFieldsOfInitialRecords.Add("InitialEntries"+FieldText);
		SelectingFieldsForNewRecords.Add("-Records"+FieldText);
		SelectingFilterFields.Add("SUM(Table." + Resource + ") <> 0");
		
	EndDo;
	
	For Each FilterElement In Filter Do
		If FilterElement.Use Then
			SelectionOfSelectionConditionsByRegister.Add("Records." + FilterElement.Name + " = " + "&" + FilterElement.Name);
			ArrayIndex = ArrayOfIndexFields.Find(FilterElement.Name);
			If ArrayIndex <> Undefined Then
				// we will remove from the indexes the field by which the selection is applied
				ArrayOfIndexFields.Delete(ArrayIndex);
			EndIf;
		EndIf;
	EndDo;
	
	If SelectionOfSelectionConditionsByRegister.Count() = 0 Then
		SelectionOfSelectionConditionsByRegister.Add("TRUE");
	EndIf;
	
	If AdditionalParameters.CheckChecksum Then
		// Let's add a checksum check (in case there are no numerical resources or they are equal to 0.
		SelectingChangeTableFields.Add("SUM(Table.Checksum) AS Checksum");
		SelectingFieldsOfInitialRecords.Add("1 AS Checksum");
		SelectingFieldsForNewRecords.Add("-1 AS Checksum");
		SelectingFilterFields.Add("SUM(Table.Checksum) <> 0");
	EndIf;
	
	FieldSelectionText = StrConcat(SelectingFields, "," + Chars.LF + Chars.Tab);
	SampleTextOfChangeTableFields = StrConcat(SelectingChangeTableFields, "," + Chars.LF + Chars.Tab);
	SampleTextForInitialRecordFields = StrConcat(SelectingFieldsOfInitialRecords, "," + Chars.LF + Chars.Tab + Chars.Tab);
	SelectionTextForNewRecordFields = StrConcat(SelectingFieldsForNewRecords, "," + Chars.LF + Chars.Tab + Chars.Tab);
	SampleTextForDimensionFields = StrConcat(SelectingDimensionFields, "," + Chars.LF + Chars.Tab);
	FilterFieldSelectionText = StrConcat(SelectingFilterFields, Chars.LF + Chars.Tab + "OR ");
	SampleTextOfIndexFields = StrConcat(ArrayOfIndexFields, "," + Chars.LF + Chars.Tab);
	
	RequestTextForSelectionOfInitialRecords = StrReplace(RequestTextForSelectionOfInitialRecords, "&SelectingFields", FieldSelectionText);
	RequestTextForSelectionOfInitialRecords = StrReplace(RequestTextForSelectionOfInitialRecords, "#RegisterTable", RegisterTable);
	RequestTextForSelectionOfInitialRecords = StrReplace(RequestTextForSelectionOfInitialRecords, "#InitialEntries", "InitialEntries"+RegisterMetadata.Name);
	If ValueIsFilled(AdditionalParameters.SelectionConditionsUpTo) Then
		RequestTextForSelectionOfInitialRecords = StrReplace(RequestTextForSelectionOfInitialRecords,
			"&ConditionsForRegisterSelection", AdditionalParameters.SelectionConditionsUpTo);
	Else
		RequestTextForSelectionOfInitialRecords = StrReplace(RequestTextForSelectionOfInitialRecords,
			"&ConditionsForRegisterSelection", StrConcat(SelectionOfSelectionConditionsByRegister, Chars.LF + Chars.Tab + "And "));
	EndIf;
	RequestTextForSelectionOfInitialRecords = StrReplace(RequestTextForSelectionOfInitialRecords, "&SelectingIndexes", SampleTextOfIndexFields);
	If ArrayOfIndexFields.Count() = 0 Then
		RequestTextForSelectionOfInitialRecords = StrReplace(RequestTextForSelectionOfInitialRecords, Chars.LF + "INDEX BY" + Chars.LF + Chars.Tab, "");
	EndIf;
	
	TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "&SelectingFieldsOfInitialRecords", SampleTextForInitialRecordFields);
	TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "&SelectingFieldsForNewRecords", SelectionTextForNewRecordFields);
	TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "&SelectingChangeTableFields", SampleTextOfChangeTableFields);
	If ValueIsFilled(AdditionalParameters.SelectionConditionsAfter) Then
		TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "&ConditionsForRegisterSelection",
			AdditionalParameters.SelectionConditionsAfter);
	Else
		TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "&ConditionsForRegisterSelection",
			StrConcat(SelectionOfSelectionConditionsByRegister, Chars.LF + Chars.Tab + Chars.Tab + "And "));
	EndIf;
	TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "#RegisterTable", RegisterTable);
	TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "#ChangesTable", TempTableName);
	TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "&SelectingDimensionFields", SampleTextForDimensionFields);
	If ValueIsFilled(FilterFieldSelectionText) Then
		TextOfChangeSelectionRequest = TextOfChangeSelectionRequest + Chars.LF + "HAVING" + Chars.LF + Chars.Tab + FilterFieldSelectionText;
	EndIf;
	
	TextOfChangeSelectionRequest = TextOfChangeSelectionRequest + Chars.LF + ";
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP #InitialEntries";
	
	TextOfChangeSelectionRequest = StrReplace(TextOfChangeSelectionRequest, "#InitialEntries", "InitialEntries"+RegisterMetadata.Name);

	Result = New Structure;
	Result.Insert("InitialDataSampleText", RequestTextForSelectionOfInitialRecords);
	Result.Insert("SampleTextOfChangeTable", TextOfChangeSelectionRequest);
	Result.Insert("TempTableName", TempTableName);
	
	Return Result;
	
EndFunction

#EndRegion

#Region PredefinedTextData

// Returns the default text for the "more Information" hyperlink.
//
// Returns:
//	String - The text "More details"
//
Function DefaultDetailsText() Export
	Return NStr("vi = 'Chi tiết hơn';
				|ru = 'Подробнее';
				|en = 'Details'; fa = 'جزئیات';
				|it = 'Dettagliatamente';
				|pl = 'Details';
				|tr = 'Ayrıntılar'");
EndFunction

// Returns the name of the log event for the custom action of the month close operation.
//
// Parameters:
//	NameAddition - String - perform action.
//
// Returns:
//	String - Event name
//
Function EventLogEventName(NameAddition) Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết chuyển cuối tháng. %1';
			|ru = 'Закрытие месяца.%1';
			|en = 'Month-end closing.%1'; fa = 'Month-end closing.%1';
			|it = 'Chiusura del mese.%1';
			|pl = 'Zamknięcie miesiąca.%1';
			|tr = 'Ay sonu kapanışı.%1'", Common.DefaultLanguageCode()),
		NameAddition);
	
EndFunction

// Returns a service symbol indicating that the exception was handled in the handler for the month closing stage.
//
// Returns:
//	String - service symbol
//
Function ServiceSymbol_ExceptionHasAlreadyBeenWorkedOutInCalculationStage() Export
	
	Return Chars.LF + "#ExceptionHasAlreadyBeenFixed" + Chars.LF;
	
EndFunction

#EndRegion

#Region SettingFunctionalLockWhenUpdatingInformationSecurity

// Checks whether the operation can be performed depending on the current state of the is update.
// If all the incoming data of the operation has not yet been processed, the operation cannot be performed.
// In this case, information about raw data is written to the log and an exception is thrown.
//
// Parameters:
//	IncomingData 		  - Map of KeyAndValue:
//							  * Key - String, MetadataObject - incoming data used by the operation
//							  * Value - AnyRef, Structure, Undefined, Array of AnyRef - Filter
//	PresentationOperation - String - custom view of the operation being performed.
//
Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity(IncomingData, PresentationOperation) Export
	
	If DoNotCheckBlockingOfIncomingDataWhenUpdatingInformationSecurity() Then
		Return;
	EndIf;
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		Return; // the IB update has been completed completely
	EndIf;
	
	SetPrivilegedMode(True);
	
	ErrorTextForException = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1: không thể thực hiện - chưa kết thúc cập nhật CSDL.
			|Chi tiết xem trong Nhật ký sự kiện.';
			|ru = '%1: выполнение невозможно - не завершено обновление ИБ.
			|Подробнее см. в Журнале регистрации.';
			|en = '%1: cannot execute - infobase update is not finished. 
			|For more information, see the event log.'; fa = '%1: cannot execute - infobase update is not finished. 
			|For more information, see the event log.';
			|it = '%1: esecuzione impossibile - non è terminato l''aggiornamento del DB.
			|Si vedano i dettagli nel Registro di registrazione.';
			|pl = '%1: wykonanie jest niemożliwe - nie jest zakończona aktualizacja BI.
			|Szczegóły zob. w Dzienniku rejestracji.';
			|tr = '%1: gerçekleştirilemiyor - Infobase güncellemesi tamamlanmadı.
			|Ayrıntılar için Kayıt Defterine bak.'"),
		PresentationOperation);
	ErrorTextForLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1: không thể thực hiện - chưa kết thúc cập nhật CSDL.
		    |Có thể thực hiện chính xác giao dịch sau khi
			|kết thúc thực hiện thành công tất cả hàm sự kiện cập nhật dữ liệu gốc đối với giao dịch này.';
			|ru = '%1: выполнение невозможно - не завершено обновление ИБ.
			|Корректное выполнение операции будет возможно после того,
			|когда будут успешно завершены все обработчики обновление исходных данных для этой операции.';
			|en = '%1: cannot execute – infobase update is not finished.
			|It will be possible to execute the operation correctly
			|when all the source data update handlers for this operation are finished successfully.'; fa = '%1: cannot execute – infobase update is not finished.
		    |It will be possible to execute the operation correctly
		    |when all the source data update handlers for this operation are finished successfully.';
			|it = '%1: esecuzione impossibile - non è terminato l''aggiornamento del DB.
			|La corretta esecuzione dell''operazione sarà possibile solo dopo che,
			|termineranno con successo tutti i trasformatori dell''aggiornamento dei dati iniziali per questa operazione.';
			|pl = '%1: wykonanie jest niemożliwe - nie jest zakończona aktualizacja BI.
			|Poprawne wykonanie operacji będzie możliwe po tym,
			|gdy będą pomyślnie zakończone wszystkie przetwarzania aktualizacja danych wyjściowych dla tej operacji.';
			|tr = '%1: gerçekleştirilemiyor - Infobase güncellemesi tamamlanmadı.
			|İşlemin doğru şekilde yürütülmesi,
			|bu işlem için kaynak verileri güncellemeye yönelik tüm işleyiciler başarıyla tamamlandıktan sonra mümkün olacaktır.'"),
		PresentationOperation);
	
	LinkSelectedData = New Array;
	FilterByRefs 			= New Array;
	UpdateHandlers   = BlockingMonthEndClosingByUpdateHandlers();
	
	DataBlocked = False;
	
	For Each DataDetails In IncomingData Do
		
		MetadataObject = DataDetails.Key;
		If TypeOf(MetadataObject) = Type("String") Then
			MetadataObject = Metadata.FindByFullName(MetadataObject);
		EndIf;
		
		BlockingHandler = UpdateHandlers.Get(MetadataObject);
		If BlockingHandler = Undefined Then
			BlockingHandler = False;
		EndIf;
		
		Filter = ?(TypeOf(DataDetails.Value) = Type("Boolean"), Undefined, DataDetails.Value);
		
		If (Metadata.InformationRegisters.Contains(MetadataObject)
		 And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent)
		 Or TypeOf(Filter) = Type("Structure") Then
			
			// We check independent registers of information one by one,
			// because there are no uniform selections for them (according to the registrar).
			// Similarly, for other types of metadata, if they are given a "complex" selection in the form of a structure.
			If BlockingHandler And InfobaseUpdate.HasDataToProcess(Undefined, MetadataObject, Filter) Then
				
				DataBlocked = True;
				
				WriteLogEvent(
					PresentationOperation,
					EventLogLevel.Error,
					MetadataObject,
					Filter,
					ErrorTextForLog);
				
			EndIf;
			
		ElsIf BlockingHandler Then

			LinkSelectedData.Add(MetadataObject.FullName());
			If TypeOf(Filter) = Type("Array") Then
				// Let's add the selection array of this metadata object to the general selection array
				CommonClientServer.SupplementArray(FilterByRefs, Filter, True);
			ElsIf Filter <> Undefined Then
				// Let's add the selection-link of this metadata object to the general array of selections
				If FilterByRefs.Find(Filter) = Undefined Then
					FilterByRefs.Add(Filter);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If LinkSelectedData.Count() > 0 Then
		
		If FilterByRefs.Count() = 0 Then
			FilterByRefs = Undefined; // without selection
		EndIf;
		
		// We will check all objects for which selection by reference /registrar is possible in one call.
		If InfobaseUpdate.HasDataToProcess(Undefined, LinkSelectedData, FilterByRefs) Then
			
			DataBlocked = True;
			
			ErrorTextForLog = ErrorTextForLog + "
				|
				|" + NStr("vi = 'Cần phải đợi cho đến khi tất cả dữ liệu của các loại sau được xử lý:';
							|ru = 'Необходимо дождаться завершения обработки всех данных следующих типов:';
							|en = 'Wait until data of the following types is processed:'; fa = 'Wait until data of the following types is processed:';
							|it = 'È necessario attendere l''elaborazione di tutti i dati dei seguenti tipi:';
							|pl = 'Należy poczekać na zakończenie przetwarzania wszystkich danych następujących typów:';
							|tr = 'Aşağıdaki türlerdeki tüm veriler işlenene kadar beklenmeli:'");
			
			For Each MetadataObjectName In LinkSelectedData Do
				// Let's list the names of metadata objects, among which there are not yet processed data.
				ErrorTextForLog = ErrorTextForLog + "
					|- " + MetadataObjectName;
			EndDo;
			
			WriteLogEvent(
				PresentationOperation,
				EventLogLevel.Error,
				,
				FilterByRefs,
				ErrorTextForLog);
			
		EndIf;
		
	EndIf;
	
	If DataBlocked Then
		// The operation cannot be performed because the update of all its incoming data has not been completed.
		Raise ErrorTextForException;
	EndIf;
	
EndProcedure

// Returns information about the importance of update handlers.
// 
// Returns:
//  Map of KeyAndValue:
//	 * Key - MetadataObject - processed metadata
//	 * Value - Boolean - the sign of blocking at the end of the month-end closing
Function BlockingMonthEndClosingByUpdateHandlers() Export
	
	Result = New Map;
	UpdateHandlers = MonthEndTransactionsCached.BlockingMonthEndClosingByUpdateHandlers();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	T.HandlerName AS HandlerName,
	|	T.ObjectsToChange AS ObjectsToChange
	|FROM
	|	InformationRegister.UpdateHandlers AS T
	|WHERE
	|	T.Status <> VALUE(Enum.UpdateHandlersStatuses.Completed)";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ItBlocksMonthEndClosing = UpdateHandlers.Get(Lower(Selection.HandlerName));
		ItBlocksMonthEndClosing = ?(ItBlocksMonthEndClosing = Undefined, False, ItBlocksMonthEndClosing);
		
		MetadataNamesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(TrimAll(Selection.ObjectsToChange), ",", True, True);
		
		For Each MetadataObjectName In MetadataNamesArray Do
			
			MetadataObject = Metadata.FindByFullName(MetadataObjectName);
			If MetadataObject = Undefined Then
				Continue;
			EndIf;
			
			Result.Insert(MetadataObject, ItBlocksMonthEndClosing);
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Update handlers that block month-end closing.
// 
// Returns:
//  String - Update Handlers Blocking Month-End Closing
Function UpdateHandlersBlockingMonthEndClosing() Export

	// Each update handler is specified on a new line, commas at the end of the line are not needed	
	Handlers = "
	|Documents.BackflushProduction.ProcessDataForMigrationToNewVersion
	|InformationRegisters.JobsForAllocatingARAP.ProcessDataForMigrationToNewVersion
	|InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.FinancialInstrumentsARAP.ProcessDataForMigrationToNewVersion
	|InformationRegisters.PerformMonthEndClosingOperations.ProcessDataForMigrationToNewVersion
	|InformationRegisters.JobsForMonthEndClosing.ProcessDataForMigrationToNewVersion
	|InformationRegisters.FinancialAccountingPolicy.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.OtherIncome.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.OtherIncome.ProcessDataToUpgradeToNewVersion_TasksByEndOfMonth
	|Catalogs.MonthEndClosingOperations.ProcessDataForMigrationToNewVersion";
	
	MonthEndTransactionsLocalization.UpdateHandlersBlockingMonthEndClosing(Handlers);
	
	Return Handlers;
	
EndFunction

// Update handlers that do not affect the month-ending closing.
// 
// Returns:
//  String - Update Handlers That Do Not Affect Month-End Closing
Function UpdateHandlersThatDoNotAffectMonthEndClosing() Export
	
	// Each update handler is specified on a new line, commas at the end of the line are not needed	
	Handlers = "
	|MonthEndTransactionsServer.ProcessDataForMigrationToNewVersion
	|Catalogs.CounterpartyContracts.ProcessDataForMigrationToNewVersion
	|Documents.DiscrepancyReportFollowingReceipt.OnAddUpdateHandlers
	|Documents.PurchaseOrder.ProcessDataForMigrationToNewVersion
	|Documents.DiscrepancyReportFollowingShipment.ProcessDataForMigrationToNewVersion
	|Documents.PurchaseAdjustment.ProcessDataForMigrationToNewVersion
	|Documents.SaleAdjustment.ProcessDataForMigrationToNewVersion
	|Catalogs.ARAPObjects.ProcessDataForMigrationToNewVersion
	|Catalogs.TypesOfPrices.ProcessDataForMigrationToNewVersion
	|Catalogs.InventoryKinds.ProcessDataForMigrationToNewVersion
	|Documents.GoodsReceiptNote.ProcessDataForMigrationToNewVersion
	|Documents.VendorInvoice.ProcessDataForMigrationToNewVersion
	|Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ProcessDataForMigrationToNewVersion
	|Documents.ReceivedTaxInvoicePrepayment.ProcessDataForMigrationToNewVersion
	|Documents.ARAPSettlement.ProcessDataForMigrationToNewVersion
	|Documents.GoodsShipmentToCustomer.ProcessDataForMigrationToNewVersion
	|Documents.ProductionStage2_2.ProcessDataForMigrationToNewVersion
	|InformationRegisters.OrderStructure.ProcessDataForMigrationToNewVersion
	|InformationRegisters.ProductionOrders.ProcessDataForMigrationToNewVersion
	|Documents.TransferOrder.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.RevenueAndCOGS.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.InventoryAndDemands.ProcessDataForMigrationToNewVersion
	|InformationRegisters.DatesOfCompanyGoodsReceipt.ProcessDataForMigrationToNewVersion
	|Documents.OrderOfMaterialsForProduction.ProcessDataForMigrationToNewVersion
	|InfobaseUpdateCA.SetConstantUseMaterialOrdersInProduction
	|InformationRegisters.IntangibleAssetsDocuments.ProcessDataForMigrationToNewVersion
	|InformationRegisters.FixedAssetsDocuments.ProcessDataForMigrationToNewVersion
	|Catalogs.BudgetBalanceItems.ProcessDataForMigrationToNewVersion
	|Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.ProcessDataForMigrationToNewVersion
	|Catalogs.BudgetFlowItems.ProcessDataForMigrationToNewVersion
	|Documents.FixedAssetsInitialRecognition2_4.ProcessDataForMigrationToNewVersion
	|Documents.FixedAssetsCostAdditions2_4.ProcessDataForMigrationToNewVersion
	|Documents.FixedAssetCostAndDepreciationAdjustment.ProcessDataForMigrationToNewVersion
	|Documents.DisposeFixedAssets2_4.ProcessDataForMigrationToNewVersion
	|
	|Documents.EngineeringChangeOrder.ProcessDataForMigrationToNewVersion
	|InformationRegisters.ItemLinksByChangeOrders.ProcessDataForMigrationToNewVersion
	|InformationRegisters.AlternativeMaterials.ProcessDataForMigrationToNewVersion
	|InformationRegisters.InventoryAllocation.ProcessDataForMigrationToNewVersion
	|InformationRegisters.PurchaseOrderStates.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.CashFlowPlansCustomers.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.CashFlowPlansVendors.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.RevenueAndCOGS.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.CustomersARAPAccounting.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.VendorsARAPAccounting.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.CustomersARAPAccountingByDueDates.ProcessDataForMigrationToNewVersion
	|AccumulationRegisters.VendorsARAPAccountingByDueDates.ProcessDataForMigrationToNewVersion
	|VATAccountingLocalization.CreateVATRateElements
	|InformationRegisters.GoodsIssueNoteReregistrationQueue.ProcessDataForMigrationToNewVersion
	|Catalogs.CCDNumbers.ProcessDataForMigrationToNewVersion
	|";
	
	MonthEndTransactionsLocalization.UpdateHandlersThatDoNotAffectMonthEndClosing(Handlers);
	
	Return Handlers;
	
EndFunction

#EndRegion

#Region SaaSOperations

// Fills in an array of undivided data types that support link matching
// when uploading data to another information database.
// 
// Parameters:
//  Types - See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.Types
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export

	Types.Add(Metadata.Catalogs.MonthEndClosingOperations);

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region BackgroundJobMethods

// The methods contained in this area are used as a parameter
// of the platform mechanism of background tasks Background tasks.Execute()

// Auxiliary method of the form of processing the operation of the month closure.
// Fills in the State of the stages in the background task.
//
// Parameters:
//   StartupParameters See  DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState
//   AdditionalParameters - Arbitrary - additional background task parameters
//
Procedure FillInStatesOfStagesInBackgroundJob(StartupParameters, AdditionalParameters = Undefined) Export
	
	DataProcessors.MonthEndClosingOperations.FillInStatesOfStages(StartupParameters);
	
EndProcedure

// Auxiliary method of the form for processing operations of the month Closure.
// Performs the calculation steps in the background.
//
Procedure CalculateStagesInBackgroundJob(StartupParameters) Export
	
	DataProcessors.MonthEndClosingOperations.PerformCalculationOfStages(StartupParameters);
	
EndProcedure

// Auxiliary method for the routine task "closing the month".
// Performs the routine task "closing the month" in the background.
// 
// Parameters:
//	JobDetails - Structure -
//	CalculationID - UUID
//
Procedure PerformMonthClosureInBackgroundJob(JobDetails, CalculationID) Export
	
	ClosingPeriods = New Array;
	If JobDetails.LastPeriodClosingStartDate <= Day(CurrentSessionDate()) Then
		ClosingPeriods.Add(AddMonth(EndOfMonth(CurrentSessionDate()), -1));
	EndIf;
	LastPeriod = BegOfDay(CurrentSessionDate());
	ClosingPeriods.Add(LastPeriod);
	
	// Consecutive closing months.
	For Each CurrentPeriod In ClosingPeriods Do
		
		If CurrentPeriod < LastPeriod Then
			CloseRA = JobDetails.CloseOperationalAccountingInPastPeriod;
			CloseCA = JobDetails.CloseLocalAccountingInPastPeriod;
			CloseIA = JobDetails.CloseFinancialAccountingInPastPeriod;
			MonthEndClosingMode = Enums.MonthEndClosingModes.FinalClosing;
		Else
			CloseRA = JobDetails.CloseOperationalAccountingInCurrentPeriod;
			CloseCA = JobDetails.CloseLocalAccountingInCurrentPeriod;
			CloseIA = False;
			MonthEndClosingMode = JobDetails.CurrentPeriodClosingMode;
		EndIf;
		
		If Not CloseRA And Not CloseCA And Not CloseIA Then
			Continue;
		EndIf;
		
		InformationRegisters.PerformMonthEndClosingOperations.UpdateFlagForStartingCalculation(
			JobDetails.Organization,
			CalculationID,
			NStr("vi = 'nhiệm vụ theo lịch trình ""Đóng tháng""';
				|ru = 'регламентное задание ""Закрытие месяца""';
				|en = 'the ""Month-end closing"" scheduled job'; fa = 'the ""Month-end closing"" scheduled job';
				|it = 'task di routine ""Chiusura del mese""';
				|pl = 'zadanie reglamentowane ""Закрытие месяца""';
				|tr = 'Zamanlanmış görev ""Ay sonu kapanışı""'"),
			CurrentPeriod);
		
		// Fill in the states of the stages.
		StructureOfData = DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState(
			CurrentPeriod,
			JobDetails.Organization,
			Undefined, // StructureOfData
			MonthEndClosingMode);
			
		AuxProperties = New Structure;
		AuxProperties.Insert("OperationalAccounting",        CloseRA);
		AuxProperties.Insert("LocalAccounting", CloseCA);
		AuxProperties.Insert("FinancialAccounting",      CloseIA);
		AuxProperties.Insert("MonthEndClosingMode",    MonthEndClosingMode);
		
		ParametersForTriggeringStateUpdates =
			DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState(StructureOfData,
			"", // The address of the storage
			Undefined, // Update only one stage
			AuxProperties);
		
		ParametersForTriggeringStateUpdates.CheckBanDate_ 	 = True;
		ParametersForTriggeringStateUpdates.UpdateListOfChecks  = True;
		ParametersForTriggeringStateUpdates.PerformChecksBeforeStage = True;
		
		DataProcessors.MonthEndClosingOperations.FillInStatesOfStages(ParametersForTriggeringStateUpdates);
		
		EventName = NStr("vi = 'Kết chuyển cuối tháng';
						|ru = 'Закрытие месяца';
						|en = 'Month-end closing'; fa = 'بستن پایان ماه';
						|it = 'Chiusura del mese';
						|pl = 'Zamknięcie miesiąca';
						|tr = 'Ay sonu kapanışı'", Common.DefaultLanguageCode());
		
		If StructureOfData.ChangesAreDisabled Then
			
			If ValueIsFilled(JobDetails.Organization) Then
				
				ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa thực hiện nhiệm vụ thường kỳ kết chuyển đóng tháng %1 theo doanh nghiệp %2.';
						|ru = 'Регламентное задание закрытия месяца %1 по организации %2 не выполнялось.';
						|en = 'The %1 scheduled job of month-end closing by the %2 company has not been executed.'; fa = 'The %1 scheduled job of month-end closing by the %2 company has not been executed.';
						|it = 'Регламентное задание закрытия месяца %1 по организации %2 не выполнялось.';
						|pl = 'The %1 scheduled job of month-end closing by the %2 company has not been executed.';
						|tr = '%2 ay sonu kapanış zamanlanmış görevi %1 işlemi yürütülmedi.'", Common.DefaultLanguageCode()),
					MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(CurrentPeriod),
					TrimAll(JobDetails.Organization));
				
			Else
				
				ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa thực hiện nhiệm vụ thường kỳ kết chuyển đóng tháng %1 theo doanh nghiệp %2.';
						|ru = 'Регламентное задание закрытия месяца %1 по организациям %2 не выполнялось.';
						|en = 'The %1 scheduled job of month-end closing by the %2 companies has not been executed.'; fa = 'The %1 scheduled job of month-end closing by the %2 companies has not been executed.';
						|it = 'Регламентное задание закрытия месяца %1 по организациям %2 не выполнялось.';
						|pl = 'The %1 scheduled job of month-end closing by the %2 companies has not been executed.';
						|tr = '%2 ay sonu kapanış zamanlanmış görevi %1 işlemi yürütülmedi.'", Common.DefaultLanguageCode()),
					MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(CurrentPeriod),
					CostCalculationAppliedAlgorithms.CalculatedCompanies(StructureOfData.CalculationParameters.CompanyArray, ","));
				
			EndIf;
			
			ProtocolText_ = ProtocolText_ + Chars.LF + StructureOfData.ExplanationsToChangeClosing;
			 
			WriteLogEvent(
			 	EventName
				,
				EventLogLevel.Error,
				Metadata.ScheduledJobs.MonthEndTransactions,
				,
				ProtocolText_);
			
			Continue;
			
		ElsIf ValueIsFilled(StructureOfData.BlockedBusinesses) Then
			
			ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhiệm vụ thường kỳ kết chuyển đóng tháng %1 chưa được thực hiện theo các doanh nghiệp bị phong tỏa: %2';
					|ru = 'Регламентное задание закрытия месяца %1 не выполнялось по заблокированным организациям: %2';
					|en = 'The %1 scheduled job of month-end closing has not been executed by the locked companies: %2'; fa = 'The %1 scheduled job of month-end closing has not been executed by the locked companies: %2';
					|it = 'Регламентное задание закрытия месяца %1 не выполнялось по заблокированным организациям: %2';
					|pl = 'The %1 scheduled job of month-end closing has not been executed by the locked companies: %2';
					|tr = 'Ay sonu kapanışının zamanlanmış görevi %1, kilitlenen hesaplar için yürütülmedi: %2'", Common.DefaultLanguageCode()),
				MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(CurrentPeriod),
				CostCalculationAppliedAlgorithms.CalculatedCompanies(StructureOfData.BlockedBusinesses, ","));
			
			 WriteLogEvent(
			 	EventName
				,
				EventLogLevel.Warning,
				Metadata.ScheduledJobs.MonthEndTransactions,
				,
				ProtocolText_);
				
		EndIf;
		
		// We will perform all the steps sequentially.
		For Each CurrentRow In StructureOfData.TableStages Do
			
			If CurrentRow.PerformedManually Then
				Continue;
			EndIf;
			
			If MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing
			 And Not CurrentRow.PerformedAtPreliminaryClosingOfMonth Then
				Continue;
			EndIf;
			
			If (Not CloseRA And CurrentRow.OperationalAccounting)
			 Or (Not CloseCA And CurrentRow.LocalAccounting)
			 Or (Not CloseIA And CurrentRow.FinancialAccounting) Then
				Continue;
			EndIf;
			
			CalculationStartParameters = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersForCalculatingStages(
				StructureOfData,
				CurrentRow.Code,
				StructureOfData.TableStages[StructureOfData.TableStages.Count()-1].Code,
				MonthEndClosingMode);
			
			DataProcessors.MonthEndClosingOperations.PerformCalculationOfStages(CalculationStartParameters);
			
		EndDo;
		
	EndDo;
	
	InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	
EndProcedure

Procedure UpdateStateOfMonthSClosing() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.UpdateMonthEndClosingState);
	
	LastMonth = BegOfMonth(AddMonth(CurrentSessionDate(), -1));
	StartUpdatingStateOfMonthSClosing(LastMonth);
	
	CurrentMonth = BegOfMonth(CurrentSessionDate());
	StartUpdatingStateOfMonthSClosing(CurrentMonth);
	
EndProcedure

Procedure StartUpdatingStateOfMonthSClosing(Period)
	
	CompanyDescription
		= DataProcessors.MonthEndClosingOperations.DescriptionOfOrganizationsToCalculate(Period, True);
		
	AvailableCompanies = CompanyDescription.AvailableCompanies;
	
	StructureOfData = DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState(
		Period, New Array(AvailableCompanies),, Enums.MonthEndClosingModes.FinalClosing);
		
	ParametersForTriggeringStateUpdates =
		DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState(StructureOfData);
	
	ParametersForTriggeringStateUpdates.CheckBanDate_ 			  = True;
	ParametersForTriggeringStateUpdates.CleanUnusedJobEntries= True;
	ParametersForTriggeringStateUpdates.UpdateScheduledTaskCaches  = True;
	ParametersForTriggeringStateUpdates.PerformChecksBeforeStage 		  = True;
	ParametersForTriggeringStateUpdates.CreateDescriptionOfOrganizations	  = False;
	ParametersForTriggeringStateUpdates.UpdateCacheOfStatusesOfOperations = True;
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Cập nhật trạng thái kết chuyển cuối tháng %1';
			|ru = 'Обновление состояния операций закрытия месяца %1';
			|en = 'Update month-end closing operation state %1'; fa = 'Update month-end closing operation state %1';
			|it = 'Update month-end closing operation state %1';
			|pl = 'Update month-end closing operation state %1';
			|tr = '%1 ay sonu kapama işlemlerinin durumunun güncellenmesi'"),
		CostCalculationProtocol.PresentationOfCalculationPeriod(Period));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters();
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 1;
	
	TimeConsumingOperations.ExecuteInBackground(
		"MonthEndTransactionsServer.FillInStatesOfStagesInBackgroundJob",
		ParametersForTriggeringStateUpdates,
		ExecutionParameters);
	
EndProcedure

#EndRegion

#Region ScheduledJobsHandlers

// Method of the routine task "calculation of course Differences".
//
Procedure PerformReevaluation() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ExchangeDifferenceCalculation);
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Return;
	EndIf;
	
	Documents.ExchangeDifferenceCalculation.PerformReevaluation(CurrentSessionDate());
	
EndProcedure

// Method of the routine task "closing the month".
//
Procedure PerformMonthClosure(Organization = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.MonthEndTransactions);
	
	DataProcessors.MonthEndClosingOperations.CheckBlockingIncomingDataWhenUpdatingInformationSecurity();
	
	JobDetails = InformationRegisters.ScheduledJobsOfMonthEndClosing.GetRoutineTaskForOrganization(Organization);
	
	If Not JobDetails.SettingExists Then
		Raise NStr("vi = 'Lịch trình kết chuyển cuối tháng chưa được thiết lập.';
					|ru = 'Не задана настройка регламентного задания закрытия месяца.';
					|en = 'Setting of scheduled jobs of month-end closing is not configured.'; fa = 'Setting of scheduled jobs of month-end closing is not configured.';
					|it = 'L''impostazione del task pianificato di chiusura del mese non è impostata.';
					|pl = 'Nie określono ustawienie zadania reglamentowanego zamknięcia miesiąca.';
					|tr = 'Ay sonu kapanışının zamanlanmış görevi için ayar yapılmadı.'");
	EndIf;
	
	// Let's check the possibility of starting the calculation.
	InformationRegisters.PerformMonthEndClosingOperations.UpdateStateOfActiveCalculations();
	
	CalculationID = New UUID; // it is written to the key of the background job and to the register of operations
	
	If JobDetails.LastPeriodClosingStartDate <= Day(CurrentSessionDate())
	 And (JobDetails.CloseOperationalAccountingInPastPeriod
	 Or JobDetails.CloseLocalAccountingInPastPeriod
	 Or JobDetails.CloseFinancialAccountingInPastPeriod) Then
		FirstPeriod = AddMonth(BegOfMonth(CurrentSessionDate()), -1);
	Else
		FirstPeriod = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.SetFlagForStartingCalculation(
		JobDetails.Organization,
		CalculationID,
		NStr("vi = 'nhiệm vụ theo lịch trình ""Đóng tháng""';
			|ru = 'регламентное задание ""Закрытие месяца""';
			|en = 'the ""Month-end closing"" scheduled job'; fa = 'the ""Month-end closing"" scheduled job';
			|it = 'task di routine ""Chiusura del mese""';
			|pl = 'zadanie reglamentowane ""Закрытие месяца""';
			|tr = 'Zamanlanmış görev ""Ay sonu kapanışı""'"),
		FirstPeriod);
	
	If ActiveCalculations.ThereAreActiveCalculations Then
		Raise ActiveCalculations.ErrorText;
	EndIf;
	
	JobDetails.Delete("Job");
	JobDetails.Delete("JobState");
	
	// Let's run the calculation in the background task.
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(JobDetails);
	ExportProcedureParameters.Add(CalculationID);
	
	BackgroundJobs.Execute(
		"MonthEndTransactionsServer.PerformMonthClosureInBackgroundJob",
		ExportProcedureParameters,
		NameOfBackgroundJob(CalculationID),
		NStr("vi = 'Nhiệm vụ theo lịch trình Đóng tháng';
			|ru = 'Регламентное задание закрытия месяца';
			|en = 'Scheduled job of month-end closing'; fa = 'Scheduled job of month-end closing';
			|it = 'Task di routine di chiusura del mese';
			|pl = 'Zadanie reglamentowane zamknięcia miesiąca';
			|tr = 'Ay sonu kapanışının zamanlanmış görevi'"));
	
EndProcedure

#EndRegion

#Region EventsSubscriptionsHandlers

// Called from a subscription to events before recording the relevant currency courses.
//
// Parameters:
//	RelativeExchangeRates - InformationRegisterRecordSet.RelativeExchangeRates - recordable set
//	RegisterRecords   - RegisterRecordsCollection - Collection of the current logger's movement.
//	Cancel 	   - Boolean - indicates that the document was rejected.
//
Procedure ReadCurrencyRatesBeforeRecording(RelativeExchangeRates, RegisterRecords, Cancel) Export
	
	// Checking for fraud.Loading is excluded on purpose, since this mechanism works
	// out when receiving data in the RIB.
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ExRates.Period    AS Period,
	|	ExRates.Currency    AS Currency,
	|	ExRates.BaseCurrency AS BaseCurrency,
	|	ExRates.CourseNumerator AS CourseNumerator,
	|	ExRates.CourseDenominator AS CourseDenominator
	|INTO RelativeExchangeRatesBeforeWrite
	|FROM
	|	InformationRegister.RelativeExchangeRates AS ExRates
	|WHERE
	|	ExRates.Period = &Period";
	
	RelativeExchangeRates.AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
	
	Query.TempTablesManager = RelativeExchangeRates.AdditionalProperties.TempTablesManager;
	Query.SetParameter("Period", RelativeExchangeRates.Filter.Period.Value);
	
	Query.Execute();
	
EndProcedure

// Called from a subscription to the event verifiedneeds of re-Evaluation.
// If the exchange rates are changed, it is necessary to revalue monetary and foreign currency funds, and recalculate mutual settlements.
//
// Parameters:
//	RelativeExchangeRates - InformationRegisterRecordSet.RelativeExchangeRates - recordable set
//	RegisterRecords   - RegisterRecordsCollection - Collection of the current logger's movement.
//	Cancel 	   - Boolean - indicates that the document was rejected.
//
Procedure CheckWhetherRevaluationIsRequired(RelativeExchangeRates, RegisterRecords, Cancel) Export
	
	// Checking for fraud.The download is not performed because this mechanism works when receiving data in the RIB.
	
	// Checking for a set record when updating the information base
	If RelativeExchangeRates.AdditionalProperties.Property("RecordingWhenUpdatingInformationBase") Then
		Return;
	EndIf;

	SetPrivilegedMode(True);
	
	If TMDataExchange.IsSubordinateDIBNode() Then
		Return;
	EndIf;
	
	Query = New Query;
	
	Query.TempTablesManager = RelativeExchangeRates.AdditionalProperties.TempTablesManager;
	
	Query.SetParameter("Period", RelativeExchangeRates.Filter.Period.Value);
	Query.SetParameter("Currency", RelativeExchangeRates.Filter.Currency.Value);
	
	Query.Text =
	"SELECT DISTINCT
	|	Cash.Organization AS Organization,
	|	Cash.BankAccount.CashCurrency AS Currency
	|INTO CurrencyInRegisters
	|FROM
	|	AccumulationRegister.BankAccountCash AS Cash
	|WHERE
	|	Cash.BankAccount.CashCurrency = &Currency
	|	AND Cash.Period >= &Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Cash.Organization AS Organization,
	|	Cash.CashAccount.CashCurrency AS Currency
	|FROM
	|	AccumulationRegister.CashAccountBalance AS Cash
	|WHERE
	|	Cash.CashAccount.CashCurrency = &Currency
	|	AND Cash.Period >= &Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Cash.Organization AS Organization,
	|	Cash.CashRegister.CashCurrency AS Currency
	|FROM
	|	AccumulationRegister.CashInCashRegistersCR AS Cash
	|WHERE
	|	Cash.CashRegister.CashCurrency = &Currency
	|	AND Cash.Period >= &Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Cash.Organization AS Organization,
	|	Cash.Currency AS Currency
	|FROM
	|	AccumulationRegister.CashInTransit AS Cash
	|WHERE
	|	Cash.Currency = &Currency
	|	AND Cash.Period >= &Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Cash.Organization AS Organization,
	|	Cash.Currency AS Currency
	|FROM
	|	AccumulationRegister.AdvanceHolderCash AS Cash
	|WHERE
	|	Cash.Currency = &Currency
	|	AND Cash.Period >= &Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	LoansDepositsLoansLeases.AccountingDimensionByPartners.Organization AS Organization,
	|	LoansDepositsLoansLeases.Currency AS Currency
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS LoansDepositsLoansLeases
	|WHERE
	|	LoansDepositsLoansLeases.Currency = &Currency
	|	AND LoansDepositsLoansLeases.Period >= &Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BEGINOFPERIOD(T.Period, MONTH) AS Month,
	|	T.Currency AS Currency,
	|	T.BaseCurrency AS BaseCurrency
	|INTO TTChangedCourses
	|FROM
	|	(SELECT
	|		T.Period AS Period,
	|		T.Currency AS Currency,
	|		T.BaseCurrency AS BaseCurrency
	|	FROM
	|		(SELECT
	|			T.Period AS Period,
	|			T.Currency AS Currency,
	|			T.BaseCurrency AS BaseCurrency,
	|			T.CourseNumerator AS CourseNumerator,
	|			T.CourseDenominator AS CourseDenominator
	|		FROM
	|			InformationRegister.RelativeExchangeRates AS T
	|		WHERE
	|			T.Period = &Period
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			T.Period,
	|			T.Currency,
	|			T.BaseCurrency,
	|			-T.CourseNumerator,
	|			-T.CourseDenominator
	|		FROM
	|			RelativeExchangeRatesBeforeWrite AS T) AS T
	|	
	|	GROUP BY
	|		T.Period,
	|		T.Currency,
	|		T.BaseCurrency
	|	
	|	HAVING
	|		(SUM(T.CourseNumerator) <> 0
	|			OR SUM(T.CourseDenominator) <> 0)) AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTChangedCourses.Month AS Month
	|FROM
	|	TTChangedCourses AS TTChangedCourses
	|	INNER JOIN CurrencyInRegisters
	|	ON TTChangedCourses.Currency = CurrencyInRegisters.Currency";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return; // the courses have not changed.
	EndIf;
	
	// We will create tasks by the end of the month.
	Query.SetParameter("CompanyArray", Catalogs.Companies.AvailableCompanies());
	
	Query.Text =
	"SELECT DISTINCT
	|	Companies.Ref AS Ref,
	|	Companies.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	MIN(BEGINOFPERIOD(Policies.Period, MONTH)) AS StartAccounting
	|INTO TTOrganizations
	|FROM
	|	Catalog.Companies AS Companies
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS Policies
	|		ON (Policies.Organization = Companies.ParentCompany)
	|		INNER JOIN CurrencyInRegisters AS CurrencyInRegisters
	|		ON Companies.Ref = CurrencyInRegisters.Organization
	|WHERE
	|	Companies.Ref IN(&CompanyArray)
	|
	|GROUP BY
	|	Companies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Companies.Ref AS Organization,
	|	ModifiedCourses.Month AS Month,
	|	ModifiedCourses.Currency AS Currency
	|INTO ttChanges
	|FROM
	|	TTOrganizations AS Companies
	|		INNER JOIN TTChangedCourses AS ModifiedCourses
	|		ON Companies.StartAccounting <= ModifiedCourses.Month
	|			AND Companies.LocalAccountingCurrency = ModifiedCourses.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Month AS Month,
	|	T.Organization AS Organization,
	|	VALUE(Catalog.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments) AS Operation
	|FROM
	|	ttChanges AS T
	|
	|ORDER BY
	|	Month,
	|	Organization";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return; // there is no data for the formation of tasks for calculation
	EndIf;
	
	Selection = QueryResult.Select();
	
	Try
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.JobsForMonthEndClosing");
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("Month",       "Month");
		LockItem.UseFromDataSource("Operation",    "Operation");
		LockItem.UseFromDataSource("Organization", "Organization");
		Block.Lock(); 
		
		InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntriesBasedOnSampleData(Selection);
		
	Except
		
		MessageText = StrTemplate(NStr("vi = 'Không thể tạo nhiệm vụ kết chuyển cuối tháng do nguyên nhân: %1';
										|ru = 'Не удалось создать задания к закрытию месяца по причине: %1';
										|en = 'Cannot create jobs for month-end closing due to: %1'; fa = 'Cannot create jobs for month-end closing due to: %1';
										|it = 'Non è stato possibile creare i compiti alla chiusura del mese a causa di: %1';
										|pl = 'Nie udało się utworzyć zadania do zamknięcia miesiąca z powodu: %1';
										|tr = 'Ay sonu kapanışı şu nedenle oluşturulamadı: %1'"),
					DetailErrorDescription(ErrorInfo()));
			
		WriteLogEvent(
				NStr("vi = 'Kiểm tra việc cần thiết đánh giá lại tiền mặt và ngoại tệ';
					|ru = 'Проверка необходимости переоценки денежных и валютных средств.';
					|en = 'Check whether cash and currency revaluation is required.'; fa = 'Check whether cash and currency revaluation is required.';
					|it = 'Verifica della necessità di rivalutazione di contanti e altra valuta.';
					|pl = 'Sprawdzenie konieczności przeszacowania środków pieniężnych i walutowych.';
					|tr = 'Nakit ve döviz yeniden değerleme ihtiyacının kontrol edilmesi.'", Common.DefaultLanguageCode()), 
				EventLogLevel.Error, , , MessageText);
				
		Raise MessageText;
	EndTry;
	
	// Let's create tasks for the distribution of calculations.
	If Not Constants.NewOnlineARAPAccounting.Get() Then
	Query.Text =
	"SELECT DISTINCT
	|	T.Month AS Month,
	|	T.Currency AS Currency
	|FROM
	|	ttChanges AS T
	|
	|ORDER BY
	|	Month";
	
	Selection = Query.Execute().Select();
	
	Query.Text =
	"SELECT DISTINCT
	|	""JobsForAllocatingCustomersARAP""      AS TaskRegisterName,
	|	Customers.AccountingDimensionByPartners                AS AccountingDimensionByPartners,
	|	Customers.AccountingDimensionByPartners.Organization    AS Organization,
	|	Customers.ARAPObject                           AS ARAPObject,
	|	&BegOfMonth                                    AS Month
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Customers
	|WHERE
	|	Customers.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND Customers.Currency = &Currency
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""JobsForAllocatingVendorsARAP""      AS TaskRegisterName,
	|	Vendors.AccountingDimensionByPartners                AS AccountingDimensionByPartners,
	|	Vendors.AccountingDimensionByPartners.Organization    AS Organization,
	|	Vendors.ARAPObject                           AS ARAPObject,
	|	&BegOfMonth                                       AS Month
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Vendors
	|WHERE
	|	Vendors.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND Vendors.Currency = &Currency";
	
	While Selection.Next() Do
		
		Query.SetParameter("Currency", 	  Selection.Currency);
		Query.SetParameter("BegOfMonth", BegOfMonth(Selection.Month));
		Query.SetParameter("EndOfMonth",  EndOfMonth(Selection.Month));
		
		SampleCalculations = Query.Execute().Select();
		
		While SampleCalculations.Next() Do
			Jobs = InformationRegisters[SampleCalculations.TaskRegisterName].CreateRecordManager(); // InformationRegisterRecordManager.JobsForAllocatingCustomersARAP, InformationRegisterRecordManager.JobsForAllocatingVendorsARAP  
			FillPropertyValues(Jobs, SampleCalculations);
			Jobs.JobNumber = InformationRegisters[SampleCalculations.TaskRegisterName].GetTaskNumber();
			Jobs.Write();
		EndDo;
		
	EndDo;
	EndIf;
	
EndProcedure

// Called from a subscription to the "clear taskreaddocument" event.
// The "Document" dimension is cleared by the "Tasks..." registers,
// where the document being deleted is used in the current records.
//
// Parameters:
//  Source - DocumentObject - the document being deleted.
//	Cancel 	 - Boolean - Indicates whether the object deletion should be interrupted.
//
Procedure ClearJobsBeforeDeletingADocument(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	
	Query = New Query("
	|SELECT
	|	Jobs.RegisterName               AS RegisterName,
	|	Jobs.Month                     AS Month,
	|	Jobs.JobNumber              AS JobNumber,
	|	Jobs.Document                  AS Document,
	|	Jobs.Operation                  AS Operation,
	|	Jobs.Organization               AS Organization,
	|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Jobs.ARAPObject            AS ARAPObject,
	|	Jobs.PackageNumber               AS PackageNumber,
	|	Jobs.AccountingObject               AS AccountingObject,
	|	Jobs.FixedAsset          AS FixedAsset,
	|	Jobs.Skip                AS SkipWhenRecording
	|FROM
	|	(SELECT DISTINCT
	|		""JobsForCalculatingCost"" AS RegisterName,
	|		
	|		Jobs.Month        AS Month,
	|		Jobs.JobNumber AS JobNumber,
	|		UNDEFINED         AS Document,
	|		UNDEFINED         AS Operation,
	|		Jobs.Organization  AS Organization,
	|		UNDEFINED         AS AccountingDimensionByPartners,
	|		UNDEFINED         AS ARAPObject,
	|		UNDEFINED         AS PackageNumber,
	|		UNDEFINED         AS AccountingObject,
	|		UNDEFINED         AS FixedAsset,
	|		CASE WHEN NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END AS            Skip
	|	FROM
	|		InformationRegister.JobsForCalculatingCost AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForCalculatingCost AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND Jobs.Organization = Duplicates.Organization
	|			AND UNDEFINED = Duplicates.Document
	|	WHERE
	|		Jobs.Document = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""JobsForMonthEndClosing"" AS RegisterName,
	|		
	|		Jobs.Month        AS Month,
	|		Jobs.JobNumber AS JobNumber,
	|		UNDEFINED         AS Document,
	|		Jobs.Operation     AS Operation,
	|		Jobs.Organization  AS Organization,
	|		UNDEFINED         AS AccountingDimensionByPartners,
	|		UNDEFINED         AS ARAPObject,
	|		UNDEFINED         AS PackageNumber,
	|		UNDEFINED         AS AccountingObject,
	|		UNDEFINED         AS FixedAsset,
	|		CASE WHEN NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END AS            Skip
	|	FROM
	|		InformationRegister.JobsForMonthEndClosing AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForMonthEndClosing AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND UNDEFINED = Duplicates.Document
	|			AND Jobs.Operation = Duplicates.Operation
	|			AND Jobs.Organization = Duplicates.Organization
	|	WHERE
	|		Jobs.Document = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""JobsForAllocatingCustomersARAP"" AS RegisterName,
	|		
	|		Jobs.Month                     AS Month,
	|		Jobs.JobNumber              AS JobNumber,
	|		UNDEFINED                      AS Document,
	|		UNDEFINED                      AS Operation,
	|		Jobs.Organization              AS Organization,
	|		Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Jobs.ARAPObject            AS ARAPObject,
	|		UNDEFINED                      AS PackageNumber,
	|		UNDEFINED                      AS AccountingObject,
	|		UNDEFINED                      AS FixedAsset,
	|		CASE WHEN Jobs.ARAPObject = &Ref OR NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END                             AS Skip
	|	FROM
	|		InformationRegister.JobsForAllocatingCustomersARAP AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForAllocatingCustomersARAP AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND UNDEFINED = Duplicates.Document
	|			AND Jobs.AccountingDimensionByPartners = Duplicates.AccountingDimensionByPartners
	|			AND Jobs.Organization = Duplicates.Organization
	|			AND Jobs.ARAPObject = Duplicates.ARAPObject
	|	WHERE
	|		Jobs.Document = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""JobsForAllocatingVendorsARAP"" AS RegisterName,
	|		
	|		Jobs.Month                     AS Month,
	|		Jobs.JobNumber              AS JobNumber,
	|		UNDEFINED                      AS Document,
	|		UNDEFINED                      AS Operation,
	|		Jobs.Organization               AS Organization,
	|		Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Jobs.ARAPObject            AS ARAPObject,
	|		UNDEFINED                      AS PackageNumber,
	|		UNDEFINED                      AS AccountingObject,
	|		UNDEFINED                      AS FixedAsset,
	|		CASE WHEN Jobs.ARAPObject = &Ref OR NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END                             AS Skip
	|	FROM
	|		InformationRegister.JobsForAllocatingVendorsARAP AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForAllocatingVendorsARAP AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND UNDEFINED = Duplicates.Document
	|			AND Jobs.AccountingDimensionByPartners = Duplicates.AccountingDimensionByPartners
	|			AND Jobs.Organization = Duplicates.Organization
	|			AND Jobs.ARAPObject = Duplicates.ARAPObject
	|	WHERE
	|		Jobs.Document = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""JobsForCalculatingFixedAssetDepreciation"" AS RegisterName,
	|		
	|		Jobs.Month                     AS Month,
	|		Jobs.JobNumber              AS JobNumber,
	|		UNDEFINED                      AS Document,
	|		UNDEFINED                      AS Operation,
	|		Jobs.Organization               AS Organization,
	|		UNDEFINED                      AS AccountingDimensionByPartners,
	|		UNDEFINED                      AS ARAPObject,
	|		Jobs.PackageNumber               AS PackageNumber,
	|		UNDEFINED                      AS AccountingObject,
	|		UNDEFINED                      AS FixedAsset,
	|		CASE WHEN NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END                             AS Skip
	|	FROM
	|		InformationRegister.JobsForCalculatingFixedAssetDepreciation AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForCalculatingFixedAssetDepreciation AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND UNDEFINED = Duplicates.Document
	|			AND Jobs.PackageNumber = Duplicates.PackageNumber
	|			AND Jobs.Organization = Duplicates.Organization
	|	WHERE
	|		Jobs.Document = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""JobsForCalculatingIntangibleAssetAmortization"" AS RegisterName,
	|		
	|		Jobs.Month                     AS Month,
	|		Jobs.JobNumber              AS JobNumber,
	|		UNDEFINED                      AS Document,
	|		UNDEFINED                      AS Operation,
	|		Jobs.Organization               AS Organization,
	|		UNDEFINED                      AS AccountingDimensionByPartners,
	|		UNDEFINED                      AS ARAPObject,
	|		Jobs.PackageNumber               AS PackageNumber,
	|		UNDEFINED                      AS AccountingObject,
	|		UNDEFINED                      AS FixedAsset,
	|		CASE WHEN NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END                             AS Skip
	|	FROM
	|		InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND UNDEFINED = Duplicates.Document
	|			AND Jobs.PackageNumber = Duplicates.PackageNumber
	|			AND Jobs.Organization = Duplicates.Organization
	|	WHERE
	|		Jobs.Document = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""JobsForCalculatingNonCurrentAssetCost"" AS RegisterName,
	|		
	|		Jobs.Month                     AS Month,
	|		Jobs.JobNumber              AS JobNumber,
	|		UNDEFINED                      AS Document,
	|		UNDEFINED                      AS Operation,
	|		Jobs.Organization               AS Organization,
	|		UNDEFINED                      AS AccountingDimensionByPartners,
	|		UNDEFINED                      AS ARAPObject,
	|		UNDEFINED                      AS PackageNumber,
	|		Jobs.AccountingObject               AS AccountingObject,
	|		UNDEFINED                      AS FixedAsset,
	|		CASE WHEN NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END                             AS Skip
	|	FROM
	|		InformationRegister.JobsForCalculatingNonCurrentAssetCost AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForCalculatingNonCurrentAssetCost AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND UNDEFINED = Duplicates.Document
	|			AND Jobs.AccountingObject = Duplicates.AccountingObject
	|			AND Jobs.Organization = Duplicates.Organization
	|	WHERE
	|		Jobs.Document = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""JobsForGeneratingFixedAssetRecords"" AS RegisterName,
	|		
	|		Jobs.Month                     AS Month,
	|		Jobs.JobNumber              AS JobNumber,
	|		UNDEFINED                      AS Document,
	|		UNDEFINED                      AS Operation,
	|		Jobs.Organization               AS Organization,
	|		UNDEFINED                      AS AccountingDimensionByPartners,
	|		UNDEFINED                      AS ARAPObject,
	|		UNDEFINED                      AS PackageNumber,
	|		Jobs.AccountingObject               AS AccountingObject,
	|		UNDEFINED                      AS FixedAsset,
	|		CASE WHEN NOT Duplicates.Document IS NULL
	|			THEN TRUE
	|			ELSE FALSE
	|		END                             AS Skip
	|	FROM
	|		InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
	|
	|		LEFT JOIN InformationRegister.JobsForGeneratingFixedAssetRecords AS Duplicates
	|		ON Jobs.Month = Duplicates.Month
	|			AND Jobs.JobNumber = Duplicates.JobNumber
	|			AND UNDEFINED = Duplicates.Document
	|			AND Jobs.AccountingObject = Duplicates.AccountingObject
	|			AND Jobs.Organization = Duplicates.Organization
	|	WHERE
	|		Jobs.Document = &Ref
	|	) AS Jobs
	|TOTALS BY
	|	Jobs.RegisterName
	|");
	
	Query.SetParameter("Ref", Source.Ref);
	TaskSelection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While TaskSelection.Next() Do
		CleaningTasks = InformationRegisters[TaskSelection.RegisterName].CreateRecordSet(); // InformationRegisterRecordSet.JobsForMonthEndClosing
		CleaningTasks.Filter.Document.Set(Source.Ref);
		InfobaseUpdate.WriteRecordSet(CleaningTasks, True);
		
		TasksToRecord = InformationRegisters[TaskSelection.RegisterName].CreateRecordSet();
		RecordsSelection = TaskSelection.Select();
		While RecordsSelection.Next() Do 
			If Not RecordsSelection.SkipWhenRecording Then
				BackToRecording = TasksToRecord.Add();
				FillPropertyValues(BackToRecording, RecordsSelection);
			EndIf;
		EndDo;
		Try
			If TasksToRecord.Count() <> 0 Then
				InfobaseUpdate.WriteRecordSet(TasksToRecord, False);
			EndIf;
		Except
			Cancel = True;
			WriteLogEvent(
				NStr("vi = 'Xóa bỏ các đối tượng có đánh dấu';
					|ru = 'Удаление помеченных объектов';
					|en = 'Deletion of marked objects'; fa = 'Deletion of marked objects';
					|it = 'Eliminazione degli oggetti selezionati';
					|pl = 'Usuwanie zaznaczonych obiektów';
					|tr = 'İşaretli nesnelerin silinmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				Metadata.CommonModules.MonthEndTransactionsServer,
				,
				DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	
EndProcedure

// Tasks for the end of the month before recording.
// 
// Parameters:
//  Source - InformationRegisterRecordSet.JobsForCalculatingCost, InformationRegisterRecordSet.JobsForMonthEndClosing, InformationRegisterRecordSet.JobsForCalculatingFixedAssetDepreciation, InformationRegisterRecordSet.JobsForCalculatingNonCurrentAssetCost, InformationRegisterRecordSet.JobsForAllocatingCustomersARAP, InformationRegisterRecordSet.JobsForGeneratingFixedAssetRecords, InformationRegisterRecordSet.JobsForAllocatingVendorsARAP, InformationRegisterRecordSet.DocumentPostingInFinancialAccounting, InformationRegisterRecordSet.JobsForGeneratingVATRecords, InformationRegisterRecordSet.JobsForCalculatingIntangibleAssetAmortization - Source
//  Cancel - Boolean - Cancel
//  Replacing - Boolean - Replacing
Procedure JobsForMonthEndClosingBeforeWrite(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load And Not Source.AdditionalProperties.Property("IsDIBExchange1") Then
		// If the task came by the end of the month for the exchange of RIB, then it must be checked for entry into the blocked period
		Return;
	EndIf;

	If Not InformationRegisters.SetUpLockFromChanges.UseMechanismToBlockChanges()
	 Or Not CheckingPeriodLockForSetOfRecords(Source) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	RegisterName = "";
	OldSourceFieldValues = New ValueTable;
	
	If False Then
	ElsIf TypeOf(Source) = Type("InformationRegisterRecordSet.DocumentPostingInFinancialAccounting") Then
		RegisterName = "InformationRegister.DocumentPostingInFinancialAccounting";
	EndIf;
	
	If ValueIsFilled(RegisterName) Then
		
		Recorder = Source.Filter.Recorder.Value;
		
		If TypeOf(Recorder) = Type("DocumentRef.InventoryCostCalculation")
		 And ValueIsFilled(Common.ObjectAttributeValue(Recorder, "EntryType"))
		 And ValueIsFilled(RegisterName) Then
			// This is a service cost calculation document with Registered Records of data conversion, according to which it is possible to be reflected in accounting in the blocked period.
			Return;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(RegisterName) Then
		
		Query = New Query;
		
		Query.Text =
		"SELECT
		|	T.Organization AS Organization,
		|	T.DateRecord AS DateRecord,
		|	T.Status AS Status
		|FROM
		|	RegisterName AS T
		|WHERE
		|	T.Recorder = &Recorder";
		
		Query.Text = StrReplace(Query.Text, "RegisterName", RegisterName);
		
		Query.SetParameter("Recorder", Recorder);
		
		OldSourceFieldValues = Query.Execute().Unload();
		
	EndIf;
	If Source.Metadata().Dimensions.Find("Month") <> Undefined Then
		FieldNamePeriod = "Month";
	Else
		FieldNamePeriod = "DateRecord";
	EndIf;
	
	FieldsNames = FieldNamePeriod + "," + "Organization";
	
	TaskTable = Source.Unload(, FieldsNames);
	TaskTableByMonth = Source.Unload(, FieldsNames);
	For Each CurrRow In OldSourceFieldValues Do
		FillPropertyValues(TaskTable.Add(), CurrRow);
		FillPropertyValues(TaskTableByMonth.Add(), CurrRow);
	EndDo;
	For Each CurrRow In TaskTableByMonth Do
		CurrRow[FieldNamePeriod] = BegOfMonth(CurrRow[FieldNamePeriod]);		
	EndDo;
	
	TaskTable.GroupBy(FieldsNames, "");
	TaskTable.Sort(FieldsNames);
	
	TaskTableByMonth.GroupBy(FieldsNames, "");
	TaskTableByMonth.Sort(FieldsNames);
	TaskTableByMonth.Columns.Add("ErrorIsFixed", New TypeDescription("Boolean"));
	
	CompanyTable = TaskTable.Copy(, "Organization");
	CompanyTable.GroupBy("Organization", "");
	
	DatesByCompany = InformationRegisters.SetUpLockFromChanges.BlockingDatesByCompanies(CompanyTable.UnloadColumn("Organization"));
	
	For Each CurrRow In TaskTable Do
		
		LockUntil = DatesByCompany.Get(CurrRow.Organization);

		If ValueIsFilled(LockUntil) And BegOfMonth(CurrRow[FieldNamePeriod]) <= LockUntil Then

			LineForMonth = TaskTableByMonth.FindRows(New Structure(FieldsNames, BegOfMonth(CurrRow[FieldNamePeriod]), CurrRow.Organization));
			If LineForMonth[0].ErrorIsFixed Then
				Continue;
			EndIf;
			
			ShouldRegisterError = True;
			ShouldRegisterError = CheckStatusChangeInRecord(Source, OldSourceFieldValues, CurrRow.Organization, CurrRow[FieldNamePeriod]);
			If ShouldRegisterError Then
				AddInformationAboutTaskInBlockedPeriod(CurrRow.Organization, CurrRow[FieldNamePeriod], LockUntil, Source.Metadata().Name, Cancel);
				LineForMonth[0].ErrorIsFixed = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DescriptionOfSystemStateChecks

// Fills in groups of checks performed during the month's closing.
//
// Parameters:
//	TableOfInspectionGroups - See AuditOfSystemState.TableOfSystemStateCheckGroups
//
Procedure FillInVerificationGroupsForRegistration(TableOfInspectionGroups) Export
	
	DescriptionOfInspectionGroup = TableOfInspectionGroups.Add();
	DescriptionOfInspectionGroup.ParentID = "";
	DescriptionOfInspectionGroup.Description = NStr("vi = 'Kết chuyển cuối tháng';
													|ru = 'Закрытие месяца';
													|en = 'Month-end closing'; fa = 'بستن پایان ماه';
													|it = 'Chiusura del mese';
													|pl = 'Zamknięcie miesiąca';
													|tr = 'Ay sonu kapanışı'");
	DescriptionOfInspectionGroup.AccountingChecksContext = Catalogs.MonthEndClosingOperations.EmptyRef();
	DescriptionOfInspectionGroup.Id = "MonthEndTransactions";
	
	StepsTable = DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth();
	
	AllStages = New Map;
	
	Selection = Catalogs.MonthEndClosingOperations.Select();
	
	While Selection.Next() Do
		If ValueIsFilled(Selection.PredefinedDataName) Then
			AllStages.Insert(Selection.Ref, True);
		EndIf;
	EndDo;
	
	For Each CurrentRow In StepsTable Do
		
		DescriptionOfInspectionGroup = TableOfInspectionGroups.Add();
		DescriptionOfInspectionGroup.ParentID = "MonthEndTransactions";
		DescriptionOfInspectionGroup.Description = CurrentRow.Description;
		DescriptionOfInspectionGroup.AccountingChecksContext = CurrentRow.Code;
		DescriptionOfInspectionGroup.Id = "Group" + "_"
			+ Catalogs.MonthEndClosingOperations.GetPredefinedItemName(CurrentRow.Code);
		
		AllStages.Delete(CurrentRow.Code);
		
	EndDo;
	
	For Each KeyAndValue In AllStages Do
		
		DescriptionOfInspectionGroup = TableOfInspectionGroups.Add();
		DescriptionOfInspectionGroup.ParentID = "MonthEndTransactions";
		DescriptionOfInspectionGroup.Description = TrimAll(KeyAndValue.Key);
		DescriptionOfInspectionGroup.AccountingChecksContext = KeyAndValue.Key;
		DescriptionOfInspectionGroup.Id = "Group" + "_" + Catalogs.MonthEndClosingOperations.GetPredefinedItemName(KeyAndValue.Key);
		
	EndDo;
	
EndProcedure

// Fills in checks that are performed during the closing of the month.
//
// Parameters:
//	TableOfChecks - See AuditOfSystemStateOverridable.FillOutChecksForRegistration.
//
Procedure FillOutChecksForRegistration(TableOfChecks) Export
	
	// Let's fill out the checks of the month's closing operations.
	CostCalculationCostAdjustment.DescriptionOfChecks_CalculationOfBatchesAndCost(TableOfChecks);
	
	DescriptionOfChecks_CorrectionOfErrorsInSourceData(TableOfChecks);
	InventoriesServer.DescriptionOfChecks_CorrectionOfNegativeBalancesOfGoodsOfOrganizations(TableOfChecks);
	IncomeAndExpensesServer.DescriptionOfAudits_AllocationOfFutureExpenses(TableOfChecks);
	FutureExpenseCommitments.DescriptionOfChecks_AccrualWriteOffOfProvisionsForUpcomingExpenses(TableOfChecks);
	ProductionServer.DescriptionOfChecks_ProcessingOfProductionWithoutOrders(TableOfChecks);
	ProductionServer.DescriptionOfInspections_AcceptanceOfInternalWorks(TableOfChecks);
	ProcessingByThirdParties.DescriptionOfInspections_RequirementsForProcessingProcessorsReports(TableOfChecks);
	TollingScheme.DescriptionOfChecks_BalancesForMakingReportsToGivers(TableOfChecks);
	InternalSubcontractingServer.DescriptionOfChecks_BalancesForMakingReportsToGivers(TableOfChecks);
	ProductionManagement.DescriptionOfInspectionsAndPlanningOfProductionOfProductsWithoutSpecifications(TableOfChecks);
	CostsServer.DescriptionOfInspections_DistributionOfMaterialsAndWorkOnCostOfProduction22(TableOfChecks);
	CostsServer.DescriptionOfChecks_SettingUpIndicatorsForAllocatingCostsToCostOfProduction(TableOfChecks);
	CostsServer.DescriptionOfChecks_SettingIndicatorsForAllocatingExpensesBetweenHIA(TableOfChecks);
	InventoriesServer.DescriptionOfChecks_RegistrationOfTransfersOfGoods(TableOfChecks);
	InventoriesServer.DescriptionOfChecks_RegistrationOfRemainingGoodsForTransfer(TableOfChecks);
	InventoriesServer.DescriptionOfChecks_ExecutionOfRedemptionOfGoods(TableOfChecks);
	InventoriesServer.DescriptionOfInspections_PreparationOfCommissionReportsBetweenOrganizations(TableOfChecks);
	InventoriesServer.DescriptionOfChecks_PreparationOfReportsToCommitteesOnWriteOffs(TableOfChecks);
	AccrualAndWriteOffOfBadDebtAlowancesServer.DescriptionOfInspections_FormationOfProvisionsForDoubtfulDebts(TableOfChecks);
	CostsServer.DescriptionOfChecks_ConfiguringCostAllocation(TableOfChecks);
	CostsServer.DescriptionOfChecks_SettingUpCostAllocationManually(TableOfChecks);
	Documents.AllocationOfOtherCosts.DescriptionOfInspections_RegistrationOfDocumentsForDistributionOfExpensesByAreasOfActivity(TableOfChecks);
	Documents.AllocationOfOtherCosts.DescriptionOfInspections_DistributionOfExpensesByAreasOfActivity(TableOfChecks);
	Documents.AllocationOfIncomeByLinesOfBusiness.DescriptionOfInspections_DistributionOfIncomeByAreasOfActivity(TableOfChecks);	
	MonthEndTransactionsLocalization.AddChecksForRegistration(TableOfChecks);
	ARAPAccountingServer.DescriptionOfChecks_FormationOfRegisteredRecordsOnSettlementsWithPartnersAndReassessmentOfSettlements(TableOfChecks);
	BackdateJobQueue.DescriptionOfChecks_CalculationOfAmountsOfDocumentsInAccountingCurrenciesAndRepostingOfFinancialRegisters(TableOfChecks);
	
	// We will also create service contextual checks,
	// to which you can write messages about problems diagnosed during the calculation.

	MonthEndClosingOperations = Catalogs.MonthEndClosingOperations.Select();
	
	While MonthEndClosingOperations.Next() Do
		
		SynonymOfOperation = String(MonthEndClosingOperations.Ref);
		
		If ValueIsFilled(MonthEndClosingOperations.PredefinedDataName) Then
			VerificationDescription = AddDescriptionOfNewCheck(TableOfChecks,
				IDOfStageServiceCheck(MonthEndClosingOperations.Ref),
				MonthEndClosingOperations.Ref,
				Enums.TimeOfStartingMonthEndClosingOperationCheck.DuringCalculation,
				"");
			VerificationDescription.ExecutedOnlyInContext = True;
			
			FillInPresentationOfNewCheck(VerificationDescription,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Các vấn đề được chẩn đoán trong quá trình hoạt động ""%1""';
						|ru = 'Проблемы, диагностированные при выполнении операции ""%1""';
						|en = 'Issues found when executing the ""%1"" operation'; fa = 'Issues found when executing the ""%1"" operation';
						|it = 'Problemi, diagnosticati durante l''esecuzione dell''operazione ""%1""';
						|pl = 'Problemy, wykryte podczas wykonania operacji ""%1""';
						|tr = '""%1"" işlemi sırasında sorun giderme'", Common.DefaultLanguageCode()),
					SynonymOfOperation),
				NStr("vi = 'Một kiểm tra theo ngữ cảnh để ghi lại các vấn đề được chẩn đoán trong quá trình tính toán.';
					|ru = 'Служебная контекстная проверка для регистрации проблем, диагностированных в ходе расчета.';
					|en = 'Service context check to register issues found during the calculation.'; fa = 'Service context check to register issues found during the calculation.';
					|it = 'Verifica contestuale del servizio per la registrazione dei problemi diagnosticati durante il calcolo.';
					|pl = 'Serwisowe sprawdzenie kontekstu w celu rejestracji problemów, wykrytych w trakcie obliczenia.';
					|tr = 'Hesaplama sırasında sorun giderme kaydı için özel içerik kontrolü.'", Common.DefaultLanguageCode()));
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the internal review stage of the end of the month.
// You can add messages about problems that were diagnosed during the calculation to these checks.
//
// Parameters:
//	CalculationStage 				- CatalogRef.MonthEndClosingOperations - month closing stage
//	ReturnErrorIfThereIsNo - Boolean - issue an error if the stage service check is not found.
//
// Returns:
//	CatalogRef.AccountingCheckRules - service check of the closing stage of the month.
//
Function ServiceStageCheck(CalculationStage, ReturnErrorIfThereIsNo = True) Export
	
	Validation = AuditOfSystemState.FindValidationByKeyFields(
		CalculationStage,
		IDOfStageServiceCheck(CalculationStage));
	
	If Not ValueIsFilled(Validation) And ReturnErrorIfThereIsNo Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy kiểm tra ngữ cảnh dịch vụ cho hoạt động ""%1""';
				|ru = 'Не найдена служебная контекстная проверка для операции ""%1""';
				|en = 'Service context check for the ""%1"" operation was not found'; fa = 'Service context check for the ""%1"" operation was not found';
				|it = 'Nessun controllo contestuale di servizio trovato per l''operazione ""%1""';
				|pl = 'Nie jest wyszukane serwisowe sprawdzenie kontekstu dla operacji ""%1""';
				|tr = '""%1"" işlemi için özel içerik kontrolü bulunamadı'"),
			TrimAll(CalculationStage));
		
		Raise ErrorText;
		
	EndIf;
	
	Return Validation;
	
EndFunction

// Returns the ID of the service check for the month closing stage.
//
// Parameters:
//	CalculationStage - CatalogRef.MonthEndClosingOperations - the closing stage of the month.
//
// Returns:
//	String - id of the service check.
//
Function IDOfStageServiceCheck(CalculationStage) Export
	
	Id =
		"ServiceContextualInformationForOrganizationsByPeriod_"
		+ Catalogs.MonthEndClosingOperations.GetPredefinedItemName(CalculationStage);
	
	Return Id;
	
EndFunction

#EndRegion

#Region DescriptionOfParametersOfMonthClosingOperations

// Creates a description of the group of technological parameters of the month closing mechanism.
//
// Returns:
//	ValueTable - See Initialize the description of the Operation parameter group in the manager module for the values of the Month Closure setting constant.
//
Function DescriptionOfGroupsOfParametersForMonthClosingOperation() Export
	
	IsFileIB    = Common.FileInfobase();
	IsDataArea = Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable();
	
	DescriptionOfParameterGroups = Constants.MonthEndClosingSettings.CreateValueManager().InitializeDescriptionOfGroupsOfOperationParameters();
	
	GroupDetails = DescriptionOfParameterGroups.Add();
	GroupDetails.Name 			= "ErrorLogging_";
	GroupDetails.Description = NStr("vi = 'Lỗi đăng nhập';
									|ru = 'Регистрация ошибок';
									|en = 'Register errors'; fa = 'Register errors';
									|it = 'Registrazione degli errori';
									|pl = 'Rejestracja błędów';
									|tr = 'Hata kaydı'");
	GroupDetails.LongDesc 	=
		NStr("vi = 'Các thông số ảnh hưởng đến việc đăng ký lỗi khi tính toán các kỳ kết thúc một tháng.';
			|ru = 'Параметры, влияющие на регистрацию ошибок при расчете этапов закрытия месяца.';
			|en = 'Parameters that affect error registration while calculating month-end closing stages.'; fa = 'Parameters that affect error registration while calculating month-end closing stages.';
			|it = 'Parametri che influenzano la registrazione di errori nel calcolo delle fasi della chiusura del mese.';
			|pl = 'Parametry, wpływające na rejestrację błędów podczas obliczenia etapów zamknięcia miesiąca.';
			|tr = 'Ayı sonu kapanışı aşamalarını hesaplarken hataların kaydını etkileyen parametreler.'");
	
	GroupDetails = DescriptionOfParameterGroups.Add();
	GroupDetails.Name 			= "FederalLawRestrictions";
	GroupDetails.Description = NStr("vi = 'Quản lý đa luồng';
									|ru = 'Управление многопоточностью';
									|en = 'Multithreading control'; fa = 'Multithreading control';
									|it = 'Управление многопоточностью';
									|pl = 'Zarządzanie wielowątkowością';
									|tr = 'Çok kullanım yönetimi'", Common.DefaultLanguageCode());
	GroupDetails.Hide 		= IsFileIB Or IsDataArea;
	GroupDetails.LongDesc 	=
		NStr("vi = 'Các tham số áp đặt các hạn chế đối với các nhiệm vụ nền mà được sử dụng trong các giao dịch đóng tháng.
		|Chỉ được sử dụng trong cơ sở thông tin client-server,
		|vì ở chế độ File-server, Nền tảng không hỗ trợ làm việc song song của các nhiệm vụ nền.';
		|ru = 'Параметры, накладывающие ограничения на фоновые задания, используемые в операциях закрытия месяца.
		|Используются только в клиент-серверной информационной базе,
		|т.к. в файловом режиме Платформа не поддерживает параллельную работу фоновых заданий.';
		|en = 'Parameters that restrict background jobs used in month-end closing transactions.
		|You can use the parameters only in client/server infobases
		|as the Platform does not support parallel processing of background jobs in file mode.'; fa = 'Parameters that restrict background jobs used in month-end closing transactions.
		|You can use the parameters only in client/server infobases
		|as the Platform does not support parallel processing of background jobs in file mode.';
		|it = 'Параметры, накладывающие ограничения на фоновые задания, используемые в операциях закрытия месяца.
		|Используются только в клиент-серверной информационной базе,
		|т.к. в файловом режиме Платформа не поддерживает параллельную работу фоновых заданий.';
		|pl = 'Parameters that restrict background jobs used in month-end closing transactions.
		|You can use the parameters only in client/server infobases
		|as the Platform does not support parallel processing of background jobs in file mode.';
		|tr = 'Ay kapatma işlemlerinde kullanılan arka plan işlerinde kısıtlandırma yapan parametreler. 
		|Sadece istemci sunucusu bilgi tabanında kullanılır, 
		|çünkü dosya modunda Platform arka plan işlerinin paralel olarak yürütülmesini desteklememektedir.'", Common.DefaultLanguageCode());
		
	GroupDetails = DescriptionOfParameterGroups.Add();
	GroupDetails.Name 			= "Debug";
	GroupDetails.Description = NStr("vi = 'Tùy chỉnh đối với chuyên gia kỹ thuật';
									|ru = 'Настройки для технического специалиста';
									|en = 'Settings for technical specialist'; fa = 'Settings for technical specialist';
									|it = 'Impostazioni per i tecnici';
									|pl = 'Ustawienia dla specjalisty technicznego';
									|tr = 'Teknisyen için ayarlar'");
	GroupDetails.LongDesc 	=
		NStr("vi = 'Tham số được dùng để gỡ rối các giai đoạn đóng tháng.
		|Nên thay đổi các tham số này chỉ trong cơ sở thông tin thử nghiệm!';
		|ru = 'Параметры, используемые для отладки этапов закрытия месяца.
		|Изменять данные параметры рекомендуется только в тестовых информационных базах!';
		|en = 'Parameters used to debug month-end closing stages.
		|These parameters can be changed only in test infobases.'; fa = 'Parameters used to debug month-end closing stages.
		|These parameters can be changed only in test infobases.';
		|it = 'Parametri usati per il debug delle fasi di chiusura del mese.
		|Si consiglia di modificare questi parametri solo nei database di test!';
		|pl = 'Parametry, stosowane do debugowania etapów zamknięcia miesiąca.
		|Zmiana danych parametrów jest zalecana tylko w tekstowych bazach informacyjnych!';
		|tr = 'Ay sonu kapanış aşamalarında hata ayıklamak için kullanılan parametreler.
		|Bu parametrelerin yalnızca test infobase''inde değiştirilmesi önerilmektedir!'");
		
	GroupDetails = DescriptionOfParameterGroups.Add();
	GroupDetails.Name 			= "StagesOfPreliminaryClosingOfMonth";
	GroupDetails.Description = NStr("vi = 'Đóng tháng sơ bộ';
									|ru = 'Предварительное закрытие месяца';
									|en = 'Preliminary month-end closing'; fa = 'Preliminary month-end closing';
									|it = 'Chiusura preliminare del mese';
									|pl = 'Wstępne zamknięcie miesiąca';
									|tr = 'Ay sonu ön kapanışı'", Common.DefaultLanguageCode());
	GroupDetails.Hide		= Not CalculationOfCostCached.BatchAccountingVersion22();
	GroupDetails.LongDesc 	=
		NStr("vi = 'Bật / tắt các giai đoạn riêng khi đóng tháng sơ bộ.';
			|ru = 'Включение / выключение отдельных этапов предварительного закрытия месяца.';
			|en = 'Enable/disable individual stages of preliminary month-end closing.'; fa = 'Enable/disable individual stages of preliminary month-end closing.';
			|it = 'Attivazione / disattivazione delle singole fasi della chiusura preliminare del mese.';
			|pl = 'Włączenie / wyłączenie oddzielnych etapów wstępnego zamknięcia miesiąca.';
			|tr = 'Ay sonu ön kapanışının bireysel aşamalarını etkinleştir / devre dışı bırak.'", Common.DefaultLanguageCode());
		
	GroupDetails = DescriptionOfParameterGroups.Add();
	GroupDetails.Name 			= "StagesOfFinalClosingOfMonth";
	GroupDetails.Description = NStr("vi = 'Kết thúc đóng tháng';
									|ru = 'Окончательное закрытие месяца';
									|en = 'Final month-end closing'; fa = 'Final month-end closing';
									|it = 'Chiusura definitiva del mese';
									|pl = 'Ostateczne zamknięcie miesiąca';
									|tr = 'Ayın sonu kapanışı'", Common.DefaultLanguageCode());
	GroupDetails.Hide		= Not CalculationOfCostCached.BatchAccountingVersion22();
	GroupDetails.LongDesc 	=
		NStr("vi = 'Tham số các giai đoạn đóng tháng cuối cùng.';
			|ru = 'Параметры этапов окончательного закрытия месяца.';
			|en = 'Parameters of the final month-end closing stages.'; fa = 'Parameters of the final month-end closing stages.';
			|it = 'Parametri delle fasi di chiusura definitiva del mese.';
			|pl = 'Parametry etapów ostatecznego zamknięcia miesiąca.';
			|tr = 'Ayın son kapanış aşamalarının parametreleri.'", Common.DefaultLanguageCode());
		
	GroupDetails = DescriptionOfParameterGroups.Add();
	GroupDetails.Name 			= "BlockingFromChanges";
	GroupDetails.Description = NStr("vi = 'Phong tỏa tránh các thay đổi';
									|ru = 'Блокировка от изменений';
									|en = 'Lock from changes'; fa = 'قفل در برابر تغییرات';
									|it = 'Блокировка от изменений';
									|pl = 'Lock from changes';
									|tr = 'Değişikliklerden kilit'", Common.DefaultLanguageCode());
	GroupDetails.LongDesc 	=
		NStr("vi = 'Tùy chỉnh cơ chế phong tỏa kỳ đã đóng tránh các thay đổi.';
			|ru = 'Настройки механизма блокировки закрываемого периода от изменений.';
			|en = 'Settings for the lock of a closing period from changes.'; fa = 'Settings for the lock of a closing period from changes.';
			|it = 'Настройки механизма блокировки закрываемого периода от изменений.';
			|pl = 'Settings for the lock of a closing period from changes.';
			|tr = 'Kapanış döneminin değişikliklerden kilitlenmesi için mekanizmanın ayarları.'", Common.DefaultLanguageCode());
		
	Return DescriptionOfParameterGroups;
	
EndFunction

// Generates a description of the technological parameters of the month closing mechanism.
//
// Returns:
//	ValueTable - see Initialize the description of the Operation parameters in the manager module for the values of the Month Closure setting constant.
//
Function DescriptionOfTechnologicalParametersForClosingMonth() Export
	
	IsFileIB    = Common.FileInfobase();
	IsDataArea = Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable();
	
	ParametersDetails = Constants.MonthEndClosingSettings.CreateValueManager().InitializeDescriptionOfOperationParameters();
	
	#Region ErrorLogging_

	Parent = "ErrorLogging_";
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "NumberOfRegisteredErrorsOfSameType";
	ParameterDetails.Description 		  = NStr("vi = 'Số lượng lỗi được ghi lại của một loại';
													|ru = 'Количество регистрируемых ошибок одного вида';
													|en = 'Number of registered errors of one kind'; fa = 'Number of registered errors of one kind';
													|it = 'Numero di errori dello stesso tipo registrati';
													|pl = 'Ilość rejestrowanych błędów jednego rodzaju';
													|tr = 'Aynı türden kaydedilen hataların sayısı'");
	ParameterDetails.ValueType   	  = New TypeDescription("Number",,, New NumberQualifiers(6, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith     	  = 0;
	ParameterDetails.DefaultValue = 100;
	ParameterDetails.LongDesc =
		NStr("vi = 'Được dùng để đẩy nhanh quá trình cập nhật trạng thái và thực hiện tính toán các giao dịch.
		|Nếu kết quả thực hiện việc kiểm tra nào đó có tìm thấy nhiều lỗi cùng kiểu,
		|thì theo quy tắc không cần ghi nhận tất cả lỗi, mà cần phân biệt theo nguyên nhân phát sinh các lỗi này.
		|Nếu chỉ ra giá trị 0 thì sẽ ghi nhận tất cả các lỗi tìm thấy.';
		|ru = 'Предназначен для ускорения обновления состояния и выполнения расчета операций.
		|Если в результате выполнения какой-либо проверки найдено большое количество однотипных ошибок,
		|то как правило нет смысла регистрировать их все - надо разбираться с причинами возникновения этих ошибок.
		|Если указано значение 0, то будут зарегистрированы все найденные ошибки.';
		|en = 'Designed to speed up the state update and perform the operation calculation.
		|If a lot of similar errors are found as a result of any check, do not register them and try to find out the reasons of these errors.
		|If the value is set to 0, then all found errors will be registered.
		|'; fa = 'Designed to speed up the state update and perform the operation calculation.
		|If a lot of similar errors are found as a result of any check, do not register them and try to find out the reasons of these errors.
		|If the value is set to 0, then all found errors will be registered.
		|';
		|it = 'Previsto per accelerare l''aggiornamento dello stato e dell''esecuzione del calcolo delle operazioni.
		|Se come risultato dell''esecuzione di un test viene rilevato un numero elevato di errori dello stesso tipo,
		|di regola non ha senso registrarli tutti: è necessario comprendere le cause di questi errori.
		|Se il valore indicato è 0, verranno registrati tutti gli errori trovati.';
		|pl = 'Jest przeznaczony do przyspieszania aktualizacji statusu i wykonania obliczenia operacji.
		|Jeżeli w wyniku wykonania jakiegokolwiek sprawdzenia została znaleziona duża ilość błędów jednego typu,
		|to na ogół nie ma sensu rejestrować ich wszystkie - trzeba wyjaśniać przyczyny powstania tych błędów.
		|Jeżeli jest wskazana wartość 0, to będą zarejestrowane wszystkie ujawnione błędy.';
		|tr = 'Durum güncellemesini hızlandırmak ve işlemlerin hesaplanmasını gerçekleştirmek için tasarlanmıştır.
		|Herhangi bir kontrol sonucunda aynı türden çok sayıda hata bulunursa, 
		|o zaman kural olarak hepsini günlüğe kaydetmenin bir anlamı yoktur - bu hataların nedenleriyle ilgilenmeniz gerekir.
		|Değer 0 ise, bulunan tüm hatalar günlüğe kaydedilir.'");
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "DuplicateFoundIssuesInLog";
	ParameterDetails.Description 		  = NStr("vi = 'Các vấn đề trùng lặp được tìm thấy trong nhật ký';
													|ru = 'Дублировать найденные проблемы в журнале регистрации';
													|en = 'Duplicate found issues in the event log'; fa = 'Duplicate found issues in the event log';
													|it = 'Duplicare i problemi trovati nel registro di registrazione';
													|pl = 'Dubluj ujawnione problemy w dzienniku rejestracji';
													|tr = 'Kayıt defterinde bulunan tekrarlanan sorunlar'");
	ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
	ParameterDetails.DefaultValue = True;
	ParameterDetails.LongDesc =
		NStr("vi = 'Xác định thao tác của cơ chế đóng tháng khi làm việc với nhật ký sự kiện.
		|Nếu có đặt giá trị True thì thông tin về tất cả các lỗi tìm thấy được ghi nhận trong cơ chế ""Kiểm soát trạng thái hệ thống"",
		|sẽ bị trùng lặp trong nhật ký sự kiện.';
		|ru = 'Определяет поведение механизма закрытия месяца в части работы с журналом регистрации.
		|Если установлено значение Истина, то информация о всех найденных проблемах, регистрируемые в механизме ""Аудит состояния системы"",
		|будет дублироваться в журнале регистрации.';
		|en = 'Defines the behavior of month-end closing mechanism for the event log.
		|If True value is set, information about all found issues which are registered in the ""System state audit"" mechanism
		|will be duplicated in the event log.'; fa = 'Defines the behavior of month-end closing mechanism for the event log.
		|If True value is set, information about all found issues which are registered in the ""System state audit"" mechanism
		|will be duplicated in the event log.';
		|it = 'Definisce il comportamento del meccanismo di chiusura del mese nella parte di lavoro con il registro di registrazione.
		|Se impostato su True, le informazioni su tutti i problemi rilevati registrati nel meccanismo ""Verifica dello stato del sistema""
		|verranno duplicati nel registro di registrazione.';
		|pl = 'Definiuje zachowanie mechanizmu zamknięcia miesiąca w części pracy z dziennikiem rejestracji.
		|Jeśli jest ustanowiona wartość Prawda, to informacje o wszystkich ujawnionych problemach, rejestrowane w mechanizmie """"Аудит состояния системы"",
		|będzie dublowany w dzienniku rejestracji.';
		|tr = 'Kayıt günlüğü ile çalışma açısından ay kapanış mekanizmasının davranışını tanımlar.
		|1 olarak ayarlanırsa, ""Sistem durum denetimi"" mekanizmasında günlüğe kaydedilen bulunan tüm sorunlarla ilgili bilgiler
		|günlüğe kopyalanacaktır.'");
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "NumberOfVerificationAttempts";
	ParameterDetails.Description 		  = NStr("vi = 'Số lượng tối đa thực hiện kiểm tra';
													|ru = 'Максимальное количество выполнения проверки';
													|en = 'Maximum number of checks'; fa = 'Maximum number of checks';
													|it = 'Quantità massima di esecuzione della verifica';
													|pl = 'Maksymalna ilość wykonania sprawdzenia';
													|tr = 'Gerçekleştirilecek maksimum kontrol sayısı'");
	ParameterDetails.ValueType   	  = New TypeDescription("Number",,, New NumberQualifiers(4, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith     	  = 1;
	ParameterDetails.RangeBy    	  = 5;
	ParameterDetails.DefaultValue = 3;
	ParameterDetails.LongDesc =
		NStr("vi = 'Nếu khi ghi lại kết quả thực hiện kiểm tra xảy ra lỗi phong tỏa ghi lại dữ liệu thì sẽ đặt trạng thái ""Cần thực hiện"" đối với giai đoạn đóng tháng, thậm chí nếu không có lỗi thực sự trong giai đoạn này.
		|Để sửa lỗi cụ thể, có thể thử ghi lại kết quả thực hiện nhiều lần, theo giá trị của tham số này.';
		|ru = 'Если при записи результатов выполнения проверки возникает ошибка блокировки записи данных, то этапу закрытия месяца будет установлено состояние ""Требуется выполнение"", даже если нет реальных ошибок в данном этапе.
		|Чтобы попытаться исправить подобную проблему попытка записи результатов выполнения проверки может выполняться несколько раз, в соответствии со значением данного параметра.';
		|en = 'If an error of locking data writing occurs when you save the check results, the month-end closing stage is set to the ""Execution is required"" state even if this stage does not have any errors.
		|To solve the issue, you can try saving the check results as many times as the parameter value specifies.'; fa = 'If an error of locking data writing occurs when you save the check results, the month-end closing stage is set to the ""Execution is required"" state even if this stage does not have any errors.
		|To solve the issue, you can try saving the check results as many times as the parameter value specifies.';
		|it = 'Se durante la registrazione dei risultati di esecuzione della verifica si è verificato un errore di blocco della registrazione dei dati, presso la fase di chiusura del mese sarà impostato lo stato ""Esecuzione richiesta"", anche se non vi sono veri e propri errori in questa fase.
		|Per provare a correggere questo problema, è possibile eseguire il tentativo di registrazione di esecuzione più di una volta, in corrispondenza con il valore di questo parametro.';
		|pl = 'Jeśli podczas zapisu wyników sprawdzenia występuje błąd blokady zapisu danych, to dla etapu zamknięcia miesiąca będzie ustawiony status ""Konieczne wymaganie"", nawet jeśli brak rzeczywistych błędów w tym etapie.
		|Aby spróbować podobny problem próba zapisu wyników wykonania sprawdzenia może być wykonywana kilka razy, zgodnie z wartością tego parametru.';
		|tr = 'Bir doğrulama gerçekleştirilmesinin sonuçları kaydedilirken bir veri yazma kilidi hatası oluşursa, aşamada gerçek hatalar olmasa bile ay sonu aşaması ""Yürütme Gerekli"" olarak ayarlanacaktır.
		|Bu sorunu çözmeye çalışmak için, bu parametrenin değerine göre, kontrol yürütmenin sonuçlarını yazma girişimi birkaç kez gerçekleştirilebilir.'");
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "IgnoreErrorsOfEmergencyEndOFCheck";
	ParameterDetails.Description 		  = NStr("vi = 'Bỏ qua lỗi sự cố xác thực';
													|ru = 'Игнорировать ошибку аварийного завершения проверки';
													|en = 'Ignore an abnormal check termination error'; fa = 'Ignore an abnormal check termination error';
													|it = 'Ignorare l''errore di verifica terminata con errori';
													|pl = 'Ignoruj błąd awaryjnego zakończenia sprawdzenia';
													|tr = 'Doğrulama kilitlenme hatasını görmezden gel'");
	ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
	ParameterDetails.DefaultValue = False;
	ParameterDetails.LongDesc =
		NStr("vi = 'Khi thực hiện kiểm tra, nếu xảy ra lỗi, ví dụ, do lỗi trong mã kiểm tra thì giai đoạn đóng tháng sẽ được đặt trạng thái ""Cần thực hiện"", ngay cả khi không có lỗi thực sự trong giai đoạn này.
		|Có thể đặt giá trị tham số này thành ""Có"" để bỏ qua sự cố này trước khi phát hành bản sửa lỗi cấu hình.';
		|ru = 'Если при выполнении проверки возникает ошибка, например, из-за ошибки в коде самой проверки, то этапу закрытия месяца будет установлено состояние ""Требуется выполнение"", даже если нет реальных ошибок в данном этапе.
		|Чтобы игнорировать подобную проблему до выхода исправительной сборки конфигурации можно установить значение данного параметра равным ""Да"".';
		|en = 'If an error occurs during the check, for example, due to an error in the check code, the month-end closing stage is set to the ""Execution is required"" state even if this stage does not have any errors.
		|To ignore the issue until the configuration patch is released, you can set this parameter to ""Yes"".'; fa = 'If an error occurs during the check, for example, due to an error in the check code, the month-end closing stage is set to the ""Execution is required"" state even if this stage does not have any errors.
		|To ignore the issue until the configuration patch is released, you can set this parameter to ""Yes"".';
		|it = 'Se durante l''esecuzione della verifica insorge un errore, ad esempio a causa dell''errore nel codice di verifica, presso la fase di chiusura del mese sarà impostato lo stato ""Esecuzione richiesta"", anche se non vi sono veri e propri errori durante questa fase. 
		|Per ignorare questo problema fino al rilascio di un assemblaggio correttivo dell''applicazione, è possibile impostare il valore di questo parametro pari a ""Si"".';
		|pl = 'Jeśli podczas wykonania sprawdzenia wystąpił błąd, na przykład, z powodu błędu w kodzie sprawdzenia, to dla etapu będzie ustawiony status ""Konieczne wymaganie"", nawet jeśli nie ma rzeczywistych błędów w tym etapie.
		|Aby zignorować podobny problem przed wydaniem skorygowanej kompilacji konfiguracji można ustawić wartość tego parametru równym ""Tak"".';
		|tr = 'Doğrulama yapılırken, örneğin doğrulama kodundaki hata nedeniyle bir hata oluşursa, bu aşamada gerçek hatalar olmasa bile ay sonu aşaması ""Yürütme Gerekli"" olarak ayarlanacaktır.
		|Düzeltici bir yapılandırma derlemesi yayınlanana kadar bu sorunu görmezden gel için bu parametreyi ""Evet"" olarak ayarlayabilirsiniz.'");
	
	#EndRegion
	
	#Region FederalLawRestrictions
	
	Parent = "FederalLawRestrictions";
	
	// MaximumNumberOfFederalLawsForFormationOfDocuments
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "MaximumNumberOfFederalLawsForFormationOfDocuments";
	ParameterDetails.Description 		  = NStr("vi = 'Số luồng tạo chứng từ hệ thống được thực thi đồng thời tối đa';
													|ru = 'Максимальное количество одновременно выполняемых потоков формирования служебных документов';
													|en = 'Maximum number of simultaneously performed threads of internal document creation'; fa = 'Maximum number of simultaneously performed threads of internal document creation';
													|it = 'Максимальное количество одновременно выполняемых потоков формирования служебных документов';
													|pl = 'Maximum number of simultaneously performed threads of internal document creation';
													|tr = 'Aynı anda gerçekleştirilen maksimum lot oluşturma ile hizmet belgelerinin sayısı'", Common.DefaultLanguageCode());
	ParameterDetails.ValueType   	  = New TypeDescription("Number",,, New NumberQualifiers(3, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith     	  = 0;
	ParameterDetails.DefaultValue = ?(IsFileIB, 0, ?(IsDataArea, 1, 5));
	ParameterDetails.LongDesc =
		NStr("vi = 'Số lượng nhiệm vụ nền chạy đồng thời tối đa để tạo hàng loạt chứng từ hệ thống.
		|Được sử dụng trong một số giai đoạn kết thúc tháng, nhiệm vụ của giai đoạn này là tạo chứng từ.';
		|ru = 'Максимальное количество одновременно запущенных фоновых заданий для пакетного формирования служебных документов.
		|Используется в некоторых этапах закрытия месяца, задачей которых является формирование документов.';
		|en = 'Maximum number of simultaneously started background jobs for batch creation of internal documents.
		|It is used during month-end closing stages intended for creating documents.'; fa = 'Maximum number of simultaneously started background jobs for batch creation of internal documents.
		|It is used during month-end closing stages intended for creating documents.';
		|it = 'Максимальное количество одновременно запущенных фоновых заданий для пакетного формирования служебных документов.
		|Используется в некоторых этапах закрытия месяца, задачей которых является формирование документов.';
		|pl = 'Maximum number of simultaneously started background jobs for batch creation of internal documents.
		|It is used during month-end closing stages intended for creating documents.';
		|tr = 'Hizmet belgelerinin topluca oluşturulması için eş zamanlı yürütülen arka plan işlemlerinin maksimum sayısı.
		|Görevi belge üretmek olan bazı ay sonu kapanış aşamalarında kullanılır.'", Common.DefaultLanguageCode());
	
	#EndRegion
	
	#Region Debug
	
	Parent = "Debug";
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "DoNotCheckBlockingOfIncomingDataWhenUpdatingInformationSecurity";
	ParameterDetails.Description 		  = NStr("vi = 'Không kiểm tra việc hoàn thành cập nhật CSTT';
													|ru = 'Не проверять окончание обновления информационной базы';
													|en = 'Do not check infobase update end'; fa = 'Do not check infobase update end';
													|it = 'Non controllare la fine dell''aggiornamento del database';
													|pl = 'Nie sprawdzaj koniec aktualizacji bazy informacyjnej';
													|tr = 'Infobase güncellemesinin tamamlandığını kontrol etme'");
	ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
	ParameterDetails.DefaultValue = False;
	ParameterDetails.LongDesc =
		NStr("vi = 'Cho phép bỏ qua việc kiểm tra kết thúc cập nhật cơ sở thông tin.
		|Nếu chưa đặt thuộc tính này và việc cập nhật dữ liệu đầu vào của cơ chế tính toán vẫn chưa kết thúc,
		|thì sẽ không thực hiện tính toán, bởi vì dữ liệu đầu vào có thể không chính xác.';
		|ru = 'Позволяет пропустить проверку окончания обновления информационной базы.
		|Если это свойство не установлено и обновление входящих данных механизма расчета еще не завершено,
		|то расчет выполняться не будет, т.к. его входящие данные могут быть некорректны.';
		|en = 'Allows you to skip the infobase update check end.
		|If this property is not set and incoming data of the calculator is not updated,
		|calculation will not be executed since its incoming data might be incorrect.'; fa = 'Allows you to skip the infobase update check end.
		|If this property is not set and incoming data of the calculator is not updated,
		|calculation will not be executed since its incoming data might be incorrect.';
		|it = 'Ti permette di saltare il controllo della fine dell''aggiornamento del database.
		|Se questa proprietà non è impostata e i l''aggiornamento dati di input del meccanismo di calcolo non è ancora stato completati,
		|il calcolo non verrà eseguito, perché il suo input potrebbe essere errato.';
		|pl = 'Pozwala pominąć sprawdzanie ukończenia aktualizacji bazy informacyjnej.
		|Jeśli ta właściwość nie jest ustawiona i aktualizacja danych przychodzących mechanizmu obliczenia jeszcze nie jest zakończona,
		|to obliczenie nie będzie wykonywane, ponieważ jego dane przychodzące mogą być niepoprawne.';
		|tr = 'Infobase güncellemesinin tamamlanıp tamamlanmadığını kontrol etmenizi sağlar.
		|Bu özellik ayarlanmamışsa ve çözücüye gelen verilerin güncellemesi henüz tamamlanmamışsa
		|hesaplama yapılmaz çünkü giriş verileri yanlış olabilir.'");
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "DebugMode";
	ParameterDetails.Description 		  = NStr("vi = 'Chế độ gỡ rối hạch toán';
													|ru = 'Режим отладки расчета';
													|en = 'Calculation debugging mode'; fa = 'Calculation debugging mode';
													|it = 'Regime di calcolo debug';
													|pl = 'Tryb debugowania rozliczenia';
													|tr = 'Hesaplama hata ayıklama modu'");
	ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
	ParameterDetails.DefaultValue = False;
	ParameterDetails.LongDesc =
		NStr("vi = 'Cho phép đặt tham số hệ thống cho các giao dịch đóng tháng
		|Tham số hệ thống chỉ được dùng để làm rõ lỗi tính toán.
		|Để tham số này có hiệu lực, cần lưu lại tham số và mở lại biểu mẫu tùy chỉnh tham số.';
		|ru = 'Позволяет устанавливать служебные параметры операций закрытия месяца
		|Служебные параметры предназначены только для расследования проблем расчета.
		|Чтобы данный параметр вступил в силу нужно сохранить параметры и повторно открыть форму настройки параметров.';
		|en = 'Allows you to set internal parameters for month-end close
		|Internal parameters are intended for investigating calculation problems only.
		|Save the parameters and reopen the parameter settings form for this parameter to take effect.'; fa = 'Allows you to set internal parameters for month-end close
		|Internal parameters are intended for investigating calculation problems only.
		|Save the parameters and reopen the parameter settings form for this parameter to take effect.';
		|it = 'Consente di impostare i parametri di servizio delle operazioni di chiusura del mese
		| I parametri di servizio sono previsti solamente per l''analisi dei problemi di calcolo.
		|Per attivare questo parametro, è necessario salvare i parametri e aprire nuovamente il form dell''impostazione dei parametri.';
		|pl = 'Pozwala na ustawienie parametrów serwisowych operacji zamknięcia miesiąca
		|Parametry serwisowe są przeznaczone tylko do wykrycia problemów obliczenia.
		|Aby ten parametr zaczął obowiązywać należy zapisać parametry i ponownie otworzyć formularz ustawienia parametrów.';
		|tr = 'Ay sonu kapanış işlemleri için servis parametreleri belirlemenizi sağlar.
		|Özel parametreleri yalnızca hesaplama problemlerini araştırmak içindir.
		|Bu parametrenin etkili olması için parametreleri kaydetmeli ve parametre ayarları formu yeniden açılmalı.'");
	
	#EndRegion
	
	#Region StagesOfPreliminaryClosingOfMonth
	
		Parent = "StagesOfPreliminaryClosingOfMonth";
		
		// DistributionOfAdditionalCostsBetweenPartiesAndGoods
		ParameterDetails = ParametersDetails.Add();
		ParameterDetails.Parent 			  = Parent;
		ParameterDetails.Name 				  = "DistributionOfAdditionalCostsBetweenPartiesAndGoods";
		ParameterDetails.Description 		  = NStr("vi = 'Phân bổ chi phí bổ sung cho hàng hóa';
														|ru = 'Распределение дополнительных расходов по товарам';
														|en = 'Additional expenses allocation by goods'; fa = 'Additional expenses allocation by goods';
														|it = 'Distribuzione dei costi aggiuntivi per merci';
														|pl = 'Podział dodatkowych rozchodów wg towarów';
														|tr = 'Ek giderlerin ürünlere göre dağıtımı'", Common.DefaultLanguageCode());
		ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
		ParameterDetails.DefaultValue = True;
		ParameterDetails.Hide			  = Not CalculationOfCostCached.BatchAccountingVersion22();
		ParameterDetails.LongDesc =
			NStr("vi = 'Thực hiện giao dịch phân bổ chi phí bổ sung theo hàng hóa.
			|Cho phép nhận giá vốn hàng hóa có tính đến chi phí bổ sung đã ghi nhận.';
			|ru = 'Выполнение операции распределения дополнительных расходов по товарам.
			|Позволяет получить себестоимость товаров с учетом зарегистрированных дополнительных расходов.';
			|en = 'Execution of the additional expenses allocation by goods.
			|Allows you to get the inventory cost taking into account the registered additional expenses.'; fa = 'Execution of the additional expenses allocation by goods.
			|Allows you to get the inventory cost taking into account the registered additional expenses.';
			|it = 'Esecuzione dell''operazione di distribuzione dei costi aggiuntivi per merci.
			|Consente di ottenere il prezzo di costo delle merci in considerazione dei costi aggiuntivi registrati.';
			|pl = 'Wykonanie operacji podziału dodatkowych rozchodów wg towarów.
			|Pozwala otrzymać koszt własny z uwzględnieniem zarejestrowanych rozchodów dodatkowych.';
			|tr = 'Ek giderlerin ürünlere göre dağıtılması işleminin gerçekleştirilmesi.
			|Kayıtlı ek maliyetleri dikkate alarak ürün maliyetinin alınmasını sağlar.'", Common.DefaultLanguageCode());
			
		// DistributionOfItemByItemSalesExpenses
		ParameterDetails = ParametersDetails.Add();
		ParameterDetails.Parent 			  = Parent;
		ParameterDetails.Name 				  = "DistributionOfItemByItemSalesExpenses";
		ParameterDetails.Description 		  = NStr("vi = 'Phân bổ chi phí vào doanh số bán hàng';
														|ru = 'Распределение расходов на продажу';
														|en = 'Sales expense allocation'; fa = 'Sales expense allocation';
														|it = 'Распределение расходов на продажу';
														|pl = 'Sales expense allocation';
														|tr = 'Satış giderlerinin dağıtımı'", Common.DefaultLanguageCode());
		ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
		ParameterDetails.DefaultValue = True;
		ParameterDetails.Hide			  = Not CalculationOfCostCached.BatchAccountingVersion22();
		ParameterDetails.LongDesc =
			NStr("vi = 'Thực hiện giao dịch phân bổ chi phí bán hàng theo từng giai đoạn.
			|Cho phép nhận lợi nhuận gộp có tính đến chi phí bán hàng đã ghi nhận.';
			|ru = 'Выполнение операции распределения постатейных расходов на продажу.
			|Позволяет получить валовую прибыль с учетом зарегистрированных расходов на продажу.';
			|en = 'Execution of the itemized sales expense allocation.
			|Allows you to get a gross profit taking into account the registered sales expenses.'; fa = 'Execution of the itemized sales expense allocation.
			|Allows you to get a gross profit taking into account the registered sales expenses.';
			|it = 'Выполнение операции распределения постатейных расходов на продажу.
			|Позволяет получить валовую прибыль с учетом зарегистрированных расходов на продажу.';
			|pl = 'Execution of the itemized sales expense allocation.
			|Allows you to get a gross profit taking into account the registered sales expenses.';
			|tr = 'Satış giderlerinin kalemlere göre dağıtılması işleminin gerçekleştirilmesi.
			|Kayıtlı satış giderlerini muhasebeleştirerek brüt kâr elde etmenizi sağlamaktadır.'", Common.DefaultLanguageCode());
			
	#EndRegion
	
	#Region StagesOfFinalClosingOfMonth
	
		Parent = "StagesOfFinalClosingOfMonth";
		
		// RestoreChronologicalSequenceOfDebitingBatches
		ParameterDetails = ParametersDetails.Add();
		ParameterDetails.Parent 			  = Parent;
		ParameterDetails.Name 				  = "RestoreChronologicalSequenceOfDebitingBatches";
		ParameterDetails.Description 		  = NStr("vi = 'Khôi phục trình tự thiết lập thời gian ghi giảm lô hàng theo ""FIFO""';
														|ru = 'Восстанавливать хронологическую последовательность списания партий по ""ФИФО""';
														|en = 'Restore the chronological sequence of writing off lots based on ""FIFO""'; fa = 'Restore the chronological sequence of writing off lots based on ""FIFO""';
														|it = 'Ripristinare l''ordine cronologico di cancellazione dei lotti secondo ""FIFO""';
														|pl = 'Przywróć kolejność chronologiczną rozchodu partii wg ""FIFO""';
														|tr = 'Lotlarının gider yazma kronolojik sırasını ""FIFO""ya göre geri yükle'", Common.DefaultLanguageCode());
		ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
		ParameterDetails.DefaultValue = True;
		ParameterDetails.LongDesc =
			NStr("vi = 'Sẽ thực hiện phân bổ đầy đủ lô hàng mà không lưu lại kết quả tính toán sơ bộ.
			|Cho phép phục hồi trình tự thời gian khi ghi giảm lô hàng theo ""FIFO"".
			|Được sử dụng nếu trong tháng này, sau khi đóng tháng sơ bộ đã thay đổi các chứng từ bằng ""ngày hồi tố"" và điều này
			|làm vi phạm trình tự thời gian khi ghi giảm lô hàng.';
			|ru = 'Будет выполнено полное распределение партий без сохранения результатов предварительного расчета.
			|Позволяет восстановить хронологическую последовательность списания партий по ""ФИФО"".
			|Имеет смысл если в текущем месяце после предварительного закрытия месяца были изменения документов ""задним числом"" и это
			|привело к нарушению хронологической последовательности списания партий.';
			|en = 'The full lot allocation will be performed without saving the results of the preliminary calculation.
			|Allows you to restore the chronological sequence of writing off the lots based on ""FIFO"".
			|Makes sense if there were ""retroactive"" changes in documents in the current month after the preliminary month-end closing and this
			| caused a violation of the chronological sequence of writing off lots.'; fa = 'The full lot allocation will be performed without saving the results of the preliminary calculation.
			|Allows you to restore the chronological sequence of writing off the lots based on ""FIFO"".
			|Makes sense if there were ""retroactive"" changes in documents in the current month after the preliminary month-end closing and this
			| caused a violation of the chronological sequence of writing off lots.';
			|it = 'Verrà eseguita assegnazione completa dei lotti senza salvataggio dei risultati del calcolo preliminare.
			|Consente di ripristinare l''ordine cronologico di cancellazione dei lotti secondo ""FIFO"".
			|Questa operazione ha senso se nel mese corrente sono state effettuate delle modifiche ""retroattive""
			|che hanno portato all''interruzione della sequenza cronologica di cancellazione lotti.';
			|pl = 'Będzie wykonany pełny podział partii bez zapisywania rezultatów wstępnego obliczenia.
			|Pozwala przywrócić kolejność chronologiczną rozchodu partii wg ""FIFO"".
			|Ma sens, jeśli w bieżącym miesiącu po wstępnym zamknięciu miesiąca były zmiany dokumentów ""ze wsteczną datą"" i to
			|doprowadziło do naruszenia kolejności chronologicznej rozchodu partii.';
			|tr = 'Lotların tam bir dağılımı, ön hesaplamanın sonuçları kaydedilmeden gerçekleştirilecektir.
			|Lotların gider yazma kronolojik sırasını ""FIFO""ya göre geri yüklenmesini sağlar.
			|Ay sonu ön kapanışından sonraki cari ayda belgelerde ""geriye dönük"" değişiklikler olup olmadığı ve bunun 
			| lotların silinmesinin kronolojik sırasının ihlaline yol açması mantıklıdır.'", Common.DefaultLanguageCode());
			
		// HighlightDeviationsInCostOfFinalCalculation
		ParameterDetails = ParametersDetails.Add();
		ParameterDetails.Parent 			  = Parent;
		ParameterDetails.Name 				  = "HighlightDeviationsInCostOfFinalCalculation";
		ParameterDetails.Description 		  = NStr("vi = 'Tách chọn chênh lệch giá vốn của phép tính cuối cùng so với kết quả của phép tính sơ bộ';
														|ru = 'Выделять отклонения себестоимости окончательного расчета от результата предварительного расчета';
														|en = 'Highlight cost deviations in the final calculation from the preliminary calculation result'; fa = 'Highlight cost deviations in the final calculation from the preliminary calculation result';
														|it = 'Evidenziare le variazioni del costo di produzione del calcolo definitivo rispetto al risultato del calcolo preliminare';
														|pl = 'Wyróżniaj odchylenia kosztu własnego ostatecznego obliczenia od rezultatu wstępnego obliczenia';
														|tr = 'Ön hesaplamanın sonucundan nihai hesaplamanın maliyetindeki sapmaları seç'", Common.DefaultLanguageCode());
		ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
		ParameterDetails.DefaultValue = False;
		ParameterDetails.LongDesc =
			NStr("vi = 'Khi tính giá vốn, sẽ tính chênh lệch lần tính cuối cùng với kết qua tính sơ bộ.
			|Chênh lệch sẽ được phản ánh bởi các bản ghi riêng trong biểu ghi tích lũy:
			|""Giá vốn hàng hóa"", ""Doanh thu và giá vốn hàng bán"", ""Chi phí khác"" với tham chiếu đến chứng từ hệ thống ""Nguồn ghi tính giá vốn"".
			|Bật tham số này tăng số lượng bản ghi kết chuyển trong biểu ghi và có thể làm tăng thời gian đóng tháng.';
			|ru = 'При расчете себестоимости будут рассчитаны отклонения окончательного расчета от результата предварительного расчета.
			|Отклонения будут отражены отдельными записями в регистрах накопления:
			|""Себестоимость товаров"", ""Выручка и себестоимость продаж"", ""Прочие расходы"" со ссылкой на служебный документ ""Регистратор расчета себестоимости"".
			|Включение данного параметра увеличивает количество движений в регистрах и может приводить к увеличению времени закрытия месяца.';
			|en = 'The deviations of the final calculation from the preliminary calculation result will be calculated when calculating the cost.
			|The deviations will be recorded in separate records in the accumulation registers:
			|""Inventory cost"", ""Revenue and cost of goods sold"", ""Other expenses"" with reference to the internal document ""Cost calculation recorder"".
			|Enabling this parameter increases the number of register records in the registers and may cause the month-end closing time to increase.'; fa = 'The deviations of the final calculation from the preliminary calculation result will be calculated when calculating the cost.
			|The deviations will be recorded in separate records in the accumulation registers:
			|""Inventory cost"", ""Revenue and cost of goods sold"", ""Other expenses"" with reference to the internal document ""Cost calculation recorder"".
			|Enabling this parameter increases the number of register records in the registers and may cause the month-end closing time to increase.';
			|it = 'Durante il calcolo del costo di produzione verranno quantificate le variazioni del calcolo definitivo rispetto al risultato del calcolo preliminare.
			|Le variazioni verranno registrate separatamente nei registri di accumulo:
			|""Costo di produzione dei prodotti"", ""Fatturazione e costo delle vendite"", ""Altre spese"" con il link al documento di servizio ""Registratore del calcolo del costo di produzione"".
			|Attivazione di questo parametro aumento il numero di movimenti nei registri e può comportare un aumento del tempo di chiusura del mese.';
			|pl = 'Podczas rozliczenia kosztu własnego będą rozliczone odchylenia ostatecznego rozliczenia od rezultatu wstępnego obliczenia.
			|Odchylenia będą odzwierciedlone jako oddzielne wpisy w rejestrach akumulacji:
			|""Koszt własny towarów"", ""Utarg i koszt własny sprzedaży"", ""Pozostałe rozchody"" z odnośnikiem do dokumentu służbowego ""Rejestrator rozliczenia kosztu własnego"".
			|Włączenie niniejszego parametru zwiększa ilość ruchów w rejestrach i może doprowadzić do zwiększenia czasu zamknięcia miesiąca.';
			|tr = 'Maliyet fiyatı hesaplanırken, nihai hesaplamanın ön hesaplama sonucundan sapmaları hesaplanacaktır.
			|Sapmalar, birikim kayıtlarındaki ayrı girişlere yansıtılacaktır:
			|""Stok maliyeti"", ""Gelir ve satış maliyeti"", ""Maliyet hesaplama sicili"" hizmet belgesine atıfta bulunarak ""Diğer giderler"".
			|Bu parametrenin etkinleştirilmesi, kasalardaki hareket sayısını artırır ve ay sonu kapanış saatinde bir artışa neden olabilir.'", Common.DefaultLanguageCode());
	
	#EndRegion

	#Region BlockingFromChanges
	
	Parent = "BlockingFromChanges";
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Parent 			  = Parent;
	ParameterDetails.Name 				  = "UseMechanismToBlockChanges";
	ParameterDetails.Description 		  = NStr("vi = 'Sử dụng cơ chế phong tỏa đóng tháng tránh các thay đổi';
													|ru = 'Использовать механизм блокировки закрытия месяца от изменений';
													|en = 'Use the lock of month-end closing from changes'; fa = 'Use the lock of month-end closing from changes';
													|it = 'Использовать механизм блокировки закрытия месяца от изменений';
													|pl = 'Use the lock of month-end closing from changes';
													|tr = 'Ay soni kapanışını değişikliklerden engellemek için bir mekanizma kullan'");
	ParameterDetails.ValueType   	  = New TypeDescription("Boolean");
	ParameterDetails.DefaultValue = True;
	ParameterDetails.LongDesc =
		NStr("vi = 'Cho phép bật sử dụng/tắt sử dụng cơ chế phong tỏa';
			|ru = 'Позволяет включить/отключить использование механизма блокировки';
			|en = 'Allows you to enable or disable the lock'; fa = 'Allows you to enable or disable the lock';
			|it = 'Позволяет включить/отключить использование механизма блокировки';
			|pl = 'Allows you to enable or disable the lock';
			|tr = 'Engelleme mekanizmasının kullanımını etkinleştirmesini/devre dışı bırakılmasını sağlar'");
	
	#EndRegion
	
	ToCompleteDescriptionOfTechnologicalParametersOfMonthSClosing(ParametersDetails);
	
	Return ParametersDetails;
	
EndFunction

Procedure ToCompleteDescriptionOfTechnologicalParametersOfMonthSClosing(ParametersDetails)
	
	// In the procedure, you can add new technological parameters for closing the month.
	// This is used in extensions to debug the cost calculation.
	// For examples of parameter descriptions, see the function descriptiontechnological parameters of the Month closure().  
	
EndProcedure

// Returns the value of the technological parameter of the layout Mode.
//
// Returns:
//	Boolean - the value of the debugging mode
//
Function CalculationDebuggingMode() Export
	
	Return CalculationOfCostCached.ValuesOfTechnologicalParameters(Catalogs.MonthEndClosingOperations.EmptyRef()).DebugMode;
	
EndFunction

// Returns the values of the general technological parameters of the month closing.
//
// Returns:
//	Structure - parameter values
//		Key - parameter name
//		Value - the value of the parameter;
// 
Function GeneralParametersForClosingMonth() Export
	
	Return CalculationOfCostCached.ValuesOfTechnologicalParameters(Catalogs.MonthEndClosingOperations.EmptyRef());
	
EndFunction

#EndRegion

#Region MethodsForDescribingStages

// Structure of the action description.
// 
// Returns:
//  Structure - Structure Of The Action Description:
// * ActionKind - EnumRef.DrillDownActionKindsForMonthEndOperations -
// * Handler - String -
// * FormName - String -
// * MetadataObjectName - String -
// * AtClient - Boolean -
// * AtServer - Boolean -
// * OpenInsteadOfGR - Boolean -
// * NotRequiredOnSuccessfulExecution - Boolean -
// * OpenFormWithBlocking - Boolean -
// * FormParameters - Structure -:
Function StructureOfActionDescription() Export
	
	LongDesc = New Structure;
	
	LongDesc.Insert("ActionKind", 					  Enums.DrillDownActionKindsForMonthEndOperations.EmptyRef());
	LongDesc.Insert("Handler",  					  "");
	LongDesc.Insert("FormName",    					  "");
	LongDesc.Insert("MetadataObjectName",			  "");
	LongDesc.Insert("AtClient",   					  False);
	LongDesc.Insert("AtServer",   					  False);
	LongDesc.Insert("OpenInsteadOfGR", 				  False);
	LongDesc.Insert("NotRequiredOnSuccessfulExecution", False);
	LongDesc.Insert("OpenFormWithBlocking", 	  False);
	
	LongDesc.Insert("FormParameters", 				  New Structure);
	
	Return LongDesc;
	
EndFunction

#EndRegion

#Region MethodsForDealingWithSystemStateProblems

Function NumberOfRegisteredErrorsOfSameType() Export
	
	ParameterValues = CalculationOfCostCached.ValuesOfTechnologicalParameters(
		Catalogs.MonthEndClosingOperations.EmptyRef());
		
	Return ParameterValues.NumberOfRegisteredErrorsOfSameType;
	
EndFunction

Function InitializeCalculationParametersForVerification(CheckParameters) Export
	
	// Preparation of calculation parameters.
	CalculationParameters = New Structure("RegistrationPeriod, CompanyArray, MonthEndClosingMode");
	
	AdditionalParameters = AdditionalVerificationParameters_(CheckParameters);
	
	// selection by period.
	If AdditionalParameters.Property("Period") Then
		If TypeOf(AdditionalParameters.Period) = Type("StandardPeriod") Then
			Period = AdditionalParameters.Period; //StandardPeriod
			CalculationParameters.RegistrationPeriod = BegOfMonth(Period.StartDate);
		Else // value type - Date
			CalculationParameters.RegistrationPeriod = BegOfMonth(AdditionalParameters.Period);
		EndIf;
	ElsIf AdditionalParameters.Property("RegistrationPeriod") Then
		CalculationParameters.RegistrationPeriod = BegOfMonth(AdditionalParameters.RegistrationPeriod);
	Else
		CalculationParameters.RegistrationPeriod = BegOfMonth(CurrentSessionDate());
	EndIf;
	If AdditionalParameters.Property("BeginOfPeriod") Then
		CalculationParameters.Insert("BeginOfPeriod", AdditionalParameters.BeginOfPeriod);
		CalculationParameters.Insert("EndOfPeriod", AdditionalParameters.EndOfPeriod);
	EndIf;
	
	// Selection by organization.
	If AdditionalParameters.Property("CompanyArray") Then
		CalculationParameters.CompanyArray = TMCommonUseClientServer.Array(AdditionalParameters.CompanyArray);
	EndIf;
	
	If Not ValueIsFilled(CalculationParameters.CompanyArray) Then
		CalculationParameters.CompanyArray = Catalogs.Companies.AvailableCompanies();
	EndIf;
	
	// Fill in the selections in the verification parameters.
	CheckParameters.Filters.Clear();
	
	For Each CurrentCompany In CalculationParameters.CompanyArray Do
		NewRow = CheckParameters.Filters.Add();
		NewRow.Organization 	  = CurrentCompany;
		NewRow.CheckedPeriod = CalculationParameters.RegistrationPeriod;
	EndDo;
	
	If ValueIsFilled(AdditionalParameters) And AdditionalParameters.Property("MonthEndClosingMode") Then
		CalculationParameters.Insert("MonthEndClosingMode", AdditionalParameters.MonthEndClosingMode);
	Else
		CalculationParameters.Insert("MonthEndClosingMode", Undefined);
	EndIf;
	
	Return CalculationParameters;
	
EndFunction

Function GenerateDescriptionOfStageData(Code) Export
	
	TableStages = DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth();
	StageString_  = TableStages.Find(Code, "Code"); 
	
	If StageString_ = Undefined Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy mô tả hoạt động gần tháng ""%1""';
				|ru = 'Не найдено описание операции закрытия месяца ""%1""';
				|en = 'Description of the ""%1"" month-end closing operation was not found'; fa = 'Description of the ""%1"" month-end closing operation was not found';
				|it = 'La descrizione dell''operazione di chiusura del mese ""%1"" non è stata trovata';
				|pl = 'Nie znaleziono opisu operacji zamknięcia miesiąca ""%1""';
				|tr = '''%1'' ay sonu kapanış işlemi için açıklama bulunamadı'"),
			TrimAll(Code));
			
		Raise ErrorText;
		
	EndIf;
	
	Data_Stage = TMCommonUse.ConvertTableRowToStructure(StageString_);
	
	Return Data_Stage;
	
EndFunction


Procedure AddObjectToFixedProblem(CheckParameters, DataSource, IssueDetails, FieldList, ObjectFieldName) Export
	
	Presentation = "";
	
	For Each ListItem In FieldList Do
		
		FieldName = ListItem.Value;
		Simple = DataSource[FieldName];
		
		If ValueIsFilled(ListItem.Presentation) And ValueIsFilled(Simple) Then
			Presentation = Presentation + ?(Presentation = "", "", "; ")
				+ ListItem.Presentation + ": """
				+ TrimAll(Simple) + """";
		EndIf;
		
	EndDo;
	
	Presentation = IssueDetails + ":
		|" + Presentation;
	
	AuditOfSystemState.AddObjectToFixedProblem(
		CheckParameters,
		DataSource[ObjectFieldName],
		Presentation);
		
	If Not CheckParameters.Property("AdditionalParameters")
	 Or Not CheckParameters.AdditionalParameters.Property("ResultIsInRegistrationLog")
	 Or CheckParameters.AdditionalParameters.ResultIsInRegistrationLog Then
		DuplicateToLog(CheckParameters.AccountingChecksContext, CheckParameters.Validation, Presentation);
	EndIf;
		
EndProcedure

Procedure AddCompositeObjectToFixedProblem(CheckParameters, DataSource, IssueDetails, FieldList, RegisterNameToDecrypt = "") Export
	
	Details   = New Structure("RegisterNameToDecrypt, ListOfFieldsToDecrypt", RegisterNameToDecrypt, FieldList);
	Presentation = "";
	
	For Each ListItem In FieldList Do
		
		FieldName = ListItem.Value;
		Simple = DataSource[FieldName];
		
		If Simple = NULL Then
			Continue;
		EndIf;
		
		Details.Insert(FieldName, Simple);
		
		If ValueIsFilled(ListItem.Presentation) And ValueIsFilled(Simple) Then
			Presentation = Presentation + ?(Presentation = "", "", "; ")
				+ ListItem.Presentation + ": """
				+ TrimAll(Simple) + """";
		EndIf;
		
	EndDo;
	
	Presentation = IssueDetails + ":
		|" + Presentation;
	
	AuditOfSystemState.AddCompositeObjectToFixedProblem(
		CheckParameters,
		Details,
		Presentation);
	
	If Not CheckParameters.Property("AdditionalParameters")
	 Or Not CheckParameters.AdditionalParameters.Property("ResultIsInRegistrationLog")
	 Or CheckParameters.AdditionalParameters.ResultIsInRegistrationLog Then
		DuplicateToLog(CheckParameters.AccountingChecksContext, CheckParameters.Validation, Presentation);
	EndIf;
	
EndProcedure

Procedure AddInformationAboutUnregisteredObjectsToFixedIssue(CheckParameters, IssueDetails, ObjectCount) Export
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nhiều vấn đề tương tự được tìm thấy: %1';
			|ru = 'Еще найдено аналогичных проблем: %1';
			|en = 'Similar issues found: %1'; fa = 'Similar issues found: %1';
			|it = 'Trovati altri problemi analoghi: %1';
			|pl = 'Jeszcze wykryto analogicznych problemów: %1';
			|tr = 'Daha fazla benzer sorun bulundu: %1%1'", Common.DefaultLanguageCode()),
		TrimAll(ObjectCount));
	
	AuditOfSystemState.AddObjectToFixedProblem(
		CheckParameters,
		Undefined,
		Presentation);
	
	Presentation = IssueDetails + ":
		|" + Presentation;
	
	If Not CheckParameters.Property("AdditionalParameters")
	 Or Not CheckParameters.AdditionalParameters.Property("ResultIsInRegistrationLog")
	 Or CheckParameters.AdditionalParameters.ResultIsInRegistrationLog Then
		DuplicateToLog(CheckParameters.AccountingChecksContext, CheckParameters.Validation, Presentation);
	EndIf;
	
EndProcedure

#EndRegion

#Region MethodsForWorkingWithTasksByEndOfMonth

#Region MethodsForWorkingWithMonthClosingBackgroundJobs

Function CurStateOfBackgroundJob(TaskKeyOrID) Export
	
	Result = New Structure;
	Result.Insert("Description", "");
	Result.Insert("NotFound4", False);
	Result.Insert("Active", False);
	Result.Insert("Completed", False);
	Result.Insert("Failed", False);
	Result.Insert("Canceled", False);
	Result.Insert("Begin");
	Result.Insert("End");
	Result.Insert("ErrorText", "");
	Result.Insert("Job");
	
	If TypeOf(TaskKeyOrID) = Type("String") Then
		
		FilterOfTasks = New Structure("Key", TaskKeyOrID);
		Jobs      = BackgroundJobs.GetBackgroundJobs(FilterOfTasks);
		
		If Jobs.Count() = 0 Then
			Job = Undefined;
		Else
			Job = Jobs[0];
		EndIf;
		
	Else
		Job = BackgroundJobs.FindByUUID(TaskKeyOrID);
	EndIf;
	
	If Job = Undefined Then
		
		Result.NotFound4 = True;
		
		If TypeOf(TaskKeyOrID) = Type("String") Then
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhiệm vụ nền với khóa ""%1""không được tìm thấy.';
					|ru = 'Фоновое задание с ключом ""%1"" не найдено.';
					|en = 'Background job with the ""%1"" key is not found.'; fa = 'Background job with the ""%1"" key is not found.';
					|it = 'Task  di background con chiave ""%1"" non trovato.';
					|pl = 'Zadanie w tle z kluczem ""%1"" nie znaleziono.';
					|tr = '""%1"" anahtarına sahip arka plan işi bulunamadı.'"),
				TrimAll(TaskKeyOrID));
		Else
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa tìm thấy nhiệm vụ nền với tên định danh ""%1"".';
					|ru = 'Фоновое задание с идентификатором ""%1"" не найдено.';
					|en = 'Background job with the ""%1"" ID is not found.'; fa = 'Background job with the ""%1"" ID is not found.';
					|it = 'Task di background con identificatore ""%1"" non trovato.';
					|pl = 'Zadanie w tle z identyfikatorem ""%1"" nie znaleziono.';
					|tr = '""%1"" kimliğine sahip arka plan işi bulunamadı.'"),
				TrimAll(TaskKeyOrID));
		EndIf;
		
		Return Result;
		
	EndIf;
	
	Result.Job 	   = Job;
	Result.Description = Job.Description;
	Result.Begin 	   = Job.Begin;
	Result.End 	   = Job.End;
	
	If Job.State = BackgroundJobState.Active Then
		Result.Active = True;
	ElsIf Job.State = BackgroundJobState.Completed Then
		Result.Completed = True;
	ElsIf Job.State = BackgroundJobState.Failed Then
		Result.Failed = True;
		Result.ErrorText = DetailErrorDescription(Job.ErrorInfo);
	ElsIf Job.State = BackgroundJobState.Canceled Then
		Result.Canceled = True;
	EndIf;
	
	Return Result;
	
EndFunction

Function CancelBackgroundJob_(JobID) Export 
	
	JobState = CurStateOfBackgroundJob(JobID);
	
	If JobState.Active Then
		
		SetPrivilegedMode(True);
		
		Try
			JobState.Job.Cancel();
		Except
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(
				EventLogEventName(NStr("vi = 'Hủy thực hiện nhiệm vụ nền';
										|ru = 'Отмена выполнения фонового задания';
										|en = 'Cancel background job'; fa = 'لغو کار پس‌زمینه';
										|it = 'Annullamento del Task di background';
										|pl = 'Anulowanie wykonywania zadania w tle';
										|tr = 'Arka plan işinin gerçekleştirilmesinin iptali'", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ErrorText);
			
			Return False;
			
		EndTry;
		
	EndIf;
	
	Return True;
	
EndFunction

// Returns the name of a unique background task for closing the month
//
// Returns:
//	String - The name of the background task with the calculation ID.
//
Function NameOfBackgroundJob(CalculationID) Export
	
	Return "MonthEndTransactions_" + TrimAll(CalculationID);
	
EndFunction

#EndRegion

#Region MethodsForWorkingWithTaskRegisters

// Task registers for closing the month.
// 
// Returns:
//  Map of KeyAndValue:
//	* Key - MetadataObjectInformationRegister -
//  * Value - Boolean, Undefined -
Function TaskRegistersForEndOfMonth() Export
	
	Result = New Map;
	Result.Insert(Metadata.InformationRegisters.JobsForAllocatingCustomersARAP, Not GetFunctionalOption("NewOnlineARAPAccounting"));
	Result.Insert(Metadata.InformationRegisters.JobsForAllocatingVendorsARAP, Not GetFunctionalOption("NewOnlineARAPAccounting"));
	Result.Insert(Metadata.InformationRegisters.JobsForMonthEndClosing);
	Result.Insert(Metadata.InformationRegisters.JobsForCalculatingCost);
	Result.Insert(Metadata.InformationRegisters.JobsForGeneratingVATRecords);
	Result.Insert(Metadata.InformationRegisters.JobsForCalculatingIntangibleAssetAmortization);
	Result.Insert(Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation);
	Result.Insert(Metadata.InformationRegisters.JobsForCalculatingNonCurrentAssetCost);
	Result.Insert(Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords);
	Result.Insert(Metadata.InformationRegisters.DocumentPostingInFinancialAccounting, GetFunctionalOption("UseFinancialAccounting"));
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region MethodsForMeasuringPerformance

Procedure IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, DataVolume = 1) Export
	
	DataProcessors.MonthEndClosingOperations.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, DataVolume);
	
EndProcedure

Function TemporaryTableSizes(TemporaryTableContainer, HandlerParameters = Undefined) Export
	
	TemporaryTableSizes = CostCalculationAppliedAlgorithms.TemporaryTableSizes(TemporaryTableContainer);
	
	If ValueIsFilled(HandlerParameters) Then
		IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, TemporaryTableSizes.TotalSizeOfTables);
	EndIf;
	
	Return TemporaryTableSizes;
	
EndFunction

Function TemporaryTableSize(TemporaryTableContainer, TableName, HandlerParameters = Undefined) Export
	
	DataVolume = CostCalculationAppliedAlgorithms.TemporaryTableSize(TemporaryTableContainer, TableName);
	
	If ValueIsFilled(HandlerParameters) Then
		IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, DataVolume);
	EndIf;
	
	Return DataVolume;
	
EndFunction

#EndRegion

#Region MethodsForTestingMonthClose

#Region CheckingCalculationOfStages

// Runs in the background task that is created in the testing processing of the month-close Operation.
//
// Parameters:
//	Period - Date - the test period.
//
Procedure TestingClosingOfMonth(Period) Export
	
	// Let's check the possibility of starting the calculation.
	InformationRegisters.PerformMonthEndClosingOperations.UpdateStateOfActiveCalculations();
	
	CalculationID = New UUID; // it is written to the key of the background job and to the register of operations
	IsFileIB = Common.FileInfobase();
	
	ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.SetFlagForStartingCalculation(
		,
		CalculationID,
		NStr("vi = 'Kiểm tra hoạt động kết thúc hàng tháng';
			|ru = 'Тестирование операций закрытия месяца';
			|en = 'Test month-end closing operations'; fa = 'Test month-end closing operations';
			|it = 'Testing dell''operazione di chiusura del mese';
			|pl = 'Testowanie operacji zamknięcia miesiąca';
			|tr = 'Ay sonu kapanış işlemlerinin test edilmesi'"),
		Period);
	
	If ActiveCalculations.ThereAreActiveCalculations Then
		Raise ActiveCalculations.ErrorText;
	EndIf;
	
	// Fill in the states of the stages.
	StructureOfData = DetermineStateOfMonthClosingStagesForTesting(Period);
	
	If StructureOfData.ChangesAreDisabled Then
		
		 Template1 = NStr("vi = '%Couples1%';
							|ru = '%Couples1%';
							|en = '%Couples1%'; fa = '%Couples1%';
							|it = '%Couples1%';
							|pl = '%Couples1%';
							|tr = '%Couples1%'", Common.DefaultLanguageCode());
		 Template1 = StrReplace(Template1, "%Couples1%", "MonthEndTransactions");
		 
		 WriteLogEvent(Template1
			,
			EventLogLevel.Error,
			Metadata.CommonModules.MonthEndTransactionsServer,
			,
			StructureOfData.ExplanationsToChangeClosing);
		
		Return;
		
	EndIf;
	
	// We will perform all the stages sequentially (including the stages with the status "Completed successfully").
	For Each CurrentRow In StructureOfData.TableStages Do
		
		If CurrentRow.PerformedManually
		 And CurrentRow.State <> Enums.StatesOfMonthEndClosingOperations.NotRequired Then
			
			TheStructureOfTheSearch = New Structure("Parent", CurrentRow.Code);
			ExplanationLines = StructureOfData.StageExplanationTable.FindRows(TheStructureOfTheSearch);

			For Each ExplanationLine In ExplanationLines Do
				
				If ExplanationLine.State <> Enums.AccountingIssueSeverity.Error Then
					Continue;
				EndIf;
				
				// We will duplicate the problems diagnosed for manual operation in the log for subsequent analysis.
				WriteLogEvent(
					EventLogEventName(
						Catalogs.MonthEndClosingOperations.GetPredefinedItemName(CurrentRow.Code)),
					EventLogLevel.Error,
					,
					,
					ExplanationLine.Description);
				
			EndDo;
			
		EndIf;
		
		If CurrentRow.PerformedManually
		 Or CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
			Continue;
		EndIf;
		
		CurrentRow.State = Enums.StatesOfMonthEndClosingOperations.NotCompleted;
		
		CalculationStartParameters = DataProcessors.MonthEndClosingOperations.InitializeStartupParametersForCalculatingStages(
			StructureOfData,
			CurrentRow.Code,
			StructureOfData.TableStages[StructureOfData.TableStages.Count()-1].Code,
			Enums.MonthEndClosingModes.FinalClosing);
		
		CalculationStartParameters.AutoTesting = True;
		
		If IsFileIB Then
			
			DataProcessors.MonthEndClosingOperations.PerformCalculationOfStages(CalculationStartParameters);
			
		Else
			
			// Let's start the calculation of the stage in the background task.
			ExportProcedureParameters = New Array;
			ExportProcedureParameters.Add(CalculationStartParameters);
			
			Job = BackgroundJobs.Execute(
				"MonthEndTransactionsServer.PerformStageTestingInBackgroundTask",
				ExportProcedureParameters,
				NameOfBackgroundJob(CalculationID),
				NStr("vi = 'Kiểm tra giai đoạn kết thúc hàng tháng';
					|ru = 'Тестирование этапа закрытия месяца';
					|en = 'Test month-end closing stage'; fa = 'Test month-end closing stage';
					|it = 'Тестирование этапа закрытия месяца';
					|pl = 'Test month-end closing stage';
					|tr = 'Ay sonu kapanış aşamasının testi'"));
			
			ErrorText = "";
			ArrayOfTasks = New Array;
			ArrayOfTasks.Add(Job);
			
			Try
				
				ArrayOfTasks = BackgroundJobs.WaitForExecutionCompletion(ArrayOfTasks);
				Job = ArrayOfTasks[0];
				
				If Job.State <> BackgroundJobState.Completed Then

					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Nhiệm vụ nền tính toán giai đoạn %1 %2:
						|%3';
						|ru = 'Фоновое задание расчета этапа %1 %2:
						|%3';
						|en = 'Background job for stage calculation %1 %2:
						|%3'; fa = 'Background job for stage calculation %1 %2:
						|%3';
						|it = 'Фоновое задание расчета этапа %1 %2:
						|%3';
						|pl = 'Background job for stage calculation %1 %2:
						|%3';
						|tr = 'Aşama hesaplamasının arka plan görevi %1 %2:
						|%3'", Common.DefaultLanguageCode()),
						"""" + TrimAll(CurrentRow.Code) + """",
						?(Job.State = BackgroundJobState.Canceled,
							NStr("vi = 'đã hủy';
								|ru = 'отменено';
								|en = 'canceled'; fa = 'canceled';
								|it = 'отменено';
								|pl = 'anulowano';
								|tr = 'iptal edildi'", Common.DefaultLanguageCode()),
							NStr("vi = 'kết thúc bất thường';
								|ru = 'завершено аварийно';
								|en = 'aborted'; fa = 'aborted';
								|it = 'завершено аварийно';
								|pl = 'zakończone awaryjnie';
								|tr = 'arızalı tamamlandı'", Common.DefaultLanguageCode())),
						?(Job.ErrorInfo = Undefined,
							NStr("vi = '<Không có mô tả lỗi>';
								|ru = '<Нет описания ошибки>';
								|en = '<No error description>'; fa = '<No error description>';
								|it = '<Нет описания ошибки>';
								|pl = '<Brak opisu błędu>';
								|tr = '<Hata ayrıntıları mevcut değil>'", Common.DefaultLanguageCode()),
							DetailErrorDescription(Job.ErrorInfo)));
							
				EndIf;
				
			Except
				ErrorText = DetailErrorDescription(ErrorInfo());
			EndTry;
			
			If ValueIsFilled(ErrorText) Then
				Raise ErrorText;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationID);
	
EndProcedure

// Performs testing of the month closing stage in the background task.
//
// Parameters:
//	CalculationStartParameters - Structure - parameters for starting the calculation.
//
Procedure PerformStageTestingInBackgroundTask(CalculationStartParameters) Export
	
	DataProcessors.MonthEndClosingOperations.PerformCalculationOfStages(CalculationStartParameters);
	
EndProcedure

#EndRegion

#Region CheckingStateOfStages

// Defines the status of the month's closing stages for testing purposes.
//
// Parameters:
//	Period 			  - Date - the test period
//	CompanyArray - CatalogRef.Companies, Array - organizations for testing.
//
// Returns:
//	See DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState
//
Function DetermineStateOfMonthClosingStagesForTesting(Period, CompanyArray = Undefined) Export
	
	StructureOfData = DataProcessors.MonthEndClosingOperations.InitializeDataStructureToPopulateState(
		BegOfMonth(Period),
		CompanyArray);
	
	ParametersForTriggeringStateUpdates =
		DataProcessors.MonthEndClosingOperations.InitializeStartupParametersToPopulateState(StructureOfData);
	
	ParametersForTriggeringStateUpdates.UpdateListOfChecks    = True;
	ParametersForTriggeringStateUpdates.AutoTesting = True;
	
	DataProcessors.MonthEndClosingOperations.FillInStatesOfStages(ParametersForTriggeringStateUpdates);
	
	Return StructureOfData;
	
EndFunction

// Stores information about the state of the end of the month in the files.
// Significant columns of tables are saved in tables of Stages and tables of grouped Explanations.
// By comparing the uploaded files of different versions, you can get differences in the state of the month's closing stages
// and thus identify" opened " periods that were closed in the previous version.
//
// The saved files have the format "<uploaded data Type>_<Test period>.mxl",
// so data from the same period in different is must be uploaded to different directories,
// otherwise the second upload will overwrite the results of the first one.
//
// Parameters:
//	CatalogToUpload - String - path to the folder to save data to
//	Period 			   - Date - the test period
//	CompanyArray  - CatalogRef.Companies, Array - organizations for testing.
//
// Returns:
//	String - information about a file recording error; if there were no errors, an empty string is returned.
//
Function SaveStateOfMonthClosingStagesForTesting(CatalogToUpload, Period, CompanyArray = Undefined) Export
	
	// Let's check the incorrect procedure call.
	If Not ValueIsFilled(Period) Or Not ValueIsFilled(CatalogToUpload) Then
		Return NStr("vi = 'Chưa chỉ ra thông số bắt buộc';
					|ru = 'Не указаны обязательные параметры';
					|en = 'Required parameters are not specified'; fa = 'Required parameters are not specified';
					|it = 'Non indicati dei parametri obbligatori';
					|pl = 'Nie są wskazane parametry obowiązkowe';
					|tr = 'Zorunlu parametreler belirtilmedi'");
	EndIf;
	
	// Fill in the states of the stages.
	StructureOfData = DetermineStateOfMonthClosingStagesForTesting(Period, CompanyArray);
	
	TableStages = StructureOfData.TableStages.Copy(, "Code, State");
	TableOfGroupedExplanations = StructureOfData.TableOfGroupedExplanations.Copy(, "Parent, Description, State");
	
	// We will save the stage column as the name of the enumeration value.
	FillInStageNameColumnForTesting(TableStages, "Code");
	TableStages.Columns.Delete("Code");
	
	FillInStageNameColumnForTesting(TableOfGroupedExplanations, "Parent");
	TableOfGroupedExplanations.Columns.Delete("Parent");
	
	TableStages.Sort("Stage, State");
	TableOfGroupedExplanations.Sort("Stage, Description, State");
	
	// Let's save the tables in files.
	Directory = CommonClientServer.AddLastPathSeparator(TrimAll(CatalogToUpload));
	
	CreateDirectory(Directory);
	
	FilesNames = UploadFileNamesStateOfStagesForTesting(Period);
	
	ErrorText = TMCommonUse.SaveTableOfValuesToFile(
		TableStages,
		Directory + FilesNames.TableStages);
	
	If ValueIsFilled(ErrorText) Then
		Return ErrorText;
	EndIf;
	
	ErrorText = TMCommonUse.SaveTableOfValuesToFile(
		TableOfGroupedExplanations,
		Directory + FilesNames.TableOfGroupedExplanations);
	
	If ValueIsFilled(ErrorText) Then
		Return ErrorText;
	EndIf;
	
	Return "";
	
EndFunction

// Compares two uploads of the States of the month's closing operations.
// The upload is performed by the save state function of the closing stages of the month for Testing().
//
// Parameters:
//	Period 			      - Date - the test period
//	CatalogToUpload1   - String - path to the folder to save data # 1
//	CatalogToUpload2   - String - path to the folder to save data # 2
//	DoNotOutputNewStages  - Boolean - if True, the difference in the operation will not be displayed,
//									 which is only in one of the versions of the compared configurations
//	DoNotDisplayUnchangedStages - Boolean - if True, operations with the same status will not be output.
//
// Returns:
//	String - information about the comparison of uploads, can be one of the following types:
//		information about a comparison error if something is wrong with
//		the upload files a comparison report containing a description of the differences in the State/explanations of operations
//		is an empty line if there are no errors or differences.
//
Function CompareStateOfMonthClosingStagesForTesting(Period,
			CatalogToUpload1, CatalogToUpload2, DoNotOutputNewStages = False, DoNotDisplayUnchangedStages = False) Export
	
	MessageTexts_ = New Array;
	
	#Region CheckingFiles
	
	Directory1 = CommonClientServer.AddLastPathSeparator(TrimAll(CatalogToUpload1));
	Directory2 = CommonClientServer.AddLastPathSeparator(TrimAll(CatalogToUpload2));
	
	If Lower(Directory1) = Lower(Directory2) Then
		MessageTexts_.Add(NStr("vi = 'Tên của thư mục tải lên số 1 VÀ số 2 không được khớp';
								|ru = 'Имена каталогов выгрузки №1 И №2 не должны совпадать';
								|en = 'Names of export catalogs No.1 and No.2 must not be the same'; fa = 'Names of export catalogs No.1 and No.2 must not be the same';
								|it = 'I nomi delle directory di importazione №1 e №2 non devono coincidere';
								|pl = 'Nazwy katalogów wysłania nr1 i nr2 nie powinny być zbieżne';
								|tr = 'İndirme klasörü adları №1 AND №2 eşleşmemelidir'"));
		Return StrConcat(MessageTexts_, Chars.LF); // no further comparison is possible
	EndIf;
	
	// Let's check the availability of data upload files for the specified periods in the specified directories.
	FilesNames = UploadFileNamesStateOfStagesForTesting(Period);
	
	CheckPresenceOfUploadFileStateOfStagesForTesting(
		Directory1,
		FilesNames.TableStages,
		NStr("vi = 'giao dịch';
			|ru = 'операций';
			|en = 'operations'; fa = 'operations';
			|it = 'operazioni';
			|pl = 'operations';
			|tr = 'işlemler'"),
		MessageTexts_);
	
	CheckPresenceOfUploadFileStateOfStagesForTesting(
		Directory1,
		FilesNames.TableOfGroupedExplanations,
		NStr("vi = 'giải thích';
			|ru = 'пояснений';
			|en = 'explanations'; fa = 'explanations';
			|it = 'delle spiegazioni';
			|pl = 'explanations';
			|tr = 'not'"),
		MessageTexts_);
	
	CheckPresenceOfUploadFileStateOfStagesForTesting(
		Directory2,
		FilesNames.TableStages,
		NStr("vi = 'giao dịch';
			|ru = 'операций';
			|en = 'operations'; fa = 'operations';
			|it = 'operazioni';
			|pl = 'operations';
			|tr = 'işlemler'"),
		MessageTexts_);
	
	CheckPresenceOfUploadFileStateOfStagesForTesting(
		Directory2,
		FilesNames.TableOfGroupedExplanations,
		NStr("vi = 'giải thích';
			|ru = 'пояснений';
			|en = 'explanations'; fa = 'explanations';
			|it = 'delle spiegazioni';
			|pl = 'explanations';
			|tr = 'not'"),
		MessageTexts_);
	
	If ValueIsFilled(MessageTexts_) Then
		Return StrConcat(MessageTexts_, Chars.LF); // no further comparison is possible
	EndIf;
	
	#EndRegion
	
	#Region ReadingFiles
	
	// Let's read the tables from the files.
	TableStages1 =
		TMCommonUse.GetTableOfValuesFromFile(Directory1 + FilesNames.TableStages);
	
	If TypeOf(TableStages1) = Type("String") Then
		MessageTexts_.Add(TableStages1);
	EndIf;
	
	TableOfGroupedExplanations1 =
		TMCommonUse.GetTableOfValuesFromFile(Directory1 + FilesNames.TableOfGroupedExplanations);
	
	If TypeOf(TableOfGroupedExplanations1) = Type("String") Then
		MessageTexts_.Add(TableOfGroupedExplanations1);
	EndIf;
	
	TableStages2 =
		TMCommonUse.GetTableOfValuesFromFile(Directory2 + FilesNames.TableStages);
	
	If TypeOf(TableStages2) = Type("String") Then
		MessageTexts_.Add(TableStages2);
	EndIf;
	
	TableOfGroupedExplanations2 =
		TMCommonUse.GetTableOfValuesFromFile(Directory2 + FilesNames.TableOfGroupedExplanations);
	
	If TypeOf(TableOfGroupedExplanations2) = Type("String") Then
		MessageTexts_.Add(TableOfGroupedExplanations2);
	EndIf;
	
	If ValueIsFilled(MessageTexts_) Then
		Return StrConcat(MessageTexts_, Chars.LF); // no further comparison is possible
	EndIf;
	
	#EndRegion
	
	#Region FileCompare
	
	// Let's form tables of differences.
	TableOfDifferencesStages = TMCommonUse.CompareValueTables(
		TableStages1,
		TableStages2);
	
	If TypeOf(TableOfDifferencesStages) = Type("String") Then
		MessageTexts_.Add(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể so sánh bảng trạng thái các giai đoạn:
					|%1';
					|ru = 'Невозможно сравнить таблицы состояния этапов:
					|%1';
					|en = 'Cannot compare stage state tables:
					|%1'; fa = 'Cannot compare stage state tables:
					|%1';
					|it = 'Non è possibile confrontare le tabelle di stato delle fasi:
					|%1';
					|pl = 'Niemożliwe jest porównanie tabeli statusu etapów:
					|%1';
					|tr = 'Aşama durumu tabloları karşılaştırılamıyor:
					|%1'"),
				TableOfDifferencesStages));
	EndIf;
	
	TableOfDifferencesExplanations = TMCommonUse.CompareValueTables(
		TableOfGroupedExplanations1,
		TableOfGroupedExplanations2);
	
	If TypeOf(TableOfDifferencesExplanations) = Type("String") Then
		MessageTexts_.Add(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể so sánh bảng giải thích đối với giai đoạn:
					|%1';
					|ru = 'Невозможно сравнить таблицы пояснений к этапам:
					|%1';
					|en = 'Cannot compare explanation tables to steps:
					|%1'; fa = 'Cannot compare explanation tables to steps:
					|%1';
					|it = 'Non è possibile confrontare le tabelle delle spiegazioni delle fasi:
					|%1';
					|pl = 'Niemożliwe jest porównanie tabeli komentarzy do etapów:
					|%1';
					|tr = 'Aşama açıklama tabloları karşılaştırılamıyor:
					|%1'"),
				TableOfDifferencesExplanations));
	EndIf;
	
	If ValueIsFilled(MessageTexts_) Then
		Return StrConcat(MessageTexts_, Chars.LF); // no further comparison is possible
	ElsIf TableOfDifferencesStages.Count() = 0 And TableOfDifferencesExplanations.Count() = 0 Then
		Return ""; // there are no differences
	EndIf;
	
	// Let's add indexes to search through tables.
	TableStages1.Indexes.Add("Stage");
	TableOfDifferencesStages.Indexes.Add("Stage");
	TableOfDifferencesExplanations.Indexes.Add("Stage");
	
	#EndRegion
	
	#Region FormingArrayOfDifferingStages
	
	Stages = TableOfDifferencesStages.Copy(, "Stage");
	Stages.GroupBy("Stage", "");
	
	ArrayOfStages = Stages.UnloadColumn("Stage");
	
	Stages = TableOfDifferencesExplanations.Copy(, "Stage");
	Stages.GroupBy("Stage", "");
	
	CommonClientServer.SupplementArray(
		ArrayOfStages, 
		Stages.UnloadColumn("Stage"), True);
	
	#EndRegion
	
	#Region ReportGeneration
	
	MessageTexts_.Clear();
	
	TMCommonUseClientServer.SortArray(ArrayOfStages);
	
	For Each CurrentStep In ArrayOfStages Do
		
		State1 = Undefined;
		State2 = Undefined;
		
		// Let's check the stage state change.
		StageLines = TableOfDifferencesStages.FindRows(New Structure("Stage", CurrentStep));
		
		For Each StageString_ In StageLines Do
			
			If StageString_.RowCounterForComparedTables > 0 Then
				State1 = StageString_.State;
			Else
				State2 = StageString_.State;
			EndIf;
			
		EndDo;
		
		If Not ValueIsFilled(State1) And Not ValueIsFilled(State2) Then
			
			// The state has not changed - we will read it from the source table.
			RowOfOriginalTable = TableStages1.Find(CurrentStep, "Stage");
			
			If RowOfOriginalTable = Undefined Then
				
				MessageTexts_.Add("");
				MessageTexts_.Add("////////////////////////////////////////////////////////////////////////////////");
		
				MessageTexts_.Add(
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Lỗi: hoạt động ""%1"" không có trong bảng tải lên hoạt động';
							|ru = 'Ошибка: операция ""%1"" отсутствует в таблице выгрузки операций';
							|en = 'Error: the ""%1"" operation is missing in operation export table'; fa = 'Error: the ""%1"" operation is missing in operation export table';
							|it = 'Errore: l''operazione ""%1"" non è presente nella tabella di importazione delle operazioni';
							|pl = 'Błąd: operacja ""%1"" nie istnieje w tabeli wysłania operacji';
							|tr = 'Hata: ""%1"" işlemi, işlem boşaltma tablosunda değil'"),
						CurrentStep));
				
				Continue;
				
			EndIf;
			
			State1 = RowOfOriginalTable.State;
			State2 = State1;
			
		EndIf;
		
		If Not ValueIsFilled(State1) And ValueIsFilled(State2) Then
			
			If DoNotOutputNewStages Then
				Continue; // there is a stage only in unloading No. 2
			EndIf;
			
			TextOfDistinction = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giao dịch chỉ hiện diện trong việc kết xuất số 2: ""%1""';
					|ru = 'Операция присутствует только в выгрузке №2: ""%1""';
					|en = 'Operation exists only in export No.2: ""%1""'; fa = 'Operation exists only in export No.2: ""%1""';
					|it = 'L''operazione è presente solo nell''importazione №2: ""%1""';
					|pl = 'Operacja istnieje tylko w wysłaniu nr2: ""%1""';
					|tr = 'İşlem yalnızca yükleme №2''de mevcut: ""%1""'"),
				State2);
			
		ElsIf Not ValueIsFilled(State2) And ValueIsFilled(State1) Then
			
			If DoNotOutputNewStages Then
				Continue; // there is a stage only in unloading No. 1
			EndIf;
			
			TextOfDistinction = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giao dịch chỉ hiện diện trong việc kết xuất số 1: ""%1""';
					|ru = 'Операция присутствует только в выгрузке №1: ""%1""';
					|en = 'Operation exists only in export No.1: ""%1""'; fa = 'Operation exists only in export No.1: ""%1""';
					|it = 'L''operazione è presente solo nell''importazione №1: ""%1""';
					|pl = 'Operacja istnieje tylko w wysłaniu nr1: ""%1""';
					|tr = 'İşlem yalnızca yükleme №1''de mevcut: ""%1""'"),
				State1);
				
		ElsIf State1 <> State2 Then
			TextOfDistinction = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trạng thái hoạt động đã thay đổi: ""%1"" - ""%2""';
					|ru = 'Изменилось состояние операции: ""%1"" - ""%2""';
					|en = 'Operation state changed: ""%1"" - ""%2""'; fa = 'Operation state changed: ""%1"" - ""%2""';
					|it = 'Modificato lo stato dell''operazione ""%1"" - ""%2""';
					|pl = 'Zmienił się status operacji: ""%1"" - ""%2""';
					|tr = 'İşlem durumu değişti: ""%1"" - ""%2""'"),
				State1,
				State2);
		Else
			
			If DoNotDisplayUnchangedStages Then
				Continue; // the stage has not changed
			EndIf;
			
			TextOfDistinction = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trạng thái hoạt động không thay đổi: ""%1""';
					|ru = 'Состояние операции не изменилось: ""%1""';
					|en = 'Operation state not changed: ""%1""'; fa = 'Operation state not changed: ""%1""';
					|it = 'Lo stato dell''operazione non è modificato: ""%1""';
					|pl = 'Status operacji nie zmienił się: ""%1""';
					|tr = 'İşlem durumu değişmedi: ""%1""'"),
				State1);
			
		EndIf;
		
		MessageTexts_.Add("");
		MessageTexts_.Add("////////////////////////////////////////////////////////////////////////////////");
		
		MessageTexts_.Add(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Giao dịch ""%1""';
					|ru = 'Операция ""%1""';
					|en = '""%1"" operation'; fa = '""%1"" operation';
					|it = 'Operazione ""%1""';
					|pl = 'Operacja ""%1""';
					|tr = '""%1"" işlemi'"),
				CurrentStep));
		
		MessageTexts_.Add(TextOfDistinction);
		
		// Let's check the change of the stage explanations.
		
		StageLines = TableOfDifferencesExplanations.FindRows(New Structure("Stage", CurrentStep));
		
		If StageLines.Count() = 0 Then 
			MessageTexts_.Add(NStr("vi = 'Không có sự khác biệt trong các giải thích cho kỳ.';
									|ru = 'Отличий в пояснениях к этапу нет';
									|en = 'There are no differences in explanations to step'; fa = 'There are no differences in explanations to step';
									|it = 'Non vi sono differenze tra le spiegazioni della fase';
									|pl = 'Nie ma różnic w komentarzach do etapu';
									|tr = 'Aşama notlarında herhangi bir farklılık mevcut değil'"));
			Continue;
		EndIf;
		
		MessageTexts_.Add(NStr("vi = 'Các giải thích cho kỳ đã thay đổi';
								|ru = 'Изменились пояснения к этапу';
								|en = 'Explanations to step changed'; fa = 'Explanations to step changed';
								|it = 'Modificate le spiegazioni della fase';
								|pl = 'Zostały zmienione komentarze do etapu';
								|tr = 'Aşama için değiştirilmiş notlar'") + ":");
		
		TemplateTextDifferences = "	" + NStr("vi = 'Chỉ có trong số tải lên %1: ""%2"" - ""%3""';
												|ru = 'Есть только в выгрузке №%1: ""%2"" - ""%3""';
												|en = 'Available only in export No.%1: ""%2"" - ""%3""'; fa = 'Available only in export No.%1: ""%2"" - ""%3""';
												|it = 'Presente solo nell''importazione №%1: ""%2"" - ""%3""';
												|pl = 'Istnieje tylko w wysłaniu nr%1: ""%2"" - ""%3""';
												|tr = 'Yalnızca №%1 yüklemesinde kullanılabilir: ""%2"" - ""%3""'");
		
		For Each StageString_ In StageLines Do
			
			If StageString_.RowCounterForComparedTables > 0 Then
				TextUpload = "1";
			Else
				TextUpload = "2";
			EndIf;
			
			MessageTexts_.Add(
				StringFunctionsClientServer.SubstituteParametersToString(
					TemplateTextDifferences,
					TextUpload,
					StageString_.State,
					StageString_.Description));
			
		EndDo;
		
	EndDo;
	
	If MessageTexts_.Count() = 0 Then 
		Return "";
	EndIf;
	
	MessageTexts_.Insert(0,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo so sánh trạng thái giao dịch kết chuyển cuối tháng.
			|Trong báo cáo chỉ bao gồm các giao dịch có khác biệt trong trạng thái và/hoặc trong mô tả lỗi (diễn giải).
			|
			|Kỳ kiểm tra: %1
			|Kết xuất số 1: ""%2""
			|Kết xuất số 2: ""%3""';
			|ru = 'Отчет о сравнении состояний операций закрытия месяца.
			|В отчет включены только операции, имеющие различия в состоянии и/или в описании проблем (пояснениях).
			|
			|Проверяемый период: %1
			|Выгрузка №1: ""%2""
			|Выгрузка №2: ""%3""';
			|en = 'Report on comparison of month-end closing operation states. 
			|The report contains only operations having discrepancies in state and/or in problem description (explanation).
			|
			|Checked period: %1
			|Export No.1: ""%2""
			|Export No.2: ""%3""'; fa = 'Report on comparison of month-end closing operation states. 
			|The report contains only operations having discrepancies in state and/or in problem description (explanation).
			|
			|Checked period: %1
			|Export No.1: ""%2""
			|Export No.2: ""%3""';
			|it = 'Report sul confronto dello stato delle operazioni di chiusura del mese.
			|Il rapporto include solo quelle operazioni che presentano differenze nello stato e / o nella descrizione dei problemi (spiegazioni).
			|
			|Periodo controllato: %1
			|.Importazione №1:""%2""
			|Importazione №2: ""%3""';
			|pl = 'Raport o porównaniu statusów operacji zamknięcia miesiąca.
			|W raporcie są zawarte tylko operacje, mające różnice w statusie i/lub w opisie problemów (komentarzach).
			|
			|Sprawdzany okres: %1
			|Wysłanie nr 1: ""%2""
			|Wysłanie nr 2: ""%3""';
			|tr = 'Ay sonu kapanış işlem durumu karşılaştırma raporu.
			|Rapor, yalnızca durum ve/veya sorun ayrıntılarında (notlarında) farklılıklar olan işlemleri içerir.
			|
			|Kontrol edilen dönem: %1
			|Yükleme №1: ""%2""
			|Yükleme №2: ""%3""'"),
			CostCalculationProtocol.PresentationOfCalculationPeriod(Period),
			Directory1,
			Directory2));
		
	MessageTexts_.Add("");
	
	#EndRegion
	
	Return StrConcat(MessageTexts_, Chars.LF);
	
EndFunction

// Auxiliary methods.

// Fills the "Stage" column with the name of the Directories value.Month-closing operations.
// 
// Parameters:
// 	Table - ValueTable -
// 	StageColumn - String -
//
Procedure FillInStageNameColumnForTesting(Table, StageColumn)
	
	Table.Columns.Insert(0, "Stage", New TypeDescription("String"));
	
	For Each String In Table Do
		String.Stage = Catalogs.MonthEndClosingOperations.GetPredefinedItemName(String[StageColumn]);
	EndDo;
	
EndProcedure

// Returns the names of files to upload statuses and explanations of the operations of closing the month.
//
Function UploadFileNamesStateOfStagesForTesting(Period)
	
	FileNameSuffix = "_" + Format(Period, "DF=MM-yy") + ".mxl";
	
	Result = New Structure;
	
	Result.Insert("TableStages",
		"ClosingMonth_StagesTable" + FileNameSuffix);
	Result.Insert("TableOfGroupedExplanations",
		"ClosingOfMonth_TableOfGroupedExplanations" + FileNameSuffix);
	
	Return Result;
	
EndFunction

// Checks for the presence of files for uploading States/explanations of month closing operations.
//
Procedure CheckPresenceOfUploadFileStateOfStagesForTesting(Directory, FileName, FileAssignment, MessageTexts_)
	
	Files = FindFiles(Directory, FileName, False);
	
	If Files.Count() <> 1 Then
		
		MessageTexts_.Add(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể tìm thấy tệp tải lên bảng %1 ""%2""';
					|ru = 'Не найден файл выгрузки таблицы %1 ""%2""';
					|en = 'Export file ""%2"" of table %1 was not found'; fa = 'Export file ""%2"" of table %1 was not found';
					|it = 'Non trovato il file di importazione della tabella %1 ""%2""';
					|pl = 'Nie znaleziono pliku wysłania tabeli %1 ""%2""';
					|tr = 'Yükleme tablosu dosyası %1 ""%2"" bulunamadı'"),
				FileAssignment,
				Directory + FileName));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Debug

Function DoNotCheckBlockingOfIncomingDataWhenUpdatingInformationSecurity()
	
	ParameterValues = CalculationOfCostCached.ValuesOfTechnologicalParameters(
		Catalogs.MonthEndClosingOperations.EmptyRef());
		
	Return ParameterValues.DoNotCheckBlockingOfIncomingDataWhenUpdatingInformationSecurity;
	
EndFunction

#EndRegion

#EndRegion

#Region MethodsForBlockingPeriod

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "GeneratedJobsOfMonthEndClosing" Then
		ClearGeneratedTasksSessionParameter();
		SpecifiedParameters.Add("GeneratedJobsOfMonthEndClosing");
	EndIf;
	
EndProcedure

// Clear the generated tasks session parameter.
//
// Parameters:
//  DocumentBeingModified - DocumentRef, Undefined - Document to change
Procedure ClearGeneratedTasksSessionParameter(DocumentBeingModified = Undefined)
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(DocumentBeingModified) Then
		SessionParameters.GeneratedJobsOfMonthEndClosing = New ValueStorage(Undefined);
		Return;
	EndIf;
	
	StructureOfData = SessionParameters.GeneratedJobsOfMonthEndClosing.Get();
	
	If StructureOfData = Undefined Then
		Return;
	EndIf;
	
	DocumentsBeingModified = StructureOfData.DocumentsBeingModified; //Array
	
	If DocumentsBeingModified.Count() = 1 Then
		SessionParameters.GeneratedJobsOfMonthEndClosing = New ValueStorage(Undefined);
		Return;
	EndIf;
	
	DocumentsBeingModified.Delete(DocumentsBeingModified.Find(DocumentBeingModified));
	
	SessionParameters.GeneratedJobsOfMonthEndClosing = New ValueStorage(StructureOfData);
	
EndProcedure

// Initialize the generated tasks session parameter.
// 
// Parameters:
//  Document - DocumentObject - Document to change
Procedure InitializeGeneratedTasksSessionParameter(Document) Export
	
	SetPrivilegedMode(True);
	
	StructureOfData = SessionParameters.GeneratedJobsOfMonthEndClosing.Get();
	
	If StructureOfData = Undefined Then
		
		TaskTable = New ValueTable;
		TaskTable.Columns.Add("Organization");
		TaskTable.Columns.Add("TaskPeriod");
		TaskTable.Columns.Add("BlockingPeriod");
		TaskTable.Columns.Add("TaskRegisterName");
		
		DocumentsBeingModified = New Array;
		
		StructureOfData = New Structure;
		StructureOfData.Insert("DocumentsBeingModified",	DocumentsBeingModified);
		StructureOfData.Insert("TaskTable", TaskTable);
		
	Else
		
		DocumentsBeingModified = StructureOfData.DocumentsBeingModified;
		
	EndIf;
	
	DocumentsBeingModified.Add(Document.Ref);
	
	SessionParameters.GeneratedJobsOfMonthEndClosing = New ValueStorage(StructureOfData);
	
EndProcedure

// Add information about the task in the blocked period.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  TaskPeriod - Date - the period of the task
//  BlockingPeriod - Date - Blocking Period
//  TaskRegisterName - String - Task Register Name
//  Cancel - Boolean - Cancel
Procedure AddInformationAboutTaskInBlockedPeriod(Organization, TaskPeriod, BlockingPeriod, TaskRegisterName, Cancel)

	SetPrivilegedMode(True);
	
	StructureOfData = SessionParameters.GeneratedJobsOfMonthEndClosing.Get();
	
	If StructureOfData = Undefined Then
		
		// The task was not generated from the Document Management module
		ErrorText = ErrorTextForRecordingTaskInBlockedPeriod(Organization, TaskPeriod, BlockingPeriod, TaskRegisterName);
		
		Common.MessageToUser(ErrorText,,,, Cancel);
		
		WriteLogEvent(
			NStr("vi = 'Thay đổi dữ liệu trong kỳ được phong tỏa';
				|ru = 'Изменение данных в заблокированном периоде';
				|en = 'Change data in the locked period'; fa = 'Change data in the locked period';
				|it = 'Изменение данных в заблокированном периоде';
				|pl = 'Change data in the locked period';
				|tr = 'Kilitlenen dönemdeki verileri değiştirme'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.InformationRegisters.Find(TaskRegisterName),
			,
			ErrorText);
		
		Return;
		
	EndIf;

	TaskTable = StructureOfData.TaskTable; //ValueTable
	
	NwRw = TaskTable.Add();
	NwRw.Organization 		  = Organization;
	NwRw.TaskPeriod 	  = BegOfMonth(TaskPeriod);
	NwRw.BlockingPeriod   = BegOfMonth(BlockingPeriod);
	NwRw.TaskRegisterName = TaskRegisterName;
	
	SessionParameters.GeneratedJobsOfMonthEndClosing = New ValueStorage(StructureOfData);
	
EndProcedure

// Check the generated tasks when conducting the document.
// 
// Parameters:
//  Document - DocumentObject - Document to change
//  Cancel - Boolean - Cancel
Procedure CheckGeneratedTasksWhenConductingDocument(Document, Cancel) Export
	
	SetPrivilegedMode(True);
	
	DocumentBeingModified = Document.Ref;
	StructureOfData    = SessionParameters.GeneratedJobsOfMonthEndClosing.Get();
	TaskTable     = StructureOfData.TaskTable; //ValueTable
	
	ClearGeneratedTasksSessionParameter(DocumentBeingModified);
	
	If TaskTable.Count() = 0 Then
		// There are no generated tasks in the blocked period
		Return;
	EndIf;
	
	// add the error to the registration Log
	TaskTable.GroupBy("Organization, TaskPeriod, BlockingPeriod, TaskRegisterName");
	TaskTable.Sort("Organization, TaskPeriod, BlockingPeriod, TaskRegisterName");
	
	ErrorsArray = New Array;
	For Each CurrRow In TaskTable Do
		
		ErrorsArray.Add(
			ErrorTextForRecordingTaskInBlockedPeriod(CurrRow.Organization, CurrRow.TaskPeriod, CurrRow.BlockingPeriod, CurrRow.TaskRegisterName));
		
	EndDo;
	
	ErrorText = NStr("vi = 'Không thể thay đổi chứng từ';
					|ru = 'Невозможно изменение документа';
					|en = 'Cannot change the document'; fa = 'Cannot change the document';
					|it = 'Невозможно изменение документа';
					|pl = 'Cannot change the document';
					|tr = 'Belge düzenlenemiyor'", Common.DefaultLanguageCode()) + " "
		+ TrimAll(DocumentBeingModified) + ":" + Chars.LF
		+ StrConcat(ErrorsArray, Chars.LF);
	
	WriteLogEvent(
		NStr("vi = 'Thay đổi dữ liệu trong kỳ được phong tỏa';
			|ru = 'Изменение данных в заблокированном периоде';
			|en = 'Change data in the locked period'; fa = 'Change data in the locked period';
			|it = 'Изменение данных в заблокированном периоде';
			|pl = 'Change data in the locked period';
			|tr = 'Kilitlenen dönemdeki verileri değiştirme'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		DocumentBeingModified.Metadata(),
		DocumentBeingModified,
		ErrorText);
	
	// We will report the error to the user
	TaskTableIsCollapsed = TaskTable.Copy(, "Organization, TaskPeriod, BlockingPeriod");
	TaskTableIsCollapsed.GroupBy("Organization, TaskPeriod, BlockingPeriod");
	TaskTableIsCollapsed.Sort("Organization, TaskPeriod, BlockingPeriod");
	
	CurrentCompany = Undefined;
	
	For Each CurrRow In TaskTableIsCollapsed Do
		
		If CurrentCompany <> CurrRow.Organization Then
			
			// We will inform you about the earliest period of tasks generated by the document
			ErrorText = ErrorTextForRecordingTaskInBlockedPeriod(CurrRow.Organization, CurrRow.TaskPeriod, CurrRow.BlockingPeriod,, DocumentBeingModified);
			
			Common.MessageToUser(ErrorText,,,, Cancel);
		
			CurrentCompany = CurrRow.Organization;
			
		EndIf;
		
	EndDo;
	
	StructureOfData = SessionParameters.GeneratedJobsOfMonthEndClosing.Get();
	
	If StructureOfData <> Undefined Then

		TaskTable = StructureOfData.TaskTable; //ValueTable
		TaskTable.Clear();
		
		SessionParameters.GeneratedJobsOfMonthEndClosing = New ValueStorage(StructureOfData);
		
	EndIf;
	
EndProcedure

// The text of the task recording error in the blocked period.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  TaskPeriod - Date - the period of the task
//  BlockingPeriod - Date - Blocking Period
//  TaskRegisterName - String - Task Register Name
//  DocumentBeingModified - DocumentRef - Document to change
// 
// Returns:
//  String - Error Text For Recording A Task In A Blocked Period
Function ErrorTextForRecordingTaskInBlockedPeriod(Organization, TaskPeriod, BlockingPeriod, TaskRegisterName = Undefined, DocumentBeingModified = Undefined) Export
	
	If Not ValueIsFilled(TaskRegisterName) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thay đổi chứng từ ""%1"" của doanh nghiệp %2 trong kỳ %3: đã thiết lập phong tỏa tránh các thay đổi trước kỳ %4';
				|ru = 'Невозможно изменение документа ""%1"" организации %2 в периоде %3: установлена блокировка от изменения до периода %4';
				|en = 'Cannot change the %1 document of the %2 company in the period %3: the lock from changes is set until %4'; fa = 'Cannot change the %1 document of the %2 company in the period %3: the lock from changes is set until %4';
				|it = 'Невозможно изменение документа ""%1"" организации %2 в периоде %3: установлена блокировка от изменения до периода %4';
				|pl = 'Cannot change the %1 document of the %2 company in the period %3: the lock from changes is set until %4';
				|tr = '%2 iş yerinin ""%1"" belgesi %3 döneminde değiştirilemiyor: %4 dönemine kadar değişiklik kilitli'", Common.DefaultLanguageCode()),
			DocumentBeingModified,
			Organization,
			MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(TaskPeriod),
			MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(EndOfMonth(BlockingPeriod) + 1));
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thêm bản ghi vào biểu ghi %1 theo doanh nghiệp %2 trong kỳ %3: đã thiết lập phong tỏa tránh các thay đổi trước kỳ %4';
				|ru = 'Невозможно добавить запись в регистр %1 по организации %2 в периоде %3: установлена блокировка от изменения до периода %4';
				|en = 'Cannot add a record to the %1 register by the %2 company in the period %3: the lock from changes is set until %4'; fa = 'Cannot add a record to the %1 register by the %2 company in the period %3: the lock from changes is set until %4';
				|it = 'Невозможно добавить запись в регистр %1 по организации %2 в периоде %3: установлена блокировка от изменения до периода %4';
				|pl = 'Cannot add a record to the %1 register by the %2 company in the period %3: the lock from changes is set until %4';
				|tr = '%2 iş yerinde %3 döneminde %1 defterine kayıt eklenemiyor: %4 dönemine kadar değişiklik kilitli'", Common.DefaultLanguageCode()),
			Metadata.InformationRegisters[TaskRegisterName].Presentation(),
			Organization,
			MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(TaskPeriod),
			MonthEndTransactionsClientServer.PeriodRepresentationMonthYear(EndOfMonth(BlockingPeriod) + 1));
	EndIf;
	
	Return ErrorText;
	
EndFunction

// Disable the period lock check for a set of records.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet - Recordset
Procedure DisablePeriodCheckBlockingForSetOfRecords(RecordSet) Export
	
	RecordSet.AdditionalProperties.Insert("DisablePeriodBlockingVerification", True);
	
EndProcedure

// Check the period lock for a set of records.
// 
// Parameters:
//  RecordSet - InformationRegisterRecordSet.JobsForCalculatingCost, InformationRegisterRecordSet.JobsForMonthEndClosing, InformationRegisterRecordSet.JobsForCalculatingFixedAssetDepreciation, InformationRegisterRecordSet.JobsForCalculatingNonCurrentAssetCost, InformationRegisterRecordSet.JobsForAllocatingCustomersARAP, InformationRegisterRecordSet.JobsForGeneratingFixedAssetRecords, InformationRegisterRecordSet.JobsForAllocatingVendorsARAP, InformationRegisterRecordSet.DocumentPostingInFinancialAccounting, InformationRegisterRecordSet.JobsForGeneratingVATRecords, InformationRegisterRecordSet.JobsForCalculatingIntangibleAssetAmortization - Recordset
// 
// Returns:
//  Boolean - Checking The Period Lock For A Set Of Records
Function CheckingPeriodLockForSetOfRecords(RecordSet) Export

	Return Not RecordSet.AdditionalProperties.Property("DisablePeriodBlockingVerification");
	
EndFunction

// Organizations available for calculation.
// 
// Parameters:
//  Period - Date - Period
//  CompanyArray - Array of CatalogRef.Companies - array of organizations
// 
// Returns:
//  Array of CatalogRef.Companies - Companies available For Settlement
Function CompaniesAvailableForSettlement(Period, CompanyArray) Export
	
	DatesByCompany = InformationRegisters.SetUpLockFromChanges.BlockingDatesByCompanies(CompanyArray);
	AvailableCompanies = New Array;
	
	For Each CurrentCompany In CompanyArray Do
		
		LockUntil = DatesByCompany.Get(CurrentCompany);

		If Not ValueIsFilled(LockUntil) Or BegOfMonth(Period) > LockUntil Then
			AvailableCompanies.Add(CurrentCompany);
		EndIf;
		
	EndDo;
	
	Return AvailableCompanies;
	
EndFunction

// There is a right to manage the blocking of the period.
// 
// Returns:
//  Boolean - You Have The Right To Manage The Blocking Of The Period
Function YouHaveRightToManageBlockingOfPeriod() Export
	
	Return AccessRight("Update", Metadata.InformationRegisters.SetUpLockFromChanges);
	
EndFunction

// check the Status change in the record.
// 
// Parameters:
//  Source - InformationRegisterRecordSet.JobsForCalculatingCost, InformationRegisterRecordSet.JobsForMonthEndClosing, InformationRegisterRecordSet.JobsForCalculatingFixedAssetDepreciation, InformationRegisterRecordSet.JobsForCalculatingNonCurrentAssetCost, InformationRegisterRecordSet.JobsForAllocatingCustomersARAP, InformationRegisterRecordSet.JobsForGeneratingFixedAssetRecords, InformationRegisterRecordSet.JobsForAllocatingVendorsARAP, InformationRegisterRecordSet.DocumentPostingInFinancialAccounting, InformationRegisterRecordSet.JobsForGeneratingVATRecords, InformationRegisterRecordSet.JobsForCalculatingIntangibleAssetAmortization - Source
//  OldSourceFieldValues - ValueTable - Old Source Field Values
//  Organization - CatalogRef.Companies - Organization
//  Period - Date - Period
// 
// Returns:
//  Boolean - Check the Status Change In the Record
Function CheckStatusChangeInRecord(Source, OldSourceFieldValues, Organization, Period)
	
	Result = True;
	
	If Not ValueIsFilled(OldSourceFieldValues) Then
		Return Result;
	EndIf;
		
	OldLines = OldSourceFieldValues.FindRows(New Structure("Organization, DateRecord", Organization, Period));
	
	If OldLines.Count() = 1 Then
		
		SourceTable2 = Source.Unload(, "Organization, DateRecord, Status");
		NewLines = SourceTable2.FindRows(New Structure("Organization, DateRecord", Organization, Period));

		If NewLines.Count() = 1 Then
			If OldLines[0].Status = NewLines[0].Status Then
				Result = False;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "MonthEndTransactionsServer.ProcessDataForMigrationToNewVersion";
	Handler.Version = "*";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("74d98af1-b1ee-4187-ab5e-67accc16c9cf");
	Handler.UpdateDataFillingProcedure = "MonthEndTransactionsServer.RegisterDataForProcessing";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ExecuteInMasterNodeOnly = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Xóa dữ liệu không sử dụng trong các biểu ghi dịch vụ của cơ chế đóng tháng';
							|ru = 'Очищает неиспользуемые данные в служебных регистрах механизма закрытия месяца';
							|en = 'Clears unused data in internal registers of the month-end closing'; fa = 'Clears unused data in internal registers of the month-end closing';
							|it = 'Очищает неиспользуемые данные в служебных регистрах механизма закрытия месяца';
							|pl = 'Clears unused data in internal registers of the month-end closing';
							|tr = 'Ay kapatma mekanizmasının servis kayıtlarındaki kullanılmayan verileri temizler'");
	
	ReadableChangeable = RegistersProcessedWhenUpdatingInformationSecurity();
	
	Handler.ObjectsToRead = StrConcat(ReadableChangeable, ",");
	Handler.ObjectsToChange = Handler.ObjectsToRead;

EndProcedure

// Registers data for updating
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataForProcessing(Parameters) Export

	Editable1 = RegistersProcessedWhenUpdatingInformationSecurity();
	
	Query = New Query;
	Query.SetParameter("UnusedOperations", Catalogs.MonthEndClosingOperations.UnusedOperations());
	Query.SetParameter("CurrentVersion", TrimAll(Metadata.Version));
	
	// The order of the requests must correspond to the order of the registers in the registers being processed by the update()
	Query.Text =
	"SELECT DISTINCT
	|	T.Operation
	|FROM
	|	InformationRegister.PerformMonthEndClosingOperations AS T
	|WHERE
	|	T.Operation IN (&UnusedOperations)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Operation
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS T
	|WHERE
	|	T.Operation IN (&UnusedOperations)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.VersionNumber AS VersionNumber
	|FROM
	|	InformationRegister.LotAccountingDataCache AS T
	|WHERE
	|	T.VersionNumber <> &CurrentVersion
	|";
	
	QueryResult = Query.ExecuteBatch();
	
	For RegisterNumber = 0 To 2 Do
		
		AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
		AdditionalParameters.IsIndependentInformationRegister = True;
		AdditionalParameters.FullRegisterName = Editable1[RegisterNumber];
		
		InfobaseUpdate.MarkForProcessing(Parameters, QueryResult[RegisterNumber].Unload(), AdditionalParameters);
		
	EndDo;
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Editable1 = RegistersProcessedWhenUpdatingInformationSecurity();
	ProcessingCompleted = True;
	
	For RegisterNumber = 0 To 2 Do
		
		FullRegisterName = Editable1[RegisterNumber];
		ShortRegisterName = Metadata.FindByFullName(FullRegisterName).Name;
		DimensionName = ?(RegisterNumber = 2, "VersionNumber", "Operation");
		
		Selection = InfobaseUpdate.SelectStandaloneInformationRegisterDimensionsToProcess(Parameters.Queue, FullRegisterName);
		
		While Selection.Next() Do
			
			BeginTransaction();
			
			Try
				
				DimensionValue = Selection[DimensionName];
				Block = New DataLock;
				
				// Blocking the inventory allocation register.
				LockItem = Block.Add(FullRegisterName);
				LockItem.SetValue(DimensionName, DimensionValue);
				LockItem.Mode = DataLockMode.Shared;
				
				Block.Lock();
				
				RecordSet = InformationRegisters[ShortRegisterName].CreateRecordSet();
				RecordSet.Filter[DimensionName].Set(DimensionValue, True);
				
				InfobaseUpdate.WriteRecordSet(RecordSet, True);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				ProcessingCompleted = False;
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Undefined);
				
			EndTry;
			
		EndDo;
		
	EndDo;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Function RegistersProcessedWhenUpdatingInformationSecurity()

	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.PerformMonthEndClosingOperations.FullName());
	Editable1.Add(Metadata.InformationRegisters.JobsForMonthEndClosing.FullName());
	Editable1.Add(Metadata.InformationRegisters.LotAccountingDataCache.FullName());
	
	Return Editable1;
	
EndFunction

#EndRegion

#Region Testing

// Used for auto-testing - allows you to disable month closing checks, which allows you to significantly speed up testing.
// 
// Returns:
//  Boolean - Simplified Auto-Testing
Function SimplifiedAutoTesting() Export
	Return False;
EndFunction

#EndRegion

#EndRegion
