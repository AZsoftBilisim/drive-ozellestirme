#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a temporary data table of the document.
// Used for filling in inventory types.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date					AS Date,
	|	&Organization			AS Organization,
	|	&Partner				AS Partner,
	|	&Counterparty				AS Counterparty,
	|	&Terms				AS Terms,
	|	&Contract				AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&Warehouse					AS Warehouse,
	|	&BusinessOperation	AS BusinessOperation,
	|	FALSE					AS ThereAreTransactionsInTablePart,
	|	&Department			AS Department,
	|	&Manager				AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5)
	|			THEN VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|	END                                                      AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber                AS LineNumber,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic             AS Characteristic,
	|	TableOfGoods.Purpose                 AS Purpose,
	|	TableOfGoods.Series                      AS Series,
	|	TableOfGoods.BatchesIndicationStatus        AS BatchesIndicationStatus,
	|	TableOfGoods.DocumentInflow        AS DocumentInflow,
	|	TableOfGoods.SalesOrder               AS SalesOrder,
	|	TableOfGoods.Count                 AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END								      AS QuantityByGBRN,
	|	TableOfGoods.Package                   AS Package,
	|	TableOfGoods.Sum                      AS Sum,
	|	TableOfGoods.Warehouse                      AS Warehouse,
	|	&FieldTextTableOfGoodsCCDNumber_	      AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber         AS LineNumber,
	|	TableOfGoods.Products        AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic      AS Characteristic,
	|	TableOfGoods.Series			   AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose          AS Purpose,
	|	TableOfGoods.DocumentInflow AS DocumentInflow,
	|	TableOfGoods.SalesOrder        AS SalesOrder,
	|	TableOfGoods.Count          AS Count,
	|	TableOfGoods.QuantityByGBRN    AS QuantityByGBRN,
	|	TableOfGoods.Sum               AS Sum,
	|	TableOfGoods.Warehouse               AS Warehouse,
	|	TRUE                             AS SelectTypesOfStocks,
	|	UNDEFINED                       AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CCDNumber            AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.DocumentInflow        AS DocumentInflow,
	|	TableTypesOfStocks_.SalesOrder               AS SalesOrder,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END                                         AS QuantityByGBRN,
	|	TableTypesOfStocks_.Sum                      AS Sum
	|
	|INTO InitialTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	UNDEFINED                                  AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products                        AS Products,
	|	Dimension.Characteristic                      AS Characteristic,
	|	Dimension.Series                               AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.DocumentInflow        AS DocumentInflow,
	|	TableTypesOfStocks_.SalesOrder               AS SalesOrder,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	TableTypesOfStocks_.Sum                      AS Sum,
	|	VALUE(Catalog.Warehouses.EmptyRef)      AS OriginWarehouse,
	|	Dimension.StorageLocation                       AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually                    AS InventoryOwnerAttributesAreSpecifiedManually
	|
	|INTO TableTypesOfStocks_
	|FROM
	|	InitialTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	Query.TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
	 Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		CurrentOperation = BusinessOperation;
	Else
		CurrentOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale;
	EndIf;
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("Date",						Date);
	Query.SetParameter("Partner",					Partner);
	Query.SetParameter("Warehouse",						Warehouse);
	Query.SetParameter("Counterparty",					Counterparty);
	Query.SetParameter("Terms",					Terms);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Department",				Department);
	Query.SetParameter("BusinessOperation",		CurrentOperation);
	Query.SetParameter("Manager",					Manager);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("TableOfGoods",				TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",			InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",	InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsQuantityByGBRN_",
		"TableOfGoods",
		"QuantityByGBRN",
		"TableOfGoods.QuantityByGBRN",
		"0");
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumber_",
		"TableOfGoods",
		"CCDNumber",
		"TableOfGoods.CCDNumber",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

// Creates a temporary table of the goods with the dimension of the separate account.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table manager.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query                         = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes                  AS ItemsLocationAttributes,
	|	TableOfGoods.Products                                AS Products,
	|	TableOfGoods.Characteristic                              AS Characteristic,
	|	TableOfGoods.Purpose                                  AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                                      AS Series,
	|	TableOfGoods.Count                                  AS Count,
	|	DocumentDataTable.Partner                             AS Partner,
	|	DocumentDataTable.Terms                          AS Terms,
	|	DocumentDataTable.Department                       AS Department,
	|	TableOfGoods.Warehouse                                       AS Warehouse,
	|	DocumentDataTable.Manager                            AS Manager,
	|	DocumentDataTable.SalesOpportunity                              AS SalesOpportunity,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation
	|
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON (TRUE)";
	
	Query.Execute();
	
EndProcedure

// Fills in the default purchase terms in the document for shipping goods from storage.
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//	Operation        - Undefined, EnumRef.BusinessTransactions - 
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True, Operation = Undefined) Export
	
	If ValueIsFilled(Terms) Then
		Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
	EndIf;
	
	If ValueIsFilled(Partner) Then
		If Operation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		 Or Operation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			DefaultPurchasingConditions = Undefined;
		Else
			FilterParameters = New Structure;
			FilterParameters.Insert("OnlyValid",                       True);
			FilterParameters.Insert("ConsiderWarehouseGroups",                  True);
			FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
			FilterParameters.Insert("SelectedAgreement",                     Terms);
			FilterParameters.Insert("BusinessTransactions", Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
		
			DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, FilterParameters);
		EndIf;
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				TheCounterpartyPriorToTheChange = Counterparty;
				
				If RecalculatePrices_
					And ValueIsFilled(Terms) Then
					
					FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
					FillParameters.Insert("PopulationFields", "Price");
					FillParameters.Insert("Date",           Date);
					FillParameters.Insert("Currency",         Currency);
					FillParameters.Insert("Terms",     Terms);
					
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					
					PricesAreFilledOut = PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
					
				EndIf;
				
			Else
				Terms = DefaultPurchasingConditions.Terms;
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			EndIf;
			
		Else
			Terms = Undefined;
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			?(TheCounterpartyPriorToTheChange = Counterparty, CounterpartyBankAccount, Undefined));
		
	EndIf;
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills in the terms of purchase under the agreement in the document of shipment of goods from storage.
//
Procedure FillInTermsOfPurchaseUnderAgreement(RecalculatePrices_ = True) Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
	FillInTermsOfPurchase(PurchaseConditions);
	
	If RecalculatePrices_
		And ValueIsFilled(Terms) Then
		
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price");
		FillParameters.Insert("Date",           Date);
		FillParameters.Insert("Currency",         Currency);
		FillParameters.Insert("Terms",     Terms);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		
		PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
		
	EndIf;
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
EndProcedure

// Fills in the purchase conditions in the document for shipment of goods from storage according to the specified parameters.
//
// Parameters:
//	PurchaseConditions - Structure - structure for filling in the document details.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency                  = PurchaseConditions.Currency;
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Organization)
		And PurchaseConditions.Organization <> Organization Then
		
		Organization         = PurchaseConditions.Organization;
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
		
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If ValueIsFilled(PurchaseConditions.Counterparty)
		And PurchaseConditions.Counterparty <> Counterparty Then
		
		Counterparty = PurchaseConditions.Counterparty;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Warehouse                   = PurchaseConditions.Warehouse;
		StructureOfResponsible = PurchasesServer.GetWarehouseManager(Warehouse, Manager);
		
		If StructureOfResponsible <> Undefined Then
			IssuiedBy          = StructureOfResponsible.EmployeeResponsible;
			IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	ContractBusinessTransaction = PurchaseConditions.BusinessOperation;
	
	If PurchaseConditions.ContractsAreUsed <> Undefined
		And PurchaseConditions.ContractsAreUsed Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Currency;
		Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount,
			CounterpartyBankAccount);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns the sum of the document.
//
// Returns:
//	Number - the amount of the document.
//
Function GetDocumentAmount() Export
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Sum        AS Sum
	|
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0) AS Sum
	|FROM
	|	Goods AS Goods";
	
	Query.SetParameter("Goods", Goods.Unload(, "Products, Sum"));
	
	Upload0   = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].Sum;
	
	Return TotalAmount__;
	
