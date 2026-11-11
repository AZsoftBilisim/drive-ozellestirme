#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
	Return;
EndProcedure

// End StandardSubsystems.ObjectsVersioning


// The function defines the default distribution method.
//
// Returns the distribution method if one distribution method is found.
// Returns an empty link if the distribution method was not found or more than one method was found.
//
// Parameters:
//  AllocatedAccordingToRule - EnumRef.AllocationRulesByLinesOfBusiness - The distribution rule.
//
// Returns:
//	CatalogRef.AllocationMethodsByLinesOfBusiness - The found distribution method.
//
Function DefaultDistributionMethod(AllocatedAccordingToRule) Export
	
	Query = New Query("
	|SELECT
	|	MAX(DistributionMethods.Ref) AS LineOfBusinessAllocationMethod,
	|	COUNT(DistributionMethods.Ref)
	|FROM
	|	Catalog.AllocationMethodsByLinesOfBusiness AS DistributionMethods
	|WHERE
	|	NOT DistributionMethods.DeletionMark
	|	AND (DistributionMethods.AllocatedAccordingToRule = &AllocatedAccordingToRule
	|		OR &AllocatedAccordingToRule = UNDEFINED)
	|
	|HAVING
	|	COUNT(DistributionMethods.Ref) = 1
	|");
	
	Query.SetParameter("AllocatedAccordingToRule", AllocatedAccordingToRule);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		LineOfBusinessAllocationMethod = Selection.LineOfBusinessAllocationMethod;
	Else
		LineOfBusinessAllocationMethod = Catalogs.AllocationMethodsByLinesOfBusiness.EmptyRef();
	EndIf;
	
	Return LineOfBusinessAllocationMethod;

EndFunction

#EndRegion

#EndIf