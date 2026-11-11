#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Records "external" source settings that are not stored directly in the Catalog element 
// 
// Parameters:
//  DataSource - CatalogRef.SourcesToImportProductionMasterData
//  Settings - Structure
//  UpdateTaskSettings - Boolean
Procedure RecordSourceSettings(DataSource, Settings, UpdateTaskSettings = False) Export
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.DataSource.Set(DataSource);
	RecordSet.Read();
	
	If RecordSet.Count() Then
		Record = RecordSet[0];
	Else
		Record = RecordSet.Add();
		Record.DataSource = DataSource;
	EndIf;
	
	FillPropertyValues(Record, Settings);
	
	If UpdateTaskSettings Then
		CheckUpdateTaskSettings(Record, Settings);
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

// Download State TABLE by SOURCE
// 
// Parameters:
//  DataSources - CatalogRef.SourcesToImportProductionMasterData
// 
// Returns:
//  ValueTable
Function ImportState(DataSources) Export
	
	ProblematicStates = Enums.ImportMasterDataStates.ProblematicStates();
	
	QueryText = "
	|SELECT
	|	T1.Ref                                                 AS DataSource,
	|	FALSE                                                      AS AutoimportIsUsed,
	|	UNDEFINED                                              AS AutoimportSchedule,
	|	ISNULL(T2.AutoimportJobID, UNDEFINED) AS AutoimportJobID,
	|	ISNULL(T2.StartDate, DATETIME(1, 1, 1))                 AS StartDate,
	|	ISNULL(T2.EndDate, DATETIME(1, 1, 1))              AS EndDate,
	|	ISNULL(T2.ErrorsCount, 0)                            AS ErrorsCount,
	|	ISNULL(T2.State, &DoNotPerformed)                      AS State,
	|	FALSE                                                      AS StateIsProblematic
	|FROM
	|	Catalog.SourcesToImportProductionMasterData AS T1
	|
	|		LEFT JOIN InformationRegister.MasterDataImportSettings AS T2
	|		ON T1.Ref = T2.DataSource
	|WHERE
	|	T1.Ref IN (&DataSources)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataSources", DataSources);
	Query.SetParameter("DoNotPerformed", Enums.ImportMasterDataStates.DoNotPerformed);
	
	Result = Query.Execute().Unload();
	
	For Each String In Result Do
		Catalogs.SourcesToImportProductionMasterData.FillInStartupSettings(String);
		If ProblematicStates.FindByValue(String.State) <> Undefined Then
			String.StateIsProblematic = True;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Procedure CheckUpdateTaskSettings(Record, Settings)
	
	Job = ScheduledJobsServer.Job(Record.AutoimportJobID);
	
	If Not Record.Used
			Or Settings.Property("AutoUploadDeleteTask") Then
		If Job <> Undefined Then 
			ScheduledJobsServer.DeleteJob(Job);
			Record.AutoimportJobID = CommonClientServer.BlankUUID();
		EndIf;
		Return;
	EndIf;
	
	Changes = New Structure;
	
	Use = Undefined;
	If Settings.Property("AutoimportIsUsed", Use) Then
		If Use = True
				Or Job <> Undefined Then
			Changes.Insert("Use", Use);
		EndIf;
	EndIf;
	
	Schedule = Undefined;
	If Settings.Property("AutoimportSchedule", Schedule) Then
		If Schedule <> Undefined
				Or Job <> Undefined Then
			Changes.Insert("Schedule", Schedule);
		EndIf;
	EndIf;
	
	If Changes.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Job = Undefined Then
		
		JobKey = DataProcessors.ImportProductionMasterData.KeyForPerformingActionInBackground(
			Record.DataSource,
			DataProcessors.ImportProductionMasterData.UploadDataAction());
		
		ProcedureParameters = New Array;
		ProcedureParameters.Add(Record.DataSource);
		
		JobParameters = New Structure;
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ImportProductionMasterData);
		JobParameters.Insert("Use", False);
		JobParameters.Insert("Description", DataProcessors.ImportProductionMasterData.LogEventKey(Record.DataSource));
		JobParameters.Insert("Parameters", ProcedureParameters);
		JobParameters.Insert("Key", JobKey);
		
		Job = ScheduledJobsServer.AddJob(JobParameters);
		Record.AutoimportJobID = ScheduledJobsServer.UUID(Job);
		
	EndIf;
	
	ScheduledJobsServer.ChangeJob(Job, Changes);
	
EndProcedure

#EndRegion

#EndIf