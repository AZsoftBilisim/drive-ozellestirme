///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called from ExchangeMessagesTransport.AllTypesOfTransport.
// Returns all available transport types.
// 
// Parameters:
//  TypesOfTransport - Array of DataProcessorObject.ExchangeMessageTransportCOM,
//    DataProcessorObject.ExchangeMessageTransportEMAIL,
//    DataProcessorObject.ExchangeMessagesTransportESB1C,
//    DataProcessorObject.ExchangeMessagesTransportFILE,
//    DataProcessorObject.ExchangeMessagesTransportFTP,
//    DataProcessorObject.ExchangeMessagesTransportGoogleDrive,
//    DataProcessorObject.ExchangeMessagesTransportHTTP,
//    DataProcessorObject.ExchangeMessagesTransportSM,
//    DataProcessorObject.ExchangeMessagesTransportWS,
//    DataProcessorObject.ExchangeMessagesTransportPassiveMode,
//    DataProcessorObject.ExchangeMessagesTransportYandexDisk - Transport processors, including those added during customization.
//
Procedure WhenDeterminingTransportTypes(TypesOfTransport) Export
	
	
	
EndProcedure

// Called in ExchangeMessagesTransport.AvailableTransportTypes.
// Specifies available transport types for an exchange plan node.
// 
// Parameters:
//  AvailableTransportTypes - Array of DataProcessorObject.ExchangeMessageTransportCOM,
//    DataProcessorObject.ExchangeMessageTransportEMAIL,
//    DataProcessorObject.ExchangeMessagesTransportESB1C,
//    DataProcessorObject.ExchangeMessagesTransportFILE,
//    DataProcessorObject.ExchangeMessagesTransportFTP,
//    DataProcessorObject.ExchangeMessagesTransportGoogleDrive,
//    DataProcessorObject.ExchangeMessagesTransportHTTP,
//    DataProcessorObject.ExchangeMessagesTransportSM,
//    DataProcessorObject.ExchangeMessagesTransportWS,
//    DataProcessorObject.ExchangeMessagesTransportPassiveMode,
//    DataProcessorObject.ExchangeMessagesTransportYandexDisk - Transport processors, including those added during customization.
//  Peer - ExchangePlanRef - Target node.
//  SettingsMode - String - Setting option
//
Procedure WhenDeterminingAvailableTransportTypes(AvailableTransportTypes, Peer, SettingsMode = "") Export

	//
	
EndProcedure

// Called in ExchangeWebServiceOperationData.AssembleFileFromParts, 
// when putting a file to the exchange message storage (DataExchangeMessages information register).
// 
// Parameters:
//  FileName - String
//  FileID - String 
//
Procedure OnPutFileToStorage(FileName, FileID) Export
	
	//
	
EndProcedure

// Called in ExchangeWebServiceOperationData.PrepareFileForReceipt,
// before getting a file from the exchange message storage (DataExchangeMessages information register).
// 
// Parameters:
//  FileID - String
//
Procedure BeforeRetrievingFileFromRepository(FileID) Export

	//
	
EndProcedure

// On validating required transport settings attributes.
//
// Parameters:
//  Setting - QueryResult, Structure - Values of transport settings attributes.
//  TransportManager - Arbitrary - Transport manager. See ExchangeMessagesTransport.TransportManagerById().
//  SettingFilledIn - Boolean - Check result.
//
Procedure WhenCheckingFillingInRequiredAttributesOfTransportSettings(Setting, TransportManager, SettingFilledIn) Export
	
		
EndProcedure

#EndRegion
