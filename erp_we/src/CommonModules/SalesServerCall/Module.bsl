////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions for recalculating the totals of documents in forms.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks whether the table part contains rows with an empty shipment date in the non-canceled rows.
//	
// Parameters:
//		Object - FormDataStructure - object being checked
//		TSName - String - name of the PM being checked.
//
// Returns:
//		Boolean - indicates whether there are lines with an empty shipment date.
Function ShipmentDateIsBlank(Val Object, TSName) Export
	
	If Object.NotShipInInstallments Then
		If Not ValueIsFilled(Object.DateOfShipment) Then
			
			Return True;
			
		EndIf;
		
	Else
		For Each CurRow In Object[TSName] Do
			
			If Not CurRow.Canceled
				And Not ValueIsFilled(CurRow.DateOfShipment) Then
				
				Return True;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	Return False;
	
EndFunction

// Gets the minimum Document shipment date.
//
// Parameters:
//  Object - FormDataStructure - Client's order, Client's requestcountry return.
//  TabularSectionName - String - Name of the table part. The default value is "Products".
// 
// Returns:
//  Date - Minimum date of shipment of the document.
//
Function MinimumDateOfShipmentOfObject(Val Object, TabularSectionName = "Goods") Export

	Return OrdersServer.GetMinimumDateOfShipmentOfObject(Object, TabularSectionName);

EndFunction

// This function returns the status of the actual document shipment
//
// Parameters:
// 		ShippingDocuments - Array - Links to documents-orders for shipment.
//
// Returns:
// 		Structure - A structure with the fields "There are loaded goods, there are assembled goods" of the "Boolean" type.
//
Function GetStateOfActualShipment(ShippingDocuments) Export
	
	Return SalesServer.GetStateOfActualShipment(ShippingDocuments);
	
EndFunction

// Creates a structure for creating an implementation for one or more customer orders.
// If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
// 	ReferencesArrray - Array of DocumentRef - orders to suppliers for which you need to enter an implementation.
// 	DocumentName - String - name of the document that is being created based on orders.
// 	HeaderAttributes - Structure - the structure where the header details from the order array will be placed.
// 	BusinessOperation - EnumRef.BusinessTransactions
//
// Returns:
// 	Boolean - False if the details of the header differ in the transferred orders.
//
Function GenerateImplementationFillInData(ReferencesArrray,
	DocumentName,
	HeaderAttributes,
	BusinessOperation = Undefined) Export
	
	TextOrders = "";
	
	If AccessRight("Read", Metadata.Documents.SalesOrder) Then
		TextOrders = 
		"SELECT
		|	SalesOrder.Ref                                AS SalesOrder,
		|	SalesOrder.Partner                               AS Partner,
		|	SalesOrder.Counterparty                            AS Counterparty,
		|	SalesOrder.Contract                               AS Contract,
		|	SalesOrder.Organization                           AS Organization,
		|	SalesOrder.Terms                            AS Terms,
		|	SalesOrder.SalesOpportunity                                AS SalesOpportunity,
		|	SalesOrder.Warehouse                                 AS Warehouse,
		|	SalesOrder.Department                         AS Department,
		|	SalesOrder.BusinessOperation                 AS BusinessOperation,
		|	SalesOrder.Currency                                AS ARAPCurrency,
		|	SalesOrder.VATTaxation                    AS VATTaxation,
		|	SalesOrder.PriceIncludesVAT                       AS PriceIncludesVAT,
		|	SalesOrder.ARAPObjectSettings                       AS ARAPObjectSettings,
		|	SalesOrder.ForeignCurrencyTransaction                         AS ForeignCurrencyTransaction,
		|	SalesOrder.ToReturnReusablePackage             AS ToReturnReusablePackage,
		|	SalesOrder.PackageDepositIsRequired                  AS PackageDepositIsRequired,
		|	SalesOrder.ReusablePackageReturnCycleLength        AS ReusablePackageReturnCycleLength,
		|	SalesOrder.PaymentMethod                           AS PaymentMethod,
		|	SalesOrder.PaymentSchedule                          AS PaymentSchedule,
		|	SalesOrder.BankAccount                        AS BankAccount,
		|	SalesOrder.CashAccount                                 AS CashAccount,
		|	SalesOrder.CounterpartyBankAccount             AS CounterpartyBankAccount,
		|	SalesOrder.Shipper                      AS Shipper,
		|	SalesOrder.GoodsRecipient                       AS GoodsRecipient,
		|	SalesOrder.ShipperBankAccount        AS ShipperBankAccount,
		|	SalesOrder.GoodsRecipientBankAccount         AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN
		|			SalesOrder.Warehouse.IsFolder AND SalesOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|		THEN
		|			VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE
		|			SalesOrder.Warehouse
		|	END AS OriginWarehouse,
		|	SalesOrder.DeliveryMethod                        AS DeliveryMethod,
		|
		|	SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
		|		                                               AS MethodOfDeliveryByCarrier,
		|	SalesOrder.CarrierPartner                     AS CarrierPartner,
		|	SalesOrder.DeliveryAddress                         AS DeliveryAddress,
		|	SalesOrder.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
		|	SalesOrder.DeliveryAddressValue AS DeliveryAddressValue,
		|	SalesOrder.DeliveryAddressOfCarrier              AS DeliveryAddressOfCarrier,
		|	SalesOrder.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	SalesOrder.DeliveryZone                          AS DeliveryZone,
		|	SalesOrder.DeliveryTimeFrom                        AS DeliveryTimeFrom,
		|	SalesOrder.DeliveryTimeTo                       AS DeliveryTimeTo,
		|	SalesOrder.AdditionalDeliveryInformation    AS AdditionalDeliveryInformation,
		|	&RTUDocumentName                                   AS DocumentName,
		|	SalesOrder.LineOfBusiness               AS LineOfBusiness,
		|	SalesOrder.ContactPerson                        AS ContactPerson,
		|	SalesOrder.LoyaltyCard                       AS LoyaltyCard,
		|	SalesOrder.UISStateContractStep                   AS UISStateContractStep,
		|	SalesOrder.FinancialAccountingGroup                AS FinancialAccountingGroup,
		|	SalesOrder.ThisIsOrderAsInvoice                       AS ThisIsOrderAsInvoice,
		|	NOT SalesOrder.BusinessOperation IN(&ValidOperations) 
		|	OR (SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|		AND SalesOrder.Contract.ConsignmentSales25
		|		AND NOT &ThisIsShipmentOfGoodsFromStorage
		|		AND NOT &ThisIsTransferOfGoodsToKeeper) AS ThereIsInvalidOperation
		|INTO TTCustomerOrders_
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref IN (&ReferencesArrray)";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
		
		CreateTemporaryTable = True;
		
		If TextOrders <> "" Then
			CreateTemporaryTable = False;
			
			TextOrders = TextOrders + "
			|
			|UNION ALL
			|";
		EndIf; 
		TextOrders = TextOrders + "
			|SELECT
			|	ReturnRequest.Ref                         AS SalesOrder,
			|	ReturnRequest.Partner                        AS Partner,
			|	ReturnRequest.Counterparty                     AS Counterparty,
			|	ReturnRequest.Contract                        AS Contract,
			|	ReturnRequest.Organization                    AS Organization,
			|	ReturnRequest.Terms                     AS Terms,
			|	ReturnRequest.SalesOpportunity                         AS SalesOpportunity,
			|	ReturnRequest.Warehouse                          AS Warehouse,
			|	ReturnRequest.Department                  AS Department,
			|	CASE
			|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
			|				OR ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
			|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
			|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
			|			THEN VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
			|		ELSE
			|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
			|	END                                                 AS BusinessOperation,
			|	ReturnRequest.Currency                                AS ARAPCurrency,
			|	ReturnRequest.VATTaxation                    AS VATTaxation,
			|	ReturnRequest.PriceIncludesVAT                       AS PriceIncludesVAT,
			|	ReturnRequest.ARAPObjectSettings                       AS ARAPObjectSettings,
			|	ReturnRequest.ForeignCurrencyTransaction                         AS ForeignCurrencyTransaction,
			|	ReturnRequest.ToReturnReusablePackage             AS ToReturnReusablePackage,
			|	ReturnRequest.PackageDepositIsRequired                  AS PackageDepositIsRequired,
			|	ReturnRequest.ReusablePackageReturnCycleLength        AS ReusablePackageReturnCycleLength,
			|	ReturnRequest.PaymentMethod                           AS PaymentMethod,
			|	ReturnRequest.PaymentSchedule                          AS PaymentSchedule,
			|	ReturnRequest.BankAccount                        AS BankAccount,
			|	ReturnRequest.CashAccount                                 AS CashAccount,
			|	ReturnRequest.CounterpartyBankAccount             AS CounterpartyBankAccount,
			|	ReturnRequest.Shipper                      AS Shipper,
			|	ReturnRequest.GoodsRecipient                       AS GoodsRecipient,
			|	ReturnRequest.ShipperBankAccount        AS ShipperBankAccount,
			|	ReturnRequest.GoodsRecipientBankAccount         AS GoodsRecipientBankAccount,
			|	ReturnRequest.Warehouse                                 AS OriginWarehouse,
			|	ReturnRequest.DeliveryMethod                        AS DeliveryMethod,
			|
			|	ReturnRequest.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
			|		                                              AS MethodOfDeliveryByCarrier,
			|	ReturnRequest.CarrierPartner                     AS CarrierPartner,
			|	ReturnRequest.DeliveryAddress                         AS DeliveryAddress,
			|	ReturnRequest.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
			|	ReturnRequest.DeliveryAddressValue AS DeliveryAddressValue,
			|	ReturnRequest.DeliveryAddressOfCarrier              AS DeliveryAddressOfCarrier,
			|	ReturnRequest.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
			|	ReturnRequest.DeliveryZone                          AS DeliveryZone,
			|	ReturnRequest.DeliveryTimeFrom                        AS DeliveryTimeFrom,
			|	ReturnRequest.DeliveryTimeTo                       AS DeliveryTimeTo,
			|	ReturnRequest.AdditionalDeliveryInformation    AS AdditionalDeliveryInformation,
			|	&RTUDocumentName                                      AS DocumentName,
			|	ReturnRequest.LineOfBusiness               AS LineOfBusiness,
			|	ReturnRequest.ContactPerson                        AS ContactPerson,
			|	ReturnRequest.LoyaltyCard                       AS LoyaltyCard,
			|	""""                                                  AS UISStateContractStep,
			|	ReturnRequest.FinancialAccountingGroup                AS FinancialAccountingGroup,
			|	ReturnRequest.ThisIsOrderAsInvoice                       AS ThisIsOrderAsInvoice,
			|	NOT (CASE
			|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
			|				OR ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
			|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
			|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
			|			THEN VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
			|		ELSE
			|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
			|	END) IN(&ValidOperations)                         AS ThereIsInvalidOperation
			|,&NameTTCustomerOrders
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
			|WHERE
			|	ReturnRequest.Ref IN(&ReferencesArrray)";
		
		TextOrders = StrReplace(TextOrders,
						",&NameTTCustomerOrders",
						?(CreateTemporaryTable, "INTO TTCustomerOrders_", ""));
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.GoodsShipmentToCustomer)
		And AccessRight("Read", Metadata.Documents.SalesOrder)
		And AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
		
		QueryText =
		"SELECT
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.Ref
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.Ref
		|		ELSE DocumentHeader.Ref
		|	END AS SalesOrder,
		|	DocumentHeader.Partner AS Partner,
		|	DocumentHeader.Counterparty AS Counterparty,
		|	DocumentHeader.Contract AS Contract,
		|	DocumentHeader.Organization AS Organization,
		|	DocumentHeader.Terms AS Terms,
		|	DocumentHeader.SalesOpportunity AS SalesOpportunity,
		|	DocumentHeader.Warehouse AS Warehouse,
		|	DocumentHeader.Department AS Department,
		|	DocumentHeader.BusinessOperation AS BusinessOperation,
		|	DocumentHeader.Currency AS ARAPCurrency,
		|	DocumentHeader.VATTaxation AS VATTaxation,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.PriceIncludesVAT
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.PriceIncludesVAT
		|		ELSE
		|			TRUE
		|	END AS PriceIncludesVAT,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.ARAPObjectSettings
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.ARAPObjectSettings
		|		ELSE VALUE(Enum.ARAPObjectSettings.EmptyRef)
		|	END AS ARAPObjectSettings,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.ForeignCurrencyTransaction
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.ForeignCurrencyTransaction
		|		ELSE FALSE
		|	END AS ForeignCurrencyTransaction,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.ToReturnReusablePackage
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.ToReturnReusablePackage
		|		ELSE FALSE
		|	END AS ToReturnReusablePackage,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.PackageDepositIsRequired
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.PackageDepositIsRequired
		|		ELSE FALSE
		|	END AS PackageDepositIsRequired,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.ReusablePackageReturnCycleLength
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.ReusablePackageReturnCycleLength
		|		ELSE FALSE
		|	END AS ReusablePackageReturnCycleLength,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.PaymentMethod
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.PaymentMethod
		|		ELSE FALSE
		|	END AS PaymentMethod,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.PaymentSchedule
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.PaymentSchedule
		|		ELSE VALUE(Catalog.PaymentSchedules.EmptyRef)
		|	END AS PaymentSchedule,
		|	DocumentHeader.CompanyBankAccount AS BankAccount,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.CashAccount
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.CashAccount
		|		ELSE VALUE(Catalog.CashAccounts.EmptyRef)
		|	END AS CashAccount,
		|	DocumentHeader.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	DocumentHeader.Shipper AS Shipper,
		|	DocumentHeader.GoodsRecipient AS GoodsRecipient,
		|	DocumentHeader.ShipperBankAccount AS ShipperBankAccount,
		|	DocumentHeader.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN DocumentHeader.Warehouse.IsFolder
		|		AND DocumentHeader.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE DocumentHeader.Warehouse
		|	END AS OriginWarehouse,
		|	DocumentHeader.DeliveryMethod AS DeliveryMethod,
		|	DocumentHeader.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) AS
		|		MethodOfDeliveryByCarrier,
		|	DocumentHeader.CarrierPartner AS CarrierPartner,
		|	DocumentHeader.DeliveryAddress AS DeliveryAddress,
		|	DocumentHeader.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
		|	DocumentHeader.DeliveryAddressValue AS DeliveryAddressValue,
		|	DocumentHeader.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
		|	DocumentHeader.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	DocumentHeader.DeliveryZone AS DeliveryZone,
		|	DocumentHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	DocumentHeader.DeliveryTimeTo AS DeliveryTimeTo,
		|	DocumentHeader.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
		|	&RTUDocumentName AS DocumentName,
		|	DocumentHeader.LineOfBusiness AS LineOfBusiness,
		|	DocumentHeader.ContactPerson AS ContactPerson,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.LoyaltyCard
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.LoyaltyCard
		|		ELSE VALUE(Catalog.LoyaltyCards.EmptyRef)
		|	END AS LoyaltyCard,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.UISStateContractStep
		|		ELSE """"
		|	END AS UISStateContractStep,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.FinancialAccountingGroup
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.FinancialAccountingGroup
		|		ELSE VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef)
		|	END AS FinancialAccountingGroup,
		|	CASE
		|		WHEN DocSalesOrder.Ref IS NOT NULL
		|			THEN DocSalesOrder.ThisIsOrderAsInvoice
		|		WHEN DocReturnRequest.Ref IS NOT NULL
		|			THEN DocReturnRequest.ThisIsOrderAsInvoice
		|		ELSE FALSE
		|	END AS ThisIsOrderAsInvoice,
		|	FALSE AS ThereIsInvalidOperation
		|INTO TTCustomerOrders_
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS GoodsTable
		|		INNER JOIN Document.GoodsShipmentToCustomer AS DocumentHeader
		|		ON GoodsTable.Ref = DocumentHeader.Ref
		|		LEFT JOIN Document.SalesOrder AS DocSalesOrder
		|		ON GoodsTable.SalesOrder REFS Document.SalesOrder
		|		AND GoodsTable.SalesOrder = DocSalesOrder.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocReturnRequest
		|		ON GoodsTable.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|		AND GoodsTable.SalesOrder = DocReturnRequest.Ref
		|WHERE
		|	DocumentHeader.Ref IN (&ReferencesArrray)";
		
		If ValueIsFilled(TextOrders) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextOrders);
			QueryTexts.Add(StrReplace(QueryText, "INTO TTCustomerOrders_", ""));
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextOrders = QueryText;
		
	EndIf;

	If AccessRight("Read", Metadata.Documents.GoodsReceiptFromCustomer)
		And AccessRight("Read", Metadata.Documents.GoodsShipmentToCustomer)
		And AccessRight("Read", Metadata.Documents.SalesOrder)
		And AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
		
		QueryText =
		"SELECT
		|	DocSalesOrder.Ref AS SalesOrder,
		|	GoodsTable.Ref.Partner AS Partner,
		|	GoodsTable.Ref.Counterparty AS Counterparty,
		|	GoodsTable.Ref.Contract AS Contract,
		|	GoodsTable.Ref.Organization AS Organization,
		|	GoodsTable.Ref.Terms AS Terms,
		|	GoodsTable.Ref.SalesOpportunity AS SalesOpportunity,
		|	GoodsTable.Ref.Warehouse AS Warehouse,
		|	GoodsTable.Ref.Department AS Department,
		|	GoodsTable.Ref.BusinessOperation AS BusinessOperation,
		|	GoodsTable.Ref.Currency AS ARAPCurrency,
		|	DocSalesOrder.VATTaxation AS VATTaxation,
		|	DocSalesOrder.PriceIncludesVAT AS PriceIncludesVAT,
		|	DocSalesOrder.ARAPObjectSettings AS ARAPObjectSettings,
		|	DocSalesOrder.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	DocSalesOrder.ToReturnReusablePackage AS ToReturnReusablePackage,
		|	DocSalesOrder.PackageDepositIsRequired AS PackageDepositIsRequired,
		|	DocSalesOrder.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
		|	DocSalesOrder.PaymentMethod AS PaymentMethod,
		|	DocSalesOrder.PaymentSchedule AS PaymentSchedule,
		|	DocSalesOrder.BankAccount AS BankAccount,
		|	DocSalesOrder.CashAccount AS CashAccount,
		|	DocSalesOrder.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	DocSalesOrder.Shipper AS Shipper,
		|	DocSalesOrder.GoodsRecipient AS GoodsRecipient,
		|	DocSalesOrder.ShipperBankAccount AS ShipperBankAccount,
		|	DocSalesOrder.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN GoodsTable.Ref.Warehouse.IsFolder
		|		AND GoodsTable.Ref.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE GoodsTable.Ref.Warehouse
		|	END AS OriginWarehouse,
		|	DocSalesOrder.DeliveryMethod AS DeliveryMethod,
		|	DocSalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) AS MethodOfDeliveryByCarrier,
		|	DocSalesOrder.CarrierPartner AS CarrierPartner,
		|	DocSalesOrder.DeliveryAddress AS DeliveryAddress,
		|	DocSalesOrder.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
		|	DocSalesOrder.DeliveryAddressValue AS DeliveryAddressValue,
		|	DocSalesOrder.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
		|	DocSalesOrder.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	DocSalesOrder.DeliveryZone AS DeliveryZone,
		|	DocSalesOrder.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	DocSalesOrder.DeliveryTimeTo AS DeliveryTimeTo,
		|	DocSalesOrder.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
		|	&RTUDocumentName AS DocumentName,
		|	GoodsTable.Ref.LineOfBusiness AS LineOfBusiness,
		|	DocSalesOrder.ContactPerson AS ContactPerson,
		|	DocSalesOrder.LoyaltyCard AS LoyaltyCard,
		|	DocSalesOrder.UISStateContractStep AS UISStateContractStep,
		|	DocSalesOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	DocSalesOrder.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
		|	FALSE AS ThereIsInvalidOperation
		|INTO TTCustomerOrders_
		|FROM
		|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
		|		INNER JOIN Document.SalesOrder AS DocSalesOrder
		|		ON GoodsTable.ReferenceOrder = DocSalesOrder.Ref
		|WHERE
		|	GoodsTable.Ref IN (&ReferencesArrray)
		|
		|UNION ALL
		|
		|SELECT
		|	DocShipmentOfItems.Ref AS SalesOrder,
		|	GoodsTable.Ref.Partner AS Partner,
		|	GoodsTable.Ref.Counterparty AS Counterparty,
		|	GoodsTable.Ref.Contract AS Contract,
		|	GoodsTable.Ref.Organization AS Organization,
		|	GoodsTable.Ref.Terms AS Terms,
		|	GoodsTable.Ref.SalesOpportunity AS SalesOpportunity,
		|	GoodsTable.Ref.Warehouse AS Warehouse,
		|	GoodsTable.Ref.Department AS Department,
		|	GoodsTable.Ref.BusinessOperation AS BusinessOperation,
		|	GoodsTable.Ref.Currency AS ARAPCurrency,
		|	DocShipmentOfItems.VATTaxation AS VATTaxation,
		|	TRUE AS PriceIncludesVAT,
		|	VALUE(Enum.ARAPObjectSettings.EmptyRef) AS ARAPObjectSettings,
		|	FALSE AS ForeignCurrencyTransaction,
		|	FALSE AS ToReturnReusablePackage,
		|	FALSE AS PackageDepositIsRequired,
		|	0 AS ReusablePackageReturnCycleLength,
		|	VALUE(Enum.PaymentForms.EmptyRef) AS PaymentMethod,
		|	VALUE(Catalog.PaymentSchedules.EmptyRef) AS PaymentSchedule,
		|	DocShipmentOfItems.CompanyBankAccount AS BankAccount,
		|	VALUE(Catalog.CashAccounts.EmptyRef) AS CashAccount,
		|	DocShipmentOfItems.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	DocShipmentOfItems.Shipper AS Shipper,
		|	DocShipmentOfItems.GoodsRecipient AS GoodsRecipient,
		|	DocShipmentOfItems.ShipperBankAccount AS ShipperBankAccount,
		|	DocShipmentOfItems.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN GoodsTable.Ref.Warehouse.IsFolder
		|		AND GoodsTable.Ref.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE GoodsTable.Ref.Warehouse
		|	END AS OriginWarehouse,
		|	DocShipmentOfItems.DeliveryMethod AS DeliveryMethod,
		|	DocShipmentOfItems.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) AS MethodOfDeliveryByCarrier,
		|	DocShipmentOfItems.CarrierPartner AS CarrierPartner,
		|	DocShipmentOfItems.DeliveryAddress AS DeliveryAddress,
		|	DocShipmentOfItems.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
		|	DocShipmentOfItems.DeliveryAddressValue AS DeliveryAddressValue,
		|	DocShipmentOfItems.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
		|	DocShipmentOfItems.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	DocShipmentOfItems.DeliveryZone AS DeliveryZone,
		|	DocShipmentOfItems.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	DocShipmentOfItems.DeliveryTimeTo AS DeliveryTimeTo,
		|	DocShipmentOfItems.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
		|	&RTUDocumentName AS DocumentName,
		|	GoodsTable.Ref.LineOfBusiness AS LineOfBusiness,
		|	DocShipmentOfItems.ContactPerson AS ContactPerson,
		|	VALUE(Catalog.LoyaltyCards.EmptyRef) AS LoyaltyCard,
		|	"""" AS UISStateContractStep,
		|	VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef) AS FinancialAccountingGroup,
		|	FALSE AS ThisIsOrderAsInvoice,
		|	FALSE AS ThereIsInvalidOperation
		|FROM
		|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
		|		INNER JOIN Document.GoodsShipmentToCustomer AS DocShipmentOfItems
		|		ON GoodsTable.ReferenceOrder = DocShipmentOfItems.Ref
		|WHERE
		|	GoodsTable.Ref IN (&ReferencesArrray)
		|
		|UNION ALL
		|
		|SELECT
		|	DocReturnRequest.Ref AS SalesOrder,
		|	GoodsTable.Ref.Partner AS Partner,
		|	GoodsTable.Ref.Counterparty AS Counterparty,
		|	GoodsTable.Ref.Contract AS Contract,
		|	GoodsTable.Ref.Organization AS Organization,
		|	GoodsTable.Ref.Terms AS Terms,
		|	GoodsTable.Ref.SalesOpportunity AS SalesOpportunity,
		|	GoodsTable.Ref.Warehouse AS Warehouse,
		|	GoodsTable.Ref.Department AS Department,
		|	GoodsTable.Ref.BusinessOperation AS BusinessOperation,
		|	GoodsTable.Ref.Currency AS ARAPCurrency,
		|	DocReturnRequest.VATTaxation AS VATTaxation,
		|	DocReturnRequest.PriceIncludesVAT AS PriceIncludesVAT,
		|	DocReturnRequest.ARAPObjectSettings AS ARAPObjectSettings,
		|	DocReturnRequest.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	DocReturnRequest.ToReturnReusablePackage AS ToReturnReusablePackage,
		|	DocReturnRequest.PackageDepositIsRequired AS PackageDepositIsRequired,
		|	DocReturnRequest.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
		|	DocReturnRequest.PaymentMethod AS PaymentMethod,
		|	DocReturnRequest.PaymentSchedule AS PaymentSchedule,
		|	DocReturnRequest.BankAccount AS BankAccount,
		|	DocReturnRequest.CashAccount AS CashAccount,
		|	DocReturnRequest.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	DocReturnRequest.Shipper AS Shipper,
		|	DocReturnRequest.GoodsRecipient AS GoodsRecipient,
		|	DocReturnRequest.ShipperBankAccount AS ShipperBankAccount,
		|	DocReturnRequest.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN GoodsTable.Ref.Warehouse.IsFolder
		|		AND GoodsTable.Ref.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE GoodsTable.Ref.Warehouse
		|	END AS OriginWarehouse,
		|	DocReturnRequest.DeliveryMethod AS DeliveryMethod,
		|	DocReturnRequest.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) AS MethodOfDeliveryByCarrier,
		|	DocReturnRequest.CarrierPartner AS CarrierPartner,
		|	DocReturnRequest.DeliveryAddress AS DeliveryAddress,
		|	DocReturnRequest.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
		|	DocReturnRequest.DeliveryAddressValue AS DeliveryAddressValue,
		|	DocReturnRequest.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
		|	DocReturnRequest.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	DocReturnRequest.DeliveryZone AS DeliveryZone,
		|	DocReturnRequest.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	DocReturnRequest.DeliveryTimeTo AS DeliveryTimeTo,
		|	DocReturnRequest.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
		|	&RTUDocumentName AS DocumentName,
		|	GoodsTable.Ref.LineOfBusiness AS LineOfBusiness,
		|	DocReturnRequest.ContactPerson AS ContactPerson,
		|	VALUE(Catalog.LoyaltyCards.EmptyRef) AS LoyaltyCard,
		|	"""" AS UISStateContractStep,
		|	VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef) AS FinancialAccountingGroup,
		|	DocReturnRequest.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
		|	FALSE AS ThereIsInvalidOperation
		|FROM
		|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
		|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocReturnRequest
		|		ON GoodsTable.ReferenceOrder = DocReturnRequest.Ref
		|WHERE
		|	GoodsTable.Ref IN (&ReferencesArrray)
		|";
		
		If ValueIsFilled(TextOrders) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextOrders);
			QueryTexts.Add(StrReplace(QueryText, "INTO TTCustomerOrders_", ""));
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextOrders = QueryText;
		
	EndIf;

	// The credit note is an order for the receipt of goods from the customer - 
	// this is a separate return from the customer; adjustment by fin. parts, arrival at the warehouse. parts.
	If AccessRight("Read", Metadata.Documents.SaleAdjustment) Then
		
		TextOrders = 
		"SELECT
		|	Table.Ref                                AS SalesOrder,
		|	Table.Partner                               AS Partner,
		|	Table.Counterparty                            AS Counterparty,
		|	Table.Contract                               AS Contract,
		|	Table.Organization                           AS Organization,
		|	Table.Terms                            AS Terms,
		|	Table.SalesOpportunity                                AS SalesOpportunity,
		|	Table.Warehouse                                 AS Warehouse,
		|	Table.Department                         AS Department,
		|	Table.BusinessOperation                 AS BusinessOperation,
		|	Table.Currency                                AS ARAPCurrency,
		|	Table.VATTaxation                    AS VATTaxation,
		|	Table.PriceIncludesVAT                       AS PriceIncludesVAT,
		|	Table.ARAPObjectSettings                       AS ARAPObjectSettings,
		|	UNDEFINED                                  AS ForeignCurrencyTransaction,
		|	UNDEFINED                                  AS ToReturnReusablePackage,
		|	UNDEFINED                                  AS PackageDepositIsRequired,
		|	UNDEFINED                                  AS ReusablePackageReturnCycleLength,
		|	Table.PaymentMethod                           AS PaymentMethod,
		|	Table.PaymentSchedule                          AS PaymentSchedule,
		|	Table.CompanyBankAccount             AS BankAccount,
		|	UNDEFINED                                  AS CashAccount,
		|	Table.CounterpartyBankAccount             AS CounterpartyBankAccount,
		|	Table.Shipper                      AS Shipper,
		|	Table.GoodsRecipient                       AS GoodsRecipient,
		|	Table.ShipperBankAccount        AS ShipperBankAccount,
		|	Table.GoodsRecipientBankAccount         AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN
		|			Table.Warehouse.IsFolder AND Table.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|		THEN
		|			VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE
		|			Table.Warehouse
		|	END AS OriginWarehouse,
		|	UNDEFINED                                  AS DeliveryMethod,
		|	UNDEFINED                                  AS MethodOfDeliveryByCarrier,
		|
		|	UNDEFINED                                  AS CarrierPartner,
		|	Table.DeliveryAddress                         AS DeliveryAddress,
		|	Table.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
		|	Table.DeliveryAddressValue AS DeliveryAddressValue,
		|	UNDEFINED                                  AS DeliveryAddressOfCarrier,
		|	""""                                          AS DeliveryAddressOfCarrierFieldValues,
		|	UNDEFINED                                  AS DeliveryZone,
		|	UNDEFINED                                  AS DeliveryTimeFrom,
		|	UNDEFINED                                  AS DeliveryTimeTo,
		|	""""                                          AS AdditionalDeliveryInformation,
		|	&RTUDocumentName                              AS DocumentName,
		|	Table.LineOfBusiness               AS LineOfBusiness,
		|	UNDEFINED                                  AS ContactPerson,
		|	UNDEFINED                                  AS LoyaltyCard,
		|	Table.UISStateContractStep                   AS UISStateContractStep,
		|	Table.FinancialAccountingGroup                AS FinancialAccountingGroup,
		|	UNDEFINED                                  AS ThisIsOrderAsInvoice,
		|	NOT Table.BusinessOperation IN(&ValidOperations) AS ThereIsInvalidOperation
		|INTO TTCustomerOrders_
		|FROM
		|	Document.SaleAdjustment AS Table
		|WHERE
		|	Table.Ref IN (&ReferencesArrray)";
		
		If ValueIsFilled(TextOrders) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextOrders);
			QueryTexts.Add(StrReplace(QueryText, "INTO TTCustomerOrders_", ""));
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextOrders = QueryText;
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.MaterialProviderOrder2_5) Then
		
		QueryText =
		"SELECT
		|	MaterialProviderOrder2_5.Ref                                          AS SalesOrder,
		|	MaterialProviderOrder2_5.Partner                                         AS Partner,
		|	MaterialProviderOrder2_5.Counterparty                                      AS Counterparty,
		|	MaterialProviderOrder2_5.Contract                                         AS Contract,
		|	MaterialProviderOrder2_5.Organization                                     AS Organization,
		|	VALUE(Catalog.TermsOfSale.EmptyRef)           AS Terms,
		|	MaterialProviderOrder2_5.SalesOpportunity                                          AS SalesOpportunity,
		|	MaterialProviderOrder2_5.Warehouse                                           AS Warehouse,
		|	MaterialProviderOrder2_5.Department                                   AS Department,
		|	VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5) AS BusinessOperation,
		|	MaterialProviderOrder2_5.Currency                                          AS ARAPCurrency,
		|	MaterialProviderOrder2_5.VATTaxation                              AS VATTaxation,
		|	MaterialProviderOrder2_5.PriceIncludesVAT                                 AS PriceIncludesVAT,
		|	MaterialProviderOrder2_5.ARAPObjectSettings                                 AS ARAPObjectSettings,
		|	MaterialProviderOrder2_5.ForeignCurrencyTransaction                                   AS ForeignCurrencyTransaction,
		|	FALSE                                                             AS ToReturnReusablePackage,
		|	MaterialProviderOrder2_5.PackageDepositIsRequired                            AS PackageDepositIsRequired,
		|	0                                                                AS ReusablePackageReturnCycleLength,
		|	MaterialProviderOrder2_5.PaymentMethod                                     AS PaymentMethod,
		|	MaterialProviderOrder2_5.PaymentSchedule                                    AS PaymentSchedule,
		|	MaterialProviderOrder2_5.BankAccount                                  AS BankAccount,
		|	MaterialProviderOrder2_5.CashAccount                                           AS CashAccount,
		|	MaterialProviderOrder2_5.CounterpartyBankAccount                       AS CounterpartyBankAccount,
		|	MaterialProviderOrder2_5.Shipper                                AS Shipper,
		|	MaterialProviderOrder2_5.GoodsRecipient                                 AS GoodsRecipient,
		|	MaterialProviderOrder2_5.ShipperBankAccount                  AS ShipperBankAccount,
		|	MaterialProviderOrder2_5.GoodsRecipientBankAccount                   AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN MaterialProviderOrder2_5.Warehouse.IsFolder
		|			AND MaterialProviderOrder2_5.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|				THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE MaterialProviderOrder2_5.Warehouse
		|	END                                                            AS OriginWarehouse,
		|	MaterialProviderOrder2_5.DeliveryMethod                                  AS DeliveryMethod,
		|	CASE
		|		WHEN MaterialProviderOrder2_5.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                            AS MethodOfDeliveryByCarrier,
		|	MaterialProviderOrder2_5.CarrierPartner                               AS CarrierPartner,
		|	MaterialProviderOrder2_5.DeliveryAddress                                   AS DeliveryAddress,
		|	MaterialProviderOrder2_5.DeliveryAddressFieldValues                      AS DeliveryAddressFieldValues,
		|	MaterialProviderOrder2_5.DeliveryAddressValue AS DeliveryAddressValue,
		|	MaterialProviderOrder2_5.DeliveryAddressOfCarrier                        AS DeliveryAddressOfCarrier,
		|	MaterialProviderOrder2_5.DeliveryAddressOfCarrierFieldValues           AS DeliveryAddressOfCarrierFieldValues,
		|	MaterialProviderOrder2_5.DeliveryZone                                    AS DeliveryZone,
		|	MaterialProviderOrder2_5.DeliveryTimeFrom                                  AS DeliveryTimeFrom,
		|	MaterialProviderOrder2_5.DeliveryTimeTo                                 AS DeliveryTimeTo,
		|	MaterialProviderOrder2_5.AdditionalDeliveryInformation              AS AdditionalDeliveryInformation,
		|	&RTUDocumentName                                                 AS DocumentName,
		|	MaterialProviderOrder2_5.LineOfBusiness                         AS LineOfBusiness,
		|	MaterialProviderOrder2_5.ContactPerson                                  AS ContactPerson,
		|	VALUE(Catalog.LoyaltyCards.EmptyRef)                AS LoyaltyCard,
		|	""""                                                             AS UISStateContractStep,
		|	MaterialProviderOrder2_5.FinancialAccountingGroup                          AS FinancialAccountingGroup,
		|	UNDEFINED                                                     AS ThisIsOrderAsInvoice,
		|	CASE
		|		WHEN VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5) IN (&ValidOperations)
		|			THEN FALSE
		|		ELSE TRUE
		|	END                                                            AS ThereIsInvalidOperation
		|INTO TTCustomerOrders_
		|FROM
		|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
		|WHERE
		|	MaterialProviderOrder2_5.Ref IN (&ReferencesArrray)";
		
		If ValueIsFilled(TextOrders) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextOrders);
			QueryTexts.Add(StrReplace(QueryText, "INTO TTCustomerOrders_", ""));
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextOrders = QueryText;
		
	EndIf;
	TextDataOfDocuments = "";
	
	If AccessRight("Read", Metadata.Documents.SalesOrder) Then
		TextDataOfDocuments = "
		|SELECT
		|	SalesOrder.Ref AS SalesOrder,
		|	SalesOrder.Status AS Status,
		|	NOT SalesOrder.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN
		|			SalesOrder.Status IN (&ArrayOfCustomerOrderStatuses)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus,
		|	SalesOrder.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
		|	
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref IN (&ReferencesArrray)
		|	AND SalesOrder.BusinessOperation IN(&ValidOperations)
		|	AND (NOT SalesOrder.Posted
		|		OR NOT SalesOrder.Status IN(&ArrayOfCustomerOrderStatuses))";
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
		If TextDataOfDocuments <> "" Then
			TextDataOfDocuments = TextDataOfDocuments + "
			|
			|UNION ALL
			|";
		EndIf; 
		TextDataOfDocuments = TextDataOfDocuments + "
		|SELECT
		|	ReturnRequest.Ref AS SalesOrder,
		|	ReturnRequest.Status AS Status,
		|	NOT ReturnRequest.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN
		|			ReturnRequest.Status IN (&ArrayOfRefundRequestStatuses)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus,
		|	ReturnRequest.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
		|WHERE
		|	ReturnRequest.Ref IN(&ReferencesArrray)
		|	AND (CASE
		|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|				OR ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
		|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
		|			THEN VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|		ELSE
		|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|	END) IN(&ValidOperations)
		|	AND (NOT ReturnRequest.Posted
		|		OR NOT ReturnRequest.Status IN(&ArrayOfRefundRequestStatuses))";
	EndIf; 
	
	If AccessRight("Read", Metadata.Documents.GoodsShipmentToCustomer) Then
		
		QueryText =
		"SELECT
		|	GoodsShipmentToCustomer.Ref			AS SalesOrder,
		|	UNDEFINED								AS Status,
		|	NOT GoodsShipmentToCustomer.Posted		AS ThereAreErrorsPosted,
		|	FALSE										AS ThereAreErrorsStatus,
		|	UNDEFINED								AS ThisIsOrderAsInvoice
		|FROM
		|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
		|WHERE
		|	GoodsShipmentToCustomer.Ref IN (&ReferencesArrray)";
		
		If ValueIsFilled(TextDataOfDocuments) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextDataOfDocuments);
			QueryTexts.Add(QueryText);
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextDataOfDocuments = QueryText;
		
	EndIf;

	If AccessRight("Read", Metadata.Documents.SaleAdjustment) Then
		
		QueryText =
		"SELECT
		|	SaleAdjustment.Ref			AS SalesOrder,
		|	UNDEFINED								AS Status,
		|	NOT SaleAdjustment.Posted	AS ThereAreErrorsPosted,
		|	FALSE										AS ThereAreErrorsStatus,
		|	UNDEFINED								AS ThisIsOrderAsInvoice
		|FROM
		|	Document.SaleAdjustment AS SaleAdjustment
		|WHERE
		|	SaleAdjustment.Ref IN (&ReferencesArrray)";
		
		If ValueIsFilled(TextDataOfDocuments) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextDataOfDocuments);
			QueryTexts.Add(QueryText);
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextDataOfDocuments = QueryText;
		
	EndIf;

	If AccessRight("Read", Metadata.Documents.GoodsReceiptFromCustomer) Then
		
		QueryText =
		"SELECT
		|	GoodsReceiptFromCustomer.Ref      AS SalesOrder,
		|	UNDEFINED                            AS Status,
		|	NOT GoodsReceiptFromCustomer.Posted AS ThereAreErrorsPosted,
		|	FALSE                                    AS ThereAreErrorsStatus,
		|	UNDEFINED                            AS ThisIsOrderAsInvoice
		|FROM
		|	Document.GoodsReceiptFromCustomer AS GoodsReceiptFromCustomer
		|WHERE
		|	GoodsReceiptFromCustomer.Ref IN (&ReferencesArrray)";
		
		If ValueIsFilled(TextDataOfDocuments) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextDataOfDocuments);
			QueryTexts.Add(QueryText);
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextDataOfDocuments = QueryText;
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.MaterialProviderOrder2_5) Then
		
		QueryText =
		"SELECT
		|	MaterialProviderOrder2_5.Ref                                     AS SalesOrder,
		|	MaterialProviderOrder2_5.Status                                     AS Status,
		|	NOT MaterialProviderOrder2_5.Posted                                AS ThereAreErrorsPosted,
		|	NOT MaterialProviderOrder2_5.Status IN (&ArrayOfStatusesOfGiverSOrder) AS ThereAreErrorsStatus,
		|	UNDEFINED                                                AS ThisIsOrderAsInvoice
		|FROM
		|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
		|WHERE
		|	MaterialProviderOrder2_5.Ref IN (&ReferencesArrray)
		|	AND VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5) IN (&ValidOperations)
		|	AND (NOT MaterialProviderOrder2_5.Posted OR NOT MaterialProviderOrder2_5.Status IN (&ArrayOfStatusesOfGiverSOrder))";
		
		If ValueIsFilled(TextDataOfDocuments) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(TextDataOfDocuments);
			QueryTexts.Add(QueryText);
			
			CommonClientServer.DeleteAllValueOccurrencesFromArray(QueryTexts, "");
			QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			
		EndIf;
			
		TextDataOfDocuments = QueryText;
		
	EndIf;
	QueryText = TextOrders + 
	";
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	SalesOrders.SalesOrder          AS SalesOrder,
	|	SalesOrders.BusinessOperation AS BusinessOperation
	|FROM
	|	TTCustomerOrders_ AS SalesOrders
	|WHERE
	|	SalesOrders.ThereIsInvalidOperation
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	MIN(CustomerOrders.DocumentName)                   AS DocumentName,
	|	MIN(CustomerOrders.Partner)                        AS Partner,
	|	MIN(CustomerOrders.Counterparty)                     AS Counterparty,
	|	MIN(CustomerOrders.Contract)                        AS Contract,
	|	MIN(CustomerOrders.Organization)                    AS Organization,
	|	MIN(CustomerOrders.LoyaltyCard)                AS LoyaltyCard,
	|	MIN(CustomerOrders.Terms)                     AS Terms,
	|	MIN(CustomerOrders.SalesOpportunity)                         AS SalesOpportunity,
	|	MIN(CustomerOrders.Warehouse)                          AS Warehouse,
	|	MIN(CustomerOrders.BusinessOperation)          AS BusinessOperation,
	|	MIN(CustomerOrders.ARAPCurrency)           AS ARAPCurrency,
	|	MIN(CustomerOrders.VATTaxation)             AS VATTaxation,
	|	MIN(CustomerOrders.PriceIncludesVAT)                AS PriceIncludesVAT,
	|	MIN(CustomerOrders.ARAPObjectSettings)                AS ARAPObjectSettings,
	|	MIN(CustomerOrders.ForeignCurrencyTransaction)                  AS ForeignCurrencyTransaction,
	|	MIN(CustomerOrders.ToReturnReusablePackage)      AS ToReturnReusablePackage,
	|	MIN(CustomerOrders.PackageDepositIsRequired)           AS PackageDepositIsRequired,
	|	MIN(CustomerOrders.ReusablePackageReturnCycleLength) AS ReusablePackageReturnCycleLength,
	|	MIN(CustomerOrders.LineOfBusiness)        AS LineOfBusiness,
	|	MIN(CustomerOrders.UISStateContractStep)            AS UISStateContractStep,
	|	MIN(CustomerOrders.FinancialAccountingGroup)         AS FinancialAccountingGroup,
	|	MIN(CustomerOrders.ThisIsOrderAsInvoice)                AS ThisIsOrderAsInvoice,
	|	MIN(CustomerOrders.PaymentSchedule)                   AS PaymentSchedule,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.PaymentMethod) > 1
	|		THEN
	|			VALUE(Enum.PaymentForms.EmptyRef)
	|		ELSE
	|			MIN(CustomerOrders.PaymentMethod)
	|	END AS PaymentMethod,
	|	MIN(
	|		CASE
	|			WHEN &ToUseTermsOfSales
	|				THEN CustomerOrders.Terms.CalculatePackageReturnDateAccordingToCalendar
	|			ELSE FALSE
	|		END) AS CalculatePackageReturnDateAccordingToCalendar,
	|	MIN(
	|		CASE
	|			WHEN &ToUseTermsOfSales 
	|				THEN CustomerOrders.Terms.ScheduleOfPackageReturn
	|			ELSE VALUE(Catalog.BusinessCalendars.EmptyRef)
	|		END) AS ScheduleOfPackageReturn,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.Department) > 1
	|		THEN
	|			VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE
	|			MIN(CustomerOrders.Department)
	|	END AS Department,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|					THEN
	|						CustomerOrders.ContactPerson
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT CustomerOrders.ContactPerson) = 1
	|		THEN
	|			MAX(CustomerOrders.ContactPerson)
	|		ELSE
	|			VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|	END AS ContactPerson,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.Partner) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPartner,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.Counterparty) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCounterparty,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.Contract) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesContract,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.Organization) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCompany,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.Terms) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesAgreement,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.SalesOpportunity) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesSalesOpportunity,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.OriginWarehouse) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesWarehouse,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.BusinessOperation) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesEconomicOperation,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.ARAPCurrency) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInCurrencyOfMutualSettlements,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.VATTaxation) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesVATTaxation,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.PriceIncludesVAT) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPriceIncludesVAT,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.ToReturnReusablePackage) > 1
	|				AND NOT &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInMultiTurnContainers,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.PackageDepositIsRequired) > 1
	|				AND NOT &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesDepositForContainerIsRequired,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.ReusablePackageReturnCycleLength) > 1
	|				AND NOT &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInReturnPeriodOfMultiTurnContainers,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.ARAPObjectSettings) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInOrderOfCalculations,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN
	|						CustomerOrders.BankAccount
	|					ELSE
	|						NULL
	|				END) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|					THEN
	|						CustomerOrders.CashAccount
	|					ELSE
	|						NULL
	|				END) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesCheckout,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.PaymentMethod) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInFormOfPayment,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.ForeignCurrencyTransaction) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesPaymentInCurrency,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|					THEN
	|						CustomerOrders.BankAccount
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(CustomerOrders.BankAccount)
	|		ELSE
	|			VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|	END AS BankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
	|					THEN
	|						CustomerOrders.CashAccount
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(CustomerOrders.CashAccount)
	|		ELSE
	|			VALUE(Catalog.CashAccounts.EmptyRef)
	|	END AS CashAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|					THEN
	|						CustomerOrders.CounterpartyBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT CustomerOrders.Counterparty) = 1
	|		THEN
	|			MAX(CustomerOrders.CounterpartyBankAccount)
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS CounterpartyBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						CustomerOrders.Shipper
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(CustomerOrders.Shipper)
	|		ELSE
	|			VALUE(Catalog.Counterparties.EmptyRef)
	|	END AS Shipper,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.GoodsRecipient <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						CustomerOrders.GoodsRecipient
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(CustomerOrders.GoodsRecipient)
	|		ELSE
	|			VALUE(Catalog.Counterparties.EmptyRef)
	|	END AS GoodsRecipient,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.ShipperBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|					THEN
	|						CustomerOrders.ShipperBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						CustomerOrders.Shipper
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(CustomerOrders.ShipperBankAccount)
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS ShipperBankAccount,
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.GoodsRecipientBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|					THEN
	|						CustomerOrders.GoodsRecipientBankAccount
	|					ELSE
	|						NULL
	|				END) = 1 AND
	|			COUNT(DISTINCT
	|				CASE
	|					WHEN
	|						CustomerOrders.GoodsRecipient <> VALUE(Catalog.Counterparties.EmptyRef)
	|					THEN
	|						CustomerOrders.GoodsRecipient
	|					ELSE
	|						NULL
	|				END) = 1
	|		THEN
	|			MAX(CustomerOrders.GoodsRecipientBankAccount)
	|		ELSE
	|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END AS GoodsRecipientBankAccount,
	|	MIN(CustomerOrders.OriginWarehouse) AS OriginWarehouse,
	|	CASE
	|		WHEN
	|			MIN(CustomerOrders.Warehouse.IsFolder) = TRUE AND MIN(CustomerOrders.Warehouse.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ItIsForbiddenToSelectWarehouseGroup,
	|	CASE
	|		WHEN COUNT(DISTINCT CustomerOrders.DeliveryMethod) = 1
	|			THEN MIN(CustomerOrders.DeliveryMethod)
	|		ELSE VALUE(Enum.TransportMethods.SelfPickup)
	|	END AS DeliveryMethod,
	|	CASE
	|		WHEN MIN(CustomerOrders.DeliveryMethod) = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND COUNT(DISTINCT CustomerOrders.CarrierPartner) = 1
	|		THEN MIN(CustomerOrders.CarrierPartner)
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS CarrierPartner,
	|	CASE
	|		WHEN COUNT(DISTINCT CustomerOrders.DeliveryAddress) = 1
	|		THEN MIN(CustomerOrders.DeliveryAddress)
	|		ELSE """"
	|	END AS DeliveryAddress,
	|	CASE
	|		WHEN COUNT(DISTINCT CustomerOrders.DeliveryAddress) = 1
	|		THEN MIN(CAST(CustomerOrders.DeliveryAddressFieldValues AS STRING(10))) = """"
	|		ELSE TRUE
	|	END AS DeliveryAddressFieldValuesEmpty,
	|	CASE
	|		WHEN COUNT(DISTINCT CustomerOrders.DeliveryAddress) = 1
	|		THEN MIN(CAST(CustomerOrders.DeliveryAddressValue AS STRING(10))) = """"
	|		ELSE TRUE
	|	END AS DeliveryAddressValueIsEmpty,
	|	CASE
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|			AND MIN(CustomerOrders.DeliveryMethod) = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND COUNT(DISTINCT CAST(CustomerOrders.AdditionalDeliveryInformation AS STRING(10))) = 1
	|		THEN MIN(CAST(CustomerOrders.AdditionalDeliveryInformation AS STRING(10))) = """"
	|		ELSE TRUE
	|	END AS AdditionalInformationOnDeliveryOfEmpty,
	|	UNDEFINED AS DeliveryAddressOfCarrier,
	|	UNDEFINED AS DeliveryAddressOfCarrierFieldValues,
	|	UNDEFINED AS DeliveryZone,
	|	UNDEFINED AS DeliveryTimeFrom,
	|	UNDEFINED AS DeliveryTimeTo,
	|
	|	NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|		AND COUNT(DISTINCT CustomerOrders.DeliveryMethod) > 1
	|		AND MAX(CustomerOrders.MethodOfDeliveryByCarrier) = TRUE
	|		AS ThereAreIncompatibleShippingMethods,
	|
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.LineOfBusiness) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInDirectionOfActivity,
	|
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.FinancialAccountingGroup) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesInFinancialAccounting,
	|
	|	CASE
	|		WHEN
	|			COUNT(DISTINCT CustomerOrders.ThisIsOrderAsInvoice) > 1
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThereAreDifferencesThisIsOrderAsInvoice
	|
	|INTO TTHeaderDetails
	|FROM
	|	TTCustomerOrders_ AS CustomerOrders
	|WHERE
	|	CustomerOrders.BusinessOperation IN(&ValidOperations)
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT TOP 1
	|	DocumentHeader.DocumentName                   AS DocumentName,
	|	DocumentHeader.Partner                        AS Partner,
	|	DocumentHeader.Counterparty                     AS Counterparty,
	|	DocumentHeader.Contract                        AS Contract,
	|	DocumentHeader.Organization                    AS Organization,
	|	DocumentHeader.LoyaltyCard                AS LoyaltyCard,
	|	DocumentHeader.Terms                     AS Terms,
	|	DocumentHeader.SalesOpportunity                         AS SalesOpportunity,
	|	DocumentHeader.Warehouse                          AS Warehouse,
	|	DocumentHeader.BusinessOperation          AS BusinessOperation,
	|	DocumentHeader.ARAPCurrency           AS ARAPCurrency,
	|	DocumentHeader.VATTaxation             AS VATTaxation,
	|	DocumentHeader.PriceIncludesVAT                AS PriceIncludesVAT,
	|	DocumentHeader.ARAPObjectSettings                AS ARAPObjectSettings,
	|	DocumentHeader.PaymentMethod                    AS PaymentMethod,
	|	DocumentHeader.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction,
	|	DocumentHeader.ToReturnReusablePackage      AS ToReturnReusablePackage,
	|	DocumentHeader.PackageDepositIsRequired           AS PackageDepositIsRequired,
	|	DocumentHeader.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
	|	DocumentHeader.LineOfBusiness        AS LineOfBusiness,
	|	DocumentHeader.PaymentSchedule                   AS PaymentSchedule,
	|	DocumentHeader.CalculatePackageReturnDateAccordingToCalendar AS CalculatePackageReturnDateAccordingToCalendar,
	|	DocumentHeader.ScheduleOfPackageReturn          AS ScheduleOfPackageReturn,
	|	DocumentHeader.Department                  AS Department,
	|	DocumentHeader.ContactPerson                 AS ContactPerson,
	|	DocumentHeader.ThereAreDifferencesPartner             AS ThereAreDifferencesPartner,
	|	DocumentHeader.ThereAreDifferencesCounterparty          AS ThereAreDifferencesCounterparty,
	|	DocumentHeader.ThereAreDifferencesContract             AS ThereAreDifferencesContract,
	|	DocumentHeader.ThereAreDifferencesCompany         AS ThereAreDifferencesCompany,
	|	DocumentHeader.ThereAreDifferencesAgreement          AS ThereAreDifferencesAgreement,
	|	DocumentHeader.ThereAreDifferencesSalesOpportunity              AS ThereAreDifferencesSalesOpportunity,
	|	DocumentHeader.ThereAreDifferencesWarehouse               AS ThereAreDifferencesWarehouse,
	|	DocumentHeader.ThereAreDifferencesEconomicOperation AS ThereAreDifferencesEconomicOperation,
	|	DocumentHeader.ThereAreDifferencesInCurrencyOfMutualSettlements  AS ThereAreDifferencesInCurrencyOfMutualSettlements,
	|	DocumentHeader.ThereAreDifferencesVATTaxation  AS ThereAreDifferencesVATTaxation,
	|	DocumentHeader.ThereAreDifferencesPriceIncludesVAT     AS ThereAreDifferencesPriceIncludesVAT,
	|	DocumentHeader.ThereAreDifferencesInMultiTurnContainers AS ThereAreDifferencesInMultiTurnContainers,
	|	DocumentHeader.ThereAreDifferencesDepositForContainerIsRequired AS ThereAreDifferencesDepositForContainerIsRequired,
	|	DocumentHeader.ThereAreDifferencesInReturnPeriodOfMultiTurnContainers AS ThereAreDifferencesInReturnPeriodOfMultiTurnContainers,
	|	DocumentHeader.ThereAreDifferencesInOrderOfCalculations     AS ThereAreDifferencesInOrderOfCalculations,
	|	CASE
	|		WHEN 
	|			NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			AND NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.EmptyRef)
	|		THEN
	|			FALSE
	|		ELSE
	|			DocumentHeader.ThereAreDifferencesBankAccount
	|	END AS ThereAreDifferencesBankAccount,
	|	CASE
	|		WHEN 
	|			NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|			AND NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.EmptyRef)
	|		THEN
	|			FALSE
	|		ELSE
	|			DocumentHeader.ThereAreDifferencesCheckout              
	|	END AS ThereAreDifferencesCheckout,
	|	DocumentHeader.ThereAreDifferencesInFormOfPayment         AS ThereAreDifferencesInFormOfPayment,
	|	DocumentHeader.ThereAreDifferencesPaymentInCurrency       AS ThereAreDifferencesPaymentInCurrency,
	|	CASE
	|		WHEN 
	|			NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.BankAccountPayment)
	|			AND NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.EmptyRef)
	|		THEN
	|			VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|		ELSE
	|			DocumentHeader.BankAccount
	|	END AS BankAccount,
	|	CASE
	|		WHEN 
	|			NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.CashAccountPayment_)
	|			AND NOT DocumentHeader.PaymentMethod = VALUE(Enum.PaymentForms.EmptyRef)
	|		THEN
	|			VALUE(Catalog.CashAccounts.EmptyRef)
	|		ELSE
	|			DocumentHeader.CashAccount
	|	END AS CashAccount,
	|	DocumentHeader.CounterpartyBankAccount      AS CounterpartyBankAccount,
	|	DocumentHeader.Shipper               AS Shipper,
	|	DocumentHeader.GoodsRecipient                AS GoodsRecipient,
	|	DocumentHeader.ShipperBankAccount AS ShipperBankAccount,
	|	DocumentHeader.GoodsRecipientBankAccount  AS GoodsRecipientBankAccount,
	|	DocumentHeader.OriginWarehouse                  AS OriginWarehouse,
	|	DocumentHeader.ItIsForbiddenToSelectWarehouseGroup AS ItIsForbiddenToSelectWarehouseGroup,
	|	DocumentHeader.DeliveryMethod                 AS DeliveryMethod,
	|	DocumentHeader.CarrierPartner              AS CarrierPartner,
	|	DocumentHeader.DeliveryAddress                  AS DeliveryAddress,
	|	DocumentHeader.UISStateContractStep            AS UISStateContractStep,
	|	DocumentHeader.FinancialAccountingGroup         AS FinancialAccountingGroup,
	|	DocumentHeader.ThisIsOrderAsInvoice                AS ThisIsOrderAsInvoice,
	|	CASE
	|		WHEN DocumentHeader.DeliveryAddressFieldValuesEmpty
	|		THEN """" 
	|		ELSE ISNULL(OrderHeader_.DeliveryAddressFieldValues, """")
	|	END AS DeliveryAddressFieldValues,
	|	CASE
	|		WHEN DocumentHeader.DeliveryAddressValueIsEmpty
	|		THEN """" 
	|		ELSE ISNULL(OrderHeader_.DeliveryAddressValue, """")
	|	END AS DeliveryAddressValue,
	|	CASE
	|		WHEN DocumentHeader.AdditionalInformationOnDeliveryOfEmpty
	|		THEN """" 
	|		ELSE ISNULL(OrderHeader_.AdditionalDeliveryInformation, """")
	|	END AS AdditionalDeliveryInformation,
	|	DocumentHeader.DeliveryAddressOfCarrier                 AS DeliveryAddressOfCarrier,
	|	DocumentHeader.DeliveryAddressOfCarrierFieldValues    AS DeliveryAddressOfCarrierFieldValues,
	|	DocumentHeader.DeliveryZone                             AS DeliveryZone,
	|	DocumentHeader.DeliveryTimeFrom                           AS DeliveryTimeFrom,
	|	DocumentHeader.DeliveryTimeTo                          AS DeliveryTimeTo,
	|	DocumentHeader.ThereAreIncompatibleShippingMethods         AS ThereAreIncompatibleShippingMethods,
	|	DocumentHeader.ThereAreDifferencesInDirectionOfActivity       AS ThereAreDifferencesInDirectionOfActivity,
	|	DocumentHeader.ThereAreDifferencesInFinancialAccounting        AS ThereAreDifferencesInFinancialAccounting,
	|	DocumentHeader.ThereAreDifferencesThisIsOrderAsInvoice               AS ThereAreDifferencesThisIsOrderAsInvoice
	|FROM
	|	TTHeaderDetails AS DocumentHeader
	|		LEFT JOIN TTCustomerOrders_ AS OrderHeader_
	|		ON TRUE
	|;
	|//////////////////////////////////////////////////////////////////////////////// 4
	|" + TextDataOfDocuments;
	
	ThisIsTransferOfGoodsToKeeper = ?(DocumentName = Metadata.Documents.TransferOfGoodsToBailee.Name, True, False);
	ThisIsShipmentOfGoodsFromStorage = ?(DocumentName = Metadata.Documents.GoodsShipmentFromStorage.Name, True, False);
	If ThisIsTransferOfGoodsToKeeper Then
		RTUDocumentName = NStr("vi = 'chuyển hàng cho người trông coi';
								|ru = 'передачи товаров хранителю';
								|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
								|it = 'consegne di merci al custode';
								|pl = 'transfer towarów do depozytariusza';
								|tr = 'VMI doldurma'");
	ElsIf ThisIsShipmentOfGoodsFromStorage Then
		RTUDocumentName = NStr("vi = 'chuyển cho người đặt gia công';
								|ru = 'передачи давальцу';
								|en = 'transfers to material provider'; fa = 'transfers to material provider';
								|it = 'trasferimenti al fornitore';
								|pl = 'przekazania właścicielowi surowców';
								|tr = 'tedarikçiye transfer'");
	Else
		RTUDocumentName = NStr("vi = 'giao hàng và cung cấp dịch vụ';
								|ru = 'реализации товаров и услуг';
								|en = 'customer invoice'; fa = 'customer invoice';
								|it = 'vendite di merci e servizi';
								|pl = 'sprzedaż towarów i usług';
								|tr = 'ürün ve hizmet satışları'");
	EndIf;
	
	ValidOperations = TMCommonUse.PermissibleBusinessOperationsOfDocument(DocumentName);
	
	Query = New Query(QueryText);
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("ValidOperations", ValidOperations);
	Query.SetParameter("RTUDocumentName", RTUDocumentName);
	Query.SetParameter("ThisIsTransferOfGoodsToKeeper", ThisIsTransferOfGoodsToKeeper);
	Query.SetParameter("ThisIsShipmentOfGoodsFromStorage", ThisIsShipmentOfGoodsFromStorage);
	Query.SetParameter("ToUseTermsOfSales", GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers", GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	StatusesMap = New Map;
	ArrayOfValidStatuses = Documents.SalesOrder.ValidInputStatusesBasedOn();
	StatusesMap.Insert(Type("EnumRef.SalesOrderStatuses"), ArrayOfValidStatuses);
	Query.SetParameter("ArrayOfCustomerOrderStatuses", ArrayOfValidStatuses);
	ArrayOfValidStatuses = Documents.RequestForReturnOfGoodsFromCustomer.ValidInputStatusesBasedOn();
	StatusesMap.Insert(Type("EnumRef.StatusesOfRequestsForReturnOfGoodsFromCustomers"), ArrayOfValidStatuses);
	Query.SetParameter("ArrayOfRefundRequestStatuses", ArrayOfValidStatuses);
	Query.SetParameter(
		"ArrayOfStatusesOfGiverSOrder",
		Documents.MaterialProviderOrder2_5.ValidInputStatusesBasedOn(DocumentName));
	QueryResult = Query.ExecuteBatch();
	SelectionHeaderDetails = QueryResult[3].Select();
	SelectionHeaderDetails.Next();
	
	ExcludedOrders = New Array;
	OrdersWithInvalidOperation = QueryResult[1].Select();
	
	While OrdersWithInvalidOperation.Next() Do
		
		If ReferencesArrray.Count() > 1 Then
			MessageText = NStr("vi = 'Đơn hàng %ReferenceOrder% bị bỏ qua vì không thể thực thi chứng từ ""%DocumentName%"" trên cơ sở đơn đặt hàng với hoạt động ""%BusinessOperation%"".';
								|ru = 'Распоряжение %ReferenceOrder% пропущено, т.к. невозможно оформить документ ""%DocumentName%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'The %ReferenceOrder% reference is skipped as you cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" transaction.'; fa = 'The %ReferenceOrder% reference is skipped as you cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" transaction.';
								|it = 'La disposizione %ReferenceOrder% è mancante, poiché non è possibile emettere il documento ""%DocumentName%"" sulla base della disposizione con operazione ""%BusinessOperation%"".';
								|pl = 'Zamówienie %ReferenceOrder% pominięte, ponieważ nie można wydać dokumentu ""%DocumentName%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = 'Sipariş %ReferenceOrder% atlandı çünkü ""%BusinessOperation%"" işlemi ile siparişe göre ""%DocumentName%"" belgesini düzenlemek mümkün değil.'");
		Else
			MessageText = NStr("vi = 'Không thể thực thi chứng từ ""%DocumentName%"" trên cơ sở đơn hàng với thao tác ""%BusinessOperation%"".';
								|ru = 'Невозможно оформить документ ""%DocumentName%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'Cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" operation.'; fa = 'Cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" operation.';
								|it = 'Non è possibile emettere il documento ""%DocumentName%"" in base alla disposizione con l''operazione ""%BusinessOperation%"".';
								|pl = 'Nie jest możliwe wystawienie dokumentu ""%DocumentName%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = '""%DocumentName%"" belgesini ""%BusinessOperation%"" işlemiyle siparişe göre düzenlemek mümkün değil.'");
		EndIf;
		
		MessageText = StrReplace(MessageText,
									"%DocumentName%",
									Metadata.Documents[DocumentName].Synonym);
		MessageText = StrReplace(MessageText,
									"%BusinessOperation%",
									OrdersWithInvalidOperation.BusinessOperation);
		MessageText = StrReplace(MessageText,
									"%ReferenceOrder%",
									OrdersWithInvalidOperation.SalesOrder);
		
		CommonClientServer.MessageToUser(MessageText, OrdersWithInvalidOperation.SalesOrder);
		
		ExcludedOrders.Add(OrdersWithInvalidOperation.SalesOrder);
	EndDo;
	
	If OrdersWithInvalidOperation.Count() = ReferencesArrray.Count() Then
		Return False;
	EndIf;
	
	ReferencesArrray = CommonClientServer.ArraysDifference(ReferencesArrray, ExcludedOrders);
	
	Cancel = False;
	
	If SalesServer.ReportErrorsInDataGenerationAndImplementation(SelectionHeaderDetails) Then
		
		ErrorText = NStr("vi = 'Không thể nhập một %Document% trên cơ sở các lệnh đã chọn';
						|ru = 'Ввод одной %Document% на основании выделенных распоряжений невозможен';
						|en = 'Cannot register one %Document% based on the selected references'; fa = 'Cannot register one %Document% based on the selected references';
						|it = 'L''immissione di un documento %Document% in base alle disposizioni stabilite non è possibile';
						|pl = 'Wpisanie jednego %Document% na podstawie wybranych zamówień jest niemożliwe';
						|tr = 'Seçilen siparişler bazında bir %Document% girmek mümkün değil'");
		ErrorText = StrReplace(ErrorText, "%Document%", SelectionHeaderDetails.DocumentName);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,
			Cancel);
		
	Else
		
		If Not QueryResult[4].IsEmpty() > 0 Then

			SampleOrders = QueryResult[4].Select();
			
			While SampleOrders.Next() Do
				If TypeOf(SampleOrders.SalesOrder) = Type("DocumentRef.MaterialProviderOrder2_5") Then
					
					Documents.MaterialProviderOrder2_5.CheckPossibilityOfEnteringBasedOn(
						SampleOrders.SalesOrder,
						SampleOrders.Status,
						SampleOrders.ThereAreErrorsPosted,
						DocumentName);
					
				Else
					MetadataOfDocument = SampleOrders.SalesOrder.Metadata(); // MetadataObjectDocument
					Documents[MetadataOfDocument.Name].CheckPossibilityOfEnteringBasedOn(
						SampleOrders.SalesOrder,
						SampleOrders.Status,
						SampleOrders.ThereAreErrorsPosted);
				EndIf;
			EndDo;
			
		EndIf;
		
		HeaderAttributes.Insert("Partner",                               SelectionHeaderDetails.Partner);
		HeaderAttributes.Insert("Counterparty",                            SelectionHeaderDetails.Counterparty);
		HeaderAttributes.Insert("Contract",                               SelectionHeaderDetails.Contract);
		HeaderAttributes.Insert("Organization",                           SelectionHeaderDetails.Organization);
		HeaderAttributes.Insert("Warehouse",                                 SelectionHeaderDetails.Warehouse);
		HeaderAttributes.Insert("Department",                         SelectionHeaderDetails.Department);
		HeaderAttributes.Insert("Terms",                            SelectionHeaderDetails.Terms);
		HeaderAttributes.Insert("BusinessOperation",                 SelectionHeaderDetails.BusinessOperation);
		HeaderAttributes.Insert("ARAPCurrency",                  SelectionHeaderDetails.ARAPCurrency);
		HeaderAttributes.Insert("VATTaxation",                    SelectionHeaderDetails.VATTaxation);
		HeaderAttributes.Insert("PriceIncludesVAT",                       SelectionHeaderDetails.PriceIncludesVAT);
		HeaderAttributes.Insert("ARAPObjectSettings",                       SelectionHeaderDetails.ARAPObjectSettings);
		HeaderAttributes.Insert("PaymentMethod",                           SelectionHeaderDetails.PaymentMethod);
		HeaderAttributes.Insert("PaymentSchedule",                          SelectionHeaderDetails.PaymentSchedule);
		HeaderAttributes.Insert("ForeignCurrencyTransaction",                         SelectionHeaderDetails.ForeignCurrencyTransaction);
		HeaderAttributes.Insert("ToReturnReusablePackage",             SelectionHeaderDetails.ToReturnReusablePackage);
		HeaderAttributes.Insert("PackageDepositIsRequired",                  SelectionHeaderDetails.PackageDepositIsRequired);
		HeaderAttributes.Insert("CalculatePackageReturnDateAccordingToCalendar", SelectionHeaderDetails.CalculatePackageReturnDateAccordingToCalendar);
		HeaderAttributes.Insert("ScheduleOfPackageReturn",                 SelectionHeaderDetails.ScheduleOfPackageReturn);
		HeaderAttributes.Insert("ReusablePackageReturnCycleLength",        SelectionHeaderDetails.ReusablePackageReturnCycleLength);
		HeaderAttributes.Insert("OriginWarehouse",                         SelectionHeaderDetails.OriginWarehouse);
		HeaderAttributes.Insert("ItIsForbiddenToSelectWarehouseGroup",        SelectionHeaderDetails.ItIsForbiddenToSelectWarehouseGroup);
		HeaderAttributes.Insert("SalesOpportunity",                                SelectionHeaderDetails.SalesOpportunity);
		HeaderAttributes.Insert("Shipper",                      SelectionHeaderDetails.Shipper);
		HeaderAttributes.Insert("GoodsRecipient",                       SelectionHeaderDetails.GoodsRecipient);
		HeaderAttributes.Insert("ShipperBankAccount",        SelectionHeaderDetails.ShipperBankAccount);
		HeaderAttributes.Insert("GoodsRecipientBankAccount",         SelectionHeaderDetails.GoodsRecipientBankAccount);
		HeaderAttributes.Insert("BankAccount",                        SelectionHeaderDetails.BankAccount);
		HeaderAttributes.Insert("CounterpartyBankAccount",             SelectionHeaderDetails.CounterpartyBankAccount);
		HeaderAttributes.Insert("LineOfBusiness",               SelectionHeaderDetails.LineOfBusiness);
		HeaderAttributes.Insert("ContactPerson",                        SelectionHeaderDetails.ContactPerson);
		HeaderAttributes.Insert("LoyaltyCard",                       SelectionHeaderDetails.LoyaltyCard);
		HeaderAttributes.Insert("UISStateContractStep",                	 SelectionHeaderDetails.UISStateContractStep);
		HeaderAttributes.Insert("FinancialAccountingGroup",                SelectionHeaderDetails.FinancialAccountingGroup);
		HeaderAttributes.Insert("CashAccount",                                 SelectionHeaderDetails.CashAccount);
		HeaderAttributes.Insert("ThisIsOrderAsInvoice",                       SelectionHeaderDetails.ThisIsOrderAsInvoice);
		
		GoodsDelivery.AddDeliveryDetailsToFillInDetails(HeaderAttributes,SelectionHeaderDetails);
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Creates a structure for creating and performing work on one or more customer orders
// If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray   - Array - orders to suppliers for which you need to enter an implementation.
//  HeaderAttributes - Structure - the structure where the header details from the order array will be placed.
//
// Returns:
//   Boolean - False if the details of the header differ in the transferred orders.
//
Function GenerateDataForFillingInReportsOfCompletedWorks(ReferencesArrray, HeaderAttributes) Export
	
	Query = New Query(
		"SELECT
		|	MIN(SalesOrder.Partner)                 AS Partner,
		|	MIN(SalesOrder.Counterparty)              AS Counterparty,
		|	MIN(SalesOrder.Contract)                 AS Contract,
		|	MIN(SalesOrder.Organization)             AS Organization,
		|	MIN(SalesOrder.Terms)              AS Terms,
		|	MIN(SalesOrder.SalesOpportunity)                  AS SalesOpportunity,
		|	MIN(SalesOrder.ARAPCurrency)    AS ARAPCurrency,
		|	MIN(SalesOrder.VATTaxation)      AS VATTaxation,
		|	MIN(SalesOrder.PriceIncludesVAT)         AS PriceIncludesVAT,
		|	MIN(SalesOrder.ARAPObjectSettings)         AS ARAPObjectSettings,
		|	MIN(SalesOrder.LineOfBusiness) AS LineOfBusiness,
		|	MIN(SalesOrder.FinancialAccountingGroup)  AS FinancialAccountingGroup,
		|	MIN(SalesOrder.UISStateContractStep)     AS UISStateContractStep,
		|	MIN(SalesOrder.LoyaltyCard)         AS LoyaltyCard,
		|	MIN(SalesOrder.ThisIsOrderAsInvoice)         AS ThisIsOrderAsInvoice,
		|	MIN(SalesOrder.PaymentSchedule)            AS PaymentSchedule,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT
		|				CASE
		|					WHEN
		|						SalesOrder.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|					THEN
		|						SalesOrder.Department
		|					ELSE
		|						NULL
		|				END) = 1
		|		THEN
		|			MAX(SalesOrder.Department)
		|		ELSE
		|			VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT
		|				CASE
		|					WHEN
		|						SalesOrder.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|					THEN
		|						SalesOrder.BankAccount
		|					ELSE
		|						NULL
		|				END) = 1 AND
		|			COUNT(DISTINCT SalesOrder.Organization) = 1
		|		THEN
		|			MAX(SalesOrder.BankAccount)
		|		ELSE
		|			VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|	END AS BankAccount,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT
		|				CASE
		|					WHEN
		|						SalesOrder.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|					THEN
		|						SalesOrder.CounterpartyBankAccount
		|					ELSE
		|						NULL
		|				END) = 1 AND
		|			COUNT(DISTINCT SalesOrder.Counterparty) = 1
		|		THEN
		|			MAX(SalesOrder.CounterpartyBankAccount)
		|		ELSE
		|			VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|	END AS CounterpartyBankAccount,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT
		|				CASE
		|					WHEN
		|						SalesOrder.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
		|					THEN
		|						SalesOrder.ContactPerson
		|					ELSE
		|						NULL
		|				END) = 1 AND
		|			COUNT(DISTINCT SalesOrder.ContactPerson) = 1
		|		THEN
		|			MAX(SalesOrder.ContactPerson)
		|		ELSE
		|			VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
		|	END AS ContactPerson,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.Partner) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesPartner,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.Counterparty) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesCounterparty,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.Contract) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesContract,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.Organization) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesCompany,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.Terms) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesAgreement,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.SalesOpportunity) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesSalesOpportunity,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.ARAPCurrency) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesInCurrencyOfMutualSettlements,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.VATTaxation) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesVATTaxation,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.PriceIncludesVAT) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesPriceIncludesVAT,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.ARAPObjectSettings) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesInOrderOfCalculations,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.LineOfBusiness) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesInDirectionOfActivity,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.FinancialAccountingGroup) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesInFinancialAccounting,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.UISStateContractStep) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesUISStateContractStep,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.LoyaltyCard) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesLoyaltyCard,
		|	CASE
		|		WHEN
		|			COUNT(DISTINCT SalesOrder.ThisIsOrderAsInvoice) > 1
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreDifferencesThisIsOrderAsInvoice
		|FROM
		|	(SELECT
		|		SalesOrder.Partner AS Partner,
		|		SalesOrder.Counterparty AS Counterparty,
		|		SalesOrder.Contract AS Contract,
		|		SalesOrder.Organization AS Organization,
		|		SalesOrder.Department AS Department,
		|		SalesOrder.Terms AS Terms,
		|		SalesOrder.SalesOpportunity AS SalesOpportunity,
		|		SalesOrder.Currency AS ARAPCurrency,
		|		SalesOrder.VATTaxation AS VATTaxation,
		|		SalesOrder.PriceIncludesVAT AS PriceIncludesVAT,
		|		SalesOrder.ARAPObjectSettings AS ARAPObjectSettings,
		|		SalesOrder.BankAccount,
		|		SalesOrder.CounterpartyBankAccount,
		|		SalesOrder.LoyaltyCard AS LoyaltyCard,
		|		SalesOrder.LineOfBusiness,
		|		SalesOrder.ContactPerson,
		|		SalesOrder.FinancialAccountingGroup,
		|		SalesOrder.ThisIsOrderAsInvoice,
		|		SalesOrder.UISStateContractStep,
		|		SalesOrder.PaymentSchedule AS PaymentSchedule
		|	FROM
		|		Document.SalesOrder AS SalesOrder
		|	WHERE
		|		SalesOrder.Ref IN(&ReferencesArrray)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReturnRequest.Partner,
		|		ReturnRequest.Counterparty,
		|		ReturnRequest.Contract,
		|		ReturnRequest.Organization,
		|		ReturnRequest.Department,
		|		ReturnRequest.Terms,
		|		ReturnRequest.SalesOpportunity,
		|		ReturnRequest.Currency,
		|		ReturnRequest.VATTaxation,
		|		ReturnRequest.PriceIncludesVAT,
		|		ReturnRequest.ARAPObjectSettings,
		|		ReturnRequest.BankAccount,
		|		ReturnRequest.CounterpartyBankAccount,
		|		ReturnRequest.LoyaltyCard,
		|		ReturnRequest.LineOfBusiness,
		|		ReturnRequest.ContactPerson,
		|		ReturnRequest.FinancialAccountingGroup,
		|		ReturnRequest.ThisIsOrderAsInvoice,
		|		"""",
		|		ReturnRequest.PaymentSchedule
		|	FROM
		|		Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
		|	WHERE
		|		ReturnRequest.Ref IN(&ReferencesArrray)) AS SalesOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SalesOrder.Ref AS SalesOrder,
		|	SalesOrder.Status AS Status,
		|	CASE
		|		WHEN SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsEconomicOperation,
		|	(NOT SalesOrder.Posted) AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN SalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|				OR SalesOrder.Status = VALUE(Enum.SalesOrderStatuses.Closed)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	TRUE AS OrderOrder,
		|	SalesOrder.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
		|	SalesOrder.BusinessOperation AS BusinessOperation
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref IN(&ReferencesArrray)
		|	AND ((NOT SalesOrder.Posted)
		|			OR (NOT SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer))
		|			OR SalesOrder.Status <> VALUE(Enum.SalesOrderStatuses.ToShip)
		|				AND SalesOrder.Status <> VALUE(Enum.SalesOrderStatuses.Closed))
		|
		|UNION ALL
		|
		|SELECT
		|	ReturnRequest.Ref,
		|	ReturnRequest.Status,
		|	CASE
		|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|				OR ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
		|			THEN FALSE
		|		ELSE TRUE
		|	END,
		|	(NOT ReturnRequest.Posted),
		|	CASE
		|		WHEN ReturnRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|				OR ReturnRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed)
		|			THEN FALSE
		|		ELSE TRUE
		|	END,
		|	FALSE,
		|	ReturnRequest.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
		|	ReturnRequest.BusinessOperation
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
		|WHERE
		|	ReturnRequest.Ref IN(&ReferencesArrray)
		|	AND ((NOT ReturnRequest.Posted)
		|			OR (NOT(ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|					OR ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)))
		|			OR ReturnRequest.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|				AND ReturnRequest.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	QueryResult = Query.ExecuteBatch();
	SelectionHeaderDetails = QueryResult[0].Select();
	SelectionHeaderDetails.Next();
	
	Cancel = False;
	
	MessageText = NStr("vi = 'Trong các lệnh đã chọn có khác biệt tại trường ""%FieldPresentation%""';
						|ru = 'У выделенных распоряжений отличается поле ""%FieldPresentation%""';
						|en = 'The ""%FieldPresentation%"" field of the selected references differs.'; fa = 'The ""%FieldPresentation%"" field of the selected references differs.';
						|it = 'Nei riferimenti evidenziati il campo ""%FieldPresentation%"" differisce';
						|pl = 'W zaznaczonych zamówieniach różni się pole ""%FieldPresentation%""';
						|tr = 'Seçilen siparişler farklı bir alana sahip ""%FieldPresentation%""'");
	
	If SelectionHeaderDetails.ThereAreDifferencesPartner Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Bạn hàng';
																|ru = 'Партнер';
																|en = 'Partner'; fa = 'شریک تجاری';
																|it = 'Partner';
																|pl = 'Partner';
																|tr = 'İş ortağı'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCounterparty Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Controparte';
																|pl = 'Kontrahent';
																|tr = 'Cari hesap'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesCompany Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Doanh nghiệp';
																|ru = 'Организация';
																|en = 'Company'; fa = 'Company';
																|it = 'Azienda';
																|pl = 'Firma';
																|tr = 'İş yeri'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesAgreement Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thỏa thuận';
																|ru = 'Соглашение';
																|en = 'Agreement'; fa = 'توافق‌نامه';
																|it = 'Accordo';
																|pl = 'Porozumienie';
																|tr = 'Anlaşma'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesContract Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Hợp đồng';
																|ru = 'Договор';
																|en = 'Contract'; fa = 'قرارداد';
																|it = 'Contratto';
																|pl = 'Contract';
																|tr = 'Sözleşme'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesSalesOpportunity Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Vụ việc';
																|ru = 'Сделка';
																|en = 'Sales opportunity'; fa = 'فرصت فروش';
																|it = 'Transazione';
																|pl = 'Umowa';
																|tr = 'Satış fırsatı'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInCurrencyOfMutualSettlements Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Tiền tệ hạch toán công nợ';
																|ru = 'Валюта взаиморасчетов';
																|en = 'AR/AP currency'; fa = 'ارز دریافتنی/پرداختنی';
																|it = 'Valuta di regolamento dei conti';
																|pl = 'Waluta rozliczeń wzajemnych';
																|tr = 'Alacak/Borç muhasebesi para birimi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesVATTaxation Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Chịu thuế GTGT';
																|ru = 'Налогообложение НДС';
																|en = 'VAT taxation'; fa = 'مشمولیت مالیات بر ارزش افزوده';
																|it = 'Tassazione IVA';
																|pl = 'Opodatkowanie VAT';
																|tr = 'KDV vergilendirilmesi'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesPriceIncludesVAT Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giá gồm thuế GTGT';
																|ru = 'Цена включает НДС';
																|en = 'Price includes VAT'; fa = 'قیمت شامل مالیات بر ارزش افزوده است';
																|it = 'Il prezzo include l''IVA';
																|pl = 'Cena zawiera VAT';
																|tr = 'Fiyata KDV dahildir'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInOrderOfCalculations Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Quy trình thanh toán';
																|ru = 'Порядок расчетов';
																|en = 'Payment terms'; fa = 'شرایط پرداخت';
																|it = 'Modalità di regolamenti';
																|pl = 'Sposób rozliczeń';
																|tr = 'Ödeme şartları'")),
			,
			,
			,
			Cancel);
		
		EndIf;
		
	If SelectionHeaderDetails.ThereAreDifferencesInDirectionOfActivity Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Lĩnh vực hoạt động';
																|ru = 'Направление деятельности';
																|en = 'Line of business'; fa = 'خط کسب‌وکار';
																|it = 'Settore di attività';
																|pl = 'Rodzaj działalności';
																|tr = 'İş kolu'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesInFinancialAccounting Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Nhóm kế toán tài chính';
																|ru = 'Группа финансового учета';
																|en = 'Financial accounting group'; fa = 'گروه حسابداری مالی';
																|it = 'Gruppo di contabilità finanziaria';
																|pl = 'Grupa ewidencji finansowej';
																|tr = 'Finansal muhasebe grubu'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesLoyaltyCard Then
		
		CommonClientServer.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Thẻ khách hàng thân thiết';
																|ru = 'Карта лояльности';
																|en = 'Loyalty card'; fa = 'کارت وفاداری';
																|it = 'Carta fedeltà';
																|pl = 'Karta lojalnościowa';
																|tr = 'Sadakat kartı'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesUISStateContractStep Then
		
		Common.MessageToUser(
			StrReplace(MessageText, "%FieldPresentation%", NStr("vi = 'Giai đoạn trong hợp đồng với chính phủ';
																|ru = 'Этап государственного контракта';
																|en = 'State contract step'; fa = 'State contract step';
																|it = 'Fase della commessa statale';
																|pl = 'Etap kontraktu państwowego';
																|tr = 'Devlet sözleşmesi aşaması'")),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesThisIsOrderAsInvoice Then
		
		Common.MessageToUser(
			NStr("vi = 'Đã tạo các chênh lệch được tách chọn nếu trong các tùy chỉnh hệ thống khác nhau sử dụng đơn hàng.';
				|ru = 'Выделенные распоряжения были созданы при разных системных настройках использования заказов.';
				|en = 'The selected references were created using different system order settings.'; fa = 'The selected references were created using different system order settings.';
				|it = 'Выделенные распоряжения были созданы при разных системных настройках использования заказов.';
				|pl = 'The selected references were created using different system order settings.';
				|tr = 'Seçilen siparişler, kullanım siparişleri için farklı sistem ayarları altında oluşturuldu.'"),
			,
			,
			,
			Cancel);
		
	EndIf;
	
	If SelectionHeaderDetails.ThereAreDifferencesPartner 
		Or SelectionHeaderDetails.ThereAreDifferencesCounterparty 
		Or SelectionHeaderDetails.ThereAreDifferencesCompany 
		Or SelectionHeaderDetails.ThereAreDifferencesAgreement 
		Or SelectionHeaderDetails.ThereAreDifferencesContract 
		Or SelectionHeaderDetails.ThereAreDifferencesSalesOpportunity 
		Or SelectionHeaderDetails.ThereAreDifferencesInCurrencyOfMutualSettlements 
		Or SelectionHeaderDetails.ThereAreDifferencesVATTaxation 
		Or SelectionHeaderDetails.ThereAreDifferencesPriceIncludesVAT 
		Or SelectionHeaderDetails.ThereAreDifferencesInOrderOfCalculations 
		Or SelectionHeaderDetails.ThereAreDifferencesInDirectionOfActivity 
		Or SelectionHeaderDetails.ThereAreDifferencesInFinancialAccounting 
		Or SelectionHeaderDetails.ThereAreDifferencesUISStateContractStep 
		Or SelectionHeaderDetails.ThereAreDifferencesThisIsOrderAsInvoice 
		Or SelectionHeaderDetails.ThereAreDifferencesLoyaltyCard Then
		
		ErrorText = NStr("vi = 'Không thể nhập một biên bản bàn giao dịch vụ trên cơ sở lệnh đã chọn';
						|ru = 'Ввод одного акта выполненных работ на основании выделенных распоряжений невозможен';
						|en = 'Cannot register one ""Customer invoice — Services"" based on the selected references'; fa = 'Cannot register one ""Customer invoice — Services"" based on the selected references';
						|it = 'L''immissione di una nota di accettazione in base alle disposizioni stabilite non è possibile';
						|pl = 'Wpis jednego zestawienia wykonanych prac na podstawie przydzielonych zamówień jest niemożliwy';
						|tr = 'Seçilen siparişler bazında gerçekleştirilen işlerin tutanak raporu girilemez'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,
			Cancel);
		
	Else
		
		If Not QueryResult[1].IsEmpty() > 0 Then
			
			SampleOrders = QueryResult[1].Select();
			
			While SampleOrders.Next() Do
				
				If SampleOrders.OrderOrder Then
					Documents.SalesOrder.CheckPossibilityOfEnteringBasedOn(
						SampleOrders.SalesOrder,
						SampleOrders.Status,
						SampleOrders.ThereAreErrorsPosted);
				Else
					Documents.RequestForReturnOfGoodsFromCustomer.CheckPossibilityOfEnteringBasedOn(
						SampleOrders.SalesOrder,
						SampleOrders.Status,
						SampleOrders.ThereAreErrorsPosted);
				EndIf;
				
				If SampleOrders.ThereAreErrorsPosted Then
					
					ErrorText = NStr("vi = 'Chứng từ %Document% chưa kết chuyển. Lập trên cơ sở bị cấm.';
									|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
									|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
									|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
									|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
									|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belgeye dayalı giriş yasaktır.'");
					ErrorText = StrReplace(ErrorText, "%Document%", SampleOrders.SalesOrder);
					
					CommonClientServer.MessageToUser(
						ErrorText,
						,
						,
						,
						Cancel);
					
				ElsIf SampleOrders.ThereAreErrorsEconomicOperation Then
					
					ErrorText = NStr("vi = 'Không thể nhập trên cơ sở chứng từ có giao dịch kinh tế %BusinessOperation%.';
									|ru = 'Ввод на основании документа с хозяйственной операцией %BusinessOperation% невозможен.';
									|en = 'Generation from a base document with business transaction %BusinessOperation% is not allowed.'; fa = 'Generation from a base document with business transaction %BusinessOperation% is not allowed.';
									|it = 'Inserimento in base al documento con operazione commerciale %BusinessOperation% non è possibile.';
									|pl = 'Wprowadzenie na podstawie dokumentu z operacją gospodarczą %BusinessOperation%nie jest możliwe.';
									|tr = 'Ticari işlem ile temel belgenin girişi %BusinessOperation% imkansız'");
					ErrorText = StrReplace(ErrorText, "%BusinessOperation%", SampleOrders.BusinessOperation);
					
					CommonClientServer.MessageToUser(
						ErrorText,
						,
						,
						,
						Cancel);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		HeaderAttributes.Insert("Partner",                        SelectionHeaderDetails.Partner);
		HeaderAttributes.Insert("Counterparty",                     SelectionHeaderDetails.Counterparty);
		HeaderAttributes.Insert("Contract",                        SelectionHeaderDetails.Contract);
		HeaderAttributes.Insert("Organization",                    SelectionHeaderDetails.Organization);
		HeaderAttributes.Insert("Department",                  SelectionHeaderDetails.Department);
		HeaderAttributes.Insert("Terms",                     SelectionHeaderDetails.Terms);
		HeaderAttributes.Insert("ARAPCurrency",           SelectionHeaderDetails.ARAPCurrency);
		HeaderAttributes.Insert("VATTaxation",             SelectionHeaderDetails.VATTaxation);
		HeaderAttributes.Insert("PriceIncludesVAT",                SelectionHeaderDetails.PriceIncludesVAT);
		HeaderAttributes.Insert("ARAPObjectSettings",                SelectionHeaderDetails.ARAPObjectSettings);
		HeaderAttributes.Insert("SalesOpportunity",                         SelectionHeaderDetails.SalesOpportunity);
		HeaderAttributes.Insert("CounterpartyBankAccount",      SelectionHeaderDetails.CounterpartyBankAccount);
		HeaderAttributes.Insert("BankAccount",                 SelectionHeaderDetails.BankAccount);
		HeaderAttributes.Insert("ContactPerson",                 SelectionHeaderDetails.ContactPerson);
		HeaderAttributes.Insert("LineOfBusiness",        SelectionHeaderDetails.LineOfBusiness);
		HeaderAttributes.Insert("FinancialAccountingGroup",         SelectionHeaderDetails.FinancialAccountingGroup);
		HeaderAttributes.Insert("UISStateContractStep",            SelectionHeaderDetails.UISStateContractStep);
		HeaderAttributes.Insert("LoyaltyCard",                SelectionHeaderDetails.LoyaltyCard);
		HeaderAttributes.Insert("ThisIsOrderAsInvoice",                SelectionHeaderDetails.ThisIsOrderAsInvoice);
		HeaderAttributes.Insert("PaymentSchedule",                   SelectionHeaderDetails.PaymentSchedule);
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction


// Re-fills in the order invoice form data
//
// Parameters:
// 		FormData1 - FormDataStructure - refillable invoice.
//
// Returns:
// 		Boolean - "True" if the invoice is overfilled.
//
Function ReFillInvoiceForOrders(FormData1) Export
	
	FillingStructure = SalesServer.ReFillInvoiceForOrders(FormData1);
	Return FillingStructure;
	
EndFunction

// Gets the basis for the invoice for payment
//
// Parameters:
//  DocumentBasis	 - DocumentRef - The invoice Foundation document.
// 
// Returns:
//  DocumentRef, CatalogRef.CounterpartyContracts  - Footing.
//
Function GetBasisForPaymentInvoice(DocumentBasis) Export
	
	ARAPObjectSettings = Common.ObjectAttributeValue(DocumentBasis, "ARAPObjectSettings");
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
		Basis =Common.ObjectAttributeValue(DocumentBasis, "Contract");
	Else
		Basis = DocumentBasis;
	EndIf;
	
	Return Basis
	
EndFunction

// Creates the structure of the list of documents for setting the status
//
// Parameters:
//  ArrayOfImplementations - Array - array of documents.
// 
// Returns:
//  Structure - the structure of the returned parameters.
//
Function CreateStructureOfDocumentList(ArrayOfImplementations) Export
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("HighlightedLinesContainShipment", False);
	ReturnStructure.Insert("TheHighlightedLinesContainMoreThanJustTheShipment", False);
	
	If Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
		Return ReturnStructure;
	EndIf;
	
	ValuesOfBusinessTransactions = Common.ObjectsAttributeValue(ArrayOfImplementations, "BusinessOperation");
	
	For Each CurRow In ArrayOfImplementations Do
		
		If ValuesOfBusinessTransactions[CurRow] = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or ValuesOfBusinessTransactions[CurRow] = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
			Or ValuesOfBusinessTransactions[CurRow] = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
			ReturnStructure.Insert("HighlightedLinesContainShipment", True);
		ElsIf ValuesOfBusinessTransactions[CurRow] <> Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or ValuesOfBusinessTransactions[CurRow] = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
			ReturnStructure.Insert("TheHighlightedLinesContainMoreThanJustTheShipment", True);
		EndIf;
		
		If ReturnStructure.HighlightedLinesContainShipment
			 And ReturnStructure.TheHighlightedLinesContainMoreThanJustTheShipment Then
			 Break;
		 EndIf;
		 
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

#Region ProceduresAndFunctionsForSettingAgreementStatuses

// Sets the status to "Not approved" and selected in the list of agreements.
//
// Parameters:
//  Terms1 - Array - array of agreements with clients.
//
// Returns:
//   Number - The number of successfully processed agreements.
//
Function EstablishStatusOfAgreementsWithCustomersNotAgreed (Val Terms1) Export
	
	Return Catalogs.TermsOfSale.SetStatus(Terms1, Enums.StatusesOfTermsOfSales.NotApproved);

EndFunction

// Sets the "Valid" status for selected agreements in the list.
//
// Parameters:
//   Terms1 - Number - The number of successfully processed agreements.
//
// Returns:
//   Number - the number of agreements for which the status "Valid" is set.
//
Function SetStatusOfAgreementsWithClientsValid(Val Terms1) Export
	
	Return Catalogs.TermsOfSale.SetStatus(Terms1, Enums.StatusesOfTermsOfSales.Valid);

EndFunction

// Sets the "Closed" status for selected agreements in the list
//
// Parameters:
//  Terms1 - Array - array of agreements with clients.
//
// Returns:
//   Number - The number of successfully processed agreements.
//
Function SetStatusOfCustomerAgreementsClosed(Val Terms1) Export
	
	Return Catalogs.TermsOfSale.SetStatus(Terms1, Enums.StatusesOfTermsOfSales.Closed);

EndFunction

#EndRegion

// Fills in the selection data during auto-selection of Analytics based on the entered text.
//
// Parameters:
//  ChoiceData - ValueList - List of values to fill in.
//  Text - String - Text entered in the field.
//
Procedure FillInExpenseAnalyticsSelectionData(ChoiceData, Text) Export
	
	SalesServer.FillInExpenseAnalyticsSelectionData(ChoiceData, Text);
	
EndProcedure

#Region EnsuringDataSecurity

// Returns data from the current user's secure storage based on the passed keys
// 
// Parameters:
// 	Keys - See Common.ReadDataFromSecureStorage.Keys
// Returns:
// 	See SalesServer.ReadDataFromSecureStorage
//
Function ReadDataFromSecureStorage(Keys) Export
	
	Return SalesServer.ReadDataFromSecureStorage(Keys);
	
EndFunction

#EndRegion

#EndRegion

#Region ProcedureForCheckingContractInDocument

// Returns the result of partner verification in the created Contract and document.
//
//Parameters:
//	Contract - CatalogRef.CounterpartyContracts - a Contract has been CREATED.
//	SelectionData_ - Structure - the selection parameters depend on the document.
//	DocumentPartner - CatalogRef.Partners - The partner from the document.
//	ErrorMessage - String - generated error message.
//	 
//Returns:
//	Boolean - indicates that the check passed.
//
Function CheckSelectionAndPartnerData(Contract, SelectionData_, DocumentPartner, ErrorMessage = "") Export
	
	CheckPassed = True;
	
	ParametersArray = New Array();
	For Each FilterParameter In SelectionData_ Do
		ParametersArray.Add(FilterParameter.Key);
	EndDo;
	
	If ParametersArray.Find("Partner") = Undefined Then
		ParametersArray.Add("Partner");
	EndIf;
	If ParametersArray.Find("ItIsAllowedToWorkWithSubsidiaryPartners") = Undefined Then
		ParametersArray.Add("ItIsAllowedToWorkWithSubsidiaryPartners");
	EndIf;
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, ParametersArray);
	For Each FilterParameter In SelectionData_ Do
		If TypeOf(FilterParameter.Value) = Type("FixedArray") Then
			If FilterParameter.Value.Find(ContractDetails_[FilterParameter.Key]) = Undefined Then
				CheckPassed = False;
				Break;
			EndIf;
		ElsIf ContractDetails_[FilterParameter.Key] <> FilterParameter.Value Then
			CheckPassed = False;
			Break;
		EndIf;
	EndDo;
	
	If CheckPassed Then
		
		AgreementPartner = ContractDetails_.Partner;
		
		If ContractDetails_.ItIsAllowedToWorkWithSubsidiaryPartners Then
			
			PartnerList = New ValueList;
			PartnersAndCounterparties.FillInListOfPartnersWithParents(DocumentPartner, PartnerList);
			
			ArrayOfPartners = PartnerList.UnloadValues();
			If ArrayOfPartners.Find(AgreementPartner) = Undefined Then
				CheckPassed = False;
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối tác được chỉ ra trong hợp đồng ""%1"" cần là ""%2"" hoặc đối tác mẹ';
						|ru = 'Указанный партнер в договоре ""%1"" должен быть ""%2"" или головной партнер';
						|en = 'The partner specified in the ""%1"" contract must be ""%2"" or the main partner'; fa = 'The partner specified in the ""%1"" contract must be ""%2"" or the main partner';
						|it = 'Указанный партнер в договоре ""%1"" должен быть ""%2"" или головной партнер';
						|pl = 'The partner specified in the ""%1"" contract must be ""%2"" or the main partner';
						|tr = '""%1"" sözleşmesinde belirtilen ortak, ""%2"" veya baş ortak olmalıdır'"),
					Contract, DocumentPartner);
			EndIf;
			
		ElsIf AgreementPartner <> DocumentPartner Then
			CheckPassed = False;
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối tác được chỉ ra trong hợp đồng ""%1"" cần là ""%2""';
					|ru = 'Указанный партнер в договоре ""%1"" должен быть ""%2""';
					|en = 'The partner specified in the ""%1"" contract must be ""%2""'; fa = 'The partner specified in the ""%1"" contract must be ""%2""';
					|it = 'Указанный партнер в договоре ""%1"" должен быть ""%2""';
					|pl = 'The partner specified in the ""%1"" contract must be ""%2""';
					|tr = '""%1"" sözleşmesinde belirtilen ortak, ""%2"" olmalıdır'"),
				Contract, DocumentPartner);
		EndIf;
		
	Else
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" không tương ứng với điều kiện lựa chọn';
				|ru = '""%1"" не соответствует условиям выбора';
				|en = '""%1"" does not meet the selection criteria'; fa = '""%1"" does not meet the selection criteria';
				|it = '""%1"" не соответствует условиям выбора';
				|pl = '""%1"" does not meet the selection criteria';
				|tr = '""%1"" seçim koşullarıyla eşleşmiyor'"),
			Contract);
	EndIf;
		
	Return CheckPassed;
	
EndFunction

#EndRegion

// This is an agreement on a new commission.
// 
// Parameters:
//  Terms - CatalogRef.TermsOfSale
// 
// Returns:
//  Boolean - This Is The Agreement On The New Commission
Function ThisIsAgreementOnNewCommission(Terms) Export
	
	Return SalesServer.ThisIsAgreementOnNewCommission(Terms);
	
EndFunction

#Region Private

#Region Internal

#Region FormationOfSetOfDocuments

// Forms the structure of document tables based on the transmitted orders and parameters
// 
// Parameters:
// 		ComplianceWithOrders - See SalesClient.InitializeOrders
// 		GenerationParameters - See SalesServer.NewParametersForDesignOfSetOfDocuments
// 	
// Returns:
// 		See SalesServer.IssueInvoiceOnServer
// 
Function IssueInvoiceOnServer(ComplianceWithOrders, GenerationParameters) Export
	
	Return SalesServer.IssueInvoiceOnServer(ComplianceWithOrders, GenerationParameters);
	
EndFunction

// Starts a background task for generating documents based on the passed structure
// 
// Parameters:
// 	ParametersStructure - See SalesServer.IssueNumberOfInvoicesAccordingToTablesCall.ParametersStructure
// 	GenerationParameters - See SalesServer.NewParametersForDesignOfSetOfDocuments
// 	CurPackageNumber - See SalesServer.IssueNumberOfInvoicesAccordingToTablesCall.CurPackageNumber
// 	
// Returns:
// 	See SalesServer.IssueNumberOfInvoicesAccordingToTablesCall
//
Function IssueNumberOfInvoicesAccordingToTablesCall(ParametersStructure, GenerationParameters, CurPackageNumber = Undefined) Export
	
	Return SalesServer.IssueNumberOfInvoicesAccordingToTablesCall(ParametersStructure, GenerationParameters, CurPackageNumber);
	
EndFunction

// Returns a table of connected equipment in the context of cash registers and organizations
//
// Parameters:
// 	CreatedDocuments - See SalesServer.GetConnectedHardware.CreatedDocuments
// 	EquipmentTable - See SalesServer.GetConnectedHardware.EquipmentTable 
//
Procedure GetConnectedHardware(CreatedDocuments, EquipmentTable) Export
	
	SalesServer.GetConnectedHardware(CreatedDocuments, EquipmentTable);
	
EndProcedure

// Calls the constructor function for parameters for generating a set of documents
//
// Returns:
// 	See SalesServer.NewParametersForDesignOfSetOfDocuments
//
Function NewParametersForDesignOfSetOfDocuments() Export
	
	Return SalesServer.NewParametersForDesignOfSetOfDocuments();
	
EndFunction

// Complements the data structure according to orders and the transmitted formation parameters.
// 
// Parameters:
// 		ComplianceWithOrders - See SalesClient.InitializeOrders
// 		GenerationParameters - See SalesServer.NewParametersForDesignOfSetOfDocuments
// 	
Procedure ToSupplementStructureOfOrdersAndFormationParameters(ComplianceWithOrders, GenerationParameters) Export
	
	SalesServer.ToSupplementStructureOfOrdersAndFormationParameters(ComplianceWithOrders, GenerationParameters);
	
EndProcedure

// According to the transmitted orders and parameters, it forms the structure of shipment document tables
// 
// Parameters:
// 		ComplianceWithOrders - See SalesClient.InitializeOrders
// 		GenerationParameters - See SalesServer.NewParametersForDesignOfSetOfDocuments
// 	
// 	
// Returns:
// 		See SalesServer.ArrangeShipmentATServer
// 
Function ArrangeShipmentATServer(ComplianceWithOrders, GenerationParameters) Export
	
	Return SalesServer.ArrangeShipmentATServer(ComplianceWithOrders, GenerationParameters);
	
EndFunction

#EndRegion

#Region SettingUpSetOfDocuments

// Retrieves parameters for generating a set of documents from the current user's settings store
// 
// Parameters:
// 	ObjectKey - String - the key of the received settings
//
// Returns:
// 	See SalesServer.GetASetOfDocumentsSetup
//
Function GetASetOfDocumentsSetup(ObjectKey) Export
	
	Return SalesServer.GetASetOfDocumentsSetup(ObjectKey);
	
EndFunction

// Saves parameters for creating a set of documents in the current user's settings storage
// 
// Parameters:
// 	Settings - See SalesServer.SaveDocumentSetSettings.Settings
// 	ObjectKey - String - key of saved settings
//
Procedure SaveDocumentSetSettings(Settings, ObjectKey) Export
	
	SalesServer.SaveDocumentSetSettings(Settings, ObjectKey);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion
