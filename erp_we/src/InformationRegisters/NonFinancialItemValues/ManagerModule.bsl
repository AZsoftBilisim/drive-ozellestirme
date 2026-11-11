
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
	|	( Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef)
	|	OR ValueAllowed(Scenario)
	|	) AND ( Organization = VALUE(Catalog.Companies.EmptyRef)
	|	OR ValueAllowed(Organization)
	|	) AND ( Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|	OR ValueAllowed(Department)
	|	) AND ValueAllowed(NonFinancialItem)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
