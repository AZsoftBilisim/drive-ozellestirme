///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region SelectiveDataRegistration

// Returns a structure of selective object registration parameters.
// The structure is stored in the "DataExchangeRules" information register.
//
// Parameters:
//   ExchangePlanName - String - an exchange plan name.
//
// Returns:
//   
//                                    In case the given plan does not use selective registration,
//                                    "Undefined" is returned.
//                                  - Undefined - Selective object registration parameters.
//   In case the given plan does not use selective registration,
//                                                   "Undefined" is returned.
//
Function SelectiveRegistrationParametersByExchangeNodeName(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	
	Query.Text = 
	"SELECT
	|	DataExchangeRules.SelectiveRegistrationParameters AS SelectiveRegistrationParameters
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsRegistrationRules)
	|	AND DataExchangeRules.ExchangePlanName = &ExchangePlanName";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then // For one exchange plan, there can only be one entry in the registration rules.
		
		SelectiveRegistrationParameters = Selection.SelectiveRegistrationParameters.Get();
		
		// "SelectiveRegistrationParameters" supports the following keys:
		// - IsXDTOExchangePlan
		// - RegistrationAttributesTable
		
		Return SelectiveRegistrationParameters;
		
	EndIf;
	
	Return DataExchangeRegistrationServer.NewParametersOfExchangePlanDataSelectiveRegistration(ExchangePlanName);
	
EndFunction

// Returns the selective object registration mode specified in the exchange plan settings.
// If the setting is not specified, returns the default value ("Modified").
// For IFDE exchange plans, if the mode is "AccordingToXMLRules" (which is not supported by IFDE), returns the default value.
//
// Returns:
//   String - The value of the "SelectiveRegistrationMode" setting.
//
// Valid values are:
//
//   Disabled - Register all objects
//                         (See DataExchangeRegistrationServer.
//   AccordingToXMLRules - Register the objects whose PCR fields were modified
//                         (See DataExchangeRegistrationServer.
//   Modified - Register the objects whose "Modified" property is set to True
//                         (See DataExchangeRegistrationServer.
//
Function ExchangePlanDataSelectiveRegistrationMode(ExchangePlanName) Export
	
	SettingValue = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "SelectiveRegistrationMode");
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName)
		And SettingValue = DataExchangeRegistrationServer.SelectiveRegistrationModeByXMLRules() Then
		
		// The XDTO format supports only "Modified" the selective registration mode.
		// To fix the implicit integration error, implicitly change the selective registration value.
		SettingValue = DataExchangeRegistrationServer.SelectiveRegistrationModeModification();
		
	ElsIf SettingValue = Undefined Then
		
		// If the setting is not described, return the default value.
		SettingValue = DataExchangeRegistrationServer.SelectiveRegistrationModeModification();
		
	EndIf;
	
	Return SettingValue;
	
EndFunction

#EndRegion

#EndRegion