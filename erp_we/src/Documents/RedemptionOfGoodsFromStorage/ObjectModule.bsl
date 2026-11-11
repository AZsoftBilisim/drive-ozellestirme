#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sale in the purchase of goods from storage.
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency                  = PurchaseConditions.Currency;
	PaymentMethod             = PurchaseConditions.PaymentMethod;
	VendorPriceKind       = PurchaseConditions.VendorPriceKind;
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Organization)
		And PurchaseConditions.Organization <> Organization Then
		
		Organization = PurchaseConditions.Organization;
		
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If ValueIsFilled(PurchaseConditions.Counterparty)
		And PurchaseConditions.Counterparty <> Counterparty Then
		
		Counterparty = PurchaseConditions.Counterparty;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If Counterparty <> TheCounterpartyPriorToTheChange Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If PurchaseConditions.ContractsAreUsed <> Undefined
		And PurchaseConditions.ContractsAreUsed Then
		
		DocumentBusinessTransaction = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
		If BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
			DocumentBusinessTransaction = TollingSchemeClientServer.ContractBusinessTransaction();
		EndIf;
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = ARAPCurrency;
		
		Contract = PurchasesServer.GetDefaultContract(ThisObject,
															DocumentBusinessTransaction,
															AddlParameters);
		
		If ValueIsFilled(Contract) Then
			PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
				ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
				CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount,
			CounterpartyBankAccount);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") 
			Or GetFunctionalOption("UseVendorARAPInLineOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
		CompleteVATTaxation();
		
	Else
		
		If ForeignCurrencyTransaction <> PurchaseConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
			CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(), CompanyBankAccount);
	
	PaymentDateValue = PurchasesServer.GetLatestDateOnSchedule(Date, PurchaseConditions.Terms);
	
	If ValueIsFilled(PaymentDateValue) Then
		PaymentDate = PaymentDateValue;
	Else
		PaymentDate = CurrentSessionDate();
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
	EndIf;
	
	PriceIncludesVAT = PurchaseConditions.PriceIncludesVAT;
	
	FillOutRansomUnderActivity();
	
EndProcedure

// Fills in the terms of purchases under the trade agreement with the supplier.
//
// Parameters:
//	RecalculatePrices_ - Boolean - True - Indicates the need to recalculate prices in the table part of the document.
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True) Export
	
	DocumentBusinessTransaction = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	If BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		DocumentBusinessTransaction = TollingSchemeClientServer.ContractBusinessTransaction();
	EndIf;
	If ValueIsFilled(Partner) Then
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		FilterParameters = New Structure();
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("BusinessTransactions", DocumentBusinessTransaction);
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, FilterParameters);
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
				If RecalculatePrices_
					And ValueIsFilled(Terms) Then
					FillInPrices();
				EndIf;
				
			Else
				Terms = DefaultPurchasingConditions.Terms;
				
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				If TheCounterpartyPriorToTheChange <> Counterparty Then
					CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
				EndIf;
			EndIf;
			
		Else
			
			Terms = Undefined;
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			If TheCounterpartyPriorToTheChange <> Counterparty Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = ARAPCurrency;
			
			Contract = PurchasesServer.GetDefaultContract(ThisObject,
																DocumentBusinessTransaction,
																AddlParameters);
			
			PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
			
			SelectingTypeOfPrices = New Structure("Owner, AvailableForPurchase", Partner, True);
			VendorPriceKind = Catalogs.VendorPriceTypes.DefaultPriceType(VendorPriceKind, SelectingTypeOfPrices);
			
			If RecalculatePrices_
				And ValueIsFilled(VendorPriceKind) Then
				FillInPrices();
			EndIf;
			
			CompleteVATTaxation();
			FillOutRansomUnderActivity();
			
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
			ParametersOfAccount, CounterpartyBankAccount);
		
	EndIf;
	
EndProcedure

// Creates a temporary table of products with separate accounting Analytics
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus IN (14, 18)
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse,
	|
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	DocumentDataTable.Partner AS Partner,
	|
	|	DocumentDataTable.Terms AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|
	|	TableOfGoods.Count AS Count
	|	
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|;
	|";
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// Generates temporary document data tables.
//
// Parameters:
//	RefillInventoryKinds - Boolean - Indicates whether the inventory types must be re-filled.
//
// Returns:
//	TempTablesManager - manager of temporary document data tables.
//
Function TemporaryDocumentDataTables(RefillInventoryKinds = False) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	UNDEFINED AS Warehouse,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	&PriceKind AS PriceKind,
	|	VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN TableOfGoods.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN TableOfGoods.Warehouse
	|		WHEN TableOfGoods.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN TableOfGoods.Department
	|		WHEN TableOfGoods.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN TableOfGoods.Contract
	|		ELSE UNDEFINED
	|	END AS StorageLocation,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&BusinessOperation AS BusinessOperation
	|INTO TTOriginalProductTable
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR &RefillInventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	TableOfGoods.BusinessOperation AS BusinessOperation,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TTOriginalProductTable AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT) AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	CASE
	|		WHEN TableOfGoods.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN TableOfGoods.Warehouse
	|		WHEN TableOfGoods.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN TableOfGoods.Department
	|		WHEN TableOfGoods.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN TableOfGoods.Contract
	|		ELSE UNDEFINED
	|	END AS StorageLocation,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.BatchesIndicationStatus,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Count,
	|	TableOfGoods.QuantityByGBRN,
	|	TableOfGoods.StorageLocation AS Warehouse,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Package,
	|	TableOfGoods.Price,
	|	&VendorPriceKind AS PriceKind,
	|	TableOfGoods.AmountIncludingVAT,
	|	TableOfGoods.VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Package AS Package,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount
	|INTO InitialTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.Package AS Package,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	Dimension.StorageLocation AS Warehouse,
	|	&SalesOpportunity AS SalesOpportunity,
	|	FALSE AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	InitialTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("VendorPriceKind", VendorPriceKind);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("Department", Department);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Query.SetParameter("PriceIncludesVAT", ?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	Query.SetParameter("RefillInventoryKinds", RefillInventoryKinds);
	Query.SetParameter("Posted", Posted);
	Query.SetParameter("PriceKind", VendorPriceKind);
	
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
	
	Return TempTablesManager;
	
EndFunction

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

Procedure FillInPrices()
	
	If Goods.Count() = 0
		Or (Not ValueIsFilled(VendorPriceKind)
		And Not ValueIsFilled(Terms)) Then
		Return;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",     "Price, VATRate");
	FillParameters.Insert("Date",               Date);
	FillParameters.Insert("Currency",             Currency);
	FillParameters.Insert("Terms",         Terms);
	FillParameters.Insert("VendorPriceKind",  VendorPriceKind);
	FillParameters.Insert("VATTaxation", VATTaxation);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",     "NumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	PricesAreFilledOut = PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);

EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.RedemptionOfGoodsFromStorage - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = ParametersForFillingInventoryTypes(True);
	
	If TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry") Then
		FillParameters.DocumentMakesBothArrivalAndExpenditure = False;
	Else
		If WriteMode = DocumentWriteMode.UndoPosting Then
			FillParameters.DocumentMakesBothArrivalAndExpenditure = False;
		EndIf;
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.RedemptionOfGoodsFromStorage.CollectionOfTabularPartsOfGoods.
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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	SeriesSpecificationParameters        = ProductsServer.SeriesSpecificationParameters(ThisObject,
									Documents.RedemptionOfGoodsFromStorage);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel, True);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	
	RedemptionOfGoodsFromStorageLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

// Parameters:
// 	FillingData - Structure - contains including:
// 		* HeaderFields - Structure - (optional)
//
Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("HeaderFields") Then
			
			HeaderFields = FillingData.HeaderFields;
			
			Date               = HeaderFields.Period;
			Organization        = HeaderFields.Recipient;
			Partner            = HeaderFields.Sender;
			VendorPriceKind  = HeaderFields.PriceKind;
			Contract            = HeaderFields.Contract;
			Currency             = HeaderFields.Currency;
			VATTaxation = HeaderFields.VATTaxation;
			Counterparty         = HeaderFields.Counterparty;
			
			If FillingData.Property("FillInByOrganizationSProductReserves") Then
				Query = New Query;
				
				For Each KeyValue In HeaderFields Do
					Query.SetParameter(KeyValue.Key, KeyValue.Value);
				EndDo;
				
				Query.SetParameter("BeginOfPeriod",   BegOfMonth(HeaderFields.Period));
				Query.SetParameter("EndOfPeriod",    EndOfMonth(HeaderFields.Period));
				Query.SetParameter("IssueRansoms", True);
				TypesOfRedemptionStocks = New Array;
				TypesOfRedemptionStocks.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
				
				If ValueIsFilled(Contract)
				   And Common.ObjectAttributeValue(Contract, "BusinessOperation") =
													TollingSchemeClientServer.ContractBusinessTransaction() Then
					TypesOfRedemptionStocks.Clear();
					TypesOfRedemptionStocks.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
					TypesOfRedemptionStocks.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
					TypesOfRedemptionStocks.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
				EndIf;
				
				Query.SetParameter("TypesOfRedemptionStocks", TypesOfRedemptionStocks);
				Query.Text = InventoriesServer.TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query,
																								"SelectingDocumentContent");
				
				ResultTable2 = Query.Execute().Unload();
				
				TypeStorageLocation = New TypeDescription("EnumRef.StorageLocationTypes");
				WarehouseType_         = New TypeDescription("CatalogRef.Warehouses");
				ContractType_       = New TypeDescription("CatalogRef.CounterpartyContracts");
				UnitType__ = New TypeDescription("CatalogRef.BusinessStructure");
				TypeKeeper     = New TypeDescription("CatalogRef.Partners");
				TypeCounterparty    = New TypeDescription("CatalogRef.Counterparties");
				
				ResultTable2.Columns.Add("StorageType", TypeStorageLocation);
				ResultTable2.Columns.Add("Warehouse",            WarehouseType_);
				ResultTable2.Columns.Add("Contract",          ContractType_);
				ResultTable2.Columns.Add("Department",    UnitType__);
				ResultTable2.Columns.Add("Custodian",        TypeKeeper);
				ResultTable2.Columns.Add("Counterparty",       TypeCounterparty);
				
				StorageLocation = ?(ValueIsFilled(HeaderFields.StorageLocationWarehouse),
									Enums.StorageLocationTypes.Warehouse,
									?(ValueIsFilled(HeaderFields.StorageLocationDepartment),
										Enums.StorageLocationTypes.Department,
										Enums.StorageLocationTypes.CounterpartyContract));
				
				ResultTable2.FillValues(StorageLocation,                        "StorageType");
				ResultTable2.FillValues(HeaderFields.StorageLocationWarehouse,         "Warehouse");
				ResultTable2.FillValues(HeaderFields.StorageLocationDepartment, "Department");
				ResultTable2.FillValues(HeaderFields.StorageLocationContract,       "Contract");
				ResultTable2.FillValues(HeaderFields.StorageLocationPartner,       "Custodian");
				ResultTable2.FillValues(HeaderFields.StorageLocationCounterparty,    "Counterparty");
				
				Goods.Load(ResultTable2);
				
				ValueTableColumn = ResultTable2.Columns.InventoryOwnerAttribute; // ValueTableColumn
				ValueTableColumn.Name = "RedeemedInventoryOwnerAttributes";
				
				ValueTableColumn = ResultTable2.Columns.SenderSInventoryType; // ValueTableColumn
				ValueTableColumn.Name = "InventoryOwnerAttribute";
				
				InventoryKinds.Load(ResultTable2);
				
			EndIf;
			
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	FillOutBankAccounts();
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
		
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument();
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	RedemptionOfGoodsFromStorageLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	RoundingParameters = Undefined;
	If BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		
		FoundRows = Goods.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
		If FoundRows.Count() > 0 Then
			
			DefaultAssignment = Common.ObjectAttributeValue(Contract, "Purpose");
			
			For Each StringTSGoods In Goods Do
				StringTSGoods.Purpose = DefaultAssignment;
			EndDo;
			
		EndIf;
		
		RoundingParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		RoundingParameters.AdditionalFields.Insert("Warehouse", "Goods.Warehouse");
		RoundingParameters.ConditionForSelectingRowsByAdditionalFields =
			"(VALUETYPE(Goods.Warehouse) <> TYPE(Catalog.Warehouses)
			|OR " + ProductionServer.ConditionForSelectingRowsForRounding("Goods", "Warehouse") + ")";
		
	EndIf;
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
																		Documents.RedemptionOfGoodsFromStorage);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
		
	RegistrationParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	RedemptionOfGoodsFromStorageLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RedemptionOfGoodsFromStorageLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	RegistrationParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RedemptionOfGoodsFromStorageLocalization.UndoPosting(ThisObject, Cancel);
	
	RegistrationParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	IncomingDocumentDate		= Date(1,1,1);
	IncomingDocumentNumber		= "";
	InventoryOwnerAttributesAreSpecifiedManually	= False;
	
	For Each TSRow In Goods Do
		TSRow.RowID = "";
		TSRow.InventoryOwnerAttribute          = Catalogs.InventoryKinds.EmptyRef();
	EndDo;
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	RedemptionOfGoodsFromStorageLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	RedemptionOfGoodsFromStorageLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InventoryKinds

Function ParametersForFillingInventoryTypes(ParametersForConducting = False)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	SelectionOfStockTypes_.InventoryType = New Array;
	
	If ParametersForConducting Then
		// Adding our own inventory type to restore reserves
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	Else
		SelectionOfStockTypes_.Organization = Organization;
		SelectionOfStockTypes_.GoodsOwner = Partner;
		SelectionOfStockTypes_.Counterparty = Counterparty;
		SelectionOfStockTypes_.Contract = Contract;
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	Else
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	EndIf;
	Return FillParameters;
	
EndFunction

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	RefillInventoryKinds	= AdditionalProperties.Property("RefillInventoryKinds");
	TempTablesManager		= TemporaryDocumentDataTables(RefillInventoryKinds);
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		GroupColumns  = "ItemsLocationAttributes, InventoryOwnerAttribute, RedeemedInventoryOwnerAttributes, CCDNumber, VATRate,
								|Package, RowID, Price";
		TotalingColumns = "NumberOfPackages, Count, QuantityByGBRN, AmountIncludingVAT, VATAmount";
		
		InventoryKinds.GroupBy(GroupColumns, TotalingColumns);
		
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, VATTaxation";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.Package AS Package,
	|		TableOfGoods.Price AS Price,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType  IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.Package AS Package,
	|		TableTypesOfStocks_.Price AS Price,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Package,
	|	TableOfGoods.Price
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInAdditionalStockTypes() Export
	
	GroupColumns  = "ItemsLocationAttributes, Package, InventoryOwnerAttribute, Price";
	TotalingColumns = "Count, NumberOfPackages, VATAmount, AmountIncludingVAT, AmountARAP, 
							|AmountVATARAP";
	
	GoodsTable = Goods.Unload(, GroupColumns + ", " + TotalingColumns);
	GoodsTable.GroupBy(GroupColumns, TotalingColumns);
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity	= RowOfGoods.Count;
		NumberOfPackages	= RowOfGoods.NumberOfPackages;
		
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
			FillPropertyValues(NewRow, RowOfGoods, "Price, Package");
			
			NewRow.RedeemedInventoryOwnerAttributes = RowOfGoods.InventoryOwnerAttribute;
			NewRow.NumberOfPackages = NumberOfPackages * Count / GoodsQuantity;
			NewRow.Count = Count;
			NewRow.QuantityByGBRN = Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.AmountIncludingVAT = ?(Count = GoodsQuantity, RowOfGoods.AmountIncludingVAT,
				Count * RowOfGoods.AmountIncludingVAT / GoodsQuantity);
			NewRow.VATAmount = ?(Count = GoodsQuantity, RowOfGoods.VATAmount,
				Count * RowOfGoods.VATAmount / GoodsQuantity);
				
			NewRow.AmountARAP = ?(Count = GoodsQuantity, RowOfGoods.AmountARAP,
				Count * RowOfGoods.AmountARAP / GoodsQuantity);
			NewRow.AmountVATARAP = ?(Count = GoodsQuantity, RowOfGoods.AmountVATARAP,
				Count * RowOfGoods.AmountVATARAP / GoodsQuantity);
			
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT = InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount = InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.AmountARAP = InventoryLine.AmountARAP - NewRow.AmountARAP;
			InventoryLine.AmountVATARAP = InventoryLine.AmountVATARAP - NewRow.AmountVATARAP;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			NumberOfPackages = NumberOfPackages - NewRow.NumberOfPackages;
			
			RowOfGoods.AmountIncludingVAT = RowOfGoods.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			RowOfGoods.VATAmount = RowOfGoods.VATAmount - NewRow.VATAmount;
			RowOfGoods.AmountARAP = RowOfGoods.AmountARAP - NewRow.AmountARAP;
			RowOfGoods.AmountVATARAP = RowOfGoods.AmountVATARAP - NewRow.AmountVATARAP;
			
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
	
EndProcedure

// This procedure creates a temporary table of available inventory types.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table manager.
//
Procedure GenerateAvailableInventoryTypes(TempTablesManager) Export
	
	Query = New Query("

	|SELECT
	|	InventoryKinds.Ref AS InventoryOwnerAttribute,
	|	InventoryKinds.Ref AS SellerInventoryOwnerAttribute,
	|	FALSE AS SelectionAccordingToCommitteeSVATRate,
	|	UNDEFINED AS CommitteeSVATRate
	|INTO AvailableTypesOfStocks
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	NOT InventoryKinds.DeletionMark
	|	AND InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.GoodsOwner = &Partner
	|	AND InventoryKinds.Terms = &Terms
	|	AND InventoryKinds.Currency = &Currency
	|	AND InventoryKinds.PriceKind = &VendorPriceKind
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|
	|INDEX BY
	|	InventoryOwnerAttribute
	|");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("VendorPriceKind", VendorPriceKind);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.RedemptionOfGoodsFromStorage.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.RedemptionOfGoodsFromStorage.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Undefined,
																		Undefined,
																		Undefined,
																		Undefined);
	
	WarehouseFieldText =
	"CASE
	|	WHEN Collection.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|		THEN Collection.Warehouse
	|	WHEN Collection.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		THEN Collection.Contract
	|	WHEN Collection.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|		THEN Collection.Department
	|	ELSE UNDEFINED
	|END";
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("OwnGoods",				New Structure("FieldText", WarehouseFieldText));
	FieldsNames.Insert("ReusablePackage",	New Structure("FieldText", WarehouseFieldText));
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region InitializationAndFilling

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Organization") Then
		Organization = FillingData.Organization;
	EndIf;
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		FillInDefaultPurchaseConditions();
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument()
	
	If ValueIsFilled(Contract) Then
		FieldsNames        = "LineOfBusiness, ARAPObjectSettings, ARAPCurrency, FinancialAccountingGroup, ForeignCurrencyTransaction, 
							|CounterpartyBankAccount, BankAccount, Manager, BusinessOperation";
		ContractDetails_ = Common.ObjectAttributesValues(Contract, FieldsNames);
		
		FillPropertyValues(ThisObject, ContractDetails_, ,
			"LineOfBusiness, FinancialAccountingGroup, ForeignCurrencyTransaction, CounterpartyBankAccount, Manager, BusinessOperation");
		If Not ValueIsFilled(LineOfBusiness) Then
			LineOfBusiness = ContractDetails_.LineOfBusiness;
		EndIf;
		
		If Not ValueIsFilled(FinancialAccountingGroup) Then
			FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
		EndIf;
		
		If Not ValueIsFilled(ForeignCurrencyTransaction) Then
			ForeignCurrencyTransaction = ContractDetails_.ForeignCurrencyTransaction;
		EndIf;
		
		If Not ValueIsFilled(CounterpartyBankAccount) Then
			CounterpartyBankAccount = ContractDetails_.CounterpartyBankAccount;
		EndIf;
		
		If Not ValueIsFilled(CompanyBankAccount) Then
			CompanyBankAccount = ContractDetails_.BankAccount;
		EndIf;
		
		If Not ValueIsFilled(Manager) Then
			Manager = ContractDetails_.Manager;
		EndIf;
		
	EndIf;
	
	SelectingTypeOfPrices = New Structure("Owner, AvailableForPurchase", Partner, True);
	VendorPriceKind = Catalogs.VendorPriceTypes.DefaultPriceType(VendorPriceKind, SelectingTypeOfPrices);
	
	If ValueIsFilled(VendorPriceKind) Then
		FieldsNames                 = "PriceIncludesVAT, Currency";
		DetailsSupplierSPriceType = Common.ObjectAttributesValues(VendorPriceKind, FieldsNames);
		
		PriceIncludesVAT = DetailsSupplierSPriceType.PriceIncludesVAT;
		
		If Not ValueIsFilled(Currency) Then
			Currency = DetailsSupplierSPriceType.Currency;
		EndIf;
	EndIf;
	
	Organization          = SettingsValueCached.GetDefaultOrganization(Organization);
	Currency               = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	If ValueIsFilled(Contract)
	   And Common.ObjectAttributeValue(Contract, "BusinessOperation") =
											TollingSchemeClientServer.ContractBusinessTransaction() Then
		Department = Common.ObjectAttributeValue(Contract, "Department");
	Else
		Department = SettingsValueCached.UserDivision(Manager, Department);
	EndIf;
	If ValueIsFilled(Contract) Then
		
		If ContractDetails_.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal;
			Currency = ContractDetails_.ARAPCurrency;
		ElsIf ContractDetails_.BusinessOperation =
										TollingSchemeClientServer.ContractBusinessTransaction() Then
			BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods;
		ElsIf Not ValueIsFilled(BusinessOperation) Then
			BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage;
		EndIf;
	
	ElsIf Not ValueIsFilled(BusinessOperation) Then
	
		If GetFunctionalOption("UseCustodyDuringPurchase") Then
			BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage;
		ElsIf GetFunctionalOption("UseTollManufacturing2_5") Then
			BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods;
		ElsIf GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
			BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal;
		EndIf;
	
	EndIf;

	If Not ValueIsFilled(Terms) And ValueIsFilled(Partner) Then
		FilterParameters = New Structure();
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("BusinessTransactions", Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);

		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, FilterParameters);
		
		If DefaultPurchasingConditions <> Undefined And ValueIsFilled(DefaultPurchasingConditions.Terms)
			And (Organization = DefaultPurchasingConditions.Organization Or Not ValueIsFilled(DefaultPurchasingConditions.Organization)) Then
			Terms = DefaultPurchasingConditions.Terms;
		EndIf;
	EndIf;
		
	If Not ValueIsFilled(FinancialAccountingGroup) Then
		FinancialAccountingGroup = Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(
			Organization,
			ARAPCurrency);
	EndIf;
		
	If Not ValueIsFilled(VATTaxation) Then
		CompleteVATTaxation();
	EndIf;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Partner);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		Undefined);
	
	FillOutRansomUnderActivity();
		
	FillInDefaultDetailsInTablePart();
	
EndProcedure

Procedure FillInDefaultDetailsInTablePart()
	
	If Goods.Count() > 0 Then
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RedemptionOfGoodsFromStorage);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
		
		TMCommonUse.CollapseTablePart(ThisObject, "Goods", "BatchesIndicationStatus,Price");	
		
		CachedValues = Undefined;
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
		
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
		
		FillInPrices();
	EndIf;
	
	If InventoryKinds.Count() > 0 Then
		TMCommonUse.CollapseTablePart(ThisObject, "InventoryKinds", "Price");
	EndIf;	
	
EndProcedure

Procedure CompleteVATTaxation()
	
	FillParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
EndProcedure

Procedure FillOutRansomUnderActivity()
	
	FillParameters = Documents.RedemptionOfGoodsFromStorage.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(RedemptionForActivity, FillParameters);
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
EndProcedure

Function OrganizationSDefaultAccountParameters()
	
	If ValueIsFilled(Organization) Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.LineOfBusiness = LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	
	Return ParametersOfAccount;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
