///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Allows adding new or changing the existing table document formats
// in order to comply with local requirements.
// For example, you can specify formats required by the local regulatory authorities.  
// 
// Parameters: 
//  FormatsTable - See StandardSubsystemsServer.SpreadsheetDocumentSaveFormatsSettings
//
Procedure OnSetupSpreadsheetSaveFormats(FormatsTable) Export
	
	
EndProcedure

// Defines the minimum and recommended 1C:Enterprise versions required for the configuration,
// as defined in "GeneralPurposeOverridable.OnDefiningCommonParametersOfBasicFunctionality".
// You can use it to set the minimum and recommended 1C:Enterprise versions based on external service data.
// 
// Parameters:
//  MinPlatformVersion   - See CommonOverridable.OnDetermineCommonCoreParameters.CommonParameters.
//  RecommendedPlatformVersion - See CommonOverridable.OnDetermineCommonCoreParameters.CommonParameters.
//
Procedure OnDefineMinAndRecommended1CEnterpriseVersions(MinPlatformVersion, RecommendedPlatformVersion) Export
	
	
EndProcedure

// Called when the minimum and recommended 1C:Enterprise versions are incorrectly specified
// in the OnDefineMinAndRecommended1CEnterpriseVersions procedure.
//
// Parameters:
//  MinSpecified - String
//  RecommendedSpecified - String
//  RequiredMinSSL - String
//  CommonParameters - See Common.CommonCoreParameters
//
Procedure OnFillIncorrectMinAndRecommended1CEnterpriseVersions(MinSpecified, RecommendedSpecified,
	RequiredMinSSL, CommonParameters) Export
	

EndProcedure

#EndRegion