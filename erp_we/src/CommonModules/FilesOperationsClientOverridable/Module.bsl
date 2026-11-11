///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called when an error occurs when capturing a file.
//
// Parameters:
//  FileData          - See FilesOperations.FileData.
//  StandardProcessing - Boolean - indicates a standard event processing.
//
Procedure OnFileCaptureError(FileData, StandardProcessing) Export

EndProcedure

// Called at the beginning of method FilesOperationsInternalClient.ActionWithFile().
//		Allows implementing custom logic for managing files stored in file archives.
//		For example, you can check if a file is available in the archive and, if it is not, open a custom form to submit 
//		a request to the administrator for access.
//
// Parameters:
//  FileOperationParameters	- See FilesOperationsClient.ParametersForAsynchronousFileReceipt
//  StandardProcessing		- Boolean - If set to False, method FilesOperationsInternalClient.ActionWithFile() 
//							  		will skip its default processing.
//
Procedure OnExecuteActionWithFile(FileOperationParameters, StandardProcessing = True) Export

EndProcedure

#EndRegion
