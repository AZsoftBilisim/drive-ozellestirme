#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in settings that affect the use of the exchange plan.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  Settings - See DataExchangeServer.ExchangePlanSettings
//
Procedure OnGetSettings(Settings) Export	
EndProcedure

// Fills in a set of parameters that define the exchange configuration option.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	OptionDetails - See DataExchangeServer.SettingOptionDetails
//  SettingID - String - ID of the exchange configuration option.
//  ContextParameters - Structure - See DataExchangeServer.ContextParametersOfSettingOptionDetailsReceipt 
//  								 description of the function's return value. 
//
Procedure OnGetSettingOptionDetails(OptionDetails, SettingID,
	ContextParameters) Export
EndProcedure

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//  Array of String - a list of the names of the object's details.
//  
Function AttributesToSkipInBatchProcessing() Export	
EndFunction

#EndRegion

#EndIf