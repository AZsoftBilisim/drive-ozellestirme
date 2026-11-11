// @strict-types

#Region Internal

// Indicates that any delivery is being used in the system
// 
// Returns:
//  Boolean 
//
Function UsedDelivery() Export
	
	Return GetFunctionalOption("UseDeliveryManagement");
	
EndFunction

// Indicates that version 2.0 delivery is being used in the system
// 
// Returns:
//  Boolean 
//
Function UsedDelivery20() Export
	
	Return GetFunctionalOption("UseDeliveryManagement")
			And GetFunctionalOption("NotUseDeliveryManagement25");
	
EndFunction

// Indicates that version 2.5 delivery is being used in the system
// 
// Returns:
//  Boolean 
//
Function UsedDelivery25() Export
	
	Return GetFunctionalOption("UseDeliveryManagement")
			And GetFunctionalOption("NotUseDeliveryManagement20");
	
EndFunction

#EndRegion