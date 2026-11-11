#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.GoodsForRegistrationOfImportDocuments);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.GoodsForRegistrationOfApplicationForImportFromEEUCountries);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.GoodsForRegistrationOfImportDocuments);
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.GoodsForRegistrationOfApplicationForImportFromEEUCountries);
		
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
		
	RegisterMetadata = Metadata.AccumulationRegisters.GoodsForRegistrationOfImportDocuments;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.GoodsForRegistrationOfApplicationForImportFromEEUCountries;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then	
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the register.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "GoodsForRegistrationOfImportDocuments");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "GoodsForRegistrationOfApplicationForImportFromEEUCountries");
	
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
//  QueryTexts - ValueList of String- list of query texts and their names.
//  Document - DocumentObject, Structure - the document being recorded contains:
//  	* AdditionalProperties - Structure:
//  		** DocumentsPosting - Structure:
//  			*** DocumentProperties - FixedStructure:
//  				**** IsNew - Boolean
//  				**** WriteMode - DocumentWriteMode
//  				**** PostingMode - DocumentPostingMode
//  				**** Posted - Boolean
//  			*** ControlTables - Structure:
//  				**** MovementOfGoodsOfOrganizationsChange - Structure:
//  					***** ThereAreRecordsInTable - Boolean
//  					***** Parameters - Structure:
//  						****** MinimumPeriod - Date
//  		** PreparationOfGoodsForRegistrationOfImportDocumentsChange - Arbitrary
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region GoodsForRegistrationOfImportDocuments
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "PreparationOfGoodsForRegistrationOfImportDocumentsChange") Then
		
		QueryText =
			"SELECT
			|	DATETIME(1,1,1) 											AS Period,
			|	BalanceTable.Organization 								AS Organization,
			|	BalanceTable.Vendor 									AS Vendor,
			|	BalanceTable.DocumentInflow 						AS DocumentInflow,
			|	BalanceTable.ItemsLocationAttributes.Products 	AS Products,
			|	BalanceTable.ItemsLocationAttributes.Characteristic 	AS Characteristic,
			|	BalanceTable.ItemsLocationAttributes.StorageLocation 	AS Warehouse,
			|	BalanceTable.ItemsLocationAttributes.Products.UnitOfMeasure AS UnitOfMeasure,
			|	BalanceTable.ItemsLocationAttributes.Series 			AS Series,
			|	BalanceTable.InventoryOwnerAttribute 									AS InventoryOwnerAttribute,
			|	BalanceTable.ImportDocumentType 						AS ImportDocumentType,
			|	BalanceTable.SumBalance 								AS Sum,
			|	BalanceTable.CountBalance 							AS Count,
			|	CAST(BalanceTable.QuantityByGBRNBalance AS NUMBER(23, 11)) 	AS QuantityByGBRN
			|FROM
			|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(,
			|			(Organization, Vendor, DocumentInflow, ItemsLocationAttributes, InventoryOwnerAttribute, ImportDocumentType) IN
			|				(SELECT
			|					Table.Organization,
			|					Table.Vendor,
			|					Table.DocumentInflow,
			|					Table.ItemsLocationAttributes,
			|					Table.InventoryOwnerAttribute,
			|					Table.ImportDocumentType
			|				FROM
			|					PreparationOfGoodsForRegistrationOfImportDocumentsChange AS Table)
			|	) AS BalanceTable
			|		LEFT JOIN Document.SigningOfLeaseContract AS DocumentOfConclusionOfContractOfLease 
			|		ON BalanceTable.DocumentInflow = DocumentOfConclusionOfContractOfLease.Ref
			|
			|WHERE
			|	(BalanceTable.CountBalance < 0 OR BalanceTable.QuantityByGBRNBalance < 0)
			|	AND DocumentOfConclusionOfContractOfLease.Ref IS NULL
			|
			|UNION ALL
			|
			|SELECT
			|	BalanceTable.Period										AS Period,
			|	BalanceTable.Organization 								AS Organization,
			|	BalanceTable.Vendor 									AS Vendor,
			|	BalanceTable.DocumentInflow 						AS DocumentInflow,
			|	BalanceTable.ItemsLocationAttributes.Products 	AS Products,
			|	BalanceTable.ItemsLocationAttributes.Characteristic 	AS Characteristic,
			|	BalanceTable.ItemsLocationAttributes.StorageLocation 	AS Warehouse,
			|	BalanceTable.ItemsLocationAttributes.Products.UnitOfMeasure AS UnitOfMeasure,
			|	BalanceTable.ItemsLocationAttributes.Series 			AS Series,
			|	BalanceTable.InventoryOwnerAttribute 									AS InventoryOwnerAttribute,
			|	BalanceTable.ImportDocumentType 						AS ImportDocumentType,
			|	BalanceTable.SumTurnover 								AS Sum,
			|	0															AS Count,
			|	0															AS QuantityByGBRN
			|FROM
			|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.BalanceAndTurnovers(
			|			,
			|			,
			|			Month,
			|			,
			|			(Organization, Vendor, ItemsLocationAttributes, InventoryOwnerAttribute, DocumentInflow, ImportDocumentType) IN
			|				(SELECT
			|					Table.Organization,
			|					Table.Vendor,
			|					Table.ItemsLocationAttributes,
			|					Table.InventoryOwnerAttribute,
			|					Table.DocumentInflow,
			|					Table.ImportDocumentType
			|				FROM
			|					PreparationOfGoodsForRegistrationOfImportDocumentsChange AS Table)
			|			AND ImportDocumentType = &IdApplicationForImportOfGoods) AS BalanceTable
			|		INNER JOIN Document.SigningOfLeaseContract AS DocumentOfConclusionOfContractOfLease
			|		ON BalanceTable.DocumentInflow = DocumentOfConclusionOfContractOfLease.Ref
			|WHERE
			|	BalanceTable.SumTurnover < 0
			|";
			
		Query.SetParameter("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods"));
		QueryTexts.Add(QueryText, "ErrorsInPreparationOfImportDocuments");
		
	EndIf;
	
	#EndRegion
	
	#Region GoodsForRegistrationOfApplicationForImportFromEEUCountries
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "GoodsForRegistrationOfApplicationForImportFromEEUCountriesUpdate") Then
		
		QueryText =
			"SELECT
			|	BalanceTable.DocumentInflow           AS DocumentInflow,
			|	BalanceTable.Products                  AS Products,
			|	BalanceTable.Characteristic                AS Characteristic,
			|	BalanceTable.Series                         AS Series,
			|	BalanceTable.Products.UnitOfMeasure AS UnitOfMeasure,
			|	BalanceTable.Warehouse                         AS Warehouse,
			|	BalanceTable.ToRegisterBalance            AS ToRegister
			|FROM
			|	AccumulationRegister.GoodsForRegistrationOfApplicationForImportFromEEUCountries.Balance(
			|			,
			|			(DocumentInflow, Products, Characteristic, Series, Warehouse) IN
			|				(SELECT
			|					Table.DocumentInflow,
			|					Table.Products,
			|					Table.Characteristic,
			|					Table.Series,
			|					Table.Warehouse
			|				FROM
			|					GoodsForRegistrationOfApplicationForImportFromEEUCountriesUpdate AS Table)) AS BalanceTable
			|WHERE
			|	BalanceTable.ToRegisterBalance < 0";
		
		QueryTexts.Add(QueryText, "ErrorsGoodsForProcessingImportApplications");
		
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
	
	#Region GoodsForRegistrationOfImportDocuments
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "PreparationOfGoodsForRegistrationOfImportDocumentsChange") Then
		
		MessageTemplateWithoutReceipt = NStr("vi = 'Mặt hàng %1
			|Số lượng hàng hóa cần lập không tương ứng với số lượng trong chứng từ tiếp nhận đối với %2 %3';
			|ru = 'Номенклатура %1
			|Количество товара к оформлению не соответствует количеству в документе поступления на %2 %3';
			|en = 'Item %1
			|The quantity of goods to register is not equal to the quantity in the receipt document by %2 %3'; fa = 'Item %1
			|The quantity of goods to register is not equal to the quantity in the receipt document by %2 %3';
			|it = 'Nomenclatura %1
			| La quantità di merce in formalizzazione non corrisponde alla quantità nel documento di ricezione di %2%3';
			|pl = 'Produkt %1
			|Ilość towaru do rejestracji nie jest zgodna z ilością w dokumencie wpływu na %2 %3';
			|tr = 'Öğe %1
			|Kaydedilecek ürün miktarı, giriş belgesindeki miktarla uyuşmuyor %2 %3'");
		ReceiptMessageTemplate = MessageTemplateWithoutReceipt + " " + NStr("vi = '(xem chứng từ %4)';
																			|ru = '(см. документ %4)';
																			|en = '(see the %4 document)'; fa = '(see the %4 document)';
																			|it = '(vedi documento %4)';
																			|pl = '(zob. dokument %4)';
																			|tr = '(belgeye bak %4)'");
		
		MessageTemplateWithoutReceiptRent = NStr("vi = 'Số tiền dịch vụ cần tạo không tương ứng với số tiền trong chứng từ tiếp nhận đối với %1 %2';
												|ru = 'Сумма услуг к оформлению не соответствует сумме в документе поступления на %1 %2';
												|en = 'Service amount to register is not equal to the amount in the receipt document by %1 %2'; fa = 'Service amount to register is not equal to the amount in the receipt document by %1 %2';
												|it = 'L''importo dei servizi in formalizzazione non corrisponde all''importo nel documento di ricezione di %1 %2';
												|pl = 'Wartość usług do rejestracji nie jest zgodna z wartością w dokumencie wpływu na %1 %2';
												|tr = 'Kaydedilecek hizmetlerin tutarı giriş belgesindeki tutarla %1 %2 oranında uyuşmuyor'");
		TemplateForRentalReceiptMessage = MessageTemplateWithoutReceiptRent + " " + NStr("vi = '(xem chứng từ %3)';
																						|ru = '(см. документ %3)';
																						|en = '(see the %3 document)'; fa = '(see the %3 document)';
																						|it = '(vedi documento %3)';
																						|pl = '(zob. dokument %3)';
																						|tr = '(belgeye bak %3)'");
		
		For Each ErrorString In ControlResults.ErrorsInPreparationOfImportDocuments Do
			If TypeOf(ErrorString.DocumentInflow) = Type("DocumentRef.SigningOfLeaseContract") Then 

				If ValueIsFilled(ErrorString.DocumentInflow) Then
					MessageText = StrTemplate(TemplateForRentalReceiptMessage,
						-ErrorString.Sum, ErrorString.UnitOfMeasure, ErrorString.DocumentInflow);
				Else
					MessageText = StrTemplate(MessageTemplateWithoutReceiptRent,
						-ErrorString.Sum, ErrorString.UnitOfMeasure);
				EndIf;
				
			Else
				ProductPresentation = ProductsClientServer.ProductPresentation(ErrorString.Products,
					ErrorString.Characteristic);
				
				If ValueIsFilled(ErrorString.DocumentInflow) Then
					MessageText = StrTemplate(ReceiptMessageTemplate, ProductPresentation,
						-ErrorString.Count, ErrorString.UnitOfMeasure, ErrorString.DocumentInflow);
				Else
					MessageText = StrTemplate(MessageTemplateWithoutReceipt, ProductPresentation,
						-ErrorString.Count, ErrorString.UnitOfMeasure);
				EndIf;
			EndIf;
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region GoodsForRegistrationOfApplicationForImportFromEEUCountries
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "GoodsForRegistrationOfApplicationForImportFromEEUCountriesUpdate") Then
		
		MessageTemplateWithoutReceipt = NStr("vi = 'Mặt hàng %1
			|Số lượng hàng hóa cần lập không tương ứng với số lượng trong chứng từ tiếp nhận đối với %2 %3';
			|ru = 'Номенклатура %1
			|Количество товара к оформлению не соответствует количеству в документе поступления на %2 %3';
			|en = 'Item %1
			|The quantity of goods to register is not equal to the quantity in the receipt document by %2 %3'; fa = 'Item %1
			|The quantity of goods to register is not equal to the quantity in the receipt document by %2 %3';
			|it = 'Nomenclatura %1
			| La quantità di merce in formalizzazione non corrisponde alla quantità nel documento di ricezione di %2%3';
			|pl = 'Produkt %1
			|Ilość towaru do rejestracji nie jest zgodna z ilością w dokumencie wpływu na %2 %3';
			|tr = 'Öğe %1
			|Kaydedilecek ürün miktarı, giriş belgesindeki miktarla uyuşmuyor %2 %3'");
		ReceiptMessageTemplate = MessageTemplateWithoutReceipt + " " + NStr("vi = '(xem chứng từ %4)';
																			|ru = '(см. документ %4)';
																			|en = '(see the %4 document)'; fa = '(see the %4 document)';
																			|it = '(vedi documento %4)';
																			|pl = '(zob. dokument %4)';
																			|tr = '(belgeye bak %4)'");
		
		For Each ErrorString In ControlResults.ErrorsGoodsForProcessingImportApplications Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(ErrorString.Products,
				ErrorString.Characteristic);
				
			If ValueIsFilled(ErrorString.DocumentInflow) Then
				MessageText = StrTemplate(ReceiptMessageTemplate, ProductPresentation,
					-ErrorString.ToRegister, ErrorString.UnitOfMeasure, ErrorString.DocumentInflow);
			Else
				MessageText = StrTemplate(MessageTemplateWithoutReceipt, ProductPresentation,
					-ErrorString.ToRegister, ErrorString.UnitOfMeasure);
			EndIf;
			
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Supplements the request to reflect the document by reflecting the registration of the import of goods from the Customs Union.
// The operation generates movements according to the register of the product formalizationvocation.
//
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextProducts_1 - String - The text of the receipt request from the purchase document.
// 	    The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization in which the import of goods from the customs Union is reflected.
// 	     * Counterparty - CatalogRef.Counterparties - Counterparty-supplier of goods.
// 	     * DocumentAcquisitions - DefinedType.TaxInvoice - Link to the document of purchase of goods.
// 	    Imported goods.
// 	     * Products - CatalogRef.Products - Imported item.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the imported nomenclature item.
// 	     * Series - CatalogRef.ItemsBatches - A series of imported nomenclature items.
// 	     * Count - Number - Quantity of imported goods.
// 	     * RowID - String, UUID - ID of the purchase document line.
// 	    analytics of accounting for imported goods.
// 	     * Warehouse - CatalogRef.Warehouses - The warehouse where the goods are purchased.
// 	     * ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - Product accounting analytics key.
//
Procedure ReflectImportOfGoodsFromCustomsUnion(Query, QueryTexts, Registers, TextProducts_1) Export
	
	If Not Query.Parameters.Property("ProductProductTypes") Then
		Query.SetParameter("ProductProductTypes", VATAccountingERPInternal.ProductProductTypes());
	EndIf;
	
	TextGoodsForProcessingImportApplications =
	"SELECT
	|	Goods.Ref                          AS Recorder,
	|	Goods.Period                          AS Period,
	|	Goods.Warehouse                           AS Warehouse,
	|	Goods.DocumentAcquisitions            AS DocumentInflow,
	|	Goods.Products                    AS Products,
	|	Goods.Characteristic                  AS Characteristic,
	|	Goods.Series                           AS Series,
	|	Goods.Count                      AS ToRegister,
	|	Goods.RowID             AS RowID,
	|	DocumentAmounts_.AmountExcludingVAT            AS TaxInvoicedPrice
	|FROM
	|	#Goods AS Goods
	|	LEFT JOIN
	|		Catalog.Counterparties AS Counterparties
	|	ON
	|		Goods.Counterparty = Counterparties.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Goods.Ref = DocumentAmounts_.Ref
	|		AND Goods.RowID = DocumentAmounts_.RowID
	|WHERE
	|	Goods.Products.ItemsType IN (&ProductProductTypes)
	|";
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("GoodsForRegistrationOfApplicationForImportFromEEUCountries", Registers) Then 
		ReflectionTemplateTexts.Insert("GoodsForRegistrationOfApplicationForImportFromEEUCountries", TextGoodsForProcessingImportApplications);
	EndIf;
	If ReflectionTemplateTexts.Count() > 0 Then
		ManagerOfDocument = Common.ObjectManagerByRef(Query.Parameters.Ref);
		ManagerOfDocument.GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("Goods", TextProducts_1);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
EndProcedure

// Supplements the request to reflect the document by reflecting the registration of the import of goods from the Customs Union.
// The operation generates movements according to the register of the goods formationdocumentsimport.
//
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextProducts_1 - String - The text of the receipt request from the purchase document.
// 	     The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization in which the import of goods from the customs Union is reflected.
// 	     * Counterparty - CatalogRef.Counterparties - Counterparty-supplier of goods.
// 	     * DocumentAcquisitions - DefinedType.TaxInvoice - Link to the document of purchase of goods.
// 	    Imported goods.
// 	     * Products - CatalogRef.Products - Imported item.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the imported nomenclature item.
// 	     * Series - CatalogRef.ItemsBatches - A series of imported nomenclature items.
// 	     * Count - Number - Quantity of imported goods.
// 	     * RowID - String, UUID - ID of the purchase document line.
// 	    analytics of accounting for imported goods.
// 	     * Warehouse - CatalogRef.Warehouses- The warehouse where the goods are purchased.
// 	     * ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - Product accounting analytics key.
//
Procedure ReflectImportOfGoodsFromCustomsUnionNewMechanics(Query, QueryTexts, Registers, TextProducts_1) Export
	
	If Not Query.Parameters.Property("ProductProductTypes") Then
		Query.SetParameter("ProductProductTypes", VATAccountingERPInternal.ProductProductTypes());
	EndIf;
	
	TextGoodsForRegistrationOfImportDocuments =
	"SELECT
	|	Goods.RecordType                     AS RecordType,
	|	Goods.Ref                          AS Recorder,
	|	Goods.Period                          AS Period,
	|	Goods.Organization                     AS Organization,
	|	Goods.Vendor                       AS Vendor,
	|	Goods.ItemsLocationAttributes      AS ItemsLocationAttributes,
	|	Goods.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	Goods.DocumentAcquisitions            AS DocumentInflow,
	|	Goods.ImportDocumentType             AS ImportDocumentType,
	|	Goods.Count                      AS Count,
	|	Goods.QuantityByGBRN                AS QuantityByGBRN,
	|	Goods.Sum			               AS Sum,
	|	Goods.CCDNumber                        AS CCDNumber,
	|	Goods.RowID             AS RowID,
	|	TRUE								   AS Primary
	|FROM
	|	#Goods AS Goods
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON Goods.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref	   
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON InventoryLocationAttributeKeys.Products = CatProducts.Ref
	|
	|WHERE
	|	CatProducts.ItemsType IN (&ProductProductTypes)
	|	AND Goods.Sum <> 0
	|";
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("GoodsForRegistrationOfImportDocuments", Registers) Then 
		ReflectionTemplateTexts.Insert("GoodsForRegistrationOfImportDocuments", TextGoodsForRegistrationOfImportDocuments);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("Goods", TextProducts_1);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
