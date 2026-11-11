///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Technical support line code.
// 
// Parameters:
//  Recipient - String
//
Procedure OnDefineTechnicalSupportRequestRecipient(Recipient) Export
	
	
EndProcedure

// Sender parameters in the mobile signature service.
// 
// Parameters:
//  Sender - Structure
//
Procedure OnDefineParametersOfDocumentsForSignatureSender(Sender) Export
	
	
EndProcedure

// Filter for signature selection.
// 
// Parameters:
//  Filter - String
//
Procedure OnGetFilterForSelectingSignatures(Filter) Export
	
	
EndProcedure

// In case of errors on the client.
// 
// Parameters:
//  ErrorsDescription - Structure
//
Procedure OnGetErrorAtClient(ErrorsDescription) Export
	
	
EndProcedure

// Form for sending data for signing to the mobile signing service.
// 
// Parameters:
//  FormName - String
//
Procedure OnDefineSignatureSubmissionForm(FormName) Export
	
	
EndProcedure

// On getting a mobile add-in ID.
// 
// Parameters:
//  Component - String
//
Procedure OnReceivingMobileComponentID(Component) Export
	
	
EndProcedure

// On getting a choice list with MR LOAs in the form for adding signatures from a file.
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  CurrentData - FormDataCollectionItem - Signature string in form "Common.AddDigitalSignatureFromFile".
//  ChoiceList - ValueList
//
Procedure OnGetChoiceListWithMRLOAs(Form, CurrentData, ChoiceList) Export
	
	
EndProcedure

// On choosing an MR LOA on the form for exporting signatures from a file.
// 
// Parameters:
//  CompletionHandler - CallbackDescription
//  CurrentData - FormDataCollectionItem - Signature string in form "Common.AddDigitalSignatureFromFile". 
//
Procedure OnSelectMRLOA(CompletionHandler, CurrentData) Export
	
	
EndProcedure

// Adds MR LOA files to the list when saving a signature.
// 
// Parameters:
//  MRLOAFiles - Map
//  SignaturesCollection - FormDataCollection
//
Procedure OnDefineMRLOAFiles(MRLOAFiles,
		SignaturesCollection) Export
		
	
EndProcedure

// On checking for conflicts between cryptographic applications.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CheckResult - Structure
//
Procedure OnCheckCryptoAppsConflict(Form, CheckResult) Export
	
	
EndProcedure

// On checking for installed cryptographic applications.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CheckResult - Structure
//  HasAppsToCheck - Boolean
//
Procedure OnCheckInstalledCryptoApps(Form, CheckResult, HasAppsToCheck) Export
	
	
EndProcedure

// Detects tokens connected to the device.
// 
// Parameters:
//  ComponentObject - Undefined, AddInObject.
//  SuggestInstall - Boolean - Prompt to install the add-in (if not yet installed).
// 
// Returns:
//  Promise - Structure
//
Async Function InstalledTokens(ComponentObject = Undefined, SuggestInstall = False) Export

	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Tokens", New Array);
	Result.Insert("Error", "");
	
	
	Return Result;
	
EndFunction

// Adds token certificates to the passed array.
// 
// Parameters:
//  Tokens - Array, Undefined
//  CertificatesArray - Array
// 
// Returns:
//  Array of CryptoCertificate
//
Async Function AddCertificatesFromTokenToArray(Tokens, CertificatesArray) Export
	
	
	Return CertificatesArray;
	
EndFunction

// Retrieves the token by a certificate.
// 
// Parameters:
//  Notification - CallbackDescription
//  Certificate - CryptoCertificate
//  StandardProcessing - Boolean
//  SuggestInstall - Boolean - Prompt to install the add-in.
//  Refresh - Boolean - Update the list of token certificates in the cache.
// 
// Returns:
//  Promise - Array of Structure - Tokens
//  
Procedure OnGettingTokenByCertificate(Notification, Certificate, StandardProcessing, SuggestInstall = True, Refresh = False) Export
	
	
EndProcedure

// Retrieves a certificate from the token by its fingerprint.
// 
// Parameters:
//  Notification - CallbackDescription
//  Thumbprint - String
//  StandardProcessing - Boolean
//  SuggestInstall - Boolean - Prompt to install the add-in.
//  Refresh - Boolean - Update the list of token certificates in the cache.
// 
// Returns:
//  CryptoCertificate
//  
Procedure OnGettingCertificateByThumbprintOnToken(Notification, Thumbprint, StandardProcessing, SuggestInstall = True, Refresh = False) Export
	
	
EndProcedure

// Retrieves certificates from the token.
// 
// Parameters:
//  Notification - CallbackDescription - Notification result: Array of CryptoCertificate.
//  Token - Structure
//  StandardProcessing - Boolean
//  SuggestInstall - Boolean - Prompt to install the add-in.
//  Refresh - Boolean - Update the list of token certificates in the cache.
// 
// Returns:
//  
//  
Procedure OnGettingCertificatesOnToken(Notification, Token, StandardProcessing, SuggestInstall = True, Refresh = False) Export
	
	
EndProcedure

// Finds an encryption token that supports the given encryption algorithm.
// 
// Parameters:
//  Notification - CallbackDescription - Notification result: a structure containing the token properties.
//  Certificate - CryptoCertificate
//  EncryptAlgorithm - String - OID or See DigitalSignatureClient.Encrypt.DataDetails.
//  CertificateProperties - Structure:
//    * PublicKeyAlgorithm - String - OID
//  StandardProcessing - Boolean
//
Procedure OnSearchTokenForEncryption(Notification, Certificate, EncryptAlgorithm, CertificateProperties = Undefined,
	StandardProcessing = True) Export
	
	
EndProcedure

