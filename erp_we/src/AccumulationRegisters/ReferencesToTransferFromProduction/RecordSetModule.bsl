#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew",    AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	Table.Period              AS Period,
	|	Table.RowCode           AS RowCode,
	|	Table.Organization         AS Organization,
	|	Table.ReferenceOrder        AS ReferenceOrder,
	|	Table.Sender         AS Sender,
	|	Table.Recipient          AS Recipient,
	|	Table.Products        AS Products,
	|	Table.Characteristic      AS Characteristic,
	|	Table.Purpose          AS Purpose,
	|	Table.Series               AS Series,
	|	Table.Operation            AS Operation,
	|	Table.RecordType         AS RecordType,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Count
	|		ELSE
	|			-Table.Count
	|	END                       AS CountBeforeWrite
	|INTO RegisteredRecordsOfTransferOrderFromProductionBeforeRecording
	|FROM
	|	AccumulationRegister.ReferencesToTransferFromProduction AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND NOT &IsNew
	|";
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text =
	"SELECT
	|	MAX(ChangesTable.DateOfRecordingControl) AS DateOfControl,
	|	ChangesTable.Organization                  AS Organization,
	|	ChangesTable.ReferenceOrder                 AS ReferenceOrder,
	|	ChangesTable.RowCode                    AS RowCode,
	|	ChangesTable.Sender                  AS Sender,
	|	ChangesTable.Recipient                   AS Recipient,
	|	ChangesTable.Products                 AS Products,
	|	ChangesTable.Characteristic               AS Characteristic,
	|	ChangesTable.Purpose                   AS Purpose,
	|	ChangesTable.Series                        AS Series,
	|	ChangesTable.Operation                     AS Operation,
	|	SUM(ChangesTable.CountUpdate)   AS CountUpdate
	|INTO RegisteredRecordsOfTransferOrderFromProductionChange
	|FROM
	|	(SELECT
	|		DATETIME(1,1,1)                AS DateOfRecordingControl,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN BEGINOFPERIOD(Table.Period, MONTH)
	|			ELSE ENDOFPERIOD(Table.Period, MONTH)
	|		END                           AS DateOfControlBeforeWrite,
	|		Table.Organization             AS Organization,
	|		Table.ReferenceOrder            AS ReferenceOrder,
	|		Table.RowCode               AS RowCode,
	|		Table.Sender             AS Sender,
	|		Table.Recipient              AS Recipient,
	|		Table.Products            AS Products,
	|		Table.Characteristic          AS Characteristic,
	|		Table.Purpose              AS Purpose,
	|		Table.Series                   AS Series,
	|		Table.Operation                AS Operation,
	|		Table.CountBeforeWrite  AS CountUpdate
	|	FROM
	|		RegisteredRecordsOfTransferOrderFromProductionBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN BEGINOFPERIOD(Table.Period, MONTH)
	|			ELSE ENDOFPERIOD(Table.Period, MONTH)
	|		END                           AS DateOfRecordingControl,
	|		DATETIME(1,1,1)                AS DateOfControlBeforeWrite,
	|		Table.Organization             AS Organization,
	|		Table.ReferenceOrder            AS ReferenceOrder,
	|		Table.RowCode               AS RowCode,
	|		Table.Sender             AS Sender,
	|		Table.Recipient              AS Recipient,
	|		Table.Products            AS Products,
	|		Table.Characteristic          AS Characteristic,
	|		Table.Purpose              AS Purpose,
	|		Table.Series                   AS Series,
	|		Table.Operation                AS Operation,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Count
	|			ELSE
	|				Table.Count
	|		END                           AS CountUpdate
	|	FROM
	|		AccumulationRegister.ReferencesToTransferFromProduction AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.ReferenceOrder,
	|	ChangesTable.RowCode,
	|	ChangesTable.Sender,
	|	ChangesTable.Recipient,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Purpose,
	|	ChangesTable.Series,
	|	ChangesTable.Operation
	|
	|HAVING
	|	SUM(ChangesTable.CountUpdate) > 0
	|		OR MAX(ChangesTable.DateOfRecordingControl) <> MAX(ChangesTable.DateOfControlBeforeWrite)
	|;
	|DROP RegisteredRecordsOfTransferOrderFromProductionBeforeRecording
	|";
	
	Selection = Query.ExecuteBatch()[0].Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	
	DocumentsPosting.RegisterControlTable(
		AdditionalProperties,
		"RegisteredRecordsOfTransferOrderFromProductionChange",
		HasChanges);
	
	If HasChanges
		And GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
		
		Query = New Query;
		Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());
		Query.SetParameter("DimensionalTypesOfUnits",
			Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
		Query.TempTablesManager = AdditionalProperties.TempTablesManager;
		
		Query.Text =
		"SELECT
		|	Table.Sender,
		|	Table.Recipient,
		|	Table.Organization,
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Series,
		|	Table.Operation,
		|	Table.RowCode
		|INTO RegisteredRecordsOrdersForTransferFromProductionChangeMeasuredGoods
		|FROM
		|	RegisteredRecordsOfTransferOrderFromProductionChange AS Table
		|
		|WHERE
		|	Table.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|
		|GROUP BY
		|	Table.Sender,
		|	Table.Recipient,
		|	Table.Organization,
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Series,
		|	Table.Operation,
		|	Table.RowCode
		|
		|INDEX BY
		|	Table.Sender,
		|	Table.Recipient,
		|	Table.Organization,
		|	Table.ReferenceOrder,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose,
		|	Table.Series,
		|	Table.Operation,
		|	Table.RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// Main table
		|SELECT
		|	ToTransfer.RecordType,
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode,
		|	SUM(ToTransfer.Count) AS Count
		|INTO TTTransferOrdersFromProduction
		|FROM
		|	AccumulationRegister.ReferencesToTransferFromProduction AS ToTransfer
		|
		|	INNER JOIN RegisteredRecordsOfTransferOrderFromProductionChange AS Changes
		|	ON ToTransfer.Sender			= Changes.Sender
		|	AND ToTransfer.Recipient				= Changes.Recipient
		|	AND ToTransfer.Organization				= Changes.Organization
		|	AND ToTransfer.ReferenceOrder			= Changes.ReferenceOrder
		|	AND ToTransfer.Products			= Changes.Products
		|	AND ToTransfer.Characteristic			= Changes.Characteristic
		|	AND ToTransfer.Purpose				= Changes.Purpose
		|	AND ToTransfer.Series					= Changes.Series
		|	AND ToTransfer.Operation				= Changes.Operation
		|	AND ToTransfer.RowCode				= Changes.RowCode
		|
		|GROUP BY
		|	ToTransfer.RecordType,
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode
		|
		|INDEX BY
		|	ToTransfer.RecordType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// Tolerance
		|SELECT
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode,
		|	SUM(ToTransfer.Count
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|INTO TTPermissibleDeviationsOfTransferOrderFromProduction
		|FROM
		|	TTTransferOrdersFromProduction AS ToTransfer
		|
		|	INNER JOIN RegisteredRecordsOrdersForTransferFromProductionChangeMeasuredGoods AS Changes
		|	ON ToTransfer.Sender			= Changes.Sender
		|	AND ToTransfer.Recipient				= Changes.Recipient
		|	AND ToTransfer.Organization				= Changes.Organization
		|	AND ToTransfer.ReferenceOrder			= Changes.ReferenceOrder
		|	AND ToTransfer.Products			= Changes.Products
		|	AND ToTransfer.Characteristic			= Changes.Characteristic
		|	AND ToTransfer.Purpose				= Changes.Purpose
		|	AND ToTransfer.Series					= Changes.Series
		|	AND ToTransfer.Operation				= Changes.Operation
		|	AND ToTransfer.RowCode				= Changes.RowCode
		|
		|WHERE
		|	ToTransfer.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|GROUP BY
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode
		|
		|INDEX BY
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// Deleting a list of measured products
		|DROP RegisteredRecordsOrdersForTransferFromProductionChangeMeasuredGoods
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		//Balance
		|SELECT
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode,
		|	SUM(CASE
		|			WHEN ToTransfer.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN ToTransfer.Count
		|			ELSE -ToTransfer.Count
		|	END) AS Count
		|INTO TTTransferOrdersFromProductionBalance
		|FROM
		|	TTTransferOrdersFromProduction AS ToTransfer
		|
		|GROUP BY
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode
		|
		|INDEX BY
		|	ToTransfer.Sender,
		|	ToTransfer.Recipient,
		|	ToTransfer.Organization,
		|	ToTransfer.ReferenceOrder,
		|	ToTransfer.Products,
		|	ToTransfer.Characteristic,
		|	ToTransfer.Purpose,
		|	ToTransfer.Series,
		|	ToTransfer.Operation,
		|	ToTransfer.RowCode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		// Tasks for adjusting rows of dimensional goods
		|SELECT DISTINCT
		|	Balance.ReferenceOrder AS ReferenceOrder
		|FROM
		|	TTTransferOrdersFromProductionBalance AS Balance
		|
		|	INNER JOIN TTPermissibleDeviationsOfTransferOrderFromProduction AS AcceptableDeviations
		|	ON AcceptableDeviations.Sender		= Balance.Sender
		|	AND AcceptableDeviations.Recipient		= Balance.Recipient
		|	AND AcceptableDeviations.Organization		= Balance.Organization
		|	AND AcceptableDeviations.ReferenceOrder		= Balance.ReferenceOrder
		|	AND AcceptableDeviations.Products		= Balance.Products
		|	AND AcceptableDeviations.Characteristic	= Balance.Characteristic
		|	AND AcceptableDeviations.Purpose		= Balance.Purpose
		|	AND AcceptableDeviations.Series			= Balance.Series
		|	AND AcceptableDeviations.Operation			= Balance.Operation
		|	AND AcceptableDeviations.RowCode		= Balance.RowCode
		|
		|WHERE
		|	Balance.Count <= AcceptableDeviations.AllowableVariance
		|	AND Balance.Count >= -AcceptableDeviations.AllowableVariance
		|";
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			InformationRegisters.OrderQueueToAdjustRowsOfMeasuringGoods.AddOrderToQueue(Selection.ReferenceOrder);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
