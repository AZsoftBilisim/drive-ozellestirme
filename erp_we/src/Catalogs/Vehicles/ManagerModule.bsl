// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region InterfaceImplementation

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
// 
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array; // Array of String
	NotAttributesToEdit.Add("CapacityPresentation");
	NotAttributesToEdit.Add("TrailerRegPlate");
	NotAttributesToEdit.Add("LicenseCardKind");
	NotAttributesToEdit.Add("LicenseCardNumber");
	NotAttributesToEdit.Add("RegistrationNumberOfLicenseCard");
	NotAttributesToEdit.Add("LicenseCardSeries");
	
	Return NotAttributesToEdit;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	GoodsDeliveryServerCall.VehiclesProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion