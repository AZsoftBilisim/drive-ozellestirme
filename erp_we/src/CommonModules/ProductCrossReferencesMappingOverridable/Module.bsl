/////////////////////////////////////////////////////////////////////////////////////////
// Comparison of the nomenclature of the counteragents is definable:
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
/////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region WorkingWithCatalogProductsOfCounterparties

// The event handler for the "Precontamination" form selection guide Nomenclaturachimica.
//
// Parameters:
//  Form                - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel                - Boolean                     - indicates that the form was not created.
//  StandardProcessing - Boolean                     - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingOnServer_FormForSelectingProductListOfCounterparties(Form, Cancel, StandardProcessing) Export
	PartnersProductsServer.WhenCreatingOnServer_FormForSelectingProductListOfCounterparties(Form, Cancel, StandardProcessing);
EndProcedure

// The event handler for the "Precontamination" form-list-directory of Nomenclaturachimica.
//
// Parameters:
//  Form                - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel                - Boolean                     - indicates that the form was not created.
//  StandardProcessing - Boolean                     - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingListOfCounterpartyProductsOnServer_Form(Form, Cancel, StandardProcessing) Export
	PartnersProductsServer.WhenCreatingListOfCounterpartyProductsOnServer_Form(Form, Cancel, StandardProcessing);
EndProcedure

// The event handler for the "Precontamination" form-group directory Nomenclaturachimica.
//
// Parameters:
//  Form                - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel                - Boolean                     - indicates that the form was not created.
//  StandardProcessing - Boolean                     - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingCounterpartyProductGroupFormOnServer(Form, Cancel, StandardProcessing) Export
	PartnersProductsServer.WhenCreatingCounterpartyProductGroupFormOnServer(Form, Cancel, StandardProcessing);
EndProcedure

// Handler of the "appendingserver" event of the form element of the Nomenclaturecontagents directory.
//
// Parameters:
//  Form                - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel                - Boolean                     - indicates that the form was not created.
//  StandardProcessing - Boolean                     - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingCounterpartyProductItemFormOn_Server(Form, Cancel, StandardProcessing) Export
	PartnersProductsServer.WhenCreatingCounterpartyProductItemFormOn_Server(Form, Cancel, StandardProcessing);
EndProcedure

// The event handler for the "Pictureinpicture" element form guide Nomenclaturachimica.
//
// Parameters:
//  Form         - ClientApplicationForm                - the form from which the procedure is called from the event handler.
//  CurrentObject - CatalogObject.ProductCrossReferences - the object of the counterparty's nomenclature.
//
Procedure WhenReadingOnServer_FormOfCounterpartyProductItem(Form, CurrentObject) Export
	PartnersProductsServer.WhenReadingOnServer_FormOfCounterpartyProductItem(Form, CurrentObject);
EndProcedure

// Handler of the "Before writing to the Server" event of the form element of the Nomenclature of Counterparties reference list.
//
// Parameters:
//  Form           - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel           - Boolean                     - indicates that the form was not created.
//  CurrentObject   - CatalogObject.ProductCrossReferences - the object of the counterparty's nomenclature.
//  WriteParameters - Structure                                 - the structure of the recording parameters.
//
Procedure BeforeRecordingOnServer_FormOfCounterpartyProductItem(Form, Cancel, CurrentObject, WriteParameters) Export
	PartnersProductsServer.BeforeRecordingOnServer_FormOfCounterpartyProductItem(Form, Cancel, CurrentObject, WriteParameters);
EndProcedure

// Handler for the "Post-Write Server" event of the form element of the Nomenclaturecontagents directory.
//
// Parameters:
//  Form           - ClientApplicationForm                - the form from which the procedure is called from the event handler.
//  CurrentObject   - CatalogObject.ProductCrossReferences - the object of the counterparty's nomenclature.
//  WriteParameters - Structure                                 - the structure of the recording parameters.
//
Procedure AfterRecordingOnServer_FormOfCounterpartyProductItem(Form, CurrentObject, WriteParameters) Export
	PartnersProductsServer.AfterRecordingOnServer_FormOfCounterpartyProductItem(Form, CurrentObject, WriteParameters);
