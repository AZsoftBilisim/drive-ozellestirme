//////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Commission sales"
// related to the business operation "Return from the commissionaire".
// 
//////////////////////////////////////////////////////////////////
//

#Region Public

#Region UnifiedMethodsForBusinessOperations

#Region FillType

// Returns the sales condition
//
// Parameters:
//  Terms - CatalogRef.TermsOfSale - 
//
// Returns:
//  See SalesServer.GetTermsAndConditionsOfSale
//
Function GetTermsAndConditionsOfSale(Terms) Export

	Return SalesServer.GetTermsAndConditionsOfSale(Terms);

EndFunction

// Returns a list of details by which tables are compared when filling in orders/orders
// 
// Returns:
// 	String
//
Function KeyFieldsOfGoodsTable() Export
	
	Return "Products, Characteristic, ProductsRecordingAsReceived, CharacteristicRecordingAsReceived, Purpose, Series";
	
EndFunction

#EndRegion

#Region Posting

// Returns parameters for filling in inventory types for the document "Receipt of goods from the custodian".
//
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian
//
// Returns:
//  See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	Var FillParameters;
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	FillParameters.SelectionOfStockTypes_.Organization = Object.Organization;
	
	FillParameters.SelectionOfStockTypes_.InventoryType  = New Array;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ConsignedGoods);
	
	Return FillParameters;

EndFunction

// Adds an additional property for monitoring when conducting
// 
// Parameters:
//  Object - DocumentObject.ReceiptOfGoodsFromCustodian - 
//
Procedure AddAdditionalPropertyToControlWhenConducting(Object) Export
	
	If Not Object.ByReferences Then
		Object.RegisterRecords.CompanyGoods.AdditionalProperties.Insert("CreateSummaryTableProductsOfOrganizations");
	EndIf;
	
EndProcedure

#EndRegion

#Region Rounding

// Fills in the Shopbill and need to Round attributes in the table rows
// 
// Parameters:
//  Object - FormDataStructure - table being processed
//  
Procedure FillInShopPantryAttributeInTable(Object) Export
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.Goods,, Object.Warehouse);
	
EndProcedure

// Recalculates the number of units
//
// Parameters:
//  Object - FormDataStructure - 
//
Procedure RecalculateNumberOfUnits(Object) Export
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionRecalculateNumberOfUnits(StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

// Adds the actions "Fill in the sign of the checkbook"
//
// Parameters:
//  StructureOfActions - Structure - 
//  Warehouse - CatalogRef.Warehouses - 
//
Procedure AddFillInActionForShopPantryAttribute(StructureOfActions, Warehouse) Export
	
	StructureOfActions.Insert("FillInShopPantryAttribute", New Structure("WarehouseValue_", Warehouse));
	
EndProcedure

// Adds the action "Recalculate the number of units"
//
// Parameters:
//  StructureOfActions - Structure - 
//
Procedure AddActionRecalculateNumberOfUnits(StructureOfActions) Export
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits());
	
EndProcedure

// Returns the parameters for recalculating the client units
//
// Returns:
//  Undefined - 
//
Function ParametersForRecalculatingNumberOfUnits() Export
	
	Return Undefined;
	
EndFunction

// Returns the parameters for rounding
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses - 
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding(Warehouse) Export
	
	Return New Structure("Goods");
	
EndFunction

#EndRegion

#Region QueriesTexts

//Returns the text of the request data for input validation based on
//
// Returns:
//  String - 
//
Function QueryTextDataForInputValidationBasedOn() Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(
	"SELECT
	|	ReferenceOrder.Ref AS Basis,
	|	ReferenceOrder.Status AS Status,
	|	FALSE AS RegistrationViaRM,
	|	CASE
	|		WHEN ReferenceOrder.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE ReferenceOrder.Warehouse
	|	END               AS Warehouse,
	|	ReferenceOrder.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS ReferenceOrder
	|WHERE
	|	ReferenceOrder.Ref IN(&References)
	|
	|UNION ALL
	|
	|SELECT
	|	ReferenceOrder.Ref AS Basis,
	|	UNDEFINED        AS Status,
	|	FALSE AS RegistrationViaRM,
	|	CASE
	|		WHEN ReferenceOrder.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE ReferenceOrder.Warehouse
	|	END               AS Warehouse,
	|	ReferenceOrder.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.TransferOfGoodsToBailee AS ReferenceOrder
	|WHERE
	|	ReferenceOrder.Ref IN(&References)
	|");
	
	QueriesTexts.Add(
	"SELECT TOP 1
	|	1
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Products_From_Orders
	|WHERE
	|	Products_From_Orders.Ref IN(&References)
	|	AND NOT Products_From_Orders.Canceled
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS Products_From_Orders
	|WHERE
	|	Products_From_Orders.Ref IN(&References)
	|");
	
	QueriesTexts.Add(
		AccumulationRegisters.GoodsToReceive.QueryTextBalance(
			"TTBalancesForRegistration",
			New Structure("DocumentInflow", "References"),
			"ToRegister <> 0"));
	
	QueriesTexts.Add(
	"SELECT
	|	Set.ReferenceOrder AS InstructionsForRegistration
	|FROM
	|	(SELECT
	|		RequirementsForRegistration_1.ReferenceOrder AS ReferenceOrder
	|	FROM
	|		TTBalancesForRegistration AS RequirementsForRegistration_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref AS ReferenceOrder
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref IN (&References)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentTable.Ref AS ReferenceOrder
	|	FROM
	|		Document.TransferOfGoodsToBailee AS DocumentTable
	|	WHERE
	|		DocumentTable.Ref IN (&References)
	|	) AS Set
	|
	|GROUP BY
	|	Set.ReferenceOrder
	|");
	
	Return StrConcat(QueriesTexts, Common.QueryBatchSeparator());

EndFunction

//Returns the request text invoice filling data
//
// Returns:
//  String - 
//
Function QueryTextInvoiceFillingData() Export
	
	QueryText =
	"SELECT
	|	&BusinessOperation AS BusinessOperation,
	|	OrderDocument.Ref.Organization AS Organization,
	|	OrderDocument.Ref.Department AS Department,
	|	CASE
	|		WHEN OrderDocument.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrderDocument.Ref.Warehouse
	|	END AS Warehouse,
	|	OrderDocument.Ref.SalesOpportunity AS SalesOpportunity,
	|	OrderDocument.Ref.Partner AS Partner,
	|	OrderDocument.Ref.Counterparty AS Counterparty,
	|	OrderDocument.Ref.Terms AS Terms,
	|	OrderDocument.Ref.Contract AS Contract,
	|	OrderDocument.Ref.LineOfBusiness AS LineOfBusiness,
	|	OrderDocument.Ref.Currency AS Currency,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderDocument.PriceKind) = 1
	|			THEN MAX(OrderDocument.PriceKind)
	|		ELSE VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END AS PriceKind,
	|	OrderDocument.Ref.ReturnOfSpoiledGoods AS ReturnOfSpoiledGoods
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS OrderDocument
	|WHERE
	|	OrderDocument.Ref = &OrderDocument
	|GROUP BY
	|	OrderDocument.Ref,
	|	OrderDocument.Ref.Organization,
	|	OrderDocument.Ref.Department,
	|	CASE
	|		WHEN OrderDocument.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE OrderDocument.Ref.Warehouse
	|	END,
	|	OrderDocument.Ref.SalesOpportunity,
	|	OrderDocument.Ref.Partner,
	|	OrderDocument.Ref.Counterparty,
	|	OrderDocument.Ref.Terms,
	|	OrderDocument.Ref.Contract,
	|	OrderDocument.Ref.LineOfBusiness,
	|	OrderDocument.Ref.Currency,
	|	OrderDocument.Ref.ReturnOfSpoiledGoods
	|
	|UNION ALL
	|
	|SELECT
	|	&BusinessOperation AS BusinessOperation,
	|	Transfer_.Ref.Organization AS Organization,
	|	Transfer_.Ref.Department AS Department,
	|	CASE
	|		WHEN Transfer_.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE Transfer_.Ref.Warehouse
	|	END AS Warehouse,
	|	Transfer_.Ref.SalesOpportunity AS SalesOpportunity,
	|	Transfer_.Ref.Partner AS Partner,
	|	Transfer_.Ref.Counterparty AS Counterparty,
	|	Transfer_.Ref.Terms AS Terms,
	|	Transfer_.Ref.Contract AS Contract,
	|	Transfer_.Ref.LineOfBusiness AS LineOfBusiness,
	|	Transfer_.Ref.Currency AS Currency,
	|	CASE
	|		WHEN COUNT(DISTINCT Transfer_.PriceKind) = 1
	|			THEN MAX(Transfer_.PriceKind)
	|		ELSE VALUE(Catalog.TypesOfPrices.EmptyRef)
	|	END AS PriceKind,
	|	FALSE AS ReturnOfSpoiledGoods
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS Transfer_
	|WHERE
	|	Transfer_.Ref = &OrderDocument
	|GROUP BY
	|	Transfer_.Ref,
	|	Transfer_.Ref.Organization,
	|	Transfer_.Ref.Department,
	|	CASE
	|		WHEN Transfer_.Ref.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE Transfer_.Ref.Warehouse
	|	END,
	|	Transfer_.Ref.SalesOpportunity,
	|	Transfer_.Ref.Partner,
	|	Transfer_.Ref.Counterparty,
	|	Transfer_.Ref.Terms,
	|	Transfer_.Ref.Contract,
	|	Transfer_.Ref.LineOfBusiness,
	|	Transfer_.Ref.Currency";

	Return QueryText;
	
EndFunction

//Returns the text of the goods request of the order document
//
// Parameters:
//  Filter - Map - 
//  SupplementSeriesTable - Boolean -
//
// Returns:
//  String - Query text
//
Function RequestTextAndOrderDocument(Filter, SupplementSeriesTable = False) Export
	
	QueryText =
		Documents.RequestForReturnOfGoodsFromCustomer.QueryTextDocumentGoods(
			Filter,
		JoinText(False, True),
			SupplementSeriesTable);
	
	Return QueryText;
	
EndFunction

//Returns the text of the request for the transferred goods
//
// Returns:
//  String - 
//
Function QueryTextGoodsTransferred() Export

	Return Documents.ReceiptOfGoodsFromCustodian.QueryTextGoodsTransferred();

EndFunction

// Returns the text of the connection between the tables "Table" and "Accounting data"
// 
//  Parameters:
//  UseCCDNumber - Boolean -
//  KeepAccountingByBatch - Boolean -  
//
// Returns:
//  String - 
//
Function JoinText(UseCCDNumber = True, KeepAccountingByBatch = False) Export

	JoinText = " Table.Ref = DataOfAccounting.ReferenceOrder
		| AND Table.Products = DataOfAccounting.Products
		| AND Table.Characteristic = DataOfAccounting.Characteristic
		| AND Table.Purpose = DataOfAccounting.Purpose";
		
	If UseCCDNumber Then
		
		JoinText = JoinText + "
			| AND Table.CCDNumber = DataOfAccounting.CCDNumber";
			
	EndIf;
	
	If KeepAccountingByBatch Then
		
		JoinText = JoinText + "
			| AND Table.Series = DataOfAccounting.Series";
			
	EndIf;

	Return JoinText;

EndFunction

#Region TextsOfRequestsToFillInListOfOrders

// Returns the text of the request for orders available in the invoice.
// 
// Parameters:
//  RequestTextParameters - See TMCommonUse.ParametersOfRequestTextForOrdersInvoices
//
// Returns:
//  String - request text
//
Function QueryTextWaybillOrders(RequestTextParameters) Export
	
	TMCommonUse.AddSelectionItemToCollection(
		RequestTextParameters.Filter,
		"TableOfOrders.Warehouse",
		"&Warehouse",
		"=");
	
	Return Documents.RequestForReturnOfGoodsFromCustomer.RequestTextForOrdersInvoices(RequestTextParameters);
	
EndFunction

// Returns the text of the request for instructions for registration
//
// Returns:
//  String - request text
//
Function QueryTextInstructionsForRegistration() Export

	Return AccumulationRegisters.GoodsToReceive.QueryTextInstructionsForRegistration();

EndFunction

// Returns the text of the request for goods orders for registration
//
// Returns:
//  String - request text
//
Function QueryTextRemnantsOfGoodsForRegistration(TempTableName, FilterByDimensions = Undefined) Export
	
	If FilterByDimensions = Undefined Then
		FilterByDimensions = New Map;
	EndIf;
	
	QueryText =
		AccumulationRegisters.GoodsToReceive.QueryTextBalance(
			TempTableName,
			FilterByDimensions,
			"ToRegister > 0");
	
	QueryText = RequestSchemes.AddSelectionFieldToQuery(QueryText, "0", "RowCode");
	QueryText = RequestSchemes.SetIndexingOfQueryFields(QueryText, "Products, Characteristic");
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for duplicates of goods orders for registration
//
// Returns:
//  String - request text
//
Function QueryTextDuplicatesOfProductsForRegistration() Export
	
	Return
	"SELECT
	|	COUNT(*)                    AS DuplicateCount,
	|	GoodsForRegistration.Products   AS Products,
	|	GoodsForRegistration.Characteristic AS Characteristic
	|INTO DuplicatesOfProductsForRegistration
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|
	|GROUP BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic
	|";
	
EndFunction

#EndRegion

#EndRegion

#Region ReferenceOrder

// Returns an array of order types
//
// Returns:
//  Array of Type -
//
Function TypesOfProducts_() Export
	
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	
	Return TypesArray;
	
EndFunction

// Returns the name of the order register
//
// Returns:
//  String - 
//
Function RegisterNameOrder() Export
	
	Return "GoodsToReceive";
	
EndFunction

// Returns the name of the dimension of the remainder register that is used as an order
//
// Returns:
//  String - 
//
Function NameDimensionOrder() Export
	
	Return "DocumentInflow";
	
EndFunction

// Returns the use of string code attribute
//
// Returns:
//  Boolean - 
//
Function UseLineCode() Export
	
	Return False;
	
EndFunction

// Returns the synonym of the order.
//
// Returns:
//  String - synonym of the order.
//
Function SynonymForOrder() Export
	
	Return NStr("vi = 'Giấy đề nghị trả hàng từ người nhận ký gửi';
				|ru = 'Заявка на возврат товаров от комиссионера';
				|en = 'Consignment pick-up request'; fa = 'درخواست برداشت امانی';
				|it = 'Dichiarazione di reso articoli dal commissionario';
				|pl = 'Wniosek o zwrot towarów od komisanta';
				|tr = 'Konsinyeden ürünlerin iadesi için başvuru'");
	
EndFunction

#EndRegion

#Region DiscrepancyCertificate

// Returns the type of the basis of the act of discrepancy
//
// Returns:
//  EnumRef.TypesOfBaseDocumentsForDiscrepancyReport
//
Function TypeOfBasisOfAct() Export
	
	Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent;
	
EndFunction

// Returns the postfix of the name of the discrepancy report
//
// Returns:
//  String - 
//
Function ActNamePostfix() Export
	
	Return NStr("vi = 'sau khi tiếp nhận hàng hóa từ người nhận ký gửi';
				|ru = 'после поступления товаров от комиссионера';
				|en = 'after goods receipt from the consignee'; fa = 'after goods receipt from the consignee';
				|it = 'dopo la ricezione articoli dal commissionario';
				|pl = 'po przyjęciu towarów od komisanta';
				|tr = 'konsinyeden irsaliye sonrası'");
	
EndFunction

// Returns the title of the discrepancy report form when creating
//
// Returns:
//  String - 
//
Function TitleOfReportCreationForm() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận hàng hóa từ người nhận ký gửi (tạo mới)';
				|ru = 'Акт о расхождениях после поступления товаров от комиссионера (создание)';
				|en = 'Discrepancy report following goods receipt from consignee (create)'; fa = 'Discrepancy report following goods receipt from consignee (create)';
				|it = 'Atto sulle discrepanze dopo la ricezione articoli dal commissionario (creazione)';
				|pl = 'Protokół o odchyleniu po wpływie towarów od komisanta (tworzenie)';
				|tr = 'Konsinyeden irsaliye sonrası tutarsızlık raporu (oluşturma)'");
	
EndFunction

// Returns the title of the discrepancy report form
//
// Returns:
//  String - 
//
Function ReportFormHeader() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận hàng hóa từ người nhận ký gửi';
				|ru = 'Акт о расхождениях после поступления товаров от комиссионера';
				|en = 'Discrepancy report following goods receipt from consignee'; fa = 'Discrepancy report following goods receipt from consignee';
				|it = 'Atto sulle discrepanze dopo la ricezione di articoli dal commissionario';
				|pl = 'Protokół o odchyleniu po wpływie towarów od komisanta';
				|tr = 'Konsinyeden irsaliye sonrası tutarsızlık raporu'");
	
EndFunction

// Returns the hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ReportAgreementHint() Export
	
	Return NStr("vi = 'Hợp đồng mà có lập chứng từ tiếp nhận';
				|ru = 'Договор, в рамках которого оформлено поступление';
				|en = 'Contract under which the receiving is registered'; fa = 'Contract under which the receiving is registered';
				|it = 'Accordo in base al quale è stata formalizzata la ricezione';
				|pl = 'Umowa, w której wydano zezwolenie';
				|tr = 'Girişin düzenlenmesi kapsamındaki sözleşme'");
	
EndFunction

// Returns a hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ActAgreementHint() Export
	
	Return NStr("vi = 'Thỏa thuận mà hàng hóa được chuyển giao.';
				|ru = 'Соглашение, по которому был передан товар.';
				|en = 'Agreement under which the goods have been transferred.'; fa = 'Agreement under which the goods have been transferred.';
				|it = 'Accordo in base al quale è stata consegnata la merce.';
				|pl = 'Umowa, na mocy której towary zostały przekazane.';
				|tr = 'Ürünlerin transfer edildiği anlaşma.'");
	
EndFunction

// Returns the title of the document base
//
// Returns:
//  String - 
//
Function TitleOfDocumentGroundsOfAct() Export
	
	Return NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi';
				|ru = 'Поступление от комиссионера';
				|en = 'Receipt from consignee'; fa = 'دریافت از امانت‌دار';
				|it = 'Ricezione dal commissionario';
				|pl = 'Przyjęcie od komisanta';
				|tr = 'Konsinyeden gelen giriş'");
	
EndFunction

// Returns the title based on
//
// Parameters:
//  AddPartner - Boolean -
//
// Returns:
//  String - 
//
Function HeadlineOnGrounds(AddPartner = True) Export
	
	If AddPartner Then
		Return NStr("vi = 'Theo tiếp nhận từ người nhận ký gửi';
					|ru = 'По поступлениям от комиссионера';
					|en = 'By receipts from consignee'; fa = 'By receipts from consignee';
					|it = 'Per ricezioni dal commissionario';
					|pl = 'Według przyjęć od komisanta';
					|tr = 'Konsinyeden girişlere göre'");
	Else
		Return NStr("vi = 'Theo tiếp nhận';
					|ru = 'По поступлениям';
					|en = 'By receipts'; fa = 'بر اساس دریافت‌ها';
					|it = 'Secondo gli arrivi';
					|pl = 'Wg wpływów';
					|tr = 'Tahsilatlara göre'");
	EndIf;
	
EndFunction

//Returns a description of the field with comments
//
// Returns:
//  String - 
//
Function BasementVendorComment() Export
	
	Return NStr("vi = 'Ghi chú của người nhận ký gửi về chênh lệch trong dòng';
				|ru = 'Комментарии комиссионера по расхождениям в строке';
				|en = 'Consignee comments on line discrepancies'; fa = 'Consignee comments on line discrepancies';
				|it = 'Commenti del commissionario per discrepanze nella riga';
				|pl = 'Uwagi komisanta odnośnie do odchylenia w wierszu';
				|tr = 'Satırdaki tutarsızlıklara ilişkin konsinye yorumları'");
	
EndFunction

//Returns the name of the column, who gives the comment
//
// Returns:
//  String - 
//
Function CustomerComment() Export
	
	Return NStr("vi = 'người nhận ký gửi';
				|ru = 'комиссионера';
				|en = 'consignee'; fa = 'consignee';
				|it = 'commissionario';
				|pl = 'consignee';
				|tr = 'konsinye'");
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business operation of the document.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function BusinessOperation() Export
	
	Return Enums.BusinessTransactions.ReturnFromCommissionAgent;
	
EndFunction

// Returns the business transaction of the contract.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToCommissionAgent;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with suppliers
//
// Returns:
//  Boolean - 
//
Function AgreementsWithSuppliersAreApplicable() Export
	
	Return True;
	
EndFunction

// Returns a sign of the applicability of agreements with clients
//
// Returns:
//  Boolean - 
//
Function CustomerAgreementsAreApplicable() Export
	
	Return True;
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return GetFunctionalOption("ToUseTermsOfSales");

EndFunction

// Returns the use of a request for the return of goods from customers attribute
//
// Returns:
//  Boolean -
//
Function UseOrders() Export
	
	Return GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");

EndFunction

// Returns the attribute using receipts for multiple orders.
//
// Returns:
//  Boolean -
//
Function UseReceiptForMultipleOrders() Export

	Return False;

EndFunction

// Returns the attribute using the advanced features of the customer's order
//
// Returns:
//  Boolean -
//
Function UseAdvancedFeaturesOfSalesOrder() Export
	
	Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
EndFunction

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//    Object                         - FormDataStructure, DocumentObject - The object from which the main parameters for the search will be taken.
//    CurrencySelection_2                  - Boolean - Search by the specified settlement currency of the Contract you are looking for (True) or
//												without taking into account the settlement currency (False).
//    FilterByLineOfBusiness - Boolean - Conduct a search in the specified area of activity of the desired Contract (True) or
//												in all directions (False).
//
// Returns:
//    CatalogRef.CounterpartyContracts - the default counterparty agreement.
//
Function GetDefaultContract(Object, CurrencySelection_2 = True, FilterByLineOfBusiness = True) Export
	
	BusinessOperation = ContractBusinessTransaction();
	
	Currency = Undefined;
	If CurrencySelection_2 Then
		Currency = Object.Currency;
	EndIf;
	
	LineOfBusiness = Undefined;
	If FilterByLineOfBusiness
	   And GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	Contract = SalesServer.GetDefaultContract(Object, BusinessOperation, Currency, LineOfBusiness, True);
	
	Return Contract;
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	Items = Form.Items;
	Items.Contract.Enabled = True;
	Items.Contract.Visible = True;
	
EndProcedure

// Adjusts the form.
//
// Parameters:
//  Form - ClientApplicationForm - Contains:
//           * Items - FormAllItems - Contains:
//              ** Partner - TextBox - Contains:
//                  *** Title - String -
//              ** GoodsSelectTransferredGoods - FormCommand - Contains:
//                  *** Title - String -
//              ** CloseRequest - FormCommand - Contains:
//                  *** Title - String -
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	Object    = Form.Object;
	
	Form.AutoTitle = False;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);
	
	Form.HeaderOfSubmittedProductSelectionForm = NStr("vi = 'Chọn hàng hóa đã chuyển giao cho người nhận ký gửi';
														|ru = 'Подбор товаров, переданных комиссионеру';
														|en = 'Pick consignment sales stock'; fa = 'انتخاب موجودی فروش امانی';
														|it = 'Selezione articoli trasferiti al commissionario';
														|pl = 'Wybór towarów, przekazanych komisantowi';
														|tr = 'Konsinyeye transfer edilen ürünlerin seçimi'");

	Items.Partner.Title                         = NStr("vi = 'Người nhận ký gửi';
														|ru = 'Комиссионер';
														|en = 'Consignee'; fa = 'امانت‌دار';
														|it = 'Commissionario';
														|pl = 'Consignee';
														|tr = 'Konsinye'");
	Items.GoodsSelectTransferredGoods.Title = "";
	Items.PagesOrder.Visible                   = UseOrders();
	Items.ByReference.Title                  = NStr("vi = 'Theo giấy đề nghị';
													|ru = 'По заявке';
													|en = 'By request'; fa = 'بر اساس درخواست';
													|it = 'Per richiesta';
													|pl = 'Wg zamówienia';
													|tr = 'Talebe göre'");
	Items.ByReferences.Title                 = NStr("vi = 'Theo giấy đề nghị';
													|ru = 'По заявкам';
													|en = 'By requests'; fa = 'بر اساس درخواست‌ها';
													|it = 'Per richieste';
													|pl = 'Wg zamówień';
													|tr = 'Taleplere göre'");
	Items.CloseRequest.Title                   = NStr("vi = 'Đóng giấy đề nghị';
														|ru = 'Закрыть заявку';
														|en = 'Close request'; fa = 'بستن درخواست';
														|it = 'Chiudi la richiesta';
														|pl = 'Zamknij zgłoszenie';
														|tr = 'Talebi kapat'");
	Items.CloseApplications.Title                   = NStr("vi = 'Đóng giấy đề nghị';
															|ru = 'Закрыть заявки';
															|en = 'Close requests'; fa = 'بستن درخواست‌ها';
															|it = 'Chiudere richieste';
															|pl = 'Zamknij zgłoszenia';
															|tr = 'Başvuruları kapat'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	
	Items.PriceKind.Visible                      = True;
	Items.GoodsPrice.Visible                   = True;
	Items.GoodsSum.Visible                  = True;
	Items.GoodsFillInPricesByPriceKind.Visible = True;
	Items.GoodsFillInCCDNumbers.Visible     = Not Form.TheCommissionAgentDoesNotKeepRecordsOnTheRNPT;
	Items.GroupInTotal.Visible                  = True;
	
	Items.GoodsFillInPricesUnderAgreement.Visible = True;
	Items.ReusablePackageReturn.Visible = Object.ReusablePackageReturn;
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	Items = Form.Items;
	
	// Partner
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
			
	Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Counterparty
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo người nhận ký gửi';
																		|ru = 'По комиссионеру';
																		|en = 'By consignee'; fa = 'By consignee';
																		|it = 'Per commissionario';
																		|pl = 'Według komisanta';
																		|tr = 'Konsinye üzerine'")));
			
	Items.Counterparty.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	//Contract
	ChoiceParametersArray = New Array;
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction()));
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.ConsignmentSales25", True));


	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
		
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	//Terms
	ChoiceParametersArray = New Array;
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.ConsignmentSales25", True));
		
	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Date", "Object.Date", LinkedValueChangeMode.DontChange));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	Items.Terms.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Terms.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	If Items.Find("LineOfBusiness") <> Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		
		Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	EndIf;
	
	// Type of price
	If Not Items.Find("PriceKind") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
		
		Items.PriceKind.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	EndIf;
	
EndProcedure

// Returns the title of the document form transfer of goods to the custodian.
//
// Parameters:
//  NewDocument - Boolean - 
//  Number - Number - 
//  Date - Date - 
//
// Returns:
//  String - 
//
Function DocumentFormHeader(NewDocument, Number, Date) Export
	
	If NewDocument Then
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (creazione)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluşturma)'"), ObjectPresentation());
	Else
		Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
								|ru = '%1 %2 от %3';
								|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
								|it = '%1 %2 del %3';
								|pl = '%1 %2 z dnia %3';
								|tr = '%3 tarihli %1 %2'"), ObjectPresentation(), Number, Date);
	EndIf;
	
	Return Title;
	
EndFunction

// Returns a representation of the document receipt of goods from the custodian.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Tiếp nhận hàng hóa từ người nhận ký gửi';
				|ru = 'Поступление товаров от комиссионера';
				|en = 'Receipt of goods from consignee'; fa = 'Receipt of goods from consignee';
				|it = 'Ricezione articoli dal commissionario';
				|pl = 'Przyjęcia towarów od komisanta';
				|tr = 'Malların konsinyeden teslim alınması'");
	
EndFunction

#EndRegion

#EndRegion

#EndRegion
