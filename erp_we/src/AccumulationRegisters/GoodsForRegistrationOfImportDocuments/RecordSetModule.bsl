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
	|	Table.Period						 AS Period,
	|	Table.Organization                  AS Organization,
	|	Table.Vendor                    AS Vendor,
	|	Table.DocumentInflow          AS DocumentInflow,
	|	Table.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	Table.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	Table.ImportDocumentType          AS ImportDocumentType,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Sum
	|		ELSE
	|			-Table.Sum
	|	END                                AS SumBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.Count
	|		ELSE
	|			-Table.Count
	|	END                                AS CountBeforeWrite,
	|	CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|			Table.QuantityByGBRN
	|		ELSE
	|			-Table.QuantityByGBRN
	|	END                                AS QuantityByGBRNBeforeWrite
	|INTO PrepareGoodsForImportPaperworkBeforeRecording
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments AS Table
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
	|	ChangesTable.Period		                 AS Period,
	|	ChangesTable.Organization                 AS Organization,
	|	ChangesTable.Vendor                   AS Vendor,
	|	ChangesTable.DocumentInflow         AS DocumentInflow,
	|	ChangesTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	ChangesTable.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|	ChangesTable.ImportDocumentType         AS ImportDocumentType,
	|	SUM(ChangesTable.SumUpdate)  	 AS SumUpdate,
	|	SUM(ChangesTable.CountUpdate)  AS CountUpdate,
	|	SUM(ChangesTable.QuantityByGBRNUpdate) AS QuantityByGBRNUpdate
	|INTO PreparationOfGoodsForRegistrationOfImportDocumentsChange
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN VALUETYPE(Table.DocumentInflow) = TYPE(Document.VendorInvoice) 
	|				THEN DATETIME(1,1,1)
	|			WHEN VALUETYPE(Table.DocumentInflow) = TYPE(Document.SigningOfLeaseContract) 
	|				THEN Table.Period
	|			ELSE
	|				DATETIME(1,1,1)
	|		END 								AS Period,
	|		Table.Organization                 AS Organization,
	|		Table.Vendor                   AS Vendor,
	|		Table.DocumentInflow         AS DocumentInflow,
	|		Table.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|		Table.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|		Table.ImportDocumentType 		AS ImportDocumentType,
	|		Table.SumBeforeWrite           AS SumUpdate,
	|		Table.CountBeforeWrite      AS CountUpdate,
	|		Table.QuantityByGBRNBeforeWrite AS QuantityByGBRNUpdate
	|	FROM
	|		PrepareGoodsForImportPaperworkBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE 
	|			WHEN VALUETYPE(Table.DocumentInflow) = TYPE(Document.VendorInvoice) 
	|				THEN DATETIME(1,1,1)
	|			WHEN VALUETYPE(Table.DocumentInflow) = TYPE(Document.SigningOfLeaseContract) 
	|				THEN Table.Period
	|			ELSE
	|				DATETIME(1,1,1)
	|		END								AS Period,
	|		Table.Organization                 AS Organization,
	|		Table.Vendor                   AS Vendor,
	|		Table.DocumentInflow         AS DocumentInflow,
	|		Table.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|		Table.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|		Table.ImportDocumentType			AS ImportDocumentType,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Sum
	|			ELSE
	|				Table.Sum
	|		END                               AS SumUpdate,
	|		CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-Table.Count
	|			ELSE
	|				Table.Count
	|		END                               AS CountUpdate,
	|		CASE
	|			WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -Table.QuantityByGBRN
	|			ELSE Table.QuantityByGBRN
	|		END								AS QuantityByGBRNUpdate
	|	FROM
	|		AccumulationRegister.GoodsForRegistrationOfImportDocuments AS Table
	|	WHERE
	|		Table.Recorder = &Recorder) AS ChangesTable
	|
	|GROUP BY
	|	ChangesTable.Period,
	|	ChangesTable.Organization,
	|	ChangesTable.Vendor,
	|	ChangesTable.DocumentInflow,
	|	ChangesTable.ItemsLocationAttributes,
	|	ChangesTable.InventoryOwnerAttribute,
	|	ChangesTable.ImportDocumentType
	|
	|HAVING
	|	(SUM(ChangesTable.CountUpdate) > 0
	|		OR SUM(ChangesTable.QuantityByGBRNUpdate) > 0 
	|		OR SUM(ChangesTable.SumUpdate) > 0 AND VALUETYPE(ChangesTable.DocumentInflow) = TYPE(Document.SigningOfLeaseContract)
	|	)
	|;
	|DROP PrepareGoodsForImportPaperworkBeforeRecording
	|";
	
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	Selection = QueryResult.Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"PreparationOfGoodsForRegistrationOfImportDocumentsChange", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
