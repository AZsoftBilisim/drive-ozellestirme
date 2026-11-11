#Region Public

// Fills in the settlement registers in the new architecture based on the passed parameter structure.
//
// Parameters:
//	MainParameters - See CalculationDistributionParameters
//	TableToDistribution - See TableToDistribution 
//		The distribution is performed in a loop on the rows of this table.
//
Procedure CompleteOperationalSettlements(MainParameters, TableToDistribution) Export
	
	If TableToDistribution.Count() = 0 Then
		Return;
	EndIf;

	#Region InitializingQueryAndVariables
	
	RequestingAugmentedTableForDistribution = New Query;
	RequestingAugmentedTableForDistribution.Text = "
	|SELECT DISTINCT
	|	TTParameters.PaymentType_ AS PaymentType_,
	|	TTParameters.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTParameters.ARAPObject AS ARAPObject,
	|	TTParameters.Currency AS Currency,
	|	TTParameters.RecalculationStartDate AS RecalculationStartDate,
	|	TTParameters.PeriodForMonitoringChangesAndCreatingTasks AS PeriodForMonitoringChangesAndCreatingTasks
	|INTO TTTableOfDistributionParameters
	|FROM
	|	&TableOfDistributionParameters AS TTParameters
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTParameters.PaymentType_ AS PaymentType_,
	|	TTParameters.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS TheseAreSettlementsWithCustomers,
	|	TTParameters.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTParameters.ARAPObject AS ARAPObject,
	|	TTParameters.Currency AS Currency,
	|	CASE WHEN TTParameters.RecalculationStartDate = DATETIME(1,1,1)
	|		THEN DATETIME(1,1,1,0,0,2)
	|		ELSE TTParameters.RecalculationStartDate
	|	END AS RecalculationStartDate,
	|	TTParameters.PeriodForMonitoringChangesAndCreatingTasks AS PeriodForMonitoringChangesAndCreatingTasks,
	|
	|	ISNULL(Catalog.Object, UNDEFINED) AS Object,
	|	ISNULL(Catalog.Contract, DimensionKeysOfAccountingByPartners.Contract) AS Contract,
	|	CASE WHEN ISNULL(Catalog.Contract.OffsetOrderOfPaymentsAndInvoices, 
	|							VALUE(Enum.OffsetOrdersOfPaymentsAndInvoices.EmptyRef)) 
	|				= VALUE(Enum.OffsetOrdersOfPaymentsAndInvoices.EmptyRef)
	|		THEN ConstantOffsetOrderOfPaymentsAndInvoices.Value
	|		ELSE ISNULL(Catalog.Contract.OffsetOrderOfPaymentsAndInvoices, VALUE(Enum.OffsetOrdersOfPaymentsAndInvoices.EmptyRef))
	|	END = VALUE(Enum.OffsetOrdersOfPaymentsAndInvoices.ByPlannedRepaymentDate) AS PaymentOffsetByPaymentDate,
	|
	|	Catalog.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|		AND ISNULL(Catalog.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable))
	|			 = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate) AS FixedInvoiceRate,
	|	
	|	CASE WHEN ISNULL(ExchangeRates.RateARAPCurrencyDenominator, 0) = 0 OR ISNULL(ExchangeRates.RateManagementAccountingCurrencyNumerator, 0) = 0
	|			THEN 0
	|		ELSE ISNULL(ExchangeRates.RateARAPCurrencyNumerator, 0)/ISNULL(ExchangeRates.RateARAPCurrencyDenominator, 0)
	|	END AS LocalFixedRate,
	|
	|	CASE WHEN ISNULL(ExchangeRates.RateARAPCurrencyDenominator, 0) = 0
	|			THEN 0
	|		ELSE ISNULL(ExchangeRates.RateARAPCurrencyNumerator, 0)
	|				* ISNULL(ExchangeRates.RateManagementAccountingCurrencyDenominator, 0)
	|				/ ISNULL(ExchangeRates.RateARAPCurrencyDenominator, 0)
	|				* ISNULL(ExchangeRates.RateManagementAccountingCurrencyNumerator, 0)
	|	END AS FixedRateMan,
	|
	|	ISNULL(Catalog.Object.ContractSchedule, 
	|		VALUE(Document.ContractSchedule.EmptyRef)) <> VALUE(Document.ContractSchedule.EmptyRef) AS ScheduleInContract,
	|	ISNULL(Catalog.Contract.ContractRateOption, VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
	|	Catalog.ARAPObjectType AS ARAPObjectType,
	|	ISNULL(Catalog.Object.ContractSchedule, UNDEFINED) AS ContractSchedule,
	|	DimensionKeysOfAccountingByPartners.Organization AS Organization,
	|	DimensionKeysOfAccountingByPartners.Counterparty AS Counterparty,
	|	DimensionKeysOfAccountingByPartners.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	TTTableOfDistributionParameters AS TTParameters
	|		LEFT JOIN Catalog.ARAPObjects AS Catalog
	|		ON TTParameters.ARAPObject = Catalog.Ref
	|		LEFT JOIN InformationRegister.DocumentCurrenciesAndRates AS ExchangeRates
	|			ON (Catalog.Object = ExchangeRates.Document)
	|		LEFT JOIN InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(,) AS ExchangeRatesUnderContract
	|			ON (Catalog.Contract = ExchangeRatesUnderContract.Contract)
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			ON TTParameters.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|		INNER JOIN Constant.OffsetOrderOfPaymentsAndInvoices AS ConstantOffsetOrderOfPaymentsAndInvoices
	|			ON TRUE";
	
	RequestingAugmentedTableForDistribution.SetParameter("TableOfDistributionParameters", TableToDistribution);
	ExtendedTableToDistribution = RequestingAugmentedTableForDistribution.Execute().Unload(); 
	
	ThereAreRecordsOfSettlementsWithCustomers    = ExtendedTableToDistribution.FindRows(New Structure("TheseAreSettlementsWithCustomers",True)).Count() > 0;
	ThereAreRecordsOfSettlementsWithSuppliers = ExtendedTableToDistribution.FindRows(New Structure("TheseAreSettlementsWithCustomers",False)).Count() > 0;
	
	StartDateOfRecalculationMinimum = Date(3999,1,1);
	For Each TableRowToDistribution In ExtendedTableToDistribution Do
		StartDateOfRecalculationMinimum = Min(StartDateOfRecalculationMinimum, TableRowToDistribution.RecalculationStartDate);
	EndDo;
	
	RecordPortionSize = RecordPortionSize();
	BusinessOperationsNotShipping = BusinessOperationsNotShipping();
	EconomicTransferOperations = EconomicTransactionsOfTransferOfSettlements();
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	StartDateOfRecalculationIsDifferent = CommonClientServer.CollapseArray(
		ExtendedTableToDistribution.UnloadColumn("RecalculationStartDate")).Count() > 1;

	// Variables that apply to all lines of assignments for distribution
	GlobalVariables = Common.CopyRecursive(MainParameters);
	GlobalVariables.Insert("DailyReassessment",                               Constants.RevalueCurrencyByDays.Get());
	GlobalVariables.Insert("RecordPortionSize",                                 RecordPortionSize);
	GlobalVariables.Insert("ManagementAccountingCurrency",                         ManagementAccountingCurrency);
	GlobalVariables.Insert("ThereAreRecordsOfSettlementsWithCustomers",                       ThereAreRecordsOfSettlementsWithCustomers);
	GlobalVariables.Insert("ThereAreRecordsOfSettlementsWithSuppliers",                    ThereAreRecordsOfSettlementsWithSuppliers);
	GlobalVariables.Insert("StartDateOfRecalculationIsDifferent",                   StartDateOfRecalculationIsDifferent);
	
	Query                         = New Query;
	Manager                       = New TempTablesManager;
	Query.TempTablesManager = Manager;
	Query.SetParameter("CurrencyOfMan",                   ManagementAccountingCurrency);
	Query.SetParameter("RecordPortionSize",          RecordPortionSize);
	Query.SetParameter("ListOfOrderTypes",          ListOfPlanRegistrarTypes());
	Query.SetParameter("ManualCourseOfOperations",        BusinessOfOperationsWithManualCourse());
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("EmptyLinksToOrders",        EmptyLinksToOrders());
	Query.SetParameter("ListOfTypesThatRefinePlans", ListOfTypesThatRefinePlans());
	Query.SetParameter("StartDateOfRecalculationMinimum", StartDateOfRecalculationMinimum);
	Query.SetParameter("AugmentedDistributionParameters", ExtendedTableToDistribution);
	Query.SetParameter("ListOfAccountingAnalystsByPartners", CommonClientServer.CollapseArray(
		ExtendedTableToDistribution.UnloadColumn("AccountingDimensionByPartners")));
	
	#EndRegion
	
	#Region GettingDataForAllTasks
	
	// Movements before the start of the recalculation and balances.
	GenerateTTOfRegisterData(Query, GlobalVariables);
	StartDateOfCourses = Date(3000,1,1);
	
	If GlobalVariables.ThereAreRecordsOfSettlementsWithCustomers Then
		// The data of the registers with an order of magnitude less than the order of the start of the calculation and the records copied storno are further supplemented.
		TableOfSettlementsWithClientsByTime      = RecordsBeforeStartOfCalculationByTime(Query, GlobalVariables, True);
		TablePaymentPlanForClients               = RecordsBeforeStartOfPaymentPlanCalculation(Query, GlobalVariables, True);
		TablePlanOfShipmentsOfSuppliesToCustomers    = RecordsBeforeCalculationOfShipmentPlan(Query, GlobalVariables, True);
		
		DataForDistributionClients = GetDataForDistribution(Query, True);
		DataForDistributionClients.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
		
		InvoiceTableClients = GetInvoiceData(Query, True);
		
		OriginalRecordersAreClients = Query.TempTablesManager.Tables["TTSourceRecordersClients"].GetData().Unload();
		InitialRecordersRegisterRecordsClients = RegisteredRecordsOfCancelledDocumentsBeforeStartOfCalculation(Query,True);
		InitialRecordersRegisterRecordsPaymentPlanClients = RegisteredRecordsOfCancelledDocumentsPaymentPlanBeforeStartOfCalculation(Query,True);
		SourceRecordersRegisterRecordsShipmentPlanCustomers = RegisteredRecordsOfCancelledDocumentsPlanOfShipmentsBeforeStartOfCalculation(Query,True);
		
		TableOfBalancesOfSettlementsCustomers = TableOfBalancesOfSettlements(Query,True);
		
		StartDateOfCourses = Min(StartDateOfCourses,
								?(DataForDistributionClients.Count() > 0,DataForDistributionClients[0].Period,CurrentSessionDate()),
								?(TableOfBalancesOfSettlementsCustomers.Count() > 0,TableOfBalancesOfSettlementsCustomers[0].OccurrenceDate,CurrentSessionDate()))
		
	EndIf;
	
	If GlobalVariables.ThereAreRecordsOfSettlementsWithSuppliers Then
		
		TableOfSettlementsWithSuppliersByTime     = RecordsBeforeStartOfCalculationByTime(Query, GlobalVariables, False);
		TablePaymentPlanForSuppliers              = RecordsBeforeStartOfPaymentPlanCalculation(Query, GlobalVariables, False);
		TablePlanOfShipmentsOfSuppliesToSuppliers   = RecordsBeforeCalculationOfShipmentPlan(Query, GlobalVariables, False);
		
		DataForDistributionProviders = GetDataForDistribution(Query, False);
		DataForDistributionProviders.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
		
		InvoiceTableSuppliers = GetInvoiceData(Query, False);
		
		SourceRecordersSuppliers = Query.TempTablesManager.Tables["TTSourceRecordersSuppliers"].GetData().Unload();
		SourceRecordersRegisterRecordsSuppliers = RegisteredRecordsOfCancelledDocumentsBeforeStartOfCalculation(Query, False);
		InitialRecordersRegisterRecordsPaymentPlanSuppliers = RegisteredRecordsOfCancelledDocumentsPaymentPlanBeforeStartOfCalculation(Query,False);
		SourceRecordersRegisterRecordsShipmentPlanSuppliers = RegisteredRecordsOfCancelledDocumentsPlanOfShipmentsBeforeStartOfCalculation(Query,False);
		
		TableOfBalancesOfSettlementsSuppliers = TableOfBalancesOfSettlements(Query,False);
		
		StartDateOfCourses = Min(StartDateOfCourses,
								?(DataForDistributionProviders.Count() > 0,DataForDistributionProviders[0].Period,CurrentSessionDate()),
								?(TableOfBalancesOfSettlementsSuppliers.Count() > 0,TableOfBalancesOfSettlementsSuppliers[0].OccurrenceDate,CurrentSessionDate()))
		
	EndIf;
	
	#Region TablesForScheduledCalculations
		
		If GlobalVariables.ThereAreRecordsOfSettlementsWithCustomers Then
			
			// Balances of scheduled payments for clarification and closing with undistributed advances.
			BalancesOfScheduledPaymentsCustomers = Query.TempTablesManager.Tables["TTCalculationsPaymentPlanBalancesCustomers"].GetData().Unload(); //ValueTable
			BalancesOfScheduledPaymentsCustomers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			// Balances of planned shipments for clarification and closing with undistributed advances.
			BalancesOfPlannedShipmentsToCustomers = Query.TempTablesManager.Tables["TTCalculationsShipmentPlanDeliveriesBalancesCustomers"].GetData().Unload(); //ValueTable
			BalancesOfPlannedShipmentsToCustomers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			// Balances and movements of undistributed advances.
			RegisteredRecordsOfPrepaymentsForSummingCustomers = BalancesOfUndistributedAdvancesOfPlannedPaymentAtBeginningOfRecalculation(Query, True);
			RegisteredRecordsOfPrepaymentsForSummingCustomers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			BalancesOfAdvancesCustomers = RegisteredRecordsOfPrepaymentsForSummingCustomers.Copy(New Structure("SetOff, BalanceIsPositive", False, True));
			BalancesOfAdvancesCustomers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			RegisteredRecordsOfPrepaymentsForSummingCustomers.GroupBy("ARAPObject,AccountingDimensionByPartners,Currency,DateOfMovement,Recorder,ThisIsImplementationInPath,OperationProcedure,SummedUp","Sum");
			
			//The Expenditure Registered Recorded invoices, which are distributed to The Balances Of The planned schedules.
			ClarificationsOfPaymentSchedulesClients    = GetClarificationsOfPaymentSchedules(Query, GlobalVariables, True);
			ClarificationsOfPaymentSchedulesClients.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			ClosingShippingSchedulesCustomers = GetClosingShippingSchedules(Query, GlobalVariables, True);
			ClosingShippingSchedulesCustomers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			//incoming movements of orders, as well as movements of schedule refinements are added to this table.
			//it is used to transfer movements to the Accumulation register records table and to determine the Balances of scheduled payments for each day.
			ScheduledPaymentRegisteredRecordsForSummationClients    = GetIncomingRegisteredRecordsForScheduledPayments(Query, GlobalVariables, True);
			ScheduledPaymentRegisteredRecordsForSummationClients.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			RegisteredRecordsOfScheduledShipmentsForSummingCustomers = ToGetIncomingRegisteredRecordsForScheduledShipments(Query, GlobalVariables, True);
			RegisteredRecordsOfScheduledShipmentsForSummingCustomers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
		EndIf;
		
		If GlobalVariables.ThereAreRecordsOfSettlementsWithSuppliers Then
			
			// Balances of scheduled payments for clarification and closing with undistributed advances.
			BalancesOfScheduledPaymentsSuppliers = Query.TempTablesManager.Tables["TTCalculationsPaymentPlanBalancesVendors"].GetData().Unload(); //ValueTable
			BalancesOfScheduledPaymentsSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			// Balances of planned shipments for clarification and closing with undistributed advances.
			BalancesOfPlannedShipmentsSuppliers = Query.TempTablesManager.Tables["TTCalculationsShipmentPlanSuppliesBalancesVendors"].GetData().Unload(); //ValueTable
			BalancesOfPlannedShipmentsSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			// Balances and movements of undistributed advances.
			RegisteredRecordsOfPrepaymentsForSummationSuppliers = BalancesOfUndistributedAdvancesOfPlannedPaymentAtBeginningOfRecalculation(Query, False);
			RegisteredRecordsOfPrepaymentsForSummationSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			BalancesOfAdvancesSuppliers = RegisteredRecordsOfPrepaymentsForSummationSuppliers.Copy(New Structure("SetOff, BalanceIsPositive", False, True));
			BalancesOfAdvancesSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			RegisteredRecordsOfPrepaymentsForSummationSuppliers.GroupBy("ARAPObject,AccountingDimensionByPartners,Currency,DateOfMovement,Recorder,ThisIsImplementationInPath,OperationProcedure,SummedUp","Sum");
			
			//The Expenditure Registered Recorded invoices, which are distributed to The Balances Of The planned schedules.
			ClarificationsOfPaymentSchedulesSuppliers    = GetClarificationsOfPaymentSchedules(Query, GlobalVariables, False);
			ClarificationsOfPaymentSchedulesSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			ClosingShippingSchedulesSuppliers = GetClosingShippingSchedules(Query, GlobalVariables, False);
			ClosingShippingSchedulesSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			//incoming movements of orders, as well as movements of schedule refinements are added to this table.
			//it is used to transfer movements to the Accumulation register records table and to determine the Balances of scheduled payments for each day.
			PlannedPaymentRegisteredRecordsForSummationSuppliers    = GetIncomingRegisteredRecordsForScheduledPayments(Query, GlobalVariables, False);
			PlannedPaymentRegisteredRecordsForSummationSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
			RegisteredRecordsOfScheduledShipmentsForSummationSuppliers = ToGetIncomingRegisteredRecordsForScheduledShipments(Query, GlobalVariables, False);
			RegisteredRecordsOfScheduledShipmentsForSummationSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency");
			
		EndIf;
	
	#EndRegion
	
	If Not MainParameters.OnlyPlannedCalculations Then
		CreateTableOfDatesForPeriod(Query.TempTablesManager, "TableOfDates", StartDateOfCourses, BegOfDay(CurrentSessionDate()));
	EndIf;
	
	#EndRegion
	
	For Each StringOfBasicCalculationParameters In ExtendedTableToDistribution Do
		
		// Contains variables and tables related to the current row of the distribution table.
		CurrentVariables = Common.ValueTableRowToStructure(StringOfBasicCalculationParameters);
		
		#Region GettingDataForDistribution
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("ARAPObject",            StringOfBasicCalculationParameters.ARAPObject);
		FilterStructure1.Insert("AccountingDimensionByPartners", StringOfBasicCalculationParameters.AccountingDimensionByPartners);
		FilterStructure1.Insert("Currency",                    StringOfBasicCalculationParameters.Currency);
		
		If StringOfBasicCalculationParameters.TheseAreSettlementsWithCustomers Then
			
			BusinessTransactions = New Map;
			BusinessTransactions.Insert("ApplyingPrepayment",             Enums.BusinessTransactions.CustomerPrepaymentSettlement);
			BusinessTransactions.Insert("RepaymentOfDebt",  Enums.BusinessTransactions.RepaymentOfCustomerReceivables);
			BusinessTransactions.Insert("RefundOfAdvancePayment",           Enums.BusinessTransactions.RefundToCustomer);
			BusinessTransactions.Insert("RevaluationIsPositive", Enums.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain);
			BusinessTransactions.Insert("RevaluationNegative", Enums.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss);
			BusinessTransactions.Insert("Planning",            Enums.BusinessTransactions.SchedulingOfSalesOrder);
			CurrentVariables.Insert("BusinessTransactions", BusinessTransactions);
			
			HOSettings = New Map;
			HOSettings.Insert("PaymentSettlement", Catalogs.BusinessTransactionsSettings.CustomerPrepaymentSettlement);
			HOSettings.Insert("RevaluationIsPositive", Catalogs.BusinessTransactionsSettings.ExchangeDifferencesCustomersExchangeGain);
			HOSettings.Insert("RevaluationNegative", Catalogs.BusinessTransactionsSettings.ExchangeDifferencesCustomersExchangeLoss);
			CurrentVariables.Insert("HOSettings", HOSettings);
			
			DataForDistribution = DataForDistributionClients.Copy(FilterStructure1);
			
			CurrentVariables.Insert("OriginalRecorders", OriginalRecordersAreClients.Copy(FilterStructure1));
			CurrentVariables.Insert("RegisteredRecordsOfOriginalRecorders", InitialRecordersRegisterRecordsClients.Copy(FilterStructure1));
			CurrentVariables.Insert("InitialRecordersRegisterRecordsPaymentPlan", InitialRecordersRegisterRecordsPaymentPlanClients.Copy(FilterStructure1));
			CurrentVariables.Insert("SourceRecordersRegisterRecordsShipmentPlan", SourceRecordersRegisterRecordsShipmentPlanCustomers.Copy(FilterStructure1));
			
			CurrentVariables.Insert("TableOfBalancesOfSettlements", TableOfBalancesOfSettlementsCustomers.Copy(FilterStructure1));
			
			PrepaymentRegisteredRecordsForSummation = RegisteredRecordsOfPrepaymentsForSummingCustomers.Copy(FilterStructure1);
			RegisteredRecordsOfScheduledPaymentsForSummation = ScheduledPaymentRegisteredRecordsForSummationClients.Copy(FilterStructure1);
			PlannedShipmentRegisteredRecordsForSummation = RegisteredRecordsOfScheduledShipmentsForSummingCustomers.Copy(FilterStructure1);
			ClarificationsOfPaymentSchedules = ClarificationsOfPaymentSchedulesClients.Copy(FilterStructure1);
			ClosingShippingSchedules = ClosingShippingSchedulesCustomers.Copy(FilterStructure1);
		
			BalancesOfScheduledPayments = BalancesOfScheduledPaymentsCustomers.Copy(FilterStructure1);
			BalancesOfScheduledPayments.Indexes.Add("DocumentPlan,PaymentOption");
			BalancesOfScheduledPayments.Indexes.Add("DocumentPlan");
			
			BalanceOfPlannedShipments = BalancesOfPlannedShipmentsToCustomers.Copy(FilterStructure1);
			BalanceOfPlannedShipments.Indexes.Add("DocumentPlan");
			
			BalanceOfAdvances = BalancesOfAdvancesCustomers.Copy(FilterStructure1).Total("Sum");
			
			InvoicesData = New Map;
			InvoiceDataTable = InvoiceTableClients.Copy(FilterStructure1);
			For Each String In InvoiceDataTable Do
				InvoicesData.Insert(String.Invoice,
											SumStructure(String.Sum,
											String.SumCompl,
											String.SumMan));
			EndDo;
			InvoiceDataTable.Clear();
			CurrentVariables.Insert("InvoicesData", InvoicesData);
			
			CurrentVariables.Insert("PaymentPlanTable", TablePaymentPlanForClients.Copy(FilterStructure1));
			TableShipmentPlanDeliveries = TablePlanOfShipmentsOfSuppliesToCustomers.Copy(FilterStructure1);
			CurrentVariables.Insert("TableOfCalculationsByTerms", TableOfSettlementsWithClientsByTime.Copy(FilterStructure1));
			
			NameOfSettlementRegister = "CustomersARAPAccountingByDueDates";
			PaymentPlanRegisterName = "CustomersARAPAccountingCashFlowPlan";
			ShippingPlanRegisterNameDelivery = "CustomersARAPAccountingPlannedShipments";
			
		Else
			
			BusinessTransactions = New Map;
			BusinessTransactions.Insert("ApplyingPrepayment",             Enums.BusinessTransactions.VendorPrepaymentSettlement);
			BusinessTransactions.Insert("RepaymentOfDebt",  Enums.BusinessTransactions.AccountsPayableRepayment);
			BusinessTransactions.Insert("RefundOfAdvancePayment",           Enums.BusinessTransactions.RefundFromVendor);
			BusinessTransactions.Insert("RevaluationIsPositive", Enums.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss);
			BusinessTransactions.Insert("RevaluationNegative", Enums.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain);
			BusinessTransactions.Insert("Planning",            Enums.BusinessTransactions.SchedulingOfPurchaseOrder);
			CurrentVariables.Insert("BusinessTransactions", BusinessTransactions);
			
			HOSettings = New Map;
			HOSettings.Insert("PaymentSettlement", Catalogs.BusinessTransactionsSettings.VendorPrepaymentSettlement);
			HOSettings.Insert("RevaluationIsPositive", Catalogs.BusinessTransactionsSettings.ExchangeDifferencesVendorsExchangeLoss);
			HOSettings.Insert("RevaluationNegative", Catalogs.BusinessTransactionsSettings.ExchangeDifferencesVendorsExchangeGain);
			CurrentVariables.Insert("HOSettings", HOSettings);
			
			DataForDistribution = DataForDistributionProviders.Copy(FilterStructure1);
			
			CurrentVariables.Insert("OriginalRecorders", SourceRecordersSuppliers.Copy(FilterStructure1));
			CurrentVariables.Insert("RegisteredRecordsOfOriginalRecorders", SourceRecordersRegisterRecordsSuppliers.Copy(FilterStructure1));
			CurrentVariables.Insert("InitialRecordersRegisterRecordsPaymentPlan", InitialRecordersRegisterRecordsPaymentPlanSuppliers.Copy(FilterStructure1));
			CurrentVariables.Insert("SourceRecordersRegisterRecordsShipmentPlan", SourceRecordersRegisterRecordsShipmentPlanSuppliers.Copy(FilterStructure1));
			
			CurrentVariables.Insert("TableOfBalancesOfSettlements",TableOfBalancesOfSettlementsSuppliers.Copy(FilterStructure1));
			
			PrepaymentRegisteredRecordsForSummation = RegisteredRecordsOfPrepaymentsForSummationSuppliers.Copy(FilterStructure1);
			RegisteredRecordsOfScheduledPaymentsForSummation = PlannedPaymentRegisteredRecordsForSummationSuppliers.Copy(FilterStructure1);
			PlannedShipmentRegisteredRecordsForSummation = RegisteredRecordsOfScheduledShipmentsForSummationSuppliers.Copy(FilterStructure1);
			ClarificationsOfPaymentSchedules = ClarificationsOfPaymentSchedulesSuppliers.Copy(FilterStructure1);
			ClosingShippingSchedules = ClosingShippingSchedulesSuppliers.Copy(FilterStructure1);
			
			BalancesOfScheduledPayments = BalancesOfScheduledPaymentsSuppliers.Copy(FilterStructure1);
			BalancesOfScheduledPayments.Indexes.Add("DocumentPlan,PaymentOption");
			BalancesOfScheduledPayments.Indexes.Add("DocumentPlan");
			
			BalanceOfPlannedShipments = BalancesOfPlannedShipmentsSuppliers.Copy(FilterStructure1);
			BalanceOfPlannedShipments.Indexes.Add("DocumentPlan");
			
			BalanceOfAdvances = BalancesOfAdvancesSuppliers.Copy(FilterStructure1).Total("Sum");
				
			InvoicesData = New Map;
			InvoiceDataTable = InvoiceTableSuppliers.Copy(FilterStructure1);
			For Each String In InvoiceDataTable Do
				InvoicesData.Insert(String.Invoice,
											SumStructure(String.Sum,
											String.SumCompl,
											String.SumMan));
			EndDo;
			InvoiceDataTable.Clear();
			CurrentVariables.Insert("InvoicesData", InvoicesData);
			
			CurrentVariables.Insert("PaymentPlanTable",TablePaymentPlanForSuppliers.Copy(FilterStructure1));
			TableShipmentPlanDeliveries = TablePlanOfShipmentsOfSuppliesToSuppliers.Copy(FilterStructure1);
			CurrentVariables.Insert("TableOfCalculationsByTerms",TableOfSettlementsWithSuppliersByTime.Copy(FilterStructure1));
			
			NameOfSettlementRegister = "VendorsARAPAccountingByDueDates";
			PaymentPlanRegisterName = "VendorsARAPAccountingCashFlowPlan";
			ShippingPlanRegisterNameDelivery = "VendorsARAPAccountingPlannedDeliveries";
		
		EndIf;
		
		CurrentVariables.RegisteredRecordsOfOriginalRecorders.Indexes.Add("DocumentRecorder");
		CurrentVariables.OriginalRecorders.Indexes.Add("NewRegistrar");
		CurrentVariables.OriginalRecorders.Indexes.Add("CancelledRegistrar");
		
		CurrentVariables.Insert("RevaluationProcedure", New Map);
		CurrentVariables.Insert("ChartAdjustmentData", New Map);
		
		Query.SetParameter("ARAPObject",             CurrentVariables.ARAPObject);
		Query.SetParameter("AccountingDimensionByPartners",  CurrentVariables.AccountingDimensionByPartners);
		Query.SetParameter("Currency",                     CurrentVariables.Currency);
		Query.SetParameter("PaymentType_",                CurrentVariables.PaymentType_);
		Query.SetParameter("RecalculationStartDate",        CurrentVariables.RecalculationStartDate);
		Query.SetParameter("PeriodForMonitoringChangesAndCreatingTasks", CurrentVariables.PeriodForMonitoringChangesAndCreatingTasks);
		
		ShipmentRows = DataForDistribution.FindRows(New Structure("ThisIsPayment",False));
		RemainderLines_ = CurrentVariables.TableOfBalancesOfSettlements.FindRows(New Structure("Prepayment",0));
		
		NeedReassessment = (StringOfBasicCalculationParameters.Currency <> StringOfBasicCalculationParameters.LocalAccountingCurrency 
			Or StringOfBasicCalculationParameters.Currency <> ManagementAccountingCurrency)
			And (ShipmentRows.Count() > 0 Or RemainderLines_.Count() > 0)
			And Not GlobalVariables.OnlyPlannedCalculations;
		CurrentVariables.Insert("NeedReassessment",NeedReassessment);
		If NeedReassessment Then
			
			TableOfExchangeRates = GetCurrencyRates(Query, StartDateOfCourses, GlobalVariables, CurrentVariables);
			CurrentVariables.Insert("TableOfExchangeRates", TableOfExchangeRates);
			
			DateOfBeginningOfExchangeDifferences = Min(?(ShipmentRows.Count() > 0, ShipmentRows[0].OccurrenceDate, CurrentSessionDate()),
				?(RemainderLines_.Count() > 0, RemainderLines_[0].OccurrenceDate, CurrentSessionDate()));
			EndDateOfExchangeDifferences = Max(?(ShipmentRows.Count() > 0, ShipmentRows[ShipmentRows.Count()-1].OccurrenceDate, CurrentSessionDate()),CurrentSessionDate());
			
			DocumentsForCalculatingExchangeDifferences = Documents.ExchangeDifferenceCalculation.RevaluationDocuments(StringOfBasicCalculationParameters.Organization,
				DateOfBeginningOfExchangeDifferences,
				EndDateOfExchangeDifferences,
				CurrentVariables.TheseAreSettlementsWithCustomers);
				
			CurrentVariables.Insert("DocumentsForCalculatingExchangeDifferences", DocumentsForCalculatingExchangeDifferences);
			
		EndIf;
		#EndRegion
		
		DataForDistribution.Indexes.Add("Recorder");
		
		#Region CalculationOfPlannedSchedules
		BalancesOfPlannedShipmentsToClarifyDatesOfRepaymentOfAdvances = BalanceOfPlannedShipments.Copy();
		BalancesOfPlannedShipmentsToClarifyDatesOfRepaymentOfAdvances.GroupBy("PlannedRepaymentDate","Sum,AmountOfUndistributedAdvance");
		ScheduledShipmentRegisteredRecords = PlannedShipmentRegisteredRecordsForSummation.Copy();
		ScheduledShipmentRegisteredRecords.GroupBy("OperationProcedure,PlannedRepaymentDate","Sum");
		
		#Region PrepaymentRegisteredRecordsForSummation
		Balance_ = CurrentVariables.TableOfBalancesOfSettlements.Total("Prepayment") - CurrentVariables.TableOfBalancesOfSettlements.Total("Debt");
		For Each CalculationLine_ In DataForDistribution Do
			If CalculationLine_.ThisIsPayment Then
				If Balance_ + CalculationLine_.Sum > 0 Then
					AmountOfRegisteredRecorded = ?(Balance_ >= 0,CalculationLine_.Sum, Balance_ + CalculationLine_.Sum);
					NwRw = PrepaymentRegisteredRecordsForSummation.Add();
					NwRw.DateOfMovement       = BegOfDay(CalculationLine_.Period);
					NwRw.Sum             = AmountOfRegisteredRecorded;
					NwRw.OperationProcedure   = CalculationLine_.OperationProcedure;
					NwRw.Recorder       = CalculationLine_.Recorder;
					NwRw.ThisIsImplementationInPath = CalculationLine_.ThisIsImplementationInPath;
					NwRw.SummedUp    = False;
				EndIf;
				Balance_ = Balance_ + CalculationLine_.Sum;
			ElsIf Not CalculationLine_.ThisIsPayment Then
				If Balance_ > 0 Then
					AmountOfRegisteredRecorded = ?(Balance_ - CalculationLine_.Sum >= 0,CalculationLine_.Sum, Balance_);
					NwRw = PrepaymentRegisteredRecordsForSummation.Add();
					NwRw.DateOfMovement       = BegOfDay(CalculationLine_.Period);
					NwRw.Sum             = -AmountOfRegisteredRecorded;
					NwRw.OperationProcedure   = CalculationLine_.OperationProcedure;
					NwRw.Recorder       = CalculationLine_.Recorder;
					NwRw.ThisIsImplementationInPath = CalculationLine_.ThisIsImplementationInPath;
					NwRw.SummedUp    = False;
				EndIf;
				Balance_ = Balance_ - CalculationLine_.Sum;
			EndIf;
		EndDo;
		PrepaymentRegisteredRecordsForSummation.Sort("DateOfMovement ASC,OperationProcedure ASC");
		
		PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule = PrepaymentRegisteredRecordsForSummation.Copy();
		PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule.GroupBy("DateOfMovement,Recorder,ThisIsImplementationInPath,OperationProcedure","Sum");
		PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule.Sort("DateOfMovement DESC");
		
		#EndRegion
			
			// 1. We determine the list of dates at the end of which it is necessary to make a redistribution of unused advances.
			#Region ListOfDatesForRegisteringRecords
			ListOfPrepaymentMovementDates = PrepaymentRegisteredRecordsForSummation.Copy(New Structure("SummedUp",False),"DateOfMovement").UnloadColumn("DateOfMovement");
			ListOfRegisteredRecordsForScheduledPayments = RegisteredRecordsOfScheduledPaymentsForSummation.Copy(,"Date").UnloadColumn("Date");
			ListOfRegisteredRecordsOfScheduledShipments = PlannedShipmentRegisteredRecordsForSummation.Copy(,"Date").UnloadColumn("Date");
			ListOfDatesOfPaymentClarifications = ClarificationsOfPaymentSchedules.Copy(,"OccurrenceDate").UnloadColumn("OccurrenceDate");
			ListOfDatesWhenShipmentsWereClarified = ClosingShippingSchedules.Copy(,"OccurrenceDate").UnloadColumn("OccurrenceDate");
			ListOfDatesSourceRecorders = CurrentVariables.OriginalRecorders.Copy(,"NewPeriodStartOfDay").UnloadColumn("NewPeriodStartOfDay");
			
			CommonClientServer.SupplementArray(ListOfPrepaymentMovementDates, ListOfRegisteredRecordsForScheduledPayments);
			CommonClientServer.SupplementArray(ListOfPrepaymentMovementDates, ListOfRegisteredRecordsOfScheduledShipments);
			CommonClientServer.SupplementArray(ListOfPrepaymentMovementDates, ListOfDatesOfPaymentClarifications);
			CommonClientServer.SupplementArray(ListOfPrepaymentMovementDates, ListOfDatesWhenShipmentsWereClarified);
			CommonClientServer.SupplementArray(ListOfPrepaymentMovementDates, ListOfDatesSourceRecorders);
			DatesArray = CommonClientServer.CollapseArray(ListOfPrepaymentMovementDates);
			ListOfDates_ = New ValueList;
			ListOfDates_.LoadValues(DatesArray);
			ListOfDates_.SortByValue(SortDirection.Asc);
			#EndRegion
			
			For Each ListValue In ListOfDates_ Do
				
				InitialRecordersByCurrentDate = CurrentVariables.OriginalRecorders.FindRows(New Structure("NewPeriodStartOfDay", ListValue.Value));
				
				// 2. Add Receipts for Orders and roll up the Balance Of scheduled payments and shipments
				#Region AddingIncomingRegisteredRecordsOfScheduledPaymentsAndStorno
				While RegisteredRecordsOfScheduledPaymentsForSummation.Count() > 0 Do
					String = RegisteredRecordsOfScheduledPaymentsForSummation[0];
					If String.Date <= ListValue.Value Then
						NwRw = BalancesOfScheduledPayments.Add();
						NwRw.DocumentPlan = String.Recorder;
						NwRw.OccurrenceDate = String.OccurrenceDate;
						NwRw.PlannedRepaymentDate = String.PlannedRepaymentDate;
						NwRw.PaymentOption = String.PaymentOption;
						NwRw.AmountDue = String.Sum;
						NwRw.AmountDueIsUndistributedAdvance = 0;
						NwRw.ThereIsUndistributedAdvanceAmountDue = False;
						
						RegisteredRecordsOfScheduledPaymentsForSummation.Delete(0);
					Else
						Break;
					EndIf;
				EndDo;
				
				For Each StringOfOriginalRecorder In InitialRecordersByCurrentDate Do
					// We only cancel the record with the Unallocated advance = False, because the Truth will be recalculated automatically below.
					RegisteredRecordsOfOriginalPaymentPlanDocument = CurrentVariables.InitialRecordersRegisterRecordsPaymentPlan.Copy(New Structure("DocumentRecorder,UnallocatedAdvancePayment", StringOfOriginalRecorder.CancelledRegistrar, False));
					CommonClientServer.SupplementTable(CurrentVariables.PaymentPlanTable.Copy(New Structure("DocumentRecorder,RecordingBeforeCalculationStarts,UnallocatedAdvancePayment", StringOfOriginalRecorder.CancelledRegistrar,Undefined, False)),
															RegisteredRecordsOfOriginalPaymentPlanDocument);
					// The Register Recorded Storno (with a minus)
					For Each SourceDocumentRegisteredRecord In RegisteredRecordsOfOriginalPaymentPlanDocument Do
						StringIsStorno = CurrentVariables.PaymentPlanTable.Add();
						FillPropertyValues(StringIsStorno,SourceDocumentRegisteredRecord);
						StringIsStorno.DocumentRecorder = StringOfOriginalRecorder.NewRegistrar;
						StringIsStorno.Period              = StringOfOriginalRecorder.NewPeriod;
						StringIsStorno.OperationProcedure     = StringOfOriginalRecorder.NewOrderOfOperation;
						StringIsStorno.AmountDue             = -SourceDocumentRegisteredRecord.AmountDue;
						StringIsStorno.ReversingEntry              = True;
					EndDo;
					// Incoming Registered Recorded Balances of the schedule
					For Each StringOfOriginalRegisteredRecords In RegisteredRecordsOfOriginalPaymentPlanDocument Do
						// If the closing of the invoice schedule has been suspended, the schedule must be returned to the Balance.
						NwRw = BalancesOfScheduledPayments.Add();
						NwRw.DocumentPlan = StringOfOriginalRegisteredRecords.DocumentPlan;
						NwRw.OccurrenceDate = StringOfOriginalRegisteredRecords.OccurrenceDate;
						NwRw.PlannedRepaymentDate = StringOfOriginalRegisteredRecords.PlannedRepaymentDate;
						NwRw.PaymentOption = StringOfOriginalRegisteredRecords.PaymentOption;
						NwRw.AmountDue = StringOfOriginalRegisteredRecords.AmountDue;
						NwRw.AmountDueIsUndistributedAdvance = 0;
					EndDo;
				EndDo;
				
				BalancesOfScheduledPayments.Sort("PlannedRepaymentDate,OccurrenceDate,PaymentOption", New CompareValues);
				#EndRegion
				
				#Region AddingIncomingRegisteredRecordsOfScheduledShipmentsAndStorno
				While PlannedShipmentRegisteredRecordsForSummation.Count() > 0 Do
					String = PlannedShipmentRegisteredRecordsForSummation[0];
					If String.Date <= ListValue.Value Then
						NwRw = BalanceOfPlannedShipments.Add();
						NwRw.DocumentPlan = String.Recorder;
						NwRw.OccurrenceDate = String.OccurrenceDate;
						NwRw.PlannedRepaymentDate = String.PlannedRepaymentDate;
						NwRw.Sum = String.Sum;
						NwRw.AmountOfUndistributedAdvance = 0;
						NwRw.ThereIsAmountOfUndistributedAdvance = False;
						
						PlannedShipmentRegisteredRecordsForSummation.Delete(0);
					Else
						Break;
					EndIf;
				EndDo;
				
				For Each StringOfOriginalRecorder In InitialRecordersByCurrentDate Do
					SourceDocumentRegisteredRecordsShipmentPlan = CurrentVariables.SourceRecordersRegisterRecordsShipmentPlan.Copy(New Structure("DocumentRecorder,UnallocatedAdvancePayment", StringOfOriginalRecorder.CancelledRegistrar,False));
					CommonClientServer.SupplementTable(TableShipmentPlanDeliveries.Copy(New Structure("DocumentRecorder,RecordingBeforeCalculationStarts,UnallocatedAdvancePayment", StringOfOriginalRecorder.CancelledRegistrar,Undefined,False)),
						SourceDocumentRegisteredRecordsShipmentPlan);
					// The Register Recorded Storno (with a minus)
					For Each SourceDocumentRegisteredRecord In SourceDocumentRegisteredRecordsShipmentPlan Do
						StringIsStorno = TableShipmentPlanDeliveries.Add();
						FillPropertyValues(StringIsStorno,SourceDocumentRegisteredRecord);
						StringIsStorno.DocumentRecorder = StringOfOriginalRecorder.NewRegistrar;
						StringIsStorno.Period              = StringOfOriginalRecorder.NewPeriod;
						StringIsStorno.OperationProcedure     = StringOfOriginalRecorder.NewOrderOfOperation;
						
						StringIsStorno.Sum = -SourceDocumentRegisteredRecord.Sum;
						StringIsStorno.ReversingEntry = True;
					EndDo;
					// Incoming Registered Recorded Balances of the schedule
					For Each StringOfOriginalRegisteredRecords In SourceDocumentRegisteredRecordsShipmentPlan Do
						NwRw = BalanceOfPlannedShipments.Add();
						NwRw.DocumentPlan = StringOfOriginalRegisteredRecords.DocumentPlan;
						NwRw.OccurrenceDate = StringOfOriginalRegisteredRecords.OccurrenceDate;
						NwRw.PlannedRepaymentDate = StringOfOriginalRegisteredRecords.PlannedRepaymentDate;
						NwRw.Sum = StringOfOriginalRegisteredRecords.Sum;
						NwRw.AmountOfUndistributedAdvance = 0;
					EndDo;
				EndDo;
				
				BalanceOfPlannedShipments.Sort("PlannedRepaymentDate,OccurrenceDate");
				#EndRegion
				
				// 3. Add clarifications of the payment schedule for orders and cancel the records of undistributed advances, if any.
				#Region DistributionOfActualShipmentToScheduledPayments
				
				SchRefinements = 0;
				While SchRefinements < ClarificationsOfPaymentSchedules.Count() Do
					StringClarifications = ClarificationsOfPaymentSchedules[SchRefinements];
					If StringClarifications.OccurrenceDate > ListValue.Value Then
						Break;
					EndIf;
						
					// Taking into account the payment option
					RemainderLines_ = BalancesOfScheduledPayments.FindRows(New Structure("DocumentPlan,PaymentOption",StringClarifications.OrderDocument,StringClarifications.PaymentOption));
					For Each RemainderLine_ In RemainderLines_ Do
						If BegOfDay(RemainderLine_.OccurrenceDate) > StringClarifications.OccurrenceDate Then
							Continue;
						EndIf;
						If StringClarifications.Sum = 0 Then
							Break;
						EndIf;
						DebitedAmount = Min(RemainderLine_.AmountDue, StringClarifications.Sum);
						ReducePaymentPlanForOrder(CurrentVariables.PaymentPlanTable, RemainderLine_, StringClarifications, DebitedAmount);
						If DebitedAmount > 0 Then
							UnallocatedAdvanceBalanceLines = BalancesOfScheduledPayments.FindRows(New Structure("ThereIsUndistributedAdvanceAmountDue",True));
							For Each BalanceLineOfUndistributedAdvance In UnallocatedAdvanceBalanceLines Do
								If DebitedAmount = 0 Then
									Break;
								EndIf;
								If BalanceLineOfUndistributedAdvance.AmountDueIsUndistributedAdvance < 0 Then
									AmountOfCancellation = Max(-DebitedAmount, BalanceLineOfUndistributedAdvance.AmountDueIsUndistributedAdvance);
									ToCancelUnallocatedAdvance(CurrentVariables.PaymentPlanTable, BalanceLineOfUndistributedAdvance, StringClarifications, AmountOfCancellation);
									DebitedAmount = DebitedAmount + AmountOfCancellation;
								EndIf;
							EndDo;
						EndIf;
					EndDo;
					// Excluding the payment option
					If StringClarifications.Sum > 0 Then
						RemainderLines_ = BalancesOfScheduledPayments.FindRows(New Structure("DocumentPlan",StringClarifications.OrderDocument));
						For Each RemainderLine_ In RemainderLines_ Do
							If BegOfDay(RemainderLine_.OccurrenceDate) > StringClarifications.OccurrenceDate Then
								Continue;
							EndIf;
							If StringClarifications.Sum = 0 Then
								Break;
							EndIf;
							DebitedAmount = Min(RemainderLine_.AmountDue, StringClarifications.Sum);
							ReducePaymentPlanForOrder(CurrentVariables.PaymentPlanTable, RemainderLine_, StringClarifications, DebitedAmount);
							// If not the entire undistributed advance was reduced
							If DebitedAmount > 0 Then
								UnallocatedAdvanceBalanceLines = BalancesOfScheduledPayments.FindRows(New Structure("ThereIsUndistributedAdvanceAmountDue",True));
								For Each BalanceLineOfUndistributedAdvance In UnallocatedAdvanceBalanceLines Do
									If DebitedAmount = 0 Then
										Break;
									EndIf;
									If BalanceLineOfUndistributedAdvance.AmountDueIsUndistributedAdvance < 0 Then
										AmountOfCancellation = Max(-DebitedAmount, BalanceLineOfUndistributedAdvance.AmountDueIsUndistributedAdvance);
										ToCancelUnallocatedAdvance(CurrentVariables.PaymentPlanTable, BalanceLineOfUndistributedAdvance, StringClarifications, AmountOfCancellation);
										DebitedAmount = DebitedAmount + AmountOfCancellation;
									EndIf;
								EndDo;
							EndIf;
						EndDo;
					EndIf;
						
					If StringClarifications.Sum = 0 Then
						ClarificationsOfPaymentSchedules.Delete(SchRefinements);
					Else
						SchRefinements = SchRefinements + 1;
					EndIf;
				EndDo;
				#EndRegion
				
				// 4. Add the closure of the shipment schedule for orders and cancel the records of undistributed advances, if any.
				#Region DistributionOfActualShipmentToScheduledShipments
				ClosingAcc = 0;
				While ClosingAcc < ClosingShippingSchedules.Count() Do
					ClosureString = ClosingShippingSchedules[ClosingAcc];
					If ClosureString.OccurrenceDate > ListValue.Value Then
						Break;
					Else
						RemainderLines_ = BalanceOfPlannedShipments.FindRows(New Structure("DocumentPlan",ClosureString.OrderDocument));
						For Each RemainderLine_ In RemainderLines_ Do
							If BegOfDay(RemainderLine_.OccurrenceDate) > ClosureString.OccurrenceDate Then
								Continue;
							EndIf;
							If ClosureString.Sum = 0 Then
								Break;
							EndIf;
							DebitedAmount = Min(RemainderLine_.Sum,ClosureString.Sum);
							ReduceOrderShipmentPlan(TableShipmentPlanDeliveries, RemainderLine_, ClosureString, DebitedAmount);
							// If not the entire undistributed advance was reduced
							If DebitedAmount > 0 Then
								UnallocatedAdvanceBalanceLines = BalanceOfPlannedShipments.FindRows(New Structure("ThereIsAmountOfUndistributedAdvance",True));
								For Each BalanceLineOfUndistributedAdvance In UnallocatedAdvanceBalanceLines Do
									If DebitedAmount = 0 Then
										Break;
									EndIf;
									If BalanceLineOfUndistributedAdvance.AmountOfUndistributedAdvance < 0 Then
										AmountOfCancellation = Max(-DebitedAmount, BalanceLineOfUndistributedAdvance.AmountOfUndistributedAdvance);
										ToCancelUnallocatedAdvanceOfShipmentPlan(TableShipmentPlanDeliveries, BalanceLineOfUndistributedAdvance, ClosureString, AmountOfCancellation);
										DebitedAmount = DebitedAmount + AmountOfCancellation;
									EndIf;
								EndDo;
							EndIf;
						EndDo;
						
					EndIf;
					If ClosureString.Sum = 0 Then
						ClosingShippingSchedules.Delete(ClosingAcc);
					Else
						ClosingAcc = ClosingAcc + 1;
					EndIf;
				EndDo;
				#EndRegion
				
				// 5. Update the Balance of the prepayment to understand how much you need to redistribute advances.
				#Region CalculationOfBalanceOfAdvances
				For Each String In PrepaymentRegisteredRecordsForSummation Do
					If String.DateOfMovement > ListValue.Value Then
						Break;
					EndIf;
					If Not String.SummedUp Then
						String.SummedUp         = True;
						BalanceOfAdvances = BalanceOfAdvances + String.Sum;
					EndIf;
				EndDo;
				RegisterRecordedPrepaymentsToSummarizeShipmentPlan = PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule.Copy();
				#EndRegion
				
				// Advance delta = Balance of advances at the end of the day - already added lines of Unallocated Advance.
				AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule = BalanceOfAdvances + BalancesOfScheduledPayments.Total("AmountDueIsUndistributedAdvance");
				AmountOfAdvancesForDistributionAccordingToScheduleOfShipments = BalanceOfAdvances + BalanceOfPlannedShipments.Total("AmountOfUndistributedAdvance");
				
				// 6. Distribution of the delta of the amount of advances for the day according to the schedule of scheduled payment (Registered Records with the flag "unallocated advance")
				#Region DistributionOfAdvancesAccordingToPaymentSchedule
				// If the delta is positive (the amount of advances has increased) then we look at the Balance, taking into account the unallocated advances already credited (Unallocated Advance = True or False)
				If AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule > 0 Then
					For Each RemainderLine_ In BalancesOfScheduledPayments Do
						If AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule = 0 Then
							Break;
						EndIf;
						If (RemainderLine_.AmountDue + RemainderLine_.AmountDueIsUndistributedAdvance) <= 0 Then
							Continue;
						EndIf;
						For Each PrepaymentMOVEMENT In PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule Do
							DebitedAmount = Min(AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule,PrepaymentMOVEMENT.Sum,RemainderLine_.AmountDue + RemainderLine_.AmountDueIsUndistributedAdvance);
							If DebitedAmount <= 0 Or PrepaymentMOVEMENT.DateOfMovement > ListValue.Value Then
								Continue;
							EndIf;
							
							ReducePaymentPlanForOrder(CurrentVariables.PaymentPlanTable, RemainderLine_, PrepaymentMOVEMENT, DebitedAmount, EndOfDay(ListValue.Value));
							AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule = AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule - DebitedAmount;
							
						EndDo;
					EndDo;
				// If the delta is negative, then only the credited unallocated advances should be reduced (Unallocated advance = True)
				ElsIf AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule < 0 Then
					Cnt = BalancesOfScheduledPayments.Count()-1;
					While Cnt >= 0 Do
						RemainderLine_ = BalancesOfScheduledPayments[Cnt];
						If AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule = 0 Then
							Break;
						EndIf;
						If RemainderLine_.AmountDueIsUndistributedAdvance = 0 Then
							Cnt = Cnt -1;
							Continue;
						EndIf;
						For Each PrepaymentMOVEMENT In PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule Do
							DebitedAmount = -Min(-AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule,-PrepaymentMOVEMENT.Sum,-RemainderLine_.AmountDueIsUndistributedAdvance);
							If PrepaymentMOVEMENT.DateOfMovement > ListValue.Value
								Or DebitedAmount >= 0
								Or PrepaymentMOVEMENT.ThisIsImplementationInPath Then
								Continue;
							EndIf;
								
							ToCancelUnallocatedAdvance(CurrentVariables.PaymentPlanTable, RemainderLine_, PrepaymentMOVEMENT, DebitedAmount, EndOfDay(ListValue.Value));
							AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule = AmountOfAdvancesToBeDistributedAccordingToPaymentSchedule - DebitedAmount;
								
						EndDo;
						Cnt = Cnt -1;
					EndDo;
				EndIf;
				#EndRegion
				
				// 7. The distribution of the delta of the amount of advances for the day according to the schedule of scheduled shipment (Registered Recorded with the flag "unallocated advance")
				#Region DistributionOfAdvancesAccordingToShipmentSchedule
				// If the delta is positive (the amount of advances has increased) then we look at the Balance, taking into account the unallocated advances already credited (Unallocated Advance = True or False)
				If AmountOfAdvancesForDistributionAccordingToScheduleOfShipments > 0 Then
					For Each RemainderLine_ In BalanceOfPlannedShipments Do
						If AmountOfAdvancesForDistributionAccordingToScheduleOfShipments = 0 Then
							Break;
						EndIf;
						If (RemainderLine_.Sum + RemainderLine_.AmountOfUndistributedAdvance) <= 0 Then
							Continue;
						EndIf;
						For Each PrepaymentMOVEMENT In RegisterRecordedPrepaymentsToSummarizeShipmentPlan Do
							If PrepaymentMOVEMENT.DateOfMovement = ListValue.Value //We select the Registered Records Of The current day, because it was they who changed the Balance Of The advance
								And PrepaymentMOVEMENT.DateOfMovement >= RemainderLine_.OccurrenceDate //The schedule of shipments is specified only by prepayments entered after the Order.
								And PrepaymentMOVEMENT.Sum > 0
								And AmountOfAdvancesForDistributionAccordingToScheduleOfShipments > 0 Then
								
								DebitedAmount = Min(AmountOfAdvancesForDistributionAccordingToScheduleOfShipments,PrepaymentMOVEMENT.Sum,RemainderLine_.Sum + RemainderLine_.AmountOfUndistributedAdvance);
								
								ReduceOrderShipmentPlan(TableShipmentPlanDeliveries, RemainderLine_, PrepaymentMOVEMENT, DebitedAmount, EndOfDay(ListValue.Value));
								
								AmountOfAdvancesForDistributionAccordingToScheduleOfShipments = AmountOfAdvancesForDistributionAccordingToScheduleOfShipments - DebitedAmount;
							EndIf;
						EndDo;
					EndDo;
				// If the delta is negative, then only the credited unallocated advances should be reduced (Unallocated advance = True)
				ElsIf AmountOfAdvancesForDistributionAccordingToScheduleOfShipments < 0 Then
					Cnt = BalanceOfPlannedShipments.Count()-1;
					While Cnt >= 0 Do
						RemainderLine_ = BalanceOfPlannedShipments[Cnt];
						If AmountOfAdvancesForDistributionAccordingToScheduleOfShipments = 0 Then
							Break;
						EndIf;
						If RemainderLine_.AmountOfUndistributedAdvance = 0 Then
							Cnt = Cnt -1;
							Continue;
						EndIf;
						For Each PrepaymentMOVEMENT In RegisterRecordedPrepaymentsToSummarizeShipmentPlan Do
							If PrepaymentMOVEMENT.DateOfMovement = ListValue.Value
								And PrepaymentMOVEMENT.Sum < 0
								And AmountOfAdvancesForDistributionAccordingToScheduleOfShipments < 0 Then
								DebitedAmount = -Min(-AmountOfAdvancesForDistributionAccordingToScheduleOfShipments,-PrepaymentMOVEMENT.Sum,-RemainderLine_.AmountOfUndistributedAdvance);
								If PrepaymentMOVEMENT.DateOfMovement > ListValue.Value Or DebitedAmount >= 0 Then
									Continue;
								EndIf;
								
								ToCancelUnallocatedAdvanceOfShipmentPlan(TableShipmentPlanDeliveries, RemainderLine_, PrepaymentMOVEMENT, DebitedAmount, EndOfDay(ListValue.Value));
								AmountOfAdvancesForDistributionAccordingToScheduleOfShipments = AmountOfAdvancesForDistributionAccordingToScheduleOfShipments - DebitedAmount;
								
							EndIf;
						EndDo;
						Cnt = Cnt -1;
					EndDo;
				EndIf;
				#EndRegion
				
				// 8. Deletion of the recorded lines of RegisteredRecorded Advance Payment
				#Region DeletingObsoleteLines
				Cnt = 0;
				While Cnt < PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule.Count() Do
					String = PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule[Cnt];
					If String.DateOfMovement <= ListValue.Value And String.Sum = 0 Then
						PrepaymentRegisteredRecordsForDistributionAccordingToPaymentSchedule.Delete(Cnt);
					Else
						Break;
					EndIf;
				EndDo;
				
				#EndRegion
				
			EndDo;
			
		#EndRegion

		#Region DistributionOfPaymentsToInvoices
		For Each CalculationLine_ In DataForDistribution Do
			
			CurrentVariables.TableOfBalancesOfSettlements.GroupBy("ARAPDocument,PlannedRepaymentDate,RepaymentDateIsNotFilledIn,OccurrenceDate,OperationProcedure,SettlementProcedureByPaymentDate,DateOfRevaluation","Debt,DebtLocal,ARAPMan,Prepayment,PrepaymentLocal,PrepaymentMan");
			EmptyRows = CurrentVariables.TableOfBalancesOfSettlements.FindRows(New Structure("Prepayment,Debt",0,0));
			For Each IsBlankString In EmptyRows Do
				CurrentVariables.TableOfBalancesOfSettlements.Delete(IsBlankString);
			EndDo;
			
			If CalculationLine_.ReversingEntry Then
			#Region ReversingEntry
				AddStornoEntries(GlobalVariables,CurrentVariables,CalculationLine_);
				If TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.ReversingEntry") Then
					AddMendingRegisterRecordedIfNecessary(GlobalVariables, CurrentVariables, CalculationLine_);
				EndIf;
				// New RegisteredRecorded corrections may be to another AR/AP object - it is necessary to write off the zero Balances before the next line of calculations
				WriteOffLocalMansVidsBasedOnZeroBalances(CurrentVariables, BegOfDay(CalculationLine_.Period));
				Continue;
			#EndRegion
			EndIf;
			
			If CalculationLine_.ThisIsPayment Then
				
				If CalculationLine_.NewRegisteredRecordedCorrections Then
				#Region NewRegisteredRecordedCorrections
					SuitableLines = CurrentVariables.TableOfBalancesOfSettlements.Copy(New Structure("Prepayment,ARAPDocument", 0, CalculationLine_.Recorder));
					For Each AppropriateLineIsStorno In SuitableLines Do
						If CalculationLine_.Sum = 0 Then
							Break;
						EndIf;
						
						#Region DeterminingAmountOfWriteOff
						DebitedAmount = Min(AppropriateLineIsStorno.Debt,CalculationLine_.Sum);
						If DebitedAmount = 0 Then
							Continue;
						EndIf;
						AmountOfLocalTaxDebited = DebitedAmount(0, AppropriateLineIsStorno.DebtLocal, AppropriateLineIsStorno.Debt, DebitedAmount);
						AmountOfManDebiting = DebitedAmount(0, AppropriateLineIsStorno.ARAPMan, AppropriateLineIsStorno.Debt, DebitedAmount);
						#EndRegion
						
						#Region ExpenseDebt
						If CalculationLine_.OffsetPeriod >= CurrentVariables.RecalculationStartDate Then
							AddDebtExpense(CurrentVariables, AppropriateLineIsStorno, CalculationLine_, DebitedAmount, AmountOfLocalTaxDebited, AmountOfManDebiting, BusinessTransactions["RepaymentOfDebt"]);
						EndIf;
						#EndRegion
						
						CalculationLine_.Sum       = CalculationLine_.Sum     - DebitedAmount;
						CalculationLine_.SumCompl   = CalculationLine_.SumCompl - AmountOfLocalTaxDebited;
						CalculationLine_.SumMan    = CalculationLine_.SumMan  - AmountOfManDebiting;
					EndDo;
				#EndRegion
				EndIf;
				
				If TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.SaleAdjustment")
					Or TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.PurchaseAdjustment") Then
				#Region CorrectionOfInvoiceInMinus
					RemnantsOfLinkedDocument = CurrentVariables.TableOfBalancesOfSettlements.FindRows(New Structure("Prepayment, ARAPDocument", 0, CalculationLine_.LinkedDocument));
					For Each RemainderLineOfLinkedDocument In RemnantsOfLinkedDocument Do
						If CalculationLine_.Sum = 0 Then
							Break;
						EndIf;
						If CalculationLine_.OperationProcedure < RemainderLineOfLinkedDocument.OperationProcedure Then
							Continue;
						EndIf;
						
						If NeedReassessment Then
							ReassessDebt(GlobalVariables, CurrentVariables, CalculationLine_.LinkedDocument, CalculationLine_.Period, False);
						EndIf;
						
						#Region DeterminingAmountOfWriteOff
						DebitedAmount = Min(CalculationLine_.Sum, RemainderLineOfLinkedDocument.Debt);
						If DebitedAmount = 0 Then
							Continue;
						EndIf;
						If CalculationLine_.ManualLocalCourse
							Or CurrentVariables.InvoicesData[CalculationLine_.LinkedDocument] = Undefined Then
							LocalAdjustmentAmount = Round(DebitedAmount * CalculationLine_.SumCompl / CalculationLine_.Sum,2);
						Else
							LocalAdjustmentAmount = Round(DebitedAmount
								* (CurrentVariables.InvoicesData[CalculationLine_.LinkedDocument].TheAmountOfTheDocumentRegl 
									/ CurrentVariables.InvoicesData[CalculationLine_.LinkedDocument].DocumentAmount),2);
						EndIf;
								
						If CalculationLine_.ManualManCourse
							Or CurrentVariables.InvoicesData[CalculationLine_.LinkedDocument] = Undefined Then
							ManSAdjustmentAmount = Round(DebitedAmount * CalculationLine_.SumMan / CalculationLine_.Sum,2);
						Else
							ManSAdjustmentAmount = Round(DebitedAmount
								* (CurrentVariables.InvoicesData[CalculationLine_.LinkedDocument].DocumentAmountManag 
									/ CurrentVariables.InvoicesData[CalculationLine_.LinkedDocument].DocumentAmount),2);
						EndIf;
						#EndRegion
						
						#Region ExpenseDebt
						AddDebtExpense(CurrentVariables, RemainderLineOfLinkedDocument, CalculationLine_, DebitedAmount, LocalAdjustmentAmount, ManSAdjustmentAmount);
						#EndRegion
						
						CalculationLine_.Sum     = CalculationLine_.Sum     - DebitedAmount;
						CalculationLine_.SumCompl = CalculationLine_.SumCompl - LocalAdjustmentAmount;
						CalculationLine_.SumMan  = CalculationLine_.SumMan  - ManSAdjustmentAmount;
						
					EndDo;
					
					If CalculationLine_.Sum > 0 Then
						RecalculateAmountsIfThisIsAdjustment(GlobalVariables, CurrentVariables, CalculationLine_);
					EndIf;
					#EndRegion
				EndIf;
				
				If TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.ARAPAccountingScheduleAdjustment") Then
					#Region ScheduleAdjustment
					If CalculationLine_.BusinessOperation = Enums.BusinessTransactions.AdjustCustomerPaymentSchedule
						Or CalculationLine_.BusinessOperation = Enums.BusinessTransactions.AdjustVendorPaymentSchedule Then
						BalanceOfARAPDocument = CurrentVariables.TableOfBalancesOfSettlements.FindRows(New Structure("Prepayment, ARAPDocument", 0, CalculationLine_.ARAPDocument));
						For Each LineOfCalculatedLinkedDocument In BalanceOfARAPDocument Do
							If CalculationLine_.Sum = 0 Then
								Break;
							EndIf;
							
							If NeedReassessment Then
								ReassessDebt(GlobalVariables, CurrentVariables, CalculationLine_.ARAPDocument, CalculationLine_.Period, False);
							EndIf;
							
							#Region DeterminingAmountOfWriteOff
							DebitedAmount = Min(CalculationLine_.Sum, LineOfCalculatedLinkedDocument.Debt);
							If DebitedAmount = 0 Then
								Continue;
							EndIf;
							
							//We write off the debt to the current debt rate so that there are no exchange differences.
							LocalAdjustmentAmount = Round(DebitedAmount * LineOfCalculatedLinkedDocument.DebtLocal / LineOfCalculatedLinkedDocument.Debt,2);
							ManSAdjustmentAmount = Round(DebitedAmount * LineOfCalculatedLinkedDocument.ARAPMan / LineOfCalculatedLinkedDocument.Debt,2);
							// All amounts of write-offs of schedule adjustments need to be added up in order to then charge the same amounts without the formation of exchange differences
							If CurrentVariables.ChartAdjustmentData[CalculationLine_.Recorder] = Undefined Then
								CurrentVariables.ChartAdjustmentData.Insert(CalculationLine_.Recorder, ChartAdjustmentDataStructure());
							EndIf;
							AdjustmentDataOfChart                 = CurrentVariables.ChartAdjustmentData[CalculationLine_.Recorder];
							AdjustmentDataOfChart.SumExpense     = AdjustmentDataOfChart.SumExpense     + DebitedAmount;
							AdjustmentDataOfChart.LocalExpenseAmount = AdjustmentDataOfChart.LocalExpenseAmount + LocalAdjustmentAmount;
							AdjustmentDataOfChart.AmountOfManSExpense  = AdjustmentDataOfChart.AmountOfManSExpense  + ManSAdjustmentAmount;
							AdjustmentDataOfChart.OccurrenceDate = LineOfCalculatedLinkedDocument.OccurrenceDate;
							#EndRegion
							
							#Region ExpenseDebt
							AddDebtExpense(CurrentVariables, LineOfCalculatedLinkedDocument, CalculationLine_, DebitedAmount, LocalAdjustmentAmount, ManSAdjustmentAmount);
							#EndRegion
							
							CalculationLine_.Sum     = CalculationLine_.Sum     - DebitedAmount;
							CalculationLine_.SumCompl = CalculationLine_.SumCompl - LocalAdjustmentAmount;
							CalculationLine_.SumMan  = CalculationLine_.SumMan  - ManSAdjustmentAmount;
						EndDo;
						
						If CalculationLine_.Sum > 0 Then
							CalculationLine_.Sum = 0;
						EndIf;
						// If the expense amounts have not been added yet, then the Receipt does not need to be added, we will write down an empty structure
						If CurrentVariables.ChartAdjustmentData[CalculationLine_.Recorder] = Undefined Then
							CurrentVariables.ChartAdjustmentData.Insert(CalculationLine_.Recorder, ChartAdjustmentDataStructure());
						EndIf;
					Else
						FillInScheduleAdjustmentData(CurrentVariables, CalculationLine_.Recorder, DataForDistribution, CalculationLine_.ThisIsPayment);
					EndIf;
					#EndRegion
				EndIf;
				
				If CalculationLine_.Sum > 0 Then
					#Region RepaymentOfDebt
					If StringOfBasicCalculationParameters.PaymentOffsetByPaymentDate Then
						CurrentVariables.TableOfBalancesOfSettlements.Sort("RepaymentDateIsNotFilledIn ASC, PlannedRepaymentDate ASC, OccurrenceDate ASC, SettlementProcedureByPaymentDate ASC, OperationProcedure ASC");
					Else
						CurrentVariables.TableOfBalancesOfSettlements.Sort("OccurrenceDate ASC, OperationProcedure ASC, RepaymentDateIsNotFilledIn ASC, PlannedRepaymentDate ASC, SettlementProcedureByPaymentDate ASC");
					EndIf;
					
					For Each SuitableShippingLine In CurrentVariables.TableOfBalancesOfSettlements Do
						If CalculationLine_.Sum = 0 Then
							Break;
						EndIf;
						If SuitableShippingLine.Prepayment <> 0 Then
							// This is not a shipping line
							Continue;
						EndIf;
						
						If NeedReassessment Then
							ReassessDebt(GlobalVariables, CurrentVariables, SuitableShippingLine.ARAPDocument, CalculationLine_.Period, True);
						EndIf;
						
						#Region DeterminingAmountOfWriteOff
						DebitedAmount = Min(SuitableShippingLine.Debt,CalculationLine_.Sum);
						If DebitedAmount = 0 Then
							Continue;
						EndIf;
						
						//We write off the debt at the payment rate if it is not a debt transfer.
						If CalculationLine_.BusinessOperation = Enums.BusinessTransactions.DebtTransfer Then
							AmountOfLocalTaxDebited = DebitedAmount(0, SuitableShippingLine.DebtLocal, SuitableShippingLine.Debt, DebitedAmount);
							AmountOfManDebiting = DebitedAmount(0, SuitableShippingLine.ARAPMan, SuitableShippingLine.Debt, DebitedAmount);
						Else
							AmountOfLocalTaxDebited = DebitedAmount(0, CalculationLine_.SumCompl, CalculationLine_.Sum, DebitedAmount);
							AmountOfManDebiting = DebitedAmount(0, CalculationLine_.SumMan, CalculationLine_.Sum, DebitedAmount);
						EndIf;
						#EndRegion
						
						#Region ExpenseDebt
						If CalculationLine_.OffsetPeriod >= CurrentVariables.RecalculationStartDate Then
							If EconomicTransferOperations.Find(CalculationLine_.BusinessOperation) <> Undefined Then
								BusinessOperation         = CalculationLine_.BusinessOperation;
							Else
								BusinessOperation         = CurrentVariables.BusinessTransactions["RepaymentOfDebt"];
							EndIf;
							AddDebtExpense(CurrentVariables, SuitableShippingLine, CalculationLine_, DebitedAmount, AmountOfLocalTaxDebited, AmountOfManDebiting, BusinessOperation);
						EndIf;
						#EndRegion
						
						CalculationLine_.Sum       = CalculationLine_.Sum     - DebitedAmount;
						CalculationLine_.SumCompl   = CalculationLine_.SumCompl - AmountOfLocalTaxDebited;
						CalculationLine_.SumMan    = CalculationLine_.SumMan  - AmountOfManDebiting;
					EndDo;
					#EndRegion
				EndIf;
					
				If CalculationLine_.Sum > 0 Then
					
					#Region ClarificationOfDatesOfRepaymentOfAdvances
						//Updating the Balance of planned shipments
						While ScheduledShipmentRegisteredRecords.Count() > 0 Do
							String = ScheduledShipmentRegisteredRecords[0];
							If String.OperationProcedure < CalculationLine_.OperationProcedure Then
								NwRw = BalancesOfPlannedShipmentsToClarifyDatesOfRepaymentOfAdvances.Add();
								NwRw.PlannedRepaymentDate = String.PlannedRepaymentDate;
								NwRw.Sum = String.Sum;
								NwRw.AmountOfUndistributedAdvance = 0;
								ScheduledShipmentRegisteredRecords.Delete(String);
							Else
								Break;
							EndIf;
						EndDo;
						
						BalancesOfPlannedShipmentsToClarifyDatesOfRepaymentOfAdvances.GroupBy("PlannedRepaymentDate","Sum,AmountOfUndistributedAdvance");
						BalancesOfPlannedShipmentsToClarifyDatesOfRepaymentOfAdvances.Sort("PlannedRepaymentDate ASC");
						To_Clarify = CalculationLine_.Sum;
						For Each RemainderLine_ In BalancesOfPlannedShipmentsToClarifyDatesOfRepaymentOfAdvances Do
							If RemainderLine_.Sum + RemainderLine_.AmountOfUndistributedAdvance <= 0 Then
								Continue;
							EndIf;
							If To_Clarify = 0 Then
								Break;
							EndIf;
							
							AmountOfUpdate = Min(RemainderLine_.Sum + RemainderLine_.AmountOfUndistributedAdvance,To_Clarify);
							If CalculationLine_.Sum > AmountOfUpdate Then
								LocalClarificationAmount = DebitedAmount(0, CalculationLine_.SumCompl, CalculationLine_.Sum, AmountOfUpdate);
								AmountOfManSClarification = DebitedAmount(0, CalculationLine_.SumMan, CalculationLine_.Sum, AmountOfUpdate);
								If Not ValueIsFilled(CalculationLine_.PlannedRepaymentDate) Then
									NwRw = DataForDistribution.Insert(DataForDistribution.IndexOf(CalculationLine_)+1);
									FillPropertyValues(NwRw,CalculationLine_);
									NwRw.Sum = CalculationLine_.Sum - AmountOfUpdate;
									NwRw.SumCompl= CalculationLine_.SumCompl - LocalClarificationAmount;
									NwRw.SumMan = CalculationLine_.SumMan - AmountOfManSClarification;
									
									CalculationLine_.Sum = AmountOfUpdate;
									CalculationLine_.SumCompl = LocalClarificationAmount;
									CalculationLine_.SumMan = AmountOfManSClarification;
									CalculationLine_.PlannedRepaymentDate = RemainderLine_.PlannedRepaymentDate;
									To_Clarify = 0;
								Else
									To_Clarify = To_Clarify - AmountOfUpdate;
								EndIf;
								RemainderLine_.Sum = RemainderLine_.Sum - AmountOfUpdate;
							Else
								If Not ValueIsFilled(CalculationLine_.PlannedRepaymentDate) Then
									CalculationLine_.PlannedRepaymentDate = RemainderLine_.PlannedRepaymentDate;
								EndIf;
								RemainderLine_.Sum = RemainderLine_.Sum - CalculationLine_.Sum;
								To_Clarify = 0;
							EndIf;
						EndDo;
					#EndRegion
					
					#Region PrepaymentReceipt
					AddReceipt(CurrentVariables, CalculationLine_, "Payment");
					#EndRegion
				EndIf;
				
			Else
				
				LinesOfRegisteredRecordsOfExpenseOfShipmentPlan = TableShipmentPlanDeliveries.FindRows(
					New Structure("DocumentRecorder, IncludedInBalanceOfPlannedShipments,RecordType",
						CalculationLine_.Recorder, False, AccumulationRecordType.Expense));
				For Each StringOfRegisteredRecords In LinesOfRegisteredRecordsOfExpenseOfShipmentPlan Do
					NwRw = BalancesOfPlannedShipmentsToClarifyDatesOfRepaymentOfAdvances.Add();
					NwRw.PlannedRepaymentDate = StringOfRegisteredRecords.PlannedRepaymentDate;
					NwRw.Sum = -StringOfRegisteredRecords.Sum;
					NwRw.AmountOfUndistributedAdvance = 0;
					StringOfRegisteredRecords.IncludedInBalanceOfPlannedShipments = True;
				EndDo;
				
				If CalculationLine_.NewRegisteredRecordedCorrections Then
				#Region NewRegisteredRecordedCorrections
					SuitableLines = CurrentVariables.TableOfBalancesOfSettlements.Copy(New Structure("Debt,ARAPDocument", 0, CalculationLine_.Recorder));
					For Each AppropriateLineIsStorno In SuitableLines Do
						If CalculationLine_.Sum = 0 Then
							Break;
						EndIf;
						
						#Region DeterminingAmountOfWriteOff
						DebitedAmount = Min(AppropriateLineIsStorno.Debt,CalculationLine_.Sum);
						If DebitedAmount = 0 Then
							Continue;
						EndIf;
						AmountOfLocalTaxDebited = DebitedAmount(0, AppropriateLineIsStorno.DebtLocal, AppropriateLineIsStorno.Debt, DebitedAmount);
						AmountOfManDebiting = DebitedAmount(0, AppropriateLineIsStorno.ARAPMan, AppropriateLineIsStorno.Debt, DebitedAmount);
						#EndRegion
						
						#Region ExpenseDebt
						If CalculationLine_.OffsetPeriod >= CurrentVariables.RecalculationStartDate Then
							NewRow_Prepayment_Expense = AddPrepaymentExpense(CurrentVariables, AppropriateLineIsStorno, CalculationLine_, DebitedAmount, AmountOfLocalTaxDebited, AmountOfManDebiting);
						EndIf;
						#EndRegion
						
						// Reducing the payment line by the credited amount.
						CalculationLine_.Sum       = CalculationLine_.Sum     - DebitedAmount;
						CalculationLine_.SumCompl   = CalculationLine_.SumCompl - AmountOfLocalTaxDebited;
						CalculationLine_.SumMan    = CalculationLine_.SumMan  - AmountOfManDebiting;
					EndDo;
				#EndRegion
				EndIf;
				
				If TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.ARAPAccountingScheduleAdjustment") Then
					
					#Region ScheduleAdjustment
					If CalculationLine_.BusinessOperation = Enums.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule
						Or CalculationLine_.BusinessOperation = Enums.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule Then
						BalanceOfARAPDocument = CurrentVariables.TableOfBalancesOfSettlements.FindRows(New Structure("Debt, ARAPDocument", 0, CalculationLine_.ARAPDocument));
						For Each LineOfBalanceOfARAPDocument In BalanceOfARAPDocument Do
							If CalculationLine_.Sum = 0 Then
								Break;
							EndIf;
							
							#Region DeterminingAmountOfWriteOff
							DebitedAmount = Min(CalculationLine_.Sum, LineOfBalanceOfARAPDocument.Prepayment);
							If DebitedAmount = 0 Then
								Continue;
							EndIf;
							LocalAdjustmentAmount = Round(DebitedAmount * LineOfBalanceOfARAPDocument.PrepaymentLocal / LineOfBalanceOfARAPDocument.Prepayment,2);
							ManSAdjustmentAmount = Round(DebitedAmount * LineOfBalanceOfARAPDocument.PrepaymentMan / LineOfBalanceOfARAPDocument.Prepayment,2);
							
							// All the amounts of write-offs of schedule adjustments need to be added up in order to then charge the same amounts without the formation of dollar differences
							If CurrentVariables.ChartAdjustmentData[CalculationLine_.Recorder] = Undefined Then
								CurrentVariables.ChartAdjustmentData.Insert(CalculationLine_.Recorder, ChartAdjustmentDataStructure());
							EndIf;
							AdjustmentDataOfChart                 = CurrentVariables.ChartAdjustmentData[CalculationLine_.Recorder];
							AdjustmentDataOfChart.SumExpense     = AdjustmentDataOfChart.SumExpense     + DebitedAmount;
							AdjustmentDataOfChart.LocalExpenseAmount = AdjustmentDataOfChart.LocalExpenseAmount + LocalAdjustmentAmount;
							AdjustmentDataOfChart.AmountOfManSExpense  = AdjustmentDataOfChart.AmountOfManSExpense  + ManSAdjustmentAmount;
							AdjustmentDataOfChart.OccurrenceDate = LineOfBalanceOfARAPDocument.OccurrenceDate;
							#EndRegion
							
							#Region PrepaymentExpense
							NewRow_Prepayment_Expense = AddPrepaymentExpense(CurrentVariables,LineOfBalanceOfARAPDocument,CalculationLine_, DebitedAmount,LocalAdjustmentAmount,ManSAdjustmentAmount);
							#EndRegion
							
							//Reducing the payment line by the amount of the reverse.
							CalculationLine_.Sum     = CalculationLine_.Sum     - DebitedAmount;
							CalculationLine_.SumCompl = CalculationLine_.SumCompl - LocalAdjustmentAmount;
							CalculationLine_.SumMan  = CalculationLine_.SumMan  - ManSAdjustmentAmount;
							
						EndDo;
						If CalculationLine_.Sum > 0 Then
							CalculationLine_.Sum = 0;
						EndIf;
						// If the expense amounts have not been added yet, then the Receipt does not need to be added, we will write down an empty structure
						If CurrentVariables.ChartAdjustmentData[CalculationLine_.Recorder] = Undefined Then
							CurrentVariables.ChartAdjustmentData.Insert(CalculationLine_.Recorder, ChartAdjustmentDataStructure());
						EndIf;
					Else
						FillInScheduleAdjustmentData(CurrentVariables, CalculationLine_.Recorder, DataForDistribution, CalculationLine_.ThisIsPayment);
					EndIf;
					#EndRegion
				EndIf;
				
				// Transfer of the advance payment to the AR/AP document - invoice.
				// If "TRUE" - the prepayment will simply be reduced, otherwise a record will be created for the receipt and expenditure of the debt.
				DoubleEntryIsNotNeeded = BusinessOperationsNotShipping.Find(CalculationLine_.BusinessOperation) <> Undefined;
				
				If TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.SaleAdjustment")
					Or TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.PurchaseAdjustment") Then
					RecalculateAmountsIfThisIsAdjustment(GlobalVariables, CurrentVariables, CalculationLine_, "ShipmentDelivery");
				EndIf;
				
				#Region ApplyingPrepayment
				If StringOfBasicCalculationParameters.PaymentOffsetByPaymentDate Then
					CurrentVariables.TableOfBalancesOfSettlements.Sort("RepaymentDateIsNotFilledIn ASC, PlannedRepaymentDate ASC, OccurrenceDate ASC, SettlementProcedureByPaymentDate ASC,  OperationProcedure ASC");
				Else
					CurrentVariables.TableOfBalancesOfSettlements.Sort("OccurrenceDate ASC, OperationProcedure ASC, RepaymentDateIsNotFilledIn ASC, PlannedRepaymentDate ASC, SettlementProcedureByPaymentDate ASC");
				EndIf;
				
				For Each SuitablePaymentLine In CurrentVariables.TableOfBalancesOfSettlements Do
					If CalculationLine_.Sum = 0 Then
						Break;
					EndIf;
					If SuitablePaymentLine.Debt <> 0 Then
						// This is not a payment line
						Continue;
					EndIf;
					If SuitablePaymentLine.Prepayment < 0 Then
						Raise(StrTemplate(NStr("vi = 'Trong biểu ghi hạch toán công nợ đã tìm thấy số dư âm tại ngày %1. Không thể kết chuyển.';
												|ru = 'В регистрах взаиморасчетов обнаружены отрицательные остатки на дату %1. Проведение невозможно.';
												|en = 'AR/AP accounting registers show negative balances as of %1. Posting is unavailable.'; fa = 'AR/AP accounting registers show negative balances as of %1. Posting is unavailable.';
												|it = 'Nei registri dei conti reciproci sono stati rilevati saldi negativi in data %1. Impossibile pubblicare.';
												|pl = 'W rejestrach rozliczeń wzajemnych wykryto salda ujemne na dzień %1. Zatwierdzenie jest niemożliwe.';
												|tr = '%1 tarihinde mutabakat kayıtlarında negatif bakiyeler bulundu. Kaydetme mümkün değildir.'"),
							CurrentVariables.RecalculationStartDate));
					EndIf;
					
					#Region DeterminingAmountOfWriteOff
					
					If Not DoubleEntryIsNotNeeded Then
						If CalculationLine_.Recorder = SuitablePaymentLine.ARAPDocument
							And TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.ConsignmentReportFromCustomer")
							And CalculationLine_.BusinessOperation = Enums.BusinessTransactions.CommissionAgentSRemunerationDeduction Then
							BusinessTransactionOfOffsettingAdvance = Enums.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment;
						ElsIf CalculationLine_.Recorder = SuitablePaymentLine.ARAPDocument
							And TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.ConsignmentReportToVendor")
							And CalculationLine_.BusinessOperation = Enums.BusinessTransactions.RemunerationDeductionByConsignor Then
							BusinessTransactionOfOffsettingAdvance = Enums.BusinessTransactions.RemunerationOffsetWithPaymentToConsignor;
						ElsIf CalculationLine_.Recorder = SuitablePaymentLine.ARAPDocument
							And TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.CommissionReportIntercompany")
							And (CalculationLine_.BusinessOperation = Enums.BusinessTransactions.CommissionAgentSRemunerationDeduction
								Or CalculationLine_.BusinessOperation = Enums.BusinessTransactions.RemunerationDeductionByConsignor) Then
							If GlobalVariables.TheseAreSettlementsWithCustomers Then
								BusinessTransactionOfOffsettingAdvance = Enums.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment;
							Else
								BusinessTransactionOfOffsettingAdvance = Enums.BusinessTransactions.RemunerationOffsetWithPaymentToConsignor;
							EndIf;
						ElsIf CalculationLine_.Recorder = SuitablePaymentLine.ARAPDocument
							And TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.ElectronicTicketTransaction")
							And (CalculationLine_.BusinessOperation = Enums.BusinessTransactions.BookingViaAgent
								Or CalculationLine_.BusinessOperation = Enums.BusinessTransactions.UseBookingByAdvanceHolder
								Or CalculationLine_.BusinessOperation = Enums.BusinessTransactions.BookingViaAdvanceHolder) Then
							BusinessTransactionOfOffsettingAdvance = Enums.BusinessTransactions.UseBookingByAdvanceHolder;
						Else
							BusinessTransactionOfOffsettingAdvance = CurrentVariables.BusinessTransactions["ApplyingPrepayment"];
						EndIf;
						IdOfAdvanceCreditRecordSFin = New UUID;
					EndIf;
					
					DebitedAmount = Min(CalculationLine_.Sum,SuitablePaymentLine.Prepayment);
					If DebitedAmount = 0 Then
						Continue;
					EndIf;
					
					//The return of the advance is reflected at the return rate. Arbitrary settlement is always at its own rate.
					If (CalculationLine_.BusinessOperation = Enums.BusinessTransactions.ARAPSettlement
							Or CalculationLine_.BusinessOperation = Enums.BusinessTransactions.UseBookingByAdvanceHolder)
						And CalculationLine_.ManualLocalCourse
						Or CalculationLine_.ThisIsRefundOfAdvance
							And CalculationLine_.Recorder = SuitablePaymentLine.ARAPDocument
						Or CalculationLine_.ReversingEntry Then
						AmountOfLocalTaxDebited = DebitedAmount(CalculationLine_.InitialAmountOfLocal/CalculationLine_.InitialAmount_,
							CalculationLine_.SumCompl, CalculationLine_.Sum, DebitedAmount);
					// The remaining advances are at the advance rate.
					Else
						AmountOfLocalTaxDebited = DebitedAmount(0, SuitablePaymentLine.PrepaymentLocal, SuitablePaymentLine.Prepayment, DebitedAmount);
					EndIf;
					
					If (CalculationLine_.BusinessOperation = Enums.BusinessTransactions.ARAPSettlement
							Or CalculationLine_.BusinessOperation = Enums.BusinessTransactions.UseBookingByAdvanceHolder)
						And CalculationLine_.ManualManCourse
						Or CalculationLine_.ThisIsRefundOfAdvance 
							And CalculationLine_.Recorder = SuitablePaymentLine.ARAPDocument
						Or CalculationLine_.ReversingEntry Then
						AmountOfManDebiting = DebitedAmount(CalculationLine_.InitialAmountOfMan/CalculationLine_.InitialAmount_,
							CalculationLine_.SumMan, CalculationLine_.Sum, DebitedAmount);
					Else
						AmountOfManDebiting = DebitedAmount(0, SuitablePaymentLine.PrepaymentMan, SuitablePaymentLine.Prepayment, DebitedAmount);
					EndIf;
					#EndRegion
					
					If CalculationLine_.ManualManCourse Or CalculationLine_.ThisIsRefundOfAdvance Then
						ParishDebtMan = DebitedAmount(CalculationLine_.InitialAmountOfMan/CalculationLine_.InitialAmount_, 
							CalculationLine_.SumMan, CalculationLine_.Sum, DebitedAmount);
					Else
						ParishDebtMan = AmountOfManDebiting;
					EndIf;
					If CalculationLine_.ManualLocalCourse Or CalculationLine_.ThisIsRefundOfAdvance Then
						ParishDebtLocal = DebitedAmount(CalculationLine_.InitialAmountOfLocal/CalculationLine_.InitialAmount_, 
							CalculationLine_.SumCompl, CalculationLine_.Sum, DebitedAmount);
					Else
						ParishDebtLocal = AmountOfLocalTaxDebited;
					EndIf;
				
					#Region ExpensePrepayment
					If CalculationLine_.OffsetPeriod >= CurrentVariables.RecalculationStartDate And Not CalculationLine_.ReversingEntry Then
						NewRow_Prepayment_Expense = AddPrepaymentExpense(CurrentVariables, SuitablePaymentLine, CalculationLine_, DebitedAmount, AmountOfLocalTaxDebited, AmountOfManDebiting, DoubleEntryIsNotNeeded);
						If Not DoubleEntryIsNotNeeded Then
							NewRow_Prepayment_Expense.BusinessOperation = BusinessTransactionOfOffsettingAdvance;
							NewRow_Prepayment_Expense.FinRecordID = IdOfAdvanceCreditRecordSFin;
							NewRow_Prepayment_Expense.BusinessTransactionSetting = CurrentVariables.HOSettings["PaymentSettlement"];
						EndIf;
					EndIf;
					#EndRegion
				
					If Not DoubleEntryIsNotNeeded Then
						If CalculationLine_.Period >= CurrentVariables.RecalculationStartDate Then
						#Region ReceiptDebt
						
							//We reflect the arrival of the amount of debt at the prepayment rate.
							NewRow_Duty_Parish = CurrentVariables.TableOfCalculationsByTerms.Add();
							NewRow_Duty_Parish.RecordType                   = AccumulationRecordType.Receipt;
							
							NewRow_Duty_Parish.DocumentRecorder           = CalculationLine_.Recorder;
							NewRow_Duty_Parish.DocumentCurrency               = CalculationLine_.DocumentCurrency;
							NewRow_Duty_Parish.OperationProcedure               = CalculationLine_.OperationProcedure;
							NewRow_Duty_Parish.ReversingEntry                        = False;
							NewRow_Duty_Parish.Period                        = CalculationLine_.Period;
							NewRow_Duty_Parish.OccurrenceDate             = CalculationLine_.OccurrenceDate;
							NewRow_Duty_Parish.PlannedRepaymentDate        = CalculationLine_.PlannedRepaymentDate;
							NewRow_Duty_Parish.ARAPDocument             = ?(CalculationLine_.ARAPDocument <> CalculationLine_.Recorder, CalculationLine_.ARAPDocument, CalculationLine_.Recorder);
							NewRow_Duty_Parish.SettlementProcedure                 = CalculationLine_.SettlementProcedureByPaymentDate;
							NewRow_Duty_Parish.BusinessOperation         = CalculationLine_.BusinessOperation;
							NewRow_Duty_Parish.BusinessTransactionSetting = CalculationLine_.BusinessTransactionSetting;
							NewRow_Duty_Parish.FinRecordID        = CalculationLine_.FinRecordID;
							//return of the DS, the article must be
							NewRow_Duty_Parish.CashFlowItem = CalculationLine_.CashFlowItem;
							NewRow_Duty_Parish.LinkedDocument             = Undefined;
							
							//Only the shipping registrar is connected to the receiver
							NewRow_Duty_Parish.DestinationAccountingDimensionByPartners = CalculationLine_.DestinationAccountingDimensionByPartners;
							NewRow_Duty_Parish.CalculationObjectReceiver            = CalculationLine_.CalculationObjectReceiver;
							NewRow_Duty_Parish.CurrencyReceiver                    = CalculationLine_.CurrencyReceiver;
							NewRow_Duty_Parish.AmountReceiver                     = DebitedAmount(0, CalculationLine_.AmountReceiver, CalculationLine_.Sum, DebitedAmount);
							CalculationLine_.AmountReceiver = CalculationLine_.AmountReceiver - NewRow_Duty_Parish.AmountReceiver;
							
							NewRow_Duty_Parish.ByDataOfSourceARAPObject  = CalculationLine_.ByDataOfSourceARAPObject;
							NewRow_Duty_Parish.CorARAPObject                 = CalculationLine_.CorARAPObject;
							NewRow_Duty_Parish.CorPartnerAccountingDimension      = CalculationLine_.CorPartnerAccountingDimension;
							
							NewRow_Duty_Parish.Debt                          = DebitedAmount;
							NewRow_Duty_Parish.DebtLocal                      = ParishDebtLocal;
							NewRow_Duty_Parish.ARAPMan                       = ParishDebtMan;
							NewRow_Duty_Parish.RecordingBeforeCalculationStarts         = False;
							If NewRow_Duty_Parish.ReversingEntry
								And CalculationLine_.SettlementTransaction = Enums.SettlementOperations.Payment Then
								NewRow_Duty_Parish.SettlementTransaction = Enums.SettlementOperations.TransferOfSettlements;
							Else
								NewRow_Duty_Parish.SettlementTransaction = CalculationLine_.SettlementTransaction;
							EndIf;
							NewRow_Duty_Parish.Prepayment                    = 0;
							NewRow_Duty_Parish.PrepaymentLocal                = 0;
							NewRow_Duty_Parish.PrepaymentMan                 = 0;
							
							AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, NewRow_Duty_Parish);
						#EndRegion
						EndIf;
						
						#Region ExpenseDebt
						If CalculationLine_.OffsetPeriod>= CurrentVariables.RecalculationStartDate Then
						//We transfer the prepayment to the settlement document of the shipment.
						NewRow_Debt_Expense = CurrentVariables.TableOfCalculationsByTerms.Add();
						NewRow_Debt_Expense.RecordType                   = AccumulationRecordType.Expense;
						NewRow_Debt_Expense.DocumentCurrency               = CalculationLine_.DocumentCurrency;
						NewRow_Debt_Expense.Period                        = CalculationLine_.OffsetPeriod;
						
						//Uniplan
						NewRow_Debt_Expense.BusinessOperation         = NewRow_Prepayment_Expense.BusinessOperation;
						NewRow_Debt_Expense.BusinessTransactionSetting = NewRow_Prepayment_Expense.BusinessTransactionSetting;
						NewRow_Debt_Expense.FinRecordID        = NewRow_Prepayment_Expense.FinRecordID;
						
						NewRow_Debt_Expense.PlannedRepaymentDate        = NewRow_Duty_Parish.PlannedRepaymentDate;
						NewRow_Debt_Expense.ARAPDocument             = NewRow_Duty_Parish.ARAPDocument;
						NewRow_Debt_Expense.OccurrenceDate             = NewRow_Duty_Parish.OccurrenceDate;
						NewRow_Debt_Expense.SettlementProcedure                 = CalculationLine_.OperationProcedure;
						NewRow_Debt_Expense.OperationProcedure               = CalculationLine_.OperationProcedure;
						NewRow_Debt_Expense.DocumentRecorder           = CalculationLine_.Recorder;
						NewRow_Debt_Expense.CashFlowItem = CalculationLine_.CashFlowItem;
						NewRow_Debt_Expense.ReversingEntry                        = False;
						NewRow_Debt_Expense.LinkedDocument             = Undefined;
						
						NewRow_Debt_Expense.DestinationAccountingDimensionByPartners  = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
						NewRow_Debt_Expense.CalculationObjectReceiver             = Catalogs.ARAPObjects.EmptyRef();
						NewRow_Debt_Expense.CurrencyReceiver                     = Catalogs.Currencies.EmptyRef();
						NewRow_Debt_Expense.AmountReceiver                      = 0;
						
						NewRow_Debt_Expense.ByDataOfSourceARAPObject = False;
						NewRow_Debt_Expense.CorARAPObject                = Catalogs.ARAPObjects.EmptyRef();
						NewRow_Debt_Expense.CorPartnerAccountingDimension     = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
						
						NewRow_Debt_Expense.Debt                          = NewRow_Prepayment_Expense.Prepayment;
						NewRow_Debt_Expense.ARAPMan                       = NewRow_Prepayment_Expense.PrepaymentMan;
						NewRow_Debt_Expense.DebtLocal                      = NewRow_Prepayment_Expense.PrepaymentLocal;
						NewRow_Debt_Expense.RecordingBeforeCalculationStarts         = False;
						If NewRow_Debt_Expense.ReversingEntry
							And CalculationLine_.SettlementTransaction = Enums.SettlementOperations.Payment Then
							NewRow_Debt_Expense.SettlementTransaction = Enums.SettlementOperations.TransferOfSettlements;
						Else
							NewRow_Debt_Expense.SettlementTransaction = CalculationLine_.SettlementTransaction;
						EndIf;
						NewRow_Debt_Expense.Prepayment                    = 0;
						NewRow_Debt_Expense.PrepaymentMan                 = 0;
						NewRow_Debt_Expense.PrepaymentLocal                = 0;
						
						AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, NewRow_Debt_Expense, NewRow_Duty_Parish);
						EndIf;
						#EndRegion
					
					EndIf;
				
					// We reduce the amount of the shipment line that will go to the parish.
					If CalculationLine_.ManualLocalCourse And Not DoubleEntryIsNotNeeded Then
						CalculationLine_.SumCompl = CalculationLine_.SumCompl - ParishDebtLocal;
					Else
						// There could have been a revaluation above, so the amount for revaluation should be changed as well as the Local amount
						// For a manual or unfilled course, we determine the Local amount. relative to amounts in currencies
						If CalculationLine_.ManualLocalCourse
							Or CalculationLine_.RateARAPCurrencyDenominator = 0
							Or TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.SaleAdjustment")
							Or TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.PurchaseAdjustment") Then
							Rate = CalculationLine_.InitialAmountOfLocal / CalculationLine_.InitialAmount_;
						Else
							Rate = CalculationLine_.RateARAPCurrencyNumerator / CalculationLine_.RateARAPCurrencyDenominator;
						EndIf;
						RecalculatedLocalBalance = DebitedAmount(Rate, CalculationLine_.SumCompl, CalculationLine_.Sum, CalculationLine_.Sum-DebitedAmount);
						CalculationLine_.SumCompl = RecalculatedLocalBalance;
					EndIf;
					
					If CalculationLine_.ManualManCourse And Not DoubleEntryIsNotNeeded Then
						CalculationLine_.SumMan = CalculationLine_.SumMan - ParishDebtMan;
					Else
						// For a manual or unfilled exchange rate, we determine the amount of upr. in relation to the amounts in currencies
						If CalculationLine_.ManualManCourse
							Or CalculationLine_.RateARAPCurrencyDenominator = 0
							Or CalculationLine_.ExchangeRateNumeratorOfManSCurrency = 0
							Or TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.SaleAdjustment")
							Or TypeOf(CalculationLine_.Recorder) = Type("DocumentRef.PurchaseAdjustment") Then
							Rate = CalculationLine_.InitialAmountOfMan / CalculationLine_.InitialAmount_;
						ElsIf CalculationLine_.RateARAPCurrencyDenominator = 0 Then
							Rate = CalculationLine_.ExchangeRateDenominatorCurrencyMan / CalculationLine_.ExchangeRateNumeratorOfManSCurrency;
						Else
							Rate = CalculationLine_.RateARAPCurrencyNumerator * CalculationLine_.ExchangeRateDenominatorCurrencyMan
								/ (CalculationLine_.RateARAPCurrencyDenominator * CalculationLine_.ExchangeRateNumeratorOfManSCurrency);
						EndIf;
						RecalculatedBalanceOfMan = DebitedAmount(Rate, CalculationLine_.SumMan, CalculationLine_.Sum, CalculationLine_.Sum-DebitedAmount);
						CalculationLine_.SumMan = RecalculatedBalanceOfMan;
					EndIf;
					CalculationLine_.Sum                  = CalculationLine_.Sum - DebitedAmount;
					
					//Stores the weighted average rates of invoices for making adjustments.
					If CurrentVariables.InvoicesData[CalculationLine_.Recorder] = Undefined Then
						CurrentVariables.InvoicesData.Insert(CalculationLine_.Recorder, SumStructure());
					EndIf;
					
					DataFromInvoice                    = CurrentVariables.InvoicesData[CalculationLine_.Recorder];
					DataFromInvoice.DocumentAmount     = DataFromInvoice.DocumentAmount     + DebitedAmount;
					DataFromInvoice.TheAmountOfTheDocumentRegl = DataFromInvoice.TheAmountOfTheDocumentRegl + AmountOfLocalTaxDebited;
					DataFromInvoice.DocumentAmountManag  = DataFromInvoice.DocumentAmountManag  + AmountOfManDebiting;
					
				EndDo;
				
				#EndRegion
				
				If CalculationLine_.Sum > 0 Then
					#Region ReceiptOfDebt
					AddReceipt(CurrentVariables, CalculationLine_, "ShipmentDelivery");
					#EndRegion
				EndIf;
				
			EndIf;
			
			If CalculationLine_.NewRegisteredRecordedCorrections Then
				AddMendingRegisterRecordedIfNecessary(GlobalVariables, CurrentVariables, CalculationLine_);
			EndIf;
			
			WriteOffLocalMansVidsBasedOnZeroBalances(CurrentVariables,BegOfDay(CalculationLine_.Period));
			
		EndDo;
		
		//Reassess all debt Balances
		If NeedReassessment Then
			For Each RemainderLine_ In CurrentVariables.TableOfBalancesOfSettlements Do
				If RemainderLine_.Debt > 0 Then
					ReassessDebt(GlobalVariables, CurrentVariables, RemainderLine_.ARAPDocument, CurrentSessionDate(), False);
				EndIf;
			EndDo;
		EndIf;
		
		#EndRegion

		#Region FixingResults
		
		SetOfRecordsByDate = AccumulationRegisters[NameOfSettlementRegister].CreateRecordSet();
		SetOfPaymentPlanRecords = AccumulationRegisters[PaymentPlanRegisterName].CreateRecordSet();
		RecordsetShipmentPlanDeliveries = AccumulationRegisters[ShippingPlanRegisterNameDelivery].CreateRecordSet();
		
		CurrentVariables.TableOfCalculationsByTerms.GroupBy("Period, Recorder, RecordType, AccountingDimensionByPartners, ARAPObject, Currency, DocumentRecorder,
				|ARAPDocument, BusinessOperation, PlannedRepaymentDate, OccurrenceDate, SettlementProcedure, OperationProcedure,
				|DocumentCurrency, LinkedDocument, CashFlowItem, CorARAPObject, CorPartnerAccountingDimension,
				|CalculationObjectReceiver, DestinationAccountingDimensionByPartners, CurrencyReceiver, ReversingEntry,
				|BusinessTransactionSetting,FinRecordID,RecordingBeforeCalculationStarts,ByDataOfSourceARAPObject,SettlementTransaction,SettlementRecordType",
				"Prepayment, PrepaymentLocal, PrepaymentMan, Debt, DebtLocal, ARAPMan,AmountReceiver");
		// Filling in the types of settlement records for settlement transactions in distributed movements
		For Each StringOfRegisteredRecords In CurrentVariables.TableOfCalculationsByTerms Do
			If Not StringOfRegisteredRecords.RecordingBeforeCalculationStarts
				And Not ValueIsFilled(StringOfRegisteredRecords.SettlementRecordType) Then
				StringOfRegisteredRecords.SettlementRecordType = SettlementRecordType(StringOfRegisteredRecords);
			EndIf;
		EndDo;
		
		CurrentVariables.TableOfCalculationsByTerms.FillValues(CurrentVariables.AccountingDimensionByPartners, "AccountingDimensionByPartners");
		CurrentVariables.TableOfCalculationsByTerms.FillValues(CurrentVariables.ARAPObject,            "ARAPObject");
		CurrentVariables.TableOfCalculationsByTerms.FillValues(CurrentVariables.Currency,            "Currency");
		CurrentVariables.TableOfCalculationsByTerms.Indexes.Add("Recorder");
		
		If GlobalVariables.RecordChanges_ Then
			TableOfLoggers = TableOfFreeCalculationLoggers(CurrentVariables, GlobalVariables);
		EndIf;
		
		If Not GlobalVariables.OnlyPlannedCalculations And GlobalVariables.RecordChanges_ Then
			
			PrepareDataToRecord(CurrentVariables, CurrentVariables.TableOfCalculationsByTerms, SetOfRecordsByDate, TableOfLoggers);
			
			#Region CheckingRegisterChanges
			
			ChangesTable = Undefined;
			
			If CurrentVariables.PeriodForMonitoringChangesAndCreatingTasks < Date(3000,1,1) Then
			
				Query.Text = "
				|SELECT *
				|INTO TTMovementAfter
				|FROM  &TableByTerms AS RegisteredRecordsAfter
				|;
				|SELECT
				|	NestedQuery.Period                        AS Period,
				|	NestedQuery.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
				|	NestedQuery.ARAPObject                AS ARAPObject,
				|	NestedQuery.Currency                        AS Currency,
				|	NestedQuery.ARAPDocument             AS ARAPDocument,
				|	NestedQuery.PlannedRepaymentDate        AS PlannedRepaymentDate,
				|	NestedQuery.OccurrenceDate             AS OccurrenceDate,
				|	NestedQuery.BusinessOperation         AS BusinessOperation,
				|	NestedQuery.DocumentRecorder           AS DocumentRecorder,	
				|	SUM(NestedQuery.Prepayment)                    AS Prepayment,
				|	SUM(NestedQuery.PrepaymentLocal)                AS PrepaymentLocal,
				|	SUM(NestedQuery.PrepaymentMan)                 AS PrepaymentMan,
				|	SUM(NestedQuery.Debt)                          AS Debt,
				|	SUM(NestedQuery.DebtLocal)                      AS DebtLocal,
				|	SUM(NestedQuery.ARAPMan)                       AS ARAPMan,
				|	NestedQuery.DocumentRecorder REFS Document.OBEntryARAP AS CreateTasksByEndOfNextMonth
				|INTO ChangesTableCustomersARAPAccountingByDueDates
				|FROM
				|	(SELECT
				|		CalculationsByTerms.Period                        AS Period,
				|		CalculationsByTerms.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
				|		CalculationsByTerms.ARAPObject                AS ARAPObject,
				|		CalculationsByTerms.Currency                        AS Currency,
				|		CalculationsByTerms.ARAPDocument             AS ARAPDocument,
				|		CASE WHEN CalculationsByTerms.Prepayment <> 0 
				|			THEN DATETIME(1, 1, 1)
				|			ELSE CalculationsByTerms.PlannedRepaymentDate
				|		END                                         AS PlannedRepaymentDate,
				|		CalculationsByTerms.OccurrenceDate             AS OccurrenceDate,
				|		CASE WHEN VALUETYPE(CalculationsByTerms.DocumentRecorder)
				|						IN (TYPE(Document.SaleAdjustment),
				|						   TYPE(Document.PurchaseAdjustment))
				|			THEN VALUE(Enum.BusinessTransactions.EmptyRef)
				|			ELSE CalculationsByTerms.BusinessOperation
				|		END                                         AS BusinessOperation,
				|		CalculationsByTerms.DocumentRecorder           AS DocumentRecorder,
				|		
				|		CalculationsByTerms.Prepayment                    AS Prepayment,
				|		CalculationsByTerms.PrepaymentLocal                AS PrepaymentLocal,
				|		CalculationsByTerms.PrepaymentMan                 AS PrepaymentMan,
				|		CalculationsByTerms.Debt                          AS Debt,
				|		CalculationsByTerms.DebtLocal                      AS DebtLocal,
				|		CalculationsByTerms.ARAPMan                       AS ARAPMan
				|		
				|	FROM
				|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
				|	WHERE
				|		CalculationsByTerms.Active
				|		AND CalculationsByTerms.ARAPObject = &ARAPObject
				|		AND CalculationsByTerms.AccountingDimensionByPartners = &AccountingDimensionByPartners
				|		AND CalculationsByTerms.Period >= &PeriodForMonitoringChangesAndCreatingTasks
				|		AND NOT CalculationsByTerms.DocumentRecorder REFS Document.RegisterAdjustment
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		RegisteredRecordsAfter.Period                        AS Period,
				|		RegisteredRecordsAfter.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
				|		RegisteredRecordsAfter.ARAPObject                AS ARAPObject,
				|		RegisteredRecordsAfter.Currency                        AS Currency,
				|		RegisteredRecordsAfter.ARAPDocument             AS ARAPDocument,
				|		CASE WHEN RegisteredRecordsAfter.Prepayment <> 0 
				|			THEN DATETIME(1, 1, 1)
				|			ELSE RegisteredRecordsAfter.PlannedRepaymentDate
				|		END                                       AS PlannedRepaymentDate,
				|		RegisteredRecordsAfter.OccurrenceDate             AS OccurrenceDate,
				|		CASE WHEN VALUETYPE(RegisteredRecordsAfter.DocumentRecorder)
				|						IN (TYPE(Document.SaleAdjustment),
				|						   TYPE(Document.PurchaseAdjustment))
				|			THEN VALUE(Enum.BusinessTransactions.EmptyRef)
				|			ELSE RegisteredRecordsAfter.BusinessOperation
				|		END                                       AS BusinessOperation,
				|		RegisteredRecordsAfter.DocumentRecorder           AS DocumentRecorder,
				|		
				|		-RegisteredRecordsAfter.Prepayment                    AS Prepayment,
				|		-RegisteredRecordsAfter.PrepaymentLocal                AS PrepaymentLocal,
				|		-RegisteredRecordsAfter.PrepaymentMan                 AS PrepaymentMan,
				|		-RegisteredRecordsAfter.Debt                          AS Debt,
				|		-RegisteredRecordsAfter.DebtLocal                      AS DebtLocal,
				|		-RegisteredRecordsAfter.ARAPMan                       AS ARAPMan
				|	FROM
				|		TTMovementAfter AS RegisteredRecordsAfter
				|	WHERE
				|		RegisteredRecordsAfter.Period >= &PeriodForMonitoringChangesAndCreatingTasks) AS NestedQuery
				|GROUP BY
				|	NestedQuery.Period,
				|	NestedQuery.AccountingDimensionByPartners,
				|	NestedQuery.ARAPObject,
				|	NestedQuery.Currency,
				|	NestedQuery.ARAPDocument,
				|	NestedQuery.PlannedRepaymentDate,
				|	NestedQuery.OccurrenceDate,
				|	NestedQuery.BusinessOperation,
				|	NestedQuery.DocumentRecorder
				|HAVING
				|	SUM(NestedQuery.Prepayment) <> 0
				|	OR SUM(NestedQuery.PrepaymentLocal) <> 0
				|	OR SUM(NestedQuery.PrepaymentMan) <> 0
				|	OR SUM(NestedQuery.Debt) <> 0
				|	OR SUM(NestedQuery.DebtLocal) <> 0
				|	OR SUM(NestedQuery.ARAPMan) <> 0";
				
				If Not CurrentVariables.TheseAreSettlementsWithCustomers Then
					Query.Text = StrReplace(Query.Text,
						"AccumulationRegister.CustomersARAPAccountingByDueDates",
						"AccumulationRegister.VendorsARAPAccountingByDueDates");
					Query.Text = StrReplace(Query.Text,
						"ChangesTableCustomersARAPAccountingByDueDates",
						"ChangesTableVendorsARAPAccountingByDueDates");
				EndIf;
				
				CalculationsToCheck = CurrentVariables.TableOfCalculationsByTerms.Copy(New Structure("RecordingBeforeCalculationStarts",False));
				
				Query.SetParameter("TableByTerms", CalculationsToCheck);
				Query.SetParameter("ArrayOfLoggersInvolved",
					CurrentVariables["ArrayOfLoggersInvolved"
						+ ?(CurrentVariables.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting,"CustomersARAPAccountingByDueDates","VendorsARAPAccountingByDueDates")]);
						
				If ValueIsFilled(CurrentVariables.PeriodForMonitoringChangesAndCreatingTasks) Then
					Query.SetParameter("PeriodForMonitoringChangesAndCreatingTasks", CurrentVariables.PeriodForMonitoringChangesAndCreatingTasks);
				Else
					Query.SetParameter("PeriodForMonitoringChangesAndCreatingTasks", CurrentVariables.RecalculationStartDate);
				EndIf;
				
				Query.Execute();
				
				If ExchangePlans.MasterNode() = Undefined Then
					InformationRegisters.JobsForARAPAllocating.CreateNonOperationalQueueTasksONChangeOfDueDateCalculations(
						Query.TempTablesManager, CurrentVariables.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
				EndIf;
				
				If CurrentVariables.TheseAreSettlementsWithCustomers Then
					
					ReflectionUpdateText =
					"SELECT
					|	ChangesTable.DocumentRecorder AS Recorder
					|FROM
					|	ChangesTableCustomersARAPAccountingByDueDates AS ChangesTable
					|GROUP BY
					|	ChangesTable.DocumentRecorder";
					ReflectionUpdateText =
					"SELECT
					|	ChangesTable.DocumentRecorder AS Recorder,
					|	ChangesTable.Period AS Period,
					|	ChangesTable.AccountingDimensionByPartners AS AccountingDimensionByPartners
					|FROM
					|	ChangesTableCustomersARAPAccountingByDueDates AS ChangesTable
					|GROUP BY
					|	ChangesTable.DocumentRecorder,
					|	ChangesTable.Period,
					|	ChangesTable.AccountingDimensionByPartners";
					Query.Text = ReflectionUpdateText;
					
					ChangesTable = Query.Execute().Unload();
					
					#Region CheckingBanDate
					
					RequestToCheckBanDate = New Query("
					|SELECT
					|	ISNULL(MIN(ChangesTable.Period),DATETIME(3999,1,1)) AS Period
					|FROM
					|	ChangesTableCustomersARAPAccountingByDueDates AS ChangesTable
					|GROUP BY
					|	ISNULL(ChangesTable.ARAPObject.Organization, UNDEFINED)");
					
					RequestToCheckBanDate.TempTablesManager = Query.TempTablesManager;
					MinimumPeriodSelection = RequestToCheckBanDate.Execute().Select();
					DataToCheck = PeriodClosingDates.DataToCheckTemplate();
					While MinimumPeriodSelection.Next() Do
						NewRow = DataToCheck.Add();
						NewRow.Date   = BegOfDay(MinimumPeriodSelection.Period);
						NewRow.Object = StringOfBasicCalculationParameters.Organization;
						NewRow.Section = "FinancialOutline";
					EndDo;
					
					ErrorDescription = NStr("vi = 'Dữ liệu khấu trừ thay đổi đang trong kỳ đóng.';
											|ru = 'Изменяемые данные взаиморасчетов находятся в закрытом периоде.';
											|en = 'AR/AP data being changed is in the closed period.'; fa = 'AR/AP data being changed is in the closed period.';
											|it = 'I dati delle obbligazioni reciproche da modificare si riferiscono a un periodo chiuso.';
											|pl = 'Zmieniane dane rozliczeń wzajemnych znajdują się w zamkniętym okresie.';
											|tr = 'Mutabakatların değişen verileri kapalı dönemdedir.'");
					
					If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, SetOfRecordsByDate) Then
						Raise ErrorDescription;
					EndIf;
					#EndRegion
					LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(ChangesTable);
					FinancialAccountingPostingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInInternationalAccounting(ChangesTable);
					Query.Text =
					"SELECT DISTINCT
					|	BEGINOFPERIOD(Changes.Period, MONTH)         AS Period,
					|	Changes.ARAPDocument                    AS Document,
					|	Changes.AccountingDimensionByPartners.Counterparty AS Counterparty
					|FROM
					|	ChangesTableCustomersARAPAccountingByDueDates AS Changes";
					
					NdsupChanges = Query.Execute().Unload();
					
					DocumentEmulation = DocumentsPosting.DocumentEmulation(Undefined, Undefined);
					DocumentEmulation.AdditionalProperties.DocumentsPosting.DocumentProperties =
						New Structure(DocumentEmulation.AdditionalProperties.DocumentsPosting.DocumentProperties);
					DocumentEmulation.AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode = DocumentWriteMode.Posting;
					MonthEndTransactionsServer.ReflectTasksByEndOfMonth(DocumentEmulation, Query.TempTablesManager);
					
				Else
					
					ReflectionUpdateText =
					"SELECT
					|	ChangesTable.DocumentRecorder AS Recorder
					|FROM
					|	ChangesTableVendorsARAPAccountingByDueDates AS ChangesTable
					|GROUP BY
					|	ChangesTable.DocumentRecorder";
					ReflectionUpdateText =
					"SELECT
					|	ChangesTable.DocumentRecorder AS Recorder,
					|	ChangesTable.Period AS Period,
					|	ChangesTable.AccountingDimensionByPartners AS AccountingDimensionByPartners
					|FROM
					|	ChangesTableVendorsARAPAccountingByDueDates AS ChangesTable
					|GROUP BY
					|	ChangesTable.DocumentRecorder,
					|	ChangesTable.Period,
					|	ChangesTable.AccountingDimensionByPartners";
					Query.Text = ReflectionUpdateText;
						
					ChangesTable = Query.Execute().Unload();
					
					#Region CheckingBanDate
					
					RequestToCheckBanDate = New Query("SELECT
					|	ISNULL(MIN(ChangesTable.Period), DATETIME(3999, 1, 1)) AS Period
					|FROM
					|	ChangesTableVendorsARAPAccountingByDueDates AS ChangesTable
					|GROUP BY
					|	ISNULL(ChangesTable.ARAPObject.Organization, UNDEFINED)");
					
					RequestToCheckBanDate.TempTablesManager = Query.TempTablesManager;
					MinimumPeriodSelection = RequestToCheckBanDate.Execute().Select();
					DataToCheck = PeriodClosingDates.DataToCheckTemplate();
					
					While MinimumPeriodSelection.Next() Do
						NewRow = DataToCheck.Add();
						NewRow.Date = BegOfDay(MinimumPeriodSelection.Period);
						NewRow.Object = StringOfBasicCalculationParameters.Organization;
						NewRow.Section = "FinancialOutline";
					EndDo;
					ErrorDescription = NStr("vi = 'Dữ liệu khấu trừ thay đổi đang trong kỳ đóng.';
											|ru = 'Изменяемые данные взаиморасчетов находятся в закрытом периоде.';
											|en = 'AR/AP data being changed is in the closed period.'; fa = 'AR/AP data being changed is in the closed period.';
											|it = 'I dati delle obbligazioni reciproche da modificare si riferiscono a un periodo chiuso.';
											|pl = 'Zmieniane dane rozliczeń wzajemnych znajdują się w zamkniętym okresie.';
											|tr = 'Mutabakatların değişen verileri kapalı dönemdedir.'");
					If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, SetOfRecordsByDate) Then
						Raise ErrorDescription;
					EndIf;
					#EndRegion
					LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(ChangesTable);
					FinancialAccountingPostingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInInternationalAccounting(ChangesTable);
					Query.Text =
					"SELECT DISTINCT
					|	BEGINOFPERIOD(Changes.Period, MONTH)         AS Period,
					|	Changes.DocumentRecorder                          AS Document,
					|	Changes.AccountingDimensionByPartners.Counterparty AS Counterparty
					|FROM
					|	ChangesTableVendorsARAPAccountingByDueDates AS Changes
					|
					|UNION
					|
					|SELECT DISTINCT
					|	BEGINOFPERIOD(Changes.Period, MONTH)         AS Period,
					|	Changes.ARAPDocument                    AS Document,
					|	Changes.AccountingDimensionByPartners.Counterparty AS Counterparty
					|FROM
					|	ChangesTableVendorsARAPAccountingByDueDates AS Changes";
					
					NdsupChanges = Query.Execute().Unload();
					
					DocumentEmulation = DocumentsPosting.DocumentEmulation(Undefined, Undefined);
					DocumentEmulation.AdditionalProperties.DocumentsPosting.DocumentProperties =
						New Structure(DocumentEmulation.AdditionalProperties.DocumentsPosting.DocumentProperties);
					DocumentEmulation.AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode = DocumentWriteMode.Posting;
					MonthEndTransactionsServer.ReflectTasksByEndOfMonth(DocumentEmulation, Query.TempTablesManager);
					
				EndIf;
				
				CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "TTMovementAfter");
		
			EndIf;
			
			#EndRegion
			
			WriteInPortions(CurrentVariables, CurrentVariables.TableOfCalculationsByTerms, SetOfRecordsByDate);
			
			If CurrentVariables.PeriodForMonitoringChangesAndCreatingTasks < Date(3000,1,1) Then
				If CurrentVariables.TheseAreSettlementsWithCustomers Then
					VATAccountingERP.ReflectChangesInSettlementsWithCustomersInVATAccounting(NdsupChanges);
					// We destroy the temporary table of changes, because different sets of records can be recorded with the same query manager.
					CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "ChangesTableCustomersARAPAccountingByDueDates");
				Else
					VATAccountingERP.ReflectChangesInSettlementsWithSuppliersInVATAccounting(NdsupChanges);
					// We destroy the temporary table of changes, because different sets of records can be recorded with the same query manager.
					CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, "ChangesTableVendorsARAPAccountingByDueDates");
				EndIf;
			EndIf;
			
			EndIf;
			
			If ChangesTable <> Undefined And ChangesTable.Count() > 0 Then
				ARAPAccountingInternal.RemoveSystemRegisterAdjustments(CurrentVariables.RecalculationStartDate, CurrentVariables.Organization,, CurrentVariables.Counterparty);
			EndIf;
		
		If GlobalVariables.RecordChanges_ Then
		
			//Incoming movements are written directly by documents
			PaymentPlanTable = CurrentVariables.PaymentPlanTable.Copy(New Structure("RecordType", AccumulationRecordType.Expense));
			PaymentPlanTable.GroupBy("Period, Recorder, RecordType, AccountingDimensionByPartners, ARAPObject, Currency, DocumentRecorder,
					|DocumentPlan, PlannedRepaymentDate, OccurrenceDate, PaymentOption, OperationProcedure, UnallocatedAdvancePayment,DocumentPayments",
					"AmountDue");
			
			PaymentPlanTable.FillValues(CurrentVariables.AccountingDimensionByPartners, "AccountingDimensionByPartners");
			PaymentPlanTable.FillValues(CurrentVariables.ARAPObject,            "ARAPObject");
			PaymentPlanTable.FillValues(CurrentVariables.Currency,            "Currency");
			PaymentPlanTable.Indexes.Add("Recorder");
		
			PrepareDataToRecord(CurrentVariables, PaymentPlanTable, SetOfPaymentPlanRecords, TableOfLoggers);
			WriteInPortions(CurrentVariables, PaymentPlanTable, SetOfPaymentPlanRecords);
			
		EndIf;
		
		If GlobalVariables.RecordChanges_ Then
			
			TableShipmentPlanDeliveries = TableShipmentPlanDeliveries.Copy(New Structure("RecordType", AccumulationRecordType.Expense));
			
			TableShipmentPlanDeliveries.FillValues(CurrentVariables.AccountingDimensionByPartners, "AccountingDimensionByPartners");
			TableShipmentPlanDeliveries.FillValues(CurrentVariables.ARAPObject,            "ARAPObject");
			TableShipmentPlanDeliveries.FillValues(CurrentVariables.Currency,            "Currency");
			TableShipmentPlanDeliveries.Indexes.Add("Recorder");
		
			PrepareDataToRecord(CurrentVariables, TableShipmentPlanDeliveries, RecordsetShipmentPlanDeliveries, TableOfLoggers);
			WriteInPortions(CurrentVariables, TableShipmentPlanDeliveries, RecordsetShipmentPlanDeliveries);
			
		EndIf;
		
		If ExchangePlans.MasterNode() = Undefined And Not GlobalVariables.OnlyPlannedCalculations And GlobalVariables.RecordChanges_ Then
			RemoveUnusedSettlementLoggers(Query, NameOfSettlementRegister, PaymentPlanRegisterName, ShippingPlanRegisterNameDelivery);
		EndIf;
		
		#EndRegion
		
	EndDo;
	
	//Used to correct Balances
	If MainParameters.Property("CalculatedRegisteredRecords") And ExtendedTableToDistribution.Count() = 1 Then
		
		If GlobalVariables.TheseAreSettlementsWithCustomers Then
			RegisterName = "CustomersARAPAccountingByDueDates";
		Else 
			RegisterName = "VendorsARAPAccountingByDueDates";
		EndIf;
		MainParameters.CalculatedRegisteredRecords.Insert(
			RegisterName,
			CurrentVariables.TableOfCalculationsByTerms);
		
	EndIf;
	
EndProcedure

// Causes the redistribution of settlements across the tuple table. Supplements receivers, if necessary, and distributes in portions, 
// if you need a sequential recalculation of different AR/AP objects. 
//	
// Parameters:
//	DistributionParameters - See CalculationDistributionParameters
//	SourceTableForDistribution - ValueTable:
//		* PaymentType_ - EnumRef.PartnersARAPAccountingTypes 
//		* AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners
//		* ARAPObject - CatalogRef.ARAPObjects
//		* Currency - CatalogRef.Currencies
//		* RecalculationStartDate - Date - Minimum period of changes or start of recalculation
//		* PeriodForMonitoringChangesAndCreatingTasks - Date - The date starting from which changes are to be checked and child tasks are to be created.
//
//		* DestinationAccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners
//		* CalculationObjectReceiver - CatalogRef.ARAPObjects
//		* CurrencyReceiver - CatalogRef.Currencies
//		* ByDataOfSourceARAPObject - Boolean
//		* Document - DocumentRef - The registrar of Registered Records of settlements.
//
Procedure FillInOperationalARAPAccountsAccordingToTable(DistributionParameters, SourceTableForDistribution) Export
	
	If SourceTableForDistribution.Count() = 0 Then
		Return;
	EndIf;
	
	If Not DistributionParameters.SupplementDistributeReceivers Then
		
		TableToDistribution = TableToDistribution();
		
		Fields = "PaymentType_,AccountingDimensionByPartners,ARAPObject,Currency";
		SelectionOfTuples = New Structure(Fields);
		
		Tuples = SourceTableForDistribution.Copy();
		Tuples.GroupBy(Fields);
		For Each Tuple In Tuples Do
			RowToDistribution = TableToDistribution.Add();
			RowToDistribution.PaymentType_ = Tuple.PaymentType_;
			RowToDistribution.AccountingDimensionByPartners = Tuple.AccountingDimensionByPartners;
			RowToDistribution.ARAPObject = Tuple.ARAPObject;
			RowToDistribution.Currency = Tuple.Currency;
			
			FillPropertyValues(SelectionOfTuples, Tuple);
			TupleRows = SourceTableForDistribution.FindRows(SelectionOfTuples);
			For Each TupleString In TupleRows Do
				If ValueIsFilled(RowToDistribution.RecalculationStartDate) Then
					RowToDistribution.RecalculationStartDate = Min(TupleString.RecalculationStartDate, RowToDistribution.RecalculationStartDate);
				Else
					RowToDistribution.RecalculationStartDate = TupleString.RecalculationStartDate;
				EndIf;
				
				If ValueIsFilled(RowToDistribution.PeriodForMonitoringChangesAndCreatingTasks) Then
					RowToDistribution.PeriodForMonitoringChangesAndCreatingTasks = Min(TupleString.PeriodForMonitoringChangesAndCreatingTasks, RowToDistribution.PeriodForMonitoringChangesAndCreatingTasks);
				Else
					RowToDistribution.PeriodForMonitoringChangesAndCreatingTasks = TupleString.PeriodForMonitoringChangesAndCreatingTasks;
				EndIf;

			EndDo;
		EndDo;
		
		CompleteOperationalSettlements(DistributionParameters, TableToDistribution);
	Else
		// We are looking for all dependent calculation objects affected by the redistribution of Cur and add them to the general table
		LinkTable = TableOfSourceReceiverRelationships(SourceTableForDistribution);
		LinkTable.Sort("OperationProcedure, ByDataOfSourceARAPObject");
		
		// Let's divide all the lines into portions: the distribution of each next portion depends on the distribution of the previous one
		LinkTable.Columns.Add("PortionNumber", New TypeDescription("Number"));
		// A document is required to fill in the task register
		LinkTable.Columns.Add("DocumentSource", Documents.AllRefsType());
		LinkTable.Indexes.Add("DestinationAccountingDimensionByPartners, CalculationObjectReceiver, CurrencyReceiver");
		SelectionOfReceivers = New Structure("DestinationAccountingDimensionByPartners, CalculationObjectReceiver, CurrencyReceiver");
		
		MaximumServingNumber = 0;
		For Each RowToDistribution In LinkTable Do
			
			SelectionOfReceivers.DestinationAccountingDimensionByPartners = RowToDistribution.AccountingDimensionByPartners;
			SelectionOfReceivers.CalculationObjectReceiver = RowToDistribution.ARAPObject;
			SelectionOfReceivers.CurrencyReceiver = RowToDistribution.Currency;
			
			RowsSources = LinkTable.FindRows(SelectionOfReceivers);
			
			For Each SourceRow In RowsSources Do
				// The distribution string is the receiver of the found string and should be distributed in the next batch if it has the same or later day
				If SourceRow.OperationProcedure <= RowToDistribution.OperationProcedure
					And RowToDistribution.PortionNumber <= SourceRow.PortionNumber Then
					RowToDistribution.PortionNumber = SourceRow.PortionNumber + 1;
					// Let's write down the registrar who initiated the increase in the portion to record the tasks.
					RowToDistribution.DocumentSource = SourceRow.Recorder;
					MaximumServingNumber = Max(MaximumServingNumber, RowToDistribution.PortionNumber);
				EndIf;
			EndDo;
			
		EndDo;
		
		PortionFields = "PortionNumber,AccountingDimensionByPartners,ARAPObject,Currency";
		LinkTable.Indexes.Add(PortionFields);
		FilterPortions = New Structure(PortionFields);
		
		TuplesOfChangeTable = LinkTable.Copy(, "PortionNumber,AccountingDimensionByPartners,Organization,ARAPObject,Currency,PaymentType_,DocumentSource");
		TuplesOfChangeTable.GroupBy("PortionNumber,AccountingDimensionByPartners,Organization,ARAPObject,Currency,PaymentType_,DocumentSource");
		TuplesOfChangeTable.Indexes.Add("PortionNumber");
		
		// It is needed to distribute all related tuples within one day in order not to register tasks again.
		MinimumStartDateForRecalculationOfZeroPortion = Date(3999, 1, 1);
		For Each RowToDistribution In LinkTable Do
			If RowToDistribution.PortionNumber = 0 Then
				MinimumStartDateForRecalculationOfZeroPortion = Min(MinimumStartDateForRecalculationOfZeroPortion, RowToDistribution.RecalculationStartDate);
			EndIf;
		EndDo;
		
		// If you need to register tasks, then we will distribute all portions that have connections during the first day of the zero portion
		If DistributionParameters.RegisterTasksByReceivers Then
			NumberOfServingsToBeProcessed = 0;
			For Each RowToDistribution In LinkTable Do
				If RowToDistribution.RecalculationStartDate <= MinimumStartDateForRecalculationOfZeroPortion
					And RowToDistribution.PortionNumber >= NumberOfServingsToBeProcessed Then
					NumberOfServingsToBeProcessed = RowToDistribution.PortionNumber + 1;
				EndIf;
			EndDo;
		Else
			// Distribute all portions
			NumberOfServingsToBeProcessed = MaximumServingNumber + 1;
		EndIf;
		
		// Let's perform the distribution of each portion in order
		For PortionNumber = 0 To MaximumServingNumber Do
			
			TuplesRows = TuplesOfChangeTable.Copy(New Structure("PortionNumber", PortionNumber));
			
			If NumberOfServingsToBeProcessed > 0 Then
				
				TuplesRows.GroupBy("PortionNumber,AccountingDimensionByPartners,ARAPObject,Currency,PaymentType_");
				TableForPortionDistribution = TableToDistribution();
				
				For Each TupleString In TuplesRows Do
					
					StringOfBasicCalculationParameters = TableForPortionDistribution.Add();
					
					// Fill in the key fields - partner accounting analytics, settlement object, currency and type of settlement
					FillPropertyValues(StringOfBasicCalculationParameters, TupleString);
					
					// We are looking for the minimum start date of recalculation and the period of change control among the source data
					FillPropertyValues(FilterPortions, TupleString);
					OriginalLines = LinkTable.FindRows(FilterPortions);
					If OriginalLines.Count() = 0 Then
						Raise(NStr("ru = 'Не найдены исходные строки при определении даты начала пересчета.';
									|vi = 'The source strings were not found when determining the recalculation start date.';
									|en = 'The source strings were not found when determining the recalculation start date.'; fa = 'The source strings were not found when determining the recalculation start date.';
									|it = 'The source strings were not found when determining the recalculation start date.';
									|pl = 'The source strings were not found when determining the recalculation start date.';
									|tr = 'Sayım başlangıç tarihi belirlenirken kaynak satırlar bulunamadı.'"));
					EndIf;
					For Each ChangesRow In OriginalLines Do
						
						If ValueIsFilled(StringOfBasicCalculationParameters.RecalculationStartDate) Then
							StringOfBasicCalculationParameters.RecalculationStartDate = Min(ChangesRow.RecalculationStartDate, StringOfBasicCalculationParameters.RecalculationStartDate);
						Else
							StringOfBasicCalculationParameters.RecalculationStartDate = ChangesRow.RecalculationStartDate;
						EndIf;
						
						If ValueIsFilled(StringOfBasicCalculationParameters.PeriodForMonitoringChangesAndCreatingTasks) Then
							StringOfBasicCalculationParameters.PeriodForMonitoringChangesAndCreatingTasks = 
								Min(StringOfBasicCalculationParameters.PeriodForMonitoringChangesAndCreatingTasks, ChangesRow.PeriodForMonitoringChangesAndCreatingTasks);
						Else
							StringOfBasicCalculationParameters.PeriodForMonitoringChangesAndCreatingTasks = ChangesRow.PeriodForMonitoringChangesAndCreatingTasks;
						EndIf;
						
					EndDo;
					
				EndDo;
				
				CompleteOperationalSettlements(DistributionParameters, TableForPortionDistribution);
				
			Else
				
				TableForRegisteringTasks = InformationRegisters.JobsForARAPAllocating.TaskGenerationTable();
				
				For Each TupleString In TuplesRows Do
					
					JobRow = TableForRegisteringTasks.Add();
					
					JobRow.Organization               = TupleString.Organization;
					JobRow.Document                  = TupleString.DocumentSource;
					JobRow.AccountingDimensionByPartners = TupleString.AccountingDimensionByPartners;
					JobRow.ARAPObject            = TupleString.ARAPObject;
					JobRow.Currency                    = TupleString.Currency;
					
					// We are looking for the minimum start date of recalculation and the period of change control among the source data
					FillPropertyValues(FilterPortions, TupleString);
					OriginalLines = LinkTable.FindRows(FilterPortions);
					If OriginalLines.Count() = 0 Then
						Raise(NStr("ru = 'Не найдены исходные строки при определении даты начала пересчета.';
									|vi = 'The source strings were not found when determining the recalculation start date.';
									|en = 'The source strings were not found when determining the recalculation start date.'; fa = 'The source strings were not found when determining the recalculation start date.';
									|it = 'The source strings were not found when determining the recalculation start date.';
									|pl = 'The source strings were not found when determining the recalculation start date.';
									|tr = 'Sayım başlangıç tarihi belirlenirken kaynak satırlar bulunamadı.'"));
					EndIf;
					For Each ChangesRow In OriginalLines Do
						
						If ValueIsFilled(JobRow.TaskPeriod) Then
							JobRow.TaskPeriod = Min(ChangesRow.RecalculationStartDate, JobRow.TaskPeriod);
						Else
							JobRow.TaskPeriod = ChangesRow.RecalculationStartDate;
						EndIf;
						
						If ValueIsFilled(JobRow.ChangeControlPeriod) Then
							JobRow.ChangeControlPeriod = 
								Min(JobRow.ChangeControlPeriod, ChangesRow.PeriodForMonitoringChangesAndCreatingTasks);
						Else
							JobRow.ChangeControlPeriod = ChangesRow.PeriodForMonitoringChangesAndCreatingTasks;
						EndIf;
						
					EndDo;
					
				EndDo;
				
				InformationRegisters.JobsForARAPAllocating.CreateTasksBasedOnDataFromValueTable(TableForRegisteringTasks);
				
				// We register only 1 portion of receivers.
				Break;
				
			EndIf;
			
			NumberOfServingsToBeProcessed = NumberOfServingsToBeProcessed - 1;
			
		EndDo;
	EndIf;
	
EndProcedure

// Deprecated. Recalculates all exchange rate differences for the specified period.
//
// Parameters:
//	CompanyArray - Array of CatalogRef.Companies- The list of organizations that need to be re-evaluated.
//	BeginOfPeriod - Date - The beginning of the period of translation of exchange differences.
//	EndOfPeriod - Date - The end of the period of translation of exchange differences.
//  Parameters - See RevaluationParameters
//
Procedure PerformRevaluationForPeriod(CompanyArray, Val BeginOfPeriod, Val EndOfPeriod, Parameters) Export
	
	ARAPAccountingRevaluationServer.PerformRevaluationForPeriod(CompanyArray, BeginOfPeriod, EndOfPeriod, Parameters);
	
EndProcedure

// Deprecated. Adds entries to the revaluation on the same date.
//
// Parameters:
//	CompanyArray - Array of CatalogRef.Companies - The list of organizations that need to be re-evaluated.
//	Period - Date - The date at the end of which the revaluation should be performed.
//  Parameters - See RevaluationParameters 
//
Procedure PerformRevaluationOnDate(CompanyArray, Period, Parameters) Export
	
	ARAPAccountingRevaluationServer.PerformRevaluationOnDate(CompanyArray, Period, Parameters);
	
EndProcedure

//Returns the string order of the document by the passed parameters.
// 
// Parameters:
// 	Date - Date - The date by which you want to make a string order.
// 	Number - String - document number.
// 	DocumentType - Type - The document reference type.
// 	TypeOfOperationForSorting - String - type of operation in the order of credit "By type of document"
// 	TypeAsString - String - See TypeNumber.
// 	OrderOfOperationsWithinDocument - String - the number of operations within the same Recorders.
// Returns:
// 	String - LongDesc
Function Order(Date, Number, DocumentType, TypeOfOperationForSorting, TypeAsString = Undefined, OrderOfOperationsWithinDocument = "1") Export
	If Not ValueIsFilled(Date) Then 
		Return Undefined;
	EndIf;
	DateAsString = Format(Date, "DF=yyyyMMddHHmmss");
	If TypeAsString = Undefined Then
		TypeAsString = TypeNumber(DocumentType);
	EndIf;
	Return Left(DateAsString, 8) + TypeOfOperationForSorting + Right(DateAsString, 6) + TypeAsString + Number + OrderOfOperationsWithinDocument;
EndFunction

// Returns the structure of the parameters required to fill in the settlement registers.
// 
// Returns:
//  Structure - Structure Of Settlement Parameters:
// * OnlyPlannedCalculations - Boolean - True, if you need to calculate everything, but write down only the planned calculations. 
// 			It is used to add changes to the change control table when the event is canceled and to exclude it from returning to reflection under Local and IFRS.
// * RecordChanges_ - Boolean - False if you want to get a table of generated RegisteredRecorded changes.
// * SupplementDistributeReceivers - Boolean - A sign that distribution tables need to be recursively supplemented with receivers.
// * RegisterTasksByReceivers - Boolean - It is necessary to distribute the minimum number of portions in the current call, 
// 						and register tasks for the deferred distribution of settlements by receivers.
Function CalculationDistributionParameters() Export
	
	Structure = New Structure;
	Structure.Insert("OnlyPlannedCalculations", False);
	Structure.Insert("RecordChanges_", True);
	Structure.Insert("SupplementDistributeReceivers", False);
	Structure.Insert("RegisterTasksByReceivers", False);
	
	Return Structure;
	
EndFunction

// The table is for distribution.
// 
// Returns:
//  ValueTable - Table To Distribution:
// * PaymentType_ - EnumRef.PartnersARAPAccountingTypes - Type of settlements - with customers or with suppliers, to determine which register to recalculate.
// * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics for recalculation.
// * ARAPObject - CatalogRef.ARAPObjects - AR/AP object to be recalculated
// * Currency - CatalogRef.Currencies - Currency of mutual settlements to be recalculated
// * RecalculationStartDate - Date - The date of the start of recalculation will be given by the beginning of the day.
// * PeriodForMonitoringChangesAndCreatingTasks - Date - The date from which you want to perform change control and create child tasks.
Function TableToDistribution() Export
	
	Table = New ValueTable;
	Table.Columns.Add("PaymentType_", New TypeDescription("EnumRef.PartnersARAPAccountingTypes"));
	Table.Columns.Add("AccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
	Table.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	Table.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	Table.Columns.Add("RecalculationStartDate", Common.DateTypeDetails(DateFractions.Date));
	Table.Columns.Add("PeriodForMonitoringChangesAndCreatingTasks", Common.DateTypeDetails(DateFractions.Date));
	
	Return Table;
	
EndFunction

#Region SettlementRegistrars

//Returns the table of service documents of the calculation Logger for overwriting by the passed parameters.
//
// Parameters:
//	CurrentVariables - Structure - LongDesc:
//		* ARAPObject - CatalogRef.ARAPObjects - The object of calculations.
//		* AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Settlement analytics.
//		* Currency - CatalogRef.Currencies - The currency of mutual settlements.
//		* TheseAreSettlementsWithCustomers - Boolean - these are settlements with customers, not with suppliers.
//		* Organization - CatalogRef.Companies - Organization of the calculation.
//	TableName - String - the name of the Accumulation register, which will determine the free registrar or not.
//	RecordsCount - Number - The number of entries to be subsequently written to the register.
//	TableOfFreeRegistrars - See TableOfFreeCalculationLoggers.
//
// Returns:
//	ValueTable - a table with the following columns:
//		* Ref - DocumentRef.ARAPAccountingRecorder - service document found;
//		* CleaningRequired - Boolean - In this document there are movements in the given table.
//
Function FreeSettlementRegistrars(CurrentVariables, TableName, RecordsCount, TableOfFreeRegistrars)
	
	If RecordsCount = 0 Then
		NumberOfRegistrars = 0;
	Else
		NumberOfRegistrars = Int(RecordsCount/RecordPortionSize()) + 1;
	EndIf;
	
	DocumentsTable = New ValueTable();
	DocumentsTable.Columns.Add("Ref", New TypeDescription("DocumentRef.ARAPAccountingRecorder"));
	DocumentsTable.Columns.Add("CleaningRequired", New TypeDescription("Boolean"));
	
	PaymentType_ = ?(CurrentVariables.TheseAreSettlementsWithCustomers, Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	
	FreeRecorders = TableOfFreeRegistrars.FindRows(New Structure("TableName", TableName));
	
	For Each LineFreeRecorders In FreeRecorders Do
		FillPropertyValues(DocumentsTable.Add(), LineFreeRecorders);
	EndDo;
	
	ListOfSettlementTablesWithPartners = New Array;
	If CurrentVariables.TheseAreSettlementsWithCustomers Then
		ListOfSettlementTablesWithPartners.Add("CustomersARAPAccountingByDueDates");
		ListOfSettlementTablesWithPartners.Add("CustomersARAPAccountingCashFlowPlan");
		ListOfSettlementTablesWithPartners.Add("CustomersARAPAccountingPlannedShipments");
	Else
		ListOfSettlementTablesWithPartners.Add("VendorsARAPAccountingByDueDates");
		ListOfSettlementTablesWithPartners.Add("VendorsARAPAccountingCashFlowPlan");
		ListOfSettlementTablesWithPartners.Add("VendorsARAPAccountingPlannedDeliveries");
	EndIf;
	
	While DocumentsTable.Count() < NumberOfRegistrars Do
		DocumentObject = Documents.ARAPAccountingRecorder.CreateDocument();
		DocumentObject.Currency = CurrentVariables.Currency;
		DocumentObject.AccountingDimensionByPartners = CurrentVariables.AccountingDimensionByPartners;
		DocumentObject.Organization = CurrentVariables.Organization;
		DocumentObject.ARAPObject = CurrentVariables.ARAPObject;
		DocumentObject.PaymentType_ = PaymentType_;
		DocumentObject.Date = CurrentSessionDate();
		DocumentObject.Write(DocumentWriteMode.Posting);
		
		NwRw = DocumentsTable.Add();
		NwRw.Ref = DocumentObject.Ref;
		NwRw.CleaningRequired = False;
		
		For Each Table In ListOfSettlementTablesWithPartners Do
			FreeRecorder = TableOfFreeRegistrars.Add();
			FreeRecorder.TableName = Table;
			FreeRecorder.Ref = DocumentObject.Ref;
			FreeRecorder.CleaningRequired = False;
		EndDo;
		
	EndDo;
	
	Return DocumentsTable;
	
EndFunction

// Table of free calculation loggers.
// 
// Parameters:
//	CurrentVariables - Structure - LongDesc:
//		* ARAPObject - DefinedType.ARAPObject - The object of calculations.
//		* AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Settlement analytics.
//		* Currency - CatalogRef.Currencies - The currency of mutual settlements.
//		* TheseAreSettlementsWithCustomers - Boolean - these are settlements with customers, not with suppliers.
//		* Organization - Undefined, CatalogRef.Companies - Organization of the calculation.
//	GlobalVariables - Structure - It may contain information about full payment registrars, if any.
// 
// Returns:
//	ValueTable - a table with the following columns:
//		* TableName - String - Name of the Accumulation register;
//		* Ref - DocumentRef.ARAPAccountingRecorder - service document found;
//		* CleaningRequired - Boolean - In this document there are movements in the given table.
//
//  
Function TableOfFreeCalculationLoggers(CurrentVariables, GlobalVariables)
		
	If CurrentVariables.TheseAreSettlementsWithCustomers Then
		TableCalculationsByTime             = "CustomersARAPAccountingByDueDates";
		TableCalculationsPaymentPlan            = "CustomersARAPAccountingCashFlowPlan";
		TableCalculationsPlanOfShipmentsDeliveries = "CustomersARAPAccountingPlannedShipments";
	Else
		TableCalculationsByTime             = "VendorsARAPAccountingByDueDates";
		TableCalculationsPaymentPlan            = "VendorsARAPAccountingCashFlowPlan";
		TableCalculationsPlanOfShipmentsDeliveries = "VendorsARAPAccountingPlannedDeliveries";
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Currency",                    CurrentVariables.Currency);
	Query.SetParameter("AccountingDimensionByPartners", CurrentVariables.AccountingDimensionByPartners);
	Query.SetParameter("ARAPObject",            CurrentVariables.ARAPObject);
	Query.SetParameter("TableCalculationsByTime",    TableCalculationsByTime);
	Query.SetParameter("TableCalculationsPaymentPlan",   TableCalculationsPaymentPlan);
	Query.SetParameter("TableCalculationsPlanOfShipmentsDeliveries", TableCalculationsPlanOfShipmentsDeliveries);
	
	EmptyRecordersOfCalculations = Documents.ARAPAccountingRecorder.EmptyRef();
	
	If CommonClientServer.HasAttributeOrObjectProperty(GlobalVariables,TableCalculationsByTime + "Recorders") Then
		ListOfFullRecordersDueDateCalculations = Common.CopyRecursive(GlobalVariables[TableCalculationsByTime + "Recorders"]);
	Else
		ListOfFullRecordersDueDateCalculations = New Array;
	EndIf;
	ListOfFullRecordersDueDateCalculations.Add(EmptyRecordersOfCalculations);
	
	Query.SetParameter("ListOfFullRecordersDueDateCalculations", ListOfFullRecordersDueDateCalculations);
	
	ListOfFullRecordersByTables = New Array;
		
		If CommonClientServer.HasAttributeOrObjectProperty(GlobalVariables, TableCalculationsPaymentPlan + "Recorders") Then
			ListOfFullRecordersCalculationsPaymentPlan = Common.CopyRecursive(GlobalVariables[TableCalculationsPaymentPlan + "Recorders"]);
		Else
			ListOfFullRecordersCalculationsPaymentPlan = New Array;
		EndIf;
		ListOfFullRecordersCalculationsPaymentPlan.Add(EmptyRecordersOfCalculations);
		
		If CommonClientServer.HasAttributeOrObjectProperty(GlobalVariables, TableCalculationsPlanOfShipmentsDeliveries + "Recorders") Then
			ListOfFullRecordersCalculationsShippingPlanDeliveries = Common.CopyRecursive(GlobalVariables[TableCalculationsPlanOfShipmentsDeliveries + "Recorders"]);
		Else
			ListOfFullRecordersCalculationsShippingPlanDeliveries = New Array;
		EndIf;
		ListOfFullRecordersCalculationsShippingPlanDeliveries.Add(EmptyRecordersOfCalculations);
		
		Query.SetParameter("ListOfFullRecordersCalculationsPaymentPlan", ListOfFullRecordersCalculationsPaymentPlan);
		Query.SetParameter("ListOfFullRecordersCalculationsShippingPlanDeliveries", ListOfFullRecordersCalculationsShippingPlanDeliveries);
		
		For Each Recorder In ListOfFullRecordersDueDateCalculations Do
			If ListOfFullRecordersCalculationsPaymentPlan.Find(Recorder) <> Undefined
				And ListOfFullRecordersCalculationsShippingPlanDeliveries.Find(Recorder) <> Undefined Then
				ListOfFullRecordersByTables.Add(Recorder);
			EndIf;
		EndDo;
	
	Query.SetParameter("ListOfFullRecordersByTables", ListOfFullRecordersByTables);
	
	ArrayOfRequestTexts = New Array;
	
	QueryText = "
	|SELECT DISTINCT
	|	NumberOfRecordsOfARAPRecorders.Document AS Recorder
	|INTO TTAvailableRecorders
	|FROM
	|	InformationRegister.NumberOfRecordsOfARAPRecorders AS NumberOfRecordsOfARAPRecorders
	|WHERE
	|	NumberOfRecordsOfARAPRecorders.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|	AND NumberOfRecordsOfARAPRecorders.ARAPObject = &ARAPObject
	|	AND NumberOfRecordsOfARAPRecorders.Currency = &Currency
	|	AND NOT NumberOfRecordsOfARAPRecorders.Document IN (&ListOfFullRecordersByTables)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&TableCalculationsByTime AS TableName,
	|	AvailableRecorders.Recorder AS Ref,
	|	SUM(ISNULL(NumberOfRecordsOfARAPRecorders.RecordsCount, 0)) > 0 AS CleaningRequired
	|FROM
	|	TTAvailableRecorders AS AvailableRecorders
	|		LEFT JOIN InformationRegister.NumberOfRecordsOfARAPRecorders AS NumberOfRecordsOfARAPRecorders
	|		ON AvailableRecorders.Recorder = NumberOfRecordsOfARAPRecorders.Document
	|		AND NumberOfRecordsOfARAPRecorders.TableName = &TableCalculationsByTime
	|WHERE
	|	NOT AvailableRecorders.Recorder IN (&ListOfFullRecordersDueDateCalculations)
	|GROUP BY
	|	AvailableRecorders.Recorder";
		
	ArrayOfRequestTexts.Add(QueryText);
			
		QueryText = "
		|SELECT
		|	&TableCalculationsPaymentPlan AS TableName,
		|	AvailableRecorders.Recorder AS Ref,
		|	SUM(ISNULL(NumberOfRecordsOfARAPRecorders.RecordsCount, 0)) > 0 AS CleaningRequired
		|FROM
		|	TTAvailableRecorders AS AvailableRecorders
		|		LEFT JOIN InformationRegister.NumberOfRecordsOfARAPRecorders AS NumberOfRecordsOfARAPRecorders
		|		ON AvailableRecorders.Recorder = NumberOfRecordsOfARAPRecorders.Document
		|		AND NumberOfRecordsOfARAPRecorders.TableName = &TableCalculationsPaymentPlan
		|WHERE
		|	NOT AvailableRecorders.Recorder IN (&ListOfFullRecordersCalculationsPaymentPlan)
		|GROUP BY
		|	AvailableRecorders.Recorder
		|
		|UNION ALL
		|
		|SELECT
		|	&TableCalculationsPlanOfShipmentsDeliveries AS TableName,
		|	AvailableRecorders.Recorder AS Ref,
		|	SUM(ISNULL(NumberOfRecordsOfARAPRecorders.RecordsCount, 0)) > 0 AS CleaningRequired
		|FROM
		|	TTAvailableRecorders AS AvailableRecorders
		|		LEFT JOIN InformationRegister.NumberOfRecordsOfARAPRecorders AS NumberOfRecordsOfARAPRecorders
		|		ON AvailableRecorders.Recorder = NumberOfRecordsOfARAPRecorders.Document
		|		AND NumberOfRecordsOfARAPRecorders.TableName = &TableCalculationsPlanOfShipmentsDeliveries
		|WHERE
		|	NOT AvailableRecorders.Recorder IN (&ListOfFullRecordersCalculationsShippingPlanDeliveries)
		|GROUP BY
		|	AvailableRecorders.Recorder";
			
		ArrayOfRequestTexts.Add(QueryText);
		
	Query.Text = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());
		
	DocumentsTable = Query.Execute().Unload(); // SeeFreeSettlementRegistrars
	DocumentsTable.Indexes.Add("TableName");
	
	Return DocumentsTable;
	
EndFunction

#EndRegion

#Region FillingClearingRegisters

// Deprecated. Performs initial filling of registers of the new architecture
//
// Parameters:
//	Parameters - Structure - parameters of the waiting handler
//	  Disable the verification of the completion of the delayed update.IB is a Boolean flag that disables checking the End of the delayed IB update.
//	ResultAddress - String - the address of the temporary storage where the result of the wait handler will be placed.
//
Procedure FillRegistersWhenEnablingNewArchitecture(Parameters, ResultAddress) Export

	If Not Parameters.Property("DisableCheckingEndOfDelayedInfobaseUpdate")
	   And Not InfobaseUpdate.DeferredUpdateCompleted() Then
		Text = NStr("ru = 'Переход на онлайн взаиморасчеты уже запущен. Дождитесь завершения отложенного обновления.';
					|vi = 'Transfer to online AR/AP accounting is already started. Wait for the deferred update to complete.';
					|en = 'Transfer to online AR/AP accounting is already started. Wait for the deferred update to complete.'; fa = 'Transfer to online AR/AP accounting is already started. Wait for the deferred update to complete.';
					|it = 'Transfer to online AR/AP accounting is already started. Wait for the deferred update to complete.';
					|pl = 'Transfer to online AR/AP accounting is already started. Wait for the deferred update to complete.';
					|tr = 'Online alacak/borç muhasebesine geçiş zaten başlatıldı. Ertelenen güncellemenin tamamlanmasını bekleyin.'");
		Raise Text;
	EndIf;
	
	Constants.MigrationToOnlineARAPAccountingHasStarted.Set(True);//The tasks of the non-operational pre-examination queue have started to be registered
	ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(CurrentSessionDate(),,False);
	ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(CurrentSessionDate(),,False);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("AccumulationRegister.CustomersARAPAccountingByDocuments");
		LockItem = Block.Add("AccumulationRegister.VendorsARAPAccountingByDocuments");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		FillInRegisterOfTransitionToOnline();
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		EventName = NameOfLogEventWhenOnlineCalculationsAreEnabled() 
					+ " " + NStr("ru = 'Не удалось заполнить регистр перехода.';
								|vi = 'Cannot fill in the transfer register.';
								|en = 'Cannot fill in the transfer register.'; fa = 'Cannot fill in the transfer register.';
								|it = 'Cannot fill in the transfer register.';
								|pl = 'Cannot fill in the transfer register.';
								|tr = 'Geçiş kayıt tablosu doldurulamadı.'", Common.DefaultLanguageCode());
		WriteLogEvent(EventName,
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	DescriptionOfTransitionMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccounting.TransitionToNewArchitecture.Multithreaded");
	If Common.FileInfobase() Then
		DescriptionOfTransitionMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccounting.TransitionToNewArchitecture.FileInforbaseFind");
	EndIf;
	
	ARAPAccountingInternal.ClearSettlementRegisters();
	ARAPAccountingInternal.IncludeCalculationRegisterTotals();
	
	TransferRegisterAdjustmentsATServer();
	
	//Phase 1 - Basic transfer (data copying)
	If Common.FileInfobase() Then
		ProcessedItemsTotal = TransferOfflineSettlements();
	Else
		MPParameters = ParametersOfMultithreadedProcessingOfCalculations();
		MPParameters.Procedure.Name = "OnlineARAPAccountingServer.TransferOfflineSettlements";
		MPParameters.Procedure.JobPresentation = NStr("vi = 'Chuyển hạch toán công nợ ngoại tuyến';
														|ru = 'Перенос офлайн взаиморасчетов';
														|en = 'Transfer of offline settlements'; fa = 'Transfer of offline settlements';
														|it = 'Trasferimento di pagamenti reciproci offline';
														|pl = 'Przenoszenie rozliczeń wzajemnych offline';
														|tr = 'Çevrimdışı mutabakatların transferi'");
		MPParameters.Data.QueryCondition = "Jobs.RecountDate = DATETIME(1,1,1)";
		
		ProcessedItemsTotal = MultithreadedProcessingOfTasksForDistributionOfCalculations(MPParameters);
	EndIf;
	
	Template = NStr("ru = 'Завершен перенос офлайн расчетов. Обработано: %1 кортежей';
					|vi = 'Transfer of offline AR/AP accounting is completed. Processed: %1 tuples';
					|en = 'Transfer of offline AR/AP accounting is completed. Processed: %1 tuples'; fa = 'Transfer of offline AR/AP accounting is completed. Processed: %1 tuples';
					|it = 'Transfer of offline AR/AP accounting is completed. Processed: %1 tuples';
					|pl = 'Transfer of offline AR/AP accounting is completed. Processed: %1 tuples';
					|tr = 'Çevrimdışı hesaplamaların aktarımı tamamlandı. İşlenen: %1  demet'");
	WriteLogEvent(NameOfLogEventWhenOnlineCalculationsAreEnabled(),
		EventLogLevel.Information,,,StrTemplate(Template, ProcessedItemsTotal));
	
	//Phase 2 - Tail transfer (rechecked during the main transfer)
	//The transfer of tails will be performed in the non-operational queue of the pre-examination
	
	Constants.MigrationToOnlineARAPAccountingHasStarted.Set(False);
	Constants.NewOnlineARAPAccounting.Set(True);
	Try
		Catalogs.BusinessTransactionsSettings.ReplaceSourcesOfSettlementsWithPartners();
	Except
		EventName = NameOfLogEventWhenOnlineCalculationsAreEnabled() 
					+ " " + NStr("ru = 'Этап 2.';
								|vi = 'Step 2.';
								|en = 'Step 2.'; fa = 'مرحله 2.';
								|it = 'Step 2.';
								|pl = 'Step 2.';
								|tr = '2. etap.'", Common.DefaultLanguageCode());
		Text =  NStr("ru = 'Замена источников в настройках хозяйственных операций';
					|vi = 'Replace sources in business operation settings';
					|en = 'Replace sources in business operation settings'; fa = 'Replace sources in business operation settings';
					|it = 'Replace sources in business operation settings';
					|pl = 'Replace sources in business operation settings';
					|tr = 'Ticari işlem ayarlarındaki kaynakların değiştirilmesi'", Common.DefaultLanguageCode()) + Chars.LF + Chars.LF;
		WriteLogEvent(EventName,
			EventLogLevel.Error,,, Text + DetailErrorDescription(ErrorInfo()));
	EndTry;
	Try
		
		CorrectReversedBalance(BegOfMonth(CurrentSessionDate()));
		
	Except
		
		EventName = NameOfLogEventWhenOnlineCalculationsAreEnabled() 
					+ " " + NStr("ru = 'Этап 2.';
								|vi = 'Step 2.';
								|en = 'Step 2.'; fa = 'مرحله 2.';
								|it = 'Step 2.';
								|pl = 'Step 2.';
								|tr = '2. etap.'", Common.DefaultLanguageCode());
		Text =  NStr("ru = 'Исправление развернутого сальдо';
					|vi = 'Detailed balance correction';
					|en = 'Detailed balance correction'; fa = 'Detailed balance correction';
					|it = 'Detailed balance correction';
					|pl = 'Detailed balance correction';
					|tr = 'Ayrıntılı bakiyenin düzeltilmesi'", Common.DefaultLanguageCode()) + Chars.LF + Chars.LF;
		WriteLogEvent(EventName,
			EventLogLevel.Error,,, Text + DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(DescriptionOfTransitionMeasurement, ProcessedItemsTotal);
	
EndProcedure

// Deprecated. New clears the registers of the payments in the transaction lock all of the calculations.
Procedure ClearRegistersWhenShuttingDownNewArchitecture(Parameters = Undefined, UUID = Undefined) Export
	
	BeginTransaction();
	Try
		
		ReturnCustomersARAPAccountingRegisteredRecords();
		Catalogs.BusinessTransactionsSettings.ReplaceSourcesOfSettlementsWithPartners();
		Constants.NewOnlineARAPAccounting.Set(False);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Tắt hạch toán trực tuyến với các đối tác.';
							|ru = 'Выключение онлайн взаиморасчетов с партнерами.';
							|en = 'Disable online mutual settlements with partners.'; fa = 'Disable online mutual settlements with partners.';
							|it = 'Disattivazione online dei conti reciproci con i partner.';
							|pl = 'Wyłączenie online rozliczeń wzajemnych z partnerami.';
							|tr = 'İş ortaklarıyla çevrimiçi mutabakatların kapatılması.'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
		
	ARAPAccountingInternal.ClearSettlementRegisters();
	
	ARAPAccountingInternal.RemoveSystemRegisterAdjustments(Date(1,1,1));
		
	ARAPAccountingInternal.IncludeCalculationRegisterTotals();
	
EndProcedure

// Deprecated. Filling in the new registers all objects in the calculations.
// 
// Parameters:
//  OnlyPlannedCalculations - Boolean - Only Planned Calculations
Procedure FillInAllCalculations(OnlyPlannedCalculations = False) Export
	
	ARAPAccountingInternal.FillInAllCalculations(OnlyPlannedCalculations);

EndProcedure

#EndRegion

#Region SwitchingToNewArchitectureWhenUpdating

#Region InfobaseUpdate

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure WhenAddingHandlerForSwitchingToNewSettlementArchitecture(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "OnlineARAPAccountingServer.ProcessDataForTransitionToNewSettlementArchitecture";
	Handler.Version = "11.5.27.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("c196aaa5-6e50-42d4-9f83-13f14b8dccbb");
	Handler.Multithreaded = False;
	Handler.UpdateDataFillingProcedure = "OnlineARAPAccountingServer.RegisterDataForProcessingToSwitchToNewSettlementArchitecture";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = NStr("ru = 'Переход на новую архитектуру взаиморасчетов';
							|vi = 'Migrate to a new AR/AP configuration';
							|en = 'Migrate to a new AR/AP configuration'; fa = 'Migrate to a new AR/AP configuration';
							|it = 'Migrate to a new AR/AP configuration';
							|pl = 'Migrate to a new AR/AP configuration';
							|tr = 'Yeni alacak/borç muhasebesi mimarisine geçiş'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Constants.NewOnlineARAPAccounting.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ObjectsToLock = "";
	
EndProcedure

// The procedure for registering data for the update handler is to process the data for the transition Version.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataForProcessingToSwitchToNewSettlementArchitecture(Parameters) Export
	
	Return; //Registration is not required
	
EndProcedure

Procedure ProcessDataForTransitionToNewSettlementArchitecture(Parameters) Export

	NewOnlineARAPAccounting = Constants.NewOnlineARAPAccounting.Get();
	If NewOnlineARAPAccounting Then
		Parameters.ProcessingCompleted = True;
	Else
		
		ExportProcedureParameters = New Structure;
		ExportProcedureParameters.Insert("DisableCheckingEndOfDelayedInfobaseUpdate", True);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters();
		ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Переход на новую архитектуру взаиморасчетов';
															|vi = 'Migrate to a new AR/AP configuration';
															|en = 'Migrate to a new AR/AP configuration'; fa = 'Migrate to a new AR/AP configuration';
															|it = 'Migrate to a new AR/AP configuration';
															|pl = 'Migrate to a new AR/AP configuration';
															|tr = 'Yeni alacak/borç muhasebesi mimarisine geçiş'");
		
		Result = TimeConsumingOperations.ExecuteInBackground(
			"OnlineARAPAccountingServer.FillRegistersWhenEnablingNewArchitecture",
			ExportProcedureParameters,
			ExecutionParameters);
		
		//in the file database and when Debugging mode is enabled, a long-term Operation is performed without a background task
		If ValueIsFilled(Result.JobID) Then
			Job = BackgroundJobs.FindByUUID(Result.JobID);
			Try
				ResultOfWaiting = Job.WaitForExecutionCompletion();
				If ResultOfWaiting.State = BackgroundJobState.Failed 
					Or ResultOfWaiting.State = BackgroundJobState.Canceled Then
					MessageText = NStr("ru = 'Не удалось выполнить переход на онлайн взаиморасчеты.
					|Причину завершения задания перехода смотри выше этой записи в журнале регистрации.';
					|vi = 'Cannot switch to online AR/AP accounting.
					|See the reason for completing the migration job above this record in the event log.';
					|en = 'Cannot switch to online AR/AP accounting.
					|See the reason for completing the migration job above this record in the event log.'; fa = 'Cannot switch to online AR/AP accounting.
					|See the reason for completing the migration job above this record in the event log.';
					|it = 'Cannot switch to online AR/AP accounting.
					|See the reason for completing the migration job above this record in the event log.';
					|pl = 'Cannot switch to online AR/AP accounting.
					|See the reason for completing the migration job above this record in the event log.';
					|tr = 'Çevrimiçi alacak/borç muhasebesine geçiş yapılamadı.
					| Geçiş görevinin tamamlanma sebebi için kayıt günlüğünde bu kaydın üzerine bakın.'");
					WriteLogEvent(NameOfLogEventWhenOnlineCalculationsAreEnabled(),
						EventLogLevel.Information,,,MessageText);
				EndIf;
			Except
				WriteLogEvent(NameOfLogEventWhenOnlineCalculationsAreEnabled(),
					EventLogLevel.Information,,,NStr("ru = 'Истекло время ожидания фонового задания перехода на онлайн взаиморасчеты';
													|vi = 'The background job for switch to online AR/AP accounting timed out';
													|en = 'The background job for switch to online AR/AP accounting timed out'; fa = 'The background job for switch to online AR/AP accounting timed out';
													|it = 'The background job for switch to online AR/AP accounting timed out';
													|pl = 'The background job for switch to online AR/AP accounting timed out';
													|tr = 'Çevrimiçi alacak/borç muhasebesine geçiş arka plan görevinin bekleme süresi doldu'"));
			EndTry;
		EndIf;
		NewOnlineARAPAccounting = Constants.NewOnlineARAPAccounting.Get();
		If Not NewOnlineARAPAccounting 
			And Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
			Constants.MigrationToOnlineARAPAccountingHasStarted.Set(False);
		EndIf;
		
		Parameters.ProcessingCompleted = NewOnlineARAPAccounting;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region ErrorCorrection

// Deprecated. Generates the query text to search for incorrect data in calculation registers. 
// 
// Parameters:
// 	TTName - String - Name of the temporary table to place the result in
// 	NoManualAdjustments - Boolean - the need to exclude from the result of the request the Calculation Analysts for partners 
// 	                                  and Settlement Objects for which manual register adjustments have been introduced.
// Returns:
// 	String - Query text
Function TextOfRequestForIncorrectBalancesOfSettlementsByTerms(TTName = "", NoManualAdjustments = True) Export
	
	Return ARAPAccountingInternal.TextOfRequestForIncorrectBalancesOfSettlementsByTerms(TTName, NoManualAdjustments);
	
EndFunction

// Deprecated. Generates a text query to search for records with a detailed balance calculation in the registers. 
// 
// Parameters:
// 	TTName - String - Name of the temporary table to place the result in
// 	NoManualAdjustments - Boolean - the need to exclude Partner Settlement Analysts from the query result 
// Returns:
// 	String - Query text
Function QueryTextDetailedBalance(TTName = "", NoManualAdjustments = True) Export
	
	Return ARAPAccountingInternal.QueryTextDetailedBalance(TTName, NoManualAdjustments) 
	
EndFunction

// Deprecated. Correction of settlement balances
// 
// Parameters:
// 	Period - Date - The verification period, at the beginning of the month of the period, the balances will be checked, 
//		if they are incorrect, an adjustment will be created for the end of the previous month.
//		If the balances are in order at the beginning of the period, but not at the beginning of the next month, then a partial recalculation of the calculations will be launched.
// 	CompanyArray - Array of CatalogRef.Companies - Array of organizations that need to correct settlement balances
Procedure FixSettlementBalances(Period, Val CompanyArray = Undefined) Export
	
	ARAPAccountingInternal.FixSettlementBalances(Period, CompanyArray)
	
EndProcedure

// Deprecated. Correction of the expanded balance on mutual settlements
// 
// Parameters:
// 	Period - Date - Verification period, you must specify the end of the month
// 	CompanyArray - Array of CatalogRef.Companies - The array organization for which you want to fix a detailed balance of payments
Procedure CorrectReversedBalance(Period, Val CompanyArray = Undefined) Export
	
	ARAPAccountingInternal.CorrectReversedBalance(Period, CompanyArray)
	
EndProcedure

// Deprecated. Adds data on other income / expenses to movements 
// 
// Parameters:
// 	AdjustingObject - DocumentObject.RegisterAdjustment - A document object with already recorded movements based on calculations.
Procedure SupplementAdjustmentWithRegisteredRecordsInOtherIncomeExpenses(AdjustingObject) Export
	
	ARAPAccountingInternal.SupplementAdjustmentWithRegisteredRecordsInOtherIncomeExpenses(AdjustingObject);
	
EndProcedure

#EndRegion

// Deprecated. Registers calculation objects for deferred calculation by time and plan
// 
// Parameters:
// 	Recorder - DocumentRef - The registrar, the initiator of registration of tasks (the conducted document).
// 	ChangesTable - See TableToDistribution
Procedure RegisterChangesToDeferredAllocation(Recorder, ChangesTable) Export
	
	ARAPAccountingInternal.RegisterChangesToDeferredAllocation(Recorder, ChangesTable);
	
EndProcedure

// Deprecated. Performs the distribution of calculations for current tasks to be distributed in the registers of the assignment of the distribution of settlements and the assignment of the distribution of mutual settlements
// 
// Parameters:
// 	Parameters - Structure, Undefined - The structure passes a table of tasks for distribution:
// 	 *DataForDevelopment - See ARAPAccountingInternal.DataForProcessing
// 	ResultAddress - String - address of the temporary storage where the result of the procedure will be placed.
Procedure PerformDeferredAllocation(Parameters = Undefined, ResultAddress = Undefined) Export
	
	ARAPAccountingInternal.PerformDeferredAllocation(Parameters, ResultAddress);
	
EndProcedure

// empty links to orders.
// 
// Returns:
//  Array of Type - Empty Links To Orders
Function EmptyLinksToOrders() Export
	
	EmptyLinksToOrders = New Array;
	EmptyLinksToOrders.Add(Undefined);
	EmptyLinksToOrders.Add(Documents.SalesOrder.EmptyRef());
	EmptyLinksToOrders.Add(Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef());
	EmptyLinksToOrders.Add(Documents.PurchaseOrder.EmptyRef());
	
	EmptyLinksToOrders.Add(Documents.SubcontractOrder2_5.EmptyRef());
	EmptyLinksToOrders.Add(Documents.MaterialProviderOrder2_5.EmptyRef());
	Return EmptyLinksToOrders;
EndFunction

#EndRegion

#Region Private

#Region GetData

// Generates temporary tables for all analysts to calculate
Procedure GenerateTTOfRegisterData(Query, GlobalVariables)
	
	Texts = New Array;
	
	// The augmented parameters are then used in all connections to obtain data.
	Texts.Add("SELECT DISTINCT
	|	AugmentedDistributionParameters.ARAPObject AS ParameterARAPObject,
	|	AugmentedDistributionParameters.AccountingDimensionByPartners AS PartnerAccountingAnalyticsParameter,
	|	AugmentedDistributionParameters.Currency AS CurrencyParameter,
	|	AugmentedDistributionParameters.TheseAreSettlementsWithCustomers AS ParameterIsCustomerSettlements,
	|	AugmentedDistributionParameters.ScheduleInContract AS ScheduleParameterInContract,
	|	AugmentedDistributionParameters.ContractSchedule AS ContractScheduleParameter,
	|	AugmentedDistributionParameters.LocalAccountingCurrency AS ParameterCurrencyOfRegulatedAccounting,
	|	AugmentedDistributionParameters.RecalculationStartDate AS ParameterDateWhenRecalculationStarted,
	|	AugmentedDistributionParameters.PaymentType_ AS CalculationsTypeParameter
	|INTO TTAugmentedDistributionParameters
	|FROM
	|	&AugmentedDistributionParameters AS AugmentedDistributionParameters
	|
	|INDEX BY
	|	PartnerAccountingAnalyticsParameter,
	|	ParameterARAPObject,
	|	CurrencyParameter");
	
	If GlobalVariables.ThereAreRecordsOfSettlementsWithCustomers Then
		Texts.Add(QueryTextCalculationsByTermsBalance(GlobalVariables.StartDateOfRecalculationIsDifferent, True));
		Texts.Add(QueryTextRegisteredRecordedCalculationsFromMomentOfRecalculation(True));
		Texts.Add(QueryTextSourceRecorders(True));
		Texts.Add(QueryTextPaymentPlanCalculationsBalance(GlobalVariables.StartDateOfRecalculationIsDifferent,True));
		Texts.Add(QueryTextCalculationsShipmentPlanDeliveriesBalance(GlobalVariables.StartDateOfRecalculationIsDifferent, True));
	EndIf;

	If GlobalVariables.ThereAreRecordsOfSettlementsWithSuppliers Then
		Texts.Add(QueryTextCalculationsByTermsBalance(GlobalVariables.StartDateOfRecalculationIsDifferent,False));
		Texts.Add(QueryTextRegisteredRecordedCalculationsFromMomentOfRecalculation(False));
		Texts.Add(QueryTextSourceRecorders(False));
		Texts.Add(QueryTextPaymentPlanCalculationsBalance(GlobalVariables.StartDateOfRecalculationIsDifferent,False));
		Texts.Add(QueryTextCalculationsShipmentPlanDeliveriesBalance(GlobalVariables.StartDateOfRecalculationIsDifferent, False));
	EndIf;
	
	#Region ServiceRecordersOfSettlements
	ArrayOfTexts = New Array;
	// Service Recorders of calculations to speed up requests.
	ArrayOfTexts.Add("
	|SELECT DISTINCT
	|	Calculations.Period AS Period,
	|	Calculations.Recorder AS Recorder
	|INTO TTSettlementsWithClientsOnTimeRecorders
	|FROM AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON Calculations.DestinationAccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|");

	ArrayOfTexts.Add("
	|SELECT DISTINCT
	|	Calculations.Period AS Period,
	|	Calculations.Recorder AS Recorder
	|INTO TTSettlementsWithSuppliersOnTimeRecorders
	|FROM AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON Calculations.DestinationAccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|");
	
	QueryTextTTReceiverTypes = "";
	
	// Determines whether the Registered Recorded receiver is a shipment or a payment.
	If GlobalVariables.ThereAreRecordsOfSettlementsWithCustomers Then
		QueryTextTTReceiverTypes = "
			|SELECT DISTINCT
			|	RegisteredRecords.Recorder AS Recorder,
			|	RegisteredRecords.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	RegisteredRecords.ARAPObject AS ARAPObject,
			|	RegisteredRecords.Currency AS Currency,
			|	RegisteredRecords.ThisIsPayment  AS ReceiverIsPayment
			|INTO TTReceiverTypes
			|FROM
			|	RegisteredRecordsClients AS RegisteredRecords
			|WHERE
			|	RegisteredRecords.ByDataOfSourceARAPObject
			|	AND RegisteredRecords.Sum <> 0
			|";
	EndIf;
	
	If GlobalVariables.ThereAreRecordsOfSettlementsWithSuppliers Then
		QueryText = "SELECT DISTINCT
			|	RegisteredRecords.Recorder AS Recorder,
			|	RegisteredRecords.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	RegisteredRecords.ARAPObject AS ARAPObject,
			|	RegisteredRecords.Currency AS Currency,
			|	RegisteredRecords.ThisIsPayment AS ReceiverIsPayment
			|INTO TTReceiverTypes
			|FROM
			|	RegisteredRecordsSuppliers AS RegisteredRecords
			|WHERE
			|	RegisteredRecords.ByDataOfSourceARAPObject
			|	AND RegisteredRecords.Sum <> 0
			|";
		If GlobalVariables.ThereAreRecordsOfSettlementsWithCustomers Then
			QueryTextTTReceiverTypes = QueryTextTTReceiverTypes + TMCommonUse.QuerySeparatorInJoin();
			QueryText = StrReplace(QueryText, "INTO TTReceiverTypes", "");
		EndIf;
		QueryTextTTReceiverTypes = QueryTextTTReceiverTypes + QueryText;
	EndIf;
	ArrayOfTexts.Add(QueryTextTTReceiverTypes);
	
	Texts.Add(StrConcat(ArrayOfTexts,";"));
	#EndRegion
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function QueryTextCalculationsByTermsBalance(StartDateOfRecalculationIsDifferent, CustomersARAPAccounting = True, TableName = "")

	//Calculation data before the start of recalculation.
	
	ArrayOfSubqueryTexts = New Array;
	
	SubqueryTextBalance = "
	|SELECT
	|	CalculationsByTermsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CalculationsByTermsBalance.ARAPObject AS ARAPObject,
	|	CalculationsByTermsBalance.Currency AS Currency,
	|	CalculationsByTermsBalance.ARAPDocument AS ARAPDocument,
	|	CalculationsByTermsBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CalculationsByTermsBalance.OccurrenceDate AS OccurrenceDate,
	|	CalculationsByTermsBalance.PrepaymentBalance AS PrepaymentBalance,
	|	CalculationsByTermsBalance.PrepaymentLocalBalance AS PrepaymentLocalBalance,
	|	CalculationsByTermsBalance.PrepaymentManBalance AS PrepaymentManBalance,
	|	CalculationsByTermsBalance.DebtBalance AS DebtBalance,
	|	CalculationsByTermsBalance.DebtLocalBalance AS DebtLocalBalance,
	|	CalculationsByTermsBalance.ARAPManBalance AS ARAPManBalance,
	|	0 AS PrepaymentTurnover,
	|	0 AS PrepaymentLocalTurnover,
	|	0 AS PrepaymentManTurnover,
	|	0 AS DebtTurnover,
	|	0 AS DebtLocalTurnover,
	|	0 AS ARAPManTurnover
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&StartDateOfRecalculationMinimum, (AccountingDimensionByPartners,
	|		ARAPObject, Currency) IN
	|		(SELECT
	|			TTParameters.PartnerAccountingAnalyticsParameter,
	|			TTParameters.ParameterARAPObject,
	|			TTParameters.CurrencyParameter
	|		FROM
	|			TTAugmentedDistributionParameters AS TTParameters)) AS CalculationsByTermsBalance";
	
	ArrayOfSubqueryTexts.Add(SubqueryTextBalance);
	
	If StartDateOfRecalculationIsDifferent Then
		
		TextOfRegisteredRecordsSubquery = "
		|SELECT
		|	CalculationsByTerms.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CalculationsByTerms.ARAPObject AS ARAPObject,
		|	CalculationsByTerms.Currency AS Currency,
		|	CalculationsByTerms.ARAPDocument AS ARAPDocument,
		|	CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	CalculationsByTerms.OccurrenceDate AS OccurrenceDate,
		|	SUM(0) AS PrepaymentBalance,
		|	SUM(0) AS PrepaymentLocalBalance,
		|	SUM(0) AS PrepaymentManBalance,
		|	SUM(0) AS DebtBalance,
		|	SUM(0) AS DebtLocalBalance,
		|	SUM(0) AS ARAPManBalance,
		|	SUM(CASE
		|		WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.Prepayment
		|		ELSE -CalculationsByTerms.Prepayment
		|	END) AS PrepaymentTurnover,
		|	SUM(CASE
		|		WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.PrepaymentLocal
		|		ELSE -CalculationsByTerms.PrepaymentLocal
		|	END) AS PrepaymentLocalTurnover,
		|	SUM(CASE
		|		WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.PrepaymentMan
		|		ELSE -CalculationsByTerms.PrepaymentMan
		|	END) AS PrepaymentManTurnover,
		|	SUM(CASE
		|		WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.Debt
		|		ELSE -CalculationsByTerms.Debt
		|	END) AS DebtTurnover,
		|	SUM(CASE
		|		WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.DebtLocal
		|		ELSE -CalculationsByTerms.DebtLocal
		|	END) AS DebtLocalTurnover,
		|	SUM(CASE
		|		WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.ARAPMan
		|		ELSE -CalculationsByTerms.ARAPMan
		|	END) AS ARAPManTurnover
		|FROM
		|	TTAugmentedDistributionParameters AS TTParameters
		|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
		|		ON TTParameters.ParameterARAPObject = CalculationsByTerms.ARAPObject
		|		AND TTParameters.PartnerAccountingAnalyticsParameter = CalculationsByTerms.AccountingDimensionByPartners
		|		AND TTParameters.CurrencyParameter = CalculationsByTerms.Currency
		|		AND CalculationsByTerms.Active
		|		AND CalculationsByTerms.Period >= &StartDateOfRecalculationMinimum
		|		AND CalculationsByTerms.Period < TTParameters.ParameterDateWhenRecalculationStarted
		|GROUP BY
		|	CalculationsByTerms.AccountingDimensionByPartners,
		|	CalculationsByTerms.ARAPObject,
		|	CalculationsByTerms.Currency,
		|	CalculationsByTerms.ARAPDocument,
		|	CalculationsByTerms.PlannedRepaymentDate,
		|	CalculationsByTerms.OccurrenceDate";
		
		ArrayOfSubqueryTexts.Add(TextOfRegisteredRecordsSubquery);
		
	EndIf;
	
	SubqueryText = StrConcat(ArrayOfSubqueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTextCalculationsByTermsBalance = "
	|SELECT
	|	BalanceAndTurnovers.ARAPObject AS ARAPObject,
	|	BalanceAndTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	BalanceAndTurnovers.ARAPDocument AS ARAPDocument,
	|	BalanceAndTurnovers.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate AS OccurrenceDate,
	|	SUM(BalanceAndTurnovers.PrepaymentBalance + BalanceAndTurnovers.PrepaymentTurnover) AS PrepaymentBalance,
	|	SUM(BalanceAndTurnovers.PrepaymentLocalBalance + BalanceAndTurnovers.PrepaymentLocalTurnover) AS PrepaymentLocalBalance,
	|	SUM(BalanceAndTurnovers.PrepaymentManBalance + BalanceAndTurnovers.PrepaymentManTurnover) AS PrepaymentManBalance,
	|	SUM(BalanceAndTurnovers.DebtBalance + BalanceAndTurnovers.DebtTurnover) AS DebtBalance,
	|	SUM(BalanceAndTurnovers.DebtLocalBalance + BalanceAndTurnovers.DebtLocalTurnover) AS DebtLocalBalance,
	|	SUM(BalanceAndTurnovers.ARAPManBalance + BalanceAndTurnovers.ARAPManTurnover) AS ARAPManBalance
	|INTO VT_BalancesClients
	|FROM
	|	&SubqueryText AS BalanceAndTurnovers
	|GROUP BY
	|	BalanceAndTurnovers.ARAPObject,
	|	BalanceAndTurnovers.AccountingDimensionByPartners,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.ARAPDocument,
	|	BalanceAndTurnovers.PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency,
	|	ARAPDocument
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationsByTermsBalance.ARAPObject AS ARAPObject,
	|	CalculationsByTermsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CalculationsByTermsBalance.Currency AS Currency,
	|	CalculationsByTermsBalance.ARAPDocument AS ARAPDocument,
	|	CalculationsByTermsBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CalculationsByTermsBalance.OccurrenceDate AS OccurrenceDate,
	|	CalculationsByTermsBalance.PrepaymentBalance AS PrepaymentBalance,
	|	CalculationsByTermsBalance.PrepaymentLocalBalance AS PrepaymentLocalBalance,
	|	CalculationsByTermsBalance.PrepaymentManBalance AS PrepaymentManBalance,
	|	CalculationsByTermsBalance.DebtBalance AS DebtBalance,
	|	CalculationsByTermsBalance.DebtLocalBalance AS DebtLocalBalance,
	|	CalculationsByTermsBalance.ARAPManBalance AS ARAPManBalance,
	|	MAX(SupportingInformation.OperationProcedure) AS OperationProcedure
	|INTO TTBalancesWithLastMomentOfIncomingRegisteredRecordedCustomers
	|FROM
	|	VT_BalancesClients AS CalculationsByTermsBalance
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS SupportingInformation
	|			ON CalculationsByTermsBalance.AccountingDimensionByPartners     = SupportingInformation.AccountingDimensionByPartners
	|				AND CalculationsByTermsBalance.ARAPObject             = SupportingInformation.ARAPObject
	|				AND CalculationsByTermsBalance.Currency                     = SupportingInformation.Currency
	|				AND CalculationsByTermsBalance.ARAPDocument          = SupportingInformation.ARAPDocument
	|				AND CalculationsByTermsBalance.PlannedRepaymentDate     = SupportingInformation.PlannedRepaymentDate
	|				AND CalculationsByTermsBalance.OccurrenceDate          = SupportingInformation.OccurrenceDate
	|				AND SupportingInformation.Active
	|				AND SupportingInformation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND NOT SupportingInformation.DocumentRecorder REFS Document.ExchangeDifferenceCalculation
	|				AND NOT SupportingInformation.ReversingEntry
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON TTParameters.ParameterARAPObject = CalculationsByTermsBalance.ARAPObject
	|				AND TTParameters.PartnerAccountingAnalyticsParameter = CalculationsByTermsBalance.AccountingDimensionByPartners
	|				AND TTParameters.CurrencyParameter = CalculationsByTermsBalance.Currency
	|				AND SupportingInformation.Period < TTParameters.ParameterDateWhenRecalculationStarted
	|GROUP BY
	|	CalculationsByTermsBalance.ARAPObject,
	|	CalculationsByTermsBalance.AccountingDimensionByPartners,
	|	CalculationsByTermsBalance.Currency,
	|	CalculationsByTermsBalance.ARAPDocument,
	|	CalculationsByTermsBalance.OccurrenceDate,
	|	CalculationsByTermsBalance.PlannedRepaymentDate,
	|	CalculationsByTermsBalance.PrepaymentBalance,
	|	CalculationsByTermsBalance.PrepaymentLocalBalance,
	|	CalculationsByTermsBalance.PrepaymentManBalance,
	|	CalculationsByTermsBalance.DebtBalance,
	|	CalculationsByTermsBalance.DebtLocalBalance,
	|	CalculationsByTermsBalance.ARAPManBalance
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency,
	|	ARAPDocument,
	|	PlannedRepaymentDate,
	|	OccurrenceDate,
	|	OperationProcedure
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationsByTermsBalance.ARAPObject AS ARAPObject,
	|	CalculationsByTermsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CalculationsByTermsBalance.Currency AS Currency,
	|	CalculationsByTermsBalance.ARAPDocument AS ARAPDocument,
	|	CalculationsByTermsBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	CalculationsByTermsBalance.OccurrenceDate AS OccurrenceDate,
	|	MIN(SupportingInformation.SettlementProcedure) AS SettlementProcedure,
	|	CalculationsByTermsBalance.OperationProcedure AS OperationProcedure,
	|	MAX(SupportingInformation.LinkedDocument) AS LinkedDocument,
	|	MAX(SupportingInformation.DocumentCurrency) AS DocumentCurrency,
	|	MAX(SupportingInformation.CashFlowItem) AS CashFlowItem,
	|	MAX(SupportingInformation.BusinessOperation) AS BusinessOperation,
	|	MAX(SupportingInformation.DocumentRecorder) AS DocumentRecorder,
	|	CalculationsByTermsBalance.PrepaymentBalance AS Prepayment,
	|	CalculationsByTermsBalance.PrepaymentLocalBalance AS PrepaymentLocal,
	|	CalculationsByTermsBalance.PrepaymentManBalance AS PrepaymentMan,
	|	CalculationsByTermsBalance.DebtBalance AS Debt,
	|	CalculationsByTermsBalance.DebtLocalBalance AS DebtLocal,
	|	CalculationsByTermsBalance.ARAPManBalance AS ARAPMan,
	|	CalculationsByTermsBalance.PrepaymentBalance <> 0 AS ThereIsPrepayment,
	|	CalculationsByTermsBalance.DebtBalance <> 0 AS ThereIsDuty
	|INTO TTDueSettlementsBalancesCustomers
	|FROM
	|	TTBalancesWithLastMomentOfIncomingRegisteredRecordedCustomers AS CalculationsByTermsBalance
	|		INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS SupportingInformation
	|			ON CalculationsByTermsBalance.AccountingDimensionByPartners     = SupportingInformation.AccountingDimensionByPartners
	|				AND CalculationsByTermsBalance.ARAPObject             = SupportingInformation.ARAPObject
	|				AND CalculationsByTermsBalance.Currency                     = SupportingInformation.Currency
	|				AND CalculationsByTermsBalance.ARAPDocument          = SupportingInformation.ARAPDocument
	|				AND CalculationsByTermsBalance.PlannedRepaymentDate     = SupportingInformation.PlannedRepaymentDate
	|				AND CalculationsByTermsBalance.OccurrenceDate          = SupportingInformation.OccurrenceDate
	|				AND CalculationsByTermsBalance.OperationProcedure            = SupportingInformation.OperationProcedure
	|				AND SupportingInformation.Active
	|				AND SupportingInformation.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND NOT SupportingInformation.DocumentRecorder REFS Document.ExchangeDifferenceCalculation
	|				AND NOT SupportingInformation.ReversingEntry
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON TTParameters.ParameterARAPObject = CalculationsByTermsBalance.ARAPObject
	|				AND TTParameters.PartnerAccountingAnalyticsParameter = CalculationsByTermsBalance.AccountingDimensionByPartners
	|				AND TTParameters.CurrencyParameter = CalculationsByTermsBalance.Currency
	|				AND SupportingInformation.Period < TTParameters.ParameterDateWhenRecalculationStarted
	|GROUP BY
	|	CalculationsByTermsBalance.ARAPObject,
	|	CalculationsByTermsBalance.AccountingDimensionByPartners,
	|	CalculationsByTermsBalance.Currency,
	|	CalculationsByTermsBalance.ARAPDocument,
	|	CalculationsByTermsBalance.OccurrenceDate,
	|	CalculationsByTermsBalance.OperationProcedure,
	|	CalculationsByTermsBalance.PlannedRepaymentDate,
	|	CalculationsByTermsBalance.PrepaymentBalance,
	|	CalculationsByTermsBalance.PrepaymentLocalBalance,
	|	CalculationsByTermsBalance.PrepaymentManBalance,
	|	CalculationsByTermsBalance.DebtBalance,
	|	CalculationsByTermsBalance.DebtLocalBalance,
	|	CalculationsByTermsBalance.ARAPManBalance,
	|	CalculationsByTermsBalance.PrepaymentBalance <> 0,
	|	CalculationsByTermsBalance.DebtBalance <> 0
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency,
	|	ThereIsPrepayment,
	|	ThereIsDuty";
	
	QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance, 
			"&SubqueryText", 
			"(" + SubqueryText + ")");
		
	If Not StartDateOfRecalculationIsDifferent Then
		
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"SUM(BalanceAndTurnovers.PrepaymentBalance + BalanceAndTurnovers.PrepaymentTurnover)", 
			"BalanceAndTurnovers.PrepaymentBalance + BalanceAndTurnovers.PrepaymentTurnover");
		
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance, 
			"SUM(BalanceAndTurnovers.PrepaymentLocalBalance + BalanceAndTurnovers.PrepaymentLocalTurnover)",
			"BalanceAndTurnovers.PrepaymentLocalBalance + BalanceAndTurnovers.PrepaymentLocalTurnover");
		
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance, 
			"SUM(BalanceAndTurnovers.PrepaymentManBalance + BalanceAndTurnovers.PrepaymentManTurnover)",
			"BalanceAndTurnovers.PrepaymentManBalance + BalanceAndTurnovers.PrepaymentManTurnover");
		
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"SUM(BalanceAndTurnovers.DebtBalance + BalanceAndTurnovers.DebtTurnover)",
			"BalanceAndTurnovers.DebtBalance + BalanceAndTurnovers.DebtTurnover");
		
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"SUM(BalanceAndTurnovers.DebtLocalBalance + BalanceAndTurnovers.DebtLocalTurnover)",
			"BalanceAndTurnovers.DebtLocalBalance + BalanceAndTurnovers.DebtLocalTurnover");
		
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"SUM(BalanceAndTurnovers.ARAPManBalance + BalanceAndTurnovers.ARAPManTurnover)",
			"BalanceAndTurnovers.ARAPManBalance + BalanceAndTurnovers.ARAPManTurnover");
		
		GroupingSubquery ="
		|GROUP BY
		|	BalanceAndTurnovers.ARAPObject,
		|	BalanceAndTurnovers.AccountingDimensionByPartners,
		|	BalanceAndTurnovers.Currency,
		|	BalanceAndTurnovers.ARAPDocument,
		|	BalanceAndTurnovers.PlannedRepaymentDate,
		|	BalanceAndTurnovers.OccurrenceDate";
		
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance, GroupingSubquery, "");
		
	EndIf;
	
	If Not CustomersARAPAccounting Then
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"AccumulationRegister.CustomersARAPAccountingByDueDates",
			"AccumulationRegister.VendorsARAPAccountingByDueDates");
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"VT_BalancesClients",
			"VT_BalanceSuppliers");
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"TTBalancesWithLastMomentOfIncomingRegisteredRecordedCustomers",
			"TTBalancesWithLastMomentOfIncomingRegisteredRecordedSuppliers");
		QueryTextCalculationsByTermsBalance = StrReplace(QueryTextCalculationsByTermsBalance,
			"TTDueSettlementsBalancesCustomers",
			"TTDueDateCalculationsBalancesVendors");
	EndIf;
	
	Return QueryTextCalculationsByTermsBalance;
	
EndFunction

Function QueryTextRegisteredRecordedCalculationsFromMomentOfRecalculation(CustomersARAPAccounting = True)

	If CustomersARAPAccounting Then
		#Region SettlementsWithClientsFromMomentOfRecalculation
		QueryText = "
		|SELECT 
		|	Calculations.Period AS Period,
		|	Calculations.RecordType AS RecordType,
		|	Calculations.Recorder AS Recorder,
		|
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject AS ARAPObject,
		|	Calculations.Currency AS Currency,
		|	
		// Next, the flags This is the load and this is the payment and the amount modulo are used.
		|	CASE WHEN Calculations.Sum < 0 THEN -Calculations.Sum ELSE Calculations.Sum END AS Sum,
		|	CASE WHEN Calculations.AmountDue < 0 THEN -Calculations.AmountDue ELSE Calculations.AmountDue END AS AmountDue,
		|	CASE WHEN Calculations.ToShip < 0 THEN -Calculations.ToShip ELSE Calculations.ToShip END AS ToShip,
		|
		|	Calculations.SettlementTransaction AS SettlementTransaction,
		|	Calculations.BusinessOperation AS BusinessOperation,
		|	Calculations.SaleByOrder AS SaleByOrder,
		|	Calculations.RecorderDate AS RecorderDate,
		|	Calculations.PaymentDate AS PaymentDate,
		|	CASE WHEN Calculations.SumCompl < 0 THEN -Calculations.SumCompl ELSE Calculations.SumCompl END AS SumCompl,
		|	CASE WHEN Calculations.SumMan < 0 THEN -Calculations.SumMan ELSE Calculations.SumMan END AS SumMan,
		|	Calculations.CashFlowItem AS CashFlowItem,
		|	Calculations.ARAPDocument AS ARAPDocument,
		|	Calculations.OperationProcedure AS OperationProcedure,
		|	Calculations.SettlementProcedureByPaymentDate AS SettlementProcedureByPaymentDate,
		|	Calculations.LinkedDocument AS LinkedDocument,
		|	Calculations.PaymentOption AS PaymentOption,
		|	Calculations.DocumentCurrency AS DocumentCurrency,
		|	Calculations.CorARAPObject AS CorARAPObject,
		|	Calculations.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
		|	Calculations.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	Calculations.FinRecordID AS FinRecordID,
		|	Calculations.CalculationObjectReceiver AS CalculationObjectReceiver,
		|	Calculations.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
		|	Calculations.CurrencyReceiver AS CurrencyReceiver,
		|	CASE WHEN Calculations.AmountReceiver < 0 THEN -Calculations.AmountReceiver ELSE Calculations.AmountReceiver END AS AmountReceiver,
		|	Calculations.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
		|	Calculations.ReversingEntry AS ReversingEntry,
		|
		|	(Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND Calculations.Sum < 0
		|		OR Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND Calculations.Sum> 0) AS ThisIsPayment,
		|
		|	Calculations.DocumentCurrency = Parameters.ParameterCurrencyOfRegulatedAccounting
		|		OR Parameters.CurrencyParameter = Parameters.ParameterCurrencyOfRegulatedAccounting AS ManualLocalCourse,
		|
		|	Calculations.DocumentCurrency = &CurrencyOfMan 
		|		OR Parameters.CurrencyParameter = &CurrencyOfMan AS ManualManCourse,
		|
		|	Calculations.RateARAPCurrencyNumerator AS RateARAPCurrencyNumerator,
		|	Calculations.RateARAPCurrencyDenominator AS RateARAPCurrencyDenominator,
		|	Calculations.ExchangeRateNumeratorOfManSCurrency AS ExchangeRateNumeratorOfManSCurrency,
		|	Calculations.ExchangeRateDenominatorCurrencyMan AS ExchangeRateDenominatorCurrencyMan
		|
		|INTO RegisteredRecordsClients
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|		INNER JOIN TTAugmentedDistributionParameters AS Parameters
		|			ON Calculations.ARAPObject = Parameters.ParameterARAPObject
		|				AND Calculations.AccountingDimensionByPartners = Parameters.PartnerAccountingAnalyticsParameter
		|				AND Calculations.Currency = Parameters.CurrencyParameter
		|				AND Calculations.Period >= Parameters.ParameterDateWhenRecalculationStarted
		|WHERE
		|	Calculations.Active
		|	AND NOT Calculations.Recorder REFS Document.RegisterAdjustment
		|	AND Parameters.ParameterIsCustomerSettlements
		|	AND (Calculations.Sum <> 0 OR Calculations.AmountDue <> 0  OR Calculations.ToShip <> 0)
		|	
		|INDEX BY
		|	ARAPObject,
		|	AccountingDimensionByPartners,
		|	Currency,
		|	RecordType";
		#EndRegion
	Else
		#Region SettlementsWithSuppliersFromMomentOfRecalculation
		
		QueryText = "
		|SELECT 
		|	Calculations.Period AS Period,
		|	Calculations.RecordType AS RecordType,
		|	Calculations.Recorder AS Recorder,
		|
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject AS ARAPObject,
		|	Calculations.Currency AS Currency,
		|	
		|	CASE WHEN Calculations.Sum < 0 THEN -Calculations.Sum ELSE Calculations.Sum END AS Sum,
		|	CASE WHEN Calculations.AmountDue < 0 THEN -Calculations.AmountDue ELSE Calculations.AmountDue END AS AmountDue,
		|	CASE WHEN Calculations.ToReceive < 0 THEN -Calculations.ToReceive ELSE Calculations.ToReceive END AS ToShip,
		|	
		|	Calculations.SettlementTransaction AS SettlementTransaction,
		|	Calculations.BusinessOperation AS BusinessOperation,
		|	Calculations.PurchaseByOrder AS PurchaseByOrder,
		|	Calculations.RecorderDate AS RecorderDate,
		|	Calculations.PaymentDate AS PaymentDate,
		|	CASE WHEN Calculations.SumCompl < 0 THEN -Calculations.SumCompl ELSE Calculations.SumCompl END AS SumCompl,
		|	CASE WHEN Calculations.SumMan < 0 THEN -Calculations.SumMan ELSE Calculations.SumMan END AS SumMan,
		|	Calculations.CashFlowItem AS CashFlowItem,
		|	Calculations.ARAPDocument AS ARAPDocument,
		|	Calculations.OperationProcedure AS OperationProcedure,
		|	Calculations.SettlementProcedureByPaymentDate AS SettlementProcedureByPaymentDate,
		|	Calculations.LinkedDocument AS LinkedDocument,
		|	Calculations.PaymentOption AS PaymentOption,
		|	Calculations.DocumentCurrency AS DocumentCurrency,
		|	Calculations.CorARAPObject AS CorARAPObject,
		|	Calculations.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
		|	Calculations.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	Calculations.FinRecordID AS FinRecordID,
		|	Calculations.CalculationObjectReceiver AS CalculationObjectReceiver,
		|	Calculations.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
		|	Calculations.CurrencyReceiver AS CurrencyReceiver,
		|	CASE WHEN Calculations.AmountReceiver < 0 THEN -Calculations.AmountReceiver ELSE Calculations.AmountReceiver END AS AmountReceiver,
		|	Calculations.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
		|	Calculations.ReversingEntry AS ReversingEntry,
		|
		|	(Calculations.RecordType = VALUE(AccumulationRecordType.Expense) AND Calculations.Sum + Calculations.AmountDue < 0
		|		OR Calculations.RecordType = VALUE(AccumulationRecordType.Receipt) AND Calculations.Sum + Calculations.AmountDue > 0) AS ThisIsPayment,
		|	Calculations.DocumentCurrency = Parameters.ParameterCurrencyOfRegulatedAccounting
		|			OR Parameters.CurrencyParameter = Parameters.ParameterCurrencyOfRegulatedAccounting AS ManualLocalCourse,
		|	Calculations.DocumentCurrency = &CurrencyOfMan 
		|			OR Parameters.CurrencyParameter = &CurrencyOfMan AS ManualManCourse,
		|
		|	Calculations.RateARAPCurrencyNumerator AS RateARAPCurrencyNumerator,
		|	Calculations.RateARAPCurrencyDenominator AS RateARAPCurrencyDenominator,
		|	Calculations.ExchangeRateNumeratorOfManSCurrency AS ExchangeRateNumeratorOfManSCurrency,
		|	Calculations.ExchangeRateDenominatorCurrencyMan AS ExchangeRateDenominatorCurrencyMan
		|
		|INTO RegisteredRecordsSuppliers
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|		INNER JOIN TTAugmentedDistributionParameters AS Parameters
		|			ON Calculations.ARAPObject = Parameters.ParameterARAPObject
		|				AND Calculations.AccountingDimensionByPartners = Parameters.PartnerAccountingAnalyticsParameter
		|				AND Calculations.Currency = Parameters.CurrencyParameter
		|				AND Calculations.Period >= Parameters.ParameterDateWhenRecalculationStarted
		|WHERE
		|	Calculations.Active
		|	AND NOT Calculations.Recorder REFS Document.RegisterAdjustment
		|	AND NOT Parameters.ParameterIsCustomerSettlements
		|	AND (Calculations.Sum <> 0 OR Calculations.AmountDue <> 0  OR Calculations.ToReceive <> 0)
		|	
		|INDEX BY
		|	ARAPObject,
		|	AccountingDimensionByPartners,
		|	Currency,
		|	RecordType";
		#EndRegion
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextPaymentPlanCalculationsBalance(StartDateOfRecalculationIsDifferent, CustomersARAPAccounting)
	
	ArrayOfSubqueryTexts = New Array;
	
	SubqueryTextBalance = "
	|SELECT
	|	PaymentPlanCalculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentPlanCalculations.ARAPObject AS ARAPObject,
	|	PaymentPlanCalculations.Currency AS Currency,
	|	PaymentPlanCalculations.DocumentPlan AS DocumentPlan,
	|	PaymentPlanCalculations.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	PaymentPlanCalculations.OccurrenceDate AS OccurrenceDate,
	|	PaymentPlanCalculations.PaymentOption AS PaymentOption,
	|	PaymentPlanCalculations.UnallocatedAdvancePayment AS UnallocatedAdvancePayment,
	|	PaymentPlanCalculations.AmountDueBalance AS AmountDueBalance,
	|	0 AS AmountDueForTurnover
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(&StartDateOfRecalculationMinimum, (AccountingDimensionByPartners,
	|		ARAPObject, Currency) IN
	|		(SELECT
	|			TTParameters.PartnerAccountingAnalyticsParameter,
	|			TTParameters.ParameterARAPObject,
	|			TTParameters.CurrencyParameter
	|		FROM
	|			TTAugmentedDistributionParameters AS TTParameters)) AS PaymentPlanCalculations";
	
	ArrayOfSubqueryTexts.Add(SubqueryTextBalance);
	
	If StartDateOfRecalculationIsDifferent Then
		
		TextOfRegisteredRecordsSubquery = "
		|SELECT
		|	PaymentPlanCalculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	PaymentPlanCalculations.ARAPObject AS ARAPObject,
		|	PaymentPlanCalculations.Currency AS Currency,
		|	PaymentPlanCalculations.DocumentPlan AS DocumentPlan,
		|	PaymentPlanCalculations.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	PaymentPlanCalculations.OccurrenceDate AS OccurrenceDate,
		|	PaymentPlanCalculations.PaymentOption AS PaymentOption,
		|	PaymentPlanCalculations.UnallocatedAdvancePayment AS UnallocatedAdvancePayment,
		|	SUM(0) AS AmountDueBalance,
		|	SUM(CASE
		|		WHEN PaymentPlanCalculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PaymentPlanCalculations.AmountDue
		|		ELSE -PaymentPlanCalculations.AmountDue
		|	END) AS AmountDueForTurnover
		|FROM
		|	TTAugmentedDistributionParameters AS TTParameters
		|		INNER JOIN AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlanCalculations
		|		ON TTParameters.ParameterARAPObject = PaymentPlanCalculations.ARAPObject
		|		AND TTParameters.PartnerAccountingAnalyticsParameter = PaymentPlanCalculations.AccountingDimensionByPartners
		|		AND TTParameters.CurrencyParameter = PaymentPlanCalculations.Currency
		|		AND PaymentPlanCalculations.Active
		|		AND PaymentPlanCalculations.Period >= &StartDateOfRecalculationMinimum
		|		AND PaymentPlanCalculations.Period < TTParameters.ParameterDateWhenRecalculationStarted
		|GROUP BY
		|	PaymentPlanCalculations.AccountingDimensionByPartners,
		|	PaymentPlanCalculations.ARAPObject,
		|	PaymentPlanCalculations.Currency,
		|	PaymentPlanCalculations.DocumentPlan,
		|	PaymentPlanCalculations.PlannedRepaymentDate,
		|	PaymentPlanCalculations.OccurrenceDate,
		|	PaymentPlanCalculations.PaymentOption,
		|	PaymentPlanCalculations.UnallocatedAdvancePayment";
		
		ArrayOfSubqueryTexts.Add(TextOfRegisteredRecordsSubquery);
		
	EndIf;
	
	SubqueryText = StrConcat(ArrayOfSubqueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTextPaymentPlanCalculationsBalance = "
	|SELECT
	|	BalanceAndTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceAndTurnovers.ARAPObject AS ARAPObject,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	BalanceAndTurnovers.DocumentPlan AS DocumentPlan,
	|	BalanceAndTurnovers.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate AS OccurrenceDate,
	|	BalanceAndTurnovers.PaymentOption AS PaymentOption,
	|	SUM(CASE WHEN NOT BalanceAndTurnovers.UnallocatedAdvancePayment 
	|				THEN BalanceAndTurnovers.AmountDueBalance + BalanceAndTurnovers.AmountDueForTurnover
	|			ELSE 0
	|		END) AS AmountDue,
	|	SUM(CASE WHEN BalanceAndTurnovers.UnallocatedAdvancePayment 
	|				THEN BalanceAndTurnovers.AmountDueBalance + BalanceAndTurnovers.AmountDueForTurnover
	|			ELSE 0
	|		END) AS AmountDueIsUndistributedAdvance,
	|	SUM(CASE WHEN BalanceAndTurnovers.UnallocatedAdvancePayment 
	|				THEN BalanceAndTurnovers.AmountDueBalance + BalanceAndTurnovers.AmountDueForTurnover
	|			ELSE 0
	|		END) < 0 AS ThereIsUndistributedAdvanceAmountDue
	|INTO TTCalculationsPaymentPlanBalancesCustomers
	|FROM
	|	&SubqueryText AS BalanceAndTurnovers
	|GROUP BY
	|	BalanceAndTurnovers.AccountingDimensionByPartners,
	|	BalanceAndTurnovers.ARAPObject,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.DocumentPlan,
	|	BalanceAndTurnovers.PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate,
	|	BalanceAndTurnovers.PaymentOption
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency,
	|	DocumentPlan,
	|	PlannedRepaymentDate
	|";
		
	QueryTextPaymentPlanCalculationsBalance = StrReplace(QueryTextPaymentPlanCalculationsBalance,
		"&SubqueryText",
		"(" + SubqueryText + ")");
	
	If Not CustomersARAPAccounting Then
		QueryTextPaymentPlanCalculationsBalance = StrReplace(QueryTextPaymentPlanCalculationsBalance,
			"AccumulationRegister.CustomersARAPAccountingCashFlowPlan",
			"AccumulationRegister.VendorsARAPAccountingCashFlowPlan");
		
		QueryTextPaymentPlanCalculationsBalance = StrReplace(QueryTextPaymentPlanCalculationsBalance,
			"TTCalculationsPaymentPlanBalancesCustomers",
			"TTCalculationsPaymentPlanBalancesVendors");
	EndIf; 
	
	Return QueryTextPaymentPlanCalculationsBalance;
	
EndFunction

Function QueryTextCalculationsShipmentPlanDeliveriesBalance(StartDateOfRecalculationIsDifferent, CustomersARAPAccounting)
	
	ArrayOfSubqueryTexts = New Array;
	
	SubqueryTextBalance = "
	|SELECT
	|	PaymentPlanCalculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PaymentPlanCalculations.ARAPObject AS ARAPObject,
	|	PaymentPlanCalculations.Currency AS Currency,
	|	PaymentPlanCalculations.DocumentPlan AS DocumentPlan,
	|	PaymentPlanCalculations.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	PaymentPlanCalculations.OccurrenceDate AS OccurrenceDate,
	|	PaymentPlanCalculations.UnallocatedAdvancePayment AS UnallocatedAdvancePayment,
	|	PaymentPlanCalculations.SumBalance AS SumBalance,
	|	0 AS AmountAboutTurnover
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingPlannedShipments.Balance(&StartDateOfRecalculationMinimum, (AccountingDimensionByPartners,
	|		ARAPObject, Currency) IN
	|		(SELECT
	|			TTParameters.PartnerAccountingAnalyticsParameter,
	|			TTParameters.ParameterARAPObject,
	|			TTParameters.CurrencyParameter
	|		FROM
	|			TTAugmentedDistributionParameters AS TTParameters)) AS PaymentPlanCalculations";
	
	ArrayOfSubqueryTexts.Add(SubqueryTextBalance);
	
	If StartDateOfRecalculationIsDifferent Then
		
		TextOfRegisteredRecordsSubquery = "
		|SELECT
		|	PaymentPlanCalculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	PaymentPlanCalculations.ARAPObject AS ARAPObject,
		|	PaymentPlanCalculations.Currency AS Currency,
		|	PaymentPlanCalculations.DocumentPlan AS DocumentPlan,
		|	PaymentPlanCalculations.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	PaymentPlanCalculations.OccurrenceDate AS OccurrenceDate,
		|	PaymentPlanCalculations.UnallocatedAdvancePayment AS UnallocatedAdvancePayment,
		|	SUM(0) AS SumBalance,
		|	SUM(CASE
		|		WHEN PaymentPlanCalculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN PaymentPlanCalculations.Sum
		|		ELSE -PaymentPlanCalculations.Sum
		|	END) AS AmountAboutTurnover
		|FROM
		|	TTAugmentedDistributionParameters AS TTParameters
		|		INNER JOIN AccumulationRegister.CustomersARAPAccountingPlannedShipments AS PaymentPlanCalculations
		|		ON TTParameters.ParameterARAPObject = PaymentPlanCalculations.ARAPObject
		|		AND TTParameters.PartnerAccountingAnalyticsParameter = PaymentPlanCalculations.AccountingDimensionByPartners
		|		AND TTParameters.CurrencyParameter = PaymentPlanCalculations.Currency
		|		AND PaymentPlanCalculations.Active
		|		AND PaymentPlanCalculations.Period >= &StartDateOfRecalculationMinimum
		|		AND PaymentPlanCalculations.Period < TTParameters.ParameterDateWhenRecalculationStarted
		|GROUP BY
		|	PaymentPlanCalculations.AccountingDimensionByPartners,
		|	PaymentPlanCalculations.ARAPObject,
		|	PaymentPlanCalculations.Currency,
		|	PaymentPlanCalculations.DocumentPlan,
		|	PaymentPlanCalculations.PlannedRepaymentDate,
		|	PaymentPlanCalculations.OccurrenceDate,
		|	PaymentPlanCalculations.UnallocatedAdvancePayment";
		
		ArrayOfSubqueryTexts.Add(TextOfRegisteredRecordsSubquery);
		
	EndIf;
	
	SubqueryText = StrConcat(ArrayOfSubqueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTextCalculationsShipmentPlanDeliveriesBalance = "
	|SELECT
	|	BalanceAndTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceAndTurnovers.ARAPObject AS ARAPObject,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	BalanceAndTurnovers.DocumentPlan AS DocumentPlan,
	|	BalanceAndTurnovers.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate AS OccurrenceDate,
	|	SUM(CASE WHEN NOT BalanceAndTurnovers.UnallocatedAdvancePayment 
	|				THEN BalanceAndTurnovers.SumBalance + BalanceAndTurnovers.AmountAboutTurnover
	|			ELSE 0
	|		END) AS Sum,
	|	SUM(CASE WHEN BalanceAndTurnovers.UnallocatedAdvancePayment 
	|				THEN BalanceAndTurnovers.SumBalance + BalanceAndTurnovers.AmountAboutTurnover
	|			ELSE 0
	|		END) AS AmountOfUndistributedAdvance,
	|	SUM(CASE WHEN BalanceAndTurnovers.UnallocatedAdvancePayment 
	|				THEN BalanceAndTurnovers.SumBalance + BalanceAndTurnovers.AmountAboutTurnover
	|			ELSE 0
	|		END) < 0 AS ThereIsAmountOfUndistributedAdvance
	|INTO TTCalculationsShipmentPlanDeliveriesBalancesCustomers
	|FROM
	|	&SubqueryText AS BalanceAndTurnovers
	|GROUP BY
	|	BalanceAndTurnovers.AccountingDimensionByPartners,
	|	BalanceAndTurnovers.ARAPObject,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.DocumentPlan,
	|	BalanceAndTurnovers.PlannedRepaymentDate,
	|	BalanceAndTurnovers.OccurrenceDate
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency";
	
	QueryTextCalculationsShipmentPlanDeliveriesBalance = StrReplace(QueryTextCalculationsShipmentPlanDeliveriesBalance, 
			"&SubqueryText", 
			"(" + SubqueryText + ")");
			
	If Not CustomersARAPAccounting Then
		QueryTextCalculationsShipmentPlanDeliveriesBalance = StrReplace(QueryTextCalculationsShipmentPlanDeliveriesBalance,
			"AccumulationRegister.CustomersARAPAccountingPlannedShipments",
			"AccumulationRegister.VendorsARAPAccountingPlannedDeliveries");
		QueryTextCalculationsShipmentPlanDeliveriesBalance = StrReplace(QueryTextCalculationsShipmentPlanDeliveriesBalance,
			"TTCalculationsShipmentPlanDeliveriesBalancesCustomers","TTCalculationsShipmentPlanSuppliesBalancesVendors");
	EndIf; 
	
	Return QueryTextCalculationsShipmentPlanDeliveriesBalance;
	
EndFunction

// For corrections and storno, the Registered Records of the original documents that are not included in the distribution period are copied "As is".
Function QueryTextSourceRecorders(TheseAreSettlementsWithCustomers)
	
	QueryText = "
	|SELECT
	|	RegisterRecords.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	RegisterRecords.ARAPObject            AS ARAPObject,
	|	RegisterRecords.Currency                    AS Currency,
	|
	|	Register3.ReversedDocument        AS CancelledRegistrar,
	|	Register3.CorrectedDocument        AS CorrectedDocument,
	|	MIN(BEGINOFPERIOD(ISNULL(SourceDocument_.IBDocumentDate,DATETIME(1,1,1)), DAY)) AS OriginalDateOfOccurrence,
	|
	|	RegisterRecords.Recorder                         AS NewRegistrar,
	|	MIN(RegisterRecords.Period)                     AS NewPeriod,
	|	BEGINOFPERIOD(MIN(RegisterRecords.Period),DAY) AS NewPeriodStartOfDay,
	|	MIN(RegisterRecords.OperationProcedure)            AS NewOrderOfOperation,
	|	FALSE AS Reversed
	|INTO TTSourceRecordersClients
	|FROM
	|	RegisteredRecordsClients AS RegisterRecords
	|		INNER JOIN InformationRegister.DocumentsRegistry AS Register3
	|			ON Register3.Ref = RegisterRecords.Recorder
	|				AND Register3.ReverseTransactionCorrection
	|				AND Register3.Posted
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS SourceDocument_
	|			ON SourceDocument_.Ref = Register3.CorrectedDocument
	|GROUP BY 
	|	RegisterRecords.AccountingDimensionByPartners,
	|	RegisterRecords.ARAPObject,
	|	RegisterRecords.Currency,
	|	Register3.ReversedDocument,
	|	Register3.CorrectedDocument,
	|	RegisterRecords.Recorder
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText,"RegisteredRecordsClients","RegisteredRecordsSuppliers");
		QueryText = StrReplace(QueryText,"TTSourceRecordersClients","TTSourceRecordersSuppliers");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns a table of Registered Records of source documents that are being reversed in the current distribution
Function RegisteredRecordsOfCancelledDocumentsBeforeStartOfCalculation(Query, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|	SELECT
	|		InitialCalculationsByTime.Period                             AS Period,
	|		InitialCalculationsByTime.RecordType                        AS RecordType,
	|		InitialCalculationsByTime.DocumentRecorder                AS DocumentRecorder,
	|		InitialCalculationsByTime.ARAPObject                     AS ARAPObject,
	|		InitialCalculationsByTime.AccountingDimensionByPartners          AS AccountingDimensionByPartners,
	|		InitialCalculationsByTime.Currency                             AS Currency,
	|		InitialCalculationsByTime.PlannedRepaymentDate             AS PlannedRepaymentDate,
	|		InitialCalculationsByTime.OccurrenceDate                  AS OccurrenceDate,
	|		InitialCalculationsByTime.OperationProcedure                    AS OperationProcedure,
	|		InitialCalculationsByTime.SettlementProcedure                      AS SettlementProcedure,
	|		InitialCalculationsByTime.ARAPDocument                  AS ARAPDocument,
	|		InitialCalculationsByTime.BusinessOperation              AS BusinessOperation,
	|		VALUE(Enum.SettlementOperations.EmptyRef) AS SettlementTransaction,
	|		InitialCalculationsByTime.SettlementRecordType            AS SettlementRecordType,
	|		InitialCalculationsByTime.CorARAPObject                  AS CorARAPObject,
	|		InitialCalculationsByTime.CorPartnerAccountingDimension       AS CorPartnerAccountingDimension,
	|		InitialCalculationsByTime.DestinationAccountingDimensionByPartners  AS DestinationAccountingDimensionByPartners,
	|		InitialCalculationsByTime.CalculationObjectReceiver             AS CalculationObjectReceiver,
	|		InitialCalculationsByTime.CurrencyReceiver                     AS CurrencyReceiver,
	|		InitialCalculationsByTime.AmountReceiver                      AS AmountReceiver,
	|		InitialCalculationsByTime.ByDataOfSourceARAPObject   AS ByDataOfSourceARAPObject,
	|		
	|		FALSE                                                       AS ReversingEntry,
	|		
	|		InitialCalculationsByTime.Debt           AS Debt,
	|		InitialCalculationsByTime.DebtLocal       AS DebtLocal,
	|		InitialCalculationsByTime.ARAPMan        AS ARAPMan,
	|		InitialCalculationsByTime.Prepayment     AS Prepayment,
	|		InitialCalculationsByTime.PrepaymentLocal AS PrepaymentLocal,
	|		InitialCalculationsByTime.PrepaymentMan  AS PrepaymentMan,
	|
	|		0 AS Corrected,
	|
	|		InitialCalculationsByTime.DocumentCurrency                 AS DocumentCurrency,
	|		InitialCalculationsByTime.CashFlowItem   AS CashFlowItem,
	|		InitialCalculationsByTime.FinRecordID          AS FinRecordID,
	|		InitialCalculationsByTime.BusinessTransactionSetting  AS BusinessTransactionSetting,
	|		InitialCalculationsByTime.LinkedDocument               AS LinkedDocument,
	|		FALSE                                                    AS Reversed
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS InitialCalculationsByTime
	|			INNER JOIN TTSourceRecordersClients AS TTSourceRecorders
	|				ON TTSourceRecorders.CancelledRegistrar = InitialCalculationsByTime.DocumentRecorder
	|					AND TTSourceRecorders.AccountingDimensionByPartners = InitialCalculationsByTime.AccountingDimensionByPartners
	|					AND TTSourceRecorders.ARAPObject = InitialCalculationsByTime.ARAPObject
	|					AND TTSourceRecorders.Currency = InitialCalculationsByTime.Currency
	|			INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|				ON InitialCalculationsByTime.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|					AND InitialCalculationsByTime.ARAPObject = TTParameters.ParameterARAPObject
	|					AND InitialCalculationsByTime.Currency = TTParameters.CurrencyParameter
	|	WHERE
	|		NOT InitialCalculationsByTime.ReversingEntry
	|		AND InitialCalculationsByTime.Period < TTParameters.ParameterDateWhenRecalculationStarted";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"TTSourceRecordersClients","TTSourceRecordersSuppliers");
		Query.Text = StrReplace(Query.Text,"AccumulationRegister.CustomersARAPAccountingByDueDates","AccumulationRegister.VendorsARAPAccountingByDueDates");
	EndIf;
	
	RegisterRecords = Query.Execute().Unload();
	Return RegisterRecords;
	
EndFunction

// Returns a table of Registered Records of source documents that are being reversed in the current distribution
Function RegisteredRecordsOfCancelledDocumentsPaymentPlanBeforeStartOfCalculation(Query, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|	SELECT
	|		InitialCalculations.Period                        AS Period,
	|		InitialCalculations.RecordType                   AS RecordType,
	|		InitialCalculations.DocumentRecorder           AS DocumentRecorder,
	|		InitialCalculations.ARAPObject                AS ARAPObject,
	|		InitialCalculations.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
	|		InitialCalculations.Currency                        AS Currency,
	|		InitialCalculations.DocumentPlan                  AS DocumentPlan,
	|		InitialCalculations.PlannedRepaymentDate        AS PlannedRepaymentDate,
	|		InitialCalculations.OccurrenceDate             AS OccurrenceDate,
	|		InitialCalculations.PaymentOption                 AS PaymentOption,
	|		InitialCalculations.UnallocatedAdvancePayment         AS UnallocatedAdvancePayment,
	|		InitialCalculations.DocumentPayments                AS DocumentPayments,
	|		FALSE                                          AS ReversingEntry,
	|		InitialCalculations.AmountDue AS AmountDue
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS InitialCalculations
	|			INNER JOIN TTSourceRecordersClients AS TTSourceRecorders
	|				ON TTSourceRecorders.CancelledRegistrar = InitialCalculations.DocumentRecorder
	|					AND TTSourceRecorders.AccountingDimensionByPartners = InitialCalculations.AccountingDimensionByPartners
	|					AND TTSourceRecorders.ARAPObject = InitialCalculations.ARAPObject
	|					AND TTSourceRecorders.Currency = InitialCalculations.Currency
	|			INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|				ON InitialCalculations.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|					AND InitialCalculations.ARAPObject = TTParameters.ParameterARAPObject
	|					AND InitialCalculations.Currency = TTParameters.CurrencyParameter
	|	WHERE
	|		NOT InitialCalculations.ReversingEntry
	|		AND InitialCalculations.Period < TTParameters.ParameterDateWhenRecalculationStarted
	|		AND NOT InitialCalculations.UnallocatedAdvancePayment";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"TTSourceRecordersClients","TTSourceRecordersSuppliers");
		Query.Text = StrReplace(Query.Text,"AccumulationRegister.CustomersARAPAccountingCashFlowPlan","AccumulationRegister.VendorsARAPAccountingCashFlowPlan");
	EndIf;
	
	RegisterRecords = Query.Execute().Unload();
	Return RegisterRecords;
	
EndFunction

// Returns a table of Registered Records of source documents that are being reversed in the current distribution
Function RegisteredRecordsOfCancelledDocumentsPlanOfShipmentsBeforeStartOfCalculation(Query, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|	SELECT
	|		InitialCalculations.Period                         AS Period,
	|		InitialCalculations.RecordType                    AS RecordType,
	|		InitialCalculations.DocumentRecorder            AS DocumentRecorder,
	|		InitialCalculations.ARAPObject                 AS ARAPObject,
	|		InitialCalculations.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|		InitialCalculations.Currency                         AS Currency,
	|		InitialCalculations.DocumentPlan                   AS DocumentPlan,
	|		InitialCalculations.PlannedRepaymentDate         AS PlannedRepaymentDate,
	|		InitialCalculations.OccurrenceDate              AS OccurrenceDate,
	|		InitialCalculations.UnallocatedAdvancePayment          AS UnallocatedAdvancePayment,
	|		FALSE                                           AS ReversingEntry,
	|		InitialCalculations.Sum                          AS Sum,
	|		InitialCalculations.DocumentPayments                 AS DocumentPayments
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingPlannedShipments AS InitialCalculations
	|			INNER JOIN TTSourceRecordersClients AS TTSourceRecorders
	|				ON TTSourceRecorders.CancelledRegistrar = InitialCalculations.DocumentRecorder
	|					AND TTSourceRecorders.AccountingDimensionByPartners = InitialCalculations.AccountingDimensionByPartners
	|					AND TTSourceRecorders.ARAPObject = InitialCalculations.ARAPObject
	|					AND TTSourceRecorders.Currency = InitialCalculations.Currency
	|			INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|				ON InitialCalculations.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|					AND InitialCalculations.ARAPObject = TTParameters.ParameterARAPObject
	|					AND InitialCalculations.Currency = TTParameters.CurrencyParameter
	|	WHERE
	|		NOT InitialCalculations.ReversingEntry
	|		AND InitialCalculations.Period < TTParameters.ParameterDateWhenRecalculationStarted
	|		AND NOT InitialCalculations.UnallocatedAdvancePayment";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"TTSourceRecordersClients","TTSourceRecordersSuppliers");
		Query.Text = StrReplace(Query.Text,"AccumulationRegister.CustomersARAPAccountingPlannedShipments","AccumulationRegister.VendorsARAPAccountingPlannedDeliveries");
	EndIf;
	
	RegisterRecords = Query.Execute().Unload();
	Return RegisterRecords;
	
EndFunction

// Returns records before the start of the calculation (order), the number of which in the service document Recorder is less than the size of the portion of the record
// These records will be overwritten. They do not participate in the distribution.
Function RecordsBeforeStartOfCalculationByTime(Query, GlobalVariables, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|SELECT
	|	Table.Document AS Recorder
	|INTO TTFullRecorders
	|FROM
	|InformationRegister.NumberOfRecordsOfARAPRecorders AS Table
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON Table.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|				AND Table.ARAPObject = TTParameters.ParameterARAPObject
	|				AND Table.Currency = TTParameters.CurrencyParameter
	|				AND TTParameters.ParameterIsCustomerSettlements = &TheseAreSettlementsWithCustomers
	|WHERE
	|	Table.TableName = ""CustomersARAPAccountingByDueDates""
	|	AND Table.RecordPeriod < TTParameters.ParameterDateWhenRecalculationStarted
	|GROUP BY
	|	Table.Document
	|HAVING
	|	SUM(Table.RecordsCount) = &RecordPortionSize
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Recorders.Recorder AS Recorder
	|FROM
	|	TTFullRecorders AS Recorders
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.Recorder AS Recorder,
	|	Table.DocumentRecorder AS DocumentRecorder,
	|	Table.OperationProcedure AS OperationProcedure,
	|	Table.ReversingEntry AS ReversingEntry,
	|	TRUE AS RecordingBeforeCalculationStarts,
	|	VALUE(Enum.SettlementOperations.EmptyRef) AS SettlementTransaction,
	|
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.Currency AS Currency,
	|	Table.ARAPDocument AS ARAPDocument,
	|	Table.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	Table.OccurrenceDate AS OccurrenceDate,
	|	
	|	Table.Prepayment AS Prepayment,
	|	Table.PrepaymentLocal AS PrepaymentLocal,
	|	Table.PrepaymentMan AS PrepaymentMan,
	|	Table.Debt AS Debt,
	|	Table.DebtLocal AS DebtLocal,
	|	Table.ARAPMan AS ARAPMan,
	|
	|	//They accumulate how many Registered Records storno have already been added
	|	0 AS Corrected,
	|	
	|	Table.SettlementProcedure AS SettlementProcedure,
	|	Table.DocumentCurrency AS DocumentCurrency,
	|	Table.LinkedDocument AS LinkedDocument,
	|	Table.CashFlowItem AS CashFlowItem,
	|	Table.SettlementRecordType AS SettlementRecordType,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.CorPartnerAccountingDimension AS CorPartnerAccountingDimension,
	|	Table.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	Table.FinRecordID AS FinRecordID,
	|	Table.CorARAPObject AS CorARAPObject,
	|	Table.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	Table.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	Table.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|	Table.CurrencyReceiver AS CurrencyReceiver,
	|	Table.AmountReceiver AS AmountReceiver
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Table
	|		LEFT JOIN TTFullRecorders AS TTFullRecorders
	|			ON TTFullRecorders.Recorder = Table.Recorder
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON Table.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|				AND Table.ARAPObject = TTParameters.ParameterARAPObject
	|				AND Table.Currency = TTParameters.CurrencyParameter
	|				AND TTParameters.ParameterIsCustomerSettlements = &TheseAreSettlementsWithCustomers
	|WHERE
	|	TTFullRecorders.Recorder IS NULL // If the number of records is <> portions then they will be redistributed.
	|	AND Table.Period < TTParameters.ParameterDateWhenRecalculationStarted
	|	AND Table.Active
	|;
	|DROP TTFullRecorders";
	
	If TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text, "&TheseAreSettlementsWithCustomers", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "CustomersARAPAccountingByDueDates", "VendorsARAPAccountingByDueDates");
		Query.Text = StrReplace(Query.Text, "&TheseAreSettlementsWithCustomers", "FALSE");
		Query.Text = StrReplace(Query.Text, "TTSourceRecordersClients", "TTSourceRecordersSuppliers")
	EndIf;
	
	Results = Query.ExecuteBatch();
	FullRegistrars = Results[1].Unload().UnloadColumn("Recorder");
	RecordsBeforeStartOfCalculation = Results[2].Unload();
	
	If TheseAreSettlementsWithCustomers Then
		GlobalVariables.Insert("SettlementsWithClientsOnTimeRecorders", FullRegistrars);
	Else
		GlobalVariables.Insert("SettlementsWithSuppliersOnTimeRecorders", FullRegistrars);
	EndIf;
	
	Return RecordsBeforeStartOfCalculation;
	
EndFunction

// Returns records before the start of the calculation (order), the number of which in the service document Registrar is less than the size of the record portion
Function RecordsBeforeStartOfPaymentPlanCalculation(Query, GlobalVariables, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|SELECT
	|	Table.Document AS Recorder
	|INTO TTFullRecorders
	|FROM
	|InformationRegister.NumberOfRecordsOfARAPRecorders AS Table
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON Table.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|				AND Table.ARAPObject = TTParameters.ParameterARAPObject
	|				AND Table.Currency = TTParameters.CurrencyParameter
	|				AND TTParameters.ParameterIsCustomerSettlements = &TheseAreSettlementsWithCustomers
	|WHERE
	|	Table.TableName = ""CustomersARAPAccountingCashFlowPlan""
	|	AND Table.RecordPeriod < TTParameters.ParameterDateWhenRecalculationStarted
	|GROUP BY
	|	Table.Document
	|HAVING
	|	SUM(Table.RecordsCount) = &RecordPortionSize
	|
	|INDEX BY
	|	Recorder
	|;
	|SELECT
	|	Recorders.Recorder AS Recorder
	|FROM
	|	TTFullRecorders AS Recorders
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.Recorder AS Recorder,
	|	Table.DocumentRecorder AS DocumentRecorder,
	|	Table.OperationProcedure AS OperationProcedure,
	|	Table.ReversingEntry AS ReversingEntry,
	|	TRUE AS RecordingBeforeCalculationStarts,
	|	
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.Currency AS Currency,
	|	Table.DocumentPlan AS DocumentPlan,
	|	Table.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	Table.OccurrenceDate AS OccurrenceDate,
	|	Table.PaymentOption AS PaymentOption,
	|	Table.UnallocatedAdvancePayment AS UnallocatedAdvancePayment,
	|	
	|	Table.AmountDue AS AmountDue,
	|	
	|	Table.DocumentPayments AS DocumentPayments
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS Table
	|		LEFT JOIN TTFullRecorders AS TTFullRecorders
	|			ON TTFullRecorders.Recorder = Table.Recorder
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON Table.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|				AND Table.ARAPObject = TTParameters.ParameterARAPObject
	|				AND Table.Currency = TTParameters.CurrencyParameter
	|				AND Table.Period < TTParameters.ParameterDateWhenRecalculationStarted
	|				AND TTParameters.ParameterIsCustomerSettlements = &TheseAreSettlementsWithCustomers
	|WHERE
	|	TTFullRecorders.Recorder IS NULL // If the number of records is <> portions then they will be redistributed.
	|	AND Table.Active
	|	AND Table.Recorder REFS Document.ARAPAccountingRecorder
	|;
	|DROP TTFullRecorders";
	
	If TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text, "&TheseAreSettlementsWithCustomers", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "CustomersARAPAccountingCashFlowPlan", "VendorsARAPAccountingCashFlowPlan");
		Query.Text = StrReplace(Query.Text, "&TheseAreSettlementsWithCustomers", "FALSE");
		Query.Text = StrReplace(Query.Text, "TTSourceRecordersClients", "TTSourceRecordersSuppliers")
	EndIf;
	
	Results = Query.ExecuteBatch();
	FullRegistrars = Results[1].Unload().UnloadColumn("Recorder");
	RecordsBeforeStartOfCalculation = Results[2].Unload();
	
	If TheseAreSettlementsWithCustomers Then
		GlobalVariables.Insert("SettlementsWithClientsPaymentPlanRecorders", FullRegistrars);
	Else
		GlobalVariables.Insert("SettlementsWithSuppliersPaymentPlanRecorders", FullRegistrars);
	EndIf;
	
	Return RecordsBeforeStartOfCalculation;
	
EndFunction

// Returns records before the start of the calculation (order), the number of which in the service document Registrar is less than the size of the record portion
Function RecordsBeforeCalculationOfShipmentPlan(Query, GlobalVariables, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|SELECT
	|	Table.Document AS Recorder
	|INTO TTFullRecorders
	|FROM
	|InformationRegister.NumberOfRecordsOfARAPRecorders AS Table
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON Table.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|				AND Table.ARAPObject = TTParameters.ParameterARAPObject
	|				AND Table.Currency = TTParameters.CurrencyParameter
	|				AND TTParameters.ParameterIsCustomerSettlements = &TheseAreSettlementsWithCustomers
	|WHERE
	|	Table.TableName = ""CustomersARAPAccountingPlannedShipments""
	|	AND Table.RecordPeriod < TTParameters.ParameterDateWhenRecalculationStarted
	|GROUP BY
	|	Table.Document
	|HAVING
	|	SUM(Table.RecordsCount) = &RecordPortionSize
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Recorders.Recorder AS Recorder
	|FROM
	|	TTFullRecorders AS Recorders
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.Recorder AS Recorder,
	|	Table.DocumentRecorder AS DocumentRecorder,
	|	Table.OperationProcedure AS OperationProcedure,
	|	Table.ReversingEntry AS ReversingEntry,
	|	TRUE AS RecordingBeforeCalculationStarts,
	|	
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.Currency AS Currency,
	|	Table.DocumentPlan AS DocumentPlan,
	|	Table.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	Table.OccurrenceDate AS OccurrenceDate,
	|	Table.UnallocatedAdvancePayment AS UnallocatedAdvancePayment,
	|	
	|	Table.Sum AS Sum,
	|	TRUE AS IncludedInBalanceOfPlannedShipments,
	|	
	|	Table.DocumentPayments AS DocumentPayments
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingPlannedShipments AS Table
	|		LEFT JOIN TTFullRecorders AS TTFullRecorders
	|			ON TTFullRecorders.Recorder = Table.Recorder
	|		INNER JOIN TTAugmentedDistributionParameters AS TTParameters
	|			ON Table.AccountingDimensionByPartners = TTParameters.PartnerAccountingAnalyticsParameter
	|				AND Table.ARAPObject = TTParameters.ParameterARAPObject
	|				AND Table.Currency = TTParameters.CurrencyParameter
	|				AND TTParameters.ParameterIsCustomerSettlements = &TheseAreSettlementsWithCustomers
	|WHERE
	|	TTFullRecorders.Recorder IS NULL // If the number of records is <> portions then they will be redistributed.
	|	AND Table.Period < TTParameters.ParameterDateWhenRecalculationStarted
	|	AND Table.Active
	|;
	|DROP TTFullRecorders";
	
	If TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text, "&TheseAreSettlementsWithCustomers", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "CustomersARAPAccountingPlannedShipments", "VendorsARAPAccountingPlannedDeliveries");
		Query.Text = StrReplace(Query.Text, "&TheseAreSettlementsWithCustomers", "FALSE");
		Query.Text = StrReplace(Query.Text, "TTSourceRecordersClients", "TTSourceRecordersSuppliers")
	EndIf;
	
	Results = Query.ExecuteBatch();
	FullRegistrars = Results[1].Unload().UnloadColumn("Recorder");
	RecordsBeforeStartOfCalculation = Results[2].Unload();
	
	If TheseAreSettlementsWithCustomers Then
		GlobalVariables.Insert("SettlementsWithCustomersShipmentPlanRecorders", FullRegistrars);
	Else
		GlobalVariables.Insert("SettlementsWithSuppliersSupplyPlanRecorders", FullRegistrars);
	EndIf;
	
	Return RecordsBeforeStartOfCalculation;
	
EndFunction

Function GetDataForDistribution(Query, TheseAreSettlementsWithCustomers)
	
	Query.Text = "
	|SELECT
	|	NestedQuery.ThisIsPayment                         AS ThisIsPayment,
	|	NestedQuery.Period                            AS Period,
	|	NestedQuery.OperationProcedure                   AS OperationProcedure,
	|	NestedQuery.SettlementProcedureByPaymentDate        AS SettlementProcedureByPaymentDate,
	|	NestedQuery.Recorder                       AS Recorder,
	|	
	|	NestedQuery.ARAPObject                    AS ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
	|	NestedQuery.Currency                            AS Currency,
	|	NestedQuery.ARAPDocument                 AS ARAPDocument,
	|	NestedQuery.PlannedRepaymentDate            AS PlannedRepaymentDate,
	|	NestedQuery.OccurrenceDate                 AS OccurrenceDate,
		
	|	NestedQuery.SettlementTransaction            AS SettlementTransaction,
	|	NestedQuery.BusinessOperation             AS BusinessOperation,
	|	
	|	NestedQuery.CorARAPObject                 AS CorARAPObject,
	|	NestedQuery.CorPartnerAccountingDimension      AS CorPartnerAccountingDimension,
	|	NestedQuery.ByDataOfSourceARAPObject  AS ByDataOfSourceARAPObject,
	|	NestedQuery.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|	NestedQuery.CalculationObjectReceiver            AS CalculationObjectReceiver,
	|	NestedQuery.CurrencyReceiver                    AS CurrencyReceiver,
	|	SUM(NestedQuery.AmountReceiver)                           AS AmountReceiver,
	|	
	|	NestedQuery.ReversingEntry                                         AS ReversingEntry,
	|	NestedQuery.CancelledRegistrar                        AS CancelledRegistrar,
	|	NestedQuery.NewRegisteredRecordedCorrections                       AS NewRegisteredRecordedCorrections,
	|	
	|	SUM(NestedQuery.Sum)                                   AS Sum,
	|	SUM(NestedQuery.Sum)                                   AS AmountToDistribution,
	|	SUM(NestedQuery.Sum) <> 0                              AS ThereIsBalanceToDistribution,
	|	SUM(NestedQuery.Sum)                                   AS InitialAmount_,
	|	SUM(NestedQuery.SumCompl)                               AS SumCompl,
	|	SUM(NestedQuery.SumCompl)                               AS InitialAmountOfLocal,
	|	SUM(NestedQuery.SumMan)                                AS SumMan,
	|	SUM(NestedQuery.SumMan)                                AS InitialAmountOfMan,
	|	
	|	UUID(NestedQuery.Recorder) AS RecordersID,
	|	NestedQuery.DocumentCurrency                                   AS DocumentCurrency,
	|	NestedQuery.CashFlowItem                     AS CashFlowItem,
	|	NestedQuery.FinRecordID                            AS FinRecordID,
	|	NestedQuery.BusinessTransactionSetting                    AS BusinessTransactionSetting,
	|	NestedQuery.DateOfRevaluation                                    AS DateOfRevaluation,
	|	NestedQuery.LinkedDocument                                 AS LinkedDocument,
	|	
	|	CASE
	|		WHEN BEGINOFPERIOD(NestedQuery.Period, DAY) >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|			THEN NestedQuery.Period
	|		ELSE TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|	END                                                                               AS OffsetPeriod,
	|	
	|	NestedQuery.ManualLocalCourse                                                      AS ManualLocalCourse,
	|	NestedQuery.ManualManCourse                                                       AS ManualManCourse,
	|	
	|	MAX(NestedQuery.RateARAPCurrencyNumerator)                         AS RateARAPCurrencyNumerator,
	|	MAX(NestedQuery.RateARAPCurrencyDenominator)                       AS RateARAPCurrencyDenominator,
	|	MAX(NestedQuery.ExchangeRateNumeratorOfManSCurrency)                                    AS ExchangeRateNumeratorOfManSCurrency,
	|	MAX(NestedQuery.ExchangeRateDenominatorCurrencyMan)                                  AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	CASE
	|		WHEN TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|			 	AND (NestedQuery.Recorder REFS Document.BankAccountIssue
	|					OR NestedQuery.Recorder REFS Document.CashVoucher)
	|			OR NOT TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|				AND (NestedQuery.Recorder REFS Document.BankAccountReceiptNote
	|					OR NestedQuery.Recorder REFS Document.CashAccountReceiptNote)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                               AS ThisIsRefundOfAdvance,
	|	CASE
	|		WHEN TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|			 	AND NestedQuery.Recorder REFS Document.CustomerInvoice
	|			THEN CAST(NestedQuery.Recorder AS Document.CustomerInvoice).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|		WHEN TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|				AND NestedQuery.Recorder REFS Document.CustomerInvoiceServicesAndAssets
	|			THEN CAST(NestedQuery.Recorder AS Document.CustomerInvoiceServicesAndAssets).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|		ELSE FALSE
	|	END                                                                               AS ThisIsImplementationInPath
	|FROM (
	|	//Shipments and payments without a source settlement object
	|	SELECT
	|		Calculations.ThisIsPayment                                   AS ThisIsPayment,
	|		Calculations.Recorder                                 AS Recorder,
	|		//Entering the Balances writes the date of the primary document to the registrar's date, and the Register Records must be made by the date of entering the Balances
	|		CASE WHEN VALUETYPE(Calculations.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
	|				THEN Calculations.Period
	|			ELSE Calculations.RecorderDate
	|		END                                               AS Period,
	|		Calculations.OperationProcedure                             AS OperationProcedure,
	|		Calculations.SettlementProcedureByPaymentDate                  AS SettlementProcedureByPaymentDate,
	|		
	|		Calculations.AccountingDimensionByPartners                   AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject                              AS ARAPObject,
	|		Calculations.Currency                                      AS Currency,
	|		CASE 
	|			WHEN Calculations.ARAPDocument <> UNDEFINED AND Calculations.ARAPDocument <> VALUE(Document.SourceDocument.EmptyRef)
	|				THEN Calculations.ARAPDocument
	|			WHEN NOT TTSourceRecorders.CorrectedDocument IS NULL AND NOT Calculations.ReversingEntry
	|				THEN TTSourceRecorders.CorrectedDocument 
	|			ELSE Calculations.Recorder
	|		END                                               AS ARAPDocument,
	|		BEGINOFPERIOD(CASE
	|			WHEN Calculations.PaymentDate = DATETIME(1,1,1) AND NOT Calculations.ThisIsPayment
	|				THEN Calculations.Period
	|			ELSE Calculations.PaymentDate
	|		END , DAY)                                       AS PlannedRepaymentDate,
	|		CASE 
	|			WHEN NOT TTSourceRecorders.CorrectedDocument IS NULL AND NOT Calculations.ReversingEntry
	|					AND NOT VALUETYPE(Calculations.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
	|				THEN TTSourceRecorders.OriginalDateOfOccurrence
	|			ELSE BEGINOFPERIOD(Calculations.RecorderDate, DAY)
	|		END                                               AS OccurrenceDate,
	|		
	|		Calculations.Sum                                       AS Sum,
	|		Calculations.SumCompl                                   AS SumCompl,
	|		Calculations.SumMan                                    AS SumMan,
	|		
	|		Calculations.CorARAPObject                           AS CorARAPObject,
	|		Calculations.CorPartnerAccountingDimension                AS CorPartnerAccountingDimension,
	|		Calculations.ByDataOfSourceARAPObject            AS ByDataOfSourceARAPObject,
	|		Calculations.DestinationAccountingDimensionByPartners           AS DestinationAccountingDimensionByPartners,
	|		Calculations.CalculationObjectReceiver                      AS CalculationObjectReceiver,
	|		Calculations.CurrencyReceiver                              AS CurrencyReceiver,
	|		Calculations.AmountReceiver                               AS AmountReceiver,
	|		
	|		Calculations.ReversingEntry                                                              AS ReversingEntry,
	|		NOT Calculations.ReversingEntry AND NOT TTSourceRecorders.CancelledRegistrar IS NULL AS NewRegisteredRecordedCorrections,
	|		ISNULL(TTSourceRecorders.CancelledRegistrar, UNDEFINED)          AS CancelledRegistrar,
	|		
	|		Calculations.SettlementTransaction                      AS SettlementTransaction,
	|		Calculations.BusinessOperation                       AS BusinessOperation,
	|		Calculations.BusinessTransactionSetting              AS BusinessTransactionSetting,
	|		Calculations.FinRecordID                      AS FinRecordID,
	|		Calculations.DocumentCurrency                             AS DocumentCurrency,
	|		Calculations.CashFlowItem               AS CashFlowItem,
	|		Calculations.LinkedDocument                           AS LinkedDocument,
	|		Calculations.ManualLocalCourse 
	|			OR (Calculations.BusinessOperation IN (&ManualCourseOfOperations) AND NOT Calculations.ThisIsPayment) AS ManualLocalCourse,
	|		Calculations.ManualManCourse 
	|			OR (Calculations.BusinessOperation IN (&ManualCourseOfOperations) AND NOT Calculations.ThisIsPayment) AS ManualManCourse,
	|		CASE WHEN (Calculations.Recorder REFS Document.OBEntry
	|						OR Calculations.Recorder REFS Document.OBEntryARAP)
	|				THEN Calculations.Period
	|			ELSE Calculations.RecorderDate
	|		END                                              AS DateOfRevaluation,
	|		Calculations.RateARAPCurrencyNumerator          AS RateARAPCurrencyNumerator,
	|		Calculations.RateARAPCurrencyDenominator        AS RateARAPCurrencyDenominator,
	|		Calculations.ExchangeRateNumeratorOfManSCurrency                     AS ExchangeRateNumeratorOfManSCurrency,
	|		Calculations.ExchangeRateDenominatorCurrencyMan                   AS ExchangeRateDenominatorCurrencyMan
	|
	|	FROM
	|		RegisteredRecordsClients AS Calculations
	|			LEFT JOIN TTSourceRecordersClients AS TTSourceRecorders
	|				ON TTSourceRecorders.NewRegistrar = Calculations.Recorder
	|					AND TTSourceRecorders.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
	|					AND TTSourceRecorders.ARAPObject = Calculations.ARAPObject
	|					AND TTSourceRecorders.Currency = Calculations.Currency
	|	WHERE
	|		NOT Calculations.ByDataOfSourceARAPObject
	|	
	|	UNION ALL
	|	
	|	//Register Recorded movements from the settlement object of the source ""Settlements with clients on time""
	|	SELECT
	|		TTReceiverTypes.ReceiverIsPayment                       AS ThisIsPayment,
	|		Calculations.DocumentRecorder                              AS Recorder,
	|		Calculations.Period                                           AS Period,
	|		Calculations.OperationProcedure                                  AS OperationProcedure,
	|		Calculations.SettlementProcedure                                    AS SettlementProcedureByPaymentDate,
	|		
	|		Calculations.DestinationAccountingDimensionByPartners                AS AccountingDimensionByPartners,
	|		Calculations.CalculationObjectReceiver                           AS ARAPObject,
	|		Calculations.CurrencyReceiver                                   AS Currency,
	|		Calculations.ARAPDocument                                AS ARAPDocument,
	|		CASE WHEN Calculations.PlannedRepaymentDate = DATETIME(1,1,1) AND NOT TTReceiverTypes.ReceiverIsPayment
	|			THEN Calculations.OccurrenceDate
	|			ELSE Calculations.PlannedRepaymentDate
	|		END                                                    AS PlannedRepaymentDate,
	|		Calculations.OccurrenceDate                                AS OccurrenceDate,
	|		
	|		Calculations.AmountReceiver                                    AS Sum,
	|		Calculations.DebtLocal + Calculations.PrepaymentLocal                AS SumCompl,
	|		Calculations.ARAPMan + Calculations.PrepaymentMan                  AS SumMan,
	|		
	|		Calculations.ARAPObject                                   AS CorARAPObject,
	|		Calculations.AccountingDimensionByPartners                        AS CorPartnerAccountingDimension,
	|		TRUE                                                   AS ByDataOfSourceARAPObject,
	|		VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
	|		VALUE(Catalog.ARAPObjects.EmptyRef)        AS CalculationObjectReceiver,
	|		VALUE(Catalog.Currencies.EmptyRef)                 AS CurrencyReceiver,
	|		0                                                        AS AmountReceiver,
	|		
	|		Calculations.ReversingEntry                                                     AS ReversingEntry,
	|		NOT Calculations.ReversingEntry AND NOT DocumentCorrections.Recorder IS NULL AS NewRegisteredRecordedCorrections,
	|		UNDEFINED                                                       AS CancelledRegistrar,
	|		
	|		VALUE(Enum.SettlementOperations.TransferOfSettlements) AS SettlementTransaction,
	|		Calculations.BusinessOperation                            AS BusinessOperation,
	|		Calculations.BusinessTransactionSetting                   AS BusinessTransactionSetting,
	|		Calculations.FinRecordID                           AS FinRecordID,
	|		Calculations.DocumentCurrency                                  AS DocumentCurrency,
	|		Calculations.CashFlowItem                    AS CashFlowItem,
	|		UNDEFINED                                             AS LinkedDocument,
	|		TRUE                                                   AS ManualLocalCourse,
	|		TRUE                                                   AS ManualManCourse,
	|		CASE WHEN TTReceiverTypes.ReceiverIsPayment 
	|				THEN DATETIME(1,1,1)
	|			ELSE Calculations.Period
	|		END                                                    AS DateOfRevaluation,
	|		CASE WHEN Calculations.AmountReceiver = 0
	|				THEN 0
	|			ELSE CAST((Calculations.DebtLocal + Calculations.PrepaymentLocal) / Calculations.AmountReceiver AS NUMBER (10,4))
	|		END                                                    AS RateARAPCurrencyNumerator,
	|		1                                                        AS RateARAPCurrencyDenominator,
	|		CASE WHEN Calculations.ARAPMan + Calculations.PrepaymentMan = 0
	|				THEN 0
	|			ELSE CAST((Calculations.DebtLocal + Calculations.PrepaymentLocal) / (Calculations.ARAPMan + Calculations.PrepaymentMan) AS NUMBER (10,4))
	|		END                                                    AS ExchangeRateNumeratorOfManSCurrency,
	|		1                                                        AS ExchangeRateDenominatorCurrencyMan
	|	FROM
	|		TTSettlementsWithClientsOnTimeRecorders AS TTSettlementsWithClientsOnTime
	|			INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|				INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|					ON Calculations.CalculationObjectReceiver = TTCalculationParameters.ParameterARAPObject
	|						AND Calculations.DestinationAccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|						AND Calculations.CurrencyReceiver = TTCalculationParameters.CurrencyParameter
	|						AND Calculations.Period >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|			ON TTSettlementsWithClientsOnTime.Period = Calculations.Period
	|				AND TTSettlementsWithClientsOnTime.Recorder = Calculations.Recorder
	|			INNER JOIN TTReceiverTypes AS TTReceiverTypes
	|			ON Calculations.DocumentRecorder = TTReceiverTypes.Recorder
	|				AND Calculations.CalculationObjectReceiver = TTReceiverTypes.ARAPObject
	|				AND Calculations.DestinationAccountingDimensionByPartners = TTReceiverTypes.AccountingDimensionByPartners
	|				AND Calculations.CurrencyReceiver = TTReceiverTypes.Currency
	|			LEFT JOIN InformationRegister.DocumentCorrections AS DocumentCorrections
	|				ON DocumentCorrections.Recorder = Calculations.DocumentRecorder
	|	
	|	UNION ALL
	|	
	|	//Register Recorded movements from the settlement object of the source ""Settlements with suppliers on time""
	|	SELECT
	|		TTReceiverTypes.ReceiverIsPayment                       AS ThisIsPayment,
	|		Calculations.DocumentRecorder                              AS Recorder,
	|		Calculations.Period                                           AS Period,
	|		Calculations.OperationProcedure                                  AS OperationProcedure,
	|		Calculations.SettlementProcedure                                    AS SettlementProcedureByPaymentDate,
	|		
	|		Calculations.DestinationAccountingDimensionByPartners                AS AccountingDimensionByPartners,
	|		Calculations.CalculationObjectReceiver                           AS ARAPObject,
	|		Calculations.CurrencyReceiver                                   AS Currency,
	|		Calculations.ARAPDocument                                AS ARAPDocument,
	|		CASE WHEN Calculations.PlannedRepaymentDate = DATETIME(1,1,1) AND NOT TTReceiverTypes.ReceiverIsPayment 
	|			THEN Calculations.OccurrenceDate
	|			ELSE Calculations.PlannedRepaymentDate
	|		END                                                    AS PlannedRepaymentDate,
	|		Calculations.OccurrenceDate                                AS OccurrenceDate,
	|		
	|		Calculations.AmountReceiver                                    AS Sum,
	|		Calculations.DebtLocal + Calculations.PrepaymentLocal                AS SumCompl,
	|		Calculations.ARAPMan + Calculations.PrepaymentMan                  AS SumMan,
	|		
	|		Calculations.ARAPObject                                   AS CorARAPObject,
	|		Calculations.AccountingDimensionByPartners                        AS CorPartnerAccountingDimension,
	|		TRUE                                                   AS ByDataOfSourceARAPObject,
	|		VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
	|		VALUE(Catalog.ARAPObjects.EmptyRef)        AS CalculationObjectReceiver,
	|		VALUE(Catalog.Currencies.EmptyRef)                 AS CurrencyReceiver,
	|		0                                                        AS AmountReceiver,
	|	
	|		Calculations.ReversingEntry                                                     AS ReversingEntry,
	|		NOT Calculations.ReversingEntry AND NOT DocumentCorrections.Recorder IS NULL AS NewRegisteredRecordedCorrections,
	|		UNDEFINED                                                       AS CancelledRegistrar,
	|	
	|		CASE
	|			WHEN TTReceiverTypes.ReceiverIsPayment 
	|				AND Calculations.BusinessOperation IN (VALUE(Enum.BusinessTransactions.BookingViaAgent),
	|													VALUE(Enum.BusinessTransactions.BookingFromVendor))
	|				 THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
	|			ELSE VALUE(Enum.SettlementOperations.TransferOfSettlements) 
	|		END                                                    AS SettlementTransaction,
	|		Calculations.BusinessOperation                            AS BusinessOperation,
	|		Calculations.BusinessTransactionSetting                   AS BusinessTransactionSetting,
	|		Calculations.FinRecordID                           AS FinRecordID,
	|		Calculations.DocumentCurrency                                  AS DocumentCurrency,
	|		Calculations.CashFlowItem                    AS CashFlowItem,
	|		UNDEFINED                                             AS LinkedDocument,
	|		TRUE                                                   AS ManualLocalCourse,
	|		TRUE                                                   AS ManualManCourse,
	|		CASE WHEN TTReceiverTypes.ReceiverIsPayment
	|			THEN DATETIME(1,1,1)
	|			ELSE Calculations.Period
	|		END                                                    AS DateOfRevaluation,
	|		CASE WHEN Calculations.AmountReceiver = 0
	|				THEN 0
	|			ELSE CAST((Calculations.DebtLocal + Calculations.PrepaymentLocal) / Calculations.AmountReceiver AS NUMBER (10,4))
	|		END                                                    AS RateARAPCurrencyNumerator,
	|		1                                                        AS RateARAPCurrencyDenominator,
	|		CASE WHEN Calculations.ARAPMan + Calculations.PrepaymentMan = 0
	|				THEN 0
	|			ELSE CAST((Calculations.DebtLocal + Calculations.PrepaymentLocal) / (Calculations.ARAPMan + Calculations.PrepaymentMan) AS NUMBER (10,4))
	|		END                                                    AS ExchangeRateNumeratorOfManSCurrency,
	|		1                                                        AS ExchangeRateDenominatorCurrencyMan
	|	FROM
	|		TTSettlementsWithSuppliersOnTimeRecorders AS TTSettlementsWithSuppliersOnTime
	|			INNER JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations 
	|				INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|					ON Calculations.CalculationObjectReceiver = TTCalculationParameters.ParameterARAPObject
	|						AND Calculations.DestinationAccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|						AND Calculations.CurrencyReceiver = TTCalculationParameters.CurrencyParameter
	|						AND Calculations.Period >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|			ON TTSettlementsWithSuppliersOnTime.Period = Calculations.Period
	|				AND TTSettlementsWithSuppliersOnTime.Recorder = Calculations.Recorder
	|		INNER JOIN TTReceiverTypes AS TTReceiverTypes
	|			ON Calculations.DocumentRecorder = TTReceiverTypes.Recorder
	|				AND Calculations.CalculationObjectReceiver = TTReceiverTypes.ARAPObject
	|				AND Calculations.DestinationAccountingDimensionByPartners = TTReceiverTypes.AccountingDimensionByPartners
	|				AND Calculations.CurrencyReceiver = TTReceiverTypes.Currency
	|			LEFT JOIN InformationRegister.DocumentCorrections AS DocumentCorrections
	|				ON DocumentCorrections.Recorder = Calculations.DocumentRecorder
	|	) AS NestedQuery
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON NestedQuery.ARAPObject = TTCalculationParameters.ParameterARAPObject
	|				AND NestedQuery.AccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|				AND NestedQuery.Currency = TTCalculationParameters.CurrencyParameter
	|GROUP BY
	|	NestedQuery.ThisIsPayment,
	|	NestedQuery.Period,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.Currency,
	|	NestedQuery.PlannedRepaymentDate,
	|	NestedQuery.OccurrenceDate,
	|	NestedQuery.OperationProcedure,
	|	NestedQuery.SettlementProcedureByPaymentDate,
	|	NestedQuery.Recorder,
	|	NestedQuery.ARAPDocument,
	|	NestedQuery.SettlementTransaction,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.CorARAPObject,
	|	NestedQuery.CorPartnerAccountingDimension,
	|	NestedQuery.ByDataOfSourceARAPObject,
	|	NestedQuery.DestinationAccountingDimensionByPartners,
	|	NestedQuery.CalculationObjectReceiver,
	|	NestedQuery.CurrencyReceiver,
	|	NestedQuery.ReversingEntry,
	|	NestedQuery.CancelledRegistrar,
	|	NestedQuery.NewRegisteredRecordedCorrections,
	|	NestedQuery.DocumentCurrency,
	|	NestedQuery.CashFlowItem,
	|	NestedQuery.FinRecordID,
	|	NestedQuery.BusinessTransactionSetting,
	|	NestedQuery.DateOfRevaluation,
	|	NestedQuery.LinkedDocument,
	|	NestedQuery.ManualLocalCourse,
	|	NestedQuery.ManualManCourse,
	|	CASE
	|		WHEN BEGINOFPERIOD(NestedQuery.Period, DAY) >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|			THEN NestedQuery.Period
	|		ELSE TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|	END,
	|	CASE
	|		WHEN TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|			 	AND (NestedQuery.Recorder REFS Document.BankAccountIssue
	|					OR NestedQuery.Recorder REFS Document.CashVoucher)
	|			OR NOT TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|				AND (NestedQuery.Recorder REFS Document.BankAccountReceiptNote
	|					OR NestedQuery.Recorder REFS Document.CashAccountReceiptNote)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|			 	AND NestedQuery.Recorder REFS Document.CustomerInvoice
	|			THEN CAST(NestedQuery.Recorder AS Document.CustomerInvoice).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|		WHEN TTCalculationParameters.ParameterIsCustomerSettlements AND NOT NestedQuery.ThisIsPayment
	|				AND NestedQuery.Recorder REFS Document.CustomerInvoiceServicesAndAssets
	|			THEN CAST(NestedQuery.Recorder AS Document.CustomerInvoiceServicesAndAssets).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|		ELSE FALSE
	|	END
	|HAVING
	|	SUM(NestedQuery.Sum) > 0
	|ORDER BY
	|	NestedQuery.OperationProcedure ASC,
	|	NestedQuery.ReversingEntry DESC,
	|	NestedQuery.OccurrenceDate ASC,
	|	//First we distribute it with a completed repayment date, then with an ""Automatic"" one
	|	CASE WHEN NestedQuery.PlannedRepaymentDate = DATETIME(1,1,1)
	|		THEN 2
	|		ELSE 1
	|	END,
	|	NestedQuery.PlannedRepaymentDate,
	|	SUM(NestedQuery.Sum)
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"RegisteredRecordsClients","RegisteredRecordsSuppliers");
		Query.Text = StrReplace(Query.Text,"TTSourceRecordersClients","TTSourceRecordersSuppliers");
	EndIf;
	
	Result     = Query.Execute();
	Data = Result.Unload();
	
	Return Data;
	
EndFunction

// Returns a table of exchange rates for the period between the first settlement record and the current date.
Function GetCurrencyRates(Query, StartDate, GlobalVariables, CurrentVariables)
	
	Query.SetParameter("StartDate",                 StartDate);
	Query.SetParameter("Currency",                     CurrentVariables.Currency);
	Query.SetParameter("CurrencyOfMan",                  GlobalVariables.ManagementAccountingCurrency);
	Query.SetParameter("ComplCurrency",                 CurrentVariables.LocalAccountingCurrency);
	Query.SetParameter("Contract",                    CurrentVariables.Contract);
	Query.SetParameter("CourseSpecifiedInContract", CurrentVariables.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract);
	
	If CurrentVariables.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
		Query.Text = "
		|SELECT
		|	ExRates.Date AS Date,
		|	SUM(ExRates.LocalCourse) AS LocalCourse,
		|	SUM(ExRates.ManSCourse) AS ManSCourse
		|FROM
		|	(SELECT
		|		TableOfDates.Date AS Date,
		|		CASE WHEN &Currency <> &ComplCurrency
		|				THEN ISNULL(SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator,0)
		|			ELSE 1
		|		END AS LocalCourse,
		|		CASE WHEN &Currency = &CurrencyOfMan
		|				THEN ISNULL(SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator,0)
		|			ELSE 0
		|		END AS ManSCourse
		|	FROM
		|		TableOfDates AS TableOfDates
		|			LEFT JOIN InformationRegister.ARAPAccountingExchangeRatesForContracts AS SettlementCurrencyRates_
		|				ON TableOfDates.Date = SettlementCurrencyRates_.Period
		|					AND SettlementCurrencyRates_.Contract = &Contract
		|	
		|	UNION ALL 
		|	
		|	SELECT
		|		TableOfDates.Date AS Date,
		|		0 AS LocalCourse, 
		|		CASE WHEN &Currency = &CurrencyOfMan
		|			THEN 0
		|		ELSE
		|			CASE WHEN &ComplCurrency <> &CurrencyOfMan
		|					THEN ISNULL(ManSExchangeRates.CourseNumerator / ManSExchangeRates.CourseDenominator,0)
		|				ELSE 1
		|			END 
		|		END AS ManSCourse
		|	FROM
		|		TableOfDates AS TableOfDates
		|			LEFT JOIN InformationRegister.RelativeExchangeRates AS ManSExchangeRates
		|				ON TableOfDates.Date = ManSExchangeRates.Period
		|					AND ManSExchangeRates.Currency = &CurrencyOfMan
		|					AND ManSExchangeRates.BaseCurrency = &ComplCurrency) AS ExRates
		|
		|GROUP BY
		|	ExRates.Date
		|ORDER BY
		|	Date ASC
		|";
	Else
		Query.Text = "
		|SELECT
		|	ExRates.Date AS Date,
		|	SUM(ExRates.LocalCourse) AS LocalCourse,
		|	SUM(ExRates.ManSCourse) AS ManSCourse
		|FROM
		|	(SELECT
		|		TableOfDates.Date AS Date,
		|		ISNULL(CASE WHEN SettlementCurrencyRates_.Currency = &Currency AND &Currency <> &ComplCurrency
		|					THEN SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator
		|					ELSE 0
		|				END,
		|				CASE WHEN &ComplCurrency = &Currency
		|					THEN 1
		|					ELSE 0
		|				END) AS LocalCourse,
		|		ISNULL(CASE WHEN SettlementCurrencyRates_.Currency = &CurrencyOfMan AND &ComplCurrency <> &CurrencyOfMan
		|					THEN SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator
		|					ELSE 0
		|				END,
		|				CASE WHEN &ComplCurrency = &CurrencyOfMan
		|						THEN 1
		|					ELSE 0
		|				END) AS ManSCourse
		|	FROM
		|		TableOfDates AS TableOfDates
		|			LEFT JOIN InformationRegister.RelativeExchangeRates AS SettlementCurrencyRates_
		|				ON TableOfDates.Date = SettlementCurrencyRates_.Period
		|					AND SettlementCurrencyRates_.BaseCurrency = &ComplCurrency
		|					AND SettlementCurrencyRates_.Currency IN (&Currency,&CurrencyOfMan)) AS ExRates
		|
		|GROUP BY
		|	ExRates.Date
		|ORDER BY
		|	Date ASC
		|";
	EndIf;
	
	Currency_Rates =  Query.Execute().Unload();
	
	Query.Text = "
	|SELECT
	|	SUM(ExRates.LocalCourse) AS LocalCourse,
	|	SUM(ExRates.ManSCourse) AS ManSCourse
	|FROM
	|	(SELECT
	|		SettlementCurrencyRates_.Period AS Date,
	|		CASE WHEN NOT &CourseSpecifiedInContract AND SettlementCurrencyRates_.Currency = &Currency 
	|			THEN SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator
	|			ELSE 0
	|		END AS LocalCourse,
	|		CASE WHEN NOT (&CourseSpecifiedInContract AND &CurrencyOfMan = &Currency) AND SettlementCurrencyRates_.Currency = &CurrencyOfMan 
	|			THEN SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator
	|			ELSE 0
	|		END AS ManSCourse
	|	FROM
	|		InformationRegister.RelativeExchangeRates.SliceLast(&StartDate, BaseCurrency = &ComplCurrency AND Currency IN (&Currency,&CurrencyOfMan)) AS SettlementCurrencyRates_
	|	
	|	UNION ALL 
	|	
	|	SELECT
	|		SettlementCurrencyRates_.Period AS Date,
	|		SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator  AS LocalCourse,
	|		CASE WHEN &CourseSpecifiedInContract AND &CurrencyOfMan = &Currency
	|			THEN SettlementCurrencyRates_.CourseNumerator / SettlementCurrencyRates_.CourseDenominator
	|			ELSE 0
	|		END AS ManSCourse
	|	FROM
	|		InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&StartDate, Contract = &Contract) AS SettlementCurrencyRates_
	|	WHERE &CourseSpecifiedInContract) AS ExRates
	|;";
	
	CurrencyRatesCut = Query.Execute().Unload();
	
	CurLocalExchangeRate = ?(CurrencyRatesCut.Count() > 0, CurrencyRatesCut[0].LocalCourse, 1);
	CurRateOfMan = ?(CurrencyRatesCut.Count() > 0, CurrencyRatesCut[0].ManSCourse, 1);
	
	CurLocalExchangeRate = ?(ValueIsFilled(CurLocalExchangeRate), CurLocalExchangeRate, 1);
	CurRateOfMan =  ?(ValueIsFilled(CurRateOfMan), CurRateOfMan, 1);
	
	LinesWithEmptyLocalCourse = Currency_Rates.FindRows(New Structure("LocalCourse", 0));
	For Each EmptyCourseLine In LinesWithEmptyLocalCourse Do
		If Currency_Rates.IndexOf(EmptyCourseLine) = 0 Then 
			EmptyCourseLine.LocalCourse = CurLocalExchangeRate;
			If Not ValueIsFilled(EmptyCourseLine.ManSCourse) Then
				EmptyCourseLine.ManSCourse = CurRateOfMan;
			EndIf;
		Else
			EmptyCourseLine.LocalCourse = Currency_Rates[Currency_Rates.IndexOf(EmptyCourseLine)-1].LocalCourse;
			If Not ValueIsFilled(EmptyCourseLine.ManSCourse) Then
				EmptyCourseLine.ManSCourse = Currency_Rates[Currency_Rates.IndexOf(EmptyCourseLine)-1].ManSCourse;
			EndIf;
		EndIf;
	EndDo;
	
	LinesWithEmptyManExchangeRate = Currency_Rates.FindRows(New Structure("ManSCourse", 0));
	For Each EmptyCourseLine In LinesWithEmptyManExchangeRate Do
		If Currency_Rates.IndexOf(EmptyCourseLine) = 0 Then 
			EmptyCourseLine.ManSCourse = CurRateOfMan;
		Else
			EmptyCourseLine.ManSCourse = Currency_Rates[Currency_Rates.IndexOf(EmptyCourseLine)-1].ManSCourse;
		EndIf;
	EndDo;
	
	Currency_Rates.Indexes.Add("Date");
	
	Return Currency_Rates;
	
EndFunction

// Returns a table of invoices and advances credited to them at the time of recalculation.
//The data is used to determine the weighted average rate of the invoice.
Function GetInvoiceData(Query, TheseAreSettlementsWithCustomers)
	
	Query.Text = "
	|SELECT DISTINCT
	|	Table.ARAPObject AS ARAPObject,
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.Currency AS Currency,
	|	Table.LinkedDocument AS LinkedDocument
	|INTO TableRelatedDocuments
	|FROM
	|	RegisteredRecordsClients AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTParameters.CalculationsTypeParameter AS PaymentType_,
	|	TTParameters.PartnerAccountingAnalyticsParameter AS AccountingDimensionByPartners,
	|	TTParameters.ParameterARAPObject AS ARAPObject,
	|	TTParameters.CurrencyParameter AS Currency,
	|	TTParameters.ParameterDateWhenRecalculationStarted AS RecalculationStartDate,
	|	TableRelatedDocuments.LinkedDocument AS LinkedDocument
	|INTO TTRelatedDocumentsClient
	|FROM
	|	TTAugmentedDistributionParameters AS TTParameters
	|		INNER JOIN TableRelatedDocuments AS TableRelatedDocuments
	|		ON TTParameters.PartnerAccountingAnalyticsParameter = TableRelatedDocuments.AccountingDimensionByPartners
	|		AND TTParameters.ParameterARAPObject = TableRelatedDocuments.ARAPObject
	|		AND TTParameters.CurrencyParameter = TableRelatedDocuments.Currency
	|WHERE
	|	TTParameters.ParameterIsCustomerSettlements = &ParameterIsCustomerSettlements
	|
	|INDEX BY
	|	ARAPObject,
	|	AccountingDimensionByPartners,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCalculationsForTermsUpTo.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTCalculationsForTermsUpTo.ARAPObject AS ARAPObject,
	|	TTCalculationsForTermsUpTo.Currency AS Currency,
	|	TTCalculationsForTermsUpTo.DocumentRecorder AS Invoice,
	|	SUM(ISNULL(CASE
	|		WHEN TTCalculationsForTermsUpTo.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN TTCalculationsForTermsUpTo.Prepayment - TTCalculationsForTermsUpTo.Debt
	|		ELSE TTCalculationsForTermsUpTo.Debt
	|	END, 0)) AS Sum,
	|	SUM(ISNULL(CASE
	|		WHEN TTCalculationsForTermsUpTo.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN TTCalculationsForTermsUpTo.PrepaymentLocal - TTCalculationsForTermsUpTo.DebtLocal
	|		ELSE TTCalculationsForTermsUpTo.DebtLocal
	|	END, 0)) AS SumCompl,
	|	SUM(ISNULL(CASE
	|		WHEN TTCalculationsForTermsUpTo.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN TTCalculationsForTermsUpTo.PrepaymentMan - TTCalculationsForTermsUpTo.ARAPMan
	|		ELSE TTCalculationsForTermsUpTo.ARAPMan
	|	END, 0)) AS SumMan
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS TTCalculationsForTermsUpTo
	|		INNER JOIN TTRelatedDocumentsClient AS TableOfRelatedDocuments
	|		ON TTCalculationsForTermsUpTo.DocumentRecorder = TableOfRelatedDocuments.LinkedDocument
	|		AND TTCalculationsForTermsUpTo.AccountingDimensionByPartners = TableOfRelatedDocuments.AccountingDimensionByPartners
	|		AND TTCalculationsForTermsUpTo.ARAPObject = TableOfRelatedDocuments.ARAPObject
	|		AND TTCalculationsForTermsUpTo.Currency = TableOfRelatedDocuments.Currency
	|		AND TTCalculationsForTermsUpTo.Period < TableOfRelatedDocuments.RecalculationStartDate
	|		AND NOT VALUETYPE(TTCalculationsForTermsUpTo.DocumentRecorder) IN (TYPE(Document.SaleAdjustment),TYPE(Document.PurchaseAdjustment))
	|WHERE
	|	TTCalculationsForTermsUpTo.Active
	|GROUP BY
	|	TTCalculationsForTermsUpTo.AccountingDimensionByPartners,
	|	TTCalculationsForTermsUpTo.ARAPObject,
	|	TTCalculationsForTermsUpTo.Currency,
	|	TTCalculationsForTermsUpTo.DocumentRecorder
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfRelatedDocuments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableOfRelatedDocuments.ARAPObject AS ARAPObject,
	|	TableOfRelatedDocuments.Currency AS Currency,
	|	RelatedDocuments.Ref AS Invoice,
	|	RelatedDocuments.AmountARAP AS Sum,
	|	RelatedDocuments.SumCompl AS SumCompl,
	|	RelatedDocuments.SumMan AS SumMan
	|FROM
	|	Document.SourceDocument AS RelatedDocuments
	|		INNER JOIN TTRelatedDocumentsClient AS TableOfRelatedDocuments
	|		ON RelatedDocuments.Ref = TableOfRelatedDocuments.LinkedDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTRelatedDocumentsClient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableRelatedDocuments";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"RegisteredRecordsClients","RegisteredRecordsSuppliers");
		Query.Text = StrReplace(Query.Text,"AccumulationRegister.CustomersARAPAccountingByDueDates", "AccumulationRegister.VendorsARAPAccountingByDueDates");
		Query.Text = StrReplace(Query.Text,"TTRelatedDocuments", "TTRelatedDocumentsVendor");
		Query.Text = StrReplace(Query.Text, "&ParameterIsCustomerSettlements", "FALSE");
	Else
		Query.Text = StrReplace(Query.Text, "&ParameterIsCustomerSettlements", "TRUE");
	EndIf;
	
	TableOfRelatedDocuments = Query.Execute().Unload();
	
	Return TableOfRelatedDocuments;
	
EndFunction

// The Balance of the prepayment at the beginning of the recalculation minus those who have already written off scheduled payments.
// 
// Parameters:
//  Query - Query - Query
// 
// Returns:
//  ValueTable
Function BalancesOfUndistributedAdvancesOfPlannedPaymentAtBeginningOfRecalculation(Query, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
		|SELECT DISTINCT
		|	Balance.ARAPObject                    AS ARAPObject,
		|	Balance.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	Balance.Currency                            AS Currency,
		|	Balance.ARAPDocument                 AS Recorder,
		|	MAX(Balance.OccurrenceDate)       AS DateOfMovement,
		|	MAX(Balance.OperationProcedure)         AS OperationProcedure
		|INTO TTPrepaymentDocuments
		|FROM
		|	TTCalculationsByTermsBalance AS Balance
		|WHERE
		|	Balance.Prepayment >0
		|GROUP BY
		|	Balance.ARAPObject,
		|	Balance.AccountingDimensionByPartners,
		|	Balance.Currency,
		|	Balance.ARAPDocument
		|;
		|SELECT
		|	NestedQuery.ARAPObject AS ARAPObject,
		|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	NestedQuery.Currency AS Currency,
		|	NestedQuery.DateOfMovement      AS DateOfMovement,
		|	NestedQuery.Recorder       AS Recorder,
		|	NestedQuery.ThisIsImplementationInPath AS ThisIsImplementationInPath,
		|	NestedQuery.OperationProcedure   AS OperationProcedure,
		|	NestedQuery.SetOff           AS SetOff,
		|	TRUE                            AS SummedUp,
		|	SUM(NestedQuery.Sum)      AS Sum,
		|	SUM(NestedQuery.Sum) > 0  AS BalanceIsPositive
		|FROM
		|	(
		|	SELECT
		|		Calculations.ARAPObject AS ARAPObject,
		|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		Calculations.Currency AS Currency,
		|		Calculations.DocumentRecorder AS Recorder,
		|		Calculations.OccurrenceDate   AS DateOfMovement,
		|		Calculations.OperationProcedure     AS OperationProcedure,
		|		FALSE                        AS SetOff,
		|		&ThisIsImplementationInPath         AS ThisIsImplementationInPath,
		|		Calculations.Prepayment          AS Sum
		|	FROM
		|		TTCalculationsByTermsBalance AS Calculations
		|	WHERE
		|		Calculations.Prepayment > 0
		|		AND VALUETYPE(Calculations.DocumentRecorder) NOT IN (TYPE(Document.PurchaseAdjustment), TYPE(Document.SaleAdjustment))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		PrepaymentDocuments.ARAPObject                   AS ARAPObject,
		|		PrepaymentDocuments.AccountingDimensionByPartners        AS AccountingDimensionByPartners,
		|		PrepaymentDocuments.Currency                           AS Currency,
		|		PrepaymentDocuments.Recorder                      AS Recorder,
		|		PrepaymentDocuments.DateOfMovement                     AS DateOfMovement,
		|		PrepaymentDocuments.OperationProcedure                  AS OperationProcedure,
		|		TRUE                                               AS SetOff,
		|		FALSE                                                 AS ThisIsImplementationInPath,
		|		-PaymentPlans.AmountDue                                  AS Sum
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlans
		|			INNER JOIN TTPrepaymentDocuments AS PrepaymentDocuments
		|				ON PrepaymentDocuments.Recorder = PaymentPlans.DocumentPayments
		|			INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
		|				ON PaymentPlans.ARAPObject = TTCalculationParameters.ParameterARAPObject
		|					AND PaymentPlans.AccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
		|					AND PaymentPlans.Currency = TTCalculationParameters.CurrencyParameter
		|	WHERE
		|		PaymentPlans.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND PaymentPlans.UnallocatedAdvancePayment
		|		AND PaymentPlans.Period < TTCalculationParameters.ParameterDateWhenRecalculationStarted
		|		AND VALUETYPE(PrepaymentDocuments.Recorder) NOT IN (TYPE(Document.PurchaseAdjustment), TYPE(Document.SaleAdjustment))
		|) AS NestedQuery
		|GROUP BY
		|	NestedQuery.ARAPObject,
		|	NestedQuery.AccountingDimensionByPartners,
		|	NestedQuery.Currency,
		|	NestedQuery.Recorder,
		|	NestedQuery.ThisIsImplementationInPath,
		|	NestedQuery.DateOfMovement,
		|	NestedQuery.SetOff,
		|	NestedQuery.OperationProcedure
		|ORDER BY
		|	ARAPObject,
		|	AccountingDimensionByPartners,
		|	Currency,
		|	DateOfMovement
		|";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"AccumulationRegister.CustomersARAPAccountingCashFlowPlan ","AccumulationRegister.VendorsARAPAccountingCashFlowPlan ");
		Query.Text = StrReplace(Query.Text,"TTCalculationsByTermsBalance","TTDueDateCalculationsBalancesVendors");
		Query.Text = StrReplace(Query.Text,"TTPrepaymentDocuments","TTPrepaidDocumentsVendors");
		Query.Text = StrReplace(Query.Text,"&ThisIsImplementationInPath","FALSE");
	Else
		Query.Text = StrReplace(Query.Text,"TTCalculationsByTermsBalance","TTDueSettlementsBalancesCustomers");
		Query.Text = StrReplace(Query.Text,"TTPrepaymentDocuments","TTPrePaymentDocumentsCustomers");
		Query.Text = StrReplace(
			Query.Text,
			"&ThisIsImplementationInPath",
			"CASE
			|			WHEN Calculations.DocumentRecorder REFS Document.CustomerInvoice
			|				THEN CAST(Calculations.DocumentRecorder AS Document.CustomerInvoice).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
			|			WHEN Calculations.DocumentRecorder REFS Document.CustomerInvoiceServicesAndAssets
			|				THEN CAST(Calculations.DocumentRecorder AS Document.CustomerInvoiceServicesAndAssets).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
			|			ELSE FALSE
			|		END");
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

Function GetIncomingRegisteredRecordsForScheduledPayments(Query, GlobalVariables, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|SELECT
	|	Calculations.ARAPObject                              AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners                   AS AccountingDimensionByPartners,
	|	Calculations.Currency                                      AS Currency,
	|	Calculations.RecorderDate                            AS OccurrenceDate,
	|	BEGINOFPERIOD(Calculations.RecorderDate,DAY)        AS Date,
	|	Calculations.OperationProcedure                             AS OperationProcedure,
	|	Calculations.Recorder                                 AS Recorder,
	|	Calculations.PaymentDate                                 AS PlannedRepaymentDate,
	|	Calculations.PaymentOption                               AS PaymentOption,
	|	SUM(Calculations.AmountDue)                              AS Sum
	|FROM
	|	RegisteredRecords AS Calculations
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON Calculations.ARAPObject = TTCalculationParameters.ParameterARAPObject
	|				AND Calculations.AccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|				AND Calculations.Currency = TTCalculationParameters.CurrencyParameter
	|				// Extra order entries are included in the calculation for orders with a period longer than the order date
	|				AND Calculations.RecorderDate >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|WHERE
	|	(VALUETYPE(Calculations.Recorder) IN (&TypesOfLoggers) OR &ImplementationIsOnWay)
	|		AND Calculations.RecordType = &Receipt
	|GROUP BY
	|	Calculations.ARAPObject,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Currency,
	|	Calculations.RecorderDate,
	|	BEGINOFPERIOD(Calculations.RecorderDate,DAY),
	|	Calculations.OperationProcedure,
	|	Calculations.Recorder,
	|	Calculations.PaymentDate,
	|	Calculations.PaymentOption
	|ORDER BY
	|	Calculations.ARAPObject,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Currency,
	|	Calculations.RecorderDate
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"RegisteredRecords","RegisteredRecordsSuppliers");
		Query.Text = StrReplace(Query.Text,"&Receipt","VALUE(AccumulationRecordType.Expense)");
		Query.Text = StrReplace(Query.Text,"&ImplementationIsOnWay","FALSE");
	Else
		Query.Text = StrReplace(Query.Text,"RegisteredRecords","RegisteredRecordsClients");
		Query.Text = StrReplace(Query.Text,"&Receipt","VALUE(AccumulationRecordType.Receipt)");
		Query.Text = StrReplace(Query.Text,"&ImplementationIsOnWay","(Calculations.SaleByOrder IN (&EmptyLinksToOrders) AND NOT TTCalculationParameters.ScheduleParameterInContract)
																	|AND	(CAST(Calculations.Recorder AS Document.CustomerInvoice).Status <> VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
																	|		AND CAST(Calculations.Recorder AS Document.CustomerInvoice).BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
																	|												VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
																	|												VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
																	|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
																	|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
																	|	OR CAST(Calculations.Recorder AS Document.CustomerInvoiceServicesAndAssets).Status <> VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
																	|		AND CAST(Calculations.Recorder AS Document.CustomerInvoiceServicesAndAssets).BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
																	|									VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
																	|	)");
	EndIf;
	
	Query.SetParameter("TypesOfLoggers", ListOfPlanRegistrarTypes());
	
	Result  = Query.Execute();
	IncomingChartRegisteredRecords = Result.Unload();
	
	Return IncomingChartRegisteredRecords;
	
EndFunction

//Returns a table of invoices that Close RegisteredRecorded Plans
Function GetClarificationsOfPaymentSchedules(Query, GlobalVariables, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|SELECT
	|	Calculations.ARAPObject                              AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners                   AS AccountingDimensionByPartners,
	|	Calculations.Currency                                      AS Currency,
	|	Calculations.RecorderDate                            AS DateOfMovement,
	|	BEGINOFPERIOD(Calculations.RecorderDate,DAY)        AS OccurrenceDate,
	|	Calculations.OperationProcedure                             AS OperationProcedure,
	|	Calculations.Recorder                                 AS Recorder,
	|	CASE WHEN TTCalculationParameters.ScheduleParameterInContract
	|			THEN TTCalculationParameters.ContractScheduleParameter
	|			ELSE Calculations.SaleByOrder
	|	END AS OrderDocument,
	|	CASE WHEN Calculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.EmptyRef)
	|			THEN VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned)
	|		WHEN Calculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.EmptyRef)
	|			THEN VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt)
	|		ELSE Calculations.PaymentOption 
	|	END                                               AS PaymentOption,
	|	//With ADDN and AZDN, the amount moves along another calculation object
	|	Calculations.AmountDue                                     AS Sum
	|FROM
	|	RegisteredRecordsClients AS Calculations
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON Calculations.ARAPObject = TTCalculationParameters.ParameterARAPObject
	|				AND Calculations.AccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|				AND Calculations.Currency = TTCalculationParameters.CurrencyParameter
	|				// Extra order entries are included in the calculation for orders with a period longer than the order date
	|				AND Calculations.RecorderDate >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|WHERE
	|	Calculations.RecordType = &Expense AND Calculations.AmountDue > 0
	|	AND (Calculations.SaleByOrder NOT IN (&EmptyLinksToOrders) OR TTCalculationParameters.ScheduleParameterInContract)
	|	AND VALUETYPE(Calculations.Recorder) IN (&ListOfTypesThatRefinePlans)
	|ORDER BY
	|	Calculations.ARAPObject,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Currency,
	|	Calculations.RecorderDate,
	|	Calculations.Period
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"AccumulationRegister.CustomersARAPAccounting ","AccumulationRegister.VendorsARAPAccounting ");
		Query.Text = StrReplace(Query.Text,"&Expense","VALUE(AccumulationRecordType.Receipt)");
		Query.Text = StrReplace(Query.Text,"SaleByOrder","PurchaseByOrder");
		Query.Text = StrReplace(Query.Text,"RegisteredRecordsClients","RegisteredRecordsSuppliers");
	Else
		Query.Text = StrReplace(Query.Text,"&Expense","VALUE(AccumulationRecordType.Expense)");
	EndIf;
	
	Result  = Query.Execute();
	ClarificationsOfPaymentSchedules = Result.Unload();
	ClarificationsOfPaymentSchedules.Indexes.Add("OrderDocument");
	
	Return ClarificationsOfPaymentSchedules;
	
EndFunction

Function ToGetIncomingRegisteredRecordsForScheduledShipments(Query, GlobalVariables, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|SELECT
	|	Calculations.ARAPObject                              AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners                   AS AccountingDimensionByPartners,
	|	Calculations.Currency                                      AS Currency,
	|	Calculations.RecorderDate                            AS OccurrenceDate,
	|	BEGINOFPERIOD(Calculations.RecorderDate,DAY)        AS Date,
	|	Calculations.OperationProcedure                             AS OperationProcedure,
	|	Calculations.Recorder                                 AS Recorder,
	|	BEGINOFPERIOD(Calculations.Period,DAY)                  AS PlannedRepaymentDate,
	|	Calculations.ToShip                                   AS Sum
	|FROM
	|	RegisteredRecordsClients AS Calculations
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON Calculations.ARAPObject = TTCalculationParameters.ParameterARAPObject
	|				AND Calculations.AccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|				AND Calculations.Currency = TTCalculationParameters.CurrencyParameter
	|				// In the calculation of the movement, there are extra entries of orders for shipment with a period longer than the order date
	|				AND Calculations.RecorderDate >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|WHERE
	|	VALUETYPE(Calculations.Recorder) IN (&TypesOfLoggers)
	|		AND Calculations.RecordType = &Expense
	|ORDER BY 
	|	Calculations.ARAPObject,
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.Currency,
	|	Calculations.RecorderDate,
	|	Calculations.Period
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"&Expense","VALUE(AccumulationRecordType.Receipt)");
		Query.Text = StrReplace(Query.Text,"RegisteredRecordsClients","RegisteredRecordsSuppliers");
	Else
		Query.Text = StrReplace(Query.Text,"&Expense","VALUE(AccumulationRecordType.Expense)");
	EndIf;
	
	Query.SetParameter("TypesOfLoggers", ListOfPlanRegistrarTypes());
	
	Result  = Query.Execute();
	IncomingRegisteredRecordsOfShipmentSchedule = Result.Unload();
	
	Return IncomingRegisteredRecordsOfShipmentSchedule;
	
EndFunction

// Parameters:
//  TableOfCurrentReceivers - ValueTable - It contains AR/AP objects for which it is necessary to find related calculations.:
//   * RecalculationStartDate - Date - The day from which the receiver search is performed
//   * ARAPObject - CatalogRef.ARAPObjects - The source AR/AP object from which you need to start searching for receivers
//   * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics Source
//   * Currency - CatalogRef.Currencies - Currency Source
//  CalculatedMeasurements - ValueTable - A table of already added recursively AR/AP objects for recalculation:
//   * OperationProcedure - String - The order for sorting and determining the connectivity of recalculation objects
//   * ARAPObject - CatalogRef.ARAPObjects - The source AR/AP object from which you need to start searching for receivers
//   * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics Source
//   * Currency - CatalogRef.Currencies - Currency Source
//   * CalculationObjectReceiver - CatalogRef.ARAPObjects - Calculation Object Receiver
//   * DestinationAccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics Receiver
//   * CurrencyReceiver - CatalogRef.Currencies - Currency Receiver
// 
// Returns:
//  ValueTable:
//   * RecalculationStartDate - Date - The day from which you need to make the distribution
//   * OperationProcedure - String - The order for sorting and determining the connectivity of recalculation objects
//   * PaymentType_ - EnumRef.PartnersARAPAccountingTypes - What calculations need to be distributed
//   * ARAPObject - CatalogRef.ARAPObjects - AR/AP object to be recalculated
//   * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics for recalculation
//   * Currency - CatalogRef.Currencies - Currency For Conversion
//   * ByDataOfSourceARAPObject - Boolean - This is the receiver string
//   * CalculationObjectReceiver - CatalogRef.ARAPObjects - Calculation Object Receiver
//   * DestinationAccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics Receiver
//   * CurrencyReceiver - CatalogRef.Currencies - Currency Receiver
// 
Function GetRelationshipTableRecursively(TableOfCurrentReceivers, CalculatedMeasurements = Undefined)
	
	ArrayOfRequestPackets = New Array;
	ArrayOfRequestJoins = New Array;
	
	If CalculatedMeasurements = Undefined Then
		// The first call, it is necessary to add a table of measurements already taken into account to the calculation
		
		CalculatedMeasurements = New ValueTable;
		StringQualifier = New StringQualifiers(40);
		CalculatedMeasurements.Columns.Add("OperationProcedure", New TypeDescription("String", , , , StringQualifier));
		CalculatedMeasurements.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
		CalculatedMeasurements.Columns.Add("AccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
		CalculatedMeasurements.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
		CalculatedMeasurements.Columns.Add("CalculationObjectReceiver", New TypeDescription("CatalogRef.ARAPObjects"));
		CalculatedMeasurements.Columns.Add("DestinationAccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
		CalculatedMeasurements.Columns.Add("CurrencyReceiver", New TypeDescription("CatalogRef.Currencies"));
		
		// The operation order does not have to be filled in for the first call
		ConditionForSearchingForReceivers = "TTCurrentReceivers.RecalculationStartDate <= Calculations.Period";
		
		// Group the input table so that further search works optimally
		ArrayOfRequestPackets.Add("
			|SELECT DISTINCT
			|	Table.RecalculationStartDate       AS RecalculationStartDate,
			|	Table.PeriodForMonitoringChangesAndCreatingTasks AS PeriodForMonitoringChangesAndCreatingTasks,
			|	Table.ARAPObject            AS ARAPObject,
			|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	Table.Currency                    AS Currency
			|INTO TTCurrentReceiversTable
			|FROM
			|	&TableOfCurrentReceivers AS Table
			|");
		
		// In the first call, we are not looking for receivers, but current objects for distribution
		ArrayOfRequestPackets.Add("
			|SELECT
			|	MIN(Table.RecalculationStartDate) AS RecalculationStartDate,
			|	MIN(Table.PeriodForMonitoringChangesAndCreatingTasks) AS PeriodForMonitoringChangesAndCreatingTasks,
			|	Table.ARAPObject AS ARAPObject,
			|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	Table.Currency AS Currency
			|INTO TTCurrentReceivers
			|FROM
			|	TTCurrentReceiversTable AS Table
			|
			|GROUP BY
			|	Table.ARAPObject,
			|	Table.AccountingDimensionByPartners,
			|	Table.Currency
			|
			|INDEX BY
			|	ARAPObject,
			|	AccountingDimensionByPartners,
			|	Currency"); 
		ArrayOfRequestPackets.Add("DROP TTCurrentReceiversTable");
		
	Else
		
		ConditionForSearchingForReceivers = "TTCurrentReceivers.OperationProcedure <= Calculations.OperationProcedure";
		// Empty calculation objects are added to the search from the empty Attribute of the account objectreception, they must be discarded
		ArrayOfRequestPackets.Add("
			|SELECT DISTINCT
			|	Table.RecalculationStartDate               AS RecalculationStartDate,
			|	Table.PeriodForMonitoringChangesAndCreatingTasks AS PeriodForMonitoringChangesAndCreatingTasks,
			|	Table.OperationProcedure                   AS OperationProcedure,
			|	Table.Recorder                       AS Recorder,
			|	Table.Organization                       AS Organization,
			|	Table.CalculationObjectReceiver            AS ARAPObject,
			|	Table.DestinationAccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	Table.CurrencyReceiver                    AS Currency
			|INTO TTCurrentReceiversWithEmpty
			|FROM
			|	&TableOfCurrentReceivers AS Table
			|");
		
		ArrayOfRequestPackets.Add("
			|SELECT
			|	MIN(Table.RecalculationStartDate) AS RecalculationStartDate,
			|	MIN(Table.PeriodForMonitoringChangesAndCreatingTasks) AS PeriodForMonitoringChangesAndCreatingTasks,
			|	Table.OperationProcedure           AS OperationProcedure,
			|	Table.Recorder               AS Recorder,
			|	Table.Organization               AS Organization,
			|	Table.ARAPObject            AS ARAPObject,
			|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	Table.Currency                    AS Currency
			|INTO TTCurrentReceivers
			|FROM
			|	TTCurrentReceiversWithEmpty AS Table
			|WHERE
			|	Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|
			|GROUP BY
			|	Table.OperationProcedure,
			|	Table.Recorder,
			|	Table.Organization,
			|	Table.ARAPObject,
			|	Table.AccountingDimensionByPartners,
			|	Table.Currency
			|INDEX BY
			|	ARAPObject,
			|	AccountingDimensionByPartners,
			|	Currency,
			|	OperationProcedure
			|");
		
		ArrayOfRequestPackets.Add("DROP TTCurrentReceiversWithEmpty");
		
		ArrayOfRequestJoins.Add("
			|SELECT DISTINCT
			|	TTCurrentReceivers.RecalculationStartDate                           AS RecalculationStartDate,
			|	TTCurrentReceivers.PeriodForMonitoringChangesAndCreatingTasks       AS PeriodForMonitoringChangesAndCreatingTasks,
			|	CatalogARAPObjects.PaymentType_                            AS PaymentType_,
			|	TTCurrentReceivers.OperationProcedure                               AS OperationProcedure,
			|	TTCurrentReceivers.Recorder                                   AS Recorder,
			|	TTCurrentReceivers.Organization                                   AS Organization,
			|	TTCurrentReceivers.ARAPObject                                AS ARAPObject,
			|	TTCurrentReceivers.AccountingDimensionByPartners                     AS AccountingDimensionByPartners,
			|	TTCurrentReceivers.Currency                                        AS Currency,
			|	TRUE                                                           AS ByDataOfSourceARAPObject,
			|	VALUE(Catalog.ARAPObjects.EmptyRef)                AS CalculationObjectReceiver,
			|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
			|	VALUE(Catalog.Currencies.EmptyRef)                         AS CurrencyReceiver
			|FROM
			|	TTCurrentReceivers AS TTCurrentReceivers
			|	INNER JOIN Catalog.ARAPObjects AS CatalogARAPObjects
			|		ON TTCurrentReceivers.ARAPObject = CatalogARAPObjects.Ref
			|");
		
	EndIf;
	
	ArrayOfRequestPackets.Add("
		|SELECT
		|	Table.OperationProcedure                   AS OperationProcedure,
		|	Table.ARAPObject                    AS ARAPObject,
		|	Table.AccountingDimensionByPartners         AS AccountingDimensionByPartners,
		|	Table.Currency                            AS Currency,
		|	Table.CalculationObjectReceiver            AS CalculationObjectReceiver,
		|	Table.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
		|	Table.CurrencyReceiver                    AS CurrencyReceiver
		|INTO TTCalculatedMeasurements
		|FROM
		|	&CalculatedMeasurements AS Table
		|INDEX BY
		|	OperationProcedure,
		|	ARAPObject,
		|	AccountingDimensionByPartners,
		|	Currency,
		|	CalculationObjectReceiver,
		|	DestinationAccountingDimensionByPartners,
		|	CurrencyReceiver
		|");
	
	QueryTextTemplate2 = "
		|SELECT DISTINCT
		|	CASE
		|		WHEN BEGINOFPERIOD(Calculations.Period, DAY) > TTCurrentReceivers.RecalculationStartDate
		|			THEN BEGINOFPERIOD(Calculations.Period, DAY)
		|		ELSE TTCurrentReceivers.RecalculationStartDate
		|	END                                      AS RecalculationStartDate,
		|	TTCurrentReceivers.PeriodForMonitoringChangesAndCreatingTasks AS PeriodForMonitoringChangesAndCreatingTasks,
		|	&PaymentType_                               AS PaymentType_,
		|	Calculations.OperationProcedure                    AS OperationProcedure,
		|	Calculations.Recorder                        AS Recorder,
		|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
		|	Calculations.ARAPObject                     AS ARAPObject,
		|	Calculations.AccountingDimensionByPartners          AS AccountingDimensionByPartners,
		|	Calculations.Currency                             AS Currency,
		|	Calculations.ByDataOfSourceARAPObject   AS ByDataOfSourceARAPObject,
		|	Calculations.CalculationObjectReceiver             AS CalculationObjectReceiver,
		|	Calculations.DestinationAccountingDimensionByPartners  AS DestinationAccountingDimensionByPartners,
		|	Calculations.CurrencyReceiver                     AS CurrencyReceiver
		|FROM
		|	TTCurrentReceivers AS TTCurrentReceivers
		|	INNER JOIN AccumulationRegister.CustomersARAPAccounting AS Calculations
		|		ON TTCurrentReceivers.ARAPObject = Calculations.ARAPObject
		|		AND TTCurrentReceivers.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
		|		AND TTCurrentReceivers.Currency = Calculations.Currency
		|		AND &ConditionForSearchingForReceivers
		|	LEFT JOIN TTCalculatedMeasurements AS TTCalculatedMeasurements
		|		ON Calculations.ARAPObject = TTCalculatedMeasurements.ARAPObject
		|		AND Calculations.AccountingDimensionByPartners = TTCalculatedMeasurements.AccountingDimensionByPartners
		|		AND Calculations.Currency = TTCalculatedMeasurements.Currency
		|		AND Calculations.CalculationObjectReceiver = TTCalculatedMeasurements.CalculationObjectReceiver
		|		AND Calculations.DestinationAccountingDimensionByPartners = TTCalculatedMeasurements.DestinationAccountingDimensionByPartners
		|		AND Calculations.CurrencyReceiver = TTCalculatedMeasurements.CurrencyReceiver
		|		AND Calculations.OperationProcedure = TTCalculatedMeasurements.OperationProcedure
		|WHERE
		|	Calculations.Active
		|	AND TTCalculatedMeasurements.ARAPObject IS NULL
		|	AND (&ResourceOccupancyCondition)";
	
	// We are looking for records of transactions in the operational register of settlements with clients
	ArrayOfRequestJoins.Add(
		StrReplace(StrReplace(QueryTextTemplate2,
				"&ResourceOccupancyCondition",
				"Calculations.Sum <> 0
				|	OR Calculations.SumCompl <> 0
				|	OR Calculations.SumMan <> 0
				|	OR Calculations.AmountDue <> 0
				|	OR Calculations.ToShip <> 0"),
			"&PaymentType_",
			"VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)"));
	
	// We are looking for entries in the register of settlements on terms with clients
	ArrayOfRequestJoins.Add(
		StrReplace(StrReplace(StrReplace(StrReplace(QueryTextTemplate2,
						"Calculations.Recorder",
						"Calculations.DocumentRecorder"),
					Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName(),
					Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName()),
				"&ResourceOccupancyCondition",
				"TRUE"),
			"&PaymentType_",
			"VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)"));
	
	// We are looking for entries in the operational register of settlements with suppliers
	ArrayOfRequestJoins.Add(
		StrReplace(StrReplace(StrReplace(QueryTextTemplate2,
					Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName(),
					Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName()),
				"&ResourceOccupancyCondition",
				"Calculations.Sum <> 0
				|	OR Calculations.SumCompl <> 0
				|	OR Calculations.SumMan <> 0
				|	OR Calculations.AmountDue <> 0
				|	OR Calculations.ToReceive <> 0"),
			"&PaymentType_",
			"VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)"));
	
	// We are looking for entries in the register of settlements on terms with suppliers
	ArrayOfRequestJoins.Add(
		StrReplace(StrReplace(StrReplace(StrReplace(QueryTextTemplate2,
						"Calculations.Recorder",
						"Calculations.DocumentRecorder"),
					Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName(),
					Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.FullName()),
				"&ResourceOccupancyCondition",
				"TRUE"),
			"&PaymentType_",
			"VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)"));
	
	ArrayOfRequestPackets.Add(StrConcat(ArrayOfRequestJoins, TMCommonUse.QuerySeparatorInJoin(True)));
	
	Query = New Query;
	Query.SetParameter("TableOfCurrentReceivers", TableOfCurrentReceivers);
	Query.SetParameter("CalculatedMeasurements", CalculatedMeasurements);
	Query.Text = StrConcat(ArrayOfRequestPackets, Common.QueryBatchSeparator());
	Query.Text = StrReplace(Query.Text, "&ConditionForSearchingForReceivers", ConditionForSearchingForReceivers);
	
	// New receivers for distribution
	TableOfReceivers = Query.Execute().Unload();
	
	// We add all new receivers to the table with the data already added to the calculation
	For Each DestinationRow1 In TableOfReceivers Do
		FillPropertyValues(CalculatedMeasurements.Add(), DestinationRow1);
	EndDo;
	If TableOfReceivers.Count() > 0 Then
		LinkTable = GetRelationshipTableRecursively(TableOfReceivers, CalculatedMeasurements);
		For Each DestinationRow1 In LinkTable Do
			FillPropertyValues(TableOfReceivers.Add(), DestinationRow1);
		EndDo;
	EndIf;
	
	ColumnsNames = New Array;
	For Each Column In TableOfReceivers.Columns Do
		ColumnsNames.Add(Column.Name);
	EndDo;
	
	TableOfReceivers.GroupBy(StrConcat(ColumnsNames, ","));
	
	Return TableOfReceivers;
	
EndFunction

// Finds recursively all related AR/AP objects according to the passed table
//
// Parameters:
//  OriginalTableForRecalculation - ValueTable - Contains calculation objects for which it is necessary to find related calculations. It must contain columns:
//   * RecalculationStartDate - Date - The day from which the receiver search is performed
//   * PeriodForMonitoringChangesAndCreatingTasks - Date - the day from which you need to check changes and create tasks
//   * PaymentType_ - EnumRef.PartnersARAPAccountingTypes - What calculations need to be distributed
//   * ARAPObject - CatalogRef.ARAPObjects - The source AR/AP object from which you need to start searching for receivers
//   * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics Source
//   * Currency - CatalogRef.Currencies - Currency Source
// 
// Returns:
//  ValueTable:
//   * RecalculationStartDate - Date - The day from which you need to make the distribution
//   * PeriodForMonitoringChangesAndCreatingTasks - Date - the day from which you need to check changes and create tasks
//   * OperationProcedure - String - The order for sorting and determining the connectivity of recalculation objects
//   * Recorder - DocumentRef - The registrar document that formed the connection is needed to register tasks for the distribution of receivers
//   * Organization - CatalogRef - Organization, used to register tasks for the distribution of receivers
//   * PaymentType_ - EnumRef.PartnersARAPAccountingTypes - What calculations need to be distributed
//   * ARAPObject - CatalogRef.ARAPObjects - AR/AP object to be recalculated
//   * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics for recalculation
//   * Currency - CatalogRef.Currencies - Currency For Conversion
//   * ByDataOfSourceARAPObject - Boolean - This is the receiver string
//   * CalculationObjectReceiver - CatalogRef.ARAPObjects - Calculation Object Receiver
//   * DestinationAccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Analytics Receiver
//   * CurrencyReceiver - CatalogRef.Currencies - Currency Receiver
// 
Function TableOfSourceReceiverRelationships(OriginalTableForRecalculation) Export
	
	Result = OriginalTableForRecalculation.Copy();
	If Result.Columns.Find("OperationProcedure") = Undefined Then
		StringQualifier = New StringQualifiers(40);
		Result.Columns.Add("OperationProcedure", New TypeDescription("String", , , , StringQualifier));
	EndIf;
	If Result.Columns.Find("Recorder") = Undefined Then
		Result.Columns.Add("Recorder", Documents.AllRefsType());
	EndIf;
	If Result.Columns.Find("Organization") = Undefined Then
		Result.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	EndIf;
	If Result.Columns.Find("ByDataOfSourceARAPObject") = Undefined Then
		Result.Columns.Add("ByDataOfSourceARAPObject", New TypeDescription("Boolean"));
	EndIf;
	If Result.Columns.Find("CalculationObjectReceiver") = Undefined Then
		Result.Columns.Add("CalculationObjectReceiver", New TypeDescription("CatalogRef.ARAPObjects"));
	EndIf;
	If Result.Columns.Find("DestinationAccountingDimensionByPartners") = Undefined Then
		Result.Columns.Add("DestinationAccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
	EndIf;
	If Result.Columns.Find("CurrencyReceiver") = Undefined Then
		Result.Columns.Add("CurrencyReceiver", New TypeDescription("CatalogRef.Currencies"));
	EndIf;
	
	For Each InitialString In Result Do
		If Not ValueIsFilled(InitialString.OperationProcedure) Then
			InitialString.OperationProcedure = Order(InitialString.RecalculationStartDate, "", Type("DocumentRef.RegisterAdjustment"), "0", "00");
		EndIf;
	EndDo;
	
	LinkTable = GetRelationshipTableRecursively(OriginalTableForRecalculation);
	
	For Each FoundLinkString In LinkTable Do
		
		NewRow = Result.Add();
		NewRow.RecalculationStartDate                     = FoundLinkString.RecalculationStartDate;
		NewRow.PeriodForMonitoringChangesAndCreatingTasks = FoundLinkString.PeriodForMonitoringChangesAndCreatingTasks;
		NewRow.OperationProcedure                         = FoundLinkString.OperationProcedure;
		NewRow.Recorder                             = FoundLinkString.Recorder;
		NewRow.Organization                             = FoundLinkString.Organization;
		NewRow.PaymentType_                             = FoundLinkString.PaymentType_;
		NewRow.ARAPObject                          = FoundLinkString.ARAPObject;
		NewRow.AccountingDimensionByPartners               = FoundLinkString.AccountingDimensionByPartners;
		NewRow.Currency                                  = FoundLinkString.Currency;
		NewRow.ByDataOfSourceARAPObject        = FoundLinkString.ByDataOfSourceARAPObject;
		NewRow.CalculationObjectReceiver                  = FoundLinkString.CalculationObjectReceiver;
		NewRow.DestinationAccountingDimensionByPartners       = FoundLinkString.DestinationAccountingDimensionByPartners;
		NewRow.CurrencyReceiver                          = FoundLinkString.CurrencyReceiver;
		
	EndDo;
	
	Return Result;
	
EndFunction

//Returns a table of invoices that Close RegisteredRecorded Plans
Function GetClosingShippingSchedules(Query, GlobalVariables, TheseAreSettlementsWithCustomers = False)
	
	Query.Text = "
	|SELECT
	|	Calculations.RecorderDate                            AS DateOfMovement,
	|	BEGINOFPERIOD(Calculations.RecorderDate,DAY)        AS OccurrenceDate,
	|	Calculations.ARAPObject                              AS ARAPObject,
	|	Calculations.AccountingDimensionByPartners                   AS AccountingDimensionByPartners,
	|	Calculations.Currency                                      AS Currency,
	|	Calculations.OperationProcedure                             AS OperationProcedure,
	|	Calculations.Recorder                                 AS Recorder,
	|	CASE WHEN TTCalculationParameters.ScheduleParameterInContract
	|			THEN TTCalculationParameters.ContractScheduleParameter
	|			ELSE Calculations.SaleByOrder
	|	END                                               AS OrderDocument,
	|//With ADDN and AZDN, the amount moves along another calculation object
	|	Calculations.ToShip AS Sum
	|FROM
	|	RegisteredRecordsClients AS Calculations
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON Calculations.ARAPObject = TTCalculationParameters.ParameterARAPObject
	|				AND Calculations.AccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|				AND Calculations.Currency = TTCalculationParameters.CurrencyParameter
	|				// In the calculation of the movement, there are extra entries of orders for shipment with a period longer than the order date
	|				AND Calculations.RecorderDate >= TTCalculationParameters.ParameterDateWhenRecalculationStarted
	|WHERE
	|	Calculations.ToShip > 0 AND Calculations.RecordType = &Receipt
	|	AND (Calculations.SaleByOrder NOT IN (&EmptyLinksToOrders) OR TTCalculationParameters.ScheduleParameterInContract)
	|	AND VALUETYPE(Calculations.Recorder) IN (&ListOfTypesThatRefinePlans)
	|ORDER BY
	|	Calculations.RecorderDate
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"&Receipt","VALUE(AccumulationRecordType.Expense)");
		Query.Text = StrReplace(Query.Text,"SaleByOrder","PurchaseByOrder");
		Query.Text = StrReplace(Query.Text,"RegisteredRecordsClients","RegisteredRecordsSuppliers");
	Else
		Query.Text = StrReplace(Query.Text,"&Receipt","VALUE(AccumulationRecordType.Receipt)");
	EndIf;
	
	Result  = Query.Execute();
	ClosingShippingSchedules = Result.Unload();
	ClosingShippingSchedules.Indexes.Add("OrderDocument");
	
	Return ClosingShippingSchedules;
EndFunction

Function TableOfBalancesOfSettlements(Query, TheseAreSettlementsWithCustomers);
	Query.Text = "
	|SELECT
	|	Balance.ARAPObject                                                            AS ARAPObject,
	|	Balance.AccountingDimensionByPartners                                                 AS AccountingDimensionByPartners,
	|	Balance.Currency                                                                    AS Currency,
	|
	|	Balance.ARAPDocument                                                         AS ARAPDocument,
	|	Balance.OccurrenceDate                                                         AS OccurrenceDate,
	|	Balance.PlannedRepaymentDate                                                    AS PlannedRepaymentDate,
	//It is necessary to sort the Balances to be read when creating repair records.
	|	Balance.OperationProcedure                                                           AS OperationProcedure,
	|	Balance.SettlementProcedure                                                             AS SettlementProcedureByPaymentDate,
	|	Balance.PlannedRepaymentDate = DATETIME(1,1,1)                                 AS RepaymentDateIsNotFilledIn,
	|
	|	BEGINOFPERIOD(DATEADD(TTCalculationParameters.ParameterDateWhenRecalculationStarted,SECOND,-1),DAY) AS DateOfRevaluation,
	|	Balance.Debt                                                                AS Debt,
	|	Balance.DebtLocal                                                            AS DebtLocal,
	|	Balance.ARAPMan                                                             AS ARAPMan,
	|	Balance.Prepayment                                                          AS Prepayment,
	|	Balance.PrepaymentLocal                                                      AS PrepaymentLocal,
	|	Balance.PrepaymentMan                                                       AS PrepaymentMan
	|FROM
	|	TTDueSettlementsBalancesCustomers AS Balance
	|		INNER JOIN TTAugmentedDistributionParameters AS TTCalculationParameters
	|			ON Balance.ARAPObject = TTCalculationParameters.ParameterARAPObject
	|				AND Balance.AccountingDimensionByPartners = TTCalculationParameters.PartnerAccountingAnalyticsParameter
	|				AND Balance.Currency = TTCalculationParameters.CurrencyParameter
	|WHERE
	|	Balance.ThereIsPrepayment OR Balance.ThereIsDuty
	|ORDER BY
	|	Balance.OperationProcedure,
	|	CASE WHEN Balance.PlannedRepaymentDate = DATETIME(1,1,1) AND Balance.Prepayment > 0
	|		THEN 2
	|		ELSE 1
	|	END 
	|";
	If Not TheseAreSettlementsWithCustomers Then
		Query.Text = StrReplace(Query.Text,"TTDueSettlementsBalancesCustomers","TTDueDateCalculationsBalancesVendors");
	EndIf;
	
	Result     = Query.Execute();
	
	Return Result.Unload();
EndFunction

#EndRegion

#Region CommonMethodsForAddingStrings

#Region ActualRegisteredRecords

//Overestimates the debt until the moment of payment or for the current month
Procedure ReassessDebt(GlobalVariables, CurrentVariables, ARAPDocument, Val Date, RevalueAsOfTransferredDate = False)
	
	If CurrentVariables.ContractRateOption = Enums.ContractRateOptions.FixedAsOfShipmentDate 
		Or Not CurrentVariables.NeedReassessment Then
		Return;
	EndIf;
	
	If Date <> Undefined Then
		Date = BegOfDay(Date);
	EndIf;
	
	LinesForRevaluation = CurrentVariables.TableOfBalancesOfSettlements.FindRows(New Structure("ARAPDocument",ARAPDocument));
	For Each ShipmentLine In LinesForRevaluation Do
		
		If ShipmentLine.Debt = 0 And Not RevalueAsOfTransferredDate Then
			Continue;
		EndIf;
		
		If CurrentVariables.ContractRateOption = Enums.ContractRateOptions.FixedAsOfShipmentDate Then
		#Region FixedRateOnDateOfShipment
			// revaluation to a fixed rate is possible after partial payment at a different manual rate or payment in a currency other than the Local accounting currency.
			If Date <> Undefined Then
				AmountOfLocalRevaluation = Round(ShipmentLine.Debt * CurrentVariables.LocalFixedRate, 2) - ShipmentLine.SumCompl;
				AmountOfRevaluationOfMan = Round(ShipmentLine.Debt * CurrentVariables.FixedRateMan, 2) - ShipmentLine.SumMan;
				AddRevaluationRecord(CurrentVariables, Date, ShipmentLine, "Debt", AmountOfLocalRevaluation, AmountOfRevaluationOfMan);
				ShipmentLine.DateOfRevaluation = Date;
			EndIf;
			Continue;
		#EndRegion
		EndIf;
		
		#Region MonthlyRevaluation
		If GlobalVariables.DailyReassessment Then
			DateOfBirth_1 = BegOfDay(ShipmentLine.DateOfRevaluation);
		Else
			DateOfBirth_1 = BegOfDay(EndOfMonth(ShipmentLine.DateOfRevaluation));
		EndIf;
		
		FinalDateOfRevaluation = ?(Date <> Undefined, Date, CurrentSessionDate());
		While DateOfBirth_1 < FinalDateOfRevaluation Do
			
			CourseLine = CurrentVariables.TableOfExchangeRates.Find(DateOfBirth_1, "Date");
			
			If CourseLine <> Undefined Then
				AmountOfLocalRevaluation = Round(ShipmentLine.Debt * CourseLine.LocalCourse, 2) - ShipmentLine.DebtLocal;
				AmountOfRevaluationOfMan = Round(ShipmentLine.Debt * CourseLine.LocalCourse / CourseLine.ManSCourse, 2) - ShipmentLine.ARAPMan;
				AddRevaluationRecord(CurrentVariables, EndOfDay(DateOfBirth_1), ShipmentLine, "Debt", AmountOfLocalRevaluation, AmountOfRevaluationOfMan);
				ShipmentLine.DateOfRevaluation = DateOfBirth_1;
			EndIf;
			
			If GlobalVariables.DailyReassessment Then
				DateOfBirth_1 = DateOfBirth_1 + 86400;
			Else
				DateOfBirth_1 = BegOfDay(EndOfMonth(EndOfMonth(DateOfBirth_1)+1));
			EndIf;
			
		EndDo;
		
		#EndRegion
		
		#Region RevaluationOnTransferredDate
		If Date <> Undefined And Date > ShipmentLine.DateOfRevaluation 
			And RevalueAsOfTransferredDate Then
			
			CourseLine = CurrentVariables.TableOfExchangeRates.Find(Date, "Date");
			If CourseLine <> Undefined Then 
				AmountOfLocalRevaluation = Round(ShipmentLine.Debt * CourseLine.LocalCourse, 2) - ShipmentLine.DebtLocal;
				AmountOfRevaluationOfMan = Round(ShipmentLine.Debt  * CourseLine.LocalCourse / CourseLine.ManSCourse, 2) - ShipmentLine.ARAPMan;
				AddRevaluationRecord(CurrentVariables, Date, ShipmentLine, "Debt", AmountOfLocalRevaluation, AmountOfRevaluationOfMan);
				ShipmentLine.DateOfRevaluation = Date;
			EndIf;
			
		EndIf;
		#EndRegion
		
	EndDo;
	
EndProcedure

Procedure WriteOffLocalMansVidsBasedOnZeroBalances(CurrentVariables, RevaluationPeriod)
	LinesForRevaluation = CurrentVariables.TableOfBalancesOfSettlements.FindRows(New Structure("Debt,Prepayment",0,0));
	For Each LineForRevaluation In LinesForRevaluation Do
		If LineForRevaluation.DebtLocal <> 0 Or LineForRevaluation.ARAPMan <> 0 Then
			AddRevaluationRecord(CurrentVariables, RevaluationPeriod, LineForRevaluation, "Debt", -LineForRevaluation.DebtLocal, -LineForRevaluation.ARAPMan);
		EndIf;
		If LineForRevaluation.PrepaymentLocal <> 0 Or LineForRevaluation.PrepaymentMan <> 0 Then
			AddRevaluationRecord(CurrentVariables, RevaluationPeriod, LineForRevaluation, "Prepayment", -LineForRevaluation.PrepaymentLocal, -LineForRevaluation.PrepaymentMan);
		EndIf;
		CurrentVariables.TableOfBalancesOfSettlements.Delete(LineForRevaluation);
	EndDo;
EndProcedure

Procedure AddReceipt(CurrentVariables, CalculationLine_, SourceType)
	
	If CalculationLine_.Period >= CurrentVariables.RecalculationStartDate Then
	
		NwRw = CurrentVariables.TableOfCalculationsByTerms.Add();
		NwRw.RecordType                   = AccumulationRecordType.Receipt;
		NwRw.DocumentRecorder           = CalculationLine_.Recorder;
		NwRw.ARAPDocument             = CalculationLine_.ARAPDocument;
		If Not ValueIsFilled(NwRw.ARAPDocument) Then
			NwRw.ARAPDocument = CalculationLine_.Recorder;
		EndIf;
		NwRw.BusinessOperation         = CalculationLine_.BusinessOperation;
		NwRw.DocumentCurrency               = CalculationLine_.DocumentCurrency;
		NwRw.OccurrenceDate             = ?(CalculationLine_.ReversingEntry, BegOfDay(CalculationLine_.Period), CalculationLine_.OccurrenceDate);
		NwRw.Period                        = CalculationLine_.Period;
		NwRw.OperationProcedure               = CalculationLine_.OperationProcedure;
		NwRw.CashFlowItem = CalculationLine_.CashFlowItem;
		NwRw.BusinessTransactionSetting = CalculationLine_.BusinessTransactionSetting;
		NwRw.FinRecordID        = CalculationLine_.FinRecordID;
		NwRw.CorARAPObject             = CalculationLine_.CorARAPObject;
		NwRw.CorPartnerAccountingDimension  = CalculationLine_.CorPartnerAccountingDimension;
		NwRw.DestinationAccountingDimensionByPartners = CalculationLine_.DestinationAccountingDimensionByPartners;
		NwRw.CalculationObjectReceiver            = CalculationLine_.CalculationObjectReceiver;
		NwRw.CurrencyReceiver                    = CalculationLine_.CurrencyReceiver;
		NwRw.AmountReceiver                     = CalculationLine_.AmountReceiver;
		NwRw.ByDataOfSourceARAPObject  = CalculationLine_.ByDataOfSourceARAPObject;
		
		NwRw.ReversingEntry                        = False;
		
		If SourceType = "Payment" Then
		
			NwRw.LinkedDocument     = CalculationLine_.LinkedDocument;
		
			NwRw.Debt           = 0;
			NwRw.DebtLocal       = 0;
			NwRw.ARAPMan        = 0;
		
			NwRw.Prepayment     = CalculationLine_.Sum;
			NwRw.PrepaymentLocal = CalculationLine_.SumCompl;
			NwRw.PrepaymentMan  = CalculationLine_.SumMan;
			
			// If the Balance is formed storno by the record, then the maturity date is equal to the date of occurrence
			If CalculationLine_.ReversingEntry Then
				NwRw.PlannedRepaymentDate = BegOfDay(CalculationLine_.Period);
			Else
				NwRw.PlannedRepaymentDate = CalculationLine_.PlannedRepaymentDate;
			EndIf;
			
			NwRw.SettlementProcedure = ?(NwRw.PlannedRepaymentDate= Date(1,1,1),
												CalculationLine_.SettlementProcedureByPaymentDate,
												Format(NwRw.PlannedRepaymentDate , "DF=yyyyMMdd") + Right(CalculationLine_.SettlementProcedureByPaymentDate,20));
		ElsIf SourceType = "ShipmentDelivery" Then
		
			NwRw.Debt           = CalculationLine_.Sum;
			NwRw.DebtLocal       = CalculationLine_.SumCompl;
			NwRw.ARAPMan        = CalculationLine_.SumMan;
			
			NwRw.Prepayment     = 0;
			NwRw.PrepaymentLocal = 0;
			NwRw.PrepaymentMan  = 0;
			// If the Balance is formed storno by the record, then the maturity date is equal to the date of occurrence
			If CalculationLine_.ReversingEntry Then
				NwRw.PlannedRepaymentDate = BegOfDay(CalculationLine_.Period);
			Else
				NwRw.PlannedRepaymentDate = CalculationLine_.PlannedRepaymentDate;
			EndIf;
			NwRw.SettlementProcedure = CalculationLine_.SettlementProcedureByPaymentDate;
			
		EndIf;
		NwRw.RecordingBeforeCalculationStarts = False;
		NwRw.SettlementTransaction = CalculationLine_.SettlementTransaction;
		
		AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, NwRw);
	EndIf;

	If SourceType = "ShipmentDelivery" Then
		//There may not be an entry in these invoices.
		If CurrentVariables.InvoicesData[CalculationLine_.Recorder] = Undefined Then
			CurrentVariables.InvoicesData.Insert(CalculationLine_.Recorder, SumStructure());
		EndIf;
		
		// If we add a receipt, then the advances have already been credited, and part of the debt remains at the invoice rate.
		DataFromInvoice = CurrentVariables.InvoicesData[CalculationLine_.Recorder];
		DataFromInvoice.DocumentAmount     = DataFromInvoice.DocumentAmount + CalculationLine_.Sum;
		DataFromInvoice.TheAmountOfTheDocumentRegl = DataFromInvoice.TheAmountOfTheDocumentRegl + CalculationLine_.SumCompl;
		DataFromInvoice.DocumentAmountManag  = DataFromInvoice.DocumentAmountManag  + CalculationLine_.SumMan;
		
	EndIf;
	
EndProcedure

Procedure AddDebtExpense(CurrentVariables, RemainderLine_, CalculationLine_, DebitedAmount, AmountOfLocalTaxDebited, AmountOfManDebiting, BusinessOperation = Undefined);
	
	NewRow_Debt_Expense = CurrentVariables.TableOfCalculationsByTerms.Add();
	NewRow_Debt_Expense.RecordType                   = AccumulationRecordType.Expense;
	NewRow_Debt_Expense.DocumentRecorder           = CalculationLine_.Recorder;
	NewRow_Debt_Expense.Period                        = CalculationLine_.OffsetPeriod;
	NewRow_Debt_Expense.OperationProcedure               = CalculationLine_.OperationProcedure;
	
	NewRow_Debt_Expense.ARAPDocument             = RemainderLine_.ARAPDocument;
	NewRow_Debt_Expense.OccurrenceDate             = RemainderLine_.OccurrenceDate;
	NewRow_Debt_Expense.PlannedRepaymentDate        = RemainderLine_.PlannedRepaymentDate;
	NewRow_Debt_Expense.SettlementProcedure                 = RemainderLine_.SettlementProcedureByPaymentDate;
	
	NewRow_Debt_Expense.BusinessTransactionSetting = CalculationLine_.BusinessTransactionSetting;
	NewRow_Debt_Expense.FinRecordID         = CalculationLine_.FinRecordID;
	
	NewRow_Debt_Expense.BusinessOperation         = ?(BusinessOperation = Undefined, CalculationLine_.BusinessOperation, BusinessOperation);
	NewRow_Debt_Expense.SettlementTransaction        = CalculationLine_.SettlementTransaction;
	NewRow_Debt_Expense.DocumentCurrency               = CalculationLine_.DocumentCurrency;
	NewRow_Debt_Expense.CashFlowItem = CalculationLine_.CashFlowItem;
	NewRow_Debt_Expense.ReversingEntry                        = False;
	NewRow_Debt_Expense.LinkedDocument             = CalculationLine_.LinkedDocument;
	
	//Only the payment registrar is connected to the receiver
	NewRow_Debt_Expense.DestinationAccountingDimensionByPartners = CalculationLine_.DestinationAccountingDimensionByPartners;
	NewRow_Debt_Expense.CalculationObjectReceiver            = CalculationLine_.CalculationObjectReceiver;
	NewRow_Debt_Expense.CurrencyReceiver                    = CalculationLine_.CurrencyReceiver;
	NewRow_Debt_Expense.AmountReceiver                     = DebitedAmount(0, CalculationLine_.AmountReceiver, CalculationLine_.Sum, DebitedAmount);
	CalculationLine_.AmountReceiver = CalculationLine_.AmountReceiver - NewRow_Debt_Expense.AmountReceiver;
	NewRow_Debt_Expense.ByDataOfSourceARAPObject  = CalculationLine_.ByDataOfSourceARAPObject;
	NewRow_Debt_Expense.CorARAPObject                 = CalculationLine_.CorARAPObject;
	NewRow_Debt_Expense.CorPartnerAccountingDimension      = CalculationLine_.CorPartnerAccountingDimension;
	
	NewRow_Debt_Expense.Debt     = DebitedAmount;
	NewRow_Debt_Expense.DebtLocal = AmountOfLocalTaxDebited;
	NewRow_Debt_Expense.ARAPMan  = AmountOfManDebiting;
	NewRow_Debt_Expense.RecordingBeforeCalculationStarts = False;
	NewRow_Debt_Expense.Prepayment = 0;
	NewRow_Debt_Expense.PrepaymentLocal = 0;
	NewRow_Debt_Expense.PrepaymentMan = 0;
	
	AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, NewRow_Debt_Expense);
	
EndProcedure

Function AddPrepaymentExpense(CurrentVariables, RemainderLine_, CalculationLine_, DebitedAmount, AmountOfLocalTaxDebited, AmountOfManDebiting, FillInReceiversSources = True);
	
	NewRow_Prepayment_Expense                          = CurrentVariables.TableOfCalculationsByTerms.Add();
	NewRow_Prepayment_Expense.RecordType              = AccumulationRecordType.Expense;
	
	NewRow_Prepayment_Expense.DocumentRecorder      = CalculationLine_.Recorder;
	NewRow_Prepayment_Expense.DocumentCurrency          = CalculationLine_.DocumentCurrency;
	NewRow_Prepayment_Expense.Period                   = CalculationLine_.OffsetPeriod;
	NewRow_Prepayment_Expense.ARAPDocument        = RemainderLine_.ARAPDocument;
	NewRow_Prepayment_Expense.OccurrenceDate        = RemainderLine_.OccurrenceDate;
	NewRow_Prepayment_Expense.PlannedRepaymentDate   = RemainderLine_.PlannedRepaymentDate;
	NewRow_Prepayment_Expense.SettlementProcedure            = RemainderLine_.SettlementProcedureByPaymentDate;
	NewRow_Prepayment_Expense.OperationProcedure          = CalculationLine_.OperationProcedure;
	NewRow_Prepayment_Expense.CashFlowItem = CalculationLine_.CashFlowItem;
	
	If FillInReceiversSources  Then
		NewRow_Prepayment_Expense.DestinationAccountingDimensionByPartners = CalculationLine_.DestinationAccountingDimensionByPartners;
		NewRow_Prepayment_Expense.CalculationObjectReceiver  = CalculationLine_.CalculationObjectReceiver;
		NewRow_Prepayment_Expense.CurrencyReceiver  = CalculationLine_.CurrencyReceiver;
		NewRow_Prepayment_Expense.AmountReceiver = DebitedAmount(0, CalculationLine_.AmountReceiver, CalculationLine_.Sum, DebitedAmount);
		CalculationLine_.AmountReceiver = CalculationLine_.AmountReceiver - NewRow_Prepayment_Expense.AmountReceiver;
		
		NewRow_Prepayment_Expense.ByDataOfSourceARAPObject = CalculationLine_.ByDataOfSourceARAPObject;
		NewRow_Prepayment_Expense.CorARAPObject                = CalculationLine_.CorARAPObject;
		NewRow_Prepayment_Expense.CorPartnerAccountingDimension     = CalculationLine_.CorPartnerAccountingDimension;
		
	Else
		NewRow_Prepayment_Expense.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
		NewRow_Prepayment_Expense.CalculationObjectReceiver  = Catalogs.ARAPObjects.EmptyRef();
		NewRow_Prepayment_Expense.CurrencyReceiver  = Catalogs.Currencies.EmptyRef();
		NewRow_Prepayment_Expense.AmountReceiver = 0;
		
		NewRow_Prepayment_Expense.ByDataOfSourceARAPObject = False;
		NewRow_Prepayment_Expense.CorARAPObject                = Catalogs.ARAPObjects.EmptyRef();
		NewRow_Prepayment_Expense.CorPartnerAccountingDimension     = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
	EndIf;
	
	NewRow_Prepayment_Expense.ReversingEntry                   = False;
	NewRow_Prepayment_Expense.BusinessOperation    = CalculationLine_.BusinessOperation;
	NewRow_Prepayment_Expense.FinRecordID   = CalculationLine_.FinRecordID;
	NewRow_Prepayment_Expense.BusinessTransactionSetting = CalculationLine_.BusinessTransactionSetting;
	
	NewRow_Prepayment_Expense.Prepayment     = DebitedAmount;
	NewRow_Prepayment_Expense.PrepaymentLocal = AmountOfLocalTaxDebited;
	NewRow_Prepayment_Expense.PrepaymentMan  = AmountOfManDebiting;
	NewRow_Prepayment_Expense.RecordingBeforeCalculationStarts = False;
	NewRow_Prepayment_Expense.SettlementTransaction = CalculationLine_.SettlementTransaction;
	NewRow_Prepayment_Expense.Debt           = 0;
	NewRow_Prepayment_Expense.DebtLocal       = 0;
	NewRow_Prepayment_Expense.ARAPMan        = 0;
	
	AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, NewRow_Prepayment_Expense);
	
	Return NewRow_Prepayment_Expense;
EndFunction

//Adds entries to the revaluation of debt.
Procedure AddRevaluationRecord(CurrentVariables, Period, CalculationLine_, Type, SumCompl, SumMan)
	
	If Not CurrentVariables.NeedReassessment
		Or SumCompl = 0 And SumMan = 0 Then
		Return;
	EndIf;
	
	RevaluationProcedure = CurrentVariables.RevaluationProcedure.Get(Period);
	If RevaluationProcedure = Undefined Then
		RevaluationProcedure = Order(Period,"", Type("DocumentRef.ExchangeDifferenceCalculation"),"9","99");
		CurrentVariables.RevaluationProcedure.Insert(Period, RevaluationProcedure);
	EndIf;
	
	If Period < CurrentVariables.RecalculationStartDate Then
		Return;
	EndIf;
	
	If SumCompl < 0 Or SumMan < 0 Then
		RevaluationLine = CurrentVariables.TableOfCalculationsByTerms.Add();
		RevaluationLine.RecordType              = AccumulationRecordType.Expense;
		RevaluationLine.DocumentRecorder      = CurrentVariables.DocumentsForCalculatingExchangeDifferences[BegOfMonth(Period)];
		RevaluationLine.BusinessOperation    = CurrentVariables.BusinessTransactions["RevaluationNegative"];
		RevaluationLine.ARAPDocument        = CalculationLine_.ARAPDocument;
		RevaluationLine.OccurrenceDate        = CalculationLine_.OccurrenceDate;
		RevaluationLine.BusinessTransactionSetting = CurrentVariables.HOSettings["RevaluationNegative"];
		RevaluationLine.FinRecordID   = New UUID;
		RevaluationLine.SettlementProcedure            = RevaluationProcedure;
		RevaluationLine.Period                   = EndOfDay(Period);
		RevaluationLine.OperationProcedure          = RevaluationProcedure;
		RevaluationLine.CashFlowItem = Catalogs.CashFlowReportItems.EmptyRef();
		RevaluationLine.Debt = 0;
		RevaluationLine.Prepayment = 0;
		
		If Type = "Debt" Then
			RevaluationLine.DebtLocal             = ?(SumCompl < 0, -SumCompl, 0);
			RevaluationLine.ARAPMan              = ?(SumMan < 0, -SumMan, 0);
			RevaluationLine.PrepaymentLocal = 0;
			RevaluationLine.PrepaymentMan = 0;
			RevaluationLine.PlannedRepaymentDate   = CalculationLine_.PlannedRepaymentDate;
		Else
			RevaluationLine.PrepaymentLocal       = ?(SumCompl < 0, -SumCompl, 0);
			RevaluationLine.PrepaymentMan        = ?(SumMan < 0, -SumMan, 0);
			RevaluationLine.PlannedRepaymentDate   = Date(1,1,1);
			RevaluationLine.DebtLocal = 0;
			RevaluationLine.ARAPMan = 0;
		EndIf;
		RevaluationLine.RecordingBeforeCalculationStarts = False;
		RevaluationLine.SettlementTransaction = Enums.SettlementOperations.ARAPAdjustment;
		
		RevaluationLine.CorARAPObject            = Catalogs.ARAPObjects.EmptyRef();
		RevaluationLine.CorPartnerAccountingDimension = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
		RevaluationLine.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
		RevaluationLine.CalculationObjectReceiver            = Catalogs.ARAPObjects.EmptyRef();
		RevaluationLine.CurrencyReceiver            = Catalogs.Currencies.EmptyRef();
		RevaluationLine.AmountReceiver = 0;
		RevaluationLine.ByDataOfSourceARAPObject = False;
		RevaluationLine.ReversingEntry = False;
		
		AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, RevaluationLine, CalculationLine_.OperationProcedure);
	EndIf;
	
	If SumCompl > 0 Or SumMan > 0 Then
		RevaluationLine = CurrentVariables.TableOfCalculationsByTerms.Add();
		RevaluationLine.RecordType              = AccumulationRecordType.Receipt;
		RevaluationLine.DocumentRecorder      = CurrentVariables.DocumentsForCalculatingExchangeDifferences[BegOfMonth(Period)];
		RevaluationLine.BusinessOperation    = CurrentVariables.BusinessTransactions["RevaluationIsPositive"];
		RevaluationLine.ARAPDocument        = CalculationLine_.ARAPDocument;
		RevaluationLine.OccurrenceDate        = CalculationLine_.OccurrenceDate;
		RevaluationLine.BusinessTransactionSetting = CurrentVariables.HOSettings["RevaluationIsPositive"];
		RevaluationLine.FinRecordID   = New UUID;
		RevaluationLine.SettlementProcedure            = RevaluationProcedure;
		RevaluationLine.Period                   = EndOfDay(Period);
		RevaluationLine.OperationProcedure          = RevaluationProcedure;
		RevaluationLine.CashFlowItem = Catalogs.CashFlowReportItems.EmptyRef();
		RevaluationLine.Debt = 0;
		RevaluationLine.Prepayment = 0;
		
		If Type = "Debt" Then
			RevaluationLine.DebtLocal               = ?(SumCompl > 0, SumCompl, 0);
			RevaluationLine.ARAPMan                = ?(SumMan > 0, SumMan, 0);
			RevaluationLine.PrepaymentLocal = 0;
			RevaluationLine.PrepaymentMan = 0;
			RevaluationLine.PlannedRepaymentDate = CalculationLine_.PlannedRepaymentDate;
		Else
			RevaluationLine.PrepaymentLocal         = ?(SumCompl > 0, SumCompl, 0);
			RevaluationLine.PrepaymentMan          = ?(SumMan > 0, SumMan, 0);
			RevaluationLine.DebtLocal = 0;
			RevaluationLine.ARAPMan = 0;
			RevaluationLine.PlannedRepaymentDate   = Date(1,1,1);
		EndIf;
		RevaluationLine.RecordingBeforeCalculationStarts = False;
		RevaluationLine.SettlementTransaction = Enums.SettlementOperations.ARAPAdjustment;
		
		RevaluationLine.CorARAPObject            = Catalogs.ARAPObjects.EmptyRef();
		RevaluationLine.CorPartnerAccountingDimension = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
		RevaluationLine.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
		RevaluationLine.CalculationObjectReceiver            = Catalogs.ARAPObjects.EmptyRef();
		RevaluationLine.CurrencyReceiver            = Catalogs.Currencies.EmptyRef();
		RevaluationLine.AmountReceiver = 0;
		RevaluationLine.ByDataOfSourceARAPObject = False;
		RevaluationLine.ReversingEntry = False;
		
		AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, RevaluationLine, CalculationLine_.OperationProcedure, CalculationLine_.SettlementProcedureByPaymentDate);
	EndIf;
	
EndProcedure

// Add a Registered Record to the calculation Balance table.
// 
// Parameters:
//  TableOfBalancesOfSettlements - ValueTable - Table of Balances of Settlements
//  StringOfCalculationsByTime - ValueTableRow - A string of calculations by time, which must be added to the Balance.
//  OperationProcedure - Undefined, ValueTableRow - The order of the operation that will be assigned to the row of the Balance table. 
//  SettlementProcedureByPaymentDate - Undefined - The order of offsetting by payment date, which will be assigned to the row in the Balance table.
Procedure AddRegisteredRecordsToCalculationBalanceTable(TableOfBalancesOfSettlements, StringOfCalculationsByTime, OperationProcedure = Undefined, SettlementProcedureByPaymentDate = Undefined)
	
	If StringOfCalculationsByTime.RecordType = AccumulationRecordType.Expense Then
		Multiplier = -1;
	Else
		Multiplier = 1;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("ARAPDocument,OccurrenceDate,PlannedRepaymentDate");
	FillPropertyValues(TheStructureOfTheSearch,StringOfCalculationsByTime);
	RowsOfControlTable = TableOfBalancesOfSettlements.FindRows(TheStructureOfTheSearch);
	
	If RowsOfControlTable.Count() = 0 Then
		
		If StringOfCalculationsByTime.RecordType = AccumulationRecordType.Expense
			And OperationProcedure = Undefined Then
			Raise(NStr("ru = 'Не указана строка остатков для списания';
						|vi = 'The line of balance to write off is not specified';
						|en = 'The line of balance to write off is not specified'; fa = 'The line of balance to write off is not specified';
						|it = 'The line of balance to write off is not specified';
						|pl = 'The line of balance to write off is not specified';
						|tr = 'Gider yazılacak bakiye satırı belirtilmedi'", Common.DefaultLanguageCode()));
		EndIf;
		
		RowOfControlTable = TableOfBalancesOfSettlements.Add();
		RowOfControlTable.ARAPDocument = StringOfCalculationsByTime.ARAPDocument;
		RowOfControlTable.OccurrenceDate = StringOfCalculationsByTime.OccurrenceDate;
		RowOfControlTable.PlannedRepaymentDate = StringOfCalculationsByTime.PlannedRepaymentDate;
		RowOfControlTable.OperationProcedure = ?(OperationProcedure=Undefined, StringOfCalculationsByTime.OperationProcedure, OperationProcedure);
		RowOfControlTable.SettlementProcedureByPaymentDate = ?(SettlementProcedureByPaymentDate=Undefined, StringOfCalculationsByTime.SettlementProcedure, SettlementProcedureByPaymentDate);
		RowOfControlTable.RepaymentDateIsNotFilledIn = Not ValueIsFilled(RowOfControlTable.PlannedRepaymentDate);
		RowOfControlTable.DateOfRevaluation = BegOfDay(StringOfCalculationsByTime.Period);
		
		RowOfControlTable.Debt = StringOfCalculationsByTime.Debt * Multiplier;
		RowOfControlTable.DebtLocal = StringOfCalculationsByTime.DebtLocal * Multiplier;
		RowOfControlTable.ARAPMan = StringOfCalculationsByTime.ARAPMan * Multiplier;
		RowOfControlTable.Prepayment = StringOfCalculationsByTime.Prepayment * Multiplier;
		RowOfControlTable.PrepaymentLocal = StringOfCalculationsByTime.PrepaymentLocal * Multiplier;
		RowOfControlTable.PrepaymentMan = StringOfCalculationsByTime.PrepaymentMan * Multiplier;
	Else
		RowOfControlTable = RowsOfControlTable[0];
		RowOfControlTable.Debt = RowOfControlTable.Debt + StringOfCalculationsByTime.Debt * Multiplier;
		RowOfControlTable.DebtLocal = RowOfControlTable.DebtLocal + StringOfCalculationsByTime.DebtLocal * Multiplier;
		RowOfControlTable.ARAPMan = RowOfControlTable.ARAPMan + StringOfCalculationsByTime.ARAPMan * Multiplier;
		RowOfControlTable.Prepayment = RowOfControlTable.Prepayment + StringOfCalculationsByTime.Prepayment * Multiplier;
		RowOfControlTable.PrepaymentLocal = RowOfControlTable.PrepaymentLocal + StringOfCalculationsByTime.PrepaymentLocal * Multiplier;
		RowOfControlTable.PrepaymentMan = RowOfControlTable.PrepaymentMan + StringOfCalculationsByTime.PrepaymentMan * Multiplier;
	EndIf;
	
EndProcedure

#EndRegion

//Recalculates the amount of regl. and UPR. accounting for the calculation line at the exchange rate of the linked document, if it is held.
Procedure RecalculateAmountsIfThisIsAdjustment(GlobalVariables, CurrentVariables, CalculationLine_, SourceType = "")
	
	InvoicesData = CurrentVariables.InvoicesData;
	
	If InvoicesData[CalculationLine_.LinkedDocument] <> Undefined
			And InvoicesData[CalculationLine_.LinkedDocument].DocumentAmount <> 0 Then
		
		If CurrentVariables.LocalAccountingCurrency <> CalculationLine_.DocumentCurrency
				And CurrentVariables.LocalAccountingCurrency <> CurrentVariables.Currency Then
			CalculationLine_.SumCompl = Round(CalculationLine_.Sum *
				(InvoicesData[CalculationLine_.LinkedDocument].TheAmountOfTheDocumentRegl
					/ InvoicesData[CalculationLine_.LinkedDocument].DocumentAmount),2);
		EndIf;
		If GlobalVariables.ManagementAccountingCurrency <> CalculationLine_.DocumentCurrency
				And GlobalVariables.ManagementAccountingCurrency <> CurrentVariables.Currency Then
			CalculationLine_.SumMan = Round(CalculationLine_.Sum *
				(InvoicesData[CalculationLine_.LinkedDocument].DocumentAmountManag
					/ InvoicesData[CalculationLine_.LinkedDocument].DocumentAmount),2);
		EndIf;
		
		If SourceType = "ShipmentDelivery" Then
			
			CalculationLine_.InitialAmountOfLocal = Round(CalculationLine_.InitialAmount_
				* (InvoicesData[CalculationLine_.LinkedDocument].TheAmountOfTheDocumentRegl
					/ InvoicesData[CalculationLine_.LinkedDocument].DocumentAmount),2);
			CalculationLine_.InitialAmountOfMan = Round(CalculationLine_.InitialAmount_
				* (InvoicesData[CalculationLine_.LinkedDocument].DocumentAmountManag
					/ InvoicesData[CalculationLine_.LinkedDocument].DocumentAmount),2);
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the amount of Local and Man. accounting lines of payment or shipment/delivery before adding incoming
// Registered Recorded at the rate of the saved amounts of expenditure Registered Recorded schedule adjustments.
Procedure FillInScheduleAdjustmentData(CurrentVariables, Recorder, DataForDistribution, ThisIsPayment)
	
	AdjustmentDataOfChart = CurrentVariables.ChartAdjustmentData[Recorder];
	// Undefined is possible if the accrual and write-off adjustment entries were already added earlier before the recalculation began
	If AdjustmentDataOfChart <> Undefined
		And AdjustmentDataOfChart.SumExpense >= 0 Then
		CalculationRows = DataForDistribution.FindRows(New Structure("Recorder",Recorder));
		// The amount for the arrival must be distributed starting from later repayment dates 
		IndexOf = CalculationRows.Count();
		While IndexOf > 0 Do
			
			IndexOf = IndexOf - 1;
			CalculationLine_ = CalculationRows[IndexOf];
			
			If CalculationLine_.Sum = 0
				Or CalculationLine_.ThisIsPayment <> ThisIsPayment Then
				Continue;
			EndIf;
			
			Sum = Min(AdjustmentDataOfChart.SumExpense, CalculationLine_.Sum);
			
			If CalculationLine_.Sum = Sum Then
				CalculationLine_.SumCompl = DebitedAmount(0, AdjustmentDataOfChart.LocalExpenseAmount, AdjustmentDataOfChart.SumExpense, Sum);
				CalculationLine_.SumMan  = DebitedAmount(0, AdjustmentDataOfChart.AmountOfManSExpense,  AdjustmentDataOfChart.SumExpense, Sum);
				CalculationLine_.OccurrenceDate = AdjustmentDataOfChart.OccurrenceDate;
			Else
				CalculationLine_.Sum = AdjustmentDataOfChart.SumExpense;
				CalculationLine_.SumCompl = AdjustmentDataOfChart.LocalExpenseAmount;
				CalculationLine_.SumMan = AdjustmentDataOfChart.AmountOfManSExpense;
				CalculationLine_.OccurrenceDate = AdjustmentDataOfChart.OccurrenceDate;
			EndIf;
			
			AdjustmentDataOfChart.SumExpense     = AdjustmentDataOfChart.SumExpense     - CalculationLine_.Sum;
			AdjustmentDataOfChart.LocalExpenseAmount = AdjustmentDataOfChart.LocalExpenseAmount - CalculationLine_.SumCompl;
			AdjustmentDataOfChart.AmountOfManSExpense  = AdjustmentDataOfChart.AmountOfManSExpense  - CalculationLine_.SumMan;
			
		EndDo;
		// All lines for incoming movements have been reduced, no more need to enter the cycle to reduce the amount
		If AdjustmentDataOfChart.SumExpense = 0 Then
			CurrentVariables.ChartAdjustmentData[Recorder] = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

#Region RegisteredRecordsOfPlans

// Closing the order payment schedule by actual shipment. Changes the Balance line.
// Parameters:
//  Current Refineries - Structure
//  RemainderLine - ValueTableRow - the Balance line of the plan for the order.
//  Calculation string - Value table string - calculation string that closes the Balance.
//  DebitedAmount - Number
Procedure ReducePaymentPlanForOrder(TableOfRegisteredRecordsOfScheduledPayments, RemainderLine, StringClarifications, DebitedAmount, DateOfUnallocatedAdvance = Undefined)
	
	If DebitedAmount = 0 Then
		Return;
	EndIf;
	
	StringClarifications.Sum = StringClarifications.Sum - DebitedAmount;
	
	If BegOfDay(StringClarifications.DateOfMovement) < RemainderLine.OccurrenceDate Then
		DocumentRecorder = RemainderLine.DocumentPlan;
		OperationProcedure = "";
		Period = RemainderLine.OccurrenceDate;
	Else
		DocumentRecorder = StringClarifications.Recorder;
		OperationProcedure = StringClarifications.OperationProcedure;
		Period = StringClarifications.DateOfMovement;
	EndIf;
	
	NwRw = TableOfRegisteredRecordsOfScheduledPayments.Add();
	NwRw.RecordType               = AccumulationRecordType.Expense;
	NwRw.DocumentRecorder       = DocumentRecorder;
	NwRw.OperationProcedure           = OperationProcedure;
	NwRw.DocumentPayments            = StringClarifications.Recorder;
	
	NwRw.DocumentPlan              = RemainderLine.DocumentPlan;
	NwRw.PaymentOption             = RemainderLine.PaymentOption;
	NwRw.OccurrenceDate         = RemainderLine.OccurrenceDate;
	NwRw.PlannedRepaymentDate    = RemainderLine.PlannedRepaymentDate;
	
	// Closing the payment schedule by actual shipment
	If DateOfUnallocatedAdvance = Undefined Then
		NwRw.Period                    = Period;
		NwRw.UnallocatedAdvancePayment     = False;
		NwRw.AmountDue                   = DebitedAmount;
		
		RemainderLine.AmountDue = RemainderLine.AmountDue - DebitedAmount;
		
		// If there are unallocated Balances on this line, we cancel them.
		If RemainderLine.AmountDueIsUndistributedAdvance < 0 Then
			AmountOfCancellation = Max(-DebitedAmount, RemainderLine.AmountDueIsUndistributedAdvance);
			ToCancelUnallocatedAdvance(TableOfRegisteredRecordsOfScheduledPayments, RemainderLine, StringClarifications, AmountOfCancellation);
			DebitedAmount = DebitedAmount + AmountOfCancellation;
		EndIf;
	// Pre-closing of the payment schedule with actual payment
	Else
		NwRw.Period                    = DateOfUnallocatedAdvance;
		NwRw.UnallocatedAdvancePayment     = True;
		NwRw.AmountDue                   = DebitedAmount;
		
		RemainderLine.AmountDueIsUndistributedAdvance = RemainderLine.AmountDueIsUndistributedAdvance - DebitedAmount;
		RemainderLine.ThereIsUndistributedAdvanceAmountDue = RemainderLine.AmountDueIsUndistributedAdvance < 0;
	EndIf;
	
EndProcedure

// Parameters:
//  TableOfRegisteredRecordsOfScheduledPayments - ValueTable
//  RemainderLine - ValueTableRow
//  StringClarifications - ValueTableRow
//  DebitedAmount - Number
//  DateOfUnallocatedAdvance - Date - It is transmitted if the record of the unallocated advance is canceled by another unallocated advance.
Procedure ToCancelUnallocatedAdvance(TableOfRegisteredRecordsOfScheduledPayments, RemainderLine, StringClarifications, DebitedAmount, DateOfUnallocatedAdvance = Undefined)
	
	If DebitedAmount = 0 Then
		Return;
	EndIf;
	
	// If you first completed the clarification document, and then the order.
	If BegOfDay(StringClarifications.DateOfMovement) < RemainderLine.OccurrenceDate Then
		DocumentRecorder = RemainderLine.DocumentPlan;
		OperationProcedure = RemainderLine.OperationProcedure;
		Period = RemainderLine.OccurrenceDate;
	Else
		DocumentRecorder = StringClarifications.Recorder;
		OperationProcedure = StringClarifications.OperationProcedure;
		Period = StringClarifications.DateOfMovement;
	EndIf;
	
	NwRw = TableOfRegisteredRecordsOfScheduledPayments.Add();
	NwRw.RecordType               = AccumulationRecordType.Expense;
	NwRw.DocumentRecorder       = DocumentRecorder;
	NwRw.DocumentPlan              = RemainderLine.DocumentPlan;
	NwRw.PaymentOption             = RemainderLine.PaymentOption;
	NwRw.Period                    = ?(DateOfUnallocatedAdvance = Undefined, Period, DateOfUnallocatedAdvance);
	NwRw.OperationProcedure           = OperationProcedure;
	NwRw.OccurrenceDate         = RemainderLine.OccurrenceDate;
	NwRw.PlannedRepaymentDate    = RemainderLine.PlannedRepaymentDate;
	NwRw.UnallocatedAdvancePayment     = True;
	NwRw.DocumentPayments            = StringClarifications.Recorder;
	NwRw.AmountDue                   = DebitedAmount;
	
	RemainderLine.AmountDueIsUndistributedAdvance = RemainderLine.AmountDueIsUndistributedAdvance - DebitedAmount;
	
EndProcedure

// Parameters:
//  TableOfRegisteredRecordsOfPlannedShipments - ValueTable
//  RemainderLine - ValueTableRow
//  StringClarifications - ValueTableRow
//  DebitedAmount - Number
//  DateOfUnallocatedAdvance - Date
Procedure ReduceOrderShipmentPlan(TableOfRegisteredRecordsOfPlannedShipments, RemainderLine, StringClarifications, DebitedAmount, DateOfUnallocatedAdvance = Undefined)
	
	If DebitedAmount = 0 Then
		Return;
	EndIf;
	
	StringClarifications.Sum = StringClarifications.Sum - DebitedAmount;
	
	If BegOfDay(StringClarifications.DateOfMovement) < RemainderLine.OccurrenceDate Then
		DocumentRecorder = RemainderLine.DocumentPlan;
		OperationProcedure = "";
		Period = RemainderLine.OccurrenceDate;
	Else
		DocumentRecorder = StringClarifications.Recorder;
		OperationProcedure = StringClarifications.OperationProcedure;
		Period = StringClarifications.DateOfMovement;
	EndIf;
	
	NwRw = TableOfRegisteredRecordsOfPlannedShipments.Add();
	NwRw.RecordType               = AccumulationRecordType.Expense;
	NwRw.DocumentRecorder       = DocumentRecorder;
	NwRw.OperationProcedure           = OperationProcedure;
	NwRw.DocumentPayments            = StringClarifications.Recorder;
	
	NwRw.DocumentPlan              = RemainderLine.DocumentPlan;
	NwRw.OccurrenceDate         = RemainderLine.OccurrenceDate;
	NwRw.PlannedRepaymentDate    = RemainderLine.PlannedRepaymentDate;
	
	NwRw.Sum                     = DebitedAmount;
	
	NwRw.IncludedInBalanceOfPlannedShipments = False;
	If DateOfUnallocatedAdvance = Undefined Then
		NwRw.Period                    = Period;
		NwRw.UnallocatedAdvancePayment     = False;
		
		RemainderLine.Sum = RemainderLine.Sum - DebitedAmount;
		
		// If there are unallocated Balances on this line, we cancel them.
		If RemainderLine.AmountOfUndistributedAdvance < 0 Then
			AmountOfCancellation = Max(-DebitedAmount, RemainderLine.AmountOfUndistributedAdvance);;
			ToCancelUnallocatedAdvanceOfShipmentPlan(TableOfRegisteredRecordsOfPlannedShipments, RemainderLine, StringClarifications, AmountOfCancellation);
			DebitedAmount = DebitedAmount + AmountOfCancellation;
		EndIf;
		
	Else
		NwRw.Period                    = DateOfUnallocatedAdvance;
		NwRw.UnallocatedAdvancePayment     = True;
		RemainderLine.AmountOfUndistributedAdvance = RemainderLine.AmountOfUndistributedAdvance - DebitedAmount;
		RemainderLine.ThereIsAmountOfUndistributedAdvance = RemainderLine.AmountOfUndistributedAdvance < 0;
	EndIf;
	
EndProcedure

// Parameters:
//  TableOfRegisteredRecordsOfPlannedShipments - ValueTable
//  RemainderLine - ValueTableRow
//  StringClarifications - ValueTableRow
//  DebitedAmount - Number
//  DateOfUnallocatedAdvance - Date
Procedure ToCancelUnallocatedAdvanceOfShipmentPlan(TableOfRegisteredRecordsOfPlannedShipments, RemainderLine, StringClarifications, DebitedAmount, DateOfUnallocatedAdvance = Undefined)
	
	If DebitedAmount = 0 Then
		Return;
	EndIf;
	
	// If you first completed the clarification document, and then the order.
	If BegOfDay(StringClarifications.DateOfMovement) < RemainderLine.OccurrenceDate Then
		DocumentRecorder = RemainderLine.DocumentPlan;
		OperationProcedure = RemainderLine.OperationProcedure;
		Period = RemainderLine.OccurrenceDate;
	Else
		DocumentRecorder = StringClarifications.Recorder;
		OperationProcedure = StringClarifications.OperationProcedure;
		Period = StringClarifications.DateOfMovement;
	EndIf;
	
	NwRw = TableOfRegisteredRecordsOfPlannedShipments.Add();
	NwRw.RecordType               = AccumulationRecordType.Expense;
	NwRw.DocumentRecorder       = DocumentRecorder;
	NwRw.DocumentPlan              = RemainderLine.DocumentPlan;
	NwRw.Period                    = ?(DateOfUnallocatedAdvance = Undefined, Period, DateOfUnallocatedAdvance);
	NwRw.OperationProcedure           = OperationProcedure;
	NwRw.OccurrenceDate         = RemainderLine.OccurrenceDate;
	NwRw.PlannedRepaymentDate    = RemainderLine.PlannedRepaymentDate;
	NwRw.UnallocatedAdvancePayment     = True;
	NwRw.DocumentPayments            = StringClarifications.Recorder;
	NwRw.Sum                     = DebitedAmount;
	NwRw.IncludedInBalanceOfPlannedShipments = False;
	
	RemainderLine.AmountOfUndistributedAdvance = RemainderLine.AmountOfUndistributedAdvance - DebitedAmount;
	RemainderLine.ThereIsAmountOfUndistributedAdvance = RemainderLine.AmountOfUndistributedAdvance < 0;
	
EndProcedure

#EndRegion

#Region ReversingEntry

Procedure AddNegativeRegisteredRecordStorno(CurrentVariables, StringOfOriginalRecorder, SourceDocumentRegisteredRecord)
	
	StringIsStorno = CurrentVariables.TableOfCalculationsByTerms.Add();
	
	StringIsStorno.RecordType = SourceDocumentRegisteredRecord.RecordType;
	
	StringIsStorno.ARAPDocument = SourceDocumentRegisteredRecord.ARAPDocument;
	StringIsStorno.PlannedRepaymentDate = SourceDocumentRegisteredRecord.PlannedRepaymentDate;
	StringIsStorno.OccurrenceDate = SourceDocumentRegisteredRecord.OccurrenceDate;
	
	StringIsStorno.DocumentRecorder = StringOfOriginalRecorder.NewRegistrar;
	StringIsStorno.Period              = StringOfOriginalRecorder.NewPeriod;
	StringIsStorno.OperationProcedure     = StringOfOriginalRecorder.NewOrderOfOperation;
	StringIsStorno.SettlementProcedure       = StringOfOriginalRecorder.NewOrderOfOperation;
	
	StringIsStorno.BusinessOperation       = SourceDocumentRegisteredRecord.BusinessOperation;
	StringIsStorno.BusinessTransactionSetting  = SourceDocumentRegisteredRecord.BusinessTransactionSetting;
	StringIsStorno.FinRecordID        = SourceDocumentRegisteredRecord.FinRecordID;
	StringIsStorno.DocumentCurrency               = SourceDocumentRegisteredRecord.DocumentCurrency;
	StringIsStorno.CashFlowItem = SourceDocumentRegisteredRecord.CashFlowItem;
	
	StringIsStorno.Debt           = -SourceDocumentRegisteredRecord.Debt;
	StringIsStorno.DebtLocal       = -SourceDocumentRegisteredRecord.DebtLocal;
	StringIsStorno.ARAPMan        = -SourceDocumentRegisteredRecord.ARAPMan;
	StringIsStorno.Prepayment     = -SourceDocumentRegisteredRecord.Prepayment;
	StringIsStorno.PrepaymentLocal = -SourceDocumentRegisteredRecord.PrepaymentLocal;
	StringIsStorno.PrepaymentMan  = -SourceDocumentRegisteredRecord.PrepaymentMan;
	StringIsStorno.ReversingEntry = True;
	
	StringIsStorno.RecordingBeforeCalculationStarts = False;
	// If the Registered Records of the original document after the start of the calculations, then the type of record has not yet been filled in - we determine of operation of mutual settlements
	StringIsStorno.SettlementTransaction = SourceDocumentRegisteredRecord.SettlementTransaction;
	// If the source document is Registered Recorded before the start of calculations, then we immediately take its record type 
	StringIsStorno.SettlementRecordType = SourceDocumentRegisteredRecord.SettlementRecordType;
	
	StringIsStorno.CorPartnerAccountingDimension = SourceDocumentRegisteredRecord.CorPartnerAccountingDimension;
	StringIsStorno.CorARAPObject = SourceDocumentRegisteredRecord.CorARAPObject;
	StringIsStorno.DestinationAccountingDimensionByPartners = SourceDocumentRegisteredRecord.DestinationAccountingDimensionByPartners;
	StringIsStorno.CalculationObjectReceiver = SourceDocumentRegisteredRecord.CalculationObjectReceiver;
	StringIsStorno.CurrencyReceiver = SourceDocumentRegisteredRecord.CurrencyReceiver;
	StringIsStorno.AmountReceiver = SourceDocumentRegisteredRecord.AmountReceiver;
	StringIsStorno.ByDataOfSourceARAPObject = SourceDocumentRegisteredRecord.ByDataOfSourceARAPObject;
	
	AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements, StringIsStorno, SourceDocumentRegisteredRecord.OperationProcedure, SourceDocumentRegisteredRecord.SettlementProcedure);
	
EndProcedure

Procedure AddRepairRegisterRecordedOnMinusBalance(GlobalVariables, CurrentVariables, ControlString, RecorderSCalculationString)
	
	CorrectingNegativeDebt = ControlString.Debt < 0;
	
	If CorrectingNegativeDebt Then
		Resource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Debt.Name;
		LocalResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.DebtLocal.Name;
		ManResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.ARAPMan.Name;
		OppositeResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Prepayment.Name;
		OppositeResourceIsLocal = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentLocal.Name;
		OppositeResourceIsMan = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentMan.Name;
	Else
		Resource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Prepayment.Name;
		LocalResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentLocal.Name;
		ManResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentMan.Name;
		OppositeResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Debt.Name;
		OppositeResourceIsLocal = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.DebtLocal.Name;
		OppositeResourceIsMan = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.ARAPMan.Name;
	EndIf;
	
	AmountOfRepair = -ControlString[Resource];
	AmountOfRepairLocal = -ControlString[LocalResource];
	AmountOfRepairMan = -ControlString[ManResource];
	While AmountOfRepair > 0 Do
		DebitedAmount = Undefined;
		
		//We close the minus to another minus in the opposite resource
		For Each RemainderLine_ In CurrentVariables.TableOfBalancesOfSettlements Do
			If RemainderLine_[OppositeResource] < 0 And RecorderSCalculationString.Period >= RemainderLine_.OccurrenceDate Then
				
				BusinessOperation = Enums.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno;
				BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.RestoreDebtPrepaymentUponARAPAccountingStorno;
				
				DebitedAmount = Min(-RemainderLine_[OppositeResource],AmountOfRepair);
				AmountOfLocalTaxDebited = DebitedAmount(0,AmountOfRepairLocal,AmountOfRepair,DebitedAmount);
				AmountOfManDebiting = DebitedAmount(0,AmountOfRepairMan,AmountOfRepair,DebitedAmount);
				
				#Region AssociatedIncomingRepairRegisteredRecorded
				NwRw_Receipt = CurrentVariables.TableOfCalculationsByTerms.Add();
				NwRw_Receipt.RecordType = AccumulationRecordType.Receipt;
				
				NwRw_Receipt.ARAPDocument = RemainderLine_.ARAPDocument;
				NwRw_Receipt.PlannedRepaymentDate = RemainderLine_.PlannedRepaymentDate;
				NwRw_Receipt.OccurrenceDate = RemainderLine_.OccurrenceDate;
				
				NwRw_Receipt.DocumentRecorder = RecorderSCalculationString.Recorder;
				NwRw_Receipt.Period              = RecorderSCalculationString.Period;
				NwRw_Receipt.OperationProcedure     = RecorderSCalculationString.OperationProcedure;
				NwRw_Receipt.SettlementProcedure       = RecorderSCalculationString.OperationProcedure;
				NwRw_Receipt.FinRecordID  = RecorderSCalculationString.RecordersID;
				NwRw_Receipt.DocumentCurrency               = RecorderSCalculationString.DocumentCurrency;
				NwRw_Receipt.CashFlowItem = Undefined;
				
				NwRw_Receipt.BusinessOperation           = BusinessOperation;
				NwRw_Receipt.BusinessTransactionSetting  = BusinessTransactionSetting;
				
				NwRw_Receipt[Resource]        = 0;
				NwRw_Receipt[LocalResource]    = 0;
				NwRw_Receipt[ManResource]     = 0;
				NwRw_Receipt[OppositeResource]        = DebitedAmount;
				NwRw_Receipt[OppositeResourceIsLocal]    = AmountOfLocalTaxDebited;
				NwRw_Receipt[OppositeResourceIsMan]     = AmountOfManDebiting;
				
				NwRw_Receipt.ReversingEntry = False;
				
				NwRw_Receipt.RecordingBeforeCalculationStarts = False;
				NwRw_Receipt.SettlementTransaction = Enums.SettlementOperations.ARAPAdjustment;
				
				NwRw_Receipt.CorPartnerAccountingDimension = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
				NwRw_Receipt.CorARAPObject = Catalogs.ARAPObjects.EmptyRef();
				NwRw_Receipt.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
				NwRw_Receipt.CalculationObjectReceiver = Catalogs.ARAPObjects.EmptyRef();
				NwRw_Receipt.CurrencyReceiver = Catalogs.Currencies.EmptyRef();
				NwRw_Receipt.AmountReceiver = 0;
				NwRw_Receipt.ByDataOfSourceARAPObject = False;
				
				AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements,NwRw_Receipt);
				
				#EndRegion
				
				Break;
			EndIf;
		EndDo;
		
		//We close the minus to the plus in the same resource
		If DebitedAmount = Undefined Then
			For Each RemainderLine_ In CurrentVariables.TableOfBalancesOfSettlements Do
				If RemainderLine_[Resource] > 0 And RecorderSCalculationString.Period >= RemainderLine_.OccurrenceDate Then
					
					If Resource = "Debt" Then
						BusinessOperation           = Enums.BusinessTransactions.DebtOffsetUponARAPAccountingStorno;
						BusinessTransactionSetting  = Catalogs.BusinessTransactionsSettings.DebtOffsetUponARAPAccountingStorno;
					Else
						BusinessOperation           = Enums.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno;
						BusinessTransactionSetting  = Catalogs.BusinessTransactionsSettings.PrepaymentOffsetUponARAPAccountingStorno;
					EndIf;
					
					DebitedAmount = Min(RemainderLine_[Resource],AmountOfRepair);
					AmountOfLocalTaxDebited = DebitedAmount(0,AmountOfRepairLocal,AmountOfRepair,DebitedAmount);
					AmountOfManDebiting = DebitedAmount(0,AmountOfRepairMan,AmountOfRepair,DebitedAmount);
					
					#Region RelatedConsumableMendingRegisteredRecorded
					NwRw_Expense = CurrentVariables.TableOfCalculationsByTerms.Add();
					NwRw_Expense.RecordType = AccumulationRecordType.Expense;
					
					NwRw_Expense.ARAPDocument = RemainderLine_.ARAPDocument;
					NwRw_Expense.PlannedRepaymentDate = RemainderLine_.PlannedRepaymentDate;
					NwRw_Expense.OccurrenceDate = RemainderLine_.OccurrenceDate;
					
					NwRw_Expense.DocumentRecorder = RecorderSCalculationString.Recorder;
					NwRw_Expense.Period              = RecorderSCalculationString.Period;
					NwRw_Expense.OperationProcedure     = RecorderSCalculationString.OperationProcedure;
					NwRw_Expense.SettlementProcedure       = RecorderSCalculationString.OperationProcedure;
					NwRw_Expense.FinRecordID  = RecorderSCalculationString.RecordersID;
					NwRw_Expense.DocumentCurrency               = RecorderSCalculationString.DocumentCurrency;
					NwRw_Expense.CashFlowItem = RecorderSCalculationString.CashFlowItem;
					
					NwRw_Expense.BusinessOperation           = BusinessOperation;
					NwRw_Expense.BusinessTransactionSetting  = BusinessTransactionSetting;
					
					NwRw_Expense[Resource]        = DebitedAmount;
					NwRw_Expense[LocalResource]    = AmountOfLocalTaxDebited;
					NwRw_Expense[ManResource]     = AmountOfManDebiting;
					NwRw_Expense[OppositeResource]        = 0;
					NwRw_Expense[OppositeResourceIsLocal]    = 0;
					NwRw_Expense[OppositeResourceIsMan]     = 0;
					
					NwRw_Expense.ReversingEntry = False;
					
					NwRw_Expense.RecordingBeforeCalculationStarts = False;
					NwRw_Expense.SettlementTransaction = Enums.SettlementOperations.ARAPAdjustment;
					
					NwRw_Expense.CorPartnerAccountingDimension = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
					NwRw_Expense.CorARAPObject = Catalogs.ARAPObjects.EmptyRef();
					NwRw_Expense.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
					NwRw_Expense.CalculationObjectReceiver = Catalogs.ARAPObjects.EmptyRef();
					NwRw_Expense.CurrencyReceiver = Catalogs.Currencies.EmptyRef();
					NwRw_Expense.AmountReceiver = 0;
					NwRw_Expense.ByDataOfSourceARAPObject = False;
					
					AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements,NwRw_Expense );
					
					If Resource = "Debt" Then
						ReassessDebt(GlobalVariables, CurrentVariables, RemainderLine_.ARAPDocument, RecorderSCalculationString.Period, True);
					EndIf;
					
					#EndRegion
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		// If it was not possible to find the Balance to reduce, we add the parish.
		If DebitedAmount = Undefined Then
			
			BusinessOperation           = Enums.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno;
			BusinessTransactionSetting  = Catalogs.BusinessTransactionsSettings.RestoreDebtPrepaymentUponARAPAccountingStorno;
			
			DebitedAmount = AmountOfRepair;
			AmountOfLocalTaxDebited = AmountOfRepairLocal;
			AmountOfManDebiting = AmountOfRepairMan;
			
			#Region AssociatedIncomingRepairRegisteredRecorded
			NwRw_Receipt = CurrentVariables.TableOfCalculationsByTerms.Add();
			NwRw_Receipt.RecordType = AccumulationRecordType.Receipt;
			
			NwRw_Receipt.ARAPDocument = RecorderSCalculationString.ARAPDocument;
			NwRw_Receipt.PlannedRepaymentDate = RecorderSCalculationString.PlannedRepaymentDate;
			NwRw_Receipt.OccurrenceDate = RecorderSCalculationString.OccurrenceDate;
			
			NwRw_Receipt.DocumentRecorder = RecorderSCalculationString.Recorder;
			NwRw_Receipt.Period              = RecorderSCalculationString.Period;
			NwRw_Receipt.OperationProcedure     = RecorderSCalculationString.OperationProcedure;
			NwRw_Receipt.SettlementProcedure       = RecorderSCalculationString.OperationProcedure;
			NwRw_Receipt.FinRecordID  = RecorderSCalculationString.RecordersID;
			NwRw_Receipt.DocumentCurrency               = RecorderSCalculationString.DocumentCurrency;
			NwRw_Receipt.CashFlowItem = RecorderSCalculationString.CashFlowItem;
			
			NwRw_Receipt.BusinessOperation           = BusinessOperation;
			NwRw_Receipt.BusinessTransactionSetting  = BusinessTransactionSetting;
			
			NwRw_Receipt[OppositeResource]        = DebitedAmount;
			NwRw_Receipt[OppositeResourceIsLocal]    = AmountOfLocalTaxDebited;
			NwRw_Receipt[OppositeResourceIsMan]     = AmountOfManDebiting;
			NwRw_Receipt[Resource]        = 0;
			NwRw_Receipt[LocalResource]    = 0;
			NwRw_Receipt[ManResource]     = 0;
			
			NwRw_Receipt.ReversingEntry = False;
			
			NwRw_Receipt.RecordingBeforeCalculationStarts = False;
			NwRw_Receipt.SettlementTransaction = Enums.SettlementOperations.ARAPAdjustment;
			
			NwRw_Receipt.CorPartnerAccountingDimension = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
			NwRw_Receipt.CorARAPObject = Catalogs.ARAPObjects.EmptyRef();
			NwRw_Receipt.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
			NwRw_Receipt.CalculationObjectReceiver = Catalogs.ARAPObjects.EmptyRef();
			NwRw_Receipt.CurrencyReceiver = Catalogs.Currencies.EmptyRef();
			NwRw_Receipt.AmountReceiver = 0;
			NwRw_Receipt.ByDataOfSourceARAPObject = False;
			
			AddRegisteredRecordsToCalculationBalanceTable(CurrentVariables.TableOfBalancesOfSettlements,NwRw_Receipt);
			
			#EndRegion
			
		EndIf;
	
		#Region AddingRegisteredRecordToCloseMinusSign
	
		RepairRow = CurrentVariables.TableOfCalculationsByTerms.Add();
		
		RepairRow.RecordType = AccumulationRecordType.Receipt;
		
		RepairRow.ARAPDocument = ControlString.ARAPDocument;
		RepairRow.PlannedRepaymentDate = ControlString.PlannedRepaymentDate;
		RepairRow.OccurrenceDate = ControlString.OccurrenceDate;
		
		RepairRow.DocumentRecorder = RecorderSCalculationString.Recorder;
		RepairRow.Period              = RecorderSCalculationString.Period;
		RepairRow.OperationProcedure     = RecorderSCalculationString.OperationProcedure;
		RepairRow.SettlementProcedure       = RecorderSCalculationString.OperationProcedure;
		RepairRow.FinRecordID  = RecorderSCalculationString.RecordersID;
		RepairRow.DocumentCurrency               = RecorderSCalculationString.DocumentCurrency;
		RepairRow.CashFlowItem = RecorderSCalculationString.CashFlowItem;
		
		RepairRow.BusinessOperation           = BusinessOperation;
		RepairRow.BusinessTransactionSetting  = BusinessTransactionSetting;
		RepairRow.SettlementTransaction = Enums.SettlementOperations.ARAPAdjustment;
		
		RepairRow[Resource]         = DebitedAmount;
		RepairRow[LocalResource]     = AmountOfLocalTaxDebited;
		RepairRow[ManResource]      = AmountOfManDebiting;
		RepairRow[OppositeResource]        = 0;
		RepairRow[OppositeResourceIsLocal]    = 0;
		RepairRow[OppositeResourceIsMan]     = 0;
		
		RepairRow.ReversingEntry = False;
		
		RepairRow.RecordingBeforeCalculationStarts = False;
		
		RepairRow.CorPartnerAccountingDimension = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
		RepairRow.CorARAPObject = Catalogs.ARAPObjects.EmptyRef();
		RepairRow.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
		RepairRow.CalculationObjectReceiver = Catalogs.ARAPObjects.EmptyRef();
		RepairRow.CurrencyReceiver = Catalogs.Currencies.EmptyRef();
		RepairRow.AmountReceiver = 0;
		RepairRow.ByDataOfSourceARAPObject = False;
		
		// Instead of adding control and folding to the table 
		ControlString.Debt = 0;
		ControlString.DebtLocal = 0;
		ControlString.ARAPMan = 0;
		ControlString.Prepayment = 0;
		ControlString.PrepaymentLocal = 0;
		ControlString.PrepaymentMan = 0;
		
		If Resource = "Debt" Then
			ReassessDebt(GlobalVariables, CurrentVariables, ControlString.ARAPDocument, RecorderSCalculationString.Period, True);
		EndIf;
		
		#EndRegion
		
		AmountOfRepair = AmountOfRepair - DebitedAmount;
		AmountOfRepairLocal = AmountOfRepairLocal - AmountOfLocalTaxDebited;
		AmountOfRepairMan = AmountOfRepairMan - AmountOfManDebiting;
	EndDo;
	
EndProcedure

Procedure AddRepairRegisterRecordedOnExpandedBalance(GlobalVariables, CurrentVariables, AmountToCollapse, RecorderSCalculationString)
	
	AmountOfDebtWriteOff = AmountToCollapse;
	AmountOfPrepaymentDebited = AmountToCollapse;
	// We write it off at the prepayment rate
	PrepaymentAmountLocal = 0;
	ManSPrepaymentAmount = 0;
	
	For Each RemainderLine_ In CurrentVariables.TableOfBalancesOfSettlements Do
		If AmountOfPrepaymentDebited = 0 Then
			Break;
		EndIf;
		If RemainderLine_.Prepayment = 0 Then
			Continue;
		EndIf;
		
		AddRepairRegisterRecordedOfUnfoldedBalance(GlobalVariables, CurrentVariables, RemainderLine_, RecorderSCalculationString, AmountOfPrepaymentDebited, PrepaymentAmountLocal, ManSPrepaymentAmount);
		
	EndDo;
	
	For Each RemainderLine_ In CurrentVariables.TableOfBalancesOfSettlements Do
		If AmountOfDebtWriteOff = 0 Then
			Break;
		EndIf;
		If RemainderLine_.Debt = 0 Then
			Continue;
		EndIf;
		
		AddRepairRegisterRecordedOfUnfoldedBalance(GlobalVariables, CurrentVariables, RemainderLine_, RecorderSCalculationString, AmountOfDebtWriteOff, PrepaymentAmountLocal, ManSPrepaymentAmount);
		
	EndDo;
	
EndProcedure

Procedure AddRepairRegisterRecordedOfUnfoldedBalance(GlobalVariables, CurrentVariables, RemainderLine_, RecorderSCalculationString, AmountToBeDebited_, PrepaymentAmountLocal, ManSPrepaymentAmount)
	
	If RemainderLine_.Debt > 0 And AmountToBeDebited_ > 0 Then
		Resource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Debt.Name;
		LocalResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.DebtLocal.Name;
		ManResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.ARAPMan.Name;
		OppositeResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Prepayment.Name;
		OppositeResourceIsLocal = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentLocal.Name;
		OppositeResourceIsMan = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentMan.Name;
		ItSDuty = True;
	Else
		Resource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Prepayment.Name;
		LocalResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentLocal.Name;
		ManResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.PrepaymentMan.Name;
		OppositeResource = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.Debt.Name;
		OppositeResourceIsLocal = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.DebtLocal.Name;
		OppositeResourceIsMan = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Resources.ARAPMan.Name;
		ItSDuty = False;
	EndIf;
	
	DebitedAmount = Min(RemainderLine_[Resource],AmountToBeDebited_);
	
	If ItSDuty Then
		AmountOfLocalTaxDebited = DebitedAmount(0,PrepaymentAmountLocal,AmountToBeDebited_,DebitedAmount);
		AmountOfManDebiting = DebitedAmount(0,ManSPrepaymentAmount,AmountToBeDebited_,DebitedAmount);
	Else
		AmountOfLocalTaxDebited = DebitedAmount(0,RemainderLine_[LocalResource],RemainderLine_[Resource],DebitedAmount);
		AmountOfManDebiting = DebitedAmount(0,RemainderLine_[ManResource],RemainderLine_[Resource],DebitedAmount);
	EndIf;
	
	AmountToBeDebited_ = AmountToBeDebited_ - DebitedAmount;
	
	RemainderLine_[Resource] = RemainderLine_[Resource] - DebitedAmount;
	RemainderLine_[LocalResource] = RemainderLine_[LocalResource] - AmountOfLocalTaxDebited;
	RemainderLine_[ManResource] = RemainderLine_[ManResource] - AmountOfManDebiting;
	
	NwRw_Expense = CurrentVariables.TableOfCalculationsByTerms.Add();
	NwRw_Expense.RecordType = AccumulationRecordType.Expense;
	
	NwRw_Expense.ARAPDocument = RemainderLine_.ARAPDocument;
	NwRw_Expense.PlannedRepaymentDate = RemainderLine_.PlannedRepaymentDate;
	NwRw_Expense.OccurrenceDate = RemainderLine_.OccurrenceDate;
	
	NwRw_Expense.DocumentRecorder = RecorderSCalculationString.Recorder;
	NwRw_Expense.Period              = RecorderSCalculationString.Period;
	NwRw_Expense.OperationProcedure     = RecorderSCalculationString.OperationProcedure;
	NwRw_Expense.SettlementProcedure       = RecorderSCalculationString.OperationProcedure;
	NwRw_Expense.FinRecordID  = RecorderSCalculationString.RecordersID;
	NwRw_Expense.DocumentCurrency               = RecorderSCalculationString.DocumentCurrency;
	NwRw_Expense.CashFlowItem = RecorderSCalculationString.CashFlowItem;
	
	NwRw_Expense.BusinessOperation           = CurrentVariables.BusinessTransactions["ApplyingPrepayment"];
	NwRw_Expense.BusinessTransactionSetting  = CurrentVariables.HOSettings["PaymentSettlement"];
	
	NwRw_Expense[Resource]        = DebitedAmount;
	NwRw_Expense[LocalResource]    = AmountOfLocalTaxDebited;
	NwRw_Expense[ManResource]     = AmountOfManDebiting;
	NwRw_Expense[OppositeResource]        = 0;
	NwRw_Expense[OppositeResourceIsLocal]    = 0;
	NwRw_Expense[OppositeResourceIsMan]     = 0;
	
	NwRw_Expense.ReversingEntry = False;
	
	NwRw_Expense.RecordingBeforeCalculationStarts = False;
	NwRw_Expense.SettlementTransaction = Enums.SettlementOperations.ARAPAdjustment;
	
	NwRw_Expense.CorPartnerAccountingDimension = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
	NwRw_Expense.CorARAPObject = Catalogs.ARAPObjects.EmptyRef();
	NwRw_Expense.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
	NwRw_Expense.CalculationObjectReceiver = Catalogs.ARAPObjects.EmptyRef();
	NwRw_Expense.CurrencyReceiver = Catalogs.Currencies.EmptyRef();
	NwRw_Expense.AmountReceiver = 0;
	NwRw_Expense.ByDataOfSourceARAPObject = False;
	
	If Resource = "Debt" Then
		ReassessDebt(GlobalVariables, CurrentVariables, RemainderLine_.ARAPDocument, RecorderSCalculationString.Period, True);
	EndIf;
	
	If ItSDuty Then
		PrepaymentAmountLocal = PrepaymentAmountLocal - AmountOfLocalTaxDebited;
		ManSPrepaymentAmount = ManSPrepaymentAmount - AmountOfManDebiting;
	Else
		PrepaymentAmountLocal = PrepaymentAmountLocal + AmountOfLocalTaxDebited;
		ManSPrepaymentAmount = ManSPrepaymentAmount + AmountOfManDebiting;
	EndIf;
	
EndProcedure

Procedure AddMendingRegisterRecordedIfNecessary(GlobalVariables, CurrentVariables, StringIsStorno)
	
	// We check for a negative Balance
	CurrentVariables.TableOfBalancesOfSettlements.GroupBy("ARAPDocument,PlannedRepaymentDate,RepaymentDateIsNotFilledIn,OccurrenceDate,OperationProcedure,DateOfRevaluation, SettlementProcedureByPaymentDate","Debt,DebtLocal,ARAPMan,Prepayment,PrepaymentLocal,PrepaymentMan");
	If CurrentVariables.PaymentOffsetByPaymentDate Then
		CurrentVariables.TableOfBalancesOfSettlements.Sort("SettlementProcedureByPaymentDate ASC, OperationProcedure ASC");
	Else
		CurrentVariables.TableOfBalancesOfSettlements.Sort("OperationProcedure ASC, SettlementProcedureByPaymentDate ASC");
	EndIf;
	For Each ControlString In CurrentVariables.TableOfBalancesOfSettlements Do
		If ControlString.Debt < 0 Or ControlString.Prepayment < 0 Then
			AddRepairRegisterRecordedOnMinusBalance(GlobalVariables, CurrentVariables, ControlString, StringIsStorno);
		EndIf;
	EndDo;
	
	// We check for the expanded balance
	TotalDebt = CurrentVariables.TableOfBalancesOfSettlements.Total("Debt");
	ResultIsPrepayment = CurrentVariables.TableOfBalancesOfSettlements.Total("Prepayment");
	If TotalDebt> 0 And ResultIsPrepayment > 0 Then
		AmountToCollapse = Min(TotalDebt, ResultIsPrepayment);
		AddRepairRegisterRecordedOnExpandedBalance(GlobalVariables, CurrentVariables, AmountToCollapse, StringIsStorno);
	EndIf;
	
EndProcedure

// Adds all the Recorder's Registered Records storno - the Registered Records of the original document with a minus.
// Called when adding offset lines, when one of the lines is a Registered Record storno.
Procedure AddStornoEntries(GlobalVariables, CurrentVariables, CalculationLine_)
	
	If Not CalculationLine_.ReversingEntry Then
		Return;
	EndIf;
	
	StringOfOriginalRecorder = CurrentVariables.OriginalRecorders.Find(CalculationLine_.Recorder, "NewRegistrar");
	If StringOfOriginalRecorder <> Undefined And Not StringOfOriginalRecorder.Reversed Then
	
		#Region CalculationsByTerms
		SourceDocumentRegisteredRecords = CurrentVariables.RegisteredRecordsOfOriginalRecorders.Copy(New Structure("DocumentRecorder", CalculationLine_.CancelledRegistrar));
		If SourceDocumentRegisteredRecords.Count() = 0 Then
			SourceDocumentRegisteredRecords = CurrentVariables.TableOfCalculationsByTerms.FindRows(New Structure("DocumentRecorder,RecordingBeforeCalculationStarts,ReversingEntry", CalculationLine_.CancelledRegistrar,False,False));
		EndIf;
	
		For Each SourceDocumentRegisteredRecord In SourceDocumentRegisteredRecords Do
			If SourceDocumentRegisteredRecord.Debt <> 0 And SourceDocumentRegisteredRecord.RecordType = AccumulationRecordType.Receipt Then
				ReassessDebt(GlobalVariables, CurrentVariables, SourceDocumentRegisteredRecord.ARAPDocument, StringOfOriginalRecorder.NewPeriod);
			EndIf;
			AddNegativeRegisteredRecordStorno(CurrentVariables, StringOfOriginalRecorder, SourceDocumentRegisteredRecord);
		EndDo;
		#EndRegion
		
		StringOfOriginalRecorder.Reversed = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region SwitchingToOnlineSettlements

// Obsolete3
Procedure FillInRegisterOfTransitionToOnline()
	
	#Region QueryText
	QueryText = 
	"SELECT
	|	MAX(CustomersARAPAccounting.DateOfMovement) AS DateOfMovement,
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	CustomersARAPAccounting.Currency AS Currency,
	|	COUNT(*) AS DocumentsCount,
	|	MAX(CustomersARAPAccounting.Priority) AS Priority
	|FROM 
	|	(SELECT DISTINCT
	|		PartnersARAPAccounting.Period AS DateOfMovement,
	|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		PartnersARAPAccounting.SalesOrder AS ARAPObject,
	|		PartnersARAPAccounting.Currency AS Currency,
	|		CASE WHEN ISNULL(Calculations.ByDataOfSourceARAPObject,FALSE)
	|			THEN 2
	|			ELSE 1
	|		END AS Priority
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS PartnersARAPAccounting
	|			LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS Calculations
	|				ON Calculations.Recorder = PartnersARAPAccounting.Recorder
	|					AND Calculations.AccountingDimensionByPartners = PartnersARAPAccounting.AccountingDimensionByPartners
	|					AND Calculations.ARAPObject = PartnersARAPAccounting.SalesOrder
	|		
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		PartnersARAPAccounting.Period AS DateOfMovement,
	|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		PartnersARAPAccounting.ARAPObject AS ARAPObject,
	|		PartnersARAPAccounting.Currency AS Currency,
	|		CASE WHEN PartnersARAPAccounting.ByDataOfSourceARAPObject
	|			THEN 2
	|			ELSE 1
	|		END AS Priority
	|	FROM 
	|		AccumulationRegister.CustomersARAPAccounting AS PartnersARAPAccounting
	|	WHERE
	|		NOT TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				AccumulationRegister.CustomersARAPAccountingByDocuments AS CalculationsAccordingToDocuments
	|			WHERE
	|				PartnersARAPAccounting.AccountingDimensionByPartners = CalculationsAccordingToDocuments.AccountingDimensionByPartners
	|				AND PartnersARAPAccounting.ARAPObject = CalculationsAccordingToDocuments.SalesOrder
	|				AND PartnersARAPAccounting.Currency = CalculationsAccordingToDocuments.Currency
	|		)
	|
	|	) AS CustomersARAPAccounting
	|
	|GROUP BY
	|	CustomersARAPAccounting.AccountingDimensionByPartners,
	|	CustomersARAPAccounting.ARAPObject,
	|	CustomersARAPAccounting.Currency
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(VendorsARAPAccounting.DateOfMovement) AS DateOfMovement,
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.Currency AS Currency,
	|	COUNT(*) AS DocumentsCount,
	|	MAX(VendorsARAPAccounting.Priority) AS Priority
	|FROM 
	|	(SELECT DISTINCT
	|		PartnersARAPAccounting.Period AS DateOfMovement,
	|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		PartnersARAPAccounting.PurchaseOrder AS ARAPObject,
	|		PartnersARAPAccounting.Currency AS Currency,
	|		CASE WHEN ISNULL(Calculations.ByDataOfSourceARAPObject,FALSE)
	|			THEN 2
	|			ELSE 1
	|		END AS Priority
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS PartnersARAPAccounting
	|			LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS Calculations
	|				ON Calculations.Recorder = PartnersARAPAccounting.Recorder
	|					AND Calculations.AccountingDimensionByPartners = PartnersARAPAccounting.AccountingDimensionByPartners
	|					AND Calculations.ARAPObject = PartnersARAPAccounting.PurchaseOrder
	|		
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		PartnersARAPAccounting.Period AS DateOfMovement,
	|		PartnersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		PartnersARAPAccounting.ARAPObject AS ARAPObject,
	|		PartnersARAPAccounting.Currency AS Currency,
	|		CASE WHEN PartnersARAPAccounting.ByDataOfSourceARAPObject
	|			THEN 2
	|			ELSE 1
	|		END AS Priority
	|	FROM 
	|		AccumulationRegister.VendorsARAPAccounting AS PartnersARAPAccounting
	|	WHERE
	|		NOT TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				AccumulationRegister.VendorsARAPAccountingByDocuments AS CalculationsAccordingToDocuments
	|			WHERE
	|				PartnersARAPAccounting.AccountingDimensionByPartners = CalculationsAccordingToDocuments.AccountingDimensionByPartners
	|				AND PartnersARAPAccounting.ARAPObject = CalculationsAccordingToDocuments.PurchaseOrder
	|				AND PartnersARAPAccounting.Currency = CalculationsAccordingToDocuments.Currency
	|		)
	|
	|	) AS VendorsARAPAccounting
	|
	|GROUP BY
	|	VendorsARAPAccounting.AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject,
	|	VendorsARAPAccounting.Currency
	|
	|ORDER BY
	|	DocumentsCount DESC,
	|	AccountingDimensionByPartners,
	|	ARAPObject";
	#EndRegion
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	Set = InformationRegisters.JobsForAllocatingARAP.CreateRecordSet();
	Set.Write();
	LineNumber = 0;
	While Selection.Next() Do
		
		LineNumber = LineNumber + 1;
		FillPropertyValues(Set.Add(), Selection);
		If LineNumber = 1000 Then
			Set.Write(False);
			Set.Clear();
			LineNumber = 0;
		EndIf;
		
	EndDo;
	Set.Write(False);
	TotalToTransfer = Selection.Count();
	
	CommonSettingsStorage.Save("TransitionToNewSettlementArchitecture", "TotalToTransfer", TotalToTransfer);
	
	TotalRecords = NStr("vi = 'Tổng số bộ để mang';
						|ru = 'Всего кортежей к переносу';
						|en = 'Total tuples for transfer'; fa = 'Total tuples for transfer';
						|it = 'Totale tuple da tasferire';
						|pl = 'Łącznie krotek do przenoszenia';
						|tr = 'Toplam transfer edilecek demet'")+": %1";
	WriteLogEvent(NameOfLogEventWhenOnlineCalculationsAreEnabled(),
		EventLogLevel.Information,,,StrTemplate(TotalRecords, TotalToTransfer));
	
EndProcedure

// Performs the filling of operational settlements when the Online settlements option is enabled
// 
// Parameters:
//   Parameters - Structure - optional.
//   ResultAddress - String - optional
//
// Returns:
//   Number - Number of processed records
//
Function TransferOfflineSettlements(Parameters = Undefined, ResultAddress = Undefined) Export
	
	If Parameters <> Undefined And Parameters.Property("DataForProcessing_") Then
		DataForProcessing_ = Parameters.DataForProcessing_;
	Else
		DataParameters = ARAPAccountingInternal.MultithreadedDataParameters();
		DataForProcessing_ = ARAPAccountingInternal.DataForProcessing(DataParameters, True).Data;
	EndIf;
	
	ProcessingProcedure_ = GeneratePortionsOfDataProcessingRegistersOfMutualSettlements(DataForProcessing_, 1000);
	
	NumberOfRecordsProcessed = 0;
	OperationProcedure = New Map;
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BusinessOperationsNotShipping", BusinessOperationsNotShipping());

	ListOfOutgoingPaymentTypes = New Array;
	ListOfOutgoingPaymentTypes.Add(Type("DocumentRef.BankAccountIssue"));
	ListOfOutgoingPaymentTypes.Add(Type("DocumentRef.CashVoucher"));
	Query.SetParameter("ListOfOutgoingPaymentTypes", ListOfOutgoingPaymentTypes);
	
	StringQualifier = New StringQualifiers(40);
	DataForProcessing_.Columns.Add("OperationProcedure", New TypeDescription("String", , , , StringQualifier));

	For CurrentProcessingOrder = 1 To ProcessingProcedure_ Do

		PortionOfDataToBeProcessed = DataForProcessing_.Copy(New Structure("ProcessingProcedure_", CurrentProcessingOrder));
		
		NumberOfRecordsToBeProcessed = PortionOfDataToBeProcessed.Count();
		If NumberOfRecordsToBeProcessed = 0 Then
			Continue;
		EndIf;
		
		NumberOfRecordsToProcessClients = PortionOfDataToBeProcessed.FindRows(New Structure("PaymentType_",
			Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting)).Count();
			
		ThereAreRecordsOfSettlementsWithClients = (NumberOfRecordsToProcessClients > 0);
		ThereAreRecordsSettlementsWithSuppliers = (NumberOfRecordsToBeProcessed - NumberOfRecordsToProcessClients > 0);

		BeginTransaction();

		Try
			
			// 1. Transfer the calculation to the documents.
			Query.SetParameter("DataForProcessing_", PortionOfDataToBeProcessed);
			
			If ThereAreRecordsOfSettlementsWithClients Then
				Query.Text = QueryTextCustomersARAPAccountingByDocuments();
				TableOfDetailedRecordsClients = Query.Execute().Unload();
				TableOfDetailedRecordsClients.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
			EndIf;

			If ThereAreRecordsSettlementsWithSuppliers Then
				Query.Text = QueryTextVendorsARAPAccountingByDocuments();
				TableOfDetailedRecordsSuppliers = Query.Execute().Unload();
				TableOfDetailedRecordsSuppliers.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
			EndIf;
			
			For Each ReadyForProcessing In PortionOfDataToBeProcessed Do
				
				FilterStructure1 = New Structure;
				FilterStructure1.Insert("AccountingDimensionByPartners", ReadyForProcessing.AccountingDimensionByPartners);
				FilterStructure1.Insert("ARAPObject", ReadyForProcessing.ARAPObject);
				FilterStructure1.Insert("Currency", ReadyForProcessing.Currency);
				
				If ReadyForProcessing.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
					TableOfDetailedRecords = TableOfDetailedRecordsClients.Copy(FilterStructure1);
				Else
					TableOfDetailedRecords = TableOfDetailedRecordsSuppliers.Copy(FilterStructure1);
				EndIf;

				TheseAreSettlementsWithCustomers = (ReadyForProcessing.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
				If TableOfDetailedRecords.Count() > 0 Then
					RecordNewSettlementRecordsByDueDate(TheseAreSettlementsWithCustomers, TableOfDetailedRecords, OperationProcedure);
					NumberOfRecordsProcessed = NumberOfRecordsProcessed + TableOfDetailedRecords.Count();
				EndIf;
				
				If ValueIsFilled(ReadyForProcessing.RecountDate) Then
					ReadyForProcessing.Period = BegOfDay(ReadyForProcessing.RecountDate);
				EndIf;
				
			EndDo;

			DistributionParameters = CalculationDistributionParameters();
			DistributionParameters.SupplementDistributeReceivers = False;
			DistributionParameters.OnlyPlannedCalculations = True;
			
			FillInOperationalARAPAccountsAccordingToTable(DistributionParameters, PortionOfDataToBeProcessed);
			
			For Each Record In PortionOfDataToBeProcessed Do

				AdditionalFilterDimensions = "";
				If Record.RecountDate = Date('00010101') Then
					AdditionalFilterDimensions = "RecountDate";
				EndIf;
				MarkTaskCompletion(Record, AdditionalFilterDimensions);

			EndDo;

			CommitTransaction();
			
		Except
			RollbackTransaction();
			EventName = NameOfLogEventWhenOnlineCalculationsAreEnabled()
				+ " " + NStr("ru = 'Работа потока.';
							|vi = 'Work of thread.';
							|en = 'Work of thread.'; fa = 'Work of thread.';
							|it = 'Work of thread.';
							|pl = 'Work of thread.';
							|tr = 'Akış işleyişi.'",Common.DefaultLanguageCode());
			ErrorText = DetailErrorDescription(ErrorInfo());
			WriteLogEvent(EventName, EventLogLevel.Error, , , ErrorText);
		EndTry;
		
	EndDo;
	
	If ResultAddress <> Undefined Then
		Result = New Structure("NumberOfRecordsProcessed", NumberOfRecordsProcessed);
		PutToTempStorage(Result, ResultAddress);
	EndIf;
	
	Return NumberOfRecordsProcessed;
	
EndFunction

Procedure RecordNewSettlementRecordsByDueDate(TheseAreSettlementsWithCustomers, TableOfDetailedRecords, OperationProcedure)
	
	If TheseAreSettlementsWithCustomers Then
		RecordSet = AccumulationRegisters.CustomersARAPAccountingByDueDates.CreateRecordSet();
	Else
		RecordSet = AccumulationRegisters.VendorsARAPAccountingByDueDates.CreateRecordSet();
	EndIf;
	RecordSet.DataExchange.Load = True;
	
	TableOfDetailedRecords.Columns.Add("ReversingEntry", New TypeDescription("Boolean"));
	TableOfDetailedRecords.Columns.Add("SettlementRecordType", New TypeDescription("EnumRef.TypesOfSettlementRecords"));
	TableOfDetailedRecords.Columns.Add("Recorder", New TypeDescription("DocumentRef.ARAPAccountingRecorder"));
	TableOfDetailedRecords.Indexes.Add("Recorder");
	
	StornoArray = New Array;
	For Each StringOfRegisteredRecords In TableOfDetailedRecords Do
		If TypeOf(StringOfRegisteredRecords.DocumentRecorder) = Type("DocumentRef.ReversingEntry") Then
			StornoArray.Add(StringOfRegisteredRecords.DocumentRecorder);
		EndIf;
	EndDo;
	ComplianceOfCancelledDocuments = Common.ObjectsAttributeValue(StornoArray, "ReversedDocument");
	For Each StringOfRegisteredRecords In TableOfDetailedRecords Do
		If Not ValueIsFilled(StringOfRegisteredRecords.OperationProcedure) Then
			If OperationProcedure.Get(StringOfRegisteredRecords.Period) = Undefined Then
				OperationProcedure.Insert(StringOfRegisteredRecords.Period, Order(StringOfRegisteredRecords.Period, "", Type("DocumentRef.ExchangeDifferenceCalculation"),"9","99"));
			EndIf;
			StringOfRegisteredRecords.OperationProcedure = OperationProcedure[StringOfRegisteredRecords.Period];
		EndIf;
		TypeOfRegistrar = TypeOf(StringOfRegisteredRecords.DocumentRecorder);
		If TypeOfRegistrar = Type("DocumentRef.ReversingEntry")
			And ComplianceOfCancelledDocuments[StringOfRegisteredRecords.DocumentRecorder] <> Undefined Then
			TypeOfRegistrar = TypeOf(ComplianceOfCancelledDocuments[StringOfRegisteredRecords.DocumentRecorder]);
		EndIf;
		FillInTypeOfSettlementRecord(StringOfRegisteredRecords, TypeOfRegistrar);
	EndDo;
	
	AnalystTable = TableOfDetailedRecords.Copy();
	AnalystTable.GroupBy("AccountingDimensionByPartners, ARAPObject, Currency, Organization");
	Filter = AnalystTable[0];
	
	StructureOfLoggerParameters = New Structure;
	StructureOfLoggerParameters.Insert("ARAPObject",            Filter.ARAPObject);
	StructureOfLoggerParameters.Insert("AccountingDimensionByPartners", Filter.AccountingDimensionByPartners);
	StructureOfLoggerParameters.Insert("Currency",                    Filter.Currency);
	StructureOfLoggerParameters.Insert("Organization",               Filter.Organization);
	StructureOfLoggerParameters.Insert("TheseAreSettlementsWithCustomers",      TheseAreSettlementsWithCustomers);
	
	TableOfLoggers = TableOfFreeCalculationLoggers(StructureOfLoggerParameters, New Structure);
	PrepareDataToRecord(StructureOfLoggerParameters, TableOfDetailedRecords, RecordSet, TableOfLoggers);
	WriteInPortions(StructureOfLoggerParameters, TableOfDetailedRecords, RecordSet);

EndProcedure

Function QueryTextCustomersARAPAccountingByDocuments()
	
	Return "
	|SELECT DISTINCT
	|	BasicCalculationParameters.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BasicCalculationParameters.ARAPObject AS ARAPObject,
	|	BasicCalculationParameters.Currency AS Currency
	|INTO TTBasicCalculationParameters
	|FROM
	|	&DataForProcessing_ AS BasicCalculationParameters
	|WHERE
	|	BasicCalculationParameters.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|INTO TTRecorders_
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|		INNER JOIN TTBasicCalculationParameters AS BasicCalculationParameters
	|			ON Calculations.AccountingDimensionByPartners = BasicCalculationParameters.AccountingDimensionByPartners
	|				AND Calculations.SalesOrder = BasicCalculationParameters.ARAPObject
	|				AND Calculations.Currency = BasicCalculationParameters.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE WHEN CustomersARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN CustomersARAPAccounting.ARAPDocument
	|		ELSE CustomersARAPAccounting.Recorder 
	|	END                                      AS Recorder,
	|	BEGINOFPERIOD(CustomersARAPAccounting.Period,DAY) AS Date,
	|	MIN(CustomersARAPAccounting.OperationProcedure) AS OperationProcedure,
	|	MIN(CustomersARAPAccounting.SettlementProcedureByPaymentDate) AS SettlementProcedureByPaymentDate,
	|	MIN(CASE WHEN CustomersARAPAccounting.Recorder REFS Document.OBEntry
	|					OR CustomersARAPAccounting.Recorder REFS Document.OBEntryARAP
	|						THEN CustomersARAPAccounting.RecorderDate
	|				ELSE CustomersARAPAccounting.Period
	|			END)                             AS OccurrenceDate,
	|	MIN(CustomersARAPAccounting.DocumentCurrency) AS DocumentCurrency,
	|	MAX(CustomersARAPAccounting.PaymentDate)    AS PaymentDate
	|INTO OrderOfDocuments
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN TTRecorders_ AS Recorders
	|			ON Recorders.Recorder = CustomersARAPAccounting.Recorder
	|WHERE
	|	CustomersARAPAccounting.Active
	|	AND NOT CustomersARAPAccounting.OperationProcedure = """"
	|	AND CustomersARAPAccounting.Sum <> 0
	|GROUP BY
	|	CASE WHEN CustomersARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN CustomersARAPAccounting.ARAPDocument
	|		ELSE CustomersARAPAccounting.Recorder 
	|	END,
	|	BEGINOFPERIOD(CustomersARAPAccounting.Period,DAY)
	|INDEX BY
	|	Recorder
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE WHEN CustomersARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN CustomersARAPAccounting.ARAPDocument
	|		ELSE CustomersARAPAccounting.Recorder 
	|	END                                      AS Recorder,
	|	MIN(CustomersARAPAccounting.OperationProcedure) AS OperationProcedure,
	|	MIN(CustomersARAPAccounting.SettlementProcedureByPaymentDate) AS SettlementProcedureByPaymentDate,
	|	MIN(CASE WHEN CustomersARAPAccounting.Recorder REFS Document.OBEntry
	|					OR CustomersARAPAccounting.Recorder REFS Document.OBEntryARAP
	|						THEN CustomersARAPAccounting.RecorderDate
	|				ELSE CustomersARAPAccounting.Period
	|			END)                             AS OccurrenceDate,
	|	MIN(CustomersARAPAccounting.DocumentCurrency) AS DocumentCurrency,
	|	MAX(CustomersARAPAccounting.PaymentDate)    AS PaymentDate
	|INTO DatesOfOccurrence
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN TTRecorders_ AS Recorders
	|			ON Recorders.Recorder = CustomersARAPAccounting.Recorder
	|WHERE
	|	CustomersARAPAccounting.Active
	|	AND NOT CustomersARAPAccounting.OperationProcedure = """"
	|	AND CustomersARAPAccounting.Sum <> 0
	|GROUP BY
	|	CASE WHEN CustomersARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN CustomersARAPAccounting.ARAPDocument
	|		ELSE CustomersARAPAccounting.Recorder 
	|	END
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomersARAPAccountingByDocuments.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingByDocuments.SalesOrder                          AS ARAPObject,
	|	CustomersARAPAccountingByDocuments.SalesOrder.ARAPObjectType       AS ARAPObjectType,
	|	CustomersARAPAccountingByDocuments.Currency                                AS Currency,
	|	CustomersARAPAccountingByDocuments.Recorder                           AS DocumentRecorder,
	|	CustomersARAPAccountingByDocuments.Period                                AS Period,
	|	CustomersARAPAccountingByDocuments.ARAPDocument                     AS ARAPDocument,
	|	CustomersARAPAccountingByDocuments.BusinessOperation                 AS BusinessOperation,
	|	CustomersARAPAccountingByDocuments.CashFlowItem         AS CashFlowItem,
	|	CASE WHEN RecordType = VALUE(AccumulationRecordType.Receipt) AND (CustomersARAPAccountingByDocuments.Debt > 0
	|			OR CustomersARAPAccountingByDocuments.DebtLocal > 0 OR CustomersARAPAccountingByDocuments.ARAPMan > 0
	|			OR CustomersARAPAccountingByDocuments.Prepayment < 0 OR CustomersARAPAccountingByDocuments.PrepaymentLocal < 0
	|			OR CustomersARAPAccountingByDocuments.PrepaymentMan < 0)
	|		OR RecordType = VALUE(AccumulationRecordType.Expense) AND (CustomersARAPAccountingByDocuments.Prepayment > 0
	|			OR CustomersARAPAccountingByDocuments.PrepaymentLocal > 0 OR CustomersARAPAccountingByDocuments.PrepaymentMan > 0
	|			OR CustomersARAPAccountingByDocuments.Debt < 0 OR CustomersARAPAccountingByDocuments.DebtLocal < 0 
	|			OR CustomersARAPAccountingByDocuments.ARAPMan < 0) THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END                                                               AS RecordType,
	|	CAST(CustomersARAPAccountingByDocuments.ARAPDocument AS Document.SaleAdjustment).DocumentBasis AS LinkedDocument,
	|
	|	CASE WHEN CustomersARAPAccountingByDocuments.Prepayment < 0 THEN
	|		-CustomersARAPAccountingByDocuments.Prepayment 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.Prepayment
	|	END                                                               AS Prepayment,
	|	CASE WHEN CustomersARAPAccountingByDocuments.PrepaymentMan < 0 THEN
	|		-CustomersARAPAccountingByDocuments.PrepaymentMan 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.PrepaymentMan
	|	END                                                               AS PrepaymentMan,
	|	CASE WHEN CustomersARAPAccountingByDocuments.PrepaymentLocal < 0 THEN
	|		-CustomersARAPAccountingByDocuments.PrepaymentLocal 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.PrepaymentLocal
	|	END                                                               AS PrepaymentLocal,
	|	CASE WHEN CustomersARAPAccountingByDocuments.Debt < 0 THEN
	|		-CustomersARAPAccountingByDocuments.Debt 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.Debt
	|	END                                                               AS Debt,
	|	CASE WHEN CustomersARAPAccountingByDocuments.ARAPMan < 0 THEN
	|		-CustomersARAPAccountingByDocuments.ARAPMan 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.ARAPMan
	|	END                                                               AS ARAPMan,
	|	CASE WHEN CustomersARAPAccountingByDocuments.DebtLocal < 0 THEN
	|		-CustomersARAPAccountingByDocuments.DebtLocal 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.DebtLocal
	|	END                                                               AS DebtLocal,
	|
	|	CASE WHEN CustomersARAPAccountingByDocuments.Prepayment <> 0 THEN DATETIME(1,1,1)
	|		WHEN (RecordType = VALUE(AccumulationRecordType.Receipt) AND (CustomersARAPAccountingByDocuments.Debt > 0
	|				OR CustomersARAPAccountingByDocuments.DebtLocal > 0 OR CustomersARAPAccountingByDocuments.ARAPMan > 0
	|				OR CustomersARAPAccountingByDocuments.Prepayment < 0 OR CustomersARAPAccountingByDocuments.PrepaymentLocal < 0
	|				OR CustomersARAPAccountingByDocuments.PrepaymentMan < 0)
	|			OR RecordType = VALUE(AccumulationRecordType.Expense) AND (CustomersARAPAccountingByDocuments.Prepayment > 0
	|				OR CustomersARAPAccountingByDocuments.PrepaymentLocal > 0 OR CustomersARAPAccountingByDocuments.PrepaymentMan > 0
	|				OR CustomersARAPAccountingByDocuments.Debt < 0 OR CustomersARAPAccountingByDocuments.DebtLocal < 0 
	|				OR CustomersARAPAccountingByDocuments.ARAPMan < 0))
	|			AND NOT ((CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntry OR
	|					CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP) AND 
	|					CustomersARAPAccountingByDocuments.ARAPDocument <> UNDEFINED)
	|			AND NOT CustomersARAPAccountingByDocuments.Recorder REFS Document.ExchangeDifferenceCalculation THEN
	|			ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|	ELSE
	|		ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|	END                                                               AS PlannedRepaymentDate,
	|	ISNULL(DatesOfOccurrence.OccurrenceDate,DATETIME(1,1,1))      AS OccurrenceDate,
	|	ISNULL(OrderOfDocuments.OperationProcedure,"""")                    AS OperationProcedure,
	|	ISNULL(DatesOfOccurrence.SettlementProcedureByPaymentDate,"""")         AS ProcedureForCreditingRegistrar,
	|	ISNULL(DatesOfOccurrence.SettlementProcedureByPaymentDate,"""")         AS SettlementProcedure,
	|	ISNULL(DatesOfOccurrence.DocumentCurrency,
	|		ISNULL(DatesOfOccurrence.DocumentCurrency,
	|			VALUE(Catalog.Currencies.EmptyRef)))                  AS DocumentCurrency
	|INTO TTCalculations
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
	|		INNER JOIN TTBasicCalculationParameters AS BasicCalculationParameters
	|			ON CustomersARAPAccountingByDocuments.AccountingDimensionByPartners = BasicCalculationParameters.AccountingDimensionByPartners
	|				AND CustomersARAPAccountingByDocuments.SalesOrder = BasicCalculationParameters.ARAPObject
	|				AND CustomersARAPAccountingByDocuments.Currency = BasicCalculationParameters.Currency
	|		LEFT JOIN OrderOfDocuments AS OrderOfDocuments
	|			ON CustomersARAPAccountingByDocuments.Recorder = OrderOfDocuments.Recorder
	|				AND BEGINOFPERIOD(CustomersARAPAccountingByDocuments.Period) = OrderOfDocuments.Date
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON CustomersARAPAccountingByDocuments.ARAPDocument = DatesOfOccurrence.Recorder
	|WHERE
	|	(CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntry
	|		OR CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP)
	|	AND CustomersARAPAccountingByDocuments.Recorder <> CustomersARAPAccountingByDocuments.ARAPDocument
	|	AND (CustomersARAPAccountingByDocuments.Prepayment <> 0
	|		OR CustomersARAPAccountingByDocuments.PrepaymentLocal <> 0
	|		OR CustomersARAPAccountingByDocuments.PrepaymentMan <> 0
	|		OR CustomersARAPAccountingByDocuments.Debt <> 0
	|		OR CustomersARAPAccountingByDocuments.DebtLocal <> 0
	|		OR CustomersARAPAccountingByDocuments.ARAPMan <> 0)
	|	AND CustomersARAPAccountingByDocuments.Active
	|
	|UNION ALL
	|
	|SELECT
	|	CustomersARAPAccountingByDocuments.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingByDocuments.SalesOrder                          AS ARAPObject,
	|	CustomersARAPAccountingByDocuments.SalesOrder.ARAPObjectType       AS ARAPObjectType,
	|	CustomersARAPAccountingByDocuments.Currency                                AS Currency,
	|	CustomersARAPAccountingByDocuments.Recorder                           AS DocumentRecorder,
	|	CustomersARAPAccountingByDocuments.Period                                AS Period,
	|	CustomersARAPAccountingByDocuments.ARAPDocument                     AS ARAPDocument,
	|	CustomersARAPAccountingByDocuments.BusinessOperation                 AS BusinessOperation,
	|	CustomersARAPAccountingByDocuments.CashFlowItem         AS CashFlowItem,
	|CASE WHEN RecordType = VALUE(AccumulationRecordType.Receipt) 
	|			AND (CustomersARAPAccountingByDocuments.Debt > 0
	|				OR CustomersARAPAccountingByDocuments.DebtLocal > 0 OR CustomersARAPAccountingByDocuments.ARAPMan > 0
	|				OR CustomersARAPAccountingByDocuments.Prepayment < 0 OR CustomersARAPAccountingByDocuments.PrepaymentLocal < 0
	|				OR CustomersARAPAccountingByDocuments.PrepaymentMan < 0
	|				OR (VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes) 
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|					)
	|						AND CustomersARAPAccountingByDocuments.Prepayment > 0)
	|		OR RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND NOT ((VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes)
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|			)
	|				AND CustomersARAPAccountingByDocuments.Prepayment > 0)
	|			AND (CustomersARAPAccountingByDocuments.Prepayment > 0
	|				OR CustomersARAPAccountingByDocuments.PrepaymentLocal > 0 OR CustomersARAPAccountingByDocuments.PrepaymentMan > 0
	|				OR CustomersARAPAccountingByDocuments.Debt < 0 OR CustomersARAPAccountingByDocuments.DebtLocal < 0 
	|				OR CustomersARAPAccountingByDocuments.ARAPMan < 0) THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END                                                               AS RecordType,
	|	CASE WHEN CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment 
	|		THEN CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.SaleAdjustment).DocumentBasis
	|		ELSE CAST(CustomersARAPAccountingByDocuments.ARAPDocument AS Document.SaleAdjustment).DocumentBasis
	|	END AS LinkedDocument,
	|
	|	CASE WHEN (VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes)
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|				)
	|		AND CustomersARAPAccountingByDocuments.Prepayment > 0 
	|			THEN 0
	|		WHEN CustomersARAPAccountingByDocuments.Prepayment < 0 THEN
	|			-CustomersARAPAccountingByDocuments.Prepayment 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.Prepayment
	|	END                                                               AS Prepayment,
	|	CASE WHEN (VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes)
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|				)
	|		AND CustomersARAPAccountingByDocuments.Prepayment > 0 
	|			THEN 0
	|		WHEN CustomersARAPAccountingByDocuments.PrepaymentMan < 0 THEN
	|			-CustomersARAPAccountingByDocuments.PrepaymentMan 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.PrepaymentMan
	|	END                                                               AS PrepaymentMan,
	|	CASE WHEN (VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes)
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|				)
	|		AND CustomersARAPAccountingByDocuments.Prepayment > 0 
	|			THEN 0
	|		WHEN CustomersARAPAccountingByDocuments.PrepaymentLocal < 0 THEN
	|			-CustomersARAPAccountingByDocuments.PrepaymentLocal
	|	ELSE
	|		CustomersARAPAccountingByDocuments.PrepaymentLocal
	|	END                                                               AS PrepaymentLocal,
	|	CASE WHEN CustomersARAPAccountingByDocuments.Debt < 0 THEN
	|		-CustomersARAPAccountingByDocuments.Debt 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.Debt
	|		+ CASE WHEN (VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes)
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|					)
	|			AND CustomersARAPAccountingByDocuments.Prepayment > 0
	|				THEN CustomersARAPAccountingByDocuments.Prepayment
	|			ELSE 0
	|		END
	|	END                                                               AS Debt,
	|	CASE WHEN CustomersARAPAccountingByDocuments.ARAPMan < 0 THEN
	|		-CustomersARAPAccountingByDocuments.ARAPMan 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.ARAPMan
	|		+ CASE WHEN (VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes)
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|						)
	|			AND CustomersARAPAccountingByDocuments.PrepaymentMan > 0
	|				THEN CustomersARAPAccountingByDocuments.PrepaymentMan
	|			ELSE 0
	|		END
	|	END                                                               AS ARAPMan,
	|	CASE WHEN CustomersARAPAccountingByDocuments.DebtLocal < 0 THEN
	|		-CustomersARAPAccountingByDocuments.DebtLocal 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.DebtLocal
	|		+ CASE WHEN (VALUETYPE(CustomersARAPAccountingByDocuments.Recorder) IN (&ListOfOutgoingPaymentTypes)
	|					OR ISNULL(CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.PaymentCardTransaction).BusinessOperation,UNDEFINED) = VALUE(Enum.BusinessTransactions.RefundToCustomer)
	|						)
	|			AND CustomersARAPAccountingByDocuments.PrepaymentLocal > 0
	|				THEN CustomersARAPAccountingByDocuments.PrepaymentLocal
	|			ELSE 0
	|		END
	|	END                                                               AS DebtLocal,
	|
	|	CASE WHEN CustomersARAPAccountingByDocuments.Prepayment <> 0 THEN DATETIME(1,1,1)
	|		WHEN (RecordType = VALUE(AccumulationRecordType.Receipt) AND (CustomersARAPAccountingByDocuments.Debt > 0
	|				OR CustomersARAPAccountingByDocuments.DebtLocal > 0 OR CustomersARAPAccountingByDocuments.ARAPMan > 0)
	|			OR RecordType = VALUE(AccumulationRecordType.Expense) AND (CustomersARAPAccountingByDocuments.Prepayment > 0
	|				OR CustomersARAPAccountingByDocuments.PrepaymentLocal > 0 OR CustomersARAPAccountingByDocuments.PrepaymentMan > 0))
	|			AND NOT ((CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntry OR
	|					CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP) AND
	|					CustomersARAPAccountingByDocuments.ARAPDocument <> UNDEFINED)
	|			AND NOT CustomersARAPAccountingByDocuments.Recorder REFS Document.ExchangeDifferenceCalculation THEN
	|			CASE
	|				WHEN ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1)) = DATETIME(1,1,1)
	|					THEN ISNULL(OrderOfDocuments.PaymentDate, DATETIME(1,1,1))
	|				ELSE ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|			END
	|	ELSE
	|		ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|	END                                                               AS PlannedRepaymentDate,
	|	ISNULL(DatesOfOccurrence.OccurrenceDate,DATETIME(1,1,1))      AS OccurrenceDate,
	|	ISNULL(OrderOfDocuments.OperationProcedure,"""")                    AS OperationProcedure,
	|	ISNULL(OrderOfDocuments.SettlementProcedureByPaymentDate,"""")         AS ProcedureForCreditingRegistrar,
	|	ISNULL(DatesOfOccurrence.SettlementProcedureByPaymentDate,"""")         AS SettlementProcedure,
	|	ISNULL(DatesOfOccurrence.DocumentCurrency,
	|		ISNULL(OrderOfDocuments.DocumentCurrency,
	|			VALUE(Catalog.Currencies.EmptyRef)))                  AS DocumentCurrency
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
	|		INNER JOIN TTBasicCalculationParameters AS BasicCalculationParameters
	|			ON CustomersARAPAccountingByDocuments.AccountingDimensionByPartners = BasicCalculationParameters.AccountingDimensionByPartners
	|				AND CustomersARAPAccountingByDocuments.SalesOrder = BasicCalculationParameters.ARAPObject
	|				AND CustomersARAPAccountingByDocuments.Currency = BasicCalculationParameters.Currency
	|		LEFT JOIN OrderOfDocuments AS OrderOfDocuments
	|			ON CustomersARAPAccountingByDocuments.Recorder = OrderOfDocuments.Recorder
	|				AND BEGINOFPERIOD(CustomersARAPAccountingByDocuments.Period) = OrderOfDocuments.Date
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON CustomersARAPAccountingByDocuments.ARAPDocument = DatesOfOccurrence.Recorder
	|WHERE
	|	(NOT (CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntry
	|		OR CustomersARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP)
	|	OR CustomersARAPAccountingByDocuments.Recorder = CustomersARAPAccountingByDocuments.ARAPDocument)
	|	AND (CustomersARAPAccountingByDocuments.Prepayment <> 0
	|		OR CustomersARAPAccountingByDocuments.PrepaymentLocal <> 0
	|		OR CustomersARAPAccountingByDocuments.PrepaymentMan <> 0
	|		OR CustomersARAPAccountingByDocuments.Debt <> 0
	|		OR CustomersARAPAccountingByDocuments.DebtLocal <> 0
	|		OR CustomersARAPAccountingByDocuments.ARAPMan <> 0)
	|	AND CustomersARAPAccountingByDocuments.Active
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                AS ARAPObject,
	|	Calculations.Currency                        AS Currency,
	|	Calculations.DocumentRecorder           AS DocumentRecorder,
	|	Calculations.ARAPDocument             AS ARAPDocument,
	|	Calculations.BusinessOperation         AS BusinessOperation,
	|	Calculations.Period                        AS Period,
	|	Calculations.PlannedRepaymentDate        AS PlannedRepaymentDate,
	|	Calculations.OccurrenceDate             AS OccurrenceDate,
	|	Calculations.RecordType                   AS RecordType,
	|	SUM(Calculations.Prepayment)             AS Prepayment,
	|	SUM(Calculations.PrepaymentMan)          AS PrepaymentMan,
	|	SUM(Calculations.PrepaymentLocal)         AS PrepaymentLocal,
	|	SUM(Calculations.Debt)                   AS Debt,
	|	SUM(Calculations.ARAPMan)                AS ARAPMan,
	|	SUM(Calculations.DebtLocal)               AS DebtLocal,
	|	Calculations.LinkedDocument             AS LinkedDocument,
	|	Calculations.CashFlowItem AS CashFlowItem,
	|	Calculations.OperationProcedure               AS OperationProcedure,
	|	Calculations.SettlementProcedure                 AS SettlementProcedure,
	|	Calculations.DocumentCurrency               AS DocumentCurrency,
	|	Calculations.Organization                   AS Organization
	|FROM (
	|	SELECT
	|		PaymentOffsets.AccountingDimensionByPartners                            AS AccountingDimensionByPartners,
	|		PaymentOffsets.ARAPObject                                       AS ARAPObject,
	|		PaymentOffsets.Currency                                               AS Currency,
	|		PaymentOffsets.DocumentRecorder                                  AS DocumentRecorder,
	|		PaymentOffsets.DocumentRecorder                                  AS ARAPDocument,
	|		PaymentOffsets.BusinessOperation                                AS BusinessOperation,
	|		PaymentOffsets.Period                                               AS Period,
	|		DatesOfOccurrence.PaymentDate                                    AS PlannedRepaymentDate,
	|		PaymentOffsets.Period                                               AS OccurrenceDate,
	|		VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
	|		0                                                                AS Prepayment,
	|		0                                                                AS PrepaymentMan,
	|		0                                                                AS PrepaymentLocal,
	|		PaymentOffsets.Prepayment                                           AS Debt,
	|		PaymentOffsets.PrepaymentMan                                        AS ARAPMan,
	|		PaymentOffsets.PrepaymentLocal                                       AS DebtLocal,
	|		UNDEFINED                                                     AS LinkedDocument,
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef)  AS CashFlowItem,
	|		PaymentOffsets.OperationProcedure                                      AS OperationProcedure,
	|		PaymentOffsets.ProcedureForCreditingRegistrar                            AS SettlementProcedure,
	|		PaymentOffsets.DocumentCurrency                                      AS DocumentCurrency,
	|		PaymentOffsets.AccountingDimensionByPartners.Organization                AS Organization
	|	FROM TTCalculations AS PaymentOffsets
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON PaymentOffsets.DocumentRecorder = DatesOfOccurrence.Recorder
	|	WHERE	PaymentOffsets.Prepayment > 0 
	|		AND PaymentOffsets.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND PaymentOffsets.BusinessOperation NOT IN (&BusinessOperationsNotShipping)
	|		AND PaymentOffsets.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PaymentOffsets.AccountingDimensionByPartners                            AS AccountingDimensionByPartners,
	|		PaymentOffsets.ARAPObject                                       AS ARAPObject,
	|		PaymentOffsets.Currency                                               AS Currency,
	|		PaymentOffsets.DocumentRecorder                                  AS DocumentRecorder,
	|		PaymentOffsets.DocumentRecorder                                  AS ARAPDocument,
	|		VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)  AS BusinessOperation,
	|		PaymentOffsets.Period                                               AS Period,
	|		DatesOfOccurrence.PaymentDate                                    AS PlannedRepaymentDate,
	|		PaymentOffsets.Period                                               AS OccurrenceDate,
	|		VALUE(AccumulationRecordType.Expense)                           AS RecordType,
	|		0                                                                AS Prepayment,
	|		0                                                                AS PrepaymentMan,
	|		0                                                                AS PrepaymentLocal,
	|		PaymentOffsets.Prepayment                                           AS Debt,
	|		PaymentOffsets.PrepaymentMan                                        AS ARAPMan,
	|		PaymentOffsets.PrepaymentLocal                                       AS DebtLocal,
	|		UNDEFINED                                                     AS LinkedDocument,
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef)  AS CashFlowItem,
	|		PaymentOffsets.OperationProcedure                                      AS OperationProcedure,
	|		PaymentOffsets.ProcedureForCreditingRegistrar                            AS SettlementProcedure,
	|		PaymentOffsets.DocumentCurrency                                      AS DocumentCurrency,
	|		PaymentOffsets.AccountingDimensionByPartners.Organization                AS Organization
	|	FROM TTCalculations AS PaymentOffsets
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON PaymentOffsets.DocumentRecorder = DatesOfOccurrence.Recorder
	|	WHERE
	|		PaymentOffsets.Prepayment > 0 
	|		AND PaymentOffsets.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND PaymentOffsets.BusinessOperation NOT IN (&BusinessOperationsNotShipping)
	|		AND PaymentOffsets.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsAccordingToDocuments.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
	|		CalculationsAccordingToDocuments.ARAPObject                AS ARAPObject,
	|		CalculationsAccordingToDocuments.Currency                        AS Currency,
	|		CalculationsAccordingToDocuments.DocumentRecorder           AS DocumentRecorder,
	|		CalculationsAccordingToDocuments.ARAPDocument             AS ARAPDocument,
	|		CASE WHEN CalculationsAccordingToDocuments.Prepayment <> 0 AND CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND CalculationsAccordingToDocuments.BusinessOperation NOT IN (VALUE(Enum.BusinessTransactions.ARAPSettlement),
	|					VALUE(Enum.BusinessTransactions.APWriteOff),
	|					VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
	|				THEN VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|			WHEN CalculationsAccordingToDocuments.Debt <> 0 AND CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND CalculationsAccordingToDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.ARAPSettlement)
	|				AND CalculationsAccordingToDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				AND CalculationsAccordingToDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				AND CalculationsAccordingToDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction)
	|				THEN VALUE(Enum.BusinessTransactions.RepaymentOfCustomerReceivables)
	|			ELSE CalculationsAccordingToDocuments.BusinessOperation 
	|		END AS BusinessOperation,
	|		CalculationsAccordingToDocuments.Period                        AS Period,
	|		CalculationsAccordingToDocuments.PlannedRepaymentDate        AS PlannedRepaymentDate,
	|		CalculationsAccordingToDocuments.OccurrenceDate             AS OccurrenceDate,
	|		CalculationsAccordingToDocuments.RecordType                   AS RecordType,
	|		CalculationsAccordingToDocuments.Prepayment                    AS Prepayment,
	|		CalculationsAccordingToDocuments.PrepaymentMan                 AS PrepaymentMan,
	|		CalculationsAccordingToDocuments.PrepaymentLocal                AS PrepaymentLocal,
	|		CalculationsAccordingToDocuments.Debt                          AS Debt,
	|		CalculationsAccordingToDocuments.ARAPMan                       AS ARAPMan,
	|		CalculationsAccordingToDocuments.DebtLocal                      AS DebtLocal,
	|		CASE WHEN (CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Receipt) AND CalculationsAccordingToDocuments.Prepayment > 0)
	|			OR (CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Expense) AND CalculationsAccordingToDocuments.Debt > 0)
	|			THEN CalculationsAccordingToDocuments.LinkedDocument
	|			ELSE UNDEFINED
	|		END                                             AS LinkedDocument,
	|		CalculationsAccordingToDocuments.CashFlowItem AS CashFlowItem,
	|		CalculationsAccordingToDocuments.OperationProcedure               AS OperationProcedure,
	|		CalculationsAccordingToDocuments.SettlementProcedure                 AS SettlementProcedure,
	|		CalculationsAccordingToDocuments.DocumentCurrency               AS DocumentCurrency,
	|		CalculationsAccordingToDocuments.AccountingDimensionByPartners.Organization AS Organization
	|	FROM TTCalculations AS CalculationsAccordingToDocuments) AS Calculations
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.DocumentRecorder,
	|	Calculations.ARAPDocument,
	|	Calculations.BusinessOperation,
	|	Calculations.Period,
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.OccurrenceDate,
	|	Calculations.RecordType,
	|	Calculations.LinkedDocument,
	|	Calculations.CashFlowItem,
	|	Calculations.OperationProcedure,
	|	Calculations.SettlementProcedure,
	|	Calculations.DocumentCurrency,
	|	Calculations.Organization
	|;
	|DROP TTBasicCalculationParameters;
	|DROP TTRecorders_;
	|DROP OrderOfDocuments;
	|DROP DatesOfOccurrence;
	|DROP TTCalculations
	|";
	
EndFunction

Function QueryTextVendorsARAPAccountingByDocuments()
	
	Return "
	|SELECT DISTINCT
	|	BasicCalculationParameters.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BasicCalculationParameters.ARAPObject AS ARAPObject,
	|	BasicCalculationParameters.Currency AS Currency
	|INTO TTBasicCalculationParameters
	|FROM
	|	&DataForProcessing_ AS BasicCalculationParameters
	|WHERE
	|	BasicCalculationParameters.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|INTO TTRecorders_
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|		INNER JOIN TTBasicCalculationParameters AS BasicCalculationParameters
	|			ON Calculations.AccountingDimensionByPartners = BasicCalculationParameters.AccountingDimensionByPartners
	|				AND Calculations.PurchaseOrder = BasicCalculationParameters.ARAPObject
	|				AND Calculations.Currency = BasicCalculationParameters.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE WHEN VendorsARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN VendorsARAPAccounting.ARAPDocument
	|		ELSE VendorsARAPAccounting.Recorder 
	|	END                                         AS Recorder,
	|	BEGINOFPERIOD(VendorsARAPAccounting.Period,DAY) AS Date,
	|	MIN(VendorsARAPAccounting.OperationProcedure) AS OperationProcedure,
	|	MIN(VendorsARAPAccounting.SettlementProcedureByPaymentDate) AS SettlementProcedureByPaymentDate,
	|	MIN(CASE WHEN VendorsARAPAccounting.Recorder REFS Document.OBEntry OR
	|					VendorsARAPAccounting.Recorder REFS Document.OBEntryARAP
	|						THEN VendorsARAPAccounting.RecorderDate
	|				ELSE VendorsARAPAccounting.Period
	|			END)                                AS OccurrenceDate,
	|	MIN(VendorsARAPAccounting.DocumentCurrency) AS DocumentCurrency,
	|	MAX(VendorsARAPAccounting.PaymentDate)    AS PaymentDate
	|INTO OrderOfDocuments
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN TTRecorders_ AS Recorders
	|			ON Recorders.Recorder = VendorsARAPAccounting.Recorder
	|WHERE
	|	VendorsARAPAccounting.Active
	|	AND NOT VendorsARAPAccounting.OperationProcedure = """"
	|	AND (VendorsARAPAccounting.Sum <> 0 OR VendorsARAPAccounting.AmountDue <> 0)
	|GROUP BY
	|	CASE WHEN VendorsARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN VendorsARAPAccounting.ARAPDocument
	|		ELSE VendorsARAPAccounting.Recorder 
	|	END,
	|	BEGINOFPERIOD(VendorsARAPAccounting.Period,DAY)
	|INDEX BY
	|	Recorder
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE WHEN VendorsARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN VendorsARAPAccounting.ARAPDocument
	|		ELSE VendorsARAPAccounting.Recorder 
	|	END                                         AS Recorder,
	|	MIN(VendorsARAPAccounting.OperationProcedure) AS OperationProcedure,
	|	MIN(VendorsARAPAccounting.SettlementProcedureByPaymentDate) AS SettlementProcedureByPaymentDate,
	|	MIN(CASE WHEN VendorsARAPAccounting.Recorder REFS Document.OBEntry OR
	|					VendorsARAPAccounting.Recorder REFS Document.OBEntryARAP
	|						THEN VendorsARAPAccounting.RecorderDate
	|				ELSE VendorsARAPAccounting.Period
	|			END)                                AS OccurrenceDate,
	|	MIN(VendorsARAPAccounting.DocumentCurrency) AS DocumentCurrency,
	|	MAX(VendorsARAPAccounting.PaymentDate)    AS PaymentDate
	|INTO DatesOfOccurrence
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN TTRecorders_ AS Recorders
	|			ON Recorders.Recorder = VendorsARAPAccounting.Recorder
	|WHERE
	|	VendorsARAPAccounting.Active
	|	AND NOT VendorsARAPAccounting.OperationProcedure = """"
	|	AND (VendorsARAPAccounting.Sum <> 0 OR VendorsARAPAccounting.AmountDue <> 0)
	|GROUP BY
	|	CASE WHEN VendorsARAPAccounting.ARAPDocument <> UNDEFINED 
	|		THEN VendorsARAPAccounting.ARAPDocument
	|		ELSE VendorsARAPAccounting.Recorder 
	|	END
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorsARAPAccountingByDocuments.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDocuments.PurchaseOrder                AS ARAPObject,
	|	VendorsARAPAccountingByDocuments.PurchaseOrder.ARAPObjectType AS ARAPObjectType,
	|	VendorsARAPAccountingByDocuments.Currency                         AS Currency,
	|	VendorsARAPAccountingByDocuments.Recorder                    AS DocumentRecorder,
	|	VendorsARAPAccountingByDocuments.ARAPDocument              AS ARAPDocument,
	|	VendorsARAPAccountingByDocuments.BusinessOperation          AS BusinessOperation,
	|	VendorsARAPAccountingByDocuments.CashFlowItem  AS CashFlowItem,
	|	VendorsARAPAccountingByDocuments.Period                         AS Period,
	|	CASE WHEN RecordType = VALUE(AccumulationRecordType.Receipt) AND (VendorsARAPAccountingByDocuments.Debt < 0
	|				OR VendorsARAPAccountingByDocuments.DebtLocal < 0 OR VendorsARAPAccountingByDocuments.ARAPMan < 0
	|				OR VendorsARAPAccountingByDocuments.Prepayment > 0 OR VendorsARAPAccountingByDocuments.PrepaymentLocal > 0
	|				OR VendorsARAPAccountingByDocuments.PrepaymentMan > 0)
	|		OR RecordType = VALUE(AccumulationRecordType.Expense) AND (VendorsARAPAccountingByDocuments.Prepayment < 0
	|				OR VendorsARAPAccountingByDocuments.PrepaymentLocal < 0 OR VendorsARAPAccountingByDocuments.PrepaymentMan < 0
	|				OR VendorsARAPAccountingByDocuments.Debt > 0 OR VendorsARAPAccountingByDocuments.DebtLocal > 0 
	|				OR VendorsARAPAccountingByDocuments.ARAPMan > 0) THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END                                                           AS RecordType,
	|	CAST(VendorsARAPAccountingByDocuments.ARAPDocument AS Document.PurchaseAdjustment).DocumentBasis AS LinkedDocument,
	|
	|	CASE WHEN VendorsARAPAccountingByDocuments.Prepayment < 0  THEN
	|		-VendorsARAPAccountingByDocuments.Prepayment 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.Prepayment
	|	END                                                           AS Prepayment,
	|	CASE WHEN VendorsARAPAccountingByDocuments.PrepaymentMan < 0  THEN
	|		-VendorsARAPAccountingByDocuments.PrepaymentMan 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.PrepaymentMan
	|	END                                                           AS PrepaymentMan,
	|	CASE WHEN VendorsARAPAccountingByDocuments.PrepaymentLocal < 0  THEN
	|		-VendorsARAPAccountingByDocuments.PrepaymentLocal 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.PrepaymentLocal
	|	END                                                           AS PrepaymentLocal,
	|	CASE WHEN VendorsARAPAccountingByDocuments.Debt < 0  THEN
	|		-VendorsARAPAccountingByDocuments.Debt 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.Debt
	|	END                                                           AS Debt,
	|	CASE WHEN VendorsARAPAccountingByDocuments.ARAPMan < 0  THEN
	|		-VendorsARAPAccountingByDocuments.ARAPMan 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.ARAPMan
	|	END                                                           AS ARAPMan,
	|	CASE WHEN VendorsARAPAccountingByDocuments.DebtLocal < 0  THEN
	|		-VendorsARAPAccountingByDocuments.DebtLocal 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.DebtLocal
	|	END                                                           AS DebtLocal,
	|
	|	CASE WHEN VendorsARAPAccountingByDocuments.Prepayment <> 0 THEN DATETIME(1,1,1)
	|		WHEN (RecordType = VALUE(AccumulationRecordType.Receipt) AND (VendorsARAPAccountingByDocuments.Debt < 0
	|				OR VendorsARAPAccountingByDocuments.DebtLocal < 0 OR VendorsARAPAccountingByDocuments.ARAPMan < 0
	|				OR VendorsARAPAccountingByDocuments.Prepayment > 0 OR VendorsARAPAccountingByDocuments.PrepaymentLocal > 0
	|				OR VendorsARAPAccountingByDocuments.PrepaymentMan > 0)
	|		OR RecordType = VALUE(AccumulationRecordType.Expense) AND (VendorsARAPAccountingByDocuments.Prepayment < 0
	|				OR VendorsARAPAccountingByDocuments.PrepaymentLocal < 0 OR VendorsARAPAccountingByDocuments.PrepaymentMan < 0
	|				OR VendorsARAPAccountingByDocuments.Debt > 0 OR VendorsARAPAccountingByDocuments.DebtLocal > 0 
	|				OR VendorsARAPAccountingByDocuments.ARAPMan > 0)) 
	|			AND NOT ((VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntry OR
	|					VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP) AND 
	|					VendorsARAPAccountingByDocuments.ARAPDocument <> UNDEFINED)
	|			AND NOT VendorsARAPAccountingByDocuments.Recorder REFS Document.ExchangeDifferenceCalculation THEN
	|			ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|	ELSE
	|		ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|	END                                                           AS PlannedRepaymentDate,
	|	ISNULL(DatesOfOccurrence.OccurrenceDate, DATETIME(1,1,1)) AS OccurrenceDate,
	|	ISNULL(OrderOfDocuments.OperationProcedure,"""")                AS OperationProcedure,
	|	ISNULL(DatesOfOccurrence.SettlementProcedureByPaymentDate,"""")     AS ProcedureForCreditingRegistrar,
	|	ISNULL(DatesOfOccurrence.SettlementProcedureByPaymentDate,"""")     AS SettlementProcedure,
	|	ISNULL(DatesOfOccurrence.DocumentCurrency,
	|		ISNULL(DatesOfOccurrence.DocumentCurrency,
	|			VALUE(Catalog.Currencies.EmptyRef)))              AS DocumentCurrency
	|INTO TTCalculations
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccountingByDocuments
	|		INNER JOIN TTBasicCalculationParameters AS BasicCalculationParameters
	|			ON VendorsARAPAccountingByDocuments.AccountingDimensionByPartners = BasicCalculationParameters.AccountingDimensionByPartners
	|				AND VendorsARAPAccountingByDocuments.PurchaseOrder = BasicCalculationParameters.ARAPObject
	|				AND VendorsARAPAccountingByDocuments.Currency = BasicCalculationParameters.Currency
	|		LEFT JOIN OrderOfDocuments AS OrderOfDocuments
	|			ON VendorsARAPAccountingByDocuments.Recorder = OrderOfDocuments.Recorder
	|				AND BEGINOFPERIOD(VendorsARAPAccountingByDocuments.Period,DAY) = OrderOfDocuments.Date
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON VendorsARAPAccountingByDocuments.ARAPDocument = DatesOfOccurrence.Recorder
	|WHERE
	|	(VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntry
	|		OR VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP)
	|	AND VendorsARAPAccountingByDocuments.Recorder <> VendorsARAPAccountingByDocuments.ARAPDocument
	|	AND (VendorsARAPAccountingByDocuments.Prepayment <> 0
	|		OR VendorsARAPAccountingByDocuments.PrepaymentLocal <> 0
	|		OR VendorsARAPAccountingByDocuments.PrepaymentMan <> 0
	|		OR VendorsARAPAccountingByDocuments.Debt <> 0
	|		OR VendorsARAPAccountingByDocuments.DebtLocal <> 0
	|		OR VendorsARAPAccountingByDocuments.ARAPMan <> 0)
	|	AND VendorsARAPAccountingByDocuments.Active
	|	
	|UNION ALL
	|
	|SELECT
	|	VendorsARAPAccountingByDocuments.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDocuments.PurchaseOrder                AS ARAPObject,
	|	VendorsARAPAccountingByDocuments.PurchaseOrder.ARAPObjectType AS ARAPObjectType,
	|	VendorsARAPAccountingByDocuments.Currency                         AS Currency,
	|	VendorsARAPAccountingByDocuments.Recorder                    AS DocumentRecorder,
	|	VendorsARAPAccountingByDocuments.ARAPDocument              AS ARAPDocument,
	|	VendorsARAPAccountingByDocuments.BusinessOperation          AS BusinessOperation,
	|	VendorsARAPAccountingByDocuments.CashFlowItem  AS CashFlowItem,
	|	VendorsARAPAccountingByDocuments.Period                         AS Period,
	|	CASE WHEN RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND NOT (VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|						AND VendorsARAPAccountingByDocuments.Prepayment > 0)
	|				AND (VendorsARAPAccountingByDocuments.Debt < 0
	|					OR VendorsARAPAccountingByDocuments.DebtLocal < 0 OR VendorsARAPAccountingByDocuments.ARAPMan < 0
	|					OR VendorsARAPAccountingByDocuments.Prepayment > 0 OR VendorsARAPAccountingByDocuments.PrepaymentLocal > 0
	|					OR VendorsARAPAccountingByDocuments.PrepaymentMan > 0 )
	|		OR RecordType = VALUE(AccumulationRecordType.Expense) 
	|				AND (VendorsARAPAccountingByDocuments.Prepayment < 0
	|					OR VendorsARAPAccountingByDocuments.PrepaymentLocal < 0 OR VendorsARAPAccountingByDocuments.PrepaymentMan < 0
	|					OR VendorsARAPAccountingByDocuments.Debt > 0 OR VendorsARAPAccountingByDocuments.DebtLocal > 0 
	|					OR VendorsARAPAccountingByDocuments.ARAPMan > 0
	|					OR VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|						AND VendorsARAPAccountingByDocuments.Prepayment > 0) THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END                                                           AS RecordType,
	|	CASE WHEN VendorsARAPAccountingByDocuments.Recorder REFS Document.PurchaseAdjustment 
	|		THEN CAST(VendorsARAPAccountingByDocuments.Recorder AS Document.PurchaseAdjustment).DocumentBasis
	|		ELSE CAST(VendorsARAPAccountingByDocuments.ARAPDocument AS Document.PurchaseAdjustment).DocumentBasis
	|	END AS LinkedDocument,
	|
	//Calculations based on documents were incorrectly reflected
	|	CASE WHEN VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|		AND VendorsARAPAccountingByDocuments.Prepayment > 0 
	|			THEN 0
	|		WHEN VendorsARAPAccountingByDocuments.Prepayment < 0  THEN
	|			-VendorsARAPAccountingByDocuments.Prepayment 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.Prepayment
	|	END                                                           AS Prepayment,
	|	CASE WHEN VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|		AND VendorsARAPAccountingByDocuments.PrepaymentMan > 0 
	|			THEN 0
	|		WHEN VendorsARAPAccountingByDocuments.PrepaymentMan < 0  THEN
	|			-VendorsARAPAccountingByDocuments.PrepaymentMan 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.PrepaymentMan
	|	END                                                           AS PrepaymentMan,
	|	CASE WHEN VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|		AND VendorsARAPAccountingByDocuments.PrepaymentLocal > 0 
	|			THEN 0
	|		WHEN VendorsARAPAccountingByDocuments.PrepaymentLocal < 0  THEN
	|			-VendorsARAPAccountingByDocuments.PrepaymentLocal 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.PrepaymentLocal
	|	END                                                           AS PrepaymentLocal,
	|	CASE WHEN VendorsARAPAccountingByDocuments.Debt < 0  THEN
	|		-VendorsARAPAccountingByDocuments.Debt 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.Debt
	|		+ CASE WHEN VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|			AND VendorsARAPAccountingByDocuments.Prepayment > 0
	|				THEN VendorsARAPAccountingByDocuments.Prepayment
	|			ELSE 0
	|		END
	|	END                                                           AS Debt,
	|	CASE WHEN VendorsARAPAccountingByDocuments.ARAPMan < 0  THEN
	|		-VendorsARAPAccountingByDocuments.ARAPMan 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.ARAPMan
	|		+ CASE WHEN VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|			AND VendorsARAPAccountingByDocuments.PrepaymentMan > 0
	|				THEN VendorsARAPAccountingByDocuments.PrepaymentMan
	|			ELSE 0
	|		END
	|	END                                                           AS ARAPMan,
	|	CASE WHEN VendorsARAPAccountingByDocuments.DebtLocal < 0  THEN
	|		-VendorsARAPAccountingByDocuments.DebtLocal 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.DebtLocal
	|		+ CASE WHEN VALUETYPE(VendorsARAPAccountingByDocuments.Recorder) IN (TYPE(Document.BankAccountReceiptNote),TYPE(Document.CashAccountReceiptNote))
	|			AND VendorsARAPAccountingByDocuments.PrepaymentLocal > 0
	|				THEN VendorsARAPAccountingByDocuments.PrepaymentLocal
	|			ELSE 0
	|		END
	|	END                                                           AS DebtLocal,
	|
	|	CASE WHEN VendorsARAPAccountingByDocuments.Prepayment <> 0 THEN DATETIME(1,1,1)
	|		WHEN (RecordType = VALUE(AccumulationRecordType.Receipt) AND 
	|				(VendorsARAPAccountingByDocuments.Prepayment > 0 OR VendorsARAPAccountingByDocuments.PrepaymentLocal > 0
	|				OR VendorsARAPAccountingByDocuments.PrepaymentMan > 0)
	|		OR RecordType = VALUE(AccumulationRecordType.Expense) AND 
	|				(VendorsARAPAccountingByDocuments.Debt > 0 OR VendorsARAPAccountingByDocuments.DebtLocal > 0 
	|				OR VendorsARAPAccountingByDocuments.ARAPMan > 0)) 
	|			AND NOT ((VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntry OR
	|					VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP) AND 
	|					VendorsARAPAccountingByDocuments.ARAPDocument <> UNDEFINED)
	|			AND NOT VendorsARAPAccountingByDocuments.Recorder REFS Document.ExchangeDifferenceCalculation THEN
	|			CASE
	|				WHEN ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1)) = DATETIME(1,1,1)
	|					THEN ISNULL(OrderOfDocuments.PaymentDate, DATETIME(1,1,1))
	|				ELSE ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|			END
	|	ELSE
	|		ISNULL(DatesOfOccurrence.PaymentDate, DATETIME(1,1,1))
	|	END                                                           AS PlannedRepaymentDate,
	|	ISNULL(DatesOfOccurrence.OccurrenceDate, DATETIME(1,1,1)) AS OccurrenceDate,
	|	ISNULL(OrderOfDocuments.OperationProcedure,"""")                AS OperationProcedure,
	|	ISNULL(OrderOfDocuments.SettlementProcedureByPaymentDate,"""")     AS ProcedureForCreditingRegistrar,
	|	ISNULL(DatesOfOccurrence.SettlementProcedureByPaymentDate,"""")     AS SettlementProcedure,
	|	ISNULL(DatesOfOccurrence.DocumentCurrency,
	|		ISNULL(OrderOfDocuments.DocumentCurrency,
	|			VALUE(Catalog.Currencies.EmptyRef)))              AS DocumentCurrency
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccountingByDocuments
	|		INNER JOIN TTBasicCalculationParameters AS BasicCalculationParameters
	|			ON VendorsARAPAccountingByDocuments.AccountingDimensionByPartners = BasicCalculationParameters.AccountingDimensionByPartners
	|				AND VendorsARAPAccountingByDocuments.PurchaseOrder = BasicCalculationParameters.ARAPObject
	|				AND VendorsARAPAccountingByDocuments.Currency = BasicCalculationParameters.Currency
	|		LEFT JOIN OrderOfDocuments AS OrderOfDocuments
	|			ON VendorsARAPAccountingByDocuments.Recorder = OrderOfDocuments.Recorder
	|				AND BEGINOFPERIOD(VendorsARAPAccountingByDocuments.Period,DAY) = OrderOfDocuments.Date
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON VendorsARAPAccountingByDocuments.ARAPDocument = DatesOfOccurrence.Recorder
	|WHERE
	|	(NOT (VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntry 
	|			OR VendorsARAPAccountingByDocuments.Recorder REFS Document.OBEntryARAP)
	|		OR VendorsARAPAccountingByDocuments.Recorder = VendorsARAPAccountingByDocuments.ARAPDocument)
	|	AND (VendorsARAPAccountingByDocuments.Prepayment <> 0
	|		OR VendorsARAPAccountingByDocuments.PrepaymentLocal <> 0
	|		OR VendorsARAPAccountingByDocuments.PrepaymentMan <> 0
	|		OR VendorsARAPAccountingByDocuments.Debt <> 0
	|		OR VendorsARAPAccountingByDocuments.DebtLocal <> 0
	|		OR VendorsARAPAccountingByDocuments.ARAPMan <> 0)
	|	AND VendorsARAPAccountingByDocuments.Active
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                AS ARAPObject,
	|	Calculations.Currency                        AS Currency,
	|	Calculations.DocumentRecorder           AS DocumentRecorder,
	|	Calculations.ARAPDocument             AS ARAPDocument,
	|	Calculations.BusinessOperation         AS BusinessOperation,
	|	Calculations.Period                        AS Period,
	|	Calculations.PlannedRepaymentDate        AS PlannedRepaymentDate,
	|	Calculations.OccurrenceDate             AS OccurrenceDate,
	|	Calculations.RecordType                   AS RecordType,
	|	SUM(Calculations.Prepayment)             AS Prepayment,
	|	SUM(Calculations.PrepaymentMan)          AS PrepaymentMan,
	|	SUM(Calculations.PrepaymentLocal)         AS PrepaymentLocal,
	|	SUM(Calculations.Debt)                   AS Debt,
	|	SUM(Calculations.ARAPMan)                AS ARAPMan,
	|	SUM(Calculations.DebtLocal)               AS DebtLocal,
	|	Calculations.LinkedDocument             AS LinkedDocument,
	|	Calculations.CashFlowItem AS CashFlowItem,
	|	Calculations.OperationProcedure               AS OperationProcedure,
	|	Calculations.SettlementProcedure                 AS SettlementProcedure,
	|	Calculations.DocumentCurrency               AS DocumentCurrency,
	|	Calculations.Organization                   AS Organization
	|FROM (
	|	SELECT
	|		PaymentOffsets.AccountingDimensionByPartners                            AS AccountingDimensionByPartners,
	|		PaymentOffsets.ARAPObject                                       AS ARAPObject,
	|		PaymentOffsets.Currency                                               AS Currency,
	|		PaymentOffsets.DocumentRecorder                                  AS DocumentRecorder,
	|		PaymentOffsets.DocumentRecorder                                  AS ARAPDocument,
	|		PaymentOffsets.BusinessOperation                                AS BusinessOperation,
	|		PaymentOffsets.Period                                               AS Period,
	|		DatesOfOccurrence.PaymentDate                                    AS PlannedRepaymentDate,
	|		PaymentOffsets.Period                                               AS OccurrenceDate,
	|		VALUE(AccumulationRecordType.Receipt)                           AS RecordType,
	|		0                                                                AS Prepayment,
	|		0                                                                AS PrepaymentMan,
	|		0                                                                AS PrepaymentLocal,
	|		PaymentOffsets.Prepayment                                           AS Debt,
	|		PaymentOffsets.PrepaymentMan                                        AS ARAPMan,
	|		PaymentOffsets.PrepaymentLocal                                       AS DebtLocal,
	|		UNDEFINED                                                     AS LinkedDocument,
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef)  AS CashFlowItem,
	|		PaymentOffsets.OperationProcedure                                      AS OperationProcedure,
	|		PaymentOffsets.ProcedureForCreditingRegistrar                            AS SettlementProcedure,
	|		PaymentOffsets.DocumentCurrency                                      AS DocumentCurrency,
	|		PaymentOffsets.AccountingDimensionByPartners.Organization                AS Organization
	|	FROM TTCalculations AS PaymentOffsets
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON PaymentOffsets.DocumentRecorder = DatesOfOccurrence.Recorder
	|	WHERE
	|		PaymentOffsets.Prepayment > 0 
	|		AND PaymentOffsets.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND PaymentOffsets.BusinessOperation NOT IN (&BusinessOperationsNotShipping)
	|		AND PaymentOffsets.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PaymentOffsets.AccountingDimensionByPartners                              AS AccountingDimensionByPartners,
	|		PaymentOffsets.ARAPObject                                         AS ARAPObject,
	|		PaymentOffsets.Currency                                                 AS Currency,
	|		PaymentOffsets.DocumentRecorder                                    AS DocumentRecorder,
	|		PaymentOffsets.DocumentRecorder                                    AS ARAPDocument,
	|		VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement) AS BusinessOperation,
	|		PaymentOffsets.Period                                                 AS Period,
	|		DatesOfOccurrence.PaymentDate                                      AS PlannedRepaymentDate,
	|		PaymentOffsets.Period                                                 AS OccurrenceDate,
	|		VALUE(AccumulationRecordType.Expense)                             AS RecordType,
	|		0                                                                  AS Prepayment,
	|		0                                                                  AS PrepaymentMan,
	|		0                                                                  AS PrepaymentLocal,
	|		PaymentOffsets.Prepayment                                             AS Debt,
	|		PaymentOffsets.PrepaymentMan                                          AS ARAPMan,
	|		PaymentOffsets.PrepaymentLocal                                         AS DebtLocal,
	|		UNDEFINED                                                       AS LinkedDocument,
	|		VALUE(Catalog.CashFlowReportItems.EmptyRef)    AS CashFlowItem,
	|		PaymentOffsets.OperationProcedure                                        AS OperationProcedure,
	|		PaymentOffsets.ProcedureForCreditingRegistrar                            AS SettlementProcedure,
	|		PaymentOffsets.DocumentCurrency                                        AS DocumentCurrency,
	|		PaymentOffsets.AccountingDimensionByPartners.Organization                  AS Organization
	|	FROM TTCalculations AS PaymentOffsets
	|		LEFT JOIN DatesOfOccurrence AS DatesOfOccurrence
	|			ON PaymentOffsets.DocumentRecorder = DatesOfOccurrence.Recorder
	|	WHERE
	|		PaymentOffsets.Prepayment > 0 
	|		AND PaymentOffsets.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND PaymentOffsets.BusinessOperation NOT IN (&BusinessOperationsNotShipping)
	|		AND PaymentOffsets.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.PaymentReturn)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CalculationsAccordingToDocuments.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
	|		CalculationsAccordingToDocuments.ARAPObject                AS ARAPObject,
	|		CalculationsAccordingToDocuments.Currency                        AS Currency,
	|		CalculationsAccordingToDocuments.DocumentRecorder           AS DocumentRecorder,
	|		CalculationsAccordingToDocuments.ARAPDocument             AS ARAPDocument,
	|		CASE WHEN CalculationsAccordingToDocuments.Prepayment <> 0 AND CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND CalculationsAccordingToDocuments.BusinessOperation NOT IN (VALUE(Enum.BusinessTransactions.ARAPSettlement),
	|					VALUE(Enum.BusinessTransactions.APWriteOff),
	|					VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
	|				THEN VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|			WHEN CalculationsAccordingToDocuments.Debt <> 0 AND CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND CalculationsAccordingToDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.ARAPSettlement)
	|				AND CalculationsAccordingToDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				AND CalculationsAccordingToDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				THEN VALUE(Enum.BusinessTransactions.AccountsPayableRepayment)
	|			ELSE CalculationsAccordingToDocuments.BusinessOperation 
	|		END AS BusinessOperation,
	|		CalculationsAccordingToDocuments.Period                        AS Period,
	|		CalculationsAccordingToDocuments.PlannedRepaymentDate        AS PlannedRepaymentDate,
	|		CalculationsAccordingToDocuments.OccurrenceDate             AS OccurrenceDate,
	|		CalculationsAccordingToDocuments.RecordType                   AS RecordType,
	|		CalculationsAccordingToDocuments.Prepayment                    AS Prepayment,
	|		CalculationsAccordingToDocuments.PrepaymentMan                 AS PrepaymentMan,
	|		CalculationsAccordingToDocuments.PrepaymentLocal                AS PrepaymentLocal,
	|		CalculationsAccordingToDocuments.Debt                          AS Debt,
	|		CalculationsAccordingToDocuments.ARAPMan                       AS ARAPMan,
	|		CalculationsAccordingToDocuments.DebtLocal                      AS DebtLocal,
	|		CASE WHEN (CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Receipt) AND CalculationsAccordingToDocuments.Prepayment > 0)
	|			OR (CalculationsAccordingToDocuments.RecordType = VALUE(AccumulationRecordType.Expense) AND CalculationsAccordingToDocuments.Debt > 0)
	|			THEN CalculationsAccordingToDocuments.LinkedDocument
	|			ELSE UNDEFINED
	|		END                                             AS LinkedDocument,
	|		CalculationsAccordingToDocuments.CashFlowItem AS CashFlowItem,
	|		CalculationsAccordingToDocuments.OperationProcedure               AS OperationProcedure,
	|		CalculationsAccordingToDocuments.SettlementProcedure                 AS SettlementProcedure,
	|		CalculationsAccordingToDocuments.DocumentCurrency               AS DocumentCurrency,
	|		CalculationsAccordingToDocuments.AccountingDimensionByPartners.Organization AS Organization
	|	FROM TTCalculations AS CalculationsAccordingToDocuments) AS Calculations
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.DocumentRecorder,
	|	Calculations.ARAPDocument,
	|	Calculations.BusinessOperation,
	|	Calculations.Period,
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.OccurrenceDate,
	|	Calculations.RecordType,
	|	Calculations.LinkedDocument,
	|	Calculations.CashFlowItem,
	|	Calculations.OperationProcedure,
	|	Calculations.SettlementProcedure,
	|	Calculations.DocumentCurrency,
	|	Calculations.Organization
	|;
	|DROP TTBasicCalculationParameters;
	|DROP TTRecorders_;
	|DROP OrderOfDocuments;
	|DROP DatesOfOccurrence;
	|DROP TTCalculations
	|";
	
EndFunction

// Deprecated.
Function NameOfLogEventWhenOnlineCalculationsAreEnabled()
	
	Return NStr("ru = 'Включение онлайн взаиморасчетов с партнерами.';
				|vi = 'Enable online mutual settlements with partners.';
				|en = 'Enable online mutual settlements with partners.'; fa = 'Enable online mutual settlements with partners.';
				|it = 'Attivazione online dei conti reciproci con i partner.';
				|pl = 'Włączenie online rozliczeń wzajemnych z partnerami.';
				|tr = 'İş ortakları ile çevrim içi mutabakatların etkinleştirilmesi.'", Common.DefaultLanguageCode());
	
EndFunction

Procedure TransferRegisterAdjustmentsATServer()
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryTextForTransferringRegisterAdjustments();
	
	PaymentType_ = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	TotalMoved = 0;
	TypeOfRegistrar = Type("DocumentRef.RegisterAdjustment");
	Type = 21;
	TypeOfOperationForSorting = "0";
	OrderOfOperationsWithinDocument = "1";
	While PaymentType_.Next() Do
		
		Adjusting = PaymentType_.Select(QueryResultIteration.ByGroups);
		While Adjusting.Next() Do
			BeginTransaction();
			Try
				If PaymentType_.TheseAreSettlementsWithCustomers Then
					RegisterName = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name;
					Set = AccumulationRegisters.CustomersARAPAccountingByDueDates.CreateRecordSet();
					Set.Filter.Recorder.Set(Adjusting.DocumentRecorder);
				Else
					RegisterName = Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name;
					Set = AccumulationRegisters.VendorsARAPAccountingByDueDates.CreateRecordSet();
					Set.Filter.Recorder.Set(Adjusting.DocumentRecorder);
				EndIf;
				AdjustmentDate = Adjusting.AdjustmentDate;
				AdjustmentNumber = Adjusting.AdjustmentNumber;
				AdjustingObject = Adjusting.DocumentRecorder.GetObject();
				If AdjustingObject.RegistersTable.Find(RegisterName) = Undefined Then
					NewRegister = AdjustingObject.RegistersTable.Add();
					NewRegister.Name = RegisterName;
				EndIf;
				RegisterRecords = Adjusting.Select(QueryResultIteration.ByGroups);
				While RegisterRecords.Next() Do
					
					PaymentDate = ?(ValueIsFilled(RegisterRecords.PaymentDate), RegisterRecords.PaymentDate, Date(3000,1,1));
					
					NewRecord = Set.Add();
					
					//Dimensions
					NewRecord.Period = RegisterRecords.Period;
					NewRecord.AccountingDimensionByPartners = RegisterRecords.AccountingDimensionByPartners;
					NewRecord.ARAPObject = RegisterRecords.ARAPObject;
					NewRecord.Currency = RegisterRecords.Currency;
					NewRecord.ARAPDocument = RegisterRecords.ARAPDocument;
					NewRecord.OccurrenceDate = RegisterRecords.APARDocumentDate;
					If NewRecord.Prepayment = 0 Then
						NewRecord.PlannedRepaymentDate = RegisterRecords.PaymentDate;
					EndIf;
					//Resources
					NewRecord.Prepayment = RegisterRecords.Prepayment;
					NewRecord.PrepaymentLocal = RegisterRecords.PrepaymentLocal;
					NewRecord.PrepaymentMan = RegisterRecords.PrepaymentMan;
					NewRecord.Debt = RegisterRecords.Debt;
					NewRecord.DebtLocal = RegisterRecords.DebtLocal;
					NewRecord.ARAPMan = RegisterRecords.ARAPMan;
					
					//Attributes
					NewRecord.CashFlowItem = RegisterRecords.CashFlowItem;
					NewRecord.BusinessOperation = RegisterRecords.BusinessOperation;
					NewRecord.DocumentRecorder = RegisterRecords.DocumentRecorder;
					
					NewRecord.OperationProcedure = OnlineARAPAccountingServer.Order(RegisterRecords.AdjustmentDate, RegisterRecords.AdjustmentNumber, Undefined, TypeOfOperationForSorting, Type, OrderOfOperationsWithinDocument);
					NewRecord.SettlementProcedure = OnlineARAPAccountingServer.Order(PaymentDate, RegisterRecords.AdjustmentNumber, Undefined, TypeOfOperationForSorting, Type);
					FillInTypeOfSettlementRecord(NewRecord, TypeOfRegistrar);
					
				EndDo;
				AdjustingObject.DataExchange.Load = True;
				AdjustingObject.Write();
				Set.DataExchange.Load = True;
				Set.Write();
				
				TotalMoved = TotalMoved + 1;
				CommitTransaction();
			Except
				RollbackTransaction();
				EventName = NameOfLogEventWhenOnlineCalculationsAreEnabled() 
							+ NStr("ru = 'Перенос Корректировки регистров.';
									|vi = 'Register adjustment transfer.';
									|en = 'Register adjustment transfer.'; fa = 'Register adjustment transfer.';
									|it = 'Register adjustment transfer.';
									|pl = 'Register adjustment transfer.';
									|tr = 'Kayıt düzeltmelerinin taşınması.'", Common.DefaultLanguageCode());
				Template = NStr("ru = 'Не удалось перенести Корректировку регистров %1 от %2 по причине:
				|%3';
				|vi = 'Cannot transfer the ""%1"" register adjustment dated %2. Reason:
				|%3';
				|en = 'Cannot transfer the ""%1"" register adjustment dated %2. Reason:
				|%3'; fa = 'Cannot transfer the ""%1"" register adjustment dated %2. Reason:
				|%3';
				|it = 'Cannot transfer the ""%1"" register adjustment dated %2. Reason:
				|%3';
				|pl = 'Cannot transfer the ""%1"" register adjustment dated %2. Reason:
				|%3';
				|tr = '%2 tarihli %1 kayıt tablosu düzeltmesi aktarılamadı, sebep:
				|%3'");
				Text = StringFunctionsClientServer.SubstituteParametersToString(Template, 
							AdjustmentNumber, Format(AdjustmentDate, "DF='dd-MM-yyyy'"), DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(EventName,EventLogLevel.Error,,, Text);
			EndTry;
		EndDo;//according to the documents
	
	EndDo;//by types of calculations
	
	Template = NStr("ru = 'Перенесено корректировок регистров';
					|vi = 'Transferred register adjustments';
					|en = 'Transferred register adjustments'; fa = 'Transferred register adjustments';
					|it = 'Transferred register adjustments';
					|pl = 'Transferred register adjustments';
					|tr = 'Kayıt tablosu düzeltmeleri aktarıldı'")+": %1";
	WriteLogEvent(NameOfLogEventWhenOnlineCalculationsAreEnabled(),
		EventLogLevel.Information,,,StrTemplate(Template, TotalMoved));
	
	
EndProcedure

Function QueryTextForTransferringRegisterAdjustments()
	
	Return 
	"SELECT
	|	TRUE                                                              AS TheseAreSettlementsWithCustomers,
	|	CustomersARAPAccountingByDocuments.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingByDocuments.SalesOrder                          AS ARAPObject,
	|	CustomersARAPAccountingByDocuments.SalesOrder.ARAPObjectType       AS ARAPObjectType,
	|	CustomersARAPAccountingByDocuments.Currency                                AS Currency,
	|	CustomersARAPAccountingByDocuments.Recorder                           AS DocumentRecorder,
	|	CustomersARAPAccountingByDocuments.Period                                AS Period,
	|	CustomersARAPAccountingByDocuments.ARAPDocument                     AS ARAPDocument,
	|	CustomersARAPAccountingByDocuments.BusinessOperation                 AS BusinessOperation,
	|	CustomersARAPAccountingByDocuments.CashFlowItem         AS CashFlowItem,
	|	CASE WHEN RecordType = VALUE(AccumulationRecordType.Receipt) 
	|			AND (CustomersARAPAccountingByDocuments.Debt > 0
	|				OR CustomersARAPAccountingByDocuments.DebtLocal > 0 OR CustomersARAPAccountingByDocuments.ARAPMan > 0
	|				OR CustomersARAPAccountingByDocuments.Prepayment < 0 OR CustomersARAPAccountingByDocuments.PrepaymentLocal < 0
	|				OR CustomersARAPAccountingByDocuments.PrepaymentMan < 0)
	|		OR RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND NOT (CustomersARAPAccountingByDocuments.Prepayment > 0
	|				OR CustomersARAPAccountingByDocuments.PrepaymentLocal > 0 OR CustomersARAPAccountingByDocuments.PrepaymentMan > 0
	|				OR CustomersARAPAccountingByDocuments.Debt < 0 OR CustomersARAPAccountingByDocuments.DebtLocal < 0 
	|				OR CustomersARAPAccountingByDocuments.ARAPMan < 0) THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END                                                               AS RecordType,
	|	CASE WHEN CustomersARAPAccountingByDocuments.Recorder REFS Document.SaleAdjustment 
	|		THEN CAST(CustomersARAPAccountingByDocuments.Recorder AS Document.SaleAdjustment).DocumentBasis
	|		ELSE CAST(CustomersARAPAccountingByDocuments.ARAPDocument AS Document.SaleAdjustment).DocumentBasis
	|	END AS LinkedDocument,
	|
	|	CASE 
	|		WHEN CustomersARAPAccountingByDocuments.Prepayment < 0
	|			THEN -CustomersARAPAccountingByDocuments.Prepayment 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.Prepayment
	|	END                                                               AS Prepayment,
	|	CASE 
	|		WHEN CustomersARAPAccountingByDocuments.PrepaymentMan < 0 
	|			THEN -CustomersARAPAccountingByDocuments.PrepaymentMan 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.PrepaymentMan
	|	END                                                               AS PrepaymentMan,
	|	CASE 
	|		WHEN CustomersARAPAccountingByDocuments.PrepaymentLocal < 0
	|			THEN -CustomersARAPAccountingByDocuments.PrepaymentLocal
	|	ELSE
	|		CustomersARAPAccountingByDocuments.PrepaymentLocal
	|	END                                                               AS PrepaymentLocal,
	|	CASE WHEN CustomersARAPAccountingByDocuments.Debt < 0 THEN
	|		-CustomersARAPAccountingByDocuments.Debt 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.Debt
	|	END                                                               AS Debt,
	|	CASE WHEN CustomersARAPAccountingByDocuments.ARAPMan < 0 THEN
	|		-CustomersARAPAccountingByDocuments.ARAPMan 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.ARAPMan
	|	END                                                               AS ARAPMan,
	|	CASE WHEN CustomersARAPAccountingByDocuments.DebtLocal < 0 THEN
	|		-CustomersARAPAccountingByDocuments.DebtLocal 
	|	ELSE
	|		CustomersARAPAccountingByDocuments.DebtLocal
	|	END                                                               AS DebtLocal,
	|	CustomersARAPAccountingByDocuments.PaymentDate                           AS PaymentDate,
	|	AdjustingEntries.Date                                                  AS AdjustmentDate,
	|	AdjustingEntries.Number                                                 AS AdjustmentNumber,
	|	ISNULL(Register3.IBDocumentDate,AdjustingEntries.Date)                 AS APARDocumentDate,
	|	ISNULL(Register3.IBDocumentNumber,AdjustingEntries.Number)               AS NumberOfARAPDocument
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccountingByDocuments
	|	INNER JOIN Document.RegisterAdjustment AS AdjustingEntries
	|	ON CustomersARAPAccountingByDocuments.Recorder = AdjustingEntries.Ref
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|	ON CustomersARAPAccountingByDocuments.ARAPDocument = Register3.Ref
	|	AND NOT Register3.AdditionalRecord
	|WHERE
	|	(CustomersARAPAccountingByDocuments.Prepayment <> 0
	|		OR CustomersARAPAccountingByDocuments.PrepaymentLocal <> 0
	|		OR CustomersARAPAccountingByDocuments.PrepaymentMan <> 0
	|		OR CustomersARAPAccountingByDocuments.Debt <> 0
	|		OR CustomersARAPAccountingByDocuments.DebtLocal <> 0
	|		OR CustomersARAPAccountingByDocuments.ARAPMan <> 0)
	|	AND CustomersARAPAccountingByDocuments.Active
	|
	|UNION ALL
	|
	|SELECT
	|	FALSE                                                            AS TheseAreSettlementsWithCustomers,
	|	VendorsARAPAccountingByDocuments.AccountingDimensionByPartners      AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDocuments.PurchaseOrder                AS ARAPObject,
	|	VendorsARAPAccountingByDocuments.PurchaseOrder.ARAPObjectType AS ARAPObjectType,
	|	VendorsARAPAccountingByDocuments.Currency                         AS Currency,
	|	VendorsARAPAccountingByDocuments.Recorder                    AS DocumentRecorder,
	|	VendorsARAPAccountingByDocuments.Period                         AS Period,
	|	VendorsARAPAccountingByDocuments.ARAPDocument              AS ARAPDocument,
	|	VendorsARAPAccountingByDocuments.BusinessOperation          AS BusinessOperation,
	|	VendorsARAPAccountingByDocuments.CashFlowItem  AS CashFlowItem,
	|	CASE WHEN RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND (VendorsARAPAccountingByDocuments.Debt < 0
	|					OR VendorsARAPAccountingByDocuments.DebtLocal < 0 OR VendorsARAPAccountingByDocuments.ARAPMan < 0
	|					OR VendorsARAPAccountingByDocuments.Prepayment > 0 
	|					OR VendorsARAPAccountingByDocuments.PrepaymentLocal > 0 OR VendorsARAPAccountingByDocuments.PrepaymentMan > 0 )
	|		OR RecordType = VALUE(AccumulationRecordType.Expense) 
	|				AND (VendorsARAPAccountingByDocuments.Prepayment < 0
	|					OR VendorsARAPAccountingByDocuments.PrepaymentLocal < 0 OR VendorsARAPAccountingByDocuments.PrepaymentMan < 0
	|					OR VendorsARAPAccountingByDocuments.Debt > 0 OR VendorsARAPAccountingByDocuments.DebtLocal > 0 
	|					OR VendorsARAPAccountingByDocuments.ARAPMan > 0) THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END                                                           AS RecordType,
	|	CASE WHEN VendorsARAPAccountingByDocuments.Recorder REFS Document.PurchaseAdjustment 
	|		THEN CAST(VendorsARAPAccountingByDocuments.Recorder AS Document.PurchaseAdjustment).DocumentBasis
	|		ELSE CAST(VendorsARAPAccountingByDocuments.ARAPDocument AS Document.PurchaseAdjustment).DocumentBasis
	|	END AS LinkedDocument,
	|
	|	CASE
	|		WHEN VendorsARAPAccountingByDocuments.Prepayment < 0  THEN
	|			-VendorsARAPAccountingByDocuments.Prepayment 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.Prepayment
	|	END                                                           AS Prepayment,
	|	CASE 
	|		WHEN VendorsARAPAccountingByDocuments.PrepaymentMan < 0  THEN
	|			-VendorsARAPAccountingByDocuments.PrepaymentMan 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.PrepaymentMan
	|	END                                                           AS PrepaymentMan,
	|	CASE
	|		WHEN VendorsARAPAccountingByDocuments.PrepaymentLocal < 0  THEN
	|			-VendorsARAPAccountingByDocuments.PrepaymentLocal 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.PrepaymentLocal
	|	END                                                           AS PrepaymentLocal,
	|	CASE WHEN VendorsARAPAccountingByDocuments.Debt < 0  THEN
	|		-VendorsARAPAccountingByDocuments.Debt 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.Debt
	|	END                                                           AS Debt,
	|	CASE WHEN VendorsARAPAccountingByDocuments.ARAPMan < 0  THEN
	|		-VendorsARAPAccountingByDocuments.ARAPMan 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.ARAPMan
	|	END                                                           AS ARAPMan,
	|	CASE WHEN VendorsARAPAccountingByDocuments.DebtLocal < 0  THEN
	|		-VendorsARAPAccountingByDocuments.DebtLocal 
	|	ELSE
	|		VendorsARAPAccountingByDocuments.DebtLocal
	|	END                                                           AS DebtLocal,
	|	VendorsARAPAccountingByDocuments.PaymentDate                    AS PaymentDate,
	|	AdjustingEntries.Date                                              AS AdjustmentDate,
	|	AdjustingEntries.Number                                             AS AdjustmentNumber,
	|	ISNULL(Register3.IBDocumentDate,AdjustingEntries.Date)             AS APARDocumentDate,
	|	ISNULL(Register3.IBDocumentNumber,AdjustingEntries.Number)           AS NumberOfARAPDocument
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccountingByDocuments
	|	INNER JOIN Document.RegisterAdjustment AS AdjustingEntries
	|	ON VendorsARAPAccountingByDocuments.Recorder = AdjustingEntries.Ref
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|	ON VendorsARAPAccountingByDocuments.ARAPDocument = Register3.Ref
	|	AND NOT Register3.AdditionalRecord
	|WHERE
	|	VendorsARAPAccountingByDocuments.Recorder REFS Document.RegisterAdjustment
	|	AND (VendorsARAPAccountingByDocuments.Prepayment <> 0
	|		OR VendorsARAPAccountingByDocuments.PrepaymentLocal <> 0
	|		OR VendorsARAPAccountingByDocuments.PrepaymentMan <> 0
	|		OR VendorsARAPAccountingByDocuments.Debt <> 0
	|		OR VendorsARAPAccountingByDocuments.DebtLocal <> 0
	|		OR VendorsARAPAccountingByDocuments.ARAPMan <> 0)
	|	AND VendorsARAPAccountingByDocuments.Active
	|TOTALS
	|	MAX(AdjustmentDate),
	|	MAX(AdjustmentNumber)
	|BY
	|	TheseAreSettlementsWithCustomers,
	|	DocumentRecorder";
	
EndFunction

#EndRegion

#Region ClearingSettlementRegisters

// Outdated. Clears settlement registers.
// 
// Parameters:
//  OnlyPlannedCalculations - Boolean - No need to clean up the actual calculations.
Procedure ClearSettlementRegisters(OnlyPlannedCalculations = False) Export
	
	ARAPAccountingInternal.ClearSettlementRegisters(OnlyPlannedCalculations);
		
EndProcedure

// Outdated. Clears the transferred calculation register.
Procedure ClearRegister(RegisterName, ProcessedItemsTotal = 0) Export
	
	ARAPAccountingInternal.ClearRegister(RegisterName, ProcessedItemsTotal) 
	
EndProcedure

//Outdated. Clears the transferred calculation register in several threads.
// 
// Parameters:
// 	RegisterName - String - Name of the accumulation register to clear
// Returns:
// 	Number - Number of registrars processed
//
Function PerformRegisterCleanupMultithreaded(RegisterName) Export
	
	Return ARAPAccountingInternal.PerformRegisterCleanupMultithreaded(RegisterName) 
	
EndFunction

//Outdated. Clears the transferred register of calculations by the registrar
Procedure ClearRegisterOfMutualSettlementsOnDocument(Recorder, RegisterName) Export
	
	ARAPAccountingInternal.ClearRegisterOfMutualSettlementsOnDocument(Recorder, RegisterName);
	
EndProcedure

//outdated.
Procedure DeleteDocumentEntries(Parameters, ResultAddress = Undefined) Export
	
	ARAPAccountingInternal.DeleteDocumentEntries(Parameters, ResultAddress);
	
EndProcedure

//outdated.
Procedure RemoveServiceLoggers(Parameters, ResultAddress = Undefined) Export
	
	ARAPAccountingInternal.RemoveServiceLoggers(Parameters, ResultAddress)
	
EndProcedure

#EndRegion

#Region AuxiliaryFunctions
// Deprecated.
Function MultithreadedProcessingOfTasksForDistributionOfCalculations(Parameters)
	
	ProcessingProcedure = Parameters.Procedure;
	DataParameters = Parameters.Data;
	ChunkSizeOfProcessingInSingleThread = Parameters.ChunkSizeOfProcessingInSingleThread;

	Threads = New Array;
	FreeThreadsCount = ARAPAccountingInternal.NumberOfSettlementsAllocationThreads();
	ObjectsCountForProcessing = ChunkSizeOfProcessingInSingleThread * FreeThreadsCount;
	DataParameters.LatestRecord = NewCursor();
	NumberOfRecordsProcessed = 0;
	NumberOfProcessedTasks = 0;
	While ObjectsCountForProcessing > 0 Do

		If FreeThreadsCount > 0 Then

			DataParameters.PortionSize = ChunkSizeOfProcessingInSingleThread * FreeThreadsCount;
			DataForProcessing = ARAPAccountingInternal.DataForProcessing(DataParameters, True);
			Tuples = DataForProcessing.Tuples;
			DataParameters.LatestRecord = NewCursor();
			If Tuples.Count() > 0 And DataForProcessing.LeftToProcess > 0 Then
				FillPropertyValues(DataParameters.LatestRecord, Tuples[Tuples.Count() - 1]);
			EndIf;

			DataParameters.PortionSize = 1;
			If Tuples.Count()/FreeThreadsCount > 1 Then
				PortionSize = Tuples.Count()/FreeThreadsCount;
				If Int(PortionSize) <> PortionSize Then
					DataParameters.PortionSize = Int(PortionSize) + 1;
				Else
					DataParameters.PortionSize = PortionSize;
				EndIf;
			EndIf;
			ObjectsCountForProcessing = DataForProcessing.LeftToProcess;
			While Tuples.Count() > 0 Do

				StreamData = SelectDataForStream(DataForProcessing, DataParameters.PortionSize);
				Stream = ARAPAccountingInternal.NewFlowDescription(ProcessingProcedure.Name);
				Stream.JobDescription = ProcessingProcedure.JobPresentation;
				Stream.ProcedureParameters.Insert("DataForProcessing_", StreamData.Jobs);
				Stream.ProcedureParameters.Insert("SupplementDistributeReceivers", True);
				For Each Parameter In ProcessingProcedure.Parameters Do
					Stream.ProcedureParameters.Insert(Parameter.Key, Parameter.Value);
				EndDo;
				ARAPAccountingInternal.StartProcessingInBackground(Stream);
				AddThreadTuples(Stream, DataParameters.TuplesInProcessing, StreamData.Tuples);
				NumberOfProcessedTasks = NumberOfProcessedTasks + StreamData.Jobs.Count();
				Threads.Add(Stream);

			EndDo;

		EndIf;

		ARAPAccountingInternal.WaitForThreadCompletion(Stream);

		ARAPAccountingInternal.StopThreadsWithCompletedBackgroundJobs(Threads, DataParameters.TuplesInProcessing, NumberOfRecordsProcessed);
		ThisIsLastPortion = DataParameters.LatestRecord.ARAPObject = Undefined;
		If ThisIsLastPortion Then
			ARAPAccountingInternal.WaitForAllThreadsCompletion(Threads, DataParameters.TuplesInProcessing, NumberOfRecordsProcessed);
		EndIf;

		NumberOfAvailableStreams = ARAPAccountingInternal.NumberOfSettlementsAllocationThreads();
		FreeThreadsCount = Max(NumberOfAvailableStreams - Threads.Count(), 0);

	EndDo;

	ARAPAccountingInternal.WaitForAllThreadsCompletion(Threads,,NumberOfRecordsProcessed);

	If NumberOfRecordsProcessed = 0 Then
		Return NumberOfProcessedTasks;
	EndIf;

	Return NumberOfRecordsProcessed;
	
EndFunction

// Deprecated.
Function ParametersOfMultithreadedProcessingOfCalculations(ChunkSizeInSingleStream = Undefined)
	
	Result = New Structure;
	
	ProcessingProcedure = New Structure;
	ProcessingProcedure.Insert("Name", "");
	ProcessingProcedure.Insert("JobPresentation", "");
	ProcessingProcedure.Insert("Parameters", New Structure);
	
	DataProcessorData = ARAPAccountingInternal.MultithreadedDataParameters();
	
	Result.Insert("ChunkSizeOfProcessingInSingleThread", ARAPAccountingInternal.ChunkSizeOfProcessingInSingleThread());
	If ChunkSizeInSingleStream <> Undefined Then
		Result.ChunkSizeOfProcessingInSingleThread = ChunkSizeInSingleStream;
	EndIf;
	Result.Insert("Procedure", ProcessingProcedure);
	Result.Insert("Data", DataProcessorData);
	
	Return Result;
	
EndFunction

// Deprecated.
Function NewCursor()
	
	LatestRecord = New Structure("DocumentsCount,AccountingDimensionByPartners,ARAPObject");
	LatestRecord.DocumentsCount = 0;
	
	Return LatestRecord;
	
EndFunction

// Deprecated.
Procedure AddThreadTuples(Stream,TuplesInProcessing,Tuples)
	
	If TuplesInProcessing = Undefined Then
		TuplesInProcessing = Tuples.Copy();
		TuplesInProcessing.FillValues(Stream.JobID,"ThreadID");
		Return;
	EndIf;
	
	For Each Tuple In Tuples Do
		NewRow = TuplesInProcessing.Add();
		FillPropertyValues(NewRow, Tuple);
		NewRow.ThreadID = Stream.JobID;
	EndDo;
	
EndProcedure

// Deprecated. The tuples with the largest number of documents are the first to be sent for processing.
// For a more uniform loading of threads and maximum parallelization of processing
// , such tuples are distributed evenly across all free threads,
// rather than assigning all the "heavy" ones to one processing thread.
//
Function SelectDataForStream(DataForProcessing_, PortionSize)
	
	TupleFields = "PaymentType_,AccountingDimensionByPartners,ARAPObject,Currency";
	Tuples = DataForProcessing_.Tuples;
	Jobs = DataForProcessing_.Data;
	ThreadAssignments = Jobs.CopyColumns();
	ThreadTuples = Jobs.CopyColumns(TupleFields);
	ThisIsLastPortion = Tuples.Count()/PortionSize <= 1;
	IndexOf = 0;
	While (ThreadTuples.Count() < PortionSize Or ThisIsLastPortion)
		And Tuples.Count() > 0 Do
		
		Tuple = Tuples[IndexOf];
		Filter = New Structure(TupleFields);
		FillPropertyValues(Filter,Tuple);
		RecordsToBeProcessed = Jobs.FindRows(Filter);
		For Each Record In RecordsToBeProcessed Do
			FillPropertyValues(ThreadAssignments.Add(), Record);
		EndDo;
		FillPropertyValues(ThreadTuples.Add(), Tuple);
		
		Tuples.Delete(Tuple);
		IndexOf = IndexOf + PortionSize;
		If IndexOf >= Tuples.Count() Then
			IndexOf = 0;
		EndIf;
	EndDo;
	
	StreamData = New Structure;
	StreamData.Insert("Jobs", ThreadAssignments);
	StreamData.Insert("Tuples", ThreadTuples);
	
	Return StreamData;
	
EndFunction

// Deprecated.
Procedure MarkTaskCompletion(FilterByDimensions, AdditionalSelectionDimensions = "") Export
	
	LineSelectionMeasurements =  
	"PaymentType_,
	|AccountingDimensionByPartners,
	|ARAPObject,
	|Currency,
	|Currency";
	If Not IsBlankString(AdditionalSelectionDimensions)  Then
		LineSelectionMeasurements = LineSelectionMeasurements + "," + AdditionalSelectionDimensions;
	EndIf;
	
	FilterDimensions = New Structure(LineSelectionMeasurements);
	FillPropertyValues(FilterDimensions, FilterByDimensions);
	
	Set = InformationRegisters.JobsForAllocatingARAP.CreateRecordSet();
	For Each Dimension In FilterDimensions Do
		If Dimension.Value <> Undefined Then
			DimensionName = ?(Dimension.Key = "Currency", "Currency", Dimension.Key);
			Set.Filter[DimensionName].Set(Dimension.Value);
		EndIf;
	EndDo;
	
	Set.Write();
	
EndProcedure

//For purposes of sorting documents within 1 second.
// 
// Parameters:
// 	DocumentType - Type - The type of document for which the number is selected.
// Returns:
// 	String - A number for the order.
Function TypeNumber(DocumentType) Export
	
	//	When adding a document, add it to the end with a new number, without changing the types of other documents.
	Type = "";
	
	If DocumentType = Type("DocumentRef.ExchangeDifferenceCalculation") Or DocumentType = Type("DocumentRef.ARAPAccountingRecorder")Then
		Type="99";
	ElsIf DocumentType = Type("DocumentRef.ExpenseReport") Then
		Type="01";
	ElsIf DocumentType = Type("DocumentRef.SalesOrder") Then
		Type="14";
	ElsIf DocumentType = Type("DocumentRef.PurchaseOrder") Then
		Type="16";
	ElsIf DocumentType = Type("DocumentRef.CustomerInvoice") Then
		Type="39";
	ElsIf DocumentType = Type("DocumentRef.VendorInvoice") Then
		Type="35";
	ElsIf DocumentType = Type("DocumentRef.CustomerInvoiceServices") Then
		Type="02";
	ElsIf DocumentType = Type("DocumentRef.BankAccountIssue") Then
		Type="41";
	ElsIf DocumentType = Type("DocumentRef.PaymentCardTransaction") Then
		Type="22";
	ElsIf DocumentType = Type("DocumentRef.BankAccountReceiptNote") Then
		Type="33";
	ElsIf DocumentType = Type("DocumentRef.OBEntry")
		Or DocumentType = Type("DocumentRef.OBEntryARAP") Then
		Type="03";
	ElsIf DocumentType = Type("DocumentRef.ARAPSettlement") Then
		Type="04";
	ElsIf DocumentType = Type("DocumentRef.IntercompanyGoodsReturn") Then
		Type="07";
	ElsIf DocumentType = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		Type="06";
	ElsIf DocumentType = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		Type="07";
	ElsIf DocumentType = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
		Type="09";
	ElsIf DocumentType = Type("DocumentRef.RedemptionOfReturnablePackagingFromVendor") Then
		Type="10";
	ElsIf DocumentType = Type("DocumentRef.ContractSchedule") Then
		Type="12";
	ElsIf DocumentType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		Type="17";
	ElsIf DocumentType = Type("DocumentRef.PaymentRequest") Then
		Type="18";
	ElsIf DocumentType = Type("DocumentRef.PurchaseAdjustment") Then
		Type="19";
	ElsIf DocumentType = Type("DocumentRef.SaleAdjustment") Then
		Type="20";
	ElsIf DocumentType = Type("DocumentRef.RegisterAdjustment") Then
		Type="21";
	ElsIf DocumentType = Type("DocumentRef.ConsignmentReportFromCustomer") Then
		Type="25";
	ElsIf DocumentType = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
		Type="26";
	ElsIf DocumentType = Type("DocumentRef.ConsignmentReportToVendor") Then
		Type="27";
	ElsIf DocumentType = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
		Type="28";
	ElsIf DocumentType = Type("DocumentRef.CommissionReportIntercompany") Then
		Type="30";
	ElsIf DocumentType = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
		Type="31";
	ElsIf DocumentType = Type("DocumentRef.CustomerInvoiceIntercompany") Then
		Type="32";
	ElsIf DocumentType = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		Type="36";
	ElsIf DocumentType = Type("DocumentRef.CashAccountReceiptNote") Then
		Type="37";
	ElsIf DocumentType = Type("DocumentRef.CashVoucher") Then
		Type="38";
	ElsIf DocumentType = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		Type="40";
	ElsIf DocumentType = Type("DocumentRef.ARAPAdjustment") Then
		Type="42";
	ElsIf DocumentType = Type("DocumentRef.CCDImport") Then
		Type="43";
	ElsIf DocumentType = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		Type="11";
	ElsIf DocumentType = Type("DocumentRef.SubcontractOrder2_5") Then
		Type="51";
	
	ElsIf DocumentType = Type("DocumentRef.SubcontractorReport2_5") Then
		Type="52";
	ElsIf DocumentType = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
		Type="45";
	ElsIf DocumentType = Type("DocumentRef.ReportOnVMIAdjustment") Then
		Type="46";
	ElsIf DocumentType = Type("DocumentRef.MaterialProviderOrder2_5") Then
		Type="53";
	ElsIf DocumentType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		Type="54";
	ElsIf DocumentType = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
		Type="55";
	ElsIf DocumentType = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
		 Type="47";
	ElsIf DocumentType = Type("DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5") Then
		Type="48";
	ElsIf DocumentType = Type("DocumentRef.ElectronicTicketTransaction") Then
		Type="49";
	ElsIf DocumentType = Type("DocumentRef.ReversingEntry") Then
		Type="50";
	ElsIf DocumentType = Type("DocumentRef.GiftCertificateCancellation") Then
		Type="56";
	ElsIf DocumentType = Type("DocumentRef.ReturnOfGiftCards") Then
		Type="57";
	ElsIf DocumentType = Type("DocumentRef.CustomerBonusCertificate") Then
		Type="58";
	ElsIf DocumentType = Type("DocumentRef.VendorBonusCertificate") Then
		Type="59";
	ElsIf DocumentType = Type("DocumentRef.GiftCertificateSale") Then
		Type="60";
	ElsIf DocumentType = Type("DocumentRef.RetailSalesReport") Then
		Type="61";
	ElsIf DocumentType = Type("DocumentRef.CashRegisterReceipt") Then
		Type="62";
	ElsIf DocumentType = Type("DocumentRef.GoodsReceiptFromCustomer") Then
		Type="63";
	ElsIf DocumentType = Type("DocumentRef.WriteOffOfShippedGoods") Then
		Type="64";
	ElsIf DocumentType = Type("DocumentRef.ARAPAccountingScheduleAdjustment") Then
		Type="65";
	ElsIf DocumentType = Type("DocumentRef.BankReportOnAcquiringTransactions") Then
		Type="66";
	ElsIf DocumentType = Type("DocumentRef.GoodsShipmentToCustomer") Then
		Type="67";
	EndIf;
	
	If Type = ""
		And Common.DebugMode() Then
		
		DetailErrorDescription = StrReplace(
			NStr("vi = 'Chưa xác định trình tự phân bổ kiểu chứng từ trong ngày %1.';
				|ru = 'Не определен порядок распределения типа документа в пределах дня %1.';
				|en = 'The order of document type distribution within the day %1 is not defined.'; fa = 'The order of document type distribution within the day %1 is not defined.';
				|it = 'Non è determinato l''ordine di suddivisione del tipo di documento entro un giorno %1.';
				|pl = 'Nie określono trybu podziału typu dokumentu wciągu dnia %1.';
				|tr = 'Belge tipinin %1 günü içindeki dağıtım sırası tanımlanmadı.'"),
			"%1",
			DocumentType);
			
		WriteLogEvent(NStr("vi = 'Hạch toán công nợ hoạt động với đối tác';
							|ru = 'Оперативные взаиморасчеты с контрагентами';
							|en = 'Real-time AR/AP with counterparties'; fa = 'Real-time AR/AP with counterparties';
							|it = 'Conti reciproci operativi con le controparti';
							|pl = 'Operacyjne rozliczenia wzajemne z kontrahentami';
							|tr = 'Cari hesaplarla operasyonel mutabakatlar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription);
			
		Raise DetailErrorDescription;
		
	Else
		Return Type;
	EndIf;
	
EndFunction

//Returns the implementation data structure to pass between service procedures.
//
// Returns:
//	Structure - implementation data structure.
//		* The sum of the amounts for adjustments - at the first mention, a record is formed with the initial amount, then payments and adjustments are deducted from it.
//		* The remaining amounts for calculating the average exchange rate and, probably, the formation of movements on the Amounts of documents in the regl currency.
Function SumStructure(DocumentAmount = 0, TheAmountOfTheDocumentRegl = 0, DocumentAmountManag = 0)
	SumStructure = New Structure;
	SumStructure.Insert("DocumentAmount", DocumentAmount);
	SumStructure.Insert("TheAmountOfTheDocumentRegl", TheAmountOfTheDocumentRegl);
	SumStructure.Insert("DocumentAmountManag", DocumentAmountManag);
	Return SumStructure;
EndFunction

//Returns the data structure for adjusting the settlement schedule to save the exchange rate and the date of occurrence
// during the transfer of scheduled repayment dates.
//
// Returns:
//	Structure - structure for storing expenditure amounts of schedule adjustments:
//	 * SumExpense - Number - the amount of debt expense or prepayment in the settlement currency.
//	 * LocalExpenseAmount - Number - the amount of debt expense or prepayment in the currency of regulated accounting.
//	 * AmountOfManSExpense - Number - the amount of debt expense or prepayment in the currency of management accounting.
//	 * OccurrenceDate - Date - The original date of the debt.
Function ChartAdjustmentDataStructure()
	StructureOfData = New Structure;
	StructureOfData.Insert("SumExpense", 0);
	StructureOfData.Insert("LocalExpenseAmount", 0);
	StructureOfData.Insert("AmountOfManSExpense", 0);
	StructureOfData.Insert("OccurrenceDate", Date(1,1,1));
	Return StructureOfData;
EndFunction

//Types of registrars that move the payment, shipment, and delivery plan to the parish.
//
// Returns:
// 	ValueList of Type - A list of document types that move only scheduled settlement registers. It is used for the distribution of planned calculations.
Function ListOfPlanRegistrarTypes() Export
	ListOfPlanRegistrarTypes = New ValueList;
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.SubcontractOrder2_5"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.SalesOrder"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.PurchaseOrder"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.ContractSchedule"));
	Return ListOfPlanRegistrarTypes;
EndFunction

//For these household operations, a double entry will not be created in the time calculation registers.
// 
// Returns:
// 	Array of EnumRef.BusinessTransactions - An array of operations for which you do not need to make an entry on the transfer of the advance.
//
Function BusinessOperationsNotShipping() Export
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.APWriteOff);
	Array.Add(Enums.BusinessTransactions.ARWriteOff);
	Array.Add(Enums.BusinessTransactions.AccrualOfAccountsPayable);
	Array.Add(Enums.BusinessTransactions.AccrualOfAccountsReceivable);
	Array.Add(Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance);
	Array.Add(Enums.BusinessTransactions.ReturnOfGoodsToVendor);
	Array.Add(Enums.BusinessTransactions.IntercompanyGoodsReturn);
	Array.Add(Enums.BusinessTransactions.ReserveCustomerPrepayment);
	Array.Add(Enums.BusinessTransactions.RefundToCustomer);
	Array.Add(Enums.BusinessTransactions.RefundToCustomerSPaymentCard);
	Array.Add(Enums.BusinessTransactions.RefundAcquiringPayment);
	Array.Add(Enums.BusinessTransactions.RefundFromVendor);
	Array.Add(Enums.BusinessTransactions.RefundToAnotherCompany);
	Array.Add(Enums.BusinessTransactions.RefundFromAnotherCompany);
	Array.Add(Enums.BusinessTransactions.RecordOfRefundThroughTheCommissionAgent);
	Array.Add(Enums.BusinessTransactions.BookingReturn);
	Array.Add(Enums.BusinessTransactions.UseBookingByAdvanceHolder);
	Array.Add(Enums.BusinessTransactions.RefundOfAdvanceHolderBooking);
	
	CommonClientServer.SupplementArray(Array, EconomicTransactionsOfTransferOfSettlements());
	
	Return Array;
EndFunction

//For these household operations, a double entry will not be generated in the time settlement registers, and the original business transaction will also be saved.
// 
// Returns:
// 	Array of EnumRef.BusinessTransactions - An array of operations for which you do not need to make an entry on the transfer of the advance.
//
Function EconomicTransactionsOfTransferOfSettlements()
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.ARAPSettlement);
	Array.Add(Enums.BusinessTransactions.SettlementOfPrepayment);
	Array.Add(Enums.BusinessTransactions.DebtTransfer);
	Array.Add(Enums.BusinessTransactions.PaymentTransferBetweenBranchOffices);
	Array.Add(Enums.BusinessTransactions.DebtTransferBetweenBranchOffices);
	Array.Add(Enums.BusinessTransactions.CommissionAgentSRemunerationDeduction);
	Array.Add(Enums.BusinessTransactions.RemunerationDeductionByConsignor);
	Array.Add(Enums.BusinessTransactions.AdjustCustomerPaymentSchedule);
	Array.Add(Enums.BusinessTransactions.AdjustVendorPaymentSchedule);
	Array.Add(Enums.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule);
	Array.Add(Enums.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule);
	Return Array;
EndFunction

//According to household data. all amounts in the currency of regulated and management accounting will not be recalculated against advances.
// 
// Returns:
// 	Array of EnumRef.BusinessTransactions - An array of unreadable operations.
Function BusinessOfOperationsWithManualCourse() Export
	Array = New Array;
	Array.Add(Enums.BusinessTransactions.ARAPSettlement);
	Array.Add(Enums.BusinessTransactions.ReceiptOfFinancialDocumentsFromVendor);
	Array.Add(Enums.BusinessTransactions.UseBookingByAdvanceHolder);
	Return Array;
EndFunction

// Deprecated. Returns the movement of documents Sales of goods and services with households. the operation is Goods in transit to movements
//that are suitable for offline settlements.
//
Procedure ReturnCustomersARAPAccountingRegisteredRecords()
	
	Query = New Query("
	|SELECT
	|	CustomersARAPAccounting.Recorder                  AS Recorder,
	|	MAX(CustomersARAPAccounting.Period)             AS MaximumPeriod
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment),
	|												VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer),
	|												VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|	AND VALUETYPE(CustomersARAPAccounting.Recorder) IN (TYPE(Document.CustomerInvoice),
	|													TYPE(Document.CustomerInvoiceServicesAndAssets))
	|	AND CustomersARAPAccounting.Sum <> 0
	|GROUP BY
	|	CustomersARAPAccounting.Recorder
	|HAVING
	|	COUNT(DISTINCT CustomersARAPAccounting.Period) > 1");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecordSet = AccumulationRegisters.CustomersARAPAccounting.CreateRecordSet();
		RecordSet.DataExchange.Load = True;
		RecordSet.Filter.Recorder.Set(Selection.Recorder);
		RecordSet.Read();
		For Each Record In RecordSet Do
			If Record.Sum <> 0 Then
				Record.Period = Selection.MaximumPeriod;
			EndIf;
		EndDo;
		RecordSet.Write();
	EndDo;
EndProcedure

// The default size of the settlement record portion.
// 
// Returns:
//  Number - The number of simultaneously recorded register entries under one service document by the Registrar.
Function RecordPortionSize() Export
	Return 1000;
EndFunction

Procedure WriteInPortions(CurrentVariables, RecordsTable, RecordSet) 
	
	RegisterName = RecordSet.Metadata().Name;
	
	For Each ARAPAccountingRecorder In CurrentVariables["ArrayOfLoggersInvolved"+RegisterName] Do
		
		RecordSet.Filter.Recorder.Set(ARAPAccountingRecorder);
		RecordSet.Load(RecordsTable.Copy(New Structure("Recorder", ARAPAccountingRecorder)));
		RecordSet.Write();
		
	EndDo;
	
	For Each StringOfFreeLoggers In CurrentVariables["ArrayOfFreeLoggers"+RegisterName] Do
		
		If StringOfFreeLoggers.CleaningRequired Then
			CurrentRegistrar = StringOfFreeLoggers.Ref; // DocumentRef.ARAPAccountingRecorder
			RecordSet.Filter.Recorder.Set(CurrentRegistrar);
			RecordSet.Clear();
			RecordSet.Write();
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PrepareDataToRecord(CurrentVariables, RecordsTable, RecordSet, TableOfFreeRegistrars)
	RecordPortionSize = RecordPortionSize();
	RegisterName = RecordSet.Metadata().Name;
	
	ArrayOfFreeLoggers = FreeSettlementRegistrars(CurrentVariables, RegisterName, RecordsTable.Count(), TableOfFreeRegistrars);
	ArrayOfLoggersInvolved = New Array;
	
	If ArrayOfFreeLoggers.Count() > 0 Then
		
		CurrentRow = 1;
		CurrentRegistrar = 0;
		
		ArrayOfFreeLoggers[CurrentRegistrar].CleaningRequired = False;
		ArrayOfLoggersInvolved.Add(ArrayOfFreeLoggers[CurrentRegistrar].Ref);
		
		For Each String In RecordsTable Do
			If TypeOf(String.DocumentRecorder) = Type("DocumentRef.RegisterAdjustment") Then
				Continue;
			EndIf;
			If CurrentRow > RecordPortionSize Then
				CurrentRow = 1;
				CurrentRegistrar = CurrentRegistrar + 1;
				ArrayOfFreeLoggers[CurrentRegistrar].CleaningRequired = False;
				ArrayOfLoggersInvolved.Add(ArrayOfFreeLoggers[CurrentRegistrar].Ref);
			EndIf;
			String.Recorder = ArrayOfFreeLoggers[CurrentRegistrar].Ref;
			
			CurrentRow = CurrentRow + 1;
		EndDo;
		
	EndIf;
	
	CurrentVariables.Insert("ArrayOfFreeLoggers" + RegisterName, ArrayOfFreeLoggers);
	CurrentVariables.Insert("ArrayOfLoggersInvolved" + RegisterName, ArrayOfLoggersInvolved);
EndProcedure

// Finds unused settlement loggers and deletes them
//
// Parameters:
//   Query - Query - Request with set parameters.
//   NameOfSettlementRegister - String
//   PaymentPlanRegisterName - String
//   ShippingPlanRegisterNameDelivery - String
//
Procedure RemoveUnusedSettlementLoggers(Query, NameOfSettlementRegister, PaymentPlanRegisterName, ShippingPlanRegisterNameDelivery)
	
	Query.Text = "
	|
	|SELECT
	|	ARAPAccountingRecorder.Ref AS Ref
	|FROM
	|	Document.ARAPAccountingRecorder AS ARAPAccountingRecorder
	|WHERE            
	|	ARAPAccountingRecorder.ARAPObject              = &ARAPObject
	|	AND ARAPAccountingRecorder.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|	AND ARAPAccountingRecorder.Currency                    = &Currency
	|	AND ARAPAccountingRecorder.PaymentType_               = &PaymentType_
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			&PaymentPlanTable_ AS PaymentPlanCalculations
	|		WHERE
	|			PaymentPlanCalculations.Recorder = ARAPAccountingRecorder.Ref
	|	)
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			&DeliveryShipmentPlanTable AS CalculationsShipmentPlanDeliveries
	|		WHERE
	|			CalculationsShipmentPlanDeliveries.Recorder = ARAPAccountingRecorder.Ref
	|	)
	|	AND NOT TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			&CalculationTable AS CalculationsByTerms
	|		WHERE
	|			CalculationsByTerms.Recorder = ARAPAccountingRecorder.Ref
	|	)
	|	
	|";
	
	Query.Text = StrReplace(Query.Text,"&CalculationTable", "AccumulationRegister." + NameOfSettlementRegister);
	Query.Text = StrReplace(Query.Text,"&DeliveryShipmentPlanTable", "AccumulationRegister." + ShippingPlanRegisterNameDelivery);
	Query.Text = StrReplace(Query.Text,"&PaymentPlanTable_", "AccumulationRegister." + PaymentPlanRegisterName);
	
	SelectionOfDocuments = Query.Execute().Select();
	
	While SelectionOfDocuments.Next() Do
		DocumentObject = SelectionOfDocuments.Ref.GetObject(); // DocumentObject.ARAPAccountingRecorder
		DocumentObject.Delete();
	EndDo;
	
EndProcedure

// Deprecated.
Procedure CalculateEverything(ExecutionParameters, StorageAddress) Export
	
	ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(ExecutionParameters.EndOfSettlementPeriod_, Undefined);
	ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(ExecutionParameters.EndOfSettlementPeriod_, Undefined);
	
EndProcedure

// Deprecated. Finds register adjustments based on the specified parameters, clears them and returns a new adjustment.
//
// Parameters:
//   AdjustmentPeriod_ - Date - All adjustments later than this date will be cleared, and with an equal date they will also be deleted.
//   Organization - CatalogRef.Companies
//   Operation - EnumRef.RegisterAdjustmentOperations
//
// Returns:
//   DocumentObject.RegisterAdjustment - An empty adjustment document, with the details filled in.
//
Function RegisterAdjustment(AdjustmentPeriod_, Organization, Operation) Export
	
	ARAPAccountingInternal.RegisterAdjustment(AdjustmentPeriod_, Organization, Operation);
	
EndFunction

// Collapses and leaves only significant changes, returning the table 
// 
// Parameters:
//  TempTablesManager - Undefined, TempTablesManager - Temporary table manager that contains temporary tables "Calculation of Change clients" or "Calculation of Change suppliers"
// 
// Returns:
//  ValueTable - See TableToDistribution - Transformed the table of changes into a table for distribution
Function TableOfChangesForRecalculation(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("TypesWithoutChangeCheck", ListOfPlanRegistrarTypes());
	Query.Text = "
	|SELECT
	|	NestedQuery.PaymentType_                      AS PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners        AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject                   AS ARAPObject,
	|	NestedQuery.Currency                           AS Currency,
	|	MAX(NestedQuery.ByDataOfSourceARAPObject) AS ByDataOfSourceARAPObject,
	|	MIN(NestedQuery.RecalculationStartDate)     AS RecalculationStartDate,
	|	MIN(NestedQuery.PeriodForMonitoringChangesAndCreatingTasks) AS PeriodForMonitoringChangesAndCreatingTasks
	|FROM 
	|	&ChangesTable AS NestedQuery
	|GROUP BY
	|	NestedQuery.PaymentType_,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.Currency
	|";
	
	NestedRequestTexts = New Array;
	If TempTablesManager.Tables.Find("SettlementsWithCustomersChanges") <> Undefined Then
		
		NestedRequestTexts.Add("
		|	SELECT
		|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)                 AS PaymentType_,
		|		Changes.AccountingDimensionByPartners                                             AS AccountingDimensionByPartners,
		|		Changes.ARAPObject                                                        AS ARAPObject,
		|		Changes.Currency                                                                AS Currency,
		|		Changes.ByDataOfSourceARAPObject                                      AS ByDataOfSourceARAPObject,
		|		BEGINOFPERIOD(
		|			CASE WHEN Changes.Sum = 0
		|					AND (Changes.AmountDue <> 0 OR Changes.ToShip <> 0)
		|					AND VALUETYPE(Changes.Document) <> TYPE(Document.OBEntry)
		|					AND VALUETYPE(Changes.Document) <> TYPE(Document.OBEntryARAP)
		|				THEN Changes.RecorderDate
		|				ELSE Changes.Period
		|			END, DAY)                                                                AS RecalculationStartDate,
		|		CASE
		|			WHEN VALUETYPE(Changes.Document) IN (&TypesWithoutChangeCheck)
		|				THEN DATETIME(3999,1,1)
		|			ELSE BEGINOFPERIOD(Changes.Period, DAY)
		|		END                                                                           AS PeriodForMonitoringChangesAndCreatingTasks
		|	FROM
		|		SettlementsWithCustomersChanges AS Changes
		|	WHERE
		|		Changes.Sum <> 0 OR Changes.SumCompl <> 0 OR Changes.SumMan<> 0 OR Changes.AmountDue <> 0 OR Changes.ToShip <> 0
		|
		|");
		
	EndIf;
	
	If TempTablesManager.Tables.Find("SettlementsWithCustomersChanges") <> Undefined
		And TempTablesManager.Tables.Find("VendorsARAPAccountingChanges") <> Undefined Then
		NestedRequestTexts.Add("
		|	
		|	UNION ALL
		|");
	EndIf;
	
	If TempTablesManager.Tables.Find("VendorsARAPAccountingChanges") <> Undefined Then
		
		NestedRequestTexts.Add("
		|	SELECT
		|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)              AS PaymentType_,
		|		Changes.AccountingDimensionByPartners                                             AS AccountingDimensionByPartners,
		|		Changes.ARAPObject                                                        AS ARAPObject,
		|		Changes.Currency                                                                AS Currency,
		|		Changes.ByDataOfSourceARAPObject                                      AS ByDataOfSourceARAPObject,
		|		BEGINOFPERIOD(
		|			CASE WHEN Changes.Sum = 0
		|					AND (Changes.AmountDue <> 0 OR Changes.ToReceive <> 0)
		|					AND VALUETYPE(Changes.Document) <> TYPE(Document.OBEntry)
		|					AND VALUETYPE(Changes.Document) <> TYPE(Document.OBEntryARAP)
		|				THEN Changes.RecorderDate
		|				ELSE Changes.Period
		|			END, DAY)                                                                AS RecalculationStartDate,
		|		CASE
		|			WHEN VALUETYPE(Changes.Document) IN (&TypesWithoutChangeCheck)
		|				THEN DATETIME(3999,1,1)
		|			ELSE BEGINOFPERIOD(Changes.Period, DAY)
		|		END                                                                           AS PeriodForMonitoringChangesAndCreatingTasks
		|	FROM
		|		VendorsARAPAccountingChanges AS Changes
		|	WHERE
		|		Changes.Sum <> 0 OR Changes.SumCompl <> 0 OR Changes.SumMan<> 0 OR Changes.AmountDue <> 0 OR Changes.ToReceive <> 0
		|
		|");
		
	EndIf;
	
	If NestedRequestTexts.Count() = 0 Then 
		Return TableToDistribution(); 
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&ChangesTable", StrTemplate("(%1)", StrConcat(NestedRequestTexts)));
	
	ChangesTable = Query.Execute().Unload();
	
	Return ChangesTable;
	
EndFunction

// Tired. Returns the structure of the parameters required for document registration to the deferred distribution of calculations.
// 
// Returns:
// 	Structure - LongDesc:
//  *TheseAreSettlementsWithCustomers - Boolean - True if these are payments to customers.
//  *RevaluationByDays - Boolean - The truth is if it is necessary to reevaluate every day, otherwise only on the days of payment.
//  *ReFillingTARegisters - Boolean - True if the calculation of coursework for TA is performed.
//
Function RevaluationParameters(TheseAreSettlementsWithCustomers = Undefined, RevaluationByDays = Undefined) Export
	
	Return ARAPAccountingRevaluationServer.RevaluationParameters(TheseAreSettlementsWithCustomers, RevaluationByDays);
	
EndFunction

// Tired.
Procedure RestartRevsTA(Organization, Period, TheseAreSettlementsWithCustomers) Export
	RestartRevsTA(Organization, Period, TheseAreSettlementsWithCustomers)
EndProcedure

Function DebitedAmount(Rate, AmountInCurrency, AmountARAP, AmountToBeDebited_)
	
	If AmountToBeDebited_ = AmountARAP Then
		Return AmountInCurrency;
	ElsIf AmountInCurrency = 0 Or AmountARAP = 0 Then
		Return 0;
	Else
		If Rate = 0 Then
			If AmountInCurrency > AmountARAP Then
				Return Round(AmountInCurrency / AmountARAP * AmountToBeDebited_, 2);
			Else
				Return Round(AmountToBeDebited_ / (AmountARAP/AmountInCurrency), 2);
			EndIf;
		Else
			Return Round(Rate * AmountToBeDebited_,2);
		EndIf;
	EndIf;
	
EndFunction

Procedure CreateTableOfDatesForPeriod(TempTablesManager, TempTableName, StartDate, EndDate)
	
	If Not ValueIsFilled(StartDate) Or StartDate<Date(1980,1,1) Then
		Raise(NStr("vi = 'Chưa điền ngày bắt đầu giới hạn tỷ giá.';
					|ru = 'Не заполнена дата начала границы курсов.';
					|en = 'Start date of the rate boundary is not filled.'; fa = 'Start date of the rate boundary is not filled.';
					|it = 'Не заполнена дата начала границы курсов.';
					|pl = 'Start date of the rate boundary is not filled.';
					|tr = 'Kur sınırının başlangıç ​​tarihi doldurulmadı.'"));
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT 0 AS Step
	|INTO TableOfInitialFigures
	|UNION ALL
	|SELECT 1
	|UNION ALL
	|SELECT 2
	|UNION ALL
	|SELECT 3
	|UNION ALL
	|SELECT 4
	|UNION ALL
	|SELECT 5
	|UNION ALL
	|SELECT 6
	|UNION ALL
	|SELECT 7
	|UNION ALL
	|SELECT 8
	|UNION ALL
	|SELECT 9
	|INDEX BY
	|	Step
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfInitialFigures1.Step * 1000 + TableOfInitialFigures2.Step * 100 + TableOfInitialFigures3.Step * 10 + TableOfInitialFigures4.Step AS Counter
	|INTO TableCounter
	|FROM
	|	TableOfInitialFigures AS TableOfInitialFigures1,
	|	TableOfInitialFigures AS TableOfInitialFigures2,
	|	TableOfInitialFigures AS TableOfInitialFigures3,
	|	TableOfInitialFigures AS TableOfInitialFigures4
	|WHERE
	|	(TableOfInitialFigures1.Step * 1000 + TableOfInitialFigures2.Step * 100 + TableOfInitialFigures3.Step * 10 + TableOfInitialFigures4.Step) <= DATEDIFF(&StartDate,&EndDate,DAY)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DATEADD(&StartDate, DAY, TableCounter.Counter) AS Date
	|INTO TTName
	|FROM
	|	TableCounter AS TableCounter
	|INDEX BY
	|	Date
	|";
	
	Query.SetParameter("StartDate",BegOfDay(StartDate));
	Query.SetParameter("EndDate",BegOfDay(EndDate));
	Query.Text = StrReplace(Query.Text,"TTName",TempTableName);
	Query.Execute();
	
EndProcedure

// Deprecated. The Query Text for obtaining the number of entries in the operational registers of mutual settlements.
// 
// Parameters:
//  NameOfTableToProcess - String - name of the temporary table:
// * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners
// * ARAPObject - CatalogRef.ARAPObjects
// * Currency - CatalogRef.Currencies
// * PaymentType_ - EnumRef.PartnersARAPAccountingTypes 
// 
// Returns:
//  String -  Query text
//
Function QueryTextNumberOfEntriesInOnlineSettlementRegisters(NameOfTableToProcess) Export

		QueryText = "
		|SELECT
		|	TTToProcess.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	TTToProcess.ARAPObject AS ARAPObject,
		|	TTToProcess.Currency AS Currency,
		|	SUM(RegisterNumberOfEntries.RecordsCount) AS RecordsCount
		|FROM
		|	TTDataToProcess AS TTToProcess
		|		INNER JOIN InformationRegister.NumberOfRecordsOfARAPRecorders AS RegisterNumberOfEntries
		|		ON TTToProcess.AccountingDimensionByPartners = RegisterNumberOfEntries.AccountingDimensionByPartners
		|		AND TTToProcess.ARAPObject = RegisterNumberOfEntries.ARAPObject
		|		AND TTToProcess.Currency = RegisterNumberOfEntries.Currency
		|GROUP BY
		|	TTToProcess.AccountingDimensionByPartners,
		|	TTToProcess.ARAPObject,
		|	TTToProcess.Currency";

	QueryText = StrReplace(QueryText, "TTDataToProcess AS TTToProcess", NameOfTableToProcess + " AS TTToProcess");
	
	Return QueryText;

EndFunction

// Deprecated. Generate data processing portions of the calculation registers.
// 
// Parameters:
//  DataForProcessing_ - ValueTable - :
// * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - 
// * ARAPObject - CatalogRef.ARAPObjects - 
// * Currency - CatalogRef.Currencies - 
//  RecordProcessingPortionSize - Number - The number of entries per batch to be processed
// 
// Returns:
//  Number - number of servings
//
Function GeneratePortionsOfDataProcessingRegistersOfMutualSettlements(DataForProcessing_, RecordProcessingPortionSize = 1000) Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	Data.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Data.ARAPObject AS ARAPObject,
	|	Data.Currency AS Currency
	|INTO TTDataToProcess
	|FROM
	|	&DataForProcessing_ AS Data
	|
	|INDEX BY
	|	ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataToProcess.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTDataToProcess.Currency AS Currency,
	|	TTDataToProcess.ARAPObject AS ARAPObject,
	|	CASE
	|		WHEN ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract)
	|			THEN 100
	|		ELSE 1
	|	END AS WeightFactorOfProcessing
	|FROM
	|	TTDataToProcess AS TTDataToProcess
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON TTDataToProcess.ARAPObject = ARAPObjects.Ref";
	Query.SetParameter("DataForProcessing_", DataForProcessing_);
	WeightingFactorsOfRecordProcessing = Query.Execute().Unload();
	WeightingFactorsOfRecordProcessing.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
	
	If DataForProcessing_.Columns.Find("ProcessingProcedure_") = Undefined Then
		DataForProcessing_.Columns.Add("ProcessingProcedure_", Common.TypeDescriptionNumber(15, 0));
		DataForProcessing_.Indexes.Add("ProcessingProcedure_");
	EndIf;
	
	CurPortionSize = 0;
	ProcessingProcedure_ = 1;
	
	For Each RecordingForProcessing In DataForProcessing_ Do

		FilterStructure1 = New Structure;
		FilterStructure1.Insert("AccountingDimensionByPartners", RecordingForProcessing.AccountingDimensionByPartners);
		FilterStructure1.Insert("ARAPObject", RecordingForProcessing.ARAPObject);
		FilterStructure1.Insert("Currency", RecordingForProcessing.Currency);

		RecordsForARAPObject = WeightingFactorsOfRecordProcessing.FindRows(FilterStructure1);
		WeightFactorOfProcessing = ?(RecordsForARAPObject.Count() > 0,
			RecordsForARAPObject[0].WeightFactorOfProcessing, 0);

		If Not CurPortionSize = 0 And (CurPortionSize + WeightFactorOfProcessing) > RecordProcessingPortionSize Then

			ProcessingProcedure_ = ProcessingProcedure_ + 1;
			CurPortionSize = 0;

		EndIf;

		RecordingForProcessing.ProcessingProcedure_ = ProcessingProcedure_;
		CurPortionSize = CurPortionSize + WeightFactorOfProcessing;

	EndDo;
	
	Return ProcessingProcedure_;

EndFunction

// Deprecated. Clears operational settlement registers and deletes service registrars.
// 
// Parameters:
//  ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
//  AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting analytics by partners
Procedure ClearSettlementRegistersAndDeleteServiceRecorders(ARAPObject = Undefined, AccountingDimensionByPartners = Undefined) Export
	
	ARAPAccountingInternal.ClearSettlementRegistersAndDeleteServiceRecorders(ARAPObject, AccountingDimensionByPartners);
	
EndProcedure

Function SettlementRecordType(TableEntry)
	
	ThisIsPrepayment = (TableEntry.Prepayment <> Undefined
			Or TableEntry.PrepaymentMan <> Undefined
			Or TableEntry.PrepaymentLocal <> Undefined)
		And (TableEntry.Prepayment <> 0
			Or TableEntry.PrepaymentMan <> 0 
			Or TableEntry.PrepaymentLocal <> 0);
	
	Return Enums.TypesOfSettlementRecords.TypeOfRecordOfOperation(
		TableEntry.SettlementTransaction,
		ThisIsPrepayment,
		TableEntry.RecordType);
	
EndFunction

Function ListOfTypesThatRefinePlans()
	ListOfPlanRegistrarTypes = New ValueList;
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.SubcontractorReport2_5"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.CustomerInvoiceServices"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.CustomerInvoice"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.PurchasingReportToConsignorPrincipal"));
	
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.VendorInvoice"));
	
	//specify the schedule of the Contract
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.ReturnablePackagingRedemptionByCustomer"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.RedemptionOfGoodsByCustodian"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.ElectronicTicketTransaction"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.RedemptionOfReturnablePackagingFromVendor"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.RedemptionOfGoodsFromStorage"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.ReportOnVMIAdjustment"));
	ListOfPlanRegistrarTypes.Add(Type("DocumentRef.CCDImport"));
	
	Return ListOfPlanRegistrarTypes;
	
EndFunction

#EndRegion

#Region HandlerForUpdatesByTypesOfSettlementRecords

// Deprecated. Delete in the next LTS. Fills in the type field of the recordingrecounts in the transmitted Registered Record line
//
// Parameters:
//  Record - ValueTableRow - Time-based Registered Records
//  TypeOfRegistrar - Type - Type of registrar's document
//
Procedure FillInTypeOfSettlementRecord(Record, TypeOfRegistrar) Export
	
	If Record.RecordType = AccumulationRecordType.Receipt And Not Record.ReversingEntry
		Or Record.RecordType = AccumulationRecordType.Expense And Record.ReversingEntry Then
		If Record.Prepayment <> 0 Then
			If (ThisIsDebtAdjustment(Record.BusinessOperation)
				And Not TypeOfRegistrar = Type("DocumentRef.SaleAdjustment")
				And Not TypeOfRegistrar = Type("DocumentRef.PurchaseAdjustment"))
				Or TypeOfRegistrar = Type("DocumentRef.ARAPAdjustment")
				Or Not ValueIsFilled(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ElectronicTicketTransaction")
					And Record.BusinessOperation = Enums.BusinessTransactions.VendorPrepaymentSettlement Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease;
			ElsIf ThisIsTransferOfMutualSettlements(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ARAPSettlement") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease;
			ElsIf ThisIsAdjustmentOfInvoice(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.SaleAdjustment")
				Or TypeOfRegistrar = Type("DocumentRef.PurchaseAdjustment") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease;
			ElsIf ThisIsPayment(Record.BusinessOperation, True) Then 
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.PaymentPrepaymentIncrease;
			ElsIf Record.ReversingEntry Or TypeOfRegistrar = Type("DocumentRef.ElectronicTicketTransaction")
				And (Record.BusinessOperation = Enums.BusinessTransactions.CustomerPrepaymentSettlement
					Or Record.BusinessOperation = Enums.BusinessTransactions.VendorPrepaymentSettlement) Then
				// Set-off of payment that occurs when the storno
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease;
			ElsIf TypeOf(Record.Recorder) = Type("DocumentRef.RegisterAdjustment") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease;
			Else
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease;
			EndIf;
		ElsIf Record.Debt <> 0 Then 
			If ThisIsRefund(Record.BusinessOperation) Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.RefundIncreasesDebt;
			ElsIf ThisIsTransferOfMutualSettlements(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ARAPSettlement") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.TransferOfSettlementsDebtIncrease;
			ElsIf ThisIsShipment(Record.BusinessOperation) Then 
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.ShipmentDebtIncrease;
			ElsIf ThisIsAdjustmentOfInvoice(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.SaleAdjustment")
				Or TypeOfRegistrar = Type("DocumentRef.PurchaseAdjustment") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfInvoiceDebtIncrease;
			ElsIf ThisIsDebtAdjustment(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ARAPAdjustment")
				Or Not ValueIsFilled(Record.BusinessOperation) Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease;
			ElsIf Record.ReversingEntry Or TypeOfRegistrar = Type("DocumentRef.ElectronicTicketTransaction")
				And (Record.BusinessOperation = Enums.BusinessTransactions.CustomerPrepaymentSettlement
					Or Record.BusinessOperation = Enums.BusinessTransactions.VendorPrepaymentSettlement) Then
				// Set-off of payment that occurs when the storno
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.TransferOfSettlementsDebtIncrease;
			ElsIf TypeOf(Record.Recorder) = Type("DocumentRef.RegisterAdjustment") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease;
			Else
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease;
			EndIf;
		ElsIf Record.PrepaymentMan <> 0 Or Record.PrepaymentLocal <> 0 Then
			Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease;
		Else
			Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease;
		EndIf;
	Else
		If Record.Prepayment <> 0 Then
			If ThisIsRefund(Record.BusinessOperation) Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.RefundDecreasesPrepayment;
			ElsIf ThisIsDebtAdjustment(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ARAPAdjustment")
				Or Not ValueIsFilled(Record.BusinessOperation) Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease;
			ElsIf ThisIsTransferOfMutualSettlements(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ARAPSettlement") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentDecrease;
			ElsIf ThisIsShipment(Record.BusinessOperation) Then
				If Record.ReversingEntry Then
					// For storno, we reflect the set-off of payment as an adjustment of the invoice
					Record.SettlementRecordType = Enums.TypesOfSettlementRecords.InvoiceAdjustmentPrepaymentDecrease;
				Else
					Record.SettlementRecordType = Enums.TypesOfSettlementRecords.ShipmentPrepaymentDecrease;
				EndIf;
			ElsIf ThisIsAdjustmentOfInvoice(Record.BusinessOperation) Then

				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.ShipmentPrepaymentDecrease;
			ElsIf TypeOf(Record.Recorder) = Type("DocumentRef.RegisterAdjustment") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.InvoiceAdjustmentPrepaymentDecrease;
			Else
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease;
			EndIf;
		ElsIf Record.Debt <> 0 Then
			If ThisIsRefund(Record.BusinessOperation) Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.RefundDecreasesDebt;
			ElsIf ThisIsPayment(Record.BusinessOperation)
				And Not TypeOfRegistrar = Type("DocumentRef.ReturnOfGoodsFromCustomer") 
				And Not TypeOfRegistrar = Type("DocumentRef.ReturnOfGoodsToVendor") 
				And Not TypeOfRegistrar = Type("DocumentRef.IntercompanyGoodsReturn")
				And Not TypeOfRegistrar = Type("DocumentRef.ARAPAdjustment")
				And Not TypeOfRegistrar = Type("DocumentRef.SaleAdjustment") 
				And Not TypeOfRegistrar = Type("DocumentRef.PurchaseAdjustment") 
				And Not TypeOfRegistrar = Type("DocumentRef.ARAPSettlement") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.PaymentDebtDecrease;
			ElsIf ThisIsTransferOfMutualSettlements(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ARAPSettlement") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.TransferOfSettlementsDebtDecrease;
			ElsIf ThisIsShipment(Record.BusinessOperation) Then
				If Record.ReversingEntry Then
					Record.SettlementRecordType = Enums.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease;
				Else
					Record.SettlementRecordType = Enums.TypesOfSettlementRecords.ShipmentDebtDecrease;
				EndIf;
			ElsIf ThisIsAdjustmentOfInvoice(Record.BusinessOperation)
				And Not TypeOfRegistrar = Type("DocumentRef.ARAPAdjustment")
				Or TypeOfRegistrar = Type("DocumentRef.SaleAdjustment")
				Or TypeOfRegistrar = Type("DocumentRef.PurchaseAdjustment") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease;
			ElsIf ThisIsDebtAdjustment(Record.BusinessOperation)
				Or TypeOfRegistrar = Type("DocumentRef.ARAPAdjustment") 
				Or Not ValueIsFilled(Record.BusinessOperation) Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;
			ElsIf TypeOf(Record.Recorder) = Type("DocumentRef.RegisterAdjustment") Then
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;
			Else
				Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;
			EndIf;
		ElsIf Record.PrepaymentMan <> 0 Or Record.PrepaymentLocal <> 0 Then 
			Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease;
		Else
			Record.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;
		EndIf;
	EndIf;
	
EndProcedure

// Deprecated. Delete in the next LTS.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions 
// 
// Returns:
//  Boolean - The transferred business transaction is an adjustment of debt
Function ThisIsDebtAdjustment(BusinessOperation)
	
	Return 
		// Increase in prepayment
		BusinessOperation = Enums.BusinessTransactions.ExchangeDifferencesCustomersExchangeLoss
		Or BusinessOperation = Enums.BusinessTransactions.ExchangeDifferencesVendorsExchangeGain
		// Debt increase
		Or BusinessOperation = Enums.BusinessTransactions.ExchangeDifferencesCustomersExchangeGain
		Or BusinessOperation = Enums.BusinessTransactions.ExchangeDifferencesVendorsExchangeLoss
		// AdjustingEntries
		Or BusinessOperation = Enums.BusinessTransactions.ARAPAdjustment
		Or BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable
		Or BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsReceivable
		Or BusinessOperation = Enums.BusinessTransactions.ARWriteOff
		Or BusinessOperation = Enums.BusinessTransactions.APWriteOff
		Or BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerBonuses
		Or BusinessOperation = Enums.BusinessTransactions.RecordCustomerBonusRebates
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryVendorBonuses
		Or BusinessOperation = Enums.BusinessTransactions.RecordVendorBonusRebate
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
		Or BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		// Commission fees
		Or BusinessOperation = Enums.BusinessTransactions.CommissionAgentSRemunerationDeduction
		Or BusinessOperation = Enums.BusinessTransactions.RemunerationDeductionByConsignor
		// Reservations in the part of the accountable
		Or BusinessOperation = Enums.BusinessTransactions.BookingViaAdvanceHolder
		Or BusinessOperation = Enums.BusinessTransactions.UseBookingByAdvanceHolder
		Or BusinessOperation = Enums.BusinessTransactions.RefundOfAdvanceHolderBooking
		Or BusinessOperation = Enums.BusinessTransactions.PenaltiesForReturningBookingOfAccountablePerson
		Or BusinessOperation = Enums.BusinessTransactions.BookingReturn 
		// Booking Return Storno
		Or BusinessOperation = Enums.BusinessTransactions.UseBookingByAdvanceHolderStorno
		// Salary reflection in financial accounting
		Or BusinessOperation = Enums.BusinessTransactions.DeductionFromAnEmployeeSalaryAgainstSale
		// ReversingEntry
		Or BusinessOperation = Enums.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno
		Or BusinessOperation = Enums.BusinessTransactions.DebtOffsetUponARAPAccountingStorno
		Or BusinessOperation = Enums.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno
	
EndFunction

// Deprecated. Delete in the next LTS.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions 
// 
// Returns:
//  Boolean - The transferred business transaction is an adjustment of the invoice
Function ThisIsAdjustmentOfInvoice(BusinessOperation)
	
	Return 
		BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor
		Or BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		Or BusinessOperation = Enums.BusinessTransactions.BookingReturn 
		// Returns of Goods
		Or BusinessOperation = Enums.BusinessTransactions.RepaymentOfCustomerReceivables
		Or BusinessOperation = Enums.BusinessTransactions.AccountsPayableRepayment
		// Negative reports to the committee/commission agent
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentReportToVendor
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer
		// Negative reflection of reward
		Or BusinessOperation = Enums.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentNotificationCommissionFee
	
EndFunction

// Deprecated. Delete in the next LTS.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions 
// 
// Returns:
//  Boolean - The transferred business transaction is the transfer of mutual settlements
Function ThisIsTransferOfMutualSettlements(BusinessOperation)
	
	Return 
		BusinessOperation = Enums.BusinessTransactions.ARAPSettlement
		Or BusinessOperation = Enums.BusinessTransactions.RecordOfPaymentThroughTheCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.SettlementOfPrepayment
		Or BusinessOperation = Enums.BusinessTransactions.DebtTransfer
		Or BusinessOperation = Enums.BusinessTransactions.DebtTransferBetweenBranchOffices
		Or BusinessOperation = Enums.BusinessTransactions.PaymentTransferBetweenBranchOffices
		Or BusinessOperation = Enums.BusinessTransactions.ReserveCustomerPrepayment
	
EndFunction

// Deprecated. Delete in the next LTS.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions 
// 
// Returns:
//  Boolean - The transferred business transaction is a refund
Function ThisIsRefund(BusinessOperation)
	
	Return 
		BusinessOperation = Enums.BusinessTransactions.RefundToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.RefundFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.RefundToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.RefundToCustomerSPaymentCard
	
EndFunction

// Deprecated. Delete in the next LTS.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions 
// 
// Returns:
//  Boolean - The transferred business transaction is a payment
Function ThisIsPayment(BusinessOperation, ThisIsReceiptOfPrepayment=False) Export
	
	Return 
		BusinessOperation = Enums.BusinessTransactions.BookingFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.BookingViaAgent
		Or BusinessOperation = Enums.BusinessTransactions.BookingViaAdvanceHolder
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfCashEquivalentsToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.PaymentToVendor
		Or BusinessOperation = Enums.BusinessTransactions.CustomsPayment
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromOtherCompany
		Or BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions
		Or BusinessOperation = Enums.BusinessTransactions.GiftCertificateSale
		Or BusinessOperation = Enums.BusinessTransactions.RepaymentOfCustomerReceivables
		Or BusinessOperation = Enums.BusinessTransactions.AccountsPayableRepayment
		Or BusinessOperation = Enums.BusinessTransactions.PenaltiesForReturnOfReservation
		Or BusinessOperation = Enums.BusinessTransactions.PenaltiesForReturningBookingOfAccountablePerson
		// Entering balances
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor
		Or (ThisIsReceiptOfPrepayment
			And (BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer
				Or BusinessOperation = Enums.BusinessTransactions.WriteOffReportFromCommissionAgent
				Or BusinessOperation = Enums.BusinessTransactions.ConsignmentReportToVendor
				Or BusinessOperation = Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost))
	
EndFunction

// Deprecated. Delete in the next LTS.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions 
// 
// Returns:
//  Boolean - The transferred business transaction is a shipment
Function ThisIsShipment(BusinessOperation)Export
	
	Return 
		// Debt increase
		BusinessOperation = Enums.BusinessTransactions.BookingFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.BookingViaAgent
		Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage
		Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods
		Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByCustodian
		Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
		Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
		Or BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany
		Or BusinessOperation = Enums.BusinessTransactions.CommissionWriteOffReportIntercompany
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee
		Or BusinessOperation = Enums.BusinessTransactions.WriteOffReportFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentReportToVendor
		Or BusinessOperation = Enums.BusinessTransactions.ConsignmentNotificationCommissionFee
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost
		Or BusinessOperation = Enums.BusinessTransactions.RegisterCCDThroughBroker
		Or BusinessOperation = Enums.BusinessTransactions.RegisterCCDUnassisted
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Or BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		Or BusinessOperation = Enums.BusinessTransactions.ReceiptOfFinancialDocumentsFromVendor
		Or BusinessOperation = Enums.BusinessTransactions.ProductionByToller
		Or BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5
		Or BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5
		Or BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
		Or BusinessOperation = Enums.BusinessTransactions.RetailSaleOfGoods
		Or BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany
		Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer
		Or BusinessOperation = Enums.BusinessTransactions.RenderRentalServices
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or BusinessOperation = Enums.BusinessTransactions.PenaltiesForReturnOfReservation
		// Reduction of prepayment and debt
		Or BusinessOperation = Enums.BusinessTransactions.CustomerPrepaymentSettlement
		Or BusinessOperation = Enums.BusinessTransactions.VendorPrepaymentSettlement
		Or BusinessOperation = Enums.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment
		Or BusinessOperation = Enums.BusinessTransactions.RemunerationOffsetWithPaymentToConsignor
		// Entering balances
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable
	
EndFunction

#EndRegion

// To distribute the background task AR/AP accounting.
// 
// Returns:
//  Boolean - To Distribute The Background Task AR/AP Accounting
Function AllocateARAPInBackgroundJob() Export
	
	SetPrivilegedMode(True);
	Return Constants.AllocateARAPInBackgroundJob.Get()
		And Not Common.FileInfobase() And Not Common.DebugMode();

EndFunction

// Returns the conditions under which the distribution of mutual settlements can be performed in the transaction of the document.
// 
// Returns:
//  Structure - Conditions for the distribution of settlements in a document transaction:
// * NumberOfBalanceEntries - Number - The number of Balance entries in the register of settlements by terms
// * NumberOfDocumentsAhead - Number - The number of registrars ahead of the ongoing document on the register of settlements
Function ConditionsForDistributionOfSettlementsInDocumentTransaction() Export
	
	TermsOfDistributionInTransaction = New Structure;
	TermsOfDistributionInTransaction.Insert("NumberOfBalanceEntries", 20);
	TermsOfDistributionInTransaction.Insert("NumberOfDocumentsAhead", 10);
	
	Return TermsOfDistributionInTransaction;

EndFunction

#EndRegion
