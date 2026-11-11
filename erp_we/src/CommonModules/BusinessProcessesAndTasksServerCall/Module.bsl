///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use "BusinessProcessesAndTasksServer.TaskExecutionForm".
// Gets a structure with the description of a task execution form.
//
// Parameters:
//  TaskRef - TaskRef.PerformerTask
//
// Returns:
//   See BusinessProcessesAndTasksOverridable.OnReceiveTaskExecutionForm.FormParameters
//
Function TaskExecutionForm(Val TaskRef) Export
	
	Return BusinessProcessesAndTasksServer.TaskExecutionForm(TaskRef);
	
EndFunction

// Deprecated. Instead, use "BusinessProcessesAndTasksServer.IsPerformerTask"
// Checks whether the report cell contains a reference to the task and returns details value in
// the "DetailsValue" parameter.
//
// Parameters:
//  Details             - String - a cell name.
//  ReportDetailsData - String - address in temporary storage.
//  DetailsValue     - TaskRef.PerformerTask
//                          - Arbitrary - details value from the cell.
// 
// Returns:
//  Boolean - True if it is a task to an assignee.
//
Function IsPerformerTask(Val Details, Val ReportDetailsData, DetailsValue) Export
	
	Return BusinessProcessesAndTasksServer.IsPerformerTask(Details, ReportDetailsData, DetailsValue);
	
EndFunction

// Deprecated. Instead, use BusinessProcessesAndTasks.ExecuteTask".
// Completes the TaskRef task. If necessary executes
// DefaultCompletionHandler in the manager module
// of the business process where the TaskRef task belongs.
//
// Parameters:
//  TaskRef        - TaskRef
//  DefaultAction - Boolean       - shows whether it is required to call procedure 
//                                       DefaultCompletionHandler for the task business process.
//
Procedure ExecuteTask(TaskRef, DefaultAction = False) Export
	
	BusinessProcessesAndTasksServer.ExecuteTask(TaskRef, DefaultAction);
	
EndProcedure

// Deprecated. Instead, use "BusinessProcessesAndTasksServer.IsHeadTask".
// Checks whether the specified task is the head one.
//
// Parameters:
//  TaskRef  - TaskRef.PerformerTask
//
// Returns:
//   Boolean
//
Function IsHeadTask(Val TaskRef) Export
	
	Return BusinessProcessesAndTasksServer.IsHeadTask(TaskRef);
	
EndFunction

// Deprecated. Instead, use "BusinessProcessesAndTasksServer.GeneratePerformerChoiceData".
// Generates a choice list for picking assignees in input fields of flexible type ("User" and "Role").
//
// Parameters:
//  Text - String - a text fragment to search for possible assignees.
// 
// Returns:
//  ValueList - a selection list containing possible assignees.
//
Function GeneratePerformerChoiceData(Val Text) Export
	
	Return BusinessProcessesAndTasksServer.GeneratePerformerChoiceData(Text);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Marks the specified business processes as active.
//
// Parameters:
//  Var_BusinessProcesses - Array of DefinedType.BusinessProcess
//
Procedure ActivateBusinessProcesses(Var_BusinessProcesses) Export
	
	BusinessProcessesAndTasksServer.ActivateBusinessProcesses(Var_BusinessProcesses);
	
EndProcedure

// Marks the specified business processes as active.
//
// Parameters:
//  BusinessProcess - DefinedType.BusinessProcess
//
Procedure ActivateBusinessProcess(BusinessProcess) Export
	
	BusinessProcessesAndTasksServer.ActivateBusinessProcess(BusinessProcess);
	
EndProcedure

// Marks the specified business processes as suspended.
//
// Parameters:
//  Var_BusinessProcesses - Array of DefinedType.BusinessProcess
//
Procedure StopBusinessProcesses(Var_BusinessProcesses) Export
	
	BusinessProcessesAndTasksServer.StopBusinessProcesses(Var_BusinessProcesses);
	
EndProcedure

// Marks the specified business process as suspended.
//
// Parameters:
//  BusinessProcess - DefinedType.BusinessProcess
//
Procedure StopBusinessProcess(BusinessProcess) Export
	
	BusinessProcessesAndTasksServer.StopBusinessProcess(BusinessProcess);
	
EndProcedure

// Marks the specified task as accepted for execution.
//
// Parameters:
//   Var_Tasks - Array of TaskRef.PerformerTask
//
Procedure AcceptTasksForExecution(Var_Tasks) Export
	
	BusinessProcessesAndTasksServer.AcceptTasksForExecution(Var_Tasks);
	
EndProcedure

// Marks the specified tasks as not accepted for execution.
//
// Parameters:
//   Var_Tasks - Array of TaskRef.PerformerTask
//
Procedure CancelAcceptTasksForExecution(Var_Tasks) Export
	
	BusinessProcessesAndTasksServer.CancelAcceptTasksForExecution(Var_Tasks);
	
EndProcedure

// Forwards "TasksToRedirect" to a new assignee specified in the "ForwardingInfo" structure.
//
// Parameters:
//  RedirectedTasks_ - Array of TaskRef.PerformerTask
//  ForwardingInfo   - Structure - new values of task addressing attributes.
//  IsCheckOnly         - Boolean    - If True, the function does not actually forward
//                                       tasks, it only checks 
//                                       whether they can be forwarded.
//  RedirectedTasks - Array of TaskRef.PerformerTask - forwarded tasks.
//                                       The array elements might not exactly match 
//                                       the TasksToRedirect elements if some tasks cannot be forwarded.
//
// Returns:
//   Boolean   - True if the tasks are forwarded successfully.
//
Function ForwardTasks(Val RedirectedTasks_, Val ForwardingInfo, Val IsCheckOnly = False,
	RedirectedTasks = Undefined) Export
	
	Return BusinessProcessesAndTasksServer.ForwardTasks(RedirectedTasks_, ForwardingInfo, IsCheckOnly,
		RedirectedTasks);
	
EndFunction

// Returns:
//  Number
//
Function UncompletedBusinessProcessesTasksCount(Val Var_BusinessProcesses) Export
	
	BusinessProcessesArray = New Array;
	For Each BusinessProcess In Var_BusinessProcesses Do
		If TypeOf(BusinessProcess) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		BusinessProcessesArray.Add(BusinessProcess);
	EndDo;
		
	If BusinessProcessesArray.Count() = 0 Then
		Return 0;
	EndIf;

	Query = New Query(
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	Task.PerformerTask AS PerformerTasks
		|WHERE
		|	PerformerTasks.BusinessProcess IN (&BusinessProcesses)
		|	AND PerformerTasks.Executed = FALSE");

	Query.SetParameter("BusinessProcesses", BusinessProcessesArray);
	Return Query.Execute().Unload()[0].Count;
	
EndFunction

// Returns:
//  Number
//
Function UncompletedBusinessProcessTasksCount(Val BusinessProcess) Export
	
	Return UncompletedBusinessProcessesTasksCount(CommonClientServer.ValueInArray(BusinessProcess));
	
EndFunction

// Returns:
//  - BusinessProcessRef
//  - Undefined
//
Function MarkBusinessProcessesForDeletion(Val SelectedRows) Export
	
	Count = 0;
	For Each TableRow In SelectedRows Do
		BusinessProcessRef = TableRow.Owner;
		If BusinessProcessRef = Undefined Or BusinessProcessRef.IsEmpty() Then
			Continue;
		EndIf;
		BeginTransaction();
		Try
			BusinessProcessesAndTasksServer.LockBusinessProcesses(BusinessProcessRef);
			BusinessProcessObject = BusinessProcessRef.GetObject();
			BusinessProcessObject.SetDeletionMark(Not BusinessProcessObject.DeletionMark);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		Count = Count + 1;
	EndDo;
	Return ?(Count = 1, SelectedRows[0].Owner, Undefined);
EndFunction

#EndRegion