EndProcedure

// Event handler for changing the item mapping field in the Nomenclature of Contractors directory.
// It is necessary to check the correctness of filling in the characteristics and packaging when changing the counterparty's nomenclature.
//
// Parameters:
//  Form               - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  ComparisonData - See ProductCrossReferencesMappingClientServer.NewMatchingData
//
Procedure WhenMatchingProductRangeChanges_CounterpartyProductRange(Form, ComparisonData) Export
	PartnersProductsServer.WhenMatchingProductRangeChanges_CounterpartyProductRange(Form, ComparisonData);
EndProcedure

// Handler of the event "Processing the receipt of the data of the selection" of the object manager of the Nomenclaturecontagent directory.
//
// Parameters:
//  ChoiceData         - ValueList - a list of the counterparty nomenclature to display to the user for selection.
//  Parameters            - Structure      - contains settings for the choice.
//  StandardProcessing - Boolean         - indicates standard event handling.
//
Procedure ProcessingOfSelectionDataAcquisition_ProductListOfCounterparties(ChoiceData, Parameters, StandardProcessing) Export
	PartnersProductsServer.ProcessingOfSelectionDataAcquisition_ProductListOfCounterparties(ChoiceData, Parameters, StandardProcessing);
EndProcedure

// Overrides the dynamic list request text for the Nomenclaturecontagent directory selection form.
// By default, the following parameters are available:
//  Empty nomenclature - Definable type.Nomenclatureabed-reference of the nomenclature.
//  Nomenclatureabor-definable type.Nomenclatureabed-reference of the nomenclature.
//  Characterizationselect-definabletype.Nomenclature specificationsbed-link to the characteristics of the nomenclature.
//  Packageabout-definabletype.Packaging Nomenclature - packaging/unit of measurement. If an
//                                                                        empty package/unit of measurement was passed to the counterparty's item selection form
//                                                                        , it will be re-filled with the item storage unit if the item was passed in the parameters.
// If necessary, additional parameters can be described in the method setParameters of the dynamic search_formateselection of the counteragent nomenclature.
//
// Parameters:
//  QueryText - String - query text.
//
Procedure DynamicListRequestText_CounterpartyProductSelectionForm(QueryText) Export
	PartnersProductsServer.DynamicListRequestText_CounterpartyProductSelectionForm(QueryText);
EndProcedure

// Overrides the dynamic list parameters for the Nomenclaturecontagent Directory selection form.
//
// Parameters:
//  Parameters - Structure          - parameters of the selection form.
//  List    - DynamicList - select list of the nomenclature of counterparties directory.
//
Procedure SetDynamicListParameters_CounterpartyProductSelectionForm(Parameters, List) Export
	PartnersProductsServer.SetDynamicListParameters_CounterpartyProductSelectionForm(Parameters, List);
EndProcedure

// Overrides the request for the counterparty item selection list.
// You must return the "Link" field in the request - links to the counterparty's item.
// The parameter value is available in the request: 
//  The owner of the nomenclature is a definable type.Owner Nomenclature-the owner for whom you need to create a selection list.
//  Nomenclature         - Definable type.Nomenclatured - range of the company to filter items of the company.
//  Characteristic-Definable type.Characteristic nomenclaturebed-a characteristic of the company's nomenclature for filtering the counterparty's nomenclature.
//  Packaging-Definable type.Packaging nomenclaturebed-packaging of the company's nomenclature for filtering the counterparty's nomenclature.
//
// Parameters:
//  Query - Query - request for a list of the counterparty's item selection.
//
Procedure RequestTextForCounterpartyProductSelectionList(Query) Export
	PartnersProductsServer.RequestTextForCounterpartyProductSelectionList(Query);
