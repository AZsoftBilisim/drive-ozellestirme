///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overrides certificate presentations.
// 
// Parameters:
//  Certificate - CryptoCertificate
//  UTCOffset - Number
//  Presentation - String
//
Procedure OnGetCertificatePresentation(Val Certificate, Val UTCOffset, Presentation) Export
	
	
EndProcedure

// Overrides certificate subject presentations.
// 
// Parameters:
//  Certificate - CryptoCertificate
//  Presentation - String
//
Procedure OnGetSubjectPresentation(Val Certificate, Presentation) Export
	
	
EndProcedure

// Overrides the extended property structure of the certificate subject.
// 
// Parameters:
//  Subject - FixedStructure
//  Properties - Structure
//
Procedure OnGetExtendedCertificateSubjectProperties(Val Subject, Properties) Export
	
	
EndProcedure

// Overrides the extended property structure of the certificate issuer.
// 
// Parameters:
//  Issuer - FixedStructure
//  Properties - Structure
//
Procedure OnGetExtendedCertificateIssuerProperties(Val Issuer, Properties) Export
	
	
EndProcedure

// Overrides the certificate comparison result by the subject properties.
// 
// Parameters:
//  PropertiesOfNew - Structure
//  PropertiesOfOld - Structure
//  Result - Boolean
//
Procedure WhenComparingCertificates(PropertiesOfNew, PropertiesOfOld, Result) Export
	
	
EndProcedure

// On receiving an XML envelope.
// 
// Parameters:
//  Parameters - Structure
//  XMLEnvelope - String
//
Procedure OnReceivingXMLEnvelope(Parameters, XMLEnvelope) Export
	
	
EndProcedure

// On receiving the default envelope version.
// 
// Parameters:
//  XMLEnvelope - String
//
Procedure OnGetDefaultEnvelopeVariant(XMLEnvelope) Export

	
EndProcedure

// On determining if an application is available.
// 
// Parameters:
//  Parameters - SelectionFromQueryResult, Structure
//  Structure - Structure
//
Procedure OnDefineAppAvailability(Parameters, Structure) Export
	
	
EndProcedure


// Address of the revocation list located on a different resource.
// 
// Parameters:
//  CertificateAuthorityName - String - Issuer's name (lower case, Latin letters)
//  CertificateProperties  - BinaryData - Certificate data.
//                       - String - Certificate data address.
//                       - Structure - See DigitalSignatureInternalClientServer.CertificateProperties
//  CARevocationListDirectories - String - The names of the directories used for caching revocation lists on a local resource,
//                        taken from the accredited CA classifier settings, match the certificate issuer names.
// 
// Returns:
//  Structure:
//   * InternalAddress - String - ID for searching within the infobase
//   * ExternalAddress - String - Resource address (for downloading)
//
Function RevocationListInternalAddress(CertificateAuthorityName, CertificateProperties, CARevocationListDirectories) Export
	
	Result = New Structure("ExternalAddress, InternalAddress");
	
	CertificateAuthorityName = StrReplace(CertificateAuthorityName, " ", "_");
	CertificateAuthorityName = TrimAll(StrConcat(StrSplit(CertificateAuthorityName, "!*'();«»:@&=+$,/?%#[]\|<>", True), ""));
	
	CertificateAuthorityName = CommonClientServer.ReplaceProhibitedCharsInFileName(CertificateAuthorityName, "");
	
	If Not ValueIsFilled(CertificateAuthorityName) Then
		Return Result;
	EndIf;
	
	If TypeOf(CertificateProperties) <> Type("Structure") Then
		CertificateProperties = 
			DigitalSignatureInternalClientServer.CertificateAdditionalProperties(CertificateProperties, 0);
	EndIf;
	
	If Not ValueIsFilled(CertificateProperties.CertificateAuthorityKeyID) Then
		Return Result;
	EndIf;
	
	Result.InternalAddress = StrTemplate("%1/%2", CertificateAuthorityName, Lower(CertificateProperties.CertificateAuthorityKeyID));
	
	
	Return Result;
	
EndFunction

