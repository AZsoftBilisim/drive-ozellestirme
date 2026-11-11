#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds an enumeration of "cost Groupings in the order to the processor" to the passed parameter value"
//
// Parameters:
//  ChoiceData - ValueList, Array - the collection to which you add the values of the enumeration
//  Parameters    - See UsageParameters
//
Procedure FillInSelectionData(ChoiceData, Val Parameters = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = UsageParameters();
	EndIf;
	
	ChoiceData.Clear();
	
	For Each Parameter In Parameters Do
		
		If Parameter.Value Then
			ChoiceData.Add(Enums.CostGroupingsInTollingOrder[Parameter.Key]);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns parameters for using cost grouping.
//
// Returns:
//  Structure - Contains:
//   * NoGrouping          - Boolean - 
//   * ByProducts             - Boolean - 
//   * ByProductBOM         - Boolean - 
//   * ByProductionStages    - Boolean -
//   * ByProductionOrders - Boolean -
//
Function UsageParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("NoGrouping",              True);
	Parameters.Insert("ByProducts",                 True);
	Parameters.Insert("ByProductsAndAssignments",     False);
	Parameters.Insert("ByProductBOM",             True);
	Parameters.Insert("ByProductBOMAndAssignments", False);
	Parameters.Insert("ByProductionStages",        False);
	Parameters.Insert(
		"ByProductionStages",
		GetFunctionalOption("UseProductionManagement2_2"));
	
	Return Parameters;
	
EndFunction

#EndRegion

#EndIf