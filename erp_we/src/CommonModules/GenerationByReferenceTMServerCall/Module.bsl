#Region Private

#Region PurchaseOrders

Function CheckPossibilityOfEnteringBasedOn(CommandParameter) Export
	
	AttributesStructure1 = Common.ObjectAttributesValues(CommandParameter,"Status,Posted");
	
	ObjectManager = Common.ObjectManagerByRef(CommandParameter);
	ObjectManager.CheckPossibilityOfEnteringBasedOn(
		CommandParameter, AttributesStructure1.Status, Not AttributesStructure1.Posted, True);
	
EndFunction

#EndRegion

#Region DocumentsBasedOnOrder

// Forms the parameters for opening the invoice form based on the order/orders.
// 
// Parameters:
//  References - Array of DocumentRef- the list of orders on the basis of which the invoice is issued.
//  InvoiceName - String - The type of document on the basis of which the order is formed.
//  BusinessOperation - Undefined, EnumRef.BusinessTransactions - economic operation
// 
// Returns:
//  Structure - Parameters for opening the invoice form based on the order
Function ParametersForOpeningInvoiceFormBasedOnOrder(References, InvoiceName, BusinessOperation = Undefined) Export
	
	DataToCheck = Documents[InvoiceName].DataForInputValidationBasedOn(References, BusinessOperation);
	OpenDocumentForm = False;
	
	If ValueIsFilled(DataToCheck.Basis) Then
		
		// Checking the status
		AcceptableStatuses = Documents[DataToCheck.Basis.Metadata().Name].ValidInputStatusesBasedOn(InvoiceName);
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(DataToCheck.Basis, DataToCheck.Status, False,
			AcceptableStatuses.Find(DataToCheck.Status) = Undefined, AcceptableStatuses);
			
		// Checking actions
		If Not DataToCheck.ThereIsShip Then
			Raise ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment()
		EndIf;
		
		OpenDocumentForm = True;
		
	EndIf;
	
	If Not ValueIsFilled(DataToCheck.InstructionsForRegistration) Then
		Raise NStr("vi = 'Không cần lập hóa đơn: lệnh cần lập chứng từ đã được thực hiện hoặc không tồn tại.';
					|ru = 'Оформление накладных не требуется: распоряжения на оформление уже исполнены, либо отсутствуют.';
					|en = 'Invoice registration is not required: the registration references are already fulfilled or missing.'; fa = 'Invoice registration is not required: the registration references are already fulfilled or missing.';
					|it = 'Invoice registration is not required: the registration references are already fulfilled or missing.';
					|pl = 'Invoice registration is not required: the registration references are already fulfilled or missing.';
					|tr = 'Fatura düzenlemeye gerek yoktur: Fatura düzenleme talimatları zaten yerine getirilmiş veya mevcut değildir.'");
	EndIf;
	
	If Not ValueIsFilled(DataToCheck.Basis) And DataToCheck.CanBeGrouped Then
		GroupingInstructions = CommonClientServer.CopyArray(DataToCheck.InstructionsForRegistration);
		InvoicesServer.GroupDocumentsByKeyFields(GroupingInstructions,
			Documents[InvoiceName].KeyFieldsOfHeader());
		If GroupingInstructions.Count() = 1 Then
			OpenDocumentForm = True;
		EndIf;
	EndIf;
	
	OpeningParameters = New Structure;
	If OpenDocumentForm Then
		
		FillParameters = Documents[InvoiceName].DocumentFillingParameters();
		FillPropertyValues(FillParameters, DataToCheck);
		HeaderAttributes = Documents[InvoiceName].InvoiceFillingData(DataToCheck.InstructionsForRegistration,
			DataToCheck);
		Documents[InvoiceName].InitializeFillingParameters(FillParameters, HeaderAttributes,
			DataToCheck.InstructionsForRegistration);
		
		OpeningParameters.Insert("FormName", "Document." + InvoiceName + ".ObjectForm");
		OpeningParameters.Insert("FormParameters", New Structure("Basis", FillParameters));
		OpeningParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.Independent);
		
	Else
		
		OpeningParameters = Documents[InvoiceName].ParametersForOpeningWorkplaceForm(BusinessOperation);
		OpeningParameters.FormParameters.Insert("FormAssignmentKey", "InputOnBasis");
		OpeningParameters.FormParameters.Insert("References",        References);
		OpeningParameters.Insert("FormWindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
	Return OpeningParameters;
	
EndFunction

Function ReportOfCompletedWorkFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	
	If Common.IsReference(TypeOf(CommandParameter))
		Or Not GetFunctionalOption("UseCustomerInvoicesForSeveralOrders") Then
		
		If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() > 0 Then
			DocumentBasis = CommandParameter[0];
		Else
			DocumentBasis = CommandParameter;
		EndIf;
		
		BasisParameters.Insert("DocumentBasis", DocumentBasis);
		
	Else
		
		HeaderAttributes = New Structure;
		If Not SalesServerCall.GenerateDataForFillingInReportsOfCompletedWorks(CommandParameter, HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("HeaderAttributes",    HeaderAttributes);
		BasisParameters.Insert("DocumentBasis", CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function PurchaseOfGoodsAndServicesFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("WarehouseForReceipt",  Undefined);
	
	If Common.IsReference(TypeOf(CommandParameter))
		Or Not GetFunctionalOption("UseReceiptForMultipleOrders") Then
		
		If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() > 0 Then
			DocumentBasis = CommandParameter[0];
		Else
			DocumentBasis = CommandParameter;
		EndIf;
		
		If TMCommonUse.CheckOrderOperation(DocumentBasis,"VendorInvoice") Then
			
			BasisParameters.Insert("DocumentBasis", DocumentBasis);
			
		Else
			
			Return Undefined;
			
		EndIf;
	Else
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(CommandParameter, "VendorInvoice", HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("HeaderAttributes",    HeaderAttributes);
		BasisParameters.Insert("DocumentBasis", CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function AcceptanceOfGoodsForStorageFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("WarehouseForReceipt",  Undefined);
	
	If TypeOf(CommandParameter) = Type("Array")
		And CommandParameter.Count() > 0 Then
		
		DocumentBasis = CommandParameter[0];
		
	Else
		DocumentBasis = CommandParameter;
	EndIf;
	
	BusinessOperation = Undefined;
	If TypeOf(DocumentBasis) = Type("DocumentRef.MaterialProviderOrder2_5") Then
		BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5");
	EndIf;
	If Common.IsReference(TypeOf(CommandParameter))
		Or BusinessOperation = Undefined
			And Not GetFunctionalOption("UseReceiptForMultipleOrders") Then
		
		If TMCommonUse.CheckOrderOperation(DocumentBasis, "GoodsReceiptForStorage", BusinessOperation) Then
			BasisParameters.Insert("DocumentBasis", DocumentBasis);
		Else
			Return Undefined;
		EndIf;
		
	Else
		
		HeaderAttributes = New Structure;
		If Not PurchasesServerCall.GenerateReceiptFillingData(CommandParameter, "GoodsReceiptForStorage", HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("HeaderAttributes",    HeaderAttributes);
		BasisParameters.Insert("DocumentBasis", CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function PaymentCardOperation_ReturnFillingParameters(CommandParameter) Export
	
	If TypeOf(CommandParameter) = Type("Array")
		And CommandParameter.Count() > 0 Then
		TheseGrounds = CommandParameter[0];	
	Else
		TheseGrounds = CommandParameter;
	EndIf;	
	
	Return New Structure("Basis", New Structure("Basis, BusinessOperation", TheseGrounds, Enums.BusinessTransactions.RefundToCustomer));
	
EndFunction

#EndRegion

#Region TransferOrder

Function CreateMovingOrderBasedOnPurchaseOfGoodsAndServicesForGroupOfWarehousesCreationParameters(CommandParameter) Export
	
	ParametersForCreatingWarehousesByGroup = Documents.TransferOrder.ParametersForCreatingWarehousesForGroupBasedOnReceiptOfGoodsAndServices(CommandParameter);
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

Function CreateMovingOrderBasedOnAcceptanceOfGoodsForStorageByWarehouseGroupCreationParameters(CommandParameter) Export
	
	ParametersForCreatingWarehousesByGroup = Documents.TransferOrder.ParametersForCreatingGroupOfWarehousesForAcceptingGoodsForStorage(CommandParameter);
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

#Region InventoryTransfer

Function CreateMovementOfGoodsBasedOnGroupOfWarehousesCreationParameters(CommandParameter) Export
	
	ParametersForCreatingWarehousesByGroup = Documents.InventoryTransfer.ParametersForCreatingWarehousesByGroup(CommandParameter);
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

#Region WriteOffOfGoodsShortages

Function CreateStockShortageRecognitionBasedOnGroupOfWarehousesCreationParameters(CommandParameter) Export
	
	ParametersForCreatingWarehousesByGroup = Documents.WriteOffOfGoodsShortages.ParametersForCreatingWarehousesByGroup(CommandParameter);
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

#Region GoodsDamage

Function CreateDamageToGoodsBasedOnWarehouseGroupCreationParameters(CommandParameter) Export
	
	ParametersForCreatingWarehousesByGroup = Documents.GoodsDamage.ParametersForCreatingWarehousesByGroup(CommandParameter);
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

#Region ReturnOfGoodsToVendor

Function CreateReturnOfGoodsToSupplierBasedOnWarehouseGroupCreationParameters(CommandParameter) Export
	
	ParametersForCreatingWarehousesByGroup = Documents.ReturnOfGoodsToVendor.ParametersForCreatingWarehousesByGroup(CommandParameter);
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

#Region GoodsShipmentFromStorage

Function CreateShipmentOfGoodsFromStorageBasedOnGroupOfWarehousesCreationParameters(CommandParameter) Export
	
	ParametersForCreatingWarehousesByGroup = Documents.GoodsShipmentFromStorage.ParametersForCreatingWarehousesByGroup(CommandParameter);
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

#Region CustomerInvoice

Function SalesOfGoodsAndServicesFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("OriginWarehouse", 			Undefined);
	BasisParameters.Insert("SaleRegistrationOption", Enums.SalesRegistrationOptions.CustomerInvoice);
	
	If Common.IsReference(TypeOf(CommandParameter))
		Or Not GetFunctionalOption("UseSaleByMultipleOrders") Then
		
		If TypeOf(CommandParameter) = Type("Array")
			And CommandParameter.Count() > 0 Then
			
			DocumentBasis = CommandParameter[0];
			
		Else
			DocumentBasis = CommandParameter;
		EndIf;
		
		BusinessOperation = Undefined;
		If TypeOf(DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			EconomicOperationImplementation = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
			BusinessOperation = SalesServer.GetBusinessOfOperationOfImplementationOfRefund(EconomicOperationImplementation);
		EndIf;
		
		If TMCommonUse.CheckOrderOperation(DocumentBasis, "CustomerInvoice", BusinessOperation) Then
			BasisParameters.Insert("DocumentBasis", DocumentBasis);
		Else
			Return Undefined;
		EndIf;
		
	Else
		
		HeaderAttributes = New Structure;
		DocumentName   = "CustomerInvoice";
		
		If Not SalesServerCall.GenerateImplementationFillInData(CommandParameter, DocumentName, HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("HeaderAttributes",      HeaderAttributes);
		BasisParameters.Insert("DocumentBasis",   CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function TransferOfOwnershipFormOpeningParameters(CommandParameter) Export
	
	HeaderAttributes = New Structure;
	DocumentName   = "CustomerInvoice";
	
	If Not SalesServerCall.GenerateImplementationFillInData(CommandParameter,
		DocumentName,
		HeaderAttributes,
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")) Then
		
		Return Undefined;
	EndIf;
	
	BasisParameters = ParametersOfBasisForTransferOfOwnership();
	BasisParameters.OriginWarehouse = Undefined;
	BasisParameters.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
	BasisParameters.DocumentBasis = CommandParameter;
	BasisParameters.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods");
	BasisParameters.HeaderAttributes = HeaderAttributes;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function ShipmentOfItemsToClientFormOpeningParameters(CommandParameter) Export
	
	DataForInputValidationBasedOn =
		Documents.GoodsShipmentToCustomer.DataForInputValidationBasedOn(CommandParameter);
	
	ProhibitedBusinessTransactions = New Array();
	ProhibitedBusinessTransactions.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
	
	For Each BusinessOperation In DataForInputValidationBasedOn.BusinessTransactions Do
		
		If ProhibitedBusinessTransactions.Find(BusinessOperation) <> Undefined Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhập chứng từ giao hàng cho khách trên cơ sở chứng từ có giao dịch ""%1"".';
					|ru = 'Ввод отгрузки товаров клиенту на основании документа с операцией ""%1"" невозможен.';
					|en = 'Cannot generate a goods shipment to customer from a base document with the ""%1"" business transaction.'; fa = 'Cannot generate a goods shipment to customer from a base document with the ""%1"" business transaction.';
					|it = 'Cannot generate a goods shipment to customer from a base document with the ""%1"" business transaction.';
					|pl = 'Cannot generate a goods shipment to customer from a base document with the ""%1"" business transaction.';
					|tr = '""%1"" işlemli bir belge baz alınarak müşteriye ürün sevkiyatı girilemez.'"),
				BusinessOperation);
			
		EndIf;
		
	EndDo;
	
	If Not DataForInputValidationBasedOn.ThereIsShip Then
		Raise ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment();
	EndIf;
	
	BasisParameters = New Structure;
	BasisParameters.Insert("OriginWarehouse", Undefined);
	
	HeaderAttributes = New Structure;
	DocumentName   = "GoodsShipmentToCustomer";
	
	If Not SalesServerCall.GenerateImplementationFillInData(CommandParameter, DocumentName, HeaderAttributes) Then
		Return Undefined;
	EndIf;
	
	BasisParameters.Insert("HeaderAttributes",      HeaderAttributes);
	BasisParameters.Insert("DocumentBasis",   CommandParameter);
		
	Return New Structure("Basis", BasisParameters);
	
EndFunction

// Function-constructor of parameters of the basis of transfer of ownership
//
// Returns:
//  Structure:
//		* OriginWarehouse 				- CatalogRef.Warehouses
//		* SaleRegistrationOption 		- EnumRef.SalesRegistrationOptions
//		* DocumentBasis 			- DocumentRef.SalesOrder, 
//										- Array of DocumentRef.SalesOrder
//		* BusinessOperation 		- EnumRef.BusinessTransactions
//		* HeaderAttributes				- Structure - the structure where the header Attributes from the array of orders will be placed
//
Function ParametersOfBasisForTransferOfOwnership()
	
	ListOfFoundationDocumentTypes = New Array;
	ListOfFoundationDocumentTypes.Add(New TypeDescription("DocumentRef.SalesOrder"));
	ListOfFoundationDocumentTypes.Add(New TypeDescription("Array"));
	
	BasisParameters = New Structure;
	BasisParameters.Insert("OriginWarehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	BasisParameters.Insert("SaleRegistrationOption",
		PredefinedValue("Enum.SalesRegistrationOptions.EmptyRef"));
	BasisParameters.Insert("DocumentBasis", ListOfFoundationDocumentTypes);
	BasisParameters.Insert("BusinessOperation",
		PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	BasisParameters.Insert("HeaderAttributes", New Structure);
	
	Return BasisParameters;
	
EndFunction

#EndRegion

#Region ProformaInvoice

Function InvoiceImplementationReportGetFormOpeningParameters(Basis) Export
	
	FormOpenParameters = Undefined;
	
	AnArrayOfOrders = InvoiceForPaymentImplementationReportReceiveOrdersImplementationServer(Basis);
	ARAPObjectSettings = Common.ObjectAttributeValue(Basis, "ARAPObjectSettings");
	
	If (ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
				Or AnArrayOfOrders.Count() = 0)
			And ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts") Then
		
		FormOpenParameters = New Structure();
		If GetFunctionalOption("NewOnlineARAPAccounting") Then
			FormOpenParameters.Insert("FormName", "Document.CustomerCommercialInvoice.Form.CommercialInvoiceCreationForm");
		Else
			FormOpenParameters.Insert("FormName", "Document.CustomerCommercialInvoice.Form.DocumentForm");
		EndIf;
		FormOpenParameters.Insert("FormParameters", New Structure("Basis", Basis));
		
	ElsIf AnArrayOfOrders.Count() = 1
		And ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders") Then
		DocumentBasis = SalesServerCall.GetBasisForPaymentInvoice(AnArrayOfOrders[0]);
		FormParameters = New Structure;
		FormParameters.Insert("Basis", DocumentBasis);
		FormParameters.Insert("OnlyActualDebt", True);
		
		FormOpenParameters = New Structure();
		FormOpenParameters.Insert("FormName", "Document.CustomerCommercialInvoice.Form.CommercialInvoiceCreationForm");
		FormOpenParameters.Insert("FormParameters", FormParameters);
		
	ElsIf ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts") Then
		FormParameters = New Structure;
		FormParameters.Insert("Basis", Basis);
		FormParameters.Insert("OnlyActualDebt", True);
			
		FormOpenParameters = New Structure();
		FormOpenParameters.Insert("FormName", "Document.CustomerCommercialInvoice.Form.DocumentForm");
		FormOpenParameters.Insert("FormParameters", FormParameters);
		
	EndIf;
	
	Return FormOpenParameters;
	
EndFunction

Function InvoiceForPaymentImplementationReportReceiveOrdersImplementationServer(Basis)
	
	Query = New Query;
	Query.SetParameter("Basis", Basis);
	
	If TypeOf(Basis) = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
		
		Query.Text =
		"SELECT DISTINCT
		|	PurchasingReportToConsignorPrincipalGoods.SalesOrder AS SalesOrder
		|FROM
		|	Document.PurchasingReportToConsignorPrincipal.Goods AS PurchasingReportToConsignorPrincipalGoods
		|WHERE
		|	PurchasingReportToConsignorPrincipalGoods.Ref = &Basis
		|	AND PurchasingReportToConsignorPrincipalGoods.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)";
		
		QueryResult = Query.Execute();
		AnArrayOfOrders = QueryResult.Unload().UnloadColumn("SalesOrder");
		
	Else
		
		Query.Text =
		"SELECT
		|	TheOrdersTable.SalesOrder AS SalesOrder
		|FROM
		|	Document.CustomerInvoice.Goods AS TheOrdersTable
		|WHERE
		|	TheOrdersTable.Ref = &Basis
		|	AND TheOrdersTable.SalesOrder <> UNDEFINED
		|	AND TheOrdersTable.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
		|	AND TheOrdersTable.SalesOrder <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|	AND NOT (VALUETYPE(TheOrdersTable.SalesOrder) = TYPE(Document.GoodsShipmentToCustomer)
		|		OR VALUETYPE(TheOrdersTable.SalesOrder) = TYPE(Document.SourceDocument)
		|			AND CAST(TheOrdersTable.SalesOrder AS Document.SourceDocument).SourceDocumentType =
		|			VALUE(Enum.SourceDocumentTypes.GoodsShipmentToCustomer))
		|
		|UNION
		|
		|SELECT
		|	TheOrdersTable.SalesOrder AS SalesOrder
		|FROM
		|	Document.CustomerInvoice AS TheOrdersTable
		|WHERE
		|	TheOrdersTable.Ref = &Basis
		|	AND TheOrdersTable.SalesOrder <> UNDEFINED
		|	AND TheOrdersTable.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
		|	AND TheOrdersTable.SalesOrder <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|	AND NOT (VALUETYPE(TheOrdersTable.SalesOrder) = TYPE(Document.GoodsShipmentToCustomer)
		|		OR VALUETYPE(TheOrdersTable.SalesOrder) = TYPE(Document.SourceDocument)
		|			AND CAST(TheOrdersTable.SalesOrder AS Document.SourceDocument).SourceDocumentType =
		|			VALUE(Enum.SourceDocumentTypes.GoodsShipmentToCustomer))
		|
		|UNION
		|
		|SELECT DISTINCT
		|	CustomerInvoiceServicesServices.SalesOrder AS SalesOrder
		|FROM
		|	Document.CustomerInvoiceServices.Services AS CustomerInvoiceServicesServices
		|WHERE
		|	CustomerInvoiceServicesServices.Ref = &Basis
		|	AND CustomerInvoiceServicesServices.SalesOrder <> UNDEFINED
		|	AND CustomerInvoiceServicesServices.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
		|	AND CustomerInvoiceServicesServices.SalesOrder <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|
		|UNION
		|
		|SELECT
		|	CustomerInvoiceServices.SalesOrder AS SalesOrder
		|FROM
		|	Document.CustomerInvoiceServices AS CustomerInvoiceServices
		|WHERE
		|	CustomerInvoiceServices.Ref = &Basis
		|	AND CustomerInvoiceServices.SalesOrder <> UNDEFINED
		|	AND CustomerInvoiceServices.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
		|	AND CustomerInvoiceServices.SalesOrder <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)";
		
		QueryResult = Query.ExecuteBatch();
		AnArrayOfOrders = QueryResult[QueryResult.UBound()].Unload().UnloadColumn("SalesOrder");
		
	EndIf;
	
	Return AnArrayOfOrders;
	
EndFunction

Function InvoiceForPaymentUnderAgreementCheckWhetherInvoicesCanBeCreated(Contract) Export
	
	ARAPObjectSettings = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings");
	Return ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
	
EndFunction

Function InvoiceForPaymentReportGiver2_5GetFormOpeningParameters(ReportToMaterialProvider) Export
	
	FormOpenParameters = Undefined;
	
	AnArrayOfOrders = InvoiceForPaymentReportToGiver2_5GetOrdersReportToGiver2_5Server(ReportToMaterialProvider);
	
	If InvoiceForPaymentReportToGiverCheckSettlementProcedure(ReportToMaterialProvider) Or AnArrayOfOrders.Count() = 0 Then
		
		FormOpenParameters = New Structure();
		FormOpenParameters.Insert("FormName", "Document.CustomerCommercialInvoice.Form.DocumentForm");
		FormOpenParameters.Insert("FormParameters", New Structure("Basis", ReportToMaterialProvider));
		
	ElsIf AnArrayOfOrders.Count() = 1 Then
		
		DocumentBasis = SalesServerCall.GetBasisForPaymentInvoice(AnArrayOfOrders[0]);
		FormParameters = New Structure("Basis", DocumentBasis);
			
		FormOpenParameters = New Structure();
		FormOpenParameters.Insert("FormName", "Document.CustomerCommercialInvoice.Form.CommercialInvoiceCreationForm");
		FormOpenParameters.Insert("FormParameters", FormParameters);
		
	EndIf;
	
	Return FormOpenParameters;
	
EndFunction

Function InvoiceForPaymentReportToGiver2_5GetOrdersReportToGiver2_5Server(ReportToMaterialProvider)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ProductTable.MaterialProviderOrder AS SalesOrder
	|INTO
	|	Orders
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ProductTable
	|WHERE
	|	ProductTable.Ref = &ReportToMaterialProvider
	|	AND ProductTable.MaterialProviderOrder <> VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	ReportToMaterialProvider2_5.MaterialProviderOrder AS SalesOrder
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS ReportToMaterialProvider2_5
	|WHERE
	|	ReportToMaterialProvider2_5.Ref = &ReportToMaterialProvider
	|	AND ReportToMaterialProvider2_5.MaterialProviderOrder <> VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Orders.SalesOrder AS SalesOrder
	|FROM
	|	Orders AS Orders
	|";
		
	Query.SetParameter("ReportToMaterialProvider", ReportToMaterialProvider);
	
	Result = Query.Execute();
	
	Return Result.Unload().UnloadColumn("SalesOrder");
	
EndFunction

Function InvoiceForPaymentReportToGiverCheckSettlementProcedure(ReportToMaterialProvider)
	
	ARAPObjectSettings = Common.ObjectAttributeValue(ReportToMaterialProvider, "ARAPObjectSettings");
	
	Return ARAPObjectSettings <> Enums.ARAPObjectSettings.ByOrders;
	
EndFunction



#EndRegion

#Region ProductRangeChange

Function SetInventoryLevelControl(CommandParameter) Export
	
	Return DataProcessors.SetUpStockReplenishment.EstablishInventoryMaintenanceToDocumentAssortmentChanges(CommandParameter);
	
EndFunction

#EndRegion

Function CheckRecalculationStatusOnServer(RecalculationLink) Export
	
	CheckResult = New Structure;
	CheckResult.Insert("YouCanOpenAssistant", False);
	CheckResult.Insert("UserMessage", "");
	
	Status = Common.ObjectAttributeValue(RecalculationLink, "Status");
	If Status = Enums.InventoryRecountStatuses.Completed2 Then 
		CheckResult.YouCanOpenAssistant = True;
	Else
		UserMessage = NStr("vi = 'Chứng từ ""%InventoryRecount%"" có trạng thái ""%CurrentStatus%"". Có thể sử dụng trợ lý tạo biên bản kho chỉ theo trạng thái ""%StatusCompleted_%"".';
							|ru = 'Документ ""%InventoryRecount%"" находится в статусе ""%CurrentStatus%"". Воспользоваться помощником оформления складских актов можно только в статусе ""%StatusCompleted_%"".';
							|en = '""%InventoryRecount%"" status is ""%CurrentStatus%."" You can run Inventory Adjustment Wizard only if its status is ""%StatusCompleted_%.""'; fa = '""%InventoryRecount%"" status is ""%CurrentStatus%."" You can run Inventory Adjustment Wizard only if its status is ""%StatusCompleted_%.""';
							|it = 'Il documento ""%InventoryRecount%"" è nello stato ""%CurrentStatus%"". È possibile utilizzare l''assistente per la registrazione degli atti di magazzino solo nello stato ""%StatusCompleted_%"".';
							|pl = 'Dokument ""%InventoryRecount%"" jest w statusie ""%CurrentStatus%"". Skorzystać z asystenta tworzenia aktów magazynowych można tylko w statusie ""%StatusCompleted_%"".';
							|tr = '""%InventoryRecount%"" belgesi ""%CurrentStatus%"" durumundadır. Stok düzeltmeleri asistanı yalnızca ""%StatusCompleted_%"" durumunda kullanılabilir.'");
		UserMessage = StrReplace(UserMessage, "%InventoryRecount%", RecalculationLink);
		UserMessage = StrReplace(UserMessage, "%CurrentStatus%", Status);
		UserMessage = StrReplace(UserMessage, "%StatusCompleted_%", Enums.InventoryRecountStatuses.Completed2);
		CheckResult.UserMessage	= UserMessage;
	EndIf;
	
	Return CheckResult;
	
EndFunction




Function CreateProductionOrder22BasedOnGiverSOrder2_5VerificationOfGrounds(ObjectsOfBases) Export
	
	Return Documents.MaterialProviderOrder2_5.CreateProductionOrder22BasedOnGiverSOrderCheckingGrounds(ObjectsOfBases);
	
EndFunction

Function CreateProductionOperationBasedOnBaseCheck(BasisObject) Export
	
	Return Documents.ProductionOperation2_2.CreateProductionOperationBasedOnBaseCheck(BasisObject);
	
EndFunction

Function ToCreateInitialRemnantsOfUnfinishedProductionByBatchesOfProduction(DocumentReference, FormIdentifier) Export
	
	JobDescription = NStr("vi = 'Phân bổ số dư ban đầu SXDD theo lô sản xuất';
							|ru = 'Распределение начальных остатков НЗП по партиям производство';
							|en = 'Allocation of WIP opening balances by production lots'; fa = 'Allocation of WIP opening balances by production lots';
							|it = 'Spartizione dei saldi iniziali della produzione non completata per lotti di produzione';
							|pl = 'Rozkład sald początkowych produkcji w toku według partii produkcji';
							|tr = 'TMÜ bakiyelerinin üretim lotlarına göre dağılımı'");
	MethodToExecute = "Documents.InitialWIPBalancesByBusinessUnits.DistributeInitialBalancesAmongProductionBatches";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		MethodToExecute,
		DocumentReference,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

Function AcceptanceOfFinishedProductBeingRepairedFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	
	If TypeOf(CommandParameter) = Type("Array")
		And CommandParameter.Count() > 0 Then
		DocumentBasis = CommandParameter[0];
	Else
		DocumentBasis = CommandParameter;
	EndIf;
	
	BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5");
	
	If TMCommonUse.CheckOrderOperation(DocumentBasis, "GoodsReceiptForStorage", BusinessOperation) Then
		BasisParameters.Insert("DocumentIsBasisOfFinishedProductBeingRepaired", DocumentBasis);
	Else
		Return Undefined;
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function ReportOfDiscrepanciesAfterAcceptanceAndOpeningOfForm(CommandParameter) Export
	
	If TMCommonUse.CheckOrderOperation(CommandParameter[0], "DiscrepancyReportFollowingReceipt") Then
		BasisParameters = New Structure;
		BasisParameters.Insert("DocumentBasis", CommandParameter[0]);
		
		FormParameters = New Structure("Basis", BasisParameters);
		
		Return FormParameters;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region TransferOfGoodsToBailee

Function TransferOfGoodsToCustodianFormOpeningParameters(ObjectsOfBases) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("OriginWarehouse", Undefined);
	BasisParameters.Insert("ErrorText", "");
	
	If Common.IsReference(TypeOf(ObjectsOfBases))
		Or Not GetFunctionalOption("UseSaleByMultipleOrders") Then
		
		If TypeOf(ObjectsOfBases) = Type("Array")
			And ObjectsOfBases.Count() > 0 Then
			
			DocumentBasis = ObjectsOfBases[0];
			
		Else
			DocumentBasis = ObjectsOfBases;
		EndIf;
		
		If TMCommonUse.CheckOrderOperation(DocumentBasis, "TransferOfGoodsToBailee") Then
			BasisParameters.Insert("DocumentBasis", DocumentBasis);
		ElsIf TMCommonUse.CheckOrderOperation(DocumentBasis, "TransferToCommissionAgent")
			And ValueIsFilled(DocumentBasis.Contract) Then
			BasisParameters.Insert("DocumentBasis", DocumentBasis);
		Else
			Return Undefined;
		EndIf;
		
	Else
		
		HeaderAttributes = New Structure;
		DocumentName   = "TransferOfGoodsToBailee";
		
		Query = New Query();
		Query.SetParameter("ReferencesArrray", ObjectsOfBases);
		Query.Text =
			"SELECT
			|	SalesOrder.Ref AS Ref
			|FROM
			|	Document.SalesOrder AS SalesOrder
			|	LEFT JOIN Catalog.CounterpartyContracts AS ContractFromOrder
			|		ON ContractFromOrder.Ref = SalesOrder.Contract
			|WHERE
			|	SalesOrder.Ref IN(&ReferencesArrray)
			|	AND ((SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
			|		AND NOT SalesOrder.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
			|		AND ContractFromOrder.ConsignmentSales25)
			|		OR SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale))";
		
		ResultOfCheckingObjectsOfBases = Query.Execute().Unload().UnloadColumn("Ref");
		
		If ResultOfCheckingObjectsOfBases.Count() = 0 Then
			
			If ObjectsOfBases.Count() = 1 Then
				ErrorText = NStr("vi = 'Không thể thực hiện lệnh đối với chứng từ này';
								|ru = 'Команда не может быть выполнена для данного документа';
								|en = 'Unable to execute the command for this document'; fa = 'Unable to execute the command for this document';
								|it = 'Il comando non può essere eseguito per questo documento';
								|pl = 'Nie można wykonać polecenia dla danego dokumentu.';
								|tr = 'Mevcut belge için komut gerçekleştirilemez'");
			Else
				ErrorText = NStr("vi = 'Không thể thực hiện lệnh đối với chứng từ đã chọn';
								|ru = 'Команда не может быть выполнена для выбранных документов';
								|en = 'Command cannot be executed for the selected documents'; fa = 'Command cannot be executed for the selected documents';
								|it = 'Il comando non può essere eseguito per documenti selezionati';
								|pl = 'Nie można wykonać polecenia dla wybranych dokumentów.';
								|tr = 'Seçili belgeler için komut gerçekleştirilemez'");
			EndIf;
			
			Common.MessageToUser(ErrorText);
			
			Return Undefined;
			
		EndIf;
		
		If Not SalesServerCall.GenerateImplementationFillInData(ResultOfCheckingObjectsOfBases, DocumentName, HeaderAttributes) Then
			Return Undefined;
		EndIf;
		
		BasisParameters.Insert("HeaderAttributes",    HeaderAttributes);
		BasisParameters.Insert("DocumentBasis", ResultOfCheckingObjectsOfBases);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

#EndRegion

#Region InventoryAssignmentAdjustment

Function CreateAdjustmentToDestinationOfGoodsBasedOnCustomerSOrderCheckingDestinationType(CommandParameters) Export
	
	Return Documents.InventoryAssignmentAdjustment.CreateAdjustmentToDestinationOfGoodsBasedOnCustomerSOrderCheckingDestinationType(CommandParameters);
	
EndFunction

#EndRegion

#Region GoodsShipmentFromStorage

Function CreateShipmentOfGoodsFromStorageBasedOnCustomerOrderDestinationTypeVerification(CommandParameters) Export
	
	Return Documents.GoodsShipmentFromStorage.CreateShipmentOfGoodsFromStorageBasedOnCustomerOrderVerificationOfBusinessTransactions(CommandParameters);
	
EndFunction

Function ShipmentOfGoodsFromStorageTransferOfFormOpeningParametersToGiver(CommandParameter) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("BusinessOperation", Enums.BusinessTransactions.TransferToMaterialProvider2_5);
	
	If Common.IsReference(TypeOf(CommandParameter))
	 Or Not GetFunctionalOption("UseSaleByMultipleOrders") Then
		
		If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() > 0 Then
			DocumentBasis = CommandParameter[0];
		Else
			DocumentBasis = CommandParameter;
		EndIf;
		
		BasisParameters.Insert("DocumentBasis", DocumentBasis);
		
	Else
		
		BasisParameters.Insert("DocumentBasis", CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function ShipmentOfGoodsFromStorageReturnToGiverFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("BusinessOperation", Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	
	If Common.IsReference(TypeOf(CommandParameter))
	 Or Not GetFunctionalOption("UseSaleByMultipleOrders") Then
		
		If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() > 0 Then
			DocumentBasis = CommandParameter[0];
		Else
			DocumentBasis = CommandParameter;
		EndIf;
		
		BasisParameters.Insert("DocumentBasis", DocumentBasis);
		
	Else
		
		BasisParameters.Insert("DocumentBasis", CommandParameter);
		
	EndIf;
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

Function ShipmentOfGoodsFromStorageReturnOfRepairedFinishedProductFormOpeningParameters(CommandParameter) Export
	
	BasisParameters = New Structure;
	BasisParameters.Insert("BusinessOperation", Enums.BusinessTransactions.ReturnToMaterialProvider2_5);
	
	DocumentBasis = CommandParameter;
	
	BasisParameters.Insert("DocumentBasis",                      DocumentBasis);
	BasisParameters.Insert("DocumentIsBasisOfFinishedProductBeingRepaired", True);
	
	Return New Structure("Basis", BasisParameters);
	
EndFunction

#EndRegion

#EndRegion
