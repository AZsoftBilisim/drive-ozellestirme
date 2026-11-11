#Region Public

#Region CalculationStages

// Stage " Fillingpartyregistressthe Cost Of Goods"
//
// Parameters:
//	CalculationParameters - Structure - calculation execution parameters
//			For more information, see explanations in the calculation code of the highest values of the setalgorithms.initializationparameterscountparties
//
Procedure FillingOfLotsInRegisterCostOfGoods(CalculationParameters) Export
	
	// Fill in the service parameters of this stage (not required in other stages).
	CostCalculationAppliedAlgorithms.BatchesAreFilledInRegisterCostOfGoods(CalculationParameters, True);
	
	InvoicingOfDeliveries(CalculationParameters);
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "FillingOfLotsInRegisterCostOfGoods");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfBatchesOfGoods(CalculationParameters),
		DescriptionOfChainsOfBatchesOfGoods(CalculationParameters),
		DescriptionOfRegisteredRecordsOfBatchesOfGoods(CalculationParameters),
		DescriptionOfUnrecordedBatchesOfGoods(CalculationParameters));
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForBatchesOfGoods(CalculationParameters);
	
	// 3. Getting chains from source data
	// 	- generates temporary tables of Sources and Receivers.
	CostCalculationAppliedAlgorithms.BuildChainsOfRegisteredRecords(CalculationParameters);
	
	// 4. Filling in batches in chains
	// 	- fills in the Calculation parameters table.Distribution of parties.Settlement parties.
	CostCalculationAppliedAlgorithms.CalculateBatchesByChains(CalculationParameters);
	
	// 5. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	// Fill in the service parameters of this stage (not required in other stages).
	CostCalculationAppliedAlgorithms.BatchesAreFilledInRegisterCostOfGoods(CalculationParameters, False);
	
EndProcedure

// The stage of "Invoicing deliveries"
//
// Parameters:
//	CalculationParameters - Structure - calculation execution parameters
//			For more information, see explanations in the code of the calculation of the value of the individual rhythms.Initializationparametersaccount of parties()
//
Procedure InvoicingOfDeliveries(CalculationParameters) Export
	
	If Not GetFunctionalOption("UseUninvoicedDeliveries") Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "InvoicingOfDeliveries");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfBatchesOfGoods(CalculationParameters),
		DescriptionOfChainsOfBatchesOfGoods(CalculationParameters),
		DescriptionOfRegisteredRecordsInvoicingOfDeliveries(CalculationParameters),
		DescriptionOfUnrecordedBatchesOfGoods(CalculationParameters));
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForInvoicingDeliveries(CalculationParameters);
	
	// 3. Getting chains from source data
	// 	- generates temporary tables of Sources and Receivers.
	CostCalculationAppliedAlgorithms.BuildChainsOfRegisteredRecords(CalculationParameters);
	
	// 4. Filling in batches in chains
	// 	- fills in the Calculation parameters table.Distribution of parties.Settlement parties.
	CostCalculationAppliedAlgorithms.CalculateBatchesByChains(CalculationParameters);
	
	// 5. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

// The stage of "Filling in the party register of the hand and the cost of sales"
//
// Parameters:
//	CalculationParameters - Structure - calculation execution parameters
//			For more information, see explanations in the calculation code of the highest values of the setalgorithms.initializationparameterscountparties
//
Procedure FillingOfLotsInRegisterRevenueAndCostOfSales(CalculationParameters) Export
	
	// Fill in the service parameters of this stage (not required in other stages).
	CostCalculationAppliedAlgorithms.BatchesAreFilledInRegisterRevenueAndCostOfSales(CalculationParameters, True);
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "FillingOfLotsInRegisterRevenueAndCostOfSales");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchDistribution(
		CalculationParameters,
		TableForDistributionOfRevenueBatches(CalculationParameters),
		DescriptionOfRevenueChains(CalculationParameters),
		DescriptionOfRevenueBatchRegisteredRecords(CalculationParameters),
		DescriptionOfUnrecordedRevenueBatches(CalculationParameters));
	
	// 2. Obtaining the initial data for the calculation
	// 	- generates a temporary Data table.
	GetDataForRevenueBatches(CalculationParameters);
	
	// 3. Getting chains from source data
	// 	- generates temporary tables of Sources and Receivers.
	CostCalculationAppliedAlgorithms.BuildChainsOfRegisteredRecords(CalculationParameters);
	
	// 4. Filling in batches in chains
	// 	- fills in the Calculation parameters table.Distribution of parties.Settlement parties.
	CostCalculationAppliedAlgorithms.CalculateBatchesByChains(CalculationParameters);
	
	// 5. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of revenue and the value of sales.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
	// Fill in the service parameters of this stage (not required in other stages).
	CostCalculationAppliedAlgorithms.BatchesAreFilledInRegisterRevenueAndCostOfSales(CalculationParameters, False);
	
EndProcedure

// Stage " Preparation of the data for the preliminary calculation of the cost"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForPreliminaryCostCalculation(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForPreliminaryCostCalculation");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.InventoryCost.Name);
	
	// 2. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfRequestForDataPreparationForPreliminaryCostCalculation(CalculationParameters));
	
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region StageProcedures_InvoicingOfDeliveries

#Region Description_InvoicingOfDeliveries

// The stage of invoicing of deliveries calculates the deviations of the invoice amount from the amount of receipt of goods to the warehouse and
// the assignment of the calculated amount according to the analytics of receipt of goods to the warehouse. 
// And also calculates the deviations of the invoice amount from the receipt of services to the subdivision, and the assignment of the calculated amount
// in the direction of receipt of works and services to the subdivision.
// The stage is performed if the functional option "Use unfactured deliveries" is enabled.
// 
// An unfactured delivery is reflected in the documents "Receipt of goods to the warehouse" and "Receipt of services to the division".
// 	For the documents "Receipt of goods to the warehouse" and "Receipt of services to the division", a correction or 
// 	a document "Reverse" can be entered.
// The invoice of the delivery is reflected in the document "Purchase of goods and services". The document "Reverse" can be entered for the invoice document.
// The Invoice can be adjusted by the document "Purchase Adjustment" in The Cur or the next period. 
// Three types of adjustments are supported (processed in different ways):
// - Adjustment of the quantity plus (increase in invoice) with or without changing the invoice amount
// - Correction of the quantity minus (reduction of invoice) with or without changing the invoice amount
// - Adjustment of the invoice amount (both plus and minus)
//
// Initial data of unfactured deliveries:
// - Balances at the beginning of the period from the register "Cost of goods" under the accounting section "Unfactured deliveries".
// - Movements "Expense" for the Cur Period in the register "Cost of goods" under the accounting section "Unfactured deliveries"
//		with the type of entries "Batch".
// Initial invoice data:
// - Movement "Arrival" according to the register "Cost of goods" according to the accounting section "Unfactured deliveries" with the type of records "Consumption".
// Initial data for attributing deviations:
// - Movement of documents "Receipt of goods to the warehouse" and "Receipt of services to the division."
//
// Invoice algorithm:
//	1) The Balances and Receipts of the unfactured delivery in quantity and amount (hereinafter referred to as "Sources") are distributed to the 
//	invoice documents ("Purchase of goods and services" and "Purchase adjustment" to adjust the quantity in the plus) 
//	in proportion to the quantity in the invoice (hereinafter referred to as "Receivers"). 
//	Sources and receivers are selected by the fields "Organization", "Inventory accounting analytics", "Inventory type".
//	Sources are additionally sorted by orders to the supplier specified in the documents "Receipt of goods to the warehouse" and "Receipt of services to the division".
//	For receivers, the order to the supplier is determined according to the data in the tabular part of the document "Purchase of goods and services", 
//	which contains a link to the order to the supplier. The row of the table part is determined by the connection by the "Row identifier" field.
//	We get the result of the distribution - a receiver line with a filled batch and batch accounting analytics. 
//	For each row of the distribution result, we calculate the difference between the cost in the source and the cost in the receiver.
//	The difference with the cost is attributed to deviations.
//	2) The calculated deviations are distributed to analysts of the receipt of goods to the warehouse, to analysts of the receipt of works to the division, and
//	to analysts of cost reflection.
//	The temporary difference in the valuation of an unfactured delivery completely translates into deviations in cost and is reflected in the 
//	analysis of accounting for goods and works, or in the analysis of expenses (for works and services written off as expenses).
//	The permanent difference in the valuation of an unfactured delivery is written off, but does not translate into deviations, because deviations
//	in the part of the permanent difference must be formed from the sum of deviations in Local accounting so that in accounting for expenses the amount
//	of the permanent difference corresponds to the amount of Local Accounting (for expenses not accepted for income tax accounting).  
//	3) For distributed deviations, movements are generated according to the register "Cost of goods" for goods and works, and
//	 according to the register "Other expenses" for services and works written off as expenses.
//
// Adjustment of the purchase invoice
//	The invoice cost adjustment depends on the adjustment period.
//	When The Cur period is Adjusted, movements are generated with the type of Cost correction record.
//	When adjusting the previous period, movements are formed with the type of record of the adjustment of the acquisition of the previous period.
//	When adjusting the quantity in the direction of increase, movements with the type of record Consumption are formed (similar to invoicing).
//	When adjusting the amount downwards, movements are formed with the type of recording of the turnoff, regardless of the adjustment period.
// Selection of records:
//	The selection of records is performed in the request for texturecorrectioncorrections().
// Sources:
//	For such adjustments, the source is the record type "Past".
//	Records with the "Past" type are generated in the text request. The initial statistics are for correction of the correction().
//	The selection of movements for the formation of records with the "Past" type is performed according to the temporary table of document access and actual delivery before the log period.
//	The temporary table of document access to the actual delivery of the previous log period is generated in 
//	the request for the text document access to the actual delivery of the previous log Period() according To the movements of the documents of The Cur Period 
//	with selection by record types, adjustment of acquisition of the previous period, additional expenses by the party, cost adjustment.
// 

#EndRegion

// Data Initialization

Function DescriptionOfRegisteredRecordsInvoicingOfDeliveries(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfBatchesOfGoods(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "InvoicingOfDeliveries");
	RegisterRecordsDetails.Insert("TempTableName", "TTInvoicingOfDeliveries");
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	ConsumptionFieldsOfBatchOfGoods(CalculationParameters));
	RegisterRecordsDetails.Insert("Indicators", "Denominator, Count, Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
		|LocalCost, PermanentDifference, CostTD,
		|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
		|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
		|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
		|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal,
		|ItemizedFixedCostsCompl, ItemizedVariableCostsCompl");
	RegisterRecordsDetails.Insert("BasisOfArrival", "Count");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Count");
	RegisterRecordsDetails.Insert("ExpenseKey", "DocumentSource");
	RegisterRecordsDetails.Insert("OrderField_", "ReceiptPeriod");
	RegisterRecordsDetails.Insert("SortFields", "VATActivityType, Lot, PrioritySource");
	RegisterRecordsDetails.Insert("SortingByCondition", True);
	
	RegisterRecordsDetails.Insert("ThereIsStorno", True);
	RegisterRecordsDetails.Insert("ThereAreFixes", True);
	RegisterRecordsDetails.Insert("ThereIsBusinessOperation", True);
	RegisterRecordsDetails.Insert("ThereIsAccountingSection", True);
	
	RegisterRecordsDetails.Insert("TemporaryTablesForFollowingSteps", "UninvoicedDeliveries");
	
	Return RegisterRecordsDetails;
	
EndFunction

// Sample data

Procedure GetDataForInvoicingDeliveries(CalculationParameters)
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("InvoicingOfDeliveries", True);
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"ItemsLocationAttributes", // Separator
		"Denominator, Count,
			|Cost, CostExcludingVAT, OffBalanceCost, AddExpensesForGoods, AdditionalExpensesExcludingVAT, LaborCosts,
			|ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
			|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
			|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
			|LocalCost, OffBalanceCostLocal, PermanentDifference, CostTD,
			|AddExpensesLocal, LaborCostsLocal, ItemizedFixedCostsCompl, ItemizedVariableCostsCompl", // Resources
		"Products DESC, Priority ASC, Period, Organization, InventoryOwnerAttribute,
			|Lot, LotVendorAttributes, Recorder, CorLot, LotVendorAttributesCorr, RecordType DESC"); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		TextOfRequestForInvoicingDeliveries(CalculationParameters),
		NumberingParameters);
	
EndProcedure

// Request texts

// ... general

// Generating the full text of the stage request.
//
// Parameters:
//	CalculationParameters - Structure - calculation execution parameters
//			For more information, see explanations in the code of the calculation of the value of the individual rhythms.Initializationparametersaccount of parties()
//
// Returns:
//	String - Query text
//
Function TextOfRequestForInvoicingDeliveries(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// preparation of temporary tables
		+ TextInitializationOfBatchesOfGoods() // TUE Declarations, declarations of access
		+ Common.QueryBatchSeparator() + TextDocumentsOfReceiptOfUnfacturedDeliveriesOfPreviousPeriod() // TT document access and factored delivery before the log period
		+ Common.QueryBatchSeparator() + TextUnfacturedDeliveries() // tue unfactured deliveries
		+ Common.QueryBatchSeparator() + TextPastImplementations() // tue Past realizations
		+ Common.QueryBatchSeparator() + TextCorrectedDocuments() // tue Corrected documents
		+ Common.QueryBatchSeparator() + TextCalculatedDocuments() // tue Calculated documents
		+ Common.QueryBatchSeparator() + TextDocumentRegistryTable() // TT with data from the document registry
		+ Common.QueryBatchSeparator()
		// Sample data
		+ TextDescriptionOfDataForBatchesOfGoods() // w Data
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialBalancesOfUnfacturedDeliveries() // Uses unfactured deliveries
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialBalancesForInvoiceAdjustments() // Uses document access and factored delivery of the past period
		+ TMCommonUse.QuerySeparatorInJoin() + TextFinalBalancesOfUnfacturedDeliveries()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurUnfacturedDeliveries()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurInvoicesOfDeliveries()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurInvoiceAdjustments()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfReverseMovementOfCorrectedDocumentsOfInvoiceOfDeliveries() // uses corrected documents
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfCorrectedDocumentsOfCurPeriod() // uses corrected documents
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfReverseMovementOfCorrectedDocumentsOfPastPeriod() // uses corrected documents
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfMovementWithSelectedParties()
		+ "";
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextDocumentsOfReceiptOfUnfacturedDeliveriesOfPreviousPeriod() // TT document access and factored delivery before the log period
	Return "
		|SELECT DISTINCT
		|	DD.DocumentSource AS Inpayment
		|INTO DocumentsOfReceiptOfUnfactDeliveryOfPreviousPeriod
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|
		|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
		|	ON Register3.Ref = DD.DocumentSource
		|		AND NOT Register3.AdditionalRecord
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	DD.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|		VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction),
		|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|		VALUE(Enum.LotRecordTypes.CostAdjustment))
		|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND DD.DocumentSource <> UNDEFINED
		|	AND Register3.IBDocumentDate < &BeginOfPeriod
		|";
EndFunction

// The temporary table of unfactured deliveries is used to determine the direction of writing off deviations in the cost.
// Deviations in the cost are calculated as the difference between the amount of receipt of goods to the warehouse or receipt of services to the subdivision
// of receipt of services to the subdivision and the amount of invoice specified in the documents "Purchase of goods and services"
// in the procedure to fill in the calculation partyusest value of goods().
// For goods and works, deviations in cost are reflected by the analysis of receipt of goods to the warehouse in the following fields:
// - Inventory accounting analytics
// - Inventory type (the inventory type is not filled in for work)
// - Accounting section
// - Batch and Batch accounting analytics (filled in using the FIFO method of estimating the value of goods)
// - The organization, Financial accounting analytics and the Type of VAT activity are the same when goods arrive at the warehouse and 
//		in the "Unfactured deliveries" section. 
// For services and works written off as expenses, deviations in the cost are reflected in the cost analysis in the following fields:
// - Subdivision (corresponds to the subdivision in the inventory accounting analytics in the "Unfactured deliveries" section)
// - Cost item and cost analytics
// - Direction of activity
//
// The temporary table is used in the functions Textnumber of Party items(), textnumber of Party items().
//
Function TextUnfacturedDeliveries() // tue unfactured deliveries
	Return "
		|SELECT DISTINCT
		|	Balance.Lot AS Lot,
		|	Balance.LotVendorAttributes AS LotVendorAttributes,
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Balance.AccountingSection AS AccountingSection
		|	
		|INTO ActualUnfacturedDeliveries
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,
		|		Organization IN (&CompanyArray)
		|		AND AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	) AS Balance
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON Balance.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Balance.Lot AS Lot,
		|	Balance.LotVendorAttributes AS LotVendorAttributes,
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Balance.AccountingSection AS AccountingSection
		|FROM
		|	AccumulationRegister.InventoryCost AS Balance
		|	INNER JOIN DocumentsOfReceiptOfUnfactDeliveryOfPreviousPeriod AS NonInvoicing
		|		ON NonInvoicing.Inpayment = Balance.Recorder
		|
		|INDEX BY
		|	Lot,
		|	LotVendorAttributes,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	AccountingSection
		|;
		|SELECT
		|	Balance.Lot AS Lot,
		|	Balance.LotVendorAttributes AS LotVendorAttributes,
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Balance.AccountingSection AS AccountingSection,
		|	MAX(DD.Period) AS Period,
		|	MAX(DD.Recorder) AS Recorder
		|
		|INTO RecordersOfUnfacturedDeliveries
		|FROM
		|	ActualUnfacturedDeliveries AS Balance
		|	INNER JOIN AccumulationRegister.InventoryCost AS DD
		|		ON DD.Lot = Balance.Lot
		|		AND DD.Period < &BeginOfPeriod
		|		AND DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
		|		AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
		|		AND DD.AccountingSection = Balance.AccountingSection
		|		AND DD.LotVendorAttributes = Balance.LotVendorAttributes
		|		AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND DD.Count <> 0
		|		AND NOT DD.ReversingEntry
		|
		|GROUP BY
		|	Balance.Lot,
		|	Balance.LotVendorAttributes,
		|	Balance.ItemsLocationAttributes,
		|	Balance.InventoryOwnerAttribute,
		|	Balance.AccountingSection
		|
		|INDEX BY
		|	Lot,
		|	LotVendorAttributes,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	AccountingSection
		|;
		|SELECT
		|	DD.Lot AS Lot,
		|	DD.LotVendorAttributes AS LotVendorAttributes,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.AccountingSection AS AccountingSection,
		|	MAX(DD.CorItemsLocationAttributes) AS CorItemsLocationAttributes,
		|	MAX(DD.CorInventoryOwnerAttribute) AS CorInventoryOwnerAttribute,
		|	MAX(DD.CorAccountingSection) AS CorAccountingSection,
		|	MAX(ISNULL(ArrivalAtWarehouse.Lot, UNDEFINED)) AS CorLot,
		|	MAX(ISNULL(ArrivalAtWarehouse.LotVendorAttributes, UNDEFINED)) AS LotVendorAttributesCorr,
		|
		// Cost reflection analytics
		|	MAX(DD.Department) AS Department,
		|	MAX(DD.ExpenseItemOfWriteOff) AS ExpenseItemOfWriteOff,
		|	MAX(DD.DimensionOfExpenses) AS DimensionOfExpenses,
		|	MAX(DD.CorLineOfBusiness) AS CorLineOfBusiness
		|	
		|INTO UninvoicedDeliveries
		|FROM
		|	RecordersOfUnfacturedDeliveries AS Balance
		|
		|	INNER JOIN AccumulationRegister.InventoryCost AS DD
		|		ON DD.Recorder = Balance.Recorder
		|		AND DD.Period = Balance.Period
		|		AND DD.Lot = Balance.Lot
		|		AND DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
		|		AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
		|		AND DD.AccountingSection = Balance.AccountingSection
		|		AND DD.LotVendorAttributes = Balance.LotVendorAttributes
		|		AND NOT DD.ReversingEntry
		|	LEFT JOIN AccumulationRegister.InventoryCost AS ArrivalAtWarehouse
		|		ON ArrivalAtWarehouse.Recorder = Balance.Recorder
		|		AND ArrivalAtWarehouse.Period = Balance.Period
		|		AND ArrivalAtWarehouse.Lot = Balance.Lot
		|		AND ArrivalAtWarehouse.ItemsLocationAttributes = DD.CorItemsLocationAttributes
		|		AND ArrivalAtWarehouse.InventoryOwnerAttribute = DD.CorInventoryOwnerAttribute
		|		AND ArrivalAtWarehouse.AccountingSection = DD.CorAccountingSection
		|		AND NOT ArrivalAtWarehouse.ReversingEntry
		|GROUP BY
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.AccountingSection
		|
		|INDEX BY
		|	Lot,
		|	LotVendorAttributes,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	AccountingSection
		|";

EndFunction

// ... data samples

Function TextInitialBalancesOfUnfacturedDeliveries() // Uses the registrydocumentstatistics of parties, unfactated deliveries
	Return 
		"SELECT
		|	""TextInitialBalancesOfUnfacturedDeliveries"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.CountBalance < 0 THEN TRUE
		|		ELSE FALSE END)							 AS ThisIsReverseTransaction,
		|	0 												 AS Priority,
		|	0 												 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products 		 AS Products,
		|	T.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	(CASE
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		// For batch balances, the period is determined by the batch date.
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		ELSE DATETIME(1,1,1) END)				 AS Period,
		// The Access Period field is filled in the same way as the Period field.
		|	(CASE
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		ELSE DATETIME(1,1,1) END)				 AS ReceiptPeriod,
		|	DATETIME(1,1,1)								 AS VariancePeriod,
		|	T.Lot										 AS Recorder,
		|	UNDEFINED 			 	 					 AS RecordType,
		|	T.ItemsLocationAttributes 					 AS ItemsLocationAttributes,
		|	T.AccountingSection				 					 AS AccountingSection,
		|	T.InventoryOwnerAttribute				 					 AS InventoryOwnerAttribute,
		|	T.Organization				 					 AS Organization,
		|	T.Lot					 					 AS Lot,
		|	UNDEFINED									 AS ProductionOrder,
		|	T.LotVendorAttributes		 					 AS LotVendorAttributes,
		|	T.FinancialAccountingDimension  					 AS FinancialAccountingDimension,
		|	T.VATActivityType		 					 AS VATActivityType,
		|
		|	T.CountBalance 							 AS Count,
		|	T.CostBalance 								 AS Cost,
		|	T.CostExcludingVATBalance 						 AS CostExcludingVAT,
		|	T.OffBalanceCostBalance 					 AS OffBalanceCost,
		|	T.CostManBalance 							 AS CostMan,
		|	T.AddExpensesManBalance 							 AS AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVATBalance 				 AS ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVATBalance 			 AS ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsManBalance 						 AS LaborCostsMan,
		|	T.ItemizedFixedCostsManagBalance 				 AS ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManagBalance 				 AS ItemizedVariableCostsManag,
		|	T.AddExpensesForGoodsBalance 						 	 AS AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVATBalance 				 		 AS AdditionalExpensesExcludingVAT,
		|	T.LaborCostsBalance 							 AS LaborCosts,
		|	T.ItemizedFixedCostsIncludingVATBalance 				 AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVATBalance 			 AS ItemizedFixedCostsExcludingVAT,
		|	T.LocalCostBalance 							 AS LocalCost,
		|	T.OffBalanceCostLocalBalance 				 AS OffBalanceCostLocal,
		|	T.PermanentDifferenceBalance 						 AS PermanentDifference,
		|	T.CostTDBalance 						 AS CostTD,
		|	T.CostOfPersonalIncomeTaxBalance 							 AS CostOfPersonalIncomeTax,
		|	T.AddExpensesLocalBalance 						 AS AddExpensesLocal,
		|	T.LaborCostsLocalBalance 						 AS LaborCostsLocal,
		|	T.ItemizedFixedCostsComplBalance 				 AS ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsComplBalance 			     AS ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocalBalance 			     AS ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentManBalance 			     AS ProvisionForImpairmentMan,
		|
		|	ISNULL(Register3.BusinessOperation,
		|		VALUE(Enum.BusinessTransactions.EmptyRef)) AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	ISNULL(UninvoicedDeliveries.CorItemsLocationAttributes,
		|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))	AS CorItemsLocationAttributes,
		|	ISNULL(UninvoicedDeliveries.CorAccountingSection,
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)) AS CorAccountingSection,
		|	ISNULL(UninvoicedDeliveries.CorInventoryOwnerAttribute,
		|		VALUE(Catalog.InventoryKinds.EmptyRef))						AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	ISNULL(UninvoicedDeliveries.Department,
		|		UNDEFINED)														AS Department,
		|	ISNULL(UninvoicedDeliveries.DimensionOfExpenses,
		|		UNDEFINED)														AS DimensionOfExpenses,
		|	ISNULL(UninvoicedDeliveries.ExpenseItemOfWriteOff,
		|		UNDEFINED)														AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	ISNULL(UninvoicedDeliveries.CorLot,
		|		UNDEFINED)														AS CorLot,
		|	ISNULL(UninvoicedDeliveries.LotVendorAttributesCorr,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))		AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	(CASE
		|		WHEN VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE UNDEFINED END)											AS PrioritySource,
		|	ISNULL(UninvoicedDeliveries.CorLineOfBusiness,
		|		UNDEFINED)														AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,	
		|		Organization IN (&CompanyArray)
		|		AND AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		AND &RestoreChronologicalSequenceOfDebitingBatches
		|	) AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN Document.SourceDocument AS SourceDocument
		|		ON SourceDocument.Ref = T.Lot
		|	LEFT JOIN RegisterOfDocumentsRemainingBatches AS Register3
		|		ON Register3.Ref = T.Lot
		|	LEFT JOIN UninvoicedDeliveries AS UninvoicedDeliveries
		|		ON UninvoicedDeliveries.Lot = T.Lot
		|		AND UninvoicedDeliveries.LotVendorAttributes = T.LotVendorAttributes
		|		AND UninvoicedDeliveries.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND UninvoicedDeliveries.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND UninvoicedDeliveries.AccountingSection = T.AccountingSection
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = T.Lot
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = T.Lot
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|";
EndFunction

Function TextInitialBalancesForInvoiceAdjustments() // Uses document access and factored delivery of the past period
	Return 
		"SELECT
		|	""TextInitialBalancesForInvoiceAdjustments""   AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Previous) 	  AS EntryType,
		|	FALSE												  AS ThisIsExactlyCalculatedMovement,
		|	FALSE												  AS ThisIsReverseTransaction,
		|	0 										  			  AS Priority,
		|	0								  					  AS Denominator,
		|	TRUE 												  AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 			  AS Products,
		|	DD.LotVendorAttributes.VATTaxation 			  AS TaxationOfParty,
		|
		|	&EndOfPreviousPeriod 	 						  AS Period,
		|	&EndOfPreviousPeriod 	 						  AS ReceiptPeriod,
		|	DATETIME(1,1,1)									  AS VariancePeriod,
		|	(CASE
		|		WHEN NOT Adjusting.Ref IS NULL THEN Adjusting.DocumentBasis
		|		ELSE DD.Recorder END)						  AS Recorder,
		|	UNDEFINED 			 	 						  AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.Count AS Count,
		|	DD.Cost,
		|	DD.CostExcludingVAT,
		|	DD.OffBalanceCost,
		|	DD.CostMan,
		|	DD.AddExpensesMan,
		|	DD.ItemizedVariableCostsIncludingVAT,
		|	DD.ItemizedVariableCostsExcludingVAT,
		|	DD.LaborCostsMan,
		|	DD.ItemizedFixedCostsManag,
		|	DD.ItemizedVariableCostsManag,
		|	DD.AddExpensesForGoods,
		|	DD.AdditionalExpensesExcludingVAT,
		|	DD.LaborCosts,
		|	DD.ItemizedFixedCostsIncludingVAT,
		|	DD.ItemizedFixedCostsExcludingVAT,
		|	DD.LocalCost,
		|	DD.OffBalanceCostLocal,
		|	DD.PermanentDifference,
		|	DD.CostTD,
		|	DD.CostOfPersonalIncomeTax,
		|	DD.AddExpensesLocal,
		|	DD.LaborCostsLocal,
		|	DD.ItemizedFixedCostsCompl,
		|	DD.ItemizedVariableCostsCompl,
		|	DD.ProvisionForImpairmentLocal,
		|	DD.ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation 												AS BusinessOperation,
		|	UNDEFINED															AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	ISNULL(OtherExpenses.Department, DD.Department)					AS Department,
		|	ISNULL(OtherExpenses.DimensionOfExpenses, DD.DimensionOfExpenses)			AS DimensionOfExpenses,
		|	ISNULL(OtherExpenses.ExpenseItem, DD.ExpenseItemOfWriteOff)		AS ExpenseItemOfWriteOff,
		|	DD.IncomeItem															AS IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	DD.AssetAndLiabilityItem												AS AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension												AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED 															AS DocumentSource,
		// The conditions for filling in the Priority Source field must match the request for the text of the actual Delivery facturefactors().
		|	(CASE
		|		WHEN NOT AcquisitionTypesOfInventory.PurchaseOrder IS NULL
		|		 AND AcquisitionTypesOfInventory.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN AcquisitionTypesOfInventory.PurchaseOrder
		|		WHEN NOT PurchaseGoods.PurchaseOrder IS NULL
		|		 AND PurchaseGoods.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseGoods.PurchaseOrder
		|		WHEN NOT PurchaseAdjustmentDiscrepancies.PurchaseOrder IS NULL
		|		 AND PurchaseAdjustmentDiscrepancies.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseAdjustmentDiscrepancies.PurchaseOrder
		|		ELSE ISNULL(CorrectedDocuments_.Recorder, UNDEFINED) END) AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN DocumentsOfReceiptOfUnfactDeliveryOfPreviousPeriod AS ReceiptDocuments
		|		ON ReceiptDocuments.Inpayment = DD.Recorder
		|	LEFT JOIN Document.VendorInvoice.InventoryKinds AS AcquisitionTypesOfInventory
		|		ON AcquisitionTypesOfInventory.Ref = DD.Recorder
		|		AND AcquisitionTypesOfInventory.RowID = DD.RowID
		|	LEFT JOIN Document.VendorInvoice.Goods AS PurchaseGoods
		|		ON PurchaseGoods.Ref = DD.Recorder
		|		AND PurchaseGoods.RowID = DD.RowID
		|	LEFT JOIN Document.PurchaseAdjustment.Discrepancies AS PurchaseAdjustmentDiscrepancies
		|		ON PurchaseAdjustmentDiscrepancies.Ref = DD.Recorder
		|		AND PurchaseAdjustmentDiscrepancies.RowID = DD.RowID
		|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON Adjusting.Ref = DD.Recorder
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.Recorder = DD.Recorder
		|	LEFT JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
		|		ON OtherExpenses.Period = DD.Period
		|		AND OtherExpenses.Recorder = DD.Recorder
		|		AND OtherExpenses.Organization = DD.Organization
		|		AND OtherExpenses.BusinessTransactionSetting = DD.BusinessTransactionSetting
		|		AND OtherExpenses.FinRecordID = DD.FinRecordID
		|		AND NOT OtherExpenses.LotCalculation
		|		AND NOT OtherExpenses.CalculationOfCost
		|		AND NOT OtherExpenses.ReversingEntry
		|WHERE
		|	DD.Count <> 0
		|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND DD.Period < &BeginOfPeriod
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND DD.Period < &DateOfMigrationToBatchAccounting22)
		|";
EndFunction

Function TextFinalBalancesOfUnfacturedDeliveries() // Uses the registrydocumentstatistics of parties, unfactated deliveries
	Return 
		"SELECT
		|	""TextFinalBalancesOfUnfacturedDeliveries"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)							 AS ThisIsReverseTransaction,
		|	0 												 AS Priority,
		|	0 												 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products 		 AS Products,
		|	T.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	(CASE
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		// For batch balances, the period is determined by the batch date.
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		ELSE DATETIME(1,1,1) END)				 AS Period,
		// The Access Period field is filled in the same way as the Period field.
		|	(CASE
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		ELSE DATETIME(1,1,1) END)				 AS ReceiptPeriod,
		|	DATETIME(1,1,1)								 AS VariancePeriod,
		|	T.Lot										 AS Recorder,
		|	UNDEFINED 			 	 					 AS RecordType,
		|	T.ItemsLocationAttributes 					 AS ItemsLocationAttributes,
		|	T.AccountingSection				 					 AS AccountingSection,
		|	T.InventoryOwnerAttribute				 					 AS InventoryOwnerAttribute,
		|	T.Organization				 					 AS Organization,
		|	T.Lot					 					 AS Lot,
		|	UNDEFINED									 AS ProductionOrder,
		|	T.LotVendorAttributes		 					 AS LotVendorAttributes,
		|	T.FinancialAccountingDimension  					 AS FinancialAccountingDimension,
		|	T.VATActivityType		 					 AS VATActivityType,
		|
		|	T.Count									 AS Count,
		|	T.Cost										 AS Cost,
		|	T.CostExcludingVAT								 AS CostExcludingVAT,
		|	T.OffBalanceCost							 AS OffBalanceCost,
		|	T.CostMan									 AS CostMan,
		|	T.AddExpensesMan									 AS AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT						 AS ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT					 AS ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan								 AS LaborCostsMan,
		|	T.ItemizedFixedCostsManag						 AS ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag						 AS ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods									 AS AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT								 AS AdditionalExpensesExcludingVAT,
		|	T.LaborCosts									 AS LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT						 AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT					 AS ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost									 AS LocalCost,
		|	T.OffBalanceCostLocal						 AS OffBalanceCostLocal,
		|	T.PermanentDifference								 AS PermanentDifference,
		|	T.CostTD								 AS CostTD,
		|	T.CostOfPersonalIncomeTax									 AS CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal								 AS AddExpensesLocal,
		|	T.LaborCostsLocal								 AS LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl						 AS ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl						 AS ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal						 AS ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan						 AS ProvisionForImpairmentMan,
		|
		|	ISNULL(Register3.BusinessOperation,
		|		VALUE(Enum.BusinessTransactions.EmptyRef)) AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	ISNULL(UninvoicedDeliveries.CorItemsLocationAttributes,
		|		VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))	AS CorItemsLocationAttributes,
		|	ISNULL(UninvoicedDeliveries.CorAccountingSection,
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)) AS CorAccountingSection,
		|	ISNULL(UninvoicedDeliveries.CorInventoryOwnerAttribute,
		|		VALUE(Catalog.InventoryKinds.EmptyRef))						AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	ISNULL(UninvoicedDeliveries.Department,
		|		UNDEFINED)														AS Department,
		|	ISNULL(UninvoicedDeliveries.DimensionOfExpenses,
		|		UNDEFINED)														AS DimensionOfExpenses,
		|	ISNULL(UninvoicedDeliveries.ExpenseItemOfWriteOff,
		|		UNDEFINED)														AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	ISNULL(UninvoicedDeliveries.CorLot,
		|		UNDEFINED)														AS CorLot,
		|	ISNULL(UninvoicedDeliveries.LotVendorAttributesCorr,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))		AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	(CASE
		|		WHEN VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE UNDEFINED END)											AS PrioritySource,
		|	ISNULL(UninvoicedDeliveries.CorLineOfBusiness,
		|		UNDEFINED)														AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	TTCashSettlementBalancesCostOfGoods AS T
		|
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN Document.SourceDocument AS SourceDocument
		|		ON SourceDocument.Ref = T.Lot
		|	LEFT JOIN RegisterOfDocumentsRemainingBatches AS Register3
		|		ON Register3.Ref = T.Lot
		|	LEFT JOIN UninvoicedDeliveries AS UninvoicedDeliveries
		|		ON UninvoicedDeliveries.Lot = T.Lot
		|		AND UninvoicedDeliveries.LotVendorAttributes = T.LotVendorAttributes
		|		AND UninvoicedDeliveries.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND UninvoicedDeliveries.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND UninvoicedDeliveries.AccountingSection = T.AccountingSection
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = T.Lot
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = T.Lot
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|WHERE
		|	T.Organization IN (&CompanyArray)
		|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT &RestoreChronologicalSequenceOfDebitingBatches
		|";
EndFunction

Function TextCurUnfacturedDeliveries() // uses corrected documents
	Return 
		"SELECT
		|	""TextCurUnfacturedDeliveries"" 					AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance)			AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)										AS ThisIsReverseTransaction,
		|	(CASE
		|		WHEN T.OfficialTypeOfMovementParish THEN 10
		|		ELSE 90 END)											AS Priority,
		|	0 															AS Denominator,
		|	TRUE 														AS CalculationIsCompleted,
		|	Dimension.Products										AS Products,
		|	CASE WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|		THEN T.LotVendorAttributes.VATTaxation
		|		ELSE UNDEFINED
		|	END 														AS TaxationOfParty,
		|
		|	T.Period AS Period,
		|	CASE
		|		WHEN NOT Corrections.DateOfDocumentBeingCancelled IS NULL
		|			THEN Corrections.DateOfDocumentBeingCancelled
		|		ELSE T.Period END AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|
		|	T.Count,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.OffBalanceCost,
		|	T.CostMan,
		|	T.AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan,
		|	T.ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost,
		|	T.OffBalanceCostLocal,
		|	T.PermanentDifference,
		|	T.CostTD,
		|	T.CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal,
		|	T.LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	ISNULL(OtherExpenses.Department, T.Department) AS Department,
		|	ISNULL(OtherExpenses.DimensionOfExpenses, T.DimensionOfExpenses) AS DimensionOfExpenses,
		|	ISNULL(OtherExpenses.ExpenseItem, T.ExpenseItemOfWriteOff) AS ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	CASE
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.Lot
		|		ELSE T.CorLot
		|	END AS CorLot,
		|	CASE
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.LotVendorAttributes
		|		ELSE T.LotVendorAttributesCorr
		|	END AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	(CASE
		|		WHEN T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.DocumentVATActivityType
		|		ELSE T.VATActivityType END) AS DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource,
		|	(CASE
		|		WHEN VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE ISNULL(CorrectedDocuments_.ReversedDocument, UNDEFINED) END) AS PrioritySource,
		|	ISNULL(OtherExpenses.LineOfBusiness, T.CorLineOfBusiness) AS CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
		|		ON CorDimension.Ref = T.CorItemsLocationAttributes
		|	LEFT JOIN Catalog.Warehouses AS CorWarehouses
		|		ON CorDimension.StorageLocation = CorWarehouses.Ref
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = T.Recorder
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = T.Recorder
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = T.Recorder
		|	LEFT JOIN CorrectedDocuments_ AS Corrections
		|		ON Corrections.Recorder = T.Recorder
		|	LEFT JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
		|		ON OtherExpenses.Period = T.Period
		|		AND OtherExpenses.Recorder = T.Recorder
		|		AND OtherExpenses.Organization = T.Organization
		|		AND OtherExpenses.BusinessTransactionSetting = T.BusinessTransactionSetting
		|		AND OtherExpenses.FinRecordID = T.FinRecordID
		|		AND NOT OtherExpenses.LotCalculation
		|		AND NOT OtherExpenses.CalculationOfCost
		|		AND NOT OtherExpenses.ReversingEntry
		|WHERE
		|	T.Count <> 0
		|	AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT T.ReversingEntry
		|	AND &RestoreChronologicalSequenceOfDebitingBatches
		|";
EndFunction

Function TextCurInvoicesOfDeliveries()
	QueryText = 
		"SELECT
		|	""TextCurInvoicesOfDeliveries""	 						AS RequestSource,
		|	T.EntryType 												AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)										AS ThisIsReverseTransaction,
		|	(CASE
		|		WHEN T.OfficialTypeOfMovementParish AND T.EntryType IN (&UnreadableRecordTypes) THEN 10
		|		ELSE 90 END)											AS Priority,
		|	0 															AS Denominator,
		|	CASE
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|			THEN TRUE
		|		ELSE FALSE
		|	END 														AS CalculationIsCompleted,
		|	Dimension.Products										AS Products,
		|	CASE WHEN (T.EntryType IN (&UnreadableRecordTypes) AND T.Organization IN (&SFIFOOrganizationsSliding))
		|		THEN T.LotVendorAttributes.VATTaxation
		|		ELSE UNDEFINED
		|	END 														AS TaxationOfParty,
		|
		|	T.Period AS Period,
		|	CASE
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			THEN &BeginOfPeriod
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		 AND NOT SourceDocument.Date IS NULL
		|			THEN SourceDocument.Date
		|		WHEN PurchaseAdjustment.DocumentBasis IS NOT NULL
		|			THEN RegisterOfPurchaseAdjustments.IBDocumentDate
		|		ELSE T.Period
		|	END AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	CASE
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		 OR T.ReversingEntry
		|			THEN T.Lot
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	CASE
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		OR T.ReversingEntry
		|			THEN T.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END AS LotVendorAttributes,
		|	CASE
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND T.FinancialAccountingDimensionOfDocument <> UNDEFINED
		|			THEN T.FinancialAccountingDimensionOfDocument
		|		ELSE T.CorControllingAttributes
		|	END AS FinancialAccountingDimension,
		|	CASE
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|			THEN T.VATActivityType
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.CorItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.CorItemsLocationAttributes.Purpose.VATActivityType
		|		WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		ELSE T.CorVATActivityTypes
		|	END AS VATActivityType,
		|
		|	T.Count,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.OffBalanceCost,
		|	T.CostMan,
		|	T.AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan,
		|	T.ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost,
		|	T.OffBalanceCostLocal,
		|	T.PermanentDifference,
		|	T.CostTD,
		|	T.CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal,
		|	T.LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	CASE
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.CorItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|				AND NOT T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|			THEN T.CorItemsLocationAttributes.Purpose.VATActivityType
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		ELSE T.CorVATActivityTypes
		|	END AS CorVATActivityTypes,
		|
		|	CASE
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.CorItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.CorItemsLocationAttributes.Purpose.VATActivityType
		|		WHEN T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.DocumentVATActivityType
		|		ELSE T.CorVATActivityTypes
		|	END AS DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource,
		// The conditions for filling in the Priority Source field must match the requests 
		// The text of the initial statistics for the correction of the text() and the text of the following correction of the text().
		|	(CASE
		|		WHEN NOT AcquisitionTypesOfInventory.PurchaseOrder IS NULL
		|		 AND AcquisitionTypesOfInventory.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN AcquisitionTypesOfInventory.PurchaseOrder
		|		WHEN NOT PurchaseGoods.PurchaseOrder IS NULL
		|		 AND PurchaseGoods.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseGoods.PurchaseOrder
		|		WHEN NOT PurchaseAdjustmentDiscrepancies.PurchaseOrder IS NULL
		|		 AND PurchaseAdjustmentDiscrepancies.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseAdjustmentDiscrepancies.PurchaseOrder
		|		WHEN NOT PurchaseAdjustmentInventoryKinds.PurchaseOrder IS NULL
		|		 AND PurchaseAdjustmentInventoryKinds.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseAdjustmentInventoryKinds.PurchaseOrder
		|		ELSE ISNULL(CorrectedDocuments_.Recorder, UNDEFINED) END) AS PrioritySource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|	LEFT JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
		|		ON PurchaseAdjustment.Ref = T.Recorder
		|	LEFT JOIN RegisterOfDocumentsOfBatchOfPurchaseAdjustments AS RegisterOfPurchaseAdjustments
		|		ON RegisterOfPurchaseAdjustments.Ref = PurchaseAdjustment.DocumentBasis
		|	LEFT JOIN Document.VendorInvoice AS PurchaseOfGoods
		|		ON PurchaseOfGoods.Ref = T.Recorder
		|	LEFT JOIN Document.VendorInvoice.InventoryKinds AS AcquisitionTypesOfInventory
		|		ON AcquisitionTypesOfInventory.Ref = T.Recorder
		|		AND AcquisitionTypesOfInventory.RowID = T.RowID
		|	LEFT JOIN Document.VendorInvoice.Goods AS PurchaseGoods
		|		ON PurchaseGoods.Ref = T.Recorder
		|		AND PurchaseGoods.RowID = T.RowID
		|	LEFT JOIN Document.PurchaseAdjustment.Discrepancies AS PurchaseAdjustmentDiscrepancies
		|		ON PurchaseAdjustmentDiscrepancies.Ref = T.Recorder
		|		AND PurchaseAdjustmentDiscrepancies.RowID = T.RowID
		|	LEFT JOIN Document.PurchaseAdjustment.InventoryKinds AS PurchaseAdjustmentInventoryKinds
		|		ON PurchaseAdjustmentInventoryKinds.Ref = T.Recorder
		|		AND PurchaseAdjustmentInventoryKinds.RowID = T.RowID
		|	LEFT JOIN Document.SourceDocument AS SourceDocument
		|		ON SourceDocument.Ref = T.Lot
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations_
		|		ON T.Organization = AccountingPoliciesOfOrganizations_.Organization
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS WriteOffItem
		|		ON WriteOffItem.Ref = T.ExpenseItemOfWriteOff
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.Recorder = T.Recorder
		|WHERE
		|	T.Count <> 0
		|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT T.ReversingEntry
		|	AND (NOT T.LotCalculationPerformed
		|		OR &RestoreChronologicalSequenceOfDebitingBatches)
		// The receipt of primary batches is described in the function textcurrent actual deliveries()
		|	AND T.EntryType <> VALUE(Enum.LotRecordTypes.Lot)
		|";
	Return QueryText;
EndFunction

Function TextCurInvoiceAdjustments()
	Return 
		"SELECT
		|	""TextCurInvoiceAdjustments""						AS RequestSource,
		|	DD.EntryType 							  					AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	FALSE														AS ThisIsReverseTransaction,
		|	10 										  					AS Priority,
		|	0															AS Denominator,
		|	FALSE 														AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					AS Products,
		|	UNDEFINED 												AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|
		|	0 AS Count,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(DD.OffBalanceCost) AS OffBalanceCost,
		|	SUM(DD.CostMan) AS CostMan,
		|	SUM(DD.AddExpensesMan) AS AddExpensesMan,
		|	SUM(DD.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(DD.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(DD.LaborCostsMan) AS LaborCostsMan,
		|	SUM(DD.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(DD.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(DD.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.LaborCosts) AS LaborCosts,
		|	SUM(DD.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(DD.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DD.LocalCost) AS LocalCost,
		|	SUM(DD.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD) AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(DD.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(DD.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(DD.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(DD.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(DD.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(DD.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	SUM(DD.VATManag) AS VATManag,
		|	SUM(DD.VATLocal) AS VATLocal,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		// The conditions for filling in the Priority Source field must match the request for the text of the actual Delivery facturefactors().
		|	(CASE
		|		WHEN NOT PurchaseAdjustmentDiscrepancies.PurchaseOrder IS NULL
		|		 AND PurchaseAdjustmentDiscrepancies.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseAdjustmentDiscrepancies.PurchaseOrder
		|		WHEN NOT PurchaseAdjustmentInventoryKinds.PurchaseOrder IS NULL
		|		 AND PurchaseAdjustmentInventoryKinds.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseAdjustmentInventoryKinds.PurchaseOrder
		|		ELSE UNDEFINED END) AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN Document.PurchaseAdjustment.Discrepancies AS PurchaseAdjustmentDiscrepancies
		|		ON PurchaseAdjustmentDiscrepancies.Ref = DD.Recorder
		|		AND PurchaseAdjustmentDiscrepancies.RowID = DD.RowID
		|	LEFT JOIN Document.PurchaseAdjustment.InventoryKinds AS PurchaseAdjustmentInventoryKinds
		|		ON PurchaseAdjustmentInventoryKinds.Ref = DD.Recorder
		|		AND PurchaseAdjustmentInventoryKinds.RowID = DD.RowID
		|WHERE
		|	DD.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|		VALUE(Enum.LotRecordTypes.IncludeExciseInCost),
		|		VALUE(Enum.LotRecordTypes.CostAdjustment),
		|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		// Data on other sections of accounting is processed at the stage of filling in the Party register of the cost of goods 
		// See TextCurrentAdditionalExpensesAmountWithBatchOfImportApplication.
		|	AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.VATActivityType,
		|	DD.Period,
		|	DD.VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.BusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.RowCode,
		|	DD.ProductsGroup,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END), // DocumentVATActivityType
		|	DD.CorLineOfBusiness,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	(CASE
		|		WHEN NOT PurchaseAdjustmentDiscrepancies.PurchaseOrder IS NULL
		|		 AND PurchaseAdjustmentDiscrepancies.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseAdjustmentDiscrepancies.PurchaseOrder
		|		WHEN NOT PurchaseAdjustmentInventoryKinds.PurchaseOrder IS NULL
		|		 AND PurchaseAdjustmentInventoryKinds.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN PurchaseAdjustmentInventoryKinds.PurchaseOrder
		|		ELSE UNDEFINED END), // PrioritySource
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|";
EndFunction

Function TextOfReverseMovementOfCorrectedDocumentsOfInvoiceOfDeliveries() // uses corrected documents
	
	Return " 
		|SELECT
		|	""TextOfReverseMovementOfCorrectedDocumentsOfInvoiceOfDeliveries""       AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance)     AS EntryType,
		|	FALSE                                                 AS ThisIsExactlyCalculatedMovement,
		|	TRUE                                               ThisIsReverseTransaction,
		|	0                                                    AS Priority,
		|	0                                                    AS Denominator,
		|	TRUE                                               AS CalculationIsCompleted,
		|	RegisterData.ItemsLocationAttributes.Products AS Products,
		|	RegisterData.LotVendorAttributes.VATTaxation AS TaxationOfParty,
		|
		|	CorrectedDocuments_.Period,
		|	(CASE
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		WHEN RegisterData.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		|		ELSE &EndOfPreviousPeriod END)            AS ReceiptPeriod,
		|	RegisterData.VariancePeriod                      AS VariancePeriod,
		|	CorrectedDocuments_.Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	RegisterData.ItemsLocationAttributes,
		|	RegisterData.AccountingSection,
		|	RegisterData.InventoryOwnerAttribute,
		|	RegisterData.Organization,
		|	RegisterData.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	RegisterData.LotVendorAttributes,
		|	RegisterData.FinancialAccountingDimension,
		|	RegisterData.VATActivityType,
		|
		|	SUM(-RegisterData.Count) AS Count,
		|	SUM(CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterData.Cost ELSE RegisterData.Cost END) AS Cost,
		|	SUM(CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterData.CostExcludingVAT ELSE RegisterData.CostExcludingVAT END) AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	SUM(CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterData.CostMan ELSE RegisterData.CostMan END) AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	SUM(CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterData.LocalCost ELSE RegisterData.LocalCost END) AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	SUM(CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterData.PermanentDifference ELSE RegisterData.PermanentDifference END) AS PermanentDifference,
		|	SUM(CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterData.CostTD ELSE RegisterData.CostTD END) AS CostTD,
		|	SUM(CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterData.CostOfPersonalIncomeTax ELSE RegisterData.CostOfPersonalIncomeTax END) AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	UNDEFINED AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	RegisterData.AccountingDimensionByPartners,
		|	RegisterData.SalesOrder,
		|	RegisterData.Department,
		|	RegisterData.DimensionOfExpenses,
		|	RegisterData.ExpenseItemOfWriteOff,
		|	RegisterData.IncomeItem,
		|	RegisterData.DimensionOfRevenue,
		|	RegisterData.SalePeriod,
		|	RegisterData.AssetAndLiabilityItem,
		|	RegisterData.AssetsLiabilitiesDimension,
		|	RegisterData.DocumentRegisterRecords,
		|	RegisterData.RowID,
		|	UNDEFINED AS ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	RegisterData.DocumentVATActivityType,
		|	RegisterData.VATActivityTypeShipments,
		|	RegisterData.FinancialAccountingDimensionOfDocument,
		|	RegisterData.CostAccountingTransaction,
		|	SUM(-RegisterData.VATManag) AS VATManag,
		|	SUM(-RegisterData.VATLocal) AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	RegisterData.Recorder AS DocumentSource,
		|	(CASE
		|		WHEN VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE CorrectedDocuments_.Recorder END) AS PrioritySource,
		|	UNDEFINED AS CorLineOfBusiness,
		|	UNDEFINED AS RowCode,
		|	UNDEFINED AS CCDNumber,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	UNDEFINED AS FinRecordID,
		|	UNDEFINED AS GLAccountSettings,
		|	TRUE AS ReversingEntry,
		|	RegisterData.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	RegisterData.CostDefiningMethod,
		|	RegisterData.CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS RegisterData
		|	INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = RegisterData.Recorder
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = RegisterData.Lot
		|		AND NOT Register3.AdditionalRecord
		|		AND RegisterData.Lot <> UNDEFINED
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = RegisterData.Lot
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = RegisterData.Lot
		|WHERE
		|	RegisterData.Organization IN (&CompanyArray)
		|	AND RegisterData.Period < &BeginOfPeriod
		|	AND RegisterData.Active
		|	AND VALUETYPE(RegisterData.Recorder) = TYPE(Document.VendorInvoice)
		|	AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT RegisterData.CalculationOfCost
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND RegisterData.Period < &DateOfMigrationToBatchAccounting22)
		|	AND NOT RegisterData.ReversingEntry
		|
		|GROUP BY
		|	RegisterData.ItemsLocationAttributes.Products,
		|	RegisterData.LotVendorAttributes.VATTaxation,
		|	CorrectedDocuments_.Period,
		|	(CASE
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		WHEN RegisterData.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		|		ELSE &EndOfPreviousPeriod END), // ReceiptPeriod
		|	RegisterData.VariancePeriod,
		|	CorrectedDocuments_.Recorder,
		|	RegisterData.ItemsLocationAttributes,
		|	RegisterData.AccountingSection,
		|	RegisterData.InventoryOwnerAttribute,
		|	RegisterData.Organization,
		|	RegisterData.Lot,
		|	RegisterData.LotVendorAttributes,
		|	RegisterData.FinancialAccountingDimension,
		|	RegisterData.VATActivityType,
		|	RegisterData.AccountingDimensionByPartners,
		|	RegisterData.SalesOrder,
		|	RegisterData.Department,
		|	RegisterData.DimensionOfExpenses,
		|	RegisterData.ExpenseItemOfWriteOff,
		|	RegisterData.IncomeItem,
		|	RegisterData.DimensionOfRevenue,
		|	RegisterData.SalePeriod,
		|	RegisterData.AssetAndLiabilityItem,
		|	RegisterData.AssetsLiabilitiesDimension,
		|	RegisterData.DocumentRegisterRecords,
		|	RegisterData.RowID,
		|	RegisterData.DocumentVATActivityType,
		|	RegisterData.VATActivityTypeShipments,
		|	RegisterData.FinancialAccountingDimensionOfDocument,
		|	RegisterData.CostAccountingTransaction,
		|	RegisterData.Recorder, // DocumentSource
		|	(CASE
		|		WHEN VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE CorrectedDocuments_.Recorder END), // PrioritySource
		|	RegisterData.LotCalculationPerformed,
		|	RegisterData.CostDefiningMethod,
		|	RegisterData.CostCalculationDate
		|";
EndFunction

// Filling out the payment batch

Procedure FillInEstimatedBatchOfInvoicesForDeliveries(CalculationParameters, SettlementBatch, Expense, Receipt)
	
	// To invoice the delivery, only the batch formed by the unfactured delivery should be selected,
	// except for reverse entries and purchase adjustments.
	If Expense.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
	 And Expense.EntryType = Enums.LotRecordTypes.Consumption
	 And Receipt.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
	 And Receipt.EntryType <> Enums.LotRecordTypes.ConsumptionReverseTransaction
	 And Not Receipt.ReversingEntry
	 Or Expense.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
	 And Expense.EntryType = Enums.LotRecordTypes.Consumption
	 And Receipt.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
	 And Receipt.EntryType <> Enums.LotRecordTypes.ConsumptionReverseTransaction
	 And Not Receipt.ReversingEntry Then
		Return;

	// an Debit note should not be a source for the acquisition itself.
	// The description of the chains is made uniform for this stage and the stage of filling Lot references in the cost price - there such chains are permissible.		
	ElsIf Receipt.EntryType = Enums.LotRecordTypes.ConsumptionReverseTransaction
	 And Expense.EntryType = Enums.LotRecordTypes.Consumption
	 And Expense.Recorder = Receipt.DocumentSource Then
	 	Return;
		
	// For the record type "Write-Off Of The Balance Without A Batch", only a source with an empty batch should be selected.
	// For such a source, There will Be No Balance Of Goods for Invoicing.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot
	 And ValueIsFilled(Receipt.Lot) Then
		Return;
		
	// To correct an unfactated post, a batch corresponding to the corrected receipt should be selected.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
	 And (Expense.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
	 	Or Expense.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
	 And ValueIsFilled(Receipt.Lot)
	 And ValueIsFilled(Expense.Lot)
	 And Receipt.Lot <> Expense.Lot Then
		Return;
	EndIf;
	
	SumResourcesByString = 
	"Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
	|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
	|LocalCost, PermanentDifference, CostTD,
	|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
	|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
	|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal, ItemizedFixedCostsCompl, ItemizedVariableCostsCompl,
	|CostOfPersonalIncomeTax";
	SummaryResources = New Structure(SumResourcesByString);
	TotalVATResources = New Structure("VATLocal, VATManag");
	
	// We fill out the settlement batch according to the expenditure batch-the basis
	FillPropertyValues(SettlementBatch, Expense);
	
	//	We fill in the batch identification in the settlement batch
	FillPropertyValues(SettlementBatch, Receipt, "Lot, LotVendorAttributes, TaxationOfParty, VATActivityType, FinancialAccountingDimension, ReceiptPeriod, ProductionOrder");
	
	If SettlementBatch.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod
	 And SettlementBatch.Count = 0 Then
		// The document source does not change, you need to save the record as it is
	ElsIf SettlementBatch.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
	 Or SettlementBatch.EntryType = Enums.LotRecordTypes.IncludeVATInCostExpenses
	 Or SettlementBatch.EntryType = Enums.LotRecordTypes.IncludeExciseInCost Then
		// The document source does not change, you need to save the record as it is
	ElsIf SettlementBatch.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified And Receipt.ReversingEntry Then
		// The document source does not change, you need to save the record as it is
	Else
		SettlementBatch.DocumentSource = Receipt.Recorder;
	EndIf;
	
	If SettlementBatch.RecordType = AccumulationRecordType.Receipt
	 And Expense.EntryType <> Enums.LotRecordTypes.PurchaseAdjustment Then
		
		// Filling in the Cor fields is used to determine the base for the allocation of additional expenses in the Template text request for Primary document receivers().
		SettlementBatch.CorVATActivityTypes = Receipt.VATActivityType;
		SettlementBatch.CorItemsLocationAttributes = Receipt.ItemsLocationAttributes;
		SettlementBatch.CorLot = Receipt.Lot;
		If SettlementBatch.EntryType <> Enums.LotRecordTypes.PurchaseAdjustment
		// For the application for the import of goods, the Party Accounting field remains the initial one, because it determines
		// the analysis of VAT accounting reflected in the document. 
		 And SettlementBatch.EntryType <> Enums.LotRecordTypes.AddExpensesLotIsSpecified Then
			SettlementBatch.LotVendorAttributesCorr = Receipt.LotVendorAttributes;
		EndIf;
		
		If ValueIsFilled(Receipt.CorCompany) Then
			SettlementBatch.CorCompany = Receipt.Organization;
		EndIf;
		
	EndIf;
	
	If SettlementBatch.RecordType = AccumulationRecordType.Expense
	 And Not ValueIsFilled(SettlementBatch.DocumentVATActivityType) Then
		SettlementBatch.CorVATActivityTypes = Receipt.VATActivityType;
	EndIf;
	
	// the calculated batch is filled with the largest total deductible
	If Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified
	 And Expense.Count <> 0 Then
	 	If Receipt.EntryType = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction Then
	 		NumberOfDebits = Min(Expense.Denominator, Receipt.Denominator);
			ParishBasis = ?(Receipt.Count <> 0, NumberOfDebits / Receipt.Denominator, 0);
	 	Else
			NumberOfDebits = Min(Expense.Denominator, Receipt.Count);
			ParishBasis = ?(Receipt.Count <> 0, NumberOfDebits / Receipt.Count, 0);
		EndIf;
		ConsumptionBasis = ?(Expense.Denominator <> 0, NumberOfDebits / Expense.Denominator, 0);
	
	// The purchase adjustment of the previous period does not have a quantity, so we use the first source completely.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod
	 Or Expense.EntryType = Enums.LotRecordTypes.CostAdjustment
	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost
	 Or Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified Then
		// For reverse additional expenses, the denominator is always equal to the receiver, because reverse is performed for the full amount.
		If Receipt.EntryType = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction
		 Or Expense.EntryType = Enums.LotRecordTypes.IncludeVATInCostExpenses
	 	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost Then 
			NumberOfDebits = 1;
		Else
			NumberOfDebits = Receipt.Count;
		EndIf;
		ParishBasis = 1;
		ConsumptionBasis = 1;
	Else
		NumberOfDebits = Min(Expense.Count, Receipt.Count);
		ParishBasis = ?(Receipt.Count <> 0, NumberOfDebits / Receipt.Count, 0);
		ConsumptionBasis = ?(Expense.Count <> 0, NumberOfDebits / Expense.Count, 0);
	EndIf;
	
	If NumberOfDebits = 0 Then
		Return;
	EndIf;
	
	// we fill in the indicators of the settlement batch
	If Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified
	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost
	 Or Expense.EntryType = Enums.LotRecordTypes.CostAdjustment
	 Or Expense.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod Then
		SettlementBatch.Count = 0;
	Else
		SettlementBatch.Count = Round(NumberOfDebits, 3);
	EndIf;
	
	For Each ResourceName In SummaryResources Do
		SettlementBatch[ResourceName.Key] = Round(ConsumptionBasis * SettlementBatch[ResourceName.Key], 2);
	EndDo;
	For Each ResourceName In TotalVATResources Do
		SettlementBatch[ResourceName.Key] = Round(ConsumptionBasis * SettlementBatch[ResourceName.Key], 2);
	EndDo;
	
	// adjusting the calculation base in the expense
	Expense.Count = Expense.Count - SettlementBatch.Count;
	For Each ResourceName In SummaryResources Do
		Expense[ResourceName.Key] = Expense[ResourceName.Key] - SettlementBatch[ResourceName.Key];
	EndDo;
	For Each ResourceName In TotalVATResources Do
		Expense[ResourceName.Key] = Expense[ResourceName.Key] - SettlementBatch[ResourceName.Key];
	EndDo;
	
	// adjusting the calculation base in the parish
	If Not (Receipt.EntryType = Enums.LotRecordTypes.PreviousPeriodCorrections
	 And Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
	 And Receipt.Recorder = Expense.Recorder) Then
		
		If Not Receipt.ThisIsReverseTransaction And SettlementBatch.ThisIsReverseTransaction
		 And SettlementBatch.EntryType = Enums.LotRecordTypes.Consumption Then	
			Receipt.Count = Receipt.Count + SettlementBatch.Count;
		Else
			Receipt.Count = Receipt.Count - SettlementBatch.Count;
			// When adjusting the acquisition, it is necessary to adjust the quantitative and cost indicators in the source. 
			If Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment Then
				For Each ResourceName In SummaryResources Do
					SummaryResources[ResourceName.Key] = Round(ParishBasis * Receipt[ResourceName.Key], 2);
					Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SettlementBatch[ResourceName.Key];
				EndDo;
				For Each ResourceName In TotalVATResources Do
					Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SettlementBatch[ResourceName.Key];
				EndDo;
			EndIf;
		EndIf;
		
	EndIf;
	
	// Based on the results of batch identification, we determine the completeness of the calculation
	SettlementBatch.CalculationIsCompleted = Receipt.CalculationIsCompleted;
	
	// Deviations in the cost of goods
	#Region DeviationsInCost
	
	// When adjusting the purchase, the summary resources have already been filled in earlier.
	If Expense.EntryType <> Enums.LotRecordTypes.PurchaseAdjustment Then
		For Each ResourceName In SummaryResources Do
			SummaryResources[ResourceName.Key] = Round(ParishBasis * Receipt[ResourceName.Key], 2);
			Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SummaryResources[ResourceName.Key];
		EndDo;
	EndIf;
		
	ThereAreVariances = False;
	
	// Deviations in the cost are calculated for invoicing the delivery and for adjusting the unfactated delivery,
	// except for the reverse unfactated delivery, because when reversing, the cost of the original batch does not change and deviations should not occur,
	// except (for additional expenses) reverse the source of the invoiced delivery, because the deviation is considered for the reversing document, and for the current one should be ignored.
	// in addition to reducing the invoice for the delivery of the previous period, because such a correction returns the batch of 
	// goods received to the warehouse, and deviations are calculated only when the batch of goods received is written off.
	// The conditions for calculating deviations in the cost must correspond to the procedure for filling in the calculation partyusebest value of goods().
	If (Expense.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
			And (Not Receipt.ReversingEntry 
				Or Expense.EntryType <> Enums.LotRecordTypes.AddExpensesLotIsSpecified
				And Expense.EntryType <> Enums.LotRecordTypes.IncludeExciseInCost)
		Or Expense.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
			And (Not Receipt.ReversingEntry
				Or Expense.EntryType <> Enums.LotRecordTypes.AddExpensesLotIsSpecified
				And Expense.EntryType <> Enums.LotRecordTypes.IncludeExciseInCost)
		Or Expense.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
			And Not Expense.ReversingEntry
		Or Expense.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
			And Not Expense.ReversingEntry)
		And Not (Receipt.EntryType = Enums.LotRecordTypes.Previous And Expense.EntryType = Enums.LotRecordTypes.ConsumptionReverseTransaction)
		And Expense.EntryType <> Enums.LotRecordTypes.PurchaseAdjustment Then
			
		For Each ResourceName In SummaryResources Do
			If SettlementBatch[ResourceName.Key] - SummaryResources[ResourceName.Key] <> 0 Then
			 	ThereAreVariances = True;
			 	Break;
			EndIf;
		EndDo;
		// Deviations in the cost of VAT amounts should be calculated only for goods that have arrived at the warehouse,
		// because for VAT purposes, only movements with the accounting section other than "Unfactated deliveries"
		// are selected. See the request for the formation of a temporary table of arrivals of goods IN2_4 in the function of the text request for the preparation of data distribution data().
		// For unfactated services, you need to calculate VAT deviations, because the VAT amount is used
		// when calculating the detail of the batches.
		// See the request for the formation of a temporary table of the time spent for the distributionproductive in the text allocation function of the expenses of the
		// general module of the calculation of the cost of the index.
	 	If Not ThereAreVariances And ValueIsFilled(Receipt.CorAccountingSection)
	 	 Or Not ThereAreVariances And TypeOf(Receipt.Lot) = Type("DocumentRef.ReceiptOfServicesToBusinessUnit") Then
			For Each ResourceName In TotalVATResources Do
				If SettlementBatch[ResourceName.Key] <> 0 Then
				 	ThereAreVariances = True;
				 	Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
		
	// fill in the cor Attributes in the incoming movement. They will be needed to allocate additional expenses.
	AttributeDeviationsToOtherIncomeExpenses = False;
	If Expense.RecordType = AccumulationRecordType.Receipt Then
		FillPropertyValues(SettlementBatch, Receipt, "CorItemsLocationAttributes, CorAccountingSection, CorInventoryOwnerAttribute, CorLot, LotVendorAttributesCorr,
			|Department, ExpenseItemOfWriteOff, DimensionOfExpenses, CorLineOfBusiness");
			
		// For the application for the import of goods, the Party Accounting field remains the initial one, because it determines
		// the analysis of VAT accounting reflected in the document. 
		If SettlementBatch.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified Then
			SettlementBatch.LotVendorAttributesCorr = Expense.LotVendorAttributesCorr;
		EndIf;
	EndIf;
	If Not CalculationParameters.FederalDistrict.AllocationOfAdditionalExpensesByDisposedGoods 
	 And Receipt.ReceiptPeriod < CalculationParameters.PayrollPeriod.BeginOfPeriod Then
		AttributeDeviationsToOtherIncomeExpenses = True;
	EndIf;
		
	// Deviations between the actual and contractual cost.
	If ThereAreVariances Then
		Variances = CostCalculationAppliedAlgorithms.AddSettlementBatch(CalculationParameters, SettlementBatch, False);
		
		DeviationsTotal = 0;
		For Each ResourceName In SummaryResources Do
			// The entire amount of additional costs for non-invoiced deliveries is attributed to a deviation in cost. 
			If Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified
			 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost Then
				Variances[ResourceName.Key] = SettlementBatch[ResourceName.Key];
			Else
				Variances[ResourceName.Key] = SettlementBatch[ResourceName.Key] - SummaryResources[ResourceName.Key];
				DeviationsTotal = DeviationsTotal  + Variances[ResourceName.Key]; 
			EndIf;
		EndDo;
		
		Variances.RecordType = AccumulationRecordType.Expense;
		Variances.Count  = 0;
		Variances.DocumentSource = Undefined;
		
		If SettlementBatch.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified And Variances.AddExpensesLocal <> 0
			And Variances.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.IncludeVATInCostExpenses Then
			Variances.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.ExpenseAllocationToCost;
		ElsIf SettlementBatch.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified And Not Receipt.BusinessTransactionSetting.IsEmpty() Then
			Variances.BusinessTransactionSetting = Receipt.BusinessTransactionSetting;
		EndIf;
		
		If TypeOf(Variances.Recorder) = Type("DocumentRef.WriteOffDiscrepanciesBetweenReceiptAndPurchase") Then
			If DeviationsTotal < 0 Then
				Variances.EntryType = Enums.LotRecordTypes.CostVarianceForOtherIncome;
			Else
				Variances.EntryType = Enums.LotRecordTypes.GoodsCostVarianceForOtherExpenses;
			EndIf;
		
		ElsIf Not AttributeDeviationsToOtherIncomeExpenses 
		 And (ValueIsFilled(Receipt.CorAccountingSection)
		 	And ValueIsFilled(Receipt.Lot)
		 	Or (Expense.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
		 		And (Variances.AccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductStock
		 		Or Variances.AccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductionCosts))) Then
			Variances.EntryType = Enums.LotRecordTypes.CostVariance;
			
		// Deviations in works or services written off as expenses are reflected in the cost analysis, regardless of the deviation sign.
		ElsIf Not ValueIsFilled(SettlementBatch.InventoryOwnerAttribute) Then
			Variances.EntryType = Enums.LotRecordTypes.GoodsCostVarianceForOtherExpenses;
			FillPropertyValues(Variances, Receipt, "Department, ExpenseItemOfWriteOff, DimensionOfExpenses, CorLineOfBusiness");
			If Not ValueIsFilled(Variances.ExpenseItemOfWriteOff) Then
				Variances.ExpenseItemOfWriteOff = ChartsOfCharacteristicTypes.ExpenseItems.GoodsValueVariance;
				Variances.DimensionOfExpenses = Expense.Products;
			EndIf;
			
		ElsIf DeviationsTotal < 0 Then
		// The formation of movements according to the register "Other income" is performed in the general module "Calculation of the cost of cost correction"
		// in the procedure for the formation of the movement of deviations in the cost of goods () #The area of deviation in the cost of income.
			Variances.EntryType = Enums.LotRecordTypes.CostVarianceForOtherIncome;
			Variances.IncomeItem = ChartsOfCharacteristicTypes.IncomeItems.GoodsValueVariance;
			Variances.DimensionOfRevenue = Expense.Products;
		Else
		// The formation of Registered Records according to the register "Other expenses" is performed in the general module "Calculation of the Cost of cost correction"
		// in the procedure for the formation of the movement of deviations in the cost of goods () #The area of deviation in the cost of expenses.
			Variances.EntryType = Enums.LotRecordTypes.GoodsCostVarianceForOtherExpenses;
			Variances.ExpenseItemOfWriteOff = ChartsOfCharacteristicTypes.ExpenseItems.GoodsValueVariance;
			Variances.DimensionOfExpenses = Expense.Products;
		EndIf;
		Variances.ReversingEntry = False;
		
		If Variances.EntryType = Enums.LotRecordTypes.GoodsCostVarianceForOtherExpenses Then
			Variances.FinRecordID = String(New UUID());
		ElsIf ValueIsFilled(Variances.RowID) Then
			Variances.FinRecordID = Variances.RowID;
		EndIf;
		
		Variances.LotCalculationPerformed = True;
		Variances.VariancePeriod    = Receipt.ReceiptPeriod;
		Variances.MonthEndClosingMode = CalculationParameters.MonthEndClosingMode;
		
		// In the calculated amounts of deviations, you need to change the sign if there was a negative amount in the line for which the deviations were calculated 
		// . In such a line, the It is Currently flag is set. 
		Indicators = CalculationParameters.DistributionOfParties.RegisterRecordsDetails.Indicators;
		CostCalculationAppliedAlgorithms.InvertMetrics(Variances, Indicators, SettlementBatch.ThisIsReverseTransaction); 
		
		// Deviations are reflected as additional. expenses.
		If ValueIsFilled(Receipt.CorAccountingSection) And Not AttributeDeviationsToOtherIncomeExpenses
		 And Variances.EntryType = Enums.LotRecordTypes.CostVariance Then
			
			DeliveryToWarehouse = CostCalculationAppliedAlgorithms.AddSettlementBatch(CalculationParameters,, False);
			FillPropertyValues(DeliveryToWarehouse, Variances,
				"Period, Recorder, InventoryOwnerAttribute, Organization, FinancialAccountingDimension, VATActivityType, BusinessOperation, DocumentSource,
				|FinRecordID, BusinessTransactionSetting, LotVendorAttributesCorr,
				|VATLocal, VATManag, CalculationIsCompleted");
			
			DeliveryToWarehouse.ItemsLocationAttributes = Receipt.CorItemsLocationAttributes;
			DeliveryToWarehouse.AccountingSection 				 = Receipt.CorAccountingSection;
			DeliveryToWarehouse.InventoryOwnerAttribute 				 = Receipt.CorInventoryOwnerAttribute;
			DeliveryToWarehouse.Lot 					 = Receipt.CorLot;
			DeliveryToWarehouse.LotVendorAttributes  	 = Receipt.LotVendorAttributesCorr;
			// When accounting for the average cost, it is necessary to fill in the Party Data Analysis field from the Party Analysis field of the source.
			// The field of Coralitika of the Party account is used in the stage of formation of Registered Records according to the register of detailationparty goods of the country.
			// It is the same with the Expenditure analysis and Document Source fields - they are used to determine the batch.
			If Not ValueIsFilled(DeliveryToWarehouse.Lot) Then
				DeliveryToWarehouse.LotVendorAttributesCorr = Receipt.LotVendorAttributes;
			EndIf;
			DeliveryToWarehouse.EntryType 				 = Enums.LotRecordTypes.CostVariance;
			DeliveryToWarehouse.AddExpensesForGoods 				 = Variances.Cost + Variances.AddExpensesForGoods;
			DeliveryToWarehouse.AdditionalExpensesExcludingVAT 			 = Variances.CostExcludingVAT + Variances.AdditionalExpensesExcludingVAT;
			DeliveryToWarehouse.AddExpensesMan 			 = Variances.CostMan + Variances.AddExpensesMan;
			DeliveryToWarehouse.AddExpensesLocal 			 = Variances.LocalCost + Variances.AddExpensesLocal;
			DeliveryToWarehouse.CostTD 			 = Variances.CostTD;
			DeliveryToWarehouse.PermanentDifference 		 = Variances.PermanentDifference;
			DeliveryToWarehouse.CostOfPersonalIncomeTax				 = Variances.CostOfPersonalIncomeTax;
			DeliveryToWarehouse.DimensionOfExpenses 		 = Receipt.Lot;
			DeliveryToWarehouse.DocumentSource 			 = Receipt.Lot;
			DeliveryToWarehouse.LotCalculationPerformed		 = True;
			DeliveryToWarehouse.VariancePeriod			 = Receipt.ReceiptPeriod;
			DeliveryToWarehouse.MonthEndClosingMode		 = CalculationParameters.MonthEndClosingMode;
			
			CostCalculationAppliedAlgorithms.InvertMetrics(DeliveryToWarehouse, Indicators, SettlementBatch.ThisIsReverseTransaction); 
			
		EndIf;
		
	EndIf;
	
	#EndRegion
		
	SettlementBatch.LotCalculationPerformed = True;
	SettlementBatch.MonthEndClosingMode = CalculationParameters.MonthEndClosingMode;
	
EndProcedure

#EndRegion

#Region ProcedureOfStage_InvoicingOfDeliveriesAtMediumSlip

Procedure InvoicingOfDeliveriesAtMediumSlip(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "InvoicingOfDeliveriesAtMediumSlip");
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	#Region DataPreparation
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
	|SELECT
	|	Invoices_1.ItemsLocationAttributes,
	|	Invoices_1.InventoryOwnerAttribute,
	|	Invoices_1.Organization,
	|	Invoices_1.Lot AS Lot,
	|	Invoices_1.LotVendorAttributes AS LotVendorAttributes,
	|	Invoices_1.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Invoices_1.VATActivityType AS VATActivityType,
	|	MAX(Invoices_1.FinRecordID) AS FinRecordID
	|
	|INTO InvoicesOfDeliveriesIdsOfFinRecord
	|FROM
	|	AccumulationRegister.InventoryCost AS Invoices_1
	|WHERE
	|	Invoices_1.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Invoices_1.Organization IN (&MediumSlipOrganizations)
	|	AND Invoices_1.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Invoices_1.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|	AND Invoices_1.LotCalculation
	|	AND Invoices_1.FinRecordID <> &IDOfUnusedFinRecord
	|GROUP BY
	|	Invoices_1.ItemsLocationAttributes,
	|	Invoices_1.InventoryOwnerAttribute,
	|	Invoices_1.Organization,
	|	Invoices_1.Lot,
	|	Invoices_1.LotVendorAttributes,
	|	Invoices_1.FinancialAccountingDimension,
	|	Invoices_1.VATActivityType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	Balance.ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.Organization,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Balance.VATActivityType AS VATActivityType,
	// Resources
	|	Balance.Count AS Count,
	|	Balance.Cost AS Cost,
	|	Balance.CostExcludingVAT AS CostExcludingVAT,
	|	Balance.LocalCost AS LocalCost,
	|	Balance.CostMan AS CostMan,
	|	Balance.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|
	|INTO InvoicesOfDeliveriesPreliminary
	|FROM
	|	TTCashSettlementBalancesCostOfGoods AS Balance
	|WHERE
	|	Balance.Count > 0
	|	AND Balance.Organization IN (&MediumSlipOrganizations)
	|	AND Balance.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.RecNo
	|FROM
	|	InvoicesOfDeliveriesPreliminary AS T
	|";
	
	IDsTable = New ValueTable;
	IDsTable.Columns.Add("Id", Common.StringTypeDetails(36));
	IDsTable.Columns.Add("RecNo", Common.TypeDescriptionNumber(31));
	
	Selection = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	While Selection.Next() Do
		NewRow = IDsTable.Add();
		NewRow.Id = New UUID;
		NewRow.RecNo = Selection.RecNo;
	EndDo;
	
	Query.SetParameter("IDsTable", IDsTable);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "InvoicesOfDeliveriesPreliminary") = 0 Then
		
		// We will destroy unnecessary temporary tables.
		NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, ExistingTT);
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
		
		Return;
		
	EndIf;
	
	Query.Text = "
	|SELECT
	|	IDsTable.Id AS Id,
	|	IDsTable.RecNo AS RecNo
	|INTO IDsTable
	|FROM
	|	&IDsTable AS IDsTable
	|INDEX BY
	|	RecNo
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.Organization AS Organization,
	|	Balance.Lot AS CorLot,
	|	Balance.LotVendorAttributes AS LotVendorAttributesCorr,
	|	Balance.FinancialAccountingDimension AS CorControllingAttributes,
	|	Balance.VATActivityType AS CorVATActivityTypes,
	|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
	|	IDsTable.Id AS FinRecordID,
	// Resources
	|	Balance.Count AS Count,
	|	Balance.Cost AS Cost,
	|	Balance.CostExcludingVAT AS CostExcludingVAT,
	|	Balance.LocalCost AS LocalCost,
	|	Balance.CostMan AS CostMan,
	|	Balance.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|
	|INTO InvoicesOfDeliveriesLeftovers
	|FROM
	|	InvoicesOfDeliveriesPreliminary AS Balance
	|		LEFT JOIN IDsTable AS IDsTable
	|		ON IDsTable.RecNo = Balance.RecNo
	|
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.Ref = Balance.Lot
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsRegistry.IBDocumentDate AS Period,
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Balance.Organization AS Organization,
	|	Balance.Lot AS Lot,
	|	Balance.LotVendorAttributes AS LotVendorAttributes,
	|	Balance.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Balance.VATActivityType AS VATActivityType,
	|	Balance.Lot AS CorLot,
	|	Balance.LotVendorAttributes AS LotVendorAttributesCorr,
	|	Balance.FinancialAccountingDimension AS CorControllingAttributes,
	|	Balance.VATActivityType AS CorVATActivityTypes,
	|	ISNULL(IDs.FinRecordID, """") AS IdOfFinRecordEx,
	// Resources.
	|	Balance.Count
	|INTO UninvoicedDeliveriesBalance
	|FROM
	|	TTCashSettlementBalancesCostOfGoods AS Balance
	|
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|	ON Balance.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|
	|	INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.Ref = Balance.Lot
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|	LEFT JOIN InvoicesOfDeliveriesIdsOfFinRecord AS IDs
	|	ON IDs.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND IDs.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND IDs.Organization = Balance.Organization
	|		AND IDs.Lot = Balance.Lot
	|		AND IDs.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND IDs.FinancialAccountingDimension = Balance.FinancialAccountingDimension
	|		AND IDs.VATActivityType = Balance.VATActivityType
	|WHERE
	|	Balance.Count < 0
	|	AND Balance.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|	AND (
	|		Balance.ItemsLocationAttributes,
	|		Balance.InventoryOwnerAttribute,
	|		Balance.Organization) IN (
	|			SELECT
	|				Lots.ItemsLocationAttributes,
	|				Lots.InventoryOwnerAttribute,
	|				Lots.Organization
	|			FROM
	|				InvoicesOfDeliveriesLeftovers AS Lots
	|			)
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	#EndRegion
	
	#Region DataDistribution
	
	// Initializing the distribution
	DistributionParameters = CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod(
		"InvoicesOfDeliveriesLeftovers",
		"UninvoicedDeliveriesBalance",
		"ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
		
	CostCalculationUniversalAlgorithms.InitializeNumericalDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		"Cost,CostExcludingVAT,LocalCost,CostMan,CostOfPersonalIncomeTax");
		
	CostCalculationUniversalAlgorithms.InitializeOtherDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		"CorLot, LotVendorAttributesCorr, CorControllingAttributes, CorVATActivityTypes, BusinessOperation, FinRecordID",
		"Lot, LotVendorAttributes, FinancialAccountingDimension, VATActivityType, IdOfFinRecordEx");
		
	// We distribute
	CostCalculationAppliedAlgorithms.DistributeByMethodOfReducedResidueWithTimeMeasurement(
		CalculationParameters,
		DistributionParameters,
		"DistributeUsingReducedRemainderMethod",
		"InvoicingOfDeliveriesAtMediumSlip");
		
	If DistributionParameters.DistributionResults.ResultSize = 0 Then
		
		// We will destroy unnecessary temporary tables.
		NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, ExistingTT);
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
		
		Return; // there is no distributed data
		
	EndIf;
	
	#EndRegion
	
	#Region FormationOfRegisteredRecords
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "InvoicingOfDeliveriesAtMediumSlip_FormationOfRegisteredRecorded");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTOfRegisteredRecordsOfInvoiceOfDeliveries, TTOfRegisteredRecordedDeviationsInCost");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		InvoicingOfDeliveriesWithMediumSlipFormationOfRegisteredRecords(CalculationParameters));
		
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	// Cost of goods.
	TempTableName = "TTInvoicingOfDeliveriesInventoryCostsAreMediumSliding";
	RegisterName = Metadata.AccumulationRegisters.InventoryCost.Name;
	ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
	TemporaryTableNameSource = "TTOfRegisteredRecordsOfInvoiceOfDeliveries";
	
	CopiedFields = CostCalculationUniversalAlgorithms.GetColumnNamesOfTemporaryTableByString(CalculationParameters, TemporaryTableNameSource);
	
	FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
	CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
	
	CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(CalculationParameters, FieldDescriptionTable, 
		RegisterName, TemporaryTableNameSource, TempTableName);
	
	MatchingTemporaryMovementTables = New Map;
	MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
	
	// Deviation in the cost of goods.
	TempTableName = "TTInvoiceOfDeliveriesDeviationsInCostOfGoodsIsMediumSliding";
	RegisterName = Metadata.AccumulationRegisters.GoodsCostVariances.Name;
	ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
	TemporaryTableNameSource = "TTOfRegisteredRecordedDeviationsInCost";
	
	CopiedFields = CostCalculationUniversalAlgorithms.GetColumnNamesOfTemporaryTableByString(CalculationParameters, TemporaryTableNameSource);
	
	FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
	CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
	
	CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(CalculationParameters, FieldDescriptionTable, 
		RegisterName, TemporaryTableNameSource, TempTableName);
	
	MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.CacheGeneratedRegisteredRecordsFromTemporaryTables(CalculationParameters, MatchingTemporaryMovementTables);
	
	// We will destroy unnecessary temporary tables.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, ExistingTT);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
EndProcedure

Function InvoicingOfDeliveriesWithMediumSlipFormationOfRegisteredRecords(CalculationParameters)
	
	QueryText = "";
	
	#Region UninvoicedDeliveries
	QueryText = QueryText + "
	|SELECT
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.AccountingSection AS AccountingSection,
	|	MAX(DD.CorItemsLocationAttributes) AS CorItemsLocationAttributes,
	|	MAX(DD.CorInventoryOwnerAttribute) AS CorInventoryOwnerAttribute,
	|	MAX(DD.CorAccountingSection) AS CorAccountingSection,
	|	MAX(ISNULL(ArrivalAtWarehouse.Lot, UNDEFINED)) AS CorLot,
	|	MAX(ISNULL(ArrivalAtWarehouse.LotVendorAttributes, UNDEFINED)) AS LotVendorAttributesCorr,
	|
	// Cost reflection analytics
	|	MAX(DD.Department) AS Department,
	|	MAX(DD.ExpenseItemOfWriteOff) AS ExpenseItemOfWriteOff,
	|	MAX(DD.DimensionOfExpenses) AS DimensionOfExpenses,
	|	MAX(DD.CorLineOfBusiness) AS CorLineOfBusiness
	|	
	|INTO UninvoicedDeliveries
	|FROM
	|	UninvoicedDeliveriesBalance AS Balance
	|
	|	INNER JOIN AccumulationRegister.InventoryCost AS DD
	|		ON DD.Recorder = Balance.Lot
	|		AND DD.Period = Balance.Period
	|		AND DD.Lot = Balance.Lot
	|		AND DD.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND NOT DD.ReversingEntry
	|	LEFT JOIN AccumulationRegister.InventoryCost AS ArrivalAtWarehouse
	|		ON ArrivalAtWarehouse.Recorder = Balance.Lot
	|		AND ArrivalAtWarehouse.Period = Balance.Period
	|		AND ArrivalAtWarehouse.Lot = Balance.Lot
	|		AND ArrivalAtWarehouse.ItemsLocationAttributes = DD.CorItemsLocationAttributes
	|		AND ArrivalAtWarehouse.InventoryOwnerAttribute = DD.CorInventoryOwnerAttribute
	|		AND ArrivalAtWarehouse.AccountingSection = DD.CorAccountingSection
	|		AND ArrivalAtWarehouse.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND NOT ArrivalAtWarehouse.ReversingEntry
	|GROUP BY
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.AccountingSection AS AccountingSection,
	|	MAX(DD.CorItemsLocationAttributes) AS CorItemsLocationAttributes,
	|	MAX(DD.CorInventoryOwnerAttribute) AS CorInventoryOwnerAttribute,
	|	MAX(DD.CorAccountingSection) AS CorAccountingSection,
	|	MAX(ISNULL(ArrivalAtWarehouse.Lot, UNDEFINED)) AS CorLot,
	|	MAX(ISNULL(ArrivalAtWarehouse.LotVendorAttributes, UNDEFINED)) AS LotVendorAttributesCorr,
	|
	// Cost reflection analytics
	|	MAX(DD.Department) AS Department,
	|	MAX(DD.ExpenseItemOfWriteOff) AS ExpenseItemOfWriteOff,
	|	MAX(DD.DimensionOfExpenses) AS DimensionOfExpenses,
	|	MAX(DD.CorLineOfBusiness) AS CorLineOfBusiness
	|FROM
	|	UninvoicedDeliveriesBalance AS Balance
	|
	|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Balance.Lot = Register3.CorrectedDocument
	|		AND NOT Register3.AdditionalRecord
	|		AND Register3.ReverseTransactionCorrection
	|
	|	INNER JOIN AccumulationRegister.InventoryCost AS DD
	|		ON DD.Recorder = Register3.Ref
	|		AND DD.Lot = Balance.Lot
	|		AND DD.LotVendorAttributes = Balance.LotVendorAttributes
	|		AND DD.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|		AND DD.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
	|		AND DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND NOT DD.ReversingEntry
	|
	|	LEFT JOIN AccumulationRegister.InventoryCost AS ArrivalAtWarehouse
	|		ON ArrivalAtWarehouse.Recorder = Register3.Ref
	|		AND ArrivalAtWarehouse.Period = Balance.Period
	|		AND ArrivalAtWarehouse.Lot = Balance.Lot
	|		AND ArrivalAtWarehouse.ItemsLocationAttributes = DD.CorItemsLocationAttributes
	|		AND ArrivalAtWarehouse.InventoryOwnerAttribute = DD.CorInventoryOwnerAttribute
	|		AND ArrivalAtWarehouse.AccountingSection = DD.CorAccountingSection
	|		AND ArrivalAtWarehouse.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND NOT ArrivalAtWarehouse.ReversingEntry
	|GROUP BY
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.ItemsLocationAttributes,
	|	DD.InventoryOwnerAttribute,
	|	DD.AccountingSection
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	AccountingSection
	|;";
	#EndRegion
	
	#Region TTOfRegisteredRecordsOfInvoiceOfDeliveries
	QueryText = QueryText + "
	// Write-off of the Balance of unfactured deliveries.
	|SELECT
	|	""1"" AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
	|	&EndOfPeriod AS Period,
	|	TTCostCalculationRecorders.Ref AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// Changes
	|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries) AS AccountingSection,
	|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DD.Organization AS Organization,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	DD.VATActivityType AS VATActivityType,
	// Resources
	|	DD.Count		AS Count,
	|	DD.Cost		AS Cost,
	|	DD.CostExcludingVAT	AS CostExcludingVAT,
	|	DD.LocalCost	AS LocalCost,
	|	DD.CostMan		AS CostMan,
	|	0					AS PermanentDifference,
	|	0					AS CostTD,
	|	DD.CostOfPersonalIncomeTax		AS CostOfPersonalIncomeTax,
	// Attributes
	|	UninvoicedDeliveries.CorAccountingSection AS CorAccountingSection,
	|	UninvoicedDeliveries.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	UninvoicedDeliveries.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	DD.CorLot AS CorLot,
	|	DD.LotVendorAttributesCorr AS LotVendorAttributesCorr,
	|	UNDEFINED AS CorControllingAttributes,
	|	UNDEFINED AS CorVATActivityTypes,
	|	UNDEFINED AS CorLineOfBusiness,
	|	DD.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS ExpenseItemOfWriteOff,
	|	UNDEFINED AS DimensionOfExpenses,
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	TRUE AS ThisIsExactlyCalculatedMovement
	|
	|INTO TTOfRegisteredRecordsOfInvoiceOfDeliveries
	|FROM
	|	TTDistributionResult AS DD
	|	INNER JOIN TTCostCalculationRecorders AS TTCostCalculationRecorders
	|		ON TTCostCalculationRecorders.Organization = DD.Organization
	|
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = DD.BusinessOperation
	|
	|	LEFT JOIN UninvoicedDeliveries AS UninvoicedDeliveries
	|		ON UninvoicedDeliveries.Lot = DD.Lot
	|		AND UninvoicedDeliveries.LotVendorAttributes = DD.LotVendorAttributes
	|		AND UninvoicedDeliveries.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND UninvoicedDeliveries.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND UninvoicedDeliveries.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|WHERE
	|	(DD.Cost <> 0 OR DD.CostExcludingVAT <> 0 OR DD.LocalCost <> 0 OR DD.CostMan <> 0
	|		OR DD.CostOfPersonalIncomeTax <> 0)
	|
	|UNION ALL
	|
	// Deviations in the cost between invoicing and the cost of acquisition.
	|SELECT
	|	""2"" AS RequestSource,
	|	CASE
	|		WHEN UninvoicedDeliveries.ExpenseItemOfWriteOff <> UNDEFINED
	|		 AND UninvoicedDeliveries.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses)
	|		ELSE VALUE(Enum.LotRecordTypes.CostVariance)
	|	END AS EntryType,
	|	&EndOfPeriod AS Period,
	|	TTCostCalculationRecorders.Ref AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	// Changes
	|	DD.ItemsLocationAttributes,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|	DD.InventoryOwnerAttribute,
	|	DD.Organization,
	|	DD.Lot AS Lot,
	|	DD.LotVendorAttributes AS LotVendorAttributes,
	|	DD.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	DD.VATActivityType AS VATActivityType,
	// Resources
	|	0 AS Count,
	|	CAST(DD.Cost - DD.Count * ISNULL(Prices.Cost, 0) AS NUMBER(31,2)) AS Cost,
	|	CAST(DD.CostExcludingVAT - DD.Count * ISNULL(Prices.CostExcludingVAT, 0) AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(DD.LocalCost - DD.Count * ISNULL(Prices.LocalCost, 0) AS NUMBER(31,2)) AS LocalCost,
	|	CAST(DD.CostMan - DD.Count * ISNULL(Prices.CostMan, 0) AS NUMBER(31,2)) AS CostMan,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	CAST(DD.CostOfPersonalIncomeTax - DD.Count * ISNULL(Prices.CostOfPersonalIncomeTax, 0) AS NUMBER(31,2)) AS CostOfPersonalIncomeTax,
	// Attributes
	|	UninvoicedDeliveries.CorAccountingSection AS CorAccountingSection,
	|	UninvoicedDeliveries.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	UninvoicedDeliveries.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	UNDEFINED AS CorLot,
	|	UNDEFINED AS LotVendorAttributesCorr,
	|	UNDEFINED AS CorControllingAttributes,
	|	UNDEFINED AS CorVATActivityTypes,
	|	UninvoicedDeliveries.CorLineOfBusiness AS CorLineOfBusiness,
	|	DD.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	UninvoicedDeliveries.Department AS Department,
	|	UninvoicedDeliveries.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
	|	UninvoicedDeliveries.DimensionOfExpenses AS DimensionOfExpenses,
	|	(CASE
	|		WHEN DD.IdOfFinRecordEx <> """" THEN DD.IdOfFinRecordEx
	|		ELSE DD.FinRecordID END) AS FinRecordID,
	|	TRUE AS ThisIsExactlyCalculatedMovement
	|FROM
	|	TTDistributionResult AS DD
	|
	|	INNER JOIN TTCostCalculationRecorders AS TTCostCalculationRecorders
	|		ON TTCostCalculationRecorders.Organization = DD.Organization
	|
	|	LEFT JOIN TTValueOfBatchesOfGoods AS Prices
	|		ON Prices.Lot = DD.Lot
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributes
	|		AND Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Prices.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|
	|	LEFT JOIN UninvoicedDeliveries AS UninvoicedDeliveries
	|		ON UninvoicedDeliveries.Lot = DD.Lot
	|		AND UninvoicedDeliveries.LotVendorAttributes = DD.LotVendorAttributes
	|		AND UninvoicedDeliveries.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND UninvoicedDeliveries.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND UninvoicedDeliveries.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = DD.BusinessOperation
	|
	|UNION ALL
	|
	// Write-off of the Balance of the invoice of deliveries.
	|SELECT
	|	""3"" AS RequestSource,
	|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
	|	&EndOfPeriod AS Period,
	|	TTCostCalculationRecorders.Ref AS Recorder,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	// Changes
	|	DD.ItemsLocationAttributes,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|	DD.InventoryOwnerAttribute,
	|	DD.Organization,
	|	DD.CorLot AS Lot,
	|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
	|	DD.CorControllingAttributes AS FinancialAccountingDimension,
	|	DD.CorVATActivityTypes AS VATActivityType,
	// Resources
	|	DD.Count		AS Count,
	|	DD.Cost			AS Cost,
	|	DD.CostExcludingVAT		AS CostExcludingVAT,
	|	DD.LocalCost		AS LocalCost,
	|	DD.CostMan			AS CostMan,
	|	0						AS PermanentDifference,
	|	0						AS CostTD,
	|	DD.CostOfPersonalIncomeTax			AS CostOfPersonalIncomeTax,
	// Attributes
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
	|	DD.Lot AS CorLot,
	|	DD.LotVendorAttributes AS LotVendorAttributesCorr,
	|	DD.FinancialAccountingDimension AS CorControllingAttributes,
	|	DD.VATActivityType AS CorVATActivityTypes,
	|	UNDEFINED AS CorLineOfBusiness,
	|	DD.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS ExpenseItemOfWriteOff,
	|	UNDEFINED AS DimensionOfExpenses,
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	TRUE AS ThisIsExactlyCalculatedMovement
	|FROM
	|	TTDistributionResult AS DD
	|	INNER JOIN TTCostCalculationRecorders AS TTCostCalculationRecorders
	|		ON TTCostCalculationRecorders.Organization = DD.Organization
	|
	|	LEFT JOIN TTValueOfBatchesOfGoods AS Prices
	|		ON Prices.Organization = DD.Organization
	|		AND Prices.Lot = DD.CorLot
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributesCorr
	|		AND Prices.FinancialAccountingDimension = DD.CorControllingAttributes
	|		AND Prices.VATActivityType = DD.CorVATActivityTypes
	|		AND Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Prices.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = DD.BusinessOperation
	|WHERE
	|	(DD.Cost <> 0 OR DD.CostExcludingVAT <> 0 OR DD.LocalCost <> 0 OR DD.CostMan <> 0
	|		OR DD.CostOfPersonalIncomeTax <> 0)
	|
	|INDEX BY
	|	Recorder
	|;";
	#EndRegion
	
	#Region TTOfRegisteredRecordedDeviationsInCost
	QueryText = QueryText + "
	// The formation of Registered Records according to the register "Deviations in the cost of items".
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&EndOfPeriod AS Period,
	|	TTCostCalculationRecorders.Ref AS Recorder,
	// Dimensions
	|	DD.Organization AS Organization,
	|	DimensionOfProductItem.Products AS Products,
	|	DimensionOfProductItem.Characteristic AS Characteristic,
	|	DD.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
	|			THEN DimensionOfProductItem.Purpose.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		WHEN DimensionOfProductItem.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN DimensionOfProductItem.StorageLocation
	|		WHEN DimensionOfProductItem.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN CAST(DimensionOfProductItem.StorageLocation AS Catalog.Warehouses).Department
	|		WHEN DimensionOfProductItem.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN CAST(DimensionOfProductItem.StorageLocation AS Catalog.CounterpartyContracts).Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE
	|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
	|			THEN DimensionOfProductItem.StorageLocation
	|		ELSE UNDEFINED
	|	END AS StorageLocation,
	|	BEGINOFPERIOD(Register3.IBDocumentDate, MONTH) AS VariancePeriod,
	// Resources
	|	DD.Cost AS CostVariancesIncludingVAT,
	|	DD.CostExcludingVAT AS CostVariancesExcludingVAT,
	|	DD.LocalCost AS CostVariancesLocal,
	|	DD.CostMan AS CostVariancesMgmt,
	|	0 AS AdditionalExpensesIncludingVAT,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|	DD.PermanentDifference AS PermanentDifference,
	|	DD.CostTD AS CostTD,
	|	DD.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
	// Attributes
	|	DD.BusinessOperation AS BusinessOperation,
	|	DD.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DD.FinRecordID AS FinRecordID,
	|	DD.EntryType AS EntryType,
	|	FALSE AS ReversingEntry,
	|	UNDEFINED AS DistributionPeriod,
	|	&MonthEndClosingMode AS MonthEndClosingMode
	|
	|INTO TTOfRegisteredRecordedDeviationsInCost
	|FROM
	|	TTOfRegisteredRecordsOfInvoiceOfDeliveries AS DD
	|
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|	ON DimensionOfProductItem.Ref = DD.CorItemsLocationAttributes
	|
	|	INNER JOIN TTCostCalculationRecorders AS TTCostCalculationRecorders
	|		ON TTCostCalculationRecorders.Organization = DD.Organization
	|
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|	ON Register3.Ref = DD.Lot
	|		AND NOT Register3.AdditionalRecord
	|
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	
	|WHERE
	|	DD.EntryType = VALUE(Enum.LotRecordTypes.CostVariance)
	|	AND (DD.Cost <> 0 OR DD.CostExcludingVAT <> 0 OR DD.LocalCost <> 0 OR DD.CostMan <> 0
	|		OR DD.PermanentDifference <> 0 OR DD.CostTD <> 0 OR DD.CostOfPersonalIncomeTax <> 0)
	|;";
	#EndRegion
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region StageProcedures_FillingInLotsInRegisterCostOfGoods

#Region Description_FillingOfLotsInRegisterCostOfGoods

// The stage performs the selection of batches for documents of movement of goods, as well as documents of adjustment.
// The rules for the compilation of chains of selection of batches "Source" - "Receiver" are described in the function of the description of the list of party goods().
//
// At the stage of filling in the Party register of the cost of goods, batch measurements are filled in the register "Cost of goods".
// Party dimensions: Party, analyticsaccounts of parties, analyticsfinancial accounting, Activity types
// The stage is performed with any method of cost estimation.
// When using the "Monthly Average" estimation method, the measurements of the Financial accounting analyst and the activity of the index are filled in at the stage.
//
// Features of the selection of batch measurements for individual business operations:
// Return of goods to the supplier
//	The document "Purchase of goods and services" may be indicated in the return of goods to the supplier. If the
//	purchase document is specified, the batch must be written off in accordance with the specified purchase document.
//	If the specified batch is no longer in the Balances, then negative Balances for the specified batch should be formed, which
//	will then be written off by the "re-sorting of party goods" stage.
//
//	To return the goods to the supplier, the batch must be selected first, regardless of the date of return to the supplier.
//	To do this, fill in the Period of receipt for the selection of batches with the date of the receipt document specified in the return to the supplier.
//	The selection of movements of returns to the supplier is performed in the function of the text of the current turnover of the goods parties().
//	Verification of the compliance of the selected batch with the specified document for the purchase of goods is performed in the function to fill in the estimated value of the goods().
//	To return the goods to the supplier, either a batch corresponding to the purchase of goods specified in the return to the supplier,
//	or an empty batch, if the purchase of goods was executed using the "Average for a month."
//	
// Selection of sources for certain types of records:
// - Adjustment of acquisitions of the previous period - for this type of records, cumulative adjustments for acquisitions of the previous period are reflected.
//	For this type of records, it is necessary to select a batch analysis of the cost of goods (Batch, analytical accounting of parties, 
//	The type of activity of the index, the analysis of financial accounting), which reflects the acquisition in the last period, because when carrying
//	out the adjustment document, in the general case, it is impossible to accurately determine the batch analytics.
//	The source is the values of the "Document source" field in movements with the record types "Readjustment of the acquisition of the previous period".
//	Sources must have a record type of "Past". 
//	The table for the selection of movements is generated in the textdocumentapplication function() and saved to the temporary document access table.
//	The selection of movements for sources is formed in the functions of the initial textstatecorrectioncorrection() and
//	The text of the initial settings for correcting and acquiring the water settings().

#EndRegion

// Data Initialization

Function ConsumptionFieldsOfBatchOfGoods(CalculationParameters)
	
	Return "ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection";
	
EndFunction

Function DescriptionOfChainsOfBatchesOfGoods(CalculationParameters) Export
	
	// Important: features of the use of recording types in movements formed by this particular stage.
	// If at this stage a record is generated with the record type used in the Template of the Cost register,
	// (See CalculationOfCostCached.ThisIsOnlyCalculatedRecordType)
	// then it is considered that this is the "primary" record in which the batch identification fields are simply filled in.
	//	- the "Calculation of parties" attribute for such a record is set to False.
	// If a record is generated with any other type of record, then it is considered to be a "calculated" record.
	//	- the "Calculation of parties" attribute for such a record is set to True.
	// You can also "forcibly" set the calculation of parties to the value True - using the request field, this is the current settlement movement.
	
	DescriptionOfChains = New Map;
	ConsumptionFields	= ConsumptionFieldsOfBatchOfGoods(CalculationParameters);
	
	// Consumption <- (Balance, Batch, Moving, Moving Apart, Moving Alone, Remaining Grouped, Return, Consumption, 
	// REPOSITIONUPR, correction of the past period, return of another warehouse).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.Consumption, 		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.Balance,				ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.Lot,				ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.Move, 		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.GroupedStock, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.ReturnReverseTransaction,		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.ConsumptionReverseTransaction,	ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.TransferAuto, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.TransferMan,      ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.PreviousPeriodCorrections, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.ReturnToAnotherWarehouse, ConsumptionFields);
	
	// wayway consumption <- (wayway movement, movement, Balance).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionGoodsInTransit, 
		"ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection, Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.ConsumptionGoodsInTransit,
		Enums.LotRecordTypes.TransferGoodsInTransit, 
		"ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection, Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.ConsumptionGoodsInTransit,
		Enums.LotRecordTypes.Move, 
		"ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection, Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.ConsumptionGoodsInTransit,
		Enums.LotRecordTypes.Balance, 
		"ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection, Recorder");
		
	// The movement of goods halfway <- (Consumption of goods halfway, Consumption, Reverse consumption).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferGoodsInTransit,
		"Recorder, AccountingSection, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.TransferGoodsInTransit,
		Enums.LotRecordTypes.ConsumptionGoodsInTransit,
		"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.TransferGoodsInTransit,
		Enums.LotRecordTypes.Consumption,
		"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, 
		Enums.LotRecordTypes.TransferGoodsInTransit,
		Enums.LotRecordTypes.ConsumptionReverseTransaction,
		"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	
	// ConsumptionAuto <- (Remainder, Batch, Moving, Moving separately, remaining grouped, Reversal, reversal of consumption, correction of the last period).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionLotCalculation, 		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.Balance,				ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.Lot,				ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.Move, 		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.GroupedStock, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.ReturnReverseTransaction,		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.ConsumptionReverseTransaction,	ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.PreviousPeriodCorrections, ConsumptionFields);
		
	// Ostatox Grouped <- (Reverse, return past periods, return from the source document)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.GroupedStock,	ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.ReversingEntry,					ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.PreviousPeriodReturn,	ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.GroupedStock,
		Enums.LotRecordTypes.ReturnWithoutSourceDocument, ConsumptionFields);
		
	// Write-off of other Parties <- (Balance, Party, Relocation, Moving separately, remaining grouped, Refund cancellation, Consumption cancellation, REPOSITIONUPR, Correction of past period, Write-down of other parties)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ExpensesToOtherProductionLots, 		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.Balance,				ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.Lot,				ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.Move, 		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.GroupedStock, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.ReturnReverseTransaction,		ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.ConsumptionReverseTransaction,	ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.TransferMan,      ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.PreviousPeriodCorrections, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpensesToOtherProductionLots,
		Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots, ConsumptionFields);
		
	// Write-offs of other parties <- (Write-offs of other parties)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots,
		Enums.LotRecordTypes.ExpensesToOtherProductionLots, ConsumptionFields + ", Recorder");
		
	// Acquisition adjustment <- (Balance, Batch, Remaining grouped, correction of the past period)	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.PurchaseAdjustment, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.Balance, 				 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.Lot, 				 	 ConsumptionFields);	
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.GroupedStock, 	 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PurchaseAdjustment,
		Enums.LotRecordTypes.PreviousPeriodCorrections, 	 ConsumptionFields);
		
	// Correction of the displacement of the past period <- (Balance, Batch, remaining grouped, correction of the past period)	
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.CorrectPreviousPeriodTransfer, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CorrectPreviousPeriodTransfer,
		Enums.LotRecordTypes.Balance, 				 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CorrectPreviousPeriodTransfer,
		Enums.LotRecordTypes.Lot, 				 	 ConsumptionFields);	
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CorrectPreviousPeriodTransfer,
		Enums.LotRecordTypes.GroupedStock, 	 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CorrectPreviousPeriodTransfer,
		Enums.LotRecordTypes.PreviousPeriodCorrections, 	 ConsumptionFields);
		
	// Additional expenses of the Party <- (Past, Import, stornodoprasdov)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.AddExpensesLotIsNotSpecified,	ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.AddExpensesLotIsNotSpecified,
		Enums.LotRecordTypes.Previous, 			ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.AddExpensesLotIsNotSpecified,
		Enums.LotRecordTypes.Import, 				ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.AddExpensesLotIsNotSpecified,
		Enums.LotRecordTypes.AdditionalExpensesReverseTransaction, 	ConsumptionFields);
	
	// Additional expenditures by the Party <- (Past, Import, Reverse Expenditures, Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.AddExpensesLotIsSpecified,	ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.AddExpensesLotIsSpecified,
		Enums.LotRecordTypes.Previous, 			ConsumptionFields + ", Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.AddExpensesLotIsSpecified,
		Enums.LotRecordTypes.Import, 		ConsumptionFields + ", Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.AddExpensesLotIsSpecified,
		Enums.LotRecordTypes.AdditionalExpensesReverseTransaction, 	ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.AddExpensesLotIsSpecified,
		Enums.LotRecordTypes.Consumption, 		ConsumptionFields + ", Recorder");
	
	// Inclusion of the cost <- (Additional expenses by the party, additional expenses by the party)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.IncludeVATInCostExpenses, ConsumptionFields + ", DocumentSource, Recorder, RowID");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.IncludeVATInCostExpenses,
		Enums.LotRecordTypes.AddExpensesLotIsSpecified,     ConsumptionFields + ", DocumentSource, Recorder, RowID");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.IncludeVATInCostExpenses,
		Enums.LotRecordTypes.AddExpensesLotIsNotSpecified,    ConsumptionFields + ", DocumentSource, Recorder, RowID");
	
	// Inclusion of the Excise duty <- (Additional expenses by the party, additional expenses by the Party, cancellation of expenses, cost adjustment, cost adjustment of the acquisition of the previous period)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.IncludeExciseInCost, ConsumptionFields + ", DocumentSource, RowID");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.IncludeExciseInCost,
		Enums.LotRecordTypes.AddExpensesLotIsSpecified, ConsumptionFields + ", DocumentSource, RowID");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.IncludeExciseInCost,
		Enums.LotRecordTypes.AddExpensesLotIsNotSpecified, ConsumptionFields + ", DocumentSource, RowID");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.IncludeExciseInCost,
		Enums.LotRecordTypes.AdditionalExpensesReverseTransaction, 	ConsumptionFields + ", DocumentSource, RowID");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.IncludeExciseInCost,
		Enums.LotRecordTypes.CostAdjustment, ConsumptionFields + ", DocumentSource, RowID");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.IncludeExciseInCost,
		Enums.LotRecordTypes.DebitNoteForPreviousPeriod, ConsumptionFields + ", DocumentSource, RowID");
	
	// Adjusting the acquisition of the past period <- (Past, past expenditures)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.DebitNoteForPreviousPeriod, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.DebitNoteForPreviousPeriod,
		Enums.LotRecordTypes.Previous, ConsumptionFields + ", Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.DebitNoteForPreviousPeriod,
		Enums.LotRecordTypes.AdditionalExpensesReverseTransaction, 	ConsumptionFields + ", DocumentSource");
		
	// Cost adjustment <- (Past, past expenses)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.CostAdjustment, ConsumptionFields + ", DocumentSource");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAdjustment,
		Enums.LotRecordTypes.Previous, ConsumptionFields + ", Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAdjustment,
		Enums.LotRecordTypes.AdditionalExpensesReverseTransaction, 	ConsumptionFields + ", DocumentSource");
	
	// Realisation Adjustment <- (Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.SaleAdjustment, ConsumptionFields + ", Recorder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.SaleAdjustment,
		Enums.LotRecordTypes.Consumption, ConsumptionFields + ", Recorder");
	
	// Reverse <- (Consumption, Consumption, correction of the current period, adjustment of the implementation)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReversingEntry, 				"DocumentSource, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReversingEntry,
		Enums.LotRecordTypes.Consumption, 		"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReversingEntry,
		Enums.LotRecordTypes.ConsumptionLotCalculation, 		"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReversingEntry,
		Enums.LotRecordTypes.CurrentPeriodCorrections, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReversingEntry,
		Enums.LotRecordTypes.SaleAdjustment, "DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	// Reverse Consumption <- (Consumption, Past)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionReverseTransaction, 	"DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionReverseTransaction,
		Enums.LotRecordTypes.Consumption, 		"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionReverseTransaction,
		Enums.LotRecordTypes.Previous,				"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	// Return <- (Reverse, Reverse consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnReverseTransaction,	"DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnReverseTransaction,
		Enums.LotRecordTypes.ReversingEntry, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnReverseTransaction,
		Enums.LotRecordTypes.ConsumptionReverseTransaction, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	// Return of another Deposit <- (Return of another deposit)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction,	"DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction,
		Enums.LotRecordTypes.ReturnToAnotherWarehouse, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	// Return of the Source document <- (Consumption, Past)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnWithoutSourceDocument, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnWithoutSourceDocument,
		Enums.LotRecordTypes.Consumption, 				 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnWithoutSourceDocument,
		Enums.LotRecordTypes.Previous, 					 ConsumptionFields);
		
	// write-offs of the party's statistics <- (consumption, Balance, write-offs of the party's statistics, correction of the past period)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.Consumption, 				 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.Balance, 					 ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.PreviousPeriodCorrections,	 ConsumptionFields);
		
	// Write-offsostat of the Non-Party <- (Write-offsostat of the Non-party)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot, 	"DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot,
		Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute");
		
	// Return of another Deposit <- (Return of another deposit, Consumption, ConsumptionAuto)
	// When returning to another warehouse, you do not need to connect to the accounting section, because the return warehouse may have an accounting section
	// that is different from the shipping warehouse accounting section. 
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReturnToAnotherWarehouse, "DocumentSource, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouse,
		Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouse,
		Enums.LotRecordTypes.Consumption, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReturnToAnotherWarehouse,
		Enums.LotRecordTypes.ConsumptionLotCalculation, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	
	// Movement <- (Consumption, consumptionproduction, ConsumptionAuto, Return of another warehouse, reverse consumption, return of past periods).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.Move, 			"Recorder, AccountingSection, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.Consumption, 			"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ConsumptionProduction, "Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ConsumptionLotCalculation, 		"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ReturnToAnotherWarehouse, 	"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.ConsumptionReverseTransaction, 	"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Move,
		Enums.LotRecordTypes.PreviousPeriodReturn, 	"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
		
	// Moving apart <- (Consumption, consumptionproduction, consumptionauthor, return to another warehouse).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, 	"Recorder, AccountingSection, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferOnAssignmentBasis,
		Enums.LotRecordTypes.Consumption, 			"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, CorCompany");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferOnAssignmentBasis,
		Enums.LotRecordTypes.ConsumptionProduction, "Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, CorCompany");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferOnAssignmentBasis,
		Enums.LotRecordTypes.ConsumptionLotCalculation, 		"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, CorCompany");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferOnAssignmentBasis,
		Enums.LotRecordTypes.ReturnToAnotherWarehouse, 	"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute, CorCompany");
		
	// Moving Auto <- (Consumption, Consumptionproduction, ConsumptionAuto, Distribution).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferAuto, 		"Recorder, AccountingSection, ItemsLocationAttributes, InventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.Consumption, 			"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.ConsumptionProduction, "Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.ConsumptionLotCalculation, 		"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferAuto,
		Enums.LotRecordTypes.Allocation, 			"Recorder, CorAccountingSection, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
		
	// Movementupr <- (Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferMan, 	"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferMan,
		Enums.LotRecordTypes.Consumption, 	"Recorder, CorItemsLocationAttributes, CorInventoryOwnerAttribute, CorCompany");
		
	// Displacement of the state <- (Consumption)
	// The type of record of the movementthe state has no receivers, it forms the Balance at the end of the month.
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.TransferToBalance, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.TransferToBalance,
		Enums.LotRecordTypes.Consumption, "Recorder, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	
	// Distribution <- (Moving, Moving separately, Balance, Batch, Moving separately, Remaining grouped)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.Allocation, 		"ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.Move, 		"ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.Balance,				"ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.Lot,				"ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, "ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Allocation,
		Enums.LotRecordTypes.GroupedStock, "ItemsLocationAttributes, Organization");
		
	// Write-off Issue <- (Move, Move apart, Move Auto, Batch, Remainder, Remaining inventory, Reverse Write-off Issue).
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.CostAllocationToProductionLots, 	"ItemsLocationAttributes, Organization, ProductionOrder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.Move, 		"ItemsLocationAttributes, Organization, ProductionOrder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.TransferAuto, 	"ItemsLocationAttributes, Organization, ProductionOrder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.Lot,				"ItemsLocationAttributes, Organization, ProductionOrder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.WIPStock,			"ItemsLocationAttributes, Organization, ProductionOrder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.Balance,				"ItemsLocationAttributes, Organization, ProductionOrder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, "ItemsLocationAttributes, Organization, ProductionOrder");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CostAllocationToProductionLots,
		Enums.LotRecordTypes.ReverseOfCostAllocationToProductionLots, "ItemsLocationAttributes, Organization, ProductionOrder");
		
	// Issue <- (Write-off Issue)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ProductionIssue, 				"Recorder, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ProductionIssue,
		Enums.LotRecordTypes.CostAllocationToProductionLots, 	"Recorder, CorItemsLocationAttributes, CorInventoryOwnerAttribute");
		
	// Consumptionproduction <- (Batch, Moving, Moving separately, Remainder)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionProduction, "ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.Lot, 				"ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.Move, 		"ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.Balance,				"ItemsLocationAttributes, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionProduction,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, "ItemsLocationAttributes, Organization");
		
	// Write-offs Expenses <- (Batch, Remainder)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ExpenseAs,	"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpenseAs,
		Enums.LotRecordTypes.Lot, 				"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ExpenseAs,
		Enums.LotRecordTypes.Balance,				"Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
		
	// Return past periods <- (Past, Consumption)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.PreviousPeriodReturn, "SalesOrder, CorItemsLocationAttributes, CorInventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PreviousPeriodReturn,
		Enums.LotRecordTypes.Previous, 				"SalesOrder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.PreviousPeriodReturn,
		Enums.LotRecordTypes.Consumption, 			"SalesOrder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	
	// Reversal of past periods <- (Return of past periods)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ReverseOfPreviousPeriodsReturn, "DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ReverseOfPreviousPeriodsReturn,
		Enums.LotRecordTypes.PreviousPeriodReturn, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization");
	
	// Correction of the current period <- (Moving, moving apart)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.CurrentPeriodCorrections, "DocumentSource, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CurrentPeriodCorrections,
		Enums.LotRecordTypes.Move, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.CurrentPeriodCorrections,
		Enums.LotRecordTypes.TransferOnAssignmentBasis, "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection");
	
	// Addition <- (<without sources - for generating records based on request data>)
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.Supplement);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.AdditionPreviousPeriod);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.AdditionLotsCalculation);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.InclusionExclusionOfVATInCost);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.CostVariance);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.CostVarianceForOtherIncome);
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.GoodsCostVarianceForOtherExpenses);
	
	Return DescriptionOfChains;
	
EndFunction

Function DescriptionOfRegisteredRecordsOfBatchesOfGoods(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfBatchesOfGoods(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "FillingOfLotsInRegisterCostOfGoods");
	RegisterRecordsDetails.Insert("RegisterName", Metadata.AccumulationRegisters.InventoryCost.Name);
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	ConsumptionFieldsOfBatchOfGoods(CalculationParameters));
	RegisterRecordsDetails.Insert("Indicators", "Denominator, Count, Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
		|LocalCost, PermanentDifference, CostTD, CostOfPersonalIncomeTax,
		|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
		|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
		|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
		|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal,
		|ItemizedFixedCostsCompl, ItemizedVariableCostsCompl");
	RegisterRecordsDetails.Insert("BasisOfArrival", "Count");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Count");
	RegisterRecordsDetails.Insert("ExpenseKey", "DocumentSource");
	RegisterRecordsDetails.Insert("OrderField_", "ReceiptPeriod");
	RegisterRecordsDetails.Insert("SortFields", "VATActivityType, FinancialAccountingDimension, Lot,
		|PrioritySource, PriorityBusinessOperation, CCDNumber");
	RegisterRecordsDetails.Insert("SortingByCondition", True);
	
	RegisterRecordsDetails.Insert("ThereIsStorno", True);
	RegisterRecordsDetails.Insert("ThereAreFixes", True);
	RegisterRecordsDetails.Insert("ThereIsBusinessOperation", True);
	RegisterRecordsDetails.Insert("ThereIsCalculationOfBatches", True);
	RegisterRecordsDetails.Insert("ThereIsAccountingSection", True);
	
	RegisterRecordsDetails.Insert("TemporaryTablesForFollowingSteps", "CalculatedDocuments, ThereAreDeclarations, ThereAreImportNotifications");
	
	Return RegisterRecordsDetails;
	
EndFunction

Function DescriptionOfUnrecordedBatchesOfGoods(CalculationParameters)
	
	UnrecordedRecordTypes = New Map;
	For Each CurItem In CalculationParameters.UnreadableRecordTypes Do
		UnrecordedRecordTypes.Insert(CurItem, True);
	EndDo;
	
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Import, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Previous, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.CostAllocationToProductionLots, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.ReverseOfCostAllocationToProductionLots, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.GroupedStock, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.SaleAdjustment, True);
	
	UnwrittenPartitions = New Map;
	UnwrittenPartitions.Insert(Enums.SectionsOfInventoryCostAccounting.EmptyRef(), True);
	
	Return CostCalculationAppliedAlgorithms.DescriptionOfNonWritableData(True, UnrecordedRecordTypes, UnwrittenPartitions);
	
EndFunction

Function TableForDistributionOfBatchesOfGoods(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfDataForBatchesOfGoods());
	
EndFunction

// Sample data

Procedure GetDataForBatchesOfGoods(CalculationParameters)
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("InvoicingOfDeliveries", False);
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"ItemsLocationAttributes", // Separator
		"Denominator, Count,
			|Cost, CostExcludingVAT, OffBalanceCost, AddExpensesForGoods, AdditionalExpensesExcludingVAT, LaborCosts,
			|ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
			|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
			|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
			|LocalCost, OffBalanceCostLocal, PermanentDifference, CostTD, CostOfPersonalIncomeTax,
			|AddExpensesLocal, LaborCostsLocal, ItemizedFixedCostsCompl, ItemizedVariableCostsCompl", // Resources
		"Products DESC, Priority ASC, Period, Organization, InventoryOwnerAttribute,
			|Lot, LotVendorAttributes, Recorder, CorLot, LotVendorAttributesCorr, RecordType DESC"); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForBatchesOfGoods(CalculationParameters),
		NumberingParameters);
	
	AdjustBatchAccountingStatisticsForBatchesOfGoods(CalculationParameters);
	
EndProcedure

Procedure AdjustBatchAccountingStatisticsForBatchesOfGoods(CalculationParameters)
	
	QueryText = 
	"SELECT DISTINCT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.LotVendorAttributes AS LotVendorAttributes
	|FROM
	|	Data AS T
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN T.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN T.ItemsLocationAttributes
	|		ELSE T.CorItemsLocationAttributes
	|	END,
	|	T.LotVendorAttributesCorr
	|FROM
	|	Data AS T";
	
	CostCalculationAppliedAlgorithms.AdjustBatchAccountingCriteriaForCalculation(CalculationParameters, QueryText);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForBatchesOfGoods(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// preparation of temporary tables
		+ TextInitializationOfBatchesOfGoods() // TUE Declarations, declarations of access
		+ Common.QueryBatchSeparator() + TextPastImplementations() // tue Past realizations
		+ Common.QueryBatchSeparator() + TextIsDeclaration() // in the remainder of the import, there are declarations
		
		+ Common.QueryBatchSeparator() + TextOfCorrectionOfPastReportsToGiver() // TT Past Reportproduction
		
		+ Common.QueryBatchSeparator() + TextDocumentsOfReceipt() // in the Access document
		+ Common.QueryBatchSeparator() + TextReturnsWithoutSourceDocument() // tue return of the document source
		+ Common.QueryBatchSeparator() + TextCorrectedDocuments() // tue Corrected documents
		+ Common.QueryBatchSeparator() + TextCalculatedDocuments() // tue Calculated documents
		+ Common.QueryBatchSeparator() + TextDocumentRegistryTable() // TT with data from the document registry
		+ Common.QueryBatchSeparator() + TextOfPurchaseOfGoodsOnOrders() // tue purchases of goods by order
		
		+ Common.QueryBatchSeparator() + ThereIsInvoiceForTraceableWorks() // TT is a factualization
		+ Common.QueryBatchSeparator() + TextTTGoodsToTransfer()
		+ Common.QueryBatchSeparator() + TextEstimatedBalanceOfBatchesOfGoods() // TT estimated cost of party goods
		+ Common.QueryBatchSeparator() + TextOfReverseImplementations()
		+ Common.QueryBatchSeparator()
		// Sample data
		+ TextDescriptionOfDataForBatchesOfGoods() // w Data
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialBalancesOfBatchesOfGoods()
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialBalancesReportsToGiver()
		+ TMCommonUse.QuerySeparatorInJoin() + TextFinalBalancesOfBatchesOfGoods()
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialResiduesOfUnfinishedProduction()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurArrivalsOfLotsOfGoods()
		+ TMCommonUse.QuerySeparatorInJoin() + TextRemainderGrouped()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfCorrectionImplementation()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurTurnoverOfLotsOfGoods()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurImplementationsOfLocalOnly()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurTurnsOfProductionCosts()
		+ TMCommonUse.QuerySeparatorInJoin() + TextStornoOfRegisteredRecordedDistributionOfMaterialsMediumSlip()
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialBalancesOfImportPurchases()
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialBalancesForAcquisitionAdjustment()
		+ TMCommonUse.QuerySeparatorInJoin() + TextInitialBalancesForPurchaseAdjustmentsEnteringBalances()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurImportPurchases()
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurExpensesWithoutBatchForDistribution() // Uses Declarations
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurExpensesWithPartyToDistribution() // Uses Declarations
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurrentAdditionalExpensesAmountWithBatchOfImportApplication()
		+ TMCommonUse.QuerySeparatorInJoin() + PurchaseAdjustmentText()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfImplementationOfPastMonths() // uses past implementations
		+ TMCommonUse.QuerySeparatorInJoin() + TextReportsOfCommissionAgentsOfPreviousMonths() // uses the return of the source document  
		+ TMCommonUse.QuerySeparatorInJoin() + TextCurProductReleases()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfCorrectedDocumentsOfCurPeriod() // uses corrected documents
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfReverseMovementOfCorrectedDocumentsOfPastPeriod() // uses corrected documents
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfMovementWithSelectedParties()
		+ TMCommonUse.QuerySeparatorInJoin() + TextAdjustmentOfCostOfInventoryRecordedAtDisposalOfFA()
		+ TMCommonUse.QuerySeparatorInJoin() + TextGoodsToTransferExpense()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfGoodsToTransferParish()
		+ TMCommonUse.QuerySeparatorInJoin() + TextTTInvoiceOfDeliveries()
		+ CalculationOfCostLocalization.RequestTextForBatchesOfGoods()
		+ "";
	
	Return QueryText;
	
EndFunction

// ... data descriptions

Function TextDescriptionOfDataForBatchesOfGoods() Export
	
	QueryText = 
		"SELECT TOP 0 // 76 FIELDS
		|	CAST("""" AS STRING(80)) 					AS RequestSource,
		|	T.EntryType										AS EntryType,
		|	FALSE											AS ThisIsExactlyCalculatedMovement,
		|	FALSE											AS ThisIsReverseTransaction,
		|	0 												AS Priority,
		|	0 												AS Denominator,
		|	FALSE 											AS CalculationIsCompleted,
		|	VALUE(Catalog.Products.EmptyRef)  AS Products,
		|	T.LotVendorAttributes.VATTaxation 		AS TaxationOfParty,
		|	T.Period										AS Period,
		|	T.Period										AS ReceiptPeriod,
		|	T.VariancePeriod								AS VariancePeriod,
		|	T.Recorder									AS Recorder,
		|	T.RecordType 									AS RecordType,
		|
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.Lot AS ProductionOrder,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|
		|	T.Count,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.OffBalanceCost,
		|	T.CostMan,
		|	T.AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan,
		|	T.ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost,
		|	T.OffBalanceCostLocal,
		|	T.PermanentDifference,
		|	T.CostTD,
		|	T.CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal,
		|	T.LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	T.BusinessOperation AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	T.DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource,
		|	T.DocumentSource AS PrioritySource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	T.LotCalculationPerformed,
		|	T.MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|INTO Data
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextInitializationOfBatchesOfGoods() // Declarations, declarations of access
	Return "
		|SELECT
		|	DD.Ref,
		|	(CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN Rows.ItemsLocationAttributes
		|		ELSE AnalyticsWithoutAssignment.DimensionKey
		|	END) AS ItemsLocationAttributes,
		|	ISNULL(SectionLines.VATRate, Rows.VATRate) AS VATRate,
		|	Rows.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Rows.PurchaseForActivity AS VATActivityType,
		|	Rows.RowID AS RowID,
		|	Rows.DocumentInflow AS DocumentInflow,
		|	Rows.Count AS Count
		|INTO Declarations
		|FROM
		|	Document.CCDImport AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Document.CCDImport.Goods AS Rows
		|		ON Rows.Ref = DD.Ref
		|	LEFT JOIN Document.CCDImport.Sections AS SectionLines
		|		ON SectionLines.Ref = DD.Ref
		|		AND SectionLines.SectionNumber = Rows.SectionNumber
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = Rows.ItemsLocationAttributes
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
		|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
		|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
		|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
		|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
		|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
		|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
		|WHERE
		|	DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN (&CompanyArray)
		|	AND DD.Posted
		|;
		|SELECT
		|	DD.Ref,
		|	(CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN Rows.ItemsLocationAttributes
		|		ELSE AnalyticsWithoutAssignment.DimensionKey
		|	END) AS ItemsLocationAttributes,
		|	Rows.DocumentInflow,
		|	Rows.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Rows.RowID AS RowID,
		|	Rows.Count AS Count
		|INTO IncomeDeclarations
		|FROM
		|	Document.CCDImport AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Document.CCDImport.Goods AS Rows
		|		ON Rows.Ref = DD.Ref
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = Rows.ItemsLocationAttributes
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
		|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
		|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
		|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
		|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
		|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
		|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
		|WHERE
		|	DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN (&CompanyArray)
		|	AND DD.Posted
		|	AND Rows.DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef)
		|";
EndFunction

Function TextPastImplementations() // tue Past realizations
	Return "
		|SELECT DISTINCT
		|	DD.DocumentSource AS DocumentSalesOfGoodsAndServices,
		|	DD.DocumentSource AS DocumentSource,
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod)
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DD.CorItemsLocationAttributes END) AS ItemsLocationAttributes,
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod)
		|			THEN DD.InventoryOwnerAttribute
		|		ELSE DD.CorInventoryOwnerAttribute END) AS InventoryOwnerAttribute,
		|	ISNULL(DD.CorInventoryOwnerAttribute.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) AS CorInventoryType,
		|	DD.SalesOrder AS SalesOrder
		|
		|INTO PastImplementations
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	DD.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|	AND DD.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods)
		|	AND DD.Count > 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	SaleAdjustment.Ref AS DocumentSalesOfGoodsAndServices,
		|	SaleAdjustment.DocumentBasis AS DocumentSource,
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod)
		|			THEN DD.ItemsLocationAttributes
		|		ELSE DD.CorItemsLocationAttributes END) AS ItemsLocationAttributes,
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod)
		|			THEN DD.InventoryOwnerAttribute
		|		ELSE DD.CorInventoryOwnerAttribute END) AS InventoryOwnerAttribute,
		|	ISNULL(DD.CorInventoryOwnerAttribute.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) AS CorInventoryType,
		|	DD.SalesOrder AS SalesOrder
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Document.SaleAdjustment AS SaleAdjustment
		|		ON SaleAdjustment.DocumentBasis = DD.DocumentSource
		|		AND NOT SaleAdjustment.Ref = DD.Recorder
		|		AND SaleAdjustment.Date < &BeginOfPeriod
		|WHERE
		|	DD.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|	AND DD.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods)
		|	AND DD.Count > 0
		|";
EndFunction

Function TextIsDeclaration() // in the remainder of the import, there are declarations
	Return "
		|SELECT DISTINCT
		|	Balance.Lot AS Lot,
		|	BEGINOFPERIOD(Import.Date, MONTH) AS Date
		|INTO LeftoversImport
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,
		|		Organization IN (&CompanyArray)
		|	) AS Balance
		|	INNER JOIN Document.VendorInvoice AS Import
		|		ON Import.Ref = Balance.Lot
		|		AND Import.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.PurchaseByImport),
		|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Balance.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|INDEX BY
		|	Lot
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DD.Lot AS Lot,
		|	MAX(DD.Date) AS Date
		|INTO ThereAreDeclarations
		|FROM
		|	(SELECT
		|		Lots.DocumentSource AS Lot,
		|		MAX(Declarations.Date) AS Date
		|	FROM
		|		Document.CCDImport AS Declarations
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Declarations.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		INNER JOIN AccumulationRegister.InventoryCost AS Lots
		|			ON Lots.Recorder = Declarations.Ref
		|	WHERE
		|		Declarations.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND Declarations.Posted
		|		AND Lots.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
		|	GROUP BY
		|		Lots.DocumentSource
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Balance.Lot AS Lot,
		|		MAX(Declarations.Date) AS Date
		|	FROM
		|		LeftoversImport AS Balance
		|		INNER JOIN AccumulationRegister.InventoryCost AS Lots
		|			ON Lots.Lot = Balance.Lot
		|			AND Lots.Period BETWEEN Balance.Date AND &BeginOfPeriod
		|		INNER JOIN Document.CCDImport AS Declarations
		|			ON Lots.Recorder = Declarations.Ref
		|	WHERE
		|		Lots.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
		|	GROUP BY
		|		Balance.Lot
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Lots.DocumentInflow AS Lot,
		|		MAX(Declarations.Date) AS Date
		|	FROM
		|		Document.CCDImport AS Declarations
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Declarations.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		INNER JOIN Document.CCDImport.Goods AS Lots
		|			ON Lots.Ref = Declarations.Ref
		|		LEFT JOIN AccumulationRegister.InventoryCost AS InventoryCost
		|			ON Lots.Ref = InventoryCost.Recorder
		|			AND Lots.DocumentInflow = InventoryCost.Lot
		|			AND InventoryCost.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
		|	WHERE
		|		Declarations.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND InventoryCost.Recorder IS NULL
		|		AND NOT Lots.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
		|		AND Declarations.Posted
		|	GROUP BY
		|		Lots.DocumentInflow
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Balance.Lot AS Lot,
		|		MAX(Declarations.Date) AS Date
		|	FROM
		|		LeftoversImport AS Balance
		|		INNER JOIN Document.CCDImport.Goods AS Lots
		|			ON Lots.DocumentInflow = Balance.Lot
		|		INNER JOIN Document.CCDImport AS Declarations
		|			ON Lots.Ref = Declarations.Ref
		|			AND Declarations.Date BETWEEN Balance.Date AND &BeginOfPeriod
		|		LEFT JOIN AccumulationRegister.InventoryCost AS InventoryCost
		|			ON Lots.Ref = InventoryCost.Recorder
		|			AND Lots.DocumentInflow = InventoryCost.Lot
		|			AND InventoryCost.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
		|	WHERE
		|		InventoryCost.Recorder IS NULL
		|		AND NOT Lots.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
		|		AND Declarations.Posted
		|	GROUP BY
		|		Balance.Lot
		|	) AS DD
		|GROUP BY
		|	DD.Lot
		|
		|INDEX BY
		|	Lot
		|";
EndFunction

Function TextOfCorrectionOfPastReportsToGiver() // TT Past Reportproduction
	Return 
		"SELECT
		|	AdjustingEntries.Ref AS Adjusting,
		|	ReportsToGiver.Ref AS ReportToMaterialProvider
		|INTO PastReports
		|FROM
		|	Document.SaleAdjustment AS AdjustingEntries
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON AdjustingEntries.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Document.ReportToMaterialProvider2_5 AS ReportsToGiver
		|		ON AdjustingEntries.DocumentBasis = ReportsToGiver.Ref
		|WHERE
		|	AdjustingEntries.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND AdjustingEntries.Posted
		|	AND ReportsToGiver.Date < &BeginOfPeriod
		|
		|INDEX BY
		|	ReportToMaterialProvider
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReportsToGiver.Adjusting AS Adjusting,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	SUM(T.Count) AS Count,
		|	SUM(T.OffBalanceCost) AS OffBalanceCost,
		|	SUM(T.OffBalanceCostLocal) AS OffBalanceCostLocal
		|INTO PastReportsProducts
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|		INNER JOIN PastReports AS ReportsToGiver
		|		ON T.Recorder = ReportsToGiver.ReportToMaterialProvider
		|WHERE
		|	T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|	AND T.Active
		|
		|GROUP BY
		|	ReportsToGiver.Adjusting,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute
		|HAVING 
		|	SUM(T.Count) <> 0
		|
		|INDEX BY
		|	Adjusting
		|";
	
EndFunction



Function TextDocumentsOfReceipt() // in the Access document
	Return "
		|SELECT DISTINCT
		|	DD.DocumentSource AS Ref
		|INTO InitialReceiptDocuments
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	DD.EntryType IN (
		|		 VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|		 VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|		 VALUE(Enum.LotRecordTypes.CostAdjustment))
		|	AND NOT DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|	AND DD.DocumentSource <> UNDEFINED
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AdjustingEntries.Ref AS Ref
		|INTO InitialPurchaseAdjustments
		|FROM
		|	Document.PurchaseAdjustment AS AdjustingEntries
		|		INNER JOIN InitialReceiptDocuments AS Inflow
		|		ON AdjustingEntries.DocumentBasis = Inflow.Ref
		|WHERE
		|	AdjustingEntries.Date <= &EndOfPeriod
		|	AND AdjustingEntries.Posted
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// The Access Document table should contain both the original documents for the purchase of goods and all their adjustments
		// In this case, the initial data will be selected in the text for the Acquisition correction() for the case
		// when the acquisition correction does not correct the original document itself, but its previous correction
		|SELECT
		|	DD.Ref AS Ref
		|INTO ReceiptDocuments
		|FROM
		|	InitialReceiptDocuments AS DD
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Cost_.Recorder AS Ref
		|FROM
		|	AccumulationRegister.InventoryCost AS Cost_
		|		INNER JOIN InitialPurchaseAdjustments AS AdjustingEntries
		|		ON Cost_.Recorder = AdjustingEntries.Ref
		|WHERE
		|	Cost_.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND Cost_.Count > 0
		|";
EndFunction

Function TextReturnsWithoutSourceDocument() // tue return of the document source
	Return "
		|SELECT
		|	DD.Organization AS Organization,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.AccountingSection AS AccountingSection
		|	
		|INTO ReturnsWithoutSourceDocument
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	DD.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|GROUP BY
		|	DD.Organization,
		|	DD.ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute,
		|	DD.AccountingSection
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	AccountingSection
		|";

EndFunction

Function TextCorrectedDocuments() Export // tue Corrected documents
	Return "
		|SELECT DISTINCT
		|	Register3.CorrectedDocument    AS CorrectedDocument,
		|	Register3.ReversedDocument    AS ReversedDocument,
		|	RegistrySource.IBDocumentDate AS DateOfDocumentBeingCancelled,
		|	Register3.IBDocumentDate         AS Period,
		|	Register3.Ref                  AS Recorder
		|INTO CorrectedDocuments_
		|FROM
		|	InformationRegister.DocumentsRegistry AS Register3
		|	
		|	INNER JOIN InformationRegister.DocumentsRegistry AS RegistrySource
		|	ON RegistrySource.Ref = Register3.ReversedDocument
		|	AND NOT RegistrySource.AdditionalRecord
		|	
		|	LEFT JOIN Document.BackflushProduction AS AttributesBP
		|	ON AttributesBP.Ref = Register3.Ref
		|
		|	LEFT JOIN Document.BackflushProduction AS AttributesOfCanceledPbZ
		|	ON AttributesOfCanceledPbZ.Ref = Register3.ReversedDocument
		|
		|WHERE
		|	Register3.IBDocumentDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Register3.Organization IN (&CompanyArray)
		|	AND Register3.ReverseTransactionCorrection
		|	AND Register3.Posted
		|	AND NOT Register3.AdditionalRecord
		|
		|INDEX BY
		|	ReversedDocument
		|";
EndFunction

Function TextCalculatedDocuments() // tue Calculated documents
	Return "	
		|SELECT DISTINCT
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder
		|INTO CalculatedDocuments
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	NOT &RestoreChronologicalSequenceOfDebitingBatches
		|	AND DD.LotCalculationPerformed
		|	AND NOT DD.ReversingEntry
		|
		|INDEX BY
		|	Period,
		|	Recorder
		|";
EndFunction

Function TextDocumentRegistryTable() // TT with data from the document registry
	Return "	
		|SELECT
		|	Register3.Ref AS Ref,
		|	MAX(Register3.IBDocumentDate) AS IBDocumentDate,
		|	MAX(Register3.BusinessOperation) AS BusinessOperation,
		|	MAX(T.AccountingSection) AS AccountingSection
		|INTO RegisterOfDocumentsRemainingBatches
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,	Organization IN (&CompanyArray)) AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
		|	ON Register3.Ref = T.Lot
		|		AND (NOT Register3.AdditionalRecord OR Register3.RefType IN (&DocumentsWithTwoOrganizations))
		|		AND T.Lot <> UNDEFINED
		|WHERE
		|	&RestoreChronologicalSequenceOfDebitingBatches
		|GROUP BY
		|	Register3.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	Register3.Ref AS Ref,
		|	MAX(Register3.IBDocumentDate) AS IBDocumentDate,
		|	MAX(Register3.BusinessOperation) AS BusinessOperation,
		|	MAX(T.AccountingSection) AS AccountingSection
		|FROM
		|	TTCashSettlementBalancesCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
		|	ON Register3.Ref = T.Lot
		|		AND (NOT Register3.AdditionalRecord OR Register3.RefType IN (&DocumentsWithTwoOrganizations))
		|		AND T.Lot <> UNDEFINED
		|WHERE
		|	NOT &RestoreChronologicalSequenceOfDebitingBatches
		|GROUP BY
		|	Register3.Ref
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Register3.Ref AS Ref,
		|	MAX(Register3.IBDocumentDate) AS IBDocumentDate,
		|	MAX(Register3.BusinessOperation) AS BusinessOperation,
		|	MAX(T.AccountingSection) AS AccountingSection
		|INTO RegisterOfDocumentsBalanceOfBatchesOfPastImplementations
		|FROM AccumulationRegister.InventoryCost AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN PastImplementations AS Past
		|		ON T.Recorder = Past.DocumentSalesOfGoodsAndServices
		|		AND T.ItemsLocationAttributes = Past.ItemsLocationAttributes
		|		AND (T.InventoryOwnerAttribute = Past.InventoryOwnerAttribute
		|			OR T.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef))
		|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
		|	ON Register3.Ref = T.Lot
		|		AND (NOT Register3.AdditionalRecord OR Register3.RefType IN (&DocumentsWithTwoOrganizations))
		|		AND T.Lot <> UNDEFINED
		|WHERE
		|	T.Organization IN (&CompanyArray)
		|	AND T.Period < &BeginOfPeriod
		|	AND T.Active
		|	AND NOT T.CalculationOfCost
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND T.Period < &DateOfMigrationToBatchAccounting22)
		|	AND NOT T.ReversingEntry
		|
		|GROUP BY
		|	Register3.Ref
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Register3.Ref AS Ref,
		|	MAX(Register3.IBDocumentDate) AS IBDocumentDate,
		|	MAX(Register3.BusinessOperation) AS BusinessOperation,
		|	MAX(T.AccountingSection) AS AccountingSection
		|INTO RegisterOfDocumentsOfBatchOfPurchaseAdjustments
		|FROM TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON T.Recorder = Adjusting.Ref
		|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
		|	ON Register3.Ref = Adjusting.DocumentBasis
		|
		|GROUP BY
		|	Register3.Ref
		|
		|INDEX BY
		|	Ref
		|";
EndFunction

Function TextOfPurchaseOfGoodsOnOrders() // tue purchases of goods by order
	Return "
		|SELECT
		|	Balance.Lot AS Lot,
		|	Balance.LotVendorAttributes AS LotVendorAttributes,
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Balance.AccountingSection AS AccountingSection,
		|	MAX(ISNULL(PurchaseOfGoodsTypesOfStocks.PurchaseOrder,
		|		Purchases.OrderDocument)) AS PurchaseOrder
		|	
		|INTO PurchasesOfGoodsOnOrders
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,
		|		Organization IN (&CompanyArray)
		|		AND AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|	) AS Balance
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Balance.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN AccumulationRegister.Purchases AS Purchases
		|		ON Purchases.Recorder = Balance.Lot
		|		AND Purchases.Period < &BeginOfPeriod
		|		AND Purchases.ItemsLocationAttributes = Balance.ItemsLocationAttributes
		|		AND Purchases.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
		|	LEFT JOIN Document.VendorInvoice.InventoryKinds AS PurchaseOfGoodsTypesOfStocks
		|		ON PurchaseOfGoodsTypesOfStocks.Ref = Balance.Lot
		|		AND PurchaseOfGoodsTypesOfStocks.LineNumber = Balance.LotVendorAttributes.RowCode
		|		AND PurchaseOfGoodsTypesOfStocks.ItemsLocationAttributes = Balance.ItemsLocationAttributes
		|		AND PurchaseOfGoodsTypesOfStocks.InventoryOwnerAttribute = Balance.InventoryOwnerAttribute
		|GROUP BY
		|	Balance.Lot,
		|	Balance.LotVendorAttributes,
		|	Balance.ItemsLocationAttributes,
		|	Balance.InventoryOwnerAttribute,
		|	Balance.AccountingSection
		|
		|INDEX BY
		|	Lot,
		|	LotVendorAttributes,
		|	ItemsLocationAttributes,
		|	InventoryOwnerAttribute,
		|	AccountingSection
		|";
EndFunction


Function ThereIsInvoiceForTraceableWorks() // TT is a factualization
	Return "
	|SELECT DISTINCT
	|	Balance.Lot AS Lot,
	|	Balance.ItemsLocationAttributes.Products AS Products,
	|	BEGINOFPERIOD(ReceiptOfServices.Date, MONTH) AS Date
	|
	|INTO BalancesOfUnfacturedWork
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,
	|		Organization IN (&CompanyArray)
	|		AND ISNULL(ItemsLocationAttributes.Products.TracedGoods, FALSE)
	|		AND Lot REFS Document.ReceiptOfServicesToBusinessUnit
	|	) AS Balance
	|	INNER JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
	|		ON ReceiptOfServices.Ref = Balance.Lot
	|INDEX BY
	|	Lot
	|;
	|////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Invoices_1.Lot AS Lot,
	|	Invoices_1.Period AS Date,
	|	Invoices_1.Products AS Products
	|
	|INTO ThereAre_Invoices
	|FROM
	|	TTInvoicingOfDeliveries AS Invoices_1
	|WHERE
	|	Invoices_1.Products.TracedGoods
	|	AND Invoices_1.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
	|	AND Invoices_1.Count > 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Invoices_1.Lot AS Lot,
	|	Invoices_1.Period AS Date, 
	|	Balance.Products AS Products
	|FROM
	|	BalancesOfUnfacturedWork AS Balance
	|	INNER JOIN AccumulationRegister.InventoryCost AS Invoices_1
	|		ON Invoices_1.Period BETWEEN Balance.Date AND &EndOfPreviousPeriod
	|		AND Invoices_1.Lot = Balance.Lot
	|		AND Invoices_1.ItemsLocationAttributes.Products = Balance.Products
	|		AND Invoices_1.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND Invoices_1.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
	|		AND Invoices_1.Count > 0
	|
	|INDEX BY
	|	Lot,
	|	Products
	|";		 
EndFunction

Function TextEstimatedBalanceOfBatchesOfGoods() // TT estimated cost of party goods
	Return "
		|SELECT
		|	T.ItemsLocationAttributes			AS ItemsLocationAttributes,
		|	T.AccountingSection							AS AccountingSection,
		|	T.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
		|	T.Organization							AS Organization,
		|	T.Lot								AS Lot,
		|	T.LotVendorAttributes					AS LotVendorAttributes,
		|	T.FinancialAccountingDimension				AS FinancialAccountingDimension,
		|	T.VATActivityType					AS VATActivityType,
		|
		|	SUM(T.Count) 					AS Count,
		|	SUM(T.Cost) 						AS Cost,
		|	SUM(T.CostExcludingVAT) 				AS CostExcludingVAT,
		|	SUM(T.OffBalanceCost)			AS OffBalanceCost,
		|	SUM(T.CostMan)					AS CostMan,
		|	SUM(T.AddExpensesMan)					AS AddExpensesMan,
		|	SUM(T.ItemizedVariableCostsIncludingVAT)		AS ItemizedVariableCostsIncludingVAT,
		|	SUM(T.ItemizedVariableCostsExcludingVAT)	AS ItemizedVariableCostsExcludingVAT,
		|	SUM(T.LaborCostsMan)				AS LaborCostsMan,
		|	SUM(T.ItemizedFixedCostsManag)		AS ItemizedFixedCostsManag,
		|	SUM(T.ItemizedVariableCostsManag)		AS ItemizedVariableCostsManag,
		|	SUM(T.AddExpensesForGoods)						AS AddExpensesForGoods,
		|	SUM(T.AdditionalExpensesExcludingVAT)				AS AdditionalExpensesExcludingVAT,
		|	SUM(T.LaborCosts)					AS LaborCosts,
		|	SUM(T.ItemizedFixedCostsIncludingVAT)		AS ItemizedFixedCostsIncludingVAT,
		|	SUM(T.ItemizedFixedCostsExcludingVAT)	AS ItemizedFixedCostsExcludingVAT,
		|	SUM(T.LocalCost)					AS LocalCost,
		|	SUM(T.OffBalanceCostLocal)		AS OffBalanceCostLocal,
		|	SUM(T.PermanentDifference)				AS PermanentDifference,
		|	SUM(T.CostTD)				AS CostTD,
		|	SUM(T.CostOfPersonalIncomeTax)					AS CostOfPersonalIncomeTax,
		|	SUM(T.AddExpensesLocal)					AS AddExpensesLocal,
		|	SUM(T.LaborCostsLocal)				AS LaborCostsLocal,
		|	SUM(T.ItemizedFixedCostsCompl)		AS ItemizedFixedCostsCompl,
		|	SUM(T.ItemizedVariableCostsCompl)		AS ItemizedVariableCostsCompl,
		|	SUM(T.ProvisionForImpairmentLocal)		AS ProvisionForImpairmentLocal,
		|	SUM(T.ProvisionForImpairmentMan)		AS ProvisionForImpairmentMan
		|
		|INTO EstimatedBalanceOfBatchesOfGoods
		|FROM (
		|	SELECT
		|		T.ItemsLocationAttributes,
		|		T.AccountingSection,
		|		T.InventoryOwnerAttribute,
		|		T.Organization,
		|		T.Lot,
		|		T.LotVendorAttributes,
		|		T.FinancialAccountingDimension,
		|		T.VATActivityType,
		|
		|		T.CountBalance						AS Count,
		|		T.CostBalance						AS Cost,
		|		T.CostExcludingVATBalance				AS CostExcludingVAT,
		|		T.OffBalanceCostBalance			AS OffBalanceCost,
		|		T.CostManBalance					AS CostMan,
		|		T.AddExpensesManBalance					AS AddExpensesMan,
		|		T.ItemizedVariableCostsIncludingVATBalance 		AS ItemizedVariableCostsIncludingVAT,
		|		T.ItemizedVariableCostsExcludingVATBalance	AS ItemizedVariableCostsExcludingVAT,
		|		T.LaborCostsManBalance				AS LaborCostsMan,
		|		T.ItemizedFixedCostsManagBalance		AS ItemizedFixedCostsManag,
		|		T.ItemizedVariableCostsManagBalance		AS ItemizedVariableCostsManag,
		|		T.AddExpensesForGoodsBalance						AS AddExpensesForGoods,
		|		T.AdditionalExpensesExcludingVATBalance				AS AdditionalExpensesExcludingVAT,
		|		T.LaborCostsBalance					AS LaborCosts,
		|		T.ItemizedFixedCostsIncludingVATBalance		AS ItemizedFixedCostsIncludingVAT,
		|		T.ItemizedFixedCostsExcludingVATBalance	AS ItemizedFixedCostsExcludingVAT,
		|		T.LocalCostBalance					AS LocalCost,
		|		T.OffBalanceCostLocalBalance		AS OffBalanceCostLocal,
		|		T.PermanentDifferenceBalance				AS PermanentDifference,
		|		T.CostTDBalance				AS CostTD,
		|		T.AddExpensesLocalBalance					AS AddExpensesLocal,
		|		T.CostOfPersonalIncomeTaxBalance					AS CostOfPersonalIncomeTax,
		|		T.LaborCostsLocalBalance				AS LaborCostsLocal,
		|		T.ItemizedFixedCostsComplBalance		AS ItemizedFixedCostsCompl,
		|		T.ItemizedVariableCostsComplBalance		AS ItemizedVariableCostsCompl,
		|		T.ProvisionForImpairmentLocalBalance		AS ProvisionForImpairmentLocal,
		|		T.ProvisionForImpairmentManBalance		AS ProvisionForImpairmentMan
		|	FROM
		|		AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,
		|			Organization IN (&CompanyArray)
		|			AND NOT AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|		) AS T
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	WHERE
		|		NOT &RestoreChronologicalSequenceOfDebitingBatches
		|
		|	UNION ALL
		|
		|	SELECT
		|		T.ItemsLocationAttributes,
		|		T.AccountingSection,
		|		T.InventoryOwnerAttribute,
		|		T.Organization,
		|		T.Lot,
		|		T.LotVendorAttributes,
		|		T.FinancialAccountingDimension,
		|		T.VATActivityType,
		|
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.Count AS Count,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.Cost AS Cost,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.CostExcludingVAT AS CostExcludingVAT,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.OffBalanceCost AS OffBalanceCost,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.CostMan AS CostMan,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.AddExpensesMan AS AddExpensesMan,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedVariableCostsIncludingVAT AS ItemizedVariableCostsIncludingVAT,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.LaborCostsMan AS LaborCostsMan,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedFixedCostsManag AS ItemizedFixedCostsManag,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedVariableCostsManag AS ItemizedVariableCostsManag,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.AddExpensesForGoods AS AddExpensesForGoods,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.LaborCosts AS LaborCosts,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedFixedCostsIncludingVAT AS ItemizedFixedCostsIncludingVAT,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.LocalCost AS LocalCost,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.OffBalanceCostLocal AS OffBalanceCostLocal,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.PermanentDifference AS PermanentDifference,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.CostTD AS CostTD,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.AddExpensesLocal AS AddExpensesLocal,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.LaborCostsLocal AS LaborCostsLocal,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
		|		CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1
		|			ELSE -1 END * T.ProvisionForImpairmentMan AS ProvisionForImpairmentMan
		|	FROM
		|		AccumulationRegister.InventoryCost AS T
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	WHERE
		|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND T.Organization IN (&CompanyArray)
		|		AND T.Active
		|		AND NOT &RestoreChronologicalSequenceOfDebitingBatches
		|		AND NOT T.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|		AND (CASE
		|			WHEN T.EntryType IN (&UnreadableRecordTypes)
		|			 OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			 OR T.LotCalculationPerformed
		|				THEN TRUE
		|			ELSE FALSE END)
		|	) AS T
		|
		|GROUP BY
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|";
EndFunction

Function TextOfReverseImplementations()
	Return "
		|SELECT DISTINCT
		|	T.DocumentSource AS SaleOfGoodsAndServices
		|INTO TTReverseImplementations
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	VALUETYPE(T.Recorder) = TYPE(Document.SaleAdjustment)
		|	AND VALUETYPE(T.DocumentSource) = TYPE(Document.CustomerInvoice)
		|	AND T.EntryType = VALUE(Enum.LotRecordTypes.ReversingEntry)
		|INDEX BY
		|	SaleOfGoodsAndServices
		|";
	
EndFunction

// ... data samples

Function TextInitialBalancesOfBatchesOfGoods() // Uses there are declarations, there are import notifications, there are facts
	Return 
		"SELECT
		|	""TextInitialBalancesOfBatchesOfGoods"" 			 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.CountBalance < 0 THEN TRUE
		|		ELSE FALSE END)							 AS ThisIsReverseTransaction,
		|	0 												 AS Priority,
		|	0 												 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products 		 AS Products,
		|	T.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	(CASE
		// For imported goods, the Period field is always determined based on the date of customs declaration.
		// When receiving goods in transit from suppliers, the value of the Period of receipt field is filled in from the Period field
		// so that the selection of batches in the warehouse is performed taking into account the date of the customs declaration.
		|		WHEN NOT ThereAreDeclarations.Date IS NULL THEN ThereAreDeclarations.Date
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		// For batch balances, the period is determined by the batch date.
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		// When accounting for FIFO, balances without lots should be written off first.
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		// When accounting for the average, balances without batches should be written off after balances with batches.
		|		ELSE &EndOfPreviousPeriod END)        AS Period,
		// The Access Period field is filled in the same way as the Period field.
		// For own goods in transit from suppliers, the date of customs declaration is not taken into account, since the receipt of goods in the outi is
		// processed without taking into account the presence of a customs declaration.
		|	(CASE
		|		WHEN NOT ThereAreDeclarations.Date IS NULL
		|		 AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			THEN ThereAreDeclarations.Date
		|		WHEN NOT ThereAre_Invoices.Date IS NULL THEN ThereAre_Invoices.Date
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		|		ELSE &EndOfPreviousPeriod END)        AS ReceiptPeriod,
		|	DATETIME(1,1,1)								 AS VariancePeriod,
		|	T.Lot										 AS Recorder,
		|	UNDEFINED 			 	 					 AS RecordType,
		|	T.ItemsLocationAttributes 					 AS ItemsLocationAttributes,
		|	T.AccountingSection				 					 AS AccountingSection,
		|	T.InventoryOwnerAttribute				 					 AS InventoryOwnerAttribute,
		|	T.Organization				 					 AS Organization,
		|	T.Lot					 					 AS Lot,
		|	UNDEFINED									 AS ProductionOrder,
		|	T.LotVendorAttributes		 					 AS LotVendorAttributes,
		|	T.FinancialAccountingDimension  					 AS FinancialAccountingDimension,
		|	T.VATActivityType		 					 AS VATActivityType,
		|
		|	T.CountBalance 							 AS Count,
		|	T.CostBalance 								 AS Cost,
		|	T.CostExcludingVATBalance 						 AS CostExcludingVAT,
		|	T.OffBalanceCostBalance 					 AS OffBalanceCost,
		|	T.CostManBalance 							 AS CostMan,
		|	T.AddExpensesManBalance 							 AS AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVATBalance 				 AS ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVATBalance 			 AS ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsManBalance 						 AS LaborCostsMan,
		|	T.ItemizedFixedCostsManagBalance 				 AS ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManagBalance 				 AS ItemizedVariableCostsManag,
		|	T.AddExpensesForGoodsBalance 						 	 AS AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVATBalance 				 		 AS AdditionalExpensesExcludingVAT,
		|	T.LaborCostsBalance 							 AS LaborCosts,
		|	T.ItemizedFixedCostsIncludingVATBalance 				 AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVATBalance 			 AS ItemizedFixedCostsExcludingVAT,
		|	T.LocalCostBalance 							 AS LocalCost,
		|	T.OffBalanceCostLocalBalance 				 AS OffBalanceCostLocal,
		|	T.PermanentDifferenceBalance 						 AS PermanentDifference,
		|	T.CostTDBalance 						 AS CostTD,
		|	T.CostOfPersonalIncomeTaxBalance 							 AS CostOfPersonalIncomeTax,
		|	T.AddExpensesLocalBalance 						 AS AddExpensesLocal,
		|	T.LaborCostsLocalBalance 						 AS LaborCostsLocal,
		|	T.ItemizedFixedCostsComplBalance 				 AS ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsComplBalance 			     AS ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocalBalance 			     AS ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentManBalance 			     AS ProvisionForImpairmentMan,
		|
		|	ISNULL(Register3.BusinessOperation,
		|		VALUE(Enum.BusinessTransactions.EmptyRef)) AS BusinessOperation,
		|	(CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|		ELSE UNDEFINED END) AS PriorityBusinessOperation,
		|	UNDEFINED															AS CorItemsLocationAttributes,
		|	UNDEFINED															AS CorAccountingSection,
		|	UNDEFINED															AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	UNDEFINED															AS CorLot,
		|	UNDEFINED															AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	(CASE
		|		WHEN T.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		ELSE ISNULL(PurchasesOfGoodsOnOrders.PurchaseOrder, UNDEFINED) END) AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,
		|		Organization IN (&CompanyArray)
		|		AND AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	) AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN Document.VendorInvoice AS Import
		|		ON Import.Ref = T.Lot
		|		AND Import.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.PurchaseByImport),
		|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	LEFT JOIN ThereAreDeclarations AS ThereAreDeclarations
		|		ON ThereAreDeclarations.Lot = T.Lot
		|	LEFT JOIN Document.SourceDocument AS SourceDocument
		|		ON SourceDocument.Ref = T.Lot
		|	LEFT JOIN RegisterOfDocumentsRemainingBatches AS Register3
		|		ON Register3.Ref = T.Lot
		|	LEFT JOIN PurchasesOfGoodsOnOrders AS PurchasesOfGoodsOnOrders
		|		ON PurchasesOfGoodsOnOrders.Lot = T.Lot
		|		AND PurchasesOfGoodsOnOrders.LotVendorAttributes = T.LotVendorAttributes
		|		AND PurchasesOfGoodsOnOrders.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND PurchasesOfGoodsOnOrders.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND PurchasesOfGoodsOnOrders.AccountingSection = T.AccountingSection
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = T.Lot
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = T.Lot
		|	LEFT JOIN ThereAre_Invoices AS ThereAre_Invoices
		|		ON ThereAre_Invoices.Lot = T.Lot
		|		AND ThereAre_Invoices.Products = Dimension.Products
		|WHERE
		|	NOT (NOT T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		AND NOT Import.Ref IS NULL AND ThereAreDeclarations.Lot IS NULL
		|		AND T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5))
		|
		// The Lot reference of the tracked work is available for distribution only if there is an invoice, because in the items of organizations
		// such work will be reflected only when the delivery is invoiced.
		|	AND NOT (NOT ReceiptOfServices.Ref IS NULL
		|		 AND ISNULL(Dimension.Products.TracedGoods, FALSE)
		|		 AND ThereAre_Invoices.Products IS NULL)
		|	AND NOT (T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		OR FALSE)
		|	AND &RestoreChronologicalSequenceOfDebitingBatches
		|";
EndFunction

Function TextInitialBalancesReportsToGiver()
	// If the goods were transferred to the giver in the last period, then there will be no Balance of the goods.
	// In this case, in the quality of the Balance, we use the movements of the report itself to the giver.
	Return 
		"SELECT
		|	""TextInitialBalancesReportsToGiver""		 	  AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	FALSE 							 				 AS ThisIsReverseTransaction,
		|	90 												 AS Priority,
		|	0 												 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products 		 AS Products,
		|	T.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	&BeginOfPeriod         				 			 AS Period,
		|	&BeginOfPeriod        							 AS ReceiptPeriod,
		|	DATETIME(1,1,1)								 AS VariancePeriod,
		|	T.Lot										 AS Recorder,
		|	UNDEFINED 			 	 					 AS RecordType,
		|	T.ItemsLocationAttributes 					 AS ItemsLocationAttributes,
		|	T.AccountingSection				 					 AS AccountingSection,
		|	T.InventoryOwnerAttribute				 					 AS InventoryOwnerAttribute,
		|	T.Organization				 					 AS Organization,
		|	T.Lot					 					 AS Lot,
		|	UNDEFINED									 AS ProductionOrder,
		|	T.LotVendorAttributes		 					 AS LotVendorAttributes,
		|	T.FinancialAccountingDimension  					 AS FinancialAccountingDimension,
		|	T.VATActivityType		 					 AS VATActivityType,
		|
		|	T.Count 							 		 AS Count,
		|	T.Cost 								 	 AS Cost,
		|	T.CostExcludingVAT		 						 AS CostExcludingVAT,
		|	T.OffBalanceCost		 					 AS OffBalanceCost,
		|	T.CostMan		 							 AS CostMan,
		|	T.AddExpensesMan		 							 AS AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT		 				 AS ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT		 			 AS ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan		 						 AS LaborCostsMan,
		|	T.ItemizedFixedCostsManag		 				 AS ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag		 				 AS ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods		 						 	 AS AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT		 				 		 AS AdditionalExpensesExcludingVAT,
		|	T.LaborCosts		 							 AS LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT		 				 AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT		 			 AS ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost		 							 AS LocalCost,
		|	T.OffBalanceCostLocal		 				 AS OffBalanceCostLocal,
		|	T.PermanentDifference		 						 AS PermanentDifference,
		|	T.CostTD		 						 AS CostTD,
		|	T.CostOfPersonalIncomeTax		 							 AS CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal		 						 AS AddExpensesLocal,
		|	T.LaborCostsLocal		 						 AS LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl		 				 AS ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl		 			     AS ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal		 			     AS ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan		 			     AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.EmptyRef) 				AS BusinessOperation,
		|	UNDEFINED 															AS PriorityBusinessOperation,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)		AS CorItemsLocationAttributes,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) 	AS CorAccountingSection,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)							AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	UNDEFINED															AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)				AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	UNDEFINED 															AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	T.Period < &BeginOfPeriod
		|	AND T.Organization IN (&CompanyArray)
		|	AND T.Recorder IN (SELECT ReportsToGiver.ReportToMaterialProvider FROM PastReports AS ReportsToGiver)
		|	AND T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|	AND T.Active
		|	AND &RestoreChronologicalSequenceOfDebitingBatches
		|";
EndFunction

Function TextFinalBalancesOfBatchesOfGoods() // Uses there are declarations, there are import notifications, there are facts
	Return 
		"SELECT
		|	""TextFinalBalancesOfBatchesOfGoods"" 			 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)							 AS ThisIsReverseTransaction,
		|	0 												 AS Priority,
		|	0 												 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products 		 AS Products,
		|	T.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	(CASE
		|		WHEN NOT ThereAreDeclarations.Date IS NULL THEN ThereAreDeclarations.Date
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		// For batch balances, the period is determined by the batch date.
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		// When accounting for FIFO, balances without lots should be written off first.
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		// When accounting for the average, balances without batches should be written off after balances with batches.
		|		ELSE &EndOfPreviousPeriod END)        AS Period,
		// The Access Period field is filled in the same way as the Period field.
		|	(CASE
		|		WHEN NOT ThereAreDeclarations.Date IS NULL
		|		 AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			THEN ThereAreDeclarations.Date
		|		WHEN NOT ThereAre_Invoices.Date IS NULL THEN ThereAre_Invoices.Date
		|		WHEN NOT SourceDocument.Date IS NULL THEN SourceDocument.Date
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		|		ELSE &EndOfPreviousPeriod END)        AS ReceiptPeriod,
		|	DATETIME(1,1,1)								 AS VariancePeriod,
		|	T.Lot										 AS Recorder,
		|	UNDEFINED 			 	 					 AS RecordType,
		|	T.ItemsLocationAttributes 					 AS ItemsLocationAttributes,
		|	T.AccountingSection				 					 AS AccountingSection,
		|	T.InventoryOwnerAttribute				 					 AS InventoryOwnerAttribute,
		|	T.Organization				 					 AS Organization,
		|	T.Lot					 					 AS Lot,
		|	UNDEFINED									 AS ProductionOrder,
		|	T.LotVendorAttributes		 					 AS LotVendorAttributes,
		|	T.FinancialAccountingDimension  					 AS FinancialAccountingDimension,
		|	T.VATActivityType		 					 AS VATActivityType,
		|
		|	T.Count 									 AS Count,
		|	T.Cost 									 AS Cost,
		|	T.CostExcludingVAT 								 AS CostExcludingVAT,
		|	T.OffBalanceCost 						 AS OffBalanceCost,
		|	T.CostMan 									 AS CostMan,
		|	T.AddExpensesMan 								 AS AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT 					 AS ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT 					 AS ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan 								 AS LaborCostsMan,
		|	T.ItemizedFixedCostsManag 						 AS ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag 						 AS ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods 								 	 AS AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT 				 				 AS AdditionalExpensesExcludingVAT,
		|	T.LaborCosts 									 AS LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT 					 AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT 					 AS ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost 								 AS LocalCost,
		|	T.OffBalanceCostLocal 					 AS OffBalanceCostLocal,
		|	T.PermanentDifference 							 AS PermanentDifference,
		|	T.CostTD 								 AS CostTD,
		|	T.CostOfPersonalIncomeTax 									 AS CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal 								 AS AddExpensesLocal,
		|	T.LaborCostsLocal 								 AS LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl 					 AS ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl 				   	 AS ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal 					     AS ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan 					     AS ProvisionForImpairmentMan,
		|
		|	ISNULL(Register3.BusinessOperation,
		|		VALUE(Enum.BusinessTransactions.EmptyRef)) AS BusinessOperation,
		|	(CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND VALUETYPE(T.Lot) <> TYPE(Document.BackflushProduction)
		|		 AND VALUETYPE(T.Lot) <> TYPE(Document.ProductionStage2_2)
		|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND (VALUETYPE(T.Lot) = TYPE(Document.BackflushProduction)
		|		 	OR VALUETYPE(T.Lot) = TYPE(Document.ProductionStage2_2)
		|			)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		ELSE UNDEFINED END) AS PriorityBusinessOperation,
		|	UNDEFINED															AS CorItemsLocationAttributes,
		|	UNDEFINED															AS CorAccountingSection,
		|	UNDEFINED															AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	UNDEFINED															AS CorLot,
		|	UNDEFINED															AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	(CASE
		|		WHEN T.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		ELSE ISNULL(PurchasesOfGoodsOnOrders.PurchaseOrder, UNDEFINED) END) AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	EstimatedBalanceOfBatchesOfGoods AS T
		|	LEFT JOIN Document.VendorInvoice AS Import
		|		ON Import.Ref = T.Lot
		|		AND Import.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.PurchaseByImport),
		|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	LEFT JOIN ThereAreDeclarations AS ThereAreDeclarations
		|		ON ThereAreDeclarations.Lot = T.Lot
		|	LEFT JOIN Document.SourceDocument AS SourceDocument
		|		ON SourceDocument.Ref = T.Lot
		|	LEFT JOIN RegisterOfDocumentsRemainingBatches AS Register3
		|		ON Register3.Ref = T.Lot
		|	LEFT JOIN PurchasesOfGoodsOnOrders AS PurchasesOfGoodsOnOrders
		|		ON PurchasesOfGoodsOnOrders.Lot = T.Lot
		|		AND PurchasesOfGoodsOnOrders.LotVendorAttributes = T.LotVendorAttributes
		|		AND PurchasesOfGoodsOnOrders.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND PurchasesOfGoodsOnOrders.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND PurchasesOfGoodsOnOrders.AccountingSection = T.AccountingSection
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = T.Lot
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = T.Lot
		|	LEFT JOIN ThereAre_Invoices AS ThereAre_Invoices
		|		ON ThereAre_Invoices.Lot = T.Lot
		|		AND ThereAre_Invoices.Products = Dimension.Products
		|WHERE
		|	T.Count > 0
		|	AND NOT (NOT T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		AND NOT Import.Ref IS NULL AND ThereAreDeclarations.Lot IS NULL
		|		AND T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5))
		|
		// The Lot reference of the tracked work is available for distribution only if there is an invoice, because in the items of organizations
		// such work will be reflected only when the delivery is invoiced.
		|	AND NOT (NOT ReceiptOfServices.Ref IS NULL
		|		 AND ISNULL(Dimension.Products.TracedGoods, FALSE)
		|		 AND ThereAre_Invoices.Products IS NULL)
		|	AND NOT (T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		)
		|	AND NOT &RestoreChronologicalSequenceOfDebitingBatches
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|";
EndFunction

Function TextInitialResiduesOfUnfinishedProduction()
	Return 
		"SELECT
		|	""TextInitialResiduesOfUnfinishedProduction"" 			 		 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.WIPStock) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.CountBalance < 0 THEN TRUE
		|		ELSE FALSE END)							 AS ThisIsReverseTransaction,
		|	0 												 AS Priority,
		|	0 												 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products 		 AS Products,
		|	T.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	ISNULL(Register3.IBDocumentDate,
		|			&EndOfPreviousPeriod)				 AS Period,
		|	ISNULL(Register3.IBDocumentDate,
		|			&EndOfPreviousPeriod)				 AS ReceiptPeriod,
		|	DATETIME(1,1,1)								 AS VariancePeriod,
		|	UNDEFINED									 AS Recorder,
		|	UNDEFINED 			 	 					 AS RecordType,
		|	T.ItemsLocationAttributes 					 AS ItemsLocationAttributes,
		|	T.AccountingSection				 					 AS AccountingSection,
		|	T.InventoryOwnerAttribute				 					 AS InventoryOwnerAttribute,
		|	T.Organization				 					 AS Organization,
		|	T.Lot					 					 AS Lot,
		|	T.Lot 										 AS ProductionOrder,
		|	T.LotVendorAttributes		 					 AS LotVendorAttributes,
		|	T.FinancialAccountingDimension  					 AS FinancialAccountingDimension,
		|	T.VATActivityType		 					 AS VATActivityType,
		|
		|	T.CountBalance 							 AS Count,
		|	T.CostBalance 								 AS Cost,
		|	T.CostExcludingVATBalance 						 AS CostExcludingVAT,
		|	T.OffBalanceCostBalance 					 AS OffBalanceCost,
		|	T.CostManBalance 							 AS CostMan,
		|	T.AddExpensesManBalance 							 AS AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVATBalance 				 AS ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVATBalance 			 AS ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsManBalance 						 AS LaborCostsMan,
		|	T.ItemizedFixedCostsManagBalance 				 AS ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManagBalance 				 AS ItemizedVariableCostsManag,
		|	T.AddExpensesForGoodsBalance 						 	 AS AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVATBalance 				 		 AS AdditionalExpensesExcludingVAT,
		|	T.LaborCostsBalance 							 AS LaborCosts,
		|	T.ItemizedFixedCostsIncludingVATBalance 				 AS ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVATBalance 			 AS ItemizedFixedCostsExcludingVAT,
		|	T.LocalCostBalance 							 AS LocalCost,
		|	T.OffBalanceCostLocalBalance 				 AS OffBalanceCostLocal,
		|	T.PermanentDifferenceBalance 						 AS PermanentDifference,
		|	T.CostTDBalance 						 AS CostTD,
		|	T.CostOfPersonalIncomeTaxBalance 							 AS CostOfPersonalIncomeTax,
		|	T.AddExpensesLocalBalance 						 AS AddExpensesLocal,
		|	T.LaborCostsLocalBalance 						 AS LaborCostsLocal,
		|	T.ItemizedFixedCostsComplBalance 				 AS ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsComplBalance 			     AS ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocalBalance 			     AS ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentManBalance 			     AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.EmptyRef) 				AS BusinessOperation,
		|	UNDEFINED															AS PriorityBusinessOperation,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)		AS CorItemsLocationAttributes,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) 	AS CorAccountingSection,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)							AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	UNDEFINED 															AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) 			AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	UNDEFINED															AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,	Organization IN (&CompanyArray)) AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN RegisterOfDocumentsRemainingBatches AS Register3
		|		ON Register3.Ref = T.Lot
		|WHERE
		|	T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|";
EndFunction

Function TextCurArrivalsOfLotsOfGoods() // Uses there are declarations, returnable wastes, there are import notifications, there are facts
	Return 
		"SELECT
		|	""TextCurArrivalsOfLotsOfGoods"" 						AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Balance)			AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)										AS ThisIsReverseTransaction,
		|	(CASE
		|		WHEN T.OfficialTypeOfMovementParish THEN 10
		|		ELSE 90 END)											AS Priority,
		|	0 															AS Denominator,
		|	TRUE 														AS CalculationIsCompleted,
		|	Dimension.Products										AS Products,
		|	CASE WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|		THEN T.LotVendorAttributes.VATTaxation
		|		ELSE UNDEFINED
		|	END 														AS TaxationOfParty,
		|
		|	T.Period AS Period,
		|	CASE
		|		WHEN FALSE THEN T.Period // for easy tag placement

		// For the release of products by the production stage, the receipt period will be increased by 1 second,
		// so that the release to the sorting division will be later than the transfer of materials to the division.
		|		WHEN T.Recorder REFS Document.ProductionStage2_2
		|			THEN DATEADD(T.Period, SECOND, 1)
		|		WHEN NOT ThereAre_Invoices.Date IS NULL THEN ThereAre_Invoices.Date
		|		WHEN NOT Corrections.DateOfDocumentBeingCancelled IS NULL
		|			THEN Corrections.DateOfDocumentBeingCancelled
		|		WHEN T.Recorder REFS Document.PurchaseAdjustment AND T.Lot <> UNDEFINED
		|			THEN RegisterOfPurchaseAdjustments.IBDocumentDate
		|		ELSE ISNULL(ThereAreDeclarations.Date, T.Period)
		|	END AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	CASE
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR T.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN T.Lot
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	(CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND NOT BatchProductionStage.ReferenceOrder IS NULL
		|			THEN BatchProductionStage.ReferenceOrder
		|		ELSE UNDEFINED END) AS ProductionOrder,
		|	CASE
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR T.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|			THEN T.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END AS LotVendorAttributes,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.FinancialAccountingDimension REFS Catalog.AnalyticalInventoryGroups
		|		 AND NOT &AnalyticalAccountingByProductsGroups
		|			THEN UNDEFINED
		|		ELSE T.FinancialAccountingDimension
		|	END AS FinancialAccountingDimension,
		|	T.VATActivityType,
		|
		|	SUM(T.Count) AS Count,
		|	SUM(T.Cost) AS Cost,
		|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(T.OffBalanceCost) AS OffBalanceCost,
		|	SUM(T.CostMan) AS CostMan,
		|	SUM(T.AddExpensesMan) AS AddExpensesMan,
		|	SUM(T.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(T.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(T.LaborCostsMan) AS LaborCostsMan,
		|	SUM(T.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(T.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(T.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(T.LaborCosts) AS LaborCosts,
		|	SUM(T.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(T.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(T.LocalCost) AS LocalCost,
		|	SUM(T.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(T.PermanentDifference) AS PermanentDifference,
		|	SUM(T.CostTD) AS CostTD,
		|	SUM(T.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(T.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(T.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(T.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(T.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(T.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(T.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		ELSE UNDEFINED END) AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.CorLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE T.CorLot
		|	END AS CorLot,
		|	T.LotVendorAttributesCorr,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.CorControllingAttributes REFS Catalog.AnalyticalInventoryGroups
		|		 AND NOT &AnalyticalAccountingByProductsGroups
		|			THEN UNDEFINED
		|		WHEN NOT T.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		 AND (ISNULL(CorDimension.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Department)
		|				OR ISNULL(CorWarehouses.ShopFloorStockroom, FALSE))
		|		 AND &AnalyticalAccountingByProductsGroups
		|			THEN T.ProductsGroup
		|		ELSE T.CorControllingAttributes
		|	END AS CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	(CASE
		|		WHEN T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.DocumentVATActivityType
		|		ELSE T.VATActivityType END) AS DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	SUM(T.VATManag) AS VATManag,
		|	SUM(T.VATLocal) AS VATLocal,
		|	T.ProductCostElement,
		|	ISNULL(Adjusting.DocumentBasis, T.DocumentSource) AS DocumentSource,
		|	(CASE
		// For a correction document, the priority source is the correction document itself. 
		|		WHEN T.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		 AND NOT AcquisitionTypesOfInventory.PurchaseOrder IS NULL
		|		 AND AcquisitionTypesOfInventory.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN AcquisitionTypesOfInventory.PurchaseOrder
		|		ELSE ISNULL(CorrectedDocuments_.ReversedDocument, UNDEFINED) END) AS PrioritySource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	"""" AS FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
		|		ON CorDimension.Ref = T.CorItemsLocationAttributes
		|	LEFT JOIN Catalog.Warehouses AS CorWarehouses
		|		ON CorDimension.StorageLocation = CorWarehouses.Ref
		|	LEFT JOIN Document.VendorInvoice AS Import
		|		ON Import.Ref = T.Lot
		|		AND Import.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.PurchaseByImport),
		|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	LEFT JOIN ThereAreDeclarations AS ThereAreDeclarations
		|		ON ThereAreDeclarations.Lot = T.Recorder
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = T.Recorder
		|	LEFT JOIN Document.VendorInvoice.InventoryKinds AS AcquisitionTypesOfInventory
		|		ON AcquisitionTypesOfInventory.Ref = T.Recorder
		|		AND AcquisitionTypesOfInventory.RowID = T.RowID
		|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON Adjusting.Ref = T.Recorder
		|	LEFT JOIN RegisterOfDocumentsOfBatchOfPurchaseAdjustments AS RegisterOfPurchaseAdjustments
		|		ON RegisterOfPurchaseAdjustments.Ref = Adjusting.DocumentBasis
		|	LEFT JOIN Document.ProductionStage2_2 AS BatchProductionStage
		|		ON BatchProductionStage.Ref = T.Lot
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = T.Recorder
		|	LEFT JOIN CorrectedDocuments_ AS Corrections
		|		ON Corrections.Recorder = T.Recorder
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = T.Lot
		|	LEFT JOIN ThereAre_Invoices AS ThereAre_Invoices
		|		ON ThereAre_Invoices.Lot = T.Recorder
		|		AND ThereAre_Invoices.Products = Dimension.Products
		|WHERE
		|	T.Count <> 0
		|	AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|	AND NOT (NOT T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		AND NOT Import.Ref IS NULL AND ThereAreDeclarations.Lot IS NULL
		|		AND Dimension.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5))
		|
		// The Lot reference of the tracked work is available for distribution only if there is an invoice, because in the items of organizations
		// such work will be reflected only when the delivery is invoiced.
		|	AND NOT (NOT ReceiptOfServices.Ref IS NULL
		|		 AND ISNULL(Dimension.Products.TracedGoods, FALSE)
		|		 AND ThereAre_Invoices.Products IS NULL)
		|	AND NOT T.ReversingEntry
		|	AND &RestoreChronologicalSequenceOfDebitingBatches
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|
		|GROUP BY
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END), // ThisIsReverseTransaction
		|	(CASE
		|		WHEN T.OfficialTypeOfMovementParish THEN 10
		|		ELSE 90 END), //	Priority
		|	Dimension.Products,
		|	CASE WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|		THEN T.LotVendorAttributes.VATTaxation
		|		ELSE UNDEFINED
		|	END, // TaxationOfParty
		|
		|	T.Period,
		|	CASE
		|		WHEN FALSE THEN T.Period // for easy tag placement

		// For the release of products by the production stage, the receipt period will be increased by 1 second,
		// so that the release to the sorting division will be later than the transfer of materials to the division.
		|		WHEN T.Recorder REFS Document.ProductionStage2_2
		|			THEN DATEADD(T.Period, SECOND, 1)
		|		WHEN NOT ThereAre_Invoices.Date IS NULL THEN ThereAre_Invoices.Date
		|		WHEN NOT Corrections.DateOfDocumentBeingCancelled IS NULL
		|			THEN Corrections.DateOfDocumentBeingCancelled
		|		WHEN T.Recorder REFS Document.PurchaseAdjustment AND T.Lot <> UNDEFINED
		|			THEN RegisterOfPurchaseAdjustments.IBDocumentDate
		|		ELSE ISNULL(ThereAreDeclarations.Date, T.Period)
		|	END, // ReceiptPeriod
		|	T.VariancePeriod,
		|	T.Recorder,
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END, // RecordType
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	CASE
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR T.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN T.Lot
		|		ELSE UNDEFINED
		|	END, // Lot
		|	(CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND NOT BatchProductionStage.ReferenceOrder IS NULL
		|			THEN BatchProductionStage.ReferenceOrder
		|		ELSE UNDEFINED END), // ProductionOrder
		|	CASE
		|		WHEN T.Organization IN (&SFIFOOrganizationsSliding)
		|		 OR T.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|			THEN T.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END, // LotVendorAttributes
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.FinancialAccountingDimension REFS Catalog.AnalyticalInventoryGroups
		|		 AND NOT &AnalyticalAccountingByProductsGroups
		|			THEN UNDEFINED
		|		ELSE T.FinancialAccountingDimension
		|	END, // FinancialAccountingDimension
		|	T.VATActivityType,
		|
        |	T.BusinessOperation,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		ELSE UNDEFINED END), // PriorityBusinessOperation
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.CorLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE T.CorLot
		|	END, // CorLot
		|	T.LotVendorAttributesCorr,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN T.CorControllingAttributes REFS Catalog.AnalyticalInventoryGroups
		|		 AND NOT &AnalyticalAccountingByProductsGroups
		|			THEN UNDEFINED
		|		WHEN NOT T.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		 AND (ISNULL(CorDimension.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Department)
		|				OR ISNULL(CorWarehouses.ShopFloorStockroom, FALSE))
		|		 AND &AnalyticalAccountingByProductsGroups
		|			THEN T.ProductsGroup
		|		ELSE T.CorControllingAttributes
		|	END, // CorControllingAttributes
		|	T.CorVATActivityTypes,
		|	(CASE
		|		WHEN T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.DocumentVATActivityType
		|		ELSE T.VATActivityType END), // DocumentVATActivityType
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.ProductCostElement,
		|	ISNULL(Adjusting.DocumentBasis, T.DocumentSource), // DocumentSource
		|	(CASE
		// For a correction document, the priority source is the correction document itself. 
		|		WHEN T.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|		 AND NOT AcquisitionTypesOfInventory.PurchaseOrder IS NULL
		|		 AND AcquisitionTypesOfInventory.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN AcquisitionTypesOfInventory.PurchaseOrder
		|		ELSE ISNULL(CorrectedDocuments_.ReversedDocument, UNDEFINED) END), // PrioritySource
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	T.BusinessTransactionSetting,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|";
EndFunction

Function TextRemainderGrouped()
	Return 
		"SELECT
		|	""TextRemainderGrouped"" 								AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.GroupedStock) AS EntryType,
		|	FALSE AS ThisIsExactlyCalculatedMovement,
		|	FALSE AS ThisIsReverseTransaction,
		|	90	 AS Priority,
		|	0 	 AS Denominator,
		|	FALSE AS CalculationIsCompleted,
		|	Dimension.Products AS Products,
		|	UNDEFINED AS TaxationOfParty,
		|
		|	MIN(T.Period) AS Period,
		|	MIN(CASE
		// The return of past periods must be completed at the very beginning, so we leave the receipt period empty.
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN DATETIME(1,1,1)
		|		ELSE T.Period END) AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS VariancePeriod,
		|	UNDEFINED AS Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		|
		|	SUM(CASE
		|		WHEN T.Count < 0 THEN -T.Count
		|		ELSE T.Count END) AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	UNDEFINED AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	UNDEFINED AS CorGrossInitialCostENT,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS DocumentRegisterRecords,
		|	UNDEFINED AS RowID,
		|	UNDEFINED AS ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS DocumentVATActivityType,
		|	UNDEFINED AS VATActivityTypeShipments,
		|	UNDEFINED AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED AS CostAccountingTransaction,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	UNDEFINED AS CorLineOfBusiness,
		|	0 AS RowCode,
		|	UNDEFINED AS CCDNumber,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" AS FinRecordID,
		|	UNDEFINED AS GLAccountSettings,
		|	FALSE AS ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	UNDEFINED AS CostDefiningMethod,
		|	DATETIME(1,1,1) AS CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = T.Recorder
		|		AND T.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|WHERE
		|	T.Count <> 0
		|	AND T.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.ReversingEntry),
		|		VALUE(Enum.LotRecordTypes.PreviousPeriodReturn),
		|		VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument))
		// We exclude documents for which storno or correction has been entered, because such documents are sources for storno records.
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|GROUP BY
		|	Dimension.Products,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization
		|";
EndFunction

// For a situation where the implementation document has several adjustments, and one of them corrects products
// that are only in another adjustment (this product is not in the original implementation), we create a separate sub-asset of the Implementation adjustment
// For such a situation, a chain is being built:
// Consumption (first adjustment) -> Realisation adjustment (communication by Registrar) -> Reverse (communication by Document source)
// The connection Consumption -> Reverse is impossible to build directly, because these sub-assets do not have a suitable field for communication.
Function TextOfCorrectionImplementation()
	Return 
		"SELECT
		|	""TextOfCorrectionImplementation"" 								 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.SaleAdjustment) AS EntryType,
		|	FALSE AS ThisIsExactlyCalculatedMovement,
		|	FALSE AS ThisIsReverseTransaction,
		|	90	 AS Priority,
		|	0 	 AS Denominator,
		|	FALSE AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	UNDEFINED AS TaxationOfParty,
		|
		|	MIN(T.Period) AS Period,
		|	&BeginningOfNextPeriod AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS VariancePeriod,
		|	T.Recorder AS Recorder,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		|
		|	SUM(T.Count) AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	UNDEFINED AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	UNDEFINED AS CorGrossInitialCostENT,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS DocumentRegisterRecords,
		|	UNDEFINED AS RowID,
		|	UNDEFINED AS ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	UNDEFINED AS CorVATActivityTypes,
		|	UNDEFINED AS DocumentVATActivityType,
		|	UNDEFINED AS VATActivityTypeShipments,
		|	UNDEFINED AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED AS CostAccountingTransaction,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	SalesOfGoodsAndServices.SaleOfGoodsAndServices AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	UNDEFINED AS CorLineOfBusiness,
		|	0 AS RowCode,
		|	UNDEFINED AS CCDNumber,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" AS FinRecordID,
		|	UNDEFINED AS GLAccountSettings,
		|	FALSE AS ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	UNDEFINED AS CostDefiningMethod,
		|	DATETIME(1,1,1) AS CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Document.SaleAdjustment AS AdjustingEntries
		|		ON AdjustingEntries.Ref = T.Recorder
		|	INNER JOIN TTReverseImplementations AS SalesOfGoodsAndServices
		|		ON SalesOfGoodsAndServices.SaleOfGoodsAndServices = AdjustingEntries.DocumentBasis
		|WHERE
		|	T.Count <> 0
		|	AND T.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|GROUP BY
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Recorder,
		|	SalesOfGoodsAndServices.SaleOfGoodsAndServices
		|";
EndFunction

Function TextCurTurnoverOfLotsOfGoods() // uses returnable waste
	QueryText =
		"SELECT
		|	""TextCurTurnoverOfLotsOfGoods"" 						AS RequestSource,
		|	T.EntryType 												AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)										AS ThisIsReverseTransaction,
		|	(CASE
		|		WHEN T.OfficialTypeOfMovementParish AND T.EntryType IN (&UnreadableRecordTypes) THEN 10
		|		ELSE 90 END)											AS Priority,
		|	0 															AS Denominator,
		|	CASE
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|				OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|		THEN TRUE
		|		WHEN NOT (T.Organization IN (&SFIFOOrganizationsSliding))
		|		    AND T.EntryType = VALUE(Enum.LotRecordTypes.ConsumptionGoodsInTransit)
		|		THEN TRUE 
		|		ELSE FALSE
		|	END 														AS CalculationIsCompleted,
		|	Dimension.Products										AS Products,
		|	CASE WHEN (T.EntryType IN (&UnreadableRecordTypes) AND T.Organization IN (&SFIFOOrganizationsSliding))
		|		OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|		OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|		THEN T.LotVendorAttributes.VATTaxation
		|		ELSE UNDEFINED
		|	END 														AS TaxationOfParty,
		|
		|	T.Period AS Period,
		|	CASE
		// To adjust the acquisition of the previous period, the value of the "Receipt Period" field is determined by the date of the document being corrected.
		// to adjust the Cur period, the value of the "receipt period" field is determined by the start date of the period,
		// so that the batch is selected first to adjust the purchase.
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|		 AND PurchaseAdjustment.DocumentBasis IS NOT NULL
		|		 AND RegisterOfPurchaseAdjustments.IBDocumentDate IS NOT NULL
		|		 AND RegisterOfPurchaseAdjustments.IBDocumentDate < &BeginOfPeriod
		|			THEN RegisterOfPurchaseAdjustments.IBDocumentDate
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			THEN &BeginOfPeriod
		// To return without a source document, we increase the receipt period by 1 second,
		// so that the return by sorting would be later than consumption.
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			THEN DATEADD(T.Period, SECOND, 1)
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		 AND NOT SourceDocument.Date IS NULL
		|			THEN SourceDocument.Date
		// The return of past periods must be completed at the very beginning, so we leave the receipt period empty. 
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN DATETIME(1,1,1)
		// For the release of products by the production stage, the receipt period will be increased by 1 second,
		// so that the release to the sorting division will be later than the transfer of materials to the division.
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.Recorder REFS Document.ProductionStage2_2
		|			THEN DATEADD(T.Period, SECOND, 1)
		// For consumption by the production stage, we take the receipt period from the document date
		// if the consumption date is equal to the stage date.
		|		WHEN T.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Consumption),
		|			VALUE(Enum.LotRecordTypes.Move))
		|		 AND T.Recorder REFS Document.ProductionStage2_2
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND ENDOFPERIOD(ProductionStage.Date, DAY) = ENDOFPERIOD(T.Period, DAY)
		|			THEN ProductionStage.Date
		// For consumption by production without an order, we take the receipt period from the date of the document.
		|		WHEN T.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Consumption),
		|			VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots))
		|		 AND T.Recorder REFS Document.BackflushProduction
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN BackflushProduction.Date
		|		WHEN T.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Consumption),
		|			VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots))
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND T.CorAccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN ENDOFPERIOD(T.Period, DAY)
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		 AND T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|			THEN ENDOFPERIOD(T.Period, DAY)
		|		WHEN T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|			AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			AND NOT T.OfficialTypeOfMovementParish
		|			THEN ENDOFPERIOD(T.Period, DAY)
		|		WHEN ReturnsOfGoodsToSupplier.DocumentInflow.Date IS NOT NULL
		|				AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN ReturnsOfGoodsToSupplier.DocumentInflow.Date
		|		ELSE T.Period
		|	END AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	CASE WHEN (T.EntryType IN (&UnreadableRecordTypes)
		|				AND T.Organization IN (&SFIFOOrganizationsSliding))
		|		OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|		OR T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|			AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			AND NOT T.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Consumption),
		|				VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot))
		|		OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|		OR T.ReversingEntry
		|			THEN T.Lot
		|		WHEN ReturnsOfGoodsToSupplier.DocumentInflow IS NOT NULL
		|				AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN ReturnsOfGoodsToSupplier.DocumentInflow
		|		WHEN GoodsShipmentFromStorage.DocumentInflow IS NOT NULL
		|				AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN GoodsShipmentFromStorage.DocumentInflow
		|		WHEN VALUETYPE(ISNULL(UninvoicedReceipt.ReferenceOrder, UNDEFINED)) = TYPE(Document.VendorInvoice)
		|		 AND T.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 	THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN PurchaseAdjustment.DocumentBasis IS NOT NULL
		|				AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN PurchaseAdjustment.DocumentBasis
		|		WHEN VALUETYPE(ISNULL(MovementOfProductsAndMaterials.ReferenceOrder, UNDEFINED)) = TYPE(Document.ProductionStage2_2)
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND NOT T.OfficialTypeOfMovementParish
		|			THEN MovementOfProductsAndMaterials.ReferenceOrder
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	(CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN NOT CorProductionOrder.Ref IS NULL
		|			THEN CorProductionOrder.Ref
		|		ELSE UNDEFINED END) AS ProductionOrder,
		|	CASE WHEN (T.EntryType IN (&UnreadableRecordTypes)
		|				AND T.Organization IN (&SFIFOOrganizationsSliding))
		|		OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|		OR T.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			AND T.Organization IN (&SFIFOOrganizationsSliding)
		|		OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
		|			AND NOT T.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Consumption),
		|				VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot))
		|		OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|		OR T.ReversingEntry
		|			THEN T.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END AS LotVendorAttributes,
		|	CASE
		|		WHEN T.FinancialAccountingDimension REFS Catalog.AnalyticalInventoryGroups
		|		 AND (NOT &AnalyticalAccountingByProductsGroups
		// There is no indication of the product group in the movement of goods and in the adjustment of the destination.
		|		 OR NOT Move.Ref IS NULL
		|		 OR NOT AssignmentAdjustment.Ref IS NULL)
		|			THEN UNDEFINED
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND T.FinancialAccountingDimensionOfDocument <> UNDEFINED
		|		 AND T.EntryType <> VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN T.FinancialAccountingDimensionOfDocument
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|			OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			OR T.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|			OR T.EntryType = VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis)
		|			OR T.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			OR T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|				AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|			THEN T.FinancialAccountingDimension
		|		WHEN NOT T.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND &AnalyticalAccountingByProductsGroups
		|			THEN T.ProductsGroup
		|		WHEN T.CorControllingAttributes REFS Catalog.AnalyticalInventoryGroups
		|		 AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN UNDEFINED
		|		ELSE T.CorControllingAttributes
		|	END AS FinancialAccountingDimension,
		|	CASE
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		 OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|		 OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|			THEN T.VATActivityType
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(CorBatchProduction.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN CorBatchProduction.VATActivityType
		// According to off-balance sheet sections of accounting, only a semi-finished product of the giver may have an off-balance sheet cost.
		// In other cases, there is only an off-balance sheet cost and we do not fill in the VAT on them.
		|		WHEN T.AccountingSection IN (&OffBalanceSheetAccountingSections)
		|		 AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		  AND ISNULL(T.InventoryOwnerAttribute.InventoryType, UNDEFINED) <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
		|			THEN UNDEFINED
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.CorItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND NOT (T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|				AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN (CASE
		|				WHEN T.CorItemsLocationAttributes.Purpose.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportSale)
		|					THEN (CASE WHEN ISNULL(T.CorItemsLocationAttributes.Products.FEACNCode.Commodity, FALSE)
		|						THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
		|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods) END)
		|				ELSE T.CorItemsLocationAttributes.Purpose.VATActivityType END)
		// If the assignment is not filled in in the inventory accounting analytics, for example, when transferring to a reworker, but
		// the assignment is filled in in the inventory accounting analytics, the VAT taxation is determined by the purpose specified in the analytics. 
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			AND NOT (T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|				AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN (CASE
		|				WHEN T.ItemsLocationAttributes.Purpose.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportSale)
		|					THEN (CASE WHEN ISNULL(T.ItemsLocationAttributes.Products.FEACNCode.Commodity, FALSE)
		|						THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
		|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods) END)
		|				ELSE T.ItemsLocationAttributes.Purpose.VATActivityType END)
		|
		|		WHEN NOT Move.TransferForActivity IS NULL
		|			THEN
		|				CASE WHEN Move.TransferForActivity <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|					THEN Move.TransferForActivity
		|				WHEN T.OfficialTypeOfMovementParish AND OrganizationsWithOneTypeOfActivity.VATActivityType IS NULL
		|					THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|				ELSE ISNULL(OrganizationsWithOneTypeOfActivity.VATActivityType, AccountingPoliciesOfOrganizations_.DefaultVATTaxation) END
		|		WHEN NOT InventoryConsumption.ConsumptionForActivity IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN CASE
		|				WHEN NOT WriteOffItem.Ref IS NULL
		|				 AND WriteOffItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|				 AND WriteOffItem.VATAssetTaxClass IN (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
		|				 AND WriteOffItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|					THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
		|				WHEN InventoryConsumption.ConsumptionForActivity <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|					THEN InventoryConsumption.ConsumptionForActivity
		|					ELSE AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|				END
		|		WHEN NOT AssignmentAdjustment.Ref IS NULL AND NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN NOT AssignmentAdjustment.Ref IS NULL
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferBalancesToNewActivityType)
		|			AND NOT T.OfficialTypeOfMovementParish
		|		THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN NOT Misgrading.VATActivityType IS NULL
		|			THEN
		|				CASE WHEN Misgrading.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|					THEN Misgrading.VATActivityType
		|					ELSE AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|				END
		|		WHEN NOT Damage.VATActivityType IS NULL
		|			THEN
		|				CASE WHEN Damage.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|					THEN Damage.VATActivityType
		|					ELSE AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|				END
		|		WHEN NOT GoodsHandover.VATTaxation IS NULL THEN
		|			GoodsHandover.VATTaxation
		|		WHEN NOT MovementOfProductsAndMaterials.VATTaxation IS NULL
		|			THEN
		|				CASE WHEN MovementOfProductsAndMaterials.VATTaxation <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|					THEN MovementOfProductsAndMaterials.VATTaxation
		|					ELSE AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|				END
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		// Filling in the Document Activity types and Document activity types must correspond to filling in the corresponding fields
		// in the Operation descriptionaccountability() function of the document manager module to return the goods to the supplier.
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
		|		 AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.ItemsLocationAttributes.Purpose.VATActivityType
		|		WHEN ReturnsOfGoodsToSupplier.DocumentInflow.PurchaseForActivity IS NOT NULL
		|			THEN ReturnsOfGoodsToSupplier.DocumentInflow.PurchaseForActivity
		// The documents "Transfer of goods to the Custodian" and "Receipt of goods to the Custodian" do not have data on the VAT taxation activity,
		// therefore, for these documents, the VAT taxation activity of the selected batch must be preserved.
		|		WHEN VALUETYPE(T.Recorder) = TYPE(Document.TransferOfGoodsToBailee)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN VALUETYPE(T.Recorder) = TYPE(Document.ReceiptOfGoodsFromCustodian)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		 AND T.EntryType <> VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|		 AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|		 AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferBalancesToNewActivityType)
		|			THEN T.DocumentVATActivityType
		|		WHEN T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		 OR T.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|		 OR T.EntryType = VALUE(Enum.LotRecordTypes.ReversingEntry)
		|			AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		ELSE T.CorVATActivityTypes
		|	END AS VATActivityType,
		|
		|	T.Count,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.OffBalanceCost,
		|	T.CostMan,
		|	T.AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan,
		|	T.ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost,
		|	T.OffBalanceCostLocal,
		|	T.PermanentDifference,
		|	T.CostTD,
		|	T.CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal,
		|	T.LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		// The filling in of the Priority Economic Operation field should be the same in the functions:
		// -
		// - The text of the current turnover of the Party goods() - The text of the movement of the corrected documents of the current period() - The text of the movement of the corrected documents of the previous period()
		// 
		|	(CASE
		|		WHEN T.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN UNDEFINED
		|		WHEN T.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots))
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND T.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		ELSE UNDEFINED END) AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	(CASE
		|		WHEN T.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|		 AND T.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			THEN PurchaseOfGoods.Department
		|		ELSE T.Department END) AS Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		// Filling in the Corporate Party and Corporate Party account fields must correspond to the request of the Textstor of the movement of corrected documentsreferences of the current period().
		|	(CASE
		|		WHEN T.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN UNDEFINED
		|		WHEN T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND (T.CorLot <> T.Recorder
		|			OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToProduction))
		|		 AND T.EntryType <> VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|		 AND T.CorItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|			THEN UNDEFINED
		|		WHEN T.CorLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE T.CorLot END) AS CorLot,
		|	(CASE
		|		WHEN T.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN UNDEFINED
		|		WHEN T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND (T.CorLot <> T.Recorder
		|			OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToProduction))
		|		 AND T.EntryType <> VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|			THEN UNDEFINED
		|		ELSE T.LotVendorAttributesCorr END) AS LotVendorAttributesCorr,
		|	CASE
		|		WHEN FALSE THEN UNDEFINED // for easy tag placement
		|		WHEN (T.CorControllingAttributes REFS Catalog.AnalyticalInventoryGroups
		|			OR T.FinancialAccountingDimensionOfDocument REFS Catalog.AnalyticalInventoryGroups)
		|		 AND (NOT &AnalyticalAccountingByProductsGroups
		// For incoming movements, we do not fill in the "Coralitikafinancovogoucheta".
		|		 OR T.OfficialTypeOfMovementParish
		// There is no indication of the product group in the movement of goods and in the adjustment of the destination.
		|		 OR NOT Move.Ref IS NULL
		|		 OR NOT AssignmentAdjustment.Ref IS NULL)
		|			THEN UNDEFINED
		// In the "Work in progress" section of the financial accounting analytics, there should be a group of products from the production batch.
		|		WHEN NOT CorBatchProduction.ProductsGroup IS NULL
		|		 AND &AnalyticalAccountingByProductsGroups
		|		 AND CorBatchProduction.ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|			THEN CorBatchProduction.ProductsGroup
		|		WHEN NOT CorBatchProduction.ProductsGroup IS NULL
		|		 AND (NOT &AnalyticalAccountingByProductsGroups
		|		 	OR CorBatchProduction.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef))
		|			THEN UNDEFINED
		|		WHEN NOT T.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		 AND (ISNULL(CorDimension.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Department)
		|				OR ISNULL(CorWarehouses.ShopFloorStockroom, FALSE))
		|		 AND &AnalyticalAccountingByProductsGroups
		|			THEN T.ProductsGroup
		|		WHEN T.FinancialAccountingDimensionOfDocument REFS Catalog.AnalyticalInventoryGroups
		|		 AND (ISNULL(CorDimension.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Department)
		|				OR ISNULL(CorWarehouses.ShopFloorStockroom, FALSE))
		|		 AND &AnalyticalAccountingByProductsGroups
		|			THEN T.FinancialAccountingDimensionOfDocument
		|		WHEN T.FinancialAccountingDimensionOfDocument <> UNDEFINED
		|		 AND NOT T.OfficialTypeOfMovementParish
		|		 AND NOT T.FinancialAccountingDimensionOfDocument REFS Catalog.AnalyticalInventoryGroups
		|		 AND CorBatchProduction.Ref IS NULL
		|			THEN T.FinancialAccountingDimensionOfDocument
		// For the "Moving" type of records, the financial accounting Analytics field is filled in in the procedure to fill in the Calculation partyusest value of goods().
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|			THEN UNDEFINED
		|		ELSE T.CorControllingAttributes
		|	END AS CorControllingAttributes,
		|	CASE
		|
		// The type of activity of VAT must always correspond to the batch of production, even if the VATS
		// taxation activity is not filled in the batch of production, because in the Register Recorded with the quantity, the VAT taxation activity is always determined 
		// from the batch of production.
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND NOT CorBatchProduction.VATActivityType IS NULL
		|			THEN CorBatchProduction.VATActivityType
		// According to off-balance sheet sections of accounting, only a semi-finished product of the giver may have an off-balance sheet cost.
		// In other cases, there is only an off-balance sheet cost and cor. Type of activitiesnot VAT is filled in.
		|		WHEN T.CorAccountingSection IN (&OffBalanceSheetAccountingSections)
		|		 AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		  AND ISNULL(T.CorInventoryOwnerAttribute.InventoryType, UNDEFINED) <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
		|			THEN UNDEFINED
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.CorItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|				AND NOT (T.AccountingSection IN (
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|					AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|				AND NOT (T.CorAccountingSection IN (
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|					AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN (CASE
		|				WHEN T.CorItemsLocationAttributes.Purpose.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportSale)
		|					THEN (CASE WHEN ISNULL(T.CorItemsLocationAttributes.Products.FEACNCode.Commodity, FALSE)
		|						THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
		|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods) END)
		|				ELSE T.CorItemsLocationAttributes.Purpose.VATActivityType END)
		|		WHEN NOT Move.TransferForActivity IS NULL AND NOT T.OfficialTypeOfMovementParish
		|		 AND Move.TransferForActivity <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN Move.TransferForActivity
		|		WHEN NOT InventoryConsumption.ConsumptionForActivity IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN CASE
		|				WHEN NOT WriteOffItem.Ref IS NULL
		|				 AND WriteOffItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|				 AND WriteOffItem.VATAssetTaxClass IN (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
		|				 AND WriteOffItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|					THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
		|				WHEN NOT WriteOffItem.Ref IS NULL
		|				 AND WriteOffItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|					THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|				ELSE InventoryConsumption.ConsumptionForActivity END
		|		WHEN NOT AssignmentAdjustment.Ref IS NULL AND NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN NOT AssignmentAdjustment.Ref IS NULL
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN NOT DetailedBalanceCorrection.Ref IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN NOT Misgrading.VATActivityType IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN Misgrading.VATActivityType
		|		WHEN NOT Damage.VATActivityType IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN Damage.VATActivityType
		|		WHEN NOT MovementOfProductsAndMaterials.VATTaxation IS NULL AND NOT T.OfficialTypeOfMovementParish
		|		 AND MovementOfProductsAndMaterials.VATTaxation <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN MovementOfProductsAndMaterials.VATTaxation
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
		|		 AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.ItemsLocationAttributes.Purpose.VATActivityType
		|		WHEN ReturnsOfGoodsToSupplier.DocumentInflow.PurchaseForActivity IS NOT NULL
		|			THEN ReturnsOfGoodsToSupplier.DocumentInflow.PurchaseForActivity
		// The documents "Transfer of goods to the Custodian" and "Receipt of goods to the Custodian" do not have data on the VAT taxation activity,
		// therefore, for these documents, the VAT taxation activity of the selected batch must be preserved.
		|		WHEN VALUETYPE(T.Recorder) = TYPE(Document.TransferOfGoodsToBailee)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN VALUETYPE(T.Recorder) = TYPE(Document.ReceiptOfGoodsFromCustodian)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		
		// The type of activity of VAT must correspond to the type of activity of the VAT document, except for the transfer of goods between organizations.
		// For the transfer of goods between cor organizations, the type of activity is determined by the type of activity of the recipient organization or 
		// by the value of the "Transfer for activity" field. At the same time, the COR type of VAT activity is filled in when carrying out the document.
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		 AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
		|		 AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|			THEN T.DocumentVATActivityType
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE T.CorVATActivityTypes
		|	END AS CorVATActivityTypes,
		|
		|	CASE
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND NOT CorBatchProduction.VATActivityType IS NULL
		|			THEN CorBatchProduction.VATActivityType
		|		WHEN T.CorAccountingSection IN (&OffBalanceSheetAccountingSections)
		|		 AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|			THEN UNDEFINED
		|		WHEN NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.CorItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|				AND NOT (T.AccountingSection IN (
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|					AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|				AND NOT (T.CorAccountingSection IN (
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|					AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN (CASE
		|				WHEN T.CorItemsLocationAttributes.Purpose.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportSale)
		|					THEN (CASE WHEN ISNULL(T.CorItemsLocationAttributes.Products.FEACNCode.Commodity, FALSE)
		|						THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
		|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods) END)
		|				ELSE T.CorItemsLocationAttributes.Purpose.VATActivityType END)
		|		WHEN T.CorAccountingSection IN (&OffBalanceSheetAccountingSections)
		|			THEN UNDEFINED
		|		WHEN NOT Move.TransferForActivity IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN Move.TransferForActivity
		|		WHEN NOT InventoryConsumption.ConsumptionForActivity IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN CASE
		|				WHEN NOT WriteOffItem.Ref IS NULL
		|				 AND WriteOffItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|				 AND WriteOffItem.VATAssetTaxClass IN (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
		|				 AND WriteOffItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|					THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
		|				WHEN NOT WriteOffItem.Ref IS NULL
		|				 AND WriteOffItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|					THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|				ELSE InventoryConsumption.ConsumptionForActivity END
		|		WHEN NOT AssignmentAdjustment.Ref IS NULL AND NOT T.OfficialTypeOfMovementParish
		|		 AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN NOT AssignmentAdjustment.Ref IS NULL
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN NOT DetailedBalanceCorrection.Ref IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN NOT Misgrading.VATActivityType IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN Misgrading.VATActivityType
		|		WHEN NOT Damage.VATActivityType IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN Damage.VATActivityType
		|		WHEN NOT MovementOfProductsAndMaterials.VATTaxation IS NULL AND NOT T.OfficialTypeOfMovementParish
		|			THEN MovementOfProductsAndMaterials.VATTaxation
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
		|		 AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.ItemsLocationAttributes.Purpose.VATActivityType
		|		WHEN ReturnsOfGoodsToSupplier.DocumentInflow.PurchaseForActivity IS NOT NULL
		|			THEN ReturnsOfGoodsToSupplier.DocumentInflow.PurchaseForActivity
		// The documents "Transfer of goods to the Custodian" and "Receipt of goods to the Custodian" do not have data on the VAT taxation activity,
		// therefore, for these documents, the VAT taxation activity of the selected batch must be preserved.
		|		WHEN VALUETYPE(T.Recorder) = TYPE(Document.TransferOfGoodsToBailee)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN VALUETYPE(T.Recorder) = TYPE(Document.ReceiptOfGoodsFromCustodian)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		WHEN T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN T.DocumentVATActivityType
		|		ELSE T.CorVATActivityTypes
		|	END AS DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	CASE
		|		WHEN T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			AND T.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|			THEN T.Recorder
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|		 AND VALUETYPE(T.Recorder) = TYPE(Document.PurchaseAdjustment)
		|			THEN T.DocumentSource
		|		WHEN NOT T.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.ReversingEntry),
		|			VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction),
		|			VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction),
		|			VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse),
		|			VALUE(Enum.LotRecordTypes.PreviousPeriodReturn),
		|			VALUE(Enum.LotRecordTypes.Supplement))
		|		THEN UNDEFINED
		|		ELSE T.DocumentSource
		|	END AS DocumentSource,
		|	(CASE
		|		WHEN T.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN T.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND NOT AcquisitionTypesOfInventory.PurchaseOrder IS NULL
		|		 AND AcquisitionTypesOfInventory.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|			THEN AcquisitionTypesOfInventory.PurchaseOrder
		// For the processor's report, we select batches based on the production order.
		|		WHEN T.AccountingSection IN
		|		  (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller),
		|		   VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners),
		|		   VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners))
		|		 AND NOT CorProductionOrder.Ref IS NULL
		|			THEN CorProductionOrder.Ref
		|		ELSE ISNULL(CorrectedDocuments_.Recorder, UNDEFINED) END) AS PrioritySource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorDimension
		|		ON CorDimension.Ref = T.CorItemsLocationAttributes
		|	LEFT JOIN Catalog.Warehouses AS CorWarehouses
		|		ON CorDimension.StorageLocation = CorWarehouses.Ref
		|	LEFT JOIN Document.InventoryTransfer AS Move
		|		ON Move.Ref = T.Recorder
		|	LEFT JOIN Document.InventoryAssignmentAdjustment AS AssignmentAdjustment
		|		ON AssignmentAdjustment.Ref = T.Recorder
		|	LEFT JOIN Document.InventoryConsumption AS InventoryConsumption
		|		ON InventoryConsumption.Ref = T.Recorder
		|	LEFT JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
		|		ON PurchaseAdjustment.Ref = T.Recorder
		|	LEFT JOIN RegisterOfDocumentsOfBatchOfPurchaseAdjustments AS RegisterOfPurchaseAdjustments
		|		ON RegisterOfPurchaseAdjustments.Ref = PurchaseAdjustment.DocumentBasis
		|	LEFT JOIN Document.GoodsMisgrading AS Misgrading
		|		ON Misgrading.Ref = T.Recorder
		|	LEFT JOIN Document.GoodsDamage AS Damage
		|		ON Damage.Ref = T.Recorder
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = T.Recorder
		|	LEFT JOIN Document.VendorInvoice AS PurchaseOfGoods
		|		ON PurchaseOfGoods.Ref = T.Recorder
		|	LEFT JOIN Document.VendorInvoice.InventoryKinds AS AcquisitionTypesOfInventory
		|		ON AcquisitionTypesOfInventory.Ref = T.Recorder
		|		AND AcquisitionTypesOfInventory.RowID = T.RowID
		|	LEFT JOIN Document.CustomerInvoiceIntercompany AS GoodsHandover
		|		ON GoodsHandover.Ref = T.Recorder
		|	LEFT JOIN Document.SourceDocument AS SourceDocument
		|		ON SourceDocument.Ref = T.Lot
		|	LEFT JOIN Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting AS DetailedBalanceCorrection
		|		ON DetailedBalanceCorrection.Ref = T.Recorder
		|	LEFT JOIN Document.MovementOfProductsAndMaterials AS MovementOfProductsAndMaterials
		|		ON MovementOfProductsAndMaterials.Ref = T.Recorder
		|	LEFT JOIN Catalog.ProductionLots AS CorBatchProduction
		|		ON CorBatchProduction.Ref = T.CorLot
		|	LEFT JOIN Document.BackflushProduction AS BackflushProduction
		|		ON BackflushProduction.Ref = T.Recorder
		|	LEFT JOIN Document.ReturnOfGoodsToVendor.InventoryKinds AS ReturnsOfGoodsToSupplier
		|		ON ReturnsOfGoodsToSupplier.Ref = T.Recorder
		|		AND T.RowID = ReturnsOfGoodsToSupplier.RowID
		|	LEFT JOIN Document.GoodsShipmentFromStorage.InventoryKinds AS GoodsShipmentFromStorage
		|		ON GoodsShipmentFromStorage.Ref = T.Recorder
		|		AND T.RowID = GoodsShipmentFromStorage.RowID
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations_
		|		ON T.Organization = AccountingPoliciesOfOrganizations_.Organization
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS WriteOffItem
		|		ON WriteOffItem.Ref = T.ExpenseItemOfWriteOff
		|	LEFT JOIN Document.ProductionStage2_2 AS ProductionStage
		|		ON ProductionStage.Ref = T.Recorder
		|	LEFT JOIN Document.ProductionStage2_2 AS BatchProductionStage
		|		ON BatchProductionStage.Ref = T.Lot
		|	LEFT JOIN Document.ProductionOrder2_2 AS CorProductionOrder
		|		ON CorProductionOrder.Ref = CorBatchProduction.Document
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.Recorder = T.Recorder
		|	LEFT JOIN TTOrganizationsWithOneTypeOfActivityVAT AS OrganizationsWithOneTypeOfActivity
		|		ON T.Organization = OrganizationsWithOneTypeOfActivity.Organization
		|WHERE
		|	(T.Count <> 0 OR T.EntryType = VALUE(Enum.LotRecordTypes.Supplement))
		|	AND NOT T.ReversingEntry
		|	AND (NOT T.LotCalculationPerformed
		|		OR &RestoreChronologicalSequenceOfDebitingBatches)
		// The receipts for the implementation of the regl accounting are described in the function textcurrent realizationtolkoregl()
		|	AND NOT (T.EntryType = VALUE(Enum.LotRecordTypes.TransferMan)
		|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
		// The receipt of primary batches is described in the functions of the text endpoints of the Party items() and the text of the Incoming Party items()
		|	AND T.EntryType <> VALUE(Enum.LotRecordTypes.Lot)
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|";
	Return QueryText;
EndFunction

Function TextCurImplementationsOfLocalOnly()
	Return 
		"SELECT
		|	""TextCurImplementationsOfLocalOnly"" AS RequestSource,
		|	DD.EntryType,
		|	FALSE AS ThisIsExactlyCalculatedMovement,
		|	FALSE AS ThisIsReverseTransaction,
		|	90 AS Priority,
		|	0 AS Denominator,
		|	FALSE AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products AS Products,
		|	DD.LotVendorAttributes.VATTaxation AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	SUM(DD.Count) AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	UNDEFINED AS LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes AS CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	DD.EntryType = VALUE(Enum.LotRecordTypes.TransferMan)
		|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
		|GROUP BY
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.LotVendorAttributes.VATTaxation,
		|	DD.Period,
		|	DD.VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END, // RecordType
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.BusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END), // DocumentVATActivityType
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|";
EndFunction

Function TextCurTurnsOfProductionCosts()
	Return
		"SELECT
		|	""TextCurTurnsOfProductionCosts"" 	  			AS RequestSource,
		|	CASE WHEN
		|		T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|			THEN VALUE(Enum.LotRecordTypes.Supplement)
		|			ELSE T.EntryType
		|	END														AS EntryType,
		|	TRUE														AS ThisIsExactlyCalculatedMovement,
		|	FALSE														AS ThisIsReverseTransaction,
		|	45 										  					AS Priority,
		|	0 										  					AS Denominator,
		|	CASE
		|		WHEN T.Organization IN (&MediumSlipOrganizations)
		|			THEN TRUE
		|		WHEN T.EntryType IN (&UnreadableRecordTypes)
		|		 OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END 														AS CalculationIsCompleted,
		|	T.ItemsLocationAttributes.Products 					AS Products,
		|	CASE WHEN (T.EntryType IN (&UnreadableRecordTypes) AND T.Organization IN (&SFIFOOrganizationsSliding))
		|		OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|		THEN T.LotVendorAttributes.VATTaxation
		|		ELSE UNDEFINED
		|	END 														AS TaxationOfParty,
		|
		|	T.Period,
		|	T.Period AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	T.RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	CASE WHEN (T.EntryType IN (&UnreadableRecordTypes) AND T.Organization IN (&SFIFOOrganizationsSliding))
		|		OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|		THEN T.Lot
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	CASE WHEN (T.EntryType IN (&UnreadableRecordTypes) AND T.Organization IN (&SFIFOOrganizationsSliding))
		|		OR T.ItemsLocationAttributes.ProductCostElement <> VALUE(Catalog.ProductCostElements.EmptyRef)
		|		THEN T.LotVendorAttributes
		|		ELSE UNDEFINED
		|	END AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	T.Count,
		|	T.Cost AS Cost,
		|	T.CostExcludingVAT AS CostExcludingVAT,
		|	T.OffBalanceCost AS OffBalanceCost,
		|	CASE
		|		WHEN &CompanyManagementAccounting
		|		THEN T.Cost
		|		ELSE T.CostMan
		|	END AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost AS LocalCost,
		|	T.OffBalanceCostLocal AS OffBalanceCostLocal,
		|	T.PermanentDifference AS PermanentDifference,
		|	0 AS CostTD,
		|	T.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	UNDEFINED AS DocumentRegisterRecords,
		|	T.RowID,
		|	UNDEFINED AS ProductsGroup,
		|	CASE
		|		WHEN T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			AND T.CorLot <> T.Recorder
		|			AND NOT VALUETYPE(T.CorLot) = TYPE(Catalog.ProductionLots)
		|			THEN UNDEFINED
		|		ELSE T.CorLot
		|	END AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes AS CorControllingAttributes,
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|	T.CorVATActivityTypes AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	UNDEFINED AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED AS CostAccountingTransaction,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	UNDEFINED AS CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	FALSE AS ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	DATETIME(1,1,1) AS CostCalculationDate
		|FROM
		|	TTProductionCostsCostOfGoods AS T
		|WHERE
		|	T.Count <> 0
		|";
EndFunction

Function TextStornoOfRegisteredRecordedDistributionOfMaterialsMediumSlip()
	Return "
		|SELECT
		|	""TextStornoOfRegisteredRecordedDistributionOfMaterialsMediumSlip"" AS RequestSource,
		|	T.EntryType 												AS EntryType,
		|	TRUE														AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)										AS ThisIsReverseTransaction,
		|	10															AS Priority,
		|	0 															AS Denominator,
		|	TRUE 														AS CalculationIsCompleted,
		|	Dimension.Products										AS Products,
		|	UNDEFINED												AS TaxationOfParty,
		|
		|	T.Period AS Period,
		|	T.Period AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	-T.Count AS Count,
		|	-T.Cost AS Cost,
		|	-T.CostExcludingVAT AS CostExcludingVAT,
		|	-T.OffBalanceCost AS OffBalanceCost,
		|	-T.CostMan AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	-T.LocalCost AS LocalCost,
		|	-T.OffBalanceCostLocal AS OffBalanceCostLocal,
		|	-T.PermanentDifference AS PermanentDifference,
		|	-T.CostTD AS CostTD,
		|	-T.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	T.DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	T.LotCalculationPerformed,
		|	T.MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|WHERE
		|	T.Organization IN (&MediumSlipOrganizations)
		|	AND T.Count <> 0
		|	AND NOT T.OfficialTypeOfMovementParish
		|	AND NOT T.LotCalculation
		|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
		|";
EndFunction

Function TextInitialBalancesOfImportPurchases()
	Return 
		"SELECT
		|	""TextInitialBalancesOfImportPurchases"" 	  	AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Previous) AS EntryType,
		|	FALSE											AS ThisIsExactlyCalculatedMovement,
		|	FALSE											AS ThisIsReverseTransaction,
		|	0 										  		AS Priority,
		|	0								  				AS Denominator,
		|	TRUE 											AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 		AS Products,
		|	DD.LotVendorAttributes.VATTaxation 		AS TaxationOfParty,
		|
		|	&EndOfPreviousPeriod 	 					AS Period,
		|	&EndOfPreviousPeriod 	 					AS ReceiptPeriod,
		|	DATETIME(1,1,1)								AS VariancePeriod,
		|	DD.Lot 				 	 					AS Recorder,
		|	UNDEFINED 			 	 					AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.CountBalance AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	ISNULL(Inpayment.BusinessOperation, UNDEFINED) 				AS BusinessOperation,
		|	UNDEFINED															AS PriorityBusinessOperation,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) 		AS CorItemsLocationAttributes,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) 	AS CorAccountingSection,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) 							AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	UNDEFINED 															AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) 			AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	UNDEFINED															AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost.Balance(&BorderEndOfPreviousPeriod,	
		|		Organization IN (&CompanyArray)
		|		AND AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
		|	) AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN Document.VendorInvoice AS Inpayment
		|		ON Inpayment.Ref = DD.Lot
		|	LEFT JOIN ReceiptDocuments AS DocumentsOfPreviousPeriod
		|		ON DocumentsOfPreviousPeriod.Ref = DD.Lot
		|WHERE
		|	(ISNULL(Inpayment.BusinessOperation, UNDEFINED) IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseByImport),
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	OR DD.Lot = UNDEFINED)
		|	AND DocumentsOfPreviousPeriod.Ref IS NULL
		|";
EndFunction

Function TextInitialBalancesForAcquisitionAdjustment()
	Return 
		"SELECT
		|	""TextInitialBalancesForAcquisitionAdjustment"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Previous) 	  AS EntryType,
		|	FALSE												  AS ThisIsExactlyCalculatedMovement,
		|	FALSE												  AS ThisIsReverseTransaction,
		|	0 										  			  AS Priority,
		|	0								  					  AS Denominator,
		|	TRUE 												  AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 			  AS Products,
		|	DD.LotVendorAttributes.VATTaxation 			  AS TaxationOfParty,
		|
		|	DD.Period				 	 						  AS Period,
		|	DD.Period				 	 						  AS ReceiptPeriod,
		|	DATETIME(1,1,1)									  AS VariancePeriod,
		|	(CASE
		|		WHEN NOT Adjusting.Ref IS NULL THEN Adjusting.DocumentBasis
		|		ELSE DD.Recorder END)						  AS Recorder,
		|	UNDEFINED 			 	 						  AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		// For import purchases, we will fill in the batch and batch accounting analytics if the FIFO is used in the current period
		// , but there was a different evaluation method in the previous period and the batch was not filled in.
		// The situation is similar when changing the assessment method from FIFO to Monthly Average.
		// If the accounting policy changes, the batch in the cost of goods will be filled in according to the data of the batch detailing register
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot = UNDEFINED
		|			THEN DD.Recorder
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND NOT DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot <> UNDEFINED
		|			THEN UNDEFINED
		|		ELSE DD.Lot END) AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot = UNDEFINED
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND NOT DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot <> UNDEFINED
		|			THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE DD.LotVendorAttributes END) AS LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	SUM(DD.Count) AS Count,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	SUM(DD.CostMan) AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DD.LocalCost) AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation 												AS BusinessOperation,
		|	UNDEFINED															AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED 															AS DocumentSource,
		|	UNDEFINED															AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	ISNULL(PurchaseGoods.CCDNumber,
		|		 ISNULL(AcquisitionTypesOfInventory.CCDNumber, UNDEFINED))			AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN ReceiptDocuments AS Inpayment
		|		ON Inpayment.Ref = DD.Recorder
		|	LEFT JOIN Document.PurchaseAdjustment AS Adjusting
		|		ON Adjusting.Ref = DD.Recorder
		|	LEFT JOIN Document.VendorInvoice.Goods AS PurchaseGoods
		|		ON PurchaseGoods.Ref = DD.Recorder
		|		AND PurchaseGoods.RowID = DD.RowID
		|	LEFT JOIN Document.VendorInvoice.InventoryKinds AS AcquisitionTypesOfInventory
		|		ON AcquisitionTypesOfInventory.Ref = DD.Recorder
		|		AND AcquisitionTypesOfInventory.RowID = DD.RowID
		|WHERE
		|	DD.Count <> 0
		|	AND DD.Period <= &EndOfPeriod // to adjust the acquisition, there may be Cur or past source documents
		|	AND DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND DD.Period < &DateOfMigrationToBatchAccounting22)
		|
		|GROUP BY
		|	DD.LotVendorAttributes.VATTaxation, // TaxationOfParty
		|	DD.Period,
		|	(CASE
		|		WHEN NOT Adjusting.Ref IS NULL THEN Adjusting.DocumentBasis
		|		ELSE DD.Recorder END), //	Recorder
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot = UNDEFINED
		|			THEN DD.Recorder
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND NOT DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot <> UNDEFINED
		|			THEN UNDEFINED
		|		ELSE DD.Lot END), // Lot
		|	(CASE
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot = UNDEFINED
		|			THEN DD.LotVendorAttributesCorr
		|		WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|		 AND NOT DD.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND DD.Lot <> UNDEFINED
		|			THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE DD.LotVendorAttributes END), // LotVendorAttributes
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.BusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|	ISNULL(PurchaseGoods.CCDNumber,
		|		 ISNULL(AcquisitionTypesOfInventory.CCDNumber, UNDEFINED)) // CCDNumber
		|";
EndFunction

Function TextInitialBalancesForPurchaseAdjustmentsEnteringBalances()
	Return 
		"SELECT
		|	""TextInitialBalancesForPurchaseAdjustmentsEnteringBalances"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Previous) 	  AS EntryType,
		|	FALSE												  AS ThisIsExactlyCalculatedMovement,
		|	FALSE												  AS ThisIsReverseTransaction,
		|	0 										  			  AS Priority,
		|	0								  					  AS Denominator,
		|	TRUE 												  AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 			  AS Products,
		|	DD.LotVendorAttributes.VATTaxation 			  AS TaxationOfParty,
		|
		|	&EndOfPreviousPeriod 	 						  AS Period,
		|	&EndOfPreviousPeriod 	 						  AS ReceiptPeriod,
		|	DATETIME(1,1,1)									  AS VariancePeriod,
		|	DD.Lot											  AS Recorder,
		|	UNDEFINED 			 	 						  AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.Count AS Count,
		|	DD.Cost AS Cost,
		|	DD.CostExcludingVAT AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	DD.CostMan AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	DD.LocalCost AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation 												AS BusinessOperation,
		|	UNDEFINED															AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED 															AS DocumentSource,
		|	UNDEFINED															AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	FALSE																	AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN Document.OBEntryGoods AS OBEntry
		|		ON OBEntry.Ref = DD.Recorder
		|	INNER JOIN ReceiptDocuments AS Inpayment
		|		ON Inpayment.Ref = DD.Lot
		|WHERE
		|	DD.Count <> 0
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND DD.Period < &DateOfMigrationToBatchAccounting22)
		|";
EndFunction

Function TextCurImportPurchases()
	Return 
		"SELECT
		|	""TextCurImportPurchases"" 	  				 		 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Import) 			 AS EntryType,
		|	FALSE														 AS ThisIsExactlyCalculatedMovement,
		|	FALSE														 AS ThisIsReverseTransaction,
		|	10 										  					 AS Priority,
		|	0								  							 AS Denominator,
		|	TRUE 														 AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					 AS Products,
		|	DD.LotVendorAttributes.VATTaxation 					 AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	UNDEFINED AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	DD.Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	DD.CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes AS CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	DD.VATManag,
		|	DD.VATLocal,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	DD.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|	AND DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseByImport),
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|	AND NOT DD.ReversingEntry
		|";
EndFunction

Function TextCurExpensesWithoutBatchForDistribution() // Uses Declarations
	Return 
		"SELECT
		|	""TextCurExpensesWithoutBatchForDistribution"" 	  		AS RequestSource,
		|	DD.EntryType 							  					AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	FALSE														AS ThisIsReverseTransaction,
		|	10 										  					AS Priority,
		|	MAX(Declarations.Count)								AS Denominator,
		|	FALSE 														AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					AS Products,
		|	UNDEFINED 												AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	(CASE
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN Declarations.DocumentInflow
		|		ELSE UNDEFINED END) AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|
		|	0 AS Count,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(DD.OffBalanceCost) AS OffBalanceCost,
		|	SUM(DD.CostMan) AS CostMan,
		|	SUM(DD.AddExpensesMan) AS AddExpensesMan,
		|	SUM(DD.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(DD.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(DD.LaborCostsMan) AS LaborCostsMan,
		|	SUM(DD.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(DD.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(DD.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.LaborCosts) AS LaborCosts,
		|	SUM(DD.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(DD.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DD.LocalCost) AS LocalCost,
		|	SUM(DD.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD) AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(DD.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(DD.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(DD.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(DD.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(DD.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(DD.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	SUM(DD.VATManag) AS VATManag,
		|	SUM(DD.VATLocal) AS VATLocal,
		|	DD.ProductCostElement,
		|	Declarations.DocumentInflow AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN Declarations AS Declarations
		|		ON Declarations.Ref = DD.Recorder
		|		AND Declarations.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND Declarations.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND Declarations.VATActivityType = DD.VATActivityType
		|		AND Declarations.VATRate = DD.LotVendorAttributesCorr.VATRate
		|		AND Declarations.RowID = DD.RowID
		|WHERE
		|	DD.EntryType = VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified)
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.VATActivityType,
		|	DD.Period,
		|	DD.VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.BusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.RowCode,
		|	DD.ProductsGroup,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	DD.CorLineOfBusiness,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END), // DocumentVATActivityType
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	DD.ProductCostElement,
		|	Declarations.DocumentInflow,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|";
EndFunction

Function TextCurExpensesWithPartyToDistribution() // Uses declarations for access
	Return 
		"SELECT
		|	""TextCurExpensesWithPartyToDistribution"" 	  		AS RequestSource,
		|	DD.EntryType 							  					AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	FALSE														AS ThisIsReverseTransaction,
		|	10 										  					AS Priority,
		|	MAX(Declarations.Count)			  					AS Denominator,
		|	FALSE 														AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					AS Products,
		|	UNDEFINED 												AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|
		|	0 AS Count,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(DD.OffBalanceCost) AS OffBalanceCost,
		|	SUM(DD.CostMan) AS CostMan,
		|	SUM(DD.AddExpensesMan) AS AddExpensesMan,
		|	SUM(DD.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(DD.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(DD.LaborCostsMan) AS LaborCostsMan,
		|	SUM(DD.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(DD.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(DD.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.LaborCosts) AS LaborCosts,
		|	SUM(DD.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(DD.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DD.LocalCost) AS LocalCost,
		|	SUM(DD.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD) AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(DD.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(DD.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(DD.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(DD.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(DD.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(DD.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes AS CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	SUM(DD.VATManag) AS VATManag,
		|	SUM(DD.VATLocal) AS VATLocal,
		|	DD.ProductCostElement,
		|	DD.DocumentSource AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN IncomeDeclarations AS Declarations
		|		ON Declarations.Ref = DD.Recorder
		|		AND Declarations.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND Declarations.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|		AND Declarations.DocumentInflow = DD.DocumentSource
		|		AND Declarations.RowID = DD.RowID
		|WHERE
		|	DD.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|		VALUE(Enum.LotRecordTypes.IncludeVATInCostExpenses),
		|		VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.VATActivityType,
		|	DD.Period,
		|	DD.VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.BusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.RowCode,
		|	DD.ProductsGroup,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	DD.CorLineOfBusiness,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END), // DocumentVATActivityType
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|";
EndFunction

Function TextCurrentAdditionalExpensesAmountWithBatchOfImportApplication()
	QueryText = " 
		|SELECT
		|	""TextCurrentAdditionalExpensesAmountWithBatchOfImportApplication"" 	  		AS RequestSource,
		|	DD.EntryType 							  					AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	FALSE														AS ThisIsReverseTransaction,
		|	10 										  					AS Priority,
		|	SUM(ProductsOfApplication.Count * ISNULL(&QueryTextPackagingFactor, 1))	AS Denominator,
		|	FALSE 														AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					AS Products,
		|	UNDEFINED 												AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|
		|	0 AS Count,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(DD.OffBalanceCost) AS OffBalanceCost,
		|	SUM(DD.CostMan) AS CostMan,
		|	SUM(DD.AddExpensesMan) AS AddExpensesMan,
		|	SUM(DD.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(DD.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(DD.LaborCostsMan) AS LaborCostsMan,
		|	SUM(DD.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(DD.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(DD.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.LaborCosts) AS LaborCosts,
		|	SUM(DD.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(DD.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DD.LocalCost) AS LocalCost,
		|	SUM(DD.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD) AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(DD.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(DD.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(DD.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(DD.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(DD.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(DD.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	SUM(DD.VATManag) AS VATManag,
		|	SUM(DD.VATLocal) AS VATLocal,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	ISNULL(ProductsOfApplication.CDNumber, UNDEFINED) AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Document.ApplicationForImportationOfGoods.Goods AS ProductsOfApplication
		|		ON ProductsOfApplication.Ref = DD.Recorder
		|		AND ProductsOfApplication.RowID = DD.FinRecordID
		|WHERE
		|	(DD.EntryType = VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
		|		AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
		|		OR DD.EntryType = VALUE(Enum.LotRecordTypes.IncludeExciseInCost)
		|	)
		// Data on the accounting section "Unfactated deliveries" are processed at the stage of invoicing deliveries 
		// See TextCurInvoiceAdjustments.
		|	AND NOT DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT DD.ReversingEntry
		|
		|GROUP BY
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.VATActivityType,
		|	DD.Period,
		|	DD.VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.BusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.RowCode,
		|	ISNULL(ProductsOfApplication.CDNumber, UNDEFINED),
		|	DD.ProductsGroup,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	DD.CorLineOfBusiness,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END), // DocumentVATActivityType
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsOfApplication.UnitOfMeasure",
			"DD.ItemsLocationAttributes.Products"));
			
	Return QueryText;
EndFunction

Function PurchaseAdjustmentText()
	QueryText = "
		|SELECT
		|	""PurchaseAdjustmentText""							AS RequestSource,
		|	DD.EntryType 							  					AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	FALSE														AS ThisIsReverseTransaction,
		|	10 										  					AS Priority,
		|	MAX(ISNULL(ProductsOfApplication.Count, 0) * ISNULL(&QueryTextPackagingFactor, 1)) AS Denominator,
		|	FALSE 														AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					AS Products,
		|	UNDEFINED 												AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|
		|	0 AS Count,
		|	SUM(DD.Cost) AS Cost,
		|	SUM(DD.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(DD.OffBalanceCost) AS OffBalanceCost,
		|	SUM(DD.CostMan) AS CostMan,
		|	SUM(DD.AddExpensesMan) AS AddExpensesMan,
		|	SUM(DD.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(DD.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(DD.LaborCostsMan) AS LaborCostsMan,
		|	SUM(DD.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(DD.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(DD.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(DD.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(DD.LaborCosts) AS LaborCosts,
		|	SUM(DD.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(DD.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DD.LocalCost) AS LocalCost,
		|	SUM(DD.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(DD.PermanentDifference) AS PermanentDifference,
		|	SUM(DD.CostTD) AS CostTD,
		|	SUM(DD.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(DD.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(DD.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(DD.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(DD.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(DD.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(DD.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	DD.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes AS CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	SUM(DD.VATManag) AS VATManag,
		|	SUM(DD.VATLocal) AS VATLocal,
		|	DD.ProductCostElement,
		|	DD.DocumentSource AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	DD.RowCode,
		|	(CASE
		|		WHEN NOT ProductsOfApplication.CDNumber IS NULL
		|			THEN ProductsOfApplication.CDNumber
		|		WHEN NOT CorrectingDiscrepancy.CCDNumber IS NULL
		|			THEN CorrectingDiscrepancy.CCDNumber
		|		WHEN NOT AdjustmentTypesOfStocks.CCDNumber IS NULL
		|			THEN AdjustmentTypesOfStocks.CCDNumber
		|		ELSE UNDEFINED END) AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN Document.ApplicationForImportationOfGoods.Goods AS ProductsOfApplication
		|		ON ProductsOfApplication.Ref = DD.Recorder
		|		AND ProductsOfApplication.RowID = DD.FinRecordID
		|	LEFT JOIN Document.PurchaseAdjustment.Discrepancies AS CorrectingDiscrepancy
		|		ON CorrectingDiscrepancy.Ref = DD.Recorder
		|		AND CorrectingDiscrepancy.RowID = DD.RowID
		|	LEFT JOIN Document.PurchaseAdjustment.InventoryKinds AS AdjustmentTypesOfStocks
		|		ON AdjustmentTypesOfStocks.Ref = DD.Recorder
		|		AND AdjustmentTypesOfStocks.RowID = DD.RowID
		|WHERE
		|	DD.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.CostAdjustment),
		|		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|	AND DD.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND NOT DD.ReversingEntry
		|GROUP BY
		|	DD.EntryType,
		|	DD.ItemsLocationAttributes.Products,
		|	DD.VATActivityType,
		|	DD.Period,
		|	DD.VariancePeriod,
		|	DD.Recorder,
		|	CASE WHEN DD.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.BusinessOperation,
		|	DD.CorItemsLocationAttributes,
		|	DD.CorAccountingSection,
		|	DD.CorInventoryOwnerAttribute,
		|	DD.CorCompany,
		|	DD.CorGrossInitialCostENT,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Department,
		|	DD.DimensionOfExpenses,
		|	DD.ExpenseItemOfWriteOff,
		|	DD.IncomeItem,
		|	DD.DimensionOfRevenue,
		|	DD.SalePeriod,
		|	DD.AssetAndLiabilityItem,
		|	DD.AssetsLiabilitiesDimension,
		|	DD.DocumentRegisterRecords,
		|	DD.RowID,
		|	DD.RowCode,
		|	(CASE
		|		WHEN NOT ProductsOfApplication.CDNumber IS NULL
		|			THEN ProductsOfApplication.CDNumber
		|		WHEN NOT CorrectingDiscrepancy.CCDNumber IS NULL
		|			THEN CorrectingDiscrepancy.CCDNumber
		|		WHEN NOT AdjustmentTypesOfStocks.CCDNumber IS NULL
		|			THEN AdjustmentTypesOfStocks.CCDNumber
		|		ELSE UNDEFINED END), // CCDNumber
		|	DD.ProductsGroup,
		|	DD.LotVendorAttributesCorr,
		|	DD.CorControllingAttributes,
		|	DD.CorVATActivityTypes,
		|	DD.CorLineOfBusiness,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END), // DocumentVATActivityType
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	DD.ProductCostElement,
		|	DD.DocumentSource,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	DD.CostDefiningMethod,
		|	DD.CostCalculationDate
		|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsOfApplication.UnitOfMeasure",
			"DD.ItemsLocationAttributes.Products"));
	
	Return QueryText;
EndFunction

Function TextOfImplementationOfPastMonths() // uses past implementations 
	Return 
		"SELECT
		|	""TextOfImplementationOfPastMonths"" 	  			 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Previous) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	FALSE											 AS ThisIsReverseTransaction,
		|	0 										  		 AS Priority,
		|	0								  				 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 		 AS Products,
		|	DD.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	DD.Period,
		// The receipt period is determined by the batch date. For an empty batch - the end of the previous period. 
		|	CASE
		|		WHEN Register3.IBDocumentDate IS NOT NULL 
		|			THEN Register3.IBDocumentDate
		// When accounting for FIFO, balances without lots should be written off first.
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		// When accounting for the average, balances without batches should be written off after balances with batches.
		|		ELSE &EndOfPreviousPeriod
		|	END AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	DD.RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	(CASE
		|		WHEN DD.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|			THEN Past.InventoryOwnerAttribute
		|		WHEN Past.CorInventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|			THEN DD.CorInventoryOwnerAttribute
		|		ELSE DD.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType AS VATActivityType,
		|
		|	SUM(DD.Count) AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.EmptyRef) 				AS BusinessOperation,
		|	UNDEFINED															AS PriorityBusinessOperation,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) 		AS CorItemsLocationAttributes,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) 	AS CorAccountingSection,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) 							AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	(CASE
		|		WHEN Past.SalesOrder <> UNDEFINED
		|		 AND DD.SalesOrder = UNDEFINED
		|			THEN Past.SalesOrder
		|		ELSE DD.SalesOrder END)										AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	UNDEFINED 															AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) 			AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	DD.CorVATActivityTypes 												AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	Past.DocumentSource												AS DocumentSource,
		|	UNDEFINED															AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	DD.LotCalculationPerformed													AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN PastImplementations AS Past
		|		ON DD.Recorder = Past.DocumentSalesOfGoodsAndServices
		|		AND DD.ItemsLocationAttributes = Past.ItemsLocationAttributes
		|		AND (DD.InventoryOwnerAttribute = Past.InventoryOwnerAttribute
		|			OR DD.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef))
		|	LEFT JOIN RegisterOfDocumentsBalanceOfBatchesOfPastImplementations AS Register3
		|		ON Register3.Ref = DD.Lot
		|WHERE
		|	DD.Organization IN (&CompanyArray)
		|	AND DD.Period < &BeginOfPeriod
		|	AND DD.Active
		|	AND NOT DD.CalculationOfCost
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND DD.Period < &DateOfMigrationToBatchAccounting22)
		|	AND NOT DD.ReversingEntry
		|
		|GROUP BY
		|	DD.ItemsLocationAttributes.Products,
		|	DD.LotVendorAttributes.VATTaxation,
		|	DD.Period,
		|	CASE
		|		WHEN Register3.IBDocumentDate IS NOT NULL 
		|			THEN Register3.IBDocumentDate
		|		WHEN DD.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		|		ELSE &EndOfPreviousPeriod
		|	END, // ReceiptPeriod
		|	DD.VariancePeriod,
		|	DD.Recorder,
		|	DD.RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	(CASE
		|		WHEN DD.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|			THEN Past.InventoryOwnerAttribute
		|		WHEN Past.CorInventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
		|			THEN DD.CorInventoryOwnerAttribute
		|		ELSE DD.InventoryOwnerAttribute END), // InventoryOwnerAttribute
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.CorVATActivityTypes,
		|	Past.DocumentSource,
		|	DD.LotCalculationPerformed,
		|	(CASE
		|		WHEN Past.SalesOrder <> UNDEFINED
		|		 AND DD.SalesOrder = UNDEFINED
		|			THEN Past.SalesOrder
		|		ELSE DD.SalesOrder END) // SalesOrder
		|";
EndFunction

Function TextReportsOfCommissionAgentsOfPreviousMonths() // uses the return of the source document 
	Return 
		"SELECT
		|	""TextReportsOfCommissionAgentsOfPreviousMonths"" 	  	 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Previous) AS EntryType,
		|	FALSE											 AS ThisIsExactlyCalculatedMovement,
		|	FALSE											 AS ThisIsReverseTransaction,
		|	0 										  		 AS Priority,
		|	0								  				 AS Denominator,
		|	TRUE 											 AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 		 AS Products,
		|	DD.LotVendorAttributes.VATTaxation 		 AS TaxationOfParty,
		|
		|	MAX(DD.Period) AS Period,
		|	MAX(DD.Period) AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS VariancePeriod,
		|	DD.Recorder AS Recorder,
		|	DD.RecordType,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	(CASE
		|		WHEN DD.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|			THEN Past.InventoryOwnerAttribute
		|		ELSE DD.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
		|	DD.Organization,
		|	DD.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|
		|	SUM(DD.Count) AS Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.EmptyRef) 				AS BusinessOperation,
		|	UNDEFINED															AS PriorityBusinessOperation,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) 		AS CorItemsLocationAttributes,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) 	AS CorAccountingSection,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) 							AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.Companies.EmptyRef) 							AS CorCompany,
		|	CAST(0 AS NUMBER(31,2)) 											AS CorGrossInitialCostENT,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) 		AS AccountingDimensionByPartners,
		|	UNDEFINED 															AS SalesOrder,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) 					AS Department,
		|	UNDEFINED 															AS DimensionOfExpenses,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) 			AS ExpenseItemOfWriteOff,
		|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) 			AS IncomeItem,
		|	UNDEFINED 															AS DimensionOfRevenue,
		|	DATETIME(1, 1, 1) 														AS SalePeriod,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) 	AS AssetAndLiabilityItem,
		|	UNDEFINED 															AS AssetsLiabilitiesDimension,
		|	UNDEFINED 															AS DocumentRegisterRecords,
		|	CAST("""" AS STRING(36)) 											AS RowID,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	UNDEFINED 															AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) 			AS LotVendorAttributesCorr,
		|	UNDEFINED 															AS CorControllingAttributes,
		|	DD.CorVATActivityTypes 												AS CorVATActivityTypes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) 				AS DocumentVATActivityType,
		|	DD.VATActivityTypeShipments 											AS VATActivityTypeShipments,
		|	UNDEFINED 															AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED 															AS CostAccountingTransaction,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATManag,
		|	CAST(0 AS NUMBER(31,2)) 											AS VATLocal,
		|	UNDEFINED															AS ProductCostElement,
		|	UNDEFINED															AS DocumentSource,
		|	UNDEFINED															AS PrioritySource,
		|	UNDEFINED															AS CorLineOfBusiness,
		|	UNDEFINED															AS RowCode,
		|	UNDEFINED															AS CCDNumber,
		|	UNDEFINED															AS BusinessTransactionSetting,
		|	UNDEFINED															AS FinRecordID,
		|	UNDEFINED															AS GLAccountSettings,
		|	FALSE																	AS ReversingEntry,
		|	DD.LotCalculationPerformed													AS LotCalculationPerformed,
		|	UNDEFINED															AS MonthEndClosingMode,
		|	UNDEFINED															AS CostDefiningMethod,
		|	DATETIME(1,1,1)														AS CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN ReturnsWithoutSourceDocument AS Past
		|		ON Past.Organization = DD.Organization
		|		AND Past.AccountingSection = DD.AccountingSection
		|		AND Past.ItemsLocationAttributes = DD.ItemsLocationAttributes
		|		AND (Past.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
		|			OR DD.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef))
		|WHERE
		|	DD.Organization IN (&CompanyArray)
		|	AND DD.Period < &BeginOfPeriod
		|	AND DD.Active
		|	AND NOT DD.CalculationOfCost
		|	AND DD.EntryType IN ( VALUE(Enum.LotRecordTypes.Consumption),
		// Within the framework of one document, the report of the Commissionaire can be the sale and return of goods by identical measurements.
		|		VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument))
		|	AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND DD.Period < &DateOfMigrationToBatchAccounting22)
		|	AND NOT DD.ReversingEntry
		|
		|GROUP BY
		|	DD.ItemsLocationAttributes.Products,
		|	DD.LotVendorAttributes.VATTaxation,
		|	DD.RecordType,
		|	DD.Recorder,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	(CASE
		|		WHEN DD.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|			THEN Past.InventoryOwnerAttribute
		|		ELSE DD.InventoryOwnerAttribute END),
		|	DD.Organization,
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.VATActivityTypeShipments,
		|	DD.CorVATActivityTypes,
		|	DD.LotCalculationPerformed
		|
		|HAVING
		// We take only those reports of the commission agent whose shipment quantity is greater than 0.
		|	SUM(DD.Count) > 0
		|";
EndFunction

Function TextOfCorrectedDocumentsOfCurPeriod() // uses corrected documents
	
	// Filling in the fields must correspond to the Batch Accountserver function.Search Query texts():
	// Registrar, Period, type of record, document source, Koranalitikauchetanomenclature, Corvidzapas
	QueryText = " 
		|SELECT
		|	""TextOfCorrectedDocumentsOfCurPeriod"" AS RequestSource,
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN VALUE(Enum.LotRecordTypes.Supplement)
		// To return the goods from the customer, we leave the current types of records
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|		 AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|			THEN RegisterData.EntryType
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn)
		// Incoming traffic
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			THEN VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			THEN VALUE(Enum.LotRecordTypes.Lot)
		|
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN VALUE(Enum.LotRecordTypes.AdditionalExpensesReverseTransaction)
		|
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN VALUE(Enum.LotRecordTypes.CurrentPeriodCorrections)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.OfficialTypeOfMovementParish
		|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		// Expendable movements
		// There is a separate rule for the sale of goods between organizations and sale without transfer of ownership
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|		 										   VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN VALUE(Enum.LotRecordTypes.ReversingEntry)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|			THEN VALUE(Enum.LotRecordTypes.ReverseOfCostAllocationToOtherLots)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot)
		|			THEN VALUE(Enum.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot)
		|
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.ReversingEntry),
		|				VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction))
		|			THEN VALUE(Enum.LotRecordTypes.ReturnReverseTransaction)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
		|			THEN VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction)
		|
		|		ELSE RegisterData.EntryType END) AS EntryType,
		|	FALSE AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN RegisterData.Count > 0 THEN TRUE
		|		ELSE FALSE END) AS ThisIsReverseTransaction,
		|	(CASE
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|		 AND RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse),
		|				VALUE(Enum.LotRecordTypes.Move))
		|			THEN 90 
		|		ELSE 0 END)                                   AS Priority,
		|	0                     								 AS Denominator,
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|		 AND RegisterData.Count < 0
		|			THEN TRUE
		|		WHEN RegisterData.OfficialTypeOfMovementParish AND RegisterData.Count = 0
		|			THEN TRUE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost),
		|		 		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|		 		VALUE(Enum.LotRecordTypes.CostAdjustment))
		|			THEN TRUE		
		|		ELSE FALSE END)                                AS CalculationIsCompleted,
		|	RegisterData.ItemsLocationAttributes.Products           AS Products,
		|	UNDEFINED                                                     AS TaxationOfParty,
		|
		|	CorrectedDocuments_.Period,
		|	(CASE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost),
		|		 		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|		 		VALUE(Enum.LotRecordTypes.CostAdjustment))
		|			THEN DATETIME(1,1,1)
		// The adjustment of the acquisition of the current period should be worked out before other receivers.
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN &BeginOfPeriod
		// Sources for receivers with the record type Ostatoxgrouped must first be distributed to storno documents.
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.ReversingEntry),
		|				VALUE(Enum.LotRecordTypes.PreviousPeriodReturn),
		|				VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn),
		|				VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument))
		|			THEN &BeginOfPeriod
		|		ELSE RegisterData.Period END) AS ReceiptPeriod,
		|	RegisterData.VariancePeriod AS VariancePeriod,
		|	CorrectedDocuments_.Recorder,
		|	(CASE
		|		WHEN RegisterData.OfficialTypeOfMovementParish THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense) END) AS RecordType,
		|	RegisterData.ItemsLocationAttributes,
		|	RegisterData.AccountingSection,
		|	RegisterData.InventoryOwnerAttribute,
		|	RegisterData.Organization,
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN RegisterData.Lot
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified)
		|		 AND RegisterData.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND RegisterData.Lot = UNDEFINED
		|			THEN RegisterData.DocumentSource
		|		WHEN RegisterData.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Lot),
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|			VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
		|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|			VALUE(Enum.LotRecordTypes.CostAdjustment),
		|			VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN RegisterData.Lot
		|		WHEN RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			AND RegisterData.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|		THEN RegisterData.Lot
		|		ELSE UNDEFINED END) AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN RegisterData.LotVendorAttributes
		|		WHEN RegisterData.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Lot),
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|			VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
		|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|			VALUE(Enum.LotRecordTypes.CostAdjustment),
		|			VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN RegisterData.LotVendorAttributes
		|		ELSE UNDEFINED END) AS LotVendorAttributes,
		|	RegisterData.FinancialAccountingDimension,
		|	(CASE
		|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.TransferOfGoodsToBailee)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.ReceiptOfGoodsFromCustodian)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		ELSE RegisterData.VATActivityType END) AS VATActivityType,
		|
		|	-SUM(RegisterData.Count) AS Count,
		|	-SUM(RegisterData.Cost) AS Cost,
		|	-SUM(RegisterData.CostExcludingVAT) AS CostExcludingVAT,
		|	-SUM(RegisterData.OffBalanceCost) AS OffBalanceCost,
		|	-SUM(RegisterData.CostMan) AS CostMan,
		|	-SUM(RegisterData.AddExpensesMan) AS AddExpensesMan,
		|	-SUM(RegisterData.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	-SUM(RegisterData.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	-SUM(RegisterData.LaborCostsMan) AS LaborCostsMan,
		|	-SUM(RegisterData.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	-SUM(RegisterData.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	-SUM(RegisterData.AddExpensesForGoods) AS AddExpensesForGoods,
		|	-SUM(RegisterData.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	-SUM(RegisterData.LaborCosts) AS LaborCosts,
		|	-SUM(RegisterData.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	-SUM(RegisterData.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	-SUM(RegisterData.LocalCost) AS LocalCost,
		|	-SUM(RegisterData.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	-SUM(RegisterData.PermanentDifference) AS PermanentDifference,
		|	-SUM(RegisterData.CostTD) AS CostTD,
		|	-SUM(RegisterData.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	-SUM(RegisterData.AddExpensesLocal) AS AddExpensesLocal,
		|	-SUM(RegisterData.LaborCostsLocal) AS LaborCostsLocal,
		|	-SUM(RegisterData.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	-SUM(RegisterData.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	-SUM(RegisterData.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	-SUM(RegisterData.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	RegisterData.BusinessOperation,
		// The filling in of the Priority Economic Operation field should be the same in the functions:
		// -
		// - The text of the current turnover of the Party goods() - The text of the movement of the corrected documents of the current period() - The text of the movement of the corrected documents of the previous period()
		// 
		|	(CASE
		|		WHEN RegisterData.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN UNDEFINED
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots))
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND RegisterData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		ELSE UNDEFINED END) AS PriorityBusinessOperation,
		|	RegisterData.CorItemsLocationAttributes,
		|	RegisterData.CorAccountingSection,
		|	RegisterData.CorInventoryOwnerAttribute,
		|	RegisterData.CorCompany,
		|	RegisterData.CorGrossInitialCostENT,
		|	RegisterData.AccountingDimensionByPartners,
		|	RegisterData.SalesOrder,
		|	RegisterData.Department,
		|	RegisterData.DimensionOfExpenses,
		|	RegisterData.ExpenseItemOfWriteOff,
		|	RegisterData.IncomeItem,
		|	RegisterData.DimensionOfRevenue,
		|	RegisterData.SalePeriod,
		|	RegisterData.AssetAndLiabilityItem,
		|	RegisterData.AssetsLiabilitiesDimension,
		|	RegisterData.DocumentRegisterRecords,
		|	RegisterData.RowID,
		|	RegisterData.ProductsGroup,
		// Filling in the Corporate Party and Corporate Party account fields must match the request for textcurrent turnover of Party products().
		|	(CASE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN UNDEFINED
		|		WHEN RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND (RegisterData.CorLot <> RegisterData.Recorder
		|			OR RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToProduction))
		|		 AND RegisterData.EntryType <> VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|		 AND RegisterData.CorItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|			THEN UNDEFINED
		|		WHEN RegisterData.CorLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE RegisterData.CorLot END) AS CorLot,
		|	(CASE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN UNDEFINED
		|		WHEN RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND (RegisterData.CorLot <> RegisterData.Recorder
		|			OR RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToProduction))
		|		 AND RegisterData.EntryType <> VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|			THEN UNDEFINED
		|		ELSE RegisterData.LotVendorAttributesCorr END) AS LotVendorAttributesCorr,
		|	RegisterData.CorControllingAttributes,
		|	RegisterData.CorVATActivityTypes,
		|	(CASE
		|		WHEN NOT RegisterData.OfficialTypeOfMovementParish 
		|			AND ISNULL(CorBatchProduction.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN CorBatchProduction.VATActivityType
		|		WHEN RegisterData.AccountingSection IN (&OffBalanceSheetAccountingSections) THEN UNDEFINED
		|		WHEN CorrectedDocuments_.Recorder REFS Document.ReversingEntry
		|				AND RegisterData.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN RegisterData.DocumentVATActivityType
		|		WHEN RegisterData.OfficialTypeOfMovementParish THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE RegisterData.CorVATActivityTypes END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	(CASE
		|		WHEN RegisterData.OfficialTypeOfMovementParish THEN UNDEFINED
		|		ELSE RegisterData.FinancialAccountingDimensionOfDocument END) AS FinancialAccountingDimensionOfDocument,
		|	RegisterData.CostAccountingTransaction,
		|	-SUM(RegisterData.VATManag) AS VATManag,
		|	-SUM(RegisterData.VATLocal) AS VATLocal,
		|	RegisterData.ProductCostElement,
		|	(CASE
		// There is a separate rule for the sale of goods between organizations and sale without transfer of ownership
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|		 										   VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN RegisterData.Recorder
		//	When reversing the return of goods from the client of the previous period, the document source is filled in with the implementation document
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|		 AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN RegisterData.DocumentSource
		|
		|		WHEN RegisterData.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Consumption),
		|			VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot))
		|		 AND RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND NOT RegisterData.OfficialTypeOfMovementParish
		|			THEN CorrectedDocuments_.Recorder
		// When the additional expenses are reversed with the specified batch, the document source is filled in with the batch (from the original source document)
		// This is necessary to build a chain of additional expenses by the party <- stornodoprasdov
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN RegisterData.DocumentSource
		|
		|		ELSE RegisterData.Recorder END) AS DocumentSource,
		|	(CASE
		|		WHEN RegisterData.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN RegisterData.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|		 AND VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE RegisterData.Recorder END) AS PrioritySource,
		|	RegisterData.CorLineOfBusiness,
		|	RegisterData.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	RegisterData.BusinessTransactionSetting,
		|	RegisterData.FinRecordID,
		|	RegisterData.GLAccountSettings,
		|	TRUE AS ReversingEntry,
		|	RegisterData.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	RegisterData.CostDefiningMethod,
		|	RegisterData.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS RegisterData
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON RegisterData.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = RegisterData.Recorder
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = RegisterData.Recorder
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = RegisterData.Recorder
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations_
		|		ON RegisterData.Organization = AccountingPoliciesOfOrganizations_.Organization
		|	LEFT JOIN Catalog.ProductionLots AS CorBatchProduction
		|		ON CorBatchProduction.Ref = RegisterData.CorLot
		|WHERE
		|	NOT RegisterData.CalculationOfCost
		|	AND NOT RegisterData.LotCalculation
		|	AND NOT RegisterData.ReversingEntry
		|	AND (&InvoicingOfDeliveries AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		OR NOT &InvoicingOfDeliveries AND RegisterData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|
		|GROUP BY
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN VALUE(Enum.LotRecordTypes.Supplement)
		// To return the goods from the customer, we leave the current types of records
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|		 AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|			THEN RegisterData.EntryType
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn)
		// Incoming traffic
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			THEN VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			THEN VALUE(Enum.LotRecordTypes.Lot)
		|
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN VALUE(Enum.LotRecordTypes.AdditionalExpensesReverseTransaction)
		|
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN VALUE(Enum.LotRecordTypes.CurrentPeriodCorrections)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.OfficialTypeOfMovementParish
		|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		// Expendable movements
		// There is a separate rule for the sale of goods between organizations and sale without transfer of ownership
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|		 										   VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN VALUE(Enum.LotRecordTypes.ReversingEntry)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|			THEN VALUE(Enum.LotRecordTypes.ReverseOfCostAllocationToOtherLots)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot)
		|			THEN VALUE(Enum.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot)
		|
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.ReversingEntry),
		|				VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction))
		|			THEN VALUE(Enum.LotRecordTypes.ReturnReverseTransaction)
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
		|			THEN VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction)
		|
		|		ELSE RegisterData.EntryType END), // EntryType
		|	(CASE
		|		WHEN RegisterData.Count > 0 THEN TRUE
		|		ELSE FALSE END), // ThisIsReverseTransaction
		|	(CASE
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|		 AND RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse),
		|				VALUE(Enum.LotRecordTypes.Move))
		|			THEN 90 
		|		ELSE 0 END), // Priority
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|		 AND RegisterData.Count < 0
		|			THEN TRUE
		|		WHEN RegisterData.OfficialTypeOfMovementParish AND RegisterData.Count = 0
		|			THEN TRUE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost),
		|		 		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment))
		|			THEN TRUE		
		|		ELSE FALSE END), // CalculationIsCompleted
		|	RegisterData.ItemsLocationAttributes.Products,
		|	RegisterData.Period,
		|	(CASE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost),
		|		 		VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment))
		|			THEN DATETIME(1,1,1)
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN &BeginOfPeriod
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.ReversingEntry),
		|				VALUE(Enum.LotRecordTypes.PreviousPeriodReturn),
		|				VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn),
		|				VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument))
	 	|			THEN &BeginOfPeriod
		|		ELSE RegisterData.Period END), // ReceiptPeriod
		|	CorrectedDocuments_.Period,
		|	RegisterData.VariancePeriod,
		|	CorrectedDocuments_.Recorder,
		|	(CASE
		|		WHEN RegisterData.OfficialTypeOfMovementParish THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense) END),
		|	RegisterData.ItemsLocationAttributes,
		|	RegisterData.AccountingSection,
		|	RegisterData.InventoryOwnerAttribute,
		|	RegisterData.Organization,
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN RegisterData.Lot
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified)
		|		 AND RegisterData.Organization IN (&SFIFOOrganizationsSliding)
		|		 AND RegisterData.Lot = UNDEFINED
		|			THEN RegisterData.DocumentSource
		|		WHEN RegisterData.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Lot),
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|			VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
		|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|			VALUE(Enum.LotRecordTypes.CostAdjustment),
		|			VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN RegisterData.Lot
		|		WHEN RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			AND RegisterData.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
		|		THEN RegisterData.Lot
		|		ELSE UNDEFINED END), // Lot
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN RegisterData.LotVendorAttributes
		|		WHEN RegisterData.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Lot),
		|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|			VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
		|			VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|			VALUE(Enum.LotRecordTypes.CostAdjustment),
		|			VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN RegisterData.LotVendorAttributes
		|		ELSE UNDEFINED END),
		|	RegisterData.FinancialAccountingDimension,
		|	(CASE
		|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.TransferOfGoodsToBailee)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.ReceiptOfGoodsFromCustodian)
		|			THEN AccountingPoliciesOfOrganizations_.DefaultVATTaxation
		|		ELSE RegisterData.VATActivityType END), // VATActivityType
		|	RegisterData.BusinessOperation,
		|	(CASE
		|		WHEN RegisterData.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN UNDEFINED
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots))
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND RegisterData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		ELSE UNDEFINED END), // PriorityBusinessOperation
		|	RegisterData.CorItemsLocationAttributes,
		|	RegisterData.CorAccountingSection,
		|	RegisterData.CorInventoryOwnerAttribute,
		|	RegisterData.CorCompany,
		|	RegisterData.CorGrossInitialCostENT,
		|	RegisterData.AccountingDimensionByPartners,
		|	RegisterData.SalesOrder,
		|	RegisterData.Department,
		|	RegisterData.DimensionOfExpenses,
		|	RegisterData.ExpenseItemOfWriteOff,
		|	RegisterData.IncomeItem,
		|	RegisterData.DimensionOfRevenue,
		|	RegisterData.SalePeriod,
		|	RegisterData.AssetAndLiabilityItem,
		|	RegisterData.AssetsLiabilitiesDimension,
		|	RegisterData.DocumentRegisterRecords,
		|	RegisterData.RowID,
		|	RegisterData.ProductsGroup,
		|	(CASE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN UNDEFINED
		|		WHEN RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND (RegisterData.CorLot <> RegisterData.Recorder
		|			OR RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToProduction))
		|		 AND RegisterData.EntryType <> VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|		 AND RegisterData.CorItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|			THEN UNDEFINED
		|		WHEN RegisterData.CorLot = VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE RegisterData.CorLot END), // CorLot
		|	(CASE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN UNDEFINED
		|		WHEN RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND (RegisterData.CorLot <> RegisterData.Recorder
		|			OR RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToProduction))
		|		 AND RegisterData.EntryType <> VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|			THEN UNDEFINED
		|		ELSE RegisterData.LotVendorAttributesCorr END), // LotVendorAttributesCorr
		|	RegisterData.CorControllingAttributes,
		|	RegisterData.CorVATActivityTypes,
		|	RegisterData.OfficialTypeOfMovementParish,
		|	CorBatchProduction.VATActivityType,
		|	(CASE
		|		WHEN NOT RegisterData.OfficialTypeOfMovementParish
		|			AND ISNULL(CorBatchProduction.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
		|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN CorBatchProduction.VATActivityType
		|		WHEN RegisterData.AccountingSection IN (&OffBalanceSheetAccountingSections) THEN UNDEFINED
		|		WHEN CorrectedDocuments_.Recorder REFS Document.ReversingEntry
		|				AND RegisterData.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN RegisterData.DocumentVATActivityType
		|		WHEN RegisterData.OfficialTypeOfMovementParish THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE RegisterData.CorVATActivityTypes END),
		|	(CASE
		|		WHEN RegisterData.OfficialTypeOfMovementParish THEN UNDEFINED
		|		ELSE RegisterData.FinancialAccountingDimensionOfDocument END), // FinancialAccountingDimensionOfDocument
		|	RegisterData.CostAccountingTransaction,
		|	RegisterData.ProductCostElement,
		|	(CASE
		// There is a separate rule for the sale of goods between organizations and sale without transfer of ownership
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|		 										   VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|			THEN RegisterData.Recorder
		//	When reversing the return of goods from the client of the previous period, the document source is filled in with the implementation document
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|		 AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN RegisterData.DocumentSource
		|
		|		WHEN RegisterData.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.Consumption),
		|			VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot))
		|		 AND RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND NOT RegisterData.OfficialTypeOfMovementParish
		|			THEN CorrectedDocuments_.Recorder
		// When the additional expenses are reversed with the specified batch, the document source is filled in with the batch (from the original source document)
		// This is necessary to build a chain of additional expenses by the party <- stornodoprasdov
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN RegisterData.DocumentSource
		|
		|		ELSE RegisterData.Recorder END), // DocumentSource
		|	(CASE
		|		WHEN RegisterData.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN RegisterData.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|		 AND VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE RegisterData.Recorder END), // PrioritySource
		|	RegisterData.CorLineOfBusiness,
		|	RegisterData.RowCode,
		|	RegisterData.BusinessTransactionSetting,
		|	RegisterData.FinRecordID,
		|	RegisterData.GLAccountSettings,
		|	RegisterData.LotCalculationPerformed,
		|	RegisterData.CostDefiningMethod,
		|	RegisterData.CostCalculationDate
		|";
	Return QueryText;
EndFunction

Function TextOfReverseMovementOfCorrectedDocumentsOfPastPeriod() // uses corrected documents
	
	// Filling in the fields must correspond to the functions See BatchAccountingServer.TextsOfCancellationRequests
	// See CostCalculationCostAdjustment.AdjustCostOfReverseCorrectedDocuments() and
	// () 
// Fields: Registrar, Period, Record Type, Document Source
	Return " 
		|SELECT
		|	""TextOfReverseMovementOfCorrectedDocumentsOfPastPeriod""        AS RequestSource,
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.CostAllocationToProductionLots)
		|			THEN VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			THEN VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn)
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|		WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		    AND RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|			THEN VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|		WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND NOT RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 OR RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			THEN VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		// For the reverse document, the Purchase of goods and services for the invoice of delivery, the type of record is supplemented,
		// because for the purposes of distributing batches, it is necessary to create a record with the cost taking into account the calculated deviations in cost.
		// Such movements are formed in the Text Movement function of the corrected documents of the invoices and deliveries().
		// Conditions for filling in the record type, the addition must meet the conditions for data sampling in this function.
		|		WHEN RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND VALUETYPE(RegisterData.Recorder) = TYPE(Document.VendorInvoice)
		|			THEN VALUE(Enum.LotRecordTypes.Supplement)
		|		ELSE VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections) END) AS EntryType,
		|	FALSE                                                 AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN RegisterData.Count > 0 THEN TRUE
		|		ELSE FALSE END)                                AS ThisIsReverseTransaction,
		|	0                                                    AS Priority,
		|	0                                                    AS Denominator,
		|	(CASE
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|		 OR RegisterData.EntryType = VALUE(Enum.LotRecordTypes.CostAllocationToProductionLots)
		|			THEN TRUE
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
		|		 AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN TRUE
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
		|		 AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|			THEN TRUE
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN TRUE
		|		WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt) AND RegisterData.Count = 0
		|			THEN TRUE
		|		WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND NOT RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 OR RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			THEN FALSE
		|		ELSE TRUE END)                              AS CalculationIsCompleted,
		|	RegisterData.ItemsLocationAttributes.Products AS Products,
		|	CASE
		|		WHEN RegisterData.Organization IN (&SFIFOOrganizationsSliding)
		|			OR VALUETYPE(RegisterData.Lot) = TYPE(Catalog.ProductionLots)
		|			OR RegisterData.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		THEN RegisterData.LotVendorAttributes.VATTaxation
		|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
		|	END AS TaxationOfParty,
		|
		|	CorrectedDocuments_.Period,
		|	(CASE
		|		WHEN NOT Register3.IBDocumentDate IS NULL THEN Register3.IBDocumentDate
		|		WHEN RegisterData.Organization IN (&SFIFOOrganizationsSliding) THEN DATETIME(1,1,1)
		|		ELSE &EndOfPreviousPeriod END)            AS ReceiptPeriod,
		|	RegisterData.VariancePeriod AS VariancePeriod,
		|	CorrectedDocuments_.Recorder,
		|	RegisterData.RecordType,
		|	RegisterData.ItemsLocationAttributes,
		|	RegisterData.AccountingSection,
		|	RegisterData.InventoryOwnerAttribute,
		|	RegisterData.Organization,
		|	CASE
		|		WHEN RegisterData.Lot <> UNDEFINED
		|		 AND (RegisterData.Organization IN (&SFIFOOrganizationsSliding)
		|			OR VALUETYPE(RegisterData.Lot) = TYPE(Catalog.ProductionLots)
		|			OR RegisterData.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)))
		|			THEN RegisterData.Lot
		// For the planned cost of the issue, we keep the original Lot reference, because for this record the Lot reference will not be selected.
		|		WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|			THEN RegisterData.Lot
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND RegisterData.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN RegisterData.Recorder
		|		ELSE UNDEFINED
		|	END AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	CASE
		|		WHEN RegisterData.Organization IN (&SFIFOOrganizationsSliding)
		|			OR RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|			OR VALUETYPE(RegisterData.Lot) = TYPE(Catalog.ProductionLots)
		|			OR RegisterData.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		THEN RegisterData.LotVendorAttributes
		|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|	END AS LotVendorAttributes,
		|	RegisterData.FinancialAccountingDimension,
		|	RegisterData.VATActivityType,
		|
		|	-RegisterData.Count,
		|	-RegisterData.Cost,
		|	-RegisterData.CostExcludingVAT,
		|	-RegisterData.OffBalanceCost,
		|	-RegisterData.CostMan,
		|	-RegisterData.AddExpensesMan,
		|	-RegisterData.ItemizedVariableCostsIncludingVAT,
		|	-RegisterData.ItemizedVariableCostsExcludingVAT,
		|	-RegisterData.LaborCostsMan,
		|	-RegisterData.ItemizedFixedCostsManag,
		|	-RegisterData.ItemizedVariableCostsManag,
		|	-RegisterData.AddExpensesForGoods,
		|	-RegisterData.AdditionalExpensesExcludingVAT,
		|	-RegisterData.LaborCosts,
		|	-RegisterData.ItemizedFixedCostsIncludingVAT,
		|	-RegisterData.ItemizedFixedCostsExcludingVAT,
		|	-RegisterData.LocalCost,
		|	-RegisterData.OffBalanceCostLocal,
		|	-RegisterData.PermanentDifference,
		|	-RegisterData.CostTD,
		|	-RegisterData.CostOfPersonalIncomeTax,
		|	-RegisterData.AddExpensesLocal,
		|	-RegisterData.LaborCostsLocal,
		|	-RegisterData.ItemizedFixedCostsCompl,
		|	-RegisterData.ItemizedVariableCostsCompl,
		|	-RegisterData.ProvisionForImpairmentLocal,
		|	-RegisterData.ProvisionForImpairmentMan,
		|
		|	RegisterData.BusinessOperation,
		// The filling in of the Priority Economic Operation field should be the same in the functions:
		// -
		// - The text of the current turnover of the Party goods() - The text of the movement of the corrected documents of the current period() - The text of the movement of the corrected documents of the previous period()
		// 
		|	(CASE
		|		WHEN RegisterData.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN UNDEFINED
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.Move),
		|				VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots))
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.MaterialTransferToProduction)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		 AND RegisterData.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
		|				VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		ELSE UNDEFINED END) AS PriorityBusinessOperation,
		|	RegisterData.CorItemsLocationAttributes,
		|	RegisterData.CorAccountingSection,
		|	RegisterData.CorInventoryOwnerAttribute,
		|	RegisterData.CorCompany,
		|	RegisterData.CorGrossInitialCostENT,
		|	RegisterData.AccountingDimensionByPartners,
		|	RegisterData.SalesOrder,
		|	RegisterData.Department,
		|	RegisterData.DimensionOfExpenses,
		|	RegisterData.ExpenseItemOfWriteOff,
		|	RegisterData.IncomeItem,
		|	RegisterData.DimensionOfRevenue,
		|	RegisterData.SalePeriod,
		|	RegisterData.AssetAndLiabilityItem,
		|	RegisterData.AssetsLiabilitiesDimension,
		|	RegisterData.DocumentRegisterRecords,
		|	RegisterData.RowID,
		|	RegisterData.ProductsGroup,
		|	RegisterData.CorLot,
		|	RegisterData.LotVendorAttributesCorr,
		|	RegisterData.CorControllingAttributes,
		|	RegisterData.CorVATActivityTypes,
		|	RegisterData.DocumentVATActivityType,
		|	RegisterData.VATActivityTypeShipments,
		|	RegisterData.FinancialAccountingDimensionOfDocument,
		|	RegisterData.CostAccountingTransaction,
		|	-RegisterData.VATManag,
		|	-RegisterData.VATLocal,
		|	RegisterData.ProductCostElement,
		|	(CASE
		// When correcting cost adjustment records, the document source is filled in with the original source document.
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.CostAdjustment)
		|			THEN RegisterData.DocumentSource
		|		ELSE RegisterData.Recorder END) AS DocumentSource,
		|	(CASE
		|		WHEN RegisterData.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
		|		 AND VALUETYPE(UninvoicedReceipt.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN UninvoicedReceipt.ReferenceOrder
		|		WHEN RegisterData.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|		 AND VALUETYPE(ReceiptOfServices.ReferenceOrder) = TYPE(Document.PurchaseOrder)
		|			THEN ReceiptOfServices.ReferenceOrder
		|		ELSE CorrectedDocuments_.Recorder END) AS PrioritySource,
		|	RegisterData.CorLineOfBusiness,
		|	RegisterData.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	RegisterData.BusinessTransactionSetting,
		|	RegisterData.FinRecordID,
		|	RegisterData.GLAccountSettings,
		|	TRUE AS ReversingEntry,
		|	RegisterData.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	RegisterData.CostDefiningMethod,
		|	RegisterData.CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS RegisterData
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON RegisterData.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	
		|	INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = RegisterData.Recorder
		|
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON Register3.Ref = RegisterData.Lot
		|		AND NOT Register3.AdditionalRecord
		|		AND RegisterData.Lot <> UNDEFINED
		|	LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS UninvoicedReceipt
		|		ON UninvoicedReceipt.Ref = RegisterData.Recorder
		|	LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServices
		|		ON ReceiptOfServices.Ref = RegisterData.Recorder
		|WHERE
		|	RegisterData.Organization IN (&CompanyArray)
		|	AND RegisterData.Period < &BeginOfPeriod
		|	AND RegisterData.Active
		|	AND NOT RegisterData.CalculationOfCost
		|	AND (NOT RegisterData.LotCalculation
		|		OR RegisterData.EntryType = VALUE(Enum.LotRecordTypes.CostAllocationToProductionLots))
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND RegisterData.Period < &DateOfMigrationToBatchAccounting22)
		|	AND NOT RegisterData.ReversingEntry
		|	AND (&InvoicingOfDeliveries AND RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		OR NOT &InvoicingOfDeliveries AND RegisterData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|";
EndFunction

Function TextOfMovementWithSelectedParties()
	Return "
		|SELECT
		|	""TextOfMovementWithSelectedParties"" 						AS RequestSource,
		|	T.EntryType 												AS EntryType,
		|	FALSE														AS ThisIsExactlyCalculatedMovement,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END)										AS ThisIsReverseTransaction,
		|	10															AS Priority,
		|	0 															AS Denominator,
		|	TRUE 														AS CalculationIsCompleted,
		|	Dimension.Products										AS Products,
		|	UNDEFINED												AS TaxationOfParty,
		|
		|	T.Period AS Period,
		|	T.Period AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	SUM(T.Count) AS Count,
		|	SUM(T.Cost) AS Cost,
		|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(T.OffBalanceCost) AS OffBalanceCost,
		|	SUM(T.CostMan) AS CostMan,
		|	SUM(T.AddExpensesMan) AS AddExpensesMan,
		|	SUM(T.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(T.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(T.LaborCostsMan) AS LaborCostsMan,
		|	SUM(T.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(T.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(T.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(T.LaborCosts) AS LaborCosts,
		|	SUM(T.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(T.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(T.LocalCost) AS LocalCost,
		|	SUM(T.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(T.PermanentDifference) AS PermanentDifference,
		|	SUM(T.CostTD) AS CostTD,
		|	SUM(T.CostOfPersonalIncomeTax) AS CostOfPersonalIncomeTax,
		|	SUM(T.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(T.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(T.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(T.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(T.ProvisionForImpairmentLocal) AS ProvisionForImpairmentLocal,
		|	SUM(T.ProvisionForImpairmentMan) AS ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.Lot
		|		ELSE T.CorLot END) AS CorLot,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.LotVendorAttributes
		|		ELSE T.LotVendorAttributesCorr END) AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	T.DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	T.LotCalculationPerformed,
		|	T.MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|WHERE
		|	T.Count <> 0
		|	AND T.LotCalculationPerformed
		|	AND NOT T.ReversingEntry
		|	AND (&InvoicingOfDeliveries AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		OR NOT &InvoicingOfDeliveries AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|	AND NOT &RestoreChronologicalSequenceOfDebitingBatches
		|
		|GROUP BY
		|	T.EntryType,
		|	(CASE
		|		WHEN T.Count < 0 THEN TRUE
		|		ELSE FALSE END), // ThisIsReverseTransaction
		|	Dimension.Products,
		|	T.Period,
		|	T.VariancePeriod,
		|	T.Recorder,
		|	CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE VALUE(AccumulationRecordType.Expense)
		|	END, // RecordType
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.BusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.Lot
		|		ELSE T.CorLot END), // CorLot
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.LotVendorAttributes
		|		ELSE T.LotVendorAttributesCorr END), // LotVendorAttributesCorr
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	T.DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	T.LotCalculationPerformed,
		|	T.MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|";
EndFunction

Function TextAdjustmentOfCostOfInventoryRecordedAtDisposalOfFA()
	Return "
		|SELECT
		|	""TextAdjustmentOfCostOfInventoryRecordedAtDisposalOfFA"" AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Supplement) AS EntryType,
		|	FALSE AS ThisIsExactlyCalculatedMovement,
		|	FALSE AS ThisIsReverseTransaction,
		|	10 AS Priority,
		|	0 AS Denominator,
		|	TRUE AS CalculationIsCompleted,
		|	Dimension.Products AS Products,
		|	UNDEFINED AS TaxationOfParty,
		|
		|	T.Period AS Period,
		|	T.Period AS ReceiptPeriod,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	0 AS Count,
		|	OtherExpenses.Sum AS Cost,
		|	OtherExpenses.AmountExcludingVAT AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	OtherExpenses.SumMan AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	OtherExpenses.SumCompl AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	OtherExpenses.PermanentDifference AS PermanentDifference,
		|	OtherExpenses.CostTD AS CostTD,
		|	OtherExpenses.AITAmount AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets) AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.Lot
		|		ELSE T.CorLot END) AS CorLot,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|		 AND T.Organization IN (&SFIFOOrganizationsSliding)
		|			THEN T.LotVendorAttributes
		|		ELSE T.LotVendorAttributesCorr END) AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	T.DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	T.CorLineOfBusiness,
		|	T.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	VALUE(Catalog.BusinessTransactionsSettings.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets) AS BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	TRUE AS LotCalculationPerformed,
		|	&MonthEndClosingMode AS MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = T.ItemsLocationAttributes
		|	INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
		|		ON OtherExpenses.Recorder = T.Recorder
		|		AND OtherExpenses.Period = T.Period
		|		AND OtherExpenses.FinRecordID = T.FinRecordID
		|WHERE
		|	T.Count <> 0
		|	AND T.OfficialTypeOfMovementParish
		|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived)
		|	AND T.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.RegistrationAtFADisposal)
		|	AND NOT T.ReversingEntry
		|	AND OtherExpenses.BusinessOperation = VALUE(Enum.BusinessTransactions.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets)
		|";
EndFunction

Function TextTTInvoiceOfDeliveries()
	
	QueryText = 
		"SELECT
		|	""TextTTInvoiceOfDeliveries"" AS RequestSource,
		|	T.EntryType,
		|	T.ThisIsExactlyCalculatedMovement,
		|	T.ThisIsReverseTransaction,
		|	10 AS Priority,
		|	T.Denominator,
		|	TRUE AS CalculationIsCompleted,
		|	T.Products,
		|	T.TaxationOfParty,
		|	T.Period,
		|	T.ReceiptPeriod,
		|	T.VariancePeriod,
		|	T.Recorder,
		|	T.RecordType,
		|
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.ProductionOrder,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|
		|	T.Count,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.OffBalanceCost,
		|	T.CostMan,
		|	T.AddExpensesMan,
		|	T.ItemizedVariableCostsIncludingVAT,
		|	T.ItemizedVariableCostsExcludingVAT,
		|	T.LaborCostsMan,
		|	T.ItemizedFixedCostsManag,
		|	T.ItemizedVariableCostsManag,
		|	T.AddExpensesForGoods,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.LaborCosts,
		|	T.ItemizedFixedCostsIncludingVAT,
		|	T.ItemizedFixedCostsExcludingVAT,
		|	T.LocalCost,
		|	T.OffBalanceCostLocal,
		|	T.PermanentDifference,
		|	T.CostTD,
		|	T.CostOfPersonalIncomeTax,
		|	T.AddExpensesLocal,
		|	T.LaborCostsLocal,
		|	T.ItemizedFixedCostsCompl,
		|	T.ItemizedVariableCostsCompl,
		|	T.ProvisionForImpairmentLocal,
		|	T.ProvisionForImpairmentMan,
		|
		|	T.BusinessOperation,
		|	T.PriorityBusinessOperation,
		|	T.CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorCompany,
		|	T.CorGrossInitialCostENT,
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.Department,
		|	T.DimensionOfExpenses,
		|	T.ExpenseItemOfWriteOff,
		|	T.IncomeItem,
		|	T.DimensionOfRevenue,
		|	T.SalePeriod,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.DocumentRegisterRecords,
		|	T.RowID,
		|	T.ProductsGroup,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|	T.DocumentVATActivityType,
		|	T.VATActivityTypeShipments,
		|	T.FinancialAccountingDimensionOfDocument,
		|	T.CostAccountingTransaction,
		|	T.VATManag,
		|	T.VATLocal,
		|	T.ProductCostElement,
		|	T.DocumentSource,
		|	T.PrioritySource,
		|	T.CorLineOfBusiness,
		|	UNDEFINED AS CCDNumber,
		|	T.RowCode,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.GLAccountSettings,
		|	T.ReversingEntry,
		|	T.LotCalculationPerformed,
		|	T.MonthEndClosingMode,
		|	T.CostDefiningMethod,
		|	T.CostCalculationDate
		|FROM
		|	TTInvoicingOfDeliveries AS T
		|";

	Return QueryText;
	
EndFunction

Function TextCurProductReleases()
	Return 
		"SELECT
		|	""TextCurProductReleases"" 	      				AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.ProductionIssue) 		AS EntryType,
		|	FALSE													AS ThisIsExactlyCalculatedMovement,
		|	FALSE													AS ThisIsReverseTransaction,
		|	99 										  				AS Priority,
		|	0 										  				AS Denominator,
		|	FALSE 													AS CalculationIsCompleted,
		|	VALUE(Catalog.Products.EmptyRef) 			AS Products,
		|	UNDEFINED                              				AS TaxationOfParty,
		|
		|	DD.Period,
		|	DD.Period AS ReceiptPeriod,
		|	DD.VariancePeriod AS VariancePeriod,
		|	DD.Recorder,
		|	UNDEFINED AS RecordType,
		|	UNDEFINED AS ItemsLocationAttributes,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	UNDEFINED AS InventoryOwnerAttribute,
		|	DD.Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	UNDEFINED AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	UNDEFINED AS VATActivityType,
		|
		|	DD.Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	DD.AccountingSection AS CorAccountingSection,
		|	DD.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	AnalyticsGiver.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS DocumentRegisterRecords,
		|	"""" AS RowID,
		|	UNDEFINED AS ProductsGroup,
		|	DD.Lot AS CorLot,
		|	DD.LotVendorAttributes AS LotVendorAttributesCorr,
		|	DD.FinancialAccountingDimension AS CorControllingAttributes,
		|	DD.VATActivityType AS CorVATActivityTypes,
		|	(CASE
		|		WHEN DD.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DD.DocumentVATActivityType
		|		ELSE DD.VATActivityType END) AS DocumentVATActivityType,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityTypeShipments,
		|	DD.FinancialAccountingDimensionOfDocument,
		|	DD.CostAccountingTransaction,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	DD.CorLineOfBusiness,
		|	UNDEFINED AS RowCode,
		|	UNDEFINED AS CCDNumber,
		|	DD.BusinessTransactionSetting,
		|	DD.FinRecordID,
		|	DD.GLAccountSettings,
		|	DD.ReversingEntry,
		|	DD.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	UNDEFINED AS CostDefiningMethod,
		|	DATETIME(1,1,1) AS CostCalculationDate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON DD.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = DD.ItemsLocationAttributes
		|	LEFT JOIN TTAccountingAnalyticsForPartnersFromGiverReports AS AnalyticsGiver
		|		ON AnalyticsGiver.Recorder = DD.Recorder
		|WHERE
		|	DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ProductsRelease),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
		|	AND NOT DD.ReversingEntry
		|";
EndFunction

// Filling out the payment batch

Procedure FillInEstimatedBatchCostOfGoods(CalculationParameters, SettlementBatch, Expense, Receipt)
	
	GoodsInTransitAccountingSections = New Array;
	GoodsInTransitAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransit);
	GoodsInTransitAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent);
	GoodsInTransitAccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent);
	
	ThisIsRealizationOfGoodsInTransit = GoodsInTransitAccountingSections.Find(Expense.AccountingSection) <> Undefined
		And (Expense.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Expense.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit);
	
	If (Expense.EntryType = Enums.LotRecordTypes.CostAllocationToProductionLots
			Or Expense.EntryType = Enums.LotRecordTypes.Allocation)
	 And Not ValueIsFilled(Expense.ProductionOrder)
	 And ValueIsFilled(Expense.AccountingSection)
	 And Expense.AccountingSection <> Receipt.AccountingSection Then
		Return;
	
	// For an additional expenses reflected in the customs declaration for import exclude sources other than import purchases.
	ElsIf (Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsNotSpecified
	 Or Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified)
	 And Receipt.EntryType <> Enums.LotRecordTypes.AdditionalExpensesReverseTransaction
	 And ValueIsFilled(Receipt.BusinessOperation)
	 And Receipt.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
	 And Receipt.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
	 And Receipt.BusinessOperation <> Enums.BusinessTransactions.PurchaseByImport
	 And Receipt.BusinessOperation <> Enums.BusinessTransactions.ImportGoodsInTransit Then
		Return;
		
	// To adjust the purchase, a batch corresponding to the adjusted purchase must be selected,
	// except for unfactured deliveries, because for unfactured deliveries 
	// , the invoice document is indicated in the purchase adjustment, not the batch document.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
	 And Expense.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries
	 And ValueIsFilled(Receipt.Lot)
	 And ValueIsFilled(Expense.Lot)
	 And Receipt.Lot <> Expense.Lot
	 And (Receipt.DocumentSource <> Expense.Lot
	 	Or Expense.ReversingEntry) Then
		Return;
		
	// To reverse the Registered Records, we check the compliance of the source and receiver batch accounting analytics.	
	ElsIf Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
	 And Expense.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries
	 And Expense.ReversingEntry
	 And ValueIsFilled(Receipt.LotVendorAttributes)
	 And ValueIsFilled(Expense.LotVendorAttributes)
	 And Receipt.LotVendorAttributes <> Expense.LotVendorAttributes Then
		Return;
		
	// When accounting for the average cost for the adjustment of the acquisition, we select the source corresponding to the period of the document being corrected.
	// To adjust the acquisition of the Cur period, sources of only the Cur period can be selected,
	// except for unfactated deliveries, because for unfactated deliveries 
	// , the invoice document is indicated in the purchase adjustment, not the batch document. 
	ElsIf Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
	 And Expense.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries
	 And Not ValueIsFilled(Expense.Lot)
	 And Expense.ReceiptPeriod >= CalculationParameters.PayrollPeriod.BeginOfPeriod
	 And Receipt.Period < CalculationParameters.PayrollPeriod.BeginOfPeriod Then
	 	Return;
		
	// For a return without a source document, the return of goods from a commission agent cannot be a source.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.ReturnWithoutSourceDocument
	 And Receipt.EntryType = Enums.LotRecordTypes.Consumption
	 And Receipt.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Return;
	 
	ElsIf ValueIsFilled(Expense.Recorder)
		And Expense.Recorder = Receipt.DocumentSource
		And Receipt.EntryType <> Enums.LotRecordTypes.ReversingEntry
		And Receipt.EntryType <> Enums.LotRecordTypes.AdditionalExpensesReverseTransaction
		And Expense.EntryType <> Enums.LotRecordTypes.ReversingEntry
		And Receipt.EntryType <> Enums.LotRecordTypes.ReturnWithoutSourceDocument
		And Receipt.EntryType <> Enums.LotRecordTypes.GroupedStock
		And Not Expense.Recorder = Receipt.Recorder Then
		Return;
		
	// For the record type "Write-Off Of The Balance Without A Batch", only a source with blank batch accounting analytics should be selected.
	// The batch from such a source is filled with the value of the priority batch for selection.
	// For such a source, There Will Not Be Enough Balances Of Goods in Transit from suppliers.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.WriteOffOfBalanceWithoutLot
	 And ValueIsFilled(Receipt.LotVendorAttributes) Then
		Return;
	
	// The receipt of goods in transit should pick up only the Balance/adjustment for the same purchase document.
	// In addition to the batches formed by the acquisition adjustment with the type of adjustment "Adjustment by agreement of the parties",
	// such adjustments form new batches.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.Consumption
		And (Receipt.EntryType = Enums.LotRecordTypes.Balance
			Or Receipt.EntryType = Enums.LotRecordTypes.PreviousPeriodCorrections)
		And Receipt.AccountingSection = Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors
		And Expense.AccountingSection = Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors
		And TypeOf(Receipt.Lot) <> Type("DocumentRef.PurchaseAdjustment")
		And ValueIsFilled(Receipt.Lot)
		And ValueIsFilled(Expense.Lot)
		And Receipt.Lot <> Expense.Lot Then
			Return;
	
	// The credit note of the previous period, if there are other credit note of the same document in the current period.
	// The source cannot be the expense document itself.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.PreviousPeriodReturn
		And (Receipt.EntryType = Enums.LotRecordTypes.Consumption)
		And Receipt.Recorder = Expense.Recorder
		And TypeOf(Expense.Recorder) = Type("DocumentRef.SaleAdjustment") Then
			Return;
	
	// The expense of goods in transit should pick up a batch from the same sales document that the arrival was made with.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.Consumption
		And Receipt.AccountingSection = Expense.AccountingSection
		And ThisIsRealizationOfGoodsInTransit
		And TypeOf(Receipt.Recorder) = Type("DocumentRef.CustomerInvoice")
		And TypeOf(Expense.Recorder) = Type("DocumentRef.CustomerInvoice")
		And Receipt.Recorder <> Expense.Recorder Then
		Return;
			
	// Source "Sales (goods in transit)" first of all, the "Move" should be written off to the receiver.
	// In this case, the "Denominator" field will decrease to zero.
	// For a refund from a customer or an adjustment of sales (goods in transit), this source will be selected
	// after the denominator is equal to 0.
	ElsIf TypeOf(Receipt.Recorder) = Type("DocumentRef.CustomerInvoice")
	 And Receipt.CorAccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsInTransit
	 And Receipt.Recorder <> Expense.Recorder
	 And Receipt.Denominator = Receipt.Count Then
	 	Return;
	 	
	// For the return of goods to the supplier, either a batch corresponding to the purchase of goods specified in the return to the supplier,
	// or a batch with a similar type of VAT, 
	// except for unfactated deliveries, can be selected, because for unfactated deliveries, the invoice document is indicated in the purchase adjustment 
	// , not the batch document.
	ElsIf Expense.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor
	 And Expense.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries
	 And ValueIsFilled(Expense.VATActivityType)
	 And ValueIsFilled(Receipt.VATActivityType)
	 And ValueIsFilled(Expense.Lot)
	 And ValueIsFilled(Receipt.Lot)
	 And Expense.Lot <> Receipt.Lot
	 And Expense.VATActivityType <> Receipt.VATActivityType Then
	 	Return;
	 	
	// For the return of goods to the supplier, a source with a similar type of VAT may be selected
	// if the purchase of goods was made using the "Monthly Average" cost estimation method.
	ElsIf Expense.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor
	 And Expense.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries
	 And ValueIsFilled(Expense.VATActivityType)
	 And ValueIsFilled(Receipt.VATActivityType)
	 And Not ValueIsFilled(Receipt.Lot)
	 And Expense.VATActivityType <> Receipt.VATActivityType Then
	 	Return;
	 	
	// For the source and receiver with the specified CCD numbers, we check the correspondence of the CCD number.
	ElsIf ValueIsFilled(Expense.CCDNumber)
	 And ValueIsFilled(Receipt.CCDNumber)
	 And Expense.CCDNumber <> Receipt.CCDNumber Then
	 	Return;
	 	
	// For a receiver with an empty CCD number, we skip the source with the CCD number filled in.
	ElsIf (Expense.EntryType = Enums.LotRecordTypes.CostAdjustment
		Or Expense.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod)
	 And Not ValueIsFilled(Expense.CCDNumber)
	 And ValueIsFilled(Receipt.CCDNumber) Then
	 	Return;
	
	// For corrective documents, only the Lot reference Of the corrected document can serve as a source.
	// If there is no such Lot reference, the unassembled Lot Reference will be corrected by the Lot Reference re-sorting mechanism.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer
	 And Not (Receipt.Lot = Expense.Lot And Receipt.LotVendorAttributes = Expense.LotVendorAttributes) Then
		Return;
		
	// To adjust the purchase of the previous period, there may be several sources - lines of the document for the purchase of goods
	// with different costs. If the negative cost of the adjustment is greater than the cost in the line of the purchase document, 
	// then this means that the adjustment belongs to another line and the current source should be ignored.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod
	 And Receipt.EntryType = Enums.LotRecordTypes.Previous
	 And ValueIsFilled(Expense.Lot)
	 And ValueIsFilled(Receipt.Lot)
	 And (Expense.AddExpensesForGoods < 0 And -Expense.AddExpensesForGoods > Receipt.Cost
	 Or Expense.AdditionalExpensesExcludingVAT < 0 And -Expense.AdditionalExpensesExcludingVAT > Receipt.CostExcludingVAT
	 Or Expense.AddExpensesMan < 0 And -Expense.AddExpensesMan > Receipt.CostMan
	 Or Expense.AddExpensesLocal < 0 And -Expense.AddExpensesLocal > Receipt.LocalCost) Then
		Return;
		
	// For a source of "Reverse consumption" with a household operation "Report to the giver (2.5)", the receiver can only be "Moving"
	// according to the same document.
	ElsIf Receipt.EntryType = Enums.LotRecordTypes.ConsumptionReverseTransaction
	 And Receipt.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
	 And Expense.Recorder <> Receipt.Recorder Then
		Return;
		
	ElsIf Receipt.EntryType = Enums.LotRecordTypes.PreviousPeriodReturn
	 And Receipt.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod
	 And Expense.EntryType <> Enums.LotRecordTypes.ReverseOfPreviousPeriodsReturn
	 And Expense.Recorder <> Undefined
	 And Expense.Recorder <> Receipt.Recorder Then
		Return;
		
	ElsIf Expense.EntryType = Enums.LotRecordTypes.PreviousPeriodReturn
	 And Receipt.EntryType = Enums.LotRecordTypes.Previous
	 And Expense.DocumentSource <> Receipt.DocumentSource Then
	 	Return;
		
	// For a receiver with a household account operation "Reverse write-off for expenses", the receiver can only be the registrar
	// specified in the source document.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.PreviousPeriodReturn
	 And Expense.BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction
	 And Expense.DocumentSource <> Receipt.Recorder Then
		Return;
		
	EndIf;
	
	SumResourcesByString = 
	"Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
	|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
	|LocalCost, PermanentDifference, CostTD, CostOfPersonalIncomeTax,
	|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
	|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
	|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal, ItemizedFixedCostsCompl, ItemizedVariableCostsCompl";
	SummaryResources = New Structure(SumResourcesByString);
	TotalVATResources = New Structure("VATLocal, VATManag");
	
	// When accounting by average, when the goods arrive from the goods accounting section en route to the warehouse accounting section, the batch in the warehouse becomes empty.
	// As a result, if a correction document or a reverse is entered for such a receipt document,
	// then the batch in the corrective Registered Records for the section of goods in transit is not selected, because it is obtained from the warehouse accounting section (where it is empty).
	// For such a situation, in the Register Records for the warehouse section of accounting, we will save the batch of goods purchased in the Party field,
	// and then, when correcting Register Records for the goods section en route, we will return it to the Batch field.
	ThisIsAdjustmentOfGoodsInTransitByAverage = 
		((TypeOf(Receipt.Recorder) = Type("DocumentRef.ReceiptOfGoodsToWarehouse")
			And (TypeOf(Expense.Recorder) = Type("DocumentRef.ReceiptOfGoodsToWarehouse")
				Or TypeOf(Expense.Recorder) = Type("DocumentRef.ReversingEntry")
				And TypeOf(Expense.DocumentSource) = Type("DocumentRef.ReceiptOfGoodsToWarehouse")))
			Or (TypeOf(Receipt.Recorder) = Type("DocumentRef.ReversingEntry")
				And Receipt.Recorder = Expense.Recorder
				And Expense.AccountingSection = Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
	 	And (Expense.EntryType = Enums.LotRecordTypes.CurrentPeriodCorrections
	 		Or Expense.EntryType = Enums.LotRecordTypes.ReversingEntry)
		And CalculationParameters.AccountingPolicies.FIFOSliding.UsedInCurPeriod.Find(SettlementBatch.Organization) = Undefined;
	
	// We fill out the settlement batch according to the expenditure batch-the basis
	FillPropertyValues(SettlementBatch, Expense);
	
	//	We fill in the batch identification in the settlement batch
	If Not ThisIsRealizationOfGoodsInTransit Then
		
		FillPropertyValues(SettlementBatch, Receipt, "Lot, LotVendorAttributes, TaxationOfParty, FinancialAccountingDimension, ReceiptPeriod, ProductionOrder");
		
		If ValueIsFilled(SettlementBatch.CorLot)
			And GoodsInTransitAccountingSections.Find(Expense.CorAccountingSection) <> Undefined
			And TypeOf(SettlementBatch.CorLot) = Type("DocumentRef.CustomerInvoice") Then
			SettlementBatch.LotVendorAttributesCorr = SettlementBatch.LotVendorAttributes;
		EndIf;
		
		// When receiving goods in transit from suppliers, the receipt period is filled in taking into account the date of the customs declaration,
		// because when distributing batches in the section "Own goods in transit (from suppliers)" the date of the customs declaration is not taken into account.
		If SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors
		 And SettlementBatch.BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit Then
			SettlementBatch.ReceiptPeriod = SettlementBatch.Period;
		EndIf;
		
	ElsIf CalculationParameters.AccountingPolicies.FIFOSliding.UsedInCurPeriod.Find(SettlementBatch.Organization) <> Undefined Then
		
		SettlementBatch.LotVendorAttributes = Receipt.LotVendorAttributes;
		
		If SettlementBatch.RecordType = AccumulationRecordType.Receipt Then
			SettlementBatch.Lot = ?(SettlementBatch.ReversingEntry, SettlementBatch.DocumentSource, SettlementBatch.Recorder);
		EndIf;
	
	EndIf;
	
	If False Then
	ElsIf SettlementBatch.RecordType = AccumulationRecordType.Receipt
	 And Not SettlementBatch.ReversingEntry
	 And Not ThisIsRealizationOfGoodsInTransit
	 And SettlementBatch.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors
	 And SettlementBatch.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.AddExpensesLotIsSpecified
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.AddExpensesLotIsNotSpecified
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.PurchaseAdjustment
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.DebitNoteForPreviousPeriod
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.CostAdjustment
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.IncludeVATInCostExpenses
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.IncludeExciseInCost
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.GroupedStock
	 And CalculationParameters.AccountingPolicies.FIFOSliding.UsedInCurPeriod.Find(SettlementBatch.Organization) = Undefined Then
		SettlementBatch.Lot = Undefined;
		SettlementBatch.LotVendorAttributes = Undefined;
	EndIf;
	
	If ThisIsAdjustmentOfGoodsInTransitByAverage Then
		If Expense.AccountingSection = Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors Then
			SettlementBatch.Lot = Receipt.CorLot;
			SettlementBatch.LotVendorAttributes = Receipt.LotVendorAttributesCorr;
		Else
			SettlementBatch.CorLot = Receipt.CorLot;
			SettlementBatch.LotVendorAttributesCorr = Receipt.LotVendorAttributesCorr;
		EndIf;
	EndIf;
	
	If SettlementBatch.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod
	Or SettlementBatch.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified
	Or SettlementBatch.EntryType = Enums.LotRecordTypes.IncludeVATInCostExpenses
	Or SettlementBatch.EntryType = Enums.LotRecordTypes.IncludeExciseInCost
	Or SettlementBatch.EntryType = Enums.LotRecordTypes.CostAdjustment Then
		// The document source does not change, you need to save the record as it is
	ElsIf SettlementBatch.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
	 Or SettlementBatch.EntryType = Enums.LotRecordTypes.CorrectPreviousPeriodTransfer
	 Or SettlementBatch.EntryType = Enums.LotRecordTypes.TransferGoodsInTransit And SettlementBatch.ReversingEntry Then 
		// The document source does not change, you need to save the record as it is
	ElsIf SettlementBatch.EntryType = Enums.LotRecordTypes.ProductionIssue
	 Or SettlementBatch.EntryType = Enums.LotRecordTypes.ReverseOfCostAllocationToProductionLots
	 Or Receipt.EntryType = Enums.LotRecordTypes.ReverseOfCostAllocationToProductionLots
	 Or Receipt.EntryType = Enums.LotRecordTypes.GroupedStock Then
		SettlementBatch.DocumentSource = Receipt.DocumentSource;
	Else
		SettlementBatch.DocumentSource = Receipt.Recorder;
	EndIf;
	
	If SettlementBatch.EntryType = Enums.LotRecordTypes.CostAllocationToProductionLots Then
		SettlementBatch.ThisIsReverseTransaction = False;
		SettlementBatch.AccountingDimensionByPartners = Receipt.AccountingDimensionByPartners;
	EndIf;
	
	If SettlementBatch.EntryType = Enums.LotRecordTypes.ProductionIssue Then
		SettlementBatch.RecordType = Receipt.RecordType;
		SettlementBatch.AccountingDimensionByPartners = Receipt.AccountingDimensionByPartners;
	EndIf;
	
	If SettlementBatch.EntryType <> Enums.LotRecordTypes.Move
		And SettlementBatch.EntryType <> Enums.LotRecordTypes.TransferOnAssignmentBasis
		And SettlementBatch.EntryType <> Enums.LotRecordTypes.TransferMan
		And SettlementBatch.EntryType <> Enums.LotRecordTypes.TransferAuto
		And SettlementBatch.EntryType <> Enums.LotRecordTypes.TransferToBalance
		And SettlementBatch.EntryType <> Enums.LotRecordTypes.CurrentPeriodCorrections
		// For a receiver with the record type Reversed and the sign Reversed, the source is the incoming movement of the same document,
		// therefore, such a record should be processed by analogy with incoming movements with the record type Moving in another branch of the condition.
		And Not (SettlementBatch.EntryType = Enums.LotRecordTypes.ReversingEntry And SettlementBatch.ReversingEntry)
		And Not ThisIsRealizationOfGoodsInTransit Then
		
			If SettlementBatch.EntryType <> Enums.LotRecordTypes.PreviousPeriodReturn
				And Not (SettlementBatch.EntryType = Enums.LotRecordTypes.ReversingEntry
				And SettlementBatch.BusinessOperation = Enums.BusinessTransactions.ReverseOfSale
				And Receipt.VATActivityType = Enums.VATTaxationTypes.ByActualUsage)
				Or Not ValueIsFilled(SettlementBatch.VATActivityType) Then
				SettlementBatch.VATActivityType = Receipt.VATActivityType;
			EndIf;
			
			// The Upload Activity type field is used to determine the cost of the refund.
			// The conditions for filling in the Activity type field of the upload should correspond to the conditions for using the field
			// in the procedure for correcting the cost of writing inventory() of the general module for calculating the cost of cost correction.
			If (SettlementBatch.EntryType = Enums.LotRecordTypes.ReversingEntry
				And (SettlementBatch.BusinessOperation = Enums.BusinessTransactions.ReverseOfSale
				Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction))
				Or SettlementBatch.EntryType = Enums.LotRecordTypes.ReturnToAnotherWarehouse
					And (SettlementBatch.BusinessOperation = Enums.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse
					Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse)
				And SettlementBatch.AccountingSection <> Enums.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent Then
					SettlementBatch.VATActivityTypeShipments = Receipt.VATActivityType;
			EndIf;
			
	ElsIf Not ThisIsRealizationOfGoodsInTransit Then
		
		// For the entry type "Move" to the cor. analytics fin. we write accounting analytics for fin. source accounting (which was debited from the warehouse). 
		If SettlementBatch.EntryType = Enums.LotRecordTypes.Move Then
			SettlementBatch.CorControllingAttributes = Receipt.FinancialAccountingDimension;
			
		// For the record type "Correction of the current period" in the cor. analytics fin. accounting write cor. analytics fin. source accounting,
		// so that you can then fill out the fin analytics correctly. Registered Records with the "Reverse" record type.
		ElsIf SettlementBatch.EntryType = Enums.LotRecordTypes.CurrentPeriodCorrections
		 And Receipt.EntryType = Enums.LotRecordTypes.Move Then
		 	SettlementBatch.CorControllingAttributes = Receipt.CorControllingAttributes;
		EndIf;
		
		// When reversing/correcting the movement of goods, financial accounting analytics should always be taken from the source's cor. analytics.
		// In this case, the analytics of the fin. The accounting will correspond to the analytics of the Registered Records of the original document.
		If SettlementBatch.EntryType = Enums.LotRecordTypes.ReversingEntry
		 And Receipt.EntryType = Enums.LotRecordTypes.CurrentPeriodCorrections Then
		 	SettlementBatch.FinancialAccountingDimension = Receipt.CorControllingAttributes;
		ElsIf ValueIsFilled(Receipt.CorControllingAttributes)
		 And SettlementBatch.EntryType <> Enums.LotRecordTypes.CurrentPeriodCorrections Then
			SettlementBatch.FinancialAccountingDimension = Receipt.CorControllingAttributes; 
		Else
			SettlementBatch.FinancialAccountingDimension = Expense.FinancialAccountingDimension;
		EndIf;
		
		If Not ValueIsFilled(SettlementBatch.FinancialAccountingDimension)
			And SettlementBatch.FinancialAccountingDimension <> Undefined Then
			SettlementBatch.FinancialAccountingDimension = Undefined;
		EndIf;
		
		If Not ValueIsFilled(SettlementBatch.CorControllingAttributes)
			And SettlementBatch.CorControllingAttributes <> Undefined Then
			SettlementBatch.CorControllingAttributes = Undefined;
		EndIf;
		
		If ValueIsFilled(Receipt.CorVATActivityTypes) Then
			SettlementBatch.VATActivityType = Receipt.CorVATActivityTypes;
		Else
			SettlementBatch.VATActivityType = Receipt.VATActivityType;
		EndIf;
	EndIf;
	
	If SettlementBatch.RecordType = AccumulationRecordType.Receipt
	 And Receipt.EntryType <> Enums.LotRecordTypes.Import
	 And Expense.EntryType <> Enums.LotRecordTypes.PurchaseAdjustment
	 And Receipt.EntryType <> Enums.LotRecordTypes.ReturnToAnotherWarehouse
	 And Expense.EntryType <> Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction
	 And Not ThisIsRealizationOfGoodsInTransit
	 And Not (Receipt.EntryType = Enums.LotRecordTypes.Previous
	 	 And Expense.EntryType <> Enums.LotRecordTypes.PreviousPeriodReturn) Then
		
	 	If Receipt.EntryType = Enums.LotRecordTypes.Previous
	 	 And Expense.EntryType = Enums.LotRecordTypes.PreviousPeriodReturn Then
			If Receipt.VATActivityType <> Enums.VATTaxationTypes.ByActualUsage Then
				// If the type of activity of VAT in the source was "For actual use",
				// then the refund should be issued for the main type of activity of the organization, 
				// because it is wrong to return for the type of activity "For actual use" from the point of view of VAT accounting,
				// since the "actual use" occurred at the time of disposal of this batch.
				SettlementBatch.VATActivityType = Receipt.VATActivityType;
			EndIf;
			SettlementBatch.CorVATActivityTypes = Receipt.CorVATActivityTypes;
		ElsIf Expense.EntryType = Enums.LotRecordTypes.CurrentPeriodCorrections Then
		 	// When canceling, the types of activities must be taken from the foundation document
			SettlementBatch.VATActivityType = Receipt.VATActivityType;
			SettlementBatch.CorVATActivityTypes = Receipt.CorVATActivityTypes;
		Else
			SettlementBatch.CorVATActivityTypes = Receipt.VATActivityType;
		EndIf;

		SettlementBatch.CorItemsLocationAttributes = Receipt.ItemsLocationAttributes;
		
		If Not ThisIsAdjustmentOfGoodsInTransitByAverage Then
			SettlementBatch.CorLot = Receipt.Lot;
			If SettlementBatch.EntryType <> Enums.LotRecordTypes.PurchaseAdjustment Then
				SettlementBatch.LotVendorAttributesCorr = Receipt.LotVendorAttributes;
			EndIf;
		EndIf;
		
		If ValueIsFilled(Receipt.CorCompany) Then
			SettlementBatch.CorCompany = Receipt.Organization;
		EndIf;
		
	EndIf;
	
	// In the expenditure RegisterRecorded, we will fill in the "Corvide ACTIVITIESINDS" field with the VAT taxation type of the source, 
	// if the VAT taxation type of the document has not been filled in.
	// However, we exclude the "Actual use" of the VAT taxation type of activity when goods are disposed of, 
	// because when a batch with this activity type is disposed of, a change in the VAT taxation type must be made in order to accept VAT for deduction.
	// When writing off to batches of production, the corvide activity is not overfilled, because it must always correspond to the batch of production.
	If SettlementBatch.RecordType = AccumulationRecordType.Expense
	 And Not ThisIsRealizationOfGoodsInTransit
	 And Not ValueIsFilled(SettlementBatch.DocumentVATActivityType)
	 And TypeOf(SettlementBatch.CorLot) <> Type("CatalogRef.ProductionLots")
	 And Not (Receipt.VATActivityType = Enums.VATTaxationTypes.ByActualUsage 
	 		And SettlementBatch.CorAccountingSection = Enums.SectionsOfInventoryCostAccounting.EmptyRef()) Then
		SettlementBatch.CorVATActivityTypes = Receipt.VATActivityType;
	EndIf;
	If TypeOf(Receipt.FinancialAccountingDimension) = Type("CatalogRef.AnalyticalInventoryGroups")
		And SettlementBatch.RecordType = AccumulationRecordType.Expense
		And SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductionCosts
		And (SettlementBatch.CorAccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductionCosts
		) Then
		
		// Transfer between organizations from the point of view of production (work, materials in storerooms) works similarly to external receipt:
		// - by expenditure movements, product groups are written off from the balances,
		// - an empty product group is accounted for.
		If SettlementBatch.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany
		 Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents
		 Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
			SettlementBatch.CorControllingAttributes = Undefined;
		ElsIf Not ValueIsFilled(SettlementBatch.CorControllingAttributes) Then
			SettlementBatch.CorControllingAttributes = Receipt.FinancialAccountingDimension;
		EndIf;
		
	EndIf;
	
	If (ValueIsFilled(SettlementBatch.CorAccountingSection)
		  Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting)
	 And Not ThisIsRealizationOfGoodsInTransit
	 And SettlementBatch.RecordType = AccumulationRecordType.Expense
	 // Additional condition for the batch type.
	 And TypeOf(SettlementBatch.CorLot) <> Type("CatalogRef.ProductionLots")
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.ProductionIssue
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.ExpensesToOtherProductionLots
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.ReverseOfCostAllocationToOtherLots
	 And TypeOf(SettlementBatch.Recorder) <> Type("DocumentRef.InventoryCostCalculation")
	 And SettlementBatch.CorLot <> SettlementBatch.Recorder
	 And Not (SettlementBatch.CorLot = SettlementBatch.DocumentSource And SettlementBatch.ReversingEntry) Then
	 
		// It will work for expenditure movements of a document that meets the following conditions:
		// - the document forms movements both on arrival and on expenditure
		// - its incoming movement does not form a new batch
		// An example of such a document is the movement of goods between warehouses.
		If (CalculationParameters.AccountingPolicies.FIFOSliding.UsedInCurPeriod.Find(SettlementBatch.Organization) = Undefined
				And SettlementBatch.CorAccountingSection <> Enums.SectionsOfInventoryCostAccounting.WorkInProgress)
				And Not ValueIsFilled(SettlementBatch.CorCompany)
		 Or (ValueIsFilled(SettlementBatch.CorCompany)
			  And CalculationParameters.AccountingPolicies.FIFOSliding.UsedInCurPeriod.Find(SettlementBatch.CorCompany) = Undefined) Then
			SettlementBatch.CorLot 				= Undefined;
			SettlementBatch.LotVendorAttributesCorr = Undefined;
		
		// The COR Lot Reference In The expenditure Registered Record Is filled in from the source if:
		// - the Item is moved within the same organization
		// - The Item is transferred to the Branch Office (three Household Operations)
		ElsIf Not ValueIsFilled(SettlementBatch.CorCompany)
		 Or SettlementBatch.CorCompany = SettlementBatch.Organization
		 Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices
		 Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices
		 Or SettlementBatch.BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices Then
			SettlementBatch.CorLot 				= Receipt.Lot;
			SettlementBatch.LotVendorAttributesCorr = Receipt.LotVendorAttributes;
		EndIf;
		
		If Not ValueIsFilled(SettlementBatch.CorInventoryOwnerAttribute) Then
			SettlementBatch.CorInventoryOwnerAttribute = Receipt.InventoryOwnerAttribute;
		EndIf;
		
	EndIf;
	
	// If from one source the quantity needs to be distributed simultaneously to two receivers, then 
	// for the first receiver the distribution should be performed according to the denominator, and for the second receiver according to the quantity.
	// For example, for an implementation with a deferred transfer of ownership, a distribution is performed by denominator 
	// for incoming movements of the implementation document, and a distribution is performed by quantity for adjustment and return documents.
	// In this case, the denominator in the settlement batch must be filled with the amount that was selected
	// In the line of the calculated batch, which in the future will be a source with a distribution by denominator, it is necessary to fill in the denominator.  
	If Receipt.EntryType = Enums.LotRecordTypes.CostAllocationToProductionLots And Expense.EntryType = Enums.LotRecordTypes.ProductionIssue Then
		DistributeAccordingToDenominatorOfParish = True;
	ElsIf ThisIsRealizationOfGoodsInTransit And (Expense.EntryType = Enums.LotRecordTypes.Move Or 
		Expense.EntryType = Enums.LotRecordTypes.TransferGoodsInTransit) Then
			
		DistributeAccordingToDenominatorOfParish = True;
	ElsIf (Expense.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod
		Or Expense.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	 And Expense.EntryType = Enums.LotRecordTypes.Move Then
		DistributeAccordingToDenominatorOfParish = True;
	ElsIf Expense.EntryType = Enums.LotRecordTypes.Move
	 And Receipt.EntryType = Enums.LotRecordTypes.Consumption
	 And Receipt.AccountingSection = Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors Then
		DistributeAccordingToDenominatorOfParish = True;
	Else
		DistributeAccordingToDenominatorOfParish = False;
	EndIf;
	
	If GoodsInTransitAccountingSections.Find(Expense.CorAccountingSection) <> Undefined
		And (Expense.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Expense.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit) Then
		FillInDenominator = True;
	ElsIf (Expense.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod
		Or Expense.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		Or Expense.BusinessOperation = Enums.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	 And (Expense.EntryType = Enums.LotRecordTypes.Consumption
	 Or Expense.EntryType = Enums.LotRecordTypes.ConsumptionReverseTransaction
	 Or Expense.EntryType = Enums.LotRecordTypes.PreviousPeriodReturn) Then
		FillInDenominator = True;
	ElsIf Expense.EntryType = Enums.LotRecordTypes.Consumption
	 And Expense.AccountingSection = Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors Then
		FillInDenominator = True;
	Else
		FillInDenominator = False;
	EndIf;
	
	// the calculated batch is filled with the largest total deductible
	If Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsNotSpecified
	 Or (Expense.EntryType = Enums.LotRecordTypes.CostAdjustment
		And Expense.Denominator <> 0)
	 Or (Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified
		And Expense.Denominator <> 0) Then
	 	
	 	// For reverse additional expenses, the denominator is always equal to the receiver, because reverse is performed for the full amount.
	 	If Receipt.EntryType = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction Then
	 		NumberOfDebits = Expense.Denominator;
			ParishBasis = 0;
	 	Else
			NumberOfDebits = Min(Expense.Denominator, Receipt.Count);
			ParishBasis = ?(Receipt.Count <> 0, NumberOfDebits / Receipt.Count, 0);
		EndIf;
		ConsumptionBasis = ?(Expense.Denominator <> 0, NumberOfDebits / Expense.Denominator, 0);
		
	// The purchase adjustment of the previous period does not have a quantity, so we use the first source completely.
	ElsIf Expense.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod
	 Or Expense.EntryType = Enums.LotRecordTypes.CostAdjustment
	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeVATInCostExpenses
	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost
	 Or Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified Then
	 	// For reverse additional expenses, the denominator is always equal to 1, because reverse is performed for the full amount.
	 	If Receipt.EntryType = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction
	 	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeVATInCostExpenses
	 	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost Then
	 		NumberOfDebits = 1;
	 		ConsumptionBasis = 1;
	 	Else
	 		NumberOfDebits = Receipt.Count;
	 		ConsumptionBasis = ?(Expense.Denominator = 0, 1, NumberOfDebits / Expense.Denominator);
	 	EndIf;
		ParishBasis = 1;
	ElsIf DistributeAccordingToDenominatorOfParish Then
		NumberOfDebits = Min(Expense.Count, Receipt.Denominator);
		ParishBasis = ?(Receipt.Denominator <> 0, NumberOfDebits / Receipt.Denominator, 0);
		ConsumptionBasis = ?(Expense.Count <> 0, NumberOfDebits / Expense.Count, 0);
	Else
		NumberOfDebits = Min(Expense.Count, Receipt.Count);
		ParishBasis = ?(Receipt.Count <> 0, NumberOfDebits / Receipt.Count, 0);
		ConsumptionBasis = ?(Expense.Count <> 0, NumberOfDebits / Expense.Count, 0);
	EndIf;
	
	If NumberOfDebits = 0 Then
		Return;
	EndIf;
	
	// we fill in the indicators of the settlement batch
	If Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsNotSpecified
	 Or Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified
	 Or Expense.EntryType = Enums.LotRecordTypes.CostAdjustment
	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeVATInCostExpenses
	 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost
	 Or Expense.EntryType = Enums.LotRecordTypes.DebitNoteForPreviousPeriod Then
		SettlementBatch.Count = 0;
	ElsIf Receipt.EntryType = Enums.LotRecordTypes.CostAllocationToProductionLots
	 And Expense.EntryType = Enums.LotRecordTypes.ProductionIssue Then
		SettlementBatch.Count = Round(ParishBasis * Receipt.Count, 3);
	Else
		SettlementBatch.Count = Round(NumberOfDebits, 3);
	EndIf;
	
	If FillInDenominator Then
		SettlementBatch.Denominator = SettlementBatch.Count; 
	EndIf;
	
	For Each ResourceName In SummaryResources Do
		SettlementBatch[ResourceName.Key] = Round(ConsumptionBasis * SettlementBatch[ResourceName.Key], 2);
	EndDo;
	For Each ResourceName In TotalVATResources Do
		SettlementBatch[ResourceName.Key] = Round(ConsumptionBasis * SettlementBatch[ResourceName.Key], 2);
	EndDo;
	
	If SettlementBatch.EntryType = Enums.LotRecordTypes.ReturnWithoutSourceDocument
	 And SettlementBatch.BusinessOperation = Enums.BusinessTransactions.ConsignmentReportFromCustomer Then
		SettlementBatch.SalePeriod = Receipt.Period;
	EndIf;
	
	// adjusting the calculation base in the expense
	If SettlementBatch.EntryType <> Enums.LotRecordTypes.ProductionIssue Then
		
		Expense.Count = Expense.Count - SettlementBatch.Count;
		
		If Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsNotSpecified
		 Or Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified
		 Or Expense.EntryType = Enums.LotRecordTypes.IncludeVATInCostExpenses
		 Or Expense.EntryType = Enums.LotRecordTypes.IncludeExciseInCost
		 Or Expense.EntryType = Enums.LotRecordTypes.CostAdjustment Then
			If Expense.Denominator <> 0 Then
				Expense.Denominator = Expense.Denominator - NumberOfDebits;
			EndIf;
		EndIf;
		
		For Each ResourceName In SummaryResources Do
			Expense[ResourceName.Key] = Expense[ResourceName.Key] - SettlementBatch[ResourceName.Key];
		EndDo;
		For Each ResourceName In TotalVATResources Do
			Expense[ResourceName.Key] = Expense[ResourceName.Key] - SettlementBatch[ResourceName.Key];
		EndDo;
		
	EndIf;
	
	// adjusting the calculation base in the parish
	If Not (Receipt.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			And Receipt.EntryType = Enums.LotRecordTypes.Consumption)
	And Not (Receipt.EntryType = Enums.LotRecordTypes.PreviousPeriodCorrections
			And Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
			And Receipt.Recorder = Expense.Recorder)
	// There may be several adjustments for one acquisition document, so there is no need to adjust the database in the source.
	And Expense.EntryType <> Enums.LotRecordTypes.CostAdjustment
	And Expense.EntryType <> Enums.LotRecordTypes.DebitNoteForPreviousPeriod
	And Not (Receipt.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany
			And Receipt.EntryType = Enums.LotRecordTypes.Consumption)
	And Not (Receipt.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod
			And Receipt.EntryType = Enums.LotRecordTypes.PreviousPeriodReturn)
	And Not (Receipt.BusinessOperation = Enums.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse
		And Receipt.EntryType = Enums.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction
		And Expense.EntryType = Enums.LotRecordTypes.ReturnToAnotherWarehouse) 
	And Not (Receipt.BusinessOperation = Enums.BusinessTransactions.AllocationOfExpensesForProductionLots
	  And Receipt.EntryType = Enums.LotRecordTypes.Allocation)
	// For receivers with the recording type of inclusion, the excise value and inclusion of the add value use the same source,
	// so the database does not need to be adjusted.
	And Not Expense.EntryType =  Enums.LotRecordTypes.IncludeExciseInCost 
	And Not Expense.EntryType =  Enums.LotRecordTypes.IncludeVATInCostExpenses Then
		
		If Expense.EntryType = Enums.LotRecordTypes.AddExpensesLotIsNotSpecified Then
		 	If Receipt.EntryType = Enums.LotRecordTypes.AdditionalExpensesReverseTransaction Then
		 		Receipt.Denominator = Receipt.Denominator - NumberOfDebits;
		 	Else
				Receipt.Count = Receipt.Count - NumberOfDebits;
		 	EndIf;
		ElsIf Receipt.EntryType = Enums.LotRecordTypes.CostAllocationToProductionLots
		 And Expense.EntryType = Enums.LotRecordTypes.ProductionIssue Then
			Receipt.Denominator = Receipt.Denominator - NumberOfDebits;
			Receipt.Count = Receipt.Count - SettlementBatch.Count;
		ElsIf DistributeAccordingToDenominatorOfParish Then
			Receipt.Denominator = Receipt.Denominator - NumberOfDebits;
		ElsIf Not Receipt.ThisIsReverseTransaction And SettlementBatch.ThisIsReverseTransaction
		 And SettlementBatch.EntryType = Enums.LotRecordTypes.Consumption Then	
			Receipt.Count = Receipt.Count + SettlementBatch.Count;
		
		// An debit note to reduce the quantity should reduce the quantitative and cost indicators at the source.
		// The source and receiver have different signs of quantity or different types of movements.
		ElsIf Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
		 And (Expense.ThisIsReverseTransaction And Not Receipt.ThisIsReverseTransaction
		 Or Not Expense.ThisIsReverseTransaction And Receipt.ThisIsReverseTransaction
		 Or Expense.RecordType <> Receipt.RecordType) Then
			Receipt.Count = Receipt.Count - SettlementBatch.Count;
			For Each ResourceName In SummaryResources Do
				SummaryResources[ResourceName.Key] = Round(ParishBasis * Receipt[ResourceName.Key], 2);
				If Receipt[ResourceName.Key] <> 0 Then
					Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SettlementBatch[ResourceName.Key];
				EndIf;
			EndDo;
			For Each ResourceName In TotalVATResources Do
				If Receipt[ResourceName.Key] <> 0 Then
					Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SettlementBatch[ResourceName.Key];
				EndIf;
			EndDo;
			
		// To debit notes, you need to adjust the quantitative and cost indicators in the source.
		// The source and receiver have the same signs of quantity and the same types of movements.
		ElsIf Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
		 And Expense.RecordType = Receipt.RecordType
		 And (Not Expense.ThisIsReverseTransaction And Not Receipt.ThisIsReverseTransaction
		 Or Expense.ThisIsReverseTransaction And Receipt.ThisIsReverseTransaction) Then
			Receipt.Count = Receipt.Count + SettlementBatch.Count;
			For Each ResourceName In SummaryResources Do
				SummaryResources[ResourceName.Key] = Round(ParishBasis * Receipt[ResourceName.Key], 2);
				Receipt[ResourceName.Key] = Receipt[ResourceName.Key] + SettlementBatch[ResourceName.Key];
			EndDo;
			For Each ResourceName In TotalVATResources Do
				Receipt[ResourceName.Key] = Receipt[ResourceName.Key] + SettlementBatch[ResourceName.Key];
			EndDo;
		Else
			Receipt.Count = Receipt.Count - ?(SettlementBatch.Count = 0, NumberOfDebits,
				SettlementBatch.Count);
			// When adjusting the purchase, it is necessary to adjust the quantitative and cost indicators in the source 
			// if the source is partially used, which means that deviations will not be calculated for the line (see the conditions below after the comment "Deviations in the cost of goods")
			If Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
		 	 And Receipt.Count <> 0
		 	 And Not Expense.ReversingEntry Then // for the reverse, we always calculate deviations, so the reverse does not reduce the sum indicators in the source.
				For Each ResourceName In SummaryResources Do
					Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SettlementBatch[ResourceName.Key];
				EndDo;
				For Each ResourceName In TotalVATResources Do
					Receipt[ResourceName.Key] = Receipt[ResourceName.Key] - SettlementBatch[ResourceName.Key];
				EndDo;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(SettlementBatch.AccountingSection) Then
		SettlementBatch.AccountingSection = Receipt.AccountingSection;
	EndIf;
	
	If Not ValueIsFilled(SettlementBatch.InventoryOwnerAttribute) And ValueIsFilled(Receipt.InventoryOwnerAttribute)
	 And SettlementBatch.EntryType <> Enums.LotRecordTypes.PreviousPeriodReturn
	 Or SettlementBatch.EntryType = Enums.LotRecordTypes.ConsumptionProduction Then
		SettlementBatch.InventoryOwnerAttribute = Receipt.InventoryOwnerAttribute;
	EndIf;
	
	If SettlementBatch.EntryType = Enums.LotRecordTypes.ProductionIssue Then
		
		SettlementBatch.Products = Receipt.Products;
		SettlementBatch.ItemsLocationAttributes = Receipt.ItemsLocationAttributes;
		SettlementBatch.Lot = Receipt.Lot;
		SettlementBatch.LotVendorAttributes = Receipt.LotVendorAttributes;
		SettlementBatch.Department = Receipt.Department;
		SettlementBatch.ProductCostElement = Receipt.ProductCostElement;
		SettlementBatch.RowID = Receipt.RowID;
		SettlementBatch.RowCode = Receipt.RowCode;
		SettlementBatch.ProductsGroup = Receipt.FinancialAccountingDimension;
		
	EndIf;
	
	If SettlementBatch.EntryType <> Enums.LotRecordTypes.ProductionIssue Then
		If SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.WorkInProgress
			Or SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.ProductionCosts Then
			If Receipt.AccountingSection = Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing Then
				SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing;
			ElsIf Receipt.AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping Then
				SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(SettlementBatch.CorItemsLocationAttributes)
			And (SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing
				Or SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping) Then
			SettlementBatch.CorAccountingSection = Enums.SectionsOfInventoryCostAccounting.EmptyRef();
		
		
		EndIf;
	EndIf;
	
	// For the goods transferred to the processor, we fill in the priority source.
	If (SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToToller
	   Or SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners
	   Or SettlementBatch.AccountingSection = Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	 And ValueIsFilled(Receipt.ProductionOrder) Then
	 	SettlementBatch.PrioritySource = Receipt.ProductionOrder; 
	EndIf;
	
	// We will replace the old batch accounting analysts with new ones.
	If CalculationParameters.DistributionOfParties.AdditionalProperties.Property("PartyAccountingAnalysts") Then
		
		PartyAccountingAnalysts = CalculationParameters.DistributionOfParties.AdditionalProperties.PartyAccountingAnalysts; // Map
		
		NewPartyAccountingAnalytics = PartyAccountingAnalysts.Get(SettlementBatch.LotVendorAttributes);
		
		If ValueIsFilled(NewPartyAccountingAnalytics) Then
			SettlementBatch.LotVendorAttributes = NewPartyAccountingAnalytics;
		EndIf;
		
		NewPartyAccountingAnalytics = PartyAccountingAnalysts.Get(SettlementBatch.LotVendorAttributesCorr);
		
		If ValueIsFilled(NewPartyAccountingAnalytics) Then
			SettlementBatch.LotVendorAttributesCorr = NewPartyAccountingAnalytics;
		EndIf;
		
	EndIf;
	
	// The reverse of the write-off for the issue only reduces the amount of write-off for the issue,
	// but the result should not be used in further chains.  
	If SettlementBatch.EntryType = Enums.LotRecordTypes.CostAllocationToProductionLots
	 And Receipt.EntryType = Enums.LotRecordTypes.ReverseOfCostAllocationToProductionLots Then
		SettlementBatch.CalculationIsCompleted = False;
	Else
		// Based on the results of batch identification, we determine the completeness of the calculation
		SettlementBatch.CalculationIsCompleted = Receipt.CalculationIsCompleted;
	EndIf;
	
	// Inclusion or exclusion of VAT in the value of goods for the movements of the customs declaration for import.
	#Region InclusionExclusionOfVAT
	
	If (SettlementBatch.EntryType = Enums.LotRecordTypes.AddExpensesLotIsNotSpecified
	 Or SettlementBatch.EntryType = Enums.LotRecordTypes.AddExpensesLotIsSpecified)
	 And SettlementBatch.VATActivityType <> SettlementBatch.CorVATActivityTypes Then
	 
		InclusionExclusionOfVAT = CostCalculationAppliedAlgorithms.AddSettlementBatch(CalculationParameters);
		FillPropertyValues(InclusionExclusionOfVAT, SettlementBatch,, SumResourcesByString);
		InclusionExclusionOfVAT.EntryType = Enums.LotRecordTypes.InclusionExclusionOfVATInCost;
		
		If CalculationParameters.TypesOfTaxationVATIsIncludedInCost[SettlementBatch.VATActivityType] <> Undefined
		 And CalculationParameters.TypesOfTaxationVATIsNotIncludedInCost[SettlementBatch.CorVATActivityTypes] <> Undefined Then
			InclusionExclusionOfVAT.AddExpensesLocal = SettlementBatch.VATLocal;
			InclusionExclusionOfVAT.AddExpensesMan = ?(CalculationParameters.CompanyManagementAccounting, SettlementBatch.VATManag, 0);
			
		ElsIf CalculationParameters.TypesOfTaxationVATIsNotIncludedInCost[SettlementBatch.VATActivityType] <> Undefined
		 And CalculationParameters.TypesOfTaxationVATIsIncludedInCost[SettlementBatch.CorVATActivityTypes] <> Undefined Then
			InclusionExclusionOfVAT.AddExpensesLocal = -SettlementBatch.VATLocal;
			InclusionExclusionOfVAT.AddExpensesMan = ?(CalculationParameters.CompanyManagementAccounting, -SettlementBatch.VATManag, 0);
		 
		EndIf;
	 
	EndIf;
	
	#EndRegion
	
	// Deviations in the cost of goods.
	#Region DeviationsInCost
	
	// The conditions for calculating deviations in cost must correspond to the procedure for filling in the estimated Delivery Invoice part().
	// To adjust the purchase, we calculate deviations only if the previous period is adjusted to reduce the quantity,
	// if there is a quantitative Balance after the adjustment. 
	// In the current period, the amount of deviations should be taken into account when calculating the cost of goods.
	If Expense.EntryType = Enums.LotRecordTypes.PurchaseAdjustment
		And Receipt.ReceiptPeriod < CalculationParameters.PayrollPeriod.BeginOfPeriod
		And SettlementBatch.ThisIsReverseTransaction
		And Receipt.Count > 0 Then
	 
		BalanceAfterAdjustment = 0;
		For Each ResourceName In SummaryResources Do
			BalanceAfterAdjustment = BalanceAfterAdjustment + Receipt[ResourceName.Key];
		EndDo;
		
		// We will attribute negative deviations in value to other income (if the amount of the adjustment exceeds the amount of the Balance),
		// in order to exclude the occurrence of negative total Balances.  
		If BalanceAfterAdjustment < 0 Then
			Variances = CostCalculationAppliedAlgorithms.AddSettlementBatch(CalculationParameters, SettlementBatch, False);
			Variances.RecordType = AccumulationRecordType.Expense;
			Variances.Count  = 0;
			Variances.EntryType = Enums.LotRecordTypes.CostVarianceForOtherIncome;
			Variances.IncomeItem = ChartsOfCharacteristicTypes.IncomeItems.GoodsValueVariance;
			Variances.DimensionOfRevenue = Expense.Products;
			Variances.ReversingEntry = False;
			Variances.BusinessOperation = Enums.BusinessTransactions.GoodsValueVarianceIncome;
			Variances.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.GoodsValueVarianceIncome;
			If ValueIsFilled(Variances.RowID) Then
				Variances.FinRecordID = Variances.RowID;
			EndIf;
			
			For Each ResourceName In SummaryResources Do
				If SummaryResources[ResourceName.Key] <> 0 Then
					Variances[ResourceName.Key] = -(SettlementBatch[ResourceName.Key] - SummaryResources[ResourceName.Key]);
				EndIf;
			EndDo;
			
		EndIf;
	EndIf;
	
	#EndRegion
	
	If SettlementBatch.CalculationIsCompleted Then
		// At the preliminary closing of the month, the indication of the calculation of batches is set only if there
		// is a completed batch.
		If CalculationParameters.AccountingPolicies.FIFOSliding.UsedInCurPeriod.Find(SettlementBatch.Organization) <> Undefined
		 And CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing
		 And Not ValueIsFilled(SettlementBatch.Lot) Then
			SettlementBatch.LotCalculationPerformed = False;
		Else
			SettlementBatch.LotCalculationPerformed = True;
		EndIf;
		SettlementBatch.MonthEndClosingMode = CalculationParameters.MonthEndClosingMode;
	EndIf;
	
EndProcedure

#EndRegion

#Region StageProcedures_FillingInBatchesInRegisterRevenueAndCostOfSales

// Data Initialization

Function ConsumptionAndRevenueFields(CalculationParameters)
	
	Return "Recorder, ItemsLocationAttributes, InventoryOwnerAttribute, Organization, AccountingSection, AccountingDimensionByPartners, SalesOrder";
	
EndFunction

Function DescriptionOfRevenueChains(CalculationParameters)
	
	DescriptionOfChains = New Map;
	ConsumptionFields	= ConsumptionAndRevenueFields(CalculationParameters);
	
	// Consumption <- (Batch)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.Consumption, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.Consumption,
		Enums.LotRecordTypes.Lot,		ConsumptionFields);
		
	// Consumption is <- (partiid for distribution)
	CostCalculationAppliedAlgorithms.AddReceiverDescription(DescriptionOfChains,
		Enums.LotRecordTypes.ConsumptionLotCalculation, ConsumptionFields);
	CostCalculationAppliedAlgorithms.AddSourceDescription(DescriptionOfChains, Enums.LotRecordTypes.ConsumptionLotCalculation,
		Enums.LotRecordTypes.LotsToAllocate, ConsumptionFields);	
	
	// Addition <- (<without sources - for generating records based on request data>)
	CostCalculationAppliedAlgorithms.AddAddOnDescription(DescriptionOfChains, Enums.LotRecordTypes.Supplement);
	
	Return DescriptionOfChains;
	
EndFunction

Function DescriptionOfRevenueBatchRegisteredRecords(CalculationParameters)
	
	DistributionTableColumns = TableForDistributionOfRevenueBatches(CalculationParameters).Columns;
	
	RegisterRecordsDetails = CostCalculationAppliedAlgorithms.RegisterRecordsDetails();
	RegisterRecordsDetails.Insert("Context", "FillingOfLotsInRegisterRevenueAndCostOfSales");
	RegisterRecordsDetails.Insert("RegisterName", Metadata.AccumulationRegisters.RevenueAndCOGS.Name);
	RegisterRecordsDetails.Insert("CalculationFields", CostCalculationAppliedAlgorithms.ListOfFields(DistributionTableColumns));
	RegisterRecordsDetails.Insert("ComparisonKeys",	ConsumptionAndRevenueFields(CalculationParameters));
	RegisterRecordsDetails.Insert("Indicators", "Count, Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
		|RevenueAmount, RevenueAmountExcludingVAT, RevenueAmountExclVATLocal, RevenueAmountIncludingVATLocal, ManualDiscount, DiscountMarkupAmount,
		|RevenueAmountPD, RevenueAmountTD,
		|LocalCost, PermanentDifference, CostTD,
		|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
		|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
		|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
		|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal,
		|ItemizedFixedCostsCompl, ItemizedVariableCostsCompl,
		|AmountInARAPCurrency, AmountExcludingVATInARAPCurrency, AmountInDocumentCurrency, AmountExcludingVATInDocumentCurrency");
	RegisterRecordsDetails.Insert("BasisOfArrival", "Count");
	RegisterRecordsDetails.Insert("BasisOfConsumption", "Count");
	RegisterRecordsDetails.Insert("OrderField_", "Period");
	RegisterRecordsDetails.Insert("SortFields", "FinRecordID");
	RegisterRecordsDetails.Insert("SortingByCondition", True);
	RegisterRecordsDetails.Insert("ThereIsStorno", True);
	
	Return RegisterRecordsDetails;
	
EndFunction

Function DescriptionOfUnrecordedRevenueBatches(CalculationParameters)
	
	UnrecordedRecordTypes = New Map;
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.Lot, True);
	UnrecordedRecordTypes.Insert(Enums.LotRecordTypes.LotsToAllocate, True);
	
	UnwrittenPartitions = New Map;
	
	Return CostCalculationAppliedAlgorithms.DescriptionOfNonWritableData(True, UnrecordedRecordTypes, UnwrittenPartitions);
	
EndFunction

Function TableForDistributionOfRevenueBatches(CalculationParameters)
	
	Return CostCalculationAppliedAlgorithms.TableForDistributionOfLots(CalculationParameters,
		TextDescriptionOfTheseRevenueBatches());
	
EndFunction

// Sample data

Procedure GetDataForRevenueBatches(CalculationParameters)
	
	NumberingParameters = CostCalculationAppliedAlgorithms.GenerateParametersForNumberingRowsInTemporaryTable(
		"ItemsLocationAttributes", // Separator
		CalculationParameters.DistributionOfParties.RegisterRecordsDetails.Indicators, // Resources
		ConsumptionAndRevenueFields(CalculationParameters)); // Order
	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForRevenueBatches(CalculationParameters),
		NumberingParameters);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForRevenueBatches(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// preparation of temporary tables
		+ TextInitializationOfRevenueBatches()
		+ Common.QueryBatchSeparator()
		// Sample data
		+ TextDescriptionOfTheseRevenueBatches() // w Data
		+ TMCommonUse.QuerySeparatorInJoin() + BatchTextForRevenue()
		+ TMCommonUse.QuerySeparatorInJoin() + BatchTextForRevenueWithoutQuantity()
		+ TMCommonUse.QuerySeparatorInJoin() + TextRevenueWithoutLots()
		+ TMCommonUse.QuerySeparatorInJoin() + TextRevenueWithoutBatchesWithoutQuantity()
		+ TMCommonUse.QuerySeparatorInJoin() + TextRevenueSavedRegisteredRecords()
		+ "";
	
	Return QueryText;
	
EndFunction

// ... data descriptions

Function TextDescriptionOfTheseRevenueBatches()
	
	QueryText = 
		"SELECT TOP 0
		|	CAST("""" AS STRING(80)) 						  AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.EmptyRef) AS EntryType,
		|	FALSE 												  AS CalculationIsCompleted,
		|	T.Period											  AS Period,
		|	T.AdjustmentPeriod_								  AS AdjustmentPeriod_,
		|	T.Recorder										  AS Recorder,
		|	FALSE 												  AS ThisIsReverseTransaction,
		|
		|	VALUE(Catalog.Companies.EmptyRef)		  AS Organization,
		|   T.ItemsLocationAttributes,
		|   T.SalesOrder,
		|   T.AccountingDimensionByPartners,
		|   T.Department,
		|   T.InventoryType,
		|   T.InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   T.Lot,
		|   T.LotVendorAttributes,
		|   T.FinancialAccountingDimension,
		|   T.VATActivityType,
		|   T.Manager,
		|   T.Warehouse,
		|   T.Terms,
		|   T.Contract,
		|   T.BusinessOperation,
		|   T.SetAccountingDimension,
		|   T.CounterpartyLineOfBusiness,
		|   T.ProductLineOfBusiness,
		|
		|   T.Count,
		|   T.RevenueAmount,
		|   T.RevenueAmountExcludingVAT,
		|   T.Cost,
		|   T.CostExcludingVAT,
		|   T.AddExpensesForGoods,
		|   T.AdditionalExpensesExcludingVAT,
		|   T.SellingExpensesIncludingVAT,
		|   T.SellingExpensesExcludingVAT,
		|   T.LocalCost,
		|   T.RevenueAmountExclVATLocal,
		|   T.RevenueAmountPD,
		|   T.RevenueAmountTD,
		|   T.PermanentDifference,
		|   T.CostTD,
		|   T.RevenueAmountIncludingVATLocal,
		|   T.ManualDiscount,
		|   T.DiscountMarkupAmount,
		|   T.OffBalanceCost,
		|   T.LaborCosts,
		|   T.ItemizedFixedCostsIncludingVAT,
		|   T.ItemizedVariableCostsIncludingVAT,
		|   T.ItemizedFixedCostsExcludingVAT,
		|   T.ItemizedVariableCostsExcludingVAT,
		|   T.OffBalanceCostLocal,
		|   T.AddExpensesLocal,
		|   T.SellingExpensesLocal,
		|   T.LaborCostsLocal,
		|   T.ItemizedFixedCostsCompl,
		|   T.ItemizedVariableCostsCompl,
		|   T.CostMan,
		|   T.AddExpensesMan,
		|   T.SellingExpensesMan,
		|   T.LaborCostsMan,
		|   T.ItemizedFixedCostsManag,
		|   T.ItemizedVariableCostsManag,
		|	T.ExciseAmountInCurrencyMgmt,
		|	T.ExciseAmountInCurrencyLocal,
		|
		|   T.VATTaxation,
		|   T.ARAPCurrency,
		|   T.AmountInARAPCurrency,
		|   T.AmountExcludingVATInARAPCurrency,
		|   T.DocumentCurrency,
		|   T.AmountInDocumentCurrency,
		|   T.AmountExcludingVATInDocumentCurrency,
		|   T.SourceOfProductFinancialAccountingGroup,
		|   T.SourceOfARAPFinancialAccountingGroup,
		|   T.DocumentRegisterRecords,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate
		|INTO Data
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|";

	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextInitializationOfRevenueBatches()
	Return "
		|SELECT DISTINCT
		|	InventoryCost.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	InventoryCost.Recorder AS Recorder,
		|	InventoryCost.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	InventoryCost.FinRecordID AS FinRecordID
		|INTO InventoryCostForTTRevenueWithoutBatches
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS InventoryCost
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON InventoryCost.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	InventoryCost.LotCalculationPerformed
		|	AND InventoryCost.CorItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|	AND InventoryCost.CorItemsLocationAttributes <> UNDEFINED
		|	AND InventoryCost.BusinessOperation IN(&ArrayOfOperationsRefundsForPastPeriods)
		|INDEX BY
		|	BusinessTransactionSetting,
		|	Recorder,
		|	FinRecordID,
		|	CorItemsLocationAttributes
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Period,
		|	T.AdjustmentPeriod_,
		|	T.Recorder,
		|	PartnerAnalytics_.Organization AS Organization,
		|	ISNULL(InventoryCost.CorItemsLocationAttributes, T.ItemsLocationAttributes) AS ItemsLocationAttributes,
		|	T.SalesOrder,
		|	T.AccountingDimensionByPartners,
		|	T.Department,
		|	T.InventoryType,
		|	T.InventoryOwnerAttribute,
		|	T.AccountingSection,
		|	T.Manager,
		|	T.Warehouse,
		|	T.Terms,
		|	T.Contract,
		|	T.BusinessOperation,
		|	T.SetAccountingDimension,
		|	T.CounterpartyLineOfBusiness,
		|	T.ProductLineOfBusiness,
		|	T.VATTaxation,
		|	T.ARAPCurrency,
		|	T.DocumentCurrency,
		|	T.SourceOfProductFinancialAccountingGroup,
		|	T.SourceOfARAPFinancialAccountingGroup,
		|	T.DocumentRegisterRecords,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate,
		|
		|	SUM(T.Count) AS Count,
		|	SUM(T.RevenueAmount) AS RevenueAmount,
		|	SUM(T.RevenueAmountExcludingVAT) AS RevenueAmountExcludingVAT,
		|	SUM(T.Cost) AS Cost,
		|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	SUM(T.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(T.SellingExpensesIncludingVAT) AS SellingExpensesIncludingVAT,
		|	SUM(T.SellingExpensesExcludingVAT) AS SellingExpensesExcludingVAT,
		|	SUM(T.LocalCost) AS LocalCost,
		|	SUM(T.RevenueAmountExclVATLocal) AS RevenueAmountExclVATLocal,
		|	SUM(T.RevenueAmountPD) AS RevenueAmountPD,
		|	SUM(T.RevenueAmountTD) AS RevenueAmountTD,
		|	SUM(T.PermanentDifference) AS PermanentDifference,
		|	SUM(T.CostTD) AS CostTD,
		|	SUM(T.RevenueAmountIncludingVATLocal) AS RevenueAmountIncludingVATLocal,
		|	SUM(T.ManualDiscount) AS ManualDiscount,
		|	SUM(T.DiscountMarkupAmount) AS DiscountMarkupAmount,
		|	SUM(T.OffBalanceCost) AS OffBalanceCost,
		|	SUM(T.LaborCosts) AS LaborCosts,
		|	SUM(T.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(T.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(T.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(T.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(T.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(T.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(T.SellingExpensesLocal) AS SellingExpensesLocal,		
		|	SUM(T.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(T.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(T.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(T.CostMan) AS CostMan,
		|	SUM(T.AddExpensesMan) AS AddExpensesMan,
		|	SUM(T.SellingExpensesMan) AS SellingExpensesMan,		
		|	SUM(T.LaborCostsMan) AS LaborCostsMan,
		|	SUM(T.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(T.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	SUM(T.ExciseAmountInCurrencyMgmt) AS ExciseAmountInCurrencyMgmt,
		|	SUM(T.ExciseAmountInCurrencyLocal) AS ExciseAmountInCurrencyLocal,
		|
		|	SUM(T.AmountInARAPCurrency) AS AmountInARAPCurrency,
		|	SUM(T.AmountExcludingVATInARAPCurrency) AS AmountExcludingVATInARAPCurrency,
		|	SUM(T.AmountInDocumentCurrency) AS AmountInDocumentCurrency,
		|	SUM(T.AmountExcludingVATInDocumentCurrency) AS AmountExcludingVATInDocumentCurrency
		|INTO TTRevenueWithoutBatches
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|		INNER JOIN TTPartnerAnalyticsSelection AS PartnerAnalytics_
		|			ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON PartnerAnalytics_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
		|			ON T.ItemsLocationAttributes = DimensionOfProductItem.Ref
		|		INNER JOIN Catalog.Products AS CatProducts
		|			ON DimensionOfProductItem.Products = CatProducts.Ref
		|		LEFT JOIN InventoryCostForTTRevenueWithoutBatches AS InventoryCost
		|			ON T.Recorder = InventoryCost.Recorder
		|			AND T.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods)
		|			AND T.BusinessTransactionSetting = InventoryCost.BusinessTransactionSetting
		|			AND T.FinRecordID = InventoryCost.FinRecordID
		|WHERE
		|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		// The conditions for excluding records from the selection must match the conditions for the selection to save
		// Registered Records in the function of the Textpreservable Movements().
		|	AND NOT (T.Recorder REFS Document.OBEntry 
		|		OR T.Recorder REFS Document.OBEntrySalesForPastPeriods)
		|	AND CatProducts.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
		|	AND NOT T.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn),
		|		VALUE(Enum.BusinessTransactions.AdjustBeforeEnteringBalance))
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|	AND T.Active
		|
		|GROUP BY
		|	T.Period,
		|	T.AdjustmentPeriod_,
		|	T.Recorder,
		|	PartnerAnalytics_.Organization,
		|	ISNULL(InventoryCost.CorItemsLocationAttributes, T.ItemsLocationAttributes),
		|	T.SalesOrder,
		|	T.AccountingDimensionByPartners,
		|	T.Department,
		|	T.InventoryType,
		|	T.InventoryOwnerAttribute,
		|	T.AccountingSection,
		|	T.Manager,
		|	T.Warehouse,
		|	T.Terms,
		|	T.Contract,
		|	T.BusinessOperation,
		|	T.SetAccountingDimension,
		|	T.CounterpartyLineOfBusiness,
		|	T.ProductLineOfBusiness,
		|	T.VATTaxation,
		|	T.ARAPCurrency,
		|	T.DocumentCurrency,
		|	T.SourceOfProductFinancialAccountingGroup,
		|	T.SourceOfARAPFinancialAccountingGroup,
		|	T.DocumentRegisterRecords,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate
		|INDEX BY
		|	T.Recorder
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Recorder,
		|   T.SalesOrder
		|INTO TTAmountAdjustments
		|FROM
		|	TTRevenueWithoutBatches AS T
		|WHERE
		|	T.Count = 0
		|INDEX BY
		|	Recorder
		|
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|   T.Recorder AS Recorder,
		|	T.SalesOrder,
		|	T.AccountingDimensionByPartners,
		|	Filter.Recorder AS Adjusting
		|INTO TTImplementationDocuments
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|		INNER JOIN TTAmountAdjustments AS Filter
		|			ON T.SalesOrder = Filter.SalesOrder
		|WHERE
		|	T.Period <= &EndOfPeriod
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|	AND T.Active
		|	AND T.Count <> 0
		|	AND (Filter.SalesOrder <> UNDEFINED OR T.Recorder = Filter.Recorder)
		|INDEX BY
		|	Recorder
		|
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Period,
		|	T.Recorder AS Recorder,
		|	Recorders.Adjusting,
		|   T.Organization,
		|   T.ItemsLocationAttributes,
		|	CASE WHEN T.SalesOrder = UNDEFINED
		|		THEN Recorders.SalesOrder
		|		ELSE T.SalesOrder
		|	END AS SalesOrder,
		|	CASE WHEN T.AccountingDimensionByPartners = VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
		|		THEN Recorders.AccountingDimensionByPartners
		|		ELSE T.AccountingDimensionByPartners
		|	END AS AccountingDimensionByPartners,
		|	(CASE
		|		WHEN T.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
		|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
		|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
		|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
		|				VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses))
		|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
		|		ELSE T.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   T.Lot,
		|   T.LotVendorAttributes,
		|   T.FinancialAccountingDimension,
		|   T.VATActivityType,
		|   T.BusinessOperation,
		|   T.Count
		|INTO TTBatchesForAmountAdjustments
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTImplementationDocuments AS Recorders
		|		ON T.Recorder = Recorders.Recorder
		|WHERE
		|	T.Count <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	T.Period,
		|	T.Recorder AS Recorder,
		|	Recorders.Adjusting,
		|   T.Organization,
		|   T.ItemsLocationAttributes,
		|	CASE WHEN T.SalesOrder = UNDEFINED
		|		THEN Recorders.SalesOrder
		|		ELSE T.SalesOrder
		|	END AS SalesOrder,
		|	CASE WHEN T.AccountingDimensionByPartners = VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
		|		THEN Recorders.AccountingDimensionByPartners
		|		ELSE T.AccountingDimensionByPartners
		|	END AS AccountingDimensionByPartners,
		|	(CASE
		|		WHEN T.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
		|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
		|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
		|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
		|				VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses))
		|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
		|		ELSE T.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   T.Lot,
		|   T.LotVendorAttributes,
		|   T.FinancialAccountingDimension,
		|   T.VATActivityType,
		|   T.BusinessOperation,
		|   T.Count
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN TTImplementationDocuments AS Recorders
		|		ON T.Recorder = Recorders.Recorder
		|WHERE
		|	T.Period < &BeginOfPeriod
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|	AND T.Active
		|	AND T.Count <> 0
		|INDEX BY
		|	Recorder,
		|	ItemsLocationAttributes
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Period AS Period,
		|	T.AdjustmentPeriod_ AS AdjustmentPeriod_,
		|	T.Recorder AS Recorder,
		|	T.Organization AS Organization,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.SalesOrder AS SalesOrder,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.Department AS Department,
		|	T.InventoryType AS InventoryType,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.AccountingSection AS AccountingSection,
		|	T.Manager AS Manager,
		|	T.Warehouse AS Warehouse,
		|	T.Terms AS Terms,
		|	T.Contract AS Contract,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.SetAccountingDimension AS SetAccountingDimension,
		|	T.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
		|	T.ProductLineOfBusiness AS ProductLineOfBusiness,
		|	SUM(ISNULL(SalesOfGoodsAndServices.Count, 0)) AS Count,
		|	SUM(CASE WHEN ISNULL(SalesOfGoodsAndServices.Count, 0) > 0 THEN SalesOfGoodsAndServices.Count ELSE 0 END) AS QuantityPositive,
		|	MIN(T.RevenueAmount) AS RevenueAmount,
		|	MIN(T.RevenueAmountExcludingVAT) AS RevenueAmountExcludingVAT,
		|	MIN(T.Cost) AS Cost,
		|	MIN(T.CostExcludingVAT) AS CostExcludingVAT,
		|	MIN(T.AddExpensesForGoods) AS AddExpensesForGoods,
		|	MIN(T.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	MIN(T.SellingExpensesIncludingVAT) AS SellingExpensesIncludingVAT,
		|	MIN(T.SellingExpensesExcludingVAT) AS SellingExpensesExcludingVAT,
		|	MIN(T.LocalCost) AS LocalCost,
		|	MIN(T.RevenueAmountExclVATLocal) AS RevenueAmountExclVATLocal,
		|	MIN(T.RevenueAmountPD) AS RevenueAmountPD,
		|	MIN(T.RevenueAmountTD) AS RevenueAmountTD,
		|	MIN(T.PermanentDifference) AS PermanentDifference,
		|	MIN(T.CostTD) AS CostTD,
		|	MIN(T.RevenueAmountIncludingVATLocal) AS RevenueAmountIncludingVATLocal,
		|	MIN(T.ManualDiscount) AS ManualDiscount,
		|	MIN(T.DiscountMarkupAmount) AS DiscountMarkupAmount,
		|	MIN(T.OffBalanceCost) AS OffBalanceCost,
		|	MIN(T.LaborCosts) AS LaborCosts,
		|	MIN(T.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	MIN(T.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	MIN(T.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	MIN(T.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	MIN(T.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	MIN(T.AddExpensesLocal) AS AddExpensesLocal,
		|	MIN(T.SellingExpensesLocal) AS SellingExpensesLocal,
		|	MIN(T.LaborCostsLocal) AS LaborCostsLocal,
		|	MIN(T.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	MIN(T.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	MIN(T.CostMan) AS CostMan,
		|	MIN(T.AddExpensesMan) AS AddExpensesMan,
		|	MIN(T.SellingExpensesMan) AS SellingExpensesMan,
		|	MIN(T.LaborCostsMan) AS LaborCostsMan,
		|	MIN(T.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	MIN(T.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	MIN(T.ExciseAmountInCurrencyMgmt) AS ExciseAmountInCurrencyMgmt,
		|	MIN(T.ExciseAmountInCurrencyLocal) AS ExciseAmountInCurrencyLocal,
		|	T.VATTaxation AS VATTaxation,
		|	T.ARAPCurrency AS ARAPCurrency,
		|	MIN(T.AmountInARAPCurrency) AS AmountInARAPCurrency,
		|	MIN(T.AmountExcludingVATInARAPCurrency) AS AmountExcludingVATInARAPCurrency,
		|	T.DocumentCurrency AS DocumentCurrency,
		|	MIN(T.AmountInDocumentCurrency) AS AmountInDocumentCurrency,
		|	MIN(T.AmountExcludingVATInDocumentCurrency) AS AmountExcludingVATInDocumentCurrency,
		|	T.SourceOfProductFinancialAccountingGroup AS SourceOfProductFinancialAccountingGroup,
		|	T.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
		|	T.DocumentRegisterRecords AS DocumentRegisterRecords,
		|   T.BusinessTransactionSetting,
		|   T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate
		|INTO TTRevenueWithoutBatchesWithoutQuantity
		|FROM
		|	TTRevenueWithoutBatches AS T
		|		INNER JOIN TTAmountAdjustments AS AdjustingEntries
		|		ON T.Recorder = AdjustingEntries.Recorder
		|			AND T.SalesOrder = AdjustingEntries.SalesOrder
		|		LEFT JOIN TTBatchesForAmountAdjustments AS SalesOfGoodsAndServices
		|		ON T.ItemsLocationAttributes = SalesOfGoodsAndServices.ItemsLocationAttributes
		|			AND T.InventoryOwnerAttribute = SalesOfGoodsAndServices.InventoryOwnerAttribute
		|			AND T.Organization = SalesOfGoodsAndServices.Organization
		|			AND T.AccountingSection = SalesOfGoodsAndServices.AccountingSection
		|			AND T.AccountingDimensionByPartners = SalesOfGoodsAndServices.AccountingDimensionByPartners
		|			AND T.SalesOrder = SalesOfGoodsAndServices.SalesOrder
		|			AND T.Recorder = SalesOfGoodsAndServices.Adjusting
		|WHERE
		|	T.Count = 0
		|
		|GROUP BY
		|	T.Period,
		|	T.AdjustmentPeriod_,
		|	T.Recorder,
		|	T.Organization,
		|	T.ItemsLocationAttributes,
		|	T.SalesOrder,
		|	T.AccountingDimensionByPartners,
		|	T.Department,
		|	T.InventoryType,
		|	T.InventoryOwnerAttribute,
		|	T.AccountingSection,
		|	T.Manager,
		|	T.Warehouse,
		|	T.Terms,
		|	T.Contract,
		|	T.BusinessOperation,
		|	T.SetAccountingDimension,
		|	T.CounterpartyLineOfBusiness,
		|	T.ProductLineOfBusiness,
		|	T.VATTaxation,
		|	T.ARAPCurrency,
		|	T.DocumentCurrency,
		|	T.SourceOfProductFinancialAccountingGroup,
		|	T.SourceOfARAPFinancialAccountingGroup,
		|	T.DocumentRegisterRecords,
		|	T.BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate
		|INDEX BY
		|	Recorder
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Recorder
		|INTO TTRevenueRegistrars
		|FROM
		|	TTRevenueWithoutBatches AS T
		|INDEX BY
		|	Recorder
		|;
		|////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Recorder,
		|	T.ItemsLocationAttributes
		|INTO TTSelectionAdjustmentOfAmounts
		|FROM
		|	TTRevenueWithoutBatches AS T
		|
		|UNION
		|
		|SELECT DISTINCT
		|	T.Recorder,
		|	T.ItemsLocationAttributes
		|FROM
		|	TTRevenueWithoutBatchesWithoutQuantity AS T
		|INDEX BY
		|	Recorder,
		|	ItemsLocationAttributes
		|";
	
EndFunction

// ... data samples

Function BatchTextForRevenue()
	Return 
		"SELECT
		|	""BatchTextForRevenue"" 						  	  AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Lot)  	  AS EntryType,
		|	TRUE 												  AS CalculationIsCompleted,
		|	T.Period											  AS Period,
		|	DATETIME(1,1,1)									  AS AdjustmentPeriod_,
		|	T.Recorder										  AS Recorder,
		|	CASE WHEN T.Count < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|
		|   T.Organization,
		|	CASE WHEN T.ItemsLocationAttributes <> T.CorItemsLocationAttributes
		|		AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|			VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse),
		|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)) 
		|		AND NOT T.CorItemsLocationAttributes IN (UNDEFINED, 
		|			VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)) THEN
		|		T.CorItemsLocationAttributes
		|	ELSE
		|		T.ItemsLocationAttributes
		|	END AS ItemsLocationAttributes,
		|   T.SalesOrder,
		|   T.AccountingDimensionByPartners,
		|   UNDEFINED AS Department,
		|   UNDEFINED AS InventoryType,
		// The condition for the Type of reserves field must be identical to the calculation of the cost of cost correction.Adjust the value of sales
		|	(CASE
		|		WHEN ISNULL(T.InventoryOwnerAttribute.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
		|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
		|		ELSE T.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
		// The conditions for determining the accounting field must correspond to the procedure for adjusting the cost of returns of the past periods()
		// #Revenue area and the cost of sales of the general module calculation of the cost of cost correction.
		|	(CASE
		|		WHEN T.ItemsLocationAttributes <> T.CorItemsLocationAttributes
		|		 AND T.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|			VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse),
		|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)) 
		|		 AND NOT T.CorItemsLocationAttributes IN (UNDEFINED, VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))
		|		 AND ISNULL(T.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
		|		 	<> ISNULL(T.CorItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
		|		THEN (CASE WHEN ISNULL(T.CorItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) END)
		|	ELSE T.AccountingSection END) AS AccountingSection,
		|   T.Lot,
		|   T.LotVendorAttributes,
		|   T.FinancialAccountingDimension,
		|   T.VATActivityType,
		|   UNDEFINED AS Manager,
		|   UNDEFINED AS Warehouse,
		|   UNDEFINED AS Terms,
		|   UNDEFINED AS Contract,
		|   UNDEFINED AS BusinessOperation,
		|   UNDEFINED AS SetAccountingDimension,
		|   UNDEFINED AS CounterpartyLineOfBusiness,
		|   UNDEFINED AS ProductLineOfBusiness,
		|
		|   T.Count,
		|   0 AS RevenueAmount,
		|   0 AS RevenueAmountExcludingVAT,
		|   0 AS Cost,
		|   0 AS CostExcludingVAT,
		|   0 AS AddExpensesForGoods,
		|   0 AS AdditionalExpensesExcludingVAT,
		|   0 AS SellingExpensesIncludingVAT,
		|   0 AS SellingExpensesExcludingVAT,
		|   0 AS LocalCost,
		|   0 AS RevenueAmountExclVATLocal,
		|   0 AS RevenueAmountPD,
		|   0 AS RevenueAmountTD,
		|   0 AS PermanentDifference,
		|   0 AS CostTD,
		|   0 AS RevenueAmountIncludingVATLocal,
		|   0 AS ManualDiscount,
		|   0 AS DiscountMarkupAmount,
		|   0 AS OffBalanceCost,
		|   0 AS LaborCosts,
		|   0 AS ItemizedFixedCostsIncludingVAT,
		|   0 AS ItemizedVariableCostsIncludingVAT,
		|   0 AS ItemizedFixedCostsExcludingVAT,
		|   0 AS ItemizedVariableCostsExcludingVAT,
		|   0 AS OffBalanceCostLocal,
		|   0 AS AddExpensesLocal,
		|   0 AS SellingExpensesLocal,
		|   0 AS LaborCostsLocal,
		|   0 AS ItemizedFixedCostsCompl,
		|   0 AS ItemizedVariableCostsCompl,
		|   0 AS CostMan,
		|   0 AS AddExpensesMan,
		|   0 AS SellingExpensesMan,
		|   0 AS LaborCostsMan,
		|   0 AS ItemizedFixedCostsManag,
		|   0 AS ItemizedVariableCostsManag,
		|	0 AS ExciseAmountInCurrencyMgmt,
		|	0 AS ExciseAmountInCurrencyLocal,
		|
		|   UNDEFINED AS VATTaxation,
		|   UNDEFINED AS ARAPCurrency,
		|   0 AS AmountInARAPCurrency,
		|   0 AS AmountExcludingVATInARAPCurrency,
		|   UNDEFINED AS DocumentCurrency,
		|   0 AS AmountInDocumentCurrency,
		|   0 AS AmountExcludingVATInDocumentCurrency,
		|   UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|   UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|   UNDEFINED AS DocumentRegisterRecords,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	T.FinRecordID,
		|	T.ReversingEntry,
		|	UNDEFINED AS VATRate
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTRevenueRegistrars AS Recorders
		|		ON T.Recorder = Recorders.Recorder
		|WHERE
		|	T.Count <> 0
		|";
EndFunction

Function BatchTextForRevenueWithoutQuantity()
	Return 
		"SELECT
		|	""BatchTextForRevenueWithoutQuantity"" 				  AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.LotsToAllocate) AS EntryType,
		|	TRUE 												  AS CalculationIsCompleted,
		|	T.Period											  AS Period,
		|	DATETIME(1,1,1)									  AS AdjustmentPeriod_,
		|	T.Adjusting										  AS Recorder,
		|	CASE WHEN SUM(T.Count) < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|
		|   T.Organization,
		|   T.ItemsLocationAttributes,
		|   T.SalesOrder,
		|   T.AccountingDimensionByPartners,
		|   UNDEFINED AS Department,
		|   UNDEFINED AS InventoryType,
		|   T.InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   T.Lot,
		|   T.LotVendorAttributes,
		|   T.FinancialAccountingDimension,
		|   T.VATActivityType,
		|   UNDEFINED AS Manager,
		|   UNDEFINED AS Warehouse,
		|   UNDEFINED AS Terms,
		|   UNDEFINED AS Contract,
		|   UNDEFINED AS BusinessOperation,
		|   UNDEFINED AS SetAccountingDimension,
		|   UNDEFINED AS CounterpartyLineOfBusiness,
		|   UNDEFINED AS ProductLineOfBusiness,
		|
		|   SUM(T.Count) AS Count,
		|   0 AS RevenueAmount,
		|   0 AS RevenueAmountExcludingVAT,
		|   0 AS Cost,
		|   0 AS CostExcludingVAT,
		|   0 AS AddExpensesForGoods,
		|   0 AS AdditionalExpensesExcludingVAT,
		|   0 AS SellingExpensesIncludingVAT,
		|   0 AS SellingExpensesExcludingVAT,
		|   0 AS LocalCost,
		|   0 AS RevenueAmountExclVATLocal,
		|   0 AS RevenueAmountPD,
		|   0 AS RevenueAmountTD,
		|   0 AS PermanentDifference,
		|   0 AS CostTD,
		|   0 AS RevenueAmountIncludingVATLocal,
		|   0 AS ManualDiscount,
		|   0 AS DiscountMarkupAmount,
		|   0 AS OffBalanceCost,
		|   0 AS LaborCosts,
		|   0 AS ItemizedFixedCostsIncludingVAT,
		|   0 AS ItemizedVariableCostsIncludingVAT,
		|   0 AS ItemizedFixedCostsExcludingVAT,
		|   0 AS ItemizedVariableCostsExcludingVAT,
		|   0 AS OffBalanceCostLocal,
		|   0 AS AddExpensesLocal,
		|   0 AS SellingExpensesLocal,
		|   0 AS LaborCostsLocal,
		|   0 AS ItemizedFixedCostsCompl,
		|   0 AS ItemizedVariableCostsCompl,
		|   0 AS CostMan,
		|   0 AS AddExpensesMan,
		|   0 AS SellingExpensesMan,
		|   0 AS LaborCostsMan,
		|   0 AS ItemizedFixedCostsManag,
		|   0 AS ItemizedVariableCostsManag,
		|	0 AS ExciseAmountInCurrencyMgmt,
		|	0 AS ExciseAmountInCurrencyLocal,
		|
		|   UNDEFINED AS VATTaxation,
		|   UNDEFINED AS ARAPCurrency,
		|   0 AS AmountInARAPCurrency,
		|   0 AS AmountExcludingVATInARAPCurrency,
		|   UNDEFINED AS DocumentCurrency,
		|   0 AS AmountInDocumentCurrency,
		|   0 AS AmountExcludingVATInDocumentCurrency,
		|   UNDEFINED AS SourceOfProductFinancialAccountingGroup,
		|   UNDEFINED AS SourceOfARAPFinancialAccountingGroup,
		|   UNDEFINED AS DocumentRegisterRecords,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" AS FinRecordID,
		|	FALSE AS ReversingEntry,
		|	UNDEFINED AS VATRate
		|FROM
		|	TTBatchesForAmountAdjustments AS T
		|	INNER JOIN TTSelectionAdjustmentOfAmounts AS Filter
		|		ON T.Adjusting = Filter.Recorder
		|		 AND T.ItemsLocationAttributes = Filter.ItemsLocationAttributes
		|GROUP BY
		|	T.Period,
		|	T.Adjusting,
		|   T.Organization,
		|   T.ItemsLocationAttributes,
		|   T.SalesOrder,
		|   T.AccountingDimensionByPartners,
		|   T.InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   T.Lot,
		|   T.LotVendorAttributes,
		|   T.FinancialAccountingDimension,
		|   T.VATActivityType
		|";
EndFunction

Function TextRevenueWithoutLots()
	Return 
		"SELECT
		|	""TextRevenueWithoutLots"" 						  	  AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Consumption)  AS EntryType,
		|	(CASE
		|		WHEN T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn)
		|			THEN TRUE
		|		ELSE FALSE END)								  AS CalculationIsCompleted,
		|	T.Period											  AS Period,
		|	T.AdjustmentPeriod_								  AS AdjustmentPeriod_,
		|	T.Recorder										  AS Recorder,
		|	CASE WHEN T.Count < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|
		|	T.Organization,
		|   T.ItemsLocationAttributes,
		|   T.SalesOrder,
		|   T.AccountingDimensionByPartners,
		|   T.Department,
		|   T.InventoryType,
		|   T.InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   UNDEFINED AS Lot,
		|   UNDEFINED AS LotVendorAttributes,
		|   UNDEFINED AS FinancialAccountingDimension,
		|   UNDEFINED AS VATActivityType,
		|   T.Manager,
		|   T.Warehouse,
		|   T.Terms,
		|   T.Contract,
		|   T.BusinessOperation,
		|   T.SetAccountingDimension,
		|   T.CounterpartyLineOfBusiness,
		|   T.ProductLineOfBusiness,
		|
		|   T.Count,
		|   T.RevenueAmount,
		|   T.RevenueAmountExcludingVAT,
		|   T.Cost,
		|   T.CostExcludingVAT,
		|   T.AddExpensesForGoods,
		|   T.AdditionalExpensesExcludingVAT,
		|   T.SellingExpensesIncludingVAT,
		|   T.SellingExpensesExcludingVAT,
		|   T.LocalCost,
		|   T.RevenueAmountExclVATLocal,
		|   T.RevenueAmountPD,
		|   T.RevenueAmountTD,
		|   T.PermanentDifference,
		|   T.CostTD,
		|   T.RevenueAmountIncludingVATLocal,
		|   T.ManualDiscount,
		|   T.DiscountMarkupAmount,
		|   T.OffBalanceCost,
		|   T.LaborCosts,
		|   T.ItemizedFixedCostsIncludingVAT,
		|   T.ItemizedVariableCostsIncludingVAT,
		|   T.ItemizedFixedCostsExcludingVAT,
		|   T.ItemizedVariableCostsExcludingVAT,
		|   T.OffBalanceCostLocal,
		|   T.AddExpensesLocal,
		|   T.SellingExpensesLocal,
		|   T.LaborCostsLocal,
		|   T.ItemizedFixedCostsCompl,
		|   T.ItemizedVariableCostsCompl,
		|   T.CostMan,
		|   T.AddExpensesMan,
		|   T.SellingExpensesMan,
		|   T.LaborCostsMan,
		|   T.ItemizedFixedCostsManag,
		|   T.ItemizedVariableCostsManag,
		|	T.ExciseAmountInCurrencyMgmt,
		|	T.ExciseAmountInCurrencyLocal,
		|
		|   T.VATTaxation,
		|   T.ARAPCurrency,
		|   T.AmountInARAPCurrency,
		|   T.AmountExcludingVATInARAPCurrency,
		|   T.DocumentCurrency,
		|   T.AmountInDocumentCurrency,
		|   T.AmountExcludingVATInDocumentCurrency,
		|   T.SourceOfProductFinancialAccountingGroup,
		|   T.SourceOfARAPFinancialAccountingGroup,
		|   T.DocumentRegisterRecords,
		|   T.BusinessTransactionSetting,
		|   T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate
		|FROM
		|	TTRevenueWithoutBatches AS T
		|WHERE
		|	T.Count <> 0
		|";
EndFunction

Function TextRevenueWithoutBatchesWithoutQuantity()
	Return 
		"SELECT
		|	""TextRevenueWithoutBatchesWithoutQuantity"" 				  	 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.ConsumptionLotCalculation) AS EntryType,
		|	FALSE 												  	 AS CalculationIsCompleted,
		|	T.Period											  	 AS Period,
		|	T.AdjustmentPeriod_								  	 AS AdjustmentPeriod_,
		|	T.Recorder										  	 AS Recorder,
		|	CASE WHEN T.Count < 0 THEN TRUE ELSE FALSE END AS ThisIsReverseTransaction,
		|
		|	T.Organization,
		|   T.ItemsLocationAttributes,
		|   T.SalesOrder,
		|   T.AccountingDimensionByPartners,
		|   T.Department,
		|   T.InventoryType,
		|   T.InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   UNDEFINED AS Lot,
		|   UNDEFINED AS LotVendorAttributes,
		|   UNDEFINED AS FinancialAccountingDimension,
		|   UNDEFINED AS VATActivityType,
		|   T.Manager,
		|   T.Warehouse,
		|   T.Terms,
		|   T.Contract,
		|   T.BusinessOperation,
		|   T.SetAccountingDimension,
		|   T.CounterpartyLineOfBusiness,
		|   T.ProductLineOfBusiness,
		|
		|   CASE WHEN T.QuantityPositive > 0
		|		THEN T.QuantityPositive
		|		ELSE T.Count
		|	END AS Count,
		|   T.RevenueAmount,
		|   T.RevenueAmountExcludingVAT,
		|   T.Cost,
		|   T.CostExcludingVAT,
		|   T.AddExpensesForGoods,
		|   T.AdditionalExpensesExcludingVAT,
		|   T.SellingExpensesIncludingVAT,
		|   T.SellingExpensesExcludingVAT,
		|   T.LocalCost,
		|   T.RevenueAmountExclVATLocal,
		|   T.RevenueAmountPD,
		|   T.RevenueAmountTD,
		|   T.PermanentDifference,
		|   T.CostTD,
		|   T.RevenueAmountIncludingVATLocal,
		|   T.ManualDiscount,
		|   T.DiscountMarkupAmount,
		|   T.OffBalanceCost,
		|   T.LaborCosts,
		|   T.ItemizedFixedCostsIncludingVAT,
		|   T.ItemizedVariableCostsIncludingVAT,
		|   T.ItemizedFixedCostsExcludingVAT,
		|   T.ItemizedVariableCostsExcludingVAT,
		|   T.OffBalanceCostLocal,
		|   T.AddExpensesLocal,
		|   T.SellingExpensesLocal,
		|   T.LaborCostsLocal,
		|   T.ItemizedFixedCostsCompl,
		|   T.ItemizedVariableCostsCompl,
		|   T.CostMan,
		|   T.AddExpensesMan,
		|   T.SellingExpensesMan,
		|   T.LaborCostsMan,
		|   T.ItemizedFixedCostsManag,
		|   T.ItemizedVariableCostsManag,
		|	T.ExciseAmountInCurrencyMgmt,
		|	T.ExciseAmountInCurrencyLocal,
		|
		|   T.VATTaxation,
		|   T.ARAPCurrency,
		|   T.AmountInARAPCurrency,
		|   T.AmountExcludingVATInARAPCurrency,
		|   T.DocumentCurrency,
		|   T.AmountInDocumentCurrency,
		|   T.AmountExcludingVATInDocumentCurrency,
		|   T.SourceOfProductFinancialAccountingGroup,
		|   T.SourceOfARAPFinancialAccountingGroup,
		|   T.DocumentRegisterRecords,
		|   T.BusinessTransactionSetting,
		|   T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate
		|FROM
		|	TTRevenueWithoutBatchesWithoutQuantity AS T
		|";
EndFunction

Function TextRevenueSavedRegisteredRecords()
	Return 
		"SELECT
		|	""TextRevenueSavedRegisteredRecords"" 				  AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.Supplement)   AS EntryType,
		|	TRUE 												  AS CalculationIsCompleted,
		|	T.Period											  AS Period,
		|	T.AdjustmentPeriod_								  AS AdjustmentPeriod_,
		|	T.Recorder										  AS Recorder,
		|	FALSE 												  AS ThisIsReverseTransaction,
		|
		|	PartnerAnalytics_.Organization 						  AS Organization,
		|   T.ItemsLocationAttributes,
		|   T.SalesOrder,
		|   T.AccountingDimensionByPartners,
		|   T.Department,
		|   T.InventoryType,
		|   T.InventoryOwnerAttribute,
		|   T.AccountingSection,
		|   T.Lot,
		|   T.LotVendorAttributes,
		|   T.FinancialAccountingDimension,
		|   T.VATActivityType,
		|   T.Manager,
		|   T.Warehouse,
		|   T.Terms,
		|   T.Contract,
		|   T.BusinessOperation,
		|   T.SetAccountingDimension,
		|   T.CounterpartyLineOfBusiness,
		|   T.ProductLineOfBusiness,
		|
		|   T.Count,
		|   T.RevenueAmount,
		|   T.RevenueAmountExcludingVAT,
		|   T.Cost,
		|   T.CostExcludingVAT,
		|   T.AddExpensesForGoods,
		|   T.AdditionalExpensesExcludingVAT,
		|   T.SellingExpensesIncludingVAT,
		|   T.SellingExpensesExcludingVAT,
		|   T.LocalCost,
		|   T.RevenueAmountExclVATLocal,
		|   T.RevenueAmountPD,
		|   T.RevenueAmountTD,
		|   T.PermanentDifference,
		|   T.CostTD,
		|   T.RevenueAmountIncludingVATLocal,
		|   T.ManualDiscount,
		|   T.DiscountMarkupAmount,
		|   T.OffBalanceCost,
		|   T.LaborCosts,
		|   T.ItemizedFixedCostsIncludingVAT,
		|   T.ItemizedVariableCostsIncludingVAT,
		|   T.ItemizedFixedCostsExcludingVAT,
		|   T.ItemizedVariableCostsExcludingVAT,
		|   T.OffBalanceCostLocal,
		|   T.AddExpensesLocal,
		|   T.SellingExpensesLocal,
		|   T.LaborCostsLocal,
		|   T.ItemizedFixedCostsCompl,
		|   T.ItemizedVariableCostsCompl,
		|   T.CostMan,
		|   T.AddExpensesMan,
		|   T.SellingExpensesMan,
		|   T.LaborCostsMan,
		|   T.ItemizedFixedCostsManag,
		|   T.ItemizedVariableCostsManag,
		|	T.ExciseAmountInCurrencyMgmt,
		|	T.ExciseAmountInCurrencyLocal,
		|
		|   T.VATTaxation,
		|   T.ARAPCurrency,
		|   T.AmountInARAPCurrency,
		|   T.AmountExcludingVATInARAPCurrency,
		|   T.DocumentCurrency,
		|   T.AmountInDocumentCurrency,
		|   T.AmountExcludingVATInDocumentCurrency,
		|   T.SourceOfProductFinancialAccountingGroup,
		|   T.SourceOfARAPFinancialAccountingGroup,
		|   T.DocumentRegisterRecords,
		|   T.BusinessTransactionSetting,
		|   T.FinRecordID,
		|	T.ReversingEntry,
		|	T.VATRate
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|		INNER JOIN TTPartnerAnalyticsSelection AS PartnerAnalytics_
		|			ON T.AccountingDimensionByPartners = PartnerAnalytics_.DimensionKey
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON PartnerAnalytics_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
		|			INNER JOIN Catalog.Products AS CatProducts
		|				ON DimensionOfProductItem.Products = CatProducts.Ref
		|			ON T.ItemsLocationAttributes = DimensionOfProductItem.Ref
		|WHERE
		|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		// The conditions for the selection to save Registered Records must correspond to the conditions for excluding entries from the selection
		// in the text initialization function of the Party Handles() in the request for the formation of a temporary table in the hands of non-parties.
		|	AND (CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		|		OR T.Recorder REFS Document.OBEntry
		|		OR T.Recorder REFS Document.OBEntrySalesForPastPeriods
		|		OR T.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn),
		|			VALUE(Enum.BusinessTransactions.AdjustBeforeEnteringBalance))
		// For organizations on a medium-slip, you need to save all the original Registered Records, otherwise they will not be in the table of Cash settlement turnovers and the highest value of sales. 
		|		OR TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		)
		|	AND T.Active
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|";
EndFunction

// Filling out the payment batch

Procedure FillInEstimatedBatchOfRevenueAndCostOfSales(CalculationParameters, SettlementBatch, Expense, Receipt)
	
	// For adjustments of amounts without adjusting the quantity, we use only
	// records with a positive quantity as sources, i.e. we take data only from real implementations,
	// because they have all the necessary information about the corrected batches of goods.
	// If there are only a few implementations, then we take data from them.
	If Expense.EntryType = Enums.LotRecordTypes.ConsumptionLotCalculation
	 And Receipt.Count <= 0 And Expense.Count >= 0 Then
		NumberOfDebits = 0;
	Else
		NumberOfDebits = Min(Expense.Count, Receipt.Count);
	EndIf;
	
	If NumberOfDebits = 0 Then
		Return;
	EndIf;
	
	SummaryResources = New Structure(
	"Cost, CostExcludingVAT, AddExpensesForGoods, AdditionalExpensesExcludingVAT,
	|RevenueAmount, RevenueAmountExcludingVAT, RevenueAmountExclVATLocal, RevenueAmountIncludingVATLocal, ManualDiscount, DiscountMarkupAmount,
	|RevenueAmountPD, RevenueAmountTD,
	|LocalCost, PermanentDifference, CostTD,
	|OffBalanceCost, LaborCosts, ItemizedFixedCostsIncludingVAT, ItemizedFixedCostsExcludingVAT,
	|ItemizedVariableCostsIncludingVAT, ItemizedVariableCostsExcludingVAT,
	|CostMan, AddExpensesMan, LaborCostsMan, ItemizedFixedCostsManag, ItemizedVariableCostsManag,
	|OffBalanceCostLocal, AddExpensesLocal, LaborCostsLocal,
	|ItemizedFixedCostsCompl, ItemizedVariableCostsCompl,
	|SellingExpensesIncludingVAT, SellingExpensesExcludingVAT, SellingExpensesMan, SellingExpensesLocal,
	|AmountInARAPCurrency, AmountExcludingVATInARAPCurrency, AmountInDocumentCurrency, AmountExcludingVATInDocumentCurrency,
	|ExciseAmountInCurrencyMgmt, ExciseAmountInCurrencyLocal");
	
	// We fill out the settlement batch according to the expenditure batch-the basis
	FillPropertyValues(SettlementBatch, Expense);
	
	//	We fill in the batch identification in the settlement batch
	FillPropertyValues(SettlementBatch, Receipt, "Lot, LotVendorAttributes, VATActivityType, FinancialAccountingDimension");
	
	// the calculated batch is filled with the largest total deductible
	ConsumptionBasis = ?(Expense.Count <> 0, NumberOfDebits / Expense.Count, 0);
	
	// we fill in the indicators of the settlement batch
	
	If Expense.EntryType = Enums.LotRecordTypes.ConsumptionLotCalculation Then
		SettlementBatch.Count = 0;
	Else
		SettlementBatch.Count = NumberOfDebits;
	EndIf;
	
	For Each ResourceName In SummaryResources Do
		SettlementBatch[ResourceName.Key] = Round(ConsumptionBasis * SettlementBatch[ResourceName.Key], 2);
		Expense[ResourceName.Key] = Expense[ResourceName.Key] - SettlementBatch[ResourceName.Key];
	EndDo;
	
	// We adjust the calculation base in the income and expense
	If Expense.EntryType <> Enums.LotRecordTypes.ConsumptionLotCalculation Then
		Receipt.Count = Receipt.Count - NumberOfDebits;
	EndIf;
	Expense.Count = Expense.Count - NumberOfDebits;
	
	SettlementBatch.CalculationIsCompleted = True;
	
EndProcedure

#EndRegion

#Region ProcedureOfStage_ReSortingOfBatchesOfGoods

Procedure GoodsLotsMisgrading(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "GoodsLotsMisgrading");
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	#Region DataPreparation
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
	|SELECT
	|	RECORDAUTONUMBER() AS RecNo,
	|	Balance.ItemsLocationAttributes,
	|	Balance.AccountingSection,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.Organization,
	|	Balance.Lot AS CorLot,
	|	Balance.LotVendorAttributes AS LotVendorAttributesCorr,
	|	Balance.FinancialAccountingDimension AS CorControllingAttributes,
	|	Balance.VATActivityType AS CorVATActivityTypes,
	// Resources
	|	-Balance.Count AS Count
	|
	|INTO PartiesWithNegativeAmountOfTime
	|FROM
	|	TTCashSettlementBalancesCostOfGoods AS Balance
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|	ON Balance.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|WHERE
	|	Balance.Count < 0
	|	AND Balance.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|;
	|SELECT
	|	T.RecNo
	|FROM
	|	PartiesWithNegativeAmountOfTime AS T
	|";
	IDsTable = New ValueTable;
	IDsTable.Columns.Add("Id", Common.StringTypeDetails(36));
	IDsTable.Columns.Add("RecNo", Common.TypeDescriptionNumber(31));
	
	Selection = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	While Selection.Next() Do
		NewRow = IDsTable.Add();
		NewRow.Id = New UUID;
		NewRow.RecNo = Selection.RecNo;
	EndDo;
	
	Query.SetParameter("IDsTable", IDsTable);
	
	If CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "PartiesWithNegativeAmountOfTime") = 0 Then
		
		// We will destroy unnecessary temporary tables.
		NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, ExistingTT);
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
		
		Return;
		
	EndIf;
	
	Query.Text = "
	|SELECT
	|	IDsTable.Id AS Id,
	|	IDsTable.RecNo AS RecNo
	|INTO IDsTable
	|FROM
	|	&IDsTable AS IDsTable
	|INDEX BY
	|	RecNo
	|;
	|SELECT
	|	Balance.ItemsLocationAttributes,
	|	Balance.AccountingSection,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.Organization,
	|	Balance.CorLot,
	|	Balance.LotVendorAttributesCorr,
	|	Balance.CorControllingAttributes,
	|	Balance.CorVATActivityTypes,
	|	IDsTable.Id AS FinRecordID,
	// Resources
	|	Balance.Count AS Count
	|
	|INTO BatchesWithNegativeQuantity
	|FROM
	|	PartiesWithNegativeAmountOfTime AS Balance
	|	LEFT JOIN IDsTable AS IDsTable
	|		ON IDsTable.RecNo = Balance.RecNo
	|;
	|SELECT
	|	Balance.ItemsLocationAttributes,
	|	Balance.AccountingSection,
	|	Balance.InventoryOwnerAttribute,
	|	Balance.Organization,
	|	Balance.Lot,
	|	Balance.LotVendorAttributes,
	|	Balance.FinancialAccountingDimension,
	|	Balance.VATActivityType,
	|	ISNULL(Register3.IBDocumentDate, &BeginOfPeriod) AS BatchDate,
	|	Balance.Count
	|INTO AvailableBatches
	|FROM
	|	TTCashSettlementBalancesCostOfGoods AS Balance
	|	LEFT JOIN Document.VendorInvoice AS Import
	|		ON Import.Ref = Balance.Lot
	|		AND Import.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.PurchaseByImport),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
	|	LEFT JOIN ThereAreDeclarations AS ThereAreDeclarations
	|		ON ThereAreDeclarations.Lot = Balance.Lot
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Register3.Ref = Balance.Lot
	|		AND NOT Register3.AdditionalRecord
	|		AND Balance.Lot <> UNDEFINED
	|WHERE
	|	Balance.Count > 0
	|	AND (
	|		Balance.ItemsLocationAttributes,
	|		Balance.AccountingSection,
	|		Balance.InventoryOwnerAttribute,
	|		Balance.Organization) IN (
	|	SELECT
	|		Lots.ItemsLocationAttributes,
	|		Lots.AccountingSection,
	|		Lots.InventoryOwnerAttribute,
	|		Lots.Organization
	|	FROM
	|		BatchesWithNegativeQuantity AS Lots)
	|	AND NOT (NOT Balance.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		AND NOT Import.Ref IS NULL AND ThereAreDeclarations.Lot IS NULL)
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	#EndRegion
	
	#Region DataDistribution
	
	// Initializing the distribution
	DistributionParameters = CostCalculationUniversalAlgorithms.InitializeDistributionParametersUsingReducedRemainderMethod(
		"BatchesWithNegativeQuantity",
		"AvailableBatches",
		"ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, Organization");
		
	CostCalculationUniversalAlgorithms.InitializeNumericalDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters);
		
	CostCalculationUniversalAlgorithms.InitializeOtherDistributionFieldsUsingReducedRemainderMethod(
		DistributionParameters,
		"CorLot, LotVendorAttributesCorr, CorControllingAttributes, CorVATActivityTypes, FinRecordID",
		"Lot, LotVendorAttributes, FinancialAccountingDimension, VATActivityType",
		,
		,
		"BatchDate, Lot");
		
	// We distribute
	CostCalculationAppliedAlgorithms.DistributeByMethodOfReducedResidueWithTimeMeasurement(
		CalculationParameters,
		DistributionParameters,
		"DistributeUsingReducedRemainderMethod",
		"GoodsLotsMisgrading");
		
	If DistributionParameters.DistributionResults.ResultSize = 0 Then
		
		// We will destroy unnecessary temporary tables.
		NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, ExistingTT);
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
		
		Return; // there is no distributed data
		
	EndIf;
	
	#EndRegion
	
	#Region FormationOfRegisteredRecords
	
	Query.Text =
	"SELECT
	|	VALUE(Enum.LotRecordTypes.Consumption) AS EntryType,
	|	&EndOfPeriod AS Period,
	|	TTCostCalculationDocuments.Ref AS Recorder,
	|	TTCostCalculationDocuments.Ref AS DocumentRegisterRecords,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	// Changes
	|	DD.ItemsLocationAttributes,
	|	DD.AccountingSection,
	|	DD.InventoryOwnerAttribute,
	|	DD.Organization,
	|	DD.Lot,
	|	DD.LotVendorAttributes,
	|	DD.FinancialAccountingDimension,
	|	DD.VATActivityType,
	// Resources
	|	DD.Count AS Count,
	|	CAST(DD.Count * ISNULL(Prices.Cost, 0) AS NUMBER(31,2)) AS Cost,
	|	CAST(DD.Count * ISNULL(Prices.CostExcludingVAT, 0) AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.OffBalanceCost, 0) AS NUMBER(31,2)) AS OffBalanceCost,
	|	CAST(DD.Count * ISNULL(Prices.AdditionalExpenseCost, 0) AS NUMBER(31,2)) AS AddExpensesForGoods,
	|	CAST(DD.Count * ISNULL(Prices.AdditionalExpensesCostExcludingVAT, 0) AS NUMBER(31,2)) AS AdditionalExpensesExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.LaborCosts, 0) AS NUMBER(31,2)) AS LaborCosts,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsIncludingVAT, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsIncludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsIncludingVAT, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsIncludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsExcludingVAT, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsExcludingVAT, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.LocalCost, 0) AS NUMBER(31,2)) AS LocalCost,
	|	CAST(DD.Count * ISNULL(Prices.OffBalanceCostLocal, 0) AS NUMBER(31,2)) AS OffBalanceCostLocal,
	|	CAST(DD.Count * ISNULL(Prices.AddExpensesLocal, 0) AS NUMBER(31,2)) AS AddExpensesLocal,
	|	CAST(DD.Count * ISNULL(Prices.LaborCostsLocal, 0) AS NUMBER(31,2)) AS LaborCostsLocal,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsCompl, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsCompl,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsCompl, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsCompl,
	|	CAST(DD.Count * ISNULL(Prices.PermanentDifference, 0) AS NUMBER(31,2)) AS PermanentDifference,
	|	CAST(DD.Count * ISNULL(Prices.CostTD, 0) AS NUMBER(31,2)) AS CostTD,
	|	CAST(DD.Count * ISNULL(Prices.CostOfPersonalIncomeTax, 0) AS NUMBER(31,2)) AS CostOfPersonalIncomeTax,
	|	CAST(DD.Count * ISNULL(Prices.CostMan, 0) AS NUMBER(31,2)) AS CostMan,
	|	CAST(DD.Count * ISNULL(Prices.AddExpensesMan, 0) AS NUMBER(31,2)) AS AddExpensesMan,
	|	CAST(DD.Count * ISNULL(Prices.LaborCostsMan, 0) AS NUMBER(31,2)) AS LaborCostsMan,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsManag, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsManag,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsManag, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsManag,
	// Attributes
	|	VALUE(Enum.BusinessTransactions.GoodsLotsMisgrading) AS BusinessOperation,
	|	DD.ItemsLocationAttributes.WarehouseArea.Department AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.GoodsValueVariance) AS ExpenseItemOfWriteOff,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.GoodsValueVariance) AS IncomeItem,
	|	DD.ItemsLocationAttributes.Products AS DimensionOfExpenses,
	|	DD.ItemsLocationAttributes.Products AS DimensionOfRevenue,
	|	DD.CorVATActivityTypes,
	|	DD.FinRecordID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|
	|INTO TTMovementReSortingOfParties
	|FROM
	|	TTDistributionResult AS DD
	|	INNER JOIN TTCostCalculationDocuments AS TTCostCalculationDocuments
	|		ON TTCostCalculationDocuments.Organization = DD.Organization
	|	LEFT JOIN TTValueOfBatchesOfGoods AS Prices
	|		ON Prices.Organization = DD.Organization
	|		AND Prices.Lot = DD.CorLot
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributesCorr
	|		AND Prices.FinancialAccountingDimension = DD.CorControllingAttributes
	|		AND Prices.VATActivityType = DD.CorVATActivityTypes
	|		AND Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Prices.AccountingSection = DD.AccountingSection
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsLotsMisgrading)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.LotRecordTypes.PurchaseAdjustment) AS EntryType,
	|	&EndOfPeriod AS Period,
	|	TTCostCalculationDocuments.Ref AS Recorder,
	|	TTCostCalculationDocuments.Ref AS DocumentRegisterRecords,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	// Changes
	|	DD.ItemsLocationAttributes,
	|	DD.AccountingSection,
	|	DD.InventoryOwnerAttribute,
	|	DD.Organization,
	|	DD.CorLot AS Lot,
	|	DD.LotVendorAttributesCorr AS LotVendorAttributes,
	|	DD.CorControllingAttributes AS FinancialAccountingDimension,
	|	DD.CorVATActivityTypes AS VATActivityType,
	// Resources
	|	DD.Count AS Count,
	|	CAST(DD.Count * ISNULL(Prices.Cost, 0) AS NUMBER(31,2)) AS Cost,
	|	CAST(DD.Count * ISNULL(Prices.CostExcludingVAT, 0) AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.OffBalanceCost, 0) AS NUMBER(31,2)) AS OffBalanceCost,
	|	CAST(DD.Count * ISNULL(Prices.AdditionalExpenseCost, 0) AS NUMBER(31,2)) AS AddExpensesForGoods,
	|	CAST(DD.Count * ISNULL(Prices.AdditionalExpensesCostExcludingVAT, 0) AS NUMBER(31,2)) AS AdditionalExpensesExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.LaborCosts, 0) AS NUMBER(31,2)) AS LaborCosts,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsIncludingVAT, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsIncludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsIncludingVAT, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsIncludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsExcludingVAT, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsExcludingVAT, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsExcludingVAT,
	|	CAST(DD.Count * ISNULL(Prices.LocalCost, 0) AS NUMBER(31,2)) AS LocalCost,
	|	CAST(DD.Count * ISNULL(Prices.OffBalanceCostLocal, 0) AS NUMBER(31,2)) AS OffBalanceCostLocal,
	|	CAST(DD.Count * ISNULL(Prices.AddExpensesLocal, 0) AS NUMBER(31,2)) AS AddExpensesLocal,
	|	CAST(DD.Count * ISNULL(Prices.LaborCostsLocal, 0) AS NUMBER(31,2)) AS LaborCostsLocal,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsCompl, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsCompl,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsCompl, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsCompl,
	|	CAST(DD.Count * ISNULL(Prices.PermanentDifference, 0) AS NUMBER(31,2)) AS PermanentDifference,
	|	CAST(DD.Count * ISNULL(Prices.CostTD, 0) AS NUMBER(31,2)) AS CostTD,
	|	CAST(DD.Count * ISNULL(Prices.CostOfPersonalIncomeTax, 0) AS NUMBER(31,2)) AS CostOfPersonalIncomeTax,
	|	CAST(DD.Count * ISNULL(Prices.CostMan, 0) AS NUMBER(31,2)) AS CostMan,
	|	CAST(DD.Count * ISNULL(Prices.AddExpensesMan, 0) AS NUMBER(31,2)) AS AddExpensesMan,
	|	CAST(DD.Count * ISNULL(Prices.LaborCostsMan, 0) AS NUMBER(31,2)) AS LaborCostsMan,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedFixedCostsManag, 0) AS NUMBER(31,2)) AS ItemizedFixedCostsManag,
	|	CAST(DD.Count * ISNULL(Prices.ItemizedVariableCostsManag, 0) AS NUMBER(31,2)) AS ItemizedVariableCostsManag,
	// Attributes
	|	VALUE(Enum.BusinessTransactions.GoodsLotsMisgrading) AS BusinessOperation,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS ExpenseItemOfWriteOff,
	|	UNDEFINED AS IncomeItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DD.VATActivityType AS CorVATActivityTypes,
	|	DD.FinRecordID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	TTDistributionResult AS DD
	|	INNER JOIN TTCostCalculationDocuments AS TTCostCalculationDocuments
	|		ON TTCostCalculationDocuments.Organization = DD.Organization
	|	LEFT JOIN TTValueOfBatchesOfGoods AS Prices
	|		ON Prices.Organization = DD.Organization
	|		AND Prices.Lot = DD.CorLot
	|		AND Prices.LotVendorAttributes = DD.LotVendorAttributesCorr
	|		AND Prices.FinancialAccountingDimension = DD.CorControllingAttributes
	|		AND Prices.VATActivityType = DD.CorVATActivityTypes
	|		AND Prices.ItemsLocationAttributes = DD.ItemsLocationAttributes
	|		AND Prices.InventoryOwnerAttribute = DD.InventoryOwnerAttribute
	|		AND Prices.AccountingSection = DD.AccountingSection
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON BusinessTransactionsSettings.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsLotsMisgrading)
	|INDEX BY
	|	Recorder
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	TempTableName = "TTOfCostRegisterRecordsReSortingOfLotReferences";
	RegisterName = Metadata.AccumulationRegisters.InventoryCost.Name;
	ReceiverDescription = CalculationParameters.RegisterRecords[RegisterName];
	TemporaryTableNameSource = "TTMovementReSortingOfParties";
	
	CopiedFields = CostCalculationUniversalAlgorithms.GetColumnNamesOfTemporaryTableByString(CalculationParameters, TemporaryTableNameSource);
	
	FieldDescriptionTable = CostCalculationAppliedAlgorithms.GenerateDescriptionOfRequestFields(ReceiverDescription.Table);
	CostCalculationAppliedAlgorithms.CopyRequestFields(FieldDescriptionTable, CopiedFields);
	
	CostCalculationAppliedAlgorithms.MakeRequestForFieldDescriptions(CalculationParameters, FieldDescriptionTable, 
		RegisterName, TemporaryTableNameSource, TempTableName);
	
	MatchingTemporaryMovementTables = New Map;
	MatchingTemporaryMovementTables.Insert(TempTableName, RegisterName);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.CacheGeneratedRegisteredRecordsFromTemporaryTables(CalculationParameters, MatchingTemporaryMovementTables);
	
	// We will destroy unnecessary temporary tables.
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters, ExistingTT);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
EndProcedure

#EndRegion

#Region StageProcedure_ReverseOrderOfCalculationOfBatchesOfCorrectedDocuments

Procedure ReverseOrderOfCalculationOfBatchesOfCorrectedDocuments(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "ReverseOrderOfCalculationOfBatchesOfCorrectedDocuments");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.AccumulationRegisters.InventoryCost.Name);
	
	// 2. Getting the source data for the broadcast
	// 	- generates a temporary Data table.	
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForReverseBatchCalculationCostOfGoods(CalculationParameters));
		
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

// Getting data for movements in the "Cost of goods" register.

Function RequestTextForReverseBatchCalculationCostOfGoods(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// preparation of temporary tables
		+ TextCorrectedDocuments() // tue Corrected documents
		+ Common.QueryBatchSeparator() + TextCorrectedProductionBatches()
		+ Common.QueryBatchSeparator()
		// Sample data
		+ TextDescriptionOfDataForBatchesOfGoods() // w Data
		+ TMCommonUse.QuerySeparatorInJoin() + TextReverseMovementCalculationOfBatchesCostOfGoods()
		+ "";
	
	Return QueryText;
	
EndFunction

// Returns the request text.
// 
// Returns:
// 	String - Query text
//
Function TextCorrectedProductionBatches() // tue Fixed Production parties
	
	Return "	
		|SELECT DISTINCT
		|	DD.ReversedDocument AS DocumentSource,
		|	ProductionLots.Ref AS Lot,
		|	ProductionLots.LineOfBusiness AS LineOfBusiness,
		|	DD.Period,
		|	DD.Recorder
		|INTO CorrectedProductionBatches
		|FROM
		|	CorrectedDocuments_ AS DD
		|	INNER JOIN Catalog.ProductionLots AS ProductionLots
		|		ON ProductionLots.Document = DD.ReversedDocument
		|";
EndFunction

Function TextReverseMovementCalculationOfBatchesCostOfGoods() Export // uses corrected documents
	Return 
		"SELECT
		|	""TextReverseMovementCalculationOfBatchesCostOfGoods_1"" AS RequestSource,
		|	RegisterData.EntryType						AS EntryType,
		|	FALSE											AS ThisIsExactlyCalculatedMovement,
		|	FALSE											AS ThisIsReverseTransaction,
		|	0 												AS Priority,
		|	0 												AS Denominator,
		|	TRUE 											AS CalculationIsCompleted,
		|	VALUE(Catalog.Products.EmptyRef)  AS Products,
		|	UNDEFINED							 		AS TaxationOfParty,
		|	CorrectedDocuments_.Period,
		|	CorrectedDocuments_.Period AS ReceiptPeriod,
		|	RegisterData.VariancePeriod AS VariancePeriod,
		|	CorrectedDocuments_.Recorder,
		|	RegisterData.RecordType,
		|
		|	RegisterData.ItemsLocationAttributes,
		|	RegisterData.AccountingSection,
		|	RegisterData.InventoryOwnerAttribute,
		|	RegisterData.Organization,
		|	RegisterData.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	RegisterData.LotVendorAttributes,
		|	RegisterData.FinancialAccountingDimension,
		|	RegisterData.VATActivityType,
		|
		|	-RegisterData.Count,
		|	-RegisterData.Cost,
		|	-RegisterData.CostExcludingVAT,
		|	-RegisterData.OffBalanceCost,
		|	-RegisterData.CostMan,
		|	-RegisterData.AddExpensesMan,
		|	-RegisterData.ItemizedVariableCostsIncludingVAT,
		|	-RegisterData.ItemizedVariableCostsExcludingVAT,
		|	-RegisterData.LaborCostsMan,
		|	-RegisterData.ItemizedFixedCostsManag,
		|	-RegisterData.ItemizedVariableCostsManag,
		|	-RegisterData.AddExpensesForGoods,
		|	-RegisterData.AdditionalExpensesExcludingVAT,
		|	-RegisterData.LaborCosts,
		|	-RegisterData.ItemizedFixedCostsIncludingVAT,
		|	-RegisterData.ItemizedFixedCostsExcludingVAT,
		|	-RegisterData.LocalCost,
		|	-RegisterData.OffBalanceCostLocal,
		|	-RegisterData.PermanentDifference,
		|	-RegisterData.CostTD,
		|	-RegisterData.CostOfPersonalIncomeTax,
		|	-RegisterData.AddExpensesLocal,
		|	-RegisterData.LaborCostsLocal,
		|	-RegisterData.ItemizedFixedCostsCompl,
		|	-RegisterData.ItemizedVariableCostsCompl,
		|	-RegisterData.ProvisionForImpairmentLocal,
		|	-RegisterData.ProvisionForImpairmentMan,
		|
		|	RegisterData.BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	RegisterData.CorItemsLocationAttributes,
		|	RegisterData.CorAccountingSection,
		|	RegisterData.CorInventoryOwnerAttribute,
		|	RegisterData.CorCompany,
		|	RegisterData.CorGrossInitialCostENT,
		|	RegisterData.AccountingDimensionByPartners,
		|	RegisterData.SalesOrder,
		|	RegisterData.Department,
		|	RegisterData.DimensionOfExpenses,
		|	RegisterData.ExpenseItemOfWriteOff,
		|	RegisterData.IncomeItem,
		|	RegisterData.DimensionOfRevenue,
		|	RegisterData.SalePeriod,
		|	RegisterData.AssetAndLiabilityItem,
		|	RegisterData.AssetsLiabilitiesDimension,
		|	RegisterData.DocumentRegisterRecords,
		|	RegisterData.RowID,
		|	RegisterData.ProductsGroup,
		|	RegisterData.CorLot,
		|	RegisterData.LotVendorAttributesCorr,
		|	RegisterData.CorControllingAttributes,
		|	RegisterData.CorVATActivityTypes,
		|	RegisterData.DocumentVATActivityType,
		|	RegisterData.VATActivityTypeShipments,
		|	RegisterData.FinancialAccountingDimensionOfDocument,
		|	RegisterData.CostAccountingTransaction,
		|	-RegisterData.VATManag,
		|	-RegisterData.VATLocal,
		|	RegisterData.ProductCostElement,
		|	RegisterData.DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	RegisterData.CorLineOfBusiness,
		|	RegisterData.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	RegisterData.BusinessTransactionSetting,
		|	RegisterData.FinRecordID,
		|	RegisterData.GLAccountSettings,
		|	TRUE AS ReversingEntry,
		|	RegisterData.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	RegisterData.CostDefiningMethod,
		|	RegisterData.CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS RegisterData
		|	
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON RegisterData.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	
		|	INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON CorrectedDocuments_.ReversedDocument = RegisterData.Recorder
		|
		|WHERE
		|	RegisterData.Organization IN (&CompanyArray)
		|	AND RegisterData.Period < &BeginOfPeriod
		|	AND RegisterData.Active
		|	AND (RegisterData.EntryType IN (
		|		VALUE(Enum.LotRecordTypes.CostVariance),
		|		VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|		VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|		VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost),
		|		VALUE(Enum.LotRecordTypes.ProductionIssue))
		// An additional condition for the incoming Registered Records on the Doc-tu distribution of returnable waste.
		|		OR (RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
		|		)
		|	AND NOT RegisterData.CalculationOfCost
		|	AND RegisterData.LotCalculation
		|	AND NOT RegisterData.ReversingEntry
		|	AND NOT (&BatchAccountingWasUsedBeforeSwitchingToVersion22 = TRUE // the parameter value can be UNDEFINED
		|		AND RegisterData.Period < &DateOfMigrationToBatchAccounting22)
		|
		|
		// Storno quantitative Registered Recorded distribution of materials for release using the method of evaluation "Medium-slip".
		// The initial Registered Records for distribution to the issue are formed under the documents "Cost Calculation Register",
		// therefore, a separate reversal of such records is required.
		|UNION ALL
		|
		|SELECT
		|	""TextReverseMovementCalculationOfBatchesCostOfGoods_2"" AS RequestSource,
		|	RegisterData.EntryType						AS EntryType,
		|	FALSE											AS ThisIsExactlyCalculatedMovement,
		|	TRUE											AS ThisIsReverseTransaction,
		|	0 												AS Priority,
		|	0 												AS Denominator,
		|	TRUE 											AS CalculationIsCompleted,
		|	VALUE(Catalog.Products.EmptyRef)  AS Products,
		|	UNDEFINED							 		AS TaxationOfParty,
		|	CorrectedProductionBatches.Period			AS Period,
		|	CorrectedProductionBatches.Period			AS ReceiptPeriod,
		|	RegisterData.VariancePeriod					AS VariancePeriod,
		|	CalculationLoggers.Ref						AS Recorder,
		|
		|	RegisterData.RecordType,
		|
		|	RegisterData.ItemsLocationAttributes,
		|	RegisterData.AccountingSection,
		|	RegisterData.InventoryOwnerAttribute,
		|	RegisterData.Organization,
		|	RegisterData.Lot,
		|	UNDEFINED AS ProductionOrder,
		|	RegisterData.LotVendorAttributes,
		|	RegisterData.FinancialAccountingDimension,
		|	RegisterData.VATActivityType,
		|
		|	-RegisterData.Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.ProductionCostsReverseTransaction),
		|	UNDEFINED AS PriorityBusinessOperation,
		|	RegisterData.CorItemsLocationAttributes,
		|	RegisterData.CorAccountingSection,
		|	RegisterData.CorInventoryOwnerAttribute,
		|	RegisterData.CorCompany,
		|	RegisterData.CorGrossInitialCostENT,
		|	RegisterData.AccountingDimensionByPartners,
		|	RegisterData.SalesOrder,
		|	RegisterData.Department,
		|	RegisterData.DimensionOfExpenses,
		|	RegisterData.ExpenseItemOfWriteOff,
		|	RegisterData.IncomeItem,
		|	RegisterData.DimensionOfRevenue,
		|	RegisterData.SalePeriod,
		|	RegisterData.AssetAndLiabilityItem,
		|	RegisterData.AssetsLiabilitiesDimension,
		|	RegisterData.DocumentRegisterRecords,
		|	RegisterData.RowID,
		|	RegisterData.ProductsGroup,
		|	RegisterData.CorLot,
		|	RegisterData.LotVendorAttributesCorr,
		|	RegisterData.CorControllingAttributes,
		|	RegisterData.CorVATActivityTypes,
		|	RegisterData.DocumentVATActivityType,
		|	RegisterData.VATActivityTypeShipments,
		|	RegisterData.FinancialAccountingDimensionOfDocument,
		|	RegisterData.CostAccountingTransaction,
		|	0,
		|	0,
		|	RegisterData.ProductCostElement,
		|	RegisterData.DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	RegisterData.CorLineOfBusiness,
		|	RegisterData.RowCode,
		|	UNDEFINED AS CCDNumber,
		|	VALUE(Catalog.BusinessTransactionsSettings.ProductionCostsReverseTransaction),
		|	RegisterData.FinRecordID,
		|	RegisterData.GLAccountSettings,
		|	TRUE AS ReversingEntry,
		|	RegisterData.LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	RegisterData.CostDefiningMethod,
		|	RegisterData.CostCalculationDate
		|FROM
		|	AccumulationRegister.InventoryCost AS RegisterData
		|	INNER JOIN CorrectedProductionBatches AS CorrectedProductionBatches
		|		ON CorrectedProductionBatches.Lot = RegisterData.Lot
		|	INNER JOIN TTCostCalculationRecorders AS CalculationLoggers
		|		ON CalculationLoggers.Organization = RegisterData.Organization
		|WHERE
		|	RegisterData.Organization IN (&MediumSlipOrganizations)
		|	AND RegisterData.Period < &BeginOfPeriod
		|	AND RegisterData.Active
		|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.CostAllocationToProductionLots)
		|	AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
		|	AND NOT RegisterData.CalculationOfCost
		|	AND RegisterData.LotCalculation
		|	AND NOT RegisterData.ReversingEntry
		|	AND VALUETYPE(RegisterData.Recorder) = TYPE(Document.CostCalculationRecorder)
		|";
EndFunction

#EndRegion

#Region StageProcedure_PreparationOfDataForPreliminaryCostCalculation

// Request texts

// ... general

Function TextOfRequestForDataPreparationForPreliminaryCostCalculation(CalculationParameters = Undefined) Export
	
	QueryText = ""
		+ TextTTGoodsToTransfer()
		+ Common.QueryBatchSeparator()
		// Sample data
		+ TextDescriptionOfDataForBatchesOfGoods() //w Data
		+ TMCommonUse.QuerySeparatorInJoin() + TextGoodsToTransferExpense()
		+ TMCommonUse.QuerySeparatorInJoin() + TextOfGoodsToTransferParish()
		+ "";
	
	Return QueryText;
	
EndFunction

Function TextTTGoodsToTransfer() // TTGoodsToTransfer
	Return
		"SELECT
		|	ProductsSold.CompanyOwner            AS CompanyCustomer,
		|	ProductsSold.SellerInventoryOwnerAttribute.Organization AS CompanyRecipient,
		|	ProductsSold.ItemsLocationAttributes     AS ItemsLocationAttributes,
		|	SUM(ProductsSold.CountBalance)       AS Count,
		|	ProductsSold.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner            AS SellerInventoryOwnerAttribute,
		|	ProductsSold.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType AS SellerSInventoryType,
		|	ProductsSold.SellerInventoryOwnerAttribute 								  AS RecipientInventoryOwnerAttribute,
		|	ProductsSold.SellerInventoryOwnerAttribute.InventoryType					  AS RecipientInventoryType
		|
		|INTO TTGoodsToTransfer
		|FROM
		|	AccumulationRegister.CompanyGoodsForTransfer.Balance(&BorderEndOfPeriod,
		|		CompanyOwner IN (&CompanyArray)
		|		AND SellerInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|		AND (&MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|			OR &ScheduledJob)
		|	) AS ProductsSold
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON ProductsSold.CompanyOwner = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|
		|GROUP BY
		|	ProductsSold.CompanyOwner,
		|	ProductsSold.SellerInventoryOwnerAttribute.Organization,
		|	ProductsSold.ItemsLocationAttributes,
		|	ProductsSold.SellerInventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	ProductsSold.SellerInventoryOwnerAttribute
		|
		|UNION ALL
		|
		|SELECT
		|	Reserves.Organization                            AS CompanyCustomer,
		|	Reserves.CorCompany                         AS CompanyRecipient,
		|	Reserves.ItemsLocationAttributes             AS ItemsLocationAttributes,
		|	SUM(Reserves.Count)                      AS Count,
		|	Reserves.InventoryOwnerAttribute                             AS SellerInventoryOwnerAttribute,
		|	Reserves.InventoryOwnerAttribute.InventoryType                  AS SellerSInventoryType,
		|	Reserves.CorInventoryOwnerAttribute                          AS RecipientInventoryOwnerAttribute,
		|	Reserves.CorInventoryOwnerAttribute.InventoryType               AS RecipientInventoryType
		|
		|FROM
		|	AccumulationRegister.CompanySafeStock AS Reserves
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON Reserves.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	Reserves.Period BETWEEN &BeginOfPeriod AND ENDOFPERIOD(&EndOfPeriod, MONTH)
		|	AND Reserves.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Reserves.Organization IN (&CompanyArray)
		|	AND Reserves.CorInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
		|	AND (&MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|		OR &ScheduledJob)
		|
		|GROUP BY
		|	Reserves.Organization,
		|	Reserves.CorCompany,
		|	Reserves.ItemsLocationAttributes,
		|	Reserves.InventoryOwnerAttribute,
		|	Reserves.CorInventoryOwnerAttribute
		|";
EndFunction

Function TextGoodsToTransferExpense() // uses vttovarytransmission
	QueryText =
		"SELECT
		|	""TextGoodsToTransferExpense"" 	  				 			 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.ConsumptionLotCalculation)	 AS EntryType,
		|	FALSE														 AS ThisIsExactlyCalculatedMovement,
		|	FALSE														 AS ThisIsReverseTransaction,
		|	10 										  					 AS Priority,
		|	0								  							 AS Denominator,
		|	(CASE
		|		WHEN &ScheduledJob THEN TRUE
		|		ELSE FALSE END)										 AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					 AS Products,
		|	UNDEFINED 												 AS TaxationOfParty,
		|
		|	&EndOfPeriod AS Period,
		|	&BeginOfPeriod AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS VariancePeriod,
		|	TTCostCalculationDocuments.Ref AS Recorder,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	(CASE 
		|		WHEN DD.SellerSInventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
		|		WHEN DD.SellerSInventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
		|		WHEN DD.SellerSInventoryType IN
		|				(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		WHEN DD.SellerSInventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
		|		WHEN ISNULL(DD.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
		|	END) AS AccountingSection,
		|	DD.SellerInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.CompanyCustomer AS Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		|
		|	DD.Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany) AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	DD.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	(CASE 
		|		WHEN DD.RecipientInventoryOwnerAttribute = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
		|		WHEN DD.RecipientInventoryOwnerAttribute = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
		|		WHEN DD.RecipientInventoryOwnerAttribute IN
		|				(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		WHEN DD.RecipientInventoryOwnerAttribute = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
		|		WHEN ISNULL(DD.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
		|	END) AS CorAccountingSection,
		|	DD.RecipientInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	DD.CompanyRecipient AS CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS DocumentRegisterRecords,
		|	"""" AS RowID,
		|	UNDEFINED AS ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	AccountingPoliciesOfOrganizations_.DefaultVATTaxation AS CorVATActivityTypes,
		|	AccountingPoliciesOfOrganizations_.DefaultVATTaxation AS DocumentVATActivityType,
		|	UNDEFINED AS VATActivityTypeShipments,
		|	UNDEFINED AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED AS CostAccountingTransaction,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	UNDEFINED AS CorLineOfBusiness,
		|	0 AS RowCode,
		|	UNDEFINED AS CCDNumber,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" FinRecordID,
		|	UNDEFINED AS GLAccountSettings,
		|	FALSE AS ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	UNDEFINED AS CostDefiningMethod,
		|	DATETIME(1,1,1) AS CostCalculationDate
		|FROM
		|	TTGoodsToTransfer AS DD
		|	INNER JOIN TTCostCalculationDocuments AS TTCostCalculationDocuments
		|		ON TTCostCalculationDocuments.Organization = DD.CompanyCustomer
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations_
		|		ON DD.CompanyRecipient = AccountingPoliciesOfOrganizations_.Organization
		|";
	Return QueryText;
EndFunction

Function TextOfGoodsToTransferParish() // uses vttovarytransmission
	QueryText =
		"SELECT
		|	""TextOfGoodsToTransferParish"" 	  				 			 AS RequestSource,
		|	VALUE(Enum.LotRecordTypes.TransferAuto)	 AS EntryType,
		|	FALSE														 AS ThisIsExactlyCalculatedMovement,
		|	FALSE														 AS ThisIsReverseTransaction,
		|	10 										  					 AS Priority,
		|	0								  							 AS Denominator,
		|	TRUE 														 AS CalculationIsCompleted,
		|	DD.ItemsLocationAttributes.Products 					 AS Products,
		|	UNDEFINED 												 AS TaxationOfParty,
		|
		|	&EndOfPeriod AS Period,
		|	&BeginOfPeriod AS ReceiptPeriod,
		|	DATETIME(1,1,1) AS VariancePeriod,
		|	TTCostCalculationDocuments.Ref AS Recorder,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DD.ItemsLocationAttributes,
		|	(CASE 
		|		WHEN DD.RecipientInventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
		|		WHEN DD.RecipientInventoryType = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
		|		WHEN DD.RecipientInventoryType IN
		|				(VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|				VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
		|		WHEN DD.RecipientInventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
		|		WHEN ISNULL(DD.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
		|	END) AS AccountingSection,
		|	DD.RecipientInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DD.CompanyRecipient AS Organization,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductionOrder,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	AccountingPoliciesOfOrganizations_.DefaultVATTaxation AS VATActivityType,
		|
		|	DD.Count,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ProvisionForImpairmentLocal,
		|	0 AS ProvisionForImpairmentMan,
		|
		|	VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany) AS BusinessOperation,
		|	UNDEFINED AS PriorityBusinessOperation,
		|	UNDEFINED AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorAccountingSection,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	UNDEFINED AS CorCompany,
		|	0 AS CorGrossInitialCostENT,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS Department,
		|	UNDEFINED AS DimensionOfExpenses,
		|	UNDEFINED AS ExpenseItemOfWriteOff,
		|	UNDEFINED AS IncomeItem,
		|	UNDEFINED AS DimensionOfRevenue,
		|	UNDEFINED AS SalePeriod,
		|	UNDEFINED AS AssetAndLiabilityItem,
		|	UNDEFINED AS AssetsLiabilitiesDimension,
		|	UNDEFINED AS DocumentRegisterRecords,
		|	"""" AS RowID,
		|	UNDEFINED AS ProductsGroup,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		|	UNDEFINED AS DocumentVATActivityType,
		|	UNDEFINED AS VATActivityTypeShipments,
		|	UNDEFINED AS FinancialAccountingDimensionOfDocument,
		|	UNDEFINED AS CostAccountingTransaction,
		|	0 AS VATManag,
		|	0 AS VATLocal,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS DocumentSource,
		|	UNDEFINED AS PrioritySource,
		|	UNDEFINED AS CorLineOfBusiness,
		|	0 AS RowCode,
		|	UNDEFINED AS CCDNumber,
		|	UNDEFINED AS BusinessTransactionSetting,
		|	"""" FinRecordID,
		|	UNDEFINED AS GLAccountSettings,
		|	FALSE AS ReversingEntry,
		|	FALSE AS LotCalculationPerformed,
		|	UNDEFINED AS MonthEndClosingMode,
		|	UNDEFINED AS CostDefiningMethod,
		|	DATETIME(1,1,1) AS CostCalculationDate
		|FROM
		|	TTGoodsToTransfer AS DD
		|	INNER JOIN TTCostCalculationDocuments AS TTCostCalculationDocuments
		|		ON TTCostCalculationDocuments.Organization = DD.CompanyRecipient
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations_
		|		ON DD.CompanyRecipient = AccountingPoliciesOfOrganizations_.Organization
		|";
	Return QueryText;
EndFunction

#EndRegion

#Region StageProcedures_Contextual

// Used for all calls to fill in the billing batch.
//
Procedure FillInSettlementBatch(CalculationParameters, Context, SettlementBatch, Expense, Receipt, BatchIsFull) Export
	
	If Context = "InvoicingOfDeliveries" Then
		FillInEstimatedBatchOfInvoicesForDeliveries(CalculationParameters, SettlementBatch, Expense, Receipt);
		BatchIsFull = True;
	ElsIf Context = "FillingOfLotsInRegisterCostOfGoods" Then
		FillInEstimatedBatchCostOfGoods(CalculationParameters, SettlementBatch, Expense, Receipt);
		BatchIsFull = True;
	ElsIf Context = "FillingOfLotsInRegisterRevenueAndCostOfSales" Then
		FillInEstimatedBatchOfRevenueAndCostOfSales(CalculationParameters, SettlementBatch, Expense, Receipt);
		BatchIsFull = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Testing

// Supplements the list of orders with the distribution of parties.
//
// Parameters:
//	StageList - ValueList - list of stages with the distribution of parties
//
Procedure SupplementStagesWithDistributionOfBatches(StageList) Export
	
	StageList.Add("InvoicingOfDeliveries");
	StageList.Add("FillingOfLotsInRegisterCostOfGoods");
	StageList.Add("FillingOfLotsInRegisterRevenueAndCostOfSales");
	StageList.Add("ReverseOrderOfCalculationOfBatchesOfCorrectedDocuments");
	
EndProcedure

// Complements the list of releases with the broadcast of the games.
//
// Parameters:
//	StageList - ValueList - list of stages with broadcast parties
//
Procedure AddStagesWithBatchTranslation(StageList) Export
	
	StageList.Add("PreparationOfDataForPreliminaryCostCalculation");
	
EndProcedure

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList of String- 
//
Procedure ComplementStepsWithDataPreparationForFollowingSteps(StageList) Export
	
	StageList.Add("InvoicingOfDeliveriesAtMediumSlip_FormationOfRegisteredRecorded");
	
EndProcedure

Procedure RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText) Export
	
	If StageName_ = "InvoicingOfDeliveries" Then
		QueryText = TextOfRequestForInvoicingDeliveries(CalculationParameters);
		
	ElsIf StageName_ = "FillingOfLotsInRegisterCostOfGoods" Then
		QueryText = RequestTextForBatchesOfGoods(CalculationParameters);
		
	ElsIf StageName_ = "FillingOfLotsInRegisterRevenueAndCostOfSales" Then
		QueryText = RequestTextForRevenueBatches(CalculationParameters);
		
	ElsIf StageName_ = "ReverseOrderOfCalculationOfBatchesOfCorrectedDocuments" Then
		QueryText = RequestTextForReverseBatchCalculationCostOfGoods(CalculationParameters);
		
	ElsIf StageName_ = "InvoicingOfDeliveriesAtMediumSlip_FormationOfRegisteredRecorded" Then
		QueryText = InvoicingOfDeliveriesWithMediumSlipFormationOfRegisteredRecords(CalculationParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
