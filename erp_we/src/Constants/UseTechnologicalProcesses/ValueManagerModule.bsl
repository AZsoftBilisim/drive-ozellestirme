#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	SetName = "Catalog_TechnologicalProcesses";
	
	Query = New Query("SELECT
		|	1
		|FROM
		|	Catalog.AdditionalAttributesAndInfoSets AS AdditionalAttributesAndInfoSets
		|WHERE
		|	AdditionalAttributesAndInfoSets.Ref = &Ref");
	
	Query.SetParameter("Ref", PropertyManager.PropertiesSetByName(SetName));
	
	ResultIsEmpty = Query.Execute().IsEmpty();
	
	If ResultIsEmpty Then
		Return;
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseTechnologicalProcesses.Get();
	
	PropertyManager.SetPropertySetParameters(SetName, SetParameters);
	
EndProcedure

#EndRegion

#EndIf
