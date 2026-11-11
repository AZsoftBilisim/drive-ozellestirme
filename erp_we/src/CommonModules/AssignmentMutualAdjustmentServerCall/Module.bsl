/////////////////////////////////////////////////////////////////////////////
// The module "Counter-correction of the Server call assignments" contains procedures 
// and functions for working with the counter-correction mechanism.
//
/////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns data for counter adjustment of the destination
//
// Parameters:
//  Parameters - See AssignmentMutualAdjustment.DestinationCounterAdjustmentData.Parameters
//  UUID - UUID - id of the form for placing the selection of goods in the storage
//
// Returns:
//  See AssignmentMutualAdjustment.DestinationCounterAdjustmentData
//
Function DestinationCounterAdjustmentData(Parameters, UUID) Export
	
	Return AssignmentMutualAdjustment.DestinationCounterAdjustmentData(Parameters, UUID);
	
EndFunction

#EndRegion
