////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Processing on the side"
// related to the economic operation "Transfer to the processor".
// 
////////////////////////////////////////////////////////////////
//

#Region Public

#Region UnifiedMethods

#Region FillType

// Returns the text of the request to fill in the document on the basis of the order to the processor.
//
// Returns:
//  String -
//
Function TextOfRequestToFillInOrderForm() Export
	
	QueryText =
	"SELECT
	|	OrderDocument.Ref                                                  AS SalesOrder,
	|	VALUE(Enum.BusinessTransactions.TransferToToller2_5) AS BusinessOperation,
	|	OrderDocument.Status                                                  AS DocumentStatus,
	|	OrderDocument.Partner                                                 AS Partner,
	|	OrderDocument.Counterparty                                              AS Counterparty,
	|	VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) AS CounterpartyBankAccount,
	|	VALUE(Catalog.TermsOfSale.EmptyRef)        AS Terms,
	|	OrderDocument.Organization                                             AS Organization,
	|	OrderDocument.BankAccount                                          AS CompanyBankAccount,
	|	OrderDocument.Contract                                                 AS Contract,
	|	VALUE(Catalog.Warehouses.EmptyRef)                      AS Warehouse,
	|	FALSE                                                          AS AdvancedWarehousingOnShipment,
	|	FALSE                                                          AS ItIsForbiddenToSelectWarehouseGroup,
	|	OrderDocument.Currency                                                  AS Currency,
	|	VALUE(Catalog.Counterparties.EmptyRef)                 AS Shipper,
	|	VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) AS ShipperBankAccount,
	|	VALUE(Catalog.Counterparties.EmptyRef)                 AS GoodsRecipient,
	|	VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) AS GoodsRecipientBankAccount,
	|	OrderDocument.DateOfShipment                                            AS DateOfShipment,
	|	OrderDocument.NotShipInInstallments                                      AS NotShipInInstallments,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.DeliveryMethod
	|	END                                                         AS DeliveryMethod,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.CarrierPartner
	|	END                                                         AS CarrierPartner,
	|	OrderDocument.DeliveryAddress                                           AS DeliveryAddress,
	|	OrderDocument.DeliveryAddressFieldValues                              AS DeliveryAddressFieldValues,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.DeliveryZone
	|	END                                                         AS DeliveryZone,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.DeliveryTimeFrom
	|	END                                                         AS DeliveryTimeFrom,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.DeliveryTimeTo
	|	END                                                         AS DeliveryTimeTo,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.AdditionalDeliveryInformation
	|	END                                                         AS AdditionalDeliveryInformation,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.SpecialTransportationConditions
	|	END                                                         AS SpecialTransportationConditions,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			THEN OrderDocument.SpecialTransportationConditionsDescription
	|	END                                                         AS SpecialTransportationConditionsDescription,
	|	OrderDocument.SalesOpportunity                                                  AS SalesOpportunity,
	|	OrderDocument.Department                                           AS Department,
	|	OrderDocument.ContactPerson                                          AS ContactPerson,
	|	OrderDocument.LineOfBusiness                                 AS LineOfBusiness,
	|	OrderDocument.PriceIncludesVAT                                         AS PriceIncludesVAT,
	|	FALSE                                                          AS ToReturnReusablePackage,
	|	0                                                             AS ReusablePackageReturnCycleLength,
	|	VALUE(Catalog.BusinessCalendars.EmptyRef)   AS ScheduleOfPackageReturn,
	|	FALSE                                                          AS CalculatePackageReturnDateAccordingToCalendar,
	|	FALSE                                                          AS ThisIsOrderAsInvoice,
	|	NOT OrderDocument.Posted                                             AS ThereAreErrorsPosted
	|FROM
	|	Document.SubcontractOrder2_5 AS OrderDocument
	|WHERE
	|	OrderDocument.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	ShippingOrdersTurnover.Warehouse AS Warehouse
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(,,, ReferenceOrder = &DocumentBasis) AS ShippingOrdersTurnover";

	Return QueryText;
	
EndFunction

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	Return "Partner, Counterparty, Contract, Organization, SalesOpportunity, Currency, LineOfBusiness";
	
EndFunction

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure;
	
	FillParameters.Insert("DocumentBasis",   Undefined);
	FillParameters.Insert("HeaderAttributes",      Undefined);
	
	FillParameters.Insert("Warehouse",               Undefined);
	FillParameters.Insert("OriginWarehouse",       Undefined);
	
	FillParameters.Insert("FillByWarehouseDocument",   Undefined);
	FillParameters.Insert("DesignParameters", New Structure("ByOrders, ByNotes"));
	
	FillParameters.Insert("KeyFields",        "Products, Characteristic, Series, Purpose, AssignmentSender, Warehouse");
	
	Return FillParameters;
	
