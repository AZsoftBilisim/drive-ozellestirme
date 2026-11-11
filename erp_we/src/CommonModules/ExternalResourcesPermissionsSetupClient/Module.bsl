///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParametersOnStart.DisplayPermissionSetupAssistant Then
		
		If ClientParametersOnStart.CheckExternalResourceUsagePermissionsApplication Then
			
			AfterCheckApplicabilityOfPermissionsToUseExternalResources(
				ClientParametersOnStart.PermissionsToUseExternalResourcesApplicabilityCheck);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// The logic of switching between the operations of the external resource permission wizard.
// 
//

// Starts external resource permissions setup wizard.
//
// Operation result is form opening
// "DataProcessor.ExternalResourcePermissionSetup.Form.PermissionsRequestInitialization", for which a procedure is set
// as closing notification details
// DataProcessorAfterInitializeRequestForPermissionsToUseExternalResources.
//
// Parameters:
//  IDs - Array of UUID - IDs (UUID) of requests to use external resources,
//                  for which the wizard is called.
//  OwnerForm - ClientApplicationForm
//                - Undefined - a form, for which the wizard is opened.
//  ClosingNotification1 - CallbackDescription, Undefined - details of a notification that must be
//                        processed after closing the wizard.
//  EnablingMode - Boolean - indicates that the wizard is called upon enabling usage for the security profile
//                            infobase.
//  DisablingMode - Boolean - indicates that the wizard is called upon disabling usage for the security profile
//                             infobase.
//  RecoveryMode - Boolean - indicates that the wizard is called to restore settings of security profiles in
//                                 the server cluster (according to the current infobase data).
//
Procedure StartInitializingRequestForPermissionsToUseExternalResources(
		Val IDs,
		Val OwnerForm,
		Val ClosingNotification1,
		Val EnablingMode = False,
		Val DisablingMode = False,
		Val RecoveryMode = False) Export
	
	If EnablingMode Or SafeModeManagerClient.DisplayPermissionSetupAssistant() Then
		
		State = RequestForPermissionsToUseExternalResourcesState();
		State.RequestsIDs = IDs;
		State.CallbackDescription = ClosingNotification1;
		State.OwnerForm = OwnerForm;
		State.EnablingMode = EnablingMode;
		State.DisablingMode = DisablingMode;
		State.RecoveryMode = RecoveryMode;
		
		FormParameters = New Structure();
		FormParameters.Insert("IDs", IDs);
		FormParameters.Insert("EnablingMode", State.EnablingMode);
		FormParameters.Insert("DisablingMode", State.DisablingMode);
		FormParameters.Insert("RecoveryMode", State.RecoveryMode);
		
		CallbackDescription = New CallbackDescription(
			"AfterInitializeRequestForPermissionsToUseExternalResources",
			ExternalResourcesPermissionsSetupClient,
			State);
		
		OpenForm(
			"DataProcessor.ExternalResourcesPermissionsSetup.Form.PermissionsRequestInitialization",
			FormParameters,
			OwnerForm,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
		
	EndIf;
	
EndProcedure

// Starts the security profile permission setup dialog.
// Operation result is form opening:
// "DataProcessor.ExternalResourcePermissionSetup.Form.ExternalResourcePermissionSetup", 
// for which a procedure is set as closing notification details
// AfterSetUpPermissionsToUseExternalResources or abnormal wizard termination.
//
// Parameters:
//  Result - DialogReturnCode - a result of executing a previous operation of
//                                   external resource permissions application wizard (used values are OK and Cancel),
//  State - See RequestForPermissionsToUseExternalResourcesState
//
//
Procedure AfterInitializeRequestForPermissionsToUseExternalResources(Result, State) Export
	
	If TypeOf(Result) = Type("Structure") And Result.ReturnCode = DialogReturnCode.OK Then
		
		InitializationState = GetFromTempStorage(Result.StateStorageAddress);
		
		If InitializationState.PermissionApplicationRequired Then
			
			State.StorageAddress = InitializationState.StorageAddress;
			
			FormParameters = New Structure();
			FormParameters.Insert("StorageAddress", State.StorageAddress);
			FormParameters.Insert("RecoveryMode", State.RecoveryMode);
			FormParameters.Insert("CheckMode", State.CheckMode);
			
			CallbackDescription = New CallbackDescription(
				"AfterSetUpPermissionsToUseExternalResources",
				ExternalResourcesPermissionsSetupClient,
				State);
			
			OpenForm(
				"DataProcessor.ExternalResourcesPermissionsSetup.Form.ExternalResourcesPermissionsSetup",
				FormParameters,
				State.OwnerForm,
				,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			
			// The requested permissions are excessive. Do not change security profiles on the cluster.
			// 
			CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.CallbackDescription);
			
		EndIf;
		
	Else
		
		ExternalResourcesPermissionsSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestsIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.CallbackDescription);
		
	EndIf;
	
EndProcedure

// Starts the dialog of waiting for server cluster security profile settings to be applied.
// Operation result is form opening:
// "DataProcessor.ExternalResourcePermissionSetup.PermissionsRequestEnd", for which a procedure is set
// as a closing notification details
// AfterCompleteRequestForPermissionsToUseExternalResources or abnormal wizard termination.
//
// Parameters:
//  Result - DialogReturnCode - a result of executing a previous operation of
//                                   external resource permissions application wizard (used values are OK, Skip, and Cancel).
//                                   Ignore value is used if no changes were made to the
//                                   security profile settings but requests to use external resources
//                                   must be considered applied (for example, if permissions to use
//                                   all external resources being requested have already been granted),
//  State - See RequestForPermissionsToUseExternalResourcesState
//
Procedure AfterSetUpPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK Or Result = DialogReturnCode.Ignore Then
		
		PlanPermissionApplyingCheckAfterOwnerFormClose(
			State.OwnerForm,
			State.RequestsIDs);
		
		FormParameters = New Structure();
		FormParameters.Insert("StorageAddress", State.StorageAddress);
		FormParameters.Insert("RecoveryMode", State.RecoveryMode);
		
		If Result = DialogReturnCode.OK Then
			FormParameters.Insert("Duration", ChangeApplyingTimeout());
		Else
			FormParameters.Insert("Duration", 0);
		EndIf;
		
		CallbackDescription = New CallbackDescription(
			"AfterCompleteRequestForPermissionsToUseExternalResources",
			ExternalResourcesPermissionsSetupClient,
			State);
		
		OpenForm(
			"DataProcessor.ExternalResourcesPermissionsSetup.Form.PermissionsRequestEnd",
			FormParameters,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	Else
		
		ExternalResourcesPermissionsSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestsIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.CallbackDescription);
		
	EndIf;
	
EndProcedure

// Processes the data entered to the external resource permission application wizard.
// The operation result is processing of the notification description, which was initially passed from the form for which
// the wizard was opened.
//
// Parameters:
//  Result - DialogReturnCode - a result of executing a previous operation of
//                                   external resource permissions application wizard (used values are OK and Cancel),
//  State - See RequestForPermissionsToUseExternalResourcesState.
//
Procedure AfterCompleteRequestForPermissionsToUseExternalResources(Result, State) Export
	
	If Result = DialogReturnCode.OK Then
		
		ShowUserNotification(NStr("vi = 'Tùy chỉnh cho phép';
									|ru = 'Настройка разрешений';
									|en = 'Permission settings'; fa = 'Permission settings';
									|it = 'Configurare le autorizzazioni';
									|pl = 'Ustawienia zezwoleń';
									|tr = 'İzin ayarları'"),,
			NStr("vi = 'Thay đổi trong tùy chỉnh trương mục bảo mật trong cụm Server.';
				|ru = 'Внесены изменения в настройки профилей безопасности в кластере серверов.';
				|en = 'Security profile settings are changed in the server cluster.'; fa = 'Security profile settings are changed in the server cluster.';
				|it = 'Sono state apportate modifiche alle impostazioni dei profili di sicurezza in un cluster di server.';
				|pl = 'Są wprowadzone zmiany w ustawieniach profili bezpieczeństwa w klastrze serwerów.';
				|tr = 'Sunucu kümesinin güvenlik profili ayarlarını değiştirin.'"));
		
		CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(State.CallbackDescription);
		
	Else
		
		ExternalResourcesPermissionsSetupServerCall.CancelApplyRequestsToUseExternalResources(
			State.RequestsIDs);
		CancelSetUpPermissionsToUseExternalResourcesAsynchronously(State.CallbackDescription);
		
	EndIf;
	
EndProcedure

// Asynchronously (relative to the code, from which the wizard was called) processes the notification details
// that were initially passed from the form, for which the wizard was opened returning the return code OK.
//
// Parameters:
//  CallbackDescription - CallbackDescription - Description passed from the calling code.
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesAsynchronously(Val CallbackDescription)
	
	ParameterName = "StandardSubsystems.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = CallbackDescription;
	
	AttachIdleHandler("FinishExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Asynchronously (relative to the code, from which the wizard was called) processes the notification details
// that were initially passed from the form, for which the wizard was opened returning the return code Cancel.
//
// Parameters:
//  CallbackDescription - CallbackDescription - Description passed from the calling code.
//
Procedure CancelSetUpPermissionsToUseExternalResourcesAsynchronously(Val CallbackDescription)
	
	ParameterName = "StandardSubsystems.NotificationOnApplyExternalResourceRequest";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters[ParameterName] = CallbackDescription;
	
	AttachIdleHandler("CancelExternalResourcePermissionSetup", 0.1, True);
	
EndProcedure

// Synchronously (relative to the code, from which the wizard was called) processes the notification details
// that were initially passed from the form, for which the wizard was opened.
//
// Parameters:
//  ReturnCode - DialogReturnCode
//
Procedure CompleteSetUpPermissionsToUseExternalResourcesSynchronously(Val ReturnCode) Export
	
	ClosingNotification1 = ApplicationParameters["StandardSubsystems.NotificationOnApplyExternalResourceRequest"];
	ApplicationParameters["StandardSubsystems.NotificationOnApplyExternalResourceRequest"] = Undefined;
	If ClosingNotification1 <> Undefined Then
		RunCallback(ClosingNotification1, ReturnCode);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// The logic of the external resource permission wizard that checks for the
// completion of the operations where such permissions were requested.
// 
//

// Starts the wizard in operation completion check mode. In this mode, the wizard checks whether the operation whence requests for
// permissions to use external resources were applied is completed.
//
// The result of the procedure is a startup of the
// external resource permissions setup wizard in operation completion check mode.
// Once the wizard is closed, the
// PermissionApplyingAfterCheckAfterOwnerFormClose() procedure
// is used for processing the notification description.
//
// Parameters:
//  Result - Arbitrary - a result of closing the form, for which 
//                             external resource permissions setup wizard was opened. Does not used in the procedure body, the parameter is required
//                             for defining a form closing notification description procedure.
//  State - See PermissionsApplicabilityCheckStateAfterCloseOwnerForm.
//
Procedure CheckPermissionsAppliedAfterOwnerFormClose(Result, State) Export
	
	OriginalOnCloseNotifyDescription = State.CallbackDescription;
	If OriginalOnCloseNotifyDescription <> Undefined Then
		RunCallback(OriginalOnCloseNotifyDescription, Result);
	EndIf;
	
	Validation = ExternalResourcesPermissionsSetupServerCall.CheckApplyPermissionsToUseExternalResources();
	AfterCheckApplicabilityOfPermissionsToUseExternalResources(Validation);
	
EndProcedure

// Checks whether requests to use external resources were applied.
//
// Parameters:
//  Validation - See ExternalResourcesPermissionsSetupServerCall.CheckApplyPermissionsToUseExternalResources.
//
Procedure AfterCheckApplicabilityOfPermissionsToUseExternalResources(Val Validation)
	
	If Not Validation.CheckResult Then
		
		ApplyingState = RequestForPermissionsToUseExternalResourcesState();
		
		ApplyingState.RequestsIDs = Validation.RequestsIDs;
		ApplyingState.StorageAddress = Validation.StateTemporaryStorageAddress;
		ApplyingState.CheckMode = True;
		
		Result = New Structure();
		Result.Insert("ReturnCode", DialogReturnCode.OK);
		Result.Insert("StateStorageAddress", Validation.StateTemporaryStorageAddress);
		
		AfterInitializeRequestForPermissionsToUseExternalResources(
			Result, ApplyingState);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Invoke the external resource permission wizard in special modes.
// 
//

// Calls the external resource permissions setup wizard in infobase security profile enabling
// mode.
//
// Parameters:
//  OwnerForm - ClientApplicationForm - Form that must be locked before permissions are applied.
//  ClosingNotification1 - CallbackDescription - it will be called once permissions are granted.
//
Procedure StartEnablingSecurityProfilesUsage(OwnerForm, ClosingNotification1 = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification1, True, False, False);
	
EndProcedure

// Calls the external resource permissions setup wizard in infobase security profile disabling
// mode.
//
// Parameters:
//  OwnerForm - ClientApplicationForm - Form that must be locked before permissions are applied.
//  ClosingNotification1 - CallbackDescription - it will be called once permissions are granted.
//
Procedure StartDisablingSecurityProfilesUsage(OwnerForm, ClosingNotification1 = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification1, False, True, False);
	
EndProcedure

// Calls the external resource permissions setup wizard in server cluster security profile settings recovery
// mode based on the current
// infobase state.
//
// Parameters:
//  OwnerForm - ClientApplicationForm - Form that must be locked before permissions are applied.
//  ClosingNotification1 - CallbackDescription - it will be called once permissions are granted.
//
Procedure StartRestoringSecurityProfiles(OwnerForm, ClosingNotification1 = Undefined) Export
	
	StartInitializingRequestForPermissionsToUseExternalResources(
		New Array(), OwnerForm, ClosingNotification1, False, False, True);
	
EndProcedure

// Creates a structure used for storing the
// external resource permissions setup wizard state.
//
// Returns: 
//   Structure - for field details, see the function body.
//
Function RequestForPermissionsToUseExternalResourcesState()
	
	Result = New Structure();
	
	// IDs of requests to use external resources to be provided.
	Result.Insert("RequestsIDs", New Array());
	
	// The original details of the notification that is triggered after the permission request is confirmed.
	// 
	Result.Insert("CallbackDescription", Undefined);
	
	// Address in a temporary storage for storing data passed between forms.
	Result.Insert("StorageAddress", "");
	
	// The form where the request to use external resources was initialized.
	// 
	Result.Insert("OwnerForm");
	
	// Enabling mode - indicates whether security profiles are being enabled.
	Result.Insert("EnablingMode", False);
	
	// Disabling mode - indicates whether security profiles are being disabled.
	Result.Insert("DisablingMode", False);
	
	// In restoration mode, permissions are requested "from scratch"
	// (ignoring the information on the previously granted permissions).
	// 
	Result.Insert("RecoveryMode", False);
	
	// The check mode: indicates the completion of the operation that granted new permissions in security profiles.
	// For example, when saving a new catalog item, permissions are granted but the writing is not completed.
	// 
	Result.Insert("CheckMode", False);
	
	Return Result;
	
EndFunction

// Creates a structure used for storing a state of check for completion
// of the operation where the requests for permissions to use external resources were applied.
//
// Returns: 
//   Structure - for field details, see the function body.
//
Function PermissionsApplicabilityCheckStateAfterCloseOwnerForm()
	
	Result = New Structure();
	
	// Address in a temporary storage for storing data passed between forms.
	Result.Insert("StorageAddress", Undefined);
	
	// The original details of the form notification that triggers when permission applicability is checked.
	// 
	Result.Insert("CallbackDescription", Undefined);
	
	Return Result;
	
EndFunction

// Returns the duration of waiting for changes
// in server cluster security profile settings to be applied.
//
// Returns:
//   Number - duration of waiting for changes to be applied (in seconds).
//
Function ChangeApplyingTimeout()
	
	Return 20; // Interval that rphost uses to update the current security profile settings from rmngr.
	
EndFunction

// Plans (by substituting a value to OnCloseNotifyDescription form property) a wizard call
// to check whether the action is complete when the form that called the master is closed.
//
// As a result, the
// PermissionsApplicabilityCheckAfterOwnerFormClose procedure is called after closing the form, for which 
// external resource permissions setup wizard was opened.
//
// Parameters:
//  OwnerForm - ClientApplicationForm, Undefined - when this form is closed, the procedure will
//    check completion of operations that included requests for permissions to use
//    external resources.
//  RequestsIDs - Array of UUID - IDs (UUID) of requests for permissions to
//    use external resources applied within the operation, the completion of which is being checked.
//
Procedure PlanPermissionApplyingCheckAfterOwnerFormClose(FormOwner, RequestsIDs)
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		
		InitialNotifyDescription = FormOwner.CallbackDescriptionOnClose;
		If InitialNotifyDescription <> Undefined Then
			
			If InitialNotifyDescription.Module = ExternalResourcesPermissionsSetupClient
					And InitialNotifyDescription.ProcedureName = "CheckPermissionsAppliedAfterOwnerFormClose" Then
				Return;
			EndIf;
			
		EndIf;
		
		State = PermissionsApplicabilityCheckStateAfterCloseOwnerForm();
		State.CallbackDescription = InitialNotifyDescription;
		
		PermissionsApplicabilityCheckNotifyDescription = New CallbackDescription(
			"CheckPermissionsAppliedAfterOwnerFormClose",
			ExternalResourcesPermissionsSetupClient,
			State);
		
		FormOwner.CallbackDescriptionOnClose = PermissionsApplicabilityCheckNotifyDescription;
		
	EndIf;
	
EndProcedure

#EndRegion