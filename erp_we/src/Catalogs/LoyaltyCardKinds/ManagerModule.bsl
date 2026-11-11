#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed.
//
// Returns:
//  Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("ValidityStartDate");
	Result.Add("ValidityEndDate; SetDateInterval");
	Result.Add("Personalized; PersonalizationType");
	Result.Add("AllowAutoRegistrationAtFirstReading; ActivationProcedure");
	Result.Add("CardType");
	Result.Add("TemplatesOfLoyaltyCardCodes");
	Result.Add("LoyaltyProgram");
	
	Return Result;

EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
// Returns:
//  Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("ValidityStartDate");
	NotAttributesToEdit.Add("ValidityEndDate");
	NotAttributesToEdit.Add("Personalized");
	NotAttributesToEdit.Add("AllowAutoRegistrationAtFirstReading");
	NotAttributesToEdit.Add("CardType");
	
	Return NotAttributesToEdit;
	
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
		
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#EndIf