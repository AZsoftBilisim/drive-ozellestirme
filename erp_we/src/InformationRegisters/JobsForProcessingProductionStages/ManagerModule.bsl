#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the task register.
//
// Parameters:
//  ProductionStage - DocumentRef.ProductionStage2_2	 - the stage to add the task to.
//  Actions		 - See StructureOfActions
//
Procedure AddJob(ProductionStage, Actions) Export
	
	If Actions.RefreshStatus Or Actions.FillInAccordingToOperations Then
		
		Data = New Structure;
		Data.Insert("ProductionStage",     ProductionStage);
		Data.Insert("RefreshStatus",    Actions.RefreshStatus);
		Data.Insert("FillInAccordingToOperations", Actions.FillInAccordingToOperations);
		
		DeferredJobs.ProcessQueueTasks("JobsForProcessingProductionStages", Data);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Returns the structure of actions.
//
// Returns:
//  Structure - structure of actions:
//   * RefreshStatus    - Boolean -
//   * FillInAccordingToOperations - Boolean -
//
Function StructureOfActions() Export
	
	StructureOfActions = New Structure("RefreshStatus, FillInAccordingToOperations", False, False);
	Return StructureOfActions;
	
EndFunction

#Region DeferredJobs

// Returns the Query Text of the task selection.
//
// Parameters:
//  Query            - See DeferredJobs.QueryTextOfDefaultTaskSelection.Query
//  QueueParameters  - See DeferredJobs.QueryTextOfDefaultTaskSelection.QueueParameters
//  JobsCount - See DeferredJobs.QueryTextOfDefaultTaskSelection.Query
//
// Returns:
//  String - Task Selection Query Text
//
Function TaskSelectionQueryText(Query, QueueParameters, JobsCount) Export
	
	QueryText = DeferredJobs.QueryTextOfDefaultTaskSelection(
					Query,
					QueueParameters,
					JobsCount,
					"Table.PostponeExecutionUntil < &CurrentUniversalDate");
	
	Query.SetParameter("CurrentUniversalDate", CurrentUniversalDate());
	
	Return QueryText;
	
EndFunction

// Returns additional task completion properties.
//
// Parameters:
// 	RecordError - See DeferredJobs.CompleteJobs.RecordError
//
// Returns:
//  Undefined, Structure - Additional task completion properties:
//   * TaskIdsForStageBlockingErrors - Array of UUID -
//
Function AdditionalProperties(RecordError) Export
	
	If RecordError Then
		AdditionalProperties = New Structure;
		AdditionalProperties.Insert("TaskIdsForStageBlockingErrors", New Array);
	Else
		AdditionalProperties = Undefined;
	EndIf;
	
	Return AdditionalProperties;
	
EndFunction

// Performs error preprocessing before the main processing in the method See DeferredJobs.CompleteJobs.
//
// Parameters:
//  QueueParameters                    - ValueTableRow of See DeferredJobs.TaskQueues
//  Data                              - ValueTable - data for completing tasks,
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  ExceptionText                     - String - text of the exception error,
//  AdditionalProperties              - See AdditionalProperties
//
Procedure BeforeErrorHandling(
			QueueParameters,
			Data,
			IdsOfUnprocessedRecords,
			ExceptionText,
			AdditionalProperties) Export
	
	TaskIdsForStageBlockingErrors = AdditionalProperties.TaskIdsForStageBlockingErrors;
	If TaskIdsForStageBlockingErrors.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DimensionCalculation,
	|	MIN(NumberOfShifts) + 1 AS NumberOfShifts
	|FROM
	|	InformationRegister.JobsForProcessingProductionStages AS Table
	|WHERE
	|	Table.RecordID IN (&TaskIdsForStageBlockingErrors)
	|
	|GROUP BY
	|	DimensionCalculation
	|";
	
	DimensionCalculation = QueueParameters.DimensionCalculation;
	If Not ValueIsFilled(DimensionCalculation) Then
		DimensionCalculation = "RecordID";
	EndIf;
	
	Query = New Query;
	Query.Text = StrReplace(QueryText, "DimensionCalculation", DimensionCalculation);
	
	Query.SetParameter("TaskIdsForStageBlockingErrors", TaskIdsForStageBlockingErrors);
	
	TableOfShifts = Query.Execute().Unload();
	TableOfShifts.Indexes.Add(DimensionCalculation);
	
	Data.Indexes.Add("RecordID");
	
	If DimensionCalculation <> "RecordID" Then
		Data.Indexes.Add(DimensionCalculation);
	EndIf;
	
	FilterRecordID = New Structure("RecordID");
	FilterDimensionCalculation    = New Structure(DimensionCalculation);
	
	CurrentUniversalDate = CurrentUniversalDate();
	
	For Each RecordID In TaskIdsForStageBlockingErrors Do
		
		FilterRecordID.RecordID = RecordID;
		
		DataString = Data.FindRows(FilterRecordID)[0];
		
		FillPropertyValues(FilterDimensionCalculation, DataString);
		
		NumberOfShifts = TableOfShifts.FindRows(FilterDimensionCalculation)[0].NumberOfShifts;
		
		If NumberOfShifts = 1 Then
			PostponeExecutionUntil = CurrentUniversalDate + 60 * 5;
		ElsIf NumberOfShifts = 2 Then
			PostponeExecutionUntil = CurrentUniversalDate + 60 * 12;
		ElsIf NumberOfShifts = 3 Then
			PostponeExecutionUntil = CurrentUniversalDate + 60 * 20;
		Else
			Continue;
		EndIf;
		
		Data.Delete(DataString);
		IdsOfUnprocessedRecords.Delete(RecordID);
		
		RecordSet = InformationRegisters.JobsForProcessingProductionStages.CreateRecordSet();
		RecordSet.Filter.RecordID.Set(RecordID);
		RecordSet.Read();
		
		For Each SetRecord In RecordSet Do
			SetRecord.NumberOfShifts    = NumberOfShifts;
			SetRecord.PostponeExecutionUntil = PostponeExecutionUntil;
		EndDo;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf