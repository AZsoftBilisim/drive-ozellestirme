
#Region EventHandlers

// The event handler Obrabatyvaniya
//
Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
		If Parameters.Property("Filter") Then
		
		// We will replace the platform mechanism for forming a selection list,
		// because selection is required by the date of receipt of data on responsible persons.
		StandardProcessing = False;
		ChoiceData 		 = New ValueList;
		
		SearchString         = "";
		Parameters.Property("SearchString", SearchString);
		
		TableOfResponsiblePersons = EmployeesInChargeServerCall.GetTableOfResponsiblePersonsForSelection(Parameters.Filter, True, SearchString);
		
		For Each CurrRow In TableOfResponsiblePersons Do
			
			ListItemStructure = New Structure;
			ListItemStructure.Insert("Value", 		CurrRow.Ref);
			ListItemStructure.Insert("DeletionMark", CurrRow.DeletionMark);
			ListItemStructure.Insert("Warning"); // standard message
			
			ChoiceData.Add(ListItemStructure);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf
