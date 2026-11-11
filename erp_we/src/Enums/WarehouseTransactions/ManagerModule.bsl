#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Checks whether the array contains warehouse operations of the "Acceptance" type.
//
// Parameters:
//	WarehouseTransactions - Array - array of values of warehouse operations.
//
// Returns:
//	Boolean - True, among the array elements there is a warehouse operation of the "Prika" type.
//
Function ThereIsAcceptance(WarehouseTransactions) Export
	
	Return WarehousesClientServer.ThereIsAcceptance(WarehouseTransactions);
	
EndFunction

// Returns an array of values for warehouse operations of the "Acceptance" type"
//
// Returns:
//	Array - array of values of warehouse operations.
//
Function WarehouseOperationsOfGoodsAcceptance() Export
	
	Return WarehousesClientServer.WarehouseOperationsOfGoodsAcceptance();
	
EndFunction

// Checks whether the array contains warehouse operations of the "Shipment" type.
//
// Parameters:
//	WarehouseTransactions - Array - array of values of warehouse operations.
//
// Returns:
//	Boolean - True, among the array elements there is a warehouse operation of the "Shipment" type.
//
Function ThereIsShipment(WarehouseTransactions) Export
	
	Return WarehousesClientServer.ThereIsShipment(WarehouseTransactions);
	
EndFunction

// Returns an array of values for warehouse operations of the "Shipment" type"
//
// Returns:
//	Array - array of values of warehouse operations.
//
Function WarehouseShippingOperations() Export
	
	Return WarehousesClientServer.WarehouseShippingOperations();

EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not GetFunctionalOption("UseProduction") Then
		
		StandardProcessing = False;
		
		ArrayOfExcludedValues = New Array;
		ArrayOfExcludedValues.Add(PredefinedValue("Enum.WarehouseTransactions.ProductReceivingFromManufacturing"));
		
		GeneralPurposeTMServerCall.SelectableEnumerationValues(
			"WarehouseTransactions",
			ChoiceData,
			Parameters,
			ArrayOfExcludedValues);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

