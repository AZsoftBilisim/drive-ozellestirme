#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the name of the distribution database SCD. SKD is located in the layouts of this object.
// Parameters:
//	AllocationBase - EnumRef.AllocationDirectionByBusinessUnits - distribution base.
// Returns:
//	String - the name of the SKD.
Function NameOfDistributionBaseSchema(AllocationBase) Export
	
	Return "AllocationDirection";
	
EndFunction

#EndRegion

#EndIf
