#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function determines whether or not partner access groups are used
//
//	Returns:
//		Boolean - if TRUE, then access groups are used.
//
Function AccessGroupsAreUsed() Export
	
	Return
		GetFunctionalOption("LimitAccessAtRecordLevel")
		And GetFunctionalOption("UsePartnerAccessGroups");
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf