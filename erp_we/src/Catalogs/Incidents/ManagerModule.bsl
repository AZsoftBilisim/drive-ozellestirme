#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public 

#Region Other

// Returns duplicate incidents
// 
// Parameters:
//  Ref - CatalogRef.Incidents - The incident being checked for duplicates.
//  IncidentsPassed - Array of CatalogRef.Incidents - The completed incidents are placed along the chain of duplicates.
// 
// Returns:
//  Array of CatalogRef.Incidents
Function IncidentDuplicates(Ref, IncidentsPassed) Export
	
	DuplicateIncidents = New Array;
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	Incidents.Ref AS Ref,
	|	FALSE AS Main
	|FROM
	|	Catalog.Incidents AS Incidents
	|WHERE
	|	Incidents.Duplicate1 = &Ref
	|	AND Incidents.DeletionMark = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	Incidents.Ref,
	|	TRUE
	|FROM
	|	Catalog.Incidents AS Incidents
	|WHERE
	|	Incidents.Ref = &Ref
	|	AND Incidents.DeletionMark = FALSE";
	
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.Main Then
			DuplicateIncidents.Add(Selection.Ref);
			IncidentsPassed.Add(Selection.Ref);
			Duplicate1 = Common.ObjectAttributeValue(Selection.Ref, "Duplicate1");
			BranchPassed = IncidentsPassed.Find(Duplicate1) <> Undefined;
			If ValueIsFilled(Duplicate1) And Not BranchPassed Then
				CommonClientServer.SupplementArray(DuplicateIncidents, IncidentDuplicates(Duplicate1, IncidentsPassed));
			EndIf;
		Else
			BranchPassed = IncidentsPassed.Find(Selection.Ref) <> Undefined;
			If Not BranchPassed Then
				IncidentsPassed.Add(Selection.Ref);
				CommonClientServer.SupplementArray(DuplicateIncidents, IncidentDuplicates(Selection.Ref, IncidentsPassed));
			EndIf;
		EndIf;
		
	EndDo;
	
	Return DuplicateIncidents;
	
EndFunction

// Restricting the selection of a new type of incident. They are used both to limit the selection list and to check for changing the view.
//
// Parameters:
//  SetOfPropertiesAndProps - CatalogRef.AdditionalAttributesAndInfoSets - A set of incident type properties
// Returns:
//   - Boolean - True
//
Function RestrictingSelectionOfNewTypeOfIncident(SetOfPropertiesAndProps) Export

	Query = New Query;
	
	Query.SetParameter("PropertiesSet", SetOfPropertiesAndProps);
	
	Query.Text =
	"SELECT
	|	AddAttributes.Property AS Property
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AddAttributes
	|WHERE
	|	AddAttributes.Ref = &PropertiesSet";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

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

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("vi = '%1 %2 ngày %3';
		|ru = '%1 %2 от %3';
		|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
		|it = '%1 %2 del %3';
		|pl = '%1 %2 z dnia %3';
		|tr = '%3 tarihli %1 %2'"),
	Data.Description,
	Data.Code,
	Data.RegistrationDate);
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Code");
	Fields.Add("Description");
	Fields.Add("RegistrationDate");
	
EndProcedure

#EndRegion