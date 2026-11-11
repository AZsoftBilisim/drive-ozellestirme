#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Subsystem " Prohibition of editing object details"
//
// Returns:
//   Array - names of the object's blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("SalesOpportunityType");
	
	Return Result;
	
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

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Result = PartnersAndCounterpartiesServerCall.TypesOfSelectionDataTransactions(Parameters.SearchString);
	
	If Result <> Undefined Then
		StandardProcessing = False;
		ChoiceData = Result;
	EndIf;
	
EndProcedure

#EndRegion

