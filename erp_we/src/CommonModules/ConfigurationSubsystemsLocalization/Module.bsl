#Region Public

// Defines a list of library modules and configurations that provide
// basic information about themselves: name, version, list of update handlers
// , as well as dependencies on other libraries.
//
// The composition of the mandatory procedures of such a module can be found in the general module Updating the information database
// (Software interface area).
// At the same time, the module of the Library of standard subsystems for
// updating the information database itself does not need to be explicitly added to the array of modules of the subsystems.
//
// Parameters:
//  SubsystemsModules - Array - the names of the server-side common modules, libraries and configuration.
//                             For example: "Obnovlenchestvo" library
//                                       "Obnovleniyami" - configuration.
//                    
Procedure OnAddSubsystems(SubsystemsModules) Export
	
	
EndProcedure

#EndRegion