EndProcedure

#EndRegion

#Region WorkingWithUnitsOfMeasurement
// Defines the properties of the transferred package or unit of measurement according to the nomenclature of the information base.
// You need to fill in the properties of the transmitted package by item in the Package Properties parameter.
//
// Parameters:
//  Package         - DefinedType.PackageEDLItems - the package or unit of measurement of the item.
//  Products     - DefinedType.EDLProducts         - the nomenclature of the search for the base unit of measurement.
//  PackingProperties - Structure of See ProductCrossReferencesMappingClientServer.NewPackagingProperties - properties of the packaging.
//
Procedure WhenDeterminingPropertiesOfPackagingUnitsOfMeasurementOfNomenclature(Val Package, Val Products, PackingProperties) Export
	PartnersProductsServer.WhenDeterminingPropertiesOfPackagingUnitsOfMeasurementOfNomenclature(Package, Products, PackingProperties);
EndProcedure

// Searches for the name of the unit of measurement by the OKEI code in the classifier.
// You need to return the name of the unit of measurement or an empty string.
// Please note that the base unit of measurement can be a package.
// In this case, you need to change the transmitted OKEI code.
// For example: t (ton) will be the packing for kg (kilogram).
// It is recommended that if you do not find a unit of measurement in the reference book for the OKEI code,
// but it is in the classifier - upload the unit of measurement from the classifier to the database.
//
// Parameters:
//  OceaniaUnitCode      - String - The code for the OCEAN unit of measurement.
//  UnitOfMeasureDescription - String - the name of the unit of measurement found by the OKEI code.
//
Procedure FindUnitNameByOkeyCode(OceaniaUnitCode, UnitOfMeasureDescription) Export
	PartnersProductsServer.FindUnitNameByOkeyCode(OceaniaUnitCode, UnitOfMeasureDescription);
EndProcedure

// Returns whether the item is the owner of the package.
// It must be redefined if packages can be used in the database.
// You need to check the packaging for the owner and determine whether the item is the owner.
//
// Parameters:
//  Package                     - DefinedType.PackageEDLItems - reference to the packaging unit of measurement.
//  PackagingOwnerProductRange - Boolean                                  - indicates that the package owner is an item.
//
Procedure PackageOwnerUnitsOfMeasurementProducts(Val Package, PackagingOwnerProductRange) Export

	
	PartnersProductsServer.PackageOwnerUnitsOfMeasurementProducts(Package, PackagingOwnerProductRange);
EndProcedure

// Returns the base unit of measurement for the item.
//
// Parameters:
//  Products     - DefinedType.EDLProducts          - the link of the item.
//  UnitOfMeasure - DefinedType.PackageEDLItems - reference to the item's base unit of measurement.
//
Procedure BasicUnitOfProductMeasurement(Val Products, UnitOfMeasure) Export
	PartnersProductsServer.BasicUnitOfProductMeasurement(Products, UnitOfMeasure);
EndProcedure

#EndRegion

#Region ComparisonOfProductsInDocuments

// Redefines the text of the search query for an unrelated Product of counterparties for the Product of the information database.
// It is necessary to return the temporary Products table with columns:
//  Products            - Definable type.NomenclatoraBED - Product reference.
//  Characteristic - A definable type.SpecificationaNomencenturyBED - link characteristics.
//  Packaging is a definable type.Packaginganomencenturybed - package reference/units of measurement.
//  The nomenclature of the Contact is a reference link.Counteragents' Nomenclature - a reference to the counterparty's Product name.
//
// It needs to be redefined if the columns in the product table are named differently or if you want to replace the field values.
// When the attribute "Table of goods to silence = True" is set, the standard table of goods is used,
// if there is a substitution of field values, they must be executed.
// 
// Example:
// If There Is No table of goods by silence Then
//		
//		Query text = 
//		"SELECT
//		|T Items.The nomenclature of the counteragent AS the nomenclature of the counteragent,
//		|T Items.Product AS A Product,
//		|T Items.Characteristic AS A Characteristic,
//		|T Items.Packing AS Packing
//		|PLACE PRODUCTS
//		|FROM
//		|	&Goods AS Goods
//		| WHERE
//		|T Items.Products <> VALUE(Catalog.Products.Empty link)
//		|T Products.Partner Nomenclature <> VALUE(Catalog.Nomenclature of contragents.Empty link)";
//		
//		Query text = Query text + General purpose.Delimiterpackage of queries();
//		
//	The end if;
//	
//	Query text = Query text +
//	... (field substitution text).
//
// Parameters:
//  QueryText              - String - Query text
//  DefaultProductTable - Boolean - whether to use the default goods table with columns:
//   * Products            - DefinedType.EDLProducts               - the link of the item.
//   * Characteristic          - DefinedType.ItemsCharacteristicEDL - the characteristics link.
//   * Package                - DefinedType.PackageEDLItems       - reference of the package/unit of measurement.
//   * ProductCrossReference - CatalogRef.ProductCrossReferences     - reference of the counterparty's nomenclature.
//
Procedure TextOfSearchRequestForUnmappedProductListOfCounterpartiesForInformationSecurityProductList(QueryText, DefaultProductTable) Export
	PartnersProductsServer.TextOfSearchRequestForUnmappedProductListOfCounterpartiesForInformationSecurityProductList(
		QueryText, DefaultProductTable);
EndProcedure


#EndRegion


#Region WorkingWithInformationSecurityData


// Determines the owner of the item used by the counterparty.
//
// Parameters:
//  Counterparty - DefinedType.EDIParticipant - the counterparty for which you want to determine the owner of the item.
//  Owner - DefinedType.ItemOwnerEDL - the owner of the item (to be changed). By default, it is equal to the Counterparty parameter.
//
Procedure WhenDeterminingOwnerOfCounterpartySProductList(Val Counterparty, Owner) Export
		PartnersProductsServer.WhenDeterminingOwnerOfCounterpartySProductList(Counterparty, Owner);
EndProcedure

// Defines the properties of a set of items in the information base.
// Description of the properties in the method of mapping the nomenclature of the contragentsclientserver.New properties of nomenclatureib.
//
// Parameters:
//  SetOfProducts - Array of DefinedType.EDLProducts - references to the information security item that you want to define properties for.
//  PropertiesOfInformationSecurityProducts - Map - Contains:
//  * Key     - DefinedType.EDLProducts - link to the information security nomenclature.
//  * Value - Structure                       - contains the properties of the information security item.
//                                                 See ProductCrossReferencesMappingClientServer.NewPropertiesOfInformationSecurityProducts.
//
Procedure WhenDeterminingPropertiesOfInformationBaseProduct(Val SetOfProducts, PropertiesOfInformationSecurityProducts) Export
	PartnersProductsServer.WhenDeterminingPropertiesOfInformationBaseProduct(SetOfProducts, PropertiesOfInformationSecurityProducts);
EndProcedure

// Defines the form headers and item mapping fields, which may depend on the application solution and its settings.
//
// Parameters:
//  Presentations - Structure - a set of Presentations that can be overridden:
//   * OwnerOfProductItemPresentation    - String - representation of the item owner field.
//                                                            By default, it is taken from the Owner-nomenclature type being defined.
//   * ProductObjectPresentation            - String - representation of the item field.
//                                                            By default, it is taken from the defined nomenclatureabed type.
//   * FeaturePresentationOfObject          - String - representation of the item characteristics field.
//                                                            By default, it is taken from the defined type of the characteristic nomenclature of the DBED.
//   * PackagingObjectPresentation                - String - representation of the item packaging field.
//                                                            By default, it is taken from the package type being defined, the nomenclature of the FED.
//   * ProductsAndListPresentation  - String - representation of the list of the counterparty nomenclature.
//                                                            By default, "Counterparty Nomenclature".
//   * ItemProductsAndPresentation - String - representation of the object of the counterparty nomenclature.
//                                                            By default, "Counterparty Nomenclature".
//   * OwnerOfProductInGenitiveCase      - String - representation of the item owner field in the genitive case.
//                                                            By default, "Counterparty".
//
// Example:
//  Representations.Nomenclaturecontragentapresentationdisk = NStr("ru = 'Product list of partners'");
//  Representations.Item nomenclaturecontent representationobject = NStr("ru = 'Partner's Product list'");
//  Representations.The owner of the nomenclature is the representation of the object = NStr("ru = 'Partner'");
//  Representations.The owner of the nomenclature of the parent company is also = NStr("ru = 'Partner'").
//
Procedure WhenDefiningPresentationsOfProductCollation(Presentations) Export
	PartnersProductsServer.WhenDefiningPresentationsOfProductCollation(Presentations);
EndProcedure

// Defines the relationship between the parts of the nomenclature of the information base.
// Sets the dependence of the characteristics and packages on the nomenclature.
// Used when filling in the "Link of Selection parameters" property in the form elements.
//
// Parameters:
//  ProductStructure_ - Structure - description of the structure of the nomenclature of the information base (to be changed):
//   * NameOfCharacteristicLinkParameter - String - name of the link parameter for selecting a characteristic by item. By default, " Selection.The owner."
//   * NameOfPackageConnectionParameter - String - name of the package selection link parameter for the item. By default, " Selection.The owner."
//
Procedure WhenDeterminingStructureOfProductOfInformationBase(ProductStructure_) Export
	PartnersProductsServer.WhenDeterminingStructureOfProductOfInformationBase(ProductStructure_);
EndProcedure

// Defines the combination barcode( item, feature, package) and item barcodes.
// You must fill in the Barcode and other Barcode nomenclature parameters with the barcodes found.
//
// Parameters:
//  InformationSecurityProducts              - See ProductCrossReferencesMappingClientServer.NewProductsOfInformationBase
//  Barcode                    - String           - combination barcode: nomenclature, characteristics, packaging.
//  OtherProductsBarcodes - Array of String - Barcodes of the nomenclature.
//
Procedure WhenDeterminingBarcodesOfCounterpartySProductRange(Val InformationSecurityProducts, Barcode, OtherProductsBarcodes) Export
	PartnersProductsServer.WhenDeterminingBarcodesOfCounterpartySProductRange(InformationSecurityProducts, Barcode, OtherProductsBarcodes);
EndProcedure

// In the procedure, it is required to determine the sign of using the characteristics of the nomenclature in the information security.
//
// Parameters:
//  ItemVariantsAreUsed - Boolean - The information base uses the characteristics of the nomenclature.
//
Procedure CheckUsageCharacteristics(ItemVariantsAreUsed) Export
		
EndProcedure

#EndRegion


#Region AccessManagement

// See AccessManagementOverridable.OnFillAccessRestriction
Procedure WhenFillingInAccessRestriction_ProductListOfCounterparties(Restriction) Export
	PartnersProductsServer.WhenFillingInAccessRestriction_ProductListOfCounterparties(Restriction);
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
Procedure WhenFillingInListsWithRestrictedAccess_ProductsOfCounterparties(Lists) Export
	PartnersProductsServer.WhenFillingInListsWithRestrictedAccess_ProductsOfCounterparties(Lists);
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds
Procedure WhenFillingInTypesOfRightsRestrictionsForMetadataObjects_ProductListOfCounterparties(LongDesc) Export
	PartnersProductsServer.WhenFillingInTypesOfRightsRestrictionsForMetadataObjects_ProductListOfCounterparties(LongDesc);
EndProcedure

#EndRegion

#Region ObjectVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
//
Procedure WhenDefiningObjectVersioningSettings_ProductListOfCounterparties(Settings) Export
	
EndProcedure

#EndRegion

#EndRegion
