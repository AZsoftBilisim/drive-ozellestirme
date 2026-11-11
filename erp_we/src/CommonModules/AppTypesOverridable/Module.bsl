
#Region Public

// Generates a table of types of configuration applications.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  AppTypes - See AppTypesServer.NewAppTypesTable.
//
Procedure OnDefineConfigurationAppTypes(AppTypes) Export
	
	
EndProcedure

// Defines additional properties of the basic application view
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  AdditionalProperties - Structure
//
Procedure OnDefineBasicAppTypeAddProperties(AdditionalProperties) Export
	
	
EndProcedure

// Returns the application view that will be installed by default 
// if, for example, it was not possible to define the application view by name or services.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  ApplicationKind - Structure - See AppTypesServer.NewAppType (returned data).
//
Procedure OnDefineDefaultAppType(ApplicationKind) Export
	
EndProcedure

// Adds procedures to the table that handle the transition from one type of application to another.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  Handlers - ValueTable:
//    * AppTypeOriginalName - String - The name of the application type that the transition is being made from.
//    * AppTypeName           - String - the name of the application type to which the transition is performed.
//    * Procedure                   - String - full name of the transition handler procedure.
//                                             It must be export.
// Note:
//  If at least one handler is missing from the previous one to the target application view, the transition will not be possible
//
Procedure OnAddHandlersUpgradeAppType(Handlers) Export
	
	
EndProcedure

// Called when installing the basic application view.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - indicates a processing error. Default = False.
//   * Message - String - processing error message.
//
Procedure OnBasicAppTypeInstalling(ProcessingResult) Export
	
EndProcedure

// Called when you cancel the installation of the basic application view.
// Canceling the installation of the basic application view occurs if the permanent application view is being installed.
// The procedure should return the data changed when installing the basic application view to its original State. 
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - indicates a processing error. Default = False.
//   * Message - String - processing error message.
//
Procedure OnCancelBasicAppTypeInstallation(ProcessingResult) Export
	
EndProcedure

// Called after installing the app view.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ApplicationKind - String - name of the application type.
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - indicates a processing error. Default = False.
//   * Message - String - processing error message.
//
Procedure AfterAppTypeInstallation(ApplicationKind, ProcessingResult) Export
	
	
EndProcedure

// Called before the procedures that handle the transition to a new type of application.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  ApplicationKind - String - The name of the application type that the transition is being made from.
//  TargetAppType - String - the name of the application type to which the transition is performed.
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - indicates a processing error. Default = False.
//   * Message - String - processing error message.
//
Procedure BeforeAppTypeUpgrade(ApplicationKind, TargetAppType, ProcessingResult) Export
	
EndProcedure

// Called after the transition to the new app view is Ended.
// @skip-warning EmptyMethod - Overridable method.
// Parameters:
//  ApplicationKind - String - the name of the application type that the transition was made from.
//  TargetAppType - String - the name of the application type to which the transition was made.
//  ProcessingResult - Structure - method processing results (returned data):
//   * Error - Boolean - indicates a processing error. Default = False.
//   * Message - String - processing error message.
//
Procedure AfterUpgradeToAppType(ApplicationKind, TargetAppType, ProcessingResult) Export
	
	
EndProcedure

// Defines the parameters for notification of an app view update.
// @skip-warning EmptyMethod - Overridable method.
// Parameters:
//  NoticeParameters - See AppTypesServer.NewFinishUpgradeNotificationSettings.
//
Procedure OnDefineNotificationParameters(NoticeParameters) Export
	
	
EndProcedure

// Defines an array of extension names for the types of applications that will be excluded from uploading
//  
// @skip-warning EmptyMethod - Overridable method.
// Parameters:
//  ExtensionNames - Array of String
//
Procedure OnDefineAppTypesExtensionNames(ExtensionNames) Export
	
	
EndProcedure

// Called when getting the name of the current application view.
// The procedure allows you to redefine the name of the current application view to the passed new name
// and continue using the application with the new name of the application view for the local version
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  NewAppTypeName - String - The name of the application view that can be set as current.
//  CurrentAppTypeName - String - the name of the current application view (returned data).
//
Procedure OnGetCurrentAppTypeName(NewAppTypeName, CurrentAppTypeName) Export
	
	
EndProcedure

#EndRegion