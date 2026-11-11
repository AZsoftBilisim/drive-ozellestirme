#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the values of the setup option details
// 
// Parameters:
// 	SetupSettings - CatalogRef.SetupOptions
// Returns:
// 	See StructureOfSetupOptionDetails
Function SettingOptionDetailsValues(SetupSettings) Export
	
	Result = StructureOfSetupOptionDetails();
	
	If ValueIsFilled(SetupSettings) Then
		
		QueryText = "
		|SELECT
		|	SetupOptions.OperationTime      AS OperationTime,
		|	SetupOptions.UnitOfMeasure AS UnitOfMeasure
		|FROM
		|	Catalog.SetupOptions AS SetupOptions
		|WHERE
		|	SetupOptions.Ref = &SetupSettings";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("SetupSettings", SetupSettings);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		If Selection.Next() Then
			FillPropertyValues(Result, Selection);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the structure of the setup option details.
//
// Returns:
//  Structure - Contains:
//   * OperationTime - Number
//   * UnitOfMeasure - EnumRef.TimeMeasureUnits
Function StructureOfSetupOptionDetails()
	
	Result = New Structure;
	
	Result.Insert("OperationTime", 0);
	Result.Insert("UnitOfMeasure", Enums.TimeMeasureUnits.EmptyRef());
	
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

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Filter.Property("Owner")
		And Parameters.Property("WorkCenter") Then
		
		Parameters.Filter.Insert("Owner", ProductionProcessEditorClientServer.WorkCenterType(Parameters.WorkCenter));
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf