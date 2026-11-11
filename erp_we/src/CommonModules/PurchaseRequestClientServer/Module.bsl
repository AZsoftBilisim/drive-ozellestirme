
#Region Public

#Region InterfaceImplementation

#EndRegion

#EndRegion

#Region Internal

#Region BDRLimits

// The target of the purchase, which is filled in when the functional option of the BDR limits is disabled.
// 
// Returns:
//  EnumRef.PurchaseObjectives - Default Purchase Target
Function DefaultPurchaseTarget() Export
	Return PredefinedValue("Enum.PurchaseObjectives.CoreActivity");
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region BatchProcessingOfTablePart

// Forms the structure of actions for processing the tabular part on changing the number of packages.
// 
// Parameters:
//  PriceIncludesVAT - Boolean - The Attribute of the item with the same name.
// 
// Returns:
//  Structure - Actions When Changing The Quantity:
// * RecalculateNumberOfUnits - Undefined - Property that enables the action of converting packages into units.
//
// * RecalculateAmount - Undefined - Property that enables the action of recalculating the amount.
// * RecalculateVATAmount - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
// * RecalculateAmountWithVAT - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
Function ActionsWhenChangingQuantity(PriceIncludesVAT) Export
	
	Actions = New Structure;
	Actions.Insert("RecalculateNumberOfUnits", Undefined);
	CommonClientServer.SupplementStructure(Actions, ActionsForRecalculatingAmount(PriceIncludesVAT), True);
	
	//@skip-check constructor-function-return-section -- When the structure is supplemented, the properties are not recognized.
	Return Actions;
	
EndFunction

// Forms a structure of actions to fill in the price type and dependent properties.
// 
// Parameters:
//  Object -  
//  - FormDataStructure:
//  	* Date - Date
//  	* Organization - CatalogRef.Companies
//  	* PriceIncludesVAT - Boolean
//  	* Currency - CatalogRef.Currencies
//  - DocumentObject.PurchaseRequest 
// 
// Returns:
//  Structure - Actions To Fill In The Price:
// * FillInTermsOfPurchase - See BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine.
//
// * RecalculateAmount - Undefined - Property that enables the action of recalculating the amount.
// * RecalculateVATAmount - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
// * RecalculateAmountWithVAT - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
Function ActionsForFillingInPriceType(Object) Export

	Actions = New Structure;
	
	FillParameters = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object);
	FillParameters.UseAgreementFromTable = True;
	FillParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	Actions.Insert("FillInTermsOfPurchase", FillParameters);
	
	CommonClientServer.SupplementStructure(Actions, ActionsForRecalculatingAmount(Object.PriceIncludesVAT), True);
	
	//@skip-check constructor-function-return-section -- When the structure is supplemented, the properties are not recognized.
	Return Actions;
		
EndFunction

// Forms a structure of actions to fill in the price and dependent properties.
// 
// Parameters:
//  Object -  
//  - FormDataStructure:
//  	* Date - Date
//  	* Organization - CatalogRef.Companies
//  	* PriceIncludesVAT - Boolean
//  	* Currency - CatalogRef.Currencies
//  - DocumentObject.PurchaseRequest
// 
// Returns:
//  Structure - Actions To Fill In The Price:
// * FillInPurchasePrice - See BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine.
//
// * RecalculateAmount - Undefined - Property that enables the action of recalculating the amount.
// * RecalculateVATAmount - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
// * RecalculateAmountWithVAT - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
Function ActionsToFillInPrice(Object) Export

	Actions = New Structure;
	
	FillParameters = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object);
	FillParameters.UseAgreementFromTable = True;
	FillParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	Actions.Insert("FillInPurchasePrice", FillParameters);
	
	CommonClientServer.SupplementStructure(Actions, ActionsForRecalculatingAmount(Object.PriceIncludesVAT), True);
	
	//@skip-check constructor-function-return-section -- When the structure is supplemented, the properties are not recognized.
	Return Actions;
	
EndFunction

// Forms a structure with actions to fill in VAT taxation based of operation.
// Recalculates the rate and the VAT amount.
//
// Parameters:
//  Object -  
//  - FormDataStructure:
//  	* Date - Date
//  	* Ref - DocumentRef.PurchaseRequest
//  	* Organization - CatalogRef.Companies
//  	* PriceIncludesVAT - Boolean
//   SpecifiedVATRate - See ActionsForFillingInVATRate.SpecifiedVATRate
//
// Returns:
//   Structure:
//   * FillInVATTaxationPurchases - See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
Function ActionsOfFillingInVATTaxation(Object, SpecifiedVATRate = Undefined) Export
	
	Actions = New Structure;
	
	// Taxation of VAT is calculated according to the household. of operations. The Attribute is missing from the purchase request,
	//    Therefore, the Attributes of the form are calculated first, and then the taxation is filled in.
	CommonClientServer.SupplementStructure(Actions, ActionsOfFillingInBusinessOfOperation());
	
	FillParameters = VATAccountingERPClientServer.ParametersOfBatchFillingInOfTaxationVATPurchases();
	FillParameters.Date = Object.Date;
	FillParameters.Document = Object.Ref;
	Actions.Insert("FillInVATTaxationPurchases", FillParameters);
	
	// Recalculation of the VAT amount on changes in the rate.
	CommonClientServer.SupplementStructure(
		Actions,
		VATRateAdjustmentActions(Object, SpecifiedVATRate),
		True);
	
	Return Actions;
	
EndFunction

// Forms the structure of actions for filling in the Attributes of the "Business Operation" form of the tabular part. 
//
// Returns:
//   Structure:
//    * CompleteOfOperationAccordingToAgreementContract - See BatchProcessingOfTablePartClientServer.ParametersForFillingOfOperationsByAgreementContract.
Function ActionsOfFillingInBusinessOfOperation() Export
	
	Actions = New Structure;
	
	FillParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingOfOperationsByAgreementContract();
	FillParameters.DefaultValue = PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier");
	Actions.Insert("CompleteOfOperationAccordingToAgreementContract", FillParameters);
	
	Return Actions;
	
EndFunction

// Forms the structure of actions for the VAT rate and dependent properties.
// 
// Parameters:
//  Object -  
//  - FormDataStructure:
//  	* Date - Date
//  	* Organization - CatalogRef.Companies
//  	* PriceIncludesVAT - Boolean
//  - DocumentObject.PurchaseRequest
//  SpecifiedVATRate - Undefined, CatalogRef.VATRates - VAT rate specified in the document
//
// Returns:
//  Structure - Actions To Fill In The Price:
// * FillInVATRate - See BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate.
//
// * RecalculateAmount - Undefined - Property that enables the action of recalculating the amount.
// * RecalculateVATAmount - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
// * RecalculateAmountWithVAT - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS.
Function ActionsForFillingInVATRate(Object, SpecifiedVATRate = Undefined) Export
	
	Actions = New Structure;
	
	FillParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	FillParameters.SpecifiedVATRate = SpecifiedVATRate;
	FillParameters.VATTaxationAtTabularPart = True;
	Actions.Insert("FillInVATRate", FillParameters);
	
	CommonClientServer.SupplementStructure(Actions, ActionsForRecalculatingAmount(Object.PriceIncludesVAT, False), True);
	
	//@skip-check constructor-function-return-section -- When the structure is supplemented, the properties are not recognized.
	Return Actions;
	
EndFunction

// Forms the structure of actions for the VAT rate and dependent properties.
// 
// Parameters:
//  Object -  
//  - FormDataStructure:
//  	* Date - Date
//  	* Organization - CatalogRef.Companies
//  	* PriceIncludesVAT - Boolean
//  - DocumentObject.PurchaseRequest
//	SpecifiedVATRate - Undefined, CatalogRef.VATRates - VAT rate specified in the document
// Returns:
//  Structure - Actions To Fill In The Price:
// * AdjustVATRate - See BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate.
Function VATRateAdjustmentActions(Object, SpecifiedVATRate = Undefined) Export
	
	Actions = New Structure;
	
	FillParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	FillParameters.SpecifiedVATRate = SpecifiedVATRate;
	FillParameters.VATTaxationAtTabularPart = True;
	FillParameters.InitializingIncomingDocument = True;
	Actions.Insert("AdjustVATRate", FillParameters);
	
	Return Actions;
	
EndFunction

// Forms the structure of actions for processing the tabular part for calculating amounts
// 
// Parameters:
//  PriceIncludesVAT - Boolean - The Attribute of the item with the same name.
//  RecalculateAmount - Boolean - Enables/disables the calculation of the amount. "False" is indicated, for example, in cases:
//		a) The amount is changed and it is necessary to calculate the VAT and the amount with VAT.
//		b) VAT is adjusted.
//  RecalculateVATAmount - Boolean - Enables/disables VAT calculation. "False" is indicated if the VAT amount is adjusted.
// 
// Returns:
//  Structure - Actions For Recalculating The Amount:
// * RecalculateAmount - Undefined - Property that enables the action of recalculating the amount.
// * RecalculateVATAmount - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS
// * RecalculateAmountWithVAT - See BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS
Function ActionsForRecalculatingAmount(PriceIncludesVAT, RecalculateAmount = True, RecalculateVATAmount = True) Export
	
	ObjectSimulation = New Structure;
	ObjectSimulation.Insert("PriceIncludesVAT", PriceIncludesVAT);
	RecalculationParameters = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ObjectSimulation);
	
	Actions = New Structure;
	If RecalculateAmount Then
		Actions.Insert("RecalculateAmount", Undefined);
	EndIf;
	
	If RecalculateVATAmount Then
		Actions.Insert("RecalculateVATAmount", RecalculationParameters);
	EndIf;
	
	Actions.Insert("RecalculateAmountWithVAT", RecalculationParameters);
	
	Return Actions;
	
EndFunction

#EndRegion

#EndRegion