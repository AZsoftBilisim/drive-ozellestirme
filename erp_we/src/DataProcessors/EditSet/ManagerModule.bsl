#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes the parameters for verifying the correctness of the set.
//
// Parameters:
//	Object - DataProcessorObject.EditSet,
//				This Formstructure is a document for which it is necessary to obtain the parameters of the kit verification.
//
// Returns:
//	Structure - See AccountingForTraceableGoodsLocalization.SetValidationParameters.
//
Function SetValidationParameters(Object) Export
	
	ProductConfigurationOptions = SetsServerCall.ProductConfigurationOptions(
													Object.ProductsInSet,
													Object.ItemVariantOfSet);
	
	RowFilter = New Structure;
	RowFilter.Insert("Products",		ProductConfigurationOptions.ProductsOfMainComponent);
	RowFilter.Insert("Characteristic",	ProductConfigurationOptions.MainComponentCharacteristic);
	
	Main_Components = Object.Components.FindRows(RowFilter);
	
	CheckParameters = AccountingForTraceableGoodsLocalization.SetValidationParameters();
	CheckParameters.Date				= Object.Date;
	CheckParameters.KitAssembly	= Object.BusinessOperation <> Enums.BusinessTransactions.DisassemblyIntoComponents;
	
	CheckParameters.Products		= Object.ProductsInSet;
	CheckParameters.Characteristic	= Object.ItemVariantOfSet;
	
	If Main_Components.Count() Then
		FillPropertyValues(CheckParameters, ProductConfigurationOptions);
	EndIf;
	
	CheckParameters.TSName = "Components";
	
	Return CheckParameters;
	
EndFunction

#EndRegion

#EndIf
