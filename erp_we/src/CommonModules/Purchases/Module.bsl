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
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.PurchaseOrders);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		DocumentType = TypeOf(Document);
		
		If Not Properties.IsNew
				And (DocumentType = Type("DocumentObject.PurchaseOrder")
				Or DocumentType = Type("DocumentObject.SubcontractOrder2_5")
				Or DocumentType = Type("DocumentObject.MaterialProviderOrder2_5")
				Or DocumentType = Type("DocumentObject.ProductionStage2_2") And Document.ProductionByThirdParty
				)
			Or Properties.WriteMode = DocumentWriteMode.Posting
				And (DocumentType = Type("DocumentObject.VendorInvoice")
				Or DocumentType = Type("DocumentObject.SubcontractorReport2_5")


				Or DocumentType = Type("DocumentObject.ReceiptOfGoodsFromCustodian")
					And Document.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
				Or DocumentType = Type("DocumentObject.GoodsReceiptForStorage"))
			Or DocumentCorrection.ThisIsCorrectiveDocument(Document) Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.PurchaseOrders);
		EndIf;

		If Properties.WriteMode = DocumentWriteMode.Posting
			And (DocumentType = Type("DocumentObject.ConsignmentReportToVendor") 
			Or DocumentType = Type("DocumentObject.PurchaseInvoiceConsignmentStockLost")
			) Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal);
		EndIf;
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal);
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.PurchaseOrders;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of purchases.
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
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "PurchaseOrders");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ServicesForRegistrationOfReportsToPrincipal");
	
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
	MatchingQueryTexts.Insert("RequirementsOfServiceForPreparationOfReportsToPrincipalChange", 
		AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal.RequestTextMonitoringBanDate(Query));
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
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfOrdersToSuppliersChange") Then
		
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
			Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
		
		If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
			
			QueryText =
				"SELECT
				|	BalanceTable.PurchaseOrder                AS OrderDocument,
				|	BalanceTable.Products                   AS Products,
				|	BalanceTable.Products.UnitOfMeasure  AS UnitOfMeasure,
				|	BalanceTable.Characteristic                 AS Characteristic,
				|	BalanceTable.Warehouse                          AS Warehouse,
				|	BalanceTable.ToRegisterBalance             AS ToRegister,
				|	BalanceTable.ToReceiveBalance            AS ToReceive
				|FROM
				|	AccumulationRegister.PurchaseOrders.Balance(,
				|			(PurchaseOrder, Products, Characteristic, Warehouse) IN
				|				(SELECT
				|					Table.PurchaseOrder,
				|					Table.Products,
				|					Table.Characteristic,
				|					Table.Warehouse
				|				FROM
				|					MovementOfOrdersToSuppliersChange AS Table)
				|	) AS BalanceTable
				|WHERE
				|	BalanceTable.ToRegisterBalance < 0
				|	OR BalanceTable.ToReceiveBalance < 0
				|";
			
		Else
			
			QueryText = 
				"SELECT
				|	OrdersBalance.PurchaseOrder                AS OrderDocument,
				|	OrdersBalance.Products                   AS Products,
				|	OrdersBalance.Products.UnitOfMeasure  AS UnitOfMeasure,
				|	OrdersBalance.Characteristic                 AS Characteristic,
				|	OrdersBalance.Warehouse                          AS Warehouse,
				|	OrdersBalance.ToRegisterBalance             AS ToRegister,
				|	OrdersBalance.ToReceiveBalance            AS ToReceive
				|FROM
				|	TTOrdersToSuppliersBalance AS OrdersBalance
				|	LEFT JOIN
				|		TTAcceptableDeviationsOrdersToSuppliers AS AcceptableDeviations
				|		ON
				|			OrdersBalance.PurchaseOrder  = AcceptableDeviations.PurchaseOrder
				|			AND OrdersBalance.Products   = AcceptableDeviations.Products
				|			AND OrdersBalance.Characteristic = AcceptableDeviations.Characteristic
				|			AND OrdersBalance.Warehouse          = AcceptableDeviations.Warehouse
				|WHERE
				|	OrdersBalance.ToRegisterBalance + ISNULL(AcceptableDeviations.AllowableVariance,0) < 0
				|	OR OrdersBalance.ToReceiveBalance + ISNULL(AcceptableDeviations.ToleranceForAdmission,0) < 0
				|";
			
		EndIf;
		
		QueryTexts.Add(QueryText, "ErrorsOrdersToSuppliers");
		
	EndIf;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RequirementsOfServiceForPreparationOfReportsToPrincipalChange") Then
		
			QueryText =
				"SELECT
				|	BalanceTable.Organization AS Organization,
				|	BalanceTable.ItemsLocationAttributes AS ItemsLocationAttributes,
				|	BalanceTable.ItemsLocationAttributes.Products AS Products,
				|	BalanceTable.ItemsLocationAttributes.Products.UnitOfMeasure  AS UnitOfMeasure,
				|	BalanceTable.ItemsLocationAttributes.Characteristic AS Characteristic,
				|	BalanceTable.ItemsLocationAttributes.Series AS Series,
				|	BalanceTable.Terms AS Terms,
				|	BalanceTable.Terms.Partner AS Consignor,
				|	BalanceTable.Currency AS Currency,
				|	BalanceTable.CountBalance AS Count,
				|	BalanceTable.RevenueAmountBalance AS RevenueAmount,
				|	BalanceTable.VATAmountBalance AS VATAmount
				|FROM
				|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Balance(
				|			,
				|			(Organization, ItemsLocationAttributes, Terms, Currency) IN
				|				(SELECT
				|					Table.Organization,
				|					Table.ItemsLocationAttributes,
				|					Table.Terms,
				|					Table.Currency
				|				FROM
				|					RequirementsOfServiceForPreparationOfReportsToPrincipalChange AS Table)) AS BalanceTable
				|WHERE
				|	(BalanceTable.CountBalance < 0
				|			OR BalanceTable.RevenueAmountBalance < 0
				|			OR BalanceTable.VATAmountBalance < 0)";

		QueryTexts.Add(QueryText, "RequirementsOfServiceForPreparationOfReportsToPrincipal");
			
	EndIf;
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementOfOrdersToSuppliersChange") Then
		
		WarehouseMessageTemplate = NStr("vi = 'Mặt hàng %1, kho %2
			|Đã lập nhiều hơn số lượng chỉ ra trong lệnh %3 là %4%5';
			|ru = 'Номенклатура %1, склад %2
			|Оформлено больше, чем указано в распоряжении %3, на %4 %5';
			|en = 'Item %1, warehouse %2
			|Registered more than specified in reference %3 by %4 %5'; fa = 'Item %1, warehouse %2
			|Registered more than specified in reference %3 by %4 %5';
			|it = 'Номенклатура %1, склад %2
			|Оформлено больше, чем указано в распоряжении %3, на %4 %5';
			|pl = 'Item %1, warehouse %2
			|Registered more than specified in reference %3 by %4 %5';
			|tr = 'Öğe %1, ambar %2
			| %3siparişinde belirtilenden %4 %5 kadar fazla kaydedildi'");
			
		MessageTemplateWithoutWarehouse = NStr("vi = 'Mặt hàng %1
			|Đã lập nhiều hơn số lượng đã chỉ ra trong lệnh %3 là %4 %5';
			|ru = 'Номенклатура %1
			|Оформлено больше, чем указано в распоряжении %3, на %4 %5';
			|en = 'Item %1
			|Registered more than specified in reference %3 by %4 %5'; fa = 'Item %1
			|Registered more than specified in reference %3 by %4 %5';
			|it = 'Номенклатура %1
			|Оформлено больше, чем указано в распоряжении %3, на %4 %5';
			|pl = 'Item %1
			|Registered more than specified in reference %3 by %4 %5';
			|tr = 'Öğe %1
			| %3siparişinde belirtilenden %4%5 kadar fazla kaydedildi'");
		
		For Each ErrorString In ControlResults.ErrorsOrdersToSuppliers Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
				ErrorString.Products, ErrorString.Characteristic);
			
			If ValueIsFilled(ErrorString.ToRegister) Then
				Count = -ErrorString.ToRegister;
			Else
				Count = -ErrorString.ToReceive;
			EndIf;
			
			If ValueIsFilled(ErrorString.Warehouse) Then
				MessageText = StrTemplate(WarehouseMessageTemplate, ProductPresentation, ErrorString.Warehouse,
					ErrorString.OrderDocument, Count, ErrorString.UnitOfMeasure);
			Else
				MessageText = StrTemplate(MessageTemplateWithoutWarehouse, ProductPresentation,,
					ErrorString.OrderDocument, Count, ErrorString.UnitOfMeasure);
			EndIf;
			
			CommonClientServer.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RequirementsOfServiceForPreparationOfReportsToPrincipalChange") Then
		
		MessageTemplateWithVAT = NStr("vi = 'Đối với doanh nghiệp, %1 không đủ để hoàn thành %2%3 cho số tiền%4%5 và số tiền thuế GTGT %6 %7dịch vụ: %8, đối tác có %9';
										|ru = 'По организации %1 не хватает к оформлению %2 %3 на сумму %4 %5 и сумму НДС %6 %7 услуг: %8, у партнера %9';
										|en = 'There is a lack of registration of %2 %3 for the amount of %4 %5 and VAT amount of %6 %7 of services: %8, at the %9 partner by the %1 company '; fa = 'There is a lack of registration of %2 %3 for the amount of %4 %5 and VAT amount of %6 %7 of services: %8, at the %9 partner by the %1 company ';
										|it = 'There is a lack of registration of %2 %3 for the amount of %4 %5 and VAT amount of %6 %7 of services: %8, at the %9 partner by the %1 company ';
										|pl = 'There is a lack of registration of %2 %3 for the amount of %4 %5 and VAT amount of %6 %7 of services: %8, at the %9 partner by the %1 company ';
										|tr = '%1 iş yeri kapsamında, %4 %5 tutarındaki ve %6 %7 KDV tutarındaki %2 %3 hizmetin düzenlenmesi için yeterli değildir: %8, iş ortağındaki %9'");
		MessageTemplateWithoutVAT = NStr("vi = 'Đối với doanh nghiệp, %1 không đủ để hoàn thành %2%3 cho số tiền%4%5 dịch vụ:%6, đối tác có%7';
										|ru = 'По организации %1 не хватает к оформлению %2 %3 на сумму %4 %5 услуг: %6, у партнера %7';
										|en = 'There is a lack of registration of %2%3 for the amount of %4%5services: %6at the partner %7 by company %1'; fa = 'There is a lack of registration of %2%3 for the amount of %4%5services: %6at the partner %7 by company %1';
										|it = 'Per l''azienda %1 non sono stati emessi %2 %3 per l''importo %4 %5 per servizi: %6, del partner %7';
										|pl = 'Wg firmy %1 nie wystarcza do sporządzenia %2 %3 na kwotę %4 %5 usług: %6, u partnera %7';
										|tr = '%1 iş yerinde %2 %3 kaydı için %4 %5 tutarında hizmet mevcut değil hizmetler: %6, iş ortağı %7'");
		
		For Each ErrorString In ControlResults.RequirementsOfServiceForPreparationOfReportsToPrincipal Do
			
			ProductPresentation = ProductsClientServer.ProductPresentation(ErrorString.Products,
				ErrorString.Characteristic,, ErrorString.Series);
				
			If ErrorString.VATAmount < 0 Then
				
				MessageText = StrTemplate(MessageTemplateWithVAT, ErrorString.Organization, -ErrorString.Count, ErrorString.UnitOfMeasure, -ErrorString.RevenueAmount, ErrorString.Currency,
					-ErrorString.VATAmount,
					ErrorString.Currency,
					ProductPresentation,
					ErrorString.Consignor);
			Else
				
				MessageText = StrTemplate(MessageTemplateWithoutVAT, ErrorString.Organization, -ErrorString.Count, ErrorString.UnitOfMeasure, -ErrorString.RevenueAmount, ErrorString.Currency,
					ProductPresentation,
					ErrorString.Consignor);
				
			EndIf;
			
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
