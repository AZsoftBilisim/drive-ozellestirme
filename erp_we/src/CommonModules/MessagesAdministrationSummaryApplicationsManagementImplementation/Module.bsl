///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }SetSynopticExchange.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure ConfigureUploadingToSummaryApp_(DataAreaCode, Parameters) Export 
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }SetCorrSynopticExchange.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure ConfigureUploadingToSummaryApp(DataAreaCode, Parameters) Export 
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }PushSynopticExchangeStep1.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure InteractiveLaunchOfUploadingToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

// Processing incoming messages with type {http://www.1c.ru/1cFresh/ManageSynopticExchange/a.b.c.d }PushSynopticExchangeStep2.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataAreaCode - Number - data area code,
//  Parameters - Structure - ID of the backup,
//
Procedure InteractiveLaunchOfDownloadToSummaryApplication(DataAreaCode, Parameters) Export 
EndProcedure

#EndRegion
