#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Constructor that returns a collection of Attributes of the directory used to determine the uniqueness of the key.
//
// Returns:
//	Map of KeyAndValue:
//		* Key - String - the name of the Attributes of the directory.
//		* Value - Arbitrary - the value of the props.
//
Function KeyAttributes() Export
	
	Result = New Map;
	Result.Insert("Organization");
	Result.Insert("InventoryType");
	Result.Insert("VATTaxation");
	Result.Insert("GoodsOwner");
	Result.Insert("Terms");
	Result.Insert("Currency");
	Result.Insert("SaleOfAnotherCompanyInventory");
	Result.Insert("InventoryOwnerAttributeOfCompanyGoodsOwner");
	Result.Insert("GoodsTransferMethod");
	Result.Insert("NotUsedVendor");
	Result.Insert("NotUsedPurpose");
	Result.Insert("NotUsedBusinessUnit");
	Result.Insert("NotUsedManager");
	Result.Insert("NotUsedSalesOpportunity");
	Result.Insert("FinancialAccountingGroup");
	Result.Insert("Counterparty");
	Result.Insert("Contract");
	Result.Insert("NotUsedAssignment");
	Result.Insert("ProductsGroup");
	Result.Insert("PriceKind");
	Result.Insert("SubjectToExcise");
	Result.Insert("BusinessUnitProduction");
	
	Return Result;
	
EndFunction

// Returns the Inventory owner attribute for the current document.
//
// Parameters:
//	Organization - CatalogRef.Companies - Organization of the document
//	BusinessOperation - EnumRef.BusinessTransactions - The operation of the document
//	DocumentAttributes - Structure, QueryResultSelection - Document data:
//      * Organization - CatalogRef.Companies
//      * InventoryType - EnumRef.InventoryTypes
//      * GoodsOwner - CatalogRef.Companies, CatalogRef.Partners -
//      * Counterparty - CatalogRef.Companies, CatalogRef.Counterparties -
//      * Terms - CatalogRef.TermsOfPurchaseFromVendors
//      * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts -
//      * Currency - CatalogRef.Currencies
//      * VATTaxation - EnumRef.VATTaxationTypes
//      * TaxationOfOrganization - EnumRef.TaxationSystems
//      * InventoryOwnerAttribute - CatalogRef.InventoryKinds
//      * FinancialAccountingGroup - CatalogRef.InventoryAccountingGroups
//      * ProductsGroup - CatalogRef.Companies
//      * BusinessOperation - EnumRef.BusinessTransactions
//      * PriceKind - CatalogRef.VendorPriceTypes
//      * RetainedStockType - CatalogRef.InventoryKinds
//      * SubjectToExcise - Boolean - indicates that the excise tax amount should be calculated for this item.
//      * BusinessUnitProduction - CatalogRef.BusinessStructure - the division in which the excisable item was produced.
//
// Returns:
//	CatalogRef.InventoryKinds - The found type of stocks.
//
Function DocumentInventoryView(Organization, BusinessOperation = Undefined, DocumentAttributes = Undefined) Export
	
	If ValueIsFilled(DocumentAttributes) Then
		AttributesNames = "
			|Organization,
			|InventoryType,
			|GoodsOwner,
			|Counterparty,
			|Terms,
			|Contract,
			|Currency,
			|VATTaxation,
			|TaxationOfOrganization,
			|InventoryOwnerAttribute,
			|FinancialAccountingGroup,
			|ProductsGroup,
			|BusinessOperation,
			|PriceKind,
			|SubjectToExcise,
			|BusinessUnitProduction,
			|RetainedStockType
			|";
		Attributes = New Structure(AttributesNames);
		
		Attributes.Organization = Catalogs.Companies.EmptyRef();
		Attributes.GoodsOwner = Undefined;
		Attributes.Counterparty = Undefined;
		Attributes.Contract = Undefined;
		Attributes.Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		Attributes.Currency = Catalogs.Currencies.EmptyRef();
		Attributes.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
		Attributes.InventoryType = Enums.InventoryTypes.EmptyRef();
		Attributes.FinancialAccountingGroup = Catalogs.InventoryAccountingGroups.EmptyRef();
		Attributes.ProductsGroup = Catalogs.AnalyticalInventoryGroups.EmptyRef();
		Attributes.PriceKind = Catalogs.VendorPriceTypes.EmptyRef();
		Attributes.SubjectToExcise = False;
		Attributes.BusinessUnitProduction = Catalogs.BusinessStructure.EmptyRef();
		
		FillPropertyValues(Attributes, DocumentAttributes);
	Else
		Attributes = Undefined;
	EndIf;
	
	If ValueIsFilled(Attributes)
		And ValueIsFilled(Attributes.RetainedStockType) Then
		
		// The type of reserves is already known - no need to try to reformulate it
		Result = Attributes.RetainedStockType;
		
	Else
		StructureTypeOfInventory = StockTypeStructure(Organization, BusinessOperation, Attributes);
		
		SetPrivilegedMode(True);
		Result = TypeOfInventoryBySelectionsCache(StructureTypeOfInventory);
		SetPrivilegedMode(False);
	EndIf;
	
	Return Result;

EndFunction

// Returns the Inventory owner attribute for Transferring items between organizations.
//
// Parameters:
//	InventoryOwnerAttributeOfCompanyGoodsOwner - CatalogRef.InventoryKinds - Type of inventory of the owner organization
//	CompanyCustomer - CatalogRef.Companies - Organization - the seller
//	TransferForActivity_ - EnumRef.VATTaxationTypes - Taxation of activities
//	DocumentDate - Date - Date of the document, to determine whether the document falls under the 150FZ
//	Commodity - Boolean - A sign indicating whether the product is a raw material or not.
//
// Returns:
//	CatalogRef.InventoryKinds - Created inventory view.
//
Function TypeOfInventoryToTransferBetweenOrganizations(InventoryOwnerAttributeOfCompanyGoodsOwner,
												CompanyCustomer,
												Val TransferForActivity_,
												Val DocumentDate = Undefined,
												Commodity = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TypesOfOwnerStocks.Ref AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TypesOfSellerSInventory.Ref AS InventoryOwnerAttribute,
	|	Setting.CompanyCustomer AS Organization,
	|	TypesOfOwnerStocks.Organization AS Consignor,
	|	TypesOfOwnerStocks.Organization AS Counterparty,
	|	Setting.Currency AS Currency,
	|	Setting.GoodsTransferMethod AS GoodsTransferMethod,
	|	TRUE AS SaleOfAnotherCompanyInventory,
	|	&TransferForActivity_ AS VATTaxation,
	|	CASE
	|		WHEN Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|			THEN TypesOfOwnerStocks.Organization
	|		ELSE TypesOfOwnerStocks.GoodsOwner
	|	END AS GoodsOwner,
	|	TypesOfOwnerStocks.InventoryType AS InventoryTypeOfOwner,
	|	TypesOfOwnerStocks.VATTaxation AS OwnerTaxation
	|FROM
	|	Catalog.InventoryKinds AS TypesOfOwnerStocks
	|		INNER JOIN InformationRegister.CustomizeCustomerInvoiceIntercompany AS Setting
	|		ON TypesOfOwnerStocks.Organization = Setting.CompanyOwner
	|			AND TypesOfOwnerStocks.InventoryType = Setting.InventoryType
	|			AND (Setting.CompanyCustomer = &CompanyCustomer)
	|			AND (Setting.GoodsTransferMethod <> VALUE(Enum.GoodsTransferMethods.NotTransferred))
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfSellerSInventory
	|		ON TypesOfOwnerStocks.Ref = TypesOfSellerSInventory.InventoryOwnerAttributeOfCompanyGoodsOwner
	|			AND (Setting.CompanyCustomer = TypesOfSellerSInventory.Organization)
	|			AND (Setting.GoodsTransferMethod = TypesOfSellerSInventory.GoodsTransferMethod)
	|			AND (Setting.Currency = TypesOfSellerSInventory.Currency
	|				OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.Sale))
	|			AND (TypesOfSellerSInventory.VATTaxation = &TransferForActivity_
	|				OR Setting.GoodsTransferMethod = VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent))
	|WHERE
	|	TypesOfOwnerStocks.Ref = &InventoryOwnerAttributeOfCompanyGoodsOwner";
	
	UseSeparateAccountingByTaxation =
		AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(CompanyCustomer, DocumentDate);
	
	Query.SetParameter("CompanyCustomer", CompanyCustomer);
	Query.SetParameter("InventoryOwnerAttributeOfCompanyGoodsOwner", InventoryOwnerAttributeOfCompanyGoodsOwner);
	
	If UseSeparateAccountingByTaxation Then
		Query.SetParameter("TransferForActivity_", TransferForActivity_);
	Else
		Query.SetParameter("TransferForActivity_", Enums.VATTaxationTypes.EmptyRef());
	EndIf;
	
	InventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		
		If ValueIsFilled(Selection.InventoryOwnerAttribute) Then
			InventoryOwnerAttribute = Selection.InventoryOwnerAttribute;
		Else
			ParameterNames = "
				|Organization,
				|GoodsTransferMethod,
				|Consignor,
				|Counterparty,
				|Currency,
				|InventoryOwnerAttributeOfCompanyGoodsOwner,
				|SaleOfAnotherCompanyInventory,
				|GoodsOwner,
				|VATTaxation
				|";
			FillParameters = New Structure(ParameterNames);
			FillPropertyValues(FillParameters, Selection);
			
			If Selection.GoodsTransferMethod = Enums.GoodsTransferMethods.TransferToCommissionAgent
				Or Selection.GoodsTransferMethod = Enums.GoodsTransferMethods.ConsignmentGoodsTransferAndReturn Then
				
				If TransferForActivity_ = Enums.VATTaxationTypes.ExportSale
					And DocumentDate >= VATAccountingERP.AccountingSettings().ExportSplitDate Then
					
					If Commodity Then
						VATTaxation = Enums.VATTaxationTypes.ExportOfCommoditiesServicesWorks;
					Else
						VATTaxation = Enums.VATTaxationTypes.ExportOfNonResourceGoods;
					EndIf;
					
				ElsIf Selection.InventoryTypeOfOwner = Enums.InventoryTypes.ConsignedGoods Then
					VATTaxation = Selection.OwnerTaxation;
				Else
					SetPrivilegedMode(True);
					AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(
						Selection.GoodsOwner,
						CurrentSessionDate());
					VATTaxation = AccountingParametersForOrganization.BasicTaxationVATSales;
					SetPrivilegedMode(False);
				EndIf;
				
			ElsIf UseSeparateAccountingByTaxation Then
				If TransferForActivity_ = Enums.VATTaxationTypes.ExportSale
					And DocumentDate >= VATAccountingERP.AccountingSettings().ExportSplitDate Then
					If Commodity Then
						VATTaxation = Enums.VATTaxationTypes.ExportOfCommoditiesServicesWorks;
					Else
						VATTaxation = Enums.VATTaxationTypes.ExportOfNonResourceGoods;
					EndIf;
				Else
					VATTaxation = TransferForActivity_;
				EndIf;
			Else
				VATTaxation = Enums.VATTaxationTypes.EmptyRef();
			EndIf;
			
			CatalogObject = Catalogs.InventoryKinds.CreateItem();
			FillPropertyValues(CatalogObject, FillParameters);
			CatalogObject.VATTaxation = VATTaxation;
			
			SetPrivilegedMode(True);
			CatalogObject.Write();
			SetPrivilegedMode(False);
			
			InventoryOwnerAttribute = CatalogObject.Ref;
		EndIf;
		
	EndIf;
	
	Return InventoryOwnerAttribute;
	
