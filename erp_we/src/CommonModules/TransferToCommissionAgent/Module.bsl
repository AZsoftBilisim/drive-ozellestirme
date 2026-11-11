////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Commission sales"
// related to the economic operation "Transfer to commission".
// 
////////////////////////////////////////////////////////////////
//

#Region Public

#Region UnifiedMethods

#Region FillType

// Returns the text of the request to fill in the document on the basis of the order for transfer to the commission.
//
// Returns:
//  String -
//
Function TextOfRequestToFillInOrderForm() Export
	
	QueryText =
	"SELECT
	|	SalesOrder.Ref      AS SalesOrder,
	|	VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) AS BusinessOperation,
	|	SalesOrder.Status      AS DocumentStatus,
	|	SalesOrder.Partner     AS Partner,
	|	SalesOrder.Counterparty  AS Counterparty,
	|	SalesOrder.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	SalesOrder.Terms  AS Terms,
	|	SalesOrder.Organization AS Organization,
	|	SalesOrder.BankAccount AS CompanyBankAccount,
	|	SalesOrder.Contract     AS Contract,
	|	CASE
	|		WHEN
	|			ISNULL(Warehouses.IsFolder, FALSE)
	|				AND ISNULL(Warehouses.SelectGroup, UNDEFINED) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE SalesOrder.Warehouse
	|	END                    AS Warehouse,
	|	ISNULL(Warehouses.UseWarehouseManagemantSystemForGoodsIssue,
	|			FALSE)            AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN
	|			ISNULL(Warehouses.IsFolder, FALSE)
	|				AND ISNULL(Warehouses.SelectGroup, UNDEFINED) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                    AS ItIsForbiddenToSelectWarehouseGroup,
	|	SalesOrder.Currency      AS Currency,
	|
	|	SalesOrder.Shipper               AS Shipper,
	|	SalesOrder.ShipperBankAccount AS ShipperBankAccount,
	|	SalesOrder.GoodsRecipient                AS GoodsRecipient,
	|	SalesOrder.GoodsRecipientBankAccount  AS GoodsRecipientBankAccount,
	|
	|	SalesOrder.DateOfShipment       AS DateOfShipment,
	|	SalesOrder.NotShipInInstallments AS NotShipInInstallments,
	|
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryMethod
	|	END                                   AS DeliveryMethod,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.CarrierPartner
	|	END                                   AS CarrierPartner,
	|	SalesOrder.DeliveryAddress              AS DeliveryAddress,
	|	SalesOrder.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryZone
	|	END                                   AS DeliveryZone,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryTimeFrom
	|	END                                   AS DeliveryTimeFrom,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryTimeTo
	|	END                                   AS DeliveryTimeTo,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.AdditionalDeliveryInformation
	|	END                                   AS AdditionalDeliveryInformation,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.SpecialTransportationConditions
	|	END                                   AS SpecialTransportationConditions,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|				AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.SpecialTransportationConditionsDescription
	|	END                                   AS SpecialTransportationConditionsDescription,
	|
	|	SalesOrder.SalesOpportunity                  AS SalesOpportunity,
	|	SalesOrder.Department           AS Department,
	|	SalesOrder.ContactPerson          AS ContactPerson,
	|	SalesOrder.LineOfBusiness AS LineOfBusiness,
	|
	|	SalesOrder.ToReturnReusablePackage      AS ToReturnReusablePackage,
	|	SalesOrder.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
	|	CASE
	|		WHEN &ToUseTermsOfSales
	|			THEN ISNULL(Terms1.ScheduleOfPackageReturn, VALUE(Catalog.BusinessCalendars.EmptyRef))
	|		ELSE VALUE(Catalog.BusinessCalendars.EmptyRef)
	|	END                                       AS ScheduleOfPackageReturn,
	|	CASE
	|		WHEN &ToUseTermsOfSales 
	|			THEN ISNULL(Terms1.CalculatePackageReturnDateAccordingToCalendar, FALSE)
	|		ELSE FALSE
	|	END                                       AS CalculatePackageReturnDateAccordingToCalendar,
	|
	|	SalesOrder.ThisIsOrderAsInvoice                AS ThisIsOrderAsInvoice,
	|
	|	NOT SalesOrder.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON SalesOrder.Warehouse = Warehouses.Ref
	|	
	|		LEFT JOIN Catalog.TermsOfSale AS Terms1
	|		ON SalesOrder.Terms = Terms1.Ref
	|WHERE
	|	SalesOrder.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT DISTINCT
	|	ShippingOrdersShipped.Warehouse AS Warehouse
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersShipped
	|	LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON ShippingOrdersShipped.Warehouse = Warehouses.Ref
	|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
	|		ON TRUE
	|WHERE
	|	ShippingOrdersShipped.QuantityToBeShippedTurnover
	|		- ShippingOrdersShipped.ShippedQuantityTurnover > 0
	|	AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|		OR Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|			AND Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue > &CheckDate
	|		OR TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForIssueBalanceAndTurnovers.Warehouse AS Warehouse
	|FROM
	|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
	|			,
	|			,
	|			,
	|			,
	|			DocumentShipments = &DocumentBasis
	|				AND CAST(Warehouse AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsIssue
	|				AND CAST(Warehouse AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsIssue < &CheckDate
	|		) AS GoodsForIssueBalanceAndTurnovers
	|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
	|		ON TRUE
	|WHERE
	|	GoodsForIssueBalanceAndTurnovers.ToShipExpense - GoodsForIssueBalanceAndTurnovers.ToRegisterExpense > 0
	|	AND TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst)
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText = "
		|	ReferenceOrder = &DocumentBasis
		|";
	TableFormationParameters.Group = "Warehouse";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Return QueryText;
	
