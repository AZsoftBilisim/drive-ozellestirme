
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
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.TransferredReturnablePackaging);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.GoodsTransferredToCommissionAgent);
		
		Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.DatesOfConsignmentGoodsTransfer);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		DocumentType = TypeOf(Document);
		
		If Properties.WriteMode = DocumentWriteMode.Posting
				And (DocumentType = Type("DocumentObject.ReturnOfGoodsFromCustomer")
				Or DocumentType = Type("DocumentObject.ReturnablePackagingRedemptionByCustomer")
				Or DocumentType = Type("DocumentObject.OBEntryGoods")
				Or DocumentType = Type("DocumentObject.OBEntry")
				Or DocumentType = Type("DocumentObject.SaleAdjustment"))
			Or Not Properties.IsNew
				And (
				DocumentType = Type("DocumentObject.CustomerInvoice"))
			Or DocumentCorrection.ThisIsCorrectiveDocument(Document) Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.TransferredReturnablePackaging);
		EndIf;
		
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.GoodsTransferredToCommissionAgent);
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.TransferredReturnablePackaging);
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.TransferredReturnablePackaging;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	
	RegisterMetadata = Metadata.AccumulationRegisters.GoodsTransferredToCommissionAgent;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// Procedure for forming movements on subordinate registers of transmission to the response storage.
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
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "TransferredReturnablePackaging");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "GoodsTransferredToCommissionAgent");
	
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
	MatchingQueryTexts.Insert("RegisteredRecordsTransferredReturnPackagingChange", 
		AccumulationRegisters.TransferredReturnablePackaging.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// Procedure for generating movements based on independent registers of transmission to the response storage.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	TableName = "Table" + "DatesOfConsignmentGoodsTransfer";
	
	If TablesForRegisteredRecords.Property(TableName)
		And ValueIsFilled(TablesForRegisteredRecords[TableName]) Then
		
		For Each TableRow In TablesForRegisteredRecords[TableName] Do
			RecordManager = InformationRegisters.DatesOfConsignmentGoodsTransfer.CreateRecordManager();
			FillPropertyValues(RecordManager, TableRow);
			RecordManager.Write(True);
		EndDo;
		
	EndIf;
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region TransferredReturnablePackaging
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsTransferredReturnPackagingChange") Then
		
		QueryText =
			"SELECT
			|	BalanceTable.Partner                        AS Partner,
			|	BalanceTable.Products                   AS Products,
			|	BalanceTable.Products.UnitOfMeasure  AS UnitOfMeasure,
			|	BalanceTable.Characteristic                 AS Characteristic,
			|	BalanceTable.DocumentTransfers_               AS DocumentTransfers_,
			|	BalanceTable.DepositIsRequired              AS DepositIsRequired,
			|	BalanceTable.InventoryOwnerAttribute                     AS InventoryOwnerAttribute,
			|	BalanceTable.CCDNumber                       AS CCDNumber,
			|	BalanceTable.CountBalance              AS Count,
			|	BalanceTable.SumBalance                   AS Sum
			|FROM
			|	AccumulationRegister.TransferredReturnablePackaging.Balance(,
			|			(Partner, Products, Characteristic, DocumentTransfers_, InventoryOwnerAttribute, CCDNumber, DepositIsRequired) IN
			|				(SELECT
			|					Table.Partner,
			|					Table.Products,
			|					Table.Characteristic,
			|					Table.DocumentTransfers_,
			|					Table.InventoryOwnerAttribute,
			|					Table.CCDNumber,
			|					Table.DepositIsRequired
			|				FROM
			|					RegisteredRecordsTransferredReturnPackagingChange AS Table)
			|	) AS BalanceTable
			|
			|WHERE
			|	BalanceTable.CountBalance < 0";
		
		QueryTexts.Add(QueryText, "ErrorsTransferredReturnContainers");
		
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
	
	#Region TransferredReturnablePackaging
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsTransferredReturnPackagingChange") Then
		
		MessageTemplate = NStr("vi = 'Mặt hàng %1. Được trả lại (được mua lại) nhiều hơn %2 %3 so với chuyển đi. %4.';
								|ru = 'Номенклатура %1. Возвращается (выкупается) больше на %2 %3, чем передано. %4.';
								|en = 'Items %1. Returned (redeemed) more by %2 %3, than transferred. %4.'; fa = 'Items %1. Returned (redeemed) more by %2 %3, than transferred. %4.';
								|it = 'Articolo %1. Viene reso (riscattato) per un numero superiore di %2 %3, rispetto a quello trasferito. %4.';
								|pl = 'Nomenklatura %1. Powraca (zostaje odkupiona) więcej o %2 %3, niż przekazano. %4.';
								|tr = 'Öğe %1. Transfer edilenden daha fazla %2 %3 iade ediliyor (itfa ediliyor). %4.'");
		
		For Each ErrorString In ControlResults.ErrorsTransferredReturnContainers Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(ErrorString.Products,
				ErrorString.Characteristic);
			
			DimensionTransfers_ = New Array;
			
			If ValueIsFilled(ErrorString.DocumentTransfers_) Then 
				TransferAnalyticsLine = StrTemplate(NStr("vi = 'Chứng từ: %1';
														|ru = 'Документ: %1';
														|en = 'Document: %1'; fa = 'Document: %1';
														|it = 'Documento: %1';
														|pl = 'Dokument: %1';
														|tr = 'Belge: %1'"), ErrorString.DocumentTransfers_);
				DimensionTransfers_.Add(TransferAnalyticsLine);
			EndIf;
			
			If ValueIsFilled(ErrorString.InventoryOwnerAttribute) Then
				TransferAnalyticsLine = StrTemplate(NStr("vi = 'Dạng hàng tồn kho: %1';
														|ru = 'Вид запасов: %1';
														|en = 'Inventory owner attributes: %1'; fa = 'Inventory owner attributes: %1';
														|it = 'Tipo di scorte: %1';
														|pl = 'Rodzaj pozycji: %1';
														|tr = 'Stok sahibinin öznitelikleri: %1'"), ErrorString.InventoryOwnerAttribute);
				DimensionTransfers_.Add(TransferAnalyticsLine);
			EndIf;
			
			If ValueIsFilled(ErrorString.CCDNumber) Then
				TransferAnalyticsLine = StrTemplate(NStr("vi = 'Số TKHQ: %1';
														|ru = 'Номер ГТД: %1';
														|en = 'CCD number: %1'; fa = 'CCD number: %1';
														|it = 'Numero di dichiarazione doganale: %1';
														|pl = 'Numer ŁDC: %1';
														|tr = 'Gümrük Kargo Beyannamesi numarası: %1'"), ErrorString.CCDNumber);
				DimensionTransfers_.Add(TransferAnalyticsLine);
			EndIf;
			
			If ErrorString.DepositIsRequired Then
				DimensionTransfers_.Add(NStr("vi = 'Đang thế chấp';
											|ru = 'Под залог';
											|en = 'Against security'; fa = 'Against security';
											|it = 'In garanzia';
											|pl = 'Za kaucją';
											|tr = 'Kefalet altında'"));
			EndIf;
			
			TransferAnalyticsLine = StrConcat(DimensionTransfers_, ", ");
			
			MessageText = StrTemplate(MessageTemplate, ProductPresentation,
				-ErrorString.Count, ErrorString.UnitOfMeasure, TransferAnalyticsLine);
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region GoodsTransferredToToller
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementGoodsTransferredToProcessorChange") Then
		
			MessageTemplate = NStr("vi = 'Mặt hàng %1
				|Đã vượt quá số dư nguyên vật liệu đã chuyển giao cho người nhận gia công là %2 %3';
				|ru = 'Номенклатура %1
				|Превышен остаток сырья и материалов переданных переработчику на %2 %3';
				|en = 'Items %1
				|Remaining raw and consumable materials transferred to the subcontractor are exceeded by %2 %3'; fa = 'Items %1
				|Remaining raw and consumable materials transferred to the subcontractor are exceeded by %2 %3';
				|it = 'Articolo %1
				| Superata la rimanenza di materie prime e materiali trasferiti al subfornitore per %2%3';
				|pl = 'Nomenklatura %1
				|Został przekroczony limit pozostałości surowca i materiałów przekazanych przetwórcy o %2 %3';
				|tr = 'Öğe %1
				|fason üreticiye transfer edilen hammadde ve malzeme bakiyesinin %2 %3 oranında aşılması'");
		
		For Each ErrorString In ControlResults.ErrorsGoodsTransferredToProcessor Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(ErrorString.Products,
				ErrorString.Characteristic);
			
			MessageText = StrTemplate(MessageTemplate, ProductPresentation,
				-ErrorString.Count ,ErrorString.UnitOfMeasure);
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#EndRegion