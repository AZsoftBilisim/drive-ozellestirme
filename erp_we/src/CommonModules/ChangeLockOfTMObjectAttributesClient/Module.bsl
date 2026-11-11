
#Region Public

// The function checks whether the object is used in a long operation
// 
// Parameters:
//  Form - ClientApplicationForm - A Form of checking the use of a reference in other objects.
//  IdleHandlerParameters - See TimeConsumingOperationsClient.InitIdleHandlerParameters
//  UseLocalValidationFunction - Boolean - Use the local verification function
//
Procedure CheckObjectUsage(Form, IdleHandlerParameters, UseLocalValidationFunction = False) Export
	
	ThereAreRefs = Undefined;
	Result = ChangeLockOfTMObjectAttributesServerCall.CheckObjectUsage(
		Form.Parameters.Object,
		Form.UUID,
		Form.StorageAddress,
		ThereAreRefs,
		UseLocalValidationFunction);
	
	If Not Result.Status = "Completed2" Then
		Form.JobID = Result.JobID;
		Form.StorageAddress       = Result.ResultAddress;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		CallbackOnCompletion = New CallbackDescription("CheckUsageOfNotificationObject", ThisObject, Form);
	
		TimeConsumingOperationsClient.WaitCompletion(
			Result, CallbackOnCompletion, IdleParameters);
	Else
		ChangeLockOfTMObjectAttributesClientServer.GetVerificationResult(Form, ThereAreRefs);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckUsageOfNotificationObject(Result, AdditionalParameters) Export
		
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ChangeLockOfTMObjectAttributesClientServer.GetVerificationResult(AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion