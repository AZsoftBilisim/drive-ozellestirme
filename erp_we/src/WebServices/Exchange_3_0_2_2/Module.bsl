///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Web service operation handlers.

// An analog of the "Upload" operation.
Function ExecuteExport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea)

	Return ExchangeWebServiceOperationData.ExecuteExport(
		ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea);

EndFunction

// An analog of the "UploadData" operation.
Function RunDataExport(ExchangePlanName, InfobaseNodeCode, FileIDAsString, TimeConsumingOperation,
	OperationID, TimeConsumingOperationAllowed, DataArea)
	
	Return ExchangeWebServiceOperationData.RunDataExport(ExchangePlanName, InfobaseNodeCode, 
		FileIDAsString, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed, DataArea)

EndFunction

// An analog of the "UploadDataInt" operation.
Function RunDataExportInternalPublication(ExchangePlanName, InfobaseNodeCode, TaskID__, DataArea)
	
	Return ExchangeWebServiceOperationData.RunDataExportInternalPublication(
		ExchangePlanName, InfobaseNodeCode, TaskID__, DataArea);
	
EndFunction

// An analog of the "Download" operation.
Function ExecuteImport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea)
	
	Return ExchangeWebServiceOperationData.ExecuteImport(
		ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage, DataArea);
	
EndFunction

// An analog of the "DownloadData" operation.
Function RunDataImport(ExchangePlanName, InfobaseNodeCode, FileIDAsString, TimeConsumingOperation,
	OperationID, TimeConsumingOperationAllowed, DataArea)
		
	Return ExchangeWebServiceOperationData.RunDataImport(ExchangePlanName, InfobaseNodeCode, 
		FileIDAsString, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed, DataArea);
	
EndFunction

// An analog of the "DownloadDataInt" operation.
Function RunDataImportInternalPublication(ExchangePlanName, InfobaseNodeCode, TaskID__,
	FileIDAsString, DataArea)
	
	Return ExchangeWebServiceOperationData.RunDataImportInternalPublication(
		ExchangePlanName, InfobaseNodeCode, TaskID__,
		FileIDAsString, DataArea);
	
EndFunction

// An analog of the "GetIBParameters" operation.
Function GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage, DataArea, AdditionalXDTOParameters) 
	
	Return ExchangeWebServiceOperationData.GetInfobaseParameters(
		ExchangePlanName, NodeCode, ErrorMessage, DataArea, AdditionalXDTOParameters)
	
EndFunction

// An analog of the "CreateExchangeNode" operation.
Function CreateDataExchangeNode(XDTOParameters, DataArea)
	
	Return ExchangeWebServiceOperationData.CreateDataExchangeNode(XDTOParameters, DataArea);
	
EndFunction

// An analog of the "RemoveExchangeNode" operation.
Function DeleteDataExchangeNode(ExchangePlanName, NodeID, DataArea)
	
	Return ExchangeWebServiceOperationData.DeleteDataExchangeNode(ExchangePlanName, NodeID, DataArea);
	
EndFunction

// An analog of the "GetContinuousOperationStatus" operation.
Function GetTimeConsumingOperationState(OperationID, ErrorMessageString, DataArea)
	
	Return ExchangeWebServiceOperationData.GetTimeConsumingOperationState(
		OperationID, ErrorMessageString, DataArea);
		
EndFunction

// An analog of the "PrepareGetFile" operation.
Function PrepareGetFile(FileId, BlockSize, TransferId, PartQuantity, Zone)
	
	Return ExchangeWebServiceOperationData.PrepareFileForReceipt(FileId, BlockSize, TransferId, PartQuantity, Zone);
	
EndFunction

// An analog of the "GetFilePart" operation.
Function GetFilePart(TransferId, PartNumber, PartData, Zone)
	
	Return ExchangeWebServiceOperationData.GetFileChunk(TransferId, PartNumber, PartData, Zone);
	
EndFunction

// An analog of the "ReleaseFile" operation.
Function ReleaseFile(TransferId)
	
	Return ExchangeWebServiceOperationData.DeleteExchangeMessage(TransferId);
	
EndFunction

// An analog of the "PutFilePart" operation.
//
// Parameters:
//   TransferId - UUID - data transfer session UUID.
//   PartNumber - Number - the file part number.
//   PartData - BinaryData - the file part details.
//
Function PutFilePart(TransferId, PartNumber, PartData, Zone)
	
	Return ExchangeWebServiceOperationData.PutFileChunk(TransferId, PartNumber, PartData, Zone);
	
EndFunction

// An analog of the "SaveFileFromParts" operation.
Function SaveFileFromParts(TransferId, PartQuantity, FileId, Zone)
	
	Return ExchangeWebServiceOperationData.AssembleFileFromParts(TransferId, PartQuantity, FileId, Zone);
	
EndFunction

// An analog of the "PutMessageForDataMatching" operation.
Function PutMessageForDataMatching(ExchangePlanName, NodeID, FileID, DataArea)
	
	Return ExchangeWebServiceOperationData.PutMessageForDataMapping(
		ExchangePlanName, NodeID, FileID, DataArea);
	
EndFunction

// An analog of the "Ping" operation.
Function Ping()
	// Test connection.
	Return "";
EndFunction

// An analog of the "TestConnection" operation.
Function TestConnection(ExchangePlanName, NodeCode, Result, DataArea)
	
	Return ExchangeWebServiceOperationData.TestingConnection(ExchangePlanName, NodeCode, Result, DataArea);
	
EndFunction

// An analog of the "ChangeNodeTransportToWSPass" operation.
Function ChangeNodeTransportToWSInt(XDTOParameters, DataArea)
	
	Return ExchangeWebServiceOperationData.ChangeTransportToInternalPublishingWebService(XDTOParameters, DataArea);
	
EndFunction

// An analog of the "Callback" operation.
Function Callback(TaskID, Error, Zone)
	
	Return ExchangeWebServiceOperationData.CallingBack(TaskID, Error, Zone);
	
EndFunction

// Matches the "TaskStatus" operation.
Function TaskStatus(TaskID)
	
	Return ExchangeWebServiceOperationData.TaskStatus(TaskID);
	
EndFunction

// An analog of the "StopTasks" operation.
Function StopTasks(TasksID, Zone)
	
	Return ExchangeWebServiceOperationData.StopTasks(TasksID, Zone);
		
EndFunction

#EndRegion
