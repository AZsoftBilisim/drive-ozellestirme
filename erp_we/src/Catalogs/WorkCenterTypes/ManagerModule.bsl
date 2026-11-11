#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns names of blocked details for the BSP details blocking mechanism
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Department");
	Return Result;
	
EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Department");
	
	Return NotAttributesToEdit;
	
EndFunction

// Returns the maximum availability of RC types in the planning interval.
//
// Parameters:
//  WorkCenterTypes	 - Array - links to types of work centers.
// 
// Returns:
//  Map - the key is a reference to the type of RC, the value is maximum availability.
//
Function MaximumAvailabilityInSeconds(WorkCenterTypes) Export
	
	Result = New Map;
	
	Query = New Query(
		"SELECT
		|	WorkCenterTypes.Ref AS Ref,
		|	WorkCenterTypes.MaximumWorkCenterAvailability AS MaximumAvailability,
		|	WorkCenterTypes.UnitOfMeasureOfWorkCenterSchedule AS UnitOfAvailability,
		|	WorkCenterTypes.Department.PlanningInterval AS PlanningInterval
		|FROM
		|	Catalog.WorkCenterTypes AS WorkCenterTypes
		|WHERE
		|	WorkCenterTypes.Ref IN(&References)");
	
	Query.SetParameter("References", WorkCenterTypes);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
		
	While Selection.Next() Do
		
		If ValueIsFilled(Selection.MaximumAvailability) Then
			
			Enabled = ProductionPlanningClientServer.GetTimeInSeconds(
				Selection.MaximumAvailability,
				Selection.UnitOfAvailability);
				
		Else
			
			If Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
				Enabled = 3600;
			ElsIf Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Day
				Or Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
				Enabled = 86400;
			ElsIf Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
				Enabled = 604800;
			ElsIf Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
				Enabled = 2592000; // 30 days
			EndIf;
			
		EndIf;
		
		Result.Insert(Selection.Ref, Enabled);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the values of the details of the work center view
// 
// Parameters:
// 	WorkCenterType - CatalogRef.WorkCenterTypes,CatalogRef.WorkCenters
// 	SetupSettings - CatalogRef.SetupOptions
// Returns:
// 	See StructureOfWorkCenterTypeDetails
Function ValuesForWorkCenterTypeDetails(WorkCenterType, SetupSettings = Undefined) Export
	
	Result = StructureOfWorkCenterTypeDetails();
	
	If ValueIsFilled(WorkCenterType) Then
		
		QueryText = "
		|SELECT
		|	WorkCenterTypes.SetupSettingsAreUsed      AS SetupSettingsAreUsed,
		|	WorkCenterTypes.ParallelLoad             AS ParallelLoad,
		|	WorkCenterTypes.UnitOfMeasureOfLoad         AS UnitOfMeasureOfLoad,
		|	WorkCenterTypes.ImportOption                  AS ImportOption,
		|	CASE
		|		WHEN WorkCenterTypes.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|					AND WorkCenterTypes.SetupSettingsAreUsed
		|			THEN ISNULL(SetupOptions.OperationTime, 0)
		|		ELSE WorkCenterTypes.OperationTime
		|	END                                               AS OperationTime,
		|	CASE
		|		WHEN WorkCenterTypes.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|					AND WorkCenterTypes.SetupSettingsAreUsed
		|			THEN ISNULL(SetupOptions.UnitOfMeasure, VALUE(Enum.TimeMeasureUnits.EmptyRef))
		|		ELSE WorkCenterTypes.UnitOfMeasure
		|	END                                               AS UnitOfMeasure
		|
		|FROM
		|	Catalog.WorkCenterTypes AS WorkCenterTypes
		|
		|		LEFT JOIN Catalog.SetupOptions AS SetupOptions
		|		ON SetupOptions.Owner = WorkCenterTypes.Ref
		|			AND SetupOptions.Ref = &SetupSettings
		|
		|WHERE
		|	WorkCenterTypes.Ref = &WorkCenterType
		|		OR TRUE IN (
		|				SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.WorkCenters AS T
		|				WHERE
		|					T.Ref= &WorkCenterType
		|					AND T.WorkCenterType = WorkCenterTypes.Ref)
		|";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("WorkCenterType", WorkCenterType);
		Query.SetParameter("SetupSettings",    SetupSettings);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		If Selection.Next() Then
			FillPropertyValues(Result, Selection);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the structure of the details of the work center view
//
// Returns:
//  Structure - Contains:
//   * SetupSettingsAreUsed - Boolean
//   * ParallelLoad - Boolean
//   * OperationTime - Number
//   * UnitOfMeasure - EnumRef.TimeMeasureUnits
//   * ImportOption - EnumRef.WorkCenterLoadOptions
//   * UnitOfMeasureOfLoad - String
Function StructureOfWorkCenterTypeDetails()
	
	Result = New Structure;
	
	Result.Insert("SetupSettingsAreUsed", False);
	Result.Insert("ParallelLoad",        False);
	
	Result.Insert("OperationTime",                 0);
	Result.Insert("UnitOfMeasure",            Enums.TimeMeasureUnits.EmptyRef());
	
	Result.Insert("ImportOption",             Enums.WorkCenterLoadOptions.EmptyRef());
	Result.Insert("UnitOfMeasureOfLoad",    "");
	
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