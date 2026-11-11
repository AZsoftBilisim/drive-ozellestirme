
#Region Public

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a creation command on the basis that forms creation commands based on objects.
// For the syntax of the Add Command Creation procedure, see the documentation.
//
// See GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands
//   
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	
EndProcedure


// Called to generate a list of create commands based on the create command base, once for when
// necessary, and then the result is cached using the module with repeated use of the return values.
// Here you can define base creation commands that are common to most configuration objects.
//
// See GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands
//
Procedure BeforeAddGenerationCommands(GenerationCommands, Parameters, StandardProcessing) Export
	
	
EndProcedure

Function AddCommandCreateExchangeWithBanksBasedOnEmail(GenerationCommands) Export

	
	Return Undefined;
EndFunction

#EndRegion
