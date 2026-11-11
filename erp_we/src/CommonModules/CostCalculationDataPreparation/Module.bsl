#Region Public

// Stage of preparation for calculation
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfInitialDataForCalculation(CalculationParameters) Export
	
	CostCalculationDataPreparationLocalization.PreparationOfInitialDataForCalculation(CalculationParameters);
	
	RecheckDocumentsByRegisters(CalculationParameters);
	
	// We will fix the problems in the movements and in the documents themselves in the calculated period.
	FixProblemsInRegisteredRecordsAndDocuments(CalculationParameters);
	
	ClearManRegistersData(CalculationParameters);
	
	// Let's check the correctness of the initial data for the calculation.
	CostCalculationAppliedAlgorithms.CheckCorrectnessOfSourceDataBeforeCalculation(CalculationParameters);
	
	// Update the register caches whose data has been changed in this procedure.
	// When using a sliding average estimate, any registers on which Register Records of the documents being corrected can be changed.
	CostCalculationAppliedAlgorithms.UpdateCalculatedRegisterCaches_(
		CalculationParameters,
		Not CalculationOfCostCached.MediumSlipValuationIsUsed());
	
EndProcedure

#EndRegion

#Region Private

Procedure RecheckDocumentsByRegisters(CalculationParameters)
	
	// Re-checking of documents is performed in autotests on a file database.
	If Not CalculationParameters.AutoTesting
	 Or Not CalculationOfCostCached.ValuesOfTechnologicalParameters().SendDocumentsToRegisters Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "RecheckDocumentsByRegisters");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	#Region CostOfGoods_RevenueAndCostOfSales
	
	Query.Text = "
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	DD.Recorder           AS Ref,
	|	DD.Organization           AS Organization,
	|	1						 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND NOT DD.LotCalculation
	|	AND NOT DD.CalculationOfCost
	|	AND NOT DD.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""RevenueAndCOGS""	         AS RegisterName,
	|	DD.Recorder                           AS Ref,
	|	DD.AccountingDimensionByPartners.Organization AS Organization,
	|	2							             AS ErrorCode
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS DD
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.AccountingDimensionByPartners.Organization IN (&CompanyArray)
	|	AND NOT DD.LotCalculation
	|	AND NOT DD.CalculationOfCost
	|	AND NOT DD.AccountingDimensionByPartners.Organization IN (&MediumSlipOrganizations)
	|";
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Kết chuyển lại các chứng từ theo biểu ghi ""Giá vốn hàng hóa"" khi tự động thử nghiệm';
										|ru = 'Перепроведение документов по регистру ""Себестоимость товаров"" при автотестировании';
										|en = 'Repost documents in the ""Inventory cost"" register upon automatic testing'; fa = 'Repost documents in the ""Inventory cost"" register upon automatic testing';
										|it = 'Ripubblicazione documenti per il registro ""Prezzo di costo merce"" durante l''autotest';
										|pl = 'Ponowne zatwierdzenie dokumentów według rejestru ""Koszt własny towarów"" podczas testowania automatycznego';
										|tr = 'Otomatik test sırasında ""Stok maliyeti"" kaydındaki belgelerin yeniden kaydedilmesi'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Kết chuyển lại các chứng từ theo biểu ghi ""Doanh thu và giá vốn hàng bán"" khi tự động thử nghiệm';
										|ru = 'Перепроведение документов по регистру ""Выручка и себестоимость продаж"" при автотестировании';
										|en = 'Repost documents in the ""Revenue and cost of goods sold"" register upon automatic testing'; fa = 'Repost documents in the ""Revenue and cost of goods sold"" register upon automatic testing';
										|it = 'Ripubblicazione dei documenti per il registro ""Profitto e prezzo di costo della vendita"" durante l''autotest';
										|pl = 'Ponowne zatwierdzenie dokumentów według rejestru ""Utarg i koszt własny sprzedaży"" podczas testowania automatycznego';
										|tr = 'Otomatik test sırasında ""Gelir ve satışların Maliyeti"" kaydındaki belgelerin yeniden kaydedilmesi'", Common.DefaultLanguageCode()));
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'kết chuyển lại các chứng từ theo biểu ghi khi tự động thử nghiệm';
			|ru = 'перепроведение документов по регистрам при автотестировании';
			|en = 'repost documents in registers upon automatic testing'; fa = 'repost documents in registers upon automatic testing';
			|it = 'ripubblicazione dei documenti per registri durante l''autotest';
			|pl = 'ponowne zatwierdzenie dokumentów według rejestrów podczas testowania automatycznego';
			|tr = 'otomatik test sırasında belgelerin siciller tarafından yeniden kaydedilmesi'", Common.DefaultLanguageCode()),
		Undefined, // Additional field
		True // Re-examination only
		);
		
	#EndRegion
	
	#Region OtherExpenses
	
	Query.SetParameter("TypesOfDocumentsAboutSiIa", CostCalculationAppliedAlgorithms.TypesOfDocumentsAboutSiIa());
	
	TypesOfRecordersWithNonStandardLogicOfRegisteringRecordedMovements = New Array();
	CostCalculationDataPreparationLocalization.ToSupplementTypesOfRecordersWithNonStandardLogicOfFormationOfRegisteredRecords(
		TypesOfRecordersWithNonStandardLogicOfRegisteringRecordedMovements);
	
	Query.SetParameter("TypesOfDocumentsAreRoutine", CommonClientServer.ArraysDifference(
		CostCalculationAppliedAlgorithms.TypesOfDocumentsAreRoutine(),
		TypesOfRecordersWithNonStandardLogicOfRegisteringRecordedMovements));
	
	Query.Text = "
	|SELECT
	|	MIN(DD.Period) AS Period,
	|	DD.Recorder AS Ref,
	|	DD.Organization AS Organization
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND NOT DD.LotCalculation
	|	AND NOT DD.CalculationOfCost
	|	AND NOT VALUETYPE(DD.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND NOT VALUETYPE(DD.Recorder) IN (&TypesOfDocumentsAreRoutine)
	|	AND NOT DD.Organization IN (&MediumSlipOrganizations)
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization
	|
	|UNION // the same documents can be selected in both queries
	|
	|SELECT
	|	MIN(DD.Period) AS Period,
	|	DD.Recorder AS Ref,
	|	DD.Organization AS Organization
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD
	|	INNER JOIN Document.SubcontractorReport2_5 AS SubcontractorReport
	|		ON SubcontractorReport.Ref = DD.Recorder
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND DD.CalculationOfCost
	|	AND NOT DD.Organization IN (&MediumSlipOrganizations)
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization
	|
	|ORDER BY
	|	Period ASC,
	|	Ref
	|";
	SelectionOfDocuments = Query.Execute().Select();
	
	RegisterDescription = CalculationParameters.RegisterRecords[Metadata.AccumulationRegisters.OtherExpenses.Name];
	RegisterDescription.ItIsNecessaryToUpdateCalculatedCache = True;
	
	CostCalculationAppliedAlgorithms.RestoreMovementOfDocumentsInAccumulationRegister(
		CalculationParameters, 
		SelectionOfDocuments, 
		Metadata.AccumulationRegisters.OtherExpenses.Name);
		
	#EndRegion
	
	#Region ItemisedExpensesLots
	
	Query.Text = "
	|SELECT
	|	MIN(DD.Period) AS Period,
	|	DD.Recorder AS Ref,
	|	DD.Organization AS Organization
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS DD
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND NOT DD.LotCalculation
	|	AND NOT DD.CalculationOfCost
	|	AND NOT VALUETYPE(DD.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND NOT DD.Organization IN (&MediumSlipOrganizations)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization
	|
	|ORDER BY
	|	Period ASC,
	|	Ref
	|";
	SelectionOfDocuments = Query.Execute().Select();
	
	RegisterDescription = CalculationParameters.RegisterRecords[Metadata.AccumulationRegisters.ItemisedExpensesLots.Name];
	RegisterDescription.ItIsNecessaryToUpdateCalculatedCache = True;
	
	CostCalculationAppliedAlgorithms.RestoreMovementOfDocumentsInAccumulationRegister(
		CalculationParameters, 
		SelectionOfDocuments, 
		Metadata.AccumulationRegisters.ItemisedExpensesLots.Name);
		
	#EndRegion
	
	#Region OtherIncome
	
	Query.Text = "
	|SELECT
	|	MIN(DD.Period) AS Period,
	|	DD.Recorder AS Ref,
	|	DD.Organization AS Organization
	|FROM
	|	AccumulationRegister.OtherIncome AS DD
	|WHERE
	|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DD.Organization IN (&CompanyArray)
	|	AND NOT DD.CalculationOfCost
	|	AND NOT VALUETYPE(DD.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND NOT VALUETYPE(DD.Recorder) IN (&TypesOfDocumentsAreRoutine)
	|	AND NOT DD.Organization IN (&MediumSlipOrganizations)
	|
	|GROUP BY
	|	DD.Recorder,
	|	DD.Organization
	|
	|ORDER BY
	|	Period ASC,
	|	Ref
	|";
	SelectionOfDocuments = Query.Execute().Select();
	
	RegisterDescription = CalculationParameters.RegisterRecords[Metadata.AccumulationRegisters.OtherIncome.Name];
	RegisterDescription.ItIsNecessaryToUpdateCalculatedCache = True;
	
	CostCalculationAppliedAlgorithms.RestoreMovementOfDocumentsInAccumulationRegister(
		CalculationParameters, 
		SelectionOfDocuments, 
		Metadata.AccumulationRegisters.OtherIncome.Name);
		
	#EndRegion
	
EndProcedure

// A mechanism similar in purpose to the is update mechanism.
// It is performed when calculating a specific period and corrects documents only for this period.
//
// Fixes problems in document movements and in the documents themselves in the calculated period.
//
// There are errors that "spoil" the original data for the calculation,
// but the update handler is not written to correct their consequences.
// For example, due to some old error, in some cases the document movements were incorrect.
// - if you write an update handler to fix this error,
// it will change the data of past "closed" periods, which means that these periods will no longer be "closed".
// You will have to re-close these periods, which may change their cost and, as a result,
// regulated reporting. This is bad, because for these periods, reports may already be submitted.
// - on the other hand, in the periods that the user will recalculate, this error in movements should be corrected
// so that in these recalculated periods, the cost price is based on the correct source data.
//
// This procedure is intended to correct such errors.
// In fact, it is an analog of the update handler that corrects document movements in the period specified by the user.
//
// This procedure is also used to adjust the period movements when recalculating it in batch accounting version 2.2.
Procedure FixProblemsInRegisteredRecordsAndDocuments(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "FixProblemsInRegisteredRecordsAndDocuments");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	ExistingTtToStage = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query);
	
	#Region BatchAccountingFieldsVersion22
	
	// We will check in the primary movements of the documents the correctness of filling in the fields:
	// Party, Corporation, type records, party accounting analytics, type of VAT activity.
	// If the fields are filled in incorrectly, then, apparently, the document was carried out before switching to batch accounting version 2.2 -
	// it is necessary to double-check the document according to the register containing incorrect movements.
	// If, after rechecking the document, the fields are still filled in incorrectly, then the error lies
	// in the procedures for generating document movements or in the layout of the description of movements (for the register of the cost of goods).
	
	// We will prepare auxiliary data.
	DescriptionOfChains 		= CostCalculationFillingInformationAboutLots.DescriptionOfChainsOfBatchesOfGoods(CalculationParameters);
	RecordTypesUsed = CostCalculationAppliedAlgorithms.TypesOfRecordsUsedInChains(DescriptionOfChains);
	
	Query.SetParameter("RecordTypesUsed", RecordTypesUsed);
	Query.SetParameter("AnalyticalAccountingByProductsGroups", GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	#Region QueryText
	
	// We will prepare a request for the formation of a registration with incorrect movements.
	QueryText = "
	|SELECT DISTINCT
	|	T.Recorder				AS Recorder,
	|	T.Organization				AS Organization,
	|	T.ProductionLot		AS ProductionLot
	|INTO TTOtherWorkInProgressExpenses
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (TYPE(Document.InventoryCostCalculation),
	|									TYPE(Document.RegisterAdjustment))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.RecordType			 AS RecordType,
	|	T.Recorder 			 AS Recorder,
	|	T.Organization 			 AS Organization,
	|	T.LotVendorAttributes	 AS LotVendorAttributes,
	|	T.VATActivityType	 AS VATActivityType
	|INTO TTMovementAndOtherExpenses
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Recorder AS Recorder,
	|	T.Organization,
	|	T.BusinessOperation
	|INTO ImplementationsInWayOfDifferentAccountingSection
	|FROM
	|	TTMovementCostOfGoods AS T
	|	INNER JOIN AccumulationRegister.InventoryCost AS InventoryCost
	|		ON InventoryCost.Recorder = T.Recorder
	|		AND InventoryCost.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.Move)
	|		AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND InventoryCost.ItemsLocationAttributes = T.ItemsLocationAttributes
	|		AND InventoryCost.InventoryOwnerAttribute = T.InventoryOwnerAttribute
	|		AND InventoryCost.AccountingSection <> T.AccountingSection
	|WHERE
	|	VALUETYPE(T.Recorder) = TYPE(Document.CustomerInvoice)
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|	AND T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.SaleOfGoodsAndServices)
	|INDEX BY
	|    Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Table of analysts with negative Balances. According to such analysts, it makes no sense to check the zero cost in the
	// documents' Register Records when using the "Medium-slip" valuation method, since such Balances arise in the absence of receipts and
	// , accordingly, it is impossible to calculate the medium-slip cost from them.
	// Balances are sampled on the date of relevance, because when determining the average sliding cost, Balances are also taken
	// on the date of relevance. See the request for the formation of a table with the highest value of the data in the procedure 
	// Add the text of the query to the account of the average sliding cost() #Area Add the text of the query to the average sliding cost.
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization
	|
	|INTO Negative_Balance
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(,
	|		Organization IN (&MediumSlipOrganizations)
	// The request was left for the purpose of debugging the mesanism of correcting Registered Records.
	|		AND FALSE
	|		AND NOT AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|		) AS T
	|WHERE
	|	T.CountBalance < 0
	|INDEX BY
	|	ItemsLocationAttributes,
	|	AccountingSection,
	|	InventoryOwnerAttribute,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.RegisterName AS RegisterName,
	|	T.Ref 	  AS Ref,
	|	T.Organization AS Organization,
	|	T.BusinessOperation AS BusinessOperation,
	|	T.ErrorCode   AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM (
	|	SELECT DISTINCT
	|		""InventoryCost"" AS RegisterName,
	|		T.Recorder AS Ref,
	|		T.Organization AS Organization,
	|		T.BusinessOperation AS BusinessOperation,
	|		CASE
	|			WHEN Rules.EmptyLoggerValue IS NULL 
	|				THEN 1
	|			WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CASE
	|						WHEN T.EntryType IN
	|							(SELECT
	|								RecordTypes.EntryTypeReceipt
	|							 FROM
	|								TTRulesForFillingInRecordTypeField AS RecordTypes
	|							 WHERE
	|								VALUETYPE(T.Recorder) = VALUETYPE(RecordTypes.EmptyLoggerValue)
	|								AND (RecordTypes.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|									OR T.BusinessOperation = RecordTypes.BusinessOperation)
	|								AND (RecordTypes.PositiveQuantity = UNDEFINED
	|									OR T.PositiveQuantity = RecordTypes.PositiveQuantity))
	|							THEN 0
	|						ELSE 2
	|					END
	|			ELSE CASE
	|						WHEN T.EntryType IN
	|							(SELECT
	|								RecordTypes.EntryTypeExpense
	|							 FROM
	|								TTRulesForFillingInRecordTypeField AS RecordTypes
	|							 WHERE
	|								VALUETYPE(T.Recorder) = VALUETYPE(RecordTypes.EmptyLoggerValue)
	|								AND (RecordTypes.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|									OR T.BusinessOperation = RecordTypes.BusinessOperation)
	|								AND (RecordTypes.PositiveQuantity = UNDEFINED
	|									OR T.PositiveQuantity = RecordTypes.PositiveQuantity))
	|						THEN 0
	|					ELSE 3
	|				END
	|		END AS ErrorCode
	|	FROM
	|		TTMovementCostOfGoods AS T
	|			LEFT JOIN TTRulesForFillingInRecordTypeField AS Rules
	|			ON VALUETYPE(T.Recorder) = VALUETYPE(Rules.EmptyLoggerValue)
	|				AND (Rules.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|					OR T.BusinessOperation = Rules.BusinessOperation)
	|				AND (Rules.PositiveQuantity = UNDEFINED
	|					OR T.PositiveQuantity = Rules.PositiveQuantity)
	// When using a medium-slip, we do not check the acceptable record types, because the batch distribution stages are not performed.
	|	WHERE
	|		NOT T.Organization IN(&MediumSlipOrganizations)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		CASE
	// Checking the cor. of the Lot Reference in the consumable Registered Records when the cor is filled. organizations (Intercampany scheme).
	|			WHEN T.Organization IN (&SFIFOOrganizationsSliding)
	|				AND T.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
	|				AND NOT T.CorCompany IN (&SFIFOOrganizationsSliding)
	|				AND NOT VALUETYPE(T.CorLot) = TYPE(Catalog.ProductionLots)
	|				AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN
	|					CASE
	|						WHEN T.CorLot = UNDEFINED
	|							THEN 0
	|						ELSE 5
	|					END
	|			WHEN NOT T.Organization IN (&SFIFOOrganizationsSliding)
	|				AND T.CorCompany IN (&SFIFOOrganizationsSliding)
	|				AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|				THEN
	|					CASE
	|						WHEN T.CorLot = T.Recorder
	|							THEN 0
	|						ELSE 6
	|					END
	// Checking the cor. Lot References in the expenditure RegisteredRecords without cor. organizations (changing the Lot Reference document within the same organization).
	|			WHEN T.Organization IN (&SFIFOOrganizationsSliding)
	|				AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND NOT T.CorAccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping),
	|										VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef))
	|				AND ISNULL(Rules.EntryTypeExpense, UNDEFINED) = T.EntryType
	|				AND NOT T.CorCostElement IS NULL
	|				AND (
	// When writing off production Lot References to the box, the Lot References must be filled in.
	|					(
	|						NOT VALUETYPE(T.Recorder) = TYPE(Document.ProductionStage2_2)
	|						AND
	|						(ISNULL(Rules.CorPartyAtExpense, FALSE)
	|							AND T.CorLot = UNDEFINED
	|						OR NOT ISNULL(Rules.CorPartyAtExpense, FALSE)
	|							AND NOT T.CorLot = UNDEFINED)
	|						)
	// For the production stage, the box Lot Reference is filled in with the Lot Reference of the production stage.
	|					OR (VALUETYPE(T.Recorder) = TYPE(Document.ProductionStage2_2)
	|						AND (ISNULL(Rules.CorPartyAtExpense, FALSE)
	|							AND T.CorLot <> ProductionStages.ProductionLot
	|							OR NOT ISNULL(Rules.CorPartyAtExpense, FALSE)
	|								AND T.CorLot = ProductionStages.ProductionLot)
	|					)
	|
	|				)
	|				THEN 6
	|			WHEN NOT T.Organization IN (&SFIFOOrganizationsSliding)
	|				AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND T.CorLot = T.Recorder
	|				AND NOT T.CorAccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|										VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping),
	|										VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|				AND NOT T.CorCostElement IS NULL
	|				THEN 5
	|			ELSE 0
	|		END
	|	FROM
	|		TTMovementCostOfGoods AS T
	|			LEFT JOIN TTRulesForFillingInRecordTypeField AS Rules
	|			ON VALUETYPE(T.Recorder) = VALUETYPE(Rules.EmptyLoggerValue)
	|				AND (Rules.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|					OR T.BusinessOperation = Rules.BusinessOperation)
	|				AND (Rules.PositiveQuantity = UNDEFINED
	|					OR T.PositiveQuantity = Rules.PositiveQuantity)
	|			LEFT JOIN Document.ProductionStage2_2 AS ProductionStages
	|			ON ProductionStages.Ref = T.Recorder
	|
	|
	|			LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|			ON CatProductionLots.Ref = T.CorLot
	|	WHERE
	|		NOT T.ReversingEntry
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		CASE
	|			WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					AND Rules.DocumentSourceInParish AND T.DocumentSource = UNDEFINED
	|			  THEN 18
	|			WHEN T.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND Rules.DocumentSourceInExpense AND T.DocumentSource = UNDEFINED
	|			  THEN 19
	|			  ELSE 0
	|		END
	|	FROM
	|		TTMovementCostOfGoods AS T
	|			LEFT JOIN TTRulesForFillingInRecordTypeField AS Rules
	|			ON VALUETYPE(T.Recorder) = VALUETYPE(Rules.EmptyLoggerValue)
	|				AND (Rules.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|					OR T.BusinessOperation = Rules.BusinessOperation)
	|				AND (Rules.PositiveQuantity = UNDEFINED
	|					OR T.PositiveQuantity = Rules.PositiveQuantity)
	|				AND (Rules.DocumentSourceInParish AND T.EntryType = Rules.EntryTypeReceipt
	|					OR Rules.DocumentSourceInExpense AND T.EntryType = Rules.EntryTypeExpense)
	|	WHERE
	|		CASE
	|			WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					AND Rules.DocumentSourceInParish AND T.DocumentSource = UNDEFINED
	|			  THEN 18
	|			WHEN T.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND Rules.DocumentSourceInExpense AND T.DocumentSource = UNDEFINED
	|			  THEN 19
	|			  ELSE 0
	|		END <> 0
	|	
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"" AS RegisterName,
	|		T.Recorder AS Ref,
	|		T.Organization AS Organization,
	|		T.BusinessOperation AS BusinessOperation,
	|		CASE
	|			WHEN T.Organization IN (&SFIFOOrganizationsSliding) AND T.Lot = UNDEFINED
	|				THEN 4
	|			WHEN NOT (T.Organization IN (&SFIFOOrganizationsSliding)) AND T.Lot <> UNDEFINED
	|			  AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|			  AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|			  AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			  AND NOT (T.AccountingSection IN(VALUE (Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|											VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping))
	|					AND NOT T.ProductCostElement IS NULL)
	|				THEN 5
	|			ELSE 0
	|		END AS ErrorCode
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		(T.EntryType IN (&TypesOfPrimaryBatchRecords)
	|		OR T.EntryType IN (
	|				VALUE(Enum.LotRecordTypes.PurchaseAdjustment),
	|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
	|			AND VALUETYPE(T.Recorder) <> TYPE(Document.SaleAdjustment)
	|		OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|			AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		AND NOT T.ReversingEntry
	|		OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|			AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|		OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|			AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		7
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		NOT (T.EntryType IN (&RecordTypesUsed))
	|		AND NOT (T.EntryType IN (&UnreadableRecordTypes))
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		8
	|	FROM
	|		TTMovementCostOfGoods AS T
	|			INNER JOIN Catalog.KeysForLotVendorAttributes AS Analysts
	|			ON T.LotVendorAttributes = Analysts.Ref
	|	WHERE
	|		Analysts.AssetTaxClass = VALUE(Enum.AssetKinds.EmptyRef)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		9
	|	FROM
	|		TTMovementCostOfGoods AS T
	|			INNER JOIN Catalog.KeysForLotVendorAttributes AS Analysts
	|			ON T.LotVendorAttributesCorr = Analysts.Ref
	|	WHERE
	|		Analysts.AssetTaxClass = VALUE(Enum.AssetKinds.EmptyRef)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""ItemisedExpensesLots"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		8
	|	FROM
	|		TTMovementAndOtherExpenses AS T
	|			INNER JOIN Catalog.KeysForLotVendorAttributes AS Analysts
	|			ON T.LotVendorAttributes = Analysts.Ref
	|	WHERE
	|		Analysts.AssetTaxClass = VALUE(Enum.AssetKinds.EmptyRef)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""ItemisedExpensesLots"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		10
	|	FROM
	|		TTMovementAndOtherExpenses AS T
	|			INNER JOIN Catalog.KeysForLotVendorAttributes AS Analysts
	|			ON T.LotVendorAttributes = Analysts.Ref
	|	WHERE
	|		T.VATActivityType = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		11
	|	FROM
	|		TTMovementCostOfGoods AS T
	|
	|		LEFT JOIN Catalog.KeysForLotVendorAttributes AS Analysts
	|			ON T.LotVendorAttributes = Analysts.Ref
	|
	|	WHERE
	|		T.Organization IN (&SFIFOOrganizationsSliding)
	|		AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ProductsRelease),
	|									VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|									VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND NOT T.ReversingEntry
	|		AND VALUETYPE(T.Recorder) IN (
	|			TYPE(Document.ProductionStage2_2),
	
	|			TYPE(Document.BackflushProduction))
	|		AND ISNULL(Analysts.RowCode, 0) = 0
	|		AND NOT T.ReversingEntry
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		12
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		14
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.VATActivityType = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND T.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		AND NOT T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners))
	|
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		DD.Recorder,
	|		DD.Organization,
	|		DD.BusinessOperation,
	|		16
	|	FROM
	|		TTMovementCostOfGoods AS DD
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CatItemsLocationAttributes
	|		ON CatItemsLocationAttributes.Ref = DD.ItemsLocationAttributes
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = CatItemsLocationAttributes.Products
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CatCorItemsLocationAttributes
	|		ON CatCorItemsLocationAttributes.Ref = DD.CorItemsLocationAttributes
	|
	|	WHERE
	|		DD.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND NOT (DD.Recorder REFS Document.SubcontractorReport2_5
	|			OR DD.Recorder REFS Document.ReversingEntry AND DD.DocumentSource REFS Document.SubcontractorReport2_5)
	|		AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		AND (DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|			AND (&AnalyticalAccountingByProductsGroups
	|				AND NOT CatProducts.AnalyticalGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				AND (DD.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|					OR (DD.CorControllingAttributes = UNDEFINED
	|							AND (ISNULL(CatCorItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
	|								OR CatCorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|								OR CatCorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|								)
	|						)
	|				)
	|				
	|			)
	|			OR DD.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|				AND NOT DD.CorControllingAttributes = UNDEFINED
	|		)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		17
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.BusinessOperation = VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification)
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
	|		AND T.DocumentSource = UNDEFINED
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		20
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		NOT T.Organization IN (&SFIFOOrganizationsSliding)
	|		AND T.LotVendorAttributesCorr = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (T.LocalCost <> 0 OR T.VATLocal <> 0)
	|		AND T.EntryType IN (
	|			VALUE(Enum.LotRecordTypes.Lot),
	|			VALUE(Enum.LotRecordTypes.PurchaseAdjustment))
	|		AND T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
	|		AND NOT T.ReversingEntry
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		21
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		AND T.SalePeriod = DATETIME(1,1,1)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		22
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|		AND T.CorCompany = VALUE(Catalog.Companies.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		23
	|	FROM
	|		TTMovementCostOfGoods AS T
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = T.Lot
	|
	|	WHERE
	|		CatProductionLots.UsedForNavigation
	|		AND NOT ISNULL(T.ItemsLocationAttributes.ProductCostElement,
	|			VALUE(Catalog.ProductCostElements.EmptyRef)) =
	|				VALUE(Catalog.ProductCostElements.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		23
	|	FROM
	|		TTMovementCostOfGoods AS T
	|
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = T.CorLot
	|
	|	WHERE
	|		CatProductionLots.UsedForNavigation
	|		AND NOT ISNULL(T.CorItemsLocationAttributes.ProductCostElement,
	|			VALUE(Catalog.ProductCostElements.EmptyRef)) =
	|				VALUE(Catalog.ProductCostElements.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""OtherWorkInProgressExpenses"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		23
	|	FROM
	|		TTOtherWorkInProgressExpenses AS T
	|
	|	WHERE
	|		ISNULL(T.ProductionLot.UsedForNavigation, FALSE)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		24
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
	|			ON RevenueAndCOGS.Recorder = T.Recorder
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.Organization = VALUE(Catalog.Companies.ManagementCompany)
	|		AND T.AccountingDimensionByPartners = VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|		AND T.EntryType <> VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|		AND T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		25
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		(T.LotVendorAttributesCorr = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|			OR T.LotVendorAttributesCorr = T.LotVendorAttributes) // By mistake, the props of the KorAnalitikaUchetAparty were overloaded
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND VALUETYPE(T.Recorder) <> TYPE(Document.VendorInvoice)
	|		AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|		AND T.EntryType IN (
	|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
	|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified))
	|
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""RevenueAndCOGS"",
	|		T.Recorder,
	|		Dimension.Organization,
	|		UNDEFINED,
	|		28
	|	FROM
	|		AccumulationRegister.RevenueAndCOGS AS T
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
	|			ON Dimension.Ref = T.AccountingDimensionByPartners
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Dimension.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.CommissionReportIntercompany)
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		30
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.CCDImport AS Declaration
	|			ON Declaration.Ref = T.Recorder
	|	WHERE
	|		T.CorVATActivityTypes = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		31
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		&KeepRecordsOfInventoryCostByAssignments
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		AND VALUETYPE(T.Recorder) IN (
	|			TYPE(Document.BackflushProduction),
	|			TYPE(Document.AssemblyFromComponents))
	|		OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.CustomerInvoiceIntercompany))
	|
	|		AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|			<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|			<> T.VATActivityType
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		32
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.BackflushProduction AS BackflushProduction
	|			ON BackflushProduction.Ref = T.Recorder
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|		AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|		AND T.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		33
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.ProductionStage2_2 AS ProductionStage
	|			ON ProductionStage.Ref = T.Recorder
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.ItemsLocationAttributes = T.CorItemsLocationAttributes
	|		AND T.AccountingSection = T.CorAccountingSection
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToProduction)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		34
	|	FROM
	|		AccumulationRegister.InventoryCost AS T
	|		INNER JOIN Document.RecyclableWasteAllocation AS Attributes
	|			ON Attributes.Ref = T.Recorder
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.Active
	|		AND T.Organization IN(&CompanyArray)
	|		AND NOT T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND T.Count < 0
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|		AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|	UNION ALL
	|	
	// Filling out the documentation for the returnable waste of the production stages (balance)
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		35
	|	FROM
	|		AccumulationRegister.InventoryCost AS T
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN(&CompanyArray)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.ProductionStage2_2)
	|		AND NOT T.LocalCost = 0
	|		AND T.DocumentRegisterRecords = UNDEFINED
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|		AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|	UNION ALL
	|	
	// Filling out the documentation for the returnable waste of the production stages (off-balance)
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		35
	|	FROM
	|		AccumulationRegister.InventoryCost AS T
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN(&CompanyArray)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.ProductionStage2_2)
	|		AND NOT T.OffBalanceCostLocal = 0
	|		AND T.DocumentRegisterRecords = UNDEFINED
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|		AND NOT T.Organization IN (&MediumSlipOrganizations)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		36
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
	|			ON PurchaseAdjustment.Ref = T.Recorder
	|	WHERE
	|		T.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
	|		AND T.Cost <> 0
	|		OR
	|		T.EntryType IN (
	|			VALUE(Enum.LotRecordTypes.Lot),
	|			VALUE(Enum.LotRecordTypes.PurchaseAdjustment))
	|		AND T.Count = 0
	|		AND T.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|		OR
	|		T.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
	|		AND T.Count = 0
	|		AND T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|		AND T.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)
	|	
	// After changing the "Shop pantry" check box, movements with the wrong accounting section may remain in the warehouse.
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		37
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|		AND T.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""RevenueAndCOGS"",
	|		T.Recorder,
	|		Dimension.Organization,
	|		UNDEFINED,
	|		37
	|	FROM
	|		AccumulationRegister.RevenueAndCOGS AS T
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
	|			ON Dimension.Ref = T.AccountingDimensionByPartners
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Dimension.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|		AND T.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		38
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|		AND NOT T.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""RevenueAndCOGS"",
	|		T.Recorder,
	|		Dimension.Organization,
	|		UNDEFINED,
	|		38
	|	FROM
	|		AccumulationRegister.RevenueAndCOGS AS T
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
	|			ON Dimension.Ref = T.AccountingDimensionByPartners
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Dimension.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|		AND NOT T.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""ItemisedExpensesLots"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		39
	|	FROM
	|		AccumulationRegister.ItemisedExpensesLots AS T
	|		INNER JOIN Document.OtherIncomeExpenses AS Filter
	|			ON T.Recorder = Filter.Ref
	|			AND Filter.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseReclassification)
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		40
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		AND T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		41
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.InventoryAssignmentAdjustment)
	|		AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.ItemsLocationAttributes = T.CorItemsLocationAttributes
	|		AND T.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		42
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.CorGrossInitialCostENT <> 0
	|		AND T.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor),
	|			VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn),
	|			VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation),
	|			VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation),
	|			VALUE(Enum.BusinessTransactions.SaleOfTransferredReturnablePackaging),
	|			VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransaction),
	|			VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse),
	|			VALUE(Enum.BusinessTransactions.GoodsLotsMisgrading))
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		43
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation)
	|		AND T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
	|		AND T.IncomeItem = VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		44
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Catalog.ProductionLots AS ProductionLots
	|			ON ProductionLots.Ref = T.Lot
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		AND VALUETYPE(T.Recorder) IN (
	|			TYPE(Document.BackflushProduction),
	|			TYPE(Document.ProductionStage2_2),
	|			TYPE(Document.ProductionCostAllocation))
	|		AND ProductionLots.VATActivityType	<> T.VATActivityType
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		45
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		AND T.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		46
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.ProductionStage2_2.InventoryOwnerAttributesMaterials AS TabularSection
	|			ON TabularSection.Ref = T.Recorder
	|			AND TabularSection.RowID = T.RowID
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.ProductionStage2_2)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		47
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.VendorInvoice)
	|		AND T.RowID = """"
	
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		48
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting)
	|		AND T.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		49
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent))
	|		AND T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		51
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.ProductionCostAllocation)
	|		AND T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND (T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			OR T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|			AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner))
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		52
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|		AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND ISNULL(T.CorItemsLocationAttributes.Products.ItemsType, UNDEFINED)
	|			= VALUE(Enum.ItemsTypes.Work_5)
	|		AND T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		AND T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		53
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.BackflushProduction.InventoryOwnerAttributesSideProducts AS InventoryKinds
	|			ON InventoryKinds.Ref = T.Recorder
	|			AND InventoryKinds.RowID = T.RowID
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		54
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.ProductionStage2_2.InventoryOwnerAttributesProducts AS InventoryKinds
	|			ON InventoryKinds.Ref = T.Recorder
	|			AND InventoryKinds.RowID = T.RowID
	|			AND InventoryKinds.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		55
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|		AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		57
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		LEFT JOIN Document.CustomerInvoice AS SaleOfGoodsAndServices
	|			ON SaleOfGoodsAndServices.Ref = T.DocumentSource
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.Count < 0
	|		AND T.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReverseOfSale),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent))
	|		AND (T.SalePeriod < &BeginOfPeriod AND T.SalePeriod <> DATETIME(1,1,1)
	|			OR ISNULL(SaleOfGoodsAndServices.Date, &BeginOfPeriod) < &BeginOfPeriod)
	|		AND NOT T.ReversingEntry
	|		AND NOT T.Organization IN(&MediumSlipOrganizations)
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""RevenueAndCOGS"",
	|		T.Recorder,
	|		Dimension.Organization,
	|		UNDEFINED,
	|		57
	|	FROM
	|		AccumulationRegister.RevenueAndCOGS AS T
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
	|			ON Dimension.Ref = T.AccountingDimensionByPartners
	|		LEFT JOIN TTMovementCostOfGoods AS Cost_
	|			ON Cost_.Recorder = T.Recorder
	|			AND Cost_.FinRecordID = T.FinRecordID
	|			AND Cost_.FinRecordID <> """"
	|		LEFT JOIN Document.CustomerInvoice AS SaleOfGoodsAndServices
	|			ON SaleOfGoodsAndServices.Ref = Cost_.DocumentSource
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Dimension.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.Count < 0
	|		AND T.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReverseOfSale),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent))
	|		AND (Cost_.SalePeriod < &BeginOfPeriod AND Cost_.SalePeriod <> DATETIME(1,1,1)
	|			OR ISNULL(SaleOfGoodsAndServices.Date, &BeginOfPeriod) < &BeginOfPeriod)
	|		AND NOT T.ReversingEntry
	|		AND NOT Dimension.Organization IN(&MediumSlipOrganizations)
	|
	|	UNION ALL
	|	
	// In the "Work in progress" Controlling attribute, the financial accounting should correspond to a group of products from
	// the production batch, or have an UNDEFINED value if the product group is not filled in.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		58
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Catalog.ProductionLots AS ProductionLots
	|			ON ProductionLots.Ref = T.Lot
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)                                           
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|		AND (&AnalyticalAccountingByProductsGroups
	|			AND ProductionLots.ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			AND ProductionLots.ProductsGroup <> T.FinancialAccountingDimension
	|			OR &AnalyticalAccountingByProductsGroups
	|				AND ProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				AND T.FinancialAccountingDimension <> UNDEFINED
	|			OR NOT &AnalyticalAccountingByProductsGroups AND T.FinancialAccountingDimension <> UNDEFINED
	|			)
	|
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		59
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		LEFT JOIN TTMovementCostOfGoods AS RegisterRecordsReceipt
	|			ON RegisterRecordsReceipt.Recorder = T.Recorder
	|			AND RegisterRecordsReceipt.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND RegisterRecordsReceipt.ItemsLocationAttributes = T.CorItemsLocationAttributes
	|			AND RegisterRecordsReceipt.AccountingSection = T.AccountingSection
	|			AND RegisterRecordsReceipt.VATActivityType = T.CorVATActivityTypes
	|	WHERE
	//		Checking the correspondence of movements to transfer the book value of goods to a management organization
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|		AND NOT T.AccountingSection IN (&OffBalanceSheetAccountingSections)
	|		AND RegisterRecordsReceipt.Recorder IS NULL
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		60
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.ConsignmentReportFromCustomer)
	|		AND T.RowID = """"
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		61
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.InventoryOwnerAttribute.InventoryType IN (
	|			VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|		AND T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		62
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		AND T.Count < 0
	|		AND NOT T.ReversingEntry
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""ItemisedExpensesLots"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		63
	|	FROM
	|		TTMovementAndOtherExpenses AS T
	|		INNER JOIN Document.PurchaseAdjustment AS Adjusting
	|			ON Adjusting.Ref = T.Recorder
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.LotVendorAttributes = VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|
	|	UNION ALL
	|	
	// The goods transferred to the commission for the commission sale of version 2.5 are counted in the section "Goods transferred to the commission",
	// except for the goods accepted for the commission. Goods accepted for commission and remain on the accounting section "Goods accepted for commission".
	// It is legal to transfer only your own goods and goods accepted for commission to the commission.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		64
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		AND T.ItemsLocationAttributes.Contract.ContractType = VALUE(Enum.ContractTypes.WithConsignee)
	|		AND NOT T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent))
	|	
	|	
	|	UNION ALL
	|
	// In the cost of goods, a cost accounting operation must be completed for retirements at a fixed cost,
	// This is necessary for the correct operation of the procedure to adjust the cost of writing inventory().
	// In the requests of this procedure, there are conditions for the cost accounting operation.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		66
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.Count <> 0
	|		AND T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.EmptyRef)
	|		AND T.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor),
	|			VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation),
	|			VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation))
	|	
	|	UNION ALL
	|
	// The sale without transfer of ownership for a commission product must have the same Accounting section
	|	SELECT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		67
	|	FROM
	|		ImplementationsInWayOfDifferentAccountingSection AS T
	|	
	|	UNION ALL
	|
	|	SELECT
	|		""RevenueAndCOGS"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		67
	|	FROM
	|		ImplementationsInWayOfDifferentAccountingSection AS T
	|	
	|	UNION ALL
	|	
	// Correction of Registered Records for record types with an incorrect sign of the quantity.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		68
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND NOT T.ReversingEntry
	|		AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.RetailSaleOfGoods)
	|		AND (T.Count < 0 AND T.EntryType  = VALUE(Enum.LotRecordTypes.Consumption)
	|			OR T.Count > 0 AND T.EntryType  = VALUE(Enum.LotRecordTypes.ReversingEntry))
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""RevenueAndCOGS"",
	|		T.Recorder,
	|		Dimension.Organization,
	|		UNDEFINED,
	|		70
	|	FROM
	|		AccumulationRegister.RevenueAndCOGS AS T
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
	|			ON Dimension.Ref = T.AccountingDimensionByPartners
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Dimension.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.Count <> 0
	|		AND T.VATActivityType = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		71
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		LEFT JOIN TTAccountingPoliciesOfSourceDocuments AS SourceDocumentPolicies
	|			ON T.Recorder = SourceDocumentPolicies.Recorder
	|			AND T.Organization = SourceDocumentPolicies.Organization
	|			AND T.DocumentSource = SourceDocumentPolicies.DocumentSource
	|	WHERE
	|		&KeepRecordsOfInventoryCostByAssignments
	|		AND T.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		AND ISNULL(SourceDocumentPolicies.InventoryValuationMethod, UNDEFINED) <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|			<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|			<> T.VATActivityType
	|		AND NOT T.Recorder REFS Document.ApplicationForImportationOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""OtherExpenses"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		72
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
	|			ON OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND OtherExpenses.Recorder = T.Recorder
	|			AND OtherExpenses.FinRecordID = T.FinRecordID
	|			AND OtherExpenses.BusinessTransactionSetting = T.BusinessTransactionSetting
	|			AND OtherExpenses.BusinessOperation <> T.BusinessOperation
	|	WHERE
	|		T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		73
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|		AND T.EntryType <> VALUE(Enum.LotRecordTypes.IncludeVATInCostExpenses)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.CCDImport)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		75
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Document.VendorInvoice AS Purchase
	|			ON Purchase.Ref = T.DocumentSource
	|			AND Purchase.Date < &BeginOfPeriod
	|	WHERE
	|		T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.ReversingEntry)
	|		AND T.EntryType <> VALUE(Enum.LotRecordTypes.Supplement)
	|		AND T.Count <> 0
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		76
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|		AND T.VATActivityType = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	// In case of medium-slip VAT taxation is not filled in.
	|		AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|	UNION ALL
	|	
	// The documents "Transfer of goods to the Custodian" and "Receipt of goods to the Custodian" do not have data on the VAT taxation activity,
	// therefore, for these documents, the VAT taxation activity of the selected batch must be preserved.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		77
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.DocumentVATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND ISNULL(T.CorItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|			= VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND (VALUETYPE(T.Recorder) = TYPE(Document.TransferOfGoodsToBailee)
	|			OR VALUETYPE(T.Recorder) = TYPE(Document.ReceiptOfGoodsFromCustodian))
	|		AND NOT T.ReversingEntry
	|	
	|	UNION ALL
	|	
	// When releasing products at the calculated cost and applying the accounting of products at the planned cost, the 
	// Registered Records for the output of products must be performed according to the Accounting section "Output" to calculate the deviations between the planned and
	// actual cost.
	// When the accounting of products at the planned cost is turned off, there should be no Registered Recorded in the Accounting section "Output".
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		(CASE
	|			WHEN T.ProductCostingByPlannedCost THEN 78
	|			ELSE 79 END) AS ErrorCode
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		LEFT JOIN TTMovementCostOfGoods AS RegisterRecords
	|			ON RegisterRecords.Recorder = T.Recorder
	|			AND RegisterRecords.FinRecordID = T.FinRecordID
	|			AND RegisterRecords.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.Count <> 0
	|		AND T.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ProductsRelease),
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
	|		AND NOT T.ReversingEntry
	|		AND (T.ProductCostingByPlannedCost AND RegisterRecords.Recorder IS NULL
	|			OR NOT T.ProductCostingByPlannedCost AND NOT RegisterRecords.Recorder IS NULL)
	|
	|	UNION ALL
	|	
	// When releasing products at the calculated cost and applying the accounting of products at the planned cost, the 
	// Registered Records for the output of products must be performed according to the Accounting section "Output" to calculate the deviations between the planned and
	// actual cost.
	// When the accounting of products at the planned cost is turned off, there should be no Registered Recorded in the Accounting section "Output".
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		(CASE
	|			WHEN T.ProductCostingByPlannedCost THEN 78
	|			ELSE 79 END) AS ErrorCode
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		LEFT JOIN TTMovementCostOfGoods AS RegisterRecords
	|			ON RegisterRecords.Recorder = T.Recorder
	|			AND RegisterRecords.FinRecordID = T.FinRecordID
	|			AND RegisterRecords.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|			AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.Count <> 0
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		AND NOT T.ReversingEntry
	|		AND (T.ProductCostingByPlannedCost AND RegisterRecords.Recorder IS NULL
	|			OR NOT T.ProductCostingByPlannedCost AND NOT RegisterRecords.Recorder IS NULL)
	|		AND VALUETYPE(T.Recorder) <> TYPE(Document.MovementOfProductsAndMaterials)
	|
	|	UNION ALL
	|	
	// When releasing products at a fixed cost, the "Output" section of accounting should not be used.
	// The "Output" section applies only to products at the calculated cost for calculating deviations
	// between the planned and actual cost.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		80 AS ErrorCode
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.Count <> 0
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		AND T.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost),
	|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost),
	|			VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost))
	|		AND NOT T.ReversingEntry
	|
	|	UNION ALL
	|	
	// When releasing products to the workshop pantry, the workshop pantry should also be indicated in the "Output" section
	// for separate accounting of the actual cost of each workshop pantry.
	// This corresponds to the Registered Records when the accounting is turned off at the planned cost - the products are immediately released to the shop pantry.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		81 AS ErrorCode
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.Count <> 0
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		AND ISNULL(T.CorItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
	|		AND T.CorItemsLocationAttributes <> T.ItemsLocationAttributes
	|		AND NOT T.ReversingEntry
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""GoodsCostVariances"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		82
	|	FROM
	|		AccumulationRegister.GoodsCostVariances AS T
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.StorageLocation = VALUE(Catalog.Warehouses.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""GoodsCostVariances"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		83
	|	FROM
	|		AccumulationRegister.GoodsCostVariances AS T
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|		AND T.VariancePeriod = &BeginOfPeriod
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		84 AS ErrorCode
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.Count <> 0
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND T.Lot = UNDEFINED
	|		AND T.Organization IN (&MediumSlipOrganizations)
	|
	|	UNION ALL
	|
	// Checking the presence of an uncalculated cost at a medium-slip.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		85 AS ErrorCode
	|	FROM
	// The selection is performed from the register Register Recorded table to use suitable indices when connected to the taboice of negative stat.
	|		AccumulationRegister.InventoryCost AS T
	|		LEFT JOIN Negative_Balance AS Negative_Balance
	|			ON Negative_Balance.ItemsLocationAttributes = T.ItemsLocationAttributes
	|			AND Negative_Balance.AccountingSection = T.AccountingSection
	|			AND Negative_Balance.InventoryOwnerAttribute = T.InventoryOwnerAttribute
	|			AND Negative_Balance.Organization = T.Organization
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	// The request was left for the purpose of debugging the mesanism of correcting Registered Records.
	|		AND FALSE
	|		AND T.Organization IN (&MediumSlipOrganizations)
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND NOT VALUETYPE(T.Recorder) IN (
	|			TYPE(Document.InventoryCostCalculation),
	|			TYPE(Document.CalculationOfInventoryImpairmentProvision),
	|			TYPE(Document.RegisterAdjustment))
	|		AND T.Count <> 0
	|		AND T.Cost = 0
	|		AND T.OffBalanceCost = 0
	|		AND T.LocalCost = 0
	|		AND T.OffBalanceCostLocal = 0
	|		AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		AND T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|		AND Negative_Balance.ItemsLocationAttributes IS NULL
	// In the report to the giver between companies there is no planned cost of the issue, so the average sliding cost cannot be 
	// calculated for this document.
	|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	// For the inventory type "Giver's Products", the cost may be empty.
	|		AND ISNULL(T.InventoryOwnerAttribute.InventoryType, UNDEFINED) <> VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|
	|
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		78
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.AccountingSection IN (
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
	|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
	|		AND VALUETYPE(T.Recorder) IN (TYPE(Document.CCDImport),
	|										TYPE(Document.ApplicationForImportationOfGoods))
	|		AND T.RowID = """"
	|	
	|	UNION ALL
	|	
	// If the document contains the same nomenclature and characteristics with the same warehouse, purpose and series
	// in several lines, then all such lines should contain batch accounting analytics with the same line code
	// so that the same lines form one common batch.
	// Request fill analysts accounting of the parties running in functions of RequestTextStringCodesForBatchAccountingAnalytics()
	// General module CostCalculationDocumentsPosting(). 
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		87
	|	FROM
	|		(SELECT
	|			T.Recorder,
	|			T.Organization,
	|			T.ItemsLocationAttributes,
	|			SUM(1) AS RowsCount,
	|			COUNT(DISTINCT Keys.RowCode) AS NumberOfLineCodes
	|		FROM
	|			TTMovementCostOfGoods AS T
	|			INNER JOIN Catalog.KeysForLotVendorAttributes AS Keys
	|			ON T.LotVendorAttributes = Keys.Ref
	|		WHERE
	|			T.Count > 0
	|			AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND T.EntryType IN (
	|				VALUE(Enum.LotRecordTypes.Lot),
	|				VALUE(Enum.LotRecordTypes.Consumption))
	|			AND VALUETYPE(T.Recorder) = TYPE(Document.VendorInvoice)
	|			AND T.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
	|			AND NOT T.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.AssemblyFromComponents),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
	|				VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|		GROUP BY
	|			T.Recorder,
	|			T.Organization,
	|			T.ItemsLocationAttributes
	|		) AS T
	|	WHERE
	|		T.RowsCount > 1
	|		AND T.NumberOfLineCodes > 1
	|
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""OtherAssetsAndLiabilitiesRecords"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessTransactionSetting.BusinessOperation AS BusinessOperation,
	|		88
	|	FROM
	|		AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS T
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND VALUETYPE(T.Recorder) = TYPE(Document.AllocationOfOtherCosts)
	|
	|	UNION ALL
	|	
	// Prior to version 2.5.14, the record type "Purchase adjustment" was filled in in the movements of the document "Reverse" for the movement of goods. 
	// After 2.5.14, the record type changed to "Correction of the movement of the previous period". 
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		89
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.ReversingEntry
	|		AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
	|		AND T.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits),
	|			VALUE(Enum.BusinessTransactions.InternalWorkReceipt),
	|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
	|			VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|			VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom),
	|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
	|			VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom),
	|			VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
	|			VALUE(Enum.BusinessTransactions.InternalGoodsReceipt),
	|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale),
	|			VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
	|			VALUE(Enum.BusinessTransactions.TransferToToller2_5),
	|			VALUE(Enum.BusinessTransactions.InventoryTransfer),
	|			VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|			VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5),
	|			VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|			VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			)
	|		AND VALUETYPE(T.DocumentSource) <> TYPE(Document.BackflushProduction)
	|		AND VALUETYPE(T.DocumentSource) <> TYPE(Document.RecyclableWasteAllocation)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		90
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		INNER JOIN Catalog.ProductionLots AS ProductionLots
	|			ON ProductionLots.Ref = T.CorLot
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|		AND (&AnalyticalAccountingByProductsGroups
	|			AND ProductionLots.ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			AND ProductionLots.ProductsGroup <> T.CorControllingAttributes
	|			OR &AnalyticalAccountingByProductsGroups
	|				AND ProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				AND T.CorControllingAttributes <> UNDEFINED
	|			OR NOT &AnalyticalAccountingByProductsGroups AND T.CorControllingAttributes <> UNDEFINED
	|			)
	|
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		91
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		AND T.LocalCost <> 0
	|		AND T.DocumentRegisterRecords = UNDEFINED
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		92
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		VALUETYPE(T.Recorder) = TYPE(Document.CCDImport)
	|		AND T.RowID = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		93
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.VariancePeriod = DATETIME(1,1,1)
	|		AND (T.BusinessOperation = VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|			OR T.EntryType = VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
	|
	|	UNION ALL
	|
	// In storno register Registered Recorded register, the period of deviation must be filled in.
	|	SELECT DISTINCT
	|		""OtherExpenses"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		94
	|	FROM
	|		AccumulationRegister.OtherExpenses AS T
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.VariancePeriod = DATETIME(1,1,1)
	|		AND (T.ReversingEntry
	|			AND VALUETYPE(T.Recorder) IN (
	|				TYPE(Document.OBEntryOtherExpenses),
	|				TYPE(Document.ReversingEntry))
	|			OR VALUETYPE(T.Recorder) = TYPE(Document.PurchaseAdjustment))
	|
	|	UNION ALL
	|
	// In storno register Registered Recorded register, the period of deviation must be filled in.
	|	SELECT DISTINCT
	|		""ItemisedExpensesLots"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		95
	|	FROM
	|		AccumulationRegister.ItemisedExpensesLots AS T
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND T.Organization IN (&CompanyArray)
	|		AND T.Active
	|		AND NOT T.LotCalculation
	|		AND NOT T.CalculationOfCost
	|		AND T.VariancePeriod = DATETIME(1,1,1)
	|		AND (T.ReversingEntry
	|			AND VALUETYPE(T.Recorder) IN (
	|				TYPE(Document.OBEntryOtherExpenses),
	|				TYPE(Document.ReversingEntry))
	|			OR VALUETYPE(T.Recorder) = TYPE(Document.PurchaseAdjustment))
	|
	|	UNION ALL
	|	
	// Verification of compliance of the cor of the analytics of the expenditure RegisteredRecords and the analytics of the incoming Registered Records.
	// If the accounting section is filled in in the Registered Records, then there must be an incoming Registered Records with analytics 
	// corresponding to the COR Attributes of the expenditure Registered Records.
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		96
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		LEFT JOIN TTMovementCostOfGoods AS RegisterRecordsReceipt
	|			ON RegisterRecordsReceipt.Recorder = T.Recorder
	|			AND RegisterRecordsReceipt.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND RegisterRecordsReceipt.ItemsLocationAttributes = T.CorItemsLocationAttributes
	|			AND RegisterRecordsReceipt.AccountingSection = T.CorAccountingSection
	|			AND RegisterRecordsReceipt.VATActivityType = T.CorVATActivityTypes
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		AND T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		AND NOT T.AccountingSection IN (&OffBalanceSheetAccountingSections)
	|		AND RegisterRecordsReceipt.Recorder IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		97
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		&KeepRecordsOfInventoryCostByAssignments
	|		AND T.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|			<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		AND ISNULL(T.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|			<> T.VATActivityType
	|		AND T.Recorder REFS Document.ReturnOfGoodsToVendor
	|		AND NOT T.AccountingSection IN (&OffBalanceSheetAccountingSections)
	|
	|	UNION ALL
	|	
	// If the document contains the same nomenclature, characteristics and purpose, but with different divisions, 
	// articles and analytics in several lines, then in all such lines there should be batch accounting analytics with different 
	// line code so that the same lines form different batches.
	// Request fill analysts accounting of the parties running in functions of 
	// document Postplasmapheresis. 
	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		UNDEFINED,
	|		98
	|	FROM
	|		(SELECT
	|			T.Recorder,
	|			T.Organization,
	|			T.ItemsLocationAttributes,
	|			SUM(1) AS RowsCount,
	|			MIN(Keys.RowCode) AS RowCode
	|		FROM
	|			TTMovementCostOfGoods AS T
	|			INNER JOIN Catalog.KeysForLotVendorAttributes AS Keys
	|			ON T.LotVendorAttributes = Keys.Ref
	|		WHERE
	|			T.Count > 0
	|			AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND T.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|			AND VALUETYPE(T.Recorder) = TYPE(Document.ReceiptOfServicesToBusinessUnit)
	|			AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		GROUP BY
	|			T.Recorder,
	|			T.Organization,
	|			T.ItemsLocationAttributes
	|		) AS T
	|	WHERE
	|		T.RowsCount > 1
	|		AND T.RowCode = 0
	|	
	|	UNION ALL
	|	





	|	SELECT DISTINCT
	|		""InventoryCost"",
	|		T.Recorder,
	|		T.Organization,
	|		T.BusinessOperation,
	|		99
	|	FROM
	|		TTMovementCostOfGoods AS T
	|	WHERE
	|		T.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND T.EntryType = VALUE(Enum.LotRecordTypes.Consumption) 
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		AND T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.Move)		
	|		AND T.SalesOrder = UNDEFINED
	|	) AS T
	|
	|WHERE
	|	T.ErrorCode <> 0
	|";
	
	Query.Text = QueryTextTTAverageCostOfGoods() + QueryText;
	
	#EndRegion
	
	// Let's form a description of possible error codes in the movements.
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Đối với bản ghi kết chuyển, chưa tìm thấy quy tắc tương ứng điền kiểu bản ghi cho nó';
										|ru = 'Для движения не найдено соответствующее ему правило заполнения типа записи';
										|en = 'A respective record type autofill rule is not found for the register record'; fa = 'A respective record type autofill rule is not found for the register record';
										|it = 'Для движения не найдено соответствующее ему правило заполнения типа записи';
										|pl = 'A respective record type autofill rule is not found for the register record';
										|tr = 'Hareket için karşılık gelen bir kayıt tipi doldurma kuralı bulunamadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Kiểu bản ghi của bản ghi kết chuyển tăng không tương ứng với quy tắc';
										|ru = 'Тип записи приходного движения не соответствует правилу';
										|en = 'The record type of the receipt register record does not match the rule'; fa = 'The record type of the receipt register record does not match the rule';
										|it = 'Тип записи приходного движения не соответствует правилу';
										|pl = 'The record type of the receipt register record does not match the rule';
										|tr = 'Gelen hareket kaydının giriş türü kurala uygun değil'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(3, NStr("vi = 'Kiểu bản ghi của bản ghi kết chuyển giảm không tương ứng với quy tắc';
										|ru = 'Тип записи расходного движения не соответствует правилу';
										|en = 'The record type of the expense register record does not match the rule'; fa = 'The record type of the expense register record does not match the rule';
										|it = 'Тип записи расходного движения не соответствует правилу';
										|pl = 'The record type of the expense register record does not match the rule';
										|tr = 'Gider hareketi kayıt türünün kurala uygun olmaması'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(4, NStr("vi = 'Đối với doanh nghiệp có phương pháp định giá theo ""FIFO (liên hoàn)"", chưa điền lô đầu tiên';
										|ru = 'Для организаций с методом оценки ""ФИФО (скользящая)"" не заполнена первичная партия';
										|en = 'Primary lot for companies with the ""FIFO (rolling valuation)"" evaluation method is not filled in'; fa = 'Primary lot for companies with the ""FIFO (rolling valuation)"" evaluation method is not filled in';
										|it = 'Per l''organizzazione con metodo di classificazione ""FIFO (scorrevole)"" il lotto principale non è compilato';
										|pl = 'Dla firm z metodą oceny ""ФИФО (скользящая)"" nie jest wypełniona partia pierwotna';
										|tr = '""FIFO (yuvarlanan)"" değerleme yöntemine sahip iş yerleri için birincil lot doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(5, NStr("vi = 'Đối với doanh nghiệp có phương pháp đánh giá không phải là FIFO (đánh giá trượt), điền lô hàng chính hoặc lô hàng đối ứng';
										|ru = 'Для организаций с методом оценки, отличным от ""ФИФО (скользящая)"", заполнена первичная партия или кор. партия';
										|en = 'Primary lot or corr. lot is filled in for companies with evaluation method other than ""FIFO (rolling valuation)""'; fa = 'Primary lot or corr. lot is filled in for companies with evaluation method other than ""FIFO (rolling valuation)""';
										|it = 'Per l''organizzazione con metodo di classificazione diverso da ""FIFO (scorrevole)"" il lotto principale o il partito corr. è compilato';
										|pl = 'Dla firm z metodą oceny, różniącą się od ""ФИФО (скользящая)"", jest wypełniona partia pierwotna lub kor. partia';
										|tr = '""FIFO (yuvarlanan)"" dışında bir değerleme yöntemine sahip iş yerleri için, birincil lot veya düzeltme lot dolduruldu'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(6, NStr("vi = 'Đối với doanh nghiệp có phương pháp ""Định giá theo FIFO (liên hoàn)"", điền sai lô đối ứng trong bản ghi kết chuyển xuất';
										|ru = 'Для организаций с методом оценки ""ФИФО (скользящая)"" некорректно заполнена кор. партия в расходном движении';
										|en = 'For companies with the ""FIFO (rolling valuation)"" evaluation method, the correspondent lot is filled incorrectly in the expense register record'; fa = 'For companies with the ""FIFO (rolling valuation)"" evaluation method, the correspondent lot is filled incorrectly in the expense register record';
										|it = 'Для организаций с методом оценки ""ФИФО (скользящая)"" некорректно заполнена кор. партия в расходном движении';
										|pl = 'For companies with the ""FIFO (rolling valuation)"" evaluation method, the correspondent lot is filled incorrectly in the expense register record';
										|tr = '""FIFO (yuvarlanan)"" değerleme yöntemine sahip iş yerleri için, gider hareketindeki düzeltme lot yanlış dolduruldu'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(7, NStr("vi = 'Kiểu bản ghi đã chỉ ra trong bản ghi kết chuyển không được dùng khi phân bổ lô hàng';
										|ru = 'Тип записи, указанный в движении, не используется при распределении партий';
										|en = 'Record type specified in the movement is not used in lot allocation'; fa = 'Record type specified in the movement is not used in lot allocation';
										|it = 'Il tipo di registrazione, indicato nel movimento, non viene utilizzato durante l''allocazione dei lotti';
										|pl = 'Typ zapisu, wskazany w ruchu, nie jest używany podczas podziału partii';
										|tr = 'Harekette belirtilen kayıt türü lotlarının tahsisinde kullanılmaz'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(8, NStr("vi = 'Đối tượng phân tích kế toán lô hàng không chứa dạng giá trị';
										|ru = 'Аналитика учета партий не содержит вида ценности';
										|en = 'Dimension (Lot accounting) does not contain an asset tax class'; fa = 'Dimension (Lot accounting) does not contain an asset tax class';
										|it = 'L''analitica di contabilità dei lotti non contiene alcun tipo di valore';
										|pl = 'Analityka ewidencji partii nie zawiera rodzaju wartości';
										|tr = 'Lot muhasebe boyutu değer türünü içermez'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(9, NStr("vi = 'Đối tượng phân tích kế toán lô hàng đối ứng không chứa dạng giá trị';
										|ru = 'Кор. аналитика учета партий не содержит вида ценности';
										|en = 'Dimension (Lot accounting) does not contain asset tax class'; fa = 'Dimension (Lot accounting) does not contain asset tax class';
										|it = 'L''analitica corr. di contabilizzazione dei lotti non contiene alcun tipo di valore';
										|pl = 'Коr. analityka ewidencji partii nie zawiera rodzaju wartości';
										|tr = 'Lot muhasebenin ilgili boyutu değer türünü içermez'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(10, NStr("vi = 'Chưa điền dạng hoạt động thuế GTGT khi điền đối tượng phân tích kế toán lô hàng';
										|ru = 'Не заполнен вид деятельности НДС при заполненной аналитике учета партий';
										|en = 'VAT activity type is not specified while lot: vendor attributes are filled in'; fa = 'VAT activity type is not specified while lot: vendor attributes are filled in';
										|it = 'Il tipo di attività IVA non viene compilato quando l''analitica di contabilità dei lotti è compilata';
										|pl = 'Nie jest wypełniony rodzaj działalności VAT przy wypełnionej analityce ewidencji partii';
										|tr = 'Lot satıcı özniteliği doldurulurken faaliyet türü KDV doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(11, NStr("vi = 'Đối với đối tượng phân tích kế toán lô hàng xuất xưởng sản phẩm, chưa điền mã dòng (sản phẩm)';
										|ru = 'Для аналитики учета партий выпуска изделий не заполнен код строки (продукции)';
										|en = 'Line (product) code is not specified for lot: vendor attributes of product release'; fa = 'Line (product) code is not specified for lot: vendor attributes of product release';
										|it = 'Per l''analitica di contabilizzazione dei lotti di emissione degli elaborati non è compilato il codice della riga (della produzione)';
										|pl = 'Dla analityki ewidencji partii zwolnienia wyrobów nie jest wypełniony kod wiersza (produkcji)';
										|tr = 'Nihai ürün sürüm lotlarının muhasebeleştirilmesi boyutu için hiçbir satır kodu (imal edilen ürünler) doldurulmamıştır'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(12, NStr("vi = 'Chưa điền đối tượng phân tích kế toán mặt hàng đối ứng cho giao dịch ""Bán hàng (hàng đi đường)""';
										|ru = 'Не заполнена кор. аналитика учета номенклатуры для операции ""Реализация (товары в пути)""';
										|en = 'Cor. inventory location attributes are not filled in for ""Customer invoice — Goods-in-transit""'; fa = 'Cor. inventory location attributes are not filled in for ""Customer invoice — Goods-in-transit""';
										|it = 'Per l''operazione ""Vendita (merce in transito)"" non è indicata l''analitica corr. di contabilizzazione dell''articolo';
										|pl = 'Nie jest wypełniona kor. analityka ewidencji nomenklatury dla operacji ""Реализация (товары в пути)""';
										|tr = '""Satışlar (transit mallar)"" işlemi için ilgili muhasebe boyutu öğesi doldurulmamıştır'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(13, NStr("vi = 'Đối với các chứng từ nhận hàng bán bị trả lại từ khách hàng/doanh nghiệp vào kho khác với kho bán hàng, sử dụng sai giao dịch kinh tế và kiểu bản ghi';
										|ru = 'Для документов возврата товаров от клиента/организации на склад, отличный от склада реализации, используются неправильные хозяйственные операции и типы записей';
										|en = 'Incorrect business transactions and record types are used for the documents for goods return from customer/company to the warehouse other than the sales warehouse'; fa = 'Incorrect business transactions and record types are used for the documents for goods return from customer/company to the warehouse other than the sales warehouse';
										|it = 'Per i documenti di reso delle merci da un cliente / organizzazione a un magazzino diverso dal magazzino di realizzo, vengono utilizzate operazioni commerciali e tipi di record errati';
										|pl = 'Dla dokumentów zwrotu towarów od klienta/ firmy na magazyn, różniącego się od magazynu realizacji, są stosowane  nieprawidłowe operacje gospodarcze i rodzaje wpisów';
										|tr = 'Bir müşteriden/iş yerinden satış ambarı dışındaki bir ambara iade edilen ürünlerin belgeleri için yanlış ticari işlemler ve kayıt türleri kullanılır'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(14, NStr("vi = 'Chưa điền dạng hoạt động thuế GTGT trong các bản ghi kết chuyển nhập có kiểu bản ghi ""Lô hàng""';
										|ru = 'Не заполнен вид деятельности НДС у приходных движений с типом записи ""Партия""';
										|en = 'VAT activity type is not specified for receipt records with the ""Lot"" record type'; fa = 'VAT activity type is not specified for receipt records with the ""Lot"" record type';
										|it = 'Il tipo di attività IVA dei movimenti di entrata con tipo di registrazione ""Lotto"" non è compilato';
										|pl = 'Nie jest wypełniony rodzaj działalności VAT w ruchach przychodzących z rodzajem zapisu ""Партия""';
										|tr = 'Kayıt tipi ""Lot"" olarak gelen hareketler için faaliyet türü KDV doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(15, NStr("vi = 'Đối với các chứng từ xuất xưởng đã phát hiện các bản ghi kết chuyển âm về phế liệu thu hồi khi sản xuất sản phẩm gia công';
										|ru = 'Для документов выпуска обнаружены отрицательные движения по возвратным отходам при производстве давальческой продукции';
										|en = 'Negative records of recyclable waste on production of material provider products are found for release documents.'; fa = 'Negative records of recyclable waste on production of material provider products are found for release documents.';
										|it = 'Per i documenti di emissione, sono stati rilevati movimenti negativi per gli scarti di recupero durante la fabbricazione dei prodotti del committente';
										|pl = 'Dla dokumentów wydania są ujawnione ujemne przepływy w odpadach zwrotnych podczas wytwarzania produkcji właściciela surowca';
										|tr = 'Üretim belgeleri için tedarikçi üzerine imal edilen ürünlerin geri dönüştürülebilir atıklara ilişkin olumsuz hareketler tespit edilmiştir'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(16, NStr("vi = 'Đã điền sai đối tượng phân tích kế toán xuất xưởng phế liệu thu hồi (đối tượng phân tích kế toán mặt hàng đối ứng, đối tượng phân tích đối ứng trong kế toán tài chính).';
										|ru = 'Неправильно заполнена аналитика учета выпуска возвратных отходов (кор. аналитика учета номенклатуры, кор. аналитика финансового учета).';
										|en = 'Accounting dimension of recyclable waste release is filled in incorrectly (corr. inventory location attributes, corr. financial accounting dimension).'; fa = 'Accounting dimension of recyclable waste release is filled in incorrectly (corr. inventory location attributes, corr. financial accounting dimension).';
										|it = 'Analitica di contabilizzazione dell''emissione degli scarti di recupero incorrettamente compilata (analitica corrispondente di contabilizzazione dell''articolo, analitica corrispondente della contabilità finanziaria).';
										|pl = 'Nieprawidłowo jest wypełniona analityka ewidencji wydania odpadów zwrotnych (kor. analityka ewidencji nomenklatury, kor. analityka ewidencji finansowej).';
										|tr = 'Geri dönüştürülebilir atık konusunun muhasebesinin boyutunda yanlış dolduruldu (ilgili stok konum öznitelikleri, ilgili mali hesap boyutu).'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(17, NStr("vi = 'Chưa điền chứng từ là nguồn giao dịch ""Chi phí bổ sung có chỉ ra chứng từ lô hàng"".';
										|ru = 'Не заполнен документ - источник для операции ""Дополнительные расходы с указанием документа партии"".';
										|en = 'Source document is required for the ""Additional expenses with lot document specification"" operation.'; fa = 'Source document is required for the ""Additional expenses with lot document specification"" operation.';
										|it = 'Documento non compilato - sorgente per l''operazione ""Spese aggiuntive con indicazione del documento del lotto"".';
										|pl = 'Nie jest wypełniony dokument - źródło dla operacji ""Дополнительные расходы с указанием документа партии"".';
										|tr = '""Lot belge ile ek giderler"" işlemi için kaynak belge doldurulmadı.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(18, NStr("vi = 'Điền chứng từ-nguồn trong bảng ghi kết chuyển tăng không tương ứng với quy tắc.';
										|ru = 'Заполнение документа-источника в приходном движении не соответствует правилу.';
										|en = 'The source document population in the receipt register record does not match the rule.'; fa = 'The source document population in the receipt register record does not match the rule.';
										|it = 'Заполнение документа-источника в приходном движении не соответствует правилу.';
										|pl = 'The source document population in the receipt register record does not match the rule.';
										|tr = 'Gelen harekette kaynak belgenin tamamlanması kurala uygun değildir.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(19, NStr("vi = 'Điền chứng từ-nguồn trong bản ghi kết chuyển giảm không tương ứng với quy tắc.';
										|ru = 'Заполнение документа-источника в расходном движении не соответствует правилу.';
										|en = 'The source document population in the expense register record does not match the rule.'; fa = 'The source document population in the expense register record does not match the rule.';
										|it = 'Заполнение документа-источника в расходном движении не соответствует правилу.';
										|pl = 'The source document population in the expense register record does not match the rule.';
										|tr = 'Gider hareketinde kaynak belgenin tamamlanması kurala uygun değildir.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(20, NStr("vi = 'Chưa điền đối tượng phân tích kế toán lô hàng đối ứng của bản ghi kết chuyển nhập có kiểu bản ghi ""Lô hàng"" hoặc ""Điều chỉnh mua hàng"" đối với các doanh nghiệp áp dụng phương pháp đánh giá hàng tồn kho khác với ""FIFO (đánh giá trượt)""';
										|ru = 'Не заполнена кор. аналитика учета партий приходных движений с типом записи ""Партия"" или ""Корректировка приобретения"" для организаций с методом оценки, отличным от ""ФИФО (скользящая)""';
										|en = 'Corr. dimension (Lot accounting) of receipt record with the ""Lot"" or ""Purchase adjustment"" record type is not filled in for companies using an evaluation method different form ""FIFO (rolling valuation)""'; fa = 'Corr. dimension (Lot accounting) of receipt record with the ""Lot"" or ""Purchase adjustment"" record type is not filled in for companies using an evaluation method different form ""FIFO (rolling valuation)""';
										|it = 'Analitica corrispondente della contabilizzazione dei lotti di movimenti in entrata con tipo di registrazione ""Lotto"" o ""Correzione di acquisto"" per le aziende con metodo di classificazione diverso da ""FIFO (scorrevole)"" non compilata';
										|pl = 'Nie jest wypełniona kor. analityka ewidencji partii ruchów przychodzących z rodzajem wpisów ""Partia"" lub ""Korekta zakupu"" dla firm z metodą oceny, różniącą się od ""FIFO (przesuwna)""';
										|tr = '""FIFO (yuvarlanan)"" dışında bir değerleme yöntemine sahip iş yerleri için kayıt tipi ""Lot"" veya ""Satın alma düzeltmesi"" olan gelen hareketlerin lot muhasebesinin boyutu doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(21, NStr("vi = 'Chưa điền kỳ bán hàng đối với giao dịch ""Nhận hàng bán kỳ trước bị trả lại""';
										|ru = 'Не заполнен период продажи для операции ""Возврат товаров от клиента прошлых периодов""';
										|en = 'Sale period is required for the ""Sales return of previous periods"" operation'; fa = 'Sale period is required for the ""Sales return of previous periods"" operation';
										|it = 'Il periodo di vendita per l''operazione ""Reso dei prodotti dal cliente dei periodi passati"" non è compilato';
										|pl = 'Nie jest wypełniony okres sprzedaży dla operacji ""Возврат товаров от клиента прошлых периодов""';
										|tr = '""Önceki dönemlere ait müşteriden ürün iadesi"" işlemi için satış dönemi doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(22, NStr("vi = 'Chưa điền mục tin đối ứng cho giao dịch ""Mua hàng theo kế toán tài chính""';
										|ru = 'Не заполнены кор. реквизиты для операции ""Закупка по регл. учету""';
										|en = 'Cor. attributes are required for the ""Purchase by local accounting"" operation'; fa = 'Cor. attributes are required for the ""Purchase by local accounting"" operation';
										|it = 'Requisiti corrispondenti per l''operazione ""Acquisto per la contabilità regolamentare"" non compilati';
										|pl = 'Nie są wypełnione kor. atrybuty dla operacji ""Закупка по регл. учету""';
										|tr = '""Yerel muhasebe kapsamında satın alma"" işlemi için düzeltme öznitelikler doldurulmamıştır'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(23, NStr("vi = 'Trong sản xuất dở dang, để làm lô hàng sản xuất có sử dụng tham chiếu đến phần tử hệ thống của danh mục ""Lô hàng sản xuất""';
										|ru = 'В незавершенном производстве в качестве партии производства используется ссылка на служебный элемент справочника ""Партии производства""';
										|en = 'In unfinished production, a link to a service item of the ""Production lots"" catalog is used as a production lot'; fa = 'In unfinished production, a link to a service item of the ""Production lots"" catalog is used as a production lot';
										|it = 'Nella produzione in corso, come lotto di produzione viene utilizzato il riferimento all''elemento di servizio della directory ""Lotti di produzione""';
										|pl = 'W produkcji w toku, jako partia produkcji, odniesienie jest używane do elementu usługi w katalogu „Partie produkcji”.';
										|tr = 'Devam eden imalatta, üretim lotu olarak ""Üretim lotları"" katalog hizmet öğesine bir bağlantı kullanılır'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(24, NStr("vi = 'Chưa điền đối tượng phân tích kế toán theo bạn hàng trong các bản ghi kết chuyển của chứng từ bán hàng';
										|ru = 'Не заполнена аналитика учета по партнерам в движениях документов продажи';
										|en = 'Accounting dimension by partners is required for sales document register records'; fa = 'Accounting dimension by partners is required for sales document register records';
										|it = 'L''analitica di contabilità secondo i partner nei movimenti dei documenti di vendita non è compilata';
										|pl = 'Nie jest wypełniona analityka ewidencji wg partnerów w ruchach dokumentów sprzedaży';
										|tr = 'Satış belgelerinin hareketlerindeki iş ortağı muhasebe boyutu doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(25, NStr("vi = 'Chưa điền đối tượng phân tích đối ứng kế toán lô hàng trong các bản ghi kết chuyển nhập có kiểu bản ghi ""Chi phí bổ sung (chưa chỉ ra lô hàng)"" và ""Chi phí bổ sung (có chỉ ra lô hàng)""';
										|ru = 'Не заполнена кор. аналитика учета партий в приходных движениях с типом записей ""Доп. расходы (не указана партия)"" и ""Доп. расходы (указана партия)""';
										|en = 'Corr. dimension (Lot accounting) is required for receipt movements with the ""Add. expenses (lot is not specified)"" and ""Add. expenses (lot is specified)"" record types'; fa = 'Corr. dimension (Lot accounting) is required for receipt movements with the ""Add. expenses (lot is not specified)"" and ""Add. expenses (lot is specified)"" record types';
										|it = 'L''analitica corrispondente di contabilizzazione dei lotti nei movimenti di entrata con tipo di registrazione ""Spese aggiuntive (lotto non indicato)"" e ""Spese aggiuntive (lotto indicato)"" non è compilata';
										|pl = 'Nie jest wypełniona kor. analityka ewidencji partii w ruchach przychodzących z rodzajem zapisów ""Доп. расходы (не указана партия)"" oraz ""Доп. расходы (указана партия)""';
										|tr = 'Düzeltme kayıt tipi ""Ek giderler (lot belirtilmemiş)"" ve ""Ek giderler (lot  belirtilmiş)"" olan gelen hareketlerde lot muhasebesi boyutu doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(26, NStr("vi = 'Trong bản ghi kết chuyển theo phân bổ nguyên vật liệu tại bảng kê bên nhận gia công đã điền mục tin ""Nhóm sản phẩm"".';
										|ru = 'В движениях по распределению материалов в отчете переработчика заполнен реквизит ""Группа продукции"".';
										|en = '""Inventory group"" attribute is filled in material allocation movements in ""Subcontracting services notification received"".'; fa = '""Inventory group"" attribute is filled in material allocation movements in ""Subcontracting services notification received"".';
										|it = 'Nei movimenti di allocazione dei materiali nel report dell''elaboratore è compilato il requisito ""Gruppo di produzione"".';
										|pl = 'W ruchach dotyczących podziału materiałów w raporcie przetwórcy jest wypełniony atrybut  ""Grupa produkcji"".';
										|tr = '""Grup imal edilen ürünler"" özniteliği, fason üretici raporundaki malzeme dağılımına ilişkin hareketlerde doldurulur.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(27, NStr("vi = 'Trong các bản ghi kết chuyển về xuất xưởng sản phẩm, việc điền các mục tin ""Đối tượng phân tích kế toán tài chính"" và ""Nhóm sản phẩm"" là khác nhau.';
										|ru = 'В движениях по выпуску продукции отличается заполнение реквизитов ""Аналитика финансового учета"" и ""Группа продукции"".';
										|en = 'In product release movements, the ""Financial accounting dimension"" and ""Inventory group"" attributes are filled in differently.'; fa = 'In product release movements, the ""Financial accounting dimension"" and ""Inventory group"" attributes are filled in differently.';
										|it = 'Nei movimenti di emissione della produzione la compilazione del requisito ""Analitica della contabilità finanziaria"" differisce da quella del requisito ""Gruppo di produzione"".';
										|pl = 'W ruchach wydania produkcji różni się wypełnienie atrybutów ""Analityka ewidencji finansowej"" i ""Grupa produkcji"".';
										|tr = 'İmal edilen ürünlerin üretim hareketlerde ""Finansal muhasebe boyutu"" ve ""Grup imal edilen ürünler"" özniteliklerinin doldurulması farklıdır.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(28, NStr("vi = 'Đã điền sai phần hành kế toán đối với giao dịch ""Bảng kê ký gửi giữa các doanh nghiệp""';
										|ru = 'Не корректно заполнен раздел учета для операции ""Отчет по комиссии между организациями""';
										|en = 'Accounting section for the ""Commission sales report — Intercompany"" operation is filled in incorrectly'; fa = 'Accounting section for the ""Commission sales report — Intercompany"" operation is filled in incorrectly';
										|it = 'Sezione contabile per l''operazione ""Rapporto sulla commissione tra le società""';
										|pl = 'Nie poprawnie jest wypełniony rozdział ewidencji dla operacji ""Raport po komisji sprawdzającej pomiędzy firmami""';
										|tr = '""İşyerleri arası komisyon satış raporu"" işlemi için muhasebe bölümü doğru şekilde doldurulmamıştır'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(30, NStr("vi = 'Đã điền sai dạng hoạt động thuế GTGT đối với chứng từ ""Tờ khai hải quan nhập khẩu"".';
										|ru = 'Не корректно заполнен кор. вид деятельности НДС для документа ""Таможенная декларация на импорт"".';
										|en = 'The cor VAT activity type is filled incorrectly for the ""Customs declaration for import"" document.'; fa = 'The cor VAT activity type is filled incorrectly for the ""Customs declaration for import"" document.';
										|it = 'Il tipo corrispondente di attività IVA per il documento ""Dichiarazione doganale di importazione"" non è compilato correttamente.';
										|pl = 'Nieprawidłowo wypełniony rodzaj działalności VAT dla dokumentu „Importowa deklaracja celna”.';
										|tr = '""İthalat için gümrük beyannamesi"" belgesi için düzeltme faaliyet türü KDV doğru doldurulmadı.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(31, NStr("vi = 'Đã điền sai dạng hoạt động thuế GTGT trong bản ghi kết chuyển nhập của chứng từ.';
										|ru = 'Не корректно заполнен вид деятельности НДС в приходном движении документа.';
										|en = 'The VAT activity type in receipt document register record is filled in incorrectly.'; fa = 'The VAT activity type in receipt document register record is filled in incorrectly.';
										|it = 'Tipo di attività IVA non compilato correttamente nel movimento in entrata del documento.';
										|pl = 'Rodzaj działalności jest wypełniony niepoprawnie w ruchu przychodzącym dokumentu.';
										|tr = 'Belge giriş hareketinde faaliyet türü KDV doğru doldurulmadı.'"));
	DecodingErrorCodes.Insert(32, NStr("vi = 'Đã điền sai kiểu bản ghi trong bản ghi kết chuyển nhập đối với chứng từ ""Sản xuất không có đơn hàng""';
										|ru = 'Не корректно заполнен тип записи в приходном движении для документа ""Производство без заказа"".';
										|en = 'The entry type in receipt movements for the document ""Backflush production"" is filled in incorrectly.'; fa = 'The entry type in receipt movements for the document ""Backflush production"" is filled in incorrectly.';
										|it = 'Il tipo di voce nel movimento d''incasso per il documento ""Produzione senza un ordine"" non è stato compilato correttamente.';
										|pl = 'Został niepoprawnie wypełniony rodzaj wpisu w ruchu przychodowym dla dokumentu ""Produkcja bez zamówienia"".';
										|tr = '""Geriye dönük üretim"" belgesi için giriş hareketindeki kayıt türü doğru doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(33, NStr("vi = 'Sai bản ghi kết chuyển thay đổi mục đích công việc trong chứng từ ""Công đoạn sản xuất"".';
										|ru = 'Не корректные движения по изменению назначения работ для документа ""Этап производства"".';
										|en = 'Incorrect records to change the job assignments for the ""Production stage"" document.'; fa = 'Incorrect records to change the job assignments for the ""Production stage"" document.';
										|it = 'Movimento non corretto per modificare l''assegnazione del lavoro per il documento ""Fase di produzione"".';
										|pl = 'Nieprawidłowe ruchy według zmiany  przeznaczenia prac dla dokumentu ""Etap produkcji"".';
										|tr = 'Üretim aşaması belgesi için iş atamasını değiştirmeye yönelik hatalı hareketler.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(34, NStr("vi = 'Sai bản ghi kết chuyển theo phần hành ghi nhận ""Chi phí sản xuất"".';
										|ru = 'Некорректные движения по разделу учета ""Производственные затраты"".';
										|en = 'Incorrect movements on the ""Production costs"" accounting section.'; fa = 'Incorrect movements on the ""Production costs"" accounting section.';
										|it = 'Movimenti non corretti relativi alla sezione della contabilità ""Spese di produzione"".';
										|pl = 'Nieprawidłowe ruchy według rozdziału ewidencji ""Koszty produkcji"".';
										|tr = '""Üretim maliyetleri"" muhasebe bölümündeki hatalı hareketler.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(35, NStr("vi = 'Chưa điền mục tin ""Chứng từ bản ghi kết chuyển"" trong bản ghi kết chuyển của thành phẩm theo giá trị cố định.';
										|ru = 'Не заполнен реквизит ""Документ движения"" в движениях продукции по фиксированной стоимости.';
										|en = 'Attribute ""Transfer record"" is required for fixed-cost product transfer records.'; fa = 'Attribute ""Transfer record"" is required for fixed-cost product transfer records.';
										|it = 'Il requisito ""Documento di movimento"" nei movimenti di prodotti a prezzo fisso non è compilato.';
										|pl = 'Nie wypełniono atrybutu ""Dokument ruchu"" w ruchach produkcji według wartości ustalonej.';
										|tr = 'Sabit maliyetli ürünlerin kayıtlarında ""Transfer kaydı"" özniteliği doldurulmamıştır.'"));
	DecodingErrorCodes.Insert(36, NStr("vi = 'Sai bản ghi kết chuyển của chứng từ ""Điều chỉnh mua"".';
										|ru = 'Некорректные движения документа ""Корректировка приобретения"".';
										|en = 'Invalid records in the ""Purchase adjustment"" document.'; fa = 'Invalid records in the ""Purchase adjustment"" document.';
										|it = 'Movimenti non corretti del documento ""Correzione di acquisto"".';
										|pl = 'Niepoprawne ruchy dokumentu ""Korekta zakupu"".';
										|tr = '""Satın alma düzeltmesi"" belgesinin hatalı hareketleri.'"));
	DecodingErrorCodes.Insert(37, NStr("vi = 'Sai phần hành ghi nhận đối với các bản ghi kết chuyển trong kho xưởng.';
										|ru = 'Неправильный раздел учета для движений в цеховой кладовой.';
										|en = 'Invalid accounting section for transfer in the shop floor stockrooms.'; fa = 'Invalid accounting section for transfer in the shop floor stockrooms.';
										|it = 'Sezione contabile non corretta per i movimenti di magazzino del reparto.';
										|pl = 'Nieprawidłowy rozdział ewidencji dla ruchów w magazynie spiżarni.';
										|tr = 'Atölye deposundaki hareketler için yanlış muhasebe bölümü.'"));
	DecodingErrorCodes.Insert(38, NStr("vi = 'Sai phần hành ghi nhận đối với các bản ghi kết chuyển theo kho mà không phải là kho xưởng.';
										|ru = 'Неправильный раздел учета для движений по складу, который не является цеховой кладовой.';
										|en = 'Invalid accounting section for transfer in the warehouse which is not a shop floor stockroom.'; fa = 'Invalid accounting section for transfer in the warehouse which is not a shop floor stockroom.';
										|it = 'Sezione contabile non corretta per i movimenti di magazzino che non è un magazzino del reparto.';
										|pl = 'Nieprawidłowy rozdział ewidencji dla ruchów w magazynie, który nie jest komórką wytwórni.';
										|tr = 'Atölye deposu olmayan bir ambardaki hareketler için yanlış muhasebe bölümü.'"));
	DecodingErrorCodes.Insert(39, NStr("vi = 'Sai dạng bản ghi kết chuyển của chứng từ ""Phản ánh thu nhập và chi phí khác"".';
										|ru = 'Неправильный вид движения документа ""Отражение прочих доходов и расходов"".';
										|en = 'Wrong type of register records of the ""Non-operating income and expenses"" document.'; fa = 'Wrong type of register records of the ""Non-operating income and expenses"" document.';
										|it = 'Неправильный вид движения документа ""Отражение прочих доходов и расходов"".';
										|pl = 'Wrong type of register records of the ""Non-operating income and expenses"" document.';
										|tr = '""Diğer gelirlerin ve giderlerin yansıtılması"" belge kayıt tablosunun hareket türü yanlış.'"));
	DecodingErrorCodes.Insert(40, NStr("vi = 'Sai phân hệ kế toán cho hàng hóa lưu kho có quyền bán.';
										|ru = 'Неправильный раздел учета для товаров на хранении с правом продажи.';
										|en = 'Incorrect accounting section for goods at storage with the right of sale.'; fa = 'Incorrect accounting section for goods at storage with the right of sale.';
										|it = 'La sezione di contabilità non corretta per le merci in magazzino con diritto di vendita.';
										|pl = 'Nie prawidłowy rozdział ewidencji dla towaru do przechowywania z prawem sprzedaży.';
										|tr = 'Satış yetkisi ile depolanan mallar için yanlış muhasebe bölümü.'"));
	DecodingErrorCodes.Insert(41, NStr("vi = 'Sai bản ghi kết chuyển của chứng từ ""Điều chỉnh mục đích hàng hóa"" khi tắt ghi nhận giá vốn theo mục đích.';
										|ru = 'Некорректные движения документа ""Корректировка назначения товаров"" при отключенном учете себестоимости по назначениям.';
										|en = 'Incorrect records in the ""Inventory assignment adjustment"" document with disabled cost accounting by destinations.'; fa = 'Incorrect records in the ""Inventory assignment adjustment"" document with disabled cost accounting by destinations.';
										|it = 'Movimenti non corretti del documento ""Rettifica di destinazione articoli"" con registrazione contabile del costo secondo le destinazioni disattivata.';
										|pl = 'Nieprawidłowe ruchy dokumentu ""Zapis korygujący przeznaczenia towarów"" z odłączoną ewidencją kosztów własnych wg przeznaczeń.';
										|tr = 'Atamalara göre maliyet muhasebesi devre dışı bırakıldığında ""Stok atama düzeltmesi"" belgesinin hatalı hareketleri.'"));
	DecodingErrorCodes.Insert(42, NStr("vi = 'Trong bản ghi kết chuyển đã điền mục tin ""Giá trị điều chỉnh"".';
										|ru = 'В движениях заполнен реквизит ""Кор стоимость"".';
										|en = 'The ""Cor cost"" attribute is filled in the register records.'; fa = 'The ""Cor cost"" attribute is filled in the register records.';
										|it = 'Il requistito ""Costo corrispondente"" nei movimenti è compilato.';
										|pl = 'W przepływach wypełniono atrybut ""Kor wartość"".';
										|tr = 'Hareketlerde ""Düzeltme maliyet"" özniteliği doldurulur.'"));
	DecodingErrorCodes.Insert(43, NStr("vi = 'Chưa điền dạng thu nhập trong bản ghi kết chuyển của chứng từ ""Hàng hỏng"".';
										|ru = 'Не заполнена статья доходов в движениях документа ""Порча товаров"".';
										|en = 'The income item in the ""Stock quality change"" document records cannot be empty.'; fa = 'The income item in the ""Stock quality change"" document records cannot be empty.';
										|it = 'La voce di entrata ""Deterioramento delle merci"" nei movimenti del documento non è compilata.';
										|pl = 'Nie wypełniono rodzaju przychodów w ruchach dokumentu ""Uszkodzenie towarów""';
										|tr = '""Stok kalite değişikliği"" belgesinin hareketlerindeki gelir kalemi doldurulmamıştır.'"));
	DecodingErrorCodes.Insert(44, NStr("vi = 'Dạng hoạt động thuế GTGT trong bản ghi kết chuyển nhập không tương ứng với lô hàng sản xuất.';
										|ru = 'Вид деятельности НДС в приходном движении не соответствует партии производства.';
										|en = 'VAT activity type in receipt record does not match production lot.'; fa = 'VAT activity type in receipt record does not match production lot.';
										|it = 'Tipo di attività IVA nel movimento di entrata non corrisponde al lotto di produzione.';
										|pl = 'Rodzaj działalności VAT w ruchu przychodzącym nie odpowiada partii produkcji.';
										|tr = 'Giriş hareketindeki faaliyet türü KDV üretim lotuna karşılık gelmemektedir.'"));
	DecodingErrorCodes.Insert(45, NStr("vi = 'Sai phân hệ kế toán đối với hàng đặt riêng.';
										|ru = 'Неправильный раздел учета для собственных товаров.';
										|en = 'Incorrect accounting section for own goods items.'; fa = 'Incorrect accounting section for own goods items.';
										|it = 'Sezione contabile errata per propri prodotti.';
										|pl = 'Nie prawidłowy podział ewidencji dla towarów własnych.';
										|tr = 'Özel ürünler için yanlış muhasebe bölümü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(46, NStr("vi = 'Sai kiểu bản ghi trong bản ghi kết chuyển ghi giảm nguyên vật liệu chưa sử dụng vào chi phí.';
										|ru = 'Неправильный тип записи в движениях списания неизрасходованных материалов на расходы.';
										|en = 'Incorrect record type in transactions to write off unspent materials to expenses.'; fa = 'Incorrect record type in transactions to write off unspent materials to expenses.';
										|it = 'Tipo di voce errata nei movimenti di storno di materiali non usati nelle spese.';
										|pl = 'Nie prawidłowy typ zapisywania w ruchach rozchodowania niewykorzystanych materiałów na rozchody.';
										|tr = 'Harcanmamış malzemeleri gider yazmak için hareketlerde yanlış giriş türü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(47, NStr("vi = 'Chưa điền tên định danh của dòng trong bản ghi kết chuyển chứng từ ""Mua hàng hóa dịch vụ"".';
										|ru = 'Не заполнен идентификатор строки в движениях документа ""Приобретение товаров услуг"".';
										|en = 'The line ID is missing in the ""Vendor invoice"" document records.'; fa = 'The line ID is missing in the ""Vendor invoice"" document records.';
										|it = 'ID della stringa nei movimenti del documento ""Acquisto di beni e servizi"" non compilato.';
										|pl = 'Nie wypełniono identyfikatora wierszu w ruchach dokumentu ""Nabycie towarów usług"".';
										|tr = '""Ürün ve hizmet alımı"" belgesinin hareketlerindeki satır tanımlayıcısı doldurulmamıştır.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(48, NStr("vi = 'Bản ghi kết chuyển thừa của chứng từ ""Điều chỉnh số dư mở hàng hóa trong doanh nghiệp"".';
										|ru = 'Лишние движения документа ""Исправление развернутого сальдо товаров организаций"".';
										|en = 'Extra records of the document ""Correction of detailed balance of company goods"".'; fa = 'Extra records of the document ""Correction of detailed balance of company goods"".';
										|it = 'Movimenti in eccesso del documento ""Rettifica del saldo esplicativo delle merci aziendali"".';
										|pl = 'Zbędne ruchy dokumenty ""Korekta rozwiniętego salda towarów firm"".';
										|tr = '""İş yerlerinin katlanmamış ürün bakiyesinin düzeltilmesi"" belgesinin gereksiz hareketleri.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(49, NStr("vi = 'Sai phần hành kế toán ""Hàng đi đường (giao hàng mà chưa chuyển giao quyền sở hữu)"" đối với hàng hóa ký gửi.';
										|ru = 'Неправильный раздел учета ""Товары в пути (отгрузка без перехода права собственности)"" для комиссионных товаров.';
										|en = 'Incorrect accounting section ""Goods in transit (shipment with deferred transfer of title of goods)"" for consignment goods.'; fa = 'Incorrect accounting section ""Goods in transit (shipment with deferred transfer of title of goods)"" for consignment goods.';
										|it = 'Sezione contabile errata ""Merci in transito (spedizione senza il passaggio di proprietà)"" per le merci in conto vendita.';
										|pl = 'Nieprawidłowy rozdział ewidencji ""Towary w drodze (wysyłka bez przejścia prawa własności)"" dla towarów komisowych.';
										|tr = 'Komisyon ürünleri için hatalı muhasebe bölümü ""Transit mallar (mülkiyet devri olmadan sevkiyat)"".'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(51, NStr("vi = 'Sai phần hành kế toán trong bản ghi kết chuyển ghi giảm hàng hóa ký gửi.';
										|ru = 'Не правильный раздел учета в движениях списания комиссионного товара.';
										|en = 'Incorrect accounting section in the consigned goods write-off records.'; fa = 'Incorrect accounting section in the consigned goods write-off records.';
										|it = 'Sezione di contabilità non valida nei movimenti di cancellazione della merce su commissione.';
										|pl = 'Nieprawidłowy rozdział ewidencji w przepływach rozchodu towarów komisowych.';
										|tr = 'Komisyon ürünlerinin gider yazma hareketlerinde yanlış muhasebe bölümü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(52, NStr("vi = 'Sai phân hệ kế toán đối ứng khi thực hiện công việc giữa các doanh nghiệp.';
										|ru = 'Неправильный кор. раздел учета при реализации работ между организациями.';
										|en = 'Incorrect corr. accounting section on implementation of works between companies.'; fa = 'Incorrect corr. accounting section on implementation of works between companies.';
										|it = 'Settore di contabilità di contropartita non corretto durante la realizzazione di lavori tra le aziende.';
										|pl = 'Niepoprawny rozdział kor. ewidencji przy realizacji prac między firmami.';
										|tr = 'İş yerleri arasında iş satışına ilişkin muhasebenin yanlış düzeltme bölümü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(53, NStr("vi = 'Sai giao dịch kinh tế trong bản ghi kết chuyển xuất xưởng phụ phẩm đối với chi phí.';
										|ru = 'Неправильная хозяйственная операция в движениях выпуска побочных изделий на расходы.';
										|en = 'Incorrect business transaction in records of the by-products release for expenses.'; fa = 'Incorrect business transaction in records of the by-products release for expenses.';
										|it = 'Operazione economica errata nei movimenti di rilascio dei sottoprodotti per spese.';
										|pl = 'Nieprawidłowa operacja gospodarcza w przepływach wydania produktów ubocznych na rozchody.';
										|tr = 'Yan nihai ürünlerin giderlere aktarılması hareketlerinde hatalı ticari işlem.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(54, NStr("vi = 'Sai giao dịch kinh tế trong bản ghi kết chuyển xuất xưởng phụ phẩm đối với chi phí.';
										|ru = 'Неправильная хозяйственная операция в движениях выпуска побочных изделий на расходы.';
										|en = 'Incorrect business transaction in records of the by-products release for expenses.'; fa = 'Incorrect business transaction in records of the by-products release for expenses.';
										|it = 'Operazione economica errata nei movimenti di rilascio dei sottoprodotti per spese.';
										|pl = 'Nieprawidłowa operacja gospodarcza w przepływach wydania produktów ubocznych na rozchody.';
										|tr = 'Yan nihai ürünlerin giderlere aktarılması hareketlerinde hatalı ticari işlem.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(55, NStr("vi = 'Sai phần hành kế toán đối với hàng hóa đi đường từ nhà cung cấp.';
										|ru = 'Неправильный раздел учета для товаров в пути от поставщиков.';
										|en = 'Incorrect accounting section for the goods in transit from vendors.'; fa = 'Incorrect accounting section for the goods in transit from vendors.';
										|it = 'Sezione di contabilità non corretta per le merci in transito dai fornitori.';
										|pl = 'Nieprawidłowy rozdział ewidencji dla towarów w drodze od dostawców.';
										|tr = 'Tedarikçilerden transit mallar için yanlış muhasebe bölümü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(57, NStr("vi = 'Sai giao dịch kinh tế để nhận hàng bán trong kỳ trước bị trả lại.';
										|ru = 'Неправильная хозяйственная операция для возврата от клиента товаров, проданных в прошлом периоде.';
										|en = 'Incorrect business transaction for the return of goods sold in the previous period from the customer.'; fa = 'Incorrect business transaction for the return of goods sold in the previous period from the customer.';
										|it = 'Operazione commerciale errata per il reso di articoli dal cliente, venduti nel periodo precedente.';
										|pl = 'Nieprawidłowa operacja gospodarcza dla zwrotu od nabywcy towarów, sprzedanych w poprzednim okresie.';
										|tr = 'Bir müşteriden önceki dönemde satılan ürünlerin iadesi için hatalı ticari işlem.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(58, NStr("vi = 'Đối tượng phân tích kế toán tài chính trong bản ghi kết chuyển nhập không tương ứng với lô hàng sản xuất.';
										|ru = 'Аналитика финансового учета в приходном движении не соответствует партии производства.';
										|en = 'Financial accounting dimension in the receipt document register record does not correspond to the production lot.'; fa = 'Financial accounting dimension in the receipt document register record does not correspond to the production lot.';
										|it = 'L''analisi dati di contabilità finanziaria nei movimenti di entrata non corrisponde ai lotti di produzione.';
										|pl = 'Analityka ewidencji finansowej w przepływie przychodzącym nie jest zgodna z partią produkcji.';
										|tr = 'Giriş hareketindeki finansal hesap boyutu üretim lotuyla eşleşmemektedir.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(59, NStr("vi = 'Đã điền sai dạng đối ứng hoạt động thuế GTGT trong bản ghi kết chuyển xuất ""Giao hàng (chỉ kế toán tài chính)"".';
										|ru = 'Не корректно заполнен кор. вид деятельности НДС в расходном движении ""Реализация (только регл. учет)"".';
										|en = 'The cor. VAT activity type in the ""Sales (only local accounting)"" expense record is filled in incorrectly.'; fa = 'The cor. VAT activity type in the ""Sales (only local accounting)"" expense record is filled in incorrectly.';
										|it = 'Tipo corr. di attività IVA non compilato correttamente nel movimento di uscita ""Vendita (solo contabilità reg.)"".';
										|pl = 'Niepoprawnie wypełniony rodzaj korygujący działalności VAT w przepływie wychodzącym ""Sprzedaż (tylko ewidencja regl.)"".';
										|tr = 'Düzeltme faaliyet türü KDV ""Satışlar (sadece yerel muhasebe)"" gider hareketinde doğru şekilde doldurulmadı.'"));
	DecodingErrorCodes.Insert(60, NStr("vi = 'Chưa điền tên định danh của dòng trong các bản ghi kết chuyển chứng từ ""Bảng kê hàng hóa của người nhận ký gửi"".';
										|ru = 'Не заполнен идентификатор строки в движениях документа ""Отчет комиссионера"".';
										|en = 'Line ID in the ""Consignment issue notification"" document records is not filled in.'; fa = 'Line ID in the ""Consignment issue notification"" document records is not filled in.';
										|it = 'Non è compilato l''ID della riga nei movimenti del documento ""Report del commissionario"".';
										|pl = 'Nie wypełniono identyfikatora wiersza w przepływach dokumentu ""Raport komisanta"".';
										|tr = '""Komisyon temsilcisinin raporu"" belgesinin hareketlerindeki satır tanımlayıcısı doldurulmadı.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(61, NStr("vi = 'Sai phần hành kế toán đối với nguyên vật liệu gia công, bán thành phẩm hoặc thành phẩm.';
										|ru = 'Неправильный раздел учета для давальческих материалов, полуфабрикатов или продукции.';
										|en = 'Incorrect accounting section for provider materials, semi-finished products, and manufactured products.'; fa = 'Incorrect accounting section for provider materials, semi-finished products, and manufactured products.';
										|it = 'Sezione errata di contabilità per i materiali del fornitore, semilavorati o prodotti.';
										|pl = 'Nieprawidłowa sekcja ewidencji dla materiałów właściciela surowców, półproduktów lub produkcji.';
										|tr = 'Tedarikçi malzemeler, yarı mamuller veya imal edilen ürünler için yanlış muhasebe bölümü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(62, NStr("vi = 'Sai dấu hiệu trong số lượng đối với giao dịch ""Nhận hàng bán của các kỳ trước bị trả lại""';
										|ru = 'Неправильный знак у количества для операции ""Возврат товаров от клиента прошлых периодов""';
										|en = 'Invalid quantity sign for the ""Sales return of previous periods"" operation'; fa = 'Invalid quantity sign for the ""Sales return of previous periods"" operation';
										|it = 'Segno non valido presso la quantità per l''operazione ""Reso articoli dal cliente dei periodi precedenti""';
										|pl = 'Nieprawidłowy znak ilości dla operacji ""Zwrot towarów od nabywcy poprzednich okresów""';
										|tr = '""Önceki dönemlere ait müşterilerden gelen ürünlerin iadesi"" işlemi için miktarın yanlış işareti'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(63, NStr("vi = 'Chưa điền đối tượng phân tích kế toán lô hàng trong bản ghi kết chuyển của chứng từ ""Điều chỉnh mua hàng"".';
										|ru = 'Не заполнена аналитика учета партий в движениях документа ""Корректировка приобретения"".';
										|en = 'Dimension (Lot accounting) of register records of the ""Purchase adjustment"" document is not filled.'; fa = 'Dimension (Lot accounting) of register records of the ""Purchase adjustment"" document is not filled.';
										|it = 'Le analitiche di contabilità dei lotti nei movimenti del documento ""Rettifica di acquisto"" non sono compilate.';
										|pl = 'Nie wypełniono analityki ewidencji partii w przepływach dokumentu ""Korekta zakupu"".';
										|tr = '""Satın alma düzeltmesi"" belgesinin hareketlerindeki lot muhasebe boyutu doldurulmadı.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(64, NStr("vi = 'Sai phân hệ kế toán đối với hàng hóa tại nơi nhận ký gửi.';
										|ru = 'Неправильный раздел учета для товаров у комиссионера.';
										|en = 'Incorrect accounting section for goods held by a consignee.'; fa = 'Incorrect accounting section for goods held by a consignee.';
										|it = 'Неправильный раздел учета для товаров у комиссионера.';
										|pl = 'Incorrect accounting section for goods held by a consignee.';
										|tr = 'Konsinyenin iş yerindeki ürünler için yanlış muhasebe bölümü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(66, NStr("vi = 'Chưa điền giao dịch ghi nhận giá vốn trong các bản ghi kết chuyển giá vốn hàng hóa.';
										|ru = 'Не заполнена операция учета себестоимости в движениях себестоимости товаров.';
										|en = 'Cost accounting transaction is not filled in inventory cost register records.'; fa = 'Cost accounting transaction is not filled in inventory cost register records.';
										|it = 'Не заполнена операция учета себестоимости в движениях себестоимости товаров.';
										|pl = 'Cost accounting transaction is not filled in inventory cost register records.';
										|tr = 'Ürün hareketlerinin maliyetindeki maliyet muhasebesi işlemi doldurulmadı.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(67, NStr("vi = 'Sai phần tính giá vốn trong giao hàng ký gửi đi đường.';
										|ru = 'Некорректный раздел учета себестоимости в реализации комиссионного товара в пути.';
										|en = 'Incorrect cost accounting section in sales of consignment goods in transit.'; fa = 'Incorrect cost accounting section in sales of consignment goods in transit.';
										|it = 'Некорректный раздел учета себестоимости в реализации комиссионного товара в пути.';
										|pl = 'Incorrect cost accounting section in sales of consignment goods in transit.';
										|tr = 'Komisyona tabi transit malların satışında yanlış maliyet muhasebesi bölümü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(68, NStr("vi = 'Dấu hiệu chưa đúng ở số lượng trong bản ghi kết chuyển xuất.';
										|ru = 'Не правильный знак у количества в расходном движении.';
										|en = 'Incorrect character in the quantity in the expense register record.'; fa = 'Incorrect character in the quantity in the expense register record.';
										|it = 'Не правильный знак у количества в расходном движении.';
										|pl = 'Incorrect character in the quantity in the expense register record.';
										|tr = 'Gider hareketindeki miktarda yanlış işaret mevcut.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(70, NStr("vi = 'Chưa điền dạng hoạt động thuế GTGT khi trả lại từ khách hàng theo giá trị đã chỉ ra';
										|ru = 'Не заполнен вид деятельности НДС при возврате от клиента по указанной стоимости';
										|en = 'The VAT activity type is not filled upon sales return at the specified cost'; fa = 'The VAT activity type is not filled upon sales return at the specified cost';
										|it = 'Не заполнен вид деятельности НДС при возврате от клиента по указанной стоимости';
										|pl = 'The VAT activity type is not filled upon sales return at the specified cost';
										|tr = 'Müşteriden belirtilen değerde iade yapıldığında faaliyet türü KDV doldurulmadı'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(71, NStr("vi = 'Đã điền sai dạng hoạt động thuế GTGT theo từng lần ""Giao hàng không có hóa đơn"".';
										|ru = 'Не корректно заполнен вид деятельности НДС в разделе ""Неотфактурованные поставки"".';
										|en = 'The VAT activity type in the ""Goods received not invoiced"" section is filled incorrectly.'; fa = 'The VAT activity type in the ""Goods received not invoiced"" section is filled incorrectly.';
										|it = 'Не корректно заполнен вид деятельности НДС в разделе ""Неотфактурованные поставки"".';
										|pl = 'The VAT activity type in the ""Goods received not invoiced"" section is filled incorrectly.';
										|tr = '""Faturasız tedarik"" bölümündeki faaliyet türü KDV doğru doldurulmadı.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(72, NStr("vi = 'Giao dịch kinh tế không chính xác để xuất xưởng theo giá trị thực tế trong biểu ghi ""Chi phí khác"".';
										|ru = 'Не правильная хозяйственная операция для выпуска по фикс. стоимости в регистре ""Прочие расходы"".';
										|en = 'Incorrect business transaction for product release at fixed cost in the ""Other expenses"" register.'; fa = 'Incorrect business transaction for product release at fixed cost in the ""Other expenses"" register.';
										|it = 'Не правильная хозяйственная операция для выпуска по фикс. стоимости в регистре ""Прочие расходы"".';
										|pl = 'Incorrect business transaction for product release at fixed cost in the ""Other expenses"" register.';
										|tr = '“Diğer giderler” kaydında sabit maliyetle serbest bırakma için yanlış ticari işlem.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(73, NStr("vi = 'Sai kiểu bản ghi đối với bản ghi kết chuyển giá trị gồm thuế GTGT trong biểu ghi ""Giá vốn hàng hóa"".';
										|ru = 'Не правильный тип записи для движения по включению НДС в стоимость в регистре ""Себестоимость товаров"".';
										|en = 'Incorrect record type for the record of including VAT in cost in the ""Inventory cost"" register.'; fa = 'Incorrect record type for the record of including VAT in cost in the ""Inventory cost"" register.';
										|it = 'Не правильный тип записи для движения по включению НДС в стоимость в регистре ""Себестоимость товаров"".';
										|pl = 'Incorrect record type for the record of including VAT in cost in the ""Inventory cost"" register.';
										|tr = '""Stok Maliyeti"" kaydına KDV''yi dahil etmek için yanlış giriş türü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(75, NStr("vi = 'Sai kiểu bản ghi để đảo ngược ';
										|ru = 'Не правильный тип записи для сторно движения фактуровки поставки в регистре ""Себестоимость товаров"".';
										|en = 'Incorrect record type for the storno record for the invoice entry in the ""Inventory cost"" register.'; fa = 'Incorrect record type for the storno record for the invoice entry in the ""Inventory cost"" register.';
										|it = 'Не правильный тип записи для сторно движения фактуровки поставки в регистре ""Себестоимость товаров"".';
										|pl = 'Incorrect record type for the storno record for the invoice entry in the ""Inventory cost"" register.';
										|tr = '""Stok Maliyeti"" kaydına tedarik faturasının iptali için yanlış giriş türü.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(76, NStr("vi = 'Chưa điền dạng hoạt động thuế GTGT trong các bản ghi kết chuyển với dạng bản ghi ""Bổ sung"" trong biểu ghi ""Giá vốn hàng hóa"".';
										|ru = 'Не заполнен вид деятельности НДС в движениях с типом записи ""Дополнение"" в регистре ""Себестоимость товаров"".';
										|en = 'The VAT activity type is not filled in register records with the ""Addition"" record type in the ""Inventory cost"" register.'; fa = 'The VAT activity type is not filled in register records with the ""Addition"" record type in the ""Inventory cost"" register.';
										|it = 'Не заполнен вид деятельности НДС в движениях с типом записи ""Дополнение"" в регистре ""Себестоимость товаров"".';
										|pl = 'The VAT activity type is not filled in register records with the ""Addition"" record type in the ""Inventory cost"" register.';
										|tr = '""Stok maliyeti"" kaydında kayıt türü ""Ek"" olan hareketlerde KDV faaliyet türü doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(77, NStr("vi = 'Đã điền dạng hoạt động thuế GTGT của chứng từ trong các bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa"" đối với chứng từ ""Chuyển hàng cho người trông coi"" và ""Tiếp nhận hàng hóa từ bên cất giữ"".';
										|ru = 'Заполнен вид деятельности НДС документа в движениях по регистру ""Себестоимость товаров"" у документов ""Передача товаров хранителю"" и ""Поступление товаров от хранителя"".';
										|en = 'The document VAT activity type is filled in the ""Inventory cost"" register records for the ""VMI fill-up"" and ""VMI return"" documents.'; fa = 'The document VAT activity type is filled in the ""Inventory cost"" register records for the ""VMI fill-up"" and ""VMI return"" documents.';
										|it = 'Заполнен вид деятельности НДС документа в движениях по регистру ""Себестоимость товаров"" у документов ""Передача товаров хранителю"" и ""Поступление товаров от хранителя"".';
										|pl = 'The document VAT activity type is filled in the ""Inventory cost"" register records for the ""VMI fill-up"" and ""VMI return"" documents.';
										|tr = '""VMI Transferi"" ve ""İrsaliyenin Saklayıcıdan Teslim Alınması"" belgeleri için ""Ürünlerin Maliyeti"" kaydında bulunan hareketlerdeki belgenin KDV faaliyet türü doldurulur.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(78, NStr("vi = 'Khi xuất xưởng thành phẩm theo giá trị ước tính không có bản ghi kết chuyển theo phần hành kế toán ""Xuất xưởng thành phẩm"".';
										|ru = 'При выпуске продукции по плановой стоимости нет движений по разделу учета ""Выпуск продукции"".';
										|en = 'When you release products at a standard cost, the ""Product release"" accounting section has no records.'; fa = 'When you release products at a standard cost, the ""Product release"" accounting section has no records.';
										|it = 'When you release products at a standard cost, the ""Product release"" accounting section has no records.';
										|pl = 'When you release products at a standard cost, the ""Product release"" accounting section has no records.';
										|tr = 'Ürünler planlanmış maliyetle piyasaya sürüldüğünde,muhasebenin ""Ürün çıkışı"" bölümünde herhangi bir hareket gerçekleşmez.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(79, NStr("vi = 'Khi xuất xưởng thành phẩm theo giá trị thực tế có bản ghi kết chuyển theo phần hành kế toán ""Xuất xưởng thành phẩm"".';
										|ru = 'При выпуске продукции по фактической стоимости есть движения по разделу учета ""Выпуск продукции"".';
										|en = 'When you release products at an actual cost, the ""Product release"" accounting section has records.'; fa = 'When you release products at an actual cost, the ""Product release"" accounting section has records.';
										|it = 'When you release products at an actual cost, the ""Product release"" accounting section has records.';
										|pl = 'When you release products at an actual cost, the ""Product release"" accounting section has records.';
										|tr = 'Ürünler gerçek maliyetle piyasaya sürüldüğünde muhasebenin ""Ürün çıkışı"" bölümünde hareketlilik olur.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(80, NStr("vi = 'Khi xuất xưởng thành phẩm theo giá trị thực tế có bản ghi kết chuyển theo phần hành kế toán ""Xuất xưởng thành phẩm"".';
										|ru = 'При выпуске продукции по фиксированной стоимости есть движения по разделу учета ""Выпуск продукции"".';
										|en = 'When you release products at a fixed cost, the ""Product release"" accounting section has records.'; fa = 'When you release products at a fixed cost, the ""Product release"" accounting section has records.';
										|it = 'When you release products at a fixed cost, the ""Product release"" accounting section has records.';
										|pl = 'When you release products at a fixed cost, the ""Product release"" accounting section has records.';
										|tr = 'Ürünler sabit maliyetle piyasaya sürüldüğünde muhasebenin ""Ürün çıkışı"" bölümünde hareketlilik olur.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(81, NStr("vi = 'Khi xuất xưởng thành phẩm vào kho xưởng, đã điền sai kho bãi trong phần hành kế toán ""Xuất xưởng thành phẩm"".';
										|ru = 'При выпуске продукции в цеховую кладовую не правильно заполнено место хранения в разделе учета ""Выпуск продукции"".';
										|en = 'Storage location is filled incorrectly in the ""Product release"" accounting section upon releasing products to the shop floor stockroom.'; fa = 'Storage location is filled incorrectly in the ""Product release"" accounting section upon releasing products to the shop floor stockroom.';
										|it = 'Storage location is filled incorrectly in the ""Product release"" accounting section upon releasing products to the shop floor stockroom.';
										|pl = 'Storage location is filled incorrectly in the ""Product release"" accounting section upon releasing products to the shop floor stockroom.';
										|tr = 'Ürünler mağaza atölye deposuna bırakıldığında saklama yeri, muhasebenin ""Ürün çıkışı"" bölümünde doğru doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(82, NStr("vi = 'Đã điền sai kho bãi trong biểu ghi ""Chênh lệch trong giá trị hàng hóa"".';
										|ru = 'Не корректно заполнено место хранения в регистре ""Отклонения в стоимости товаро"".';
										|en = 'Storage location is filled incorrectly in the ""Goods cost variances"" register.'; fa = 'Storage location is filled incorrectly in the ""Goods cost variances"" register.';
										|it = 'Storage location is filled incorrectly in the ""Goods cost variances"" register.';
										|pl = 'Storage location is filled incorrectly in the ""Goods cost variances"" register.';
										|tr = '""Ürünler maliyetindeki sapmalar"" kaydındaki saklama yeri yanlış doldurulmuş.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(83, NStr("vi = 'Đã điền sai kỳ chênh lệch để điều chỉnh mua hàng của kỳ trước trong biểu ghi ""Chênh lệch về giá trị hàng hóa"".';
										|ru = 'Не корректно заполнен период отклонений для корректировки приобретения прошлого периода в регистре ""Отклонения в стоимости товаров"".';
										|en = 'Variance period for the previous period purchase adjustment is filled incorrectly in the ""Goods cost variances"" register.'; fa = 'Variance period for the previous period purchase adjustment is filled incorrectly in the ""Goods cost variances"" register.';
										|it = 'Variance period for the previous period purchase adjustment is filled incorrectly in the ""Goods cost variances"" register.';
										|pl = 'Variance period for the previous period purchase adjustment is filled incorrectly in the ""Goods cost variances"" register.';
										|tr = '""Ürün maliyetindeki farklar"" kaydındaki önceki dönemin alımını düzeltebilmek için fark dönemi doğru doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(84, NStr("vi = 'Chưa điền lô hàng trong các bản ghi kết chuyển giá vốn hàng hóa theo phần hành kế toán ""Giao hàng chưa có hóa đơn"".';
										|ru = 'Не заполнена партия в движениях себестоимости товаров по разделу учета ""Неотфактурованные поставки"".';
										|en = 'A lot in the inventory cost records is not filled for the ""Goods received not invoiced"" accounting section.'; fa = 'A lot in the inventory cost records is not filled for the ""Goods received not invoiced"" accounting section.';
										|it = 'A lot in the inventory cost records is not filled for the ""Goods received not invoiced"" accounting section.';
										|pl = 'A lot in the inventory cost records is not filled for the ""Goods received not invoiced"" accounting section.';
										|tr = '""Faturalandırılmayan malzemeler"" muhasebe bölümüne göre ürün hareketlerinin maliyetine yönelik parti doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(85, NStr("vi = 'Chưa tính giá trị theo phương thức đánh giá ""Bình quân gia quyền liên hoàn"".';
										|ru = 'Не рассчиталась стоимость по методу оценки ""Среднескользящая"".';
										|en = 'Cannot calculate cost by the ""Moving average"" evaluation method.'; fa = 'Cannot calculate cost by the ""Moving average"" evaluation method.';
										|it = 'Cannot calculate cost by the ""Moving average"" evaluation method.';
										|pl = 'Cannot calculate cost by the ""Moving average"" evaluation method.';
										|tr = 'Maliyet, ""Orta kayan"" değerleme yöntemine göre yerleştirilmemiş.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(87, NStr("vi = 'Đã điền mã dòng khác nhau trong đối tượng phân tích ghi nhận lô hàng của chứng từ nhập với các đối tượng phân tích giống nhau trong các dòng chứng từ';
										|ru = 'Заполнены различные коды строк в аналитике учета партии приходного документа при одинаковых аналитиках в строках документа';
										|en = 'Different line codes are filled in the lot accounting dimension of the incoming document for the same dimensions in the document lines'; fa = 'Different line codes are filled in the lot accounting dimension of the incoming document for the same dimensions in the document lines';
										|it = 'Заполнены различные коды строк в аналитике учета партии приходного документа при одинаковых аналитиках в строках документа';
										|pl = 'Different line codes are filled in the lot accounting dimension of the incoming document for the same dimensions in the document lines';
										|tr = 'Gelen belgenin lot muhasebesinin boyutunda, belge satırlarında aynı boyutlarda farklı satır kodları dolduruldu'", Common.DefaultLanguageCode()));	
	DecodingErrorCodes.Insert(88, NStr("vi = 'Chưa điền mục tin tính toán lô hàng và tính toán giá vốn trong các bản ghi kết chuyển theo biểu ghi ""Biến động tài sản và nguồn vốn khác""';
										|ru = 'Не заполнены реквизиты расчета партий и расчета себестоимости в движениях по регистру ""Движения Прочие активы-пассивы""';
										|en = 'The lot calculation attributes and cost calculation attributes are not filled in the ""Flow of other assets and liabilities"" register records'; fa = 'The lot calculation attributes and cost calculation attributes are not filled in the ""Flow of other assets and liabilities"" register records';
										|it = 'Не заполнены реквизиты расчета партий и расчета себестоимости в движениях по регистру ""Движения Прочие активы-пассивы""';
										|pl = 'The lot calculation attributes and cost calculation attributes are not filled in the ""Flow of other assets and liabilities"" register records';
										|tr = 'Не заполнены реквизиты расчета партий и расчета себестоимости в движениях по регистру ""Движения Прочие активы-пассивы""'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(89, NStr("vi = 'Sai kiểu bản ghi trong bản ghi kết chuyển đảo ngược của điều chuyển hàng hóa';
										|ru = 'Не правильный тип записи в сторно движениях перемещения товаров';
										|en = 'Incorrect record type in storno records of the goods transfer'; fa = 'Incorrect record type in storno records of the goods transfer';
										|it = 'Incorrect record type in storno records of the goods transfer';
										|pl = 'Incorrect record type in storno records of the goods transfer';
										|tr = 'Mal transferinin tersine çevrilmesinde giriş türü yanlış'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(90, NStr("vi = 'Đối tượng phân tích kế toán tài chính trong bản ghi kết chuyển xuất không tương ứng với lô hàng sản xuất.';
										|ru = 'Аналитика финансового учета в расходом движении не соответствует партии производства.';
										|en = 'Financial accounting dimension in the expense document register record does not correspond to the production lot.'; fa = 'Financial accounting dimension in the expense document register record does not correspond to the production lot.';
										|it = 'Financial accounting dimension in the expense document register record does not correspond to the production lot.';
										|pl = 'Financial accounting dimension in the expense document register record does not correspond to the production lot.';
										|tr = 'Gidiş hareketindeki finansal muhasebe boyutu, üretim partisiyle eşleşmemektedir.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(91, NStr("vi = 'Chưa điền mục tin ""Chứng từ của bản ghi kết chuyển"" trong bản ghi kết chuyển của báo cáo của người đặt gia công giữa các doanh nghiệp.';
										|ru = 'Не заполнен реквизит ""Документ движения"" в движениях отчета давальцу между организациями.';
										|en = 'The ""Transfer record"" attribute is required for records of Intercompany consumption report — Subcontracting services delivered.'; fa = 'The ""Transfer record"" attribute is required for records of Intercompany consumption report — Subcontracting services delivered.';
										|it = 'The ""Transfer record"" attribute is required for records of Intercompany consumption report — Subcontracting services delivered.';
										|pl = 'The ""Transfer record"" attribute is required for records of Intercompany consumption report — Subcontracting services delivered.';
										|tr = 'İş yerleri arası tüketim raporu-verilen fason hizmetleri kayıtlarında gerekli ""Transfer kaydı"" alanı doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(92, NStr("vi = 'Chưa điền ID dòng trong bản ghi kết chuyển của chứng từ ""Tờ khai hải quan nhập khẩu"".';
										|ru = 'Не заполнен идентификатор строки в движениях документа ""Таможенная декларация на импорт"".';
										|en = 'The line ID in the ""Customs import declaration"" document register records is not filled in.'; fa = 'The line ID in the ""Customs import declaration"" document register records is not filled in.';
										|it = 'The line ID in the ""Customs import declaration"" document register records is not filled in.';
										|pl = 'The line ID in the ""Customs import declaration"" document register records is not filled in.';
										|tr = '""İthalat için gümrük beyannamesi"" belgesinin hareketlerinde satır tanımlayıcısı doldurulmadı.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(93, NStr("ru = 'Не заполнен реквизит ""Период отклонения"" в сторно движениях по регистру ""Себестоимость товаров"".';
										|vi = 'The ""Variance period"" attribute is not filled in storno records of the ""Cost of goods sold"" register.';
										|en = 'The ""Variance period"" attribute is not filled in storno records of the ""Cost of goods sold"" register.'; fa = 'The ""Variance period"" attribute is not filled in storno records of the ""Cost of goods sold"" register.';
										|it = 'The ""Variance period"" attribute is not filled in storno records of the ""Cost of goods sold"" register.';
										|pl = 'The ""Variance period"" attribute is not filled in storno records of the ""Cost of goods sold"" register.';
										|tr = '""Ürün maliyeti"" kaydındaki ters hareketlerde ""Fark dönemi"" alanı doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(94, NStr("ru = 'Не заполнен реквизит ""Период отклонения"" в сторно движениях по регистру ""Прочие расходы"".';
										|vi = 'The ""Variance period"" attribute is not filled in storno records of the ""Other expenses"" register.';
										|en = 'The ""Variance period"" attribute is not filled in storno records of the ""Other expenses"" register.'; fa = 'The ""Variance period"" attribute is not filled in storno records of the ""Other expenses"" register.';
										|it = 'The ""Variance period"" attribute is not filled in storno records of the ""Other expenses"" register.';
										|pl = 'The ""Variance period"" attribute is not filled in storno records of the ""Other expenses"" register.';
										|tr = '""Diğer giderler"" kaydındaki iptal hareketlerinde  ""Fark dönemi"" alanı doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(95, NStr("ru = 'Не заполнен реквизит ""Период отклонения"" в сторно движениях по регистру ""Партии прочих расходов"".';
										|vi = 'The ""Variance period"" attribute is not filled in storno records of the ""Material overheads for allocation"" register.';
										|en = 'The ""Variance period"" attribute is not filled in storno records of the ""Material overheads for allocation"" register.'; fa = 'The ""Variance period"" attribute is not filled in storno records of the ""Material overheads for allocation"" register.';
										|it = 'The ""Variance period"" attribute is not filled in storno records of the ""Material overheads for allocation"" register.';
										|pl = 'The ""Variance period"" attribute is not filled in storno records of the ""Material overheads for allocation"" register.';
										|tr = '""Diğer gider partileri"" kaydındaki iptal hareketlerinde ""Fark dönemi"" alanı doldurulmamış.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(96, NStr("vi = 'Đã điền sai dạng hoạt động đối ứng thuế GTGT trong bản ghi kết chuyển xuất ""Giao hàng (hàng đi đường)"".';
										|ru = 'Не корректно заполнен кор. вид деятельности НДС в расходном движении ""Реализация (товары в пути)"".';
										|en = 'The cor. VAT activity type in the ""Customer invoice — Goods-in-transit"" expense record is filled in incorrectly.'; fa = 'The cor. VAT activity type in the ""Customer invoice — Goods-in-transit"" expense record is filled in incorrectly.';
										|it = 'The cor. VAT activity type in the ""Customer invoice — Goods-in-transit"" expense record is filled in incorrectly.';
										|pl = 'The cor. VAT activity type in the ""Customer invoice — Goods-in-transit"" expense record is filled in incorrectly.';
										|tr = '""Satış (yoldaki ürünler)"" gider hareketinde KDV ilgili faaliyet türü hatalı doldurulmuş.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(97, NStr("vi = 'Đã điền sai dạng hoạt động thuế GTGT trong bản ghi kết chuyển của chứng từ ""Trả lại hàng cho người bán"".';
										|ru = 'Не корректно заполнен вид деятельности НДС в движениях документа ""Возврат товаров поставщику"".';
										|en = 'The VAT activity type in the ""Return of goods to vendor"" document register records is filled in incorrectly.'; fa = 'The VAT activity type in the ""Return of goods to vendor"" document register records is filled in incorrectly.';
										|it = 'The VAT activity type in the ""Return of goods to vendor"" document register records is filled in incorrectly.';
										|pl = 'The VAT activity type in the ""Return of goods to vendor"" document register records is filled in incorrectly.';
										|tr = '""Tedarikçiye ürün iadesi"" belgesinin hareketlerinde KDV faaliyet türü hatalı doldurulmuş.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(98, NStr("vi = 'Đã điền mã dòng khác nhau trong đối tượng phân tích ghi nhận lô hàng của chứng từ nhập với các đối tượng phân tích giống nhau trong các dòng chứng từ';
										|ru = 'Заполнены различные коды строк в аналитике учета партии приходного документа при одинаковых аналитиках в строках документа';
										|en = 'Different line codes are filled in the lot accounting dimension of the incoming document for the same dimensions in the document lines'; fa = 'Different line codes are filled in the lot accounting dimension of the incoming document for the same dimensions in the document lines';
										|it = 'Заполнены различные коды строк в аналитике учета партии приходного документа при одинаковых аналитиках в строках документа';
										|pl = 'Different line codes are filled in the lot accounting dimension of the incoming document for the same dimensions in the document lines';
										|tr = 'Gelen belgenin lot muhasebesinin boyutunda, belge satırlarında aynı boyutlarda farklı satır kodları dolduruldu'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(99, NStr("ru = 'Не заполнен реквизит ""Заказ клиента"" в движениях реализации товаров и услуг.';
										|vi = 'The ""Sales order"" attribute is not filled in the customer invoice register records.';
										|en = 'The ""Sales order"" attribute is not filled in the customer invoice register records.'; fa = 'The ""Sales order"" attribute is not filled in the customer invoice register records.';
										|it = 'The ""Sales order"" attribute is not filled in the customer invoice register records.';
										|pl = 'The ""Sales order"" attribute is not filled in the customer invoice register records.';
										|tr = 'Ürün ve hizmet satış hareketlerinde ""satıi siparişi"" alanı doldurulmadı.'", Common.DefaultLanguageCode()));
	
	AdditionalFields = New Structure("BusinessOperation", NStr("vi = 'giao dịch';
																|ru = 'операция';
																|en = 'transaction'; fa = 'transaction';
																|it = 'operazione';
																|pl = 'operacja';
																|tr = 'işlem'", Common.DefaultLanguageCode()));
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'sửa lỗi trong các bản ghi kết chuyển của chứng từ';
			|ru = 'исправление ошибок в движениях документов';
			|en = 'error correction in document records'; fa = 'error correction in document records';
			|it = 'correzione errore nei movimenti dei documenti';
			|pl = 'korygowanie błędów w przepływach dokumentów';
			|tr = 'belge kayıtlarında hataların düzeltilmesi'", Common.DefaultLanguageCode()),
		AdditionalFields);
	
	#EndRegion
	

	#Region EnablingCostAccounting
	
	DecodingErrorCodes = New Map;	
	DecodingErrorCodes.Insert(1, NStr("vi = 'bật quản lý giá vốn';
										|ru = 'Включение учета себестоимости';
										|en = 'enable cost accounting'; fa = 'enable cost accounting';
										|it = 'Включение учета себестоимости';
										|pl = 'Włączenie ewidencji kosztów własnych';
										|tr = 'maliyet muhasebesinin etkinleştirilmesi'", Common.DefaultLanguageCode()));
	
	Query.SetParameter("ImportDocumentType", Common.MetadataObjectID("Document.CCDImport"));
	
	Query.Text = QueryTextEnablingCostAccounting();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bật quản lý giá vốn';
			|ru = 'включение учета себестоимости';
			|en = 'enable cost accounting'; fa = 'enable cost accounting';
			|it = 'включение учета себестоимости';
			|pl = 'włączenie ewidencji kosztów własnych';
			|tr = 'maliyet muhasebesinin etkinleştirilmesi'", Common.DefaultLanguageCode()));
	
	#EndRegion

	#Region RevenueAndCOGS
	
	// Correction of incorrect movements in the register "Revenue and cost of sales".
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Trùng lặp giá vốn dự tính trong các bản ghi kết chuyển gốc';
										|ru = 'Дублирование расчетной себестоимости в первичных движениях';
										|en = 'Duplication of estimated cost in primary records'; fa = 'Duplication of estimated cost in primary records';
										|it = 'Duplicazione del costo di produzione stimato nei movimenti primari';
										|pl = 'Dublowanie szacowanych kosztów własnych w ruchach pierwotnych';
										|tr = 'Birincil hareketlerde tahmini satış maliyetinin tekrarlanması'", Common.DefaultLanguageCode()));
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query);
	
	Query.Text = RequestTextDocumentsWithDuplicatesOfRevenueAndCostOfSalesRegisteredRecords();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'lỗi 00-00071689';
			|ru = 'ошибка 00-00071689';
			|en = 'error 00-00071689'; fa = 'error 00-00071689';
			|it = 'errore 00-00071689';
			|pl = 'błąd 00-00071689';
			|tr = 'hata 00-00071689'", Common.DefaultLanguageCode()));
	
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query, ExistingTT);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Thiếu các bản ghi kết chuyển gốc khi điều chỉnh doanh thu';
										|ru = 'Пропавшие первичные движения по корректировке выручки';
										|en = 'Missing primary records on revenue adjustment'; fa = 'Missing primary records on revenue adjustment';
										|it = 'Movimenti primari di rettifica del ricavo scomparsi';
										|pl = 'Stracone ruchy początkowe po korekcie utargu';
										|tr = 'Gelir düzeltmelerinde eksik birincil hareketler'"));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Bản ghi kết chuyển theo biểu ghi ""Doanh thu và giá vốn hàng bán"" không tương ứng với bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa""';
										|ru = 'Движения по регистру ""Выручка и себестоимость продаж"" не соответствуют движениям по регистру ""Себестоимость товаров""';
										|en = 'The ""Revenue and COGS"" register records do not correspond to the ""Inventory cost"" register records'; fa = 'The ""Revenue and COGS"" register records do not correspond to the ""Inventory cost"" register records';
										|it = 'Движения по регистру ""Выручка и себестоимость продаж"" не соответствуют движениям по регистру ""Себестоимость товаров""';
										|pl = 'The ""Revenue and COGS"" register records do not correspond to the ""Inventory cost"" register records';
										|tr = '""Hasılat ve satışların Maliyeti"" kayıtlarındaki hareketlerin ""Stok maliyeti"" kayıtlarındaki hareketlere uygun gelmemesi'"));
	DecodingErrorCodes.Insert(3, NStr("vi = 'Để làm việc, không điền phân hệ kế toán trong bản ghi kết chuyển theo biểu ghi ""Doanh thu và giá vốn hàng bán""';
										|ru = 'Для работы не заполнен раздел учета в движениях по регистру ""Выручка и себестоимости продаж""';
										|en = 'To operate, an accounting section in the the ""Revenue and COGS"" register records is not filled'; fa = 'To operate, an accounting section in the the ""Revenue and COGS"" register records is not filled';
										|it = 'Non è stata compilata per il lavoro la sezione contabile nei movimenti del registro ""Fatturazione e costo delle vendite""';
										|pl = 'Do pracy nie jest wypełniona sekcja ewidencji w przepływach według rejestru ""Для работы не заполнен раздел учета в движениях по регистру ""Przychód ш koszt własny sprzedaży""';
										|tr = 'Kayıttaki hareketlerde ""Hasılat ve satışların maliyeti"" muhasebe bölümü iş için doldurulmadı'"));
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query);
	
	Query.Text = RequestTextDocumentsWithMissingRegisteredRecordsInRevenueAndCostOfSales();
	
	AdditionalFields = New Structure("BusinessOperation", NStr("vi = 'giao dịch';
																|ru = 'операция';
																|en = 'transaction'; fa = 'transaction';
																|it = 'operazione';
																|pl = 'operacja';
																|tr = 'işlem'", Common.DefaultLanguageCode()));
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển theo biểu ghi ""Doanh thu và giá vốn hàng bán""';
			|ru = 'исправление движений по регистру ""Выручка и себестоимость продаж""';
			|en = 'correction of records in the ""Revenue and COGS"" register'; fa = 'correction of records in the ""Revenue and COGS"" register';
			|it = 'rettifica di movimenti nel registro ""Ricavi e dei costi di vendita""';
			|pl = 'korekta ruchów wg rejestru ""Utarg i koszt własny sprzedaży""';
			|tr = '""Hasılat ve satışların maliyeti"" kayıtlarındaki hareketlerin düzeltilmesi'"),
		AdditionalFields);
	
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query, ExistingTT);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
	#EndRegion

	#Region IncorrectFinancialAccountingAnalytics
	
	// Correction of incorrect empty financial accounting analytics in the "Cost of goods" register.
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Đối tượng phân tích trống của kế toán tài chính trong các bản ghi kết chuyển ban đầu có giá trị khác với KHÔNG XÁC ĐỊNH';
										|ru = 'Пустая аналитика финансового учет в первичных движениях имеет значение отличное от НЕОПРЕДЕЛЕНО';
										|en = 'Empty dimension of financial accounting in primary records has a value different from UNDEFINED'; fa = 'Empty dimension of financial accounting in primary records has a value different from UNDEFINED';
										|it = 'L''analitica vuota della contabilità finanziaria nei movimenti primari ha valore diverso da INDEFINITO';
										|pl = 'Pusta analityka ewidencji finansowej w ruchach pierwotnych ma wartość różniącą się od NIEOKREŚLONO';
										|tr = 'Birincil hareketlerdeki boş finansal muhasebe boyutu BELİRLENMEDİ dışında bir değere sahiptir'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Đối tượng phân tích trung gian trống của kế toán tài chính trong các bản ghi kết chuyển gốc có giá trị khác với KHÔNG XÁC ĐỊNH';
										|ru = 'Пустая кор аналитика финансового учет в первичных движениях имеет значение отличное от НЕОПРЕДЕЛЕНО';
										|en = 'Empty adjustment dimension of financial accounting in primary records has a value different from UNDEFINED'; fa = 'Empty adjustment dimension of financial accounting in primary records has a value different from UNDEFINED';
										|it = 'L''analitica core vuota di contabilità finanziaria nei movimenti primari ha un valore diverso da NON DEFINITO';
										|pl = 'Pusta analityka kor ewidencji finansowej w ruchach pierwotnych ma wartość różniącą się od NIEOKREŚLONO';
										|tr = 'Birincil hareketlerde finansal muhasebenin boş düzeltme boyutu BELİRLENMEDİ dışında bir değere sahiptir'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(3, NStr("vi = 'Đối tượng phân tích kế toán tài chính trống trong các bản ghi kết chuyển gốc khác với đối tượng phân tích kế toán tài chính đối ứng';
										|ru = 'Пустая аналитика финансового учет в первичных движениях отличается от кор аналитики финансового учета';
										|en = 'Empty dimension of financial accounting in primary records is different from cor. dimension of financial accounting'; fa = 'Empty dimension of financial accounting in primary records is different from cor. dimension of financial accounting';
										|it = 'L''analisi vuota della contabilità finanziaria nei movimenti primari differisce dalla corr di analisi di contabilità finanziaria';
										|pl = 'Pusta analityka ewidencji finansowej w pierwotnych przepływach różni się od analityki korespondencyjnej ewidencji finansowej';
										|tr = 'Birincil hareketlerdeki boş finansal muhasebe boyutu, düzeltme finansal muhasebe boyutundan farklıdır'", Common.DefaultLanguageCode()));
	
	Query.Text =
	"SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	1 						 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.FinancialAccountingDimension IN
	|		(VALUE(Catalog.BusinessStructure.EmptyRef),
	|		 VALUE(Catalog.Users.EmptyRef),
	|		 VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef),
	|		 VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef))
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	2 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.CorControllingAttributes IN
	|		(VALUE(Catalog.BusinessStructure.EmptyRef),
	|		 VALUE(Catalog.Users.EmptyRef),
	|		 VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef),
	|		 VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef))
	|	AND VALUETYPE(T.Recorder) IN (
	|		TYPE(Document.CustomerInvoice),
	|		TYPE(Document.InventoryTransfer))
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	3 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	LEFT JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|		ON RegisterRecords.Period = T.Period
	|		AND RegisterRecords.Recorder = T.Recorder
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND NOT RegisterRecords.LotCalculation
	|		AND NOT RegisterRecords.CalculationOfCost
	|		AND RegisterRecords.CorItemsLocationAttributes = T.ItemsLocationAttributes
	|		AND RegisterRecords.CorInventoryOwnerAttribute = T.InventoryOwnerAttribute
	|		AND RegisterRecords.CorControllingAttributes = T.FinancialAccountingDimension
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND T.CorControllingAttributes  <> UNDEFINED
	|	AND VALUETYPE(T.Recorder) = TYPE(Document.CustomerInvoiceIntercompany)
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|	AND RegisterRecords.Recorder IS NULL
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|";

	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa đối tượng phân tích kế toán tài chính trong các bản ghi kết chuyển';
			|ru = 'исправление аналитики финансового учета в движениях';
			|en = 'correction of financial accounting dimension in records'; fa = 'correction of financial accounting dimension in records';
			|it = 'correzione dell''analisi di contabilità finanziaria nei movimenti';
			|pl = 'korygowanie analityki ewidencji finansowej w przepływach';
			|tr = 'hareketlerde finansal muhasebe boyutunun düzeltilmesi'", Common.DefaultLanguageCode()));
	
	#EndRegion

	#Region AmountsInRegisteredRecords
	
	// Verification of compliance with the fullness of the amount of upr./regl. values of functional options.
	DecodingErrorCodes = New Map;
	
	Template1 = NStr("vi = 'Điền số tiền quản trị trong bản ghi kết chuyển không tương ứng với giá trị tùy chọn chức năng ""%Couples1%""';
					|ru = 'Заполнение упр. сумм в движениях не соответствует значению функциональной опции ""%Couples1%""';
					|en = 'Filling of the amounts, ENT in register records does not correspond to the value of the functional option ""%Couples1%""'; fa = 'Filling of the amounts, ENT in register records does not correspond to the value of the functional option ""%Couples1%""';
					|it = 'La compilazione degli importi di gestione nei movimenti non corrisponde al valore dell''opzione funzionale %Couples1%';
					|pl = 'Wypełnienie wartości zarz. w ruchach nie odpowiada wartości opcji funkcjonalnej ""%Couples1%""';
					|tr = 'Hareketlerdeki yönetim muhasebesi miktarlarının doldurulması ""%Couples1%"" fonksiyon seçeneğinin değerine karşılık gelmiyor'", Common.DefaultLanguageCode());
	Template1 = StrReplace(Template1, "%Couples1%", "KeepManagementRecordsOfOrganizations");
	DecodingErrorCodes.Insert(1,Template1 );
	
	Template1 = NStr("vi = 'Điền số tiền quy định trong bản ghi kết chuyển không tương ứng với giá trị tùy chọn chức năng ""%Couples1%""';
					|ru = 'Заполнение регл. сумм в движениях не соответствует значению функциональной опции ""%Couples1%""';
					|en = 'Filling of the local amounts in register records does not correspond to the value of the functional option ""%Couples1%""'; fa = 'Filling of the local amounts in register records does not correspond to the value of the functional option ""%Couples1%""';
					|it = 'La compilazione degli importi regolatori nei movimenti non corrisponde al valore dell''opzione funzionale %Couples1%';
					|pl = 'Wypełnienie wartości regl. w ruchach nie odpowiada wartości opcji funkcjonalnej ""%Couples1%""';
					|tr = 'Hareketlerdeki yerel muhasebe miktarlarının doldurulması ""%Couples1%"" fonksiyon seçeneğinin değerine karşılık gelmiyor'", Common.DefaultLanguageCode());
	Template1 = StrReplace(Template1, "%Couples1%", "UseAccountingOfOtherIncomeExpensesInLocalAccounting");
	DecodingErrorCodes.Insert(2,Template1 );

	DecodingErrorCodes.Insert(3, NStr("vi = 'Điền số tiền không gồm thuế GTGT trong bản ghi kết chuyển không tương ứng với phương án phân bổ dạng chi phí';
										|ru = 'Заполнение суммы без НДС в движениях не соответствует варианту распределения статьи расходов';
										|en = 'Filling of amounts excluding VAT in the records does not match the expense item distribution option'; fa = 'Filling of amounts excluding VAT in the records does not match the expense item distribution option';
										|it = 'Compilazione dell''importo senza IVA nei movimenti non corrisponde all''opzione di ripartizione delle voci di spesa';
										|pl = 'Wypełnienie kwoty bez VAT w ruchach nie odpowiada wariantowi podziału rodzaju kosztów';
										|tr = 'Hareketlerde KDV hariç tutarın doldurulması, gider kaleminin tahsisat seçeneğine karşılık gelmez'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(4, NStr("vi = 'Bản ghi kết chuyển theo biểu ghi ""Thu nhập khác"" được lập mà không có dấu hiệu ""Tính giá vốn"".';
										|ru = 'Движения по регистру ""Прочие доходы"" сформированы без признака ""Расчет себестоимости"".';
										|en = 'Records of the ""Income"" register are created without the ""Cost calculation"" flag.'; fa = 'Records of the ""Income"" register are created without the ""Cost calculation"" flag.';
										|it = 'Movimenti per il registro ""Altre entrate"" creati senza segno ""Calcolo prezzo di costo"".';
										|pl = 'Przepływy według rejestru ""Inne dochody"" są zarejestrowane bez oznaki ""Obliczenie kosztów własnych"".';
										|tr = '""Diğer gelirler"" kaydı üzerindeki hareketler ""Maliyet hesaplaması"" bayrağı olmadan oluşturuldu.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(5, NStr("vi = 'Trong các bản ghi kết chuyển theo biểu ghi ""Chi phí khác"", số tiền chênh lệch vĩnh viễn bị điền vượt mức.';
										|ru = 'В движениях по регистру ""Прочие расходы"" излишне заполнена сумма постоянной разницы.';
										|en = 'In records of the ""Other expenses"" register, the permanent difference amount is unnecessarily filled.'; fa = 'In records of the ""Other expenses"" register, the permanent difference amount is unnecessarily filled.';
										|it = 'In records of the ""Other expenses"" register, the permanent difference amount is unnecessarily filled.';
										|pl = 'In records of the ""Other expenses"" register, the permanent difference amount is unnecessarily filled.';
										|tr = '""Diğer giderler"" kaydındaki hareketlerde kalıcı fark tutarı fazla doldurulmuş.'", Common.DefaultLanguageCode()));
	
	#Region ExcludedDocumentTypes
	
	Query.SetParameter("TypesOfDocumentsAboutSiIa", CostCalculationAppliedAlgorithms.TypesOfDocumentsAboutSiIa());
	Query.SetParameter("TypesOfRegulatoryDocuments", CostCalculationAppliedAlgorithms.TypesOfDocumentsAreRoutine());
	
	#EndRegion
	
	Query.Text =
	"SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	1 						 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND (T.EntryType IN (&UnreadableRecordTypes)
	|		OR T.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
	|		  AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|	AND (T.Cost <> 0 OR T.CorGrossInitialCostENT <> 0 OR T.AddExpensesForGoods <> 0 OR T.LaborCosts <> 0
	|		OR T.ItemizedFixedCostsIncludingVAT <> 0 OR T.ItemizedVariableCostsIncludingVAT <> 0
	|		OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|	AND NOT T.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale))
	|	AND NOT T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.GoodsValueVarianceIncome),
	|		VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses))
	|	AND ((&CompanyManagementAccounting AND (T.CostExcludingVAT <> 0 OR T.CorGrossInitialCostENT <> 0
	|			OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|			 AND T.LocalCost <> 0
	|			 AND T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage))
	|		AND T.CostMan = 0 AND T.AddExpensesMan = 0 AND T.LaborCostsMan = 0
	|		AND T.ItemizedFixedCostsManag = 0 AND T.ItemizedVariableCostsManag = 0)
	|	OR (NOT &CompanyManagementAccounting
	|		AND (T.CostMan <> 0 OR T.AddExpensesMan <> 0 OR T.LaborCostsMan <> 0
	|		OR T.ItemizedFixedCostsManag <> 0 OR T.ItemizedVariableCostsManag <> 0)))
	|	AND NOT (T.CostExcludingVAT = 0	AND T.AddExpensesForGoods <> 0 AND T.AddExpensesMan = 0)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""OtherIncome"" 		 AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	CASE
	|		WHEN T.Sum <> 0
	|			AND T.SumCompl = 0
	|			AND &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|			THEN 2
	|		WHEN T.SumCompl <> 0
	|			AND NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|			THEN 2
	|		ELSE 1
	|	END					 AS ErrorCode
	|FROM
	|	AccumulationRegister.OtherIncome AS T
	|	LEFT JOIN TTExchangeRatesOfOrganizations AS ExRates
	|		ON T.Organization = ExRates.Organization
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND ((&CompanyManagementAccounting
	|			AND T.SumMan = 0
	|			AND T.Sum <> 0)
	|		OR (NOT &CompanyManagementAccounting
	|			AND T.SumMan <> 0)
	|		OR (T.Sum <> 0
	|			AND T.SumCompl = 0
	|			AND NOT (CAST(T.Sum * ExRates.ManSCurrencyRatio AS NUMBER(31,2)) BETWEEN -&ErrorValueCostLocal AND &ErrorValueCostLocal)
	|			AND &UseAccountingOfOtherIncomeExpensesInLocalAccounting)
	|		OR (T.SumCompl <> 0
	|			AND NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting)
	|	  )
	// We exclude the selection of Registered Recorded cost deviations generated during the execution of the document.
	// The verification of the amounts in such RegisteredRecords is not required.
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsValueVarianceIncome)
	|
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""OtherIncome"" 		 AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	4						 AS ErrorCode
	|FROM
	|	AccumulationRegister.OtherIncome AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.CalculationOfCost
	|	AND VALUETYPE(T.Recorder) = TYPE(Document.ReturnOfGoodsFromCustomer)
	// We exclude the selection of Registered Recorded cost deviations generated during the execution of the document.
	// The verification of the amounts in such RegisteredRecords is not required.
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsValueVarianceIncome)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""OtherExpenses"" 		 AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	1 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND ((&CompanyManagementAccounting AND T.SumMan = 0 AND T.Sum <> 0 AND T.SumCompl <> 0
	|			AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa))
	|		OR (NOT &CompanyManagementAccounting AND T.SumMan <> 0
	|			AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)))
	// We exclude the selection of Registered Recorded cost deviations generated during the execution of the document.
	// The verification of the amounts in such RegisteredRecords is not required.
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses)
	// The Registered Records with these household of operations are generated of operations "Closing expenses from the disposal of FAS",
	// so verification of such Registered Records is not required.
	|	AND NOT T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CloseFixedAssetSalesExpenses),
	|		VALUE(Enum.BusinessTransactions.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer),
	|		VALUE(Enum.BusinessTransactions.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer),
	|		VALUE(Enum.BusinessTransactions.CloseFixedAssetWriteOffExpenses))
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""OtherExpenses"" 		 AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	2 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	| 	AND T.MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.EmptyRef)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.ReverseVATAccrual)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.CalculationOfDiscountInterestExpenses)
	
	// By adjusting the debt, the entire amount of the debt can be written off at the expense of reserves. in this case, the sum of the Local movements will be equal to 0.
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	// in the sale of services and other assets, the amount of Local. it may not be filled in.
	|	AND NOT T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		VALUE(Enum.BusinessTransactions.CostOfIntangibleAssetsSold))
	// If the amount without VAT is equal to 0, it means that the document contains only the amount of VAT. In this case, the Local amount will not be filled in.
	|	AND ((&UseAccountingOfOtherIncomeExpensesInLocalAccounting AND T.SumCompl = 0 AND T.Sum <> 0 AND T.AmountExcludingVAT <> 0
	|			AND NOT T.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ExpenseReversalInManAccounting),
	|				VALUE(Enum.BusinessTransactions.ExpenseRegistrationInManAccounting))
	|			AND NOT T.ExpenseItem.CostAllocationOptionLocal IN (
	|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
	|				VALUE(Enum.CostAllocationOptions.OnOtherAssets)))
	|		OR (NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting AND T.SumCompl <> 0))
	// Register Records document "Other goods recording" with a host of "operation Capitalization (at retirement FA)" are formed
	// during the execution of operation "Closing costs on disposal FA", so checking such Register Records is not required.
	|	AND NOT T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal),
	|		VALUE(Enum.BusinessTransactions.AdjustmentOfExpensesFromDisposalOfFixedAssets),
	|		VALUE(Enum.BusinessTransactions.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets))
	// The Registered Records with these household of operations are generated of operations "Closing expenses from the disposal of FAS",
	// so verification of such Registered Records is not required.
	|	AND NOT T.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CloseFixedAssetSalesExpenses),
	|		VALUE(Enum.BusinessTransactions.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer),
	|		VALUE(Enum.BusinessTransactions.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer),
	|		VALUE(Enum.BusinessTransactions.CloseFixedAssetWriteOffExpenses))
	// We exclude the selection of Registered Recorded cost deviations generated during the execution of the document.
	// The verification of the amounts in such RegisteredRecords is not required.
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""ItemisedExpensesLots"" AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	1 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|	LEFT JOIN TTExchangeRatesOfOrganizations AS ExRates
	|		ON T.Organization = ExRates.Organization
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND ((&CompanyManagementAccounting AND T.Cost <> 0 AND T.VATLocal <> 0 AND T.VATManag = 0
	|			AND CAST(T.VATLocal * ExRates.LocalCurrencyRatio AS NUMBER(31,2)) <> 0
	|			AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa))
	|		OR (NOT &CompanyManagementAccounting AND T.VATManag <> 0)
	|		OR (T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseRegistrationInManAccounting)
	|			AND T.VATManag <> 0))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""ItemisedExpensesLots"" AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	2 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|	LEFT JOIN TTExchangeRatesOfOrganizations AS ExRates
	|		ON T.Organization = ExRates.Organization
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND ((&UseAccountingOfOtherIncomeExpensesInLocalAccounting AND T.Cost <> 0 AND T.LocalCost = 0 AND T.VATLocal = 0 AND T.PermanentDifference = 0 AND T.CostTD = 0
	|			AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|			AND NOT T.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ExpenseReversalInManAccounting),
	|				VALUE(Enum.BusinessTransactions.ExpenseRegistrationInManAccounting))
	|			AND (T.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		  ))
	|		OR (NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting AND (T.LocalCost <> 0 OR T.VATLocal <> 0 OR T.PermanentDifference <> 0 OR T.CostTD <> 0)))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""RevenueAndCOGS"" AS RegisterName,
	|	T.Recorder 			        AS Ref,
	|	Dimension.Organization 			AS Organization,
	|	1 						        AS ErrorCode
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS T
	|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
	|		ON Dimension.Ref = T.AccountingDimensionByPartners
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Dimension.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND ((&CompanyManagementAccounting AND T.Cost <> 0 AND T.CostMan = 0)
	|		OR (NOT &CompanyManagementAccounting AND T.CostMan <> 0))
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT Dimension.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	// Checking the filling of the amount without VAT in movements.
	|SELECT DISTINCT
	|	""OtherExpenses"" 		 AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	3 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.ReverseVATAccrual)
	|
	// The amount without VAT may not be filled in if the document specifies the amount of VAT equal to the amount of the document.
	// In this case, the amount without VAT and the amount of regl will be equal to 0. 
	|	AND T.Sum <> 0 AND T.AmountExcludingVAT = 0 AND T.SumCompl <> 0
	|	AND NOT T.ExpenseItem.CostAllocationOptionManag IN (
	|		VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
	|		VALUE(Enum.CostAllocationOptions.OnOtherAssets))
	|	AND NOT T.ReversingEntry
	// We exclude the selection of Registered Recorded cost deviations generated during the execution of the document.
	// The verification of the amounts in such RegisteredRecords is not required.
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	// In the "Trade Management" configuration in the "Other expenses" register, the amount of the permanent difference is not filled in,
	// because the cost allocation mechanisms of this configuration do not know how to work with a steady difference.
	|SELECT DISTINCT
	|	""OtherExpenses"" 		 AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	5 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND FALSE // verification is performed only in the ""Trade Management"" configuration
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|	AND T.PermanentDifference <> 0
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.ReverseVATAccrual)
	|
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'điền sai số tiền của kế toán quản trị';
			|ru = 'некорректное заполнение сумм упр. учета';
			|en = 'amounts, mgmt are filled in incorrectly'; fa = 'amounts, mgmt are filled in incorrectly';
			|it = 'compilazione incorretta dell''importo della contabilità gestionale';
			|pl = 'niepoprawne wypełnienie kwot ewidencji zarz.';
			|tr = 'yönetim muhasebe tutarlarının yanlış doldurulması'", Common.DefaultLanguageCode()));
	
	#EndRegion

	
	#Region BookValueOfProductsWithRegistrationOfGiverSReport
	
	// Correction of movements by register Output
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Sản phẩm của bên đặt gia công mà cần lập bảng kê, không nên có giá trị dự tính.';
										|ru = 'Продукция давальца, по которой необходимо отчитаться, не должна иметь плановую стоимость.';
										|en = 'Manufactured products of material provider for which it is necessary to report should not have a standard cost.'; fa = 'Manufactured products of material provider for which it is necessary to report should not have a standard cost.';
										|it = 'Prodotti in conto terzi per i quali è necessario presentare il rapporto, non devono avere un costo pianificato.';
										|pl = 'Wiersze pozycji właściciela surowców, wg którego należy złożyć raport, nie powinni mieć wartości planowanej.';
										|tr = 'Tedarikçinin imal edilen ürünleri standart maliyete sahip olmamalıdır.'", Common.DefaultLanguageCode()));
	
	Query.Text =
	"SELECT DISTINCT
	|	T.Recorder,
	|	T.Organization,
	|   (T.Cost = 0
	|		AND T.CostExcludingVAT = 0
	|		AND T.LocalCost = 0
	|		AND T.CostMan = 0) AS EmptyAmounts
	|INTO AdvanceRegistrars
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|		INNER JOIN Document.MovementOfProductsAndMaterials AS TrafficGoods
	|		ON T.Recorder = TrafficGoods.Ref
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|	AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|								VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom))
	|	AND NOT T.CalculationOfCost
	|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|SELECT DISTINCT
	|	""InventoryCost""	AS RegisterName,
	|	Recorders.Recorder	AS Ref,
	|	Recorders.Organization	AS Organization,
	|	1 						 	AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AdvanceRegistrars AS Recorders
	|		INNER JOIN Document.MovementOfProductsAndMaterials.Goods AS GoodsTable
	|		ON Recorders.Recorder = GoodsTable.Ref
	|				
	|		INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS StageProducts
	|		ON GoodsTable.ReferenceOrder = StageProducts.Ref
	|			AND GoodsTable.RowCode = StageProducts.RowCode
	|WHERE
	|	Recorders.EmptyAmounts
	|		AND NOT GoodsTable.Sum = 0
	|;
	|DROP AdvanceRegistrars";
			
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'sai bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa""';
			|ru = 'некорректные движения по регистру ""Себестоимость товаров""';
			|en = 'incorrect records in the ""Inventory cost"" register'; fa = 'incorrect records in the ""Inventory cost"" register';
			|it = 'movimenti incorretti per il registro ""Costo di produzione dei prodotti""';
			|pl = 'niepoprawne ruchy w rejestrze ""Себестоимость товаров""';
			|tr = '""Stok maliyeti"" kaydındaki hatalı hareketler'", Common.DefaultLanguageCode()));
	
	#EndRegion
	#Region LaborCostsOfUnfinishedProduction
	
	// We will prepare a request for the formation of a registration with incorrect movements.
	// We exclude the documents "Reflection of the payment in the financial accounting", since they must be carried out at the very end.
	Query.Text = "
	|SELECT DISTINCT
	|	""WIPLaborCosts""	AS RegisterName,
	|	T.Recorder								AS Ref,
	|	T.Organization								AS Organization,
	|	1											AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND ISNULL(T.ProductionLot.UsedForNavigation, FALSE)
	|";
	
	// Let's form a description of possible error codes in the movements.
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Trong sản xuất dở dang, để làm lô hàng sản xuất có sử dụng tham chiếu đến chứng từ lô hàng, mà không phải danh mục ""Lô hàng sản xuất""';
										|ru = 'В незавершенном производстве в качестве партии производства используется ссылка на документ партии, а не на справочник ""Партии производства""';
										|en = 'In unfinished production, a reference to lot document is used instead of the reference to the ""Production lots"" catalog'; fa = 'In unfinished production, a reference to lot document is used instead of the reference to the ""Production lots"" catalog';
										|it = 'Nella produzione non terminata, come lotto di produzione di utilizza un collegamento al documento del lotto, e non all''elenco ""Lotti di produzione""';
										|pl = 'W niezakończonej produkcji jako partia produkcji jest stosowany odnośnik do dokumentu partii, a nie do katalogu ""Partie produkcji""';
										|tr = 'Devam eden imalatta, üretim lotu olarak ""Üretim Lotları"" kataloğu değil, lot belgesine yapılan bir bağlantı kullanılır'", Common.DefaultLanguageCode()));
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chuyển sang lô hàng sản xuất mới';
			|ru = 'переход на новую партию производства';
			|en = 'transfer to new production lot'; fa = 'transfer to new production lot';
			|it = 'passaggio ad un nuovo lotto di produzione';
			|pl = 'przejście do nowej partii produkcji';
			|tr = 'yeni lot üretimine transfer'", Common.DefaultLanguageCode()));
	
	// We will prepare a request for the formation of a registration with incorrect movements.
	// We select only the documents "Reflection of the payment in the financial accounting", since all the others have already been rechecked.
	Query.Text = " 
	|SELECT DISTINCT
	|	""WIPLaborCosts""	AS RegisterName,
	|	T.Recorder								AS Ref,
	|	T.Organization								AS Organization,
	|	1											AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.WIPLaborCosts AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND ISNULL(T.ProductionLot.UsedForNavigation, FALSE)
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'lưu chuyển không chính xác ""Chi phí nhân công của SXDD""';
			|ru = 'некорректные движения ""Трудозатраты НЗП""';
			|en = 'incorrect records ""Labor costs of WIP""'; fa = 'incorrect records ""Labor costs of WIP""';
			|it = 'movimenti incorretti ""Costo di manodopera della Produzione Incompleta (lavori/prodotti in corso di fabbricazione)""';
			|pl = 'niepoprawne ruchy ""Трудозатраты НЗП""';
			|tr = '""İş gücü maliyetleri TMÜ""nin yanlış hareketleri'", Common.DefaultLanguageCode()));
	
	#EndRegion

	#Region RecordsProductsProducts
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Chưa tạo bản ghi kết chuyển về số lượng theo biểu ghi ""Bản ghi kết chuyển Mặt hàng - Mặt hàng"".';
										|ru = 'Не сформированы количественные движения по регистру ""Движения Номенклатура - Номенклатура"".';
										|en = 'Quantitative register records ""Line item records"" are not generated.'; fa = 'Quantitative register records ""Line item records"" are not generated.';
										|it = 'Non sono stati generati i movimenti di quantità per il registro ""Movimenti di articoli - Articoli"".';
										|pl = 'Nie utworzono ilościowych przepływów wg rejestrów ""Przepływy Nomenklatura - Nomenklatura"".';
										|tr = '""Hareketler Öğe - Öğe"" kaydındaki nicel hareketler oluşturulmadı.'"));
	
	Query.Text = "
	|SELECT DISTINCT
	|	T.Recorder				AS Ref,
	|	T.Organization				AS Organization
	|INTO TTCostRegisteredRecordsWriteOffInProduction
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND T.CorItemsLocationAttributes <> T.ItemsLocationAttributes
	|	AND VALUETYPE(T.Recorder) IN (
	|		TYPE(Document.ProductionStage2_2),
	|		TYPE(Document.BackflushProduction))
	|INDEX BY
	|	Ref
	|;
	|
	|SELECT DISTINCT
	|	T.Recorder AS Ref
	|INTO TTMovementProductsWriteOffInProduction
	|FROM
	|	AccumulationRegister.RecordsProductsProducts AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND NOT T.CalculationOfCost
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND VALUETYPE(T.Recorder) IN (
	|		TYPE(Document.ProductionStage2_2),
	|		TYPE(Document.BackflushProduction))
	|INDEX BY
	|	Ref
	|;
	|
	|SELECT DISTINCT
	|	""RecordsProductsProducts""	AS RegisterName,
	|	Cost_.Ref					AS Ref,
	|	Cost_.Organization				AS Organization,
	|	1 										AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	TTCostRegisteredRecordsWriteOffInProduction AS Cost_
	|	LEFT JOIN TTMovementProductsWriteOffInProduction AS RegisterRecords
	|		ON RegisterRecords.Ref = Cost_.Ref
	|WHERE
	|	RegisterRecords.Ref IS NULL
	|";

	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển chứng từ sản xuất theo biểu ghi ""Bản ghi kết chuyển mặt hàng-mặt hàng""';
			|ru = 'исправление движений документов производства по регистру ""Движения номенклатура-номенклатура""';
			|en = 'correction of production document records on the register ""Line item records""'; fa = 'correction of production document records on the register ""Line item records""';
			|it = 'correzione di movimento dei documenti di produzione secondo il registro ""Movimenti articoli-articoli""';
			|pl = 'korekta ruchów dokumentów produkcji wg rejestru ""Ruchy pozycja-pozycja""';
			|tr = '""Hareketler öğe-öğe"" kaydındaki üretim belgelerinin hareketlerinin düzeltilmesi'"));
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(
		CalculationParameters,
		"TTCostRegisteredRecordsWriteOffInProduction, TTMovementProductsWriteOffInProduction");
	
	#EndRegion
	#Region RegisterRecordsProductsIncomeExpenses
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Đã tạo sai các bản ghi kết chuyển theo biểu ghi ""Bản ghi kết chuyển Mặt hàng - Thu nhập/Chi phí"".';
										|ru = 'Сформированы некорректные движения по регистру ""Движения Номенклатура - Доходы/Расходы"".';
										|en = 'Invalid records were generated for the ""Items - Income/Expenses"" register.'; fa = 'Invalid records were generated for the ""Items - Income/Expenses"" register.';
										|it = 'Sono stati creati dei movimenti incorretti per il registro ""Movimenti Nomenclatura - Entrate/Uscite"".';
										|pl = 'Utworzono nieprawidłowe ruchy wg rejestru ""Ruchy Pozycje - Dochody/Rozchody"".';
										|tr = '""Hareketler Öğe- Gelir/Gider"" kaydında hatalı hareketler oluşturuldu.'"));
	
	Query.Text = "
	|SELECT DISTINCT
	|	T.Recorder				AS Ref,
	|	T.Period					AS Period,
	|	T.Organization				AS Organization
	|INTO TTCostRegisteredRecordsWriteOffInProduction
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|INDEX BY
	|	Ref,
	|	Period
	|;
	|
	|SELECT DISTINCT
	|	T.Recorder 				AS Ref,
	|	T.Period	  				AS Period
	|INTO TTMovementProductsWriteOffInProduction
	|FROM
	|	AccumulationRegister.RegisterRecordsProductsIncomeExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND NOT T.CalculationOfCost
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|INDEX BY
	|	Ref,
	|	Period
	|;
	|
	|SELECT DISTINCT
	|	""RegisterRecordsProductsIncomeExpenses""	AS RegisterName,
	|	Cost_.Ref					AS Ref,
	|	Cost_.Organization				AS Organization,
	|	1 										AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	TTCostRegisteredRecordsWriteOffInProduction AS Cost_
	|	LEFT JOIN TTMovementProductsWriteOffInProduction AS RegisterRecords
	|		ON RegisterRecords.Ref = Cost_.Ref
	|		 AND RegisterRecords.Period = Cost_.Period
	|WHERE
	|	RegisterRecords.Ref IS NULL
	|";

	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển chứng từ theo biểu ghi ""Bản ghi kết chuyển mặt hàng thu nhập-chi phí""';
			|ru = 'исправление движений документов по регистру ""Движения номенклатура доходы-расходы""';
			|en = 'correction of document records on the register ""Items - Income/Expenses""'; fa = 'correction of document records on the register ""Items - Income/Expenses""';
			|it = 'correzione di movimenti nei documenti del registro ""Movimenti articoli entrate-uscite""';
			|pl = 'korekta ruchów dokumentów wg rejestru ""Ruchy pozycja dochody-rozchody""';
			|tr = '""Kayıtlar öğe gelir-gider"" kaydındaki belge kayıtlarının düzeltilmesi'"));
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(
		CalculationParameters,
		"TTCostRegisteredRecordsWriteOffInProduction, TTMovementProductsWriteOffInProduction");
	
	#EndRegion

	#Region LineOfBusinessInOtherExpenses
		
	// In the registers "Other expenses" and "Lots of other expenses", the direction of activity is filled in only when the
	// cost accounting for the direction of activity is enabled. 
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Đã điền mảng hoạt động khi tắt sử dụng ghi nhận chi phí';
										|ru = 'Заполнено направление деятельности с выключенным учетом затрат';
										|en = 'The line of business has been filled in with expenses accounting disabled'; fa = 'The line of business has been filled in with expenses accounting disabled';
										|it = 'Risulta compilato il settore di attività con contabilità spese disabilitata';
										|pl = 'Wypełniony rodzaj działalnością z wyłączoną ewidencją rozchodów';
										|tr = 'Maliyet muhasebesi kapalıyken iş kolu dolduruldu'"));
	
	Query.Text = "
	|SELECT DISTINCT
	|	""OtherExpenses""		 AS RegisterName,
	|	T.Recorder			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	1 						 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND NOT T.LineOfBusiness.CostAccounting
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""ItemisedExpensesLots"" AS RegisterName,
	|	T.Recorder			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	1 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND NOT T.LineOfBusiness.CostAccounting
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|";
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'điền sai mảng hoạt động trong chi phí khác';
			|ru = 'некорректное заполнение направления деятельности в прочих расходах';
			|en = 'incorrect filling of the line of business in other expenses'; fa = 'incorrect filling of the line of business in other expenses';
			|it = 'compilazione errata del settore di attività nelle altre spese';
			|pl = 'niepoprawne wypełnienie rodzaju działalności w pozostałych rozchodach';
			|tr = 'diğer giderlerde iş kolunun yanlış doldurulması'"));
	
	#EndRegion

	#Region PartnerInProductAccountingAnalytics
	
	// Replacement of the inventory accounting analysis keys with a partner with the keys with the counterparty's contract.
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Trong khóa đối tượng phân tích kế toán mặt hàng trong biểu ghi ""Giá vốn hàng hóa"" đã chỉ ra bạn hàng, mà không phải hợp đồng với đối tác.';
										|ru = 'В ключе аналитики учета номенклатуры в регистре ""Себестоимость товаров"" указан партнер, а не договор контрагента.';
										|en = 'In the inventory location attribute key, in the ""Inventory cost"" register, a partner is specified instead of a counterparty contract.'; fa = 'In the inventory location attribute key, in the ""Inventory cost"" register, a partner is specified instead of a counterparty contract.';
										|it = 'Nella chiave di analisi della contabilità della nomenclatura nel registro ""Costo di produzione delle merci"" è specificato il partner, e non il contratto del contraente.';
										|pl = 'W kluczowej analizie spisu nomenklatury w rejestrze „Koszt towarów” wskazany jest partner, a nie umowa z kontrahentem.';
										|tr = 'Öğe muhasebesi boyutu anahtarında, ""Stok maliyeti"" kaydı cari hesap sözleşmesini değil, iş ortağı belirtildi.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Trong khóa đối tượng phân tích kế toán mặt hàng trong biểu ghi ""Mua hàng"" đã chỉ ra bạn hàng, mà không phải hợp đồng với đối tác.';
										|ru = 'В ключе аналитики учета номенклатуры в регистре ""Закупки"" указан партнер, а не договор контрагента.';
										|en = 'In the inventory location attribute key, in the ""Purchases"" register, a partner is specified instead of a counterparty contract.'; fa = 'In the inventory location attribute key, in the ""Purchases"" register, a partner is specified instead of a counterparty contract.';
										|it = 'Nella chiave di analisi della contabilità della nomenclatura nel registro ""Acquisti"" è specificato il partner, e non il contratto del contraente.';
										|pl = 'W kluczu analizy księgowości zapasów w rejestrze „Nabycie” wskazany jest partner, a nie umowa z kontrahentem.';
										|tr = 'Satın almalar kaydındaki öğe muhasebe boyutu anahtarı, cari sözleşmesini değil, bir iş ortağı belirtildi.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(3, NStr("vi = 'Khóa đối tượng phân tích kế toán mặt hàng trong biểu ghi ""Bản ghi kết chuyển Mặt hàng - Mặt hàng"" đã chỉ ra đối tác mà không phải là thỏa thuận của đối tác.';
										|ru = 'В ключе аналитики учета номенклатуры в регистре ""Движения Номенклатура - Номенклатура"" указан партнер, а не договор контрагента.';
										|en = 'In the inventory location attribute key, in the ""Line item records"" register, a partner is specified instead of a counterparty contract.'; fa = 'In the inventory location attribute key, in the ""Line item records"" register, a partner is specified instead of a counterparty contract.';
										|it = 'Nella chiave di analisi della contabilità della nomenclatura nel registro ""Movimenti Nomenclatura - Nomenclatura"" è specificato il partner, e non il contratto del contraente.';
										|pl = 'W kluczu analizy księgowości nomenklatury w rejestrze „Nomenklatura - Nomenklatura” wskazany jest partner, a nie umowa z kontrahentem.';
										|tr = 'Öğe muhasebe boyutu anahtarında, Hareketler Öğe - Öğe kaydı cari hesap sözleşmesi değil, iş ortağı belirtildi.'", Common.DefaultLanguageCode()));
	
	Query.Text =
	"SELECT DISTINCT
	|	""InventoryCost""	AS RegisterName,
	|	T.Recorder				AS Ref,
	|	T.Organization				AS Organization,
	|	1							AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND T.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
	|	AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""Purchases""	  AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	2			  AS ErrorCode
	|FROM
	|	AccumulationRegister.Purchases AS T
	|
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND T.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoodsInTransit),
	|		VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|	AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|	AND NOT T.CalculationOfCost
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""RecordsProductsProducts"" AS RegisterName,
	|	T.Recorder						 AS Ref,
	|	T.Organization						 AS Organization,
	|	3									 AS ErrorCode
	|FROM
	|	AccumulationRegister.RecordsProductsProducts AS T
	|
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND T.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoodsInTransit),
	|		VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery))
	|	AND T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|	AND NOT T.CalculationOfCost
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'sửa khóa của đối tượng phân tích kế toán hàng tồn kho trong các biểu ghi (thay thế đối tác bằng hợp đồng)';
			|ru = 'исправление ключей аналитики учета номенклатуры в регистрах (замена партнера на договор)';
			|en = 'correction of the inventory location attribute keys in registers (replacement of a partner for a contract)'; fa = 'correction of the inventory location attribute keys in registers (replacement of a partner for a contract)';
			|it = 'correzione delle chiavi delle analisi contabili di nomenclatura nei registri (sostituzione del partner per un contratto)';
			|pl = 'korekta kluczy analityki inwentaryzacji nomenklatury w rejestrach (zamiana partnera na umowę)';
			|tr = 'kayıtlardaki öğe muhasebe boyutu anahtarlarının düzeltilmesi (iş ortağının sözleşme ile değiştirilmesi)'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region NoCustomsDutyInDocumentRegisteredRecordsCustomsDeclarationImport
	
	// Correction of movements in the register "Cost of goods" for documents "Customs declaration for import".
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Trong bản ghi kết chuyển tờ khai hải quan nhập khẩu theo biểu ghi ""Giá vốn hàng hóa"" không có số tiền thuế. Cần kết chuyển lại chứng từ theo biểu ghi ""Giá vốn hàng hóa"".';
										|ru = 'В движения таможенной декларации на импорт по регистру ""Себестоимость товаров"" отсутствует сумма пошлины. Требуется перепровести документ по регистру ""Себестоимость товаров""';
										|en = 'Duty amount is missing in records of the customs declaration for import by the ""Inventory cost"" register. Repost the document for the ""Inventory cost"" register'; fa = 'Duty amount is missing in records of the customs declaration for import by the ""Inventory cost"" register. Repost the document for the ""Inventory cost"" register';
										|it = 'Nei movimenti della dichiarazione doganale di importazione sul registro ""Costo di produzione delle merci"" manca l''importo di dazio. È necessario eseguire una nuova registrazione del documento sul registro ""Costo di produzione delle merci""';
										|pl = 'W ruchu deklaracji celnej importu do rejestru „Koszt towarów” nie ma kwoty cła. Wymagane jest ponowne przekazanie dokumentu do rejestru „Koszt własny towarów”';
										|tr = '""Stok maliyeti"" kaydında yer alan ithalat gümrük beyannamesi hareketinde gümrük vergisi tutarı bulunmamaktadır. ""Stok maliyeti"" kaydında belgenin yeniden kaydedilmesi gerekmektedir'", Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	Declaration.Ref 		 AS Ref,
	|	Declaration.Organization 	 AS Organization,
	|	1 						 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	Document.CCDImport AS Declaration
	|	LEFT JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|		ON Declaration.Ref = RegisterRecords.Recorder
	|		AND RegisterRecords.EntryType IN (
	|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
	|			VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified))
	|WHERE
	|	Declaration.Posted
	|	AND Declaration.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Declaration.Organization IN (&CompanyArray)
	|	AND Declaration.Status <> VALUE(Enum.CustomsDeclarationStatus.CustomsClearance)
	|	AND (Declaration.DocumentAmount - Declaration.CustomsFee - Declaration.CustomsPenalty) <> 0
	|	AND RegisterRecords.Recorder IS NULL
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT Declaration.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|SELECT TOP 0
	|	""InventoryCost"" AS RegisterName,
	|	RegisterRecords.Recorder	 AS Ref,
	|	RegisterRecords.Organization 	 AS Organization,
	|	1 						 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS RegisterRecords
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'không phản ánh thuế hải quan trong bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa""';
			|ru = 'не отражена таможенная пошлина в движениях по регистру ""Себестоимость товаров""';
			|en = 'customs duty is not recorded in records for the ""Inventory cost"" register'; fa = 'customs duty is not recorded in records for the ""Inventory cost"" register';
			|it = 'il dazio doganale non è riportato nei movimenti del registro ""Costo di produzione delle merci""';
			|pl = 'Cła nie są odzwierciedlone w ruchach w rejestrze „Koszt własny towarów”';
			|tr = '""Stok maliyeti"" kayıtlarındaki hareketlerde gümrük vergisi yansıtılmadı'", Common.DefaultLanguageCode()));

	
	#EndRegion
	
	#Region ShipmentAnalyticsInReturnOfGoodsBetweenOrganizations
	
	// Filling in the new props of the tabular part of the views of the reserves
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Chưa điền đối tượng phân tích mặt hàng giao hàng trong chứng từ trả lại hàng hóa giữa các doanh nghiệp.';
										|ru = 'Не заполнена аналитика номенклатуры отгрузки в документе возврата товаров между организациями.';
										|en = 'Shipped products dimension is required in the ""Goods return — Intercompany"" document.'; fa = 'Shipped products dimension is required in the ""Goods return — Intercompany"" document.';
										|it = 'L''analisi della nomenclatura della spedizione non è compilata nel documento di reso delle merci tra le aziende.';
										|pl = 'Nie została wypełniona analityka nomenklatury wysyłki w dokumencie zwrotu towarów między firmami.';
										|tr = 'Sevkiyat öğesi boyutu, iş yerleri arası ürün iadesi belgesinde doldurulmadı.'", Common.DefaultLanguageCode()));
	
	Query.Text =
	"SELECT DISTINCT
	|	T.Ref				AS Ref,
	|	T.Ref.Organization	AS Organization,
	|	1						AS ErrorCode
	|INTO TTRecordersForReconnection
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS T
	|
	|WHERE
	|	T.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Ref.Organization IN(&CompanyArray)
	|	AND T.Ref.Posted
	|	AND T.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument)
	|	AND T.ItemsLocationAttributesShipment = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|";
	
	CostCalculationAppliedAlgorithms.RecheckTheDocuments(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa khóa đối tượng phân tích kế toán mặt hàng giao hàng trong chứng từ trả lại hàng hóa giữa các doanh nghiệp';
			|ru = 'исправление ключей аналитики учета номенклатуры отгрузки в документе возврата товаров между организациями';
			|en = 'correction of shipped inventory dimension keys in the ""Goods return — Intercompany"" document'; fa = 'correction of shipped inventory dimension keys in the ""Goods return — Intercompany"" document';
			|it = 'correzione delle chiavi dell''analisi di nomenclatura della spedizione nel documento di reso delle merci tra le aziende';
			|pl = 'korekta kluczy analityki ewidencji nomenklatury wysyłki w dokumencie zwrotu towarów między firmami';
			|tr = 'İşyerleri arası ürün iadesi belgesinde sevkiyat öğesi muhasebesinin boyutu anahtarlarının düzeltilmesi'", Common.DefaultLanguageCode()));
	
	#EndRegion

	#Region TurningOnCostAccountingByPurposes
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'bật sử dụng hạch toán giá vốn theo mục đích';
										|ru = 'Включение учета себестоимости по назначениям';
										|en = 'enable cost accounting by assignments'; fa = 'enable cost accounting by assignments';
										|it = 'abilitazione del calcolo di costo di produzione per assegnazioni';
										|pl = 'włączenie ewidencji kosztów własnych według przeznaczeń';
										|tr = 'atamalara göre maliyet muhasebesinin etkinleştirilmesi'", Common.DefaultLanguageCode()));

	Query.SetParameter("ImportDocumentType", Common.MetadataObjectID("Document.CCDImport"));
	
	Query.Text = QueryTextTurningOnCostAccountingByPurposes();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bật sử dụng hạch toán giá vốn theo mục đích';
			|ru = 'включение учета себестоимости по назначениям';
			|en = 'enable cost accounting by assignments'; fa = 'enable cost accounting by assignments';
			|it = 'abilitazione del calcolo di costo di produzione per assegnazioni';
			|pl = 'włączenie ewidencji kosztów własnych według przeznaczeń';
			|tr = 'atamalara göre maliyet muhasebesinin etkinleştirilmesi'", Common.DefaultLanguageCode()));
		
	Query.Text = RequestTextEnablingRevenueAndCostOfSalesAccountingByDestination();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bật sử dụng ghi nhận doanh thu và giá vốn bán hàng theo mục đích';
			|ru = 'включение учета выручки и себестоимости продаж по назначениям';
			|en = 'enabling accounting of revenue and COGS by assignments'; fa = 'enabling accounting of revenue and COGS by assignments';
			|it = 'abilitazione del calcolo di costo di vendite per assegnazioni';
			|pl = 'włączenie ewidencji przychodów i kosztów własnych sprzedaży według przeznaczeń';
			|tr = 'atamaya göre gelirin muhasebeleştirilmesi ve satışların maliyetinin dahil edilmesi'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region TurningOffCostAccountingByPurposes
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'bật quản lý giá vốn theo mục đích';
										|ru = 'Выключение учета себестоимости по назначениям';
										|en = 'disable cost accounting by assignments'; fa = 'disable cost accounting by assignments';
										|it = 'Выключение учета себестоимости по назначениям';
										|pl = 'Wyłączenie ewidencji kosztów własnych według przeznaczeń';
										|tr = 'atamaya göre maliyet muhasebesinin kapatılması'", Common.DefaultLanguageCode()));
	
	Query.Text = QueryTextTurningOffCostAccountingByPurposes();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bật quản lý giá vốn theo mục đích';
			|ru = 'выключение учета себестоимости по назначениям';
			|en = 'disable cost accounting by assignments'; fa = 'disable cost accounting by assignments';
			|it = 'выключение учета себестоимости по назначениям';
			|pl = 'wyłączenie ewidencji kosztów własnych według przeznaczeń';
			|tr = 'atamaya göre maliyet muhasebesinin kapatılması'", Common.DefaultLanguageCode()));
		
	Query.Text = RequestTextDisablingRevenueAndCostOfSalesAccountingByDestination();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'tắt sử dụng ghi nhận doanh thu và giá vốn bán hàng theo mục đích';
			|ru = 'выключение учета выручки и себестоимости продаж по назначениям';
			|en = 'disabling accounting of revenue and COGS by assignments'; fa = 'disabling accounting of revenue and COGS by assignments';
			|it = 'abilitazione del calcolo di costo di vendite per assegnazioni';
			|pl = 'wyłączenie ewidencji przychodów i kosztów własnych sprzedaży według przeznaczeń';
			|tr = 'atamaya göre gelir ve satış maliyeti muhasebesinin kapatılması'", Common.DefaultLanguageCode()));
		
	#EndRegion
		
	#Region TurningOnTurnoverAccountingByInventoryKinds
	
	DecodingErrorCodes = New Map;	
	DecodingErrorCodes.Insert(1, NStr("vi = 'bật sử dụng hạch toán giá vốn theo dạng vật tư';
										|ru = 'Включение учета себестоимости по видам запасов';
										|en = 'Enable cost accounting by inventory owner attributes'; fa = 'Enable cost accounting by inventory owner attributes';
										|it = 'abilitazione del calcolo di costo per tipi di scorte';
										|pl = 'włączenie ewidencji kosztów własnych według rodzajów zapasów';
										|tr = 'stok türüne göre maliyet muhasebesinin dahil edilmesi'", Common.DefaultLanguageCode()));
	
	Query.Text = QueryTextTurningOnTurnoverAccountingByInventoryKinds();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bật sử dụng hạch toán giá vốn theo dạng vật tư';
			|ru = 'включение учета себестоимости по видам запасов';
			|en = 'Enable cost accounting by inventory owner attributes'; fa = 'Enable cost accounting by inventory owner attributes';
			|it = 'abilitazione del calcolo di costo per tipi di scorte';
			|pl = 'włączenie ewidencji kosztów własnych według rodzajów zapasów';
			|tr = 'stok türüne göre maliyet muhasebesinin dahil edilmesi'", Common.DefaultLanguageCode()));
		
	Query.Text = RequestTextEnablingRevenueAndCostOfSalesAccountingByInventoryType();
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bật sử dụng hạch toán doanh thu và giá vốn theo dạng hàng tồn kho';
			|ru = 'включение учета выручки и себестоимости продаж по видам запасов';
			|en = 'enabling accounting of revenue and COGS by inventory owner attributes'; fa = 'enabling accounting of revenue and COGS by inventory owner attributes';
			|it = 'abilitazione del calcolo di vendite e del costo di vendite per tipi di scorte';
			|pl = 'wyłączenie ewidencji przychodów i kosztów własnych sprzedaży według rodzajów zapasów';
			|tr = 'stok türüne göre gelirin muhasebeleştirilmesi ve satışların maliyetinin dahil edilmesi'", Common.DefaultLanguageCode()));
	
	#EndRegion
	#Region ConformityOfGoodsOfOrganizationsAndCostPrice
	
	// Correction of movements by register Output
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Bản ghi kết chuyển của công đoạn sản xuất theo biểu ghi ""Giá vốn hàng hóa"" không tương ứng với biểu ghi ""Hàng hóa trong doanh nghiệp"". Cần kết chuyển lại chứng từ theo biểu ghi ""Giá vốn hàng hóa""';
										|ru = 'Движения этапа производства по регистру ""Себестоимость товаров"" не соответствуют регистру ""Товары организаций"". Требуется перепровести документ по регистру ""Себестоимость товаров""';
										|en = 'Movements of production stage in the ""Inventory cost"" register do not correspond to the ""Company goods"" register. Repost the document for the ""Inventory cost"" register'; fa = 'Movements of production stage in the ""Inventory cost"" register do not correspond to the ""Company goods"" register. Repost the document for the ""Inventory cost"" register';
										|it = 'I movimenti della fase di produzione per il registro ""Costo di produzione delle merci"" non corrispondono al registro ""Merci delle organizzazioni"". È necessario ri-registrare il documento sul registro ""Costo di produzione delle merci""';
										|pl = 'Ruchy etapu produkcji w rejestrze ""Себестоимость товаров"" nie odpowiadają rejestru ""Товары организаций"". Trzeba przeksięgować dokument w rejestrze ""Себестоимость товаров""';
										|tr = '""Stok maliyeti"" kaydındaki üretim aşamasının hareketleri ""İş yerleri ürünleri"" kaydına karşılık gelmemektedir. ""Stok maliyeti"" kaydındaki belgenin yeniden kaydedilmesi gerekmektedir'", Common.DefaultLanguageCode()));
	
	Query.Text =
	"SELECT
	|	CompanyGoods.Recorder AS Recorder,
	|	(CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN CompanyGoods.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END) AS ItemsLocationAttributes,
	|	CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CompanyGoods.Count + CompanyGoods.ToRegisterGoodsIssue AS Count,
	|	CompanyGoods.Organization AS Organization
	|INTO TTGoodsOfOrganizationsAndCost
	|FROM
	|	AccumulationRegister.CompanyGoods AS CompanyGoods
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON AnalyticsWithoutAssignment.Products = CompanyGoods.ItemsLocationAttributes.Products
	|	AND AnalyticsWithoutAssignment.Characteristic = CompanyGoods.ItemsLocationAttributes.Characteristic
	|	AND AnalyticsWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|	AND AnalyticsWithoutAssignment.Series = CompanyGoods.ItemsLocationAttributes.Series
	|	AND AnalyticsWithoutAssignment.StorageLocation = CompanyGoods.ItemsLocationAttributes.StorageLocation
	|	AND AnalyticsWithoutAssignment.ProductCostElement = CompanyGoods.ItemsLocationAttributes.ProductCostElement
	|
	|WHERE
	|	VALUETYPE(CompanyGoods.Recorder) = TYPE(Document.ProductionStage2_2)
	|	AND CompanyGoods.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CompanyGoods.Organization IN (&CompanyArray)
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryCost.Recorder,
	|	InventoryCost.ItemsLocationAttributes,
	|	InventoryCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	-InventoryCost.Count,
	|	InventoryCost.Organization
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|
	|	LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS OutputProductTable
	|	ON InventoryCost.Recorder = OutputProductTable.Ref
	|	AND InventoryCost.RowID = OutputProductTable.RowID
	|
	|	LEFT JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS TableOfByProducts
	|	ON InventoryCost.Recorder = TableOfByProducts.Ref
	|	AND InventoryCost.RowID = TableOfByProducts.RowID
	|
	|WHERE
	// We exclude movements in work-in-progress.
	|	VALUETYPE(InventoryCost.Recorder) = TYPE(Document.ProductionStage2_2)
	|	AND InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND InventoryCost.ItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	// We exclude the issue at the planned cost.
	|	AND InventoryCost.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	// We exclude only untraceable works.
	|	AND (InventoryCost.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|		OR InventoryCost.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND InventoryCost.ItemsLocationAttributes.Products.TracedGoods
	|			AND InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		)
	// We exclude the movement to the registration of reports to the giver.
	|	AND NOT (
	|		InventoryCost.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		AND InventoryCost.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ProductsRelease),
	|			VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|			VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|		AND InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		AND (NOT InventoryCost.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			OR InventoryCost.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef))
	|		)
	// We exclude goods purchased from the commitee.
	| 	AND NOT (
	|		InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		AND InventoryCost.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner))
	// We exclude movements at cost for products that are written off as expenses, because there are no similar movements in the goods of organizations.
	|	AND NOT ISNULL(OutputProductTable.ToExpenseAs, FALSE)
	|	AND NOT ISNULL(TableOfByProducts.ToExpenseAs, FALSE)
	// Exclude internal processing Registered Records, Receipt and expense of affiliated organizations of branches
	|	AND NOT (InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			AND InventoryCost.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
	|			AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)
	|		)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	TTMovement.Recorder AS Ref,
	|	TTMovement.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	TTGoodsOfOrganizationsAndCost AS TTMovement
	|
	|GROUP BY
	|	TTMovement.Recorder,
	|	TTMovement.ItemsLocationAttributes,
	|	TTMovement.InventoryOwnerAttribute,
	|	TTMovement.Organization
	|
	|HAVING
	|	SUM(TTMovement.Count) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTGoodsOfOrganizationsAndCost
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'sai bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa""';
			|ru = 'некорректные движения по регистру ""Себестоимость товаров""';
			|en = 'incorrect records in the ""Inventory cost"" register'; fa = 'incorrect records in the ""Inventory cost"" register';
			|it = 'movimenti incorretti per il registro ""Costo di produzione dei prodotti""';
			|pl = 'niepoprawne ruchy w rejestrze ""Себестоимость товаров""';
			|tr = '""Stok maliyeti"" kaydındaki hatalı hareketler'", Common.DefaultLanguageCode()));
	
	#EndRegion
	#Region PurchaseAdjustment
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Sai giao dịch ghi nhận giá vốn trong bản ghi kết chuyển của chứng từ ""Điều chỉnh mua hàng"".';
										|ru = 'Неправильная операция учета себестоимости в движениях документа ""Корректировка приобретения"".';
										|en = 'Incorrect cost accounting transaction in the ""Purchase adjustment"" document register records'; fa = 'Incorrect cost accounting transaction in the ""Purchase adjustment"" document register records';
										|it = 'Неправильная операция учета себестоимости в движениях документа ""Корректировка приобретения"".';
										|pl = 'Incorrect cost accounting transaction in the ""Purchase adjustment"" document register records';
										|tr = '""Satın alma düzeltmesi"" belgesinin hareketlerinde hatalı maliyet muhasebesi işlemi.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Sai số tiền thuế GTGT trong bản ghi kết chuyển chứng từ ""Điều chỉnh mua hàng"".';
										|ru = 'Неправильные суммы НДС в движениях документа ""Корректировка приобретения"".';
										|en = 'Incorrect VAT amounts in register records for the ""Purchase adjustment"" document.'; fa = 'Incorrect VAT amounts in register records for the ""Purchase adjustment"" document.';
										|it = 'Importi IVA non corretti nelle registrazioni del documento ""Correzione di acquisizione"".';
										|pl = 'Niepoprawne wartości VAT w przepływach dokumentu ""Korekta zakupu"".';
										|tr = '""Satın alma düzeltmesi"" belgesinin hareketlerinde hatalı KDV tutarları.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(3, NStr("ru = 'Лишние движения по регистру ""Движения Прочие активы и пассивы"" у документа ""Корректировка приобретения"".';
										|vi = 'Extra records of the ""Purchase adjustment"" document in the ""Other assets and liabilities records"" register.';
										|en = 'Extra records of the ""Purchase adjustment"" document in the ""Other assets and liabilities records"" register.'; fa = 'Extra records of the ""Purchase adjustment"" document in the ""Other assets and liabilities records"" register.';
										|it = 'Extra records of the ""Purchase adjustment"" document in the ""Other assets and liabilities records"" register.';
										|pl = 'Extra records of the ""Purchase adjustment"" document in the ""Other assets and liabilities records"" register.';
										|tr = '""Satın alma düzeltmesi"" belgesinde ""Diğer varlıklar ve yükümlülükler hareketleri"" kaydında fazla hareket bulunmaktadır.'", Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Ref 		 		 AS Ref,
	|	T.Organization 	 		 AS Organization,
	|	1 						 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	Document.PurchaseAdjustment AS T
	|	INNER JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|		ON T.Ref = RegisterRecords.Recorder
	|WHERE
	|	T.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND RegisterRecords.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
	|	AND T.Posted
	|	AND NOT RegisterRecords.LotCalculation
	|	AND NOT RegisterRecords.CalculationOfCost
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Ref 		 		 AS Ref,
	|	T.Organization 	 		 AS Organization,
	|	2 						 AS ErrorCode
	|FROM
	|	Document.PurchaseAdjustment AS T
	|	INNER JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|		ON T.Ref = RegisterRecords.Recorder
	|WHERE
	|	T.Posted
	|	AND T.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND RegisterRecords.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|	AND (RegisterRecords.VATLocal <> 0 OR RegisterRecords.VATManag <> 0)
	|	AND NOT RegisterRecords.LotCalculation
	|	AND NOT RegisterRecords.CalculationOfCost
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""OtherAssetsAndLiabilitiesRecords"",
	|	T.Recorder,
	|	T.Organization,
	|	3
	|FROM
	|	AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS T
	|	INNER JOIN Document.PurchaseAdjustment AS DocumentAdjustingEntries
	|		ON DocumentAdjustingEntries.Ref = T.Recorder
	|	INNER JOIN Document.PurchaseAdjustment.Discrepancies AS CorrectingDiscrepancy
	|		ON CorrectingDiscrepancy.Ref = T.Recorder
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.AssetRef <> ISNULL(CAST(DocumentAdjustingEntries.ExpenseItem AS ChartOfCharacteristicTypes.AssetLiabilityItems), UNDEFINED)
	|	AND T.AssetRef <> ISNULL(CAST(DocumentAdjustingEntries.IncomeItem AS ChartOfCharacteristicTypes.AssetLiabilityItems), UNDEFINED)
	|	AND T.AssetRef <> ISNULL(CAST(CorrectingDiscrepancy.ExpenseItem AS ChartOfCharacteristicTypes.AssetLiabilityItems), UNDEFINED)
	|";

	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'Sửa chữa các bản ghi kết chuyển của chứng từ ""Điều chỉnh mua lại""';
			|ru = 'исправление движений документа ""Корректировка приобретения""';
			|en = 'corrected records in the ""Purchase adjustment"" document'; fa = 'corrected records in the ""Purchase adjustment"" document';
			|it = 'correzione derl movimento del documento ""Correzione di acquisto""""';
			|pl = 'poprawa ruchów dokumentu ""Korekta zakupu""';
			|tr = '""Satın alma düzeltmesi"" belgesindeki hareketlerin düzeltilmesi'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region SaleAdjustment
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Sai bản ghi kết chuyển trong chứng từ ""Điều chỉnh bán hàng"".';
										|ru = 'Неправильное движение в документе ""Корректировка реализации"".';
										|en = 'Incorrect register record in the ""Sales adjustment"" document.'; fa = 'Incorrect register record in the ""Sales adjustment"" document.';
										|it = 'Registrazione non corretta nel documento ""Correzione di vendita"".';
										|pl = 'Nieprawidłowy przepływ w dokumencie ""Korekta sprzedaży"".';
										|tr = '""Satış Düzeltmesi"" belgesinde yanlış hareket.'", Common.DefaultLanguageCode()));

	Query.SetParameter("CostAccountingByAssignmentValidFrom", Constants.CostAccountingByAssignmentValidFrom.Get());
	
	QueriesTexts = New Array;
	
	// when the separate cost accounting for assignments was turned off, in the document "adjustment of sales",
	// created on the basis of a document of the previous period, with a completed line of business,
	// an incoming movement was formed with incorrectly selected Product accounting analysts
	// who had a completed assignment.
	
	QueryText = "SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON InventoryCost.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND VALUETYPE(InventoryCost.Recorder) = TYPE(Document.SaleAdjustment)
	|	AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	AND InventoryLocationAttributeKeys.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	AND InventoryLocationAttributeKeys.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (NOT &KeepRecordsOfInventoryCostByAssignments
	|			OR &KeepRecordsOfInventoryCostByAssignments
	|				AND InventoryCost.Period < &CostAccountingByAssignmentValidFrom)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|";
	
	QueriesTexts.Add(QueryText);
	
	// When adjusting downwards (registration) of returnable containers from the sale of the previous period, batches were not formed at the close of the month, as the Analytics and inventory type were not filled in.
	
	QueryText = "SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	1 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND VALUETYPE(InventoryCost.Recorder) = TYPE(Document.SaleAdjustment)
	|	AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnPackageFromCustomerOfPreviousPeriods)
	|	AND InventoryCost.CorItemsLocationAttributes = VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	AND InventoryCost.CorInventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|";
	
	QueriesTexts.Add(QueryText);
	
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
	CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển chứng từ ""Điều chỉnh bán hàng""';
			|ru = 'исправление движений документа ""Корректировка реализации""';
			|en = 'correct register records in the ""Sales adjustment"" document'; fa = 'correct register records in the ""Sales adjustment"" document';
			|it = 'correzione dei movimenti del documento ""Correzione di vendita""';
			|pl = 'poprawa przepływów dokumentu ""Korekta sprzedaży""';
			|tr = '""Satış Düzeltme"" belgesindeki hareketlerin düzeltilmesi'", Common.DefaultLanguageCode()));
		
	// Adjustment documents that, according to the PH "Other expenses", generated incorrect incoming movements due to discrepancies in terms of VAT.                                       .
	// before the correction, the amount of the constant difference was not formed in such movements, which is why the Balance balances hung in other expenses, and extra TA amounts appeared in the transactions
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'sai bản ghi kết chuyển theo chứng từ ""Điều chỉnh bán hàng"" trong biểu ghi ""Chi phí khác""';
										|ru = 'Некорректные движения по документу ""Корректировка реализации"" в регистре ""Прочие расходы""';
										|en = 'incorrect register records in the ""Sales adjustment"" document of the ""Other expenses"" register'; fa = 'incorrect register records in the ""Sales adjustment"" document of the ""Other expenses"" register';
										|it = 'Некорректные движения по документу ""Корректировка реализации"" в регистре ""Прочие расходы""';
										|pl = 'incorrect register records in the ""Sales adjustment"" document of the ""Other expenses"" register';
										|tr = '""Diğer giderler"" kaydındaki ""Satış düzeltmesi"" belgesinde yanlış hareketler'", Common.DefaultLanguageCode()));
	
	Query.Text = "SELECT DISTINCT
	|	""OtherExpenses"" AS RegisterName,
	|	OtherExpenses.Recorder AS Ref,
	|	OtherExpenses.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|WHERE 
	|	OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND OtherExpenses.Organization IN (&CompanyArray) 
	|	AND VALUETYPE(OtherExpenses.Recorder) = TYPE(Document.SaleAdjustment)
	|	AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND OtherExpenses.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
	|	AND NOT OtherExpenses.ExpenseItem.EnteredInTaxAccounting
	|	AND OtherExpenses.PermanentDifference = 0
	|	AND OtherExpenses.Sum = 0
	|	AND OtherExpenses.AmountExcludingVAT = 0
	|	AND OtherExpenses.SumCompl <> 0
	|	AND OtherExpenses.SumMan <> 0";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'sai bản ghi kết chuyển theo chứng từ ""Điều chỉnh bán hàng"" trong biểu ghi ""Chi phí khác""';
			|ru = 'некорректные движения по документу ""Корректировка реализации"" в регистре ""Прочие расходы""';
			|en = 'incorrect register records in the ""Sales adjustment"" document of the ""Other expenses"" register'; fa = 'incorrect register records in the ""Sales adjustment"" document of the ""Other expenses"" register';
			|it = 'некорректные движения по документу ""Корректировка реализации"" в регистре ""Прочие расходы""';
			|pl = 'incorrect register records in the ""Sales adjustment"" document of the ""Other expenses"" register';
			|tr = '""Diğer giderler"" kaydındaki ""Satış düzeltmesi"" belgesinde yanlış hareketler'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region OtherGoodsRecordingAsReceived_InventoryConsumptionReverseTransaction
	
	// For Internal ConsumptionStorno write-Off, the Line Of Business In other Expenses Is not Filled In, although when writing off it is indicated
	//	that it is necessary to fill in the root Directions Of the Activity in such documents.
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Sai bản ghi trong chứng từ ""Ghi tăng khác"".';
										|ru = 'Неправильное движение в документе ""Прочее оприходование товаров"".';
										|en = 'Incorrect register record in the ""Other receipt of goods"" document.'; fa = 'Incorrect register record in the ""Other receipt of goods"" document.';
										|it = 'Неправильное движение в документе ""Прочее оприходование товаров"".';
										|pl = 'Incorrect register record in the ""Other receipt of goods"" document.';
										|tr = '""Diğer ürün girişleri"" belgesinde yanlış hareket.'", Common.DefaultLanguageCode()));

	Query.Text = "SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|		INNER JOIN Document.OtherGoodsRecordingAsReceived AS OtherGoodsRecordingAsReceived
	|		ON InventoryCost.Recorder = OtherGoodsRecordingAsReceived.Ref
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|	AND InventoryCost.CorLineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	AND OtherGoodsRecordingAsReceived.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
	CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển của chứng từ ""Ghi tăng khác""';
			|ru = 'исправление движений документа ""Прочее оприходование товаров""';
			|en = 'correct register records of the ""Other receipt of goods"" document'; fa = 'correct register records of the ""Other receipt of goods"" document';
			|it = 'исправление движений документа ""Прочее оприходование товаров""';
			|pl = 'correct register records of the ""Other receipt of goods"" document';
			|tr = '""Diğer ürün girişleri"" belgesinin hareketlerinin düzeltilmesi'", Common.DefaultLanguageCode()));
		
	#EndRegion
	#Region Production_WriteOffToOtherBatches
	
	DecodingErrorCodes = New Map;
	// For movements with the specified cost (returnable waste, planned cost), the movement document is not filled in, although it was indicated before,
	//	it is necessary to fill in the movement document in such records, otherwise the transactions are generated without taking into account the cost.
	DecodingErrorCodes.Insert(1, NStr("vi = 'Sai biến động trong chứng từ ""Sản xuất không theo đơn đặt hàng"".';
										|ru = 'Неправильное движение в документе ""Производство без заказа"".';
										|en = 'Incorrect register record in the ""Backflush production"" document.'; fa = 'Incorrect register record in the ""Backflush production"" document.';
										|it = 'Неправильное движение в документе ""Производство без заказа"".';
										|pl = 'Incorrect register record in the ""Backflush production"" document.';
										|tr = '""Geriye dönük üretim"" belgesinde hatalı hareket.'", Common.DefaultLanguageCode()));
	// For all production RegisteredRecords without an order, with the exception of Registered Records with the business transaction "", the identifier of the financial record must be indicated.
	DecodingErrorCodes.Insert(2, NStr("vi = 'Chưa chỉ ra IPM trong chứng từ ""Sản xuất không theo đơn đặt hàng"".';
										|ru = 'Не указывается ИФЗ в документе ""Производство без заказа"".';
										|en = 'The financial record ID is not specified in the ""Backflush production"" document.'; fa = 'The financial record ID is not specified in the ""Backflush production"" document.';
										|it = 'Не указывается ИФЗ в документе ""Производство без заказа"".';
										|pl = 'The financial record ID is not specified in the ""Backflush production"" document.';
										|tr = '""Geriye dönük üretim"" belgesinde herhangi bir IFZ belirtilmemiştir.'", Common.DefaultLanguageCode()));
	// For off-balance sheet inventory types, when transferring an item to production, only the place of accounting in analytics (per division) should change
	//	, the accounting section itself should remain the same. However, the accounting section "Work in progress" was indicated, which led to errors in the transactions.
	DecodingErrorCodes.Insert(3, NStr("vi = 'Sai bản ghi kết chuyển trong chứng từ ""Giai đoạn sản xuất"" khi ghi giảm đối với các lô hàng khác: đối với dạng vật tư ngoài bảng, phần ghi nhận cần phải là ngoài bảng.';
										|ru = 'Неправильное движение в документе ""Этап производства"" при списании на другие партии: для забалансовых типов запасов раздел учета должен оставаться забалансовым.';
										|en = 'Incorrect register record in the ""Production stage"" document when writing off to other lots: for off-balance inventory types, the branch of accounting must be off-balance.'; fa = 'Incorrect register record in the ""Production stage"" document when writing off to other lots: for off-balance inventory types, the branch of accounting must be off-balance.';
										|it = 'Неправильное движение в документе ""Этап производства"" при списании на другие партии: для забалансовых типов запасов раздел учета должен оставаться забалансовым.';
										|pl = 'Incorrect register record in the ""Production stage"" document when writing off to other lots: for off-balance inventory types, the branch of accounting must be off-balance.';
										|tr = 'Diğer partilere yazarken ""Üretim Aşaması"" belgesinde gerçekleştirilen işlem yanlış: Bakiye dışı envanter türleri için muhasebe bölümü bakiye dışı bırakılmalıdır.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(4, NStr("vi = 'Sai bản ghi kết chuyển trong chứng từ ""Sản xuất không có đơn hàng"" khi ghi giảm đối với các lô hàng khác: đối với dạng vật tư ngoài bảng, phần ghi nhận cần phải là ngoài bảng.';
										|ru = 'Неправильное движение в документе ""Производство без заказа"" при списании на другие партии: для забалансовых типов запасов раздел учета должен оставаться забалансовым.';
										|en = 'Incorrect register record in the ""Backflush production"" document when writing off to other lots: for off-balance inventory types, the branch of accounting must be off-balance.'; fa = 'Incorrect register record in the ""Backflush production"" document when writing off to other lots: for off-balance inventory types, the branch of accounting must be off-balance.';
										|it = 'Неправильное движение в документе ""Производство без заказа"" при списании на другие партии: для забалансовых типов запасов раздел учета должен оставаться забалансовым.';
										|pl = 'Incorrect register record in the ""Backflush production"" document when writing off to other lots: for off-balance inventory types, the branch of accounting must be off-balance.';
										|tr = 'Diğer partilere yazarken ""Geriye dönük üretim"" belgesinde gerçekleştirilen işlem yanlış: Bakiye dışı envanter türleri için muhasebe bölümü bakiye dışı bırakılmalıdır.'", Common.DefaultLanguageCode()));

	Query.Text = "SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|		INNER JOIN Document.BackflushProduction AS BackflushProduction
	|		ON InventoryCost.Recorder = BackflushProduction.Ref
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND InventoryCost.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots)
	|	AND InventoryCost.DocumentRegisterRecords = UNDEFINED
	|	AND InventoryCost.LocalCost <> 0
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	2 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|		INNER JOIN Document.BackflushProduction AS DocumentData
	|		ON InventoryCost.Recorder = DocumentData.Ref
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND InventoryCost.InventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider), VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider), VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|	AND InventoryCost.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction)
	|	AND InventoryCost.FinRecordID = &IDOfUnusedFinRecord
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	3 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|		INNER JOIN Document.ProductionStage2_2 AS DocumentData
	|		ON InventoryCost.Recorder = DocumentData.Ref
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND InventoryCost.InventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider), VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider), VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|	AND InventoryCost.Lot REFS Catalog.ProductionLots
	|	AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	4 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|		INNER JOIN Document.BackflushProduction AS DocumentData
	|		ON InventoryCost.Recorder = DocumentData.Ref
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Organization IN (&CompanyArray)
	|	AND InventoryCost.InventoryOwnerAttribute.InventoryType IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider), VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider), VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|	AND InventoryCost.Lot REFS Catalog.ProductionLots
	|	AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
	CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi của chứng từ sản xuất';
			|ru = 'исправление движений производственных документов';
			|en = 'correct register records of production documents'; fa = 'correct register records of production documents';
			|it = 'исправление движений производственных документов';
			|pl = 'correct register records of production documents';
			|tr = 'üretim belgeleri işlemlerinin düzeltilmesi'", Common.DefaultLanguageCode()));
		
	#EndRegion
	#Region ReturnToAnotherWarehouse
	
	DecodingErrorCodes = New Map;
	// When returning goods/containers to another warehouse or for a different purpose, instead of 3 Registered Records (reverse sales, transfer to another warehouse/destination
	//, one Registered Record should be made immediately according to new data, as implemented in Local accounting.
	DecodingErrorCodes.Insert(1, NStr("vi = 'Sai bản ghi kết chuyển trả lại sang kho khác trong chứng từ ""Nhận hàng bán bị trả lại"".';
										|ru = 'Неправильное движение возврата на другой склад в документе ""Возврат товаров от клиента"".';
										|en = 'Incorrect record of return to another warehouse in the ""Sales return"" document.'; fa = 'Incorrect record of return to another warehouse in the ""Sales return"" document.';
										|it = 'Неправильное движение возврата на другой склад в документе ""Возврат товаров от клиента"".';
										|pl = 'Incorrect record of return to another warehouse in the ""Sales return"" document.';
										|tr = '""Müşteriden ürün iadesi"" belgesinde iadenin yanlışlıkla başka bir ambara gönderilmesi.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Sai bản ghi kết chuyển trả lại sang kho khác trong chứng từ ""Nhận hàng bán bị trả lại giữa các doanh nghiệp"".';
										|ru = 'Неправильное движение возврата на другой склад в документе ""Возврат товаров между организациями"".';
										|en = 'Incorrect record of return to another warehouse in the ""Goods return — Intercompany"" document.'; fa = 'Incorrect record of return to another warehouse in the ""Goods return — Intercompany"" document.';
										|it = 'Неправильное движение возврата на другой склад в документе ""Возврат товаров между организациями"".';
										|pl = 'Incorrect record of return to another warehouse in the ""Goods return — Intercompany"" document.';
										|tr = '""İş yerleri arasında ürün iadesi"" belgesinde iadenin yanlışlıkla başka bir ambara gönderilmesi.'", Common.DefaultLanguageCode()));
	
	Query.Text =
	"SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Recorder REFS Document.ReturnOfGoodsFromCustomer
	|	AND InventoryCost.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse),
	|		VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse))
	|	AND InventoryCost.Count < 0 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT
	|	""InventoryCost"" AS RegisterName,
	|	InventoryCost.Recorder AS Ref,
	|	InventoryCost.Organization AS Organization,
	|	2 AS ErrorCode
	|FROM
	|	AccumulationRegister.InventoryCost AS InventoryCost
	|WHERE
	|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND InventoryCost.Recorder REFS Document.IntercompanyGoodsReturn
	|	AND InventoryCost.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse),
	|		VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse))
	|	AND InventoryCost.Count < 0 AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
	|
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
	CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển của chứng từ khi trả lại hàng hóa/bao bì vào kho khác';
			|ru = 'исправление движений документов при возврате товара/тары на другой склад';
			|en = 'Correction of document records when returning goods/packages to another warehouse'; fa = 'Correction of document records when returning goods/packages to another warehouse';
			|it = 'исправление движений документов при возврате товара/тары на другой склад';
			|pl = 'Correction of document records when returning goods/packages to another warehouse';
			|tr = 'ürünlerin/eşyaların başka bir ambara ürün iadesi gerçekleştirilirken belge kayıtlarında düzeltmesi'", Common.DefaultLanguageCode()));
		
	#EndRegion
	
	#Region RevenueServicesAndAssets
	
	// Documents that previously had movements in the "Other expenses" register should now form movements in the "Other Revenue" register:
	// - "Sale of services and other assets"
	// - "Adjustment of sales", which has a document - basis "Sale of services and other assets"
	// - "Accruals on loans and deposits"
	// - "Salary reflection in financial accounting"  
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Khôi phục các bản ghi kết chuyển theo biểu ghi ""Doanh thu khác"".';
										|ru = 'Восстановление движений по регистру ""Прочая выручка"".';
										|en = 'Restore records through ""Revenue — Services and Assets"" register.'; fa = 'Restore records through ""Revenue — Services and Assets"" register.';
										|it = 'Recupero dei movimenti in base al registro ""Altre entrate"".';
										|pl = 'Przywrócenie przepływów wg rejestru ""Pozostały utarg"".';
										|tr = '""Diğer Gelirler"" kaydındaki hareketlerin geri yüklenmesi.'", Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT DISTINCT
	|	T.Recorder     AS Recorder,
	|	T.Organization     AS Organization
	|INTO TTRegistrarsWithOtherIncome
	|FROM
	|	AccumulationRegister.OtherIncome AS T
	|	LEFT JOIN Document.SaleAdjustment AS Adjusting
	|		ON Adjusting.Ref = T.Recorder
	|	LEFT JOIN Document.CustomerInvoiceServicesAndAssets AS ImplementationOfServices
	|		ON ImplementationOfServices.Ref = Adjusting.DocumentBasis
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND NOT T.CalculationOfCost
	|	AND (VALUETYPE(T.Recorder) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	// The adjustment of the sale of services of the previous year is reflected in the "Other income" register, and not in the "Other revenue" register.
	|		OR NOT ImplementationOfServices.Ref IS NULL
	|			AND BEGINOFPERIOD(Adjusting.Date, YEAR) = BEGINOFPERIOD(ImplementationOfServices.Date, YEAR)
	|		OR VALUETYPE(T.Recorder) = TYPE(Document.LoanAndDepositInterestCharge)
	|		)
	|;
	|SELECT
	|	""RevenueServicesAndAssets"" AS RegisterName,
	|	T.Recorder     AS Ref,
	|	T.Organization     AS Organization,
	|	1                 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	TTRegistrarsWithOtherIncome AS T
	|
	|UNION ALL
	|
	|SELECT
	|	""OtherIncome""  AS RegisterName,
	|	T.Recorder     AS Ref,
	|	T.Organization     AS Organization,
	|	1                 AS ErrorCode
	|FROM
	|	TTRegistrarsWithOtherIncome AS T
	|;
	|DROP TTRegistrarsWithOtherIncome
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'khôi phục các bản ghi kết chuyển theo biểu ghi ""Doanh thu khác""';
			|ru = 'восстановление движений по регистру ""Прочая выручка""';
			|en = 'restore records through ""Revenue — Services and Assets"" register'; fa = 'restore records through ""Revenue — Services and Assets"" register';
			|it = 'recupero dei movimenti in base al registro ""Altre entrate""';
			|pl = 'przywrócenie przepływów wg rejestru ""Pozostały utarg""';
			|tr = '""diğer gelirler"" kaydındaki hareketlerin geri yüklenmesi'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region ItemisedExpensesLots
	
	// Reflection of articles with a variant of distribution of production costs in the register of accumulation of lots of other expenses.
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Việc phản ánh các dạng chi phí với phương án phân bổ ""Cho chi phí sản xuất"" trong biểu ghi ""Lô hàng có chi phí khác"" không tương ứng với chính sách kế toán của doanh nghiệp';
										|ru = 'Отражение статей с вариантом распределения ""На производственные затраты"" в регистре ""Партии прочих расходов"" не соответствует учетной политике организации';
										|en = 'Record items with allocation option ""For production costs"" in the ""Material overheads for allocation"" register does not correspond to the company accounting policy'; fa = 'Record items with allocation option ""For production costs"" in the ""Material overheads for allocation"" register does not correspond to the company accounting policy';
										|it = 'La riflessione delle voci con variante di distribuzione ""Per spese di produzione"" nel registro ""Lotti di altre spese"" non corrisponde alla politica contabile dell''azienda';
										|pl = 'Wyświetlenie pozycji z wariantem podziału ""Na koszty produkcji"" w rejestrze ""Partie innych rozchodów"" nie jest zgodna z polityką rachunkowości firmy';
										|tr = '""Üretim maliyetlerine"" tahsis seçeneğine sahip kalemlerin ""Diğer gider lotları"" kaydına yansıtılması iş yerinin muhasebe politikasına uygun değildir'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Việc phản ánh các dạng chi phí với phương án phân bổ ""Cho giá vốn hàng hóa"" trong biểu ghi ""Lô hàng có chi phí khác"" không tương ứng với chính sách kế toán của doanh nghiệp';
										|ru = 'Отражение статей с вариантом распределения ""На себестоимость товаров"" в регистре ""Партии прочих расходов"" не соответствует учетной политике организации';
										|en = 'Recording items with allocation option ""To inventory cost"" in the ""Material overheads for allocation"" register does not correspond to the company accounting policy'; fa = 'Recording items with allocation option ""To inventory cost"" in the ""Material overheads for allocation"" register does not correspond to the company accounting policy';
										|it = 'La riflessione delle voci con variante di distribuzione ""Per il prezzo di costo degli articoli"" nel registro ""Lotti di altre spese"" non corrisponde alla politica contabile dell''azienda';
										|pl = 'Wyświetlenie pozycji z wariantem podziału ""Na koszty własne towarów"" w rejestrze ""Partie innych rozchodów"" nie jest zgodna z polityką rachunkowości firmy';
										|tr = '""Stok maliyetine"" tahsis seçeneğine sahip kalemlerin ""Diğer gider lotları"" kaydına yansıtılması iş yerinin muhasebe politikasına uygun değildir'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(3, NStr("vi = 'Đối với các dạng có phương án phân bổ ""Phân bổ vào giá vốn hàng hóa"" không có bản ghi kết chuyển trong biểu ghi ""Lô hàng có chi phí khác"" đối với doanh nghiệp nộp thuế thu nhập bổ sung';
										|ru = 'Для статей с вариантом распределения ""На себестоимость товаров"" нет движений в регистре ""Партии прочих расходов"" для организации плательщика НДД';
										|en = 'For items with the ""To inventory cost"" allocation option, there are no records in the ""Material overheads for allocation"" register for the AIT payer company'; fa = 'For items with the ""To inventory cost"" allocation option, there are no records in the ""Material overheads for allocation"" register for the AIT payer company';
										|it = 'Для статей с вариантом распределения ""На себестоимость товаров"" нет движений в регистре ""Партии прочих расходов"" для организации плательщика НДД';
										|pl = 'For items with the ""To inventory cost"" allocation option, there are no records in the ""Material overheads for allocation"" register for the AIT payer company';
										|tr = '""Stok maliyetine"" dağıtım seçeneğine sahip kalemler için, EGV mükellefinin iş yerine ilişkin ""Diğer gider lotları"" kaydında herhangi bir hareket yoktur'", Common.DefaultLanguageCode()));
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query);
	
	Query.Text = TextOfArticleRequestWithSeparateConsiderationOfNDSInRegisterOfPartyOfOtherExpenses();
	ParametersOfSelectionOfDocumentsOfRequestOfArticleWithSeparateAccountingOfNDSInRegisterOfPartyOfOtherExpenses(Query);
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bản ghi kết chuyển không chính xác theo biểu ghi ""Lô hàng có chi phí khác""';
			|ru = 'некорректные движения по регистру ""Партии прочих расходов""';
			|en = 'incorrect records in the ""Material overheads for allocation"" register'; fa = 'incorrect records in the ""Material overheads for allocation"" register';
			|it = 'movimenti errati per il registro ""Lotti di altre spese""';
			|pl = 'niepoprawne ruchy według rejestru ""Partie innych rozchodów""';
			|tr = '""diğer gider lotları"" kaydındaki yanlış hareketler'", Common.DefaultLanguageCode()));
		
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Đã điền đối tượng phân tích kế toán mặt hàng trong biểu ghi ""Lô hàng có chi phí khác"".';
										|ru = 'Заполнена аналитика учета номенклатуры в регистре ""Партии прочих расходов"".';
										|en = 'Inventory location attributes are filled in the ""Material overheads for allocation"" register.'; fa = 'Inventory location attributes are filled in the ""Material overheads for allocation"" register.';
										|it = 'Compilata l''analitica di contabilità di nomenclatura nel registro ""Lotti di altre spese"".';
										|pl = 'Wypełniono analitykę ewidencji produktu w rejestrze ""Partie innych rozchodów"".';
										|tr = '""Diğer gider lotları"" kaydında muhasebe boyutu öğesi dolduruldu.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2, NStr("vi = 'Đã điền số tiền thuế GTGT trong các bản ghi kết chuyển với dấu hiệu Đảo ngược trong biểu ghi ""Lô hàng có chi phí khác"".';
										|ru = 'Заполнена сумма НДС в движениях с признаком Сторно в регистре ""Партии прочих расходов"".';
										|en = 'The VAT amount is filled in records with the Storno flag in the ""Material overheads for allocation"" register.'; fa = 'The VAT amount is filled in records with the Storno flag in the ""Material overheads for allocation"" register.';
										|it = 'Заполнена сумма НДС в движениях с признаком Сторно в регистре ""Партии прочих расходов"".';
										|pl = 'The VAT amount is filled in records with the Storno flag in the ""Material overheads for allocation"" register.';
										|tr = '""Diğer giderler kısmı"" kaydında Alacak işareti ile işlemlerdeki KDV miktarı doldurulmuştur.'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(3, NStr("vi = 'Đã tạo bản ghi kết chuyển theo biểu ghi ""Lô hàng chi phí khác"" đối với doanh nghiệp có phương thức đánh giá giá trị ""FIFO (đánh giá bình quân)"".';
										|ru = 'Сформированы движения по регистру ""Партии прочих расходов"" для организации с методом оценки стоимости ""ФИФО (взвешенная)"".';
										|en = 'The ""Material overheads for allocation"" register records are created for a company with the ""FIFO (weighted estimate)"" cost evaluation method.'; fa = 'The ""Material overheads for allocation"" register records are created for a company with the ""FIFO (weighted estimate)"" cost evaluation method.';
										|it = 'The ""Material overheads for allocation"" register records are created for a company with the ""FIFO (weighted estimate)"" cost evaluation method.';
										|pl = 'The ""Material overheads for allocation"" register records are created for a company with the ""FIFO (weighted estimate)"" cost evaluation method.';
										|tr = '""FIFO (ağırlıklı)"" maliyetlendirme yöntemine sahip bir iş yeri için ""Diğer giderler partisi"" kaydında oluşturulan hareketler.'", Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT
	|	""ItemisedExpensesLots"" AS RegisterName,
	|	T.Recorder     AS Ref,
	|	T.Organization     AS Organization,
	|	CASE WHEN T.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|		THEN 1
	|		ELSE 3
	|	END AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND (T.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|		OR T.Organization IN(&SFIFOOrganizationsWeighted))
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
	|	AND VALUETYPE(T.Recorder) <> TYPE(Document.PurchaseAdjustment)
	|	AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsWithoutRegisteredRecords)
	|
	|UNION ALL
	|
	|SELECT
	|	""ItemisedExpensesLots"" AS RegisterName,
	|	T.Recorder     AS Ref,
	|	T.Organization     AS Organization,
	|	2                 AS ErrorCode
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND T.ReversingEntry
	|	AND (T.VATLocal <> 0 OR T.VATManag <> 0)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'bản ghi kết chuyển không chính xác theo biểu ghi ""Lô hàng có chi phí khác""';
			|ru = 'некорректные движения по регистру ""Партии прочих расходов""';
			|en = 'incorrect records in the ""Material overheads for allocation"" register'; fa = 'incorrect records in the ""Material overheads for allocation"" register';
			|it = 'movimenti errati per il registro ""Lotti di altre spese""';
			|pl = 'niepoprawne ruchy według rejestru ""Partie innych rozchodów""';
			|tr = '""diğer gider lotları"" kaydındaki yanlış hareketler'", Common.DefaultLanguageCode()));
		
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query, ExistingTT);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, NewTT);
	
	#EndRegion
	
	#Region OtherExpenses
	
	// In the documents "Movement of other assets and liabilities for the operation of increasing assets by reducing expenses, incorrect movements were formed in the "Other expenses" register:
	// - there was: expenditure movement with positive amounts
	// - should be: incoming traffic with negative amounts
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1, NStr("vi = 'Đã tạo bản ghi kết chuyển sai theo biểu ghi ""Chi phí khác"".';
										|ru = 'Сформированы некорректные движения по регистру  ""Прочие расходы"".';
										|en = 'Generated records in the ""Other expenses"" register are incorrect.'; fa = 'Generated records in the ""Other expenses"" register are incorrect.';
										|it = 'Sono stati generate registrazioni non corrette in base al registro ""Altre uscite"".';
										|pl = 'Utworzono niepoprawne przepływy według rejestru ""Inne rozchody"".';
										|tr = '""Diğer giderler"" kaydında hatalı hareketler oluşturuldu.'", Common.DefaultLanguageCode()));;
	
	Query.Text = "
	|SELECT DISTINCT
	|	""OtherExpenses"" 		 AS RegisterName,
	|	T.Recorder 			 AS Ref,
	|	T.Organization 			 AS Organization,
	|	1 						 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN (&CompanyArray)
	|	AND T.Active
	|	AND T.Recorder REFS Document.MovementOfOtherAssetsAndLiabilities
	|	AND RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.RecordOfOtherAssetsLiabilities)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.Sum > 0 AND T.AmountExcludingVAT > 0
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển chứng từ theo biểu ghi ""Chi phí khác"".';
			|ru = 'исправление движений документов по регистру ""Прочие расходы"".';
			|en = 'correct document register records in the ""Other expenses"" register.'; fa = 'correct document register records in the ""Other expenses"" register.';
			|it = 'correzione delle registrazioni dei documenti in base al registro ""Altre uscite"".';
			|pl = 'korekta przepływów dokumentów według rejestru ""Inne rozchody"".';
			|tr = '""diğer giderler"" kaydındaki belge kayıtlarının düzeltilmesi.'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region InventoryCostsOfAmountInCustomsDeclarationsImport
	
	// In the documents of the Customs Declaration of Import, the cost calculation regulations
	// could have GENERATED Entries with an incomplete amount, the error was corrected as part of task 00-0054007
	// to restore the amounts of Entries, it is necessary to Reposting the documents
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1,
		NStr("vi = 'Số tiền trong bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa"" khác với biểu ghi ""Mua hàng""';
			|ru = 'Отличаются суммы в движениях по регистру ""Себестоимость товаров"" от регистра ""Закупки""';
			|en = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Purchases"" register records'; fa = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Purchases"" register records';
			|it = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Purchases"" register records';
			|pl = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Purchases"" register records';
			|tr = '""Stok maliyeti"" kayıtlarındaki hareketlerde yer alan tutarlar ""Satın almalar"" kayıtlarından farklıdır'",
			Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2,
		NStr("vi = 'Số tiền trong bản ghi kết chuyển theo biểu ghi ""Mua hàng"" khác với biểu ghi ""Giá vốn hàng hóa""';
			|ru = 'Отличаются суммы в движениях по регистру ""Закупки"" от регистра ""Себестоимость товаров""';
			|en = 'Amounts in the ""Purchases"" register records differ from amounts in the ""Inventory cost"" register records'; fa = 'Amounts in the ""Purchases"" register records differ from amounts in the ""Inventory cost"" register records';
			|it = 'Amounts in the ""Purchases"" register records differ from amounts in the ""Inventory cost"" register records';
			|pl = 'Amounts in the ""Purchases"" register records differ from amounts in the ""Inventory cost"" register records';
			|tr = '""Satın almalar"" kayıtlarındaki hareketlerde yer alan tutarlar ""Stok maliyeti"" kayıtlarından farklıdır'",
			Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(3,
		NStr("vi = 'Số tiền trong bản ghi kết chuyển theo biểu ghi ""Chênh lệch trong giá trị hàng hóa"" khác với biểu ghi ""Mua hàng""';
			|ru = 'Отличаются суммы в движения по регистру ""Отклонения в стоимости товаров"" от регистра ""Закупки""';
			|en = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Purchases"" register records'; fa = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Purchases"" register records';
			|it = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Purchases"" register records';
			|pl = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Purchases"" register records';
			|tr = '""Maliyet farkları"" kaydındaki hareketlerde yer alan tutarlar ""Satın alımlar"" kayıtlarından farklıdır'",
			Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT
	|	VZ.Recorder AS Recorder,
	|	VZ.Organization AS Organization,
	|	VZ.Products AS Products,
	|	VZ.Characteristic AS Characteristic,
	|	SUM(VZ.AddExpensesForGoods) AS AddExpensesForGoods,
	|	SUM(VZ.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
	|	SUM(VZ.AddExpensesLocal) AS AddExpensesLocal
	|INTO TTAmountsOfRegisteredRecordsOfCustomsDeclaration
	|FROM
	|	(SELECT
	|		InventoryCost.Organization AS Organization,
	|		InventoryCost.Recorder AS Recorder,
	|		InventoryCost.ItemsLocationAttributes.Products AS Products,
	|		InventoryCost.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		InventoryCost.AddExpensesForGoods AS AddExpensesForGoods,
	|		InventoryCost.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|		InventoryCost.AddExpensesLocal AS AddExpensesLocal
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|	WHERE
	|		InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND InventoryCost.Organization IN (&CompanyArray)
	|		AND InventoryCost.Active
	|		AND InventoryCost.Recorder REFS Document.CCDImport
	|		AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND NOT InventoryCost.EntryType = VALUE(Enum.LotRecordTypes.IncludeExciseInCost)
	|		AND NOT InventoryCost.LotCalculation
	|		AND NOT InventoryCost.CalculationOfCost
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsCostVariances.Organization AS Organization,
	|		GoodsCostVariances.Recorder AS Recorder,
	|		GoodsCostVariances.Products AS Products,
	|		GoodsCostVariances.Characteristic AS Characteristic,
	|		GoodsCostVariances.CostVariancesIncludingVAT AS AddExpensesForGoods,
	|		GoodsCostVariances.CostVariancesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|		GoodsCostVariances.CostVariancesLocal
	|			+ GoodsCostVariances.VATLocal AS AddExpensesLocal
	|	FROM
	|		AccumulationRegister.GoodsCostVariances AS GoodsCostVariances
	|	WHERE
	|		GoodsCostVariances.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND GoodsCostVariances.Organization IN (&CompanyArray)
	|		AND GoodsCostVariances.Active
	|		AND GoodsCostVariances.Recorder REFS Document.CCDImport
	|		AND GoodsCostVariances.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Purchases.Organization,
	|		Purchases.Recorder,
	|		Purchases.ItemsLocationAttributes.Products,
	|		Purchases.ItemsLocationAttributes.Characteristic,
	|		-Purchases.Sum AS AddExpensesForGoods,
	|		-Purchases.AmountExcludingVAT AS AdditionalExpensesExcludingVAT,
	|		-Purchases.LocalCost AS AddExpensesLocal
	|	FROM
	|		AccumulationRegister.Purchases AS Purchases
	|	WHERE
	|		Purchases.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Purchases.Organization IN (&CompanyArray)
	|		AND Purchases.Active
	|		AND Purchases.Recorder REFS Document.CCDImport
	|) AS VZ
	|GROUP BY
	|	VZ.Recorder,
	|	VZ.Products,
	|	VZ.Organization,
	|	VZ.Characteristic
	|HAVING
	|	(SUM(VZ.AddExpensesForGoods) <> 0
	|	OR SUM(VZ.AdditionalExpensesExcludingVAT) <> 0
	|	OR SUM(VZ.AddExpensesLocal) <> 0)
	|;
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	TTAmountsOfRegisteredRecordsOfCustomsDeclaration AS T
	|WHERE
	|	NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""Purchases"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	2 AS ErrorCode
	|FROM
	|	TTAmountsOfRegisteredRecordsOfCustomsDeclaration AS T
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""GoodsCostVariances"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	3 AS ErrorCode
	|FROM
	|	TTAmountsOfRegisteredRecordsOfCustomsDeclaration AS T
	|WHERE
	|	T.Organization IN (&MediumSlipOrganizations)
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển của chứng từ ""Tờ khai hải quan nhập khẩu"" theo biểu ghi ""Giá vốn hàng hóa"" và ""Mua hàng"".';
			|ru = 'исправление движений документа ""Таможенная декларация на импорт"" по регистрам ""Себестоимость товаров"" и ""Закупки"".';
			|en = 'correct register records of the ""Customs import declaration"" document by the ""Inventory cost"" and ""Purchases"" registers.'; fa = 'correct register records of the ""Customs import declaration"" document by the ""Inventory cost"" and ""Purchases"" registers.';
			|it = 'correct register records of the ""Customs import declaration"" document by the ""Inventory cost"" and ""Purchases"" registers.';
			|pl = 'correct register records of the ""Customs import declaration"" document by the ""Inventory cost"" and ""Purchases"" registers.';
			|tr = '""Stok maliyeti"" ve ""satın almalar"" kayıtlarında ""İthal Gümrük Beyannamesi"" belgesinin hareketlerinin düzeltilmesi.'",
			Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region InventoryCostsOfAmountOfRegisteredRecordsOfExciseTaxes
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1,
		NStr("vi = 'Số tiền trong bản ghi kết chuyển theo biểu ghi ""Giá vốn hàng hóa"" khác với biểu ghi ""Biến động theo thuế TTĐB""';
			|ru = 'Отличаются суммы в движениях по регистру ""Себестоимость товаров"" от регистра ""Движения по акцизам""';
			|en = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Register records by excises"" register records'; fa = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Register records by excises"" register records';
			|it = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Register records by excises"" register records';
			|pl = 'Amounts in the ""Inventory cost"" register records differ from amounts in the ""Register records by excises"" register records';
			|tr = '""Stok maliyeti"" kayıtlarındaki hareketlerde yer alan tutarlar ""Tüketim vergisi hareketleri"" kayıtlarından farklıdır'",
			Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2,
		NStr("vi = 'Số tiền trong bản ghi kết chuyển theo biểu ghi ""Chênh lệch trong giá trị hàng hóa"" khác với biểu ghi ""Biến động theo thuế TTĐB""';
			|ru = 'Отличаются суммы в движения по регистру ""Отклонения в стоимости товаров"" от регистра ""Движения по акцизам""';
			|en = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Register records by excises"" register records'; fa = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Register records by excises"" register records';
			|it = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Register records by excises"" register records';
			|pl = 'Amounts in the ""Goods cost variances"" register records differ from amounts in the ""Register records by excises"" register records';
			|tr = '""Maliyet farkları"" kaydındaki hareketlerde yer alan tutarlar ""Tüketim vergisi hareketleri"" kayıtlarından farklıdır'",
			Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT
	|	T.Recorder AS Recorder,
	|	T.Organization AS Organization,
	|	T.Products AS Products,
	|	T.FinRecordID,
	|	T.BusinessTransactionSetting,
	|	SUM(T.AddExpensesLocal) AS AddExpensesLocal,
	|	SUM(T.AddExpensesMan) AS AddExpensesMan
	|INTO TTAmountsOfRegisteredRecordedExciseTaxes
	|FROM
	|	(SELECT
	|		InventoryCost.Organization AS Organization,
	|		InventoryCost.Recorder AS Recorder,
	|		InventoryCost.ItemsLocationAttributes.Products AS Products,
	|		InventoryCost.FinRecordID,
	|		InventoryCost.BusinessTransactionSetting,
	|		InventoryCost.AddExpensesLocal AS AddExpensesLocal,
	|		InventoryCost.AddExpensesMan AS AddExpensesMan
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|	WHERE
	|		InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND InventoryCost.Organization IN (&CompanyArray)
	|		AND InventoryCost.Active
	|		AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND InventoryCost.EntryType = VALUE(Enum.LotRecordTypes.IncludeExciseInCost)
	|		AND NOT InventoryCost.LotCalculation
	|		AND NOT InventoryCost.CalculationOfCost
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsCostVariances.Organization AS Organization,
	|		GoodsCostVariances.Recorder AS Recorder,
	|		GoodsCostVariances.Products AS Products,
	|		GoodsCostVariances.FinRecordID,
	|		GoodsCostVariances.BusinessTransactionSetting,
	|		GoodsCostVariances.CostVariancesLocal AS AddExpensesLocal,
	|		GoodsCostVariances.CostVariancesMgmt AS AddExpensesMan
	|	FROM
	|		AccumulationRegister.GoodsCostVariances AS GoodsCostVariances
	|	WHERE
	|		GoodsCostVariances.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND GoodsCostVariances.Organization IN (&CompanyArray)
	|		AND GoodsCostVariances.Active
	|		AND GoodsCostVariances.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|	UNION ALL
	|
	|	SELECT
	|		RegisterRecordsByExcises.Organization,
	|		RegisterRecordsByExcises.Recorder,
	|		RegisterRecordsByExcises.Products,
	|		RegisterRecordsByExcises.FinRecordID,
	|		RegisterRecordsByExcises.BusinessTransactionSetting,
	|		-RegisterRecordsByExcises.ExciseAmountInCurrencyLocal AS AddExpensesLocal,
	|		-RegisterRecordsByExcises.ExciseAmountInCurrencyLocal AS AddExpensesMan
	|	FROM
	|		AccumulationRegister.RegisterRecordsByExcises AS RegisterRecordsByExcises
	|	WHERE
	|		RegisterRecordsByExcises.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND RegisterRecordsByExcises.Organization IN (&CompanyArray)
	|		AND RegisterRecordsByExcises.Active
	|		AND RegisterRecordsByExcises.KindOfTransactionWithExcisableGoods IN (
	|			VALUE(Enum.KindsOfTransactionsWithExcisableGoods.PurchaseEAEU),
	|			VALUE(Enum.KindsOfTransactionsWithExcisableGoods.Import))
	|) AS T
	|GROUP BY
	|	T.Recorder,
	|	T.Products,
	|	T.Organization,
	|	T.FinRecordID,
	|	T.BusinessTransactionSetting
	|HAVING
	|	(SUM(T.AddExpensesLocal) < 0
	|	OR SUM(T.AddExpensesMan) < 0)
	|;
	|SELECT DISTINCT
	|	""InventoryCost"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	TTAmountsOfRegisteredRecordsOfCustomsDeclaration AS T
	|WHERE
	|	NOT T.Organization IN (&MediumSlipOrganizations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	""GoodsCostVariances"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	2 AS ErrorCode
	|FROM
	|	TTAmountsOfRegisteredRecordsOfCustomsDeclaration AS T
	|WHERE
	|	T.Organization IN (&MediumSlipOrganizations)
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'điều chỉnh bản ghi kết chuyển với số tiền thuế TTĐB theo biểu ghi ""Giá vốn hàng hóa"".';
			|ru = 'исправление движений на сумму акциза по регистру ""Себестоимость товаров"".';
			|en = 'correct records for the excise amount in the ""Inventory cost"" register.'; fa = 'correct records for the excise amount in the ""Inventory cost"" register.';
			|it = 'correct records for the excise amount in the ""Inventory cost"" register.';
			|pl = 'correct records for the excise amount in the ""Inventory cost"" register.';
			|tr = '""Stok maliyeti"" kaydındaki tüketim vergisi tutarı hareketlerinin düzeltilmesi.'",
			Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region AllocationOfOtherCosts
	
	// In the closing period there should not be 2 documents on TA and Local Accounting with Similar Analysts
	// If there are such documents, we mark one for deletion, put 2 check marks on the second one.
	Query.Text = "SELECT
	|	AllocationOfOtherCosts.Organization AS Organization,
	|	AllocationOfOtherCosts.Department AS Department,
	|	AllocationOfOtherCosts.ExpenseItem AS ExpenseItem,
	|	AllocationOfOtherCosts.DimensionOfExpenses AS DimensionOfExpenses,
	|	COUNT(AllocationOfOtherCosts.Ref) AS DocumentsCount,
	|	MAX(AllocationOfOtherCosts.ManagementAccounting) AS ManagementAccounting,
	|	MAX(AllocationOfOtherCosts.AIT) AS AIT,
	|	MAX(AllocationOfOtherCosts.LocalAccounting) AS LocalAccounting,
	|	MAX(AllocationOfOtherCosts.TaxAccounting) AS TaxAccounting,
	|	BEGINOFPERIOD(AllocationOfOtherCosts.Date, MONTH) AS MonthOfExpenditure,
	|	AllocationOfOtherCosts.LineOfBusiness AS LineOfBusiness,
	|	MAX(CASE
	|		WHEN AllocationOfOtherCosts.LocalAccounting
	|			THEN AllocationOfOtherCosts.Ref
	|		ELSE UNDEFINED
	|	END) AS DocumentForConducting
	|INTO AttributesWITHDoubleDocuments
	|FROM
	|	Document.AllocationOfOtherCosts AS AllocationOfOtherCosts
	|	LEFT JOIN Catalog.CostCenters AS ConstCenter
	|		ON ConstCenter.Ref = AllocationOfOtherCosts.DimensionOfExpenses
	|WHERE
	|	AllocationOfOtherCosts.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND AllocationOfOtherCosts.Organization IN (&CompanyArray)
	|	AND AllocationOfOtherCosts.Posted
	|	AND (AllocationOfOtherCosts.LocalAccounting OR AllocationOfOtherCosts.TaxAccounting)
	|	AND (AllocationOfOtherCosts.ExpenseItem.CostAllocationOptionLocal = AllocationOfOtherCosts.ExpenseItem.CostAllocationOptionTax
	|		OR ConstCenter.CostAllocationOptionLocal = ConstCenter.CostAllocationOptionTax
	|		)
	|GROUP BY
	|	AllocationOfOtherCosts.Organization,
	|	AllocationOfOtherCosts.Department,
	|	AllocationOfOtherCosts.ExpenseItem,
	|	AllocationOfOtherCosts.DimensionOfExpenses,
	|	BEGINOFPERIOD(AllocationOfOtherCosts.Date, MONTH),
	|	AllocationOfOtherCosts.LineOfBusiness
	|HAVING
	|	COUNT(AllocationOfOtherCosts.Ref) > 1
	|	AND MAX(AllocationOfOtherCosts.LocalAccounting)
	|	AND MAX(AllocationOfOtherCosts.TaxAccounting)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AttributesWITHDoubleDocuments.DocumentForConducting AS DocumentForConducting,
	|	AttributesWITHDoubleDocuments.ManagementAccounting AS ManagementAccounting,
	|	AttributesWITHDoubleDocuments.AIT AS AIT
	|FROM
	|	AttributesWITHDoubleDocuments AS AttributesWITHDoubleDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllocationOfOtherCosts.Ref AS DocumentToMarkForDeletion
	|FROM
	|	AttributesWITHDoubleDocuments AS AttributesWITHDoubleDocuments
	|		INNER JOIN Document.AllocationOfOtherCosts AS AllocationOfOtherCosts
	|		ON AttributesWITHDoubleDocuments.Organization = AllocationOfOtherCosts.Organization
	|		AND AttributesWITHDoubleDocuments.Department = AllocationOfOtherCosts.Department
	|		AND AttributesWITHDoubleDocuments.ExpenseItem = AllocationOfOtherCosts.ExpenseItem
	|		AND AttributesWITHDoubleDocuments.DimensionOfExpenses = AllocationOfOtherCosts.DimensionOfExpenses
	|		AND (AllocationOfOtherCosts.LocalAccounting
	|		OR AllocationOfOtherCosts.TaxAccounting)
	|		AND AttributesWITHDoubleDocuments.LineOfBusiness = AllocationOfOtherCosts.LineOfBusiness
	|		AND AttributesWITHDoubleDocuments.DocumentForConducting <> AllocationOfOtherCosts.Ref
	|		AND AllocationOfOtherCosts.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND AllocationOfOtherCosts.Posted";
	
	RequestResultPackage = Query.ExecuteBatch();
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("Document.AllocationOfOtherCosts");
		LockItem.DataSource = RequestResultPackage[1];
		LockItem.UseFromDataSource("Ref", "DocumentForConducting");
		Block.Lock();
		
		Block = New DataLock;
		LockItem = Block.Add("Document.AllocationOfOtherCosts");
		LockItem.DataSource = RequestResultPackage[2];
		LockItem.UseFromDataSource("Ref", "DocumentToMarkForDeletion");
		Block.Lock();  
		
		DocumentsToPost = RequestResultPackage[1].Select();
		DocumentsToBeSubmittedForDeletion = RequestResultPackage[2].Select();
		
		While DocumentsToBeSubmittedForDeletion.Next() Do
			DocumentObject = DocumentsToBeSubmittedForDeletion.DocumentToMarkForDeletion.GetObject();
			DocumentObject.AdditionalProperties.Insert("CancelRecordingOfTaskForCalculatingCost", True);
			DocumentObject.DeletionMark = True;
			DocumentObject.Write(DocumentWriteMode.UndoPosting);
		EndDo;
		
		While DocumentsToPost.Next() Do
			DocumentObject = DocumentsToPost.DocumentForConducting.GetObject();
			DocumentObject.ManagementAccounting = DocumentsToPost.ManagementAccounting;
			DocumentObject.AIT = DocumentsToPost.AIT;
			DocumentObject.TaxAccounting = True;
			DocumentObject.DataExchange.Load = True;
			DocumentObject.Write();
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể chỉnh sửa chứng từ phân bổ chi phí khác theo nguyên nhân: 
				|%1';
				|ru = 'Не удалось исправить документы распределения прочих затрат по причине:
				|%1';
				|en = 'Cannot correct the documents of other cost allocation due to:
				|%1'; fa = 'Cannot correct the documents of other cost allocation due to:
				|%1';
				|it = 'Не удалось исправить документы распределения прочих затрат по причине:
				|%1';
				|pl = 'Cannot correct the documents of other cost allocation due to:
				|%1';
				|tr = 'Diğer maliyet tahsis belgelerinin aşağıdaki nedenlerle düzeltilememesi:
				|%1'", Common.DefaultLanguageCode()),
			DetailErrorDescription(ErrorInfo()));
		
		CostCalculationProtocol.FixCalculationError(
			CalculationParameters,
			Enums.TypesOfLotAccountingAndCostErrors.ErrorInSourceDataForCalculation,
			ProtocolText_);
		
		Raise CostCalculationAppliedAlgorithms.TextExceptionToLogProblem(
			ProtocolText_);
		
	EndTry;
	
	#EndRegion
	
	#Region RevenueAndCostOfGoodsSoldDoublingNumberOfVDInSales
	
	// In the documents of the return of the client's goods, the cost calculation regulations, the stage of
	// filling the party in the register of the Sales register and the sale Accumulation register adds to the revenue register and the sale price movement without a batch and with a double, affected, etc. quantity
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1,
		NStr("vi = 'Đã tạo các bản ghi sai theo biểu ghi ""Doanh thu và giá vốn hàng bán"", đã tìm thấy chênh lệch theo số lượng với biểu ghi ""Giá vốn hàng bán""';
			|ru = 'Сформированы некорректные движения по регистру ""Выручка и себестоимость продаж"", найдены расхождения по количеству с регистром ""Себестоимость товаров""';
			|en = 'Incorrect ""Revenue and COGS"" register records are generated. Discrepancies in quantity with the ""Inventory cost"" register are found'; fa = 'Incorrect ""Revenue and COGS"" register records are generated. Discrepancies in quantity with the ""Inventory cost"" register are found';
			|it = 'Сформированы некорректные движения по регистру ""Выручка и себестоимость продаж"", найдены расхождения по количеству с регистром ""Себестоимость товаров""';
			|pl = 'Incorrect ""Revenue and COGS"" register records are generated. Discrepancies in quantity with the ""Inventory cost"" register are found';
			|tr = '""Satış geliri ve maliyeti"" kaydında hatalı hareketler oluşturuldu, ""Stok maliyeti"" kaydıyla miktar olarak tutarsızlıklar bulundu'",
			Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT
	|	VZ.Organization AS Organization,
	|	VZ.Recorder AS Recorder,
	|	VZ.Products AS Products,
	|	VZ.BusinessOperation AS BusinessOperation,
	|	SUM(VZ.Count) AS Count
	|INTO TTRecordersWithErrorsInNumber
	|FROM
	|	(SELECT
	|		T.AccountingDimensionByPartners.Organization AS Organization,
	|		T.Recorder AS Recorder,
	|		T.ItemsLocationAttributes.Products AS Products,
	|		T.BusinessOperation AS BusinessOperation,
	// The amount of this type of return, in movements, is negative
	|		T.Count AS Count
	|	FROM
	|		AccumulationRegister.RevenueAndCOGS AS T
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
	|		ON T.AccountingDimensionByPartners = Analysts.Ref
	|	WHERE
	|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Analysts.Organization IN(&CompanyArray)
	|		AND T.Recorder REFS Document.ReturnOfGoodsFromCustomer 
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	// The service is not displayed in the cost price, so we exclude it from the revenue and cost of sales 
	|		AND T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
	// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
	// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
	|		AND NOT Analysts.Organization IN (&MediumSlipOrganizations)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.Organization,
	|		T.Recorder,
	|		CatProducts.Ref AS Products,
	|		T.BusinessOperation,
	|		T.Count
	|	FROM
	|		TTMovementCostOfGoods AS T
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CatInventoryLocationAttributeKeys
	|		ON (CatInventoryLocationAttributeKeys.Ref = T.ItemsLocationAttributes)
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorKeysForItemAccountingAnalytics
	|		ON (CorKeysForItemAccountingAnalytics.Ref = T.CorItemsLocationAttributes)
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON (ISNULL(CorKeysForItemAccountingAnalytics.Products, CatInventoryLocationAttributeKeys.Products) = CatProducts.Ref)
	|	WHERE
	|		T.Recorder REFS Document.ReturnOfGoodsFromCustomer
	// Multi-turn packaging is not reflected in revenue if the return of multi-turn packaging is reflected, therefore we exclude it from the cost of goods
	// The return of a multi-turn container has an economic operation of "Reversed packaging" or "Return of packaging from a customer of previous periods", therefore the condition below excludes it
	|		AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	) AS VZ
	|
	|GROUP BY
	|	VZ.Organization,
	|	VZ.Recorder,
	|	VZ.Products,
	|	VZ.BusinessOperation
	|	
	|HAVING SUM(VZ.Count) <> 0
	|;
	|
	|SELECT DISTINCT
	|	""RevenueAndCOGS"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	TTRecordersWithErrorsInNumber AS T
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển theo biểu ghi ""Doanh thu và giá vốn hàng bán"".';
			|ru = 'исправление движений документов по регистру ""Выручка и себестоимость продаж"".';
			|en = 'correction of document records in the ""Revenue and COGS"" register.'; fa = 'correction of document records in the ""Revenue and COGS"" register.';
			|it = 'исправление движений документов по регистру ""Выручка и себестоимость продаж"".';
			|pl = 'correction of document records in the ""Revenue and COGS"" register.';
			|tr = '""Satış geliri ve maliyeti"" kaydındaki belge kayıtlarının düzeltilmesi.'",
			Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region GoodsCostVariances
	
	DecodingErrorCodes = New Map;
	DecodingErrorCodes.Insert(1,
		NStr("vi = 'Đã tạo bản ghi kết chuyển sai theo biểu ghi ""Chênh lệch trong giá trị hàng hóa""';
			|ru = 'Сформированы некорректные движения по регистру ""Отклонения в стоимости товаров""';
			|en = 'Incorrect records are created in the ""Goods cost variances"" register'; fa = 'Incorrect records are created in the ""Goods cost variances"" register';
			|it = 'Incorrect records are created in the ""Goods cost variances"" register';
			|pl = 'Incorrect records are created in the ""Goods cost variances"" register';
			|tr = '""Ürün maliyetindeki sapmalar"" kaydındaki hareketler yanlış oluşturulmuş'", Common.DefaultLanguageCode()));
	DecodingErrorCodes.Insert(2,
		NStr("vi = 'Bản ghi kết chuyển theo biểu ghi ""Chênh lệch trong giá trị hàng hóa"" không cần thiết đối với chính sách kế toán được sử dụng';
			|ru = 'Движения по регистру ""Отклонения в стоимости товаров"" не требуются для используемой учетной политики';
			|en = 'The accounting policy does not require the ""Goods cost variances"" register records'; fa = 'The accounting policy does not require the ""Goods cost variances"" register records';
			|it = 'The accounting policy does not require the ""Goods cost variances"" register records';
			|pl = 'The accounting policy does not require the ""Goods cost variances"" register records';
			|tr = '""Ürün maliyetindeki farklar"" kaydındaki hareketler, kullanımdaki muhasebe politikası için gerekli değildir'", Common.DefaultLanguageCode()));
	
	Query.Text = "
	|SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.Organization.ParentCompany AS ParentCompany,
	|	T.Recorder AS Recorder
	|INTO TTRecordersWithDeviations
	|FROM
	|	AccumulationRegister.GoodsCostVariances AS T
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND NOT T.Recorder REFS Document.RegisterAdjustment
	|
	|INDEX BY
	|	ParentCompany
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	T.Organization AS Organization,
	|	T.Recorder AS Recorder,
	|	(AccountingPolicy.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)) AS MovingAverage,
	|	AccountingPolicy.ItemizeVariancesByLinesOfBusiness,
	|	AccountingPolicy.ItemizeVariancesByBusinessUnits,
	|	AccountingPolicy.ItemizeVariancesByWarehousesStorageLocations
	|INTO TTRecordersWithDeviationsAndAccountingPolicies
	|FROM
	|	TTRecordersWithDeviations AS T
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&BeginOfPeriod, Organization IN(&CompanyArray)) AS AccountingPolicy
	|		ON T.ParentCompany = AccountingPolicy.Organization
	|
	|INDEX BY
	|	Recorder
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|
	// The conditions for filling in the fields must match the text of the request in the calculation of the highest value of the documents.Add a Text request to bow down to the value of products
	|SELECT DISTINCT
	|	T.Period 										AS Period,
	|	T.Recorder 									AS Recorder,
	|	T.Organization 									AS Organization,
	|	T.ItemsLocationAttributes.Products		AS Products,
	|	T.ItemsLocationAttributes.Characteristic		AS Characteristic,
	|	T.InventoryOwnerAttribute 									AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN NOT Recorders.ItemizeVariancesByLinesOfBusiness
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			ELSE ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END											AS LineOfBusiness,
	|	CASE
	|		WHEN NOT Recorders.ItemizeVariancesByBusinessUnits
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN T.ItemsLocationAttributes.StorageLocation
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
	|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
	|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END 											AS Department,
	|	CASE
	|		WHEN NOT Recorders.ItemizeVariancesByWarehousesStorageLocations
	|			THEN UNDEFINED
	|			ELSE T.ItemsLocationAttributes.StorageLocation
	|	END											AS StorageLocation
	|INTO TTOfCostRegisterRecordedForDeviations
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN TTRecordersWithDeviationsAndAccountingPolicies AS Recorders
	|		ON T.Recorder = Recorders.Recorder
	|		AND Recorders.MovingAverage
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|
	|INDEX BY
	|	Products,
	|	Period,
	|	Recorder
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|
	// The Registered Records of the registrar at cost do not correspond to its Registered Records for deviations
	|SELECT DISTINCT
	|	""GoodsCostVariances"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	1 AS ErrorCode
	|INTO TTRecordersWithIncorrectRegisteredRecords
	|FROM
	|	AccumulationRegister.GoodsCostVariances AS T
	|	INNER JOIN TTRecordersWithDeviationsAndAccountingPolicies AS Recorders
	|		ON T.Recorder = Recorders.Recorder
	|		AND Recorders.MovingAverage
	|	LEFT JOIN TTOfCostRegisterRecordedForDeviations AS Cost_
	|		ON T.Products = Cost_.Products
	|		AND T.Period = Cost_.Period
	|		AND T.Recorder = Cost_.Recorder
	|		AND T.Organization = Cost_.Organization
	|		AND T.Characteristic = Cost_.Characteristic
	|		AND T.InventoryOwnerAttribute = Cost_.InventoryOwnerAttribute
	|		AND T.LineOfBusiness = Cost_.LineOfBusiness
	|		AND T.Department = Cost_.Department
	|		AND T.StorageLocation = Cost_.StorageLocation
	|WHERE
	|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND T.Organization IN(&CompanyArray)
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND Cost_.Recorder IS NULL
	|
	|UNION ALL
	|
	// There is a Registered Record of deviations in the cost estimation method other than the sliding average
	|SELECT
	|	""GoodsCostVariances"" AS RegisterName,
	|	T.Recorder AS Ref,
	|	T.Organization AS Organization,
	|	2 AS ErrorCode
	|FROM
	|	TTRecordersWithDeviationsAndAccountingPolicies AS T
	|WHERE
	|	NOT T.MovingAverage
	|";
	
	CostCalculationAppliedAlgorithms.RecheckDocumentsForIndividualAccumulationRegisters(
		CalculationParameters,
		Query,
		DecodingErrorCodes,
		NStr("vi = 'chỉnh sửa bản ghi kết chuyển của chứng từ theo biểu ghi ""Chênh lệch trong giá trị hàng hóa"".';
			|ru = 'исправление движений документов по регистру ""Отклонения в стоимости товаров"".';
			|en = 'Adjusting document records in the ""Goods cost variances"" register.'; fa = 'Adjusting document records in the ""Goods cost variances"" register.';
			|it = 'Adjusting document records in the ""Goods cost variances"" register.';
			|pl = 'Adjusting document records in the ""Goods cost variances"" register.';
			|tr = '""Ürün maliyetindeki farklar"" kaydındaki belge kayıtlarının düzeltilmesi.'",
			Common.DefaultLanguageCode()));
	
	#EndRegion
	
	CostCalculationDataPreparationLocalization.FixProblemsInRegisteredRecordsAndDocuments(CalculationParameters);
	
	TTStage = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query, ExistingTtToStage);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, TTStage);
	
EndProcedure

Function TextOfArticleRequestWithSeparateConsiderationOfNDSInRegisterOfPartyOfOtherExpenses() Export
	Return
		"SELECT
		|	T.Ref 							 AS Ref,
		|	T.Organization 						 AS Organization,
		|	T.Department 					 AS Department,
		|	T.LineOfBusiness 			 AS LineOfBusiness,
		|	T.ExpenseItem 					 AS ExpenseItem,
		|	T.DimensionOfExpenses					 AS DimensionOfExpenses,
		|	MAX(T.ThereAreOtherExpenses) 		 AS ThereAreOtherExpenses,
		|	MAX(T.ThereAreLotsOfOtherExpenses) AS ThereAreLotsOfOtherExpenses
		|INTO TTMovement
		|FROM
		|	(SELECT DISTINCT
		|		T.Recorder AS Ref,
		|		T.Organization AS Organization,
		|		T.Department AS Department,
		|		T.LineOfBusiness AS LineOfBusiness,
		|		T.ExpenseItem AS ExpenseItem,
		|		T.DimensionOfExpenses	AS DimensionOfExpenses,
		|		TRUE AS ThereAreOtherExpenses,
		|		FALSE AS ThereAreLotsOfOtherExpenses
		|	FROM
		|		AccumulationRegister.OtherExpenses AS T
		|			INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|			ON AssetRef.Ref = T.ExpenseItem
		|
		|		LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
		|			ON DocumentReversingEntry.Ref = T.Recorder
		|	WHERE
		|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND T.Organization IN(&CompanyArray)
		// The condition for selecting records must match the functions:
		// See AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses()
		// See VATAccountingERP.ReflectPurchaseFromSupplier()
		// See BatchAccountingServer.TextsOfCancellationRequests()
		|		AND (
		|			(AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|				OR AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			AND (T.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|				OR T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
		|				OR T.Organization IN (&OrganizationsWithDetailedMaterialAndItemByItemCosts))
		|			)
		|		  )
		// We exclude the verification of movements on the transfer of expenses between organizations in the upr. accounting.
		|		AND NOT T.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.ExpenseReversalInManAccounting),
		|			VALUE(Enum.BusinessTransactions.ExpenseRegistrationInManAccounting))
		// We exclude the write-off of products for expenses at the planned cost
		|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
		|		AND NOT T.LotCalculation
		|		AND NOT T.CalculationOfCost
		|		AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
		|		AND NOT VALUETYPE(DocumentReversingEntry.ReversedDocument) IN (&TypesOfDocumentsAboutSiIa)
		|		AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
		|		AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsWithoutRegisteredRecords)
		|	
		|	UNION ALL
		|	
		|	SELECT DISTINCT
		|		T.Recorder,
		|		T.Organization,
		|		T.Department,
		|		T.LineOfBusiness,
		|		T.ExpenseItem,
		|		T.DimensionOfExpenses,
		|		FALSE,
		|		TRUE
		|	FROM
		|		AccumulationRegister.ItemisedExpensesLots AS T
		|			INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|			ON AssetRef.Ref = T.ExpenseItem
		|
		|		LEFT JOIN Document.ReversingEntry AS DocumentReversingEntry
		|			ON DocumentReversingEntry.Ref = T.Recorder
		|	WHERE
		|		T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND T.Organization IN(&CompanyArray)
		// The condition for selecting records must correspond to the function:
		// Accumulation registers.Lots of other expenses.The text of the request for the table of the Party and other expenses()
		|		AND (
		|			(AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|				OR AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			AND (T.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|				OR T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
		|				OR T.Organization IN (&OrganizationsWithDetailedMaterialAndItemByItemCosts))
		|			)
		|		  )
		// We exclude the verification of movements on the transfer of expenses between organizations in the upr. accounting.
		|		AND NOT T.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.ExpenseReversalInManAccounting),
		|			VALUE(Enum.BusinessTransactions.ExpenseRegistrationInManAccounting))
		// We exclude the write-off of products for expenses at the planned cost
		|		AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
		|		AND NOT T.LotCalculation
		|		AND NOT T.CalculationOfCost
		|		AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsAboutSiIa)
		|		AND NOT VALUETYPE(DocumentReversingEntry.ReversedDocument) IN (&TypesOfDocumentsAboutSiIa)
		|		AND NOT VALUETYPE(T.Recorder) IN (&TypesOfRegulatoryDocuments)
		|		AND NOT VALUETYPE(T.Recorder) IN (&TypesOfDocumentsWithoutRegisteredRecords)
		|	) AS T
		|
		|GROUP BY
		|	T.Ref,
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|;
		|/////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	""ItemisedExpensesLots"" AS RegisterName,
		|	T.Ref 				 AS Ref,
		|	T.Organization 			 AS Organization,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		 OR AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			THEN (CASE
		|					WHEN 
		|					  FALSE
		|						THEN 3
		|					ELSE 2 END)
		|		ELSE 1 END)		 AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	TTMovement AS T
		|	INNER JOIN Catalog.Companies AS Companies
		|		ON T.Organization = Companies.Ref
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|		ON AssetRef.Ref = T.ExpenseItem
		|WHERE
		|	CASE
		|		WHEN (T.Organization IN (&OrganizationsIncludingVATLotsVersion22)
		|			OR T.Organization IN (&OrganizationsIncludingVATLotsVersion24)
		|			OR T.Organization IN (&OrganizationsWithDetailedMaterialAndItemByItemCosts))
		|		 AND (AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		 OR AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
		|			THEN T.ThereAreOtherExpenses AND NOT T.ThereAreLotsOfOtherExpenses
		|		ELSE T.ThereAreLotsOfOtherExpenses
		|	END
		|;
		|/////////////////////////////////////////////////////////////////////////////
		|
		|DROP TTMovement";
EndFunction

Procedure ParametersOfSelectionOfDocumentsOfRequestOfArticleWithSeparateAccountingOfNDSInRegisterOfPartyOfOtherExpenses(Query) Export
	
	// Types of documents that have movements only on one of the registers of the batch of other expenses or other expenses.
	TypesOfLoggers = New Array;
	
	For Each MetaDocument In Metadata.Documents Do
		If MetaDocument.RegisterRecords.Contains(Metadata.AccumulationRegisters.OtherExpenses) <>
		  MetaDocument.RegisterRecords.Contains(Metadata.AccumulationRegisters.ItemisedExpensesLots) Then
			TypesOfLoggers.Add(Type("DocumentRef." + MetaDocument.Name));
		EndIf;
	EndDo;
	
	TypesOfLoggers.Add(Type("DocumentRef.AllocationOfOtherCosts"));
	
	Query.SetParameter("TypesOfDocumentsWithoutRegisteredRecords", TypesOfLoggers);
	
EndProcedure

// Returns the text of the request for the formation of the movement of the value of the goods
//
// Returns:
//	String - Query text
//
Function QueryTextTTAverageCostOfGoods() Export
	Return
		"SELECT DISTINCT
		|	T.RecordType				 AS RecordType,
		|	T.Recorder 				 AS Recorder,
		|	T.Organization 				 AS Organization,
		|	T.CorCompany 			 AS CorCompany,
		|	T.Lot 	  				 AS Lot,
		|	T.CorLot 	  			 AS CorLot,
		|	T.BusinessOperation 	 AS BusinessOperation,
		|	T.EntryType					 AS EntryType,
		|	T.LotVendorAttributes		 AS LotVendorAttributes,
		|	T.LotVendorAttributesCorr	 AS LotVendorAttributesCorr,
		|	ARTICLES__.Ref				 AS ProductCostElement, 
		|	CorArticles.Ref			 AS CorCostElement, 
		|	T.AccountingSection				 AS AccountingSection,
		|	T.InventoryOwnerAttribute				 AS InventoryOwnerAttribute,
		|	T.CorInventoryOwnerAttribute				 AS CorInventoryOwnerAttribute,
		|	T.CorAccountingSection			 AS CorAccountingSection,
		|	T.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	T.CorItemsLocationAttributes	AS CorItemsLocationAttributes,
		|	T.FinancialAccountingDimension	AS FinancialAccountingDimension,
		|	T.CorControllingAttributes	AS CorControllingAttributes,
		|	T.VATActivityType		 AS VATActivityType,
		|	T.CorVATActivityTypes		 AS CorVATActivityTypes,
		|	T.DocumentVATActivityType AS DocumentVATActivityType,
		|	T.AccountingDimensionByPartners	 AS AccountingDimensionByPartners,
		|	T.ProductsGroup			 AS ProductsGroup,
		|	T.DocumentSource			 AS DocumentSource,
		|	T.SalesOrder				 AS SalesOrder,
		|	T.SalePeriod				 AS SalePeriod,
		|	T.ReversingEntry					 AS ReversingEntry,
		|	T.RowID		 AS RowID,
		|	T.FinRecordID	 AS FinRecordID,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.CostAccountingTransaction AS CostAccountingTransaction,
		|	T.CostDefiningMethod AS CostDefiningMethod,
		|	CASE WHEN T.Count > 0
		|		THEN TRUE
		|		ELSE FALSE
		|	END 						 AS PositiveQuantity,
		|	T.DocumentRegisterRecords			 AS DocumentRegisterRecords,
		|	T.VariancePeriod			 AS VariancePeriod,
		|	ISNULL(AccountingPoliciesOfFinancialAccounting.InventoryValuationMethod, UNDEFINED) AS InventoryValuationMethod,
		// Full-fledged accounting of finished products at the planned cost is maintained when deviations are written-off to the cost of sales,
		// except for the "Medium-sliding" valuation method. With an average sliding cost, products are always recorded at the planned cost.
		|	(CASE
		|		WHEN ISNULL(AccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost, FALSE)
		|		 AND ISNULL(AccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold, FALSE)
		|		 OR (ISNULL(AccountingPoliciesOfFinancialAccounting.InventoryValuationMethod, UNDEFINED)
		|				= VALUE(Enum.InventoryValuationMethods.MovingAverage))
		|			THEN TRUE
		|		ELSE FALSE END)		 AS ProductCostingByPlannedCost,
		|	T.CorGrossInitialCostENT				 AS CorGrossInitialCostENT,
		|	T.IncomeItem				 AS IncomeItem,
		|	T.Count				 AS Count,
		|	T.Cost					 AS Cost,
		|	T.OffBalanceCost		 AS OffBalanceCost,
		|	T.LocalCost				 AS LocalCost,
		|	T.VATLocal					 AS VATLocal,
		|	T.OffBalanceCostLocal	 AS OffBalanceCostLocal
		|INTO TTMovementCostOfGoods
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|		LEFT JOIN TTAccountingPoliciesOfFinancialAccounting AS AccountingPoliciesOfFinancialAccounting
		|			ON T.Organization = AccountingPoliciesOfFinancialAccounting.Organization
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
		|			ON T.ItemsLocationAttributes = DimensionOfProductItem.Ref
		|		LEFT JOIN Catalog.ProductCostElements AS ARTICLES__
		|			ON DimensionOfProductItem.ProductCostElement = ARTICLES__.Ref
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorAnalysisOfProducts
		|			ON T.CorItemsLocationAttributes = CorAnalysisOfProducts.Ref
		|		LEFT JOIN Catalog.ProductCostElements AS CorArticles
		|			ON CorAnalysisOfProducts.ProductCostElement = CorArticles.Ref
		|WHERE
		|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.Organization IN(&CompanyArray)
		// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
		// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
		|	AND NOT T.Organization IN (&MediumSlipOrganizations)
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|	AND NOT VALUETYPE(T.Recorder) IN (TYPE(Document.InventoryCostCalculation),
		|									TYPE(Document.CalculationOfInventoryImpairmentProvision),
		|									TYPE(Document.RegisterAdjustment))
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Recorder,
		|	T.DocumentSource,
		|	T.Organization
		|INTO TTDocumentsSourcesFromCostPrice
		|FROM 
		|	TTMovementCostOfGoods AS T
		|WHERE
		|	T.DocumentSource <> UNDEFINED
		|INDEX BY
		|	DocumentSource
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Recorder,
		|	T.DocumentSource,
		|	T.Organization AS Organization,
		|	Register3.IBDocumentDate AS Date
		|INTO TTDocumentsSourcesFromCostPriceWithDates
		|FROM 
		|	TTDocumentsSourcesFromCostPrice AS T
		|	INNER JOIN InformationRegister.DocumentsRegistry AS Register3
		|		ON T.DocumentSource = Register3.Ref
		|		AND NOT Register3.AdditionalRecord
		|INDEX BY
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Recorder,
		|	T.DocumentSource,
		|	T.Organization AS Organization,
		|	T.Date,
		|	MAX(AccountingPolicy.Period) AS PolicyPeriod
		|INTO TTDocumentsAreSourcesFromCostPriceWithDatesAndPeriodsOfPolicies
		|FROM 
		|	TTDocumentsSourcesFromCostPriceWithDates AS T
		|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
		|		ON T.Organization = AccountingPolicy.Organization
		|		AND T.Date >= AccountingPolicy.Period
		|GROUP BY
		|	T.Recorder,
		|	T.DocumentSource,
		|	T.Organization,
		|	T.Date
		|INDEX BY
		|	PolicyPeriod,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Recorder,
		|	T.DocumentSource,
		|	T.Organization,
		|	AccountingPolicy.InventoryValuationMethod
		|INTO TTAccountingPoliciesOfSourceDocuments
		|FROM 
		|	TTDocumentsAreSourcesFromCostPriceWithDatesAndPeriodsOfPolicies AS T
		|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
		|		ON T.Organization = AccountingPolicy.Organization
		|		AND T.PolicyPeriod = AccountingPolicy.Period
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
EndFunction

// Returns the text of a request that allows you to get a list of documents
// with incorrect (duplicated) movements in revenue and cost of sales
// that appeared as a result of error 00-00071689.
//
// Returns:
//	String - Query text
//
Function RequestTextDocumentsWithDuplicatesOfRevenueAndCostOfSalesRegisteredRecords() Export
	Return
		"SELECT DISTINCT
		|	""RevenueAndCOGS"" AS RegisterName,
		|	T.Recorder 					AS Ref,
		|	Analysts.Organization			AS Organization,
		|	1 								AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
		|		ON T.AccountingDimensionByPartners = Analysts.Ref
		|WHERE
		|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Analysts.Organization IN(&CompanyArray)
		|	AND T.Count = 0
		|	AND T.Cost <> 0
		|	AND NOT T.CalculationOfCost AND NOT T.ReversingEntry
		|	AND NOT T.Recorder REFS Document.RegisterAdjustment
		|	AND NOT T.Recorder REFS Document.InventoryCostCalculation
		|	AND NOT T.Recorder REFS Document.CalculationOfInventoryImpairmentProvision
		|	AND NOT T.Recorder REFS Document.SaleAdjustment";
EndFunction

// Returns the text of a request that allows you to get a list of documents
// with missing movements for adjusting revenue and cost of sales
// that appeared as a result of error 00-00302463.
//
Function RequestTextDocumentsWithMissingRegisteredRecordsInRevenueAndCostOfSales()
	Return
		"SELECT TOP 0
		|	""RevenueAndCOGS"" 		AS RegisterName,
		|	T.Recorder							AS Ref,
		|	T.AccountingDimensionByPartners.Organization	AS Organization,
		|	T.BusinessOperation					AS BusinessOperation,
		|	1 										AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	""RevenueAndCOGS"" AS RegisterName,
		|	T.Ref 						AS Ref,
		|	T.Ref.Organization			AS Organization,
		|	UNDEFINED					AS BusinessOperation,
		|	1 								AS ErrorCode
		|FROM
		|	Document.SaleAdjustment.InventoryOwnerAttributesRevenueAdjustment AS T
		|	LEFT JOIN AccumulationRegister.RevenueAndCOGS AS Revenue
		|		ON T.Ref = Revenue.Recorder
		|		AND T.ItemsLocationAttributes.Products = Revenue.ItemsLocationAttributes.Products
		|		AND T.ItemsLocationAttributes.Characteristic = Revenue.ItemsLocationAttributes.Characteristic
		|		AND T.ItemsLocationAttributes.Series = Revenue.ItemsLocationAttributes.Series
		|		AND Revenue.Count = 0
		|		AND NOT Revenue.CalculationOfCost
		|WHERE
		|	T.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.Ref.Organization IN(&CompanyArray)
		|	AND (T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR (T.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|			AND CASE WHEN T.Ref.DocumentBasis REFS Document.CustomerInvoice
		|				THEN CAST(T.Ref.DocumentBasis AS Document.CustomerInvoice).ToReturnReusablePackage
		|				ELSE FALSE
		|			  END = FALSE)
		|		OR T.ItemsLocationAttributes.Products.ItemsType IS NULL)
		|	AND Revenue.Recorder IS NULL
		|
		|UNION ALL
		|
		// Movements in the register "Revenue and cost of sales" must correspond to movements in the register "Cost of goods"
		// in the fields: Period, Registrar, analyticaccountinganomenclature, type of inventory, Organization, Accounting division,
		// Client's order, Record ID, Reverse.
		// Batch measurements are not taken into account, because they are not yet filled in at the beginning of the month's closing.
		// We do not check compliance with the Analytics Accounting Partner field, because this field is not always filled in in the movements of the "Cost of goods" register.
		// The inventory type is not filled in for the giver's reports in the movements according to the "Revenue and cost of sales" register.
		// For such movements, the connection with the cost of goods in the "Inventory type" field does not need to be made. 
		|SELECT DISTINCT
		|	""RevenueAndCOGS"" AS RegisterName,
		|	T.Recorder					AS Ref,
		|	Dimension.Organization			AS Organization,
		|	T.BusinessOperation			AS BusinessOperation,
		|	2 								AS ErrorCode
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
		|		ON Dimension.Ref = T.AccountingDimensionByPartners
		|	LEFT JOIN AccumulationRegister.InventoryCost AS Cost_
		|		ON Cost_.Period = T.Period
		|		AND Cost_.Recorder = T.Recorder
		|		AND (Cost_.ItemsLocationAttributes = T.ItemsLocationAttributes
		|			OR T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer), 
		|				VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods))
		|			AND Cost_.CorItemsLocationAttributes = T.ItemsLocationAttributes
		|			OR Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse)
		|			AND T.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ReverseOfSale),
		|				VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer))
		|			AND Cost_.CorItemsLocationAttributes = T.ItemsLocationAttributes
		|		)
		// For reports to the giver, the inventory type is not filled in.
		|		AND (Cost_.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|			OR T.InventoryType = VALUE(Enum.InventoryTypes.OperationService))
		|		AND Cost_.Organization = Dimension.Organization
		|		AND (Cost_.AccountingSection = T.AccountingSection
		|			OR Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse))
		|		AND (Cost_.SalesOrder = T.SalesOrder
		|			OR Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExternalReceipt))
		|		AND Cost_.FinRecordID = T.FinRecordID
		|		AND Cost_.ReversingEntry = T.ReversingEntry
		|WHERE
		|	&UseCostAccounting
		|	AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Dimension.Organization IN (&CompanyArray)
		|	AND T.Count <> 0
		|	AND T.ItemsLocationAttributes.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
		// For households. the "Registration on return" operation is not performed to calculate the cost (the cost is determined by the data of the document).
		// For the return of goods from the client of past periods, the cost of the return is determined by the movements of the sales document.
		// Therefore, for such operations it is not necessary to check the correspondence of register movements.
		|	AND NOT T.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn),
		|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods))
		|	AND T.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
		|	AND VALUETYPE(T.Recorder) <> TYPE(Document.OBEntrySalesForPastPeriods)
		|	AND VALUETYPE(T.Recorder) <> TYPE(Document.OBEntry)
		// In past periods, there may be RegisteredRecorded with obsolete types of stocks. We exclude such Registered Records from the check.
		|	AND NOT ISNULL(T.InventoryOwnerAttribute.Obsolete1, FALSE)
		|	AND T.Active
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|	AND Cost_.Recorder IS NULL
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	""RevenueAndCOGS"" AS RegisterName,
		|	T.Recorder					AS Ref,
		|	Dimension.Organization			AS Organization,
		|	T.BusinessOperation			AS BusinessOperation,
		|	3 								AS ErrorCode
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS T
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
		|		ON Dimension.Ref = T.AccountingDimensionByPartners
		|WHERE
		|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Dimension.Organization IN (&CompanyArray)
		|	AND T.Count <> 0
		|	AND T.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|
		|UNION ALL
		|
		// Movements in the "Cost of goods" register must correspond to the "Revenue and cost of sales"
		// register in the part of filling in the "Partner accounting Analytics" field.
		|SELECT DISTINCT
		|	""InventoryCost""		AS RegisterName,
		|	T.Recorder					AS Ref,
		|	Dimension.Organization			AS Organization,
		|	T.BusinessOperation			AS BusinessOperation,
		|	2 								AS ErrorCode
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Dimension
		|		ON Dimension.Ref = T.AccountingDimensionByPartners
		|	LEFT JOIN AccumulationRegister.RevenueAndCOGS AS Revenue
		|		ON Revenue.Period = T.Period
		|		AND Revenue.Recorder = T.Recorder
		|		AND Revenue.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND Revenue.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND Revenue.AccountingDimensionByPartners.Organization = T.Organization
		|		AND Revenue.AccountingSection = T.AccountingSection
		|		AND Revenue.SalesOrder = T.SalesOrder
		|		AND Revenue.AccountingDimensionByPartners = T.AccountingDimensionByPartners
		|		AND Revenue.BusinessTransactionSetting = T.BusinessTransactionSetting
		|		AND Revenue.FinRecordID = T.FinRecordID
		|		AND Revenue.ReversingEntry = T.ReversingEntry
		|WHERE
		|	&UseCostAccounting
		|	AND T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.Organization IN (&CompanyArray)
		|	AND T.Count <> 0
		// For households. The cost calculation is not performed of operation "Registration on return" (the cost is determined by the document data),
		// therefore, for such operations of operation, it is not necessary to check the correspondence of the Registered Records.
		// There is no connection of operation "Sale of commission goods" to the registers of inventory costs and cost of sales.
		// OF Operation "Sales (Local accounting only)", there are no Registered Records for the "Revenue and cost of sales" register for households.
		|	AND NOT T.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn),
		|		VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|		VALUE(Enum.BusinessTransactions.ConsignmentSale))
		|	AND ISNULL(T.InventoryOwnerAttribute.InventoryType, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
		|	AND T.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
		|	AND VALUETYPE(T.Recorder) IN (
		|		TYPE(Document.CustomerInvoice),
		|		TYPE(Document.RetailReturnsReport))
		|	AND T.Active
		|	AND NOT T.LotCalculation
		|	AND NOT T.CalculationOfCost
		|	AND Revenue.Recorder IS NULL
		|";
EndFunction

Procedure ClearManRegistersData(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "ClearManagementRegisterData");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
		"SELECT DISTINCT
		|	T.Recorder
		|FROM
		|	AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities AS T
		|WHERE
		|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.Organization IN(&CompanyArray)
		|	AND T.Recorder REFS Document.AllocationOfOtherCosts";
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		
		WriteParameters = CostCalculationAppliedAlgorithms.InitializeRecordingParameters(
			CalculationParameters.PayrollPeriod.BeginOfPeriod,
			CalculationParameters.TaskNumberBeforeCalculation);
	
		Try
			CostCalculationAppliedAlgorithms.RecordRegisteredRecordsByRegister(
				Selection,
				AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities,
				WriteParameters);
		Except
			
			// We will add information about the error to the calculation protocol, errors should already be registered in the month closing mechanism.
			ProtocolText_ = DetailErrorDescription(ErrorInfo());
			
			CostCalculationProtocol.FixCalculationError(
				CalculationParameters,
				Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenWritingRecordsInRegisters,
				ProtocolText_);
				
			Raise ProtocolText_;
			
		EndTry;
		
		CostCalculationProtocol.AdditionalInformation(
			CalculationParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xóa bản ghi kết chuyển theo biểu ghi %1: %2';
					|ru = 'Очищено движений по регистру %1: %2';
					|en = 'Records by %1 register cleared:%2'; fa = 'Records by %1 register cleared:%2';
					|it = 'Cancellati movimenti per registro: %1:%2';
					|pl = 'Oczyszczono ruchów w rejestrze %1: %2';
					|tr = '%1: %2 kaydında hareketler temizlendi'", Common.DefaultLanguageCode()),
				Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.FullName(),
				CostCalculationProtocol.ValuePresentation(Selection.Count())));
		
		
	EndIf;
	
EndProcedure

#Region TurningOnTurnoverAccountingByInventoryKinds

// We select documents in the Register Records of which the type of inventory is not filled in, except for exceptions.
// Additionally, we select data from the documents "Correction of the expanded balance of items of companies",
// if they did not have any Registered Records according to the register "Inventory costs" and the types of inventory write-off and inventory are different.
//
// Registered Records for which the inventory type is not filled in in inventory cost accounting:
// - the item accounting analytics shows the item with the "Service" type
// - the item accounting analytics shows the untraceable item with the "Work" item type
// - items purchased from the committee
//		Accounting section "Items in warehouses", in the item accounting analytics the type of storage location "Partner" or "Company"
// - products reflected in the reports of the processor
//		The Accounting section "Production costs", in the analytics of the nomenclature accounting type of storage location "Partner"
// - works for the preparation of reports to
//		the giver of the "Receipt" Registered Record under the Accounting section "Production costs" with the completed details "Cor.analytics of the nomenclature accounting", 
//		the business of Operation "Output", and the type of record "Batch" or "Batch", etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc., etc.Transfer of productionproduction".
// - products sold of Operation by the document "Report to the giver"
//		of Registered Records with the economic operation "Report to the giver"
//
// Additional exceptions for revenue and cost of goods sold:
// - the inventory type indicates the value "Agent service"
//	(in the analytics of the inventory item, the item with the item type "Service. Performed by a partner")
//
// Exceptions for production documents 2.1:	
// - the type of inventory in Registered Records is filled offline: the Accounting section "Production costs" and the type of record "Consumption (production)"
// - for the document "Movement of materials in production" the type of inventory in Registered Records is filled offline
//
// It is necessary to correct the RegisteredRecorded in the registers:
//	- Inventory costs
//	- Revenue and Cost of goods sold
//
// Returns:
//	String - Query text
//
Function QueryTextTurningOnTurnoverAccountingByInventoryKinds() Export
	Return "
		|SELECT DISTINCT
		|	""InventoryCost""			AS RegisterName,
		|	InventoryCost.Recorder	AS Ref,
		|	InventoryCost.Organization	AS Organization,
		|	1									AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|WHERE
		|	InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND InventoryCost.Organization IN(&CompanyArray)
		|	AND InventoryCost.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|	AND InventoryCost.Count <> 0
		|	AND NOT InventoryCost.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		// Untraceable works.
		|	AND NOT (
		|		InventoryCost.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND NOT InventoryCost.ItemsLocationAttributes.Products.TracedGoods)
		// Work in Unfinished production.
		|	AND NOT (
		|		InventoryCost.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		// Goods purchased from the committees, or reflected in the reports of the processor
		|	AND NOT (
		|		InventoryCost.AccountingSection IN (
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|			VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts))
		|		AND InventoryCost.ItemsLocationAttributes.StorageType IN (
		|			VALUE(Enum.StorageLocationTypes.Partner),
		|			VALUE(Enum.StorageLocationTypes.Organization)))
		// Returnable waste reflected in the processor's report.
		|	AND NOT (
		|		InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		AND InventoryCost.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|		AND InventoryCost.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.ProductsRelease),
		|			 VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
		|		AND InventoryCost.Count < 0)
		// Receipt and write-off of the issued processor's work, for dependent organizations (branches)
		|	AND NOT (InventoryCost.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			AND InventoryCost.EntryType = VALUE(Enum.LotRecordTypes.Supplement)
		|			AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices)    
		|			AND VALUETYPE(InventoryCost.Recorder) IN (TYPE(Document.BackflushProduction), TYPE(Document.ProductionStage2_2))
		|		)

		// Work on the preparation of reports to the giver
		// Adjusted work for the preparation of reports to the giver
		|	AND NOT (VALUETYPE(InventoryCost.Recorder) = TYPE(Document.SaleAdjustment)
		|		AND InventoryCost.BusinessOperation IN 
		|			(VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|			VALUE(Enum.BusinessTransactions.Subcontracting2_5),
		|			VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
		|			VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
		|			VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
		|			VALUE(Enum.BusinessTransactions.ReportToMaterialProviderReverseTransaction),
		|			VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod)))
		|	AND NOT InventoryCost.CalculationOfCost
		|	AND NOT InventoryCost.LotCalculation
		|	AND NOT InventoryCost.Recorder REFS Document.InventoryCostCalculation
		|	AND NOT InventoryCost.Recorder REFS Document.CalculationOfInventoryImpairmentProvision
		|	AND NOT InventoryCost.ReversingEntry
		|
		|UNION ALL
		|
		// Additionally, we select data from the documents "Correction of the expanded balance of goods of organizations",
		// if they did not have movements in the register "Cost of goods" and the types of inventory write-off and accounting differ.
		|SELECT DISTINCT
		|	""InventoryCost""		AS RegisterName,
		|	Corrections.Ref				AS Ref,
		|	Corrections.Ref.Organization	AS Organization,
		|	1								AS ErrorCode
		|FROM
		|	Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting.Corrections AS Corrections
		|	LEFT JOIN AccumulationRegister.InventoryCost AS InventoryCost
		|		ON InventoryCost.Period = Corrections.Ref.Date
		|		AND InventoryCost.Recorder = Corrections.Ref
		|WHERE
		|	Corrections.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Corrections.Ref.Organization IN(&CompanyArray)
		|	AND Corrections.WriteOffInventoryAttributes <> Corrections.InventoryOwnerAttributeGoodsReceipts
		|	AND InventoryCost.Recorder IS NULL
		|";
EndFunction

// We select documents in the movements of which the type of stocks is not filled in, except for exceptions.
//
// Returns:
//	String - Query text
//
Function RequestTextEnablingRevenueAndCostOfSalesAccountingByInventoryType() Export
	Return "
		|SELECT DISTINCT
		|	""RevenueAndCOGS""			AS RegisterName,
		|	RevenueAndCOGS.Recorder	AS Ref,
		|	Analysts.Organization					AS Organization,
		|	1										AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
		|		ON RevenueAndCOGS.AccountingDimensionByPartners = Analysts.Ref
		|WHERE
		|	RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Analysts.Organization IN(&CompanyArray)
		|	AND RevenueAndCOGS.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|	AND RevenueAndCOGS.Count <> 0
		|	AND NOT RevenueAndCOGS.InventoryType IN (
		|		VALUE(Enum.InventoryTypes.OperationService),
		|		VALUE(Enum.InventoryTypes.AgentService))
		// Untraceable works.
		|	AND NOT (RevenueAndCOGS.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND NOT RevenueAndCOGS.ItemsLocationAttributes.Products.TracedGoods)
		|	AND NOT RevenueAndCOGS.CalculationOfCost
		|	AND NOT RevenueAndCOGS.LotCalculation
		|	AND NOT RevenueAndCOGS.Recorder REFS Document.InventoryCostCalculation
		|	AND NOT RevenueAndCOGS.Recorder REFS Document.CalculationOfInventoryImpairmentProvision
		|	AND NOT RevenueAndCOGS.Recorder REFS Document.OBEntry
		|	AND NOT RevenueAndCOGS.Recorder REFS Document.OBEntrySalesForPastPeriods
		|";
EndFunction

#EndRegion

#Region EnablingCostAccounting

// We select documents that have movements on operational registers, but there are no movements on cost accounting.
// Data from the following operational registers are used:
//	- Goods of organizations
//		, except for customs declarations with zero amounts of duty and VAT
//		, except for movements of goods in the status "Shipped"
//		, except for assemblies of goods in the status "In operation"
//	- Goods of organizations to be transferred
//	- Goods transferred to the processor
//	- Goods received from the processor
//	- The goods to the customs Declaration (motion "Parish)
//	- The materials in the production (including works in batch accounting version 2.2,
//		when the batch account 2.1 not used simultaneously with the online movements on the register "Cost of goods")
//		excludes traffic from documents "means the Itinerary of production", "write-off the cost of the release", "Distribution of materials and work,"
//		used for the production of 2.1, because these documents are not doing the online movements register "Cost of goods" 
//		simultaneously register "Materials and work in production."
// In addition to the operational registers, we select data directly from documents (these documents do not have operational registers):
//	- Report to the giver
//	- Application for the import of goods from the EAEU with the completed amount of VAT
//	- Entering balances with the "OU" checkbox turned off
// Exceptions:
//	- There are no corresponding operational registers for cost movements under the accounting section "Work in progress".
//		But this accounting section always corresponds with other sections that have corresponding operational registers.
//		Therefore, we do not check the movements under the "Work in progress" section. They will be re-formed simultaneously with other movements.
//	- The movements of the documents "Application for the import of goods from the EAEU" at cost do not have the corresponding operational registers. 
//		We check the data in the tabular part of the documents
//	- Movement of documents "Distribution of materials and works" when distributing materials according to the rule
//	- Movement of documents "Correction of the expanded balance of goods of organizations" if the type of stocks does not change in the movements.
// 		Such documents will not have movements in the "Cost of goods" register.
//	- Register adjustment documents. Such documents can have movements only on operational registers.
//	- Documents for entering initial balances that have the "Cost price" checkbox unchecked (such documents do not have cost accounting movements)
//
// Returns:
//	String - Query text
//
Function QueryTextEnablingCostAccounting() Export
	Return "
		// We select customs declarations for imports, which indicate zero amounts of customs duty and VAT.
		|SELECT DISTINCT
		|	DD.Ref,
		|	Rows.ItemsLocationAttributes
		|INTO ZeroSumDeclarations
		|FROM
		|	Document.CCDImport AS DD
		|	INNER JOIN Document.CCDImport.Goods AS Rows
		|		ON Rows.Ref = DD.Ref
		|WHERE
		|	DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN (&CompanyArray)
		|	AND DD.Posted
		|	AND Rows.DutyAmount = 0
		|	AND Rows.VATAmount = 0
		|	AND DD.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
		|
		|UNION ALL
		|
		// If the storage location differs from the warehouse in the Product accounting analytics,
		// then we will select the Product accounting analytics corresponding to the warehouse.
		|SELECT DISTINCT
		|	DD.Ref,
		|	Dimension.DimensionKey AS ItemsLocationAttributes
		|FROM
		|	Document.CCDImport AS DD
		|	INNER JOIN Document.CCDImport.Goods AS Rows
		|		ON Rows.Ref = DD.Ref
		|	INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
		|		ON Dimension.Products = Rows.Products
		|		AND Dimension.Characteristic = Rows.Characteristic
		|		AND Dimension.Series = Rows.Series
		|		AND Dimension.StorageLocation = Rows.Warehouse
		|		AND (CASE WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN Dimension.Purpose = Rows.Purpose
		|			ELSE Dimension.Purpose = VALUE(Catalog.Assignments.EmptyRef) END)
		|WHERE
		|	DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN (&CompanyArray)
		|	AND DD.Posted
		|	AND Rows.DutyAmount = 0
		|	AND Rows.VATAmount = 0
		|	AND DD.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
		|;
		// We select the Balance entry documents that are not reflected in the cost
		|SELECT
		|	T.Ref AS Ref
		|INTO TTInputOfBalancesWithCostAccountingTurned
		|FROM
		|	Document.OBEntry AS T
		|WHERE
		|	T.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.Organization IN (&CompanyArray)
		|	AND T.Posted
		|	AND NOT T.PostInCostAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	T.Ref
		|FROM
		|	Document.OBEntryGoods AS T
		|WHERE
		|	T.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.Organization IN (&CompanyArray)
		|	AND T.Posted
		|	AND NOT T.PostInCostAccounting
		|
		|INDEX BY
		|	Ref
		|;
		// We select documents that have movements on operational registers.
		|SELECT DISTINCT
		|	Goods.Recorder AS Recorder,
		|	Goods.Organization AS Organization
		|INTO DocumentsWithRegisteredRecords
		|FROM (
		|	SELECT DISTINCT
		|		CompanyGoods.Recorder AS Recorder,
		|		CompanyGoods.Organization AS Organization
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		// We exclude customs declarations with zero amounts of duty and VAT
		|		LEFT JOIN ZeroSumDeclarations AS Declarations
		|			ON Declarations.Ref = CompanyGoods.Recorder
		|			AND Declarations.ItemsLocationAttributes = CompanyGoods.ItemsLocationAttributes
		|			AND VALUETYPE(CompanyGoods.Recorder) = TYPE(Document.CCDImport)
		// We exclude the movement of goods in the status "Shipped"
		|		LEFT JOIN Document.InventoryTransfer AS Move
		|			ON Move.Ref = CompanyGoods.Recorder
		|			AND Move.Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
		// We exclude the reverse movement of goods in the Status "Shipped"
		|		LEFT JOIN Document.ReversingEntry AS ReverseMovementOfGoods
		|			ON ReverseMovementOfGoods.Ref = CompanyGoods.Recorder
		|			AND ReverseMovementOfGoods.ReversedDocument REFS Document.InventoryTransfer
		|			AND CAST(ReverseMovementOfGoods.ReversedDocument AS Document.InventoryTransfer).Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
		// We exclude the assembly of goods in the status "In progress"
		|		LEFT JOIN Document.AssemblyFromComponents AS Assembly
		|			ON Assembly.Ref = CompanyGoods.Recorder
		|			AND Assembly.Status = VALUE(Enum.GoodsAssemblyStatuses.InProgress)
		|		LEFT JOIN TTInputOfBalancesWithCostAccountingTurned AS OBEntry
		|			ON CompanyGoods.Recorder = OBEntry.Ref
		|	WHERE
		|		&UseCostAccounting
		|		AND CompanyGoods.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND CompanyGoods.Organization IN(&CompanyArray)
		|		AND (CompanyGoods.ShipmentCompany = VALUE(Catalog.Companies.EmptyRef)
		|			OR CompanyGoods.ShipmentCompany = CompanyGoods.Organization)
		|		AND VALUETYPE(CompanyGoods.Recorder) <> TYPE(Document.RegisterAdjustment)
		// We exclude the procurement Consignment Notification Report (principal), because it divides the Register Records only by items of organizations.
		|		AND VALUETYPE(CompanyGoods.Recorder) <> TYPE(Document.PurchasingReportToConsignorPrincipal)
		// We exclude the Registering Records according to the type of destination "Delivery of the principal", because according to such appointments, in theory, Registering Records at cost should not be formed.
		|		AND CompanyGoods.ItemsLocationAttributes.Purpose.AssignmentType <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
		// We exclude the movement of production documents 2.2, for which there are no online movements according to the register "Cost of goods"
		|		AND CompanyGoods.BusinessOperation <> VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
		// We exclude the movements of the documents "Correction of the expanded balance of goods of organizations" and "Adjustment of the destination of goods",
		// if the type of inventory does not change in the movements. Such documents will not have movements in the "Cost of goods" register.
		|		AND NOT (
		|			CompanyGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsAssignmentAdjustments)
		|			AND CompanyGoods.InventoryOwnerAttribute = CompanyGoods.CorInventoryOwnerAttribute)
		// We exclude customs declarations with zero amounts of duty and VAT
		|		AND Declarations.Ref IS NULL
		// Exclude inputs of balances with cost accounting turned off
		|		AND OBEntry.Ref IS NULL
		// We exclude the movement of goods in the status "Shipped"
		|		AND Move.Ref IS NULL
		// We exclude the reverse movement of goods in the Status "Shipped"
		|		AND ReverseMovementOfGoods.Ref IS NULL
		// We exclude the assembly of goods in the status "In progress"
		|		AND Assembly.Ref IS NULL
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		CompanyGoodsForTransfer.Recorder AS Recorder,
		|		CompanyGoodsForTransfer.SellerInventoryOwnerAttribute.Organization AS Organization
		|	FROM
		|		AccumulationRegister.CompanyGoodsForTransfer AS CompanyGoodsForTransfer
		|	WHERE
		|		&UseCostAccounting
		|		AND CompanyGoodsForTransfer.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND CompanyGoodsForTransfer.SellerInventoryOwnerAttribute.Organization IN(&CompanyArray)
		|		AND VALUETYPE(CompanyGoodsForTransfer.Recorder) <> TYPE(Document.RegisterAdjustment)
		|
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		GoodsForRegistrationOfImportDocuments.Recorder AS Recorder,
		|		GoodsForRegistrationOfImportDocuments.Organization AS Organization
		|	FROM
		|		AccumulationRegister.GoodsForRegistrationOfImportDocuments AS GoodsForRegistrationOfImportDocuments
		|	WHERE
		|		&UseCostAccounting
		|		AND GoodsForRegistrationOfImportDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND GoodsForRegistrationOfImportDocuments.Organization IN(&CompanyArray)
		|		AND GoodsForRegistrationOfImportDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND VALUETYPE(GoodsForRegistrationOfImportDocuments.Recorder) <> TYPE(Document.RegisterAdjustment)
		|		AND GoodsForRegistrationOfImportDocuments.ImportDocumentType = &ImportDocumentType
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		MaterialsAndWorksInProduction.Recorder AS Recorder,
		|		MaterialsAndWorksInProduction.Organization AS Organization
		|	FROM
		|		AccumulationRegister.MaterialsAndWorksInProduction AS MaterialsAndWorksInProduction
		|		LEFT JOIN TTInputOfBalancesWithCostAccountingTurned AS OBEntry
		|			ON MaterialsAndWorksInProduction.Recorder = OBEntry.Ref
		|	WHERE
		|		&UseCostAccounting
		|		AND MaterialsAndWorksInProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND MaterialsAndWorksInProduction.Organization IN(&CompanyArray)
		|		AND MaterialsAndWorksInProduction.Count <> 0
		|		AND NOT VALUETYPE(MaterialsAndWorksInProduction.Recorder) IN (
		|			TYPE(Document.RegisterAdjustment),
		|			TYPE(Document.InventoryCostCalculation))
		// Exclude inputs of balances with cost accounting turned off
		|		AND OBEntry.Ref IS NULL
		// In addition to the documents "Distribution of materials and works" and "Distribution of returnable waste".
		// They make movements according to the register "Materials and works in production", but do not always have movements according to the register "Cost of goods".
		|		AND VALUETYPE(MaterialsAndWorksInProduction.Recorder) <> TYPE(Document.ProductionCostAllocation)
		|		AND VALUETYPE(MaterialsAndWorksInProduction.Recorder) <> TYPE(Document.RecyclableWasteAllocation)
		|
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		ApplicationForImportationGoods.Ref AS Recorder,
		|		ApplicationForImportationGoods.Ref.Organization AS Organization
		|	FROM
		|		Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationGoods
		|	WHERE
		|		&UseCostAccounting
		|		AND ApplicationForImportationGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND ApplicationForImportationGoods.Ref.Organization IN(&CompanyArray)
		|		AND ApplicationForImportationGoods.Ref.Posted
		|		AND ApplicationForImportationGoods.VATAmount <> 0
		|		AND ApplicationForImportationGoods.Products <> VALUE(Catalog.Products.EmptyRef)
		|		AND VALUETYPE(ApplicationForImportationGoods.DocumentInflow) <> TYPE(Document.SigningOfLeaseContract)
		|		AND VALUETYPE(ApplicationForImportationGoods.DocumentInflow) <> TYPE(Document.VendorInvoiceServicesAndAssets)
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		OBEntry.Ref AS Recorder,
		|		OBEntry.Ref.Organization AS Organization
		|	FROM
		|		Document.OBEntry.Goods AS OBEntry
		|	WHERE
		|		&UseCostAccounting
		|		AND OBEntry.Ref.PostInCostAccounting
		|		AND NOT OBEntry.Ref.RecordInOperationalAccounting
		|		AND OBEntry.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND OBEntry.Ref.Organization IN(&CompanyArray)
		|		AND OBEntry.Ref.Posted
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		OBEntry.Ref AS Recorder,
		|		OBEntry.Ref.Organization AS Organization
		|	FROM
		|		Document.OBEntryGoods.Goods AS OBEntry
		|	WHERE
		|		&UseCostAccounting
		|		AND OBEntry.Ref.PostInCostAccounting
		|		AND NOT OBEntry.Ref.RecordInOperationalAccounting
		|		AND OBEntry.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND OBEntry.Ref.Organization IN(&CompanyArray)
		|		AND OBEntry.Ref.Posted
		|	) AS Goods
		|INDEX BY
		|	Recorder,
		|	Organization
		|;
		// We select documents that have movements at cost.
		|SELECT DISTINCT
		|	InventoryCost.Recorder AS Recorder,
		|	InventoryCost.Organization AS Organization
		|
		|INTO ThereAreCostRegisteredRecords
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|	INNER JOIN DocumentsWithRegisteredRecords AS DocumentsWithRegisteredRecords
		|		ON DocumentsWithRegisteredRecords.Recorder = InventoryCost.Recorder
		|		AND DocumentsWithRegisteredRecords.Organization = InventoryCost.Organization
		|WHERE
		|	&UseCostAccounting
		|	AND InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND InventoryCost.Organization IN(&CompanyArray)
		|	AND NOT InventoryCost.CalculationOfCost
		|	AND NOT InventoryCost.LotCalculation
		|INDEX BY
		|	Recorder,
		|	Organization
		|;
		//We select documents that have movements on operational registers, but there are no movements on cost accounting.
		|SELECT DISTINCT
		|	""InventoryCost""			AS RegisterName,
		|	DocumentsWithRegisteredRecords.Recorder	AS Ref,
		|	DocumentsWithRegisteredRecords.Organization	AS Organization,
		|	1									AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	DocumentsWithRegisteredRecords AS DocumentsWithRegisteredRecords
		|
		|	LEFT JOIN ThereAreCostRegisteredRecords AS ThereAreCostRegisteredRecords
		|		ON ThereAreCostRegisteredRecords.Recorder = DocumentsWithRegisteredRecords.Recorder
		|		AND ThereAreCostRegisteredRecords.Organization = DocumentsWithRegisteredRecords.Organization
		|
		// We exclude from errors refunds and reverse refunds, multi-turn containers, Operation - "Refund from the commission agent (2.0)"
		|		LEFT JOIN Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
		|		ON ThereAreCostRegisteredRecords.Recorder IS NULL
		|			AND DocumentsWithRegisteredRecords.Recorder = ReturnOfGoodsFromCustomer.Ref
		|			AND ReturnOfGoodsFromCustomer.ReusablePackageReturn
		|			AND ReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
		|			
		|		LEFT JOIN Document.ReversingEntry AS ReversingEntry
		|		ON ThereAreCostRegisteredRecords.Recorder IS NULL
		|			AND DocumentsWithRegisteredRecords.Recorder = ReversingEntry.Ref
		|			AND  VALUETYPE(ReversingEntry.ReversedDocument) = TYPE(Document.ReturnOfGoodsFromCustomer)
		|		
		|		LEFT JOIN Document.ReturnOfGoodsFromCustomer AS CancelledReturnOfGoodsFromCustomer
		|		ON ReversingEntry.ReversedDocument = CancelledReturnOfGoodsFromCustomer.Ref
		|			AND CancelledReturnOfGoodsFromCustomer.ReusablePackageReturn
		|			AND CancelledReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
		|
		|WHERE
		|	&UseCostAccounting
		|	AND ThereAreCostRegisteredRecords.Recorder IS NULL
		|
		// We exclude from errors refunds and reverse refunds, multi-turn containers, Operation - "Refund from the commission agent (2.0)"
		|	AND ReturnOfGoodsFromCustomer.Ref IS NULL
		|	AND CancelledReturnOfGoodsFromCustomer.Ref IS NULL
		// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
		// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
		|	AND NOT DocumentsWithRegisteredRecords.Organization IN (&MediumSlipOrganizations)
		|;
		|DROP ZeroSumDeclarations;
		|DROP TTInputOfBalancesWithCostAccountingTurned;
		|DROP DocumentsWithRegisteredRecords;
		|DROP ThereAreCostRegisteredRecords
		|";
EndFunction

#EndRegion

#Region TurningOffCostAccountingByPurposes

// Select the documents that have a specified purpose in the movements in the inventory tracking Analytics.
// It is necessary to correct the movement in the registers:
//	- Cost of goods
//	- Revenue and cost of sales
//
// Returns:
//	String - Query text
//
Function QueryTextTurningOffCostAccountingByPurposes() Export
	Return "
		|SELECT DISTINCT
		|	""InventoryCost""			AS RegisterName,
		|	InventoryCost.Recorder	AS Ref,
		|	InventoryCost.Organization	AS Organization,
		|	1									AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|WHERE
		|	NOT &KeepRecordsOfInventoryCostByAssignments
		|	AND InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND InventoryCost.Organization IN(&CompanyArray)
		|	AND InventoryCost.ItemsLocationAttributes.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|	AND NOT InventoryCost.CalculationOfCost
		|	AND NOT InventoryCost.LotCalculation
		|	AND NOT InventoryCost.Recorder REFS Document.InventoryCostCalculation
		|	AND NOT InventoryCost.Recorder REFS Document.CalculationOfInventoryImpairmentProvision
		|
		// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
		// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
		|	AND NOT InventoryCost.Organization IN (&MediumSlipOrganizations)
		|";
EndFunction

// Select the documents that have a destination specified in the movements in the inventory accounting analytics.
//
// Returns:
//	String - Query text
//
Function RequestTextDisablingRevenueAndCostOfSalesAccountingByDestination() Export
	Return "
		|SELECT DISTINCT
		|	""RevenueAndCOGS""			AS RegisterName,
		|	RevenueAndCOGS.Recorder	AS Ref,
		|	Analysts.Organization					AS Organization,
		|	1										AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
		|		ON RevenueAndCOGS.AccountingDimensionByPartners = Analysts.Ref
		|WHERE
		|	NOT &KeepRecordsOfInventoryCostByAssignments
		|	AND RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Analysts.Organization IN(&CompanyArray)
		|	AND RevenueAndCOGS.ItemsLocationAttributes.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|	AND NOT RevenueAndCOGS.CalculationOfCost
		|	AND NOT RevenueAndCOGS.LotCalculation
		|	AND NOT RevenueAndCOGS.Recorder REFS Document.InventoryCostCalculation
		|	AND NOT RevenueAndCOGS.Recorder REFS Document.CalculationOfInventoryImpairmentProvision
		|
		// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
		// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
		|	AND NOT Analysts.Organization IN (&MediumSlipOrganizations)
		|";
EndFunction

#EndRegion

#Region TurningOnCostAccountingByPurposes

// Select documents that have a purpose specified in the movements for operational registers
// , but the purpose is not specified in the cost accounting movement.
// Data from the following operational registers is used:
//	- Goods of organizations
//		other than customs declarations with zero amounts of duty and VAT
//		other than movements of goods in the "Shipped" status
//		other than assemblies of goods in the "in progress" status"
//	- Products of organizations to be transferred
//	- Goods transferred to the processor
//	- Goods received from the processor
//	- Goods for customs Declaration processing ("Arrival" movement)
//	- The materials in the production (including the work with batch account version 2.2,
//		when batch accounting 2.1 not used simultaneously with online movements on the register "Cost of goods")
//		excluded movement the document "Route sheet of the production, write off the cost of production," "Distribution of materials and labor",
//		used for the production of 2.1, because these documents do not do online movements on the register "Cost of goods" 
//		simultaneously with the register of "Materials and production".
// In addition to the operational registers, select data directly from the documents (these documents do not have operational registers):
//	- report to the giver
//	- Application for import of goods from the EAEU with the completed VAT amount
//	- Enter balances with the "OU" checkbox disabled"
// Exceptions:
//	- The goods transferred to the Commission are not registered by appointment
//	- For the goods to issue reports to the Commitee, accounting for appointments is not maintained
//	- Goods shipped without transfer of ownership are not accounted for by destination
//	- There are no corresponding operational registers for cost movements under the "work in progress" accounting section.
//		However, this accounting section always corresponds to other sections that have corresponding operational registers.
//		Therefore, we do not check the movement under the "work in progress" section. They will be re-formed at the same time as other movements.
//	- Movements of documents "Application for import of goods from the EAEU" at cost do not have the corresponding operational registers. 
//		We check the data in the table part of the documents
//	- Movement of documents "Distribution of materials and works" when distributing materials according to the rule
//	- Movement of documents "Correction of the expanded balance of goods of organizations" if the movement does not change the type of inventory.
// 		Such documents will not have movements in the "Cost of goods" register.
//	- Documents for correcting registers. Such documents can only have movements in operational registers.
//	- Documents for entering initial balances that have the "Cost price" checkbox unchecked (such documents do not have movements for cost accounting)
//
// Returns:
//	String - Query text
//
Function QueryTextTurningOnCostAccountingByPurposes() Export
	Return "
		|SELECT
		|	Keys.Ref AS Ref
		|INTO AnalyticsWithAssignments
		|FROM
		|	Catalog.InventoryLocationAttributeKeys AS Keys
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND &UseCostAccounting
		|	AND Keys.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|	AND Keys.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|INDEX BY
		|	Ref
		|;
		// We select customs declarations for imports, which indicate zero amounts of customs duty and VAT.
		|SELECT DISTINCT
		|	DD.Ref AS Ref,
		|	Rows.ItemsLocationAttributes AS ItemsLocationAttributes
		|INTO ZeroSumDeclarations
		|FROM
		|	Document.CCDImport AS DD
		|	INNER JOIN Document.CCDImport.Goods AS Rows
		|		ON Rows.Ref = DD.Ref
		|	INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|		ON AnalyticsWithAssignments.Ref = Rows.ItemsLocationAttributes
		|WHERE
		|	DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DD.Organization IN (&CompanyArray)
		|	AND DD.Posted
		|	AND Rows.DutyAmount = 0
		|	AND Rows.VATAmount = 0
		|INDEX BY
		|	Ref,
		|	ItemsLocationAttributes
		|;
		|SELECT
		|	OBEntry.Ref AS Ref
		|INTO TTInputOfBalancesWithCostAccountingTurned
		|FROM
		|	Document.OBEntry AS OBEntry
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND &UseCostAccounting
		|	AND OBEntry.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND OBEntry.Organization IN(&CompanyArray)
		|	AND NOT OBEntry.PostInCostAccounting
		|	AND OBEntry.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	OBEntry.Ref
		|FROM
		|	Document.OBEntryGoods AS OBEntry
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND &UseCostAccounting
		|	AND OBEntry.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND OBEntry.Organization IN(&CompanyArray)
		|	AND NOT OBEntry.PostInCostAccounting
		|	AND OBEntry.Posted
		|
		|INDEX BY
		|	Ref
		|;
		// We select the documents that have an appointment indicated in the movements of the operational registers.
		|SELECT DISTINCT
		|	Goods.Recorder AS Recorder,
		|	Goods.Organization AS Organization
		|INTO DocumentsWithAssignments
		|FROM (
		|	SELECT DISTINCT
		|		CompanyGoods.Recorder AS Recorder,
		|		CompanyGoods.Organization AS Organization
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = CompanyGoods.ItemsLocationAttributes
		// We exclude customs declarations with zero amounts of duty and VAT
		|		LEFT JOIN ZeroSumDeclarations AS Declarations
		|			ON Declarations.Ref = CompanyGoods.Recorder
		|			AND Declarations.ItemsLocationAttributes = CompanyGoods.ItemsLocationAttributes
		|			AND VALUETYPE(CompanyGoods.Recorder) = TYPE(Document.CCDImport)
		// We exclude the movement of goods in the status "Shipped"
		|		LEFT JOIN Document.InventoryTransfer AS Move
		|			ON Move.Ref = CompanyGoods.Recorder
		|			AND Move.Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
		// We exclude the reverse movement of goods in the Status "Shipped"
		|		LEFT JOIN Document.ReversingEntry AS ReverseMovementOfGoods
		|			ON ReverseMovementOfGoods.Ref = CompanyGoods.Recorder
		|			AND ReverseMovementOfGoods.ReversedDocument REFS Document.InventoryTransfer
		|			AND CAST(ReverseMovementOfGoods.ReversedDocument AS Document.InventoryTransfer).Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
		// We exclude the assembly of goods in the status "In progress"
		|		LEFT JOIN Document.AssemblyFromComponents AS Assembly
		|			ON Assembly.Ref = CompanyGoods.Recorder
		|			AND Assembly.Status = VALUE(Enum.GoodsAssemblyStatuses.InProgress)
		// We exclude the input of Balances with cost accounting turned off
		|		LEFT JOIN TTInputOfBalancesWithCostAccountingTurned OBEntry
		|			ON CompanyGoods.Recorder = OBEntry.Ref
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND CompanyGoods.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND CompanyGoods.Organization IN(&CompanyArray)
		|		AND VALUETYPE(CompanyGoods.Recorder) <> TYPE(Document.RegisterAdjustment)
		// We exclude the movement of production documents 2.2, for which there are no online movements according to the register "Cost of goods"
		|		AND CompanyGoods.BusinessOperation <> VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
		// We exclude the movement of documents "Correction of the expanded balance of goods of organizations" if the type of stocks does not change in the movements.
		// Such documents will not have movements in the "Cost of goods" register.
		|		AND NOT (
		|			CompanyGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsAssignmentAdjustments)
		|			AND CompanyGoods.InventoryOwnerAttribute = CompanyGoods.CorInventoryOwnerAttribute
		|			AND VALUETYPE(CompanyGoods.Recorder) <> TYPE(Document.InventoryAssignmentAdjustment))
		// We exclude customs declarations with zero amounts of duty and VAT
		|		AND Declarations.Ref IS NULL
		// Exclude inputs of balances with cost accounting turned off
		|		AND OBEntry.Ref IS NULL
		// We exclude the movement of goods in the status "Shipped"
		|		AND Move.Ref IS NULL
		// We exclude the reverse movement of goods in the Status "Shipped"
		|		AND ReverseMovementOfGoods.Ref IS NULL
		// We exclude the assembly of goods in the status "In progress"
		|		AND Assembly.Ref IS NULL
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		CompanyGoodsForTransfer.Recorder AS Recorder,
		|		CompanyGoodsForTransfer.SellerInventoryOwnerAttribute.Organization AS Organization
		|	FROM
		|		AccumulationRegister.CompanyGoodsForTransfer AS CompanyGoodsForTransfer
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = CompanyGoodsForTransfer.ItemsLocationAttributes
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND CompanyGoodsForTransfer.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND CompanyGoodsForTransfer.SellerInventoryOwnerAttribute.Organization IN(&CompanyArray)
		|		AND VALUETYPE(CompanyGoodsForTransfer.Recorder) <> TYPE(Document.RegisterAdjustment)
		|
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		GoodsForRegistrationOfImportDocuments.Recorder AS Recorder,
		|		GoodsForRegistrationOfImportDocuments.Organization AS Organization
		|	FROM
		|		AccumulationRegister.GoodsForRegistrationOfImportDocuments AS GoodsForRegistrationOfImportDocuments
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = GoodsForRegistrationOfImportDocuments.ItemsLocationAttributes
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND GoodsForRegistrationOfImportDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND GoodsForRegistrationOfImportDocuments.Organization IN(&CompanyArray)
		|		AND GoodsForRegistrationOfImportDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND VALUETYPE(GoodsForRegistrationOfImportDocuments.Recorder) <> TYPE(Document.RegisterAdjustment)
		|		AND GoodsForRegistrationOfImportDocuments.ImportDocumentType = &ImportDocumentType
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		MaterialsAndWorksInProduction.Recorder AS Recorder,
		|		MaterialsAndWorksInProduction.Organization AS Organization
		|	FROM
		|		AccumulationRegister.MaterialsAndWorksInProduction AS MaterialsAndWorksInProduction
		// We exclude the input of Balances with cost accounting turned off
		|		LEFT JOIN TTInputOfBalancesWithCostAccountingTurned OBEntry
		|			ON MaterialsAndWorksInProduction.Recorder = OBEntry.Ref
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND MaterialsAndWorksInProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND MaterialsAndWorksInProduction.Organization IN(&CompanyArray)
		|		AND MaterialsAndWorksInProduction.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|		AND MaterialsAndWorksInProduction.Count <> 0
		|		AND NOT VALUETYPE(MaterialsAndWorksInProduction.Recorder) IN (
		|			TYPE(Document.RegisterAdjustment),
		|			TYPE(Document.InventoryCostCalculation))
		// Exclude inputs of balances with cost accounting turned off
		|		AND OBEntry.Ref IS NULL
		// In addition to the documents "Distribution of materials and works". They make movements according to the register "Materials and works in production",
		// but do not always have movements according to the register "Cost of goods".
		|		AND VALUETYPE(MaterialsAndWorksInProduction.Recorder) <> TYPE(Document.ProductionCostAllocation)
		|
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		ApplicationForImportationGoods.Ref AS Recorder,
		|		ApplicationForImportationGoods.Ref.Organization AS Organization
		|	FROM
		|		Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationGoods
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = ApplicationForImportationGoods.ItemsLocationAttributes
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND ApplicationForImportationGoods.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND ApplicationForImportationGoods.Ref.Organization IN(&CompanyArray)
		|		AND ApplicationForImportationGoods.Ref.Posted
		|		AND ApplicationForImportationGoods.VATAmount <> 0
		|		AND VALUETYPE(ApplicationForImportationGoods.DocumentInflow) <> TYPE(Document.SigningOfLeaseContract)
		|		AND VALUETYPE(ApplicationForImportationGoods.DocumentInflow) <> TYPE(Document.VendorInvoiceServicesAndAssets)
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		OBEntry.Ref AS Recorder,
		|		OBEntry.Ref.Organization AS Organization
		|	FROM
		|		Document.OBEntry.Goods AS OBEntry
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = OBEntry.ItemsLocationAttributes
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND OBEntry.Ref.PostInCostAccounting
		|		AND NOT OBEntry.Ref.RecordInOperationalAccounting
		|		AND OBEntry.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND OBEntry.Ref.Organization IN(&CompanyArray)
		|		AND OBEntry.Ref.Posted
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		OBEntry.Ref AS Recorder,
		|		OBEntry.Ref.Organization AS Organization
		|	FROM
		|		Document.OBEntryGoods.Goods AS OBEntry
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = OBEntry.ItemsLocationAttributes
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND OBEntry.Ref.PostInCostAccounting
		|		AND NOT OBEntry.Ref.RecordInOperationalAccounting
		|		AND OBEntry.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND OBEntry.Ref.Organization IN(&CompanyArray)
		|		AND OBEntry.Ref.Posted
		|	) AS Goods
		|INDEX BY
		|	Recorder,
		|	Organization
		|;
		// We select the documents that have the destination specified in the cost movements.
		|SELECT DISTINCT
		|	InventoryCost.Recorder AS Recorder,
		|	InventoryCost.Organization AS Organization
		|
		|INTO CostRegisteredRecordsWithAssignments
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|	INNER JOIN DocumentsWithAssignments AS DocumentsWithAssignments
		|		ON DocumentsWithAssignments.Recorder = InventoryCost.Recorder
		|		AND DocumentsWithAssignments.Organization = InventoryCost.Organization
		|	INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|		ON AnalyticsWithAssignments.Ref = InventoryCost.ItemsLocationAttributes
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND InventoryCost.Organization IN(&CompanyArray)
		|	AND NOT InventoryCost.CalculationOfCost
		|	AND NOT InventoryCost.LotCalculation
		|INDEX BY
		|	Recorder,
		|	Organization
		|;
		|SELECT DISTINCT
		|	InventoryCost.Recorder AS Recorder,
		|	InventoryCost.Organization AS Organization
		|
		|INTO ThereAreCostRegisteredRecords
		|FROM
		|	AccumulationRegister.InventoryCost AS InventoryCost
		|	INNER JOIN DocumentsWithAssignments AS DocumentsWithAssignments
		|		ON DocumentsWithAssignments.Recorder = InventoryCost.Recorder
		|		AND DocumentsWithAssignments.Organization = InventoryCost.Organization
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND InventoryCost.Organization IN(&CompanyArray)
		|	AND NOT InventoryCost.CalculationOfCost
		|	AND NOT InventoryCost.LotCalculation
		|INDEX BY
		|	Recorder,
		|	Organization
		|;
		// We select documents that have a purpose specified in the movements according to operational registers,
		// and the purpose is not specified in the cost accounting movements (there are no movements with the specified purpose).
		|SELECT DISTINCT
		|	""InventoryCost""			AS RegisterName,
		|	DocumentsWithAssignments.Recorder	AS Ref,
		|	DocumentsWithAssignments.Organization	AS Organization,
		|	1									AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	DocumentsWithAssignments AS DocumentsWithAssignments
		// We perform verification only if there are movements at the cost of goods. 
		|	INNER JOIN ThereAreCostRegisteredRecords AS ThereAreCostRegisteredRecords
		|		ON ThereAreCostRegisteredRecords.Recorder = DocumentsWithAssignments.Recorder
		|		AND ThereAreCostRegisteredRecords.Organization = DocumentsWithAssignments.Organization
		|	LEFT JOIN CostRegisteredRecordsWithAssignments AS InventoryCost
		|		ON InventoryCost.Recorder = DocumentsWithAssignments.Recorder
		|		AND InventoryCost.Organization = DocumentsWithAssignments.Organization
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND InventoryCost.Recorder IS NULL
		// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
		// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
		|	AND NOT DocumentsWithAssignments.Organization IN (&MediumSlipOrganizations)
		|;
		|DROP AnalyticsWithAssignments;
		|DROP ZeroSumDeclarations;
		|DROP TTInputOfBalancesWithCostAccountingTurned;
		|DROP DocumentsWithAssignments;
		|DROP ThereAreCostRegisteredRecords;
		|DROP CostRegisteredRecordsWithAssignments
		|";
EndFunction

// We select documents that do not have a destination specified in the movements in the inventory accounting analytics.
//
// Returns:
//	String - Query text
//
Function RequestTextEnablingRevenueAndCostOfSalesAccountingByDestination() Export
	Return "
		|SELECT
		|	Keys.Ref AS Ref
		|INTO AnalyticsWithAssignments
		|FROM
		|	Catalog.InventoryLocationAttributeKeys AS Keys
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND &UseCostAccounting
		|	AND Keys.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|	AND Keys.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|INDEX BY
		|	Ref
		|;
		|SELECT DISTINCT
		|	RevenueAndCOGS.Recorder AS Recorder,
		|	Analysts.Organization AS Organization
		|INTO SalesDocuments
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
		|		ON RevenueAndCOGS.AccountingDimensionByPartners = Analysts.Ref
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND &UseCostAccounting
		|	AND RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Analysts.Organization IN (&CompanyArray)
		|	AND NOT RevenueAndCOGS.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|		VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|;
		// We select the sales documents that have an appointment indicated in the movements of the operational registers.
		|SELECT DISTINCT
		|	Goods.Recorder AS Recorder,
		|	Goods.Organization AS Organization
		|INTO DocumentsWithAssignments
		|FROM (
		|	SELECT DISTINCT
		|		CompanyGoods.Recorder AS Recorder,
		|		CompanyGoods.Organization AS Organization
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		|		INNER JOIN SalesDocuments AS SalesDocuments
		|			ON SalesDocuments.Recorder = CompanyGoods.Recorder
		|			AND SalesDocuments.Organization = CompanyGoods.Organization
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = CompanyGoods.ItemsLocationAttributes
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND CompanyGoods.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND CompanyGoods.Organization IN(&CompanyArray)
		|
		|	UNION ALL
		|	SELECT DISTINCT
		|		CompanyGoodsForTransfer.Recorder AS Recorder,
		|		CompanyGoodsForTransfer.SellerInventoryOwnerAttribute.Organization AS Organization
		|	FROM
		|		AccumulationRegister.CompanyGoodsForTransfer AS CompanyGoodsForTransfer
		|		INNER JOIN SalesDocuments AS SalesDocuments
		|			ON SalesDocuments.Recorder = CompanyGoodsForTransfer.Recorder
		|			AND SalesDocuments.Organization = CompanyGoodsForTransfer.SellerInventoryOwnerAttribute.Organization
		|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|			ON AnalyticsWithAssignments.Ref = CompanyGoodsForTransfer.ItemsLocationAttributes
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND CompanyGoodsForTransfer.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND CompanyGoodsForTransfer.SellerInventoryOwnerAttribute.Organization IN(&CompanyArray)
		|
		|	UNION ALL
		|	SELECT DISTINCT
		|		MaterialsAndWorksInProduction.Recorder AS Recorder,
		|		MaterialsAndWorksInProduction.Organization AS Organization
		|	FROM
		|		AccumulationRegister.MaterialsAndWorksInProduction AS MaterialsAndWorksInProduction
		|		INNER JOIN SalesDocuments AS SalesDocuments
		|			ON SalesDocuments.Recorder = MaterialsAndWorksInProduction.Recorder
		|			AND SalesDocuments.Organization = MaterialsAndWorksInProduction.Organization
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND MaterialsAndWorksInProduction.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND MaterialsAndWorksInProduction.Organization IN(&CompanyArray)
		|		AND MaterialsAndWorksInProduction.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		ReportToMaterialProvider2_5.Ref      AS Recorder,
		|		ReportToMaterialProvider2_5.Organization AS Organization
		|	FROM
		|		Document.ReportToMaterialProvider2_5 AS ReportToMaterialProvider2_5
		|	WHERE
		|		&KeepRecordsOfInventoryCostByAssignments
		|		AND &UseCostAccounting
		|		AND ReportToMaterialProvider2_5.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND ReportToMaterialProvider2_5.Organization IN(&CompanyArray)
		|		AND ReportToMaterialProvider2_5.Posted
		|
		|	) AS Goods
		|INDEX BY
		|	Recorder,
		|	Organization
		|;
		// We select the documents that have the destination specified in the revenue and cost of sales movements.
		|SELECT DISTINCT
		|	RevenueAndCOGS.Recorder AS Recorder,
		|	Analysts.Organization AS Organization
		|
		|INTO CostRegisteredRecordsWithAssignments
		|FROM
		|	AccumulationRegister.RevenueAndCOGS AS RevenueAndCOGS
		|	INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Analysts
		|		ON RevenueAndCOGS.AccountingDimensionByPartners = Analysts.Ref
		|	INNER JOIN DocumentsWithAssignments AS DocumentsWithAssignments
		|		ON DocumentsWithAssignments.Recorder = RevenueAndCOGS.Recorder
		|		AND DocumentsWithAssignments.Organization = Analysts.Organization
		|	INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
		|		ON AnalyticsWithAssignments.Ref = RevenueAndCOGS.ItemsLocationAttributes
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND RevenueAndCOGS.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND Analysts.Organization IN(&CompanyArray)
		|	AND RevenueAndCOGS.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|	AND RevenueAndCOGS.BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		|INDEX BY
		|	Recorder,
		|	Organization
		|;
		// We select documents that have a purpose specified in the movements according to operational registers
		// , and the purpose is not specified in the movement of revenue and cost of sales (there are no movements with the specified purpose).
		|SELECT DISTINCT
		|	""RevenueAndCOGS""		AS RegisterName,
		|	DocumentsWithAssignments.Recorder	AS Ref,
		|	DocumentsWithAssignments.Organization	AS Organization,
		|	1									AS ErrorCode
		|INTO TTRecordersWithIncorrectRegisteredRecords
		|FROM
		|	DocumentsWithAssignments AS DocumentsWithAssignments
		|	LEFT JOIN CostRegisteredRecordsWithAssignments AS InventoryCost
		|		ON InventoryCost.Recorder = DocumentsWithAssignments.Recorder
		|		AND InventoryCost.Organization = DocumentsWithAssignments.Organization
		|WHERE
		|	&KeepRecordsOfInventoryCostByAssignments
		|	AND InventoryCost.Recorder IS NULL
		// When using a medium-sliding cost, Registered Records checks are not performed, because the mechanism for holding a document
		// in one register does not take into account that Registered Records can be generated simultaneously in corresponding registers. 
		|	AND NOT DocumentsWithAssignments.Organization IN (&MediumSlipOrganizations)
		|;
		|DROP AnalyticsWithAssignments;
		|DROP SalesDocuments;
		|DROP DocumentsWithAssignments;
		|DROP CostRegisteredRecordsWithAssignments
		|";
EndFunction

#EndRegion

#EndRegion
