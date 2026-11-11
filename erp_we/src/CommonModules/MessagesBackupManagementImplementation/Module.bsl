///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Processing incoming messages with type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d }PlanZoneBackup.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  BackupID - UUID - ID of the backup,
//  BackupMoment - Date - date and time of the backup,
//  Forcibly - Boolean - flag for forced backup creation.
//  ForSupport - Boolean - indicates whether to create a copy for the support service.
//
Procedure PlanToCreateBackupOfArea(Val DataAreaCode,
		Val BackupID, Val BackupMoment,
		Val Forcibly, Val ForSupport) Export
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d }CancelZoneBackup.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  BackupID - UUID - ID of the backup.
//
Procedure CancelBackupOfArea(Val DataAreaCode, Val BackupID) Export
EndProcedure

// Processing incoming messages with the type
// {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d}UpdateScheduledZoneBackupSettings.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataArea - Number - value of the data area separator.
//  Settings - Structure - new backup settings.
//
Procedure UpdatePeriodicBackupSettings(Val DataArea, Val Settings) Export
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/SaaS/ManageZonesBackup/a.b.c.d }CancelScheduledZoneBackup.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataArea - Number - value of the data area separator.
//
Procedure CancelPeriodicBackups(Val DataArea) Export
EndProcedure

#EndRegion
