////////////////////////////////////////////////////////////////////////////////
// GENERAL IMPLEMENTATION OF REMOTE ADMINISTRATION MESSAGE PROCESSING
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// {http://www.1c.ru/1cFresh/Application/Permissions/Control/a.b.c.d}InfoBasePermissionsRequestProcessed
//
// Parameters:
//  IDOfPackage - UUID - ID of the request to use external resources.
//  ProcessingResult - EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS - processing result,
//  ErrorInfo - XDTODataObject - {http://www.1c.ru/SaaS/ServiceCommon}ErrorDescription.
//
Procedure UnsharedSessionRequestProcessed(Val IDOfPackage, Val ProcessingResult, Val ErrorInfo) Export
	
	RequestProcessed(IDOfPackage, ProcessingResult);
	
EndProcedure

// {http://www.1c.ru/1cFresh/Application/Permissions/Control/a.b.c.d}ApplicationPermissionsRequestProcessed
//
// Parameters:
//  IDOfPackage - UUID - ID of the request to use external resources.
//  ProcessingResult - EnumRef.ExternalResourcesUsageQueriesProcessingResultsSaaS - processing result,
//  ErrorInfo - XDTODataObject - {http://www.1c.ru/SaaS/ServiceCommon}ErrorDescription.
//
Procedure SplitSessionRequestProcessed(Val IDOfPackage, Val ProcessingResult, Val ErrorInfo) Export
	
	RequestProcessed(IDOfPackage, ProcessingResult);
	
EndProcedure

#EndRegion

#Region Private

Procedure RequestProcessed(Val IDOfPackage, Val ProcessingResult)
	
	BeginTransaction();
	
	Try
		
		Manager = SafeModeManagerInternalSaaS.PackageApplicationManager(IDOfPackage);
		
		If ProcessingResult = Enums.ExternalResourcesUsageQueriesProcessingResultsSaaS.RequestApproved Then
			Manager.CompleteApplyRequestsToUseExternalResources();
		Else
			Manager.CancelRequestsToUseExternalResources();
		EndIf;
		
		SafeModeManagerInternalSaaS.SetResultOfPacketProcessing(ProcessingResult);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

