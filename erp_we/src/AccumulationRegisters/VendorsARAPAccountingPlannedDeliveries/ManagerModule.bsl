
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS T1 
	|	ON T.AccountingDimensionByPartners = T1.DimensionKey
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T1.Organization)
	|	AND ValueAllowed(T1.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf