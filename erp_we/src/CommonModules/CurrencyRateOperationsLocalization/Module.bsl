///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called during the initial population of the currency catalog. Adds the specified currencies from the classifier.
//
// Parameters:
//  CurrencyCodes - Array of String - Numeric codes for the currencies to be added.
//  Currencies - Array of CatalogRef.Currencies - An output parameter. Added currencies.
//  StandardProcessing - Boolean - An output parameter. Set to "False" if a custom procedure is implemented.
//
Procedure OnAddCurrenciesByCode(Val CurrencyCodes, Currencies, StandardProcessing) Export


EndProcedure

// Determines the technical capability to load exchange rates from the internet
// (that is, whether such functionality is integrated into the configuration).
//
// Parameters:
//  Value - Boolean
//
Procedure OnDefineImportAvailabilityOfCurrencyRates(Value) Export


EndProcedure

// Determines the currencies for which it is technically possible to load exchange rates from the internet
// (the data is provided by the external resource).
//
// Parameters:
//  CurrenciesImportedFromInternetCodes - Array of String - Output parameter.
//
Procedure OnDefineCurrencyCodesImportedFromInternet(CurrenciesImportedFromInternetCodes) Export


EndProcedure

// Called when importing exchange rates on the current date.
//
// Parameters:
//  ImportParameters - Structure:
//   * BeginOfPeriod - Date - Start of the import period.
//   * EndOfPeriod - Date - End of the import period.
//   * ListOfCurrencies - ValueTable:
//     ** Currency - CatalogRef.Currencies
//     ** CurrencyCode_ - String
//  ResultAddress - String - Address in the temporary storage to save the import result.
//
Procedure OnImportUpToDateRates(ImportParameters = Undefined, ResultAddress = Undefined) Export
	
	
EndProcedure

// See the work of classificatorsperefineable.The prize of the classifier's load.
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export


EndProcedure

// Adds a new item to the to-do list.
//
// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export

	
EndProcedure

// Specifies collections of metadata objects that contain input forms for writing numbers in words for various languages.
// The name of each form must comply with the pattern CurrencyInWordsParameters_<language code>.
// 
// For example, "CurrencyInWordsParameters_en". To create a new input form for writing numbers in words in a desired language, copy
// the "CurrencyInWordsParameters_en" form, change the language code in its name, and implement the population of the writing parameters in the selected language.
// For more details on CurrencyInWordsParameters, see the NumberInWords function in the Syntax Assistance.
// 
// Parameters:
//  CollectionsOfForms - Array of MetadataObjectCollection - Output parameter.
//
Procedure OnDefineWritingInWordsInputForms(CollectionsOfForms) Export


EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
Procedure OnDefineScheduledJobSettings(Settings) Export

	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	
EndProcedure

// See the Internet user support is undetectable.When changing the data of the identification of the Internet support.
Procedure OnChangeOnlineSupportAuthenticationData(UserData) Export
	
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	
EndProcedure

#EndRegion

#Region Private


// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("OnImportUpToDateRates", True);
	
EndProcedure

#EndRegion
