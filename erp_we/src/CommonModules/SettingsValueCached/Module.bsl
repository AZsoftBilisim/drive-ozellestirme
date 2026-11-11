
#Region Public

#Region FunctionsForGettingDefaultValues

// The function determines the bank account based on the parameters passed.
//
// Returns a link to the account if one bank account was found based on the parameters.
// Returns an empty link if no bank account was found or there are more than one accounts.
//
// Parameters:
//  ParametersOfAccount - See CashServer.ParametersForFillingInCounterpartySBankAccount.
//
// Returns:
//  CatalogRef.CounterpartyBankAccounts - counterparty's default bank account.
//
Function DefaultCounterpartyBankAccount(ParametersOfAccount) Export
	
	Return Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(ParametersOfAccount.Counterparty,
		ParametersOfAccount.Currency, ParametersOfAccount.OffsettingAccount, ParametersOfAccount.ExcludeCurrencyAccounts);
	
EndFunction

// Defines the organization's bank account by the specified parameters.
//
// See Catalogs.CompaniesBankAccounts.GetDefaultBankAccount.
//
// Parameters:
//  ParametersOfAccount - See CashServer.ParametersForFillingOutOrganizationSBankAccount.
//
// Returns:
//  CatalogRef.CompaniesBankAccounts - counterparty's default bank account.
//
Function OrganizationSDefaultBankAccount(ParametersOfAccount) Export
	
	Return Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
	
EndFunction

// Gets an organization if it is the only one in the IB
// If the organization passed as a parameter is already filled in, returns it.
// If the organization is not passed as a parameter or an empty one is passed,
// it returns the only organization in the information database. If
// there is more than one organization in the database, it returns an empty link to the organization.
//
// Parameters:
//   Organization - CatalogRef.Companies - The organization to fill in.
//
// Returns:
//   CatalogRef.Companies - default organization.
//
Function GetDefaultOrganization(Val Organization = Undefined) Export

	If Not ValueIsFilled(Organization) Then
		Return Catalogs.Companies.GetDefaultOrganization();
	Else
		Return Organization;
	EndIf;
	
EndFunction

// Returns the version of the classification by default.
// If there is only one option in the IB that is not marked for deletion,
// a link to it will be returned, otherwise a link to the first element created in the directory will be returned.
//
// Parameters:
//  OnlyIfOne - Boolean - returns a variant only if it is the only one in the IB.
//
// Returns:
//  CatalogRef.TimeBucketsForAgingAnalysis - link to the option.
//
Function DefaultDebtClassificationOption(OnlyIfOne = False) Export
	SetPrivilegedMode(True);
	DefaultDebtClassificationOption = Catalogs.TimeBucketsForAgingAnalysis.EmptyRef();
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 2
	|	TimeBucketsForAgingAnalysis.Ref AS Ref
	|FROM
	|	Catalog.TimeBucketsForAgingAnalysis AS TimeBucketsForAgingAnalysis
	|WHERE
	|	NOT TimeBucketsForAgingAnalysis.DeletionMark";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If OnlyIfOne And Selection.Count() = 1 
			Or Not OnlyIfOne Then
			DefaultDebtClassificationOption = Selection.Ref;
		EndIf;
	EndIf;
	SetPrivilegedMode(False);
	
	Return DefaultDebtClassificationOption;
EndFunction

// Gets the dispatcher division, if it is the only one in the IB
// If the passed parameter division Manager is already filled in, it returns it.
// If the dispatcher division is not passed as a parameter, or an empty one is passed,
//	it returns the only dispatcher division in the information database. 
// If there are several dispatcher divisions in the database, 
//	returns the dispatcher division from the user settings.
// If the dispatcher division is not specified in the user settings,
//	it returns an empty division.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - the division to fill in.
//  User - CatalogRef.Users - link to the user.
//
// Returns:
//  CatalogRef.BusinessStructure - the default division.
//
Function GetDefaultManagerDivision(Val Department = Undefined, Val User = Undefined) Export
	
	If Not ValueIsFilled(Department) Then
		Return Catalogs.BusinessStructure.GetDefaultManagerDivision(User);
	Else
		Return Department;
	EndIf;
	
EndFunction

// Gets the priority used for filling in new documents.
//
// Parameters:
//  Priority - CatalogRef.Priorities	 - default priority.
// 
// Returns:
//  CatalogRef.Priorities - default priority.
//
Function GetDefaultPriority(Val Priority = Undefined) Export 
	
	If Not ValueIsFilled(Priority) Then
		Return Catalogs.Priorities.GetDefaultPriority();
	Else
		Return Priority;
	EndIf;
	
EndFunction

// Retrieves the cash flow item for the selected business transaction.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//
// Returns:
// 	CatalogRef.CashFlowReportItems - A predefined DDS article.
//
Function GetCashFlowItem(BusinessOperation) Export
	
	Return Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(BusinessOperation);
	
EndFunction // Get the status of the movement of monetary funds()

// Gets the division of the selected user.
//
// Parameters:
//	User - CatalogRef.Users - the current user.
//	Department - CatalogRef.BusinessStructure
//
// Returns:
//	DefinedType.Department - The user's division.
//
Function UserDivision(User, Department = Undefined) Export
	
	If Not ValueIsFilled(Department) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	Users.Department AS Department
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.Ref = &User";
		
		Query.SetParameter("User", User);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Department = Selection.Department;
		Else
			Department = Catalogs.BusinessStructure.EmptyRef();
		EndIf;
		
	EndIf;
	
	Return Department;
	
EndFunction // User's Subdivision()

// Returns the structure for the responsible person of the specified warehouse if the responsible person or their position is specified.
//
// Parameters:
// 		Warehouse - CatalogRef.Warehouses
//
// Returns:
// 		Undefined, Structure - structure with fields: 
// 		* EmployeeResponsible - CatalogRef.Persons
// 		* ResponsiblePosition - String
//
Function GetWarehouseManager(Warehouse) Export
	
	Structure = Common.ObjectAttributesValues(Warehouse, "CurrentEmployeeInChargeTypes, CurrentPositionOfTheResponsiblePerson");
	
	If ValueIsFilled(Structure.CurrentEmployeeInChargeTypes) Or ValueIsFilled(Structure.CurrentPositionOfTheResponsiblePerson) Then
		
		Return New Structure("EmployeeResponsible, ResponsiblePosition",
			Structure.CurrentEmployeeInChargeTypes,
			Structure.CurrentPositionOfTheResponsiblePerson);
		
	EndIf;
	
	Return Undefined;
	
EndFunction //Get the responsibleposclad()

// Returns an array of references to the warehouse groups that the specified warehouse belongs to in the hierarchy.
//
// Parameters:
//  Warehouse - CatalogRef.Warehouses - the warehouse for which you want to get an array of groups.
//
// Returns:
//  Array - an array of links to groups whose hierarchy includes the warehouse.
//
Function FolderHierarchy(Warehouse) Export
	Return Catalogs.Warehouses.FolderHierarchy(Warehouse);
EndFunction

// Gets a scenario by plan type if there is one in the IB
// If the Script passed as a parameter is already filled in, it returns it.
// If the Script is not passed as a parameter or is passed empty,
// it returns the only script in the information database. If there is more than one planning Scenario
// in the database, it returns an empty link to the scenario.
//
// Parameters:
//   PlanType - EnumRef.TypesOfPlans - Plan type: sales plan, purchase plan, etc.
//   Scenario - CatalogRef.SalesOperationsPlanningScenarios - The script to fill in.
//
// Returns:
//   CatalogRef.SalesOperationsPlanningScenarios - the default scheduling scenario.
//
Function GetDefaultScript(Val PlanType, Val Scenario = Undefined) Export

	If Not ValueIsFilled(Scenario) Then
		Return Planning.GetDefaultScript(PlanType);
	Else
		Return Scenario;
	EndIf;
	
EndFunction // Get a screenplay by Silence()

// Deprecated. Returns the currency of regulated accounting.
// If the currency passed as the parameter is already filled in, it returns it.
// If the currency is not passed as a parameter or an empty one is passed, the currency is used.
//  If the RU currency is not filled in, it returns an empty link to the currency.
//
// Parameters:
//   Currency - CatalogRef.Currencies - The currency to fill in.
//
// Returns:
//   CatalogRef.Currencies - default currency.
//
Function GetCurrencyOfRegulatedAccounting(Val Currency = Undefined) Export
	
	If Not ValueIsFilled(Currency) Then
		Return Constants.LocalAccountingCurrency.Get();
	Else
		Return Currency;
	EndIf;
	
EndFunction

// Returns the regulated accounting currency defined for the organization.
//
// Parameters:
//   Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the currency of regulated accounting.
//
// Returns:
//   CatalogRef.Currencies - 
//
Function CurrencyOfOrganizationSRegulatedAccounting(Val Organization) Export
	
	If Not ValueIsFilled(Organization) Then
		Return Undefined;
	Else
		Return Common.ObjectAttributeValue(Organization, "LocalAccountingCurrency");
	EndIf;
	
EndFunction

// Returns the default base currency.
//
// Returns:
//   CatalogRef.Currencies - 
//
Function DefaultBaseCurrency() Export
	
	Return Constants.DefaultBaseCurrency.Get();

EndFunction

// Returns the currency of management accounting.
//
// Returns:
//   CatalogRef.Currencies - 
//
Function ManagementAccountingCurrency() Export
	
	Return Constants.ManagementAccountingCurrency.Get();
	
EndFunction

// Returns the supplier's price type if it is the only one in the IB.
//
// Parameters:
// 	Vendor - CatalogRef.Partners - the partner to get the price type for.
//
// Returns:
// 	CatalogRef.VendorPriceTypes
//
Function DefaultVendorPriceView(Vendor) Export
	
	PriceKind = Undefined;
	
	Query = New Query(
	"SELECT TOP 2
	|	VendorPriceTypes.Ref
	|FROM
	|	Catalog.VendorPriceTypes AS VendorPriceTypes
	|WHERE
	|	VendorPriceTypes.Owner = &Owner");
	
	Query.SetParameter("Owner", Vendor);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Count() = 1 Then
		If Selection.Next() Then
			PriceKind = Selection.Ref;
		EndIf;
	EndIf;
	
	Return PriceKind
	
EndFunction

// Gets the shop storeroom of the selected division.
//
// Parameters:
//	Department	- CatalogRef.BusinessStructure - The division that the storeroom is defined for
//	ShopFloorStockroom	- CatalogRef.Warehouses - Previously obtained storeroom.
//
// Returns:
//	CatalogRef.Warehouses - The unit's storeroom.
//
Function GetDefaultShopPantry(Department, ShopFloorStockroom = Undefined) Export
	
	If Not ValueIsFilled(ShopFloorStockroom) Then
		ShopFloorStockroom = Catalogs.BusinessStructure.DefaultShopPantry(Department);
	EndIf;
	
	Return ShopFloorStockroom;
	
EndFunction
// Returns the properties of the item details, taking into account the settings made
// in the metadata and defined in the modules of the item Manager.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	AccountingFeature - EnumRef.ItemAccountingFeatures - feature of the given item.
//	UseVariants - EnumRef.ItemVariantsUsageOptions, Boolean - 
//		use case for the item or whether characteristics are used.
//	UseShelfLifeOnBatchRegistration - Boolean - indicates whether the expiration date is used in the item series.
//
// Returns:
//	See Catalogs.Products.AllAttributes.
//
Function AllProductDetails(ItemsType,
								AccountingFeature,
								UseVariants,
								UseShelfLifeOnBatchRegistration) Export
	
	Return Catalogs.Products.AllAttributes(ItemsType,
												AccountingFeature,
												UseVariants,
												UseShelfLifeOnBatchRegistration);
	
EndFunction

// Returns the properties of the item details, taking into account the settings made
// in the metadata and defined in the modules of the item Manager.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	AccountingFeature - EnumRef.ItemAccountingFeatures - feature of the given item.
//	UseVariants - EnumRef.ItemVariantsUsageOptions, Boolean - 
//		use case for the item or whether characteristics are used.
//	UseShelfLifeOnBatchRegistration - Boolean - indicates whether the expiration date is used in the item series.
//
// Returns:
//	ValueTable - the columns of the table are the same as the properties in the structure See Catalogs.Products.AllAttributes.
//
Function AllProductDetailsTable(ItemsType,
										AccountingFeature,
										UseVariants,
										UseShelfLifeOnBatchRegistration) Export
	
	AllProductDetailsStructure = SettingsValueCached.AllProductDetails(ItemsType,
																						AccountingFeature,
																						UseVariants,
																						UseShelfLifeOnBatchRegistration);
	
	Table = Catalogs.Products.StructureOfDescriptionOfDetailsInTable(AllProductDetailsStructure);
	
	Return Table;
	
EndFunction

// Returns the properties of the item details, taking into account the settings made
// in the metadata and defined in the modules of the item Manager.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	AccountingFeature - EnumRef.ItemAccountingFeatures - feature of the given item.
//
// Returns:
//	FixedStructure - See Catalogs.ItemsCharacteristics.AllAttributes.
//
Function AllDetailsOfProductCharacteristics(ItemsType, AccountingFeature) Export
	
	Return Catalogs.ItemsCharacteristics.AllAttributes(ItemsType, AccountingFeature);
	
EndFunction

// Returns the properties of the item details, taking into account the settings made
// in the metadata and defined in the modules of the item Manager.
//
// Parameters:
//	ItemsType - EnumRef.ItemsTypes - the type of item.
//	AccountingFeature - EnumRef.ItemAccountingFeatures - feature of the given item.
//
// Returns:
//	ValueTable - the columns of the table are the same as the properties in the structure
//						See Catalogs.ItemsCharacteristics.AllAttributes.
//
Function AllDetailsOfProductCharacteristicsTable(ItemsType, AccountingFeature) Export
	
	AllDetailsOfCharacteristicsOfProductRangeStructure =
		SettingsValueCached.AllDetailsOfProductCharacteristics(ItemsType, AccountingFeature);
	
	Return Catalogs.Products.StructureOfDescriptionOfDetailsInTable(AllDetailsOfCharacteristicsOfProductRangeStructure);
	
EndFunction

// Cache for the Directories function.Types of supplies.Vijayasundaram
//
// Parameters:
//  Organization - CatalogRef.Companies - the organization on whose behalf the sale of goods will be processed
//  InventoryType - EnumRef.InventoryTypes, Array of EnumRef.InventoryTypes - available inventory types of products.
//  GoodsOwner - CatalogRef.Companies, CatalogRef.Partners - the owner of the goods.
//  Counterparty - CatalogRef.Companies, CatalogRef.Partners - the counterparty with whom the contract for the sale of goods is concluded.
//  Terms - CatalogRef.TermsOfPurchaseFromVendors - the agreement under which the receipt of goods is processed.
//  Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts, Array of CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - the contract under which the sale of goods is executed.
//  Currency - CatalogRef.Currencies - the currency used for settlements with the owner of the goods.
//  VATTaxation - EnumRef.VATTaxationTypes - type of taxation of sales of goods subject to value added tax.
//  FinancialAccountingGroup - CatalogRef.InventoryAccountingGroups - group of financial accounting of goods.
//  ProductsGroup - CatalogRef.AnalyticalInventoryGroups - type of product.
//  PriceKind - CatalogRef.VendorPriceTypes - type of price at which the receipt of goods is recorded.
//  SubjectToExcise - Boolean - indicates that the excise tax amount should be calculated for this item.
//  BusinessUnitProduction - CatalogRef.BusinessStructure - the division in which the excisable item was produced.
// 
// Returns:
//  CatalogRef.InventoryKinds
//
Function TypeOfStockBySelection(Organization,
	InventoryType,
	GoodsOwner,
	Counterparty,
	Terms,
	Contract,
	Currency,
	VATTaxation,
	FinancialAccountingGroup,
	ProductsGroup,
	PriceKind,
	SubjectToExcise,
	BusinessUnitProduction) Export // The number of parameters increases what is described in the standard, but here it is a conscious decision for the operation of the cache
	
	StructureOfAnalytics = Catalogs.InventoryKinds.StockTypeSelectionParameters();

	StructureOfAnalytics.Organization = Organization;
	StructureOfAnalytics.InventoryType = InventoryType;
	StructureOfAnalytics.GoodsOwner = GoodsOwner;
	StructureOfAnalytics.Counterparty = Counterparty;
	StructureOfAnalytics.Terms = Terms;
	StructureOfAnalytics.Contract = Contract;
	StructureOfAnalytics.Currency = Currency;
	StructureOfAnalytics.VATTaxation = VATTaxation;
	StructureOfAnalytics.FinancialAccountingGroup = FinancialAccountingGroup;
	StructureOfAnalytics.ProductsGroup = ProductsGroup;
	StructureOfAnalytics.PriceKind = PriceKind;
	StructureOfAnalytics.SubjectToExcise = SubjectToExcise;
	StructureOfAnalytics.BusinessUnitProduction = BusinessUnitProduction;
	
	Return Catalogs.InventoryKinds.TypeOfStockBySelection(StructureOfAnalytics);
	
EndFunction

// Deprecated. It is necessary to use the methods of the software interface for VAT accounting (accounting, accounting, customer, etc.)
//
// Returns VAT taxation under the contract, line of business, organization and warehouse on the date.
//
// Parameters:
//	Organization - CatalogRef.Companies - The organization for which the tax system is defined
//	Warehouse - CatalogRef.Warehouses - Retail warehouse for which the tax system is defined
//	Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract selected in the document
//	LineOfBusiness - CatalogRef.LinesOfBusiness - The direction of activity selected in the document
//	Date - Date - Date of determining the tax system for the organization and warehouse.
//
// Returns:
//  EnumRef.VATTaxationTypes
//
Function VATTaxation(Val Organization, Val Warehouse = Undefined, Val Contract = Undefined, Val LineOfBusiness = Undefined, Val Date = Undefined) Export
	
	If ValueIsFilled(Contract) Or ValueIsFilled(LineOfBusiness) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	1 AS Order,
		|	CounterpartyContracts.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Contract
		|	AND NOT CounterpartyContracts.VATTaxationIsDeterminedInDocuments
		|	
		|UNION ALL
		|	
		|SELECT
		|	1 AS Order,
		|	IntercompanyContracts.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.IntercompanyContracts AS IntercompanyContracts
		|WHERE
		|	IntercompanyContracts.Ref = &Contract
		|	AND NOT IntercompanyContracts.VATTaxationIsDeterminedInDocuments
		|
		|UNION ALL
		|	
		|SELECT
		|	2 AS Order,
		|	LinesOfBusiness.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.LinesOfBusiness AS LinesOfBusiness
		|WHERE
		|	LinesOfBusiness.Ref = &LineOfBusiness
		|	AND NOT LinesOfBusiness.VATTaxationIsDeterminedInDocuments
		|
		|ORDER BY
		|	Order";
		
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("LineOfBusiness", LineOfBusiness);
		
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		
		QueryResultEmpty = QueryResult.IsEmpty();
		
	Else
		
		QueryResultEmpty = True;
		
	EndIf;
	
	If QueryResultEmpty Then
		AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date, Warehouse);
		VATTaxation = AccountingParametersForOrganization.BasicTaxationVATSales;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		VATTaxation =  Selection.VATTaxation;
	EndIf;
	
	Return VATTaxation;
	
EndFunction

// Returns the warehouse if it is the only one in the IB
// If the warehouse passed as a parameter is already full, returns it.
// If the warehouse is not passed as a parameter or is passed empty,
// returns the only warehouse in the information database. If
// there is more than one warehouse in the database, it returns an empty link to the warehouse.
//
// Parameters:
//  Warehouse - CatalogRef.Warehouses - The warehouse to fill in.
//  ConsiderWarehouseGroups - Boolean
//  ExcludeGroupsAvailableInOrders - Boolean
//
// Returns:
//  CatalogRef.Warehouses - the default warehouse.
//
Function GetDefaultWarehouse(Val Warehouse = Undefined, ConsiderWarehouseGroups = False, ExcludeGroupsAvailableInOrders=False) Export
	
	If Not ValueIsFilled(Warehouse) Then
		Return Catalogs.Warehouses.DefaultWarehouse(ConsiderWarehouseGroups, ExcludeGroupsAvailableInOrders);
	Else
		Return Warehouse;
	EndIf;
	
EndFunction 

// Returns the warehouse if it is the only one in the IB.
// If the warehouse passed as a parameter is already full, returns it.
// If the warehouse is not passed as a parameter or is passed empty,
// returns the only warehouse in the information database. If
// there is more than one warehouse in the database, it returns an empty link to the warehouse.
//
// Parameters:
//   Warehouse - CatalogRef.Warehouses - The warehouse to fill in.
//
// Returns:
//  CatalogRef.Warehouses - the default retail warehouse.
//
Function GetDefaultRetailWarehouse(Val Warehouse = Undefined) Export

	If Not ValueIsFilled(Warehouse) Then
		Warehouse = Catalogs.Warehouses.DefaultRetailWarehouse();
	Else
		WarehouseStore = Common.ObjectAttributeValue(Warehouse, "WarehouseStore");
		If Not (WarehouseStore = Enums.TypesOfWarehouses.RetailStore) Then
			Warehouse = Catalogs.Warehouses.DefaultRetailWarehouse();
		EndIf;
	EndIf;
	
	Return Warehouse;
	
EndFunction

// Returns the organization's cash register if it is the only one in the IB.
// If the cash register passed as a parameter is already filled in, it returns it.
// If the cash register is not passed as a parameter or is passed empty,
// it returns the only cash register in the information database. If
// there is more than one sales register in the database, it returns an empty link to the sales register.
// Returns the cash register only if the transferred payment form is cash or Undefined.
//
// Parameters:
//  ParametersStructure - Structure - Structure of parameters for determining the cashier:
//   * Organization - CatalogRef.Companies - The organization for which you need to get an invoice.
//   * PaymentMethod - EnumRef.PaymentForms - The form of payment by which the need to receive a cash register is determined.
//   * CashAccount       - CatalogRef.CashAccounts - The cashier you need to fill out
//   * Currency      - CatalogRef.Currencies - Account currency
//   * LineOfBusiness - CatalogRef.LinesOfBusiness - the desired direction of the cashier's activity.
//
// Returns:
//   CatalogRef.CashAccounts - the organization's default cash register.
//
Function GetOrganizationSDefaultSalesRegister(ParametersStructure = Undefined) Export
	
	If ParametersStructure = Undefined Then
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	EndIf;
	
	Organization 			= ParametersStructure.Organization;
	PaymentMethod 			= ParametersStructure.PaymentMethod;
	CashAccount		 			= ParametersStructure.CashAccount;
	Currency					= ParametersStructure.Currency;
	LineOfBusiness	= ParametersStructure.LineOfBusiness;
	Individual			= ParametersStructure.Individual;
	
	If (PaymentMethod = Undefined Or PaymentMethod = Enums.PaymentForms.CashAccountPayment_)
		And Not ValueIsFilled(CashAccount) And (ValueIsFilled(Organization) Or Organization = Undefined) Then
		Return Catalogs.CashAccounts.GetCheckoutByDefault(Organization, Currency, LineOfBusiness, Individual);
	ElsIf ValueIsFilled(CashAccount) And (PaymentMethod = Enums.PaymentForms.BankAccountPayment
		Or PaymentMethod = Enums.PaymentForms.InstantPayments) Then
		TypesArray = New Array;
		TypesArray.Add(TypeOf(CashAccount));
		DescriptionOfCheckoutTypes = New TypeDescription(TypesArray);
		Return DescriptionOfCheckoutTypes.AdjustValue();
	Else
		Return CashAccount;
	EndIf;
	
EndFunction

// Returns the default contact person if there is one for the specified partner
//
// Parameters:
//  Partner - CatalogRef.Partners - the partner for whom you need to get a contact person.
//
// Returns:
//  CatalogRef.ContactPersonsForPartners - the default contact person of the partner.
//
Function GetDefaultPartnerContactPerson(Val Partner) Export
	
	Query = New Query(
	"SELECT ALLOWED TOP 2
	|	ContactPersonsForPartners.Ref
	|FROM
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Owner = &Partner");
	
	Query.SetParameter("Partner", Partner);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return PredefinedValue("Catalog.ContactPersonsForPartners.EmptyRef");
	EndIf;
	
	Selection = Result.Select();
	
	If Selection.Count() = 1 Then
		Selection.Next();
		Return Selection.Ref;
	EndIf;
	
	Return PredefinedValue("Catalog.ContactPersonsForPartners.EmptyRef");
	
EndFunction

// Returns weight barcode prefixes.
//
// Returns:
//	Array of String - prefixes of weight barcodes.
//
Function GetWeightBarCodePrefixes() Export
	
	ReturnValue = New Array;
	
	RangesOfWeightBarcodes = RangesOfWeightBarcodes();
	For Each TSRow In RangesOfWeightBarcodes Do
		ReturnValue.Add(Right(TSRow.Span, 1));
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Gets the inventory group of the item, if it is the only one in the IB
// If the warehouse group passed as a parameter is already filled in, returns it.
// If the warehouse group is not passed as a parameter or an empty one is passed,
// it returns the only warehouse group in the information database. If there is more than one warehouse group
// in the database, it returns an empty reference to the warehouse group.
//
// Parameters:
//  WarehouseGroupOfProducts - CatalogRef.WarehouseGroupsOfItems - the warehouse group
//                                to fill in.
//
// Returns:
//  CatalogRef.WarehouseGroupsOfItems - the default inventory group of the item.
//
Function DefaultProductInventoryGroup(Val WarehouseGroupOfProducts = Undefined) Export

	If Not ValueIsFilled(WarehouseGroupOfProducts) Then
		Return Catalogs.WarehouseGroupsOfItems.DefaultProductInventoryGroup();
	Else
		Return WarehouseGroupOfProducts;
	EndIf;
	
EndFunction

// Gets a warehouse group of packages if it is the only one in the IB
// If the warehouse group passed as a parameter is already filled in, returns it.
// If the warehouse group is not passed as a parameter or an empty one is passed,
// it returns the only warehouse group in the information database. If there is more than one warehouse group
// in the database, it returns an empty reference to the warehouse group.
//
// Parameters:
//  WarehouseGroupOfPackages - CatalogRef.WarehousePackageGroups - the warehouse group
//                            to fill in.
//
// Returns:
//  CatalogRef.WarehousePackageGroups - the default warehouse group of packages.
//
Function DefaultWarehouseGroupOfPackages(Val WarehouseGroupOfPackages = Undefined) Export

	If Not ValueIsFilled(WarehouseGroupOfPackages) Then
		Return Catalogs.WarehousePackageGroups.DefaultWarehouseGroupOfPackages();
	Else
		Return WarehouseGroupOfPackages;
	EndIf;
	
EndFunction

// Returns the store format, if it is the only one in the IB/
//
// Parameters:
//   PlanningObject - CatalogRef.StoreFormats, CatalogRef.Warehouses - the object of planning, which
//                                                                                     you need to fill.
//
// Returns:
//    CatalogRef.StoreFormats, CatalogRef.Warehouses - the default scheduling object.
//
Function GetDefaultSchedulingObject(Val PlanningObject = Undefined) Export

	If Not ValueIsFilled(PlanningObject) Then
		If GetFunctionalOption("UseStoreFormats") Then
			Return Catalogs.StoreFormats.GetDefaultStoreFormat();
		Else
			Return Catalogs.Warehouses.DefaultWarehouse();
		EndIf; 
	Else
		Return PlanningObject;
	EndIf;
	
EndFunction

// Function-constructor of parameters for selecting the default price type
//
// Returns:
// 	Structure - Structure of parameters for selecting the type of prices:
//      * PriceKind                                   - CatalogRef.TypesOfPrices - The type of price to fill in.
//      * PriceIncludesVAT                           - Boolean - Indicates whether VAT is included in the price.
//      * UseWhileSellingToCustomers                    - Boolean - Choosing the type of price for sale
//      * UseForIntercompanySales - Boolean - Choosing the type of price to transfer between organizations.
//      * UseWhileTransferringProductsToMaterialProvider  - Boolean - The choice of the type of price for the transfer of products to the giver.
//
Function ParametersForSelectingDefaultPriceType() Export
	
	ChoiceParameters = New Structure;
	
	ChoiceParameters.Insert("PriceKind", Undefined);
	ChoiceParameters.Insert("PriceIncludesVAT", Undefined);
	ChoiceParameters.Insert("UseWhileSellingToCustomers", Undefined);
	ChoiceParameters.Insert("UseForIntercompanySales", Undefined);
	ChoiceParameters.Insert("UseWhileTransferringProductsToMaterialProvider", Undefined);
	ChoiceParameters.Insert("Status", Undefined);
	
	Return ChoiceParameters;
	
EndFunction

// Returns the price type, if it is the only one in the IB.
// If the price type passed as a parameter is already filled in, it returns it.
// If the price type is not passed as a parameter or is passed empty,
// it returns the only price type in the information database. If there are several types of prices
// in the database, it returns an empty link to the price type.
//
// Parameters:
//   ChoiceParameters - Structure - Structure of the selection parameters, constructor of the value of Customizationpovtisp.Parameterselection of the price for silence.
//
// Returns:
//   CatalogRef.TypesOfPrices - the default price type.
//
Function DefaultPriceType(ChoiceParameters) Export

	PriceKind                                   = ChoiceParameters.PriceKind;
	PriceIncludesVAT                           = ChoiceParameters.PriceIncludesVAT;
	UseWhileSellingToCustomers                    = ChoiceParameters.UseWhileSellingToCustomers;
	UseForIntercompanySales = ChoiceParameters.UseForIntercompanySales;
	UseWhileTransferringProductsToMaterialProvider  = ChoiceParameters.UseWhileTransferringProductsToMaterialProvider;
	
	If Not ValueIsFilled(PriceKind) Then
		
		FilterParameters = New Structure;
		
		If PriceIncludesVAT <> Undefined Then
			FilterParameters.Insert("PriceIncludesVAT", PriceIncludesVAT);
		EndIf;
		If UseWhileSellingToCustomers <> Undefined Then
			FilterParameters.Insert("UseWhileSellingToCustomers", UseWhileSellingToCustomers);
		EndIf;
		If UseForIntercompanySales <> Undefined Then
			FilterParameters.Insert("UseForIntercompanySales", UseForIntercompanySales);
		EndIf;
		
		If UseWhileTransferringProductsToMaterialProvider <> Undefined Then
			FilterParameters.Insert("UseWhileTransferringProductsToMaterialProvider", UseWhileTransferringProductsToMaterialProvider);
		EndIf;
		
		Return Catalogs.TypesOfPrices.DefaultPriceType(PriceKind, FilterParameters);
		
	Else
		Return PriceKind;
	EndIf;
	
EndFunction

#Region Barcoding

// Returns the default range of weight barcodes.
//
// Returns:
//   String - default range.
//
Function DefaultRangeOfWeightBarcodes() Export
	
	Ranges = RangesOfWeightBarcodes();
	For Each TSRow In Ranges Do
		Return TSRow.Span;	
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns settings for weight barcodes ranges.
//
// Returns:
//	Array of See InformationRegisters.ItemsBarcodes.SettingBarcodeRange.
//
Function RangesOfWeightBarcodes() Export
	
	RangesOfWeightBarcodes = New Array;
	
	SettingsForBarcodeRanges = InformationRegisters.ItemsBarcodes.SettingsForBarcodeRanges();
	For Each Setting In SettingsForBarcodeRanges Do
		If Setting.SoldByWeight Then
			RangesOfWeightBarcodes.Add(Setting);
		EndIf
	EndDo;
	
	Return RangesOfWeightBarcodes;
	
EndFunction

// Returns the settings for the ranges of individual barcodes.
//
// Returns:
//	Array of See InformationRegisters.ItemsBarcodes.SettingBarcodeRange.
//
Function RangesOfUnitBarcodes() Export
	
	RangesOfUnitBarcodes = New Array;
	
	SettingsForBarcodeRanges = InformationRegisters.ItemsBarcodes.SettingsForBarcodeRanges();
	For Each Setting In SettingsForBarcodeRanges Do
		If Not Setting.SoldByWeight Then
			RangesOfUnitBarcodes.Add(Setting);
		EndIf
	EndDo;
	
	Return RangesOfUnitBarcodes;
	
EndFunction

#EndRegion

#Region DiscountsMarkups

// Determines how many discounts (mark-UPS) are involved in information security objects.
//
// Returns:
//  Structure - a structure containing the number of discounts (margins) involved in information security facilities.
//
Function NumberOfSourcesOfDiscountsMargins() Export
	
	StructureToReturn = New Structure;
	StructureToReturn.Insert("TotalWarehouses", 0);
	StructureToReturn.Insert("TotalInStandardAgreements", 0);
	StructureToReturn.Insert("TotalInIndividualAgreements", 0);
	StructureToReturn.Insert("TotalInLoyaltyCards", 0);
	
	RequestTextByTypeLoyaltyCard = "
	|SELECT ALLOWED
	|	COUNT(LoyaltyCardKinds.Ref) AS ObjectCount
	|FROM
	|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds";
	
	QueryTextByWarehouses = "
	|SELECT ALLOWED
	|	COUNT(Warehouses.Ref) AS ObjectCount
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	NOT Warehouses.IsFolder";
	
	RequestTextForIndividualAgreements = "
	|SELECT ALLOWED
	|	COUNT(TermsOfSale.Ref) AS ObjectCount
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	NOT TermsOfSale.Standard_";
	
	RequestTextForStandardAgreements = "
	|SELECT ALLOWED
	|	COUNT(TermsOfSale.Ref) AS ObjectCount
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	TermsOfSale.Standard_";
	
	Query = New Query;
	NumberOfRequests_ = 0;
	MatchingDataToRequestNumbers = New Map;
	QueryTextPostfix = "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	If GetFunctionalOption("UseLoyaltyCards")
		And AccessRight("Read", Metadata.Catalogs.LoyaltyCards) Then
		
		Query.Text = Query.Text + RequestTextByTypeLoyaltyCard;
		MatchingDataToRequestNumbers.Insert(NumberOfRequests_, "TotalInLoyaltyCards");
		NumberOfRequests_ = NumberOfRequests_ + 1;
		
	EndIf;
	
	If GetFunctionalOption("UseSeveralWarehouses")
		And AccessRight("Read", Metadata.Catalogs.Warehouses) Then
		
		Query.Text = Query.Text + ?(NumberOfRequests_ = 0 , "", QueryTextPostfix) + QueryTextByWarehouses;
		MatchingDataToRequestNumbers.Insert(NumberOfRequests_, "TotalWarehouses");
		NumberOfRequests_ = NumberOfRequests_ + 1;
		
	EndIf;
	
	If GetFunctionalOption("UseCustomerTermsOfSales")
		And AccessRight("Read", Metadata.Catalogs.TermsOfSale) Then
		
		Query.Text = Query.Text + ?(NumberOfRequests_ = 0 , "", QueryTextPostfix) + RequestTextForIndividualAgreements;
		MatchingDataToRequestNumbers.Insert(NumberOfRequests_, "TotalInIndividualAgreements");
		NumberOfRequests_ = NumberOfRequests_ + 1;
		
	EndIf;
	
	If GetFunctionalOption("UseStandardTermsOfSalesWithCustomers") 
		And AccessRight("Read", Metadata.Catalogs.TermsOfSale) Then
		
		Query.Text = Query.Text + ?(NumberOfRequests_ = 0 , "", QueryTextPostfix) + RequestTextForStandardAgreements;
		MatchingDataToRequestNumbers.Insert(NumberOfRequests_, "TotalInStandardAgreements");
		NumberOfRequests_ = NumberOfRequests_ + 1;
		
	EndIf;
	
	If NumberOfRequests_ > 0 Then
		
		QueryResult = Query.ExecuteBatch(); 
		
		For Indus = 1 To NumberOfRequests_ Do 
			
			Selection = QueryResult[Indus - 1].Select();
			If Selection.Next() Then
				StructureToReturn[MatchingDataToRequestNumbers.Get(Indus-1)] = Selection.ObjectCount;
			EndIf;
			
		EndDo
		
	EndIf;
	
	Return StructureToReturn;
	
EndFunction

#EndRegion

#Region AccessToDetailsOfMetadataObjects

// Returns a list of directory details that cannot be changed by the current user.
//
// Parameters:
//		CatalogName - String - the name of the directory as it is set in the metadata
//		IsFolder - Boolean - check the details of a group or directory element
//		AttributesNotToCheck - String - list of details that can be" legally " changed programmatically when recording an item
// Returns:
//		String - a comma-separated list of unavailable details.
//
Function DetailsOfBusinessCatalogThatCanTBeEdited(CatalogName, IsFolder = False, AttributesNotToCheck = "") Export
	
	Attributes = "";
	
	If Users.IsFullUser() Then
		Return Attributes; // all details are available for editing
	EndIf;
	
	CatalogMetadata = Metadata.Catalogs[CatalogName];
	AttributesToExclude  = New Structure(
		"Predefined,Ref,IsFolder" + ?(IsBlankString(AttributesNotToCheck), "", "," + AttributesNotToCheck));
	
	For Each AttributeMetadata In CatalogMetadata.StandardAttributes Do
		If Not AttributesToExclude.Property(AttributeMetadata.Name)
		 And Not AccessRight("Edit", CatalogMetadata,, AttributeMetadata.Name) Then
			Attributes = Attributes + ?(IsBlankString(Attributes), "", ",") + AttributeMetadata.Name;
		EndIf;
	EndDo;
	
	For Each AttributeMetadata In CatalogMetadata.Attributes Do
		If Not IsFolder And AttributeMetadata.Use = Metadata.ObjectProperties.AttributeUse.ForFolder
		 Or IsFolder And AttributeMetadata.Use = Metadata.ObjectProperties.AttributeUse.ForItem Then
			Continue; // the props are not used
		EndIf;
		If Not AttributesToExclude.Property(AttributeMetadata.Name)
		 And Not AccessRight("Edit", AttributeMetadata) Then
			Attributes = Attributes + ?(IsBlankString(Attributes), "", ",") + AttributeMetadata.Name;
		EndIf;
	EndDo;
	
	Return Attributes;
	
EndFunction

// Returns the structure of the directory details.
//
// Parameters:
//		CatalogName - String - the name of the directory as it is set in the metadata
// Returns:
//		Structure - standard and usual details of the directory.
//
Function CatalogAttributes(CatalogName) Export
	
	AttributesStructure1   = New Structure;
	CatalogMetadata = Metadata.Catalogs[CatalogName];
	
	For Each Attribute In CatalogMetadata.StandardAttributes Do
		AttributesStructure1.Insert(Attribute.Name, Attribute.Synonym);
	EndDo;
	
	For Each Attribute In CatalogMetadata.Attributes Do
		AttributesStructure1.Insert(Attribute.Name, Attribute.Synonym);
	EndDo;
	
	Return AttributesStructure1;
	
EndFunction

#EndRegion

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. You should use the monetary means of the server.Get a Bank accountcontradent to silence.
// Returns the counterparty's bank account if it is the only one in the information security
// If the bank account passed as a parameter is already full, returns it.
// If the bank account is not passed as a parameter or an empty one is passed,
// it returns the only bank account in the information database. If there is more than one bank account
// in the database, it returns an empty link to the bank account
// Returns the bank account only if the submitted payment Form is non-cash or Undefined.
//
// Parameters:
//  Counterparty     - CatalogRef.Counterparties - The counterparty for which you want to account
//  PaymentMethod    - EnumRef.PaymentForms - The form of payment used to determine whether
//                   a Bank account is required.
//  BankAccount - CatalogRef.CounterpartyBankAccounts - Bank account to fill out
//  OffsettingAccount - CatalogRef.CompaniesBankAccounts - the invoice that the received invoice corresponds to.
//
// Returns:
//  CatalogRef.CounterpartyBankAccounts - counterparty's default bank account.
//
Function GetDefaultCounterpartyBankAccount(Val Counterparty, Val PaymentMethod = Undefined,
	Val BankAccount = Undefined, Val OffsettingAccount = Undefined) Export
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	ParametersOfAccount.OffsettingAccount = OffsettingAccount;
	
	Return CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount, BankAccount, PaymentMethod);
	
EndFunction

// Deprecated. You should use a money server.Get a bank accountorganizationin silence.
// Returns the organization's bank account if it is the only one in the information security
// If the bank account passed as a parameter is already full, returns it.
// If the bank account is not passed as a parameter or an empty one is passed,
// it returns the only bank account in the information database. If there is more than one bank account
// in the database, it returns an empty link to the bank account
// Returns the bank account only if the submitted payment Form is non-cash or not specified.
//
// Parameters:
//   ParametersStructure - Structure - The structure of parameters for determining the account:
//     * Organization             - CatalogRef.Companies - The organization for which you need to get an invoice.
//     * PaymentMethod             - EnumRef.PaymentForms - The form of payment used to determine whether
//                                                                  a Bank account is required.
//     * BankAccount          - CatalogRef.CompaniesBankAccounts - Bank account that need to be filled.
//     * Currency                  - CatalogRef.Currencies - Account currency.
//     * LineOfBusiness - CatalogRef.LinesOfBusiness - the desired direction of the account.
//     * ExcludeCurrencyAccounts   - Boolean - if True, accounts in the currency passed in the Currency parameter are excluded.
//
// Returns:
//   CatalogRef.CompaniesBankAccounts - the default bank account of the organization.
//
Function GetOrganizationSDefaultBankAccount(ParametersStructure = Undefined) Export
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersStructure,
		ParametersStructure.BankAccount, ParametersStructure.PaymentMethod);
	
EndFunction

#EndRegion

#EndRegion
