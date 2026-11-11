
#Region Internal

#Region FillingAppointments

// See ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase
// 
// Returns:
//  Boolean - It is necessary to update the parameters of filling assignments when changing products
Function ItIsNecessaryToUpdateParametersForFillingAssignmentsWhenChangingProducts(Object, CurrentData, CachedValues) Export
	
	Return Object.DynamicStructure
		And (
			CurrentData.Purpose <> CachedValues.Purpose
			Or CurrentData.Canceled <> CachedValues.Canceled
		);
	
EndFunction

#EndRegion

#EndRegion