EndFunction

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.GoodsShipmentFromStorage - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.GoodsShipmentFromStorage.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("Basis")
				And TypeOf(FillingData.Basis) = Type("DocumentRef.GoodsQualityControlCertificate") Then
			FillInCertificateOfQualityControl(FillingData);
		ElsIf FillingData.Property("DiscrepancyCertificate")
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.GoodsShipmentFromStorage") Then
				If FillingData.Property("Patch") Then
					DocumentCorrection.FillInCorrection(ThisObject, FillingData.BasisOfAct);
					CorrectionCorrectionOfDocumentOnBasisOfActOnDiscrepanciesInShipmentOfGoodsFromStorage(FillingData);
				Else
					FillOutOnBasisOfActOnDiscrepanciesInShipmentOfGoodsFromStorage(FillingData);
				EndIf;
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.GoodsReceiptForStorage") Then
				FillOutOnBasisOfActOnDiscrepanciesInAcceptanceOfGoodsForStorage(FillingData);
			EndIf;
			
		ElsIf FillingData.Property("DocumentBasis") Then
			
			TypeBase = TypeOf(FillingData.DocumentBasis);
			
			If TypeBase = Type("Array") Then
				
				If TypeOf(FillingData.DocumentBasis[0]) = Type("DocumentRef.SalesOrder") Then
					
					FillInDocumentOnClientSOrder(FillingData);
				ElsIf TypeOf(FillingData.DocumentBasis[0]) = Type("DocumentRef.MaterialProviderOrder2_5") Then
					
					HeaderAttributes = Undefined;
					FillingData.Property("HeaderAttributes", HeaderAttributes);
					
					FillPropertyValues(ThisObject, HeaderAttributes);
					If Not HeaderAttributes.Property("Currency") Then
						HeaderAttributes.Property("ARAPCurrency", Currency);
					EndIf;
					
					OriginWarehouse = Undefined;
					FillingData.Property("OriginWarehouse", OriginWarehouse);
					
					DesignParameters = Undefined;
					FillingData.Property("DesignParameters", DesignParameters);
					
					FillParameters = ?(ValueIsFilled(DesignParameters),
												New Structure("DesignParameters", DesignParameters),
												Undefined);
					
					SelectionData_ = New Structure("Ref, Partner, Counterparty, Contract, Organization, Currency, SalesOpportunity,
												   |LineOfBusiness");
					
					FillPropertyValues(SelectionData_, ThisObject);
					
					If HeaderAttributes.Property("GoodsShipment")
					   And ValueIsFilled(HeaderAttributes.GoodsShipment) Then
						SelectionData_.Insert("GoodsShipment", HeaderAttributes.GoodsShipment);
					EndIf;
					
					Documents.GoodsShipmentFromStorage.FillByOrderBalances(
						SelectionData_, Goods, OriginWarehouse, FillingData.DocumentBasis, FillParameters);
					
					If GetFunctionalOption("UseMaterialProviderOrder2_5") Then
					
						Orders = New Array;
						CommonClientServer.SupplementArray(Orders, Goods.UnloadColumn("SalesOrder"), True);
						
						OrdersCount = Orders.Count();
						
						ByOrder = OrdersCount > 0;
						If OrdersCount = 1 Then
							Basis = Orders[0];
						EndIf;
					
					EndIf;
				EndIf;
			ElsIf TypeBase = Type("DocumentRef.MaterialProviderOrder2_5") Then
				
				FillInBasedOnGiverSOrder2_5(FillingData);
			EndIf;
			
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.GoodsReceiptForStorage") Then
		FillInDocumentOnBasisOfAcceptanceOfGoodsForStorage(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Then
		FillInDocumentOnClientSOrder(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		FillInDocumentBasedOnReportToGiver2_5(FillingData);	
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	EndIf;
	
	FillOutBankAccounts();
	
	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
	GoodsShipmentFromStorageLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	SeriesSpecificationParameters        = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.GoodsShipmentFromStorage);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel,
		NotCheckedAttributeArray);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel, True);
	If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		NotCheckedAttributeArray.Add("Currency");
		
		FoundRows = Goods.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
		If FoundRows.Count() > 0 Then
			
			ItemsTypes = Goods.UnloadColumn("Products");
			ItemsTypes = Common.ObjectsAttributeValue(ItemsTypes, "ItemsType");
			
			ErrorText = NStr("vi = 'Trong dòng %1 của danh sách ""Hàng hóa"" chưa điền trường ""Ấn định""';
							|ru = 'В строке %1 списка ""Товары"" не заполнено поле ""Назначение""';
							|en = 'The ""Assignment"" field in line %1 of the ""Goods"" list is not filled'; fa = 'The ""Assignment"" field in line %1 of the ""Goods"" list is not filled';
							|it = 'Nella stringa %1 dell''elenco ""Merci"" non è compilato il campo ""Assegnazione""';
							|pl = 'W wierszu %1 listy ""Towary"" nie jest wypełnione pole ""Przeznaczenie""';
							|tr = '""Ürünler"" liste%1 kutusundaki ""Hedef"" alanı doldurulmamış'");
			
			For Each TableRow In FoundRows Do
				
				If ItemsTypes[TableRow.Products] = Enums.ItemsTypes.ReusablePackage Then
					Continue;
				EndIf;
				
				Common.MessageToUser(
					StrTemplate(ErrorText, TableRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", TableRow.LineNumber, "Purpose"),,
					Cancel);
					
			EndDo;
			
		EndIf;
		
	EndIf;
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
		
		If ByOrder
			And Not ValueIsFilled(LineProducts_.SalesOrder) Then
			
			OrderPresentation = NStr("vi = 'Đơn hàng của khách';
									|ru = 'Заказ клиента';
									|en = 'Sales order'; fa = 'سفارش فروش';
									|it = 'Заказ клиента';
									|pl = 'Zamówienie klienta';
									|tr = 'Satış siparişi'");
			If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
				Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
				OrderPresentation = NStr("vi = 'Đơn hàng của bên đặt gia công';
										|ru = 'Заказ давальца';
										|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
										|it = 'Заказ давальца';
										|pl = 'Zamówienie dostawcy';
										|tr = 'Tedarikçi siparişi'");
			EndIf;
			ErrorText = NStr("vi = 'Chưa điền trường ""%OrderPresentation%"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""%OrderPresentation%"" в строке %LineNumber% списка ""Товары""';
							|en = 'The ""%OrderPresentation%"" field in line %LineNumber% of the ""Goods"" list is not filled'; fa = 'The ""%OrderPresentation%"" field in line %LineNumber% of the ""Goods"" list is not filled';
							|it = 'Не заполнено поле ""%OrderPresentation%"" в строке %LineNumber% списка ""Товары""';
							|pl = 'The ""%OrderPresentation%"" field in line %LineNumber% of the ""Goods"" list is not filled';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%OrderPresentation%"" alanı doldurulmamış'");
			ErrorText = StrReplace(ErrorText, "%OrderPresentation%", OrderPresentation);
			ErrorText = StrReplace(ErrorText, "%LineNumber%",         LineProducts_.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "SalesOrder"),
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	CheckConformityOfProductContract(Cancel);
	If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		SalesServer.CheckShipmentBan(Partner, Cancel);
	Else
		PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
		PurchasesServer.CheckCorrectnessOfReturnedProducts(ThisObject, Cancel);
	EndIf;
	GoodsShipmentFromStorageLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	DocumentAmount         = GetDocumentAmount();
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentFromStorage);
	
	RoundingParameters = Undefined;
	If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
	Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		RoundingParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		RoundingParameters.AdditionalFields.Insert("Warehouse", "Goods.Warehouse");
		RoundingParameters.ConditionForSelectingRowsByAdditionalFields =
			ProductionServer.ConditionForSelectingRowsForRounding("Goods", "Warehouse");
		
	EndIf;
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
	   And ByOrder And ValueIsFilled(Basis) Then
		
		For Each CurRow In Goods Do
			
			If Not ValueIsFilled(CurRow.SalesOrder) Then
				CurRow.SalesOrder = Basis;
			EndIf;
			
		EndDo;
	
	EndIf;
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	
	If IsNew()
		And Not ValueIsFilled(Number) Then
		
		SetNewNumber();
		
	EndIf;
	
	GoodsShipmentFromStorageLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	GoodsShipmentFromStorageLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	GoodsShipmentFromStorageLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	GoodsShipmentFromStorageLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);

	InventoryOwnerAttributesAreSpecifiedManually = False;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	For Each TSRow In Goods Do
		TSRow.RowID = "";
	EndDo;
	
	InitializeDocument();
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	GoodsShipmentFromStorageLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

#EndRegion

#Region Private

Procedure CheckConformityOfProductContract(Cancel)
	
	If BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		For Each LineProducts_ In Goods Do
			
			If ValueIsFilled(LineProducts_.Purpose) Then
				ContractOfGoods = Common.ObjectAttributeValue(LineProducts_.Purpose, "Contract");
				If Contract <> ContractOfGoods Then
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Hợp đồng chỉ định trong dòng %1 của danh sách ""Hàng hóa"" không khớp với hợp đồng chứng từ.';
							|ru = 'Договор назначения в строке %1 списка ""Товары"" не совпадает с договором документа.';
							|en = 'The assignment contract in line %1 of the ""Goods"" list does not match the document contract.'; fa = 'The assignment contract in line %1 of the ""Goods"" list does not match the document contract.';
							|it = 'Il contratto d''incarico nella riga %1 dell''elenco ""Merci"" non corrisponde al contratto del documento.';
							|pl = 'Umowa przeznaczenia w wierszu %1 listy ""Towary"" nie odpowiada umowie dokumentu.';
							|tr = '""Ürünler"" listesinin %1 satırındaki hedef sözleşme, belge sözleşmesiyle eşleşmiyor.'"),
						Goods.IndexOf(LineProducts_) + 1);
						
					Common.MessageToUser(
						Text,
						ThisObject,
						"Goods[" + Goods.IndexOf(LineProducts_) + "].Purpose",
						,
						Cancel);
				EndIf;
				
			EndIf;
				
		EndDo;
		
	EndIf;
	
EndProcedure

#Region InitializationAndFilling

Procedure FillOutOnBasisOfActOnDiscrepanciesInShipmentOfGoodsFromStorage(Val FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DiscrepancyReportFollowingShipment.Ref                             AS DiscrepancyCertificate,
	|	GoodsShipmentFromStorage.Ref                                  AS Ref,
	|	GoodsShipmentFromStorage.Partner                                 AS Partner,
	|	GoodsShipmentFromStorage.Counterparty                              AS Counterparty,
	|	GoodsShipmentFromStorage.Contract                                 AS Contract,
	|	GoodsShipmentFromStorage.Terms                              AS Terms,
	|	GoodsShipmentFromStorage.Organization                             AS Organization,
	|	GoodsShipmentFromStorage.Department                           AS Department,
	|	GoodsShipmentFromStorage.Warehouse                                   AS Warehouse,
	|	GoodsShipmentFromStorage.Director                            AS Director,
	|	GoodsShipmentFromStorage.ChiefAccountant                        AS ChiefAccountant,
	|	GoodsShipmentFromStorage.ContactPerson                          AS ContactPerson,
	|	GoodsShipmentFromStorage.CompanyBankAccount               AS CompanyBankAccount,
	|	GoodsShipmentFromStorage.CounterpartyBankAccount               AS CounterpartyBankAccount,
	|	GoodsShipmentFromStorage.BusinessOperation                   AS BusinessOperation,
	|	GoodsShipmentFromStorage.SalesOpportunity                                  AS SalesOpportunity,
	|	GoodsShipmentFromStorage.Currency                                  AS Currency,
	|	NOT GoodsShipmentFromStorage.Posted                             AS ThereAreErrorsPosted,
	|	NOT DiscrepancyReportFollowingShipment.Posted                        AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingShipment.Status                             AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingShipment.Status IN (
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion)) AS ThereAreErrorsStatusReport
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|		INNER JOIN Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|		ON (TRUE)
	|WHERE
	|	GoodsShipmentFromStorage.Ref        = &DocumentBasisCorrectionOfBasis
	|	AND DiscrepancyReportFollowingShipment.Ref = &DiscrepancyCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products                          AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic                        AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose                            AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder                          AS SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode                             AS RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package                              AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series                                 AS Series,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument -
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages)               AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument -
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Count)                       AS Count,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price                                  AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse                                 AS Warehouse,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument -
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum)                            AS Sum,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow                   AS DocumentInflow
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(
	|		Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND (CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument -
	|		CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages) > 0
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow
	|
	|ORDER BY
	|	MAX(CertificateOfDiscrepanciesAfterShipmentOfGoods.LineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products                  AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic                AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose                    AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series                         AS Series,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument -
	|		DiscrepancyReportFollowingShipmentSetOfSeries.Count)               AS Count,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse                         AS Warehouse
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Action = VALUE(
	|		Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument - DiscrepancyReportFollowingShipmentSetOfSeries.Count > 0
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse";
	
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	
	// Filling in the act if there is a correction of the grounds of the act.
	If FillingData.Property("CorrectionOfBasis") And ValueIsFilled(FillingData.CorrectionOfBasis) Then
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.CorrectionOfBasis);
	Else
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.BasisOfAct);
	EndIf;
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection  = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	// According to the document of shipment of goods from storage.
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.Ref, Undefined,
		HeaderSelection.ThereAreErrorsPosted);
	
	// According to the act of discrepancies after shipment.
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.DiscrepancyCertificate,
		HeaderSelection.StatusOfDivergenceReport,
		HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		HeaderSelection.ThereAreErrorsStatusReport,
		DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn());
	
	AdditionalReturnWithinGoodsReturn = FillingData.BasisOfAct;
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = QueryBatch[1].Unload();
	
	ArrayOfCustomerOrders = New Array();
	
	For Each CurRow In TableOfGoods Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		NewRow.Sum = NewRow.Price * NewRow.NumberOfPackages;
		If Not ValueIsFilled(NewRow.SalesOrder) Then
			Continue;
		EndIf;
		If ArrayOfCustomerOrders.Find(NewRow.SalesOrder) = Undefined Then
			ArrayOfCustomerOrders.Add(NewRow.SalesOrder);
		EndIf;
	EndDo;
	
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	If ArrayOfCustomerOrders.Count() = 1 Then
		ByOrder = True;
		Basis = ArrayOfCustomerOrders[0];
	ElsIf ArrayOfCustomerOrders.Count() > 1 Then
		ByOrder = True;
	EndIf;
	
