///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// See JobsQueueOverridable.OnDefineHandlerAliases.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

#Region JobsQueueHandlers

// Performs processing of the supplied subscriber data.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	FileID - String - ID of the file to process (length 36).
//
// Example:
// Example of file content: {"upload": [{"file": "base_data.json", "handler": "base_data"}]}, where
//  - upload-a section with descriptions of the processing order, can contain several elements.
//  - file - the name of the initial data file to be processed.
//  - handler-id of the initial data file handler.
//
Procedure ProcessData__(FileID) Export
EndProcedure

#EndRegion

#EndRegion

