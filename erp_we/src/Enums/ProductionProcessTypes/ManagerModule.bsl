#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a list of available production process types depending on the current values of the functional options
//
// Parameters:
//  DynamicStructure	 - Boolean	 - option value (contextual)
// 
// Returns:
//  Array - array of available production process types
//
Function AvailableTypes(DynamicStructure = Undefined) Export
	
	If DynamicStructure = Undefined Then
		DynamicStructure = False;
		DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	EndIf;

	ProcessTypes = New Array();
	
	ProcessTypes.Add(Enums.ProductionProcessTypes.Assembly);
	
	If DynamicStructure Then
		ProcessTypes.Add(Enums.ProductionProcessTypes.PerformRM);
	Else
		ProcessTypes.Add(Enums.ProductionProcessTypes.Repair);
		ProcessTypes.Add(Enums.ProductionProcessTypes.WithoutBillsOfMaterials);
	EndIf;
	
	ProcessTypes.Add(Enums.ProductionProcessTypes.Disassembly);
	
	Return ProcessTypes;

EndFunction

#EndRegion

#EndIf
