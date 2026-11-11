#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the props "Party" in the tabular part.
// If necessary, new elements of the batch directory are created.
//
// Parameters:
//	Object - DocumentObject.InventoryConsumption, DocumentObject.OBEntry, DocumentObject.OBEntryInventoryInOperation - The document in which the batch is filled in.
//  WriteMode - DocumentWriteMode - The current document recording mode.
//
Procedure FillInBatches(Object, WriteMode) Export
	
	If WriteMode <> DocumentWriteMode.Posting
		And WriteMode <> DocumentWriteMode.UndoPosting Then
		Return;
	EndIf;
	
	BeginningOfApplicationOfFSBU5 = '000101010000';
	BeginningOfApplicationOfFSBU5 = LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019();
	If TypeOf(Object) = Type("DocumentObject.InventoryConsumption") Then
		
		TabularSection = Object.Goods; // Document.InventoryConsumption.Goods
		DocumentData = TabularSection.Unload();

		DocumentData.Columns.Add("StartDateOfOperation", New TypeDescription("Date"));
		DocumentData.Columns.Add("ServiceLife", Common.TypeDescriptionNumber(5));
		
		DocumentData.FillValues(BegOfMonth(Object.Date), "StartDateOfOperation");
	ElsIf TypeOf(Object) = Type("DocumentObject.RecordInventoryInOperation") Then
		
		TabularSection = Object.Goods; // Document.RecordInventoryInOperation.Goods
		DocumentData = TabularSection.Unload();

		DocumentData.Columns.Add("StartDateOfOperation", New TypeDescription("Date"));
		DocumentData.Columns.Add("FixedAsset", New TypeDescription("CatalogRef.Assets"));
		DocumentData.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
		DocumentData.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
		
		DocumentData.FillValues(BegOfMonth(Object.Date), "StartDateOfOperation");
	ElsIf TypeOf(Object) = Type("DocumentObject.OBEntry") Then
		
		TabularSection = Object.InventoryInOperation;
		DocumentData = TabularSection.Unload();

		DocumentData.Columns.Add("ServiceLife", Common.TypeDescriptionNumber(5));
		DocumentData.Columns.Add("FixedAsset", New TypeDescription("CatalogRef.Assets"));
	ElsIf TypeOf(Object) = Type("DocumentObject.OBEntryInventoryInOperation") Then
		
		TabularSection = Object.InventoryInOperation;
		DocumentData = TabularSection.Unload();
		
		DocumentData.Columns.Add("ServiceLife", Common.TypeDescriptionNumber(5));

	Else
		
		ErrorText = StrTemplate(NStr("vi = 'Đối với chứng từ ""%1"" không cần điền lô hàng';
									|ru = 'Для документа ""%1"" не предусмотрено заполнение партий';
									|en = 'Cannot fill in lots in the ""%1"" document'; fa = 'Cannot fill in lots in the ""%1"" document';
									|it = 'Per il documento ""%1"" non è prevista la compilazione del lotto';
									|pl = 'Dla dokumentu ""%1"" nie jest przewidziane wypełnienie partii';
									|tr = '""%1"" belgesinin gruplar halinde doldurulması için herhangi bir hüküm bulunmamaktadır'"), TypeOf(Object));

		Raise ErrorText;
		
	EndIf;
	ClearInventoryNumber(DocumentData);
	ListOfParties = New ValueTable();
	ListOfParties.Columns.Add("Lot", New TypeDescription("CatalogRef.LotsOfInventoryInOperation"));
	For Each TSRow In DocumentData Do
		If ValueIsFilled(TSRow.Lot) Then
			NewRow = ListOfParties.Add();
			NewRow.Lot = TSRow.Lot;
		EndIf;
	EndDo;
	
	Block = New DataLock;
	
	LockItem = Block.Add("Catalog.LotsOfInventoryInOperation");
	LockItem.DataSource = DocumentData;
	LockItem.UseFromDataSource("OperationCategory", "OperationCategory");
	LockItem.UseFromDataSource("StartDateOfOperation", "StartDateOfOperation");
	LockItem.UseFromDataSource("AssetID", "AssetID");
	
	If Object.Date < BeginningOfApplicationOfFSBU5 Then
		LockItem.UseFromDataSource("ExpenseItem", "ExpenseItem");
		LockItem.UseFromDataSource("DimensionOfExpenses", "DimensionOfExpenses");
	EndIf;
	LockItem = Block.Add("AccumulationRegister.InventoryInOperation");
	LockItem.DataSource = ListOfParties;
	LockItem.UseFromDataSource("Lot", "Lot");
	Block.Lock();
	
	QueryText = 
	"SELECT
	|	CAST(Table.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(Table.StartDateOfOperation AS DATE) AS StartDateOfOperation,
	|	CAST(Table.OperationCategory AS Catalog.OperationCategories) AS OperationCategory,
	|	Table.AssetID AS AssetID,
	|	CAST(Table.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems) AS ExpenseItem,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.ServiceLife AS ServiceLife,
	|	CAST(Table.Lot AS Catalog.LotsOfInventoryInOperation) AS Lot
	|	,CAST(Table.FixedAsset AS Catalog.Assets) AS FixedAsset
	|
	|INTO DocumentData
	|
	|FROM
	|	&DocumentData AS Table
	|
	|INDEX BY
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(Table.StartDateOfOperation, MONTH) AS StartDateOfOperation,
	|
	|	CASE
	|		WHEN Table.ServiceLife <> 0
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DATEADD(Table.StartDateOfOperation, MONTH, Table.ServiceLife), MONTH), DAY)
	|		WHEN ISNULL(Table.OperationCategory.ServiceLife, 0) <> 0
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DATEADD(Table.StartDateOfOperation, MONTH, Table.OperationCategory.ServiceLife), MONTH), DAY)
	|		ELSE DATETIME(1,1,1)
	|	END AS CompletionDate_,
	|
	|	CASE
	|		WHEN Table.ServiceLife <> 0
	|			THEN Table.ServiceLife
	|		ELSE Table.OperationCategory.ServiceLife
	|	END AS ServiceLife,
	|
	|	Table.OperationCategory AS OperationCategory,
	|	Table.Lot AS Lot
	|	,Table.FixedAsset AS FixedAsset
	|
	|INTO LinesThatDoNotRequireUpdating
	|
	|FROM
	|	DocumentData AS Table
	|
	|		INNER JOIN Catalog.LotsOfInventoryInOperation AS CatalogOfLots
	|		ON CatalogOfLots.Ref = Table.Lot
	|
	|WHERE
	|	&FillInBatches
	|
	|	AND NOT CatalogOfLots.DeletionMark
	|	AND CatalogOfLots.Lot258
	|	AND CatalogOfLots.OperationCategory = Table.OperationCategory
	|
	|	AND (CatalogOfLots.ServiceLife = Table.ServiceLife
	|			AND Table.ServiceLife <> 0
	|		OR CatalogOfLots.ServiceLife = ISNULL(Table.OperationCategory.ServiceLife, 0)
	|			AND Table.ServiceLife = 0)
	|
	|	AND CatalogOfLots.StartDateOfOperation = Table.StartDateOfOperation
	|
	|	AND (Table.OperationCategory.AccountAsGroupFA
	|			AND CatalogOfLots.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|			AND (CatalogOfLots.FixedAsset = Table.FixedAsset
	|					OR Table.FixedAsset = VALUE(Catalog.Assets.EmptyRef))
	|		OR NOT Table.OperationCategory.AccountAsGroupFA
	|			AND CatalogOfLots.FixedAsset = VALUE(Catalog.Assets.EmptyRef))
	|
	|	AND NOT (Table.StartDateOfOperation < &BeginningOfApplicationOfFSBU5
	|			AND Table.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.ByAssetActivity)
	|			AND Table.OperationCategory.StocktakingRecord
	|			AND CatalogOfLots.AssetID <> Table.AssetID)
	|
	|	AND (&Date >= &BeginningOfApplicationOfFSBU5
	|		OR Table.ExpenseItem = CatalogOfLots.ExpenseItem
	|			AND Table.DimensionOfExpenses = CatalogOfLots.DimensionOfExpenses)
	|
	|
	|INDEX BY
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(Table.StartDateOfOperation, MONTH) AS StartDateOfOperation,
	|
	|	CASE
	|		WHEN Table.ServiceLife <> 0
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DATEADD(Table.StartDateOfOperation, MONTH, Table.ServiceLife), MONTH), DAY)
	|		WHEN ISNULL(Table.OperationCategory.ServiceLife, 0) <> 0
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DATEADD(Table.StartDateOfOperation, MONTH, Table.OperationCategory.ServiceLife), MONTH), DAY)
	|		ELSE DATETIME(1,1,1)
	|	END AS CompletionDate_,
	|
	|	CASE
	|		WHEN Table.ServiceLife <> 0
	|			THEN Table.ServiceLife
	|		ELSE Table.OperationCategory.ServiceLife
	|	END AS ServiceLife,
	|
	|	CASE
	|		WHEN Table.StartDateOfOperation < &BeginningOfApplicationOfFSBU5
	|				AND Table.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.ByAssetActivity)
	|				AND Table.OperationCategory.StocktakingRecord
	|			THEN Table.AssetID
	|		WHEN TRUE
	|			THEN """"
	|	END AS AssetID,
	|	Table.OperationCategory AS OperationCategory,
	|	Table.Lot AS Lot
	|	,Table.ExpenseItem AS ExpenseItem
	|	,Table.DimensionOfExpenses AS DimensionOfExpenses
	|	,Table.FixedAsset AS FixedAsset
	|
	|INTO LinesRequiringUpdating
	|
	|FROM
	|	DocumentData AS Table
	|
	|WHERE
	|	&FillInBatches
	|	AND NOT Table.LineNumber IN (
	|		SELECT
	|			LinesThatDoNotRequireUpdating.LineNumber
	|		FROM
	|			LinesThatDoNotRequireUpdating)
	|
	|INDEX BY
	|	Lot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// In the first request, batches are selected taking into account the OS specified in the document
	|SELECT
	|	CatalogOfLots.Ref AS Ref,
	|	CatalogOfLots.DeletionMark AS DeletionMark,
	|	CatalogOfLots.OperationCategory AS OperationCategory,
	|	CatalogOfLots.ServiceLife AS ServiceLife,
	|	CatalogOfLots.StartDateOfOperation AS StartDateOfOperation,
	|	CatalogOfLots.CompletionDate_ AS CompletionDate_,
	|	CatalogOfLots.FixedAsset AS FixedAsset
	|
	|INTO AllSuitableBatchesTakingIntoAccountOS
	|	
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS CatalogOfLots
	|WHERE
	|	CatalogOfLots.Lot258
	|	AND CatalogOfLots.OperationCategory.AccountAsGroupFA
	|	AND CatalogOfLots.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|	AND (CatalogOfLots.OperationCategory, 
	|		CatalogOfLots.ServiceLife, 
	|		CatalogOfLots.StartDateOfOperation, 
	|		CatalogOfLots.CompletionDate_, 
	|		CatalogOfLots.FixedAsset) IN (
	|
	|		SELECT
	|			LinesRequiringUpdating.OperationCategory AS OperationCategory,
	|			LinesRequiringUpdating.ServiceLife AS ServiceLife,
	|			LinesRequiringUpdating.StartDateOfOperation AS StartDateOfOperation,
	|			LinesRequiringUpdating.CompletionDate_ AS CompletionDate_,
	|			LinesRequiringUpdating.FixedAsset AS FixedAsset
	|		FROM
	|			LinesRequiringUpdating AS LinesRequiringUpdating
	|		WHERE
	|			LinesRequiringUpdating.FixedAsset <> VALUE(Catalog.Assets.EmptyRef))
	|
	|UNION ALL
	|
	// In the second query, one batch is selected for each group 
	|SELECT
	|	CatalogOfLots.Ref AS Ref,
	|	CatalogOfLots.DeletionMark AS DeletionMark,
	|	CatalogOfLots.OperationCategory AS OperationCategory,
	|	CatalogOfLots.ServiceLife AS ServiceLife,
	|	CatalogOfLots.StartDateOfOperation AS StartDateOfOperation,
	|	CatalogOfLots.CompletionDate_ AS CompletionDate_,
	|	CatalogOfLots.FixedAsset AS FixedAsset
	|	
	|FROM
	|	(SELECT
	|		CatalogOfLots.OperationCategory AS OperationCategory,
	|		CatalogOfLots.ServiceLife AS ServiceLife,
	|		CatalogOfLots.StartDateOfOperation AS StartDateOfOperation,
	|		CatalogOfLots.CompletionDate_ AS CompletionDate_,
	|		MAX(CatalogOfLots.FixedAsset) AS FixedAsset
	|	
	|	FROM
	|		Catalog.LotsOfInventoryInOperation AS CatalogOfLots
	|	WHERE
	|		CatalogOfLots.Lot258
	|		AND CatalogOfLots.OperationCategory.AccountAsGroupFA
	|		AND CatalogOfLots.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|		AND (CatalogOfLots.OperationCategory, 
	|			CatalogOfLots.ServiceLife, 
	|			CatalogOfLots.StartDateOfOperation, 
	|			CatalogOfLots.CompletionDate_) IN (
	|
	|			SELECT
	|				LinesRequiringUpdating.OperationCategory AS OperationCategory,
	|				LinesRequiringUpdating.ServiceLife AS ServiceLife,
	|				LinesRequiringUpdating.StartDateOfOperation AS StartDateOfOperation,
	|				LinesRequiringUpdating.CompletionDate_ AS CompletionDate_
	|			FROM
	|				LinesRequiringUpdating AS LinesRequiringUpdating
	|			WHERE
	|				LinesRequiringUpdating.FixedAsset = VALUE(Catalog.Assets.EmptyRef))
	|
	|	GROUP BY
	|		CatalogOfLots.OperationCategory,
	|		CatalogOfLots.ServiceLife,
	|		CatalogOfLots.StartDateOfOperation,
	|		CatalogOfLots.CompletionDate_
	|
	|	) AS BatchesWithOSInMind
	|
	|	INNER JOIN Catalog.LotsOfInventoryInOperation AS CatalogOfLots
	|	ON CatalogOfLots.OperationCategory = BatchesWithOSInMind.OperationCategory
	|		AND CatalogOfLots.ServiceLife = BatchesWithOSInMind.ServiceLife
	|		AND CatalogOfLots.StartDateOfOperation = BatchesWithOSInMind.StartDateOfOperation
	|		AND CatalogOfLots.Lot258
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(AllSuitableBatches.Ref) AS Ref,
	|	AllSuitableBatches.DeletionMark AS DeletionMark,
	|	AllSuitableBatches.OperationCategory AS OperationCategory,
	|	AllSuitableBatches.ServiceLife AS ServiceLife,
	|	AllSuitableBatches.StartDateOfOperation AS StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_ AS CompletionDate_,
	|	AllSuitableBatches.FixedAsset AS FixedAsset
	|
	|INTO SuitableBatchesTakingIntoAccountOS
	|	
	|FROM
	|	AllSuitableBatchesTakingIntoAccountOS AS AllSuitableBatches
	|	
	|WHERE
	|	NOT AllSuitableBatches.DeletionMark
	|
	|GROUP BY
	|	AllSuitableBatches.DeletionMark,
	|	AllSuitableBatches.OperationCategory,
	|	AllSuitableBatches.ServiceLife,
	|	AllSuitableBatches.StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_,
	|	AllSuitableBatches.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(AllSuitableBatches.Ref) AS Ref,
	|	AllSuitableBatches.DeletionMark AS DeletionMark,
	|	AllSuitableBatches.OperationCategory AS OperationCategory,
	|	AllSuitableBatches.ServiceLife AS ServiceLife,
	|	AllSuitableBatches.StartDateOfOperation AS StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_ AS CompletionDate_,
	|	AllSuitableBatches.FixedAsset AS FixedAsset
	|
	|FROM
	|	AllSuitableBatchesTakingIntoAccountOS AS AllSuitableBatches
	|
	|		LEFT JOIN AllSuitableBatchesTakingIntoAccountOS AS AllSuitableBatches2
	|		ON AllSuitableBatches2.Ref <> AllSuitableBatches.Ref
	|			AND NOT AllSuitableBatches2.DeletionMark
	|			AND AllSuitableBatches2.OperationCategory = AllSuitableBatches.OperationCategory
	|			AND AllSuitableBatches2.ServiceLife = AllSuitableBatches.ServiceLife
	|			AND AllSuitableBatches2.StartDateOfOperation = AllSuitableBatches.StartDateOfOperation
	|			AND AllSuitableBatches2.CompletionDate_ = AllSuitableBatches.CompletionDate_
	|			AND AllSuitableBatches2.FixedAsset = AllSuitableBatches.FixedAsset
	|
	|WHERE
	|	AllSuitableBatches.DeletionMark
	|	AND AllSuitableBatches2.Ref IS NULL
	|
	|GROUP BY
	|	AllSuitableBatches.DeletionMark,
	|	AllSuitableBatches.OperationCategory,
	|	AllSuitableBatches.ServiceLife,
	|	AllSuitableBatches.StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_,
	|	AllSuitableBatches.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogOfLots.Ref AS Ref,
	|	CatalogOfLots.DeletionMark AS DeletionMark,
	|	CatalogOfLots.OperationCategory AS OperationCategory,
	|	CatalogOfLots.ServiceLife AS ServiceLife,
	|	CatalogOfLots.AssetID AS AssetID,
	|	CatalogOfLots.StartDateOfOperation AS StartDateOfOperation,
	|	CatalogOfLots.CompletionDate_ AS CompletionDate_,
	|	CASE
	|		WHEN &Date < &BeginningOfApplicationOfFSBU5
	|			THEN CatalogOfLots.ExpenseItem
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE
	|		WHEN &Date < &BeginningOfApplicationOfFSBU5
	|			THEN CatalogOfLots.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses
	|
	|INTO AllSuitableBatchesExcludingOS
	|
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS CatalogOfLots
	|WHERE
	|	CatalogOfLots.Lot258
	|	AND NOT CatalogOfLots.OperationCategory.AccountAsGroupFA
	|	AND CatalogOfLots.FixedAsset = VALUE(Catalog.Assets.EmptyRef)
	|
	|	AND (CatalogOfLots.OperationCategory, 
	|		CatalogOfLots.ServiceLife, 
	|		CatalogOfLots.AssetID, 
	|		CatalogOfLots.StartDateOfOperation, 
	|		CatalogOfLots.CompletionDate_) IN (
	|
	|		SELECT
	|			LinesRequiringUpdating.OperationCategory AS OperationCategory,
	|			LinesRequiringUpdating.ServiceLife AS ServiceLife,
	|			LinesRequiringUpdating.AssetID AS AssetID,
	|			LinesRequiringUpdating.StartDateOfOperation AS StartDateOfOperation,
	|			LinesRequiringUpdating.CompletionDate_ AS CompletionDate_
	|		FROM
	|			LinesRequiringUpdating AS LinesRequiringUpdating)
	|
	|	AND (&Date >= &BeginningOfApplicationOfFSBU5
	|		OR (CatalogOfLots.ExpenseItem, CatalogOfLots.DimensionOfExpenses) IN (
	|
	|			SELECT
	|				LinesRequiringUpdating.ExpenseItem AS ExpenseItem,
	|				LinesRequiringUpdating.DimensionOfExpenses AS DimensionOfExpenses
	|			FROM
	|				LinesRequiringUpdating AS LinesRequiringUpdating))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(AllSuitableBatches.Ref) AS Ref,
	|	AllSuitableBatches.DeletionMark AS DeletionMark,
	|	AllSuitableBatches.OperationCategory AS OperationCategory,
	|	AllSuitableBatches.ServiceLife AS ServiceLife,
	|	AllSuitableBatches.AssetID AS AssetID,
	|	AllSuitableBatches.StartDateOfOperation AS StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_ AS CompletionDate_,
	|	AllSuitableBatches.ExpenseItem AS ExpenseItem,
	|	AllSuitableBatches.DimensionOfExpenses AS DimensionOfExpenses
	|
	|INTO SuitableBatchesExcludingOS
	|	
	|FROM
	|	AllSuitableBatchesExcludingOS AS AllSuitableBatches
	|	
	|WHERE
	|	NOT AllSuitableBatches.DeletionMark
	|
	|GROUP BY
	|	AllSuitableBatches.DeletionMark,
	|	AllSuitableBatches.OperationCategory,
	|	AllSuitableBatches.ServiceLife,
	|	AllSuitableBatches.AssetID,
	|	AllSuitableBatches.StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_,
	|	AllSuitableBatches.ExpenseItem,
	|	AllSuitableBatches.DimensionOfExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(AllSuitableBatches.Ref) AS Ref,
	|	AllSuitableBatches.DeletionMark AS DeletionMark,
	|	AllSuitableBatches.OperationCategory AS OperationCategory,
	|	AllSuitableBatches.ServiceLife AS ServiceLife,
	|	AllSuitableBatches.AssetID AS AssetID,
	|	AllSuitableBatches.StartDateOfOperation AS StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_ AS CompletionDate_,
	|	AllSuitableBatches.ExpenseItem AS ExpenseItem,
	|	AllSuitableBatches.DimensionOfExpenses AS DimensionOfExpenses
	|
	|FROM
	|	AllSuitableBatchesExcludingOS AS AllSuitableBatches
	|
	|		LEFT JOIN AllSuitableBatchesExcludingOS AS AllSuitableBatches2
	|		ON AllSuitableBatches2.Ref <> AllSuitableBatches.Ref
	|			AND NOT AllSuitableBatches2.DeletionMark
	|			AND AllSuitableBatches2.OperationCategory = AllSuitableBatches.OperationCategory
	|			AND AllSuitableBatches2.ServiceLife = AllSuitableBatches.ServiceLife
	|			AND AllSuitableBatches2.AssetID = AllSuitableBatches.AssetID
	|			AND AllSuitableBatches2.StartDateOfOperation = AllSuitableBatches.StartDateOfOperation
	|			AND AllSuitableBatches2.CompletionDate_ = AllSuitableBatches.CompletionDate_
	|			AND AllSuitableBatches2.ExpenseItem = AllSuitableBatches.ExpenseItem
	|			AND AllSuitableBatches2.DimensionOfExpenses = AllSuitableBatches.DimensionOfExpenses
	|
	|WHERE
	|	AllSuitableBatches.DeletionMark
	|	AND AllSuitableBatches2.Ref IS NULL
	|
	|GROUP BY
	|	AllSuitableBatches.DeletionMark,
	|	AllSuitableBatches.OperationCategory,
	|	AllSuitableBatches.ServiceLife,
	|	AllSuitableBatches.AssetID,
	|	AllSuitableBatches.StartDateOfOperation,
	|	AllSuitableBatches.CompletionDate_,
	|	AllSuitableBatches.ExpenseItem,
	|	AllSuitableBatches.DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Unused document batches
	|SELECT
	|	CatalogOfLots.Ref AS Ref,
	|	CatalogOfLots.DeletionMark AS DeletionMark,
	|	CatalogOfLots.OperationCategory AS OperationCategory,
	|	CatalogOfLots.ServiceLife AS ServiceLife,
	|	CatalogOfLots.StartDateOfOperation AS StartDateOfOperation,
	|	CatalogOfLots.CompletionDate_ AS CompletionDate_,
	|	CatalogOfLots.FixedAsset AS FixedAsset,
	|	CatalogOfLots.ExpenseItem AS ExpenseItem,
	|	CatalogOfLots.DimensionOfExpenses AS DimensionOfExpenses
	|
	|FROM
	|	Catalog.LotsOfInventoryInOperation AS CatalogOfLots
	|
	|WHERE
	|	CatalogOfLots.Lot258
	|
		// This is the batch in the document
	|	AND CatalogOfLots.Ref IN (
	|		SELECT
	|			DocumentData.Lot AS Lot
	|		FROM
	|			DocumentData AS DocumentData
	|
	|		UNION ALL
	|
	|		SELECT
	|			DocumentData.Lot AS Lot
	|		FROM
	|			Document.InventoryConsumption.Goods AS DocumentData
	|		WHERE
	|			DocumentData.Ref = &Ref
	|
	|		UNION ALL
	|
	|		SELECT
	|			DocumentData.Lot AS Lot
	|		FROM
	|			Document.RecordInventoryInOperation.Goods AS DocumentData
	|		WHERE
	|			DocumentData.Ref = &Ref
	|
	|		UNION ALL
	|
	|		SELECT
	|			DocumentData.Lot AS Lot
	|		FROM
	|			Document.OBEntryInventoryInOperation.InventoryInOperation AS DocumentData
	|		WHERE
	|			DocumentData.Ref = &Ref
	|
	|		UNION ALL
	|
	|		SELECT
	|			DocumentData.Lot AS Lot
	|		FROM
	|			Document.OBEntry.InventoryInOperation AS DocumentData
	|		WHERE
	|			DocumentData.Ref = &Ref)
	|
		// Not used in other documents
	|	AND NOT 1 IN (
	|		SELECT
	|			1
	|		FROM
	|			AccumulationRegister.InventoryInOperation AS InventoryInOperation
	|		WHERE
	|			InventoryInOperation.Recorder <> &Ref
	|			AND InventoryInOperation.Lot = CatalogOfLots.Ref)
	|
		// The batch will not be used in the document
	|	AND (NOT (CatalogOfLots.Ref) IN (
	|			SELECT
	|				SuitableBatches.Ref
	|			FROM
	|				SuitableBatchesTakingIntoAccountOS AS SuitableBatches)
	|
	|		AND NOT (CatalogOfLots.Ref) IN (
	|			SELECT
	|				SuitableBatches.Ref
	|			FROM
	|				SuitableBatchesExcludingOS AS SuitableBatches)
	|
	|		AND NOT (CatalogOfLots.Ref) IN (
	|			SELECT
	|				LinesThatDoNotRequireUpdating.Lot
	|			FROM
	|				LinesThatDoNotRequireUpdating AS LinesThatDoNotRequireUpdating)
	|
	|		OR NOT &FillInBatches)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuitableBatches.Ref AS Ref,
	|	SuitableBatches.DeletionMark AS DeletionMark,
	|	SuitableBatches.OperationCategory AS OperationCategory,
	|	SuitableBatches.ServiceLife AS ServiceLife,
	|	"""" AS AssetID,
	|	SuitableBatches.StartDateOfOperation AS StartDateOfOperation,
	|	SuitableBatches.CompletionDate_ AS CompletionDate_,
	|	SuitableBatches.FixedAsset AS FixedAsset,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses
	|FROM
	|	SuitableBatchesTakingIntoAccountOS AS SuitableBatches
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SuitableBatches.Ref AS Ref,
	|	SuitableBatches.DeletionMark AS DeletionMark,
	|	SuitableBatches.OperationCategory AS OperationCategory,
	|	SuitableBatches.ServiceLife AS ServiceLife,
	|	SuitableBatches.AssetID AS AssetID,
	|	SuitableBatches.StartDateOfOperation AS StartDateOfOperation,
	|	SuitableBatches.CompletionDate_ AS CompletionDate_,
	|	SuitableBatches.ExpenseItem AS ExpenseItem,
	|	SuitableBatches.DimensionOfExpenses AS DimensionOfExpenses
	|FROM
	|	SuitableBatchesExcludingOS AS SuitableBatches
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LinesRequiringUpdating.LineNumber AS LineNumber,
	|	LinesRequiringUpdating.OperationCategory AS OperationCategory,
	|	LinesRequiringUpdating.OperationCategory.AccountAsGroupFA AS AccountAsGroupFA,
	|	LinesRequiringUpdating.OperationCategory.OSGroup AS OSGroup,
	|	LinesRequiringUpdating.ServiceLife AS ServiceLife,
	|	LinesRequiringUpdating.AssetID AS AssetID,
	|	LinesRequiringUpdating.StartDateOfOperation AS StartDateOfOperation,
	|	LinesRequiringUpdating.CompletionDate_ AS CompletionDate_
	|	,LinesRequiringUpdating.FixedAsset AS FixedAsset
	|	,LinesRequiringUpdating.ExpenseItem AS ExpenseItem
	|	,LinesRequiringUpdating.DimensionOfExpenses AS DimensionOfExpenses
	|FROM
	|	LinesRequiringUpdating AS LinesRequiringUpdating";
	
	SetPrivilegedMode(True);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("DocumentData", DocumentData);
	Query.SetParameter("FillInBatches", WriteMode = DocumentWriteMode.Posting);
	Query.SetParameter("BeginningOfApplicationOfFSBU5", BeginningOfApplicationOfFSBU5);
	
	Result = Query.ExecuteBatch();
	
	BatchTableExcludingOS = Result[Result.UBound()-1].Unload();
	TableOfUnusedBatches = Result[Result.UBound()-3].Unload();
	BatchTableWithOS = Result[Result.UBound()-2].Unload();
	
	PartyDetailsUsed = "OperationCategory,ServiceLife,StartDateOfOperation,CompletionDate_,FixedAsset";
	StructureOfSearchWithOSInMind = New Structure(PartyDetailsUsed);
	BatchTableWithOS.Indexes.Add(PartyDetailsUsed);
	PartyDetailsUsed = "OperationCategory,ServiceLife,StartDateOfOperation,CompletionDate_,AssetID";
	If Object.Date < BeginningOfApplicationOfFSBU5 Then
		PartyDetailsUsed = PartyDetailsUsed + "," + "ExpenseItem,DimensionOfExpenses"
	EndIf;
	StructureOfSearchWithoutTakingIntoAccountOS = New Structure(PartyDetailsUsed);
	BatchTableExcludingOS.Indexes.Add(PartyDetailsUsed);
	BatchTableWithOS.Indexes.Add(PartyDetailsUsed);
	NamingParameters = New Structure("StartDateOfOperation,CompletionDate_,ServiceLife,OperationCategory");
	
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		
		TSRow = TabularSection[Selection.LineNumber - 1];
		
		BatchTable_ = BatchTableExcludingOS;
		TheStructureOfTheSearch = StructureOfSearchWithoutTakingIntoAccountOS;
		If Selection.AccountAsGroupFA Then
			BatchTable_ = BatchTableWithOS;
			If ValueIsFilled(Selection.FixedAsset) Then
				TheStructureOfTheSearch = StructureOfSearchWithOSInMind;
			Else
				TheStructureOfTheSearch = StructureOfSearchWithoutTakingIntoAccountOS;
			EndIf;
		EndIf;
		FillPropertyValues(TheStructureOfTheSearch, Selection);
		StringsList = BatchTable_.FindRows(TheStructureOfTheSearch);
		
		If StringsList.Count() = 0 Then
			
			// There is no necessary batch.
			// First, an unused batch is taken, if there is none, then a new batch is created.
			PartyObject = Undefined;
			If TableOfUnusedBatches.Count() <> 0 Then
				PartyObject = TableOfUnusedBatches[0].Ref.GetObject(); // CatalogObject.LotsOfInventoryInOperation
				PartyObject.FixedAsset = Catalogs.Assets.EmptyRef();
				PartyObject.DeletionMark = False;
				TableOfUnusedBatches.Delete(TableOfUnusedBatches[0]);
			EndIf;
			If PartyObject = Undefined Then
				PartyObject = Catalogs.LotsOfInventoryInOperation.CreateItem();
			EndIf;
			
			FillPropertyValues(PartyObject, TheStructureOfTheSearch);
			PartyObject.Description = GenerateName(PartyObject);
			If Selection.AccountAsGroupFA Then
				
				FillPropertyValues(NamingParameters, PartyObject);
				NameOfOS = FormNameOfGroupOS(NamingParameters);
				
				If Not ValueIsFilled(PartyObject.FixedAsset) Then
				
					FixedAsset = Catalogs.Assets.CreateItem();
					FixedAsset.OSType = Enums.FATypes.GroupFA;
					FixedAsset.Description = NameOfOS;
					FixedAsset.OSGroup = Selection.OSGroup;
					FixedAsset.Write();
					PartyObject.FixedAsset = FixedAsset.Ref;
					
				ElsIf Not ValueIsFilled(Selection.FixedAsset) Then
					
					// Updating Attributes only if an existing FA is not selected in the document
					FAAttributes = Common.ObjectAttributesValues(PartyObject.FixedAsset, "Description,OSGroup");
					If FAAttributes.Description <> NameOfOS
						Or FAAttributes.OSGroup <> Selection.OSGroup Then
						
						FixedAsset = PartyObject.FixedAsset.GetObject();
						FixedAsset.Description = NameOfOS;
						FixedAsset.OSGroup = Selection.OSGroup;
						FixedAsset.Write();
						
					EndIf;
					
				EndIf;
				
			EndIf;
			PartyObject.Lot258 = True;
			PartyObject.Write();
			
			BatchData = BatchTable_.Add();
			FillPropertyValues(BatchData, TheStructureOfTheSearch);
			BatchData.Ref = PartyObject.Ref;
			BatchData.DeletionMark = PartyObject.DeletionMark;
			If Selection.AccountAsGroupFA Then
				BatchData.FixedAsset = PartyObject.FixedAsset;
			EndIf;
		Else
			
			// There is the right batch.
			BatchData = StringsList[0];
			
		EndIf;
		
		If BatchData.DeletionMark Then
			PartyObject = BatchData.Ref.GetObject(); // CatalogObject.LotsOfInventoryInOperation
			PartyObject.Description = GenerateName(PartyObject);
			PartyObject.DeletionMark = False;
			PartyObject.Write();
		EndIf;
		
		TSRow.Lot = BatchData.Ref;
			
	EndDo;
	
	// Deleting unused batches.
	For Each BatchData In TableOfUnusedBatches Do
		If Not BatchData.DeletionMark Then
			PartyObject = BatchData.Ref.GetObject(); // CatalogObject.LotsOfInventoryInOperation
			PartyObject.SetDeletionMark(True);
		EndIf;
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	InventoryInOperationServerCall.ProcessingOfReceivingDataOnSelectionOfBatchOfGoodsInOperation(
		ChoiceData, 
		Parameters, 
		StandardProcessing);
		
	Return; // the UT has an empty handler
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

// Forms the name of the party.
// 
// Parameters:
//  Object - CatalogObject.LotsOfInventoryInOperation - Object
// 
// Returns:
//  String - Description
//
Function GenerateName(Object) Export
	
	CategoryName = Common.ObjectAttributeValue(Object.OperationCategory, "Description");
	
	If Object.ServiceLife <> 0 Then
		
		Description = StrTemplate(
					NStr("vi = '%1 (từ %2 đến %3)';
						|ru = '%1 (с %2 по %3)';
						|en = '%1 (from %2 to %3)'; fa = '%1 (from %2 to %3)';
						|it = '%1 (da %2 a %3)';
						|pl = '%1 (od %2 do %3)';
						|tr = '%1(%2''dan %3 kadar)'"),
					TrimAll(CategoryName),
					Format(Object.StartDateOfOperation, NStr("vi = 'ДФ=''МММ ""năm"" гггг''';
															|ru = 'ДФ=''МММ гггг ""г.""''';
															|en = 'DF=''MMM yyyy'''; fa = 'DF=''MMM yyyy''';
															|it = 'DF=''MMMM yyyy."""";';
															|pl = 'DF=''МММ yyyy ""r.""''';
															|tr = 'DF=''MMMM yyyy ""yıl.""'''")),
					Format(Object.CompletionDate_, NStr("vi = 'ДФ=''МММ ""năm"" гггг''';
														|ru = 'ДФ=''МММ гггг ""г.""''';
														|en = 'DF=''MMM yyyy'''; fa = 'DF=''MMM yyyy''';
														|it = 'DF=''MMMM yyyy."""";';
														|pl = 'DF=''МММ yyyy ""r.""''';
														|tr = 'DF=''MMMM yyyy ""yıl.""'''")));
					
	Else
		
		Description = StrTemplate(
					NStr("vi = '%1 (từ %2)';
						|ru = '%1 (с %2)';
						|en = '%1 (from %2)'; fa = '%1 (from %2)';
						|it = '%1 (da %2)';
						|pl = '%1 (od %2)';
						|tr = '(%2''den) %1'"),
					TrimAll(CategoryName),
					Format(Object.StartDateOfOperation, NStr("vi = 'ДФ=''МММ ""năm"" гггг''';
															|ru = 'ДФ=''МММ гггг ""г.""''';
															|en = 'DF=''MMM yyyy'''; fa = 'DF=''MMM yyyy''';
															|it = 'DF=''MMMM yyyy."""";';
															|pl = 'DF=''МММ yyyy ""r.""''';
															|tr = 'DF=''MMMM yyyy ""yıl.""'''")));
					
	EndIf;
	
	Return Description;
	
EndFunction

// Forms the name of the group OS.
// 
// Parameters:
//  Parameters - Structure - Contains:
//  	* StartDateOfOperation - Date -
//  	* CompletionDate_ - Date -
//  	* ServiceLife - Number -
//  	* OperationCategory - CatalogRef.OperationCategories -
// 
// Returns:
//  String - The name of the group OS.
Function FormNameOfGroupOS(Parameters) Export

	CategoryName = Common.ObjectAttributeValue(Parameters.OperationCategory, "Description");
	
	If Parameters.ServiceLife <> 0 Then
		
		Description = StrTemplate(
					NStr("vi = '%1 (từ %2 đến %3)';
						|ru = '%1 (с %2 по %3)';
						|en = '%1 (from %2 to %3)'; fa = '%1 (from %2 to %3)';
						|it = '%1 (da %2 a %3)';
						|pl = '%1 (od %2 do %3)';
						|tr = '%1(%2''dan %3 kadar)'"),
					TrimAll(CategoryName),
					Format(Parameters.StartDateOfOperation, NStr("vi = 'ДФ=''МММ ""năm"" гггг''';
																|ru = 'ДФ=''МММ гггг ""г.""''';
																|en = 'DF=''MMM yyyy'''; fa = 'DF=''MMM yyyy''';
																|it = 'DF=''MMMM yyyy."""";';
																|pl = 'DF=''МММ yyyy ""r.""''';
																|tr = 'DF=''MMMM yyyy ""yıl.""'''")),
					Format(Parameters.CompletionDate_, NStr("vi = 'ДФ=''МММ ""năm"" гггг''';
															|ru = 'ДФ=''МММ гггг ""г.""''';
															|en = 'DF=''MMM yyyy'''; fa = 'DF=''MMM yyyy''';
															|it = 'DF=''MMMM yyyy."""";';
															|pl = 'DF=''МММ yyyy ""r.""''';
															|tr = 'DF=''MMMM yyyy ""yıl.""'''")));
					
	Else
		
		Description = StrTemplate(
					NStr("vi = '%1 (từ %2)';
						|ru = '%1 (с %2)';
						|en = '%1 (from %2)'; fa = '%1 (from %2)';
						|it = '%1 (da %2)';
						|pl = '%1 (od %2)';
						|tr = '(%2''den) %1'"),
					TrimAll(CategoryName),
					Format(Parameters.StartDateOfOperation, NStr("vi = 'ДФ=''МММ ""năm"" гггг''';
																|ru = 'ДФ=''МММ гггг ""г.""''';
																|en = 'DF=''MMM yyyy'''; fa = 'DF=''MMM yyyy''';
																|it = 'DF=''MMMM yyyy."""";';
																|pl = 'DF=''МММ yyyy ""r.""''';
																|tr = 'DF=''MMMM yyyy ""yıl.""'''")));
					
	EndIf;
	
	Return Description;
	
EndFunction

Procedure ClearInventoryNumber(DocumentData, DetailsOfCategories = Undefined)
	
	BeginningOfApplicationOfFSBU5 = LocalAccntingClientServer.BeginningOfApplicationFSBU5_2019();
	
	For Each RowData In DocumentData Do
		
		If RowData.StartDateOfOperation < BeginningOfApplicationOfFSBU5
			And ValueIsFilled(RowData.OperationCategory) Then
			
			If DetailsOfCategories = Undefined Then
				DetailsOfCategories = DetailsOfCategories(DocumentData);
			EndIf;
			
			CategoryProperties = DetailsOfCategories.Get(RowData.OperationCategory);
			If CategoryProperties.MethodOfRepaymentOfCostOfAC <> Enums.WaysToRepayCostOfInventory.ByAssetActivity
				Or Not CategoryProperties.StocktakingRecord Then
				RowData.AssetID = "";
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function DetailsOfCategories(DocumentData)
	
	ListOfCategories = New Array;
	For Each RowData In DocumentData Do
		If ValueIsFilled(RowData.OperationCategory) Then
			ListOfCategories.Add(RowData.OperationCategory);
		EndIf;
	EndDo;
	
	DetailsOfCategories = Common.ObjectsAttributesValues(ListOfCategories, "MethodOfRepaymentOfCostOfAC,StocktakingRecord");
	
	Return DetailsOfCategories;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
