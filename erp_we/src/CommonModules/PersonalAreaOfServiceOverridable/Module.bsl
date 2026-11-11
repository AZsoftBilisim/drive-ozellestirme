
#Region Public

// Defines the parameters of the service's merchant profile.
// Explicit parameter definition is required when embedding the BTS.
//
// Parameters:
//  Parameters - Structure:
//   * Use - Boolean - Determines whether the personal account of the service is used in the application configuration.
//   * DisplayInSectionPanel - Boolean - Controls the display of the service
//    's merchant profile in the application configuration section panel.
// @skip-check module-empty-method - Overridable method.
Procedure OnDefiningParameters(Parameters) Export
	
	Parameters.Use = True;
	Parameters.DisplayInSectionPanel = True;
	
EndProcedure

// Allows you to disable the use of the service's merchant profile for the current application.
// On changes to data that affects the override result, call
// Personal service cubicle.Renewing the use of your personal cabinet
//
// Parameters:
//  Used - Boolean
//
// @skip-check module-empty-method - Overridable method.
Procedure OnEnabled(Used) Export
EndProcedure

#EndRegion
