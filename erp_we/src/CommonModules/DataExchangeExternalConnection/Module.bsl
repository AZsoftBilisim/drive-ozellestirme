///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns data from a list of objects of the specified metadata object as a system presentation.
// 
// Parameters:
//  FullTableName - String - a name of the table that corresponds to the metadata object.
// 
// Returns:
//  String - system presentation of a value table containing data of the specified metadata object.
//
Function GetTableObjects(FullTableName) Export
	
	Return ValueToStringInternal(Common.ValueFromXMLString(DataExchangeServer.GetTableObjects(FullTableName)));
	
EndFunction

// Returns data from a list of objects of the specified metadata object as an XML string.
// 
// Parameters:
//  FullTableName - String - a name of the table that corresponds to the metadata object.
// 
// Returns:
//  String - an XML string of serialized presentation of the value table containing specified metadata object data.
//
Function GetTableObjects_2_0_1_6(FullTableName) Export
	
	Return DataExchangeServer.GetTableObjects(FullTableName);
	
EndFunction

// Returns specified properties (Synonym, Hierarchical) of a metadata object.
// 
// Parameters:
//  FullTableName - String - a name of the table that corresponds to the metadata object.
// 
// Returns:
//  Structure - Metadata object properties.:
//    * Synonym - String - synonym.
//    * Hierarchical - String - the Hierarchical flag.
//
Function MetadataObjectProperties(FullTableName) Export
	
	Return DataExchangeServer.MetadataObjectProperties(FullTableName);
	
EndFunction

#EndRegion

#Region Internal

// ACC:299-off - The method is intended for backward compatibility when syncing via a COM connection.

// 
// Exports data for the infobase node to a temporary file.
// The procedure is used during synchronization via COM connection with additional parameters.
// Only peer infobases can call it (through an external connection), therefore, it is not implemented in this infobase.
//
// Parameters:
//  Cancel - Boolean - Flag indicating whether an error occurred when preparing a message.
//  ExchangePlanName - String - IFDE plan name.
//  InfobaseNodeCode - String - String used to identify the exchange plan node with settings.
//  FullNameOfExchangeMessageFile - String - Path to the file that will take the conversion result.
//  ErrorMessageString - String - Error details.
//
Procedure ExportForInfobaseNode(Cancel, ExchangePlanName, InfobaseNodeCode, FullNameOfExchangeMessageFile, ErrorMessageString = "") Export
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	If Common.FileInfobase() Then
		
		Try
			DataExchangeServer.ExportForInfobaseNodeViaFile(ExchangePlanName, InfobaseNodeCode, FullNameOfExchangeMessageFile);
		Except
			Cancel = True;
			ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
		
	Else
		
		Address = "";
		
		Try
			
			DataExchangeServer.ExportToTempStorageForInfobaseNode(ExchangePlanName, InfobaseNodeCode, Address);
			
			MessageData = GetFromTempStorage(Address); // BinaryData
			MessageData.Write(FullNameOfExchangeMessageFile);
			
			DeleteFromTempStorage(Address);
			
		Except
			Cancel = True;
			ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
		
	EndIf;
	
EndProcedure

// ACC:299-on

// Records data exchange start in the event log.
// (For internal use only).
//
Procedure WriteLogEventDataExchangeStart(ExchangeSettingsStructure) Export
	
	DataExchangeServer.WriteLogEventDataExchangeStart(ExchangeSettingsStructure);
	
EndProcedure

// Records completion of data exchange via external connection.
// (For internal use only).
//
Procedure WriteExchangeFinish(ExchangeSettingsStructureExternalConnection) Export
	
	ExchangeSettingsStructureExternalConnection.ExchangeExecutionResult = Enums.ExchangeExecutionResults[ExchangeSettingsStructureExternalConnection.ExchangeExecutionResultString];
	
	DataExchangeServer.WriteExchangeFinishUsingExternalConnection(ExchangeSettingsStructureExternalConnection);
	
EndProcedure

// Gets read object conversion rules by the exchange plan name.
// (For internal use only).
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
//  GetCorrespondentRules - Boolean - By default, it is set to "False".
// 
// Returns:
//  - Undefined
//  - ValueStorage - Value storage with conversion rules
//
Function GetObjectConversionRules(ExchangePlanName, GetCorrespondentRules = False) Export
	
	Return DataExchangeServer.GetObjectConversionRulesViaExternalConnection(ExchangePlanName, GetCorrespondentRules);
	
EndFunction

// Receives the structure of exchange settings.
// (For internal use only).
// 
// Parameters:
//  Structure - Structure:
//   *ExchangePlanName - String
//   *CorrespondentExchangePlanName - String
//   *CurrentExchangePlanNodeCode1 - String
//   *TransactionItemsCount - Number
//   *ActionOnStringExchange - String - Value of the ActionsOnExchange enumeration.
//   *DebugMode - Boolean
//   *ExchangeProtocolFileName - String
// 
// Returns:
//   See DataExchangeServer.ExchangeOverExternalConnectionSettingsStructure
// 
Function ExchangeSettingsStructure(Structure) Export
	
	Return DataExchangeServer.ExchangeOverExternalConnectionSettingsStructure(DataExchangeEvents.CopyStructure(Structure));
	
EndFunction

// Checks if the exchange plan with the specified name exists.
// (For internal use only).
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
// 
// Returns:
//  Boolean - Exchange plan exists
//
Function ExchangePlanExists(ExchangePlanName) Export
	
	Return Metadata.ExchangePlans.Find(ExchangePlanName) <> Undefined;
	
EndFunction

// Gets the prefix of default infobase via external connection.
// Wrapper of a function with the same name in the overridable module.
// (For internal use only).
// 
// Returns:
//  - Undefined
//  - String
//
Function DefaultInfobasePrefix() Export
	
	InfobasePrefix = Undefined;
	DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(InfobasePrefix);
	
	Return InfobasePrefix;
	
EndFunction

// Checks whether it is necessary to check conversion rules for version differences.
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
// 
// Returns:
//   See DataExchangeServer.ExchangePlanSettingValue
//
Function WarnAboutExchangeRuleVersionMismatch(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "WarnAboutExchangeRuleVersionMismatch");
	
EndFunction

// Receives the flag of the FullAccess role availability.
// (For internal use only).
// 
// Returns:
//   See Users.IsFullUser
//
Function RoleAvailableFullAccess() Export
	
	Return Users.IsFullUser(, True);
	
EndFunction

// Returns a name of a predefined exchange plan node.
// (For internal use only).
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
// 
// Returns:
//   See DataExchangeServer.PredefinedExchangePlanNodeDescription
Function PredefinedExchangePlanNodeDescription(ExchangePlanName) Export
	
	Return DataExchangeServer.PredefinedExchangePlanNodeDescription(ExchangePlanName);
	
EndFunction

// Returns a code of a predefined exchange plan node.
// (For internal use only).
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
// 
// Returns:
//   See DataExchangeServer.PredefinedExchangePlanNodeCode
//
Function PredefinedExchangePlanNodeCode(ExchangePlanName) Export
	
	Return DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
	
EndFunction

// For internal use.
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
// 
// Returns:
//  String - System presentation of the structure with the tables from the given exchange plan.
//
Function GetCommonNodesData(Val ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Return ValueToStringInternal(DataExchangeServer.DataForThisInfobaseNodeTabularSections(ExchangePlanName));
	
EndFunction

// For internal use.
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object
// 
// Returns:
//  String - System presentation of the structure with the tables from the given exchange plan.
//
Function GetCommonNodesData_2_0_1_6(Val ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Return Common.ValueToXMLString(DataExchangeServer.DataForThisInfobaseNodeTabularSections(ExchangePlanName));
	
EndFunction

// For internal use.
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
//  NodeCode - String 
//  ErrorMessage - String
// 
// Returns:
//  String - System presentation of the structure containing infobase parameters
//
Function GetInfobaseParameters(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return DataExchangeServer.GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage);
	
EndFunction

// For internal use.
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
//  NodeCode - String 
//  ErrorMessage - String
// 
// Returns:
//  String - Serialized presentation of the structure containing infobase parameters.
//
Function GetInfobaseParameters_2_0_1_6(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return DataExchangeServer.GetInfobaseParameters_2_0_1_6(ExchangePlanName, NodeCode, ErrorMessage);
	
EndFunction

// For internal use.
// 
// Parameters:
//  ExchangePlanName - String - Name of exchange plan as metadata object.
//  NodeCode - String 
//  ErrorMessage - String
//  AdditionalParameters - Structure - Structure of additional parameters
// 
// Returns:
//  String - Serialized presentation of the structure containing infobase parameters.
//
Function GetInfobaseParameters_3_0_2_2(Val ExchangePlanName, Val NodeCode, ErrorMessage,
	AdditionalParameters = Undefined) Export 
	
	Return DataExchangeServer.GetInfobaseParameters_3_0_2_2(ExchangePlanName, NodeCode, ErrorMessage,
		AdditionalParameters);
	
EndFunction

#EndRegion
