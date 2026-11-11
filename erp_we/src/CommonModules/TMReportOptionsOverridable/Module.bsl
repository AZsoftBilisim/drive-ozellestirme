#Region Public

// See ReportsOptionsOverridable.DefineSectionsWithReportOptions
Procedure DefineSectionsWithReportOptions(Sections) Export
	If Not GetFunctionalOption("BaseVersion") Then
		Sections.Add(ReportsOptionsClientServer.HomePageID(),
			NStr("vi = 'Chính';
				|ru = 'Главное';
				|en = 'Main'; fa = 'اصلی';
				|it = 'Principale';
				|pl = 'Main';
				|tr = 'Genel'"));
		
		Sections.Add(Metadata.Subsystems.CRMAndMarketing,
			NStr("vi = 'Báo cáo CRM và marketing';
				|ru = 'Отчеты по CRM и маркетингу';
				|en = 'CRM and marketing reports'; fa = 'گزارش‌های CRM و بازاریابی';
				|it = 'Report relativi ai CRM e marketing';
				|pl = 'Raporty wg CRM i marketingowe';
				|tr = 'CRM ve pazarlama raporları'"));
		
		Sections.Add(Metadata.Subsystems.Purchases,
			NStr("vi = 'Báo cáo mua hàng';
				|ru = 'Отчеты по закупкам';
				|en = 'Purchasing reports'; fa = 'گزارش‌های خرید';
				|it = 'Report di acquisto';
				|pl = 'Raporty według zakupów';
				|tr = 'Satın alma raporları'"));
		
		Sections.Add(Metadata.Subsystems.TreasuryAndARAPAccounting,
			NStr("vi = 'Báo cáo ngân quỹ';
				|ru = 'Отчеты по казначейству';
				|en = 'Treasury reports'; fa = 'گزارش‌های خزانه‌داری';
				|it = 'Report relativi alla gestione di tesorerie';
				|pl = 'Raporty według skarbu';
				|tr = 'Hazine raporları'"));
		
		Sections.Add(Metadata.Subsystems.Sales,
			NStr("vi = 'Báo cáo bán hàng';
				|ru = 'Отчеты по продажам';
				|en = 'Sales reports'; fa = 'گزارش‌های فروش';
				|it = 'Report di vendita';
				|pl = 'Raporty dotyczące sprzedaży';
				|tr = 'Satış raporları'"));
		
		Sections.Add(Metadata.Subsystems.Warehouse,
			NStr("vi = 'Báo cáo theo kho';
				|ru = 'Отчеты по складу';
				|en = 'Warehouse reports'; fa = 'گزارش‌های انبار';
				|it = 'Report di magazzino';
				|pl = 'Raporty według magazynu';
				|tr = 'Ambar raporları'") );
		
		Sections.Add(Metadata.Subsystems.FinancialResultAndControlling,
			NStr("vi = 'Báo cáo kết quả kinh doanh';
				|ru = 'Отчеты по финансовому результату';
				|en = 'Profitability and cost reports'; fa = 'گزارش‌های سودآوری و بهای تمام‌شده';
				|it = 'Report relativi al risultato finanziario';
				|pl = 'Raporty według rezultatów finansowych';
				|tr = 'Kârlılık ve maliyet raporları'"));
		If GetFunctionalOption("TradeManagement") Then
			Sections.Add(Metadata.Subsystems.Find("Planning"),
					NStr("vi = 'Báo cáo theo kế hoạch';
						|ru = 'Отчеты по планированию';
						|en = 'Planning reports'; fa = 'Planning reports';
						|it = 'Report per pianificazione';
						|pl = 'Raporty według planowania';
						|tr = 'Planlama raporları'"));
		Else
			Sections.Add(Metadata.Subsystems.BudgetingAndPlanning,
				NStr("vi = 'Báo cáo ngân sách và kế hoạch';
					|ru = 'Отчеты по бюджетированию и планированию';
					|en = 'Budgeting and planning reports'; fa = 'گزارش‌های بودجه‌بندی و برنامه‌ریزی';
					|it = 'Report budgeting e pianificazione';
					|pl = 'Raporty według budżetowania i planowania';
					|tr = 'Bütçeleme ve planlama raporları'"));
		EndIf;
		Sections.Add(Metadata.Subsystems.Production,
			NStr("vi = 'Báo cáo sản xuất';
				|ru = 'Отчеты по производству';
				|en = 'Manufacturing reports'; fa = 'گزارش‌های تولید';
				|it = 'Report di produzione';
				|pl = 'Raporty według produkcji';
				|tr = 'Üretim raporları'"));
			
		Sections.Add(Metadata.Subsystems.NonCurrentAssets,
			NStr("vi = 'Báo cáo tài sản dài hạn';
				|ru = 'Отчеты по внеоборотным активам';
				|en = 'Fixed and intangible assets reports'; fa = 'گزارش‌های دارایی‌های ثابت و نامشهود';
				|it = 'Report relativi alle attività non correnti';
				|pl = 'Raporty według aktywów nieobrotowych';
				|tr = 'Duran varlıklara ilişkin tablolar'"));
		Sections.Add(Metadata.Subsystems.InternationalFinancialAccounting,
			NStr("vi = 'Báo cáo kế toán quốc tế';
				|ru = 'Отчеты по международному финансовому учету';
				|en = 'General ledger reports'; fa = 'گزارش‌های دفتر کل';
				|it = 'Report per contabilità finanziaria internazionale';
				|pl = 'Raporty według księgowości międzynarodowej';
				|tr = 'Uluslararası kârlılık ve maliyet raporları'"));
	EndIf;
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions
Procedure CustomizeReportsOptions(Settings) Export
	DisplayReportOptions = False;
	
	UseProduction = GetFunctionalOption("UseProduction");
	UseMultipleKindsOfProducts = GetFunctionalOption("UseMultipleKindsOfProducts");
	
	RebatesServer.CustomizeReportsOptions(Settings);
	GoodsDelivery.CustomizeReportsOptions(Settings);
	VATAccountingERP.CustomizeReportsOptions(Settings);
	NonCurrentAssets.CustomizeReportsOptions(Settings);
	LeasedAssetAccounting.CustomizeReportsOptions(Settings);
	RMManagement.CustomizeReportsOptions(Settings);
	FinancialAccountingOfGeneralPurpose.CustomizeReportsOptions(Settings);
	Reports.ABCXYZAnalysisOfInventory.CustomizeReportOptions(Settings);
	Reports.ABCXYZCustomersAllocation.CustomizeReportOptions(Settings);
	Reports.ReceiptsAndExpendituresAnalysis.CustomizeReportOptions(Settings);
	
	#Region EventLogAnalysis
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.EventLogAnalysis);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UserActivity");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UsersActivityAnalysis");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "EventLogMonitor");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ScheduledJobsDuration");
	#EndRegion
	
	Reports.CustomerRankingABC.CustomizeReportOptions(Settings);
	Reports.FulfillmentAnalysisOfProductRange.CustomizeReportOptions(Settings);
	Reports.BCGMatrix.CustomizeReportOptions(Settings);
	Reports.CustomerLoyaltyXYZ.CustomizeReportOptions(Settings);
	Reports.AnalysisOfStockBalanceOfCompanies.CustomizeReportOptions(Settings);
	Reports.InitialRequestAnalysis.CustomizeReportOptions(Settings);
	Reports.PrimaryDemandAnalysis.CustomizeReportOptions(Settings);
	Reports.CustomerComplaintsAnalysis.CustomizeReportOptions(Settings);
	Reports.AnalysisOfReasonsForSalesOrderCancellation.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.AnalysisOfReasonsForPurchaseOrderCancellation.CustomizeReportOptions(Settings);
	Reports.AnalysisOfReasonsForPurchaseOrderCancellationAccordingToDocument.CustomizeReportOptions(Settings);
	Reports.AnalysisOfReasonsForLosingOpportunities.CustomizeReportOptions(Settings);
	Reports.InitialWIPOpeningBalancesAllocationAnalysis.CustomizeReportOptions(Settings);
	Reports.ReleasedProductsCostAnalysis.CustomizeReportOptions(Settings);
	Reports.ProductsCostTree.CustomizeReportOptions(Settings);
	Reports.InventoryCost.CustomizeReportOptions(Settings);
	Reports.FinancialResultsAnalysis.CustomizeReportOptions(Settings);
	Reports.PriceAnalysis.CustomizeReportOptions(Settings);
	Reports.AnalysisOfSalesRepresentativePerformance.CustomizeReportOptions(Settings);
	Reports.AnalysisOfVariancesInGoodsCost.CustomizeReportOptions(Settings);
	Reports.MaterialAndLaborAllocationBase.CustomizeReportOptions(Settings);
	Reports.ProductionCostsAllocationBase.CustomizeReportOptions(Settings);
	Reports.BonusPoints.CustomizeReportOptions(Settings);
	Reports.StatusOfCashShifts.CustomizeReportOptions(Settings);
	#Region BudgetReport
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BudgetReport);
	DisableReport(DescriptionOfReport);
	#EndRegion
	Reports.GrossProfitByPaidCustomerInvoices.CustomizeReportOptions(Settings);
	Reports.BankStatementReconciliation.CustomizeReportOptions(Settings);
	Reports.CashStatement.CustomizeReportOptions(Settings);
	Reports.CashPaysheetAtAdvanceHolder.CustomizeReportOptions(Settings);
	Reports.CashFlow.CustomizeReportOptions(Settings);
	Reports.LotList.CustomizeReportOptions(Settings);
	Reports.TransferredReturnablePackagingList.CustomizeReportOptions(Settings);
	Reports.ReceivedReturnablePackagingList.CustomizeReportOptions(Settings);
	Reports.ItemsBatchList.CustomizeReportOptions(Settings, UseProduction);
	Reports.WarehouseStock.CustomizeReportOptions(Settings);
	Reports.AnalysisOfPassingGoodsQualityControl.CustomizeReportOptions(Settings);
	Reports.WarehouseStockInItemPrices.CustomizeReportOptions(Settings);
	Reports.CompanyGoodsStock.CustomizeReportOptions(Settings);
	Reports.CompanyGoodsStockInItemPrices.CustomizeReportOptions(Settings);
	Reports.AccountsPayablesAndReceivablesByIntercompany.CustomizeReportOptions(Settings);
	Reports.CustomersARAPStatement.CustomizeReportOptions(Settings);
	Reports.PartnersARAPAccountingStatement.CustomizeReportOptions(Settings);
	Reports.ProbabilityForecast.CustomizeReportOptions(Settings);
	Reports.SalesPipeline.CustomizeReportOptions(Settings);
	Reports.PerformanceOfBudgetProcessTasks.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.FulfillmentOfRegularConditionsOfTermsOfSales.CustomizeReportOptions(Settings);
	Reports.ProductsRelease.CustomizeReportOptions(Settings);
	Reports.RevenueAndCOGS.CustomizeReportOptions(Settings, UseMultipleKindsOfProducts);
	Reports.RevenueAndCOGSFromRetail.CustomizeReportOptions(Settings);
	Reports.ProductionSchedule2_2.CustomizeReportOptions(Settings);
	Reports.StandardProductionScheduleByOrders.CustomizeReportOptions(Settings);
	
	Reports.StateOfProductionOrderReadiness.CustomizeReportOptions(Settings);
	Reports.ItemBatchMovement.CustomizeReportOptions(Settings, UseProduction);
	
	
	Reports.AccountsReceivable.CustomizeReportOptions(Settings);
	Reports.AccountsReceivableOverduePercentage.CustomizeReportOptions(Settings);
	Reports.ObjectDemoScenarios.CustomizeReportOptions(Settings);
	Reports.ProductionStageResourceChart.CustomizeReportOptions(Settings);
	Reports.MonitorOrder.CustomizeReportOptions(Settings);
	Reports.StartingLotProductionChart.CustomizeReportOptions(Settings);
	Reports.ConnectedProductionStagesChart.CustomizeReportOptions(Settings);
	Reports.TrendsOfItemPrices.CustomizeReportOptions(Settings);
	Reports.TrendsOfItemPrices2_5.CustomizeReportOptions(Settings);
	Reports.PriceChangeTrendsOfVendorPartNumbers.CustomizeReportOptions(Settings);
	Reports.TrendsOfSalesRepresentativePerformanceIndicators.CustomizeReportOptions(Settings);
	Reports.IncidentTrends.CustomizeReportOptions(Settings);
	Reports.AvailabilityOfTargetValueAnalysisOptions.CustomizeReportOptions(Settings);
	Reports.PartnerProfile.CustomizeReportOptions(Settings);
	Reports.IncidentDuplicates.CustomizeReportOptions(Settings);
	Reports.BlockedBins.CustomizeReportOptions(Settings);

	#Region HungTasks
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.HungTasks);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Nhiệm vụ không thể thực hiện do chưa điền danh sách vai trò và người thực hiện.';
									|ru = 'Задачи, которые не могут быть выполнены из-за того, что не заполнен список ролей и исполнителей.';
									|en = 'Tasks that cannot be completed because of unfilled list of roles and assignees.'; fa = 'Tasks that cannot be completed because of unfilled list of roles and assignees.';
									|it = 'Task che non possono essere eseguiti a causa della mancata compilazione dell''elenco dei ruoli e assegnatari.';
									|pl = 'Zadania, które nie mogą być wykonane z powodu tego, że nie jest wypełniona lista roli i wykonawców.';
									|tr = 'Roller ve atanan listesi tamamlanmadığı için tamamlanamayan görevler.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UnassignedTasksByPerformers");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UnassignedTasksByAddressingObjects");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "OverdueTasks");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UnassignedTasksSummary");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	#EndRegion
	Reports.LoadOfWorkCenterTypes.CustomizeReportOptions(Settings);
	Reports.EquipmentLoadAccordingToProductionScheduleModel.CustomizeReportOptions(Settings);
	Reports.ProductionOperationParameters.CustomizeReportOptions(Settings);
	Reports.ProductionOperationProgress.CustomizeReportOptions(Settings);
	#Region Jobs
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.Jobs);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "JobsList");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	#EndRegion
	
	#Region Tasks
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.Tasks);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PerformerDisciplineSummary");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CurrentTasks");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	#EndRegion
	
	#Region ExpiringTasksOnDate
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ExpiringTasksOnDate);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExpiringTasksOnDate");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	#EndRegion

	Reports.CustomersAccountsReceivable.CustomizeReportOptions(Settings);
	Reports.CustomerDebtsByDeadlines.CustomizeReportOptions(Settings);
	Reports.PaymentsFromCustomersByDeadlines.CustomizeReportOptions(Settings);
	Reports.VendorsAccountsPayable.CustomizeReportOptions(Settings);
	Reports.VendorPayablesByDeadlines.CustomizeReportOptions(Settings);
	Reports.PaymentsToVendorsByDeadlines.CustomizeReportOptions(Settings);
	
	#Region PartnersPropertiesFilling
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PartnersPropertiesFilling);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Đã điền tất cả thuộc tính của khách hàng, nhà cung cấp hay chưa?
		|Cần điền bao nhiêu thuộc tính và những thuộc tính nào?';
		|ru = 'Все ли свойства клиентов, поставщиков заполнены?
		|Сколько и каких свойств нужно заполнить?';
		|en = 'Are all the customers'' and vendors'' properties filled in? 
		|How many and which properties are yet to be filled in?'; fa = 'Are all the customers'' and vendors'' properties filled in? 
		|How many and which properties are yet to be filled in?';
		|it = 'Le proprietà dei clienti e dei fornitori sono compilate?
		| Quali e quante proprietà devono essere compilate?';
		|pl = 'Czy wszystkie właściwości klientów, dostawców są wypełnione? 
		|Ile i jakich właściwości należy wypełnić?';
		|tr = 'Müşterilerin ve tedarikçilerin tüm özellikleri dolduruldu mu?
		|Kaç ve hangi özelliklerin doldurulması gerekiyor?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Các thuộc tính của khách hàng, nhà cung cấp đã được điền đến mức nào?
		|Đánh giá mức độ hoàn thiện cơ sở khách hàng.';
		|ru = 'Насколько заполнены свойства клиентов, поставщиков?
		|Оценка полноты клиентской базы.';
		|en = 'Check if customer and vendor properties are fully filled in.
		|Assess the customer base fullness.'; fa = 'Check if customer and vendor properties are fully filled in.
		|Assess the customer base fullness.';
		|it = 'Come sono compilate le proprietà dei clienti e dei fornitori?
		|Valutazione della completezza della base clienti.';
		|pl = 'Na ile są wypełnione właściwości klientów, dostawców? 
		|Ocena kompletności bazy klienckiej.';
		|tr = 'Müşterilerin, tedarikçilerin özellikleri ne kadar dolduruldu
		|İstemci tabanının tamlığının tahmini.'");
	#EndRegion
	
	Reports.GoodsPlacementInBinLocationWarehouse.CustomizeReportOptions(Settings);
	Reports.NonFinancialItemValues.CustomizeReportOptions(Settings);
	Reports.ChangeABCXYZClassificationOfCustomers.CustomizeReportOptions(Settings);
	Reports.ItemPriceIndexes.CustomizeReportOptions(Settings);
	Reports.VendorPriceIndexes.CustomizeReportOptions(Settings);
	Reports.FulfillmentOfProcurementPlan.CustomizeReportOptions(Settings);
	Reports.SalesPlanFulfillment.CustomizeReportOptions(Settings);
	Reports.ProductionPlanFulfillment.CustomizeReportOptions(Settings);
	Reports.AssemblyDisassemblyPlanFulfillment.CustomizeReportOptions(Settings);
	Reports.FulfillmentOfInventoryConsumptionPlan.CustomizeReportOptions(Settings);
	Reports.FulfillmentOfTransferAndAssemblyOrders.CustomizeReportOptions(Settings);
	Reports.EventCalendar.CustomizeReportOptions(Settings);
	Reports.ExpenseCard.CustomizeReportOptions(Settings);
	Reports.ARAPAccountingStatementByReturnablePackagingProvided.CustomizeReportOptions(Settings);
	Reports.ARAPAccountingStatementByReturnablePackagingReceived.CustomizeReportOptions(Settings);
	Reports.CustomerARAPOpenItems.CustomizeReportOptions(Settings);
	Reports.CustomerARAPOpenItems24.CustomizeReportOptions(Settings);
	Reports.VendorARAPOpenItems.CustomizeReportOptions(Settings);
	Reports.FinancialInstrumentsARAPCard.CustomizeReportOptions(Settings);
	
	#Region ContactInformation
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ContactInformation);
	DescriptionOfReport.DCSSettingsFormat = False;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	SetImportanceOfReportOption(OptionDetails, "SeeAlso");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Thông tin về khách hàng, nhà cung cấp, người quản lý chính của họ, 
		|phân loại ABC/XYZ và thông tin liên hệ.';
		|ru = 'Информация о клиентах, поставщиках, их основном менеджере, 
		|ABC/XYZ-классификации и контактной информации.';
		|en = 'Information about customers, vendors, their main sales persons, 
		|ABC/XYZ classification and contact details.'; fa = 'Information about customers, vendors, their main sales persons, 
		|ABC/XYZ classification and contact details.';
		|it = 'Informazioni sui clienti, fornitori, il loro capo manager, 
		|classificazione ABC/XYZ e informazioni di contatto.';
		|pl = 'Informacja o klientach, dostawcach, ich podstawowym menedżerze, 
		|ABC/XYZ-klasyfikacji i informacji kontaktowej.';
		|tr = 'Müşteriler, tedarikçiler, esas yöneticileri hakkında bilgiler, 
		|ABC/XYZ sınıflandırması ve iletişim bilgileri.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByContactPersons");
	SetImportanceOfReportOption(OptionDetails, "SeeAlso");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Thông tin về người liên hệ.';
									|ru = 'Информация о контактных лицах.';
									|en = 'Information on contact persons.'; fa = 'Information on contact persons.';
									|it = 'Informazioni sulle persone di contatto.';
									|pl = 'Informacja o osobach kontaktowych.';
									|tr = 'İrtibat kişileri hakkında bilgi.'");
	#EndRegion
	
	Reports.ControlOfAdvancesPaidToAdvanceHolderUnderRequest.CustomizeReportOptions(Settings);
	Reports.ControlOfProductsAndMaterialFlowOnProductionStage.CustomizeReportOptions(Settings);
	Reports.ControlOfCCDNumbersOfGoods.CustomizeReportOptions(Settings);
	Reports.CashTransactionControl.CustomizeReportOptions(Settings);
	Reports.ControlOfInventoryTransferDocumentRegistration.CustomizeReportOptions(Settings);
	Reports.ControlRegistrationOfGoodsInTransitAndUninvoicedSupplies.CustomizeReportOptions(Settings);

	
	Reports.ControlOfProductsTransferToMaterialProvider2_5.CustomizeReportOptions(Settings);
	
	Reports.ControlOfRawAndConsumableMaterialsDeliveryToToller2_5.CustomizeReportOptions(Settings);
	Reports.ControlOfCustomerInvoicesIntercompany.CustomizeReportOptions(Settings);
		
	
	Reports.ProductsDeliveryControlByToller2_5.CustomizeReportOptions(Settings);
	
	Reports.ControlOfRawAndConsumableMaterialsDeliveryFromMaterialProvider2_5.CustomizeReportOptions(Settings);
	Reports.ApplicationOfRulesForCalculationOfInventoryImpairmentProvision.CustomizeReportOptions(Settings);
	Reports.AccountsPayable.CustomizeReportOptions(Settings);
	Reports.CashFlowLimits.CustomizeReportOptions(Settings);
	#Region CashFlowLimitsForBudgetingData
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CashFlowLimitsForBudgetingData);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UseOfCashFlowLimits");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích kế hoạch-thực tế có sử dụng hạn mức trong kỳ.';
									|ru = 'План-фактный анализ использования лимитов за период.';
									|en = 'View variance analysis of cash flow limits over the period.'; fa = 'View variance analysis of cash flow limits over the period.';
									|it = 'Scostamento delle vendite dell''utilizzo dei limiti per il periodo.';
									|pl = 'Aktualny plan analiza używania limitów za okres.';
									|tr = 'Dönem için limit kullanımının plan-gerçek analizi.'");
	DisableReportOption(Settings, DescriptionOfReport, "UseOfCashFlowLimitsContext");
	#EndRegion
	
	#Region LimitsByBudgetingData
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LimitsByBudgetingData);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UsingLimitsBasedOnBudgetingData");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích kế hoạch-thực tế có sử dụng hạn mức trong kỳ.';
									|ru = 'План-фактный анализ использования лимитов за период.';
									|en = 'View variance analysis of cash flow limits over the period.'; fa = 'View variance analysis of cash flow limits over the period.';
									|it = 'Scostamento delle vendite dell''utilizzo dei limiti per il periodo.';
									|pl = 'Aktualny plan analiza używania limitów za okres.';
									|tr = 'Dönem için limit kullanımının plan-gerçek analizi.'");
	DisableReportOption(Settings, DescriptionOfReport, "UsingLimitsBasedOnBudgetingDataContext");
	#EndRegion
	Reports.BudgetingProcessmonitor.CustomizeReportOptions(Settings);
	Reports.PerformanceDashboard.CustomizeReportOptions(Settings);
	Reports.InventoryTurnover.CustomizeReportOptions(Settings);
	Reports.TrialBalanceOfAssetsAndLiabilities.CustomizeReportOptions(Settings);
	Reports.BudgetingTurnoverBalanceReport.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.TrialBalanceForBudgetBalanceItems.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.FulfillmentOfPaymentRequests.CustomizeReportOptions(Settings);
	Reports.BalancesAndMovementsOfCashInCashRegisters.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.StockAvailability.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.CompanyStockBalance.CustomizeReportOptions(Settings);
	Reports.ConsignedStockBalanceIssued.CustomizeReportOptions(Settings);
	

	Reports.ConsignedStockBalanceReceived.CustomizeReportOptions(Settings);
	
	#Region VariancesFromPurchaseConditions
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VariancesFromPurchaseConditions);
	DisableReport(DescriptionOfReport);
	#EndRegion
	
	#Region VariancesFromSalesTermsAndConditions
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VariancesFromSalesTermsAndConditions);
	DisableReport(DescriptionOfReport);
	#EndRegion
	
	Reports.CompanyNegativeStockBalance.CustomizeReportOptions(Settings);
	Reports.NegativeBalanceOfStockAndSafeStockOfCompanies.CustomizeReportOptions(Settings);
	Reports.SidedBalanceByInventoryOwnerAttributesAndCCDNumbers.CustomizeReportOptions(Settings);
	Reports.UnregisteredSurplusesAndShortagesOfGoods.CustomizeReportOptions(Settings);
	Reports.CreateReportsToConsignor.CustomizeReportOptions(Settings);
	Reports.SalesProfitabilityAssessment.CustomizeReportOptions(Settings);
	Reports.SalesProfitabilityAssessment2_5.CustomizeReportOptions(Settings);
	Reports.ErrorsInAllocatioOfWIPCostBalances.CustomizeReportOptions(Settings);
	Reports.ErrorsOfProductsCostingCalculation.CustomizeReportOptions(Settings);
	Reports.BlackListOfCustomersForDeliveryControl.CustomizeReportOptions(Settings);
	Reports.TransferredReturnablePackaging.CustomizeReportOptions(Settings);
	Reports.IntersectionOfRulesForCalculatingOfInventoryImpairmentProvision.CustomizeReportOptions(Settings);
	Reports.ProductSegmentOverlaps.CustomizeReportOptions(Settings);
	Reports.PartnersSegmentOverlaps.CustomizeReportOptions(Settings);
	Reports.PlannedAndActualCostsForRedistribution.CustomizeReportOptions(Settings);
	Reports.TargetAndActualProductsCost.CustomizeReportOptions(Settings);
	Reports.PlannedDemandForMaterials.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.PlannedDemandForSemiFinishedProducts.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.PlannedDemandForHumanResources.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.PlannedDemandForWorkCenterTypes.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.ProductionPlanProductsAndSemiFinishedProducts.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.ProductCostEstimate.CustomizeReportOptions(Settings);
	Reports.ProductStandardCostComparison.CustomizeReportOptions(Settings);
	Reports.PlannedAndActualProductionExpenseStandards.CustomizeReportOptions(Settings);
	Reports.PurchasePlan.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.VarianceAnalysisOfFinancialInstruments.CustomizeReportOptions(Settings);
	Reports.VarianceAnalysisOfFinancialInstrumentsTM.CustomizeReportOptions(Settings);
	Reports.VarianceAnalysisOfSalesRepresentativePerformanceByQuantity.CustomizeReportOptions(Settings);
	Reports.VarianceAnalysisOfSalesRepresentativePerformanceByAmount.CustomizeReportOptions(Settings);
	Reports.PaymentDisciplineOfCustomers.CustomizeReportOptions(Settings);
	Reports.RepeatedSales.CustomizeReportOptions(Settings);
	Reports.DemandForMaterialsAccordingToProductionScheduleModel.CustomizeReportOptions(Settings);
	Reports.PaymentDisciplineOfCustomers24.CustomizeReportOptions(Settings);
	Reports.PriceList.CustomizeReportOptions(Settings);
	Reports.PriceList2_5.CustomizeReportOptions(Settings);
	Reports.PriceListForOrderPlacement.CustomizeReportOptions(Settings);
	Reports.ApplicationOfItemBatch.CustomizeReportOptions(Settings, UseProduction);
	
	#Region DiscountsAppliedInDocument
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DiscountsAppliedInDocument);
	DisableReport(DescriptionOfReport);
	#EndRegion
	
	Reports.ReceivedReturnablePackaging.CustomizeReportOptions(Settings);
	
	#Region ShipmentProhibitionReasons
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ShipmentProhibitionReasons);
	DescriptionOfReport.DefineFormSettings = True;
	DisableReport(DescriptionOfReport);
	#EndRegion
	Reports.CheckRelatedBudgetBalancesAndTurnovers.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.CheckBudgetItemLinks.CustomizeReportOptions(Settings);
	Reports.IntercompanySales.CustomizeReportOptions(Settings);
	Reports.ComparisonOfSalesOfSamePeriods.CustomizeReportOptions(Settings);
	Reports.ComparisonOfSalesOfTwoPeriods.CustomizeReportOptions(Settings);
	Reports.PerformanceOfWarehouseWorkers.CustomizeReportOptions(Settings);
	Reports.ProductionCosts.CustomizeReportOptions(Settings);
	Reports.ProductionCostsByProductionLots.CustomizeReportOptions(Settings);
	Reports.ItemizedProductionCosts.CustomizeReportOptions(Settings);
	Reports.ProductionMaterialCost.CustomizeReportOptions(Settings);
	#Region OverdueTasks
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.OverdueTasks);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TasksCompletedWithDeadlineViolation");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	#EndRegion
	
	Reports.SalesRepresentativeVisitingSchedule.CustomizeReportOptions(Settings);
	Reports.IntercompanyARAP.CustomizeReportOptions(Settings);
	Reports.CustomersARAPAccounting.CustomizeReportOptions(Settings);
	Reports.PartnersARAPAccounting.CustomizeReportOptions(Settings);
	Reports.VendorsARAPAccounting.CustomizeReportOptions(Settings);
	Reports.ReceiptDrillDownByItems.CustomizeReportOptions(Settings);
	Reports.ExplanationOfTollingOrderStatus.CustomizeReportOptions(Settings);
	Reports.OvertimeCostDrillDown.CustomizeReportOptions(Settings);
	#Region BudgetReportFormulaDrillDown
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BudgetReportFormulaDrillDown);
	DescriptionOfReport.DefineFormSettings = True;
	DisableReport(DescriptionOfReport);
	#EndRegion
	Reports.LoanAndDepositContractsRegistry.CustomizeReportOptions(Settings);
	Reports.PaymentList.CustomizeReportOptions(Settings);
	Reports.IncidentRegistry.CustomizeReportOptions(Settings);
	
	
	Reports.StatementOfFutureExpenseCommitments.CustomizeReportOptions(Settings);
	Reports.ResultOfActualDataQuery.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.ResultsOfApprovalOfInventoryConsumptionOrder.CustomizeReportOptions(Settings);
	Reports.PurchaseApprovalResults.CustomizeReportOptions(Settings);
	Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer.CustomizeReportOptions(Settings);
	Reports.SaleApprovalResults.CustomizeReportOptions(Settings);
	Reports.ResultsOfProductsPriceApproval.CustomizeReportOptions(Settings);
	Reports.TestResults.CustomizeReportOptions(Settings);
	Reports.RecommendationsForImprovingBudgetEntryFormCalculationSpeed.CustomizeReportOptions(Settings);
	Reports.PlansEquilibriumERP.CustomizeReportOptions(Settings);
	Reports.PlansEquilibriumTM.CustomizeReportOptions(Settings);
	Reports.ReconciliationOfOperationalAccountingAndCost.CustomizeReportOptions(Settings);
	Reports.ARAPReconciliationWithPartners.CustomizeReportOptions(Settings);
	Reports.BudgetIndicatorLinks.CustomizeReportOptions(Settings);
	Reports.QualityCertificatesWhichAreAboutToExpire.CustomizeReportOptions(Settings);
	Reports.SaleContent.CustomizeReportOptions(Settings);
	Reports.SegmentContent.CustomizeReportOptions(Settings);
	Reports.ProductRangeState.CustomizeReportOptions(Settings);
	
	#Region DocumentFulfillmentStatus
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DocumentFulfillmentStatus);
	DisableReport(DescriptionOfReport);
	#EndRegion
	
	Reports.StatusOfCustomersARAP.CustomizeReportOptions(Settings);
	Reports.StatusOfCustomersARAPSelfServiceWorkplace.CustomizeReportOptions(Settings);
	Reports.StateOfSettlementsWithCommissionAgents.CustomizeReportOptions(Settings);
	Reports.StateOfSettlementsWithConsignors.CustomizeReportOptions(Settings);
	Reports.StateOfVendorAccountsPayable.CustomizeReportOptions(Settings);
	#Region DetailedCalculationOfBudgetTargets
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DetailedCalculationOfBudgetTargets);
	DisableReport(DescriptionOfReport);
	#EndRegion
	Reports.DetailedCalculationOfCurrencyRevaluation.CustomizeReportOptions(Settings);
	Reports.StatementOfInventoryImpairmentProvisionChange.CustomizeReportOptions(Settings);
	Reports.StatementOfInventoryImpairmentProvision.CustomizeReportOptions(Settings);
	Reports.ReferenceAddressWarehousingOfProducts.CustomizeReportOptions(Settings);
	Reports.CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts.CustomizeReportOptions(Settings);
	Reports.ComparisonOfPartnersSegments.CustomizeReportOptions(Settings);
	Reports.ProductRangeAndSalesTrends.CustomizeReportOptions(Settings);
	Reports.ComparativeAnalysisOfManagerPerformanceIndicators.CustomizeReportOptions(Settings);
	Reports.IncidentStatistics.CustomizeReportOptions(Settings);
	Reports.ProductionOrderStructure2_2.CustomizeReportOptions(Settings);
	Reports.ProductionOrderStructureDynamic.CustomizeReportOptions(Settings);
	Reports.CapitalizationExpenseStructure.CustomizeReportOptions(Settings);
	Reports.ItemsBatchStructure.CustomizeReportOptions(Settings, UseProduction);
	Reports.RouteSheetChart.CustomizeReportOptions(Settings);
	Reports.ProductRangeCompleteness.CustomizeReportOptions(Settings);
	Reports.CurrentAssortmentQuota.CustomizeReportOptions(Settings);
	Reports.InventorySchedule.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.GoodsInStorageBins.CustomizeReportOptions(Settings);
	Reports.GoodsForPicking.CustomizeReportOptions(Settings);
	Reports.GoodsToReceive.CustomizeReportOptions(Settings);
	Reports.GoodsInWarehousesByShelfLives.CustomizeReportOptions(Settings);
	Reports.GoodsForIssue.CustomizeReportOptions(Settings);
	Reports.GoodsTransferredToCommissionAgent.CustomizeReportOptions(Settings);
	Reports.GoodsTransferredToCommissionAgent2_5.CustomizeReportOptions(Settings);
	Reports.ShipmentAndReturnReferenceStatement.CustomizeReportOptions(Settings);

	
	Reports.RawAndConsumableMaterialsDeliveredToTollers2_5.CustomizeReportOptions(Settings);
	Reports.GoodsAcceptedForProcessing2_5.CustomizeReportOptions(Settings);
	Reports.GoodsReceivedByCommissionAgent.CustomizeReportOptions(Settings);
	Reports.GoodsReceivedForSafekeeping.CustomizeReportOptions(Settings);
	Reports.GoodsWithExpiringCertificates.CustomizeReportOptions(Settings);
	Reports.SupplySchemeGoods.CustomizeReportOptions(Settings);
	Reports.PurchaseConditions.CustomizeReportOptions(Settings);
	Reports.SalesTermsAndConditions.CustomizeReportOptions(Settings);
	Reports.SalesTermsAndConditions2_5.CustomizeReportOptions(Settings);
	Reports.ActualProductCost.CustomizeReportOptions(Settings);
	Reports.BalanceSheetStatement.CustomizeReportOptions(Settings);
	Reports.BalanceSheetStatementControl.CustomizeReportOptions(Settings);
	Reports.FinancialCondition.CustomizeReportOptions(Settings);
	Reports.RMProgress.CustomizeReportOptions(Settings);
	Reports.EfficiencyOfCustomerOpportunities.CustomizeReportOptions(Settings);
	Reports.LotsInProduction.CustomizeReportOptions(Settings);
	Reports.FinancialInstrumentsARAPStatement.CustomizeReportOptions(Settings);
	Reports.DemandsForCreationOfProductionStages.CustomizeReportOptions(Settings);
	Reports.DiscountedDebtStatement.CustomizeReportOptions(Settings);
	
	#Region DetailedCalculationOfDiscountingInterestExpenseAccrual
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DetailedCalculationOfDiscountingInterestExpenseAccrual);
	DescriptionOfReport.LongDesc = NStr("vi = 'Xác định số tiền chi phí tính chiết khấu theo phần trăm công nợ phải trả nhà cung cấp.';
										|ru = 'Определение суммы процентных расходов дисконтирования кредиторской задолженности поставщикам.';
										|en = 'Determine the amount of discounting interest expenses of accounts payable to vendors.'; fa = 'Determine the amount of discounting interest expenses of accounts payable to vendors.';
										|it = 'La definizione dell''importo delle spese di interessi di sconto dei debiti verso i fornitori.';
										|pl = 'Określenie kwoty kosztów odsetkowych dyskontowania zobowiązań dostawcom.';
										|tr = 'Tedarikçilere ödenecek iskonto edilmiş borçlar için faiz gideri tutarının belirlenmesi.'");
	#EndRegion

	#Region DetailedCalculationOfDiscountingInterestExpenseWriteOff
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DetailedCalculationOfDiscountingInterestExpenseWriteOff);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DetailedCalculationOfDiscountingInterestExpenseWriteOff");
	OptionDetails.LongDesc = NStr("vi = 'Xác định số tiền ghi giảm chi phí tính chiết khấu theo phần trăm trong tháng chỉ ra
	|có tính đến sự thay đổi điều kiện thanh toán và tỷ lệ tính chiết khấu, tiến hành thanh toán và điều chỉnh.';
	|ru = 'Определение суммы списания процентных расходов дисконтирования на указанный месяц
	|с учетом изменения условий оплаты и ставки дисконтирования, проведения оплаты и корректировки.';
	|en = 'Determine the write-off amount of discounting interest expenses for the specified month
	|considering changes in payment terms, discounting rates, payment transactions, and adjustments.'; fa = 'Determine the write-off amount of discounting interest expenses for the specified month
	|considering changes in payment terms, discounting rates, payment transactions, and adjustments.';
	|it = 'La definizione dell''importo delle spese di interessi di sconto per il mese indicato
	|con calcolo della modifica delle condizioni di pagamento e dell''aliquota di sconto, esecuzione pagamenti e correzione.';
	|pl = 'Określenie kwoty rozchodu kosztów odsetkowych dyskontowania na podany miesiąc
	|z uwzględnieniem zmiany warunków płatności i stawki dyskontowania, zatwierdzenia płatności i korekty.';
	|tr = 'Belirtilen aya ait iskonto edilmiş faiz giderlerinden kaydı düşürülecek tutarın
	|ödeme şartlarındaki ve iskonto oranındaki değişiklikler dikkate alınarak belirlenmesi, ödemelerin ve düzeltmelerin yapılması.'");
	OptionDetails.Enabled = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ContextOption_");
	OptionDetails.Enabled = False;
	#EndRegion
	#Region ReferenceCalculationDiscountingOfProvisionsAndContingentLiabilities
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DetailedCalculationOfDiscountingOfProvisionsAndContingentLiabilities);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReferenceCalculationDiscountingOfProvisionsAndContingentLiabilities");
	OptionDetails.LongDesc = NStr("vi = 'Xác định số tiền chi phí phần trăm chiết khấu dự phòng chi phí trả trước.';
									|ru = 'Определение суммы процентных расходов дисконтирования резервов предстоящих расходов.';
									|en = 'Identify an interest expense amount of discounting of provisions and contingent liabilities.'; fa = 'Identify an interest expense amount of discounting of provisions and contingent liabilities.';
									|it = 'Определение суммы процентных расходов дисконтирования резервов предстоящих расходов.';
									|pl = 'Identify an interest expense amount of discounting of provisions and contingent liabilities.';
									|tr = 'Karşılıklar ve şarta bağlı yükümlülüklerin iskonto edilmiş karşılıklar için faiz gideri tutarının belirlenmesi.'");
	OptionDetails.Enabled = True;
	#EndRegion
	
	#Region DetailedCalculationProvisionDiscountingInterestOfFutureExpenseCommitments
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DetailedCalculationProvisionDiscountingInterestOfFutureExpenseCommitments);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DetailedCalculationProvisionDiscountingInterestOfFutureExpenseCommitments");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thay đổi số tiền chi phí phần trăm chiết khấu của đối tượng kế toán dự phòng.';
									|ru = 'Анализ изменения суммы процентных расходов дисконтирования объекта учета резервов.';
									|en = 'Analyze changes in the interest expense amount of provision object discounting.'; fa = 'Analyze changes in the interest expense amount of provision object discounting.';
									|it = 'Анализ изменения суммы процентных расходов дисконтирования объекта учета резервов.';
									|pl = 'Analyze changes in the interest expense amount of provision object discounting.';
									|tr = 'Karşılık muhasebe nesnesinin iskonto edilmesi için faiz giderleri miktarındaki değişikliğin analizi.'");
	OptionDetails.Enabled = True;
	#EndRegion
	Reports.ScheduleOfProductionOrderMaterialConsumption.CustomizeReportOptions(Settings);
	Reports.ScheduleOfHumanResourceOccupancyByProductionOrders.CustomizeReportOptions(Settings);
	Reports.LaborInputOfProductionOrder.CustomizeReportOptions(Settings);
	Reports.ItemPlanItemDrillDown.CustomizeReportOptions(Settings);
	Reports.OrderCompleteness.CustomizeReportOptions(Settings);
	Reports.ControlOfProductionByOrder.CustomizeReportOptions(Settings);
	Reports.DrillDownProductionOrderControlByReleaseLots.CustomizeReportOptions(Settings);
	Reports.AccruedExciseAmounts.CustomizeReportOptions(Settings);
	Reports.ShipmentTransferRecords.CustomizeReportOptions(Settings);
	
	Reports.MasterDataDuplicateReport.CustomizeReportOptions(Settings);
	
EndProcedure

// See ReportsOptionsOverridable.RegisterChangesOfReportOptionsKeys.
Procedure RegisterChangesOfReportOptionsKeys(Changes) Export
	
	AddChangeKeys(Changes, "AccountsReceivable", "IntervalsHorizontally", "AccountsReceivable");
	AddChangeKeys(Changes, "AccountsReceivable", "AccordingToSettlementDocuments", "AccountsReceivableForSettlementDocuments");
	AddChangeKeys(Changes, "AccountsPayable", "IntervalsHorizontally", "AccountsPayable");
	AddChangeKeys(Changes, "AccountsPayable", "AccordingToSettlementDocuments", "AccountsPayableOnSettlementDocuments");
	AddChangeKeys(Changes, "WarehouseStockInItemPrices", "Main", "ListOfProductPrices");
	AddChangeKeys(Changes, "RevenueAndCOGS", "SalesList_", "SalesByPartners");
	AddChangeKeys(Changes, "RevenueAndCOGS", "SalesAnalysisBySupplier", "SalesBySupplier");
	AddChangeKeys(Changes, "RevenueAndCOGS", "SalesAnalysisByBusinessRegionChart", "AnalysisOfSalesByBusinessRegion");
	AddChangeKeys(Changes, "TrendsOfSalesRepresentativePerformanceIndicators", "Main", "DynamicsOfIndicatorsOfSalesRepresentatives");
	AddChangeKeys(Changes, "CustomerARAPOpenItems", "Main", "CustomerARAPOpenItems");
	AddChangeKeys(Changes, "VendorARAPOpenItems", "Main", "VendorARAPOpenItems");
	AddChangeKeys(Changes, "VarianceAnalysisOfSalesRepresentativePerformanceByQuantity", 
		"CompletingTasksByNumberBySalesRepresentatives", "CompletingTasksForRepresentatives");
	AddChangeKeys(Changes, "VarianceAnalysisOfSalesRepresentativePerformanceByQuantity", 
		"CompletingTasksByQuantityByProductCategory", "JobExecutionByProducts");
	AddChangeKeys(Changes, "SalesRepresentativeVisitingSchedule", "Main", "SalesRepresentativeVisitingSchedule");
	AddChangeKeys(Changes, "LoanAndDepositContractsRegistry", "Main", "RegisterOfLoanDepositAgreements");
	AddChangeKeys(Changes, "LoanAndDepositContractsRegistry", "Horizontal", "RegisterOfCreditDepositAgreementsHorizontal");
	AddChangeKeys(Changes, "StatusOfCustomersARAP", "Main", "StatusOfCustomersARAP");
	AddChangeKeys(Changes, "StateOfVendorAccountsPayable", "Main", "StateOfVendorAccountsPayable");
	AddChangeKeys(Changes, "InventorySchedule", "Main", "InventorySchedule");
	AddChangeKeys(Changes, "CompanyGoodsStockInItemPrices", "Main", "CompanyGoodsStockInItemPrices");
	
EndProcedure

// Returns the report name as specified in the Configurator
//
// Parameters:
//	Form - ClientApplicationForm - report form.
//
// Returns:
//	String - the name of the report without the word "Report.".
//
Function NameOfObjectKeyReport(Form) Export
	If Form = Undefined Then
		ReportName = Undefined;
	Else
		If TypeOf(Form.ReportSettings.ReportRef) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
			ReportName = Form.ReportSettings.ReportRef.ObjectName;
		ElsIf TypeOf(Form.ReportSettings.ReportRef) = Type("String") Then
			ReportName = StrReplace(Form.ReportSettings.ReportRef, "ExternalReport.", "");
		Else
			ReportName = Common.ObjectAttributeValue(Form.ReportSettings.ReportRef, "Name");
		EndIf;
	EndIf;
	
	Return ReportName;
EndFunction

// Disables the specified report with all its variants from the "report Variants" mechanism.
//
// Parameters:
//  DescriptionOfReport - ValueTreeRow - Provided "as is" from Varietythat.Description of the report().
//
Procedure DisableReport(DescriptionOfReport) Export
	
	DescriptionOfReport.Enabled = False;
	
EndProcedure

// Disables the specified report option from the report Options mechanism.
//
// Parameters:
//  Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//  DescriptionOfReport - ValueTreeRow - Passed "as is" from See ReportsOptions.DescriptionOfReport.
//  VariantKey   - String - name of the report variant.
//
Procedure DisableReportOption(Settings, DescriptionOfReport, VariantKey) Export
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, VariantKey);
	
	OptionDetails.Enabled = False;
	
EndProcedure

// Sets the importance for the specified report variant in the specified subsystem
//
// Parameters:
//  OptionDetails - ValueTreeRow - Provided "as is" from Varietythat.Description of the report().
//  Importance - String -
//               	|- "" - The output of the report in its group in the usual font.
//               	|- "Important" - The output of the report in its group in bold.
//               	|- "See also" - The output of the report in the "See also" group.
//  Subsystem - MetadataObject - if a subsystem is not specified, then for all subsystems of the variant.
//
Procedure SetImportanceOfReportOption(OptionDetails, Importance, Subsystem = Undefined) Export
	
	If ImportanceIsCorrect(Importance) Then
		Location = OptionDetails.Location.Get(Subsystem);
		
		If Not Location = Undefined Then
			OptionDetails.Location.Insert(Subsystem, Importance);
		Else
			For Each Location In OptionDetails.Location Do 
				OptionDetails.Location.Insert(Location.Key, Importance);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Checks the string for the content of the importance parameters
//
// Parameters:
//  Importance - String - possible option: "", "Important", " See Also"
//
// Returns: 
//  Boolean   - True if the passed string is equal to one of the values:
//               	|- "" - The output of the report in its group in the usual font.
//               	|- "Important" - The output of the report in its group in bold.
//               	|- "See also" - The output of the report in the "See also" group.
//             A lie, otherwise.
//
Function ImportanceIsCorrect(Importance)
	
	Return IsBlankString(Importance) Or Importance = "Important" Or Importance = "SeeAlso";
	
EndFunction

// Adds a report variant to the rename table
//
// Parameters:
//  Changes - See ReportsOptionsOverridable.RegisterChangesOfReportOptionsKeys
//  ReportName - String - Report name of the report variant owner
//  OldOptionName - String - The name of the report to rename
//  RelevantOptionName - String - New name of the report variant
//
Procedure AddChangeKeys(Changes, ReportName, OldOptionName, RelevantOptionName) Export
	
	Update = Changes.Add();
	
	Update.Report 				= Metadata.Reports[ReportName];
	Update.OldOptionName 	= OldOptionName;
	Update.RelevantOptionName = RelevantOptionName;
	
EndProcedure

// Adds or removes a subsystem from report variant placements.
//
// Parameters:
//	Location - Map of KeyAndValue - settings for placing the report variant in sections (subsystems) where:
//             * Key - MetadataObject - the subsystem that hosts the report or report variant.
//             * Value - String - the settings in the subsystem (group) - "", "Important", "Stacie".
//	Action - String - "Delete" or " Paste"
//	SubsystemName - String - subsystem name
//		subordinate subsystems are separated by".", the service words " Subsystem "or" Subsystems " do not need to be specified.
//
Procedure ChangePlacementOfReportVariant(Location, Action, SubsystemName) Export
	
	Subsystem = TMCommonUse.SubsystemByName(SubsystemName);
	If Subsystem = Undefined Then
		Return; // there is no such subsystem in metadata
	EndIf;
	
	If Action = "Delete" Then
		Location.Delete(Subsystem);
	ElsIf Action = "Insert" Then
		Location.Insert(Subsystem);
	EndIf;
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

