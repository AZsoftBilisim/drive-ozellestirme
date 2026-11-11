
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
	|	ValueAllowed(PriceKind)";
	
	Restriction.TextForExternalUsers1 =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(PriceKind)
	|	AND PriceKind.UseWhileSellingToCustomers";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
