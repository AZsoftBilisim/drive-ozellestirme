/////////////////////////////////////////////////////////////////////////////////////////
// Comparison of Nomenclature of Counterparties Client: 
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region WorkingWithCatalogProductsOfCounterparties

// Opens the form for selecting the Nomenclaturecontagents directory.
//
// Parameters:
//  FormParameters      - Structure                  - shape parameter.
//  FormOwner       - ClientApplicationForm - owner of the form.
//  ClosingNotification1 - CallbackDescription         - notifications to be executed after the form is closed.
//  WindowOpeningMode   - FormWindowOpeningMode     - the mode in which to open the form window.
//
Procedure OpenCounterpartyProductSelectionForm(Val FormParameters,
		Val FormOwner = Undefined, Val ClosingNotification1 = Undefined, Val WindowOpeningMode = Undefined) Export
		
	OpenForm("Catalog.ProductCrossReferences.Form.ChoiceForm",
		FormParameters, FormOwner, , , , ClosingNotification1, WindowOpeningMode);
		
EndProcedure

// Opens the list form of the Nomenclaturecontagents directory.
//
// Parameters:
//  FilterParameters     - Structure                  - form selection parameters.
//  FormOwner       - ClientApplicationForm - owner of the form.
//  ClosingNotification1 - CallbackDescription         - notifications to be executed after the form is closed.
//  WindowOpeningMode   - FormWindowOpeningMode     - the mode in which to open the form window.
//
Procedure OpenCounterpartyProductListForm(Val FilterParameters,
		Val FormOwner = Undefined, Val ClosingNotification1 = Undefined, Val WindowOpeningMode = Undefined) Export
	
	OpenForm("Catalog.ProductCrossReferences.Form.ListForm",
		FilterParameters, FormOwner, , , , ClosingNotification1, WindowOpeningMode);

EndProcedure

// Returns a list of the current item of the counterparty, taking into account the filter by owner, item, characteristic, and package.
//
// Parameters:
//  ItemOwner - DefinedType.ItemOwnerEDL       - the owner for which you want to create a list of choices.
//  Products         - DefinedType.EDLProducts               - the range of the company to filter items of the company.
//  Characteristic       - DefinedType.ItemsCharacteristicEDL - characteristics of the company's nomenclature
//                                                                         for filtering the counterparty's nomenclature.
//  Package             - DefinedType.PackageEDLItems       - packaging an enterprise item
//                                                                         to filter the counterparty item.
//
// Returns:
//   Array of CatalogRef.ProductCrossReferences - the counterparty's nomenclature suitable for filtering conditions.
//
Function CreateListForSelectingCounterpartyProducts(Val ItemOwner, Val Products, Val Characteristic, Val Package) Export

	Return ProductCrossReferencesMappingInternalServerCall.CreateListForSelectingCounterpartyProducts(
		ItemOwner, Products, Characteristic, Package);
	
EndFunction

#EndRegion


#EndRegion