// CA revocation list catalogs.
// 
// Parameters:
//  AccreditedCertificationCenters - Structure
// 
// Returns:
//  String - CA revocation list catalogs
//
Function CARevocationListDirectories(AccreditedCertificationCenters) Export
	
	Return "";
	
EndFunction

// Returns data required for the CA check.
// 
// Parameters:
//  SearchValues - String
//  AccreditedCertificationCenters - Structure
// 
// Returns:
//  Undefined
//  * AllowedUncredited - Boolean:
//   * ActionPeriods - Undefined, Array of Structure:
//  **DateFrom1 - Date
//  **DateTo - Date, Undefined
//  * ValidityEndDate - Undefined, Date
//  * UpdateDate - Undefined, Date
//  * FurtherSettings - Map
//   * AllowedUncredited - Boolean
//   * ActionPeriods - Undefined, Array of Structure:
//     **DateFrom1 - Date
//     **DateTo - Date, Undefined
//   * ValidityEndDate - Undefined, Date
//   * UpdateDate - Undefined, Date
//   * FurtherSettings - Map
//
Function CertificationAuthorityData(SearchValues, AccreditedCertificationCenters) Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

// On determining the link to the application guides.
// 
// Parameters:
//  Section - String
//  URL - String
//
Procedure OnDefineRefToAppsGuide(Section, URL) Export
	
	
EndProcedure

// On determining the reference to the error search when managing digital signatures.
// 
// Parameters:
//  URL - String
//  SearchString - String - Search string
//
Procedure OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(URL, SearchString = "") Export
	
	
EndProcedure

// Convert the name of the passed algorithm (depending on the passed presentation).
// 
// Parameters:
//  EncryptAlgorithm  - String
// 
// Returns:
//  String
//
Function ConvertedEncryptAlgorithm(EncryptAlgorithm) Export
	
	Result = "";
	
	
	If IsBlankString(Result) Then
		Result = EncryptAlgorithm;
	EndIf;
	
	Return Result;
	
EndFunction

// Implements alternative cryptography manager parameters.
// For example, in order to comply with the regional aspects of a digital signature and encryption application.
//
// Parameters:
//  ApplicationDetails - See DigitalSignatureInternalCached.ApplicationDetails
//  Manager - CryptoManager
//  EncryptAlgorithm - String
//  Result - Boolean
//
Procedure OnSetCryptoManagerParameters(ApplicationDetails, Manager, EncryptAlgorithm, Result) Export
	
	
EndProcedure

// Adds algorithms required for creating signatures considering regional aspects.
//
// Parameters:
//  Sets	 - Array
//
Procedure OnSetAlgorithmSetsToCreateSignature(Sets) Export
	
	
EndProcedure

// Adds encryption algorithms considering regional aspects.
//
// Parameters:
//  Sets	 - Array
//
Procedure OnSetEncryptAlgorithmsSets(Sets) Export
	
	
EndProcedure

// Adds regional signature algorithms to the list of valid algorithms.
// 
// Returns:
//  Array
//
Function AppsRelevantAlgorithms() Export
	
	Result = New Array;
	
	
	Return Result;
	
EndFunction


// For internal use only.
// 
// Parameters:
//  Certificate - CryptoCertificate
//  CheckContext - See "CertificateCAVerificationContext"
// 
// Returns:
//   See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//
Function ResultofCertificateAuthorityVerification(Certificate, CheckContext) Export
	
	CertificationAuthorityAuditResult = DigitalSignatureInternalClientServer.DefaultCAVerificationResult();
	
	
	Return CertificationAuthorityAuditResult;
	
EndFunction

// On getting the name of a digital signing application.
// 
// Parameters:
//  Cryptoprovider - Structure
//  Result - String
//
Procedure OnGetDigitalSigningAppName(Cryptoprovider, Result) Export
	
	
EndProcedure

// Error occurred due to missing token libraries.
// 
// Parameters:
//  ErrorText - String
//  Result - Boolean
//
Procedure OnDefineImportErrorInTokenLibraries(ErrorText, Result) Export
	
	
EndProcedure

// Link to the article about CAs.
// 
// Returns:
//  String - Link to the article about CAs
//
Function LinktothearticleonCAs() Export
	
	Ref = "";
	Return Ref;
	
EndFunction

#EndRegion

