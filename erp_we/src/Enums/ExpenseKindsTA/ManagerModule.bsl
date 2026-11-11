#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns an array of types of expenses that are normalized in tax accounting,
// because Chapter 25 of the Tax Code of the Russian Federation provides for amount limits for them
// 
// Returns:
//  Array of EnumRef.ExpenseKindsTA - Rationing Expenses
//
Function RationingExpenses() Export
	
	RationingExpenses = NormalizedExpensesLaborRemuneration();
	RationingExpenses.Add(RepresentationalExpenses);
	RationingExpenses.Add(AdvertisingExpensesNormalized);
	
	Return RationingExpenses;
	
EndFunction

// Returns an array of types of expenses related amount due to labor, which are normalized in tax accounting,
// because for them Chapter 25 of the Tax Code of the Russian Federation provides for restrictions on the amounts
//
// Returns:
//  Array of EnumRef.ExpenseKindsTA
//
Function NormalizedExpensesLaborRemuneration() Export
	
	NormalizedExpensesLaborRemuneration = New Array;
	NormalizedExpensesLaborRemuneration.Add(VoluntaryPersonalInsurance);
	NormalizedExpensesLaborRemuneration.Add(VoluntaryPersonalInsuranceInCaseOfDeathOrDisability);
	NormalizedExpensesLaborRemuneration.Add(VoluntaryAccordingToContractsLongTermLifeInsuranceEmployees);
	NormalizedExpensesLaborRemuneration.Add(ExpensesForCompensationOfEmployeeCostsForPayingInterest);
	
	Return NormalizedExpensesLaborRemuneration;
	
EndFunction

#EndRegion

#EndIf
