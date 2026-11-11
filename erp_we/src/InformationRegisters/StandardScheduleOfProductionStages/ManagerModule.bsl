
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Calculates the standard schedule for a given production order.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - order, the queue of the stages of which must be calculated
//
Procedure Calculate(ReferenceOrder) Export
	
	Query = New Query;
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	TempTablesManager = New TempTablesManager;
	Documents.ProductionStage2_2.CreateTTCommunicationStagesByOrder(
		TempTablesManager, ReferenceOrder, True);
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = QueryTextForCalculatingStandardProductionSchedule();
	
	ResultsArray = Query.ExecuteBatch();
	Schedule = ResultsArray[0].Unload();
	
	CalculateTheSchedule(Schedule, ResultsArray[1].Unload());
	
	Set = InformationRegisters.StandardScheduleOfProductionStages.CreateRecordSet();
	Set.Filter.ReferenceOrder.Set(ReferenceOrder);
	Set.Load(Schedule);
	Set.Write();
	
EndProcedure

#EndRegion

#Region Private

Procedure CalculateTheSchedule(Stages, Dependencies) Export
	
	Stages.Indexes.Add("ProductionStage");
	Dependencies.Indexes.Add("Stage");
	Dependencies.Indexes.Add("NextStage");
	
	Stages.Columns.Add("Path", New TypeDescription("Map"));
	
	// Calculation before launch
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("FirstStage", True);
	
	For Each String In Stages.FindRows(TheStructureOfTheSearch) Do
		CalculateDuration_(Stages, Dependencies, String, "DurationBeforeStart", True);
	EndDo;
	
	// Calculation before release
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("LastStage", True);
	
	For Each String In Stages.FindRows(TheStructureOfTheSearch) Do
		CalculateDuration_(Stages, Dependencies, String, "DurationBeforeProductionIssue", False);
	EndDo;
	
	Stages.Columns.Delete("Path");
	
EndProcedure

