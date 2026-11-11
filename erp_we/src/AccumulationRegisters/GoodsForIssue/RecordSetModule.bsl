#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	TMCommonUse.CollapseRecordSet(ThisObject, True);
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	ModesOfFormationOfSpendingOrdersAutomatically = Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.Automatically;
	If ModesOfFormationOfSpendingOrdersAutomatically Then
		
		If Not AdditionalProperties.Property("TempTablesManager") Then
			AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
		EndIf;
		
		Query = New Query;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.Text =
		"SELECT
		|	Table.RecordType          AS RecordType,
		|	Table.DocumentShipments     AS DocumentShipments,
		|	Table.Recipient           AS Recipient,
		|	Table.Period               AS Period,
		|	Table.Products         AS Products,
		|	Table.Characteristic       AS Characteristic,
		|	Table.Purpose           AS Purpose,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.Series                AS Series,
		|	Table.Warehouse                AS Warehouse,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Table.ToShip
		|		ELSE -Table.ToShip
		|	END                        AS ToShipBeforeWrite,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -Table.AssemblyInProgress
		|		ELSE Table.AssemblyInProgress
		|	END                        AS AssemblyInProgressBeforeWrite,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -Table.Assembled
		|		ELSE Table.Assembled
		|	END                        AS AssembledBeforeWrite,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -Table.ToRegister
		|		ELSE Table.ToRegister
		|	END                        AS ToRegisterBeforeWrite,
		|	CASE
		|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN -Table.ForAssembly
		|		ELSE Table.ForAssembly
		|	END                        AS ForAssemblyBeforeWrite
		|INTO MovementOfGoodsForShipmentForPeriodBeforeRecording
		|FROM
		|	AccumulationRegister.GoodsForIssue AS Table
		|WHERE
		|	Table.Recorder = &Recorder";
		Query.Execute();
		
	EndIf;
	
	If Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;

	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.RecordType          AS RecordType,
	|	Table.DocumentShipments     AS DocumentShipments,
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	Table.Purpose           AS Purpose,
	|	Table.ControlledLotReference AS ControlledLotReference,
	|	Table.Series                AS Series,
	|	Table.Warehouse                AS Warehouse,
	|	Table.Recipient           AS Recipient,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.InReserve + Table.ToShip
	|		ELSE -Table.InReserve - Table.ToShip
	|	END                        AS InReserveForShipmentBeforeRecording,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Table.ToShip
	|		ELSE -Table.ToShip
	|	END                        AS ToShipBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Table.AssemblyInProgress
	|		ELSE Table.AssemblyInProgress
	|	END                        AS AssemblyInProgressBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Table.Assembled
	|		ELSE Table.Assembled
	|	END                        AS AssembledBeforeWrite,
	|	CASE
	|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Table.ToRegister
	|		ELSE Table.ToRegister
	|	END                        AS ToRegisterBeforeWrite
	|INTO RegisteredRecordsGoodsForIssueBeforeWrite
	|FROM
	|	AccumulationRegister.GoodsForIssue AS Table
	|WHERE
	|	Table.Recorder = &Recorder";
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ModesOfFormationOfSpendingOrdersAutomatically = Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.Automatically;
	
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		
		ProhibitFormationOfPivotTable = Undefined;
		AdditionalProperties.Property("ProhibitControlOfMovementOfGoodsForShipmentChangeSummary", ProhibitFormationOfPivotTable);
		ProhibitFormationOfPivotTable = ?(ProhibitFormationOfPivotTable = Undefined, False, ProhibitFormationOfPivotTable);
		
		Query = New Query;
		IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
		Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.SetParameter("ProhibitFormationOfPivotTable", ProhibitFormationOfPivotTable);
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		
		// The change of the new set relative to the current one is calculated taking into account the accumulated changes
		// and placed in a temporary table.
		
		Query.Text =
		"SELECT
		|	ChangesTable.DocumentShipments           AS DocumentShipments,
		|	ChangesTable.Products               AS Products,
		|	ChangesTable.Characteristic             AS Characteristic,
		|	ChangesTable.Purpose                 AS Purpose,
		|	ChangesTable.ControlledLotReference       AS ControlledLotReference,
		|	ChangesTable.Series                      AS Series,
		|	ChangesTable.Warehouse                      AS Warehouse,
		|	ChangesTable.Recipient                 AS Recipient,
		|	SUM(ChangesTable.ToShipUpdate)  AS ToShipUpdate,
		|	SUM(ChangesTable.AssemblyInProgressUpdate) AS AssemblyInProgressUpdate,
		|	SUM(ChangesTable.AssembledUpdate)    AS AssembledUpdate,
		|	SUM(ChangesTable.ToRegisterUpdate) AS ToRegisterUpdate
		|INTO RegisteredRecordsOfGoodsToShipAreReReflected
		|FROM
		|	(SELECT
		|		Table.DocumentShipments       AS DocumentShipments,
		|		Table.Products           AS Products,
		|		Table.Characteristic         AS Characteristic,
		|		Table.Purpose             AS Purpose,
		|		Table.ControlledLotReference   AS ControlledLotReference,
		|		Table.Series                  AS Series,
		|		Table.Warehouse                  AS Warehouse,
		|		Table.Recipient             AS Recipient,
		|		Table.ToShipBeforeWrite  AS ToShipUpdate,
		|		Table.AssemblyInProgressBeforeWrite AS AssemblyInProgressUpdate,
		|		Table.AssembledBeforeWrite    AS AssembledUpdate,
		|		Table.ToRegisterBeforeWrite AS ToRegisterUpdate
		|	FROM
		|		RegisteredRecordsGoodsForIssueBeforeWrite AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.DocumentShipments,
		|		Table.Products,
		|		Table.Characteristic,
		|		Table.Purpose,
		|		Table.ControlledLotReference,
		|		Table.Series,
		|		Table.Warehouse,
		|		Table.Recipient,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -Table.ToShip
		|			ELSE Table.ToShip
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.AssemblyInProgress
		|			ELSE -Table.AssemblyInProgress
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.Assembled
		|			ELSE -Table.Assembled
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.ToRegister
		|			ELSE -Table.ToRegister
		|		END
		|	FROM
		|		AccumulationRegister.GoodsForIssue AS Table
		|	WHERE
		|		Table.Recorder = &Recorder) AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.DocumentShipments,
		|	ChangesTable.Products,
		|	ChangesTable.Characteristic,
		|	ChangesTable.Purpose,
		|	ChangesTable.ControlledLotReference,
		|	ChangesTable.Series,
		|	ChangesTable.Warehouse,
		|	ChangesTable.Recipient
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ChangesTable.DocumentShipments           AS DocumentShipments,
		|	ChangesTable.Products               AS Products,
		|	ChangesTable.Characteristic             AS Characteristic,
		|	ChangesTable.Purpose                 AS Purpose,
		|	ChangesTable.ControlledLotReference       AS ControlledLotReference,
		|	ChangesTable.Series                      AS Series,
		|	ChangesTable.Warehouse                      AS Warehouse,
		|	ChangesTable.Recipient                 AS Recipient,
		|	ChangesTable.ToShipUpdate         AS ToShipUpdate,
		|	ChangesTable.AssemblyInProgressUpdate        AS AssemblyInProgressUpdate,
		|	ChangesTable.AssembledUpdate           AS AssembledUpdate
		|INTO RegisteredRecordsGoodsForIssueUpdate
		|FROM
		|	RegisteredRecordsOfGoodsToShipAreReReflected AS ChangesTable
		|WHERE
		|	ChangesTable.ToShipUpdate <> 0
		|		OR ChangesTable.AssemblyInProgressUpdate <> 0
		|		OR ChangesTable.AssembledUpdate <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Products             AS Products,
		|	T.Characteristic           AS Characteristic,
		|	T.Purpose               AS Purpose,
		|	T.ControlledLotReference     AS ControlledLotReference,
		|	T.Series                    AS Series,
		|	T.Warehouse                    AS Warehouse,
		|	T.Recipient               AS Recipient,
		|	SUM(T.IncreaseInParish) AS IncreaseInParish
		|INTO MovementOfGoodsForShipmentChangeInSummary
		|FROM
		|	(SELECT
		|		Table.RecordType                      AS RecordType,
		|		Table.Products                     AS Products,
		|		Table.Characteristic                   AS Characteristic,
		|		Table.Purpose                       AS Purpose,
		|		Table.ControlledLotReference             AS ControlledLotReference,
		|		Table.Series                            AS Series,
		|		Table.Warehouse                            AS Warehouse,
		|		Table.Recipient                       AS Recipient,
		|		-Table.InReserveForShipmentBeforeRecording   AS IncreaseInParish
		|	FROM
		|		RegisteredRecordsGoodsForIssueBeforeWrite AS Table
		|WHERE
		|	Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND Table.Warehouse.RealTimeStockControl
		|	AND NOT &ProhibitFormationOfPivotTable
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.RecordType,
		|		Table.Products,
		|		Table.Characteristic,
		|		Table.Purpose,
		|		Table.ControlledLotReference,
		|		Table.Series,
		|		Table.Warehouse,
		|		Table.Recipient,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.InReserve + Table.ToShip
		|			ELSE -Table.InReserve - Table.ToShip
		|		END
		|	FROM
		|		AccumulationRegister.GoodsForIssue AS Table
		|	WHERE
		|		Table.Recorder = &Recorder) AS T
		|WHERE
		|	T.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND T.Warehouse.RealTimeStockControl
		|	AND NOT &ProhibitFormationOfPivotTable
		|
		|GROUP BY
		|	T.RecordType,
		|	T.Products,
		|	T.Warehouse,
		|	T.Recipient,
		|	T.Characteristic,
		|	T.Purpose,
		|	T.ControlledLotReference,
		|	T.Series
		|
		|HAVING
		|	SUM(T.IncreaseInParish) > 0";
		
		Result = Query.ExecuteBatch();
		
		Selection = Result[Result.UBound() - 1].Select();
		DocumentsPosting.RegisterControlTable(AdditionalProperties,
			"RegisteredRecordsGoodsForIssueUpdate", Selection.Next() And Selection.Count > 0);
		
		Selection = Result[Result.UBound()].Select();
		DocumentsPosting.RegisterControlTable(AdditionalProperties,
			"MovementOfGoodsForShipmentChangeInSummary", Selection.Next() And Selection.Count > 0);
		
	EndIf;
	
	If ModesOfFormationOfSpendingOrdersAutomatically
		And AdditionalProperties.Property("TempTablesManager") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		Query.Text =
		"SELECT
		|	ChangesTable.Warehouse           AS Warehouse,
		|	ChangesTable.Recipient      AS Recipient,
		|	MIN(ChangesTable.Period) AS Period
		|INTO TableOfRecipients
		|FROM
		|	(SELECT
		|		Table.RecordType             AS RecordType,
		|		Table.Period                  AS Period,
		|		Table.Recipient              AS Recipient,
		|		Table.DocumentShipments        AS DocumentShipments,
		|		Table.Products            AS Products,
		|		Table.Characteristic          AS Characteristic,
		|		Table.Purpose              AS Purpose,
		|		Table.ControlledLotReference    AS ControlledLotReference,
		|		Table.Series                   AS Series,
		|		Table.Warehouse                   AS Warehouse,
		|		Table.ToShipBeforeWrite   AS ToShipUpdate,
		|		Table.ToRegisterBeforeWrite AS ToRegisterUpdate,
		|		Table.ForAssemblyBeforeWrite     AS ForAssemblyUpdate,
		|		Table.AssemblyInProgressBeforeWrite  AS AssemblyInProgressUpdate,
		|		Table.AssembledBeforeWrite     AS AssembledUpdate
		|	FROM
		|		MovementOfGoodsForShipmentForPeriodBeforeRecording AS Table
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.RecordType,
		|		Table.Period,
		|		Table.Recipient,
		|		Table.DocumentShipments,
		|		Table.Products,
		|		Table.Characteristic,
		|		Table.Purpose,
		|		Table.ControlledLotReference,
		|		Table.Series,
		|		Table.Warehouse,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN -Table.ToShip
		|			ELSE Table.ToShip
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.ToRegister
		|			ELSE -Table.ToRegister
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.ForAssembly
		|			ELSE -Table.ForAssembly
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.AssemblyInProgress
		|			ELSE -Table.AssemblyInProgress
		|		END,
		|		CASE
		|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN Table.Assembled
		|			ELSE -Table.Assembled
		|		END
		|	FROM
		|		AccumulationRegister.GoodsForIssue AS Table
		|	WHERE
		|		Table.Recorder = &Recorder) AS ChangesTable
		|
		|GROUP BY
		|	ChangesTable.RecordType,
		|	ChangesTable.Warehouse,
		|	ChangesTable.Recipient
		|
		|HAVING
		|	(SUM(ChangesTable.ToShipUpdate) + SUM(ChangesTable.ForAssemblyUpdate) + SUM(ChangesTable.AssemblyInProgressUpdate) + SUM(ChangesTable.AssembledUpdate) <> 0
		|		OR SUM(ChangesTable.ToRegisterUpdate) <> 0
		|			AND &IssueInvoicesFirst)
		|
		|INDEX BY
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfRecipients.Warehouse		AS Warehouse,
		|	TableOfRecipients.Recipient	AS Recipient
		|FROM
		|	TableOfRecipients AS TableOfRecipients
		|		INNER JOIN Catalog.Warehouses CatalogWarehouses
		|		ON TableOfRecipients.Warehouse = CatalogWarehouses.Ref
		|
		|WHERE
		|	CatalogWarehouses.UseWarehouseManagemantSystemForGoodsIssue
		|		AND TableOfRecipients.Period >= CatalogWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP MovementOfGoodsForShipmentForPeriodBeforeRecording";
		
		ProcedureForProcessingDocuments	= Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
		IssueInvoicesFirst	=
			ProcedureForProcessingDocuments = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
		
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
		
		RecipientsOfGoods = Query.Execute().Unload();
		
		If RecipientsOfGoods.Count() > 0 Then
			Result = WarehousesServer.DataForFormingQueueForReissuingSpendingOrders(RecipientsOfGoods);
			
			If Result.Count() > 0 Then
				WarehousesServer.UpdateQueueForFormationOfSpendingOrders(Result, Filter.Recorder.Value);
			EndIf;
		EndIf;
		
	EndIf;
	
	UseAllowableDeviationOfMeasuringGoodsShipmentReceiving =
		GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving");
		
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
			
		If UseAllowableDeviationOfMeasuringGoodsShipmentReceiving Then
			
			Query = New Query;
			Query.SetParameter("Recorder", Filter.Recorder.Value);
			Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
				Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());
			Query.SetParameter("DimensionalTypesOfUnits",
				Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
			Query.TempTablesManager = AdditionalProperties.TempTablesManager;
			
			Query.Text =
			"SELECT
			|	ChangesTable.DocumentShipments            AS DocumentShipments,
			|	ChangesTable.Products                AS Products,
			|	ChangesTable.Purpose                  AS Purpose,
			|	ChangesTable.ControlledLotReference        AS ControlledLotReference,
			|	ChangesTable.Characteristic              AS Characteristic,
			|	ChangesTable.Series                       AS Series,
			|	ChangesTable.Warehouse                       AS Warehouse,
			|	SUM(ChangesTable.ToShipUpdate)   AS ToShipUpdate
			|INTO RegisteredRecordsShipmentOrdersChangeMeasuredGoods
			|FROM
			|	(SELECT
			|
			|	RegisteredRecordsGoodsForIssueBeforeWrite.DocumentShipments      AS DocumentShipments,
			|	RegisteredRecordsGoodsForIssueBeforeWrite.Products          AS Products,
			|	RegisteredRecordsGoodsForIssueBeforeWrite.Characteristic        AS Characteristic,
			|	RegisteredRecordsGoodsForIssueBeforeWrite.Purpose            AS Purpose,
			|	RegisteredRecordsGoodsForIssueBeforeWrite.ControlledLotReference  AS ControlledLotReference,
			|	RegisteredRecordsGoodsForIssueBeforeWrite.Series                 AS Series,
			|	RegisteredRecordsGoodsForIssueBeforeWrite.Warehouse                 AS Warehouse,
			|	RegisteredRecordsGoodsForIssueBeforeWrite.ToShipBeforeWrite AS ToShipUpdate
			|
			|	FROM RegisteredRecordsGoodsForIssueBeforeWrite AS RegisteredRecordsGoodsForIssueBeforeWrite
			|
			|	UNION ALL
			|
			|	SELECT
			|	Table.DocumentShipments     AS DocumentShipments,
			|	Table.Products         AS Products,
			|	Table.Characteristic       AS Characteristic,
			|	Table.Purpose           AS Purpose,
			|	Table.ControlledLotReference AS ControlledLotReference,
			|	Table.Series                AS Series,
			|	Table.Warehouse                AS Warehouse,
			|	CASE
			|		WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN -Table.ToShip
			|		ELSE Table.ToShip
			|	END                        AS ToShipBeforeWrite
			|	
			|FROM
			|	AccumulationRegister.GoodsForIssue AS Table
			|WHERE
			|	Table.Recorder = &Recorder) AS ChangesTable
			|
			|WHERE
			|	ChangesTable.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
			|
			|GROUP BY
			|	ChangesTable.DocumentShipments,
			|	ChangesTable.Products,
			|	ChangesTable.Purpose,
			|	ChangesTable.ControlledLotReference,
			|	ChangesTable.Characteristic,
			|	ChangesTable.Series,
			|	ChangesTable.Warehouse
			|
			|HAVING
			|	SUM(ChangesTable.ToShipUpdate) <> 0
			|;
			|
			|///////////////////////////////////////////////////////////////////////////////////
			|
			|	SELECT
			|	GoodsForIssue.DocumentShipments     AS DocumentShipments,
			|	GoodsForIssue.Products         AS Products,
			|	GoodsForIssue.Characteristic       AS Characteristic,
			|	GoodsForIssue.Purpose           AS Purpose,
			|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
			|	GoodsForIssue.Series                AS Series,
			|	GoodsForIssue.Warehouse                AS Warehouse,
			|	SUM(GoodsForIssue.ToShip
			|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
			|INTO TTAcceptableDeviationsShippingOrders
			|FROM
			|	AccumulationRegister.GoodsForIssue AS GoodsForIssue
			|	INNER JOIN
			|		RegisteredRecordsShipmentOrdersChangeMeasuredGoods AS Changes
			|		ON GoodsForIssue.DocumentShipments        = Changes.DocumentShipments
			|			AND GoodsForIssue.Products         = Changes.Products
			|			AND GoodsForIssue.Purpose           = Changes.Purpose
			|			AND GoodsForIssue.ControlledLotReference = Changes.ControlledLotReference
			|			AND GoodsForIssue.Characteristic       = Changes.Characteristic
			|			AND GoodsForIssue.Series                = Changes.Series
			|			AND GoodsForIssue.Warehouse                = Changes.Warehouse
			|WHERE
			|	GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
			|GROUP BY
			|	GoodsForIssue.DocumentShipments,
			|	GoodsForIssue.Products,
			|	GoodsForIssue.Purpose,
			|	GoodsForIssue.ControlledLotReference,
			|	GoodsForIssue.Characteristic,
			|	GoodsForIssue.Series,
			|	GoodsForIssue.Warehouse
			|;
			|
			|/////////////////////////////////////////////////////////////////////////////////////////
			|
			|	SELECT
			|	GoodsForIssue.DocumentShipments     AS DocumentShipments,
			|	GoodsForIssue.Products         AS Products,
			|	GoodsForIssue.Characteristic       AS Characteristic,
			|	GoodsForIssue.Purpose           AS Purpose,
			|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
			|	GoodsForIssue.Series                AS Series,
			|	GoodsForIssue.Warehouse                AS Warehouse,
			|	SUM(CASE WHEN GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
			|			GoodsForIssue.ToShip
			|		ELSE
			|			-GoodsForIssue.ToShip
			|	END)                               AS ToShipBalance
			|INTO TTShippingOrdersBalances
			|FROM
			|	AccumulationRegister.GoodsForIssue    AS GoodsForIssue
			|	INNER JOIN
			|		RegisteredRecordsShipmentOrdersChangeMeasuredGoods AS Changes
			|		ON GoodsForIssue.DocumentShipments        = Changes.DocumentShipments
			|			AND GoodsForIssue.Products         = Changes.Products
			|			AND GoodsForIssue.Purpose           = Changes.Purpose
			|			AND GoodsForIssue.ControlledLotReference = Changes.ControlledLotReference
			|			AND GoodsForIssue.Characteristic       = Changes.Characteristic
			|			AND GoodsForIssue.Series                = Changes.Series
			|			AND GoodsForIssue.Warehouse                = Changes.Warehouse
			|GROUP BY
			|	GoodsForIssue.DocumentShipments,
			|	GoodsForIssue.Products,
			|	GoodsForIssue.Purpose,
			|	GoodsForIssue.ControlledLotReference,
			|	GoodsForIssue.Characteristic,
			|	GoodsForIssue.Series,
			|	GoodsForIssue.Warehouse
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	OrdersBalance.DocumentShipments AS DocumentShipments
			|FROM
			|	TTShippingOrdersBalances AS OrdersBalance
			|	INNER JOIN
			|		TTAcceptableDeviationsShippingOrders AS AcceptableDeviations
			|		ON
			|			OrdersBalance.DocumentShipments       = AcceptableDeviations.DocumentShipments
			|			AND OrdersBalance.Products         = AcceptableDeviations.Products
			|			AND OrdersBalance.Purpose           = AcceptableDeviations.Purpose
			|			AND OrdersBalance.ControlledLotReference = AcceptableDeviations.ControlledLotReference
			|			AND OrdersBalance.Characteristic       = AcceptableDeviations.Characteristic
			|			AND OrdersBalance.Series                = AcceptableDeviations.Series
			|			AND OrdersBalance.Warehouse                = AcceptableDeviations.Warehouse
			|WHERE
			|	OrdersBalance.ToShipBalance <= AcceptableDeviations.AllowableVariance
			|	AND OrdersBalance.ToShipBalance >= -AcceptableDeviations.AllowableVariance
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP RegisteredRecordsGoodsForIssueBeforeWrite
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP RegisteredRecordsShipmentOrdersChangeMeasuredGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTAcceptableDeviationsShippingOrders
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TTShippingOrdersBalances
			|";
			
			SampleOrder = Query.Execute().Select();
			
			While SampleOrder.Next() Do
				
				InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.AddOrderToQueue(
					SampleOrder.DocumentShipments);
				
			EndDo;
			
		Else
			
			Query = New Query;
			Query.TempTablesManager = AdditionalProperties.TempTablesManager;
			
			Query.Text = "DROP RegisteredRecordsGoodsForIssueBeforeWrite";
			
			Query.Execute();
			
		EndIf;
			
	EndIf;
	
EndProcedure

#EndRegion

#EndIf