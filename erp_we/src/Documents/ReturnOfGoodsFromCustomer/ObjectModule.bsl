#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region SalesTermsAndConditions

// Fills in the terms of sale in the return of goods from the customer
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in
//	FillInDetailsOfBase - Boolean - Indicates whether the base is filled in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions, Val FillInDetailsOfBase = True) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	If FillInDetailsOfBase Then
		
		If ValueIsFilled(SalesTermsAndConditions.Currency) Then
			Currency = SalesTermsAndConditions.Currency;
		EndIf;
		
		PriceIncludesVAT      = SalesTermsAndConditions.PriceIncludesVAT;
		LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
		
		If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
			Warehouse = SalesTermsAndConditions.Warehouse;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Organization) Then
		Organization = SalesTermsAndConditions.Organization;
	EndIf;
		
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If SalesTermsAndConditions.NewCommissionScheme <> Undefined And SalesTermsAndConditions.NewCommissionScheme
		And SalesTermsAndConditions.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		SalesTermsAndConditions.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		BusinessOperation = SalesServer.GetRefundTransactionForSale(SalesTermsAndConditions.BusinessOperation);
		ReusablePackageReturn = SalesTermsAndConditions.ReturnReusablePackage;
		DepositForPackageIsRequired = SalesTermsAndConditions.PackageDepositIsRequired;
	EndIf;
	
	ContractBusinessTransaction = Undefined;
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Then
		ContractBusinessTransaction = Enums.BusinessTransactions.SaleToCustomer;
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		ContractBusinessTransaction = Enums.BusinessTransactions.TransferToCommissionAgent;
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent Then
		ContractBusinessTransaction = Enums.BusinessTransactions.TransferToCommissionAgent;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		Contract = SalesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, Currency,,
			ConsignmentSalesServer.ReturnOfGoodsViaCommissionAgent(BusinessOperation));
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;

	EndIf;
	
	If Not ValueIsFilled(SalesTermsAndConditions.ContractsAreUsed) 
		Or Not SalesTermsAndConditions.ContractsAreUsed Then
		ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
	Else
		ForeignCurrencyTransaction = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the return of products from the customer
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled (Partner) Or Not ToUseTermsOfSales Then
		
		ConsignmentSales25 =
			(BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent);
		
		FilterParameters = New Structure();
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.ReturnOfGoodsFromCustomer.EmptyRef());
		FilterParameters.Insert("ConsignmentSales25", ConsignmentSales25);
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
			Partner,
			FilterParameters);
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or 
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
			Else
				Terms = DefaultSalesTerms.Terms;
			EndIf;
			
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
		EndIf;
		
	EndIf;
	
	FillParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

// Fills in the terms of sales under the agreement in the return of goods from the customer
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	FillParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

#EndRegion

#Region Other

// returns the TT data manager for the document.
//
// Parameters:
//	SelectionByMethodOfDeterminingCost - String - string ID of the selection for determining the cost method.
//	FilterByProductType - String - string ID for selecting products by item type.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables(SelectionByMethodOfDeterminingCost = "All",
										FilterByProductType = "All") Export
	
	If FilterByProductType = "Tara" Then
		InitializeAnalyticsKeysForTransferredContainerToClient();
	EndIf;
	
	QueryTexts = New Array;
	
	PartOfTheRequestText =
	"SELECT
	|	&Date					AS Date,
	|	&Organization			AS Organization,
	|	&Warehouse					AS Warehouse,
	|	&Partner				AS Partner,
	|	&Counterparty				AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&Contract				AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)	AS Currency,
	|	&DocumentSalesOfGoodsAndServices		AS DocumentSalesOfGoodsAndServices,
	|	&VATTaxation		AS VATTaxation,
	|	&BusinessOperation	AS BusinessOperation,
	|	FALSE					AS ThereAreTransactionsInTablePart,
	|	&SubjectToExcise		AS SubjectToExcise,
	|	&BusinessUnitProduction AS BusinessUnitProduction,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.ProductsRecordingAsReceived	AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived	AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END										AS QuantityByGBRN,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE TableOfGoods.Warehouse
	|	END										AS Warehouse,
	|	CASE
	|		WHEN TableOfGoods.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef)
	|				OR TableOfGoods.DocumentSalesOfGoodsAndServices = VALUE(Document.RetailSalesReport.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.DocumentSalesOfGoodsAndServices
	|	END										AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT) AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	TableOfGoods.Cost_				AS Cost_,
	|	TableOfGoods.CostExcludingVAT_			AS CostExcludingVAT_,
	|	TableOfGoods.CostLocal			AS CostLocal,
	|	TableOfGoods.CDCost				AS CDCost,
	|	TableOfGoods.TDCost				AS TDCost,
	|	TableOfGoods.CCDNumber						AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.CostDefiningMethod IN(&CostDefiningMethods)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	CASE
	|		WHEN &SelectionOfContainers
	|			THEN ISNULL(ContainerAnalytics.DimensionKey, TableOfGoods.ItemsLocationAttributes)
	|		ELSE TableOfGoods.ItemsLocationAttributes
	|	END										AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsRecordingAsReceived	AS ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived	AS CharacteristicRecordingAsReceived,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	TableOfGoods.SalesOpportunity						AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.CommissionAmount			AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration		AS AmountVATRemuneration,
	|	TableOfGoods.Cost_				AS Cost_,
	|	TableOfGoods.CostExcludingVAT_			AS CostExcludingVAT_,
	|	TableOfGoods.CostLocal			AS CostLocal,
	|	TableOfGoods.CDCost				AS CDCost,
	|	TableOfGoods.TDCost				AS TDCost,
	|	CASE
	|		WHEN (CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND &ReusablePackageReturn)
	|			THEN FALSE
	|		ELSE TRUE
	|	END										AS SelectTypesOfStocks,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, &Date) AS Date,
	|	LogInAnalytics.DimensionKey		AS AnalysisOfAccountingForProductList,
	|	TableOfGoods.CCDNumber						AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS LogInAnalytics
	|		ON TableOfGoods.ProductsRecordingAsReceived = LogInAnalytics.Products
	|			AND TableOfGoods.CharacteristicRecordingAsReceived = LogInAnalytics.Characteristic
	|			AND TableOfGoods.Purpose = LogInAnalytics.Purpose
	|			AND TableOfGoods.Series = LogInAnalytics.Series
	|			AND TableOfGoods.Warehouse = LogInAnalytics.StorageLocation
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS ContainerAnalytics
	|		ON TableOfGoods.Products = ContainerAnalytics.Products
	|			AND TableOfGoods.Characteristic = ContainerAnalytics.Characteristic
	|			AND ContainerAnalytics.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND ContainerAnalytics.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND ContainerAnalytics.StorageLocation = &Partner
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableOfGoods.DocumentSalesOfGoodsAndServices = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	&FilterByProductType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber							AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment	AS ItemsLocationAttributesShipment,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived			AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived			AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.Series								AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber								AS CCDNumber,
	|	TableTypesOfStocks_.VATRate							AS VATRate,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|	END													AS DocumentSalesOfGoodsAndServices,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|				OR TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN TableTypesOfStocks_.CostDefiningMethod
	|		ELSE VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	END													AS CostDefiningMethod,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)		AS SalesOpportunity,
	|	TableTypesOfStocks_.Count							AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END													AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount								AS VATAmount,
	|	TableTypesOfStocks_.ExciseTaxAmount							AS ExciseTaxAmount,
	|	TableTypesOfStocks_.Cost_						AS Cost_,
	|	TableTypesOfStocks_.CostExcludingVAT_					AS CostExcludingVAT_,
	|	TableTypesOfStocks_.CostLocal					AS CostLocal,
	|	TableTypesOfStocks_.CDCost						AS CDCost,
	|	TableTypesOfStocks_.TDCost						AS TDCost
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.CostDefiningMethod IN (&CostDefiningMethods)";
	QueryTexts.Add(PartOfTheRequestText);
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.SelectingCategoriesByDate = False;
	RequestTextParameters.FieldNamePeriod = "Date";
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	PartOfTheRequestText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber							AS LineNumber,
	|	CASE
	|		WHEN &SelectionOfContainers
	|			THEN ISNULL(ContainerAnalytics.DimensionKey, TableTypesOfStocks_.ItemsLocationAttributes)
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes
	|	END													AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment	AS ItemsLocationAttributesShipment,
	|	Dimension.Products									AS Products,
	|	Dimension.Characteristic								AS Characteristic,
	|	Dimension.Series											AS Series,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived			AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived			AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.InventoryOwnerAttribute							AS InventoryOwnerAttribute,
	|	UNDEFINED											AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber								AS CCDNumber,
	|	TableTypesOfStocks_.VATRate							AS VATRate,
	|	ISNULL(DimensionShipments.StorageLocation, VALUE(Catalog.Warehouses.EmptyRef)) AS OriginWarehouse,
	|	Dimension.StorageLocation									AS Warehouse,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices					AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.CostDefiningMethod		AS CostDefiningMethod,
	|	TableTypesOfStocks_.SalesOpportunity								AS SalesOpportunity,
	|	TableTypesOfStocks_.Count							AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN						AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount								AS VATAmount,
	|	TableTypesOfStocks_.ExciseTaxAmount							AS ExciseTaxAmount,
	|	TableTypesOfStocks_.Cost_						AS Cost_,
	|	TableTypesOfStocks_.CostExcludingVAT_					AS CostExcludingVAT_,
	|	TableTypesOfStocks_.CostLocal					AS CostLocal,
	|	TableTypesOfStocks_.CDCost						AS CDCost,
	|	TableTypesOfStocks_.TDCost						AS TDCost,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS							InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionShipments
	|		ON TableTypesOfStocks_.ItemsLocationAttributesShipment = DimensionShipments.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON Dimension.Products = CatProducts.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS ContainerAnalytics
	|		ON Dimension.Products = ContainerAnalytics.Products
	|			AND Dimension.Characteristic = ContainerAnalytics.Characteristic
	|			AND ContainerAnalytics.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND ContainerAnalytics.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND ContainerAnalytics.StorageLocation = &Partner
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableTypesOfStocks_.DocumentSalesOfGoodsAndServices = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON CatProducts.Ref = Category_Data.Products
	|			AND ISNULL(DocumentsRegistry.IBDocumentDate, &Date) = Category_Data.Period
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS DataOfInventory
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = DataOfInventory.Ref
	|
	|WHERE
	|	&FilterByProductType
	|	AND &SelectionOfExcisableItems
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	QueryTexts.Add(PartOfTheRequestText);
	
	TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref",									Ref);
	Query.SetParameter("Date",									Date);
	Query.SetParameter("Organization",							Organization);
	Query.SetParameter("Partner",								Partner);
	Query.SetParameter("Counterparty",								Counterparty);
	Query.SetParameter("Contract",								Contract);
	Query.SetParameter("Terms",								Terms);
	Query.SetParameter("VATTaxation",						VATTaxation);
	Query.SetParameter("Warehouse",									Warehouse);
	Query.SetParameter("DocumentSalesOfGoodsAndServices",						DocumentSalesOfGoodsAndServices);
	Query.SetParameter("PriceIncludesVAT",						?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("BusinessOperation",					BusinessOperation);
	Query.SetParameter("TableOfGoods",							TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",						InventoryKinds);
	Query.SetParameter("ReusablePackageReturn",	ReusablePackageReturn);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",				InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("SelectionOfContainers",								FilterByProductType = "Tara");
	
	If SelectionByMethodOfDeterminingCost = "All" Then
		CostDefiningMethods = New Array;
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.FromSalesDocument);
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.Manually);
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.EmptyRef());
	ElsIf SelectionByMethodOfDeterminingCost = "FromSalesDocument" Then
		CostDefiningMethods = 	New Array;
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.FromSalesDocument);
	ElsIf SelectionByMethodOfDeterminingCost = "NotFromSalesDocument" Then
		CostDefiningMethods = New Array;
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.Manually);
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.EmptyRef());
	EndIf;
	
	Query.SetParameter("CostDefiningMethods", CostDefiningMethods);
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	Query.SetParameter("Country",							RegistrationCountry);
	Query.SetParameter("UseExcisableGoods",	UseExcisableGoods);
	Query.SetParameter("SubjectToExcise",
								?(SelectionByMethodOfDeterminingCost = "NotFromSalesDocument",
								SubjectToExcise,
								False));
	Query.SetParameter("BusinessUnitProduction",
								?(SelectionByMethodOfDeterminingCost = "NotFromSalesDocument",
								BusinessUnitProduction,
								Catalogs.BusinessStructure.EmptyRef()));
	
	If SelectionByMethodOfDeterminingCost = "NotFromSalesDocument" Then
		TextSelectionOfExcisableItems = "(NOT ISNULL(Category_Data.ExcisableGoods, FALSE)
			|		OR TableTypesOfStocks_.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
			|		OR (ISNULL(Category_Data.ExcisableGoods, FALSE)
			|			AND DataOfInventory.SubjectToExcise = &SubjectToExcise
			|			AND DataOfInventory.BusinessUnitProduction = &BusinessUnitProduction)
			|	)";
	Else
		TextSelectionOfExcisableItems = "TRUE";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&SelectionOfExcisableItems", TextSelectionOfExcisableItems);
	If FilterByProductType = "All" Then
		TextSelectionByItemType = "TRUE";
	ElsIf FilterByProductType = "Products" Then
		TextSelectionByItemType = "CatProducts.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)";
	Else
		TextSelectionByItemType = "CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&FilterByProductType", TextSelectionByItemType);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ReturnOfGoodsFromCustomer - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.ReturnOfGoodsFromCustomer.CollectionOfTabularPartsOfGoods.
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

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FilledInBasedOnDocument	= False;
	RecalculateQuantityByRNPT		= True;
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("FillInTransferredContainer") Then
			FillInDocumentOnBasisOfTransferredContainer(FillingData);
			
			FilledInBasedOnDocument	= True;
			RecalculateQuantityByRNPT		= False;
		ElsIf FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.CustomerInvoice") Then
				FillInDocumentOnBasisOfActAfterShipment(FillingData);
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
				FillInDocumentOnBasisOfActAfterAcceptance(FillingData);
			EndIf;
		ElsIf FillingData.Property("AnArrayOfOrders") Then
			FillInFromOrder(FillingData);
		ElsIf FillingData.Property("ServicesForSaleOfGoods") Then
			FillInDocumentBasedOnSaleOfGoodsAndServices(FillingData.DocumentBasis, FillingData.DesignParameters);
			FilledInBasedOnDocument = True;
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoice") Then
		FillInDocumentBasedOnSaleOfGoodsAndServices(FillingData);
		FilledInBasedOnDocument = True;
	ElsIf FillInDataType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		FillInDocumentOnBasisOfRequestForReturnOfGoodsFromClient(FillingData);
		FilledInBasedOnDocument = True;
		
	EndIf;
	
	ClearCostDeterminationMethodAndImplementationDocument();
	
	ReturnOfGoodsFromCustomerLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	If Not FilledInBasedOnDocument Then
		InitializeSalesConditions();
	EndIf;
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	BonusPointsServer.FillInBonusPointsReturnItemsFromCustomer(ThisObject);
	
	If RecalculateQuantityByRNPT Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
	EndIf;
	
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	NotCheckedAttributeArray.Add("Goods.ProductsRecordingAsReceived");
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
		
	Else
		
		NotCheckedAttributeArray.Add("Terms");
		
	EndIf;
	
	AmountReducedDebt = 0;
	For Each PaymentDecryptionLine In ARAPDetails Do
		If ValueIsFilled(PaymentDecryptionLine.ARAPObject)
			And PaymentDecryptionLine.ARAPObject <> ARAPObject Then
			AmountReducedDebt = AmountReducedDebt + PaymentDecryptionLine.Sum;
		EndIf;
	EndDo;
	
	DocumentAmount = GetDocumentAmount();
	CompensationAmount = DocumentAmount - AmountReducedDebt;
	
	If CompensationAmount = 0
		Or BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Then
		
		NotCheckedAttributeArray.Add("CompensationMethod");
		
	EndIf;
	
	CashServer.CheckCompletionOfPaymentDecryption(
		ThisObject,
		GetDocumentAmount(),
		BusinessOperation,
		Cancel);
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.ReturnOfGoodsFromCustomer.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
		
	If Not CashIssued Then
		NotCheckedAttributeArray.Add("CashAccountIssueNoteNumber");
		NotCheckedAttributeArray.Add("CashAccountIssueNoteDate");
	EndIf;
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		// If the account details are not used for a business transaction, we exclude this account from verification.
		If ArrayOfOperationDetails.Find(ArrayElement) = Undefined Then
			NotCheckedAttributeArray.Add(ArrayElement);
		ElsIf CheckedAttributes.Find(ArrayElement) = Undefined Then
			CheckedAttributes.Add(ArrayElement);	
		EndIf;
				
	EndDo;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReturnOfGoodsFromCustomer);
	ProductsServer.CheckSeriesCompletion(ThisObject,
	                                            SeriesSpecificationParameters,
	                                            Cancel,
	                                            NotCheckedAttributeArray);
	
	ProductsServer.CheckTypeOfProductDescription(ThisObject,Cancel);
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	If Not BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		And (ThisIsTraceableDocument
			Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")) Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		If ReturnOfSpoiledGoods Then
			AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(
				ThisObject,
				Goods,
				Date,
				"ProductsRecordingAsReceived");
		Else
			AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
		EndIf;
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.DocumentSalesOfGoodsAndServices");
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		And ReusablePackageReturn Then
		MatchingProductsType = Common.ObjectsAttributeValue(Goods.UnloadColumn("Products"), "ItemsType");
	EndIf;
		
	For Each RowOfTables In Goods Do
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress =  StrReplace(ErrorAddress, "%LineNumber%", RowOfTables.LineNumber);
		SalesDocumentField = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "DocumentSalesOfGoodsAndServices");
		ProductDescriptionField = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "ProductsRecordingAsReceived");
		
		If Not ValueIsFilled(RowOfTables.DocumentSalesOfGoodsAndServices)
			And (RowOfTables.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromTransferDocument
				Or (BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
					And ReusablePackageReturn
					And MatchingProductsType.Get(RowOfTables.Products) = Enums.ItemsTypes.ReusablePackage)) Then
			
				ErrorText = NStr("vi = 'Chưa điền cột ""Chứng từ bán hàng""';
								|ru = 'Не заполнена колонка ""Документ продажи""';
								|en = 'Column ""Sales document"" is not filled in'; fa = 'Column ""Sales document"" is not filled in';
								|it = 'La colonna ""Documento di vendita"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Документ продажи""';
								|tr = '""Satış belgesi"" sütunu eksik'");
				Common.MessageToUser(ErrorText + ErrorAddress, ThisObject, SalesDocumentField,, Cancel);
				
		EndIf;
		
		If RowOfTables.Damage Then
			
			If Not ValueIsFilled(RowOfTables.ProductsRecordingAsReceived) Then
				ErrorText = NStr("vi = 'Cột ""mặt hàng (đăng)"" không được điền';
								|ru = 'Не заполнена колонка ""Номенклатура (оприходование)""';
								|en = 'Column ""Items (recording as received)"" is not filled in'; fa = 'Column ""Items (recording as received)"" is not filled in';
								|it = 'La colonna ""Articolo (registrazione in contabilità)"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Номенклатура (оприходование)""';
								|tr = '""Öğe (Envanter)"" sütunu eksik'");
				Common.MessageToUser(ErrorText + ErrorAddress,ThisObject,ProductDescriptionField,,Cancel);
			ElsIf RowOfTables.Products = RowOfTables.ProductsRecordingAsReceived Then
				ErrorText = NStr("vi = 'Hàng hóa có chất lượng ban đầu trùng với hàng hóa có chất lượng khác';
								|ru = 'Товар исходного качества совпадает с товаром другого качества';
								|en = 'Goods of original quality matches with goods of different quality'; fa = 'Goods of original quality matches with goods of different quality';
								|it = 'Il prodotto della qualità originale coincide con il prodotto di una qualità diversa';
								|pl = 'Towar oryginalnej jakości zbiega się z towarem innej jakości';
								|tr = 'Orijinal kalitedeki ürün uygun kalitede olmayan ürünle eşleşmektedir'");
				Common.MessageToUser(ErrorText + ErrorAddress,ThisObject,ProductDescriptionField,,Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	If Not SubjectToExcise Then
		NotCheckedAttributeArray.Add("BusinessUnitProduction");
	Else
		ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
		ControlParameters.ErrorTextTemplate =
			NStr("vi = 'Đã cấm trả lại hàng hóa chịu thuế TTĐB ""%Products%"" mà được chỉ định trong dòng %LineNumber% của danh sách ""%TabularSectionPresentation%"" vào kho bán lẻ ""%Warehouse%""';
				|ru = 'Запрещен возврат подакцизного товара ""%Products%"", указанного в строке %LineNumber% списка ""%TabularSectionPresentation%"" на розничный склад ""%Warehouse%""';
				|en = 'Cannot return the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse'; fa = 'Cannot return the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse';
				|it = 'Cannot return the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse';
				|pl = 'Cannot return the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse';
				|tr = '""%TabularSectionPresentation%"" listesinin %LineNumber% satırında belirtilen tüketim vergisine tabi ""%Products%"" ürününün ""%Warehouse%"" perakende ambarına iadesi yasaktır'");
		ControlParameters.CheckingWarehouse = True;
		ExcisableGoodsAccounting.ControlOfFillingExcisableItems(ThisObject, ControlParameters, Cancel);
	EndIf;
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		"DateOfReceipt");
	
	QualityControl.ProcessingVerificationOfCorrectnessOfConnectionWithBatches(
		ThisObject,
		SeriesSpecificationParameters.LinkFields,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	ReturnOfGoodsFromCustomerLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ClearCostDeterminationMethodAndImplementationDocument();
	
	ThereIsStockQualityChangeInDocument = False;
	CompletedImplementationDocument = False;
	For Each RowOfTables In Goods Do
		
		If RowOfTables.Damage Then
			ThereIsStockQualityChangeInDocument = True;
		EndIf;
		
		If ValueIsFilled(RowOfTables.DocumentSalesOfGoodsAndServices) Then
			CompletedImplementationDocument = True;
		EndIf;
		
		If ThereIsStockQualityChangeInDocument And CompletedImplementationDocument Then
			Break;
		EndIf;
		
	EndDo;
	
	If GetFunctionalOption("UseGoodsQuality") Then
		ReturnOfSpoiledGoods = ThereIsStockQualityChangeInDocument;
	EndIf;
	
	If CompletedImplementationDocument Then
		RecordInProfitLossOfPreviousYears = False;
	EndIf;
	
	If Not ReusablePackageReturn
		And DepositForPackageIsRequired Then
		DepositForPackageIsRequired = False;
	EndIf;
	
	DocumentAmount = GetDocumentAmount();
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReturnOfGoodsFromCustomer);
	ProductsServer.ClearUnusedSeries(ThisObject,SeriesSpecificationParameters);
	
	RegistrationParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	RegistrationParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		AccountingForTraceableGoodsLocalization.ClearDataOnImportedGoodsInCommissionAgentSDocuments(ThisObject);
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
		SalesServer.CheckCorrectnessOfReturnedProducts(ThisObject, "Goods", Cancel);
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		CashRegisterReceipt = Undefined;
	EndIf;
	
	BonusPointsServer.FillInBonusPointsReturnItemsFromCustomer(ThisObject);
	
	If Not CashIssued Then
		CashAccountIssueNoteNumber = "";
		CashAccountIssueNoteDate = '00010101';
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	ReturnOfGoodsFromCustomerLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReturnOfGoodsFromCustomerLocalization.Posting(ThisObject, Cancel, PostingMode);

	RegistrationParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	RegistrationParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
	EndIf;
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReturnOfGoodsFromCustomerLocalization.UndoPosting(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	RegistrationParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	RequestForReturnOfGoodsFromCustomer = Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef();
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	
	For Each TSRow In Goods Do
		TSRow.RowCode = 0;
	EndDo;
	
	InventoryKinds.Clear();
	SetOfSeries.Clear();
	
	InitializeDocument();
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	RecalculateNumberOfRNPT();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	ReturnOfGoodsFromCustomerLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReturnOfGoodsFromCustomerLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillingByReason

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("BusinessOperation") Then
		BusinessOperation = FillingData.BusinessOperation;
		If FillingData.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
			Partner = Catalogs.Partners.RetailCustomer;
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			If GetFunctionalOption("ToUseTermsOfSales") Then
				FillInDefaultSalesConditions();
			EndIf;
		ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		EndIf;
	ElsIf FillingData.Property("Partner") Then
		Partner = FillingData.Partner;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		If GetFunctionalOption("ToUseTermsOfSales") Then
			FillInDefaultSalesConditions();
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnSaleOfGoodsAndServices(Val DocumentBasis, DesignParameters = Undefined)
	
	EnterOnBasisOfUnverified = False;
	If Not DesignParameters = Undefined
		And TypeOf(DesignParameters) = Type("Structure") Then
		
		DesignParameters.Property("EnterOnBasisOfUnverified", EnterOnBasisOfUnverified);
		EnterOnBasisOfUnverified = ?(EnterOnBasisOfUnverified = Undefined,
											False,
											EnterOnBasisOfUnverified);
	
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	GoodsTable.ARAPObject AS ARAPObject
	|INTO ARAPObjects
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CustomerInvoice.Ref AS DocumentSalesOfGoodsAndServices,
	|	CustomerInvoice.Ref AS Ref,
	|	CustomerInvoice.Terms AS Terms,
	|	CustomerInvoice.Organization AS Organization,
	|	CustomerInvoice.Partner AS Partner,
	|	CustomerInvoice.Counterparty AS Counterparty,
	|	CustomerInvoice.ContactPerson AS ContactPerson,
	|	CustomerInvoice.Currency AS Currency,
	|	CustomerInvoice.ARAPCurrency AS ARAPCurrency,
	|	CustomerInvoice.SalesOpportunity AS SalesOpportunity,
	|	CustomerInvoice.Department AS Department,
	|	CustomerInvoice.Status AS DocumentStatus,
	|	CASE
	|		WHEN CustomerInvoice.Warehouse.IsFolder
	|				AND CustomerInvoice.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE CustomerInvoice.Warehouse
	|	END AS Warehouse,
	|	CustomerInvoice.BusinessOperation AS EconomicOperationImplementation,
	|	CustomerInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	CustomerInvoice.VATTaxation AS VATTaxation,
	|	CustomerInvoice.Contract AS Contract,
	|	CustomerInvoice.ToReturnReusablePackage AS ReusablePackageReturn,
	|	CustomerInvoice.PackageDepositIsRequired AS DepositForPackageIsRequired,
	|	NOT CustomerInvoice.Posted
	|		AND NOT &EnterOnBasisOfUnverified AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|				OR CustomerInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus,
	|	CustomerInvoice.LineOfBusiness AS LineOfBusiness,
	|	CustomerInvoice.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CustomerInvoice.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
	|	CustomerInvoice.CustomerCounterparty AS CustomerCounterparty,
	|	CustomerInvoice.CustomerPartner AS CustomerPartner,
	|	CustomerInvoice.CustomerContract AS CustomerContract
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	CustomersARAPAccounting.Currency AS ARAPCurrency,
	|	ISNULL(CustomersARAPAccounting.SumBalance, 0) AS SumBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|			,
	|			ARAPObject IN
	|				(SELECT
	|					ARAPObjects.ARAPObject
	|				FROM
	|					ARAPObjects)) AS CustomersARAPAccounting
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT TOP 1
	|	SaleAdjustment.Ref AS Ref
	|INTO LastAdjustmentData
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON SaleAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|			AND RegisterOfDocumentsStornoCorrection.Posted
	|			AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	SaleAdjustment.Posted
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|	AND SaleAdjustment.DocumentBasis = &DocumentBasis
	|	AND NOT SaleAdjustment.AdjustmentKind IN (VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods),
	|													VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
	|
	|ORDER BY
	|	SaleAdjustment.PointInTime DESC
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	ISNULL(DimensionOfSets.DimensionKey, VALUE(Catalog.KeysOfSetAccountingDimension.EmptyRef)) AS SetAccountingDimension,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	DimensionOfProductItem.DimensionKey AS ItemsLocationAttributes,
	|	GoodsTable.Products AS Products,
	|	CatalogProducts.ItemsType AS ItemsType,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.Warehouse AS Warehouse
	|INTO ProductsForSale
	|FROM
	|	Document.SaleAdjustment.Goods AS GoodsTable
	|		INNER JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON GoodsTable.Ref = LastAdjustmentData.Ref
	|		
	|		LEFT JOIN InformationRegister.SetAccountingDimension AS DimensionOfSets
	|		ON GoodsTable.ProductsInSet = DimensionOfSets.ProductsInSet
	|			AND GoodsTable.ItemVariantOfSet = DimensionOfSets.ItemVariantOfSet
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionOfProductItem
	|		ON GoodsTable.Products = DimensionOfProductItem.Products
	|			AND GoodsTable.Characteristic = DimensionOfProductItem.Characteristic
	|			AND GoodsTable.Purpose = DimensionOfProductItem.Purpose
	|			AND GoodsTable.Series = DimensionOfProductItem.Series
	|			AND GoodsTable.Warehouse = DimensionOfProductItem.StorageLocation
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON GoodsTable.Products = CatalogProducts.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.SetAccountingDimension,
	|	GoodsTable.ProductsInSet,
	|	GoodsTable.ItemVariantOfSet,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Products,
	|	CatalogProducts.ItemsType,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.Package,
	|	GoodsTable.NumberOfPackages,
	|	GoodsTable.Count,
	|	GoodsTable.Sum,
	|	GoodsTable.VATRate,
	|	GoodsTable.VATAmount,
	|	GoodsTable.AmountIncludingVAT,
	|	GoodsTable.Warehouse
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON TRUE
	|		
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON GoodsTable.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|			AND RegisterOfDocumentsStornoCorrection.Posted
	|			AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON GoodsTable.Products = CatalogProducts.Ref
	|
	|WHERE
	|	GoodsTable.Ref = &DocumentBasis
	|	AND LastAdjustmentData.Ref IS NULL
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|
	|INDEX BY
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	ProductsForSale.SetAccountingDimension AS SetAccountingDimension,
	|	ProductsForSale.ProductsInSet AS ProductsInSet,
	|	ProductsForSale.ItemVariantOfSet AS ItemVariantOfSet,
	|	ISNULL(ProductKitConfigurations.ContainsServices, FALSE) AS SetContainsServices,
	|	ProductsForSale.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ProductsForSale.Products AS Products,
	|	ProductsForSale.ItemsType AS ItemsType,
	|	ProductsForSale.Characteristic AS Characteristic,
	|	ProductsForSale.Purpose AS Purpose,
	|	ProductsForSale.Series AS Series,
	|	ProductsForSale.Package AS Package,
	|	SUM(ProductsForSale.NumberOfPackages) AS NumberOfPackages,
	|	SUM(ProductsForSale.Count) AS Count,
	|	SUM(ProductsForSale.Sum) AS Sum,
	|	ProductsForSale.VATRate AS VATRate,
	|	SUM(ProductsForSale.VATAmount) AS VATAmount,
	|	SUM(ProductsForSale.AmountIncludingVAT) AS AmountIncludingVAT,
	|	ProductsForSale.Warehouse AS Warehouse
	|INTO GoodsSales_
	|FROM
	|	ProductsForSale AS ProductsForSale
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = ProductsForSale.ProductsInSet
	|			AND ProductKitConfigurations.Characteristic = ProductsForSale.ItemVariantOfSet
	|			AND ProductKitConfigurations.Main
	|
	|GROUP BY
	|	ProductsForSale.SetAccountingDimension,
	|	ProductsForSale.ProductsInSet,
	|	ProductsForSale.ItemVariantOfSet,
	|	ISNULL(ProductKitConfigurations.ContainsServices, FALSE),
	|	ProductsForSale.ItemsLocationAttributes,
	|	ProductsForSale.Products,
	|	ProductsForSale.ItemsType,
	|	ProductsForSale.Characteristic,
	|	ProductsForSale.Purpose,
	|	ProductsForSale.Series,
	|	ProductsForSale.Package,
	|	ProductsForSale.VATRate,
	|	ProductsForSale.Warehouse
	|
	|INDEX BY
	|	SetAccountingDimension,
	|	ItemsLocationAttributes,
	|	Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	ISNULL(SetAnalyticsKeys.Ref, VALUE(Catalog.KeysOfSetAccountingDimension.EmptyRef)) AS SetAccountingDimension,
	|	ISNULL(SetAnalyticsKeys.ProductsInSet, VALUE(Catalog.Products.EmptyRef)) AS ProductsInSet,
	|	ISNULL(SetAnalyticsKeys.ItemVariantOfSet, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS ItemVariantOfSet,
	|	RefundProducts.ItemsLocationAttributesShipment AS ItemsLocationAttributes,
	|	DimensionKeys.Products AS Products,
	|	CatalogProducts.ItemsType AS ItemsType,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	DimensionKeys.Purpose AS Purpose,
	|	DimensionKeys.Series AS Series,
	|	RefundProducts.Package AS Package,
	|	SUM(RefundProducts.NumberOfPackages) AS NumberOfPackages,
	|	SUM(RefundProducts.Count) AS Count,
	|	SUM(RefundProducts.AmountIncludingVAT - RefundProducts.VATAmount) AS Sum,
	|	RefundProducts.VATRate AS VATRate,
	|	SUM(RefundProducts.VATAmount) AS VATAmount,
	|	SUM(RefundProducts.AmountIncludingVAT) AS AmountIncludingVAT,
	|	DimensionKeys.StorageLocation AS Warehouse
	|INTO ProductsFromPreviousRefunds
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS RefundProducts
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|		ON RefundProducts.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|			AND RegisterOfDocumentsStornoCorrection.Posted
	|			AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|		
	|		LEFT JOIN Catalog.KeysOfSetAccountingDimension AS SetAnalyticsKeys
	|		ON RefundProducts.SetAccountingDimension = SetAnalyticsKeys.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON RefundProducts.ItemsLocationAttributesShipment = DimensionKeys.Ref
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON DimensionKeys.Products = CatalogProducts.Ref
	|
	|WHERE
	|	RefundProducts.Ref.Posted
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|	AND RefundProducts.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	ISNULL(SetAnalyticsKeys.Ref, VALUE(Catalog.KeysOfSetAccountingDimension.EmptyRef)),
	|	ISNULL(SetAnalyticsKeys.ProductsInSet, VALUE(Catalog.Products.EmptyRef)),
	|	ISNULL(SetAnalyticsKeys.ItemVariantOfSet, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
	|	RefundProducts.ItemsLocationAttributesShipment,
	|	DimensionKeys.Products,
	|	CatalogProducts.ItemsType,
	|	DimensionKeys.Characteristic,
	|	DimensionKeys.Purpose,
	|	DimensionKeys.Series,
	|	RefundProducts.Package,
	|	RefundProducts.VATRate,
	|	DimensionKeys.StorageLocation
	|
	|INDEX BY
	|	SetAccountingDimension,
	|	ItemsLocationAttributes,
	|	Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	ISNULL(GoodsSales_.SetAccountingDimension, ProductsFromPreviousRefunds.SetAccountingDimension) AS SetAccountingDimension,
	|	ISNULL(GoodsSales_.ProductsInSet, ProductsFromPreviousRefunds.ProductsInSet) AS ProductsInSet,
	|	ISNULL(GoodsSales_.ProductsInSet.Description, ProductsFromPreviousRefunds.ProductsInSet.Description) AS ProductsInSetPresentation,
	|	ISNULL(GoodsSales_.ItemVariantOfSet, ProductsFromPreviousRefunds.ItemVariantOfSet) AS ItemVariantOfSet,
	|	ISNULL(GoodsSales_.ItemVariantOfSet.Description, ProductsFromPreviousRefunds.ItemVariantOfSet.Description) AS ItemVariantOfSetPresentation,
	|	ISNULL(GoodsSales_.SetContainsServices, FALSE) AS SetContainsServices,
	|	ISNULL(GoodsSales_.Products, ProductsFromPreviousRefunds.Products) AS Products,
	|	ISNULL(GoodsSales_.Products.Description, ProductsFromPreviousRefunds.Products.Description) AS ProductsPresentation,
	|	ISNULL(GoodsSales_.ItemsLocationAttributes, ProductsFromPreviousRefunds.ItemsLocationAttributes) AS ItemsLocationAttributes,
	|	ISNULL(GoodsSales_.ItemsType, ProductsFromPreviousRefunds.ItemsType) AS ItemsType,
	|	ISNULL(GoodsSales_.Characteristic, ProductsFromPreviousRefunds.Characteristic) AS Characteristic,
	|	ISNULL(GoodsSales_.Characteristic.Description, ProductsFromPreviousRefunds.Characteristic.Description) AS CharacteristicPresentation,
	|	ISNULL(GoodsSales_.Purpose, ProductsFromPreviousRefunds.Purpose) AS Purpose,
	|	ISNULL(GoodsSales_.Series, ProductsFromPreviousRefunds.Series) AS Series,
	|	ISNULL(GoodsSales_.Series.Description, ProductsFromPreviousRefunds.Series.Description) AS SeriesPresentation,
	|	ISNULL(GoodsSales_.Count, 0) - ISNULL(ProductsFromPreviousRefunds.Count, 0) AS Count,
	|	0 AS NumberOfPackages,
	|	ISNULL(GoodsSales_.Package, ProductsFromPreviousRefunds.Package) AS Package,
	|	ISNULL(GoodsSales_.Package.Description, ProductsFromPreviousRefunds.Package.Description) AS PackagePresentation,
	|	ISNULL(GoodsSales_.VATRate, ProductsFromPreviousRefunds.VATRate) AS VATRate,
	|	ISNULL(GoodsSales_.Sum, 0) - ISNULL(ProductsFromPreviousRefunds.Sum, 0) AS Sum,
	|	ISNULL(GoodsSales_.VATAmount, 0) - ISNULL(ProductsFromPreviousRefunds.VATAmount, 0) AS VATAmount,
	|	ISNULL(GoodsSales_.AmountIncludingVAT, 0) - ISNULL(ProductsFromPreviousRefunds.AmountIncludingVAT, 0) AS AmountIncludingVAT,
	|	&DocumentBasis AS DocumentSalesOfGoodsAndServices,
	|	ISNULL(GoodsSales_.Warehouse, ProductsFromPreviousRefunds.Warehouse) AS Warehouse
	|FROM
	|	GoodsSales_ AS GoodsSales_
	|		FULL JOIN ProductsFromPreviousRefunds AS ProductsFromPreviousRefunds
	|		ON GoodsSales_.SetAccountingDimension = ProductsFromPreviousRefunds.SetAccountingDimension
	|			AND GoodsSales_.ItemsLocationAttributes = ProductsFromPreviousRefunds.ItemsLocationAttributes
	|			AND GoodsSales_.Package = ProductsFromPreviousRefunds.Package
	|
	|ORDER BY
	|	ProductsInSetPresentation,
	|	ItemVariantOfSetPresentation,
	|	ProductsPresentation,
	|	CharacteristicPresentation,
	|	SeriesPresentation,
	|	PackagePresentation
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	TransferredReturnablePackagingBalance.Products AS Products,
	|	TransferredReturnablePackagingBalance.Characteristic AS Characteristic,
	|	TransferredReturnablePackagingBalance.Partner AS Partner,
	|	TransferredReturnablePackagingBalance.DocumentTransfers_ AS DocumentTransfers_,
	|	TransferredReturnablePackagingBalance.CountBalance AS Count,
	|	TransferredReturnablePackagingBalance.SumBalance AS Sum
	|INTO TTTransferredReturnPackaging
	|FROM
	|	AccumulationRegister.TransferredReturnablePackaging.Balance(, DocumentTransfers_ = &DocumentBasis) AS TransferredReturnablePackagingBalance
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 9
	|SELECT
	|	TTTransferredReturnPackaging.Products AS Products,
	|	TTTransferredReturnPackaging.Characteristic AS Characteristic,
	|	TTTransferredReturnPackaging.DocumentTransfers_ AS DocumentSalesOfGoodsAndServices,
	|	SUM(TTTransferredReturnPackaging.Count) AS Count,
	|	SUM(TTTransferredReturnPackaging.Count) AS NumberOfPackages,
	|	SUM(TTTransferredReturnPackaging.Sum) AS Sum,
	|	SUM(TTTransferredReturnPackaging.Sum) AS AmountIncludingVAT,
	|	CASE
	|		WHEN SUM(TTTransferredReturnPackaging.Count) = 0
	|			THEN SUM(TTTransferredReturnPackaging.Sum)
	|		ELSE SUM(TTTransferredReturnPackaging.Sum) / SUM(TTTransferredReturnPackaging.Count)
	|	END AS Price,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate
	|FROM
	|	TTTransferredReturnPackaging AS TTTransferredReturnPackaging
	|
	|GROUP BY
	|	TTTransferredReturnPackaging.Products,
	|	TTTransferredReturnPackaging.Characteristic,
	|	TTTransferredReturnPackaging.DocumentTransfers_
	|
	|HAVING
	|	SUM(TTTransferredReturnPackaging.Count) > 0
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	DocumentSalesOfGoodsAndServices";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("EnterOnBasisOfUnverified", EnterOnBasisOfUnverified);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[1].Select();
	HeaderSelection.Next();
	
	SamplingBaseCalculations = QueryBatch[2].Select();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	BusinessOperation = SalesServer.GetRefundTransactionForSale(HeaderSelection.EconomicOperationImplementation);
	
	SearchKeys = "ItemsLocationAttributes, SetAccountingDimension, VATRate";
	
	TableOfGoods = QueryBatch[7].Unload(); // ValueTable -
	TableOfGoods.Indexes.Add(SearchKeys);
	
	TheStructureOfTheSearch = New Structure(SearchKeys);
	
	For Each String In TableOfGoods Do
		If String.Count < 0 Then
			FillPropertyValues(TheStructureOfTheSearch, String);
			SalesLines = TableOfGoods.FindRows(TheStructureOfTheSearch);
			
			For Each LineOfSale In SalesLines Do
				If LineOfSale.Count < 0 Then
					Continue;
				EndIf;
				
				String.Count	= -String.Count;
				String.Sum		= -String.Sum;
				String.VATAmount		= -String.VATAmount;
				String.AmountIncludingVAT	= -String.AmountIncludingVAT;
				
				If String.Count > LineOfSale.Count Then
					AmountToDeduct	= LineOfSale.Count;
					AmountToDeduct_		= LineOfSale.Sum;
					AmountOfVATDeducted	= LineOfSale.VATAmount;
					AmountWithVATDeductible	= LineOfSale.AmountIncludingVAT;
				Else
					AmountToDeduct	= String.Count;
					AmountToDeduct_		= String.Sum;
					AmountOfVATDeducted	= String.VATAmount;
					AmountWithVATDeductible	= String.AmountIncludingVAT;
				EndIf;
				
				LineOfSale.Count	= LineOfSale.Count - AmountToDeduct;
				String.Count			= String.Count - AmountToDeduct;
				
				LineOfSale.Sum			= LineOfSale.Sum - AmountToDeduct_;
				String.Sum				= String.Sum - AmountToDeduct_;
				
				LineOfSale.VATAmount		= LineOfSale.VATAmount - AmountOfVATDeducted;
				String.VATAmount				= String.VATAmount - AmountOfVATDeducted;
				
				LineOfSale.AmountIncludingVAT		= LineOfSale.AmountIncludingVAT - AmountWithVATDeductible;
				String.AmountIncludingVAT			= String.AmountIncludingVAT - AmountWithVATDeductible;
			EndDo;
		EndIf;
	EndDo;
	
	ArrayOfRowsToDelete_1 = New Array;
	For Each String In TableOfGoods Do
		If String.Count <= 0 Then
			ArrayOfRowsToDelete_1.Add(String);
		EndIf;
	EndDo;
	
	For Each String In ArrayOfRowsToDelete_1 Do
		TableOfGoods.Delete(String);
	EndDo;
	
	TableOfGoods.Columns.Delete("SetAccountingDimension");
	TableOfGoods.Columns.Delete("ItemsLocationAttributes");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(TableOfGoods, StructureOfActions);
	
	For Each CurRow In TableOfGoods Do
		If CurRow.ItemsType = Enums.ItemsTypes.OwnGoods
				And Not ValueIsFilled(CurRow.ProductsInSet)
			Or (CurRow.ItemsType = Enums.ItemsTypes.ReusablePackage
					And Not HeaderSelection.ReusablePackageReturn)
				And Not ValueIsFilled(CurRow.ProductsInSet)
			Or ValueIsFilled(CurRow.ProductsInSet)
				And Not CurRow.SetContainsServices Then
			
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, CurRow);
			
			NewRow.CostDefiningMethod =
				?(ValueIsFilled(NewRow.DocumentSalesOfGoodsAndServices),
				Enums.WaysToCalculateReturnCost.FromSalesDocument,
				Enums.WaysToCalculateReturnCost.FromCurrentDocument);
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(
				NewRow,
				HeaderSelection.PriceIncludesVAT,
				False,
				False,
				True);
			
		EndIf;
	EndDo;
	
	PackageTable = QueryBatch[9].Unload();
	
	For Each CurrentRow In PackageTable Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurrentRow);
		
		NewRow.CostDefiningMethod =
			?(ValueIsFilled(NewRow.DocumentSalesOfGoodsAndServices),
			Enums.WaysToCalculateReturnCost.FromSalesDocument,
			Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(NewRow, HeaderSelection.PriceIncludesVAT, False, False, True);
	EndDo;
	
	FillInCCDNumbersOnOrders(HeaderSelection.PriceIncludesVAT);
	FillOutSettlements(SamplingBaseCalculations);
	
EndProcedure

Procedure FillInDocumentOnBasisOfRequestForReturnOfGoodsFromClient(Val DocumentBasis)
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("EmptyBatch_", Catalogs.ItemsBatches.EmptyRef());
	Query.Text =
	"SELECT
	|	RequestForReturnOfGoodsFromCustomer.Ref                AS RequestForReturnOfGoodsFromCustomer,
	|	RequestForReturnOfGoodsFromCustomer.Partner               AS Partner,
	|	RequestForReturnOfGoodsFromCustomer.DocumentSalesOfGoodsAndServices    AS DocumentSalesOfGoodsAndServices,
	|	RequestForReturnOfGoodsFromCustomer.CashRegisterReceipt                AS CashRegisterReceipt,
	|	RequestForReturnOfGoodsFromCustomer.Counterparty            AS Counterparty,
	|	RequestForReturnOfGoodsFromCustomer.ContactPerson        AS ContactPerson,
	|	RequestForReturnOfGoodsFromCustomer.Organization           AS Organization,
	|	RequestForReturnOfGoodsFromCustomer.Terms            AS Terms,
	|	RequestForReturnOfGoodsFromCustomer.Currency                AS Currency,
	|	RequestForReturnOfGoodsFromCustomer.Warehouse                 AS Warehouse,
	|	RequestForReturnOfGoodsFromCustomer.Department         AS Department,
	|	RequestForReturnOfGoodsFromCustomer.ReturnOfSpoiledGoods          AS ReturnOfSpoiledGoods,
	|	RequestForReturnOfGoodsFromCustomer.SalesOpportunity                AS SalesOpportunity,
	|	RequestForReturnOfGoodsFromCustomer.PriceIncludesVAT       AS PriceIncludesVAT,
	|	RequestForReturnOfGoodsFromCustomer.VATTaxation    AS VATTaxation,
	|	RequestForReturnOfGoodsFromCustomer.BusinessOperation AS BusinessOperation,
	|	RequestForReturnOfGoodsFromCustomer.Status                AS DocumentStatus,
	|	RequestForReturnOfGoodsFromCustomer.Contract               AS Contract,
	|	RequestForReturnOfGoodsFromCustomer.GoodsReceiptOption AS GoodsReceiptOption,
	|	
	|	CASE WHEN RequestForReturnOfGoodsFromCustomer.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods) THEN
	|		VALUE(Enum.CompensationMethodsForReturnsOfGoods.ReturnCash)
	|	ELSE
	|		RequestForReturnOfGoodsFromCustomer.CompensationMethod
	|	END AS CompensationMethod,
	|	
	|	NOT RequestForReturnOfGoodsFromCustomer.Posted           AS ThereAreErrorsPosted,
	|	RequestForReturnOfGoodsFromCustomer.ToReturnReusablePackage AS ReusablePackageReturn,
	|	RequestForReturnOfGoodsFromCustomer.PackageDepositIsRequired AS DepositForPackageIsRequired,
	|	RequestForReturnOfGoodsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	RequestForReturnOfGoodsFromCustomer.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
	|	ISNULL(RequestForReturnOfGoodsFromCustomer.Contract.ConsignmentSales25, FALSE) AS ContractCommissionSales25,
	|	RequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice       AS ThisIsOrderAsInvoice,
	|
	|	RequestForReturnOfGoodsFromCustomer.ReturnedBatch.(
	|		Products                                 AS Products,
	|		Characteristic                               AS Characteristic,
	|		Series                                        AS Series,
	|		Purpose                                   AS Purpose,
	|		Count                                   AS Count,
	|		DocumentSalesOfGoodsAndServices                           AS DocumentSalesOfGoodsAndServices,
	|		Warehouse                           			 AS Warehouse
	|	) AS SetOfSeries
	|
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|WHERE
	|	RequestForReturnOfGoodsFromCustomer.Ref = &DocumentBasis";
	
	HeaderSelection = Query.Execute().Select();
	HeaderSelection.Next();
	
	If HeaderSelection.ContractCommissionSales25 Then
		ErrorText = NStr("vi = 'Không thể lập chứng từ ""%1"" trên cơ sở lệnh %2 với hợp đồng ký gửi phiên bản %3. Để lập chứng từ trả lại. Để lập chứng từ trả lại, hãy sử dụng chứng từ ""%4""';
						|ru = 'Невозможно оформить документ ""%1"" на основании распоряжения %2 с договором комиссии версии %3. Для оформления возврата воспользуйтесь документом ""%4""';
						|en = 'Cannot register the ""%1"" document based on the %2 reference with the cross-company sales contract version %3. To register the return, use the ""%4"" document'; fa = 'Cannot register the ""%1"" document based on the %2 reference with the cross-company sales contract version %3. To register the return, use the ""%4"" document';
						|it = 'Impossibile registrare il documento ""%1"" in base all''ordine %2 con l''accordo di commissione della versione %3. Per la registrazione del reso utilizzare il documento ""%4""';
						|pl = 'Nie można utworzyć dokumentu ""%1"" na podstawie zamówienia %2 z umową komisową wersji %3. Aby utworzyć zwrot użyj dokumentu ""%4""';
						|tr = 'Komisyon sözleşmesi %3versiyonuna sahip bir %2emir temelinde bir ""%1"" belgesi düzenlemek mümkün değildir. İadeyi yapmak için ""%4"" belgesini kullanın'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
											Metadata.Documents.ReturnOfGoodsFromCustomer.Synonym,
											DocumentBasis,
											ConsignmentSalesServer.PostfixCommissionSchemes25(),
											Metadata.Documents.ReceiptOfGoodsFromCustodian.Synonym);
		
		Raise ErrorText;
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(DocumentBasis, "ReturnOfGoodsFromCustomer",
		HeaderSelection.BusinessOperation);
	
	Documents.RequestForReturnOfGoodsFromCustomer.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.RequestForReturnOfGoodsFromCustomer,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		True);
	
	Query.SetParameter("ThisIsOrderAsInvoice", HeaderSelection.ThisIsOrderAsInvoice);
	
	// Filling in the header.
	FillPropertyValues(ThisObject, HeaderSelection);
	
	SetOfSeries.Load(HeaderSelection.SetOfSeries.Unload());
	
	// Filling in PM goods.
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &DocumentBasis";
	TableFormationParameters.Group = "Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = TableFormationParameters.Group;
	TableFormationParameters.TempTableName = "TT_RequestsForReturnsTurnoverExpanded";
	
	TT_RequestsForReturnsTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = TT_RequestsForReturnsTurnoverExpanded +
	Common.QueryBatchSeparator() +
	"SELECT
	|	ApplicationProducts.LineNumber AS LineNumber,
	|	ApplicationProducts.ProductsInSet AS ProductsInSet,
	|	ApplicationProducts.ItemVariantOfSet AS ItemVariantOfSet,
	|	ApplicationProducts.Products AS Products,
	|	ApplicationProducts.Characteristic AS Characteristic,
	|	ApplicationProducts.Series AS Series,
	|	ApplicationProducts.Purpose AS Purpose,
	|	ApplicationProducts.Count AS QuantityInApplication,
	|	ApplicationProducts.Damage AS Damage,
	|	ApplicationProducts.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	ApplicationProducts.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	ApplicationProducts.RowCode AS RowCode,
	|	CASE
	|		WHEN ApplicationProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS ZoomRatio,
	|	ApplicationProducts.Package AS Package,
	|	ApplicationProducts.Price AS Price,
	|	ApplicationProducts.VATRate AS VATRate,
	|	(RequestsForReturnOfGoodsFromCustomers.ForRegistrationOnReturnsQuantityTurnover -
	|		RequestsForReturnOfGoodsFromCustomers.IssuedByReturnsQuantityTurnover) AS Count,
	|	ApplicationProducts.NumberOfPackages AS NumberOfPackages,
	|	ApplicationProducts.Sum AS Sum,
	|	ApplicationProducts.Warehouse AS Warehouse,
	|	ApplicationProducts.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|INTO ApplicationProducts
	|FROM
	|	TT_RequestsForReturnsTurnoverExpanded AS RequestsForReturnOfGoodsFromCustomers
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS ApplicationProducts
	|		ON (ApplicationProducts.Ref = &DocumentBasis)
	|			AND RequestsForReturnOfGoodsFromCustomers.RowCode = ApplicationProducts.RowCode
	|			AND (RequestsForReturnOfGoodsFromCustomers.Products = CASE
	|				WHEN ApplicationProducts.Damage
	|					THEN ApplicationProducts.ProductsRecordingAsReceived
	|				ELSE ApplicationProducts.Products
	|			END)
	|			AND (RequestsForReturnOfGoodsFromCustomers.Characteristic = CASE
	|				WHEN ApplicationProducts.Damage
	|					THEN ApplicationProducts.CharacteristicRecordingAsReceived
	|				ELSE ApplicationProducts.Characteristic
	|			END)
	|WHERE
	|	(RequestsForReturnOfGoodsFromCustomers.ForRegistrationOnReturnsQuantityTurnover -
	|		RequestsForReturnOfGoodsFromCustomers.IssuedByReturnsQuantityTurnover) > 0
	|		AND NOT &ThisIsOrderAsInvoice
	|
	|UNION ALL
	|
	|SELECT
	|	ApplicationProducts.LineNumber AS LineNumber,
	|	ApplicationProducts.ProductsInSet AS ProductsInSet,
	|	ApplicationProducts.ItemVariantOfSet AS ItemVariantOfSet,
	|	ApplicationProducts.Products AS Products,
	|	ApplicationProducts.Characteristic AS Characteristic,
	|	ApplicationProducts.Series AS Series,
	|	ApplicationProducts.Purpose AS Purpose,
	|	ApplicationProducts.Count AS QuantityInApplication,
	|	ApplicationProducts.Damage AS Damage,
	|	ApplicationProducts.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	ApplicationProducts.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	ApplicationProducts.RowCode AS RowCode,
	|	CASE
	|		WHEN ApplicationProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END AS ZoomRatio,
	|	ApplicationProducts.Package AS Package,
	|	ApplicationProducts.Price AS Price,
	|	ApplicationProducts.VATRate AS VATRate,
	|	ApplicationProducts.Count AS Count,
	|	ApplicationProducts.NumberOfPackages AS NumberOfPackages,
	|	ApplicationProducts.Sum AS Sum,
	|	ApplicationProducts.Warehouse AS Warehouse,
	|	ApplicationProducts.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS ApplicationProducts
	|
	|WHERE
	|	ApplicationProducts.Ref = &DocumentBasis
	|		AND &ThisIsOrderAsInvoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ApplicationProducts.LineNumber AS LineNumber,
	|	ApplicationProducts.ProductsInSet AS ProductsInSet,
	|	ApplicationProducts.ItemVariantOfSet AS ItemVariantOfSet,
	|	ApplicationProducts.Products AS Products,
	|	ApplicationProducts.Characteristic AS Characteristic,
	|	ApplicationProducts.Series AS Series,
	|	ApplicationProducts.Purpose AS Purpose,
	|	ApplicationProducts.QuantityInApplication AS QuantityInApplication,
	|	ApplicationProducts.Damage AS Damage,
	|	ApplicationProducts.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	ApplicationProducts.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	ApplicationProducts.RowCode AS RowCode,
	|	ApplicationProducts.ZoomRatio,
	|	ApplicationProducts.Package AS Package,
	|	ApplicationProducts.Price AS Price,
	|	ApplicationProducts.VATRate AS VATRate,
	|	ApplicationProducts.Count AS Count,
	|	ApplicationProducts.NumberOfPackages AS NumberOfPackages,
	|	ApplicationProducts.Sum AS Sum,
	|	ApplicationProducts.Warehouse AS Warehouse,
	|	ApplicationProducts.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|FROM
	|	ApplicationProducts AS ApplicationProducts
	|
	|ORDER BY
	|	ApplicationProducts.LineNumber
	|";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ApplicationProducts.Package",
		"ApplicationProducts.Products"));
	
	Query.Text = QueryText;
	SampleProducts_ = Query.Execute().Select();
	
	While SampleProducts_.Next() Do
		
		TabRow = Goods.Add();
		
		FillPropertyValues(TabRow, SampleProducts_, "ProductsInSet, ItemVariantOfSet,
			|Products, Characteristic, Series, Warehouse, Purpose, Package, RowCode, Price, VATRate, DocumentSalesOfGoodsAndServices");
		
		//@skip-check bsl-legacy-check-string-literal
		If Not ValueIsFilled(TabRow.DocumentSalesOfGoodsAndServices)
			And Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation") =
				Enums.BusinessTransactions.ReturnFromRetailCustomer Then
			TabRow.DocumentSalesOfGoodsAndServices = DocumentSalesOfGoodsAndServices;
		EndIf;
		
		TabRow.Count         = SampleProducts_.Count;
		TabRow.NumberOfPackages = SampleProducts_.Count / SampleProducts_.ZoomRatio;
		If SampleProducts_.QuantityInApplication = TabRow.Count Then
			TabRow.Sum = SampleProducts_.Sum;
		Else
			TabRow.Sum = TabRow.NumberOfPackages * TabRow.Price;
		EndIf; 
		TabRow.VATAmount           = PriceManagementSystemClientServer.CalculateVATAmount(TabRow.Sum, TabRow.VATRate, PriceIncludesVAT);
		TabRow.AmountIncludingVAT          = ?(PriceIncludesVAT, TabRow.Sum, TabRow.Sum+TabRow.VATAmount);
		
		If SampleProducts_.Damage
			And BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			
			FillPropertyValues(TabRow, SampleProducts_, "Damage, ProductsRecordingAsReceived, CharacteristicRecordingAsReceived")
			
		EndIf;
		
		TabRow.CostDefiningMethod = ?(ValueIsFilled(TabRow.DocumentSalesOfGoodsAndServices),
				Enums.WaysToCalculateReturnCost.FromSalesDocument,
				Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		
	EndDo;
	
	FillInCCDNumbersOnOrders(HeaderSelection.PriceIncludesVAT);
	
	If Goods.Count() = 0 Then
		
		MessageText = NStr("vi = 'Không có dữ liệu để điền theo chứng từ ""%Request%"" .';
							|ru = 'Нет данных для заполнения по документу ""%Request%"" .';
							|en = 'No data for population by document ""%Request%"".'; fa = 'No data for population by document ""%Request%"".';
							|it = 'Nessun dato da compilare nel documento ""%Request%"".';
							|pl = 'Brak danych do wypełnienia według dokumentu ""%Request%"" .';
							|tr = '""%Request%"" belgesi için doldurulacak veri yok.'");
		MessageText = StrReplace(MessageText, "%Request%", HeaderSelection.RequestForReturnOfGoodsFromCustomer);
		Common.MessageToUser(MessageText, ThisObject, "RequestForReturnOfGoodsFromCustomer");
		
	Else
		
		FillInARAPAccountsForReturnRequests(DocumentBasis);
		
	EndIf;
	
	SetPrivilegedMode(False);

EndProcedure

Procedure FillInDocumentOnBasisOfTransferredContainer(Val DetailsOfFillingInForm)
	
	FillPropertyValues(ThisObject, DetailsOfFillingInForm.HeaderAttributes);
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		If Not ValueIsFilled(Terms) Then
			FillInDefaultSalesConditions();
		EndIf;
	Else
		
		If DetailsOfFillingInForm.HeaderAttributes.PriceIncludesVAT = Undefined Then
			
			DetailsOfDefaultPrice = Catalogs.TypesOfPrices.PriceTypeAndPriceIncludesVATAttributeByDefault(
				New Structure("UseWhileSellingToCustomers", True),
				Documents.ReturnOfGoodsFromCustomer.EmptyRef());
			
			FillPropertyValues(ThisObject, DetailsOfDefaultPrice);
		EndIf;
		
	EndIf;
	
	ReusablePackageReturn = True;
	DepositForPackageIsRequired = DetailsOfFillingInForm.HeaderAttributes.DepositForPackageIsRequired;
	
	If IsTempStorageURL(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage) Then
		
		TransferredPackage = GetFromTempStorage(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage);
		Goods.Load(TransferredPackage);
		
		For Each CurrentRow In Goods Do
			
			CurrentRow.AmountIncludingVAT = CurrentRow.Sum;
			CurrentRow.NumberOfPackages = CurrentRow.Count;
			CurrentRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
			CurrentRow.CostDefiningMethod = ?(ValueIsFilled(CurrentRow.DocumentSalesOfGoodsAndServices),
				Enums.WaysToCalculateReturnCost.FromSalesDocument,
				Enums.WaysToCalculateReturnCost.FromCurrentDocument);
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, PriceIncludesVAT, False, False, True);
			
		EndDo;
		
	EndIf;
	
	FillInCCDNumbersOnOrders(PriceIncludesVAT);
	
	// We will fill out mutual settlements.
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
	
		Query = New Query(
		"SELECT DISTINCT
		|	GoodsTable.ARAPObject AS ARAPObject
		|INTO ARAPObjects
		|FROM
		|	Document.CustomerInvoice.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref  IN (&BasisDocuments)
		|	AND GoodsTable.Ref.OrderSales
		|	AND GoodsTable.SalesOrder <> UNDEFINED
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
		|	CustomersARAPAccounting.Currency AS ARAPCurrency,
		|	ISNULL(CustomersARAPAccounting.SumBalance, 0) AS SumBalance
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(
		|			,
		|			ARAPObject IN
		|				(SELECT
		|					ARAPObject
		|				FROM
		|					ARAPObjects)) AS CustomersARAPAccounting
		|;
		|");
		
		Query.SetParameter("BasisDocuments", Goods.UnloadColumn("DocumentSalesOfGoodsAndServices"));
		QueryResult = Query.Execute();
		SamplingBaseCalculations = QueryResult.Select();
		
		AmountForAllocation = GetDocumentAmount();
		
		While AmountForAllocation > 0 And SamplingBaseCalculations.Next() Do
			
			If SamplingBaseCalculations.SumBalance > 0 Then
				
				NewRow = ARAPDetails.Add();
				NewRow.ARAPCurrency = SamplingBaseCalculations.ARAPCurrency;
				NewRow.ARAPObject = SamplingBaseCalculations.ARAPObject;
				
				If AmountForAllocation > SamplingBaseCalculations.SumBalance Then
					NewRow.Sum = SamplingBaseCalculations.SumBalance;
				Else
					NewRow.Sum = AmountForAllocation;
				EndIf;
				
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				
			EndIf;
			
		EndDo;
		
		If AmountForAllocation > 0 Then
			
			NewRow = ARAPDetails.Add();
			NewRow.ARAPCurrency = Currency;
			NewRow.Sum = AmountForAllocation;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfActAfterShipment(Val FillingData)
	
	SetPrivilegedMode(True);
	
	QueryText = Documents.DiscrepancyReportFollowingShipment.RequestTextForOverDeliveredGoods();
	Query = New Query(QueryText);
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[1].Select();
	SamplingBaseCalculations = QueryBatch[2].Select();
	
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	BusinessOperation = SalesServer.GetRefundTransactionForSale(HeaderSelection.EconomicOperationImplementation);
	
	TableOfGoods = QueryBatch[12].Unload();
	
	For Each CurRow In TableOfGoods Do
			
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		NewRow.CostDefiningMethod = ?(ValueIsFilled(NewRow.DocumentSalesOfGoodsAndServices),
				Enums.WaysToCalculateReturnCost.FromSalesDocument,
				Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		PriceManagementSystem.RecalculateAmountsInRow(
			NewRow,
			False,
			False,
			False,
			HeaderSelection.PriceIncludesVAT);
		
	EndDo;
	
	FillOutSettlements(SamplingBaseCalculations);
	
EndProcedure

Procedure FillInDocumentOnBasisOfActAfterAcceptance(FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ReturnOfGoodsFromCustomer.Ref                              AS AdditionalReturnWithinGoodsReturn,
	|	DiscrepancyReportFollowingReceipt.Ref                         AS DiscrepancyCertificate,
	|	ReturnOfGoodsFromCustomer.Terms                          AS Terms,
	|	ReturnOfGoodsFromCustomer.Organization                         AS Organization,
	|	ReturnOfGoodsFromCustomer.Partner                             AS Partner,
	|	ReturnOfGoodsFromCustomer.Counterparty                          AS Counterparty,
	|	ReturnOfGoodsFromCustomer.Currency                              AS Currency,
	|	ReturnOfGoodsFromCustomer.SalesOpportunity                              AS SalesOpportunity,
	|	ReturnOfGoodsFromCustomer.Department                       AS Department,
	|	ReturnOfGoodsFromCustomer.DocumentSalesOfGoodsAndServices                  AS DocumentSalesOfGoodsAndServices,
	|	ReturnOfGoodsFromCustomer.Warehouse                               AS Warehouse,
	|	ReturnOfGoodsFromCustomer.BusinessOperation               AS BusinessOperation,
	|	ReturnOfGoodsFromCustomer.RequestForReturnOfGoodsFromCustomer     AS RequestForReturnOfGoodsFromCustomer,
	|	ReturnOfGoodsFromCustomer.PriceIncludesVAT                     AS PriceIncludesVAT,
	|	ReturnOfGoodsFromCustomer.VATTaxation                  AS VATTaxation,
	|	ReturnOfGoodsFromCustomer.Contract                             AS Contract,
	|	ReturnOfGoodsFromCustomer.ReasonForReturn                     AS ReasonForReturn,
	|	ReturnOfGoodsFromCustomer.ReusablePackageReturn AS ReusablePackageReturn,
	|	ReturnOfGoodsFromCustomer.DepositForPackageIsRequired             AS DepositForPackageIsRequired,
	|	ReturnOfGoodsFromCustomer.CompensationMethod                   AS CompensationMethod,
	|	NOT ReturnOfGoodsFromCustomer.Posted                         AS ThereAreErrorsAndGrounds,
	|	NOT DiscrepancyReportFollowingReceipt.Posted                    AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.Status                         AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingReceipt.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)) AS ThereAreErrorsStatusReport
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|		ON (TRUE)
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
	|	ON
	|		ReturnOfGoodsFromCustomer.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
	|		AND RegisterOfDocumentsStornoCorrection.Posted
	|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Products           AS Products,
	|	DiscrepancyReportFollowingReceipt.Characteristic         AS Characteristic,
	|	DiscrepancyReportFollowingReceipt.Purpose             AS Purpose,
	|	DiscrepancyReportFollowingReceipt.Warehouse                  AS Warehouse,
	|	DiscrepancyReportFollowingReceipt.Series                  AS Series,
	|	DiscrepancyReportFollowingReceipt.BatchesIndicationStatus    AS BatchesIndicationStatus,
	|	DiscrepancyReportFollowingReceipt.Package               AS Package,
	|	DiscrepancyReportFollowingReceipt.Price                   AS Price,
	|	DiscrepancyReportFollowingReceipt.VATRate              AS VATRate,
	|	DiscrepancyReportFollowingReceipt.DocumentSalesOfGoodsAndServices     AS DocumentSalesOfGoodsAndServices,
	|	DiscrepancyReportFollowingReceipt.RowCode              AS RowCode,
	|	DiscrepancyReportFollowingReceipt.CCDNumber               AS CCDNumber,
	|
	|	SUM(DiscrepancyReportFollowingReceipt.CountByDocument - DiscrepancyReportFollowingReceipt.Count)                 AS Count,
	|	SUM(DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages) AS NumberOfPackages,
	|	SUM(DiscrepancyReportFollowingReceipt.SumByDocument - DiscrepancyReportFollowingReceipt.Sum)                           AS Sum,
	|	SUM(DiscrepancyReportFollowingReceipt.VATAmountByDocument - DiscrepancyReportFollowingReceipt.VATAmount)                     AS VATAmount,
	|	SUM(DiscrepancyReportFollowingReceipt.AmountIncludingVATByDocument - DiscrepancyReportFollowingReceipt.AmountIncludingVAT)                   AS AmountIncludingVAT
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
	|	AND DiscrepancyReportFollowingReceipt.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages > 0
	|
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse,
	|	Series,
	|	BatchesIndicationStatus,
	|	Package,
	|	Price,
	|	VATRate,
	|	DocumentSalesOfGoodsAndServices,
	|	RowCode,
	|	CCDNumber
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products                                                                 AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic                                                               AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse                                                                        AS Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series                                                                        AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose                                                                   AS Purpose,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument - DiscrepancyReportFollowingReceiptSetOfSeries.Count)  AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument - DiscrepancyReportFollowingReceiptSetOfSeries.Count > 0
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|
	|SELECT DISTINCT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|
	|INTO ReturnImplementations
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &DocumentBasis
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages > 0
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////4
	|
	|SELECT
	|	CatalogARAPObjects.Ref AS ARAPObject
	|INTO ARAPObjects
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|		INNER JOIN Catalog.ARAPObjects AS CatalogARAPObjects
	|			ON CatalogARAPObjects.Object = DiscrepancyReportFollowingReceipt.Contract
	|				AND NOT CatalogARAPObjects.DeletionMark
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|
	|UNION ALL
	|
	|SELECT
	|	SalesOfGoodsServicesGoods.ARAPObject AS ARAPObject
	|FROM
	|Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|WHERE
	|	SalesOfGoodsServicesGoods.Ref IN
	|		(SELECT
	|			ReturnImplementations.DocumentSalesOfGoodsAndServices
	|		FROM
	|			ReturnImplementations AS ReturnImplementations)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////5
	|SELECT
	|	CustomersARAPAccounting.ARAPObject            AS ARAPObject,
	|	CustomersARAPAccounting.Currency                    AS ARAPCurrency,
	|	ISNULL(CustomersARAPAccounting.SumBalance, 0) AS SumBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|			,
	|			ARAPObject IN
	|				(SELECT
	|					ARAPObject
	|				FROM
	|					ARAPObjects)) AS CustomersARAPAccounting";
	
	SetPrivilegedMode(True);
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	QueryBatch = Query.ExecuteBatch();
	
	SetPrivilegedMode(True);
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	// According to the return document
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.AdditionalReturnWithinGoodsReturn,
		,
		HeaderSelection.ThereAreErrorsAndGrounds,
		,
		);
		
	// According to the act of discrepancies
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DiscrepancyCertificate,
		HeaderSelection.StatusOfDivergenceReport,
		HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		HeaderSelection.ThereAreErrorsStatusReport,
		DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn());
		
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = QueryBatch[1].Unload();
	
	For Each CurRow In TableOfGoods Do
			
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		NewRow.CostDefiningMethod = ?(ValueIsFilled(NewRow.DocumentSalesOfGoodsAndServices),
				Enums.WaysToCalculateReturnCost.FromSalesDocument,
				Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		PriceManagementSystem.RecalculateAmountsInRow(
			NewRow,
			False,
			False,
			False,
			HeaderSelection.PriceIncludesVAT);
		
	EndDo;
		
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	SamplingBaseCalculations = QueryBatch[5].Select();
	FillOutSettlements(SamplingBaseCalculations);
	
EndProcedure

Procedure FillInFromOrder(FillingStructure)
	
	AnArrayOfOrders = FillingStructure.AnArrayOfOrders;
	
	If FillingStructure.Property("Warehouse") And ValueIsFilled(FillingStructure.Warehouse) Then
		FillingStructure.HeaderAttributes.Warehouse = FillingStructure.Warehouse;
	EndIf;
	
	If FillingStructure.HeaderAttributes.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		FillingStructure.HeaderAttributes.CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash;
	EndIf;
	
	FillParameters = Documents.ReturnOfGoodsFromCustomer.DocumentFillingParameters();
	FillPropertyValues(FillParameters, FillingStructure);
	Documents.ReturnOfGoodsFromCustomer.InitializeFillingParameters(FillParameters,
		FillingStructure.HeaderAttributes, AnArrayOfOrders);
	
	If FillingStructure.Property("FillByWarehouseDocument") Then
		FillParameters.FillByWarehouseDocument = FillingStructure.FillByWarehouseDocument;
	Else
		OriginWarehouse = FillingStructure.HeaderAttributes.Warehouse;
		UseAdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(OriginWarehouse, CurrentSessionDate());
		
		RegistrationProcedure = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
		OrdersFirst = (RegistrationProcedure = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst);
		
		FillParameters.FillByWarehouseDocument = UseAdvancedWarehousing And OrdersFirst;
	EndIf;
	
	InvoiceTable = Documents.ReturnOfGoodsFromCustomer.TableDataAndDocument(Ref);
	TableOfBarcodesOfPackages = ReturnOfGoodsFromCustomerLocalization.ToFormStructureOfBarcodesOfPackages();
	
	Documents.ReturnOfGoodsFromCustomer.FillInByOrdersOrders(InvoiceTable, Ref, FillParameters, TableOfBarcodesOfPackages);
	
	TableOverheadColumnQuantity        = InvoiceTable.Columns.Count; // ValueTableColumn
	InvoiceTableColumnsQuantityInOrder_ = InvoiceTable.Columns.NoteQuantity; // ValueTableColumn
	InvoiceTableColumnsQuantityInOrder = InvoiceTable.Columns.QuantityInOrder; // ValueTableColumn
	
	If FillParameters.FillByWarehouseDocument Then
		TableOverheadColumnQuantity.Name        = "QuantityBeforeChange_";
		InvoiceTableColumnsQuantityInOrder_.Name = "Count";
	Else
		TableOverheadColumnQuantity.Name        = "QuantityBeforeChange_";
		InvoiceTableColumnsQuantityInOrder.Name = "Count";
	EndIf;
	
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	Goods.Load(InvoiceTable);
	
	For Each CurRow In Goods Do
		
		If Not ValueIsFilled(CurRow.CostDefiningMethod) Then
			CurRow.CostDefiningMethod = ?(ValueIsFilled(CurRow.DocumentSalesOfGoodsAndServices),
				Enums.WaysToCalculateReturnCost.FromSalesDocument,
				Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		EndIf;
			
	EndDo;
	
	If FillParameters.FillByWarehouseDocument And TableOfBarcodesOfPackages.Count() > 0 Then
		PackageBarcodes.Load(TableOfBarcodesOfPackages);
	EndIf; 
	
	FillInCCDNumbersOnOrders(FillingStructure.HeaderAttributes.PriceIncludesVAT);
	
	Documents.ReturnOfGoodsFromCustomer.FillInHeaderOfOrderDocument(ThisObject, FillParameters, FillingStructure.AnArrayOfOrders);
	
	Documents.ReturnOfGoodsFromCustomer.UpdateDependentDetailsOfTablePart(Goods, FillParameters, False);
	
	FillInARAPAccountsForReturnRequests(AnArrayOfOrders);
	
EndProcedure

#EndRegion

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author                = Users.CurrentUser();
	DocumentBasis = SalesServer.DocumentBasis(ThisObject,
		"RequestForReturnOfGoodsFromCustomer, DocumentSalesOfGoodsAndServices, Goods.DocumentSalesOfGoodsAndServices");
	ResponsiblePersonsServer.InstallManager(ThisObject, DocumentBasis);
	Organization          = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Warehouse                = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department        = SettingsValueCached.UserDivision(Manager, Department);
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(RequestForReturnOfGoodsFromCustomer);
	
	FillParameters = Documents.ReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = 
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(
			ThisObject, False, ReusablePackageReturn);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);
	
	If ValueIsFilled(DocumentSalesOfGoodsAndServices) Then
		StructureOfFillingInVATRate.Date = Common.ObjectAttributeValue(DocumentSalesOfGoodsAndServices, "Date");
	EndIf;
	
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
			
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	InventoryTypesAreOverfilled = False;
	
	DocumentProducts			= CommonClientServer.CollapseArray(Goods.UnloadColumn("Products"));
	MatchingItemTypes	= Common.ObjectsAttributeValue(DocumentProducts, "ItemsType");
	
	DocumentContainsGoods			= True;
	DocumentContainsNegotiableContainer	= False;
	
	If ReusablePackageReturn Then
		DocumentContainsGoods			= DocumentContainsItemType(MatchingItemTypes,
																			Enums.ItemsTypes.OwnGoods);
		DocumentContainsNegotiableContainer	= DocumentContainsItemType(MatchingItemTypes,
																			Enums.ItemsTypes.ReusablePackage);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
		TempTablesManager = TemporaryDocumentDataTables("All");
		
		If Not Posted
			Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.SelectTypesOfStocksForIntercampany = False;
			FillParameters.ReportFillingErrors = True;
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
			
			Filters = FillParameters.SelectionOfStockTypes_;
			Filters.Organization = Organization;
			Filters.VATTaxation = VATTaxation;
			
			FillParameters.NameOfRemainderTable = "GoodsTransferredToCommissionAgent";
			
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
			
			If Not Cancel Then
				InventoryTypesAreOverfilled = True;
			EndIf;
			
		EndIf;
		
	Else
		
		RowFilter = New Structure("CostDefiningMethod",
									Enums.WaysToCalculateReturnCost.FromSalesDocument);
		AccordingToSaleDocuments = Goods.FindRows(RowFilter);
		
		ThereAreOnSaleDocuments		= AccordingToSaleDocuments.Count() > 0;
		ThereAreUndocumentedSales	= AccordingToSaleDocuments.Count() <> Goods.Count();
		
		TempTablesManager = TemporaryDocumentDataTables("FromSalesDocument");
		
		If Not Posted
			Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			ManagerOfTemporaryProductTables	= ?(DocumentContainsGoods,
												?(ReusablePackageReturn,
													TemporaryDocumentDataTables("FromSalesDocument", "Products"),
													TempTablesManager),
												Undefined);
			ManagerOfTemporaryTareTables		= ?(DocumentContainsNegotiableContainer,
												TemporaryDocumentDataTables("FromSalesDocument", "Tara"),
												Undefined);
			
			If ThereAreUndocumentedSales Then
				RowFilter = New Structure("CostDefiningMethod",
											Enums.WaysToCalculateReturnCost.Manually);
				TypesOfStocksWithoutSaleDocuments = InventoryKinds.Unload(RowFilter);
				
				RowFilter = New Structure("CostDefiningMethod",
											Enums.WaysToCalculateReturnCost.FromCurrentDocument);
				
				TMCommonUse.AddRowsToTable(TypesOfStocksWithoutSaleDocuments,
															InventoryKinds.Unload(RowFilter));
				InventoryKinds.Clear();
			EndIf;
			
			If DocumentContainsGoods Then
				FillParameters = ParametersForFillingTypesOfInventoryAccordingToSalesDocuments();
				FillParameters.NameOfRemainderTable = "SoldGoods";
				If Documents.ReturnOfGoodsFromCustomer.ExcisableGoodsAreUsed(ThisObject) Then
					AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
					FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
				EndIf;
				InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																		ManagerOfTemporaryProductTables,
																		Cancel,
																		FillParameters);
			EndIf;
			
			If DocumentContainsNegotiableContainer Then
				TypesOfStocksOfGoods = TypesOfStocksOfGoods();
				
				FillParameters = ParametersForFillingTypesOfInventoryAccordingToSalesDocuments();
				FillParameters.NameOfRemainderTable = "TransferredReturnablePackaging";
				
				InventoryKinds.Clear();
				
				InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																		ManagerOfTemporaryTareTables,
																		Cancel,
																		FillParameters);
				
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksOfGoods);
			EndIf;
			
			If Not Cancel Then
				InventoryTypesAreOverfilled = True;
			EndIf;
			
			For Each TableRow In InventoryKinds Do
				TableRow.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromSalesDocument;
			EndDo;
			
			If ThereAreUndocumentedSales Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksWithoutSaleDocuments);
			EndIf;
		ElsIf Documents.ReturnOfGoodsFromCustomer.ExcisableGoodsAreUsed(ThisObject)
			And LineOfBusiness <> Common.ObjectAttributeValue(Ref, "LineOfBusiness") Then
			AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
		EndIf;
		
		TempTablesManager = TemporaryDocumentDataTables("NotFromSalesDocument");
		
		If Not Posted
			Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
			Or CheckChangesToDocumentDetails(TempTablesManager, "NotFromSalesDocument")
			Or CheckProductChanges_(TempTablesManager) Then
			
			If ThereAreOnSaleDocuments Then
				RowFilter = New Structure("CostDefiningMethod",
											Enums.WaysToCalculateReturnCost.FromSalesDocument);
				TypesOfStocksAccordingToSaleDocuments = InventoryKinds.Unload(RowFilter);
				
				InventoryKinds.Clear();
			EndIf;
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.SelectTypesOfStocksForIntercampany = False;
			FillParameters.ReportFillingErrors = False;
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
			
			Filters = FillParameters.SelectionOfStockTypes_;
			Filters.Organization = Organization;
			Filters.VATTaxation = VATTaxation;
			
			VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(FillParameters.SelectionOfStockTypes_,
																		Organization,
																		Date,
																		VATTaxation);
			
			FillParameters.NameOfRemainderTable = "TableTypesOfStocks_";
			If SubjectToExcise
				And Documents.ReturnOfGoodsFromCustomer.ExcisableGoodsAreUsed(ThisObject) Then
				
				AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
				FillParameters.CalculateAmountOfExciseTax = True;
				Filters.SubjectToExcise.Clear();
				
			EndIf;
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject, TempTablesManager, Cancel, FillParameters);
			
			If Not Cancel Then
				InventoryTypesAreOverfilled = True;
			EndIf;
			ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
			If ThereAreOnSaleDocuments Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksAccordingToSaleDocuments);
			EndIf;
		ElsIf SubjectToExcise
			And Documents.ReturnOfGoodsFromCustomer.ExcisableGoodsAreUsed(ThisObject)
			And LineOfBusiness <> Common.ObjectAttributeValue(Ref, "LineOfBusiness") Then
			AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
		EndIf;
		
	EndIf;
	
	If InventoryTypesAreOverfilled Then
		TMCommonUse.CollapseTablePart(ThisObject, "InventoryKinds");
		
		FillInCostOfInventoryTypes(MatchingItemTypes, DocumentContainsNegotiableContainer, Cancel);
		FillInInventoryTypeProductList(Cancel);
	EndIf;
	
EndProcedure

Function DocumentContainsItemType(MatchingItemTypes, ItemsType)
	
	DocumentContainsItemType = False;
	
	For Each MapData In MatchingItemTypes Do
		If MapData.Value = ItemsType Then
			DocumentContainsItemType = True;
			
			Break;
		EndIf;
	EndDo;
	
	Return DocumentContainsItemType;
	
EndFunction

Function ParametersForFillingTypesOfInventoryAccordingToSalesDocuments()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.SelectTypesOfStocksForIntercampany = False;
	FillParameters.ReportFillingErrors = True;
	FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
	FillParameters.SelectionOfStockTypes_.Organization = Organization;
	
	Return FillParameters;
	
EndFunction

Function TypesOfStocksOfGoods()
	
	TypesOfStocksOfGoods = InventoryKinds.UnloadColumns();
	
	If InventoryKinds.Count() = 0 Then
		Return TypesOfStocksOfGoods;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes
	|INTO TableTypesOfStocks_
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON Dimension.Products = ProductData_1.Ref
	|
	|WHERE
	|	ProductData_1.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)";
	
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		NewRow = TypesOfStocksOfGoods.Add();
		FillPropertyValues(NewRow, InventoryKinds[Selection.LineNumber - 1]);
	EndDo;
	
	Return TypesOfStocksOfGoods;
	
