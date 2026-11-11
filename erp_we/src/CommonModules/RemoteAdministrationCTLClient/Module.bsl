////////////////////////////////////////////////////////////////////////////////
// Subsystem "Remote administration".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called when the session is terminated by the end-User subsystem.
//
// Parameters:
//  OwnerForm - ClientApplicationForm - from which the session is terminated,
//  SessionsNumbers - Number - number of the session to end,
//  StandardProcessing - Boolean - flag for performing standard session termination processing
//    (connecting to the server agent via a COM connection or the administration server
//    requesting cluster connection parameters from the current user). Can be
//    set to False inside the event handler, in which case standard
//    session termination processing will not be performed,
//  NotificationAfterTerminateSession - CallbackDescription - description of the alert that should
//    be called after the session ends (to automatically update the list of active
//    users). If the value of the standard Processing parameter is set to False,
//    after the session ends successfully, the transmitted notification description must be
//    processed using the perform message Processing method (the
//    result parameter value should be passed the return code of the Dialog.OK on successful
//    session termination). This parameter can be omitted . in this case, you should not process the notification
//    .
//
Procedure OnEndSessions(OwnerForm, Val SessionsNumbers, StandardProcessing, Val NotificationAfterTerminateSession = Undefined) Export
	
	If CommonClient.DataSeparationEnabled() Then
		
		If CommonClient.SeparatedDataUsageAvailable() Then
			
			StandardProcessing = False;
			
			FormParameters = New Structure();
			FormParameters.Insert("SessionsNumbers", SessionsNumbers);
			
			CallbackDescription = New CallbackDescription(
				"AfterSessionTermination", ThisObject, New Structure("CallbackDescription", NotificationAfterTerminateSession));
			
			OpenForm("CommonForm.SessionsTerminationSaaS",
				FormParameters,
				OwnerForm,
				SessionsNumbers,
				,
				,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Called after the session ends. Executes the original notification description from the processing form
// Active users to update the list of active users after the session ends.
//
// Parameters:
//  Result - Arbitrary - not analyzed in this procedure. Must be passed to the original alert description,
//  Context - Structure - With Fields:
//   * CallbackDescription - CallbackDescription - the original description of the alert.
//
Procedure AfterSessionTermination(Result, Context) Export
	
	If Context.CallbackDescription <> Undefined Then
		
		RunCallback(Context.CallbackDescription, Result);
		
	EndIf;
	
EndProcedure

#EndRegion

