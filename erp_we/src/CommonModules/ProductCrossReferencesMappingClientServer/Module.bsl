/////////////////////////////////////////////////////////////////////////////////////////
// Comparison of Nomenclature of Contractors Clientserver:
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a data set that represents the item in the information database.
//
// Parameters:
//  Products   - DefinedType.EDLProducts               - the value for the initialization of the output properties of the Item.
//  Characteristic - DefinedType.ItemsCharacteristicEDL - the value for the initialization of the output property Characterization.
//  Package       - DefinedType.PackageEDLItems       - the value for initializing the output property of the Package.
//
// Returns:
//  Structure - data representing the nomenclature of the information base:
//   * Products   - DefinedType.EDLProducts, Undefined               - the nomenclature of information security. Undefined if not initialized.
//   * Characteristic - DefinedType.ItemsCharacteristicEDL, Undefined - characteristics of the IB nomenclature. Undefined if not initialized.
//   * Package       - DefinedType.PackageEDLItems, Undefined       - packaging of the information base nomenclature. Undefined if not initialized.
//
Function NewProductsOfInformationBase(Val Products = Undefined, Val Characteristic = Undefined, Val Package = Undefined) Export
	
	InformationSecurityProducts = New Structure;
	InformationSecurityProducts.Insert("Products"  , Products);
	InformationSecurityProducts.Insert("Characteristic", Characteristic);
	InformationSecurityProducts.Insert("Package"      , Package);

	Return InformationSecurityProducts;
	
EndFunction

// Returns a data set representing the counterparty's item in the information database.
//
// Parameters:
//  Products   - DefinedType.EDLProducts               - the value for the initialization of the output properties of the Item.
//  Characteristic - DefinedType.ItemsCharacteristicEDL - the value for the initialization of the output property Characterization.
//  Package       - DefinedType.PackageEDLItems       - the value for initializing the output property of the Package.
//
// Returns:
//  Structure - data representing the nomenclature of the counterparty of the information base:
//   * Products            - DefinedType.EDLProducts, Undefined               - the nomenclature of information security. Undefined if not initialized.
//   * Characteristic          - DefinedType.ItemsCharacteristicEDL, Undefined - characteristics of the IB nomenclature. Undefined if not initialized.
//   * Package                - DefinedType.PackageEDLItems, Undefined       - packaging of the information base nomenclature. Undefined if not initialized.
//   * ProductCrossReference - CatalogRef.ProductCrossReferences                   - reference of the counterparty nomenclature.
//
Function NewProductsForInformationBase(Val Products = Undefined, Val Characteristic = Undefined, Val Package = Undefined) Export
	
	InformationSecurityProducts = New Structure;
	InformationSecurityProducts.Insert("Products"           , Products);
	InformationSecurityProducts.Insert("Characteristic"         , Characteristic);
	InformationSecurityProducts.Insert("Package"               , Package);
	InformationSecurityProducts.Insert("ProductCrossReference", PredefinedValue("Catalog.ProductCrossReferences.EmptyRef"));

	Return InformationSecurityProducts;
	
EndFunction

// Returns a data set that represents the counterparty's item.
//
// Parameters:
//  Owner      - DefinedType.ItemOwnerEDL - the value for initializing the output property Owner.
//  Id - String                                  - the value for the initialization of the output of the ID property.
//
// Returns:
//  Structure - data representing the counterparty's nomenclature:
//   * Owner                           - DefinedType.ItemOwnerEDL - the owner of the item.
//                                        - Undefined if not initialized.
//   * Id                      - String - the key to the uniqueness of the counterparty's nomenclature, the value depends on the context.
//   * Description                       - String - name of the item.
//   * Characteristic                     - String - name of the item's characteristic.
//   * PackageName               - String - the name of the package of the item.
//   * UnitOfMeasure                   - String - name of the basic unit of measurement of the item.
//   * UnitOfMeasureCode                - String - The OCEAN code of the basic unit of measurement of the item.
//   * SKU                            - String - the article of the nomenclature.
//   * VATRate                          - String - the VAT rate of the item. 
//   * CombinationBarcode                 - String - combination barcode: nomenclature, characteristic, packaging.
//   * ItemsBarcodes              - String - other bar codes of items separated by commas.
//   * ServiceItemID   - String - id in the 1C service:Nomenclature.
//   * ServiceVariantID - String - id of the characteristic in the 1C service:Nomenclature.
//   * ProductsIdentifier          - String - the identification of the item.
//   * ItemVariantID        - String - ID of the characteristic.
//   * PackageID              - String - package ID.
//   * IDHistory             - Array of String - alternative identifiers.
//   * QuantityInBaseUnitOfMeasure  - Number  - the number of the base unit of measurement (numerator).
//   * NumberOfPackages                 - Number  - number of packages (denominator)
//   * OptionForSpecifyingProducts        - EnumRef.EDLItemsSpecificationOptions - the value in whose terms the nomenclature is specified.
//                                                                                               By default, the counterparty's nomenclature.
//   * ProductCrossReference            - CatalogRef.ProductCrossReferences          - reference of the counterparty nomenclature.
//
Function NewCounterpartyProducts(Val Owner = Undefined, Val Id = "") Export
	
	ProductCrossReference = New Structure;
	ProductCrossReference.Insert("Owner"            , Owner);
	ProductCrossReference.Insert("Id"       , Id);
	ProductCrossReference.Insert("Description"        , "");
	ProductCrossReference.Insert("Characteristic"      , "");
	ProductCrossReference.Insert("PackageName", "");
	ProductCrossReference.Insert("UnitOfMeasure"    , "");
	ProductCrossReference.Insert("UnitOfMeasureCode" , "");
	ProductCrossReference.Insert("SKU"             , "");
	ProductCrossReference.Insert("VATRate"           , "");
	ProductCrossReference.Insert("CombinationBarcode"                , "");
	ProductCrossReference.Insert("ItemsBarcodes"             , "");
	ProductCrossReference.Insert("ServiceItemID"  , "");
	ProductCrossReference.Insert("ServiceVariantID", "");
	ProductCrossReference.Insert("ProductsIdentifier"         , "");
	ProductCrossReference.Insert("ItemVariantID"       , "");
	ProductCrossReference.Insert("PackageID"             , "");
	ProductCrossReference.Insert("IDHistory"            , New Array);
	ProductCrossReference.Insert("NumberOfPackages"                , 0);
	ProductCrossReference.Insert("QuantityInBaseUnitOfMeasure" , 0);
	ProductCrossReference.Insert("ProductCrossReference"           , 
		PredefinedValue("Catalog.ProductCrossReferences.EmptyRef"));
	ProductCrossReference.Insert("OptionForSpecifyingProducts"       ,
		PredefinedValue("Enum.EDLItemsSpecificationOptions.ProductCrossReference"));
	
	ProductCrossReference.Insert("ProductsAndServicesCode"       , "");
	
	ProductCrossReferencesMappingClientServerOverridable.AddStructureItemOfCounterparty(ProductCrossReference);
		
	Return ProductCrossReference;

EndFunction

// Returns the structure of the properties of the information security item.
//
// Returns:
//  Structure - Information Base Product Properties:
//   * UseCharacteristics           - Boolean - indicates whether the characteristics are used. By default, False.
//   * UsePackages                 - Boolean - indicates the use of packages. By default, False.
//   * RequiredFillingInCharacteristics - Boolean - indicates whether the characteristics must be filled in when using them. Default is True.
//   * DefaultUnitOfMeasurement          - DefinedType.PackageEDLItems - the basic unit of measurement of the item.
//
Function NewPropertiesOfInformationSecurityProducts() Export
	
	ProductItemProperty = New Structure;
	ProductItemProperty.Insert("UseCharacteristics"          , False);
	ProductItemProperty.Insert("UsePackages"                , False);
	ProductItemProperty.Insert("RequiredFillingInCharacteristics", True);
	ProductItemProperty.Insert("DefaultUnitOfMeasurement"         , Undefined);
	
	Return ProductItemProperty;
	
