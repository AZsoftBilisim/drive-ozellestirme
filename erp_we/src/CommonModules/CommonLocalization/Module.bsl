#Region Public

// Defines metadata objects and individual details that are excluded from the search results for links,
// are not taken into account when exclusively deleting marked links, replacing links, and in the report on places of use.
//
// See CommonOverridable.OnAddReferenceSearchExceptions
//
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	
EndProcedure

// Determines the correspondence of the names of session parameters and handlers for their installation.
//
// The specified modules must contain the handler procedure to which the parameters are passed
//  Parameter Name - String is the name of the session parameter to be set.
//  Set Parameters - Array - names of parameters that are already set.
// 
// The following is an example of a handler procedure for copying to the specified modules.
// 
//
// See CommonOverridable.OnAddSessionParameterSettingHandlers.
//
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	
EndProcedure

// Allows you to set the values of parameters required for the client
// configuration code to work without additional server calls.
// 
// See CommonOverridable.OnAddClientParameters
//
Procedure OnAddClientParameters(Parameters) Export
	
	Return;
	
EndProcedure

// See CommonOverridable.BeforeStartApplication
Procedure BeforeStartApplication() Export
	
	
EndProcedure

// Allows you to set the values of parameters required for the client code
// to work when running the configuration (in the event handlers before the system starts Working and before the system starts Working) 
// without additional server calls. 
// 
// See CommonOverridable.OnAddClientParametersOnStart
//
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	Return;
	
EndProcedure

// Called when updating the information base to account for renaming subsystems and roles in the configuration.
//  
// See CommonOverridable.OnAddMetadataObjectsRenaming
//
Procedure OnAddMetadataObjectsRenaming(Total) Export

	Return;

EndProcedure

// Defines a list of versions of software interfaces available through the InterfaceVersion web service.
// 
// See CommonOverridable.OnDefineSupportedInterfaceVersions
//
Procedure OnDefineSupportedInterfaceVersions(SupportedVersions) Export

	Return;
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export

	
EndProcedure

//See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	
EndProcedure

// Allows you to determine the names of the printed main printed forms from other sources, for example, to get
// the name of the document that was printed using the EDI system.
//
// Parameters:
//  Objects_Accounting - AnyRef
//               - Array of DefinedType.ObjectWithDefaultPrintForms - objects for which it is necessary
//                                                                              to obtain the name of printed forms.
//  PresentationsOfDocuments - Map of KeyAndValue - Compliance of documents and titles for printing:
//               * Key     - DefinedType.ObjectWithDefaultPrintForms - link to the document.
//               * Value - String, Undefined - A Presentation for printing.
//
Procedure WhenReceivingNamesOfPrintedMainPrintingForms(Objects_Accounting, PresentationsOfDocuments) Export
	
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// See CommonOverridable.OnAddClientParametersOnStart
//
Procedure ClientParametersOnStart(Parameters) Export


EndProcedure

// See CommonOverridable.OnAddClientParameters
//
Procedure ClientRunParameters(Parameters) Export
	
	
EndProcedure

#EndRegion

#EndRegion
