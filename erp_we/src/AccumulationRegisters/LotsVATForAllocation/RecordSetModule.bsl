#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If Not DataExchange.Load Then
		CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	VATLots.Period                         AS Period,
	|	VATLots.Recorder                    AS Recorder,
	|	VATLots.RecordType                    AS RecordType,
	|	VATLots.Organization                    AS Organization,
	|	VATLots.Department                  AS Department,
	|	VATLots.LineOfBusiness        AS LineOfBusiness,
	|	VATLots.ExpenseItem                 AS ExpenseItem,
	|	VATLots.DimensionOfExpenses              AS DimensionOfExpenses,
	|	VATLots.AssetsLiabilitiesDimension       AS AssetsLiabilitiesDimension,
	|	VATLots.Vendor                      AS Vendor,
	|	VATLots.ExpenseReceiptDocument    AS ExpenseReceiptDocument,
	|	VATLots.VATActivityType             AS VATActivityType,
	|	VATLots.AssetTaxClass                    AS AssetTaxClass,
	|	VATLots.VATRate                      AS VATRate,
	|	VATLots.CorVATActivityTypes          AS CorVATActivityTypes,
	|	VATLots.DocumentSalesOfGoodsAndServices             AS DocumentSalesOfGoodsAndServices,
	|	VATLots.ExpenseItem_        AS ExpenseItem_,
	|	VATLots.ExpensesPostingDimension     AS ExpensesPostingDimension,
	|	VATLots.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VATLots.FinRecordID         AS FinRecordID,
	|	VATLots.ReversingEntry                         AS ReversingEntry,
	|	VATLots.LocalCost                  AS LocalCost,
	|	VATLots.VATLocal                        AS VATLocal,
	|	VATLots.VATManag                         AS VATManag
	|INTO LotsVATForAllocationBeforeWrite
	|FROM
	|	AccumulationRegister.LotsVATForAllocation AS VATLots
	|WHERE
	|	VATLots.Recorder = &Recorder
	|");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	ThisIsCancellationOfEvent = (AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting);
	Query.SetParameter("ThisIsCancellationOfEvent", ThisIsCancellationOfEvent);
	
	Query.Execute();

EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// Verification of fraud.Loading is not required, because this object in the RIB must create tasks when writing.
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	ArrayOfRequestTexts = New Array;
	
	TextOfChangeTable = 
	"SELECT
	|	Table.Period                         AS Period,
	|	Table.Recorder                    AS Recorder,
	|	Table.RecordType                    AS RecordType,
	|	Table.Organization                    AS Organization,
	|	Table.Department                  AS Department,
	|	Table.LineOfBusiness        AS LineOfBusiness,
	|	Table.ExpenseItem                 AS ExpenseItem,
	|	Table.DimensionOfExpenses              AS DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension       AS AssetsLiabilitiesDimension,
	|	Table.Vendor                      AS Vendor,
	|	Table.ExpenseReceiptDocument    AS ExpenseReceiptDocument,
	|	Table.VATActivityType             AS VATActivityType,
	|	Table.AssetTaxClass                    AS AssetTaxClass,
	|	Table.VATRate                      AS VATRate,
	|	Table.CorVATActivityTypes          AS CorVATActivityTypes,
	|	Table.DocumentSalesOfGoodsAndServices             AS DocumentSalesOfGoodsAndServices,
	|	Table.ExpenseItem_        AS ExpenseItem_,
	|	Table.ExpensesPostingDimension     AS ExpensesPostingDimension,
	|	Table.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	Table.FinRecordID         AS FinRecordID,
	|	Table.ReversingEntry                         AS ReversingEntry,
	|	SUM(Table.LocalCost)           AS LocalCost,
	|	SUM(Table.VATLocal)                 AS VATLocal,
	|	SUM(Table.VATManag)                  AS VATManag
	|INTO TableOfChangesInNDSKDistributionTotal
	|FROM
	|	(SELECT
	|		Table.Period                         AS Period,
	|		Table.Recorder                    AS Recorder,
	|		Table.RecordType                    AS RecordType,
	|		Table.Organization                    AS Organization,
	|		Table.Department                  AS Department,
	|		Table.LineOfBusiness        AS LineOfBusiness,
	|		Table.ExpenseItem                 AS ExpenseItem,
	|		Table.DimensionOfExpenses              AS DimensionOfExpenses,
	|		Table.AssetsLiabilitiesDimension       AS AssetsLiabilitiesDimension,
	|		Table.Vendor                      AS Vendor,
	|		Table.ExpenseReceiptDocument    AS ExpenseReceiptDocument,
	|		Table.VATActivityType             AS VATActivityType,
	|		Table.AssetTaxClass                    AS AssetTaxClass,
	|		Table.VATRate                      AS VATRate,
	|		Table.CorVATActivityTypes          AS CorVATActivityTypes,
	|		Table.DocumentSalesOfGoodsAndServices             AS DocumentSalesOfGoodsAndServices,
	|		Table.ExpenseItem_        AS ExpenseItem_,
	|		Table.ExpensesPostingDimension     AS ExpensesPostingDimension,
	|		Table.BusinessTransactionSetting AS BusinessTransactionSetting,
	|		Table.FinRecordID         AS FinRecordID,
	|		Table.ReversingEntry                         AS ReversingEntry,
	|		Table.LocalCost                  AS LocalCost,
	|		Table.VATLocal                        AS VATLocal,
	|		Table.VATManag                         AS VATManag
	|	FROM
	|		LotsVATForAllocationBeforeWrite AS Table
	|
	|	UNION ALL
	|	
	|	SELECT
	|		VATLots.Period                         AS Period,
	|		VATLots.Recorder                    AS Recorder,
	|		VATLots.RecordType                    AS RecordType,
	|		VATLots.Organization                    AS Organization,
	|		VATLots.Department                  AS Department,
	|		VATLots.LineOfBusiness        AS LineOfBusiness,
	|		VATLots.ExpenseItem                 AS ExpenseItem,
	|		VATLots.DimensionOfExpenses              AS DimensionOfExpenses,
	|		VATLots.AssetsLiabilitiesDimension       AS AssetsLiabilitiesDimension,
	|		VATLots.Vendor                      AS Vendor,
	|		VATLots.ExpenseReceiptDocument    AS ExpenseReceiptDocument,
	|		VATLots.VATActivityType             AS VATActivityType,
	|		VATLots.AssetTaxClass                    AS AssetTaxClass,
	|		VATLots.VATRate                      AS VATRate,
	|		VATLots.CorVATActivityTypes          AS CorVATActivityTypes,
	|		VATLots.DocumentSalesOfGoodsAndServices             AS DocumentSalesOfGoodsAndServices,
	|		VATLots.ExpenseItem_        AS ExpenseItem_,
	|		VATLots.ExpensesPostingDimension     AS ExpensesPostingDimension,
	|		VATLots.BusinessTransactionSetting AS BusinessTransactionSetting,
	|		VATLots.FinRecordID         AS FinRecordID,
	|		VATLots.ReversingEntry                         AS ReversingEntry,
	|		-VATLots.LocalCost                 AS LocalCost,
	|		-VATLots.VATLocal                       AS VATLocal,
	|		-VATLots.VATManag                        AS VATManag
	|	FROM
	|		AccumulationRegister.LotsVATForAllocation AS VATLots
	|	WHERE
	|		VATLots.Recorder = &Recorder
	|
	|) AS Table
	|
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.RecordType,
	|	Table.Organization,
	|	Table.Department,
	|	Table.LineOfBusiness,
	|	Table.ExpenseItem,
	|	Table.DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension,
	|	Table.Vendor,
	|	Table.ExpenseReceiptDocument,
	|	Table.VATActivityType,
	|	Table.AssetTaxClass,
	|	Table.VATRate,
	|	Table.CorVATActivityTypes,
	|	Table.DocumentSalesOfGoodsAndServices,
	|	Table.ExpenseItem_,
	|	Table.ExpensesPostingDimension,
	|	Table.BusinessTransactionSetting,
	|	Table.FinRecordID,
	|	Table.ReversingEntry
	|HAVING
	|	SUM(Table.LocalCost) <> 0
	|	OR SUM(Table.VATLocal) <> 0
	|	OR SUM(Table.VATManag) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period                         AS Period,
	|	Table.Recorder                    AS Recorder,
	|	Table.Organization                    AS Organization,
	|	Table.Department                  AS Department,
	|	Table.LineOfBusiness        AS LineOfBusiness,
	|	Table.ExpenseItem                 AS ExpenseItem,
	|	Table.ExpenseItem.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	Table.DimensionOfExpenses              AS DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension       AS AssetsLiabilitiesDimension,
	|	Table.Vendor                      AS Vendor,
	|	Table.ExpenseReceiptDocument    AS ExpenseReceiptDocument,
	|	Table.VATActivityType             AS VATActivityType,
	|	Table.AssetTaxClass                    AS AssetTaxClass,
	|	Table.VATRate                      AS VATRate,
	|	Table.CorVATActivityTypes          AS CorVATActivityTypes,
	|	Table.DocumentSalesOfGoodsAndServices             AS DocumentSalesOfGoodsAndServices,
	|	Table.ExpenseItem_        AS ExpenseItem_,
	|	Table.ExpensesPostingDimension     AS ExpensesPostingDimension,
	|	Table.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	Table.FinRecordID         AS FinRecordID,
	|	Table.LocalCost                  AS LocalCost,
	|	Table.VATLocal                        AS VATLocal,
	|	Table.VATManag                         AS VATManag
	|INTO ChangesTableLotsVATForAllocation
	|FROM
	|	TableOfChangesInNDSKDistributionTotal AS Table
	|WHERE
	|	Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Lots.Period AS Period,
	|	Lots.Organization AS Organization,
	|	Lots.VATActivityType AS VATActivityType,
	|	Lots.CorVATActivityTypes AS CorVATActivityTypes,
	|	Lots.ExpenseReceiptDocument AS TaxInvoice
	|INTO TTBatchChange
	|FROM
	|	TableOfChangesInNDSKDistributionTotal AS Lots
	|WHERE
	|	Lots.RecordType = VALUE(AccumulationRecordType.Expense)
	|";
	ArrayOfRequestTexts.Add(TextOfChangeTable);
	ArrayOfRequestTexts.Add("DROP LotsVATForAllocationBeforeWrite");
	ArrayOfRequestTexts.Add("DROP TableOfChangesInNDSKDistributionTotal");
	
	Query = New Query();
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();

	VATAccountingLocalization.CreateTasksForCreatingBookOfPurchasesSales(Query.TempTablesManager);
	
EndProcedure

#EndRegion

#EndIf
