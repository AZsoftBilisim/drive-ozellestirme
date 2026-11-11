#Region Public

// Returns whether PBU18 should be used for the organization.
// Parameters:
//	Organization - Array, ValueList, CatalogRef.Companies - organization for which the need to apply PBU18 is determined;
//	Period - Date - the date at the beginning of the month when the need to apply PBU18 is determined.
//
// Returns:
//	Boolean - True if the organization applies PBU18 on the date. Otherwise, it's a lie.
//
Function SupportPBU18(Val Organization, Period) Export
	Result = False;

	Return Result;
	
EndFunction

// Returns whether permanent differences are recorded.
//
// Parameters:
//	Organization - Array, ValueList, CatalogRef.Companies - the organization that the attribute is defined for;
//	Period - Date - the date at the beginning of the month that the attribute is defined for.
//
// Returns:
//	Boolean - True if the organization keeps records of permanent differences.
//
Function CalculationOfPermanentAndTemporaryDifferencesIsKept(Val Organization, Period) Export
	
	Result = False;

	Return Result;
	
EndFunction

// Returns whether the application for the organization of the CFC statements 25/2018.
// Parameters:
//	Organization - Array, ValueList, CatalogRef.Companies - organization for which the application of FSB 25/2018 is determined;
//	Period - Date - the date at the beginning of the month that determines the application of FSB 25/2018.
//
// Returns:
//	Boolean - True if the organization applies FSB 25/2018 on the date. Otherwise, it's a lie.
//
Function FSB25IsApplied(Val Organization, Period) Export
	Result = False;

	Return Result;
	
EndFunction

// Current INV application settings for the organization.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  DateOfSettings - Date - Date of Settings
// 
// Returns:
//  Undefined, Map of KeyAndValue - Current Settings For Using INV By Organization:
//   * Key - String - 
//   * Value - Structure - INV Application Settings:
//    ** RegionCode - String
//    ** RegionalINVIsApplied - Boolean
//    ** ShareOfINV_RBExpenses - Number
//    ** MinimumINVRate - Number
//    ** DeadlineForTransferringDeduction - Number
//    ** FederalINVIsApplied - Boolean
//    ** ShareOfINV_FBExpenses - Number
//    ** MinimumPeriodOfActualUse - Number
Function CurrentSettingsForUsingINVByOrganization(Val Organization, Val DateOfSettings) Export
	
	CurrentSettings_ = New Map;
	
	
	Return CurrentSettings_;
	
EndFunction

#EndRegion

#Region Internal

Function SystemOfTaxationOfOrganization(Organization, ValidityDate = Undefined, Default = True) Export
	
	TaxationSystem = Enums.TaxationSystems.Shared3;
	If TypeOf(Organization) = Type("Array") Then
		Return Undefined;
	EndIf;
	
	Return TaxationSystem;
	
EndFunction

// Returns whether the organization applies patents on the specified date
//
// Parameters:
//  Organization	 - CatalogRef.Companies - Organization that needs to be identified
//  ValidityDate		 - Date - The date on which the definition is required
// 
// Returns:
//  Boolean - does the organization use patents on the specified date
//
Function OrganizationAppliesPatents(Organization, ValidityDate = Undefined) Export
	
	PTSIsApplied = False;
	If TypeOf(Organization) = Type("Array") Then
		Return False;
	EndIf;
	
	Return PTSIsApplied;
	
EndFunction

Procedure AddAvailableParametersForAccountingPolicies(List, Val Companies, Date = Undefined) Export
EndProcedure

Procedure TextsOfRequestsForObtainingAccountingPolicyStatistics(QueriesTexts) Export
	
	
EndProcedure

// Function-aggregator of information about tax accounting settings for a specific date
//
// Parameters:
//  Period       - Date - date when the settings were read.
//  Organization  - CatalogRef.Companies - the organization
//                 for which you want to get the settings.
// 
// Returns:
//  Undefined, ValueTable - if there is not a single record of the accounting settings is undefined, otherwise the table.
//
Function AccountingPolicyTaxAccounting(Period, Organization) Export
	Return Undefined;
EndFunction

// Returns whether separate accounting of goods is used for VAT taxation. 
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
//	Boolean - Characteristic value
// 
Function SeparateAccountingOfGoodsByVATTaxation(Organization, Period = Undefined) Export
	
	SeparateAccountingOfGoodsByVATTaxation = False;
	
	Return SeparateAccountingOfGoodsByVATTaxation;
	
EndFunction

// Returns an indication of the use of separate VAT accounting for VAT taxation. 
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
//	Boolean - Characteristic value
// 
Function SeparateFAAccountingByVATTaxation(Organization, Period = Undefined) Export
	
	SeparateFAAccountingByVATTaxation = False;
	
	Return SeparateFAAccountingByVATTaxation;
	
EndFunction

// Returns an indication of using separate accounting of item-by-item production costs for VAT taxation. 
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
//	Boolean - Characteristic value
// 
Function SeparateAccountingOfItemizedProductionCostsForVATTaxation(Organization, Period = Undefined) Export
	
	SeparateAccountingOfItemizedProductionCostsForVATTaxation = False;
	
	Return SeparateAccountingOfItemizedProductionCostsForVATTaxation;
	
EndFunction

Procedure VATAccountingSettingsBeforeWrite(SetRow) Export
EndProcedure

// Receives up-to-date data on the accounting policy of tax accounting. 
//
// Parameters:
//	Form - Structure - The form of the record of the register of information of the accounting policyfinancial accounting:
// 	 * Record - InformationRegisterRecordManager.FinancialAccountingPolicy - 
// 	 * STSIsApplied - Boolean -
//	 * STSIsAppliedIncomeMinusExpenses - Boolean - 
//
Procedure ReadRegisterEntry_AccountingPolicyOfFinAccounting(Form) Export
	

EndProcedure
 
#EndRegion

#Region Private

Function FSBIsApplied14(Organization, Period) Export
	
	SettingValue = Undefined;
	

	Return SettingValue;
	
EndFunction

Function FSB6IsApplied(Organization, Period) Export
	
	FSB6IsApplied = Undefined;
	

	Return FSB6IsApplied;
	
EndFunction

Function PropertyTaxAdvancesArePaid(Organization, Period) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction


Function FALocalAccountingIsConductedIndependently(Organization, Period) Export

	Result = Undefined;
	
	Return Result;
	
EndFunction

Function ProcedureOfFixedAssetDepreciationChargeLocal(Organization, Period) Export
	
	DepreciationChargeProcedureLocal = Undefined;
	

	Return DepreciationChargeProcedureLocal;
		
EndFunction

Procedure AddAccountingSettingsForNonCurrentAssets(Organization, Period, AccountingSettings) Export
	
	
EndProcedure

#EndRegion
