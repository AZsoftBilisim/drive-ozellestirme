
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
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.InventoryConsumptionOrders);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.TransferOrders);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.AssemblyOrders);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		DocumentType = TypeOf(Document);
		
		CorrectiveDocument = DocumentCorrection.ThisIsCorrectiveDocument(Document);
		
		If DocumentType = Type("DocumentObject.InventoryConsumptionOrder")
				Or DocumentType = Type("DocumentObject.RMOrder")
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And DocumentType = Type("DocumentObject.InventoryConsumption")
			Or CorrectiveDocument  Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.InventoryConsumptionOrders);
		EndIf;
		
		If DocumentType = Type("DocumentObject.TransferOrder")
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And DocumentType = Type("DocumentObject.InventoryTransfer")
			Or CorrectiveDocument Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.TransferOrders);
		EndIf;
		
		If DocumentType = Type("DocumentObject.ByAssemblyDisassemblyOrder")
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And DocumentType = Type("DocumentObject.AssemblyFromComponents")
			Or CorrectiveDocument Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.AssemblyOrders);
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.InventoryConsumptionOrders;
	
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.TransferOrders;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.AssemblyOrders;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of the internal distribution.
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
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InventoryConsumptionOrders");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "TransferOrders");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AssemblyOrders");
	
EndProcedure

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

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region InventoryConsumptionOrders
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOfDomesticConsumptionOrdersUpdate") Then
		
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		
		If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
			
			QueryText =
				"SELECT
				|	BalanceTable.InventoryConsumptionOrder  AS OrderDocument,
				|	BalanceTable.Products                  AS Products,
				|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
				|	BalanceTable.Characteristic                AS Characteristic,
				|	BalanceTable.Series                         AS Series,
				|	BalanceTable.Warehouse                         AS Warehouse,
				|	BalanceTable.ToRegisterBalance            AS Count
				|FROM
				|	AccumulationRegister.InventoryConsumptionOrders.Balance(,
				|			(InventoryConsumptionOrder, Products, Characteristic, Series, Warehouse) IN
				|				(SELECT
				|					Table.InventoryConsumptionOrder,
				|					Table.Products,
				|					Table.Characteristic,
				|					Table.Series,
				|					Table.Warehouse
				|				FROM
				|					RegisteredRecordsOfDomesticConsumptionOrdersUpdate AS Table)
				|	) AS BalanceTable
				|WHERE
				|	BalanceTable.ToRegisterBalance < 0";
			
		Else
			
			QueryText = 
				"SELECT
				|	OrdersBalance.InventoryConsumptionOrder   AS OrderDocument,
				|	OrdersBalance.Products                   AS Products,
				|	OrdersBalance.Products.UnitOfMeasure  AS UnitOfMeasure,
				|	OrdersBalance.Characteristic                 AS Characteristic,
				|	OrdersBalance.Series                          AS Series,
				|	OrdersBalance.Warehouse                          AS Warehouse,
				|	OrdersBalance.ToRegisterBalance             AS Count
				|FROM
				|	TTOrdersForDomesticConsumptionBalance AS OrdersBalance
				|	LEFT JOIN
				|		TTToleranceOrdersForDomesticConsumption AS AcceptableDeviations
				|		ON
				|			OrdersBalance.InventoryConsumptionOrder = AcceptableDeviations.InventoryConsumptionOrder
				|			AND OrdersBalance.Products               = AcceptableDeviations.Products
				|			AND OrdersBalance.Characteristic             = AcceptableDeviations.Characteristic
				|			AND OrdersBalance.Warehouse                      = AcceptableDeviations.Warehouse
				|			AND OrdersBalance.Series                      = AcceptableDeviations.Series
				|WHERE
				|	OrdersBalance.ToRegisterBalance + ISNULL(AcceptableDeviations.AllowableVariance,0) < 0";
			
		EndIf;
		
		QueryTexts.Add(QueryText, "ErrorsOrdersForDomesticConsumption");
		
	EndIf;
	
	#EndRegion
	
	#Region TransferOrders
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOrdersToMoveChange") Then
		
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		
		If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
			
			QueryText =
				"SELECT
				|	BalanceTable.TransferOrder AS OrderDocument,
				|	BalanceTable.Products       AS Products,
				|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
				|	BalanceTable.Characteristic     AS Characteristic,
				|	BalanceTable.Series              AS Series,
				|	UNDEFINED                       AS Warehouse,
				|	UNDEFINED                       AS Department,
				|	BalanceTable.ToRegisterBalance AS Count
				|FROM
				|	AccumulationRegister.TransferOrders.Balance(,
				|			(TransferOrder, Products, Characteristic, Series) IN
				|				(SELECT
				|					Table.TransferOrder,
				|					Table.Products,
				|					Table.Characteristic,
				|					Table.Series
				|				FROM
				|					RegisteredRecordsOrdersToMoveChange AS Table)
				|	) AS BalanceTable
				|WHERE
				|	BalanceTable.ToRegisterBalance < 0";
			
		Else
			
			QueryText = 
				"SELECT
				|	OrdersBalance.TransferOrder             AS OrderDocument,
				|	OrdersBalance.Products                   AS Products,
				|	OrdersBalance.Products.UnitOfMeasure  AS UnitOfMeasure,
				|	OrdersBalance.Characteristic                 AS Characteristic,
				|	OrdersBalance.Series                          AS Series,
				|	UNDEFINED                                 AS Warehouse,
				|	UNDEFINED                                 AS Department,
				|	OrdersBalance.ToRegisterBalance             AS Count
				|FROM
				|	TTMoveOrdersBalance AS OrdersBalance
				|	LEFT JOIN
				|		TTToleranceMoveOrders AS AcceptableDeviations
				|		ON
				|			OrdersBalance.TransferOrder = AcceptableDeviations.TransferOrder
				|			AND OrdersBalance.Products     = AcceptableDeviations.Products
				|			AND OrdersBalance.Characteristic   = AcceptableDeviations.Characteristic
				|			AND OrdersBalance.Series            = AcceptableDeviations.Series
				|WHERE
				|	OrdersBalance.ToRegisterBalance + ISNULL(AcceptableDeviations.AllowableVariance,0) < 0";
			
		EndIf;
		
		QueryTexts.Add(QueryText, "ErrorsMoveOrders");
		
	EndIf;
	
	#EndRegion
	
	#Region AssemblyOrders
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsBuildOrdersChange") Then
		
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		
		If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
			
			QueryText =
				"SELECT
				|	BalanceTable.ByAssemblyDisassemblyOrder      AS ByAssemblyDisassemblyOrder,
				|	BalanceTable.Products       AS Products,
				|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
				|	BalanceTable.Characteristic     AS Characteristic,
				|	BalanceTable.Series              AS Series,
				|	BalanceTable.AssemblyType          AS AssemblyType,
				|	BalanceTable.ToRegisterBalance AS Count
				|FROM
				|	AccumulationRegister.AssemblyOrders.Balance(,
				|			(ByAssemblyDisassemblyOrder, Products, Characteristic, Series, AssemblyType) IN
				|				(SELECT
				|					Table.ByAssemblyDisassemblyOrder,
				|					Table.Products,
				|					Table.Characteristic,
				|					Table.Series,
				|					Table.AssemblyType
				|				FROM
				|					RegisteredRecordsBuildOrdersChange AS Table)
				|	) AS BalanceTable
				|WHERE
				|	BalanceTable.ToRegisterBalance < 0";
			
		Else
			
			QueryText = 
				"SELECT
				|	OrdersBalance.ByAssemblyDisassemblyOrder                  AS ByAssemblyDisassemblyOrder,
				|	OrdersBalance.Products                   AS Products,
				|	OrdersBalance.Products.UnitOfMeasure  AS UnitOfMeasure,
				|	OrdersBalance.Characteristic                 AS Characteristic,
				|	OrdersBalance.Series                          AS Series,
				|	OrdersBalance.AssemblyType                      AS AssemblyType,
				|	OrdersBalance.ToRegisterBalance             AS Count
				|FROM
				|	TTAssemblyOrdersBalance AS OrdersBalance
				|	LEFT JOIN
				|		TTAcceptableDeviationsAssemblyOrders AS AcceptableDeviations
				|		ON
				|			OrdersBalance.ByAssemblyDisassemblyOrder    = AcceptableDeviations.ByAssemblyDisassemblyOrder
				|			AND OrdersBalance.Products   = AcceptableDeviations.Products
				|			AND OrdersBalance.Characteristic = AcceptableDeviations.Characteristic
				|			AND OrdersBalance.AssemblyType      = AcceptableDeviations.AssemblyType
				|			AND OrdersBalance.Series          = AcceptableDeviations.Series
				|WHERE
				|	OrdersBalance.ToRegisterBalance + ISNULL(AcceptableDeviations.AllowableVariance,0) < 0";
			
		EndIf;
		
		QueryTexts.Add(QueryText, "BuildOrderErrors");
		
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
	
	#Region InventoryConsumptionOrders
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOfDomesticConsumptionOrdersUpdate") Then
		
		If TypeOf(Document) = Type("DocumentObject.InventoryConsumption") Then
			
			WarehouseMessageTemplate = NStr("vi = 'Mặt hàng %1, kho bãi %2
				|Đã lập nhiều hơn số đã chỉ ra trong lệnh là %3 %4';
				|ru = 'Номенклатура %1, склад %2
				|Оформлено больше, чем указано в распоряжении, на %3 %4';
				|en = 'Items %1, warehouse %2
				| Registered more than stated in the instruction by %3 %4'; fa = 'Items %1, warehouse %2
				| Registered more than stated in the instruction by %3 %4';
				|it = 'Articolo %1, magazzino %2
				| Indicata quantità superiore rispetto alla disposizione, di %3 %4';
				|pl = 'Pozycja %1, magazyn %2
				|Sporządzono więcej, niż określono w zamówieniu, o %3 %4';
				|tr = 'Öğe %1, ambar %2
				| siparişinde belirtilenden %3 %4 kadar fazla kaydedildi'");
			MessageTemplateWithoutWarehouse = NStr("vi = 'Mặt hàng %1
				|Đã lập nhiều hơn số lượng đã chỉ ra trong lệnh là %3 %4';
				|ru = 'Номенклатура %1
				|Оформлено больше, чем указано в распоряжении, на %3 %4';
				|en = 'Items %1
				| Registered more than stated in the instruction by %3 %4'; fa = 'Items %1
				| Registered more than stated in the instruction by %3 %4';
				|it = 'Articolo %1
				| Indicata quantità superiore rispetto alla disposizione, di %3%4';
				|pl = 'Pozycja %1
				|Sporządzono więcej, niż określono w zamówieniu, o %3 %4';
				|tr = 'Öğe %1
				| siparişinde belirtilenden %3 %4 kadar daha fazla kaydedildi'");
			
		Else
			
			WarehouseMessageTemplate = NStr("vi = 'Mặt hàng %1, kho bãi %2
				|Số lượng đã lập chứng từ tiêu dùng nội bộ nhiều hơn trong chứng từ, %3 %4';
				|ru = 'Номенклатура %1, склад %2
				|Оформлено внутреннее потребление в количестве большем, чем указано в документе, на %3 %4';
				|en = 'Items %1, warehouse %2
				| Registered inventory consumption exceeds the one specified in the document by %3 %4'; fa = 'Items %1, warehouse %2
				| Registered inventory consumption exceeds the one specified in the document by %3 %4';
				|it = 'Articolo %1, magazzino %2
				|La quantità indicata impiegata per consumo interno è superiore rispetto a quella indicato nel documento, di %3 %4';
				|pl = 'Nomenklatura %1, magazyn %2
				|Sporządzono spożycie na potrzeby wewnętrzne w ilości większej, niż określono w dokumencie, o %3 %4';
				|tr = 'Öğe %1, ambar %2
				|İç tüketim, belgede belirtilenden daha fazla miktarda %3 %4 kadar kaydedilmiştir'");
			MessageTemplateWithoutWarehouse = NStr("vi = 'Mặt hàng %1
				|Số lượng đã lập trong chứng từ tiêu dùng nội bộ nhiều hơn số lượng đã chỉ ra trong chứng từ %3 %4';
				|ru = 'Номенклатура %1
				|Оформлено внутреннее потребление в количестве большем, чем указано в документе, на %3 %4';
				|en = 'Items %1
				|Registered inventory consumption exceeds the one specified in the document by %3 %4'; fa = 'Items %1
				|Registered inventory consumption exceeds the one specified in the document by %3 %4';
				|it = 'Articolo %1
				| La quantità indicata impiegata per consumo interno è superiore rispetto a quella indicato nel documento, di %3 %4';
				|pl = 'Nomenklatura %1
				|Sporządzono spożycie na potrzeby wewnętrzne w ilości większej, niż określono w dokumencie, o %3 %4';
				|tr = 'Öğe %1
				|İç tüketim, belgede belirtilenden daha fazla miktarda %3 %4 kadar kaydedilmiştir'");
			
		EndIf;
		
		For Each ErrorString In ControlResults.ErrorsOrdersForDomesticConsumption Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products, ErrorString.Characteristic);
			
			If ValueIsFilled(ErrorString.Warehouse) Then
 				MessageText = StrTemplate(WarehouseMessageTemplate, ProductPresentation, ErrorString.Warehouse,
					-ErrorString.Count, ErrorString.UnitOfMeasure);
			Else
 				MessageText = StrTemplate(MessageTemplateWithoutWarehouse, ProductPresentation,,
					-ErrorString.Count, ErrorString.UnitOfMeasure);
			EndIf;
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region InventoryConsumptionOrders
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsOrdersToMoveChange") Then
		
		MessageTemplateForWarehouseWithDivision = NStr("vi = 'Mặt hàng %1, kho bãi %2, bộ phận %3
			|Đã lập nhiều hơn số lượng đã chỉ ra trong lệnh cần lập là %4 %5';
			|ru = 'Номенклатура %1, склад %2, подразделение %3
			|Оформлено больше, чем указано в распоряжении на оформление, на %4 %5';
			|en = 'Items %1, warehouse %2, business unit %3
			| Registered more than stated in the instruction for registration by %4 %5'; fa = 'Items %1, warehouse %2, business unit %3
			| Registered more than stated in the instruction for registration by %4 %5';
			|it = 'Articolo %1, magazzino %2, reparto %3
			| Indicata quantità superiore rispetto alla disposizione, di %4 %5';
			|pl = 'Pozycja %1, magazyn %2, dział %3
			|Sporządzono więcej, niż określono w zamówieniu na sporządzenie, o %4 %5';
			|tr = 'Öğe %1, ambar %2, departman %3
			| Kayıt emrinde belirtilenden %4 %5 kadar fazla kaydedildi'");
			
		TemplateForMessageWithWarehouseWithoutDivision = NStr("vi = 'Mặt hàng %1, kho bãi %2
			|Đã lập số lượng nhiều hơn trong lệnh là %4 %5';
			|ru = 'Номенклатура %1, склад %2
			|Оформлено больше, чем указано в распоряжении на оформление, на %4 %5';
			|en = 'Items %1, warehouse %2
			| Registered more than stated in the instruction for registration by  %4 %5'; fa = 'Items %1, warehouse %2
			| Registered more than stated in the instruction for registration by  %4 %5';
			|it = 'Articolo %1, magazzino %2
			| Indicata quantità superiore rispetto alla disposizione, di %4 %5';
			|pl = 'Pozycja %1, magazyn %2
			|Sporządzono więcej, niż określono w zamówieniu na sporządzenie, o %4 %5';
			|tr = 'Öğe %1, ambar %2
			|Kayıt emrinde belirtilenden %4 %5 kadar fazla kaydedildi'");
			
		TemplateForMessageWithoutWarehouseWithDivision = NStr("vi = 'Mặt hàng %1, bộ phận %3
			|Số lượng đã lập nhiều hơn số lượng đã chỉ ra trong lệnh là %4 %5';
			|ru = 'Номенклатура %1, подразделение %3
			|Оформлено больше, чем указано в распоряжении на оформление, на %4 %5';
			|en = 'Items %1, business unit %3
			| Registered more than stated in the instruction for registration by %4 %5'; fa = 'Items %1, business unit %3
			| Registered more than stated in the instruction for registration by %4 %5';
			|it = 'Articolo %1, reparto %3
			| Indicata quantità superiore rispetto alla disposizione, di %4 %5';
			|pl = 'Pozycja %1, dział %3
			|Sporządzono więcej, niż określono w zamówieniu na sporządzenie, o %4 %5';
			|tr = 'Öğe %1, departman %3
			|Kayıt emrinde belirtilenden %4%5 kadar fazla kaydedildi'");
			
		MessageTemplateWithoutWarehouseWithoutDivision = NStr("vi = 'Mặt hàng %1
			|Số lượng đã lập nhiều hơn trong lệnh là %4 %5';
			|ru = 'Номенклатура %1
			|Оформлено больше, чем указано в распоряжении на оформление, на %4 %5';
			|en = 'Products %1
			|Registered more than stated in the instruction for registration by %4 %5'; fa = 'Products %1
			|Registered more than stated in the instruction for registration by %4 %5';
			|it = 'Articolo %1
			| Indicata quantità superiore rispetto alla disposizione, di %4 %5';
			|pl = 'Pozycja %1
			|Sporządzono więcej, niż określono w zamówieniu na sporządzenie, o %4%5';
			|tr = 'Öğe %1
			|Kayıt emrinde belirtilenden %4 %5 kadar fazla kaydedildi'");
		
		For Each ErrorString In ControlResults.ErrorsMoveOrders Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products, ErrorString.Characteristic);
			
			If ValueIsFilled(ErrorString.Warehouse) And ValueIsFilled(ErrorString.Department) Then
				MessageText = StrTemplate(MessageTemplateForWarehouseWithDivision,
					ProductPresentation, ErrorString.Warehouse, ErrorString.Department,
					-ErrorString.Count, ErrorString.UnitOfMeasure);
			ElsIf ValueIsFilled(ErrorString.Warehouse) And Not ValueIsFilled(ErrorString.Department) Then
				MessageText = StrTemplate(TemplateForMessageWithWarehouseWithoutDivision,
					ProductPresentation, ErrorString.Warehouse,,
					-ErrorString.Count, ErrorString.UnitOfMeasure);
			ElsIf Not ValueIsFilled(ErrorString.Warehouse) And ValueIsFilled(ErrorString.Department) Then
				MessageText = StrTemplate(TemplateForMessageWithoutWarehouseWithDivision,
					ProductPresentation,, ErrorString.Department,
					-ErrorString.Count, ErrorString.UnitOfMeasure);
			Else
				MessageText = StrTemplate(MessageTemplateWithoutWarehouseWithoutDivision, ProductPresentation,,,
					-ErrorString.Count, ErrorString.UnitOfMeasure);
			EndIf;
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region OrdersBuildOrders
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsBuildOrdersChange") Then
		
		MessageTemplate = NStr("vi = 'Mặt hàng %1
			|Số lượng đã lập nhiều hơn trong lệnh là %2 %3';
			|ru = 'Номенклатура %1
			|Оформлено больше, чем указано в распоряжении на оформление, на %2 %3';
			|en = 'Products %1
			|Registered more than stated in the instruction for registration by %2 %3'; fa = 'Products %1
			|Registered more than stated in the instruction for registration by %2 %3';
			|it = 'Articolo %1
			| Indicata quantità superiore rispetto alla disposizione, di %2%3';
			|pl = 'Pozycja %1
			|Sporządzono więcej, niż określono w zamówieniu na sporządzenie, o %2 %3';
			|tr = 'Öğe %1
			|Kayıt emrinde belirtilenden %2 %3 kadar fazla kaydedildi'");
		
		For Each ErrorString In ControlResults.BuildOrderErrors Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products, ErrorString.Characteristic);
			
			MessageText = StrTemplate(MessageTemplate, ProductPresentation,
				-ErrorString.Count, ErrorString.UnitOfMeasure);
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Adds field totals to the Query Text 
// 
// Parameters:
// 	QueryText - String - Query text
// Returns:
// 	String - Query text
Function AddResultsForNDIGC(QueryText) Export
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	LastRequest = QuerySchema.QueryBatch[QuerySchema.QueryBatch.Count() - 1];
	SenderSNDIGCIndex = LastRequest.Columns.IndexOf(LastRequest.Columns.Find("SenderSIDC")); 
	RecipientSNDIGCIndex = LastRequest.Columns.IndexOf(LastRequest.Columns.Find("RecipientSIDIGC"));
	LastRequest.TotalCalculationFields.Add(LastRequest.Columns[SenderSNDIGCIndex]);
	LastRequest.TotalCalculationFields.Add(LastRequest.Columns[RecipientSNDIGCIndex]);
	QueryText = QuerySchema.GetQueryText();
	
	Return QueryText;
	
EndFunction

// Generates the text of the field for printing the LB and IGC names
// 
// Parameters:
// 	PathToLBField - String - the path to the field "Direction of activity"
// Returns:
// 	String - LongDesc
Function TextOfNDIGCField(PathToLBField = "LinesOfBusiness") Export

	FieldText = 
	"CASE
	|	WHEN LB.NameForPrinting = """"
	|	THEN ISNULL(LB.StateContract.IGCNumber, """")
	|	ELSE LB.NameForPrinting + "" "" + ISNULL(LB.StateContract.IGCNumber, """")
	|	END";
	FieldText = StrReplace(FieldText, "LB", PathToLBField);

	Return FieldText;

EndFunction

#EndRegion