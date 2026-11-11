///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// OnReadAtServer form event handler, which
// is embedded into item forms
// (these include forms of catalog items, documents, register records, etc).
// It locks a form if this is an attempt to modify shared data
// received from an application running in a standalone workstation.
//
// Parameters:
//  CurrentObject       - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject
//                      - InformationRegisterRecordManager - a record manager.
//  ReadOnly - Boolean - a ReadOnly form property.
//
Procedure ObjectOnReadAtServer(CurrentObject, ReadOnly) Export
	
	If Not ReadOnly Then
		
		MetadataObject = Metadata.FindByType(TypeOf(CurrentObject));
		StandaloneModeInternal.DefineDataChangeCapability(MetadataObject, ReadOnly);
		
	EndIf;
	
EndProcedure

// Disables automatic synchronization between a web application
// and a standalone workstation when the password for connection is not specified.
//
// Parameters:
//  Source - 
//             that was modified.
//
Procedure DisableAutoDataSyncronizationWithWebApplication(Source) Export
	
	StandaloneModeInternal.DisableAutoDataSyncronizationWithWebApplication(Source);
	
EndProcedure

// Reads and sets the notification option about long standalone workstation synchronization.
//
// Parameters:
//   FlagValue1     - Boolean - a flag value to be set
//   SettingDetails - Structure - takes a value for the setting description.
//
// Returns:
//   Boolean, Undefined - a setting value of the display warning of long-running synchronization.
//
Function LongSynchronizationQuestionSetupFlag(FlagValue1 = Undefined, SettingDetails = Undefined) Export
	
	Return StandaloneModeInternal.LongSynchronizationQuestionSetupFlag(FlagValue1, SettingDetails);
	
EndFunction

// Returns the password recovery address of the online application account.
//
// Returns:
//   String - an address for account password recovery.
//
Function AccountPasswordRecoveryAddress() Export
	
	Return StandaloneModeInternal.AccountPasswordRecoveryAddress();
	
EndFunction

// Initializes a standalone workstation upon the first start.
// Fills in a list of users and other settings.
// It is called before user authorization. It might require restarting the computer.
//
// Parameters:
//   Parameters - Structure - a parameter structure.
//
// Returns:
//   Boolean - indicates whether it is possible to continue standalone workstation setup.
//
Function ContinueStandaloneWorkstationSetup(Parameters) Export
	
	If Not StandaloneModeInternal.MustPerformStandaloneWorkstationSetupOnFirstStart() Then
		Return False;
	EndIf;
		
	Try
		StandaloneModeInternal.PerformStandaloneWorkstationSetupOnFirstStart();
		Parameters.Insert("RestartAfterStandaloneWorkstationSetup");
	Except
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(StandaloneModeInternal.StandaloneWorkstationCreationEventLogMessageText(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		Parameters.Insert("StandaloneWorkstationSetupError",
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Internal

Function ConstantNameArmBasicFunctionality() Export
	
	Return "StandardSubsystemsStandaloneMode";
	
EndFunction

Procedure DisablePropertyIB() Export
	
	IsStandaloneWorkplace = Constants.IsStandaloneWorkplace.CreateValueManager();
	IsStandaloneWorkplace.Read();
	If IsStandaloneWorkplace.Value Then
		
		IsStandaloneWorkplace.Value = False;
		ModuleUpdatingInfobase = Common.CommonModule("InfobaseUpdate");
		ModuleUpdatingInfobase.WriteData(IsStandaloneWorkplace);
		
	EndIf;
	
	ConstantName = ConstantNameArmBasicFunctionality();
	If Metadata.Constants.Find(ConstantName) <> Undefined Then
		
		If Constants[ConstantName].Get() = True Then
			
			Constants[ConstantName].Set(False);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Intended to be called from the master node reconnection form.
// See CommonForm.ReconnectToMasterNode.
//
Procedure WhenConfirmingDisconnectionOfCommunicationWithTheMasterNode() Export
	
	ConstantName = ConstantNameArmBasicFunctionality();
	IsConstantBaseFunctionality = (Metadata.Constants.Find(ConstantName) <> Undefined);
	
	If Constants.IsStandaloneWorkplace.Get() = False
		And 
		(IsConstantBaseFunctionality 
			And Constants[ConstantName].Get() = False) Then
		
		Return;
		
	EndIf;
	
	DisablePropertyIB();
	
	DoNotUseSeparationByDataAreas = Constants.DoNotUseSeparationByDataAreas.CreateValueManager();
	DoNotUseSeparationByDataAreas.Read();
	If Not Constants.UseSeparationByDataAreas.Get()
		And Not DoNotUseSeparationByDataAreas.Value Then
		
		DoNotUseSeparationByDataAreas.Value = True;
		
		ModuleUpdatingInfobase = Common.CommonModule("InfobaseUpdate");
		ModuleUpdatingInfobase.WriteData(DoNotUseSeparationByDataAreas);
		
	EndIf;
		
EndProcedure

#EndRegion