////////////////////////////////////////////////////////////////////////////////
// Subsystem "Commercial offers documents".
// General module.Commercial propositiondocumentservereferencesexternal links
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The ability to override the presentation of the item to be printed.
//
// Parameters:
//  PresentationForPrinting - String - it is intended for storing the generated view.
//  Products           - DefinedType.EDLProducts - Nomenclature.
//  Characteristic         - DefinedType.ItemsCharacteristicEDL - characteristic.
//  StandardProcessing   - Boolean - this parameter is passed to indicate that standard (system) processing of view generation is performed.
//      If this parameter is set to False in the body of the handler procedure, standard event processing will not be performed.
//
Procedure CreatePresentationOfProductsForPrinting(PresentationForPrinting, Products, Characteristic, StandardProcessing) Export
	
	CommercialProposalsDocumentsClientServerTM.CreatePresentationOfProductsForPrinting(PresentationForPrinting, Products, Characteristic, StandardProcessing)
	
EndProcedure

// Ability to create a view of the status of the document "Commercial offer to the client", based on the status of the document and other data. 
//
// Parameters:
//  Form        - ClientApplicationForm - the form from which this procedure is called.
//  Status       - DefinedType.StatusesOfCommercialProposalsForCustomers - document status.
//  CurrentDate  - Date - Current date.
//
Procedure GenerateStatePresentationByStatus(Form, Status, CurrentDate) Export
	
	CommercialProposalsDocumentsClientServerTM.GenerateStatePresentationByStatus(Form, Status, CurrentDate);
	
EndProcedure

// Set the parameters of the product line when loading Bidzaar totals.
// 
// Parameters:
//  String - FormDataCollectionItem - Row Of The Products Table
//  Parameters - FormDataCollectionItem - Fill-in values from the Bidzaar service
Procedure SetParametersOfGoodsRowWhenLoadingBidzaarTotals(String, Parameters) Export

	String.VATAmount = PriceManagementSystemClientServer.CalculateVATAmount(String.Sum, String.VATRate,
		String.PriceIncludesVAT);

EndProcedure

// Add the necessary data to the context to create orders for suppliers.
// 
// Parameters:
//  Context - Structure - Data required to create orders for suppliers
Procedure AddContextForCreatingOrdersToSuppliers(Context) Export

	Taxation = CommonClientServer.StructureProperty(Context, "Taxation");
	If Taxation <> Undefined Then
		Context.Insert("VATTaxation", ?(Taxation,
	 						PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT"),
	 						PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT")));
	EndIf;

EndProcedure

// the item storage unit.
// 
// Parameters:
//  Products - DefinedType.EDLProducts
// 
// Returns:
//  DefinedType.PackageEDLItems - Product Storage Unit
Function ProductStorageUnit(Products) Export
	
	Return ProductsServerCall.ProductStorageUnit(Products);
	
EndFunction

#EndRegion
