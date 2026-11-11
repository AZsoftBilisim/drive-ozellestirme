///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function AccreditedCertificationCenters() Export
	
	Return DigitalSignatureInternalServerCall.AccreditedCertificationCenters();
	
EndFunction

Function CertificationAuthorityData(SearchValues) Export
	
	AccreditedCertificationCenters = DigitalSignatureInternalClientCached.AccreditedCertificationCenters();
	If AccreditedCertificationCenters = Undefined Then
		Return Undefined;
	EndIf;
	
	ModuleDigitalSignatureClientServerLocalization = CommonClient.CommonModule("DigitalSignatureClientServerLocalization");
	Return ModuleDigitalSignatureClientServerLocalization.CertificationAuthorityData(SearchValues, AccreditedCertificationCenters);
	
EndFunction

Function CARevocationListDirectories() Export
	
	AccreditedCertificationCenters = DigitalSignatureInternalClientCached.AccreditedCertificationCenters();
	ModuleDigitalSignatureClientServerLocalization = CommonClient.CommonModule("DigitalSignatureClientServerLocalization");
	Return ModuleDigitalSignatureClientServerLocalization.CARevocationListDirectories(AccreditedCertificationCenters);
	
EndFunction


Function ClassifierError(ErrorText, ErrorAtServer = False, SignatureVerificationError = False,
		IsCertificateSpecified = False) Export
	
	Return DigitalSignatureInternalServerCall.ClassifierError(ErrorText, ErrorAtServer, SignatureVerificationError,
		IsCertificateSpecified);
	
EndFunction

#EndRegion