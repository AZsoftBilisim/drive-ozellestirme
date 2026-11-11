#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning


// Gets the object's details that need to be blocked from being changed
//
// Returns:
//	Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("PaymentMethod");
	Result.Add("Calendar");
	Result.Add("Stages");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf