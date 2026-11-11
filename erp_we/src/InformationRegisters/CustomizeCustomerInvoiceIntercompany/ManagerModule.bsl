#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(CompanyOwner)
	|	OR ValueAllowed(CompanyCustomer)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion
	
#Region InfobaseUpdate

#EndRegion

#EndIf