// The error message indicates that an incorrect token PIN was entered.
// 
// Parameters:
//  ErrorText - String - Error text.
// 
// Returns:
//  Boolean
//
Function IsIncorrectPinCodeError(ErrorText) Export
	Return False;
EndFunction

// Retreives tokens.
// 
// Parameters:
//  Notification - CallbackDescription
//  SuggestInstall - Boolean - Prompt to install the add-in (if not yet installed).
//  StandardProcessing - Boolean - Standard data processor
//
Procedure OnGettingTokens(Notification, SuggestInstall = True, StandardProcessing = True) Export
	
	
EndProcedure

// Retrieves the thumbprints of token certificates.
// 
// Parameters:
//  Notification - CallbackDescription
//  IncludingOverduePayments - Boolean
//  SuggestInstall - Boolean - Prompt to install the add-in (if not yet installed).
//  StandardProcessing - Boolean - Standard data processor.
//
Procedure OnGettingCertificatesThumbprintsOnTokens(Notification, IncludingOverduePayments = False,
	SuggestInstall = True, StandardProcessing = True) Export
	
	
EndProcedure

// Adds signature on the token.
// 
// Parameters:
//  CallbackOnCompletion - CallbackDescription
//  SignatureParameters - Structure
//  Data - BinaryData
//  StandardProcessing - Boolean 
//
Procedure OnSigningOnToken(CallbackOnCompletion, SignatureParameters, Data, StandardProcessing = True) Export
		
	
EndProcedure

// Performs decryption on the token.
// 
// Parameters:
//  CallbackOnCompletion - CallbackDescription
//  DetailsParameters - Structure
//  Data - BinaryData
//  StandardProcessing - Boolean 
//
Procedure OnDecryptionOnToken(CallbackOnCompletion, DetailsParameters, Data, StandardProcessing = True) Export
		
	
EndProcedure

// Performs encryption on the token.
// 
// Parameters:
//  CallbackOnCompletion - CallbackDescription
//  EncryptionParameters - Structure
//  Data - BinaryData
//  StandardProcessing - Boolean 
//
Procedure OnEncryptionOnToken(CallbackOnCompletion, EncryptionParameters, Data, StandardProcessing = True) Export
		
	
EndProcedure

// Verifies a signature on the token.
// 
// Parameters:
//  CallbackOnCompletion - CallbackDescription
//  Data - BinaryData
//  Signature - BinaryData
//  CheckParameters - Structure
//  StandardProcessing - Boolean
//
Procedure OnCheckSignatureOnToken(CallbackOnCompletion, Data, Signature, CheckParameters, StandardProcessing = True) Export
	
	
EndProcedure

// Opens the form for installing cryptographic tools.
// 
// Parameters:
//  Parameters - Structure
//  Owner - ClientApplicationForm
//  Notification - CallbackDescription
//  StandardProcessing - Boolean
//
Procedure OnOpenCryptoProviderAppsInstallationForm(Parameters, Owner, Notification, StandardProcessing) Export
	
	
EndProcedure

// On filling the result of checking a CA.
// 
// Parameters:
//  Result - See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//  CryptoCertificate - CryptoCertificate
//  OnDate - Date
//  CheckParameters - Structure
//  CertificateProperties - See DigitalSignature.CertificateProperties
// 
// Returns:
//  Promise - See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//
Async Function OnFillCertificationAuthorityAuditResult(
	Result, CryptoCertificate, OnDate, CheckParameters, CertificateProperties) Export
	
	
	Return Result;
	
EndFunction

// For internal use only.
// Verifies the installation of cryptographic tools as part of the add-in installation check for managing digital signatures.
//
// Parameters:
//  Result	 - Boolean - If "True", some add-ins should be installed.
//  Components	 - See DigitalSignatureInternalClient.NewCryptoManagementAddIns.
//
Procedure OnCheckCryptoAppsInstallation(Result, Components) Export
	
	
EndProcedure

// On continuing the verification of installed cryptographic tools.
// 
// Parameters:
//  Context - Structure
//  CheckResult - Structure
//  HasAppsToCheck - Boolean 
// 
// Returns:
//  Promise - Boolean
//
Async Function OnContinueCheckInstalledCryptoApps(
		Context, CheckResult, HasAppsToCheck) Export
	
	
	Return True;
	
EndFunction

// On handling a classifier URL.
// 
// Parameters:
//  Item - FormDecoration
//  FormattedStringURL - String
//  Parameters - Structure
// 
// Returns:
//  Promise - Boolean
//
Async Function OnHandleClassifierURL(Item, FormattedStringURL, Parameters) Export
	
	Return True;
	
EndFunction

// Overrides signer parameters.
// 
// Parameters:
//  SignatoryParameters - Structure
//
Procedure OnRetrieveSignatoryParameters(SignatoryParameters) Export
	
	
EndProcedure

// Overrides the procedure for adding a digital signature application.
// 
// Parameters: 
//  StandardProcessing - Boolean
//
Procedure OnAddDigitalSignatureApp(StandardProcessing) Export
	
	
EndProcedure

// Adds to the list of events for updating the list of settings for digital signature applications.
// 
// Parameters:
//  Events - Array
//
Procedure OnGetProgramsSettingsChangeEvents(Events) Export
	
	
EndProcedure


// On signer opening.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Item - FormField
//  StandardProcessing - Boolean
//
Procedure SignatoryOnOpen(Form, Item, StandardProcessing) Export
	
	
EndProcedure

// On signer creation.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Item - FormField
//  StandardProcessing - Boolean
//
Procedure SignatoryOnCreate(Form, Item, StandardProcessing) Export

	
EndProcedure

// On signer clearing.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Item - FormField
//  StandardProcessing - Boolean
//
Procedure SignerWhenClearing(Form, Item, StandardProcessing) Export

	
EndProcedure


#EndRegion

