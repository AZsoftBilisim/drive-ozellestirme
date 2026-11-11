////////////////////////////////////////////////////////////////////////////////
// Subsystem "Basic functionality in the service model".
// General-purpose server procedures and functions:
// - Support for security profiles.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Called when confirming requests to use external resources.
//
// Parameters:
//  RequestsIDs - Array of UUID - the IDs of the queries that you want to apply,
//  OwnerForm - ClientApplicationForm - a form that should be blocked until permissions are applied,
//  ClosingNotification1 - CallbackDescription - which will be called when permissions are granted successfully.
//  StandardProcessing - Boolean - flag for performing standard processing for applying permissions to use
//    external resources (connecting to the server agent via a COM connection or the administration server
//    requesting cluster connection parameters from the current user). Can be set to False
//    inside the event handler, in this case, standard treatment is complete, the session will not be executed.
//
Procedure OnConfirmRequestsToUseExternalResources(Val RequestsIDs, OwnerForm, ClosingNotification1, StandardProcessing) Export
	
	If CommonClient.DataSeparationEnabled() Then
		
		StartInitializingRequestForPermissionsToUseExternalResources(RequestsIDs, OwnerForm, ClosingNotification1, False);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

Procedure StartInitializingRequestForPermissionsToUseExternalResources(Val IDs, OwnerForm, ClosingNotification1, CheckMode = False) Export
	
	If SafeModeManagerClient.DisplayPermissionSetupAssistant() Then
		
		ProcessingResult = ExternalResourcesPermissionsSetupSaaSServerCall.ProcessRequestsToUseExternalResources(
			IDs);
		
		If ProcessingResult.PermissionApplicationRequired Then
			
			If CommonClient.SeparatedDataUsageAvailable() Then
				
				FormName = "DataProcessor.ExternalResourcesPermissionsSetupSaaS.Form.RequestPermissionsFromSubscriberAdministrator";
				
			Else
				
				FormName = "DataProcessor.ExternalResourcesPermissionsSetupSaaS.Form.RequestPermissionsFromServiceAdministrator";
				
			EndIf;
			
			FormParameters = New Structure();
			FormParameters.Insert("IDOfPackage", IDs);
			
			CallbackDescription = New CallbackDescription(
				"AfterSetUpPermissionsToUseExternalResources",
				ExternalResourcesPermissionsSetupSaaSClient,
				FormParameters);
			
			OpenForm(
				FormName,
				FormParameters,
				OwnerForm,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(ClosingNotification1);
			
		EndIf;
		
	Else
		
		CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(ClosingNotification1);
		
	EndIf;
	
EndProcedure

Procedure AfterSetUpPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK Then
		
		CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.CallbackDescription);
		
	Else
		
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.CallbackDescription);
		
	EndIf;
	
EndProcedure

// Synchronously (with respect to the code from which the wizard was called) processes the notification description
// that was originally passed from the form for which the wizard was opened in pseudo-modal mode.
//
// Parameters:
//  ReturnCode - DialogReturnCode - 
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesSynchronously(Val ReturnCode) Export
	
	NameOfAlert = "CloudTechnology.NotificationOnApplyExternalResourceRequest";
	ClosingNotification1 = ApplicationParameters[NameOfAlert];
	ApplicationParameters[NameOfAlert] = Undefined;
	If ClosingNotification1 <> Undefined Then
		RunCallback(ClosingNotification1, ReturnCode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Asynchronously (in relation to the code from which the wizard was called), it processes the notification description
// that was originally passed from the form for which the wizard was opened in pseudo-modal mode,
// returning the OK return code.
//
// Parameters:
//  CallbackDescription - CallbackDescription - which was passed from the calling code.
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(Val CallbackDescription)
	
	ParameterName = "CloudTechnology.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = CallbackDescription;
	AttachIdleHandler("FinishConfiguringPermissionsToUseExternalResourcesInServiceModel", 0.1, True);
	
EndProcedure

// Asynchronously (in relation to the code from which the wizard was called), it processes the notification description
// that was originally passed from the form for which the wizard was opened in pseudo-modal mode,
// returning the Cancel return code.
//
// Parameters:
//  CallbackDescription - CallbackDescription - which was passed from the calling code.
//
Procedure CancelSetUpPermissionsToUseExternalResourcesAsynchronously(Val CallbackDescription)
	
	ParameterName = "CloudTechnology.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = CallbackDescription;
	AttachIdleHandler("AbortSettingPermissionsToUseExternalResourcesInServiceModel", 0.1, True);
	
EndProcedure

#EndRegion