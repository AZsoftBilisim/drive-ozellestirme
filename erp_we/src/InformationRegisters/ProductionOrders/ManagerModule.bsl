#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Code of procedures and functions

#EndRegion

#Region EventHandlers

// Code of procedures and functions

#EndRegion

#Region Internal

#Region ClosingOrder

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//	TempTablesManager - TempTablesManager - a manager containing tables of register changes.
//	TempTableName - String - name of the temporary table containing the changes.
//	CallingFromUpdateHandler - Boolean - indicates that the call is being made from the update handler.
//
Procedure CalculateStatus(TempTablesManager, TempTableName, CallingFromUpdateHandler = False) Export

	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	RECORDAUTONUMBER() AS RowIndex,
	|
	|	Plan.Products          AS Products,
	|	Plan.Characteristic        AS Characteristic,
	|	Plan.Warehouse                 AS Warehouse,
	|	Plan.Purpose            AS Purpose,
	|	Plan.ProductionOrder   AS ProductionOrder,
	|	Plan.KeyProducts      AS KeyProducts,
	|	Plan.LineNumber           AS LineNumber,
	|	Plan.BillOfMaterials          AS BillOfMaterials,
	|	Plan.DemandDate       AS DemandDate,
	|	Plan.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
	|	Plan.ProductionLotIDInProductGroup AS ProductionLotIDInProductGroup,
	|
	|	SUM(Plan.ToProduce)  AS Ordered
	|
	|INTO Plan
	|FROM
	|	InformationRegister.ProductionOrders AS Plan
	|
	|WHERE
	|	(Plan.Products, Plan.Characteristic, Plan.Warehouse, Plan.Purpose, Plan.ProductionOrder) IN
	|			(SELECT
	|				DD.Products,
	|				DD.Characteristic,
	|				DD.Warehouse,
	|				DD.Purpose,
	|				DD.ProductionOrder
	|			FROM
	|				ProductionOrdersChanges AS DD)
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.BillOfMaterials,
	|	Plan.DemandDate,
	|	Plan.DurationBeforeProductionIssue,
	|	Plan.ProductionLotIDInProductGroup,
	|	Plan.LineNumber
	|
	|HAVING
	|	SUM(Plan.ToProduce) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder
	|;
	|
	|SELECT
	|	RECORDAUTONUMBER() AS RowIndex,
	|
	|	Real.Products                    AS Products,
	|	Real.Characteristic                  AS Characteristic,
	|	Real.Warehouse                           AS Warehouse,
	|	Real.Purpose                      AS Purpose,
	|	Real.ProductionOrder             AS ProductionOrder,
	|	Real.KeyProducts                AS KeyProducts,
	|	Real.Stage                            AS Stage,
	|	Real.Lot                          AS Lot,
	|	UUID(Real.Lot) AS KeyLot,
	|	Real.Department                   AS Department,
	|	Real.ProductionLotIDInProductGroup     AS ProductionLotIDInProductGroup,
	|	
	|	Real.ReceiptOrder              AS ReceiptOrder,
	|	Real.DateOfReceipt                 AS DateOfReceipt,
	|
	|	CASE
	|		WHEN SUM(Real.ReverseKittingStarted) <> 0 OR SUM(Real.ReverseKittingCompleted) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS ThisIsDisassembly,
	|
	|	SUM(Real.Launched + Real.ReverseKittingStarted) AS Launched,
	|	SUM(Real.Done + Real.ReverseKittingCompleted)     AS Done
	|
	|INTO Real
	|FROM
	|	InformationRegister.ProductionOrders AS Real
	|
	|WHERE
	|	(Real.Products, Real.Characteristic, Real.Warehouse, Real.Purpose, Real.ProductionOrder) IN
	|			(SELECT
	|				Plan.Products,
	|				Plan.Characteristic,
	|				Plan.Warehouse,
	|				Plan.Purpose,
	|				Plan.ProductionOrder
	|			FROM
	|				Plan AS Plan)
	|
	|GROUP BY
	|	Real.Products,
	|	Real.Characteristic,
	|	Real.Warehouse,
	|	Real.Purpose,
	|	Real.ProductionOrder,
	|	Real.KeyProducts,
	|	Real.Stage,
	|	Real.DateOfReceipt,
	|	Real.ReceiptOrder,
	|	Real.Lot,
	|	Real.Department,
	|	Real.ProductionLotIDInProductGroup
	|
	|HAVING
	|	SUM(Real.Launched + Real.ReverseKittingStarted) > 0 OR SUM(Real.Done + Real.ReverseKittingCompleted) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder
	|;
	|
	|SELECT DISTINCT
	|	DD.ProductionOrder AS ProductionOrder,
	|	UUID(DD.ProductionOrder) AS DocumentID
	|FROM
	|	ProductionOrdersChanges AS DD
	|WHERE
	|	DD.ToProduceUpdate <> 0
	|	  OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			Plan AS Plan
	|		WHERE
	|			Plan.Products = DD.Products
	|			AND Plan.Characteristic = DD.Characteristic
	|			AND Plan.Warehouse = DD.Warehouse
	|			AND Plan.Purpose = DD.Purpose
	|			AND Plan.ProductionOrder = DD.ProductionOrder)
	|;
	|
	|SELECT
	|
	|	Plan.RowIndex AS RowIndex,
	|
	|	Plan.Products          AS Products,
	|	Plan.Characteristic        AS Characteristic,
	|	Plan.Warehouse                 AS Warehouse,
	|	Plan.Purpose            AS Purpose,
	|	Plan.ProductionOrder   AS ProductionOrder,
	|
	|	Plan.Ordered              AS Ordered
	|
	|FROM
	|	Plan AS Plan
	|
	|ORDER BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
		// we do not take into account the specification, because there cannot be several specifications for one analysis
	|	Plan.DemandDate,
	|	Plan.LineNumber
	|;
	|
	|SELECT
	|
	|	Real.RowIndex AS IndexOfReleaseLine,
	|
	|	Real.Products          AS Products,
	|	Real.Characteristic        AS Characteristic,
	|	Real.Warehouse                 AS Warehouse,
	|	Real.Purpose            AS Purpose,
	|	Real.ProductionOrder   AS ProductionOrder,
	|
	|	Real.Launched              AS Launched,
	|	Real.Done                AS Done
	|
	|FROM
	|	Real AS Real
	|
	|ORDER BY
	|	Real.Products,
	|	Real.Characteristic,
	|	Real.Warehouse,
	|	Real.Purpose,
	|	Real.ProductionOrder,
	|	CASE
	|		WHEN Real.ReceiptOrder = UNDEFINED THEN
	|			0
	|	ELSE
	|			1
	|	END,
	|	CASE
	|		WHEN Real.DateOfReceipt <> DATETIME(1,1,1) THEN
	|			0
	|	ELSE
	|			1
	|	END,
	|	Real.DateOfReceipt,
	|	Real.ReceiptOrder,
	|	Real.Stage
	|
	|";
	Query.Text = StrReplace(Query.Text, "ProductionOrdersChanges", TempTableName);
	
	QueryResult = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	
	Calculations = QueryResult[NumberOfPackages_-3].Unload();
	
	ClosingOrder = New ValueTable();
	ClosingOrder.Columns.Add("ProductionOrder", Metadata.InformationRegisters.OrderStructure.Dimensions.ProductionOrder.Type);
	ClosingOrder.Columns.Add("RowIndex", Common.TypeDescriptionNumber(10,0));
	ClosingOrder.Columns.Add("IndexOfReleaseLine", Common.TypeDescriptionNumber(10,0));
	ClosingOrder.Columns.Add("ReceiptOrder", Metadata.InformationRegisters.OrderStructure.Dimensions.ReceiptOrder.Type);
	ClosingOrder.Columns.Add("DateOfReceipt", Metadata.InformationRegisters.OrderStructure.Dimensions.DateOfReceipt.Type);
	ClosingOrder.Columns.Add("Launched", Common.TypeDescriptionNumber(15,3));
	ClosingOrder.Columns.Add("Done", Common.TypeDescriptionNumber(15,3));
	CloseOrderLines(QueryResult[NumberOfPackages_-2], QueryResult[NumberOfPackages_-1], ClosingOrder);

	OrderStructure.PutTableOfValuesInTemporaryTable(TempTablesManager, "ClosingOrder", ClosingOrder,,, "RowIndex");

	RecordOrderStatusCalculationResult(TempTablesManager, TempTableName, Calculations);
	
	If Not CallingFromUpdateHandler Then
		OrderStructure.StartCalculation();
	EndIf;
	
EndProcedure 

#EndRegion

#EndRegion

#Region Private

#Region ClosingOrder

Procedure CloseOrderLines(ResultItems, ResultOrderClosing, ClosingOrder)
	
	If ResultItems.IsEmpty() Or ResultOrderClosing.IsEmpty() Then
		Return;
	EndIf;
	
	ProductSelection_ = ResultItems.Select();
	SampleOrderClosing = ResultOrderClosing.Select();

	CompareValues = New CompareValues;
	ListOfDimensionFields = StrSplit("Products,Characteristic,Warehouse,Purpose,ProductionOrder", ",");
	Group = New Structure("Products,Characteristic,Warehouse,Purpose,ProductionOrder");
	
	ThereAreRecordsInSelection = ProductSelection_.Next() And SampleOrderClosing.Next();
	
	While ThereAreRecordsInSelection Do
		
		Ordered = ProductSelection_.Ordered;
		
		AvailableRunning = SampleOrderClosing.Launched;
		AvailableReady   = SampleOrderClosing.Done;
		
		While ThereAreRecordsInSelection
			And ProductSelection_.Products        = SampleOrderClosing.Products
			And ProductSelection_.Characteristic      = SampleOrderClosing.Characteristic
			And ProductSelection_.Warehouse               = SampleOrderClosing.Warehouse
			And ProductSelection_.Purpose          = SampleOrderClosing.Purpose
			And ProductSelection_.ProductionOrder = SampleOrderClosing.ProductionOrder Do
			
			Demand = ClosingOrder.Add();
			FillPropertyValues(Demand, ProductSelection_);
			FillPropertyValues(Demand, SampleOrderClosing);

			If AvailableReady > 0 And Ordered > 0 Then
				Allocated = Min(Ordered, AvailableReady);
				Demand.Done = Allocated;
				AvailableReady = AvailableReady - Allocated;
				Ordered = Ordered - Allocated;
			EndIf;
			
			If AvailableRunning > 0 And Ordered > 0 Then 
				Allocated = Min(Ordered, AvailableRunning);
				Demand.Launched = Allocated;
				AvailableRunning = AvailableRunning - Allocated;
				Ordered = Ordered - Allocated;
			EndIf;

			If Ordered = 0 Then
				ThereAreRecordsInSelection = ThereAreRecordsInSelection And ProductSelection_.Next();
				Ordered = ?(ThereAreRecordsInSelection, ProductSelection_.Ordered, -1);
			EndIf;
			
			If AvailableRunning = 0 And AvailableReady = 0 Then
				ThereAreRecordsInSelection = ThereAreRecordsInSelection And SampleOrderClosing.Next();
				AvailableRunning = ?(ThereAreRecordsInSelection, SampleOrderClosing.Launched, -1);
				AvailableReady   = ?(ThereAreRecordsInSelection, SampleOrderClosing.Done,   -1);
			EndIf;
			
		EndDo;
		
		If ThereAreRecordsInSelection Then
		
			Move = OrderStructure.CompareKeyFieldValues(ProductSelection_, SampleOrderClosing, ListOfDimensionFields, CompareValues);
			
			If Move > 0 Then
				FillPropertyValues(Group, ProductSelection_);
				ThereAreRecordsInSelection = SampleOrderClosing.FindNext(Group);
			Else
				FillPropertyValues(Group, SampleOrderClosing);
				ThereAreRecordsInSelection = ProductSelection_.FindNext(Group);
			EndIf;
			
		EndIf;
		
	EndDo;
