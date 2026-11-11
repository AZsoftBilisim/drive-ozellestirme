///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Starts data exchange and is used in the background job.
//
// Parameters:
//   JobParameters - Structure - parameters required to execute the procedure.
//   StorageAddress   - String - address of the temporary storage.
//
Procedure StartDataExchangeExecution(JobParameters, StorageAddress) Export
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	
	FillPropertyValues(ExchangeParameters, JobParameters,
		"TransportID,ExecuteImport1,ExecuteExport2,AuthenticationData");
	
	DataExchangeServer.CheckWhetherTheExchangeCanBeStarted(JobParameters.InfobaseNode, JobParameters.Cancel);
	
	If Not JobParameters.Cancel Then
		
		DataExchangeServer.ExecuteDataExchangeForInfobaseNode(
			JobParameters.InfobaseNode,
			ExchangeParameters,
			JobParameters.Cancel);
			
	EndIf;
	
	PutToTempStorage(JobParameters, StorageAddress);
	
EndProcedure

#EndRegion

#EndIf