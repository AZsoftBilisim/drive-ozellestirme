////////////////////////////////////////////////////////////////////////////////////////
// Comparison of the nomenclature of the Counteragent Service: 
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
///////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region WorkingWithProductListOfCounterparties

// Returns whether the user has rights to map the item.
//
// Returns:
//  Boolean - a sign of rights.
//
Function ThereIsRightToCompareProducts() Export
	
	Return AccessRight("Update", Metadata.Catalogs.ProductCrossReferences);
	
EndFunction

// Returns the owner of the item used by the counterparty.
//
// Parameters:
//  Counterparty - DefinedType.EDLCounterparty - counterparty, the owner of the item which you want to.
//
// Returns:
//  DefinedType.ItemOwnerEDL - owner of the counterparty's nomenclature.
//
Function OwnerOfCounterpartyProducts(Val Counterparty) Export
	
	Owner = Counterparty;
	ProductCrossReferencesMappingOverridable.WhenDeterminingOwnerOfCounterpartySProductList(Counterparty, Owner);
	Return Owner;
	
EndFunction

// Returns the first found reference of the counterparty item by owner and ID.
//
// Parameters:
//  ItemOwner - DefinedType.ItemOwnerEDL - the owner of the item.
//  Id        - String                                  - id of the counterparty's item.
//
// Returns:
//  CatalogRef.ProductCrossReferences - reference of the counterparty's nomenclature.
//
Function CounterpartyProductsByOwnerAndIdentifier(Val ItemOwner, Val Id) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductCrossReferences.Ref AS Ref
		|FROM
		|	Catalog.ProductCrossReferences AS ProductCrossReferences
		|WHERE
		|	ProductCrossReferences.ItemOwner = &ItemOwner
		|	AND ProductCrossReferences.Id = &Id";
	
	Query.SetParameter("ItemOwner", ItemOwner);
	Query.SetParameter("Id", Id);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion


#Region SearchByNaturalKeysOfCounterpartySNomenclature

// Returns a structure containing MD5 hashes from the natural keys of the item. 
// If the natural key is empty, then the value of the corresponding key structure will be an empty string.
// 
// Parameters:
//  Description - String - name of the item
//  SKU - String - article of the nomenclature
//  ProductsAndServicesCode - String - Item code
//  Barcode - String - barcode of the item
// 
// Returns:
//  Structure:
//   * DescriptionHash - String - MD5 hash from the name
//   * ItemIDHash - String - MD5 hash from the article
//   * ItemCodeHash - String - MD5 hash from the code
//   * BarcodeHash - String - MD5 hash from the barcode
//
Function HashesOfNaturalKeysOfNomenclature(Val Description, Val SKU, Val ProductsAndServicesCode,
	Val Barcode) Export
	
	Keys = New Structure;
	Keys.Insert("DescriptionHash", "");
	Keys.Insert("ItemIDHash", "");
	Keys.Insert("ItemCodeHash", "");
	Keys.Insert("BarcodeHash", "");
	
	If LineFilled(Description) Then
		Keys.DescriptionHash = HashByLine(Description);
	EndIf;
	
	If LineFilled(SKU) Then
		Keys.ItemIDHash = HashByLine(SKU);
	EndIf;
	
	If LineFilled(ProductsAndServicesCode) Then
		Keys.ItemCodeHash = HashByLine(ProductsAndServicesCode);
	EndIf;
	
	If LineFilled(Barcode) Then
		Keys.BarcodeHash = HashByLine(Barcode);
	EndIf;
	
	Return Keys;
	
EndFunction

#EndRegion

#Region FormsEventsHandlers

Procedure ProductsOnChange(Form, AttributeName, DefaultUnitOfMeasurement = Undefined) Export
	
	Items = Form.Items;
	InitialComparisonData = Form[AttributeName];
	
	NewMatchingData = ProductCrossReferencesMappingClientServer.NewMatchingData();
	FillPropertyValues(NewMatchingData, InitialComparisonData);
	NewMatchingData.DefaultUnitOfMeasurement = DefaultUnitOfMeasurement;
	
	NamesOfCommunicationParameters = ProductCrossReferencesMappingClientServer.NewNamesOfCommunicationParameters();
	ProductCrossReferencesMappingOverridable.WhenDeterminingStructureOfProductOfInformationBase(
		NamesOfCommunicationParameters);
	FillPropertyValues(NewMatchingData, NamesOfCommunicationParameters);

	ProductCrossReferencesMappingOverridable.WhenMatchingProductRangeChanges_CounterpartyProductRange(
		Form, NewMatchingData);
	
	FillPropertyValues(InitialComparisonData, NewMatchingData,, "Products");
	
	RequiredFillingInCharacteristics = NewMatchingData.UseCharacteristics 
		And NewMatchingData.RequiredFillingInCharacteristics;
	CommonClientServer.SetFormItemProperty(Items, "Characteristic", "AutoMarkIncomplete", 
		RequiredFillingInCharacteristics);
	CommonClientServer.SetFormItemProperty(Items, "Characteristic", "Enabled",
		NewMatchingData.UseCharacteristics);
	
	DefaultUnitOfMeasurement = NewMatchingData.DefaultUnitOfMeasurement;
	CommonClientServer.SetFormItemProperty(Items, "Package", "InputHint",
		DefaultUnitOfMeasurement);
	
	DataPath = StrTemplate("%1.Products", AttributeName);
	SetChoiceParametersLinks(Items, "Characteristic", NewMatchingData.NameOfCharacteristicLinkParameter,
		DataPath);
	SetChoiceParametersLinks(Items, "Package", NewMatchingData.NameOfPackageConnectionParameter, 
		DataPath);
	
