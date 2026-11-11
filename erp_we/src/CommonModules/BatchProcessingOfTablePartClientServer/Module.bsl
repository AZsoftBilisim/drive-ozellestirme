#Region Public

#Region ObtainingStructuresOfCachedValues

// Returns a structure containing the fields of the cached values.
//
// Returns:
//	Structure - the structure of cached values with the following fields:
//		* PackingFactors - Map - used for storing the values of product packaging coefficients.
//		* VolumeOfPackages - Map - used for storing the volume values of product packages.
//		* PackageWeight_ - Map - used for storing the weight values of product packages.
//		* Barcodes - Map - used to store the values of the bar codes of the product packages.
//		* MonitorCompletionOfExpenseAnalytics - Map - used for storing the values of product packaging coefficients.
//		* AllocateLBSPOToExpenseItem - Map - used to store characteristics of the distribution of VAT at the 
//			objects of expenditure.
//		* MonitorRevenueAnalyticsCompletion - Map - it is used for storing signs of filling control 
//			for revenue Analytics.
//		* UseDiscountAdjustmentsInSales - Undefined, Boolean - Truth in sales is used calculating discounts manually.
//		* UseDiscountsMarkupsInSales - Undefined, Boolean - True-sales use 
//			automatic calculation of discounts.
//		* ProductBarcodeRegistrationRightIsAvailable - Undefined, Boolean - True - the user is allowed 
//			to register the barcode of the item.
//		* AcceptedByTheKNU - Map - used for storing signs of control over the acceptance of expenditure items for
//			tax accounting.
//		* SignsOfAgreements - Map of CatalogRef.TermsOfSale - It is used to store the type
//			of agreements in strings where the value is Boolean (true is typical, false is individual).
//		* QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//		* CollectionColumns - ValueTableColumnCollection - Description of all fields in the collection being processed.
//
Function GetStructureOfCachedValues() Export
	
	CachedValues = New Structure;
	CachedValues.Insert("CollectionWithCollectionWithCompositeType",	True);
	CachedValues.Insert("PackingFactors",	New Map);
	CachedValues.Insert("VolumeOfPackages",			New Map);
	CachedValues.Insert("PackageWeight_",			New Map);
	CachedValues.Insert("Barcodes",				New Map);
	CachedValues.Insert("AssignmentProperties",		New Map);
	CachedValues.Insert("WarehouseProperties_",		New Map);
	CachedValues.Insert("ProductAttributes",	New Map); // Reference books.Nomenclature.Values of the Nomenclature Requirements()
	CachedValues.Insert("ItemsTypes",		New Map);
	CachedValues.Insert("MonitorCompletionOfExpenseAnalytics",	New Map);
	CachedValues.Insert("AllocateLBSPOToExpenseItem",			New Map);
	CachedValues.Insert("MonitorRevenueAnalyticsCompletion",	New Map);
	CachedValues.Insert("UseAssetLiabilityAnalytics",		New Map);
	CachedValues.Insert("UseDiscountAdjustmentsInSales",			Undefined);
	CachedValues.Insert("UseDiscountsMarkupsInSales",	Undefined);
	CachedValues.Insert("UseDiscountAdjustmentsInPurchases",			Undefined);
	CachedValues.Insert("ProductBarcodeRegistrationRightIsAvailable",	Undefined);
	CachedValues.Insert("AcceptedByTheKNU", New Map);
	CachedValues.Insert("RNPTCoefficients", New Map);
	CachedValues.Insert("CurrentVATRates", Undefined);
	CachedValues.Insert("QueryDetails", Undefined); // Used only on the server
	CachedValues.Insert("MaterialAssignments", New Map);
	CachedValues.Insert("ProcessedRows", New Array);
	
	CachedValues.Insert("SignsOfCategoryOfOperation", New Map);
	EmptyCategoryStructure = New Structure;
	EmptyCategoryStructure.Insert("StocktakingRecord", False);
	EmptyCategoryStructure.Insert("MethodOfRepaymentOfCostOfAC", PredefinedValue("Enum.WaysToRepayCostOfInventory.ByDate"));
	EmptyCategoryStructure.Insert("ServiceLife", 0);
	EmptyCategoryStructure.Insert("ExpenseItem", PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef"));
	CachedValues.SignsOfCategoryOfOperation.Insert(PredefinedValue("Catalog.OperationCategories.EmptyRef"), EmptyCategoryStructure);
	
	CachedValues.Insert("SignsOfAgreements", New Map);
	
	Return CachedValues;
	
EndFunction // Get structurecashable values()

// Returns a structure containing fields of cached information obtained from the product barcode.
//
// Returns:
//	Structure - the structure of cached product data obtained by the product barcode, with the following fields:
//		* Products - CatalogRef.Products - product information.
//		* ItemsType - EnumRef.ItemsTypes - type of goods.
//		* SpecifyQuantityWhenRegisteringBatch - Boolean - indicates batch accounting of the item series.
//		* Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure - packing.
//		* ProductPresentation - String - presentation of the nomenclature.
//		* ExcisableGoods - Boolean - True-the product is excisable.
//		* MarkedProducts - Boolean - True-the product is a marked product.
//		* ItemVariantsAreUsed - Boolean - True - indicates the use of characteristics.
//		* SuppliedInReusablePackage - Boolean - The truth is a sign that the item is delivered in a container.
//		* ZoomRatio - Number - the coefficient of the package.
//		* UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - unit of measurement of the product.
//		* SinglePackaging - CatalogRef.PackagesAndUnitsOfMeasure - single product packaging.
//		* MultipleUnitPackages - Boolean - Truth-the product has several types of single packages.
//		* PackingList - DocumentRef.PackingList - packing list.
//		* UnknownBarcode - Boolean - True - there is no barcode data in the information database.
//		* Barcode - String - the barcode of the product.
//		* QuantityByBarcode - Number - product quantity (in storage units) by barcode.
//		* NumberOfPackages - Number - number of product packages.
//		* BarcodeNotFromCache - Undefined, Boolean - True-the barcode is not from the memory cache.
//		* ProductsInSet - CatalogRef.Products - information about the set.
//		* ItemVariantOfSet - CatalogRef.ItemsCharacteristics - characteristics of the set.
//		* SetPricingOption - EnumRef.SetPriceCalculationOptions - option for calculating the set price.
//		* CompletedActions - Structure - the structure of the actions performed with the product line in the tabular part of the document:
//			** Added2 - Boolean - True - the product line has been added.
//			** IsChanged - Boolean - True - the product line has been changed.
//		* Assignments - Undefined, CatalogRef.Assignments - purpose of the product.
//		* UsePackages - Boolean - Truth is a sign of the use of packages.
//		* Series - CatalogRef.ItemsBatches - product series.
//		* SeriesAreUsed - Boolean - Truth is a sign of the use of series.
//		* BatchesIndicationStatuses - Map of KeyAndValue - a collection containing information about the Statuses of specifying series in warehouses:
//			** Key - CatalogRef.Warehouses - Item accounting warehouse.
//			** Value - Number - The Status of the indication of the series in stock.
//		* ItemsBarcode - Boolean - indicates that the barcode information was obtained from the Bar Code information register of the Nomenclature.
//		* NonUniqueBarcode - Boolean - a sign of the uniqueness of the barcode.
//		* ReceivedAccordingToInfobaseData - Boolean - indicates that the item barcode data was obtained from the Information Security Service.
//
Function CachedInformationStructureByBarcode() Export
	
	BarcodeInformation_ = New Structure;
	
	BarcodeInformation_.Insert("Products",						PredefinedValue("Catalog.Products.EmptyRef"));
	BarcodeInformation_.Insert("ItemsType",					PredefinedValue("Enum.ItemsTypes.EmptyRef"));
	BarcodeInformation_.Insert("SpecifyQuantityWhenRegisteringBatch",		True);
	BarcodeInformation_.Insert("Characteristic",					PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	BarcodeInformation_.Insert("Package",							PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	BarcodeInformation_.Insert("ProductPresentation",			"");
	BarcodeInformation_.Insert("ExcisableGoods",					False);
	BarcodeInformation_.Insert("MarkedProducts",				False);
	BarcodeInformation_.Insert("ItemVariantsAreUsed",		False);
	BarcodeInformation_.Insert("SuppliedInReusablePackage",	False);
	BarcodeInformation_.Insert("ZoomRatio",						1);
	BarcodeInformation_.Insert("UnitOfMeasure",					PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	BarcodeInformation_.Insert("SinglePackaging",					PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	BarcodeInformation_.Insert("MultipleUnitPackages",		False);
	BarcodeInformation_.Insert("PackingList",					PredefinedValue("Document.PackingList.EmptyRef"));
	BarcodeInformation_.Insert("UnknownBarcode",				True);
	BarcodeInformation_.Insert("Barcode",							"");
	BarcodeInformation_.Insert("QuantityByBarcode",				0);
	BarcodeInformation_.Insert("NumberOfPackages",				1);
	BarcodeInformation_.Insert("BarcodeNotFromCache",					Undefined);
	BarcodeInformation_.Insert("ProductsInSet",				PredefinedValue("Catalog.Products.EmptyRef"));
	BarcodeInformation_.Insert("ItemVariantOfSet",				PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	BarcodeInformation_.Insert("SetPricingOption",			PredefinedValue("Enum.SetPriceCalculationOptions.EmptyRef"));
	BarcodeInformation_.Insert("CompletedActions",				New Structure("Added2, IsChanged", False, False));
	BarcodeInformation_.Insert("Assignments",						Undefined);
	BarcodeInformation_.Insert("UsePackages",				False);
	BarcodeInformation_.Insert("Series",								PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
	BarcodeInformation_.Insert("SeriesAreUsed",					False);
	BarcodeInformation_.Insert("BatchesIndicationStatuses",				New Map);
	BarcodeInformation_.Insert("ItemsBarcode",				True);
	BarcodeInformation_.Insert("NonUniqueBarcode",				False);
	BarcodeInformation_.Insert("ReceivedAccordingToInfobaseData",					True);
	
	BatchProcessingOfTablePartClientServerLocalization.ToSupplementStructureOfCachedBarcodeInformation(
		BarcodeInformation_);
	
	Return BarcodeInformation_;
	
EndFunction

// Returns a structure containing fields of cached service values.
//
// Returns:
//	Structure - the structure of cached service data, with the following fields:
//		* PercentOfVATRates - Map - used for storing percentages of VAT rates.
//		* Barcodes - Map - used for storing bar code values for services.
//		* UseDiscountAdjustmentsInSales - Undefined, Boolean - Truth in sales is used calculating discounts manually.
//		* UseDiscountsMarkupsInSales - Undefined, Boolean - True-sales use 
//			automatic calculation of discounts.
//		* UseDiscountAdjustmentsInPurchases - Undefined, Boolean - True - purchases use manual discount calculation.
//
Function GetStructureOfCachedValuesServices() Export
	
	CachedValues = New Structure;
	CachedValues.Insert("PercentOfVATRates",    New Map);
	CachedValues.Insert("Barcodes",            New Map);
	CachedValues.Insert("UseDiscountAdjustmentsInSales",         Undefined);
	CachedValues.Insert("UseDiscountsMarkupsInSales", Undefined);
	CachedValues.Insert("UseDiscountAdjustmentsInPurchases",         Undefined);
	
	Return CachedValues;
	
EndFunction // Get Structurecashable Service values()

#EndRegion

#Region ObtainingParameterStructuresForProcessingTablePart

// Default parameters for filling in the supplier agreement.
// 
// Returns:
//  Structure - Default parameters for filling in the supplier agreement:
// * OnlyValid - Boolean - If reset, it is selected without selection by Status 
// * BusinessOperation - Undefined, Array of EnumRef.BusinessTransactions, EnumRef.BusinessTransactions - Selection according to the appropriate Attributes.
// * PriceIncludesVAT - Undefined, Boolean - Selection according to the appropriate Attributes.
// * ContractsAreUsed - Undefined, Boolean - Selection according to the appropriate Attributes.
Function ParametersForFillingOutSupplierAgreements() Export
	
	ReturnValue = New Structure;
	
	ReturnValue.Insert("OnlyValid",                True);
	ReturnValue.Insert("BusinessOperation",            Undefined);
	ReturnValue.Insert("PriceIncludesVAT",                  Undefined);
	ReturnValue.Insert("ContractsAreUsed", Undefined);
	
	Return ReturnValue;
	
EndFunction

// Default Contract filling parameters.
// 
// Returns:
//  Structure - Default Contract Filling Parameters:
// * Organization - CatalogRef.Companies - Selection of an organization Contract
// * BusinessOperation -Undefined, Array of EnumRef.BusinessTransactions, EnumRef.BusinessTransactions - Selection By Economic Operation
// * ARAPCurrency - Undefined, CatalogRef.Currencies - Selection by settlement currency
// * LineOfBusiness - Undefined, CatalogRef.LinesOfBusiness - Selection by line of business
// * ConsignmentSales25 - Undefined, Boolean - Selection based on commission sales.
// * ARAPObjectSettings - Undefined, EnumRef.ARAPObjectSettings - Selection according to the order of calculations.
// * RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage - Undefined, EnumRef.RegistrationOfWriteOffOfGoodsAcceptedForStorage - Selection according to the appropriate Attributes.
// * ContractWithSelfEmployedPerson - Boolean - The selection value according to the corresponding Attribute.
// * Taxation     - EnumRef.VATTaxationTypes  - Determines the use of agency VAT
// * ContractType         - Undefined, Array of EnumRef.ContractTypes - selection by Contract type
Function DefaultContractFillingParameters() Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Organization",             PredefinedValue("Catalog.Companies.EmptyRef"));
	ReturnValue.Insert("BusinessOperation",   Undefined);
	ReturnValue.Insert("ARAPCurrency",    Undefined);
	ReturnValue.Insert("LineOfBusiness", Undefined);
	ReturnValue.Insert("ConsignmentSales25",   Undefined);
	ReturnValue.Insert("ARAPObjectSettings",         Undefined);
	ReturnValue.Insert("ContractType",             Undefined);
	ReturnValue.Insert("RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage",
		Undefined);
	
	ReturnValue.Insert("Taxation",
		PredefinedValue("Enum.VATTaxationTypes.EmptyRef"));
	
	ReturnValue.Insert("ContractWithSelfEmployedPerson", False);
	
	Return ReturnValue;
	
EndFunction

// Fill-in parameters for the "Fill-in operation by Agreement" action 
// 
// Returns:
// Structure:
//  * DefaultValue - EnumRef.BusinessTransactions - The value of operation that can be set if it was not possible to fill in from the agreement and Contract.
Function ParametersForFillingOfOperationsByAgreementContract() Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("DefaultValue", PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	
	Return ReturnValue;
	
EndFunction

// Returns a structure containing the fields of values used to fill in the types of prices in the rows of the table part of the document.
//
// Parameters:
//	PriceKind - String, CatalogRef.TypesOfPrices - the name of the field or the value of the price type.
//
// Returns:
//  Structure - Parameters For Filling In The Price Type In The TS Line:
// * PriceKind - String, CatalogRef.TypesOfPrices - the name of the field or the value of the price type.
// * DefaultPriceType - Undefined, CatalogRef.TypesOfPrices - the default value used for filling in.
// * FilterParameters - Structure - Price Type Selection Parameters:
// ** PriceIncludesVAT - Undefined, Boolean - if it is undefined, then the selection is not set.
// ** Status - EnumRef.StatusesOfPriceTypeValidity - if it is undefined, then the selection is not set.
// ** UseWhileSellingToCustomers - Undefined, Boolean - if it is undefined, then the selection is not set.
// ** UseWhileTransferringProductsToMaterialProvider - Undefined, Boolean - if it is undefined, then the selection is not set.
//
Function ParametersForFillingInPriceTypeInTSLine(PriceKind) Export
	
	FilterParameters = New Structure;
	FilterParameters.Insert("PriceIncludesVAT");
	FilterParameters.Insert("Status", PredefinedValue("Enum.StatusesOfPriceTypeValidity.Valid"));
	FilterParameters.Insert("UseWhileSellingToCustomers");
	FilterParameters.Insert("UseWhileTransferringProductsToMaterialProvider");
	
	ParametersForFillingInPriceType = New Structure;
	ParametersForFillingInPriceType.Insert("PriceKind", PriceKind);
	ParametersForFillingInPriceType.Insert("DefaultPriceType");
	ParametersForFillingInPriceType.Insert("FilterParameters", FilterParameters);
	
	Return ParametersForFillingInPriceType;
	
EndFunction

// Returns a structure containing the fields of values used to fill in prices in the rows of the table part of the document.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//	PriceTypeInHeader - Boolean - The truth is a sign of indication of price in the header of the document.
//
// Returns:
//	Structure - the structure used to fill in the prices in the tabular part of the document:
//		* Date - Date - document date.
//		* Currency - CatalogRef.Currencies - the currency of the document.
//		* PriceKind - CatalogRef.TypesOfPrices - The type of price (may not be, depends on whether there is a type of price in the header of the document or not).
//
Function ParametersForFillingInPriceInTSLine(Object, PriceTypeInHeader = False) Export
	
	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("Date",   Object.Date);
	PriceFillingStructure.Insert("Currency", Object.Currency);
	
	If PriceTypeInHeader Then
		PriceFillingStructure.Insert("PriceKind", Object.PriceKind);
	EndIf;
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing fields of values used for recalculating VAT amounts in the rows of the table part 
// of the document.
//
// Parameters:
//	Object - FormDataStructure - Document data:
//	* PriceIncludesVAT - Boolean - True-VAT is included in the product price.
//	* VATTaxation - EnumRef.VATTaxationTypes - document taxation
//
// Returns:
//	Structure - the structure used to recalculate VAT amounts in the tabular part of the document:
//		* PriceIncludesVAT - Boolean - True-VAT is included in the product price.
//		* VATTaxation - EnumRef.VATTaxationTypes - Taxation of the document.
//
Function ParametersForConvertingAmountOfNDSVToTS(Object) Export
	
	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	If CommonClientServer.HasAttributeOrObjectProperty(Object,"VATTaxation") Then
		PriceFillingStructure.Insert("VATTaxation", Object.VATTaxation);
	EndIf;
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing parameters for filling in the VAT rate
// of the document.
//
// Parameters:
//	Object - FormDataStructure, Structure - Document data:
//		* Date - Date
//		* Organization - CatalogRef.Companies
//		* VATTaxation - EnumRef.VATTaxationTypes
//		* BusinessOperation - EnumRef.BusinessTransactions
//	ByShipmentDate - Boolean - Indicates that bids should be received on the date of shipment
//	ToReturnReusablePackage - Boolean - 
//
// Returns:
//	Structure - the structure used to recalculate VAT amounts in the tabular part of the document:
//		* VATTaxation - EnumRef.VATTaxationTypes - Taxation of the document.
//		* Organization - Undefined, CatalogRef.Companies - Organization of the document
//		* Date - Date, Undefined - Document date
//		* ByDateOfReceipt - Boolean - Indicates that bids should be received as of the receipt date
//		* ByShipmentDate - Boolean - Indicates that bids should be received on the date of shipment
//		* ToReturnReusablePackage - Boolean - indicates whether a multi-turn container must be returned.
//		* BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//		* NameOfProductsField - String - Name of the item field to get the bid for.
//		* Suffix - String
//		* InitializingIncomingDocument - Boolean
//		* FillingOnBasisOfCopying - Boolean
//		* VATTaxationAtTabularPart - Boolean
//		* SpecifiedVATRate - Undefined
//
Function ParametersForFillingInVATRate(Object = Undefined, ByShipmentDate = False, ToReturnReusablePackage = False) Export
	
	Parameters = New Structure;
	Parameters.Insert("Date", Undefined);
	Parameters.Insert("Organization", Undefined);
	Parameters.Insert("VATTaxation", PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT"));
	Parameters.Insert("ByShipmentDate", ByShipmentDate);
	Parameters.Insert("ToReturnReusablePackage", ToReturnReusablePackage);
	Parameters.Insert("Suffix", "");
	Parameters.Insert("InitializingIncomingDocument", False);
	Parameters.Insert("FillingOnBasisOfCopying", False);
	Parameters.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	Parameters.Insert("NameOfProductsField", "");
	Parameters.Insert("VATTaxationAtTabularPart", False);
	Parameters.Insert("SpecifiedVATRate", Undefined);
	Parameters.Insert("CorrectedDocument");
	Parameters.Insert("ByDateOfReceipt", False);
	Parameters.Insert("ByCorrectionDate", False);
	Parameters.Insert("ByImplementationDate", True);
		
	If Object <> Undefined Then
		
		Parameters.Date = Object.Date;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "Organization") Then
			Parameters.Organization = Object.Organization;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "VATTaxation") Then
			Parameters.Insert("VATTaxation", Object.VATTaxation);
		EndIf;
		
		If Not ToReturnReusablePackage And CommonClientServer.HasAttributeOrObjectProperty(Object, "ToReturnReusablePackage") Then
			Parameters.Insert("ToReturnReusablePackage", Object.ToReturnReusablePackage);
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "BusinessOperation") Then
			Parameters.Insert("BusinessOperation", Object.BusinessOperation);
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "CorrectedDocument") 
			And CommonClientServer.HasAttributeOrObjectProperty(Object, "Patch") Then
			Parameters.Insert("CorrectedDocument", Object.CorrectedDocument);
			Parameters.Insert("ByCorrectionDate", Object.Patch);
		EndIf;
				
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns a structure containing parameters for filling in the VAT rate 
// according to the price type and the register of information "Prices of nomenclature 2.5" when processing rows of the tabular part.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject - Document data.
//	ByShipmentDate - Boolean - Indicates that bids should be received on the date of shipment
//
// Returns:
//	Structure - the structure used to fill in the VAT rate by price type in the tabular part of the document:
//		* Date - Date - Document date
//		* Organization - CatalogRef.Companies - Organization of the document
//		* Partner - CatalogRef.Partners - Document Partner
//		* Terms - CatalogRef.TermsOfSale - Document Agreement
//		* PriceKind - CatalogRef.TypesOfPrices - The price type selected for filling in the lines of the document.
//		* FillInPriceView - Boolean - Indicates that you need to fill in the price type for the item
//		* ToReturnReusablePackage - Boolean - indicates whether a multi-turn container must be returned.
//		* Suffix - String - Prefix of the VAT rate filling Attribute.
//		* BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//		* VATTaxation - EnumRef.VATTaxationTypes - Taxation of the document.
//		* ByShipmentDate - Boolean - Indicates that bids should be received on the date of shipment
//
Function ParametersForFillingInVATRateByPriceType(Object = Undefined, ByShipmentDate = False) Export
	
	Parameters = New Structure;
	Parameters.Insert("Date");
	Parameters.Insert("Organization");
	Parameters.Insert("CountryOfOrganizationRegistration");
	Parameters.Insert("Partner");
	Parameters.Insert("Terms");
	Parameters.Insert("PriceKind");
	Parameters.Insert("FillInPriceView", False);
	Parameters.Insert("ToReturnReusablePackage", False);
	Parameters.Insert("Suffix", "");
	Parameters.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	Parameters.Insert("VATTaxation", PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT"));
	Parameters.Insert("ByShipmentDate", ByShipmentDate);
	Parameters.Insert("UsePriceManagementSystem25", PriceManagementSystemServerCall.UsePriceManagementSystem25());
	
	If Object <> Undefined Then
		
		Parameters.Date = Object.Date;
		If ByShipmentDate Then
			If CommonClientServer.HasAttributeOrObjectProperty(Object, "NotShipInInstallments")
				And CommonClientServer.HasAttributeOrObjectProperty(Object, "DateOfShipment")
				And Object.NotShipInInstallments And ValueIsFilled(Object.DateOfShipment) Then
					
				Parameters.Date = Object.DateOfShipment;
				
			EndIf;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "Organization") Then
			Parameters.Organization = Object.Organization;
			Parameters.CountryOfOrganizationRegistration = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Object.Organization);
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "VATTaxation") Then
			Parameters.VATTaxation = Object.VATTaxation;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "ToReturnReusablePackage") Then
			Parameters.ToReturnReusablePackage = Object.ToReturnReusablePackage;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "BusinessOperation") Then
			Parameters.BusinessOperation = Object.BusinessOperation;
		EndIf;
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns a structure containing the document currency, the currency of the organization's regulated accounting
// , and the currency of management accounting.
//
// Parameters:
// 	DocumentCurrency - CatalogRef.Currencies - the currency of the document.
// 	ComplCurrency - CatalogRef.Currencies - The local accounting currency of the organization.
// 	CurrencyOfMan - CatalogRef.Currencies - currency of management accounting.
//
// Returns:
// 	Structure:
// 		* DocumentCurrency - CatalogRef.Currencies
// 		* ComplCurrency - CatalogRef.Currencies
// 		* CurrencyOfMan - CatalogRef.Currencies
//
Function ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(DocumentCurrency, ComplCurrency, CurrencyOfMan) Export
	
	Result = New Structure;
	Result.Insert("DocumentCurrency", DocumentCurrency);
	Result.Insert("ComplCurrency", ComplCurrency);
	Result.Insert("CurrencyOfMan", CurrencyOfMan);
	
	Return Result;
	
EndFunction

// Returns a structure containing the fields of values used to fill in the quantity for the RNPT in the rows of the table
// part of the document.
//
// Parameters:
//	Object - FormDataStructure - the form data object.
//	StorageLocationFieldName - String - name of the Warehouse field located in the object header or table part.
//	StorageLocationInTabularPart - Boolean - indicates whether the Warehouse field is present in the table part of the object.
//
// Returns:
//	See AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient.
//
Function ParametersForObtainingRnptCoefficient(Object, StorageLocationFieldName = "Warehouse", StorageLocationInTabularPart = False) Export
	
	Return AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(Object,
																								StorageLocationFieldName,
																								StorageLocationInTabularPart);
	
EndFunction

// Returns a structure containing fields of values used to fill in purchase prices in the rows of the table part 
// of the document.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//	NameOfPriceTypeField - String, Undefined - The name of the Attribute of the price type header, if the name is not the "Supplier type".
//
// Returns:
//	Structure - the structure used to fill in the purchase prices in the rows of the tabular part of the document:
//		* Terms - CatalogRef.TermsOfSale - agreement on the document.
//		* Partner - CatalogRef.Partners - partner for the document.
//		* Date - Date - document date.
//		* Currency - CatalogRef.Currencies - the currency of the document.
//		* VendorPriceKind - CatalogRef.VendorPriceTypes - the currency of the document.
//		* FieldName - String - the name of the field to put the received price in
//		* PriceIncludsVAT - Undefined, Boolean - Selection on the basis of "pricesincludes" when searching for the type of prices. If it is not filled in, then the selection is not used. 
//		* UseAgreementFromTable - Boolean - Indicates the need to use the agreement not from the header, but from the tabular part.
Function GetStructureForFillingInPurchasePriceInTSLine(Object, NameOfPriceTypeField = Undefined) Export
	
	PriceFillingStructure = New Structure(
		"Terms, Partner, Date, Organization, Currency,
		|VATTaxation, ToReturnReusablePackage,
		|Partner, Date, Currency, VendorPriceKind");
	
	FillPropertyValues(PriceFillingStructure,Object);
	
	PriceFillingStructure.Insert("UseAgreementFromTable", False);
	PriceFillingStructure.Insert("PriceIncludesVAT", Undefined);
	
	If NameOfPriceTypeField <> Undefined Then
		PriceFillingStructure.VendorPriceKind = Object[NameOfPriceTypeField];
	EndIf;

	// We leave it only for documents that have the type of the supplier in the header and filled in
	If Not ValueIsFilled(PriceFillingStructure.VendorPriceKind) Then
		PriceFillingStructure.Delete("VendorPriceKind");
	EndIf;
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing the fields of values used to fill in sales conditions in the rows of the table part 
// of the document.
// 
// Parameters:
//	Object - FormDataStructure - Document data.
//
// Returns:
//	Structure - the structure used to fill in the sales conditions in the rows of the tabular part of the document:
//		* Date - Date - document date.
//		* Currency - CatalogRef.Currencies - the currency of the document.
//		* Terms - CatalogRef.TermsOfSale - agreement on the document.
//		* Partner - CatalogRef.Partners - partner for the document.
//		* Contract - CatalogRef.CounterpartyContracts - Contract for the document.
//		* Ref - DocumentRef - document link.
//		* ThisIsSaleToEndCustomer - Boolean - Determines the type of price used from the commission Contract 2.5.
//
Function GetStructureForFillingInSalesConditionsInTSLine(Object) Export
	
	TypesOfSalesDocumentsToFinalBuyer = New Array;
	TypesOfSalesDocumentsToFinalBuyer.Add(Type("DocumentRef.CustomerInvoice"));
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Ref");
	ReturnValue.Insert("Date");
	ReturnValue.Insert("Currency");
	ReturnValue.Insert("Partner");
	ReturnValue.Insert("Terms");
	ReturnValue.Insert("Contract");
	
	ThisIsSaleToEndCustomer = TypesOfSalesDocumentsToFinalBuyer.Find(TypeOf(Object.Ref)) <> Undefined;
	
	ReturnValue.Insert("ThisIsSaleToEndCustomer", ThisIsSaleToEndCustomer);
	
	FillPropertyValues(ReturnValue, Object);
	
	Return ReturnValue;
	
EndFunction

// Returns a structure containing the fields of values used to fill in retail prices in the rows of the table part 
// of the document.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//
// Returns:
//	Structure - the structure used to fill in retail prices in the rows of the tabular part of the document:
//		* Date - Date - document date.
//		* Currency - CatalogRef.Currencies - the currency of the document.
//		* PriceKind - CatalogRef.TypesOfPrices - type of prices for the document.
//
Function GetStructureOfFillingInRetailPriceInTSLine(Object) Export
	
	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("Date",    Object.Date);
	PriceFillingStructure.Insert("Currency",  Object.Currency);
	PriceFillingStructure.Insert("PriceKind", Object.PriceKind);
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing the fields of values used to fill in prices for the assortment in the rows of the table 
// part of the document.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//
// Returns:
//	Structure - the structure used to fill in prices by assortment in the rows of the tabular part of the document:
//		* Date - Date - document date.
//		* Currency - CatalogRef.Currencies - the currency of the document.
//		* Warehouse - CatalogRef.Warehouses - the warehouse on the document.
//
Function GetStructureOfFillingInPriceByAssortmentInTSLine(Object) Export
	
	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("Date",    Object.Date);
	PriceFillingStructure.Insert("Currency",  Object.Currency);
	PriceFillingStructure.Insert("Warehouse", 	Object.Warehouse);
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing the fields of values used to fill in prices for the assortment in the rows of the table 
// part of the document.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//	ObjectForStoringSalesTermsAndConditions - String, CatalogRef.StoreFormats, CatalogRef.Warehouses - 
//
// Returns:
//	Structure - the structure used to fill in prices by assortment in the rows of the tabular part of the document:
//		* Date - Date - document date.
//		* Currency - CatalogRef.Currencies - the currency of the document.
//		* ObjectForStoringSalesTermsAndConditions - String, CatalogRef.StoreFormats, CatalogRef.Warehouses -
//
Function GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions) Export
	
	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("Date", Object.Date);
	PriceFillingStructure.Insert("Currency", Object.Currency);
	PriceFillingStructure.Insert("ObjectForStoringSalesTermsAndConditions", ObjectForStoringSalesTermsAndConditions);
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing fields of values used to recalculate the sales discount price in the rows
//  of the table part of the document.
//
// Parameters:
//  Object				 - FormDataStructure - Document data.
//  DiscountsAreNotUsed - Boolean				- True if the document does not use discounts. 
//  QuantityName		 - String				- name of the quantity field in the table part of the document.
// 
// Returns:
//  Structure - the structure used to recalculate the Sale discount price in the rows of the tabular part of the document:
//  * UseManualDiscounts - Boolean - The truth is in the sales, calculation of discounts is carried out manually.
//  * UseAutomaticDiscounts - Boolean - The truth is if sales are used in the automatic calculation of discounts.
//  * UseBonusPoints - Boolean - True if bonus points are used in sales.
//  * QuantityName - String - name of the quantity field in the table part of the document.
//
Function GetStructureForRecalculatingDiscountPriceInWHSales(Object, DiscountsAreNotUsed = False, QuantityName = "NumberOfPackages") Export
	
	PriceFillingStructure = New Structure;
	
	If Not DiscountsAreNotUsed Then
		PriceFillingStructure.Insert("UseManualDiscounts");
		PriceFillingStructure.Insert("UseAutomaticDiscounts");
		PriceFillingStructure.Insert("UseBonusPoints");
	EndIf;
	
	PriceFillingStructure.Insert("QuantityName", QuantityName);
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing fields of values used to recalculate the purchase discount price in the rows
//  of the table part of the document.
//
// Parameters:
//  Object			 - FormDataStructure	 - Document data.
//  ConsignmentProcurement	 - Boolean				 - True if the Commission is accepted.
// 
// Returns:
//  Structure - the structure used to recalculate the purchase discount price in the rows of the tabular part of the document:
//  * UseManualDiscounts - Boolean - True if the discount calculation is carried out manually.
//
Function GetStructureForRecalculatingDiscountPriceInVHFPurchases(Object, ConsignmentProcurement) Export
	
	PriceFillingStructure = New Structure;
	
	If Not ConsignmentProcurement Then
		PriceFillingStructure.Insert("UseManualDiscounts");
	EndIf;
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing the fields of values used to check the matched supplier's
//  item with the warehouse item in the rows of the table part of the document.
//
// Parameters:
//  Object - FormDataStructure - Document data:
//  	* Ref - DocumentRef
//  DoNotPerformValidationForUser - Boolean - True if you don't need to check for the current user.
// 
// Returns:
//  Structure - the structure used to check the matched supplier's nomenclature with the warehouse's nomenclature in the rows of the tabular part of the document:
//  * Ref - DocumentRef - link to the document.
//  * Partner - CatalogRef.Partners - partner for the document.
//  * DoNotPerformValidationForUser - Boolean - True if no verification is performed for the current user.
//
Function GetValidationStructureOfMatchedSupplierProductInTSLine(Object, DoNotPerformValidationForUser) Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Ref",                             Object.Ref);
	ParametersStructure.Insert("Partner",                            Object.Partner);
	ParametersStructure.Insert("DoNotPerformValidationForUser", DoNotPerformValidationForUser);
	
	Return ParametersStructure;
	
EndFunction

// Returns a structure containing fields of values used to fill in information about the warehouse in the rows
//  of the table part of the document.
// 
// Parameters:
// 	Object - FormDataStructure	 - Document data.
// 	WarehouseGroup_ - Boolean - True if the warehouse is hierarchical.
// 	NameOfObjectWarehouseField - String
// 	WarehouseFieldName - String
//  NameOfChargeToExpensesField - String
// 	
// Returns:
// 	Structure - LongDesc:
// * WarehouseFieldName - String
// * DefaultWarehouse - CatalogRef.Warehouses
// * WarehouseGroup_ - Boolean
// * WarehouseGroupLink - CatalogRef.Warehouses
// * NameOfChargeToExpensesField - String
//
Function GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_, NameOfObjectWarehouseField = "Warehouse", WarehouseFieldName = "Warehouse", NameOfChargeToExpensesField = "") Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("WarehouseFieldName",            WarehouseFieldName);
	ParametersStructure.Insert("DefaultWarehouse",        Object[NameOfObjectWarehouseField]);
	ParametersStructure.Insert("WarehouseGroup_",             WarehouseGroup_);
	ParametersStructure.Insert("NameOfChargeToExpensesField", NameOfChargeToExpensesField);
	
	ParametersStructure.Insert(
		"WarehouseGroupLink",
		?(WarehouseGroup_, Object[NameOfObjectWarehouseField], PredefinedValue("Catalog.Warehouses.EmptyRef")));
	
	Return ParametersStructure;
	
EndFunction

// Returns a structure containing fields of values used to fill in information about services in the rows
//  of the table part of the document.
//
// Parameters:
//  Object					 - FormDataStructure	 - Document data.
//  FillInForAllServices	 - Boolean				 - If True, then fill in information about services in the entire tabular part of the document.
// 
// Returns:
//  Structure - the structure used to fill in information about services in the rows of the tabular part of the document:
//  * FillInForAllServices - Boolean - True - fill in information about services in the entire tabular part of the document.
//  * ProcessingServicesOfTollFreeRawMaterials - Boolean - Truth - provides services for processing
//  raw materials.
//
Function GetStructureOfFillingInServiceContentInTSLine(Object, FillInForAllServices) Export
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("FillInForAllServices", FillInForAllServices);
	If Object.Property("BusinessOperation")
		 And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5")) Then
		ParametersStructure.Insert("ProcessingServicesOfTollFreeRawMaterials", True);
	EndIf;
	Return ParametersStructure;
	
EndFunction

// Returns a structure containing fields of values used to recalculate the VAT amount for the product in the rows
//  of the table part of the document.
//
// Parameters:
//  Object	 - FormDataStructure	 - Document data.
// 
// Returns:
//  Structure - the structure used to recalculate the VAT amount for the product in the rows of the tabular part of the document:
//		* PriceIncludesVAT - Boolean - True-the VAT amount is included in the product price.
//		* VATTaxation - EnumRef.VATTaxationTypes - Taxation of the document.
//
Function ParametersForRecalculatingNDSWTCHAmount(Object) Export
	
	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	If CommonClientServer.HasAttributeOrObjectProperty(Object,"VATTaxation") Then
		PriceFillingStructure.Insert("VATTaxation", Object.VATTaxation);
	EndIf;
	
	Return PriceFillingStructure;
	
EndFunction

// Returns a structure containing the fields of values used to fill in the VAT rate in the rows 
// of the table part of the document.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//
// Returns:
//	Structure - the structure used to fill in the VAT rate in the rows of the tabular part of the document:
//		* Date - Date - document date.
//		* Organization - CatalogRef.Companies - the organization that performs the business operation according to the document.
//
Function GetStructureForFillingInVATRate(Object) Export
	
	Result = New Structure;
	Result.Insert("Date"       , Object.Date);
	Result.Insert("Organization", Object.Organization);
	
	Return Result;
	
EndFunction

// Returns a structure containing the fields of values used to fill in the identification attributes of irrevocable
//  multi-turn containers in the rows of the table part of the document.
//
// Parameters:
//  Object	 - FormDataStructure	 - Document data:
//	 * ToReturnReusablePackage - Boolean - True - to return multi-turn containers.
// 
// Returns:
//  Structure - the structure used to fill in the identification signs of irrevocable multi-turn containers in
//  the rows of the tabular part of the document:
//  * ToReturnReusablePackage - Boolean - True - to return multi-turn containers.
//
Function GetFeatureFillingStructureWithoutReturnableTare(Object) Export
	
	Result = New Structure;
	Result.Insert("ToReturnReusablePackage" , Object.ToReturnReusablePackage);
	
	Return Result;
	
EndFunction

// Returns the parameters used when filling in the country of origin of the item in the tabular part of the object.
//
// Returns:
//	Structure - a collection containing the following properties:
//		* Products - String - the name of the nomenclature field of the tabular part of the object.
//		* CCDNumber - String - the name of the GTD product number field of the tabular part of the object.
//
Function CountryOfOriginFillingParameters() Export
	
	CountryOfOriginFillingParameters = New Structure;
	CountryOfOriginFillingParameters.Insert("Products",	"Products");
	CountryOfOriginFillingParameters.Insert("CCDNumber",		"CCDNumber");
	
	Return CountryOfOriginFillingParameters;
	
EndFunction

// Returns a structure containing parameters for filling in the excisable item attribute
// of the document.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject - Document data.
//
// Returns:
//	Structure - the structure used to recalculate VAT amounts in the tabular part of the document:
//		* Organization - CatalogRef.Companies - Organization of the document
//		* Date - Date - Document date
//
Function ParametersForFillingInExcisableItemAttribute(Object) Export
	
	Parameters = New Structure;
	Parameters.Insert("Organization", Object.Organization);
	Parameters.Insert("Date", Object.Date);
	
	Return Parameters;
	
EndFunction

// Returns a structure containing parameters for recalculating the excise tax amount in the rows of the tabular part of the document.
//
// Parameters:
//	Object - FormDataStructure, DocumentObject - Document data.
//	RatePerUnitOfStorage - Boolean - Indicates that the bid should be received per item storage unit.
//
// Returns:
//	Structure - the structure used to recalculate the excise tax amount in the rows of the tabular part of the document:
//		* Date - Date - document date.
//		* Organization - CatalogRef.Companies - the organization that performs the business operation according to the document.
//		* RatePerUnitOfStorage - Boolean - indicates whether the excise tax rate is received per item storage unit.
//		* FieldNameQuantity - String - the name of the quantity field in the tabular part of the document.
//
Function ParametersForRecalculationOfExciseTaxAmount(Object = Undefined, RatePerUnitOfStorage = False) Export
	
	Parameters = New Structure;
	Parameters.Insert("Date");
	Parameters.Insert("Organization");
	Parameters.Insert("RatePerUnitOfStorage", RatePerUnitOfStorage);
	Parameters.Insert("FieldNameQuantity", "Count");
	
	If Object <> Undefined Then
		
		Parameters.Date = Object.Date;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "Organization") Then
			Parameters.Organization = Object.Organization;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Parameters.Date) Then
		Parameters.Date = GeneralPurposeTMServerCall.SessionDate();
	EndIf;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region RecalculationAndFillingProceduresClientServer

// Fills in the fields that are used to reflect discrepancies in the current row of the table 
// part of the document "Actorextensionsreferences".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInTheDiscrepancies(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If Not StructureOfActions.Property("RecalculateDiscrepancies") Then
		
		Return;
		
	EndIf;
	
	CurrentRow.NumberOfDiscrepancyPackaging = CurrentRow.NumberOfPackages - CurrentRow.NumberOfPackagesByDocument;
	CurrentRow.ThereAreDiscrepancies               = (CurrentRow.NumberOfDiscrepancyPackaging <> 0);
	
	If CurrentRow.NumberOfDiscrepancyPackaging = 0 Then
		CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging < 0 
		And (CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration")) Then
		
		CurrentRow.Action    = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging > 0 
		And (CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow")) Then
		
		CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		
	EndIf;
	
EndProcedure

// Fills in the fields used to reflect discrepancies in the current row of the table 
// part of the document "actoraccounts after Loading".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillDiscrepanciesAfterShipment(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If Not StructureOfActions.Property("RecalculateDiscrepanciesAfterShipment") Then
		
		Return;
		
	EndIf;
	
	FillInDiscrepanciesInActLine(CurrentRow);
	
	If CurrentRow.NumberOfDiscrepancyPackaging = 0 Then
		CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging < 0 
		And (CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration")) Then
		
		CurrentRow.Action    = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging > 0 
		And (CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow")) Then
		
		CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		
	EndIf;
	
	If CurrentRow.NumberOfDiscrepancyPackaging = 0 Then
		CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.EmptyRef");
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging < 0
		And CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit") Then
		
		CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging > 0
		And (CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off")
		Or CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit")
		Or CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReturnValue_")
		Or CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait")) Then
		
		CurrentRow.DiscrepancyTreatment = PredefinedValue("Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.EmptyRef");
		
	EndIf;
	
EndProcedure

// Fills in the fields that are used to reflect discrepancies in the current row of the table 
// part of the document "actorreferences after Acceptance".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInDiscrepanciesAfterAcceptance(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If Not StructureOfActions.Property("RecalculateDiscrepanciesAfterAcceptance") Then
		
		Return;
		
	EndIf;
	
	FillInDiscrepanciesInActLine(CurrentRow);
	
	If CurrentRow.NumberOfDiscrepancyPackaging = 0 Then
		CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef");
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging > 0 
		And (CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices")) Then
		
		CurrentRow.Action    = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef");
		CurrentRow.ThirdPartyIsGuilty = False;
		
	ElsIf CurrentRow.NumberOfDiscrepancyPackaging < 0 
		And (CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered")
		Or CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered")) Then
		
		CurrentRow.Action = PredefinedValue("Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.EmptyRef");
		
	EndIf;
	
EndProcedure

// Fills in the fields for signs of using comments in the current row of the table 
// part of the document "Actorextensionsreferences".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInAcceptanceCommentFlag(CurrentRow, StructureOfActions, CachedValues = Undefined) Export

	If Not StructureOfActions.Property("FlagForAcceptanceComment") Then
		
		Return;
		
	EndIf;
	
	CurrentRow.ThereIsSupplierComment = Not IsBlankString(CurrentRow.VendorSComment);
	CurrentRow.ThereIsAManagerComment = Not IsBlankString(CurrentRow.ManagerComment);

EndProcedure

// Fills in the fields for signs of using comments in the current row of the table 
// part of the document "actorextensions after Loading".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInSignForShipmentComment(CurrentRow, StructureOfActions, CachedValues = Undefined) Export

	If Not StructureOfActions.Property("FlagForShipmentComment") Then
		
		Return;
		
	EndIf;
	
	CurrentRow.ThereIsACustomerComment = Not IsBlankString(CurrentRow.CustomerComment);
	CurrentRow.ThereIsAManagerComment = Not IsBlankString(CurrentRow.ManagerComment);

EndProcedure

// Fills in the fields for signs of using comments in the current row of the table 
// part of the document "Actorextensionsreferences".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInFlagForComments(CurrentRow, StructureOfActions, CachedValues = Undefined) Export

	If Not StructureOfActions.Property("FlagForComment") Then
		
		Return;
		
	EndIf;
	
	CurrentRow.ThereIsACommentFromRecipient = Not IsBlankString(CurrentRow.RecipientComment);
	CurrentRow.ThereIsAManagerComment = Not IsBlankString(CurrentRow.ManagerComment);

EndProcedure

// Fills in the flag for processing the row in the table part of the document "incoming orders".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInItemLocationAttributeProcessingRequired(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If Not StructureOfActions.Property("FillInPlaceAttributeThatRequiresProcessing") Then
		Return;
	EndIf;
	
	If Not IsBlankString(CurrentRow.Barcode)
			And CurrentRow.BarcodeIsNotRecognized
			And (CurrentRow.ThisIsAPackingList And Not ValueIsFilled(CurrentRow.PackingList)
				Or Not CurrentRow.ThisIsAPackingList And Not ValueIsFilled(CurrentRow.Products))
		Or CurrentRow.ThisIsAPackingList
			And CurrentRow.NumberOfCompletedSubordinatePositions = 0
		Or CurrentRow.ThisIsInternalRowOfEmptyPackingList Then
		CurrentRow.DataProcessorIsRequired = 1;
	Else
		CurrentRow.DataProcessorIsRequired = 0;
	EndIf;
	
EndProcedure

// Returns a structure containing fields for recalculating the amount in the table part of the document.
//
// Parameters:
//  Attributes - String - Contains comma-separated field names,
//  FieldNameQuantity     - String - Name of the field used for calculating the proportionality coefficient.
//  RoundingBits - Structure - structure, in the format Field name => Number of fractional characters to be
//                                      used when recalculating Attributes.
//
// Returns:
//  Structure:
//            * Fields - Structure - contains fields for recalculating the amount in the table part of the document
//            * Rows - Array of FormDataCollectionItem - contains elements of the type, links, and lines for recalculating amounts.
//            * Total_Quantity - Number - the sum of the values in the "Quantity" field in the rows passed in the "Rows" parameter"
//            * FieldNameQuantity - String
//            * RoundingBits - Structure
//
Function StructureOfRecalculationOfAmount(Attributes, FieldNameQuantity = "Count", RoundingBits = Undefined) Export

	Fields = New Structure(Attributes);
	
	Result = New Structure;
	Result.Insert("Fields", Fields);
	Result.Insert("Rows", New Array());
	Result.Insert("Total_Quantity", 0);
	Result.Insert("FieldNameQuantity", FieldNameQuantity);
	Result.Insert("RoundingBits", RoundingBits);

	Return Result;

EndFunction

// Initializes the structure for recalculating the amount in the table part of the document
//
// Parameters:
//  StructureOfRecalculationOfAmount - See StructureOfRecalculationOfAmount.
//  FillingData - FormDataCollectionItem - a row containing the values of the sum indicators
//                     that will need to be distributed between the rows when recalculating the amounts.
//
// Return value
//  Structure - A structure with the following fields:
//              Fields - Structure - contains fields for recalculating the amount in the tabular part of the document,
//              Rows - Array - contains elements of the data formelementcollection type, links to rows for recalculating amounts,
//              The total Quantity is a number - the sum of the values in the "Quantity" field in the lines passed in the "Lines" parameter.
//
Procedure FillInStructureForRecalculatingAmount(StructureOfRecalculationOfAmount, FillingData) Export

	FillPropertyValues(StructureOfRecalculationOfAmount.Fields, FillingData);

	StructureOfRecalculationOfAmount.Total_Quantity = 0;
	StructureOfRecalculationOfAmount.Rows.Clear();

EndProcedure

// Adds a line for recalculating the amount to the structure for recalculating the amount. For the description, see function
// The structure of the sum count.
//
// Parameters:
//  StructureOfRecalculationOfAmount - See StructureOfRecalculationOfAmount
//  String - FormDataCollectionItem - the string to calculate the sum values for.
//
Procedure AddLineToRecalculateAmount(StructureOfRecalculationOfAmount, String) Export

	StructureOfRecalculationOfAmount.Rows.Add(String);
	StructureOfRecalculationOfAmount.Total_Quantity = StructureOfRecalculationOfAmount.Total_Quantity + String[StructureOfRecalculationOfAmount.FieldNameQuantity];

EndProcedure

// Recalculates the amounts in the rows added to the structure for recalculating the amount. For the description, see the function
// The structure of the sum count.
//
// Parameters:
//  StructureOfRecalculationOfAmount - See StructureOfRecalculationOfAmount
//
Procedure RecalculateAmounts(StructureOfRecalculationOfAmount) Export
	
	RoundingBits = Undefined;
	If StructureOfRecalculationOfAmount.Property("RoundingBits") Then
		RoundingBits = StructureOfRecalculationOfAmount.RoundingBits;
	EndIf;
	
	For Each String In StructureOfRecalculationOfAmount.Rows Do
		
		If StructureOfRecalculationOfAmount.Total_Quantity = 0 Then
			Continue;
		EndIf;
		
		ZoomRatio = String[StructureOfRecalculationOfAmount.FieldNameQuantity] / StructureOfRecalculationOfAmount.Total_Quantity;
		StructureOfRecalculationOfAmount.Total_Quantity = StructureOfRecalculationOfAmount.Total_Quantity - String[StructureOfRecalculationOfAmount.FieldNameQuantity];

		For Each Field In StructureOfRecalculationOfAmount.Fields Do
			
			NewValue = Field.Value * ZoomRatio;
			
			If RoundingBits <> Undefined Then
				String[Field.Key] = Round(NewValue, RoundingBits[Field.Key]);
			Else
				String[Field.Key] = NewValue;
			EndIf;
			
			StructureOfRecalculationOfAmount.Fields[Field.Key] = Field.Value - String[Field.Key];

		EndDo;

	EndDo;

EndProcedure

// Recalculates the number of unloaded product packages in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateQuantityDoNotShipToTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("RecalculateQuantityDoNotShip") Then
		If CurrentRow.NumberOfPackages - CurrentRow.NumberOfPackagesDoNotShip > CurrentRow.NumberOfPackagesInDocument - CurrentRow.NumberOfPackagesInDocumentUnshipped Then
			CurrentRow.NumberOfPackagesDoNotShip = CurrentRow.NumberOfPackages - (CurrentRow.NumberOfPackagesInDocument - CurrentRow.NumberOfPackagesInDocumentUnshipped);
		ElsIf CurrentRow.NumberOfPackagesDoNotShip > CurrentRow.NumberOfPackages Then
			CurrentRow.NumberOfPackagesDoNotShip = CurrentRow.NumberOfPackages;
		EndIf;
	EndIf;
	
EndProcedure

// Recalculates the Attributes in the changed lines. 
// 
// Parameters:
//  ModifiedRows - Array of Structure:
//  * Id - Number - ID of the group of modified rows,
//  * String - FormDataCollectionItem,LineOfATabularSection - the line to recalculate.
//  StructureOfRecalculation - See StructureOfRecalculationOfAmount.
//
Procedure RecalculateBankingDetailsInChangedLines(ModifiedRows, StructureOfRecalculation) Export
	
	Id = Undefined;
	For Each Update In ModifiedRows Do
		If Id <> Update.Id Then
			Id = Update.Id;
			RecalculateAmounts(StructureOfRecalculation);
			FillInStructureForRecalculatingAmount(StructureOfRecalculation, Update.String);
		EndIf;
		AddLineToRecalculateAmount(StructureOfRecalculation, Update.String);
	EndDo;
	RecalculateAmounts(StructureOfRecalculation);
	
EndProcedure

// Calculates the number of packages of goods in the Cur row of the tabular part of the document
// using the formula: Sold = Balance (accounting) - Balance (fact).
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfPackagesAfterFactInTSLine(CurrentRow, StructureOfActions, CachedValues) Export 

	If StructureOfActions.Property("RecalculateNumberOfPackagesAfterFact") Then
		CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesAccounting - CurrentRow.NumberOfPackagesReal;
	EndIf;

EndProcedure

// Calculates the actual number of packages of goods in the Cur row of the tabular part of the document
// using the formula: Balance (fact) = Balance (accounting) - Sold.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfPackagesFactByPackagesInPMLine(CurrentRow, StructureOfActions, CachedValues) Export 

	If StructureOfActions.Property("RecalculateNumberOfPackagesFactByPackages") Then
		
		CurrentRow.NumberOfPackagesReal = CurrentRow.NumberOfPackagesAccounting - CurrentRow.NumberOfPackages;
		
	EndIf;

EndProcedure

// Recalculates the quantity of the product (in storage units) in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfUnitsInTSString(CurrentRow, StructureOfActions, CachedValues) Export 

	Var PackagingProducts;
	
	If StructureOfActions.Property("RecalculateNumberOfUnits", PackagingProducts) Then
		RecalculationParameters = NormalizeUnitConversionParameters(CurrentRow, PackagingProducts);
		If ValueIsFilled(RecalculationParameters.Products) Then
			PackageData = GetPackingRatio(RecalculationParameters.Package, CachedValues, RecalculationParameters.Products);
			Count = CurrentRow.NumberOfPackages * PackageData.ZoomRatio;
		
			If PackageData.NeedToRoundUpQuantity
				And RecalculationParameters.MustBeRoundOff Then
				CurrentRow.Count = Round(Count, 0 ,RoundMode.Round15as20);
			Else
				CurrentRow.Count = Count;
			EndIf;
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "NumberOfPackages") Then
			CurrentRow.Count = CurrentRow.NumberOfPackages;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the column "Quantity by RNPT" in the Cur line. The calculation is based on:
// 1. The value of the column "Quantity".
// 2. Conversion factor, which is calculated in the context of:
//		A. Organization.
//		B. Analysis of inventory items: Nomenclature, Characteristics, Warehouse (Storage location).
//		B. CCD number (RNPT).
// According to the specified section, entries are searched in:
//		A. RN Goods of the organization,
//		B. RN Goods transferred to the commission,
//		B. RN Goods for the preparation of reports to the committee,
//		G. RN Goods for the preparation of reports to the committee on purchases.
// The calculation is performed on the found records:
// Coefficient = Quantity / Quantity;
// If there is no record, and /or the CCD Number (RNPT) is passed empty, the coefficient is set to "1",
// i.e. "Quantity according to RNPT" is equated to "Quantity".
//
// Typical scenario:
// 10 pieces of goods were received, the user indicated the CCD number (RNPT)
// and changed the value in the "Quantity according to RNPT" field from 10 to 20.
// The user enters the following document with the same product and CCD (RNPT), enters the quantity.
// The system has read from memory that the coefficient = 2, and automatically sets
// the value in the column "Quantity according to RNPT" as "Quantity" * 2.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateQuantityByRNPTVAndTS(CurrentRow, StructureOfActions, CachedValues) Export 

	Var RecalculationParameters;
	
	If StructureOfActions.Property("RecalculateQuantityByRNPT", RecalculationParameters) Then
		
		FieldNameQuantity = "Count";
		NameOfQuantityFieldAccordingToRNPT = "QuantityByGBRN";
		If RecalculationParameters.Property("FieldNamesWithSuffix")
			And ValueIsFilled(RecalculationParameters.FieldNamesWithSuffix) Then
			
			If RecalculationParameters.FieldNamesWithSuffix.Property("Count") Then
				FieldNameQuantity = RecalculationParameters.FieldNamesWithSuffix.Count;
			EndIf;
			If RecalculationParameters.FieldNamesWithSuffix.Property("QuantityByGBRN") Then
				NameOfQuantityFieldAccordingToRNPT = RecalculationParameters.FieldNamesWithSuffix.QuantityByGBRN;
			EndIf;
			
		EndIf;
		
		If CurrentRow.AccountingForTheRNPTIsMaintained Then
			If StructureOfActions.Property("FillInCCDNumberType") Then
				If CurrentRow.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
					CurrentRow[NameOfQuantityFieldAccordingToRNPT] = CurrentRow[FieldNameQuantity];
				EndIf;
			Else
				ZoomRatio = GetRnptCoefficient(RecalculationParameters, CurrentRow, CachedValues);
				
				CurrentRow[NameOfQuantityFieldAccordingToRNPT] = CurrentRow[FieldNameQuantity] * ZoomRatio;
			EndIf;
		Else
			CurrentRow[NameOfQuantityFieldAccordingToRNPT] = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the column "Quantity according to RNPT" (another column name is supported) in the Cur line.
// The calculation is based on:
// 1. The value of the column "Quantity" (another column name is supported).
// 2. Conversion factor, which is calculated in the context of:
//		A. Organization.
//		B. Analysis of inventory items: Nomenclature, Characteristics, Warehouse (Storage location).
//		B. CCD number (RNPT).
// According to the specified section, entries are searched in:
//		A. RN Goods of the organization,
//		B. RN Goods transferred to the commission,
//		B. RN Goods for the preparation of reports to the committee,
//		G. RN Goods for the preparation of reports to the committee on purchases.
// The calculation is performed on the found records:
// Coefficient = Quantity / Quantity;
// If there is no record, and /or the CCD Number (RNPT) is passed empty, the coefficient is set to "1",
// i.e. "Quantity according to RNPT" is equated to "Quantity".
//
// Typical scenario:
// 10 pieces of goods were received, the user indicated the CCD number (RNPT)
// and changed the value in the "Quantity according to RNPT" field from 10 to 20.
// The user enters the following document with the same product and CCD (RNPT), enters the quantity.
// The system has read from memory that the coefficient = 2, and automatically sets
// the value in the column "Quantity according to RNPT" as "Quantity" * 2.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - Structure - Cached value.
//
Procedure RecalculateQuantityByRnptSuffixInTSLine(CurrentRow, StructureOfActions, CachedValues) Export 

	Var RecalculationParameters;
	
	If StructureOfActions.Property("RecalculateQuantityByRNPTSuffix", RecalculationParameters) Then
		
		FieldNameQuantity = "Count";
		NameOfQuantityFieldAccordingToRNPT = "QuantityByGBRN";
		If RecalculationParameters.Property("FieldNamesWithSuffix")
			And ValueIsFilled(RecalculationParameters.FieldNamesWithSuffix) Then
			
			If RecalculationParameters.FieldNamesWithSuffix.Property("Count") Then
				FieldNameQuantity = RecalculationParameters.FieldNamesWithSuffix.Count;
			EndIf;
			If RecalculationParameters.FieldNamesWithSuffix.Property("QuantityByGBRN") Then
				NameOfQuantityFieldAccordingToRNPT = RecalculationParameters.FieldNamesWithSuffix.QuantityByGBRN;
			EndIf;
			
		EndIf;
		
		If CurrentRow.AccountingForTheRNPTIsMaintained Then
			If StructureOfActions.Property("FillInCCDNumberType") Then
				If CurrentRow.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
					CurrentRow[NameOfQuantityFieldAccordingToRNPT] = CurrentRow[FieldNameQuantity];
				EndIf;
			Else
				ZoomRatio = GetRnptCoefficient(RecalculationParameters, CurrentRow, CachedValues);
				
				CurrentRow[NameOfQuantityFieldAccordingToRNPT] = CurrentRow[FieldNameQuantity] * ZoomRatio;
			EndIf;
		Else
			CurrentRow[NameOfQuantityFieldAccordingToRNPT] = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

// Recalculates the quantity of the item (in storage units) that has the specified attribute in the current row of the table 
// part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfSuffixUnitsInTSString(CurrentRow, StructureOfActions, CachedValues) Export

	Var SuffixRecalculationParameters;
	
	If StructureOfActions.Property("RecalculateNumberOfSuffixUnits", SuffixRecalculationParameters) Then
		
		RecalculationParameters = NormalizeUnitConversionParametersSuffix(CurrentRow, SuffixRecalculationParameters);
		QuantityWithSuffix = QuantityWithSuffix(RecalculationParameters.Suffix);
		If ValueIsFilled(CurrentRow.Products) Then
			PackageData = GetPackingRatio(CurrentRow.Package, CachedValues, CurrentRow.Products);
			Count = CurrentRow[QuantityWithSuffix.NumberOfPackages] * PackageData.ZoomRatio;
			
			If PackageData.NeedToRoundUpQuantity
				And RecalculationParameters.MustBeRoundOff Then
				CurrentRow[QuantityWithSuffix.Count] = Round(Count, 0 ,RoundMode.Round15as20);
			Else
				CurrentRow[QuantityWithSuffix.Count] = Count;
			EndIf;
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, QuantityWithSuffix.NumberOfPackages) Then
			CurrentRow[QuantityWithSuffix.Count] = CurrentRow[QuantityWithSuffix.NumberOfPackages];
		EndIf;
		
	EndIf;

EndProcedure

// Recalculates the number of product packages in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfPackagesInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("RecalculateNumberOfPackages") Then
		If CurrentRow.Count = 0 Then
			CurrentRow.NumberOfPackages = 0;
		Else
			ZoomRatio = GetPackingRatio(CurrentRow.Package, CachedValues, CurrentRow.Products).ZoomRatio;
			If ZoomRatio <> 0 Then
				CurrentRow.NumberOfPackages = CurrentRow.Count / ZoomRatio;
			Else
				ExceptionText = NStr("vi = 'Khi cố gắng tính toán lại số lượng theo %UnitOfMeasurement% dung lượng bit cho phép bị vượt quá.';
									|ru = 'При попытке пересчета количества в %UnitOfMeasurement% превышена допустимая разрядность.';
									|en = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.'; fa = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.';
									|it = 'Durante il tentativo di ricalcolo della quantità di %UnitOfMeasurement%  si è verificato il superamento della capacità di cifre consentita.';
									|pl = 'Podczas próby przeliczenia ilości w %UnitOfMeasurement% została przekroczona dopuszczalna ilość pozycji.';
									|tr = 'Miktarı %UnitOfMeasurement%''a dönüştürmeye çalışırken, izin verilen bit genişliği kapasitesi aşıldı.'");
				ExceptionText = StrReplace(ExceptionText, "%UnitOfMeasurement%", CurrentRow.Package);
				
				CurrentRow.Count = 0;
				CurrentRow.NumberOfPackages = 0;
				CurrentRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
				
				Raise ExceptionText;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

// Recalculates the number of packages of the product that has the specified attribute in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfSuffixPacksInTSString(CurrentRow, StructureOfActions, CachedValues) Export 
	
	Var SuffixRecalculationParameters;
	
	If StructureOfActions.Property("RecalculateNumberOfSuffixPacks",SuffixRecalculationParameters) Then
		RecalculationParameters = NormalizeUnitConversionParametersSuffix(CurrentRow, SuffixRecalculationParameters);
		QuantityWithSuffix = QuantityWithSuffix(RecalculationParameters.Suffix);
		If CurrentRow[QuantityWithSuffix.Count] = 0 Then
			CurrentRow[QuantityWithSuffix.NumberOfPackages] = 0;
		Else
			ZoomRatio = GetPackingRatio(CurrentRow.Package, CachedValues, CurrentRow.Products).ZoomRatio;
			If ZoomRatio <> 0 Then
				CurrentRow[QuantityWithSuffix.NumberOfPackages] = CurrentRow[QuantityWithSuffix.Count] / ZoomRatio;
			Else
				ExceptionText = NStr("vi = 'Khi cố gắng tính toán lại số lượng theo %UnitOfMeasurement% dung lượng bit cho phép bị vượt quá.';
									|ru = 'При попытке пересчета количества в %UnitOfMeasurement% превышена допустимая разрядность.';
									|en = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.'; fa = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.';
									|it = 'Durante il tentativo di ricalcolo della quantità di %UnitOfMeasurement%  si è verificato il superamento della capacità di cifre consentita.';
									|pl = 'Podczas próby przeliczenia ilości w %UnitOfMeasurement% została przekroczona dopuszczalna ilość pozycji.';
									|tr = 'Miktarı %UnitOfMeasurement%''a dönüştürmeye çalışırken, izin verilen bit genişliği kapasitesi aşıldı.'");
				ExceptionText = StrReplace(ExceptionText, "%UnitOfMeasurement%", CurrentRow.Package);
				
				CurrentRow[QuantityWithSuffix.Count] = 0;
				CurrentRow[QuantityWithSuffix.NumberOfPackages] = 0;
				CurrentRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
				
				Raise ExceptionText;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Recalculates deviations by the number of product packages in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountOfDeviation(CurrentRow, StructureOfActions, CachedValues) Export 

	Var ThereArePackages;
	
	If StructureOfActions.Property("RecalculateAmountOfDeviation", ThereArePackages) Then
		CurrentRow.DeviationInStorageUnits = CurrentRow.CountReal - CurrentRow.Count;
		If ThereArePackages Then
			CurrentRow.NumberOfPackagesDiscrepancy = CurrentRow.NumberOfPackagesReal - CurrentRow.NumberOfPackages;
		EndIf;
	EndIf;

EndProcedure

// Recalculates deviations by the number of packages of the product that has the specified attribute in the current row 
// of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfSuffixPacksFromDeviationInTSString(CurrentRow, StructureOfActions, CachedValues = Undefined) Export 
	
	Suffix = Undefined;

	If StructureOfActions.Property("RecalculateNumberOfSuffixPacksFromDeviation",Suffix) Then
		If Suffix = Undefined Then
			Suffix = "";
		EndIf;
		CurrentRow[QuantityWithSuffix(Suffix).NumberOfPackages] = CurrentRow["NumberOfPackages"]
																		+ CurrentRow["NumberOfPackagesDiscrepancy"];
	EndIf;

EndProcedure

// Fills in the price view in the current row of the tabular part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInPriceTypeInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("FillInPriceView", StructureOfActionParameters) Then
		
		NameOfPriceTypeField = "PriceKind";
		If StructureOfActionParameters.Property("NameOfPriceTypeField") Then
			NameOfPriceTypeField = StructureOfActionParameters.NameOfPriceTypeField
		EndIf;
		
		CurrentRow[NameOfPriceTypeField] = StructureOfActionParameters.PriceKind;
		
	EndIf;
	
EndProcedure // Fill in the Price Tag()

// Recalculates the price per product package in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculatePricePerPackageInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	Var NumberOfUnitsBeforeRecalculation;

	If StructureOfActions.Property("RecalculatePricePerPackage", NumberOfUnitsBeforeRecalculation)
	   And NumberOfUnitsBeforeRecalculation <> 0 Then
		CurrentRow.Price = Round(CurrentRow.Price
		   / NumberOfUnitsBeforeRecalculation
		   * CurrentRow.Count, 2, RoundMode.Round15as20);
	EndIf;

EndProcedure

// Recalculates the price per product package in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculatePricePerPackageSuffixInLineTS(CurrentRow, StructureOfActions, CachedValues) Export

	Var RecalculationParameters;

	If StructureOfActions.Property("RecalculatePricePerPackageSuffix", RecalculationParameters) Then
		Suffix = RecalculationParameters.Suffix;
		NumberOfUnitsBeforeRecalculation = RecalculationParameters.Count;
		If NumberOfUnitsBeforeRecalculation <> 0 Then
			CurrentRow[PriceWithSuffix(Suffix)] = Round(CurrentRow[PriceWithSuffix(Suffix)]
			   / NumberOfUnitsBeforeRecalculation
			   * CurrentRow[QuantityWithSuffix(Suffix).Count], 2, RoundMode.Round15as20);
		EndIf;
	EndIf;

EndProcedure

// Recalculates the order price for product packaging in the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateOrderPricePerPackageInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	Var NumberOfUnitsBeforeRecalculation;

	If StructureOfActions.Property("RecalculateOrderPricePerPackage", NumberOfUnitsBeforeRecalculation)
	   And NumberOfUnitsBeforeRecalculation <> 0 Then
		CurrentRow.OrderPrice = Round(CurrentRow.OrderPrice
		   / NumberOfUnitsBeforeRecalculation
		   * CurrentRow.Count, 2, RoundMode.Round15as20);
	EndIf;

EndProcedure

// Fills in the value of the VAT rate of the returnable container in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInVATRateOfReturnableContainerInLineTS(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ThisIsReusablePackage;
	
	If StructureOfActions.Property("FillInVATRateForReturnableContainers", ThisIsReusablePackage)
		And ThisIsReusablePackage And CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
		CurrentRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	EndIf;
	
EndProcedure

// Recalculates the percentage of manual discount from the product price in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculatePercentageOfManualDiscountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	QuantityName = Undefined;
	
	If StructureOfActions.Property("RecalculatePercentageOfManualDiscount", QuantityName) Then
		If Not ValueIsFilled(QuantityName) Then
			QuantityName = "NumberOfPackages";
		EndIf;
		If CurrentRow[QuantityName] * CurrentRow.Price <> 0 Then
			CurrentRow.PercentRateOfManualDiscount = Round(100*CurrentRow.ManualDiscount / (CurrentRow[QuantityName] *CurrentRow.Price), 2);
		Else
			CurrentRow.PercentRateOfManualDiscount = 0;
		EndIf;
		
	EndIf;

EndProcedure

// Recalculates the amount of the manual discount for the product in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountOfManualDiscountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	QuantityName = Undefined;
		
	If StructureOfActions.Property("RecalculateAmountOfManualDiscount", QuantityName) Then
		
		If Not ValueIsFilled(QuantityName) Then
			QuantityName = "NumberOfPackages"; 
		EndIf;
			
		CurrentRow.ManualDiscount = Round(CurrentRow[QuantityName] *CurrentRow.Price * CurrentRow.PercentRateOfManualDiscount / 100, 2);
		
	EndIf;

EndProcedure

// Recalculates the product amount in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	QuantityName = Undefined;
	
	If StructureOfActions.Property("RecalculateAmount", QuantityName) Then
		If Not ValueIsFilled(QuantityName) Then
			QuantityName = "NumberOfPackages";
		EndIf;
		If CurrentRow <> Undefined Then
			CurrentRow.Sum = CurrentRow.Price * CurrentRow[QuantityName];
		EndIf;
	EndIf;

EndProcedure

// Recalculates the amount of the item that has the specified attribute in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateSumOfSuffixInTSString(CurrentRow, StructureOfActions, CachedValues) Export
	
	RecalculationParameters = Undefined;
	
	If StructureOfActions.Property("RecalculateSuffixAmount", RecalculationParameters) Then
		If TypeOf(RecalculationParameters) = Type("Structure") Then
			QuantityName = RecalculationParameters.QuantityName;
			Suffix = RecalculationParameters.Suffix;
		Else
			QuantityName = "NumberOfPackages";
			Suffix = RecalculationParameters;
		EndIf;
		If Not ValueIsFilled(Suffix) Then
			Suffix = ""
		EndIf;
		
		If CurrentRow <> Undefined Then
			CurrentRow[SumWithSuffix(Suffix).Sum] = CurrentRow[PriceWithSuffix(Suffix)] * CurrentRow[QuantityWithSuffix(Suffix)[QuantityName]];
		EndIf;
	EndIf;
	
EndProcedure

// Recalculates the amount of the item that has the specified attribute in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountOfVATSuffixInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	Var StructureOfActionParameters;
	Var VATRate;
		
	If StructureOfActions.Property("RecalculateVATAmountSuffix", StructureOfActionParameters) Then
	
		VATTaxation = Undefined;
		StructureOfActionParameters.Property("VATTaxation", VATTaxation);
		
		Suffix = "";
		
		If StructureOfActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			Suffix = "";
		EndIf;
		
		SumWithSuffix = SumWithSuffix(Suffix);
		RateWithSuffix = RateWithSuffix(Suffix);
		
		If Not (StructureOfActionParameters <> Undefined
				And StructureOfActionParameters.Property("VATRate", VATRate)) Then
			
			VATRate = CurrentRow[RateWithSuffix.VATRate];
			
		EndIf;
		
		If CachedValues.Property("PercentOfVATRates") Then
			CurPercentVAT = CachedValues.PercentOfVATRates[VATRate];
		Else
			CurPercentVAT = Undefined;
			
			CachedValues.Insert("PercentOfVATRates", New Map);
		EndIf;
		
		If CurPercentVAT = Undefined Then
			
			CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
			CachedValues.PercentOfVATRates.Insert(VATRate, CurPercentVAT);
			
		EndIf;
		
		CurrentRow[SumWithSuffix.VATAmount] = VATAccountingERPClientServer.CalculateVATAmount(
			CurrentRow[SumWithSuffix.Sum],
			CurPercentVAT,
			StructureOfActionParameters.PriceIncludesVAT,
			VATTaxation);
		
	EndIf;

EndProcedure

// Recalculates the product amount in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountInTSLineOfDiscrepancy(CurrentRow, StructureOfActions, CachedValues) Export

	If StructureOfActions.Property("RecalculateAmountOfDiscrepancy") Then
		If CurrentRow <> Undefined Then
			If CurrentRow.NumberOfPackagesByDocument = 0 Then
				CurrentRow.Sum = CurrentRow.Price * CurrentRow.NumberOfPackages;
			Else
				FractionOfDiscrepancy = CurrentRow.NumberOfPackages / CurrentRow.NumberOfPackagesByDocument;
				CurrentRow.Sum = CurrentRow.SumByDocument * FractionOfDiscrepancy;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

// Generates the names of price identifiers with the suffix
//
// Parameters:
//  Suffix - String
//
// Returns:
//  String - name of the price field.
//
Function PriceWithSuffix(Suffix) Export
	
	If Suffix = "OffBalance" Then
		NameOfPriceField = "PriceOffBalance";
	ElsIf Suffix = "After" Then
		NameOfPriceField = "PriceAfter";
	Else
		NameOfPriceField = "Price";
	EndIf;
	
	Return NameOfPriceField;
	
EndFunction

// Generates the names of the sum IDs with the suffix
// 
// Parameters:
// 	Suffix - String - Suffix
// 
// Returns:
// 	Structure - a set of ID names. Description:
// * Sum - String - "Sum" + suffix
// * VATAmount - String - "SummaNDS" + suffix
// * AmountIncludingVAT - String - "SummaSNDS" + suffix
//
Function SumWithSuffix(Suffix) Export
	
	ReturnStructure = New Structure("Sum, VATAmount, AmountIncludingVAT, AmountARAP, AmountExcludingVATCompl, AmountExcludingVATMan");
	
	If Not ValueIsFilled(Suffix) Then
		ReturnStructure.Sum = "Sum";
		ReturnStructure.VATAmount = "VATAmount";
		ReturnStructure.AmountIncludingVAT = "AmountIncludingVAT";
		ReturnStructure.AmountARAP = "AmountARAP";
		ReturnStructure.AmountExcludingVATCompl = "AmountExcludingVATCompl";
		ReturnStructure.AmountExcludingVATMan = "AmountExcludingVATMan";
	ElsIf Suffix = "ByDocument" Then
		ReturnStructure.Sum = "SumByDocument";
		ReturnStructure.VATAmount = "VATAmountByDocument";
		ReturnStructure.AmountIncludingVAT = "AmountIncludingVATByDocument";
		ReturnStructure.AmountARAP = "";
		ReturnStructure.AmountExcludingVATCompl = "";
		ReturnStructure.AmountExcludingVATMan = "";		
	ElsIf Suffix = "After" Then
		ReturnStructure.Sum = "AmountAfter";
		ReturnStructure.VATAmount = "VATAmountAfter";
		ReturnStructure.AmountIncludingVAT = "AmountWithVATAfter";
		ReturnStructure.AmountARAP = "AmountOfSettlementsAfter";
		ReturnStructure.AmountExcludingVATCompl = "VATExclusiveAmountLocalAfter";
		ReturnStructure.AmountExcludingVATMan = "VATExclusiveAmountManAfter";
	ElsIf Suffix = "OffBalance" Then
		ReturnStructure.Sum     = "AmountOffBalance";
		ReturnStructure.VATAmount  = "";
		ReturnStructure.AmountIncludingVAT = "";
		ReturnStructure.AmountARAP = "";
		ReturnStructure.AmountExcludingVATCompl = "";
		ReturnStructure.AmountExcludingVATMan = "";
	Else
		Raise NStr("vi = 'Hậu tố không xác định đối với số tiền:';
					|ru = 'Неизвестный суффикс для суммы:';
					|en = 'Unknown suffix for amount:'; fa = 'Unknown suffix for amount:';
					|it = 'Suffisso sconosciuto per l''importo:';
					|pl = 'Nieznany sufiks dla wartości:';
					|tr = 'Tutar için bilinmeyen son ek:'") + " " + Suffix;
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Generates the names of VAT amount identifiers with the suffix
// 
// Parameters:
// 	Suffix - String - Suffix
// 
// Returns:
// 	Structure - a set of ID names. Description:
// * Sum    - String - "Sum" + suffix
// * VATAmount - String - "SummaNDS" + suffix
//
Function SumOfNDSSSuffix(Suffix) Export
	
	ReturnStructure = New Structure("Sum, VATAmount");
	
	If Not ValueIsFilled(Suffix) Then
		ReturnStructure.Sum = "VATExclusiveAmountVal";
		ReturnStructure.VATAmount = "VATAmount";
	ElsIf Suffix = "Decrease" Then
		ReturnStructure.Sum = "VATExclusiveAmountGrossDecrease";
		ReturnStructure.VATAmount = "VATAmountReduction";
	ElsIf Suffix = "Increase" Then
		ReturnStructure.Sum = "VATExclusiveAmountGrossIncrease";
		ReturnStructure.VATAmount = "VATAmountIncrease";
	Else
		Raise NStr("vi = 'Hậu tối không xác định đối với số tiền thuế GTGT:';
					|ru = 'Неизвестный суффикс для суммы НДС:';
					|en = 'Unknown suffix for VAT amount:'; fa = 'Unknown suffix for VAT amount:';
					|it = 'Unknown suffix for VAT amount:';
					|pl = 'Unknown suffix for VAT amount:';
					|tr = 'KDV tutarı için bilinmeyen son ek:'") + " " + Suffix;
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Generates the names of the VAT rate identifiers with the suffix
// 
// Parameters:
// 	Suffix - String - Suffix
// Returns:
// 	Structure - a set of ID names. Description:
// * VATRate - String - "StavkaNDS" + suffix
Function RateWithSuffix(Suffix) Export
	
	ReturnStructure = New Structure("VATRate");
	
	If Not ValueIsFilled(Suffix) Then
		ReturnStructure.VATRate = "VATRate";
	ElsIf Suffix = "ByDocument" Then
		ReturnStructure.VATRate = "VATRate";
	ElsIf Suffix = "After" Then
		ReturnStructure.VATRate = "VATRateAfter";
	Else
		Raise NStr("vi = 'Sai hậu tố đối với thuế suất';
					|ru = 'Неизвестный суффикс для ставки:';
					|en = 'Unknown suffix for the rate:'; fa = 'Unknown suffix for the rate:';
					|it = 'Suffisso sconosciuto per l''aliquota:';
					|pl = 'Nieznany sufiks dla stawki:';
					|tr = 'Oran için bilinmeyen son ek:'") + " " + Suffix;
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Recalculates the product amount in the current row of the table part of the document "customer's Order".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountInLineTSOrderGiver(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("RecalculateGiverSOrderAmount") Then
		If CurrentRow <> Undefined Then
			CurrentRow.Sum = CurrentRow.OwnMaterials + CurrentRow.Amount;
		EndIf;
	EndIf;
	
EndProcedure

// Recalculates the service amount in the current row of the table part of the document "customer's Order".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountOfServiceInLineTSOrderGiver(CurrentRow, StructureOfActions, CachedValues) Export
	
	QuantityName = Undefined;
	
	If StructureOfActions.Property("RecalculateAmountOfServiceOrderGiver", QuantityName) Then
		If Not ValueIsFilled(QuantityName) Then
			QuantityName = "NumberOfPackages"
		EndIf;
		If CurrentRow <> Undefined Then
			CurrentRow.Amount = CurrentRow.Price * CurrentRow[QuantityName];
		EndIf;
	EndIf;
	
EndProcedure
// Recalculates the discount price in the current line.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - a structure with actions to be performed.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateDiscountPriceByAmountInSalesInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	StructureOfActionParameters = Undefined;
	
	If StructureOfActions.Property("RecalculatePriceDiscountByAmountInSales", StructureOfActionParameters) Then
		
		UseManualDiscounts = False;
		If StructureOfActionParameters <> Undefined Then
			If StructureOfActionParameters.Property("UseManualDiscounts") Then
				UseManualDiscounts = True;
			EndIf;
		EndIf;
		
		UseAutomaticDiscounts = False;
		If StructureOfActionParameters <> Undefined Then
			If StructureOfActionParameters.Property("UseAutomaticDiscounts") Then
				UseAutomaticDiscounts = True;
			EndIf;
		EndIf;
		
		UseBonusPoints = False;
		If StructureOfActionParameters <> Undefined Then
			If StructureOfActionParameters.Property("UseBonusPoints") Then
				UseBonusPoints = True;
			EndIf;
		EndIf;
		
		QuantityName = "NumberOfPackages";
		If StructureOfActionParameters <> Undefined Then
			If Not StructureOfActionParameters.Property("QuantityName",QuantityName) Then
				QuantityName = "NumberOfPackages";
			EndIf;
		EndIf;
		
		If UseManualDiscounts And CachedValues.UseDiscountAdjustmentsInSales = Undefined Then
			CachedValues.UseDiscountAdjustmentsInSales = 
				GeneralPurposeTMServerCall.ValueOfFunctionOption("UseDiscountAdjustmentsInSales");
		EndIf;
		
		If UseAutomaticDiscounts And CachedValues.UseDiscountsMarkupsInSales = Undefined Then
			CachedValues.UseDiscountsMarkupsInSales = 
				GeneralPurposeTMServerCall.ValueOfFunctionOption("UseDiscountsMarkupsInSales");
		EndIf;
		// If manual discounts are used, we recalculate the percentage and the amount of the manual discount, otherwise we recalculate the price.
		If UseManualDiscounts And CachedValues.UseDiscountAdjustmentsInSales Then
			
			If CurrentRow.Sum = 0 Or CurrentRow[QuantityName] = 0 Then
				
				CurrentRow.Price                = 0;
				CurrentRow.ManualDiscount   = 0;
				
			Else
				If ValueIsFilled(CurrentRow.PriceKind) And CurrentRow.Price = 0 Then
					CurrentRow.ManualDiscount = 0;
					CurrentRow.PercentRateOfManualDiscount = 0;
				ElsIf CurrentRow.Price = 0 Then
					If UseBonusPoints Then
						If ValueIsFilled(CurrentRow.PercentRateOfManualDiscount) Then
							CurrentRow.ManualDiscount = ((CurrentRow.Sum - CurrentRow.AmountOfBonusPointsToDeductionInCurrency) * CurrentRow.PercentRateOfManualDiscount)  / (100 - CurrentRow.PercentRateOfManualDiscount);
						EndIf;
						CurrentRow.Price = Round((CurrentRow.Sum + CurrentRow.ManualDiscount + CurrentRow.AmountOfBonusPointsToDeductionInCurrency) / CurrentRow[QuantityName], 2);
					Else
						If ValueIsFilled(CurrentRow.PercentRateOfManualDiscount) Then
							CurrentRow.ManualDiscount = (CurrentRow.Sum * CurrentRow.PercentRateOfManualDiscount)  / (100 - CurrentRow.PercentRateOfManualDiscount);
						EndIf;
						CurrentRow.Price = Round((CurrentRow.Sum + CurrentRow.ManualDiscount) / CurrentRow[QuantityName], 2);
					EndIf;
				Else
					AmountWithoutADiscount = CurrentRow.Price * CurrentRow[QuantityName];
					If UseBonusPoints Then
						CurrentRow.ManualDiscount   = AmountWithoutADiscount - CurrentRow.Sum - CurrentRow.AmountOfBonusPointsToDeductionInCurrency;
					Else
						CurrentRow.ManualDiscount   = AmountWithoutADiscount - CurrentRow.Sum;
					EndIf;
					CurrentRow.PercentRateOfManualDiscount = Round(100*CurrentRow.ManualDiscount / AmountWithoutADiscount, 2);
				EndIf;
				
			EndIf;
			
		Else
			
			If CurrentRow.Sum = 0 Or CurrentRow[QuantityName] = 0 Then
				CurrentRow.Price = 0;
			Else
				If UseBonusPoints Then
					CurrentRow.Price = Round((CurrentRow.Sum - CurrentRow.AmountOfBonusPointsToDeductionInCurrency) / CurrentRow[QuantityName], 2);
				Else
					CurrentRow.Price = Round(CurrentRow.Sum / CurrentRow[QuantityName], 2);
				EndIf;
			EndIf;
			
		EndIf;
		
		If UseAutomaticDiscounts Then
			If CachedValues.UseDiscountsMarkupsInSales Then
				CurrentRow.DiscountMarkupAmount   = 0;
				CurrentRow.PercentRateOfAutomaticDiscountMarkup = 0;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Recalculates the price and amount of the manual discount from the product price in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateDiscountPriceByAmountInPurchasesInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	StructureOfActionParameters = Undefined;
	
	If StructureOfActions.Property("RecalculatePriceDiscountForAmountInPurchases", StructureOfActionParameters) Then
		
		// If manual discounts are used, we recalculate the percentage and the amount of the manual discount, otherwise we recalculate the price.
		UseManualDiscounts = False;
		If StructureOfActionParameters <> Undefined Then
			If StructureOfActionParameters.Property("UseManualDiscounts") Then
				UseManualDiscounts = True;
			EndIf;
		EndIf;
		
		QuantityName = "NumberOfPackages";
		If StructureOfActionParameters <> Undefined Then
			If Not StructureOfActionParameters.Property("QuantityName",QuantityName) Then
				QuantityName = "NumberOfPackages";
			EndIf;
		EndIf;
		
		If UseManualDiscounts And CachedValues.UseDiscountAdjustmentsInPurchases = Undefined Then
			CachedValues.UseDiscountAdjustmentsInPurchases =
				GeneralPurposeTMServerCall.ValueOfFunctionOption("UseDiscountAdjustmentsInPurchases");
		EndIf;
		
		// If manual discounts are used, we recalculate the percentage and the amount of the manual discount, otherwise we recalculate the price.
		If UseManualDiscounts And CachedValues.UseDiscountAdjustmentsInPurchases Then
			
			If CurrentRow.Sum = 0 Or CurrentRow[QuantityName] = 0 Then
				
				CurrentRow.Price                = 0;
				CurrentRow.ManualDiscount   = 0;
				
			Else
				
				If CurrentRow.Price = 0 Then
					If ValueIsFilled(CurrentRow.PercentRateOfManualDiscount) Then
						CurrentRow.ManualDiscount = (CurrentRow.Sum * CurrentRow.PercentRateOfManualDiscount)  / (100 - CurrentRow.PercentRateOfManualDiscount);
					EndIf;
					CurrentRow.Price = Round((CurrentRow.Sum + CurrentRow.ManualDiscount) / CurrentRow[QuantityName], 2);
				Else
					AmountWithoutADiscount = CurrentRow.Price * CurrentRow[QuantityName];
					CurrentRow.ManualDiscount   = AmountWithoutADiscount - CurrentRow.Sum;
					CurrentRow.PercentRateOfManualDiscount = Round(100*CurrentRow.ManualDiscount / AmountWithoutADiscount, 2);
				EndIf;
				
			EndIf;
			
		Else
			
			If CurrentRow.Sum = 0 Or CurrentRow[QuantityName] = 0 Then
				CurrentRow.Price = 0;
			Else
				CurrentRow.Price = Round(CurrentRow.Sum / CurrentRow[QuantityName], 2);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Recalculates the price from the cost of the product in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculatePriceByAmountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	QuantityName = Undefined;
	
	If StructureOfActions.Property("RecalculatePriceByAmount", QuantityName) Then
		If Not ValueIsFilled(QuantityName) Then
			QuantityName = "NumberOfPackages";
		EndIf;
		If CurrentRow[QuantityName] = 0 Then
			CurrentRow.Price = CurrentRow.Sum;
		Else
			CurrentRow.Price = Round(CurrentRow.Sum / CurrentRow[QuantityName], 2);
		EndIf;
	EndIf;
	
EndProcedure

// Recalculates the price from the cost of the product in the current line of the table part of the document "customer's Order".
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculatePriceByAmountInTSLineOfGiverSOrder(CurrentRow, StructureOfActions, CachedValues) Export
	
	QuantityName = Undefined;
	
	If StructureOfActions.Property("RecalculatePriceByAmountOfGiverSOrder",QuantityName) Then
		If Not ValueIsFilled(QuantityName) Then
			QuantityName = "NumberOfPackages";
		EndIf;
		If CurrentRow[QuantityName] = 0 Then
			CurrentRow.Price = CurrentRow.Amount;
		Else
			CurrentRow.Price = Round(CurrentRow.Amount / CurrentRow[QuantityName], 2);
		EndIf;
	EndIf;
	
EndProcedure
// Recalculates the sales price of the product from the sales amount in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateSalePriceBySaleAmountInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("RecalculateSalePriceBySaleAmount") Then
		
		CurrentRow.SellingPrice = ?(CurrentRow.NumberOfPackages <> 0, Round(CurrentRow.SalesAmount / CurrentRow.NumberOfPackages, 2, 1), 0);
		
	EndIf;
	
EndProcedure

// Recalculates the product price based on the discount in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountTakingIntoAccountAutomaticDiscountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	StructureOfActionParameters = Undefined;
	
	If StructureOfActions.Property("RecalculateAmountTakingIntoAccountAutomaticDiscount", StructureOfActionParameters) Then
		
		Clear = Undefined;
		StructureOfActionParameters.Property("Clear", Clear);
		
		If Clear Then
			
			CurrentRow.DiscountMarkupAmount = 0;
			CurrentRow.PercentRateOfAutomaticDiscountMarkup = 0;
			
		EndIf;
		
		Discount = CurrentRow.DiscountMarkupAmount;
		
		CurrentRow.Sum = CurrentRow.Sum - Discount;
		
	EndIf;

EndProcedure

// Recalculates the cost of the product, taking into account the manual discount in the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you need to make
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountTakingIntoAccountManualDiscountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	StructureOfActionParameters = Undefined;
	
	If StructureOfActions.Property("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfActionParameters) Then
		
		Clear = Undefined;
		RecalculateAmountOfManualDiscount_ = Undefined;
		QuantityName = Undefined;
		
		If StructureOfActionParameters <> Undefined Then
			
			StructureOfActionParameters.Property("Clear", Clear);
			StructureOfActionParameters.Property("RecalculateAmountOfManualDiscount_", RecalculateAmountOfManualDiscount_);
			StructureOfActionParameters.Property("QuantityName", QuantityName);
			
			If Not ValueIsFilled(QuantityName) Then
				QuantityName = "NumberOfPackages";
			EndIf;
			
			If Clear = True Then
				
				CurrentRow.ManualDiscount = 0;
				CurrentRow.PercentRateOfManualDiscount = 0;
				
			EndIf;
			
		EndIf;
		
		If RecalculateAmountOfManualDiscount_ = False Then
			
		Else
			CurrentRow.ManualDiscount = Round(CurrentRow[QuantityName] *CurrentRow.Price * CurrentRow.PercentRateOfManualDiscount / 100, 2);
		EndIf;
			
		CurrentRow.Sum = CurrentRow.Sum - CurrentRow.ManualDiscount;
		
	EndIf;

EndProcedure

// Recalculates the cost of the product, taking into account the discount on bonus points in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountTakingIntoAccountDiscountWithBonusPointsInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	StructureOfActionParameters = Undefined;
	
	If StructureOfActions.Property("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfActionParameters) Then
		
		RecalculateAmountOfBonusPointsByLine = Undefined;
		
		If StructureOfActionParameters <> Undefined Then
			
			StructureOfActionParameters.Property("RecalculateAmountOfBonusPointsByLine", RecalculateAmountOfBonusPointsByLine);
			
		EndIf;
		
		If RecalculateAmountOfBonusPointsByLine = True Then
			
			QuantityName = "NumberOfPackages";
			NameOfQuantityIsOriginal = "PackagingQuantityInTheOrder";
			
			PairsOfAttributesToRecalculate = New Map;
			PairsOfAttributesToRecalculate.Insert("AmountOfBonusPointsToDeduction",
												"AmountOfBonusPointsToBeDebitedOnOrder");
			PairsOfAttributesToRecalculate.Insert("AmountOfBonusPointsToDeductionInCurrency",
												"AmountOfBonusPointsToBeDebitedInCurrencyOfOrder");
			
			NmbrOfPackages = CurrentRow[QuantityName];
			OriginalNumberOfPackages = CurrentRow[NameOfQuantityIsOriginal];
			If NmbrOfPackages < OriginalNumberOfPackages Then
				For Each Itm In PairsOfAttributesToRecalculate Do
					CurrentRow[Itm.Key] = CurrentRow[Itm.Value]*NmbrOfPackages/OriginalNumberOfPackages;
				EndDo;
			Else
				For Each Itm In PairsOfAttributesToRecalculate Do
					CurrentRow[Itm.Key] = CurrentRow[Itm.Value];
				EndDo;
			EndIf;
			
		EndIf;
		
		DataToRecalculate = Undefined;
		QuantityName = Undefined;

		If StructureOfActionParameters <> Undefined Then
			
			StructureOfActionParameters.Property("RecalculateAmount_", DataToRecalculate);
			StructureOfActionParameters.Property("QuantityName", QuantityName);
			
			If Not ValueIsFilled(QuantityName) Then
				QuantityName = "NumberOfPackages";
			EndIf;
			
			If ValueIsFilled(DataToRecalculate) Then
				CurrentRow.AmountOfBonusPointsToDeductionInCurrency =  Min(Round(
													DataToRecalculate.AmountOfBonusPointsToDeductionInCurrency 
													* CurrentRow[QuantityName] 
													/ DataToRecalculate[QuantityName], 2, RoundMode.Round15as20),
													DataToRecalculate.AmountOfBonusPointsToDeductionInCurrency);
			EndIf;
			
		EndIf;
		
		CurrentRow.Sum = CurrentRow.Sum - CurrentRow.AmountOfBonusPointsToDeductionInCurrency;
		
	EndIf;

EndProcedure

// Recalculates the cost of the product with VAT in the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateSumOfSNDSInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateAmountWithVAT", StructureOfActionParameters) Then
		
		CurrentRow.AmountIncludingVAT = CurrentRow.Sum + ?(StructureOfActionParameters.PriceIncludesVAT, 0, CurrentRow.VATAmount);
		
	EndIf;
	
EndProcedure

// Recalculates the value of the product with VAT that has the specified attribute in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateSumWithVATSuffixInTSString(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	Suffix = "";
	
	If StructureOfActions.Property("RecalculateSumWithVATSuffix", StructureOfActionParameters) Then
		
		If StructureOfActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			
			Suffix = "";
			
		EndIf;
		
		SumWithSuffix = SumWithSuffix(Suffix);
		
		CurrentRow[SumWithSuffix.AmountIncludingVAT] = Round(CurrentRow[SumWithSuffix.Sum]
			+ ?(StructureOfActionParameters.PriceIncludesVAT, 0, CurrentRow[SumWithSuffix.VATAmount]), 2, RoundMode.Round15as20);
		
	EndIf;
	
EndProcedure

// Recalculates the cost of the product without VAT in the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountWithoutNDSVToTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("RecalculateAmountWithoutVAT") Then
		
	    CurrentRow.AmountExcludingVAT = Round(CurrentRow.Sum - CurrentRow.VATAmount, 2, RoundMode.Round15as20);
		
	EndIf;
	
EndProcedure

// Recalculates the cost of the product in the currency of regulated accounting in the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateLocalSumInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FactorOfConversionFromManCurrencyToRegulCurrency;
	
	If StructureOfActions.Property("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency) Then
		CurrentRow.SumCompl = Round(CurrentRow.AmountExcludingVAT * FactorOfConversionFromManCurrencyToRegulCurrency, 2, 1);
	EndIf;
	
EndProcedure

// Recalculates the amount of the constant difference in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateSumOfPRVAndTS(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("RecalculatePDAmount") And Not CurrentRow.AcceptedByTheKNU Then
		CurrentRow.AmountPermanentDifferences = CurrentRow.SumCompl;
	EndIf;
	
EndProcedure

// Recalculates the VAT amount in the regulated accounting currency in the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateLocalVATInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateLocalVAT", StructureOfActionParameters) Then
		
		VATTaxation = Undefined;
		StructureOfActionParameters.Property("VATTaxation", VATTaxation);
		
		VATRate = Undefined;
		If Not StructureOfActionParameters.Property("VATRate", VATRate) Then
			VATRate = CurrentRow.VATRate;
		EndIf;
		
		If CachedValues.Property("PercentOfVATRates") Then
			CurPercentVAT = CachedValues.PercentOfVATRates[VATRate];
		Else
			CachedValues.Insert("PercentOfVATRates", New Map);
			CurPercentVAT = Undefined;
		EndIf;
		
		If CurPercentVAT = Undefined Then
			
			CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
			CachedValues.PercentOfVATRates.Insert(VATRate, CurPercentVAT);
			
		EndIf;
		
		CurrentRow.VATLocal = VATAccountingERPClientServer.CalculateVATAmount(
			CurrentRow.SumCompl,
			CurPercentVAT,
			False,
			VATTaxation);
			
	EndIf;
	
EndProcedure

// Recalculates the cost of goods without VAT in the currency of regulated accounting in the Cur line of the tabular part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountWithoutVATLocalInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateAmountWithoutVATLocal", StructureOfActionParameters) Then
		
		If StructureOfActionParameters.PriceIncludesVAT Then
			CurrentRow.AmountExcludingVATCompl = CurrentRow.AmountIncludingVAT - CurrentRow.VATAmount;
		Else
			CurrentRow.AmountExcludingVATCompl = CurrentRow.Sum;
		EndIf;
		If Not StructureOfActionParameters.ByAmountOfDocument Then
			CurrentRow.AmountExcludingVATCompl = CurrentRow.AmountExcludingVATCompl * StructureOfActionParameters.ConversionRatioFromDocumentCurrency;
		EndIf;
	
	EndIf;
	
EndProcedure

// Recalculates the cost of goods without VAT in the currency of regulated accounting in the Cur line of the tabular part of the document with the suffix.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountWithoutVATLocalSuffixInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateAmountWithoutVATLocalSuffix", StructureOfActionParameters) Then
		
		Suffix = "";
		
		If StructureOfActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			Suffix = "";
		EndIf;
		
		SumWithSuffix = SumWithSuffix(Suffix);

		If StructureOfActionParameters.PriceIncludesVAT Then
			CurrentRow[SumWithSuffix.AmountExcludingVATCompl] = CurrentRow[SumWithSuffix.AmountIncludingVAT] - CurrentRow[SumWithSuffix.VATAmount];
		Else
			CurrentRow[SumWithSuffix.AmountExcludingVATCompl] = CurrentRow[SumWithSuffix.Sum];
		EndIf;
		If Not StructureOfActionParameters.ByAmountOfDocument Then
			CurrentRow[SumWithSuffix.AmountExcludingVATCompl] = CurrentRow[SumWithSuffix.AmountExcludingVATCompl] * StructureOfActionParameters.ConversionRatioFromDocumentCurrency;
		EndIf;
		
	EndIf;
	
EndProcedure

// Recalculates the cost of goods excluding VAT in the currency of management accounting in the Cur line of the tabular part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountWithoutVATManInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateAmountWithoutVATMan", StructureOfActionParameters) Then
		
		If StructureOfActionParameters.PriceIncludesVAT Then
			CurrentRow.AmountExcludingVATMan = CurrentRow.AmountIncludingVAT - CurrentRow.VATAmount;
		Else
			CurrentRow.AmountExcludingVATMan = CurrentRow.Sum;
		EndIf;
		If Not StructureOfActionParameters.ByAmountOfDocument Then
			CurrentRow.AmountExcludingVATMan = CurrentRow.AmountExcludingVATMan * StructureOfActionParameters.ConversionRatioFromDocumentCurrency;
		EndIf;
		
	EndIf;
	
EndProcedure

// Recalculates the cost of goods excluding VAT in the currency of management accounting in the Cur line of the tabular part of the document with the suffix.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountWithoutVATManSuffixInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateAmountWithoutVATManSuffix", StructureOfActionParameters) Then
		
		Suffix = "";
		
		If StructureOfActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			Suffix = "";
		EndIf;
		
		SumWithSuffix = SumWithSuffix(Suffix);

		If StructureOfActionParameters.PriceIncludesVAT Then
			CurrentRow[SumWithSuffix.AmountExcludingVATMan] = CurrentRow[SumWithSuffix.AmountIncludingVAT] - CurrentRow[SumWithSuffix.VATAmount];
		Else
			CurrentRow[SumWithSuffix.AmountExcludingVATMan] = CurrentRow[SumWithSuffix.Sum];
		EndIf;
		If Not StructureOfActionParameters.ByAmountOfDocument Then
			CurrentRow[SumWithSuffix.AmountExcludingVATMan] = CurrentRow[SumWithSuffix.AmountExcludingVATMan] * StructureOfActionParameters.ConversionRatioFromDocumentCurrency;
		EndIf;
		
	EndIf;
	
EndProcedure

// Recalculates the sales amount of the product in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateSaleAmountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateSaleAmount", StructureOfActionParameters) Then
	
		CurrentRow.SalesAmount = CurrentRow.SellingPrice * CurrentRow.NumberOfPackages;
		
	EndIf;

EndProcedure

// Recalculates the VAT sales amount of the product in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountOfSaleOfNDSVToTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateVATSalesAmount", StructureOfActionParameters) Then
		
		VATTaxation = Undefined;
		If StructureOfActionParameters <> Undefined 
			And StructureOfActionParameters.Property("VATTaxation", VATTaxation) Then
			If VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SubjectToVATAtCustomer") 
				Or VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SubjectToVATFromPriceDifference") Then
				// Recalculation is not required 
				Return;
			EndIf;
		EndIf;
		
		VATRate = Undefined;
		If StructureOfActionParameters = Undefined Or Not StructureOfActionParameters.Property("VATRate", VATRate) Then
			VATRate = CurrentRow.VATRate;
		EndIf;
		
		If CachedValues.Property("PercentOfVATRates") Then
			CurPercentVAT = CachedValues.PercentOfVATRates[VATRate];
		Else
			CachedValues.Insert("PercentOfVATRates", New Map);
			CurPercentVAT = Undefined;
		EndIf;
		
		If CurPercentVAT = Undefined Then
			
			CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
			CachedValues.PercentOfVATRates.Insert(VATRate, CurPercentVAT);
			
		EndIf;
		
		CurrentRow.AmountSalesVAT = Round(CurrentRow.SalesAmount * CurPercentVAT / (100 + CurPercentVAT), 2, RoundMode.Round15as20);
	EndIf;

EndProcedure

// Sets whether a row is active in the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure SetStringActivity(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("SetActive") Then
		CurrentRow.Active = True;
	EndIf;
	
EndProcedure

// Fills in the product (service) destination field in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInActionForRecyclableMaterialsInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Action = Undefined;
	If StructureOfActions.Property("FillInActionForRecyclableMaterials", Action) Then
		If ValueIsFilled(Action) Then
			CurrentRow.Action = Action;
		Else
			CurrentRow.Action = PredefinedValue("Enum.ActionsOnMaterialsToSubcontract.AcceptVMI");
		EndIf;

	EndIf;
	
EndProcedure

// Fills in the product (service) destination field in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure CheckFillAssignmentInLineTS(CurrentRow, StructureOfActions, CachedValues) Export
	
	Purpose = Undefined;
	If StructureOfActions.Property("CheckFillAssignment", Purpose) Then
		
		CurrentRow.Purpose = PredefinedValue("Catalog.Assignments.EmptyRef");
		
		If Purpose <> Undefined Then
			
			If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
				Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				
				CurrentRow.Purpose = Purpose;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the product (service) destination field in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillFlagSeparatelyAsIntended(CurrentRow, StructureOfActions, CachedValues) Export
	
	PropsNameToShipSeparately = Undefined;
	If StructureOfActions.Property("FillFlagSeparatelyAsIntended", PropsNameToShipSeparately) Then
		
		CurrentRow[PropsNameToShipSeparately] = ValueIsFilled(CurrentRow.Purpose);
		
	EndIf;

EndProcedure

// Fills in the fields used to reflect product discrepancies and surpluses in the current row of the table 
// part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInDiscrepancyFlag(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("FillInDiscrepancyFlag") Then
		CurrentRow.Discrepancy = (CurrentRow.NumberOfPackages <> CurrentRow.NumberOfPackagesReal);		
	EndIf;
	
EndProcedure

// Fills in the fields used to reflect product discrepancies and surpluses in the current row of the table 
// part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfPackagesDeviation(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("RecalculateNumberOfPackagesDeviation") Then
		CurrentRow.NumberOfPackagesDiscrepancy 
			= CurrentRow.NumberOfPackagesReal - CurrentRow.NumberOfPackages;
	EndIf;
		
EndProcedure

// Fills in the fields used to reflect product discrepancies and surpluses in the current row of the table 
// part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillExcessSpoilageFlag(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("FillExcessSpoilageFlag") Then
		CurrentRow.SurplusDamage = True;		
	EndIf;
	
EndProcedure

// Sets the zero value in the product settlement amount field in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure ClearAmountOfSettlementsInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("ClearAmountOfSettlements") Then
		
		CurrentRow.AmountARAP = 0;
		
	EndIf;
	
EndProcedure

// Sets the zero value in the field of the amount of settlements (with a suffix) for the product in the Cur line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure ClearSumOfMutualSettlementsSuffixInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Suffix = Undefined;
	If StructureOfActions.Property("ClearAmountOfSettlementsSuffix", Suffix) Then
	
		If ValueIsFilled(Suffix) Then
			CurrentRow[SumWithSuffix(Suffix).AmountARAP] = 0;
		Else
			CurrentRow.AmountARAP = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets zero values in the VAT Amount (Local) and VAT Amount (upr.) fields
// in the Cur row of the tabular part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure SetVATAmountOfLocalManInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ActionParameters;
	
	If StructureOfActions.Property("SetVATAmountLocalMans", ActionParameters) Then
		
		If ActionParameters.DocumentCurrency = ActionParameters.ComplCurrency
			And CurrentRow.VATAmountCompl > 0 Then
			CurrentRow.VATAmountCompl = CurrentRow.VATAmount;
		Else
			CurrentRow.VATAmountCompl = 0;
		EndIf;
		
		If ActionParameters.DocumentCurrency = ActionParameters.CurrencyOfMan
			And CurrentRow.VATAmountMan > 0 Then
			CurrentRow.VATAmountMan = CurrentRow.VATAmount;
		Else
			CurrentRow.VATAmountMan = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

// Recalculates the VAT amount in the current line of the tabular part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateVATAmountOfShipmentInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ActionParameters;
	Var VATRate;
	
	If StructureOfActions.Property("RecalculateVATAmountOfShipment", ActionParameters) Then
		
		VATTaxation = Undefined;
		ActionParameters.Property("VATTaxation", VATTaxation);
		
		Suffix = New Array;
		
		If ActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			Suffix.Add("");
		EndIf;
		
		If Not (ActionParameters <> Undefined
				And ActionParameters.Property("VATRate", VATRate)) Then
			
			VATRate = CurrentRow["VATRate"];
			
		EndIf;
		
		If CachedValues.Property("PercentOfVATRates") Then
			CurPercentVAT = CachedValues.PercentOfVATRates[VATRate];
		Else
			CurPercentVAT = Undefined;
			
			CachedValues.Insert("PercentOfVATRates", New Map);
		EndIf;
		
		If CurPercentVAT = Undefined Then
			
			CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
			CachedValues.PercentOfVATRates.Insert(VATRate, CurPercentVAT);
			
		EndIf;
		
		For Each CrntSuffix In Suffix Do 
			
			SumOfNDSSSuffix = SumOfNDSSSuffix(CrntSuffix);
		
			CurrentRow[SumOfNDSSSuffix.VATAmount] = VATAccountingERPClientServer.CalculateVATAmount(
				CurrentRow[SumOfNDSSSuffix.Sum],
				CurPercentVAT,
				ActionParameters.PriceIncludesVAT,
				VATTaxation);
			CurrentRow["Sum"+CrntSuffix] = CurrentRow[SumOfNDSSSuffix.Sum];
			
		EndDo;
	EndIf;
	
EndProcedure

// Sets the zero value for the percentage and discount amount for the product in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure ClearAutomaticDiscountInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("ClearAutomaticDiscount") Then
		
		CurrentRow.PercentRateOfAutomaticDiscountMarkup = 0;
		CurrentRow.DiscountMarkupAmount = 0;
		
	EndIf;
	
EndProcedure

// Sets the zero value for the amount of remuneration for the product in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure ClearRewardAmountInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("ClearRewardAmount", StructureOfActionParameters) Then
	
		CurrentRow.CommissionAmount = 0;
		
	EndIf;

EndProcedure

// Fills in the partner field with a predefined value in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInForm(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("FillInForm") Then
		If Not ValueIsFilled(CurrentRow.Partner) Then
			CurrentRow.Partner = PredefinedValue("Catalog.Partners.RetailCustomer");
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the irrevocable container attribute in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInNoReturnContainerAttribute(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ToReturnReusablePackage;
	
	If StructureOfActions.Property("FillInNoReturnContainerAttribute", ToReturnReusablePackage) Then
	
		CurrentRow.WithoutReusablePackages = Not (ToReturnReusablePackage
			And CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	
	EndIf;
	
EndProcedure

// Fills in the order cancellation flag for irrevocable containers in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInCanceledWithoutReturnableContainerAttribute(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ToReturnReusablePackage;
	
	If StructureOfActions.Property("FillInCanceledWithoutReturnableContainerAttribute", ToReturnReusablePackage) Then
	
		CurrentRow.CanceledWithoutReusablePackages = Not (ToReturnReusablePackage
			And CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")) And CurrentRow.Canceled;
	
	EndIf;
	
EndProcedure

// Sets whether the irrevocable container row is active in the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInActivityWithoutReturnableContainerAttribute(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ToReturnReusablePackage;
	
	If StructureOfActions.Property("FillInActivityWithoutReturnableContainerAttribute", ToReturnReusablePackage) Then
	
		CurrentRow.ActiveWithoutReusablePackages = Not (ToReturnReusablePackage
			And CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")) And CurrentRow.Active;
	
	EndIf;
	
EndProcedure

// Fills in the fields of duplicate dependent details in the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInDuplicateDependentDetails(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ActionStructureParameter;
	If Not StructureOfActions.Property("FillInDuplicateDependentDetails", ActionStructureParameter)
		Or Not ValueIsFilled(ActionStructureParameter) Then
		Return;
	EndIf;
	
	// Parameterstructure of actions - Structure
	// 		Key: The name of the activity flag props
	// 		Value: A comma-separated string with the names of dependent details.
	
	For Each StructureField In ActionStructureParameter Do
		
		NameOfActivityFlag = StructureField.Key;
		ValueOfActivityFlag = CurrentRow[NameOfActivityFlag];
		
		DependentDetails = New Structure(StructureField.Value);
		For Each Attribute In DependentDetails Do
			CurrentRow[Attribute.Key+NameOfActivityFlag] = ?(
				ValueOfActivityFlag,
				CurrentRow[Attribute.Key],
				0);
		EndDo;
		
	EndDo;
	
EndProcedure

// Recalculates the amount over the order for the product in the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountInExcessOfOrderInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("RecalculateAmountOverOrder", StructureOfActionParameters) Then
		If TMCommonUseClientServer.HasObjectAttribute(CurrentRow, "AmountInExcessOfOrder") Then
			If StructureOfActionParameters.ImplementationReceiptByOrder And CurrentRow.RowCode = 0 Then
				If StructureOfActionParameters.Property("PackageDepositIsRequired")
					And StructureOfActionParameters.PackageDepositIsRequired Then
					CurrentRow.AmountInExcessOfOrder = CurrentRow.AmountIncludingVAT;
				Else
					CurrentRow.AmountInExcessOfOrder = CurrentRow.AmountIncludingVATWithoutReusablePackages;
				EndIf;
			Else
				CurrentRow.AmountInExcessOfOrder = 0;
			EndIf;
		EndIf;	
	EndIf;
	
EndProcedure

// Fills in the option field for reflecting the implementation adjustment in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInOptionToReflectImplementationAdjustment(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var Operation;
	
	If StructureOfActions.Property("FillInOptionToReflectImplementationAdjustment", Operation) Then
		
		If (CurrentRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.OwnGoods")
			And CurrentRow.ItemsType <> PredefinedValue("Enum.ItemsTypes.ReusablePackage"))
			Or CurrentRow.NumberOfPackages = 0 Then
			
			If Operation = PredefinedValue("Enum.BusinessTransactions.SaleOfOverdeliveredGoods") Then
				CurrentRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale");
			ElsIf Operation = PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods") Then
				CurrentRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleWriteOffForExpenses");
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Generates the names of the quantity IDs with the suffix
// 
// Parameters:
// 	Suffix - String - Suffix
// Returns:
// 	Structure - a set of ID names. Description:
// * Count - String - "Quantity" + suffix
// * NumberOfPackages - String - "Number of packages" + suffix
// * QuantityByGBRN - String - "Quantity of" + suffix
//
Function QuantityWithSuffix(Val Suffix) Export
	
	If TypeOf(Suffix) = Type("Structure") Then
		Suffix = Suffix.Suffix;
	EndIf;
	
	ReturnStructure = New Structure();
	
	ReturnStructure.Insert("Count", "");
	ReturnStructure.Insert("NumberOfPackages", "");
	ReturnStructure.Insert("QuantityByGBRN", "");
	
	If Not ValueIsFilled(Suffix) Then
		ReturnStructure.Count = "Count";
		ReturnStructure.NumberOfPackages = "NumberOfPackages";
		ReturnStructure.QuantityByGBRN = "QuantityByGBRN";
	ElsIf Suffix = "Selected" Then
		ReturnStructure.Count = "QuantityIsSelected";
		ReturnStructure.NumberOfPackages = "TheNumberOfPackagesIsSelected";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "Plan" Then
		ReturnStructure.Count = "CountPlan";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesPlan";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "ByDocument" Then
		ReturnStructure.Count = "CountByDocument";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesByDocument";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "Real" Then
		ReturnStructure.Count = "CountReal";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesReal";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "Deviation" Then
		ReturnStructure.Count = "DeviationInStorageUnits";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesDiscrepancy";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "Picked" Then
		ReturnStructure.Count = "CountPicked";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesPicked";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "Placed" Then
		ReturnStructure.Count = "CountPlaced";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesPlaced";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "Order" Then
		ReturnStructure.Count = "QuantityOrderedStorageUoM";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesToOrder";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "ForReturn" Then
		ReturnStructure.Count = "QuantityForReturn";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesDueToReturn";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "InOrder" Then
		ReturnStructure.Count = "QuantityInOrder";
		ReturnStructure.NumberOfPackages = "PackagingQuantityInTheOrder";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "AssemblyInProgress" Then
		ReturnStructure.Count = "NumberInProgress";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesCollected";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "InNote" Then
		ReturnStructure.Count = "NoteQuantity";
		ReturnStructure.NumberOfPackages = "PackagingQuantityInTheNote";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "NormativeStandard" Then
		ReturnStructure.Count = "QuantityStandard";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesStandard";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "Prediction" Then
		ReturnStructure.Count = "QuantityForecast";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesyForecast";
		ReturnStructure.QuantityByGBRN = "";
	ElsIf Suffix = "After" Then
		ReturnStructure.Count = "QuantityAfter";
		ReturnStructure.NumberOfPackages = "NumberOfPackagesAfter";
		ReturnStructure.QuantityByGBRN = "QuantityAccordingToRNPTAfter";
	ElsIf Suffix = "OffBalance" Then
		ReturnStructure.Count         = "";
		ReturnStructure.NumberOfPackages = "NumberOfPackages";
		ReturnStructure.QuantityByGBRN   = "";
	ElsIf Suffix = "Registered_" Then
		ReturnStructure.Count         = "Count";
		ReturnStructure.NumberOfPackages = "CountRecordingAsReceived";
	Else
		Raise NStr("vi = 'Hậu tố không xác định đối với số lượng:';
					|ru = 'Неизвестный суффикс для количества:';
					|en = 'Unknown suffix for quantity:'; fa = 'Unknown suffix for quantity:';
					|it = 'Suffisso sconosciuto per la quantità:';
					|pl = 'Nieznany sufiks dla ilości:';
					|tr = 'Miktar için bilinmeyen son ek:'") + " " + Suffix;
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Fills in the service details in the line based on the selected warehouse
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure RecalculateFractionOfCostInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If Not StructureOfActions.Property("RecalculateCostShare", ActionParameters) Then
		Return;
	EndIf;
	
	If IsBlankString(ActionParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
		MethodOfAllocatingFinishedProductCosts = ActionParameters.MethodOfAllocatingFinishedProductCosts;
	Else
		MethodOfAllocatingFinishedProductCosts = CurrentRow[ActionParameters.FieldNameMethodOfCostAllocationForOutputProducts];
	EndIf;
	
	ProductionClientServer.CalculateFractionOfCostPerLine(CurrentRow, MethodOfAllocatingFinishedProductCosts);
	
EndProcedure

// Fills in the cost determination method with the line
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInCostDeterminationMethodWithLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ParametersStructure;
	
	If StructureOfActions.Property("FillInCostDeterminationMethodWithLine", ParametersStructure)
		And CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "MethodForDeterminingTheCostOfALine") Then
		
		If CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromCurrentDocument") Then
			Presentation = NStr("vi = 'Bằng với số tiền trong dòng này';
								|ru = 'Равна сумме в данной строке';
								|en = 'Equals the amount in this line'; fa = 'برابر با مبلغ در این سطر';
								|it = 'Pari all''importo di questa riga';
								|pl = 'Jest równa kwocie w danym wierszu';
								|tr = 'Verilen satırdaki tutara eşit'");
		ElsIf CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromSalesDocument") Then
			Presentation = NStr("vi = 'Xác định từ chứng từ bán hàng';
								|ru = 'Определяется из документа продажи';
								|en = 'Determined from the sales document'; fa = 'از سند فروش تعیین می‌شود';
								|it = 'Viene definito dal documento di vendita';
								|pl = 'Określane jest z dokumentu sprzedaży';
								|tr = 'Satış belgesinden belirlenir'");
		ElsIf CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromTransferDocument") Then
			Presentation = NStr("vi = 'Xác định từ chứng từ chuyển nhượng';
								|ru = 'Определяется из документа передачи';
								|en = 'Determined from the transfer document'; fa = 'از سند انتقال تعیین می‌شود';
								|it = 'Viene definito dal documento di trasmissione';
								|pl = 'Określa się na podstawie dokumentu przekazania';
								|tr = 'Transfer belgesinden belirlenir'");
		ElsIf CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.Manually") Then
			If ParametersStructure.ManagementAccountingCurrency = ParametersStructure.LocalAccountingCurrency Then
				If ParametersStructure.UseLocal Then
					If ParametersStructure.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
						Presentation = NStr("vi = 'Giá vốn gồm thuế GTGT: %1% (%2%), Giá vốn không gồm thuế GTGT: %3% (%4%)';
											|ru = 'Себестоимость с НДС: %1% (%2%), Себестоимость без НДС: %3% (%4%)';
											|en = 'Cost including VAT: %1% (%2%), Cost excluding VAT: %3% (%4%)'; fa = 'Cost including VAT: %1% (%2%), Cost excluding VAT: %3% (%4%)';
											|it = 'Costi di produzione con IVA: %1% (%2%), Costi di produzione senza IVA: %3% (%4%)';
											|pl = 'Koszt własny z VAT: %1% (%2%), Koszt własny bez VAT: %3% (%4%)';
											|tr = 'KDV dahil maliyet: %1% (%2), KDV hariç maliyet: %3% (%4)'");
					Else
						Presentation = NStr("vi = 'Giá vốn: %1% (%2%)';
											|ru = 'Себестоимость: %1% (%2%)';
											|en = 'Cost: %1% (%2%)'; fa = 'Cost: %1% (%2%)';
											|it = 'Costi di produzione: %1% (%2%)';
											|pl = 'Koszt własny: %1% (%2%)';
											|tr = 'Maliyet: %1% (%2%)'");
					EndIf;
				Else
					If ParametersStructure.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
						Presentation = NStr("vi = 'Giá vốn gồm thuế GTGT: %1% (%2%)';
											|ru = 'Себестоимость с НДС: %1% (%2%)';
											|en = 'Cost including VAT: %1% (%2%)'; fa = 'Cost including VAT: %1% (%2%)';
											|it = 'Costi di produzione con IVA: %1% (%2%)';
											|pl = 'Koszt własny z VAT: %1% (%2%)';
											|tr = 'KDV dahil maliyet: %1% (%2)'");
					Else
						Presentation = NStr("vi = 'Giá vốn: %1% (%2%)';
											|ru = 'Себестоимость: %1% (%2%)';
											|en = 'Cost: %1% (%2%)'; fa = 'Cost: %1% (%2%)';
											|it = 'Costi di produzione: %1% (%2%)';
											|pl = 'Koszt własny: %1% (%2%)';
											|tr = 'Maliyet: %1% (%2%)'");
					EndIf;
				EndIf;
			Else
				If ParametersStructure.UseLocal Then
					If ParametersStructure.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
						Presentation = NStr("vi = 'Kiểm soát với thuế GTGT: %1% ( %2%), Tài chính không có thuế GTGT:%3% (%4%)';
											|ru = 'Упр. с НДС: %1% (%2%), Регл. без НДС: %3% (%4%)';
											|en = 'Mgmt including VAT: %1% (%2%), Local excluding VAT: %3% (%4%)'; fa = 'Mgmt including VAT: %1% (%2%), Local excluding VAT: %3% (%4%)';
											|it = 'Gest. con IVA: %1%(%2%), Reg. senza IVA: %3% (%4%)';
											|pl = 'Zarz. z VAT: %1% (%2%), Regl. bez VAT: %3% (%4%)';
											|tr = 'KDV dahil yönetim muhasebesi: %1% (%2%), KDV haric yerel muhasebe: %3% (%4%)'");
					Else
						Presentation = NStr("vi = 'QT: %1% ( %2%), QĐ:%3% (%4%)';
											|ru = 'Упр.: %1% (%2%), Регл.: %3% (%4%)';
											|en = 'Mgmt: %1% (%2%), Local: %3% (%4%)'; fa = 'Mgmt: %1% (%2%), Local: %3% (%4%)';
											|it = 'Gest.: %1% (%2%), Reg.: %3% (%4%)';
											|pl = 'Zarz.: %1% (%2%), Regl.: %3% (%4%)';
											|tr = 'Yönetim muhasebesi: %1% (%2%), yerel muhasebe: %3% (%4%)'");
					EndIf;
				Else
					If ParametersStructure.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
						Presentation = NStr("vi = 'QT có thuế GTGT: %1% ( %2%)';
											|ru = 'Упр. с НДС: %1% (%2%)';
											|en = 'Mgmt including VAT: %1% (%2%)'; fa = 'Mgmt including VAT: %1% (%2%)';
											|it = 'Gest. con IVA: %1% (%2%)';
											|pl = 'Zarz. z VAT: %1% (%2%)';
											|tr = 'KDV dahil yönetim muhasebesi: %1% (%2%)'");
					Else
						Presentation = NStr("vi = 'QT: %1% ( %2%)';
											|ru = 'Упр.: %1% (%2%)';
											|en = 'Mgmt: %1% (%2%)'; fa = 'Mgmt: %1% (%2%)';
											|it = 'Gest.: %1% (%2%)';
											|pl = 'Zarz.: %1% (%2%)';
											|tr = 'Yönetim muhasebesi: %1% (%2%)'");
					EndIf;
				EndIf;
			EndIf;
			Presentation = StrReplace(Presentation, "%1%", Format(CurrentRow.Cost_, "NFD=2; NZ=0"));
			Presentation = StrReplace(Presentation, "%3%", Format(CurrentRow.CostLocal, "NFD=2; NZ=0"));
			If Not ParametersStructure.Property("LocalAccountingCurrencyPresentation") Then
				ParametersStructure.Insert("LocalAccountingCurrencyPresentation", 
					String(ParametersStructure.LocalAccountingCurrency));
			EndIf;
			
			If Not ParametersStructure.Property("ManagementAccountingCurrencyPresentation") Then
				ParametersStructure.Insert("ManagementAccountingCurrencyPresentation", 
					String(ParametersStructure.ManagementAccountingCurrency));
			EndIf;
			
			Presentation = StrReplace(Presentation, "%2%",
				ParametersStructure.ManagementAccountingCurrencyPresentation);
				
			Presentation = StrReplace(Presentation, "%4%",
				ParametersStructure.LocalAccountingCurrencyPresentation);
		EndIf;
		CurrentRow.MethodForDeterminingTheCostOfALine = Presentation;
		
	EndIf;
	
EndProcedure

// Fills in the cost determination method with the line
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInMethodForDeterminingCost(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var CostDefiningMethod;
	
	If StructureOfActions.Property("FillInMethodForDeterminingCost", CostDefiningMethod)
		And CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "CostDefiningMethod") Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentSalesOfGoodsAndServices") And ValueIsFilled(CurrentRow.DocumentSalesOfGoodsAndServices) Then
			CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromSalesDocument");
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentTransfers_") And ValueIsFilled(CurrentRow.DocumentTransfers_) Then
			CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.FromTransferDocument");
		Else
			CurrentRow.CostDefiningMethod = CostDefiningMethod;
		EndIf;
	EndIf;
	
EndProcedure

// Recalculates the amount of tax accounting in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateSumOfNuvInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("RecalculateAmountTa") Then
		CurrentRow.AmountFA = CurrentRow.SumCompl - CurrentRow.AmountPermanentDifferences
			- ?(StructureOfActions.Property("RecalculateAmountOfTD"), 0, CurrentRow.AmountTemporaryDifferences);
		
	EndIf;
	
EndProcedure

// Recalculates the amount of the time difference in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountOfVRVTS(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("RecalculateAmountOfTD") Then
		CurrentRow.AmountTemporaryDifferences = CurrentRow.SumCompl - CurrentRow.AmountFA - CurrentRow.AmountPermanentDifferences;
	EndIf;
	
EndProcedure

// Returns a structure containing fields for recalculating the number of packages in the table part of the document.
//
// Parameters:
//  FieldNameQuantity         - String - Name of the field that counts the number of packages.
//  FieldNameNumberOfPackages - String - Name of the field to enter the calculated number of packages in.
//
// Returns:
//  Structure - contains fields for recalculating the number of packages in the tabular part of the document,
//              Rows - Array - contains data type elements of the Collection element, links to rows for recalculating amounts,
//              Total Quantity - Number - the sum of the values in the "Quantity" field in the rows passed in the "Rows" parameter.
//
Function StructureOfRecalculationOfNumberOfPackages(FieldNameQuantity = "Count", FieldNameNumberOfPackages = "NumberOfPackages") Export

	Result = New Structure;
	Result.Insert("Products");
	Result.Insert("Package");
	Result.Insert(FieldNameQuantity, FieldNameNumberOfPackages);
	
	Return Result;

EndFunction

// Fills the storage location in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow        - Structure - structure with the string properties of the document.
//	StructureOfActions    - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInDefaultStorageLocationType(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("FillInDefaultStorageLocationType", FillParameters) Then
		Return;
	EndIf;
	
	CurrentRow.StorageType = PredefinedValue(FillParameters.StorageType);
	
EndProcedure

// Fills in the purpose of providing a separate need for materials and semi-finished products produced in the process for the current line of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInPurposeOfProvisionInProductionPhase(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If Not StructureOfActions.Property("FillInPurposeOfProvisionInProductionPhase", ActionParameters) Then
		Return;
	EndIf;
	
	If CurrentRow.Produced Then
		ActionParameters.Property("AssignmentSemiFinishedProducts", CurrentRow.SupplyAssignment);
	Else
		ActionParameters.Property("AssignmentMaterials", CurrentRow.SupplyAssignment);
	EndIf;
	
	CurrentRow.Purpose = ?(CurrentRow.WithAssignment,
		CurrentRow.SupplyAssignment,
		PredefinedValue("Catalog.Assignments.EmptyRef"));
	
EndProcedure

// Fills in the Assignment at the end of the stage.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInAssignmentInProductionPhase(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If Not StructureOfActions.Property("FillInAssignmentInProductionPhase") Then
		Return;
	EndIf;
	
	CurrentRow.Purpose = ?(CurrentRow.WithAssignment,
		CurrentRow.SupplyAssignment,
		PredefinedValue("Catalog.Assignments.EmptyRef"));
	
EndProcedure

// Fills in the release direction for the current line in the table part of the "Production without order" document"
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInReleaseDirection(CurrentRow, StructureOfActions, CachedValues) Export

	Var ActionParameters;
	
	If Not StructureOfActions.Property("FillInReleaseDirection", ActionParameters) Then
		Return;
	EndIf;

	If ActionParameters.Property("UseWriteOffForExpenses")
	   And ActionParameters.UseWriteOffForExpenses = True
	   And CurrentRow.DirectionOfProductionIssue =
	   		PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		Return;	   			
	EndIf;   			
			
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		
		CurrentRow.DirectionOfProductionIssue = 
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit");
			
	Else
		
		CurrentRow.DirectionOfProductionIssue = 
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
			
	EndIf; 
	
EndProcedure

// Recalculates the number of packages in the rows of the tabular part when selecting the CCD kit number.
//
// Parameters:
//	CurrentRow - FormDataStructure, Structure - The Cur line for which the CCD set number was selected.
//	NewRow - FormDataStructure, Structure - a new line for which the residual CCD Number of the kit has been selected.
//	FieldNameNumberOfPackages - String - the name of the number of packages field for which recalculation is performed.
//
Procedure RecalculateNumberOfPackagesWhenSelectingCCDNumber(CurrentRow,
															NewRow,
															FieldNameNumberOfPackages = "NumberOfPackages") Export
	
	NumberOfPackagesPerLine	= CurrentRow[FieldNameNumberOfPackages];
	WholeNumberOfPackages		= CurrentRow[FieldNameNumberOfPackages]
									- Int(CurrentRow[FieldNameNumberOfPackages]) = 0;
	
	If WholeNumberOfPackages Then
		If CurrentRow[FieldNameNumberOfPackages] > 1 Then
			CurrentRow[FieldNameNumberOfPackages]	= CurrentRow[FieldNameNumberOfPackages] - 1;
			NewRow[FieldNameNumberOfPackages]		= 1;
		Else
			CurrentRow[FieldNameNumberOfPackages]	= CurrentRow[FieldNameNumberOfPackages] / 2;
			NewRow[FieldNameNumberOfPackages]		= CurrentRow[FieldNameNumberOfPackages];
		EndIf;
	Else
		If CurrentRow[FieldNameNumberOfPackages] > 1 Then
			CurrentRow[FieldNameNumberOfPackages] = Int(CurrentRow[FieldNameNumberOfPackages]);
		Else
			CurrentRow[FieldNameNumberOfPackages] = CurrentRow[FieldNameNumberOfPackages] / 2;
		EndIf;
		
		NewRow[FieldNameNumberOfPackages] = NumberOfPackagesPerLine - CurrentRow[FieldNameNumberOfPackages];
	EndIf;
	
EndProcedure

// Fills in the 'Room' field in the row with the default value (for example, the value from the header).
//
// Parameters:
//  CurrentRow - FormDataStructure, Structure - the line to fill in the field for 'The room'.
//  StructureOfActions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See GetStructureOfCachedValues
//
Procedure FillInSpaceInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If StructureOfActions.Property("FillInSpaceInTSLine") Then
		CurrentRow.Premise = StructureOfActions.FillInSpaceInTSLine;
	EndIf;
	
EndProcedure

// Fills in the field 'TYPEERAGTD' with the default value.
//
// Parameters:
//	CurrentRow - FormDataStructure, Structure - the line for which you want to fill in the 'TYPEERAGTD' field.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//
Procedure FillInDefaultCCDNumberType(CurrentRow, StructureOfActions) Export
	
	If StructureOfActions.Property("FillInCCDNumberType") Then
		CurrentRow.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.EmptyRef");
	EndIf;
	
EndProcedure

// Fills in the 'Country of origin' field with the default value.
//
// Parameters:
//	CurrentRow - FormDataStructure, Structure - the line for which you want to fill in the 'TYPEERAGTD' field.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//
Procedure FillInCountryOfOriginForDefaultCCDNumber(CurrentRow, StructureOfActions) Export
	
	If StructureOfActions.Property("FillInCountryOfOriginForCCDNumber") Then
		CurrentRow.OriginCountry = PredefinedValue("Catalog.WorldCountries.EmptyRef");
	EndIf;
	
EndProcedure

// Get the packing coefficient of the item to recalculate the quantity.
// 
// Parameters:
//  CurPackaging - CatalogRef.PackagesAndUnitsOfMeasure - The package for which you want to get the packing coefficient.
//  CachedValues See GetStructureOfCachedValues
//  CurProducts - Undefined - Cur Products
// 
// Returns:
//  Structure - Get The Packing Ratio:
// * ZoomRatio - Number - conversion factor.
// * NeedToRoundUpQuantity - Boolean - Indicates the need to round up the quantity.
//
Function GetPackingRatio(CurPackaging, CachedValues, CurProducts = Undefined) Export
	
	Result = New Structure("ZoomRatio,NeedToRoundUpQuantity");
	
	If ValueIsFilled(CurPackaging) Then
		CoefficientKey = PackingCacheKey(CurProducts, CurPackaging); 
		Cache = CachedValues.PackingFactors[CoefficientKey];
		If Cache = Undefined Then
			AttributesValues = BatchTableProcessingServerCall.PackingInformation(
				CurProducts, CurPackaging, CachedValues);
			Result.ZoomRatio    		   =  AttributesValues.ZoomRatio;
			Result.NeedToRoundUpQuantity =  AttributesValues.NeedToRoundUpQuantity;
		Else
			Result = Cache;
		EndIf;
	Else
		Result.ZoomRatio = 1;
		Result.NeedToRoundUpQuantity = False;
	EndIf;
	
	Return Result;
	
EndFunction

// Fills in the Presentation of the purchase conditions in the table row
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInPresentationOfTermsOfPurchase(CurrentRow, StructureOfActions, CachedValues) Export
	
	If Not StructureOfActions.Property("FillInPresentationOfTermsOfPurchase") Then
		Return;
	EndIf;
	
	CurrentRow.PresentationOfTermsOfPurchase = PresentationOfTermsOfPurchase(
		String(CurrentRow.Partner), // Using the Presentation cache
		CurrentRow.Sum,
		CurrentRow.AmountIncludingVAT);
	
EndProcedure

// Generates a string Presentation of the purchase terms
// Parameters:
//  PartnerPresentation_ - String - The supplier providing the conditions
//  Sum - Number - VAT exclusive
//  AmountIncludingVAT - Number - VAT inclusive
// Returns:
//  String - Presentation of the Terms of Purchase
Function PresentationOfTermsOfPurchase(PartnerPresentation_, Sum, AmountIncludingVAT) Export

	PurchaseConditionsHaveBeenFilledIn = False;
	If Not ValueIsFilled(PartnerPresentation_) Then
		Partner = NStr("ru = '<Не выбран>';
						|vi = '<Not selected>';
						|en = '<Not selected>'; fa = '<Not selected>';
						|it = '<non è selezionato>';
						|pl = '<Nie wybrany>';
						|tr = '<seçilmedi>'");
	Else
		PurchaseConditionsHaveBeenFilledIn = True;
		Partner = PartnerPresentation_;
	EndIf;
	
	If ValueIsFilled(Sum) Then
		PurchaseConditionsHaveBeenFilledIn = True;
	EndIf;
	
	PresentationText = "";
	If PurchaseConditionsHaveBeenFilledIn Then
		
		If Sum = AmountIncludingVAT Then
			PresentationText = StrTemplate(
				"%1 %2",
				Partner,
				Format(AmountIncludingVAT, "NFD=2"));
		Else
			PresentationText = StrTemplate(
				NStr("ru = '%1 %2 (%3 с НДС)';
					|vi = '%1 %2 (%3 including VAT)';
					|en = '%1 %2 (%3 including VAT)'; fa = '%1 %2 (%3 including VAT)';
					|it = '%1 %2 (%3 including VAT)';
					|pl = '%1 %2 (%3 including VAT)';
					|tr = '%1 %2 (%3 KDV dahil)'"),
				Partner,
				Format(Sum, "NFD=2"),
				Format(AmountIncludingVAT, "NFD=2"));
		EndIf; 
	
	EndIf;
	
	Return PresentationText;
	
EndFunction

// Fills in the "Charge to expenses" field and resets the division if necessary.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure FillInWriteOFFAttributeForExpensesAndDivision(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ActionParameters;
	
	If Not StructureOfActions.Property("FillInWriteOFFAttributeForExpensesAndDivision", ActionParameters) Then
		Return;
	EndIf;
	
	ThisIsInvoiceForGoods = False;
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("ThisIsInvoiceForGoods") Then
		ThisIsInvoiceForGoods = ActionParameters.ThisIsInvoiceForGoods;
	EndIf;
	
	ThisIsInvoiceForServicesAndWorks = False;
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("ThisIsInvoiceForServicesAndWorks") Then
		ThisIsInvoiceForServicesAndWorks = ActionParameters.ThisIsInvoiceForServicesAndWorks;
	EndIf;
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
		Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
		
		If ValueIsFilled(CurrentRow.Purpose) Or ThisIsInvoiceForGoods Then
			CurrentRow.ToExpenseAs = False; 
			CurrentRow.Department = Undefined;
		ElsIf Not CurrentRow.ToExpenseAs Then
			CurrentRow.Department = Undefined;
		EndIf;
		
	ElsIf CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		If ValueIsFilled(CurrentRow.Purpose) Or ThisIsInvoiceForServicesAndWorks Then
			CurrentRow.ToExpenseAs = False; 
		EndIf;
		If CurrentRow.AssignmentType = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal")
			Or ThisIsInvoiceForServicesAndWorks Then
			CurrentRow.Department = Undefined;
		EndIf;
		
	ElsIf CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		If ThisIsInvoiceForServicesAndWorks Then
			CurrentRow.ToExpenseAs = False;
			CurrentRow.Department = Undefined;
		Else
			CurrentRow.ToExpenseAs = True;
		EndIf;
	EndIf;

EndProcedure


#EndRegion

#EndRegion

#Region Internal

Function GetCurLine(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters = Undefined) Export
	
	StructureOfTSFields = FieldsOfActionLine(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters);
	
	FillPropertyValues(StructureOfTSFields, CurrentRow);
	
	If Not AdditionalFillingParameters = Undefined Then
		FillPropertyValues(StructureOfTSFields, AdditionalFillingParameters);
	EndIf;
	
	Return StructureOfTSFields;
	
EndFunction

Function FieldsOfActionLine(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters = Undefined) Export

	Var StructureOfActionParameters;
	
	CachedValues.Insert("TSFieldStructureIsComplete", New Structure);
	CachedValues.Insert("DescriptionOfFieldsByAction", New Structure);
	CachedValues.Insert("EditableFields", New Structure);
	CachedValues.Insert("ReadableFields", New Structure);
	
	ActionsOfInventoryInOperation = InventoryInOperationClientServer.FieldsOfActionLine(
		CurrentRow,
		StructureOfActions,
		CachedValues,
		AdditionalFillingParameters);
		
	For Each Action In ActionsOfInventoryInOperation Do
		AddFieldDescriptions(Action.Name, Action.ReadableFields, Action.EditableFields, CachedValues);
	EndDo;
	
	RebatesClientServer.FieldsOfActionLine(
		CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	If StructureOfActions.Property(ActionName, StructureOfActionParameters) Then
		
		AddFieldDescriptions(ActionName,
			New Structure(StructureOfActionParameters[ActionName].ReadableFields),
			New Structure(StructureOfActionParameters[ActionName].EditableFields),
			CachedValues);
			
	EndIf;
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	If StructureOfActions.Property(ActionName, StructureOfActionParameters) Then
		
		AddFieldDescriptions(ActionName,
			New Structure(StructureOfActionParameters[ActionName].ReadableFields),
			New Structure(StructureOfActionParameters[ActionName].EditableFields),
			CachedValues);
			
	EndIf;
	
	ActionName = "FillInSenderSControlledLotReference";
	If StructureOfActions.Property(ActionName, StructureOfActionParameters) Then
		
		AddFieldDescriptions(ActionName,
			New Structure(StructureOfActionParameters[ActionName].ReadableFields),
			New Structure(StructureOfActionParameters[ActionName].EditableFields),
			CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("CheckSoftwareInSalesDocument", StructureOfActionParameters) Then
		
		ReadableFields = ProvisionInDocumentsClientServer.BatchProcessingStructureOfFieldsOfCurrentLine(
			StructureOfActionParameters);
		
		EditableFields = New Structure();
		EditableFields.Insert("SupplyOption");
		EditableFields.Insert("WithAssignment");
		
		AddFieldDescriptions("CheckSoftwareInSalesDocument",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("WhenChangingTypeOfProductOrSoftwareOption",
		StructureOfActionParameters) Then
		
		ReadableFields = ProvisionInDocumentsClientServer.BatchProcessingStructureOfFieldsOfCurrentLine(
			StructureOfActionParameters);
		
		EditableFields = New Structure();
		EditableFields.Insert("DateOfShipmentRequired_");
		EditableFields.Insert("WarehouseIsRequired");
		
		AddFieldDescriptions("WhenChangingTypeOfProductOrSoftwareOption",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckNeedToUpdateColumnIsAvailable")
			Or StructureOfActions.Property("UpdateProductCache_") Then
		
		ReadableFields = New Structure();
		ReadableFields = ProvisionInDocumentsClientServer.FieldStructureCheckIfColumnUpdatesAreAvailable();
		
		EditableFields = New Structure();
		
		AddFieldDescriptions("CheckNeedToUpdateColumnIsAvailable,UpdateProductCache_",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInAvailableColumn", StructureOfActionParameters) Then
		
		ReadableFields = ProvisionInDocumentsClientServer.BatchProcessingStructureOfFieldsOfCurrentLine(
			StructureOfActionParameters);
		
		EditableFields = New Structure();
		EditableFields.Insert("Available");
		EditableFields.Insert("ReallocateInventory");
		EditableFields.Insert("ShipIfAvailable");
		
		AddFieldDescriptions("FillInAvailableColumn",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("FillInSpaceInTSLine", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Premise");
		
		AddFieldDescriptions("FillInSpaceInTSLine",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("FillInShipForOrderPlusImplementationOption") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("RegistrationOption");
		
		EditableFields = New Structure();
		EditableFields.Insert("SupplyOption");
		
		AddFieldDescriptions("FillInShipForOrderPlusImplementationOption",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInPurposeOfProvisionInProductionPhase") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("WithAssignment");
		ReadableFields.Insert("Produced");
		ReadableFields.Insert("ItemsType");
		
		EditableFields = New Structure();
		EditableFields.Insert("SupplyAssignment");
		EditableFields.Insert("Purpose");
		
		AddFieldDescriptions("FillInPurposeOfProvisionInProductionPhase",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInAssignmentInProductionPhase") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("WithAssignment");
		ReadableFields.Insert("SupplyAssignment");
		
		EditableFields = New Structure();
		EditableFields.Insert("Purpose");
		
		AddFieldDescriptions("FillInAssignmentInProductionPhase",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("CheckCharacteristicsByOwner") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		
		EditableFields = New Structure();
		EditableFields.Insert("Characteristic");
		EditableFields.Insert("ItemVariantsAreUsed");
		
		AddFieldDescriptions("CheckCharacteristicsByOwner",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckFillPackageByOwner") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		
		EditableFields = New Structure();
		EditableFields.Insert("Package");
		
		AddFieldDescriptions("CheckFillPackageByOwner",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("ClearExpenseAnalytics_", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert(StructureOfActionParameters.ExpenseItem);
		EditableFields.Insert(StructureOfActionParameters.DimensionOfExpenses);
		For Each Column In StructureOfActionParameters.AdditionalColumns Do
			EditableFields.Insert(Column);
		EndDo;
		
		AddFieldDescriptions("ClearExpenseAnalytics_",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("InitializeArticleAndAnalyticsAfterAddingLine", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		For Each Column In StructureOfActionParameters.TabularSectionColumns Do
			EditableFields.Insert(Column);
		EndDo;
		
		AddFieldDescriptions("InitializeArticleAndAnalyticsAfterAddingLine",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInTheDefaultAccountSetting", StructureOfActionParameters) Then
		
		AccountSettingsData_1 = StructureOfActionParameters.AccountSettingsData_1;
	
		ReadableFields = New Structure();
		EditableFields = New Structure();
		
		For Each SetupParameters In AccountSettingsData_1.ArrayOfSettings Do
			ReadableFields.Insert(SetupParameters.AssetAndLiabilityItem);
			ReadableFields.Insert(SetupParameters.AssetsLiabilitiesDimension);
			If Not IsBlankString(SetupParameters.ArticleType) Then
				ReadableFields.Insert(SetupParameters.ArticleType);
			EndIf;
			
			EditableFields.Insert(SetupParameters.GLAccountSettings);
			EditableFields.Insert(SetupParameters.AssetsLiabilitiesDimension);
			EditableFields.Insert(SetupParameters.Presentation);
		EndDo;
		
		AddFieldDescriptions("FillInTheDefaultAccountSetting",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInInvoiceSettingsPresentation", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		For Each Column In StructureOfActionParameters.TabularSectionColumns Do
			EditableFields.Insert(Column);
		EndDo;
		
		AddFieldDescriptions("FillInInvoiceSettingsPresentation",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfUnits", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Package");
		ReadableFields.Insert("NumberOfPackages", 0);
		
		If  StructureOfActionParameters <> Undefined 
			And StructureOfActionParameters.Property("MustBeRoundOff")
			And CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "MustBeRoundOff") Then
				ReadableFields.Insert("MustBeRoundOff");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("Count", 0);
		
		AddFieldDescriptions("RecalculateNumberOfUnits",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfPackages") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Package");
		ReadableFields.Insert("Count", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfPackages", 0);
		
		AddFieldDescriptions("RecalculateNumberOfPackages",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateQuantityByRNPT") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic",
			PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
			
		ReadableFields.Insert("CCDNumber");
		ReadableFields.Insert("AccountingForTheRNPTIsMaintained");
		ReadableFields.Insert("Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
		If StructureOfActions.RecalculateQuantityByRNPT.StorageLocationInTabularPart Then
			ReadableFields.Insert(StructureOfActions.RecalculateQuantityByRNPT.StorageLocationFieldName);
		EndIf;
		FieldNameQuantity = "Count";
		If StructureOfActions.RecalculateQuantityByRNPT.Property("FieldNamesWithSuffix")
			And ValueIsFilled(StructureOfActions.RecalculateQuantityByRNPT.FieldNamesWithSuffix) Then
			
			If CommonClientServer.HasAttributeOrObjectProperty(StructureOfActions.RecalculateQuantityByRNPT.FieldNamesWithSuffix, "Count") Then
				FieldNameQuantity = StructureOfActions.RecalculateQuantityByRNPT.FieldNamesWithSuffix.Count;
			EndIf;
			
		EndIf;
		ReadableFields.Insert(FieldNameQuantity);
		
		EditableFields = New Structure();
		If StructureOfActions.RecalculateQuantityByRNPT.Property("FieldNamesWithSuffix")
			And ValueIsFilled(StructureOfActions.RecalculateQuantityByRNPT.FieldNamesWithSuffix) Then
			EditableFields.Insert(StructureOfActions.RecalculateQuantityByRNPT.FieldNamesWithSuffix.QuantityByGBRN);
		Else
			EditableFields.Insert("QuantityByGBRN");
		EndIf;
		
		AddFieldDescriptions("RecalculateQuantityByRNPT",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("RecalculateQuantityByRNPTSuffix", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic",
			PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
			
		ReadableFields.Insert("CCDNumber");
		ReadableFields.Insert("AccountingForTheRNPTIsMaintained");
		ReadableFields.Insert("Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"));
		If StructureOfActions.RecalculateQuantityByRNPTSuffix.StorageLocationInTabularPart Then
			ReadableFields.Insert(StructureOfActions.RecalculateQuantityByRNPTSuffix.StorageLocationFieldName);
		EndIf;
		FieldNameQuantity = "Count";
		If StructureOfActionParameters.Property("FieldNamesWithSuffix")
			And ValueIsFilled(StructureOfActionParameters.FieldNamesWithSuffix) Then
			
			If StructureOfActionParameters.FieldNamesWithSuffix.Property("Count") Then
				FieldNameQuantity = StructureOfActionParameters.FieldNamesWithSuffix.Count;
			EndIf;
			
		EndIf;
		ReadableFields.Insert(FieldNameQuantity);
		
		EditableFields = New Structure();
		NameOfQuantityFieldAccordingToRNPT = "QuantityByGBRN";
		If StructureOfActionParameters.Property("FieldNamesWithSuffix")
			And ValueIsFilled(StructureOfActionParameters.FieldNamesWithSuffix) Then
			
			If StructureOfActionParameters.FieldNamesWithSuffix.Property("QuantityByGBRN") Then
				NameOfQuantityFieldAccordingToRNPT = StructureOfActionParameters.FieldNamesWithSuffix.QuantityByGBRN;
			EndIf;
			
		EndIf;
		EditableFields.Insert(NameOfQuantityFieldAccordingToRNPT);
		
		AddFieldDescriptions("RecalculateQuantityByRNPTSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInDiscrepancyAttributeOrder") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("RowCode");
		
		EditableFields = New Structure();
		EditableFields.Insert("OrderDiscrepancy_3");
		
		AddFieldDescriptions("FillInDiscrepancyAttributeOrder",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInGTINInLine", StructureOfActionParameters)  Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		EditableFields = New Structure();
		EditableFields.Insert("GTIN");
		
		AddFieldDescriptions("FillInGTINInLine",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("RecalculateSumWithVATSuffix", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		SumWithSuffix = SumWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
		ReadableFields.Insert(SumWithSuffix.Sum, 0);
		ReadableFields.Insert(SumWithSuffix.VATAmount, 0);
		
		EditableFields = New Structure();
		EditableFields.Insert(SumWithSuffix.AmountIncludingVAT, 0);
		
		AddFieldDescriptions("RecalculateSumWithVATSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfSuffixUnits", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Package");
		QuantityWithSuffix = QuantityWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
			
		ReadableFields.Insert(QuantityWithSuffix.NumberOfPackages, 0);
		
		EditableFields = New Structure();
		EditableFields.Insert(QuantityWithSuffix.Count, 0);
		
		AddFieldDescriptions("RecalculateNumberOfSuffixUnits",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfSuffixPacks", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Package");
		QuantityWithSuffix = QuantityWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
			
		ReadableFields.Insert(QuantityWithSuffix.Count, 0);
		
		EditableFields = New Structure();
		EditableFields.Insert(QuantityWithSuffix.NumberOfPackages, 0);
		
		AddFieldDescriptions("RecalculateNumberOfSuffixPacks",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountOfDeviation") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Package");
		ReadableFields.Insert("CountReal", 0);
		ReadableFields.Insert("NumberOfPackagesReal", 0);
		ReadableFields.Insert("Count", 0);
		ReadableFields.Insert("NumberOfPackages", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("DeviationInStorageUnits", 0);
		EditableFields.Insert("NumberOfPackagesDiscrepancy", 0);
		
		AddFieldDescriptions("RecalculateAmountOfDeviation",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf; 
	
	If StructureOfActions.Property("RecalculateNumberOfSuffixPacksFromDeviation", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackagesDiscrepancy", 0);
		ReadableFields.Insert("NumberOfPackages", 0);
		
		EditableFields = New Structure();
		QuantityWithSuffix = QuantityWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
		EditableFields.Insert(QuantityWithSuffix.NumberOfPackages, 0);
		
		AddFieldDescriptions("RecalculateNumberOfSuffixPacksFromDeviation",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateWeightVolume", StructureOfActionParameters) Then
		
 		ReadableFields = New Structure();
		ReadableFields.Insert("PackageWeight", 0);
		ReadableFields.Insert("PackageVolume", 0);
		QuantityWithSuffix = QuantityWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
		ReadableFields.Insert(QuantityWithSuffix.NumberOfPackages, 0);
		ReadableFields.Insert("UnitOfMeasureForWeight");
		ReadableFields.Insert("UnitOfMeasureForVolume");
		
		EditableFields = New Structure();
		EditableFields.Insert("Weight", 0);
		EditableFields.Insert("VolumeM3", 0);
		
		AddFieldDescriptions("RecalculateWeightVolume",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	Suffix = Undefined;
	
	If StructureOfActions.Property("RecalculateNumberOfPackagesByWeight", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("PackageWeight", 0);
		ReadableFields.Insert("PackageVolume", 0);
		ReadableFields.Insert("Weight", 0);
		ReadableFields.Insert("Package");
		ReadableFields.Insert("Products");
		ReadableFields.Insert("UnitOfMeasureForWeight");
		ReadableFields.Insert("UnitOfMeasureForVolume");
		
		EditableFields = New Structure();
		EditableFields.Insert("VolumeM3", 0);
		QuantityWithSuffix = QuantityWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
		EditableFields.Insert(QuantityWithSuffix.NumberOfPackages, 0);
		EditableFields.Insert(QuantityWithSuffix.Count, 0);
		
		AddFieldDescriptions("RecalculateNumberOfPackagesByWeight",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfPackagesByVolume", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("PackageWeight", 0);
		ReadableFields.Insert("PackageVolume", 0);
		ReadableFields.Insert("VolumeM3", 0);
		ReadableFields.Insert("Package");
		ReadableFields.Insert("Products");
		ReadableFields.Insert("UnitOfMeasureForWeight");
		ReadableFields.Insert("UnitOfMeasureForVolume");
		
		EditableFields = New Structure();
		EditableFields.Insert("Weight", 0);
		QuantityWithSuffix = QuantityWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
		EditableFields.Insert(QuantityWithSuffix.NumberOfPackages, 0);
		EditableFields.Insert(QuantityWithSuffix.Count, 0);
		
		AddFieldDescriptions("RecalculateNumberOfPackagesByVolume",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInPriceView") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		If StructureOfActions.FillInPriceView.Property("NameOfPriceTypeField") Then
			EditableFields.Insert(StructureOfActions.FillInPriceView.NameOfPriceTypeField);
		Else
			EditableFields.Insert("PriceKind");
		EndIf;
		
		AddFieldDescriptions("FillInPriceView",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInSalePrice") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
		
		If StructureOfActions.FillInSalePrice.Property("ColumnNamePackaging") Then
			ReadableFields.Insert(StructureOfActions.FillInSalePrice.ColumnNamePackaging);
		Else
			ReadableFields.Insert("Package");
		EndIf;
		
		EditableFields = New Structure();
		If StructureOfActions.FillInSalePrice.Property("ColumnNamePriceType") Then
			EditableFields.Insert(StructureOfActions.FillInSalePrice.ColumnNamePriceType);
		Else
			EditableFields.Insert("PriceKind");
		EndIf;
		
		If StructureOfActions.FillInSalePrice.Property("NameOfPriceField") Then
			EditableFields.Insert(StructureOfActions.FillInSalePrice.NameOfPriceField, 0);
		Else
			EditableFields.Insert("Price", 0);
		EndIf;
		
		AddFieldDescriptions("FillInSalePrice",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInSalePriceByProductRange") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
		ReadableFields.Insert("Package");
		ReadableFields.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		
		AddFieldDescriptions("FillInSalePriceByProductRange",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInDefaultSupplierAgreement", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Partner");
		ReadableFields.Insert("Terms");
		
		EditableFields = New Structure();
		EditableFields.Insert("Terms");
		
		AddFieldDescriptions("FillInDefaultSupplierAgreement",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("FillInAttributesAccordingToSupplierSAgreement", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Terms");
		
		EditableFields = New Structure;
		EditableFields.Insert("ContractsAreUsed");
		
		AddFieldDescriptions("FillInAttributesAccordingToSupplierSAgreement",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInNumberOfSupplierAgreements", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Partner");
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfAgreements");
		
		AddFieldDescriptions("FillInNumberOfSupplierAgreements",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInPartnerSDefaultCounterparty", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Partner");
		ReadableFields.Insert("Counterparty");
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Terms") Then
			ReadableFields.Insert("Terms");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("Counterparty");
		
		AddFieldDescriptions("FillInPartnerSDefaultCounterparty",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInDefaultContract", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Organization");
		ReadableFields.Insert("Partner");
		ReadableFields.Insert("Counterparty");
		ReadableFields.Insert("Contract");
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Terms") Then
			ReadableFields.Insert("Terms");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Purpose") Then
			ReadableFields.Insert("Purpose");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("Contract");
		
		AddFieldDescriptions("FillInDefaultContract",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CompleteOfOperationAccordingToAgreementContract") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Terms");
		ReadableFields.Insert("Contract");
		ReadableFields.Insert("BusinessOperation");
		
		EditableFields = New Structure;
		EditableFields.Insert("BusinessOperation");
		
		AddFieldDescriptions("CompleteOfOperationAccordingToAgreementContract",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInVATTaxationPurchases", StructureOfActionParameters) Then
		
		ReadableFields = New Structure;
		EditableFields = New Structure;
		
		ReadableFields.Insert("BusinessOperation");
		
		ReadableFields.Insert("VATTaxation");
		EditableFields.Insert("VATTaxation");
		
		AddFieldDescriptions("FillInVATTaxationPurchases",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInPurchasePrice") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Partner") Then
			ReadableFields.Insert("Partner");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Terms") Then
			ReadableFields.Insert("Terms");
		EndIf;

		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Package") Then
			ReadableFields.Insert("Package");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"VendorPriceKind") Then
			ReadableFields.Insert("VendorPriceKind");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		
		AddFieldDescriptions("FillInPurchasePrice",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInTermsOfPurchase") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Partner") Then
			ReadableFields.Insert("Partner");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Terms") Then
			ReadableFields.Insert("Terms");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Package") Then
			ReadableFields.Insert("Package");
		EndIf;
		
		EditableFields = New Structure();
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"VendorPriceKind") Then
			EditableFields.Insert("VendorPriceKind");
		EndIf;
		
		EditableFields.Insert("Price", 0);
		
		AddFieldDescriptions("FillInTermsOfPurchase",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInTheItemByThePartnerSItem") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("PartnerProducts");
		
		EditableFields = New Structure();
		EditableFields.Insert("Products");
		EditableFields.Insert("Characteristic");
		EditableFields.Insert("Package");
		EditableFields.Insert("ItemVariantsAreUsed");
		
		AddFieldDescriptions("FillInTheItemByThePartnerSItem",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillInProductNameOfProductPartner") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Package");
		
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow,
			"Partner") Then
			ReadableFields.Insert("Partner");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("PartnerProducts");
		
		AddFieldDescriptions("FillInProductNameOfProductPartner",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckMatchedPartnerProducts") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("LineNumber");
		ReadableFields.Insert("PartnerProducts");
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Package");
		
		EditableFields = New Structure();
		
		AddFieldDescriptions("CheckMatchedPartnerProducts",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInVATRate", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Period");
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentInflow") Then
			ReadableFields.Insert("DocumentInflow");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DateOfShipment") Then
			ReadableFields.Insert("DateOfShipment");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentSalesOfGoodsAndServices") Then
			ReadableFields.Insert("DocumentSalesOfGoodsAndServices");
		EndIf;
		
		If StructureOfActionParameters.Property("VATTaxationAtTabularPart")
			And StructureOfActionParameters.VATTaxationAtTabularPart Then
				ReadableFields.Insert("VATTaxation");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("VATRate");
		
		AddFieldDescriptions("FillInVATRate",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateForProductItem", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Period");
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentInflow") Then
			ReadableFields.Insert("DocumentInflow");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DateOfShipment") Then
			ReadableFields.Insert("DateOfShipment");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentSalesOfGoodsAndServices") Then
			ReadableFields.Insert("DocumentSalesOfGoodsAndServices");
		EndIf;
		
		If StructureOfActionParameters.Property("VATTaxationAtTabularPart")
			And StructureOfActionParameters.VATTaxationAtTabularPart Then
				ReadableFields.Insert("VATTaxation");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("VATRate");
		
		AddFieldDescriptions("FillInVATRateForProductItem",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateByPriceType", StructureOfActionParameters)
			Or StructureOfActions.Property("FillInVATRateSuffixByPriceType", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
		ReadableFields.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
		ReadableFields.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
		ReadableFields.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
		ReadableFields.Insert("ItemsType", PredefinedValue("Enum.ItemsTypes.EmptyRef"));
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentInflow") Then
			ReadableFields.Insert("DocumentInflow");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DateOfShipment") Then
			ReadableFields.Insert("DateOfShipment");
		EndIf;
		
		If StructureOfActionParameters.Property("VATTaxationAtTabularPart")
			And StructureOfActionParameters.VATTaxationAtTabularPart Then
				ReadableFields.Insert("VATTaxation");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("VATRate");
		
		AddFieldDescriptions("FillInVATRateByPriceType",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateForSettingUpAccountingAtCommitteeSUSN", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		If StructureOfActionParameters.Property("VATTaxationAtTabularPart")
			And StructureOfActionParameters.VATTaxationAtTabularPart Then
				ReadableFields.Insert("VATTaxation");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("VATRate");
		
		AddFieldDescriptions("FillInVATRateForSettingUpAccountingAtCommitteeSUSN",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("AdjustVATRate", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Period");
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentInflow") Then
			ReadableFields.Insert("DocumentInflow");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DateOfShipment") Then
			ReadableFields.Insert("DateOfShipment");
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentSalesOfGoodsAndServices") Then
			ReadableFields.Insert("DocumentSalesOfGoodsAndServices");
		EndIf;
		
		If StructureOfActionParameters.Property("VATTaxationAtTabularPart")
			And StructureOfActionParameters.VATTaxationAtTabularPart Then
				ReadableFields.Insert("VATTaxation");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("VATRate");
		
		AddFieldDescriptions("AdjustVATRate",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateSuffix", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		
		EditableFields = New Structure();
		RateWithSuffix = RateWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
		EditableFields.Insert(RateWithSuffix.VATRate);

		EditableFields.Insert("VATRate");
		
		AddFieldDescriptions("FillInVATRateSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInHSCode") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		
		EditableFields = New Structure();
		EditableFields.Insert("FEACNCode");
		
		AddFieldDescriptions("FillInHSCode",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInVATRateForReturnableContainers") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("ItemsType");
		
		EditableFields = New Structure();
		EditableFields.Insert("VATRate");
		
		AddFieldDescriptions("FillInVATRateForReturnableContainers",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("RecalculateVATAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Sum", 0);
		ReadableFields.Insert("VATRate", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("VATAmount", 0);
		
		AddFieldDescriptions("RecalculateVATAmount",
			ReadableFields, EditableFields, CachedValues)
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountWithVAT") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Sum", 0);
		ReadableFields.Insert("VATAmount", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountIncludingVAT", 0);
		
		AddFieldDescriptions("RecalculateAmountWithVAT",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("RecalculateAmountWithoutVAT") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Sum", 0);
		ReadableFields.Insert("VATAmount", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountExcludingVAT", 0);
		
		AddFieldDescriptions("RecalculateAmountWithoutVAT",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("RecalculateLocalAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AmountExcludingVAT", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("SumCompl", 0);
		
		AddFieldDescriptions("RecalculateLocalAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("RecalculateLocalVAT") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("VATAmount" , 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("VATLocal", 0);
		
		AddFieldDescriptions("RecalculateLocalVAT",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("RecalculateAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Price", 0);
		ReadableFields.Insert(?(IsBlankString(StructureOfActions.RecalculateAmount),
			"NumberOfPackages", StructureOfActions.RecalculateAmount), 0);
			
		EditableFields = New Structure();
		EditableFields.Insert("Sum", 0);
		
		AddFieldDescriptions("RecalculateAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateSuffixAmount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();

		ActionSuffix = ActionSuffix(StructureOfActionParameters);
		
		QuantityWithSuffix = QuantityWithSuffix(
			ActionSuffix.Suffix);
			
		ReadableFields.Insert(?(IsBlankString(ActionSuffix.QuantityName), 
									QuantityWithSuffix.NumberOfPackages,
									QuantityWithSuffix[ActionSuffix.QuantityName]), 0);

		NameOfPriceField = PriceWithSuffix(ActionSuffix.Suffix);
		ReadableFields.Insert(NameOfPriceField, 0);

		EditableFields = New Structure();
		SumWithSuffix = SumWithSuffix(ActionSuffix.Suffix);
		EditableFields.Insert(SumWithSuffix.Sum, 0);

		AddFieldDescriptions("RecalculateSuffixAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateVATAmountSuffix", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		Suffix = ActionSuffix(StructureOfActionParameters).Suffix;
	
		SumWithSuffix = SumWithSuffix(Suffix);
		ReadableFields.Insert(SumWithSuffix.Sum, 0);
		
		RateWithSuffix = RateWithSuffix(Suffix);
		ReadableFields.Insert(RateWithSuffix.VATRate , 0);
		
		EditableFields = New Structure();
		EditableFields.Insert(SumWithSuffix.VATAmount, 0);
		
		AddFieldDescriptions("RecalculateVATAmountSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfActionParameters) Then
		
		EditableFields = New Structure();
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Count", 0);
		ReadableFields.Insert("ManualDiscount", 0);
		
		RecalculateAmountOfManualDiscount_ = Undefined;
		QuantityName = Undefined;
		
		If StructureOfActionParameters <> Undefined Then
			
			StructureOfActionParameters.Property("RecalculateAmountOfManualDiscount_", RecalculateAmountOfManualDiscount_);
			StructureOfActionParameters.Property("QuantityName", QuantityName);
			
			If Not ValueIsFilled(QuantityName) Then
				QuantityName = "NumberOfPackages";
			EndIf;
			
		EndIf;
		
		If RecalculateAmountOfManualDiscount_ = False Then
			
		Else
			ReadableFields.Insert(QuantityName, 0);
			ReadableFields.Insert("PercentRateOfManualDiscount", 0);
			ReadableFields.Insert("Price", 0);
			
			EditableFields.Insert("ManualDiscount", 0);
		EndIf;
		
		EditableFields.Insert("Sum", 0);

		EditableFields.Insert("PercentRateOfManualDiscount", 0);
		
		AddFieldDescriptions("RecalculateAmountTakingIntoAccountManualDiscount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountTakingIntoAccountAutomaticDiscount") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Sum", 0);
		EditableFields.Insert("DiscountMarkupAmount", 0);
		EditableFields.Insert("PercentRateOfAutomaticDiscountMarkup", 0);
		
		AddFieldDescriptions("RecalculateAmountTakingIntoAccountAutomaticDiscount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackages", 0);
		ReadableFields.Insert("PackagingQuantityInTheOrder", 0);
		ReadableFields.Insert("AmountOfBonusPointsToBeDebitedOnOrder", 0);
		ReadableFields.Insert("AmountOfBonusPointsToBeDebitedInCurrencyOfOrder", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("Sum", 0);
		EditableFields.Insert("AmountOfBonusPointsToDeduction", 0);
		EditableFields.Insert("AmountOfBonusPointsToDeductionInCurrency", 0);
		
		If StructureOfActionParameters <> Undefined
				And StructureOfActionParameters.Property("RecalculateAmountOfBonusPointsByLine") Then
			EditableFields.Insert("AmountOfBonusPointsToDeduction", 0);
		EndIf;
		
		AddFieldDescriptions("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculatePricePerPackage") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Count", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		
		AddFieldDescriptions("RecalculatePricePerPackage",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateOrderPricePerPackage") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Count", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("OrderPrice", 0);
		
		AddFieldDescriptions("RecalculateOrderPricePerPackage",
			ReadableFields, EditableFields, CachedValues);
	EndIf;

	If StructureOfActions.Property("RecalculateAmountOverOrder") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AmountIncludingVAT", 0);
		ReadableFields.Insert("RowCode", 1);
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountInExcessOfOrder", 0);
		
		AddFieldDescriptions("RecalculateAmountOverOrder",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("RecalculatePriceDiscountByAmountInSales", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Sum", 0);
		ReadableFields.Insert("DiscountMarkupAmount", 0);
		ReadableFields.Insert("PercentRateOfAutomaticDiscountMarkup", 0);
		ReadableFields.Insert("NumberOfPackages", 0);
		ReadableFields.Insert("Count", 0);
		ReadableFields.Insert("PriceKind");
		If StructureOfActionParameters <> Undefined
			And StructureOfActionParameters.Property("UseBonusPoints") Then
			ReadableFields.Insert("AmountOfBonusPointsToDeductionInCurrency", 0);
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		EditableFields.Insert("ManualDiscount", 0);
		EditableFields.Insert("PercentRateOfManualDiscount", 0);
		EditableFields.Insert("DiscountMarkupAmount", 0);
		EditableFields.Insert("PercentRateOfAutomaticDiscountMarkup", 0);
		
		AddFieldDescriptions("RecalculatePriceDiscountByAmountInSales",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("RecalculatePriceDiscountForAmountInPurchases") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Sum", 0);
		ReadableFields.Insert("NumberOfPackages", 0);
		ReadableFields.Insert("Count", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		EditableFields.Insert("ManualDiscount", 0);
		EditableFields.Insert("PercentRateOfManualDiscount", 0);
		
		AddFieldDescriptions("RecalculatePriceDiscountForAmountInPurchases",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckFillWarehouse", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("ItemsType");
		If TypeOf(StructureOfActionParameters) = Type("Structure")
			And StructureOfActionParameters.Property("NameOfChargeToExpensesField")
			And ValueIsFilled(StructureOfActionParameters.NameOfChargeToExpensesField) Then
			ReadableFields.Insert(StructureOfActionParameters.NameOfChargeToExpensesField);
		EndIf;
		
		EditableFields = New Structure();
		WarehouseFieldName = "Warehouse";
		If TypeOf(StructureOfActionParameters) = Type("Structure")
			And StructureOfActionParameters.Property("WarehouseFieldName") Then
			WarehouseFieldName = StructureOfActionParameters.WarehouseFieldName;
		EndIf;
		EditableFields.Insert(WarehouseFieldName);
		
		AddFieldDescriptions("CheckFillWarehouse",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInOrderWarehouseAttribute", StructureOfActionParameters) Then
		
 		ReadableFields = New Structure();
		WarehouseFieldName    = "Warehouse";
		
		If TypeOf(StructureOfActionParameters) = Type("Structure")
			And StructureOfActionParameters.Property("WarehouseFieldName") Then
			WarehouseFieldName = StructureOfActionParameters.WarehouseFieldName;
		EndIf;
		ReadableFields.Insert(WarehouseFieldName);
		
		EditableFields = New Structure();
		NameOfAttributeField = "UseWarehouseManagemantSystemForGoodsSurplusesShortages";
		If TypeOf(StructureOfActionParameters) = Type("Structure")
			And StructureOfActionParameters.Property("NameOfAttributeField") Then
			NameOfAttributeField = StructureOfActionParameters.NameOfAttributeField;
		EndIf;
		EditableFields.Insert(NameOfAttributeField);
		
		AddFieldDescriptions("FillInOrderWarehouseAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillIn_TermsOfSales") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series");
		ReadableFields.Insert("Package");
		ReadableFields.Insert("VATRate");
		ReadableFields.Insert("DeliveryPeriodDays");
		ReadableFields.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		EditableFields.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
		
		AddFieldDescriptions("FillIn_TermsOfSales",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInRetailSalesTermsAndConditions") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series");
		ReadableFields.Insert("Package");
		ReadableFields.Insert("VATRate");
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		EditableFields.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
		
		AddFieldDescriptions("FillInRetailSalesTermsAndConditions",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInTermsOfServiceSales") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("VATRate");
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		EditableFields.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
		
		AddFieldDescriptions("FillInTermsOfServiceSales",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInDetailsOfProduct") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		
		EditableFields = New Structure();
		EditableFields.Insert("KeepRecordsByCCD");
		EditableFields.Insert("IsService");
		
		AddFieldDescriptions("FillInDetailsOfProduct",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInProductTypeAttribute_", StructureOfActionParameters) 
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInProductTypeAttribute_",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInProductTypeAttribute", StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInProductTypeAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCodeAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInCodeAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillInDescriptionAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInDescriptionAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillInUnitOfMeasurementAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInUnitOfMeasurementAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInMeasuredValueTypeAttribute", StructureOfActionParameters) 
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInMeasuredValueTypeAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillPackageWeight", StructureOfActionParameters) 
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillPackageWeight",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillPackageVolume", StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillPackageVolume",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfWeight", StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInUnitOfWeight",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInVolumeUnit", StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInVolumeUnit",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInSeriesAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInSeriesAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInFeatureAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInFeatureAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCCDTrackingAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInCCDTrackingAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInUnitOfMeasurementOfFEA", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInUnitOfMeasurementOfFEA",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCountryOfOriginOfProduct", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("TheRecordsAreKeptByCCD");
		
		For Each Field In StructureOfActionParameters Do
			ReadableFields.Insert(Field.Value);
		EndDo;
		
		EditableFields = New Structure();
		EditableFields.Insert("OriginCountry");
		
		AddFieldDescriptions("FillInCountryOfOriginOfProduct",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInRnptTrackingAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInRnptTrackingAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCCDNumberType", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("CCDNumber");
		
		EditableFields = New Structure();
		EditableFields.Insert("CCDNumberType");
		
		AddFieldDescriptions("FillInCCDNumberType",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInFeatureThisIsService", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInFeatureThisIsService",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInWriteOFFAttributeForExpensesAndDivision") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("ItemsType");
		ReadableFields.Insert("Purpose");
		ReadableFields.Insert("AssignmentType");
		
		EditableFields = New Structure();
		EditableFields.Insert("ToExpenseAs");
		EditableFields.Insert("Department");
		
		AddFieldDescriptions("FillInWriteOFFAttributeForExpensesAndDivision",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("SetActive") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("PictureIndex");
		
		EditableFields = New Structure();
		EditableFields.Insert("Active");
		
		AddFieldDescriptions("SetActive",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInDescriptionOfPoorQualityProduct") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		EditableFields = New Structure();
		EditableFields.Insert("Characteristic");
		EditableFields.Insert("ItemVariantsAreUsed");
		
		AddFieldDescriptions("FillInDescriptionOfPoorQualityProduct",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillInPackagingOfLowQualityGoods") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Package");
		
		EditableFields = New Structure();
		EditableFields.Insert("Package");
		
		AddFieldDescriptions("FillInPackagingOfLowQualityGoods",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("CheckCompleteConfigurationOptionByOwner") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("ItemVariantsAreUsed");
		
		EditableFields = New Structure();
		EditableFields.Insert("ProductKit");
		
		AddFieldDescriptions("CheckCompleteConfigurationOptionByOwner",
			ReadableFields, EditableFields, CachedValues);

	EndIf;
	
	If StructureOfActions.Property("FillInDiscrepancyFlag") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("NumberOfPackagesReal");
		
		EditableFields = New Structure();
		EditableFields.Insert("Discrepancy");
		
		AddFieldDescriptions("FillInDiscrepancyFlag",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountOfDiscrepancy") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Price");
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("NumberOfPackagesByDocument");
		ReadableFields.Insert("SumByDocument");
		
		EditableFields = New Structure();
		EditableFields.Insert("Sum");
		
		AddFieldDescriptions("RecalculateAmountOfDiscrepancy",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("RecalculateNumberOfPackagesDeviation") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("NumberOfPackagesReal");
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfPackagesDiscrepancy");
		
		AddFieldDescriptions("RecalculateNumberOfPackagesDeviation",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillExcessSpoilageFlag") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("SurplusDamage");
		
		AddFieldDescriptions("FillExcessSpoilageFlag",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("ClearAmountOfSettlements") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountARAP");
		
		AddFieldDescriptions("ClearAmountOfSettlements",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("ClearAmountOfSettlementsSuffix", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();

		SumWithSuffix = SumWithSuffix(
			ActionSuffix(StructureOfActionParameters).Suffix);
		EditableFields.Insert(SumWithSuffix.AmountARAP);
		
		AddFieldDescriptions("ClearAmountOfSettlementsSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("SetVATAmountLocalMans") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("VATAmount");
		
		EditableFields = New Structure();
		EditableFields.Insert("VATAmountCompl");
		EditableFields.Insert("VATAmountMan");
		
		AddFieldDescriptions("SetVATAmountLocalMans",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("RecalculateVATAmountOfShipment", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		EditableFields = New Structure();
		
		Suffix = ActionSuffix(StructureOfActionParameters).Suffix;
		
		For Each CrntSuffix In Suffix Do 
			SumOfNDSSSuffix = SumOfNDSSSuffix(CrntSuffix);
			ReadableFields.Insert(SumOfNDSSSuffix.Sum);
			EditableFields.Insert(SumOfNDSSSuffix.VATAmount);
		EndDo;
		
		ReadableFields.Insert("VATRate");
		
		AddFieldDescriptions("RecalculateVATAmountOfShipment",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("ClearAutomaticDiscount") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("PercentRateOfAutomaticDiscountMarkup");
		EditableFields.Insert("DiscountMarkupAmount");
		
		AddFieldDescriptions("ClearAutomaticDiscount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInContent") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		EditableFields = New Structure();
		EditableFields.Insert("Content");
		
		AddFieldDescriptions("FillInContent",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInDuplicateDependentDetails", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		EditableFields = New Structure();
		
		For Each StructureField In StructureOfActionParameters Do
			ReadableFields.Insert(StructureField.Key);
			DependentDetails = New Structure(StructureField.Value);
			For Each Attribute In DependentDetails Do
				EditableFields.Insert(Attribute.Key + StructureField.Key, 0);
				ReadableFields.Insert(Attribute.Key, 0);
			EndDo;
		EndDo;
		
		AddFieldDescriptions("FillInDuplicateDependentDetails",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("ClearRewardAmount") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("CommissionAmount");
		
		AddFieldDescriptions("ClearRewardAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInItemCostAnalysisOfProductRange", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Characteristic") Then
			ReadableFields.Insert("Characteristic");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert(StructureOfActionParameters.ExpenseItem);
		EditableFields.Insert(StructureOfActionParameters.DimensionOfExpenses);
		For Each Column In StructureOfActionParameters.AdditionalColumns Do
			EditableFields.Insert(Column);
		EndDo;
		
		AddFieldDescriptions("FillInItemCostAnalysisOfProductRange",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInSalesOptionAttribute", StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInSalesOptionAttribute",
			StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInExcisableItemAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		
		EditableFields = New Structure();
		EditableFields.Insert("ExcisableGoods");
		
		AddFieldDescriptions("FillInExcisableItemAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateQuantityDoNotShip") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("NumberOfPackagesInDocument");
		ReadableFields.Insert("NumberOfPackagesInDocumentUnshipped");
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfPackagesDoNotShip");
		
		AddFieldDescriptions("RecalculateQuantityDoNotShip",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateSaleAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("SellingPrice");
		ReadableFields.Insert("AmountSalesVAT");
		
		EditableFields = New Structure();
		EditableFields.Insert("SalesAmount");
		
		AddFieldDescriptions("RecalculateSaleAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("CheckSoftwareInProductionPhase", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Purpose");
		ReadableFields.Insert("DateOfShipment");
		ReadableFields.Insert("SupplyOption");
		ReadableFields.Insert("WithAssignment");
		ReadableFields.Insert("Warehouse");
		ReadableFields.Insert("Produced");
		ReadableFields.Insert("BillOfMaterials");
		ReadableFields.Insert("Warehouse");
		ReadableFields.Insert("ItemsType");
		
		EditableFields = New Structure();
		EditableFields.Insert("SupplyOption");
		EditableFields.Insert("WithAssignment");
		EditableFields.Insert("Warehouse");
		
		AddFieldDescriptions(
			"CheckSoftwareInProductionPhase", ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("CheckFillProductionWarehouse", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Department");
		
		EditableFields = New Structure();
		FieldList = StrSplit(StructureOfActionParameters.WarehouseFieldName, ",");
		For Each WarehouseFieldName In FieldList Do
			EditableFields.Insert(WarehouseFieldName);
		EndDo;
		
		AddFieldDescriptions("CheckFillProductionWarehouse",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	If StructureOfActions.Property("RecalculateAccountingQuantityOfProducts") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfPackagesReal");
		EditableFields.Insert("NumberOfPackagesAccounting");
		
		AddFieldDescriptions("RecalculateAccountingQuantityOfProducts",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfPackagesAfterFact") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackagesReal");
		ReadableFields.Insert("NumberOfPackagesAccounting");
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfPackages");
		
		AddFieldDescriptions("RecalculateNumberOfPackagesAfterFact",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateNumberOfPackagesFactByPackages") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("NumberOfPackagesAccounting");
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfPackagesReal");
		
		AddFieldDescriptions("RecalculateNumberOfPackagesFactByPackages",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInAccountingQuantityOfProductItem") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		EditableFields = New Structure();
		EditableFields.Insert("NumberOfPackagesReal");
		EditableFields.Insert("NumberOfPackagesAccounting");
		
		AddFieldDescriptions("FillInAccountingQuantityOfProductItem",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInFlagForWhetherThereIsProductSoldJointly") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		EditableFields = New Structure();
		EditableFields.Insert("IndexGoodsSoldTogether");
		
		AddFieldDescriptions("FillInFlagForWhetherThereIsProductSoldJointly",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckRowAssortment") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("LineNumber");
		ReadableFields.Insert("ProductsInSet");
		
		EditableFields = New Structure();
		EditableFields.Insert("Products");
		
		AddFieldDescriptions("CheckRowAssortment",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInNoReturnContainerAttribute", StructureOfActionParameters)  Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("ItemsType");
		
		EditableFields = New Structure();
		EditableFields.Insert("WithoutReusablePackages");
		
		AddFieldDescriptions("FillInNoReturnContainerAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCanceledWithoutReturnableContainerAttribute", StructureOfActionParameters)  Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("ItemsType");
		ReadableFields.Insert("Canceled");
		
		EditableFields = New Structure();
		EditableFields.Insert("CanceledWithoutReusablePackages");
		
		AddFieldDescriptions("FillInCanceledWithoutReturnableContainerAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInActivityWithoutReturnableContainerAttribute", StructureOfActionParameters)  Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("ItemsType");
		ReadableFields.Insert("Active");
		
		EditableFields = New Structure();
		EditableFields.Insert("ActiveWithoutReusablePackages");
		
		AddFieldDescriptions("FillInActivityWithoutReturnableContainerAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInArticleAttribute", StructureOfActionParameters) 
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInArticleAttribute", StructureOfActionParameters, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCodeAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInCodeAttribute", StructureOfActionParameters, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillInDescriptionAttribute", StructureOfActionParameters)
		And ValueIsFilled(StructureOfActionParameters) Then
		
		AddFieldsByKeyAndValue("FillInDescriptionAttribute", StructureOfActionParameters, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("FillInPriceOfTransferringProductsToGiver") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
		ReadableFields.Insert("Package");
		
		EditableFields = New Structure();
		EditableFields.Insert("PriceKind");
		EditableFields.Insert("Price", 0);
		
		AddFieldDescriptions("FillInPriceOfTransferringProductsToGiver",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("CheckFillIssuePrice") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("UseTargetCost", True);
		ReadableFields.Insert("LineNumber");
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
		ReadableFields.Insert("Package");
		ReadableFields.Insert("PriceKind");
		ReadableFields.Insert("Currency");
		ReadableFields.Insert("Manufactured");
		
		EditableFields = New Structure();
		EditableFields.Insert("Price", 0);
		EditableFields.Insert("Sum");
		
		AddFieldDescriptions("CheckFillIssuePrice",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("SetFlagForUsingPlannedCost") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Price", 0);
		ReadableFields.Insert("Sum", 0);
		ReadableFields.Insert("ProductionDate");
		
		EditableFields = New Structure();
		EditableFields.Insert("UseTargetCost", False);
		
		AddFieldDescriptions("SetFlagForUsingPlannedCost",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;		
	If StructureOfActions.Property("FillRoom", StructureOfActionParameters)  Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Premise");
		
		AddFieldDescriptions("FillRoom",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillOutSellerSForm", StructureOfActionParameters)  Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Seller");
		
		AddFieldDescriptions("FillOutSellerSForm",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckSeriesCalculateStatus", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		EditableFields = New Structure();
		// In some cases, there is a field to specify the series, the analysis, when it is not performed.
		If StructureOfActionParameters.SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
			ReadableFields.Insert("Products");
			ReadableFields.Insert("Characteristic");
			EditableFields.Insert("BatchesIndicationStatus");
			EditableFields.Insert("Series");
		Else
			For Each NameOfStatusField In StructureOfActionParameters.SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				FieldsNames = FieldNamesBySeriesIndicationStatus(NameOfStatusField);
				EditableFields.Insert(NameOfStatusField);
				If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, FieldsNames.Series) Then
					EditableFields.Insert(FieldsNames.Series);
					ReadableFields.Insert(FieldsNames.Products);
					ReadableFields.Insert(FieldsNames.Characteristic);
				EndIf;
			EndDo;
		EndIf;
		
		For Each ArrRow In StructureOfActionParameters.SeriesSpecificationParameters.LinkFields Do
			ReadableFields.Insert(ArrRow);
		EndDo;
		
		For Each ArrRow In StructureOfActionParameters.SeriesSpecificationParameters.AdditionalFieldNames Do
			ReadableFields.Insert(ArrRow);
		EndDo;
		
		If StructureOfActionParameters.SeriesSpecificationParameters.ThisIsOrder Then
			ReadableFields.Insert("Canceled");
			ReadableFields.Insert("SupplyOption");
		EndIf;
		
		If ValueIsFilled(StructureOfActionParameters.SeriesSpecificationParameters.FieldNameQuantity) Then
			ReadableFields.Insert(StructureOfActionParameters.SeriesSpecificationParameters.FieldNameQuantity, 0);
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Purpose") Then
			ReadableFields.Insert("Purpose");
		EndIf;
		
		AddFieldDescriptions("CheckSeriesCalculateStatus",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckBatchByOwner") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Series");
		
		EditableFields = New Structure();
		EditableFields.Insert("Series");
		EditableFields.Insert("SeriesAreUsed");
		
		AddFieldDescriptions("CheckBatchByOwner",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckBarcodeRegistration") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Barcode");
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series");
		ReadableFields.Insert("Package");
		
		EditableFields = New Structure();
		EditableFields.Insert("Registered");
		
		AddFieldDescriptions("CheckBarcodeRegistration",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateDiscrepanciesAfterShipment") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("Sum");
		ReadableFields.Insert("VATAmount");
		ReadableFields.Insert("AmountIncludingVAT");
		
		ReadableFields.Insert("NumberOfDiscrepancyPackaging");
		ReadableFields.Insert("DiscrepancyAmount");
		ReadableFields.Insert("PersonalIncomeTaxExpense");
		ReadableFields.Insert("TheAmountOfTheSNDSRansmission");
		
		ReadableFields.Insert("NumberOfPackagesByDocument");
		ReadableFields.Insert("CountByDocument");
		ReadableFields.Insert("SumByDocument");
		ReadableFields.Insert("VATAmountByDocument");
		ReadableFields.Insert("AmountIncludingVATByDocument");
		ReadableFields.Insert("ThereAreDiscrepancies");
		
		EditableFields = New Structure();
		EditableFields.Insert("Action");
		EditableFields.Insert("DiscrepancyTreatment");
		
		AddFieldDescriptions("RecalculateDiscrepanciesAfterShipment",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateDiscrepanciesAfterAcceptance") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfDiscrepancyPackaging");
		ReadableFields.Insert("DiscrepancyAmount");
		ReadableFields.Insert("PersonalIncomeTaxExpense");
		ReadableFields.Insert("TheAmountOfTheSNDSRansmission");
		
		ReadableFields.Insert("Price");
		ReadableFields.Insert("VATRate");
		
		ReadableFields.Insert("NumberOfPackagesByDocument");
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("CountByDocument");
		ReadableFields.Insert("Count");
		ReadableFields.Insert("SumByDocument");
		ReadableFields.Insert("Sum");
		ReadableFields.Insert("VATAmountByDocument");
		ReadableFields.Insert("VATAmount");
		ReadableFields.Insert("AmountIncludingVATByDocument");
		ReadableFields.Insert("AmountIncludingVAT");
		ReadableFields.Insert("ThereAreDiscrepancies");
		ReadableFields.Insert("ThirdPartyIsGuilty");
		
		EditableFields = New Structure();
		EditableFields.Insert("Action");
		
		AddFieldDescriptions("RecalculateDiscrepanciesAfterAcceptance",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateDiscrepancies") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfDiscrepancyPackaging");
		ReadableFields.Insert("NumberOfPackagesByDocument");
		ReadableFields.Insert("CountByDocument");
		ReadableFields.Insert("ThereAreDiscrepancies");
		
		EditableFields = New Structure();
		EditableFields.Insert("Action");
		
		AddFieldDescriptions("RecalculateDiscrepancies",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInPlaceAttributeThatRequiresProcessing") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Barcode");
		ReadableFields.Insert("BarcodeIsNotRecognized");
		ReadableFields.Insert("ThisIsAPackingList");
		ReadableFields.Insert("PackingList");
		ReadableFields.Insert("Products");
		ReadableFields.Insert("NumberOfCompletedSubordinatePositions");
		
		EditableFields = New Structure();
		EditableFields.Insert("DataProcessorIsRequired");
		
		AddFieldDescriptions("FillInPlaceAttributeThatRequiresProcessing",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckFillAssignment") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("ItemsType");
		
		EditableFields = New Structure();
		EditableFields.Insert("Purpose");
		
		AddFieldDescriptions("CheckFillAssignment",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	PropsNameToShipSeparately = Undefined;
	If StructureOfActions.Property("FillFlagSeparatelyAsIntended", PropsNameToShipSeparately) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Purpose");
		
		EditableFields = New Structure();
		EditableFields.Insert(PropsNameToShipSeparately);
		
		AddFieldDescriptions("FillFlagSeparatelyAsIntended",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("WhenChangingDestination") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Purpose");
		
		EditableFields = New Structure();
		EditableFields.Insert("AssignmentSender");
		
		AddFieldDescriptions("WhenChangingDestination",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInTrafficFlagForWarehouseRegisters", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert(StructureOfActions.FillInDestinationAttribute);
		
		EditableFields = New Structure();
		EditableFields.Insert(StructureOfActionParameters);
		
		AddFieldDescriptions("FillInTrafficFlagForWarehouseRegisters",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	DestinationAttribute = Undefined;
	If StructureOfActions.Property("FillInDestinationAttribute", DestinationAttribute) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert(DestinationAttribute);
		
		AddFieldDescriptions("FillInDestinationAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("WhenChangingProductType", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("ItemsType");
		ReadableFields.Insert("Canceled");
		If TypeOf(StructureOfActionParameters) = Type("Structure")
			And StructureOfActionParameters.Property("ThereIsWriteOffForExpenses") Then
			ReadableFields.Insert("ToExpenseAs");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("WarehouseIsRequired");
		
		AddFieldDescriptions("WhenChangingProductType",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountOfServiceOrderGiver") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Price", 0);
		ReadableFields.Insert(?(IsBlankString(StructureOfActions.RecalculateGiverSOrderAmount),
			"NumberOfPackages", StructureOfActions.RecalculateGiverSOrderAmount), 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("Amount", 0);
		
		AddFieldDescriptions("RecalculateAmountOfServiceOrderGiver",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateGiverSOrderAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Amount", 0);
		ReadableFields.Insert("OwnMaterials", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("Sum", 0);
		
		AddFieldDescriptions("RecalculateGiverSOrderAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInOptionToReflectImplementationAdjustment") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("PostingOption");
		
		AddFieldDescriptions("FillInOptionToReflectImplementationAdjustment",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;

	If StructureOfActions.Property("FillInCountryOfOriginForCCDNumber") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("OriginCountry");
		
		AddFieldDescriptions("FillInCountryOfOriginForCCDNumber",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("CheckFillSpecification", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("ItemVariantsAreUsed");
		ReadableFields.Insert("Produced");
		
		EditableFields = New Structure();
		EditableFields.Insert(StructureOfActionParameters.FieldNameSpecification);
		
		AddFieldDescriptions("CheckFillSpecification",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInProductionDate") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Canceled");
		ReadableFields.Insert("Manufactured");
		
		EditableFields = New Structure();
		EditableFields.Insert("ProductionDate");
		
		AddFieldDescriptions("FillInProductionDate",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("FillInShopPantryAttribute", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert( 
			?(StructureOfActionParameters <> Undefined And StructureOfActionParameters.Property("WarehouseFieldName"), 
				StructureOfActionParameters.WarehouseFieldName,
				"Warehouse"));
		
		EditableFields = New Structure();
		EditableFields.Insert("ShopFloorStockroom");
		If StructureOfActionParameters <> Undefined
			And StructureOfActionParameters.Property("FillInTheDepartment")
			And StructureOfActionParameters.FillInTheDepartment Then
				EditableFields.Insert("Department");
		EndIf;
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "MustBeRoundOff") Then
			EditableFields.Insert("MustBeRoundOff");
		EndIf;
		
		AddFieldDescriptions("FillInShopPantryAttribute",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("FillInReleaseDirection", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("DirectionOfProductionIssue");
		
		AddFieldDescriptions("FillInReleaseDirection",
			EditableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("FillOutRecipientInDirectionOfIssue", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("DirectionOfProductionIssue");
		
		EditableFields = New Structure();
		EditableFields.Insert("Recipient");
		
		AddFieldDescriptions("FillOutRecipientInDirectionOfIssue",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;	
	If StructureOfActions.Property("CheckFillCommunicationKeySpecifications") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		
		EditableFields = New Structure();
		ReadableFields.Insert("LinkKeyBOM");
		
		AddFieldDescriptions("CheckFillCommunicationKeySpecifications",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("CheckFillInCostShare", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
		ReadableFields.Insert("Package");
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("Count");
		If ValueIsFilled(StructureOfActionParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
			ReadableFields.Insert(StructureOfActionParameters.FieldNameMethodOfCostAllocationForOutputProducts);
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("CostShare");
		EditableFields.Insert("CostSharePerUnit");
		
		AddFieldDescriptions("CheckFillInCostShare",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateCostShare", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		ReadableFields.Insert("Characteristic");
		ReadableFields.Insert("Series");
		ReadableFields.Insert("Package");
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("Count");
		ReadableFields.Insert("CostSharePerUnit");
		If ValueIsFilled(StructureOfActionParameters.FieldNameMethodOfCostAllocationForOutputProducts) Then
			ReadableFields.Insert(StructureOfActionParameters.FieldNameMethodOfCostAllocationForOutputProducts);
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("CostShare");
		
		AddFieldDescriptions("RecalculateCostShare",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculatePDAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AcceptedByTheKNU");
		ReadableFields.Insert("SumCompl");
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountPermanentDifferences");
		
		AddFieldDescriptions("RecalculatePDAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountTa") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("SumCompl");
		ReadableFields.Insert("AmountPermanentDifferences");
		ReadableFields.Insert("AmountTemporaryDifferences");
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountFA");
		
		AddFieldDescriptions("RecalculateAmountTa",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountOfTD") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("SumCompl");
		ReadableFields.Insert("AmountFA");
		ReadableFields.Insert("AmountPermanentDifferences");
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountTemporaryDifferences");
		
		AddFieldDescriptions("RecalculateAmountOfTD",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("FillInDefaultStorageLocationType") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("StorageType");
		
		AddFieldDescriptions("FillInDefaultStorageLocationType",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	

	If StructureOfActions.Property("FillInProductOwnerIsAvailable") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Purpose");
		
		EditableFields = New Structure();
		EditableFields.Insert("FINISHEDProductOwnerIsAvailable");
		EditableFields.Insert("ProductOwner");
		
		AddFieldDescriptions("FillInProductOwnerIsAvailable", ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("FillInDirectionOfActivity", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Purpose");
		
		EditableFields = New Structure();
		EditableFields.Insert("LineOfBusiness");
		
		AddFieldDescriptions("FillInDirectionOfActivity",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInServiceDetailsForPurpose", StructureOfActionParameters) Then
		
		ReadableFields = New Structure;
		ReadableFields.Insert("Purpose");
		
		EditableFields = New Structure;
		EditableFields.Insert("AssignmentType");

		If Not (TypeOf(StructureOfActionParameters) = Type("Structure")
			And StructureOfActionParameters.Property("OnlyDestinationType")
			And StructureOfActionParameters.OnlyDestinationType = True) Then
				EditableFields.Insert("OrderDocument");
				If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Partner") Then
					EditableFields.Insert("Partner");
				EndIf;
				EditableFields.Insert("Contract");
				EditableFields.Insert("LineOfBusiness");
		EndIf;
		
		AddFieldDescriptions(
			"FillInServiceDetailsForPurpose", ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInDataOnPurchaseDocumentInReportToPurchasingCommittee") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Vendor");
		EditableFields.Insert("PurchaseDocumentType");
		
		AddFieldDescriptions("FillInDataOnPurchaseDocumentInReportToPurchasingCommittee",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInSubdivisionInTSLine", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		If TypeOf(StructureOfActionParameters) = Type("Structure")
			And StructureOfActionParameters.Property("ThereIsWriteOffForExpenses") Then
			ReadableFields.Insert("ItemsType");
			ReadableFields.Insert("AssignmentType");
			ReadableFields.Insert("ToExpenseAs");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("Department");
		
		AddFieldDescriptions("FillInSubdivisionInTSLine",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	If StructureOfActions.Property("FillInDestinationType", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Purpose");
		
		EditableFields = New Structure();
		EditableFields.Insert("AssignmentType");
		
		If ValueIsFilled(StructureOfActionParameters) Then
			
			EditableFields.Insert(StructureOfActionParameters.NameOfFieldToFillIn);
			
			If ValueIsFilled(StructureOfActionParameters.TSFieldName) Then
				ReadableFields.Insert(StructureOfActionParameters.TSFieldName);
			EndIf;
			
		EndIf;
		AddFieldDescriptions("FillInDestinationType",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateLocalOffBalanceAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AmountOffBalance", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountLocalOffBalance" , 0);
		
		AddFieldDescriptions("RecalculateLocalOffBalanceAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateOffBalancePriceByOffBalanceAmount") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AmountOffBalance", 0);
		ReadableFields.Insert("NumberOfPackages", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("PriceOffBalance" , 0);
		
		AddFieldDescriptions("RecalculateOffBalancePriceByOffBalanceAmount",
			ReadableFields, EditableFields, CachedValues);
	EndIf;
	
	If StructureOfActions.Property("RecalculatePriceOffBalancePerPackage") Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Count", 0);
		
		EditableFields = New Structure();
		EditableFields.Insert("PriceOffBalance", 0);
		
		AddFieldDescriptions("RecalculatePriceOffBalancePerPackage",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInActionForRecyclableMaterials") Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Action");
		
		AddFieldDescriptions("FillInActionForRecyclableMaterials",
			EditableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInAttributeAcceptedByCNU") Then
		
		ReadableFields = New Structure();
		ExpenseItemField = ?(ValueIsFilled(StructureOfActions.FillInAttributeAcceptedByCNU),
								StructureOfActions.FillInAttributeAcceptedByCNU,
								"ExpenseItem");
		
		ReadableFields.Insert(ExpenseItemField);
		ReadableFields.Insert("EnteredInTaxAccounting");
		
		EditableFields = New Structure();
		EditableFields.Insert("AcceptedByTheKNU");
		
		AddFieldDescriptions("FillInAttributeAcceptedByCNU",
			ReadableFields, EditableFields, CachedValues);
			
	EndIf;
	
	If StructureOfActions.Property("RecalculatePricePerPackageSuffix", StructureOfActionParameters) Then
		
		Suffix = StructureOfActionParameters.Suffix;
		ReadableFields = New Structure();
		ReadableFields.Insert(QuantityWithSuffix(Suffix).Count);
		
		EditableFields = New Structure();
		EditableFields.Insert(PriceWithSuffix(Suffix));
		
		AddFieldDescriptions("RecalculatePricePerPackageSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("CheckFillInPriceView", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		If TypeOf(StructureOfActionParameters.PriceKind) = Type("String")
				And ValueIsFilled(StructureOfActionParameters.PriceKind) Then
			ReadableFields.Insert(StructureOfActionParameters.PriceKind);
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("PriceKind");
		
		AddFieldDescriptions("CheckFillInPriceView",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculatePriceWithVAT", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Price");
		
		AddFieldDescriptions("RecalculatePriceWithVAT",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountOfManualDiscount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Price");
		ReadableFields.Insert("PercentRateOfManualDiscount");
		QuantityName = "NumberOfPackages";
		If ValueIsFilled(StructureOfActionParameters) Then
			QuantityName = StructureOfActionParameters;
		EndIf;
		ReadableFields.Insert("QuantityName");
		
		EditableFields = New Structure();
		EditableFields.Insert("ManualDiscount");
		
		AddFieldDescriptions("RecalculateAmountOfManualDiscount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountOfAutomaticDiscount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Price");
		ReadableFields.Insert("PercentRateOfAutomaticDiscountMarkup");
		QuantityName = "NumberOfPackages";
		If ValueIsFilled(StructureOfActionParameters) Then
			QuantityName = StructureOfActionParameters;
		EndIf;
		ReadableFields.Insert("QuantityName");
		
		EditableFields = New Structure();
		EditableFields.Insert("DiscountMarkupAmount");
		
		AddFieldDescriptions("RecalculateAmountOfAutomaticDiscount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculatePercentageOfManualDiscount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Price");
		ReadableFields.Insert("ManualDiscount");
		QuantityName = "NumberOfPackages";
		If ValueIsFilled(StructureOfActionParameters) Then
			QuantityName = StructureOfActionParameters;
		EndIf;
		ReadableFields.Insert("QuantityName");
		
		EditableFields = New Structure();
		EditableFields.Insert("PercentRateOfManualDiscount");
		
		AddFieldDescriptions("RecalculatePercentageOfManualDiscount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculatePriceByAmount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Sum");
		QuantityName = "NumberOfPackages";
		If ValueIsFilled(StructureOfActionParameters) Then
			QuantityName = StructureOfActionParameters;
		EndIf;
		ReadableFields.Insert("QuantityName");
		
		EditableFields = New Structure();
		EditableFields.Insert("Price");
		
		AddFieldDescriptions("RecalculatePriceByAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculatePriceByAmountOfGiverSOrder", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Amount");
		QuantityName = "NumberOfPackages";
		If ValueIsFilled(StructureOfActionParameters) Then
			QuantityName = StructureOfActionParameters;
		EndIf;
		ReadableFields.Insert("QuantityName");
		
		EditableFields = New Structure();
		EditableFields.Insert("Price");
		
		AddFieldDescriptions("RecalculatePriceByAmountOfGiverSOrder",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateSaleAmountByAmountWithVAT", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AmountIncludingVAT");
		
		EditableFields = New Structure();
		EditableFields.Insert("SalesAmount");
		
		AddFieldDescriptions("RecalculateSaleAmountByAmountWithVAT",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateSalePriceBySaleAmount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("NumberOfPackages");
		ReadableFields.Insert("SalesAmount");
		
		EditableFields = New Structure();
		EditableFields.Insert("SellingPrice");
		
		AddFieldDescriptions("RecalculateSalePriceBySaleAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountTakingIntoAccountRoundingError", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Sum");
		
		AddFieldDescriptions("RecalculateAmountTakingIntoAccountRoundingError",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateVATSalesAmount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("SalesAmount");
		If StructureOfActionParameters = Undefined
				Or Not StructureOfActionParameters.Property("VATRate") Then
			ReadableFields.Insert("VATRate");
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountSalesVAT");
		
		AddFieldDescriptions("RecalculateVATSalesAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("SetFlagForFillingInTextDescription", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
			
		EditableFields = New Structure();
		EditableFields.Insert("ForFillingInDescriptionText");
		
		AddFieldDescriptions("SetFlagForFillingInTextDescription",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInAddressStorageAttribute", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Warehouse");
		ReadableFields.Insert("Premise");
		
		EditableFields = New Structure();
		EditableFields.Insert("UseBinLocationWarehousing");
		
		AddFieldDescriptions("FillInAddressStorageAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInSpaceUsageAttribute", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Warehouse");
			
		EditableFields = New Structure();
		EditableFields.Insert("UseWarerooms");
		
		AddFieldDescriptions("FillInSpaceUsageAttribute",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FlagForAcceptanceComment", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("VendorSComment");
		ReadableFields.Insert("ManagerComment");
		
		EditableFields = New Structure();
		EditableFields.Insert("ThereIsSupplierComment");
		EditableFields.Insert("ThereIsAManagerComment");
		
		AddFieldDescriptions("FlagForAcceptanceComment",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FlagForShipmentComment", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("CustomerComment");
		ReadableFields.Insert("ManagerComment");
		
		EditableFields = New Structure();
		EditableFields.Insert("ThereIsACustomerComment");
		EditableFields.Insert("ThereIsAManagerComment");
		
		AddFieldDescriptions("FlagForShipmentComment",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FlagForComment", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("RecipientComment");
		ReadableFields.Insert("ManagerComment");
		
		EditableFields = New Structure();
		EditableFields.Insert("ThereIsACommentFromRecipient");
		EditableFields.Insert("ThereIsAManagerComment");
		
		AddFieldDescriptions("FlagForComment",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInForm", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		
		EditableFields = New Structure();
		EditableFields.Insert("Partner");
		
		AddFieldDescriptions("FillInForm",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInMethodForDeterminingCost", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		If CommonClientServer.HasAttributeOrObjectProperty(
			CurrentRow, "CostDefiningMethod") Then
				If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentSalesOfGoodsAndServices") Then
					ReadableFields.Insert("DocumentSalesOfGoodsAndServices");
				EndIf;
				
				If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DocumentTransfers_") Then
					ReadableFields.Insert("DocumentTransfers_");
				EndIf;
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("CostDefiningMethod");
		
		AddFieldDescriptions("FillInMethodForDeterminingCost",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("FillInCostDeterminationMethodWithLine", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("CostDefiningMethod");
			
		EditableFields = New Structure();
		EditableFields.Insert("MethodForDeterminingTheCostOfALine");
		
		AddFieldDescriptions("FillInCostDeterminationMethodWithLine",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateAmountWithoutVATLocal", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AmountIncludingVAT");
		ReadableFields.Insert("VATAmount");
		ReadableFields.Insert("Sum");
		ReadableFields.Insert("AmountExcludingVATCompl");
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountExcludingVATCompl");
		
		AddFieldDescriptions("RecalculateAmountWithoutVATLocal",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("RecalculateAmountWithoutVATMan", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("AmountIncludingVAT");
		ReadableFields.Insert("VATAmount");
		ReadableFields.Insert("Sum");
		ReadableFields.Insert("AmountExcludingVATMan");
		
		EditableFields = New Structure();
		EditableFields.Insert("AmountExcludingVATMan");
		
		AddFieldDescriptions("RecalculateAmountWithoutVATMan",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("RecalculateAmountWithoutVATLocalSuffix", StructureOfActionParameters) Then
		
		Suffix = "";
		
		If StructureOfActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			Suffix = "";
		EndIf;
		
		SumWithSuffix = SumWithSuffix(Suffix);
		
		ReadableFields = New Structure();
		ReadableFields.Insert(SumWithSuffix.AmountIncludingVAT);
		ReadableFields.Insert(SumWithSuffix.VATAmount);
		ReadableFields.Insert(SumWithSuffix.Sum);
		ReadableFields.Insert(SumWithSuffix.AmountExcludingVATCompl);
			
		EditableFields = New Structure();
		EditableFields.Insert(SumWithSuffix.AmountExcludingVATCompl);
		
		AddFieldDescriptions("RecalculateAmountWithoutVATLocalSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("RecalculateAmountWithoutVATManSuffix", StructureOfActionParameters) Then
		
		Suffix = "";
		
		If StructureOfActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			Suffix = "";
		EndIf;
		
		SumWithSuffix = SumWithSuffix(Suffix);
		
		ReadableFields = New Structure();
		ReadableFields.Insert(SumWithSuffix.AmountIncludingVAT);
		ReadableFields.Insert(SumWithSuffix.VATAmount);
		ReadableFields.Insert(SumWithSuffix.Sum);
		ReadableFields.Insert(SumWithSuffix.AmountExcludingVATMan);
			
		EditableFields = New Structure();
		EditableFields.Insert(SumWithSuffix.AmountExcludingVATMan);
		
		AddFieldDescriptions("RecalculateAmountWithoutVATManSuffix",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	If StructureOfActions.Property("RecalculateExciseTaxAmount", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Products");
		If ValueIsFilled(StructureOfActionParameters) Then
			ReadableFields.Insert(StructureOfActionParameters.FieldNameQuantity);
		EndIf;
		
		EditableFields = New Structure();
		EditableFields.Insert("ExciseTaxAmount");
		
		AddFieldDescriptions("RecalculateExciseTaxAmount",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
		
	If StructureOfActions.Property("FillInPresentationOfTermsOfPurchase", StructureOfActionParameters) Then
		
		ReadableFields = New Structure();
		ReadableFields.Insert("Partner");
		ReadableFields.Insert("Sum");
		ReadableFields.Insert("AmountIncludingVAT");
		
		EditableFields = New Structure();
		EditableFields.Insert("PresentationOfTermsOfPurchase");
		
		AddFieldDescriptions("FillInPresentationOfTermsOfPurchase",
			ReadableFields, EditableFields, CachedValues);
		
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.FieldsOfActionLine(
		CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters);
	
	TSFieldStructureIsComplete = CachedValues.TSFieldStructureIsComplete;
	
	TSFieldStructureIsComplete.Insert("LineNumber", 0);
	
	FillPropertyValues(TSFieldStructureIsComplete, CurrentRow);
	
	If Not AdditionalFillingParameters = Undefined Then
		FillPropertyValues(TSFieldStructureIsComplete, AdditionalFillingParameters);
	EndIf;
	
	Return TSFieldStructureIsComplete;
	
EndFunction

Procedure AddFieldDescriptions(Actions, ReadableFields, EditableFields, CachedValues) Export
	
	CommonClientServer.SupplementStructure(CachedValues.TSFieldStructureIsComplete, ReadableFields, True);
	CommonClientServer.SupplementStructure(CachedValues.TSFieldStructureIsComplete, EditableFields, True);

	ListOfActions = StrSplit(Actions, ",");
	For Each Action In ListOfActions Do
		CachedValues.EditableFields.Insert(Action, EditableFields);
		CachedValues.ReadableFields.Insert(Action, ReadableFields);
	EndDo;
	
EndProcedure

Procedure AddFieldsByKeyAndValue(ActionName, ActionParameters, CachedValues) Export
	
	ReadableFields = New Structure();
	EditableFields = New Structure();
	
	For Each Field In ActionParameters Do
		ReadableFields.Insert(Field.Key);
		If ValueIsFilled(Field.Value) Then
			EditableFields.Insert(Field.Value);
		EndIf;
	EndDo;
	
	AddFieldDescriptions(ActionName, ReadableFields, EditableFields, CachedValues);
	
EndProcedure
	
#EndRegion

#Region Private

#Region OtherProcedures

Procedure FillInDiscrepanciesInActLine(CurrentRow)
	
	CurrentRow.NumberOfDiscrepancyPackaging = CurrentRow.NumberOfPackages - CurrentRow.NumberOfPackagesByDocument;
	CurrentRow.DiscrepancyAmount              = CurrentRow.Sum - CurrentRow.SumByDocument;
	CurrentRow.PersonalIncomeTaxExpense           = CurrentRow.VATAmount - CurrentRow.VATAmountByDocument;
	CurrentRow.TheAmountOfTheSNDSRansmission          = CurrentRow.AmountIncludingVAT - CurrentRow.AmountIncludingVATByDocument;
	CurrentRow.ThereAreDiscrepancies               = (CurrentRow.NumberOfDiscrepancyPackaging <> 0);
	
EndProcedure

Function NormalizeUnitConversionParameters(CurrentRow, PackagingProducts) Export
	
	If PackagingProducts = Undefined Then
		
		Products   = CurrentRow.Products;
		Package       = CurrentRow.Package;
		MustBeRoundOff = True;
		
	ElsIf TypeOf(PackagingProducts) = Type("Structure") Then
		
		If PackagingProducts.Property("Package") Then
			Package = PackagingProducts.Package;
		ElsIf PackagingProducts.Property("UnitOfMeasurementVETIS") Then
			If ValueIsFilled(PackagingProducts.UnitOfMeasurementVETIS) Then
				Package = PackagingProducts.UnitOfMeasurementVETIS;
			Else
				Package = CurrentRow.UnitOfMeasurementVETIS;
			EndIf;
		Else
			Package = CurrentRow.Package;
		EndIf;
		
		If PackagingProducts.Property("Products") Then
			Products = PackagingProducts.Products;
		Else
			Products = CurrentRow.Products;
		EndIf;
		
		If PackagingProducts.Property("MustBeRoundOff") Then
			If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "MustBeRoundOff") Then
				MustBeRoundOff = CurrentRow.MustBeRoundOff;
			Else
				MustBeRoundOff = PackagingProducts.MustBeRoundOff;
			EndIf;
		Else
			MustBeRoundOff = True;
		EndIf;
		
	Else
		Package       = PackagingProducts;
		Products   = CurrentRow.Products;
		MustBeRoundOff = True;
	EndIf;
	
	Return New Structure("Products,Package,MustBeRoundOff", Products, Package, MustBeRoundOff);
	
EndFunction

Function NormalizeUnitConversionParametersSuffix(CurrentRow, RecalculationParameters) Export
	
	Suffix = "";
	MustBeRoundOff = True;
	
	If TypeOf(RecalculationParameters) = Type("Structure") Then
		
		If RecalculationParameters.Property("Suffix") Then
			Suffix = RecalculationParameters.Suffix;
		EndIf;
		
		If RecalculationParameters.Property("MustBeRoundOff") Then
			MustBeRoundOff = RecalculationParameters.MustBeRoundOff;
		EndIf;
	Else
		Suffix = RecalculationParameters;
	EndIf;

	If Suffix = Undefined Then
		Suffix = "";
	EndIf;
	
	Return New Structure("Suffix,MustBeRoundOff", Suffix, MustBeRoundOff); 
	
EndFunction

Function GetRnptCoefficient(RecalculationParameters, CurrentRow, CachedValues) Export
	
	Return AccountingForTraceableGoodsClientServerLocalization.GetRnptCoefficient(RecalculationParameters,
																					CurrentRow,
																					CachedValues);
	
EndFunction

Procedure RecalculateWeightVolumeInTSString(CurrentRow, StructureOfActions, CachedValues) Export 
	
	Suffix = Undefined;
	
	If StructureOfActions.Property("RecalculateWeightVolume", Suffix) Then
		
		QuantityWithSuffix = QuantityWithSuffix(Suffix);
		
		UnitWeight_ = GetPackingRatio(CurrentRow.UnitOfMeasureForWeight, CachedValues).ZoomRatio;
		If UnitWeight_ * CurrentRow.PackageWeight <> 0 Then
			
			CurrentRow.Weight =	CurrentRow[QuantityWithSuffix.NumberOfPackages]
				* Round(CurrentRow.PackageWeight / UnitWeight_, 11, RoundMode.Round15as20);
			
		EndIf;
		
		UnitVolume_ = GetPackingRatio(CurrentRow.UnitOfMeasureForVolume, CachedValues).ZoomRatio;
		If UnitVolume_ * CurrentRow.PackageVolume <> 0 Then
			
			CurrentRow.VolumeM3 =CurrentRow[QuantityWithSuffix.NumberOfPackages]
				* Round(CurrentRow.PackageVolume / UnitVolume_, 7, RoundMode.Round15as20);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function PackingCacheKey(Products, Package) Export
	
	If ValueIsFilled(Products) Then
		KeyProducts = String(Products.UUID());
	Else
		KeyProducts = "EmptyValue";
	EndIf;
	
	If ValueIsFilled(Package) Then
		KeyPacking = String(Package.UUID());
	Else
		KeyPacking = "EmptyValue";
	EndIf;
	
	Return KeyProducts + KeyPacking;
	
EndFunction

Function KeyCacheCoefficientRNPT(CurrentRow, RecalculationParameters) Export
	
	Return AccountingForTraceableGoodsClientServerLocalization.KeyCacheCoefficientRNPT(CurrentRow, RecalculationParameters);
	
EndFunction

Procedure WhenChangingAssignmentInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("WhenChangingDestination") Then
		
		CurrentRow.AssignmentSender = CurrentRow.Purpose;
		
	EndIf;
	
EndProcedure

// Recalculates the amount of the automatic discount on the product in the current row of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See GetStructureOfCachedValues.
//
Procedure RecalculateAmountOfAutomaticDiscountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	QuantityName = Undefined;
		
	If StructureOfActions.Property("RecalculateAmountOfAutomaticDiscount", QuantityName) Then
		
		If Not ValueIsFilled(QuantityName) Then
			QuantityName = "NumberOfPackages"; 
		EndIf;
			
		CurrentRow.DiscountMarkupAmount = Round(CurrentRow[QuantityName] *CurrentRow.Price
		                                              * CurrentRow.PercentRateOfAutomaticDiscountMarkup / 100, 2);
		
	EndIf;

EndProcedure

Procedure CheckFillCommunicationKeySpecifications(CurrentRow, StructureOfActions, CachedValues) Export
	
	If Not StructureOfActions.Property("CheckFillCommunicationKeySpecifications") Then
		Return;
	EndIf;
	
	CurrentRow.LinkKeyBOM = Undefined;
	
EndProcedure

Function FieldNamesBySeriesIndicationStatus(NameOfStatusField)
	
	ReturnStructure = New Structure("Series, Products, Characteristic");
	
	If NameOfStatusField = "BatchesIndicationStatus"
		Or NameOfStatusField = "BatchesIndicationStatusShortages" Then
		ReturnStructure.Series = "Series";
		ReturnStructure.Products = "Products"; 
		ReturnStructure.Characteristic = "Characteristic";
	ElsIf NameOfStatusField = "BatchesIndicationStatusSender" Then
		ReturnStructure.Series = "SenderSeries";
		ReturnStructure.Products = "SenderProducts";
		ReturnStructure.Characteristic = "SenderCharacteristic";
	ElsIf NameOfStatusField = "BatchesIndicationStatusRecipient" Then
		ReturnStructure.Series = "RecipientSeries";
		ReturnStructure.Products = "ProductsRecipient";
		ReturnStructure.Characteristic = "CharacteristicRecipient";
	ElsIf NameOfStatusField = "BatchesIndicationStatusReceipt" Then
		ReturnStructure.Series = "BatchReceipt";
		ReturnStructure.Products = "ProductsRecordingAsReceived";
		ReturnStructure.Characteristic = "CharacteristicRecordingAsReceived";
	ElsIf NameOfStatusField = "BatchesIndicationStatusInWarehouses" Then
		ReturnStructure.Series = "SeriesInWarehouses";
		ReturnStructure.Products = "ProductsInWarehouses";
		ReturnStructure.Characteristic = "CharacteristicsInWarehouses";
	ElsIf NameOfStatusField = "BatchesIndicationStatusGoodsAtPartners" Then
		ReturnStructure.Series = "BuyProductsFromPartners";
		ReturnStructure.Products = "ProductsFromPartners";
		ReturnStructure.Characteristic = "CharacteristicsProductsFromPartners";
	ElsIf NameOfStatusField = "BatchesIndicationStatusOfGoodsTransferred" Then
		ReturnStructure.Series = "SeriesOfTransferredGoods";
		ReturnStructure.Products = "ProductsTransferred";
		ReturnStructure.Characteristic = "CharacteristicsOfTransferredGoods";
	ElsIf NameOfStatusField = "StatusOfSpecifyingSeriesDebitedSeries" Then
		ReturnStructure.Series = "SeriesDecommissionedSeries";
		ReturnStructure.Products = "ProductsDecommissionedSeries";
		ReturnStructure.Characteristic = "CharacteristicDecommissionedSeries";
	ElsIf NameOfStatusField = "BatchIndicationStatusOfGoodsShipped" Then
		ReturnStructure.Series = "BatchOfShippedGoods";
		ReturnStructure.Products = "ItemOfShippedGoods";
		ReturnStructure.Characteristic = "CharacteristicsOfShippedItems";
	ElsIf NameOfStatusField = "UnderRepairBatchSpecificationStatus" Then
		ReturnStructure.Series = "UnderRepairBatch";
		ReturnStructure.Products = "UnderRepairProduct";
		ReturnStructure.Characteristic = "UnderRepairVariant";
	EndIf;
	
	Return ReturnStructure
	
EndFunction

Function ActionSuffix(Parameters)
	
	QuantityName = "";
	
	If TypeOf(Parameters) = Type("Structure") Then
		Suffix = Parameters.Suffix;
		If Parameters.Property("QuantityName") Then
			QuantityName = Parameters.QuantityName;
		EndIf;
	Else
		Suffix = Parameters;
	EndIf;

	Return New Structure("Suffix, QuantityName", Suffix, QuantityName);

EndFunction

#EndRegion

#EndRegion