EndProcedure

Procedure CorrectionCorrectionOfDocumentOnBasisOfActOnDiscrepanciesInShipmentOfGoodsFromStorage(Val FillingData)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsOfAct.RowCode             AS RowCode,
	|	ProductsOfAct.FilledInBySale AS FilledInBySale,
	|	ProductsOfAct.Products          AS Products,
	|	ProductsOfAct.Characteristic        AS Characteristic,
	|	ProductsOfAct.Purpose            AS Purpose,
	|	ProductsOfAct.SalesOrder          AS SalesOrder,
	|	ProductsOfAct.Package              AS Package,
	|	ProductsOfAct.Series                 AS Series,
	|	ProductsOfAct.Price                  AS Price,
	|	ProductsOfAct.Warehouse                 AS Warehouse,
	|	CASE
	|		WHEN ProductsOfAct.DocumentInflow = UNDEFINED
	|				OR ProductsOfAct.DocumentInflow REFS Document.VendorInvoice
	|			THEN VALUE(Document.GoodsReceiptForStorage.EmptyRef)
	|		ELSE ProductsOfAct.DocumentInflow
	|	END                     AS DocumentInflow,
	|	ProductsOfAct.Count     AS Count,
	|	ProductsOfAct.Sum          AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS ProductsOfAct
	|WHERE
	|	ProductsOfAct.Ref = &DiscrepancyCertificate
	|	AND ProductsOfAct.SaleOfGoodsAndServices = &DocumentBasis
	|	AND ProductsOfAct.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|	AND ProductsOfAct.Count > 0
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActSeries.LineNumber    AS LineNumber,
	|	ActSeries.Products   AS Products,
	|	ActSeries.Characteristic AS Characteristic,
	|	ActSeries.Purpose     AS Purpose,
	|	ActSeries.Series          AS Series,
	|	ActSeries.Warehouse          AS Warehouse,
	|	ActSeries.Count     AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS ActSeries
	|WHERE
	|	ActSeries.Ref = &DiscrepancyCertificate
	|	AND ActSeries.SaleOfGoodsAndServices = &DocumentBasis
	|	AND ActSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|	AND ActSeries.Count > 0
	|	AND NOT (NOT ActSeries.FilledInBySale
	|		AND ActSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef))";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TableOfItemsOfReport = QueryBatch[0].Unload();
	ActSeriesTable  = QueryBatch[1].Unload();
	
	GoodsTable = Goods.Unload();
	SeriesTable  = SetOfSeries.Unload();
	
	// Re-filling of products and series according to the act
	SelectionColumns =
		"Warehouse,
		|Products,
		|Characteristic,
		|Purpose,
		|Series";
	If BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale Then
		AdditionalColumns = "RowCode, DocumentInflow";
	ElsIf BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		And ByOrder Then
		AdditionalColumns = "RowCode, SalesOrder";
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		And ByOrder Then
		AdditionalColumns = "RowCode, SalesOrder";
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		AdditionalColumns = "RowCode, DocumentInflow";
	EndIf;
	SelectionColumns = SelectionColumns + "," + AdditionalColumns;
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In TableOfItemsOfReport Do
		
		If CurRow.FilledInBySale Then
			FillPropertyValues(FilterParameters, CurRow);
			FoundRows = GoodsTable.FindRows(FilterParameters);
			If FoundRows.Count() > 0 Then
				FoundRow = FoundRows[0];
				FoundRow.Count = CurRow.Count;
				FoundRow.Sum      = CurRow.Sum;
			Else
				NewRow = GoodsTable.Add();
				FillPropertyValues(NewRow, CurRow);
			EndIf;
		Else // to add lines from the over-order report
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	SelectionColumns =
		"LineNumber,
		|Products,
		|Characteristic,
		|Purpose,
		|Series,
		|Warehouse";
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In ActSeriesTable Do
		
		FillPropertyValues(FilterParameters, CurRow);
		
		FoundRows = SeriesTable.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then
			
			For Each FoundRow In FoundRows Do
				
				If FoundRow.Count = CurRow.Count Then
					Continue;
				EndIf;
				
				If FoundRow.Count > CurRow.Count Then
					FoundRow.Count = CurRow.Count;
				Else
					NewRow = SeriesTable.Add();
					FillPropertyValues(NewRow, FoundRow);
					NewRow.Count = CurRow.Count - FoundRow.Count;
				EndIf;
				
			EndDo;
			
		Else // to add lines from the act in addition to the order
			NewRow = SeriesTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	Goods.Load(GoodsTable);
	SetOfSeries.Load(SeriesTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillOutOnBasisOfActOnDiscrepanciesInAcceptanceOfGoodsForStorage(Val FillingData)
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Ref                              AS DiscrepancyCertificate,
	|	DiscrepancyReportFollowingReceipt.Partner                             AS Partner,
	|	DiscrepancyReportFollowingReceipt.Counterparty                          AS Counterparty,
	|	DiscrepancyReportFollowingReceipt.Terms                          AS Terms,
	|	DiscrepancyReportFollowingReceipt.Contract                             AS Contract,
	|	DiscrepancyReportFollowingReceipt.Organization                         AS Organization,
	|	DiscrepancyReportFollowingReceipt.Department                       AS Department,
	|	&Warehouse                                                           AS Warehouse,
	|	&DiscrepancyCertificate                                                AS Basis,
	|	DiscrepancyReportFollowingReceipt.Director                        AS Director,
	|	DiscrepancyReportFollowingReceipt.ChiefAccountant                    AS ChiefAccountant,
	|	DiscrepancyReportFollowingReceipt.BusinessOperation               AS BusinessOperation,
	|	DiscrepancyReportFollowingReceipt.Currency                              AS Currency,
	|	DiscrepancyReportFollowingReceipt.Manager                            AS Manager,
	|	NOT DiscrepancyReportFollowingReceipt.Posted                         AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.Status                              AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingReceipt.Status IN (
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion)) AS ThereAreErrorsStatusReport
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products                       AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic                     AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package                           AS Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose                         AS Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series                              AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price                               AS Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse                              AS Warehouse,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages -
	|		CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count -
	|		CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument)         AS Count,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum -
	|		CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument)              AS Sum,
	|	&DocumentBasisCorrectionOfBasis                                AS DocumentInflow
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(
	|		Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse = &Warehouse
	|	AND (CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages -
	|		CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) > 0
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse
	|
	|ORDER BY
	|	MAX(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products               AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic             AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose                 AS Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series                      AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse                      AS Warehouse,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.Count -
	|		DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Action = VALUE(
	|		Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse = &Warehouse
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Count - DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument > 0
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse";
	
	Query.SetParameter("Warehouse",            FillingData.Warehouse);
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	
	// Filling in the act if there is a correction of the grounds of the act.
	If FillingData.Property("CorrectionOfBasis") And ValueIsFilled(FillingData.CorrectionOfBasis) Then
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.CorrectionOfBasis);
	Else
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.BasisOfAct);
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection  = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	// According to the act of discrepancies after acceptance.
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.DiscrepancyCertificate,
		HeaderSelection.StatusOfDivergenceReport,
		HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		HeaderSelection.ThereAreErrorsStatusReport,
		DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn());
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	BusinessOperation     = PurchasesServer.GetRefundTransactionOnReceipt(
		HeaderSelection.BusinessOperation);
	
	TableOfGoods = QueryBatch[1].Unload();
	
	For Each CurRow In TableOfGoods Do
		NewRow = Goods.Add();
		
		FillPropertyValues(NewRow,CurRow);
		
		NewRow.Sum = NewRow.Price * NewRow.NumberOfPackages;
		
	EndDo;
	
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentFromStorage);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
EndProcedure

Procedure FillInCertificateOfQualityControl(Val FillingData)
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Documents.GoodsQualityControlCertificate.GoodsToCreateBasedOn(
		Query,
		FillingData.Basis,
		FillingData.Warehouse,
		Enums.ActionsOnGoodsInQualityControlCertificate.RegisterReturn);
	
	Query.SetParameter("Ref", FillingData.Basis);
	Query.Text =
		"SELECT
		|	Attributes.ControlledLotReference.Organization AS Organization,
		|	Attributes.ControlledLotReference.Partner AS Partner,
		|	Attributes.ControlledLotReference.Counterparty AS Counterparty,
		|	Attributes.ControlledLotReference.Lot AS Lot,
		|	Attributes.ControlledLotReference.BusinessOperation AS BusinessOperation,
		|	Attributes.ControlledLotReference.Contract AS Contract,
		|	Attributes.ControlledLotReference.LineOfBusiness AS LineOfBusiness,
		|	Attributes.ControlledLotReference.Department AS Department,
		|	Attributes.Status AS Status
		|INTO ActHeader
		|FROM
		|	Document.GoodsQualityControlCertificate AS Attributes
		|WHERE
		|	Attributes.Ref = &Ref
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	*
		|FROM
		|	ActHeader
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Attributes.Organization AS Organization,
		|	Attributes.Partner AS Partner,
		|	Attributes.Lot AS Lot,
		|	Attributes.Counterparty AS Counterparty,
		|	Attributes.Contract AS Contract,
		|	Attributes.Department AS Department,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	&Warehouse AS Warehouse,
		|	GoodsReceiptForStorage.Ref AS DocumentInflow,
		|	GoodsReceiptForStorage.Terms AS Terms,
		|	GoodsReceiptForStorage.Manager AS Manager,
		|	GoodsReceiptForStorage.ChiefAccountant AS ChiefAccountant,
		|	GoodsReceiptForStorage.CompanyBankAccount AS CompanyBankAccount,
		|	GoodsReceiptForStorage.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	GoodsReceiptForStorage.SalesOpportunity AS SalesOpportunity,
		|	GoodsReceiptForStorage.Director AS Director
		|INTO Header
		|FROM
		|	ActHeader AS Attributes
		|		LEFT JOIN Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
		|		ON GoodsReceiptForStorage.Ref = Attributes.Lot
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Attributes.Organization AS Organization,
		|	Attributes.Partner AS Partner,
		|	Attributes.Lot AS Lot,
		|	Attributes.Counterparty AS Counterparty,
		|	Attributes.Contract AS Contract,
		|	Attributes.Department AS Department,
		|	Attributes.Warehouse AS Warehouse,
		|	Attributes.Terms AS Terms,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	Attributes.Manager AS Manager,
		|	Attributes.ChiefAccountant AS ChiefAccountant,
		|	Attributes.CompanyBankAccount AS CompanyBankAccount,
		|	Attributes.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	Attributes.SalesOpportunity AS SalesOpportunity,
		|	Attributes.Director AS Director
		|FROM
		|	Header AS Attributes
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Warehouse AS Warehouse,
		|	MAX(Attributes.DocumentInflow) AS DocumentInflow,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus IN(10,14)
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	Goods.Package AS Package,
		|	SUM(Goods.Count) AS Count,
		|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN Header AS Attributes
		|		ON TRUE
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Warehouse,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus IN(10,14)
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END,
		|	Goods.Package
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Goods.Warehouse AS Warehouse,
		|	SUM(Goods.Count) AS Count
		|FROM
		|	Goods AS Goods
		|WHERE
		|	NOT Goods.BatchesIndicationStatus IN(10,14)
		|	AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND NOT (Goods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|		AND &DocumentDate <= Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue)
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Series,
		|	Goods.Warehouse";
	
	SetPrivilegedMode(True);
	
	ResultsPackage = Query.ExecuteBatch();
	AttributesOfReport = ResultsPackage[1].Select();
	AttributesOfReport.Next();
	HeaderAttributes = ResultsPackage[3].Select();
	HeaderAttributes.Next();
	QualityControl.RaiseExceptionWhenCreatingBasedOnAct(AttributesOfReport);
	BaseGoods = ResultsPackage[4].Unload();
	BaseSeries = ResultsPackage[5].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa với thao tác ""Lập chứng từ trả lại"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Документ %Document% не содержит товаров c действием ""Оформить возврат"". Ввод на основании документа запрещен.';
						|en = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.'; fa = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.';
						|it = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.';
						|pl = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.';
						|tr = '""%Document%"" belgesi ""İade düzenle"" işlemine sahip ürün içermemektedir. Belgeye dayanarak giriş yapılması yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		Raise ErrorText;
	EndIf;
	
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(AttributesOfReport.BusinessOperation);
	AllDocumentOperationsOfOperations = New ValueList();
	Documents.GoodsShipmentFromStorage.FillInListOfBusinessOperations(AllDocumentOperationsOfOperations);
	
	If AllDocumentOperationsOfOperations.FindByValue(BusinessOperation) = Undefined Then
		ErrorText = NStr("vi = 'Đối với nghiệp vụ ""%1"" mà theo đó đã nhập hàng, không đề xuất tạo chứng từ ""Xuất hàng từ kho bảo quản"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Для операции ""%1"", по которой поступил товар, не предполагается создание документа ""Отгрузка товаров с хранения"". Ввод на основании документа запрещен.';
						|en = 'Cannot create a ""VMI pick-up requests from vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.'; fa = 'Cannot create a ""VMI pick-up requests from vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
						|it = 'Cannot create a ""VMI pick-up requests from vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
						|pl = 'Cannot create a ""VMI pick-up requests from vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
						|tr = 'Ürünün girişinin yapıldığı ""%1"" işlemi için ""Depodan ürün sevkiyatı"" belgesi oluşturulması öngörülmemiştir. Belgeye dayanarak giriş yapılması yasaktır.'");
		ErrorText = StrTemplate(ErrorText, AttributesOfReport.BusinessOperation);
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, HeaderAttributes,
		"Organization,
		|Partner,
		|Counterparty,
		|Contract,
		|Department,
		|Warehouse,
		|Terms,
		|LineOfBusiness,
		|Manager,
		|ChiefAccountant,
		|CompanyBankAccount,
		|CounterpartyBankAccount,
		|SalesOpportunity,
		|Director");
	
	DocumentBasis = FillingData.Basis;
	If TypeOf(HeaderAttributes.Lot) <> Type("CatalogRef.CounterpartyContracts")
			And TypeOf(HeaderAttributes.Lot) <> Type("DocumentRef.RequestForGoodsQualityControl") Then
		Currency = Common.ObjectAttributeValue(HeaderAttributes.Lot, "Currency");
	EndIf;
	Goods.Load(BaseGoods);
	SetOfSeries.Load(BaseSeries);
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentFromStorage);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, BaseStructure);
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceOfGoodsForStorage(Val FillingData)
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	GoodsReceiptForStorage.Ref                    AS DocumentBasis,
	|	GoodsReceiptForStorage.Partner                   AS Partner,
	|	GoodsReceiptForStorage.Counterparty                AS Counterparty,
	|	GoodsReceiptForStorage.Terms                AS Terms,
	|	GoodsReceiptForStorage.Contract                   AS Contract,
	|	GoodsReceiptForStorage.Organization               AS Organization,
	|	GoodsReceiptForStorage.Department             AS Department,
	|	GoodsReceiptForStorage.Warehouse                     AS Warehouse,
	|	GoodsReceiptForStorage.Director              AS Director,
	|	GoodsReceiptForStorage.ChiefAccountant          AS ChiefAccountant,
	|	GoodsReceiptForStorage.BusinessOperation     AS BusinessOperation,
	|	GoodsReceiptForStorage.Currency                    AS Currency,
	|	GoodsReceiptForStorage.DocumentAmount            AS DocumentAmount,
	|	GoodsReceiptForStorage.Manager                  AS Manager,
	|	GoodsReceiptForStorage.SalesOpportunity                    AS SalesOpportunity,
	|	GoodsReceiptForStorage.LineOfBusiness   AS LineOfBusiness,
	|	GoodsReceiptForStorage.CompanyBankAccount AS CompanyBankAccount,
	|	GoodsReceiptForStorage.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	NOT GoodsReceiptForStorage.Posted               AS ThereAreErrorsPosted
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|WHERE
	|	GoodsReceiptForStorage.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsTable.RowCode 					AS RowCode,
	|	GoodsTable.PartnerProducts 		AS PartnerProducts,
	|	GoodsTable.Products 					AS Products,
	|	GoodsTable.Products.ItemsType 	AS ItemsType,
	|	GoodsTable.Characteristic 				AS Characteristic,
	|	GoodsTable.Package 						AS Package,
	|	GoodsTable.Purpose 					AS Purpose,
	|	GoodsTable.Series 						AS Series,
	|	GoodsTable.BatchesIndicationStatus 			AS BatchesIndicationStatus,
	|	GoodsTable.NumberOfPackages 			AS NumberOfPackages,
	|	GoodsTable.Count 					AS Count,
	|	GoodsTable.Price							AS Price,
	|	GoodsTable.Sum							AS Sum,
	|	GoodsTable.Warehouse 						AS Warehouse,
	|	GoodsTable.LineNumber 					AS LineNumber
	|INTO GoodsOfAcceptanceDocument
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsOfAcceptanceDocument.PartnerProducts 	AS PartnerProducts,
	|	GoodsOfAcceptanceDocument.Products 			AS Products,
	|	GoodsOfAcceptanceDocument.ItemsType 			AS ItemsType,
	|	GoodsOfAcceptanceDocument.Characteristic 			AS Characteristic,
	|	GoodsOfAcceptanceDocument.Package 				AS Package,
	|	GoodsOfAcceptanceDocument.Purpose 				AS Purpose,
	|	GoodsOfAcceptanceDocument.Series 					AS Series,
	|	GoodsOfAcceptanceDocument.BatchesIndicationStatus 		AS BatchesIndicationStatus,
	|	GoodsOfAcceptanceDocument.NumberOfPackages 		AS NumberOfPackages,
	|	GoodsOfAcceptanceDocument.Count 				AS Count,
	|	GoodsOfAcceptanceDocument.Price 					AS Price,
	|	GoodsOfAcceptanceDocument.Sum 					AS Sum,
	|	GoodsOfAcceptanceDocument.Warehouse 					AS Warehouse,
	|	&DocumentBasis 								AS DocumentInflow
	|FROM
	|	GoodsOfAcceptanceDocument AS GoodsOfAcceptanceDocument
	|
	|ORDER BY
	|	GoodsOfAcceptanceDocument.LineNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	SeriesTable.Products               AS Products,
	|	SeriesTable.Characteristic             AS Characteristic,
	|	SeriesTable.Purpose                 AS Purpose,
	|	SeriesTable.Series                      AS Series,
	|	SeriesTable.Warehouse                      AS Warehouse,
	|	SUM(SeriesTable.Count)          AS Count
	|FROM
	|	Document.GoodsReceiptForStorage.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &DocumentBasis
	|
	|GROUP BY
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Warehouse";
	
	Query.SetParameter("DocumentBasis", FillingData);
	
	SetPrivilegedMode(True);
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection  = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(FillingData, Undefined,
		HeaderSelection.ThereAreErrorsPosted);
	FillPropertyValues(ThisObject, HeaderSelection);
	
	BusinessOperation     = PurchasesServer.GetRefundTransactionOnReceipt(
		HeaderSelection.BusinessOperation);
	
	// Splitting lines, filling in series with status 10.
	RowIndexes   = New Array();
	TableOfGoods = QueryBatch[2].Unload(); // ValueTable
	BaseSeries = QueryBatch[3].Unload();
	
	For Each LineProducts_ In TableOfGoods Do
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, TableOfGoods.IndexOf(LineProducts_));
		EndIf;
	EndDo;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentFromStorage);
	
	ArraySeriesCommunicationFields = New Array;
	ArraySeriesCommunicationFields.Add("Products");
	ArraySeriesCommunicationFields.Add("Characteristic");
	
	CommonClientServer.SupplementArray(ArraySeriesCommunicationFields, SeriesSpecificationParameters.LinkFields);
	SeriesCommunicationFieldsString = StrConcat(ArraySeriesCommunicationFields, ",");
	
	If RowIndexes.Count() > 0 Then
		InvoicesServer.MoveSeriesFromTableToRows(TableOfGoods, RowIndexes, BaseSeries, SeriesCommunicationFieldsString);
	EndIf;
	
	ArraySeriesCommunicationFields.Add("BatchesIndicationStatus");
	FieldsForUnloadingGoodsBySeries = StrConcat(ArraySeriesCommunicationFields, ",");
	
	TableOfProductsBySeries = TableOfGoods.Copy(,FieldsForUnloadingGoodsBySeries);
	TableOfProductsBySeries.GroupBy(FieldsForUnloadingGoodsBySeries);
	
	For Each RowOfGoods In TableOfProductsBySeries Do
		If ProductsClientServer.ThisSeriesStatusIndicatesWHSeries(RowOfGoods.BatchesIndicationStatus, SeriesSpecificationParameters) Then
			
			RowFilter = New Structure(SeriesCommunicationFieldsString);
			FillPropertyValues(RowFilter, RowOfGoods);
			
			SeriesLines_ = BaseSeries.FindRows(RowFilter);
			
			For Each SeriesString In SeriesLines_ Do				
				NewRow = SetOfSeries.Add();
				FillPropertyValues(NewRow, SeriesString);
			EndDo;
			
		EndIf;
	EndDo;
	
	For Each CurRow In TableOfGoods Do
		NewRow = Goods.Add();
		
		FillPropertyValues(NewRow, CurRow);
		NewRow.Sum = NewRow.Price * NewRow.NumberOfPackages;
	EndDo;
	
	If GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments")
		And Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments") Then
		
		WarehouseArray = TMCommonUse.DeleteDuplicateElementsFromArray(Goods.UnloadColumn("Warehouse"));
		
		If WarehouseArray.Count() = 1 Then
			Warehouse = WarehouseArray[0];
		Else
			Warehouse = Catalogs.Warehouses.EmptyRef();
		EndIf;
		
	EndIf;
	
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
EndProcedure
Procedure FillInBasedOnGiverSOrder2_5(FillingData)
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &DocumentBasis";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = "ReferenceOrder, RowCode";
	TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
	
	TT_ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query = New Query;
	Query.Text =
	TT_ShipmentOrdersTurnoverExpanded
	+ Common.QueryBatchSeparator()
	+ "
	|SELECT
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|			THEN MaterialProviderOrder2_5.Ref
	|		ELSE UNDEFINED
	|	END                                             AS Basis,
	|	&ByOrder                                         AS ByOrder,
	|	MaterialProviderOrder2_5.Status                           AS DocumentStatus,
	|	MaterialProviderOrder2_5.Partner                          AS Partner,
	|	MaterialProviderOrder2_5.Counterparty                       AS Counterparty,
	|	MaterialProviderOrder2_5.Contract                          AS Contract,
	|	MaterialProviderOrder2_5.Organization                      AS Organization,
	|	MaterialProviderOrder2_5.Department                    AS Department,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|			THEN MaterialProviderOrder2_5.Warehouse
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5)
	|			THEN MaterialProviderOrder2_5.WarehouseForReceipt
	|	END                                             AS Warehouse,
	|	&BusinessOperation                            AS BusinessOperation,
	|	MaterialProviderOrder2_5.Currency                           AS Currency,
	|	MaterialProviderOrder2_5.Manager                         AS Manager,
	|	MaterialProviderOrder2_5.SalesOpportunity                           AS SalesOpportunity,
	|	MaterialProviderOrder2_5.LineOfBusiness          AS LineOfBusiness,
	|	MaterialProviderOrder2_5.BankAccount                   AS CompanyBankAccount,
	|	MaterialProviderOrder2_5.CounterpartyBankAccount        AS CounterpartyBankAccount,
	|	MaterialProviderOrder2_5.Director                     AS Director,
	|	MaterialProviderOrder2_5.ChiefAccountant                 AS ChiefAccountant,
	|	
	// Delivery. The beginning
	|	MaterialProviderOrder2_5.DeliveryAddress                    AS DeliveryAddress,
	|	MaterialProviderOrder2_5.DeliveryAddressFieldValues       AS DeliveryAddressFieldValues,
	|	MaterialProviderOrder2_5.DeliveryMethod                   AS DeliveryMethod,
	|	MaterialProviderOrder2_5.DeliveryZone                     AS DeliveryZone,
	|	MaterialProviderOrder2_5.CarrierPartner                AS CarrierPartner,
	|	MaterialProviderOrder2_5.DeliveryTimeFrom                   AS DeliveryTimeFrom,
	|	MaterialProviderOrder2_5.DeliveryTimeTo                  AS DeliveryTimeTo,
	|	MaterialProviderOrder2_5.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	MaterialProviderOrder2_5.SpecialTransportationConditions           AS SpecialTransportationConditions,
	|	MaterialProviderOrder2_5.SpecialTransportationConditionsDescription   AS SpecialTransportationConditionsDescription,
	// Delivery. Ending
	|	
	|	NOT MaterialProviderOrder2_5.Status IN (&AcceptableStatuses) AS ThereAreErrorsStatus,
	|	NOT MaterialProviderOrder2_5.Posted                      AS ThereAreErrorsPosted,
	|	&DocumentBasis                                AS DocumentBasis
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|WHERE
	|	MaterialProviderOrder2_5.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	GoodsTable.Products                 AS Products,
	|	ProductsTable.ItemsType        AS ItemsType,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	CASE
	|		WHEN ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE ManufacturedProduct.Ref.Purpose
	|	END                                      AS Purpose,
	|	GoodsTable.Series                        AS Series,
	|	ManufacturedProduct.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ISNULL(ManufacturedProduct.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) =
	|				VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.QuantityToBeShippedTurnover
	|				- GoodsTable.ShippedQuantityTurnover
	|		ELSE (GoodsTable.QuantityToBeShippedTurnover
	|				- GoodsTable.ShippedQuantityTurnover) / &QueryTextPackagingFactor
	|	END                                      AS NumberOfPackages,
	|	(GoodsTable.QuantityToBeShippedTurnover
	|		- GoodsTable.ShippedQuantityTurnover) AS Count,
	|	ISNULL(ManufacturedProduct.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	0                                          AS Price,
	|	0                                          AS Sum,
	|	GoodsTable.Warehouse                        AS Warehouse,
	|	GoodsTable.ReferenceOrder                 AS SalesOrder,
	|	GoodsTable.RowCode                    AS RowCode
	|FROM
	|	TT_ShipmentOrdersTurnoverExpanded AS GoodsTable
	|	
	|	INNER JOIN Catalog.Products AS ProductsTable
	|	ON GoodsTable.Products = ProductsTable.Ref
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS ManufacturedProduct
	|	ON GoodsTable.ReferenceOrder = ManufacturedProduct.Ref
	|	AND GoodsTable.RowCode     = ManufacturedProduct.RowCode
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|	AND ProductsTable.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (GoodsTable.QuantityToBeShippedTurnover
	|		- GoodsTable.ShippedQuantityTurnover) <> 0
	|	AND NOT &DocumentIsBasisOfFinishedProductBeingRepaired
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.PartnerProducts         AS PartnerProducts,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.Purpose                   AS Purpose,
	|	GoodsTable.Series                        AS Series,
	|	GoodsTable.BatchesIndicationStatus          AS BatchesIndicationStatus,
	|	GoodsTable.NumberOfPackages           AS NumberOfPackages,
	|	GoodsTable.Count                   AS Count,
	|	GoodsTable.Package                     AS Package,
	|	GoodsTable.Price                         AS Price,
	|	GoodsTable.Sum                        AS Sum,
	|	GoodsTable.Warehouse                        AS Warehouse,
	|	UNDEFINED                               AS SalesOrder,
	|	0                                          AS RowCode
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5)
	|	AND GoodsTable.Ref = &DocumentBasis
	|	AND GoodsTable.Action = VALUE(Enum.ActionsOnMaterialsToSubcontract.AcceptVMI)
	|	AND NOT GoodsTable.Canceled
	|	AND NOT &DocumentIsBasisOfFinishedProductBeingRepaired
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED                                                   AS PartnerProducts,
	|	GoodsTable.UnderRepairProduct                 AS Products,
	|	GoodsTable.UnderRepairProduct.ItemsType AS ItemsType,
	|	GoodsTable.UnderRepairVariant               AS Characteristic,
	|	GoodsTable.Contract.Purpose                               AS Purpose,
	|	GoodsTable.UnderRepairBatch                        AS Series,
	|	GoodsTable.UnderRepairBatchSpecificationStatus          AS BatchesIndicationStatus,
	|	1                                                              AS NumberOfPackages,
	|	1                                                              AS Count,
	|	UNDEFINED                                                   AS Package,
	|	0                                                              AS Price,
	|	0                                                              AS Sum,
	|	GoodsTable.WarehouseForReceipt                                 AS Warehouse,
	|	UNDEFINED                                                   AS SalesOrder,
	|	0                                                              AS RowCode
	|FROM
	|	Document.MaterialProviderOrder2_5 AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5)
	|	AND GoodsTable.Ref = &DocumentBasis
	|	AND &DocumentIsBasisOfFinishedProductBeingRepaired
	|
	|ORDER BY
	|	RowCode,
	|	Products
	|";
	
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ManufacturedProduct.Package", "ManufacturedProduct.Products"));
	
	Query.SetParameter("DocumentBasis",     FillingData.DocumentBasis);
	Query.SetParameter("BusinessOperation", FillingData.BusinessOperation);
	
	CustomFlag =
		FillingData.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		And GetFunctionalOption("UseMaterialProviderOrder2_5");
	Query.SetParameter("ByOrder",              CustomFlag);
	
	AcceptableStatuses =
		Documents.MaterialProviderOrder2_5.ValidInputStatusesBasedOn(
			Metadata().Name,
			FillingData.BusinessOperation);
	
	Query.SetParameter("AcceptableStatuses", AcceptableStatuses);
	
	DocumentIsBasisOfFinishedProductBeingRepaired = False;
	If CommonClientServer.HasAttributeOrObjectProperty(FillingData, "DocumentIsBasisOfFinishedProductBeingRepaired") Then
		DocumentIsBasisOfFinishedProductBeingRepaired = FillingData.DocumentIsBasisOfFinishedProductBeingRepaired;
	EndIf;
	Query.SetParameter("DocumentIsBasisOfFinishedProductBeingRepaired", DocumentIsBasisOfFinishedProductBeingRepaired);
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderSelection = ResultsArray[1].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		FillingData.DocumentBasis,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		AcceptableStatuses);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	Goods.Load(ResultsArray[2].Unload());
	
	If FillingData.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		And Goods.Count() = 0 Then
		Raise NStr("vi = 'Không có số dư cần lập.';
					|ru = 'Нет остатков к оформлению.';
					|en = 'There are no remaining goods to register.'; fa = 'There are no remaining goods to register.';
					|it = 'Non vi sono saldi da formalizzare.';
					|pl = 'Brak zapasów do rejestracji.';
					|tr = 'Hazırlanacak herhangi bir bakiye bulunmamaktadır.'");
	EndIf;
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentFromStorage));
	
	For Each CurrentData In Goods Do
		If ValueIsFilled(CurrentData.Series)
			And Not ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(CurrentData.BatchesIndicationStatus, SeriesSpecificationParameters) Then
			FillPropertyValues(SetOfSeries.Add(), CurrentData);
		EndIf;
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(
		ThisObject,
		SeriesSpecificationParameters);
	
