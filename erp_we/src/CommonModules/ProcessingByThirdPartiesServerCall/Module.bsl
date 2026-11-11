///////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Processing on the side"
// 
///////////////////////////////////////////////////////////
//

#Region Public

#Region GenerateFrom

// Returns the parameters for opening the Document form.Transfer of goods to the consumer when entering on the basis of
//
// Parameters:
//  CommandParameter - Structure
// Returns:
//  Structure - Contains:
//   * Basis - Structure - 
//
Function TransferOfGoodsToCustodianFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("OriginWarehouse", Undefined);
	
	If Common.IsReference(TypeOf(CommandParameter)) Then
		
		If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() > 0 Then
			DocumentBasis = CommandParameter[0];
		Else
			DocumentBasis = CommandParameter;
		EndIf;
		
		If TMCommonUse.CheckOrderOperation(
				DocumentBasis,
				"TransferOfGoodsToBailee",
				Enums.BusinessTransactions.TransferToToller2_5) Then
			BasisParameters.Insert("DocumentBasis", DocumentBasis);
		Else
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("DocumentBasis", DocumentBasis);
		
	Else
		
		HeaderAttributes = New Structure;
		DocumentName   = "TransferOfGoodsToBailee";
		
		If Not GenerateDataForTransferOfRawMaterials(CommandParameter, DocumentName, HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("HeaderAttributes",    HeaderAttributes);
		BasisParameters.Insert("DocumentBasis", CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

// Forms a structure for creating the transfer of raw materials for one or more orders to processors.
// If the details of the header differ in the transferred orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray     - Array of DocumentRef.SubcontractOrder2_5, DocumentRef.SubcontractOrder2_5 - orders to the processor
//                                                                 for which it is necessary to enter the transfer of raw materials.
//  DocumentName    - String - name of the document that is being created based on orders.
//  HeaderAttributes  - Structure - the structure where the header details from the order array will be placed.
//  OrderProperties_ - Structure, Undefined - 
//
// Returns:
//   Boolean - False if the details of the header differ in the transferred orders.
//
Function GenerateDataForTransferOfRawMaterials(ReferencesArrray, DocumentName, HeaderAttributes, OrderProperties_ = Undefined) Export
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&ReferencesArrray)
		|		AND (NOT &FilterByWarehouse
		|			OR Warehouse IN (&Warehouse))";
	TableFormationParameters.Group = "ReferenceOrder, Warehouse";
	TableFormationParameters.Indicators = "Ordered, ToRegister, Issued_1, ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = "ReferenceOrder";
	TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
	
	TT_ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = TT_ShipmentOrdersTurnoverExpanded
		+ Common.QueryBatchSeparator()
		+ "SELECT
		|	OrderDocument.Ref AS SalesOrder,
		|	OrderDocument.Partner AS Partner,
		|	OrderDocument.Counterparty AS Counterparty,
		|	OrderDocument.Contract AS Contract,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.SalesOpportunity AS SalesOpportunity,
		|	CASE
		|		WHEN OrderDocument.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
		|			THEN ISNULL(OrderBalances.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
		|		WHEN TRUE
		|			THEN OrderDocument.MaterialsWarehouse
		|	END AS Warehouse,
		|	ISNULL(OrderBalances.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS OriginWarehouse,
		|	OrderDocument.Department AS Department,
		|	OrderDocument.Currency AS ARAPCurrency,
		|	OrderDocument.PurchaseForActivity AS VATTaxation,
		|	OrderDocument.PriceIncludesVAT AS PriceIncludesVAT,
		|	OrderDocument.ARAPObjectSettings AS ARAPObjectSettings,
		|	OrderDocument.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	OrderDocument.PaymentMethod AS PaymentMethod,
		|	OrderDocument.PaymentSchedule AS PaymentSchedule,
		|	OrderDocument.BankAccount AS BankAccount,
		|	OrderDocument.CashAccount AS CashAccount,
		|	VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) AS CounterpartyBankAccount,
		|	VALUE(Catalog.Counterparties.EmptyRef) AS Shipper,
		|	VALUE(Catalog.Counterparties.EmptyRef) AS GoodsRecipient,
		|	VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) AS ShipperBankAccount,
		|	VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) AS GoodsRecipientBankAccount,
		|	OrderDocument.DeliveryMethod AS DeliveryMethod,
		|	OrderDocument.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) AS MethodOfDeliveryByCarrier,
		|	OrderDocument.CarrierPartner AS CarrierPartner,
		|	OrderDocument.DeliveryAddress AS DeliveryAddress,
		|	OrderDocument.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
		|	OrderDocument.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
		|	OrderDocument.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	OrderDocument.DeliveryZone AS DeliveryZone,
		|	OrderDocument.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	OrderDocument.DeliveryTimeTo AS DeliveryTimeTo,
		|	OrderDocument.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
		|	OrderDocument.LineOfBusiness AS LineOfBusiness,
		|	OrderDocument.ContactPerson AS ContactPerson,
		|	VALUE(Catalog.LoyaltyCards.EmptyRef) AS LoyaltyCard,
		|	FALSE AS ThereIsInvalidOperation
		|INTO TTOrders
		|FROM
		|	Document.SubcontractOrder2_5 AS OrderDocument
		|		LEFT JOIN TT_ShipmentOrdersTurnoverExpanded AS OrderBalances
		|		ON OrderDocument.Ref = OrderBalances.ReferenceOrder
		|WHERE
		|	OrderDocument.Ref IN (&ReferencesArrray)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Orders.SalesOrder AS SalesOrder,
		|	&BusinessOperation AS BusinessOperation
		|FROM
		|	TTOrders AS Orders
		|WHERE
		|	Orders.ThereIsInvalidOperation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(Orders.Organization) AS Organization,
		|	MIN(Orders.Partner) AS Partner,
		|	MIN(Orders.Counterparty) AS Counterparty,
		|	MIN(Orders.Contract) AS Contract,
		|	CASE
		|		WHEN COUNT(DISTINCT Orders.Department) > 1
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		ELSE MIN(Orders.Department)
		|	END AS Department,
		|	MIN(Orders.Warehouse) AS Warehouse,
		|	MIN(Orders.OriginWarehouse) AS OriginWarehouse,
		|	MIN(Orders.LoyaltyCard) AS LoyaltyCard,
		|	MIN(Orders.SalesOpportunity) AS SalesOpportunity,
		|	&BusinessOperation AS BusinessOperation,
		|	MIN(Orders.ARAPCurrency) AS ARAPCurrency,
		|	MIN(Orders.VATTaxation) AS VATTaxation,
		|	MIN(Orders.PriceIncludesVAT) AS PriceIncludesVAT,
		|	MIN(Orders.ARAPObjectSettings) AS ARAPObjectSettings,
		|	MIN(Orders.ForeignCurrencyTransaction) AS ForeignCurrencyTransaction,
		|	MIN(Orders.PaymentSchedule) AS PaymentSchedule,
		|	MIN(Orders.LineOfBusiness) AS LineOfBusiness,
		|	CASE
		|		WHEN COUNT(DISTINCT Orders.PaymentMethod) > 1
		|			THEN VALUE(Enum.PaymentForms.EmptyRef)
		|		ELSE MIN(Orders.PaymentMethod)
		|	END AS PaymentMethod,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
		|				THEN Orders.ContactPerson
		|			ELSE NULL
		|		END) = 1
		|		AND COUNT(DISTINCT Orders.ContactPerson) = 1
		|			THEN MAX(Orders.ContactPerson)
		|		ELSE VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
		|	END AS ContactPerson,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|				THEN Orders.BankAccount
		|			ELSE NULL
		|		END) = 1
		|		AND COUNT(DISTINCT Orders.Organization) = 1
		|			THEN MAX(Orders.BankAccount)
		|		ELSE VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|	END AS BankAccount,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
		|				THEN Orders.CashAccount
		|			ELSE NULL
		|		END) = 1
		|		AND COUNT(DISTINCT Orders.Organization) = 1
		|			THEN MAX(Orders.CashAccount)
		|		ELSE VALUE(Catalog.CashAccounts.EmptyRef)
		|	END AS CashAccount,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.CounterpartyBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|				THEN Orders.CounterpartyBankAccount
		|			ELSE NULL
		|		END) = 1
		|		AND COUNT(DISTINCT Orders.Counterparty) = 1
		|			THEN MAX(Orders.CounterpartyBankAccount)
		|		ELSE VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|	END AS CounterpartyBankAccount,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
		|				THEN Orders.Shipper
		|			ELSE NULL
		|		END) = 1
		|			THEN MAX(Orders.Shipper)
		|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
		|	END AS Shipper,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.GoodsRecipient <> VALUE(Catalog.Counterparties.EmptyRef)
		|				THEN Orders.GoodsRecipient
		|			ELSE NULL
		|		END) = 1
		|			THEN MAX(Orders.GoodsRecipient)
		|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
		|	END AS GoodsRecipient,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.ShipperBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|				THEN Orders.ShipperBankAccount
		|			ELSE NULL
		|		END) = 1
		|		AND COUNT(DISTINCT CASE
		|			WHEN Orders.Shipper <> VALUE(Catalog.Counterparties.EmptyRef)
		|				THEN Orders.Shipper
		|			ELSE NULL
		|		END) = 1
		|			THEN MAX(Orders.ShipperBankAccount)
		|		ELSE VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|	END AS ShipperBankAccount,
		|	CASE
		|		WHEN COUNT(DISTINCT CASE
		|			WHEN Orders.GoodsRecipientBankAccount <> VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|				THEN Orders.GoodsRecipientBankAccount
		|			ELSE NULL
		|		END) = 1
		|		AND COUNT(DISTINCT CASE
		|			WHEN Orders.GoodsRecipient <> VALUE(Catalog.Counterparties.EmptyRef)
		|				THEN Orders.GoodsRecipient
		|			ELSE NULL
		|		END) = 1
		|			THEN MAX(Orders.GoodsRecipientBankAccount)
		|		ELSE VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
		|	END AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN MIN(Orders.Warehouse.IsFolder) = TRUE
		|		AND MIN(Orders.Warehouse.SelectGroup) = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItIsForbiddenToSelectWarehouseGroup,
		|	CASE
		|		WHEN COUNT(DISTINCT Orders.DeliveryMethod) = 1
		|			THEN MIN(Orders.DeliveryMethod)
		|		ELSE VALUE(Enum.TransportMethods.SelfPickup)
		|	END AS DeliveryMethod,
		|	CASE
		|		WHEN MIN(Orders.DeliveryMethod) = VALUE(Enum.TransportMethods.ByCarrier)
		|		AND COUNT(DISTINCT Orders.CarrierPartner) = 1
		|			THEN MIN(Orders.CarrierPartner)
		|		ELSE VALUE(Catalog.Partners.EmptyRef)
		|	END AS CarrierPartner,
		|	CASE
		|		WHEN COUNT(DISTINCT Orders.DeliveryAddress) = 1
		|			THEN MIN(Orders.DeliveryAddress)
		|		ELSE """"
		|	END AS DeliveryAddress,
		|	CASE
		|		WHEN COUNT(DISTINCT Orders.DeliveryAddress) = 1
		|			THEN MIN(CAST(Orders.DeliveryAddressFieldValues AS STRING(10))) = """"
		|		ELSE TRUE
		|	END AS DeliveryAddressFieldValuesEmpty,
		|	CASE
		|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
		|		AND MIN(Orders.DeliveryMethod) = VALUE(Enum.TransportMethods.ByCarrier)
		|		AND COUNT(DISTINCT CAST(Orders.AdditionalDeliveryInformation AS STRING(10))) = 1
		|			THEN MIN(CAST(Orders.AdditionalDeliveryInformation AS STRING(10))) = """"
		|		ELSE TRUE
		|	END AS AdditionalInformationOnDeliveryOfEmpty,
		|	UNDEFINED AS DeliveryAddressOfCarrier,
		|	UNDEFINED AS DeliveryAddressOfCarrierFieldValues,
		|	UNDEFINED AS DeliveryZone,
		|	UNDEFINED AS DeliveryTimeFrom,
		|	UNDEFINED AS DeliveryTimeTo,
		|	COUNT(DISTINCT Orders.Organization) > 1 AS ThereAreDifferencesCompany,
		|	COUNT(DISTINCT Orders.Partner) > 1 AS ThereAreDifferencesPartner,
		|	COUNT(DISTINCT Orders.Counterparty) > 1 AS ThereAreDifferencesCounterparty,
		|	COUNT(DISTINCT Orders.Contract) > 1 AS ThereAreDifferencesContract,
		|	COUNT(DISTINCT Orders.SalesOpportunity) > 1 AS ThereAreDifferencesSalesOpportunity,
		|	COUNT(DISTINCT Orders.Warehouse) > 1 AS ThereAreDifferencesWarehouse,
		|	FALSE AS ThereAreDifferencesEconomicOperation,
		|	FALSE AS ThereAreDifferencesThisIsOrderAsInvoice,
		|	COUNT(DISTINCT Orders.ARAPCurrency) > 1 AS ThereAreDifferencesInCurrencyOfMutualSettlements,
		|	COUNT(DISTINCT Orders.VATTaxation) > 1 AS ThereAreDifferencesVATTaxation,
		|	COUNT(DISTINCT Orders.PriceIncludesVAT) > 1 AS ThereAreDifferencesPriceIncludesVAT,
		|	COUNT(DISTINCT Orders.ARAPObjectSettings) > 1 AS ThereAreDifferencesInOrderOfCalculations,
		|	COUNT(DISTINCT Orders.LineOfBusiness) > 1 AS ThereAreDifferencesInDirectionOfActivity,
		|	CASE
		|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
		|		AND COUNT(DISTINCT Orders.DeliveryMethod) > 1
		|		AND MAX(Orders.MethodOfDeliveryByCarrier) = TRUE
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreIncompatibleShippingMethods,
		|	COUNT(DISTINCT CASE
		|		WHEN Orders.BankAccount <> VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
		|			THEN Orders.BankAccount
		|		ELSE NULL
		|	END) > 1 AS ThereAreDifferencesBankAccount,
		|	COUNT(DISTINCT CASE
		|		WHEN Orders.CashAccount <> VALUE(Catalog.CashAccounts.EmptyRef)
		|			THEN Orders.CashAccount
		|		ELSE NULL
		|	END) > 1 AS ThereAreDifferencesCheckout,
		|	COUNT(DISTINCT Orders.PaymentMethod) > 1 AS ThereAreDifferencesInFormOfPayment,
		|	COUNT(DISTINCT Orders.ForeignCurrencyTransaction) > 1 AS ThereAreDifferencesPaymentInCurrency,
		|	COUNT(DISTINCT Orders.PaymentSchedule) > 1 AS ThereAreDifferencesPaymentSchedule
		|INTO TTHeaderDetails
		|FROM
		|	TTOrders AS Orders
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	DocumentHeader.Partner AS Partner,
		|	DocumentHeader.Counterparty AS Counterparty,
		|	DocumentHeader.Contract AS Contract,
		|	DocumentHeader.Organization AS Organization,
		|	DocumentHeader.LoyaltyCard AS LoyaltyCard,
		|	DocumentHeader.SalesOpportunity AS SalesOpportunity,
		|	DocumentHeader.Warehouse AS Warehouse,
		|	DocumentHeader.BusinessOperation AS BusinessOperation,
		|	DocumentHeader.ARAPCurrency AS ARAPCurrency,
		|	DocumentHeader.VATTaxation AS VATTaxation,
		|	DocumentHeader.PriceIncludesVAT AS PriceIncludesVAT,
		|	DocumentHeader.ARAPObjectSettings AS ARAPObjectSettings,
		|	DocumentHeader.PaymentMethod AS PaymentMethod,
		|	DocumentHeader.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	DocumentHeader.CashAccount AS CashAccount,
		|	DocumentHeader.PaymentSchedule AS PaymentSchedule,
		|	FALSE AS ThereAreDifferencesInFinancialAccounting,
		|	DocumentHeader.LineOfBusiness AS LineOfBusiness,
		|	DocumentHeader.Department AS Department,
		|	DocumentHeader.ContactPerson AS ContactPerson,
		|	DocumentHeader.ThereAreDifferencesPartner AS ThereAreDifferencesPartner,
		|	DocumentHeader.ThereAreDifferencesCounterparty AS ThereAreDifferencesCounterparty,
		|	DocumentHeader.ThereAreDifferencesContract AS ThereAreDifferencesContract,
		|	FALSE AS ThereAreDifferencesAgreement,
		|	FALSE AS ThereAreDifferencesInMultiTurnContainers,
		|	FALSE AS ThereAreDifferencesDepositForContainerIsRequired,
		|	FALSE AS ThereAreDifferencesInReturnPeriodOfMultiTurnContainers,
		|	DocumentHeader.ThereAreDifferencesCompany AS ThereAreDifferencesCompany,
		|	DocumentHeader.ThereAreDifferencesSalesOpportunity AS ThereAreDifferencesSalesOpportunity,
		|	DocumentHeader.ThereAreDifferencesWarehouse AS ThereAreDifferencesWarehouse,
		|	DocumentHeader.ThereAreDifferencesEconomicOperation AS ThereAreDifferencesEconomicOperation,
		|	DocumentHeader.ThereAreDifferencesInCurrencyOfMutualSettlements AS ThereAreDifferencesInCurrencyOfMutualSettlements,
		|	DocumentHeader.ThereAreIncompatibleShippingMethods AS ThereAreIncompatibleShippingMethods,
		|	DocumentHeader.ThereAreDifferencesInDirectionOfActivity AS ThereAreDifferencesInDirectionOfActivity,
		|	DocumentHeader.ThereAreDifferencesVATTaxation AS ThereAreDifferencesVATTaxation,
		|	DocumentHeader.ThereAreDifferencesPriceIncludesVAT AS ThereAreDifferencesPriceIncludesVAT,
		|	DocumentHeader.ThereAreDifferencesInOrderOfCalculations AS ThereAreDifferencesInOrderOfCalculations,
		|	DocumentHeader.ThereAreDifferencesBankAccount AS ThereAreDifferencesBankAccount,
		|	DocumentHeader.ThereAreDifferencesCheckout AS ThereAreDifferencesCheckout,
		|	DocumentHeader.ThereAreDifferencesInFormOfPayment AS ThereAreDifferencesInFormOfPayment,
		|	DocumentHeader.ThereAreDifferencesPaymentInCurrency AS ThereAreDifferencesPaymentInCurrency,
		|	DocumentHeader.ThereAreDifferencesPaymentSchedule AS ThereAreDifferencesPaymentSchedule,
		|	DocumentHeader.ThereAreDifferencesThisIsOrderAsInvoice AS ThereAreDifferencesThisIsOrderAsInvoice,
		|	DocumentHeader.BankAccount AS BankAccount,
		|	DocumentHeader.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	DocumentHeader.Shipper AS Shipper,
		|	DocumentHeader.GoodsRecipient AS GoodsRecipient,
		|	DocumentHeader.ShipperBankAccount AS ShipperBankAccount,
		|	DocumentHeader.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
		|	DocumentHeader.OriginWarehouse AS OriginWarehouse,
		|	DocumentHeader.ItIsForbiddenToSelectWarehouseGroup AS ItIsForbiddenToSelectWarehouseGroup,
		|	DocumentHeader.DeliveryMethod AS DeliveryMethod,
		|	DocumentHeader.CarrierPartner AS CarrierPartner,
		|	DocumentHeader.DeliveryAddress AS DeliveryAddress,
		|	CASE
		|		WHEN DocumentHeader.DeliveryAddressFieldValuesEmpty
		|			THEN """"
		|		ELSE ISNULL(OrderHeader_.DeliveryAddressFieldValues, """")
		|	END AS DeliveryAddressFieldValues,
		|	CASE
		|		WHEN DocumentHeader.AdditionalInformationOnDeliveryOfEmpty
		|			THEN """"
		|		ELSE ISNULL(OrderHeader_.AdditionalDeliveryInformation, """")
		|	END AS AdditionalDeliveryInformation,
		|	DocumentHeader.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
		|	DocumentHeader.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	DocumentHeader.DeliveryZone AS DeliveryZone,
		|	DocumentHeader.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	DocumentHeader.DeliveryTimeTo AS DeliveryTimeTo,
		|	0 AS ReusablePackageReturnCycleLength,
		|	FALSE AS CalculatePackageReturnDateAccordingToCalendar,
		|	VALUE(Catalog.BusinessCalendars.EmptyRef) AS ScheduleOfPackageReturn
		|FROM
		|	TTHeaderDetails AS DocumentHeader
		|		LEFT JOIN TTOrders AS OrderHeader_
		|		ON TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderDocument.Ref AS SalesOrder,
		|	OrderDocument.Status AS Status,
		|	NOT OrderDocument.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN OrderDocument.Status IN (&ArrayOfOrderStatuses)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus
		|FROM
		|	Document.SubcontractOrder2_5 AS OrderDocument
		|WHERE
		|	OrderDocument.Ref IN (&ReferencesArrray)
		|	AND (NOT OrderDocument.Posted
		|	OR NOT OrderDocument.Status IN (&ArrayOfOrderStatuses))";

	Query.SetParameter("ReferencesArrray" , ReferencesArrray);
	
	Query.SetParameter(
		"BusinessOperation" , ProcessingByThirdPartiesClientServer.BusinessOperationByDocumentName(DocumentName));
		
	Query.SetParameter("ToUseTermsOfSales", False);
	
	Query.SetParameter(
		"UseTransportationJobsForDeliveryAccountingByCarriers",
		GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
		
	Query.SetParameter(
		"ArrayOfOrderStatuses",
		Documents.SubcontractOrder2_5.ValidInputStatusesBasedOn());
	
	FilterByWarehouse = False;
	Warehouse         = Undefined;
	If TypeOf(OrderProperties_) = Type("Structure")
		And OrderProperties_.Property("Warehouse") Then
		FilterByWarehouse = True;
		Warehouse         = OrderProperties_.Warehouse;
	EndIf;
	Query.SetParameter("FilterByWarehouse", FilterByWarehouse);
	Query.SetParameter("Warehouse",         Warehouse);
	
	QueryResult = Query.ExecuteBatch(); // Array of QueryResult - 
	
	ResultHeaderDetails = QueryResult[4];
	SelectionHeaderDetails = ResultHeaderDetails.Select();
	SelectionHeaderDetails.Next();
	
	ExcludedOrders = New Array;
	OrdersWithInvalidOperation = QueryResult[2].Select();
	
	While OrdersWithInvalidOperation.Next() Do
		
		If ReferencesArrray.Count() > 1 Then
			MessageText = NStr("vi = 'Lệnh %ReferenceOrder% bị bỏ qua vì không thể lập chứng từ ""%DocumentName%"" trên cơ sở lệnh có giao dịch ""%BusinessOperation%"".';
								|ru = 'Распоряжение %ReferenceOrder% пропущено, т.к. невозможно оформить документ ""%DocumentName%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'The %ReferenceOrder% reference is skipped as you cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" transaction.'; fa = 'The %ReferenceOrder% reference is skipped as you cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" transaction.';
								|it = 'La disposizione %ReferenceOrder% è mancante, poiché non è possibile emettere il documento ""%DocumentName%"" sulla base della disposizione con operazione ""%BusinessOperation%"".';
								|pl = 'Zamówienie %ReferenceOrder% pominięte, ponieważ nie można wydać dokumentu ""%DocumentName%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = '""%BusinessOperation%"" işlemi ile ilgili bir talimat temelinde ""%DocumentName%"" belgesi düzenlemek mümkün olmadığından dolayı %ReferenceOrder% talimatı atlandı.'");
		Else
			MessageText = NStr("vi = 'Không thể lập chứng từ ""%DocumentName%"" trên cơ sở lệnh có giao dịch ""%BusinessOperation%"".';
								|ru = 'Невозможно оформить документ ""%DocumentName%"" на основании распоряжения с операцией ""%BusinessOperation%"".';
								|en = 'Cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" operation.'; fa = 'Cannot register the ""%DocumentName%"" document based on the reference with the ""%BusinessOperation%"" operation.';
								|it = 'Non è possibile emettere il documento ""%DocumentName%"" in base alla disposizione con l''operazione ""%BusinessOperation%"".';
								|pl = 'Nie jest możliwe wystawienie dokumentu ""%DocumentName%"" na podstawie zamówienia z operacją ""%BusinessOperation%"".';
								|tr = '""%BusinessOperation%"" işlemi ile ilgili bir talimat temelinde ""%DocumentName%"" belgesi düzenlemek mümkün değildir.'");
		EndIf;
		
		MessageText =
		 StrReplace(MessageText, "%DocumentName%", NStr("vi = 'Chuyển nguyên liệu cho gia công';
														|ru = 'Передача сырья переработчику';
														|en = 'Goods issue — Subcontracting services received'; fa = 'صدور کالا — خدمات پیمانکاری فرعی دریافتی';
														|it = 'Trasferimento di materie prime al subfornitore';
														|pl = 'Przenoszenie surowców do procesora';
														|tr = 'Hammaddelerin fason üreticiye transferi'"));
		 
		MessageText =
			StrReplace(MessageText, "%BusinessOperation%", OrdersWithInvalidOperation.BusinessOperation);
			
		MessageText =
		 StrReplace(MessageText, "%ReferenceOrder%", OrdersWithInvalidOperation.SalesOrder);
		
		Common.MessageToUser(MessageText, OrdersWithInvalidOperation.SalesOrder);
		
		ExcludedOrders.Add(OrdersWithInvalidOperation.SalesOrder);
		
	EndDo;
	
	If OrdersWithInvalidOperation.Count() = ReferencesArrray.Count() Then
		Return False;
	EndIf;
	
	ReferencesArrray = CommonClientServer.ArraysDifference(ReferencesArrray, ExcludedOrders);
	
	Cancel = False;
	
	If SalesServer.ReportErrorsInDataGenerationAndImplementation(SelectionHeaderDetails) Then
		ErrorText = NStr("vi = 'Không thể nhập một chứng từ chuyển giao nguyên vật liệu cho bên nhận gia công. Hãy sử dụng chỗ làm việc ""Chứng từ cần lập"".';
						|ru = 'Ввод одной передачи сырья переработчику невозможен. Воспользуйтесь рабочим местом ""Документы к оформлению"".';
						|en = 'You cannot enter one customer stock fill-up. Use the ""Unregistered documents"" workplace.'; fa = 'You cannot enter one customer stock fill-up. Use the ""Unregistered documents"" workplace.';
						|it = 'Non è possibile l''inserimento di un trasferimento di materie prime all''elaboratore. Utilizzare la postazione di lavoro ""Documenti in registrazione"".';
						|pl = 'Wprowadzenie jednego przeniesienia surowców do przetwórcy jest niemożliwe. Użyj miejsca pracy ""Dokumenty do rejestracji"".';
						|tr = 'Fason üreticiye tek bir hammadde transferi girişi mümkün değildir. ""Düzenlenecek belgeler"" çalışma alanını kullanın.'");
		Common.MessageToUser(ErrorText,,,, Cancel);
	Else
		
		If Not QueryResult[5].IsEmpty() Then

			SampleOrders = QueryResult[5].Select();
			
			While SampleOrders.Next() Do
				
				Documents.SubcontractOrder2_5.CheckPossibilityOfEnteringBasedOn(
					SampleOrders.SalesOrder, SampleOrders.Status, SampleOrders.ThereAreErrorsPosted);
				
			EndDo;
			
		EndIf;
		
		HeaderAttributes = New Structure;
		For Each Column In ResultHeaderDetails.Columns Do
			HeaderAttributes.Insert(Column.Name, SelectionHeaderDetails[Column.Name]);
		EndDo;
		
		GoodsDelivery.AddDeliveryDetailsToFillInDetails(HeaderAttributes,SelectionHeaderDetails);
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

#EndRegion