///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Procedure RecordPaymentOfOperation(OperationType, OperationData, ExecutionResult) Export
	
	If CommonCEL.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");   
		ModuleEquipmentPaymentSystems.RecordPaymentOfOperation(OperationType, OperationData, ExecutionResult);
	EndIf
	
EndProcedure

// Sets the ID of the fiscal transaction in the log of logging payment transactions by request ID
//
// Parameters:
//   QueryID - String - Unique Request ID
//   FiscalTransactionID - String - Id Of The Fiscal Transaction
Procedure SetIdOfFiscalRecord(QueryID, FiscalTransactionID) Export
	
	If CommonCEL.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");   
		ModuleEquipmentPaymentSystems.SetIdOfFiscalRecord(QueryID, FiscalTransactionID);
	EndIf
	
EndProcedure

// ++ Non-mobile application 

Function ParametersForLoggingHardwareOfOperations() Export
	
	Return LoggingOfCELOperations.ParametersForLoggingHardwareOfOperations();
	
EndFunction

// -- Non-mobile application 

#EndRegion

