///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Subsystem "Library of connected equipment".
// A common module.Integrationsubsystem.
//
// Server procedures and functions of integration with BSP:
//  - Subscription to BSP events;
//  - Processing of BSP events;
//  - Determination of the list of possible subscriptions in the BSP;
//  - Calling the BSP methods subscribed to.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region InterfaceImplementation

// Defines events that this library is subscribed to.
//
// Parameters:
//  Subscriptions - Structure
//
Procedure OnDefineEventSubscriptionsSSL(Subscriptions) Export
	
	// Core
	Subscriptions.OnAddSubsystems = True;
	Subscriptions.OnAddClientParametersOnStart = True;
	Subscriptions.OnAddSessionParameterSettingHandlers = True;
	
	// AddIns
	Subscriptions.OnDefineUsedAddIns = True;
	
	// ScheduledJobs
	Subscriptions.OnDefineScheduledJobSettings = True;
	
	
EndProcedure

// See SSLSubsystemsIntegration.OnDefineUsedAddIns.
//
Procedure OnDefineUsedAddIns(Components) Export
	
	EquipmentManager.FillInExternalComponentsUsed(Components);
	
EndProcedure

#Region Core

// See ConfigurationSubsystemsOverridable.OnAddSubsystems.
//
Procedure OnAddSubsystems(SubsystemsModules) Export
	
	SubsystemsModules.Add("InfobaseUpdateCEL");
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
//
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If CommonCEL.DataSeparationEnabled() 
		And Not CommonCEL.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Not CommonCEL.BSPIsUsed() Then
		Parameters.Insert("SubsystemsNames", CommonCELCached.SubsystemsNames());
		If Parameters.Property("CurrentDateOnClient") Then
			SessionDate = CurrentSessionDate();
			Parameters.Insert("SessionTimeOffset", SessionDate - Parameters.CurrentDateOnClient);
		Else
			Parameters.Insert("SessionTimeOffset", 0);
		EndIf;
	EndIf;
	
	IdOfDistributedFiscalizationDiscussion = Undefined;
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		IdOfDistributedFiscalizationDiscussion = ModuleDistributedFiscalization.ConnectingInteractionSystem();
	EndIf;
	
	SSLVersion = CommonCEL.SSLVersion();
	Parameters.Insert("SSLVersion", SSLVersion);
	Parameters.Insert("LibraryVersion", EquipmentManager.LibraryVersion());
	Parameters.Insert("IdOfDistributedFiscalizationDiscussion", IdOfDistributedFiscalizationDiscussion);
	Parameters.Insert("CompatibilityOfEquipmentTypes", EquipmentManager.CompatibilityOfEquipmentTypes());
	Parameters.Insert("AvailableTypesOfEquipment", EquipmentManager.AvailableTypesOfEquipment(True));
	Parameters.Insert("ClientNotificationsAreAvailable", CommonCEL.ClientNotificationsAreAvailable());
	
	SetPrivilegedMode(True);
	Workplace = SessionParameters.CustomerWorkplace; // direct access to the session parameter is required
	WorkplaceParameters = EquipmentManager.WorkplaceSettingsAtStartup(Workplace);
	Parameters.Insert("WorkplaceParameters", WorkplaceParameters);
	Parameters.Insert("ThereIsPlugInEquipmentAtWorkplace", 
		EquipmentManager.ThereIsPlugInEquipmentAtWorkplace(Workplace));
	
	// ++ Non-mobile application
	If CommonCEL.SeparatedDataUsageAvailable() Then
		WorkplaceParameters.RDPIsUsed = EquipmentManager.RDPProtocolIsUsed();
	EndIf;
	// -- Non-mobile application
	
	EquipmentForReinstalling = EquipmentManager.TemplatesForReinstallingDrivers(Workplace);
	Parameters.Insert("EquipmentForReinstalling", EquipmentForReinstalling);
	
	Parameters.Insert("ParametersForLoggingHardwareOfOperations", Undefined);
	If CommonCEL.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPO = CommonCEL.CommonModule("LoggingOfCELOperations");
		ParametersOfLogging = ModuleLoggingOfOperationsOfBPO.ParametersForLoggingHardwareOfOperations();
		Parameters.ParametersForLoggingHardwareOfOperations = ParametersOfLogging;
	EndIf;
	
	Parameters.Insert("LibraryClassifiers", EquipmentManager.LibraryClassifiers());
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
//
Procedure OnAddClientParameters(Parameters) Export
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
//
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
EndProcedure

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
//
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("CustomerWorkplace", 
		"EquipmentManagerServerCall.SetSessionParametersOfConnectedHardware");
	
EndProcedure                      

// The call to this procedure must be placed in the session module in the session parameter Setting procedure
// according to the documentation.
//
// Parameters:
//  SessionParametersNames - Array - session parameter identifiers to be set
//
Procedure SessionParametersSetting(SessionParametersNames) Export
	
	If SessionParametersNames <> Undefined Then
		
		For Each ParameterName In SessionParametersNames Do
			If ParameterName = "CustomerWorkplace" Then
				EquipmentManagerServerCall.SetSessionParametersOfConnectedHardware(ParameterName, Undefined);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// This procedure must be called after updating the BPO, if the BSP is not used
Procedure InfobaseUpdateCEL() Export
	
	EquipmentManager.UpdateSuppliedDrivers(); 
	EquipmentManager.UpdateInstalledDrivers();
	
	InfobaseUpdateCEL.UpdateLabelAndPriceTagTemplates();
	InfobaseUpdateCEL.UpdateHardwareRegistrationParameters();
	InfobaseUpdateCEL.SetRetentionPeriodOfOperations();
	
	
EndProcedure

#EndRegion

#Region ScheduledJobs

// It is called from the routine taskdetermined procedure.When
// defining the settings of the scheduled tasks to set the availability of the scheduled task, determines the dependence on the functional options.
// 
// Parameters:
//  Settings - ValueTable
//  FunctionalOption - MetadataObjectFunctionalOption
Procedure OnDefineScheduledJobSettings(Settings, FunctionalOption = Undefined) Export
	
	// ++ Non-mobile application
	If CommonCEL.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");
		ModuleEquipmentPaymentSystems.OnDefineScheduledJobSettings(Settings, FunctionalOption);
	EndIf;
	
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
		ModuleEquipmentReceiptPrintingDevices.OnDefineScheduledJobSettings(Settings, FunctionalOption);
		If CommonCEL.MarkingIsUsed() Then
			ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
			ModuleEquipmentManagerMarking.OnDefineScheduledJobSettings(Settings, FunctionalOption);
		EndIf;
	EndIf;

	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		ModuleDistributedFiscalization.OnDefineScheduledJobSettings(Settings, FunctionalOption);
	EndIf;

	If CommonCEL.ElectronicCashReceiptMailoutIsUsed() Then
		ElectronicReceiptMailingModule = CommonCEL.CommonModule("ElectronicCashReceiptMailout");
		ElectronicReceiptMailingModule.OnDefineScheduledJobSettings(Settings, FunctionalOption);
	EndIf;
	
	If CommonCEL.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPO = CommonCEL.CommonModule("LoggingOfCELOperations");
		ModuleLoggingOfOperationsOfBPO.OnDefineScheduledJobSettings(Settings, FunctionalOption);
	EndIf;
	// -- Non-mobile application
	
EndProcedure

#EndRegion

#Region RoutineTasksServiceTechnology

// See JobsQueueOverridable.OnGetTemplateList
Procedure OnGetTemplateList(JobTemplates) Export
	
	// ++ Non-mobile application
	If CommonCEL.UsedPaymentSystems() Then
		JobTemplates.Add(Metadata.ScheduledJobs.ClearHistoryOfPaymentTransactions.Name);
	EndIf;
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		JobTemplates.Add(Metadata.ScheduledJobs.ClearHistoryOfFiscalTransactions.Name);
		If CommonCEL.MarkingIsUsed() Then
			ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
			ModuleEquipmentManagerMarking.OnGetTemplateList(JobTemplates);
		EndIf;
	EndIf;
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		ModuleDistributedFiscalization.OnGetTemplateList(JobTemplates);
	EndIf;
	If CommonCEL.ElectronicCashReceiptMailoutIsUsed() Then
		ElectronicReceiptMailingModule = CommonCEL.CommonModule("ElectronicCashReceiptMailout");
		ElectronicReceiptMailingModule.OnGetTemplateList(JobTemplates);
	EndIf;
	
	If CommonCEL.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPO = CommonCEL.CommonModule("LoggingOfCELOperations");
		ModuleLoggingOfOperationsOfBPO.OnGetTemplateList(JobTemplates);
	EndIf;
	
	// -- Non-mobile application
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	// ++ Non-mobile application
	If CommonCEL.UsedPaymentSystems() Then
		NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ClearHistoryOfPaymentTransactions.MethodName);
	EndIf;
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ClearHistoryOfFiscalTransactions.MethodName);
		If CommonCEL.MarkingIsUsed() Then
			ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
			ModuleEquipmentManagerMarking.OnDefineHandlerAliases(NamesAndAliasesMap);
		EndIf;
	EndIf;
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		ModuleDistributedFiscalization.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	If CommonCEL.ElectronicCashReceiptMailoutIsUsed() Then
		ElectronicReceiptMailingModule = CommonCEL.CommonModule("ElectronicCashReceiptMailout");
		ElectronicReceiptMailingModule.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	If CommonCEL.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPO = CommonCEL.CommonModule("LoggingOfCELOperations");
		ModuleLoggingOfOperationsOfBPO.OnDefineHandlerAliases(NamesAndAliasesMap);
	EndIf;
	// -- Non-mobile application
	
EndProcedure

#EndRegion

#Region ServerNotifications

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	If CommonCEL.DataSeparationEnabled() 
		And Not CommonCEL.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ServerAlertsModule = CommonCEL.CommonModule("ServerNotifications");
	Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	If EquipmentManager.ThereIsPlugInEquipmentAtWorkplace(Workplace) Then
		
		NameOfAlert = EquipmentManagerClientServer.KeyForRequestingDriverLogArchive();
		Notification = ServerAlertsModule.NewServerNotification(NameOfAlert);
		Notification.NotificationReceiptModuleName = "PELSubsystemsIntegrationClient";
		Notification.VerificationPeriod = 60;
		Notifications.Insert(Notification.Name, Notification);
	
	EndIf;
	
	NameOfAlert = EquipmentManagerClientServer.KeyForRespondingToRequestForDriverLogArchive();
	Notification = ServerAlertsModule.NewServerNotification(NameOfAlert);
	Notification.NotificationReceiptModuleName = "PELSubsystemsIntegrationClient";
	Notification.VerificationPeriod = 60;
	Notifications.Insert(Notification.Name, Notification);
	
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion
