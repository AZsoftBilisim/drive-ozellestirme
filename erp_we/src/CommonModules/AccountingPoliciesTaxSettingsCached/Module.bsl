#Region Internal

// Returns the organization's tax system
// 
// Parameters:
// 	Organization - CatalogRef.Companies - link to the organization.
// 	ValidityDate - Date - date of receipt of the tax system.
// 	Default - Boolean - if true, the default tax system is returned,
// 	               otherwise it is returned only from the register entry.
// Returns:
// 	EnumRef.TaxationSystems, Undefined - the organization's taxation system.
Function SystemOfTaxationOfOrganization(Organization, ValidityDate = Undefined, Default = True) Export
	TaxationSystem = AccountingPoliciesTaxSettingsLocalization.SystemOfTaxationOfOrganization(Organization,
		ValidityDate,
		Default);
	Return TaxationSystem;
EndFunction

// See AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate
Function CurrentTaxAccountingPolicySettings(RegisterName, Organization, ValidityDate = Undefined, ReturnDefault = True, ThrowException = False) Export
	
	AccountingPolicySettings = AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings(RegisterName,
		Organization,
		ValidityDate,
		ReturnDefault,
		ThrowException);
		
	Return AccountingPolicySettings;
	
EndFunction

// See AccountingPoliciesTaxSettings.OrganizationsWithSpecifiedPolicyParameter
Function OrganizationsWithSpecifiedPolicyParameter(RegisterName, ParameterName, ParameterValue,
			Companies = Undefined, Period = Undefined) Export
			
	CompaniesList = AccountingPoliciesTaxSettings.OrganizationsWithSpecifiedPolicyParameter(
		RegisterName, 
		ParameterName, 
		ParameterValue,
		Companies, 
		Period);
			
	Return CompaniesList;
	
EndFunction

// Returns whether separate accounting of goods is used for VAT taxation. 
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
// 	Boolean - The value of the attribute.
// 
Function SeparateAccountingOfGoodsByVATTaxation(Organization, Period = Undefined) Export
	
	Return AccountingPoliciesTaxSettingsLocalization.SeparateAccountingOfGoodsByVATTaxation(Organization, Period);
	
EndFunction

// Returns an indication of the use of separate VAT accounting for VAT taxation. 
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
// 	Boolean - The value of the attribute.
// 
Function SeparateFAAccountingByVATTaxation(Organization, Period = Undefined) Export
	
	Return AccountingPoliciesTaxSettingsLocalization.SeparateFAAccountingByVATTaxation(Organization, Period);
	
EndFunction

// Returns an indication of using separate accounting of item-by-item production costs for VAT taxation. 
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
// 	Boolean - The value of the attribute.
// 
Function SeparateAccountingOfItemizedProductionCostsForVATTaxation(Organization, Period = Undefined) Export
	
	Return AccountingPoliciesTaxSettingsLocalization.SeparateAccountingOfItemizedProductionCostsForVATTaxation(Organization, Period);
	
EndFunction

// Returns the setting for generating the VAT presented when included in the price
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
//	Boolean - Characteristic value
// 
Function GenerateVATChargedWhenIncludingInCost(Organization, Period = Undefined) Export
	
	PolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
		Organization,
		Period);
		
	GenerateVATChargedWhenIncludingInCost = ?(PolicySettings <> Undefined, PolicySettings.GenerateVATChargedWhenIncludingInCost, False);

	Return GenerateVATChargedWhenIncludingInCost;
	
EndFunction

// Returns the setting for VAT deduction for expenses that are not accepted in TA
//
// Parameters:
// 	Organization - CatalogRef.Companies - Organization to get the accounting policy attribute for
// 	Period 		- Date, Undefined - Effective date of the accounting policy, if Undefined, as of the current date
//
// Returns:
//	Boolean - Characteristic value
// 
Function WriteOffVATByExpensesThatAreNotRecordedInTA(Organization, Period = Undefined) Export
	
	PolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
		Organization,
		Period);
		
	WriteOffVATByExpensesThatAreNotRecordedInTA = ?(PolicySettings <> Undefined, PolicySettings.WriteOffVATByExpensesThatAreNotRecordedInTA, False);

	Return WriteOffVATByExpensesThatAreNotRecordedInTA;
	
EndFunction

// Returns the parent organization for the transferred branch organization, or a link to itself.
// 
// Parameters:
//  Organization - CatalogRef.Companies - link to the Business directory.
// 
// Returns:
//  CatalogRef.Companies - The parent organization.
Function ParentCompany(Organization) Export
	ParentOrganizations = Catalogs.Companies.ParentOrganizations(Organization);
	
	ParentCompany = Organization;
	If ParentOrganizations.Count() > 0 Then
		ParentCompany = ParentOrganizations.Get(0);
	EndIf;
	
	Return ParentCompany
EndFunction

// Determines whether the accounting is conducted independently of the accounting department in the specified organization.
// If the organization is not specified, it is checked in all organizations available to the user.
// 
// Parameters:
// 	Organization - CatalogRef.Companies, Undefined - The organization for which the setup is being checked.
// 	Period 	- Date, Undefined - The effective date of the accounting policy, if Uncertain, then on the current date.
// 
// Returns:
//  Boolean - True, if at least one available organization regl. VNA accounting is conducted independently of upr. accounting.
Function FALocalAccountingIsConductedIndependently(Organization = Undefined, Period = Undefined) Export
	
	Result = AccountingPoliciesTaxSettingsLocalization.FALocalAccountingIsConductedIndependently(Organization, Period);
	
	If Result = Undefined Then
		
		If ValueIsFilled(Organization) Then
			
			PolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
				Metadata.InformationRegisters.FinancialAccountingPolicy.Name, Organization, Period);
			
			Result = 
				PolicySettings <> Undefined
				And PolicySettings.FixedAssetAccountingProcedureInLocalAccounting = Enums.FixedAssetAccountingProcedureInLocalAccounting.Independent;	
			
		Else
			
			TempTablesManager = New TempTablesManager();
		
			AccountingPoliciesTaxSettings.SupplementTemporaryTableManagerWithCurrentParametersForAccountingPolicies(
				Metadata.InformationRegisters.FinancialAccountingPolicy.Name,
				TempTablesManager,
				Period,
				"WPolicyData");
			
			Query = New Query;
			Query.TempTablesManager = TempTablesManager;
			Query.Text = 
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	WPolicyData AS T
			|WHERE
			|	T.FixedAssetAccountingProcedureInLocalAccounting = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
			|";
			Result = Not Query.Execute().IsEmpty();
		
		EndIf;

	EndIf;
	
	Return Result;
	
EndFunction

// Returns the order of accounting for non-current assets.
// 
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which the order is defined.
//	Period - Date - the date on which the order is determined.
//
// Returns:
//	EnumRef.AccountingPolicyForFixedAssets - Accounting procedure for non-current assets.
//
Function AccountingPolicyForFixedAssets(Organization, Period) Export
	
	Return AccountingPoliciesTaxSettings.AccountingPolicyForFixedAssets(Organization, Period);
	
EndFunction

// Returns the order in which FAS depreciation is calculated in Man accounting.
// 
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which the order is defined.
//	Period - Date - the date on which the order is determined.
//
// Returns:
//	EnumRef.DepreciationProcedure - The procedure for calculating depreciation in accounting.
//
Function DepreciationProcedureFAMan(Organization, Period) Export
	
	PolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy", Organization, Period);
			
	Return PolicySettings.ProcedureOfFixedAssetDepreciationCharge;
	
EndFunction

// Returns the order in which FA depreciation is calculated in Local accounting.
// 
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which the order is defined.
//	Period - Date - the date on which the order is determined.
//
// Returns:
//	EnumRef.DepreciationProcedure - The procedure for calculating depreciation in accounting.
//
Function ProcedureOfFixedAssetDepreciationChargeLocal(Organization, Period) Export
	
	DepreciationChargeProcedureLocal = AccountingPoliciesTaxSettingsLocalization.ProcedureOfFixedAssetDepreciationChargeLocal(Organization, Period);
	
	If DepreciationChargeProcedureLocal = Undefined Then
		
		PolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"FinancialAccountingPolicy", Organization, Period);
			
		DepreciationChargeProcedureLocal = PolicySettings.ProcedureOfFixedAssetDepreciationChargeLocal;
		
	EndIf;
	
	Return DepreciationChargeProcedureLocal;
	
EndFunction

// Returns the application of FSB 14 in accounting.
// 
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which the order is defined.
//	Period - Date - the date on which the order is determined.
//
// Returns:
//	Boolean - True if the FSB 6 is applied.
//
Function FSBIsApplied14(Organization, Period) Export
	
	SettingValue = AccountingPoliciesTaxSettingsLocalization.FSBIsApplied14(Organization, Period);
	
	If SettingValue = Undefined Then
		SettingValue = True;
	EndIf;
	
	Return SettingValue;
	
EndFunction

// Returns the application of FSB 6 in accounting.
// 
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which the order is defined.
//	Period - Date - the date on which the order is determined.
//
// Returns:
//	Boolean - True if the FSB 6 is applied.
//
Function FSB6IsApplied(Organization, Period) Export
	
	FSB6IsApplied = AccountingPoliciesTaxSettingsLocalization.FSB6IsApplied(Organization, Period);
	
	If FSB6IsApplied = Undefined Then
		FSB6IsApplied = True;
	EndIf;
	
	Return FSB6IsApplied;
	
EndFunction

// Returns the accounting settings for non-current assets.
// 
// Parameters:
//	Organization - CatalogRef.Companies - the organization for which the settings are defined.
//	Period - Date - the date on which the settings are determined.
//
// Returns:
//	Structure - Contains: 
//		* AccountingPolicyForFixedAssets - EnumRef.AccountingPolicyForFixedAssets - 
//		* ProcedureOfFixedAssetDepreciationCharge - EnumRef.DepreciationProcedure - 
//		* ProcedureOfIntangibleAssetAmortizationCharge - EnumRef.DepreciationProcedure - 
//		* LeasedAssetDepreciationChargeProcedureManag - EnumRef.DepreciationProcedure - 
//		* FixedAssetAccountingProcedureInLocalAccounting - EnumRef.FixedAssetAccountingProcedureInLocalAccounting - 
//		* DepreciationChargeProcedureLocal - EnumRef.DepreciationProcedure - 
//		* LeasedFixedAssetDepreciationChargeProcedureLocal - EnumRef.DepreciationProcedure - 
//		* AccountingForRentAccordingToFSB252018 - Boolean - 
//		* PostingOptionForImpairedFADepreciation - EnumRef.PostingOptionsForImpairedFADepreciation - 
//		* FSB6IsApplied - Boolean - 
//		* FSBIsApplied14 - Boolean -
//		* FixedAssetRevaluationMethod - EnumRef.FixedAndIntangibleAssetRevaluationMethods - 
//		* IntangibleAssetRevaluationMethod - EnumRef.FixedAndIntangibleAssetRevaluationMethods - 
//		* MethodOfRevaluationOfFALocal - EnumRef.FixedAndIntangibleAssetRevaluationMethods - 
//		* MethodOfRevaluationOfIALocal - EnumRef.FixedAndIntangibleAssetRevaluationMethods - 
//
Function AccountingSettingsForNonCurrentAssets(Organization, Period) Export
	
	PolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy", Organization, Period);
	
	AccountingSettings = New Structure;
	AccountingSettings.Insert("AccountingPolicyForFixedAssets", PolicySettings.AccountingPolicyForFixedAssets);
	AccountingSettings.Insert("FixedAssetAccountingProcedureInLocalAccounting", PolicySettings.FixedAssetAccountingProcedureInLocalAccounting);
	AccountingSettings.Insert("ProcedureOfFixedAssetDepreciationCharge", PolicySettings.ProcedureOfFixedAssetDepreciationCharge);
	AccountingSettings.Insert("ProcedureOfFixedAssetDepreciationChargeLocal", PolicySettings.ProcedureOfFixedAssetDepreciationChargeLocal);
	AccountingSettings.Insert("ProcedureOfIntangibleAssetAmortizationCharge", PolicySettings.ProcedureOfIntangibleAssetAmortizationCharge);
	AccountingSettings.Insert("ProcedureOfIntangibleAssetAmortizationChargeLocal", PolicySettings.ProcedureOfIntangibleAssetAmortizationChargeLocal);
	AccountingSettings.Insert("LeasedAssetDepreciationChargeProcedureManag", PolicySettings.LeasedAssetDepreciationChargeProcedureManag);
	AccountingSettings.Insert("LeasedFixedAssetDepreciationChargeProcedureLocal", PolicySettings.LeasedFixedAssetDepreciationChargeProcedureLocal);
	AccountingSettings.Insert("AccountingForRentAccordingToFSB252018", PolicySettings.AccountingForRentAccordingToFSB252018);
	AccountingSettings.Insert("PostingOptionForImpairedFADepreciation", PolicySettings.PostingOptionForImpairedFADepreciation);
	AccountingSettings.Insert("FSB6IsApplied", True);
	AccountingSettings.Insert("FSBIsApplied14", True);
	AccountingSettings.Insert("FixedAssetRevaluationMethod", PolicySettings.FixedAssetRevaluationMethod);
	AccountingSettings.Insert("IntangibleAssetRevaluationMethod", PolicySettings.IntangibleAssetRevaluationMethod);
	AccountingSettings.Insert("MethodOfRevaluationOfFALocal", PolicySettings.FixedAssetRevaluationMethod);
	AccountingSettings.Insert("MethodOfRevaluationOfIALocal", PolicySettings.IntangibleAssetRevaluationMethod);

	AccountingPoliciesTaxSettingsLocalization.AddAccountingSettingsForNonCurrentAssets(Organization, Period, AccountingSettings);
		
	Return AccountingSettings;
	
EndFunction

// Returns the need to pay property tax advances.
//
// Parameters:
// 	Organization - CatalogRef.Companies - The company that needs to be verified for.
// 	Period - Date - The closing date of the month.
//
// Returns:
// 	Boolean - A sign of the need to pay an advance.
//
Function PropertyTaxAdvancesArePaid(Organization, Period) Export
	
	Return AccountingPoliciesTaxSettingsLocalization.PropertyTaxAdvancesArePaid(Organization, Period);
	
EndFunction

#EndRegion