EndProcedure

Procedure FillInDocumentBasedOnReportToGiver2_5(FillingData)
	
	DataBasis = Common.ObjectAttributesValues(
						FillingData,
						"Organization, Partner, Counterparty, Department, Warehouse, Contract, ReportOnOrders, MaterialProviderOrder,
						|ARAPCurrency, Manager");
	
	If DataBasis.ReportOnOrders Then
		
		If ValueIsFilled(DataBasis.MaterialProviderOrder) Then
			
			OrderDescription = New Structure;
			OrderDescription.Insert("DocumentBasis",     DataBasis.MaterialProviderOrder);
			OrderDescription.Insert("BusinessOperation", Enums.BusinessTransactions.TransferToMaterialProvider2_5);
			
			FillInBasedOnGiverSOrder2_5(OrderDescription);
			
		Else
			
			TextException =
				NStr("vi = 'Đã lập báo cáo dành cho bên đặt gia công theo nhiều đơn hàng. Không thể nhập trên cơ sở.
						   |Hãy sử dụng chỗ làm việc ""Nhận gia công"" - ""Chứng từ cần lập"".';
						   |ru = 'Отчет давальцу оформлен по нескольким заказам. Ввод на основании невозможен.
						   |Воспользуйтесь рабочим местом ""Прием в переработку"" - ""Документы к оформлению"".';
						   |en = '""Consumption report — Subcontracting services delivered"" is registered by several orders. Cannot generate from base documents.
						   |Use the ""Subcontracting services delivered — Unregistered documents"" workplace.'; fa = '""Consumption report — Subcontracting services delivered"" is registered by several orders. Cannot generate from base documents.
						   |Use the ""Subcontracting services delivered — Unregistered documents"" workplace.';
						   |it = 'Отчет давальцу оформлен по нескольким заказам. Ввод на основании невозможен.
						   |Воспользуйтесь рабочим местом ""Прием в переработку"" - ""Документы к оформлению"".';
						   |pl = '""Consumption report — Subcontracting services delivered"" is registered by several orders. Cannot generate from base documents.
						   |Use the ""Subcontracting services delivered — Unregistered documents"" workplace.';
						   |tr = 'Birden fazla sipariş için bir Tüketim raporu-Verilen fason hizmetleri düzenlendi. Buna dayalı giriş mümkün değildir.
						   |""Verilen fason  hizmetleri"" - ""İşlenecek belgeler"" çalışma alanını kullanın.'");
			
			Raise TextException;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
		|		AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Contract = &Contract
		|		AND ReferenceOrder IN
		|			(SELECT
		|				Ref
		|			FROM
		|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			WHERE
		|				DocumentsRegistry.Organization = &Organization
		|				AND NOT DocumentsRegistry.AdditionalRecord)
		|		AND (Products, Characteristic, Series, Warehouse) IN
		|			(SELECT
		|				Products,
		|				Characteristic,
		|				Series,
		|				Warehouse
		|			FROM
		|				TableOfGoods AS TableOfGoods)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
	TableFormationParameters.Indicators = "Ordered, ToRegister";
	TableFormationParameters.Resources = "Count, Sum";
	TableFormationParameters.Indexes = "ReferenceOrder, RowCode";
	TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
	
	TT_ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.Products      AS Products,
	|	TableOfGoods.Characteristic    AS Characteristic,
	|	TableOfGoods.Purpose        AS Purpose,
	|	TableOfGoods.Series             AS Series,
	|	TableOfGoods.Warehouse             AS Warehouse,
	|	SUM(TableOfGoods.Count) AS Count
	|INTO TableOfGoods
	|FROM
	|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &DocumentBasis
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.Series,
	|	TableOfGoods.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|"
	+ TT_ShipmentOrdersTurnoverExpanded
	+ Common.QueryBatchSeparator()
	+ "
	|SELECT
	|	BalancesWithoutOrder.Products     AS Products,
	|	BalancesWithoutOrder.Characteristic   AS Characteristic,
	|	BalancesWithoutOrder.Purpose       AS Purpose,
	|	BalancesWithoutOrder.Warehouse            AS Warehouse,
	|	BalancesWithoutOrder.Series            AS Series,
	|	SUM(BalancesWithoutOrder.ToTransfer) AS ToTransfer
	|INTO BalancesWithoutOrder
	|FROM
	|	(SELECT
	|		CompanyGoods.ItemsLocationAttributes.Products   AS Products,
	|		CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		CompanyGoods.ItemsLocationAttributes.Purpose     AS Purpose,
	|		CompanyGoods.ItemsLocationAttributes.StorageLocation  AS Warehouse,
	|		CompanyGoods.ItemsLocationAttributes.Series          AS Series,
	|		CompanyGoods.CountBalance                         AS ToTransfer
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(,
	|				InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|				AND CAST(InventoryOwnerAttribute.Contract AS Catalog.CounterpartyContracts).ContractType =
	|																VALUE(Enum.ContractTypes.ReceiptForTolling2_5)
	|				AND ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|				AND Organization = &Organization
	|				AND InventoryOwnerAttribute.Contract = &Contract
	|				AND (ItemsLocationAttributes.Products,
	|				   ItemsLocationAttributes.Characteristic,
	|				   ItemsLocationAttributes.Purpose,
	|				   ItemsLocationAttributes.Series,
	|				   ItemsLocationAttributes.StorageLocation) IN
	|						(SELECT
	|							TableOfGoods.Products   AS Products,
	|							TableOfGoods.Characteristic AS Characteristic,
	|							TableOfGoods.Purpose     AS Purpose,
	|							TableOfGoods.Series          AS Series,
	|							TableOfGoods.Warehouse          AS Warehouse
	|						FROM
	|							TableOfGoods AS TableOfGoods)) AS CompanyGoods
	|	WHERE
	|		CompanyGoods.CountBalance > 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		Turnovers.Products   AS Products,
	|		Turnovers.Characteristic AS Characteristic,
	|		ManufacturedProduct.Purpose   AS Purpose,
	|		Turnovers.Warehouse          AS Warehouse,
	|		Turnovers.Series          AS Series,
	|		-ManufacturedProduct.Count  AS ToTransfer
	|	FROM
	|		TT_ShipmentOrdersTurnoverExpanded AS Turnovers
	|
	|			INNER JOIN Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ManufacturedProduct
	|			ON Turnovers.ReferenceOrder = ManufacturedProduct.MaterialProviderOrder
	|			AND Turnovers.RowCode = ManufacturedProduct.RowCode
	|			AND ManufacturedProduct.Ref.Posted
	|	WHERE
	|		NOT CAST(Turnovers.ReferenceOrder AS Document.MaterialProviderOrder2_5).Ref IS NULL // to work out RLS
	|		AND NOT CAST(Turnovers.Warehouse AS Catalog.Warehouses).Ref IS NULL
	|		AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Turnovers.ReferenceOrder
	|				AND DocumentsRegistry.Organization = &Organization
	|				AND NOT DocumentsRegistry.AdditionalRecord)
	|		AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TableOfGoods AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Products = Turnovers.Products
	|				AND TableOfGoods.Characteristic = Turnovers.Characteristic
	|				AND TableOfGoods.Purpose = ManufacturedProduct.Purpose
	|				AND TableOfGoods.Series = Turnovers.Series
	|				AND TableOfGoods.Warehouse = Turnovers.Warehouse)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Turnovers.Products   AS Products,
	|		Turnovers.Characteristic AS Characteristic,
	|		GoodsTable.Purpose   AS Purpose,
	|		Turnovers.Warehouse          AS Warehouse,
	|		Turnovers.Series          AS Series,
	|		GoodsTable.Count  AS ToTransfer
	|	FROM
	|		TT_ShipmentOrdersTurnoverExpanded AS Turnovers
	|
	|			INNER JOIN Document.GoodsShipmentFromStorage.Goods AS GoodsTable
	|			ON Turnovers.ReferenceOrder = GoodsTable.SalesOrder
	|			AND Turnovers.RowCode = GoodsTable.RowCode
	|			AND GoodsTable.Ref.Posted
	|	WHERE
	|		NOT CAST(Turnovers.ReferenceOrder AS Document.MaterialProviderOrder2_5).Ref IS NULL // to work out RLS
	|		AND NOT CAST(Turnovers.Warehouse AS Catalog.Warehouses).Ref IS NULL
	|		AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|			WHERE
	|				DocumentsRegistry.Ref = Turnovers.ReferenceOrder
	|				AND DocumentsRegistry.Organization = &Organization
	|				AND NOT DocumentsRegistry.AdditionalRecord)
	|		AND TRUE IN 
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TableOfGoods AS TableOfGoods
	|			WHERE
	|				TableOfGoods.Products = Turnovers.Products
	|				AND TableOfGoods.Characteristic = Turnovers.Characteristic
	|				AND TableOfGoods.Purpose = GoodsTable.Purpose
	|				AND TableOfGoods.Series = Turnovers.Series
	|				AND TableOfGoods.Warehouse = Turnovers.Warehouse)) AS BalancesWithoutOrder
	|
	|GROUP BY
	|	BalancesWithoutOrder.Products,
	|	BalancesWithoutOrder.Characteristic,
	|	BalancesWithoutOrder.Purpose,
	|	BalancesWithoutOrder.Warehouse,
	|	BalancesWithoutOrder.Series
	|
	|HAVING
	|	SUM(BalancesWithoutOrder.ToTransfer) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Products   AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose     AS Purpose,
	|	TableOfGoods.Series          AS Series,
	|	TableOfGoods.Warehouse          AS Warehouse,
	|	CASE
	|		WHEN TableOfGoods.Count > BalancesWithoutOrder.ToTransfer
	|			THEN BalancesWithoutOrder.ToTransfer
	|		ELSE TableOfGoods.Count
	|	END AS Count
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN BalancesWithoutOrder AS BalancesWithoutOrder
	|		ON TableOfGoods.Products   = BalancesWithoutOrder.Products
	|		 AND TableOfGoods.Characteristic = BalancesWithoutOrder.Characteristic
	|		 AND TableOfGoods.Purpose     = BalancesWithoutOrder.Purpose
	|		 AND TableOfGoods.Series          = BalancesWithoutOrder.Series
	|		 AND TableOfGoods.Warehouse          = BalancesWithoutOrder.Warehouse
	|WHERE
	|	NOT BalancesWithoutOrder.Products IS NULL
	|";
	
	Query.SetParameter("DocumentBasis",       FillingData);
	Query.SetParameter("Contract",                 DataBasis.Contract);
	Query.SetParameter("Organization",             DataBasis.Organization);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Raise NStr("vi = 'Không có số dư cần lập.';
					|ru = 'Нет остатков к оформлению.';
					|en = 'There are no remaining goods to register.'; fa = 'There are no remaining goods to register.';
					|it = 'Non vi sono saldi da formalizzare.';
					|pl = 'Brak zapasów do rejestracji.';
					|tr = 'Hazırlanacak herhangi bir bakiye bulunmamaktadır.'");
	EndIf;
	
	FillPropertyValues(ThisObject, DataBasis);
	
	DocumentBasis     = FillingData;
	BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
	Currency                = DataBasis.ARAPCurrency;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		LineTSProducts = Goods.Add();
		FillPropertyValues(LineTSProducts, Selection);
		LineTSProducts.NumberOfPackages = Selection.Count;
		
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(
		ThisObject,
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentFromStorage)));
	
