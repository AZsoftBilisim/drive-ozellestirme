////////////////////////////////////////////////////////////////////////////////
// Server procedures and functions that control system settings (localization)
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Constants

// Complements the values of constants in the new default is.
//
// Parameters:
// 	Result - Structure - Complement the structure constants
//
Procedure AddDefaultValuesToConstants(Result) Export
	
	
	Return
	
EndProcedure

// Returns the default currency code
// 
// Returns:
//  String - Currency code
//
Function DefaultCurrencyCode() Export
	
	
EndFunction

// Returns a currency of regulated accounting by default
// 
// Returns:
//  CatalogRef.Currencies - the currency of regulated accounting by default
//
Function CurrencyOfRegulatedAccountingByDefault() Export
	
	
EndFunction

// Returns the main old by default
// 
// Returns:
//  CatalogRef.WorldCountries - The Main Default Country
//
Function MainDefaultCountry() Export
	
	
EndFunction

// Complements the values of constants controlled in the base version.
//
// Parameters:
// 	Result - Structure - Complement the structure constants
//
Procedure SupplementValuesOfConstantsControlledInBasicVersion(Result) Export 
	Return
EndProcedure

// Adds a list of constants that can be changed in the base version.
//
// Parameters:
// 	Result - Structure - Complement the structure constants
//
Procedure SupplementConstantsAvailableInBasicVersion(Result) Export 
	Return
EndProcedure

// Complements the values of constants controlled in the NON-basic version.
//
// Parameters:
// 	Result - Structure - Complement the structure constants
//
Procedure SupplementValuesOfConstantsControlledInNonBaseVersion(Result) Export 
	Return
EndProcedure


// Complements the table describing the dependency of constants in the configuration.
// Each row in the table means:
// for a parent constant with the value X, only the value Y for the subordinate constant is allowed.
// Parameters:
// 	Result - ValueTable:
//		* NameOfParentConstant - String
//		* NameOfSubordinateConstant - String
//		* ValueOfParentConstant - Boolean
//		* ValueOfSubordinateConstant - Boolean
//
Procedure SupplementTableOfDependenceOfConstants(Result) Export
	Return
EndProcedure

#EndRegion

#Region OtherProgrammingInterface

// Sets the visibility of groups of elements related to localization elements. 
// 
// Parameters:
// 	Form - ClientApplicationForm - the form in which you need to set visibility.
Procedure SetVisibilityOfLocalizationElements(Form) Export
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	If LocalizationRFService Then
		Return;
	EndIf;
	
	For Each FormItem In Form.Items Do
		If TypeOf(FormItem) = Type("FormGroup") 
			And StrStartsWith(FormItem.Name, "Localization") Then
			FormItem.Visible = False;
		EndIf;
	EndDo;
	
EndProcedure

// Allows you to override the default currency code.
//
// Parameters:
//  CurrencyCode_	 - String - currency code, if not specified, RUB (643).
//
Procedure OverrideDefaultCurrencyCode(CurrencyCode_) Export
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function UseExchangeWithSite() Export
	Result = False;
	Return Result
EndFunction

// Overrides the name of the layout with exchange rules.
// Parameters:
// 	NameOfExchangeRules -  String - name of the layout.
Procedure AddNameOfRulesForExchangeAndUnloadingLoadingModelOfInternationalAccounting(NameOfExchangeRules) Export
EndProcedure

#EndRegion

#Region Private

Procedure SynchronizeValuesOfSubordinateConstants(ConstantName, ConstantValue, Cancel) Export
	Return
EndProcedure

#Region AdministrationPanelEventHandlers

#Region EventHandlers_NSICatalogPanel_ProductClassifiers

// Parameters:
// 	Form - ClientApplicationForm - 
Procedure SetAvailability_ProductClassifiers(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

#EndRegion

#Region EventHandlers_UT_PurchasingAdministrationPanel

Procedure WhenCreating_PurchasesOnServer(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - 
Procedure WhenReadingOnServer__(Form) Export
	Return
EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.TMAdministrationPanel.Form.Purchases
Procedure SetAvailability_Purchases(DataPathAttribute, Form) Export
	Return
EndProcedure

Procedure Save__PropsValue(ConstantName, ConstantValue, Form) Export
	Return
EndProcedure

Procedure DisplayingWarningWhenEditing_Purchases(StructureOfConstants) Export
	
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelUT_Treasury

Procedure WhenCreatedOnServer_Treasury(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

Procedure WhenReadingOnServer_Treasury(Form) Export
	Return
EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.TMAdministrationPanel.Form.TreasuryAndARAPAccounting
Procedure SetAvailability_Treasury(DataPathAttribute, Form) Export
	Return
EndProcedure

Procedure SavePropsValue_Treasury(ConstantName, ConstantValue, Form) Export
	Return
EndProcedure

Procedure DisplayingWarningWhenEditing_Treasury(StructureOfConstants) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanel_ProductSettings

// Parameters:
//	Form - See DataProcessor.TMAdministrationPanel.Form.ProductSettings
//
Procedure WhenCreatingOnServer_ProductItemSettings(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	Return
EndProcedure 

Procedure WhenReadingOnServer_ProductSettings(Form) Export
	Return
EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.TMAdministrationPanel.Form.ProductSettings
Procedure SetAvailability_ProductSettings(DataPathAttribute, Form) Export
	Return;
	
EndProcedure

Procedure SaveValueOfProps_ProductSettings(ConstantName, ConstantValue, Form) Export
	Return
	
EndProcedure

Procedure DisplayingWarningWhenEditing_ProductSettings(StructureOfConstants) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdminPanel__InitialFilling


// LongDesc
// 
// Parameters:
// 	Form - ClientApplicationForm - 
Procedure WhenCreatedOnServer_InitialFilling(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	Return
EndProcedure

Procedure WhenReadingOnServer_InitialPadding(Form) Export
	Return
EndProcedure

Procedure SetAvailability_InitialFill(DataPathAttribute, Form) Export
	Return
EndProcedure

Procedure SavePropsValue_InitialFilling(ConstantName, ConstantValue, Form) Export
	Return
EndProcedure

Procedure DisplayingWarningWhenEditing_InitialFilling(StructureOfConstants) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_UT_EnterpriseAdministrationPanel

// Parameters:
// 	Form - See DataProcessor.TMAdministrationPanel.Form.Enterprise
Procedure WhenCreatedOnServer_Enterprise(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Parameters:
// 	Form - See DataProcessor.TMAdministrationPanel.Form.Enterprise
Procedure WhenReadingOnServer_Enterprise(Form) Export
	Return
EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.TMAdministrationPanel.Form.Enterprise
Procedure SetAvailability_Enterprise(DataPathAttribute, Form) Export
	Return
EndProcedure

Procedure SavePropsValue_Enterprise(ConstantName, ConstantValue, Form) Export
	Return
EndProcedure

Procedure DisplayingWarningWhenEditing_Enterprise(StructureOfConstants) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelUT_Sales

// Parameters:
// 	Form - See DataProcessor.TMAdministrationPanel.Form.Sales
Procedure WhenCreatedOnServer_Sales(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Parameters:
// 	Form - See DataProcessor.TMAdministrationPanel.Form.Sales
Procedure OnCreateAtServer_SalesBasic(Form) Export
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	
EndProcedure

Procedure WhenReadingOnServer_Sales(Form) Export
	Return
EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.TMAdministrationPanel.Form.Sales
Procedure SetAvailabilityForSale(DataPathAttribute, Form) Export
	Return
EndProcedure

Procedure SavePropsValue_Sales(ConstantName, ConstantValue, Form) Export
	
	
	Return
EndProcedure

Procedure DisplayingWarningWhenEditing_Sales(StructureOfConstants) Export
	Return
EndProcedure


#EndRegion

#Region EventHandlers_AdministrationPanelUT_FinancialResult

Procedure WhenCreatedOnServer_FinancialResult(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

Procedure WhenReadingOnServer_FinancialResult(Form) Export
	Return
EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.TMAdministrationPanel.Form.FinancialResultAndControlling
Procedure SetAvailability_FinancialResult(DataPathAttribute, Form) Export
	
	Return;
	
EndProcedure

Procedure Save_FinancialResult_AttributeValue(ConstantName, ConstantValue, Form) Export
	Return
EndProcedure

Procedure DisplayingWarningWhenEditing_FinancialResult(StructureOfConstants) Export
	Return
EndProcedure

Procedure AvailabilityToKeepManagementRecordsOfOrganizations(Form, OptionComment) Export
EndProcedure

#EndRegion

#Region EventHandler_AdministrationPanelUT_WarehouseAndDelivery

// Parameters:
// 	Form - See DataProcessor.TMAdministrationPanel.Form.WarehouseAndDelivery
Procedure WhenCreatedOnServer_WarehouseAndDelivery(Form) Export
	
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	
EndProcedure

// Set the availability of warehouse and delivery.
// 
// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.TMAdministrationPanel.Form.WarehouseAndDelivery
Procedure SetAvailability_WarehouseAndDelivery(DataPathAttribute, Form) Export
	Return;
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelKA_Production

// Parameters:
// 	Form - See DataProcessor.CAAdministrationPanel.Form.Production
Procedure WhenCreatedOnServer_Production(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	Return
EndProcedure

Procedure WhenReadingOnServer_Production(Form) Export
	Return
EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.CAAdministrationPanel.Form.Production
Procedure SetAvailability_Production(DataPathAttribute, Form) Export
	Return
EndProcedure

Procedure SaveValueOfProps__(ConstantName, ConstantValue, Form) Export
	Return
EndProcedure

Procedure DisplayingWarningWhenEditing__(StructureOfConstants) Export
	Return
EndProcedure

Function Production21WasUsedPreviously() Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction


#EndRegion

#Region EventHandlers_KaAdministrationPanel_NonCurrentAssets

// Parameters:
// 	Form - ClientApplicationForm - 
Procedure WhenCreatedOnServer_NonCurrentAssets(Form) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
	
EndProcedure

// Parameters:
// 	Form - See DataProcessor.CAAdministrationPanel.Form.NonCurrentAssets
// 	DataPathAttribute - String -
Procedure EstablishAvailability_NonCurrentAssets(Form, DataPathAttribute) Export

	
EndProcedure


#EndRegion
#Region EventHandlers_UpAdministrationPanel_InternationalFinancialAccounting

// Parameters:
// 	Form - See DataProcessor.AdministrationPanelERP.Form.InternationalFinancialAccounting
Procedure WhenCreatedOnServer_InternationalFinancialAccounting(Form) Export

EndProcedure

// Parameters:
// 	DataPathAttribute - String -
// 	Form - See DataProcessor.AdministrationPanelERP.Form.InternationalFinancialAccounting
Procedure EstablishAccessibility_InternationalFinancialAccounting(DataPathAttribute, Form) Export
	Return
EndProcedure
#EndRegion
#EndRegion

#Region Other


#EndRegion

#EndRegion
