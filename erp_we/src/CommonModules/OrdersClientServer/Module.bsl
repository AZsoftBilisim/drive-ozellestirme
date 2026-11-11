#Region Public

#Region StructureOfActions

// Adds the "Fill in the order sign" action to the action structure
//
// Parameters:
//  StructureOfActions - Structure - structure of actions
//  ByOrders         - Boolean    -
// 
Procedure AddActionFillInDiscrepancyOrderAttribute(StructureOfActions, ByOrders) Export
	
	If Not ByOrders Then
		Return;
	EndIf;
	
	StructureOfActions.Insert(
		"FillInDiscrepancyAttributeOrder", FillInParametersFlagDiscrepancyOrder(ByOrders));
	
EndProcedure

//Returns parameters for filling in the "Order divergence" attribute
//
// Parameters:
//  ByOrders - Boolean -
//
// Returns:
//  Structure - Contains:
//               *ByOrders - Boolean -
//
Function FillInParametersFlagDiscrepancyOrder(ByOrders) Export

	Return New Structure("ByOrders", ByOrders);

EndFunction

#EndRegion

#EndRegion