EndProcedure

#EndRegion

#Region Other

// Returns an empty reference of the BAD item.
//
// Returns:
//  DefinedType.EDLProducts - empty item reference.
//
Function EmptyBadProductReference() Export
	
	If Metadata.DefinedTypes.EDLProducts.Type.Types().Count() > 1 Then
		Return Undefined;
	ElsIf Metadata.FindByType(Metadata.DefinedTypes.EDLProducts.Type.Types()[0]) <> Undefined Then
		Return Catalogs[Metadata.FindByType(Metadata.DefinedTypes.EDLProducts.Type.Types()[0]).Name].EmptyRef();
	EndIf;
	
EndFunction

// Returns the description and relationship of the objects that make up the nomenclature of the information base.
// The result is based on defined types and redefined methods.
//
// Returns:
//  Structure - data on the structure of the nomenclature of the information base:
//   * OwnerOfProductItemPresentation - String - representation of a single object, the owner of the item.
//   * ProductObjectPresentation - String - representation of a single item item.
//   * FeaturePresentationOfObject - String - representation of a single feature object.
//   * PackagingObjectPresentation - String - representation of a single packaging object.
//   * ProductsAndListPresentation - String - representation of the list of the counterparty's nomenclature.
//   * OwnerOfProductInGenitiveCase - String - representation of the owner of the item in the genitive case.
//   * NameOfCharacteristicLinkParameter - String - the name of the parameter of the link of the characteristic from the item.
//   * NameOfPackageConnectionParameter - String - the name of the packaging link parameter from the item.
//
Function ProductMappingMetadata() Export
	
	MappingMetadata = New Structure;
	
	Presentations = PresentationsOfCounterpartyProductRange();

	ProductCrossReferencesMappingOverridable.WhenDefiningPresentationsOfProductCollation(Presentations);
	
	MappingMetadata.Insert("OwnerOfProductItemPresentation", Presentations.OwnerOfProductItemPresentation);
	MappingMetadata.Insert("ProductObjectPresentation", Presentations.ProductObjectPresentation);
	MappingMetadata.Insert("FeaturePresentationOfObject", Presentations.FeaturePresentationOfObject);
	MappingMetadata.Insert("PackagingObjectPresentation", Presentations.PackagingObjectPresentation);
	MappingMetadata.Insert("ProductsAndListPresentation", Presentations.ProductsAndListPresentation);
	MappingMetadata.Insert("ItemProductsAndPresentation", Presentations.ItemProductsAndPresentation);
	MappingMetadata.Insert("OwnerOfProductInGenitiveCase", Presentations.OwnerOfProductInGenitiveCase);
	
	
	StructureOfInformationSecurityProducts = New Structure;
	StructureOfInformationSecurityProducts.Insert("NameOfCharacteristicLinkParameter", "Filter.Owner");
	StructureOfInformationSecurityProducts.Insert("NameOfPackageConnectionParameter", "Filter.Owner");
	
	ProductCrossReferencesMappingOverridable.WhenDeterminingStructureOfProductOfInformationBase(StructureOfInformationSecurityProducts);
	
	MappingMetadata.Insert("NameOfCharacteristicLinkParameter", StructureOfInformationSecurityProducts.NameOfCharacteristicLinkParameter);
	MappingMetadata.Insert("NameOfPackageConnectionParameter", StructureOfInformationSecurityProducts.NameOfPackageConnectionParameter);
	
	Return MappingMetadata;
	
EndFunction

Function PresentationsOfCounterpartyProductRange() Export
	
	DescriptionOfItemTypes = New TypeDescription(
		ProductCrossReferencesMappingCached.TypesOfBADNomenclatureUsed());
	
	Presentations = New Structure;
	Presentations.Insert("OwnerOfProductItemPresentation", 
		ObjectPresentationByType(Metadata.DefinedTypes.ItemOwnerEDL.Type, "Owner"));
	Presentations.Insert("ProductObjectPresentation", 
		ObjectPresentationByType(DescriptionOfItemTypes, "Products"));
	Presentations.Insert("FeaturePresentationOfObject", 
		ObjectPresentationByType(Metadata.DefinedTypes.ItemsCharacteristicEDL.Type, "Characteristic"));
	Presentations.Insert("PackagingObjectPresentation", 
		ObjectPresentationByType(Metadata.DefinedTypes.PackageEDLItems.Type, "Package"));
	Presentations.Insert("OwnerOfProductInGenitiveCase", NStr("vi = 'Đối tác';
																|ru = 'Контрагента';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Della controparte';
																|pl = 'Kontrahenta';
																|tr = 'Cari hesabın'"));
	
	Presentations.Insert("ProductsAndListPresentation",
		Metadata.Catalogs.ProductCrossReferences.Synonym);
	Presentations.Insert("ItemProductsAndPresentation",
		Metadata.Catalogs.ProductCrossReferences.ObjectPresentation);
	
	Return Presentations;
	
EndFunction

// Returns the properties of a set of items in the information base.
// Defines the mandatory use of characteristics and packaging.
//
// Parameters:
//  SetOfProducts - Array of DefinedType.EDLProducts, DefinedType.EDLProducts - references to the information security item
//   that you want to define properties for. If a reference is passed, it is converted to an array.
//
// Returns:
//  - Undefined - in the case of an empty item set, it returns an Indefinite value.
//  - Map of KeyAndValue:
//  * Key     - DefinedType.EDLProducts - link to the information security nomenclature.
//  * Value - See ProductCrossReferencesMappingClientServer.NewPropertiesOfInformationSecurityProducts.
//
Function InformationBaseProductProperties(Val SetOfProducts) Export
	
	If Not ValueIsFilled(SetOfProducts) Then
		Return Undefined;
	EndIf;
	
	PropertiesOfInformationSecurityProducts = New Map;
	
	If TypeOf(SetOfProducts) <> Type("Array") Then
		SetOfProducts = CommonClientServer.ValueInArray(SetOfProducts);
	EndIf;
	
	If ValueIsFilled(SetOfProducts) Then
		ProductCrossReferencesMappingOverridable.WhenDeterminingPropertiesOfInformationBaseProduct(SetOfProducts, PropertiesOfInformationSecurityProducts);
	EndIf;
	
	Return PropertiesOfInformationSecurityProducts;
	
EndFunction


#EndRegion

#EndRegion

#Region Private


#Region Other


Procedure SetChoiceParametersLinks(FormItems, FormItemName, NameOfLinkParameter, DataPath)

	AllConnections = New Array();
	If ValueIsFilled(NameOfLinkParameter) Then
		NewLink = New ChoiceParameterLink(NameOfLinkParameter, DataPath);
		AllConnections.Add(NewLink);
	EndIf;
	CommonClientServer.SetFormItemProperty(FormItems, "Package", "ChoiceParameterLinks",
		New FixedArray(AllConnections));

EndProcedure

Function HashByLine(Val Parameter)
	
	Return Common.CheckSumString(NormalizeStringValue(Parameter));
	
EndFunction

Function NormalizeStringValue(Val Parameter)
	
	Return Upper(TrimAll(Parameter));
	
EndFunction

Function LineFilled(RowToValidate)
	
	RegularExpression = "\p{L}|\d"; // checks that the string contains at least one character or digit
	
	Return StrFindByRegularExpression(RowToValidate, RegularExpression).StartIndex > 0;
	
EndFunction

// Returns a representation of a single object of the specified type.
//
// Parameters:
//  TypeDetails - TypeDescription - the list of types allowed for the object.
//  DefaultPresentation - String - the default view, if it could not be retrieved from the metadata.
//
// Returns:
//  String - the resulting representation.
//
Function ObjectPresentationByType(Val TypeDetails, Val DefaultPresentation = "") Export
	
	Presentation = "";
	
	For Each Type In TypeDetails.Types() Do
		
		TypeMetadata = Metadata.FindByType(Type);
		
		If TypeMetadata = Undefined Then
			Continue;
		EndIf;
		
		If ValueIsFilled(Presentation) Then
			Presentation = Presentation + " / ";
		EndIf;
		
		ObjectPresentation = TypeMetadata.ObjectPresentation;
		If Not ValueIsFilled(ObjectPresentation) Then
			ObjectPresentation = TypeMetadata.Synonym;
		EndIf;
		
		Presentation = Presentation + ObjectPresentation;
		
	EndDo;
	
	If Not ValueIsFilled(Presentation) Then
		Presentation = DefaultPresentation;
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion

#EndRegion