EndProcedure
Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Partner") Then
		Partner = FillingData.Partner;
		
		CurrentOperation = 
			?(FillingData.Property("BusinessOperation"), FillingData.BusinessOperation, Undefined);
		
		FillInDefaultPurchaseConditions(, CurrentOperation);
		
	ElsIf FillingData.Property("DocumentBasis") Then
		If TypeOf(FillingData.DocumentBasis) = Type("Array") Then
			For Each CurrentData In FillingData.DocumentBasis Do
				FillInDocumentOnClientSOrder(CurrentData, FillingData.DesignParameters.ByNotes);
			EndDo;
		Else
			FillInDocumentOnClientSOrder(FillingData.DocumentBasis, FillingData.DesignParameters.ByNotes);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Organization") Then
			Organization = FillingData.Organization;
		EndIf;
	EndIf;
	
	UseVTCHWarehouse = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	If ValueIsFilled(Contract)
	   And Common.ObjectAttributeValue(Contract, "BusinessOperation") =
											TollingSchemeClientServer.ContractBusinessTransaction() Then
		Department = Common.ObjectAttributeValue(Contract, "Department");
	Else
		Department = SettingsValueCached.UserDivision(Manager, Department);
	EndIf;
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse, UseVTCHWarehouse, True);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	StructureOfResponsible = PurchasesServer.GetWarehouseManager(Warehouse, Manager);
	
	If StructureOfResponsible <> Undefined Then
		IssuiedBy          = StructureOfResponsible.EmployeeResponsible;
		IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	StructureBase = Documents.GoodsShipmentFromStorage.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);	
	
EndProcedure

// Parameters:
// 	FillingData - Structure - Contains:
// 		* Partner - CatalogRef.Partners - 
// 		* Counterparty - CatalogRef.Counterparties - 
// 		* Contract - CatalogRef.CounterpartyContracts - 
// 		* Terms - CatalogRef.TermsOfSale, CatalogRef.TermsOfPurchaseFromVendors - 
// 		* Warehouse - CatalogRef.Warehouses - 
// 		* Ref - DocumentRef - 
// 		* Organization - CatalogRef.Companies - 
// 		* Currency - CatalogRef.Currencies - 
// 	ByNotes - Boolean - 
Procedure FillInDocumentOnClientSOrder(Val FillingData, ByNotes = False)
	
	BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal;
	
	If TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	SalesOrder.Ref AS Ref,
		|	SalesOrder.Partner AS Partner,
		|	SalesOrder.Counterparty AS Counterparty,
		|	SalesOrder.Contract AS Contract,
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.Terms AS Terms,
		|	SalesOrder.Currency AS Currency,
		|	CASE
		|		WHEN SalesOrder.Warehouse.IsFolder
		|		AND SalesOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE SalesOrder.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN SalesOrder.Warehouse.IsFolder
		|		AND SalesOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItIsForbiddenToSelectWarehouseGroup
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &SalesOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	ShippingOrdersShipped.Warehouse AS Warehouse
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersShipped
		|WHERE
		|	ShippingOrdersShipped.QuantityToBeShippedTurnover
		|		- ShippingOrdersShipped.ShippedQuantityTurnover > 0
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
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query.SetParameter("SalesOrder", FillingData);
		QueryResult = Query.ExecuteBatch();
		
		HeaderAttributes = QueryResult[0].Select();
		HeaderAttributes.Next();
		
		If HeaderAttributes.ItIsForbiddenToSelectWarehouseGroup Then
			SampleWarehouse = QueryResult[1].Select();
			If SampleWarehouse.Next() Then
				Warehouse = SampleWarehouse.Warehouse;
			EndIf;
		EndIf;
		
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(FillingData);
	Else
		HeaderAttributes = Undefined;
		FillingData.Property("HeaderAttributes", HeaderAttributes);
		
		FillPropertyValues(ThisObject, HeaderAttributes);
		If Not HeaderAttributes.Property("Currency") Then
			HeaderAttributes.Insert("Currency", Catalogs.Currencies.EmptyRef());
			HeaderAttributes.Property("ARAPCurrency", HeaderAttributes.Currency);
		EndIf;
		
		HeaderAttributes.Insert("Ref", Documents.SalesOrder.EmptyRef());
		AnArrayOfOrders = FillingData.DocumentBasis;
		
	EndIf;
	
	Partner     = HeaderAttributes.Partner;
	Counterparty  = HeaderAttributes.Counterparty;
	Contract     = HeaderAttributes.Contract;
	Terms  = HeaderAttributes.Terms;
	Basis   = HeaderAttributes.Ref;
	Organization = HeaderAttributes.Organization;
	Currency      = HeaderAttributes.Currency;
	If Not ValueIsFilled(Warehouse) Then
		Warehouse   = HeaderAttributes.Warehouse;
	EndIf;
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Partner", Partner);
	FilterParameters.Insert("Counterparty", Counterparty);
	FilterParameters.Insert("Organization", Organization);
	FilterParameters.Insert("Warehouse", Warehouse);
	FilterParameters.Insert("Contract", Contract);
	FilterParameters.Insert("SalesOrders", AnArrayOfOrders);
	FilterParameters.Insert("GoodsShipment", Goods.Unload());
	FilterParameters.Insert("DocumentShipments", Ref);
	FilterParameters.Insert("ByOrder", True);
	FilterParameters.Insert("AdvancedWarehousingOnShipment", WarehousesServer.ThereIsOrderWarehouseForShipment(, Date, Warehouse));

	ShipmentData = Documents.GoodsShipmentFromStorage.GetTableOfShipmentBalances(FilterParameters);
	
	If ShipmentData.Count() = 0 Then
		ErrorText = ProvisionInDocumentsServer.ErrorTextNoProductsAvailableForShipment();
		Raise ErrorText;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each StringBalance In ShipmentData Do
		
		RowOfGoods = Goods.Add();
		FillPropertyValues(RowOfGoods, StringBalance);
		If StringBalance.AdvancedWarehousingOnShipment
			And ByNotes Then
			RowOfGoods.Count = StringBalance.QuantityIsCollected;
			RowsToProcess.Add(RowOfGoods);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Goods,
		CachedValues);
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager  = TemporaryDocumentDataTables();
	RefillInventoryKinds = AdditionalProperties.Property("RefillInventoryKinds");
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
			
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN, Sum");
		
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.SelectTypesOfStocksForIntercampany = False;
	FillParameters.ReversedDocument = ReversedDocument;
	If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		
		FillParameters.ProductOwnerInHeader = False;
		
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault =
			UserRightsCached.DisableControlOfManufacturedProductTransferToProvider();
		
		FillParameters.TableOfDetailsOfStockTypesByDefault = TableOfDetailsOfStockTypesDefaultFilling();
		
		FillParameters.SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider;
	
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		
		SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
		SelectionOfStockTypes_.Organization    = Organization;
		SelectionOfStockTypes_.GoodsOwner = Partner;
		SelectionOfStockTypes_.Contract        = Contract;
		SelectionOfStockTypes_.InventoryType     = Enums.InventoryTypes.MaterialOfMaterialProvider;
		
	Else
		SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
		SelectionOfStockTypes_.Organization = Organization;
		SelectionOfStockTypes_.GoodsOwner = Partner;
		SelectionOfStockTypes_.Contract = Contract;
		SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell;
	EndIf;
	Return FillParameters;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Warehouse";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query                         = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.DocumentInflow        AS DocumentInflow,
	|		TableOfGoods.SalesOrder               AS SalesOrder,
	|		TableOfGoods.Count                 AS Count,
	|		TableOfGoods.Sum                      AS Sum
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes,
	|		TableTypesOfStocks_.DocumentInflow,
	|		TableTypesOfStocks_.SalesOrder,
	|		-TableTypesOfStocks_.Count,
	|		-TableTypesOfStocks_.Sum
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0";
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

// The procedure fills in additional columns in the table part of the document's' types of items'.
//
Procedure FillInAdditionalStockTypes() Export
	
	GoodsTable = Goods.Unload(, "ItemsLocationAttributes, Package, DocumentInflow, SalesOrder, NumberOfPackages, Count, Price, Sum");
	GoodsTable.GroupBy("ItemsLocationAttributes, Package, DocumentInflow, SalesOrder, Price", "Count, NumberOfPackages, Sum");
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity  = RowOfGoods.Count;
		NumberOfPackages = RowOfGoods.NumberOfPackages;
		
		If GoodsQuantity = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Price                = RowOfGoods.Price;
			NewRow.Package            = RowOfGoods.Package;
			NewRow.DocumentInflow = RowOfGoods.DocumentInflow;
			NewRow.SalesOrder        = RowOfGoods.SalesOrder;
			NewRow.NumberOfPackages  = NumberOfPackages * Count / GoodsQuantity;
			NewRow.Count          = Count;
			NewRow.QuantityByGBRN    = Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.Sum               = ?(Count = GoodsQuantity,
													RowOfGoods.Sum,
													Count * RowOfGoods.Sum / GoodsQuantity);
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.Sum				= InventoryLine.Sum - NewRow.Sum;
			
			GoodsQuantity       = GoodsQuantity - NewRow.Count;
			NumberOfPackages      = NumberOfPackages - NewRow.NumberOfPackages;
			RowOfGoods.Sum     = RowOfGoods.Sum - NewRow.Sum;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Filter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(Filter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.GoodsShipmentFromStorage.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.GoodsShipmentFromStorage.CollectionOfTabularPartsOfGoods();
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		EconomicOperationForCarryingOut = BusinessOperation;
	Else
		EconomicOperationForCarryingOut =
			Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale;
	EndIf;
	// If the Warehouse is a group, then for the analysis of the inventory item, we take the warehouse from PM
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
	
	If WarehouseDetails.IsFolder
		And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
		FieldsNames.Insert("Arbitrary", "Warehouse");
	EndIf;
	
	PlacesOfAccounting =
		InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
			EconomicOperationForCarryingOut,
			Warehouse,
			Department,
			Partner);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure
Function TableOfDetailsOfStockTypesDefaultFilling()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.LineNumber                AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.Purpose                 AS Purpose
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber                           AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes            AS ItemsLocationAttributes,
	|	&Organization                                         AS Organization,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)        AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)          AS CCDNumber,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Partners.EmptyRef)
	|		ELSE CatAssignments.Partner
	|	END                                                AS GoodsOwner,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Counterparties.EmptyRef)
	|		ELSE CatAssignments.Contract.Counterparty
	|	END                                                AS Counterparty,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		ELSE CatAssignments.Contract
	|	END                                                AS Contract,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|		ELSE VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|	END                                                AS InventoryType
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|	
	|	LEFT JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = TableOfGoods.Products
	|	
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON CatAssignments.Ref = TableOfGoods.Purpose
	|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter(
		"TableOfGoods", Goods.Unload(, "LineNumber, ItemsLocationAttributes, Products, Purpose"));
	
	Return Query.Execute().Unload();
	
EndFunction
#EndRegion

#EndRegion

#EndIf
#EndIf
