////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystem "Production"
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	Parameters.ThereAreDerivedMotions = True;
	
	DocumentType = TypeOf(Document);
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ProductsRelease);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.OrdersOfMaterialsForProduction);
		

		If (DocumentType = Type("DocumentObject.ProductionStage2_2") Or DocumentType = Type("DocumentObject.ProductionOrder2_2"))
			And Not Document.DynamicStructure Then
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ProductionProcessSupply);
		EndIf;
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ReferencesToTransferFromProduction);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.LaborCostsToRegister);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.ProductsRelease);
		
		DocumentType = TypeOf(Document);
		
		CorrectiveDocument = DocumentCorrection.ThisIsCorrectiveDocument(Document);
		
		If Not Properties.IsNew
				And (DocumentType = Type("DocumentObject.OrderOfMaterialsForProduction")
				Or DocumentType = Type("DocumentObject.ProductionStage2_2")
				)
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And (DocumentType = Type("DocumentObject.MovementOfProductsAndMaterials")
				)
			Or CorrectiveDocument
			Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.OrdersOfMaterialsForProduction);
		EndIf;
		
			
		If Not Properties.IsNew
				And DocumentType = Type("DocumentObject.ProductionStage2_2")
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And DocumentType = Type("DocumentObject.MovementOfProductsAndMaterials") And Document.ByReferences
				And (Document.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
					Or Document.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction) 
			Or CorrectiveDocument Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.ReferencesToTransferFromProduction);
		EndIf;
		If DocumentType = Type("DocumentObject.BackflushProduction")
			Or Not Properties.IsNew
				And (DocumentType = Type("DocumentObject.RMOrder")
				Or DocumentType = Type("DocumentObject.ProductionStage2_2")
				Or (DocumentType = Type("DocumentObject.ProductionOperation2_2") And Document.OperationAsOutputReference)
				)
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And DocumentType = Type("DocumentObject.WorkOutput") Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.LaborCostsToRegister);
		EndIf;
		If (DocumentType = Type("DocumentObject.ProductionStage2_2") Or DocumentType = Type("DocumentObject.ProductionOrder2_2"))
			And Not Document.DynamicStructure Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.ProductionProcessSupply);
		EndIf;
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.ProductsRelease;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.OrdersOfMaterialsForProduction;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	RegisterMetadata = Metadata.AccumulationRegisters.ProductionProcessSupply;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.ReferencesToTransferFromProduction;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	RegisterMetadata = Metadata.AccumulationRegisters.LaborCostsToRegister;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		
		DocumentName = MetadataOfDocument.FullName();
		
		If DocumentName = "Document.BackflushProduction" Then
			
			QueryText = "
			// If the correction document does not support the preservation of production Lot references,
			// then Register Records will be reversed only if the production is not completed.
			// If the correction document supports the preservation of Lot references of production,
			// then the correction document generates Registered Records for the delta.
			|SELECT
			|	ReversingDocuments.Ref AS Recorder,
			|	ReversingDocuments.Date AS Period,
			|	RegisterData.Active AS Active,
			|	RegisterData.RecordType AS RecordType,
			|	RegisterData.Organization AS Organization,
			|	RegisterData.ProductionLot AS ProductionLot,
			|	RegisterData.ReferenceOrder AS ReferenceOrder,
			|	RegisterData.WorkKind AS WorkKind,
			|	RegisterData.Performer AS Performer,
			|	RegisterData.ReferenceRowCode AS ReferenceRowCode,
			|	RegisterData.Department AS Department,
			|	- RegisterData.Count AS Count,
			|	TRUE AS ReversingEntry
			|FROM
			|	AccumulationRegister.LaborCostsToRegister AS RegisterData
			|
			|	INNER JOIN &DocumentName AS ReversingDocuments
			|	ON RegisterData.Recorder = ReversingDocuments.ReversedDocument
			|	AND ReversingDocuments.Ref IN(&Ref)
			|	
			|	LEFT JOIN AccumulationRegister.LaborCostsToRegister AS RegistrationOfLaborCosts
			|	ON RegisterData.ReferenceOrder = RegistrationOfLaborCosts.ReferenceOrder
			|	AND RegistrationOfLaborCosts.RecordType = VALUE(AccumulationRecordType.Expense)
			|	
			|	LEFT JOIN Document.BackflushProduction AS AttributesOfReversingProductionWithoutOrder
			|	ON AttributesOfReversingProductionWithoutOrder.Ref = ReversingDocuments.Ref
			|
			|WHERE
			|	NOT RegisterData.ReversingEntry
			|	AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
			|	AND RegistrationOfLaborCosts.Recorder IS NULL
			// In backflushed production with correction, the preservation of production parties is supported by the preservation of production Lot references - we exclude.
			|	AND NOT ISNULL(AttributesOfReversingProductionWithoutOrder.CorrectionSavesProductionLots, FALSE)
			|";
			
			QueryText = StrReplace(QueryText, "&DocumentName", DocumentName);
			QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
			
		ElsIf DocumentName = "Document.ReversingEntry" Then
			
			QueryText = "
			// If the production is being executed Storno of the backflushed production with the preservation of the Lot references of the production,
			// then all Registered Recorded movements that were not previously suspended by the Lot references of the production will be canceled.
			|SELECT
			|	DocumentsStorno.Ref               AS Recorder,
			|	DocumentsStorno.Date                 AS Period,
			|	RegisterData.RecordType           AS RecordType,
			|	RegisterData.Organization           AS Organization,
			|	RegisterData.ProductionLot    AS ProductionLot,
			|	RegisterData.ReferenceOrder          AS ReferenceOrder,
			|	RegisterData.WorkKind              AS WorkKind,
			|	RegisterData.Performer           AS Performer,
			|	RegisterData.ReferenceRowCode AS ReferenceRowCode,
			|	RegisterData.Department         AS Department,
			|	-SUM(RegisterData.Count)    AS Count,
			|	TRUE                               AS ReversingEntry
			|FROM
			|	&DocumentName AS DocumentsStorno
			|	
			|	INNER JOIN Document.BackflushProduction AS ProductionDetailsWithoutOrder
			|	ON ProductionDetailsWithoutOrder.Ref = DocumentsStorno.ReversedDocument
			|	AND ProductionDetailsWithoutOrder.CorrectionSavesProductionLots
			|	
			|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
			|	ON CASE
			|		WHEN ProductionDetailsWithoutOrder.Patch
			|			THEN ProductionDetailsWithoutOrder.CorrectedDocument
			|		ELSE ProductionDetailsWithoutOrder.Ref
			|	END = CatProductionLots.Document
			|	AND NOT CatProductionLots.DeletionMark
			|	
			|	INNER JOIN AccumulationRegister.LaborCostsToRegister AS RegisterData
			|	ON RegisterData.ProductionLot = CatProductionLots.Ref
			|	
			|WHERE
			|	DocumentsStorno.Ref IN(&Ref)
			|	AND VALUETYPE(RegisterData.Recorder) = TYPE(Document.BackflushProduction)
			|
			|GROUP BY
			|	DocumentsStorno.Ref,
			|	DocumentsStorno.Date,
			|	RegisterData.RecordType,
			|	RegisterData.Organization,
			|	RegisterData.ProductionLot,
			|	RegisterData.ReferenceOrder,
			|	RegisterData.WorkKind,
			|	RegisterData.Performer,
			|	RegisterData.ReferenceRowCode,
			|	RegisterData.Department
			|HAVING
			|	NOT SUM(RegisterData.Count) = 0
			|
			|UNION ALL
			|
			// The cancellation of the remaining documents is carried out according to the general rules.
			|SELECT
			|	DocumentsStorno.Ref               AS Recorder,
			|	DocumentsStorno.Date                 AS Period,
			|	RegisterData.RecordType           AS RecordType,
			|	RegisterData.Organization           AS Organization,
			|	RegisterData.ProductionLot    AS ProductionLot,
			|	RegisterData.ReferenceOrder          AS ReferenceOrder,
			|	RegisterData.WorkKind              AS WorkKind,
			|	RegisterData.Performer           AS Performer,
			|	RegisterData.ReferenceRowCode AS ReferenceRowCode,
			|	RegisterData.Department         AS Department,
			|	-RegisterData.Count           AS Count,
			|	TRUE                               AS ReversingEntry
			|FROM
			|	AccumulationRegister.LaborCostsToRegister AS RegisterData
			|	
			|	INNER JOIN &DocumentName AS DocumentsStorno
			|	ON DocumentsStorno.ReversedDocument = RegisterData.Recorder
			|	AND DocumentsStorno.Ref IN (&Ref)
			|	
			|	LEFT JOIN Document.BackflushProduction AS ProductionDetailsWithoutOrder
			|	ON ProductionDetailsWithoutOrder.Ref = DocumentsStorno.ReversedDocument
			|	
			|WHERE
			|	NOT RegisterData.ReversingEntry
			|	AND (NOT VALUETYPE(RegisterData.Recorder) = TYPE(Document.BackflushProduction)
			|		OR NOT ISNULL(ProductionDetailsWithoutOrder.CorrectionSavesProductionLots, FALSE))
			|";
			
			QueryText = StrReplace(QueryText, "&DocumentName", DocumentName);
			QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
			
		Else
			
			QueriesTexts.Insert(
				RegisterMetadata.FullName(),
				DocumentsPosting.TextOfReversingRequest(
					RegisterMetadata, MetadataOfDocument));
			
		EndIf;
		
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of production.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ProductsRelease");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OrdersOfMaterialsForProduction");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ProductionProcessSupply");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ReferencesToTransferFromProduction");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "LaborCostsToRegister");
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region OrdersOfMaterialsForProduction
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOrdersOfMaterialsIntoProductionChange") Then
		
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		
		If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
			QueryText =
				"SELECT
				|	BalanceTable.ReferenceOrder                  AS OrderDocument,
				|	BalanceTable.Products                  AS Products,
				|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
				|	BalanceTable.Characteristic                AS Characteristic,
				|	BalanceTable.Series                         AS Series,
				|	BalanceTable.RowCode                     AS RowCode,
				|	BalanceTable.Warehouse                         AS Warehouse,
				|	BalanceTable.Purpose                    AS Purpose,
				|	BalanceTable.AssignmentSender         AS AssignmentSender,
				|	BalanceTable.Department                 AS Department,
				|	BalanceTable.ToRegisterBalance            AS Count
				|FROM
				|	AccumulationRegister.OrdersOfMaterialsForProduction.Balance(,
				|			(ReferenceOrder, Products, Characteristic, Series, RowCode, Warehouse, Purpose, AssignmentSender, Department) IN
				|				(SELECT
				|					Table.ReferenceOrder,
				|					Table.Products,
				|					Table.Characteristic,
				|					Table.Series,
				|					Table.RowCode,
				|					Table.Warehouse,
				|					Table.Purpose,
				|					Table.AssignmentSender,
				|					Table.Department
				|				FROM
				|					RegisteredRecordsOrdersOfMaterialsIntoProductionChange AS Table)
				|	) AS BalanceTable
				|
				|WHERE
				|	BalanceTable.ToRegisterBalance < 0";
		Else
			QueryText = 
				"SELECT
				|	BalanceTable.ReferenceOrder                  AS OrderDocument,
				|	BalanceTable.Products                  AS Products,
				|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
				|	BalanceTable.Characteristic                AS Characteristic,
				|	BalanceTable.Series                         AS Series,
				|	BalanceTable.RowCode                     AS RowCode,
				|	BalanceTable.Warehouse                         AS Warehouse,
				|	BalanceTable.Purpose                    AS Purpose,
				|	BalanceTable.AssignmentSender         AS AssignmentSender,
				|	BalanceTable.Department                 AS Department,
				|	BalanceTable.ToRegisterBalance            AS Count
				|FROM
				|	TTMaterialOrdersInProductionBalance  AS BalanceTable
				|	LEFT JOIN
				|		TTPermissibleDeviationsOrdersOfMaterialsInProduction AS AcceptableDeviations
				|		ON
				|			BalanceTable.ReferenceOrder     = AcceptableDeviations.ReferenceOrder
				|			AND BalanceTable.Products   = AcceptableDeviations.Products
				|			AND BalanceTable.Characteristic = AcceptableDeviations.Characteristic
				|			AND BalanceTable.Warehouse          = AcceptableDeviations.Warehouse
				|			AND BalanceTable.Series          = AcceptableDeviations.Series
				|			AND BalanceTable.Purpose     = AcceptableDeviations.Purpose
				|			AND BalanceTable.AssignmentSender = AcceptableDeviations.AssignmentSender
				|			AND BalanceTable.Department  = AcceptableDeviations.Department
				|
				|WHERE
				|	BalanceTable.ToRegisterBalance + ISNULL(AcceptableDeviations.AllowableVariance,0) < 0";
		EndIf;
		
		QueryTexts.Add(QueryText, "ErrorsOrderingMaterialsIntoProduction");
		
	EndIf;
	
	#EndRegion
	
	
	#Region ReferencesToTransferFromProduction
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOfTransferOrderFromProductionChange") Then
		
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		
		If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
			QueryTexts.Add(
				"SELECT
				|	BalanceTable.ReferenceOrder                  AS OrderDocument,
				|	BalanceTable.RowCode                     AS RowCode,
				|	BalanceTable.Sender                   AS Sender,
				|	BalanceTable.Recipient                    AS Recipient,
				|	BalanceTable.Organization                   AS Organization,
				|	BalanceTable.Products                  AS Products,
				|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
				|	BalanceTable.Characteristic                AS Characteristic,
				|	BalanceTable.Purpose                    AS Purpose,
				|	BalanceTable.Series                         AS Series,
				|	BalanceTable.Operation                      AS Operation,
				|	BalanceTable.CountBalance             AS Count
				|INTO VT_OrdersForTransferFromProductionOperationalControl
				|FROM
				|	AccumulationRegister.ReferencesToTransferFromProduction.Balance(,
				|			(ReferenceOrder, RowCode, Sender, Recipient, Organization, Products, Characteristic, Purpose, Series, Operation) IN
				|				(SELECT
				|					Table.ReferenceOrder,
				|					Table.RowCode,
				|					Table.Sender,
				|					Table.Recipient,
				|					Table.Organization,
				|					Table.Products,
				|					Table.Characteristic,
				|					Table.Purpose,
				|					Table.Series,
				|					Table.Operation
				|				FROM
				|					RegisteredRecordsOfTransferOrderFromProductionChange AS Table)
				|	) AS BalanceTable
				|WHERE
				|	BalanceTable.CountBalance < 0");
			
			QueryTexts.Add(
				"SELECT
				|	Table.ReferenceOrder,
				|	Table.RowCode,
				|	Table.Sender,
				|	Table.Recipient,
				|	Table.Organization,
				|	Table.Products,
				|	Table.Characteristic,
				|	Table.Purpose,
				|	Table.Series,
				|	Table.Operation
				|INTO VT_OrdersToTransferControlFromProductionOnDate
				|FROM
				|	RegisteredRecordsOfTransferOrderFromProductionChange AS Table
				|	LEFT JOIN VT_OrdersForTransferFromProductionOperationalControl
				|	ON Table.ReferenceOrder = VT_OrdersForTransferFromProductionOperationalControl.OrderDocument
				|		AND Table.RowCode = VT_OrdersForTransferFromProductionOperationalControl.RowCode
				|		AND Table.Sender = VT_OrdersForTransferFromProductionOperationalControl.Sender
				|		AND Table.Recipient = VT_OrdersForTransferFromProductionOperationalControl.Recipient
				|		AND Table.Organization = VT_OrdersForTransferFromProductionOperationalControl.Organization
				|		AND Table.Products = VT_OrdersForTransferFromProductionOperationalControl.Products
				|		AND Table.Characteristic = VT_OrdersForTransferFromProductionOperationalControl.Characteristic
				|		AND Table.Purpose = VT_OrdersForTransferFromProductionOperationalControl.Purpose
				|		AND Table.Series = VT_OrdersForTransferFromProductionOperationalControl.Series
				|		AND Table.Operation = VT_OrdersForTransferFromProductionOperationalControl.Operation
				|
				|WHERE
				|	VT_OrdersForTransferFromProductionOperationalControl.OrderDocument IS NULL");
			
			QueryText =
				"SELECT
				|	FALSE                                          AS DateControl,
				|	BalanceTable.OrderDocument                         AS OrderDocument,
				|	BalanceTable.Sender                   AS Sender,
				|	BalanceTable.Recipient                    AS Recipient,
				|	BalanceTable.Organization                   AS Organization,
				|	BalanceTable.Products                  AS Products,
				|	BalanceTable.UnitOfMeasure              AS UnitOfMeasure,
				|	BalanceTable.Characteristic                AS Characteristic,
				|	BalanceTable.Purpose                    AS Purpose,
				|	BalanceTable.Series                         AS Series,
				|	BalanceTable.Operation                      AS Operation,
				|	BalanceTable.Count                    AS Count
				|FROM
				|	VT_OrdersForTransferFromProductionOperationalControl AS BalanceTable
				|
				|UNION ALL
				|
				|SELECT
				|	TRUE                                        AS DateControl,
				|	BalanceTable.ReferenceOrder                  AS OrderDocument,
				|	BalanceTable.Sender                   AS Sender,
				|	BalanceTable.Recipient                    AS Recipient,
				|	BalanceTable.Organization                   AS Organization,
				|	BalanceTable.Products                  AS Products,
				|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
				|	BalanceTable.Characteristic                AS Characteristic,
				|	BalanceTable.Purpose                    AS Purpose,
				|	BalanceTable.Series                         AS Series,
				|	BalanceTable.Operation                      AS Operation,
				|	BalanceTable.CountBalance             AS Count
				|FROM
				|	AccumulationRegister.ReferencesToTransferFromProduction.Balance(&DateOfControl,
				|			(ReferenceOrder, RowCode, Sender, Recipient, Organization, Products, Characteristic, Purpose, Series, Operation) IN
				|				(SELECT
				|					Table.ReferenceOrder,
				|					Table.RowCode,
				|					Table.Sender,
				|					Table.Recipient,
				|					Table.Organization,
				|					Table.Products,
				|					Table.Characteristic,
				|					Table.Purpose,
				|					Table.Series,
				|					Table.Operation
				|				FROM
				|					VT_OrdersToTransferControlFromProductionOnDate AS Table)
				|	) AS BalanceTable
				|WHERE
				|	BalanceTable.CountBalance < 0
				|";
			
		ElsIf TypeOf(Document) = Type("DocumentObject.MovementOfProductsAndMaterials")
			And Document.BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
			
			QueryTexts.Add(
			"SELECT
			|	BalanceTable.ReferenceOrder                  AS ReferenceOrder,
			|	BalanceTable.RowCode                     AS RowCode,
			|	BalanceTable.Sender                   AS Sender,
			|	BalanceTable.Recipient                    AS Recipient,
			|	BalanceTable.Organization                   AS Organization,
			|	BalanceTable.Products                  AS Products,
			|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
			|	BalanceTable.Characteristic                AS Characteristic,
			|	BalanceTable.Purpose                    AS Purpose,
			|	BalanceTable.Series                         AS Series,
			|	BalanceTable.Operation                      AS Operation,
			|	BalanceTable.Count + ISNULL(AcceptableDeviations.AllowableVariance, 0) AS Count
			|INTO VT_OrdersForTransferFromProductionOperationalControl
			|FROM
			|	TTTransferOrdersFromProductionBalance AS BalanceTable
			|
			|	LEFT JOIN TTPermissibleDeviationsOfTransferOrderFromProduction AS AcceptableDeviations
			|	ON BalanceTable.Sender		= AcceptableDeviations.Sender
			|	AND BalanceTable.Recipient		= AcceptableDeviations.Recipient
			|	AND BalanceTable.Organization		= AcceptableDeviations.Organization
			|	AND BalanceTable.ReferenceOrder		= AcceptableDeviations.ReferenceOrder
			|	AND BalanceTable.Products		= AcceptableDeviations.Products
			|	AND BalanceTable.Characteristic	= AcceptableDeviations.Characteristic
			|	AND BalanceTable.Purpose		= AcceptableDeviations.Purpose
			|	AND BalanceTable.Series				= AcceptableDeviations.Series
			|	AND BalanceTable.Operation			= AcceptableDeviations.Operation
			|	AND BalanceTable.RowCode			= AcceptableDeviations.RowCode
			|
			|WHERE
			|	BalanceTable.Count + ISNULL(AcceptableDeviations.AllowableVariance, 0) < 0
			|
			|INDEX BY
			|	BalanceTable.Sender,
			|	BalanceTable.Recipient,
			|	BalanceTable.Organization,
			|	BalanceTable.ReferenceOrder,
			|	BalanceTable.Products,
			|	BalanceTable.Characteristic,
			|	BalanceTable.Purpose,
			|	BalanceTable.Series,
			|	BalanceTable.Operation,
			|	BalanceTable.RowCode
			|");
			
			QueryTexts.Add(
			"SELECT
			|	RegisterRecordTable.ReferenceOrder,
			|	RegisterRecordTable.RowCode,
			|	RegisterRecordTable.Sender,
			|	RegisterRecordTable.Recipient,
			|	RegisterRecordTable.Organization,
			|	RegisterRecordTable.Products,
			|	RegisterRecordTable.Characteristic,
			|	RegisterRecordTable.Purpose,
			|	RegisterRecordTable.Series,
			|	RegisterRecordTable.Operation
			|INTO VT_OrdersToTransferControlFromProductionOnDate
			|FROM
			|	RegisteredRecordsOfTransferOrderFromProductionChange AS RegisterRecordTable
			|
			|	LEFT JOIN VT_OrdersForTransferFromProductionOperationalControl AS OperationalControlTable
			|	ON RegisterRecordTable.ReferenceOrder		= OperationalControlTable.ReferenceOrder
			|	AND RegisterRecordTable.RowCode			= OperationalControlTable.RowCode
			|	AND RegisterRecordTable.Sender		= OperationalControlTable.Sender
			|	AND RegisterRecordTable.Recipient		= OperationalControlTable.Recipient
			|	AND RegisterRecordTable.Organization		= OperationalControlTable.Organization
			|	AND RegisterRecordTable.Products		= OperationalControlTable.Products
			|	AND RegisterRecordTable.Characteristic	= OperationalControlTable.Characteristic
			|	AND RegisterRecordTable.Purpose		= OperationalControlTable.Purpose
			|	AND RegisterRecordTable.Series				= OperationalControlTable.Series
			|	AND RegisterRecordTable.Operation			= OperationalControlTable.Operation
			|
			|WHERE
			|	OperationalControlTable.ReferenceOrder IS NULL
			|
			|INDEX BY
			|	RegisterRecordTable.Sender,
			|	RegisterRecordTable.Recipient,
			|	RegisterRecordTable.Organization,
			|	RegisterRecordTable.ReferenceOrder,
			|	RegisterRecordTable.Products,
			|	RegisterRecordTable.Characteristic,
			|	RegisterRecordTable.Purpose,
			|	RegisterRecordTable.Series,
			|	RegisterRecordTable.Operation,
			|	RegisterRecordTable.RowCode
			|");
			
			QueryText = 
			"SELECT
			|	FALSE                                          AS DateControl,
			|	BalanceTable.ReferenceOrder                  AS OrderDocument,
			|	BalanceTable.Sender                   AS Sender,
			|	BalanceTable.Recipient                    AS Recipient,
			|	BalanceTable.Organization                   AS Organization,
			|	BalanceTable.Products                  AS Products,
			|	BalanceTable.UnitOfMeasure              AS UnitOfMeasure,
			|	BalanceTable.Characteristic                AS Characteristic,
			|	BalanceTable.Purpose                    AS Purpose,
			|	BalanceTable.Series                         AS Series,
			|	BalanceTable.Operation                      AS Operation,
			|	BalanceTable.Count                    AS Count
			|FROM
			|	VT_OrdersForTransferFromProductionOperationalControl AS BalanceTable
			|
			|UNION ALL
			|
			|SELECT
			|	TRUE                                        AS DateControl,
			|	BalanceTable.ReferenceOrder                  AS OrderDocument,
			|	BalanceTable.Sender                   AS Sender,
			|	BalanceTable.Recipient                    AS Recipient,
			|	BalanceTable.Organization                   AS Organization,
			|	BalanceTable.Products                  AS Products,
			|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
			|	BalanceTable.Characteristic                AS Characteristic,
			|	BalanceTable.Purpose                    AS Purpose,
			|	BalanceTable.Series                         AS Series,
			|	BalanceTable.Operation                      AS Operation,
			|	BalanceTable.CountBalance + ISNULL(AcceptableDeviations.AllowableVariance, 0) AS Count
			|FROM
			|	AccumulationRegister.ReferencesToTransferFromProduction.Balance(&DateOfControl,
			|			(ReferenceOrder, RowCode, Sender, Recipient, Organization, Products, Characteristic, Purpose, Series, Operation) IN
			|				(SELECT
			|					Table.ReferenceOrder,
			|					Table.RowCode,
			|					Table.Sender,
			|					Table.Recipient,
			|					Table.Organization,
			|					Table.Products,
			|					Table.Characteristic,
			|					Table.Purpose,
			|					Table.Series,
			|					Table.Operation
			|				FROM
			|					VT_OrdersToTransferControlFromProductionOnDate AS Table)
			|	) AS BalanceTable
			|
			|	LEFT JOIN TTPermissibleDeviationsOfTransferOrderFromProduction AS AcceptableDeviations
			|	ON BalanceTable.Sender		= AcceptableDeviations.Sender
			|	AND BalanceTable.Recipient		= AcceptableDeviations.Recipient
			|	AND BalanceTable.Organization		= AcceptableDeviations.Organization
			|	AND BalanceTable.ReferenceOrder		= AcceptableDeviations.ReferenceOrder
			|	AND BalanceTable.Products		= AcceptableDeviations.Products
			|	AND BalanceTable.Characteristic	= AcceptableDeviations.Characteristic
			|	AND BalanceTable.Purpose		= AcceptableDeviations.Purpose
			|	AND BalanceTable.Series				= AcceptableDeviations.Series
			|	AND BalanceTable.Operation			= AcceptableDeviations.Operation
			|	AND BalanceTable.RowCode			= AcceptableDeviations.RowCode
			|
			|WHERE
			|	BalanceTable.CountBalance + ISNULL(AcceptableDeviations.AllowableVariance, 0) < 0
			|";
			
		Else
			
			QueryText =
			"SELECT
			|	FALSE			AS DateControl,
			|	UNDEFINED	AS OrderDocument,
			|	UNDEFINED	AS Sender,
			|	UNDEFINED	AS Recipient,
			|	UNDEFINED	AS Products,
			|	UNDEFINED	AS UnitOfMeasure,
			|	UNDEFINED	AS Characteristic,
			|	UNDEFINED	AS Purpose,
			|	UNDEFINED	AS Series,
			|	UNDEFINED	AS Operation,
			|	0				AS Count
			|WHERE
			|	FALSE
			|";
			
		EndIf;
		
		DateRequest = New Query("SELECT MIN(T.DateOfControl) AS Date FROM RegisteredRecordsOfTransferOrderFromProductionChange AS T");
		DateRequest.TempTablesManager = Query.TempTablesManager;
		DateSelection = DateRequest.Execute().Select();
		
		BalanceDate = ?(DateSelection.Next() And ValueIsFilled(DateSelection.Date), DateSelection.Date, Document.Date);
		Query.SetParameter("DateOfControl", BalanceDate);
		
		QueryTexts.Add(QueryText, "ErrorsInTransferOrderFromProduction");
		
	EndIf;
	
	#EndRegion
	
	#Region LaborCostsToRegister
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "AdditionalLaborCostsForRegistration") Then
		
		QueryText =
			"SELECT ALLOWED
			|	BalanceTable.Organization               AS Organization,
			|	BalanceTable.ProductionLot        AS ProductionLot,
			|	BalanceTable.ReferenceOrder              AS ReferenceOrder,
			|	BalanceTable.WorkKind                  AS WorkKind,
			|	BalanceTable.WorkKind.UnitOfMeasure AS UnitOfMeasure,
			|	BalanceTable.Performer               AS Performer,
			|	BalanceTable.Department             AS Department,
			|	BalanceTable.ReferenceRowCode     AS ReferenceRowCode,
			|	SUM(CASE
			|		WHEN BalanceTable.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN BalanceTable.Count
			|		ELSE -BalanceTable.Count
			|	END)                                    AS Count
			|FROM
			|	AdditionalLaborCostsForRegistration AS AdditionalLaborCostsForRegistration
			|	
			|	INNER JOIN AccumulationRegister.LaborCostsToRegister AS BalanceTable
			|	ON BalanceTable.Organization = AdditionalLaborCostsForRegistration.Organization
			|	AND BalanceTable.ProductionLot = AdditionalLaborCostsForRegistration.ProductionLot
			|	AND BalanceTable.ReferenceOrder = AdditionalLaborCostsForRegistration.ReferenceOrder
			|	AND BalanceTable.WorkKind = AdditionalLaborCostsForRegistration.WorkKind
			|	AND BalanceTable.Performer = AdditionalLaborCostsForRegistration.Performer
			|	AND BalanceTable.Department = AdditionalLaborCostsForRegistration.Department
			|	AND BalanceTable.ReferenceRowCode = AdditionalLaborCostsForRegistration.ReferenceRowCode
			|
			|WHERE
			|	BEGINOFPERIOD(BalanceTable.Period, MONTH) = AdditionalLaborCostsForRegistration.Month
			|
			|GROUP BY
			|	BalanceTable.Organization,
			|	BalanceTable.ProductionLot,
			|	BalanceTable.ReferenceOrder,
			|	BalanceTable.WorkKind,
			|	BalanceTable.Performer,
			|	BalanceTable.Department,
			|	BalanceTable.ReferenceRowCode
			|
			|HAVING
			|	SUM(CASE
			|		WHEN BalanceTable.RecordType = VALUE(AccumulationRecordType.Receipt)
			|			THEN BalanceTable.Count
			|		ELSE -BalanceTable.Count
			|	END) < 0
			|";
			
		QueryTexts.Add(QueryText, "ErrorsLaborCostsForRegistration");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	#Region OrdersOfMaterialsForProduction
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOrdersOfMaterialsIntoProductionChange") Then
		
		If TypeOf(Document) = Type("DocumentObject.MovementOfProductsAndMaterials")
			Then
			
			MessageTemplateForWarehouseWithDivision = NStr("vi = 'Mặt hàng %1, kho bãi %2, bộ phận %3
				|Theo dòng %4 lập nhiều hơn so với lệnh là %5 %6';
				|ru = 'Номенклатура %1, склад %2, подразделение %3
				|По строке %4 оформлено больше, чем указано в распоряжении, на %5 %6';
				|en = 'Items %1, warehouse %2, business unit %3
				| The line %4contains more registered items than stated in the instruction by %5 %6'; fa = 'Items %1, warehouse %2, business unit %3
				| The line %4contains more registered items than stated in the instruction by %5 %6';
				|it = 'Articolo %1, magazzino %2, reparto %3
				| Per la riga %4 è indicata quantità superiore rispetto alla disposizione di %5 %6';
				|pl = 'Pozycja %1, magazyn %2, dział %3 
				|W wierszu %4 sporządzono więcej, niż podano w zamówieniu o %5 %6';
				|tr = '%1 öğesi, %2 ambarı, %3 departmanı
				|%4 satırında %6 %5 üzerine talimatta belirtilenden daha fazlası oluşturuldu'");
				
			TemplateForMessageWithWarehouseWithoutDivision = NStr("vi = 'Mặt hàng %1, kho bãi %2
				|Theo dòng %4 đã lập nhiều hơn so với trong lệnh là %5 %6';
				|ru = 'Номенклатура %1, склад %2
				|По строке %4 оформлено больше, чем указано в распоряжении, на %5 %6';
				|en = 'Items %1, warehouse %2
				| The line %4contains more registered items than stated in the instruction by %5 %6'; fa = 'Items %1, warehouse %2
				| The line %4contains more registered items than stated in the instruction by %5 %6';
				|it = 'Articolo %1, magazzino %2
				| Per la riga %4  è indicata quantità superiore rispetto alla disposizione di %5 %6';
				|pl = 'Pozycja %1, magazyn %2
				|W wierszu %4 sporządzono więcej, niż podano w zamówieniu o %5 %6';
				|tr = '%1 öğesi, %2 ambarı
				|%4 satırında %6 %5 üzerine talimatta belirtilenden daha fazlası oluşturuldu'");
				
			TemplateForMessageWithoutWarehouseWithDivision = NStr("vi = 'Mặt hàng %1, bộ phận %3
				|Theo dòng %4 đã lập nhiều hơn so với trong lệnh là %5 %6';
				|ru = 'Номенклатура %1, подразделение %3
				|По строке %4 оформлено больше, чем указано в распоряжении, на %5 %6';
				|en = 'Items %1, business unit %3
				| The line %4contains more registered items than stated in the instruction by %5 %6'; fa = 'Items %1, business unit %3
				| The line %4contains more registered items than stated in the instruction by %5 %6';
				|it = 'Articolo %1, reparto %3
				| Per la riga %4  è indicata quantità superiore rispetto alla disposizione di %5 %6';
				|pl = 'Pozycja %1, dział %3
				|W wierszu %4 sporządzono więcej, niż podano w zamówieniu o %5 %6';
				|tr = '%1 öğesi, %3 departmanı
				|%4 satırında %6 %5 üzerine talimatta belirtilenden daha fazlası oluşturuldu'");
				
			MessageTemplateWithoutWarehouseWithoutDivision = NStr("vi = 'Mặt hàng %1
				|Theo dòng %4 đã lập nhiều hơn số lượng trong lệnh là %5 %6';
				|ru = 'Номенклатура %1
				|По строке %4 оформлено больше, чем указано в распоряжении, на %5 %6';
				|en = 'Items %1
				|The line %4contains more registered items than stated in the instruction by %5 %6'; fa = 'Items %1
				|The line %4contains more registered items than stated in the instruction by %5 %6';
				|it = 'Articolo %1 
				|Per la riga %4 è indicata quantità superiore rispetto alla disposizione di %5 %6';
				|pl = 'Pozycja %1
				|W wierszu %4 sporządzono więcej, niż podano w zamówieniu o %5 %6';
				|tr = '%1 öğesi
				|%4 satırında %6 %5 üzerine talimatta belirtilenden daha fazlası oluşturuldu'");
				
		Else
	
			MessageTemplateForWarehouseWithDivision = NStr("vi = 'Mặt hàng %1, kho bãi %2, bộ phận %3
				|Theo dòng %4 đã lập chứng từ chuyển giao nguyên vật liệu với số lượng lớn hơn trong chứng từ là %5 %6';
				|ru = 'Номенклатура %1, склад %2, подразделение %3
				|По строке %4 уже оформлена передача материалов в количестве большем, чем указано в документе, на %5 %6';
				|en = 'Items %1, warehouse %2, business unit %3
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5%6'; fa = 'Items %1, warehouse %2, business unit %3
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5%6';
				|it = 'Articolo %1, magazzino %2, reparto %3
				| Per la riga %4 è già stato formalizzato il trasferimento dei materiali in quantità maggiore rispetto a quanto indicato nel documento di %5 %6';
				|pl = 'Nomenklatura %1, magazyn %2, dział %3
				|W wierszu %4 już sporządzono przekazanie materiałów w większej ilości, niż podano w dokumencie o %5 %6';
				|tr = '%1 öğesi, %2 ambarı, %3 departmanı
				|%4 satırında %6 %5 üzerine malzemelerin transferi belgede belirtilenden daha fazla miktarda oluşturuldu'");
				
			TemplateForMessageWithWarehouseWithoutDivision = NStr("vi = 'Mặt hàng %1, kho bãi 2
				|Theo dòng %4 đã lập chứng từ chuyển giao nguyên vật liệu theo số lượng lớn hơn trong chứng từ là %5 %6';
				|ru = 'Номенклатура %1, склад 2
				|По строке %4 уже оформлена передача материалов в количестве большем, чем указано в документе, на %5 %6';
				|en = 'Items %1, warehouse 2 
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5 %6'; fa = 'Items %1, warehouse 2 
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5 %6';
				|it = 'Articolo %1, magazzino 
				| Per la riga %4 è già stato formalizzato il trasferimento dei materiali in quantità maggiore rispetto a quanto indicato nel documento di %5 %6';
				|pl = 'Nomenklatura %1, magazyn 
				|W wierszu %4 już sporządzono przekazanie materiałów w większej ilości, niż podano w dokumencie o %5 %6';
				|tr = '%1 öğesi, 2 ambarı
				|%4 satırında %6 %5 üzerine malzemelerin transferi belgede belirtilenden daha fazla miktarda oluşturuldu'");
				
			TemplateForMessageWithoutWarehouseWithDivision = NStr("vi = 'Mặt hàng %1, bộ phận %3
				|Theo dòng %4 đã lập chứng từ chuyển giao nguyên vật liệu với số lượng lớn hơn trong chứng từ là %5 %6';
				|ru = 'Номенклатура %1, подразделение %3
				|По строке %4 уже оформлена передача материалов в количестве большем, чем указано в документе, на %5 %6';
				|en = 'Items %1, business unit%3 
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5 %6'; fa = 'Items %1, business unit%3 
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5 %6';
				|it = 'Articolo %1, reparto %3
				| Per la riga %4 è già stato formalizzato il trasferimento dei materiali in quantità maggiore rispetto a quanto indicato nel documento di %5 %6';
				|pl = 'Nomenklatura %1, dział %3
				|W wierszu %4 już sporządzono przekazanie materiałów w większej ilości, niż podano w dokumencie o %5 %6';
				|tr = '%1 öğesi, %3 departmanı 
				|%4 satırında %6 %5 üzerine malzemelerin transferi belgede belirtilenden daha fazla miktarda oluşturuldu'");
				
			MessageTemplateWithoutWarehouseWithoutDivision = NStr("vi = 'Mặt hàng %1
				|Theo dòng %4 đã lập chứng từ chuyển giao nguyên vật liệu theo số lượng lớn hơn trong chứng từ là %5 %6';
				|ru = 'Номенклатура %1
				|По строке %4 уже оформлена передача материалов в количестве большем, чем указано в документе, на %5 %6';
				|en = 'Items %1
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5 %6'; fa = 'Items %1
				| In line %4, the transfer of materials has already been registered in quantity greater than specified in the document by %5 %6';
				|it = 'Articolo %1
				| Per la riga %4 è già stato formalizzato il trasferimento dei materiali in quantità maggiore rispetto a quanto indicato nel documento di %5 %6';
				|pl = 'Nomenklatura %1
				|W wierszu %4 już sporządzono przekazanie materiałów w większej ilości, niż podano w dokumencie o %5 %6';
				|tr = '%1 öğesi
				|%4 satırında %6 %5 üzerine malzemelerin transferi belgede belirtilenden daha fazla miktarda oluşturuldu'");
				
		EndIf;
		
		For Each ErrorString In ControlResults.ErrorsOrderingMaterialsIntoProduction Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products, ErrorString.Characteristic);
			
			If ValueIsFilled(ErrorString.Warehouse)
				And ValueIsFilled(ErrorString.Department) Then
				MessageText = StrTemplate(MessageTemplateForWarehouseWithDivision,
					ProductPresentation, ErrorString.Warehouse, ErrorString.Department,
					ErrorString.RowCode, -ErrorString.Count, ErrorString.UnitOfMeasure);
			ElsIf ValueIsFilled(ErrorString.Warehouse)
				And Not ValueIsFilled(ErrorString.Department) Then
				MessageText = StrTemplate(TemplateForMessageWithWarehouseWithoutDivision,
					ProductPresentation, ErrorString.Warehouse,,
					ErrorString.RowCode, -ErrorString.Count, ErrorString.UnitOfMeasure);
			ElsIf Not ValueIsFilled(ErrorString.Warehouse)
				And ValueIsFilled(ErrorString.Department) Then
				MessageText = StrTemplate(TemplateForMessageWithoutWarehouseWithDivision,
					ProductPresentation,, ErrorString.Department,
					ErrorString.RowCode, -ErrorString.Count, ErrorString.UnitOfMeasure);
			Else 
				MessageText = StrTemplate(MessageTemplateWithoutWarehouseWithoutDivision, ProductPresentation,,,
					ErrorString.RowCode, -ErrorString.Count, ErrorString.UnitOfMeasure);
			EndIf;
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	
	#Region ReferencesToTransferFromProduction
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOfTransferOrderFromProductionChange") Then
		
		For Each ErrorString In ControlResults.ErrorsInTransferOrderFromProduction Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products, ErrorString.Characteristic);
			
			If TypeOf(Document) = Type("DocumentObject.ProductionStage2_2") Then
				// This is the execution of the order
				If ErrorString.DateControl Then
					If ErrorString.Operation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
						MessageText = StrTemplate(
							NStr("vi = 'Mặt hàng %1 đã lập chứng từ xuất xưởng và lệnh cần lập trước khi xuất xưởng';
								|ru = 'На позицию %1 уже оформлен выпуск и распоряжение должно быть оформлено не позже выпуска';
								|en = 'Release is already registered for item %1, the reference should be registered not later than the release'; fa = 'Release is already registered for item %1, the reference should be registered not later than the release';
								|it = 'Alla voce %1 l''emissione è già avvenuta e la disposizione deve entrare in funzione non più tardi dell''emissione';
								|pl = 'W pozycji %1 jest już zatwierdzone wydanie i zamówienie powinno zostać wystawione nie później niż w momencie wydania';
								|tr = '%1 pozisyonuna yönelik ürün çıkışı oluşturuldu ve talimat, ürün çıkışından sonra oluşturulmamalıdır'"),
							ProductPresentation);
					Else
						MessageText = StrTemplate(
							NStr("vi = 'Mặt hàng %1 đã lập chứng từ trả lại và lệnh cần lập trước khi trả lại';
								|ru = 'На позицию %1 уже оформлен возврат и распоряжение должно быть оформлено не позже возврата';
								|en = 'Return has already been registered for the %1 item. Reference should be registered not later then return'; fa = 'Return has already been registered for the %1 item. Reference should be registered not later then return';
								|it = 'Alla voce %1 il reso è già stato emesso e la disposizione non deve essere emessa più tardi del reso';
								|pl = 'W pozycji %1 jest już zatwierdzony zwrot i zamówienie powinno zostać wystawione nie później niż w momencie zwrotu';
								|tr = '%1 pozisyonuna yönelik iade oluşturuldu ve talimat, iadeden sonra oluşturulmamalıdır'"),
							ProductPresentation);
					EndIf;
				Else
					If ErrorString.Operation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
						MessageText = StrTemplate(
							NStr("vi = 'Mặt hàng %1 xuất xưởng với số lượng lớn hơn so với trong chứng từ, theo  %2 %3';
								|ru = 'На позицию %1 оформлен выпуск в количестве большем, чем указано в документе, на %2 %3';
								|en = 'Registered release for the %1 item exceeds the one specified in the document by %2 %3'; fa = 'Registered release for the %1 item exceeds the one specified in the document by %2 %3';
								|it = 'Alla voce %1 l''emissione è già avvenuta in quantità superiore del %2 %3 rispetto a quella indicata nel documento';
								|pl = 'Pozycja %1 jest wydawana w wysokości większej niż określona w dokumencie na %2 %3';
								|tr = '%1 pozisyonuna yönelik %3 %2 üzerine ürün çıkışı, belgede belirtilenden daha fazla miktarda oluşturuldu'"),
							ProductPresentation, -ErrorString.Count, ErrorString.UnitOfMeasure);
					Else
						MessageText = StrTemplate(
							NStr("vi = 'Mặt hàng %1 trả lại với số lượng lớn hơn so với trong chứng từ, theo  %2 %3';
								|ru = 'На позицию %1 оформлен возврат в количестве большем, чем указано в документе, на %2 %3';
								|en = 'Registered return for the %1 item exceeds the one specified in the document by %2 %3'; fa = 'Registered return for the %1 item exceeds the one specified in the document by %2 %3';
								|it = 'Alla voce %1 il reso è già stato emesso in quantità superiore del %2 %3 rispetto a quella indicata nel documento';
								|pl = 'Pozycja %1 jest zwracana w wysokości większej niż określona w dokumencie na %2 %3';
								|tr = '%1 pozisyonuna yönelik %3 %2 üzerine iade, belgede belirtilenden daha fazla miktarda oluşturuldu'"),
							ProductPresentation, -ErrorString.Count, ErrorString.UnitOfMeasure);
					EndIf; 
				EndIf;
			Else
				// This is carrying out an invoice
				If ErrorString.DateControl Then
					If ErrorString.Operation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
						MessageText = StrTemplate(
							NStr("vi = 'Xuất xưởng sản phẩm %1 phải được lập không sớm hơn ngày hoàn thành công đoạn sản xuất';
								|ru = 'Выпуск позиции %1 должен быть оформлен не раньше даты завершения выполнения этапа производства';
								|en = 'The %1 position release must be generated not earlier than the end date of the production stage'; fa = 'The %1 position release must be generated not earlier than the end date of the production stage';
								|it = 'L''emissione della voce %1 deve avvenire non prima della pubblicazione dei dati di completamento della fase di produzione';
								|pl = 'Wydanie pozycji %1 musi być zatwierdzone nie wcześniej niż data końcowa fazy produkcji';
								|tr = '%1 ürün çıkışı pozisyonu, üretim aşamasının tamamlanma tarihinden önce oluşturulmamalıdır'"),
							ProductPresentation);
					Else
						MessageText = StrTemplate(
							NStr("vi = 'Việc trả lại mặt hàng %1 phải được lập không sớm hơn ngày hoàn thành công đoạn sản xuất';
								|ru = 'Возврат позиции %1 должен быть оформлен не раньше даты завершения выполнения этапа производства';
								|en = 'The %1 item return should be registered not earlier than the date of production stage end'; fa = 'The %1 item return should be registered not earlier than the date of production stage end';
								|it = 'Il reso della voce %1 deve avvenire non prima della pubblicazione dei dati di completamento della fase di produzione';
								|pl = 'Zwrot pozycji %1 musi być zatwierdzone nie wcześniej niż data końcowa fazy produkcji';
								|tr = '%1 iade pozisyonu, üretim aşamasının tamamlanma tarihinden önce oluşturulmamalıdır'"),
							ProductPresentation);
					EndIf;
				Else
					MessageText = StrTemplate(
						NStr("vi = 'Số lượng vị trí %1 vượt quá số lượng theo thứ tự %2%3';
							|ru = 'Количество позиций %1 превышает количество по распоряжению на %2 %3';
							|en = 'The %1 position quantity exceeds the quantity under the reference by %2 %3'; fa = 'The %1 position quantity exceeds the quantity under the reference by %2 %3';
							|it = 'La quantità di voci %1 supera la quantità prevista dalla disposizione del %2 %3';
							|pl = 'Ilość pozycji %1 przekracza ilość wg zamówienia na %2 %3';
							|tr = '%1 pozisyon miktarı, %3 %2 üzerine talimattaki miktarı aşmaktadır'"),
						ProductPresentation, -ErrorString.Count, ErrorString.UnitOfMeasure);
				EndIf;
			EndIf;
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region LaborCostsToRegister
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "AdditionalLaborCostsForRegistration") Then
		
		If TypeOf(Document) = Type("DocumentObject.WorkOutput") Then
			MessageTemplate = NStr("vi = 'Số lượng theo dạng công việc ""%1""
				| vượt quá hoặc không tương ứng với dữ liệu của lệnh ""%2"" (là %3 %4)';
				|ru = 'Количество по виду работ ""%1""
				| превышает или не соответствует данным распоряжения ""%2"" (на %3 %4)';
				|en = 'The quantity according to the ""%1"" activity kind
				| exceeds or does not correspond to the ""%2"" reference data (by %3 %4)'; fa = 'The quantity according to the ""%1"" activity kind
				| exceeds or does not correspond to the ""%2"" reference data (by %3 %4)';
				|it = 'The quantity according to the ""%1"" activity kind
				| exceeds or does not correspond to the ""%2"" reference data (by %3 %4)';
				|pl = 'The quantity according to the ""%1"" activity kind
				| exceeds or does not correspond to the ""%2"" reference data (by %3 %4)';
				|tr = '""%1"" iş türüne ilişkin miktar ""
				|, mevcut ""%2"" talimatlarını aşmakta veya karşılamamaktadır (%4 %3 üzerine)'");
		Else
			MessageTemplate = NStr("vi = 'Sản lượng của nhân viên theo dạng công việc  ""%1""
				| theo lệnh ""%2"" đã lập là %3 %4';
				|ru = 'Выработка сотрудников по виду работ ""%1""
				| по распоряжению ""%2"" уже оформлена на %3 %4';
				|en = 'Timesheets charge by the ""%1"" activity kind
				| under the ""%2"" reference is already generated for %3 %4'; fa = 'Timesheets charge by the ""%1"" activity kind
				| under the ""%2"" reference is already generated for %3 %4';
				|it = 'Timesheets charge by the ""%1"" activity kind
				| under the ""%2"" reference is already generated for %3 %4';
				|pl = 'Timesheets charge by the ""%1"" activity kind
				| under the ""%2"" reference is already generated for %3 %4';
				|tr = '""%1"" iş türüne ilişkin ""%2"" talimatı kapsamında
				|zaman çizelgesi bazlı ücretlendirmesi %3 %4 için zaten oluşturuldu'");
		EndIf;
		
		For Each ErrorString In ControlResults.ErrorsLaborCostsForRegistration Do
			
			MessageText =
				StrTemplate(
					MessageTemplate,
					ErrorString.WorkKind,
					ErrorString.ReferenceOrder,
					-ErrorString.Count,
					ErrorString.UnitOfMeasure);
			
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region Settings

// Gets the settings of the "Production" subsystem"
// 
// Returns:
//   - Structure - settings of the "Production" subsystem
//
Function SubsystemSettingsProduction() Export
	
	Result = New Structure;
	
	Result.Insert("ProductionIsUsed", GetFunctionalOption("UseProduction"));
	
	Result.Insert("ProductionIsUsed21", GetFunctionalOption("UseProductionManagement"));
	Result.Insert("ProductionIsUsed22", GetFunctionalOption("UseProductionManagement2_2"));

	Result.Insert("DynamicStructureOfProductionOrders", False);
	Result.Insert("TheProductionScheduleIsPlanned", False);
	Result.Insert("PlanningByProductionResourcesIsUsed", False);
	Result.Insert("PlanningByMaterialResourcesIsUsed", False);
	Result.Insert("ScheduleDateFormat", "DLF=D");
	Result.Insert("DateFormatOfSchedulePartOfDate", DateFractions.Date);
	ProductionManagementSettings = ProductionManagement.ProductionManagementSettings();
	FillPropertyValues(Result, ProductionManagementSettings);
	Result.Insert("ProductionByThirdPartyIsUsed", False);
	
	Result.Insert("ProductionByThirdPartyIsUsed2_5",
		GetFunctionalOption("UseProductionByThirdParty2_5"));
	Result.Insert("UseSubcontractOrders2_5",
		GetFunctionalOption("UseSubcontractOrders2_5"));
		
	Return Result;
	
EndFunction

// Returns parameters of the production division
//
// Parameters:
//  Department	- CatalogRef.BusinessStructure - The Department that you want to get parameters for
//
// Returns:
//   Structure   - contains the parameters of the production unit
//
Function ProductionBusinessUnitDescription(Department) Export
	
	DepartmentList = New Array;
	DepartmentList.Add(Department);
	Parameters = ParametersOfProductionUnits(DepartmentList);
	Return Parameters[Department];
	
EndFunction

// Returns parameters of the production division
//
// Parameters:
//  DepartmentList - Array - the list of divisions for which to retrieve parameters
//
// Returns:
//  Map - Where:
//  *Key - CatalogRef.BusinessStructure
//  *Value - See StructureOfProductionUnitDetails.
//
Function ParametersOfProductionUnits(DepartmentList) Export
	
	Query = New Query(
	"SELECT
	|	BusinessStructure.Description           AS Description,
	|	BusinessStructure.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
	|
	|	BusinessStructure.ProductionBusinessUnit AS ProductionBusinessUnit,
	|	BusinessStructure.ProductionByOrders  AS ProductionByOrders,
	|	BusinessStructure.BackflushProduction_ AS BackflushProduction_,
	|
	|	BusinessStructure.RecordingExpensesOnProcustCostIsUsed AS RecordingExpensesOnProcustCostIsUsed,
	|
	|	BusinessStructure.WorkSchedules.(
	|		WorkScheduleCalendar AS Schedule
	|	)                                     AS Schedules,
	|	MainEnterpriseCalendar.Value AS MainSchedule,
	|
	|	BusinessStructure.PlanningInterval           AS PlanningInterval,
	|	BusinessStructure.PlanningIntervalStart    AS PlanningIntervalStart,
	|	BusinessStructure.PlanningIntervalEnd AS PlanningIntervalEnd,
	|
	|
	|	BusinessStructure.UseOperationManagement   AS UseOperationManagement,
	|	BusinessStructure.UseManufacturingExecutionSystem AS UseManufacturingExecutionSystem,
	|
	|	BusinessStructure.UseMaterialsInOperations        AS UseMaterialsInOperations,
	|	BusinessStructure.UseFinishedProductsInOperations  AS UseFinishedProductsInOperations,
	|
	|	BusinessStructure.UseShiftTasks             AS UseShiftTasks,
	|	CASE
	|		WHEN BusinessStructure.WorkScheduleSetupMethod = VALUE(Enum.MethodsOfConfiguringBusinessUnitWorkSchedule.Shifts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                       AS UseShifts,
	|
	|	BusinessStructure.UseProductionSites    AS UseAreas,
	|
	|	BusinessStructure.UseTeamWorkOrders            AS UseTeamWorkOrders,
	|	BusinessStructure.UsePersonalWorkOrders         AS UsePersonalWorkOrders,
	|
	|	BusinessStructure.Ref AS Ref
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|
	|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
	|		ON (TRUE)
	|
	|WHERE
	|	BusinessStructure.Ref IN (&DepartmentList)
	|");
	Query.SetParameter("DepartmentList", DepartmentList);

	ParameterValues = New Map;
	
	For Each Ref In DepartmentList Do
		Result = StructureOfProductionUnitDetails();
		ParameterValues.Insert(Ref, Result);
	EndDo;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	While Selection.Next() Do
		
		FillPropertyValues(ParameterValues[Selection.Ref], Selection);
		
		If Selection.Schedules.IsEmpty() Then
			ParameterValues[Selection.Ref].WorkSchedules.Add(Selection.MainSchedule);
		Else
			ParameterValues[Selection.Ref].WorkSchedules = Selection.Schedules.Unload().UnloadColumn("Schedule");
		EndIf;
		
	EndDo;
	
	Return ParameterValues;
	
EndFunction

// Determines whether production version 2.1 is used
// 
// Returns:
//   Boolean - True if production version 2.1 is used
//
Function ProductionIsUsed21() Export
	
	Return GetFunctionalOption("UseProductionManagement");
	
EndFunction

// Determines whether production version 2.2 is used
// 
// Returns:
//   Boolean - True if production version 2.2 is used
//
Function ProductionIsUsed22() Export
	
	Return GetFunctionalOption("UseProductionManagement2_2");
	
EndFunction

// Determines whether series are used in production of version 2.2.
//
// Returns:
//  Structure - a structure with the following keys:
//  *UseItemsBatch - Boolean
//  *UseCostAccountingByBatches - Boolean
//
Function UseOfSeriesInProduction22() Export
	
	Result = New Structure("UseItemsBatch, UseCostAccountingByBatches", False, False);
	Result.Insert("UseItemsBatch", GetFunctionalOption("UseItemsBatchProduction22"));
	Result.Insert("UseCostAccountingByBatches", GetFunctionalOption("UseCostAccountingByBatchesProduction22"));
	Return Result;
	
EndFunction

// Sets the use of parameterization depending on the production usage
//
Procedure EstablishUseOfParameterizationOfResourceSpecifications() Export
	
	EnterpriseManagement = False;
	EnterpriseManagement = True;
	ConstantValue = False;
	
	If GetFunctionalOption("UseProduction") And EnterpriseManagement Then
		
		ConstantValue = True;
		
	EndIf;
	
	Constants.UseBillOfMaterialsParameterization.Set(ConstantValue);
	
EndProcedure

// Sets options for working with production operations depending on the use of production
//
Procedure SetOptionsForWorkingWithProductionOperations(Production21 = Undefined, Production22 = Undefined) Export
	
	EnterpriseManagement = False;
	EnterpriseManagement = True;
	If Production21 = Undefined Then
		Production21 = Constants.UseProductionManagement.Get();
	EndIf;
	
	If Production22 = Undefined Then
		Production22 = Constants.UseProductionManagement2_2.Get();
	EndIf;
	
	Constants.UseRouteSheets.Set(Production21 And EnterpriseManagement);
	Constants.StoreOperationsInBillsOfMaterials.Set(Not Production21 And Production22 And EnterpriseManagement);
	Constants.UseTechnologicalProcesses.Set(Not Production21 And Production22 And EnterpriseManagement);
EndProcedure

// Defines the use of sites in units with operational management
// 
// Returns:
//  Boolean
Function UseAreasForPostoperativeManagement() Export
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|		INNER JOIN Catalog.ProductionSites AS ProductionSites
		|		ON BusinessStructure.Ref = ProductionSites.Owner
		|WHERE
		|	BusinessStructure.UseOperationManagement
		|	AND NOT BusinessStructure.UseManufacturingExecutionSystem
		|	AND BusinessStructure.UseProductionSites");
		
	SetPrivilegedMode(True);
	UseAreas = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);
	
	Return UseAreas;
	
EndFunction

// Defines the use of plots in units with operational planning
// 
// Returns:
//  Boolean
Function UseAreasInPostoperativePlanning() Export
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|		INNER JOIN Catalog.ProductionSites AS ProductionSites
		|		ON BusinessStructure.Ref = ProductionSites.Owner
		|WHERE
		|	BusinessStructure.UseManufacturingExecutionSystem
		|	AND BusinessStructure.UseProductionSites");
	
	SetPrivilegedMode(True);
	UseAreas = Not Query.Execute().IsEmpty();
	SetPrivilegedMode(False);	
	
	Return UseAreas;
	
EndFunction

#EndRegion

#Region InputOnBasis

// Adds a command to create a document
//
// Parameters:
//  CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined -
//
Function AddCreateContentTransferCommandBasedOn(CreateCommandsBasedOn) Export
	
	CreateBasedOnCommand = Undefined;
	
	If GetFunctionalOption("UseProductionManagement2_2") Then
		
		If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials) Then
			
			TransactionList = Documents.MovementOfProductsAndMaterials.TransactionList();
			Operation = TransactionList.FindByValue(Enums.BusinessTransactions.TransferOfMaterialsToStoreroom);
			
			If Operation <> Undefined Then
				
				CreateBasedOnCommand = CreateCommandsBasedOn.Add();
				CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
				CreateBasedOnCommand.Presentation = Operation.Presentation;
				CreateBasedOnCommand.Handler = "ProductionClient.CreateTransferOfMaterialsToPantryBasedOn";
				CreateBasedOnCommand.WriteMode = "Post";
				CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
				CreateBasedOnCommand.MultipleChoice = True;
				
			EndIf;
			
		EndIf;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	
	Return CreateBasedOnCommand;
	
EndFunction

// Adds a command to create a document
//
// Parameters:
//  CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined -
//
Function AddCommandCreateProductReleaseWithoutOrderBasedOn(CreateCommandsBasedOn) Export
	
	If AccessRight("Insert", Metadata.Documents.MovementOfProductsAndMaterials) Then
		
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.MovementOfProductsAndMaterials.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Chuyển sản phẩm';
												|ru = 'Передача выпущенной продукции';
												|en = 'Transfer released products'; fa = 'Transfer released products';
												|it = 'Consegna dei prodotti emessi';
												|pl = 'Przekazanie wypuszczonej produkcji';
												|tr = 'İmal edilen ürünlerin transferi'");
		CreateBasedOnCommand.Handler = "ProductionClient.CreateProductReleaseWithoutOrderBasedOn";
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		
		CreateBasedOnCommand.FunctionalOptions = "UseProductionManagement2_2";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region JobsQueue

// Adds a task or list of tasks to the queue
//
// Parameters:
//  Queue 	- String			 - queue name (name of the queue information register).
//  Job 	- Structure, Array, ValueTable	 - a structure with the values of dimensions, details, and resources
//											, or an array of tasks for registering multiple tasks at a time.
// 
// Returns:
//  Array - ids of new tasks.
//
Function AddTaskToQueue(Queue, Job) Export
	
	RecordSet = InformationRegisters[Queue].CreateRecordSet();// InformationRegisterRecordSet
	
	IDs = New Array;
	RegistrationDay = Int((CurrentUniversalDate() - '20000101000000') / 86400);
	
	If TypeOf(Job) = Type("Array") Or TypeOf(Job) = Type("ValueTable") Then
		JobsList = Job;
	Else
		JobsList = TMCommonUseClientServer.Array(Job);
	EndIf;
	
	For Each CurrentData In JobsList Do
		
		NewJob = RecordSet.Add();
		FillPropertyValues(NewJob, CurrentData);
		
		NewJob.RegistrationDay = RegistrationDay;
		NewJob.Id = New UUID;
		
		IDs.Add(NewJob.Id);
		
	EndDo;
	
	SetPrivilegedMode(True);
	
	RecordSet.Write(False);
	
	SetPrivilegedMode(False);
	
	Return IDs;
	
EndFunction

// Starts the queue handler background task
//
// Parameters:
//  Queue			 - String							 - queue name (name of the queue information register).
//  Filter			 - Structure						 - tasks for this selection will be processed first.
//  Id	 - UUID, Array	 - ID or list of task IDs
//	  If a background task is started in the same transaction as adding new tasks to the queue, you may have a situation
//	     where the background task is started, the transaction is not completed, and the tasks to process are not visible to the background task session.
//	  To solve this problem, before processing the first batch of tasks from the queue, a transaction
//       is opened and a lock is set on tasks in the queue by ID.
//  WaitForExecutionCompletion - Boolean				 - defines the behavior if the
//    queue processing that was started earlier is already running when the task is started.
//    If True is passed, the queue will wait for processing to complete, and then
//    another iteration will be started.
//    If the value is False, then waiting and restarting are not performed.
//
Procedure StartQueueProcessingJob(Queue, Filter = Undefined, Id = Undefined, WaitForExecutionCompletion = False) Export
	
	If TaskQueueIsEmpty(Queue, Filter) Then
		Return;
	EndIf;
	
	Var_Key = Queue + ".QueueProcessing";
	
	SetPrivilegedMode(True);
	
	SearchKey = New Structure("Key, State", Var_Key, BackgroundJobState.Active);
	
	Jobs = BackgroundJobs.GetBackgroundJobs(SearchKey);
	If Jobs.UBound() <> -1 Then
		If WaitForExecutionCompletion Then
			BackgroundJobs.WaitForExecutionCompletion(Jobs);
		Else
			Return;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
	ExportProcedureName = "ProductionServer.ProcessTaskQueue";
	
	FillParameters = New Structure;
	FillParameters.Insert("Queue", Queue);
	FillParameters.Insert("Filter", Filter);
	FillParameters.Insert("Id", Id);
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(FillParameters);
	
	JobParameters = New Array;
	JobParameters.Add(ExportProcedureName);
	JobParameters.Add(ExportProcedureParameters);
	
	JobDescription = StrTemplate(NStr("vi = 'Xử lý hàng đợi < %1>';
										|ru = 'Обработка очереди <%1>';
										|en = 'Processing queue <%1>'; fa = 'Processing queue <%1>';
										|it = 'Elaborazione di fila <%1>';
										|pl = 'Przetwarzanie kolejki <%1>';
										|tr = 'Kuyruğun işlenmesi <%1>'"), Metadata.InformationRegisters[Queue].Synonym);
	
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
EndProcedure

// Checks the activity of the background queue processing task
//
// Parameters:
//  Queue - String - queue name (name of the queue information register).
// 
// Returns:
//  Boolean - True if the job queue is being processed
//
Function QueueProcessingIsInProgress(Queue) Export
	
	Var_Key = Queue + ".QueueProcessing";
	
	SearchKey = New Structure("Key, State", Var_Key, BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	Jobs = BackgroundJobs.GetBackgroundJobs(SearchKey);
	SetPrivilegedMode(False);
	
	Return (Jobs.Count() > 0 And Jobs[0].State = BackgroundJobState.Active);
	
EndFunction

#EndRegion

#Region CalculationOfCostShares

// Calculates the share of the cost of output items for the tabular part of the document
//
// Parameters:
//  Object						 - FormDataStructure	 - main details of the directory form, document
//  CostAllocationParameters - Structure			 - structure of calculation parameters, See ProductionClientServer.CostAllocationParametersForOutputProducts
//
Procedure CalculateFractionOfCost(Object, CostAllocationParameters) Export
	
	TabularSection = Object[CostAllocationParameters.TSName];
	
	If Not ValueIsFilled(TabularSection) Then
		Return;
	EndIf;
	
	If Not IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		Raise NStr("vi = 'Thông số phân bổ chi phí không chính xác thông qua.';
					|ru = 'Некорректно переданы параметры распределения затрат.';
					|en = 'Cost allocation parameters are transferred incorrectly.'; fa = 'Cost allocation parameters are transferred incorrectly.';
					|it = 'Sono stati passati incorrettamente i parametri di allocazione delle spese.';
					|pl = 'Parametry alokacji kosztów są nieprawidłowe.';
					|tr = 'Maliyet dağıtımı parametreleri doğru şekilde aktarılmadı.'");
	EndIf;
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	QueryText =
	"SELECT
	|	Table.LineNumber        AS LineNumber,
	|
	|	Table.Products       AS Products,
	|	Table.Characteristic     AS Characteristic,
	|
	|	&FieldSeries,
	|	Table.Package           AS Package,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Count         AS Count,
	|
	|	Table.CostShare      AS CostShare
	|
	|INTO TabularSection
	|FROM
	|	&Table AS Table
	|;
	|";
	
	If UsePriceManagementSystem25 Then
		QueryText = StrReplace(QueryText, "TabularSection", "TabularSectionPreliminary") + 
		"
		|SELECT
		|	Table.LineNumber        AS LineNumber,
		|	Table.Products       AS Products,
		|	Table.Characteristic     AS Characteristic,
		|	Table.Package           AS Package,
		|	Table.NumberOfPackages AS NumberOfPackages,
		|	Table.Count         AS Count,
		|	Table.CostShare      AS CostShare,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE Table.Characteristic.ItemsCharacteristicForPricing
		|	END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
		|		ELSE Table.Series.ItemsBatchForPricing
		|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE Table.Package
		|	END AS PricingPackage
		|
		|INTO TabularSection
		|FROM
		|	TabularSectionPreliminary AS Table
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = Table.Products.ProductKind
		|;
		|";
		
	EndIf;
	
	SubstituteTextOfAutoCalculationRequestForAnyCharacteristic(QueryText, 
																	CostAllocationParameters, 
																	UsePriceManagementSystem25);
	
	QueryText = QueryText + 
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|
	|	&CostShare AS CostShare,
	|	&CostSharePerUnit AS CostSharePerUnit
	|
	|FROM
	|	TabularSection AS TabularSection
	|	,CompoundShareCost
	|;
	|";

	If UsePriceManagementSystem25 Then
		
		QueryText = StrReplace(QueryText, "&FieldSeries,", "Table.Series AS Series,");
		
		SubstitutionParameters = SubstitutionParametersOfCostFractionCalculationAlgorithm(
			"TabularSection",
			"&MethodOfAllocatingFinishedProductCosts",
			"(Products, PricingVariant, PricingBatch, PricingPackage) IN (
			|	SELECT
			|		T.Products,
			|		T.PricingVariant,
			|		T.PricingBatch,
			|		T.PricingPackage
			|	FROM
			|		TabularSection AS T)",
			UsePriceManagementSystem25);
			
	Else
		
		QueryText = StrReplace(QueryText, "&FieldSeries,", "");
		
		SubstitutionParameters = SubstitutionParametersOfCostFractionCalculationAlgorithm(
			"TabularSection",
			"&MethodOfAllocatingFinishedProductCosts",
			"(Products, Characteristic) IN (
			|	SELECT
			|		T.Products,
			|		T.Characteristic
			|	FROM
			|		TabularSection AS T)",
			UsePriceManagementSystem25);
			
	EndIf;

	PerformSubstitutionOfCostFractionCalculationAlgorithm(QueryText, SubstitutionParameters, UsePriceManagementSystem25);

	Query = New Query(QueryText);
	
	Query.SetParameter("PriceKind", ProductionServerCached.TypeOfPricePlannedCost_());
	Query.SetParameter("MethodOfAllocatingFinishedProductCosts", CostAllocationParameters.MethodOfAllocatingFinishedProductCosts);
	
	UnloadingColumns = "LineNumber, Products, Characteristic, Count, CostShare";
	ColumnsByValue = New Structure();
	
	If CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "Package") Then
		UnloadingColumns = UnloadingColumns + ", Package";
	Else
		ColumnsByValue.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "NumberOfPackages") Then
		UnloadingColumns = UnloadingColumns + ", NumberOfPackages";
	Else
		ColumnsByValue.Insert("NumberOfPackages", 0);
	EndIf;
	
	If UsePriceManagementSystem25 Then
		If CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "Series") Then
			UnloadingColumns = UnloadingColumns + ", Series";
		Else
			ColumnsByValue.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
		EndIf;
	EndIf;
	ValueTable = TMCommonUse.ExportValuesTable(TabularSection,, UnloadingColumns, ColumnsByValue);
	
	Query.SetParameter("Table", ValueTable);
	Query.SetParameter("Date", ?(ValueIsFilled(
												CostAllocationParameters.ParametersForFillingInCostShares.Date), 
												CostAllocationParameters.ParametersForFillingInCostShares.Date, 
												CurrentSessionDate()));
	Query.SetParameter("Currency", ?(ValueIsFilled(
												CostAllocationParameters.ParametersForFillingInCostShares.Currency), 
												CostAllocationParameters.ParametersForFillingInCostShares.Currency, 
												ProductionServerCached.PlannedPriceCurrencyOfProductsMaterialsAndLabor()));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	While Selection.Next() Do
		ProductionClientServer.FillInCostFractionInLine(TabularSection[Selection.LineNumber - 1], Selection);
	EndDo;
	
EndProcedure

// Calculates the share of the cost of a table part row
//
// Parameters:
//  RowData				 - Structure - table part string
//  CostAllocationParameters - See ProductionClientServer.CostAllocationParametersForOutputProducts
// 
// Returns:
//  Structure - See ProductionClientServer.StructureOfShareValueFields :
// * CostShare - Number -
// * CostSharePerUnit - Number -
Function CalculateShareOfProductValue(RowData, CostAllocationParameters) Export
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();

	QueryText =
	"SELECT
	|	0                   AS LineNumber,
	|
	|	&Products       AS Products,
	|	&Characteristic     AS Characteristic,
	|
	|	&FieldSeries,
	|	&Package           AS Package,
	|	&NumberOfPackages AS NumberOfPackages,
	|	&Count         AS Count,
	|
	|	0                   AS CostShare
	|
	|INTO TabularSection
	|;
	|";

	If UsePriceManagementSystem25 Then
		QueryText = StrReplace(QueryText, "TabularSection", "TabularSectionPreliminary") + 
		"
		|SELECT
		|	Table.LineNumber        AS LineNumber,
		|	Table.Products       AS Products,
		|	Table.Characteristic     AS Characteristic,
		|	Table.Package           AS Package,
		|	Table.NumberOfPackages AS NumberOfPackages,
		|	Table.Count         AS Count,
		|	Table.CostShare      AS CostShare,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE Table.Characteristic.ItemsCharacteristicForPricing
		|	END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
		|		ELSE Table.Series.ItemsBatchForPricing
		|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE Table.Package
		|	END AS PricingPackage
		|
		|INTO TabularSection
		|FROM
		|	TabularSectionPreliminary AS Table
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = Table.Products.ProductKind
		|;
		|";
		
	EndIf;

	SubstituteTextOfAutoCalculationRequestForAnyCharacteristic(QueryText, CostAllocationParameters, UsePriceManagementSystem25);
	
	QueryText = QueryText + 
	"SELECT
	|	&CostShare AS CostShare,
	|	&CostSharePerUnit AS CostSharePerUnit
	|FROM
	|	TabularSection AS TabularSection
	|	,CompoundShareCost
	|;
	|";
	
	If UsePriceManagementSystem25 Then
	
		QueryText = StrReplace(QueryText, "&FieldSeries,", "&Series AS Series,");
	
		SubstitutionParameters = SubstitutionParametersOfCostFractionCalculationAlgorithm(
			"TabularSection",
			"&MethodOfAllocatingFinishedProductCosts",
			"(Products, PricingVariant, PricingBatch, PricingPackage) IN (
			|	SELECT
			|		T.Products,
			|		T.PricingVariant,
			|		T.PricingBatch,
			|		T.PricingPackage
			|	FROM
			|		TabularSection AS T)",
			UsePriceManagementSystem25);
			
	Else
		
		QueryText = StrReplace(QueryText, "&FieldSeries,", "");
		
		SubstitutionParameters = SubstitutionParametersOfCostFractionCalculationAlgorithm(
			"TabularSection",
			"&MethodOfAllocatingFinishedProductCosts",
			"(Products, Characteristic) IN (
			|	SELECT
			|		T.Products,
			|		T.Characteristic
			|	FROM
			|		TabularSection AS T)",
			UsePriceManagementSystem25);
			
	EndIf;
	
	PerformSubstitutionOfCostFractionCalculationAlgorithm(QueryText, SubstitutionParameters, UsePriceManagementSystem25);

	Query = New Query(QueryText);
	
	Query.SetParameter("Products",       RowData.Products);
	Query.SetParameter("Characteristic",     RowData.Characteristic);
	
	Query.SetParameter("Package",           RowData.Package);
	Query.SetParameter("NumberOfPackages", RowData.NumberOfPackages);
	Query.SetParameter("Count",         RowData.Count);
	If UsePriceManagementSystem25 Then
		If RowData.Property("Series") And TypeOf(RowData.Series) = Type("CatalogRef.ItemsBatches") Then
			Query.SetParameter("Series", RowData.Series);
		Else
			Query.SetParameter("Series", Catalogs.ItemsBatches.EmptyRef());
		EndIf;
	EndIf;
	
	Query.SetParameter("PriceKind", ProductionServerCached.TypeOfPricePlannedCost_());
	
	If IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		Query.SetParameter("MethodOfAllocatingFinishedProductCosts", CostAllocationParameters.MethodOfAllocatingFinishedProductCosts);
	Else
		Query.SetParameter("MethodOfAllocatingFinishedProductCosts", RowData[CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts]);
	EndIf;
	
	Query.SetParameter("Date", ?(ValueIsFilled(
												CostAllocationParameters.ParametersForFillingInCostShares.Date), 
												CostAllocationParameters.ParametersForFillingInCostShares.Date, 
												CurrentSessionDate()));
	Query.SetParameter("Currency", ?(ValueIsFilled(
												CostAllocationParameters.ParametersForFillingInCostShares.Currency), 
												CostAllocationParameters.ParametersForFillingInCostShares.Currency, 
												ProductionServerCached.PlannedPriceCurrencyOfProductsMaterialsAndLabor()));
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	Selection.Next();
	SetPrivilegedMode(False);
	
	Result = ProductionClientServer.StructureOfShareValueFields();
	FillPropertyValues(Result, Selection);
	
	Return Result;
	
EndFunction

// Calculates the percentage of cost distribution for output items in the table part
//
// Parameters:
//  Object						 - FormDataStructure	 - main details of the directory form, document
//  CostAllocationParameters - Structure			 - structure of calculation parameters, See ProductionClientServer.CostAllocationParametersForOutputProducts
//  Groups			         - Array, Undefined	 -
//
Procedure CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters, Groups = Undefined) Export
	
	If Not CostAllocationParameters.CalculateShareCostPercentageField Then
		Return;
	EndIf;
	
	TabularSection = Object[CostAllocationParameters.TSName];
	
	If TabularSection.Count() = 0 Then
		Return;
	EndIf;
	
	ResultsByGrouping = TotalCostSharesByGrouping(TabularSection, CostAllocationParameters, Groups);
	
	For Each String In TabularSection Do
		
		Canceled = (CostAllocationParameters.ThereIsFieldCanceled And String.Canceled);
		
		If CostAllocationParameters.CostGroupingField <> "" Then
			Group = String[CostAllocationParameters.CostGroupingField];
		Else
			Group = "";
		EndIf;
		
		If CostAllocationParameters.CostGroupingField <> ""
			And Groups <> Undefined
			And Groups.Find(Group) = Undefined Then
			Continue;
		EndIf;
		
		Totals = ResultsByGrouping[Group];
		
		If Totals = Undefined Then
			String.CostSharePercentage = 0;
			String.CostShareRequired_ = False;
			String.ThereAreErrorsOfFillingInCostShare = False;
			Continue;
		EndIf;
		
		FieldName = ?(Totals.CostShareRequired_, "CostShare", "Count");
		
		If Not Canceled
			And Totals[FieldName] <> 0
			And (Not Totals.ParameterizationIsUsed
				Or Totals.ParameterizationIsUsed
					And Not Totals.ShareOfCostIsCalculated) Then
			String.CostSharePercentage = (String[FieldName] / Totals[FieldName]) * 100;
			If String.CostSharePercentage = 100 And String[FieldName] <> Totals[FieldName] Then
				String.CostSharePercentage = 99.99;
			EndIf;
		Else
			String.CostSharePercentage =
				?(Not Totals.CostShareRequired_ And Totals.NumberOfRowsInGrouping = 1 And Not Canceled, 100, 0);
		EndIf;
		
		If CostAllocationParameters.CalculateShareOfCostAttributeRequired Then
			String.CostShareRequired_ = Totals.CostShareRequired_ And Not Canceled;
		EndIf;
		
		If CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors Then
			FillInIfThereAreErrorsInFillingInCostFraction(String, Totals, Canceled, CostAllocationParameters);
		EndIf;
		
		If CostAllocationParameters.ThereIsParameterizationOfResourceSpecification Then
			String.ProductCostIsUnavailable = Totals.ParameterizationIsUsed And Totals.ShareOfCostIsCalculated;
		EndIf;
		
	EndDo;
	
EndProcedure

// The function prepares parameters for opening the cost share entry form and returns them.
//
// Parameters:
//  Object						 - FormDataStructure	 - main details of the directory form, document
//  CostAllocationParameters - Structure			 - structure of calculation parameters, See ProductionClientServer.CostAllocationParametersForOutputProducts
//	CurDataId	 - Number				 - ID of the current line in the document form;
//
// Returns:
//	Structure - parameters of the cost share entry form
//
Function ParametersOfCostShareEntryForm(Object, CostAllocationParameters, CurDataId) Export
	
	FormParameters = New Structure;
	
	TabularSection = Object[CostAllocationParameters.TSName];
	RowData = TabularSection.FindByID(CurDataId);
	
	ItemData_3 = New Structure("
		|Products,
		|Characteristic,
		|
		|Package,
		|NumberOfPackages,
		|Count,
		|
		|CostShare,
		|CostSharePerUnit
		|");
		
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		ItemData_3.Insert("Series");
	EndIf;
	
	FillPropertyValues(ItemData_3, RowData);
	FormParameters.Insert("ItemData_3", ItemData_3);
	
	Groups = New Array;
	If CostAllocationParameters.CostGroupingField <> "" Then
		Group = RowData[CostAllocationParameters.CostGroupingField];
		FormParameters.Insert("GroupCosts", RowData[CostAllocationParameters.CostGroupingPresentationField]);
	Else
		Group = "";
		FormParameters.Insert("GroupCosts", "");
	EndIf;
	Groups.Add(Group);
	
	ResultsByGrouping = TotalCostSharesByGrouping(TabularSection, CostAllocationParameters, Groups);
	Totals = ResultsByGrouping[Group];
	
	If CostAllocationParameters.CalculateShareCostPercentageField Then
		FormParameters.Insert("CostSharePercentage", RowData.CostSharePercentage);
		FormParameters.Insert("ShareOfCostTotal", Totals.CostShare);
	Else
		FormParameters.Insert("CostSharePercentage", ?(Totals.CostShare <> 0, (RowData.CostShare/Totals.CostShare) * 100, 0));
		FormParameters.Insert("ShareOfCostTotal", Totals.CostShare);
	EndIf;
	
	FormParameters.Insert("ParameterizationIsUsed", Totals.ParameterizationIsUsed);
	
	If IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		FormParameters.Insert("MethodOfAllocatingFinishedProductCosts", CostAllocationParameters.MethodOfAllocatingFinishedProductCosts);
	Else
		FormParameters.Insert("MethodOfAllocatingFinishedProductCosts", RowData[CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts]);
	EndIf;
	
	FormParameters.Insert("ReadOnly", CostAllocationParameters.ReadOnly);

	FormParameters.Insert("ParametersForFillingInCostShares", CostAllocationParameters.ParametersForFillingInCostShares);
	
	Return FormParameters;
	
EndFunction

// Sets the conditional design for the "cost Share" field"
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  PathToElements   - String - paths to form elements.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure SetConditionalAppearanceOfShareOfCostField(Form, ObjectName, TSName, PathToElements = "", DataPaths = Undefined) Export
	
	PathToFormElements = ?(PathToElements <> "", PathToElements, TSName);
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	// View only
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[PathToFormElements + "CostShare"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = PathDataLayoutField(ObjectName, DataPaths, "MethodOfAllocatingFinishedProductCosts");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Mark blank
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[PathToFormElements + "CostShare"]["Name"]);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostShareRequired_");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// display (for canceled rows)
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[PathToFormElements + "CostShare"]["Name"]);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
EndProcedure

// Sets the extended conditional design for the fields of the "cost Share" group %"
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  PathToElements   - String - paths to form elements.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure SetConditionalAppearanceOfShareCostPercentageField(Form, ObjectName, TSName, PathToElements = "", DataPaths = Undefined) Export
	
	PathToFormElements = ?(PathToElements <> "", PathToElements, TSName);
	
	ElementNames = NamesOfCostShareElements(PathToFormElements);
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	// cost share (visibility)
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.CostShare]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = PathDataLayoutField(ObjectName, DataPaths, "MethodOfAllocatingFinishedProductCosts");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// share of the cost (mark blank)
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.CostShare]["Name"]);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostShareRequired_");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// share of cost, % (visibility)
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.CostSharePercentage]["Name"]);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.CostSharePercentage]["Name"]);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// cost share, indicator (visibility)
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.ThereAreErrorsOfFillingInCostShare]["Name"]);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.ThereAreErrorsOfFillingInCostShare]["Name"]);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.ThereAreErrorsOfFillingInCostShare]["Name"]);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;     
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".ThereAreErrorsOfFillingInCostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);     
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.ThereAreErrorsOfFillingInCostShare]["Name"]);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;     
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".ThereAreErrorsOfFillingInCostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	// share of cost, % less than 0.01 (Presentation)
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[ElementNames.CostSharePercentage]["Name"]);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".ThereAreErrorsOfFillingInCostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<0,01%';
													|ru = '<0,01%';
													|en = '<0,01%'; fa = '<0,01%';
													|it = '<0,01%';
													|pl = '<0,01%';
													|tr = '<0,01%'"));
	Item.Appearance.SetParameterValue("Visible", True);
	
EndProcedure

// Sets the Conditional appearance of the "Cost share" group fields for canceled rows
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  PathToElements   - String - paths to form elements.
//
Procedure SetConditionalAppearanceOfShareOfCostOfCanceledRowsField(Form, ObjectName, TSName, PathToElements = "") Export
	
	PathToFormElements = ?(PathToElements <> "", PathToElements, TSName);
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	// cost share (display for canceled lines)
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[PathToFormElements + "CostShare"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// share of cost, % less than 0.01 (Presentation)
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(FormItems[PathToFormElements + "CostSharePercentage"]["Name"]);
 
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", "");
	
EndProcedure

// The procedure prepares parameters for opening the cost share entry form and returns them.
//
// Parameters:
//  Object	 - DocumentObject, CatalogObject	 - object whose string needs to be checked
//  String	 - Structure	 - the line where the cost share is checked
//
// Returns:
//	Boolean - indication of the need to fill in the cost share in the line
//
Function ItIsRequiredToFillInFractionOfCost(Object, String) Export
	
	If Object.MethodOfAllocatingFinishedProductCosts =
			Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares Then
		
		Totals = Object.ManufacturedProduct.Unload(
			New Structure("Canceled", False),
			"Products, Characteristic, CostShare");
		
		Totals.GroupBy("Products, Characteristic", "CostShare");
		
		TotalShare = 0;
		For Each CurShare In Totals Do
			TotalShare = TotalShare + CurShare.CostShare
		EndDo;
		
		If String.CostShare = 0
			And (Totals.Count() > 1
			Or Not TotalShare = 0) Then
			Return True;
		Else
			Return False;
		EndIf;
		
	Else
		Return String.CostShare = 0;
	EndIf;
	
EndFunction

// Adds a request to get the data needed to fill in the cost fractions.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CompleteQueryTextCheckFillInCostFractionInBatches(StructureOfActions, QueryDetails, CachedValues) Export
	
	CostAllocationParameters = Undefined;
	
	If Not BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"CheckFillInCostShare",
		StructureOfActions,
		CachedValues,
		CostAllocationParameters) Then
	
		Return;
	EndIf;
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	// Lines To Calculate
	QueryText = "";
	If UsePriceManagementSystem25 Then
		QueryText =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.LineNumber           AS LineNumber,
		|	Table.Products          AS Products,
		|	Table.Characteristic        AS Characteristic,
		|	&TextOfPackagingUnitField            AS Package,
		|	&FieldTextNumberOfPackagingUnits  AS NumberOfPackages,
		|	Table.Count            AS Count,
		|	&MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
		|	0                             AS CostShare,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE Table.Characteristic.ItemsCharacteristicForPricing
		|	END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
		|		ELSE &BatchForPricing
		|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE &TextOfPackagingUnitField
		|	END AS PricingPackage
		|INTO TTLinesForCalculationOfCostShares
		|FROM
		|	TTDataSource AS Table
		|
		|	LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|	ON ItemKinds.Ref = Table.Products.ProductKind";
		
		ThereIsSeries = BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Series", CachedValues);
		If ThereIsSeries Then
			QueryText = StrReplace(QueryText,
				"&BatchForPricing",
				"Table.Series.ItemsBatchForPricing");
		Else
			QueryText = StrReplace(QueryText,
				"&BatchForPricing",
				"VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)");
		EndIf;
	Else
		QueryText =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.LineNumber           AS LineNumber,
		|	Table.Products          AS Products,
		|	Table.Characteristic        AS Characteristic,
		|	&TextOfPackagingUnitField            AS Package,
		|	&FieldTextNumberOfPackagingUnits  AS NumberOfPackages,
		|	Table.Count            AS Count,
		|	&MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
		|	0                             AS CostShare
		|INTO TTLinesForCalculationOfCostShares
		|FROM
		|	TTDataSource AS Table";
	EndIf;
	
	If Not IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		QueryText = StrReplace(QueryText,
			"&MethodOfAllocatingFinishedProductCosts",
			"Table." + CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts);
	EndIf;
	
	ThereArePackages = BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Package", CachedValues);
	If ThereArePackages Then
		QueryText = StrReplace(QueryText,
			"&TextOfPackagingUnitField",
			"Table.Package");
		QueryText = StrReplace(QueryText,
			"&FieldTextNumberOfPackagingUnits",
			"Table.NumberOfPackages");
	Else
		QueryText = StrReplace(QueryText,
			"&TextOfPackagingUnitField",
			"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		QueryText = StrReplace(QueryText,
			"&FieldTextNumberOfPackagingUnits",
			"Table.Count");
	EndIf;
	
	QueryDetails.QueriesTexts.Add(QueryText, "TTLinesForCalculationOfCostShares");
	TableName = "TTLinesForCalculationOfCostShares";
	
	// Automatic calculation of characteristics
	If CostAllocationParameters.AutoCalculationOfAnyCharacteristic
		And CostAllocationParameters.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByTargetCost Then
		
		If UsePriceManagementSystem25 Then
			
			QueryText =
			"SELECT
			|	ItemsPrices.Products AS Products,
			|	MAX(ItemsPrices.PricingVariant) AS PricingVariant
			|INTO TTAutoSelectionCharacteristicsOfCostShare
			|FROM
			|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY)
			|			,
			|			PriceKind = &PriceKind
			|				AND Products IN
			|					(SELECT
			|						Filter.Products
			|					FROM
			|						TTLinesForCalculationOfCostShares AS Filter)) AS ItemsPrices
			|
			|GROUP BY
			|	ItemsPrices.Products";
			
			QueryDetails.QueriesTexts.Add(QueryText, "TTAutoSelectionCharacteristicsOfCostShare");
			
			QueryText =
			"SELECT
			|	TabularSection.IdOfTTRow AS IdOfTTRow,
			|	TabularSection.LineNumber           AS LineNumber,
			|
			|	TabularSection.Products       AS Products,
			|	TabularSection.Characteristic     AS Characteristic,
			|	CASE
			|		WHEN TabularSection.Products.UseVariants IN (
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
			|			) THEN
			|			ISNULL(AutoFeedingFeatures.PricingVariant, TabularSection.PricingVariant)
			|		ELSE
			|			VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
			|	END                             AS PricingVariant,
			|	TabularSection.PricingBatch           AS PricingBatch,
			|	TabularSection.PricingPackage         AS PricingPackage,
			|
			|	TabularSection.Package           AS Package,
			|	TabularSection.NumberOfPackages AS NumberOfPackages,
			|	TabularSection.Count         AS Count,
			|
			|	TabularSection.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
			|
			|	TabularSection.CostShare AS CostShare
			|
			|INTO TTLinesForCalculatingCostSharesWithAutoCharacteristics
			|FROM
			|	TTLinesForCalculationOfCostShares AS TabularSection
			|
			|		LEFT JOIN TTAutoSelectionCharacteristicsOfCostShare AS AutoFeedingFeatures
			|		ON TabularSection.Products = AutoFeedingFeatures.Products
			|			AND (TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))";
			
			QueryDetails.QueriesTexts.Add(QueryText, "TTLinesForCalculatingCostSharesWithAutoCharacteristics");
			
		Else
			
			QueryText =
			"SELECT
			|	ItemsPrices.Products AS Products,
			|	MAX(ItemsPrices.Characteristic) AS Characteristic
			|INTO TTAutoSelectionCharacteristicsOfCostShare
			|FROM
			|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&Date, DAY)
			|			,
			|			PriceKind = &PriceKind
			|				AND Products IN
			|					(SELECT
			|						Filter.Products
			|					FROM
			|						TTLinesForCalculationOfCostShares AS Filter)) AS ItemsPrices
			|
			|GROUP BY
			|	ItemsPrices.Products";
			
			QueryDetails.QueriesTexts.Add(QueryText, "TTAutoSelectionCharacteristicsOfCostShare");
			
			QueryText =
			"SELECT
			|	TabularSection.IdOfTTRow AS IdOfTTRow,
			|	TabularSection.LineNumber           AS LineNumber,
			|
			|	TabularSection.Products       AS Products,
			|	CASE
			|		WHEN TabularSection.Products.UseVariants IN (
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
			|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
			|			) THEN
			|			ISNULL(AutoFeedingFeatures.Characteristic, TabularSection.Characteristic)
			|		ELSE
			|			VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|	END                             AS Characteristic,
			|
			|	TabularSection.Package           AS Package,
			|	TabularSection.NumberOfPackages AS NumberOfPackages,
			|	TabularSection.Count         AS Count,
			|
			|	TabularSection.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
			|
			|	TabularSection.CostShare AS CostShare
			|
			|INTO TTLinesForCalculatingCostSharesWithAutoCharacteristics
			|FROM
			|	TTLinesForCalculationOfCostShares AS TabularSection
			|
			|		LEFT JOIN TTAutoSelectionCharacteristicsOfCostShare AS AutoFeedingFeatures
			|		ON TabularSection.Products = AutoFeedingFeatures.Products
			|			AND (TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))";
			
			QueryDetails.QueriesTexts.Add(QueryText, "TTLinesForCalculatingCostSharesWithAutoCharacteristics");
			
		EndIf;
		
		TableName = "TTLinesForCalculatingCostSharesWithAutoCharacteristics";
		
	EndIf;
	
	// Calculation Of COST Shares
	If UsePriceManagementSystem25 Then
		QueryTextFilterRemainingGoodsByShelfLives =
		"(Products, PricingVariant, PricingBatch, PricingPackage) IN (
		|	SELECT
		|		T.Products,
		|		T.PricingVariant,
		|		T.PricingBatch,
		|		T.PricingPackage
		|	FROM
		|		&TableName AS T)";
	Else
		QueryTextFilterRemainingGoodsByShelfLives =
		"(Products, Characteristic) IN (
		|	SELECT
		|		T.Products,
		|		T.Characteristic
		|	FROM
		|		&TableName AS T)";
	EndIf;
	QueryTextFilterRemainingGoodsByShelfLives = StrReplace(QueryTextFilterRemainingGoodsByShelfLives, "&TableName", TableName);
	
	SubstitutionParameters = SubstitutionParametersOfCostFractionCalculationAlgorithm(
		"TabularSection",
		"TabularSection.MethodOfAllocatingFinishedProductCosts",
		QueryTextFilterRemainingGoodsByShelfLives,
		UsePriceManagementSystem25);
	
	QueryText =
	"SELECT
	|	TabularSection.IdOfTTRow AS IdOfTTRow,
	|	&CostShare AS CostShare,
	|	&CostSharePerUnit AS CostSharePerUnit
	|FROM
	|	&TableName AS TabularSection
	|	,CompoundShareCost";
	QueryText = StrReplace(QueryText, "&TableName", TableName);
	
	PerformSubstitutionOfCostFractionCalculationAlgorithm(QueryText, SubstitutionParameters, UsePriceManagementSystem25);
	
	QueryDetails.QueriesTexts.Add(QueryText, "CostShares");
	
	// Query Parameters
	QueryDetails.QueryOptions.Insert("PriceKind", ProductionServerCached.TypeOfPricePlannedCost_());
	QueryDetails.QueryOptions.Insert("Date", ?(ValueIsFilled(
												CostAllocationParameters.ParametersForFillingInCostShares.Date), 
												CostAllocationParameters.ParametersForFillingInCostShares.Date, 
												CurrentSessionDate()));
	QueryDetails.QueryOptions.Insert("Currency", ?(ValueIsFilled(
												CostAllocationParameters.ParametersForFillingInCostShares.Currency), 
												CostAllocationParameters.ParametersForFillingInCostShares.Currency, 
												ProductionServerCached.PlannedPriceCurrencyOfProductsMaterialsAndLabor()));
	QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	If IsBlankString(CostAllocationParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		QueryDetails.QueryOptions.Insert("MethodOfAllocatingFinishedProductCosts", CostAllocationParameters.MethodOfAllocatingFinishedProductCosts);
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkSchedules

// Creates a temporary table with the schedule of work of divisions.
// Table columns: Link, work Schedule.
//
// Parameters:
//  References					 - Array, CatalogRef.BusinessStructure - links to divisions.
//  TempTablesManager  - TempTablesManager - the Manager where the temporary table will be created.
//  TTName					 - String - name of the temporary table to create.
//
Procedure CreateTTDivisionSchedules(References, TempTablesManager, TTName = "TTWorkSchedules_") Export
	
	QueryText = 
		"SELECT
		|	BusinessStructure.Ref AS Ref,
		|	ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value) AS WorkScheduleCalendar
		|INTO TTName
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|
		|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|		ON BusinessStructure.Ref = Schedules.Ref
		|
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON (TRUE)		
		|WHERE
		|	BusinessStructure.Ref IN(&References)";
	
	QueryText = StrReplace(QueryText, "TTName", TTName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("References",
		?(TypeOf(References) = Type("Array"), References, CommonClientServer.ValueInArray(References)));
	Query.Execute();
	
EndProcedure

// Returns the work schedules of divisions.
//
// Parameters:
//  References - Array, CatalogRef.BusinessStructure - links to divisions.
// 
// Returns:
//  ValueTable - table with columns:
//		* Ref - CatalogRef.BusinessStructure - unit.
//		* WorkScheduleCalendar - CatalogRef.Calendars - work schedule.
//
Function DivisionWorkSchedules(References) Export
	
	TempTablesManager = New TempTablesManager;
	
	CreateTTDivisionSchedules(References, TempTablesManager, "TTWorkSchedules_");
		
	Query = New Query(
		"SELECT
		|	TTWorkSchedules_.Ref       AS Ref,
		|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleCalendar
		|FROM
		|	TTWorkSchedules_ AS TTWorkSchedules_");
	
	Query.TempTablesManager = TempTablesManager;
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the Query Text for counting the specified number of days according to calendar schedules.
//
// Parameters:
//  SearchForward - Boolean - if true, then search forward, otherwise search backward.
//	AddSeparator - Boolean - add a separator to the end of the Query Text.
//
// Returns:
//	String - the text of the request for dates according to the company's work calendar.
//
Function QueryTextForDatesByCalendar(SearchForward = True, AddSeparator = True) Export
	
	If SearchForward Then
		
		QueryText =
			"SELECT
			|	T.Calendar   AS Calendar,
			|	T.NumberOfDays   AS NumberOfDays,
			|	T.StartingDate AS StartingDate,
			|	ISNULL(DeliveryInCurYear.ScheduleDate, DeliveryNextYear.ScheduleDate) AS Date
			|INTO TTScheduleDates
			|FROM
			|	TTSearchParameters AS T //Template
			|		LEFT JOIN InformationRegister.CalendarSchedules AS CurrentDate
			|		ON T.Calendar = CurrentDate.Calendar
			|		 AND CurrentDate.Year         = YEAR(T.StartingDate)
			|		 AND CurrentDate.ScheduleDate = T.StartingDate
			|
			|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryInCurYear
			|		ON T.Calendar = DeliveryInCurYear.Calendar
			|		 AND DeliveryInCurYear.DayAddedToSchedule
			|		 AND DeliveryInCurYear.Year = YEAR(T.StartingDate)
			|		 AND DeliveryInCurYear.DaysCountInScheduleSinceBegOfYear
			|			= CurrentDate.DaysCountInScheduleSinceBegOfYear
			|			+ T.NumberOfDays
			|			+ CASE
			|				WHEN CurrentDate.DayAddedToSchedule THEN
			|					0
			|				ELSE
			|					1
			|			END
			|
			|		LEFT JOIN InformationRegister.CalendarSchedules AS LastDateOfYear
			|		ON DeliveryInCurYear.ScheduleDate IS NULL
			|		 AND T.Calendar = LastDateOfYear.Calendar
			|		 AND LastDateOfYear.Year = YEAR(T.StartingDate)
			|		 AND LastDateOfYear.ScheduleDate = BEGINOFPERIOD(ENDOFPERIOD(T.StartingDate, Year), DAY)
			|
			|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryNextYear
			|		ON DeliveryInCurYear.ScheduleDate IS NULL
			|		 AND T.Calendar = DeliveryNextYear.Calendar
			|		 AND DeliveryNextYear.DayAddedToSchedule
			|		 AND DeliveryNextYear.Year = YEAR(T.StartingDate) + 1
			|		 AND DeliveryNextYear.DaysCountInScheduleSinceBegOfYear
			|			= T.NumberOfDays
			|			- (LastDateOfYear.DaysCountInScheduleSinceBegOfYear
			|				- CurrentDate.DaysCountInScheduleSinceBegOfYear)
			|			+ CASE
			|				WHEN CurrentDate.DayAddedToSchedule THEN
			|					0
			|				ELSE
			|					1
			|			END
			|
			|WHERE
			|	NOT ISNULL(DeliveryInCurYear.ScheduleDate, DeliveryNextYear.ScheduleDate) IS NULL
			|INDEX BY
			|	Calendar, NumberOfDays, StartingDate";
			
	Else
			
		QueryText =
			"SELECT
			|	T.NumberOfDays   AS NumberOfDays,
			|	T.StartingDate AS StartingDate,
			|	ISNULL(DeliveryInCurYear.ScheduleDate, DeliveryInPreviousYear.ScheduleDate) AS Date
			|INTO TTScheduleDates
			|FROM
			|	TTSearchParameters AS T //Template
			|		LEFT JOIN InformationRegister.CalendarSchedules AS CurrentDate
			|		ON T.Calendar = CurrentDate.Calendar
			|		 AND CurrentDate.Year         = YEAR(T.StartingDate)
			|		 AND CurrentDate.ScheduleDate = T.StartingDate
			|
			|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryInCurYear
			|		ON T.Calendar = DeliveryInCurYear.Calendar
			|		 AND DeliveryInCurYear.DayAddedToSchedule
			|		 AND DeliveryInCurYear.Year = YEAR(T.StartingDate)
			|		 AND DeliveryInCurYear.DaysCountInScheduleSinceBegOfYear
			|			= CurrentDate.DaysCountInScheduleSinceBegOfYear
			|			- T.NumberOfDays
			|			+ CASE
			|				WHEN CurrentDate.DayAddedToSchedule THEN
			|					0
			|				ELSE
			|					1
			|			END
			|
			|		LEFT JOIN InformationRegister.CalendarSchedules AS LastDateOfYear
			|		ON DeliveryInCurYear.ScheduleDate IS NULL
			|		 AND T.Calendar = LastDateOfYear.Calendar
			|		 AND LastDateOfYear.Year = YEAR(T.StartingDate) - 1
			|		 AND LastDateOfYear.ScheduleDate = BEGINOFPERIOD(DATEADD(BEGINOFPERIOD(T.StartingDate, Year), SECOND, -1), DAY)
			|
			|		LEFT JOIN InformationRegister.CalendarSchedules AS DeliveryInPreviousYear
			|		ON DeliveryInCurYear.ScheduleDate IS NULL
			|		 AND T.Calendar = DeliveryInPreviousYear.Calendar
			|		 AND DeliveryInPreviousYear.DayAddedToSchedule
			|		 AND DeliveryInPreviousYear.Year = YEAR(T.StartingDate) - 1
			|		 AND DeliveryInPreviousYear.DaysCountInScheduleSinceBegOfYear
			|			= LastDateOfYear.DaysCountInScheduleSinceBegOfYear
			|				- (T.NumberOfDays - CurrentDate.DaysCountInScheduleSinceBegOfYear)
			|				+ CASE
			|					WHEN CurrentDate.DayAddedToSchedule THEN
			|						0
			|					ELSE
			|						1
			|				END
			|
			|WHERE
			|	NOT ISNULL(DeliveryInCurYear.ScheduleDate, DeliveryInPreviousYear.ScheduleDate) IS NULL
			|INDEX BY
			|	NumberOfDays, StartingDate";
			
	EndIf;
	
	If AddSeparator Then
		QueryText = QueryText + "
			|;
			|
			|////////////////////////////////////////////////////////////
			|";
	EndIf;
	
	Return QueryText;
	
EndFunction

// Creates a temporary table with the schedule of work of the types of RTS.
// Table columns: Link, work Schedule.
//
// Parameters:
//  References					 - Array, CatalogRef.WorkCenterTypes - links to types of RC.
//  TempTablesManager  - TempTablesManager - the Manager where the temporary table will be created.
//  TTName					 - String - name of the temporary table to create.
//
Procedure CreateTTSchedulesForRCTypes(References, TempTablesManager, TTName = "TTWorkSchedules_") Export
	
	QueryText = 
		"SELECT
		|	WorkCenterTypes.Ref AS Ref,
		|	CASE
		|		WHEN WorkCenterTypes.Calendar <> VALUE(Catalog.Calendars.EmptyRef)
		|			THEN WorkCenterTypes.Calendar
		|		ELSE ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value)
		|	END AS WorkScheduleCalendar
		|INTO TTName
		|FROM
		|	Catalog.WorkCenterTypes AS WorkCenterTypes
		|
		|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|		ON WorkCenterTypes.Department = Schedules.Ref
		|			AND WorkCenterTypes.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON (TRUE)
		|WHERE
		|	WorkCenterTypes.Ref IN(&References)";
	
	QueryText = StrReplace(QueryText, "TTName", TTName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("References",
		?(TypeOf(References) = Type("Array"), References, CommonClientServer.ValueInArray(References)));
		
	Query.Execute();
	
EndProcedure

// Returns work schedules and types of RTS.
//
// Parameters:
//  References - Array, CatalogRef.WorkCenterTypes - links to types of RC.
// 
// Returns:
//  ValueTable - table with columns:
//		* Ref - CatalogRef.WorkCenterTypes - type of RC.
//		* WorkScheduleCalendar - CatalogRef.Calendars - work schedule.
//
Function WorkSchedulesOfRCTypes(References) Export
	
	TempTablesManager = New TempTablesManager;
	
	CreateTTSchedulesForRCTypes(References, TempTablesManager, "TTWorkSchedules_");
		
	Query = New Query(
		"SELECT
		|	TTWorkSchedules_.Ref       AS Ref,
		|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleCalendar
		|FROM
		|	TTWorkSchedules_ AS TTWorkSchedules_");
	
	Query.TempTablesManager = TempTablesManager;
	
	Return Query.Execute().Unload();
	
EndFunction

// Creates a temporary table with work center schedules.
// Table columns: Link, work Schedule.
//
// Parameters:
//  References - Array, CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes - links to work centers
//		or the types of RC (see the OtborPoRC parameter) . In the latter case, all RC belonging to these types of RC will be received.
//  TempTablesManager - TempTablesManager - the Manager where the temporary table will be created.
//	SelectionByRC - Boolean - True: the first parameter contains links to work centers;
//		False: the first parameter contains links to types of work centers.
//  TTName  - String - name of the temporary table to create.
//
Procedure CreateTTRTSSchedules(References, TempTablesManager, SelectionByRC = True, TTName = "TTWorkSchedules_") Export
	
	QueryText = 
		"SELECT
		|	WorkCenters.Ref AS Ref,
		|	CASE
		|		WHEN WorkCenters.Calendar <> VALUE(Catalog.Calendars.EmptyRef)
		|			THEN WorkCenters.Calendar
		|		WHEN WorkCenterTypes.Calendar <> VALUE(Catalog.Calendars.EmptyRef)
		|			THEN WorkCenterTypes.Calendar
		|		ELSE ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value)
		|	END AS WorkScheduleCalendar
		|INTO TTName
		|FROM
		|	Catalog.WorkCenters AS WorkCenters
		|		LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
		|		ON WorkCenters.WorkCenterType = WorkCenterTypes.Ref
		|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|		ON (WorkCenterTypes.Department = Schedules.Ref)
		|			AND (WorkCenters.Calendar = VALUE(Catalog.Calendars.EmptyRef))
		|			AND (WorkCenterTypes.Calendar = VALUE(Catalog.Calendars.EmptyRef))
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON (TRUE)
		|WHERE
		|	(&SelectionByRC
		|				AND WorkCenters.Ref IN (&References)
		|			OR NOT &SelectionByRC
		|				AND WorkCenters.WorkCenterType IN (&References))";
	QueryText = StrReplace(QueryText, "TTName", TTName);
	
	ReferencesArrray = ?(TypeOf(References) = Type("Array"),
		References,
		CommonClientServer.ValueInArray(References));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("References", ReferencesArrray);
	Query.SetParameter("SelectionByRC", SelectionByRC);
	Query.Execute();
	
EndProcedure

// Returns work center schedules.
//
// Parameters:
//  References - Array, CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes - links to work centers
//		or the types of RC (see the OtborPoRC parameter) . In the latter case, all RC belonging to these types of RC will be received.
//	SelectionByRC - Boolean - True: the first parameter contains links to work centers;
//		False: the first parameter contains links to types of work centers.
// 
// Returns:
//  ValueTable - table with columns:
//		* Ref - CatalogRef.WorkCenters - work center.
//		* WorkScheduleCalendar - CatalogRef.Calendars - work schedule.
//
Function WorkCenterSchedules(References, SelectionByRC = True) Export
	
	TempTablesManager = New TempTablesManager;
	
	CreateTTRTSSchedules(References, TempTablesManager, SelectionByRC, "TTWorkSchedules_");
		
	Query = New Query(
		"SELECT
		|	TTWorkSchedules_.Ref       AS Ref,
		|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleCalendar
		|FROM
		|	TTWorkSchedules_ AS TTWorkSchedules_");
	
	Query.TempTablesManager = TempTablesManager;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region TypesOfProductionProcess

// Restrict the list of production process types
//
// Parameters:
//  Item					 - FormField - the form element where you want to set the restriction.
//  TypesToExclude			 - Array	 - array of production process types that should not be displayed.
//  DynamicStructure	 - Boolean	 - option value (contextual)
//
Procedure FillInListOfProductionProcessTypes(Item, TypesToExclude = Undefined, DynamicStructure = Undefined) Export
	
	TypesArray = Enums.ProductionProcessTypes.AvailableTypes(DynamicStructure);
	
	ChoiceList = Item.ChoiceList;
	ChoiceList.Clear();
	
	For Each ProcessType In TypesArray Do
		
		If Not TypesToExclude = Undefined
			And Not TypesToExclude.Find(ProcessType) = Undefined Then
			Continue;
		EndIf;
		
		ChoiceList.Add(ProcessType);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Rounding

// Returns a condition for selecting rounding rows
//
//	Parameters:
//		TSName		 - String - name of the table part
//		WarehouseFieldName - String - the name of the warehouse detail, by default " Warehouse"
//
//	Returns:
//		String - row selection condition
//			
Function ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName = "Warehouse") Export
	
	Result = StrTemplate(
		"NOT ISNULL(CAST(%1.%2 AS Catalog.Warehouses).ShopFloorStockroom, FALSE)", TSName, WarehouseFieldName);
		
	Return Result;	
	
EndFunction	

#EndRegion

#Region FillType

// Fills in the service details in the line based on the selected warehouse
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  Parameters			 - Structure - auxiliary parameters to fill in.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInShopPantryAttribute(CurrentRow, Parameters, CachedValues) Export
	
	WarehouseFieldName = "Warehouse";
	WarehouseValue_ = Undefined;
	FillInTheDepartment = False;
	
	If Parameters <> Undefined Then
		
		If Parameters.Property("WarehouseFieldName") Then
			WarehouseFieldName = Parameters.WarehouseFieldName;	
		EndIf;
			
		If Parameters.Property("FillInTheDepartment") Then
			FillInTheDepartment = Parameters.FillInTheDepartment;	
		EndIf;		
		
		Parameters.Property("WarehouseValue_", WarehouseValue_);
		
	EndIf;	
	
	If WarehouseValue_ = Undefined Then
		WarehouseValue_ = CurrentRow[WarehouseFieldName];
	EndIf;
	
	If ValueIsFilled(WarehouseValue_) And TypeOf(WarehouseValue_) = Type("CatalogRef.Warehouses") Then
		
		WarehouseProperties = CachedValues.WarehouseProperties_.Get(WarehouseValue_);
		
		If WarehouseProperties = Undefined Then
			
			WarehouseProperties_ = Catalogs.Warehouses.WarehouseProperties_(WarehouseValue_);
			WarehouseProperties = WarehouseProperties_.Get(WarehouseValue_);
			
			CachedValues.WarehouseProperties_.Insert(WarehouseValue_, WarehouseProperties);
			
		EndIf;	
		
		ShopFloorStockroom = WarehouseProperties.ShopFloorStockroom;
		Department = WarehouseProperties.Department;
		
	Else
		
		ShopFloorStockroom = False;
		Department = Undefined;
		
	EndIf;
	
	CurrentRow.ShopFloorStockroom = ShopFloorStockroom;
	
	If FillInTheDepartment And CurrentRow.ShopFloorStockroom Then
		CurrentRow.Department = Department;
	EndIf;
	
	If CurrentRow.Property("MustBeRoundOff") Then
		CurrentRow.MustBeRoundOff = Not CurrentRow.ShopFloorStockroom;	
	EndIf;	
	
EndProcedure

// Fills in the Shopbill and need to Round attributes in the table rows
// 
// Parameters:
//  FormTable   - FormDataCollection                  - table being processed
//  FieldName        - String                                - the name of the warehouse detail, by default " Warehouse"
//  WarehouseValue_ - CatalogRef.Warehouses, Undefined -
//  Rows         - Array, Undefined                  - array of processed strings
//
Procedure FillInShopPantryAttributeInTable(
			FormTable, FieldName = "Warehouse", WarehouseValue_ = Undefined, Rows = Undefined) Export
	
	If FormTable.Count() = 0 Then
		Return;
	EndIf;
		
	QueryText =
	"SELECT
	|	CAST(Table.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(&Warehouse AS Catalog.Warehouses) AS Warehouse
	|INTO Table
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.Warehouse.ShopFloorStockroom AS ShopFloorStockroom,
	|	NOT ISNULL(Table.Warehouse.ShopFloorStockroom, FALSE) AS MustBeRoundOff
	|FROM
	|	Table AS Table";
	
	If WarehouseValue_ = Undefined Then
		QueryText = StrReplace(QueryText, "&Warehouse", StrTemplate("Table.%1", FieldName));
		TableFields  = StrTemplate("LineNumber, %1", FieldName);
	Else
		TableFields  = "LineNumber";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Table", FormTable.Unload(Rows, TableFields));
	Query.SetParameter("Warehouse",   WarehouseValue_);
		
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		FillPropertyValues(FormTable[Selection.LineNumber-1], Selection,, "LineNumber");
	EndDo;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the recipient.
//
// Parameters:
//  StructureOfActions - Structure
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CompleteQueryTextRecipientInDirectionOfIssue(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillOutRecipientInDirectionOfIssue",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
	
		If GetFunctionalOption("UseSeveralWarehouses") Then
			
			QueryText = 
			"SELECT
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	CASE
			|		WHEN COUNT(CatWarehouses.Ref) = 1
			|			THEN MAX(CatWarehouses.Ref)
			|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
			|	END AS ShopFloorStockroom
			|FROM
			|	TTDataSource AS DataSource
			|
			|	LEFT JOIN Catalog.Warehouses AS CatWarehouses
			|	ON NOT CatWarehouses.DeletionMark
			|	AND NOT CatWarehouses.IsFolder
			|	AND CatWarehouses.Department = &Department
			|	AND CatWarehouses.ShopFloorStockroom
			|
			|GROUP BY
			|	DataSource.IdOfTTRow
			|";
			
			QueryDetails.QueryOptions.Insert("Department", ActionParameters.Department);
			
		Else
			
			QueryText = 
			"SELECT
			|	DataSource.IdOfTTRow AS IdOfTTRow,
			|	CASE
			|		WHEN COUNT(CatWarehouses.Ref) = 1
			|			THEN MAX(CatWarehouses.Ref)
			|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
			|	END AS ShopFloorStockroom
			|FROM
			|	TTDataSource AS DataSource
			|
			|	LEFT JOIN Catalog.Warehouses AS CatWarehouses
			|	ON NOT CatWarehouses.DeletionMark
			|	AND NOT CatWarehouses.IsFolder
			|	AND CatWarehouses.ShopFloorStockroom
			|
			|GROUP BY
			|	DataSource.IdOfTTRow
			|";
			
		EndIf;
		
		QueryDetails.QueriesTexts.Add(QueryText, "RecipientInDirectionOfIssue");
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the shop pantry attribute.
//
// Parameters:
//  StructureOfActions - Structure
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure AddShopFloorStockroomAttributeToQueryText(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInShopPantryAttribute",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
	
		WarehouseFieldName = "DataSource.Warehouse";
		If ActionParameters <> Undefined
			And ActionParameters.Property("WarehouseFieldName") Then
				WarehouseFieldName = "DataSource." + ActionParameters.WarehouseFieldName;
		ElsIf ActionParameters <> Undefined
			And ActionParameters.Property("WarehouseValue_") Then
				WarehouseFieldName = "&WarehouseValue_";
				QueryDetails.QueryOptions.Insert("WarehouseValue_", ActionParameters.WarehouseValue_);
		EndIf;
		
		QueryText = 
		"SELECT
		|	DataSource.IdOfTTRow            AS IdOfTTRow,
		|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE)       AS ShopFloorStockroom,
		|	ISNULL(CatWarehouses.Department, UNDEFINED) AS Department
		|FROM
		|	TTDataSource AS DataSource
		|
		|	LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|	ON CatWarehouses.Ref = &WarehouseFieldName
		|";
		
		QueryText = StrReplace(QueryText, "&WarehouseFieldName", WarehouseFieldName);
		QueryDetails.QueriesTexts.Add(QueryText, "ShopFloorStockroomAttribute");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region UnitGoodsInUnitOfMeasure

// Returns the request text for the "Packaging" and "quantity of Packaging" fields to replace with a storage unit 
// in the case of a piece item, which is counted in the measurement unit
// 
// Parameters:
//	TableName - String - name of the table to replace the "Packaging" and "quantity of Packages" fields for"
//
// Returns:
//  Structure - contains query texts:
//  	* Package                             - String - text for getting the "Packaging" field.
//  	* NumberOfPackages                   - String - text for getting the "quantity of Packages" field.
//  	* CompoundUnitGoodsInUnitOfMeasure - String - connection text.
//  	* UnitGoodsInUnitsOfMeasure          - String - attribute of a piece product in dimensional units
//
Function RequestTextForCustomizingUnitProductInUnitOfMeasure(TableName) Export

	TextUnitProductInUnits = 	
	"CatStorageUnits.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|	AND CatPackages.MeasuredValueType IN (
	|								VALUE(Enum.TypesOfMeasuredValues.Weight),
	|								VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
	|								VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement),
	|								VALUE(Enum.TypesOfMeasuredValues.Length))";
	
	QueryTextPackage = 
	"CASE
	|	WHEN &UnitGoodsInUnitsOfMeasure
	|		THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	ELSE Table.Package
	|END";
	
	QueryTextPackage = 
		StrReplace(QueryTextPackage, "&UnitGoodsInUnitsOfMeasure", TextUnitProductInUnits);
	
	TextNumberOfPackages = 
	"CASE
	|	WHEN &UnitGoodsInUnitsOfMeasure
	|		THEN Table.Count
	|	ELSE Table.NumberOfPackages
	|END";
	
	TextNumberOfPackages = 
		StrReplace(TextNumberOfPackages, "&UnitGoodsInUnitsOfMeasure", TextUnitProductInUnits);
	
	JoinText =
	"LEFT JOIN Catalog.Products AS CatProducts
	|	ON Table.Products = CatProducts.Ref
	|	LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS CatStorageUnits
	|	ON CatProducts.UnitOfMeasure = CatStorageUnits.Ref
	|	LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS CatPackages
	|	ON Table.Package = CatPackages.Ref";
		
	Settings = New Structure;
	Settings.Insert("UnitGoodsInUnitsOfMeasure", TextUnitProductInUnits);
	Settings.Insert("Package", StrReplace(QueryTextPackage, "Table", TableName));
	Settings.Insert("NumberOfPackages", StrReplace(TextNumberOfPackages, "Table", TableName));
	Settings.Insert("CompoundUnitGoodsInUnitOfMeasure", StrReplace(JoinText, "Table", TableName));
		
	Return Settings;
	
EndFunction

// Returns parameters for applying a piece item in a dimensional unit
//
// Returns:
//  Structure - contains application parameters:
//		*Package                             - Boolean - setting flag for the "<table name> " field.Packaging"
//		*NumberOfPackages                   - Boolean - setting flag for the "<table name> " field.Number of packages"
//		*UnitGoodsInUnitsOfMeasure          - Boolean - setting flag for the "&piece-by-piece " parameter in multi-Units"
//		*CompoundUnitGoodsInUnitOfMeasure - Boolean - indicates whether the design is configured "//&Junctionstudyreferencesexternal links"
//
Function ParametersOfApplicationOfPieceProductInDimensionalUnit() Export
	
	ApplicationSettings_ = New Structure;
	ApplicationSettings_.Insert("Package", True);
	ApplicationSettings_.Insert("NumberOfPackages", True);
	ApplicationSettings_.Insert("UnitGoodsInUnitsOfMeasure", True);
	ApplicationSettings_.Insert("CompoundUnitGoodsInUnitOfMeasure", True);
	
	Return ApplicationSettings_;
	
EndFunction		

// Applies the unit item settings to the request text, which is counted in the measurement unit
// See ProductionServer.RequestTextForCustomizingUnitProductInUnitOfMeasure 
// 
// Parameters:
//	QueryText - String - text of the request to which the settings are applied
//	TableName - String - See ProductionServer.RequestTextForCustomizingUnitProductInUnitOfMeasure
//	Parameters  - See ProductionServer.ParametersOfApplicationOfPieceProductInDimensionalUnit
//  
Procedure ApplyUnitItemSettingsInUnitOfMeasure(QueryText, TableName, Parameters = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = ParametersOfApplicationOfPieceProductInDimensionalUnit();	
	EndIf;
	
	Settings = RequestTextForCustomizingUnitProductInUnitOfMeasure(TableName);
	
	FieldName = "Package";
	If Parameters[FieldName] Then
		QueryText = StrReplace(QueryText, StrTemplate("%1.%2", TableName, FieldName), Settings[FieldName]);
	EndIf;
	
	FieldName = "NumberOfPackages";
	If Parameters[FieldName] Then
		QueryText = StrReplace(QueryText, StrTemplate("%1.%2", TableName, FieldName), Settings[FieldName]);
	EndIf;
	
	FieldName = "UnitGoodsInUnitsOfMeasure";
	If Parameters[FieldName] Then
		QueryText = StrReplace(QueryText, StrTemplate("&%1", FieldName), Settings[FieldName]);
	EndIf;	
		
	FieldName = "CompoundUnitGoodsInUnitOfMeasure";
	If Parameters[FieldName] Then	
		QueryText = StrReplace(QueryText, StrTemplate("//&%1", FieldName), Settings[FieldName]);
	EndIf;	
		
EndProcedure	

#EndRegion

#Region Other

// See ReportsTMOverridable.SupplementComplianceOfTrafficReportRegistrars
//
Procedure SupplementComplianceOfTrafficReportRegistrars(Document, RegisterMatching) Export
	
	Registers = Metadata.InformationRegisters;
	If TypeOf(Document) = Type("DocumentRef.EngineeringChangeOrder") Then
		
		RegisterMatching.Insert(Registers.ScopesOfSubstitutes, "Resolution");
		
	EndIf;
EndProcedure

// Enables / disables the use of properties for reference information.
//
Procedure SetUseOfCatalogProperties() Export
	
	SetParameters              = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseProduction.Get();
	
	PropertyManager.SetPropertySetParameters("Catalog_BillsOfMaterials", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_OrderOfMaterialsForProduction", SetParameters);	
	PropertyManager.SetPropertySetParameters("Catalog_WorkCenterTypes", SetParameters);
	PropertyManager.SetPropertySetParameters("Catalog_WorkCenters", SetParameters);
EndProcedure

// Fills in the selection data when entering text in the "Performer" field in the production stages and production without an order.
//
// Parameters:
//  ChoiceData - ValueList - list of values to fill in
//  Text - String - text entered in the field
//  Parameters - Structure - selection structure with keys:
//    * Department - CatalogRef.BusinessStructure - the department where the work is performed
//    * Organization - CatalogRef.Companies - organization of the brigade
//    * Date - Date - used to select employees for a specific date
//
Procedure FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 20
	|	Teams.Ref
	|FROM
	|	Catalog.Teams AS Teams,
	|	Catalog.BusinessStructure AS Attributes
	|
	|WHERE
	|	Attributes.Ref = &Department
	|	AND Attributes.UseTeamWorkOrders
	|	AND NOT Teams.DeletionMark
	|	AND Teams.Description LIKE &SearchString
	|	AND (Teams.Organization = &Organization
	|		OR &Organization = UNDEFINED)
	|
	|UNION ALL
	|
	|SELECT TOP 20
	|	Persons.Ref
	|FROM
	|	Catalog.Persons AS Persons,
	|	Catalog.BusinessStructure AS Attributes
	|
	|WHERE
	|	Attributes.Ref = &Department
	|	AND Attributes.UsePersonalWorkOrders
	|	AND NOT Persons.DeletionMark
	|	AND Persons.Description LIKE &SearchString
	|";
	
	Query.SetParameter("SearchString", Text + "%");
	Query.SetParameter("Department", Parameters.Department);
	
	If Parameters.Property("Organization")
		And ValueIsFilled(Parameters.Organization) Then
		Query.SetParameter("Organization", Parameters.Organization);
	Else
		Query.SetParameter("Organization", Undefined);
	EndIf;
	
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref);
	EndDo;
	
EndProcedure

// Defines what acts as a performer: a person or an employee.
// 
// Parameters:
//  Date - Date - The date that is used for comparison
// 
// Returns:
//  Boolean - The Accounting Of Labor Costs In The Context Of Employees Is Used
Function AccountingOfLaborCostsInContextOfEmployeesIsUsed(Date) Export
	
	BeginningOfAccountingOfLaborCostsForEmployees = Date(1,1,1);
	
	BeginningOfAccountingOfLaborCostsForEmployees = GetFunctionalOption("AccountingForLaborCostsByEmployees");
	
	Return ValueIsFilled(BeginningOfAccountingOfLaborCostsForEmployees) And Date >= BeginningOfAccountingOfLaborCostsForEmployees;
	
EndFunction


#EndRegion

#EndRegion

#Region Internal

#Region Posting

Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return;
	
EndProcedure

Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region HandlersForMonthClosingStages

#Region RegisterBackflushProduction

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_RegisterBackflushProduction(StepsTable,CurrentParent) Export
	
	NewRow =  MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterBackflushProduction);
	
	NewRow.MultilingualName = "vi = 'Đăng ký sản xuất không có đơn hàng (2.2)';
								|ru = 'Оформление производства без заказов (2.2)';
								|en = 'Register backflush production (2.2)';
								|it = 'Formalizzazione della produzione senza ordini (2.2)';
								|pl = 'Rejestracja produkcji bez zamówień (2.2)';
								|tr = 'Geriye dönük üretimlerin düzenlenmesi (2.2)'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ActionDesign =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProductionServer.Design_ProductionDesignWithoutOrders");
	NewRow.ActionUse =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProductionServer.Use_ProductionClearanceWithoutOrders");
	NewRow.ActionExecute  =  MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.DataProcessors.RegisterBackflushProduction.Forms.WorkplaceForm.FullName());
	NewRow.ActionExecute.FormParameters.Insert("CurrentPageName", "WorkGroup");
	
EndProcedure

// Stage handlers.

Procedure Use_ProductionClearanceWithoutOrders(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseProduction") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không hạch toán hoạt động sản xuất';
				|ru = 'Учет производственных операций не ведется';
				|en = 'Routing operation accounting is not kept'; fa = 'Routing operation accounting is not kept';
				|it = 'La contabilizzazione delle operazioni di produzione non viene effettuata';
				|pl = 'Ewidencja operacji produkcyjnych nie jest prowadzona';
				|tr = 'Rota işlemleri muhasebesi yapılmamaktadır'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	ProductionSettings = SubsystemSettingsProduction();
	
	If Not ProductionSettings.ProductionIsUsed22 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không quản lý sản xuất (phiên bản 2.2)';
				|ru = 'Не используется управление производством (версия 2.2)';
				|en = 'Production management, version 2.2 is not used'; fa = 'Production management, version 2.2 is not used';
				|it = 'Gestione della produzione non utilizzata (versione 2.2)';
				|pl = 'Nie jest używane zarządzanie produkcją (wersja 2.2)';
				|tr = 'Üretim yönetimi kullanılmamaktadır (sürüm 2.2)'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT ALLOWED
	|	CatProducts.Ref AS Work_5
	|INTO TTOperation
	|FROM
	|	Catalog.Products AS CatProducts
	|
	|WHERE
	|	CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|INDEX BY
	|	Work_5
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Works.Organization      AS Organization,
	|	Works.Department    AS Department,
	|	Works.Products     AS Products,
	|	Works.Characteristic   AS Characteristic,
	|	Works.Purpose       AS Purpose,
	// We get the volume of consumption of work in the Cur period, not provided with output.
	|	CASE
	|		WHEN Works.CountOpeningBalance > 0
	|			THEN Works.CountExpense - Works.CountReceipt - Works.CountOpeningBalance
	|		ELSE Works.CountExpense - Works.CountReceipt
	|	END AS Count
	|INTO TTUnformedProduction
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction.BalanceAndTurnovers(
	|		&BeginOfPeriod,
	|		&EndOfPeriod,,,
	|		Organization IN(&CompanyArray)
	|			AND Products IN(
	|				SELECT
	|					TTOperation.Work_5
	|				FROM
	|					TTOperation AS TTOperation)) AS Works
	|WHERE
	|	Works.CountClosingBalance < 0
	|	AND NOT CASE
	|			WHEN Works.CountOpeningBalance > 0
	|				THEN Works.CountExpense - Works.CountReceipt - Works.CountOpeningBalance
	|			ELSE Works.CountExpense - Works.CountReceipt
	|		END = 0
	|";
	
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTUnformedProduction = 0 Then

		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có công việc cần lập chứng từ xuất xưởng.';
				|ru = 'Нет работ, требующих оформления выпуска.';
				|en = 'There are no works requiring release registration.'; fa = 'There are no works requiring release registration.';
				|it = 'Non vi sono lavori che richiedono la registrazione della produzione.';
				|pl = 'Brak prac, wymagających utworzenia wydania.';
				|tr = 'Ürün çıkışı düzenlemesi gerektiren herhangi bir iş yoktur.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// Draws up the closing stage of the month for production without orders.
//
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Design_ProductionDesignWithoutOrders(HandlerParameters) Export
	
	ProductionSettings = SubsystemSettingsProduction();
	
	If Not (ProductionSettings.ProductionIsUsed21 And ProductionSettings.ProductionIsUsed22) Then
		HandlerParameters.Data_Stage.Description = NStr("vi = 'Tạo sản xuất không có đơn hàng';
														|ru = 'Оформление производства без заказов';
														|en = 'Register backflush production'; fa = 'ثبت تولید با کسر خودکار مواد';
														|it = 'Registrazione di produzione senza ordini';
														|pl = 'Rejestracja produkcji bez zamówień';
														|tr = 'Geriye dönük üretimin düzenlenmesi'");
	EndIf;
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Tạo';
													|ru = 'Оформить';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Preparare';
													|pl = 'Register';
													|tr = 'Düzenle'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfChecks_ProcessingOfProductionWithoutOrders(TableOfChecks) Export
	
	// Registration of production without orders (2.2).
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"OutstandingProductionWithoutOrders",
		Catalogs.MonthEndClosingOperations.RegisterBackflushProduction,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"ProductionServer.CheckingNeedForProductionWithoutOrders");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa lập chứng từ xuất xưởng công việc đã được người tiêu dùng tiếp nhận.';
			|ru = 'Не оформлен выпуск работ, принятых потребителями.';
			|en = 'The release of works accepted by consumers is not registered.'; fa = 'The release of works accepted by consumers is not registered.';
			|it = 'Produzione lavori accettati dai consumatori non registrata';
			|pl = 'Nie utworzono wydania prac, przyjętych przez nabywców.';
			|tr = 'Tüketiciler tarafından kabul edilen işlerin çıkışı düzenlenmedi.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần lập chứng từ xuất xưởng toàn bộ công việc đã được người tiêu dùng tiếp nhận.';
			|ru = 'Выпуск работ, принятых потребителями, должен быть оформлен в полном объеме.';
			|en = 'The release of works accepted by consumers must be registered in full.'; fa = 'The release of works accepted by consumers must be registered in full.';
			|it = 'La produzione di lavori accettati dai consumatori deve essere registrata per intero.';
			|pl = 'Wydanie prac, przyjętych przez nabywców, powinno być utworzone w pełnym zakresie.';
			|tr = 'Tüketiciler tarafından kabul edilen işlerin çıkışı eksiksiz olarak düzenlenmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

Procedure CheckingNeedForProductionWithoutOrders(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization",    NStr("vi = 'Doanh nghiệp';
											|ru = 'Организация';
											|en = 'Company'; fa = 'Company';
											|it = 'Azienda';
											|pl = 'Organizacja';
											|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department",  NStr("vi = 'Bộ phận';
										|ru = 'Подразделение';
										|en = 'Business unit'; fa = 'Business unit';
										|it = 'Reparto';
										|pl = 'Dział';
										|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("Products",   NStr("vi = 'Mặt hàng';
									|ru = 'Номенклатура';
									|en = 'Item'; fa = 'قلم';
									|it = 'Articolo';
									|pl = 'Produkt';
									|tr = 'Öğe'", Common.DefaultLanguageCode()));
	FieldList.Add("Characteristic", NStr("vi = 'Đặc tính mặt hàng';
										|ru = 'Характеристика номенклатуры';
										|en = 'Item variant'; fa = 'گونه قلم';
										|it = 'Caratteristica dell''articolo';
										|pl = 'Charakterystyka produktu';
										|tr = 'Ürün varyantları'", Common.DefaultLanguageCode()));
	FieldList.Add("Purpose",     NStr("vi = 'Mục đích';
										|ru = 'Назначение';
										|en = 'Assignment'; fa = 'تخصیص';
										|it = 'Assegnazione';
										|pl = 'Assignment';
										|tr = 'Atama'", Common.DefaultLanguageCode()));
	FieldList.Add("Count",     NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTUnformedProduction",
		NStr("vi = 'Theo doanh nghiệp ""%1"" trong %2 chưa lập chứng từ xuất xưởng công việc đã được người tiêu dùng tiếp nhận.';
			|ru = 'По организации ""%1"" за %2 не оформлен выпуск работ, принятых потребителями.';
			|en = 'The release of works accepted by consumers is not registered for %1 company as of %2.'; fa = 'The release of works accepted by consumers is not registered for %1 company as of %2.';
			|it = 'Per l''azienda ""%1"" per il periodo %2 non è registrata la produzione di lavori accettati dai consumatori.';
			|pl = 'Według firmy ""%1"" za %2 nie jest utworzone wydanie prac, przyjętych przez nabywców.';
			|tr = '""%1"" iş yerine ilişkin %2 için tüketiciler tarafından kabul edilen işlerin çıkışı düzenlenmedi.'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region RegisterWorkOutput

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_RegisterWorkOutput(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterWorkOutput);
	
	NewRow.MultilingualName = "vi = 'Lập sản lượng nhân viên';
								|ru = 'Оформление выработки сотрудников';
								|en = 'Register timesheets charge';
								|it = 'Formalizzazione della produttività dei dipendenti';
								|pl = 'Rejestracja wydajności pracowników';
								|tr = 'Zaman çizelgesi bazlı ücretlendirmenin düzenlenmesi'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Tạo';
								|ru = 'Оформить';
								|en = 'Register'; fa = 'ثبات';
								|it = 'Preparare';
								|pl = 'Register';
								|tr = 'Düzenle'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProductionServer.Use_EmployeeDevelopment");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"ProductionServer.Execute_EmployeeDevelopment");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.WorkOutput.Forms.DocumentsListForm.FullName());
	
EndProcedure

// Stage handlers.

Procedure Use_EmployeeDevelopment(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseProduction") Then
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không hạch toán sản xuất.';
				|ru = 'Производственный учет не ведется.';
				|en = 'Production accounting is not kept.'; fa = 'Production accounting is not kept.';
				|it = 'La contabilità di produzione non viene mantenuta.';
				|pl = 'Ewidencja produkcyjna nie jest prowadzona.';
				|tr = 'Üretim muhasebesi yapılmamaktadır.'", Common.DefaultLanguageCode()));
		Return;
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	// We select the orders for which there were movements in the current month
	//  - if the table is empty, then registration is not required.
	"SELECT
	|	DD.Organization AS Organization,
	|	DD.ProductionLot AS ProductionLot,
	|	DD.ReferenceOrder AS ReferenceOrder,
	|	DD.ReferenceRowCode AS ReferenceRowCode,
	|	SUM(DD.CountReceipt - DD.CountExpense) AS CountTurnover
	|INTO Turnovers
	|FROM
	|	AccumulationRegister.LaborCostsToRegister.BalanceAndTurnovers(
	|		&BeginOfPeriod,
	|		&EndOfPeriod,
	|		Month,,
	|		Organization IN (&CompanyArray)) AS DD
	|
	|GROUP BY
	|	DD.Organization,
	|	DD.ProductionLot,
	|	DD.ReferenceOrder,
	|	DD.ReferenceRowCode
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot,
	|	ReferenceOrder,
	|	ReferenceRowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// We will receive the orders for which the corrections were issued.
	// If there were no corrections, then the amount for registration is obtained by actual Balances,
	// if there were, then by turnover for the period.
	|SELECT
	|	Turnovers.Organization           AS Organization,
	|	Turnovers.ProductionLot    AS ProductionLot,
	|	Turnovers.ReferenceOrder          AS ReferenceOrder,
	|	Turnovers.ReferenceRowCode AS ReferenceRowCode
	|INTO OrdersWithCorrection
	|FROM
	|	Turnovers AS Turnovers
	|	
	|	INNER JOIN Document.BackflushProduction AS AttributesBP
	|	ON AttributesBP.Ref = Turnovers.ReferenceOrder
	|	AND AttributesBP.CorrectionSavesProductionLots
	|	
	|	INNER JOIN AccumulationRegister.LaborCostsToRegister AS LaborCostsToRegister
	|	ON LaborCostsToRegister.Organization = Turnovers.Organization
	|	AND LaborCostsToRegister.ProductionLot = Turnovers.ProductionLot
	|	AND LaborCostsToRegister.ReferenceOrder = Turnovers.ReferenceOrder
	|	AND LaborCostsToRegister.ReferenceRowCode = Turnovers.ReferenceRowCode
	|	
	|	INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsStorno
	|	ON DocumentsStorno.Ref = LaborCostsToRegister.Recorder
	|	AND DocumentsStorno.ReverseTransactionCorrection
	|	AND DocumentsStorno.Posted
	|	AND NOT DocumentsStorno.AdditionalRecord
	|
	|WHERE
	|	NOT LaborCostsToRegister.Count = 0
	|
	|GROUP BY
	|	Turnovers.Organization,
	|	Turnovers.ProductionLot,
	|	Turnovers.ReferenceOrder,
	|	Turnovers.ReferenceRowCode
	|
	|INDEX BY
	|	Organization,
	|	ProductionLot,
	|	ReferenceOrder,
	|	ReferenceRowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// We select the Balances according to the orders of the current month.
	|SELECT
	|	Balance.Organization AS Organization,
	|	Balance.CountBalance AS CountBalance
	|INTO OrganizationsWithOutstandingBalances
	|FROM
	|	AccumulationRegister.LaborCostsToRegister.Balance(
	|			,
	|			(Organization, ProductionLot, ReferenceOrder, ReferenceRowCode) IN
	|				(SELECT
	|					T.Organization,
	|					T.ProductionLot,
	|					T.ReferenceOrder,
	|					T.ReferenceRowCode
	|				FROM
	|					Turnovers AS T)) AS Balance
	|	
	// We exclude orders with corrections.
	|	LEFT JOIN OrdersWithCorrection AS OrdersWithCorrection
	|	ON OrdersWithCorrection.Organization = Balance.Organization
	|	AND OrdersWithCorrection.ProductionLot = Balance.ProductionLot
	|	AND OrdersWithCorrection.ReferenceOrder = Balance.ReferenceOrder
	|	AND OrdersWithCorrection.ReferenceRowCode = Balance.ReferenceRowCode
	|
	|WHERE
	// We exclude orders with corrections.
	|	OrdersWithCorrection.ProductionLot IS NULL
	|
	|UNION ALL
	|
	// Orders with corrections.
	|SELECT
	|	Turnovers.Organization AS Organization,
	|	Turnovers.CountTurnover AS CountBalance
	|FROM
	|	Turnovers AS Turnovers
	|	
	|	INNER JOIN OrdersWithCorrection AS OrdersWithCorrection
	|	ON OrdersWithCorrection.Organization = Turnovers.Organization
	|	AND OrdersWithCorrection.ProductionLot = Turnovers.ProductionLot
	|	AND OrdersWithCorrection.ReferenceOrder = Turnovers.ReferenceOrder
	|	AND OrdersWithCorrection.ReferenceRowCode = Turnovers.ReferenceRowCode
	|WHERE
	|	NOT Turnovers.CountTurnover = 0
	|";
	
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.Turnovers = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Trong kỳ  quy định, các nhân viên không làm việc, không cần lập tính sản lượng.';
				|ru = 'За указанный период работы сотрудниками не выполнялись, оформление выработки не требуется.';
				|en = 'Works were not performed by employees for the specified period; output registration is not required.'; fa = 'Works were not performed by employees for the specified period; output registration is not required.';
				|it = 'Per il periodo specificato, il lavoro non è stato eseguito dai dipendenti, non è richiesta alcuna regolarizzazione della produttività.';
				|pl = 'Za wskazany okres przez pracowników prace nie były wykonywane, sporządzenie produkowania nie jest potrzebne.';
				|tr = 'Belirtilen çalışma dönemi boyunca çalışanlar tarafından gerçekleştirilmedi, çıktı gerekli değil.'", Common.DefaultLanguageCode()));
		
	ElsIf TemporaryTableSizes.OrganizationsWithOutstandingBalances = 0 Then
		
		// All production is issued.
		Return;
		
	Else
		
		MonthEndTransactionsServer.CaptureUsageHandlerResultsForOrganizations(
			HandlerParameters,
			NStr("vi = 'Đối với doanh nghiệp ""%1"" trong kỳ  %2, đầu ra không được cấp cho tất cả nhân viên.';
				|ru = 'По организации ""%1"" за период %2 выработка оформлена не по всем сотрудникам.';
				|en = 'Work output is not registered by some employees for the ""%1"" company for period %2.'; fa = 'Work output is not registered by some employees for the ""%1"" company for period %2.';
				|it = 'Secondo l''organizzazione ""%1"" per il periodo %2 la produttività è stata regolarizzata non per tutti i dipendenti.';
				|pl = 'Wg firm ""%1"" za okres %2 produkowanie jest sporządzone nie dla wszystkich pracowników.';
				|tr = '""%1"" iş yerine ilişkin %2 dönemindeki çıktı, tüm çalışanlar için düzenlenmedi.'", Common.DefaultLanguageCode()),
			Query,
			"OrganizationsWithOutstandingBalances",
			False,
			True);
		
	EndIf;
	
EndProcedure

Procedure Execute_EmployeeDevelopment(HandlerParameters) Export
	
	Documents.WorkOutput.IssueAtEndOfMonth(HandlerParameters);
	
EndProcedure

#EndRegion

#Region AcceptInternalWorks

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
//
Procedure AddStage_AcceptInternalWorks(StepsTable,CurrentParent) Export
	
	NewRow =  MonthEndTransactionsServer.AddStageToTable(
		StepsTable,
		CurrentParent,
		Catalogs.MonthEndClosingOperations.AcceptInternalWorks);
	
	NewRow.MultilingualName = "vi = 'Tiếp nhận công việc nội bộ';
								|ru = 'Приемка внутренних работ';
								|en = 'Internal work acceptance';
								|it = 'Internal work acceptance';
								|pl = 'Internal work acceptance';
								|tr = 'Dahili işlerin kabulü'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ActionDesign =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProductionServer.Registration_AcceptanceOfInternalWorks");
	NewRow.ActionUse =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProductionServer.Use_AcceptanceOfInternalWorks");
	
	NewRow.ActionExecute =
		MonthEndTransactionsServer.ActionDescription_OpenForm(
			Metadata.DataProcessors.LogOfProductionDocuments.Forms.DocumentsList.FullName(),
			True);
	
	NewRow.ActionExecute.FormParameters.Insert("FormAssignmentKey", "MonthEndTransactions");
	
	FilterDocumentTypes = New ValueList;
	FilterDocumentTypes.Add(Common.MetadataObjectID(Type("DocumentRef.InternalAcceptanceCertificate")));
	NewRow.ActionExecute.FormParameters.Filter.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	FilterBusinessTransactions = New ValueList;
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits);
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices);
	NewRow.ActionExecute.FormParameters.Filter.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	
	NewRow.ActionExecute.FormParameters.Filter.Insert("Status", Enums.StatusesOfInternalAcceptanceCertificate.Issued);
	
EndProcedure

// Stage handlers
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Use_AcceptanceOfInternalWorks(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	DocumentAttributes.Organization AS Organization,
	|	DocumentAttributes.Document    AS Document
	|INTO AcceptInternalWorks
	|FROM
	|	(SELECT
	|		DocumentAttributes.Organization AS Organization,
	|		DocumentAttributes.Ref      AS Document
	|	FROM
	|		Document.InternalAcceptanceCertificate AS DocumentAttributes
	|	WHERE
	|		DocumentAttributes.Posted
	|		AND DocumentAttributes.Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Issued)
	|		AND DocumentAttributes.Organization IN (&CompanyArray)
	|		AND DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentAttributes.CompanyRecipient AS Organization,
	|		DocumentAttributes.Ref                AS Document
	|	FROM
	|		Document.InternalAcceptanceCertificate AS DocumentAttributes
	|	WHERE
	|		DocumentAttributes.Posted
	|		AND DocumentAttributes.Status = VALUE(Enum.StatusesOfInternalAcceptanceCertificate.Issued)
	|		AND DocumentAttributes.CompanyRecipient IN (&CompanyArray)
	|		AND DocumentAttributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	) AS DocumentAttributes
	|
	|GROUP BY
	|	DocumentAttributes.Organization,
	|	DocumentAttributes.Document
	|";
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.AcceptInternalWorks = 0 Then
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có biên bản công việc nội bộ nào cần nghiệm thu. ';
				|ru = 'Нет актов внутренних работ, требующих приемки.';
				|en = 'There are no internal works acceptance to take over.'; fa = 'There are no internal works acceptance to take over.';
				|it = 'There are no internal works acceptance to take over.';
				|pl = 'There are no internal works acceptance to take over.';
				|tr = 'Kabulü gereken dahili iş tutanakları bulunmamaktadır.'", Common.DefaultLanguageCode()));
	EndIf;
	
EndProcedure

// Forms out the closing stage of the month.
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_AcceptanceOfInternalWorks(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Tiếp nhận';
													|ru = 'Принять';
													|en = 'Accept'; fa = 'پذیرش';
													|it = 'Accept';
													|pl = 'Accept';
													|tr = 'Kabul et'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.
// 
// Parameters:
// 	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure DescriptionOfInspections_AcceptanceOfInternalWorks(TableOfChecks) Export
	
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(
		TableOfChecks,
		"AcceptInternalWorks",
		Catalogs.MonthEndClosingOperations.AcceptInternalWorks,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"ProductionServer.InspectionAcceptanceOfInternalWorks");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa nghiệm thu các biên bản công việc nội bộ.';
			|ru = 'Не приняты акты внутренних работ.';
			|en = 'Internal works acceptance is not performed.'; fa = 'Internal works acceptance is not performed.';
			|it = 'Internal works acceptance is not performed.';
			|pl = 'Internal works acceptance is not performed.';
			|tr = 'Dahili iş tutanakları kabul edilmedi.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Tất cả các biên bản công việc nội bộ đã lập phải được nghiệm thu hoặc hủy bỏ.';
			|ru = 'Все выставленные акты выполненных внутренних работ должны быть приняты, либо отменены.';
			|en = 'All issued internal works acceptance must be performed or cancelled.'; fa = 'All issued internal works acceptance must be performed or cancelled.';
			|it = 'All issued internal works acceptance must be performed or cancelled.';
			|pl = 'All issued internal works acceptance must be performed or cancelled.';
			|tr = 'Gerçekleştirilen dahili işlerin tüm tutanakları kabul edilmeli veya iptal edilmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

// Error logging.
// 
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure InspectionAcceptanceOfInternalWorks(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Firma';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Document",    NStr("vi = 'Chứng từ';
										|ru = 'Документ';
										|en = 'Document'; fa = 'سند';
										|it = 'Documento';
										|pl = 'Dokument';
										|tr = 'Belge'",   Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"AcceptInternalWorks",
		NStr("vi = 'Đã phát hiện các biên bản công việc nội bộ của doanh nghiệp ""%1"" trong %2 cần nghiệm thu.';
			|ru = 'Обнаружены акты внутренних работ по организации ""%1"" за %2, требующие приемки.';
			|en = 'The internal work acceptance documents of the ""%1"" company for %2 that require acceptance are found.'; fa = 'The internal work acceptance documents of the ""%1"" company for %2 that require acceptance are found.';
			|it = 'The internal work acceptance documents of the ""%1"" company for %2 that require acceptance are found.';
			|pl = 'The internal work acceptance documents of the ""%1"" company for %2 that require acceptance are found.';
			|tr = 'Kabulü gereken %2 için ""%1"" iş yeri ile ilgili dahili iş tutanakları bulundu.'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region CheckingDetails

// Checks whether the recipient is filled in in the table part.
//
// Parameters:
//	Object - DocumentObject - document being checked
//	TSName  - String         - name of the table part
//	Cancel  - Boolean         - Indicates the presence of errors.
//
Procedure CheckRecipientSFillingInTablePart(Object, TSName, Cancel) Export
	
	ObjectMetadata  = Object.Metadata();
	TSMetadata       = ObjectMetadata.TabularSections[TSName];
	TSSynonym          = TSMetadata.Synonym;
	CompositeType       = TSMetadata.Attributes.Recipient.Type.Types().Count() > 1;
	
	FlagForCancelingRows =
		TMCommonUse.ThereArePropsForPartOfObject("Canceled", ObjectMetadata, TSName);
	
	QueryText =
	"SELECT
	|	TabularSection.LineNumber      AS LineNumber,
	|	TabularSection.Products     AS Products,
	|	TabularSection.Recipient       AS Recipient,
	|	TabularSection.ToExpenseAs AS ToExpenseAs
	|INTO TabularSection
	|FROM
	|	&TabularSection AS TabularSection
	|WHERE
	|	&FilterCanceled
	|";
	
	QueryText = StrReplace(QueryText, 
		"&FilterCanceled", ?(FlagForCancelingRows, "NOT TabularSection.Canceled", "TRUE"));
	
	QueryText = QueryText + Common.QueryBatchSeparator();
	
	If CompositeType Then
		
		QueryText = QueryText + "	
		|SELECT
		|	TabularSection.LineNumber AS LineNumber,
		|	CASE
		|		WHEN TabularSection.Recipient = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                      AS NotSpecified
		|FROM
		|	TabularSection AS TabularSection
		|		LEFT JOIN Catalog.Warehouses AS CheckTable
		|		ON TabularSection.Recipient = CheckTable.Ref
		|WHERE
		|	 
		|	CAST(TabularSection.Products AS Catalog.Products).ItemsType IN (
		|					VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND NOT TabularSection.ToExpenseAs
		|	AND ISNULL(CheckTable.Ref, VALUE(Catalog.Warehouses.EmptyRef)) = VALUE(Catalog.Warehouses.EmptyRef)
		|	AND NOT &LeaveProductsAtSubcontractor
		|	AND &ProductWarehouseGroup
		|
		|UNION ALL
		|
		|SELECT
		|	TabularSection.LineNumber,
		|	CASE
		|		WHEN TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|FROM
		|	TabularSection AS TabularSection
		|		LEFT JOIN Catalog.BusinessStructure AS CheckTable
		|		ON TabularSection.Recipient = CheckTable.Ref
		|WHERE
		|	 
		|	CAST(TabularSection.Products AS Catalog.Products).ItemsType IN (
		|					VALUE(Enum.ItemsTypes.Work_5))
		|	AND NOT TabularSection.ToExpenseAs
		|	AND ISNULL(CheckTable.Ref, VALUE(Catalog.BusinessStructure.EmptyRef)) = VALUE(Catalog.BusinessStructure.EmptyRef)
		|
		|ORDER BY
		|	LineNumber";
		
	Else
		
		QueryText = QueryText + "	
		|SELECT
		|	TabularSection.LineNumber AS LineNumber,
		|	TRUE                     AS NotSpecified
		|FROM
		|	TabularSection AS TabularSection
		|WHERE
		|	 
		|	CAST(TabularSection.Products AS Catalog.Products).ItemsType IN (
		|					VALUE(Enum.ItemsTypes.Work_5))
		|	AND TabularSection.ToExpenseAs = FALSE
		|	AND TabularSection.Recipient = VALUE(Catalog.BusinessStructure.EmptyRef)";
		
	EndIf;	
	
	Query       = New Query;
	Query.Text = QueryText;
	
	TableColumns1 = "LineNumber, Products, Recipient, ToExpenseAs" 
		+ ?(FlagForCancelingRows, ", Canceled", "");
		
	Query.SetParameter("TabularSection", Object[TSName].Unload(, TableColumns1));
	
	ProductWarehouseGroup = True;
	If CommonClientServer.HasAttributeOrObjectProperty(Object, "ManufacturedProductsWarehouse") Then
		ProductWarehouseGroup = Catalogs.Warehouses.IsFolder(Object.ManufacturedProductsWarehouse);
	EndIf;
	Query.SetParameter("ProductWarehouseGroup", ProductWarehouseGroup);
	
	LeaveProductsAtSubcontractor = False;
	If CommonClientServer.HasAttributeOrObjectProperty(Object, "LeaveProductsAtSubcontractor") Then
		LeaveProductsAtSubcontractor = Object.LeaveProductsAtSubcontractor;
	EndIf;
	Query.SetParameter("LeaveProductsAtSubcontractor", LeaveProductsAtSubcontractor);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			If Selection.NotSpecified Then
				ErrorText = CommonClientServer.FillingErrorText("COLUMN", "FILLTYPE"  , "Recipient", Selection.LineNumber, TSSynonym);
			Else
				ErrorText = CommonClientServer.FillingErrorText("COLUMN", "CORRECTNESS", "Recipient", Selection.LineNumber, TSSynonym);
			EndIf;
			
			Common.MessageToUser(
				ErrorText,
				Object,
				CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "Recipient"),
				,
				Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Checks whether the cost shares are filled in in the table part.
//
// Parameters:
//	Object                        - DocumentObject - document being checked
//	TSName                         - String         - name of the table part
//	NotCheckedAttributeArray - Array         - banking details that don't need to be verified by platform verification
//	Cancel                         - Boolean         - Indicates the presence of errors.
//
Procedure CheckIfCostFractionsAreFilledInInTablePart(Object, TSName, NotCheckedAttributeArray, Cancel) Export
	
	ArrayOfCostDimensions = New Array;
	ArrayOfCostDimensions.Add(Enums.CostGroupingsInTollingOrder.NoGrouping);
	ArrayOfCostDimensions.Add(Enums.CostGroupingsInTollingOrder.ByProductBOM);
	ArrayOfCostDimensions.Add(Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments);
	ArrayOfCostDimensions.Add(Enums.CostGroupingsInTollingOrder.ByProductionStages);
	If ArrayOfCostDimensions.Find(Object.GroupCosts) = Undefined Then
		NotCheckedAttributeArray.Add(TSName + ".CostShare");
		Return;
	EndIf;
	
	CheckCostAllocationMethod =
		Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOM
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments;
	
	ObjectMetadata = Object.Metadata();
	ObjectManager   = Common.ObjectManagerByFullName(ObjectMetadata.FullName());
	
	CostAllocationParameters = ObjectManager.CostAllocationParameters(Object);
	
	If CheckCostAllocationMethod
	   And CostAllocationParameters.MethodOfAllocatingFinishedProductCosts 
			<> Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray.Add(TSName + ".CostShare");
		
	LinkFields                  = CostAllocationParameters.LinkFields;
	CostGroupField_           = CostAllocationParameters.CostGroupingField;
	CostShareVerificationFields = StrSplit(LinkFields, ",");
	
	RequestFieldTemplate = "	%1%2 AS %3";
	
	ArrayOfRequestFields = New Array;
	ArrayOfRequestFields.Add(StrTemplate(RequestFieldTemplate, ""				 , "&Ref"      , "Ref"));
	ArrayOfRequestFields.Add(StrTemplate(RequestFieldTemplate, "TabularSection.", "LineNumber"  , "LineNumber"));
	ArrayOfRequestFields.Add(StrTemplate(RequestFieldTemplate, "TabularSection.", "CostShare", "CostShare"));
	
	FlagForCancelingRows = TMCommonUse.ThereArePropsForPartOfObject("Canceled", ObjectMetadata, TSName);
	If FlagForCancelingRows Then
		ArrayOfRequestFields.Add(StrTemplate(RequestFieldTemplate, "TabularSection.", "Canceled", "Canceled"));
	EndIf;	
	
	CostGroupInHeader = False;
	If ValueIsFilled(CostGroupField_) Then
		
		CostGroupInHeader = Not TMCommonUse.ThereArePropsForPartOfObject(CostGroupField_, ObjectMetadata, TSName);
		
		If CostGroupInHeader Then
			ArrayOfRequestFields.Add(StrTemplate(RequestFieldTemplate, ""               , "&ExpenseGroup" , CostGroupField_));	
		Else
			ArrayOfRequestFields.Add(StrTemplate(RequestFieldTemplate, "TabularSection.", CostGroupField_, CostGroupField_));
		EndIf;	
		
	EndIf;	
	
	For Each VerificationField In CostShareVerificationFields Do
		ArrayOfRequestFields.Add(StrTemplate(RequestFieldTemplate, "TabularSection.", VerificationField, VerificationField));	
	EndDo;
	
	RequestFieldSeparator = ",
							  |";
	QueryTextFields 	= StrConcat(ArrayOfRequestFields, RequestFieldSeparator);
	QueryTextCondition = ?(FlagForCancelingRows, "WHERE NOT TabularSection.Canceled", "");
		
	QueryText = 
	"SELECT
	|	&QueryTextFields
	|INTO TabularSection
	|FROM
	|	&TabularSection AS TabularSection
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextFields", QueryTextFields) + QueryTextCondition + "
		|INDEX BY
		|	Ref";
	
	ArrayOfRequestTexts_ = New Array;
	ArrayOfRequestTexts_.Add(QueryText); 
	ArrayOfRequestTexts_.Add(QueryTextCheckSharesOfCostOfOutputProducts(LinkFields, CostGroupField_));
	
	QueryText = StrConcat(ArrayOfRequestTexts_, Common.QueryBatchSeparator());
				   
	Query       = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Ref"         , Object.Ref); 
	Query.SetParameter("TabularSection" , Object[TSName]);
	
	If CostGroupInHeader Then
		Query.SetParameter("ExpenseGroup" , Object[CostGroupField_]);	
	EndIf;	
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		
		TSSynonym = ObjectMetadata.TabularSections[TSName].Synonym;
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			ErrorText = CommonClientServer.FillingErrorText(
				"COLUMN", "FILLTYPE", "Share costs_2", Selection.LineNumber, TSSynonym);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				Object,
				CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "CostShare"),
				,
				Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure	

#EndRegion

#EndRegion

#Region Private

#Region Math

#Region Node_

Function GreatestCommonDivisorInCollection(Collection, ColumnName = "Count") Export
	
	If TypeOf(Collection) <> TypeOf("TabularSection") Then
		ArrayOfNumbers = New Array;
		For Each CollectionItem In Collection Do
			ArrayOfNumbers.Add(CollectionItem[ColumnName]);
		EndDo;
	Else
		ArrayOfNumbers = TMCommonUse.UnloadColumnValues(Collection, ColumnName);
	EndIf;
	
	If ArrayOfNumbers.Count() < 2 Then
		
		Node_ = 1;
		
	Else
		
		Node_ = ArrayOfNumbers[0];
		
		For IndexOf = 1 To ArrayOfNumbers.Count()-1 Do
		
			Node_ = GreatestCommonDivisor(Node_, ArrayOfNumbers[IndexOf]);
			
			If Node_ = 1 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Node_;
	
EndFunction

Function GreatestCommonDivisor(Val Numerator, Val Denominator) Export
	
	If Numerator = 0 Or Denominator = 0 Then
		
		Return 1;
		
	EndIf;

	While Denominator <> 0 Do
		
		Remainder = Numerator % Denominator;
		Numerator = Denominator;
		Denominator = Remainder;
		
	EndDo;
	
	Return Numerator;

EndFunction

#EndRegion

#Region NOC

Function SmallestCommonMultipleInCollection(Collection, ColumnName = "Count") Export
	
	If TypeOf(Collection) <> TypeOf("TabularSection") Then
		ArrayOfNumbers = New Array;
		For Each CollectionItem In Collection Do
			ArrayOfNumbers.Add(CollectionItem[ColumnName]);
		EndDo;
	Else
		ArrayOfNumbers = TMCommonUse.UnloadColumnValues(Collection, ColumnName);
	EndIf;
	
	Return SmallestCommonMultiple(ArrayOfNumbers);
	
EndFunction

Function SmallestCommonMultiple(Numbers_1) Export

	NOC = 1;
	
	For Each Number In Numbers_1 Do
		
		NOC = NOC * Number / GreatestCommonDivisor(NOC,Number);
		
	EndDo;
	
	Return NOC;
	
EndFunction

#EndRegion

#Region Fractions

// Creates a structure for storing fractions
// 
// Parameters:
//  Numerator - Number
//  Denominator - Number
// 
// Returns:
//  Structure - Fraction:
// * Numerator - Number
// * Denominator - Number
// * Value - Number
Function Fraction(Val Numerator, Val Denominator) Export
	
	Fraction = ProductionClientServer.Fraction(Numerator, Denominator);
	Return Fraction;

EndFunction

Function MinFraction(Fraction1, Fraction2) Export
	
	If Fraction1.Numerator * Fraction2.Denominator < Fraction2.Numerator * Fraction1.Denominator Then
		
		Return Fraction(Fraction1.Numerator, Fraction1.Denominator);
		
	Else
		
		Return Fraction(Fraction2.Numerator, Fraction2.Denominator);
		
	EndIf;
	
EndFunction

Function MaxFraction(Fraction1, Fraction2) Export
	
	If Fraction1.Numerator * Fraction2.Denominator > Fraction2.Numerator * Fraction1.Denominator Then
		
		Return Fraction(Fraction1.Numerator, Fraction1.Denominator);
		
	Else
		
		Return Fraction(Fraction2.Numerator, Fraction2.Denominator);
		
	EndIf;
	
EndFunction

Function SumOfFractions(ArrayOfFractions, ShortenResult = False) Export
	
	SmallestCommonMultiple = SmallestCommonMultipleInCollection(ArrayOfFractions, "Denominator");
	
	Numerator = 0;
	For Each Fraction In ArrayOfFractions Do
		Numerator = Numerator + Fraction.Numerator * SmallestCommonMultiple / Fraction.Denominator;
	EndDo;
	
	Result = ProductionClientServer.Fraction(Numerator, SmallestCommonMultiple);
	
	If ShortenResult Then
		
		ReduceFraction(Result);
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ReduceFraction(Fraction) Export
	
	GreatestCommonDivisor = GreatestCommonDivisor(Fraction.Numerator, Fraction.Denominator);
	
	Fraction.Numerator   = Fraction.Numerator / GreatestCommonDivisor;
	Fraction.Denominator = Fraction.Denominator / GreatestCommonDivisor;
	
EndProcedure

#EndRegion

#EndRegion

#Region JobsQueue

// Handles the task queue.
// 
// Parameters:
//  Parameters       - Structure - with keys:
//   * Queue       - String    - queue name (name of the queue information register).
//   * Filter         - Structure - tasks for this selection will be processed first.
//   * Id - UUID, Array, Undefined - ID or list of task IDs
//                        If the background job is started in the same transaction as adding new jobs to the queue
//                           , it is possible that the background job is running, the transaction is not completed and the jobs for
//                           processing are not visible to the background job session.
//                        To solve this problem, before processing the first batch of jobs from the queue, a
//                           transaction is opened and a lock is set on jobs in the queue by ID.
//  ResultAddress - String, Undefined - the address in the temporary storage.
//
Procedure ProcessTaskQueue(Parameters, ResultAddress = Undefined) Export
	
	Queue = Parameters.Queue;
	
	ProcessingParameters = InformationRegisters[Queue].ProcessingParameters();
	
	HandlerParameters = New Array(3); // (Task, Skip task = False, additional data)
	
	ExpectCompletionOfWritingJobsToQueue(Queue, Parameters.Id);
	
	TasksToProcess = InformationRegisters[Queue].JobsQueue(Parameters.Filter);
	
	While TasksToProcess <> Undefined Do
		
		JobsList = InformationRegisters[Queue].SelectFromQueue(TasksToProcess);
		
		While JobsList.UBound() <> - 1 Do
			
			HandlerParameters[0] = JobsList[0];
			HandlerParameters[1] = False;
			HandlerParameters[2] = ProcessingParameters.AdditionalData;
			
			Try
				
				Common.ExecuteConfigurationMethod(
					ProcessingParameters.Handler,
					HandlerParameters);
				
			Except
				
				InformationRegisters[Queue].WriteError(HandlerParameters[0], HandlerParameters[1], ErrorInfo());
				
			EndTry;
			
			If HandlerParameters[1] <> True Then
				
				InformationRegisters[Queue].DeleteJob(JobsList[0], TasksToProcess);
				
			EndIf;
			
			JobsList.Delete(0);
			
		EndDo;
		
		TasksToProcess = InformationRegisters[Queue].JobsQueue();
		
	EndDo;
	
EndProcedure

Function TaskQueueIsEmpty(Queue, Filter)
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	&InformationRegister AS Queue
	|WHERE
	|	&FilterText1");
	
	Query.Text = StrReplace(Query.Text, "&InformationRegister", "InformationRegister." + Queue);
	
	FilterText1 = "TRUE";
	If ValueIsFilled(Filter) Then
		
		FilterRows = New Array;
		For Each KeyValue In Filter Do
			FilterRows.Add(KeyValue.Key + " = &" + KeyValue.Key);
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
		FilterText1 = StrConcat(FilterRows, " And ");
		
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FilterText1", FilterText1);
	
	SetPrivilegedMode(True);
	Return Query.Execute().IsEmpty();
	
EndFunction

Procedure ExpectCompletionOfWritingJobsToQueue(Queue, Id = Undefined)
	
	If ValueIsFilled(Id) Then
		
		BeginTransaction();
		Try
			
			QueueName = "InformationRegister." + Queue;
			
			DataLock = New DataLock;
			
			If TypeOf(Id) <> Type("Array") Then
				DataLock.Add(QueueName).SetValue("Id", Id);
			Else
				For Each LockItem In Id Do
					DataLock.Add(QueueName).SetValue("Id", LockItem);
				EndDo;
			EndIf;
			
			DataLock.Lock();
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			WriteLogEvent(TaskQueueProcessingEvent(), EventLogLevel.Warning, Metadata.InformationRegisters[Queue],,
				DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndIf;
	
EndProcedure

Function JobsQueue(Queue, Filter = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(
	"SELECT
	|	*
	|INTO ProcessedTasks
	|FROM
	|	&InformationRegister AS Queue
	|WHERE
	|	&FilterText1
	|");
	
	Query.Text = StrReplace(Query.Text, "&InformationRegister", "InformationRegister." + Queue);
	
	FilterText1 = "TRUE";
	If ValueIsFilled(Filter) Then
		
		FilterRows = New Array;
		For Each KeyValue In Filter Do
			FilterRows.Add(KeyValue.Key + " = &" + KeyValue.Key);
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
		FilterText1 = StrConcat(FilterRows, " And ");
		
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FilterText1", FilterText1);
	
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	If QueryResult.Unload()[0].Count = 0 Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return TempTablesManager;
	
EndFunction

Function SelectFromQueue(Queue, TempTablesManager) Export
	
	Dimensions = Metadata.InformationRegisters[Queue].Dimensions;
	
	FieldList = New Array;
	ListOfSelectionFields = New Array;
	ListOfDimensionFields = New Array;
	
	NumberOfMeasurements = Dimensions.Count();
	IndexOf = 0;
	
	While IndexOf < NumberOfMeasurements Do
		
		Dimension = Dimensions[IndexOf];//MetadataObject -
		IndexOf = IndexOf + 1;

		If Dimension.Name <> "Id" And Dimension.Name <> "RegistrationDay" And StrFind(Dimension.Name, "Delete") = 0 Then
			FieldList.Add(Dimension.Name);
			ListOfSelectionFields.Add(StrTemplate("ProcessedTasks.%1 AS %1", Dimension.Name));
			ListOfDimensionFields.Add(StrTemplate("ProcessedTasks.%1", Dimension.Name));
		EndIf;
	EndDo;
	Query = New Query(
	"SELECT
	|	&ListOfSelectionFields
	|FROM
	|	ProcessedTasks AS ProcessedTasks
	|GROUP BY
	|	&ListOfDimensionFields
	|");
	
	Query.Text = StrReplace(Query.Text, "&ListOfSelectionFields", StrConcat(ListOfSelectionFields, ","));
	Query.Text = StrReplace(Query.Text, "&ListOfDimensionFields", StrConcat(ListOfDimensionFields, " , "));
	
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Result = New Array();
	
	Keys = StrConcat(FieldList, ",");
	While Selection.Next() Do
		Job = New Structure(Keys);
		FillPropertyValues(Job, Selection);
		Result.Add(Job);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure DeleteJob(Queue, Job, TempTablesManager) Export
	
	Dimensions = Metadata.InformationRegisters[Queue].Dimensions;//MetadataObjectCollection -
	
	Query = New Query();
	
	FieldList = New Array;
	ListOfSelectionFields_ = New Array;
	
	NumberOfMeasurements = Dimensions.Count();
	IndexOf = 0;
	
	While IndexOf < NumberOfMeasurements Do
		
		Dimension = Dimensions[IndexOf];//MetadataObject -
		IndexOf = IndexOf + 1;
		
		If Dimension.Name <> "Id" And Dimension.Name <> "RegistrationDay" And StrFind(Dimension.Name, "Delete") = 0 Then
			FieldList.Add(Dimension.Name);
			ListOfSelectionFields_.Add(StrTemplate("ProcessedTasks.%1 = &%1", Dimension.Name));
			Query.SetParameter(Dimension.Name, Job[Dimension.Name]);
		EndIf;
	EndDo;
	
	Query.Text =
	"SELECT
	|	ProcessedTasks.Id AS Id
	|FROM
	|	ProcessedTasks AS ProcessedTasks
	|WHERE
	|	&ListOfSelectionFields_
	|";
	
	Query.Text = StrReplace(Query.Text, "&ListOfSelectionFields_", StrConcat(ListOfSelectionFields_," And "));
	
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Set = InformationRegisters[Queue].CreateRecordSet(); // InformationRegisterRecordSet.QueueOfProductionPlanCalculation
		
		Set.Filter.Id.Set(Selection.Id);
		
		Set.Write(True);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure RecordTaskQueueProcessingError(Queue, ErrorText, Job = Undefined, Data = Undefined) Export
	
	EventName = TaskQueueProcessingEvent();
	
	If ValueIsFilled(Job) Then
		
		JobDetails = New Array;
		
		For Each KeyAndValue In Job Do
			JobDetails.Add(StrTemplate("%1: %2", KeyAndValue.Key, KeyAndValue.Value));
		EndDo;
		
		ErrorDescription = StrTemplate(NStr("vi = 'Lỗi xử lý nhiệm vụ :
			|
			|%2
			|
			|%3';
			|ru = 'Ошибка обработки задания :
			|
			|%2
			|
			|%3';
			|en = 'An error occurred while processing the job:
			|
			|%2
			|
			|%3'; fa = 'An error occurred while processing the job:
			|
			|%2
			|
			|%3';
			|it = 'Errore elaborazione task:
			|
			|%2
			|
			|%3';
			|pl = 'Błąd przetwarzania zadania :
			|
			|%2
			|
			|%3';
			|tr = 'Görev işleme hatası :
			|
			|%2
			|
			|%3'"), StrConcat(JobDetails, ";" + Chars.LF), ErrorText);
		
	Else
		ErrorDescription = ErrorText;
	EndIf;
	
	WriteLogEvent(
		EventName,
		EventLogLevel.Error,
		Metadata.InformationRegisters[Queue],
		Data,
		ErrorDescription);
	
EndProcedure

#EndRegion

#Region CalculationOfCostShares

Function QueryTextCheckSharesOfCostOfOutputProducts(LinkFields, CostGroupField_ = "") Export
	
	QueryText =
	"SELECT
	|	Table.ExpenseGroup AS ExpenseGroup,
	|	SUM(1)			 AS Count
	|INTO UseFractionOfCost
	|FROM
	|	(SELECT DISTINCT
	|		Table.Ref	  AS Ref,
	|		&CostGroupField AS ExpenseGroup,
	|		&CommunicationFieldsField,
	|		Table.CostShare = 0 AS ShareValueAttribute
	|	FROM
	|		TabularSection AS Table) AS Table
	|
	|GROUP BY
	|	Table.ExpenseGroup
	|
	|HAVING
	|	SUM(1) > 1
	|
	|INDEX BY
	|	Table.ExpenseGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref      AS Ref,
	|	Table.LineNumber AS LineNumber
	|FROM
	|	TabularSection AS Table
	|		INNER JOIN UseFractionOfCost AS UseFractionOfCost
	|		ON &CostGroupConnection
	|WHERE
	|	Table.CostShare = 0
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	QueryTextCommunicationFieldsField = "";
	ArrayOfCommunicationFields          = StrSplit(LinkFields, ",");
	For Each LinksField In ArrayOfCommunicationFields Do
		QueryTextCommunicationFieldsField = QueryTextCommunicationFieldsField + "Table." + LinksField + "," + Chars.LF;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&CommunicationFieldsField", 
		Left(QueryTextCommunicationFieldsField, StrLen(QueryTextCommunicationFieldsField) - 2));
		
	QueryText = StrReplace(QueryText, "&CostGroupField",
		?(ValueIsFilled(CostGroupField_), "Table." + CostGroupField_, "TRUE"));
	
	QueryText = StrReplace(QueryText, "&CostGroupConnection",
		?(ValueIsFilled(CostGroupField_), "Table." + CostGroupField_ + " = UseFractionOfCost.ExpenseGroup", "(TRUE)"));
	
	Return QueryText;
	
EndFunction

Function SubstitutionParametersOfCostFractionCalculationAlgorithm(TableName = "TabularSection", 
															SourceMethodOfDistributionOfCostsForOutputProducts = "&MethodOfAllocatingFinishedProductCosts", 
															QueryTextFilterRemainingGoodsByShelfLives = "",
															UsePriceManagementSystem25 = Undefined) Export
	
	Parameters = New Structure;
	
	Parameters.Insert("TableName", TableName);
	Parameters.Insert("SourceMethodOfDistributionOfCostsForOutputProducts", SourceMethodOfDistributionOfCostsForOutputProducts);
	
	Parameters.Insert("CostShare",           "&CostShare");               // "%of the cost%"
	Parameters.Insert("CostSharePerUnit",  "&CostSharePerUnit");      // "%share of the unit%"
	Parameters.Insert("CompoundShareCost", "," + "CompoundShareCost");// "%of the connection of the cost%"
	
	Parameters.Insert("SourceProduct",     TableName + ".Products");
	Parameters.Insert("SourceCharacteristics",   TableName + ".Characteristic");
	Parameters.Insert("SourcePackaging",         TableName + ".Package");
	Parameters.Insert("SourceUnitOfMeasurement", TableName + ".Products.UnitOfMeasure");
	Parameters.Insert("SourceQuantity",       TableName + ".Count");
	Parameters.Insert("SourceCostShare",    TableName + ".CostShare");
	
	If UsePriceManagementSystem25 = Undefined Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	EndIf;
	
	If UsePriceManagementSystem25 Then
		Parameters.Insert("SourceCharacteristicsOfTSO", TableName + ".PricingVariant");
		Parameters.Insert("SourceTSOSeries",          TableName + ".PricingBatch");
		Parameters.Insert("SourcePackagingTSO",       TableName + ".PricingPackage");
	EndIf;
	
	Parameters.Insert("QueryTextFilterRemainingGoodsByShelfLives", QueryTextFilterRemainingGoodsByShelfLives);
	Parameters.Insert("QueryTextFilterCostsAllocationMethod", "&MethodOfAllocatingFinishedProductCosts = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost)");
	Parameters.Insert("Date", "&Date");
	
	Return Parameters;
	
EndFunction

Procedure PerformSubstitutionOfCostFractionCalculationAlgorithm(QueryText, Substitution, UsePriceManagementSystem25 = False) Export
	
	Template = "
	|CASE
	|	
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost)
	|	
	|		THEN CAST(ISNULL(ISNULL(PlannedPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1), 0) * CASE
	|				WHEN &Currency <> PlannedPrices.Currency
	|				THEN CASE
	|						WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|							AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|						THEN 
	|							(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|							/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|						ELSE 0
	|					END
	|				ELSE 1
	|			END * &SourceQuantity AS NUMBER(31,2))
	|	
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByVolume)
	|	
	|		THEN &VolumeM3 * &SourceQuantity
	|	
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByWeight)
	|	
	|		THEN &Weight * &SourceQuantity
	|	
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares)
	|	
	|		THEN &SourceCostShare
	|
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByCount)
	|	
	|		THEN &SourceQuantity
	|	
	|	ELSE 0
	|	
	|END
	|;
	|CASE
	|
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost)
	|	
	|		THEN ISNULL(ISNULL(PlannedPrices.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) * CASE
	|				WHEN &Currency <> PlannedPrices.Currency
	|					THEN CASE
	|							WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|								AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN 
	|								(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|								/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|							ELSE 0
	|						END
	|				ELSE 1
	|			END, 0)
	|	
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByVolume)
	|	
	|		THEN &VolumeM3
	|	
	|	WHEN &Parameter = VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByWeight)
	|	
	|		THEN &Weight
	|	
	|	ELSE 0
	|
	|END
	|;
	|";
	
	If UsePriceManagementSystem25 Then
		Template = Template + "LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&DATE, DAY),
		|		PriceKind = &PriceKind
		|		AND &QueryTextFilterRemainingGoodsByShelfLives
		|		AND &QueryTextFilterCostsAllocationMethod
		|) AS PlannedPrices
		|ON &SourceProduct   = PlannedPrices.Products
		| AND &SourceCharacteristicsOfTSO = PlannedPrices.PricingVariant
		| AND &PricingBatch = PlannedPrices.PricingBatch
		| AND &PricingPackage = PlannedPrices.PricingPackage
		|
		|";
	Else
		Template = Template + "LEFT JOIN InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&DATE, DAY),
		|		PriceKind = &PriceKind
		|		AND &QueryTextFilterRemainingGoodsByShelfLives
		|		AND &QueryTextFilterCostsAllocationMethod
		|) AS PlannedPrices
		|ON &SourceProduct   = PlannedPrices.Products
		| AND &SourceCharacteristics = PlannedPrices.Characteristic
		|
		|";
	EndIf;
	
	Template = Template + "LEFT JOIN
	|	InformationRegister.RelativeExchangeRates.SliceLast(&DATE, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|ON 
	|	PlannedPrices.Currency = CurrencyRatesPrices.Currency
	|	
	|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DATE, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON TRUE
	|";
	
	
	Template = StrReplace(Template, "&Parameter", Substitution.SourceMethodOfDistributionOfCostsForOutputProducts);
	
	Template = StrReplace(Template, "&Weight",                 Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("&SourceUnitOfMeasurement", "&SourceProduct"));
	Template = StrReplace(Template, "&VolumeM3",               Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("&SourceUnitOfMeasurement", "&SourceProduct"));
	Template = StrReplace(Template, "&QueryTextPackagingFactor1", Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PlannedPrices.Package", "PlannedPrices.Products"));
	
	Template = StrReplace(Template, "&Date",                Substitution.Date);
	If UsePriceManagementSystem25 Then
		Template = StrReplace(Template, "&SourceCharacteristicsOfTSO", Substitution.SourceCharacteristicsOfTSO);
		Template = StrReplace(Template, "&PricingBatch",                  Substitution.SourceTSOSeries);
		Template = StrReplace(Template, "&PricingPackage",               Substitution.SourcePackagingTSO);
	EndIf;
	
	Template = StrReplace(Template, "&SourceProduct",     Substitution.SourceProduct);
	Template = StrReplace(Template, "&SourceCharacteristics",   Substitution.SourceCharacteristics);
	Template = StrReplace(Template, "&SourcePackaging",         Substitution.SourcePackaging);
	Template = StrReplace(Template, "&SourceUnitOfMeasurement", Substitution.SourceUnitOfMeasurement);
	Template = StrReplace(Template, "&SourceQuantity",       Substitution.SourceQuantity);
	Template = StrReplace(Template, "&SourceCostShare",    Substitution.SourceCostShare);
	
	If ValueIsFilled(Substitution.QueryTextFilterRemainingGoodsByShelfLives) Then
		Template = StrReplace(Template, "&QueryTextFilterRemainingGoodsByShelfLives", Substitution.QueryTextFilterRemainingGoodsByShelfLives);
	Else
		Template = StrReplace(Template, "&QueryTextFilterRemainingGoodsByShelfLives", "TRUE");
	EndIf;
	If Substitution.SourceMethodOfDistributionOfCostsForOutputProducts = "&MethodOfAllocatingFinishedProductCosts" Then
		Template = StrReplace(Template, "&QueryTextFilterCostsAllocationMethod", Substitution.QueryTextFilterCostsAllocationMethod);
	Else
		Template = StrReplace(Template, "&QueryTextFilterCostsAllocationMethod", "TRUE");
	EndIf;
	
	Templates = StrSplit(Template,";");
	
	QueryText = StrReplace(QueryText, Substitution.CompoundShareCost, Templates[2]);
	QueryText = StrReplace(QueryText, Substitution.CostSharePerUnit,  Templates[1]);
	QueryText = StrReplace(QueryText, Substitution.CostShare,           Templates[0]);
	
EndProcedure

Procedure SubstituteTextOfAutoCalculationRequestForAnyCharacteristic(QueryText, CostAllocationParameters, UsePriceManagementSystem25)
	
	If Not CostAllocationParameters.AutoCalculationOfAnyCharacteristic Then
		Return;
	EndIf;
	
	If Not CostAllocationParameters.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByTargetCost Then
		Return;
	EndIf;
	
	If UsePriceManagementSystem25 Then
		QueryText = StrReplace(QueryText, "TabularSection", "TabularPartForAutoCalculation") + 
		"SELECT
		|	ItemsPrices.Products AS Products,
		|	MAX(ItemsPrices.PricingVariant) AS PricingVariant
		|INTO TTAutoFeedingFeatures
		|FROM
		|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY)
		|			,
		|			PriceKind = &PriceKind
		|				AND Products IN
		|					(SELECT
		|						Filter.Products
		|					FROM
		|						TabularPartForAutoCalculation AS Filter)) AS ItemsPrices
		|
		|GROUP BY
		|	ItemsPrices.Products
		|;
		|	
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TabularSection.LineNumber        AS LineNumber,
		|
		|	TabularSection.Products       AS Products,
		|	TabularSection.Characteristic     AS Characteristic,
		|	CASE
		|		WHEN TabularSection.Products.UseVariants IN (
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|			) THEN
		|			ISNULL(AutoFeedingFeatures.PricingVariant, TabularSection.PricingVariant)
		|		ELSE
		|			VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|	END                             AS PricingVariant,
		|	TabularSection.PricingBatch           AS PricingBatch,
		|	TabularSection.PricingPackage         AS PricingPackage,
		|
		|	TabularSection.Package           AS Package,
		|	TabularSection.NumberOfPackages AS NumberOfPackages,
		|	TabularSection.Count         AS Count,
		|
		|	TabularSection.CostShare AS CostShare
		|
		|INTO TabularSection
		|FROM
		|	TabularPartForAutoCalculation AS TabularSection
		|
		|		LEFT JOIN TTAutoFeedingFeatures AS AutoFeedingFeatures
		|		ON TabularSection.Products = AutoFeedingFeatures.Products
		|			AND (TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|;
		|";
	Else
		QueryText = StrReplace(QueryText, "TabularSection", "TabularPartForAutoCalculation") + 
		"SELECT
		|	ItemsPrices.Products AS Products,
		|	MAX(ItemsPrices.Characteristic) AS Characteristic
		|INTO TTAutoFeedingFeatures
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&Date, DAY)
		|			,
		|			PriceKind = &PriceKind
		|				AND Products IN
		|					(SELECT
		|						Filter.Products
		|					FROM
		|						TabularPartForAutoCalculation AS Filter)) AS ItemsPrices
		|
		|GROUP BY
		|	ItemsPrices.Products
		|;
		|	
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TabularSection.LineNumber        AS LineNumber,
		|
		|	TabularSection.Products       AS Products,
		|	CASE
		|		WHEN TabularSection.Products.UseVariants IN (
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
		|			) THEN
		|			ISNULL(AutoFeedingFeatures.Characteristic, TabularSection.Characteristic)
		|		ELSE
		|			VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|	END                             AS Characteristic,
		|
		|	TabularSection.Package           AS Package,
		|	TabularSection.NumberOfPackages AS NumberOfPackages,
		|	TabularSection.Count         AS Count,
		|
		|	TabularSection.CostShare AS CostShare
		|
		|INTO TabularSection
		|FROM
		|	TabularPartForAutoCalculation AS TabularSection
		|
		|		LEFT JOIN TTAutoFeedingFeatures AS AutoFeedingFeatures
		|		ON TabularSection.Products = AutoFeedingFeatures.Products
		|			AND (TabularSection.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|;
		|";
	EndIf;
	
EndProcedure

Function TotalCostSharesByGrouping(TabularSection, CostAllocationParameters, Groups = "") Export
	
	Result = New Map;
	PropertiesOfDimensions = New Map;
	
	LinkFields = StrSplit(CostAllocationParameters.LinkFields, ",");
	
	For Each String In TabularSection Do
		
		If CostAllocationParameters.CostGroupingField <> "" Then
			Group = String[CostAllocationParameters.CostGroupingField];
		Else
			Group = "";
		EndIf;
		
		If CostAllocationParameters.ThereIsFieldCanceled And String.Canceled Then
			
			Totals = Result[Group];
			If Totals = Undefined Then
				
				Totals = New Structure();
				
				Totals.Insert("Count", 0);
				Totals.Insert("CostShare", 0);
				Totals.Insert("CostShareRequired_", False);
				Totals.Insert("ShareOfCostIsCalculated", False);
				Totals.Insert("ParameterizationIsUsed", False);
				Totals.Insert("NumberOfRowsInGrouping", 0);
				
				Result.Insert(Group, Totals);
				
			EndIf;
			
			Continue;
			
		EndIf;
		
		If CostAllocationParameters.CostGroupingField <> ""
			And Groups <> Undefined
			And Groups.Find(Group) = Undefined Then
			Continue;
		EndIf;
		
		ParameterizationIsUsed = CostAllocationParameters.ThereIsParameterizationOfResourceSpecification
			And (String.MethodOfProductsAutoselection <> Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
				Or String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData
				Or String.CalculationByFormula);
		
		ShareOfCostIsCalculated = ProductionClientServer.ShareOfCostIsCalculated(String, CostAllocationParameters);
		Totals = Result[Group];
		
		If Totals = Undefined Then
			
			Totals = New Structure();
			Totals.Insert("Count", String.Count);
			Totals.Insert("CostShare", String.CostShare);
			Totals.Insert("CostShareRequired_", ShareOfCostIsCalculated
				And Not CostAllocationParameters.SetShareOfCostIsRequiredByDefault);
			Totals.Insert("ShareOfCostIsCalculated", ShareOfCostIsCalculated);
			Totals.Insert("ParameterizationIsUsed", ParameterizationIsUsed);
			Totals.Insert("NumberOfRowsInGrouping", 1);
			
			If ValueIsFilled(CostAllocationParameters.ShareOfCostOfOtherDocumentsInGrouping) Then
				CostShare = CostAllocationParameters.ShareOfCostOfOtherDocumentsInGrouping;
				If ValueIsFilled(CostShare) Then
					Totals.CostShareRequired_ = True;
					Totals.CostShare = Totals.CostShare + CostShare;
				EndIf;
			EndIf;
			
			Result.Insert(Group, Totals);
			
		Else
			Totals.Count = Totals.Count + String.Count;
			Totals.CostShare = Totals.CostShare + String.CostShare;
			Totals.ParameterizationIsUsed = Max(Totals.ParameterizationIsUsed, ParameterizationIsUsed);
			Totals.NumberOfRowsInGrouping = Totals.NumberOfRowsInGrouping + 1;
		EndIf;
		
		If Not Totals.CostShareRequired_ Then
			If Totals.CostShare <> 0 Then
				Totals.CostShareRequired_ = True;
			ElsIf Totals.ParameterizationIsUsed And Totals.NumberOfRowsInGrouping > 1 Then
				Totals.CostShareRequired_ = True;
			Else
				If PropertiesOfDimensions[Group] <> Undefined Then
					For Each Field In LinkFields Do
						If String[Field] <> PropertiesOfDimensions[Group][Field] Then
							Totals.CostShareRequired_ = True;
							Break;
						EndIf;
					EndDo;
				Else
					RowData = New Structure(CostAllocationParameters.LinkFields);
					FillPropertyValues(RowData, String);
					PropertiesOfDimensions.Insert(Group, RowData);
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure FillInIfThereAreErrorsInFillingInCostFraction(String, Totals, Canceled, CostAllocationParameters)
	
	String.ThereAreErrorsOfFillingInCostShare = False;
	
	CalculationByFormula = (CostAllocationParameters.ThereIsParameterizationOfResourceSpecification And String.CalculationByFormula);
	
	AutoSelection = CostAllocationParameters.ThereIsParameterizationOfResourceSpecification And 
		(String.MethodOfProductsAutoselection <> Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
			Or String.MethodOfItemVariantAutoselection <> Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData);
	
	If Canceled Or String.CostShare > 0 Then
		Return;
	EndIf;
	
	If AutoSelection And Totals.ShareOfCostIsCalculated Then
		Return;
	EndIf;
	
	If CalculationByFormula And String.CostSharePerUnit > 0 And Totals.ShareOfCostIsCalculated Then
		Return;
	EndIf;
	
	If Totals.CostShareRequired_ Or String.Count = 0 And CalculationByFormula = False Then
		String.ThereAreErrorsOfFillingInCostShare = True;
	EndIf;
	
EndProcedure

Function NamesOfCostShareElements(Placement)

	ReturnValue = New Structure("CostShare, CostSharePercentage, ThereAreErrorsOfFillingInCostShare");
	
	If Placement = "ManufacturedProduct" Then
		ReturnValue.CostShare = "ManufacturedProductCostShare";
		ReturnValue.CostSharePercentage = "ManufacturedProductCostSharePercentage";
		ReturnValue.ThereAreErrorsOfFillingInCostShare = "ManufacturedProductThereAreErrorsOfFillingInCostShare";
	ElsIf Placement = "ManufacturedProducts" Then
		ReturnValue.CostShare = "ManufacturedProductsCostShare";
		ReturnValue.CostSharePercentage = "ManufacturedProductsCostSharePercentage";
		ReturnValue.ThereAreErrorsOfFillingInCostShare = "ManufacturedProductsThereAreErrorsOfFillingInCostShare";
	ElsIf Placement = "SideAndIntermediateRelease" Then
		ReturnValue.CostShare = "ByProductsShareOfValue";
		ReturnValue.CostSharePercentage = "ByProductsShareOfValuePercentage";
		ReturnValue.ThereAreErrorsOfFillingInCostShare = "ByProductsHaveErrorsFillingFractionOfCost";
	ElsIf Placement = "EditStagesFinishedProducts" Then
		ReturnValue.CostShare = "EditingStagesManufacturedProductsCostShare";
		ReturnValue.CostSharePercentage = "EditingStagesManufacturedProductsCostSharePercentage";
		ReturnValue.ThereAreErrorsOfFillingInCostShare = "EditingStagesManufacturedProductsThereAreErrorsOfFillingInCostShare";
	ElsIf Placement = "Lots" Then
		ReturnValue.CostShare = "LotsCostShare";
		ReturnValue.CostSharePercentage = "LotsCostSharePercentage";
		ReturnValue.ThereAreErrorsOfFillingInCostShare = "LotsThereAreErrorsOfFillingInCostShare";
	ElsIf Placement = "Goods" Then
		ReturnValue.CostShare = "GoodsCostShare";
		ReturnValue.CostSharePercentage = "GoodsCostSharePercentage";
		ReturnValue.ThereAreErrorsOfFillingInCostShare = "GoodsThereAreErrorsOfFillingInCostShare";
	Else
		Raise NStr("vi = 'Giá trị thông số hàm không hợp lệ';
					|ru = 'Недопустимое значение параметра функции';
					|en = 'Invalid function parameter value'; fa = 'Invalid function parameter value';
					|it = 'Valore non valido del parametro della funzione';
					|pl = 'Niedopuszczalna wartość parametru funkcji';
					|tr = 'Fonksiyon parametresinin geçersiz değeri'");
	EndIf;
	Return ReturnValue

EndFunction

#EndRegion

#Region DynamicListSelection

// Adds a selection to the selection array.
//
// Parameters:
//  FiltersList - Array of Structure - Contains:
//                             * Name          - String -
//                             * QueryText - String -
//                             * Parameters    - Structure, Arbitrary -
//                             * Use - Boolean -
//                             * Operation     - String -
//  Name          - String -
//  QueryText - String -
//  Parameters    - Structure, Arbitrary -
//  Use - Boolean -
//  Operation     - String -
//
Procedure AddSelectionToSelectionList(FiltersList, Name, QueryText, Parameters = Undefined, Use = True, Operation = "LinkInList") Export
	
	Filter = New Structure;
	
	Filter.Insert("Name", Name);
	Filter.Insert("QueryText", QueryText);
	Filter.Insert("Parameters", Parameters);
	Filter.Insert("Use", Use);
	Filter.Insert("Operation", Operation);
	
	FiltersList.Add(Filter);
	
EndProcedure

Procedure SubstitutingSelectionsInDynamicListQueryText(QueryText, FiltersList, TableName = "MainTable") Export
	
	If Not ValueIsFilled(FiltersList) Then
		Return;
	EndIf;
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	
	DataSamplingPackage = QuerySchema.QueryBatch.Count()-1;
	Filters = QuerySchema.QueryBatch[DataSamplingPackage].Operators[0].Filter;
	
	For Each Filter In FiltersList Do
		
		If Not Filter.Use Then
			Continue;
		EndIf;
		
		If Filter.Operation = "LinkInList" Then
			
			FilterText1 = StrTemplate("(%1.Ref) In
				|(
				|	%2
				|)",
				TableName,
				Filter.QueryText);
			
		ElsIf Filter.Operation = "LinkIsNotInList" Then
			
			FilterText1 = StrTemplate("NOT (%1.Ref) IN
				|(
				|	%2
				|)",
				TableName,
				Filter.QueryText);
			
		Else
			Raise NStr("vi = 'Chuyển hoạt động lựa chọn không tồn tại!';
						|ru = 'Передана несуществующая операция отбора!';
						|en = 'Non-existing filter operation is transferred.'; fa = 'Non-existing filter operation is transferred.';
						|it = 'È stata passata un''operazione di selezione inesistente!';
						|pl = 'Nieistniejąca operacja wyboru została przeniesiona!';
						|tr = 'Var olmayan bir filtre işlemi aktarıldı!'", CommonClientServer.DefaultLanguageCode());
		EndIf;
		
		FilterText1 = StrReplace(FilterText1, "&Ref", TableName + ".Ref");
		Filters.Add(FilterText1);
		
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	
EndProcedure

// Sets parameters for selecting a dynamic list.
//
// Parameters:
//  List - DynamicList - dynamic list being processed.
//  FiltersList - Array of Structure - Contains:
//                             * Name          - String -
//                             * QueryText - String -
//                             * Parameters    - Structure, Arbitrary -
//                             * Use - Boolean -
//                             * Operation     - String -
//
Procedure SetDynamicListSelectionParameters(List, FiltersList) Export
	
	For Each Filter In FiltersList Do
		
		If Not Filter.Use Then
			Continue;
		EndIf;
		
		If TypeOf(Filter.Parameters) = Type("Structure") Then
			
			For Each Parameter In Filter.Parameters Do
				
				CommonClientServer.SetDynamicListParameter(
					List,
					Parameter.Key,
					Parameter.Value);
				
			EndDo;
			
		Else
			
			CommonClientServer.SetDynamicListParameter(
				List,
				Filter.Name,
				Filter.Parameters);
			
		EndIf;
		
	EndDo;
	
	
EndProcedure

#EndRegion

#Region EventLogEvents

Function EventCalculationOfNormativeDuration() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Danh mục sản xuất';
								|ru = 'НСИ производства';
								|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
								|it = 'Informazioni Normative di Riferimento di produzione';
								|pl = 'Informacja normatywno-pomocnicza produkcji';
								|tr = 'Üretim master verisi'", LanguageCode),
						 NStr("vi = 'Tính thời lượng chuẩn';
								|ru = 'Расчет нормативной длительности';
								|en = 'Standard duration calculation'; fa = 'Standard duration calculation';
								|it = 'Calcolo della durata standard';
								|pl = 'Obliczenie działalności normatywnej';
								|tr = 'Standart sürenin hesaplanması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function CreateSpecificationEvent() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Danh mục sản xuất';
								|ru = 'НСИ производства';
								|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
								|it = 'Informazioni Normative e di Rferimento della produzione';
								|pl = 'Informacja normatywno-pomocnicza produkcji';
								|tr = 'Üretim master verisi'", LanguageCode),
						 NStr("vi = 'Tạo bảng kê chi tiết';
								|ru = 'Создание спецификации';
								|en = 'Generate bill of materials'; fa = 'Generate bill of materials';
								|it = 'Creazione specifiche';
								|pl = 'Utworzenie specyfikacji';
								|tr = 'Ürün reçetesinin oluşturulması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function CopySpecificationEvent() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Danh mục sản xuất';
								|ru = 'НСИ производства';
								|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
								|it = 'Informazioni Normative e di Rferimento della produzione';
								|pl = 'Informacja normatywno-pomocnicza produkcji';
								|tr = 'Üretim master verisi'", LanguageCode),
						 NStr("vi = 'Sao chép bảng kê chi tiết';
								|ru = 'Копирование спецификации';
								|en = 'Copy the bill of materials'; fa = 'Copy the bill of materials';
								|it = 'Copia specifiche';
								|pl = 'Kopiowanie specyfikacji';
								|tr = 'Ürün reçetesinin kopyalanması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventReplacementOfSpecifications() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Quản lý liên xưởng';
								|ru = 'Межцеховое управление';
								|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
								|it = 'Gestione interna dei reparti';
								|pl = 'Zarządzanie międzyresortowe';
								|tr = 'Üretim planlama ve kontrolü'", LanguageCode),
						 NStr("vi = 'Thay thế bảng kê chi tiết';
								|ru = 'Замена спецификаций';
								|en = 'Bills of materials replacement'; fa = 'Bills of materials replacement';
								|it = 'Sostituzione specifiche';
								|pl = 'Zamiana specyfikacji';
								|tr = 'Ürün reçetesi değişimi'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventProductionSchedulePlanning() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Quản lý liên xưởng';
								|ru = 'Межцеховое управление';
								|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
								|it = 'Gestione interna dei reparti';
								|pl = 'Zarządzanie międzyresortowe';
								|tr = 'Üretim planlama ve kontrolü'", LanguageCode),
						 NStr("vi = 'Lập kế hoạch sản xuất';
								|ru = 'Планирование графика производства';
								|en = 'Production schedule creating'; fa = 'Production schedule creating';
								|it = 'Programmazione del piano di produzione';
								|pl = 'Planowanie harmonogramu produkcji';
								|tr = 'Üretim programını planlama'", LanguageCode));
	
	Return Event;
		
EndFunction

Function EventEditingStageChain() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Quản lý liên xưởng';
								|ru = 'Межцеховое управление';
								|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
								|it = 'Gestione interna dei reparti';
								|pl = 'Zarządzanie międzyresortowe';
								|tr = 'Üretim planlama ve kontrolü'", LanguageCode),
						 NStr("vi = 'Soạn vòng lặp công đoạn';
								|ru = 'Редактирование цепочки этапов';
								|en = 'Stage chain editing'; fa = 'Stage chain editing';
								|it = 'Modifica della catena di fasi';
								|pl = 'Edycja łańcuchów etapów';
								|tr = 'Aşama zincirinin düzenlenmesi'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventSendingStagesToExecution() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Quản lý liên xưởng';
								|ru = 'Межцеховое управление';
								|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
								|it = 'Gestione interna dei reparti';
								|pl = 'Zarządzanie międzyresortowe';
								|tr = 'Üretim planlama ve kontrolü'", LanguageCode),
						 NStr("vi = 'Chuyển các công đoạn để hoàn thành';
								|ru = 'Передача этапов к выполнению';
								|en = 'Release stages'; fa = 'ترخیص مراحل';
								|it = 'Trasferimento delle fasi in esecuzione';
								|pl = 'Przekazanie etapów do wykonania';
								|tr = 'Aşamaların gerçekleştirmeye transferi'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventMarkingForDeletingStages() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Quản lý liên xưởng';
								|ru = 'Межцеховое управление';
								|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
								|it = 'Gestione interna dei reparti';
								|pl = 'Zarządzanie międzyresortowe';
								|tr = 'Üretim planlama ve kontrolü'", LanguageCode),
						 NStr("vi = 'Đánh dấu việc loại bỏ các công đoạn sản xuất';
								|ru = 'Пометка на удаление этапов производства';
								|en = 'Production stage deletion mark'; fa = 'Production stage deletion mark';
								|it = 'Contrassegno di eliminazione delle fasi di produzione';
								|pl = 'Zaznaczenie do usuwania etapów produkcji';
								|tr = 'Üretim aşamalarının silinmesine yönelik işaret'", LanguageCode));
	
	Return Event;
	
EndFunction

Function ProductionQueueCalculationEvent() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Quản lý xưởng';
								|ru = 'Внутрицеховое управление';
								|en = 'Shop management'; fa = 'مدیریت کارگاه';
								|it = 'Gestione interna del reparto';
								|pl = 'Zarządzanie procesom produkcyjnym ';
								|tr = 'Üretim atölyesi yönetimi'", LanguageCode),
						 NStr("vi = 'Tạo trình tự giao dịch sản xuất';
								|ru = 'Формирование очереди производственных операций';
								|en = 'Generating routing operation queue'; fa = 'Generating routing operation queue';
								|it = 'Creazione della coda di operazioni di produzione';
								|pl = 'Formowanie kolei operacji produkcyjnych';
								|tr = 'Rota işlemi kuyruğunun oluşturulması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventCompletionOfStagesForProductionOperations() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Quản lý xưởng';
								|ru = 'Внутрицеховое управление';
								|en = 'Shop management'; fa = 'مدیریت کارگاه';
								|it = 'Gestione interna del reparto';
								|pl = 'Zarządzanie procesom produkcyjnym ';
								|tr = 'Üretim atölyesi yönetimi'", LanguageCode),
						 NStr("vi = 'Điền các công đoạn theo hoạt động sản xuất';
								|ru = 'Заполнение этапов по производственным операциям';
								|en = 'Filling in stages according to routing operations'; fa = 'Filling in stages according to routing operations';
								|it = 'Esecuzione delle fasi per operazioni di produzione';
								|pl = 'Wypełnienie etapów wg operacji produkcyjnych';
								|tr = 'Rota işlemlerine göre aşamaların doldurulması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventCalculatingPropertyValueDuringAutoSelection() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Danh mục sản xuất';
								|ru = 'НСИ производства';
								|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
								|it = 'Informazioni Normative e di Rferimento della produzione';
								|pl = 'Informacja normatywno-pomocnicza produkcji';
								|tr = 'Üretim master verisi'", LanguageCode),
						 NStr("vi = 'Tính giá trị thuộc tính khi tự động chọn';
								|ru = 'Расчет значения свойства при автовыборе';
								|en = 'Calculating property value on autoselect'; fa = 'Calculating property value on autoselect';
								|it = 'Calcolo dei valori delle proprietà durante la selezione automatica';
								|pl = 'Obliczenie wartości właściwości podczas wyboru automatycznego';
								|tr = 'Otomatik seçimde özellik değerinin hesaplanması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function AutoselectFeatureEventByAlgorithm() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Danh mục sản xuất';
								|ru = 'НСИ производства';
								|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
								|it = 'Informazioni Normative e di Rferimento della produzione';
								|pl = 'Informacja normatywno-pomocnicza produkcji';
								|tr = 'Üretim master verisi'", LanguageCode),
						 NStr("vi = 'Tự động chọn đặc tính theo thuật toán';
								|ru = 'Автовыбор характеристики по алгоритму';
								|en = 'Automatic selection of variant as per algorithm'; fa = 'Automatic selection of variant as per algorithm';
								|it = 'Selezione automatica della caratteristica in base all''algoritmo';
								|pl = 'Wybór automatyczny charakterystyki wg algorytmu';
								|tr = 'Algoritmaya göre otomatik varyant seçimi'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventCalculationOfQuantityByFormula() Export
	
	LanguageCode = Common.DefaultLanguageCode();
	
	Event  = StrTemplate("%1.%2",
						 NStr("vi = 'Danh mục sản xuất';
								|ru = 'НСИ производства';
								|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
								|it = 'Informazioni Normative e di Rferimento della produzione';
								|pl = 'Informacja normatywno-pomocnicza produkcji';
								|tr = 'Üretim master verisi'", LanguageCode),
						 NStr("vi = 'Tính số lượng theo công thức';
								|ru = 'Расчет количества по формуле';
								|en = 'Calculating quantity using the formula'; fa = 'Calculating quantity using the formula';
								|it = 'Calcolo quantità per formula';
								|pl = 'Obliczenie ilości wg formuły';
								|tr = 'Formüle göre miktarın hesaplanması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function EventCalculationOfDurationBeforeReleaseByStagesOfProduction() Export

	LanguageCode = Common.DefaultLanguageCode();
	
	Event = StrTemplate("%1.%2",
					 NStr("vi = 'Quản lý liên xưởng';
							|ru = 'Межцеховое управление';
							|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
							|it = 'Gestione interna dei reparti';
							|pl = 'Zarządzanie międzyresortowe';
							|tr = 'Üretim planlama ve kontrolü'", LanguageCode),
					 NStr("vi = 'Tính thời lượng trước khi xuất xưởng theo các công đoạn sản xuất';
							|ru = 'Расчет длительности до выпуска по этапам производства';
							|en = 'Calculation of the duration before release by production stages'; fa = 'Calculation of the duration before release by production stages';
							|it = 'Calcolo della durata dall''avvio per fasi di produzione';
							|pl = 'Obliczenie czasu trwania przed wyprodukowaniem według etapów produkcji';
							|tr = 'Üretim aşamalarına göre ürün çıkışı öncesindeki sürenin hesaplanması'", LanguageCode));
	
	Return Event;
	
EndFunction

Function TaskQueueProcessingEvent() Export
	
	Return NStr("vi = 'Xử lý hàng đợi công việc';
				|ru = 'Обработка очереди заданий';
				|en = 'Job queue processing'; fa = 'Job queue processing';
				|it = 'Elaborazione di fila task';
				|pl = 'Przetwarzanie kolejki zadań';
				|tr = 'Görev kuyruğunun işlenmesi'", CommonClientServer.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region Table

// Returns the structure of fields for uploading and filling in the table.
//
// Returns:
// 	Structure - contains fields:
//		* MainField		  - String 	  - the main fields of the table separated by commas
//		* AdditionalFields  - Structure - structure of additional fields-key: name field 
//																			 value: type description
//		* SpoofFields     - Structure - structure of substituted fields-kluya: name of the field to fill
//																		  in value: name field data source to fill in
//		* DefaultValues - Structure - structure of default values key: the name of the field
//																			  value: the value field
// 
Function TableFieldStructure() Export
	
	FieldsStructure = New Structure;
	FieldsStructure.Insert("MainField", "");
	FieldsStructure.Insert("AdditionalFields", New Structure);
	FieldsStructure.Insert("SpoofFields", New Structure);
	FieldsStructure.Insert("DefaultValues", New Structure);
	
	Return FieldsStructure;
	
EndFunction

// Returns the address of the temporary storage of the value table created based on data from table rows
//
// Parameters:
// 	Form                 - ClientApplicationForm 		- form with a table with selected rows
// 	ObjectName            - String           		- name of the table owner object
// 	TableName            - String           		- table name
// 	SelectedRows      - Boolean           		- Truth: selected lines only
//                                           		  False: all lines
// 	TableFieldStructure - See ProductionServer.TableFieldStructure
//	RowFilter            - Structure, Undefined - key: the name of the prop table
//													  value: array of values of the props table for the selection
//
// Returns:
// 	String - the address of the temporary storage of the table value 
// 
Function PlaceStringDataInTemporaryStorage(
			Form, ObjectName, TableName, SelectedRows, TableFieldStructure, RowFilter = Undefined) Export
	
	DataTable = Form[ObjectName][TableName];
	
	MainField = TableFieldStructure.MainField;
	AdditionalFields = TableFieldStructure.AdditionalFields;
	SpoofFields = TableFieldStructure.SpoofFields;
	DefaultValues = TableFieldStructure.DefaultValues;
	
	Table = ?(TypeOf(DataTable) = Type("ValueTable"),	
					DataTable.CopyColumns(MainField),	DataTable.Unload(New Array, MainField));
	
	If AdditionalFields <> Undefined Then
		For Each AdditionalField In AdditionalFields Do
			Table.Columns.Add(AdditionalField.Key, AdditionalField.Value);	
		EndDo;	
	EndIf;	
	
	RowsData = ?(SelectedRows, Form.Items[TableName].SelectedRows, DataTable);
	For Each DataString1 In RowsData Do
		
		CurrentRow = ?(SelectedRows, DataTable.FindByID(DataString1), DataString1);
		
		If RowFilter <> Undefined Then
			
			CancelStringProcessing = False;
			
			For Each FilterElement In RowFilter Do
				If FilterElement.Value.Find(CurrentRow[FilterElement.Key]) = Undefined Then
					CancelStringProcessing = True;
					Break;
				EndIf;	
			EndDo;
			
			If CancelStringProcessing Then
				Continue;
			EndIf;	
			
		EndIf;	
		
		TableRow = Table.Add();
		FillPropertyValues(TableRow, CurrentRow);
		
		For Each FieldToReplace_ In SpoofFields Do
			TableRow[FieldToReplace_.Key] = CurrentRow[FieldToReplace_.Value];	
		EndDo;	
		
		If DefaultValues <> Undefined Then
			For Each DefaultValue In DefaultValues Do
				If Not ValueIsFilled(TableRow[DefaultValue.Key]) Then
					TableRow[DefaultValue.Key] = DefaultValue.Value;	
				EndIf;
			EndDo;
		EndIf;	
		
	EndDo;
	
	Return PutToTempStorage(Table, Form.UUID);
	
EndFunction	

// Collapses the value table with the ability to preserve the order of rows
// In cases where the summation Column parameter is not specified, all numeric columns are included in the summation columns.
// The numeric columns that should be included in the grouping columns should be listed in the grouping Columns parameter.
// You don't need to list non-numeric columns in the grouping Column.
// When you save the order of rows, columns that are not included in the collapse are not deleted and remain filled
// in with the value of the first row found in the column section of the grouping
// 
// Parameters:
//  Table			    - ValueTable              - Collapse table
//  GroupingColumns  - String, Array, Undefined - Column groupings of the table
//  TotalingColumns - String, Array, Undefined - Table collapse columns
//  SaveOrder_    - Boolean                       - Indicates whether the order of rows is preserved
//
Procedure CollapseValueTable(Table, Val GroupingColumns = Undefined, Val TotalingColumns = Undefined, SaveOrder_ = False) Export
	
	If TotalingColumns = Undefined Then
		
		If GroupingColumns = Undefined Then
			GroupingColumns = New Array;
		ElsIf TypeOf(GroupingColumns) = Type("String") Then
			GroupingColumns = StrSplit(GroupingColumns, ",", False);
		EndIf;
		
		TotalingColumns = New Array;
		
		For Each Column In Table.Columns Do
			If TypeOf(Column.ValueType.AdjustValue()) = Type("Number") Then
				If GroupingColumns.Find(Column.Name) = Undefined Then
					TotalingColumns.Add(Column.Name);
				EndIf;
			Else
				GroupingColumns.Add(Column.Name);	
			EndIf;
		EndDo;	
		
		GroupingColumns  = StrConcat(GroupingColumns , ",");
		TotalingColumns = StrConcat(TotalingColumns, ",");
		
	ElsIf GroupingColumns = Undefined Then	
		
		If TypeOf(TotalingColumns) = Type("String") Then
			TotalingColumns = StrSplit(TotalingColumns, ",", False);
		EndIf;
		
		GroupingColumns = New Array;
		
		For Each Column In Table.Columns Do
			If TotalingColumns.Find(Column.Name) = Undefined Then
				GroupingColumns.Add(Column.Name);
			EndIf;	
		EndDo;
		
		GroupingColumns  = StrConcat(GroupingColumns , ",");
		TotalingColumns = StrConcat(TotalingColumns, ",");
		
	Else	
		
		If TypeOf(GroupingColumns) = Type("Array") Then
			GroupingColumns = StrConcat(GroupingColumns, ",");	
		EndIf;	
		
		If TypeOf(TotalingColumns) = Type("Array") Then
			TotalingColumns = StrConcat(TotalingColumns, ",");	
		EndIf;	
		
	EndIf;
	
	
	If SaveOrder_ Then
		
		ArrayOfSummationColumns = StrSplit(TotalingColumns, ",");
		
		Table.Indexes.Add(GroupingColumns);
		
		RowIndex    = 0;
		RowsCount = Table.Count();
		FilterStructure1 = New Structure(GroupingColumns);
		
		While RowsCount > 0 Do
			
			DimensionString = Table[RowIndex];
			FillPropertyValues(FilterStructure1, DimensionString);
			
			RowsArray = Table.FindRows(FilterStructure1);
			IndexOfFoundString = RowsArray.UBound();
			While IndexOfFoundString > 0 Do
				
				FoundRow = RowsArray[IndexOfFoundString];
				
				For Each SummationColumn In ArrayOfSummationColumns Do
					DimensionString[SummationColumn] = DimensionString[SummationColumn] 
															 + FoundRow[SummationColumn];  
				EndDo;
				
				Table.Delete(FoundRow);
				
				RowsCount       = RowsCount - 1;
				IndexOfFoundString = IndexOfFoundString - 1;
				
			EndDo;	
			
			RowsCount = RowsCount - 1;
			RowIndex    = RowIndex + 1;
			
		EndDo;
	
	Else
		
		Table.GroupBy(GroupingColumns, TotalingColumns);
		
	EndIf;	
	
EndProcedure

// Returns a table of values by adding a column and filling 
// in the totals (by grouping columns) of another column based on the data of the table rows.
//
// Parameters:
// 	Form             - ClientApplicationForm - shape.
// 	ObjectName        - String - object name.
// 	TableName        - String - table name.
// 	SelectedRows  - Boolean - True - only selected rows
//                               False - all lines.
//  ColumnSettings  - Structure - Contains:
//   *NameOfSummableColumn - String - the name of the source column.
//   *SummaryColumn       - Structure - Contains:
//     **Name         - String                      - column name
//     **ValueType - TypeDescription, Undefined - column type, if not filled in, then the type of the column to be summed up.
//   *GroupingColumns - String - the names of the comma-separated columns for which the final column is calculated.
//	RowFilter        - Structure, Undefined - key - name of the table prop
//                                                value-array of values of the table prop for selection.
//  SourceOfResults 	  - ValueTable, FormDataCollection, Undefined - The table of values for calculating totals, 
//                                                                            if Undefined, 
//                                                                            is then defined via the form.
//
// Returns:
// 	ValueTable - the resulting table is the value
//
Function TableWithTotalValueOfColumnByRow(
			Form, ObjectName, TableName, SelectedRows, ColumnSettings, RowFilter = Undefined, SourceOfResults = Undefined) Export
	
	NameOfSummableColumn = ColumnSettings.NameOfSummableColumn;
	NameOfSummaryColumn = ColumnSettings.SummaryColumn.Name;
	TypeOfSummaryColumn = ColumnSettings.SummaryColumn.ValueType;
	GroupingColumns = ColumnSettings.GroupingColumns;
	
	DataTable = Form[ObjectName][TableName]; // FormDataCollection, ValueTable
	TableOfResults = ?(SourceOfResults <> Undefined, SourceOfResults, DataTable);
	
	Table = ?(TypeOf(DataTable) <> Type("ValueTable"), 
					DataTable.Unload(New Array), DataTable.CopyColumns());
	
	Table.Columns.Add(
		NameOfSummaryColumn, ?(TypeOfSummaryColumn = Undefined, Table.Columns[NameOfSummableColumn].ValueType, TypeOfSummaryColumn));
		
	Table.Indexes.Add(GroupingColumns);
	
	FilterStructure1 = New Structure(GroupingColumns);
	
	SelectedLinesOnly = SelectedRows And TypeOf(DataTable) <> Type("ValueTable");
	
	RowsData = ?(SelectedLinesOnly, Form.Items[TableName].SelectedRows, DataTable);
	
	For Each DataString1 In RowsData Do
		
		CurrentRow = ?(SelectedLinesOnly, DataTable.FindByID(DataString1), DataString1);
		
		If RowFilter <> Undefined Then
			
			CancelStringProcessing = False;
			
			For Each FilterElement In RowFilter Do
				If FilterElement.Value.Find(CurrentRow[FilterElement.Key]) = Undefined Then
					CancelStringProcessing = True;
					Break;
				EndIf;	
			EndDo;
			
			If CancelStringProcessing Then
				Continue;
			EndIf;	
			
		EndIf;	
		
		FillPropertyValues(Table.Add(), CurrentRow);
		
		FillPropertyValues(FilterStructure1, CurrentRow);
		
		RowsArray = Table.FindRows(FilterStructure1);
		If RowsArray.Count() > 1 Then
			ValueOfSummaryColumn = RowsArray[0][NameOfSummaryColumn];
		Else
			ValueOfSummaryColumn = 0;
			RowsArray = TableOfResults.FindRows(FilterStructure1);
			For Each FoundRow In RowsArray Do
				ValueOfSummaryColumn = ValueOfSummaryColumn + FoundRow[NameOfSummableColumn];	
			EndDo;	
		EndIf;
		
		Table[Table.Count() - 1][NameOfSummaryColumn] = ValueOfSummaryColumn;
		
	EndDo;	
	
	Return Table;
	
EndFunction	

// Filling in the shipment date in the table part of the order
// Fills in the value of the field in the rows of the value collection.
//
// Parameters:
//  Collection - FormDataCollection - The collection to fill in the field in.
//  FieldName - String - the name of the column that needs to be filled.
//  FillValue - AnyRef, Number, Date, Boolean - The value to fill in.
//  SelectedRows - Array - lines to fill in the value in.
//
Procedure FillInDetailsInCollection(Collection, FieldName, FillValue, SelectedRows = Undefined) Export

	If SelectedRows = Undefined Then

		For Each TableRow In Collection Do
			TableRow[FieldName] = FillValue;
		EndDo;

	Else

		For Each RowID In SelectedRows Do
			TableRow = Collection.FindByID(RowID);
			TableRow[FieldName] = FillValue;
		EndDo;

	EndIf;

EndProcedure

#EndRegion

#Region InformingFunctionalityIsOutdated


// Warning about the imminent limitation of the functionality of route maps
// 
// Parameters:
//  Form - ClientApplicationForm -
//  ParentGroup1 - FormGroup -
//  
// Returns:
//  FormGroup -
Function AddWarningRouteMapsAreOutdated(Form, ParentGroup1 = Undefined) Export
	
	
	LabelText = NStr("vi = 'Lưu ý! Chức năng ""Phiếu lộ trình"" đã lỗi thời và sẽ bị xóa trong phiên bản 2.6.3.';
					|ru = 'Внимание! Функциональность ""Маршрутных карт"" устарела и будет удалена в версии 2.6.3.';
					|en = 'Important. Route sheets are outdated and will be removed in version 2.6.3.'; fa = 'Important. Route sheets are outdated and will be removed in version 2.6.3.';
					|it = 'Important. Route sheets are outdated and will be removed in version 2.6.3.';
					|pl = 'Important. Route sheets are outdated and will be removed in version 2.6.3.';
					|tr = 'Dikkat! ""Rota kartları"" işlevselliği kullanımdan kaldırılmıştır ve 2.6.3 sürümünde silinecektir.'");
	LabelText = LabelText + " "
	+ NStr("vi = 'Để lưu dữ liệu, hãy sử dụng công cụ tự động chuyển các nghiệp vụ sang danh mục ""Định mức nguồn lực"", trong đó hiện đã có mô tả theo từng công đoạn của quá trình sản xuất.';
			|ru = 'Для сохранения данных, воспользуйтесь инструментом автоматического переноса операций в справочник ""Ресурсные спецификации"", в котором теперь предусмотрено пооперационное описание производственного процесса.';
			|en = 'To save the data, use the automatic operation transfer tool in the ""Bills of materials"" catalog, which now describes the production process by operations.'; fa = 'To save the data, use the automatic operation transfer tool in the ""Bills of materials"" catalog, which now describes the production process by operations.';
			|it = 'To save the data, use the automatic operation transfer tool in the ""Bills of materials"" catalog, which now describes the production process by operations.';
			|pl = 'To save the data, use the automatic operation transfer tool in the ""Bills of materials"" catalog, which now describes the production process by operations.';
			|tr = 'Verileri kaybetmemek için, üretim sürecinin artık operasyon bazında tanımlandığı ""Ürün reçeteleri"" bölümüne otomatik operasyon aktarma aracını kullanın.'");
	
	Return AddWarningFunctionalityIsOutdated(Form, LabelText, ParentGroup1);
	
EndFunction

Function AddWarningFunctionalityIsOutdated(Form, LabelText, ParentGroup1 = Undefined)
	
	ElementPrefix = "FunctionalityIsOutdated";
	
	If Form.Items.Find("Group"+ElementPrefix) <> Undefined Then
		
		Return Undefined;
	
	ElsIf ParentGroup1 = Undefined Then
		
		If Not Form.Group = ChildFormItemsGroup.Vertical Then
			Return Undefined; // if the placement group is not specified, we automatically place it only in vertical forms 
		EndIf;
		
		For Each CurrentItem In Form.Items Do
			If CurrentItem <> Form.CommandBar Then
				Break;
			EndIf;
		EndDo;
		
		If CurrentItem = Undefined Then
			NewFolder = Form.Items.Add("Group"+ElementPrefix, Type("FormGroup"));
		Else
			NewFolder = Form.Items.Insert("Group"+ElementPrefix, Type("FormGroup"),,CurrentItem);
		EndIf;
		
	Else
		
		NewFolder = Form.Items.Add("Group"+ElementPrefix, Type("FormGroup"), ParentGroup1);
		
	EndIf;
	
	NewFolder.Type = FormGroupType.UsualGroup;
	NewFolder.Group = ChildFormItemsGroup.Horizontal;
	NewFolder.Representation = UsualGroupRepresentation.None;
	NewFolder.EnableContentChange = False;
	NewFolder.ShowTitle = False;
	
	NewItem = Form.Items.Add(ElementPrefix+"Decoration1", Type("FormDecoration"), NewFolder);
	NewItem.Type = FormDecorationType.Picture;
	NewItem.Picture = PictureLib.Warning;
	NewItem.VerticalAlignInGroup = ItemVerticalAlign.Center;
	
	NewFolder = Form.Items.Add("Group"+ElementPrefix+"Warning", Type("FormGroup"), NewFolder);
	NewFolder.Type = FormGroupType.UsualGroup;
	NewFolder.Group = ChildFormItemsGroup.Vertical;
	NewFolder.Representation = UsualGroupRepresentation.None;
	NewFolder.EnableContentChange = False;
	NewFolder.ShowTitle = False;
	
	NewItem = Form.Items.Add(ElementPrefix+"Decoration2", Type("FormDecoration"), NewFolder);
	NewItem.Type = FormDecorationType.Label;
	NewItem.Title = LabelText;
	NewItem.AutoMaxWidth = False;
	NewItem.TextColor = WebColors.FireBrick;
	
	Return NewFolder; // To add additional elements
	
EndFunction

#EndRegion

#Region Other

Procedure CopyColumnValues(Table, Source, Receiver, CreateNewColumn = True) Export
	
	If CreateNewColumn Then
		
		Table.Columns.Add(Receiver, Table.Columns[Source].ValueType);
	EndIf;
	Table.LoadColumn(Table.UnloadColumn(Source), Receiver); 
	
EndProcedure

Function CreateArray(ItemCount = 1, DefaultValue = Undefined) Export
	
	Result = New Array;
	
	For Cnt = 1 To ItemCount Do
		
		Result.Add(DefaultValue);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function ArrayOfValues(Val Value1, Val Value2 = Undefined, Val Value3 = Undefined, 
	Val Value4 = Undefined) Export
	
	Result = New Array;
	Result.Add(Value1);
	If Value2 <> Undefined Then
		Result.Add(Value2);
	EndIf;
	If Value3 <> Undefined Then
		Result.Add(Value3);
	EndIf;
	If Value4 <> Undefined Then
		Result.Add(Value4);
	EndIf;
	Return Result;
	
EndFunction

Function NextRequestParameter(Text, Parameter = "", Cursor = 1) Export
	
	Parameter = "";
	Position = StrFind(Text, "&", SearchDirection.FromBegin, Cursor);
	If Position > 0 Then
		For Cursor = Position + 1 To StrLen(Text) - 1 Do
			CharCode = CharCode(Text, Cursor);
			If (CharCode >= 48 And CharCode <= 57) // Digits
				Or (CharCode >= 65 And CharCode <= 90) // latin big
				Or (CharCode >= 97 And CharCode <= 122) // latin letters are small
				Or (CharCode >= 1040 And CharCode <= 1103) // CyrillicCharacters
				Or CharCode = 95 Then // the "_" symbol
				Continue;
			EndIf;
			Parameter = Mid(Text, Position + 1, Cursor - Position - 1);
			Return True;
		EndDo;
	EndIf;
	Return False;
	
EndFunction

Function PathDataLayoutField(ObjectName, DataPaths, FieldName)
	
	FieldDataPath = CommonClientServer.StructureProperty(DataPaths, FieldName, ObjectName + "." + FieldName);
	Return New DataCompositionField(FieldDataPath);
	
EndFunction

// Returns the structure of production Department details.
//
// Returns:
//  Structure - Contains:
//   * Description - String -
//   * ProductionDispatcherBusinessUnit - Boolean -
//   * ProductionByOrders - Boolean -
//   * BackflushProduction_ - Boolean -
//   * RecordingExpensesOnProcustCostIsUsed - Boolean -
//   * WorkSchedules - Array -
//   * UseTeamWorkOrders - Boolean -
//   * UsePersonalWorkOrders - Boolean -
//
Function StructureOfProductionUnitDetails()

	Parameters = New Structure;
	
	Parameters.Insert("Description",           "");
	Parameters.Insert("ProductionDispatcherBusinessUnit", False);
	
	Parameters.Insert("ProductionBusinessUnit", False);
	Parameters.Insert("ProductionByOrders",  False);
	Parameters.Insert("BackflushProduction_", False);
	
	Parameters.Insert("RecordingExpensesOnProcustCostIsUsed", False);
	
	Parameters.Insert("WorkSchedules", New Array);
	Parameters.Insert("PlanningInterval",           Enums.ProductionScheduleAccuracy.Day);
	Parameters.Insert("PlanningIntervalStart",    '00010101');
	Parameters.Insert("PlanningIntervalEnd", EndOfDay('00010101'));
	
	
	Parameters.Insert("UseOperationManagement",   False);
	Parameters.Insert("UseMaterialsInOperations",        False);
	Parameters.Insert("UseFinishedProductsInOperations",  False);
	Parameters.Insert("UseManufacturingExecutionSystem", False);
	
	Parameters.Insert("UseShiftTasks", False);
	Parameters.Insert("UseShifts",          False);
	
	Parameters.Insert("UseAreas",        False);
	Parameters.Insert("UseTeamWorkOrders",    False);
	Parameters.Insert("UsePersonalWorkOrders", False);
	
	Return Parameters;
	
EndFunction

// Determines the availability of the "Change Selected" Commands in production documents and Catalogs
// 
// Parameters:
//  MetadataObject - MetadataObject
// 
// Returns:
//  Boolean - The Command Change Selected Is Available
Function CommandChangeSelectedIsAvailable(MetadataObject = Undefined) Export
	
	Return Users.IsFullUser(,, False);
	
EndFunction

// Converts the original color to RGB format
//
// Parameters:
//  OriginalColor - Color - The color which you want to convert.
//
// Returns:
//   Color   - color in RGB format
//
Function ColorInRGBFormat(OriginalColor) Export

	If OriginalColor.Type = ColorType.Absolute Then
		
		Return OriginalColor;
		
	ElsIf OriginalColor.Type = ColorType.WebColor Then
	
		MatchingColors = New Map;
		MatchingColors.Insert(WebColors.Aquamarine, New Color(127, 255, 212));
		MatchingColors.Insert(WebColors.AliceBlue, New Color(240, 248, 255));
		MatchingColors.Insert(WebColors.AntiqueWhite, New Color(250, 235, 215));
		MatchingColors.Insert(WebColors.Beige, New Color(245, 245, 220));
		MatchingColors.Insert(WebColors.Snow, New Color(255, 250, 250));
		MatchingColors.Insert(WebColors.White, New Color(255, 255, 255));
		MatchingColors.Insert(WebColors.Turquoise, New Color(64, 224, 208));
		MatchingColors.Insert(WebColors.PaleTurquoise, New Color(175, 238, 238));
		MatchingColors.Insert(WebColors.PaleGreen, New Color(152, 251, 152));
		MatchingColors.Insert(WebColors.PaleGoldenrod, New Color(238, 232, 170));
		MatchingColors.Insert(WebColors.PaleVioletRed, New Color(219, 112, 147));
		MatchingColors.Insert(WebColors.Lavender, New Color(230, 230, 250));
		MatchingColors.Insert(WebColors.BlanchedAlmond, New Color(255, 235, 205));
		MatchingColors.Insert(WebColors.Thistle, New Color(216, 191, 216));
		MatchingColors.Insert(WebColors.CornFlowerBlue, New Color(100, 149, 237));
		MatchingColors.Insert(WebColors.SpringGreen, New Color(0, 255, 127));
		MatchingColors.Insert(WebColors.LightBlue, New Color(173, 216, 230));
		MatchingColors.Insert(WebColors.LavenderBlush, New Color(255, 240, 245));
		MatchingColors.Insert(WebColors.LightSteelBlue, New Color(176, 196, 222));
		MatchingColors.Insert(WebColors.SlateGray, New Color(112, 128, 144));
		MatchingColors.Insert(WebColors.SlateBlue, New Color(106, 90, 205));
		MatchingColors.Insert(WebColors.BurlyWood, New Color(222, 184, 184));
		MatchingColors.Insert(WebColors.WhiteSmoke, New Color(245, 245, 245));
		MatchingColors.Insert(WebColors.YellowGreen, New Color(154, 205, 50));
		MatchingColors.Insert(WebColors.Yellow, New Color(255, 255, 0));
		MatchingColors.Insert(WebColors.Moccasin, New Color(255, 228, 181));
		MatchingColors.Insert(WebColors.LawnGreen, New Color(124, 252, 0));
		MatchingColors.Insert(WebColors.Chartreuse, New Color(127, 255, 0));
		MatchingColors.Insert(WebColors.Lime, New Color(0, 255, 0));
		MatchingColors.Insert(WebColors.GreenYellow, New Color(173, 255, 47));
		MatchingColors.Insert(WebColors.Green, New Color(0, 255, 0));
		MatchingColors.Insert(WebColors.ForestGreen, New Color(34, 139, 34));
		MatchingColors.Insert(WebColors.Goldenrod, New Color(218, 165, 32));
		MatchingColors.Insert(WebColors.Gold, New Color(255, 215, 0));
		MatchingColors.Insert(WebColors.Indigo, New Color(75, 0, 130));
		MatchingColors.Insert(WebColors.IndianRed, New Color(205, 92, 92));
		MatchingColors.Insert(WebColors.FireBrick, New Color(178, 34, 34));
		MatchingColors.Insert(WebColors.SaddleBrown, New Color(139, 69, 19));
		MatchingColors.Insert(WebColors.Coral, New Color(255, 127, 80));
		MatchingColors.Insert(WebColors.Brown, New Color(165, 42, 42));
		MatchingColors.Insert(WebColors.RoyalBlue, New Color(65, 105, 225));
		MatchingColors.Insert(WebColors.VioletRed, New Color(208, 32, 144));
		MatchingColors.Insert(WebColors.Red, New Color(255, 0, 0));
		MatchingColors.Insert(WebColors.Cream, New Color(255, 251, 240));
		MatchingColors.Insert(WebColors.Azure, New Color(240, 255, 255));
		MatchingColors.Insert(WebColors.LimeGreen, New Color(50, 205, 50));
		MatchingColors.Insert(WebColors.LemonChiffon, New Color(255, 250, 205));
		MatchingColors.Insert(WebColors.Salmon, New Color(250, 128, 114));
		MatchingColors.Insert(WebColors.LightSalmon, New Color(255, 160, 122));
		MatchingColors.Insert(WebColors.DarkSalmon, New Color(233, 150, 122));
		MatchingColors.Insert(WebColors.Linen, New Color(250, 240, 230));
		MatchingColors.Insert(WebColors.Crimson, New Color(220, 20, 60));
		MatchingColors.Insert(WebColors.MintCream, New Color(245, 255, 250));
		MatchingColors.Insert(WebColors.NavajoWhite, New Color(255, 222, 173));
		MatchingColors.Insert(WebColors.DeepSkyBlue, New Color(0, 191, 255));
		MatchingColors.Insert(WebColors.DeepPink, New Color(255, 20, 147));
		MatchingColors.Insert(WebColors.SkyBlue, New Color(135, 206, 235));
		MatchingColors.Insert(WebColors.MediumAquaMarine, New Color(102, 205, 170));
		MatchingColors.Insert(WebColors.MediumTurquoise, New Color(72, 209, 204));
		MatchingColors.Insert(WebColors.MediumSpringGreen, Undefined);
		MatchingColors.Insert(WebColors.MediumSlateBlue, New Color(123, 104, 238));
		MatchingColors.Insert(WebColors.MediumGreen, New Color(192, 220, 192));
		MatchingColors.Insert(WebColors.Peru, New Color(205, 133, 63));
		MatchingColors.Insert(WebColors.MediumPurple, New Color(147, 112, 219));
		MatchingColors.Insert(WebColors.MediumGray, Undefined);
		MatchingColors.Insert(WebColors.MediumBlue, New Color(0, 0, 205));
		MatchingColors.Insert(WebColors.MediumVioletRed, New Color(199, 21, 133));
		MatchingColors.Insert(WebColors.Olive, Undefined);
		MatchingColors.Insert(WebColors.OrangeRed, New Color(255, 69, 0));
		MatchingColors.Insert(WebColors.Orange, New Color(255, 165, 0));
		MatchingColors.Insert(WebColors.Orchid, New Color(218, 112, 214));
		MatchingColors.Insert(WebColors.MediumOrchid, New Color(186, 85, 211));
		MatchingColors.Insert(WebColors.DarkOrchid, New Color(153, 50, 204));
		MatchingColors.Insert(WebColors.Sienna, New Color(160, 82, 45));
		MatchingColors.Insert(WebColors.SeaShell, Undefined);
		MatchingColors.Insert(WebColors.PeachPuff, New Color(255, 218, 185));
		MatchingColors.Insert(WebColors.SandyBrown, New Color(244, 164, 96));
		MatchingColors.Insert(WebColors.MidnightBlue, New Color(25, 25, 112));
		MatchingColors.Insert(WebColors.GhostWhite, New Color(248, 248, 255));
		MatchingColors.Insert(WebColors.Purple, New Color(160, 32, 240));
		MatchingColors.Insert(WebColors.Wheat, New Color(245, 222, 179));
		MatchingColors.Insert(WebColors.RosyBrown, New Color(188, 143, 143));
		MatchingColors.Insert(WebColors.Pink, New Color(255, 192, 203));
		MatchingColors.Insert(WebColors.HoneyDew, Undefined);
		MatchingColors.Insert(WebColors.Tan, New Color(210, 180, 140));
		MatchingColors.Insert(WebColors.LightSlateGray, New Color(119, 136, 153));
		MatchingColors.Insert(WebColors.LightSlateBlue, New Color(132, 112, 255));
		MatchingColors.Insert(WebColors.LightYellow, New Color(255, 255, 224));
		MatchingColors.Insert(WebColors.LightGoldenRodYellow, Undefined);
		MatchingColors.Insert(WebColors.LightGreen, New Color(144, 238, 144));
		MatchingColors.Insert(WebColors.LightGoldenRod, New Color(238, 221, 130));
		MatchingColors.Insert(WebColors.LightCoral, New Color(240, 128, 128));
		MatchingColors.Insert(WebColors.Bisque, New Color(255, 228, 196));
		MatchingColors.Insert(WebColors.LightSkyBlue, New Color(135, 206, 250));
		MatchingColors.Insert(WebColors.LightPink, New Color(255, 182, 193));
		MatchingColors.Insert(WebColors.LightGray, New Color(211, 211, 211));
		MatchingColors.Insert(WebColors.Gainsboro, New Color(220, 220, 220));
		MatchingColors.Insert(WebColors.Silver, Undefined);
		MatchingColors.Insert(WebColors.CadetBlue, New Color(95, 158, 160));
		MatchingColors.Insert(WebColors.Gray, Undefined);
		MatchingColors.Insert(WebColors.DodgerBlue, New Color(30, 144, 255));
		MatchingColors.Insert(WebColors.BlueViolet, New Color(138, 43, 226));
		MatchingColors.Insert(WebColors.Blue, New Color(0, 0, 255));
		MatchingColors.Insert(WebColors.SteelBlue, New Color(70, 130, 180));
		MatchingColors.Insert(WebColors.PowderBlue, New Color(176, 224, 230));
		MatchingColors.Insert(WebColors.Plum, New Color(221, 160, 221));
		MatchingColors.Insert(WebColors.Ivory, New Color(255, 255, 240));
		MatchingColors.Insert(WebColors.OldLace, New Color(253, 245, 230));
		MatchingColors.Insert(WebColors.DarkTurquoise, New Color(0, 206, 209));
		MatchingColors.Insert(WebColors.Maroon, New Color(176, 48, 96));
		MatchingColors.Insert(WebColors.DarkSlateGray, New Color(47, 79, 79));
		MatchingColors.Insert(WebColors.DarkSlateBlue, New Color(72, 61, 139));
		MatchingColors.Insert(WebColors.DarkGreen, New Color(0, 100, 0));
		MatchingColors.Insert(WebColors.DarkGoldenRod, Undefined);
		MatchingColors.Insert(WebColors.DarkRed, New Color(139, 0, 0));
		MatchingColors.Insert(WebColors.DarkOliveGreen, New Color(85, 107, 47));
		MatchingColors.Insert(WebColors.DarkOrange, New Color(255, 140, 0));
		MatchingColors.Insert(WebColors.DarkGray, Undefined);
		MatchingColors.Insert(WebColors.DarkBlue, New Color(0, 0, 139));
		MatchingColors.Insert(WebColors.DarkViolet, New Color(148, 0, 211));
		MatchingColors.Insert(WebColors.HotPink, New Color(255, 105, 180));
		MatchingColors.Insert(WebColors.Tomato, New Color(255, 99, 71));
		MatchingColors.Insert(WebColors.PapayaWhip, New Color(255, 239, 213));
		MatchingColors.Insert(WebColors.Olivedrab, Undefined);
		MatchingColors.Insert(WebColors.MistyRose, New Color(255, 228, 225));
		MatchingColors.Insert(WebColors.DimGray, Undefined);
		MatchingColors.Insert(WebColors.Navy, Undefined);
		MatchingColors.Insert(WebColors.Violet, New Color(238, 130, 238));
		MatchingColors.Insert(WebColors.Magenta, New Color(255, 0, 255));
		MatchingColors.Insert(WebColors.DarkMagenta, New Color(139, 0, 139));
		MatchingColors.Insert(WebColors.Fuchsia, Undefined);
		MatchingColors.Insert(WebColors.Khaki, Undefined);
		MatchingColors.Insert(WebColors.DarkKhaki, New Color(189, 183, 107));
		MatchingColors.Insert(WebColors.Seagreen, Undefined);
		MatchingColors.Insert(WebColors.MediumSeaGreen, New Color(60, 179, 113));
		MatchingColors.Insert(WebColors.LightSeaGreen, New Color(32, 178, 170));
		MatchingColors.Insert(WebColors.DarkSeaGreen, New Color(143, 188, 143));
		MatchingColors.Insert(WebColors.FloralWhite, New Color(255, 250, 240));
		MatchingColors.Insert(WebColors.Cyan, New Color(0, 255, 255));
		MatchingColors.Insert(WebColors.Aqua, Undefined);
		MatchingColors.Insert(WebColors.Teal, Undefined);
		MatchingColors.Insert(WebColors.LightCyan, New Color(224, 255, 255));
		MatchingColors.Insert(WebColors.DarkCyan, New Color(0, 139, 139));
		MatchingColors.Insert(WebColors.Black, New Color(0, 0, 0));
		MatchingColors.Insert(WebColors.CornSilk, Undefined);
		MatchingColors.Insert(WebColors.Chocolate, New Color(210, 105, 30));
		
		Return MatchingColors.Get(OriginalColor);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns a service table document
//
// Returns:
//  SpreadsheetDocument - Contains:
//  * Parameters - SpreadsheetDocumentTemplateParameters - Contains:
//                 ** LineNumber - Number -
//                 ** TitleText - String - 
//
Function ServiceStructureTabularDocument() Export
	
	Return New SpreadsheetDocument;
	
EndFunction

// Returns a service table of values
//
// Returns:
//  ValueTable - Contains:
//  * LineNumber - Number - 
//  * Ref - DocumentRef, CatalogRef - 
//  * Id - Number, UUID - 
//  * StageStart - Date -
//  * LongDesc - String - 
//  * Rows - ValueTreeRowCollection - 
//
Function ServiceStructureOfValueTable() Export
	
	Return New ValueTable;
	
EndFunction

// Returns service structures
//
// Returns:
//  Structure - Contains:
//  * SpecificationsData - Array of Structure - Contains:
//                                    ** ManufacturedProducts - ValueTable - 
//                                    ** MaterialsAndServices - ValueTable - Contains:
//                                                           *** LineNumber - Number - 
//  * Supplement - Structure -
//
Function ServiceStructureOfStructure() Export
	
	Return New Structure;
	
EndFunction

// Returns a service array of structures
//
// Returns:
//  Array of Structure - Contains:
//  * Id - Number, UUID - 
//
Function ServiceStructureOfArrayOfStructures() Export
	
	Return New Structure;
	
EndFunction

#EndRegion

#EndRegion
