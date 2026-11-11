///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

// @strict-types

#Region Internal

Procedure OpenExportTemplatesForm(Val ReferencesArrray, Val ExecutionParameters) Export
	
	Form = ExecutionParameters.Form;
	FormParameters = New Structure;
	FormParameters.Insert("ExportTemplates", True);
	AdditionalParameters = ExecutionParameters.CommandDetails.AdditionalParameters;
	FormParameters.Insert("Owner", AdditionalParameters.Owner);
	
	OpenForm("InformationRegister.UserPrintTemplates.Form.PrintFormTemplates",
		FormParameters,
		Form);
	
EndProcedure

// Installs 1C:Enterprise Extension and runs the procedure
//  that opens the export form.
//  See FileSystemClient.AttachFileOperationsExtension
//  
// Parameters:
//  ReferencesArrray - Array of AnyRef
//  ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters 
// 
Procedure ExecuteExportCommandHandler(Val ReferencesArrray, Val ExecutionParameters) Export
	
	ExecutionParameters.Insert("PrintObjects", ReferencesArrray);
	ExecutionParameters.Insert("ShouldGenerateExportFile", True);
	CommonClientServer.SupplementStructure(
		ExecutionParameters.CommandDetails, 
		ExecutionParameters.CommandDetails.AdditionalParameters, 
		True); 
	
	AddnlParameter_ = New Structure;
	AddnlParameter_.Insert("ExecutionParameters", ExecutionParameters);
	Notification = New CallbackDescription("OnAttachExtensionForExport", ThisObject, AddnlParameter_);
	FileSystemClient.Attach1CEnterpriseExtension(Notification);
	
EndProcedure

#EndRegion

#Region Private

// Opens the "SaveByExportFormat" common form.
// 
// Parameters:
//  ExtensionAttached - Boolean
//  AdditionalParameters - Structure :
// * ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure OnAttachExtensionForExport(ExtensionAttached, AdditionalParameters) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("FileOperationsExtensionAttached", ExtensionAttached);
	
	PrintObjects = AdditionalParameters.ExecutionParameters.PrintObjects;
	ExecutionCommandDetails = New Structure;
	ExecutionCommandDetails.Insert("CommandDetails", AdditionalParameters.ExecutionParameters.CommandDetails);
	ExecutionCommandDetails.Insert("PrintObjects", PrintObjects);
	FormParameters.Insert("ExecutionCommandDetails", ExecutionCommandDetails);
	
	OpenForm(
		"CommonForm.SaveByExportFormat",
		FormParameters,
		AdditionalParameters.ExecutionParameters.Form);

EndProcedure

#EndRegion
