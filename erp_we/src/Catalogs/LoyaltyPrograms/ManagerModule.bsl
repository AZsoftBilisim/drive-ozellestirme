#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	
	Result.Add("ConversionRateOfBonusesIntoCurrency");
	Result.Add("MaximumSharePayableByPoints");
	Result.Add("ExcludingDiscountsProvided");
	Result.Add("BonusConversionCurrency");
	Result.Add("DoNotAccruePointsWhenPayingWithBonuses");
	Result.Add("ProductSegment;UseProductSegment");
	Result.Add("PriceGroups");
	
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