EndFunction

// Initializes the structure of filling parameters based on header details and orders.
//
// Parameters:
//  FillParameters	 - See TransferToToller.DocumentFillingParameters
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.DocumentBasis = AnArrayOfOrders;
	FillParameters.HeaderAttributes	  = HeaderAttributes;
	
	FillParameters.OriginWarehouse     =
		?(ValueIsFilled(FillParameters.Warehouse), FillParameters.Warehouse, HeaderAttributes.Warehouse);
	
	If FillParameters.DesignParameters.ByNotes = Undefined Then
		
		If FillParameters.FillByWarehouseDocument = Undefined Then
			
			FillParameters.DesignParameters.ByNotes = 
				InvoicesServer.FillByWarehouseDocument(FillParameters.OriginWarehouse);
			
		Else
			
			FillParameters.DesignParameters.ByNotes = FillParameters.FillByWarehouseDocument;
			
		EndIf;
		
	EndIf;
	
	If FillParameters.DesignParameters.ByOrders = Undefined Then
		
		FillParameters.DesignParameters.ByOrders = Not FillParameters.DesignParameters.ByNotes;
		
	EndIf;
	
EndProcedure

// Creates a structure for creating an order document
//  If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray - Array - domestic consumption orders for which you need to enter an invoice.
//  OrderProperties_ - Structure, Undefined - 
//
// Returns:
//  Structure - the structure where the header details from the order array will be placed.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	HeaderAttributes = New Structure;
	
	ToContinueTheFormation = ProcessingByThirdPartiesServerCall.GenerateDataForTransferOfRawMaterials(
					ReferencesArrray, Metadata.Documents.TransferOfGoodsToBailee.Name, HeaderAttributes, OrderProperties_);
	
	If Not ToContinueTheFormation Then
		
		Messages = New Array;
		
		For Each CurMessage In GetUserMessages(True) Do
			Messages.Add(CurMessage.Text);
		EndDo;
		
		Raise StrConcat(Messages, Chars.LF);
		
	EndIf;
	
	If Not ValueIsFilled(HeaderAttributes) Then
		Return Undefined;
	EndIf;
	
	Return HeaderAttributes;
	
EndFunction

#EndRegion

#Region Posting

// Returns parameters for filling in inventory types for the document "Transfer of goods to the custodian".
// 
// Parameters:
// 	Object - DocumentObject.TransferOfGoodsToBailee
// Returns:
// 	See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	
	AvailableStockTypes = New Array;
	AvailableStockTypes.Add(Enums.InventoryTypes.OwnGoods);
	AvailableStockTypes.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	AvailableStockTypes.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	AvailableStockTypes.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	AvailableStockTypes.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	SelectionOfStockTypes_.InventoryType = AvailableStockTypes;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region Rounding

// Fills in the Shopbill and need to Round attributes in the table rows
// 
// Parameters:
//  Object - FormDataStructure - 
//  Rows - Array, Undefined - array of processed strings
//  
Procedure FillInShopPantryAttributeInTable(Object, Rows = Undefined) Export
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.Goods,,, Rows);
	
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

// Adds the actions "Fill in the sign of the account" and "Recalculate the number of units"
//
// Parameters:
//  StructureOfActions - Structure - 
//
Procedure AddFillInActionForShopPantryAttribute(StructureOfActions) Export
	
	StructureOfActions.Insert("FillInShopPantryAttribute");
	
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
//  Structure - See ProductionClientServer.ParametersForRecalculatingNumberOfUnits
//
Function ParametersForRecalculatingNumberOfUnits() Export
	
	Return ProductionClientServer.ParametersForRecalculatingNumberOfUnits();
	
EndFunction

// Returns the parameters for rounding
// 
// Returns:
//  Structure - the elements contain a structure of rounding parameters:
//   *Goods - See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding() Export
	
	TSParameters = New Structure;
	
	TSName = "Goods";
	WarehouseFieldName = "Warehouse";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
		
	Return TSParameters;

EndFunction

#EndRegion

#Region QueriesTexts

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
		"TRUE",
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS TableProvisionOfMaterialsAndWorks
		|WHERE
		|	TableProvisionOfMaterialsAndWorks.Ref = TableOfOrders.Ref
		|	AND TableProvisionOfMaterialsAndWorks.Warehouse IN HIERARCHY (&Warehouse)",
		"In");
	
	Return Documents.SubcontractOrder2_5.RequestTextForOrdersInvoices(RequestTextParameters);
	
EndFunction

#EndRegion

// Edits the text of the conversion request to the document currency
//
// Parameters:
//  QueryText - String - the editable text of the request.
//
Procedure EditTextOfRequestForConversionToDocumentCurrency(QueryText) Export
	
	ReplaceSourceOfOrderTable(QueryText);
	
EndProcedure

// Edits the text of the request for order balances
//
// Parameters:
//  QueryText - String - the editable text of the request.
//
Procedure EditRequestTextForOrderBalances(QueryText) Export
	
	//Sources
	ReplaceSourceOfProductOrderTable(QueryText);
	ReplaceSourceOfOrderTable(QueryText);
	
	// Customer Order Table
	QueryText = StrReplace(QueryText, "&CustomerOrderAgreement",                "&Terms");
	QueryText = StrReplace(QueryText, "&CustomerSOrderToReturnMultiTurnContainer", "FALSE");
	QueryText = StrReplace(QueryText, "&CustomerOrderSenderAssignment",     "OrderingProducts.Purpose");
	QueryText =
		StrReplace(
			QueryText,
			"&CustomerOrderAssignmentStage",
			"CASE
			|	WHEN NOT OrderingProducts.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
			|		AND NOT OrderingProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|		AND OrderingProducts.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
			|		THEN OrderingProducts.Purpose
			|	WHEN OrderingProducts.Ref.SubcontractOrder.TransferToSubcontractorForOrderPurpose
			|		THEN OrderingProducts.Ref.SubcontractOrder.TransferPurpose
			|	ELSE VALUE(Catalog.Assignments.EmptyRef)
			|END");
	QueryText =
		StrReplace(
			QueryText,
			"&CustomerOrderAssignment",
			"CASE
			|	WHEN NOT OrderingProducts.SupplyOption = VALUE(Enum.SupplyOptions.TransferedEarlier)
			|		AND NOT OrderingProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|		AND OrderingProducts.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
			|		THEN OrderingProducts.Purpose
			|	WHEN OrderingProducts.Ref.TransferToSubcontractorForOrderPurpose
			|		THEN OrderingProducts.Ref.TransferPurpose
			|	ELSE VALUE(Catalog.Assignments.EmptyRef)
			|END");
	
	// Product Order table
	QueryText = StrReplace(QueryText, "&OrderGoodsAmountWithVAT", "GoodsFromOrder.Sum");
	
	// The Order Items table
	QueryText = StrReplace(QueryText, "&OrderProductsSetProducts",   "VALUE(Catalog.Products.EmptyRef)");
	QueryText = StrReplace(QueryText, "&OrderGoodsSetCharacteristics", "VALUE(Catalog.ItemsCharacteristics.EmptyRef)");
	QueryText = StrReplace(QueryText, "&OrderProductsTypeOfPrice",              "OrderingProducts.Ref.PriceKind");
	QueryText = StrReplace(QueryText, "&TableBalancesAmount",             "TableBalance.Count * OrderingProducts.Price");
	
EndProcedure

// Replaces the order source with "Document.The client's order is " for " the Document.Processing order 2_5".
//
// Parameters:
//  QueryText - String - 
//
Procedure ReplaceSourceOfOrderTable(QueryText)
	
	QueryText = StrReplace(QueryText, "Document.SalesOrder", "Document.SubcontractOrder2_5");
	
EndProcedure

// Replaces the source of the goods orders with "Document.Customer's order.Goods" on " the Document.The processing order IS2_5.Provision of materials and works".
//
// Parameters:
//  QueryText - String - 
//
Procedure ReplaceSourceOfProductOrderTable(QueryText)
	
	QueryText = StrReplace(QueryText, "Document.SalesOrder.Goods", "Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks");
	
EndProcedure

#EndRegion

#Region DocumentOrderDocument

// Returns the order's access right to the processor.
//
// Parameters:
//  NameRight - String - the name of the right being checked.
//
// Returns:
//  Boolean - 
//
Function OrderAccessRights(NameRight) Export
	
	Return AccessRight(NameRight, Metadata.Documents.SubcontractOrder2_5);
	
EndFunction

// Returns the order document manager to the processor (2.5)
//
// Returns:
//  DocumentManager.SalesOrder - 
//
Function OrderManager() Export
	
	Return Documents.SubcontractOrder2_5;
	
EndFunction

// Returns the description of the type for the order to the processor
// 
// Returns:
//  TypeDescription - 
//
Function OrderTypeDescription() Export
	
	Return New TypeDescription("DocumentRef.SubcontractOrder2_5");
	
EndFunction

// Returns the type for the order to the processor
// 
// Returns:
//  Type - 
//
Function OrderType_5() Export
	
	Return Type("DocumentRef.SubcontractOrder2_5");
	
EndFunction

// Returns the synonym of the order.
//
// Returns:
//  String - synonym of the order.
//
Function SynonymForOrder() Export
	
	Return NStr("vi = 'Đơn đặt hàng gia công';
				|ru = 'Заказ переработчику';
				|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
				|it = 'Ordine al subfornitore';
				|pl = 'Zamówienie do przetwórcy';
				|tr = 'Fason satın alma siparişi'");
	
EndFunction

#EndRegion

#Region DiscrepancyCertificate

// Returns the type of the basis of the act of discrepancy
//
// Returns:
//  EnumRef.TypesOfBaseDocumentsForDiscrepancyReport
//
Function TypeOfBasisOfAct() Export
	
	Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor;
	
EndFunction

// Returns a sign of the registration of the return document through the document of the act of discrepancy
//
// Returns:
//  Boolean - 
//
Function IssueRefundOfAct() Export
	
	Return False;
	
EndFunction

// Returns the postfix of the name of the discrepancy report
//
// Returns:
//  String - 
//
Function ActNamePostfix() Export
	
	Return NStr("vi = 'sau khi chuyển giao nguyên liệu cho người nhận gia công';
				|ru = 'после передачи сырья переработчику';
				|en = 'following ""Goods issue — Subcontracting services received""'; fa = 'following ""Goods issue — Subcontracting services received""';
				|it = 'dopo il trasferimento delle materie prime all''elaboratore';
				|pl = 'po przekazaniu surowców przetwórcy';
				|tr = 'hammaddelerin fason üreticiye transferinden sonra'");
	
EndFunction

// Returns the title of the discrepancy report form when creating
//
// Returns:
//  String - 
//
Function TitleOfReportCreationForm() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi nhận nguyên liệu trả lại từ người nhận gia công (Tạo mới)';
				|ru = 'Акт о расхождениях после передачи сырья переработчику (Создание)';
				|en = 'Subcontractor stock fill-up discrepancy report (Create)'; fa = 'Subcontractor stock fill-up discrepancy report (Create)';
				|it = 'Atto sulle discrepanze dopo il trasferimento delle materie prima all''elaboratore (Creazione)';
				|pl = 'Protokół o odchyleniach po przekazaniu surowców przetwórcom (Tworzenie)';
				|tr = 'Hammaddelerin fason üreticiye transferinden sonraki tutarsızlık raporu (Oluşturma)'");
	
EndFunction

// Returns the title of the discrepancy report form
//
// Returns:
//  String - 
//
Function ReportFormHeader() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao nguyên liệu đi gia công';
				|ru = 'Акт о расхождениях после передачи сырья переработчику';
				|en = 'Discrepancy report following customer stock fill-up'; fa = 'Discrepancy report following customer stock fill-up';
				|it = 'Акт о расхождениях после передачи сырья переработчику';
				|pl = 'Discrepancy report following customer stock fill-up';
				|tr = 'Ham maddelerin fason üreticiye transferinden sonraki tutarsızlık raporu'");
	
EndFunction

// Returns the title of the partner of the discrepancy report
//
// Returns:
//  String - 
//
Function HeaderOfActPartner() Export
	
	Return NStr("vi = 'Bên nhận gia công';
				|ru = 'Переработчик';
				|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
				|it = 'Subfornitore';
				|pl = 'Subcontractor';
				|tr = 'Fason üretici'");
	
EndFunction

// Returns the title of the document of the basis of the act of discrepancy
//
// Returns:
//  String - 
//
Function TitleOfDocumentGroundsOfAct() Export
	
	Return NStr("vi = 'Chuyển giao cho người nhận gia công';
				|ru = 'Передача переработчику';
				|en = 'Customer stock fill-up'; fa = 'تکمیل موجودی مشتری';
				|it = 'Trasferimento al subfornitore';
				|pl = 'Przekazanie przetwórcy';
				|tr = 'Fason üreticiye transfer'");
	
EndFunction

// Returns the hint of the agreement of the act of discrepancy
//
// Returns:
//  String - 
//
Function ReportAgreementHint() Export
	
	Return NStr("vi = 'Hợp đồng mà có lập chứng từ chuyển giao';
				|ru = 'Договор, в рамках которого оформлена передача';
				|en = 'Contract under which transfer is registered'; fa = 'Contract under which transfer is registered';
				|it = 'Contratto in base al quale è stata effettuata la consegna';
				|pl = 'Umowa, na mocy której wykonywany jest transfer';
				|tr = 'Transferin düzenlenmesi kapsamındaki sözleşme'");
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business operation of the document.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function BusinessOperation() Export
	
	Return Enums.BusinessTransactions.TransferToToller2_5;
	
EndFunction

// Returns the business transaction of the contract.
//
// Parameters:
//  ThisIsProductionOfEEU - Boolean - a sign of the processor's production in the EAEU countries.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction(ThisIsProductionOfEEU = False) Export
	
	Return ProcessingByThirdParties.ContractBusinessTransaction(ThisIsProductionOfEEU);
	
EndFunction

// Returns an array of business operations orders.
//
// Parameters:
//  ThisIsProductionOfEEU - Boolean - a sign of the processor's production in the EAEU countries.
//
// Returns:
//  Array of EnumRef.BusinessTransactions -
//
Function EconomicOperationsOfOrders(ThisIsProductionOfEEU = False) Export
	
	OperationArray = New Array;
	OperationArray.Add(ContractBusinessTransaction(ThisIsProductionOfEEU));
	
	Return OperationArray;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with clients
//
// Returns:
//  Boolean - 
//
Function CustomerAgreementsAreApplicable() Export
	
	Return ProcessingByThirdParties.CustomerAgreementsAreApplicable();
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return ProcessingByThirdParties.ToUseTermsOfSales();

EndFunction

// Returns the attribute using the advanced features of the customer's order
//
// Returns:
//  Boolean -
//
Function UseAdvancedFeaturesOfSalesOrder() Export
	
	Return True;
	
EndFunction

// Returns the attribute using customer orders
//
// Returns:
//  Boolean -
//
Function UseSalesOrders() Export

	Return GetFunctionalOption("UseSubcontractOrders2_5");

EndFunction

// Returns the attribute of using the implementation for multiple orders.
//
// Returns:
//  Boolean -
//
Function UseSaleByMultipleOrders() Export

	Return True;

EndFunction

// Returns a sign of implementation in excess of the order.
// 
// Returns:
// 	Boolean
//
Function SalesInExcessOfOrder() Export
	
	Return True;
	
EndFunction

// Returns a sign of deviation from the terms of sale.
// 
// Returns:
// 	Boolean
//
Function VarianceFromSalesTermsAndConditions() Export
	
	Return True;
	
EndFunction

#EndRegion

#Region BasisForPrint

// Returns the base structure based on document data
// 
// Parameters:
// 	Object - FormDataStructure, DocumentObject - The object of the document for which you want to get the text of the base.
// 	
// Returns:
//  Structure - LongDesc:
//   * Basis - String - Presentation
//   * ReferenceDocumentDateForPrintForms - Date - Date
//   * BaseDocumentNumber - String - Number
//
Function StructureOfBaseForPrinting(Object) Export
	
	BaseStructure = BaseStructure(Object);
	
	If ValueIsFilled(Object.Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "Date, Number");
	EndIf;
	
	TextBase = "";
	If ValueIsFilled(BaseStructure.Basis) Then
		
		If ValueIsFilled(Object.Contract) Then
			TextBase = NStr("vi = 'Để gia công trên cơ sở nguyên vật liệu gia công theo hợp đồng số %1 ngày %2';
							|ru = 'В переработку на давальческой основе по договору №%1 от %2';
							|en = 'subcontracting services under agreement No.%1, %2'; fa = 'subcontracting services under agreement No.%1, %2';
							|it = 'In trasformazione in conto lavorazione in base al contratto №%1 del %2';
							|pl = 'Do przetwarzania na podstawie materiałów dostawcy zgodnie z umową nr%1 z dn. %2';
							|tr = '%2 tarihli %1 numaralı sözleşme kapsamında tedarikçi temelinde işlenmeye'");
			TextBase = StrTemplate(
								TextBase,
								String(ContractDetails_.Number),
								Format(ContractDetails_.Date, "DLF=DD"));
			
		Else
			TextBase = NStr("vi = 'để gia công trên nguyên vật liệu gia công';
							|ru = 'в переработку на давальческой основе';
							|en = 'to tolling'; fa = 'to tolling';
							|it = 'in trasformazione in conto lavorazione';
							|pl = 'do przetwarzania na podstawie materiałów dostawcy';
							|tr = 'Tedarikçi temelinde işlenmeye'");
		EndIf;
		
	    TextBase = BaseStructure.Basis + ", " + TextBase;
		
	Else
		
		If ValueIsFilled(Object.Contract) Then
			TextBase = NStr("vi = 'Để gia công trên cơ sở nguyên vật liệu gia công theo hợp đồng số %1 ngày %2';
							|ru = 'В переработку на давальческой основе по договору №%1 от %2';
							|en = 'subcontracting services under agreement No.%1, %2'; fa = 'subcontracting services under agreement No.%1, %2';
							|it = 'In trasformazione in conto lavorazione in base al contratto №%1 del %2';
							|pl = 'Do przetwarzania na podstawie materiałów dostawcy zgodnie z umową nr%1 z dn. %2';
							|tr = '%2 tarihli %1 numaralı sözleşme kapsamında tedarikçi temelinde işlenmeye'");
			TextBase = StrTemplate(
								TextBase,
								String(ContractDetails_.Number),
								Format(ContractDetails_.Date, "DLF=DD"));
		Else
			TextBase = NStr("vi = 'để gia công trên nguyên vật liệu gia công';
							|ru = 'в переработку на давальческой основе';
							|en = 'to tolling'; fa = 'to tolling';
							|it = 'in trasformazione in conto lavorazione';
							|pl = 'do przetwarzania na podstawie materiałów dostawcy';
							|tr = 'Tedarikçi temelinde işlenmeye'");
		EndIf;
		
	EndIf;
	
	BaseStructure.Basis = TextBase;
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base" attribute"
// 
// Parameters:
// 	Object - FormDataStructure, DocumentObject.ReturnOfGoodsToVendor - the document object to
// 																			 get the selection list for.
// 	
// Returns:
//  ValueTable - LongDesc:
//  * Basis - String - Presentation
//  * ReferenceDocumentDateForPrintForms - Date - Date
//  * BaseDocumentNumber - String - Number
//
Function PrintBasisTable(Object) Export
	
	If ValueIsFilled(Object.Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, "Date, Number");
	EndIf;
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object, True);
	If ValueIsFilled(BaseStructure.Basis) Then
		If ValueIsFilled(Object.Contract) Then
			BaseStructure.Basis = 
					BaseStructure.Basis 
					+ ", " 
					+ StrTemplate(NStr("vi = 'cho gia công trên nguyên vật liệu gia công theo hợp đồng số %1 ngày %2';
										|ru = 'в переработку на давальческой основе по договору №%1 от %2';
										|en = 'subcontracting services under agreement No.%1, %2'; fa = 'subcontracting services under agreement No.%1, %2';
										|it = 'in trasformazione in conto lavorazione in base al contratto №%1 del %2';
										|pl = 'do przetwarzania na podstawie materiałów dostawcy zgodnie z umową nr%1 z dn. %2';
										|tr = '%2 tarihli %1 numaralı sözleşme kapsamında tedarikçi temelinde işlenmeye'"), 
							String(ContractDetails_.Number), 
							Format(ContractDetails_.Date, "DLF=DD"));
		Else
			BaseStructure.Basis = 
					BaseStructure.Basis 
					+ ", " 
					+ NStr("vi = 'cho gia công trên nguyên vật liệu gia công';
							|ru = 'в переработку на давальческой основе';
							|en = 'to tolling'; fa = 'to tolling';
							|it = 'in trasformazione in conto lavorazione';
							|pl = 'do przetwarzania na podstawie materiałów dostawcy';
							|tr = 'tedarikçi temelinde işlenmeye'");
		EndIf; 
				
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
	EndIf;
	
	BaseStructure = BaseStructure(Object, False);
	If ValueIsFilled(BaseStructure.Basis) Then
		
		If TableOfBases_.Count() = 0 Then
			If ValueIsFilled(Object.Contract) Then
				BaseStructure.Basis = BaseStructure.Basis 
						+ ", " 
						+ StrTemplate(NStr("vi = 'cho gia công trên nguyên vật liệu gia công theo hợp đồng số %1 ngày %2';
											|ru = 'в переработку на давальческой основе по договору №%1 от %2';
											|en = 'subcontracting services under agreement No.%1, %2'; fa = 'subcontracting services under agreement No.%1, %2';
											|it = 'in trasformazione in conto lavorazione in base al contratto №%1 del %2';
											|pl = 'do przetwarzania na podstawie materiałów dostawcy zgodnie z umową nr%1 z dn. %2';
											|tr = '%2 tarihli %1 numaralı sözleşme kapsamında tedarikçi temelinde işlenmeye'"), 
							String(ContractDetails_.Number), 
							Format(ContractDetails_.Date, "DLF=DD"));
			Else
				BaseStructure.Basis = BaseStructure.Basis 
						+ ", " 
						+ NStr("vi = 'cho gia công trên nguyên vật liệu gia công';
								|ru = 'в переработку на давальческой основе';
								|en = 'to tolling'; fa = 'to tolling';
								|it = 'in trasformazione in conto lavorazione';
								|pl = 'do przetwarzania na podstawie materiałów dostawcy';
								|tr = 'tedarikçi temelinde işlenmeye'");
			EndIf;
		EndIf;
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		
	EndIf;
	
	If TableOfBases_.Count() = 0 Then
		AddedRow = TableOfBases_.Add();
		If ValueIsFilled(Object.Contract) Then
			AddedRow.Basis = StrTemplate(NStr("vi = 'Cho gia công trên nguyên vật liệu gia công theo hợp đồng số %1 ngày %2';
												|ru = 'В переработку на давальческой основе по договору №%1 от %2';
												|en = 'subcontracting services under agreement No.%1, %2'; fa = 'subcontracting services under agreement No.%1, %2';
												|it = 'In trasformazione in conto lavorazione in base al contratto №%1 del %2';
												|pl = 'Do przetwarzania na podstawie materiałów dostawcy zgodnie z umową nr%1 z dn. %2';
												|tr = '%2 tarihli %1 numaralı sözleşme kapsamında tedarikçi temelinde işlenmeye'"), 
															String(ContractDetails_.Number), 
															Format(ContractDetails_.Date, "DLF=DD"));
		Else
			AddedRow.Basis = NStr("vi = 'Cho gia công trên nguyên vật liệu gia công';
									|ru = 'В переработку на давальческой основе';
									|en = 'To tolling'; fa = 'To tolling';
									|it = 'In trasformazione in conto lavorazione';
									|pl = 'Do przetwarzania na podstawie materiałów dostawcy';
									|tr = 'Tedarikçi temelinde işlenmeye'");
		EndIf;
														
		AddedRow.ReferenceDocumentDateForPrintForms = ?(ValueIsFilled(Object.Contract), ContractDetails_.Date, ""); 
		AddedRow.BaseDocumentNumber = ?(ValueIsFilled(Object.Contract), ObjectsPrefixesClientServer.NumberForPrinting(ContractDetails_.Number), ""); 
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//  Object - FormDataStructure, DocumentObject - 
//  CurrencySelection_2 - Boolean - 
//  FilterByLineOfBusiness - Boolean - 
//
// Returns:
//  CatalogRef.CounterpartyContracts - 
//
Function GetDefaultContract(Object, CurrencySelection_2 = True, FilterByLineOfBusiness = True) Export
	
	Return ProcessingByThirdParties.GetDefaultContract(Object);
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	ProcessingByThirdParties.SetContractAvailability(Form, Object, Contract);

EndProcedure

// Adjusts the form.
//
// Parameters:
//  Form - ClientApplicationForm - Contains:
//           * Items - FormAllItems - Contains:
//              ** Partner - TextBox - Contains:
//                  *** Title - String - 
//              ** GoodsSalesOrder - TextBox - Contains:
//                  *** Title - String -
//              ** CloseOrder - CommandBarButton - Contains:
//                  *** Enabled - Boolean - 
//              ** CloseOrders_2 - CommandBarButton - Contains:
//                  *** Enabled - Boolean - 
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Form.AutoTitle = False;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);

	Items.Partner.Title            = NStr("vi = 'Bên nhận gia công';
											|ru = 'Переработчик';
											|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
											|it = 'Subfornitore';
											|pl = 'Subcontractor';
											|tr = 'Fason üretici'");
	Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn đặt hàng gia công';
										|ru = 'Заказ переработчику';
										|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
										|it = 'Ordine al subfornitore';
										|pl = 'Zamówienie do przetwórcy';
										|tr = 'Fason satın alma siparişi'");
	
	RightToChangeOrders = OrderAccessRights("Update");
	Items.CloseOrder.Enabled  = RightToChangeOrders;
	Items.CloseOrders_2.Enabled = RightToChangeOrders;
	
	Items.Terms.Visible = ToUseTermsOfSales();
	Items.GoodsFillThePricesByTermsOfSales.Visible = Items.Terms.Visible;
	Items.GoodsFillInPricesUnderAgreement.Visible   = False;
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	ProcessingByThirdParties.AdjustItemSelectionSettings(Form, Object);
	
	Items = Form.Items;
	
	// Type of price
	If Not Items.Find("GoodsPriceKind") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseForIssuingProductsWorksAndServicesAtFixedCost", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.OutputAnyTypeOfPrice", True));
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.StatusesOfPriceTypeValidity.Valid));
		
		Items.GoodsPriceKind.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
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

// Returns the presentation of the document transfer of goods to the custodian.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Chuyển giao nguyên liệu cho bên nhận gia công';
				|ru = 'Передача сырья переработчику';
				|en = 'Goods issue — Subcontracting services received'; fa = 'صدور کالا — خدمات پیمانکاری فرعی دریافتی';
				|it = 'Trasferimento di materie prime al subfornitore';
				|pl = 'Przenoszenie surowców do procesora';
				|tr = 'Hammaddelerin fason üreticiye transferi'");
	
EndFunction

// Returns an indication that the warehouse is a group and groups can be used in transfer documents.
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses
// 
// Returns:
//  Boolean - This is a group of warehouses
//
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse) Export
	
	Return Catalogs.Warehouses.IsFolder(Warehouse);
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInJournal

// Returns the hyperlink text for the transition from the document log to the design workspace.
// 
// Parameters:
// 	Parameters - Structure - parameters for forming the hyperlink text.
// Returns:
// 	FormattedString, Undefined - the text of the hyperlink of the transition to the workplace of the registration of transfers.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	HaveReadRights = AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
						And AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue);
	
	If Not HaveReadRights Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Chuyển giao nguyên liệu';
						|ru = 'Передача сырья';
						|en = 'Components transfer'; fa = 'انتقال اجزا';
						|it = 'Trasmissione della materia prima';
						|pl = 'Przenoszenie surowca';
						|tr = 'Hammadde transferi'");
	HyperlinkAnchorText = "DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices/RawMaterialTransferPage";
	
	ThereAreDocumentsForRegistration = DataProcessors.DocumentsOfTransferToTollingAll2_5.ThereAreDocumentsForRegistration(
									Parameters, Enums.BusinessTransactions.TransferToToller2_5);
	
	ColorOfHyperlink = ?(ThereAreDocumentsForRegistration, Undefined, StyleColors.EmptyTableField);
	
	Return New FormattedString(HyperlinkText,, ColorOfHyperlink,, HyperlinkAnchorText);
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Private

// Returns the base text based on the document data and the specified calculation order
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.TransferOfGoodsToBailee - Object of the document to
//																			   get the base text from.
//	ByContract - Boolean - the text of the description is based on the contract, otherwise on the basis of the order
//						  (if undefined, then depending on the completed details).
//
// Returns:
//  Structure - LongDesc:
//  * Basis - String - Presentation
//  * ReferenceDocumentDateForPrintForms - Date - Date
//  * BaseDocumentNumber - String - Number
//
Function BaseStructure(Object, ByContract = Undefined)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If Not ByContract = False And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
		"SELECT ALLOWED
		|	CounterpartyContracts.NameForPrinting AS Basis,
		|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
		|	CounterpartyContracts.Number AS BaseDocumentNumber
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Ref");
		Query.SetParameter("Ref", Object.Contract);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			StructureBase.Basis = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	ElsIf Not ByContract = True And Object.TransferByOrders Then
		
		AnArrayOfOrders = Undefined;
		If ValueIsFilled(Object.SalesOrder) Then
			
			AnArrayOfOrders = New Array;
			AnArrayOfOrders.Add(Object.SalesOrder);
			
		ElsIf Object.Goods.Count() <> 0 Then
			
			If TypeOf(Object) = Type("Structure") Then
				AnArrayOfOrders = Object.Goods.UnloadColumn("SalesOrder");
			Else
				AnArrayOfOrders = Object.Goods.Unload(, "SalesOrder").UnloadColumn("SalesOrder");
			EndIf;
			
		EndIf;
		
		If AnArrayOfOrders <> Undefined Then
			
			Query = New Query(
			"SELECT ALLOWED
			|	SalesOrders.NumberAccordingToPartnerData AS NumberAccordingToPartnerData,
			|	SalesOrders.DateAccordingToInformationFromPartner  AS DateAccordingToInformationFromPartner,
			|	SalesOrders.Number                 AS Number,
			|	SalesOrders.Date                  AS Date,
			|	&SynonymForOrder                       AS Synonym
			|FROM
			|	Document.SubcontractOrder2_5 AS SalesOrders
			|WHERE
			|	SalesOrders.Ref IN(&AnArrayOfOrders)");
			
			Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
			Query.SetParameter("SynonymForOrder", SynonymForOrder());
			Selection = Query.Execute().Select();
			
			TextForOrders = "";
			OneFoundation = Selection.Count() = 1;
			While Selection.Next() Do
				
				If ValueIsFilled(Selection.NumberAccordingToPartnerData) And ValueIsFilled(Selection.DateAccordingToInformationFromPartner) Then
					
					InformationAboutOrder = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 số %2 ngày %3';
							|ru = '%1 № %2 от %3';
							|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
							|it = '%1 № %2 dal %3';
							|pl = '%1 nr %2 z dnia %3.';
							|tr = '%3 tarihli %2 numaralı %1'"),                    // String with parameters
						Selection.Synonym,                                 // 1 parameter
						Selection.NumberAccordingToPartnerData,                   // 2 parameter
						Format(Selection.DateAccordingToInformationFromPartner, "DLF=DD")); // 3 parameter
					DateForOrders  = Selection.DateAccordingToInformationFromPartner;
					OrderNumber_1 = Selection.NumberAccordingToPartnerData;
				Else
					
					InformationAboutOrder = TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
					DateForOrders  = Selection.Date;
					OrderNumber_1 = Selection.Number;
				EndIf;
				
				TextForOrders = TextForOrders + ", " + InformationAboutOrder;
				
			EndDo;
			
			StructureBase.Basis      = TrimAll(Mid(TextForOrders, 3));
			StructureBase.ReferenceDocumentDateForPrintForms  = ?(OneFoundation, DateForOrders, "");
			StructureBase.BaseDocumentNumber = ?(OneFoundation,ObjectsPrefixesClientServer.NumberForPrinting(OrderNumber_1),"");
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

#EndRegion