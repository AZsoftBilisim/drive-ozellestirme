#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Enables / disables the use of the properties subsystem for the reference list.
//
Procedure ConfigureUseOfProperties() Export
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	BusinessStructure.UseProductionSites");
		
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Not Query.Execute().IsEmpty();
	
	PropertyManager.SetPropertySetParameters("Catalog_ProductionSites", SetParameters);
	
EndProcedure

// Returns names of blocked details for the BSP details blocking mechanism
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("Owner");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
