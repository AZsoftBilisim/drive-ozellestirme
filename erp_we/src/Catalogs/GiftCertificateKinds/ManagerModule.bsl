#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array of String - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	
	Result.Add("Description");
	Result.Add("Organization");
	Result.Add("Nominal");
	Result.Add("CardType");
	Result.Add("GiftCardAccounting25");
	Result.Add("ActionPeriod");
	Result.Add("NumberOfValidityPeriods");
	Result.Add("ProductSegment;UseProductSegment");
	Result.Add("PartialPayment;PartialPaymentRadioButton");
	Result.Add("GiftCertificateCodeTemplates");
	Result.Add("GLAccount");
	Result.Add("IncomeItem");
	Result.Add("SettingUpAccountingAccountsAccountingAccountPaymentsForGiftCertificates");
	Result.Add("DimensionOfRevenue");
	Result.Add("FinancialAccountingGroup");
	Result.Add("CashFlowItemSale");
	Result.Add("CashFlowItemReturn");
	Result.Add("LineOfBusiness");
	Result.Add("Permanent");
	
	Return Result;

EndFunction

#Region InterfaceImplementation

// Fills in the details of the account settings for gift certificates that affect the setting,
// 	corresponding to the names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map of KeyAndValue:
// 		* Key - String - the Attribute name used in setting up accounting accounts
// 		* Value - String - name of the accounting analytics Attribute.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	MatchingNames.Organization = "Organization";
	
EndProcedure
#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf