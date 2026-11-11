#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
// 
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export

	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("GoodsDelivery");
	
	CustomerInvoiceLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
// 
// Parameters:
//  Document - DocumentRef.CustomerInvoice, DocumentObject.CustomerInvoice - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
		
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CustomerInvoice") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	Else
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	EndIf;

	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDatesOfConsignmentGoodsTransfer(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		QueryTextBonusPoints(Query, QueryTexts, Registers, DocumentObject);
		QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters);
		QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers);
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers, DocumentObject);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject);
		
		CustomerInvoiceLocalization.AddRequestTexts(Query, QueryTexts, Registers, DocumentObject);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	ReflectReserve(Query, QueryTexts, Registers, DocumentObject);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Number AS Number,
	|	Header.Posted AS Posted,
	|	Header.Ref AS Ref,
	|	Header.Date AS Date,
	|	Header.Partner AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	CASE WHEN (Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers)
	|			OR Header.DeliveryMethod = VALUE(Enum.TransportMethods.ToCustomerByCourier)
	|		THEN VALUE(Enum.TransportMethods.SelfPickup)
	|		ELSE Header.DeliveryMethod
	|	END                   AS DeliveryMethod,
	|	Header.DeliveryZone AS Zone,
	|	CASE
	|		WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|	END AS Address,
	|	CASE
	|		WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|	END AS FieldValueAddress,
	|	Header.DeliveryTimeFrom AS TimeFrom,
	|	Header.DeliveryTimeTo AS TimeTo,
	|	Header.AdditionalDeliveryInformation AS AdditionalInformation,
	|	NestedRequestForProducts.Warehouse AS Warehouse,
	|	TRUE AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	Header.Terms.SplitGoodsIssueNotesByReferences AS SplitGoodsIssueNotesByReferences
	|FROM
	|	(SELECT DISTINCT
	|		Goods.Ref AS Ref,
	|		Goods.Warehouse AS Warehouse
	|	FROM
	|		Document.CustomerInvoice.Goods AS Goods
	|	WHERE
	|		Goods.Ref IN(&References)
	|		AND Goods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))) AS NestedRequestForProducts
	|		INNER JOIN Document.CustomerInvoice AS Header
	|		ON (Header.Ref = NestedRequestForProducts.Ref)
	|WHERE
	|	(NOT Header.OrderSales
	|			OR NOT &UseAdvancedFeaturesOfSalesOrder
	|			OR Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers)";
	
	Return QueryText;
	
EndFunction

// Returns a list of acceptable business operations for the Foundation documents.
//
// Parameters:
//   EconomicOperationOfRealization - EnumRef.BusinessTransactions - Operation of the implementation document.
//
// Returns:
//   ValueList - the list of acceptable business operations of the foundation document.
//
Function AcceptableOperationsOfBaseDocuments(EconomicOperationOfRealization) Export
	
	TransactionList = New ValueList;
	
	If EconomicOperationOfRealization = Enums.BusinessTransactions.SaleToCustomer Or
		EconomicOperationOfRealization = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		
		TransactionList.Add(Enums.BusinessTransactions.SaleToCustomer);
		TransactionList.Add(Enums.BusinessTransactions.ReturnFromRetailCustomer);
		TransactionList.Add(Enums.BusinessTransactions.ReturnOfGoodsFromCustomer);
		
	Else
		
		TransactionList.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		TransactionList.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
		
	EndIf;
	
	Return TransactionList;
	
EndFunction

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("VATTaxation");
	ArrayOfAllProps.Add("PaymentMethod");
	ArrayOfAllProps.Add("CashAccount");
	ArrayOfAllProps.Add("Status");
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("ToReturnReusablePackage");
	ArrayOfAllProps.Add("ReusablePackagesReturnDate");
	ArrayOfAllProps.Add("PackageDepositIsRequired");
	ArrayOfAllProps.Add("DateOfTransferOfTitleToGoods");
	ArrayOfAllProps.Add("CustomerCounterparty");
	ArrayOfAllProps.Add("CustomerPartner");
	ArrayOfAllProps.Add("CustomerContract");
	ArrayOfAllProps.Add("Warehouse");
	ArrayOfAllProps.Add("Goods.PercentRateOfManualDiscount");
	ArrayOfAllProps.Add("Goods.ManualDiscount");
	ArrayOfAllProps.Add("Goods.PercentRateOfAutomaticDiscountMarkup");
	ArrayOfAllProps.Add("Goods.DiscountMarkupAmount");
	ArrayOfAllProps.Add("Goods.Warehouse");
	ArrayOfAllProps.Add("ConsigneeNumber");
	ArrayOfAllProps.Add("ConsigneeDate");
	ArrayOfAllProps.Add("ConsigneeDocumentName");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
	 Or Not ValueIsFilled(BusinessOperation) Then
		ArrayOfOperationDetails.Add("VATTaxation"); 
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("Status");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackagesReturnDate");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfAutomaticDiscountMarkup");
		ArrayOfOperationDetails.Add("Goods.DiscountMarkupAmount");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		ArrayOfOperationDetails.Add("VATTaxation"); 
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackagesReturnDate");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfAutomaticDiscountMarkup");
		ArrayOfOperationDetails.Add("Goods.DiscountMarkupAmount");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
	
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		ArrayOfOperationDetails.Add("Status");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackagesReturnDate");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then	
		ArrayOfOperationDetails.Add("VATTaxation"); 
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("Status");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackagesReturnDate");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		ArrayOfOperationDetails.Add("DateOfTransferOfTitleToGoods");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfAutomaticDiscountMarkup");
		ArrayOfOperationDetails.Add("Goods.DiscountMarkupAmount");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("Status");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackagesReturnDate");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("CustomerCounterparty");
		ArrayOfOperationDetails.Add("CustomerPartner");
		ArrayOfOperationDetails.Add("CustomerContract");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		ArrayOfOperationDetails.Add("ConsigneeNumber");
		ArrayOfOperationDetails.Add("ConsigneeDate");
		ArrayOfOperationDetails.Add("ConsigneeDocumentName");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		ArrayOfOperationDetails.Add("VATTaxation"); 
		ArrayOfOperationDetails.Add("Status");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackagesReturnDate");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		ArrayOfOperationDetails.Add("DateOfTransferOfTitleToGoods");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("CustomerCounterparty");
		ArrayOfOperationDetails.Add("CustomerPartner");
		ArrayOfOperationDetails.Add("CustomerContract");
		ArrayOfOperationDetails.Add("Warehouse");
		ArrayOfOperationDetails.Add("Goods.Warehouse");
		ArrayOfOperationDetails.Add("ConsigneeNumber");
		ArrayOfOperationDetails.Add("ConsigneeDate");
		ArrayOfOperationDetails.Add("ConsigneeDocumentName");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		ArrayOfOperationDetails.Add("VATTaxation"); 
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("Status");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfAutomaticDiscountMarkup");
		ArrayOfOperationDetails.Add("Goods.DiscountMarkupAmount");
		
	EndIf;
	
EndProcedure

// Fills in product and discount tables based on selection data or an array of orders
//
// Parameters:
//	SelectionData_            - Structure - fields that will be used to select order balances for filling in the document
//	Goods                  - FormDataCollection - item table in which are placed the remains of the orders
//	DiscountsMarkups           - FormDataCollection - discount table where discounts on orders will be placed
//	BonusPointAccrual - FormDataCollection - the table of bonus points, in which the accruals for orders will be placed
//	ImplementationWarehouse         - CatalogRef.Warehouses - warehouse where order balances will be selected
//	AnArrayOfOrders           - Array - orders for which balances will be selected
//	FillParameters     - Structure - fill parameters.
//	PackageBarcodes       - ValueTable - data on brands.
//
Procedure FillByOrderBalances(SelectionData_,
	                                 Goods,
	                                 DiscountsMarkups,
	                                 BonusPointAccrual,
	                                 ImplementationWarehouse,
	                                 AnArrayOfOrders,
	                                 FillParameters, 
	                                 PackageBarcodes) Export
	
	RegistrationOption = Undefined;
	DisplayMessage_1 = True;
	SelectionByOrdersOrders = False;
	DesignParameters    = Undefined;
	AdvancedWarehousingOnShipment = False;
	UseAdvancedFeaturesOfSalesOrder = Undefined;
	If Goods.Count() > 0 Then
		Columns = Goods[0];
	Else
		Columns = Goods.Unload().Columns;
	EndIf;
	ThereAreAttributesItemsOfSet = TMCommonUseClientServer.HasObjectAttribute(Columns, "ProductsInSet");
	ThereIsAttributeSetIndex = TMCommonUseClientServer.HasObjectAttribute(Columns, "SetIndex");
	
	FillParameters.Property("RegistrationOption", RegistrationOption);
	If FillParameters.Property("DisplayMessage_1") Then 
		DisplayMessage_1 = FillParameters.DisplayMessage_1;
	EndIf;
	If FillParameters.Property("SelectionByOrdersOrders") Then 
		SelectionByOrdersOrders = FillParameters.SelectionByOrdersOrders;
	EndIf;
	If FillParameters.Property("DesignParameters", DesignParameters) Then
		If DesignParameters <> Undefined Then
			FillingInOrders = DesignParameters.ByOrders;
			FillingByOrders = DesignParameters.ByNotes;
		EndIf;
	EndIf;
	
	If FillParameters.Property("AdvancedWarehousingOnShipment") Then
		AdvancedWarehousingOnShipment = FillParameters.AdvancedWarehousingOnShipment;
	ElsIf ValueIsFilled(ImplementationWarehouse) Then
		AdvancedWarehousingOnShipment = WarehousesServer.ThereIsOrderWarehouseForShipment(, , ImplementationWarehouse);
	EndIf;
	
	If Not FillParameters.Property("UseAdvancedFeaturesOfSalesOrder",
		UseAdvancedFeaturesOfSalesOrder) Then
		UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
	CheckOrderOfCalculations = True;
	
	If FillParameters.Property("CheckOrderOfCalculations") Then 
		CheckOrderOfCalculations = FillParameters.CheckOrderOfCalculations;
	EndIf;
	
	// Data on the remaining items of the order
	RequestResultForOrderBalances = GetQueryResultsForOrderBalances(
		SelectionData_,
		FillParameters,
		ImplementationWarehouse,
		AnArrayOfOrders);
		
	If RequestResultForOrderBalances[10].IsEmpty() 
		And RequestResultForOrderBalances[11].IsEmpty() 
		And GetFunctionalOption("UseShipmentByRowsInSalesOrder")
		And DisplayMessage_1 Then
		
		ErrorText = SalesServer.ErrorTextNoProductsAvailableForShipment(RegistrationOption);
		Raise ErrorText;
		
	EndIf;
		
	ArrayOfCustomersOrders = New Array();
	ArrayOfARAPObjectsSettings = New Array();
	SampleProducts_ = RequestResultForOrderBalances[10].Select();
	While SampleProducts_.Next() Do
		If ArrayOfCustomersOrders.Find(SampleProducts_.SalesOrder) = Undefined Then
			ArrayOfCustomersOrders.Add(SampleProducts_.SalesOrder);
		EndIf;
		If CheckOrderOfCalculations
			And ValueIsFilled(SampleProducts_.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(SampleProducts_.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(SampleProducts_.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If AnArrayOfOrders = Undefined
		And CheckOrderOfCalculations 
		And ArrayOfARAPObjectsSettings.Count() > 1 Then
		
		If SelectionData_.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			Common.MessageToUser(NStr("vi = 'Trong các lệnh đã tìm thấy, trường ""Trình tự hạch toán"" là khác nhau';
										|ru = 'У найденных распоряжений отличается поле ""Порядок расчетов""';
										|en = 'The ""Payment terms"" field data is different for the found references'; fa = 'The ""Payment terms"" field data is different for the found references';
										|it = 'The ""Payment terms"" field data is different for the found references';
										|pl = 'The ""Payment terms"" field data is different for the found references';
										|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Else
			Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
										|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
										|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
										|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
										|pl = 'The ""Payment terms"" field data is different for the found orders';
										|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		EndIf;
		
		Return;
	EndIf;
	
	// Getting a discount/mark-up table
	QueryText =
	"SELECT
	|	DiscountsMarkups.Ref AS SalesOrder,
	|	DiscountsMarkups.ConnectionKey AS ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup AS DiscountMarkup,
	|	DiscountsMarkups.Sum AS Sum
	|FROM
	|	Document.SalesOrder.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	DiscountsMarkups.Ref IN (&ArrayOfCustomersOrders)
	|UNION ALL
	|SELECT
	|	DiscountsMarkups.Ref AS SalesOrder,
	|	DiscountsMarkups.ConnectionKey AS ConnectionKey,
	|	DiscountsMarkups.DiscountMarkup AS DiscountMarkup,
	|	DiscountsMarkups.Sum AS Sum
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.DiscountsMarkups AS DiscountsMarkups
	|WHERE
	|	DiscountsMarkups.Ref IN (&ArrayOfCustomersOrders)
	|";
	Query = New Query(QueryText);
	Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
	DiscountsOrderMargins = Query.Execute().Unload();
	
	// Clearing the discount/mark-up table of the current object
	DiscountsMarkups.Clear();
	
	UseLoyaltyPrograms = GetFunctionalOption("UseLoyaltyPrograms");
	
	If UseLoyaltyPrograms Then
		
		// Getting a table of bonus points
		QueryText =
		"SELECT 
		|	TabularSection.Ref AS SalesOrder,
		|	TabularSection.ConnectionKey AS ConnectionKey,
		|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
		|	TabularSection.LoyaltyProgram.BonusConversionCurrency AS BonusConversionCurrency,
		|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency AS ConversionRateOfBonusesIntoCurrency,
		|	DATEADD(TabularSection.AccrualDate, DAY,
		|		DATEDIFF(
		|			BEGINOFPERIOD(TabularSection.Ref.Date, DAY),
		|			BEGINOFPERIOD(&CurrentDate, DAY),
		|			DAY)
		|	) AS AccrualDate,
		|	CASE
		|		WHEN TabularSection.DateOfDeduction = DATETIME(1, 1, 1)
		|			THEN TabularSection.DateOfDeduction
		|		ELSE
		|			DATEADD(
		|				TabularSection.DateOfDeduction,
		|				DAY,
		|				DATEDIFF(
		|					BEGINOFPERIOD(TabularSection.Ref.Date, DAY),
		|					BEGINOFPERIOD(&CurrentDate, DAY),
		|					DAY))
		|	END AS DateOfDeduction,
		|	TabularSection.AmountOfBonusPoints AS AmountOfBonusPoints
		|FROM
		|	Document.SalesOrder.BonusPointAccrual AS TabularSection
		|WHERE
		|	TabularSection.Ref IN (&ArrayOfCustomersOrders)
		|UNION ALL
		|SELECT
		|	TabularSection.Ref,
		|	TabularSection.ConnectionKey,
		|	TabularSection.LoyaltyProgram,
		|	TabularSection.LoyaltyProgram.BonusConversionCurrency,
		|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency,
		|	TabularSection.AccrualDate,
		|	TabularSection.DateOfDeduction,
		|	TabularSection.AmountOfBonusPoints
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.BonusPointAccrual AS TabularSection
		|WHERE
		|	TabularSection.Ref IN (&ArrayOfCustomersOrders)
		|";
		Query = New Query(QueryText);
		Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
		Query.SetParameter("CurrentDate", CurrentSessionDate());
		AccrualOfBonusPointsOfOrder = Query.Execute().Unload();
		
		LoyaltyProgram = New Structure("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency,
			|StructureOfCurrencyConversionRates");
		
		LoyaltyPrograms = AccrualOfBonusPointsOfOrder.Copy();
		
		LoyaltyPrograms.GroupBy("LoyaltyProgram, 
			|BonusConversionCurrency, 
			|ConversionRateOfBonusesIntoCurrency");
		
		If LoyaltyPrograms.Count() > 1
			And DisplayMessage_1 Then
			
			If SelectionData_.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
				ErrorText = NStr("vi = 'Đã tìm thấy các chương trình khách hàng thân thiết khác để tính điểm thưởng. Không thể giao các lệnh 
					| có chương trình tích điểm khác nhau trong một chứng từ.';
					|ru = 'Обнаружены разные программы лояльности для начисления бонусных баллов. Распоряжения 
					|с разными бонусными программами лояльности не могут быть отгружены в одном документе.';
					|en = 'Different loyalty programs are found for accrual of bonus points. References 
					|with different loyalty programs cannot be shipped within one document.'; fa = 'Different loyalty programs are found for accrual of bonus points. References 
					|with different loyalty programs cannot be shipped within one document.';
					|it = 'Different loyalty programs are found for accrual of bonus points. References 
					|with different loyalty programs cannot be shipped within one document.';
					|pl = 'Different loyalty programs are found for accrual of bonus points. References 
					|with different loyalty programs cannot be shipped within one document.';
					|tr = 'Bonus puan vermek için farklı sadakat programları tespit edilmiştir. Farklı sadakat programlarına sahip siparişler
					|, aynı belge içinde gönderilemez.'");
			Else
				ErrorText = NStr("vi = 'Đã tìm thấy các chương trình khách hàng thân thiết khác để tính điểm thưởng. Không thể giao các đơn hàng 
					| có chương trình tích điểm khác nhau vào một chứng từ.';
					|ru = 'Обнаружены разные программы лояльности для начисления бонусных баллов. Заказы 
					|с разными бонусными программами лояльности не могут быть отгружены в одном документе.';
					|en = 'Different loyalty programs are found for accrual of bonus points. Orders 
					| with different loyalty programs cannot be shipped within one document.'; fa = 'Different loyalty programs are found for accrual of bonus points. Orders 
					| with different loyalty programs cannot be shipped within one document.';
					|it = 'Sono stati rilevati programmi fedeltà per il calcolo di punti bonus. Gli ordini 
					|con diversi programmi bonus fedeltà non possono essere caricati in un documento.';
					|pl = 'Wykryto różne programy lojalnościowe do naliczenia punktów bonusowych. Zamówienia  
					|z różnymi lojalnościowymi programami bonusowymi nie mogą być wystawione w jednym dokumencie.';
					|tr = 'Bonus puan vermek için farklı sadakat programları tespit edilmiştir. Farklı sadakat programlarına sahip siparişler
					| aynı belge içinde gönderilemez.'");
			EndIf;
				
			Raise ErrorText;
		ElsIf LoyaltyPrograms.Count() = 1 Then
			FillPropertyValues(LoyaltyProgram, LoyaltyPrograms[0]);
			
			LoyaltyProgram.StructureOfCurrencyConversionRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(LoyaltyProgram.BonusConversionCurrency, 
				CurrentSessionDate(),
				SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
			
		EndIf;
		
	EndIf;
	
	// Clearing the bonus points table of the current object
	BonusPointAccrual.Clear();
	
	Query = New Query;
	Query.SetParameter("ArrayOfCustomersOrders", ArrayOfCustomersOrders);
	Query.SetParameter("DocumentCurrency",       SelectionData_.Currency);
		
	Query.Text =
	"SELECT ALLOWED
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref AS SalesOrder,
	|	TheOrdersTable.Currency AS Currency,
	|	TheOrdersTable.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN TheOrdersTable.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConvertToDocumentCurrency,
	|	TheOrdersTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|FROM
	|	Document.SalesOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref AS SalesOrder,
	|	TheOrdersTable.Currency AS Currency,
	|	TheOrdersTable.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN TheOrdersTable.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConvertToDocumentCurrency,
	|	TheOrdersTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(TableShipments.Date, DAY) AS Date,
	|	TableShipments.Ref AS SalesOrder,
	|	TableShipments.Currency AS Currency,
	|	TRUE AS PriceIncludesVAT,
	|	CASE
	|		WHEN TableShipments.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConvertToDocumentCurrency,
	|	FALSE AS ThisIsOrderAsInvoice
	|FROM
	|	Document.GoodsShipmentToCustomer AS TableShipments
	|WHERE
	|	TableShipments.Ref IN(&ArrayOfCustomersOrders)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(TableEnteringBalances.Lot.Date, DAY) AS Date,
	|	TableEnteringBalances.Lot AS SalesOrder,
	|	TableEnteringBalances.Lot.Currency AS Currency,
	|	TableEnteringBalances.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN TableEnteringBalances.Lot.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConvertToDocumentCurrency,
	|	FALSE AS ThisIsOrderAsInvoice
	|FROM
	|	Document.OBEntryGoods AS TableEnteringBalances
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableEnteringBalances.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	TableEnteringBalances.Posted
	|	AND TableEnteringBalances.Lot IN(&ArrayOfCustomersOrders)
	|	AND DocumentsRegistry.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	BEGINOFPERIOD(CombinedOrderTable.Date, DAY) AS Date,
	|	CombinedOrderTable.Currency AS Currency,
	|	CombinedOrderTable.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|		TheOrdersTable.Currency AS Currency,
	|		TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|	FROM
	|		Document.SalesOrder AS TheOrdersTable
	|	WHERE
	|		TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|		AND TheOrdersTable.Currency <> &DocumentCurrency
	|
	|	UNION ALL
	|
	|	SELECT
	|		BEGINOFPERIOD(TheOrdersTable.Date, DAY),
	|		TheOrdersTable.Currency,
	|		TheOrdersTable.Organization.LocalAccountingCurrency
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS TheOrdersTable
	|	WHERE
	|		TheOrdersTable.Ref IN(&ArrayOfCustomersOrders)
	|		AND TheOrdersTable.Currency <> &DocumentCurrency) AS CombinedOrderTable";
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultOrderDetails = ResultsArray[0]; // QueryResult
	ResultSelection = ResultsArray[1]; // QueryResult
	
	OrderDetails_ = ResultOrderDetails.Select();
	
	TableOfExchangeRates = New ValueTable;
	TableOfExchangeRates.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("Date", New TypeDescription("Date"));
	TableOfExchangeRates.Columns.Add("CourseNumerator", New TypeDescription("Number"));
	TableOfExchangeRates.Columns.Add("CourseDenominator", New TypeDescription("Number"));
	
	Selection = ResultSelection.Select();
	
	While Selection.Next() Do
		
		NewRow = TableOfExchangeRates.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Not FillParameters.Property("CourseNumerator")
			Or FillParameters.Property("CourseNumerator")
				And Not ValueIsFilled(FillParameters.CourseNumerator) Then
			Currency_Rates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.Currency, Selection.Date, Selection.LocalAccountingCurrency);
			NewRow.CourseNumerator = Currency_Rates.CourseNumerator;
			NewRow.CourseDenominator = Currency_Rates.CourseDenominator;
		Else
			NewRow.CourseNumerator = FillParameters.CourseNumerator;
			NewRow.CourseDenominator = FillParameters.CourseDenominator;
		EndIf;
		
	EndDo;
	
	If TableOfExchangeRates.Count() > 0 Then
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(SelectionData_.Currency, CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
	EndIf;
	
	RegistrationProcedure = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
	
	FillByWarehouseDocument = 
		(RegistrationProcedure = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst
		And Not SelectionByOrdersOrders
		And UseAdvancedFeaturesOfSalesOrder
		And ValueIsFilled(ImplementationWarehouse));
		
	If DesignParameters <> Undefined Then
		FillByWarehouseDocument = FillingByOrders And Not FillingInOrders;
	EndIf;
	
	ShippedStamps = Undefined;
	AddedStamps = New Map;
	
	ShippedGoods_ = RequestResultForOrderBalances[RequestResultForOrderBalances.UBound()].Unload();

	If AdvancedWarehousingOnShipment
			Or (CommonClientServer.HasAttributeOrObjectProperty(SelectionData_,"BusinessOperation") 
				And SelectionData_.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods) Then
		
		CustomerInvoiceLocalization.GenerateShippedStamps(ArrayOfCustomersOrders, ShippedStamps);
		CustomerInvoiceLocalization.ExcludeSoldBrands(ArrayOfCustomersOrders, ShippedStamps);
		
	EndIf;
	
	CheckWarehouses = Undefined;
	FillParameters.Property("CheckWarehouses", CheckWarehouses);
	
	SampleProducts_.Reset();
	While SampleProducts_.Next() Do
		
		FoundShippedStamps = Undefined;
		
		If ValueIsFilled(CheckWarehouses) Then
			WarehousesByRef = CheckWarehouses.Get(SampleProducts_.SalesOrder);
			If WarehousesByRef <> Undefined
				 And WarehousesByRef.Find(SampleProducts_.Warehouse) = Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		SearchParameters = New Structure;
		SearchParameters.Insert("SalesOrder", SampleProducts_.SalesOrder);
		SearchParameters.Insert("Products", SampleProducts_.Products);
		SearchParameters.Insert("Characteristic", SampleProducts_.Characteristic);
		SearchParameters.Insert("Warehouse", SampleProducts_.Warehouse);
		SearchParameters.Insert("Series", SampleProducts_.Series);
		SearchParameters.Insert("Purpose", SampleProducts_.Purpose);
			
		QuantityToShip = SampleProducts_.Count;
		FillingByOrder = FillByWarehouseDocument And SampleProducts_.CheckShipment;
		If FillingByOrder Then
			
			FoundRows = ShippedGoods_.FindRows(SearchParameters);
			
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
			
			ShippedLine = FoundRows[0];
			
			If ShippedLine.Count > 0 Then
				
				If ShippedLine.Count < SampleProducts_.Count Then
					QuantityToShip = ShippedLine.Count;
					ShippedLine.Count = 0;
				Else
					QuantityToShip = SampleProducts_.Count;
					ShippedLine.Count = ShippedLine.Count - SampleProducts_.Count;
				EndIf;
			Else
				Continue;
			EndIf;
			
		EndIf;
		
		If Not ShippedStamps = Undefined Then
			BrandSearchParameters = New Structure();
			BrandSearchParameters.Insert("SalesOrder", SearchParameters.SalesOrder);
			BrandSearchParameters.Insert("Products", SearchParameters.Products);
			BrandSearchParameters.Insert("Characteristic", SearchParameters.Characteristic);
			BrandSearchParameters.Insert("Warehouse", SearchParameters.Warehouse);
			BrandSearchParameters.Insert("Series", SearchParameters.Series);
			
			FoundShippedStamps = ShippedStamps.FindRows(BrandSearchParameters);
		EndIf;
		
		ProductVATRate = SampleProducts_.VATRate;
		
		RecalculateAmounts = (QuantityToShip <> SampleProducts_.QuantityInOrder);
		
		RecalculateVATRate = SelectionData_.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
			And SampleProducts_.RowCode = 0
			And Not ValueIsFilled(SampleProducts_.VATRate);
		
		RecalculateVATAmount = SelectionData_.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
			And (SampleProducts_.RowCode = 0
				Or TypeOf(SampleProducts_.SalesOrder) = Type("DocumentRef.GoodsShipmentToCustomer"));
		
		RecalculateAmountWithoutVAT = SelectionData_.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
			And SampleProducts_.RowCode = 0
			And Not SelectionData_.PriceIncludesVAT;
		
		ExcludeProperties_ = "Count";
		
		If RecalculateAmounts Then
			// If it is necessary to recalculate the amounts, the listed details will be recalculated based on the amount of mutual settlements.
			ExcludeProperties_ = ExcludeProperties_ + ", Sum, VATAmount, DiscountMarkupAmount, ManualDiscount";
		EndIf;
		
		TabRow = Goods.Add();
		FillPropertyValues(TabRow, SampleProducts_, , ExcludeProperties_);
		TabRow.VATRate = ProductVATRate;

		TabRow.Count = QuantityToShip;
		TabRow.NumberOfPackages = TabRow.Count / SampleProducts_.ZoomRatio;
		
		If SelectionByOrdersOrders Then
			
			If SelectionData_.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
				Then
				
				TabRow.QuantityInOrder = SampleProducts_.QuantityInOrder;
				TabRow.PackagingQuantityInTheOrder = SampleProducts_.QuantityInOrder / SampleProducts_.ZoomRatio;
				
				TabRow.QuantityInTransit = QuantityToShip;
				TabRow.NumberOfPackagingUnitsInTransit = QuantityToShip / SampleProducts_.ZoomRatio;
			Else
				
				TabRow.QuantityInOrder = ?(SampleProducts_.RowCode <> 0, QuantityToShip, 0);
				TabRow.PackagingQuantityInTheOrder = ?(SampleProducts_.RowCode<> 0, QuantityToShip, 0) / SampleProducts_.ZoomRatio;
				
				TabRow.QuantityInTransit = 0;
				TabRow.NumberOfPackagingUnitsInTransit = 0;
			EndIf;
			
			SearchParameters = New Structure;
			SearchParameters.Insert("SalesOrder", SampleProducts_.SalesOrder);
			SearchParameters.Insert("Products", SampleProducts_.Products);
			SearchParameters.Insert("Characteristic", SampleProducts_.Characteristic);
			SearchParameters.Insert("Warehouse", SampleProducts_.Warehouse);
			SearchParameters.Insert("Series", SampleProducts_.Series);
			SearchParameters.Insert("Purpose", SampleProducts_.Purpose);
			
			FoundRows = ShippedGoods_.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 Then
				
				ShippedLine = FoundRows[0];
				
				If ShippedLine.NumberInProgress > 0 Then
					TabRow.NumberInProgress = ShippedLine.NumberInProgress / SampleProducts_.ZoomRatio;
					ShippedLine.NumberInProgress = 0;
				EndIf;
				
				If ShippedLine.Count > 0 Then
					If ShippedLine.Count <= SampleProducts_.Count Then
						TabRow.NoteQuantity = ShippedLine.Count;
						TabRow.PackagingQuantityInTheNote = ShippedLine.Count / SampleProducts_.ZoomRatio;
						ShippedLine.Count = 0;
						ShippedGoods_.Delete(ShippedLine);
					Else
						TabRow.NoteQuantity = SampleProducts_.Count;
						TabRow.PackagingQuantityInTheNote =SampleProducts_.Count / SampleProducts_.ZoomRatio;
						ShippedLine.Count = ShippedLine.Count - SampleProducts_.Count;
					EndIf;
					
					If Not ShippedStamps = Undefined And TabRow.AdvancedWarehousingOnShipment Then
						BrandSearchParameters = New Structure();
						BrandSearchParameters.Insert("SalesOrder", SearchParameters.SalesOrder);
						BrandSearchParameters.Insert("Products", SearchParameters.Products);
						BrandSearchParameters.Insert("Characteristic", SearchParameters.Characteristic);
						BrandSearchParameters.Insert("Warehouse", SearchParameters.Warehouse);
						BrandSearchParameters.Insert("Series", SearchParameters.Series);
						
						FoundShippedStamps = ShippedStamps.FindRows(BrandSearchParameters);
					EndIf; 
					
					If TabRow.PackagingQuantityInTheNote > 0 And Not FoundShippedStamps = Undefined Then
						For Each Brand In FoundShippedStamps Do
							If AddedStamps.Get(Brand.PackageBarcode) = Undefined Then
								AddedStamps.Insert(Brand.PackageBarcode, True);
							Else 
								Continue;
							EndIf;
							TabLineOfBrand = PackageBarcodes.Add();
							FillPropertyValues(TabLineOfBrand, TabRow);
							TabLineOfBrand.PackageBarcode = Brand.PackageBarcode;
							TabLineOfBrand.FromWarrant = True;
						EndDo; 
					EndIf; 
				EndIf;
			EndIf;
		Else
			If TabRow.NumberOfPackages > 0 And Not FoundShippedStamps = Undefined Then
				For Each Brand In FoundShippedStamps Do
					If AddedStamps.Get(Brand.PackageBarcode) = Undefined Then
						AddedStamps.Insert(Brand.PackageBarcode, True);
					Else 
						Continue;
					EndIf;
					TabLineOfBrand = PackageBarcodes.Add();
					TabLineOfBrand.PackageBarcode = Brand.PackageBarcode;
				EndDo; 
			EndIf; 
		EndIf;
		
		If RecalculateAmounts Then
			
			If FillingByOrder Then
				TabRow.AmountARAP = TabRow.AmountARAP * QuantityToShip / SampleProducts_.Count;
			EndIf;
			
			TabRow.AmountIncludingVAT = TabRow.AmountARAP;
			
		EndIf;
		
		If RecalculateVATRate Then
			
			TabRow.VATRate = VATAccountingERP.VATRateForProductsAndTaxation(
				SampleProducts_.Products,
				SelectionData_.VATTaxation,
				SelectionData_.Organization,
				SelectionData_.Date,
				, True);
		
		EndIf;
		
		If RecalculateAmountWithoutVAT Then
			
			TabRow.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
				SampleProducts_.AmountARAP,
				TabRow.VATRate,
				True,
				SelectionData_.VATTaxation);
			
			TabRow.Sum = TabRow.AmountARAP - TabRow.VATAmount;
			
			If TabRow.NumberOfPackages <> 0 Then 
				TabRow.Price = TabRow.Sum / TabRow.NumberOfPackages;
			EndIf;
			
		ElsIf RecalculateVATAmount Then
			
			TabRow.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(
				SampleProducts_.AmountARAP,
				TabRow.VATRate,
				True,
				SelectionData_.VATTaxation);
			
		EndIf;
		
		OrderDetails_.Reset();
		OrderFound = OrderDetails_.FindNext(TabRow.SalesOrder, "SalesOrder");
		
		FilterParameters = New Structure("Currency,Date", OrderDetails_.Currency, OrderDetails_.Date);
		CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
		
		If OrderFound And OrderDetails_.ConvertToDocumentCurrency Then
			
			If CurrencyExchangeRate.Count() = 1 Then
			
				TabRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.Price,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.AmountIncludingVAT = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.AmountIncludingVAT,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				RecalculateAmounts = True;
			EndIf;
			
		EndIf;
		
		DiscountConversionRate = ?(RecalculateAmounts, TabRow.Count / ?(SampleProducts_.QuantityInOrder<>0,SampleProducts_.QuantityInOrder,1), 1);
		If DiscountConversionRate <> 1 Then
			TabRow.DiscountMarkupAmount = Round(SampleProducts_.DiscountMarkupAmount * DiscountConversionRate,2);
			TabRow.ManualDiscount = Round(SampleProducts_.ManualDiscount * DiscountConversionRate,2);

			TabRow.AmountOfBonusPointsToDeduction = Round(SampleProducts_.AmountOfBonusPointsToDeduction * DiscountConversionRate,2);
			TabRow.AmountOfBonusPointsToDeductionInCurrency = Round(SampleProducts_.AmountOfBonusPointsToDeductionInCurrency * DiscountConversionRate,2);
			TabRow.AmountOfEarnedBonusPointsInCurrency = Round(SampleProducts_.AmountOfEarnedBonusPointsInCurrency * DiscountConversionRate,2);
		EndIf;
		
		If OrderFound And RecalculateAmounts Then
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(
				TabRow, 
				OrderDetails_.PriceIncludesVAT,
				TabRow.PercentRateOfAutomaticDiscountMarkup<>0,
				TabRow.PercentRateOfManualDiscount<>0,
				OrderDetails_.ConvertToDocumentCurrency);
				
			If OrderFound And OrderDetails_.ConvertToDocumentCurrency And CurrencyExchangeRate.Count() = 1 Then
				TabRow.DiscountMarkupAmount = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.DiscountMarkupAmount,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.ManualDiscount = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.ManualDiscount,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.AmountOfBonusPointsToDeductionInCurrency = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.AmountOfBonusPointsToDeductionInCurrency,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
				TabRow.AmountOfEarnedBonusPointsInCurrency = ProcessingOfExchangeRatesTM.ConvertAtRate(
					TabRow.AmountOfEarnedBonusPointsInCurrency,
					CurrencyExchangeRate[0],
					StructureOfNewCurrencyRates);
			EndIf;
		EndIf;
		
		// Formation of the tabular part of discounts
		AmountForAllocation = TabRow.DiscountMarkupAmount;
		
		If TabRow.ConnectionKey <> 0 Then
			For Each OrderDiscountsRow In DiscountsOrderMargins.FindRows(New Structure("SalesOrder,ConnectionKey", TabRow.SalesOrder, TabRow.ConnectionKey)) Do
				
				DiscountsRow = DiscountsMarkups.Add();
				FillPropertyValues(DiscountsRow, OrderDiscountsRow);
				DiscountsRow.Sum = DiscountConversionRate * DiscountsRow.Sum;
				
				If OrderFound And OrderDetails_.ConvertToDocumentCurrency And CurrencyExchangeRate.Count() > 0 Then
					DiscountsRow.Sum = ProcessingOfExchangeRatesTM.ConvertAtRate(
						DiscountsRow.Sum,
						CurrencyExchangeRate[0],
						StructureOfNewCurrencyRates);
					AmountForAllocation = AmountForAllocation - DiscountsRow.Sum;
				EndIf;
				
			EndDo;
		EndIf;
		
		If OrderFound And OrderDetails_.ConvertToDocumentCurrency And AmountForAllocation <> 0 Then
			DiscountsRow.Sum = DiscountsRow.Sum + AmountForAllocation;
		EndIf;
		
		If UseLoyaltyPrograms Then
			
			// Formation of a tabular accrual of bonus points
			AmountForAllocation = TabRow.AmountOfEarnedBonusPointsInCurrency;
			If OrderFound
				And ValueIsFilled(LoyaltyProgram.BonusConversionCurrency)
				And SelectionData_.Currency <> LoyaltyProgram.BonusConversionCurrency Then
				
				AmountForAllocation = ProcessingOfExchangeRatesTM.ConvertAtRate(
					AmountForAllocation,
					StructureOfNewCurrencyRates,
					LoyaltyProgram.StructureOfCurrencyConversionRates);
					
			EndIf;
			
			If AmountForAllocation <> 0
				And ValueIsFilled(LoyaltyProgram.ConversionRateOfBonusesIntoCurrency) Then
				
				AmountForAllocation = AmountForAllocation / LoyaltyProgram.ConversionRateOfBonusesIntoCurrency;
			EndIf;
			
			If TabRow.ConnectionKey <> 0 Then
				For Each OrderBonusPointsLine In AccrualOfBonusPointsOfOrder.FindRows(New Structure("SalesOrder,ConnectionKey", TabRow.SalesOrder, TabRow.ConnectionKey)) Do
					
					BonusPointsLine = BonusPointAccrual.Add();
					FillPropertyValues(BonusPointsLine, OrderBonusPointsLine);
					BonusPointsLine.AmountOfBonusPoints = DiscountConversionRate * BonusPointsLine.AmountOfBonusPoints;
					
					AmountForAllocation = AmountForAllocation - BonusPointsLine.AmountOfBonusPoints;
					
				EndDo;
			EndIf;
			
			If OrderFound And AmountForAllocation <> 0 Then
				BonusPointsLine.AmountOfBonusPoints = BonusPointsLine.AmountOfBonusPoints + AmountForAllocation;
			EndIf;
			
		EndIf;
		
		If ThereAreAttributesItemsOfSet 
			And ThereIsAttributeSetIndex
			And ValueIsFilled(TabRow.ProductsInSet) Then
			TabRow.SetIndex = 1;
		EndIf;
		
	EndDo;
	
	If (SelectionByOrdersOrders Or FillByWarehouseDocument) And ShippedGoods_.Count()>0 Then 
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		StructureOfActions = New Structure;
		StructureOfActions.Insert("ClearAmountOfSettlements");
		RowsToProcess = New Array;
		
		For Each ShippedLine In ShippedGoods_ Do
			
			If ValueIsFilled(CheckWarehouses) Then
				WarehousesByRef = CheckWarehouses.Get(ShippedLine.SalesOrder);
				If WarehousesByRef <> Undefined
					 And WarehousesByRef.Find(ShippedLine.Warehouse) = Undefined Then
					Continue;
				EndIf;
			EndIf;
			
			If ShippedLine.Count > 0 Then //If you have shipped more
				
				SearchParameters = New Structure;
				SearchParameters.Insert("Products", ShippedLine.Products);
				SearchParameters.Insert("Characteristic", ShippedLine.Characteristic);
				SearchParameters.Insert("Warehouse", ShippedLine.Warehouse);
				SearchParameters.Insert("Series", ShippedLine.Series);
				SearchParameters.Insert("Purpose", ShippedLine.Purpose);
				
				If TypeOf(ShippedLine.SalesOrder) = Type("DocumentRef.SalesOrder") Then
					SearchParameters.Insert("SalesOrder",ShippedLine.SalesOrder)
				EndIf;
				
				FoundRows = Goods.FindRows(SearchParameters);
				
				If SelectionByOrdersOrders Then
				
					If FoundRows.Count() > 0 Then
						TabRow = FoundRows[0];
						TabRow.PackagingQuantityInTheNote = TabRow.PackagingQuantityInTheNote + ShippedLine.Count
																* (TabRow.PackagingQuantityInTheNote / TabRow.Count);
						TabRow.NoteQuantity = TabRow.NoteQuantity + ShippedLine.Count;
					Else
						TabRow = Goods.Add();
						FillPropertyValues(TabRow, ShippedLine);
						TabRow.NoteQuantity = ShippedLine.Count;
						TabRow.PackagingQuantityInTheNote = ShippedLine.Count;
					EndIf;
					
				ElsIf ShippedLine.AdvancedWarehousingOnShipment Then
					
					If FoundRows.Count() > 0 Then
						TabRow = FoundRows[0];
						TabRow.NumberOfPackages = TabRow.NumberOfPackages + ShippedLine.Count
														* (TabRow.NumberOfPackages / TabRow.Count);
						TabRow.Count = TabRow.Count + ShippedLine.Count;
						
						PriceManagementSystem.RecalculateAmountsInRow(
							TabRow, 
							True,
							False,
							True,
							SelectionData_.PriceIncludesVAT);
						
						RowsToProcess.Add(TabRow);

					Else
						TabRow = Goods.Add();
						FillPropertyValues(TabRow, ShippedLine);
						TabRow.Count = ShippedLine.Count;
						TabRow.NumberOfPackages = ShippedLine.Count;
					EndIf;
					
				EndIf;
				
			EndIf;
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Goods,
			CachedValues);
		
	EndIf;
	
EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Status,BusinessOperation,Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.CustomerInvoice";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	ImplementationOfLocalAccounting = Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
	SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(Object.BusinessOperation);
	ImplementationOfTransferOfOwnership = Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	If SalesViaCommissionAgent
		Or ImplementationOfTransferOfOwnership Then
		
		SeriesSpecificationParameters.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse",
																New Structure());
		SeriesSpecificationParameters.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse",
																New Structure());
			
	Else
		SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	EndIf;
	
	If ImplementationOfLocalAccounting Then
		SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	EndIf;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = ImplementationOfLocalAccounting
															Or ImplementationOfTransferOfOwnership;
	SeriesSpecificationParameters.ShipmentPlanning = Object.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment;
	SeriesSpecificationParameters.SelectionPlanning = Object.Status = Enums.StatusesOfCustomerInvoices.Shipped
										Or Object.Status = Enums.StatusesOfCustomerInvoices.InTransit;
	SeriesSpecificationParameters.FactOfSelection = Object.Status = Enums.StatusesOfCustomerInvoices.Shipped
										Or Object.Status = Enums.StatusesOfCustomerInvoices.InTransit;
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters);
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_SalesOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_RowCode");
	
	SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef, Undefined - a link to an order for performing a warehouse operation.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	If FieldValuesToIdentifyReferences.Goods_RowCode <> 0 Then 
		Return FieldValuesToIdentifyReferences.Goods_SalesOrder;
	Else
		Return Undefined;
	EndIf;
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array of String - array of names.
Function NamesOfIncomingDocuments() Export
	
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Bảng kê hàng bán của người nhận ký gửi';
							|ru = 'Отчет комиссионера';
							|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
							|it = 'Report del commissionario';
							|pl = 'Raport komisanta';
							|tr = 'Konsinye raporu'"));
	CustomerInvoiceLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames;
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CustomerInvoice, DocumentRef.CustomerInvoice, FormDataStructure - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	If TypeOf(Object) = Type("DocumentObject.CustomerInvoice")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.CustomerInvoice") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Organization,Contract,Warehouse,Date,LineOfBusiness,BusinessOperation, Department");
	EndIf;
	
	FillParameters.Organization = ObjectData.Organization;
	FillParameters.Date = ObjectData.Date;
	FillParameters.Warehouse = ObjectData.Warehouse;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
	FillParameters.Department = ObjectData.Department;
	
	If ObjectData.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or ObjectData.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or ObjectData.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or ObjectData.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or ObjectData.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
	
	ElsIf ObjectData.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then 
		
		FillParameters.GoodsSales = True;
		
	ElsIf ObjectData.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData,
			"BusinessOperation,
			|OrderSales,
			|Ref,
			|Contract,
			|SalesOrder,
			|Goods");
		
		BusinessOperation = StructureFillingData.BusinessOperation;
		OrderSales   = StructureFillingData.OrderSales;
		Contract               = StructureFillingData.Contract;
		ThereAreAdjustingEntries     = False;
		SalesServer.CheckForAdjustments(StructureFillingData.Ref, StructureFillingData.Ref, ThereAreAdjustingEntries);
		SalesOrder = StructureFillingData.SalesOrder;
		Goods = StructureFillingData.Goods;
		
	ElsIf FillingData = Undefined Then
		
		BusinessOperation = Undefined;
		OrderSales   = False;
		ThereAreAdjustingEntries     = False;
		Contract               = Undefined;
		SalesOrder = Undefined;
		Goods = Undefined;
		
	Else
		
		BusinessOperation = FillingData.BusinessOperation;
		OrderSales   = FillingData.OrderSales;
		Contract               = FillingData.Contract;
		ThereAreAdjustingEntries     = False;
		SalesServer.CheckForAdjustments(FillingData.Ref, FillingData.Ref, ThereAreAdjustingEntries);
		SalesOrder = FillingData.SalesOrder;
		Goods = FillingData.Goods;
		
	EndIf;
	
	SettlementParameters = New Array;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                    = True;
	ParametersStructure.PaymentType_                          = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesPaymentPlan                   = BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomerLocalAccounting")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit");
	ParametersStructure.ModifiesDeliveryShipmentPlan         = True;
	
	ParametersStructure.ARAPCurrency                 = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                  = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage            = "Object.AmountARAPByPackage";
	
	ParametersStructure.CourseNumerator                        = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                      = "Object.CourseDenominator";
	
	ParametersStructure.PathToTSData                        = "Object.Goods";
	ParametersStructure.PropsNameTSOrder                  = "SalesOrder";
	
	ParametersStructure.PathToTSDataPaymentDecryption      = "Object.ARAPDetails";
	
	ParametersStructure.Manager                             = "Object.Manager";
	ParametersStructure.OrderBase                       = "Object.SalesOrder";
	ParametersStructure.PaymentSchedule                         = "Object.PaymentSchedule";
	
	AllowManualEditingOfChart = False;
	
	If TypeOf(OrderSales) = Type("Boolean")
		And OrderSales Then
		
		BasisDocuments = New Array;
		
		If ValueIsFilled(SalesOrder) Then
			BasisDocuments.Add(SalesOrder);
		Else
			
			CommonClientServer.SupplementArray(BasisDocuments,
				Goods.Unload().UnloadColumn("SalesOrder"),
				True);
			
		EndIf;
		
		DocumentsByType = SalesServer.DocumentsBasedOnAvailabilityOfSettlementObjects(BasisDocuments);
		AllowManualEditingOfChart = DocumentsByType.DocumentsWithoutCalculationObjects.Count() > 0;
		
	EndIf;
	
	If AllowManualEditingOfChart Then
		ParametersStructure.InvoiceForOrders = "";
	Else
		ParametersStructure.InvoiceForOrders = "Object.OrderSales";
	EndIf;
	
	SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(BusinessOperation);
	ConductARAPAccountingThroughEndCustomers = False;
	
	If SalesViaCommissionAgent Then
		ParametersStructure.Contract = "Object.CustomerContract";
		If ValueIsFilled(Contract) Then
			ConductARAPAccountingThroughEndCustomers = Common.ObjectAttributeValue(Contract, "ConductARAPAccountingThroughEndCustomers");
		EndIf;
		If ConductARAPAccountingThroughEndCustomers Then
			ParametersStructure.Partner = "Object.CustomerPartner";
			ParametersStructure.Counterparty = "Object.CustomerCounterparty";
		EndIf;
		ParametersStructure.CommissionAgentSAgreement = "Object.Contract";
		ParametersStructure.IncomingDocumentNumber = "Object.ConsigneeNumber";
		ParametersStructure.IncomingDocumentDate = "Object.ConsigneeDate";
		ParametersStructure.SourceDocumentName = "Object.ConsigneeDocumentName";
	EndIf;
	
	ParametersStructure.FormItems.LabelCurrencies                    = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages                     = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement                      = "PaymentSettlement";
	ParametersStructure.FormItems.AmountOfTSSettlements            = "GoodsAmountARAP";
	ParametersStructure.FormItems.DebtLimitationText    = "DecorationDebtLimitation";
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly   = ThereAreAdjustingEntries;
	ParametersStructure.DocumentCurrencyViewOnly        = Not UserRightsCached.VarianceFromSalesTermsAndConditions() And OrderSales;
	ParametersStructure.MutualSettlementsCurrencyViewOnly   = Not UserRightsCached.VarianceFromSalesTermsAndConditions() And OrderSales;
	ParametersStructure.DonTShowCalculations                  = BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	
	ParametersStructure.PathToTSDataPaymentSteps             = "Object.PaymentScheduleSteps";
	If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then 
		ParametersStructure.DateOfTransferOfTitleToGoods   = "Object.Date";
	Else
		ParametersStructure.DateOfTransferOfTitleToGoods   = "Object.DateOfTransferOfTitleToGoods";
	EndIf;
	ParametersStructure.PaymentStepsText                   = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart           = True;
	ParametersStructure.DocumentAmountForm                  = "Form.AmountTotal";
	ParametersStructure.AmountOfDepositForContainerForm               = "Form.PackageDepositValue";
	ParametersStructure.PaymentStagesViewOnly            = Not (UserRightsCached.VarianceFromSalesTermsAndConditions() Or Not OrderSales);
	ParametersStructure.InvoiceForSeveralOrdersIsPossible = GetFunctionalOption("UseSaleByMultipleOrders");
	ParametersStructure.ThereIsDateOfTransferOfOwnership =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0")
			And (BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
				Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		Or GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5")
			And BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
	ParametersStructure.ConductARAPAccountingThroughEndCustomers = ConductARAPAccountingThroughEndCustomers;
	ParametersStructure.ThisIsTransferOfOwnership2_5 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5")
			And BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	ParametersStructure.ARAPObject                       = "Object.Goods.ARAPObject";
	ParametersStructure.ToReturnReusablePackage            = "Object.ToReturnReusablePackage";
	ParametersStructure.PackageDepositIsRequired                 = "Object.PackageDepositIsRequired";
	
	ParametersStructure.TSP                                  = "Object.Warehouse";
	SettlementParameters.Add(ParametersStructure);
	
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		
		ParametersStructure.PaymentType_                = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.Organization                = Catalogs.Companies.ManagementCompany;
		ParametersStructure.SourceOfAmountsTabularPart = True;
		ParametersStructure.ThisIsSalePurchase          = True;
		ParametersStructure.ARAPCurrency       = "Object.ARAPCurrency";
		ParametersStructure.AmountARAP        = "Object.AmountARAP";
		ParametersStructure.CourseNumerator              = "Object.CourseNumerator";
		ParametersStructure.CourseDenominator            = "Object.CourseDenominator";
		ParametersStructure.PathToTSData              = "Object.Goods";
		ParametersStructure.ARAPObject             = "Object.ObjectOfManCalculations";
		ParametersStructure.Contract                    = "";
		ParametersStructure.Manager                   = "Object.Manager";
		ParametersStructure.TSP                        = "Object.Warehouse";
		
		SettlementParameters.Add(ParametersStructure);
		
	EndIf;
	
	Return SettlementParameters;
	
EndFunction

// Returns the query text for the temporary table of vttables
// 
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//
// Returns:
//	String - 
//
Function QueryTextTTTableInventoryTypesDecorator(Query, QueryTexts, DocumentObject) Export

	Return QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	
EndFunction 

// Returns the query text for the temporary table in the course of the currency
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
// 
// Returns:
//	String - 
//
Function RequestTextTTExchangeRatesDecorator(Query, QueryTexts, DocumentObject) Export
	
	Return QueryTextTTExchangeRates(Query, QueryTexts, DocumentObject);
	
EndFunction 

// Generates a formatted string to go to the list of implementations from the document log forms
//
// Parameters:
//  Parameters - Structure 
// 
// Returns:
// 	FormattedString 
//
Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.CustomerInvoice) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Giao hàng và cung cấp dịch vụ';
						|ru = 'Реализации товаров и услуг';
						|en = 'Customer invoice'; fa = 'فاکتور مشتری';
						|it = 'Vendite di merci e servizi';
						|pl = 'Sprzedaż towarów i usług';
						|tr = 'Mal ve hizmet satışı'");
	
	Return New FormattedString(HyperlinkText,,,,"Document.CustomerInvoice.Form.ListForm");
	
EndFunction

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.CustomerInvoice - The object of the document for which you want to get the text of the base.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	BaseStructure = BaseStructure(Object, Object.ARAPObjectSettings);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		If ValueIsFilled(BaseStructure.Basis) Then
			BaseStructure.Basis = BaseStructure.Basis + ", " + NStr("vi = 'Chuyển đi ký gửi';
																	|ru = 'Передача на комиссию';
																	|en = 'Consignment sales'; fa = 'فروش امانی';
																	|it = 'Trasferimento in conto vendita';
																	|pl = 'Przekazanie do komisu';
																	|tr = 'Konsinye satış'", Common.DefaultLanguageCode());
		Else
			BaseStructure.Basis = NStr("vi = 'Chuyển đi ký gửi';
										|ru = 'Передача на комиссию';
										|en = 'Consignment sales'; fa = 'فروش امانی';
										|it = 'Trasferimento in conto vendita';
										|pl = 'Przekazanie do komisu';
										|tr = 'Konsinye satış'", Common.DefaultLanguageCode());
		EndIf;
	EndIf;
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.CustomerInvoice - The document object for which you want to get the selection list.
//
// Returns:
//	ValueTable - A table of values with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	ThisIsTransferToCommission = (Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(Object.BusinessOperation);
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	If SalesViaCommissionAgent Then
		AddedRow = TableOfBases_.Add();
		AddedRow.Basis = NStr("vi = 'Bán hàng';
								|ru = 'Реализация';
								|en = 'Sales'; fa = 'فروش';
								|it = 'Vendita';
								|pl = 'Realizacja';
								|tr = 'Satış'");
		Return TableOfBases_;
	EndIf;
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByCounterpartyContracts);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis + ?(ThisIsTransferToCommission, ", " + NStr("ru = 'передача на комиссию';
																						|vi = 'consignment sales';
																						|en = 'consignment sales'; fa = 'consignment sales';
																						|it = 'consignment sales';
																						|pl = 'consignment sales';
																						|tr = 'konsinye satış'"), "");
		
		If ValueIsFilled(BaseStructure.ReferenceDocumentDateForPrintForms) And ValueIsFilled(BaseStructure.BaseDocumentNumber) Then
			ExtendedText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 số %2 ngày %3';
						|ru = '%1 № %2 от %3';
						|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
						|it = '%1 № %2 dal %3';
						|pl = '%1 nr %2 z dnia %3.';
						|tr = '%2sayılı %3tarihli %1'"),
					BaseStructure.Basis, BaseStructure.BaseDocumentNumber, Format(BaseStructure.ReferenceDocumentDateForPrintForms, "DLF=DD"));
			ExtendedText = ExtendedText + ?(ThisIsTransferToCommission, ", " + NStr("vi = 'Chuyển đi ký gửi';
																					|ru = 'передача на комиссию';
																					|en = 'consignment sales'; fa = 'consignment sales';
																					|it = 'trasferimento in conto vendita';
																					|pl = 'przekazanie do komisu';
																					|tr = 'konsinye satış'"), "");
			AddedRow = TableOfBases_.Add();
			FillPropertyValues(AddedRow, BaseStructure);
			AddedRow.Basis = ExtendedText;
		EndIf;
		
	EndIf;
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByOrders);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis + ?(ThisIsTransferToCommission, ", " + NStr("ru = 'передача на комиссию';
																						|vi = 'consignment sales';
																						|en = 'consignment sales'; fa = 'consignment sales';
																						|it = 'consignment sales';
																						|pl = 'consignment sales';
																						|tr = 'konsinye satış'"), "");
	EndIf;
	
	If ThisIsTransferToCommission And TableOfBases_.Count()=0 Then
		AddedRow = TableOfBases_.Add();
		AddedRow.Basis = NStr("ru = 'передача на комиссию';
								|vi = 'consignment sales';
								|en = 'consignment sales'; fa = 'consignment sales';
								|it = 'consignment sales';
								|pl = 'consignment sales';
								|tr = 'konsinye satış'");
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

#EndRegion

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CustomerInvoiceLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CustomerInvoiceLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse AS Warehouse,
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.Count AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse AS Warehouse,
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|GROUP BY
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|				WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|					THEN 14
	|				ELSE 13
	|			END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|				WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|					THEN 10
	|				ELSE 9
	|			END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|		AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|		AND &SelectionPlanning
	|			THEN CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|					THEN CASE
	|						WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|						AND ProductsToRequest.Count > 0
	|							THEN 6
	|						ELSE 5
	|					END
	|				ELSE CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|					AND ProductsToRequest.Count > 0
	|						THEN 8
	|					ELSE 7
	|				END
	|			END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|		AND NOT (Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|		AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue)
	|		AND &FactOfSelection
	|		AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentToCustomer
	|			THEN CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|					THEN CASE
	|						WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|						AND ProductsToRequest.Count > 0
	|							THEN 4
	|						ELSE 3
	|					END
	|				ELSE CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|					AND ProductsToRequest.Count > 0
	|						THEN 2
	|					ELSE 1
	|				END
	|			END
	|		ELSE 0
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|			WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|				THEN CASE
	|					WHEN &DocumentOperation_ IN (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|								AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|							OR &DocumentOperation_ = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|								AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer
	|						THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 18
	|							ELSE 17
	|						END
	|					ELSE 0
	|				END
	|			ELSE 0
	|		END
	|	END AS BatchesIndicationStatusOfGoodsTransferred
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
	|			AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|		AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		AND Goods.Purpose = ProductsToRequest.Purpose
	|		AND Goods.Warehouse = ProductsToRequest.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#Region StatusChangeChecks

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status)                  AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                    AS StatusMatches,
	|	DocumentsTable.Posted               AS Posted,
	|	DocumentsTable.DeletionMark        AS DeletionMark,
	|	TRUE                                   AS Recording,
	|	DocumentsTable.OrderSales    AS OrderSales,
	|	CASE
	|		WHEN DocumentsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting) THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                    AS ThisIsClientImplementationOfLocalAccounting,
	|	CASE
	|		WHEN DocumentsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                    AS ThisIsTransferToCommission,
	|	CASE
	|		WHEN DocumentsTable.BusinessOperation IN 
	|				(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|				 VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)) THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                             AS ThisIsImplementationWithNoTransferOfOwnership,
	|	DocumentsTable.Date                            AS Date,
	|	CASE
	|		WHEN AvailabilityOfAdjustments.DocumentBasis IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END 									 AS ThereAreAdjustingEntries,
	|	&UseCreditNotes 	 AS UseCreditNotes,
	|	DocumentsTable.DateOfTransferOfTitleToGoods  AS DateOfTransferOfTitleToGoods,
	|	DocumentsTable.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	Document.CustomerInvoice AS DocumentsTable
	|		LEFT JOIN (SELECT DISTINCT
	|			DocumentData.DocumentBasis AS DocumentBasis
	|		FROM
	|			Document.SaleAdjustment AS DocumentData
	|		WHERE
	|			DocumentData.DocumentBasis IN(&DocumentsArray)
	|			AND DocumentData.Posted) AS AvailabilityOfAdjustments
	|		ON DocumentsTable.Ref = AvailabilityOfAdjustments.DocumentBasis
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("UseCreditNotes", GetFunctionalOption("UseCreditNotes"));
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Var DateOfTransferOfTitleToGoods;
	
	Cancel = False;
	
	MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices[NewStatus];
	
	If AdditionalParameters <> Undefined Then
		AdditionalParameters.Property("NewDate", DateOfTransferOfTitleToGoods);
	EndIf;
	
	If ValidationSample.ThisIsClientImplementationOfLocalAccounting Then
		
			ErrorText = NStr("vi = 'Trong chứng từ %Document% không đặt trạng thái ""%Status%"" vì để bán hàng với giao dịch ""Bán hàng theo kế toán pháp quy"" không áp dụng các trạng thái';
							|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. для реализаций с операцией ""Реализация по регл. учету"" статусы не применимы';
							|en = 'Status ""%Status%"" is not set for document %Document% because statuses are not available for the sales using transaction ""Sale in local accounting""'; fa = 'Status ""%Status%"" is not set for document %Document% because statuses are not available for the sales using transaction ""Sale in local accounting""';
							|it = 'Il documento %Document%ha lo stato ""%Status%"" non impostato, perché per l''operazione ""Vendita in base alla contabilità regolamentata"" gli stati non sono applicabili';
							|pl = 'Dokument %Document% nie ma ustawionego statusu ""%Status%"", ponieważ dla realizacji z operacją ""Realizacja według ewidencji reglam."" statusy nie są stosowane';
							|tr = '""%Document%"" belgesinin ""%Status%"" durumuna sahip değildir, çünkü durumlar ""Yerel muhasebe üzerine satış"" işlemi ile satışlar için geçerli değildir'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
		
	ElsIf MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
		
		If ValidationSample.OrderSales Then
			
			If ValidationSample.BusinessOperation =
				Enums.BusinessTransactions.TransferOfTitleToGoods Then
				
				ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"" vì chứng từ giao hàng được lập theo lệnh';
								|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. реализация оформлена по распоряжению';
								|en = 'Status ""%Status%"" is not set for the ""%Document%"" document as the sale is registered by a reference'; fa = 'Status ""%Status%"" is not set for the ""%Document%"" document as the sale is registered by a reference';
								|it = 'Status ""%Status%"" is not set for the ""%Document%"" document as the sale is registered by a reference';
								|pl = 'Status ""%Status%"" is not set for the ""%Document%"" document as the sale is registered by a reference';
								|tr = '""%Document%"" belgesi ""%Status%"" durumuna sahip değildir çünkü satış, siparişe göre düzenlenmiştir'");
			Else
				ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái %Status%"" vì chứng từ giao hàng được lập theo đơn hàng của khách';
								|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. реализация оформлена по заказу клиента';
								|en = 'Status ""%Status%"" is not set for document %Document% as sale is registered against the sales order'; fa = 'Status ""%Status%"" is not set for document %Document% as sale is registered against the sales order';
								|it = 'Il documento %Document%ha lo stato ""%Status%"" non impostato perché la vendita è formalizzata in base all''ordine del cliente';
								|pl = 'Dokument %Document% nie ma ustawionego statusu ""%Status%"" ponieważ realizację sporządozno na podstawie zamówienie';
								|tr = '""%Document%"" belgesi ""%Status%"" durumuna sahip değildir çünkü satış satış siparişine göre düzenlenmiştir'");
			EndIf;
			
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
			
		EndIf;
		
		If ValidationSample.ThisIsTransferToCommission Then
			
			ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"" vì đây là giao dịch chuyển giao ký gửi';
							|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. это передача на комиссию';
							|en = 'Status ""%Status%"" is not set for document %Document%. Reason: it is consignment sales'; fa = 'Status ""%Status%"" is not set for document %Document%. Reason: it is consignment sales';
							|it = 'Il documento %Document% ha lo stato ""%Status%"" non impostato, perché è un trasferimento in commissione';
							|pl = 'Dokument %Document% nie ma statusu ""%Status%"", ponieważ jest to przekazanie do komisu';
							|tr = '%Document% belgesi bir konsinye satış olduğu için ""%Status%"" statüsüne sahip değildir'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
			
		EndIf;
		
		If ValidationSample.ThereAreAdjustingEntries And ValidationSample.UseCreditNotes Then
			ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"" chưa được đặt, bởi vì trên cơ sở chứng từ, điều chỉnh việc thực hiện';
							|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. на основании документа введена корректировка реализации';
							|en = 'The %Document% document has no ""%Status%"" status set, because a sales adjustment has been registered for the document'; fa = 'The %Document% document has no ""%Status%"" status set, because a sales adjustment has been registered for the document';
							|it = 'Lo stato ""%Status%"" del documento %Document% non è impostato perché in base al documento è stata inserita una rettifica di vendita.';
							|pl = 'W dokumencie %Document% status ""%Status%"" nie jest ustawiony, ponieważ na podstawie dokumentu wprowadzono korektę realizacji';
							|tr = '""%Document%"" belgesi ""%Status%"" durumuna sahip değildir, çünkü belgeye dayalı olarak bir satış düzeltmesi girilmiştir'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
		EndIf;
		
	ElsIf MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices.InTransit
		And Not ValidationSample.ThisIsImplementationWithNoTransferOfOwnership Then
		
			ErrorText = NStr("vi = 'Chưa thiết lập trạng thái ""%Status%"" cho chứng từ %Document%, bởi vì trạng thái này chỉ được áp dụng
				|đối với giao hàng với giao dịch ""Giao hàng (hàng đi đường)""';
				|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. этот статус применим
				|только для реализаций с операцией ""Реализация (товары в пути)""';
				|en = 'Status ""%Status%"" is not set for document %Document% as this status applies only to sales 
				|using transaction ""Customer invoice — Goods-in-transit""'; fa = 'Status ""%Status%"" is not set for document %Document% as this status applies only to sales 
				|using transaction ""Customer invoice — Goods-in-transit""';
				|it = 'Il documento %Document%ha lo stato ""%Status%"" non impostato, perché questo stato è applicabile 
				| solo per le vendite con l''operazione ""Vendita (merce in transito)""';
				|pl = 'Dokument %Document% nie ma statusu ""%Status%"", ponieważ ten status można zastosować
				|tylko dla realizacji z operacją ""Realizacja (wiersze pozycji w drodze)""';
				|tr = '""%Document%"" belgesi ""%Status%"" durumuna sahip değildir, çünkü bu durum yalnızca
				| ""Satış (yoldaki ürünler)"" işlemi ile yapılan satışlar için geçerlidir'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);	
			
	ElsIf MeaningOfNewStatus = Enums.StatusesOfCustomerInvoices.Shipped
		And ValidationSample.ThisIsImplementationWithNoTransferOfOwnership
		And DateOfTransferOfTitleToGoods < BegOfDay(ValidationSample.Date) Then
		
			ErrorText =  NStr("vi = 'Đối với chứng từ %Document% chưa thiết lập ngày chuyển quyền sở hữu ""%TransitionDate%"", 
				|bởi vì ngày này không thể nhỏ hơn ngày chứng từ ""%Date%""';
				|ru = 'У документа %Document% не установлена дата перехода права собственности ""%TransitionDate%"", 
				|так как она не может быть меньше даты документа ""%Date%""';
				|en = 'Set date ""%TransitionDate%"" of transfer of title to goods in document %Document%. 
				|It cannot be earlier than date ""%Date%"" of the document'; fa = 'Set date ""%TransitionDate%"" of transfer of title to goods in document %Document%. 
				|It cannot be earlier than date ""%Date%"" of the document';
				|it = 'Il documento %Document% ha la data del passaggio di proprietà non impostata ""%TransitionDate%"", 
				| perché tale data non può essere precedente alla data del documento ""%Date%""';
				|pl = 'Dokument %Document% nie ma ustalonej daty przejścia prawa własności ""%TransitionDate%"", 
				|ponieważ ona nie może być mniejsza niz data dokumentu ""%Date%"".';
				|tr = '%Document% belgesinin mülkiyet devir tarihi ""%TransitionDate%"" belirtilmedi,
				| çünkü belgenin tarihinden ""%Date%"" daha önce olamaz'");
			ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
			ErrorText = StrReplace(ErrorText, "%TransitionDate%", Format(DateOfTransferOfTitleToGoods, "DLF=D"));
			ErrorText = StrReplace(ErrorText, "%Date%", Format(ValidationSample.Date, "DLF=D"));
			CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
			
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

// This function determines the details of the selected document.
//
// Parameters:
//	DocumentRef - DocumentRef - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.OrderSales AS OrderSales,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		Currency = Selection.Currency;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), Selection.BusinessOperation, Enums.BusinessTransactions.SaleToCustomer);
		ByOrder = Selection.OrderSales;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = Selection.AmountARAP;
		Rate = Selection.Rate;
		Repetition = Selection.Repetition;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		ByOrder = False;
		DocumentAmount = 0;
		AmountARAP = 0;
		Rate = 1;
		Repetition = 1;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("ByOrder", ByOrder);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	
	Return AttributesStructure1;

EndFunction

// This function checks the order document when creating an expense order
//
// Parameters:
//	ReferenceOrder - DocumentRef - Link to the order document
//	Warehouse - CatalogRef.Warehouses - Link to an item in the Warehouses reference list.
//
// Returns:
//	Structure - verification results:
//		* Cancel                      - Boolean - True if the checks passed with errors, otherwise-False
//		* ErrorText                - String - Must be filled in when Failure = True
//		* DateOfShipment               - Date - 
//		* GroupOfWarehousesAtYourDisposal - Boolean - A group of warehouses is selected at the disposal
//		* UseAdvancedWarehousing  - Boolean - The warehouse uses an order scheme.
//
Function PerformOrderChecks(ReferenceOrder, Warehouse) Export
		
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Operation", "");
	ReturnStructure.Insert("ErrorText", "");
	ReturnStructure.Insert("GroupOfWarehousesAtYourDisposal", False);
	ReturnStructure.Insert("DateOfShipment");
	ReturnStructure.Insert("UseAdvancedWarehousing");
	
	If Not ValueIsFilled(Common.ObjectAttributeValue(ReferenceOrder, "Warehouse")) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi"" trong chứng từ ""%ReferenceOrder%"". Không thể tạo phiếu.';
						|ru = 'Не заполнено поле ""Склад"" в документе ""%ReferenceOrder%"". Невозможно создать ордер.';
						|en = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.'; fa = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.';
						|it = 'Il campo ""Magazzino"" nel documento ""%ReferenceOrder%"" non è stato compilato. Impossibile creare un mandato.';
						|pl = 'Nie jest wypełnione pole ""Magazyn"" w dokumencie ""%ReferenceOrder%"". Nie można utworzyć zlecenia.';
						|tr = '""%ReferenceOrder%"" belgesindeki ""Ambar"" alanı doldurulmamış. Sipariş oluşturulamaz.'");
		ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
		ReturnStructure.ErrorText = ErrorText;
		ReturnStructure.Operation = "Cancel";
		
		Return ReturnStructure
		
	EndIf;
	
	WarehouseGroupStructure     = New Structure("IsFolder", "Warehouse.IsFolder");
	WarehouseGroupValue      = Common.ObjectAttributesValues(ReferenceOrder, WarehouseGroupStructure);
	GroupOfWarehousesAtYourDisposal = WarehouseGroupValue.IsFolder;
	
	ReturnStructure.GroupOfWarehousesAtYourDisposal = GroupOfWarehousesAtYourDisposal; 
	
	Attributes = New Structure("DateOfShipment, Warehouse, UseAdvancedWarehousing", "Date");
		 	
	If Not GroupOfWarehousesAtYourDisposal Then
		
		Attributes.Warehouse = "Warehouse";
		Attributes.UseAdvancedWarehousing ="
		|CASE
		|	WHEN ISNULL(Warehouse.UseWarehouseManagemantSystemForGoodsIssue, FALSE)
		|			AND DATE >= ISNULL(Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue, DATETIME(1,1,1))
		|		THEN TRUE
		|	ELSE FALSE
		|END";
		
		AttributesValues = Common.ObjectAttributesValues(ReferenceOrder, Attributes);
		UseAdvancedWarehousing = AttributesValues.UseAdvancedWarehousing;
		
		ReturnStructure.UseAdvancedWarehousing = UseAdvancedWarehousing;
		
		If UseAdvancedWarehousing Then
			
			Warehouse = AttributesValues.Warehouse;
			FillPropertyValues(ReturnStructure, AttributesValues, "DateOfShipment");
			
		Else
			
			ErrorText = NStr("vi = 'Đối với kho bãi ""%Warehouse%"" không cần lập phiếu xuất kho.
				|Chưa điền chứng từ.';
				|ru = 'Для склада ""%Warehouse%"" оформление расходных ордеров не требуется.
				|Заполнение документа не выполнено.';
				|en = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
				|The document is not completed.'; fa = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
				|The document is not completed.';
				|it = 'Per il magazzino, ""%Warehouse%"" non è richiesta la formalizzazione dei mandati di pagamento.
				|La compilazione del documento non è eseguita.';
				|pl = 'W przypadku magazynu ""%Warehouse%"" sporządzenie zleceń wydania nie jest wymagane.
				|Dokument nie został wypełniony.';
				|tr = '""%Warehouse%"" ambarı için herhangi bir ambar çıkış fişlerini düzenleme gerekmemektedir.
				| Belge tamamlanmamıştır.'");
			ReturnStructure.ErrorText = StrReplace(ErrorText, "%Warehouse%", String(AttributesValues.Warehouse));
			ReturnStructure.Operation = "Cancel";
			Return ReturnStructure;
			
		EndIf;	
	EndIf;
	
	Status = Common.ObjectAttributeValue(ReferenceOrder, "Status");
	
	If Status = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
		
		BusinessOperation = Common.ObjectAttributeValue(ReferenceOrder, "BusinessOperation");
		
		If BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
			
			ErrorText = NStr("vi = 'Lệnh ""%ReferenceOrder%"" đang có trạng thái ""%Status%"".
			|Chỉ cho phép nhập phiếu xuất kho trên cơ sở lệnh hiện tại với trạng thái ""Cần giao hàng"", ""Đang đi đường"" và ""Đã giao hàng"".';
			|ru = 'Распоряжение ""%ReferenceOrder%"" находится в статусе ""%Status%"".
			|Ввод расходного ордера на основании текущего распоряжения разрешен только в статусах ""К отгрузке"", ""В пути"" и ""Реализовано"".';
			|en = 'Reference ""%ReferenceOrder%"" is in status ""%Status%"".
			|You can enter a goods issue note based on the current reference only in status ""To ship"", ""In transit"", or ""Sold"".'; fa = 'Reference ""%ReferenceOrder%"" is in status ""%Status%"".
			|You can enter a goods issue note based on the current reference only in status ""To ship"", ""In transit"", or ""Sold"".';
			|it = 'La disposizione ""%ReferenceOrder%"" ha lo stato ""%Status%"". 
			|Inserimento del mandato di pagamento in base alla disposizione corrente è consentita solo per gli stati ""Per la spedizione"", ""In transito"" e ""Venduto"".';
			|pl = 'Zamówienie ""%ReferenceOrder%"" ma status ""%Status%"".
			|Wprowadzanie zlecenia wydania na podstawie bieżącego zamówienia jest dozwolone tylko w statusach ""Do wysłania"", ""W drodze"" i ""Zrealizowano"".';
			|tr = '""%ReferenceOrder%"" talimatı ""%Status%"" durumundadır.
			| Geçerli ambar çıkış fişi yalnızca ""Sevk edilecek"", ""Yolda"" ve ""Satıldı"" durumlarında girilebilir.'");
			
		Else
			
			ErrorText = NStr("vi = 'Lệnh ""%ReferenceOrder%"" đang có trạng thái ""%Status%"".
			|Chỉ cho phép nhập phiếu xuất kho trên cơ sở lệnh hiện tại với trạng thái ""Cần giao hàng"" và ""Đã giao hàng"".';
			|ru = 'Распоряжение ""%ReferenceOrder%"" находится в статусе ""%Status%"".
			|Ввод расходного ордера на основании текущего распоряжения разрешен только в статусах ""К отгрузке"" и ""Реализовано"".';
			|en = 'Reference ""%ReferenceOrder%"" is in status ""%Status%"".
			|You can enter a goods issue note based on the current reference only in status ""To ship"" or ""Sold"".'; fa = 'Reference ""%ReferenceOrder%"" is in status ""%Status%"".
			|You can enter a goods issue note based on the current reference only in status ""To ship"" or ""Sold"".';
			|it = 'La disposizione ""%ReferenceOrder%"" ha lo stato ""%Status%"". 
			| Inserimento del mandato di pagamento in base alla disposizione corrente è consentito solo per gli stati ""Per la spedizione"" e ""Venduto"".';
			|pl = 'Zamówienie ""%ReferenceOrder%"" ma status ""%Status%"".
			|Wprowadzanie zlecenia wydania na podstawie bieżącego zamówienia jest dozwolone tylko w statusach ""Do wysłania"" i ""Zrealizowane"".';
			|tr = '""%ReferenceOrder%"" talimatı ""%Status%"" durumundadır.
			| Geçerli ambar çıkış fişi yalnızca ""Sevk edilecek"" ve ""Satıldı"" durumlarında girilebilir.'");
			
		EndIf;
		ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
		ErrorText = StrReplace(ErrorText, "%Status%", String(Status));
		ReturnStructure.ErrorText = ErrorText;
		ReturnStructure.Operation = "Cancel";
		
		Return ReturnStructure
		
	EndIf;
	
	If GroupOfWarehousesAtYourDisposal Then
		If Not ValueIsFilled(Warehouse) Then
			WarehouseArray = Documents.GoodsIssueNote.OrderWarehousesDuringShipment(ReferenceOrder, Undefined);
			If WarehouseArray.Count() = 0 Then
				ErrorText = NStr("vi = 'Đối với các kho bãi của chứng từ ""%ReferenceOrder%"" không cần lập phiếu nhập kho.
										|Chưa điền chứng từ.';
										|ru = 'Для складов документа ""%ReferenceOrder%"" оформление приходных ордеров не требуется.
										|Заполнение документа не выполнено.';
										|en = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
										|The document is not populated.'; fa = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
										|The document is not populated.';
										|it = 'Per i magazzini del documento ""%ReferenceOrder%"" non è richiesta la formalizzazione dei reversali d’incasso.
										|La compilazione del documento non è eseguita.';
										|pl = 'W przypadku magazynów dokumentu ""%ReferenceOrder%"" sporządzenie zleceń wydania nie jest wymagane.
										|Dokument nie został wypełniony.';
										|tr = '""%ReferenceOrder%"" belgesindeki depolar için ambar giriş fişlerinin düzenlemesi gerekmemektedir.
										| Belge tamamlanmamıştır.'");
				ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
				ReturnStructure.ErrorText = ErrorText;
				ReturnStructure.Operation = "Cancel";
				Return ReturnStructure;
			ElsIf WarehouseArray.Count() = 1 Then
				Warehouse = WarehouseArray[0];
			Else
				ReturnStructure.Operation = "Return";
				Return ReturnStructure;
			EndIf;
		Else
			ReturnStructure.Operation = "Return";
			Return ReturnStructure;
		EndIf;
	EndIf;
	
	Return ReturnStructure
	
EndFunction

#Region DocumentFulfillmentStatus

// Initializes the status structure of the document
//
// Returns:
//   Structure - initialized document execution structure.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithCustomersTable", 1);
	StructureState.Insert("DisplayShipmentTables", 2);
	StructureState.Insert("DisplayDeliveryTables", 3);
	StructureState.Insert("ThisIsAnInvoice", True);
	StructureState.Insert("ThereAreSummaryShipmentIndicators", True);
	StructureState.Insert("NameTSGoodsShipment", "Goods");
	StructureState.Insert("RegisterNameShipmentOfServices", "ShipmentAndReturnReferences");
	StructureState.Insert("NameOfInvoiceForOrdersField", "OrderSales");
	StructureState.Insert("StructureOfAdditionalRequests", New Structure("TableScheduleOfPaymentByInvoice, QueryTextTTGoodsOrderInvoiceShipped",
	                                                                    QueryTextPaymentSchedule(), QueryTextTTGoodsOrderInvoiceShipped()));
	
	Return StructureState
	
EndFunction

#EndRegion

// Returns:
// 	Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	DocumentProcessingProcedure.NameOfFormElementIsSeparate = "GoodsWithAssignment";
	DocumentProcessingProcedure.NameOfGroupOfCommandElementsIsSeparate = "ProductsTeamGroupSeparately";
	DocumentProcessingProcedure.OrderDetailsName = "OrderSales";
	
	Return DocumentProcessingProcedure;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region VATAccounting

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.CustomerInvoice, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref					= Object.Ref;
	RegistrationParameters.Date					= Object.Date;
	RegistrationParameters.Organization			= Object.Organization;
	RegistrationParameters.Counterparty				= Object.Counterparty;
	RegistrationParameters.VATTaxation		= Object.VATTaxation;
	RegistrationParameters.SalesViaCommissionAgent =
		ConsignmentSalesServer.SalesViaCommissionAgent(Object.BusinessOperation);
	RegistrationParameters.TransferOfTitleToGoods = (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
	
	UseStatusesOfGoodsServicesSales = GetFunctionalOption("UseStatusesOfGoodsServicesSales");
	
	If (Not UseStatusesOfGoodsServicesSales) Or 
		 (UseStatusesOfGoodsServicesSales And 
		  Object.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
		
		If Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
			RegistrationParameters.TransferToCommissionAgent = True;
		Else
			RegistrationParameters.GoodsSales = True;
			RegistrationParameters.ImplementationOfWorksServices = True;
		EndIf;
	EndIf;
	Return RegistrationParameters;
	
EndFunction

// Initializes the parameters for registering notifications about the movement of tracked goods
//
// Parameters:
//  Object		- DocumentObject.CustomerInvoice, FormDataStructure	- the document to get parameters for.
//
// Returns:
// 	Structure - Structure of parameters with keys:
// 	     * Ref - DocumentRef - Link to the purchase document.
// 	     * Date - Date - Date of the sales document.
// 	     * Organization - CatalogRef.Companies - The organization in which the sale of goods is reflected.
// 	     * Counterparty - CatalogRef.Counterparties,
// 	                    Reference link.Organizations - Counterparty or buyer organization.
//       * Warehouse - CatalogRef.Warehouses -
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the sales document.
// 	     [Operation parameters]
// 	     * SaleToCountriesOfCustomsUnion - Boolean - A sign that the operation of moving goods to the country of the customs union is reflected.
//       * AccountingForTheRNPTIsMaintained - Boolean - Indicates that there are traceable products in the tabular part of the document
//
Function ParametersForRegisteringNotificationsAboutMovementOfTraceableGoods(Object) Export
	
	RegistrationParameters = New Structure;
	
	RegistrationParameters.Insert("Ref",	Object.Ref);
	RegistrationParameters.Insert("Date", Object.Date);
	RegistrationParameters.Insert("Organization", Object.Organization);
	RegistrationParameters.Insert("Counterparty",	Object.Counterparty);
	RegistrationParameters.Insert("Warehouse",	Object.Warehouse);	
	RegistrationParameters.Insert("VATTaxation", Object.VATTaxation);	
	RegistrationParameters.Insert("SaleToCountriesOfCustomsUnion", False);
	RegistrationParameters.Insert("AccountingForTheRNPTIsMaintained", False);
	RegistrationParameters.Insert("TransferOfTitleToGoods", (Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods));
	
	If ValueIsFilled(Object.Counterparty) Then
		CounterpartyDetailsValues = Common.ObjectAttributesValues(Object.Counterparty, "LegalEntityIndividual,RegistrationCountry.EEUMember");
		If CounterpartyDetailsValues.LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.LegalEntityNonResident") 
			And ValueIsFilled(CounterpartyDetailsValues.CountryOfRegistrationMemberOfEEU)
			And CounterpartyDetailsValues.CountryOfRegistrationMemberOfEEU Then		
			RegistrationParameters.SaleToCountriesOfCustomsUnion = True;
			If Object.Goods.FindRows(New Structure("AccountingForTheRNPTIsMaintained", True)).Count() Then
				RegistrationParameters.AccountingForTheRNPTIsMaintained = True;
			EndIf;
		EndIf;
	EndIf;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn.DescriptionOfBankingDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, SalesOrder, Manager";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	Parameters.FillInIf.ObjectFieldsAreEmpty = "SalesOrder";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Warehouse, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Warehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "IssuiedBy", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Warehouse, Manager";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "IssuiedBy";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Warehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "IssuiedByJobTitle", Parameters);
	
EndProcedure

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.VHFWarehouses = True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction
#Region Excisable_Items

// Returns an indication of the use of excisable items of own production in the document.
//
// Parameters:
//	DocumentObject - DocumentObject.CustomerInvoice, FormDataStructure - Document data.
//
// Returns:
//	Boolean - excisable items of own production are used.
//
Function ExcisableGoodsAreUsed(DocumentObject) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	Return ExciseTaxOfOperations().Find(DocumentObject.BusinessOperation) <> Undefined;
	
EndFunction

#EndRegion
#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.CustomerInvoice - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Status AS Status,
	|	ISNULL(DocumentData.Counterparty.RegistrationCountry.EEUMember, FALSE) AS CounterpartyMemberOfEAEU,
	|	DocumentData.DateOfTransferOfTitleToGoods AS DateOfTransferOfTitleToGoods,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.VATTaxation AS VATTaxation
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query = New Query;
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	QueryText = 
	"SELECT
	|	TableTypesOfStocks_.Ref AS Ref,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS AnalysisOfAccountingForProductsProducts,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SubjectToExcise AS SubjectToExcise,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.BusinessUnitProduction AS BusinessUnitProduction,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	CAST(TableTypesOfStocks_.ExciseTaxAmount * &ConversionRatioFromLocalToMan
	|		AS NUMBER(31,2)) AS ExciseAmountInCurrencyMgmt
	|INTO DocumentDataTableOfInventoryOwnerAttributes
	|FROM
	|	Document.CustomerInvoice.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|;
	|SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_
	|INTO TTCategoriesOfExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, (Products, Country) IN
	|		(SELECT
	|			T.AnalysisOfAccountingForProductsProducts AS Products,
	|			&RegistrationCountry AS Country
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS T)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|;
	|SELECT
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|				AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN &DateOfTransferOfTitleToGoods
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|				AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.AnalysisOfAccountingForProductsProducts AS Products,
	|	TableExciseCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|				AND &CounterpartyMemberOfEAEU
	|			THEN VALUE(Enum.KindsOfTransactionsWithExcisableGoods.EAEUExports)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|			THEN VALUE(Enum.KindsOfTransactionsWithExcisableGoods.Export)
	|		ELSE VALUE(Enum.KindsOfTransactionsWithExcisableGoods.SaleOfGoodsAndServices)
	|	END AS KindOfTransactionWithExcisableGoods,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE WHEN TableTypesOfStocks_.SubjectToExcise
	|		THEN ISNULL(TableExciseCategories.ConversionFactor_, 0) * TableTypesOfStocks_.Count
	|		ELSE 0
	|	END AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.ExciseTaxAmount     AS ExciseAmountInCurrencyLocal,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyMgmt  AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|		DocumentDataTableOfInventoryOwnerAttributes AS TableTypesOfStocks_
	|
	|		INNER JOIN TTCategoriesOfExcisableItems AS TableExciseCategories
	|		ON TableTypesOfStocks_.AnalysisOfAccountingForProductsProducts = TableExciseCategories.Products
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON &BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	&Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|	AND TableExciseCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|	AND (TableTypesOfStocks_.ExciseTaxAmount <> 0
	|		OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|		OR CASE WHEN TableTypesOfStocks_.SubjectToExcise
	|				THEN ISNULL(TableExciseCategories.ConversionFactor_, 0) * TableTypesOfStocks_.Count
	|			ELSE 0
	|			END <> 0)
	|";
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	
	If (Attributes.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or Attributes.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit) 
		And Attributes.Status = Enums.StatusesOfCustomerInvoices.Shipped Then
		RatePeriod = Attributes.DateOfTransferOfTitleToGoods;
	Else
		RatePeriod = Attributes.Period;
	EndIf;

	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);
	
	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.Text = QueryText;
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	
	Return Query.Execute();
	
EndFunction

#EndRegion
// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Giao hàng và cung cấp dịch vụ';
		|ru = 'Реализация товаров и услуг';
		|en = 'Customer invoice'; fa = 'فاکتور مشتری';
		|it = 'Realizzo di beni e servizi';
		|pl = 'Sprzedaż towarów i usług';
		|tr = 'Müşteri faturası'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("SaleRegistrationOption");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	If Data.SaleRegistrationOption = PredefinedValue("Enum.SalesRegistrationOptions.DeedOfTransfer") Then
		StandardProcessing = False;
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Biên bản chuyển giao quyền sở hữu %1 ngày %2';
				|ru = 'Акт на передачу прав %1 от %2';
				|en = 'Deed of transfer %1 dated %2'; fa = 'Deed of transfer %1 dated %2';
				|it = 'Atto del passaggio di diritti %1 del %2';
				|pl = 'Protokół przekazania uprawnień %1 z dnia %2';
				|tr = '%2 tarihli %1 yetki devir senedi'"),
			Data.Number,
			Data.Date);
	EndIf;
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "SELECT TOP 1
	|	ISNULL(DocumentDataProducts.SalesOrderIsOrderAsInvoice, UNDEFINED) AS ThisIsOrderAsInvoice
	|INTO DocumentDataProducts
	|FROM
	|	DocumentDataTableItems AS DocumentDataProducts
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Status                AS Status,
	|	DocumentData.Partner               AS Partner,
	|	DocumentData.Counterparty            AS Counterparty,
	|	DocumentData.CustomerPartner         AS CustomerPartner,
	|	DocumentData.CustomerCounterparty      AS CustomerCounterparty,
	|	DocumentData.CustomerContract         AS CustomerContract,
	|	DocumentData.CounterpartyMemberOfEAEU AS CounterpartyMemberOfEAEU,
	|	DocumentData.CounterpartyNotResident  AS CounterpartyNotResident,
	|	DocumentData.Date                  AS Period,
	|	DocumentData.DateOfTransferOfTitleToGoods   AS DateOfTransferOfTitleToGoods,
	|	DocumentData.SalesOrder          AS SalesOrder,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Department         AS Department,
	|	DocumentData.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.Warehouse                 AS Warehouse,
	|	DocumentData.ReferenceDate      AS ReferenceDate,
	|	DocumentData.PriceIncludesVAT       AS PriceIncludesVAT,
	|	DocumentData.ARAPCurrency  AS ARAPCurrency,
	|	DocumentData.OrderSales   AS CustomImplementation,
	|	DocumentData.Terms            AS Terms,
	|	DocumentData.PaymentMethod           AS PaymentMethod,
	|	DocumentData.Contract               AS Contract,
	|	DocumentData.ConductARAPAccountingThroughEndCustomers AS ConductARAPAccountingThroughEndCustomers,
	|	DocumentData.VATTaxation    AS VATTaxation,
	|	DocumentData.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	DocumentData.PackageDepositIsRequired      AS PackageDepositIsRequired,
	|	DocumentData.Manager                  AS Manager,
	|	DocumentData.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	DocumentData.SalesOpportunity                    AS SalesOpportunity,
	|	DocumentData.EnabledGoodsAssignmentInSalesOpportunity AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.ThisIsTransferToCommission  AS ThisIsTransferToCommission,
	|	DocumentData.AllowableAmountPayable AS AllowableAmountPayable,
	|	DocumentData.Number                  AS Number,
	|	DocumentData.DocumentAmount         AS DocumentAmount,
	|	DocumentData.Comment            AS Comment,
	|	DocumentData.DeletionMark        AS DeletionMark,
	|	DocumentData.Posted               AS Posted,
	|	DocumentData.Author                  AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.DeliveryIsRequired AS DeliveryIsRequired,
	|	DocumentData.DeliveryPlanning AS DeliveryPlanning,
	|	DocumentData.DeliveryMethod25 AS DeliveryMethod25,
	|	DocumentData.DeliveryPoint AS DeliveryPoint,
	|	DocumentData.DeliveryZone AS DeliveryZone,
	|	DocumentData.DeliveryToCarrier AS DeliveryToCarrier,
	|	DocumentData.CarrierPartner AS CarrierPartner,
	|	DocumentData.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	DocumentData.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting,
	|	ISNULL(DocumentDataProducts.ThisIsOrderAsInvoice, UNDEFINED) AS ThisIsOrderAsInvoice,
	|	DocumentData.LoyaltyProgram AS LoyaltyProgram,
	|	UNDEFINED AS AdjustmentPeriod_
	|
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|		LEFT JOIN DocumentDataProducts
	|		ON TRUE
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("LocalAccountingCurrency",           Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",               Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("Status",                                   ?(ValueIsFilled(Attributes.Status), Attributes.Status, Enums.StatusesOfCustomerInvoices.Shipped));
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("SalesAgainstSeveralOrders",            ?(Not ValueIsFilled(Attributes.SalesOrder), True, False));
	Query.SetParameter("BusinessOperation",                    ?(ValueIsFilled(Attributes.BusinessOperation), Attributes.BusinessOperation, Enums.BusinessTransactions.SaleToCustomer));
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAgentServiceSale",        GetFunctionalOption("UseAgentServiceSale"));
	Query.SetParameter("ListOfTypesWithUnitAnalytics",      SalesServer.TypesOfNomenclatureWithUnitAnalytics());
	
	EmptyOrderValue = EmptyOrderValues();
	Query.SetParameter("EmptyOrderValue", EmptyOrderValue);
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation",             ContractInformation);
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NumberForPrinting",                    ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("NewOnlineARAPAccounting",   GetFunctionalOption("NewOnlineARAPAccounting"));
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",  Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	Query.SetParameter("Partner",                          Attributes.Partner);
	Query.SetParameter("LoyaltyProgram",      Attributes.LoyaltyProgram);
	Query.SetParameter("CurrentDate",                      CurrentUniversalDate());
	Query.SetParameter("SalesViaCommissionAgent",      ConsignmentSalesServer.SalesViaCommissionAgent(Attributes.BusinessOperation));
	
	If ValueIsFilled(Attributes.Contract)
	 And (Attributes.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Attributes.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit) Then
		Query.SetParameter("AnalyticsPartnerInGoodsOnGo", AnalyticsPartnerInGoodsOnGo(Query));
	Else
		Query.SetParameter("AnalyticsPartnerInGoodsOnGo", True);
	EndIf;
	If Attributes.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
		Query.SetParameter("AccountingSectionCommissionItemInTransit", AccountingSectionCommissionItemInTransit(Query));
	Else
		Query.SetParameter("AccountingSectionCommissionItemInTransit", Undefined);
	EndIf;
	
	If Attributes.ThisIsOrderAsInvoice = Undefined Then
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	Else
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", Not Attributes.ThisIsOrderAsInvoice);
	EndIf;
	
	Query.SetParameter("TypesOfVATTaxationNonTaxable", VATAccountingERP.TypesOfVATTaxationNonTaxable());
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);

	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	UseExcisableGoods = False;
	RegistrationCountry = Catalogs.WorldCountries.EmptyRef();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
	If Attributes.CustomImplementation
		And Attributes.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		BasisDocuments = New Array;
		
		AttributesValues = Common.ObjectAttributesValues(DocumentRef, "SalesOrder, Goods");
		If ValueIsFilled(AttributesValues.SalesOrder) Then
			BasisDocuments.Add(AttributesValues.SalesOrder);
		Else
			
			CommonClientServer.SupplementArray(BasisDocuments,
				AttributesValues.Goods.Unload().UnloadColumn("SalesOrder"),
				True);
			
		EndIf;
		
		DocumentsByType = SalesServer.DocumentsBasedOnAvailabilityOfSettlementObjects(BasisDocuments);
		ThisIsTransferOfOwnershipWithoutOrder = DocumentsByType.DocumentsWithoutCalculationObjects.Count() > 0;
		ThisIsTransferOfOwnershipBasedOnShipment = DocumentsByType.DocumentsWithoutCalculationObjects.Count() = 1
			And TypeOf(DocumentsByType.DocumentsWithoutCalculationObjects.Get(0)) = Type("DocumentRef.GoodsShipmentToCustomer");
		
	Else
		
		ThisIsTransferOfOwnershipWithoutOrder = False;
		ThisIsTransferOfOwnershipBasedOnShipment = False;
		
	EndIf;
	
	Query.SetParameter("ThisIsTransferOfOwnershipWithoutOrder", ThisIsTransferOfOwnershipWithoutOrder);
	Query.SetParameter("ThisIsTransferOfOwnershipBasedOnShipment", ThisIsTransferOfOwnershipBasedOnShipment);
	
	If Attributes.DeliveryIsRequired Then
		
		OperationLevel = GoodsDelivery.LevelOfOperationOfDocument(DocumentRef, Attributes.DeliveryPlanning);
		Query.SetParameter("OperationLevel", OperationLevel);
		
	EndIf;
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests);
	QueryTextDocumentDataBatchTable(ListOfRequests);
	QueryTextDocumentDataTableAccumulationOfBonusPoints(ListOfRequests);
	QueryTextDocumentDataTableStagesOfPaymentSchedule(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = "SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Status AS Status,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.CustomerPartner AS CustomerPartner,
	|	DocumentData.Shipper AS Shipper,
	|	DocumentData.GoodsRecipient AS GoodsRecipient,
	|	DocumentData.CustomerCounterparty AS CustomerCounterparty,
	|	DocumentData.CustomerContract AS CustomerContract,
	|	ISNULL(DocumentData.Counterparty.RegistrationCountry.EEUMember, FALSE) AS CounterpartyMemberOfEAEU,
	|	CASE
	|		WHEN ISNULL(DocumentData.Counterparty.LegalEntityIndividual,
	|			VALUE(Enum.LegalEntityIndividual.EmptyRef)) = VALUE(Enum.LegalEntityIndividual.LegalEntityNonResident)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CounterpartyNotResident,
	|	DocumentData.Date AS Date,
	|	DocumentData.DateOfTransferOfTitleToGoods AS DateOfTransferOfTitleToGoods,
	|	DocumentData.SalesOrder AS SalesOrder,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Department AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Date AS ReferenceDate,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.OrderSales AS OrderSales,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Contract AS Contract,
	|	ISNULL(DocumentData.Contract.ConductARAPAccountingThroughEndCustomers, FALSE) AS
	|		ConductARAPAccountingThroughEndCustomers,
	|	DocumentData.DeliveryIsRequired AS DeliveryIsRequired,
	|	DocumentData.DeliveryPlanning AS DeliveryPlanning,
	|	DocumentData.DeliveryMethod25 AS DeliveryMethod25,
	|	DocumentData.DeliveryPoint AS DeliveryPoint,
	|	DocumentData.DeliveryZone AS DeliveryZone,
	|	DocumentData.DeliveryToCarrier AS DeliveryToCarrier,
	|	DocumentData.CarrierPartner AS CarrierPartner,
	|	DocumentData.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	DocumentData.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	DocumentData.PackageDepositIsRequired AS PackageDepositIsRequired,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.SalesOpportunity AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsTransferToCommission,
	|	ISNULL(DocumentData.Contract.AllowableAmountPayable, 0) AS AllowableAmountPayable,
	|	DocumentData.Number AS Number,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Author AS Author,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.AmountARAPByPackage AS AmountARAPByPackage,
	|	DocumentData.ObjectOfManCalculations AS ObjectOfManCalculations,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.ConsigneeNumber AS ConsigneeNumber,
	|	DocumentData.ConsigneeDate AS ConsigneeDate,
	|	DocumentData.ConsigneeDocumentName AS ConsigneeDocumentName
	|INTO DocumentDataHeader
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods = "SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.DeliveryLineCode AS DeliveryLineCode,
	|	GoodsTable.ManualDiscount AS ManualDiscount,
	|	GoodsTable.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	GoodsTable.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	GoodsTable.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	GoodsTable.ConnectionKey AS ConnectionKey,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	GoodsTable.SalesOrder AS SalesOrder,
	|	GoodsTable.DeliveryPeriodDays AS DeliveryPeriodDays,
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.SetAccountingDimension AS SetAccountingDimension,
	|	GoodsTable.FEACNCode AS FEACNCode,
	|	GoodsTable.ARAPObject AS ARAPObject,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
	|	GoodsTable.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
	|	GoodsTable.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
	|	GoodsTable.Products.ItemsType AS ProductsTypeOfProducts,
	|	GoodsTable.Products.TracedGoods AS ItemOfTraceableItem,
	|	GoodsTable.Products.Principal AS ItemPrincipal,
	|	GoodsTable.Products.UnitOfMeasure AS ProductsUnitOfMeasure,
	|	GoodsTable.SalesOrder.ThisIsOrderAsInvoice AS SalesOrderIsOrderAsInvoice,
	|	GoodsTable.SalesOrder.Purpose AS CustomerOrderAssignment,
	|	GoodsTable.Purpose.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
	|	GoodsTable.Purpose.VATActivityType AS PurposeOfVATSTaxationOfTypeOfActivity,
	|	GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue AS WarehouseUseOrderSchemeWhenShipping,
	|	GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue AS WarehouseStartDateOfOrderSchemeDuringShipment,
	|	GoodsTable.Characteristic.Principal AS CharacteristicOfPrincipal,
	|	GoodsTable.ItemsLocationAttributes.Purpose AS ItemsLocationAttributesAssignment,
	|	GoodsTable.ARAPObject.Partner AS ARAPObjectIsPartner,
	|	GoodsTable.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	GoodsTable.ARAPObject.Counterparty AS ARAPObjectCounterparty,
	|	GoodsTable.ARAPObject.Contract AS ARAPObjectContract,
	|	GoodsTable.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	GoodsTable.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier
	|INTO DocumentDataTableItems
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableGoods);
	
EndProcedure

Procedure QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests)
	
	QueryTextTableInventoryKinds =
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.Ref AS Ref,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Package AS Package,
	|	TableTypesOfStocks_.NumberOfPackages AS NumberOfPackages,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan AS VATAmountMan,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute.InventoryType AS RecipientSInventoryOwnerAttributeTypeOfInventory,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.FEACNCode AS FEACNCode,
	|	TableTypesOfStocks_.PartnerProducts AS PartnerProducts,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS AnalysisOfAccountingForProductsProducts,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS AnalysisOfAccountingProductsCharacteristics,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS InventoryLocationAttributeAnalysisBatch,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.TracedGoods AS
	|		InventoryLocationAttributeOfItemOfItemThatIsBeingTracked,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType AS
	|		InventoriedLocationAttributesItemTypeOfItem,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.UnitOfMeasure AS
	|		InventoryLocationAttributeOfItemOfUnitOfMeasurement,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS TypeOfInventoryOwnerAttributeOwnerOfItem,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryOwnerAttributeIsTypeOfInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS StockTypeCurrency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeInventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS InventoryOwnerAttributeSaleOfAnotherCompanySInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType AS InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.Currency AS OwnerSInventoryOwnersAttributeInventoryOwnersAttributesCurrency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Terms AS InventoryOwnerAttributeAgreement,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SubjectToExcise AS SubjectToExcise,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.BusinessUnitProduction AS BusinessUnitProduction,
	|	TableTypesOfStocks_.FEACNCode.Commodity AS HSCodeRawItem,
	|	TableTypesOfStocks_.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	TableTypesOfStocks_.ARAPObject.Contract AS ARAPObjectContract,
	|	TableTypesOfStocks_.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	TableTypesOfStocks_.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier,
	|	TableTypesOfStocks_.SetAccountingDimension.ProductsInSet AS AnalyticsOfSetAccountingSetItem,
	|	TableTypesOfStocks_.SetAccountingDimension.ItemVariantOfSet AS AnalyticsOfSetAccountingSetCharacteristics
	|INTO DocumentDataTableOfInventoryOwnerAttributes
	|FROM
	|	Document.CustomerInvoice.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableInventoryKinds);
	
EndProcedure

Procedure QueryTextDocumentDataBatchTable(ListOfRequests)
	
	QueryTextTableSetOfSeries = "SELECT
	|	SeriesTable.LineNumber AS LineNumber,
	|	SeriesTable.Ref AS Ref,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Purpose AS Purpose,
	|	SeriesTable.Warehouse AS Warehouse,
	|	SeriesTable.Purpose.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
	|	SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue AS WarehouseUseOrderSchemeWhenShipping,
	|	SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue AS WarehouseStartDateOfOrderSchemeDuringShipment
	|INTO DocumentDataBatchTable
	|FROM
	|	Document.CustomerInvoice.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	ListOfRequests.Add(QueryTextTableSetOfSeries);
	
EndProcedure

Procedure QueryTextDocumentDataTableAccumulationOfBonusPoints(ListOfRequests)
	
	QueryTextTableBonusPointAccrual = "SELECT
	|	TableAccrualOfBonusPoints.LineNumber AS LineNumber,
	|	TableAccrualOfBonusPoints.Ref AS Ref,
	|	TableAccrualOfBonusPoints.ConnectionKey AS ConnectionKey,
	|	TableAccrualOfBonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	TableAccrualOfBonusPoints.AccrualDate AS AccrualDate,
	|	TableAccrualOfBonusPoints.DateOfDeduction AS DateOfDeduction,
	|	TableAccrualOfBonusPoints.AmountOfBonusPoints AS AmountOfBonusPoints
	|INTO DocumentDataTableAccumulationOfBonusPoints
	|FROM
	|	Document.CustomerInvoice.BonusPointAccrual AS TableAccrualOfBonusPoints
	|WHERE
	|	TableAccrualOfBonusPoints.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	ListOfRequests.Add(QueryTextTableBonusPointAccrual);
	
EndProcedure

Procedure QueryTextDocumentDataTableStagesOfPaymentSchedule(ListOfRequests)

	QueryTextTablePaymentScheduleSteps = "SELECT
	|	TableStagesOfPaymentSchedule.LineNumber AS LineNumber,
	|	TableStagesOfPaymentSchedule.Ref AS Ref,
	|	TableStagesOfPaymentSchedule.OrderDocument AS OrderDocument,
	|	TableStagesOfPaymentSchedule.ExceedingOrder AS ExceedingOrder,
	|	TableStagesOfPaymentSchedule.PaymentOption AS PaymentOption,
	|	TableStagesOfPaymentSchedule.PaymentDate AS PaymentDate,
	|	TableStagesOfPaymentSchedule.Move AS Move,
	|	TableStagesOfPaymentSchedule.PaymentAmount AS PaymentAmount,
	|	TableStagesOfPaymentSchedule.PaymentPercentage AS PaymentPercentage,
	|	TableStagesOfPaymentSchedule.PackageDepositValue AS PackageDepositValue,
	|	TableStagesOfPaymentSchedule.PackageDepositPercentage AS PackageDepositPercentage,
	|	TableStagesOfPaymentSchedule.AmountARAP AS AmountARAP,
	|	TableStagesOfPaymentSchedule.AmountARAPByPackage AS AmountARAPByPackage,
	|	TableStagesOfPaymentSchedule.ARAPObject AS ARAPObject,
	|	TableStagesOfPaymentSchedule.CalculateFrom AS CalculateFrom,
	|	TableStagesOfPaymentSchedule.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier
	|INTO DocumentDataTableStagesOfPaymentSchedule
	|FROM
	|	Document.CustomerInvoice.PaymentScheduleSteps AS TableStagesOfPaymentSchedule
	|WHERE
	|	TableStagesOfPaymentSchedule.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTablePaymentScheduleSteps);

EndProcedure

Procedure QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests)

	QueryTextTableARAPDetails = "SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.Ref AS Ref,
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	PaymentDecryptionTable.ARAPObject.Object AS CalculationObjectObject,
	|	PaymentDecryptionTable.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.CustomerInvoice.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableARAPDetails);
	
EndProcedure

Function AnalyticsPartnerInGoodsOnGo(Query)
	
	AnalystRequest = New Query("
	|SELECT TOP 1
	|	TRUE AS DimensionPartner
	|FROM
	|	Document.CustomerInvoice AS SaleOfGoodsAndServices
	|	INNER JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|		ON RegisterRecords.Recorder = SaleOfGoodsAndServices.Ref
	|		AND RegisterRecords.Period = SaleOfGoodsAndServices.Date
	|		AND RegisterRecords.ItemsLocationAttributes.Partner = SaleOfGoodsAndServices.Partner
	|		AND RegisterRecords.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Partner)
	|		AND NOT RegisterRecords.CalculationOfCost
	|WHERE
	|	SaleOfGoodsAndServices.Ref = &Ref
	|	AND (SaleOfGoodsAndServices.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		OR SaleOfGoodsAndServices.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|");
	AnalystRequest.SetParameter("Ref", Query.Parameters.Ref);
	QueryResult = AnalystRequest.Execute();
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Accounting section of commission goods in transit.
// 
// Parameters:
//  Query - Query - request for initialization of data for conducting
// 
// Returns:
//  EnumRef.SectionsOfInventoryCostAccounting - Accounting section of commission goods in transit
Function AccountingSectionCommissionItemInTransit(Query)
	
	RequestSection = New Query("
	|SELECT TOP 1
	|	RegisterRecords.AccountingSection AS AccountingSection
	|FROM
	|	Document.CustomerInvoice AS SaleOfGoodsAndServices
	|	INNER JOIN AccumulationRegister.InventoryCost AS RegisterRecords
	|		ON RegisterRecords.Recorder = SaleOfGoodsAndServices.Ref
	|		AND RegisterRecords.Period = SaleOfGoodsAndServices.Date
	|		AND RegisterRecords.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND RegisterRecords.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND NOT RegisterRecords.CalculationOfCost
	|WHERE
	|	SaleOfGoodsAndServices.Ref = &Ref
	|	AND SaleOfGoodsAndServices.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|	AND SaleOfGoodsAndServices.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|");
	RequestSection.SetParameter("Ref", Query.Parameters.Ref);
	Selection = RequestSection.Execute().Select();
	If Selection.Next() Then
		AccountingSection = Selection.AccountingSection; // an outdated section for the Implementation Operation so that it does not differ from the Move Operation
	Else
		AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent;
	EndIf;
	
	Return AccountingSection;
	
EndFunction

Function QueryTextTTProductsOfOrganizations(Query, QueryTexts, DocumentObject) Export

	TableName = "TTProductsOfOrganizations";
		
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS ShipmentCompany,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeSaleOfAnotherCompanySInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeSaleOfAnotherCompanySInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeInventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeSaleOfAnotherCompanySInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory
	|		ELSE TableTypesOfStocks_.InventoryType
	|	END AS InventoryOwnerAttributeIsTypeOfInventory,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.PartnerProducts AS PartnerProducts,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS CostOfProductBatchID,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	CASE &BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		WHEN VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		WHEN VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|	END AS CorItemsLocationAttributes,
	|	CASE &BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|		WHEN VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END AS CorInventoryOwnerAttribute
	|INTO TTProductsOfOrganizations
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	(&Status <> VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	VALUE(Catalog.Companies.ManagementCompany),
	|	VALUE(Catalog.Companies.ManagementCompany),
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientSInventoryOwnerAttributeTypeOfInventory,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.Warehouse,
	|	TableTypesOfStocks_.CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.PartnerProducts,
	|	TableTypesOfStocks_.Count,
	|	TableTypesOfStocks_.QuantityByGBRN,
	|	TableTypesOfStocks_.AmountExcludingVATCompl,
	|	&BusinessOperation,
	|	CASE
	|		WHEN &ToReturnReusablePackage
	|				AND TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END,
	|	UNDEFINED,
	|	UNDEFINED
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)	
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, TableName);
			
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentObject) Export
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not ((DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment 
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent) 
			Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting)) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.Warehouse AS Warehouse,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	TTProductsOfOrganizations.PartnerProducts AS PartnerProducts,
	|	TTProductsOfOrganizations.Count AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN AS QuantityByGBRN,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation AS VATTaxation,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Terms AS Terms,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(&Period, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN TableTypesOfStocks_.QuantityByGBRN
	|		ELSE 0
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	&BusinessOperation AS BusinessOperation,
	|	&VATTaxation AS VATTaxation,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS CorItemsLocationAttributes
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	(TableTypesOfStocks_.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND NOT &ToReturnReusablePackage)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfConsignmentGoodsTransfer(Query, QueryTexts, Registers, DocumentObject)
	RegisterName = "DatesOfConsignmentGoodsTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	&Period AS TransferDate,
	|	InventoryKinds.AnalysisOfTransmittedProducts AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	&Terms AS Terms,
	|	&Organization AS Organization
	|FROM
	|	TTTableTypesOfStocks AS InventoryKinds
	|		LEFT JOIN InformationRegister.DatesOfConsignmentGoodsTransfer AS DatesOfConsignmentGoodsTransfer
	|		ON InventoryKinds.InventoryOwnerAttribute = DatesOfConsignmentGoodsTransfer.InventoryOwnerAttribute
	|			AND InventoryKinds.AnalysisOfTransmittedProducts = DatesOfConsignmentGoodsTransfer.ItemsLocationAttributes
	|			AND InventoryKinds.CCDNumber = DatesOfConsignmentGoodsTransfer.CCDNumber
	|			AND (DatesOfConsignmentGoodsTransfer.Terms = &Terms)
	|			AND (DatesOfConsignmentGoodsTransfer.Organization = &Organization)
	|WHERE
	|	(DatesOfConsignmentGoodsTransfer.TransferDate IS NULL 
	|			OR DatesOfConsignmentGoodsTransfer.TransferDate < &Period)
	|	AND (InventoryKinds.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR InventoryKinds.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND NOT &ToReturnReusablePackage)
	|
	|ORDER BY
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.AnalysisOfTransmittedProducts,
	|	InventoryKinds.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers, DocumentObject)
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment 
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent) Then
		Return "";
	EndIf; 

	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany AS CompanyOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryOwnerAttributeSaleOfAnotherCompanySInventory";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting)
			And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
		Return "";
	EndIf;
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                    AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.Currency                         AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                     AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products                   AS Products,
	|	TableTypesOfStocks_.Characteristic                 AS Characteristic,
	|	TableTypesOfStocks_.CommitteeProductAnalysis AS ItemsLocationAttributes,
	|	CASE
	|		WHEN NOT TermsOfPurchaseFromVendors.Ref IS NULL
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END                                             AS DocumentSales,
	|	TableTypesOfStocks_.CCDNumber                       AS CCDNumber,
	|	&Ref                                           AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperation                            AS BusinessOperation,
	|	TableTypesOfStocks_.Count                     AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &LocalAccountingCurrency
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END                                             AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END                                             AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END                                             AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count                     AS QuantityToRegister,
	|	TableTypesOfStocks_.QuantityByGBRN               AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &LocalAccountingCurrency
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END                                             AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.ARAPObjectIsUniqueIdentifier AS FinRecordID,
	|	&BusinessTransactionSetting                   AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN TTExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.Currency = ExchangeRates.Currency
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		ON TableTypesOfStocks_.InventoryOwnerAttributeAgreement = TermsOfPurchaseFromVendors.Ref
	|		AND TermsOfPurchaseFromVendors.SplitReportByDocuments
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (TableTypesOfStocks_.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT &ToReturnReusablePackage))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
                                          
Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers, DocumentObject)
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueriesArray = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
					And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
					And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
					And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped
				Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
					And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
					And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped)) Then

	QueryText =
	"SELECT
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|				AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN &DateOfTransferOfTitleToGoods
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|				AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	&Department AS Department,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			OR &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN 
	|				CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|					THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|					ELSE TableTypesOfStocks_.AnalysisOfTransmittedProductsWithoutAssignment
	|				END
	|		ELSE
	|				CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|					THEN TableTypesOfStocks_.ItemsLocationAttributes
	|					ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|				END
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.SetAccountingDimension AS SetAccountingDimension,
	|	TableTypesOfStocks_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableTypesOfStocks_.ARAPObjectLineOfBusiness AS CounterpartyLineOfBusiness,
	|	CASE
	|		WHEN &CustomImplementation
	|				AND &SalesAgainstSeveralOrders
	|			THEN TableTypesOfStocks_.SalesOrder
	|		WHEN &CustomImplementation
	|				AND NOT &SalesAgainstSeveralOrders
	|			THEN &SalesOrder
	|		ELSE &Ref
	|	END AS SalesOrder,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND NOT &BusinessOperation IN (VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
	|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 AND &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			THEN &AccountingSectionCommissionItemInTransit
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.InventoryType <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
	|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|		WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END AS AccountingSection,
	|	TableTypesOfStocks_.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	TableTypesOfStocks_.VATActivityType AS VATActivityType,
	|
	|	TableTypesOfStocks_.LineOfBusiness AS ProductLineOfBusiness,
	|	&Manager AS Manager,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END AS Cost,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 AND &CompanyManagementAccounting
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostMan,
	|
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS LocalCost,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS RevenueAmount,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS RevenueAmountExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS RevenueAmountExclVATLocal,
	|	TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATLocal AS RevenueAmountIncludingVATLocal,
	|	TableTypesOfStocks_.AmountOfManualManDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.AmountOfAutomaticManDiscount AS DiscountMarkupAmount,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	CASE WHEN &SalesViaCommissionAgent
	|		THEN &CustomerContract
	|		ELSE &Contract
	|	END AS Contract,
	|	&Terms AS Terms,
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountOfVATSettlements AS AmountExcludingVATInARAPCurrency,
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN UNDEFINED
	|		WHEN &ToReturnReusablePackage
	|				AND TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE TableTypesOfStocks_.VATRate
	|			WHEN &ExportVATRate THEN 
	|				CASE WHEN TableTypesOfStocks_.Commodity
	|					THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|				END
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END AS VATTaxation,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.BusinessTransactions.ConsignmentSale)
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	(TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OwnGoods)
	|			OR TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND NOT &ToReturnReusablePackage)";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
					And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
					And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
					And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
					And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then

	QueryText =
	"SELECT
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|				AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN &DateOfTransferOfTitleToGoods
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|				AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	&Department AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	GoodsTable.SetAccountingDimension AS SetAccountingDimension,
	|	GoodsTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	GoodsTable.ARAPObjectLineOfBusiness AS CounterpartyLineOfBusiness,
	|	CASE
	|		WHEN &CustomImplementation
	|				AND &SalesAgainstSeveralOrders
	|			THEN GoodsTable.SalesOrder
	|		WHEN &CustomImplementation
	|				AND NOT &SalesAgainstSeveralOrders
	|			THEN &SalesOrder
	|		ELSE &Ref
	|	END AS SalesOrder,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|			THEN VALUE(Enum.InventoryTypes.AgentService)
	|		WHEN GoodsTable.TracedGoods
	|			THEN GoodsTable.InventoryType
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
	|	GoodsTable.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	GoodsTable.VATActivityType AS VATActivityType,
	|	(CASE
	|		WHEN GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN &LineOfBusiness
	|		ELSE CatAssignments.LineOfBusiness END) AS ProductLineOfBusiness,
	|	&Manager,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|			THEN GoodsTable.AmountIncludingVATMan
	|		ELSE 0
	|	END AS Cost,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|			THEN GoodsTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		 AND &CompanyManagementAccounting
	|			THEN GoodsTable.AmountExcludingVATMan
	|		ELSE 0
	|	END AS CostMan,
	|
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|			THEN GoodsTable.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS LocalCost,
	|	GoodsTable.Count,
	|	GoodsTable.AmountIncludingVATMan,
	|	GoodsTable.AmountExcludingVATMan,
	|	GoodsTable.AmountExcludingVATCompl,
	|	GoodsTable.AmountExcludingVATCompl + GoodsTable.VATLocal,
	|	GoodsTable.AmountOfManualManDiscount,
	|	GoodsTable.AmountOfAutomaticManDiscount,
	|	GoodsTable.Warehouse,
	|	CASE WHEN &SalesViaCommissionAgent
	|		THEN &CustomerContract
	|		ELSE &Contract
	|	END AS Contract,
	|	&Terms,
	|	&ARAPCurrency,
	|	GoodsTable.AmountARAP,
	|	GoodsTable.AmountARAP - GoodsTable.AmountOfVATSettlements,
	|	&Currency,
	|	GoodsTable.AmountIncludingVAT,
	|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount,
	|	0 AS ExciseAmountInCurrencyLocal,
	|	0 AS ExciseAmountInCurrencyMgmt,
	|	CASE
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END,
	|	&BusinessOperation,
	|	GoodsTable.Products,
	|	GoodsTable.ARAPObject,
	|	
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	GoodsTable.VATRate AS VATRate,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_
	|	
	|FROM
	|	TTOperationServices AS GoodsTable
	|
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON GoodsTable.ItemsLocationAttributesAssignment = CatAssignments.Ref
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	SetRequestParameterVATTaxTypesTaxable(Query);
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
		
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers, DocumentObject)
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueriesArray = New Array;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.Organization AS Organization,
	|	&Department AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		ELSE TableTypesOfStocks_.AnalysisOfTransmittedProductsWithoutAssignment
	|	END AS CorItemsLocationAttributes,
	|	&Partner AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	&LineOfBusiness AS CorLineOfBusiness,
	|	TableTypesOfStocks_.InventoryType AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.Count AS CorQuantity,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ProductsTypeOfProducts IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ShipmentWithDeferredTransferOfTitle) AS BusinessOperation,
	|	TableTypesOfStocks_.Organization AS Organization,
	|	&Department AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		ELSE TableTypesOfStocks_.AnalysisOfTransmittedProductsWithoutAssignment
	|	END AS CorItemsLocationAttributes,
	|	&Partner AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	&LineOfBusiness AS CorLineOfBusiness,
	|	TableTypesOfStocks_.InventoryType AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.Count AS CorQuantity,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ProductsTypeOfProducts IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;

	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CASE
	|		WHEN &BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN &DateOfTransferOfTitleToGoods
	|		ELSE &Period
	|	END AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Purpose AS Purpose,
	|	CASE 
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT) 
	|				AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) 
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE GoodsTable.VATRate
	|			WHEN &ExportVATRate THEN 
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		ELSE &VATTaxation 
	|	END AS VATTaxation
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|WHERE
	|	GoodsTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ItemOfTraceableItem
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers, DocumentObject)
	RegisterName = "TransferredReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 	
	
	If Not (DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment 
			And DocumentObject.ToReturnReusablePackage) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf; 

	QueryText = 
	"SELECT
	|	TTTableTypesOfStocks.LineNumber        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	&Period                                 AS Period,
	|	TTTableTypesOfStocks.Products       AS Products,
	|	TTTableTypesOfStocks.Characteristic     AS Characteristic,
	|	TTTableTypesOfStocks.Count         AS Count,
	|	TTTableTypesOfStocks.QuantityByGBRN   AS QuantityByGBRN,
	|	TTTableTypesOfStocks.AmountIncludingVAT          AS Sum,
	|	TTTableTypesOfStocks.InventoryOwnerAttribute         AS InventoryOwnerAttribute,
	|	TTTableTypesOfStocks.CCDNumber           AS CCDNumber,
	|	&Partner                                AS Partner,
	|	&Ref                                 AS DocumentTransfers_,
	|	&PackageDepositIsRequired                   AS DepositIsRequired,
	|	
	|	CASE
	|		WHEN &PackageDepositIsRequired
	|			THEN &IDOfUnusedFinRecord
	|		ELSE TTTableTypesOfStocks.RowID
	|	END AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleOfTransferredReturnablePackaging) AS BusinessTransactionSetting 
	|	
	|FROM
	|	TTTableTypesOfStocks AS TTTableTypesOfStocks
	|WHERE
	|	TTTableTypesOfStocks.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomer
			And DocumentObject.BusinessOperation <>Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods)
			Or DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.Shipped Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	ToRegister.PrincipalProductAnalysis AS ItemsLocationAttributes,
	|	ToRegister.Terms AS Terms,
	|	ToRegister.Currency AS Currency,
	|	ToRegister.Count AS Count,
	|	ToRegister.AmountIncludingVAT * ExchangeRates.ConversionFactor_ AS RevenueAmount,
	|	ToRegister.VATAmount * ExchangeRates.ConversionFactor_ AS VATAmount,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	&Counterparty AS Customer,
	|	CASE
	|		WHEN NOT ToRegister.Terms = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|				AND ToRegister.Terms.SplitReportByDocuments
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS DocumentSales,
	|	&Ref AS DocumentSalesOfGoodsAndServices,
	|	
	|	ToRegister.ARAPObjectIsUniqueIdentifier AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	ToRegister.RowID AS RowID
	|FROM
	|	TTOperationServices AS ToRegister
	|		LEFT JOIN TTExchangeRates AS ExchangeRates
	|		ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	ToRegister.PrincipalProductAnalysis <> UNDEFINED";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	
	DoNotRecalculateVATAmounts = False;
	
	QueryTextdata_ = 
	"SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|
	|	GoodsTable.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS DocumentCurrency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Date AS VATBasePeriod,
	|	DocumentData.Date AS DateOfCourse,
	|
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.RowID AS RowID,
	|
	|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVAT,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	GoodsTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|	
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON GoodsTable.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN DocumentDataTableOfInventoryOwnerAttributes AS InventoryKinds
	|		ON GoodsTable.Ref = InventoryKinds.Ref
	|			AND GoodsTable.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND InventoryKinds.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	
	|	GoodsTable.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS DocumentCurrency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Date AS VATBasePeriod,
	|	DocumentData.Date AS DateOfCourse,
	|
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.RowID AS RowID,
	|
	|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVAT,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan,
	|	
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) 
	|			THEN FALSE
	|		WHEN GoodsTable.InventoriedLocationAttributesItemTypeOfItem = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND DocumentData.ToReturnReusablePackage
	|			AND NOT DocumentData.PackageDepositIsRequired
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	GoodsTable.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|	
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS GoodsTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON GoodsTable.Ref = DocumentData.Ref
	|WHERE
	|	GoodsTable.Ref IN (&Ref)";
	
	If DocumentObject = Undefined Then
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTableItems", "Document.CustomerInvoice.Goods");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTableOfInventoryOwnerAttributes", "Document.CustomerInvoice.InventoryKinds");
		QueryTextdata_ = StrReplace(QueryTextdata_, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
		QueryTextdata_ = StrReplace(QueryTextdata_, "GoodsTable.InventoriedLocationAttributesItemTypeOfItem", "GoodsTable.ItemsLocationAttributes.Products.ItemsType");
		QueryTextdata_ = StrReplace(QueryTextdata_, "GoodsTable.AnalysisOfAccountingForProductsProducts", "GoodsTable.ItemsLocationAttributes.Products");
	EndIf;
	
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_, DoNotRecalculateVATAmounts);
	
EndProcedure

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueriesArray = New Array;
	
	If DocumentObject = Undefined
		Or (DocumentObject.Status = Enums.StatusesOfCustomerInvoices.InTransit
			And DocumentObject.OrderSales) Then
		
		QueryText =
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	GoodsTable.SalesOrder AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.RowCode AS RowCode,
		|	CASE
		|		WHEN GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN GoodsTable.Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatus IN (10, 14)
		|			THEN GoodsTable.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped) AS Factor,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.AmountARAP AS Sum,
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS VATAmountMan
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.RowCode <> 0
		|	AND DocumentData.Status <> VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND DocumentData.OrderSales
		|	AND &TextOfOrderConditionAsInvoice";
		
		QueriesArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped
			And DocumentObject.OrderSales) Then
		
		QueryText =
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	GoodsTable.SalesOrder AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.RowCode AS RowCode,
		|	CASE
		|		WHEN GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN GoodsTable.Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatus IN (10, 14)
		|			THEN GoodsTable.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped) AS Factor,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.AmountARAP AS Sum,
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS VATAmountMan
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.RowCode <> 0
		|	AND DocumentData.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND DocumentData.OrderSales
		|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|	AND NOT ISNULL(GoodsTable.SalesOrderIsOrderAsInvoice,
		|	NOT &UseAdvancedFeaturesOfSalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	GoodsTable.SalesOrder AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.RowCode AS RowCode,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1) AS Factor,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.AmountARAP AS Sum,
		|	GoodsTable.VATAmount AS VATAmount,
		|	GoodsTable.VATAmountCompl AS VATAmountCompl,
		|	GoodsTable.VATAmountMan AS VATAmountMan
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.RowCode <> 0
		|	AND DocumentData.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND DocumentData.OrderSales
		|	AND &TextOfOrderConditionAsInvoice
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	GoodsTable.SalesOrder AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.RowCode AS RowCode,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered) AS Factor,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.AmountARAP AS Sum,
		|	GoodsTable.VATAmount AS VATAmount,
		|	GoodsTable.VATAmountCompl AS VATAmountCompl,
		|	GoodsTable.VATAmountMan AS VATAmountMan
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.RowCode <> 0
		|	AND DocumentData.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND DocumentData.OrderSales
		|	AND DocumentData.BusinessOperation NOT IN
		|		(VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
		|		VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|	AND NOT ISNULL(GoodsTable.SalesOrderIsOrderAsInvoice,
		|	NOT &UseAdvancedFeaturesOfSalesOrder)";
		
		QueriesArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.OrderSales Then
		
		QueryText =
		// 1. For a business of operation <>, the transfer of ownership over and above the order works as usual -
		// Registered Records of the order are added
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	GoodsTable.SalesOrder AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.RowCode AS RowCode,
		|	CASE
		|		WHEN TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
		|			THEN CASE
		|						WHEN GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|							VALUE(Enum.ItemsTypes.ReusablePackage))
		|							THEN GoodsTable.Warehouse
		|						ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|					END
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,
		|	CASE
		|		WHEN TableOfIndicators.Ref IN
		|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
		|			AND GoodsTable.BatchesIndicationStatus IN (10, 14)
		|			THEN GoodsTable.Series
		|		ELSE
		|			VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	TableOfIndicators.Ref AS Factor,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.AmountARAP AS Sum,
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS VATAmountMan
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
		|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
		|			
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|	AND GoodsTable.RowCode = 0
		|	AND DocumentData.OrderSales
		|	AND NOT ISNULL(GoodsTable.SalesOrderIsOrderAsInvoice,
		|	NOT &UseAdvancedFeaturesOfSalesOrder)
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	GoodsTable.SalesOrder AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.RowCode AS RowCode,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered) AS Factor,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.AmountARAP AS Sum,
		|	0 AS VATAmount,
		|	0 AS VATAmountCompl,
		|	0 AS VATAmountMan
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|			
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND DocumentData.BusinessOperation NOT IN
		|		(VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
		|		VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|	AND GoodsTable.RowCode = 0
		|	AND DocumentData.OrderSales
		|	AND NOT ISNULL(GoodsTable.SalesOrderIsOrderAsInvoice,
		|	NOT &UseAdvancedFeaturesOfSalesOrder)
		|
		|UNION ALL
		|
		// 2. For [business transaction] = [transfer of ownership rights] doesn't work over the order
		// - only Registered Records with the Completed indicator are added. So, because for the case of an over-order in
		// the transfer of ownership, you still need to add Registered Records with the Shipped indicator, which is completely wrong.
		// Therefore, for a two-way implementation in addition to the order, there may be a Shipment of goods to the customer in the document
		// (with the addition of Registered Record of the order), and in the End implementation, the addition of Registered Record with the indicator
		// Issued for [line code] = 0.
		|SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	DocumentData.Date AS Period,
		|	GoodsTable.SalesOrder AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.RowCode AS RowCode,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1) AS Factor,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.AmountARAP AS Sum,
		|	GoodsTable.VATAmount AS VATAmount,
		|	GoodsTable.VATAmountCompl AS VATAmountCompl,
		|	GoodsTable.VATAmountMan AS VATAmountMan
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|		ON DocumentData.Ref = GoodsTable.Ref
		|			
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|	AND GoodsTable.RowCode = 0
		|	AND DocumentData.OrderSales";
		
		QueriesArray.Add(QueryText);
		
	EndIf;
	
	If DocumentObject <> Undefined
		And QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = StrReplace(QueryText,
		"&TextOfOrderConditionAsInvoice",
		"CASE
		|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|		THEN TRUE
		|	ELSE NOT ISNULL(GoodsTable.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedFeaturesOfSalesOrder)
		|END");
	
	If ValueIsFilled(QueryText) Then
		
		QueryText = QueryText + "
		|
		|ORDER BY
		|	LineNumber,
		|	Factor";
		
	EndIf;
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.CustomerInvoice.Goods");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.CustomerInvoice");
		QueryText = StrReplace(QueryText, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
		QueryText = StrReplace(QueryText, "GoodsTable.SalesOrderIsOrderAsInvoice", "GoodsTable.SalesOrder.ThisIsOrderAsInvoice");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject)
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			And Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
				Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products                                AS Products,
	|	SeriesTable.Characteristic                              AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssigningTrafficToWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series                                       AS Series,
	|	SeriesTable.Count                                  AS Count,
	|	SeriesTable.Warehouse                                       AS Sender,
	|	&Partner                                                 AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)     AS Premise,
	|	VALUE(Enum.WarehouseTransactions.ShipmentToCustomer) AS WarehouseOperation,
	|	&Ref                                                  AS Document,
	|	&Period                                                  AS Period,
	|	CASE
	|		WHEN NOT SeriesTable.WarehouseUseOrderSchemeWhenShipping
	|				OR &Period < SeriesTable.WarehouseStartDateOfOrderSchemeDuringShipment 
	|			THEN TRUE
	|		ELSE FALSE 
	|	END AS ThisIsWarehouseRecord
	|FROM
	|	DocumentDataBatchTable AS SeriesTable
	|WHERE
	|	SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.AssigningTrafficToWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	GoodsTable.Warehouse,
	|	&Partner,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting)
	|		ELSE VALUE(Enum.WarehouseTransactions.ShipmentToCustomer)
	|	END,
	|	&Ref,
	|	&Period,
	|	CASE
	|		WHEN NOT GoodsTable.WarehouseUseOrderSchemeWhenShipping
	|				OR &Period < GoodsTable.WarehouseStartDateOfOrderSchemeDuringShipment
	|				OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseRecord
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON GoodsTable.Ref = DocumentData.Ref
	|WHERE
	|	GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction
Function QueryTextTableDocumentPostingInFinancialAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                        AS Period,
	|	&Organization                   AS Organization,
	|	BEGINOFPERIOD(&Period, DAY)   AS DateRecord,
	|	&BusinessOperation AS BusinessOperation
	|
	|UNION
	|
	|SELECT
	|	&Period                AS Period,
	|	&Organization           AS Organization,
	|	BEGINOFPERIOD(&DateOfTransferOfTitleToGoods, DAY) AS DateRecord,
	|	&BusinessOperation AS BusinessOperation
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|	AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Procedure SetRequestParameterTaxationOfOrganization(Query)
	
	If Query.Parameters.Property("TaxationOfOrganization") Then
		Return;
	EndIf;
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Catalogs.Companies.ManagementCompany, Query.Parameters.Period);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	SetRequestParameterTaxationOfOrganization(Query);
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.CustomerInvoice.Name,
		"Goods, InventoryKinds");
		
	LineNumberText = StrReplace(LineNumberText, "Document.CustomerInvoice.Goods",       "DocumentDataTableItems");
	LineNumberText = StrReplace(LineNumberText, "Document.CustomerInvoice.InventoryKinds",  "DocumentDataTableOfInventoryOwnerAttributes");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""Goods"" 								AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN ISNULL(DocumentTable.PurposeOfVATSTaxationOfTypeOfActivity, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentTable.PurposeOfVATSTaxationOfTypeOfActivity
	|	END                               	AS VATTaxation,
	|	CASE
	|		WHEN CatProducts.ItemsType IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               	AS AssetTaxClass,
	|	LineCodes.RowCode						AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	DocumentDataTableItems AS DocumentTable
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Goods""
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|
	|UNION ALL
	|SELECT
	|	""InventoryKinds"" 						AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN ISNULL(Dimension.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Dimension.Purpose.VATActivityType
	|		ELSE &TaxationOfOrganization
	|	END                               	AS VATTaxation,
	|	CASE
	|		WHEN CatProducts.ItemsType IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               	AS AssetTaxClass,
	|	LineCodes.RowCode						AS RowCode
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS DocumentTable
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Dimension.Ref = DocumentTable.ItemsLocationAttributes
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = Dimension.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTTableTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Undefined, DocumentObject);
	SetRequestParameterVATTaxTypesTaxable(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	SetParameterForPartnerAccountingAnalyticsRequest(Query);	
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	InventoryKinds.LineNumber                  AS LineNumber,
	|	InventoryKinds.Ref                       AS Ref,
	|	Dimension.StorageLocation					 AS Warehouse,
	|	Dimension.StorageLocation.ShopFloorStockroom  AS ShopFloorStockroom,
	|	InventoryKinds.SalesOrder                 AS SalesOrder,
	|	&Organization                             AS Organization,
	|	Dimension.Products                   AS Products,
	|	Dimension.Products.ItemsType   AS ProductsTypeOfProducts,
	|	InventoryKinds.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	InventoryKinds.RecipientInventoryOwnerAttribute         AS RecipientInventoryOwnerAttribute,
	|	InventoryKinds.RecipientSInventoryOwnerAttributeTypeOfInventory AS RecipientSInventoryOwnerAttributeTypeOfInventory,
	|	InventoryKinds.InventoryOwnerAttributeIsTypeOfInventory         AS InventoryType,
	|	InventoryKinds.StockTypeCurrency             AS Currency,
	|	InventoryKinds.InventoryOwnerAttributeSaleOfAnotherCompanySInventory 
	|		AS InventoryOwnerAttributeSaleOfAnotherCompanySInventory,
	|	InventoryKinds.InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany 
	|		AS InventoryOwnerAttributeInventoryOwnerAttributeOfOwnerCompany,
	|	InventoryKinds.InventoryOwnerAttributeInventoryOwnerAttribute AS InventoryOwnerAttributeInventoryOwnerAttribute,
	|	InventoryKinds.ARAPObjectIsUniqueIdentifier AS ARAPObjectIsUniqueIdentifier,
	|	InventoryKinds.InventoryOwnerAttributeAgreement  AS InventoryOwnerAttributeAgreement,
	|	InventoryKinds.OwnerSInventoryOwnersAttributeInventoryOwnersAttributesCurrency 
	|		AS OwnerSInventoryOwnersAttributeInventoryOwnersAttributesCurrency,
	|	InventoryKinds.InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory 
	|		AS InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory,
	|	Dimension.Characteristic                 AS Characteristic,
	|	InventoryKinds.Count                   AS Count,
	|	InventoryKinds.QuantityByGBRN             AS QuantityByGBRN,
	|	InventoryKinds.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	InventoryKinds.VATAmount                     AS VATAmount,
	|	InventoryKinds.VATRate                    AS VATRate,
	|	InventoryKinds.CCDNumber                     AS CCDNumber,
	|	InventoryKinds.CCDNumberCCDNumberType         AS CCDNumberCCDNumberType,
	|	InventoryKinds.FEACNCode                     AS FEACNCode,
	|	InventoryKinds.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey     AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.SetAccountingDimension        AS SetAccountingDimension,
	|	InventoryKinds.RowID          AS RowID,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	(CASE
	|		WHEN &AnalyticsPartnerInGoodsOnGo 
	|			THEN AnalysisOfTransmittedProducts.DimensionKey
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			THEN AnalysisOfTransmittedProductsContract.DimensionKey
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN AnalysisOfTransferredProductsEndCustomer.DimensionKey
	|		ELSE AnalysisOfTransmittedProducts.DimensionKey END) AS AnalysisOfTransmittedProducts,
	|	(CASE
	|		WHEN &AnalyticsPartnerInGoodsOnGo
	|			THEN AnalysisOfTransmittedProductsWithoutAssignment.DimensionKey
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			THEN AnalysisOfTransmittedProductsContractWithoutAssignment.DimensionKey
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN AnalysisOfTransferredProductsEndCustomerWithoutAssignment.DimensionKey
	|		ELSE AnalysisOfTransmittedProductsWithoutAssignment.DimensionKey END) AS AnalysisOfTransmittedProductsWithoutAssignment,
	|	CommitteeKeys.DimensionKey             AS CommitteeProductAnalysis,
	|	CatAssignments.LineOfBusiness    AS LineOfBusiness,
	|
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)          AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)        AS AmountExcludingVATMan,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)         AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)       AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)          AS VATLocal,
	|
	|	InventoryKinds.AmountARAP AS AmountARAP,
	|	CASE WHEN InventoryKinds.AmountIncludingVAT <> 0 THEN
	|		CAST(InventoryKinds.AmountARAP * InventoryKinds.VATAmount / InventoryKinds.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS AmountOfVATSettlements,
	|
	|	CAST(InventoryKinds.ManualDiscount * &ConversionRateToManCurrency
	|		AS NUMBER(31,2)) AS AmountOfManualManDiscount,
	|	CAST(InventoryKinds.DiscountMarkupAmount * &ConversionRateToManCurrency
	|		AS NUMBER(31,2)) AS AmountOfAutomaticManDiscount,
	|	InventoryKinds.ExciseTaxAmount AS ExciseAmountInCurrencyLocal,
	|	CAST(InventoryKinds.ExciseTaxAmount * &ConversionRatioFromLocalToMan
	|		AS NUMBER(31,2)) AS ExciseAmountInCurrencyMgmt,
	|	ISNULL(CatProducts.Principal, UNDEFINED) AS Principal,
	|	ISNULL(InventoryKinds.HSCodeRawItem, FALSE) AS Commodity,
	|	ISNULL(Dimension.Products.TracedGoods, FALSE) AS TracedGoods,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|		 AND &Manager <> VALUE(Catalog.Users.EmptyRef)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting) OR &ToReturnReusablePackage
	|			AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN UNDEFINED
	|		WHEN &VATTaxation IN (&TypesOfTaxationVATIsNotIncludedInCost) AND InventoryKinds.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) AND InventoryKinds.VATRate <> &ExportVATRate
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) AND InventoryKinds.HSCodeRawItem
	|		THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
	|		THEN VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|		ELSE &VATTaxation
	|	END AS VATActivityType,
	|	InventoryKinds.ARAPObject AS ARAPObject,
	|	InventoryKinds.ARAPObjectLineOfBusiness AS ARAPObjectLineOfBusiness,
	|	ISNULL(AnalysisOfCalculations.DimensionKey, ISNULL(AnalyticsOfCalculationsImplementationThroughCommissionAgent.DimensionKey, &AccountingDimensionByPartners)) AS AccountingDimensionByPartners,
	|	InventoryKinds.InventoriedLocationAttributesItemTypeOfItem AS InventoriedLocationAttributesItemTypeOfItem
	|
	|INTO TTTableTypesOfStocks
	|
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS InventoryKinds
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON 
	|		InventoryKinds.Ref = Amounts.Ref
	|		AND InventoryKinds.RowID = Amounts.RowID
	|
	|	LEFT JOIN 
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON 
	|		Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfTransmittedProducts
	|	ON 
	|		(&ThisIsTransferToCommission
	|			OR &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)))
	|		AND Dimension.Products = AnalysisOfTransmittedProducts.Products
	|		AND Dimension.Characteristic = AnalysisOfTransmittedProducts.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfTransmittedProducts.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalysisOfTransmittedProducts.Series
	|		AND &Partner = AnalysisOfTransmittedProducts.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProducts.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfTransmittedProductsWithoutAssignment
	|	ON 
	|		AnalysisOfTransmittedProducts.Products = AnalysisOfTransmittedProductsWithoutAssignment.Products
	|		AND AnalysisOfTransmittedProducts.Characteristic = AnalysisOfTransmittedProductsWithoutAssignment.Characteristic
	|		AND AnalysisOfTransmittedProducts.Series = AnalysisOfTransmittedProductsWithoutAssignment.Series
	|		AND AnalysisOfTransmittedProducts.StorageLocation = AnalysisOfTransmittedProductsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProductsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfTransmittedProductsContract
	|	ON 
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		AND NOT &AnalyticsPartnerInGoodsOnGo
	|		AND Dimension.Products = AnalysisOfTransmittedProductsContract.Products
	|		AND Dimension.Characteristic = AnalysisOfTransmittedProductsContract.Characteristic
	|		AND Dimension.Purpose = AnalysisOfTransmittedProductsContract.Purpose
	|		AND Dimension.Series = AnalysisOfTransmittedProductsContract.Series
	|		AND &Contract = AnalysisOfTransmittedProductsContract.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProductsContract.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfTransmittedProductsContractWithoutAssignment
	|	ON
	|		NOT &KeepRecordsOfInventoryCostByAssignments 
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		AND NOT &AnalyticsPartnerInGoodsOnGo
	|		AND Dimension.Products = AnalysisOfTransmittedProductsContractWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalysisOfTransmittedProductsContractWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfTransmittedProductsContractWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalysisOfTransmittedProductsContractWithoutAssignment.Series
	|		AND &Contract = AnalysisOfTransmittedProductsContractWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransmittedProductsContractWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfTransferredProductsEndCustomer
	|	ON 
	|		&BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|		AND NOT &AnalyticsPartnerInGoodsOnGo
	|		AND Dimension.Products = AnalysisOfTransferredProductsEndCustomer.Products
	|		AND Dimension.Characteristic = AnalysisOfTransferredProductsEndCustomer.Characteristic
	|		AND Dimension.Purpose = AnalysisOfTransferredProductsEndCustomer.Purpose
	|		AND Dimension.Series = AnalysisOfTransferredProductsEndCustomer.Series
	|		AND &CustomerContract = AnalysisOfTransferredProductsEndCustomer.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransferredProductsEndCustomer.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfTransferredProductsEndCustomerWithoutAssignment
	|	ON
	|		NOT &KeepRecordsOfInventoryCostByAssignments 
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|		AND NOT &AnalyticsPartnerInGoodsOnGo
	|		AND Dimension.Products = AnalysisOfTransferredProductsEndCustomerWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalysisOfTransferredProductsEndCustomerWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfTransferredProductsEndCustomerWithoutAssignment.Purpose
	|		AND Dimension.Series = AnalysisOfTransferredProductsEndCustomerWithoutAssignment.Series
	|		AND &CustomerContract = AnalysisOfTransferredProductsEndCustomerWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfTransferredProductsEndCustomerWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON
	|		Dimension.Products = CommitteeKeys.Products
	|		AND Dimension.Characteristic = CommitteeKeys.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND InventoryKinds.TypeOfInventoryOwnerAttributeOwnerOfItem = CommitteeKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|	ON AnalysisOfCalculations.Partner = &Partner
	|		AND AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Counterparty = &Counterparty
	|		AND AnalysisOfCalculations.Contract = InventoryKinds.ARAPObjectContract
	|		AND AnalysisOfCalculations.LineOfBusiness = InventoryKinds.ARAPObjectLineOfBusiness
	|		AND NOT (&SalesViaCommissionAgent
	|				AND &ConductARAPAccountingThroughEndCustomers)
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalyticsOfCalculationsImplementationThroughCommissionAgent
	|	ON AnalysisOfCalculations.Partner = &CustomerPartner
	|		AND AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Counterparty = &CustomerCounterparty
	|		AND AnalysisOfCalculations.Contract = &CustomerContract
	|		AND AnalysisOfCalculations.LineOfBusiness = &LineOfBusiness
	|		AND (&SalesViaCommissionAgent 
	|			AND &ConductARAPAccountingThroughEndCustomers)
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON Dimension.Purpose = CatAssignments.Ref
	|
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = Dimension.Products
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = InventoryKinds.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""";
	
	QueryTexts.Add(QueryText, RegisterName); 
	Return QueryText;
	
EndFunction

Function QueryTextTTSuitableAgreements(QueryTexts)
	
	RegisterName = "TTSuitableAgreements";
	
	QueryText = "SELECT DISTINCT
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ISNULL(TermsOfPurchases.Ref, AgreementWithProviderWithoutServices.Ref) AS Ref,
	|	ISNULL(TermsOfPurchases.Ref.Status, AgreementWithProviderWithoutServices.Status) AS Status,
	|	ISNULL(TermsOfPurchases.Ref.ValidityEndDate,
	|		AgreementWithProviderWithoutServices.ValidityEndDate) AS ValidityEndDate
	|INTO TTSuitableAgreements_Services
	|FROM
	|	DocumentDataTableItems AS ToRegister
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS TermsOfPurchases
	|		ON TermsOfPurchases.Ref.Partner = ISNULL(ToRegister.CharacteristicOfPrincipal,
	|			ToRegister.ItemPrincipal)
	|		AND TermsOfPurchases.Ref.Organization = &Organization
	|		AND TermsOfPurchases.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND TermsOfPurchases.Ref.Status IN (VALUE(Enum.StatusesOfTermsOfPurchase.Valid),
	|				VALUE(Enum.StatusesOfTermsOfPurchase.Closed))
	|		AND &Period >= TermsOfPurchases.Ref.ValidityStartDate
	|		AND (&Period <= TermsOfPurchases.Ref.ValidityEndDate
	|			OR TermsOfPurchases.Ref.ValidityEndDate = DATETIME(1, 1, 1))
	|		AND ToRegister.Products = TermsOfPurchases.Products
	|		AND ToRegister.Characteristic = TermsOfPurchases.Characteristic
	|		AND TermsOfPurchases.Ref.UseSpecifiedAgentServices
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AgreementWithProviderWithoutServices
	|		ON AgreementWithProviderWithoutServices.Partner = ISNULL(ToRegister.CharacteristicOfPrincipal,
	|			ToRegister.ItemPrincipal)
	|		AND AgreementWithProviderWithoutServices.Organization = &Organization
	|		AND AgreementWithProviderWithoutServices.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND AgreementWithProviderWithoutServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|		AND &Period >= AgreementWithProviderWithoutServices.ValidityStartDate
	|		AND (&Period <= AgreementWithProviderWithoutServices.ValidityEndDate
	|			OR AgreementWithProviderWithoutServices.ValidityEndDate = DATETIME(1, 1, 1))
	|		AND NOT AgreementWithProviderWithoutServices.UseSpecifiedAgentServices
	|
	|WHERE
	|	ToRegister.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.CharacteristicOfPrincipal, ToRegister.ItemPrincipal) <> &Organization
	|	AND ISNULL(ToRegister.CharacteristicOfPrincipal, ToRegister.ItemPrincipal) <> UNDEFINED
	|	AND &UseAgentServiceSale
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedAgreements.Products AS Products,
	|	SelectedAgreements.Characteristic AS Characteristic,
	|	SelectedAgreements.Ref AS Ref,
	|	TermsOfPurchases.Status AS Status,
	|	TermsOfPurchases.Currency AS Currency
	|	INTO TTSuitableAgreements
	|FROM
	|	(SELECT
	|		DataByServices.Products AS Products,
	|		DataByServices.Characteristic AS Characteristic,
	|		DataByServices.Ref AS Ref
	|	FROM
	|		TTSuitableAgreements_Services AS DataByServices
	|	WHERE
	|		DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataByServices.Products,
	|		DataByServices.Characteristic,
	|		MAX(DataByServices.Ref)
	|	FROM
	|		TTSuitableAgreements_Services AS DataByServices
	|	WHERE
	|		DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND (DataByServices.Products, DataByServices.Characteristic, DataByServices.ValidityEndDate) IN
	|				(SELECT
	|					Products,
	|					Characteristic,
	|					MAX(ValidityEndDate)
	|				FROM
	|					TTSuitableAgreements_Services
	|				WHERE
	|					DataByServices.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|				GROUP BY
	|					Products,
	|					Characteristic)
	|
	|	GROUP BY
	|		DataByServices.Products,
	|		DataByServices.Characteristic) AS SelectedAgreements
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|		ON SelectedAgreements.Ref = TermsOfPurchases.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAgencyServices(Query, QueryTexts)
	
	RegisterName = "TTAgencyServices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSuitableAgreements", QueryTexts) Then
		QueryTextTTSuitableAgreements(QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	CASE
	|		WHEN NOT ServiceAgreementInForce.Ref IS NULL
	|			THEN ServiceAgreementInForce.Ref
	|		ELSE ISNULL(ServiceAgreementClosed.Ref, UNDEFINED)
	|	END AS Terms,
	|	CASE
	|		WHEN NOT ServiceAgreementInForce.Ref IS NULL
	|			THEN ServiceAgreementInForce.Currency
	|		ELSE ISNULL(ServiceAgreementClosed.Currency, &Currency)
	|	END AS Currency,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	&Organization AS Organization,
	|	ISNULL(ToRegister.CharacteristicOfPrincipal, ToRegister.ItemPrincipal) AS Principal
	|INTO TTAgencyServices
	|FROM
	|	DocumentDataTableItems AS ToRegister
	|
	|	LEFT JOIN TTSuitableAgreements AS ServiceAgreementInForce
	|		ON ToRegister.Products = ServiceAgreementInForce.Products
	|		AND ToRegister.Characteristic = ServiceAgreementInForce.Characteristic
	|		AND ServiceAgreementInForce.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|
	|	LEFT JOIN TTSuitableAgreements AS ServiceAgreementClosed
	|		ON ToRegister.Products = ServiceAgreementClosed.Products
	|		AND ToRegister.Characteristic = ServiceAgreementClosed.Characteristic
	|		AND ServiceAgreementClosed.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND ServiceAgreementInForce.Ref IS NULL
	|
	|WHERE
	|	ToRegister.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.CharacteristicOfPrincipal, ToRegister.ItemPrincipal) <> &Organization
	|	AND ISNULL(ToRegister.CharacteristicOfPrincipal, ToRegister.ItemPrincipal) <> UNDEFINED
	|	AND &UseAgentServiceSale";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRates(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTExchangeRates";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	ExchangeRates.Currency AS Currency,
	|
	|	(DocumentExchangeRate.CourseNumerator * ExchangeRates.CourseDenominator)
	|   / (DocumentExchangeRate.CourseDenominator * ExchangeRates.CourseNumerator) AS ConversionFactor_
	|
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
	|		(Currency, BaseCurrency) IN (
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.Currency AS Currency,
	|				TableTypesOfStocks_.Organization.LocalAccountingCurrency AS BaseCurrency
	|			FROM
	|				TTTableTypesOfStocks AS TableTypesOfStocks_
	|			WHERE
	|				((&BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|					))
	|				OR
	|				(&BusinessOperation IN (
	|						VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|						VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)) 
	|					AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|					))
	|				AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND (TableTypesOfStocks_.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|				OR (TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT  &ToReturnReusablePackage))
	|
	|			UNION
	|
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.OwnerSInventoryOwnersAttributeInventoryOwnersAttributesCurrency AS Currency,
	|				TableTypesOfStocks_.Organization.LocalAccountingCurrency AS BaseCurrency
	|			FROM
	|				TTTableTypesOfStocks AS TableTypesOfStocks_
	|			WHERE
	|				((&BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|					))
	|				OR
	|				(&BusinessOperation IN (
	|						VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|						VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)) 
	|					AND &Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|					))
	|				AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND TableTypesOfStocks_.InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND (TableTypesOfStocks_.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|				OR (TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT  &ToReturnReusablePackage))
	|
	|			UNION
	|
	|				SELECT DISTINCT
	|					Services.Currency AS Currency,
	|					Services.Organization.LocalAccountingCurrency AS BaseCurrency
	|				FROM
	|					TTAgencyServices AS Services
	|		)
	|	) AS ExchangeRates
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency = &Currency) AS DocumentExchangeRate
	|	ON
	|		ExchangeRates.BaseCurrency = DocumentExchangeRate.BaseCurrency
	|
	|WHERE
	|	DocumentExchangeRate.CourseDenominator <> 0
	|	AND &Status <> VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTOperationServices(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTOperationServices";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Undefined, DocumentObject);
	SetRequestParameterVATTaxTypesTaxable(Query);
	InitializeProductAccountingAnalyticsKeys(Query);	
	SetRequestParametersCurrencyCoefficients(Query);	
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf;
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	Dimension.StorageLocation AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.ProductsTypeOfProducts AS ItemsType,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.VATRate AS VATRate,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.VATAmount AS VATAmount,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	GoodsTable.SalesOrder AS SalesOrder,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.ItemsLocationAttributesAssignment AS ItemsLocationAttributesAssignment,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.SetAccountingDimension AS SetAccountingDimension,
	|	CASE WHEN GoodsFromOrder.WithAssignment
	|			THEN GoodsTable.CustomerOrderAssignment
	|	END AS Purpose,
	|	CAST(GoodsTable.ManualDiscount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|	CAST(GoodsTable.DiscountMarkupAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS DiscountMarkupAmount,
	|	Amounts.VATAmountCompl AS VATLocal,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	CASE
	|		WHEN GoodsTable.AmountIncludingVAT <> 0
	|			THEN CAST(GoodsTable.AmountARAP * GoodsTable.VATAmount / GoodsTable.AmountIncludingVAT AS NUMBER(31,2))
	|		ELSE 0
	|	END AS AmountOfVATSettlements,
	|	CAST(GoodsTable.ManualDiscount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOfManualManDiscount,
	|	CAST(GoodsTable.DiscountMarkupAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOfAutomaticManDiscount,
	|	AgentServices.Terms AS Terms,
	|	AgentServices.Currency AS Currency,
	|	ISNULL(PrincipalKeys.DimensionKey, UNDEFINED) AS PrincipalProductAnalysis,
	|	ISNULL(AgentServices.Principal, UNDEFINED) AS Principal,
	|	ISNULL(Dimension.Products.TracedGoods, FALSE) AS TracedGoods,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|		 AND &Manager <> VALUE(Catalog.Users.EmptyRef)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN UNDEFINED
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE GoodsTable.VATRate
	|			WHEN &ExportVATRate THEN 
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	GoodsTable.ARAPObject AS ARAPObject,
	|	GoodsTable.ARAPObjectLineOfBusiness AS ARAPObjectLineOfBusiness,
	|	GoodsTable.ARAPObjectIsUniqueIdentifier AS ARAPObjectIsUniqueIdentifier,
	|	ISNULL(AnalysisOfCalculations.DimensionKey, &AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	GoodsTable.RowID AS RowID,
	|	CASE 
	|		WHEN GoodsTable.ProductsTypeOfProducts IN (&ListOfTypesWithUnitAnalytics) 
	|			THEN GoodsTable.Department
	|		ELSE
	|			&Department
	|	END AS Department,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes
	|
	|INTO TTOperationServices
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON GoodsTable.Ref = Amounts.Ref
	|			AND GoodsTable.RowID = Amounts.RowID
	|		LEFT JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|		ON (GoodsFromOrder.Ref = GoodsTable.SalesOrder)
	|			AND (GoodsFromOrder.RowCode = GoodsTable.RowCode)
	|		LEFT JOIN TTAgencyServices AS AgentServices
	|		ON GoodsTable.Products = AgentServices.Products
	|			AND GoodsTable.Characteristic = AgentServices.Characteristic
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS PrincipalKeys
	|		ON (PrincipalKeys.Products = GoodsTable.Products)
	|			AND (PrincipalKeys.Characteristic = GoodsTable.Characteristic)
	|			AND (PrincipalKeys.Purpose = VALUE(Catalog.Assignments.EmptyRef))
	|			AND (PrincipalKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND (PrincipalKeys.StorageLocation = AgentServices.Principal)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = PrincipalKeys.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|	ON AnalysisOfCalculations.Partner = &Partner
	|		AND AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Counterparty = &Counterparty
	|		AND AnalysisOfCalculations.Contract = GoodsTable.ARAPObjectContract
	|		AND AnalysisOfCalculations.LineOfBusiness = GoodsTable.ARAPObjectLineOfBusiness
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OperationService),
	|													VALUE(Enum.ItemsTypes.Work_5))
	|	AND GoodsTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	Dimension.StorageLocation AS Warehouse,
	|	Dimension.Products AS Products,
	|	GoodsTable.InventoriedLocationAttributesItemTypeOfItem AS ItemsType,
	|	Dimension.Characteristic AS Characteristic,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.VATAmount AS VATAmount,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	GoodsTable.SalesOrder AS SalesOrder,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Purpose AS ItemsLocationAttributesAssignment,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.SetAccountingDimension AS SetAccountingDimension,
	|	Dimension.Purpose AS Purpose,
	|	CAST(GoodsTable.ManualDiscount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS ManualDiscount,
	|	CAST(GoodsTable.DiscountMarkupAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS DiscountMarkupAmount,
	|	Amounts.VATAmountCompl AS VATLocal,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	CASE
	|		WHEN GoodsTable.AmountIncludingVAT <> 0
	|			THEN CAST(GoodsTable.AmountARAP * GoodsTable.VATAmount / GoodsTable.AmountIncludingVAT AS NUMBER(31,2))
	|		ELSE 0
	|	END AS AmountOfVATSettlements,
	|	CAST(GoodsTable.ManualDiscount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOfManualManDiscount,
	|	CAST(GoodsTable.DiscountMarkupAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOfAutomaticManDiscount,
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS PrincipalProductAnalysis,
	|	UNDEFINED AS Principal,
	|	ISNULL(Dimension.Products.TracedGoods, FALSE) AS TracedGoods,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &Manager <> VALUE(Catalog.Users.EmptyRef)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN UNDEFINED
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE GoodsTable.VATRate
	|			WHEN &ExportVATRate THEN
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|				AND &VATTaxation IN (&TypesOfVATTaxable)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END) AS VATActivityType,
	|	GoodsTable.ARAPObject AS ARAPObject,
	|	GoodsTable.ARAPObjectLineOfBusiness AS ARAPObjectLineOfBusiness,
	|	GoodsTable.ARAPObjectIsUniqueIdentifier AS ARAPObjectIsUniqueIdentifier,
	|	ISNULL(AnalysisOfCalculations.DimensionKey, &AccountingDimensionByPartners) AS AccountingDimensionByPartners,
	|	GoodsTable.RowID AS RowID,
	|	CASE
	|		WHEN GoodsTable.InventoriedLocationAttributesItemTypeOfItem IN (&ListOfTypesWithUnitAnalytics)
	|			THEN Dimension.StorageLocation
	|		ELSE
	|			&Department
	|	END AS Department,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS GoodsTable
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON GoodsTable.Ref = Amounts.Ref
	|			AND GoodsTable.RowID = Amounts.RowID
	|	
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Partner = &Partner
	|			AND AnalysisOfCalculations.Organization = &Organization
	|			AND AnalysisOfCalculations.Counterparty = &Counterparty
	|			AND AnalysisOfCalculations.Contract = GoodsTable.ARAPObjectContract
	|			AND AnalysisOfCalculations.LineOfBusiness = GoodsTable.ARAPObjectLineOfBusiness
	|	
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|			AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.InventoriedLocationAttributesItemTypeOfItem = VALUE(Enum.ItemsTypes.Work_5)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query) Export
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	If (Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit) 
		And Query.Parameters.Status = Enums.StatusesOfCustomerInvoices.Shipped Then
		RatePeriod = Query.Parameters.DateOfTransferOfTitleToGoods;
	Else
		RatePeriod = Query.Parameters.Period;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
																				Query.Parameters.ARAPCurrency,
																				RatePeriod,
																				Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
																				Query.Parameters.ARAPCurrency,
																				Query.Parameters.Period,
																				Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency_",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("ConversionRateToLocalTransferCurrency",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
EndProcedure

Procedure SetParameterForAccountingAnalystRequestForManPartners(Query)
	If Query.Parameters.Property("AccountingAnalyticsForManPartners") Then
		Return;
	EndIf;
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		ManStructure = New Structure();
		ManStructure.Insert("Organization", Catalogs.Companies.ManagementCompany);
		ManStructure.Insert("Partner", Query.Parameters.Partner);
		ManStructure.Insert("Counterparty", Query.Parameters.Counterparty);
		ManStructure.Insert("Contract", Query.Parameters.Contract);
		ManStructure.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
		AccountingAnalyticsForManPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(ManStructure);
	Else
		AccountingAnalyticsForManPartners = Undefined;
	EndIf;
	
	Query.SetParameter("AccountingAnalyticsForManPartners", AccountingAnalyticsForManPartners);
EndProcedure

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	If ConsignmentSalesServer.SalesViaCommissionAgent(Query.Parameters.BusinessOperation) Then
		StructureOfAnalytics = New Structure();
		StructureOfAnalytics.Insert("Organization", Query.Parameters.Organization);
		StructureOfAnalytics.Insert("Contract", Query.Parameters.CustomerContract);
		StructureOfAnalytics.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
		If Common.ObjectAttributeValue(Query.Parameters.Contract, "ConductARAPAccountingThroughEndCustomers") Then
			StructureOfAnalytics.Insert("Partner", Query.Parameters.CustomerPartner);
			StructureOfAnalytics.Insert("Counterparty", Query.Parameters.CustomerCounterparty);
		Else
			StructureOfAnalytics.Insert("Partner", Query.Parameters.Partner);
			StructureOfAnalytics.Insert("Counterparty", Query.Parameters.Counterparty);
		EndIf;
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
	Else
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters);
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	Table.Purpose           AS Purpose,
	|	Table.Series                AS Series,
	|	Table.Warehouse                AS Warehouse
	|FROM
	|	(
	|		SELECT
	|			Keys.Products                   AS Products,
	|			Keys.Characteristic                 AS Characteristic,
	|			&EmptyAssignment                    AS Purpose,
	|			&Series                               AS Series,
	|			Goods.TypeOfInventoryOwnerAttributeOwnerOfItem      AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND &Series                          = Dimension.Series
	|				AND Goods.TypeOfInventoryOwnerAttributeOwnerOfItem = Dimension.StorageLocation
	|				AND &EmptyAssignment               = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Dimension.Products IS NULL
	|			AND Goods.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|		UNION ALL
	|
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			&Series                     AS Series,
	|			&Partner                   AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|				INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|					ON Goods.Ref = DocumentDataHeader.Ref
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND &EmptyAssignment               = Dimension.Purpose
	|				AND &Series                          = Dimension.Series
	|				AND &Partner                        = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Dimension.Products IS NULL
	|			AND (&ThisIsTransferToCommission
	|				OR DocumentDataHeader.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|					VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			)
	|
	// Analytics keys for goods in transit
	|		UNION ALL
	|
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			Keys.Purpose           AS Purpose,
	|			Keys.Series                AS Series,
	|			&Contract                   AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|				INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|					ON Goods.Ref = DocumentDataHeader.Ref
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND Keys.Purpose                = Dimension.Purpose
	|				AND Keys.Series                     = Dimension.Series
	|				AND &Contract                        = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			NOT &AnalyticsPartnerInGoodsOnGo
	|			AND Dimension.Products IS NULL
	|			AND DocumentDataHeader.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Keys.Series                AS Series,
	|			&Contract                   AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|				INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|					ON Goods.Ref = DocumentDataHeader.Ref
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND &EmptyAssignment               = Dimension.Purpose
	|				AND Keys.Series                     = Dimension.Series
	|				AND &Contract                        = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			NOT &AnalyticsPartnerInGoodsOnGo
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND Dimension.Products IS NULL
	|			AND DocumentDataHeader.BusinessOperation 
	|				= VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			
	|		UNION ALL
	|
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			Keys.Purpose           AS Purpose,
	|			Keys.Series                AS Series,
	|			&Contract                   AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|				INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|				ON Goods.Ref = DocumentDataHeader.Ref
	|				
	|				LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|				ON Goods.ItemsLocationAttributes = Keys.Ref
	|				
	|				LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|				ON Keys.Products                 = Dimension.Products
	|					AND Keys.Characteristic            = Dimension.Characteristic
	|					AND Keys.Purpose                = Dimension.Purpose
	|					AND Keys.Series                     = Dimension.Series
	|					AND &Contract                        = Dimension.StorageLocation
	|					AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Dimension.Products IS NULL
	|			AND DocumentDataHeader.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Keys.Series                AS Series,
	|			&Contract                   AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|				INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|				ON Goods.Ref = DocumentDataHeader.Ref
	|				
	|				LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|				ON Goods.ItemsLocationAttributes = Keys.Ref
	|				
	|				LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|				ON Keys.Products                 = Dimension.Products
	|					AND Keys.Characteristic            = Dimension.Characteristic
	|					AND &EmptyAssignment               = Dimension.Purpose
	|					AND Keys.Series                     = Dimension.Series
	|					AND &Contract                        = Dimension.StorageLocation
	|					AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Dimension.Products IS NULL
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND DocumentDataHeader.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			Keys.Purpose           AS Purpose,
	|			Keys.Series                AS Series,
	|			&CustomerContract             AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|				INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|					ON Goods.Ref = DocumentDataHeader.Ref
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND Keys.Purpose                = Dimension.Purpose
	|				AND Keys.Series                     = Dimension.Series
	|				AND &CustomerContract                  = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			NOT &AnalyticsPartnerInGoodsOnGo
	|			AND Dimension.Products IS NULL
	|			AND DocumentDataHeader.BusinessOperation 
	|				= VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Keys.Series                AS Series,
	|			&CustomerContract             AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|				INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|					ON Goods.Ref = DocumentDataHeader.Ref
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND &EmptyAssignment               = Dimension.Purpose
	|				AND Keys.Series                     = Dimension.Series
	|				AND &CustomerContract                  = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			NOT &AnalyticsPartnerInGoodsOnGo
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			AND Dimension.Products IS NULL
	|			AND DocumentDataHeader.BusinessOperation 
	|				= VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			&Series                     AS Series,
	|			&Contract                   AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND &EmptyAssignment               = Dimension.Purpose
	|				AND &Series                          = Dimension.Series
	|				AND &Contract                        = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Dimension.Products IS NULL
	|			AND &SalesViaCommissionAgent
	|			
	|		UNION ALL
	|	
	|		SELECT
	|			Keys.Products            AS Products,
	|			Keys.Characteristic          AS Characteristic,
	|			&EmptyAssignment             AS Purpose,
	|			&Series                        AS Series,
	|			TypesOfOwnerStocks.GoodsOwner AS Warehouse
	|		FROM
	|			DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|
	|			INNER JOIN Catalog.InventoryKinds AS TypesOfOwnerStocks
	|			ON Goods.InventoryOwnerAttributeInventoryOwnerAttribute = TypesOfOwnerStocks.Ref
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products = Dimension.Products
	|				AND Keys.Characteristic = Dimension.Characteristic
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND &Series = Dimension.Series
	|				AND TypesOfOwnerStocks.GoodsOwner = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Dimension.Products IS NULL
	|			AND Goods.InventoryOwnerAttributeSaleOfAnotherCompanySInventory
	|			AND Goods.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND Goods.InventoryOwnerAttributeInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|		UNION ALL
	|
	|		SELECT
	|			Services.Products AS Products,
	|			Services.Characteristic AS Characteristic,
	|			&EmptyAssignment AS Purpose,
	|			&Series AS Series,
	|			ISNULL(Services.CharacteristicOfPrincipal, CatProducts.Principal) AS Warehouse
	|		FROM
	|			DocumentDataTableItems AS Services
	|
	|			INNER JOIN Catalog.Products AS CatProducts
	|			ON CatProducts.Ref = Services.Products
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Services.Products = Dimension.Products
	|				AND Services.Characteristic = Dimension.Characteristic
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND &Series = Dimension.Series
	|				AND ISNULL(Services.CharacteristicOfPrincipal, CatProducts.Principal) = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			ISNULL(Services.CharacteristicOfPrincipal, CatProducts.Principal) <> UNDEFINED
	|			AND ISNULL(Services.CharacteristicOfPrincipal, CatProducts.Principal) <> &Organization
	|			AND Dimension.DimensionKey IS NULL
	|			AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|
	|		UNION ALL
	|
	|		SELECT
	|			Keys.Products         AS Products,
	|			Keys.Characteristic       AS Characteristic,
	|			&EmptyAssignment          AS Purpose,
	|			Keys.Series                AS Series,
	|			Keys.StorageLocation                AS Warehouse
	|		FROM
	|			DocumentDataTableItems AS Goods
	|
	|			LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|			ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Keys.Products                 = Dimension.Products
	|				AND Keys.Characteristic            = Dimension.Characteristic
	|				AND Keys.Series                     = Dimension.Series
	|				AND Keys.StorageLocation			  = Dimension.StorageLocation
	|				AND &EmptyAssignment               = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			Dimension.Products IS NULL
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	) AS Table
	|");
	
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Series", Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("Partner", Query.Parameters.Partner);
	QueryAnalyst.SetParameter("Contract", Query.Parameters.Contract);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	QueryAnalyst.SetParameter("CustomerContract", Query.Parameters.CustomerContract);
	QueryAnalyst.SetParameter("ThisIsTransferToCommission", Query.Parameters.ThisIsTransferToCommission);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("AnalyticsPartnerInGoodsOnGo", Query.Parameters.AnalyticsPartnerInGoodsOnGo);
	QueryAnalyst.SetParameter("SalesViaCommissionAgent", 
		ConsignmentSalesServer.SalesViaCommissionAgent(Query.Parameters.BusinessOperation));
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	//Sets
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Keys.ProductsInSet   AS ProductsInSet,
	|	Keys.ItemVariantOfSet AS ItemVariantOfSet
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|	INNER JOIN
	|		InformationRegister.SetAccountingDimension AS Keys
	|	ON
	|		Goods.SetAccountingDimension = Keys.DimensionKey
	|
	|	LEFT JOIN
	|		InformationRegister.SetAccountingDimension AS Dimension
	|	ON
	|		Keys.ProductsInSet                = Dimension.ProductsInSet
	|		AND Keys.ItemVariantOfSet            = Dimension.ItemVariantOfSet
	|WHERE
	|	Dimension.ProductsInSet IS NULL
	|");
		
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
		
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.SetAccountingDimension.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.CustomerInvoice";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;

	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("UseAdvancedFeaturesOfSalesOrder",
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	If RegisterName = "ShipmentAndReturnReferences" Then
		
		QueryText = QueryTextTableShipmentReferences(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable);
		
		If RegisterName = "ShipmentAndReturnReferences" Then
			QueryText = StrReplace(QueryText, "DocumentTableUpdatingInformationSecurity.Ref.", "DocumentData.");
		EndIf;
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure SetRequestParameterVATTaxTypesTaxable(Query) Export
	
	If Query.Parameters.Property("TypesOfVATTaxable") Then
		Return;
	EndIf;

	Query.SetParameter("TypesOfVATTaxable", VATAccountingERP.TypesOfActivitiesVATIsAcceptedForReimbursement());
	
EndProcedure

Function QueryTextTTProductLines(Query, QueryTexts)
	
	RegisterName = "TTProductLines";
	
	QueryText = "
	|SELECT
	|	TableOfGoods.Ref AS Ref,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.PartnerProducts AS PartnerProducts,	
	|	TableOfGoods.Price AS Price,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber
	|
	|INTO TTProductLines
	|FROM
	|	DocumentDataTableItems AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension,
	|	TableOfGoods.Package,
	|	TableOfGoods.PartnerProducts,	
	|	TableOfGoods.Price
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes,
	|	SetAccountingDimension,
	|	Package,
	|	Price
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTInventoryOwnerAttributesOfWorks(Query, QueryTexts)
	
	RegisterName = "TTInventoryOwnerAttributesOfWorks";
	
	QueryText = "
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TTInventoryOwnerAttributesOfWorks
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS TableOfGoods
	|WHERE
	|	TableOfGoods.InventoriedLocationAttributesItemTypeOfItem = VALUE(Enum.ItemsTypes.Work_5)
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not (DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
			And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting)) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductLines", QueryTexts) Then
		QueryTextTTProductLines(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInventoryOwnerAttributesOfWorks", QueryTexts) Then
		QueryTextTTInventoryOwnerAttributesOfWorks(Query, QueryTexts);
	EndIf;
	
	ValueText_ = "
	|SELECT
	|	CustomerInvoice.Date AS Period,
	|	CustomerInvoice.Ref AS Ref,
	|	CustomerInvoice.BusinessOperation AS BusinessOperation,
	|	CustomerInvoice.Counterparty AS Counterparty,
	|	CustomerInvoice.Contract AS Contract,
	|	CustomerInvoice.Shipper AS Shipper,
	|	CustomerInvoice.GoodsRecipient AS GoodsRecipient,
	|	CustomerInvoice.Organization AS Organization,
	|	CustomerInvoice.Department AS Department,
	|	CustomerInvoice.Ref AS DocumentSalesOfGoodsAndServices,
	|	CustomerInvoice.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	&SalesViaCommissionAgent AS SalesViaCommissionAgent,
	|	UNDEFINED AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	TSServices.ARAPObject AS ARAPObject,
	|	CustomerInvoice.VATTaxation AS VATTaxation,
	|	TSServices.VATRate AS VATRate,
	|	TSServices.Products AS Products,
	|	TSServices.Characteristic AS Characteristic,
	|	TSServices.Price AS Price,
	|	TSServices.Series AS Series,
	|	TSServices.PartnerProducts AS PartnerProducts,	
	|	TSServices.ProductsInSet AS ProductsInSet,
	|	TSServices.ItemVariantOfSet AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|				OR TSServices.NumberOfPackages = 0
	|			THEN TSServices.Count
	|		ELSE TSServices.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN TSServices.ProductsUnitOfMeasure
	|		ELSE &RequestTextServiceUnit
	|	END AS UnitOfMeasure,
	|	0 AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	TSServices.LineNumber AS LineNumber,
	|	TSServices.RowID AS RowID,
	|	TSServices.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	DocumentDataHeader AS CustomerInvoice
	|		LEFT JOIN DocumentDataTableItems AS TSServices
	|		ON CustomerInvoice.Ref = TSServices.Ref
	|		
	|		LEFT JOIN TTInventoryOwnerAttributesOfWorks AS InventoryKinds
	|		ON TSServices.Ref = InventoryKinds.Ref
	|			AND TSServices.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|WHERE
	|	TSServices.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OperationService),
	|											VALUE(Enum.ItemsTypes.Work_5))
	// Regular work is counted in this request. And traceable in the following, i.e. from the TS Inventory owner attributes.
	|	AND InventoryKinds.Ref IS NULL
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TSServices.Ref IS NULL
	|				THEN TRUE
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	CustomerInvoice.Date,
	|	CustomerInvoice.Ref,
	|	CustomerInvoice.BusinessOperation,
	|	CustomerInvoice.Counterparty,
	|	CustomerInvoice.Contract,
	|	CustomerInvoice.Shipper,
	|	CustomerInvoice.GoodsRecipient,
	|	CustomerInvoice.Organization,
	|	CustomerInvoice.Department,
	|	CustomerInvoice.Ref,
	|	CustomerInvoice.CustomerCounterparty,
	|	&SalesViaCommissionAgent,
	|	UNDEFINED,
	|	FALSE,
	|	FALSE,
	|	FALSE,
	|	TypesOfTSStocks.ARAPObject,
	|	CustomerInvoice.VATTaxation,
	|	TypesOfTSStocks.VATRate,
	|	TypesOfTSStocks.AnalysisOfAccountingForProductsProducts,
	|	TypesOfTSStocks.AnalysisOfAccountingProductsCharacteristics,
	|	TypesOfTSStocks.Price,
	|	TypesOfTSStocks.InventoryLocationAttributeAnalysisBatch,
	|	TypesOfTSStocks.PartnerProducts,
	|	TypesOfTSStocks.AnalyticsOfSetAccountingSetItem,
	|	TypesOfTSStocks.AnalyticsOfSetAccountingSetCharacteristics,
	|	"""",
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|				OR TypesOfTSStocks.NumberOfPackages = 0
	|			THEN TypesOfTSStocks.Count
	|		ELSE TypesOfTSStocks.NumberOfPackages
	|	END,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN TypesOfTSStocks.InventoryLocationAttributeOfItemOfUnitOfMeasurement
	|		ELSE &QueryTextUnitOfMeasure
	|	END,
	|	TypesOfTSStocks.QuantityByGBRN,
	|	TypesOfTSStocks.ExciseTaxAmount,
	|	TypesOfTSStocks.CCDNumber,
	|	TypesOfTSStocks.FEACNCode,
	|	TypesOfTSStocks.InventoryOwnerAttribute,
	|	ProductLines_2.LineNumber,
	|	TypesOfTSStocks.RowID,
	|	TypesOfTSStocks.RowID,
	|	&BusinessTransactionSetting
	|FROM
	|	DocumentDataHeader AS CustomerInvoice
	|		
	|		LEFT JOIN DocumentDataTableOfInventoryOwnerAttributes AS TypesOfTSStocks
	|		ON CustomerInvoice.Ref = TypesOfTSStocks.Ref
	|
	|		LEFT JOIN TTProductLines AS ProductLines_2
	|		ON TypesOfTSStocks.Ref = ProductLines_2.Ref
	|			AND TypesOfTSStocks.ItemsLocationAttributes = ProductLines_2.ItemsLocationAttributes
	|			AND TypesOfTSStocks.SetAccountingDimension = ProductLines_2.SetAccountingDimension
	|			AND TypesOfTSStocks.Package = ProductLines_2.Package
	|			AND TypesOfTSStocks.Price = ProductLines_2.Price
	|			AND TypesOfTSStocks.PartnerProducts = ProductLines_2.PartnerProducts
	|
	|WHERE
	|	CASE
	|			WHEN CustomerInvoice.ToReturnReusablePackage
	|				THEN TypesOfTSStocks.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			ELSE TRUE
	|		END
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TypesOfTSStocks.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	ValueText_ = StrReplace(
		ValueText_,
		"&RequestTextServiceUnit",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"TSServices.Package",
			"TSServices.Products"));
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"TypesOfTSStocks.Package",
			"TypesOfTSStocks.ItemsLocationAttributes.Products"));
	ValueText_ = StrReplace(
		ValueText_,
		"&SalesViaCommissionAgent",
		ConsignmentSalesServer.QueryTextSalesViaCommissionAgent("CustomerInvoice.Ref.BusinessOperation"));
	
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region DocumentExchangeRates
	
	RegisterName = "VT_DataOfDocumentHeaderMerge";
	
	QueryTextDataOfDocumentHeaderMerge =
	"SELECT
	|	DocumentHeaderData.Date AS Date,
	|	DocumentHeaderData.Ref AS Ref,
	|	DocumentHeaderData.Organization AS Organization,
	|	DocumentHeaderData.Currency AS Currency,
	|	DocumentHeaderData.ARAPCurrency AS ARAPCurrency
	|INTO VT_DataOfDocumentHeaderMerge
	|FROM
	|	(SELECT
	|		DocumentDataHeader.DateOfTransferOfTitleToGoods AS Date,
	|		DocumentDataHeader.Ref AS Ref,
	|		DocumentDataHeader.Organization AS Organization,
	|		DocumentDataHeader.Currency AS Currency,
	|		DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|	FROM
	|		DocumentDataHeader AS DocumentDataHeader
	|	WHERE
	|		DocumentDataHeader.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentDataHeader.Date AS Date,
	|		DocumentDataHeader.Ref AS Ref,
	|		DocumentDataHeader.Organization AS Organization,
	|		DocumentDataHeader.Currency AS Currency,
	|		DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|	FROM
	|		DocumentDataHeader AS DocumentDataHeader) AS DocumentHeaderData";
	
	QueryTexts.Add(QueryTextDataOfDocumentHeaderMerge, RegisterName);
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";
	
	QueryTextExchangeRatesOfDocumentLinesOfBusiness =
	"SELECT DISTINCT
	|	DocumentHeaderData.Ref AS Ref,
	|	DocumentHeaderData.Organization AS Organization,
	|	DocumentHeaderData.Date AS DateOfCourse,
	|	DocumentARAPObjects.ARAPObject AS ARAPObject,
	|	DocumentHeaderData.Currency AS DocumentCurrency,
	|	DocumentHeaderData.ARAPCurrency AS ARAPCurrency
	|FROM
	|	(SELECT
	|		PaymentScheduleSteps.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableStagesOfPaymentSchedule AS PaymentScheduleSteps
	|
	|	UNION ALL
	|
	|	SELECT
	|		ARAPDetails.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableDecryptionOfPayment AS ARAPDetails
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentDataHeader.ObjectOfManCalculations AS ARAPObject
	|	FROM
	|		DocumentDataHeader AS DocumentDataHeader
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableItems AS GoodsTable
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.SalesOrder.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableItems AS GoodsTable
	|			INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON DocumentDataHeader.Ref = GoodsTable.Ref
	|			AND DocumentDataHeader.OrderSales
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentDataHeader.Contract.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataHeader AS DocumentDataHeader
	|	WHERE
	|		DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)) AS
	|		DocumentARAPObjects
	|		INNER JOIN VT_DataOfDocumentHeaderMerge AS DocumentHeaderData
	|		ON TRUE
	|WHERE
	|	DocumentARAPObjects.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)";
	
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(
		QueryTextExchangeRatesOfDocumentLinesOfBusiness);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	If Not Query.Parameters.Property("NewOnlineARAPAccounting") Then
		Query.SetParameter("NewOnlineARAPAccounting", Constants.NewOnlineARAPAccounting.Get());
	EndIf;
	
	#Region Sale
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		
		TextSale =
		"SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND &ConductARAPAccountingThroughEndCustomers
		|			THEN DocumentDataHeader.CustomerPartner
		|		ELSE DocumentDataHeader.Partner
		|	END AS Partner,
		|	Table.ARAPObject AS ARAPObject,
		|	Table.PaymentDate AS PaymentDate,
		|	Table.OrderDocument AS SalesOrder_,
		|	CASE
		|		WHEN &ThisIsTransferOfOwnershipWithoutOrder
		|			THEN FALSE
		|		ELSE DocumentDataHeader.OrderSales
		|	END AS InvoiceForOrders,
		|	CASE
		|		WHEN DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|		AND DocumentDataHeader.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|			VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
		|			VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|			VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			THEN Table.AmountARAP + Table.AmountARAPByPackage
		|		ELSE 0
		|	END AS AmountARAP,
		|	CASE
		|		WHEN DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|		AND DocumentDataHeader.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|			VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
		|			VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|			VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			THEN Table.AmountARAPByPackage
		|		ELSE 0
		|	END AS AmountARAPByPackage,
		|	CASE
		|		WHEN DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|		AND DocumentDataHeader.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|			VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
		|			VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|			VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			THEN Table.PaymentAmount + Table.PackageDepositValue
		|		ELSE 0
		|	END AS Sum,
		|	DocumentDataHeader.ARAPObjectSettings AS ARAPObjectSettings,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN DocumentDataHeader.DateOfTransferOfTitleToGoods
		|		ELSE DocumentDataHeader.Date
		|	END AS RecorderDate,
		|	DocumentDataHeader.Number AS RecorderNumber,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency,
		|	DocumentDataHeader.BusinessOperation AS BusinessOperation,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN DocumentDataHeader.DateOfTransferOfTitleToGoods
		|		ELSE DocumentDataHeader.Date
		|	END AS DateOfCourse,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.PaymentOption AS PaymentOption,
		|	Table.ExceedingOrder AS ExceedingOrder,
		|	UNDEFINED AS LinkedDocument
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref";
		
	Else
		TextSale = "";
	EndIf;
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		
		TextPaymentPlanning =
		"SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND &ConductARAPAccountingThroughEndCustomers
		|			THEN DocumentDataHeader.CustomerPartner
		|		ELSE DocumentDataHeader.Partner
		|	END AS Partner,
		|	Table.ARAPObject AS ARAPObject,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN DocumentDataHeader.DateOfTransferOfTitleToGoods
		|		ELSE DocumentDataHeader.Date
		|	END AS RecorderDate,
		|	DocumentDataHeader.Number AS RecorderNumber,
		|	DocumentDataHeader.ARAPObjectSettings AS ARAPObjectSettings,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.BusinessOperation AS BusinessOperation,
		|	DocumentDataHeader.PaymentMethod AS PaymentMethod,
		|	Table.PaymentDate AS PaymentDate,
		|	Table.PaymentOption AS PaymentOption,
		|	Table.AmountARAP + Table.AmountARAPByPackage AS AmountDue,
		|	CASE
		|		WHEN DocumentDataHeader.Status <> VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
		|		AND Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|		AND NOT &SalesViaCommissionAgent
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ExcludeDuringControl,
		|	CASE
		|		WHEN &ThisIsTransferOfOwnershipWithoutOrder
		|			THEN FALSE
		|		ELSE DocumentDataHeader.OrderSales
		|	END AS InvoiceForOrders,
		|	Table.OrderDocument AS SalesOrder_,
		|	Table.ExceedingOrder AS ExceedingOrder,
		|	UNDEFINED AS LinkedDocument
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	OR DocumentDataHeader.Status <> VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|		AND DocumentDataHeader.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|												VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|												VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|												VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND (Table.OrderDocument = UNDEFINED
		|			AND NOT ISNULL(DocumentDataHeader.Contract.ExecutionScheduleIsSpecified,FALSE)
		|				OR DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments))";
		
	Else
		TextPaymentPlanning = "";
	EndIf;
	
	#EndRegion
	
	#Region TextProducts_1
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		
		TextProducts_1 =
		"SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND &ConductARAPAccountingThroughEndCustomers
		|			THEN DocumentDataHeader.CustomerPartner
		|		ELSE DocumentDataHeader.Partner
		|	END AS Partner,
		|	DocumentDataHeader.Counterparty AS Counterparty,
		|	DocumentDataHeader.Contract AS Contract,
		|	DocumentDataHeader.LineOfBusiness AS LineOfBusiness,
		|	ISNULL(TableOfCalculationObjects.Ref, Table.ARAPObject) AS ARAPObject,
		|	DocumentDataHeader.Date AS DateOfShipment,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND NOT DocumentDataHeader.Status IN (VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment),
		|			VALUE(Enum.StatusesOfCustomerInvoices.Shipped))
		|			THEN Table.AmountARAP
		|		ELSE 0
		|	END AS IncreaseShipping,
		|	CASE
		|		WHEN &ThisIsTransferOfOwnershipBasedOnShipment
		|			THEN Table.AmountARAP
		|		WHEN DocumentDataHeader.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|			VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
		|			VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent))
		|		OR DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN Table.AmountARAP
		|		ELSE 0
		|	END AS ReduceShipping,
		|	CASE
		|		WHEN &ThisIsTransferOfOwnershipBasedOnShipment
		|			THEN 0
		|		ELSE Table.AmountARAP
		|	END AS IncreaseToBeSHIPPED,
		|	CASE
		|		WHEN &ThisIsTransferOfOwnershipBasedOnShipment
		|			THEN 0
		|		ELSE Table.AmountARAP
		|	END AS ReduceToBESHIPPED,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
		|			THEN 0
		|		ELSE Table.AmountARAP
		|	END AS AmountARAP,
		|	Table.SalesOrder AS SalesOrder_,
		|	&ThisIsTransferOfOwnershipBasedOnShipment AS ThisIsTransferOfOwnershipBasedOnShipment,
		|	CASE
		|		WHEN Table.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
		|		AND DocumentDataHeader.PackageDepositIsRequired
		|			THEN Table.AmountARAP
		|		ELSE 0
		|	END AS DepositForPackage,
		|	Table.RowCode = 0 AS ExceedingOrder,
		|	CASE
		|		WHEN &ThisIsTransferOfOwnershipWithoutOrder
		|			THEN &ThisIsTransferOfOwnershipBasedOnShipment
		|		ELSE DocumentDataHeader.OrderSales
		|	END AS InvoiceForOrders,
		|	DocumentDataHeader.ARAPObjectSettings AS ARAPObjectSettings,
		|	DocumentDataHeader.Date AS RecorderDate,
		|	DocumentDataHeader.Number AS RecorderNumber,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency,
		|	DocumentDataHeader.BusinessOperation AS BusinessOperation,
		|	DocumentDataHeader.Currency AS DocumentCurrency
		|FROM
		|	DocumentDataTableItems AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS TableOfCalculationObjects
		|		ON &ThisIsTransferOfOwnershipBasedOnShipment
		|		AND DocumentDataHeader.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|		AND Table.SalesOrder = TableOfCalculationObjects.Object
		|		AND NOT TableOfCalculationObjects.DeletionMark
		|		AND TableOfCalculationObjects.IsInternal
		|WHERE
		|	(Table.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|	OR DocumentDataHeader.PackageDepositIsRequired
		|	OR NOT DocumentDataHeader.ToReturnReusablePackage)";
		
	Else
		TextProducts_1 = "";
	EndIf;
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset =
	"SELECT
	|	Table.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		AND &ConductARAPAccountingThroughEndCustomers
	|			THEN DocumentDataHeader.CustomerPartner
	|		ELSE DocumentDataHeader.Partner
	|	END AS Partner,
	|	ARAPObjects.Ref AS CalculationObjectReceiver,
	|	Table.ARAPObject AS CalculationObjectSource,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency,
	|	Table.AmountARAP AS AmountARAP,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	Table.Sum AS Sum,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|		AND NOT &NewOnlineARAPAccounting
	|			THEN DocumentDataHeader.DateOfTransferOfTitleToGoods
	|		ELSE DocumentDataHeader.Date
	|	END AS DateOfCourse,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		AND DocumentDataHeader.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|		AND NOT &NewOnlineARAPAccounting
	|			THEN DocumentDataHeader.DateOfTransferOfTitleToGoods
	|		ELSE DocumentDataHeader.Date
	|	END AS RecorderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		AND BEGINOFPERIOD(DocumentDataHeader.Date,
	|			DAY) <> BEGINOFPERIOD(DocumentDataHeader.DateOfTransferOfTitleToGoods, DAY)
	|			THEN VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|		ELSE VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|	END AS BusinessOperation
	|FROM
	|	DocumentDataTableDecryptionOfPayment AS Table
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = Table.Ref
	|		AND ARAPObjects.Organization = DocumentDataHeader.Organization
	|		AND NOT ARAPObjects.OnlyBalance
	|		AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	(NOT Table.CalculationObjectObject REFS Document.CustomerInvoice
	|	OR DocumentDataHeader.Organization = VALUE(Catalog.Companies.ManagementCompany))
	|	AND NOT (Table.CalculationObjectObject REFS Document.SalesOrder
	|	AND Table.ARAPObjectOfCompany = VALUE(Catalog.Companies.ManagementCompany))";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset, TextProducts_1);
	
	#Region SaleToCustomerLocalAccounting
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		
		TextPayment =
		"SELECT
		|	Table.Ref AS Ref,
		|	VALUE(Catalog.Companies.ManagementCompany) AS Organization,
		|	Table.Partner AS Partner,
		|	Table.ObjectOfManCalculations AS ARAPObject,
		|	Table.Date AS RecorderDate,
		|	Table.Number AS RecorderNumber,
		|	Table.ARAPCurrency AS ARAPCurrency,
		|	Table.Currency AS DocumentCurrency,
		|	Table.BusinessOperation AS BusinessOperation,
		|	Table.AmountARAP AS AmountARAP,
		|	Table.DocumentAmount AS Sum,
		|	0 AS IncreaseIsPaid,
		|	0 AS ReductionIsPaid,
		|	Table.Date AS DateOfCourse,
		|	DATETIME(1, 1, 1) AS MaturityDate,
		|	UNDEFINED AS PaymentMethod,
		|	UNDEFINED AS ProformaInvoice,
		|	UNDEFINED AS CashFlowItem,
		|	UNDEFINED AS LinkedDocument,
		|	Table.ObjectOfManCalculations.UUID AS FinRecordID,
		|	UNDEFINED AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.ObjectOfManCalculations <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|";
	
	Else
		TextPayment = "";
	EndIf;
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment);
	
	#Region ImplementationToPrepaymentOnWay
	
	TextPaymentPlanning =
	"SELECT
	|	Table.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		AND &ConductARAPAccountingThroughEndCustomers
	|			THEN DocumentDataHeader.CustomerPartner
	|		ELSE DocumentDataHeader.Partner
	|	END AS Partner,
	|	Table.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	DocumentDataHeader.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	Table.PaymentDate AS PaymentDate,
	|	Table.PaymentOption AS PaymentOption,
	|	Table.AmountARAP + Table.AmountARAPByPackage AS AmountDue
	|FROM
	|	DocumentDataTableStagesOfPaymentSchedule AS Table
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	DocumentDataHeader.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|		VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods),
	|		VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
	|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|		VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|	AND DocumentDataHeader.Status <> VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|	AND (Table.OrderDocument = UNDEFINED
	|		AND NOT ISNULL(DocumentDataHeader.Contract.ExecutionScheduleIsSpecified,FALSE)
	|			OR DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments))";

	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlanning);
	
EndProcedure

Procedure ReflectReserve(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.SalesViaCommissionAgent
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		Return;
	EndIf;
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|				AND DocumentGoods.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		ELSE UNDEFINED
	|	END								AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|				AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	DocumentDataTableItems AS DocumentGoods
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Count <> 0";
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.SalesViaCommissionAgent
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
			Or DocumentObject.BusinessOperation =
				Enums.BusinessTransactions.TransferOfTitleToGoods Then
		Return;
	EndIf;
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|				AND DocumentGoods.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		ELSE UNDEFINED
	|	END								AS OrderDocument,
	|	HeaderData_.Ref					AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|				AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	DocumentDataTableItems AS DocumentGoods
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Count <> 0";
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
												
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		Return;
	EndIf;
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|				AND DocumentGoods.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		ELSE UNDEFINED
	|	END								AS OrderDocument,
	|	HeaderData_.Ref					AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|				AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	CASE
	|		WHEN HeaderData_.OrderSales
	|				AND NOT ISNULL(DocumentGoods.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedOrderFeatures)
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	DocumentDataTableItems AS DocumentGoods
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Count <> 0";
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);

	MetadataObject	= Metadata.Documents.CustomerInvoice;
	TSSeriesName			= "SetOfSeries";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										TSSeriesName);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingAnalyticsForManPartners");
	AdditionalParameters.Add("AccountingDimensionByPartners");
	AdditionalParameters.Add("TaxationOfOrganization");
	
	If Query <> Undefined Then
		SetParameterForAccountingAnalystRequestForManPartners(Query);
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
		SetRequestParameterTaxationOfOrganization(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableTypesOfStocks");
	AdditionalTables.Add("TTOperationServices");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts, Document);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTOperationServices(Query, QueryTexts, Document);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(DocumentObject) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Sales_Product
	
	If DocumentObject <> Undefined
		And ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent)
			And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
		
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN VALUE(Catalog.Companies.ManagementCompany)
	|		ELSE UNDEFINED
	|	END 											AS CorCompany,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END 											AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END 											AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN DocumentTable.Ref
	|		ELSE UNDEFINED
	|	END 											AS CorLot,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 											AS LotVendorAttributesCorr,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN &TaxationOfOrganization
	|		ELSE TableTypesOfStocks_.VATActivityType
	|	END 											AS CorVATActivityTypes,
	|	TableTypesOfStocks_.AccountingDimensionByPartners 	AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN DocumentTable.OrderSales AND &SalesAgainstSeveralOrders
	|			THEN TableTypesOfStocks_.SalesOrder
	|		WHEN DocumentTable.OrderSales AND NOT &SalesAgainstSeveralOrders
	|			THEN DocumentTable.SalesOrder
	|		ELSE DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		THEN TableTypesOfStocks_.RowID
	|		ELSE UNDEFINED
	|	END 									AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ConsignmentSale)
	|		ELSE &BusinessTransactionSetting
	|	END 									AS BusinessTransactionSetting 
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods), 
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND (TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region Implementation_Work
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment)
		And (DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped
			Or DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	CASE
	|		WHEN (DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		 AND DocumentTable.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN DocumentTable.DateOfTransferOfTitleToGoods
	|		ELSE DocumentTable.Date
	|	END 					AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN VALUE(Catalog.Companies.ManagementCompany)
	|		ELSE UNDEFINED
	|	END 											AS CorCompany,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE UNDEFINED
	|	END 										  	AS CorItemsLocationAttributes,
	|	UNDEFINED 								  	AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN DocumentTable.Ref
	|		ELSE UNDEFINED
	|	END 											AS CorLot,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 											AS LotVendorAttributesCorr,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN &TaxationOfOrganization
	|		ELSE TableTypesOfStocks_.VATActivityType
	|	END 											AS CorVATActivityTypes,
	|	TableTypesOfStocks_.AccountingDimensionByPartners  	AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN DocumentTable.OrderSales AND &SalesAgainstSeveralOrders
	|			THEN TableTypesOfStocks_.SalesOrder
	|		WHEN DocumentTable.OrderSales AND NOT &SalesAgainstSeveralOrders
	|			THEN DocumentTable.SalesOrder
	|		ELSE DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 			AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	DocumentTable.Manager 			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|		ELSE DocumentTable.BusinessOperation
	|	END									AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	// Filling in the field must correspond to the function of the textquestionatabletablyand the value of sales().
	|	&BusinessTransactionSetting	AS BusinessTransactionSetting 
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region DisposalAtFixedCost_Tare
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent
			And DocumentObject.ToReturnReusablePackage) Then
			
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  	AS CorItemsLocationAttributes,
	|	UNDEFINED 								  	AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	DocumentTable.Partner 						AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods)  AS IncomeItem,
	|	DocumentTable.Partner 						AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan 		AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan		AS CostExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl 		AS LocalCost,
	|	TableTypesOfStocks_.AmountExcludingVATMan 		AS CostMan,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleOfTransferredReturnablePackaging) AS BusinessOperation,
	|	CASE
	|		WHEN &PackageDepositIsRequired
	|			THEN TableTypesOfStocks_.ARAPObjectIsUniqueIdentifier
	|		ELSE TableTypesOfStocks_.RowID
	|	END AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleOfTransferredReturnablePackaging) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods), VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem = VALUE(Enum.ItemsTypes.ReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	EndIf;
	#EndRegion
	
	#Region Moving_Goods_TransferToCommission
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									   	AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts 	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					   	AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END 									AS AccountingSection,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END 									AS CorAccountingSection,
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods), VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND (TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region ExternalReceipt_Goods_SalesToClientLocalAccounting
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting) Then
			
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	VALUE(Catalog.Companies.ManagementCompany)	AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 				AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DocumentTable.Ref										AS Lot,
	|	&TaxationOfOrganization									AS VATActivityType,
	|	&TaxationOfOrganization									AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes						AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes						AS LotVendorAttributesCorr,
	|	DocumentTable.Partner									AS Vendor,
	|	DocumentTable.Counterparty 								AS Counterparty,
	|	TableTypesOfStocks_.VATRate								AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|	0										AS Cost,
	|	0										AS CostExcludingVAT,
	|	0										AS LocalCost,
	|	0										AS VATLocal,
	|	0										AS CostMan,
	|	0										AS VATManag,
	|	0										AS OffBalanceCost,
	|	0										AS OffBalanceCostLocal,
	|	0 										AS AddExpensesForGoods,
	|	0 										AS AdditionalExpensesExcludingVAT,
	|	0 										AS AddExpensesLocal,
	|	0 										AS AddExpensesMan,
	|	0 										AS PermanentDifference,
	|	0 										AS CostTD,
	|	0										AS CostOfPersonalIncomeTax,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.Principal = UNDEFINED
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND (TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region ExternalReceipt_Work_Implementation_LocalAccounting
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
			
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	VALUE(Catalog.Companies.ManagementCompany)	AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 				AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	DocumentTable.Ref										AS Lot,
	|	&TaxationOfOrganization									AS VATActivityType,
	|	&TaxationOfOrganization									AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes						AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes						AS LotVendorAttributesCorr,
	|	DocumentTable.Partner									AS Vendor,
	|	DocumentTable.Counterparty 								AS Counterparty,
	|	TableTypesOfStocks_.VATRate								AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 			AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	DocumentTable.Manager 			AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|	0										AS Cost,
	|	0										AS CostExcludingVAT,
	|	0										AS LocalCost,
	|	0										AS VATLocal,
	|	0										AS CostMan,
	|	0										AS VATManag,
	|	0										AS OffBalanceCost,
	|	0										AS OffBalanceCostLocal,
	|	0 										AS AddExpensesForGoods,
	|	0 										AS AdditionalExpensesExcludingVAT,
	|	0 										AS AddExpensesLocal,
	|	0 										AS AddExpensesMan,
	|	0 										AS PermanentDifference,
	|	0 										AS CostTD,
	|	0										AS CostOfPersonalIncomeTax,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region Movement_Goods_SaleWithoutTransferOfOwnership
	
	If Not DocumentObject = Undefined 
		And ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
			And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									   	AS CorCompany,
	|	DocumentTable.Ref							   	AS CorLot,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts 	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					   	AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentTable.OrderSales AND &SalesAgainstSeveralOrders
	|			THEN TableTypesOfStocks_.SalesOrder
	|		WHEN DocumentTable.OrderSales AND NOT &SalesAgainstSeveralOrders
	|			THEN DocumentTable.SalesOrder
	|		ELSE DocumentTable.Ref
	|	END 												AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	(DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			AND TableTypesOfStocks_.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods), VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	)
	|	AND (TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region Transfer_ConsignedGoods_SaleWithDeferredTransferOfTitle
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED									   	AS CorCompany,
	|	DocumentTable.Ref							   	AS CorLot,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts 	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					   	AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region Sale_Goods_SaleWithoutTransferOfOwnership
	
	If Not DocumentObject = Undefined 
		And ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
			And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.DateOfTransferOfTitleToGoods AS Period,
	|	DocumentTable.Ref 						AS Ref,
	|	UNDEFINED									AS DocumentSource,
	|	UNDEFINED									AS SourceDocumentPeriod,
	|	UNDEFINED 									AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_							AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 										AS CorCompany,
	|	TableTypesOfStocks_.ItemsLocationAttributes 		AS CorItemsLocationAttributes,
	|	UNDEFINED										AS CorInventoryOwnerAttribute,
	|	UNDEFINED										AS CorLot,
	|	UNDEFINED										AS LotVendorAttributesCorr,
	|	TableTypesOfStocks_.AccountingDimensionByPartners		AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN DocumentTable.OrderSales AND &SalesAgainstSeveralOrders
	|			THEN TableTypesOfStocks_.SalesOrder
	|		WHEN DocumentTable.OrderSales AND NOT &SalesAgainstSeveralOrders
	|			THEN DocumentTable.SalesOrder
	|		ELSE DocumentTable.Ref
	|	END 												AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|		INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|			ON TRUE
	|WHERE
	|	(DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			AND TableTypesOfStocks_.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods), VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	)
	|	AND (TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region SaleOfGoodsAndServices_ConsignedGoods_SaleWithDeferredTransferOfTitle
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped) Then
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.DateOfTransferOfTitleToGoods AS Period,
	|	DocumentTable.Ref 						AS Ref,
	|	UNDEFINED									AS DocumentSource,
	|	UNDEFINED									AS SourceDocumentPeriod,
	|	UNDEFINED 									AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_							AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 										AS CorCompany,
	|	TableTypesOfStocks_.ItemsLocationAttributes 		AS CorItemsLocationAttributes,
	|	UNDEFINED										AS CorInventoryOwnerAttribute,
	|	UNDEFINED										AS CorLot,
	|	UNDEFINED										AS LotVendorAttributesCorr,
	|	TableTypesOfStocks_.AccountingDimensionByPartners		AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN DocumentTable.OrderSales AND &SalesAgainstSeveralOrders
	|			THEN TableTypesOfStocks_.SalesOrder
	|		WHEN DocumentTable.OrderSales AND NOT &SalesAgainstSeveralOrders
	|			THEN DocumentTable.SalesOrder
	|		ELSE DocumentTable.Ref
	|	END 												AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	&AccountingSectionCommissionItemInTransit      AS AccountingSection,		
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|		INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|			ON TRUE
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR NOT &ToReturnReusablePackage)
	// this condition must be kept exactly this way in order to maintain performance on the Postgresql DBMS
	|	AND CASE
	|			WHEN NOT TableTypesOfStocks_.Ref IS NULL
	|				THEN TRUE
	|		END";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	TableTypesOfStocks_.AccountingDimensionByPartners	AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	TableTypesOfStocks_.RowID							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
EndFunction

#EndRegion

Function RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts)
	
	TempTableName = "TTMovementCounterpartyCounterparty";
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = 
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|
	|	DocumentData.CorPartner AS CorPartner,
	|	DocumentData.CorCounterparty AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END AS CorLineOfBusiness,
	|	DocumentData.CorContract AS CorContract,
	|	DocumentData.CorARAPObject AS CorARAPObject,
	|	VALUE(Enum.TypesOfDebtAmounts.CustomerAccountsReceivable) AS AmountType,
	|	VALUE(Enum.TypesOfDebtAmounts.CustomerAccountsReceivable) AS CorAmountType,
	|	&Currency AS Currency,
	|
	|	SUM(DocumentData.Sum) AS Sum,
	|	SUM(DocumentData.SumCompl) AS SumCompl,
	|	SUM(DocumentData.AmountInCurrency) AS AmountInCurrency,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	SUM(DocumentData.AmountInARAPCurrency) AS AmountInARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting AS CorCurrencyOfARAPAccounting,
	|	SUM(DocumentData.AdjAmountInARAPCurrency) AS AdjAmountInARAPCurrency,
	|
	|	DocumentData.SourceOfARAPFinancialAccountingGroup AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup AS CorSourceOfARAPFinancialAccountingGroup
	|INTO TTMovementCounterpartyCounterparty
	|FROM (
	|	SELECT
	|		&Period AS Period,
	|		VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		DataObjectOfCalculations.Department AS Department,
	|
	|		DocumentData.Partner AS Partner,
	|		DocumentData.Counterparty AS Counterparty,
	|		DocumentData.LineOfBusiness AS LineOfBusiness,
	|		DocumentData.Contract AS Contract,
	|		DataObjectOfCalculations.Ref AS ARAPObject,
	|
	|		VALUE(Catalog.Partners.OurEnterprise) AS CorPartner,
	|		DataObjectOfCalculations.Organization AS CorCounterparty,
	|		DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|		DocumentData.Contract AS CorContract,
	|		DataObjectOfCalculations.Ref AS CorARAPObject,
	|	
	|		CASE WHEN DocumentData.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN GoodsTable.AmountARAP
	|			WHEN DocumentData.Currency = &ManagementAccountingCurrency
	|				THEN GoodsTable.AmountIncludingVAT
	|			ELSE 
	|				CAST(GoodsTable.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		END AS Sum,
	|		CASE WHEN DocumentData.ARAPCurrency = &LocalAccountingCurrency
	|				THEN GoodsTable.AmountARAP
	|			WHEN DocumentData.Currency = &LocalAccountingCurrency
	|				THEN GoodsTable.AmountIncludingVAT
	|			ELSE 
	|				CAST(GoodsTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		END AS SumCompl,
	|		GoodsTable.AmountIncludingVAT AS AmountInCurrency,
	|
	|		DocumentData.ARAPCurrency AS ARAPCurrency,
	|		GoodsTable.AmountARAP AS AmountInARAPCurrency,
	|
	|		DocumentData.ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|		GoodsTable.AmountARAP AS AdjAmountInARAPCurrency,
	|
	|		DataObjectOfCalculations.Ref AS SourceOfARAPFinancialAccountingGroup,
	|		DataObjectOfCalculations.Ref AS CorSourceOfARAPFinancialAccountingGroup
	|	FROM
	|		DocumentDataHeader AS DocumentData
	|		LEFT JOIN DocumentDataTableItems AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|		LEFT JOIN Catalog.ARAPObjects AS DataObjectOfCalculations
	|			ON DocumentData.Contract = DataObjectOfCalculations.Object
	|				AND NOT DataObjectOfCalculations.DeletionMark
	|	WHERE
	|		DataObjectOfCalculations.Organization <> DocumentData.Organization
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&Period AS Period,
	|		VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices) AS BusinessOperation,
	|		DataObjectOfCalculations.Organization AS Organization,
	|		DataObjectOfCalculations.Department AS Department,
	|
	|		VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|		DocumentData.Organization AS Counterparty,
	|		DocumentData.LineOfBusiness AS LineOfBusiness,
	|		DocumentData.Contract AS Contract,
	|		DataObjectOfCalculations.Ref AS ARAPObject,
	|
	|		DocumentData.Partner AS CorPartner,
	|		DocumentData.Counterparty AS CorCounterparty,
	|		DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|		DocumentData.Contract AS CorContract,
	|		DataObjectOfCalculations.Ref AS CorARAPObject,
	|	
	|		CASE WHEN DocumentData.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN GoodsTable.AmountARAP
	|			WHEN DocumentData.Currency = &ManagementAccountingCurrency
	|				THEN GoodsTable.AmountIncludingVAT
	|			ELSE 
	|				CAST(GoodsTable.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		END AS Sum,
	|		CASE WHEN DocumentData.ARAPCurrency = &LocalAccountingCurrency
	|				THEN GoodsTable.AmountARAP
	|			WHEN DocumentData.Currency = &LocalAccountingCurrency
	|				THEN GoodsTable.AmountIncludingVAT
	|			ELSE 
	|				CAST(GoodsTable.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		END AS SumCompl,
	|		GoodsTable.AmountIncludingVAT AS AmountInCurrency,
	|
	|		DocumentData.ARAPCurrency AS ARAPCurrency,
	|		GoodsTable.AmountARAP AS AmountInARAPCurrency,
	|
	|		DocumentData.ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|		GoodsTable.AmountARAP AS AdjAmountInARAPCurrency,
	|
	|		DataObjectOfCalculations.Ref AS SourceOfARAPFinancialAccountingGroup,
	|		DataObjectOfCalculations.Ref AS CorSourceOfARAPFinancialAccountingGroup
	|	FROM
	|		DocumentDataHeader AS DocumentData
	|		LEFT JOIN DocumentDataTableItems AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|		LEFT JOIN Catalog.ARAPObjects AS DataObjectOfCalculations
	|			ON DocumentData.Contract = DataObjectOfCalculations.Object
	|			AND NOT DataObjectOfCalculations.DeletionMark
	|	WHERE
	|		DataObjectOfCalculations.Organization <> DocumentData.Organization
	|
	|	) AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Period,
	|	DocumentData.BusinessOperation,
	|   DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE)
	|			THEN DocumentData.LineOfBusiness
	|	END,
	|	DocumentData.Contract,
	|	DocumentData.ARAPObject,
	|	DocumentData.CorPartner,
	|	DocumentData.CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DocumentData.CorLineOfBusiness.VendorARAP, FALSE) THEN
	|			DocumentData.CorLineOfBusiness
	|	END,
	|	DocumentData.CorContract,
	|	DocumentData.CorARAPObject,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.CorCurrencyOfARAPAccounting,
	|	DocumentData.SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.CorSourceOfARAPFinancialAccountingGroup
	|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	RecordsCounterpartyCounterparty.Period                        AS Period,
	|	RecordsCounterpartyCounterparty.BusinessOperation         AS BusinessOperation,
	|	RecordsCounterpartyCounterparty.Organization                   AS Organization,
	|	RecordsCounterpartyCounterparty.Department                 AS Department,
	|	RecordsCounterpartyCounterparty.LineOfBusiness       AS LineOfBusiness,
	|
	|	RecordsCounterpartyCounterparty.Partner                       AS Partner,
	|	RecordsCounterpartyCounterparty.Counterparty                    AS Counterparty,
	|	RecordsCounterpartyCounterparty.Contract                       AS Contract,
	|	RecordsCounterpartyCounterparty.ARAPObject                AS ARAPObject,
	|
	|	RecordsCounterpartyCounterparty.CorPartner                    AS CorPartner,
	|	RecordsCounterpartyCounterparty.CorCounterparty                 AS CorCounterparty,
	|	RecordsCounterpartyCounterparty.CorLineOfBusiness    AS CorLineOfBusiness,
	|	RecordsCounterpartyCounterparty.CorContract                    AS CorContract,
	|	RecordsCounterpartyCounterparty.CorARAPObject             AS CorARAPObject,
	|	RecordsCounterpartyCounterparty.AmountType                      AS AmountType,
	|	RecordsCounterpartyCounterparty.CorAmountType                   AS CorAmountType,
	|	RecordsCounterpartyCounterparty.Currency                        AS Currency,
	|
	|	RecordsCounterpartyCounterparty.Sum                         AS Sum,
	|	RecordsCounterpartyCounterparty.SumCompl                     AS SumCompl,
	|	RecordsCounterpartyCounterparty.AmountInCurrency                  AS AmountInCurrency,
	|
	|	RecordsCounterpartyCounterparty.ARAPCurrency          AS ARAPCurrency,
	|	RecordsCounterpartyCounterparty.AmountInARAPCurrency    AS AmountInARAPCurrency,
	|	RecordsCounterpartyCounterparty.CorCurrencyOfARAPAccounting       AS CorCurrencyOfARAPAccounting,
	|	RecordsCounterpartyCounterparty.AdjAmountInARAPCurrency AS AdjAmountInARAPCurrency,
	|
	|	RecordsCounterpartyCounterparty.SourceOfARAPFinancialAccountingGroup           AS SourceOfARAPFinancialAccountingGroup,
	|	RecordsCounterpartyCounterparty.CorSourceOfARAPFinancialAccountingGroup        AS CorSourceOfARAPFinancialAccountingGroup
	|
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueriesArray = New Array;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment Then
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN &CustomerCounterparty
	|		ELSE &Counterparty
	|	END AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TableTypesOfStocks_.VATLocal AS SumCompl,
	|	TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan AS SumMan,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|
	|	UNDEFINED AS ARAPObject,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (&InventoryTypesOwn)
	|	AND (TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OwnGoods)
	|			OR TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND NOT &ToReturnReusablePackage)";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment Then
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	CatAssignments.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN &CustomerCounterparty
	|		ELSE &Counterparty
	|	END AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	GoodsTable.VATLocal AS SumCompl,
	|	GoodsTable.AmountIncludingVATMan - GoodsTable.AmountExcludingVATMan AS SumMan,
	|	GoodsTable.AmountIncludingVATMan AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	
	|	UNDEFINED AS ARAPObject,
	|	GoodsTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTOperationServices AS GoodsTable
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON GoodsTable.ItemsLocationAttributesAssignment = CatAssignments.Ref
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped Then
	
	QueryText = 
	"SELECT
	|	&DateOfTransferOfTitleToGoods AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN &CustomerCounterparty
	|		ELSE &Counterparty
	|	END AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TableTypesOfStocks_.VATLocal AS SumCompl,
	|	TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan AS SumMan,
	|	TableTypesOfStocks_.AmountIncludingVATMan AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
	|
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (&InventoryTypesOwn)
	|	AND (TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OwnGoods)
	|			OR TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND NOT &ToReturnReusablePackage)";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped Then
	
	QueryText = 
	"SELECT
	|	&DateOfTransferOfTitleToGoods AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	CatAssignments.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|			THEN &CustomerCounterparty
	|		ELSE &Counterparty
	|	END AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	GoodsTable.VATLocal AS SumCompl,
	|	GoodsTable.AmountIncludingVATMan - GoodsTable.AmountExcludingVATMan AS SumMan,
	|	GoodsTable.AmountIncludingVATMan AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	
	|	GoodsTable.ARAPObject AS ARAPObject,
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	TTOperationServices AS GoodsTable
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON GoodsTable.ItemsLocationAttributesAssignment = CatAssignments.Ref
	|";
	
	QueriesArray.Add(QueryText);
	
	EndIf;

	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		And DocumentObject.Status = Enums.StatusesOfCustomerInvoices.Shipped Then
	
		QueryText = 
		"SELECT
		|	&Period AS Period,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle) AS AssetRef,
		|	&Counterparty AS Dimension,
		|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
		|
		|	TableTypesOfStocks_.VATLocal AS SumCompl,
		|	TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan AS SumMan,
		|	TableTypesOfStocks_.AmountIncludingVATMan AS AmountIncludingVAT,
		|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVAT,
		|
		|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
		|	TableTypesOfStocks_.RowID AS FinRecordID,
		|	&BusinessTransactionSetting AS BusinessTransactionSetting
		|	
		|FROM
		|	TTTableTypesOfStocks AS TableTypesOfStocks_
		|
		|WHERE
		|	TableTypesOfStocks_.InventoryType IN (&InventoryTypesOwn)
		|	AND (TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OwnGoods)
		|			OR TableTypesOfStocks_.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
		|				AND NOT &ToReturnReusablePackage)";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTMovementCounterpartyCounterparty", QueryTexts) Then
		RequestTextTemporaryMovementTableCounterpartyCounterparty(Query, QueryTexts);
	EndIf;
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());

	QueryText = QueryText
		+ TMCommonUse.QuerySeparatorInJoin()
		+ OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches(, True);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters)
	
	RegisterName = "Delivery";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
	 Or DocumentObject.Status = Enums.StatusesOfCustomerInvoices.ForPrepayment
	 Or Not DocumentObject.DeliveryIsRequired
	 Or DocumentObject.DeliveryMethod25 = Enums.TransportMethods25.SelfPickup
	 Or DocumentObject.DeliveryMethod25 = Enums.TransportMethods25.OurCourier Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentHeader.DeliveryPlanning AS DeliveryPlanning,
	|	GoodsTable.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(&Period, DAY) AS Period,
	|	DocumentHeader.Organization AS Organization,
	|	VALUE(Enum.DeliveryTypes.OutgoingInfo) AS DeliveryType,
	|	BEGINOFPERIOD(&Period, DAY) AS DateOfShipment,
	|	DocumentHeader.DeliveryMethod25 AS DeliveryMethod,
	|	CASE
	|		WHEN DocumentHeader.DeliveryMethod25 = VALUE(Enum.TransportMethods25.ByCarrier)
	|			THEN DocumentHeader.CarrierPartner
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS Carrier,
	|	GoodsTable.Warehouse AS Sender,
	|	ISNULL(TableWarehousesDeliveryDetails.WarehousePoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS SenderPoint,
	|	ISNULL(TableWarehousesDeliveryDetails.AreaOfWarehouse, VALUE(Catalog.DeliveryZones.EmptyRef)) AS Sender_Area,
	|	CASE
	|		WHEN DocumentHeader.DeliveryToCarrier
	|			THEN DocumentHeader.CarrierPartner
	|		ELSE DocumentHeader.Partner
	|	END AS Recipient,
	|	CASE
	|		WHEN DocumentHeader.DeliveryToCarrier
	|			THEN DocumentHeader.CarrierDeliveryPoint
	|		ELSE DocumentHeader.DeliveryPoint
	|	END AS RecipientPoint,
	|	CASE
	|		WHEN DocumentHeader.DeliveryToCarrier
	|			THEN DocumentHeader.CarrierSDeliveryArea
	|		ELSE DocumentHeader.DeliveryZone
	|	END AS Recipient_Area,
	|	CASE
	|		WHEN &CustomImplementation
	|				AND NOT GoodsTable.SalesOrder.ThisIsOrderAsInvoice
	|			THEN GoodsTable.SalesOrder
	|		ELSE &Ref
	|	END AS ReferenceOrder,
	|	UNDEFINED AS Trip,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.DeliveryLineCode AS RowCode,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END AS PlanningDocument,
	|	1 AS Arm,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.Count AS ToDeliver,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS ToTrip,
	|	0 AS InTrip,
	|	0 AS InTransit,
	|	0 AS Delivered,
	|	0 AS Canceled,
	|	0 AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	&OperationLevel AS OperationLevel,
	|	NOT DocumentHeader.DeliveryToCarrier AS ThisIsFinalArm,
	|	1 AS MinimumArmNumber,
	|	TRUE AS PrimaryRegisterRecord,
	|	BEGINOFPERIOD(DocumentHeader.Date, DAY) AS SourceShipmentDate,
	|	GoodsTable.Purpose AS Purpose
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|		LEFT JOIN Document.CustomerInvoice AS DocumentHeader
	|		ON GoodsTable.Ref = DocumentHeader.Ref
	|		LEFT JOIN Document.CustomerInvoice.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
	|		ON GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref
	|			AND GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &DeliveryIsRequired
	|	AND &Status <> VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.SelfPickup)
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.OurCourier)
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND (&CustomImplementation
	|				AND (GoodsTable.RowCode = 0
	|					OR GoodsTable.SalesOrder.ThisIsOrderAsInvoice = TRUE)
	|				AND VALUETYPE(GoodsTable.SalesOrder) IN (&AcceptableTypesOfDeliveryOrders)
	|			OR NOT &CustomImplementation)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentHeader.DeliveryPlanning,
	|	GoodsTable.LineNumber,
	|	BEGINOFPERIOD(&Period, DAY),
	|	DocumentHeader.Organization,
	|	VALUE(Enum.DeliveryTypes.OutgoingInfo),
	|	BEGINOFPERIOD(&Period, DAY),
	|	VALUE(Enum.TransportMethods25.ByCarrier),
	|	DocumentHeader.CarrierPartner,
	|	DocumentHeader.CarrierPartner,
	|	DocumentHeader.CarrierDeliveryPoint,
	|	DocumentHeader.CarrierSDeliveryArea,
	|	DocumentHeader.Partner,
	|	DocumentHeader.DeliveryPoint,
	|	DocumentHeader.DeliveryZone,
	|	CASE
	|		WHEN &CustomImplementation
	|				AND NOT GoodsTable.SalesOrder.ThisIsOrderAsInvoice
	|			THEN GoodsTable.SalesOrder
	|		ELSE &Ref
	|	END,
	|	UNDEFINED,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.DeliveryLineCode,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|			THEN &Ref
	|		ELSE UNDEFINED
	|	END,
	|	2,
	|	GoodsTable.Package,
	|	GoodsTable.Count,
	|	CASE
	|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	&OperationLevel,
	|	TRUE,
	|	0,
	|	FALSE,
	|	DATETIME(1, 1, 1),
	|	VALUE(Catalog.Assignments.EmptyRef)
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|		LEFT JOIN Document.CustomerInvoice AS DocumentHeader
	|		ON GoodsTable.Ref = DocumentHeader.Ref
	|		LEFT JOIN Document.CustomerInvoice.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
	|		ON GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref
	|			AND GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &DeliveryIsRequired
	|	AND &Status <> VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.SelfPickup)
	|	AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.OurCourier)
	|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND DocumentHeader.DeliveryToCarrier
	|	AND (&CustomImplementation
	|				AND (GoodsTable.RowCode = 0
	|					OR GoodsTable.SalesOrder.ThisIsOrderAsInvoice = TRUE)
	|				AND VALUETYPE(GoodsTable.SalesOrder) IN (&AcceptableTypesOfDeliveryOrders)
	|			OR NOT &CustomImplementation)";
	
	AcceptableTypesOfDeliveryOrders = New Array; // Array of Type
	AcceptableTypesOfDeliveryOrders.Add(Type("DocumentRef.SalesOrder"));
	AcceptableTypesOfDeliveryOrders.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	Query.SetParameter("AcceptableTypesOfDeliveryOrders", AcceptableTypesOfDeliveryOrders);
	
	QueryText = StrReplace(QueryText, "Document.CustomerInvoice.Goods", "DocumentDataTableItems");
	QueryText = StrReplace(QueryText, "Document.CustomerInvoice AS DocumentHeader", "DocumentDataHeader AS DocumentHeader");
	QueryText = StrReplace(QueryText, "GoodsTable.Products.ItemsType", "GoodsTable.ProductsTypeOfProducts");
	QueryText = StrReplace(QueryText, "GoodsTable.SalesOrder.ThisIsOrderAsInvoice", "GoodsTable.SalesOrderIsOrderAsInvoice");
	
	SynonymForDocumentTable = "DataTable";
	GoodsDelivery.SetParametersOfEventRequest(Query, AddlParameters);
	GoodsDelivery.AddDocumentReflectionRequest(Query, Registers, QueryTexts, QueryText, SynonymForDocumentTable);
	
	Return QueryText;
	
EndFunction

Function QueryTextBonusPoints(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "BonusPoints";
	
	If Not BonusPointsServer.ItIsRequiredToAddRegisterRegisteredRecordsBonusPoints(DocumentObject.Ref) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateToProcess AS DateToProcess,
	|	BonusPoints.RecordType AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued,
	|	SUM(BonusPoints.ToWriteOff) AS ToWriteOff
	|FROM
	|	TTBonusPoints AS BonusPoints
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.Period,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.RecordType
	|HAVING
	|	SUM(BonusPoints.Accrued) <> 0
	|	OR SUM(BonusPoints.ToWriteOff) <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";

	QueryText = 
	"SELECT
	|	TabularSection.AccrualDate AS Period,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS ValidityStartDate,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateToProcess,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner,
	|	TabularSection.AmountOfBonusPoints AS Accrued,
	|	0 AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	DocumentDataTableAccumulationOfBonusPoints AS TabularSection
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON TabularSection.Ref = DocumentDataHeader.Ref
	|WHERE
	|	TabularSection.AccrualDate <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.DateOfDeduction AS Period,
	|	TabularSection.AccrualDate AS ValidityStartDate,
	|	&CurrentDate AS DateToProcess,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner,
	|	0 AS Accrued,
	|	TabularSection.AmountOfBonusPoints AS ToWriteOff
	|FROM
	|	DocumentDataTableAccumulationOfBonusPoints AS TabularSection
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON TabularSection.Ref = DocumentDataHeader.Ref
	|WHERE
	|	TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(&Period, DAY),
	|	DATETIME(1, 1, 1),
	|	&CurrentDate,
	|	VALUE(AccumulationRecordType.Expense),
	|	&LoyaltyProgram,
	|	&Partner,
	|	TabularSection.AmountOfBonusPointsToDeduction,
	|	0
	|FROM
	|	DocumentDataTableItems AS TabularSection
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON TabularSection.Ref = DocumentDataHeader.Ref
	|WHERE
	|	TabularSection.AmountOfBonusPointsToDeduction <> 0
	|	AND (TabularSection.RowCode = 0 
	|		OR ISNULL(TabularSection.SalesOrderIsOrderAsInvoice, NOT &UseAdvancedFeaturesOfSalesOrder))
	|";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN VALUE(Enum.SupplyOptions.ToSupply)
		|		ELSE VALUE(Enum.SupplyOptions.FromWarehouse)
		|	END AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	UNDEFINED AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.CustomerInvoice.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
		|		AND TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
		|		AND TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		|		AND TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|		AND TabPart.Ref.Status = VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
		|		AND (TabPart.RowCode = 0
		|			OR NOT TabPart.Ref.OrderSales
		|			OR ISNULL(TabPart.SalesOrder.ThisIsOrderAsInvoice, FALSE))";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.CustomerInvoice.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
		|		AND TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent)
		|		AND TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		|		AND TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfCustomerInvoices.InTransit),
		|			VALUE(Enum.StatusesOfCustomerInvoices.Shipped))
		|		AND (TabPart.RowCode = 0
		|			OR NOT TabPart.Ref.OrderSales
		|			OR ISNULL(TabPart.SalesOrder.ThisIsOrderAsInvoice, FALSE))";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		
		CreationCommand =
			Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(GenerationCommands);
		If CreationCommand <> Undefined Then
			
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand, 
				"BusinessOperation", 
				Enums.BusinessTransactions.TransferOfTitleToGoods,
				DataCompositionComparisonType.NotEqual);
			
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi bán cho khách hàng';
												|ru = 'Акт о расхождениях после реализации клиенту';
												|en = 'Customer invoice dispute'; fa = 'Customer invoice dispute';
												|it = 'Atto di divergenza dopo il realizzo al cliente';
												|pl = 'Sporządzanie protokołów o odchyleniu po sprzedaży klientowi.';
												|tr = 'Müşteriye satış sonrası tutarsızlık raporu'");
		EndIf;
		
		CreationCommand =
			Documents.DiscrepancyReportFollowingShipment.AddGenerateCommand(GenerationCommands);
		If CreationCommand <> Undefined Then
			
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand, 
				"BusinessOperation", 
				Enums.BusinessTransactions.TransferOfTitleToGoods,
				DataCompositionComparisonType.Equal);
			
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và chuyển giao quyền sở hữu';
												|ru = 'Акт о расхождениях после отгрузки товаров клиенту и перехода права собственности';
												|en = 'Sales dispute after goods shipment to customer and transfer of title to goods'; fa = 'Sales dispute after goods shipment to customer and transfer of title to goods';
												|it = 'Sales dispute after goods shipment to customer and transfer of title to goods';
												|pl = 'Sales dispute after goods shipment to customer and transfer of title to goods';
												|tr = 'Ürünlerin müşteri tarafında satış uyuşmazlığıyla karşılaşması ve mülkiyetin devrinde tutarsızlıkların beyanı'");
		EndIf;
		
	EndIf;
	
	Documents.ReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	
	Documents.ReturnablePackagingRedemptionByCustomer.AddGenerateCommand(GenerationCommands);
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.RequestForReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	
	Documents.SaleAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCreateReportBasedOnPaymentInvoiceCommand(GenerationCommands);
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	#Region Documents_DeliveryOrder
	CreationCommand = Documents.DeliveryOrder.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		
		AdvancedOrderOptions = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"DeliveryIsRequired", 
			True,
			DataCompositionComparisonType.Equal);
		
		If AdvancedOrderOptions Then
			
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand,
				"OrderSales", 
				False,
				DataCompositionComparisonType.Equal);
			
		EndIf;
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"DeliveryPlanning", 
			Enums.DeliveryPlanningKinds.SeparateDocument,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	#EndRegion
	
	
	CustomerInvoiceLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure


// Adds the command to create the document "Sales of goods and services".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CustomerInvoice.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CustomerInvoice);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the command to create the document "Sales of goods and services".
// 
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	ValueTableRow, Undefined -
//
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.SaleOfGoodsAndServicesCreatedOnBasisOfOrder";
		CreateBasedOnCommand.Id = "CreateByOrderReference";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CustomerInvoice);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the command to create the document "Sales of goods and services".
// 
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	ValueTableRow, Undefined -
//
Function AddCommandToCreateTransferOfOwnershipBasedOnOrder(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.CustomerInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler =
			"GenerationByReferenceTMClient.TransferOfOwnershipBasedOnOrder";
		CreateBasedOnCommand.Id = "TransferOfOwnershipBasedOnOrder";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Chuyển giao quyền sở hữu';
												|ru = 'Переход права собственности';
												|en = 'Transfer of title to goods'; fa = 'انتقال مالکیت کالا';
												|it = 'Trasferimento diritti di proprietà';
												|pl = 'Przejście prawa własności';
												|tr = 'Mülkiyet hakkı devri'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseShipmentWithDeferredTransferOfTitle2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command to create the document "Sales of goods and services".
// 
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	ValueTableRow, Undefined -
//
Function AddCreateBasedOnRightsTransferReportCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.DeedOfTransfer";
		CreateBasedOnCommand.Id = "DeedOfTransfer";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Biên bản chuyển giao quyền sở hữu';
												|ru = 'Акт на передачу прав';
												|en = 'Deed of transfer'; fa = 'صورتجلسه تحویل';
												|it = 'Atto di trasferimento dei diritti';
												|pl = 'Protokół przekazania praw';
												|tr = 'Yetki devir senedi'");
		CreateBasedOnCommand.FunctionalOptions = "UseDeedsOfTransfer";
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Returns the Query Text for filling out the document based on the client's order.
//
// Returns:
//  String -
//
Function QueryTextForFillingInBasedOnOrder() Export
	
	QueryText =
	"SELECT
	|	SalesOrder.Ref                AS SalesOrder,
	|	SalesOrder.Partner               AS Partner,
	|	SalesOrder.Counterparty            AS Counterparty,
	|	SalesOrder.ContactPerson        AS ContactPerson,
	|	SalesOrder.Contract               AS Contract,
	|	SalesOrder.Organization           AS Organization,
	|	SalesOrder.PaymentMethod           AS PaymentMethod,
	|	SalesOrder.Terms            AS Terms,
	|	SalesOrder.LoyaltyCard       AS LoyaltyCard,
	|	SalesOrder.SalesOpportunity                AS SalesOpportunity,
	|	SalesOrder.Currency                AS Currency,
	|	SalesOrder.Currency                AS ARAPCurrency,
	|	SalesOrder.PaymentSchedule          AS PaymentSchedule,
	|	SalesOrder.Department         AS Department,
	|	SalesOrder.DateOfShipment          AS DateOfShipment,
	|	SalesOrder.ThisIsOrderAsInvoice       AS ThisIsOrderAsInvoice,
	|	CASE
	|		WHEN
	|			SalesOrder.Warehouse.IsFolder AND SalesOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|		THEN
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE
	|			SalesOrder.Warehouse
	|	END AS Warehouse,
	|	CASE
	|		WHEN
	|			SalesOrder.Warehouse.IsFolder AND SalesOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ItIsForbiddenToSelectWarehouseGroup,
	|	SalesOrder.PriceIncludesVAT       AS PriceIncludesVAT,
	|	CASE 
	|		WHEN
	|			SalesOrder.VATTaxation IN (
	|					VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|					VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|		THEN 
	|			VALUE(Enum.VATTaxationTypes.ExportSale)
	|		ELSE 
	|			SalesOrder.VATTaxation
	|	END AS VATTaxation,
	|	SalesOrder.BusinessOperation AS BusinessOperation,
	|	SalesOrder.NotShipInInstallments    AS NotShipInInstallments,
	|	SalesOrder.DeliveryAddress         AS DeliveryAddress,
	|	SalesOrder.Warehouse.UseWarehouseManagemantSystemForGoodsIssue   AS AdvancedWarehousingOnShipment,
	|
	|	SalesOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	SalesOrder.Status                AS DocumentStatus,
	|	NOT SalesOrder.Posted
	|		AND NOT &EnterOnBasisOfUnverified AS ThereAreErrorsPosted,
	|	TRUE                             AS ThereAreErrorsStatus,
	|
	|	SalesOrder.BankAccount                 AS CompanyBankAccount,
	|	SalesOrder.CounterpartyBankAccount      AS CounterpartyBankAccount,
	|	SalesOrder.Shipper               AS Shipper,
	|	SalesOrder.GoodsRecipient                AS GoodsRecipient,
	|	SalesOrder.ShipperBankAccount AS ShipperBankAccount,
	|	SalesOrder.GoodsRecipientBankAccount  AS GoodsRecipientBankAccount,
	|	SalesOrder.ToReturnReusablePackage      AS ToReturnReusablePackage,
	|	SalesOrder.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
	|	SalesOrder.PackageDepositIsRequired           AS PackageDepositIsRequired,
	|	CASE
	|		WHEN &ToUseTermsOfSales 
	|			THEN SalesOrder.Terms.ScheduleOfPackageReturn
	|		ELSE VALUE(Catalog.BusinessCalendars.EmptyRef)
	|	END                                       AS ScheduleOfPackageReturn,
	|	CASE
	|		WHEN &ToUseTermsOfSales 
	|			THEN SalesOrder.Terms.CalculatePackageReturnDateAccordingToCalendar
	|		ELSE FALSE
	|	END                                       AS CalculatePackageReturnDateAccordingToCalendar,
	|
	|	SalesOrder.DiscountsMarkups.(
	|		ConnectionKey,
	|		DiscountMarkup,
	|		Sum
	|	) AS DiscountsMarkups,
	|	SalesOrder.DeliveryAddressFieldValues     AS DeliveryAddressFieldValues,
	|	SalesOrder.DeliveryAddressValue AS DeliveryAddressValue,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery20
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN VALUE(Enum.TransportMethods.EmptyRef)
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryMethod
	|	END AS DeliveryMethod,
	|
	|	CASE
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryMethod25
	|		ELSE VALUE(Enum.TransportMethods25.EmptyRef)
	|	END AS DeliveryMethod25,
	|
	|	CASE
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryPoint
	|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
	|	END AS DeliveryPoint,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN VALUE(Catalog.DeliveryZones.EmptyRef)
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryZone
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryZone
	|	END AS DeliveryZone,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN VALUE(Catalog.Partners.EmptyRef)
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.CarrierPartner
	|		WHEN SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.CarrierPartner
	|	END AS CarrierPartner,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN DATETIME(1, 1, 1)
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryTimeFrom
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryTimeFrom
	|	END AS DeliveryTimeFrom,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN DATETIME(1, 1, 1)
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryTimeTo
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.DeliveryTimeTo
	|	END AS DeliveryTimeTo,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN """"
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.AdditionalDeliveryInformation
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.AdditionalDeliveryInformation
	|	END AS AdditionalDeliveryInformation,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN FALSE
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.SpecialTransportationConditions
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.SpecialTransportationConditions
	|	END AS SpecialTransportationConditions,
	|
	|	CASE
	|		WHEN NOT &UsedDelivery
	|				OR &UsedDelivery25
	|					AND SalesOrder.ThisIsOrderAsInvoice
	|			THEN """"
	|		WHEN &UsedDelivery25
	|				AND NOT SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.SpecialTransportationConditionsDescription
	|		WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND SalesOrder.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				OR SalesOrder.ThisIsOrderAsInvoice
	|			THEN SalesOrder.SpecialTransportationConditionsDescription
	|	END AS SpecialTransportationConditionsDescription,
	|
	|	SalesOrder.UISStateContractStep            AS UISStateContractStep,
	|	SalesOrder.ARAPObjectSettings                AS ARAPObjectSettings,
	|	SalesOrder.LineOfBusiness        AS LineOfBusiness,
	|	SalesOrder.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction
	|
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.Ref = &SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
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
	|			DocumentShipments = &SalesOrder
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
		|	ReferenceOrder = &SalesOrder
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

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.PriceAnalysis.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	ReportCommand = Reports.ARAPAccountingStatementByReturnablePackagingProvided.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		Reports.SalesProfitabilityAssessment2_5.AddReportCommand(ReportsCommands);
	Else
		Reports.SalesProfitabilityAssessment.AddReportCommand(ReportsCommands);
	EndIf;
	
	Reports.DiscountsAppliedInDocument.AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfActImplementationCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	If AccessRight("View", Metadata.Reports.ActualProductCost) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager			= Metadata.Reports.ActualProductCost.FullName();
		ReportCommand.Presentation		= NStr("vi = 'Giá vốn sản phẩm thực tế';
												|ru = 'Фактическая себестоимость продукции';
												|en = 'Actual product cost'; fa = 'بهای واقعی محصول';
												|it = 'Costo di produzione effettivo';
												|pl = 'Faktyczne koszty własne produkcji';
												|tr = 'İmal edilen ürünlerin gerçek maliyeti'");
		ReportCommand.VariantKey 		= "ActualCostOfProductionContext";
		ReportCommand.Order 			= 50;
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance			= "Important";
				
	EndIf;
	CustomerInvoiceLocalization.AddReportCommands(ReportsCommands, Parameters);

	ReportCommand = Reports.StateOfDelivery.AddReportCommand(
		ReportsCommands,
		Parameters,
		"DeliveryStateContext");
	
	If ReportCommand <> Undefined Then
		
		Operations = New Array; // Array of EnumRef.BusinessTransactions
		Operations.Add(Enums.BusinessTransactions.SalesViaCommissionAgent);
		Operations.Add(Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit);
		Operations.Add(Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
		Operations.Add(Enums.BusinessTransactions.TransferOfTitleToGoods);
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			Metadata.Documents.CustomerInvoice.Attributes.BusinessOperation.Name,
			Operations,
			DataCompositionComparisonType.NotInList);
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			Metadata.Documents.CustomerInvoice.Attributes.Organization.Name,
			Catalogs.Companies.ManagementCompany,
			DataCompositionComparisonType.NotEqual);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ThisIsPartner = UserRightsCached.ThisIsPartner();
	
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership = New Structure;
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership.Insert("Attribute",
		Metadata.Documents.CustomerInvoice.Attributes.BusinessOperation.Name);
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership.Insert("ComparisonType", ComparisonType.NotEqual);
	ConditionOfVisibilityOfPrintedFormsTransferOfOwnership.Insert("Value",
		Enums.BusinessTransactions.TransferOfTitleToGoods);
	
	If Not ThisIsPartner Then
		// Expenditure invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ExpenseToPrint";
		PrintCommand.Presentation = NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
										|ru = 'Расходная накладная';
										|en = 'Sales invoice'; fa = 'فاکتور فروش';
										|it = 'Bolla di consegna';
										|pl = 'Faktura wydanie na zewnątrz';
										|tr = 'Satış faturası'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 10;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
	EndIf;

	If ThisIsPartner Or GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Sale of goods
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Invoice";
		PrintCommand.Presentation = NStr("vi = 'Giao hàng';
										|ru = 'Реализация товаров';
										|en = 'Goods sales'; fa = 'فروش کالا';
										|it = 'Vendita delle merci';
										|pl = 'Sprzedaż towarów';
										|tr = 'Malların satışı'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 11;
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Sale of goods (do not display discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Giao hàng (không hiển thị chiết khấu)';
										|ru = 'Реализация товаров (не выводить скидки)';
										|en = 'Goods sales (do not display discounts)'; fa = 'Goods sales (do not display discounts)';
										|it = 'Vendita delle merci (non visualizzare gli sconti)';
										|pl = 'Sprzedaż towarów (nie wyświetlać zniżki)';
										|tr = 'Malların satışı (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		PrintCommand.Order = 12;
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Sale of goods (display discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Invoice";
		PrintCommand.Presentation = NStr("vi = 'Giao hàng (hiển thị chiết khấu)';
										|ru = 'Реализация товаров (выводить скидки)';
										|en = 'Goods sales (display discounts)'; fa = 'Goods sales (display discounts)';
										|it = 'Vendita delle merci (visualizzare gli sconti)';
										|pl = 'Sprzedaż towarów (wyświetlać zniżki)';
										|tr = 'Malların satışı (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		PrintCommand.Order = 13;
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// The act on the provision of services
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCertificateOfRenderedServices";
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ';
										|ru = 'Акт об оказании услуг';
										|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
										|it = 'Atto di prestazione dei servizi';
										|pl = 'Protokół świadczenia usług';
										|tr = 'Hizmet tutanağı'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 14;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản';
												|ru = 'Акт';
												|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
												|it = 'Customer invoice — Services';
												|pl = 'Customer invoice — Services';
												|tr = 'Tutanak'");
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Act on the provision of services (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCertificateOfRenderedServices";
		PrintCommand.Id = "ActWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ (không hiển thị chiết khấu)';
										|ru = 'Акт об оказании услуг (не выводить скидки)';
										|en = 'Certificate of rendered services (do not display discounts)'; fa = 'Certificate of rendered services (do not display discounts)';
										|it = 'Atto di prestazione dei servizi (non visualizzare gli sconti)';
										|pl = 'Protokół świadczenia usług (nie wyświetlać zniżki)';
										|tr = 'Hizmet tutanağı (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.Order = 15;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Act on the provision of services (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCertificateOfRenderedServices";
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ (hiển thị chiết khấu)';
										|ru = 'Акт об оказании услуг (выводить скидки)';
										|en = 'Certificate of rendered services (display discounts)'; fa = 'Certificate of rendered services (display discounts)';
										|it = 'Atto di prestazione dei servizi (visualizzare gli sconti)';
										|pl = 'Protokół świadczenia usług (wyświetlać zniżki)';
										|tr = 'Hizmet tutanağı (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.Order = 16;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
	EndIf;

	If (Not ThisIsPartner And GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption"))
	 Or (ThisIsPartner And (GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption")
		 	Or GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption"))) Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 26;
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceForPaymentWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
										|ru = 'Счет на оплату (не выводить скидки)';
										|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
										|it = 'Fattura di pagamento (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		PrintCommand.Order = 27;
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
										|ru = 'Счет на оплату (выводить скидки)';
										|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
										|it = 'Fattura di pagamento (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		PrintCommand.Order = 28;
	EndIf;
	
	If (Not ThisIsPartner And GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption"))
	 Or (ThisIsPartner
		 And (GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption")
		 	Or GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption"))) Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax';
										|ru = 'Счет на оплату с факсимиле';
										|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
										|it = 'Fattura di pagamento in facsimile';
										|pl = 'Rachunek do płatności z faksymile';
										|tr = 'Kaşeli ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		PrintCommand.Order = 29;
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceWithFacsimileWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
										|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
										|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		PrintCommand.Order = 30;
	EndIf;

	If Not ThisIsPartner
		 And GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (выводить скидки)';
										|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
										|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		PrintCommand.Order = 31;
	EndIf;

	If AccessRight("Read", Metadata.Catalogs.QualityCertificates)
		And GetFunctionalOption("UseQualityCertificates") Then
		// Register of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesOfProductsRegister";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (đăng ký)';
										|ru = 'Сертификаты (реестр)';
										|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
										|it = 'Certificati (registro)';
										|pl = 'Certyfikaty (rejestr)';
										|tr = 'Sertifikalar (kayıt)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 33;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocuments";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
										|ru = 'Сертификаты (по каждой позиции документа)';
										|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
										|it = 'Certificati (per ogni voce del documento)';
										|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
										|tr = 'Sertifikalar (belgedeki her kalem için)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 34;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocumentsWithoutDuplicates";
		PrintCommand.Presentation = NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
										|ru = 'Сертификаты (по одному на сертификат)';
										|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
										|it = 'Certificati (uno per certificato)';
										|pl = 'Certyfikaty (po jednym na certyfikat)';
										|tr = 'Sertifikalar (sertifika başına bir tane)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 35;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
	EndIf;
	
	If Not ThisIsPartner Then
		// Task for the selection of goods
		PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																								"SelectionTask",
																								36);
		
		BusinessTransactions = New ValueList();
		BusinessTransactions.Add(Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
		BusinessTransactions.Add(Enums.BusinessTransactions.TransferOfTitleToGoods);
		
		AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
															"Status",
															Enums.StatusesOfCustomerInvoices.ForPrepayment,
															DataCompositionComparisonType.NotEqual);
		AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
															"BusinessOperation",
															BusinessTransactions,
															DataCompositionComparisonType.NotInList);
	EndIf;

	If Not ThisIsPartner
		 And GoodsDeliveryClientServer.UsedDelivery20() Then
		// Shipping Labels
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintingShippingLabels";
		PrintCommand.PrintManager = "DataProcessor.PrintPriceTagsAndLabels.Print";
		PrintCommand.Id = "ShippingLabel";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem giao hàng';
										|ru = 'Этикетки доставки';
										|en = 'Delivery labels'; fa = 'Delivery labels';
										|it = 'Etichette di consegna';
										|pl = 'Etykiety dostawy';
										|tr = 'Teslimat etiketleri'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 38;
		PrintCommand.VisibilityConditions.Add(ConditionOfVisibilityOfPrintedFormsTransferOfOwnership);
	EndIf;
	
	If Not ThisIsPartner And Constants.UseInternationalPrintingForms.Get() Then
		// Invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceInt";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 39;
	EndIf;
	
	If Not ThisIsPartner 
		And Not GetFunctionalOption("UseCustomerCommercialInvoices")
		And Constants.UseInternationalPrintingForms.Get() Then
		// Proforma invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceEn";
		PrintCommand.Presentation = NStr("vi = 'Proforma invoice (en)';
										|ru = 'Proforma invoice (en)';
										|en = 'Proforma invoice (en)'; fa = 'Proforma invoice (en)';
										|it = 'Proforma invoice (en)';
										|pl = 'Proforma invoice (en)';
										|tr = 'Proforma invoice (en)'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;  
	

	CustomerInvoiceLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	SynonymForTemplateForSaleOfGoodsAndServices = NStr("vi = 'Bán hàng';
														|ru = 'Реализация товаров';
														|en = 'Goods sales'; fa = 'فروش کالا';
														|it = 'Vendita delle merci';
														|pl = 'Sprzedaż towarów';
														|tr = 'Malların satışı'");
	If CommonClientServer.StructureProperty(PrintParameters, "UseSynonymForKit", False) Then
		SynonymForTemplateForSaleOfGoodsAndServices = PrintParameters.SynonymForTemplateForKit;
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"Invoice",
			SynonymForTemplateForSaleOfGoodsAndServices,
			FormPrintedFormInvoice(ObjectsArray, PrintObjects, PrintParameters),
			,
			"Document.CustomerInvoice.PF_MXL_GoodsSales");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InvoiceWithoutDiscounts") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InvoiceWithoutDiscounts",
			SynonymForTemplateForSaleOfGoodsAndServices,
			FormPrintedFormInvoice(ObjectsArray, PrintObjects, PrintParameters),
			,
			"Document.CustomerInvoice.PF_MXL_GoodsSales");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ExpenseToPrint") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ExpenseToPrint",
			NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
				|ru = 'Расходная накладная';
				|en = 'Sales invoice'; fa = 'فاکتور فروش';
				|it = 'Bolla di consegna';
				|pl = 'Faktura wydanie na zewnątrz';
				|tr = 'Satış faturası'"),
			CreatePrintedFormInvoice(ObjectsArray, PrintObjects),
			,
			"Document.CustomerInvoice.PF_MXL_ExpenseToPrint");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesOfProductsRegister") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesOfProductsRegister",
			NStr("vi = 'Giấy chứng nhận (đăng ký)';
				|ru = 'Сертификаты (реестр)';
				|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
				|it = 'Certificati (registro)';
				|pl = 'Certyfikaty (rejestr)';
				|tr = 'Sertifikalar (kayıt)'"),
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateRegistry");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocuments") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocuments",
			NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
				|ru = 'Сертификаты (по каждой позиции документа)';
				|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
				|it = 'Certificati (per ogni voce del documento)';
				|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
				|tr = 'Sertifikalar (belgedeki her kalem için)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocumentsWithoutDuplicates") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates",
			NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
				|ru = 'Сертификаты (по одному на сертификат)';
				|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
				|it = 'Certificati (uno per certificato)';
				|pl = 'Certyfikaty (po jednym na certyfikat)';
				|tr = 'Sertifikalar (sertifika başına bir tane)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
		
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	CustomerInvoiceLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else

		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.CustomerInvoice.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	CustomerInvoiceLocalization.CreateSetOfPrintedForms(ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);
			
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"Invoice");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormInvoice(PrintKit.Objects, PrintObjects, Undefined));
	EndDo;
		
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceWithoutDiscounts");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormInvoice(PrintKit.Objects, PrintObjects, New Structure("DisplayDiscounts_", False)));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ExpenseToPrint");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			CreatePrintedFormInvoice(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"Act");
	PrintParameters.Delete("DisplayDiscounts_");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCertificateOfRenderedServices.FormPrintedFormOfActOnProvisionOfServices(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ActWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCertificateOfRenderedServices.FormPrintedFormOfActOnProvisionOfServices(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoice");
	PrintParameters.Delete("DisplayDiscounts_");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;

	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceForPaymentWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceWithFacsimile");
	PrintParameters.Delete("DisplayDiscounts_");
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;

	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceWithFacsimileWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceInt");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceEn");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedProformaInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
																									PrintFormsSet,
																									ObjectsArray,
																									"GoodsPickingPlacementJob");
	
	PrintParameters.Insert("JobType", "SelectionTask");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerInvoice", PrintKit.Objects);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.CreateTaskForProductSelectionAndPlacement(StructureOfTypes,
																										PrintObjects,
																										PrintParameters));
	EndDo;

	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CertificatesOfProductsRegister");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(PrintKit.Objects, PrintObjects));
	EndDo;

	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CertificatesProductImagesFromDocuments");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(PrintKit.Objects, PrintObjects));
	EndDo;
			
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CertificatesProductImagesFromDocumentsWithoutDuplicates");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(PrintKit.Objects, PrintObjects));
	EndDo;

	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.CustomerInvoice",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ExpenseToPrint", NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
																										|ru = 'Расходная накладная';
																										|en = 'Sales invoice'; fa = 'فاکتور فروش';
																										|it = 'Bolla di consegna';
																										|pl = 'Faktura wydanie na zewnątrz';
																										|tr = 'Satış faturası'"),                         0);
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "Invoice", NStr("vi = 'Giao hàng (hiển thị chiết khấu)';
																									|ru = 'Реализация товаров (выводить скидки)';
																									|en = 'Goods sales (display discounts)'; fa = 'Goods sales (display discounts)';
																									|it = 'Vendita delle merci (visualizzare gli sconti)';
																									|pl = 'Sprzedaż towarów (wyświetlać zniżki)';
																									|tr = 'Malların satışı (indirimleri göster)'"),             0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceWithoutDiscounts", NStr("vi = 'Giao hàng (không hiển thị chiết khấu)';
																													|ru = 'Реализация товаров (не выводить скидки)';
																													|en = 'Goods sales (do not display discounts)'; fa = 'Goods sales (do not display discounts)';
																													|it = 'Vendita delle merci (non visualizzare gli sconti)';
																													|pl = 'Sprzedaż towarów (nie wyświetlać zniżki)';
																													|tr = 'Malların satışı (indirimleri gösterme)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "Act", NStr("vi = 'Biên bản cung cấp dịch vụ (hiển thị chiết khấu)';
																								|ru = 'Акт об оказании услуг (выводить скидки)';
																								|en = 'Certificate of rendered services (display discounts)'; fa = 'Certificate of rendered services (display discounts)';
																								|it = 'Atto di prestazione dei servizi (visualizzare gli sconti)';
																								|pl = 'Protokół świadczenia usług (wyświetlać zniżki)';
																								|tr = 'Hizmet tutanağı (indirimleri göster)'"),                2);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ActWithoutDiscounts", NStr("vi = 'Biên bản cung cấp dịch vụ (không hiển thị chiết khấu)';
																												|ru = 'Акт об оказании услуг (не выводить скидки)';
																												|en = 'Certificate of rendered services (do not display discounts)'; fa = 'Certificate of rendered services (do not display discounts)';
																												|it = 'Atto di prestazione dei servizi (non visualizzare gli sconti)';
																												|pl = 'Protokół świadczenia usług (nie wyświetlać zniżki)';
																												|tr = 'Hizmet tutanağı (indirimleri gösterme)'"),    0);
	Else
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "Invoice", NStr("vi = 'Giao hàng';
																									|ru = 'Реализация товаров';
																									|en = 'Goods sales'; fa = 'فروش کالا';
																									|it = 'Vendita delle merci';
																									|pl = 'Sprzedaż towarów';
																									|tr = 'Malların satışı'"),                               0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "Act", NStr("vi = 'Biên bản cung cấp dịch vụ';
																								|ru = 'Акт об оказании услуг';
																								|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
																								|it = 'Atto di prestazione dei servizi';
																								|pl = 'Protokół świadczenia usług';
																								|tr = 'Hizmet tutanağı'"),                                  2);
	EndIf;
	
	If GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoice", NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
																											|ru = 'Счет на оплату (выводить скидки)';
																											|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
																											|it = 'Fattura di pagamento (visualizzare gli sconti)';
																											|pl = 'Rachunek do płatności (wyświetlać zniżki)';
																											|tr = 'Ticari fatura (indirimleri göster)'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceForPaymentWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
																																|ru = 'Счет на оплату (не выводить скидки)';
																																|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
																																|it = 'Fattura di pagamento (non visualizzare gli sconti)';
																																|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
																																|tr = 'Ticari fatura (indirimleri gösterme)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile", NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
																														|ru = 'Счет на оплату с факсимиле (выводить скидки)';
																														|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
																														|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
																														|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
																														|tr = 'Kaşeli ticari fatura (indirimleri göster)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceWithFacsimileWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
																																|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
																																|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
																																|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
																																|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
																																|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'"), 0);
	EndIf;
	
	If GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoice", NStr("vi = 'Yêu cầu thanh toán';
																											|ru = 'Счет на оплату';
																											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
																											|it = 'Fattura di pagamento';
																											|pl = 'Rachunek do zapłaty';
																											|tr = 'Ticari fatura'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile", NStr("vi = 'Yêu cầu thanh toán ký qua fax';
																														|ru = 'Счет на оплату с факсимиле';
																														|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
																														|it = 'Fattura di pagamento in facsimile';
																														|pl = 'Rachunek do płatności z faksymile';
																														|tr = 'Kaşeli ticari fatura'"), 0);
	EndIf;
	
	If Constants.UseInternationalPrintingForms.Get() Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceInt", NStr("vi = 'Invoice';
																										|ru = 'Invoice';
																										|en = 'Invoice'; fa = 'فاکتور';
																										|it = 'Invoice';
																										|pl = 'Invoice';
																										|tr = 'Invoice'"), 2);
		If Not GetFunctionalOption("UseCustomerCommercialInvoices") Then
			InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceEn", NStr("vi = 'Proforma invoice';
																													|ru = 'Proforma invoice';
																													|en = 'Proforma invoice'; fa = 'پیش‌فاکتور';
																													|it = 'Proforma invoice';
																													|pl = 'Proforma invoice';
																													|tr = 'Proforma invoice'"), 1);
		EndIf;
	EndIf;
	
	If GetFunctionalOption("UseQualityCertificates") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
			"CertificatesOfProductsRegister",
			NStr("vi = 'Giấy chứng nhận (đăng ký)';
				|ru = 'Сертификаты (реестр)';
				|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
				|it = 'Certificati (registro)';
				|pl = 'Certyfikaty (rejestr)';
				|tr = 'Sertifikalar (kayıt)'"),
			0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
			"CertificatesProductImagesFromDocuments",
			NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
				|ru = 'Сертификаты (по каждой позиции документа)';
				|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
				|it = 'Certificati (per ogni voce del documento)';
				|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
				|tr = 'Sertifikalar (belgedeki her kalem için)'"),
			0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates",
			NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
				|ru = 'Сертификаты (по одному на сертификат)';
				|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
				|it = 'Certificati (uno per certificato)';
				|pl = 'Certyfikaty (po jednym na certyfikat)';
				|tr = 'Sertifikalar (sertifika başına bir tane)'"),
			0);
	EndIf;
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "GoodsPickingPlacementJob", NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
																												|ru = 'Задание на отбор товаров';
																												|en = 'Picking job'; fa = 'کار برداشت';
																												|it = 'Task per selezione prodotti';
																												|pl = 'Zadanie na selekcję towarów';
																												|tr = 'Mal seçimi görevi'"),         0);

	CustomerInvoiceLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

// Returns the data required for the printed form "Act of rendering services".
// 
// Parameters:
// 	PrintParameters - Structure - advanced print settings
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	
// Returns:
// 	Structure - Contains data on the header of the document, the tabular part:
// 	* HeaderResults          - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
//
Function GetDataForPrintedServiceDeliveryReportForm(PrintParameters, ObjectsArray) Export
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	Query = New Query("
	|SELECT
	|	CustomerInvoice.Ref AS Ref,
	|	CustomerInvoice.Number AS Number,
	|	CustomerInvoice.Date AS Date,
	|	CustomerInvoice.Partner AS Partner,
	|	CustomerInvoice.Counterparty AS Counterparty,
	|	CustomerInvoice.Organization AS Organization,
	|	CustomerInvoice.Organization.Prefix AS Prefix,
	|	CustomerInvoice.Currency AS Currency,
	|	CustomerInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN CustomerInvoice.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR CustomerInvoice.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	CustomerInvoice.Warehouse.CurrentEmployeeInChargeTypes.Description AS VacationProduced
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet                              AS ProductsInSet,
	|	Table.ItemVariantOfSet                            AS ItemVariantOfSet,
	|
	|	Table.Products AS Products,
	|	Table.PercentRateOfManualDiscount + Table.PercentRateOfAutomaticDiscountMarkup AS DiscountPercentage,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.VATRate AS VATRate,
	|	CASE
	|		WHEN &DisplayDiscounts_
	|			THEN Table.Price
	|		ELSE Table.Sum / Table.NumberOfPackages
	|	END AS Price,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Sum AS Sum,
	|	CASE
	|		WHEN &DisplayDiscounts_
	|			THEN Table.ManualDiscount + Table.DiscountMarkupAmount
	|		ELSE 0
	|	END AS DiscountAmount,
	|	Table.Sum + Table.ManualDiscount + Table.DiscountMarkupAmount AS AmountWithoutADiscount,
	|	Table.VATAmount AS VATAmount,
	|	Table.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	Document.CustomerInvoice.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN(&DocumentsArray)
	|	AND Table.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount)  AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount,
	|	Table.DiscountAmount                       AS DiscountAmount,
	|	Table.AmountWithoutADiscount                    AS AmountWithoutADiscount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet								AS ProductsInSet,
	|	Goods.ItemVariantOfSet								AS ItemVariantOfSet,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|	Goods.Products AS Products,
	|	Goods.Products.DescriptionFull AS ServiceNameFull,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	&QueryTextUnitOfMeasurementName AS UnitPrice,
	|	&QueryTextUnitOfMeasureLink AS UnitOfMeasure,
	|	&QueryTextUnitOfMeasurementName AS UnitOfMeasurementName,
	|	&QueryTextUnitOfMeasureCode AS UnitOfMeasureCode,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package.Description
	|	END AS PackagingName_,
	|	Goods.VATRate AS VATRate,
	|	Goods.Price AS Price,
	|	Goods.NumberOfPackages AS Count,
	|	Goods.Sum AS Sum,
	|	Goods.VATAmount AS VATAmount,
	|	Goods.DiscountAmount AS DiscountAmount,
	|	Goods.AmountWithoutADiscount AS AmountWithoutADiscount,
	|	Goods.LineNumber AS LineNumber,
	|	FALSE AS ThisIsReusablePackage
	|FROM (
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATRate,
	|		Table.VATAmount,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN &DisplayDiscounts_ THEN
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.AmountWithoutADiscount) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|			ELSE
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.ProductsInSet.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|
	|ORDER BY
	|	LineNumber,
	|	IsRecordsSet DESC
	|TOTALS
	|	SUM(DiscountAmount)
	|BY
	|	Ref");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
			
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureLink",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"Goods.Package",
			"Goods.Products"));
		
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasurementName",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"Goods.Package",
			"Goods.Products"));
		
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureCode",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Code",
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	
	ResultsArray = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", ResultsArray[0]);
	DataStructureForPrinting.Insert("ResultForTabularPart", ResultsArray[ResultsArray.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	If PrintParameters <> Undefined
		And PrintParameters.Property("DisplayDiscounts_") Then
		
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
		
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
							<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf;
	
	ColumnOfCodes				= PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn				= ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn	= ColumnOfCodes.ColumnPresentation;
	OutputCodes				= ValueIsFilled(NameOfCodeColumn);
	
	UseManualDiscounts			= GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseAutomaticDiscounts	= GetFunctionalOption("UseDiscountsMarkupsInSales");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CustomerInvoice.Ref				AS Ref,
	|	CustomerInvoice.Number				AS Number,
	|	CustomerInvoice.Date					AS Date,
	|	CustomerInvoice.Partner				AS Partner,
	|	CustomerInvoice.Counterparty			AS Recipient,
	|	CustomerInvoice.Organization			AS Organization,
	|	CustomerInvoice.Organization.Prefix	AS Prefix,
	|	CustomerInvoice.Currency				AS Currency,
	|	CustomerInvoice.PriceIncludesVAT		AS PriceIncludesVAT,
	|	CASE
	|		WHEN CustomerInvoice.VATTaxation IN(VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|															VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN FALSE
	|		ELSE TRUE
	|	END										AS ConsiderVAT,
	|	CustomerInvoice.IssuiedBy				AS VacationProduced
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|
	|WHERE
	|	CustomerInvoice.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CustomerInvoice.Ref										AS Ref,
	|	CustomerInvoice.LineNumber									AS LineNumber,
	|	ProductKitConfigurations.Ref										AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms	AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption					AS SetPricingOption,
	|	ISNULL(CustomerInvoice.SetAccountingDimension.ProductsInSet,
	|		VALUE(Catalog.Products.EmptyRef))							AS ProductsInSet,
	|	ISNULL(CustomerInvoice.SetAccountingDimension.ItemVariantOfSet,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))			AS ItemVariantOfSet,
	|	CustomerInvoice.ItemsLocationAttributes.Products		AS Products,
	|	CASE
	|		WHEN CustomerInvoice.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor1
	|	END																AS ZoomRatio,
	|	CASE
	|		WHEN CustomerInvoice.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CustomerInvoice.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE CustomerInvoice.Package
	|	END																AS UnitOfMeasure,
	|	CustomerInvoice.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|	CustomerInvoice.Package										AS Package,
	|	CustomerInvoice.VATRate									AS VATRate,
	|	CASE
	|		WHEN &DisplayDiscounts_
	|			THEN CustomerInvoice.Price
	|		ELSE CustomerInvoice.AmountIncludingVAT / CustomerInvoice.NumberOfPackages
	|	END																AS Price,
	|	CustomerInvoice.Count									AS Count,
	|	CustomerInvoice.NumberOfPackages							AS NumberOfPackages,
	|	CASE
	|		WHEN CustomerInvoice.Ref.PriceIncludesVAT
	|			THEN CustomerInvoice.AmountIncludingVAT
	|		ELSE CustomerInvoice.AmountIncludingVAT - CustomerInvoice.VATAmount
	|	END																AS Sum,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			CustomerInvoice.ManualDiscount + CustomerInvoice.DiscountMarkupAmount
	|		ELSE 0
	|	END																AS DiscountAmount,
	|	CustomerInvoice.AmountIncludingVAT + CustomerInvoice.ManualDiscount
	|		+ CustomerInvoice.DiscountMarkupAmount				AS AmountWithoutADiscount,
	|	CustomerInvoice.VATAmount										AS VATAmount,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(CustomerInvoice.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE CustomerInvoice.QuantityByGBRN
	|	END																AS QuantityByGBRN,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(CustomerInvoice.Ref.Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE CustomerInvoice.CCDNumber
	|	END																AS CCDNumber
	|INTO Goods
	|FROM
	|	Document.CustomerInvoice.InventoryKinds AS CustomerInvoice
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = CustomerInvoice.SetAccountingDimension.ProductsInSet
	|			AND ProductKitConfigurations.Characteristic = CustomerInvoice.SetAccountingDimension.ItemVariantOfSet
	|			AND ProductKitConfigurations.Main
	|
	|WHERE
	|	CustomerInvoice.Ref IN(&DocumentsArray)
	|	AND &ConditionByProductType
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TableOfGoods.Ref                AS Ref,
	|	MIN(TableOfGoods.LineNumber)  AS LineNumber,
	|	TableOfGoods.ProductsInSet    AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet  AS ItemVariantOfSet,
	|	SUM(TableOfGoods.Sum)          AS Sum,
	|	SUM(TableOfGoods.AmountWithoutADiscount) AS AmountWithoutADiscount,
	|	SUM(TableOfGoods.DiscountAmount)    AS DiscountAmount,
	|	SUM(TableOfGoods.VATAmount)       AS VATAmount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.Ref										AS Ref,
	|	Goods.ItemKitConfiguration				AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms	AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption						AS SetPricingOption,
	|	Goods.ProductsInSet							AS ProductsInSet,
	|	Goods.ItemVariantOfSet							AS ItemVariantOfSet,
	|	Goods.Products									AS Products,
	|	Goods.Characteristic								AS Characteristic,
	|	CASE
	|		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END												AS MainComponent,
	|	Goods.VATRate									AS VATRate,
	|	0													AS DefaultQuantity,
	|	Goods.Count									AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref										AS Ref,
	|	ConfigurationOptionsForProductRange.Ref											AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms	AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption					AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner									AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic							AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products			AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic		AS Characteristic,
	|	FALSE AS MainComponent,
	|	NULL														AS VATRate,
	|	SUM(ConfigurationOptionsForProductRange.Count)	AS DefaultQuantity,
	|	0															AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN
	|		(SELECT
	|			T.ItemKitConfiguration
	|		FROM
	|			Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Table.Ref										AS Ref,
	|	Table.ItemKitConfiguration				AS ItemKitConfiguration,
	|	Table.SetPricingOption					AS SetPricingOption,
	|	Table.PresentationOptionInPrintForms	AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet							AS ProductsInSet,
	|	Table.ItemVariantOfSet						AS ItemVariantOfSet,
	|	Table.Products								AS Products,
	|	Table.Characteristic								AS Characteristic,
	|	MAX(Table.VATRate)							AS VATRate,
	|	MAX(Table.MainComponent)				AS MainComponent,
	|	SUM(Table.DefaultQuantity)				AS DefaultQuantity,
	|	SUM(Table.Count)							AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	Result.Ref									AS Ref,
	|	Result.ItemKitConfiguration			AS ItemKitConfiguration,
	|	Result.SetPricingOption					AS SetPricingOption,
	|	Result.PresentationOptionInPrintForms	AS PresentationOptionInPrintForms,
	|	Result.ProductsInSet						AS ProductsInSet,
	|	Result.ItemVariantOfSet						AS ItemVariantOfSet,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.VATRate
	|			ELSE NULL
	|		END)											AS VATRate,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0
	|					AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1				AS Count,
	|	MAX(CASE
	|			WHEN Result.DefaultQuantity <> 0
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END)											AS CoefficientMaximum,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1				AS MinimumRatio
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	Table.Ref														AS Ref,
	|	Table.LineNumber													AS LineNumber,
	|	TemporaryTableSetsOptional.ItemKitConfiguration	AS ItemKitConfiguration,
	|	CASE
	|		WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN CASE
	|					WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|						THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|					ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|				END
	|		ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END																AS PresentationOptionInPrintForms,
	|	CASE
	|		WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN CASE
	|					WHEN CASE
	|							WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|								THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|							ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|						END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|								AND TemporaryTableSetsOptional.SetPricingOption IN(VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|																								VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|						THEN VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|					ELSE TemporaryTableSetsOptional.SetPricingOption
	|				END
	|			ELSE TemporaryTableSetsOptional.SetPricingOption
	|	END																AS SetPricingOption,
	|	Table.ProductsInSet											AS ProductsInSet,
	|	Table.ItemVariantOfSet										AS ItemVariantOfSet,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1)			AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1)			AS Count,
	|	CASE
	|		WHEN TemporaryTableSetsOptional.MinimumRatio = TemporaryTableSetsOptional.CoefficientMaximum
	|			THEN TRUE
	|		ELSE FALSE
	|	END																AS FullSet,
	|	Table.Sum														AS Sum,
	|	Table.AmountWithoutADiscount												AS AmountWithoutADiscount,
	|	Table.DiscountAmount													AS DiscountAmount,
	|	Table.VATAmount													AS VATAmount,
	|	TemporaryTableSetsOptional.VATRate						AS VATRate
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|			AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|			AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	NestedQuery.Ref										AS Ref,
	|	NestedQuery.LineNumber									AS LineNumber,
	|	NestedQuery.PresentationOptionInPrintForms	AS PresentationOptionInPrintForms,
	|	NestedQuery.SetPricingOption					AS SetPricingOption,
	|	NestedQuery.ProductsInSet							AS ProductsInSet,
	|	NestedQuery.ItemVariantOfSet						AS ItemVariantOfSet,
	|	NestedQuery.IsRecordsSet									AS IsRecordsSet,
	|	NestedQuery.TheseAreComponents							AS TheseAreComponents,
	|	NestedQuery.FullSet									AS FullSet,
	|	NestedQuery.Products								AS Products,
	|	NestedQuery.Products.DescriptionFull				AS ProductNameFull_,
	|	NestedQuery.Products.Code							AS Code,
	|	NestedQuery.Products.SKU						AS SKU,
	|	NestedQuery.UnitOfMeasure.Description				AS UnitPrice,
	|	NestedQuery.UnitOfMeasure							AS UnitOfMeasure,
	|	NestedQuery.Products.FEACNUnitOfMeasure.Presentation AS FEACNUnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull			AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor2, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END														AS Package,
	|	NestedQuery.NumberOfPackages							AS Count,
	|	NestedQuery.QuantityByGBRN							AS QuantityByGBRN,
	|	NestedQuery.CCDNumber									AS CCDNumber,
	|	NestedQuery.CCDNumber.CCDNumberType						AS CCDNumberType,
	|	CASE
	|		WHEN NestedQuery.CCDNumber.RegistrationNumber = """"
	|			THEN NestedQuery.CCDNumber.Presentation
	|		ELSE NestedQuery.CCDNumber.RegistrationNumber
	|	END														AS ProductBatchIDNumber,
	|	NestedQuery.Price										AS Price,
	|	NestedQuery.Sum										AS Sum,
	|	NestedQuery.DiscountAmount									AS DiscountAmount,
	|	NestedQuery.AmountWithoutADiscount								AS AmountWithoutADiscount,
	|	NestedQuery.VATRate									AS VATRate,
	|	NestedQuery.VATAmount									AS VATAmount,
	|	CASE
	|		WHEN NestedQuery.Ref.ToReturnReusablePackage
	|				AND NestedQuery.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN TRUE
	|		ELSE FALSE
	|	END														AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		Table.Ref					AS Ref,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.LineNumber
	|			ELSE Table.LineNumber
	|		END							AS LineNumber,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.PresentationOptionInPrintForms
	|			ELSE VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END							AS PresentationOptionInPrintForms,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.SetPricingOption
	|			ELSE VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END							AS SetPricingOption,
	|		Table.ProductsInSet		AS ProductsInSet,
	|		Table.ItemVariantOfSet	AS ItemVariantOfSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END							AS TheseAreComponents,
	|		FALSE							AS IsRecordsSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.FullSet
	|			ELSE FALSE
	|		END							AS FullSet,
	|		Table.Products			AS Products,
	|		Table.Count				AS Count,
	|		Table.NumberOfPackages		AS NumberOfPackages,
	|		Table.QuantityByGBRN		AS QuantityByGBRN,
	|		Table.CCDNumber				AS CCDNumber,
	|		Table.Price					AS Price,
	|		Table.Sum					AS Sum,
	|		Table.VATRate				AS VATRate,
	|		Table.VATAmount				AS VATAmount,
	|		Table.Characteristic			AS Characteristic,
	|		Table.Package				AS Package,
	|		Table.UnitOfMeasure		AS UnitOfMeasure,
	|		Table.DiscountAmount				AS DiscountAmount,
	|		Table.AmountWithoutADiscount			AS AmountWithoutADiscount
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|				AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|				AND TemporaryTableSets.Ref = Table.Ref
	|	
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|			AND TemporaryTableSets.PresentationOptionInPrintForms IN(VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|																				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TemporaryTableSets.Ref										AS Ref,
	|		TemporaryTableSets.LineNumber									AS LineNumber,
	|		TemporaryTableSets.PresentationOptionInPrintForms	AS PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption						AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet							AS ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet							AS ItemVariantOfSet,
	|		FALSE																AS TheseAreComponents,
	|		TRUE																AS IsRecordsSet,
	|		TemporaryTableSets.FullSet									AS FullSet,
	|		TemporaryTableSets.ProductsInSet							AS Products,
	|		TemporaryTableSets.Count									AS Count,
	|		TemporaryTableSets.NumberOfPackages							AS NumberOfPackages,
	|		0																	AS QuantityByGBRN,
	|		VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|		CASE
	|			WHEN &DisplayDiscounts_
	|				THEN CASE
	|						WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	|							THEN (TemporaryTableSets.AmountWithoutADiscount) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|						ELSE 0
	|					END
	|				ELSE CASE
	|						WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	|							THEN (TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|						ELSE 0
	|					END
	|		END																AS Price,
	|		TemporaryTableSets.Sum										AS Sum,
	|		TemporaryTableSets.VATRate									AS VATRate,
	|		TemporaryTableSets.VATAmount										AS VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet							AS Characteristic,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)			AS Package,
	|		TemporaryTableSets.ProductsInSet.UnitOfMeasure			AS UnitOfMeasure,
	|		TemporaryTableSets.DiscountAmount									AS DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount								AS AmountWithoutADiscount
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN(VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|																			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|	) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber,
	|	IsRecordsSet DESC
	|
	|TOTALS
	|	SUM(DiscountAmount)
	|BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT
	|	Goods.Ref	AS Ref,
	|	MAX(CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(Goods.Ref.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				AND ISNULL(Goods.Ref.Terms.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|				AND Goods.Ref.BusinessOperation IN(VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
	|														VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent))
	|				AND ISNULL(Goods.CCDNumber.CCDNumberType, UNDEFINED) IN(VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|																		VALUE(Enum.CCDNumberTypes.KitRNPT))
	|			THEN TRUE
	|		ELSE FALSE
	|	END)			AS ThereIsRNPT
	|FROM
	|	Document.CustomerInvoice.InventoryKinds AS Goods
	|
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|	AND Goods.ItemsLocationAttributes.Products.ItemsType
	|		IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	Goods.Ref
	|
	|ORDER BY
	|	Goods.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT DISTINCT
	|	DocumentTable.CCDNumber							AS CCDNumber,
	|	CASE
	|		WHEN Components.ProductBatchIDNumber.RegistrationNumber = """"
	|			THEN Components.ProductBatchIDNumber
	|		ELSE Components.ProductBatchIDNumber.RegistrationNumber
	|	END												AS ProductBatchIDNumber,
	|	Components.QuantityByGBRN						AS QuantityByGBRN,
	|	Components.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure
	|FROM
	|	Goods AS DocumentTable
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON DocumentTable.CCDNumber = Components.Ref";
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor1",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"CustomerInvoice.Package",
									"CustomerInvoice.ItemsLocationAttributes.Products"));
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor2",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"NestedQuery.Package",
									"NestedQuery.Products"));
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		ConditionByProductType = "TRUE";
	Else
		ConditionByProductType =
			"CustomerInvoice.ItemsLocationAttributes.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
			|																					VALUE(Enum.ItemsTypes.ReusablePackage))";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&ConditionByProductType", ConditionByProductType);
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_CustomerInvoice_Invoice";
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultPrintData				= ResultsArray[0]; // QueryResult - 
	ResultDocumentSelection		= ResultsArray[8]; // QueryResult - 
	DocumentTraceabilityData	= ResultsArray[9].Unload(); // ValueTable - 
	TraceableComponents			= ResultsArray[10].Unload(); // ValueTable - 
	
	PrintData		= ResultPrintData.Select();
	SelectionByDocuments	= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();
	
	FirstDocument = True;
	ThereIsRNPT = False;
	
	DocumentTraceabilityData.Indexes.Add("Ref");
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there are only services in the invoice, let's move on to the next document
		If FollowingIsFound Then
			ProductSelection_1 = SelectionByDocuments.Select();
			
			DiscountHeader = PrintFormGeneration.YouNeedToDisplayDiscounts(ProductSelection_1,
																			UseManualDiscounts
																				Or UseAutomaticDiscounts);
			ThereAreDiscounts		= DiscountHeader.ThereAreDiscounts;
			ThereIsVAT			= PrintData.ConsiderVAT;
			ThereIsRNPT		= False;
			
			FilterDocumentRows = New Structure("Ref", PrintData.Ref);
			DocumentStrings = DocumentTraceabilityData.FindRows(FilterDocumentRows);
			
			If DocumentStrings.Count() > 0 Then
				ThereIsRNPT = DocumentStrings[0].ThereIsRNPT;
			EndIf;
			
			ProductSelection_1.Reset();
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in hóa đơn';
						|ru = 'В документе %1 отсутствуют товары. Печать накладной не требуется';
						|en = 'Goods are missing in document %1. Printing of the invoice is not required'; fa = 'Goods are missing in document %1. Printing of the invoice is not required';
						|it = 'Il documento %1 non contiene le merci. La stampa della bolla non è richiesta';
						|pl = 'Brak towarów w dokumencie %1. Nie jest potrzebne drukowanie zlecenia.';
						|tr = '%1 belgesinde mal bulunmamaktadır. İrsaliyenin yazdırılmasına gerek yoktur'"),
					PrintData.Ref);
			
			Common.MessageToUser(Text, PrintData.Ref);
			
			Continue;
		EndIf;
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.CustomerInvoice.PF_MXL_GoodsSales");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument		= False;
		RowNumberStart	= SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		TemplateArea = Template.GetArea("Title");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument,
																		Template,
																		TemplateArea,
																		PrintData.Ref);
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
							PrintData,
							NStr("vi = 'Giao hàng';
								|ru = 'Реализация товаров';
								|en = 'Goods sales'; fa = 'فروش کالا';
								|it = 'Vendita delle merci';
								|pl = 'Sprzedaż towarów';
								|tr = 'Malların satışı'", Common.DefaultLanguageCode()));
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TitleText);
		
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TitleUnderscore");
		If ThereIsRNPT Then
			TemplateArea = Template.GetArea("TitleUnderlineRNPT");
		EndIf;
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		
		SupplierPresentation = PrintFormGeneration.OrganizationDescription(
									PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date),
									"FullDescr");
		
		DataStructureProvider = New Structure;
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Organization);
		
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		
		RecipientPresentation1 = PrintFormGeneration.OrganizationDescription(
									PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date),
									"FullDescr");
		
		CustomerDataStructure = New Structure;
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Recipient);
		
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		NamesOfLineAreas = NamesOfLineAreas(ThereAreDiscounts, ThereIsVAT And ShowVAT, ThereIsRNPT);
		ColumnAreaNames = ColumnAreaNames(ThereAreDiscounts, ThereIsVAT And ShowVAT, ThereIsRNPT);
		
		ProductColumnArea = Template.Area(ColumnAreaNames.FirstColumnOfGoods);
		ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
											+ ?(OutputCodes,
												0,
												Template.Area(ColumnAreaNames.ColumnOfCodes).ColumnWidth);
		
		RoomArea			= Template.GetArea(NamesOfLineAreas.TableHeader
														+ "|" + ColumnAreaNames.LineNumber);
		AreaCodes			= Template.GetArea(NamesOfLineAreas.TableHeader
														+ "|" + ColumnAreaNames.ColumnOfCodes);
		ProductArea			= Template.GetArea(NamesOfLineAreas.TableHeader
														+ "|" + ColumnAreaNames.OwnGoods);
		AreaDataQuantity	= Template.GetArea(NamesOfLineAreas.TableHeader
														+ "|" + ColumnAreaNames.DataQuantity);
		DataAreaRNPTNumber	= Template.GetArea(NamesOfLineAreas.TableHeader
														+ "|" + ColumnAreaNames.DataRNPTNumber);
		DataAreaIsSummarized	= Template.GetArea(NamesOfLineAreas.TableHeader
														+ "|" + ColumnAreaNames.DataSummary);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(AreaDataQuantity);
		
		If ThereIsRNPT Then
			SpreadsheetDocument.Join(DataAreaRNPTNumber);
		EndIf;
		
		If ThereAreDiscounts Then
			StructureOfDiscountHeader = New Structure("Discount, AmountWithoutADiscount",
														DiscountHeader.Discount, DiscountHeader.DiscountAmount);
			DataAreaIsSummarized.Parameters.Fill(StructureOfDiscountHeader);
		EndIf;
		
		SpreadsheetDocument.Join(DataAreaIsSummarized);
		
		LineNumberAreaStandard				= Template.GetArea(NamesOfLineAreas.TableRow
																		+ "|" + ColumnAreaNames.LineNumber);
		ScopeOfStringCodesStandard				= Template.GetArea(NamesOfLineAreas.TableRow
																		+ "|" + ColumnAreaNames.ColumnOfCodes);
		ProductAreaRowsStandard				= Template.GetArea(NamesOfLineAreas.TableRow
																		+ "|" + ColumnAreaNames.OwnGoods);
		DataAreaNumberOfRowsStandard	= Template.GetArea(NamesOfLineAreas.TableRow
																		+ "|" + ColumnAreaNames.DataQuantity);
		DataAreaRNPTLineNumberStandard	= Template.GetArea(NamesOfLineAreas.TableRow
																		+ "|" + ColumnAreaNames.DataRNPTNumber);
		DataAreaSumLinesStandard		= Template.GetArea(NamesOfLineAreas.TableRow
																		+ "|" + ColumnAreaNames.DataSummary);
		
		UseSets = False;
		
		If TMCommonUseClientServer.HasObjectAttribute(SelectionByDocuments, "IsRecordsSet") Then
			UseSets = True;
			
			LineNumberAreaSet			= Template.GetArea(NamesOfLineAreas.TableRowSet
																		+ "|" + ColumnAreaNames.LineNumber);
			StringCodeAreaSet				= Template.GetArea(NamesOfLineAreas.TableRowSet
																		+ "|" + ColumnAreaNames.ColumnOfCodes);
			ProductAreaRowsSet				= Template.GetArea(NamesOfLineAreas.TableRowSet
																		+ "|" + ColumnAreaNames.OwnGoods);
			DataAreaNumberOfRowsSet	= Template.GetArea(NamesOfLineAreas.TableRowSet
																		+ "|" + ColumnAreaNames.DataQuantity);
			DataAreaRNPTLineNumberSet	= Template.GetArea(NamesOfLineAreas.TableRowSet
																		+ "|" + ColumnAreaNames.DataRNPTNumber);
			DataAreaIsSummarizedSet			= Template.GetArea(NamesOfLineAreas.TableRowSet
																		+ "|" + ColumnAreaNames.DataSummary);
			
			LineNumberAreaComponents			= Template.GetArea(NamesOfLineAreas.TableRowComponents
																				+ "|" + ColumnAreaNames.LineNumber);
			StringCodeAreaComponents				= Template.GetArea(NamesOfLineAreas.TableRowComponents
																				+ "|" + ColumnAreaNames.ColumnOfCodes);
			ProductAreaRowsComponents				= Template.GetArea(NamesOfLineAreas.TableRowComponents
																				+ "|" + ColumnAreaNames.OwnGoods);
			AreaDataQuantityComponents		= Template.GetArea(NamesOfLineAreas.TableRowComponents
																				+ "|" + ColumnAreaNames.DataQuantity);
			DataAreaRNPTLineNumberAccessories	= Template.GetArea(NamesOfLineAreas.TableRowComponents
																				+ "|" + ColumnAreaNames.DataRNPTNumber);
			DataAreaIsSummarizedComponents			= Template.GetArea(NamesOfLineAreas.TableRowComponents
																				+ "|" + ColumnAreaNames.DataSummary);
		EndIf;
		
		Sum          = 0;
		VATAmount       = 0;
		TotalOfDiscounts    = 0;
		LineNumber    = 0;
		TotalWithoutDiscounts = 0;
		
		BlankData = SetsServer.BlankData();
		
		// Output the rows of the Goods table
		While ProductSelection_1.Next() Do
			
			If SetsServer.UseSetArea(ProductSelection_1, UseSets) Then
				StringCodeArea				= StringCodeAreaSet;
				LineNumberArea				= LineNumberAreaSet;
				ProductAreaRows				= ProductAreaRowsSet;
				DataAreaNumberOfRows	= DataAreaNumberOfRowsSet;
				DataAreaRNPLineNumber		= DataAreaRNPTLineNumberSet;
				DataAreaSumLines		= DataAreaIsSummarizedSet;
				
			ElsIf SetsServer.UseScope(ProductSelection_1, UseSets) Then
				StringCodeArea				= StringCodeAreaComponents;
				LineNumberArea				= LineNumberAreaComponents;
				ProductAreaRows				= ProductAreaRowsComponents;
				DataAreaNumberOfRows	= AreaDataQuantityComponents;
				DataAreaRNPLineNumber		= DataAreaRNPTLineNumberAccessories;
				DataAreaSumLines		= DataAreaIsSummarizedComponents;
			Else
				StringCodeArea				= ScopeOfStringCodesStandard;
				LineNumberArea				= LineNumberAreaStandard;
				ProductAreaRows				= ProductAreaRowsStandard;
				DataAreaNumberOfRows	= DataAreaNumberOfRowsStandard;
				DataAreaRNPLineNumber		= DataAreaRNPTLineNumberStandard;
				DataAreaSumLines		= DataAreaSumLinesStandard;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				SetParameter(LineNumberArea, "LineNumber", Undefined);
			Else
				LineNumber = LineNumber + 1;
				SetParameter(LineNumberArea, "LineNumber", LineNumber);
			EndIf;
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				
				StringCodeArea.Parameters.Fill(DataStructureCodes);
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(ProductSelection_1, UseSets);
			
			ProductAreaRows.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers	= ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode	= Common.DefaultLanguageCode();
			
			ProductPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
											ProductSelection_1.ProductNameFull_,
											ProductSelection_1.Characteristic,
											,
											,
											AdditionalParametersForGettingNameToPrint);
			OwnGoods					= PrefixAndPostfix.Prefix + ProductPresentation + PrefixAndPostfix.Postfix;
			
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			
			ProductAreaRows.Parameters.Fill(ProductDataStructure);
			
			If DiscountHeader.ThereAreDiscounts Then
				DiscountAmount = ?(DiscountHeader.OnlyMarkUp, - ProductSelection_1.DiscountAmount, ProductSelection_1.DiscountAmount);
				DataStructureDiscountAmount = New Structure("DiscountAmount", DiscountAmount);
				
				DataAreaSumLines.Parameters.Fill(DataStructureDiscountAmount);
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				DataAreaNumberOfRows.Parameters.Fill(BlankData);
				DataAreaSumLines.Parameters.Fill(BlankData);
			Else
				DataAreaNumberOfRows.Parameters.Fill(ProductSelection_1);
				DataAreaSumLines.Parameters.Fill(ProductSelection_1);
			EndIf;
			
			If ThereIsRNPT
				And ValueIsFilled(ProductSelection_1.CCDNumber)
				And ProductSelection_1.CCDNumber <> Enums.CCDNumberTypes.CCDNumber Then
				
				If ProductSelection_1.CCDNumberType = Enums.CCDNumberTypes.ProductBatchIDNumber Then
					TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
					TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(ProductSelection_1.ProductBatchIDNumber);
					TheseAreRNPTNumbers.QuantityByGBRN		= ProductSelection_1.QuantityByGBRN;
					TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(ProductSelection_1.FEACNUnitOfMeasure);
					
					DataAreaRNPLineNumber.Parameters.Fill(TheseAreRNPTNumbers);
					
					SpreadsheetDocument.Put(LineNumberArea);
					If OutputCodes Then
						SpreadsheetDocument.Join(StringCodeArea);
					EndIf;
					SpreadsheetDocument.Join(ProductAreaRows);
					SpreadsheetDocument.Join(DataAreaNumberOfRows);
					SpreadsheetDocument.Join(DataAreaRNPLineNumber);
					SpreadsheetDocument.Join(DataAreaSumLines);
					
				Else
					
					AreaOfRNPTLineNumberIsDialing			= Template.GetArea(NamesOfLineAreas.TableRowSetOfRNPT
																					+ "|" + ColumnAreaNames.LineNumber);
					AreaOfRNPTStringCodesIsSet				= Template.GetArea(NamesOfLineAreas.TableRowSetOfRNPT
																					+ "|" + ColumnAreaNames.ColumnOfCodes);
					ScopeOfProductLineRNPTSet				= Template.GetArea(NamesOfLineAreas.TableRowSetOfRNPT
																					+ "|" + ColumnAreaNames.OwnGoods);
					DataAreaNumberOfRowsRNPTSet	= Template.GetArea(NamesOfLineAreas.TableRowSetOfRNPT
																					+ "|" + ColumnAreaNames.DataQuantity);
					DataAreaSumLinesRNPTSet	= Template.GetArea(NamesOfLineAreas.TableRowSetOfRNPT
																					+ "|" + ColumnAreaNames.DataSummary);
					
					AreaOfRNPTLineNumberIsAccessories			= Template.GetArea(NamesOfLineAreas.RowOfRNPTComponentsTable
																							+ "|" + ColumnAreaNames.LineNumber);
					AreaOfRNPTLineCodesIsAccessories				= Template.GetArea(NamesOfLineAreas.RowOfRNPTComponentsTable
																							+ "|" + ColumnAreaNames.ColumnOfCodes);
					ScopeOfProductLineRNPTAccessories				= Template.GetArea(NamesOfLineAreas.RowOfRNPTComponentsTable
																							+ "|" + ColumnAreaNames.OwnGoods);
					AreaDataNumberOfLinesRNPTAccessories	= Template.GetArea(NamesOfLineAreas.RowOfRNPTComponentsTable
																							+ "|" + ColumnAreaNames.DataQuantity);
					DataAreaSummaryLinesRNPTAccessories	= Template.GetArea(NamesOfLineAreas.RowOfRNPTComponentsTable
																							+ "|" + ColumnAreaNames.DataSummary);
					
					AreaOfRNPTLineNumberIsDialing.Parameters.Fill(LineNumberArea.Parameters);
					AreaOfRNPTStringCodesIsSet.Parameters.Fill(StringCodeArea.Parameters);
					ScopeOfProductLineRNPTSet.Parameters.Fill(ProductAreaRows.Parameters);
					DataAreaNumberOfRowsRNPTSet.Parameters.Fill(DataAreaNumberOfRows.Parameters);
					DataAreaSumLinesRNPTSet.Parameters.Fill(DataAreaSumLines.Parameters);
					
					RowFilter = New Structure("CCDNumber", ProductSelection_1.CCDNumber);
					SetLines = TraceableComponents.FindRows(RowFilter);
					
					SetLineNumber = 1;
					
					For Each SetString_ In SetLines Do
						TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure");
						TheseAreRNPTNumbers.ProductBatchIDNumber				= TrimAll(SetString_.ProductBatchIDNumber);
						TheseAreRNPTNumbers.QuantityByGBRN		= ProductSelection_1.Count * SetString_.QuantityByGBRN;
						TheseAreRNPTNumbers.FEACNUnitOfMeasure	= TrimAll(SetString_.FEACNUnitOfMeasure);
						
						DataAreaRNPLineNumber.Parameters.Fill(TheseAreRNPTNumbers);
						
						If SetLineNumber = 1 Then
							SpreadsheetDocument.Put(AreaOfRNPTLineNumberIsDialing);
							If OutputCodes Then
								SpreadsheetDocument.Join(AreaOfRNPTStringCodesIsSet);
							EndIf;
							SpreadsheetDocument.Join(ScopeOfProductLineRNPTSet);
							SpreadsheetDocument.Join(DataAreaNumberOfRowsRNPTSet);
							SpreadsheetDocument.Join(DataAreaRNPLineNumber);
							SpreadsheetDocument.Join(DataAreaSumLinesRNPTSet);
						Else
							SpreadsheetDocument.Put(AreaOfRNPTLineNumberIsAccessories);
							If OutputCodes Then
								SpreadsheetDocument.Join(AreaOfRNPTLineCodesIsAccessories);
							EndIf;
							SpreadsheetDocument.Join(ScopeOfProductLineRNPTAccessories);
							SpreadsheetDocument.Join(AreaDataNumberOfLinesRNPTAccessories);
							SpreadsheetDocument.Join(DataAreaRNPLineNumber);
							SpreadsheetDocument.Join(DataAreaSummaryLinesRNPTAccessories);
						EndIf;
						
						SetLineNumber = SetLineNumber + 1;
					EndDo;
				EndIf;
				
			Else
				SpreadsheetDocument.Put(LineNumberArea);
				If OutputCodes Then
					SpreadsheetDocument.Join(StringCodeArea);
				EndIf;
				SpreadsheetDocument.Join(ProductAreaRows);
				SpreadsheetDocument.Join(DataAreaNumberOfRows);
				If ThereIsRNPT Then
					TheseAreRNPTNumbers = New Structure("ProductBatchIDNumber, QuantityByGBRN, FEACNUnitOfMeasure",
														"-", 0, "-");
					DataAreaRNPLineNumber.Parameters.Fill(TheseAreRNPTNumbers);
					
					SpreadsheetDocument.Join(DataAreaRNPLineNumber);
				EndIf;
				SpreadsheetDocument.Join(DataAreaSumLines);
			EndIf;
			
			If Not SetsServer.UseScope(ProductSelection_1, UseSets) Then
				Sum		= Sum + ProductSelection_1.Sum;
				VATAmount	= VATAmount + ProductSelection_1.VATAmount;
				
				If ThereAreDiscounts Then
					TotalOfDiscounts		= TotalOfDiscounts + ProductSelection_1.DiscountAmount;
					TotalWithoutDiscounts	= TotalWithoutDiscounts + ProductSelection_1.AmountWithoutADiscount;
				EndIf;
			EndIf;
			
		EndDo;
		
		// We output the basement
		RoomArea			= Template.GetArea(NamesOfLineAreas.TableFooter
														+ "|" + ColumnAreaNames.LineNumber);
		AreaCodes			= Template.GetArea(NamesOfLineAreas.TableFooter
														+ "|" + ColumnAreaNames.ColumnOfCodes);
		ProductArea			= Template.GetArea(NamesOfLineAreas.TableFooter
														+ "|" + ColumnAreaNames.OwnGoods);
		AreaDataQuantity	= Template.GetArea(NamesOfLineAreas.TableFooter
														+ "|" + ColumnAreaNames.DataQuantity);
		DataAreaRNPTNumber	= Template.GetArea(NamesOfLineAreas.TableFooter
														+ "|" + ColumnAreaNames.DataRNPTNumber);
		DataAreaIsSummarized	= Template.GetArea(NamesOfLineAreas.TableFooter
														+ "|" + ColumnAreaNames.DataSummary);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(AreaDataQuantity);
		
		If ThereIsRNPT Then
			SpreadsheetDocument.Join(DataAreaRNPTNumber);
		EndIf;
		
		DataStructureOfWholeDiscount = New Structure;
		
		If ThereAreDiscounts Then
			DataStructureOfWholeDiscount.Insert("TotalOfDiscounts", ?(DiscountHeader.OnlyMarkUp,-TotalOfDiscounts, TotalOfDiscounts));
			DataStructureOfWholeDiscount.Insert("TotalWithoutDiscounts", TotalWithoutDiscounts);
		EndIf;
		DataStructureOfWholeDiscount.Insert("Total", PrintFormGeneration.SumFormat(Sum));
		
		DataAreaIsSummarized.Parameters.Fill(DataStructureOfWholeDiscount);
		SpreadsheetDocument.Join(DataAreaIsSummarized);
		
		// We output the total of the ADS
		If GetFunctionalOption("UseVATAccounting") Then
			Area = Template.GetArea("VATBasement");
			If ThereIsRNPT Then
				Area = Template.GetArea("NdsrnptBasement");
			EndIf;
			
			If ThereIsVAT Then
				VATLabel = ?(PrintData.PriceIncludesVAT,
								NStr("vi = 'Trong đó thuế GTGT:';
									|ru = 'В том числе НДС:';
									|en = 'Including VAT:'; fa = 'Including VAT:';
									|it = 'IVA compresa:';
									|pl = 'W tym VAT';
									|tr = 'KDV dahil:'", Common.DefaultLanguageCode()),
								NStr("vi = 'Thuế GTGT:';
									|ru = 'Сумма НДС:';
									|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
									|it = 'Importo IVA:';
									|pl = 'Wartość VAT:';
									|tr = 'KDV tutarı:'", Common.DefaultLanguageCode()));
			Else
				VATLabel = NStr("vi = 'Không gồm thuế (GTGT)';
								|ru = 'Без налога (НДС)';
								|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
								|it = 'senza imposta (IVA)';
								|pl = 'bez podatku (VAT)';
								|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode());
			EndIf;
			
			DataStructureVATBasement = New Structure;
			DataStructureVATBasement.Insert("TotalVAT",	VATAmount);
			DataStructureVATBasement.Insert("VAT",		VATLabel);
			
			Area.Parameters.Fill(DataStructureVATBasement);
			SpreadsheetDocument.Join(Area);
		EndIf;
		
		// We output the Amount in words
		TemplateArea = Template.GetArea("AmountInWords");
		
		AmountToBeRegistered	= Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		TotalString	= StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Tổng số %1, thành tiền %2';
								|ru = 'Всего наименований %1, на сумму %2';
								|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
								|it = 'Totale articoli %1, per importo di %2';
								|pl = 'Razem pozycji %1, na kwotę %2';
								|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
							ProductSelection_1.Count(),
							PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		AmountInWords	= ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency);
		
		DataStructureSumInWords = New Structure;
		DataStructureSumInWords.Insert("TotalString",	TotalString);
		DataStructureSumInWords.Insert("AmountInWords",	AmountInWords);
		
		TemplateArea.Parameters.Fill(DataStructureSumInWords);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		If ThereIsRNPT Then
			TemplateArea = Template.GetArea("RNPTSignatures");
		EndIf;
		
		If ValueIsFilled(PrintData.VacationProduced) Then
			DataStructureVacationProduced = New Structure;
			DataStructureVacationProduced.Insert("VacationProduced",
													PersonsTM.IndividualShortName(PrintData.VacationProduced, PrintData.Date));
			
			TemplateArea.Parameters.Fill(DataStructureVacationProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument,
														RowNumberStart,
														PrintObjects,
														PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

Function NamesOfLineAreas(WithDiscount, WithVAT, ProductBatchID)
	
	PropertiesNames = "TableHeader, TableRow, TableRowSet, TableRowComponents,
					|TableRowSetOfRNPT, RowOfRNPTComponentsTable, TableFooter";
	
	NamesOfRegions = New Structure(PropertiesNames);
	
	If WithDiscount
		And WithVAT
		And Not ProductBatchID Then
		
		NamesOfRegions.TableHeader				= "TableHeaderWithDiscountWithVAT";
		NamesOfRegions.TableRow				= "TableRowWithDiscountWithVAT";
		NamesOfRegions.TableRowSet			= "TableRowWithDiscountWithVATSet";
		NamesOfRegions.TableRowComponents	= "TableRowWithDiscountWithVATComponents";
		NamesOfRegions.TableFooter				= "TableBasementWithVATDiscount";
		
	ElsIf Not WithDiscount
		And WithVAT
		And Not ProductBatchID Then
		
		NamesOfRegions.TableHeader				= "HeaderOfTableWithVAT";
		NamesOfRegions.TableRow				= "TableRowWithVAT";
		NamesOfRegions.TableRowSet			= "TableRowWithVATSet";
		NamesOfRegions.TableRowComponents	= "TableRowWithVATComponents";
		NamesOfRegions.TableFooter				= "BasementTableWithVAT";
		
	ElsIf WithDiscount
		And Not WithVAT
		And Not ProductBatchID Then
		
		NamesOfRegions.TableHeader				= "TableHeaderWithDiscount";
		NamesOfRegions.TableRow				= "TableRowWithDiscount";
		NamesOfRegions.TableRowSet			= "TableRowWithDiscountSet";
		NamesOfRegions.TableRowComponents	= "TableRowWithDiscountComponents";
		NamesOfRegions.TableFooter				= "BasementTableWithVAT";
		
	ElsIf Not WithDiscount
		And Not WithVAT
		And Not ProductBatchID Then
		
		NamesOfRegions.TableHeader				= "TableHeader";
		NamesOfRegions.TableRow				= "TableRow";
		NamesOfRegions.TableRowSet			= "TableRowSet";
		NamesOfRegions.TableRowComponents	= "TableRowComponents";
		NamesOfRegions.TableFooter				= "TableFooter";
		
	ElsIf WithDiscount
		And WithVAT
		And ProductBatchID Then
		
		NamesOfRegions.TableHeader					= "TableHeaderWithDiscountSNDSRNPT";
		NamesOfRegions.TableRow					= "TableRowWithDiscountSNDSRNPT";
		NamesOfRegions.TableRowSet				= "TableRowWithDiscountSNDSRNPTSet";
		NamesOfRegions.TableRowComponents		= "TableRowWithDiscountSNDSRNPTComponents";
		NamesOfRegions.TableFooter					= "TableBasementWithDiscountSNDSRNPT";
		
	ElsIf Not WithDiscount
		And WithVAT
		And ProductBatchID Then
		
		NamesOfRegions.TableHeader					= "HeaderOfSNDSRNPTTable";
		NamesOfRegions.TableRow					= "RowOfSNDSRNPTTable";
		NamesOfRegions.TableRowSet				= "RowOfSNDSRNPTTableSet";
		NamesOfRegions.TableRowComponents		= "RowOfSNDSRNPTTableComponents";
		NamesOfRegions.TableRowSetOfRNPT			= "RowOfSNDSRNPTTableIsSetOfRNPT";
		NamesOfRegions.RowOfRNPTComponentsTable	= "TableRowSNDSRNPTComponentsRNPT";
		NamesOfRegions.TableFooter					= "SndsrnptTableBasement";
		
	ElsIf WithDiscount
		And Not WithVAT
		And ProductBatchID Then
		
		NamesOfRegions.TableHeader					= "HeaderOfTableWithDiscountRNPT";
		NamesOfRegions.TableRow					= "TableRowWithRnptDiscount";
		NamesOfRegions.TableRowSetOfRNPT			= "TableRowWithRnptDiscountSet";
		NamesOfRegions.RowOfRNPTComponentsTable	= "TableRowWithRnptDiscountComponents";
		NamesOfRegions.TableFooter					= "SndsrnptTableBasement";  
		
	ElsIf Not WithDiscount
		And Not WithVAT
		And ProductBatchID Then
		
		NamesOfRegions.TableHeader					= "HeaderOfRNPTTable";
		NamesOfRegions.TableRow					= "RowOfRNPTTable";
		NamesOfRegions.TableRowSet				= "RowOfRNPTTableSet";
		NamesOfRegions.TableRowComponents		= "RowOfRNPTTableComponents";
		NamesOfRegions.TableRowSetOfRNPT			= "RowOfRNPTTableIsSetOfRNPT";
		NamesOfRegions.RowOfRNPTComponentsTable	= "RowOfRNPTTableRNPTComponents";
		NamesOfRegions.TableFooter					= "RnptTableBasement";
		
	EndIf;
	
	Return NamesOfRegions;
	
EndFunction

Function ColumnAreaNames(WithDiscount, WithVAT, ProductBatchID)
	
	AreaNames = "LineNumber, ColumnOfCodes, FirstColumnOfGoods, OwnGoods, DataQuantity, DataRNPTNumber,
					|DataSummary";
	
	NamesOfRegions = New Structure(AreaNames);
	
	If WithDiscount
		And WithVAT
		And Not ProductBatchID Then
		
		NamesOfRegions.LineNumber			= "LineNumber";
		NamesOfRegions.ColumnOfCodes			= "ColumnOfCodes";
		NamesOfRegions.FirstColumnOfGoods	= "FirstColumnOfGoods";
		NamesOfRegions.OwnGoods					= "DiscountedGoodsWithVAT";
		NamesOfRegions.DataQuantity		= "GivenQuantityIsDiscountedWithVAT";
		NamesOfRegions.DataSummary			= "DiscountedDataWithVAT";
		
	ElsIf ((Not WithDiscount
			And WithVAT)
		Or (WithDiscount
			And Not WithVAT))
		And Not ProductBatchID Then
		
		NamesOfRegions.LineNumber			= "LineNumber";
		NamesOfRegions.ColumnOfCodes			= "ColumnOfCodes";
		NamesOfRegions.FirstColumnOfGoods	= "FirstColumnOfGoods";
		NamesOfRegions.OwnGoods					= "ProductWithDiscountOrWithVAT";
		NamesOfRegions.DataQuantity		= "DataQuantityWithDiscountOrWithVAT";
		NamesOfRegions.DataSummary			= "DiscountedOrWithVATData";
		
	ElsIf Not WithDiscount
		And Not WithVAT
		And Not ProductBatchID Then
		
		NamesOfRegions.LineNumber			= "LineNumber";
		NamesOfRegions.ColumnOfCodes			= "ColumnOfCodes";
		NamesOfRegions.FirstColumnOfGoods	= "FirstColumnOfGoods";
		NamesOfRegions.OwnGoods					= "OwnGoods";
		NamesOfRegions.DataQuantity		= "DataQuantity";
		NamesOfRegions.DataSummary			= "Data";
		
	ElsIf Not WithDiscount
		And WithVAT
		And ProductBatchID Then
		
		NamesOfRegions.LineNumber			= "RNPTSNDSLineNumber";
		NamesOfRegions.ColumnOfCodes			= "ColumnOfRNPTSNDSCodes";
		NamesOfRegions.FirstColumnOfGoods	= "FirstColumnOfRNPTSNDSProduct";
		NamesOfRegions.OwnGoods					= "RNPTSNDSProduct";
		NamesOfRegions.DataQuantity		= "DataNumberOfSNDSRNPT";
		NamesOfRegions.DataRNPTNumber		= "DataRNPTSNDSNumber";
		NamesOfRegions.DataSummary			= "SNDSRNPTData";
		
	ElsIf Not WithDiscount
		And Not WithVAT
		And ProductBatchID Then
		
		NamesOfRegions.LineNumber			= "RNPTLineNumber";
		NamesOfRegions.ColumnOfCodes			= "ColumnOfRNPTCodes";
		NamesOfRegions.FirstColumnOfGoods	= "FirstColumnOfRNPTProduct";
		NamesOfRegions.OwnGoods					= "RNPTProduct";
		NamesOfRegions.DataQuantity		= "DataNumberOfRNPT";
		NamesOfRegions.DataRNPTNumber		= "DataRNPTNumber";
		NamesOfRegions.DataSummary			= "RNPTData";
		
	EndIf;
	
	Return NamesOfRegions;
	
EndFunction

Function CreatePrintedFormInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_CustomerInvoice_ExpenseToPrint";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	UseManualDiscounts         = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseAutomaticDiscounts = GetFunctionalOption("UseDiscountsMarkupsInSales");
	UsePackages             = GetFunctionalOption("UseItemPackages");
	
	RequestForWarehouses = New Query;
	RequestForWarehouses.Text = "
	|SELECT
	|	SalesOfGoodsServicesGoods.Ref                                        AS Ref,
	|	MAX(SalesOfGoodsServicesGoods.Ref.BusinessOperation)        AS BusinessOperation,
	|	MAX(SalesOfGoodsServicesGoods.Ref.BusinessOperation = 
	|		VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)) AS ThisIsTransferOfOwnership,
	|	MAX(CASE
	|		WHEN SalesOfGoodsServicesGoods.Products.ItemsType IN (
	|		                                                VALUE(Enum.ItemsTypes.OwnGoods),
	|		                                                VALUE(Enum.ItemsTypes.ReusablePackage)
	|		                                                )
	|			THEN TRUE
	|		ELSE
	|			FALSE
	|	END)                                                                     AS DocumentContainsItemPackaging
	|INTO PrintObjects
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|WHERE
	|	SalesOfGoodsServicesGoods.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	SalesOfGoodsServicesGoods.Ref AS Ref,
	|	SalesOfGoodsServicesGoods.Warehouse  AS Warehouse,
	|	ISNULL(SalesOfGoodsServicesGoods.Warehouse.UseItemsBatch, FALSE) AS UseItemsBatch
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|	INNER JOIN PrintObjects AS PrintObjects
	|		ON SalesOfGoodsServicesGoods.Ref = PrintObjects.Ref
	|		AND NOT PrintObjects.ThisIsTransferOfOwnership
	|		AND PrintObjects.DocumentContainsItemPackaging
	|
	|TOTALS BY
	|	Ref,
	|	UseItemsBatch
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	PrintObjects.Ref                               AS Ref,
	|	PRESENTATION(PrintObjects.Ref)                AS RepresentationOfTheReference,
	|	PrintObjects.BusinessOperation                AS BusinessOperation,
	|	PRESENTATION(PrintObjects.BusinessOperation) AS PresentationOfBusinessTransaction,
	|	PrintObjects.ThisIsTransferOfOwnership         AS ThisIsTransferOfOwnership,
	|	PrintObjects.DocumentContainsItemPackaging              AS DocumentContainsItemPackaging
	|FROM
	|	PrintObjects AS PrintObjects
	|";
	
	RequestForWarehouses.SetParameter("ObjectsArray", ObjectsArray);
	
	QueryResults = RequestForWarehouses.ExecuteBatch();

	ObjectsTree = QueryResults[QueryResults.UBound()-1].Unload(
		QueryResultIteration.ByGroups); // 1
	CheckTable = QueryResults[QueryResults.UBound()].Unload(); // 2
	
	FirstDocument = True;
	
	For Each DocumentLine In ObjectsTree.Rows Do
		
		RowNumberStart = Undefined;
		
		For Each UsingSeries In DocumentLine.Rows Do
			
			RequestForProducts = New Query;
			RequestForProducts.SetParameter("ObjectsArray", DocumentLine.Ref);
			RequestForProducts.SetParameter("WarehouseArray",  UsingSeries.Rows.UnloadColumn("Warehouse"));
			
			If UsingSeries.UseItemsBatch Then
				
				QueryTextByGoods = 
				"SELECT
				|	SalesOfGoodsServicesGoods.LineNumber AS LineNumber,
				|	SalesOfGoodsServicesGoods.Ref AS Ref,
				|	SalesOfGoodsServicesGoods.Warehouse AS Warehouse,
				|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
				|	SalesOfGoodsServicesGoods.Count AS Count,
				|	SalesOfGoodsServicesGoods.Products AS Products,
				|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
				|	SalesOfGoodsServicesGoods.Package AS Package,
				|	"""" AS Series
				|INTO TableOfGoods
				|FROM
				|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
				|WHERE
				|	SalesOfGoodsServicesGoods.Ref IN(&ObjectsArray)
				|	AND SalesOfGoodsServicesGoods.Warehouse IN(&WarehouseArray)
				|	AND NOT(SalesOfGoodsServicesGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
				|				AND SalesOfGoodsServicesGoods.BatchesIndicationStatus IN (2, 4, 6, 8))
				|
				|UNION ALL
				|
				|SELECT DISTINCT
				|	SalesOfGoodsServicesSeries.LineNumber,
				|	SalesOfGoodsServicesSeries.Ref,
				|	SalesOfGoodsServicesSeries.Warehouse,
				|	SalesOfGoodsServicesSeries.Count,
				|	SalesOfGoodsServicesSeries.Count,
				|	SalesOfGoodsServicesSeries.Products,
				|	SalesOfGoodsServicesSeries.Characteristic,
				|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
				|	SalesOfGoodsServicesSeries.Series
				|FROM
				|	Document.CustomerInvoice.SetOfSeries AS SalesOfGoodsServicesSeries
				|		INNER JOIN Document.CustomerInvoice.Goods AS GoodsTable
				|		ON SalesOfGoodsServicesSeries.Ref = GoodsTable.Ref
				|			AND SalesOfGoodsServicesSeries.Products = GoodsTable.Products
				|			AND SalesOfGoodsServicesSeries.Characteristic = GoodsTable.Characteristic
				|			AND SalesOfGoodsServicesSeries.Warehouse = GoodsTable.Warehouse
				|WHERE
				|	SalesOfGoodsServicesSeries.Ref IN(&ObjectsArray)
				|	AND SalesOfGoodsServicesSeries.Warehouse IN(&WarehouseArray)
				|	AND SalesOfGoodsServicesSeries.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
				|	AND GoodsTable.BatchesIndicationStatus IN (2, 4, 6, 8, 10)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TableOfGoods.LineNumber,
				|	TableOfGoods.Ref,
				|	TableOfGoods.Warehouse,
				|	SUM(TableOfGoods.NumberOfPackages) AS NumberOfPackages,
				|	SUM(TableOfGoods.Count) AS Count,
				|	TableOfGoods.Products,
				|	TableOfGoods.Characteristic,
				|	TableOfGoods.Package,
				|	CASE
				|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
				|			THEN NULL
				|		ELSE TableOfGoods.Series
				|	END AS Series
				|INTO SummaryTableOfProducts
				|FROM
				|	TableOfGoods AS TableOfGoods
				|
				|GROUP BY
				|	TableOfGoods.LineNumber,
				|	TableOfGoods.Ref,
				|	TableOfGoods.Warehouse,
				|	TableOfGoods.Products,
				|	TableOfGoods.Characteristic,
				|	TableOfGoods.Package,
				|	CASE
				|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
				|			THEN NULL
				|		ELSE TableOfGoods.Series
				|	END
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TableOfGoods.LineNumber,
				|	TableOfGoods.Ref AS Ref,
				|	TableOfGoods.Ref.Organization AS Organization,
				|	TableOfGoods.Ref.Counterparty AS Counterparty,
				|	TableOfGoods.Ref.Number AS Number,
				|	TableOfGoods.Ref.Date AS Date,
				|	TableOfGoods.Ref.Organization.Prefix AS Prefix,
				|	TableOfGoods.Warehouse AS Warehouse,
				|	CASE
				|		WHEN TableOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
				|			THEN REFPRESENTATION(TableOfGoods.Products.UnitOfMeasure)
				|		ELSE REFPRESENTATION(TableOfGoods.Package)
				|	END AS PresentationOfPackingUnit,
				|	PRESENTATION(TableOfGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
				|	TableOfGoods.NumberOfPackages AS NumberOfPackages,
				|	TableOfGoods.Count AS Count,
				|	TableOfGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings,
				|	TableOfGoods.Products.Code AS Code,
				|	TableOfGoods.Products.SKU AS SKU,
				|	TableOfGoods.Products.DescriptionFull AS ProductPresentation,
				|	TableOfGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
				|	TableOfGoods.Products AS Products,
				|	TableOfGoods.Characteristic AS Characteristic,
				|	CASE
				|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
				|			THEN UNDEFINED
				|		ELSE TableOfGoods.Package.Description
				|	END AS Package,
				|	TableOfGoods.Series.Description AS BatchPresentation,
				|	CASE
				|		WHEN TableOfGoods.Ref.ToReturnReusablePackage
				|				AND TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
				|			THEN TRUE
				|		ELSE FALSE
				|	END AS ThisIsReusablePackage
				|FROM
				|	SummaryTableOfProducts AS TableOfGoods
				|
				|ORDER BY LineNumber
				|
				|TOTALS BY
				|	Ref,
				|	Warehouse,
				|	Products,
				|	Characteristic
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TableOfGoods.LineNumber,
				|	TableOfGoods.Ref AS Ref,
				|	TableOfGoods.Warehouse AS Warehouse,
				|	TableOfGoods.Products AS Products,
				|	TableOfGoods.Characteristic AS Characteristic,
				|	TableOfGoods.Series.Description AS BatchPresentation
				|FROM
				|	TableOfGoods AS TableOfGoods
				|WHERE
				|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
				|	AND NOT TableOfGoods.Series IS NULL 
				|ORDER BY LineNumber
				|";
				
				QueryTextByGoods = StrReplace(QueryTextByGoods, "&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"TableOfGoods.Package",
						"TableOfGoods.Products"));
				
				RequestForProducts.Text	 = QueryTextByGoods;
				ResultsArray		 = RequestForProducts.ExecuteBatch();
				
				ResultPrintData		= ResultsArray[2]; // QueryResult
				ResultSelectionBySeries	= ResultsArray[3]; // QueryResult
				
				PrintData				= ResultPrintData.Select(QueryResultIteration.ByGroups);
				SelectionBySeries 			= ResultSelectionBySeries.Select();
				
			Else
				
				QueryTextByGoods = 
				"SELECT
				|	SalesOfGoodsServicesGoods.LineNumber AS LineNumber,
				|	SalesOfGoodsServicesGoods.Ref AS Ref,
				|	SalesOfGoodsServicesGoods.Ref.Organization AS Organization,
				|	SalesOfGoodsServicesGoods.Ref.Counterparty AS Counterparty,
				|	SalesOfGoodsServicesGoods.Ref.Number AS Number,
				|	SalesOfGoodsServicesGoods.Ref.Date AS Date,
				|	SalesOfGoodsServicesGoods.Ref.Organization.Prefix AS Prefix,
				|	SalesOfGoodsServicesGoods.Warehouse AS Warehouse,
				|	CASE
				|		WHEN SalesOfGoodsServicesGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
				|			THEN REFPRESENTATION(SalesOfGoodsServicesGoods.Products.UnitOfMeasure)
				|		ELSE REFPRESENTATION(SalesOfGoodsServicesGoods.Package)
				|	END AS PresentationOfPackingUnit,
				|	PRESENTATION(SalesOfGoodsServicesGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
				|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
				|	SalesOfGoodsServicesGoods.Count AS Count,
				|	SalesOfGoodsServicesGoods.Products.Code AS Code,
				|	SalesOfGoodsServicesGoods.Products.SKU AS SKU,
				|	SalesOfGoodsServicesGoods.Products.DescriptionFull AS ProductPresentation,
				|	SalesOfGoodsServicesGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
				|	"""" AS BatchPresentation,
				|	CASE
				|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
				|			THEN UNDEFINED
				|		ELSE SalesOfGoodsServicesGoods.Package.Description
				|	END AS Package,
				|	CASE
				|		WHEN SalesOfGoodsServicesGoods.Ref.ToReturnReusablePackage
				|				AND SalesOfGoodsServicesGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
				|			THEN TRUE
				|		ELSE FALSE
				|	END AS ThisIsReusablePackage,
				|	NULL AS BatchUsageSettings,
				|	SalesOfGoodsServicesGoods.Products AS Products,
				|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic
				|FROM
				|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
				|WHERE
				|	SalesOfGoodsServicesGoods.Ref IN(&ObjectsArray)
				|	AND SalesOfGoodsServicesGoods.Warehouse IN(&WarehouseArray)
				|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
				|
				|ORDER BY LineNumber
				|
				|TOTALS BY
				|	Ref,
				|	Warehouse,
				|	Products,
				|	Characteristic";
				
				QueryTextByGoods = StrReplace(QueryTextByGoods, "&QueryTextPackagingFactor",
					Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
						"SalesOfGoodsServicesGoods.Package",
						"SalesOfGoodsServicesGoods.Products"));
				
				RequestForProducts.Text = QueryTextByGoods;
				PrintData = RequestForProducts.Execute().Select(QueryResultIteration.ByGroups);
				
			EndIf;
			
			Template = PrintManagement.PrintFormTemplate("Document.CustomerInvoice.PF_MXL_ExpenseToPrint");
			
			WidthOfMissingAreas = 0;
			If Not OutputCodes Then
				WidthOfMissingAreas = Template.Area("ColumnOfCodes").ColumnWidth;
			EndIf;
			
			If Not UsePackages Then
				
				WidthOfMissingAreas = WidthOfMissingAreas + Template.Area("NumberOfPackagesColumn").ColumnWidth;
				WidthOfMissingAreas = WidthOfMissingAreas + Template.Area("PresentationColumnOfPackages").ColumnWidth;
				
			EndIf;
			
			// Expand the "Goods column" by the width of the missing areas
			Template.Area("ProductColumn_").ColumnWidth = Template.Area("ProductColumn_").ColumnWidth + WidthOfMissingAreas;
			
			DocumentAttributes = New Structure("Number, Date, Prefix, Presentation");
	
			While PrintData.Next() Do
				
				SearchParameters = New Structure("Ref", PrintData.Ref);
				FoundRows = CheckTable.FindRows(SearchParameters);
				
				For Each FoundRow In FoundRows Do
					CheckTable.Delete(FoundRow);
				EndDo;
				
				If RowNumberStart = Undefined Then
					RowNumberStart = SpreadsheetDocument.TableHeight + 1;
				EndIf;
				
				FillPropertyValues(DocumentAttributes, PrintData);
				
				SampleByWarehouse = PrintData.Select(QueryResultIteration.ByGroups);
				While SampleByWarehouse.Next() Do
					
					If Not FirstDocument Then
						SpreadsheetDocument.PutHorizontalPageBreak();
					EndIf;
					
					FirstDocument = False;
					
					Area = Template.GetArea("Title");
					DataStructureHeader = New Structure;
					DataStructureHeader.Insert("TitleText", NStr("vi = 'Phiếu giao hàng kiêm xuất kho';
																|ru = 'Расходная накладная';
																|en = 'Sales invoice'; fa = 'فاکتور فروش';
																|it = 'Bolla di consegna';
																|pl = 'Faktura wydanie na zewnątrz';
																|tr = 'Satış faturası'", Common.DefaultLanguageCode()));
					BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, PrintData.Ref);
					Area.Parameters.Fill(DataStructureHeader);
					SpreadsheetDocument.Put(Area);
					
					Area = Template.GetArea("Header");
					HeaderDataStructure_ = New Structure;
					HeaderDataStructure_.Insert("PresentationOfOrder", TMCommonUseClientServer.GenerateDocumentTitle(
						DocumentAttributes, NStr("vi = 'Giao hàng';
												|ru = 'Реализация товаров';
												|en = 'Goods sales'; fa = 'فروش کالا';
												|it = 'Vendita delle merci';
												|pl = 'Sprzedaż towarów';
												|tr = 'Malların satışı'", Common.DefaultLanguageCode())));
					HeaderDataStructure_.Insert("WarehousePresentation_", SampleByWarehouse.Warehouse);
					HeaderDataStructure_.Insert("Warehouse", SampleByWarehouse.Warehouse);
					Area.Parameters.Fill(HeaderDataStructure_);
					SpreadsheetDocument.Put(Area);
					
					Area = Template.GetArea("Vendor");
					DataStructureProvider = New Structure;
					DataStructureProvider.Insert("RepresentationOfTheOrganization", 
						PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(SampleByWarehouse.Organization, SampleByWarehouse.Date), 
							"FullDescr"));
					DataStructureProvider.Insert("Organization", SampleByWarehouse.Organization);
					Area.Parameters.Fill(DataStructureProvider);
					SpreadsheetDocument.Put(Area);
					
					Area = Template.GetArea("Customer");
					CustomerDataStructure = New Structure;
					DataStructureProvider.Insert("PartnerPresentation_", 
						PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(SampleByWarehouse.Counterparty, SampleByWarehouse.Date),
							"FullDescr"));
					DataStructureProvider.Insert("Counterparty", SampleByWarehouse.Counterparty);
					Area.Parameters.Fill(DataStructureProvider);
					SpreadsheetDocument.Put(Area);
					
					Area = Template.GetArea("TableHeader|BeginningOfTheLine");
					SpreadsheetDocument.Put(Area);
					If OutputCodes Then
						Area = Template.GetArea("TableHeader|ColumnOfCodes");
						DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
						Area.Parameters.Fill(DataStructureCodes);
						SpreadsheetDocument.Join(Area);
					EndIf;
					Area = Template.GetArea("TableHeader|ProductColumn_");
					SpreadsheetDocument.Join(Area);
					If UsePackages Then
						Area = Template.GetArea("TableHeader|PackingColumns");
						SpreadsheetDocument.Join(Area);
					EndIf;
					Area = Template.GetArea("TableHeader|QuantityColumns");
					SpreadsheetDocument.Join(Area);
					
					StartOfLineArea		 = Template.GetArea("TableRow|BeginningOfTheLine");
					AreaColumnCodes		 = Template.GetArea("TableRow|ColumnOfCodes");
					ProductColumnArea_	 = Template.GetArea("TableRow|ProductColumn_");
					PackagingColumnArea	 = Template.GetArea("TableRow|PackingColumns");
					AreaQuantityColumn = Template.GetArea("TableRow|QuantityColumns");
	
					LineCount = 1;				
	
					SamplingByTSLinks = SampleByWarehouse.Select(QueryResultIteration.ByGroups);
	
					While SamplingByTSLinks.Next() Do
	
						SamplingByTSProduct = SamplingByTSLinks.Select(QueryResultIteration.ByGroups);
	
						While SamplingByTSProduct.Next() Do
	
							SamplingByTSLines = SamplingByTSProduct.Select(QueryResultIteration.ByGroups);
							
							FirstRow = True;
							StringOfPackages = "";
							NumberOfPackagesString = "";
							UnitString = "";
							CountRow = "";
							
							While SamplingByTSLines.Next() Do
								
								If SamplingByTSLines.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
									
									If FirstRow Then
										
										DataStructureLineNumber = New Structure("LineNumber", LineCount);
										StartOfLineArea.Parameters.Fill(DataStructureLineNumber);
										LineCount = LineCount + 1;
										SpreadsheetDocument.Put(StartOfLineArea);
										If OutputCodes Then
											DataStructureCodes = New Structure("CodeValue", SamplingByTSLines[NameOfCodeColumn]);
											AreaColumnCodes.Parameters.Fill(DataStructureCodes);
											SpreadsheetDocument.Join(AreaColumnCodes);
										EndIf;
										
										TheStructureOfTheSearch = New Structure;
										TheStructureOfTheSearch.Insert("Ref", SamplingByTSLines.Ref);
										TheStructureOfTheSearch.Insert("Warehouse", SamplingByTSLines.Warehouse);
										TheStructureOfTheSearch.Insert("Products", SamplingByTSLines.Products);
										TheStructureOfTheSearch.Insert("Characteristic", SamplingByTSLines.Characteristic);
										
										SeriesString = "";
										While SelectionBySeries.FindNext(TheStructureOfTheSearch) Do
											SeriesString = SeriesString + SelectionBySeries.BatchPresentation + ", ";
										EndDo;
										
										If StrLen(SeriesString) <> 0 Then
											SeriesString = Left(SeriesString, StrLen(SeriesString) - 2);
										EndIf;
										
										AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
										AdditionalParametersForGettingNameToPrint.ReturnContainers = SamplingByTSLines.ThisIsReusablePackage;
										AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
										
										OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
											SamplingByTSLines.ProductPresentation,
											SamplingByTSLines.CharacteristicPresentation,
											,
											SeriesString,
											AdditionalParametersForGettingNameToPrint);
										
										ProductDataStructure = New Structure("OwnGoods", OwnGoods);
										ProductColumnArea_.Parameters.Fill(ProductDataStructure);
										
										SpreadsheetDocument.Join(ProductColumnArea_);
										
										FirstRow = False;
										
									EndIf;
									
									If UsePackages Then
										StringOfPackages = StringOfPackages + SamplingByTSLines.PresentationOfPackingUnit + Chars.LF;
										NumberOfPackagesString = NumberOfPackagesString + SamplingByTSLines.NumberOfPackages + Chars.LF;
									EndIf;
									
									UnitString = UnitString + SamplingByTSLines.PresentationOfBasicUnitOfMeasure + Chars.LF;
									CountRow = CountRow + SamplingByTSLines.Count + Chars.LF;
									
									ProductWithSeriesInstance = True;
																	
								Else			
									
									DataStructureLineNumber = New Structure("LineNumber", LineCount);
									StartOfLineArea.Parameters.Fill(DataStructureLineNumber);
									LineCount = LineCount + 1;
									SpreadsheetDocument.Put(StartOfLineArea);
									
									If OutputCodes Then
										DataStructureCodes = New Structure("CodeValue", SamplingByTSLines[NameOfCodeColumn]);
										AreaColumnCodes.Parameters.Fill(DataStructureCodes);
										SpreadsheetDocument.Join(AreaColumnCodes);
									EndIf;
									
									AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
									AdditionalParametersForGettingNameToPrint.ReturnContainers = SamplingByTSLines.ThisIsReusablePackage;
									AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
									
									OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
										SamplingByTSLines.ProductPresentation,
										SamplingByTSLines.CharacteristicPresentation,
										,
										SamplingByTSLines.BatchPresentation,
										AdditionalParametersForGettingNameToPrint);
										
									ProductDataStructure = New Structure("OwnGoods", OwnGoods);
									ProductColumnArea_.Parameters.Fill(ProductDataStructure);
									
									SpreadsheetDocument.Join(ProductColumnArea_);
									
									If UsePackages Then 									
										PackagingColumnArea.Parameters.Fill(SamplingByTSLines);
										SpreadsheetDocument.Join(PackagingColumnArea);
									EndIf;
									
									AreaQuantityColumn.Parameters.Fill(SamplingByTSLines);
									SpreadsheetDocument.Join(AreaQuantityColumn);
									
									ProductWithSeriesInstance = False;
												
								EndIf;
								
							EndDo;
							
							If ProductWithSeriesInstance Then
								If UsePackages Then
									DataStructurePackingColumn = New Structure;
									DataStructurePackingColumn.Insert("NumberOfPackages", NumberOfPackagesString);
									DataStructurePackingColumn.Insert("PresentationOfPackingUnit", StringOfPackages);
									PackagingColumnArea.Parameters.Fill(DataStructurePackingColumn);
									SpreadsheetDocument.Join(PackagingColumnArea);
								EndIf;
								
								DataStructureQuantityColumn = New Structure;
								DataStructureQuantityColumn.Insert("Count", CountRow);
								DataStructureQuantityColumn.Insert("PresentationOfBasicUnitOfMeasure", UnitString);
								AreaQuantityColumn.Parameters.Fill(DataStructureQuantityColumn);
								SpreadsheetDocument.Join(AreaQuantityColumn);
								
							EndIf;
							
						EndDo;
						
					EndDo;
					
					Area = Template.GetArea("TableFooter|BeginningOfTheLine");
					SpreadsheetDocument.Put(Area);
					If OutputCodes Then
						Area = Template.GetArea("TableFooter|ColumnOfCodes");
						SpreadsheetDocument.Join(Area);
					EndIf;
					Area = Template.GetArea("TableFooter|ProductColumn_");
					SpreadsheetDocument.Join(Area);
					If UsePackages Then
						Area = Template.GetArea("TableFooter|PackingColumns");
						SpreadsheetDocument.Join(Area);
					EndIf;
					Area = Template.GetArea("TableFooter|QuantityColumns");
					SpreadsheetDocument.Join(Area);
					
					Area = Template.GetArea("Signatures");
					TextOfResultingLine = NStr("vi = 'Số lượng các dòng là: %TotalItems_1%';
												|ru = 'Всего наименований %TotalItems_1%';
												|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
												|it = 'Totale articoli %TotalItems_1%';
												|pl = 'Razem pozycji %TotalItems_1%';
												|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
					TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", LineCount-1);
					DataStructureSummaryRow = New Structure;
					DataStructureHeader.Insert("TotalString", TextOfResultingLine);
					Area.Parameters.Fill(DataStructureHeader);
					SpreadsheetDocument.Put(Area);
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
		If Not RowNumberStart = Undefined Then
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, DocumentLine.Ref);
		EndIf;
	
	EndDo;
	
	For Each TableRow In CheckTable Do
		
		If TableRow.ThisIsTransferOfOwnership Then
			
			MessageText = NStr("vi = 'Trong chứng từ có %1 giao dịch kinh tế %2. Không cần in hóa đơn giao hàng.';
								|ru = 'В документе %1 хозяйственная операция %2. Печать расходной накладной не требуется.';
								|en = 'The ""%1"" document has the ""%2"" business transaction. Printing a sales invoice is not required.'; fa = 'The ""%1"" document has the ""%2"" business transaction. Printing a sales invoice is not required.';
								|it = 'The ""%1"" document has the ""%2"" business transaction. Printing a sales invoice is not required.';
								|pl = 'The ""%1"" document has the ""%2"" business transaction. Printing a sales invoice is not required.';
								|tr = 'Belge %1, %2 ticari işlemi mevcuttur. Öğe sertifikalarının basılmaları gerekmemektedir.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageText,
				TableRow.RepresentationOfTheReference,
				TableRow.PresentationOfBusinessTransaction);
			
			Common.MessageToUser(
				MessageText,
				TableRow.Ref);
			
			Continue;
			
		EndIf;
		
		If Not TableRow.DocumentContainsItemPackaging Then
		
			MessageText = NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in hóa đơn chi phí';
								|ru = 'В документе %1 отсутствуют товары. Печать расходной накладной не требуется.';
								|en = 'Goods are missing in document %1. Printing of a sales invoice is not required.'; fa = 'Goods are missing in document %1. Printing of a sales invoice is not required.';
								|it = 'Nel documento %1 non contiene le merci. La stampa della bolla non è richiesta.';
								|pl = 'Brak towarów w dokumencie %1. Nie jest potrzebne drukowanie zlecenia wydania towaru.';
								|tr = 'Belge %1''de mal bulunmamaktadır. Satış faturasının yazdırılmasına gerek yoktur'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageText,
				TableRow.RepresentationOfTheReference);
			
			Common.MessageToUser(
				MessageText,
				TableRow.Ref);
		
		EndIf;
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// The function receives data for generating a printed form " Notification"
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//  LanguageCode - String - the language in which the printed form will be displayed.
//                         It consists of the language code according to ISO 639-1 and, optionally, the country code according to ISO 3166-1, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_EN".
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultsByPaymentStages - QueryResult
// 		* ResultForTabularPart - QueryResult
//
Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE Documents.CompanyBankAccount.Bank.InternationalDescription END AS BankNameInt,
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE Documents.CompanyBankAccount.TransferBank.InternationalDescription END AS BankNameForPaymentsInt,
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE Documents.CompanyBankAccount.Bank.SWIFTBIC END AS BankSWIFTCode,
	|	CASE WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE Documents.CompanyBankAccount.TransferBank.SWIFTBIC END AS BankSWIFTCodeForPayments,
	|	CASE WHEN Documents.CompanyBankAccount.ManualBankDetailsChange THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE Documents.CompanyBankAccount.Bank.InternationalAddress END AS BankAddress,
	|	CASE WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE Documents.CompanyBankAccount.TransferBank.InternationalAddress END AS TransferBankAddress,
	|	
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.Shipper AS Shipper,
	|	Documents.GoodsRecipient AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.CustomerInvoice AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.LineNumber AS LineNumber,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	DocumentData.PackageDepositValue AS PaymentAmount,
	|	TRUE AS ThisIsDepositForPackage
	|
	|FROM
	|	Document.CustomerInvoice.PaymentScheduleSteps AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND DocumentData.PackageDepositValue > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.LineNumber AS LineNumber,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	
	|	DocumentData.PaymentPercentage AS PaymentPercentage,
	|	
	|	DocumentData.PaymentAmount - DocumentData.PackageDepositValue AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|
	|FROM
	|	Document.CustomerInvoice.PaymentScheduleSteps AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet                              AS ProductsInSet,
	|	Table.ItemVariantOfSet                            AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Table.Price
	|		ELSE Table.Sum/Table.NumberOfPackages 
	|	END AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	CASE
	|		WHEN
	|			Table.Ref.ToReturnReusablePackage
	|			AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Table.ManualDiscount + Table.DiscountMarkupAmount
	|		ELSE 0 
	|	END AS DiscountAmount,
	|	Table.Sum + Table.ManualDiscount + Table.DiscountMarkupAmount AS AmountWithoutADiscount
	|INTO Goods
	|FROM
	|	Document.CustomerInvoice.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|	AND (Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		AND (NOT Table.Ref.ToReturnReusablePackage OR Table.Ref.PackageDepositIsRequired))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount)  AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount,
	|	Table.DiscountAmount                       AS DiscountAmount,
	|	Table.AmountWithoutADiscount                    AS AmountWithoutADiscount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Goods.Ref											AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet								AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Goods.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Goods.ItemVariantOfSet								AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Goods.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|	Goods.DiscountAmount                                       AS DiscountAmount,
	|	Goods.AmountWithoutADiscount                                    AS AmountWithoutADiscount,
	|	Goods.ThisIsReusablePackage                                 AS ThisIsReusablePackage	
	|FROM (
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATRate,
	|		Table.VATAmount,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.ThisIsReusablePackage
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN &DisplayDiscounts_ THEN
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.AmountWithoutADiscount) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|			ELSE
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.ProductsInSet.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Goods.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Goods.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
	EndIf;
	
EndProcedure

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Other

// Returns an empty value orders
//
// Returns:
//  Array - an array of empty values.
//
Function EmptyOrderValues() Export
	
	EmptyOrderValues = New Array;
	EmptyOrderValues.Add(Undefined);
	EmptyOrderValues.Add(Documents.SalesOrder.EmptyRef());
	EmptyOrderValues.Add(Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef());
	
	Return EmptyOrderValues;
	
EndFunction

// Returns the base text based on the document data and the specified calculation order
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.CustomerInvoice - The object of the document for which you want to get the text of the base
//	ARAPObjectSettings - EnumRef.ARAPObjectSettings - Procedure of settlements.
//
// Returns:
//	Structure- Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object, ARAPObjectSettings)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		And ValueIsFilled(Object.Contract) Then
		
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
		
	ElsIf (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		And Object.OrderSales Then
		
		AnArrayOfOrders = Undefined;
		If ValueIsFilled(Object.SalesOrder) Then
			AnArrayOfOrders = New Array;
			AnArrayOfOrders.Add(Object.SalesOrder);
		ElsIf Object.Goods.Count() <> 0 Then 
			If TypeOf(Object) = Type("Structure") Then
				AnArrayOfOrders = Object.Goods.UnloadColumn("SalesOrder");
			Else
				AnArrayOfOrders = Object.Goods.Unload(,"SalesOrder").UnloadColumn("SalesOrder");
			EndIf;
		EndIf;
		
		If AnArrayOfOrders <> Undefined Then
		
			Query = New Query(
				"SELECT ALLOWED
				|	SalesOrders.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
				|	SalesOrders.DateAccordingToInformationFromCustomer  AS DateAccordingToInformationFromCustomer,
				|	SalesOrders.Number                AS Number,
				|	SalesOrders.Date                 AS Date,
				|	&SynonymForOrder                      AS Synonym
				|FROM
				|	Document.SalesOrder AS SalesOrders
				|WHERE
				|	SalesOrders.Ref IN(&AnArrayOfOrders)
				|
				|UNION ALL
				|
				|SELECT
				|	NULL AS NumberAccordingToCustomerData,
				|	NULL AS DateAccordingToInformationFromCustomer,
				|	RequestsForReturn.Number,
				|	RequestsForReturn.Date,
				|	&ApplicationSynonym
				|FROM
				|	Document.RequestForReturnOfGoodsFromCustomer AS RequestsForReturn
				|WHERE
				|	RequestsForReturn.Ref IN(&AnArrayOfOrders)
				|
				|UNION ALL
				|
				|SELECT
				|	NULL AS NumberAccordingToCustomerData,
				|	NULL AS DateAccordingToInformationFromCustomer,
				|	ShipmentOfItems.Number,
				|	ShipmentOfItems.Date,
				|	&SynonymForShipmentOfItems
				|FROM
				|	Document.GoodsShipmentToCustomer AS ShipmentOfItems
				|WHERE
				|	ShipmentOfItems.Ref IN(&AnArrayOfOrders)
				|
				|UNION ALL
				|
				|SELECT
				|	NULL AS NumberAccordingToCustomerData,
				|	NULL AS DateAccordingToInformationFromCustomer,
				|	SourceDocument.Number,
				|	SourceDocument.Date,
				|	&SynonymForShipmentOfItems
				|FROM
				|	Document.SourceDocument AS SourceDocument
				|WHERE
				|	SourceDocument.Ref IN(&AnArrayOfOrders)
				|");
			Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
			Query.SetParameter("SynonymForOrder", NStr("vi = 'Đơn hàng của khách';
														|ru = 'Заказ клиента';
														|en = 'Sales order'; fa = 'سفارش فروش';
														|it = 'Ordine del cliente';
														|pl = 'Zamówienie klienta';
														|tr = 'Satış siparişi'", Common.DefaultLanguageCode()));
			Query.SetParameter("ApplicationSynonym", NStr("vi = 'Giấy đề nghị đổi hàng';
															|ru = 'Заявка на замену';
															|en = 'Request for replacement'; fa = 'Request for replacement';
															|it = 'Domanda di sostituzione';
															|pl = 'Wniosek o wymianę';
															|tr = 'Değiştirme talebi'", Common.DefaultLanguageCode()));
			Query.SetParameter("SynonymForShipmentOfItems", NStr("vi = 'Giao hàng cho khách';
																|ru = 'Отгрузка товаров клиенту';
																|en = 'Goods shipment to customer'; fa = 'ارسال کالا به مشتری';
																|it = 'Goods shipment to customer';
																|pl = 'Goods shipment to customer';
																|tr = 'Müşteriye ürün sevkiyatı'", Common.DefaultLanguageCode()));
			Selection = Query.Execute().Select();
			
			TextForOrders = "";
			OneFoundation = Selection.Count() = 1;
			While Selection.Next() Do
				If ValueIsFilled(Selection.NumberAccordingToCustomerData) And ValueIsFilled(Selection.DateAccordingToInformationFromCustomer) Then
					TextForOrders = TextForOrders + ", " +
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '%1 số %2 ngày %3';
								|ru = '%1 № %2 от %3';
								|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
								|it = '%1 № %2 dal %3';
								|pl = '%1 nr %2 z dnia %3.';
								|tr = '%2sayılı %3tarihli %1'", Common.DefaultLanguageCode()),
							Selection.Synonym, Selection.NumberAccordingToCustomerData, Format(Selection.DateAccordingToInformationFromCustomer, "DLF=DD"));
					DateForOrders  = Selection.DateAccordingToInformationFromCustomer;
					OrderNumber_1 = Selection.NumberAccordingToCustomerData;
				Else
					NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number);
					DocumentTitle = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 số %2 ngày %3';
							|ru = '%1 № %2 от %3';
							|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
							|it = '%1 № %2 dal %3';
							|pl = '%1 nr %2 z dnia %3.';
							|tr = '%2sayılı %3tarihli %1'", Common.DefaultLanguageCode()),
						Selection.Synonym, NumberForPrinting, Format(Selection.Date, "DLF=DD"));
					TextForOrders = TextForOrders + ", " + DocumentTitle;
					DateForOrders  = Selection.Date;
					OrderNumber_1 = ?(OneFoundation,ObjectsPrefixesClientServer.NumberForPrinting(Selection.Number),"");
				EndIf;
			EndDo;
			StructureBase.Basis =  TrimAll(Mid(TextForOrders, 3));
			StructureBase.ReferenceDocumentDateForPrintForms = ?(OneFoundation, DateForOrders, "");
			StructureBase.BaseDocumentNumber = OrderNumber_1;
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

// Generates the request text that receives the payment schedule for the document
//
// Returns:
//   String   - the generated request text.
//
Function QueryTextPaymentSchedule()

	Return "
	|SELECT
	|	PaymentScheduleSteps.Ref AS Document,
	|	PaymentScheduleSteps.LineNumber AS LineNumber,
	|	PaymentScheduleSteps.PaymentOption AS PaymentOption,
	|	PaymentScheduleSteps.PaymentDate AS PaymentDate,
	|	PaymentScheduleSteps.PaymentAmount AS PaymentAmount
	|FROM
	|	Document.CustomerInvoice.PaymentScheduleSteps AS PaymentScheduleSteps
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON (ARAPObjects.ARAPObject = PaymentScheduleSteps.Ref)
	|		AND ARAPObjects.ScheduleIsRequired";

EndFunction 

Function QueryTextTTGoodsOrderInvoiceShipped()
	
	Return "
	|SELECT ALLOWED
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	DocumentGoods.Series AS Series,
	|	DocumentGoods.Warehouse AS Warehouse,
	|	TTDocuments.DocumentRef AS Ref
	|INTO TTGoodsNotShipped
	|FROM
	|	Document.CustomerInvoice.Goods AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	TTDocuments.Posted
	|	AND (NOT DocumentGoods.Ref.OrderSales
	|			OR ISNULL(DocumentGoods.SalesOrder.ThisIsOrderAsInvoice, NOT &UseAdvancedFeaturesOfSalesOrder))
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series,
	|	DocumentGoods.Warehouse,
	|	TTDocuments.DocumentRef;";
	
EndFunction

// Generates the query result for the undelivered part of orders
//
// Parameters:
//	SelectionData_     - Structure - the fields that will be selected remains orders
//	FillParameters - Structure - 
//	ImplementationWarehouse  - CatalogRef.Warehouses - warehouse where order balances will be selected
//	AnArrayOfOrders    - Array of DocumentRef - orders for which balances will be selected
//
// Returns:
//	QueryResult - the result of the request for the unloaded part of orders \ requests.
//
Function GetQueryResultsForOrderBalances(SelectionData_,
	                                              FillParameters,
	                                              ImplementationWarehouse = Undefined,
	                                              AnArrayOfOrders = Undefined)
	
	Query = New Query;
	
	Query.SetParameter("AnArrayOfOrders",             AnArrayOfOrders);
	Query.SetParameter("Partner",                   SelectionData_.Partner);
	Query.SetParameter("Counterparty",                SelectionData_.Counterparty);
	Query.SetParameter("Contract",                   SelectionData_.Contract);
	Query.SetParameter("Organization",               SelectionData_.Organization);
	Query.SetParameter("SalesOpportunity",                    SelectionData_.SalesOpportunity);
	Query.SetParameter("Terms",                SelectionData_.Terms);
	Query.SetParameter("ARAPCurrency",      SelectionData_.ARAPCurrency);
	Query.SetParameter("VATTaxation",        SelectionData_.VATTaxation);
	Query.SetParameter("PriceIncludesVAT",           SelectionData_.PriceIncludesVAT);
	Query.SetParameter("ToReturnReusablePackage", SelectionData_.ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired",      SelectionData_.PackageDepositIsRequired);
	Query.SetParameter("ARAPObjectSettings",           SelectionData_.ARAPObjectSettings);
	Query.SetParameter("Recorder",               SelectionData_.Ref);
	Query.SetParameter("ImplementationWarehouse",           ImplementationWarehouse);
	Query.SetParameter("SelectByOrder_",          AnArrayOfOrders <> Undefined);
	Query.SetParameter("BusinessOperation",     SelectionData_.BusinessOperation);
	Query.SetParameter("CurrentDate",               BegOfDay(CurrentSessionDate()));
	Query.SetParameter("ToUseTermsOfSales",
		GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("LineOfBusiness",        SelectionData_.LineOfBusiness);
	Query.SetParameter("UseLinesOfBusiness",
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	TaxationOfVATExports = SelectionData_.VATTaxation = Enums.VATTaxationTypes.ExportSale
		Or SelectionData_.VATTaxation = Enums.VATTaxationTypes.ExportOfCommoditiesServicesWorks
		Or SelectionData_.VATTaxation = Enums.VATTaxationTypes.ExportOfNonResourceGoods;
	Query.SetParameter("TaxationOfVATExports", TaxationOfVATExports);
		
	UseAdvancedFeaturesOfSalesOrder = Undefined;
	FillParameters.Property("UseAdvancedFeaturesOfSalesOrder",
		UseAdvancedFeaturesOfSalesOrder);
	If UseAdvancedFeaturesOfSalesOrder = Undefined Then
		UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	Query.SetParameter("ThisIsOrderAsInvoice", Not UseAdvancedFeaturesOfSalesOrder);
	
	EconomicOperationsOfOrders = New Array();
	
	If SelectionData_.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or SelectionData_.BusinessOperation =
			Enums.BusinessTransactions.SaleToCustomerLocalAccounting 
		Or SelectionData_.BusinessOperation =
			Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or SelectionData_.BusinessOperation =
			Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		EconomicOperationsOfOrders.Add(
			Enums.BusinessTransactions.SaleToCustomer);
		
		EconomicOperationsOfOrders.Add(
			Enums.BusinessTransactions.ReturnOfGoodsFromCustomer);
		
		EconomicOperationsOfOrders.Add(
			Enums.BusinessTransactions.ReturnFromRetailCustomer);
		
		EconomicOperationsOfOrders.Add(
			Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
		
		EconomicOperationsOfOrders.Add(
			Enums.BusinessTransactions.GoodsShipmentToCustomer);

		EconomicOperationsOfOrders.Add(
			Enums.BusinessTransactions.OBEntryShippedGoods);
		
	ElsIf SelectionData_.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent  Then
		
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		EconomicOperationsOfOrders.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
		
	EndIf;
	
	Query.SetParameter("EconomicOperationsOfOrders", EconomicOperationsOfOrders);
	
	RegistrationOption = Undefined;
	FillParameters.Property("RegistrationOption", RegistrationOption);
	
	ArrayOfDesignOptions = New Array;
	If ValueIsFilled(RegistrationOption) Then
		ArrayOfDesignOptions.Add(RegistrationOption);
	Else
		ArrayOfDesignOptions.Add(Enums.SalesRegistrationOptions.CustomerInvoice);
		ArrayOfDesignOptions.Add(Enums.SalesRegistrationOptions.DeedOfTransfer);
	EndIf;
	
	Query.SetParameter("ArrayOfDesignOptions", ArrayOfDesignOptions);
	
	If TypeOf(SelectionData_) = Type("Structure") 
		And SelectionData_.Property("GoodsSales_") Then
		Query.SetParameter("GoodsSales_", SelectionData_.GoodsSales_);
	Else
		GoodsSales_ = New ValueTable;
		GoodsSales_.Columns.Add("SalesOrder", New TypeDescription("DocumentRef.SalesOrder"));
		GoodsSales_.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		GoodsSales_.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		GoodsSales_.Columns.Add("RowCode", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		GoodsSales_.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
		GoodsSales_.Columns.Add("AmountARAP", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		GoodsSales_.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		GoodsSales_.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		GoodsSales_.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		GoodsSales_.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
		GoodsSales_.Columns.Add("QuantityInOrder", TMCommonUse.DescriptionOfQuantitativeFieldType());
		GoodsSales_.Columns.Add("Price", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
		GoodsSales_.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("VATAmount", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("VATAmountCompl", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("VATAmountMan", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("AmountIncludingVAT", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("PercentRateOfManualDiscount", New TypeDescription("Number", New NumberQualifiers(5, 2)));
		GoodsSales_.Columns.Add("ManualDiscount", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("PercentRateOfAutomaticDiscountMarkup", New TypeDescription("Number", New NumberQualifiers(5, 2)));
		GoodsSales_.Columns.Add("DiscountMarkupAmount", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("AmountOfBonusPointsToDeduction", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("AmountOfBonusPointsToDeductionInCurrency", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("AmountOfEarnedBonusPointsInCurrency", TMCommonUse.MoneyFieldTypeDescription());
		GoodsSales_.Columns.Add("ProductsInSet", New TypeDescription("CatalogRef.Products"));
		GoodsSales_.Columns.Add("ItemVariantOfSet", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		GoodsSales_.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
		GoodsSales_.Columns.Add("ConnectionKey", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		
		Query.SetParameter("GoodsSales_", GoodsSales_);
	EndIf;
	
	Query.Text =
		"SELECT
		|	CAST(GoodsSales_.RowCode AS NUMBER(10, 0)) AS RowCode,
		|	GoodsSales_.SalesOrder AS SalesOrder,
		|	CAST(GoodsSales_.Products AS Catalog.Products) AS Products,
		|	CAST(GoodsSales_.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
		|	GoodsSales_.Count AS Count,
		|	CAST(GoodsSales_.Warehouse AS Catalog.Warehouses) AS Warehouse,
		|	GoodsSales_.LineNumber AS LineNumber,
		|	CAST(GoodsSales_.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
		|	GoodsSales_.Series AS Series,
		|	GoodsSales_.PriceKind AS PriceKind,
		|	GoodsSales_.Price AS Price,
		|	GoodsSales_.VATRate AS VATRate,
		|	GoodsSales_.Sum AS Sum,
		|	GoodsSales_.VATAmount AS VATAmount,
		|	GoodsSales_.VATAmountCompl AS VATAmountCompl,
		|	GoodsSales_.VATAmountMan AS VATAmountMan,
		|	GoodsSales_.AmountIncludingVAT AS AmountIncludingVAT,
		|	GoodsSales_.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|	GoodsSales_.ManualDiscount AS ManualDiscount,
		|	GoodsSales_.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
		|	GoodsSales_.DiscountMarkupAmount AS DiscountMarkupAmount,
		|	GoodsSales_.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
		|	GoodsSales_.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
		|	GoodsSales_.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
		|	GoodsSales_.ProductsInSet AS ProductsInSet,
		|	GoodsSales_.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsSales_.Department AS Department,
		|	GoodsSales_.ConnectionKey AS ConnectionKey
		|INTO TTSalesProducts
		|FROM
		|	&GoodsSales_ AS GoodsSales_
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	TTSalesProducts.RowCode AS RowCode,
		|	TTSalesProducts.SalesOrder AS SalesOrder,
		|	TTSalesProducts.Products AS Products,
		|	TTSalesProducts.Characteristic AS Characteristic,
		|	SUM(TTSalesProducts.Count) AS Count,
		|	TTSalesProducts.Series AS Series,
		|	TTSalesProducts.Package AS Package
		|INTO TTGoodsSalesByOrder
		|FROM
		|	TTSalesProducts AS TTSalesProducts
		|WHERE
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|			THEN TRUE
		|		ELSE
		|			TTSalesProducts.RowCode <> 0
		|	END
		|
		|GROUP BY
		|	TTSalesProducts.RowCode,
		|	TTSalesProducts.SalesOrder,
		|	TTSalesProducts.Products,
		|	TTSalesProducts.Characteristic,
		|	TTSalesProducts.Series,
		|	TTSalesProducts.Package
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	&Recorder AS SalesOrder,
		|	&ARAPObjectSettings AS ARAPObjectSettings,
		|	GoodsSales_.Products AS Products,
		|	GoodsSales_.Characteristic AS Characteristic,
		|	GoodsSales_.RowCode AS RowCode,
		|	GoodsSales_.Count AS Count,
		|	GoodsSales_.Sum AS AmountARAP,
		|	GoodsSales_.Warehouse AS Warehouse,
		|	GoodsSales_.LineNumber AS LineNumber,
		|	GoodsSales_.Package AS Package,
		|	GoodsSales_.Series AS Series,
		|	GoodsSales_.PriceKind AS PriceKind,
		|	GoodsSales_.Count AS QuantityInOrder,
		|	GoodsSales_.Price AS Price,
		|	GoodsSales_.VATRate AS VATRate,
		|	GoodsSales_.Sum AS Sum,
		|	GoodsSales_.VATAmount AS VATAmount,
		|	GoodsSales_.VATAmountCompl AS VATAmountCompl,
		|	GoodsSales_.VATAmountMan AS VATAmountMan,
		|	GoodsSales_.AmountIncludingVAT AS AmountIncludingVAT,
		|	GoodsSales_.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|	GoodsSales_.ManualDiscount AS ManualDiscount,
		|	GoodsSales_.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
		|	GoodsSales_.DiscountMarkupAmount AS DiscountMarkupAmount,
		|	GoodsSales_.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
		|	GoodsSales_.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
		|	GoodsSales_.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
		|	GoodsSales_.ProductsInSet AS ProductsInSet,
		|	GoodsSales_.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsSales_.Department AS Department,
		|	GoodsSales_.ConnectionKey AS ConnectionKey,
		|	CatalogOfProductItem.ItemsType AS ItemsType,
		|	CatalogOfProductItem.FEACNCode AS FEACNCode,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|		AND Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate AS WarehouseManagementIsUsedForShipment
		|INTO TTGoodsSaleWithoutOrder
		|FROM
		|	TTSalesProducts AS GoodsSales_
		|		LEFT JOIN Catalog.Products AS CatalogOfProductItem
		|		ON (CatalogOfProductItem.Ref = GoodsSales_.Products)
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON (Warehouses.Ref = GoodsSales_.Warehouse)
		|WHERE
		|	GoodsSales_.RowCode = 0
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	SalesOrder.Ref AS Ref,
		|	SalesOrder.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
		|INTO TTOrders
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	CASE
		|		WHEN &SelectByOrder_
		|			THEN SalesOrder.Ref IN (&AnArrayOfOrders)
		|		ELSE SalesOrder.Partner = &Partner
		|			AND SalesOrder.Counterparty = &Counterparty
		|			AND (SalesOrder.Contract = &Contract
		|				OR &ToUseTermsOfSales
		|					AND NOT SalesOrder.Terms.ContractsAreUsed)
		|			AND SalesOrder.Organization = &Organization
		|			AND SalesOrder.BusinessOperation IN (&EconomicOperationsOfOrders)
		|			AND (NOT &ToUseTermsOfSales
		|				OR SalesOrder.Terms = &Terms)
		|			AND SalesOrder.SalesOpportunity = &SalesOpportunity
		|			AND (SalesOrder.Currency = &ARAPCurrency
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|			AND CASE
		|				WHEN SalesOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|					THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|				ELSE
		|					SalesOrder.VATTaxation
		|			END = &VATTaxation
		|			AND SalesOrder.PriceIncludesVAT = &PriceIncludesVAT
		|			AND (SalesOrder.ToReturnReusablePackage = &ToReturnReusablePackage
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
		|			AND (SalesOrder.PackageDepositIsRequired = &PackageDepositIsRequired
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
		|			AND (NOT &UseLinesOfBusiness
		|				OR SalesOrder.LineOfBusiness = &LineOfBusiness)
		|		END
		|	AND SalesOrder.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN ShippingGoods.Ref.Patch
		|			THEN ShippingGoods.Ref.CorrectedDocument
		|		ELSE
		|			ShippingGoods.Ref
		|	END AS Ref,
		|	CASE
		|		WHEN ShippingGoods.SalesOrder REFS Document.SalesOrder
		|			THEN CAST(ShippingGoods.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
		|		WHEN ShippingGoods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|			THEN CAST(ShippingGoods.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
		|		ELSE
		|			FALSE
		|	END AS ThisIsOrderAsInvoice
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
		|WHERE
		|	CASE
		|		WHEN ShippingGoods.SalesOrder IN (
		|			                 VALUE(Document.SalesOrder.EmptyRef),
		|			                 VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
		|			                 VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
		|			                 UNDEFINED
		|			                 )
		|			THEN TRUE
		|		WHEN ShippingGoods.SalesOrder REFS Document.SalesOrder
		|			THEN CAST(ShippingGoods.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
		|		WHEN ShippingGoods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|			THEN CAST(ShippingGoods.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
		|		ELSE
		|			FALSE
		|	END
		|	AND CASE
		|		WHEN &SelectByOrder_
		|			THEN ShippingGoods.Ref IN (&AnArrayOfOrders)
		|		ELSE ShippingGoods.Ref.Partner = &Partner
		|			AND ShippingGoods.Ref.Counterparty = &Counterparty
		|			AND ShippingGoods.Ref.Contract = &Contract
		|			AND ShippingGoods.Ref.Organization = &Organization
		|			AND ShippingGoods.Ref.BusinessOperation IN (&EconomicOperationsOfOrders)
		|			AND (NOT &ToUseTermsOfSales
		|				OR ShippingGoods.Ref.Terms = &Terms)
		|			AND ShippingGoods.Ref.SalesOpportunity = &SalesOpportunity
		|			AND ShippingGoods.Ref.Currency = &ARAPCurrency
		|			AND CASE
		|				WHEN ShippingGoods.Ref.VATTaxation IN (
		|				                            VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|				                            VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|				                            )
		|					THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|				ELSE ShippingGoods.Ref.VATTaxation
		|			END = &VATTaxation
		|			AND &PriceIncludesVAT = TRUE
		|			AND (NOT &UseLinesOfBusiness
		|				OR ShippingGoods.Ref.LineOfBusiness = &LineOfBusiness)
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrder.Ref,
		|	SalesOrder.ThisIsOrderAsInvoice
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS SalesOrder
		|WHERE
		|	CASE
		|			WHEN &SelectByOrder_
		|				THEN SalesOrder.Ref IN (&AnArrayOfOrders)
		|			ELSE SalesOrder.Partner = &Partner
		|				AND SalesOrder.Counterparty = &Counterparty
		|				AND (SalesOrder.Contract = &Contract
		|					OR &ToUseTermsOfSales
		|						AND NOT SalesOrder.Terms.ContractsAreUsed)
		|				AND SalesOrder.Organization = &Organization
		|				AND SalesOrder.BusinessOperation IN (&EconomicOperationsOfOrders)
		|				AND (NOT &ToUseTermsOfSales
		|					OR SalesOrder.Terms = &Terms)
		|				AND SalesOrder.SalesOpportunity = &SalesOpportunity
		|				AND (SalesOrder.Currency = &ARAPCurrency
		|					OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|				AND CASE
		|					WHEN SalesOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|						THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|						ELSE SalesOrder.VATTaxation
		|				END = &VATTaxation
		|				AND SalesOrder.PriceIncludesVAT = &PriceIncludesVAT
		|				AND (SalesOrder.ToReturnReusablePackage = &ToReturnReusablePackage
		|					OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
		|				AND (SalesOrder.PackageDepositIsRequired = &PackageDepositIsRequired
		|					OR &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
		|				AND (NOT &UseLinesOfBusiness
		|					OR SalesOrder.LineOfBusiness = &LineOfBusiness)
		|		END
		|	AND SalesOrder.Posted
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	OBEntryGoods.Lot AS Ref,
		|	FALSE AS ThisIsOrderAsInvoice
		|FROM
		|	Document.OBEntryGoods AS OBEntryGoods
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON OBEntryGoods.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|WHERE
		|	CASE
		|		WHEN &SelectByOrder_
		|			THEN OBEntryGoods.Lot IN (&AnArrayOfOrders)
		|		ELSE OBEntryGoods.Partner = &Partner
		|			AND OBEntryGoods.Counterparty = &Counterparty
		|			AND OBEntryGoods.Contract = &Contract
		|			AND OBEntryGoods.Organization = &Organization
		|			AND OBEntryGoods.BusinessOperation IN (&EconomicOperationsOfOrders)
		|			AND OBEntryGoods.PriceIncludesVAT = &PriceIncludesVAT
		|			AND OBEntryGoods.Currency = &ARAPCurrency
		|			AND CASE
		|				WHEN OBEntryGoods.Lot.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|					THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|					ELSE OBEntryGoods.Lot.VATTaxation
		|			END = &VATTaxation
		|	END
		|	AND OBEntryGoods.Posted
		|	AND DocumentsRegistry.Ref IS NULL
		|
		|INDEX BY
		|	Ref
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 4
		|SELECT
		|	ShippingGoods.SalesOrder AS ReferenceOrder,
		|	ShippingGoods.Ref AS ShipmentOfItems
		|INTO TTOfShipmentOfItemsByOrder
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
		|WHERE
		|	ShippingGoods.Ref.ShipmentByOrders
		|	AND NOT ShippingGoods.SalesOrder IN(
		|				VALUE(Document.SalesOrder.EmptyRef),
		|				VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
		|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
		|				UNDEFINED
		|				)
		|	AND CASE
		|		WHEN ShippingGoods.SalesOrder REFS Document.SalesOrder
		|			THEN NOT CAST(ShippingGoods.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
		|		WHEN ShippingGoods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|			THEN NOT CAST(ShippingGoods.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
		|		ELSE
		|			TRUE
		|	END
		|	AND &SelectByOrder_
		|	AND ShippingGoods.Ref IN (&AnArrayOfOrders)
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 5
		|	SELECT
		|		OrdersIssuedTurnover.ReferenceOrder AS ReferenceOrder,
		|		OrdersIssuedTurnover.Products AS Products,
		|		OrdersIssuedTurnover.Characteristic AS Characteristic,
		|		OrdersIssuedTurnover.RowCode AS RowCode,
		|		OrdersIssuedTurnover.ShippedQuantityTurnover
		|			+ OrdersIssuedTurnover.RegisteredUpToPPPQuantityTurnover
		|			- OrdersIssuedTurnover.DeductedToPPPQuantityTurnover
		|			- OrdersIssuedTurnover.IssuedQuantityTurnover
		|			- OrdersIssuedTurnover.QuantityAccepted_Turnover AS ToRegister,
		|		OrdersIssuedTurnover.ShippedAmountTurnover
		|			+ OrdersIssuedTurnover.RegisteredUpToPPPAmountTurnover
		|			- OrdersIssuedTurnover.DebitedToPPPAmountTurnover
		|			- OrdersIssuedTurnover.IssuedAmountTurnover
		|			- OrdersIssuedTurnover.AcceptedAmountTurnover AS Sum,
		|		OrdersIssuedTurnover.IssuedInvoicesVATAmountLocalTurnover
		|			- OrdersIssuedTurnover.IssuedVATAmountLocalTurnover AS VATAmountCompl,
		|		OrdersIssuedTurnover.IssuedInvoicesVATAmountManTurnover
		|			- OrdersIssuedTurnover.IssuedVATAmountManTurnover AS VATAmountMan
		|	INTO TTOrdersIssuedShipmentsOnOrders
		|	FROM
		|		#ShipmentOrdersTurnoverExpanded1 AS OrdersIssuedTurnover
		|	WHERE
		|		&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|		AND (OrdersIssuedTurnover.ShippedQuantityTurnover
		|			+ OrdersIssuedTurnover.RegisteredUpToPPPQuantityTurnover
		|			- OrdersIssuedTurnover.DeductedToPPPQuantityTurnover
		|			- OrdersIssuedTurnover.IssuedQuantityTurnover
		|			- OrdersIssuedTurnover.QuantityAccepted_Turnover <> 0
		|			OR OrdersIssuedTurnover.ShippedAmountTurnover
		|				+ OrdersIssuedTurnover.RegisteredUpToPPPAmountTurnover
		|				- OrdersIssuedTurnover.DebitedToPPPAmountTurnover
		|				- OrdersIssuedTurnover.IssuedAmountTurnover
		|				- OrdersIssuedTurnover.AcceptedAmountTurnover <> 0
		|			OR OrdersIssuedTurnover.IssuedInvoicesVATAmountLocalTurnover
		|				- OrdersIssuedTurnover.IssuedVATAmountLocalTurnover <> 0
		|			OR OrdersIssuedTurnover.IssuedInvoicesVATAmountManTurnover
		|				- OrdersIssuedTurnover.IssuedVATAmountManTurnover <> 0)
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 6
		|SELECT
		|	OrdersTable.SalesOrder AS SalesOrder,
		|	OrdersTable.Products AS Products,
		|	OrdersTable.Characteristic AS Characteristic,
		|	OrdersTable.RowCode AS RowCode,
		|	OrdersTable.Warehouse AS Warehouse,
		|	CatalogOfProductItem.FEACNCode AS FEACNCode,
		|	SUM(OrdersTable.ToRegister) AS Count,
		|	SUM(OrdersTable.Sum) AS Sum,
		|	SUM(OrdersTable.VATAmountCompl) AS VATAmountCompl,
		|	SUM(OrdersTable.VATAmountMan) AS VATAmountMan
		|INTO TableBalance
		|FROM
		|	(SELECT
		|		OrdersForShipmentAndReturnTurnover.ReferenceOrder AS SalesOrder,
		|		OrdersForShipmentAndReturnTurnover.Products AS Products,
		|		OrdersForShipmentAndReturnTurnover.Characteristic AS Characteristic,
		|		OrdersForShipmentAndReturnTurnover.RowCode AS RowCode,
		|		MAX(OrdersForShipmentAndReturnTurnover.Warehouse) AS Warehouse,
		|		SUM(OrdersForShipmentAndReturnTurnover.QuantityToBeShipped
		|			- OrdersForShipmentAndReturnTurnover.ShippedQuantity) AS ToRegister,
		|		SUM(OrdersForShipmentAndReturnTurnover.AmountToBeShipped
		|			- OrdersForShipmentAndReturnTurnover.ShippedAmount) AS Sum,
		|		SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountLocal
		|			- OrdersForShipmentAndReturnTurnover.IssuedVATAmountLocal) AS VATAmountCompl,
		|		SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountMan
		|			- OrdersForShipmentAndReturnTurnover.IssuedVATAmountMan) AS VATAmountMan
		|	FROM
		|		(
		|			SELECT
		|				TableRevolutions.ReferenceOrder AS ReferenceOrder,
		|				TableRevolutions.Products AS Products,
		|				TableRevolutions.Characteristic AS Characteristic,
		|				TableRevolutions.RowCode AS RowCode,
		|				TableRevolutions.Warehouse AS Warehouse,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS QuantityToBeShipped,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS AmountToBeShipped,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
		|						THEN TableRevolutions.CountTurnover
		|					ELSE
		|						0
		|				END AS ShippedQuantity,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
		|						THEN TableRevolutions.SumTurnover
		|					ELSE
		|						0
		|				END AS ShippedAmount,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.VATAmountManTurnover
		|					ELSE
		|						0
		|				END AS IssuedVATAmountMan,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|						THEN TableRevolutions.VATAmountComplTurnover
		|					ELSE
		|						0
		|				END AS IssuedVATAmountLocal,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|						THEN TableRevolutions.VATAmountManTurnover
		|					ELSE
		|						0
		|				END AS IssuedInvoicesVATAmountMan,
		|				CASE
		|					WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered)
		|						THEN TableRevolutions.VATAmountComplTurnover
		|					ELSE
		|						0
		|				END AS IssuedInvoicesVATAmountLocal
		|			FROM
		|				AccumulationRegister.ShipmentAndReturnReferences.Turnovers(
		|					,
		|					,
		|					,
		|					(ReferenceOrder, &ThisIsOrderAsInvoice) IN
		|						(SELECT
		|							TTOrders.Ref,
		|							TTOrders.ThisIsOrderAsInvoice
		|						FROM
		|							TTOrders)
		|					AND CASE
		|						WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|							THEN Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|								OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|						ELSE
		|							Warehouse IN (
		|								VALUE(Catalog.Warehouses.EmptyRef),
		|								&ImplementationWarehouse)
		|						END
		|					AND Products.SaleRegistrationOption IN (&ArrayOfDesignOptions)
		|					AND Factor IN (
		|							VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
		|							VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped),
		|							VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1),
		|							VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.TaxInvoicesRegistered))
		|					) AS TableRevolutions
		|		) AS OrdersForShipmentAndReturnTurnover
		|	WHERE
		|		&BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|
		|	GROUP BY
		|		OrdersForShipmentAndReturnTurnover.ReferenceOrder,
		|		OrdersForShipmentAndReturnTurnover.Products,
		|		OrdersForShipmentAndReturnTurnover.Characteristic,
		|		OrdersForShipmentAndReturnTurnover.RowCode
		|	HAVING
		|		SUM(OrdersForShipmentAndReturnTurnover.QuantityToBeShipped
		|			- OrdersForShipmentAndReturnTurnover.ShippedQuantity) <> 0
		|		 OR SUM(OrdersForShipmentAndReturnTurnover.AmountToBeShipped
		|				- OrdersForShipmentAndReturnTurnover.ShippedAmount) <> 0
		|			OR SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountLocal
		|				- OrdersForShipmentAndReturnTurnover.IssuedVATAmountLocal) <> 0
		|			OR SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountMan
		|				- OrdersForShipmentAndReturnTurnover.IssuedVATAmountMan) <> 0
		|
		|	UNION ALL
		|
		|	SELECT
		|		OrdersForShipmentAndReturnTurnover.ReferenceOrder AS SalesOrder,
		|		OrdersForShipmentAndReturnTurnover.Products AS Products,
		|		OrdersForShipmentAndReturnTurnover.Characteristic AS Characteristic,
		|		OrdersForShipmentAndReturnTurnover.RowCode AS RowCode,
		|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|		SUM(OrdersForShipmentAndReturnTurnover.ShippedQuantity
		|			+ OrdersForShipmentAndReturnTurnover.RegisteredUpToPPPQuantity
		|			- OrdersForShipmentAndReturnTurnover.DeductedToPPPQuantity
		|			- OrdersForShipmentAndReturnTurnover.QuantityAccepted_
		|			- OrdersForShipmentAndReturnTurnover.IssuedQuantity) AS ToRegister,
		|		SUM(OrdersForShipmentAndReturnTurnover.ShippedAmount
		|			+ OrdersForShipmentAndReturnTurnover.RegisteredUpToPPPAmount
		|			- OrdersForShipmentAndReturnTurnover.DebitedToPPPAmount
		|			- OrdersForShipmentAndReturnTurnover.AcceptedAmount
		|			- OrdersForShipmentAndReturnTurnover.IssuedAmount) AS Sum,
		|		SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountLocal
		|			- OrdersForShipmentAndReturnTurnover.IssuedVATAmountLocal) AS VATAmountCompl,
		|		SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountMan
		|			- OrdersForShipmentAndReturnTurnover.IssuedVATAmountMan) AS VATAmountMan
		|	FROM
		|		#ShipmentOrdersTurnoverExpanded2 AS OrdersForShipmentAndReturnTurnover
		|	WHERE
		|		&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|	
		|	GROUP BY
		|		OrdersForShipmentAndReturnTurnover.ReferenceOrder,
		|		OrdersForShipmentAndReturnTurnover.Products,
		|		OrdersForShipmentAndReturnTurnover.Characteristic,
		|		OrdersForShipmentAndReturnTurnover.RowCode
		|
		|	HAVING
		|		SUM(OrdersForShipmentAndReturnTurnover.ShippedQuantity
		|			+ OrdersForShipmentAndReturnTurnover.RegisteredUpToPPPQuantity
		|			- OrdersForShipmentAndReturnTurnover.DeductedToPPPQuantity
		|			- OrdersForShipmentAndReturnTurnover.QuantityAccepted_
		|			- OrdersForShipmentAndReturnTurnover.IssuedQuantity) <> 0
		|		OR SUM(OrdersForShipmentAndReturnTurnover.ShippedAmount
		|			+ OrdersForShipmentAndReturnTurnover.RegisteredUpToPPPAmount
		|			- OrdersForShipmentAndReturnTurnover.DebitedToPPPAmount
		|			- OrdersForShipmentAndReturnTurnover.AcceptedAmount
		|			- OrdersForShipmentAndReturnTurnover.IssuedAmount) <> 0
		|		OR SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountLocal
		|			- OrdersForShipmentAndReturnTurnover.IssuedVATAmountLocal) <> 0
		|		OR SUM(OrdersForShipmentAndReturnTurnover.IssuedInvoicesVATAmountMan
		|			- OrdersForShipmentAndReturnTurnover.IssuedVATAmountMan) <> 0
		|
		|	UNION ALL
		|	
		|	SELECT
		|		OrdersShipped.ReferenceOrder AS SalesOrder,
		|		OrdersShipped.Products AS Products,
		|		OrdersShipped.Characteristic AS Characteristic,
		|		OrdersShipped.RowCode AS RowCode,
		|		VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|		CASE
		|			WHEN OrdersShipped.ShippedQuantity < ISNULL(OrdersIssuedTurnover.ToRegister, 0)
		|				THEN OrdersShipped.ShippedQuantity
		|			ELSE
		|				ISNULL(OrdersIssuedTurnover.ToRegister, 0)
		|		END AS ToRegister,
		|		CASE
		|			WHEN OrdersShipped.ShippedAmount < ISNULL(OrdersIssuedTurnover.Sum, 0)
		|				THEN OrdersShipped.ShippedAmount
		|			ELSE
		|				ISNULL(OrdersIssuedTurnover.Sum, 0)
		|		END AS Sum,
		|		ISNULL(OrdersIssuedTurnover.VATAmountCompl, 0) AS VATAmountCompl,
		|		ISNULL(OrdersIssuedTurnover.VATAmountMan, 0) AS VATAmountMan
		|	FROM
		|		#OrdersForShipmentRegisteredRecordsExpanded3 AS OrdersShipped
		|			LEFT JOIN TTOrdersIssuedShipmentsOnOrders AS OrdersIssuedTurnover
		|				ON OrdersShipped.ReferenceOrder = OrdersIssuedTurnover.ReferenceOrder
		|					AND OrdersShipped.Products = OrdersIssuedTurnover.Products
		|					AND OrdersShipped.Characteristic = OrdersIssuedTurnover.Characteristic
		|					AND OrdersShipped.RowCode = OrdersIssuedTurnover.RowCode
		|	WHERE
		|		&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|		AND (CASE
		|			WHEN OrdersShipped.ShippedQuantity < ISNULL(OrdersIssuedTurnover.ToRegister, 0)
		|				THEN OrdersShipped.ShippedQuantity
		|			ELSE
		|				ISNULL(OrdersIssuedTurnover.ToRegister, 0)
		|		END <> 0
		|			OR CASE
		|				WHEN OrdersShipped.ShippedAmount < ISNULL(OrdersIssuedTurnover.Sum, 0)
		|					THEN OrdersShipped.ShippedAmount
		|				ELSE
		|					ISNULL(OrdersIssuedTurnover.Sum, 0)
		|			END <> 0
		|			OR ISNULL(OrdersIssuedTurnover.VATAmountCompl, 0) <> 0
		|			OR ISNULL(OrdersIssuedTurnover.VATAmountMan, 0) <> 0)
		|		
		|	UNION ALL
		|	
		|	SELECT
		|		OrdersRegisterRecords.ReferenceOrder AS SalesOrder,
		|		OrdersRegisterRecords.Products AS Products,
		|		OrdersRegisterRecords.Characteristic AS Characteristic,
		|		OrdersRegisterRecords.RowCode AS RowCode,
		|		OrdersRegisterRecords.Warehouse AS Warehouse,
		|		OrdersRegisterRecords.Count AS ToRegister,
		|		OrdersRegisterRecords.Sum AS Sum,
		|		OrdersRegisterRecords.VATAmountCompl AS VATAmountCompl,
		|		OrdersRegisterRecords.VATAmountMan AS VATAmountMan
		|	FROM
		|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
		|	WHERE
		|		OrdersRegisterRecords.Recorder = &Recorder
		|		AND CASE
		|			WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|				THEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
		|			ELSE
		|				OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
		|		END
		|		AND (OrdersRegisterRecords.ReferenceOrder, &ThisIsOrderAsInvoice) IN
		|				(SELECT
		|					TTOrders.Ref,
		|					TTOrders.ThisIsOrderAsInvoice
		|				FROM
		|					TTOrders)
		|		AND OrdersRegisterRecords.Active
		|		AND CASE
		|				WHEN &ImplementationWarehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|					THEN TRUE
		|				WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|					THEN OrdersRegisterRecords.Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|							OR OrdersRegisterRecords.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				ELSE OrdersRegisterRecords.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|			END
		|		AND OrdersRegisterRecords.Products.SaleRegistrationOption IN(&ArrayOfDesignOptions)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomerOrderGoods.Ref,
		|		CustomerOrderGoods.Products,
		|		CustomerOrderGoods.Characteristic,
		|		CustomerOrderGoods.RowCode,
		|		CustomerOrderGoods.Warehouse,
		|		CustomerOrderGoods.Count,
		|		CustomerOrderGoods.AmountIncludingVAT,
		|		0,
		|		0
		|	FROM
		|		Document.SalesOrder.Goods AS CustomerOrderGoods
		|	WHERE
		|		(CustomerOrderGoods.Ref, &ThisIsOrderAsInvoice, TRUE) IN
		|				(SELECT
		|					TTOrders.Ref,
		|					TTOrders.ThisIsOrderAsInvoice,
		|					TTOrders.ThisIsOrderAsInvoice
		|				FROM
		|					TTOrders)
		|		AND CustomerOrderGoods.Products.SaleRegistrationOption IN(&ArrayOfDesignOptions)
		|		AND NOT CustomerOrderGoods.Canceled
		|		AND NOT CustomerOrderGoods.Ref.DeletionMark
		|		AND CASE
		|				WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|					THEN CustomerOrderGoods.Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|							OR CustomerOrderGoods.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				ELSE CustomerOrderGoods.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|			END
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomerOrderGoods.Ref,
		|		CustomerOrderGoods.Products,
		|		CustomerOrderGoods.Characteristic,
		|		CustomerOrderGoods.RowCode,
		|		CustomerOrderGoods.Warehouse,
		|		CustomerOrderGoods.Count,
		|		CustomerOrderGoods.AmountIncludingVAT,
		|		0,
		|		0
		|	FROM
		|		Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS CustomerOrderGoods
		|	WHERE
		|		(CustomerOrderGoods.Ref, &ThisIsOrderAsInvoice, TRUE) IN
		|				(SELECT
		|					TTOrders.Ref,
		|					TTOrders.ThisIsOrderAsInvoice,
		|					TTOrders.ThisIsOrderAsInvoice
		|				FROM
		|					TTOrders)
		|		AND CustomerOrderGoods.Products.SaleRegistrationOption IN(&ArrayOfDesignOptions)
		|		AND NOT CustomerOrderGoods.Canceled
		|		AND NOT CustomerOrderGoods.Ref.DeletionMark
		|	
		|	) AS OrdersTable
		|		LEFT JOIN Catalog.Products AS CatalogOfProductItem
		|		ON (CatalogOfProductItem.Ref = OrdersTable.Products)
		|
		|GROUP BY
		|	OrdersTable.SalesOrder,
		|	OrdersTable.Products,
		|	OrdersTable.Characteristic,
		|	OrdersTable.RowCode,
		|	OrdersTable.Warehouse,
		|	CatalogOfProductItem.FEACNCode
		|
		|HAVING
		|	SUM(OrdersTable.ToRegister) > 0
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	RowCode,
		|	SalesOrder
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 7
		|SELECT
		|	ReferenceOrder AS Ref,
		|	MAX(Recorder) AS CorrectionLink
		|INTO TableOfCorrections
		|FROM
		|	AccumulationRegister.ShipmentAndReturnReferences
		|WHERE
		|	ReferenceOrder IN
		|		(SELECT
		|			Ref
		|		FROM
		|			TTOrders)
		|	AND VALUETYPE(Recorder) = TYPE(Document.GoodsShipmentToCustomer)
		|	AND VALUETYPE(ReferenceOrder) = TYPE(Document.GoodsShipmentToCustomer)
		|GROUP BY
		|	ReferenceOrder
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 8
		|SELECT
		|	ProductsVATRates.Products,
		|	ProductsVATRates.VATRate AS VATRate
		|INTO ProductsVATRates
		|FROM
		|	InformationRegister.ProductsVATRates.SliceLast(
		|		&Date,
		|		(Country = &RegistrationCountry
		|			OR Country = VALUE(Catalog.WorldCountries.EmptyRef))
		|		AND Products IN (SELECT 
		|								Products 
		|							FROM 
		|								TableBalance)
		|	) AS ProductsVATRates
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 9
		|SELECT
		|	BasicVATRates.VATRate AS VATRate
		|INTO BasicVATRates
		|FROM
		|	InformationRegister.BasicVATRates.SliceLast(
		|		&Date,
		|		Country = &RegistrationCountry
		|	) AS BasicVATRates
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 10
		|SELECT
		|	TableBalance.SalesOrder AS SalesOrder,
		|	OrderingProducts.Ref.ARAPObjectSettings AS ARAPObjectSettings,
		|	TableBalance.Products AS Products,
		|	OrderingProducts.PartnerProducts AS PartnerProducts,
		|	TableBalance.Characteristic AS Characteristic,
		|	TableBalance.RowCode AS RowCode,
		|	TableBalance.Count AS Count,
		|	TableBalance.Sum AS AmountARAP,
		|	TableBalance.Warehouse AS Warehouse,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|			THEN TableBalance.Count
		|		ELSE 0
		|	END AS QuantityInTransit,
		|	ISNULL(WaybillGoods.Count, 0) AS QuantityInInvoice,
		|	OrderingProducts.LineNumber AS LineNumber,
		|	OrderingProducts.Ref.SalesOpportunity AS SalesOpportunity,
		|	OrderingProducts.DateOfShipment AS DateOfShipment,
		|	ISNULL(WaybillGoods.Package, OrderingProducts.Package) AS Package,
		|	OrderingProducts.Series AS Series,
		|	OrderingProducts.PriceKind AS PriceKind,
		|	OrderingProducts.Count AS QuantityInOrder,
		|	OrderingProducts.Price AS Price,
		|	OrderingProducts.VATRate AS VATRate,
		|	CASE
		|		WHEN &TaxationOfVATExports
		|			THEN TableBalance.FEACNCode
		|		ELSE VALUE(Catalog.FEACN.EmptyRef)
		|	END AS FEACNCode,
		|	OrderingProducts.Sum AS Sum,
		|	OrderingProducts.VATAmount AS VATAmount,
		|	TableBalance.VATAmountCompl AS VATAmountCompl,
		|	TableBalance.VATAmountMan AS VATAmountMan,
		|	OrderingProducts.AmountIncludingVAT AS AmountIncludingVAT,
		|	OrderingProducts.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|	OrderingProducts.ManualDiscount AS ManualDiscount,
		|	OrderingProducts.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
		|	OrderingProducts.DiscountMarkupAmount AS DiscountMarkupAmount,
		|	OrderingProducts.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
		|	OrderingProducts.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
		|	OrderingProducts.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
		|	OrderingProducts.Products.ItemsType AS ItemsType,
		|	OrderingProducts.ProductsInSet AS ProductsInSet,
		|	OrderingProducts.ItemVariantOfSet AS ItemVariantOfSet,
		|	OrderingProducts.Department AS Department,
		|	OrderingProducts.ConnectionKey AS ConnectionKey,
		|	CASE
		|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1)
		|	END AS ZoomRatio,
		|	TableBalance.Count /
		|		ISNULL(
		|			ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2),
		|			1) AS NumberOfPackages,
		|	OrderingProducts.DeliveryPeriodDays AS DeliveryPeriodDays,
		|	OrderingProducts.SupplyOption AS SupplyOption,
		|	CASE
		|		WHEN OrderingProducts.WithAssignment
		|			THEN TableBalance.SalesOrder.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	OrderGoodsWarehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|		AND OrderGoodsWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <=
		|			&CurrentDate AS AdvancedWarehousingOnShipment,
		|	CASE
		|		WHEN OrderingProducts.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
		|			THEN FALSE
		|		ELSE OrderGoodsWarehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|				AND OrderGoodsWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|	END AS CheckShipment
		|FROM
		|	TableBalance AS TableBalance
		|		INNER JOIN Document.SalesOrder.Goods AS OrderingProducts
		|		ON TableBalance.Products = OrderingProducts.Products
		|			AND TableBalance.Characteristic = OrderingProducts.Characteristic
		|			AND TableBalance.RowCode = OrderingProducts.RowCode
		|			AND TableBalance.SalesOrder = OrderingProducts.Ref
		|		LEFT JOIN Catalog.Warehouses AS OrderGoodsWarehouse
		|		ON (OrderGoodsWarehouse.Ref = OrderingProducts.Warehouse)
		|		LEFT JOIN TTGoodsSalesByOrder AS WaybillGoods
		|		ON TableBalance.Products = WaybillGoods.Products
		|			AND TableBalance.Characteristic = WaybillGoods.Characteristic
		|			AND TableBalance.RowCode = WaybillGoods.RowCode
		|			AND TableBalance.SalesOrder = WaybillGoods.SalesOrder
		|
		|UNION ALL
		|
		|SELECT
		|	TableBalance.SalesOrder AS SalesOrder,
		|	VALUE(Enum.ARAPObjectSettings.EmptyRef) AS ARAPObjectSettings,
		|	TableBalance.Products AS Products,
		|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
		|	TableBalance.Characteristic AS Characteristic,
		|	TableBalance.RowCode AS RowCode,
		|	TableBalance.Count AS Count,
		|	TableBalance.Sum AS AmountARAP,
		|	TableBalance.Warehouse AS Warehouse,
		|	TableBalance.Count AS QuantityInTransit,
		|	ISNULL(WaybillGoods.Count, 0) AS QuantityInInvoice,
		|	ShippingGoods.LineNumber AS LineNumber,
		|	ShippingGoods.Ref.SalesOpportunity AS SalesOpportunity,
		|	ShippingGoods.Ref.Date AS DateOfShipment,
		|	ISNULL(WaybillGoods.Package, ShippingGoods.Package) AS Package,
		|	ShippingGoods.Series AS Series,
		|	ShippingGoods.PriceKind AS PriceKind,
		|	ShippingGoods.Count AS QuantityInOrder,
		|	CASE
		|		WHEN ShippingGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN TableBalance.Sum / TableBalance.Count
		|		ELSE
		|			TableBalance.Sum / TableBalance.Count
		|				* &QueryTextPackagingFactor4
		|	END AS Price,
		|	&VATRateShipmentOfGoodsWithoutOrder AS VATRate,
		|	CASE
		|		WHEN &TaxationOfVATExports
		|			THEN TableBalance.FEACNCode
		|		ELSE VALUE(Catalog.FEACN.EmptyRef)
		|	END AS FEACNCode,
		|	TableBalance.Sum AS Sum,
		|	0 AS VATAmount,
		|	TableBalance.VATAmountCompl AS VATAmountCompl,
		|	TableBalance.VATAmountMan AS VATAmountMan,
		|	TableBalance.Sum AS AmountIncludingVAT,
		|	0 AS PercentRateOfManualDiscount,
		|	0 AS ManualDiscount,
		|	0 AS PercentRateOfAutomaticDiscountMarkup,
		|	0 AS DiscountMarkupAmount,
		|	0 AS AmountOfBonusPointsToDeduction,
		|	0 AS AmountOfBonusPointsToDeductionInCurrency,
		|	0 AS AmountOfEarnedBonusPointsInCurrency,
		|	TableBalance.Products.ItemsType AS ItemsType,
		|	ShippingGoods.ProductsInSet AS ProductsInSet,
		|	ShippingGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	ShippingGoods.Ref.Department AS Department,
		|	0 AS ConnectionKey,
		|	CASE
		|		WHEN ISNULL(WaybillGoods.Package, ShippingGoods.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor4), 1)
		|	END AS ZoomRatio,
		|	TableBalance.Count /
		|		ISNULL(
		|			ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor4),
		|			1) AS NumberOfPackages,
		|	ShippingGoods.DeliveryPeriodDays AS DeliveryPeriodDays,
		|	VALUE(Enum.SupplyOptions.EmptyRef) AS SupplyOption,
		|	CASE
		|		WHEN ShippingGoods.WithAssignment
		|			THEN ShippingGoods.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	ShippingGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|		AND ShippingGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <=
		|			&CurrentDate AS AdvancedWarehousingOnShipment,
		|	ShippingGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|		AND ShippingGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <=
		|			&CurrentDate AS CheckShipment
		|FROM
		|	TableBalance AS TableBalance
		|	INNER JOIN TableOfCorrections AS TableOfCorrections
		|		ON TableBalance.SalesOrder = TableOfCorrections.Ref
		|	INNER JOIN Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
		|		ON TableBalance.Products = ShippingGoods.Products
		|			AND TableBalance.Characteristic = ShippingGoods.Characteristic
		|			AND TableBalance.RowCode = ShippingGoods.RowCode
		|			AND TableOfCorrections.CorrectionLink = ShippingGoods.Ref
		|	LEFT JOIN TTGoodsSalesByOrder AS WaybillGoods
		|		ON TableBalance.Products = WaybillGoods.Products
		|			AND TableBalance.Characteristic = WaybillGoods.Characteristic
		|			AND TableBalance.RowCode = WaybillGoods.RowCode
		|			AND TableBalance.SalesOrder = WaybillGoods.SalesOrder
		|	LEFT JOIN ProductsVATRates AS ProductsVATRates
		|		ON ProductsVATRates.Products = ShippingGoods.Products
		|	LEFT JOIN BasicVATRates AS BasicVATRates
		|		ON TRUE
		|
		|UNION ALL
		|
		|SELECT
		|	TableBalance.SalesOrder AS SalesOrder,
		|	OrderDocument.ARAPObjectSettings AS ARAPObjectSettings,
		|	TableBalance.Products AS Products,
		|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
		|	TableBalance.Characteristic AS Characteristic,
		|	TableBalance.RowCode AS RowCode,
		|	TableBalance.Count AS Count,
		|	TableBalance.Sum AS AmountARAP,
		|	TableBalance.Warehouse AS Warehouse,
		|	0 AS QuantityInTransit,
		|	ISNULL(WaybillGoods.Count, 0) AS QuantityInInvoice,
		|	OrderingProducts.LineNumber AS LineNumber,
		|	OrderDocument.SalesOpportunity AS SalesOpportunity,
		|	OrderingProducts.DateOfShipment AS DateOfShipment,
		|	ISNULL(WaybillGoods.Package, OrderingProducts.Package) AS Package,
		|	OrderingProducts.Series AS Series,
		|	OrderingProducts.PriceKind AS PriceKind,
		|	OrderingProducts.Count AS QuantityInOrder,
		|	OrderingProducts.Price AS Price,
		|	OrderingProducts.VATRate AS VATRate,
		|	CASE
		|		WHEN &TaxationOfVATExports
		|			THEN TableBalance.FEACNCode
		|		ELSE VALUE(Catalog.FEACN.EmptyRef)
		|	END AS FEACNCode,
		|	OrderingProducts.Sum AS Sum,
		|	OrderingProducts.VATAmount AS VATAmount,
		|	TableBalance.VATAmountCompl AS VATAmountCompl,
		|	TableBalance.VATAmountMan AS VATAmountMan,
		|	OrderingProducts.AmountIncludingVAT AS AmountIncludingVAT,
		|	OrderingProducts.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|	OrderingProducts.ManualDiscount AS ManualDiscount,
		|	OrderingProducts.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
		|	OrderingProducts.DiscountMarkupAmount AS DiscountMarkupAmount,
		|	OrderingProducts.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
		|	OrderingProducts.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
		|	OrderingProducts.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
		|	OrderingProducts.Products.ItemsType AS ItemsType,
		|	OrderingProducts.ProductsInSet AS ProductsInSet,
		|	OrderingProducts.ItemVariantOfSet AS ItemVariantOfSet,
		|	OrderingProducts.Department AS Department,
		|	OrderingProducts.ConnectionKey AS ConnectionKey,
		|	CASE
		|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1)
		|	END AS ZoomRatio,
		|	TableBalance.Count /
		|		ISNULL(
		|			ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2),
		|			1) AS NumberOfPackages,
		|	OrderingProducts.DeliveryPeriodDays AS DeliveryPeriodDays,
		|	OrderingProducts.SupplyOption AS SupplyOption,
		|	CASE
		|		WHEN OrderingProducts.WithAssignment
		|			THEN TableBalance.SalesOrder.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	OrderDocument.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|		AND OrderDocument.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <=
		|			&CurrentDate AS AdvancedWarehousingOnShipment,
		|	CASE
		|		WHEN OrderingProducts.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
		|			THEN FALSE
		|		ELSE OrderingProducts.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|				AND OrderingProducts.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|	END AS CheckShipment
		|FROM
		|	TableBalance AS TableBalance
		|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS OrderingProducts
		|		ON TableBalance.Products = OrderingProducts.Products
		|			AND TableBalance.Characteristic = OrderingProducts.Characteristic
		|			AND TableBalance.RowCode = OrderingProducts.RowCode
		|			AND TableBalance.SalesOrder = OrderingProducts.Ref
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS OrderDocument
		|		ON (OrderDocument.Ref = OrderingProducts.Ref)
		|		LEFT JOIN TTGoodsSalesByOrder AS WaybillGoods
		|		ON TableBalance.Products = WaybillGoods.Products
		|			AND TableBalance.Characteristic = WaybillGoods.Characteristic
		|			AND TableBalance.RowCode = WaybillGoods.RowCode
		|			AND TableBalance.SalesOrder = WaybillGoods.SalesOrder
		|
		|UNION ALL
		|
		|SELECT
		|	TableBalance.SalesOrder AS SalesOrder,
		|	VALUE(Enum.ARAPObjectSettings.EmptyRef) AS ARAPObjectSettings,
		|	TableBalance.Products AS Products,
		|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
		|	TableBalance.Characteristic AS Characteristic,
		|	TableBalance.RowCode AS RowCode,
		|	MAX(TableBalance.Count) AS Count,
		|	MAX(TableBalance.Sum) AS AmountARAP,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	MAX(TableBalance.Count) AS QuantityInTransit,
		|	SUM(ISNULL(WaybillGoods.Count, 0)) AS QuantityInInvoice,
		|	MAX(ISNULL(ShippingGoods.LineNumber, 0)) AS LineNumber,
		|	MAX(ISNULL(ShippingGoods.Ref.SalesOpportunity, VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef))) AS SalesOpportunity,
		|	MAX(ISNULL(ShippingGoods.Ref.Date, DATETIME(1, 1, 1))) AS DateOfShipment,
		|	TableBalance.Products.UnitOfMeasure AS Package,
		|	MAX(CASE
		|		WHEN ShippingGoods.Series IS NOT NULL AND ShippingGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|			THEN ShippingGoods.Series
		|		WHEN RegistrationOfItems.Series IS NOT NULL AND RegistrationOfItems.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|			THEN RegistrationOfItems.Series
		|		ELSE
		|			VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END) AS Series,
		|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
		|	0 AS QuantityInOrder,
		|	MAX(CASE
		|		WHEN TableBalance.Count = 0
		|			THEN 0
		|		ELSE
		|			TableBalance.Sum / TableBalance.Count
		|	END) AS Price,
		|	MAX(CASE
		|		WHEN ShippingGoods.Ref IS NULL
		|			THEN VALUE(Catalog.VATRates.EmptyRef)
		|		ELSE
		|			&VATRateShipmentOfGoodsWithoutOrder
		|	END) AS VATRate,
		|	CASE
		|		WHEN &TaxationOfVATExports
		|			THEN TableBalance.FEACNCode
		|		ELSE VALUE(Catalog.FEACN.EmptyRef)
		|	END AS FEACNCode,
		|	MAX(TableBalance.Sum) AS Sum,
		|	0 AS VATAmount,
		|	MAX(TableBalance.VATAmountCompl) AS VATAmountCompl,
		|	MAX(TableBalance.VATAmountMan) AS VATAmountMan,
		|	MAX(TableBalance.Sum) AS AmountIncludingVAT,
		|	0 AS PercentRateOfManualDiscount,
		|	0 AS ManualDiscount,
		|	0 AS PercentRateOfAutomaticDiscountMarkup,
		|	0 AS DiscountMarkupAmount,
		|	0 AS AmountOfBonusPointsToDeduction,
		|	0 AS AmountOfBonusPointsToDeductionInCurrency,
		|	0 AS AmountOfEarnedBonusPointsInCurrency,
		|	TableBalance.Products.ItemsType AS ItemsType,
		|	MAX(ISNULL(ShippingGoods.ProductsInSet, VALUE(Catalog.Products.EmptyRef))) AS ProductsInSet,
		|	MAX(ISNULL(ShippingGoods.ItemVariantOfSet, VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS ItemVariantOfSet,
		|	MAX(ISNULL(ShippingGoods.Ref.Department, VALUE(Catalog.BusinessStructure.EmptyRef))) AS Department,
		|	0 AS ConnectionKey,
		|	1 AS ZoomRatio,
		|	MAX(TableBalance.Count) AS NumberOfPackages,
		|	MAX(ISNULL(ShippingGoods.DeliveryPeriodDays, 0)) AS DeliveryPeriodDays,
		|	VALUE(Enum.SupplyOptions.EmptyRef) AS SupplyOption,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	MAX(CASE
		|		WHEN ShippingGoods.Warehouse IS NULL
		|			THEN FALSE
		|		ELSE
		|			ShippingGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|				AND ShippingGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|	END) AS AdvancedWarehousingOnShipment,
		|	MAX(CASE
		|		WHEN ShippingGoods.Warehouse IS NULL
		|			THEN FALSE
		|		ELSE
		|			ShippingGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|				AND ShippingGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|	END) AS CheckShipment
		|FROM
		|	TableBalance AS TableBalance
		|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
		|		ON TableBalance.Products = ShippingGoods.Products
		|			AND TableBalance.Characteristic = ShippingGoods.Characteristic
		|			AND TableBalance.RowCode = ShippingGoods.RowCode
		|			AND ShippingGoods.RowCode = 0
		|			AND TableBalance.SalesOrder = ShippingGoods.SalesOrder
		|			AND ShippingGoods.Ref.Posted
		|	LEFT JOIN Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS RegistrationOfItems
		|		ON TableBalance.Products = RegistrationOfItems.Products
		|			AND TableBalance.Characteristic = RegistrationOfItems.Characteristic
		|			AND TableBalance.SalesOrder = RegistrationOfItems.ReferenceOrder
		|			AND RegistrationOfItems.Ref.Posted
		|	LEFT JOIN TTGoodsSalesByOrder AS WaybillGoods
		|		ON TableBalance.Products = WaybillGoods.Products
		|			AND TableBalance.Characteristic = WaybillGoods.Characteristic
		|			AND TableBalance.RowCode = WaybillGoods.RowCode
		|			AND TableBalance.SalesOrder = WaybillGoods.SalesOrder
		|	LEFT JOIN ProductsVATRates AS ProductsVATRates
		|		ON ProductsVATRates.Products = TableBalance.Products
		|	LEFT JOIN BasicVATRates AS BasicVATRates
		|		ON TRUE
		|WHERE
		|	TableBalance.RowCode = 0
		|	AND ISNULL(ShippingGoods.Ref, RegistrationOfItems.Ref) IS NOT NULL
		|
		|GROUP BY
		|	TableBalance.SalesOrder,
		|	TableBalance.Products,
		|	TableBalance.Characteristic,
		|	TableBalance.RowCode,
		|	CASE
		|		WHEN &TaxationOfVATExports
		|			THEN TableBalance.FEACNCode
		|		ELSE VALUE(Catalog.FEACN.EmptyRef)
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	TableBalance.SalesOrder AS SalesOrder,
		|	VALUE(Enum.ARAPObjectSettings.EmptyRef) AS ARAPObjectSettings,
		|	TableBalance.Products AS Products,
		|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
		|	TableBalance.Characteristic AS Characteristic,
		|	TableBalance.RowCode AS RowCode,
		|	TableBalance.Count AS Count,
		|	TableBalance.Sum AS AmountARAP,
		|	TableBalance.Warehouse AS Warehouse,
		|	TableBalance.Count AS QuantityInTransit,
		|	ISNULL(WaybillGoods.Count, 0) AS QuantityInInvoice,
		|	EnteringProductBalances.LineNumber AS LineNumber,
		|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
		|	EnteringProductBalances.Ref.Date AS DateOfShipment,
		|	ISNULL(WaybillGoods.Package, EnteringProductBalances.Package) AS Package,
		|	EnteringProductBalances.Series AS Series,
		|	VALUE(Catalog.TypesOfPrices.EmptyRef) AS PriceKind,
		|	EnteringProductBalances.Count AS QuantityInOrder,
		|	CASE
		|		WHEN EnteringProductBalances.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN TableBalance.Sum / TableBalance.Count
		|		ELSE
		|			TableBalance.Sum / TableBalance.Count
		|				* &QueryTextPackagingFactor5
		|	END AS Price,
		|	&VATRateForEnteringGoodsBalances AS VATRate,
		|	CASE
		|		WHEN &TaxationOfVATExports
		|			THEN TableBalance.FEACNCode
		|		ELSE VALUE(Catalog.FEACN.EmptyRef)
		|	END AS FEACNCode,
		|	TableBalance.Sum AS Sum,
		|	0 AS VATAmount,
		|	TableBalance.VATAmountCompl AS VATAmountCompl,
		|	TableBalance.VATAmountMan AS VATAmountMan,
		|	TableBalance.Sum AS AmountIncludingVAT,
		|	0 AS PercentRateOfManualDiscount,
		|	0 AS ManualDiscount,
		|	0 AS PercentRateOfAutomaticDiscountMarkup,
		|	0 AS DiscountMarkupAmount,
		|	0 AS AmountOfBonusPointsToDeduction,
		|	0 AS AmountOfBonusPointsToDeductionInCurrency,
		|	0 AS AmountOfEarnedBonusPointsInCurrency,
		|	TableBalance.Products.ItemsType AS ItemsType,
		|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
		|	EnteringProductBalances.Ref.Department AS Department,
		|	0 AS ConnectionKey,
		|	CASE
		|		WHEN ISNULL(WaybillGoods.Package, EnteringProductBalances.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor5), 1)
		|	END AS ZoomRatio,
		|	TableBalance.Count /
		|		ISNULL(
		|			ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor5),
		|			1) AS NumberOfPackages,
		|	DATETIME(1, 1, 1) AS DeliveryPeriodDays,
		|	VALUE(Enum.SupplyOptions.EmptyRef) AS SupplyOption,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	FALSE AS AdvancedWarehousingOnShipment,
		|	FALSE AS CheckShipment
		|FROM
		|	TableBalance AS TableBalance
		|	INNER JOIN Document.OBEntryGoods.Goods AS EnteringProductBalances
		|		ON TableBalance.Products = EnteringProductBalances.Products
		|			AND TableBalance.Characteristic = EnteringProductBalances.Characteristic
		|			AND TableBalance.RowCode = EnteringProductBalances.RowCode
		|			AND TableBalance.SalesOrder = EnteringProductBalances.Ref.Lot
		|			AND EnteringProductBalances.Ref.Posted
		|	LEFT JOIN TTGoodsSalesByOrder AS WaybillGoods
		|		ON TableBalance.Products = WaybillGoods.Products
		|			AND TableBalance.Characteristic = WaybillGoods.Characteristic
		|			AND TableBalance.RowCode = WaybillGoods.RowCode
		|			AND TableBalance.SalesOrder = WaybillGoods.SalesOrder
		|	LEFT JOIN ProductsVATRates AS ProductsVATRates
		|		ON ProductsVATRates.Products = EnteringProductBalances.Products
		|	LEFT JOIN BasicVATRates AS BasicVATRates
		|		ON TRUE
		// If there is a fix for the EIT, then it works with the latest fix
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON EnteringProductBalances.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|WHERE
		|	DocumentsRegistry.Ref IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsSales_.SalesOrder,
		|	GoodsSales_.ARAPObjectSettings,
		|	GoodsSales_.Products,
		|	VALUE(Catalog.ProductCrossReferences.EmptyRef),
		|	GoodsSales_.Characteristic,
		|	GoodsSales_.RowCode,
		|	GoodsSales_.Count,
		|	GoodsSales_.Sum,
		|	GoodsSales_.Warehouse,
		|	0,
		|	GoodsSales_.Count,
		|	GoodsSales_.LineNumber,
		|	UNDEFINED,
		|	UNDEFINED,
		|	GoodsSales_.Package,
		|	GoodsSales_.Series,
		|	GoodsSales_.PriceKind,
		|	0,
		|	GoodsSales_.Price,
		|	GoodsSales_.VATRate,
		|	CASE
		|		WHEN &TaxationOfVATExports
		|			THEN GoodsSales_.FEACNCode
		|		ELSE VALUE(Catalog.FEACN.EmptyRef)
		|	END,
		|	GoodsSales_.Sum,
		|	GoodsSales_.VATAmount,
		|	GoodsSales_.VATAmountCompl,
		|	GoodsSales_.VATAmountMan,
		|	GoodsSales_.AmountIncludingVAT,
		|	GoodsSales_.PercentRateOfManualDiscount,
		|	GoodsSales_.ManualDiscount,
		|	GoodsSales_.PercentRateOfAutomaticDiscountMarkup,
		|	GoodsSales_.DiscountMarkupAmount,
		|	GoodsSales_.AmountOfBonusPointsToDeduction,
		|	GoodsSales_.AmountOfBonusPointsToDeductionInCurrency,
		|	GoodsSales_.AmountOfEarnedBonusPointsInCurrency,
		|	GoodsSales_.ItemsType,
		|	GoodsSales_.ProductsInSet,
		|	GoodsSales_.ItemVariantOfSet,
		|	GoodsSales_.Department,
		|	GoodsSales_.ConnectionKey,
		|	CASE
		|		WHEN GoodsSales_.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN 1
		|		ELSE ISNULL(&QueryTextPackagingFactor3, 1)
		|	END,
		|	GoodsSales_.Count / ISNULL(&QueryTextPackagingFactor3, 1),
		|	UNDEFINED,
		|	UNDEFINED,
		|	VALUE(Catalog.Assignments.EmptyRef),
		|	GoodsSales_.WarehouseManagementIsUsedForShipment,
		|	CASE
		|		WHEN GoodsSales_.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
		|			THEN FALSE
		|		ELSE GoodsSales_.WarehouseManagementIsUsedForShipment
		|	END
		|FROM
		|	TTGoodsSaleWithoutOrder AS GoodsSales_
		|
		|ORDER BY
		|	TableBalance.SalesOrder,
		|	OrderingProducts.LineNumber
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 11
		|SELECT TOP 1
		|	CustomerOrderGoods.LineNumber AS LineNumber
		|FROM
		|	Document.SalesOrder.Goods AS CustomerOrderGoods
		|WHERE
		|	CustomerOrderGoods.Ref IN(&AnArrayOfOrders)
		|	AND CustomerOrderGoods.Products.SaleRegistrationOption IN(&ArrayOfDesignOptions)
		|	AND CustomerOrderGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND NOT CustomerOrderGoods.Canceled
		|	AND CustomerOrderGoods.Ref.Posted
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	ShippingGoods.LineNumber
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
		|WHERE
		|	ShippingGoods.Ref IN(&AnArrayOfOrders)
		|	AND ShippingGoods.Products.SaleRegistrationOption IN(&ArrayOfDesignOptions)
		|	AND ShippingGoods.Ref.Posted
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	CustomerOrderGoods.LineNumber
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS CustomerOrderGoods
		|WHERE
		|	CustomerOrderGoods.Ref IN(&AnArrayOfOrders)
		|	AND CustomerOrderGoods.Products.SaleRegistrationOption IN(&ArrayOfDesignOptions)
		|	AND CustomerOrderGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND NOT CustomerOrderGoods.Canceled
		|	AND CustomerOrderGoods.Ref.Posted
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 12
		|SELECT
		|	SalesOrder.Ref AS Ref
		|INTO ShippingDocuments
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	CASE
		|			WHEN &SelectByOrder_
		|				THEN SalesOrder.Ref IN (&AnArrayOfOrders)
		|						OR SalesOrder.Ref = &Recorder
		|			ELSE SalesOrder.Partner = &Partner
		|					AND SalesOrder.Counterparty = &Counterparty
		|					AND (SalesOrder.Contract = &Contract
		|						OR &ToUseTermsOfSales
		|							AND NOT SalesOrder.Terms.ContractsAreUsed)
		|					AND SalesOrder.Organization = &Organization
		|					AND SalesOrder.BusinessOperation IN (&EconomicOperationsOfOrders)
		|					AND (NOT &ToUseTermsOfSales
		|						OR SalesOrder.Terms = &Terms)
		|					AND SalesOrder.SalesOpportunity = &SalesOpportunity
		|					AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|						OR SalesOrder.Currency = &ARAPCurrency)
		|					AND CASE
		|						WHEN SalesOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|							THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|						ELSE SalesOrder.VATTaxation
		|					END = &VATTaxation
		|					AND SalesOrder.PriceIncludesVAT = &PriceIncludesVAT
		|					AND SalesOrder.ToReturnReusablePackage = &ToReturnReusablePackage
		|					AND (NOT &UseLinesOfBusiness
		|						OR SalesOrder.LineOfBusiness = &LineOfBusiness)
		|		END
		|	AND CASE
		|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|				THEN SalesOrder.Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|						OR SalesOrder.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			ELSE SalesOrder.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|					OR CAST(SalesOrder.Warehouse AS Catalog.Warehouses).IsFolder
		|		END
		|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|
		|UNION ALL
		|
		|SELECT
		|	CASE
		|		WHEN ShipmentHeader.ShipmentByOrders
		|			THEN ShippingGoods.SalesOrder
		|		ELSE ShipmentHeader.Ref
		|	END AS Ref
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
		|	INNER JOIN Document.GoodsShipmentToCustomer AS ShipmentHeader
		|		ON ShippingGoods.Ref = ShipmentHeader.Ref
		|WHERE
		|	CASE
		|			WHEN &SelectByOrder_
		|				THEN ShipmentHeader.Ref IN (&AnArrayOfOrders)
		|						OR ShipmentHeader.Ref = &Recorder
		|			ELSE ShipmentHeader.Partner = &Partner
		|					AND ShipmentHeader.Counterparty = &Counterparty
		|					AND ShipmentHeader.Contract = &Contract
		|					AND ShipmentHeader.Organization = &Organization
		|					AND ShipmentHeader.BusinessOperation IN (&EconomicOperationsOfOrders)
		|					AND (NOT &ToUseTermsOfSales
		|						OR ShipmentHeader.Terms = &Terms)
		|					AND ShipmentHeader.SalesOpportunity = &SalesOpportunity
		|					AND ShipmentHeader.Currency = &ARAPCurrency
		|					AND (NOT &UseLinesOfBusiness
		|						OR ShipmentHeader.LineOfBusiness = &LineOfBusiness)
		|		END
		|	AND CASE
		|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|				THEN ShipmentHeader.Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|						OR ShipmentHeader.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			ELSE ShipmentHeader.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|					OR CAST(ShipmentHeader.Warehouse AS Catalog.Warehouses).IsFolder
		|		END
		|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|
		|UNION ALL
		|
		|SELECT
		|	RequestForReturnOfGoodsFromCustomer.Ref
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
		|WHERE
		|	CASE
		|			WHEN &SelectByOrder_
		|				THEN RequestForReturnOfGoodsFromCustomer.Ref IN (&AnArrayOfOrders)
		|						OR RequestForReturnOfGoodsFromCustomer.Ref = &Recorder
		|			ELSE RequestForReturnOfGoodsFromCustomer.Partner = &Partner
		|					AND RequestForReturnOfGoodsFromCustomer.Counterparty = &Counterparty
		|					AND (RequestForReturnOfGoodsFromCustomer.Contract = &Contract
		|						OR &ToUseTermsOfSales
		|							AND NOT RequestForReturnOfGoodsFromCustomer.Terms.ContractsAreUsed)
		|					AND RequestForReturnOfGoodsFromCustomer.Organization = &Organization
		|					AND RequestForReturnOfGoodsFromCustomer.BusinessOperation IN (&EconomicOperationsOfOrders)
		|					AND (NOT &ToUseTermsOfSales
		|						OR RequestForReturnOfGoodsFromCustomer.Terms = &Terms)
		|					AND RequestForReturnOfGoodsFromCustomer.SalesOpportunity = &SalesOpportunity
		|					AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|						OR RequestForReturnOfGoodsFromCustomer.Currency = &ARAPCurrency)
		|					AND RequestForReturnOfGoodsFromCustomer.VATTaxation = &VATTaxation
		|					AND RequestForReturnOfGoodsFromCustomer.PriceIncludesVAT = &PriceIncludesVAT
		|					AND RequestForReturnOfGoodsFromCustomer.ToReturnReusablePackage = &ToReturnReusablePackage
		|					AND (NOT &UseLinesOfBusiness
		|						OR RequestForReturnOfGoodsFromCustomer.LineOfBusiness = &LineOfBusiness)
		|		END
		|	AND CASE
		|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|				THEN RequestForReturnOfGoodsFromCustomer.Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|						OR RequestForReturnOfGoodsFromCustomer.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			ELSE RequestForReturnOfGoodsFromCustomer.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|		END
		|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|
		|UNION ALL
		|
		|SELECT
		|	CustomerInvoice.Ref
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|WHERE
		|	CASE
		|			WHEN &SelectByOrder_
		|				THEN CustomerInvoice.Ref IN (&AnArrayOfOrders)
		|						OR CustomerInvoice.Ref = &Recorder
		|			ELSE CustomerInvoice.Partner = &Partner
		|					AND CustomerInvoice.Counterparty = &Counterparty
		|					AND CustomerInvoice.Contract = &Contract
		|					AND CustomerInvoice.Organization = &Organization
		|					AND CustomerInvoice.BusinessOperation IN (&EconomicOperationsOfOrders)
		|					AND (NOT &ToUseTermsOfSales
		|						OR CustomerInvoice.Terms = &Terms)
		|					AND CustomerInvoice.SalesOpportunity = &SalesOpportunity
		|					AND (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|						OR CustomerInvoice.Currency = &ARAPCurrency)
		|					AND CustomerInvoice.VATTaxation = &VATTaxation
		|					AND CustomerInvoice.PriceIncludesVAT = &PriceIncludesVAT
		|					AND CustomerInvoice.ToReturnReusablePackage = &ToReturnReusablePackage
		|					AND (NOT &UseLinesOfBusiness
		|						OR CustomerInvoice.LineOfBusiness = &LineOfBusiness)
		|		END
		|	AND CustomerInvoice.Ref = &Recorder
		|	AND CASE
		|			WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|				THEN CustomerInvoice.Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|						OR CustomerInvoice.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			ELSE CustomerInvoice.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|		END
		|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 13
		|SELECT
		|	CatalogProducts.Ref AS Ref
		|INTO ProductsWithDesignOptions
		|FROM
		|	Catalog.Products AS CatalogProducts
		|WHERE
		|	CatalogProducts.SaleRegistrationOption IN (&ArrayOfDesignOptions)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 14
		|SELECT
		|	TTOrders.Ref AS Ref,
		|	TTOrders.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
		|INTO TTOrdersAreAll
		|FROM
		|	TTOrders AS TTOrders
		|
		|UNION ALL
		|
		|SELECT
		|	TTOfShipmentOfItemsByOrder.ReferenceOrder AS Ref,
		|	CASE
		|		WHEN TTOfShipmentOfItemsByOrder.ReferenceOrder REFS Document.SalesOrder
		|			THEN CAST(TTOfShipmentOfItemsByOrder.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
		|		WHEN TTOfShipmentOfItemsByOrder.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|			THEN CAST(TTOfShipmentOfItemsByOrder.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
		|		ELSE
		|			FALSE
		|	END AS ThisIsOrderAsInvoice
		|FROM
		|	TTOfShipmentOfItemsByOrder AS TTOfShipmentOfItemsByOrder
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 15
		|SELECT
		|	OrdersShippedTurnover.Recorder AS Recorder,
		|	OrdersShippedTurnover.ReferenceOrder AS ReferenceOrder,
		|	OrdersShippedTurnover.Products AS Products,
		|	OrdersShippedTurnover.Characteristic AS Characteristic,
		|	OrdersShippedTurnover.RowCode AS RowCode,
		|	OrdersShippedTurnover.Warehouse AS Warehouse,
		|	OrdersShippedTurnover.Series AS Series,
		|	OrdersShippedTurnover.ShippedQuantity AS ShippedQuantity
		|INTO TT_ShippingOrdersShipped
		|FROM
		|	#OrdersForShipmentRegisteredRecordsExpanded4 AS OrdersShippedTurnover
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 16
		|SELECT
		|	OrdersTable.SalesOrder AS SalesOrder,
		|	OrdersTable.Products AS Products,
		|	OrdersTable.Characteristic AS Characteristic,
		|	OrdersTable.Warehouse AS Warehouse,
		|	OrdersTable.AdvancedWarehousingOnShipment AS AdvancedWarehousingOnShipment,
		|	OrdersTable.Series AS Series,
		|	OrdersTable.Purpose AS Purpose,
		|	SUM(OrdersTable.NumberInProgress) AS NumberInProgress,
		|	SUM(OrdersTable.Count) AS Count
		|FROM
		|	(SELECT
		|		GoodsForIssueBalance.DocumentShipments AS SalesOrder,
		|		GoodsForIssueBalance.Products AS Products,
		|		GoodsForIssueBalance.Characteristic AS Characteristic,
		|		GoodsForIssueBalance.Warehouse AS Warehouse,
		|		CASE
		|			WHEN GoodsForIssueBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|					AND GoodsForIssueBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS AdvancedWarehousingOnShipment,
		|		GoodsForIssueBalance.Series AS Series,
		|		GoodsForIssueBalance.Purpose AS Purpose,
		|		GoodsForIssueBalance.AssemblyInProgressReceipt AS NumberInProgress,
		|		GoodsForIssueBalance.ToShipExpense + GoodsForIssueBalance.AssembledReceipt AS Count
		|	FROM
		|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
		|				,
		|				,
		|				,
		|				,
		|				DocumentShipments IN
		|						(SELECT
		|							ShippingDocuments.Ref
		|						FROM
		|							ShippingDocuments)
		|					AND CASE
		|						WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|							THEN Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|								OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|						ELSE Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|					END
		|					AND Products IN
		|						(SELECT
		|							ProductsWithDesignOptions.Ref
		|						FROM
		|							ProductsWithDesignOptions)) AS GoodsForIssueBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsForIssueBalance.DocumentShipments,
		|		GoodsForIssueBalance.Products,
		|		GoodsForIssueBalance.Characteristic,
		|		GoodsForIssueBalance.Warehouse,
		|		(GoodsForIssueBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|			AND GoodsForIssueBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate),
		|		GoodsForIssueBalance.Series,
		|		GoodsForIssueBalance.Purpose,
		|		GoodsForIssueBalance.AssemblyInProgressReceipt,
		|		- GoodsForIssueBalance.ToShipReceipt
		|	FROM
		|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
		|				,
		|				,
		|				Recorder,
		|				,
		|				DocumentShipments IN
		|						(SELECT
		|							ShippingDocuments.Ref
		|						FROM
		|							ShippingDocuments)
		|					AND Products IN
		|						(SELECT
		|							ProductsWithDesignOptions.Ref
		|						FROM
		|							ProductsWithDesignOptions)) AS GoodsForIssueBalance
		|	WHERE GoodsForIssueBalance.Recorder REFS Document.DiscrepancyReportFollowingShipment
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		OrdersBalance.ReferenceOrder,
		|		OrdersBalance.Products,
		|		OrdersBalance.Characteristic,
		|		OrdersBalance.Warehouse,
		|		CASE
		|			WHEN WarehouseTable.UseWarehouseManagemantSystemForGoodsIssue = TRUE
		|					AND WarehouseTable.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|				THEN TRUE
		|			ELSE FALSE
		|		END,
		|		OrdersBalance.Series,
		|		CASE
		|			WHEN OrderingProducts.WithAssignment
		|				THEN OrderingProducts.Ref.Purpose
		|			WHEN OrderGoodsReplacement.WithAssignment
		|				THEN OrderGoodsReplacement.Ref.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		0,
		|		-OrdersBalance.ShippedQuantity
		|	FROM
		|		TT_ShippingOrdersShipped AS OrdersBalance
		|			LEFT JOIN Catalog.Warehouses AS WarehouseTable
		|			ON OrdersBalance.Warehouse = WarehouseTable.Ref
		|			LEFT JOIN Document.SalesOrder.Goods AS OrderingProducts
		|			ON OrdersBalance.Products = OrderingProducts.Products
		|				AND OrdersBalance.Characteristic = OrderingProducts.Characteristic
		|				AND OrdersBalance.RowCode = OrderingProducts.RowCode
		|				AND OrdersBalance.ReferenceOrder = OrderingProducts.Ref
		|			LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS OrderGoodsReplacement
		|			ON OrdersBalance.Products = OrderGoodsReplacement.Products
		|				AND OrdersBalance.Characteristic = OrderGoodsReplacement.Characteristic
		|				AND OrdersBalance.RowCode = OrderGoodsReplacement.RowCode
		|				AND OrdersBalance.ReferenceOrder = OrderGoodsReplacement.Ref
		|	WHERE
		|		OrdersBalance.Recorder <> &Recorder
		|	) AS OrdersTable
		|
		|GROUP BY
		|	OrdersTable.SalesOrder,
		|	OrdersTable.Products,
		|	OrdersTable.Characteristic,
		|	OrdersTable.Warehouse,
		|	OrdersTable.AdvancedWarehousingOnShipment,
		|	OrdersTable.Series,
		|	OrdersTable.Purpose
		|
		|HAVING
		|	(SUM(OrdersTable.Count) > 0
		|		OR SUM(OrdersTable.NumberInProgress) > 0)
		|";
	
	// Orders for offloading turnovers Expanded 1
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"	ReferenceOrder IN
		|		(SELECT
		|			ReferenceOrder
		|		FROM
		|			TTOfShipmentOfItemsByOrder)
		|	AND Products.SaleRegistrationOption IN (&ArrayOfDesignOptions)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators =
		"Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Issued_1, Accepted, TaxInvoicesRegistered";
	TableFormationParameters.Resources = "Count, Sum, VATAmountCompl, VATAmountMan";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	// Disposal of the shipment turnover Expanded 2
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(ReferenceOrder, &ThisIsOrderAsInvoice) IN
		|	(SELECT
		|		TTOrders.Ref,
		|		TTOrders.ThisIsOrderAsInvoice
		|	FROM
		|		TTOrders)
		|	AND Products.SaleRegistrationOption IN (&ArrayOfDesignOptions)
		|	AND Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators =
		"Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Issued_1, ForReceiving, Accepted, TaxInvoicesRegistered";
	TableFormationParameters.Resources = "Count, Sum, VATAmountCompl, VATAmountMan";
	TableFormationParameters.PhysicalTable = True;
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
		
	// Dispositionmovementspolded 3
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(Recorder, ReferenceOrder) IN 
		|		(SELECT
		|			ShipmentOfItems,
		|			ReferenceOrder
		|		FROM
		|			TTOfShipmentOfItemsByOrder)
		|	AND NOT ReversingEntry
		|	AND Products.SaleRegistrationOption IN (&ArrayOfDesignOptions)
		|	AND Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "Shipped";
	TableFormationParameters.Resources = "Count, Sum";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded3 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#OrdersForShipmentRegisteredRecordsExpanded3",
		OrdersForShipmentRegisteredRecordsExpanded3);
	
	// Dispositions of the offload movementsextended 4
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(ReferenceOrder, &ThisIsOrderAsInvoice) IN
		|		(SELECT
		|			Ref,
		|			ThisIsOrderAsInvoice
		|		FROM
		|			TTOrdersAreAll)
		|	AND CASE
		|		WHEN CAST(&ImplementationWarehouse AS Catalog.Warehouses).IsFolder
		|			THEN Warehouse IN HIERARCHY (&ImplementationWarehouse)
		|					OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &ImplementationWarehouse)
		|	END
		|	AND Products IN
		|		(SELECT
		|			ProductsWithDesignOptions.Ref
		|		FROM
		|			ProductsWithDesignOptions)";
	TableFormationParameters.Group =
		"Recorder, ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "Shipped";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded4 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);

	Query.Text = StrReplace(Query.Text,
		"#OrdersForShipmentRegisteredRecordsExpanded4",
		OrdersForShipmentRegisteredRecordsExpanded4);
	
	// Query Text for VAT rate if the order is Shipment of goods to the customer
	If ValueIsFilled(SelectionData_.Organization) Then
		CompanyForCalculatingVATRate = SelectionData_.Organization;
	ElsIf TypeOf(AnArrayOfOrders) = Type("Array") And AnArrayOfOrders.Count() > 0 Then
		CompanyForCalculatingVATRate = Common.ObjectAttributeValue(AnArrayOfOrders[0], "Organization");
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"&VATRateShipmentOfGoodsWithoutOrder",
		VATAccountingERP.QueryTextVATRate(
			"ShippingGoods.Ref.VATTaxation",
			"ShippingGoods.Products",
			"&ToReturnReusablePackage"));
	
	Query.Text = StrReplace(Query.Text,
		"&VATRateForEnteringGoodsBalances",
		VATAccountingERP.QueryTextVATRate(
			"EnteringProductBalances.Ref.Lot.VATTaxation",
			"EnteringProductBalances.Products",
			"&ToReturnReusablePackage"));
	
	VATAccountingERP.SetParametersForVATRateRequest(
		Query.Parameters,
		CompanyForCalculatingVATRate,
		?(ValueIsFilled(SelectionData_.Ref),
			SelectionData_.Ref.Date,
			BegOfDay(CurrentSessionDate())));
			
	Query.SetParameter("RegistrationCountry",
		SettingsValueClientServerCached.CountryOfOrganizationRegistration(CompanyForCalculatingVATRate));
	
	// Packing Factors
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"WaybillGoods.Package",
			"WaybillGoods.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"OrderingProducts.Package",
			"OrderingProducts.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsSales_.Package",
			"GoodsSales_.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor4",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ShippingGoods.Package",
			"ShippingGoods.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor5",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"EnteringProductBalances.Package",
			"EnteringProductBalances.Products"));
	
	SetPrivilegedMode(True);
	Return Query.ExecuteBatch();
	
EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.CustomerInvoice - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	Goods.SalesOrder        AS OrderDocument,
	|	Goods.AmountIncludingVAT           AS Sum,
	|	Goods.AmountARAP AS AmountARAP,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.RowCode           AS RowCode,
	|	&ToReturnReusablePackage AS ToReturnReusablePackage,
	|	&PackageDepositIsRequired      AS PackageDepositIsRequired,
	|	&OrderingCaps                AS Order_Header,
	|	&ByOrders                 AS ByOrders
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE &LinkCondition_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	GoodsSales_.OrderDocument AS ReferenceOrder,
	|	ShipmentOfItems.Ref AS Patch,
	|	ShipmentOfItems.Date AS DateOfShipment
	|INTO ShipmentsOfGoods
	|FROM
	|	Document.GoodsShipmentToCustomer AS ShipmentOfItems
	|	INNER JOIN TTProducts_1 AS GoodsSales_
	|		ON ShipmentOfItems.Ref = GoodsSales_.OrderDocument
	|WHERE
	|	ShipmentOfItems.Posted
	|	AND &ThisIsTransferOfOwnership2_5
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	GoodsSales_.OrderDocument AS ReferenceOrder,
	|	ShipmentOfItems.Ref AS Patch,
	|	ShipmentOfItems.Date AS DateOfShipment
	|FROM
	|	Document.GoodsShipmentToCustomer AS ShipmentOfItems
	|	INNER JOIN TTProducts_1 AS GoodsSales_
	|		ON ShipmentOfItems.CorrectedDocument = GoodsSales_.OrderDocument
	|WHERE
	|	ShipmentOfItems.Posted
	|	AND &ThisIsTransferOfOwnership2_5
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT 
	|	NestedQuery.OrderDocument                            AS OrderDocument,
	|	ISNULL(NestedQuery.OrderDocument.DATE, DATETIME(1,1,1)) AS OrderDate,
	|	ISNULL(NestedQuery.OrderDocument.ApprovalDate, DATETIME(1,1,1)) AS ApprovalDate,
	|	NestedQuery.ExceedingOrder                      AS ExceedingOrder,
	|	SUM(NestedQuery.PaymentAmount)              AS PaymentAmount,
	|	SUM(NestedQuery.AmountARAP)       AS AmountARAP,
	|	SUM(NestedQuery.PackageDepositValue)         AS PackageDepositValue,
	|	SUM(NestedQuery.AmountARAPByPackage) AS AmountARAPByPackage,
	|	NestedQuery.DateOfShipment                     AS DateOfShipment
	|FROM (SELECT
	|		CASE WHEN ISNULL(Goods.OrderDocument.Number, """") = """"
	|				THEN Goods.Order_Header
	|			ELSE Goods.OrderDocument
	|		END                             AS OrderDocument,
	|		FALSE                              AS ExceedingOrder,
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                        AS PaymentAmount,
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.AmountARAP
	|			ELSE 0
	|		END                            AS AmountARAP,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                            AS PackageDepositValue,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.AmountARAP
	|			ELSE 0 
	|		END                            AS AmountARAPByPackage,
	|		CASE
	|			WHEN NOT &ThisIsTransferOfOwnership2_5
	|				THEN DATETIME(1, 1, 1)
	|			WHEN OrderingProducts.Ref IS NOT NULL
	|				THEN OrderingProducts.DateOfShipment
	|			WHEN RequestForReturnOfGoods_.Ref IS NOT NULL
	|				THEN RequestForReturnOfGoods_.DateOfShipment
	|			WHEN SourceDocument.Ref IS NOT NULL
	|				THEN SourceDocument.Date
	|			WHEN ShipmentsOfGoods.ReferenceOrder IS NOT NULL
	|				THEN ShipmentsOfGoods.DateOfShipment
	|			ELSE
	|				&Date
	|		END                            AS DateOfShipment
	|	FROM TTProducts_1 AS Goods
	|		LEFT JOIN Document.SalesOrder.Goods AS OrderingProducts
	|			ON Goods.RowCode = OrderingProducts.RowCode
	|				AND Goods.OrderDocument = OrderingProducts.Ref
	|				AND Goods.Products = OrderingProducts.Products
	|				AND Goods.Characteristic = OrderingProducts.Characteristic
	|				AND OrderingProducts.Ref.Posted
	|				AND &ThisIsTransferOfOwnership2_5
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
	|			ON Goods.RowCode = RequestForReturnOfGoods_.RowCode
	|				AND Goods.OrderDocument = RequestForReturnOfGoods_.Ref
	|				AND Goods.Products = RequestForReturnOfGoods_.Products
	|				AND Goods.Characteristic = RequestForReturnOfGoods_.Characteristic
	|				AND RequestForReturnOfGoods_.Ref.Posted
	|				AND &ThisIsTransferOfOwnership2_5
	|		LEFT JOIN Document.SourceDocument AS SourceDocument
	|			ON Goods.OrderDocument = SourceDocument.Ref
	|				AND SourceDocument.Posted
	|				AND &ThisIsTransferOfOwnership2_5
	|		LEFT JOIN ShipmentsOfGoods AS ShipmentsOfGoods
	|			ON Goods.OrderDocument = ShipmentsOfGoods.ReferenceOrder
	|				AND &ThisIsTransferOfOwnership2_5
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			ON ShipmentsOfGoods.Patch = DocumentsRegistry.ReversedDocument
	|				AND DocumentsRegistry.Posted
	|				AND NOT DocumentsRegistry.AdditionalRecord
	|				AND &ThisIsTransferOfOwnership2_5
	|	WHERE
	|		Goods.RowCode <> 0
	|		AND DocumentsRegistry.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE WHEN ISNULL(GoodsTable.OrderDocument.Number, """") = """"
	|				THEN GoodsTable.Order_Header
	|			ELSE GoodsTable.OrderDocument
	|		END                        AS OrderDocument,
	|		GoodsTable.ByOrders AS ExceedingOrder,
	|		CASE
	|			WHEN GoodsTable.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT GoodsTable.ToReturnReusablePackage
	|				THEN GoodsTable.Sum
	|			ELSE 0 
	|		END                        AS PaymentAmount,
	|		CASE
	|			WHEN GoodsTable.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT GoodsTable.ToReturnReusablePackage
	|				THEN GoodsTable.AmountARAP
	|			ELSE 0
	|		END                            AS AmountARAP,
	|		CASE 
	|			WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND GoodsTable.PackageDepositIsRequired
	|				THEN GoodsTable.Sum
	|			ELSE 0 
	|		END                            AS PackageDepositValue,
	|		CASE 
	|			WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND GoodsTable.PackageDepositIsRequired
	|				THEN GoodsTable.AmountARAP
	|			ELSE 0 
	|		END                            AS AmountARAPByPackage,
	|		CASE
	|			WHEN NOT &ThisIsTransferOfOwnership2_5
	|				THEN DATETIME(1, 1, 1)
	|			WHEN SalesOrder.Ref IS NOT NULL
	|				THEN SalesOrder.Date
	|			WHEN ReturnRequest.Ref IS NOT NULL
	|				THEN ReturnRequest.Date
	|			ELSE
	|				DATETIME(1, 1, 1)
	|		END                            AS DateOfShipment
	|	FROM TTProducts_1 AS GoodsTable
	|		LEFT JOIN Document.SalesOrder AS SalesOrder
	|			ON GoodsTable.OrderDocument = SalesOrder.Ref
	|				AND &ThisIsTransferOfOwnership2_5
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
	|			ON GoodsTable.OrderDocument = ReturnRequest.Ref
	|				AND &ThisIsTransferOfOwnership2_5
	|	WHERE
	|		GoodsTable.RowCode = 0) AS NestedQuery
	|GROUP BY
	|	NestedQuery.OrderDocument,
	|	NestedQuery.ExceedingOrder,
	|	ISNULL(NestedQuery.OrderDocument.DATE, DATETIME(1,1,1)),
	|	ISNULL(NestedQuery.OrderDocument.ApprovalDate, DATETIME(1,1,1)),
	|	NestedQuery.DateOfShipment
	|;";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&Table", "Document.SalesOrder.Goods");
		Query.Text = StrReplace(Query.Text, "&ToReturnReusablePackage", "Goods.Ref.ToReturnReusablePackage");
		Query.Text = StrReplace(Query.Text, "&PackageDepositIsRequired", "Goods.Ref.PackageDepositIsRequired");
		Query.Text = StrReplace(Query.Text, "&OrderingCaps", "Goods.Ref.SalesOrder");
		Query.Text = StrReplace(Query.Text, "&ByOrders", "Goods.Ref.OrderSales");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		Query.Text = StrReplace(Query.Text, "&ThisIsTransferOfOwnership2_5", "FALSE");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	OrderAmounts = Query.Execute().Unload();
	
	If AttributesValues = Undefined Or Not AttributesValues.ThisIsTransferOfOwnership2_5 Then
		OrderAmounts.Columns.Delete("DateOfShipment");
	EndIf;
	
	Return OrderAmounts;
	
EndFunction

//Returns the text of the request for the transferred goods
//
// Returns:
//  String - 
//
Function QueryTextGoodsTransferred() Export
	
	QueryText =
	"SELECT
	|	InvoiceGoods.LineNumber AS LineNumber,
	|	InvoiceGoods.Products AS Products,
	|	InvoiceGoods.Characteristic AS Characteristic,
	|	InvoiceGoods.Series AS Series,
	|	InvoiceGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	InvoiceGoods.Purpose AS Purpose,
	|	InvoiceGoods.CCDNumber AS CCDNumber,
	|	InvoiceGoods.Count AS Count
	|INTO TTGoodsWaybill
	|FROM
	|	&Goods AS InvoiceGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	MIN(TTGoodsWaybill.LineNumber) AS LineNumber,
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE TTGoodsWaybill.Series
	|	END AS Series,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DifferentSeriesAccounting,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber,
	|	SUM(TTGoodsWaybill.Count) AS Count
	|INTO InvoiceGoods
	|FROM
	|	TTGoodsWaybill AS TTGoodsWaybill
	|		LEFT JOIN Catalog.Products AS TT_Products
	|		ON TTGoodsWaybill.Products = TT_Products.Ref
	|		LEFT JOIN Catalog.ItemKinds AS TTTypesOfNomenclature
	|		ON TT_Products.ProductKind = TTTypesOfNomenclature.Ref
	|		LEFT JOIN Catalog.BatchAccountingPolicies AS TTSeriesAccountingPolicies
	|		ON TTTypesOfNomenclature.BatchAccountingPolicy = TTSeriesAccountingPolicies.Ref
	|	
	|GROUP BY
	|	TTGoodsWaybill.Products,
	|	TTGoodsWaybill.Characteristic,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE TTGoodsWaybill.Series
	|	END,
	|	CASE
	|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
	|			AND &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			AND NOT TTSeriesAccountingPolicies.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TTGoodsWaybill.Purpose,
	|	TTGoodsWaybill.CCDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	DimensionKeys.Ref AS Ref
	|INTO DimensionKeys
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|WHERE
	|	DimensionKeys.StorageLocation = &Contract
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3 - Balances as of the document date
	|SELECT ALLOWED
	|	GoodsTransferredBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferredBalance.CCDNumber AS CCDNumber,
	|	GoodsTransferredBalance.CountBalance AS CountBalance
	|INTO GoodsTransferredBalance
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(&Period, ItemsLocationAttributes IN
	|		(SELECT
	|			DimensionKeys.Ref
	|		FROM
	|			DimensionKeys AS DimensionKeys)
	|		AND Organization = &Organization) AS GoodsTransferredBalance
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4 - Current Balances
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	GoodsTransferred.CountBalance AS CountBalance,
	|	CASE
	|		WHEN GoodsTransferred.CountBalance < 0
	|			THEN -1
	|		ELSE 1
	|	END AS Character
	|INTO GoodsTransferredBalanceMark
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(, ItemsLocationAttributes IN
	|		(SELECT
	|			DimensionKeys.Ref
	|		FROM
	|			DimensionKeys AS DimensionKeys)
	|	AND Organization = &Organization) AS GoodsTransferred
	|;
	|
	|
	|//////////////////////////////////////////////////////////////////////////////// 5 - Balances and quantity by registrar
	|SELECT ALLOWED
	|	GoodsTransferred.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	SUM(GoodsTransferred.CountBalance) AS CountBalance
	|INTO GoodsTransferred
	|FROM
	|	(SELECT
	|		GoodsTransferred.ItemsLocationAttributes,
	|		GoodsTransferred.CCDNumber,
	|		CASE
	|			WHEN ISNULL(Balance.CountBalance * Balance.Character, 0) < GoodsTransferred.CountBalance * ISNULL(Balance.Character, 1)
	|				THEN ISNULL(Balance.CountBalance, 0)
	|			ELSE GoodsTransferred.CountBalance
	|		END AS CountBalance
	|	FROM
	|		GoodsTransferredBalance AS GoodsTransferred
	|			LEFT JOIN GoodsTransferredBalanceMark AS Balance
	|			ON GoodsTransferred.ItemsLocationAttributes = Balance.ItemsLocationAttributes
	|			AND GoodsTransferred.CCDNumber = Balance.CCDNumber
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTransferredToRegistrar.ItemsLocationAttributes,
	|		GoodsTransferredToRegistrar.CCDNumber,
	|		GoodsTransferredToRegistrar.Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS GoodsTransferredToRegistrar
	|	WHERE
	|		GoodsTransferredToRegistrar.Recorder = &Recorder
	|		AND GoodsTransferredToRegistrar.Active
	|		AND GoodsTransferredToRegistrar.ItemsLocationAttributes IN
	|			(SELECT
	|				DimensionKeys.Ref
	|			FROM
	|				DimensionKeys AS DimensionKeys)
	|		AND GoodsTransferredToRegistrar.Organization = &Organization) AS GoodsTransferred
	|GROUP BY
	|	GoodsTransferred.ItemsLocationAttributes,
	|	GoodsTransferred.CCDNumber
	|
	|HAVING
	|	SUM(GoodsTransferred.CountBalance) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT ALLOWED
	|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS
	|		Characteristic,
	|	CASE
	|		WHEN TT_Item.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END AS Purpose,
	|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	GoodsTransferred.CCDNumber AS CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry AS OriginCountry,
	|	SUM(GoodsTransferred.CountBalance) AS CountBalance
	|INTO GoodsTransferredGrouping
	|FROM
	|	GoodsTransferred AS GoodsTransferred
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTransferred.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN Catalog.Products AS TT_Item
	|		ON DimensionKeys.Products = TT_Item.Ref
	|GROUP BY
	|	ISNULL(DimensionKeys.Products, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(DimensionKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	CASE
	|		WHEN TT_Item.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DimensionKeys.Purpose
	|	END,
	|	ISNULL(DimensionKeys.Series, VALUE(Catalog.ItemsBatches.EmptyRef)),
	|	GoodsTransferred.CCDNumber,
	|	GoodsTransferred.CCDNumber.OriginCountry
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7 Connection with goods from the consignment note
	|SELECT
	|	GoodsTransferredGrouping.Products AS Products,
	|	GoodsTransferredGrouping.Characteristic AS Characteristic,
	|	GoodsTransferredGrouping.Purpose AS Purpose,
	|	GoodsTransferredGrouping.Series AS Series,
	|	ISNULL(InvoiceGoods.DifferentSeriesAccounting, FALSE) AS DifferentSeriesAccounting,
	|	GoodsTransferredGrouping.CCDNumber AS CCDNumber,
	|	GoodsTransferredGrouping.OriginCountry AS OriginCountry,
	|	GoodsTransferredGrouping.CountBalance AS CountBalance,
	|	GoodsTransferredGrouping.CountBalance - ISNULL(InvoiceGoods.Count, 0) AS LeftToSelect,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityIsSelected,
	|	ISNULL(InvoiceGoods.Count, 0) AS QuantityInInvoice
	|
	|FROM
	|	GoodsTransferredGrouping AS GoodsTransferredGrouping
	|		LEFT JOIN InvoiceGoods AS InvoiceGoods
	|		ON GoodsTransferredGrouping.Products = InvoiceGoods.Products
	|		AND GoodsTransferredGrouping.Characteristic = InvoiceGoods.Characteristic
	|		AND GoodsTransferredGrouping.Purpose = InvoiceGoods.Purpose
	|		AND GoodsTransferredGrouping.Series = InvoiceGoods.Series
	|		AND GoodsTransferredGrouping.CCDNumber = InvoiceGoods.CCDNumber
	|
	|ORDER BY
	|	ISNULL(InvoiceGoods.LineNumber, 99999)
	|";
	
	Return QueryText;
	
EndFunction

// Gets an action handler depending on the business operation
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions, Undefined - 
//
// Returns:
//  CommonModule, DocumentManager - handler manager
//
Function ActionHandler(BusinessOperation = Undefined) Export
	
	Handler = Documents.CustomerInvoice;
	
	Return Handler;
	
EndFunction

#EndRegion
#Region Excisable_Items

Function ExciseTaxOfOperations()
	
	TaxableOfOperations = New Array;
	TaxableOfOperations.Add(Enums.BusinessTransactions.SaleToCustomer);
	TaxableOfOperations.Add(Enums.BusinessTransactions.SaleToCustomerLocalAccounting);
	
	Return TaxableOfOperations;
	
EndFunction

#EndRegion
#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//     ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices";
	FormNameImplementation = "Document.CustomerInvoice.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		CommonQueryParameters.IsFullUser
		And (AccessRight("Insert", Metadata.Documents.CustomerInvoice)
			Or AccessRight("Update", Metadata.Documents.CustomerInvoice))
		And AccessRight("View",   Metadata.Documents.CustomerInvoice)
		And AccessRight("Read",     Metadata.Documents.RequestForReturnOfGoodsFromCustomer)
		And AccessRight("Read",     Metadata.InformationRegisters.ShipmentAndReturnReferencesToFulfill);
	
	If Not Enabled Then
		Return;
	EndIf;
	
	AvailabilityOfOrders = 
		AccessRight("Insert", Metadata.Documents.CustomerInvoice)
		And GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
	AvailabilityOfStatuses = 
		GetFunctionalOption("UseStatusesOfGoodsServicesSales"); 
		
	AccessibilityOnGo = GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|		&AvailabilityOfOrders1,
	|		&AccessibilityOnGo1,
	|		COUNT(DISTINCT DocumentData__.SalesOfGoodsAndServicesForPrepayment) AS SalesOfGoodsAndServicesForPrepayment
	|FROM
	|	(SELECT
	|		&AvailabilityOfOrders2,
	|		&AccessibilityOnGo2,
	|		NULL AS SalesOfGoodsAndServicesForPrepayment
	|	FROM
	|		(SELECT
	|			ShipmentAndReturnReferencesToFulfill.ReferenceOrder AS Ref,
	|			UNDEFINED AS Warehouse,
	|			UNDEFINED AS Products,
	|			UNDEFINED AS Characteristic,
	|			UNDEFINED AS Series
	|		FROM
	|			InformationRegister.ShipmentAndReturnReferencesToFulfill AS ShipmentAndReturnReferencesToFulfill
	|		WHERE
	|			(ShipmentAndReturnReferencesToFulfill.ReferenceOrder REFS Document.SalesOrder
	|				OR ShipmentAndReturnReferencesToFulfill.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|			AND ShipmentAndReturnReferencesToFulfill.DocumentStateToRegister <> VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
	|			AND ShipmentAndReturnReferencesToFulfill.ReferenceOrder IS NOT NULL
	|			AND NOT ShipmentAndReturnReferencesToFulfill.BusinessOperation IN(&BusinessTransactions)
	|	
	|		UNION ALL
	|	
	|		SELECT
	|			GoodsForIssue.DocumentShipments,
	|			GoodsForIssue.Warehouse,
	|			GoodsForIssue.Products,
	|			GoodsForIssue.Characteristic,
	|			GoodsForIssue.Series
	|		FROM
	|			AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
	|				,
	|				,
	|				,
	|				,
	|				(DocumentShipments REFS Document.SalesOrder
	|						OR DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|						OR DocumentShipments REFS Document.CustomerInvoice)) AS GoodsForIssue
	|			LEFT JOIN AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
	|					,
	|					,
	|					,
	|					,
	|					(DocumentShipments REFS Document.SalesOrder
	|							OR DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|							OR DocumentShipments REFS Document.CustomerInvoice)) AS GoodsForIssueBalanceAndTurnovers
	|			ON GoodsForIssue.DocumentShipments = GoodsForIssueBalanceAndTurnovers.DocumentShipments
	|				AND GoodsForIssue.Warehouse = GoodsForIssueBalanceAndTurnovers.Warehouse
	|		WHERE
	|			NOT ISNULL(GoodsForIssue.DocumentShipments.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) IN(&BusinessTransactions)
	|			AND (GoodsForIssue.ToShipClosingBalance - GoodsForIssue.AssembledClosingBalance > 0
	|				OR GoodsForIssue.ToRegisterClosingBalance > 0)
	|			AND GoodsForIssue.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND GoodsForIssue.DocumentShipments.Ref IS NOT NULL
	|			AND GoodsForIssue.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate) AS OrdersToBeRegistered
	|
	|	UNION
	|	
	|	SELECT DISTINCT
	|		&AvailabilityOfOrders3,
	|		&AccessibilityOnGo3,
	|		NULL
	|	FROM
	|		Document.CustomerInvoice AS CustomerInvoice
	|	WHERE
	|		CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|		AND CustomerInvoice.Manager = &User
	|		AND NOT CustomerInvoice.DeletionMark
	|
	|	UNION
	|	
	|	SELECT DISTINCT
	|		&AvailabilityOfOrders3,
	|		&AccessibilityOnGo4,
	|		CustomerInvoice.Ref
	|	FROM
	|		Document.CustomerInvoice AS CustomerInvoice
	|	WHERE
	|		CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
	|		AND CustomerInvoice.Manager = &User
	|		AND NOT CustomerInvoice.DeletionMark) AS DocumentData__";
	
	EconomicOperationsOfTransfers = New Array;
	EconomicOperationsOfTransfers.Add(Enums.BusinessTransactions.ReturnFromCustodian);
	EconomicOperationsOfTransfers.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	
	Query.SetParameter("DateOfShipmentImplementation", New Boundary(EndOfDay(CommonQueryParameters.CurrentDate), BoundaryType.Including));
	Query.SetParameter("BusinessTransactions", EconomicOperationsOfTransfers);
	
	// If we remove service comments from the request text, we will "unlock" the request lines
	Query.Text = StrReplace(Query.Text, "&AvailabilityOfOrders1,", ?(AvailabilityOfOrders, "COUNT(DISTINCT DocumentData__.OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress) AS OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress,", ""));
	Query.Text = StrReplace(Query.Text, "&AvailabilityOfOrders2,", ?(AvailabilityOfOrders, "OrdersToBeRegistered.Ref AS OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress,", ""));
	Query.Text = StrReplace(Query.Text, "&AvailabilityOfOrders3,", ?(AvailabilityOfOrders, "NULL,", ""));

	Query.Text = StrReplace(Query.Text, "&AccessibilityOnGo1,", ?(AccessibilityOnGo, "COUNT(DISTINCT DocumentData__.SalesOfGoodsAndServicesInTransit) AS SalesOfGoodsAndServicesInTransit,", ""));
	Query.Text = StrReplace(Query.Text, "&AccessibilityOnGo2,", ?(AccessibilityOnGo, "NULL AS SalesOfGoodsAndServicesInTransit,", ""));
	Query.Text = StrReplace(Query.Text, "&AccessibilityOnGo3,", ?(AccessibilityOnGo, "CustomerInvoice.Ref,", ""));
	Query.Text = StrReplace(Query.Text, "&AccessibilityOnGo4,", ?(AccessibilityOnGo, "NULL,", ""));

	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Documentsrealization of goods and services
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "DocumentsForSaleOfGoodsAndServices";
	UserTaskParent.Presentation  = NStr("vi = 'Chứng từ bán hàng và cung cấp dịch vụ';
										|ru = 'Документы реализации товаров и услуг';
										|en = 'Customer invoices'; fa = 'فاکتورهای مشتری';
										|it = 'Documenti di vendita di merci e servizi';
										|pl = 'Dokumenty nabycia towarów i usług';
										|tr = 'Mal ve hizmet satışına ilişkin belgeler'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	ThereAreOrders_ = False;
	If AvailabilityOfOrders Then
		// OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress
		FilterParameters = New Structure;
		FilterParameters.Insert("Status", Enums.StatusesOfCustomerInvoices.Shipped);
		FilterParameters.Insert("Warehouse", Catalogs.Warehouses.EmptyRef());
		FilterParameters.Insert("DateOfShipment", CommonQueryParameters.CurrentDate);
		FilterParameters.Insert("Manager", CommonQueryParameters.User);
		
		FormParameters = New Structure;
		FormParameters.Insert("QuickFilterStructure", FilterParameters);
		FormParameters.Insert("CurrentPageName", "GroupToRegister");
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress";
		ToDoItem.HasToDoItems       = Result.OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress > 0;
		ToDoItem.Presentation  = NStr("vi = 'Lệnh lập chứng từ đang làm việc';
										|ru = 'Распоряжения на оформление в работе';
										|en = 'References for registration in progress'; fa = 'References for registration in progress';
										|it = 'Le disposizioni per la formalizzazione sono in esecuzione';
										|pl = 'Zamówienia rejestracji są w toku wykonywania';
										|tr = 'İş yerinde işleme alınacak siparişler'");
		ToDoItem.Count     = Result.OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormName;
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Owner       = "DocumentsForSaleOfGoodsAndServices";
		
		If Result.OrdersForRegistrationOfSalesOfGoodsAndServicesInProgress > 0 Then
			ThereAreOrders_ = True;
		EndIf;
	EndIf;
	
	ThereAreDocumentsOnWay = False;
	If AccessibilityOnGo Then
		// SalesOfGoodsAndServicesInTransit
		FilterParameters = New Structure;
		FilterParameters.Insert("Status", Enums.StatusesOfCustomerInvoices.InTransit);
		FilterParameters.Insert("Manager", CommonQueryParameters.User);
		FilterParameters.Insert("SaleRegistrationOption", Enums.SalesRegistrationOptions.EmptyRef());
		
		FormParameters = New Structure;
		FormParameters.Insert("QuickFilterStructure", FilterParameters);
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "SalesOfGoodsAndServicesInTransit";
		ToDoItem.HasToDoItems       = Result.SalesOfGoodsAndServicesInTransit > 0;
		ToDoItem.Presentation  = NStr("vi = 'Giao hàng đang đi đường';
										|ru = 'Реализации в пути';
										|en = 'Sales in transit'; fa = 'Sales in transit';
										|it = 'Vendite in transito';
										|pl = 'Towary w drodze';
										|tr = 'Transit satışlar'");
		ToDoItem.Count     = Result.SalesOfGoodsAndServicesInTransit;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormNameImplementation;
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Owner       = "DocumentsForSaleOfGoodsAndServices";
		
		ThereAreDocumentsOnWay = ToDoItem.HasToDoItems;
	EndIf;
	
	ThereAreDocumentsForPrepayment = False;
	If AvailabilityOfStatuses Then
		// SalesOfGoodsAndServicesForPrepayment
		FilterParameters = New Structure;
		FilterParameters.Insert("Status", Enums.StatusesOfCustomerInvoices.ForPrepayment);
		FilterParameters.Insert("Manager", CommonQueryParameters.User);
		FilterParameters.Insert("SaleRegistrationOption", Enums.SalesRegistrationOptions.EmptyRef());
		
		FormParameters = New Structure;
		FormParameters.Insert("QuickFilterStructure", FilterParameters);
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "SalesOfGoodsAndServicesForPrepayment";
		ToDoItem.HasToDoItems       = Result.SalesOfGoodsAndServicesForPrepayment > 0;
		ToDoItem.Presentation  = NStr("vi = 'Chứng từ bán hàng cần trả trước';
										|ru = 'Реализации к предоплате';
										|en = 'Sales for prepayment'; fa = 'Sales for prepayment';
										|it = 'Vendite al pagamento anticipato';
										|pl = 'Realizacja do przedpłaty';
										|tr = 'Ön ödemeli satışlar'");
		ToDoItem.Count     = Result.SalesOfGoodsAndServicesForPrepayment;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormNameImplementation;
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Owner       = "DocumentsForSaleOfGoodsAndServices";
		
		ThereAreDocumentsForPrepayment = ToDoItem.HasToDoItems;
	EndIf;
	
	If ThereAreOrders_
		Or ThereAreDocumentsOnWay
		Or ThereAreDocumentsForPrepayment Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
		
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	If GetFunctionalOption("UseStatusesOfGoodsServicesSales") Then
		
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfCustomerInvoices.ForPrepayment);
		If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
			TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfCustomerInvoices.InTransit);
		EndIf;
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfCustomerInvoices.Shipped);
		
	EndIf;
	
	Return Table;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Warehouse                   AS StorageLocation,
	|	DocumentData.Department           AS Department,
	|	DocumentData.Manager                AS EmployeeResponsible,
	|	DocumentData.Author                   AS Author,
	|	CAST(DocumentData.Comment AS STRING (100)) AS Comment,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.DocumentAmount          AS Sum,
	|	DocumentData.Status                  AS Status,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	CASE
	|		WHEN DocumentData.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN """"
	|		ELSE &ContractInformation
	|	END                                   AS More,
	|	DocumentData.Date                    AS RecordingInAccountingDate,
	|	CASE 
	|		WHEN DocumentData.ConsigneeDate <> DATETIME(1,1,1)
	|			THEN DocumentData.ConsigneeDate
	|		ELSE
	|			DocumentData.Date
	|	END AS SourceDocumentDate,
	|	CASE
	|		WHEN DocumentData.ConsigneeNumber <> """"
	|			THEN DocumentData.ConsigneeNumber
	|		ELSE
	|			&NumberForPrinting
	|	END AS SourceDocumentNumber,
	|	DocumentData.ConsigneeDocumentName AS SourceDocumentName,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	If Not DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "Document.CustomerInvoice", "DocumentDataHeader");
	Else
		ContractInformationTemplate = "vi = 'Theo hợp đồng %1';
										|ru = 'По договору %1';
										|en = 'Under the %1 contract';
										|it = 'По договору %1';
										|pl = 'Under the %1 contract';
										|tr = '%1 sözleşmesi kapsamında'"; // @NStr
		QueryText = StrReplace(QueryText, "&ContractInformation", """" + ContractInformationTemplate + """");
		QueryText = StrReplace(QueryText, "%1", """" + " + CAST("""""""" AS STRING(1)) + 
			|CAST(DocumentData.Contract.Description AS STRING(150)) + CAST("""""""" AS STRING(1)) + "
			+ """");
		QueryText = StrReplace(QueryText, "&NumberForPrinting", "DocumentData.Number");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInSalesLog

Function QueryTextOrdersToBeRegistered(Organization = Undefined, Warehouse = Undefined) Export

	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.VirtualTableParameters =
		"&Warehouse IN (Warehouse, VALUE(Catalog.Warehouses.EmptyRef)
		|		AND (ReferenceOrder REFS Document.SalesOrder
		|			OR ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer)";
	TableFormationParameters.Group = "ReferenceOrder, Warehouse";
	TableFormationParameters.Indicators = "ToShip";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText =
		"SELECT ALLOWED TOP 1
		|	OrdersToBeRegistered.Ref AS Ref
		|FROM
		|	(SELECT TOP 1
		|		ShipmentReferences.ReferenceOrder AS Ref,
		|		ShipmentReferences.Warehouse
		|	FROM
		|		#ShipmentOrdersTurnoverExpanded AS ShipmentReferences
		|	WHERE
		|		ShipmentReferences.QuantityToBeShippedTurnover > 0
		|		AND &SelectionConditionOrganizationOrders
		|	
		|	UNION ALL
		|	
		|	SELECT TOP 1
		|		GoodsForIssue.DocumentShipments,
		|		GoodsForIssue.Warehouse
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Balance(
		|				,
		|				(Warehouse = &Warehouse
		|					OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
		|					AND Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|					AND Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
		|					AND (DocumentShipments REFS Document.SalesOrder
		|						OR DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
		|						OR DocumentShipments REFS Document.CustomerInvoice)) AS GoodsForIssue
		|	WHERE
		|		(GoodsForIssue.ToShipBalance - GoodsForIssue.AssembledBalance > 0
		|				OR GoodsForIssue.ToRegisterBalance > 0)
		|		AND &SelectionConditionOrganizationOfGoodsForShipment
		|		) AS OrdersToBeRegistered
		|WHERE
		|	NOT OrdersToBeRegistered.Ref IS NULL";
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	If ValueIsFilled(Organization) Then
		FilterCriterion = "
		|		CASE
		|			WHEN ShipmentReferences.ReferenceOrder REFS Document.SalesOrder
		|				THEN CAST(ShipmentReferences.ReferenceOrder AS Document.SalesOrder).Organization
		|			WHEN ShipmentReferences.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
		|				THEN CAST(ShipmentReferences.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Organization
		|		END = &Organization";
		QueryText = StrReplace(QueryText,"&SelectionConditionOrganizationOrders", FilterCriterion);
		
		FilterCriterion = "
		|		CASE
		|			WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
		|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Organization
		|			WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
		|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Organization
		|			WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
		|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Organization
		|		END = &Organization";
		QueryText = StrReplace(QueryText,"&SelectionConditionOrganizationOfGoodsForShipment", FilterCriterion);
	Else
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganizationOrders", "");
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganizationOfGoodsForShipment", "");
	EndIf;
		
	Return QueryText
	
EndFunction

Function ThereAreOrdersForRegistration(Organization = Undefined, Warehouse = Undefined) Export
		
	QueryText = QueryTextOrdersToBeRegistered(Organization, Warehouse);

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function CreateHyperlinkToDesign(Parameters) Export
	
	Organization = Parameters.Organization;
	Warehouse = Parameters.Warehouse;
	
	ShowOrders = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
		And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue);
		
	Hyperlink = Undefined;
	HyperlinkText = NStr("vi = 'Hóa đơn';
						|ru = 'Накладные';
						|en = 'Invoices'; fa = 'فاکتورها';
						|it = 'Lettere di vettura';
						|pl = 'Listy przewozowe';
						|tr = 'İrsaliye'");
	If ShowOrders Then
		Hyperlink = New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			NameOfSalesOfGoodsAndServicesListForm());
	EndIf;
	
	If ShowOrders And ThereAreOrdersForRegistration(Organization, Warehouse) Then
		Hyperlink = New FormattedString(HyperlinkText,,,,
			NameOfSalesOfGoodsAndServicesListForm());
	EndIf;
	
	Return Hyperlink;
	
EndFunction

Function NameOfSalesOfGoodsAndServicesListForm() Export
	
	Return "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices";
	
EndFunction

#EndRegion

Function GetDepositAmountByContainer(Goods) Export
	
	Query = New Query("
	|SELECT
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	Goods.AmountIncludingVAT AS AmountIncludingVAT
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|;
	|SELECT
	|	ISNULL(SUM(Goods.AmountIncludingVAT),0) AS Sum
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT"));
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].Sum;
	Return TotalAmount__;
	
EndFunction

#EndRegion

#EndIf
#EndIf
