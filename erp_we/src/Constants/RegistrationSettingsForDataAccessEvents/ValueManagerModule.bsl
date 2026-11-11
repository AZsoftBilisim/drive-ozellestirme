///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var PreviousSettings1; // Filled "BeforeWrite" to use "OnWrite".

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	// ACC:75-off - The DataExchange.Load check must follow the logging of changes.
	PrepareChangesForLogging(PreviousSettings1);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// ACC:75-off - The DataExchange.Load check must follow the logging of changes.
	DoLogChanges(PreviousSettings1);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  StoredSettings - See UserMonitoringInternal.StoredRegistrationSettings
//
// Returns:
//  Structure:
//   * DataStructureVersion - Number
//   * Use - Boolean
//   * Settings - Array of EventLogAccessEventUseDescription
//
Function SettingsToRegister(StoredSettings)
	
	Result = New Structure;
	Result.Insert("DataStructureVersion", 1);
	Result.Insert("Use", StoredSettings.Use);
	Result.Insert("Settings", StoredSettings.Content);
	
	Return Result;
	
EndFunction

Procedure PrepareChangesForLogging(PreviousSettings1)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	StoredSettings = UserMonitoringInternal.StoredRegistrationSettings();
	PreviousSettings1 = SettingsToRegister(StoredSettings);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Parameters:
//  PreviousSettings1 - See SettingsToRegister
//
Procedure DoLogChanges(PreviousSettings1)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	StoredSettings = UserMonitoringInternal.StoredRegistrationSettings(Value);
	NewSettings1 = SettingsToRegister(StoredSettings);
	
	HasChanges = False;
	For Each KeyAndValue In NewSettings1 Do
		If ValueToStringInternal(PreviousSettings1[KeyAndValue.Key])
		  <> ValueToStringInternal(KeyAndValue.Value) Then
			HasChanges = True;
			Break;
		EndIf;
	EndDo;
	
	If Not HasChanges Then
		Return;
	EndIf;
	
	Settings = NewSettings1.Settings;
	NewSettings1.Settings = New Array;
	
	For Each Setting In Settings Do
		SettingDetails = New Structure("Object, AccessFields, LoggedFields");
		FillPropertyValues(SettingDetails, Setting);
		NewSettings1.Settings.Add(SettingDetails);
	EndDo;
	
	WriteLogEvent(
		UserMonitoringInternal.EventNameDataAccessAuditingEventRegistrationSettingsChange(),
		EventLogLevel.Information,
		Metadata.Constants.RegistrationSettingsForDataAccessEvents,
		Common.ValueToXMLString(NewSettings1),
		,
		EventLogEntryTransactionMode.Transactional);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf