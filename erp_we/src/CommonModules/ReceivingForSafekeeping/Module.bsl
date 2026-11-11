
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
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ReceivedReturnablePackaging);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		DocumentType = TypeOf(Document);
		
		If Properties.WriteMode = DocumentWriteMode.Posting
				And (DocumentType = Type("DocumentObject.ReturnOfGoodsToVendor")
					Or DocumentType = Type("DocumentObject.RedemptionOfReturnablePackagingFromVendor")
					Or DocumentType = Type("DocumentObject.OBEntryGoods")
					Or DocumentType = Type("DocumentObject.OBEntry")
					Or DocumentType = Type("DocumentObject.PurchaseAdjustment"))
			Or Not Properties.IsNew
				And (DocumentType = Type("DocumentObject.VendorInvoice")
				) 
			Or DocumentCorrection.ThisIsCorrectiveDocument(Document) Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.ReceivedReturnablePackaging);
		EndIf;
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor);
		
	EndIf;
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.ReceivedReturnablePackaging);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor);
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.ReceivedReturnablePackaging;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
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
	MatchingQueryTexts.Insert("RegisteredRecordsAcceptedReturnPackagingChange", 
		AccumulationRegisters.ReceivedReturnablePackaging.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableGoodsToBeRegisteredInReportsToConsignor", 
		AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of reception on responsible storage.
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
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ReceivedReturnablePackaging");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "GoodsToBeRegisteredInReportsToConsignor");
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region ReceivedReturnablePackaging
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsAcceptedReturnPackagingChange") Then
		
		QueryText =
			"SELECT
			|	BalanceTable.Partner                        AS Partner,
			|	BalanceTable.Products                   AS Products,
			|	BalanceTable.Products.UnitOfMeasure  AS UnitOfMeasure,
			|	BalanceTable.Characteristic                 AS Characteristic,
			|	BalanceTable.DocumentInflow            AS DocumentInflow,
			|	BalanceTable.DepositIsRequired              AS DepositIsRequired,
			|	BalanceTable.CountBalance              AS Count,
			|	BalanceTable.SumBalance                   AS Sum
			|FROM
			|	AccumulationRegister.ReceivedReturnablePackaging.Balance(,
			|			(Partner, Products, Characteristic, DocumentInflow, DepositIsRequired) IN
			|				(SELECT
			|					Table.Partner,
			|					Table.Products,
			|					Table.Characteristic,
			|					Table.DocumentInflow,
			|					Table.DepositIsRequired
			|				FROM
			|					RegisteredRecordsAcceptedReturnPackagingChange AS Table)
			|	) AS BalanceTable
			|
			|WHERE
			|	BalanceTable.CountBalance < 0";
		
		QueryTexts.Add(QueryText, "ErrorsAcceptedReturnPackaging");
		
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
	
	#Region ReceivedReturnablePackaging
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsAcceptedReturnPackagingChange") Then
		
		TemplateForMessageWithDocumentWithCollateral = NStr("vi = 'Mặt hàng %1. Được trả lại (được mua lại) nhiều hơn mức chấp nhận theo chứng từ %2 theo đặt cọc %3 %4';
															|ru = 'Номенклатура %1. Возвращается (выкупается) больше, чем принято по документу %2 под залог на %3 %4';
															|en = 'Items %1. Number of returned (purchased) items exceeds the number of received ones under the document%2 against security by %3 %4'; fa = 'Items %1. Number of returned (purchased) items exceeds the number of received ones under the document%2 against security by %3 %4';
															|it = 'Articolo %1. Viene reso (riscattato) per quantità superiore, rispetto a quello accettato dietro cauzione in base al documento %2 di %3 %4';
															|pl = 'Nomenklatura %1. Powraca (zostaje odkupiona) więcej, niż przyjęto w dokumencie %2 pod zastaw o %3 %4';
															|tr = 'Öğe %1. %3 %4 kefalet altında %2 belgesinde kabul edilenden daha fazla iade edilen (itfa edilen)'");
		TemplateForMessageWithDocumentWithoutCollateral = NStr("vi = 'Mặt hàng %1. Được trả lại (được mua lại) nhiều hơn mức chấp nhận theo chứng từ %2 theo %3 %4';
																|ru = 'Номенклатура %1. Возвращается (выкупается) больше, чем принято по документу %2 на %3 %4';
																|en = 'Items %1. Number of returned (purchased) items exceeds the number of received ones under the document%2 by %3 %4'; fa = 'Items %1. Number of returned (purchased) items exceeds the number of received ones under the document%2 by %3 %4';
																|it = 'Articolo %1. Viene reso (riscattato) per quantità superiore, rispetto a quello accettato in base al documento %2 di %3 %4';
																|pl = 'Nomenklatura %1. Powraca (zostaje odkupiona) więcej, niż przyjęto w dokumencie %2 o %3 %4';
																|tr = 'Öğe %1%3 %4 kadar %2 belgesinde kabul edilenden daha fazla iade edildi (geri alındı)'");
		
		MessageTemplateWithoutDocumentWithCollateral = NStr("vi = 'Mặt hàng %1. Được trả lại (được mua lại) nhiều hơn mức đặt cọc bởi %3 %4';
															|ru = 'Номенклатура %1. Возвращается (выкупается) больше, чем принято под залог на %3 %4';
															|en = 'Items %1. Number of returned (purchased) items exceeds the number of received ones against security by %3 %4'; fa = 'Items %1. Number of returned (purchased) items exceeds the number of received ones against security by %3 %4';
															|it = 'Articolo %1. Viene reso (riscattato) per quantità superiore, rispetto a quello accettato dietro cauzione di %3 %4';
															|pl = 'Nomenklatura %1. Powraca (zostaje odkupiona) więcej, niż przyjęto pod zastaw o %3 %4';
															|tr = 'Öğe %1. %3 %4 kadar kefalete alınan daha fazlası iade edildi (itfa ediliyor)'");
		MessageTemplateWithoutDocumentWithoutCollateral = NStr("vi = 'Mặt hàng %1. Được trả lại (được mua lại) nhiều hơn mức chấp nhận %3 %4';
																|ru = 'Номенклатура %1. Возвращается (выкупается) больше, чем принято на %3 %4';
																|en = 'Items %1. Number of returned (purchased) items exceeds the number of received ones by %3 %4'; fa = 'Items %1. Number of returned (purchased) items exceeds the number of received ones by %3 %4';
																|it = 'Articolo %1. Viene reso (riscattato) per quantità superiore, rispetto a quello accettato di %3 %4';
																|pl = 'Nomenklatura %1. Powraca (zostaje odkupiona) więcej, niż przyjęto o %3 %4';
																|tr = 'Öğe %1. %3 %4 kadar kabul edilenden daha fazla iade edildi (itfa ediliyor)'");
		
		For Each ErrorString In ControlResults.ErrorsAcceptedReturnPackaging Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(ErrorString.Products,
				ErrorString.Characteristic);
			
			If ValueIsFilled(ErrorString.DocumentInflow) Then
				If ErrorString.DepositIsRequired Then
					MessageTemplate = TemplateForMessageWithDocumentWithCollateral;
				Else
					MessageTemplate = TemplateForMessageWithDocumentWithoutCollateral;
				EndIf;
			Else
				If ErrorString.DepositIsRequired Then
					MessageTemplate = MessageTemplateWithoutDocumentWithCollateral;
				Else
					MessageTemplate = MessageTemplateWithoutDocumentWithoutCollateral;
				EndIf;
			EndIf;
			
			MessageText = StrTemplate(MessageTemplate, ProductPresentation,
				ErrorString.DocumentInflow, -ErrorString.Count ,ErrorString.UnitOfMeasure);
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

#EndRegion

#EndRegion