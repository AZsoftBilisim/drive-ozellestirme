#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds the enumeration "Types of primary documents" to the passed value parameter
//
// Parameters:
//  ChoiceData - ValueList of EnumRef.SourceDocumentTypes
//  			 - Array of EnumRef.SourceDocumentTypes - the collection to which you add the values of the enumeration
//  Parameters    - See UsageParameters
//
Procedure FillInSelectionData(ChoiceData, Val Parameters = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = UsageParameters();
	EndIf;
	
	ChoiceData.Clear();
	
	For Each Parameter In Parameters Do
		
		If Parameter.Value Then
			ChoiceData.Add(Enums.SourceDocumentTypes[Parameter.Key]);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns parameters for using primary document types.
//
// Returns:
//  Structure - Contains:
//   * PurchaseFromVendor     - Boolean - 
//   * SaleToCustomer           - Boolean - 
//   * PurchaseAdjustment   - Boolean - 
//   * SaleAdjustment     - Boolean - 
//   * PaymentToVendor            - Boolean - 
//   * PaymentFromCustomer             - Boolean -
//   * CustomerBonusCertificate            - Boolean -
//   * VendorBonusCertificate         - Boolean -
//   * InternalInvoice         - Boolean -
//   * PurchaseViaAdvanceHolder - Boolean -
//   * VMIProcurement             - Boolean -
//   * ReportToMaterialProvider               - Boolean -
//   * SubcontractorReport          - Boolean -
//
Function UsageParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("PurchaseFromVendor",     True);
	Parameters.Insert("SaleToCustomer",           True);
	Parameters.Insert("PaymentToVendor",            True);
	Parameters.Insert("PaymentFromCustomer",             True);
	Parameters.Insert("InternalInvoice",         True);
	Parameters.Insert("PurchaseViaAdvanceHolder", True);
	Parameters.Insert("VMIProcurement",             False);
	Parameters.Insert("ReportToMaterialProvider",               False);
	Parameters.Insert("SubcontractorReport",          False);
	Parameters.Insert("PurchaseAdjustment",   GetFunctionalOption("UseDebitNotes"));
	Parameters.Insert("SaleAdjustment",     GetFunctionalOption("UseCreditNotes"));
	Parameters.Insert("CustomerBonusCertificate",            GetFunctionalOption("UseCustomerRebates"));
	Parameters.Insert("VendorBonusCertificate",         GetFunctionalOption("UseVendorRebates"));
	
	Parameters.Insert("GoodsShipmentToCustomer",
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5"));
	UseTollManufacturing2_5 =
		GetFunctionalOption("UseTollManufacturing2_5");
	
	Parameters.Insert(
		"VMIProcurement",
		UseTollManufacturing2_5);
	
	Parameters.Insert(
		"ReportToMaterialProvider",
		UseTollManufacturing2_5);
	UseProductionByThirdParty2_5 =
		GetFunctionalOption("UseProductionByThirdParty2_5");
		
	Parameters.Insert("SubcontractorReport", UseProductionByThirdParty2_5);
	Return Parameters;
	
EndFunction

#EndRegion

#EndIf