#Region InteractionsByContact

// Adds a report command to the list of commands.
// 
// Parameters:
//  ReportsCommands - ValueTable - table of Commands for output to the submenu, where:
//   * Id - String   - command ID.
//   * Presentation - String   - representation of the team in the form.
//   * Importance      - String   - the suffix of the group in the submenu where this command should be output.
//                                Allowed to use: "Important", "Normal" and "Stacie".
//   * Order       - Number    - the order in which the team is placed in the group. Used for setting up for a specific
//                                workplace.
//   * Picture      - Picture - picture of the team.
//   * Shortcut - Shortcut - keyboard shortcut to quickly call a command.
//   * ParameterType - TypeDescription - types of objects that this command is intended for.
//   * VisibilityInForms    - String - comma-separated form names that the command should be displayed in.
//                                    Used when the composition of teams differs for different forms.
//   * FunctionalOptions - String - comma-separated names of functional options that define the visibility of the command.
//   * VisibilityConditions    - Array - determines the visibility of the command depending on the context.
//                                    To register conditions, use the procedure
//                                    Pluggable commands.Dobasefinalization().
//                                    Conditions are combined by "And".
//   * ChangesSelectedObjects - Boolean - determines whether the command is available in a situation
//                                         where the user does not have permission to change the object.
//                                         If True, the button will not be available in the situation described above.
//                                         Optional. Default: Lie.
//   * MultipleChoice - Boolean
//                        - Undefined - if True, then the command supports multiple choice.
//                                         In this case, a list of links will be passed in the execution parameter.
//                                         Optional. Default value: True.
//   * WriteMode - String - actions related to the recording of an object that are performed before the command handler, where:
//                 "Do not write" - the object is not recorded, and the entire form is passed in the handler parameters instead of references
//                                  . In this mode, it is recommended to work directly with the form
//                                  that is passed in the structure of the 2 parameters of the command handler.
//                 "Record only new" - record new objects.
//                 "Record" - record new and modified objects.
//                 "To conduct" - to conduct documents.
//                 Confirmation is requested from the user before recording and conducting.
//                 Optional. The default value is "Record".
//   * FilesOperationsRequired - Boolean - if True, the web client offers
//                                        to install an extension for working with 1C:Company.
//                                        Optional. Default: Lie.
//   * Manager - String - full name of the metadata object responsible for executing the command.
//                         For Example, " Report.Demoniaco".
//   * FormName - String - name of the form that you want to open or get to run the command.
//                         If no Handler is specified, the "Open" method is called for the form.
//   * VariantKey - String - name of the report variant to open when running the command.
//   * FormParameterName - String - name of the form parameter to pass the link or array of links to.
//   * FormParameters - Undefined
//                    - Structure - parameters of the form specified in the formname.
//   * Handler - String - description of the procedure that processes the main action of the command.
//                  Format "<Public Module name>.<Procedure name>" is used when the procedure is placed in a common module.
//                  The "<Procedure name>" format is used in the following cases:
//                  1) if the formname is filled in, then the client procedure is expected in the module of the specified form,
//                  2) if the formname is not filled in, then a server procedure is expected in the manager module of this object.
//   * AdditionalParameters - Structure - parameters of the handler specified in the Handler.
//
// Returns:
//  ValueTableRow - 
Function AddContactInteractionCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.DocumentJournals.Interactions) Then
		
		ReportCommand = ReportsCommands.Add();
		ReportCommand.Handler                  = "ReportManagementTMClient.InteractionsByContact";
		ReportCommand.Manager                    = Metadata.DocumentJournals.Interactions.Forms.ParametricListForm.FullName();
		ReportCommand.Presentation               = NStr("vi = 'Giao tiếp';
														|ru = 'Взаимодействия';
														|en = 'Interactions'; fa = 'تعاملات';
														|it = 'Interazioni';
														|pl = 'Interactions';
														|tr = 'İş etkileşimleri'");
		ReportCommand.MultipleChoice          = False;
		ReportCommand.Importance                    = "SeeAlso";
		ReportCommand.FunctionalOptions         = "UseEmailClient";
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region PartnerSegments

// Adds a report command to the list of commands.
// 
// Parameters:
//  ReportsCommands - ValueTable - table of Commands for output to the submenu, where:
//   * Id - String   - command ID.
//   * Presentation - String   - representation of the team in the form.
//   * Importance      - String   - the suffix of the group in the submenu where this command should be output.
//                                Allowed to use: "Important", "Normal" and "Stacie".
//   * Order       - Number    - the order in which the team is placed in the group. Used for setting up for a specific
//                                workplace.
//   * Picture      - Picture - picture of the team.
//   * Shortcut - Shortcut - keyboard shortcut to quickly call a command.
//   * ParameterType - TypeDescription - types of objects that this command is intended for.
//   * VisibilityInForms    - String - comma-separated form names that the command should be displayed in.
//                                    Used when the composition of teams differs for different forms.
//   * FunctionalOptions - String - comma-separated names of functional options that define the visibility of the command.
//   * VisibilityConditions    - Array - determines the visibility of the command depending on the context.
//                                    To register conditions, use the procedure
//                                    Pluggable commands.Dobasefinalization().
//                                    Conditions are combined by "And".
//   * ChangesSelectedObjects - Boolean - determines whether the command is available in a situation
//                                         where the user does not have permission to change the object.
//                                         If True, the button will not be available in the situation described above.
//                                         Optional. Default: Lie.
//   * MultipleChoice - Boolean
//                        - Undefined - if True, then the command supports multiple choice.
//                                         In this case, a list of links will be passed in the execution parameter.
//                                         Optional. Default value: True.
//   * WriteMode - String - actions related to the recording of an object that are performed before the command handler, where:
//                 "Do not write" - the object is not recorded, and the entire form is passed in the handler parameters instead of references
//                                  . In this mode, it is recommended to work directly with the form
//                                  that is passed in the structure of the 2 parameters of the command handler.
//                 "Record only new" - record new objects.
//                 "Record" - record new and modified objects.
//                 "To conduct" - to conduct documents.
//                 Confirmation is requested from the user before recording and conducting.
//                 Optional. The default value is "Record".
//   * FilesOperationsRequired - Boolean - if True, the web client offers
//                                        to install an extension for working with 1C:Company.
//                                        Optional. Default: Lie.
//   * Manager - String - full name of the metadata object responsible for executing the command.
//                         For Example, " Report.Demoniaco".
//   * FormName - String - name of the form that you want to open or get to run the command.
//                         If no Handler is specified, the "Open" method is called for the form.
//   * VariantKey - String - name of the report variant to open when running the command.
//   * FormParameterName - String - name of the form parameter to pass the link or array of links to.
//   * FormParameters - Undefined
//                    - Structure - parameters of the form specified in the formname.
//   * Handler - String - description of the procedure that processes the main action of the command.
//                  Format "<Public Module name>.<Procedure name>" is used when the procedure is placed in a common module.
//                  The "<Procedure name>" format is used in the following cases:
//                  1) if the formname is filled in, then the client procedure is expected in the module of the specified form,
//                  2) if the formname is not filled in, then a server procedure is expected in the manager module of this object.
//   * AdditionalParameters - Structure - parameters of the handler specified in the Handler.
//
//
// Returns:
//  ValueTableRow -
Function AddPartnerSegmentsCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.InformationRegisters.SegmentPartners) Then
		
		ReportCommand = ReportsCommands.Add();
		ReportCommand.Handler                  = "ReportManagementTMClient.PartnerSegments";
		ReportCommand.Manager                    = Metadata.InformationRegisters.SegmentPartners.Forms.PartnerSegmentsParameter.FullName();
		ReportCommand.Presentation               = NStr("vi = 'Phân khúc';
														|ru = 'Сегменты';
														|en = 'Segments'; fa = 'بخش‌ها';
														|it = 'Segmenti';
														|pl = 'Segments';
														|tr = 'Segmentler'");
		ReportCommand.MultipleChoice          = False;
		ReportCommand.Importance                    = "SeeAlso";
		ReportCommand.FunctionalOptions         = "UsePartnersSegments";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion
