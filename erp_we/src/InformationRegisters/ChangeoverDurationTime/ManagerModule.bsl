#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the duration of changeover when switching from one type of setup to another.
//
//	Parameters:
//		WorkCenterType			- CatalogRef.WorkCenterTypes - View of the work center for which the changeover time is set
//		CurrentSetupSettings		- CatalogRef.SetupOptions - The setup option that the transition is being made from
//		NextSetupSettings		- CatalogRef.SetupOptions - The setup option that you are switching to
//		ChangeoverTime			- Number - Changeover time from one setup option to another.
//
Procedure SetChangeoverDuration(WorkCenterType, Val CurrentSetupSettings = Undefined, Val NextSetupSettings = Undefined, ChangeoverTime) Export
	
	If CurrentSetupSettings = Undefined Then
		CurrentSetupSettings = Catalogs.SetupOptions.EmptyRef();
	EndIf; 
	If NextSetupSettings = Undefined Then
		NextSetupSettings = Catalogs.SetupOptions.EmptyRef();
	EndIf; 
	
	RecordManager = InformationRegisters.ChangeoverDurationTime.CreateRecordManager();
	RecordManager.WorkCenterType       = WorkCenterType;
	RecordManager.CurrentSetupSettings   = CurrentSetupSettings;
	RecordManager.NextSetupSettings = NextSetupSettings;
	If ChangeoverTime <> 0 Then
		RecordManager.ChangeoverTime = ChangeoverTime;
		
		RecordManager.Write();
	Else
		RecordManager.Delete();
	EndIf; 
	
EndProcedure

// Returns the setup for readjusting all options for setting up the work center view.
//
// Parameters:
//   WorkCenterType - CatalogRef.WorkCenterTypes - View of the work center for which the changeover time is determined.
//
// Returns:
//   ValueTable - changeover duration:
//     * CurrentSetupSettings - CatalogRef.SetupOptions - the option from which the transition is performed.
//     * NextSetupSettings - CatalogRef.SetupOptions - the option that you are switching to.
//     * ChangeoverTime - Number - the duration of the changeover.
//     * ChangeoverTimeUnit - EnumRef.TimeMeasureUnits - the unit of time.
//     * SettingIsInherited - Boolean - True if the configuration is inherited due to an incomplete match of the setup options.
//     * Priority - Number - priority of using the setting.
//
Function SettingUpChangeover(WorkCenterType) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	SetupOptions.Ref AS Ref
	|INTO SetupOptions
	|FROM
	|	Catalog.SetupOptions AS SetupOptions
	|WHERE
	|	SetupOptions.Owner = &WorkCenterType
	|	AND NOT SetupOptions.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.SetupOptions.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatCurrentSetupSettings.Ref AS CurrentSetupSettings,
	|	CatNextSetupSettings.Ref AS NextSetupSettings,
	|	CASE
	|		WHEN CatCurrentSetupSettings.Ref = VALUE(Catalog.SetupOptions.EmptyRef)
	|				AND CatNextSetupSettings.Ref = VALUE(Catalog.SetupOptions.EmptyRef)
	|			THEN 1
	|		WHEN CatCurrentSetupSettings.Ref <> VALUE(Catalog.SetupOptions.EmptyRef)
	|				AND CatNextSetupSettings.Ref = VALUE(Catalog.SetupOptions.EmptyRef)
	|				AND ChangeoverTimeWorkCenter1.ChangeoverTime IS NULL
	|			THEN 4
	|		WHEN CatCurrentSetupSettings.Ref = VALUE(Catalog.SetupOptions.EmptyRef)
	|				AND CatNextSetupSettings.Ref <> VALUE(Catalog.SetupOptions.EmptyRef)
	|				AND ChangeoverTimeWorkCenter1.ChangeoverTime IS NULL
	|			THEN 4
	|		WHEN NOT ChangeoverTimeWorkCenter1.ChangeoverTime IS NULL
	|			THEN 1
	|		WHEN NOT ChangeoverTimeWorkCenter2.ChangeoverTime IS NULL
	|			THEN 2
	|		WHEN NOT ChangeoverTimeWorkCenter3.ChangeoverTime IS NULL
	|			THEN 3
	|		ELSE 4
	|	END AS Priority,
	|	CASE
	|		WHEN ISNULL(ChangeoverTimeWorkCenter1.CurrentSetupSettings,
	|				ISNULL(ChangeoverTimeWorkCenter2.CurrentSetupSettings,
	|				ISNULL(ChangeoverTimeWorkCenter3.CurrentSetupSettings,
	|				ISNULL(ChangeoverTimeWorkCenter4.CurrentSetupSettings, VALUE(Catalog.SetupOptions.EmptyRef))))) = CatCurrentSetupSettings.Ref 
	|			AND ISNULL(ChangeoverTimeWorkCenter1.NextSetupSettings,
	|				ISNULL(ChangeoverTimeWorkCenter2.NextSetupSettings,
	|				ISNULL(ChangeoverTimeWorkCenter3.NextSetupSettings,
	|				ISNULL(ChangeoverTimeWorkCenter4.NextSetupSettings, VALUE(Catalog.SetupOptions.EmptyRef))))) = CatNextSetupSettings.Ref
	|			THEN FALSE 
	|		ELSE TRUE
	|	END AS SettingIsInherited,
	|	ISNULL(ChangeoverTimeWorkCenter1.ChangeoverTime,
	|		ISNULL(ChangeoverTimeWorkCenter2.ChangeoverTime,
	|		ISNULL(ChangeoverTimeWorkCenter3.ChangeoverTime,
	|		ISNULL(ChangeoverTimeWorkCenter4.ChangeoverTime, 0)))) AS ChangeoverTime,
	|
	|	CatWorkCenterTypes.ChangeoverTimeUnit AS ChangeoverTimeUnit
	|FROM
	|	SetupOptions AS CatCurrentSetupSettings
	|		LEFT JOIN SetupOptions AS CatNextSetupSettings
	|		ON (CatNextSetupSettings.Ref = VALUE(Catalog.SetupOptions.EmptyRef)
	|				OR CatNextSetupSettings.Ref <> CatCurrentSetupSettings.Ref)
	|		LEFT JOIN Catalog.WorkCenterTypes AS CatWorkCenterTypes
	|		ON CatWorkCenterTypes.Ref = &WorkCenterType
	
	|		LEFT JOIN InformationRegister.ChangeoverDurationTime AS ChangeoverTimeWorkCenter1
	|		ON (ChangeoverTimeWorkCenter1.WorkCenterType = &WorkCenterType)
	|			AND (ChangeoverTimeWorkCenter1.CurrentSetupSettings = CatCurrentSetupSettings.Ref)
	|			AND (ChangeoverTimeWorkCenter1.NextSetupSettings = CatNextSetupSettings.Ref)
	
	|		LEFT JOIN InformationRegister.ChangeoverDurationTime AS ChangeoverTimeWorkCenter2
	|		ON (ChangeoverTimeWorkCenter2.WorkCenterType = &WorkCenterType)
	|			AND (ChangeoverTimeWorkCenter2.CurrentSetupSettings = VALUE(Catalog.SetupOptions.EmptyRef))
	|			AND (ChangeoverTimeWorkCenter2.NextSetupSettings = CatNextSetupSettings.Ref)
	
	|		LEFT JOIN InformationRegister.ChangeoverDurationTime AS ChangeoverTimeWorkCenter3
	|		ON (ChangeoverTimeWorkCenter3.WorkCenterType = &WorkCenterType)
	|			AND (ChangeoverTimeWorkCenter3.CurrentSetupSettings = CatCurrentSetupSettings.Ref)
	|			AND (ChangeoverTimeWorkCenter3.NextSetupSettings = VALUE(Catalog.SetupOptions.EmptyRef))
	
	|		LEFT JOIN InformationRegister.ChangeoverDurationTime AS ChangeoverTimeWorkCenter4
	|		ON (ChangeoverTimeWorkCenter4.WorkCenterType = &WorkCenterType)
	|			AND (ChangeoverTimeWorkCenter4.CurrentSetupSettings = VALUE(Catalog.SetupOptions.EmptyRef))
	|			AND (ChangeoverTimeWorkCenter4.NextSetupSettings = VALUE(Catalog.SetupOptions.EmptyRef))";

	Query.SetParameter("WorkCenterType", WorkCenterType);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf