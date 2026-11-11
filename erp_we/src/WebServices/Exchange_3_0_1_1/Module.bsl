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
Function ExecuteExport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage)
	
	Return ExchangeWebServiceOperationData.ExecuteExport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage)
	
EndFunction

// An analog of the "UploadData" operation.
Function RunDataExport(ExchangePlanName, InfobaseNodeCode, FileIDAsString, TimeConsumingOperation,
	OperationID, TimeConsumingOperationAllowed)
	
	Return ExchangeWebServiceOperationData.RunDataExport(ExchangePlanName, InfobaseNodeCode, 
		FileIDAsString, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed)

EndFunction

// An analog of the "Download" operation.
Function ExecuteImport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage)
	
	Return ExchangeWebServiceOperationData.ExecuteImport(
		ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage);
	
EndFunction

// An analog of the "DownloadData" operation.
Function RunDataImport(ExchangePlanName, InfobaseNodeCode, FileIDAsString, TimeConsumingOperation,
	OperationID, TimeConsumingOperationAllowed)
	
	Return ExchangeWebServiceOperationData.RunDataImport(ExchangePlanName, InfobaseNodeCode, 
		FileIDAsString, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	
EndFunction

// An analog of the "GetIBParameters" operation.
Function GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage) 
	
	Return ExchangeWebServiceOperationData.GetInfobaseParameters(
		ExchangePlanName, NodeCode, ErrorMessage)
	
EndFunction

// An analog of the "CreateExchangeNode" operation.
Function CreateDataExchangeNode(XDTOParameters)
	
	Return ExchangeWebServiceOperationData.CreateDataExchangeNode(XDTOParameters);
	
EndFunction

// An analog of the "RemoveExchangeNode" operation.
Function DeleteDataExchangeNode(ExchangePlanName, NodeID)
	
	Return ExchangeWebServiceOperationData.DeleteDataExchangeNode(ExchangePlanName, NodeID);
	
EndFunction

// An analog of the "GetContinuousOperationStatus" operation.
Function GetTimeConsumingOperationState(OperationID, ErrorMessageString)
	
	Return ExchangeWebServiceOperationData.GetTimeConsumingOperationState(
		OperationID, ErrorMessageString);
	
EndFunction

// An analog of the "PrepareGetFile" operation.
Function PrepareGetFile(FileId, BlockSize, TransferId, PartQuantity)
	
	Return ExchangeWebServiceOperationData.PrepareFileForReceipt(FileId, BlockSize, TransferId, PartQuantity);
	
EndFunction

// An analog of the "GetFilePart" operation.
Function GetFilePart(TransferId, PartNumber, PartData)
	
	Return ExchangeWebServiceOperationData.GetFileChunk(TransferId, PartNumber, PartData);
	
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
Function PutFilePart(TransferId, PartNumber, PartData)
	
	Return ExchangeWebServiceOperationData.PutFileChunk(TransferId, PartNumber, PartData);
	
EndFunction

// An analog of the "SaveFileFromParts" operation.
Function SaveFileFromParts(TransferId, PartQuantity, FileId)
	
	Return ExchangeWebServiceOperationData.AssembleFileFromParts(TransferId, PartQuantity, FileId);
	
EndFunction

// An analog of the "PutMessageForDataMatching" operation.
Function PutMessageForDataMatching(ExchangePlanName, NodeID, FileID)
	
	Return ExchangeWebServiceOperationData.PutMessageForDataMapping(
		ExchangePlanName, NodeID, FileID);
	
EndFunction

// An analog of the "Ping" operation.
Function Ping()
	// Test connection.
	Return "";
EndFunction

// An analog of the "TestConnection" operation.
Function TestConnection(ExchangePlanName, NodeCode, Result)
	
	Return ExchangeWebServiceOperationData.TestingConnection(ExchangePlanName, NodeCode, Result);
	
EndFunction

#EndRegion