EndFunction

Procedure FillInInventoryTypeProductList(Cancel)
	
	If Cancel
		Or Not ReturnOfSpoiledGoods Then
		
		Return;
		
	EndIf;
	ListOfInventoryOwnerAttributes = InventoryKinds.UnloadColumn("InventoryOwnerAttribute");
	ListOfInventoryOwnerAttributes = CommonClientServer.CollapseArray(ListOfInventoryOwnerAttributes);
	
	InventoryWriteOffData	= Common.ObjectsAttributeValue(ListOfInventoryOwnerAttributes, "SubjectToExcise");
	ExciseLines		= New Array;
	TheStructureOfTheSearch	= New Structure("ItemsLocationAttributes");
	RowFilter		= New Structure("Damage", True);
	ArrayOfProducts_2	= Goods.FindRows(RowFilter);
	
	TransferredInventoryOwnerAttributes	= New Array;
	
	For Each RowOfGoods In ArrayOfProducts_2 Do
		
		GoodsQuantity	= RowOfGoods.Count;
		AmountIncludingVAT			= RowOfGoods.AmountIncludingVAT;
		VATAmount			= RowOfGoods.VATAmount;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ProductsRecordingAsReceived	= RowOfGoods.ProductsRecordingAsReceived;
			NewRow.CharacteristicRecordingAsReceived	= RowOfGoods.CharacteristicRecordingAsReceived;
			NewRow.Count					= Count;
			NewRow.AmountIncludingVAT					= Min(AmountIncludingVAT,
														?(InventoryLine.Count <> 0,
															Count * InventoryLine.AmountIncludingVAT / InventoryLine.Count,
															0));
			NewRow.VATAmount					= Min(VATAmount,
														?(InventoryLine.Count <> 0,
															Count * InventoryLine.VATAmount / InventoryLine.Count,
															0));
			NewRow.ExciseTaxAmount					= Count * InventoryLine.ExciseTaxAmount / InventoryLine.Count;
			InventoryLine.Count	= InventoryLine.Count - NewRow.Count;
			InventoryLine.AmountIncludingVAT		= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount		= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.ExciseTaxAmount	= InventoryLine.ExciseTaxAmount - NewRow.ExciseTaxAmount;
			
			If InventoryWriteOffData.Get(InventoryLine.InventoryOwnerAttribute) Then
				ExciseLines.Add(RowOfGoods.LineNumber);
			EndIf;
			GoodsQuantity	= GoodsQuantity - NewRow.Count;
			AmountIncludingVAT			= AmountIncludingVAT - NewRow.AmountIncludingVAT;
			VATAmount			= VATAmount - NewRow.VATAmount;
			
			TransferredInventoryOwnerAttributes.Add(InventoryLine.InventoryOwnerAttribute);
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	CheckCorrectnessOfIndicationOfExciseCategories(ExciseLines, Cancel);
	SynchronizePropertiesOfInventoryOwnerAttributesOfAccount(TransferredInventoryOwnerAttributes, Cancel);
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ReturnOfGoodsFromCustomer.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ReturnOfGoodsFromCustomer.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Partner,
																		Contract);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	// If the Warehouse is a group, then for the analysis of the inventory item, we take the warehouse from PM
	WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
	
	If ValueIsFilled(Warehouse)
		And WarehouseDetails.IsFolder
		And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
		
		FieldsNames.Insert("Arbitrary", "Warehouse");
		
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	InformationRegisters.SetAccountingDimension.FillInCollection(GoodsTable);
	
EndProcedure

Procedure InitializeAnalyticsKeysForTransferredContainerToClient()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|	&Partner											AS Warehouse
	|INTO GoodsTable
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.CostDefiningMethod IN(&CostDefiningMethods)
	|
	|;
	|///////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsTable.Products		AS Products,
	|	GoodsTable.Characteristic	AS Characteristic,
	|	GoodsTable.Series				AS Series,
	|	GoodsTable.Purpose		AS Purpose,
	|	GoodsTable.Warehouse				AS Warehouse
	|FROM
	|	GoodsTable AS GoodsTable
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON GoodsTable.Products = CatProducts.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS ContainerAnalytics
	|		ON GoodsTable.Products = ContainerAnalytics.Products
	|			AND GoodsTable.Characteristic = ContainerAnalytics.Characteristic
	|			AND GoodsTable.Purpose = ContainerAnalytics.Purpose
	|			AND ContainerAnalytics.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
	|			AND GoodsTable.Series = ContainerAnalytics.Series
	|			AND GoodsTable.Warehouse = ContainerAnalytics.StorageLocation
	|
	|WHERE
	|	CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND ContainerAnalytics.DimensionKey IS NULL
	|";
	
	CostDefiningMethods = 	New Array;
	CostDefiningMethods.Add(Enums.WaysToCalculateReturnCost.FromSalesDocument);
	
	Query.SetParameter("Partner",							Partner);
	Query.SetParameter("TableOfGoods",						Goods);
	Query.SetParameter("CostDefiningMethods",	CostDefiningMethods);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
EndProcedure

Procedure SynchronizePropertiesOfInventoryOwnerAttributesOfAccount(TransferredInventoryOwnerAttributes, Cancel)
	
	If Cancel
		Or TransferredInventoryOwnerAttributes.Count() = 0
		Or Not GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups") Then
		
		Return;
		
	EndIf;
	
	TransferredInventoryOwnerAttributes = CommonClientServer.CollapseArray(TransferredInventoryOwnerAttributes);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.ProductsRecordingAsReceived AS Products,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.LineNumber		AS LineNumber,
	|	InventoryKinds.Ref				AS InventoryOwnerAttribute,
	|	&Organization					AS Organization,
	|	InventoryKinds.InventoryType			AS InventoryType,
	|	InventoryKinds.GoodsOwner		AS GoodsOwner,
	|	InventoryKinds.Counterparty			AS Counterparty,
	|	InventoryKinds.Contract				AS Contract,
	|	InventoryKinds.Terms			AS Terms,
	|	InventoryKinds.Currency				AS Currency,
	|	InventoryKinds.PriceKind				AS PriceKind,
	|	InventoryKinds.VATTaxation	AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	CatalogProducts.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	InventoryKinds.ProductsGroup		AS ProductsGroup,
	|	InventoryKinds.SubjectToExcise	AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessTransactionStockType
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute IN(&VerifiableInventory)
	|	AND CatalogProducts.FinancialAccountingGroup <> InventoryKinds.FinancialAccountingGroup
	|	AND TableOfGoods.Products <> VALUE(Catalog.Products.EmptyRef)
	|
	|ORDER BY
	|	LineNumber";
	
	NamesOfColumnsToUpload = "LineNumber, ProductsRecordingAsReceived, InventoryOwnerAttribute";
	
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("VerifiableInventory",	TransferredInventoryOwnerAttributes);
	Query.SetParameter("TableOfGoods",		InventoryKinds.Unload(, NamesOfColumnsToUpload));
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return
	EndIf;
	
	Selection = QueryResult.Select();
	InventoryOwnerAttributesGoodsReceipt = New Map;
	
	While Selection.Next() Do
		InventoryOwnerAttributeGoodsReceipt = Catalogs.InventoryKinds.DocumentInventoryView(
									Selection.Organization,
									Selection.BusinessTransactionStockType,
									Selection);
		InventoryOwnerAttributesGoodsReceipt.Insert(Selection.LineNumber, InventoryOwnerAttributeGoodsReceipt);
	EndDo;
	
	For Each InventoryLine In InventoryKinds Do
		InventoryOwnerAttributeGoodsReceipt = InventoryOwnerAttributesGoodsReceipt[InventoryLine.LineNumber];
		
		If InventoryOwnerAttributeGoodsReceipt = Undefined Then
			Continue;
		EndIf;
		
		InventoryLine.InventoryOwnerAttribute = InventoryOwnerAttributeGoodsReceipt;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function GetDocumentAmount() Export
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.AmountIncludingVAT AS AmountIncludingVAT
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|;
	|SELECT
	|	ISNULL(SUM(Goods.AmountIncludingVAT),0) AS AmountIncludingVAT
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR NOT &ToReturnReusablePackage
	|	OR &DepositForPackageIsRequired
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT"));
	Query.SetParameter("ToReturnReusablePackage", ReusablePackageReturn);
	Query.SetParameter("DepositForPackageIsRequired", DepositForPackageIsRequired);
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountIncludingVAT;
	Return TotalAmount__;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager, SelectionByMethodOfDeterminingCost = "All")
	
	AttributesCollection = New Array;
	AttributesCollection.Add("Date");
	AttributesCollection.Add("Organization");
	AttributesCollection.Add("DocumentSalesOfGoodsAndServices");
	AttributesCollection.Add("VATTaxation");
	If SelectionByMethodOfDeterminingCost = "NotFromSalesDocument" Then
		AttributesCollection.Add("SubjectToExcise");
		AttributesCollection.Add("BusinessUnitProduction");
	EndIf;
	AttributesNames = StrConcat(AttributesCollection, ",");
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|////////////////////////////////////////////////////////////////////////////////
	|// Check the correspondence of the table parts of the Products and types of stocks
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		TableOfGoods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		TableOfGoods.VATRate AS VATRate,
	|		CASE
	|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|				THEN UNDEFINED
	|			ELSE TableOfGoods.DocumentSalesOfGoodsAndServices
	|		END AS DocumentSalesOfGoodsAndServices,
	|		TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|		TableOfGoods.CCDNumber AS CCDNumber,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.Cost_ AS Cost_,
	|		TableOfGoods.CostExcludingVAT_ AS CostExcludingVAT_,
	|		TableOfGoods.CostLocal AS CostLocal,
	|		TableOfGoods.CDCost AS CDCost,
	|		TableOfGoods.TDCost AS TDCost
	|	FROM
	|		TTTableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		TableTypesOfStocks_.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod,
	|		TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.Cost_ AS Cost_,
	|		-TableTypesOfStocks_.CostExcludingVAT_ AS CostExcludingVAT_,
	|		-TableTypesOfStocks_.CostLocal AS CostLocal,
	|		-TableTypesOfStocks_.CDCost AS CDCost,
	|		-TableTypesOfStocks_.TDCost AS TDCost
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|	
	|	LEFT JOIN
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	ON
	|		TableOfGoods.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|		AND TableOfGoods.ProductsRecordingAsReceived = TableTypesOfStocks_.ProductsRecordingAsReceived
	|		AND TableOfGoods.CharacteristicRecordingAsReceived = TableTypesOfStocks_.CharacteristicRecordingAsReceived
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ProductsRecordingAsReceived,
	|	TableOfGoods.CharacteristicRecordingAsReceived,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.QuantityByGBRN) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.Cost_) <> 0
	|	OR SUM(TableOfGoods.CostExcludingVAT_) <> 0
	|	OR SUM(TableOfGoods.CostLocal) <> 0
	|	OR SUM(TableOfGoods.CDCost) <> 0
	|	OR SUM(TableOfGoods.TDCost) <> 0
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.OriginWarehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|");
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BusinessOperation", BusinessOperation);

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

// The procedure creates a temporary table of products with separate accounting Analytics.
//
// Parameters:
//	TempTablesManager - TempTablesManager - A temp table of items with separate accounting analytics.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.Users.EmptyRef) AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&VATTaxation AS VATTaxation,
	|	TableOfGoods.Count AS Count
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE";
	
	Query.SetParameter("VATTaxation", VATTaxation);
	
	Query.Execute();
	
EndProcedure

Procedure FillOutSettlements(SamplingBaseCalculations)
	
	// We will fill out mutual settlements.
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer 
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent Then
		
		AmountForAllocation = GetDocumentAmount();
		
		While AmountForAllocation > 0 And SamplingBaseCalculations.Next() Do
			
			If SamplingBaseCalculations.SumBalance > 0 Then
				
				NewRow = ARAPDetails.Add();
				NewRow.ARAPCurrency = SamplingBaseCalculations.ARAPCurrency;
				NewRow.ARAPObject = SamplingBaseCalculations.ARAPObject;
				
				Coefficients  = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
					Currency, SamplingBaseCalculations.ARAPCurrency, CurrentSessionDate(), Organization);
				LineAmount_ = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, SamplingBaseCalculations.SumBalance / Coefficients.ConversionRateToSettlementCurrency, 0);
				
				If AmountForAllocation > LineAmount_ Then
					NewRow.Sum = SamplingBaseCalculations.SumBalance;
				Else
					NewRow.Sum = AmountForAllocation;
				EndIf;
				
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				
			EndIf;
			
		EndDo;
		
		If AmountForAllocation > 0 Then
			
			NewRow = ARAPDetails.Add();
			NewRow.ARAPCurrency = Currency;
			NewRow.Sum = AmountForAllocation;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInARAPAccountsForReturnRequests(DocumentBasis)
	
	SetPrivilegedMode(True);
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Or
		BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager();
		Query.SetParameter("DocumentBasis", DocumentBasis);
		Query.Text =
			"SELECT
			|	RequestForReturnOfGoodsFromCustomer.ARAPObject AS ARAPObject
			|INTO ARAPObjects
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
			|WHERE
			|	RequestForReturnOfGoodsFromCustomer.Ref IN (&DocumentBasis)
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	GoodsTable.ARAPObject
			|FROM
			|	Document.CustomerInvoice.Goods AS GoodsTable
			|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
			|		ON (ReturnRequest.DocumentSalesOfGoodsAndServices = GoodsTable.Ref)
			|WHERE
			|	ReturnRequest.Ref IN (&DocumentBasis)
			|	AND GoodsTable.Ref.OrderSales
			|	AND GoodsTable.SalesOrder <> UNDEFINED
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ReturnRequest.ARAPObject AS ARAPObject
			|INTO ObjectsOfCalculationsForApplication
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
			|WHERE
			|	ReturnRequest.Ref IN (&DocumentBasis)
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	GoodsTable.ARAPObject
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
			|		INNER JOIN Document.CustomerInvoice.Goods AS GoodsTable
			|		ON (GoodsTable.SalesOrder = ReturnRequest.Ref)
			|WHERE
			|	ReturnRequest.Ref IN (&DocumentBasis)
			|	AND GoodsTable.Ref.OrderSales
			|	AND GoodsTable.SalesOrder <> UNDEFINED
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
			|	CustomersARAPAccounting.Currency AS ARAPCurrency,
			|	CustomersARAPAccounting.AmountDueBalance AS Sum,
			|	ISNULL(CustomersARAPAccounting.AmountDueBalance, 0) + ISNULL(CustomersARAPAccounting.SumBalance, 0) AS SumBalance
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Balance(
			|			,
			|			ARAPObject IN
			|				(SELECT
			|					ObjectsOfCalculationsForApplication.ARAPObject
			|				FROM
			|					ObjectsOfCalculationsForApplication)) AS CustomersARAPAccounting
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
			|	CustomersARAPAccounting.Currency AS ARAPCurrency,
			|	CustomersARAPAccounting.AmountDueBalance AS Sum,
			|	ISNULL(CustomersARAPAccounting.SumBalance, 0) AS SumBalance
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Balance(
			|			,
			|			ARAPObject IN
			|				(SELECT
			|					ARAPObjects.ARAPObject
			|				FROM
			|					ARAPObjects)) AS CustomersARAPAccounting";
		
		ResultsArray                 = Query.ExecuteBatch();
		
		ResultCalculationsForApplication          = ResultsArray[2]; // QueryResult
		ResultCalculationsBasedOnApplication = ResultsArray[3]; // QueryResult
		
		SampleCalculationsByApplication            = ResultCalculationsForApplication.Select();
		SampleCalculationsBasedOnApplication   = ResultCalculationsBasedOnApplication.Select();
		
		AmountForAllocation = GetDocumentAmount();
		
		While AmountForAllocation > 0 And SampleCalculationsBasedOnApplication.Next() Do
			
			If SampleCalculationsBasedOnApplication.SumBalance > 0 Then
				
				NewRow                      = ARAPDetails.Add();
				NewRow.ARAPCurrency = SampleCalculationsBasedOnApplication.ARAPCurrency;
				NewRow.ARAPObject       = SampleCalculationsBasedOnApplication.ARAPObject;
				
				Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
					Currency, SampleCalculationsBasedOnApplication.ARAPCurrency, CurrentSessionDate(), Organization);
				LineAmount_ = ?(
					Coefficients.ConversionRateToSettlementCurrency <> 0,
					SampleCalculationsBasedOnApplication.SumBalance / Coefficients.ConversionRateToSettlementCurrency,
					0);
				
				If AmountForAllocation > LineAmount_ Then
					NewRow.Sum = LineAmount_;
				Else
					NewRow.Sum = AmountForAllocation;
				EndIf;
				
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				
			EndIf;
			
		EndDo;
		
		If AmountForAllocation > 0 And SampleCalculationsByApplication.Next() Then
			
			If SampleCalculationsByApplication.SumBalance > 0 Then
				
				NewRow                      = ARAPDetails.Add();
				NewRow.ARAPCurrency = SampleCalculationsByApplication.ARAPCurrency;
				NewRow.ARAPObject       = SampleCalculationsByApplication.ARAPObject;
				
				If AmountForAllocation > SampleCalculationsByApplication.SumBalance Then
					NewRow.Sum = SampleCalculationsByApplication.SumBalance;
				Else
					NewRow.Sum = AmountForAllocation;
				EndIf;
				
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				
			EndIf;
			
		EndIf;
		
		If AmountForAllocation > 0 Then
			
			NewRow = ARAPDetails.Add();
			
			NewRow.ARAPCurrency = Currency;
			NewRow.ARAPObject       = Undefined;
			NewRow.Sum                = AmountForAllocation;
			
		EndIf;
		
		ARAPDetails.GroupBy("ARAPObject, ARAPCurrency", "Sum"); 
		
	EndIf;
	