EndFunction

// Returns the structure of the package properties.
//
// Returns:
//  Structure - Contains:
//   * PackageName                - String - indicates whether the characteristics are used. By default, False.
//   * BaseUnitOfMeasureDescription - String - indicates the use of packages. By default, False.
//   * BaseUnitOfMeasureARCMUCode      - String - indicates whether the characteristics must be filled in when using them. Default is True.
//   * QuantityInBaseUnitOfMeasure   - Number  - if there is a package, the conversion factor of 1 package per base unit of measurement is specified.
//                                                    In the case of unpacking, 1 is specified.
//   * NumberOfPackages                  - Number  - if there is a package, specify 1. In the case of unpacking, the conversion factor is specified
//                                                    the basic unit of measurement per package.
//
Function NewPackagingProperties() Export
	
	ProductItemProperty = New Structure;
	ProductItemProperty.Insert("PackageName"               , "");
	ProductItemProperty.Insert("BaseUnitOfMeasureDescription", "");
	ProductItemProperty.Insert("BaseUnitOfMeasureARCMUCode"     , "");
	ProductItemProperty.Insert("QuantityInBaseUnitOfMeasure"  , 0);
	ProductItemProperty.Insert("NumberOfPackages"                 , 0);
		
	Return ProductItemProperty;
	
EndFunction

// Returns a structure with the column names of the form for processing the mapping nomenclature of the database and the visibility attribute.
//
// Returns:
//  Structure:
//   * Package         - Boolean - The visibility of the "Packaging" column is True by default.
//   * UnitOfMeasure - Boolean - Visibility of the "Ed. ed." column, True by default.
//   * SKU          - Boolean - Visibility of the "Article" column, True by default.
//   * VATRate        - Boolean - Visibility of the "VAT Rate" column, True by default.
//   * Barcode         - Boolean - The visibility of the "Barcode" column is True by default.
//
Function NewSettingsForVisibilityOfMappingColumns() Export
	
	VisibilityOfMappingColumns = New Structure;
	VisibilityOfMappingColumns.Insert("Package",         True);
	VisibilityOfMappingColumns.Insert("UnitOfMeasure", True);
	VisibilityOfMappingColumns.Insert("SKU",          True);
	VisibilityOfMappingColumns.Insert("VATRate",        True);
	VisibilityOfMappingColumns.Insert("Barcode",         True);
		
	Return VisibilityOfMappingColumns;
	
EndFunction

// Returns a structure with item matching parameters.
//
// Returns:
//  Structure:
//	 * UseService                   - Boolean - a sign of using the 1C service:Nomenclature.
//                                            If this attribute is not filled in, the service usage is checked.
//   * PercentageOfItemSearchAccuracy    - Number  - percentage of accuracy of searching for nomenclature and characteristics in the dictionary in terms of the counterparty.
//   * ItemSearchRequired           - Boolean - indicates that you need to search for the item in terms of the counterparty.
//   * DisableNaturalKeySearch    - Boolean - indicates that the search for natural key matches is disabled. The default is False.
//   * DisableBarCodeSearchForCombinations - Boolean - indicates whether bar code search is disabled. The default is False.
//   * DisableDictionarySearch              - Boolean - indicates whether dictionary search is disabled. The default is False.
//   * AdditionalSearchParameters_        - Undefined,Arbitrary - structure of additional parameters used in redefined procedures.
//   * UseSearchForPartOfName - Boolean - a sign of the need to search for the nomenclature by part of the name,
//                                                     based on the register of the rule to search for the frequency of naming the item.
//   * UseSearchByCounterpartyNomenclature - Boolean - a sign of the need to search for hashes of natural keys in
//                                                           the register of NomenclatedcOntragentovbEDB.
//   * ItemTypeRestriction - Undefined, TypeDescription - if specified, it contains a restriction on the item type
//   * Organization - Undefined,DefinedType.Organization - the organization for which item matching is performed.
//   * CounterpartyContract - Undefined - The Contract of the counterparty for which the item comparison is performed.
//
Function NewItemMatchingParameters() Export
	
	Parameters = New Structure();
	Parameters.Insert("PercentageOfItemSearchAccuracy",    50);
	Parameters.Insert("ItemSearchRequired",           True);
	Parameters.Insert("UseService",                   False);
	Parameters.Insert("DisableBarCodeSearchForCombinations", False);
	Parameters.Insert("DisableNaturalKeySearch",    False);
	Parameters.Insert("DisableDictionarySearch",   		   False);
	Parameters.Insert("AdditionalSearchParameters_",        Undefined);
	Parameters.Insert("UseSearchForPartOfName", True);
	Parameters.Insert("UseSearchByCounterpartyNomenclature", True);
	Parameters.Insert("ItemTypeRestriction",          Undefined);
	Parameters.Insert("Organization",                          Undefined);
	Parameters.Insert("CounterpartyContract",                   Undefined);
	
	Return Parameters;
	
EndFunction

// returns the structure of the additional Attribute TS mapping processing of the comparison of the nomenclature of the ed.
//
// Returns:
//  Structure - properties of the additional item matching Attributes:
//   * Name           - String - the name of the additional Attributes of the table part.
//   * Type           - TypeDescription - the default String is (300).
//   * Presentation - String - Presentation of Attributes on the form.
//
Function NewAdditionalMatchingAttributes() Export
	
	AdditionalAttribute = New Structure;
	AdditionalAttribute.Insert("Name"           , "");
	AdditionalAttribute.Insert("Type"           , New TypeDescription("String",,,, New StringQualifiers(300)));
	AdditionalAttribute.Insert("Presentation" , "");
		
	Return AdditionalAttribute;
	
EndFunction

// Share the ID of an item a company part of the delimiter #.
//
// Parameters:
//  Id           - String    - the identifier, which must be broken up by the delimiter #.
//  ProductCrossReference - Structure - Contains:
//    *ProductsIdentifier   - String - the identification of the item.
//    *ItemVariantID - String - ID of the characteristic.
//    *PackageID       - String - package ID.
//
Procedure SplitIDIntoParts(Id, ProductCrossReference) Export
	
	PartsOfIdentifiers = StrSplit(Id, "#", True);
	TotalParts = PartsOfIdentifiers.Count();
	
	If TotalParts = 3 Then
		ProductCrossReference.ProductsIdentifier   = PartsOfIdentifiers[0];
		ProductCrossReference.ItemVariantID = PartsOfIdentifiers[1];
		ProductCrossReference.PackageID       = PartsOfIdentifiers[2];
	ElsIf TotalParts > 3 Then
		ProductCrossReference.ProductsIdentifier   = PartsOfIdentifiers[0];
		ProductCrossReference.ItemVariantID = PartsOfIdentifiers[1];
		
		IDLength = StrLen(Id);
		LengthOfIDPart = StrLen(PartsOfIdentifiers[0] + "#" + PartsOfIdentifiers[1] + "#");
		
		LastPartOfID = Mid(Id, LengthOfIDPart + 1, IDLength);
		
		ProductCrossReference.PackageID       = LastPartOfID;
	Else
		ProductCrossReference.ProductsIdentifier   = Id;
		ProductCrossReference.ItemVariantID = Id;
		ProductCrossReference.PackageID       = Id;
	EndIf;
	
	// Let's reduce the length of the identifiers to the length of the details of the Nomenclaturecontagents directory
	ProductCrossReference.ProductsIdentifier = Left(ProductCrossReference.ProductsIdentifier, 100);
	ProductCrossReference.ItemVariantID = Left(ProductCrossReference.ItemVariantID, 100);
	ProductCrossReference.PackageID = Left(ProductCrossReference.PackageID, 100);
	
EndProcedure

// Returns the identifier of the counterparty's nomenclature collected from the internal identifiers of links by the # separator. 
//
// Parameters:
//  InformationSecurityProducts - See NewProductsOfInformationBase
//
// Returns:
//  String - id of the counterparty's item.
//
Function IDOfCounterpartyProductByInformationSecurityProductType(Val InformationSecurityProducts) Export
	
	ProductsID   = ?(ValueIsFilled(InformationSecurityProducts.Products), InformationSecurityProducts.Products.UUID(), "");
	VariantID = ?(ValueIsFilled(InformationSecurityProducts.Characteristic), InformationSecurityProducts.Characteristic.UUID(), "");
	PackagingsID       = ?(ValueIsFilled(InformationSecurityProducts.Package), InformationSecurityProducts.Package.UUID(), "");
	
	Result = "";
	If ValueIsFilled(ProductsID) Then
		Result = String(ProductsID) + "#" + String(VariantID) + "#" + String(PackagingsID);
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor method, returns mapping data.
// The second parameter of the method SeeProductCrossReferencesMappingOverridable.WhenMatchingProductRangeChanges_CounterpartyProductRange.
// 
// Returns:
//  Structure:
//   * Products                - Undefined,DefinedType.EDLProducts               - reference of the IB nomenclature.
//   * Characteristic              - Undefined,DefinedType.ItemsCharacteristicEDL - link to the information security characteristics.
//   * Package                    - Undefined,DefinedType.PackageEDLItems       - link to the IB packaging.
//   * UseCharacteristics  - Boolean - indicates whether the characteristics of the information security nomenclature are used.
//   * RequiredFillingInCharacteristics - Boolean
//   * DefaultUnitOfMeasurement - Undefined,DefinedType.PackageEDLItems       - the reference of the base unit of measurement of the item of information security,
//                                                                                   which should be displayed to the user in the tooltip.
//   * NameOfCharacteristicLinkParameter - String - name of the link parameter for selecting a characteristic by item. By default, " Selection.The owner."
//   * NameOfPackageConnectionParameter       - String - name of the package selection link parameter for the item. By default, " Selection.The owner."
//
Function NewMatchingData() Export
	
	ComparisonData = New Structure;
	ComparisonData.Insert("Products", Undefined);
	ComparisonData.Insert("Characteristic", Undefined);
	ComparisonData.Insert("Package", Undefined);
	ComparisonData.Insert("UseCharacteristics", False);
	ComparisonData.Insert("RequiredFillingInCharacteristics", False);
	ComparisonData.Insert("DefaultUnitOfMeasurement", Undefined);
	ComparisonData.Insert("NameOfCharacteristicLinkParameter", "Filter.Owner");
	ComparisonData.Insert("NameOfPackageConnectionParameter", "Filter.Owner");
	
	Return ComparisonData;
	
EndFunction

// Constructor method, returns the structure of the names of the communication parameters.
//
// Returns:
//  Structure:
//   * NameOfCharacteristicLinkParameter - String - name of the link parameter for selecting a characteristic by item. By default, " Selection.The owner."
//   * NameOfPackageConnectionParameter       - String - name of the package selection link parameter for the item. By default, " Selection.The owner."
//
Function NewNamesOfCommunicationParameters() Export
	
	NamesOfCommunicationParameters = New Structure;
	NamesOfCommunicationParameters.Insert("NameOfCharacteristicLinkParameter", "Filter.Owner");
	NamesOfCommunicationParameters.Insert("NameOfPackageConnectionParameter", "Filter.Owner");
	
	Return NamesOfCommunicationParameters;
	
EndFunction


#EndRegion

