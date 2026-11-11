////////////////////////////////////////////////////////////////////////////////
// Subsystem "Quality Control Center".
//
////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

// The procedure complements the list of incident types and lists of types
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  TypesList	 - Map of KeyAndValue:
//	 * Key - String - with the type name,
//	 * Value - Structure:
//		** IncidentLevel - String
//		** Subsystem - String
//		** Tags - String
//		** CheckProcedure - String
// Example: 
//	Here it is necessary to define the applied types of incidents and methods for checking their relevance. 
//	For details, see:
// 	Description = Incident Server.Create a description of the type of incident ("Stop the exchange queue");
// 	Incident CCSERVER.Create a Type record (List of types, Description);
//
Procedure ListOfIncidentTypesRedefined(TypesList) Export
EndProcedure

// In the procedure, you can call all application checks related to periodic monitoring of the application configuration.
// The procedure is called using the routine monitoring procedure of the CCCC once a minute if the constant ADDRESSCCC is filled in.
// @skip-warning EmptyMethod - Overridable method.
//
Procedure ExecuteQCCMonitoringTasks() Export
EndProcedure

#EndRegion

