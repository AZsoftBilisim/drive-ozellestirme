///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//strict-types

#Region Internal

// BSP subscriptions
// 
// Returns: 
//  Structure:
// * BeforeExportData - Boolean
// * BeforeImportData - Boolean
// * AfterExportData - Boolean
// * AfterImportData - Boolean
// * AfterImportInfobaseUsers - Boolean
// * AfterImportInfobaseUser - Boolean
// * OnAddCTLUpdateHandlers - Boolean
// * OnImportInfobaseUser - Boolean
// * OnFillClearingDBDataExceptions - Boolean
// * OnFillIIBParametersTable - Boolean
// * OnFillTypesExcludedFromExportImport - Boolean
// * OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport - Boolean
// * OnFillCommonDataTypesSupportingRefMappingOnExport - Boolean
// * OnFillTypesThatRequireRefAnnotationOnImport - Boolean
// * OnUpdateCurrentDataAreaParameters - Boolean
// * OnDefineCorrespondentInterfaceVersion - Boolean
// * OnDefineSharedDataExceptions - Boolean
// * OnDefineScheduledJobsUsage - Boolean
// * OnDefineMessagesChannelsHandlers - Boolean
// * OnDefineErrorHandlers - Boolean
// * OnDefineSuppliedDataHandlers - Boolean
// * OnDefineUserAlias - Boolean
// * OnDefineHandlerAliases - Boolean
// * OnGetTemplateList - Boolean
// * OnRegisterDataExportHandlers - Boolean
// * OnRegisterDataImportHandlers - Boolean
// * OnSetIBParametersValues - Boolean
// * OnCreateServicesList - Boolean
// * RecordingOutgoingMessageInterfaces - Boolean
// * RecordingIncomingMessageInterfaces - Boolean
// (See CTLSubsystemsIntegration.EventsCTL)
Function SubscriptionsSSL() Export
	
	Subscriptions = CTLSubsystemsIntegration.EventsCTL();
	SSLSubsystemsIntegration.OnDefineEventsSubscriptionsCTL(Subscriptions);
	
	Return Subscriptions;
	
EndFunction

// BIP subscriptions
// 
// Returns:
//  Structure:
// * BeforeExportData - Boolean
// * BeforeImportData - Boolean
// * AfterExportData - Boolean
// * AfterImportData - Boolean
// * AfterImportInfobaseUsers - Boolean
// * AfterImportInfobaseUser - Boolean
// * OnAddCTLUpdateHandlers - Boolean
// * OnImportInfobaseUser - Boolean
// * OnFillClearingDBDataExceptions - Boolean
// * OnFillIIBParametersTable - Boolean
// * OnFillTypesExcludedFromExportImport - Boolean
// * OnFillCommonDataTypesThatDoNotRequireMappingRefsOnImport - Boolean
// * OnFillCommonDataTypesSupportingRefMappingOnExport - Boolean
// * OnFillTypesThatRequireRefAnnotationOnImport - Boolean
// * OnUpdateCurrentDataAreaParameters - Boolean
// * OnDefineCorrespondentInterfaceVersion - Boolean
// * OnDefineSharedDataExceptions - Boolean
// * OnDefineScheduledJobsUsage - Boolean
// * OnDefineMessagesChannelsHandlers - Boolean
// * OnDefineErrorHandlers - Boolean
// * OnDefineSuppliedDataHandlers - Boolean
// * OnDefineUserAlias - Boolean
// * OnDefineHandlerAliases - Boolean
// * OnGetTemplateList - Boolean
// * OnRegisterDataExportHandlers - Boolean
// * OnRegisterDataImportHandlers - Boolean
// * OnSetIBParametersValues - Boolean
// * OnCreateServicesList - Boolean
// * RecordingOutgoingMessageInterfaces - Boolean
// * RecordingIncomingMessageInterfaces - Boolean
// (See CTLSubsystemsIntegration.EventsCTL)
Function SubscriptionsOSL() Export
	
	Subscriptions = CTLSubsystemsIntegration.EventsCTL();
	If Common.SubsystemExists("OnlineUserSupport") Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule("OSLSubsystemsIntegration");
		ModuleOSLSubsystemsIntegration.OnDefineEventsSubscriptionsCTL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

Function PlusSubscriptions() Export
	
	Subscriptions = CTLSubsystemsIntegration.EventsCTL();
	If Common.SubsystemExists("PlusService") Then
		ModulePlusSubsystemsIntegration = Common.CommonModule("SubsystemIntegrationPlus");
		ModulePlusSubsystemsIntegration.OnDefineEventsSubscriptionsCTL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

#EndRegion