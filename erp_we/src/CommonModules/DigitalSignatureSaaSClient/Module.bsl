///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns:
// 	Boolean
//
Function UsageAllowed() Export
	
	Return StandardSubsystemsClient.ClientRunParameters()["UsingElectronicSignatureInServiceModelIsPossible"];
	
EndFunction

// Procedure to Change the settings for receiving temporary password
//
// Parameters:
//  Certificate - Arbitrary - Certificate
//  CallbackOnCompletion - CallbackDescription - notification of completion.
//  FormParameters - Structure - optional, contains additional parameters when opening the form
//
Procedure ChangeSettingsForGettingTemporaryPasswords(Certificate, 
													CallbackOnCompletion = Undefined, 
													FormParameters = Undefined) Export
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("Certificate", Certificate);
	
	OpenForm(
		"CommonForm.TemporaryPasswordsDeliverySettings",
		FormParameters,,,,,
		CallbackOnCompletion);
	
EndProcedure

// Procedure to Change the confirmation method cryptooperation
//
// Parameters:
//  Certificate - Arbitrary - Certificate
//  CallbackOnCompletion - CallbackDescription - notification of completion.
//  FormParameters - Structure - optional, contains additional parameters when opening the form
//
Procedure ChangeWayCryptoOperationsAreConfirmed(Certificate, 
													CallbackOnCompletion = Undefined, 
													FormParameters = Undefined) Export
	
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("Certificate", Certificate);
	
	OpenForm(
		"CommonForm.CryptoOperationsConfirmationSetting",
		FormParameters,,,,,
		CallbackOnCompletion);
	
EndProcedure

// Procedure-Disable confirmation of crypto operations
//
// Parameters:
//  Certificate - Arbitrary - Certificate
//  CallbackOnCompletion - CallbackDescription - notification of completion.
//  FormParameters - Structure - optional, contains additional parameters when opening the form
//
Procedure DisableConfirmationOfCryptoOperations(Certificate, 
												CallbackOnCompletion = Undefined, 
												FormParameters = Undefined) Export
	
	If FormParameters = Undefined Then
		FormParameters = New Structure;
	EndIf;
	
	FormParameters.Insert("Certificate", Certificate);
	
	OpenForm(
		"CommonForm.DisableCryptoOperationsConfirmation",
		FormParameters,,,,,
		CallbackOnCompletion);
	
EndProcedure

#EndRegion