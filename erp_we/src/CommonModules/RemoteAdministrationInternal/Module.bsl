////////////////////////////////////////////////////////////////////////////////
// Subsystem "Remote administration".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Event handlers of BSP subsystems.

// Called before attempting to write the values of is parameters
// to constants of the same name.
//
// Parameters:
// ParameterValues - Structure - the values of the parameters which you want to install.
// If the parameter value is set in this procedure
// , the corresponding key Value pair must be removed from the structure.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
	
	If ParameterValues.Property("InternalServiceManagerURL") Then
		
		SaaSOperationsCTL.SetInternalAddressOfServiceManager(ParameterValues.InternalServiceManagerURL);
		ParameterValues.Delete("InternalServiceManagerURL");
		
	EndIf;
	
	If ParameterValues.Property("URLOfService") Then
		
		SaaSOperationsCTL.SetInternalAddressOfServiceManager(ParameterValues.URLOfService);
		ParameterValues.Delete("URLOfService");
		
	EndIf;
	
	Owner = Common.MetadataObjectID("Constant.InternalServiceManagerURL");
	
	If ParameterValues.Property("InternalServiceUserName") Then
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, 
			ParameterValues.InternalServiceUserName, "ServiceManagerInternalUserName");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		
		ParameterValues.Delete("InternalServiceUserName");
		
	EndIf;
	
	If ParameterValues.Property("InternalServiceUserPassword") Then
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, 
			ParameterValues.InternalServiceUserPassword, "ServiceManagerInternalUserPassword");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		
		ParameterValues.Delete("InternalServiceUserPassword");
		
	EndIf;
	
	If ParameterValues.Property("ServiceManagerInternalUserName") Then
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, 
			ParameterValues.ServiceManagerInternalUserName, "ServiceManagerInternalUserName");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		ParameterValues.Delete("ServiceManagerInternalUserName");
	EndIf;
	
	If ParameterValues.Property("ServiceManagerInternalUserPassword") Then
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, 
			ParameterValues.ServiceManagerInternalUserPassword, "ServiceManagerInternalUserPassword");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		ParameterValues.Delete("ServiceManagerInternalUserPassword");
	EndIf;
	
	If ParameterValues.Property("AuthenticationProviderURL") Then
		SaaSOperationsCTL.SetAuthenticationProviderURL(ParameterValues.AuthenticationProviderURL);
		ParameterValues.Delete("AuthenticationProviderURL");
	EndIf;
	
	If ParameterValues.Property("AccessTokenAuthenticationOfInternalAPIRequests") Then
		SaaSOperationsCTL.SetAccessTokenAuthenticationOfInternalAPIRequests(
			ParameterValues.AccessTokenAuthenticationOfInternalAPIRequests);
		ParameterValues.Delete("AccessTokenAuthenticationOfInternalAPIRequests");
	EndIf;
	
EndProcedure

// Fills the passed array with General modules that are handlers
//  for the received message interfaces.
//
// Parameters:
//  HandlersArray - Array of CommonModule - array of handlers. 
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(RemoteAdministrationMessagesInterface);
	
EndProcedure

// Fills the passed array with General modules that are handlers for the interfaces
//  of the sent messages.
//
// Parameters:
//  HandlersArray - Array of CommonModule - array of handlers.
//
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
	
	HandlersArray.Add(RemoteAdministrationControlMessagesInterface);
	HandlersArray.Add(ApplicationManagementMessagesInterface);
	
EndProcedure

#EndRegion