EndFunction

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	If GetFunctionalOption("UseSaleByMultipleOrders") Then
		KeyFields = "Partner, Counterparty, Contract, Organization, SalesOpportunity, Currency, LineOfBusiness";
	Else
		KeyFields = "Ref";
	EndIf;
	
	Return KeyFields;
	
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
	
//	Completed = Processing of the server's external calls.To form Data fillingtransmission of raw materials(
//					Array of links, Metadata.Documents.Transfer of goods to the custodian.Name, details of the folder);
//					
//	If Not Fulfilled Then
//		Return is Uncertain;
//	The end if;
	
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
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	
	AvailableStockTypes = New Array;
	AvailableStockTypes.Add(Enums.InventoryTypes.OwnGoods);
	AvailableStockTypes.Add(Enums.InventoryTypes.ConsignedGoods);
	
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
//  Undefined - 
//
Function ParametersForRecalculatingNumberOfUnits() Export
	
	Return Undefined;
	
EndFunction

// Returns the parameters for rounding
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding() Export
	
	Return New Structure("Goods");
	
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
		"TableOfOrders.BusinessOperation",
		"VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)",
		"=");
	
	TMCommonUse.AddSelectionItemToCollection(
		RequestTextParameters.Filter,
		"CASE
		|	WHEN TableOfOrders.Warehouse = &Warehouse
		|		OR TableOfOrders.Warehouse IN HIERARCHY (&Warehouse)
		|		OR TableOfOrders.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		THEN TRUE
		|	ELSE FALSE
		|END",
		"TRUE",
		"=");
	
	Return Documents.SalesOrder.RequestTextForOrdersInvoices(RequestTextParameters);
	
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
	
	TMCommonUse.AddSelectionItemToCollection(
		FilterByDimensions,
		"ReferenceOrder",
		"SELECT
		|	WaybillOrders.ReferenceOrder
		|FROM
		|	WaybillOrders AS WaybillOrders");
	
	TMCommonUse.AddSelectionItemToCollection(
		FilterByDimensions,
		"CASE
		|	WHEN Warehouse = &Warehouse
		|		OR Warehouse IN HIERARCHY (&Warehouse)
		|		OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		THEN TRUE
		|	ELSE FALSE
		|END",
		"TRUE",
		"=");
	
	QueryText =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextBalance(
			TempTableName,
			FilterByDimensions,
			"ToRegister > 0");
	
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
	|	GoodsForRegistration.Characteristic AS Characteristic,
	|	GoodsForRegistration.Series          AS Series,
	|	GoodsForRegistration.Warehouse          AS Warehouse
	|INTO DuplicatesOfProductsForRegistration
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|
	|GROUP BY
	|	GoodsForRegistration.Products,
	|	GoodsForRegistration.Characteristic,
	|	GoodsForRegistration.Series,
	|	GoodsForRegistration.Warehouse
	|";
	
EndFunction

#EndRegion

// Edits the text of the conversion request to the document currency
//
// Parameters:
//  QueryText - String - the editable text of the request.
//
Procedure EditTextOfRequestForConversionToDocumentCurrency(QueryText) Export
	
	Return;
	
EndProcedure

// Edits the text of the request for order balances
//
// Parameters:
//  QueryText - String - the editable text of the request.
//
Procedure EditRequestTextForOrderBalances(QueryText) Export
	
	//Customer Order Table
	QueryText = StrReplace(QueryText, "&CustomerOrderAgreement",                "SalesOrder.Terms");
	QueryText = StrReplace(QueryText, "&CustomerSOrderToReturnMultiTurnContainer", "SalesOrder.ToReturnReusablePackage");
	QueryText = StrReplace(QueryText, "&CustomerOrderSenderAssignment",     "OrderingProducts.Ref.Purpose");
	QueryText = StrReplace(QueryText, "&CustomerOrderAssignmentStage",            "VALUE(Catalog.Assignments.EmptyRef)");
	QueryText =
		StrReplace(
			QueryText,
			"&CustomerOrderAssignment",
			"CASE
			|	WHEN OrderingProducts.WithAssignment
			|		THEN OrderingProducts.Ref.Purpose
			|	ELSE VALUE(Catalog.Assignments.EmptyRef)
			|END");
	
	//Product Order table
	QueryText = StrReplace(QueryText, "&OrderGoodsAmountWithVAT", "GoodsFromOrder.AmountIncludingVAT");
	
	//The Order Items table
	QueryText = StrReplace(QueryText, "&OrderProductsSetProducts",   "OrderingProducts.ProductsInSet");
	QueryText = StrReplace(QueryText, "&OrderGoodsSetCharacteristics", "OrderingProducts.ItemVariantOfSet");
	
	QueryText = StrReplace(QueryText, "&OrderProductsTypeOfPrice",              "OrderingProducts.PriceKind");
	QueryText = StrReplace(QueryText, "&TableBalancesAmount",             "TableBalance.Sum");
	
EndProcedure

#EndRegion

#Region DocumentOrderDocument

// Returns the access right of the customer's order.
//
// Parameters:
//  NameRight - String - the name of the right being checked.
//
// Returns:
//  Boolean - 
//
Function OrderAccessRights(NameRight) Export
	
	Return AccessRight(NameRight, Metadata.Documents.SalesOrder);
	
EndFunction

// Returns the manager of the customer's order document
//
// Returns:
//  DocumentManager.SalesOrder - 
//
Function OrderManager() Export
	
	Return Documents.SalesOrder;
	
EndFunction

// Returns the type description for the customer's order
// 
// Returns:
//  TypeDescription - 
//
Function OrderTypeDescription() Export
	
	Return New TypeDescription("DocumentRef.SalesOrder");
	
EndFunction

// Returns the type for the customer's order
// 
// Returns:
//  Type - 
//
Function OrderType_5() Export
	
	Return Type("DocumentRef.SalesOrder");
	
EndFunction

// Returns the synonym of the order.
//
// Returns:
//  String - synonym of the order.
//
Function SynonymForOrder() Export
	
	Return NStr("vi = 'Đơn hàng chuyển giao ký gửi';
				|ru = 'Заказ передачи на комиссию';
				|en = 'Order of consignment sales'; fa = 'Order of consignment sales';
				|it = 'Ordine di trasferimento in commissione';
				|pl = 'Zamówienie wydania do komisu';
				|tr = 'Konsinye satış siparişi'");
	
EndFunction

#EndRegion

#Region DiscrepancyCertificate

// Returns the type of the basis of the act of discrepancy
//
// Returns:
//  EnumRef.TypesOfBaseDocumentsForDiscrepancyReport
//
Function TypeOfBasisOfAct() Export
	
	Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent;
	
EndFunction

// Returns a sign of the registration of the return document through the document of the act of discrepancy
//
// Returns:
//  Boolean - 
//
Function IssueRefundOfAct() Export
	
	Return True;
	
EndFunction

// Returns the postfix of the name of the discrepancy report
//
// Returns:
//  String - 
//
Function ActNamePostfix() Export
	
	Return NStr("vi = 'sau khi chuyển giao hàng hóa vào ký gửi';
				|ru = 'после передачи товаров на комиссию';
				|en = 'after consignment sales'; fa = 'after consignment sales';
				|it = 'dopo il trasferimento degli articoli in commissione';
				|pl = 'po przekazaniu towarów do komisu';
				|tr = 'konsinye mal satış transferi sonrası'");
	
EndFunction

// Returns the title of the discrepancy report form when creating
//
// Returns:
//  String - 
//
Function TitleOfReportCreationForm() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao hàng hóa vào ký gửi (tạo mới)';
				|ru = 'Акт о расхождениях после передачи товаров на комиссию (создание)';
				|en = 'Discrepancy report after consignment sales (create)'; fa = 'Discrepancy report after consignment sales (create)';
				|it = 'Atto sulle discrepanze dopo il trasferimento articoli in commissione (creazione)';
				|pl = 'Protokół o odchyleniu po przekazaniu towarów do komisu (tworzenie)';
				|tr = 'Konsinye satış sonrası tutarsızlık raporu (oluşturma)'");
	
EndFunction

// Returns the title of the discrepancy report form
//
// Returns:
//  String - 
//
Function ReportFormHeader() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi chuyển hàng hóa để bán ký gửi';
				|ru = 'Акт о расхождениях после передачи товаров на комиссию';
				|en = 'Discrepancy report after consignment sales'; fa = 'Discrepancy report after consignment sales';
				|it = 'Акт о расхождениях после передачи товаров на комиссию';
				|pl = 'Discrepancy report after consignment sales';
				|tr = 'Konsinye stok transferi sonrası tutarsızlık raporu'");
	
EndFunction

// Returns the title of the partner of the discrepancy report
//
// Returns:
//  String - 
//
Function HeaderOfActPartner() Export
	
	Return NStr("vi = 'Người nhận bán ký gửi';
				|ru = 'Комиссионер';
				|en = 'Consignee'; fa = 'امانت‌دار';
				|it = 'Commissionario';
				|pl = 'Consignee';
				|tr = 'Konsinye'");
	
EndFunction

// Returns the title of the document of the basis of the act of discrepancy
//
// Returns:
//  String - 
//
Function TitleOfDocumentGroundsOfAct() Export
	
	Return NStr("vi = 'Chuyển đi ký gửi';
				|ru = 'Передача на комиссию';
				|en = 'Consignment sale'; fa = 'فروش امانی';
				|it = 'Trasferimento in conto vendita';
				|pl = 'Przekazanie do komisu';
				|tr = 'Konsinye satış'");
	
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
				|tr = 'Sevk işleminin gerçekleştirildiği sözleşme'");
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business operation of the document.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function BusinessOperation() Export
	
	Return Enums.BusinessTransactions.TransferToCommissionAgent;
	
EndFunction

// Returns the business transaction of the contract.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToCommissionAgent;
	
EndFunction

// Returns an array of business operations orders.
//
// Returns:
//  Array of EnumRef.BusinessTransactions -
//
Function EconomicOperationsOfOrders() Export
	
	OperationArray = New Array;
	OperationArray.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	OperationArray.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	
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

// Returns the attribute using the advanced features of the customer's order
//
// Returns:
//  Boolean -
//
Function UseAdvancedFeaturesOfSalesOrder() Export
	
	Return GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
EndFunction

// Returns the attribute using customer orders
//
// Returns:
//  Boolean -
//
Function UseSalesOrders() Export

	UseSalesOrders = GetFunctionalOption("UseSalesOrders")
								 Or GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");

	Return UseSalesOrders;
	
EndFunction

// Returns the attribute of using the implementation for multiple orders.
//
// Returns:
//  Boolean -
//
Function UseSaleByMultipleOrders() Export

	Return GetFunctionalOption("UseSaleByMultipleOrders");

EndFunction

// Returns a sign of implementation in excess of the order.
// 
// Returns:
// 	Boolean
//
Function SalesInExcessOfOrder() Export
	
	Return UserRightsCached.SalesInExcessOfOrder();
	
EndFunction

// Returns a sign of deviation from the terms of sale.
// 
// Returns:
// 	Boolean
//
Function VarianceFromSalesTermsAndConditions() Export
	
	Return UserRightsCached.VarianceFromSalesTermsAndConditions();
	
EndFunction

#EndRegion

#Region BasisForPrint

// Returns the base structure based on document data
// 
// Parameters:
// 	Object - FormDataStructure, DocumentObject - Object of the document to
// 																			   get the base text from.
// 	
// Returns:
//  Structure - LongDesc:
//   * Basis - String - Presentation
//   * ReferenceDocumentDateForPrintForms - Date - Date
//   * BaseDocumentNumber - String - Number
//
Function StructureOfBaseForPrinting(Object) Export
	
	ARAPObjectSettings = ARAPAccountingServer.ARAPObjectSettings(False,,Object.Terms, Object.Contract);
	
	BaseStructure = BaseStructure(Object, ARAPObjectSettings);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		BaseStructure.Basis = BaseStructure.Basis + ", " + NStr("vi = 'chuyển đi ký gửi';
																|ru = 'передача на комиссию';
																|en = 'consignment sales'; fa = 'consignment sales';
																|it = 'trasferimento in conto vendita';
																|pl = 'przekazanie do komisu';
																|tr = 'konsinye satış'");
	Else
		BaseStructure.Basis = NStr("vi = 'Chuyển đi ký gửi.';
									|ru = 'Передача на комиссию.';
									|en = 'Consignment sale.'; fa = 'Consignment sale.';
									|it = 'Trasferimento in conto vendita.';
									|pl = 'Przekazanie do komisu.';
									|tr = 'Konsinye satış.'");
	EndIf;
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base"attribute.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.TransferOfGoodsToBailee - the document object to
//																			get the selection list for.
//
// Returns:
//	ValueTable - A table of values with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis", New TypeDescription("String", , , , New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms", New TypeDescription("Date", , , , ,
																			New DateQualifiers(DateFractions.Date)));
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String", , , ,
																			New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByCounterpartyContracts);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		
		AddedRow.Basis = BaseStructure.Basis + ", " + NStr("vi = 'chuyển giao ký gửi';
															|ru = 'передача на комиссию';
															|en = 'consignment sales'; fa = 'consignment sales';
															|it = 'trasferimento in conto vendita';
															|pl = 'przekazanie do komisu';
															|tr = 'konsinye satış'");
		
		If ValueIsFilled(BaseStructure.ReferenceDocumentDateForPrintForms)
			And ValueIsFilled(BaseStructure.BaseDocumentNumber) Then
			
			ExtendedText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 số %2 ngày %3';
																						|ru = '%1 № %2 от %3';
																						|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
																						|it = '%1 № %2 dal %3';
																						|pl = '%1 nr %2 z dnia %3.';
																						|tr = '%2sayılı %3tarihli %1'"),
																						BaseStructure.Basis,
																						BaseStructure.BaseDocumentNumber,
																						Format(BaseStructure.ReferenceDocumentDateForPrintForms, "DLF=DD"));
			
			ExtendedText = ExtendedText + ", " + NStr("vi = 'chuyển đi ký gửi';
														|ru = 'передача на комиссию';
														|en = 'consignment sales'; fa = 'consignment sales';
														|it = 'trasferimento in conto vendita';
														|pl = 'przekazanie do komisu';
														|tr = 'konsinye satış'");
			
			AddedRow = TableOfBases_.Add();
			FillPropertyValues(AddedRow, BaseStructure);
			
			AddedRow.Basis = ExtendedText;
			
		EndIf;
		
	EndIf;
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByOrders);
	
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis + ", " + NStr("vi = 'chuyển giao ký gửi';
															|ru = 'передача на комиссию';
															|en = 'consignment sales'; fa = 'consignment sales';
															|it = 'trasferimento in conto vendita';
															|pl = 'przekazanie do komisu';
															|tr = 'konsinye satış'");
	EndIf;
	
	If TableOfBases_.Count() = 0 Then
		AddedRow = TableOfBases_.Add();
		AddedRow.Basis = NStr("vi = 'chuyển giao ký gửi';
								|ru = 'передача на комиссию';
								|en = 'consignment sales'; fa = 'consignment sales';
								|it = 'trasferimento in conto vendita';
								|pl = 'przekazanie do komisu';
								|tr = 'konsinye satış'");
	EndIf;
	
	Return TableOfBases_;
	
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
	   And GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
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

	Items.Partner.Title            = NStr("vi = 'Người nhận ký gửi';
											|ru = 'Комиссионер';
											|en = 'Consignee'; fa = 'امانت‌دار';
											|it = 'Commissionario';
											|pl = 'Consignee';
											|tr = 'Konsinye'");
	Items.GoodsSalesOrder.Title = NStr("vi = 'Đơn hàng ký gửi';
										|ru = 'Заказ на комиссию';
										|en = 'Order to consignee'; fa = 'Order to consignee';
										|it = 'Ordine di commissione';
										|pl = 'Zamówienie do komisu';
										|tr = 'Konsinye sipariş'");
	
	RightToChangeOrders = OrderAccessRights("Update");
	Items.CloseOrder.Enabled  = RightToChangeOrders;
	Items.CloseOrders_2.Enabled = RightToChangeOrders;
	
	Items.Terms.Visible = ToUseTermsOfSales();
	Items.GoodsFillThePricesByTermsOfSales.Visible = Items.Terms.Visible;
	Items.GoodsFillInPricesUnderAgreement.Visible   = True;
	
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
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.TransferToCommissionAgent));
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.ConsignmentSales25", True));
	
	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("ARAPCurrency", "Object.Currency", LinkedValueChangeMode.Clear));
	
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	If Not Items.Find("LineOfBusiness") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		
		Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
	// Type of price
	If Not Items.Find("GoodsPriceKind") = Undefined Then
		
		ArrayOfSelectParameterRelationships = New Array;
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("ToUseTermsOfSales", "ToUseTermsOfSales", LinkedValueChangeMode.Clear));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.Clear));
			
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Currency", "Object.Currency", LinkedValueChangeMode.Clear));
		
		Items.GoodsPriceKind.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.UseWhileSellingToCustomers", True));
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
								|tr = '%1 (oluştur)'"), ObjectPresentation());
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
	
	Return NStr("vi = 'Chuyển đi ký gửi';
				|ru = 'Передача на комиссию';
				|en = 'Consignment sales'; fa = 'فروش امانی';
				|it = 'Trasferimento in conto vendita';
				|pl = 'Przekazanie do komisu';
				|tr = 'Konsinye satış'");
	
EndFunction

// Returns an indication that the warehouse is a group and groups can be used in sales documents.
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses
// 
// Returns:
//  Boolean - This is a group of warehouses
//
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse) Export
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region Other

// Returns the base text based on the document data and the specified calculation order.
//
// Parameters:
//	Object 			- FormDataStructure, DocumentObject.TransferOfGoodsToBailee - Object of the document to
//																					get the base text from.
//	ARAPObjectSettings - EnumRef.ARAPObjectSettings 							- Procedure of settlements.
//
// Returns:
//  Structure - LongDesc:
//   * Basis - String - Presentation
//   * ReferenceDocumentDateForPrintForms - Date - Date
//   * BaseDocumentNumber - String - Number
//
Function BaseStructure(Object, ARAPObjectSettings)
	
	StructureBase = New Structure("Basis, BaseDocumentNumber, ReferenceDocumentDateForPrintForms");
	
	If (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	CounterpartyContracts.NameForPrinting AS Basis,
		|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
		|	CounterpartyContracts.Number AS BaseDocumentNumber
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Ref";
		
		Query.SetParameter("Ref", Object.Contract);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			StructureBase.Basis      = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms  = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	ElsIf (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		And Object.TransferByOrders Then
		
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
		
			Query = New Query;
			Query.Text = 
			"SELECT ALLOWED
			|	SalesOrders.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
			|	SalesOrders.DateAccordingToInformationFromCustomer  AS DateAccordingToInformationFromCustomer,
			|	SalesOrders.Number                AS Number,
			|	SalesOrders.Date                 AS Date,
			|	&SynonymForOrder                      AS Synonym
			|FROM
			|	Document.SalesOrder AS SalesOrders
			|WHERE
			|	SalesOrders.Ref IN(&AnArrayOfOrders)";
			
			Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
			Query.SetParameter("SynonymForOrder", NStr("vi = 'Đơn hàng của khách';
														|ru = 'Заказ клиента';
														|en = 'Sales order'; fa = 'سفارش فروش';
														|it = 'Ordine del cliente';
														|pl = 'Zamówienie klienta';
														|tr = 'Satış siparişi'"));
			
			Selection = Query.Execute().Select();
			
			TextForOrders = "";
			OneFoundation  = Selection.Count() = 1;
			
			While Selection.Next() Do
				
				If ValueIsFilled(Selection.NumberAccordingToCustomerData)
					And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
					
					TextForOrders = TextForOrders + ", "
									+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 số %2 ngày %3';
																									|ru = '%1 № %2 от %3';
																									|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
																									|it = '%1 № %2 dal %3';
																									|pl = '%1 nr %2 z dnia %3.';
																									|tr = '%2sayılı %3tarihli %1'"),
																							Selection.Synonym,
																							Selection.NumberAccordingToCustomerData,
																							Format(Selection.DateAccordingToInformationFromCustomer, "DLF=DD"));
					
					DateForOrders  = Selection.DateAccordingToInformationFromCustomer;
					OrderNumber_1 = Selection.NumberAccordingToCustomerData;
					
				Else
					TextForOrders = TextForOrders + ", "
									+ TMCommonUseClientServer.GenerateDocumentTitle(Selection, Selection.Synonym);
					
					DateForOrders  = Selection.Date;
					OrderNumber_1 = Selection.Number;
				EndIf;
				
			EndDo;
			
			StructureBase.Basis      = TrimAll(Mid(TextForOrders, 3));
			StructureBase.ReferenceDocumentDateForPrintForms  = ?(OneFoundation, DateForOrders, "");
			StructureBase.BaseDocumentNumber = ?(OneFoundation,
												ObjectsPrefixesClientServer.NumberForPrinting(OrderNumber_1),
												"");
			
		EndIf;
		
	EndIf;
	
	Return StructureBase;
	
EndFunction

#EndRegion
