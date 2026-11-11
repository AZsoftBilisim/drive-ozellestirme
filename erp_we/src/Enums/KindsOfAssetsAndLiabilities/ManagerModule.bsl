#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the list of types of tax assets that correspond to unused tax losses (deductions)
// that are carried forward in accordance with IAS12.34-36 and similar provisions of PBU18.11.
// the Corresponding tax assets are not calculated based on the amounts of temporary differences.
//
// 
// Returns:
//  FixedArray - transfer values corresponding to unused tax losses and deductions.
//
Function UnusedTaxLossesDeductions() Export
	
	UnusedTaxLossesDeductions = New Array;
	UnusedTaxLossesDeductions.Add(CurrentPeriodLoss);
	// To account for a loss carried forward to future periods (loss of previous periods),
	// a special (service) expense of future periods is reflected and a deductible temporary difference is deducted for the same amount.
	// As a result, a deferred tax asset of the type of expensing periods is recognized for such losses.
	// In one of the future versions, it is planned to make a separate type of deferred tax asset for this task.
	
	UnusedTaxLossesDeductions.Add(FederalInvestmentDeduction);
	UnusedTaxLossesDeductions.Add(RegionalInvestmentDeduction);
	
	Return New FixedArray(UnusedTaxLossesDeductions);
	
EndFunction

// Deferred tax assets and liabilities that are not defined in the program are classified as service assets and liabilities.
//
// 
// Returns:
//  EnumRef.KindsOfAssetsAndLiabilities
//
Function TypeOther() Export
	
	Return OtherExpenses;
	
EndFunction

#EndRegion

#EndIf
