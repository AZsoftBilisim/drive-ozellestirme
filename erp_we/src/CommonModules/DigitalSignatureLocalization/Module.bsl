///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// On create at server.
// 
// Parameters:
//  Form - ClientApplicationForm
//
Procedure OnCreateAtServer(Form) Export
	
	
EndProcedure

// Overrides the signature type display in the settings form of the administration panel and the tooltip text in the signing form.
// 
// Parameters:
//  SignatureType - EnumRef.CryptographySignatureTypes
//  SignaturePresentation - String
//
Procedure OnPopulateSignatureTypePresentation(SignatureType, SignaturePresentation) Export
	
	
EndProcedure

// Overrides the usage of the mobile signing service.
// 
// Parameters:
//  Used - Boolean
//
Procedure OnRetrieveMobileServiceUsageSettings(Used) Export
	
	
EndProcedure

// Overrides the title of the command that sends data to the mobile signing service.
// 
// Parameters:
//  Title - String
//
Procedure OnRetrieveSendForSigningCommandTitle(Title) Export
	
	
EndProcedure

// Overrides the title of the command that sends data to the mobile signing service.
// 
// Parameters:
//  ChoiceList - ValueList
//
Procedure OnRetrieveSigningTypes(ChoiceList) Export
	
	
EndProcedure

// Overrides the result of sending data to the mobile signing service.
// 
// Parameters:
//  DocumentIDs - Array of UUID
//  Result - Map:
//                * Key - UUID
//                * Result - Structure:
//                   ** Signature - BinaryData
//                   ** SignatureType  - EnumRef.CryptographySignatureTypes
//                   ** DateActionLastTimestamp - Date, Undefined - Filled only using
//                        the cryptographic manager.
//                   ** DateSignedFromLabels - Date, Undefined - Date of the earliest timestamp.
//                   ** UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                   ** Certificate  - BinaryData - Certificate used for signature validation.
//                   ** Thumbprint           - String - Certificate thumbprint in the Base64 string format.
//                   ** CertificateOwner - String - a subject presentation received from the certificate binary data.
//                   ** SignatureDate - Date - Unconfirmed signature date
//
Procedure OnRetrieveSentForSigningResults(DocumentIDs, Result) Export
	
	
EndProcedure

// Marks the signing setting in the service for deletion.
// 
// Parameters:
//  Application - CatalogRef
//  UUID - UUID
//  StandardProcessing - Boolean
//
Procedure OnChangeAppDeletionMark(Application, UUID, StandardProcessing) Export
	
	
EndProcedure

// On filling in digital signature applications.
// 
// Parameters:
//  ApplicationsTable - ValueTable
//
Procedure OnFillDigitalSignatureApps(ApplicationsTable) Export
	
	
EndProcedure

// On exporting MR LOAs.
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//
Procedure OnImportMRLOAs(Form) Export
	
	
EndProcedure

// On getting the status of a certificate issuance application.
// 
// Parameters:
//  Certificate - See DigitalSignature.CertificateIssuanceApplicationState.Certificate
//  Result - See DigitalSignature.CertificateIssuanceApplicationState
//
Procedure OnGetCertificateIssuanceApplicationStatus(Certificate, Result) Export
	
	
EndProcedure

// On filling MR LOAs.
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  SignedObject - DefinedType.SignedObject
//
Procedure OnFillMRLOAs(Form, SignedObject = Undefined) Export
	
	
EndProcedure

// On filling an MR LOA in a row.
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  SignedObject - DefinedType.SignedObject
//  RowID - Number
//
Procedure OnFillMRLOAInRow(Form, RowID, SignedObject) Export

	
EndProcedure

// See the work of classificatorsperefineable.Adding classifiers.
Procedure OnAddClassifiers(Classifiers) Export
		
	
EndProcedure

// See the work of classificatorsperefineable.The prize of the classifier's load.
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export
	
	
EndProcedure

// On adding rows on the server.
// 
// Parameters:
//  Form - See CommonForm.AddDigitalSignatureFromFile
//  PlacedFiles - Array 
//  OtherFiles - Map 
//  ErrorOnLOAsImport - String 
//  UUID - UUID
// 
Procedure OnAddRowsAtServer(Form, PlacedFiles, OtherFiles, ErrorOnLOAsImport, UUID) Export
	
	
EndProcedure

// On verifying MR LOA signatures.
// 
// Parameters:
//  Signatures - Array
//  SignedObject - DefinedType.SignedObject
//  ChecksResults - Array
//
Procedure OnVerifySignaturesOnMRLOA(Signatures, SignedObject, ChecksResults) Export


EndProcedure

// On determining if an application can be created.
// 
// Parameters:
//  AvailabilityOfCreatingAnApplication - See DigitalSignature.AvailabilityOfCreatingAnApplication
//
Procedure OnDetermineAvailabilityOfApplicationCreation(AvailabilityOfCreatingAnApplication) Export
	
	
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
Procedure OnFillCertificationAuthorityAuditResult(
	Result, CryptoCertificate, OnDate, CheckParameters, CertificateProperties) Export
	
	
EndProcedure

// On getting a list of accredited certificate authorities.
// 
// Parameters:
//  AccreditedCertificationCenters - Structure
//
Procedure OnGetAccreditedCAs(AccreditedCertificationCenters) Export
	
	
EndProcedure

// On getting a classifier of cryptographic errors.
// 
// Parameters:
//  ClassifierData - Undefined, Structure
//
Procedure OnGetCryptoErrorsClassifier(ClassifierData) Export
	
	
EndProcedure

// On determining the availability of verification against the CA list.
// 
// Parameters:
//  IsCheckAvailable - Boolean
//
Procedure OnDetermineAvailabilityOfCheckByCAList(IsCheckAvailable) Export
	
	
EndProcedure

// On getting a distribution package.
// 
// Parameters:
//  Parameters - Structure
//  Id - String
//  Result - See TimeConsumingOperations.ExecuteFunction 
//
Procedure OnGetDistribution(Parameters, Id, Result) Export
	
	
EndProcedure

// On processing the result of obtaining a distribution package.
// 
// Parameters:
//  TimeConsumingOperation - Structure:
//   * ResultAddress - String - Address in the temp storage.
//  FormIdentifier - UUID
//  Result - Structure
//
Procedure OnProcessDistributionGetResult(TimeConsumingOperation, FormIdentifier, Result) Export
	
	
EndProcedure

// On determining if a cloud signing service is used.
// 
// Parameters:
//  Result - Boolean
//
Procedure OnDefineCloudSigningServiceUsage(Result) Export
	
	
EndProcedure

// On determining the type of a signing service.
// 
// Parameters:
//  Result - Type
//
Procedure OnDefineSigningServiceAppType(Result) Export
	
	
EndProcedure

// On getting timestamp server addresses.
// 
// Parameters:
//  TimestampServersAddresses - String
//
Procedure OnGetTimestampServerAddresses(TimestampServersAddresses) Export
	
	
EndProcedure

// On getting cloud service thumbprints.
// 
// Parameters:
//  ThumbprintsArray - Array
//
Procedure OnGetCloudServiceThumbprints(ThumbprintsArray) Export
	
	
EndProcedure

// On adding cloud service certificate properties.
// 
// Parameters:
//  CertificatesPropertiesTable - ValueTable
//  NoFilter - Boolean
//
Procedure OnAddCloudServiceCertificatesProperties(CertificatesPropertiesTable, NoFilter) Export
	
	
EndProcedure

// On determining a configured cloud service.
// 
// Parameters:
//  Result - Boolean
//
Procedure OnDefineConfiguredCloudService(Result) Export
	
	
EndProcedure

// On filling cloud service certificates.
// 
// Parameters:
//  CertificatesThumbprintsAtClient - Array
//
Procedure OnFillCloudServiceCertificates(CertificatesThumbprintsAtClient) Export

		
EndProcedure

// On setting up the common settings form.
// 
// Parameters:
//  Form - ClientApplicationForm
//  DataPathAttribute - String
//  AccessToInternetServicesAllowed - Boolean
//  CommonSettings - See DigitalSignature.CommonSettings
//  StandardProcessing - Boolean
//
Procedure OnSetUpGeneralSettingsForm(Form, DataPathAttribute, AccessToInternetServicesAllowed, CommonSettings, StandardProcessing) Export
	
EndProcedure

#EndRegion