EndProcedure

Procedure RecordOrderStatusCalculationResult(TempTablesManager, TempTableName, Calculations)
	
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
	For Each Calculation In Calculations Do
		
		Block = New DataLock();
		Block.Add("InformationRegister.OrderStructure").SetValue("KeySet", Calculation.DocumentID);
		Block.Lock();

		Query.Text =
		"SELECT
		|	Table.RowIndex AS RowIndex,
		|	SUM(Table.Done) AS Done
		|INTO ClosingOrderSummaryRecords
		|FROM
		|	ClosingOrder AS Table
		|
		|GROUP BY
		|	Table.RowIndex
		|
		|HAVING
		|	SUM(Table.Done) > 0
		|
		|INDEX BY
		|	RowIndex
		|;
		|SELECT
		|	Plan.Products                                                                   AS Products,
		|	Plan.Characteristic                                                                 AS Characteristic,
		|	Plan.Warehouse                                                                          AS Warehouse,
		|	Plan.Purpose                                                                     AS Purpose,
		|	Plan.ProductionOrder                                                            AS ProductionOrder,
		|	Plan.KeyProducts                                                               AS KeyProducts,
		|	Plan.KeyLot                                                                     AS KeyLot,
		|	Plan.LineKind                                                                      AS LineKind,
		|	Plan.ReceiptOrder                                                             AS ReceiptOrder,
		|	Plan.DateOfReceipt                                                                AS DateOfReceipt,
		|	Plan.KeySet                                                                      AS KeySet,
		|	Plan.DurationBeforeProductionIssue                                                          AS DurationBeforeProductionIssue,
		|	Plan.ProductionLotIDInProductGroup                                                    AS ProductionLotIDInProductGroup,
		|	Plan.Department                                                                  AS Department,
		|	Plan.Stage                                                                           AS Stage,
		|	Plan.SemiFinishedProductBOM                                                      AS SemiFinishedProductBOM,
		|	Plan.StructureAssignment                                                            AS StructureAssignment,
		|	Plan.Ordered                                                                       AS Ordered,
		|	Plan.AllocatedInFreeProductionLots                                                           AS AllocatedInFreeProductionLots,
		|	Plan.AllocatedInAssignedProductionLots                                                AS AllocatedInAssignedProductionLots,
		|	Plan.Done                                                                         AS Done
		|
		|INTO OrderStructureBeforeWrite
		|FROM
		|	InformationRegister.OrderStructure AS Plan
		|WHERE
		|	Plan.KeySet = &DocumentID
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder,
		|	KeyProducts
		|;
		|SELECT
		|	Plan.Products                                                                   AS Products,
		|	Plan.Characteristic                                                                 AS Characteristic,
		|	Plan.Warehouse                                                                          AS Warehouse,
		|	Plan.Purpose                                                                     AS Purpose,
		|	Plan.ProductionOrder                                                            AS ProductionOrder,
		|	Plan.KeyProducts                                                               AS KeyProducts,
		|	Plan.KeyLot                                                                     AS KeyLot,
		|	Plan.LineKind                                                                      AS LineKind,
		|	Plan.ReceiptOrder                                                             AS ReceiptOrder,
		|	Plan.DateOfReceipt                                                                AS DateOfReceipt,
		|	Plan.KeySet                                                                      AS KeySet,
		|	Plan.DurationBeforeProductionIssue                                                          AS DurationBeforeProductionIssue,
		|	MAX(Plan.ProductionLotIDInProductGroup)                                          AS ProductionLotIDInProductGroup,
		|	MAX(Plan.Department)                                                        AS Department,
		|	MAX(Plan.Stage)                                                                 AS Stage,
		|	MAX(Plan.SemiFinishedProductBOM)                                            AS SemiFinishedProductBOM,
		|	MAX(Plan.StructureAssignment)                                                  AS StructureAssignment,
		|	SUM(Plan.Ordered)                                                                AS Ordered,
		|	SUM(Plan.AllocatedInFreeProductionLots)                                                    AS AllocatedInFreeProductionLots,
		|	SUM(Plan.AllocatedInAssignedProductionLots)                                         AS AllocatedInAssignedProductionLots,
		|	SUM(Plan.Done)                                                                  AS Done
		|
		|INTO OrderStructureSetOfRecords
		|FROM
		|(	SELECT
		|		Plan.Products                                                                   AS Products,
		|		Plan.Characteristic                                                                 AS Characteristic,
		|		Plan.Warehouse                                                                          AS Warehouse,
		|		Plan.Purpose                                                                     AS Purpose,
		|		Plan.ProductionOrder                                                            AS ProductionOrder,
		|		Plan.KeyProducts                                                               AS KeyProducts,
		|		&DocumentID                                                             AS KeyLot,
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)             AS LineKind,
		|		NULL                                                                                AS ReceiptOrder,
		|		NULL                                                                                AS DateOfReceipt,
		|		&DocumentID                                                             AS KeySet,
		|		Plan.DurationBeforeProductionIssue                                                          AS DurationBeforeProductionIssue,
		|		Plan.ProductionLotIDInProductGroup                                                    AS ProductionLotIDInProductGroup,
		|		NULL                                                                                AS Department,
		|		NULL                                                                                AS Stage,
		|		Plan.BillOfMaterials                                                                   AS SemiFinishedProductBOM,
		|		Plan.Purpose                                                                     AS StructureAssignment,
		|		Plan.Ordered  - ISNULL(ClosingOrder.Done, 0)                                   AS Ordered,
		|		0                                                                                   AS AllocatedInFreeProductionLots,
		|		0                                                                                   AS AllocatedInAssignedProductionLots,
		|		ISNULL(ClosingOrder.Done, 0)                                                    AS Done
		|
		|	FROM
		|		Plan AS Plan
		|			LEFT JOIN ClosingOrderSummaryRecords AS ClosingOrder
		|			ON Plan.RowIndex = ClosingOrder.RowIndex
		|	WHERE
		|		Plan.ProductionOrder = &ProductionOrder
		|
		|	UNION ALL
		|
		|	SELECT
		|		Plan.Products                                                                   AS Products,
		|		Plan.Characteristic                                                                 AS Characteristic,
		|		Plan.Warehouse                                                                          AS Warehouse,
		|		Plan.Purpose                                                                     AS Purpose,
		|		Plan.ProductionOrder                                                            AS ProductionOrder,
		|		Plan.KeyProducts                                                               AS KeyProducts,
		|
		|		Real.KeyLot                                                                     AS KeyLot,
		|
		|		CASE
		|			WHEN Real.ThisIsDisassembly THEN
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly)
		|			ELSE
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts)
		|			END AS LineKind,
		|
		|		Real.ReceiptOrder                                                             AS ReceiptOrder,
		|		Real.DateOfReceipt                                                                AS DateOfReceipt,
		|
		|		&DocumentID                                                             AS KeySet,
		|		Plan.DurationBeforeProductionIssue                                                          AS DurationBeforeProductionIssue,
		|		Real.ProductionLotIDInProductGroup                                                    AS ProductionLotIDInProductGroup,
		|		Real.Department                                                                  AS Department,
		|		Real.Stage                                                                           AS Stage,
		|		NULL                                                                                AS SemiFinishedProductBOM,
		|		Real.Purpose                                                                     AS StructureAssignment,
		|		0                                                                                   AS Ordered,
		|		CASE
		|			WHEN Real.Purpose <> &EmptyAssignment
		|				THEN ClosingOrder.Launched
		|			ELSE 0
		|		END                                                                               AS AllocatedInAssignedProductionLots,
		|		CASE
		|			WHEN Real.Purpose = &EmptyAssignment
		|				THEN ClosingOrder.Launched
		|			ELSE 0
		|		END                                                                               AS AllocatedInFreeProductionLots,
		|		0                                                                                   AS Done
		|	FROM
		|		ClosingOrder AS ClosingOrder
		|	
		|			LEFT JOIN Plan AS Plan
		|			ON ClosingOrder.RowIndex = Plan.RowIndex
		|	
		|			LEFT JOIN Real AS Real
		|			ON ClosingOrder.IndexOfReleaseLine = Real.RowIndex
		|
		|	WHERE
		|		ClosingOrder.Launched > 0 AND ClosingOrder.ProductionOrder = &ProductionOrder
		|
		|	UNION ALL
		|
		|	SELECT
		|		Plan.Products                                                                   AS Products,
		|		Plan.Characteristic                                                                 AS Characteristic,
		|		Plan.Warehouse                                                                          AS Warehouse,
		|		Plan.Purpose                                                                     AS Purpose,
		|		Plan.ProductionOrder                                                            AS ProductionOrder,
		|		Plan.KeyProducts                                                               AS KeyProducts,
		|		Plan.KeyLot                                                                     AS KeyLot,
		|		Plan.LineKind                                                                      AS LineKind,
		|		Plan.ReceiptOrder                                                             AS ReceiptOrder,
		|		Plan.DateOfReceipt                                                                AS DateOfReceipt,
		|		Plan.KeySet                                                                      AS KeySet,
		|		Plan.DurationBeforeProductionIssue                                                          AS DurationBeforeProductionIssue,
		|		Plan.ProductionLotIDInProductGroup                                                    AS ProductionLotIDInProductGroup,
		|		Plan.Department                                                                  AS Department,
		|		Plan.Stage                                                                           AS Stage,
		|		Plan.SemiFinishedProductBOM                                                      AS SemiFinishedProductBOM,
		|		Plan.StructureAssignment                                                            AS StructureAssignment,
		|		Plan.Ordered                                                                       AS Ordered,
		|		Plan.AllocatedInFreeProductionLots                                                           AS AllocatedInFreeProductionLots,
		|		Plan.AllocatedInAssignedProductionLots                                                AS AllocatedInAssignedProductionLots,
		|		Plan.Done                                                                         AS Done
		|	FROM
		|		OrderStructureBeforeWrite AS Plan
		|
		|	WHERE
		|		Plan.ProductionOrder = &ProductionOrder 
		|		  AND TRUE NOT IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				ProductionOrdersChanges AS DD
		|			WHERE
		|				DD.Products          = Plan.Products
		|				AND DD.Characteristic      = Plan.Characteristic
		|				AND DD.Warehouse               = Plan.Warehouse
		|				AND DD.Purpose          = Plan.Purpose)
		|
		|) AS Plan
		|
		|GROUP BY
		|	Plan.Products,
		|	Plan.Characteristic,
		|	Plan.Warehouse,
		|	Plan.Purpose,
		|	Plan.ProductionOrder,
		|	Plan.KeyProducts,
		|	Plan.KeyLot,
		|	Plan.LineKind,
		|	Plan.ReceiptOrder,
		|	Plan.DateOfReceipt,
		|	Plan.KeySet,
		|	Plan.DurationBeforeProductionIssue
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder,
		|	KeyProducts
		|;
		|
		|SELECT
		|	Plan.Products                                                                   AS Products,
		|	Plan.Characteristic                                                                 AS Characteristic,
		|	Plan.Warehouse                                                                          AS Warehouse,
		|	Plan.Purpose                                                                     AS Purpose,
		|	Plan.ProductionOrder                                                            AS ProductionOrder,
		|	Plan.KeyProducts                                                               AS KeyProducts,
		|	Plan.KeyLot                                                                     AS KeyLot,
		|	Plan.LineKind                                                                      AS LineKind,
		|	Plan.ReceiptOrder                                                             AS ReceiptOrder,
		|	Plan.DateOfReceipt                                                                AS DateOfReceipt,
		|	Plan.KeySet                                                                      AS KeySet,
		|	Plan.DurationBeforeProductionIssue                                                          AS DurationBeforeProductionIssue,
		|	Plan.ProductionLotIDInProductGroup                                                    AS ProductionLotIDInProductGroup,
		|	Plan.Department                                                                  AS Department,
		|	Plan.Stage                                                                           AS Stage,
		|	Plan.SemiFinishedProductBOM                                                      AS SemiFinishedProductBOM,
		|	Plan.StructureAssignment                                                            AS StructureAssignment,
		|	Plan.Ordered                                                                       AS Ordered,
		|	Plan.AllocatedInFreeProductionLots                                                           AS AllocatedInFreeProductionLots,
		|	Plan.AllocatedInAssignedProductionLots                                                AS AllocatedInAssignedProductionLots,
		|	Plan.Done                                                                         AS Done
		|FROM
		|	OrderStructureSetOfRecords AS Plan
		|";
		Query.Text = StrReplace(Query.Text, "ProductionOrdersChanges", TempTableName);
		
		Query.SetParameter("ProductionOrder", Calculation.ProductionOrder);
		Query.SetParameter("DocumentID", Calculation.DocumentID);
		
		RecordSet.Filter.KeySet.Set(Calculation.DocumentID);
		RecordSet.Load(Query.Execute().Unload());
		RecordSet.Write(True);

		Query.Text =
		"SELECT DISTINCT
		|	ChangesTable.Products AS Products,
		|	ChangesTable.Characteristic AS Characteristic,
		|	ChangesTable.Warehouse AS Warehouse,
		|	ChangesTable.Purpose AS Purpose,
		|	ChangesTable.ProductionOrder AS ProductionOrder
		|FROM
		|	(SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		RegisterRecords.ProductionOrder AS ProductionOrder,
		|		RegisterRecords.KeyProducts AS KeyProducts,
		|		MAX(RegisterRecords.SemiFinishedProductBOM) AS BillOfMaterials,
		|		RegisterRecords.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
		|		-SUM(RegisterRecords.Ordered - RegisterRecords.AllocatedInFreeProductionLots - RegisterRecords.AllocatedInAssignedProductionLots) AS CountUpdate
		|	FROM
		|		OrderStructureBeforeWrite AS RegisterRecords
		|	GROUP BY
		|		RegisterRecords.Products,
		|		RegisterRecords.Characteristic,
		|		RegisterRecords.Warehouse,
		|		RegisterRecords.Purpose,
		|		RegisterRecords.ProductionOrder,
		|		RegisterRecords.KeyProducts,
		|		RegisterRecords.DurationBeforeProductionIssue
		|
		|	UNION ALL
		|
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		RegisterRecords.ProductionOrder AS ProductionOrder,
		|		RegisterRecords.KeyProducts AS KeyProducts,
		|		MAX(RegisterRecords.SemiFinishedProductBOM) AS BillOfMaterials,
		|		RegisterRecords.DurationBeforeProductionIssue AS DurationBeforeProductionIssue,
		|		SUM(RegisterRecords.Ordered - RegisterRecords.AllocatedInFreeProductionLots - RegisterRecords.AllocatedInAssignedProductionLots) AS CountUpdate
		|	FROM
		|		OrderStructureSetOfRecords AS RegisterRecords
		|	GROUP BY
		|		RegisterRecords.Products,
		|		RegisterRecords.Characteristic,
		|		RegisterRecords.Warehouse,
		|		RegisterRecords.Purpose,
		|		RegisterRecords.ProductionOrder,
		|		RegisterRecords.KeyProducts,
		|		RegisterRecords.DurationBeforeProductionIssue) AS ChangesTable
		|GROUP BY
		|	ChangesTable.Products,
		|	ChangesTable.Characteristic,
		|	ChangesTable.Warehouse,
		|	ChangesTable.Purpose,
		|	ChangesTable.ProductionOrder,
		|	ChangesTable.KeyProducts,
		|	ChangesTable.BillOfMaterials,
		|	ChangesTable.DurationBeforeProductionIssue
		|HAVING
		|	SUM(ChangesTable.CountUpdate) <> 0
		|;
		|";
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(QueryResult.Unload());
		EndIf;
		
		If Not TheProductionScheduleIsUsed Then // regulatory schedule
			
			Query.Text =
			"SELECT DISTINCT
			|	ChangesTable.ProductionOrder AS ProductionOrder,
			|	ChangesTable.KeyLot          AS KeyLot
			|FROM
			|	(SELECT
			|		RegisterRecords.Products AS Products,
			|		RegisterRecords.Characteristic AS Characteristic,
			|		RegisterRecords.Warehouse AS Warehouse,
			|		RegisterRecords.Purpose AS Purpose,
			|		RegisterRecords.ProductionOrder AS ProductionOrder,
			|		RegisterRecords.KeyLot AS KeyLot,
			|		RegisterRecords.KeyProducts AS KeyProducts,
			|		-RegisterRecords.AllocatedInFreeProductionLots AS AllocatedInFreeProductionLotsUpdate,
			|		-RegisterRecords.AllocatedInAssignedProductionLots AS AllocatedInAssignedProductionLotsUpdate
			|	FROM
			|		OrderStructureBeforeWrite AS RegisterRecords
			|	WHERE
			|		RegisterRecords.AllocatedInFreeProductionLots <> 0 OR RegisterRecords.AllocatedInAssignedProductionLots <> 0
			|
			|	UNION ALL
			|
			|	SELECT
			|		RegisterRecords.Products AS Products,
			|		RegisterRecords.Characteristic AS Characteristic,
			|		RegisterRecords.Warehouse AS Warehouse,
			|		RegisterRecords.Purpose AS Purpose,
			|		RegisterRecords.ProductionOrder AS ProductionOrder,
			|		RegisterRecords.KeyLot AS KeyLot,
			|		RegisterRecords.KeyProducts AS KeyProducts,
			|		RegisterRecords.AllocatedInFreeProductionLots AS AllocatedInFreeProductionLotsUpdate,
			|		RegisterRecords.AllocatedInAssignedProductionLots AS AllocatedInAssignedProductionLotsUpdate
			|	FROM
			|		OrderStructureSetOfRecords AS RegisterRecords
			|	WHERE
			|		RegisterRecords.AllocatedInFreeProductionLots <> 0 OR RegisterRecords.AllocatedInAssignedProductionLots <> 0) AS ChangesTable
			|
			|GROUP BY
			|	ChangesTable.Products,
			|	ChangesTable.Characteristic,
			|	ChangesTable.Warehouse,
			|	ChangesTable.Purpose,
			|	ChangesTable.ProductionOrder,
			|	ChangesTable.KeyLot,
			|	ChangesTable.KeyProducts
			|HAVING
			|	SUM(ChangesTable.AllocatedInFreeProductionLotsUpdate) <> 0 OR SUM(ChangesTable.AllocatedInAssignedProductionLotsUpdate) <> 0
			|;";
			QueryResult = Query.Execute();
			
			If Not QueryResult.IsEmpty() Then
				InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(QueryResult.Unload());
			EndIf;
			
		EndIf;
		
		TMCommonUse.DestroyTemporaryTables(TempTablesManager, "OrderStructureBeforeWrite,OrderStructureSetOfRecords");
		
	EndDo;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.ProductionOrders.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.14";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("65cb711c-669c-4a83-a4c6-a76a92d4abfd");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.ProductionOrders.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Đang điền trường ""Khóa mặt hàng"" trong biểu ghi ""Đơn hàng sản xuất"" dựa trên dữ liệu của chứng từ';
							|ru = 'Заполняет поле ""Ключ номенклатура"" в регистре ""Заказы на производство"" на основании данных документов';
							|en = 'Fills in the ""Key item"" field in the ""Production orders"" register based on these documents'; fa = 'Fills in the ""Key item"" field in the ""Production orders"" register based on these documents';
							|it = 'Fills in the ""Key item"" field in the ""Production orders"" register based on these documents';
							|pl = 'Fills in the ""Key item"" field in the ""Production orders"" register based on these documents';
							|tr = '""Üretim siparişleri"" kaydındaki ""Öğe Anahtarı"" alanını belgelerin verilerine göre doldurur'");

	ItemsToRead = New Array;

	ItemsToRead.Add(Metadata.Documents.ProductionOrder2_2.FullName());
	ItemsToRead.Add(Metadata.Documents.ProductionStage2_2.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.ProductionOrders.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "Documents.ProductionStage2_2.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.ProductionOrders";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("ProductionOrder ASC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("ProductionOrder ASC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	QueryText = 
	"SELECT
	|	Table.Recorder AS Recorder
	|FROM
	|	InformationRegister.ProductionOrders AS Table
	|WHERE
	|	Table.Recorder REFS Document.ProductionStage2_2
	|		AND Table.KeyProducts = &EmptyLinkKey";
	
	Query = New Query(QueryText);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.ProductionOrders";
	RegisterName = "ProductionOrders";
	
	TempTablesManager = New TempTablesManager;
	
	InfobaseUpdate.CreateTemporaryTableOfDataProhibitedFromReadingAndEditing(Undefined, "Document.ProductionStage2_2", TempTablesManager);
	
	AdditionalProcessingMarkParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalProcessingMarkParameters.IsRegisterRecords = True;
	AdditionalProcessingMarkParameters.FullRegisterName = FullRegisterName;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	UpdatedData.Recorder AS Recorder
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Recorder AS Recorder
	|FROM
	|	UpdatedData AS UpdatedData
	|
	|	LEFT JOIN TTIsBlockedProductionStage2_2 AS TTIsBlockedProductionStage2_2
	|	ON UpdatedData.Recorder = TTIsBlockedProductionStage2_2.Ref
	|
	|WHERE
	|	TTIsBlockedProductionStage2_2.Ref IS NULL
	|";
	
	Query.SetParameter("UpdatedData", UpdatedData); 
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DocumentName = Selection.Recorder.Metadata().Name;
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("InformationRegister.ProductionOrders.RecordSet");
			LockItem.SetValue("Recorder", Selection.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add("Document." + DocumentName);
			LockItem.SetValue("Ref", Selection.Recorder);
			LockItem.Mode = DataLockMode.Shared;
			
			Block.Lock();
			
			RecordSet = InformationRegisters.ProductionOrders.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.Read();
			
			If Common.ObjectAttributeValue(Selection.Recorder, "Posted") = True Then
				TablesForRegisteredRecords = Documents[DocumentName].DocumentDataForPosting(Selection.Recorder, RegisterName);
				RecordSet.Load(TablesForRegisteredRecords["Table" +  RegisterName]);
			EndIf;
			
			If RecordSet.Modified() Then
				
				InfobaseUpdate.WriteData(RecordSet);
			
			Else
				
				InfobaseUpdate.MarkProcessingCompletion(
					Selection.Recorder,
					AdditionalProcessingMarkParameters, 
					Parameters.Queue);
					
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Recorder);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
	
EndProcedure 

#EndRegion

#EndRegion

#EndIf