EndProcedure

Procedure FillInCostOfInventoryTypes(MatchingItemTypes, DocumentContainsNegotiableContainer, Cancel)
	
	If DocumentContainsNegotiableContainer Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes
		|INTO TableTypesOfStocks_
		|FROM
		|	&TableTypesOfStocks_ AS TableTypesOfStocks_
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
		|	Dimension.Products							AS Products,
		|	Dimension.Characteristic						AS Characteristic
		|FROM
		|	TableTypesOfStocks_ AS TableTypesOfStocks_
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
		|		
		|		LEFT JOIN Catalog.Products AS ProductData_1
		|		ON Dimension.Products = ProductData_1.Ref
		|
		|WHERE
		|	ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)";
		
		Query.SetParameter("TableTypesOfStocks_", InventoryKinds.Unload());
		
		QueryResult	= Query.Execute();
		AnalyticsData		= QueryResult.Unload();
		
		AnalyticsData.Indexes.Add("Products, Characteristic");
	EndIf;
	
	InventoryTable = InventoryKinds.Unload();
	InventoryTable.Columns.Add("CorItemsLocationAttributes",
									New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	RegistrationWarehouses = Goods.UnloadColumn("Warehouse");
	RegistrationInventory = InventoryKinds.UnloadColumn("InventoryOwnerAttribute");
	
	RegistrationWarehouses = CommonClientServer.CollapseArray(RegistrationWarehouses);
	RegistrationInventory = CommonClientServer.CollapseArray(RegistrationInventory);
	
	WarehouseData_2 = Common.ObjectsAttributeValue(RegistrationWarehouses, "WarehouseStore");
	DataOfInventory = Common.ObjectsAttributeValue(RegistrationInventory, "SubjectToExcise");
	For Each RowOfGoods In Goods Do
		
		NumberOfProductsPerLine	= RowOfGoods.Count;
		NumberOfPackagesPerLine	= RowOfGoods.NumberOfPackages;
		SumOfSNDSInLine			= RowOfGoods.AmountIncludingVAT;
		AmountOfNDSVLine				= RowOfGoods.VATAmount;
		CostPerLine		= RowOfGoods.Cost_;
		CostPriceWithoutNDSVLine	= RowOfGoods.CostExcludingVAT_;
		LocalCostInLine	= RowOfGoods.CostLocal;
		CostOfPRVLine		= RowOfGoods.CDCost;
		CostOfVRVLine		= RowOfGoods.TDCost;
		
		TheStructureOfTheSearch = ?(ValueIsFilled(RowOfGoods.DocumentSalesOfGoodsAndServices),
							New Structure("ItemsLocationAttributes, DocumentSalesOfGoodsAndServices"),
							New Structure("ItemsLocationAttributes"));
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		If DocumentContainsNegotiableContainer Then
			ItemsType = MatchingItemTypes.Get(RowOfGoods.Products);
			
			If ItemsType = Enums.ItemsTypes.ReusablePackage Then
				DataKey = New Structure("Products, Characteristic");
				FillPropertyValues(DataKey, RowOfGoods);
				
				FilterRows = AnalyticsData.FindRows(DataKey);
				If FilterRows.Count() > 0 Then
					TheStructureOfTheSearch.ItemsLocationAttributes = FilterRows[0].ItemsLocationAttributes;
				EndIf;
			EndIf;
		EndIf;
		DisplayErrorMessages = True;
		For Each InventoryLine In InventoryTable.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(NumberOfProductsPerLine, InventoryLine.Count);
			
			NewRow = InventoryTable.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.CorItemsLocationAttributes	= RowOfGoods.ItemsLocationAttributes;
			NewRow.SetAccountingDimension			= RowOfGoods.SetAccountingDimension;
			NewRow.CostDefiningMethod	= RowOfGoods.CostDefiningMethod;
			NewRow.Count						= Count;
			NewRow.QuantityByGBRN				= Count * InventoryLine.QuantityByGBRN
															/ InventoryLine.Count;
			NewRow.Package						= RowOfGoods.Package;
			NewRow.NumberOfPackages				= ?(Count = NumberOfProductsPerLine,
															NumberOfPackagesPerLine,
															NumberOfPackagesPerLine * Count / NumberOfProductsPerLine);
			NewRow.AmountIncludingVAT						= ?(Count = NumberOfProductsPerLine,
															SumOfSNDSInLine,
															Count * SumOfSNDSInLine / NumberOfProductsPerLine);
			NewRow.VATAmount						= ?(Count = NumberOfProductsPerLine,
															AmountOfNDSVLine,
															Count * AmountOfNDSVLine / NumberOfProductsPerLine);
			NewRow.Cost_					= ?(Count = NumberOfProductsPerLine,
															CostPerLine,
															Count * CostPerLine / NumberOfProductsPerLine);
			NewRow.CostExcludingVAT_				= ?(Count = NumberOfProductsPerLine,
															CostPriceWithoutNDSVLine,
															Count * CostPriceWithoutNDSVLine / NumberOfProductsPerLine);
			NewRow.CostLocal				= ?(Count = NumberOfProductsPerLine,
															LocalCostInLine,
															Count * LocalCostInLine / NumberOfProductsPerLine);
			NewRow.CDCost					= ?(Count = NumberOfProductsPerLine,
															CostOfPRVLine,
															Count * CostOfPRVLine / NumberOfProductsPerLine);
			NewRow.TDCost					= ?(Count = NumberOfProductsPerLine,
															CostOfVRVLine,
															Count * CostOfVRVLine / NumberOfProductsPerLine);
			NewRow.ExciseTaxAmount						= Count * InventoryLine.ExciseTaxAmount / InventoryLine.Count;
			InventoryLine.CorItemsLocationAttributes	= RowOfGoods.ItemsLocationAttributes;
			InventoryLine.Count					= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN				= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.NumberOfPackages			= InventoryLine.NumberOfPackages - NewRow.NumberOfPackages;
			InventoryLine.AmountIncludingVAT						= InventoryLine.AmountIncludingVAT- NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount						= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.Cost_					= InventoryLine.Cost_ - NewRow.Cost_;
			InventoryLine.CostExcludingVAT_			= InventoryLine.CostExcludingVAT_ - NewRow.CostExcludingVAT_;
			InventoryLine.CostLocal				= InventoryLine.CostLocal - NewRow.CostLocal;
			InventoryLine.CDCost				= InventoryLine.CDCost - NewRow.CDCost;
			InventoryLine.TDCost				= InventoryLine.TDCost - NewRow.TDCost;
			InventoryLine.ExciseTaxAmount					= InventoryLine.ExciseTaxAmount - NewRow.ExciseTaxAmount;
			NumberOfProductsPerLine	= NumberOfProductsPerLine - NewRow.Count;
			NumberOfPackagesPerLine	= NumberOfPackagesPerLine - NewRow.NumberOfPackages;
			SumOfSNDSInLine			= SumOfSNDSInLine - NewRow.AmountIncludingVAT;
			AmountOfNDSVLine				= AmountOfNDSVLine - NewRow.VATAmount;
			CostPerLine		= CostPerLine - NewRow.Cost_;
			CostPriceWithoutNDSVLine	= CostPriceWithoutNDSVLine - NewRow.CostExcludingVAT_;
			LocalCostInLine	= LocalCostInLine - NewRow.CostLocal;
			CostOfPRVLine		= CostOfPRVLine - NewRow.CDCost;
			CostOfVRVLine		= CostOfVRVLine - NewRow.TDCost;
			If DisplayErrorMessages
				And DataOfInventory.Get(InventoryLine.InventoryOwnerAttribute)
				And WarehouseData_2.Get(RowOfGoods.Warehouse) = Enums.TypesOfWarehouses.RetailStore Then
				
				FieldName = "Products";
				ReturnedProduct = RowOfGoods.Products;
				
				If RowOfGoods.Damage Then
					FieldName = "ProductsRecordingAsReceived";
					ReturnedProduct = RowOfGoods.ProductsRecordingAsReceived;
				EndIf;
				
				MessageText = NStr("vi = 'Đã cấm trả lại hàng hóa chịu thuế TTĐB ""%1"" mà được chỉ định trong dòng %2 của danh sách ""Hàng hóa"" vào kho bán lẻ ""%3"".';
									|ru = 'Запрещен возврат подакцизного товара ""%1"", указанного в строке %2 списка ""Товары"" на розничный склад ""%3"".';
									|en = 'Cannot return the ""%1"" excisable goods specified in line %2 of the ""Goods"" list in the ""%3"" retail warehouse.'; fa = 'Cannot return the ""%1"" excisable goods specified in line %2 of the ""Goods"" list in the ""%3"" retail warehouse.';
									|it = 'Cannot return the ""%1"" excisable goods specified in line %2 of the ""Goods"" list in the ""%3"" retail warehouse.';
									|pl = 'Cannot return the ""%1"" excisable goods specified in line %2 of the ""Goods"" list in the ""%3"" retail warehouse.';
									|tr = '""Ürünler"" listesinin %2 satırında belirtilen tüketim vergisine tabi ""%1"" ürününün ""%3"" perakende ambarına iadesi yasaktır.'");
				MessageText = StrTemplate(MessageText,
											ReturnedProduct,
											RowOfGoods.LineNumber,
											RowOfGoods.Warehouse);
				
				Field = CommonClientServer.PathToTabularSection("Goods", RowOfGoods.LineNumber, FieldName);
				
				Common.MessageToUser(MessageText, ThisObject , Field, "", Cancel);
				
			EndIf;
			If NumberOfProductsPerLine = 0 Then
				Break;
			EndIf;
			
			DisplayErrorMessages = False;
			
		EndDo;
		
	EndDo;
	
	If DocumentContainsNegotiableContainer Then
		For Each TableRow In InventoryTable Do
			If Not ValueIsFilled(TableRow.CorItemsLocationAttributes) Then
				Continue;
			EndIf;
			
			TableRow.ItemsLocationAttributes = TableRow.CorItemsLocationAttributes;
		EndDo;
	EndIf;
	
	InventoryKinds.Load(InventoryTable);
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure ClearCostDeterminationMethodAndImplementationDocument()
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		MatchingProductsType = Common.ObjectsAttributeValue(Goods.UnloadColumn("Products"), "ItemsType");
		For Each RowProducts_ In Goods Do
			If MatchingProductsType.Get(RowProducts_.Products) = Enums.ItemsTypes.ReusablePackage 
				And ReusablePackageReturn Then
				// To return a multi-turn container, you need to save the specified sales document and the method of specifying the cost
			Else
				RowProducts_.CostDefiningMethod = Enums.WaysToCalculateReturnCost.FromCurrentDocument;
			EndIf;
		EndDo;
	Else
		For Each RowOfTables In Goods Do
			If RowOfTables.CostDefiningMethod <> Enums.WaysToCalculateReturnCost.FromSalesDocument Then
				RowOfTables.DocumentSalesOfGoodsAndServices = Undefined;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInCCDNumbersOnOrders(PriceIncludesVAT, RecalculateSummaryIndicators = True)
	
	FillParameters = PurchasesServer.ParametersForFillingInCCDNumbersBasedOnCredentials();
	QueryOptions = FillParameters.QueryOptions;
	QueryOptions.Ref = Ref;
	
	ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	ActionsWithString = New Structure;
	ActionsWithString.Insert("RecalculateAmount");
	ActionsWithString.Insert("RecalculateVATAmount",	ParametersForRecalculatingAmount);
	ActionsWithString.Insert("RecalculateAmountWithVAT",	ParametersForRecalculatingAmount);
	
	If RecalculateSummaryIndicators Then
		FillParameters.ActionsWithString = ActionsWithString;
	EndIf;
	
	FillParameters.NameOfOrderField = "DocumentSalesOfGoodsAndServices";
	
	PurchasesServer.FillInCCDNumbersAccordingToCredentials(Goods, "ByReferences", FillParameters);
	
	If Not RecalculateSummaryIndicators Then
		BatchProcessingOfTablePartServer.TreatTS(Goods, ActionsWithString, Undefined);
	EndIf;
	
EndProcedure

Procedure RecalculateNumberOfRNPT()
	
	StorageLocationFieldName = ?(BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent,
								"Partner",
								"Warehouse");
			
	ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
											ThisObject,
											StorageLocationFieldName);
	
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																					Goods);
	
EndProcedure
Procedure CheckCorrectnessOfIndicationOfExciseCategories(ExciseLines, Cancel)
	
	If Cancel
		Or ExciseLines.Count() = 0
		Or Not GetFunctionalOption("UseExcisableGoods") Then
		
		Return;
		
	EndIf;
	
	StringsList = New Array;
	ExciseLines = CommonClientServer.CollapseArray(ExciseLines);
	
	For Each LineNumber In ExciseLines Do
		StringsList.Add(Goods[LineNumber - 1]);
	EndDo;
	
	ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
	ControlParameters.NameOfFieldWithError		= "ProductsRecordingAsReceived";
	ControlParameters.ErrorTextTemplate	=
		NStr("vi = 'Có sự khác biệt giữa các thể loại hàng hóa chịu thuế TTĐB %Products% (hàng đã giao) và %ProductsRecordingAsReceived% (hàng hỏng) tại dòng %LineNumber% danh sách ""%TabularSectionPresentation%""';
			|ru = 'Различаются категории подакцизных товаров %Products% (отгруженный товар) и %ProductsRecordingAsReceived% (испорченный товар) в строке %LineNumber% списка ""%TabularSectionPresentation%""';
			|en = 'The %Products% (shipped goods) and %ProductsRecordingAsReceived% (spoiled goods) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list'; fa = 'The %Products% (shipped goods) and %ProductsRecordingAsReceived% (spoiled goods) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list';
			|it = 'The %Products% (shipped goods) and %ProductsRecordingAsReceived% (spoiled goods) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list';
			|pl = 'The %Products% (shipped goods) and %ProductsRecordingAsReceived% (spoiled goods) excisable goods categories differ in line %LineNumber% of the ""%TabularSectionPresentation%"" list';
			|tr = 'Tüketim vergisine tabi %Products% (sevk edilen ürünler) ve %ProductsRecordingAsReceived% (hasarlı ürünler) ürün kategorileri ""%TabularSectionPresentation%"" listesinin %LineNumber% satırında farklılık göstermektedir.'");
	ControlParameters.StringsList = StringsList;
	
	ExcisableGoodsAccounting.ControlOfComplianceWithCategoryOfExcisableItems(ThisObject, ControlParameters, Cancel);
	
EndProcedure
#EndRegion

#EndRegion

#EndIf
#EndIf
