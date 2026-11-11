#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a temporary data table of the document.
// Used for filling in inventory types.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	&Date                                                      AS Date,
	|	&Organization                                               AS Organization,
	|	&Partner                                                   AS GoodsOwner,
	|	&Partner                                                   AS Partner,
	|	&Counterparty                                                AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)  AS Terms,
	|	&Contract                                                   AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)                   AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&Warehouse                                                     AS Warehouse,
	|	&BusinessOperation                                     AS BusinessOperation,
	|	FALSE                                                       AS ThereAreTransactionsInTablePart,
	|	&Department                                             AS Department,
	|	&Manager                                                  AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)         AS SalesOpportunity,
	|	VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)    AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber                AS LineNumber,
	|	TableOfGoods.RowID        AS RowID,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.Characteristic             AS Characteristic,
	|	TableOfGoods.Purpose                 AS Purpose,
	|	TableOfGoods.Series                      AS Series,
	|	TableOfGoods.BatchesIndicationStatus        AS BatchesIndicationStatus,
	|	TableOfGoods.Warehouse                      AS Warehouse,
	|	TableOfGoods.MaterialProviderOrder              AS MaterialProviderOrder,
	|	TableOfGoods.ToExpenseAs           AS ToExpenseAs,
	|	TableOfGoods.Recipient                 AS Recipient,
	|	TableOfGoods.ExpenseItem             AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings       AS GLAccountSettings,
	|	TableOfGoods.ARAPObject             AS ARAPObject,
	|	TableOfGoods.NumberOfPackages         AS NumberOfPackages,
	|	TableOfGoods.Count                 AS Count,
	|	TableOfGoods.Package                   AS Package,
	|	TableOfGoods.Price                       AS Price,
	|	TableOfGoods.Sum                      AS Sum,
	|	TableOfGoods.VATRate                  AS VATRate,
	|	TableOfGoods.VATAmount                   AS VATAmount,
	|	TableOfGoods.AmountIncludingVAT                  AS AmountIncludingVAT,
	|	TableOfGoods.AmountARAP        AS AmountARAP
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber                  AS LineNumber,
	|	TableOfGoods.RowID          AS RowID,
	|	TableOfGoods.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TableOfGoods.Products                 AS Products,
	|	TableOfGoods.Characteristic               AS Characteristic,
	|	TableOfGoods.Purpose                   AS Purpose,
	|	TableOfGoods.Series                        AS Series,
	|	TableOfGoods.BatchesIndicationStatus          AS BatchesIndicationStatus,
	|	TableOfGoods.Warehouse                        AS Warehouse,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	TableOfGoods.MaterialProviderOrder                AS MaterialProviderOrder,
	|	TableOfGoods.ToExpenseAs             AS ToExpenseAs,
	|	TableOfGoods.Recipient                   AS Recipient,
	|	TableOfGoods.ExpenseItem               AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses            AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension     AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings         AS GLAccountSettings,
	|	TableOfGoods.Package                     AS Package,
	|	TableOfGoods.ARAPObject               AS ARAPObject,
	|	TableOfGoods.NumberOfPackages           AS NumberOfPackages,
	|	TableOfGoods.Count                   AS Count,
	|	TableOfGoods.Price                         AS Price,
	|	TableOfGoods.Sum                        AS Sum,
	|	TableOfGoods.VATRate                    AS VATRate,
	|	TableOfGoods.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount                     AS VATAmount,
	|	TableOfGoods.AmountARAP          AS AmountARAP,
	|	0                                           AS CommissionAmount,
	|	0                                           AS AmountVATRemuneration,
	|	TRUE                                      AS SelectTypesOfStocks,
	|	UNDEFINED                                AS DocumentSalesOfGoodsAndServices
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber                  AS LineNumber,
	|	TableOfGoods.RowID          AS RowID,
	|	TableOfGoods.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TableOfGoods.Products                 AS Products,
	|	TableOfGoods.Characteristic               AS Characteristic,
	|	TableOfGoods.Purpose                   AS Purpose,
	|	TableOfGoods.Series                        AS Series,
	|	TableOfGoods.BatchesIndicationStatus          AS BatchesIndicationStatus,
	|	Dimension.StorageLocation                     AS Warehouse,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	TableOfGoods.MaterialProviderOrder                AS MaterialProviderOrder,
	|	TableOfGoods.ToExpenseAs             AS ToExpenseAs,
	|	TableOfGoods.Recipient                   AS Recipient,
	|	TableOfGoods.ExpenseItem               AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses            AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension     AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings         AS GLAccountSettings,
	|	TableOfGoods.Package                     AS Package,
	|	TableOfGoods.ARAPObject               AS ARAPObject,
	|	TableOfGoods.NumberOfPackages           AS NumberOfPackages,
	|	TableOfGoods.Count                   AS Count,
	|	TableOfGoods.Price                         AS Price,
	|	TableOfGoods.Sum                        AS Sum,
	|	TableOfGoods.VATRate                    AS VATRate,
	|	TableOfGoods.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount                     AS VATAmount,
	|	TableOfGoods.AmountARAP          AS AmountARAP,
	|	0                                           AS CommissionAmount,
	|	0                                           AS AmountVATRemuneration,
	|	TRUE                                      AS SelectTypesOfStocks,
	|	UNDEFINED                                AS DocumentSalesOfGoodsAndServices
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	TableTypesOfStocks_.RowID        AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.MaterialProviderOrder              AS MaterialProviderOrder,
	|	TableTypesOfStocks_.ToExpenseAs           AS ToExpenseAs,
	|	TableTypesOfStocks_.ExpenseItem             AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.Recipient                 AS Recipient,
	|	TableTypesOfStocks_.Package                   AS Package,
	|	TableTypesOfStocks_.ARAPObject             AS ARAPObject,
	|	TableTypesOfStocks_.NumberOfPackages         AS NumberOfPackages,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END                                         AS QuantityByGBRN,
	|	TableTypesOfStocks_.Price                       AS Price,
	|	TableTypesOfStocks_.Sum                      AS Sum,
	|	TableTypesOfStocks_.VATRate                  AS VATRate,
	|	TableTypesOfStocks_.VATAmount                   AS VATAmount,
	|	TableTypesOfStocks_.AmountIncludingVAT                  AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountARAP        AS AmountARAP
	|INTO InitialTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	TableTypesOfStocks_.RowID             AS RowID,
	|	UNDEFINED                                       AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS ItemsLocationAttributes,
	|	Dimension.Products                             AS Products,
	|	Dimension.Characteristic                           AS Characteristic,
	|	Dimension.Series                                    AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.MaterialProviderOrder                   AS MaterialProviderOrder,
	|	TableTypesOfStocks_.ToExpenseAs                AS ToExpenseAs,
	|	TableTypesOfStocks_.ExpenseItem                  AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses               AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension        AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.Recipient                      AS Recipient,
	|	TableTypesOfStocks_.Package                        AS Package,
	|	TableTypesOfStocks_.ARAPObject                  AS ARAPObject,
	|	TableTypesOfStocks_.NumberOfPackages              AS NumberOfPackages,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                AS QuantityByGBRN,
	|	TableTypesOfStocks_.Price                            AS Price,
	|	TableTypesOfStocks_.Sum                           AS Sum,
	|	TableTypesOfStocks_.VATRate                       AS VATRate,
	|	TableTypesOfStocks_.VATAmount                        AS VATAmount,
	|	TableTypesOfStocks_.AmountIncludingVAT                       AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountARAP             AS AmountARAP,
	|	VALUE(Catalog.Warehouses.EmptyRef)           AS OriginWarehouse,
	|	Dimension.StorageLocation                            AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	FALSE                                               AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	InitialTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	Query.SetParameter("Ref",                Ref);
	Query.SetParameter("Date",                  Date);
	Query.SetParameter("Partner",               Partner);
	Query.SetParameter("Warehouse",                 Warehouse);
	Query.SetParameter("Counterparty",            Counterparty);
	Query.SetParameter("Contract",               Contract);
	Query.SetParameter("Organization",           Organization);
	Query.SetParameter("Department",         Department);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Manager",              Manager);
	Query.SetParameter("TableOfGoods",        ManufacturedProduct);
	Query.SetParameter("TableTypesOfStocks_",    InventoryKinds);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Fills in the terms of sales in the customer's order
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	Currency                  = SalesTermsAndConditions.Currency;
	ARAPCurrency    = SalesTermsAndConditions.ARAPCurrency;
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
	PriceIncludesVAT         = SalesTermsAndConditions.PriceIncludesVAT;
	
	If ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization Then
		
		Organization = SalesTermsAndConditions.Organization;
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If Not SalesTermsAndConditions.Standard_
	   And ValueIsFilled(SalesTermsAndConditions.Counterparty)
	   And SalesTermsAndConditions.Counterparty <> Counterparty Then
		Counterparty = SalesTermsAndConditions.Counterparty;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined
	   And SalesTermsAndConditions.ContractsAreUsed Then
		
		Contract = SalesServer.GetDefaultContract(
						ThisObject,
						TollingSchemeClientServer.ContractBusinessTransaction(),
						ARAPCurrency);
		
		If ValueIsFilled(Contract) Then
			PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
				ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
				CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		SalesServer.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness,, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> SalesTermsAndConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
			CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	FillInPaymentTerms_(SalesTermsAndConditions);
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the customer's order
//
Procedure FillInDefaultSalesConditions() Export
	
	If ValueIsFilled(Partner) Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",    Catalogs.TermsOfSale.EmptyRef());
		FilterParameters.Insert("EmptyDocumentLink",  Documents.ReportToMaterialProvider2_5.EmptyRef());
		FilterParameters.Insert("BusinessTransactions",  BusinessOperation);
		FilterParameters.Insert("OnlyStandard",          True);
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters, False);
		
		If DefaultSalesTerms <> Undefined Then
			
			If ValueIsFilled(DefaultSalesTerms.Terms) Then
				FillIn_TermsOfSales(DefaultSalesTerms);
			EndIf;
			
		Else
			TheCounterpartyPriorToTheChange = Counterparty;
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			If TheCounterpartyPriorToTheChange <> Counterparty Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			CounterpartyBankAccount);
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
Procedure FillInProductTrackingForm() Export
	
	// If the Warehouse is a group, then for the analysis of the inventory item, we take the warehouse from PM
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	If Not BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		And Not BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		
		WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
		If WarehouseDetails.IsFolder
			And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			FieldsNames.Arbitrary = "Warehouse";
		EndIf;
		
	EndIf;
	
	FieldsNames.Work_5 = "Department";
	
	PlacesOfAccounting =
		InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation, Warehouse, Department, Partner);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(ManufacturedProduct, PlacesOfAccounting, FieldsNames);
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.CustomerInvoice - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		
		ThereAreAdjustingEntries = False;
		SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries);
		If ThereAreAdjustingEntries Then
			SalesServer.ReportErrorsCancellationsAndAdjustments(Ref,Cancel);
		EndIf;
		
	EndIf;
	
	RoundingParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	RoundingParameters.TSName = "ManufacturedProduct";
	RoundingParameters.AdditionalFields.Insert("Warehouse", "ManufacturedProduct.Warehouse");
	RoundingParameters.ConditionForSelectingRowsByAdditionalFields =
		ProductionServer.ConditionForSelectingRowsForRounding("ManufacturedProduct", "Warehouse");
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReportToMaterialProvider2_5);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If ReportOnOrders And ValueIsFilled(MaterialProviderOrder) Then
		
		RowsArray =
			ManufacturedProduct.FindRows(New Structure("MaterialProviderOrder", Documents.MaterialProviderOrder2_5.EmptyRef()));
			
		For Each TableRow In RowsArray Do
			TableRow.MaterialProviderOrder = MaterialProviderOrder;
		EndDo;
		
	EndIf;
	
	CreateListOfDependentOrders();
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(ManufacturedProduct, PriceIncludesVAT);
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReportToMaterialProvider2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "ManufacturedProduct");
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingForm();
		FillStockTypes(Cancel);
	EndIf;
	
	GLAccountSettingsServer.BeforeWrite(ThisObject, Documents.ReportToMaterialProvider2_5.AccountingAccountSettings_());
	
	RegistrationParameters = Documents.ReportToMaterialProvider2_5.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(
		RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(ThisObject, WriteMode);
	
	ReportToMaterialProvider2_5Localization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFilling();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("AnArrayOfOrders") Then
			
			TypeBase = TypeOf(FillingData.AnArrayOfOrders[0]);
			
			If TypeBase = Type("DocumentRef.MaterialProviderOrder2_5") Then
				
				FillOutDocumentBasedOnGiverSOrder2_5(
					FillingData.AnArrayOfOrders, FillingData.HeaderAttributes);
				
			ElsIf TypeBase = Type("CatalogRef.CounterpartyContracts") Then
				
				FillInDocumentOnBasisOfContract(
					FillingData.AnArrayOfOrders, FillingData.HeaderAttributes);
				
			EndIf;
			
		Else
			
			FillInSelectionDocument(FillingData);
			
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.MaterialProviderOrder2_5") Then
		FillOutDocumentBasedOnGiverSOrder2_5(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.GoodsShipmentFromStorage") Then
		FillInDocumentBasedOnShipmentOfGoodsFromStorage(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.CounterpartyContracts") Then
		FillInDocumentOnBasisOfContract(FillingData);
	Else
		FillInDefaultSalesConditions();
	EndIf;
	
	InitializeDocument();
	
	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(
		ThisObject,
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReportToMaterialProvider2_5)));
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse",   False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	ReportToMaterialProvider2_5Localization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	NotCheckedAttributeArray = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5 Then
		PresentationOfTS = NStr("ru = 'Выпускаемая продукция';
								|vi = 'Released products';
								|en = 'Released products'; fa = 'محصولات تولیدشده';
								|it = 'Prodotti in fabbricazione';
								|pl = 'Wypuszczana produkcja';
								|tr = 'İmal edilen ürünler'");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		PresentationOfTS = NStr("ru = 'Выполняемые работы';
								|vi = 'Works to perform';
								|en = 'Works to perform'; fa = 'کارهای قابل انجام';
								|it = 'Works to perform';
								|pl = 'Works to perform';
								|tr = 'Yapılan işler'");
	EndIf;
	
	If Not ReportOnOrders
		Or ValueIsFilled(MaterialProviderOrder) Then
		NotCheckedAttributeArray.Add("ManufacturedProduct.MaterialProviderOrder");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		NotCheckedAttributeArray.Add("Warehouse");
		NotCheckedAttributeArray.Add("VATRate");
		NotCheckedAttributeArray.Add("ProcessingService");
	EndIf;
	
	QuantityVerificationParameters = Documents.ReportToMaterialProvider2_5.RoundingParameters();
	QuantityVerificationParameters.PresentationOfTS = PresentationOfTS;
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "ManufacturedProduct";
	CheckParameters.PresentationOfTS = PresentationOfTS;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	SeriesFillCheckParameters = ProductsServer.SeriesFillCheckParameters();
	SeriesFillCheckParameters.PresentationOfTS = PresentationOfTS;
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReportToMaterialProvider2_5),
		Cancel,
		NotCheckedAttributeArray,
		SeriesFillCheckParameters);
		
	NotCheckedAttributeArray.Add("ManufacturedProduct.Products");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Recipient");
	NotCheckedAttributeArray.Add("ManufacturedProduct.VATRate");
	
	ErrorText = NStr("ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3"".';
					|vi = 'The ""%1"" field in line %2 of the ""%3"" list is not filled in.';
					|en = 'The ""%1"" field in line %2 of the ""%3"" list is not filled in.'; fa = 'The ""%1"" field in line %2 of the ""%3"" list is not filled in.';
					|it = 'The ""%1"" field in line %2 of the ""%3"" list is not filled in.';
					|pl = 'The ""%1"" field in line %2 of the ""%3"" list is not filled in.';
					|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'");
	
	For Each CurrentData In ManufacturedProduct Do
		
		If CurrentData.ToExpenseAs
			And Not ValueIsFilled(CurrentData.Recipient) Then
			
			FieldName = NStr("vi = 'Người nhận';
							|ru = 'Получатель';
							|en = 'Recipient'; fa = 'گیرنده';
							|it = 'Получатель';
							|pl = 'Recipient';
							|tr = 'Alıcı'");
			
			PathToTabularSection =
				CommonClientServer.PathToTabularSection("ManufacturedProduct", CurrentData.LineNumber, "Recipient");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, FieldName, CurrentData.LineNumber, PresentationOfTS),
				ThisObject,
				PathToTabularSection,,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(CurrentData.Products) Then
			
			FieldName = NStr("vi = 'Mặt hàng';
							|ru = 'Номенклатура';
							|en = 'Item'; fa = 'قلم';
							|it = 'Номенклатура';
							|pl = 'Pozycja';
							|tr = 'Öğe'");
			
			PathToTabularSection =
				CommonClientServer.PathToTabularSection("ManufacturedProduct", CurrentData.LineNumber, "Products");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, FieldName, CurrentData.LineNumber, PresentationOfTS),
				ThisObject,
				PathToTabularSection,,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(CurrentData.VATRate) Then
			
			FieldName = NStr("vi = 'Thuế suất GTGT';
							|ru = 'Ставка НДС';
							|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
							|it = 'Aliquota IVA';
							|pl = 'Stawka VAT';
							|tr = 'KDV oranı'");
			
			PathToTabularSection =
				CommonClientServer.PathToTabularSection("ManufacturedProduct", CurrentData.LineNumber, "VATRate");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, FieldName, CurrentData.LineNumber, PresentationOfTS),
				ThisObject,
				PathToTabularSection,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	ItemsAndDimensionsSelectionParameters = Documents.ReportToMaterialProvider2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(
		ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	SalesServer.CheckShipmentBan(Partner, Cancel);
	
	ReportToMaterialProvider2_5Localization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ReportToMaterialProvider2_5.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	ReportToMaterialProvider2_5Localization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.ReportToMaterialProvider2_5.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	ReportToMaterialProvider2_5Localization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ReportOnOrders = False;
	MaterialProviderOrder  = Undefined;
	Approved     = False;
	
	InitializeDocumentBeforeFilling();
	
	For Each CurrentData In ManufacturedProduct Do
		CurrentData.MaterialProviderOrder       = Undefined;
		CurrentData.RowCode           = 0;
		CurrentData.RowID = Undefined;
	EndDo;
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	ReportToMaterialProvider2_5Localization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReportToMaterialProvider2_5Localization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillOutDocumentBasedOnGiverSOrder2_5(DocumentBasis, OrderDetails = Undefined)
	
	BasisType = TypeOf(DocumentBasis);
	
	If BasisType = Type("DocumentRef.MaterialProviderOrder2_5") Then
	
		Query = New Query;
		Query.Text =
		"SELECT
		|	MaterialProviderOrder2_5.Ref                             AS MaterialProviderOrder,
		|	CASE
		|		WHEN MaterialProviderOrder2_5.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
		|			THEN VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5)
		|		ELSE MaterialProviderOrder2_5.BusinessOperation
		|	END                                               AS BusinessOperation,
		|	MaterialProviderOrder2_5.SalesOpportunity                             AS SalesOpportunity,
		|	MaterialProviderOrder2_5.Status                             AS DocumentStatus,
		|	MaterialProviderOrder2_5.Organization                        AS Organization,
		|	MaterialProviderOrder2_5.Warehouse                              AS Warehouse,
		|	MaterialProviderOrder2_5.BankAccount                     AS CompanyBankAccount,
		|	MaterialProviderOrder2_5.Department                      AS Department,
		|	MaterialProviderOrder2_5.ARAPObjectSettings                    AS ARAPObjectSettings,
		|	MaterialProviderOrder2_5.PaymentMethod                        AS PaymentMethod,
		|	MaterialProviderOrder2_5.FinancialAccountingGroup             AS FinancialAccountingGroup,
		|	MaterialProviderOrder2_5.CashAccount                              AS CashAccount,
		|	MaterialProviderOrder2_5.Currency                             AS Currency,
		|	MaterialProviderOrder2_5.Currency                             AS ARAPCurrency,
		|	MaterialProviderOrder2_5.PaymentSchedule                       AS PaymentSchedule,
		|	MaterialProviderOrder2_5.LineOfBusiness            AS LineOfBusiness,
		|	MaterialProviderOrder2_5.ForeignCurrencyTransaction                      AS ForeignCurrencyTransaction,
		|	MaterialProviderOrder2_5.Partner                            AS Partner,
		|	MaterialProviderOrder2_5.Counterparty                         AS Counterparty,
		|	MaterialProviderOrder2_5.Contract                            AS Contract,
		|	MaterialProviderOrder2_5.ContactPerson                     AS ContactPerson,
		|	MaterialProviderOrder2_5.CounterpartyBankAccount          AS CounterpartyBankAccount,
		|	MaterialProviderOrder2_5.PriceIncludesVAT                    AS PriceIncludesVAT,
		|	MaterialProviderOrder2_5.VATTaxation                 AS VATTaxation,
		|	MaterialProviderOrder2_5.VATRate                          AS VATRate,
		|	MaterialProviderOrder2_5.ProcessingService                AS ProcessingService,
		|	NOT MaterialProviderOrder2_5.Posted                        AS ThereAreErrorsPosted,
		|	NOT MaterialProviderOrder2_5.Status IN (&AcceptableStatuses)   AS ThereAreErrorsStatus
		|FROM
		|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
		|WHERE
		|	MaterialProviderOrder2_5.Ref = &MaterialProviderOrder";
		
		Query.SetParameter("MaterialProviderOrder", DocumentBasis);
		
		AcceptableStatuses = Documents.MaterialProviderOrder2_5.ValidInputStatusesBasedOn(Metadata().Name);
		Query.SetParameter("AcceptableStatuses", AcceptableStatuses);
		
		QueryResult = Query.Execute();
		
		OrderDetails = QueryResult.Select();
		OrderDetails.Next();
		
		CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
		CheckParameters.Status = OrderDetails.DocumentStatus;
		CheckParameters.ThereAreErrorsPosted = OrderDetails.ThereAreErrorsPosted;
		CheckParameters.ThereAreErrorsStatus = OrderDetails.ThereAreErrorsStatus;
		CheckParameters.ArrayOfValidStatuses = AcceptableStatuses;
		
		TMCommonUse.CheckPossibilityOfInputBasedOnParameters(OrderDetails.MaterialProviderOrder, CheckParameters);
		
		// Filling in the header
		FillPropertyValues(ThisObject, OrderDetails);
		
	ElsIf BasisType = Type("Array") Then
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
		Currency                    = ARAPCurrency;
		CompanyBankAccount = OrderDetails.CompanyBankAccount;
		
	EndIf;
	
	If BasisType = Type("Array") Then
		AnArrayOfOrders = DocumentBasis;
	Else
		AnArrayOfOrders = New Array;
		AnArrayOfOrders.Add(DocumentBasis);
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("DisplayMessage_1", True);
	
	Documents.ReportToMaterialProvider2_5.FillByOrderBalances(ThisObject, ManufacturedProduct, AnArrayOfOrders, FillParameters);
	
	MaterialProviderOrder = ?(GetFunctionalOption("UseReportToMaterialProviderBySeveralOrders2_5"),
						Undefined,
						AnArrayOfOrders[0]);
	
	If Not ValueIsFilled(MaterialProviderOrder) And ManufacturedProduct.Count() = 0 Then
		Raise NStr("vi = 'Không có số dư cần lập.';
					|ru = 'Нет остатков к оформлению.';
					|en = 'There are no remaining goods to register.'; fa = 'There are no remaining goods to register.';
					|it = 'Non vi sono saldi da formalizzare.';
					|pl = 'Brak zapasów do rejestracji.';
					|tr = 'Hazırlanacak herhangi bir bakiye bulunmamaktadır.'");
	Else
		ReportOnOrders = True;
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnShipmentOfGoodsFromStorage(DocumentBasis)
	
	DataBasis = Common.ObjectAttributesValues(
						DocumentBasis,
						"Organization, Contract, Warehouse, ByOrder, Basis");
	
	If DataBasis.ByOrder Then
		
		If ValueIsFilled(DataBasis.Basis) Then
			FillOutDocumentBasedOnGiverSOrder2_5(DataBasis.Basis);
		Else
			
			TextException =
				NStr("vi = 'Đã lập báo cáo dành cho bên đặt gia công theo nhiều đơn hàng. Không thể nhập trên cơ sở.
						   |Hãy sử dụng chỗ làm việc ""Nhận gia công"" - ""Chứng từ cần lập"".';
						   |ru = 'Передача давальцу оформлено по нескольким заказам. Ввод на основании невозможен.
						   |Воспользуйтесь рабочим местом ""Прием в переработку"" - ""Документы к оформлению"".';
						   |en = 'Transfer to the provider is registered under several orders. Cannot generate from base documents.
						   |Use the ""Subcontracting services delivered - Unregistered documents"" workplace.'; fa = 'Transfer to the provider is registered under several orders. Cannot generate from base documents.
						   |Use the ""Subcontracting services delivered - Unregistered documents"" workplace.';
						   |it = 'Trasferimento al fornitore formalizzato in base a più ordini. Impossibile inserire nella base.
						   |Utilizzare la postazione di lavoro ""Ricezione in elaborazione"" - ""Documenti da formalizzare"".';
						   |pl = 'Przekazanie do właściciela zapasów zostało zarejestrowane według kilku zamówień. Wprowadzenie na podstawie jest niemożliwe.
						   |Skorzystaj z miejsca pracy ""Przyjęcie do przetwarzania"" - ""Dokumenty do rejestracji"".';
						   |tr = 'Birden fazla sipariş için tedarikçiye transfer düzenlenmiştir. Buna dayalı giriş mümkün değildir.
						   | Lütfen ""İşlem için teslim alma"" - ""Düzenlenecek belgeler"" çalışma alanını kullanın.'");
			
			Raise TextException;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	QueryTexts = New Array;
	
	QueryText =
	"SELECT
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.Purpose        AS Purpose,
	|	Goods.Series             AS Series,
	|	Goods.Warehouse             AS Warehouse,
	|	SUM(Goods.Count) AS Count
	|INTO Goods
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products      AS Products,
	|	SetOfSeries.Characteristic    AS Characteristic,
	|	SetOfSeries.Purpose        AS Purpose,
	|	SetOfSeries.Series             AS Series,
	|	SetOfSeries.Warehouse             AS Warehouse,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SetOfSeries
	|FROM
	|	Document.GoodsShipmentFromStorage.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Series,
	|	SetOfSeries.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products                                  AS Products,
	|	Goods.Characteristic                                AS Characteristic,
	|	Goods.Purpose                                    AS Purpose,
	|	ISNULL(SetOfSeries.Series, Goods.Series)                  AS Series,
	|	Goods.Warehouse                                         AS Warehouse,
	|	SUM(ISNULL(SetOfSeries.Count, Goods.Count)) AS Count
	|INTO TableOfGoods
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN SetOfSeries AS SetOfSeries
	|		ON Goods.Products   = SetOfSeries.Products
	|		 AND Goods.Characteristic = SetOfSeries.Characteristic
	|		 AND Goods.Purpose     = SetOfSeries.Purpose
	|		 AND Goods.Warehouse          = SetOfSeries.Warehouse
	|		 AND Goods.Series          = VALUE(Catalog.ItemsBatches.EmptyRef)
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	ISNULL(SetOfSeries.Series, Goods.Series),
	|	Goods.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|";
	
	QueryTexts.Add(QueryText);
	
	AdditionalConditionsOrganizationSProducts = 
		"InventoryOwnerAttribute.Contract = &Contract
		|AND (ItemsLocationAttributes.Products,
		|	ItemsLocationAttributes.Characteristic,
		|	ItemsLocationAttributes.Purpose,
		|	ItemsLocationAttributes.Series,
		|	ItemsLocationAttributes.StorageLocation) IN
		|		(SELECT
		|			TableOfGoods.Products   AS Products,
		|			TableOfGoods.Characteristic AS Characteristic,
		|			TableOfGoods.Purpose     AS Purpose,
		|			TableOfGoods.Series          AS Series,
		|			TableOfGoods.Warehouse          AS Warehouse
		|		FROM
		|			TableOfGoods AS TableOfGoods)";
		
	AdditionalConditionsCustomerOrders =
		"TRUE IN 
		|	(SELECT TOP 1
		|		TRUE
		|	FROM
		|		TableOfGoods AS TableOfGoods
		|	WHERE
		|		TableOfGoods.Products     = Turnovers.Products
		|		AND TableOfGoods.Characteristic = Turnovers.Characteristic
		|		AND TableOfGoods.Purpose     = Goods.Purpose
		|		AND TableOfGoods.Series          = Turnovers.Series
		|		AND TableOfGoods.Warehouse          = Turnovers.Warehouse)";
		
	ConditionForSelectingResidues = "VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
							|AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Contract = &Contract";
	
	QueryTextBalancesWithoutOrder = StrReplace(InvoicesServer.TextOfRequestForStateOfReportsGivers2_5BalancesWithoutOrder(),
												"&AdditionalConditionsOrganizationSProducts",
												AdditionalConditionsOrganizationSProducts);
	
	QueryTextBalancesWithoutOrder = StrReplace(QueryTextBalancesWithoutOrder,
												"&AdditionalConditionsCustomerOrders",
												AdditionalConditionsCustomerOrders);
	
	QueryTextBalancesWithoutOrder = StrReplace(QueryTextBalancesWithoutOrder,
												"&ConditionForSelectingResidues",
												ConditionForSelectingResidues);
	
	QueryText =
	"SELECT
	|	BalancesWithoutOrder.Products   AS Products,
	|	BalancesWithoutOrder.Characteristic AS Characteristic,
	|	BalancesWithoutOrder.Purpose     AS Purpose,
	|	BalancesWithoutOrder.Series          AS Series,
	|	BalancesWithoutOrder.Warehouse          AS Warehouse,
	|	BalancesWithoutOrder.ToRegister    AS ToRegister
	|INTO BalancesWithoutOrder
	|FROM
	|	&BalancesWithoutOrder AS BalancesWithoutOrder
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
	|		WHEN TableOfGoods.Count > BalancesWithoutOrder.ToRegister
	|			THEN BalancesWithoutOrder.ToRegister
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
	
	QueryTexts.Add(StrReplace(QueryText, "&BalancesWithoutOrder", StrTemplate("(%1)", QueryTextBalancesWithoutOrder)));
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("DocumentBasis",       DocumentBasis);
	Query.SetParameter("Contract",                 DataBasis.Contract);
	Query.SetParameter("SelectByOrganization",   True);
	Query.SetParameter("Organization",             DataBasis.Organization);
	Query.SetParameter("SelectByWarehouse",        False);
	Query.SetParameter("Warehouse",                   Undefined);
	Query.SetParameter("SelectByDivision", False);
	Query.SetParameter("Department",           Undefined);
	Query.SetParameter("SelectByManager",     False);
	Query.SetParameter("Manager",                Undefined);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Raise NStr("vi = 'Không có số dư cần lập.';
					|ru = 'Нет остатков к оформлению.';
					|en = 'There are no remaining goods to register.'; fa = 'There are no remaining goods to register.';
					|it = 'Non vi sono saldi da formalizzare.';
					|pl = 'Brak zapasów do rejestracji.';
					|tr = 'Hazırlanacak herhangi bir bakiye bulunmamaktadır.'");
	EndIf;
	
	ReferencesArrray = New Array;
	ReferencesArrray.Add(DataBasis.Contract);
	
	OrderProperties_ = New Structure;
	OrderProperties_.Insert("Warehouse", DataBasis.Warehouse);
	
	FillPropertyValues(
		ThisObject,
		Documents.ReportToMaterialProvider2_5.InvoiceFillingData(ReferencesArrray, OrderProperties_));
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		LineTSProducts = ManufacturedProduct.Add();
		FillPropertyValues(LineTSProducts, Selection);
		LineTSProducts.NumberOfPackages = Selection.Count;
		
	EndDo;
	
EndProcedure

Procedure FillInDocumentOnBasisOfContract(ContractBasis, ContractDetails_ = Undefined)
	
	BasisType = TypeOf(ContractBasis);
	
	If ValueIsFilled(ContractDetails_) Then
		
		FillPropertyValues(ThisObject, ContractDetails_);
		
	ElsIf BasisType = Type("CatalogRef.CounterpartyContracts") Then
	
		Query = New Query;
		Query.Text =
		"SELECT
		|	Contracts.Partner                   AS Partner,
		|	Contracts.Counterparty                AS Counterparty,
		|	Contracts.Ref                    AS Contract,
		|	Contracts.Organization               AS Organization,
		|	Contracts.Department             AS Department,
		|	Contracts.ARAPCurrency      AS Currency,
		|	Contracts.ARAPCurrency      AS ARAPCurrency,
		|	Contracts.LineOfBusiness   AS LineOfBusiness,
		|	Contracts.VATTaxation        AS VATTaxation,
		|	Contracts.VATRate                 AS VATRate,
		|	UNDEFINED                       AS Products,
		|	UNDEFINED                       AS Characteristic,
		|	UNDEFINED                       AS Content,
		|	UNDEFINED                       AS PriceIncludesVAT,
		|	Contracts.BankAccount            AS CompanyBankAccount,
		|	Contracts.CounterpartyBankAccount AS CounterpartyBankAccount
		|FROM
		|	Catalog.CounterpartyContracts AS Contracts
		|WHERE
		|	Contracts.Ref = &ContractBasis";
		
		Query.SetParameter("ContractBasis", ContractBasis);
		
		Result = Query.Execute();
		
		HeaderAttributes = Result.Select();
		HeaderAttributes.Next();
		
		FillPropertyValues(ThisObject, HeaderAttributes);
		
	EndIf;
	
	AdditionalConditionsOrganizationSProducts = "InventoryOwnerAttribute.Contract IN (&Contract)";
	
	AdditionalConditionsCustomerOrders    = "TRUE";
	
	ConditionForSelectingResidues = "VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
							|AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Contract IN (&Contract)";
	
	QueryTexts = StrReplace(InvoicesServer.TextOfRequestForStateOfReportsGivers2_5BalancesWithoutOrder(),
								"&AdditionalConditionsOrganizationSProducts",
								AdditionalConditionsOrganizationSProducts);
	
	QueryTexts = StrReplace(QueryTexts,
								"&AdditionalConditionsCustomerOrders",
								AdditionalConditionsCustomerOrders);
	
	QueryTexts = StrReplace(QueryTexts, "&ConditionForSelectingResidues", ConditionForSelectingResidues);
	
	Query = New Query;
	Query.Text = QueryTexts;
	
	Query.SetParameter("Contract",                 ContractBasis);
	Query.SetParameter("SelectByOrganization",   False);
	Query.SetParameter("Organization",             Undefined);
	Query.SetParameter("SelectByWarehouse",        False);
	Query.SetParameter("Warehouse",                   Undefined);
	Query.SetParameter("SelectByDivision", False);
	Query.SetParameter("Department",           Undefined);
	Query.SetParameter("SelectByManager",     False);
	Query.SetParameter("Manager",                Undefined);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Raise NStr("vi = 'Không có số dư cần lập.';
					|ru = 'Нет остатков к оформлению.';
					|en = 'There are no remaining goods to register.'; fa = 'There are no remaining goods to register.';
					|it = 'Non vi sono saldi da formalizzare.';
					|pl = 'Brak zapasów do rejestracji.';
					|tr = 'Hazırlanacak herhangi bir bakiye bulunmamaktadır.'");
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		LineTSProducts = ManufacturedProduct.Add();
		FillPropertyValues(LineTSProducts, Selection);
		LineTSProducts.Count         = Selection.ToRegister;
		LineTSProducts.NumberOfPackages = Selection.ToRegister;
		
	EndDo;
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)

	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		FillInDefaultSalesConditions();
		
	EndIf;
	
EndProcedure

Procedure InitializeDocumentBeforeFilling()
	
	If Not ValueIsFilled(BusinessOperation)
		Or BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5 Then
		BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5;
	EndIf;
	
EndProcedure

Procedure InitializeDocument()
	
	Currency               = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(ARAPCurrency);
	Organization          = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If ValueIsFilled(Contract) And Not ValueIsFilled(Department) Then
		Department = Common.ObjectAttributeValue(Contract, "Department");
	EndIf;
	
	If Not ValueIsFilled(CompanyBankAccount) Or Not ValueIsFilled(CounterpartyBankAccount) Then
		SalesServer.FillInBankAccountsUnderAgreement(Contract,
			?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
			?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization  = Organization;
	ParametersStructure.CashAccount        = CashAccount;
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	FillParameters = Documents.ReportToMaterialProvider2_5.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	
	BatchProcessingOfTablePartServer.ProcessTSString(ThisObject, StructureOfActions, CachedValues);
	RecalculateVATAmounts = Not CachedValues.ProcessedRows.Count() = 0;
	
	BatchProcessingOfTablePartServer.TreatTS(ManufacturedProduct, StructureOfActions, CachedValues);
	RecalculateVATAmounts = RecalculateVATAmounts Or Not CachedValues.ProcessedRows.Count() = 0;
	
	If RecalculateVATAmounts Then
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartServer.TreatTS(ManufacturedProduct, StructureOfActions, Undefined);
		
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager  = TemporaryDocumentDataTables();
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(
			ThisObject, TempTablesManager, Cancel, FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN, Sum");
		
		FillInAdditionalFieldsForInventoryTypes(TempTablesManager);
		
	EndIf;
	
	If Not Cancel Then
		TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	
	FillParameters.SelectTypesOfStocksForIntercampany = False;
	
	Return FillParameters;
	
EndFunction

Procedure FillInAdditionalFieldsForInventoryTypes(TempTablesManager)
	
	// Filling in the field of CORVIDS must correspond to the procedure for filling in the column of Corvids() 
	// in the document of the Implementation adjustment.
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	DocumentDataTable.Organization           AS Organization,
	|	DocumentDataTable.GoodsOwner        AS GoodsOwner,
	|	DocumentDataTable.Counterparty            AS Counterparty,
	|	DocumentDataTable.Terms            AS Terms,
	|	DocumentDataTable.Contract               AS Contract,
	|	DocumentDataTable.Currency                AS Currency,
	|	DocumentDataTable.VATTaxation    AS TaxationOfOrganization,
	|	DocumentDataTable.BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider) AS InventoryType,
	|	TableOfGoods.Products                  AS Products,
	|	TableOfGoods.Products.FinancialAccountingGroup AS FinancialAccountingGroup
	|FROM
	|	DocumentDataTable AS DocumentDataTable
	|		LEFT JOIN TableOfGoods AS TableOfGoods
	|		ON TRUE
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|
	|GROUP BY
	|	DocumentDataTable.Organization,
	|	DocumentDataTable.GoodsOwner,
	|	DocumentDataTable.Counterparty,
	|	DocumentDataTable.Terms,
	|	DocumentDataTable.Contract,
	|	DocumentDataTable.Currency,
	|	DocumentDataTable.VATTaxation,
	|	DocumentDataTable.BusinessOperation,
	|	DocumentDataTable.InventoryType,
	|	TableOfGoods.Products,
	|	TableOfGoods.Products.FinancialAccountingGroup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.RowID        AS RowID,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.MaterialProviderOrder              AS MaterialProviderOrder,
	|	TableOfGoods.ToExpenseAs           AS ToExpenseAs,
	|	TableOfGoods.Recipient                 AS Recipient,
	|	TableOfGoods.ExpenseItem             AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableOfGoods.GLAccountSettings       AS GLAccountSettings,
	|	TableOfGoods.Package                   AS Package,
	|	TableOfGoods.ARAPObject             AS ARAPObject,
	|	TableOfGoods.VATRate                  AS VATRate,
	|	TableOfGoods.NumberOfPackages         AS NumberOfPackages,
	|	TableOfGoods.Count                 AS Count,
	|	TableOfGoods.Price                       AS Price,
	|	TableOfGoods.Sum                      AS Sum,
	|	TableOfGoods.VATAmount                   AS VATAmount,
	|	TableOfGoods.AmountIncludingVAT                  AS AmountIncludingVAT,
	|	TableOfGoods.AmountARAP        AS AmountARAP
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|ORDER BY
	|	TableOfGoods.LineNumber
	|";
	
	ResultsArray = Query.ExecuteBatch();
	
	SamplingCorTypeOfInventory = ResultsArray[ResultsArray.UBound() - 1].Select();
	
	CorTypesOfStocks = New Map;
	While SamplingCorTypeOfInventory.Next() Do
		CorTypesOfStocks.Insert(
			SamplingCorTypeOfInventory.Products,
			Catalogs.InventoryKinds.DocumentInventoryView(Organization, BusinessOperation, SamplingCorTypeOfInventory));
	EndDo;
	
	FilterOfProducts_ = New Structure("ItemsLocationAttributes");
	
	GoodsTable = ResultsArray[ResultsArray.UBound()].Unload();
	For Each RowOfProduct In GoodsTable Do
		
		GoodsQuantity  = RowOfProduct.Count;
		
		FillPropertyValues(FilterOfProducts_, RowOfProduct);
		
		RowsArray = InventoryKinds.FindRows(FilterOfProducts_);
		For Each InventoryLine In RowsArray Do
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfProduct,, "ItemsLocationAttributes, Count, NumberOfPackages, 
			|Sum, VATAmount, AmountIncludingVAT, AmountARAP");
			
			NewRow.CorInventoryOwnerAttribute      = CorTypesOfStocks.Get(RowOfProduct.Products);
			
			NewRow.Count         = Count;
			NewRow.QuantityByGBRN   = ?(Count = GoodsQuantity,
													InventoryLine.QuantityByGBRN,
													InventoryLine.QuantityByGBRN * Count / GoodsQuantity);
			
			NewRow.NumberOfPackages = ?(Count = GoodsQuantity,
													RowOfProduct.NumberOfPackages,
													RowOfProduct.NumberOfPackages * Count / GoodsQuantity);
			
			NewRow.Sum              = ?(Count = GoodsQuantity,
													RowOfProduct.Sum,
													RowOfProduct.Sum * Count / GoodsQuantity);
			
			NewRow.VATAmount           = ?(Count = GoodsQuantity,
													RowOfProduct.VATAmount,
													RowOfProduct.VATAmount * Count / GoodsQuantity);
													
			NewRow.AmountIncludingVAT           = ?(Count = GoodsQuantity,
													RowOfProduct.AmountIncludingVAT,
													RowOfProduct.AmountIncludingVAT * Count / GoodsQuantity);
			
			NewRow.AmountARAP = ?(Count = GoodsQuantity,
													RowOfProduct.AmountARAP,
													RowOfProduct.AmountARAP * Count / GoodsQuantity);
			
			InventoryLine.Count       = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			RowOfProduct.NumberOfPackages = RowOfProduct.NumberOfPackages - NewRow.NumberOfPackages;
			RowOfProduct.Sum              = RowOfProduct.Sum - NewRow.Sum;
			RowOfProduct.VATAmount           = RowOfProduct.VATAmount - NewRow.VATAmount;
			RowOfProduct.AmountIncludingVAT          = RowOfProduct.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			RowOfProduct.AmountARAP = RowOfProduct.AmountARAP - NewRow.AmountARAP;
			
			GoodsQuantity  = GoodsQuantity - NewRow.Count;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(New Structure("Count", 0));
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Contract, Warehouse";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|		TableOfGoods.RowID        AS RowID,
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.MaterialProviderOrder              AS MaterialProviderOrder,
	|		TableOfGoods.ToExpenseAs           AS ToExpenseAs,
	|		TableOfGoods.ExpenseItem             AS ExpenseItem,
	|		TableOfGoods.DimensionOfExpenses          AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|		TableOfGoods.Recipient                 AS Recipient,
	|		TableOfGoods.Package                   AS Package,
	|		TableOfGoods.ARAPObject             AS ARAPObject,
	|		TableOfGoods.VATRate                  AS VATRate,
	|		TableOfGoods.Price                       AS Price
	|FROM
	|	(SELECT
	|		TableOfGoods.RowID        AS RowID,
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.MaterialProviderOrder              AS MaterialProviderOrder,
	|		TableOfGoods.ToExpenseAs           AS ToExpenseAs,
	|		TableOfGoods.ExpenseItem             AS ExpenseItem,
	|		TableOfGoods.DimensionOfExpenses          AS DimensionOfExpenses,
	|		TableOfGoods.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|		TableOfGoods.Recipient                 AS Recipient,
	|		TableOfGoods.Package                   AS Package,
	|		TableOfGoods.ARAPObject             AS ARAPObject,
	|		TableOfGoods.VATRate                  AS VATRate,
	|		TableOfGoods.Price                       AS Price,
	|		TableOfGoods.NumberOfPackages         AS NumberOfPackages,
	|		TableOfGoods.Count                 AS Count,
	|		TableOfGoods.Sum                      AS Sum,
	|		TableOfGoods.VATAmount                   AS VATAmount,
	|		TableOfGoods.AmountIncludingVAT                  AS AmountIncludingVAT,
	|		TableOfGoods.AmountARAP        AS AmountARAP
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.RowID        AS RowID,
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.MaterialProviderOrder              AS MaterialProviderOrder,
	|		TableTypesOfStocks_.ToExpenseAs           AS ToExpenseAs,
	|		TableTypesOfStocks_.ExpenseItem             AS ExpenseItem,
	|		TableTypesOfStocks_.DimensionOfExpenses          AS DimensionOfExpenses,
	|		TableTypesOfStocks_.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|		TableTypesOfStocks_.Recipient                 AS Recipient,
	|		TableTypesOfStocks_.Package                   AS Package,
	|		TableTypesOfStocks_.ARAPObject             AS ARAPObject,
	|		TableTypesOfStocks_.VATRate                  AS VATRate,
	|		TableTypesOfStocks_.Price                       AS Price,
	|		-TableTypesOfStocks_.NumberOfPackages        AS NumberOfPackages,
	|		-TableTypesOfStocks_.Count                AS Count,
	|		-TableTypesOfStocks_.Sum                     AS Sum,
	|		-TableTypesOfStocks_.VATAmount                  AS VATAmount,
	|		-TableTypesOfStocks_.AmountIncludingVAT                 AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.AmountARAP       AS AmountARAP
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.RowID,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.MaterialProviderOrder,
	|	TableOfGoods.ToExpenseAs,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.Recipient,
	|	TableOfGoods.Package,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Price
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.NumberOfPackages) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|";
	
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

#EndRegion

#Region Other

Procedure FillInPaymentTerms_(Val SalesTermsAndConditions)
	
	PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	If ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization = Organization Then
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization				= Organization;
		ParametersStructure.PaymentMethod				= PaymentMethod;
		ParametersStructure.LineOfBusiness	= LineOfBusiness;
		
		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
	EndIf;
	
EndProcedure

Procedure CreateListOfDependentOrders()
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	SalesOrder.Ref AS SalesOrder
	|FROM
	|	Document.MaterialProviderOrder2_5 AS SalesOrder
	|WHERE
	|	SalesOrder.Ref IN(&AnArrayOfOrders)
	|	
	|GROUP BY
	|	SalesOrder.Ref
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	SalesOrder.Ref AS SalesOrder
	|FROM
	|	Document.MaterialProviderOrder2_5 AS SalesOrder
	|		INNER JOIN Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ReportProducts
	|		ON SalesOrder.Ref = ReportProducts.MaterialProviderOrder
	|WHERE
	|	ReportProducts.Ref = &Ref
	|	AND SalesOrder.Ref NOT IN(&AnArrayOfOrders)
	|	
	|GROUP BY
	|	SalesOrder.Ref
	|";
	
	Query.SetParameter("Ref",        Ref);
	Query.SetParameter("AnArrayOfOrders", ManufacturedProduct.UnloadColumn("MaterialProviderOrder"));
	
	SetPrivilegedMode(True);
	
	ArrayOfDependentOrders = Query.Execute().Unload().UnloadColumn("SalesOrder");
	
	AdditionalProperties.Insert(
		"ArrayOfDependentCustomerOrders", New FixedArray(ArrayOfDependentOrders));
	
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
