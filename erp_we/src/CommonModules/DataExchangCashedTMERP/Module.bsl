#Region Public

// Determines whether this information base
// is a subordinate RIB node with filters by division.
//
// Returns:
//  Boolean - a sign of a subordinate RIB node with filters.
Function ItIsSubordinateNodeToRibsBySelection() Export
	
	Return Common.IsSubordinateDIBNodeWithFilter();
	
EndFunction

#EndRegion