Procedure CalculateDuration_(Stages, Dependencies, StringStages, ColumnName, TraversalToEnd)
	
	Path = New Map;
	Path.Insert(StringStages.ProductionStage, 0);
	StringStages.Path = Path;
	
	Queue = New Array;
	Queue.Add(StringStages);
	
	While Queue.UBound() <> -1 Do
		
		CurrentIndex = Queue.UBound();
		CurrentRow = Queue[CurrentIndex];
		
		If CurrentRow.ResourceIntensity = 0 Then
			Duration = CurrentRow[ColumnName] + 0.0001;
		Else
			Duration = Int(CurrentRow[ColumnName]) + CurrentRow.ResourceIntensity;
		EndIf;
		
		// Search for followers and add them to the queue
		If TraversalToEnd Then
			
			TheStructureOfTheSearch = New Structure("Stage", CurrentRow.ProductionStage);
			FoundRows = Dependencies.FindRows(TheStructureOfTheSearch);
			
			For Each String In FoundRows Do
				
				SubsequentStage = Stages.Find(String.NextStage, "ProductionStage");
				If SubsequentStage <> Undefined
					And Duration > SubsequentStage[ColumnName] Then
						
					SubsequentStage[ColumnName] = Duration;
					Queue.Add(SubsequentStage);
					
				EndIf;
				
			EndDo;
			
		Else
			
			TheStructureOfTheSearch = New Structure("NextStage", CurrentRow.ProductionStage);
			FoundRows = Dependencies.FindRows(TheStructureOfTheSearch);
			
			For Each String In FoundRows Do
				
				SubsequentStage = Stages.Find(String.Stage, "ProductionStage");
				If SubsequentStage <> Undefined
					And Duration > SubsequentStage[ColumnName] Then
						
					SubsequentStage[ColumnName] = Duration;
					Queue.Add(SubsequentStage);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		// Loop control
		If Queue.UBound() <> CurrentIndex Then
			For IndexOf = CurrentIndex+1 To Queue.UBound() Do
				
				String = Queue[IndexOf];
				If IndexOf = Queue.UBound() Then
					String.Path = CurrentRow.Path;
				Else
					Path = New Map;
					For Each KeyAndValue In CurrentRow.Path Do
						Path.Insert(KeyAndValue.Key, KeyAndValue.Value);
					EndDo;
					String.Path = Path;
				EndIf;
				
				If String.Path.Get(String.ProductionStage) = Undefined Then
					String.Path.Insert(String.ProductionStage, 0);
				Else
					Raise StrTemplate(
						NStr("vi = 'Trong quá trình tính toán trình tự, đã phát hiện thấy vòng lặp trong công đoạn ""%1"".';
							|ru = 'В процессе расчета очереди обнаружено зацикливание на этапе ""%1"".';
							|en = 'Loop detected during queue calculation at stage ""%1"".'; fa = 'Loop detected during queue calculation at stage ""%1"".';
							|it = 'Durante il processo di calcolo della coda è stato riscontrato un looping nella fase ""%1"".';
							|pl = 'W procesie obliczenia kolejki wykryto zapętlenie na etapie ""%1"".';
							|tr = '""%1"" aşamasındaki kuyruk hesaplaması sırasında döngü tespit edildi.'"),
						String.ProductionStage);
				EndIf;
				
			EndDo;
		Else
			CurrentRow.Path = Undefined;
		EndIf;
		
		Queue.Delete(CurrentIndex);
		
	EndDo;
	
EndProcedure

// Calculates the regulatory schedule of production stages.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Tasks of the accounting Normativnogografikaproduction", there are also service columns:
//             * ObjectOfARAP          - DocumentRef.ProductionOrder2_2 -
//             * RecordID    - UUID -
//             * NotUsedRegistrationDay - Number  -
//             * RecordDate             - Date   -
//             * JobID   - UUID - Service_
//             * TaskDate_            - Date                    - Service_
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier 
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure ProcessTasksForCalculatingStandardProductionSchedule(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	References = Common.UnloadColumn(Jobs, "ObjectOfARAP", True);
	
	TempTablesManager = New TempTablesManager;
	Documents.ProductionStage2_2.CreateTTCommunicationStagesByOrder(TempTablesManager, References, True);
	
	Query = New Query;
	Query.SetParameter("ReferenceOrder", References);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = QueryTextForCalculatingStandardProductionSchedule(True);
	
	Results = Query.ExecuteBatch();
	
	Stages = Results[0].Unload();
	Stages.Indexes.Add("ReferenceOrder");
	
	Dependencies = Results[1].Unload();
	Dependencies.Indexes.Add("ReferenceOrder");
	
	FilterReferenceOrder = New Structure("ReferenceOrder");
	
	MetaOfRegister = Undefined;
	
	For Each ReferenceOrder In References Do
		
		Try
			
			FilterReferenceOrder.ReferenceOrder = ReferenceOrder;
			
			Schedule = Stages.Copy(FilterReferenceOrder);
			
			CalculateTheSchedule(Schedule, Dependencies.Copy(FilterReferenceOrder, "Stage, NextStage"));
			
			Set = InformationRegisters.StandardScheduleOfProductionStages.CreateRecordSet();
			Set.Filter.ReferenceOrder.Set(ReferenceOrder);
			Set.Load(Schedule);
			Set.Write();
			
		Except
			
			If MetaOfRegister = Undefined Then
				
				MetaOfRegister = Metadata.InformationRegisters.JobsForTargetProductionScheduleCalculation;
				EventName   = DeferredJobs.EventName();
				ErrorFields   = New Structure("ObjectOfARAP");
				DataOfError = New Structure("ObjectOfARAP");
				
				Jobs.Indexes.Add("ObjectOfARAP");
				
			EndIf;
			
			ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(EventName, EventLogLevel.Error, MetaOfRegister,, ExceptionText);
			
			DataOfError.ObjectOfARAP = ReferenceOrder;
			
			ErrorText = DeferredJobs.ExecutionErrorText(ErrorFields, DataOfError, ExceptionText);
			
			FoundRows = Jobs.FindRows(DataOfError);
			For Each FoundRow In FoundRows Do
				IdsOfUnprocessedRecords.Insert(FoundRow.RecordID, ErrorText);
			EndDo;
			
		EndTry;
		
	EndDo;
	
EndProcedure

Function QueryTextForCalculatingStandardProductionSchedule(OrderInDependencyTable = False)
	
	QueryText =
	"SELECT
	|	ProductionStage2_2.Ref                                        AS ProductionStage,
	|	ProductionStage2_2.ReferenceOrder                                  AS ReferenceOrder,
	|	0                                                                 AS DurationBeforeStart,
	|	0                                                                 AS DurationBeforeProductionIssue,
	|	CASE
	|		WHEN ProductionStage2_2.UnitOfMeasureOfStageDuration = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN 60
	|		WHEN ProductionStage2_2.UnitOfMeasureOfStageDuration = VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN 3600
	|		WHEN ProductionStage2_2.UnitOfMeasureOfStageDuration = VALUE(Enum.TimeMeasureUnits.DAY)
	|			THEN 86400
	|		WHEN ProductionStage2_2.UnitOfMeasureOfStageDuration = VALUE(Enum.TimeMeasureUnits.Days1)
	|			THEN 86400
	|		ELSE 1
	|	END * ProductionStage2_2.StageDuration                     AS ResourceIntensity,
	|
	|	NOT TRUE IN
	|				(SELECT 
	|					TRUE
	|				FROM
	|					TTCommunicationStages AS Links
	|				WHERE                       
	|					Links.NextStage = ProductionStage2_2.Ref) AS FirstStage,
	|	NOT TRUE IN
	|				(SELECT 
	|					TRUE
	|				FROM
	|					TTCommunicationStages AS Links
	|				WHERE                       
	|					Links.Stage = ProductionStage2_2.Ref)          AS LastStage
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.ReferenceOrder IN (&ReferenceOrder)
	|	AND ProductionStage2_2.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCommunicationStages.Stage.ReferenceOrder AS ReferenceOrder,
	|	TTCommunicationStages.Stage              AS Stage,
	|	TTCommunicationStages.NextStage     AS NextStage
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages";
	
	If Not OrderInDependencyTable Then
		QueryText = StrReplace(QueryText, "TTCommunicationStages.Stage.ReferenceOrder AS ReferenceOrder,", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion
	
#EndIf
