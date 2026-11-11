
#Region Public

#Region EventHandlersSSL
// Processing of program events that occur in BSP subsystems.
// Only for calls from the BSP library to the BTS.

// Defines events that this library is subscribed to.
//
// Parameters:
//  Subscriptions - Structure - the structure property keys are the names of events that
//           this library subscribes to.
//
Procedure OnDefineEventSubscriptionsSSL(Subscriptions) Export
	
	// Core
	Subscriptions.BeforeStart = True;
	Subscriptions.OnStart = True;
	
	// UsersSessions
	Subscriptions.OnEndSessions = True;
	
	// SecurityProfiles
	Subscriptions.OnConfirmRequestsToUseExternalResources = True;
	
EndProcedure

#Region Core

// See the procedure for the general purpose of the client being undefined.Before the start of the worksystem
// Parameters:
//	Parameters - See CommonClientOverridable.BeforeStart.Parameters
Procedure BeforeStart(Parameters) Export
	
	Parameters.Modules.Add(SaaSOperationsClient);
	Parameters.Modules.Insert(0, ExportImportDataClient);
	
EndProcedure

// See the procedure for the general purpose of the client being undefined.At the beginning of the worksystem.
// Parameters:
//	Parameters - Structure:
//	 * Modules - Array - links to the modules.
Procedure OnStart(Parameters) Export
	
	Parameters.Modules.Add(ApplicationsMigrationClient);
	
EndProcedure

#EndRegion

#Region UsersSessions

// See the procedure for remote administration of the Client.The prize of the completion of the sessions.
Procedure OnEndSessions(OwnerForm, Val SessionsNumbers, StandardProcessing, Val NotificationAfterTerminateSession = Undefined) Export
	
	RemoteAdministrationCTLClient.OnEndSessions(OwnerForm, SessionsNumbers, StandardProcessing, NotificationAfterTerminateSession);
	
EndProcedure

#EndRegion

#Region SecurityProfiles

// See the procedure for working in a secure mode, the client is undetectable.Confirmation of the request for the use of external resources.
Procedure OnConfirmRequestsToUseExternalResources(Val RequestsIDs, OwnerForm, ClosingNotification1, StandardProcessing) Export

	ExternalResourcesPermissionsSetupSaaSClient.OnConfirmRequestsToUseExternalResources(
		RequestsIDs, OwnerForm, ClosingNotification1, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Internal

#Region InformationCenter

// See the Call for Online Support Customer.Processing of the announcement.
Procedure IntegrationOnlineSupportCallClientNotificationProcessing(EventName, Item) Export
	
	If CTLSubsystemsIntegrationClientCached.SubscriptionsSSL().IntegrationOnlineSupportCallClientNotificationProcessing Then
		SSLSubsystemsIntegrationClient.IntegrationOnlineSupportCallClientNotificationProcessing(EventName, Item);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Defines events that other libraries can subscribe to.
//
// Returns:
//   Structure - the keys of the structure properties are the names of events that libraries can subscribe to:
//   * IntegrationOnlineSupportCallClientNotificationProcessing - Boolean - False by default.
//
Function EventsCTL() Export
	
	Events = New Structure;
	
	// ExportImportData
	Events.Insert("IntegrationOnlineSupportCallClientNotificationProcessing", False);
	
	Return Events;
	
EndFunction

#EndRegion