EndFunction

// Returns the Inventory owner attribute for returning items from the customer.
//
// Parameters:
//	InventoryOwnerAttributeShipment - CatalogRef.InventoryKinds - The Inventory owner attribute of the item sold.
//	Organization - CatalogRef.Companies - Organization in the product return document
//				- Undefined - The organization is taken from the type of shipment inventory.
//
// Returns:
//	CatalogRef.InventoryKinds - Created inventory view.
//
Function TypeOfStockToReturnGoodsFromCustomer(InventoryOwnerAttributeShipment, Organization = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryKinds.Ref					AS InventoryOwnerAttribute,
	|	InventoryKinds.Organization				AS Organization,
	|	InventoryKinds.InventoryType				AS InventoryType,
	|	InventoryKinds.GoodsOwner			AS GoodsOwner,
	|	InventoryKinds.Counterparty				AS Counterparty,
	|	InventoryKinds.Contract					AS Contract,
	|	InventoryKinds.Terms				AS Terms,
	|	InventoryKinds.Currency					AS Currency,
	|	InventoryKinds.FinancialAccountingGroup	AS FinancialAccountingGroup,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	CASE WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	END AS BusinessOperation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref = &InventoryOwnerAttributeShipment";
	
	Query.SetParameter("InventoryOwnerAttributeShipment", InventoryOwnerAttributeShipment);
	
	InventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		InventoryOwnerAttribute = DocumentInventoryView(?(Organization = Undefined, Selection.Organization, Organization),
										Selection.BusinessOperation,
										Selection);
	EndIf;
	
	Return InventoryOwnerAttribute;
	
EndFunction

// Returns the parameters for the selection of the stocks.
//
// Returns:
//	Structure - contains the following keys:
//		* Organization - CatalogRef.Companies, Array of CatalogRef.Companies - the organization on behalf of which the sale of goods will be processed.
//		* MaterialProviderCompany - CatalogRef.Companies, Array of CatalogRef.Companies - the organization for which the production is performed.
//		* InventoryType - EnumRef.InventoryTypes, Array of EnumRef.InventoryTypes - available inventory types of products.
//		* GoodsOwner - CatalogRef.Companies, CatalogRef.Partners, Undefined - the owner of the goods.
//		* Counterparty - CatalogRef.Companies, CatalogRef.Counterparties, Undefined - the counterparty with whom the contract for the sale of goods is concluded.
//		* Terms - CatalogRef.TermsOfPurchaseFromVendors - the agreement under which the receipt of goods is processed.
//		* Contract - Undefined, CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts, Array of CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - the contract under which the sale of goods is executed.
//		* Currency - CatalogRef.Currencies - the currency used for settlements with the owner of the goods.
//		* VATTaxation - EnumRef.VATTaxationTypes - type of taxation of sales of goods subject to value added tax.
//		* FinancialAccountingGroup - CatalogRef.InventoryAccountingGroups - group of financial accounting of goods.
//		* ProductsGroup - CatalogRef.AnalyticalInventoryGroups - type of product.
//		* PriceKind - CatalogRef.VendorPriceTypes - type of price at which the receipt of goods is recorded.
//		* SubjectToExcise - Boolean, Array of Boolean - indicates that the excise tax amount should be calculated for this item.
//		* BusinessUnitProduction - CatalogRef.BusinessStructure - the division in which the excisable item was produced.
//
Function StockTypeSelectionParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	Parameters.Insert("MaterialProviderCompany", Catalogs.Companies.EmptyRef());
	Parameters.Insert("GoodsOwner", Undefined);
	Parameters.Insert("Counterparty", Undefined);
	Parameters.Insert("Contract", Undefined);
	Parameters.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	Parameters.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Parameters.Insert("VATTaxation", Enums.VATTaxationTypes.EmptyRef());
	Parameters.Insert("InventoryType", Enums.InventoryTypes.EmptyRef());
	Parameters.Insert("FinancialAccountingGroup", Catalogs.InventoryAccountingGroups.EmptyRef());
	Parameters.Insert("ProductsGroup", Catalogs.AnalyticalInventoryGroups.EmptyRef());
	Parameters.Insert("PriceKind", Catalogs.VendorPriceTypes.EmptyRef());
	Parameters.Insert("SubjectToExcise", False);
	Parameters.Insert("BusinessUnitProduction", Catalogs.BusinessStructure.EmptyRef());
	
	Return Parameters;
	
EndFunction

// Returns the value of the directory, based on the passed selection parameters.
//
// Parameters:
//	FilterFields - See StockTypeSelectionParameters.
//
// Returns:
//	CatalogRef.InventoryKinds - the found value of the directory.
//	Undefined - if the value of the directory could not be found, according to the specified selection parameters.
//
Function TypeOfStockBySelection(FilterFields) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	InventoryKinds.Ref AS Ref
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.InventoryType = &InventoryType
	|	AND InventoryKinds.VATTaxation = &VATTaxation
	|	AND InventoryKinds.GoodsOwner = &GoodsOwner
	|	AND InventoryKinds.Terms = &Terms
	|	AND InventoryKinds.Currency = &Currency
	|	AND InventoryKinds.FinancialAccountingGroup = &FinancialAccountingGroup
	|	AND InventoryKinds.Counterparty = &Counterparty
	|	AND InventoryKinds.Contract = &Contract
	|	AND InventoryKinds.ProductsGroup = &ProductsGroup
	|	AND InventoryKinds.PriceKind = &PriceKind
	|	AND InventoryKinds.SubjectToExcise = &SubjectToExcise
	|	AND InventoryKinds.BusinessUnitProduction = &BusinessUnitProduction
	|	AND NOT InventoryKinds.IsDuplicate
	|	AND NOT InventoryKinds.Obsolete1";
	
	Query.SetParameter("Organization", FilterFields.Organization);
	Query.SetParameter("InventoryType", FilterFields.InventoryType);
	Query.SetParameter("GoodsOwner", FilterFields.GoodsOwner);
	Query.SetParameter("Counterparty", FilterFields.Counterparty);
	Query.SetParameter("Terms", FilterFields.Terms);
	Query.SetParameter("Contract", FilterFields.Contract);
	Query.SetParameter("Currency", FilterFields.Currency);
	Query.SetParameter("VATTaxation", FilterFields.VATTaxation);
	Query.SetParameter("FinancialAccountingGroup", FilterFields.FinancialAccountingGroup);
	Query.SetParameter("ProductsGroup", FilterFields.ProductsGroup);
	Query.SetParameter("PriceKind", FilterFields.PriceKind);
	Query.SetParameter("SubjectToExcise", FilterFields.SubjectToExcise);
	Query.SetParameter("BusinessUnitProduction", FilterFields.BusinessUnitProduction);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		InventoryOwnerAttribute = SelectionDetailRecords.Ref;
	Else
		InventoryOwnerAttribute = Undefined;
	EndIf;
	
	Return InventoryOwnerAttribute;
	
EndFunction

#Region ReplaceDuplicateInventoryKinds

// Returns the Query Text that searches for duplicates of the directory.
//
// Returns:
//	String - query text.
//
Function RequestTextAvailabilityOfDuplicateInventoryTypes() Export
	
	QueryText =
	"SELECT TOP 1
	|	InventoryKinds.Ref AS Ref
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.IsDuplicate";
	
	Return QueryText;
	
EndFunction

// Replaces duplicates of the directory in the information database.
//
// Parameters:
//	Parameters - Structure - parameters used for data processing.
//	ResultStorageAddress_ - String - the address of the processing result in the temporary storage.
//
Procedure ReplaceInventoryKindDuplicates(Parameters = Undefined, ResultStorageAddress_ = "") Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = RequestTextForDuplicateInventoryTypes() + 
	"SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Description AS Description,
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	CASE InventoryKinds.GoodsOwner
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Partners.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.GoodsOwner
	|	END AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.GoodsTransferMethod AS GoodsTransferMethod,
	|	CASE
	|		WHEN InventoryKinds.NotUsedVendor IN (VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		WHEN NOT InventoryKinds.GoodsOwner IN (UNDEFINED, VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.NotUsedVendor
	|	END AS NotUsedVendor,
	|	CASE
	|		WHEN InventoryKinds.NotUsedPurpose = VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.PurposeIsNotLimited)
	|			THEN VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.EmptyRef)
	|		ELSE InventoryKinds.NotUsedPurpose
	|	END AS NotUsedPurpose,
	|	InventoryKinds.NotUsedBusinessUnit AS NotUsedBusinessUnit,
	|	InventoryKinds.NotUsedManager AS NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity AS NotUsedSalesOpportunity,
	|	InventoryKinds.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE InventoryKinds.Counterparty
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Counterparty
	|	END AS Counterparty,
	|	CASE InventoryKinds.Contract
	|		WHEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Contract
	|	END AS Contract,
	|	InventoryKinds.NotUsedAssignment AS NotUsedAssignment,
	|	InventoryKinds.ProductsGroup AS ProductsGroup,
	|	InventoryKinds.PriceKind AS PriceKind,
	|	InventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	InventoryKinds.IsDuplicate AS IsDuplicate
	|INTO CatInventoryKinds
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	InventoryKinds.GoodsOwner AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.GoodsTransferMethod AS GoodsTransferMethod,
	|	InventoryKinds.NotUsedVendor AS NotUsedVendor,
	|	InventoryKinds.NotUsedBusinessUnit AS NotUsedBusinessUnit,
	|	InventoryKinds.NotUsedManager AS NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity AS NotUsedSalesOpportunity,
	|	InventoryKinds.Counterparty AS Counterparty,
	|	InventoryKinds.Contract AS Contract,
	|	InventoryKinds.NotUsedAssignment AS NotUsedAssignment,
	|	InventoryKinds.ProductsGroup AS ProductsGroup,
	|	InventoryKinds.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	InventoryKinds.PriceKind AS PriceKind,
	|	InventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	InventoryKinds.Ref AS Ref
	|INTO CorrectInventoryTypes
	|FROM
	|	CatInventoryKinds AS InventoryKinds
	|		INNER JOIN TTDoubleSelections AS Filters
	|		ON InventoryKinds.Organization = Filters.Organization
	|			AND InventoryKinds.InventoryType = Filters.InventoryType
	|			AND InventoryKinds.GoodsOwner = Filters.GoodsOwner
	|			AND InventoryKinds.Terms = Filters.Terms
	|			AND InventoryKinds.Currency = Filters.Currency
	|			AND InventoryKinds.SaleOfAnotherCompanyInventory = Filters.SaleOfAnotherCompanyInventory
	|			AND InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner = Filters.InventoryOwnerAttributeOfCompanyGoodsOwner
	|			AND InventoryKinds.GoodsTransferMethod = Filters.GoodsTransferMethod
	|			AND InventoryKinds.NotUsedVendor = Filters.NotUsedVendor
	|			AND InventoryKinds.NotUsedBusinessUnit = Filters.NotUsedBusinessUnit
	|			AND InventoryKinds.NotUsedManager = Filters.NotUsedManager
	|			AND InventoryKinds.NotUsedSalesOpportunity = Filters.NotUsedSalesOpportunity
	|			AND InventoryKinds.Counterparty = Filters.Counterparty
	|			AND InventoryKinds.Contract = Filters.Contract
	|			AND InventoryKinds.NotUsedAssignment = Filters.NotUsedAssignment
	|			AND InventoryKinds.ProductsGroup = Filters.ProductsGroup
	|			AND InventoryKinds.PriceKind = Filters.PriceKind
	|			AND InventoryKinds.SubjectToExcise = Filters.SubjectToExcise
	|			AND InventoryKinds.BusinessUnitProduction = Filters.BusinessUnitProduction
	|			AND InventoryKinds.FinancialAccountingGroup = Filters.FinancialAccountingGroup
	|			AND InventoryKinds.VATTaxation = Filters.VATTaxation
	|WHERE
	|	NOT InventoryKinds.IsDuplicate
	|
	|INDEX BY
	|	Organization,
	|	InventoryType,
	|	GoodsOwner,
	|	Terms,
	|	Currency,
	|	SaleOfAnotherCompanyInventory,
	|	InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	GoodsTransferMethod,
	|	NotUsedVendor,
	|	NotUsedBusinessUnit,
	|	NotUsedManager,
	|	NotUsedSalesOpportunity,
	|	Counterparty,
	|	Contract,
	|	NotUsedAssignment,
	|	ProductsGroup,
	|	SubjectToExcise,
	|	BusinessUnitProduction,
	|	PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	InventoryKinds.GoodsOwner AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.GoodsTransferMethod AS GoodsTransferMethod,
	|	InventoryKinds.NotUsedVendor AS NotUsedVendor,
	|	InventoryKinds.NotUsedBusinessUnit AS NotUsedBusinessUnit,
	|	InventoryKinds.NotUsedManager AS NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity AS NotUsedSalesOpportunity,
	|	InventoryKinds.Counterparty AS Counterparty,
	|	InventoryKinds.Contract AS Contract,
	|	InventoryKinds.NotUsedAssignment AS NotUsedAssignment,
	|	InventoryKinds.ProductsGroup AS ProductsGroup,
	|	InventoryKinds.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	InventoryKinds.PriceKind AS PriceKind,
	|	InventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	InventoryKinds.Ref AS Ref
	|INTO DuplicatesOfInventoryTypes
	|FROM
	|	CatInventoryKinds AS InventoryKinds
	|		INNER JOIN TTDoubleSelections AS Filters
	|		ON InventoryKinds.Organization = Filters.Organization
	|			AND InventoryKinds.InventoryType = Filters.InventoryType
	|			AND InventoryKinds.GoodsOwner = Filters.GoodsOwner
	|			AND InventoryKinds.Terms = Filters.Terms
	|			AND InventoryKinds.Currency = Filters.Currency
	|			AND InventoryKinds.SaleOfAnotherCompanyInventory = Filters.SaleOfAnotherCompanyInventory
	|			AND InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner = Filters.InventoryOwnerAttributeOfCompanyGoodsOwner
	|			AND InventoryKinds.GoodsTransferMethod = Filters.GoodsTransferMethod
	|			AND InventoryKinds.NotUsedVendor = Filters.NotUsedVendor
	|			AND InventoryKinds.NotUsedBusinessUnit = Filters.NotUsedBusinessUnit
	|			AND InventoryKinds.NotUsedManager = Filters.NotUsedManager
	|			AND InventoryKinds.NotUsedSalesOpportunity = Filters.NotUsedSalesOpportunity
	|			AND InventoryKinds.Counterparty = Filters.Counterparty
	|			AND InventoryKinds.Contract = Filters.Contract
	|			AND InventoryKinds.NotUsedAssignment = Filters.NotUsedAssignment
	|			AND InventoryKinds.ProductsGroup = Filters.ProductsGroup
	|			AND InventoryKinds.PriceKind = Filters.PriceKind
	|			AND InventoryKinds.SubjectToExcise = Filters.SubjectToExcise
	|			AND InventoryKinds.BusinessUnitProduction = Filters.BusinessUnitProduction
	|			AND InventoryKinds.FinancialAccountingGroup = Filters.FinancialAccountingGroup
	|			AND InventoryKinds.VATTaxation = Filters.VATTaxation
	|WHERE
	|	InventoryKinds.IsDuplicate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(Correct_.Ref, VALUE(Catalog.InventoryKinds.EmptyRef)) AS CorrectInventoryView,
	|	Duplicates.Ref AS Duplicate1,
	|	Duplicates.Ref.DeletionMark AS MarkingDoubleDeletion
	|FROM
	|	DuplicatesOfInventoryTypes AS Duplicates
	|		LEFT JOIN CorrectInventoryTypes AS Correct_
	|		ON Duplicates.Organization = Correct_.Organization
	|			AND Duplicates.InventoryType = Correct_.InventoryType
	|			AND Duplicates.GoodsOwner = Correct_.GoodsOwner
	|			AND Duplicates.Terms = Correct_.Terms
	|			AND Duplicates.Currency = Correct_.Currency
	|			AND Duplicates.SaleOfAnotherCompanyInventory = Correct_.SaleOfAnotherCompanyInventory
	|			AND Duplicates.InventoryOwnerAttributeOfCompanyGoodsOwner = Correct_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|			AND Duplicates.GoodsTransferMethod = Correct_.GoodsTransferMethod
	|			AND Duplicates.NotUsedVendor = Correct_.NotUsedVendor
	|			AND Duplicates.NotUsedBusinessUnit = Correct_.NotUsedBusinessUnit
	|			AND Duplicates.NotUsedManager = Correct_.NotUsedManager
	|			AND Duplicates.NotUsedSalesOpportunity = Correct_.NotUsedSalesOpportunity
	|			AND Duplicates.Counterparty = Correct_.Counterparty
	|			AND Duplicates.Contract = Correct_.Contract
	|			AND Duplicates.NotUsedAssignment = Correct_.NotUsedAssignment
	|			AND Duplicates.ProductsGroup = Correct_.ProductsGroup
	|			AND Duplicates.PriceKind = Correct_.PriceKind
	|			AND Duplicates.SubjectToExcise = Correct_.SubjectToExcise
	|			AND Duplicates.BusinessUnitProduction = Correct_.BusinessUnitProduction
	|			AND Duplicates.FinancialAccountingGroup = Correct_.FinancialAccountingGroup
	|			AND Duplicates.VATTaxation = Correct_.VATTaxation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTDoubleSelections
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CorrectInventoryTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DuplicatesOfInventoryTypes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CatInventoryKinds";
	
	SetParametersForDuplicateSearchRequest(Query);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	
	// Own types of stocks.
	AllDoubles = Result.Unload();
	
	DuplicatesFilter = New Structure("CorrectInventoryView", Catalogs.InventoryKinds.EmptyRef());
	DuplicatesWithoutCorrectEntries = AllDoubles.FindRows(DuplicatesFilter);
	
	If DuplicatesWithoutCorrectEntries.Count() > 0 Then
		For Each ArrRow In DuplicatesWithoutCorrectEntries Do
			BeginTransaction();
			Try
				Block = New DataLock;
				LockItem = Block.Add("Catalog.InventoryKinds");
				LockItem.SetValue("Ref", ArrRow.Duplicate1);
				LockItem.Mode = DataLockMode.Exclusive;
				Block.Lock();
				
				CatalogObject = ArrRow.Duplicate1.GetObject();
				CatalogObject.IsDuplicate = False;
				CatalogObject.AdditionalProperties.Insert("DonTCheckDuplicates", True);
				CatalogObject.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				MessageText = NStr("vi = 'Chưa hủy đánh dấu %IsDuplicate%: %Ref% vì: %Cause%';
									|ru = 'Не отменить отметку %IsDuplicate%: %Ref% по причине: %Cause%';
									|en = 'Cannot cancel %IsDuplicate% mark: %Ref% due to: %Cause%'; fa = 'Cannot cancel %IsDuplicate% mark: %Ref% due to: %Cause%';
									|it = 'Non è stato possibile cancellare il contrassegno %IsDuplicate%: %Ref% a causa: %Cause%';
									|pl = 'Nie można anulować oznaczenia %IsDuplicate%: %Ref% z powodu: %Cause%';
									|tr = '%Cause% nedeniyle işareti %IsDuplicate%: %Ref%iptal etme'");
				MessageText = StrReplace(MessageText, "%IsDuplicate%", "IsDuplicate");
				MessageText = StrReplace(MessageText, "%Ref%", CatalogObject.Ref);
				MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(InfobaseUpdate.EventLogEvent(),
					EventLogLevel.Error,
					Metadata.Catalogs.InventoryKinds,
					CatalogObject.Ref,
					MessageText);
			EndTry;
		EndDo;
		
		MarkDuplicatesOfStockTypes();
		
	EndIf;
	
	Result = Query.Execute();
	
	// Own types of stocks.
	Result = Query.Execute();
	AllDoubles = Result.Unload();
	
	DuplicatesFilter = New Structure("CorrectInventoryView", Catalogs.InventoryKinds.EmptyRef());
	DuplicatesWithoutCorrectEntries = AllDoubles.FindRows(DuplicatesFilter);
	
	If DuplicatesWithoutCorrectEntries.Count() > 0 Then
		MessageText = NStr("vi = 'Không phải tất cả phần tử trùng lặp của dạng vật tư đều xác định được dạng vật tư cụ thể. Hãy liên hệ với nhà phát triển.';
							|ru = 'Не для всех дублей видов запасов удается определить корректный вид запасов. Обратитесь к разработчикам.';
							|en = 'Cannot determine correct inventory owner attribute for some of the duplicate inventory owner attributes. Contact the developers.'; fa = 'Cannot determine correct inventory owner attribute for some of the duplicate inventory owner attributes. Contact the developers.';
							|it = 'Non per tutti i duplicati dei tipi di scorte è possibile determinare il tipo delle scorte corretto. Contattare i sviluppatori.';
							|pl = 'Nie dla wszystkich duplikatów rodzajów zapasów można określić poprawny rodzaj pozycji. Skontaktuj się z twórcami programu.';
							|tr = 'Tüm tekrarlanan stok türleri için doğru stok türünü belirlemek mümkün değildir. Geliştiricilere başvur.'");
		
		Raise MessageText;
	EndIf;
	
	// Let's form the correspondence of the elements to the replacement.
	MatchingRecords = New Map;
	
	For Each ArrRow In AllDoubles Do
		MatchingRecords.Insert(ArrRow.Duplicate1, ArrRow.CorrectInventoryView);
		
		If Not ArrRow.MarkingDoubleDeletion Then
			CatalogObject = ArrRow.Duplicate1.GetObject();
			CatalogObject.AdditionalProperties.Insert("DonTCheckDuplicates", True);
			CatalogObject.SetDeletionMark(True, False);
		EndIf;
	EndDo;
	SetPrivilegedMode(False);
	
	If MatchingRecords.Count() > 0 Then
		// Replace the duplicates.
		Exceptions = New Array;
		Exceptions.Add(Metadata.InformationRegisters.GoodsCost);
		Exceptions.Add(Metadata.InformationRegisters.ObsoleteInventoryOwnerAttributesWithBalance);
		
		SetPrivilegedMode(True);
		TMCommonUse.ReplaceReferences(MatchingRecords, Exceptions);
		SetPrivilegedMode(False);
		
		ReplaceDuplicatesInCostOfGoodsRegister(MatchingRecords);
		
		SetPrivilegedMode(True);
		InformationRegisters.ObsoleteInventoryOwnerAttributesWithBalance.UpdateRecords();
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR(CASE WHEN VALUETYPE(GoodsOwner) = TYPE(Catalog.Companies) THEN ValueAllowed(GoodsOwner)
	|	ELSE FALSE END)) 
	|	AND(CASE WHEN InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN ValueAllowed(GoodsOwner)
	|	ELSE TRUE END) ";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region ReplaceDuplicateInventoryKinds

Function RequestTextForDuplicateInventoryTypes(ThisIsUpdateHandler = False)
	
	QueryText = 
	"SELECT
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	CASE InventoryKinds.GoodsOwner
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Partners.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.GoodsOwner
	|	END AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.GoodsTransferMethod AS GoodsTransferMethod,
	|	CASE
	|		WHEN InventoryKinds.NotUsedVendor IN (VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		WHEN NOT InventoryKinds.GoodsOwner IN (UNDEFINED, VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.NotUsedVendor
	|	END AS NotUsedVendor,
	|	CASE
	|		WHEN InventoryKinds.NotUsedPurpose = VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.PurposeIsNotLimited)
	|			THEN VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.EmptyRef)
	|		ELSE InventoryKinds.NotUsedPurpose
	|	END AS NotUsedPurpose,
	|	InventoryKinds.NotUsedBusinessUnit AS NotUsedBusinessUnit,
	|	InventoryKinds.NotUsedManager AS NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity AS NotUsedSalesOpportunity,
	|	InventoryKinds.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE InventoryKinds.Counterparty
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Counterparty
	|	END AS Counterparty,
	|	CASE InventoryKinds.Contract
	|		WHEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Contract
	|	END AS Contract,
	|	InventoryKinds.NotUsedAssignment AS NotUsedAssignment,
	|	InventoryKinds.ProductsGroup AS ProductsGroup,
	|	InventoryKinds.PriceKind AS PriceKind,
	|	InventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	SUM(1) AS DuplicateCount
	|INTO TTDoubleSelections
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	(&ByAllCompanies
	|			OR InventoryKinds.Organization IN (&CompanyArray))
	|	AND (NOT InventoryKinds.DeletionMark
	|			OR NOT &CheckDeleteMark)
	|
	|GROUP BY
	|	InventoryKinds.Organization,
	|	InventoryKinds.InventoryType,
	|	InventoryKinds.VATTaxation,
	|	CASE InventoryKinds.GoodsOwner
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Partners.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.GoodsOwner
	|	END,
	|	InventoryKinds.Terms,
	|	InventoryKinds.Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.GoodsTransferMethod,
	|	CASE
	|		WHEN InventoryKinds.NotUsedVendor IN (VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		WHEN NOT InventoryKinds.GoodsOwner IN (UNDEFINED, VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.NotUsedVendor
	|	END,
	|	CASE
	|		WHEN InventoryKinds.NotUsedPurpose = VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.PurposeIsNotLimited)
	|			THEN VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.EmptyRef)
	|		ELSE InventoryKinds.NotUsedPurpose
	|	END,
	|	InventoryKinds.NotUsedBusinessUnit,
	|	InventoryKinds.NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity,
	|	InventoryKinds.FinancialAccountingGroup,
	|	CASE InventoryKinds.Counterparty
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Counterparty
	|	END,
	|	CASE InventoryKinds.Contract
	|		WHEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Contract
	|	END,
	|	InventoryKinds.NotUsedAssignment,
	|	InventoryKinds.ProductsGroup,
	|	InventoryKinds.SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction,
	|	InventoryKinds.PriceKind
	|
	|HAVING
	|	SUM(1) > 1
	|
	|INDEX BY
	|	Organization,
	|	InventoryType,
	|	GoodsOwner,
	|	Terms,
	|	Currency,
	|	SaleOfAnotherCompanyInventory,
	|	InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	GoodsTransferMethod,
	|	NotUsedVendor,
	|	NotUsedBusinessUnit,
	|	NotUsedManager,
	|	NotUsedSalesOpportunity,
	|	Counterparty,
	|	Contract,
	|	NotUsedAssignment,
	|	ProductsGroup,
	|	SubjectToExcise,
	|	BusinessUnitProduction,
	|	PriceKind";
	
	QueryText = QueryText + 
	"
	|;
	|//////////////////////////////////////////
	|";
	
	QueryText = StrReplace(QueryText, "&ThisIsUpdateHandler", ?(ThisIsUpdateHandler, "TRUE", "FALSE"));
	
	Return QueryText;
	
EndFunction

Procedure SetParametersForDuplicateSearchRequest(Query, CompanyArray = Undefined, CheckDeleteMark = False)
	
	ThereIsSelectionByOrganization_ = ValueIsFilled(CompanyArray);
	
	Query.SetParameter("ByAllCompanies", Not ThereIsSelectionByOrganization_);
	Query.SetParameter("CompanyArray", ?(ThereIsSelectionByOrganization_, CompanyArray, New Array));
	Query.SetParameter("CheckDeleteMark", CheckDeleteMark);
	
EndProcedure

Procedure ReplaceDuplicatesInCostOfGoodsRegister(ComplianceAnalyst)
	
	AnalystTable = New ValueTable;
	AnalystTable.Columns.Add("ReplaceableAnalytics",	New TypeDescription("CatalogRef.InventoryKinds"));
	AnalystTable.Columns.Add("NewAnalytics",		New TypeDescription("CatalogRef.InventoryKinds"));
	
	For Each KeyAndValue In ComplianceAnalyst Do
		NewRow = AnalystTable.Add();
		NewRow.ReplaceableAnalytics = KeyAndValue.Key;
		NewRow.NewAnalytics 		= KeyAndValue.Value;
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("AnalystTable", AnalystTable);
	
	Query.Text =
	"SELECT
	|	T.ReplaceableAnalytics AS ReplaceableAnalytics,
	|	T.NewAnalytics AS NewAnalytics
	|INTO TTAnalytics
	|FROM
	|	&AnalystTable AS T
	|
	|INDEX BY
	|	ReplaceableAnalytics
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsCost.Recorder AS Recorder
	|INTO TTRecorders_
	|FROM
	|	InformationRegister.GoodsCost AS GoodsCost
	|		INNER JOIN TTAnalytics AS TTAnalytics
	|		ON GoodsCost.InventoryOwnerAttribute = TTAnalytics.ReplaceableAnalytics
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsCost.Recorder AS Recorder,
	|	ENDOFPERIOD(GoodsCost.Period, MONTH) AS Period,
	|	GoodsCost.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsCost.Organization AS Organization,
	|	GoodsCost.AccountingSection AS AccountingSection,
	|	ISNULL(TTAnalytics.NewAnalytics, GoodsCost.InventoryOwnerAttribute) AS InventoryOwnerAttribute,
	|	AVG(GoodsCost.Cost) AS Cost,
	|	AVG(GoodsCost.AdditionalExpenseCost) AS AdditionalExpenseCost,
	|	AVG(GoodsCost.OffBalanceCost) AS OffBalanceCost,
	|	AVG(GoodsCost.CostExcludingVAT) AS CostExcludingVAT,
	|	AVG(GoodsCost.AdditionalExpensesCostExcludingVAT) AS AdditionalExpensesCostExcludingVAT,
	|	AVG(GoodsCost.LaborCosts) AS LaborCosts,
	|	AVG(GoodsCost.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
	|	AVG(GoodsCost.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
	|	AVG(GoodsCost.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
	|	AVG(GoodsCost.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
	|	AVG(GoodsCost.LocalCost) AS LocalCost,
	|	AVG(GoodsCost.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|	AVG(GoodsCost.AddExpensesLocal) AS AddExpensesLocal,
	|	AVG(GoodsCost.LaborCostsLocal) AS LaborCostsLocal,
	|	AVG(GoodsCost.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
	|	AVG(GoodsCost.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
	|	AVG(GoodsCost.PermanentDifference) AS PermanentDifference,
	|	AVG(GoodsCost.CostTD) AS CostTD,
	|	AVG(GoodsCost.CostMan) AS CostMan,
	|	AVG(GoodsCost.AddExpensesMan) AS AddExpensesMan,
	|	AVG(GoodsCost.LaborCostsMan) AS LaborCostsMan,
	|	AVG(GoodsCost.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
	|	AVG(GoodsCost.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag
	|FROM
	|	InformationRegister.GoodsCost AS GoodsCost
	|		INNER JOIN TTRecorders_ AS TTRecorders_
	|		ON GoodsCost.Recorder = TTRecorders_.Recorder
	|		LEFT JOIN TTAnalytics AS TTAnalytics
	|		ON GoodsCost.InventoryOwnerAttribute = TTAnalytics.ReplaceableAnalytics
	|
	|GROUP BY
	|	GoodsCost.Recorder,
	|	ENDOFPERIOD(GoodsCost.Period, MONTH),
	|	GoodsCost.ItemsLocationAttributes,
	|	GoodsCost.Organization,
	|	GoodsCost.AccountingSection,
	|	ISNULL(TTAnalytics.NewAnalytics, GoodsCost.InventoryOwnerAttribute)
	|
	|ORDER BY
	|	Recorder,
	|	ItemsLocationAttributes,
	|	Organization,
	|	AccountingSection,
	|	InventoryOwnerAttribute
	|";
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Selection = QueryResult.Select();
	
	CurrentRegistrar = Undefined;
	RecordSet = InformationRegisters.GoodsCost.CreateRecordSet();
	
	While Selection.Next() Do
		
		If CurrentRegistrar <> Selection.Recorder Then
			
			If ValueIsFilled(CurrentRegistrar) Then
				RecordSet.Write(True);
			EndIf;
			
			RecordSet = InformationRegisters.GoodsCost.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			
			CurrentRegistrar = Selection.Recorder;
			
		EndIf;
		
		FillPropertyValues(RecordSet.Add(), Selection);
		
	EndDo;
	
	If ValueIsFilled(CurrentRegistrar) Then
		RecordSet.Write(True);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Other

Function CreateInventoryView(FieldsStructure)
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		
		LockItem = Block.Add("Catalog.InventoryKinds");
		If ValueIsFilled(FieldsStructure.Organization) Then
			LockItem.SetValue("Organization", FieldsStructure.Organization);
		EndIf;
		If ValueIsFilled(FieldsStructure.InventoryType) Then
			LockItem.SetValue("InventoryType", FieldsStructure.InventoryType);
		EndIf;
		If ValueIsFilled(FieldsStructure.GoodsOwner) Then
			LockItem.SetValue("GoodsOwner", FieldsStructure.GoodsOwner);
		EndIf;
		If ValueIsFilled(FieldsStructure.Counterparty) Then
			LockItem.SetValue("Counterparty", FieldsStructure.Counterparty);
		EndIf;
		If ValueIsFilled(FieldsStructure.Terms) Then
			LockItem.SetValue("Terms", FieldsStructure.Terms);
		EndIf;
		If ValueIsFilled(FieldsStructure.Contract) Then
			LockItem.SetValue("Contract", FieldsStructure.Contract);
		EndIf;
		If ValueIsFilled(FieldsStructure.Currency) Then
			LockItem.SetValue("Currency", FieldsStructure.Currency);
		EndIf;
		If ValueIsFilled(FieldsStructure.VATTaxation) Then
			LockItem.SetValue("VATTaxation", FieldsStructure.VATTaxation);
		EndIf;
		If ValueIsFilled(FieldsStructure.FinancialAccountingGroup) Then
			LockItem.SetValue("FinancialAccountingGroup", FieldsStructure.FinancialAccountingGroup);
		EndIf;
		If ValueIsFilled(FieldsStructure.ProductsGroup) Then
			LockItem.SetValue("ProductsGroup", FieldsStructure.ProductsGroup);
		EndIf;
		If ValueIsFilled(FieldsStructure.PriceKind) Then
			LockItem.SetValue("PriceKind", FieldsStructure.PriceKind);
		EndIf;
		If ValueIsFilled(FieldsStructure.SubjectToExcise) Then
			LockItem.SetValue("SubjectToExcise", FieldsStructure.SubjectToExcise);
		EndIf;
		If ValueIsFilled(FieldsStructure.BusinessUnitProduction) Then
			LockItem.SetValue("BusinessUnitProduction", FieldsStructure.BusinessUnitProduction);
		EndIf;
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		InventoryOwnerAttribute = TypeOfStockBySelection(FieldsStructure); // responsible reading is performed again
		If Not ValueIsFilled(InventoryOwnerAttribute) Then // the type of stocks in the IB is guaranteed to be absent
			CatalogObject = Catalogs.InventoryKinds.CreateItem(); // therefore, we can create a new one
			FillPropertyValues(CatalogObject, FieldsStructure);
			CatalogObject.Write();
			
			InventoryOwnerAttribute = CatalogObject.Ref;
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		DescriptionOfInventoryType = TMCommonUseClientServer.StructurePresentation(FieldsStructure);
		
		MessageText = NStr("vi = 'Không thể ghi lại hàng tồn kho mới với các tham số sau: %DescriptionOfInventoryType% do: %Cause%';
							|ru = 'Не удалось записать новый вид запасов с параметрами: %DescriptionOfInventoryType% по причине: %Cause%';
							|en = 'Cannot save the new inventory owner attributes with parameters: %DescriptionOfInventoryType%. Reason: %Cause%'; fa = 'Cannot save the new inventory owner attributes with parameters: %DescriptionOfInventoryType%. Reason: %Cause%';
							|it = 'Impossibile registrare il nuovo tipo delle scorte con parametri: %DescriptionOfInventoryType% a causa: %Cause%';
							|pl = 'Zapis nowego rodzaju pozycji z parametrami: %DescriptionOfInventoryType% nie powiodło się z powodu: %Cause%';
							|tr = '%Cause% nedeniyle %DescriptionOfInventoryType% parametrelere sahip stok türü kaydedilemedi'");
		MessageText = StrReplace(MessageText, "%DescriptionOfInventoryType%", DescriptionOfInventoryType);
		MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Error,
			Metadata.Catalogs.InventoryKinds,
			,
			MessageText);
		Raise;
	EndTry;
	
	Return InventoryOwnerAttribute;
	
EndFunction

// Returns a structure with data for searching for or creating a new item in the list of inventory Views.
//
// Parameters:
//	Organization				 - CatalogRef.Companies				 - the organization for which you want to retrieve the structure
//	BusinessOperation	 - EnumRef.BusinessTransactions	 - household. operation to get the structure for
//	DocumentAttributes		 - Structure, QueryResultSelection	 - structure or selection with values.
//
// Returns:
//	See StockTypeSelectionParameters.
//
Function StockTypeStructure(Organization, BusinessOperation = Undefined, DocumentAttributes = Undefined) Export
	
	If Not ValueIsFilled(Organization) Then
		ExceptionText = NStr("vi = 'Thử khởi tạo dạng vật tư mà chưa điền doanh nghiệp.';
							|ru = 'Попытка генерации вида запасов с незаполненной организацией.';
							|en = 'An attempt to generate inventory owner attributes with no company specified.'; fa = 'An attempt to generate inventory owner attributes with no company specified.';
							|it = 'Tentativo di generare un tipo di scorte con un''organizzazione non compilata.';
							|pl = 'Próba generacji rodzaju zapasów z niewypełnioną firmą.';
							|tr = 'Doldurulmayan bir iş yeriyle stok türü oluşturma çabası.'");
		
		Raise ExceptionText;
	EndIf;
	
	StructureTypeOfInventory = StockTypeSelectionParameters(); 
	StructureTypeOfInventory.InventoryType = Enums.InventoryTypes.OwnGoods;
	StructureTypeOfInventory.Organization = Organization;
	
	If DocumentAttributes <> Undefined Then
		
		If DocumentAttributes.InventoryType = Enums.InventoryTypes.OperationService
			Or DocumentAttributes.InventoryType = Enums.InventoryTypes.AgentService Then
			ExceptionText = NStr("vi = 'Cố gắng tạo dạng hàng tồn kho cho loại hàng tồn kho ""%InventoryType%"".
			|Các loại hàng tồn kho không được sử dụng cho dạng hàng tồn kho này.';
			|ru = 'Попытка генерации вида запасов для типа запасов ""%InventoryType%"".
			|Для этого типа запасов виды запасов не используются.';
			|en = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.
			|Inventory owner attributes are not used for this inventory type.'; fa = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.
			|Inventory owner attributes are not used for this inventory type.';
			|it = 'Tentativo di generare un tipo di scorte per il tipo di scorte ""%InventoryType%"".
			|Per questo tipo di scorte i tipi di scorte non vengono utilizzati.';
			|pl = 'Próba generacji rodzaju zapasów dla typu zapasów ""%InventoryType%"".
			|Dla tego typu zapasów rodzaje zapasów nie są używane.';
			|tr = '""%InventoryType%"" stok tipi için stok türlerinin oluşturma çabası.
			|Bu stok türü için stok türleri kullanılmıyor.'");
			ExceptionText = StrReplace(ExceptionText, "%InventoryType%", DocumentAttributes.InventoryType);
			Raise ExceptionText;
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor
			Or BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany
			Or DocumentAttributes.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
		
			StructureTypeOfInventory.InventoryType = Enums.InventoryTypes.ConsignedGoods;
			
			ExclusionTexts = New Array;
			If Not ValueIsFilled(DocumentAttributes.GoodsOwner) Then
				ExclusionTexts.Add(NStr("vi = 'Chưa điền trường bặt buộc ""Chủ sở hữu hàng hóa"".';
										|ru = 'Не заполнен обязательный реквизит ""Владелец товара"".';
										|en = 'Attribute ""Goods owner"" is required.'; fa = 'Attribute ""Goods owner"" is required.';
										|it = 'Il requisito obbligatorio ""Proprietario della merce"" non è compilato.';
										|pl = 'Nie wypełniono obowiązkowego atrybutu ""Владелец товара"".';
										|tr = 'Zorunlu öznitelik ""Ürün sahibi"" doldurulmadı.'"));
			EndIf;
			If Not ValueIsFilled(DocumentAttributes.Currency) Then
				ExclusionTexts.Add(NStr("vi = 'Chưa điền mục tin bắt buộc ""Tiền tệ"".';
										|ru = 'Не заполнен обязательный реквизит ""Валюта"".';
										|en = 'Attribute ""Currency"" is required.'; fa = 'Attribute ""Currency"" is required.';
										|it = 'Il requisito obbligatorio ""Valuta"" non è compilato.';
										|pl = 'Nie wypełniono obowiązkowego atrybutu ""Валюта"".';
										|tr = 'Zorunlu öznitelik ""Para Birimi"" doldurulmadı.'"));
			EndIf;
			If ExclusionTexts.Count() Then
				ExceptionText = NStr("vi = 'Thử khởi tạo dạng vật tư đối với kiểu vật tư ""%InventoryType%"".';
									|ru = 'Попытка генерации вида запасов для типа запасов ""%InventoryType%"".';
									|en = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.'; fa = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.';
									|it = 'Tentativo di generare un tipo di scorte per il tipo di scorte ""%InventoryType%"".';
									|pl = 'Próba generacji rodzaju zapasów dla typu zapasów ""%InventoryType%"".';
									|tr = '""%InventoryType%"" stok tipi için stok türünün oluşturma çabası.'");
				ExceptionText = StrReplace(ExceptionText, "%InventoryType%", StructureTypeOfInventory.InventoryType);
				Raise ExceptionText + Chars.LF + StrConcat(ExclusionTexts, Chars.LF);
			EndIf;
			
			StructureTypeOfInventory.GoodsOwner = DocumentAttributes.GoodsOwner;
			StructureTypeOfInventory.Counterparty = ?(ValueIsFilled(DocumentAttributes.Counterparty), DocumentAttributes.Counterparty, Undefined);
			StructureTypeOfInventory.Terms = ?(ValueIsFilled(DocumentAttributes.Terms), DocumentAttributes.Terms, Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
			StructureTypeOfInventory.Contract = ?(ValueIsFilled(DocumentAttributes.Contract), DocumentAttributes.Contract, Undefined);
			StructureTypeOfInventory.Currency = DocumentAttributes.Currency;
			StructureTypeOfInventory.VATTaxation = DocumentAttributes.VATTaxation;
			
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
			Or DocumentAttributes.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
			
			StructureTypeOfInventory.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell;
			
			ExclusionTexts = New Array;
			If Not ValueIsFilled(DocumentAttributes.GoodsOwner) Then
				ExclusionTexts.Add(NStr("vi = 'Chưa điền trường bặt buộc ""Chủ sở hữu hàng hóa"".';
										|ru = 'Не заполнен обязательный реквизит ""Владелец товара"".';
										|en = 'Attribute ""Goods owner"" is required.'; fa = 'Attribute ""Goods owner"" is required.';
										|it = 'Il requisito obbligatorio ""Proprietario della merce"" non è compilato.';
										|pl = 'Nie wypełniono obowiązkowego atrybutu ""Владелец товара"".';
										|tr = 'Zorunlu öznitelik ""Ürün sahibi"" doldurulmadı.'"));
			EndIf;
			
			If Not ValueIsFilled(DocumentAttributes.Contract) Then
				ExclusionTexts.Add(NStr("vi = 'Chưa điền mục tin bắt buộc ""Hợp đồng"".';
										|ru = 'Не заполнен обязательный реквизит ""Договор"".';
										|en = 'Attribute ""Contract"" is required.'; fa = 'Attribute ""Contract"" is required.';
										|it = 'Il requisito obbligatorio ""Accordo"" non è compilato.';
										|pl = 'Nie wypełniono obowiązkowego atrybutu ""Договор"".';
										|tr = 'Zorunlu öznitelik ""Sözleşme"" doldurulmadı.'"));
			EndIf;
			
			If BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage
				And ExclusionTexts.Count() = 1 And Not ValueIsFilled(DocumentAttributes.PriceKind) Then
				ExceptionText = NStr("vi = 'Không có đủ hàng hóa để đổi từ kho.
				|Ở phương thức hoạt động hiện nay, không kiểm soát được số dư âm hàng hóa của các doanh nghiệp, nhưng cần ghi rõ dạng giá.';
				|ru = 'Недостаточно товаров для выкупа с хранения.
				|В текущем режиме работы отрицательный остаток товаров организаций не контролируется, но необходимо указать вид цены.';
				|en = 'Insufficient goods for redemption from storage. 
				|Negative balance of the company goods is not controlled in the current operating mode but you must specify the price type.'; fa = 'Insufficient goods for redemption from storage. 
				|Negative balance of the company goods is not controlled in the current operating mode but you must specify the price type.';
				|it = 'Non ci sono abbastanza merci per la redenzione dallo stoccaggio. 
				|Nell''attuale modalità operativa, il saldo negativo delle merci delle organizzazioni non viene controllato, pertanto è necessario specificare il tipo di prezzo.';
				|pl = 'Niewystarczająca ilość towarów do wykupu i przechowywania. 
				|W bieżącym trybie pracy ujemny stan magazynowy firmy nie jest kontrolowany ale należy wskazać rodzaj ceny.';
				|tr = 'Depodan geri almak için yeterli ürün yok.
				|Mevcut çalışma modunda, iş yeri ürünlerinin negatif bakiyesi kontrol edilmiyor, ancak fiyat türünün belirtilmesi gerekiyor.'");
				Raise ExceptionText;
			ElsIf BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale
				And ExclusionTexts.Count() > 0 Then
				ExceptionText = NStr("vi = 'Không đủ hàng hóa để giao từ kho.
				|Thậm chí nếu bỏ kiểm soát số dư thì chương trình cũng không hỗ trợ giao hàng từ kho cất giữ với ""số âm"".';
				|ru = 'Недостаточно товаров для отгрузки с хранения.
				|Даже если контроль остатков отключен, программа не поддерживает отгрузку товаров с ответственного хранения ""в минус"".';
				|en = 'Insufficient goods to ship from storage.
				|Even if balance control is disabled, the application does not support VMI pick-up in the amount exceeding the actual VMI amount.'; fa = 'Insufficient goods to ship from storage.
				|Even if balance control is disabled, the application does not support VMI pick-up in the amount exceeding the actual VMI amount.';
				|it = 'Non ci sono abbastanza merci per la spedizione dallo stoccaggio.
				|Anche se il controllo delle rimanenze è disabilitato, il programma non supporta la spedizione delle merci dalla custodia responsabile ""in negativo"".';
				|pl = 'Niewystarczająca ilość towarów do wysyłki z przechowywania.
				| Nawet jeżeli kontrola ostatków jest odłączona, program nie obsługuje wysyłkę towarów z depozytu ""в минус"".';
				|tr = 'Depodan sevk edilecek yeterli ürün yok.
				|Stok kontrolü devre dışı bırakılsa bile, program ürünlerin ""kırmızıda"" kasadan sevkiyatını desteklemiyor.'");
				Raise ExceptionText;
			EndIf;
			
			If ExclusionTexts.Count() Then
				ExceptionText = NStr("vi = 'Thử khởi tạo dạng vật tư đối với kiểu vật tư ""%InventoryType%"".';
									|ru = 'Попытка генерации вида запасов для типа запасов ""%InventoryType%"".';
									|en = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.'; fa = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.';
									|it = 'Tentativo di generare un tipo di scorte per il tipo di scorte ""%InventoryType%"".';
									|pl = 'Próba generacji rodzaju zapasów dla typu zapasów ""%InventoryType%"".';
									|tr = '""%InventoryType%"" stok tipi için stok türünün oluşturma çabası.'");
				ExceptionText = StrReplace(ExceptionText, "%InventoryType%", StructureTypeOfInventory.InventoryType);
				Raise ExceptionText + Chars.LF + StrConcat(ExclusionTexts, Chars.LF);
			EndIf;
			
			StructureTypeOfInventory.GoodsOwner = DocumentAttributes.GoodsOwner;
			StructureTypeOfInventory.Counterparty = ?(ValueIsFilled(DocumentAttributes.Counterparty), DocumentAttributes.Counterparty, Undefined);
			StructureTypeOfInventory.Contract = DocumentAttributes.Contract;
			StructureTypeOfInventory.PriceKind = DocumentAttributes.PriceKind;
			
		ElsIf DocumentAttributes.InventoryType = Enums.InventoryTypes.OwnGoodsInTransit
			Or DocumentAttributes.InventoryType = Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery Then
			
			StructureTypeOfInventory.InventoryType = DocumentAttributes.InventoryType;
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
			Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5
			Or DocumentAttributes.InventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider Then
		
			StructureTypeOfInventory.InventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider;
			
			If Not ValueIsFilled(DocumentAttributes.GoodsOwner) Then
				ExceptionText = NStr("vi = 'Thử khởi tạo dạng vật tư đối với kiểu vật tư ""%InventoryType%"".
				|Chưa điền mục tin bắt buộc ""Chủ sở hữu hàng hóa"".';
				|ru = 'Попытка генерации вида запасов для типа запасов ""%InventoryType%"".
				|Не заполнен обязательный реквизит ""Владелец товара"".';
				|en = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.
				|Attribute ""Goods owner"" is required.'; fa = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.
				|Attribute ""Goods owner"" is required.';
				|it = 'Tentativo di generare un tipo di scorte per il tipo di scorte ""%InventoryType%"".
				|Il requisito obbligatorio ""Proprietario della merce"" non è compilato.';
				|pl = 'Próba generacji rodzaju zapasów dla typu zapasów ""%InventoryType%"".
				|Nie wypełniono obowiązkowego atrybutu ""Владелец товара"".';
				|tr = '""%InventoryType%"" stok tipi için stok türünün oluşturma çabası.
				|Zorunlu öznitelik ""Ürün Sahibi"" doldurulmadı.'");
				ExceptionText = StrReplace(ExceptionText, "%InventoryType%", StructureTypeOfInventory.InventoryType);
				Raise ExceptionText;
			EndIf;
			
			StructureTypeOfInventory.GoodsOwner = DocumentAttributes.GoodsOwner;
			StructureTypeOfInventory.Counterparty = ?(ValueIsFilled(DocumentAttributes.Counterparty), DocumentAttributes.Counterparty, Undefined);
			StructureTypeOfInventory.Contract = ?(ValueIsFilled(DocumentAttributes.Contract), DocumentAttributes.Contract, Undefined);
			
		ElsIf BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or DocumentAttributes.InventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider
			Or DocumentAttributes.InventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider Then
			
			If DocumentAttributes.InventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider Then
				StructureTypeOfInventory.InventoryType = DocumentAttributes.InventoryType;
			Else
				StructureTypeOfInventory.InventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider;
			EndIf;
			
			If Not ValueIsFilled(DocumentAttributes.GoodsOwner) Then
				ExceptionText = NStr("vi = 'Thử khởi tạo dạng vật tư đối với kiểu vật tư ""%InventoryType%"".
				|Chưa điền mục tin bắt buộc ""Chủ sở hữu hàng hóa"".';
				|ru = 'Попытка генерации вида запасов для типа запасов ""%InventoryType%"".
				|Не заполнен обязательный реквизит ""Владелец товара"".';
				|en = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.
				|Attribute ""Goods owner"" is required.'; fa = 'An attempt to generate inventory owner attributes for the ""%InventoryType%"" inventory type.
				|Attribute ""Goods owner"" is required.';
				|it = 'Tentativo di generare un tipo di scorte per il tipo di scorte ""%InventoryType%"".
				|Il requisito obbligatorio ""Proprietario della merce"" non è compilato.';
				|pl = 'Próba generacji rodzaju zapasów dla typu zapasów ""%InventoryType%"".
				|Nie wypełniono obowiązkowego atrybutu ""Владелец товара"".';
				|tr = '""%InventoryType%"" stok tipi için stok türünün oluşturma çabası.
				|Zorunlu öznitelik ""Ürün Sahibi"" doldurulmadı.'");
				ExceptionText = StrReplace(ExceptionText, "%InventoryType%", StructureTypeOfInventory.InventoryType);
				Raise ExceptionText;
			EndIf;
			
			StructureTypeOfInventory.GoodsOwner = DocumentAttributes.GoodsOwner;
			StructureTypeOfInventory.Counterparty = ?(ValueIsFilled(DocumentAttributes.Counterparty), DocumentAttributes.Counterparty, Undefined);
			StructureTypeOfInventory.Contract = ?(ValueIsFilled(DocumentAttributes.Contract), DocumentAttributes.Contract, Undefined);
		Else
			If ValueIsFilled(DocumentAttributes.InventoryType) Then
				StructureTypeOfInventory.InventoryType = DocumentAttributes.InventoryType;
			Else
				StructureTypeOfInventory.InventoryType = Enums.InventoryTypes.OwnGoods;
			EndIf;
		EndIf;
		
		If StructureTypeOfInventory.InventoryType <> Enums.InventoryTypes.Work_5
			And GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups") Then
			
			StructureTypeOfInventory.FinancialAccountingGroup = DocumentAttributes.FinancialAccountingGroup;
			
		EndIf;
		If GetFunctionalOption("AnalyticalAccountingByProductsGroups") Then
			StructureTypeOfInventory.ProductsGroup = DocumentAttributes.ProductsGroup;
		EndIf;
		
		If StructureTypeOfInventory.InventoryType = Enums.InventoryTypes.OwnGoods Then
			StructureTypeOfInventory.SubjectToExcise = DocumentAttributes.SubjectToExcise;
			
			If StructureTypeOfInventory.SubjectToExcise Then
				StructureTypeOfInventory.BusinessUnitProduction = DocumentAttributes.BusinessUnitProduction;
			EndIf;
		EndIf;
	EndIf;
	
	StockTypeSelectionParameters = StockTypeSelectionParameters();
	
	For Each KeyAndValue In StockTypeSelectionParameters Do
		If Not ValueIsFilled(StructureTypeOfInventory[KeyAndValue.Key]) Then
			StructureTypeOfInventory[KeyAndValue.Key] = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	Return StructureTypeOfInventory;
	
EndFunction

Function TypeOfInventoryBySelectionsCache(AnalyticsParameters)
	
	StructureOfAnalytics = StockTypeSelectionParameters();
	FillPropertyValues(StructureOfAnalytics, AnalyticsParameters);
	
	Result = SettingsValueCached.TypeOfStockBySelection(StructureOfAnalytics.Organization,
		StructureOfAnalytics.InventoryType,
		StructureOfAnalytics.GoodsOwner,
		StructureOfAnalytics.Counterparty,
		StructureOfAnalytics.Terms,
		StructureOfAnalytics.Contract,
		StructureOfAnalytics.Currency,
		StructureOfAnalytics.VATTaxation,
		StructureOfAnalytics.FinancialAccountingGroup,
		StructureOfAnalytics.ProductsGroup,
		StructureOfAnalytics.PriceKind,
		StructureOfAnalytics.SubjectToExcise,
		StructureOfAnalytics.BusinessUnitProduction);
		
	If ValueIsFilled(Result)
			And Not Common.RefExists(Result) Then
		Result = Undefined;
	EndIf;
		
	If Not ValueIsFilled(Result) Then
		Result = CreateInventoryView(StructureOfAnalytics);
		RefreshReusableValues();
	EndIf;
	
	Return Result;
	
EndFunction

// Gets an excise tax attribute for the type of inventory.
// 
// Parameters:
//  InventoryOwnerAttribute - CatalogRef.InventoryKinds - Inventory owner attributes
// 
// Returns:
//  Boolean - True if it is subject to excise duty
Function SubjectToExcise(InventoryOwnerAttribute) Export
	
	Return Common.ObjectAttributeValue(InventoryOwnerAttribute, "SubjectToExcise");
	
EndFunction

#EndRegion

#Region NormalizationOfData

Procedure MarkDuplicatesOfStockTypes() Export
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = RequestTextForDuplicateInventoryTypes(True) + 
	"SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Description AS Description,
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	CASE InventoryKinds.GoodsOwner
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Partners.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.GoodsOwner
	|	END AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.GoodsTransferMethod AS GoodsTransferMethod,
	|	CASE
	|		WHEN InventoryKinds.NotUsedVendor IN (VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		WHEN NOT InventoryKinds.GoodsOwner IN (UNDEFINED, VALUE(Catalog.Companies.EmptyRef), VALUE(Catalog.Partners.EmptyRef))
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.NotUsedVendor
	|	END AS NotUsedVendor,
	|	CASE
	|		WHEN InventoryKinds.NotUsedPurpose = VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.PurposeIsNotLimited)
	|			THEN VALUE(Enum.PurposeTypesOfInventoryOwnerAttributes.EmptyRef)
	|		ELSE InventoryKinds.NotUsedPurpose
	|	END AS NotUsedPurpose,
	|	InventoryKinds.NotUsedBusinessUnit AS NotUsedBusinessUnit,
	|	InventoryKinds.NotUsedManager AS NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity AS NotUsedSalesOpportunity,
	|	InventoryKinds.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	CASE InventoryKinds.Counterparty
	|		WHEN VALUE(Catalog.Companies.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Counterparty
	|	END AS Counterparty,
	|	CASE InventoryKinds.Contract
	|		WHEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		WHEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.Contract
	|	END AS Contract,
	|	InventoryKinds.NotUsedAssignment AS NotUsedAssignment,
	|	InventoryKinds.ProductsGroup AS ProductsGroup,
	|	InventoryKinds.PriceKind AS PriceKind,
	|	InventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	InventoryKinds.IsDuplicate AS IsDuplicate,
	|	InventoryKinds.DeletionMark AS DeletionMark
	|INTO CatInventoryKinds
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.VATTaxation AS VATTaxation,
	|	InventoryKinds.GoodsOwner AS GoodsOwner,
	|	InventoryKinds.Terms AS Terms,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.GoodsTransferMethod AS GoodsTransferMethod,
	|	InventoryKinds.NotUsedVendor AS NotUsedVendor,
	|	InventoryKinds.NotUsedPurpose AS NotUsedPurpose,
	|	InventoryKinds.NotUsedBusinessUnit AS NotUsedBusinessUnit,
	|	InventoryKinds.NotUsedManager AS NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity AS NotUsedSalesOpportunity,
	|	InventoryKinds.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	InventoryKinds.Counterparty AS Counterparty,
	|	InventoryKinds.Contract AS Contract,
	|	InventoryKinds.NotUsedAssignment AS NotUsedAssignment,
	|	InventoryKinds.ProductsGroup AS ProductsGroup,
	|	InventoryKinds.PriceKind AS PriceKind,
	|	InventoryKinds.SubjectToExcise AS SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction AS BusinessUnitProduction,
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.DeletionMark AS DeletionMark,
	|	InventoryKinds.IsDuplicate AS IsDuplicate,
	|	COUNT(DISTINCT CompanyGoods.Recorder) AS RefsCount
	|FROM
	|	CatInventoryKinds AS InventoryKinds
	|		INNER JOIN TTDoubleSelections AS Filters
	|		ON InventoryKinds.Organization = Filters.Organization
	|			AND InventoryKinds.InventoryType = Filters.InventoryType
	|			AND InventoryKinds.VATTaxation = Filters.VATTaxation
	|			AND InventoryKinds.GoodsOwner = Filters.GoodsOwner
	|			AND InventoryKinds.Terms = Filters.Terms
	|			AND InventoryKinds.Currency = Filters.Currency
	|			AND InventoryKinds.SaleOfAnotherCompanyInventory = Filters.SaleOfAnotherCompanyInventory
	|			AND InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner = Filters.InventoryOwnerAttributeOfCompanyGoodsOwner
	|			AND InventoryKinds.GoodsTransferMethod = Filters.GoodsTransferMethod
	|			AND InventoryKinds.NotUsedVendor = Filters.NotUsedVendor
	|			AND InventoryKinds.NotUsedPurpose = Filters.NotUsedPurpose
	|			AND InventoryKinds.NotUsedBusinessUnit = Filters.NotUsedBusinessUnit
	|			AND InventoryKinds.NotUsedManager = Filters.NotUsedManager
	|			AND InventoryKinds.NotUsedSalesOpportunity = Filters.NotUsedSalesOpportunity
	|			AND InventoryKinds.FinancialAccountingGroup = Filters.FinancialAccountingGroup
	|			AND InventoryKinds.Counterparty = Filters.Counterparty
	|			AND InventoryKinds.Contract = Filters.Contract
	|			AND InventoryKinds.NotUsedAssignment = Filters.NotUsedAssignment
	|			AND InventoryKinds.ProductsGroup = Filters.ProductsGroup
	|			AND InventoryKinds.PriceKind = Filters.PriceKind
	|			AND InventoryKinds.SubjectToExcise = Filters.SubjectToExcise
	|			AND InventoryKinds.BusinessUnitProduction = Filters.BusinessUnitProduction
	|			AND (NOT InventoryKinds.IsDuplicate)
	|		LEFT JOIN AccumulationRegister.CompanyGoods AS CompanyGoods
	|		ON InventoryKinds.Ref = CompanyGoods.InventoryOwnerAttribute
	|
	|GROUP BY
	|	InventoryKinds.Counterparty,
	|	InventoryKinds.NotUsedAssignment,
	|	InventoryKinds.Currency,
	|	InventoryKinds.SaleOfAnotherCompanyInventory,
	|	InventoryKinds.NotUsedVendor,
	|	InventoryKinds.Terms,
	|	InventoryKinds.IsDuplicate,
	|	InventoryKinds.GoodsOwner,
	|	InventoryKinds.GoodsTransferMethod,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	InventoryKinds.Contract,
	|	InventoryKinds.InventoryType,
	|	InventoryKinds.Ref,
	|	InventoryKinds.Organization,
	|	InventoryKinds.NotUsedManager,
	|	InventoryKinds.NotUsedSalesOpportunity,
	|	InventoryKinds.FinancialAccountingGroup,
	|	InventoryKinds.DeletionMark,
	|	InventoryKinds.ProductsGroup,
	|	InventoryKinds.PriceKind,
	|	InventoryKinds.SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction,
	|	InventoryKinds.NotUsedPurpose,
	|	InventoryKinds.NotUsedBusinessUnit,
	|	InventoryKinds.VATTaxation
	|
	|ORDER BY
	|	Organization,
	|	InventoryType,
	|	VATTaxation,
	|	GoodsOwner,
	|	Terms,
	|	Currency,
	|	SaleOfAnotherCompanyInventory,
	|	InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	GoodsTransferMethod,
	|	NotUsedVendor,
	|	NotUsedPurpose,
	|	NotUsedBusinessUnit,
	|	NotUsedManager,
	|	NotUsedSalesOpportunity,
	|	FinancialAccountingGroup,
	|	Counterparty,
	|	Contract,
	|	NotUsedAssignment,
	|	ProductsGroup,
	|	PriceKind,
	|	SubjectToExcise,
	|	BusinessUnitProduction,
	|	COUNT(DISTINCT CompanyGoods.Recorder) DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTDoubleSelections
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CatInventoryKinds";
	
	SetParametersForDuplicateSearchRequest(Query);
	
	FilterFields = "
		|	Organization,
		|	InventoryType,
		|	VATTaxation,
		|	GoodsOwner,
		|	Terms,
		|	Currency,
		|	SaleOfAnotherCompanyInventory,
		|	InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	GoodsTransferMethod,
		|	NotUsedVendor,
		|	NotUsedPurpose,
		|	NotUsedBusinessUnit,
		|	NotUsedManager,
		|	NotUsedSalesOpportunity,
		|	FinancialAccountingGroup,
		|	Counterparty,
		|	Contract,
		|	NotUsedAssignment,
		|	ProductsGroup,
		|	SubjectToExcise,
		|	BusinessUnitProduction,
		|	PriceKind
		|";
	
	FieldsForComparison	= New Structure(FilterFields);
	SelectionFields1			= New Structure(FilterFields);
	DuplicatesOfSameGroup	= New Array;
	
	Result = Query.Execute();
	SelectingDuplicatesOfInventoryTypes = Result.Select();
	
	If SelectingDuplicatesOfInventoryTypes.Next() Then
		FillPropertyValues(FieldsForComparison, SelectingDuplicatesOfInventoryTypes);
		
		DuplicatesOfSameGroup.Add(SelectingDuplicatesOfInventoryTypes.Ref);
		
		While SelectingDuplicatesOfInventoryTypes.Next() Do
			FillPropertyValues(SelectionFields1, SelectingDuplicatesOfInventoryTypes);
			
			If Not TMCommonUseClientServer.StructuresAreEqual(FieldsForComparison, SelectionFields1) Then
				SelectAndMarkDuplicates(DuplicatesOfSameGroup);
			EndIf;
			
			DuplicatesOfSameGroup.Add(SelectingDuplicatesOfInventoryTypes.Ref);
			
			FillPropertyValues(FieldsForComparison, SelectingDuplicatesOfInventoryTypes);
		EndDo;
		
		SelectAndMarkDuplicates(DuplicatesOfSameGroup);
	EndIf;
	
EndProcedure

Procedure SelectAndMarkDuplicates(DuplicatesOfSameGroup)
	
	Counter = 1;
	
	While Counter <= DuplicatesOfSameGroup.UBound() Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.InventoryKinds");
			LockItem.SetValue("Ref", DuplicatesOfSameGroup[Counter]);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			CatalogObject = DuplicatesOfSameGroup[Counter].GetObject();
			CatalogObject.IsDuplicate = True;
			CatalogObject.AdditionalProperties.Insert("DonTCheckDuplicates", True);
			
			InfobaseUpdate.WriteObject(CatalogObject);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể xử lý danh mục: %Ref% do: %Cause%';
								|ru = 'Не удалось обработать справочник: %Ref% по причине: %Cause%';
								|en = 'Cannot process the catalog: %Ref%. Reason: %Cause%'; fa = 'Cannot process the catalog: %Ref%. Reason: %Cause%';
								|it = 'Non è stato possibile processare l''elenco: %Ref% a causa di: %Cause%';
								|pl = 'Przetwarzanie katalogu: %Ref% nie powiodło się z powodu: %Cause%';
								|tr = '%Cause% nedeniyle %Ref% kataloğu işlenemedi'");
			MessageText = StrReplace(MessageText, "%Ref%", DuplicatesOfSameGroup[Counter]);
			MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Error,
				Metadata.Catalogs.InventoryKinds,
				DuplicatesOfSameGroup[Counter],
				MessageText);
		EndTry;
		
		Counter = Counter + 1;
	EndDo;
	
	DuplicatesOfSameGroup.Clear();
	
EndProcedure

// Normalizes the Attributes values of a directory object.
//
// Parameters:
//	ObjectToProcess - CatalogObject.InventoryKinds - Yandex business directory object.
//
Procedure HandleObjectAttributes(ObjectToProcess) Export
	
	If Not ValueIsFilled(ObjectToProcess.GoodsOwner)
		And ObjectToProcess.GoodsOwner <> Undefined Then
		
		ObjectToProcess.GoodsOwner = Undefined;
		
	EndIf;
	
	If Not ValueIsFilled(ObjectToProcess.Contract)
		And ObjectToProcess.Contract <> Undefined Then
		
		ObjectToProcess.Contract = Undefined;
		
	EndIf;
	
	If Not ValueIsFilled(ObjectToProcess.Counterparty)
		And ObjectToProcess.Counterparty <> Undefined Then
		
		ObjectToProcess.Counterparty = Undefined;
		
	EndIf;
	
	If Not ValueIsFilled(ObjectToProcess.NotUsedVendor)
		And ObjectToProcess.NotUsedVendor <> Undefined Then
		
		ObjectToProcess.NotUsedVendor = Undefined;
		
	ElsIf ValueIsFilled(ObjectToProcess.GoodsOwner)
		And ObjectToProcess.NotUsedVendor <> Undefined Then
		
		ObjectToProcess.NotUsedVendor = Undefined;
		
	EndIf;
	
	If ObjectToProcess.NotUsedPurpose = Enums.PurposeTypesOfInventoryOwnerAttributes.PurposeIsNotLimited Then
		ObjectToProcess.NotUsedPurpose = Enums.PurposeTypesOfInventoryOwnerAttributes.EmptyRef();
	EndIf;
	
EndProcedure

// Returns the default collection of directory Attributes.
//
// Returns:
//	Structure - contains the following keys:
//		* Organization - CatalogRef.Companies, Array of CatalogRef.Companies - the organization on behalf of which the sale of goods will be processed.
//		* InventoryType - EnumRef.InventoryTypes, Array of EnumRef.InventoryTypes - available inventory types of products.
//		* GoodsOwner - CatalogRef.Companies, CatalogRef.Partners, Undefined - the owner of the goods.
//		* Counterparty - CatalogRef.Companies, CatalogRef.Counterparties, Undefined - the counterparty with whom the contract for the sale of goods is concluded.
//		* Terms - CatalogRef.TermsOfPurchaseFromVendors - the agreement under which the receipt of goods is processed.
//		* Contract - Undefined, CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts, Array of CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - the contract under which the sale of goods is executed.
//		* Currency - CatalogRef.Currencies - the currency used for settlements with the owner of the goods.
//		* VATTaxation - EnumRef.VATTaxationTypes - type of taxation of sales of goods subject to value added tax.
//		* FinancialAccountingGroup - CatalogRef.InventoryAccountingGroups - group of financial accounting of goods.
//		* ProductsGroup - CatalogRef.AnalyticalInventoryGroups - type of product.
//		* PriceKind - CatalogRef.VendorPriceTypes - type of price at which the receipt of goods is recorded.
//		* SaleOfAnotherCompanyInventory - Boolean - indicates whether the inventory type is being used for intra-company sales.
//		* InventoryOwnerAttributeOfCompanyGoodsOwner - CatalogRef.InventoryKinds - The Inventory owner attribute of the organization that owns the item.
//		* GoodsTransferMethod - EnumRef.GoodsTransferMethods - the method of Transferring items from the owner to the seller.
//		* NotUsedVendor - CatalogRef.Companies, CatalogRef.Partners, Undefined - supplier, if there is a separate accounting of the cost of items by supplier.
//		* NotUsedBusinessUnit - CatalogRef.BusinessStructure - division of separate accounting of items
//		* NotUsedManager - CatalogRef.Users - manager of separate item accounting.
//		* NotUsedSalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer - A sales opportunity for separate accounting of items.
//		* NotUsedAssignment - CatalogRef.Assignments - assignment of a separate need provided by admission.
//		* NotUsedPurpose - EnumRef.PurposeTypesOfInventoryOwnerAttributes - purpose of the item.
//		* SubjectToExcise - Boolean - indicates that the excise tax amount should be calculated for this item.
//		* BusinessUnitProduction - CatalogRef.BusinessStructure - the division in which the excisable item was produced.
//
Function EmptyViewAndStructure() Export
	
	Parameters = New Structure;
	Parameters.Insert("Organization", Catalogs.Companies.EmptyRef());
	Parameters.Insert("GoodsOwner", Undefined);
	Parameters.Insert("Counterparty", Undefined);
	Parameters.Insert("Contract", Undefined);
	Parameters.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	Parameters.Insert("Currency", Catalogs.Currencies.EmptyRef());
	Parameters.Insert("VATTaxation", Enums.VATTaxationTypes.EmptyRef());
	Parameters.Insert("InventoryType", Enums.InventoryTypes.EmptyRef());
	Parameters.Insert("FinancialAccountingGroup", Catalogs.InventoryAccountingGroups.EmptyRef());
	Parameters.Insert("ProductsGroup", Catalogs.AnalyticalInventoryGroups.EmptyRef());
	Parameters.Insert("PriceKind", Catalogs.VendorPriceTypes.EmptyRef());
	Parameters.Insert("SubjectToExcise", False);
	Parameters.Insert("BusinessUnitProduction", Catalogs.BusinessStructure.EmptyRef());
	Parameters.Insert("SaleOfAnotherCompanyInventory", False);
	Parameters.Insert("InventoryOwnerAttributeOfCompanyGoodsOwner", Catalogs.InventoryKinds.EmptyRef());
	Parameters.Insert("GoodsTransferMethod", Enums.GoodsTransferMethods.EmptyRef());
	Parameters.Insert("NotUsedVendor", Undefined);
	Parameters.Insert("NotUsedBusinessUnit", Catalogs.BusinessStructure.EmptyRef());
	Parameters.Insert("NotUsedManager", Catalogs.Users.EmptyRef());
	Parameters.Insert("NotUsedSalesOpportunity", Catalogs.SalesOpportunitiesToCustomer.EmptyRef());
	Parameters.Insert("NotUsedAssignment", Catalogs.Assignments.EmptyRef());
	Parameters.Insert("NotUsedPurpose", Enums.PurposeTypesOfInventoryOwnerAttributes.EmptyRef());
	
	Return Parameters;
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.InventoryKinds.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.33";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("b07c9520-04e6-423a-b833-89d3a9d664a0");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.InventoryKinds.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Обновление справочника ""Виды запасов"":';
								|vi = 'Update the ""Inventory owner attributes"" catalog:';
								|en = 'Update the ""Inventory owner attributes"" catalog:'; fa = 'Update the ""Inventory owner attributes"" catalog:';
								|it = 'Update the ""Inventory owner attributes"" catalog:';
								|pl = 'Update the ""Inventory owner attributes"" catalog:';
								|tr = '""Stok sahibinin öznitelikleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("ru = '- Заполнение реквизита ""Налогообложение НДС"" для комиссионных видов запасов, переданных между организациями.';
								|vi = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|en = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.'; fa = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|it = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|pl = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|tr = '- İş yerleri arasında devredilen komisyon tipi stok sahibinin öznitelikleri için ""KDV vergilendirmesi"" alanının doldurulması.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.InventoryKinds.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.InventoryKinds.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.InventoryKinds.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Performs registration of data for updating.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects	= EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod			= InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryKinds.Ref AS Ref
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Organization <> InventoryKinds.GoodsOwner
	|	AND InventoryKinds.GoodsOwner REFS Catalog.Companies
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND NOT InventoryKinds.VATTaxation IN
	|			(VALUE(Enum.VATTaxationTypes.EmptyRef),
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|			VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute());
	
EndProcedure

// Performs processing of data registered for updating.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																							FullObjectName);
		
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Не удалось обработать справочник ""Виды запасов"" по обработчику:';
								|vi = 'Cannot process the ""Inventory owner attributes"" catalog by the handler:';
								|en = 'Cannot process the ""Inventory owner attributes"" catalog by the handler:'; fa = 'Cannot process the ""Inventory owner attributes"" catalog by the handler:';
								|it = 'Cannot process the ""Inventory owner attributes"" catalog by the handler:';
								|pl = 'Cannot process the ""Inventory owner attributes"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Stok sahibinin öznitelikleri"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("ru = '- Заполнение реквизита ""Налогообложение НДС"" для комиссионных видов запасов, переданных между организациями.';
								|vi = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|en = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.'; fa = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|it = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|pl = '- Fill in the ""VAT taxation"" attribute for consignment goods transferred between companies.';
								|tr = '- İş yerleri arasında devredilen komisyon tipi stok sahibinin öznitelikleri için ""KDV vergilendirmesi"" alanının doldurulması.'"));
	
	AcceptableTypesOfVATTaxation = New Array;
	AcceptableTypesOfVATTaxation.Add(Enums.VATTaxationTypes.EmptyRef());
	AcceptableTypesOfVATTaxation.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	AcceptableTypesOfVATTaxation.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	
	Selection = Catalogs.InventoryKinds.SelectByRefs(UpdatedData, "Ref");
	
	While Selection.Next() Do
		ExceptionReason	= 0;
		Recommendation		= "";
		
		BeginTransaction();
		
		Try
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
								Selection,
								Selection.DataVersion,
								Parameters.Queue); // A reference object.Types of reserves -
			
			ExceptionReason	= "BadData";
			Recommendation		= NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
										|ru = 'Проверьте данные справочника вручную.';
										|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
										|it = 'Проверьте данные справочника вручную.';
										|pl = 'Check the catalog data manually.';
										|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			If CatalogObject <> Undefined Then
				If AcceptableTypesOfVATTaxation.Find(CatalogObject.VATTaxation) = Undefined Then
					CatalogObject.VATTaxation =
						?(Enums.VATTaxationTypes.TypesWithVAT().Find(CatalogObject.VATTaxation) <> Undefined,
							Enums.VATTaxationTypes.SaleIsSubjectToVAT,
							Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);;
				EndIf;
			EndIf;
			
			ExceptionReason = "Record";
			
			If CatalogObject.Modified() Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "BadData" Then
				IssueDetails = InfobaseUpdateTM.DataProblem(
									Selection.Ref,
									Recommendation,
									ErrorInfo());
				
				ExceptionsWhenUpdating.Add(IssueDetails);
			ElsIf ExceptionReason = "Record" Then
				InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				
				Raise StrConcat(ListOfDescriptions, Chars.LF);
			EndIf;
		EndTry;
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																						FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf
