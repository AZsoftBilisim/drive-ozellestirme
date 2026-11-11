#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns whether the register resource names correspond to the types of normalized expenses.
//
// Returns:
// 	Map of KeyAndValue:
// 		* Key - String - Name of the register resource.
// 		* Value - String - Name of the type of normalized expense.
//
Function NamesOfTypesOfNormalizedExpenses() Export
	
	TypesOfExpenses = New Map; 
	TypesOfExpenses.Insert(
		"ShareOfAdvertisingExpenses",
		"AdvertisingExpensesNormalized");
	TypesOfExpenses.Insert(
		"ShareOfRepresentativeExpenses",
		"RepresentationalExpenses");
	TypesOfExpenses.Insert(
		"ShareOfMedicalInsuranceExpenses",
		"VoluntaryPersonalInsurance");
	TypesOfExpenses.Insert(
		"ShareOfLifeInsuranceExpenses",
		"VoluntaryAccordingToContractsLongTermLifeInsuranceEmployees");
	TypesOfExpenses.Insert(
		"ShareOfAccidentInsuranceExpenses",
		"VoluntaryPersonalInsuranceInCaseOfDeathOrDisability");
	TypesOfExpenses.Insert(
		"ShareOfInterestRepaymentToEmployeesExpenses",
		"ExpensesForCompensationOfEmployeeCostsForPayingInterest");
		
	Return TypesOfExpenses;
		
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
