///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// ACC:142-off - 3+ optional parameters to support application functions.
// ACC:134-off - 7+ parameters to support application functions.

// Starts the function execution in a background job if possible.
// The function to call can have an arbitrary number of parameters, but not more than 7.
// Values of the passed function parameters and its return value must be serialized.
// Function parameters must not be returned.
//
// We recommend that you use it together with the TimeConsumingOperationsClient.WaitForCompletion().
// If it's impossible, use IsJobCompleted() to ensure the operation is completed.
//
// Parameters:
//  ExecutionParameters - ClientApplicationForm - Form where the call originated.
//                      - UUID - an ID of the form, from which a call is executed;
//                      - Structure - See FunctionExecutionParameters
//  FunctionName - String - a name of the export function in a common module, object manager module, 
//                        or data processor module that you want to start in a background job.
//                        Examples: "MyCommonModule.MyProcedure", "Report.ImportedData.Generate"
//                        or "DataProcessor.DataImport.Import". 
//
//  Parameter1 - Arbitrary - arbitrary parameters of the function call. The number of parameters can be from 0 to 7.
//  Parameter2 - Arbitrary
//  Parameter3 - Arbitrary
//  Parameter4 - Arbitrary
//  Parameter5 - Arbitrary
//  Parameter6 - Arbitrary
//  Parameter7 - Arbitrary
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//                          - Undefined - If Status <> "Running" and the background job wasn't started.
//   * ResultAddress       - String - the address of the temporary storage where the function result must be
//                                      stored.
//   * ErrorInfo    - ErrorInfo - If Status = "Error".
//                           - Undefined - If Status <> "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
//
// Example:
//  In general, the process of starting and processing the result of a long-running operation in the form module looks like this:
//
//   1) The function that will be executed in the background is located in the object manager module or in the server common module:
//    Function CalculateValue(Val MyParameter1, Val MyParameter2) Export
//     …
//     Return Result;
//    EndFunction
//
//   2) Starting the operation on the server and attaching the idle handler:
//    &AtClient
//    Procedure CalculateValue()
//     TimeConsumingOperation = StartExecutionAtServer();
//     NotificationOfCompletion = New NotifyDescription("ProcessResult", ThisObject);
//     IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
//     TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotificationOfCompletion, IdleParameters);
//    EndProcedure
//
//    &AtServer
//    Function StartExecutionAtServer()
//     ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
//     Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "DataProcessor.MyDataProcessor.CalculateValue", 
//      MyParameter1, MyParameter2);
//    EndFunction
//    
//   3) The result processing of a long-running operation:
//    &AtClient
//    Procedure ProcessResult(Result, AdditionalParameters) Export
//     If Result = Undefined Then
//      Return;
//     EndIf;
//     If Result.Status = "Error" Then
//      StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
//      Return;
//     EndIf;
//     OutputResult(Result.ResultAddress);
//    EndProcedure 
//  
Function ExecuteFunction(Val ExecutionParameters, FunctionName, Val Parameter1 = Undefined,
	Val Parameter2 = Undefined, Val Parameter3 = Undefined, Val Parameter4 = Undefined,
	Val Parameter5 = Undefined, Val Parameter6 = Undefined, Val Parameter7 = Undefined) Export
	
	CheckNameOfProcedure(FunctionName,
		"FunctionName", "TimeConsumingOperations.ExecuteFunction", ExecutionParameters);
	
	CallParameters = ParametersList(Parameter1, Parameter2, Parameter3, Parameter4,
		Parameter5, Parameter6, Parameter7);
	
	ExecutionParameters = PrepareExecutionParameters(ExecutionParameters, "Function");
	Return ExecuteInBackground(FunctionName, CallParameters, ExecutionParameters);
	
EndFunction

// ACC:141-off - The first optional parameter followed by a required parameter is selected
// to keep the parameter order the same as in the "ExecuteFunction" function.

// Runs a procedure in a background job if possible.
// The procedure to call can have an arbitrary number of parameters, but not more than 7.
// Values of the passed procedure parameters and its return value must be serialized.
// Procedure parameters must not be returned.
//
// We recommend that you use it together with TimeConsumingOperationsClient.WaitForCompletion().
// If it's impossible, use IsJobCompleted() to ensure the operation is completed.
//
// Parameters:
//
//  ExecutionParameters - See TimeConsumingOperations.ProcedureExecutionParameters
//
//  ProcedureName - String - a name of the export procedure in a common module, object manager module, 
//                          or data processor module that you want to start in a background job.
//                          Examples: "MyCommonModule.MyProcedure", "Report.ImportedData.Generate"
//                          or "DataProcessor.DataImport.Import". 
//
//  Parameter1 - Arbitrary - arbitrary parameters of the procedure call. The number of parameters can be from 0 to 7.
//  Parameter2 - Arbitrary
//  Parameter3 - Arbitrary
//  Parameter4 - Arbitrary
//  Parameter5 - Arbitrary
//  Parameter6 - Arbitrary
//  Parameter7 - Arbitrary
//
// Returns:
//  Structure - Job runtime parameters: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//                          - Undefined - If Status <> "Running" and the background job wasn't started.
//   * ErrorInfo    - ErrorInfo - If Status = "Error".
//                           - Undefined - If Status <> "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
//
// Example:
//  In general, running a long-running operation in the form module and processing its results is organized as follows:
//
//   1) The procedure to run in the background is added to the object manager module or common server module
//    Procedure ExecuteCalculation(Val MyParameter1, Val MyParameter2) Export
//     …
//    EndProcedure
//
//   2) The operation is started on the server, and the idle handler is attached (if necessary)
//    &AtClient
//    Procedure ExecuteCalculation()
//     TimeConsumingOperation = StartExecuteAtServer();
//     NotificationOfCompletion = New NotifyDescription("ProcessResult", ThisObject);
//     IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
//     TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotificationOfCompletion, IdleParameters);
//    EndProcedure
//
//    &AtServer
//    Function StartExecuteAtServer()
//     Return TimeConsumingOperations.ExecuteProcedure(, "DataProcessor.MyDataProcessor.ExecuteCalculation", 
//      MyParameter1, MyParameter2);
//    EndFunction
//    
//   3) The result of a long-running operation is processed
//    &AtClient
//    Procedure ProcessResult(Result, AdditionalParameters) Export
//     If Result = Undefined Then
//      Return;
//     EndIf;
//     If Result.Status = "Error" Then
//      StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
//      Return;
//     EndIf;
//     OnCalculaionCompletion();
//    EndProcedure 
//   
//@skip-check method-optional-parameter-before-required
//
Function ExecuteProcedure(Val ExecutionParameters = Undefined, ProcedureName, Val Parameter1 = Undefined,
	Val Parameter2 = Undefined, Val Parameter3 = Undefined, Val Parameter4 = Undefined,
	Val Parameter5 = Undefined, Val Parameter6 = Undefined, Val Parameter7 = Undefined) Export
	
	CheckNameOfProcedure(ProcedureName,
		"ProcedureName", "TimeConsumingOperations.ExecuteFunction", ExecutionParameters);
	
	CallParameters = ParametersList(Parameter1, Parameter2, Parameter3, Parameter4,
		Parameter5, Parameter6, Parameter7);
	ExecutionParameters = PrepareExecutionParameters(ExecutionParameters, "Procedure");
	Return ExecuteInBackground(ProcedureName, CallParameters, ExecutionParameters);
	
EndFunction

// ACC:141-on
// ACC:134-on
// ACC:142-on

// Runs a function in a multi-threaded background job if possible.
// The procedure can have an arbitrary number of parameters, but no more than 7.
// Values of the passed parameters and the return value must be serialized.
// Procedure parameters must not be returned. Shared sessions do not support multi-threaded long-running operations.
// We recommend using it together with TimeConsumingOperationsClient.WaitForCompletion().
//
// If it's impossible, use IsJobCompleted() to ensure the operation is completed.
// 
//
// Parameters:
//  FunctionName - String - the name of the export function in a common module, object manager module, 
//                        or data processor module that you want to start in a background job.
//                        Example: "MyCommonModule.MyProcedure", "Reports.ImportedData.Generate"
//                        or "DataProcessors.DataImport.ObjectModule.Import". 
//  ExecutionParameters - See FunctionExecutionParameters
//  FunctionSettings - Map of KeyAndValue - Custom set of function call parameters:
//    * Key - Arbitrary - Set key.
//    * Value - Array - Up to 7 function call parameters.
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//                          - Undefined - If Status <> "Running" and the background job wasn't started.
//   * ResultAddress       - String - Address of the temporary storage to save the Map to:
//                                      ** Key - Arbitrary
//                                      ** Value - See ExecuteFunction
//   * ErrorInfo    - ErrorInfo - If Status = "Error".
//                           - Undefined - If Status <> "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
//
Function ExecuteFunctionInMultipleThreads(FunctionName, ExecutionParameters, FunctionSettings = Undefined) Export
	
	CheckNameOfProcedure(FunctionName,
		"FunctionName", "TimeConsumingOperations.ExecuteFunctionInMultipleThreads", ExecutionParameters);
	
	Return RunMethodInMultipleThreads(FunctionName, ExecutionParameters, FunctionSettings, True);
	
EndFunction

// Runs a procedure in a multi-threaded background job if possible.
// The procedure can have an arbitrary number of parameters, but no more than 7.
// Values of the passed procedure parameters must be serialized.
// Procedure parameters must not be returned. Shared sessions do not support multi-threaded long-running operations.
// We recommend using it together with TimeConsumingOperationsClient.WaitForCompletion().
//
// If it's impossible, use IsJobCompleted() to ensure the operation is completed.
// 
//
// Parameters:
//  ProcedureName - String - Name of the export procedure that you want to start in the background. 
//                          The procedure can belong to a common module, object manager module, or data processor module.
//  ExecutionParameters - See FunctionExecutionParameters
//  ProcedureSettings - Map of KeyAndValue - Custom set of procedure call parameters:
//    * Key - Arbitrary - Set key.
//    * Value - Array - Up to 7 procedure call parameters.
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//                          - Undefined - If Status <> "Running" and the background job wasn't started.
//   * ResultAddress       - String - Address of the temporary storage to save the Map to:
//                                       ** Key - Arbitrary
//                                       ** Value - See ExecuteProcedure
//   * ErrorInfo    - ErrorInfo - If Status = "Error".
//                           - Undefined - If Status <> "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
//
Function ExecuteProcedureinMultipleThreads(ProcedureName, ExecutionParameters, ProcedureSettings = Undefined) Export
	
	CheckNameOfProcedure(ProcedureName,
		"ProcedureName", "TimeConsumingOperations.ExecuteFunctionInMultipleThreads", ExecutionParameters);
	
	Return RunMethodInMultipleThreads(ProcedureName, ExecutionParameters, ProcedureSettings, False);
	
EndFunction

// The constructor for the "FunctionExecutionParameters" collection of the "ExecuteFunction" function.
//
// If "RunInBackground" and "RunNotInBackground" are set to "False", the job will be executed in the background if possible.
// The job with the session extensions runs in the main thread if any of the following conditions are met:
//  * the procedure is called in the file infobase through an external connection (this mode has no background job support);
//  * the application runs in the debug mode (see /C DebugMode command-line parameter) for configuration debugging purposes;
//  * the file infobase already has active background jobs (to avoid slow application response to user actions).
//
// Parameters:
//   FormIdentifier - UUID - a UUID of the form 
//                               containing the temporary storage where the procedure puts its result.
//
// Returns:
//   Structure - Long-running operation runtime parameters:
//     * FormIdentifier  - UUID - a UUID of the form
//                             containing the temporary storage where the procedure puts its result.
//     * WaitCompletion   - Undefined - Wait till the background job is completed.
//                           - Number - Timeout in seconds.
//                               If "0", don't wait till the background job is completed.
//                               By default, "0.8" ("4" for low-speed connections).
//     * BackgroundJobDescription - String - the description of the background job. The default value is the procedure name.
//     * BackgroundJobKey - String - A unique key of active background jobs with the same procedure name.
//                                      Intended to avoid running more than one job concurrently.
//                                      By default, it is not assigned a value.
//     * ResultAddress     - String - an address of the temporary storage where the procedure
//                                      result must be stored. If the address is not set, it is generated automatically.
//     * RunInBackground           - Boolean - If True, the job always runs in the background, except for the following cases:
//                                  a) the procedure is called in the file infobase through an external connection 
//                                  (this mode has no background job support);
//                                  b) the function belongs to an external data processor module or an external report module.
//                                  In the file mode, if any other background jobs are running,
//                                  the new job is queued and does not start running until all the previous jobs are completed.
//                                  If False, the job will be executed in the background if possible. 
//     * RunNotInBackground1         - Boolean - If True, the job always runs naturally
//                                  without using background jobs.
//     * NoExtensions            - Boolean - If True, no configuration extensions
//                                  are attached to run the background job. Has priority over the RunNotInBackground parameter. 
//     * WithDatabaseExtensions  - Boolean - If True, the background job will run with the latest version of
//                                  the configuration extensions. Has priority over the RunNotInBackground parameter.
//     * ExternalReportDataProcessor    - See NewDescriptionOfExternalProcessingReport
//                                - Undefined - If the passed method name starts with "ExternalReport" or "ExternalDataProcessor".
//                                  Calling the method requires the right to open external reports or
//                                  external data processors respectively. External reports and
//                                                 external data processors are attached with the unsafe action protection enabled.
//     * AbortExecutionIfError - Boolean - If True, when an error occurs in a child job, the multithread background job is aborted.
//                                  The running child jobs will be aborted.
//                                  Applicable to function RunFunctionInMultithreading.
//                                  
//     * RefinementErrors          - String - If a non-empty string is passed, the error is prefixed with the passed string.
//                                   For example::
//                                   NStr("en = 'Failed to clear the address classifier due to:'; fa = 'Failed to clear the address classifier due to:'")
//
Function FunctionExecutionParameters(Val FormIdentifier) Export
	
	Result = CommonBackgroundExecutionParameters();
	AddExecutionParametersToReturnResult(Result, FormIdentifier);
	Return Result;
	
EndFunction

// The constructor for the "ProcedureExecutionParameters" collection of the "ExecuteProcedure" function.
//
// If "RunInBackground" and "RunNotInBackground" are set to "False", the job will be executed in the background if possible.
// The job with the session extensions runs in the main thread if any of the following conditions are met:
//  * the procedure is called in the file infobase through an external connection (this mode has no background job support);
//  * the application runs in the debug mode (see /C DebugMode command-line parameter) for configuration debugging purposes;
//  * the file infobase already has active background jobs (to avoid slow application response to user actions).
//
// Returns:
//   Structure - Long-running operation runtime parameters:
//     * WaitCompletion   - Undefined - Wait till the background job is completed.
//                           - Number - Timeout in seconds.
//                               If "0", don't wait till the background job is completed.
//                               By default, "0.8" ("4" for low-speed connections).
//     * BackgroundJobDescription - String - the description of the background job. The default value is the procedure name.
//     * BackgroundJobKey - String - the unique key for active background jobs that have the same procedure name.
//                                      Not set by default.
//     * RunInBackground           - Boolean - If True, the job always runs in the background, except for the following cases:
//                                  a) the procedure is called in the file infobase through an external connection 
//                                  (this mode has no background job support);
//                                  b) the function belongs to an external data processor module or an external report module.
//                                  In the file mode, if any other background jobs are running,
//                                  the new job is queued and does not start running until all the previous jobs are completed.
//                                  If False, the job will be executed in the background if possible. 
//     * RunNotInBackground1         - Boolean - If True, the job always runs naturally
//                                  without using background jobs.
//     * NoExtensions            - Boolean - If True, no configuration extensions
//                                  are attached to run the background job. Has priority over the RunNotInBackground parameter. 
//     * WithDatabaseExtensions  - Boolean - If True, the background job will run with the latest version of
//                                  the configuration extensions. Has priority over the RunNotInBackground parameter. 
//     * ExternalReportDataProcessor    - See NewDescriptionOfExternalProcessingReport
//                                - Undefined - If the passed method name starts with "ExternalReport" or "ExternalDataProcessor".
//                                  Calling the method requires the right to open external reports or
//                                  external data processors respectively. External reports and
//                                                 external data processors are attached with the unsafe action protection enabled.
//     * AbortExecutionIfError - Boolean - If True, when an error occurs in a child job, the multithread background job is aborted.
//                                  The running child jobs will be aborted.
//                                  Applicable to function RunProcedureInMultithreading.
//                                  
//     * RefinementErrors          - String - If a non-empty string is passed, the error is prefixed with the passed string.
//                                   For example::
//                                   NStr("en = 'Failed to clear the address classifier due to:'; fa = 'Failed to clear the address classifier due to:'")
//
Function ProcedureExecutionParameters() Export
	
	Return CommonBackgroundExecutionParameters();
	
EndFunction

// We recommend that you use ExecuteFunction() and ExecuteProcedure() instead of this function.
// 
// It executes a procedure in a background job when possible.
// We recommend that you use it together with TimeConsumingOperationsClient.WaitForCompletion().
// If it's impossible, use IsJobCompleted() to ensure the operation is completed.
// 
// Parameters:
//  ProcedureName           - String    - a name of the export procedure in a common module, object manager module, 
//                                       or data processor module that you want to start in a background job.
//                                       Examples: "MyCommonModule.MyProcedure", "Report.ImportedData.Generate"
//                                       or "DataProcessor.DataImport.Import". 
//                                       The procedure must have two or three formal parameters:
//                                        * Parameters       - Structure - arbitrary parameters ProcedureParameters;
//                                        * ResultAddress - String    - the address of the temporary storage where the procedure
//                                          puts its result. Required;
//                                        * AdditionalResultAddress - String - If ExecutionParameters include 
//                                          the AdditionalResult parameter, this parameter contains the address of the additional temporary
//                                          storage where the procedure puts its result. This parameter is optional.
//                                       If you need to run a function in background, it is recommended that you wrap it in a function
//                                       and return its result in the second parameter ResultAddress.
//  ProcedureParameters     - Structure - arbitrary parameters used to call the ProcedureName procedure.
//  ExecutionParameters    - See TimeConsumingOperations.BackgroundExecutionParameters
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID  - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//                           - Undefined - If Status <> "Running" and the background job wasn't started.
//   * ResultAddress       - String - the address of the temporary storage to which the procedure result must be placed
//                                      (or is already placed if Status = "Completed").
//   * AdditionalResultAddress - String - If the AdditionalResult parameter is set, 
//                                      it contains the address of the additional temporary storage
//                                      , to which the procedure result must be placed
//                                      (or is already placed if Status = "Completed").
//   * ErrorInfo    - ErrorInfo - If Status = "Error".
//                           - Undefined - If Status <> "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
// 
// Example:
//  In general, running a long-running operation and processing its results is organized as follows:
//
//   1) The procedure to run in the background is added to the object manager module or common server module:
//    Procedure ExecuteAction(Parameters, ResultAddress) Export
//     …
//     PutToTempStorage(Result, ResultAddress);
//    EndProcedure
//
//   2) The operation is started on the server, and the idle handler is attached:
//    &AtClient
//    Procedure ExecuteAction()
//     TimeConsumingOperation = StartExecuteAtServer();
//     IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
//     …
//     NotificationOfCompletion = New NotifyDescription("ExecuteActionCompletion", ThisObject);
//     TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, NotificationOfCompletion, IdleParameters);
//    EndProcedure
//
//    &AtServer
//    Function StartExecuteAtServer()
//     ProcedureParameters = New Structure;
//     …
//     ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
//     …
//     Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.MyDataProcessor.ExecuteAction", 
//     ProcedureParameters, ExecutionParameters);
//    EndFunction
//    
//   3) The operation result is processed:
//    &AtClient
//    Process the output:
//     &AtClient
//      Procedure ExecuteActionCompletion(Result, AdditionalParameters) Export
//     If Result = Undefined Then
//     Return;
//      EndIf;
//      If Result.Status = "Error" Then
//     StandardSubsystemClient.OutputErrorInfo(Result.ErrorInfo);
//     Return;
//    EndIf; 
//  OutputResult(Result);
//  EndProcedure
//  
Function ExecuteInBackground(Val ProcedureName, Val ProcedureParameters, Val ExecutionParameters) Export
	
	CheckNameOfProcedure(ProcedureName,
		"ProcedureName", "TimeConsumingOperations.ExecuteInBackground", ExecutionParameters);
	
	FillInExecutionParametersTakingIntoAccountBackwardCompatibility(ExecutionParameters);
	VerifyExecutionParameters(ProcedureName, ExecutionParameters);
	If ExecutionParameters.MultithreadLongRunningOperationThreadOfControlProperties = Undefined Then
		CheckAndFillResultAddress(ExecutionParameters, "TimeConsumingOperations.ExecuteInBackground");
	EndIf;
	
	Result = New Structure;
	Result.Insert("Status", "Running");
	Result.Insert("JobID", Undefined);
	Result.Insert("ResultAddress", ExecutionParameters.ResultAddress);
	Result.Insert("AdditionalResultAddress", "");
	Result.Insert("ErrorInfo", Undefined);
	Result.Insert("BriefErrorDescription", "");
	Result.Insert("DetailErrorDescription", "");
	Result.Insert("Messages", New FixedArray(New Array));
	
	If ExecutionParameters.NoExtensions Then
		ExecutionParameters.NoExtensions = ValueIsFilled(SessionParameters.AttachedExtensions);
		
	ElsIf Not ExecutionParameters.WithDatabaseExtensions
	        And Not ExecutionParameters.RunNotInBackground1
	        And StandardSubsystemsServer.ThisIsSplitSessionModeWithNoDelimiters() Then
		
		ExecutionParameters.WithDatabaseExtensions = True;
	EndIf;
	
	ExportProcedureParameters = ProcedureParameters;
	If IsBlankString(ExecutionParameters.IsFunction) Then
		ExportProcedureParameters = New Array;
		ExportProcedureParameters.Add(ProcedureParameters);
		ExportProcedureParameters.Add(ExecutionParameters.ResultAddress);
	EndIf;
	
	If ExecutionParameters.AdditionalResult Then
		Result.AdditionalResultAddress = PutToTempStorage(Undefined, ExecutionParameters.FormIdentifier);
		ExportProcedureParameters.Add(Result.AdditionalResultAddress);
	EndIf;
	
	ExecuteWithoutBackgroundJob = IsRunWithoutBackgroundJob(ProcedureName, ExecutionParameters);
	If ExecuteWithoutBackgroundJob Then
		MessagesBeforeCall = GetUserMessages(True);
		Try
			If ExecutionParameters.IsFunction = "Function" Then
				CallFunction(ProcedureName, ExportProcedureParameters, ExecutionParameters);
			Else
				CallProcedure(ProcedureName, ExportProcedureParameters, ExecutionParameters);
			EndIf;
			Result.Status = "Completed2";
		Except
			Result.Status = "Error";
			ErrorInfo = ErrorInfo();
			If ValueIsFilled(ExecutionParameters.RefinementErrors) Then
				Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
					ExecutionParameters.RefinementErrors);
				Try
					Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
				Except
					ErrorInfo = ErrorInfo();
				EndTry;
			EndIf;
			SetErrorProperties(Result, ErrorInfo);
			WriteLogEvent(NStr("vi = 'Các hoạt động kéo dài. Lỗi thực hiện';
								|ru = 'Длительные операции.Ошибка выполнения';
								|en = 'Long-running operations.Runtime error'; fa = 'Long-running operations.Runtime error';
								|it = 'Operazioni di lunga durata. Errore di esecuzione';
								|pl = 'Operacje długotrwałe. Błąd wykonania';
								|tr = 'Uzun süreli işlemler.Yürütme hatası'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , Result.DetailErrorDescription);
		EndTry;
		Result.Messages = GetUserMessages(True);
		For Each Message In MessagesBeforeCall Do
			Message.Message();
		EndDo;
		Return Result;
	EndIf;
	
	If ExecutionParameters.WaitCompletion <> Undefined
	   And StandardSubsystemsServer.ApplicationStartupLogicDisabled()
	   And Not StandardSubsystemsServer.ThisBackgroundJobSession() Then
		
		ExecutionParameters.WaitCompletion = Undefined;
	EndIf;
	
	// Executing in background.
	SafeMode = SafeMode();
	SetSafeModeDisabled(True);
	Try
		Job = RunBackgroundJobWithClientContext(ProcedureName,
			ExecutionParameters, ExportProcedureParameters, SafeMode,
			ExecutionParameters.WaitCompletion <> Undefined);
	Except
		Result.Status = "Error";
		ErrorInfo = ?(Job <> Undefined And Job.ErrorInfo <> Undefined,
			Job.ErrorInfo, ErrorInfo());
		SetErrorProperties(Result, ErrorInfo);
		If Not IsJobWithThisKeyValueAlreadyRunningError(Job, Result, ExecutionParameters) Then
			WriteLogEvent(NStr("vi = 'Các hoạt động kéo dài. Lỗi thực hiện';
								|ru = 'Длительные операции.Ошибка выполнения';
								|en = 'Long-running operations.Runtime error'; fa = 'Long-running operations.Runtime error';
								|it = 'Operazioni di lunga durata. Errore di esecuzione';
								|pl = 'Operacje długotrwałe. Błąd wykonania';
								|tr = 'Uzun süreli işlemler.Yürütme hatası'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , Result.DetailErrorDescription);
		EndIf;
		Return Result;
	EndTry;
	SetSafeModeDisabled(False);
	
	If Job <> Undefined And Job.ErrorInfo <> Undefined Then
		Result.Status = "Error";
		SetErrorProperties(Result, Job.ErrorInfo);
		Return Result;
	EndIf;
	
	Result.JobID = Job.UUID;
	If ProcedureName = MultithreadProcessMethodName()
	   And Not ExecutionParameters.IsThreadOfControlRestart Then
		ScheduleStartOfLongRunningOperationThreads(Result, ExportProcedureParameters[0]);
	EndIf;
	JobCompleted = False;
	
	Messages = New Array;
	If ExecutionParameters.WaitCompletion <> 0 Then
		While True Do
			Job = Job.WaitForExecutionCompletion(ExecutionParameters.WaitCompletion);
			If Job.State = BackgroundJobState.Active Then
				Break;
			EndIf;
			If ExecutionParameters.WaitCompletion = Undefined Then
				CommonClientServer.SupplementArray(Messages,
					Job.GetUserMessages(True));
			EndIf;
			CurrentResult = ActionCompleted(Result.JobID, Job);
			If CurrentResult.Status <> "Running" Then
				JobCompleted = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If JobCompleted Then
		If ExecutionParameters.WaitCompletion <> Undefined Then
			Messages = GetFromNotifications(True, Result.JobID, "Messages");
		EndIf;
		Result.Messages = Messages;
	EndIf;
	
	FillPropertyValues(Result, ActionCompleted(Result.JobID), , "Messages");
	Return Result;
	
EndFunction

// Returns a new structure for the ExecutionParameters parameter of the ExecuteInBackground function.
//
// If RunInBackground = False and RunNotInBackground = False, the job will be executed in the background if possible.
// The job with the session extensions runs in the main thread if any of the following conditions are met:
//  * the procedure is called in the file infobase through an external connection (this mode has no background job support);
//  * the application runs in the debug mode (see /C DebugMode command-line parameter) for configuration debugging purposes;
//  * the file infobase already has active background jobs (to avoid slow application response to user actions);
// 
//
// Parameters:
//   FormIdentifier - UUID - a UUID of the form to whose temporary storage 
//                                                  the procedure result must be placed.
//                      - Undefined - if a temporary storage does not need to be created automatically for the lifetime of
//                                       the form, and its address is supposed to be set explicitly in the ResultAddress property.
//                                       In this case, the temporary storage must be cleared explicitly upon processing the result of
//                                       a long-running operation using the DeleteFromTempStorage method.
// Returns:
//   Structure:
//     * FormIdentifier      - UUID - a UUID of the form 
//                                 containing the temporary storage where the procedure puts its result.
//     * AdditionalResult - Boolean     - the flag that indicates whether additional temporary storage is to be used to pass 
//                                 the result from the background job to the parent session. The default value is False.
//     * WaitCompletion       - Undefined - Wait till the background job is completed.
//                               - Number - Timeout in seconds.
//                                   If "0", don't wait till the background job is completed.
//                                   By default, "0.8" ("4" for low-speed connections).
//     * BackgroundJobDescription - String - the description of the background job. The default value is the procedure name.
//     * BackgroundJobKey      - String    - the unique key for active background jobs that have the same procedure name.
//                                              Not set by default.
//     * ResultAddress          - String - the address of the temporary storage to which the procedure
//                                           result must be placed. If the address is not set, it is generated automatically 
//                                           for the lifetime of the form using the FormIdentifier ID.
//     * RunInBackground           - Boolean - If True, the job always runs in the background, except for the following cases:
//                                  a) the procedure is called in the file infobase through an external connection 
//                                  (this mode has no background job support);
//                                  b) the function belongs to an external data processor module or an external report module.
//                                  In the file mode, if any other background jobs are running,
//                                  the new job is queued and does not start running until all the previous jobs are completed.
//                                  If False, the job will be executed in the background if possible. 
//     * RunNotInBackground1         - Boolean - If True, the job always runs naturally
//                                  without using background jobs.
//     * NoExtensions            - Boolean - If True, no configuration extensions
//                                  are attached to run the background job. Has priority over the RunNotInBackground parameter. 
//     * WithDatabaseExtensions  - Boolean - If True, the background job will run with the latest version of
//                                  the configuration extensions. Has priority over the RunNotInBackground parameter. 
//     * ExternalReportDataProcessor    - See NewDescriptionOfExternalProcessingReport
//                                - Undefined - If the passed method name starts with "ExternalReport" or "ExternalDataProcessor".
//                                  Calling the method requires the right to open external reports or
//                                  external data processors respectively. External reports and
//                                                 external data processors are attached with the unsafe action protection enabled.
//     * RefinementErrors          - String - If a non-empty string is passed, the error is prefixed with the passed string.
//                                   For example::
//                                   NStr("en = 'Failed to clear the address classifier due to:'; fa = 'Failed to clear the address classifier due to:'")
//
Function BackgroundExecutionParameters(Val FormIdentifier = Undefined) Export
	
	Result = CommonBackgroundExecutionParameters();
	AddExecutionParametersToReturnResult(Result, FormIdentifier);
	Result.Insert("AdditionalResult", False);
	Return Result;
	
EndFunction

// Constructor for the value of the Externalreferencesprocessing property See BackgroundExecutionParameters
// It is required when the method name is specified, which begins
// with "External report." or "External processing.".
// When the Execute mode is used on the Phone, and the data is not specified (Undefined),
// then an attempt is made to create an external report or processing object by its name,
// based on the fact that the object is already connected in the current session.
//
// Returns:
//  Structure:
//   * Data - BinaryData - To connect an object, you need the right
//      to open an external report interactively or process it, respectively.
//      An external report or processing is enabled with protection against dangerous actions.
//            - CatalogRef - a link to an additional report or processing
//      added by the administrator. A subsystem of additional processing reports is required.
//      To connect an object, you do not need the right to open an external report and
//      external processing interactively, since the object is connected according to the settings
//      made by the administrator, and also protection from dangerous actions is not required,
//      since the administrator has already checked and confirmed security.
//   * FullFileName - String - the default empty string.
//      If you specify the full name of the file that contains the specified
//      binary data of the external report or external processing, then this file
//      will be used when connecting instead of creating a temporary file.
//
Function NewDescriptionOfExternalProcessingReport() Export
	
	Result = New Structure;
	Result.Insert("Data", Undefined);
	Result.Insert("FullFileName", "");
	
	Return Result;
	
EndFunction

// Registers information about the long-running operation progress.
// Don't use it to pass long-running operation outcome in batches.
//
// To avoid excessive memory consumption and leaks, update the progress no more than 100 times per operation.
// If the progress is updated in less than 3 seconds after the last call, the new message overwrites the old one
//
// (if the Collaboration System is used, each new message is sent with at least 3-second delay).
// Before the progress is updated, all messages from the background job queue are sent.
// To display the progress for users, set OutputProgressBar to True in the standard idle form
//
// .
//
// 
//  (See TimeConsumingOperationsClient.IdleParameters)
//
// Parameters:
//  Percent                 - Number        - progress percentage.
//  Text                   - String       - details on the current action.
//  AdditionalParameters - Arbitrary - Any additional information to be passed to the client. 
//                                           Supports only simple (serializable to XML) values.
//                                           The maximum data size is specified in the "Result" parameter of
//                                           the "ServerNotifications.SendServerNotification" procedure.
//
Procedure ReportProgress(Val Percent = Undefined, Val Text = Undefined, Val AdditionalParameters = Undefined) Export
	
	If Not StandardSubsystemsCached.IsLongRunningOperationSession() Then
		Return;
	EndIf;
	
	ValueToPass = New Structure;
	If Percent <> Undefined Then
		ValueToPass.Insert("Percent", Percent);
	EndIf;
	If Text <> Undefined Then
		ValueToPass.Insert("Text", Text);
	EndIf;
	If AdditionalParameters <> Undefined Then
		ValueToPass.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	SendClientNotification("Progress", ValueToPass);
	
EndProcedure

// Reads the runtime information on the long-running operation 
// written by the TimeConsumingOperations.ReportProgress procedure.
//
// We recommend that you obtain the progress with the notification handler
// attached with TimeConsumingOperationsClient.WaitForCompletion.
//
// Parameters:
//   JobID - UUID - a background job ID.
//
// Returns:
//  Undefined - Progress details are not obtained. 
//  Structure:
//    * Percent                 - Number  - optional. Progress percentage.
//    * Text                   - String - optional. Details on the current action.
//    * AdditionalParameters - Arbitrary - optional. Any additional information.
// 
Function ReadProgress(Val JobID) Export
	
	Return GetFromNotifications(True, JobID, "Progress");
	
EndFunction

// Cancels background job execution by the passed ID.
// If the transactions are opened in long-running operation, the last open transaction will be rolled back.
//
// Thus, if the long-running operation is processing (recording) data, record in one transaction
// to cancel the whole operation completely (in this case the whole operation will be canceled).
// If it is enough not to cancel long-running operation completely, but to cancel it at the achieved level,
// then it is not required to open one long-running transaction.
// 
// Parameters:
//  JobID - UUID - Background job ID assigned when the long-running operation was started.
//                           See TimeConsumingOperations.ExecuteInBackground.
// 
Procedure CancelJobExecution(Val JobID) Export 
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	If SessionParameters.TimeConsumingOperations.CanceledJobs.Find(JobID) = Undefined Then
		Properties = New Structure(SessionParameters.TimeConsumingOperations);
		CanceledJobs = New Array(Properties.CanceledJobs);
		CanceledJobs.Add(JobID);
		Properties.CanceledJobs = New FixedArray(CanceledJobs);
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
	EndIf;
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Job = FindJobByID(JobID);
	If Job <> Undefined
	   And Job.State = BackgroundJobState.Active Then
		
		Try
			Job.Cancel();
		Except
			// The job might have been completed at that moment and no error occurred.
			WriteLogEvent(NStr("vi = 'Giao dịch kéo dài. Đã hủy thực hiện nhiệm vụ nền';
								|ru = 'Длительные операции.Отмена выполнения фонового задания';
								|en = 'Long-running operations.Cancel background job'; fa = 'Long-running operations.Cancel background job';
								|it = 'Operazioni a lungo termine. Annullamento del compito in background';
								|pl = 'Operacje długotrwałe.Anulowanie wykonywania zadania w tle';
								|tr = 'Uzun süreli işlemler. Arka plan iş yürütme iptali'", Common.DefaultLanguageCode()),
				EventLogLevel.Information, , , ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ProcessID = SessionParameters.TimeConsumingOperations.RunOnes.Get(JobID);
	If ProcessID <> Undefined Then
		CancelAllThreadsExecution(ProcessID);
		ActionCompleted(JobID);
	EndIf;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Checks the status of the background job by the passed ID.
// If the job crashed, it throws an exception with the text of the error occurred
// and a note, for example, "See details in the Event Log."
//
// Parameters:
//  JobID - UUID - a background job ID.
//  ExtendedResult - Boolean - If True, return a structure.
//
// Returns:
//  Boolean - Job runtime status.
//  Structure:
//   * Status      - String - "Running" if the job is running;
//                            "Completed " if the job has completed;
//                            "Error" if the job has completed with error;
//                            "Canceled" if job is canceled by a user or by an administrator.
//
//   * ErrorInfo - ErrorInfo - If Status = "Error" or Status = "Canceled".
//                        - Undefined - If Status <> "Error" and Status <> "Canceled".
//
//   * JobID - UUID - The last job ID if restarts occurred
//                              (for example, for long-running operations).
//                              Or the ID that was passed to the function if no restarts occurred.
//
//   * Job - Undefined   - Job was not found.
//             - BackgroundJob - Job is found.
//
//   * ErrorText                  - String - Obsolete.
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
//
Function JobCompleted(Val JobID, ExtendedResult = False) Export
	
	CommonClientServer.CheckParameter("TimeConsumingOperations.JobCompleted",
		"JobID", JobID, Type("UUID"));
	
	CommonClientServer.CheckParameter("TimeConsumingOperations.JobCompleted",
		"ExtendedResult", ExtendedResult, Type("Boolean"));
	
	Job = Undefined;
	Result = ActionCompleted(JobID, Job);
	
	If ExtendedResult Then
		Properties = New Structure;
		Properties.Insert("Status",                       Result.Status);
		Properties.Insert("ErrorText",                  "");
		Properties.Insert("ErrorInfo",           Result.ErrorInfo);
		Properties.Insert("BriefErrorDescription",   Result.BriefErrorDescription);
		Properties.Insert("DetailErrorDescription", Result.DetailErrorDescription);
		Properties.Insert("JobID",         LastID_(JobID));
		Properties.Insert("Job",                      Job);
	EndIf;
	
	If Result.Status = "Running" Then
		Return ?(ExtendedResult, Properties, False);
	ElsIf Result.Status = "Completed2" Then
		Return ?(ExtendedResult, Properties, True);
	EndIf;
	
	If Result.Status = "Canceled" Then
		ErrorText = NStr("vi = 'Đã hủy thao tác';
						|ru = 'Операция отменена';
						|en = 'Operation canceled'; fa = 'Operation canceled';
						|it = 'Operazione annullata';
						|pl = 'Operacja została anulowana';
						|tr = 'İşlem iptal edildi'");
		Try
			Raise ErrorText;
		Except
			If Not ExtendedResult Then
				Raise;
			EndIf;
			Properties.ErrorInfo = ErrorInfo();
		EndTry;
		
	ElsIf Job = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1
			           |
			           |Chi tiết kỹ thuật:
			           |%2
			           |
			           |Xem trong nhật ký sự kiện.';
			           |ru = '%1
			           |
			           |Технические подробности:
			           |%2
			           |
			           |См. также журнал регистрации.';
			           |en = '%1
			           |
			           |Technical details:
			           |%2
			           |
			           |See also the event log.'; fa = '%1
			           |
			           |Technical details:
			           |%2
			           |
			           |See also the event log.';
			           |it = '%1
			           |Dettagli tecnici:
			           |
			           |%2
			           |
			           |vedi anche il registro degli eventi.';
			           |pl = '%1
			           |
			           |Szczegóły techniczne:
			           |%2
			           |
			           |Zob. również dziennik rejestracji.';
			           |tr = '%1
			           |
			           |Teknik ayrıntılar:
			           |%2
			           |
			           |Ayrıca bkz. olay günlüğü.'"),
			Result.BriefErrorDescription,
			Result.DetailErrorDescription);
		Refinement = CommonClientServer.ExceptionClarification(Result.ErrorInfo);
		ForAdministrator = NStr("vi = 'Xem nhật ký sự kiện.';
								|ru = 'См. также журнал регистрации.';
								|en = 'Also, see the event log.'; fa = 'Also, see the event log.';
								|it = 'См. также журнал регистрации.';
								|pl = 'Also, see the event log.';
								|tr = 'Ayrıca kayıt defterine bkz'");
		Try
			Raise(Refinement.Text, Refinement.Category,, ForAdministrator, Result.ErrorInfo);
		Except
			If Not ExtendedResult Then
				Raise;
			EndIf;
			Properties.ErrorInfo = ErrorInfo();
		EndTry;
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1
			           |
			           |Chi tiết kỹ thuật:
			           |Lỗi thực thi nhiệm vụ trong nền %2 với id %3 vì lý do
			           |%4
			           |
			           |Xem thêm nhật ký.';
			           |ru = '%1
			           |
			           |Технические подробности:
			           |Ошибка выполнения фонового задания %2 с идентификатором %3 по причине
			           |%4
			           |
			           |См. также журнал регистрации.';
			           |en = '%1
			           |
			           |Technical details:
			           |An error occurred while executing background job %2 with ID %3. Reason:
			           |%4
			           |
			           |See the event log for details.'; fa = '%1
			           |
			           |Technical details:
			           |An error occurred while executing background job %2 with ID %3. Reason:
			           |%4
			           |
			           |See the event log for details.';
			           |it = '%1
			           |
			           | Dettagli tecnici:
			           | Errore di esecuzione del task in background %2 con identificativo %3 a causa di
			           |%4
			           |
			           | Vedi inoltre il registro.';
			           |pl = '%1
			           |
			           |Szczegóły techniczne:
			           |Błąd wykonania zadania w tle %2 z identyfikatorem %3 z powodu
			           |%4
			           |
			           |Patrz również dziennik rejestracji.';
			           |tr = '%1
			           |
			           |Teknik ayrıntılar:
			           |%3 kimlikli %2arka plan görevinin 
			           |%4
			           |
			           |nedenle yürütme hatası Ayrıca olay günlüğüne bakın.'"),
			Result.BriefErrorDescription,
			Job.MethodName,
			String(JobID),
			Result.DetailErrorDescription);
		Refinement = CommonClientServer.ExceptionClarification(Result.ErrorInfo);
		ForAdministrator = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi thực hiện nhiệm vụ nền %1 có tên định danh %2.
			           | Xem thêm nhật ký sự kiện.';
			           |ru = 'Ошибка выполнения фонового задания %1 с идентификатором %2.
			           |См. также журнал регистрации.';
			           |en = 'Error executing the background job ""%1"" (id %2).
			           |See also: Event log.'; fa = 'Error executing the background job ""%1"" (id %2).
			           |See also: Event log.';
			           |it = 'Ошибка выполнения фонового задания %1 с идентификатором %2.
			           |См. также журнал регистрации.';
			           |pl = 'Error executing the background job ""%1"" (id %2).
			           |See also: Event log.';
			           |tr = '%1 arka plan işi %2 kimliğiyle yürütülürken hata oluştu.
			           |Ayrıca kayıt defterine bkz.'"),
			Job.MethodName,
			String(JobID));
		Try
			Raise(Refinement.Text, Refinement.Category,, ForAdministrator, Result.ErrorInfo);
		Except
			If Not ExtendedResult Then
				Raise;
			EndIf;
			Properties.ErrorInfo = ErrorInfo();
		EndTry;
	EndIf;
	
	Properties.ErrorText = ErrorText;
	Return Properties;
	
EndFunction

// Gets user messages from a long-running operation background job.
//
// We recommend that you obtain the messages with the notification handler
// attached with TimeConsumingOperationsClient.WaitForCompletion.
// 
// Parameters:
//  ToDeleteGetting    - Boolean                  - the flag indicates whether the received messages need to be deleted.
//  JobID - UUID - the ID of the background job corresponding to a long-running 
//                                                   operation that generates messages intended for the user. 
//                                                   If not set, the messages intended for the user are returned
//                                                   from the current user session.
// 
// Returns:
//  FixedArray - UserMessage objects that were generated in the background job.
//
// Example:
//   Operation = TimeConsumingOperations.ExecuteInBackground(…);
//   …
//   Messages = TimeConsumingOperations.MessageToUsers(True, Operation.JobID);
//
Function UserMessages(ToDeleteGetting = False, JobID = Undefined) Export
	
	If ValueIsFilled(JobID) Then
		Return GetFromNotifications(ToDeleteGetting, JobID, "Messages");
	EndIf;
	
	Return GetUserMessages(ToDeleteGetting);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use ExecuteInBackground instead.
//
// Executes procedures in a background job.
// Similar to ExecuteInBackground but with less functionality. Intended for backward compatibility.
// 
// Parameters:
//  FormIdentifier     - UUID - the ID of the form 
//                           used to start the long-running operation. 
//  ExportProcedureName - String - the name of the export procedure 
//                           that must be run in background.
//  Parameters              - Structure - all parameters required 
//                           to execute the ExportProcedureName procedure.
//  JobDescription    - String - the description of the background job. 
//                           If JobDescription is not specified it is equal to ExportProcedureName. 
//  UseAdditionalTempStorage - Boolean - the flag indicates whether
//                           additional temporary storage is to be used to pass data from the background job
//                           to the parent session. The default value is False.
//
// Returns:
//  Structure              - Job runtime parameters: 
//   * StorageAddress  - String     - the address of the temporary storage where the job result must be
//                                    stored;
//   * StorageAddressAdditional - String - the address of the additional temporary storage
//                                    where the job result must be stored (can only be used 
//                                    when UseAdditionalTempStorage is set);
//   * JobID - UUID - the unique ID of the running background job;
//                          - Undefined - Background job was not started.
//   * JobCompleted - Boolean - True if the job is completed successfully during the function call.
// 
Function StartBackgroundExecution(Val FormIdentifier, Val ExportProcedureName, Val Parameters,
	Val JobDescription = "", UseAdditionalTempStorage = False) Export
	
	CheckNameOfProcedure(ExportProcedureName,
		"ExportProcedureName", "TimeConsumingOperations.StartBackgroundExecution");
	
	StorageAddress = PutToTempStorage(Undefined, FormIdentifier);
	
	Result = New Structure;
	Result.Insert("StorageAddress",       StorageAddress);
	Result.Insert("JobCompleted",     False);
	Result.Insert("JobID", Undefined);
	
	If Not ValueIsFilled(JobDescription) Then
		JobDescription = ExportProcedureName;
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(Parameters);
	ExportProcedureParameters.Add(StorageAddress);
	
	If UseAdditionalTempStorage Then
		StorageAddressAdditional = PutToTempStorage(Undefined, FormIdentifier);
		ExportProcedureParameters.Add(StorageAddressAdditional);
	EndIf;
	
	JobsRunning = 0;
	If Common.FileInfobase()
		And Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		JobsRunning = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	
	If Common.DebugMode()
	 Or StandardSubsystemsServer.ApplicationStartupLogicDisabled()
	 Or JobsRunning > 0 Then
		Common.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters);
		Result.JobCompleted = True;
	Else
		Timeout = ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 2);
		ExecutionParameters = BackgroundExecutionParameters(Undefined);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		SafeMode = SafeMode();
		SetSafeModeDisabled(True);
		Job = RunBackgroundJobWithClientContext(ExportProcedureName,
			ExecutionParameters, ExportProcedureParameters, SafeMode);
		SetSafeModeDisabled(False);
		
		Job = Job.WaitForExecutionCompletion(Timeout);
		
		Status = ActionCompleted(Job.UUID);
		Result.JobCompleted = Status.Status = "Completed2";
		Result.JobID = Job.UUID;
	EndIf;
	
	If UseAdditionalTempStorage Then
		Result.Insert("StorageAddressAdditional", StorageAddressAdditional);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  JobID - UUID
//  Job - BackgroundJob - Found background job (the return value).
//          - Undefined - Background job was not found.
//
// Returns:
//   See OperationNewRuntimeResult
//
Function ActionCompleted(Val JobID, Job = Undefined) Export
	
	CommonClientServer.CheckParameter("TimeConsumingOperations.ActionCompleted",
		"JobID", JobID, Type("UUID"));
	
	Result = OperationNewRuntimeResult();
	LastID_ = LastID_(JobID);
	
	Job = FindJobByID(LastID_);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Job = Undefined Then
		ResultFromNotification = GetFromNotifications(False,
			JobID, "TimeConsumingOperationCompleted");
		If ResultFromNotification <> Undefined Then
			FillPropertyValues(Result, ResultFromNotification);
			SetCompletionForThreadOfControl(JobID, Result);
			Return Result;
		EndIf;
		If IsThreadOfControlRestarted(JobID, Job) Then
			Return Result;
		EndIf;
		ErrorText = NStr("vi = 'Chưa thực hiện giao dịch do kết thúc khẩn cấp nhiệm vụ nền.';
						|ru = 'Операция не выполнена из-за аварийного завершения фонового задания.';
						|en = 'Cannot perform the operation due to abnormal termination of a background job.'; fa = 'Cannot perform the operation due to abnormal termination of a background job.';
						|it = 'Operazione non compilata a causa della chiusura anomala del task in background.';
						|pl = 'Operacja nie jest wykonana z powodu awaryjnego zakończenia zadania w tle.';
						|tr = 'Arka plan görevinin çökmesi nedeniyle işlem başarısız oldu.'");
		ClarificationForAdmin = NStr("vi = 'Nhiệm vụ nền không tồn tại';
									|ru = 'Фоновое задание не существует';
									|en = 'The background job does not exist'; fa = 'The background job does not exist';
									|it = 'Compito in background inesistente';
									|pl = 'Zadania w tle nie istnieje';
									|tr = 'Arka plan işi mevcut değil'") + ": "
			+ String(LastID_);
		Try
			Raise(ErrorText,,, ClarificationForAdmin);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
		SetErrorProperties(Result, ErrorInfo);
		Result.Status = "Error";
		SetCompletionForThreadOfControl(JobID, Result);
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Active
	 Or IsThreadOfControlRestarted(JobID, Job) Then
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Canceled Then
		If SessionParameters.TimeConsumingOperations.CanceledJobs.Find(LastID_) = Undefined Then
			Result.Status = "Error";
			If Job.ErrorInfo <> Undefined Then
				Refinement = CommonClientServer.ExceptionClarification(Job.ErrorInfo,
					NStr("vi = 'Người quản trị đã hủy bỏ thao tác.';
						|ru = 'Операция отменена администратором.';
						|en = 'Operation canceled by administrator.'; fa = 'Operation canceled by administrator.';
						|it = 'Operazione annullata dall''amministratore.';
						|pl = 'Operacja została anulowana przez administratora.';
						|tr = 'İşlem yönetici tarafından iptal edildi.'"));
				Try
					Raise(Refinement.Text, Refinement.Category,,, Job.ErrorInfo);
				Except
					ErrorInfo = ErrorInfo();
				EndTry;
				SetErrorProperties(Result, ErrorInfo);
			EndIf;
		Else
			Result.Status = "Canceled";
		EndIf;
		SetCompletionForThreadOfControl(JobID, Result);
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Failed 
		Or Job.State = BackgroundJobState.Canceled Then
		
		Result.Status = "Error";
		If Job.ErrorInfo <> Undefined Then
			SetErrorProperties(Result, Job.ErrorInfo);
		EndIf;
		SetCompletionForThreadOfControl(JobID, Result);
		Return Result;
	EndIf;
	
	Result.Status = "Completed2";
	SetCompletionForThreadOfControl(JobID, Result);
	Return Result;
	
EndFunction

Procedure RunDataProcessorObjectModuleProcedure(Parameters, StorageAddress) Export 
	
	If SafeMode() <> False Then
		SafeMode = SafeMode();
	ElsIf Parameters.Property("SafeMode") And Parameters.SafeMode <> False Then
		SafeMode = Parameters.SafeMode;
	Else
		SafeMode = False;
	EndIf;
	
	If Parameters.IsExternalDataProcessor Then
		Ref = CommonClientServer.StructureProperty(Parameters, "AdditionalDataProcessorRef");
		If ValueIsFilled(Ref) And Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			DataProcessor = Common.CommonModule("AdditionalReportsAndDataProcessors").ExternalDataProcessorObject(Ref);
		Else
			VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
			DataProcessor = ExternalDataProcessors.Create(Parameters.DataProcessorName, SafeMode);
		EndIf;
	Else
		DataProcessor = DataProcessors[Parameters.DataProcessorName].Create();
	EndIf;
	
	CheckNameOfProcedure(Parameters.MethodName,
		"Parameters.MethodName", "RunDataProcessorObjectModuleProcedure",, DataProcessor);
	
	If SafeMode() = False And SafeMode <> False Then
		SetSafeMode(SafeMode);
	EndIf;
	
	Try
		FullProcedureName = DataProcessor.Metadata().FullName() + "." + Parameters.MethodName;
	Except
		FullProcedureName = Parameters.MethodName;
	EndTry;
	
	SetFullNameOfAppliedProcedure(FullProcedureName);
	
	MethodParameters = New Array;
	MethodParameters.Add(Parameters.ExecutionParameters);
	MethodParameters.Add(StorageAddress);
	Common.ExecuteObjectMethod(DataProcessor, Parameters.MethodName, MethodParameters);
	
EndProcedure

Procedure RunReportObjectModuleProcedure(Parameters, StorageAddress) Export
	
	If SafeMode() <> False Then
		SafeMode = SafeMode();
	ElsIf Parameters.Property("SafeMode") And Parameters.SafeMode <> False Then
		SafeMode = Parameters.SafeMode;
	Else
		SafeMode = False;
	EndIf;
	
	If Parameters.IsExternalReport Then
		VerifyAccessRights("InteractiveOpenExtReports", Metadata);
		Report = ExternalReports.Create(Parameters.ReportName, SafeMode);
	Else
		Report = Reports[Parameters.ReportName].Create();
	EndIf;
	
	CheckNameOfProcedure(Parameters.MethodName,
		"Parameters.MethodName", "RunReportObjectModuleProcedure",, Report);
	
	If SafeMode() = False And SafeMode <> False Then
		SetSafeMode(SafeMode);
	EndIf;
	
	Try
		FullProcedureName = Report.Metadata().FullName() + "." + Parameters.MethodName;
	Except
		FullProcedureName = Parameters.MethodName;
	EndTry;
	
	SetFullNameOfAppliedProcedure(FullProcedureName);
	
	MethodParameters = New Array;
	MethodParameters.Add(Parameters.ExecutionParameters);
	MethodParameters.Add(StorageAddress);
	Common.ExecuteObjectMethod(Report, Parameters.MethodName, MethodParameters);
	
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "TimeConsumingOperations" Then
		Properties = New Structure;
		Properties.Insert("CanceledJobs", New FixedArray(New Array));
		Properties.Insert("RunOnes", New FixedMap(New Map));
		Properties.Insert("Restarted", New FixedMap(New Map));
		Properties.Insert("MainJobID");
		Properties.Insert("ReceivedNotifications", New FixedMap(New Map));
		Properties.Insert("AddedOn", '00010101');
		Properties.Insert("DateAddedMilliseconds", 0);
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
		SpecifiedParameters.Add("TimeConsumingOperations");
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	Notification = ServerNotifications.NewServerNotification(NameOfAlert());
	Notification.NotificationSendModuleName  = "";
	Notification.NotificationReceiptModuleName = "TimeConsumingOperationsClient";
	Notifications.Insert(Notification.Name, Notification);
	
	Notification = ServerNotifications.NewServerNotification(NameOfAdditionalNotification());
	Notification.NotificationSendModuleName  = "TimeConsumingOperations";
	Notification.NotificationReceiptModuleName = "TimeConsumingOperationsClient";
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

// Returns the maximum number of threads allowed for all multithreaded long-running operations
// considering main threads.
//
// For example, if there are 10 threads and 2 operations,
// you will have 2 main threads and 8 worker threads.
//
// If there are 3 threads and 2 operations,
// you will have 2 main threads and 1 worker thread,
// with 1 main thread also functioning as a worker thread.
//
// If there are 5 threads and 7 operations,
// you will have 7 main threads and 0 worker threads,
// with each main thread also functioning as a worker thread.
//
// If there is 1 thread,
// you will have 0 worker threads,
// and the main thread will also act as a worker thread.
//
// Returns:
//  Number - number of threads.
//
Function AllowedNumberofThreads() Export
	
	If Common.DataSeparationEnabled()
	 Or Common.FileInfobase() Then
		Return 1;
	EndIf;
	
	AllowedNumberofThreads = Constants.LongRunningOperationsThreadCount.Get();
	
	If AllowedNumberofThreads > 0 Then
		Return AllowedNumberofThreads;
	EndIf;
	
	// The default value: Main thread and 3 child threads.
	Return 4;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// See StandardSubsystemsServer.OnSendServerNotification
Procedure OnSendServerNotification(NameOfAlert, ParametersVariants) Export
	
	If NameOfAlert <> NameOfAdditionalNotification() Then
		Return;
	EndIf;
	
	DeleteNonExistingThreads();
	
EndProcedure

// Returns:
//  Structure:
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//
//   * ErrorInfo    - ErrorInfo - If Status = "Error".
//                           - Undefined - If Status <> "Error".
//
//   * Progress - See ReadProgress
//
//   * Messages - Undefined
//               - FixedArray of UserMessage
//
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
//   
Function OperationNewRuntimeResult() Export
	
	Result = New Structure;
	Result.Insert("Status", "Running");
	Result.Insert("ErrorInfo", Undefined);
	Result.Insert("BriefErrorDescription", "");
	Result.Insert("DetailErrorDescription", "");
	Result.Insert("Progress", Undefined);
	Result.Insert("Messages", Undefined);
	
	Return Result;
	
EndFunction

// Parameters:
//  JobID - UUID
//
// Returns:
//  UUID
//
Function LastID_(JobID)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Last_3 = SessionParameters.TimeConsumingOperations.Restarted.Get(JobID);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If Last_3 = Undefined Then
		Return JobID;
	EndIf;
	
	Return Last_3;
	
EndFunction

Function MainJobID(BackgroundJob, ProcessID = Undefined)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If ValueIsFilled(ProcessID) Then
		Id = FirstIDOfThreadOfControlJob(ProcessID);
		Properties = New Structure(SessionParameters.TimeConsumingOperations);
		Properties.MainJobID = Id;
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
	Else
		Id = SessionParameters.TimeConsumingOperations.MainJobID;
		If Not ValueIsFilled(Id) Then
			Id = BackgroundJob.UUID;
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Id;
	
EndFunction

// Parameters:
//  Properties - Structure:
//   * BriefErrorDescription
//   * DetailErrorDescription
//  Error - ErrorInfo
//
Procedure SetErrorProperties(Properties, Error)
	
	Properties.ErrorInfo = Error;
	
	BriefErrorDescription = ErrorProcessing.BriefErrorDescription(Error);
	DetailErrorDescription = ErrorProcessing.DetailErrorDescription(Error);
	
	Properties.BriefErrorDescription = CommonClientServer.ReplaceProhibitedXMLChars(
		BriefErrorDescription);
	
	Properties.DetailErrorDescription = CommonClientServer.ReplaceProhibitedXMLChars(
		DetailErrorDescription);
	
EndProcedure

// Multi-threaded operation parameter constructor.
// 
// Parameters:
//   ProcessID - UUID
//   SavedParameters1 - Undefined, Structure
// 
// Returns:
//  Structure:
//   * ProcessID - UUID
//   * MethodName - String
//   * IsFunction - String
//   * ExecutionParameters - See FunctionExecutionParameters
//   * MethodParameters - Number, Structure
//
Function MultithreadOperationParameters(ProcessID, SavedParameters1 = Undefined) 
	
	Result = New Structure;
	Result.Insert("ProcessID", ProcessID);
	Result.Insert("MethodName",             "");
	Result.Insert("IsFunction",            "Procedure");
	Result.Insert("ExecutionParameters",   FunctionExecutionParameters(Undefined));
	Result.Insert("MethodParameters",       0);
	
	If TypeOf(SavedParameters1) = Type("Structure") Then
		FillPropertyValues(Result, SavedParameters1);
	EndIf;
	
	Return Result;
	
EndFunction

// See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	CheckParameters = Parameters.Get( // See TimeConsumingOperationsClient.
		"StandardSubsystems.Core.LongRunningOperationCheckParameters");
	
	If CheckParameters = Undefined Then
		Return;
	EndIf;
	
	Results.Insert("StandardSubsystems.Core.LongRunningOperationCheckResult",
		LongRunningOperationCheckResult(CheckParameters));
	
EndProcedure

// Only for the OnReceiptRecurringClientDataOnServer procedure.
//
// Parameters:
//  Parameters - See TimeConsumingOperationsClient.
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - UUID - Job ID
//   * Value - See OperationNewRuntimeResult
//  
Function LongRunningOperationCheckResult(Parameters) Export
	
	Result = New Map;
	For Each JobID In Parameters.JobsToCheck Do
		// @skip-check query-in-loop - the branch with the request is rarely called (only when the control thread is restarted)
		OperationResult = ActionCompleted(JobID);
		OperationResult.Messages = UserMessagesDetails(OperationResult.Messages);
		Result.Insert(JobID, OperationResult);
	EndDo;
	
	For Each JobID In Parameters.JobsToCancel Do
		CancelJobExecution(JobID);
		OperationResult = OperationNewRuntimeResult();
		OperationResult.Status = "Canceled";
		Result.Insert(JobID, OperationResult);
	EndDo;
	
	Return Result;
	
EndFunction

// For the LongRunningOperationCheckResult procedure and the ShouldSkipNotification function.
//
// Parameters:
//  Messages - FixedArray of UserMessage
// 
// Returns:
//  FixedArray of See UserMessageDetails
//
Function UserMessagesDetails(Messages)
	
	If Not ValueIsFilled(Messages) Then
		Return Messages;
	EndIf;
	
	Result = New Array;
	For Each Message In Messages Do
		Result.Add(UserMessageDetails(Message));
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

// Converts UserMessage into a structure.
//
// Parameters:
//  Message - UserMessage
//
// Returns:
//  Structure:
//   * TargetID - UUID
//   * DataKey - AnyRef
//                - InformationRegisterRecordKey
//                - AccumulationRegisterRecordKey
//                - AccountingRegisterRecordKey
//                - CalculationRegisterRecordKey
//   * Field - String
//   * DataPath - String
//   * Text - String
//
Function UserMessageDetails(Message)
	
	Result = New Structure;
	Result.Insert("TargetID", Message.TargetID);
	Result.Insert("DataKey",              Message.DataKey);
	Result.Insert("Field",                    Message.Field);
	Result.Insert("DataPath",             Message.DataPath);
	Result.Insert("Text",
		CommonClientServer.ReplaceProhibitedXMLChars(Message.Text));
	
	Return Result;
	
EndFunction

Function RunBackgroundJobWithClientContext(ProcedureName,
			ExecutionParameters, ProcedureParameters = Undefined, SafeMode = False, ShouldSendNotifications = False)
	
	BackgroundJobKey = ExecutionParameters.BackgroundJobKey;
	BackgroundJobDescription = ?(IsBlankString(ExecutionParameters.BackgroundJobDescription),
		ProcedureName, ExecutionParameters.BackgroundJobDescription);
	
	ClientParameters = StandardSubsystemsServer.ClientParametersAtServer(False);
	If ShouldSendNotifications And Not ValueIsFilled(ClientParameters.Get("ParentSessionKey")) Then
		ClientParameters = New Map(ClientParameters);
		ClientParameters.Insert("ParentSessionKey", ServerNotifications.SessionKey());
		ClientParameters = New FixedMap(ClientParameters);
	EndIf;
	
	StartupStack = "";
	If Common.CommonCoreParameters().ShouldIncludeFullStackInLongRunningOperationErrors Then
		Try
			Raise NStr("vi = 'Khởi động nhiệm vụ nền giao dịch kéo dài:';
						|ru = 'Запуск фонового задания длительной операции:';
						|en = 'Starting the background job of a long-running operation:'; fa = 'Starting the background job of a long-running operation:';
						|it = 'Запуск фонового задания длительной операции:';
						|pl = 'Starting the background job of a long-running operation:';
						|tr = 'Uzun süren bir işlem için bir arka plan işi çalıştırmak:'");
		Except
			StartupStack = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
	EndIf;
	
	AllParameters = New Structure;
	AllParameters.Insert("ProcedureName",       ProcedureName);
	AllParameters.Insert("ProcedureParameters", ProcedureParameters);
	AllParameters.Insert("ClientParametersAtServer", ClientParameters);
	AllParameters.Insert("ExecutionParameters", ExecutionParameters);
	AllParameters.Insert("SafeMode",     SafeMode);
	AllParameters.Insert("StartupStack",         StartupStack);
	
	If Not ExecutionParameters.NoExtensions
	   And Not ExecutionParameters.WithDatabaseExtensions Then
		Catalogs.ExtensionsVersions.InsertARegisteredSetOfInstalledExtensions(AllParameters);
	EndIf;
	
	BackgroundJobProcedureParameters = New Array;
	BackgroundJobProcedureParameters.Add(AllParameters);
	
	Return RunBackgroundJob(ExecutionParameters,
		BackgroundJobProcedureParameters, BackgroundJobKey, BackgroundJobDescription);
	
EndFunction

// Intended for function "ExecuteInBackground".
Function IsJobWithThisKeyValueAlreadyRunningError(Job, Result, ExecutionParameters)
	
	If Job <> Undefined
	 Or Not ValueIsFilled(ExecutionParameters.BackgroundJobKey) Then
		Return False;
	EndIf;
	
	BriefErrorDescription = ErrorProcessing.BriefErrorDescription(Result.ErrorInfo);
	// ACC:1405-off - Intended for prompt identification of the error cause.
	SearchString = NStr("vi = 'Đã thực hiện nhiệm vụ với giá trị khóa như vậy';
						|ru = 'Задание с таким значением ключа уже выполняется';
						|en = 'A job with the same key value is already running'; fa = 'A job with the same key value is already running';
						|it = 'A job with the same key value is already running';
						|pl = 'A job with the same key value is already running';
						|tr = 'Bu anahtar değerine sahip bir görev hali hazırda uygulandı'");
	// ACC:1405-on
	If ValueIsFilled(SearchString) And StrStartsWith(BriefErrorDescription, SearchString) Then
		Return True;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("MethodName", NameOfLongRunningOperationBackgroundJobProcedure());
	Filter.Insert("Key",      ExecutionParameters.BackgroundJobKey);
	Filter.Insert("State", BackgroundJobState.Active);
	
	FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	Return FoundJobs.Count() > 1;
	
EndFunction

// Returns True if the current session if a background job session of a long-running operation
// or background job method name is not specified in the scheduled jobs.
// 
//
Function ShouldSkipHandlerBeforeAppStartup() Export
	
	If CurrentRunMode() <> Undefined Then
		Return False;
	EndIf;
	
	BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	If BackgroundJob = Undefined Then
		Return False;
	EndIf;
	
	MethodName = Lower(BackgroundJob.MethodName);
	If MethodName = Lower(NameOfLongRunningOperationBackgroundJobProcedure()) Then
		Return True;
	EndIf;
	
	For Each ScheduledJob In Metadata.ScheduledJobs Do
		If MethodName = Lower(ScheduledJob.MethodName) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function NameOfLongRunningOperationBackgroundJobProcedure()
	
	Return "TimeConsumingOperations.ExecuteWithClientContext";
	
EndFunction

// Returns:
//  String
//
Function FullNameOfLongRunningOperationAppliedProcedure() Export
	
	If Not StandardSubsystemsCached.IsLongRunningOperationSession() Then
		Return "";
	EndIf;
	
	FullName = StandardSubsystemsServer.ClientParametersAtServer(False).Get(
		"FullNameOfLongRunningOperationAppliedProcedure");
	
	Return String(FullName);
	
EndFunction

Procedure SetFullNameOfAppliedProcedure(FullProcedureName)
	
	If Not StandardSubsystemsCached.IsLongRunningOperationSession() Then
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ClientParameters = New Map(SessionParameters.ClientParametersAtServer);
	ClientParameters.Insert("FullNameOfLongRunningOperationAppliedProcedure", FullProcedureName);
	SessionParameters.ClientParametersAtServer = New FixedMap(ClientParameters);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Continuation of the RunBackgroundJobWithClientContext procedure.
Procedure ExecuteWithClientContext(AllParameters) Export
	
	ClientParameters = AllParameters.ClientParametersAtServer;
	If ValueIsFilled(ClientParameters.Get("ParentSessionKey"))
	   And Not ValueIsFilled(ClientParameters.Get("MultithreadProcessJobID")) Then
		
		BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
		If BackgroundJob <> Undefined
		   And AllParameters.ProcedureName = MultithreadProcessMethodName() Then
			ClientParameters = New Map(ClientParameters);
			ProcessID = AllParameters.ProcedureParameters[0].ProcessID;
			ClientParameters.Insert("MultithreadProcessJobID",
				MainJobID(BackgroundJob, ProcessID));
			ClientParameters = New FixedMap(ClientParameters);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	SessionParameters.ClientParametersAtServer = ClientParameters;
	Catalogs.ExtensionsVersions.RestoreTheRegisteredCompositionOfInstalledExtensions(AllParameters);
	Catalogs.ExtensionsVersions.RegisterExtensionsVersionUsage();
	SetPrivilegedMode(False);
	
	If SafeMode() = False And AllParameters.SafeMode <> False Then
		If Upper(AllParameters.ProcedureName) = Upper("TimeConsumingOperations.RunDataProcessorObjectModuleProcedure")
		 Or Upper(AllParameters.ProcedureName) = Upper("TimeConsumingOperations.RunReportObjectModuleProcedure") Then
			
			AllParameters.ProcedureParameters[0].Insert("SafeMode", AllParameters.SafeMode);
		Else
			SetSafeMode(AllParameters.SafeMode);
		EndIf;
	EndIf;
	
	SetFullNameOfAppliedProcedure(AllParameters.ProcedureName);
	Result = OperationNewRuntimeResult();
	Try
		ExecutionParameters = AllParameters.ExecutionParameters;
		If ExecutionParameters.IsFunction = "Function" Then
			CallFunction(AllParameters.ProcedureName, AllParameters.ProcedureParameters, ExecutionParameters);
		Else
			CallProcedure(AllParameters.ProcedureName, AllParameters.ProcedureParameters, ExecutionParameters);
		EndIf;
		Result.Status = "Completed2";
	Except
		Result.Status = "Error";
		ErrorInfo = ErrorInfo();
		SystemInfo = New SystemInfo;
		StartupStack = AllParameters.StartupStack;
		StartupStack = ?(ValueIsFilled(StartupStack),
			CommonClientServer.ReplaceProhibitedXMLChars(StartupStack), Undefined);
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
			ExecutionParameters.RefinementErrors);
		Try
			Raise(Refinement.Text, Refinement.Category,, StartupStack, ErrorInfo);
		Except
			ClarifiedErrorInfo = ErrorInfo();
			SetErrorProperties(Result, ClarifiedErrorInfo);
			SetFullNameOfAppliedProcedure(NameOfLongRunningOperationBackgroundJobProcedure());
			SendClientNotification("TimeConsumingOperationCompleted", Result);
			Raise;
		EndTry;
	EndTry;
	
	SetFullNameOfAppliedProcedure(NameOfLongRunningOperationBackgroundJobProcedure());
	SendClientNotification("TimeConsumingOperationCompleted", Result);
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.StartAccessUpdate();
	EndIf;
	
EndProcedure

Procedure CallProcedure(ProcedureName, CallParameters, ExecutionParameters)
	
	NameParts = StrSplit(ProcedureName, ".");
	IsDataProcessorModuleProcedure = (NameParts.Count() = 4) And Upper(NameParts[2]) = "OBJECTMODULE";
	If Not IsDataProcessorModuleProcedure Then
		CheckNameOfProcedure(ProcedureName, "ProcedureName", "CallProcedure");
		Common.ExecuteConfigurationMethod(ProcedureName, CallParameters);
		Return;
	EndIf;
	
	DataProcessorReportObject = DataProcessorReportObject(ProcedureName,
		NameParts, ExecutionParameters, "ProcedureName", "CallProcedure");
	
	CheckNameOfProcedure(NameParts[3], "ProcedureName", "CallProcedure",, DataProcessorReportObject);
	
	Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], CallParameters);
	
EndProcedure

Function DataProcessorReportObject(Name, NameParts, ExecutionParameters, MethodParameterName, MethodName)
	
	IsDataProcessor = Upper(NameParts[0]) = "DATAPROCESSOR";
	IsReport = Upper(NameParts[0]) = "REPORT";
	If IsDataProcessor Or IsReport Then
		ObjectManager = ?(IsReport, Reports, DataProcessors);
		Return ObjectManager[NameParts[1]].Create();
	EndIf;
	
	IsExternalDataProcessor = Upper(NameParts[0]) = "EXTERNALDATAPROCESSOR";
	IsExternalReport = Upper(NameParts[0]) = "EXTERNALREPORT";
	If IsExternalDataProcessor Or IsExternalReport Then
		Return ExternalDataProcessorReportObject(IsExternalReport, ExecutionParameters, NameParts[1]);
	EndIf;
	
	Raise(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Sai định dạng tham số %1 (%2) trong %3.';
			|ru = 'Неверный формат параметра %1 (%2) в %3.';
			|en = 'Incorrect format of parameter %1 in %3: %2.'; fa = 'Incorrect format of parameter %1 in %3: %2.';
			|it = 'Incorrect format of parameter %1 in %3: %2.';
			|pl = 'Incorrect format of parameter %1 in %3: %2.';
			|tr = '%3 içinde %1(%2) parametre formatı geçersiz.'"),
		Name, MethodParameterName, MethodName),
		ErrorCategory.ConfigurationError);
	
EndFunction

Function ExternalDataProcessorReportObject(IsExternalReport, ExecutionParameters, NameOfAttachedReportProcessor)
	
	ObjectManager = ?(IsExternalReport, ExternalReports, ExternalDataProcessors);
	ExternalReportDataProcessor = ExecutionParameters.ExternalReportDataProcessor;
	
	If ExternalReportDataProcessor = Undefined Then
		If ExecutionParameters.RunNotInBackground1 Then
			Return ObjectManager.Create(NameOfAttachedReportProcessor, SafeMode());
		EndIf;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для вызова процедуры внешнего отчета или внешней обработки в фоне
			           |требуется заполнить свойство %1 параметра %2.';
			           |vi = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter must be filled in.';
			           |en = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter must be filled in.'; fa = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter must be filled in.';
			           |it = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter must be filled in.';
			           |pl = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter must be filled in.';
			           |tr = 'Harici rapor veya harici veri işlem prosedürünü arka planda 
			           | çağırmak için, %2 parametresinin %1 özelliğinin doldurulması gerekir.'"),
			"ExternalReportDataProcessor", "ExecutionParameters");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	SafeMode = SafeMode();
	If SafeMode <> False Then
		SetSafeModeDisabled(True);
	EndIf;
	
	If TypeOf(ExternalReportDataProcessor.Data) <> Type("BinaryData") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		Return ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorObject(
			ExternalReportDataProcessor.Data);
	EndIf;
	
	AccessRightName = ?(IsExternalReport, "InteractiveOpenExtReports", "InteractiveOpenExtDataProcessors");
	VerifyAccessRights(AccessRightName, Metadata);
	
	BinaryData = ExternalReportDataProcessor.Data;
	FullFileName = ExternalReportDataProcessor.FullFileName;
	If Not ValueIsFilled(FullFileName) Then
		CreateTempFile = True;
	Else
		CreateTempFile = False;
		Try
			FileBinaryData = New BinaryData(FullFileName);
		Except
			CreateTempFile = True;
		EndTry;
		If Not CreateTempFile Then
			CreateTempFile = FileBinaryData <> ExternalReportDataProcessor.Data;
		EndIf;
	EndIf;
	
	If CreateTempFile Then
		FullFileName = GetTempFileName();
		BinaryData.Write(FullFileName);
	EndIf;
	
	Try
		DataProcessorReportObject = ObjectManager.Create(FullFileName, SafeMode);
	Except
		If CreateTempFile Then
			DeleteFiles(FullFileName);
		EndIf;
		If SafeMode <> False Then
			SetSafeModeDisabled(False);
		EndIf;
		Raise;
	EndTry;
	If CreateTempFile Then
		DeleteFiles(FullFileName);
	EndIf;
	If SafeMode <> False Then
		SetSafeModeDisabled(False);
	EndIf;
	
	Return DataProcessorReportObject;
	
EndFunction

Procedure CallFunction(FunctionName, ProcedureParameters, ExecutionParameters)
	
	NameParts = StrSplit(FunctionName, ".");
	IsDataProcessorModuleProcedure = (NameParts.Count() = 4) And Upper(NameParts[2]) = "OBJECTMODULE";
	If Not IsDataProcessorModuleProcedure Then
		CheckNameOfProcedure(FunctionName, "FunctionName", "CallFunction");
		Result = Common.ExecuteConfigurationMethod(FunctionName, ProcedureParameters, True);
		SetFunctionCallResult(Result, ExecutionParameters);
		Return;
	EndIf;
	
	DataProcessorReportObject = DataProcessorReportObject(FunctionName,
		NameParts, ExecutionParameters, "FunctionName", "CallFunction");
	
	CheckNameOfProcedure(NameParts[3], "FunctionName", "CallFunction",, DataProcessorReportObject);
	
	Result = Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], ProcedureParameters, True);
	SetFunctionCallResult(Result, ExecutionParameters);
	
EndProcedure

Procedure SetFunctionCallResult(Result, ExecutionParameters)
	
	If ExecutionParameters.MultithreadLongRunningOperationThreadOfControlProperties = Undefined Then
		PutToTempStorage(Result, ExecutionParameters.ResultAddress);
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	SetThreadResult(ExecutionParameters.MultithreadLongRunningOperationThreadOfControlProperties, Result);
	
EndProcedure

// Parameters:
//  JobID - UUID, String
//
// Returns:
//  BackgroundJob, Undefined
//
Function FindJobByID(Val JobID)
	
	If TypeOf(JobID) = Type("String") Then
		JobID = New UUID(JobID);
	EndIf;
	
	Job = BackgroundJobs.FindByUUID(JobID);
	Return Job;
	
EndFunction

Function GetFromNotifications(ShouldSkipReceivedNotifications, JobID, NotificationsType)
	
	If NotificationsType = "Messages" Then
		WritePendingUserMessages(JobID);
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	LastAlert = Undefined;
	If ShouldSkipReceivedNotifications Then
		LastNotifications = SessionParameters.TimeConsumingOperations.ReceivedNotifications.Get(JobID);
		If LastNotifications <> Undefined Then
			LastAlert = LastNotifications[NotificationsType];
		EndIf;
	EndIf;
	Notifications = ServerNotifications.ServerNotificationForClient(JobID,
		NotificationTypeID(NotificationsType), LastAlert);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	NotificationsMessages = New Array;
	If NotificationsType = "Messages" Then
		Result = New FixedArray(NotificationsMessages);
	Else
		Result = Undefined;
	EndIf;
	
	For Each Notification In Notifications Do
		Parameters = Notification.Content.Result;
		If TypeOf(Parameters) <> Type("Structure")
		 Or Not Parameters.Property("Result")
		 Or TypeOf(Parameters.Result) <> Type("Structure") Then
			Continue;
		EndIf;
		If NotificationsType = "TimeConsumingOperationCompleted"
		   And Parameters.Property("NotificationKind")
		   And Parameters.NotificationKind = NotificationsType Then
			Return Parameters.Result;
		EndIf;
		If Not Parameters.Result.Property(NotificationsType)
		 Or NotificationsType = "Messages"
		   And TypeOf(Parameters.Result[NotificationsType]) <> Type("FixedArray")
		 Or NotificationsType = "Progress"
		   And TypeOf(Parameters.Result[NotificationsType]) <> Type("Structure") Then
			Continue;
		EndIf;
		If NotificationsType = "Messages" Then
			For Each Message In Parameters.Result.Messages Do
				NotificationsMessages.Add(Message)
			EndDo;
			Result = New FixedArray(NotificationsMessages);
		Else
			Result = Parameters.Result.Progress;
		EndIf;
	EndDo;
	
	If ShouldSkipReceivedNotifications And ValueIsFilled(Notification) Then
		Notification.Delete("Content");
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Properties = New Structure(SessionParameters.TimeConsumingOperations);
		ReceivedNotifications = New Map(Properties.ReceivedNotifications);
		LastNotifications = ReceivedNotifications.Get(JobID);
		If LastNotifications = Undefined Then
			LastNotifications = New Structure("Messages, Progress");
		Else
			LastNotifications = New Structure(LastNotifications);
		EndIf;
		LastNotifications[NotificationsType] = New FixedStructure(Notification);
		ReceivedNotifications.Insert(JobID, New FixedStructure(LastNotifications));
		KeysOfObsoleteNotifications = New Array;
		For Each KeyAndValue In ReceivedNotifications Do
			ReceivedNotification = ?(KeyAndValue.Value.Messages = Undefined,
				KeyAndValue.Value.Progress, KeyAndValue.Value.Messages);
			If ReceivedNotification.AddedOn + 60*60 < CurrentSessionDate() Then
				KeysOfObsoleteNotifications.Add(KeyAndValue.Key);
			EndIf;
		EndDo;
		For Each Var_Key In KeysOfObsoleteNotifications Do
			ReceivedNotifications.Delete(Var_Key);
		EndDo;
		Properties.ReceivedNotifications = New FixedMap(ReceivedNotifications);
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	
	Return Result;
	
EndFunction

Function NameOfAlert()
	Return "StandardSubsystems.Core.TimeConsumingOperations";
EndFunction

Function NameOfAdditionalNotification()
	Return "StandardSubsystems.Core.TimeConsumingOperations.NonExistentThreadsDeletion";
EndFunction

// Parameters:
//  Data - See ServerNotifications.MessageNewData
// 
// Returns:
//  Boolean
//
Function ShouldSkipNotification(Data) Export
	
	If Data.NameOfAlert <> NameOfAlert() Then
		Return False;
	EndIf;
	
	// If the Collaboration System is not integrated, skip the completion notification
	// as it will make an extra call to "TimeConsumingOperationsServerCall.IsBackgroundJobCompleted".
	// Without the Collaboration System, it is excessive as this is managed by the function
	// "ActionCompleted", which is part of the operation completion management run by the function
	// "LongRunningOperationCheckResult".
	// 
	// 
	// 
	
	If Data.Result.NotificationKind = "TimeConsumingOperationCompleted"
	   And Not ServerNotificationsInternalCached.AreClientNotificationsAvailable()
	   And Not ServerNotifications.CollaborationSystemConnected() Then
		
		Return True;
	EndIf;
	
	Properties = New Structure("NotificationID", Null);
	FillPropertyValues(Properties, Data);
	If Properties.NotificationID <> Null Then
		Data.Result.Result.Messages =
			UserMessagesDetails(Data.Result.Result.Messages);
	EndIf;
	
	Return False;
	
EndFunction

Procedure SendClientNotification(NotificationKind, ValueToPass,
			BackgroundJob = Undefined, MainJobID = Undefined) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	WriteUserMessages = BackgroundJob <> Undefined And NotificationKind = "UserMessage"
		And Not StandardSubsystemsCached.IsLongRunningOperationSession();
	
	If WriteUserMessages Then
		ParentSessionKey = ServerNotifications.SessionKey();
	Else
		ParentSessionKey = StandardSubsystemsServer.ClientParametersAtServer(False).Get(
			"ParentSessionKey");
		If Not ValueIsFilled(ParentSessionKey) Then
			Return;
		EndIf;
		BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
		If BackgroundJob = Undefined Then
			Return;
		EndIf;
		MultithreadProcessJobID =
			StandardSubsystemsServer.ClientParametersAtServer(False).Get(
				"MultithreadProcessJobID");
		MainJobID = ?(ValueIsFilled(MultithreadProcessJobID),
			MultithreadProcessJobID, MainJobID(BackgroundJob));
	EndIf;
	
	If NotificationKind = "TimeConsumingOperationCompleted" Then
		If ValueIsFilled(MultithreadProcessJobID) Then
			If MultithreadProcessJobID <> MainJobID(BackgroundJob)
			 Or ValueToPass.Status = "Error" Then
				Return;
			EndIf;
		EndIf;
		Result = ValueToPass;
	Else
		Result = OperationNewRuntimeResult();
	EndIf;
	
	If Not WriteUserMessages Then
		// Send accumulated messages, for example, from 1C:Enterprise
		// , which does not use "Common.MessageToUser".
		Messages = BackgroundJob.GetUserMessages(True);
		For Each Message In Messages Do
			// @skip-check query-in-loop - the branch with the request is called only on the first call in the session
			SendClientNotification("UserMessage", Message);
		EndDo;
	EndIf;
	
	If NotificationKind = "UserMessage" Then
		If ValueToPass = Null Then
			Return; // Only send accumulated messages.
		EndIf;
		Result.Messages = New FixedArray(
			CommonClientServer.ValueInArray(ValueToPass));
	ElsIf NotificationKind = "Progress" Then
		Result.Messages = New FixedArray(New Array);
		Result.Progress = ValueToPass;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("NotificationKind", NotificationKind);
	NotificationParameters.Insert("JobID", MainJobID);
	NotificationParameters.Insert("Result", Result);
	NotificationParameters.Insert("TimeSentOn", CurrentUniversalDateInMilliseconds());
	
	SessionsKeys = CommonClientServer.ValueInArray(ParentSessionKey);
	Recipients = New Map;
	Recipients.Insert(InfoBaseUsers.CurrentUser().UUID, SessionsKeys);
	
	AdditionalSendingParameters = ServerNotifications.AdditionalSendingParameters();
	AdditionalSendingParameters.GroupID  = MainJobID;
	AdditionalSendingParameters.NotificationTypeInGroup = NotificationTypeID(NotificationKind);
	AdditionalSendingParameters.ShouldWriteUnconditionally = NotificationKind = "UserMessage"
		Or NotificationKind = "TimeConsumingOperationCompleted"
		  And Not Common.FileInfobase();
	
	If NotificationKind = "Progress" Then
		AdditionalSendingParameters.Replace = True;
		AdditionalSendingParameters.DeliveryDeferral = 3;
		AdditionalSendingParameters.LogEventOnDeliveryDeferral =
			NStr("vi = 'Giao dịch kéo dài.Giao hàng chậm tiến độ';
				|ru = 'Длительные операции.Отложенная доставка прогресса';
				|en = 'Long-running operations.Deferred progress delivery'; fa = 'Long-running operations.Deferred progress delivery';
				|it = 'Длительные операции.Отложенная доставка прогресса';
				|pl = 'Long-running operations.Deferred progress delivery';
				|tr = 'Uzun süreli işlemler.Gidişatın ertelenen teslimi'",
				Common.DefaultLanguageCode());
		AdditionalSendingParameters.LogCommentOnDeliveryDeferral =
			NStr("vi = 'Gửi tiến độ nhiều hơn một lần trong 3 giây.';
				|ru = 'Отправка прогресса чаще одного раза в 3 сек.';
				|en = 'Send progress more often than every 3 seconds'; fa = 'Send progress more often than every 3 seconds';
				|it = 'Отправка прогресса чаще одного раза в 3 сек.';
				|pl = 'Send progress more often than every 3 seconds';
				|tr = '3 saniyede bir gidişatın daha sık gönderilmesi'");
	EndIf;
	
	ServerNotifications.SendServerNotificationWithGroupID(NameOfAlert(),
		NotificationParameters, Recipients, Not WriteUserMessages, AdditionalSendingParameters);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Intended for the SendClientNotification procedure and GetFromNotifications function.
Function NotificationTypeID(NotificationKind)
	
	If NotificationKind = "UserMessage" Or NotificationKind = "Messages" Then
		Return New UUID("0afef160-bfcb-459e-a890-a4afbb73b7ba");
	
	ElsIf NotificationKind = "Progress" Then
		Return New UUID("14076bb1-a1f5-4876-975a-3b7f69383f6c");
		
	ElsIf NotificationKind = "TimeConsumingOperationCompleted" Then
		Return New UUID("28e5ab5c-196b-44be-aab5-8fe7edb5225b");
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Dạng thông báo không xác định của giao dịch kéo dài ""%1"".';
			|ru = 'Неизвестный вид оповещения длительной операции ""%1"".';
			|en = 'Unknown notification type of the long-running operation: ""%1"".'; fa = 'Unknown notification type of the long-running operation: ""%1"".';
			|it = 'Неизвестный вид оповещения длительной операции ""%1"".';
			|pl = 'Unknown notification type of the long-running operation: ""%1"".';
			|tr = '""%1"" uzun süreli işleminin bilinmeyen bildirim türü.'"), NotificationKind);
	Raise(ErrorText, ErrorCategory.ConfigurationError);
	
EndFunction

Function TimeConsumingOperationNotificationKinds() Export
	
	Result = New Array;
	Result.Add(Lower(NotificationTypeID("UserMessage")));
	Result.Add(Lower(NotificationTypeID("Progress")));
	Result.Add(Lower(NotificationTypeID("TimeConsumingOperationCompleted")));
	
	Return Result;
	
EndFunction

// Writes to a queue unwritten messages that were sent without
// using the Common.MessageToUser procedure.
//
// Parameters:
//  JobID - UUID
//
Procedure WritePendingUserMessages(JobID)
	
	If StandardSubsystemsCached.IsLongRunningOperationSession() Then
		// Send accumulated messages.
		SendClientNotification("UserMessage", Null);
		Return;
	EndIf;
	
	LastID_ = LastID_(JobID);
	BackgroundJob = BackgroundJobs.FindByUUID(LastID_);
	
	If BackgroundJob <> Undefined
	   And BackgroundJob.State <> BackgroundJobState.Active
	   And Not ExclusiveModeInBackgroundJob(BackgroundJob) Then
		
		Messages = BackgroundJob.GetUserMessages(True);
		// Write accumulated messages.
		For Each Message In Messages Do
			// @skip-check query-in-loop - the branch with the request is called only on the first call in the session
			SendClientNotification("UserMessage", Message, BackgroundJob, JobID);
		EndDo;
	EndIf;
	
EndProcedure

// Parameters:
//  BackgroundJob - BackgroundJob - Task whose activity must be considered.
//
// Returns:
//  Boolean - If True, the session is running in the exclusive mode
//    and at least one background job is active (the writing is unavailable within the session).
//
Function ExclusiveModeInBackgroundJob(BackgroundJob = Undefined)
	
	If Not ExclusiveMode() Then
		Return False;
	EndIf;
	
	If BackgroundJob <> Undefined
	   And BackgroundJob.State = BackgroundJobState.Active Then
		Return True;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("State", BackgroundJobState.Active);
	
	Return BackgroundJobs.GetBackgroundJobs(Filter).Count() > 0;
	
EndFunction

Function BackgroundJobsExistInFileIB()
	
	JobsRunningInFileIB = 0;
	If Common.FileInfobase() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		JobsRunningInFileIB = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	Return JobsRunningInFileIB > 0;

EndFunction

Function CanRunInBackground(ProcedureName)
	
	NameParts = StrSplit(ProcedureName, ".");
	If NameParts.Count() = 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function RunBackgroundJob(ExecutionParameters, Parameters, Var_Key, Description)
	
	If CurrentRunMode() = Undefined
		And Common.FileInfobase() Then
		
		Session = GetCurrentInfoBaseSession();
		If ExecutionParameters.WaitCompletion = Undefined And Session.ApplicationName = "BackgroundJob" Then
			Raise(NStr("vi = 'Trong cơ sở thông tin tệp, không thể thực hiện đồng thời hơn một nhiệm vụ nền.';
						|ru = 'В файловой информационной базе невозможно одновременно выполнять более одного фонового задания.';
						|en = 'In a file infobase, only one background job can run at a time.'; fa = 'In a file infobase, only one background job can run at a time.';
						|it = 'In a file infobase, only one background job can run at a time.';
						|pl = 'In a file infobase, only one background job can run at a time.';
						|tr = 'Dosya Infobase''inde birden fazla arka plan işi aynı anda yürütülemez.'"), 
				ErrorCategory.ConfigurationError);
		ElsIf Session.ApplicationName = "COMConnection" Then
			Raise(NStr("vi = 'Trong cơ sở thông tin tệp, có thể khởi động nhiệm vụ nền chỉ từ ứng dụng Client.';
						|ru = 'В файловой информационной базе можно запустить фоновое задание только из клиентского приложения.';
						|en = 'In a file infobase, background jobs can only be started from the client application.'; fa = 'In a file infobase, background jobs can only be started from the client application.';
						|it = 'In a file infobase, background jobs can only be started from the client application.';
						|pl = 'In a file infobase, background jobs can only be started from the client application.';
						|tr = 'Dosyanın infobase''inde sadece istemci uygulamasından bir arka plan işini çalıştırabilirsiniz.'"),
				ErrorCategory.ConfigurationError);
		EndIf;
		
	EndIf;
	
	// The procedure name must be as specified in the NameOfLongRunningOperationBackgroundJobProcedure variable.
	If ExecutionParameters.NoExtensions Then
		Return ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(
			"TimeConsumingOperations.ExecuteWithClientContext", Parameters, Var_Key, Description);
	
	ElsIf ExecutionParameters.WithDatabaseExtensions Then
		Return ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			"TimeConsumingOperations.ExecuteWithClientContext", Parameters, Var_Key, Description);
	Else
		Return BackgroundJobs.Execute("TimeConsumingOperations.ExecuteWithClientContext",
			Parameters, Var_Key, Description);
	EndIf;
	
EndFunction

Function ParametersList(Val Parameter1, Val Parameter2, Val Parameter3, Val Parameter4,
	Val Parameter5, Val Parameter6, Val Parameter7)
	
	PassedParameters = New Array;
	PassedParameters.Add(Parameter7);
	PassedParameters.Add(Parameter6);
	PassedParameters.Add(Parameter5);
	PassedParameters.Add(Parameter4);
	PassedParameters.Add(Parameter3);
	PassedParameters.Add(Parameter2);
	PassedParameters.Add(Parameter1);
	
	Result = New Array;
	
	For Each Parameter In PassedParameters Do
		If Result.Count() = 0 And Parameter = Undefined Then
			Continue;
		EndIf;
		Result.Insert(0, Parameter);
	EndDo;
	
	Return Result;

EndFunction

Procedure CheckNameOfProcedure(ProcedureName, MethodParameterName, MethodName,
			ExecutionParameters = Undefined, Object = Undefined)
	
	ProcedureVerifiableName = ProcedureName;
	
	If Object = Undefined Then
		NameParts = StrSplit(ProcedureName, ".", True);
		
		If NameParts.Count() = 4 And Upper(NameParts[2]) = "OBJECTMODULE" Then
			Parameters = New Structure("ExternalReportDataProcessor, RunNotInBackground1");
			If TypeOf(ExecutionParameters) = Type("Structure") Then
				FillPropertyValues(Parameters, ExecutionParameters);
			EndIf;
			Parameters.RunNotInBackground1 = True;
			FillInParameterExternalReportProcessing(Parameters.ExternalReportDataProcessor);
			CheckParameterExternalReportProcessing(Parameters, ProcedureName, MethodName);
			Object = DataProcessorReportObject(ProcedureName,
				NameParts, Parameters, "ProcedureName", "CallProcedure");
			ProcedureVerifiableName = NameParts[3];
		
		ElsIf NameParts.Count() < 2 Or NameParts.Count() > 3 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sai giá trị tham số %1 (%2) trong %3.';
					|ru = 'Некорректное значение параметра %1 (%2) в %3.';
					|en = 'Incorrect value of parameter %1 in %3: %2.'; fa = 'Incorrect value of parameter %1 in %3: %2.';
					|it = 'Valore errato del parametro %1 (%2) in %3.';
					|pl = 'Niepoprawna wartość parametru %1 (%2) w %3.';
					|tr = '%1(%2) parametresinin %3''da geçersiz değeri.'"),
				MethodParameterName, ProcedureName, MethodName);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
	EndIf;
	
	Try
		StandardSubsystemsServer.CheckMethodForCallAsArbitraryCode(ProcedureVerifiableName, True, Object);
	Except
		ErrorInfo = ErrorInfo();
		ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai giá trị tham số %1 (%2) trong %3:';
				|ru = 'Некорректное значение параметра %1 (%2) в %3:';
				|en = 'Incorrect value of parameter %1 in %3: %2'; fa = 'Incorrect value of parameter %1 in %3: %2';
				|it = 'Incorrect value of parameter %1 in %3: %2';
				|pl = 'Incorrect value of parameter %1 in %3: %2';
				|tr = '%1(%2) parametresinin %3''da geçersiz değeri:'"),
			MethodParameterName, ProcedureName, MethodName);
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, ErrorTitle);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
EndProcedure

Function PrepareExecutionParameters(PassedParameter, IsFunction)
	
	Result = CommonBackgroundExecutionParameters();
	
	If TypeOf(PassedParameter) = Type("Structure") Then
		If ValueIsFilled(PassedParameter) Then
			Result = PassedParameter;
		EndIf;
		
	ElsIf IsFunction = "Function" Then
		Id = Undefined;
		
		If TypeOf(PassedParameter) = Type("ClientApplicationForm") Then
			Id = PassedParameter.UUID;
		
		ElsIf TypeOf(PassedParameter) = Type("UUID")
		        And ValueIsFilled(PassedParameter) Then
			
			Id = PassedParameter;
		EndIf;
		
		AddExecutionParametersToReturnResult(Result, Id);
	EndIf;
	
	Result.IsFunction = IsFunction;
	Return Result;
	
EndFunction

Procedure FillInExecutionParametersTakingIntoAccountBackwardCompatibility(ExecutionParameters)
	
	NewExecutionParameters = BackgroundExecutionParameters();
	FillPropertyValues(NewExecutionParameters, ExecutionParameters);
	
	If ExecutionParameters.Property("WaitForCompletion") And ExecutionParameters.WaitForCompletion <> -1 Then
		ExecutionParameters.WaitCompletion = ExecutionParameters.WaitForCompletion;
	EndIf;
	
	FillInParameterExternalReportProcessing(NewExecutionParameters.ExternalReportDataProcessor);
	
	ExecutionParameters = NewExecutionParameters;
	
EndProcedure

Procedure FillInParameterExternalReportProcessing(ParameterValue)
	
	If ParameterValue = Undefined Then
		Return;
	EndIf;
	
	Result = NewDescriptionOfExternalProcessingReport();
	
	If TypeOf(ParameterValue) = Type("BinaryData") Then
		Result.Data = ParameterValue;
		
	ElsIf TypeOf(ParameterValue) = Type("Structure") Then
		FillPropertyValues(Result, ParameterValue);
		
		If Result.Data = Undefined Then
			DeprecatedProperties = New Structure("BinaryData");
			FillPropertyValues(DeprecatedProperties, ParameterValue);
			Result.Data = DeprecatedProperties.BinaryData;
		EndIf;
	EndIf;
	
	ParameterValue = Result;
	
EndProcedure

Procedure VerifyExecutionParameters(ProcedureName, ExecutionParameters)

	CommonClientServer.CheckParameter("TimeConsumingOperations.ExecuteInBackground", "ExecutionParameters", 
		ExecutionParameters, Type("Structure")); 
	If ExecutionParameters.RunNotInBackground1 And ExecutionParameters.RunInBackground Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Tham số ""%1"" và ""%2""
			|không thể đồng thời nhận giá trị %3 trong %4.';
			|ru = 'Параметры ""%1"" и ""%2""
			|не могут одновременно принимать значение %3 в %4.';
			|en = 'Parameters ""%1"" and ""%2""
			|cannot have value %3 in %4 at the same time.'; fa = 'Parameters ""%1"" and ""%2""
			|cannot have value %3 in %4 at the same time.';
			|it = 'I parametri ""%1"" e ""%2 ""
			| non possono applicare contemporaneamente il valore %3 a %4';
			|pl = 'Parametry ""%1"" i ""%2""
			|nie mogą jednocześnie mieć wartości %3 w %4.';
			|tr = '""%1"" ve ""%2""
			| parametreler %4''da aynı anda %3 değerini alamaz.'"),
			"RunNotInBackground1", "RunInBackground", "True", "TimeConsumingOperations.ExecuteInBackground"),
			ErrorCategory.ConfigurationError);
	EndIf;
	If ExecutionParameters.NoExtensions And ExecutionParameters.WithDatabaseExtensions Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Tham số ""%1"" và ""%2""
			|không thể đồng thời nhận giá trị %3 trong %4.';
			|ru = 'Параметры ""%1"" и ""%2""
			|не могут одновременно принимать значение %3 в %4.';
			|en = 'Parameters ""%1"" and ""%2""
			|cannot have value %3 in %4 at the same time.'; fa = 'Parameters ""%1"" and ""%2""
			|cannot have value %3 in %4 at the same time.';
			|it = 'I parametri ""%1"" e ""%2 ""
			| non possono applicare contemporaneamente il valore %3 a %4';
			|pl = 'Parametry ""%1"" i ""%2""
			|nie mogą jednocześnie mieć wartości %3 w %4.';
			|tr = '""%1"" ve ""%2""
			| parametreler %4''da aynı anda %3 değerini alamaz.'"),
			"NoExtensions", "WithDatabaseExtensions", "True", "TimeConsumingOperations.ExecuteInBackground"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
#If ExternalConnection Then
	FileInfobase = Common.FileInfobase();
	If ExecutionParameters.NoExtensions And FileInfobase Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Không thể khởi động nhiệm vụ nền với tham số ""%1""
			|trong kết nối ngoài với cơ sở thông tin file-server trong %2.';
			|ru = 'Фоновое задание не может быть запущено с параметром ""%1""
			|во внешнем соединении с файловой информационной базой в %2.';
			|en = 'Cannot start the background job with the ""%1"" parameter
			|in the external connection with the file infobase in %2.'; fa = 'Cannot start the background job with the ""%1"" parameter
			|in the external connection with the file infobase in %2.';
			|it = 'Фоновое задание не может быть запущено с параметром ""%1""
			|во внешнем соединении с файловой информационной базой в %2.';
			|pl = 'Cannot start the background job with the ""%1"" parameter
			|in the external connection with the file infobase in %2.';
			|tr = 'Arka plan görevi, %2 içindeki dosya bilgi tabanına harici bir
			|bağlantıda ""%1"" parametresiyle başlatılamaz.'"),
			"NoExtensions", "TimeConsumingOperations.ExecuteInBackground"),
			ErrorCategory.ConfigurationError);
	ElsIf ExecutionParameters.WithDatabaseExtensions And FileInfobase Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Không thể khởi động nhiệm vụ nền với tham số ""%1""
			|trong kết nối ngoài với cơ sở thông tin file-server trong %2.';
			|ru = 'Фоновое задание не может быть запущено с параметром ""%1""
			|во внешнем соединении с файловой информационной базой в %2.';
			|en = 'Cannot start the background job with the ""%1"" parameter
			|in the external connection with the file infobase in %2.'; fa = 'Cannot start the background job with the ""%1"" parameter
			|in the external connection with the file infobase in %2.';
			|it = 'Фоновое задание не может быть запущено с параметром ""%1""
			|во внешнем соединении с файловой информационной базой в %2.';
			|pl = 'Cannot start the background job with the ""%1"" parameter
			|in the external connection with the file infobase in %2.';
			|tr = 'Arka plan görevi, %2 içindeki dosya bilgi tabanına harici bir
			|bağlantıda ""%1"" parametresiyle başlatılamaz.'"),
			"WithDatabaseExtensions", "TimeConsumingOperations.ExecuteInBackground"),
			ErrorCategory.ConfigurationError);
	EndIf;
#EndIf
	
	If ExecutionParameters.IsFunction <> "Function"
	   And ExecutionParameters.IsFunction <> "Procedure"
	   And ExecutionParameters.IsFunction <> "" Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tham số hệ thống ""%1"" có thể nhận giá trị """", ""%2"", ""%3"" trong %4.
				           |Còn đã chỉ định giá trị ""%5"".';
				           |ru = 'Служебный параметр ""%1"" может принимать значения """", ""%2"", ""%3"" в %4.
				           |А указано значение ""%5"".';
				           |en = 'Possible values for the ""%1"" service parameter are """", ""%2"", ""%3"" in %4,
				           |and not the specified ""%5"" value.'; fa = 'Possible values for the ""%1"" service parameter are """", ""%2"", ""%3"" in %4,
				           |and not the specified ""%5"" value.';
				           |it = 'Possible values for the ""%1"" service parameter are """", ""%2"", ""%3"" in %4,
				           |and not the specified ""%5"" value.';
				           |pl = 'Possible values for the ""%1"" service parameter are """", ""%2"", ""%3"" in %4,
				           |and not the specified ""%5"" value.';
				           |tr = '""%1"" hizmet parametresi, %4 kapsamında """", ""%2"", ""%3"" değerlerini alabilir.
				           |Ayrıca ""%5"" değeri belirtilmiştir.'"),
				"IsFunction",
				"Function",
				"Procedure",
				"TimeConsumingOperations.ExecuteInBackground",
				ExecutionParameters.IsFunction),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	CheckParameterExternalReportProcessing(ExecutionParameters,
		ProcedureName, "TimeConsumingOperations.ExecuteInBackground");
	
EndProcedure

Procedure CheckParameterExternalReportProcessing(ExecutionParameters, ProcedureName, MethodName)
	
	If ExecutionParameters.ExternalReportDataProcessor = Undefined Then
		If ExecutionParameters.RunNotInBackground1 
		 Or Not StrStartsWith(Upper(ProcedureName), "EXTERNALREPORT.")
		   And Not StrStartsWith(Upper(ProcedureName), "EXTERNALDATAPROCESSOR.") Then
			Return;
		EndIf;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для вызова процедуры внешнего отчета или внешней обработки в фоне
			           |требуется заполнить свойство %1 параметра %2 в %3.';
			           |vi = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |en = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.'; fa = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |it = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |pl = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |tr = 'Harici rapor veya harici veri işlem prosedürünü arka planda 
			           | çağırmak için, %3 içindeki %2 parametresinin %1 özelliğinin doldurulması gerekir.'"),
			"ExternalReportDataProcessor", "ExecutionParameters", MethodName);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	DataTypes = CommonClientServer.ValueInArray(Type("BinaryData"));
	If Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
		DataTypes.Add(ModuleAdditionalReportsAndDataProcessors.TypeAdditionalReportOrProcessing());
	EndIf;
	
	PropertiesTypesToExpect = New Structure;
	PropertiesTypesToExpect.Insert("Data", New TypeDescription(DataTypes));
	PropertiesTypesToExpect.Insert("FullFileName", Type("String"));
	
	CommonClientServer.CheckParameter(MethodName,
		"ExecutionParameters.ExternalReportDataProcessor",
		ExecutionParameters.ExternalReportDataProcessor,
		Type("Structure"),
		PropertiesTypesToExpect);
	
	If Not ValueIsFilled(ExecutionParameters.ExternalReportDataProcessor.Data) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Для вызова процедуры внешнего отчета или внешней обработки в фоне
			           |требуется заполнить свойство %1 параметра %2 в %3.';
			           |vi = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |en = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.'; fa = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |it = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |pl = 'To call a procedure of an external report or external data processor in the background,
			           |the %1 property of the %2 parameter in %3 must be filled in.';
			           |tr = 'Harici rapor veya harici veri işlem prosedürünü arka planda 
			           | çağırmak için, %3 içindeki %2 parametresinin %1 özelliğinin doldurulması gerekir.'"),
			"ExternalReportDataProcessor.Data", "ExecutionParameters", MethodName);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
EndProcedure

Procedure CheckAndFillResultAddress(ExecutionParameters, FunctionName)
	
	If ExecutionParameters.ResultAddress = Undefined Then
		
		If  Common.DebugMode()
		   And (Not ValueIsFilled(ExecutionParameters.FormIdentifier)
		      Or TypeOf(ExecutionParameters.FormIdentifier) <> Type("UUID")) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có ID biểu mẫu duy nhất nào được chỉ định trong tham số %1,
				           |cũng không có địa chỉ kho chứa tạm thời nào được chỉ định trong tham số %2
				           |của hàm %3.
				           |Nên chỉ định ID biểu mẫu hoặc địa chỉ.
				           |Địa chỉ được tạo tự động chỉ chứa giá trị cho đến lần gọi máy chủ tiếp theo 
				           |, điều này có thể dẫn đến lỗi ngoài ý muốn.';
				           |ru = 'Не указан ни уникальный идентификатор формы в параметре %1,
				           |ни адрес временного хранилища в параметре %2
				           |функции %3.
				           |Рекомендуется указать идентификатор формы или адрес.
				           |Автоматически сформированный адрес содержит значение только до следующего
				           |серверного вызова, что может приводить к неожиданным ошибкам.';
				           |en = 'Neither a unique form identifier in the parameter %1
				           |nor a temporary storage address in the parameter %2
				           | of the function %3 is specified.
				           |We recommend providing either the identifier or the address.
				           |An automatically generated address is valid only until the next server call,
				           |which may cause unexpected errors.'; fa = 'Neither a unique form identifier in the parameter %1
				           |nor a temporary storage address in the parameter %2
				           | of the function %3 is specified.
				           |We recommend providing either the identifier or the address.
				           |An automatically generated address is valid only until the next server call,
				           |which may cause unexpected errors.';
				           |it = 'Neither a unique form identifier in the parameter %1
				           |nor a temporary storage address in the parameter %2
				           | of the function %3 is specified.
				           |We recommend providing either the identifier or the address.
				           |An automatically generated address is valid only until the next server call,
				           |which may cause unexpected errors.';
				           |pl = 'Neither a unique form identifier in the parameter %1
				           |nor a temporary storage address in the parameter %2
				           | of the function %3 is specified.
				           |We recommend providing either the identifier or the address.
				           |An automatically generated address is valid only until the next server call,
				           |which may cause unexpected errors.';
				           |tr = 'Ne %3 fonksiyonun %1
				           |parametresindeki benzersiz form tanımlayıcısı ne de %2
				           |parametresindeki geçici depolama adresi belirtilmedi.
				           |Form tanımlayıcısının veya adresinin belirtilmesi önerilmektedir.
				           |Otomatik olarak oluşturulan adres, sadece bir sonraki
				           |sunucu çağrısına kadar değeri içerir ve bu da beklenmedik hatalara yol açabilir.'"),
				"ExecutionParameters.FormIdentifier", "ExecutionParameters.ResultAddress", FunctionName);
			Try
				Raise(ErrorText, ErrorCategory.ConfigurationError);
			Except
				// ACC:154-off - Recommendation: Log as a warning, not as an error.
				WriteLogEvent(NStr("vi = 'Giao dịch kéo dài. Chẩn đoán';
									|ru = 'Длительные операции.Диагностика';
									|en = 'Long-running operations.Diagnostics'; fa = 'Long-running operations.Diagnostics';
									|it = 'Operazioni di lunga durata. Diagnostica';
									|pl = 'Operacje długotrwałe. Diagnostyka';
									|tr = 'Uzun süreli işlemler.Tanılama'", Common.DefaultLanguageCode()),
					EventLogLevel.Warning, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				// ACC:154-on 
			EndTry;
		EndIf;
		ExecutionParameters.ResultAddress = PutToTempStorage(Undefined,
			ExecutionParameters.FormIdentifier);
		
	ElsIf Not IsTempStorageURL(ExecutionParameters.ResultAddress) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chỉ định sai địa chỉ kho chứa tạm thời trong tham số %1
			           |của hàm %2.';
			           |ru = 'Указан некорректный адрес временного хранилища в параметре %1
			           |функции %2.';
			           |en = 'An invalid temporary storage address was specified in parameter %1
			           | of the function %2.'; fa = 'An invalid temporary storage address was specified in parameter %1
			           | of the function %2.';
			           |it = 'An invalid temporary storage address was specified in parameter %1
			           | of the function %2.';
			           |pl = 'An invalid temporary storage address was specified in parameter %1
			           | of the function %2.';
			           |tr = '%2 fonksiyonunun %1
			           |parametresinde hatalı geçici depolama adresi belirtildi.'"),
			"ExecutionParameters.ResultAddress", FunctionName);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
EndProcedure

Function IsRunWithoutBackgroundJob(ProcedureName, ExecutionParameters)
	
#If ExternalConnection Then
	If Common.FileInfobase() Then
		Return True;
	EndIf;
#Else
	If ExecutionParameters.NoExtensions
	 Or ExecutionParameters.WithDatabaseExtensions Then
		Return False;
	EndIf;
#EndIf
	
	Return Common.DebugMode()
		Or StandardSubsystemsServer.ApplicationStartupLogicDisabled()
		  And Not StandardSubsystemsServer.ThisBackgroundJobSession()
		Or ExecutionParameters.RunNotInBackground1
		Or Not ExecutionParameters.RunInBackground
		  And BackgroundJobsExistInFileIB()
		Or Not CanRunInBackground(ProcedureName);
	
EndFunction

Function CommonBackgroundExecutionParameters()
	
	Result = New Structure;
	Result.Insert("WaitCompletion", ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 0.8));
	Result.Insert("BackgroundJobDescription", "");
	Result.Insert("BackgroundJobKey", "");
	Result.Insert("RunNotInBackground1", False);
	Result.Insert("RunInBackground", False);
	Result.Insert("NoExtensions", False);
	Result.Insert("WithDatabaseExtensions", False);
	Result.Insert("AbortExecutionIfError", False);
	Result.Insert("WaitForCompletion", -1); // Backward compatibility.
	Result.Insert("ExternalReportDataProcessor", Undefined);
	Result.Insert("RefinementErrors", "");
	Result.Insert("IsFunction", ""); // Internal
	Result.Insert("IsThreadOfControlRestart", False); // Internal
	Result.Insert("MultithreadLongRunningOperationThreadOfControlProperties", Undefined); // Internal
	
	Return Result;
	
EndFunction

Procedure AddExecutionParametersToReturnResult(Parameters, FormIdentifier)
	
	Parameters.Insert("FormIdentifier", FormIdentifier); 
	Parameters.Insert("ResultAddress", Undefined);
	
EndProcedure

// Multithread operations.

Function MultithreadProcessMethodName()
	Return "TimeConsumingOperations.ExecuteMultithreadedProcess";
EndFunction

Function ExecuteMultithreadedProcess(OperationParametersList) Export
	
	DeleteNonExistingThreads();
	
	ProcessID = OperationParametersList.ProcessID;
	AbortExecutionIfError = OperationParametersList.ExecutionParameters.AbortExecutionIfError;
	
	DynamicBatchesAcquisition = TypeOf(OperationParametersList.MethodParameters) = Type("Structure");
	Percent = 0;
	
	If DynamicBatchesAcquisition Then
		NameOfBatchAcquisitionMethod = OperationParametersList.MethodParameters.NameOfBatchAcquisitionMethod;
		ContextOfBatchesAcquisitionAndProcessing = OperationParametersList.MethodParameters.Context;
		If Not ContextOfBatchesAcquisitionAndProcessing.Property("Percent") Then
			ContextOfBatchesAcquisitionAndProcessing.Insert("Percent", 0);
		EndIf;
		ContextOfBatchesAcquisitionAndProcessing.Insert("Cache", Undefined);
	Else
		BatchesCount = OperationParametersList.MethodParameters;
		NumberofPortionsProcessed = Undefined;
	EndIf;
	
	FinishEarly = False;
	
	ProcessJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	ProcessJobID = ?(ProcessJob = Undefined,
		Undefined, ProcessJob.UUID);
	
	While True Do
		
		If DynamicBatchesAcquisition Then
			NewBatches = New Map;
			BatchesAcquisitionParameters = New Array;
			BatchesAcquisitionParameters.Add(NewBatches);
			BatchesAcquisitionParameters.Add(ContextOfBatchesAcquisitionAndProcessing);
			Common.ExecuteConfigurationMethod(NameOfBatchAcquisitionMethod, BatchesAcquisitionParameters);
			ResultsNewAddresses = New Map;
			For Each KeyAndValue In NewBatches Do
				ResultsNewAddresses.Insert(KeyAndValue.Key,
					PutToTempStorage(Undefined, New UUID));
			EndDo;
			PrepareMultiThreadOperationForStartup(OperationParametersList.MethodName,
				ResultsNewAddresses, ProcessID, NewBatches, OperationParametersList);
		EndIf;
		
		// @skip-check query-in-loop - Getting data about the threads of the current process.
		Threads = TreadsPendingProcessing(ProcessID);
		If Threads.Count() = 0 Then
			WaitForAllThreadsCompletion(ProcessID, AbortExecutionIfError, FinishEarly);
			Break;
		EndIf;
		
		If Not DynamicBatchesAcquisition And NumberofPortionsProcessed = Undefined Then
			NumberofPortionsProcessed = BatchesCount - Threads.Count();
		EndIf;
		
		For Each Stream In Threads Do
			
			FinishEarly = MonitorThreadExecution(Stream, OperationParametersList, ProcessJobID);
			If FinishEarly Then
				Break;
			EndIf;
						
			If DynamicBatchesAcquisition Then
				Percent = ContextOfBatchesAcquisitionAndProcessing.Percent;
			Else
				NumberofPortionsProcessed = NumberofPortionsProcessed + 1;
				Percent = Round(NumberofPortionsProcessed * 100 / BatchesCount);
			EndIf;
			Percent = ?(Percent < 100, Percent, 99);
			If Percent > 0 Then
				ThreadKey = Stream.ThreadKey.Get();
				ReportProgress(Percent, String(ThreadKey), "ProgressofMultithreadedProcess");
			EndIf;
			
		EndDo;
		
		If FinishEarly Then
			Break;
		EndIf;
		
		// @skip-check query-in-loop - At each iteration, you need to get up-to-date data from the information security.
		WaitForAllThreadsCompletion(ProcessID, AbortExecutionIfError, FinishEarly);
		
		If FinishEarly Then
			Break;
		EndIf;
		
	EndDo;
	
	If FinishEarly Then
		CancelAllThreadsExecution(ProcessID);
	EndIf;
	
	If Percent > 0 Then
		ReportProgress(100, "", "ProgressofMultithreadedProcess");
	EndIf;
	// Request the information register and get all the results 
	
	ThreadsProcess = ThreadsLongOperations(ProcessID); 
	ThreadExecutionResult = ThreadExecutionNewResult();
	Results = New Map();
	
	For Each Stream In ThreadsProcess Do
		If Stream.Status = TimeConsumingOperationStatus().CreatedOn Then
			Continue;
		EndIf;
		
		Var_Key = Stream.ThreadKey.Get();
		Results.Insert(Var_Key, New Structure(New FixedStructure(ThreadExecutionResult)));
		Results[Var_Key].ResultAddress = PutToTempStorage(Stream.Result.Get(), Stream.ResultAddress);
		Results[Var_Key].ErrorInfo = Stream.StorageOfErrorInfo.Get();
		
		FillPropertyValues(Results[Var_Key], Stream, 
			"Status, DetailErrorDescription, BriefErrorDescription, JobID");
		
		// @skip-check query-in-loop - the branch with the request is called only on the first call in the session
		SendThreadMessages(Stream.JobID);
	EndDo;
	
	Return Results;
	
EndFunction

Function MonitorThreadExecution(Stream, OperationParametersList, ProcessJobID)

	ProcessID = OperationParametersList.ProcessID;
	AbortExecutionIfError = OperationParametersList.ExecutionParameters.AbortExecutionIfError;

	If Stream.Status <> TimeConsumingOperationStatus().CreatedOn Then
		If AbortExecutionIfError Then
			Return True;
		EndIf; 
		// @skip-check query-in-loop - the branch with the request is called only on the first call in the session
		SendThreadMessages(Stream.JobID);
	EndIf;
	
	Result = Undefined;
	While Result = Undefined Do
		// @skip-check query-in-loop - reading out up-to-date data on information security flows.
		ExecuteInBackground = WaitForAvailableThread(ProcessID, AbortExecutionIfError);
		If ExecuteInBackground = Undefined Then
			Return True;
		EndIf;
		
		// @skip-check query-in-loop - reading out up-to-date data on information security flows.
		Result = ExecuteThread(Stream, OperationParametersList, ExecuteInBackground, ProcessJobID);
		
	EndDo;
	
	If Result.Status = TimeConsumingOperationStatus().Error And AbortExecutionIfError Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Execute the specified stream.
//
// Parameters:
//  Stream - InformationRegisterRecordSet.TimeConsumingOperations
//  OperationParametersList - See MultithreadOperationParameters
//  ExecuteInBackground - Boolean
// 
// Returns:
//   See ExecuteInBackground
//
Function ExecuteThread(Stream, OperationParametersList, ExecuteInBackground, ProcessJobID)
	
	ExecutionParameters = BackgroundExecutionParameters();
	ExecutionParameters.BackgroundJobDescription = Stream.Description;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunNotInBackground1 = OperationParametersList.ExecutionParameters.RunNotInBackground1
		Or ExclusiveMode() Or Not ExecuteInBackground;
	
	ThreadProperties = New Structure;
	ThreadProperties.Insert("ProcessID", Stream.ProcessID);
	ThreadProperties.Insert("ThreadID",   Stream.ThreadID);
	ExecutionParameters.MultithreadLongRunningOperationThreadOfControlProperties = ThreadProperties;
	
	If TypeOf(Stream.StreamParameters) = Type("ValueStorage") Then
		MethodParameters = Stream.StreamParameters.Get();
	Else
		MethodParameters = New Array;
	EndIf;
	
	ExecutionParameters = PrepareExecutionParameters(ExecutionParameters, OperationParametersList.IsFunction);
	ExecutionParameters.ExternalReportDataProcessor = OperationParametersList.ExecutionParameters.ExternalReportDataProcessor;
	
	IsThreadOccupied = False;
	NewExecutionAttempt = Stream.Status <> TimeConsumingOperationStatus().CreatedOn;
	
	If ExecutionParameters.RunNotInBackground1 = False Then
		Block = New DataLock;
		Block.Add("Constant.LongRunningOperationsThreadCount");
		MaxThreads = AllowedNumberofThreads();
		
		BeginTransaction();
		Try
			Block.Lock();
			
			Threads = ActiveThreads();
			If Threads.Count() < MaxThreads Then
				StartupTempResult = ThreadExecutionNewResult();
				StartupTempResult.JobID = ProcessJobID;
				StartupTempResult.Status = TimeConsumingOperationStatus().Running;
				RefreshThreadInformationRecords(Stream, StartupTempResult);
				IsThreadOccupied = True;
			EndIf;
		
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
	If ExecutionParameters.RunNotInBackground1 = False And Not IsThreadOccupied Then
		Return Undefined;
	EndIf;
	
	SetFullNameOfAppliedProcedure(OperationParametersList.MethodName);
	Try
		RunResult = ExecuteInBackground(OperationParametersList.MethodName, MethodParameters, ExecutionParameters);
	Except
		SetFullNameOfAppliedProcedure(MultithreadProcessMethodName());
		If IsThreadOccupied Then
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
				NStr("vi = 'Không thể khởi chạy nhiệm vụ xử lý phần dữ liệu do:';
					|ru = 'Не удалось запустить задание обработки порции по причине:';
					|en = 'Failed to start batch processing task due to:'; fa = 'Failed to start batch processing task due to:';
					|it = 'Failed to start batch processing task due to:';
					|pl = 'Failed to start batch processing task due to:';
					|tr = 'Toplu işlem görevi şu nedenlerden dolayı başlatılamadı:'"));
			Try
				Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
			Except
				ClarifiedErrorInfo = ErrorInfo();
			EndTry;
			ErrorRunResult = ThreadExecutionNewResult();
			ErrorRunResult.Status = TimeConsumingOperationStatus().Error;
			SetErrorProperties(ErrorRunResult, ClarifiedErrorInfo);
			RefreshThreadInformationRecords(Stream, ErrorRunResult);
		EndIf;
		Raise;
	EndTry;
	SetFullNameOfAppliedProcedure(MultithreadProcessMethodName());
	RefreshThreadInformationRecords(Stream, RunResult, NewExecutionAttempt);
	
	Return RunResult;
	
EndFunction

Procedure RefreshThreadInformationRecords(Stream, RunResult, NewAttempt = False,
			RestartProcess = False, SetCompletionOfActiveOne = False)
	
	IsStartupResultSpecified = RunResult <> Undefined;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Not IsStartupResultSpecified Then
		RunResult = ThreadExecutionNewResult(); 
		
		If ValueIsFilled(Stream.JobID) Then
			LastID_ = ThreadJobLastID(Stream);
			Result = JobCompleted(LastID_, True);
			RunResult.Status                       = TimeConsumingOperationStatus()[Result.Status];
			RunResult.ErrorInfo           = Result.ErrorInfo;
			RunResult.BriefErrorDescription   = Result.BriefErrorDescription;
			RunResult.DetailErrorDescription = Result.DetailErrorDescription;
		Else
			RunResult.Status = TimeConsumingOperationStatus().CreatedOn;
		EndIf;
	EndIf;
	
	ThreadID   = Stream.ThreadID;
	ProcessID = Stream.ProcessID;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.TimeConsumingOperations"); 
	LockItem.SetValue("ProcessID", ProcessID);
	LockItem.SetValue("ThreadID",   ThreadID);
	
	BeginTransaction();
	Try
		Block.Lock();
		
		RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
		RecordSet.Filter.ProcessID.Set(ProcessID);
		RecordSet.Filter.ThreadID.Set(ThreadID);
		
		RecordSet.Read();
		IsStatusUpdated = Undefined;
		
		If RecordSet.Count() > 0 Then
			Record = RecordSet.Get(0);
			IsStatusUpdated = False;
			
			If IsStartupResultSpecified And Not SetCompletionOfActiveOne Then
				If RestartProcess Then
					Record.ThreadKey = New ValueStorage(RunResult.JobID, New Deflation(9));
				Else
					Record.JobID = RunResult.JobID;
				EndIf;
				If NewAttempt Then
					Record.AttemptNumber = Stream.AttemptNumber + 1;
				EndIf;
			EndIf;
			
			If Not SetCompletionOfActiveOne
			 Or Record.Status = TimeConsumingOperationStatus().Running
			   And ThreadJobLastID(Record) = ThreadJobLastID(Stream) Then
				
				IsStatusUpdated = True;
				Record.Status = RunResult.Status;
				If RunResult.Status = TimeConsumingOperationStatus().Error Then
					Record.MethodParameters = New ValueStorage(RunResult.ErrorInfo, New Deflation(9));
					Record.DetailErrorDescription = RunResult.DetailErrorDescription;
					Record.BriefErrorDescription   = RunResult.BriefErrorDescription;
				EndIf;
			EndIf;
			FillPropertyValues(Stream, Record);
			
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SetCompletionOfActiveOne = IsStatusUpdated;
	
EndProcedure

Function FirstIDOfThreadOfControlJob(ProcessID)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TimeConsumingOperations.JobID AS JobID
	|FROM
	|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
	|WHERE
	|	TimeConsumingOperations.ProcessID = &ProcessID
	|	AND TimeConsumingOperations.ThreadID = &BlankUUID";
	
	Query.SetParameter("ProcessID", ProcessID);
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.JobID;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không tồn tại luồng điều khiển của thao tác kéo dài đa luồng %1.';
			|ru = 'Управляющий поток многопоточной длительной операции %1 не существует.';
			|en = 'Long-running operation ""%1"" missing the main thread.'; fa = 'Long-running operation ""%1"" missing the main thread.';
			|it = 'Long-running operation ""%1"" missing the main thread.';
			|pl = 'Long-running operation ""%1"" missing the main thread.';
			|tr = '%1 uzun süreli işleminin yönetim iş parçacıkları mevcut değil.'"),
		String(ProcessID));
	Raise(ErrorText, ErrorCategory.ConfigurationError);
	
EndFunction

Function ThreadJobLastID(Stream)
	
	LastID_ = Stream.JobID;
	
	If ValueIsFilled(Stream.ThreadID) Then
		Return LastID_;
	EndIf;
	
	JobID = Stream.ThreadKey.Get();
	
	If TypeOf(JobID) = Type("UUID") Then
		LastID_ = JobID;
	EndIf;
	
	Return LastID_;
	
EndFunction

// Parameters:
//  ThreadProperties - Structure:
//   * ProcessID - UUID
//   * ThreadID - UUID
//
//  Result - Arbitrary - Outcome of the worker thread function.
//
Procedure SetThreadResult(ThreadProperties, Result)
	
	Result = New ValueStorage(Result, New Deflation(9));
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.TimeConsumingOperations"); 
	LockItem.SetValue("ProcessID", ThreadProperties.ProcessID);
	LockItem.SetValue("ThreadID",   ThreadProperties.ThreadID);
	
	BeginTransaction();
	Try
		Block.Lock();
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
		RecordSet.Filter.ProcessID.Set(ThreadProperties.ProcessID);
		RecordSet.Filter.ThreadID.Set(ThreadProperties.ThreadID);
		
		RecordSet.Read();
		
		If RecordSet.Count() > 0 Then
			Record = RecordSet.Get(0);
			Record.Result = Result;
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Waits until the number of active threads drops below the maximum limit.
//
// Parameters:
//  AllowedThreadsNumber - Number
//  ProcessID - UUID
//  EndEarlyIfError - Boolean
//  ExecuteNotInBackground - Boolean - Return value
//
// Returns:
//  Boolean
//
Function WaitForAvailableThread(ProcessID, EndEarlyIfError)
	
	MaxThreads = AllowedNumberofThreads();
	ExecuteInBackground = MaxThreads > 1;
	
	Block = New DataLock;
	Block.Add("Constant.LongRunningOperationsThreadCount");
	
	While True Do
		
		BeginTransaction();
		Try
			Block.Lock();
			Threads = ActiveThreads();
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		If Threads.Count() < MaxThreads Then
			Break;
		EndIf;
		
		HasCompletedThreads = HasCompletedThreads(Threads,
			EndEarlyIfError, ProcessID);
		
		If EndEarlyIfError And HasCompletedThreads = Undefined Then 
			ExecuteInBackground = Undefined; // Thread error.
			Break;
		EndIf;
		
		If HasCompletedThreads Or Not ExecuteInBackground Then
			Break;
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("ThreadID", CommonClientServer.BlankUUID());
		TreadsOfControl = Threads.FindRows(Filter);
		For Each ThreadOfControl In TreadsOfControl Do
			Threads.Delete(ThreadOfControl);
		EndDo;
		
		If Threads.Find(ProcessID, "ProcessID") = Undefined Then
			// No need to wait if the process has no worker threads.
			ExecuteInBackground = False;
			Break;
		EndIf;
		
		WaitForThreadCompletion(Threads[0]);
	EndDo;
	
	Return ExecuteInBackground;
	
EndFunction

// Sends out to thread messages that were output without
// using the Common.MessageToUser procedure.
//
// Parameters:
//  JobID - UUID
//
Procedure SendThreadMessages(Val JobID)
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	If BackgroundJob = Undefined Then
		Return;
	EndIf;
	
	Messages = BackgroundJob.GetUserMessages(True);
	For Each Message In Messages Do
		// @skip-check query-in-loop - the branch with the request is called only on the first call in the session
		SendClientNotification("UserMessage", Message);
	EndDo;

EndProcedure

// Waits for completion of all threads.
//
// Parameters:
//  Groups - Map
//
Procedure WaitForAllThreadsCompletion(ProcessID, EndEarlyIfError, FinishEarly)
	
	Threads = ActiveThreads(ProcessID);
	
	While Threads.Count() > 0 Do
		HasCompletedThreads = HasCompletedThreads(Threads,
			EndEarlyIfError, ProcessID);
		
		If HasCompletedThreads = Undefined Then
			FinishEarly = True;
			Break;
		EndIf;
		
		If Not HasCompletedThreads Then
			WaitForThreadCompletion(Threads[0]);
		EndIf;
	EndDo;
	
EndProcedure

// Waits the specified duration for a thread to stop.
//
// Parameters:
//   Stream - ValueTableRow - the thread.
//   Duration - Number - timeout duration, in seconds.
//
Procedure WaitForThreadCompletion(Stream, Duration = 1)
	
	If Not ValueIsFilled(Stream.JobID) Then
		Return;
	EndIf;
	
	Job = BackgroundJobs.FindByUUID(Stream.JobID);
	If Job <> Undefined Then
		Job = Job.WaitForExecutionCompletion(Duration);
	EndIf;
	
EndProcedure

Function HasCompletedThreads(Threads, EndEarlyIfError, ProcessID)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	HasCompletedThreads = False;
	IndexOf = Threads.Count() - 1;
	
	While IndexOf >= 0 Do
		Stream = Threads[IndexOf];
		IndexOf = IndexOf - 1;
		
		If Not ValueIsFilled(Stream.JobID) Then
			Continue;
		EndIf;
		
		ThisIsFlowOfCurrentProcess = (Stream.ProcessID = ProcessID);
		
		LastID_ = ThreadJobLastID(Stream);
		Result = JobCompleted(LastID_, True);
		
		If Result.Status = "Running"
		 Or Result.Status = "Error"
		   And Result.Job = Undefined
		   And Not ThisIsFlowOfCurrentProcess Then
			Continue;
		EndIf;
		
		IsStatusUpdated = True;
		RefreshThreadInformationRecords(Stream, Undefined,,, IsStatusUpdated);
		TheUpdatedStatus = Stream.Status;
		
		If IsStatusUpdated <> Undefined
		   And TheUpdatedStatus = TimeConsumingOperationStatus().Running Then
			Continue;
		EndIf;
		Threads.Delete(Stream);
		HasCompletedThreads = True;
		
		If IsStatusUpdated <> Undefined
		   And TheUpdatedStatus = TimeConsumingOperationStatus().Completed2 Then
			Continue;
		EndIf;
		
		If IsStatusUpdated = True
		   And TheUpdatedStatus = TimeConsumingOperationStatus().Error Then
			
			WriteError(Result.DetailErrorDescription);
		EndIf;
		
		If EndEarlyIfError = True
		   And ThisIsFlowOfCurrentProcess Then
			Return Undefined;
		EndIf;
		
	EndDo;
	
	Return HasCompletedThreads;
	
EndFunction

// Terminates active threads.
// 
// Parameters:
//  ProcessID - UUID
// 
Procedure CancelAllThreadsExecution(ProcessID)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Threads = ActiveThreads(ProcessID);
	For Each Stream In Threads Do
		If ValueIsFilled(Stream.JobID) Then
			CancelJobExecution(Stream.JobID);
		EndIf;
	EndDo;
	
	WaitForAllThreadsCompletion(ProcessID, False, False)
	
EndProcedure

// Remove details of running threads.
// 
Procedure DeleteNonExistingThreads()
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	AllThreads = ThreadsLongOperations();
	
	Processes = AllThreads.Copy(, "ProcessID");
	Processes.GroupBy("ProcessID");
	ProcessesIDs = Processes.UnloadColumn("ProcessID");
	
	ThreadOfControlFilter = New Structure;
	ThreadOfControlFilter.Insert("ProcessID");
	ThreadOfControlFilter.Insert("ThreadID",
		CommonClientServer.BlankUUID());
	
	CurrentSessionDate = CurrentSessionDate();
	UndoTime = 24*60*60; // 24 hours.
	ObsolescenceDeadline = 15*60; // 15 minutes.
	
	For Each ProcessID In ProcessesIDs Do
		ThreadOfControlFilter.ProcessID = ProcessID;
		FoundRows = AllThreads.FindRows(ThreadOfControlFilter);
		ThreadOfControl = ?(FoundRows.Count() > 0, FoundRows[0], Undefined);
		
		If ThreadOfControl <> Undefined
		   And ThreadOfControl.CreationDate + UndoTime > CurrentSessionDate Then
			
			JobID = ThreadJobLastID(ThreadOfControl);
			Job = FindJobByID(JobID);
			If Job = Undefined
			   And (ThreadOfControl.Status = TimeConsumingOperationStatus().Running
			      Or ThreadOfControl.CreationDate + ObsolescenceDeadline > CurrentSessionDate
			      Or ThreadOfControl.Status = TimeConsumingOperationStatus().Error
			        And ThreadOfControl.AttemptNumber < AttemptsNumber())
			 Or Job <> Undefined
			   And (    Job.State = BackgroundJobState.Active
			      Or Job.End + ObsolescenceDeadline > CurrentSessionDate
			      Or Job.State = BackgroundJobState.Failed
			        And ThreadOfControl.AttemptNumber < AttemptsNumber()) Then
				Continue;
			EndIf;
		EndIf;
		
		Filter = New Structure("ProcessID", ProcessID);
		ThreadsProcess = AllThreads.Copy(Filter);
		ThreadsProcess.Sort("ThreadID");
		For Each ProcessThread In ThreadsProcess Do
			JobID = ThreadJobLastID(ProcessThread);
			Job = FindJobByID(JobID);
			If Job <> Undefined
			   And Job.State = BackgroundJobState.Active Then
				CancelJobExecution(ProcessThread.JobID);
			EndIf;
		EndDo;
		DeleteDataAboutThreads(ProcessID);
		
	EndDo;
	
EndProcedure

// Thread details.
//
// Parameters:
//  ProcessID - UUID
//                        - Undefined - Return all
//
// Returns:
//    ValueTable:
//      * Description - String - arbitrary name of the thread (used in the description of the background job).
//      * JobID - UUID - background job UUID.
//      * ProcessID - UUID - Process UUID. 
//      * ThreadID - UUID - Thread UUID within the process.
//      * ResultAddress - String - an address of the temporary storage for storing the background job result.
//      * MethodName - String - Name of the method for batch processing
//      * ThreadKey - Arbitrary - Data chunk UUID.
//      * Result - ValueStorage
//      * AttemptNumber - Number
//      * StorageOfErrorInfo - ValueStorage
//      * DetailErrorDescription - String
//      * BriefErrorDescription - String
//      * CreationDate - Date
//      * Status - String
//
Function ThreadsLongOperations(ProcessID = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TimeConsumingOperations.ResultAddress AS ResultAddress,
	|	TimeConsumingOperations.Description AS Description,
	|	TimeConsumingOperations.JobID AS JobID,
	|	TimeConsumingOperations.ProcessID AS ProcessID,
	|	TimeConsumingOperations.ThreadID AS ThreadID,
	|	TimeConsumingOperations.ThreadKey AS ThreadKey,
	|	TimeConsumingOperations.MethodName AS MethodName,
	|	TimeConsumingOperations.Result AS Result,
	|	TimeConsumingOperations.AttemptNumber AS AttemptNumber,
	|	TimeConsumingOperations.MethodParameters AS StorageOfErrorInfo,
	|	TimeConsumingOperations.DetailErrorDescription AS DetailErrorDescription,
	|	TimeConsumingOperations.BriefErrorDescription AS BriefErrorDescription,
	|	TimeConsumingOperations.CreationDate AS CreationDate,
	|	TimeConsumingOperations.Status AS Status
	|FROM
	|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations";
	
	If ValueIsFilled(ProcessID) Then
		
		Query.Text = Query.Text + "
		|WHERE
		|	TimeConsumingOperations.ProcessID = &ProcessID
		|	AND TimeConsumingOperations.ThreadID <> &BlankUUID";
		
		Query.SetParameter("ProcessID", ProcessID);
		Query.SetParameter("BlankUUID",
			CommonClientServer.BlankUUID());
		
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is in progress.
//                                     "Completed " if the job completed successfully.
//                                     "Error" if the job failed.
//                                     "Canceled" if a user or administrator canceled the job.
//                                      Empty string if the job hasn't been started.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//                          - Undefined - If Status <> "Running" and the background job wasn't started.
//   * ResultAddress       - String - Address of the temporary storage to save the Map to:
//                                      ** Key - Arbitrary 
//                                      ** Value - Structure
//   * ErrorInfo    - ErrorInfo - If Status = "Error".
//                           - Undefined - If Status <> "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//   * BriefErrorDescription   - String - Obsolete.
//   * DetailErrorDescription - String - Obsolete.
//
Function ThreadExecutionNewResult()
	
	Result = New Structure;
	Result.Insert("Status",                       "");
	Result.Insert("JobID",         Undefined);
	Result.Insert("ResultAddress",              "");
	Result.Insert("ErrorInfo",           Undefined);
	Result.Insert("BriefErrorDescription",   "");
	Result.Insert("DetailErrorDescription", "");
	Result.Insert("Messages", New FixedArray(New Array));
	
	Return Result;
	
EndFunction

Function ActiveThreads(ProcessID = Undefined)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TimeConsumingOperations.ThreadID AS ThreadID,
	|	TimeConsumingOperations.ResultAddress AS ResultAddress,
	|	TimeConsumingOperations.JobID AS JobID,
	|	TimeConsumingOperations.ProcessID AS ProcessID,
	|	TimeConsumingOperations.MethodName AS MethodName,
	|	TimeConsumingOperations.UserName AS UserName,
	|	TimeConsumingOperations.ThreadKey AS ThreadKey,
	|	TimeConsumingOperations.Description AS Description,
	|	TimeConsumingOperations.AttemptNumber AS AttemptNumber,
	|	TimeConsumingOperations.Status AS Status
	|FROM
	|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
	|WHERE
	|	TimeConsumingOperations.Status = &Running";
		
	If ValueIsFilled(ProcessID) Then
		QueryText = QueryText + "
		|	AND TimeConsumingOperations.ProcessID = &ProcessID
		|	AND TimeConsumingOperations.ThreadID <> &BlankUUID";
		
		Query.SetParameter("ProcessID", ProcessID);
		Query.SetParameter("BlankUUID",
			CommonClientServer.BlankUUID());
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("Running", TimeConsumingOperationStatus().Running);
	
	Return Query.Execute().Unload()
	
EndFunction

// Parameters:
//   ProcessID - UUID
//
// Returns:
//  ValueTable:
//   * ThreadID   - UUID
//   * ResultAddress       - String
//   * JobID  - UUID
//   * ProcessID - UUID
//   * MethodName             - String
//   * ThreadKey            - ValueStorage
//   * Description          - String
//   * AttemptNumber          - Number
//   * StreamParameters       - ValueStorage
//   * Status                - String
//  
Function TreadsPendingProcessing(ProcessID)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TimeConsumingOperations.ThreadID AS ThreadID,
	|	TimeConsumingOperations.ResultAddress AS ResultAddress,
	|	TimeConsumingOperations.JobID AS JobID,
	|	TimeConsumingOperations.ProcessID AS ProcessID,
	|	TimeConsumingOperations.MethodName AS MethodName,
	|	TimeConsumingOperations.UserName AS UserName,
	|	TimeConsumingOperations.ThreadKey AS ThreadKey,
	|	TimeConsumingOperations.Description AS Description,
	|	TimeConsumingOperations.AttemptNumber AS AttemptNumber,
	|	TimeConsumingOperations.StreamParameters AS StreamParameters,
	|	TimeConsumingOperations.Status AS Status
	|FROM
	|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
	|WHERE
	|	TimeConsumingOperations.ProcessID = &ProcessID
	|	AND TimeConsumingOperations.ThreadID <> &BlankUUID
	|	AND (TimeConsumingOperations.Status = &Created
	|			OR TimeConsumingOperations.Status = &Error
	|				AND TimeConsumingOperations.AttemptNumber < &AttemptsNumber)";
	
	Query.SetParameter("ProcessID", ProcessID);
	Query.SetParameter("AttemptsNumber",     AttemptsNumber());
	Query.SetParameter("Created", TimeConsumingOperationStatus().CreatedOn);
	Query.SetParameter("Error", TimeConsumingOperationStatus().Error);
	Query.SetParameter("BlankUUID",
		CommonClientServer.BlankUUID());
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure PrepareMultiThreadOperationForStartup(Val MethodName, ResultAddresses,
			Val ProcessID, Val Portions, OperationUpdatedParameters = Undefined)
	
	UserName = UserName();
	CurrentSessionDate = CurrentSessionDate();
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
	RecordSet.Filter.ProcessID.Set(ProcessID);
	
	For Each KeyValue In Portions Do
		
		Record = RecordSet.Add();
		
		Record.ProcessID = ProcessID;
		Record.ThreadID   = New UUID;
		Record.MethodName             = MethodName;
		Record.ThreadKey            = New ValueStorage(KeyValue.Key, New Deflation(9));
		Record.ResultAddress       = ResultAddresses[KeyValue.Key];
		Record.Status                = TimeConsumingOperationStatus().CreatedOn;
		Record.AttemptNumber          = 0;
		Record.Description          = String(KeyValue.Key);
		Record.CreationDate          = CurrentSessionDate;
		Record.UserName       = UserName;
		Record.StreamParameters       = New ValueStorage(KeyValue.Value, New Deflation(9));
		
	EndDo;
	
	ThreadID = CommonClientServer.BlankUUID();
	If OperationUpdatedParameters = Undefined Then
		Record = RecordSet.Add();
		Record.ProcessID = ProcessID;
		Record.ThreadID   = ThreadID;
		Record.Status                = TimeConsumingOperationStatus().CreatedOn;
		Record.AttemptNumber          = 0;
		Record.CreationDate          = CurrentSessionDate;
		Record.UserName       = UserName;
		RecordSet.Write();
	Else
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.TimeConsumingOperations");
		LockItem.SetValue("ProcessID", ProcessID);
		LockItem.SetValue("ThreadID", ThreadID);
		BeginTransaction();
		Try
			Block.Lock();
			SetOfOneRecord = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
			SetOfOneRecord.Filter.ProcessID.Set(ProcessID);
			SetOfOneRecord.Filter.ThreadID.Set(ThreadID);
			SetOfOneRecord.Read();
			If SetOfOneRecord.Count() <> 1 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không tồn tại luồng điều khiển của thao tác kéo dài đa luồng %1.';
						|ru = 'Управляющий поток многопоточной длительной операции %1 не существует.';
						|en = 'Long-running operation ""%1"" missing the main thread.'; fa = 'Long-running operation ""%1"" missing the main thread.';
						|it = 'Long-running operation ""%1"" missing the main thread.';
						|pl = 'Long-running operation ""%1"" missing the main thread.';
						|tr = '%1 uzun süreli işleminin yönetim iş parçacıkları mevcut değil.'"),
					String(ProcessID));
				Raise(ErrorText, ErrorCategory.ConfigurationError);
			EndIf;
			CacheCurrent = OperationUpdatedParameters.MethodParameters.Context.Cache;
			OperationUpdatedParameters.MethodParameters.Context.Cache = Undefined;
			SetOfOneRecord[0].ExecutionParameters = New ValueStorage(OperationUpdatedParameters, New Deflation(9));
			OperationUpdatedParameters.MethodParameters.Context.Cache = CacheCurrent;
			SetOfOneRecord.Write();
			RecordSet.Write(False);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

Procedure CheckIfCanRunMultiThreadLongRunningOperation(ExecutionParameters, ParametersSet, FunctionName)
	
	CommonClientServer.CheckParameter(FunctionName,
		"ExecutionParameters", ExecutionParameters, Type("Structure"));
	
	If ParametersSet <> Undefined
	   And TypeOf(ParametersSet) <> Type("Map")
	   And TypeOf(ParametersSet) <> Type("Structure") Then
		
		ErrorText = NStr("vi = 'Sai kiểu tập hợp tham số giao dịch kéo dài đa luồng.';
						|ru = 'Неверный тип набора параметров многопоточной длительной операции.';
						|en = 'Invalid parameter set type for a multithreaded long-running operation.'; fa = 'Invalid parameter set type for a multithreaded long-running operation.';
						|it = 'Invalid parameter set type for a multithreaded long-running operation.';
						|pl = 'Invalid parameter set type for a multithreaded long-running operation.';
						|tr = 'Çok iş parçacıklı uzun süreli işlemin parametre kümesi türü yanlış.'");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	If Common.DataSeparationEnabled()
	   And Not Common.SeparatedDataUsageAvailable() Then
		
		ErrorText = NStr("vi = 'Sai kiểu tập hợp tham số giao dịch kéo dài đa luồng.';
						|ru = 'Неверный тип набора параметров многопоточной длительной операции.';
						|en = 'Invalid parameter set type for a multithreaded long-running operation.'; fa = 'Invalid parameter set type for a multithreaded long-running operation.';
						|it = 'Invalid parameter set type for a multithreaded long-running operation.';
						|pl = 'Invalid parameter set type for a multithreaded long-running operation.';
						|tr = 'Çok iş parçacıklı uzun süreli işlemin parametre kümesi türü yanlış.'");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
EndProcedure

// See ExecuteFunctionInMultipleThreads
Function RunMethodInMultipleThreads(Val MethodName, Val ExecutionParameters, Val MethodParametersSet,
			Val IsFunctionExecution)
	
	NewExecutionParameters = FunctionExecutionParameters(Undefined);
	FillPropertyValues(NewExecutionParameters, ExecutionParameters);
	ExecutionParameters = NewExecutionParameters;
	
	FunctionName = ?(IsFunctionExecution, "TimeConsumingOperations.ExecuteFunctionInMultipleThreads",
	"TimeConsumingOperations.ExecuteProcedureinMultipleThreads");

	CheckIfCanRunMultiThreadLongRunningOperation(ExecutionParameters, MethodParametersSet, FunctionName);
	
	CheckAndFillResultAddress(ExecutionParameters, FunctionName);
	
	If ExecutionParameters.WaitCompletion = CommonBackgroundExecutionParameters().WaitCompletion Then
		ExecutionParameters.WaitCompletion = 0;
	EndIf;
	
	ResultAddresses = New Map;
	
	If TypeOf(MethodParametersSet) = Type("Map") Then
		For Each ParameterFunctions In MethodParametersSet Do
			StreamResultAddr = PutToTempStorage(Undefined, New UUID);
			ResultAddresses.Insert(ParameterFunctions.Key, StreamResultAddr);
		EndDo;
		MethodParameters = MethodParametersSet.Count();
	Else
		MethodParameters = MethodParametersSet; // Structure
		MethodParametersSet = New Map;
	EndIf;
	
	ProcessID = New UUID;
	MultithreadOperationParameters = MultithreadOperationParameters(ProcessID);
	MultithreadOperationParameters.MethodName = MethodName;
	MultithreadOperationParameters.IsFunction = ?(IsFunctionExecution, "Function", "Procedure");
	MultithreadOperationParameters.ExecutionParameters = ExecutionParameters;
	MultithreadOperationParameters.MethodParameters = MethodParameters;
	
	PrepareMultiThreadOperationForStartup(MethodName,
		ResultAddresses, ProcessID, MethodParametersSet);
	
	RunResult = New Structure("Status, JobID, ResultAddress",
		TimeConsumingOperationStatus().Running,, ExecutionParameters.ResultAddress);
	ScheduleStartOfLongRunningOperationThreads(RunResult, MultithreadOperationParameters);
	
	// The procedure name must be as specified in the MultithreadProcessMethodName function.
	RunResult = ExecuteFunction(ExecutionParameters,
		"TimeConsumingOperations.ExecuteMultithreadedProcess", MultithreadOperationParameters);
	
	If RunResult.Status <> TimeConsumingOperationStatus().Running Then
		DeleteDataAboutThreads(ProcessID);
	Else
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		RegisterThreadOfControlID(RunResult.JobID, ProcessID);
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	
	Return RunResult;
	
EndFunction

// Returns:
//  Structure:
//   * CreatedOn     - String
//   * Running - String
//   * Completed2   - String
//   * Error      - String
//   * Canceled    - String
//
Function TimeConsumingOperationStatus()
	
	Result = New Structure();
	Result.Insert("CreatedOn",     "");
	Result.Insert("Running", "Running");
	Result.Insert("Completed2",   "Completed2");
	Result.Insert("Error",      "Error");
	Result.Insert("Canceled",    "Canceled");
	
	Return Result;
	
EndFunction

Function AttemptsNumber()
	Return 3;
EndFunction

Procedure RegisterThreadOfControlID(JobID, ProcessID)
	
	If SessionParameters.TimeConsumingOperations.RunOnes.Get(JobID) = Undefined Then
		Properties = New Structure(SessionParameters.TimeConsumingOperations);
		RunOnes = New Map(Properties.RunOnes);
		RunOnes.Insert(JobID, ProcessID);
		Properties.RunOnes = New FixedMap(RunOnes);
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
	EndIf;
	
EndProcedure

Function IsThreadOfControlRestarted(JobID, Job)
	
	ProcessID = SessionParameters.TimeConsumingOperations.RunOnes.Get(JobID);
	
	If ProcessID = Undefined
	 Or Job <> Undefined
	   And Job.State <> BackgroundJobState.Failed
	 Or Not Common.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	BlankID = CommonClientServer.BlankUUID();
	
	Query = New Query;
	Query.SetParameter("ProcessID", ProcessID);
	Query.SetParameter("ThreadID", BlankID);
	Query.Text =
	"SELECT
	|	TimeConsumingOperations.ProcessID AS ProcessID,
	|	TimeConsumingOperations.ThreadID AS ThreadID,
	|	TimeConsumingOperations.AttemptNumber AS AttemptNumber,
	|	TimeConsumingOperations.Status AS Status,
	|	TimeConsumingOperations.ThreadKey AS ThreadKey,
	|	TimeConsumingOperations.ExecutionParameters AS ExecutionParameters
	|FROM
	|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
	|WHERE
	|	TimeConsumingOperations.ProcessID = &ProcessID
	|	AND TimeConsumingOperations.ThreadID = &ThreadID";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return False;
	EndIf;
	
	Stream = QueryResult.Unload()[0];
	
	If Stream.AttemptNumber >= AttemptsNumber() Then
		Return False;
	EndIf;
	
	Try
		OperationParametersList = MultithreadOperationParameters(Stream.ProcessID,
			Stream.ExecutionParameters.Get());
		
		ExecutionParameters = OperationParametersList.ExecutionParameters;
		ExecutionParameters.WaitCompletion = 0;
		// Restarting a background job requires starting a new background job.
		// Therefore, always start it in the background (in the job queue in file infobases).
		ExecutionParameters.RunInBackground = True;
		ExecutionParameters.IsThreadOfControlRestart = True;
		
		// The procedure name must be as specified in the MultithreadProcessMethodName function.
		RunResult = ExecuteFunction(ExecutionParameters,
			"TimeConsumingOperations.ExecuteMultithreadedProcess", OperationParametersList);
		
		If Not ValueIsFilled(RunResult.JobID) Then
			Raise(NStr("vi = 'ID duy nhất của nhiệm vụ nền.';
						|ru = 'Пустой идентификатор фонового задания.';
						|en = 'Empty UUID of the background job.'; fa = 'Empty UUID of the background job.';
						|it = 'Empty UUID of the background job.';
						|pl = 'Empty UUID of the background job.';
						|tr = 'Arka plan işinin boş tanımlayıcısı.'"), 
				ErrorCategory.ConfigurationError);
		EndIf;
		NewJob = FindJobByID(RunResult.JobID);
		If NewJob = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa thực hiện nhiệm vụ nền với ID %1.';
					|ru = 'Фоновое задание с идентификатором %1 не существует.';
					|en = 'Background job with this ID doesn''t exist: %1.'; fa = 'Background job with this ID doesn''t exist: %1.';
					|it = 'Background job with this ID doesn''t exist: %1.';
					|pl = 'Background job with this ID doesn''t exist: %1.';
					|tr = '%1 kimliğine sahip arka plan işi mevcut değil.'"),
				RunResult.JobID);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
		Job = NewJob;
		
		Properties = New Structure(SessionParameters.TimeConsumingOperations);
		Restarted = New Map(Properties.Restarted);
		Restarted.Insert(JobID, RunResult.JobID);
		Properties.Restarted = New FixedMap(Restarted);
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
		
		RefreshThreadInformationRecords(Stream, RunResult, True, True);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi thử khởi động lại nhiệm vụ nền %1
			           |của luồng quản trị %2 đã xảy ra lỗi:
			           |
			           |%3';
			           |ru = 'При попытке перезапуска фонового задания %1
			           |управляющего потока %2 возникла ошибка:
			           |
			           |%3';
			           |en = 'An error occurred while restarting the %1 background job
			           |of the %2 thread of control:
			           |
			           |%3'; fa = 'An error occurred while restarting the %1 background job
			           |of the %2 thread of control:
			           |
			           |%3';
			           |it = 'При попытке перезапуска фонового задания %1
			           |управляющего потока %2 возникла ошибка:
			           |
			           |%3';
			           |pl = 'An error occurred while restarting the %1 background job
			           |of the %2 thread of control:
			           |
			           |%3';
			           |tr = '%2 yönetim akışının %1
			           | arka plan işlerini çalıştırmaya kalkışırken hata oluştu:
			           |
			           |%3'"),
			String(JobID),
			String(Stream.ProcessID),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteError(ErrorText);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Procedure SetCompletionForThreadOfControl(JobID, Result)
	
	ProcessID = SessionParameters.TimeConsumingOperations.RunOnes.Get(JobID);
	If ProcessID = Undefined Then
		Return;
	EndIf;
	
	BlankID = CommonClientServer.BlankUUID();
	
	Query = New Query;
	Query.SetParameter("ProcessID", ProcessID);
	Query.SetParameter("ThreadID", BlankID);
	Query.SetParameter("Status", TimeConsumingOperationStatus().Running);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
	|WHERE
	|	TimeConsumingOperations.ProcessID = &ProcessID
	|	AND TimeConsumingOperations.ThreadID = &ThreadID
	|	AND TimeConsumingOperations.Status = &Status";
	
	If Not Query.Execute().IsEmpty() Then
		// Set the main thread's status to Completed.
		RunResult = ThreadExecutionNewResult();
		RunResult.Status                       = TimeConsumingOperationStatus()[Result.Status];
		RunResult.ErrorInfo           = Result.ErrorInfo;
		RunResult.BriefErrorDescription   = Result.BriefErrorDescription;
		RunResult.DetailErrorDescription = Result.DetailErrorDescription;
		MainThreadDescription = New Structure;
		MainThreadDescription.Insert("ProcessID", ProcessID);
		MainThreadDescription.Insert("ThreadID",   BlankID);
		MainThreadDescription.Insert("JobID",  JobID);
		MainThreadDescription.Insert("ThreadKey",
			New ValueStorage(LastID_(JobID)));
		
		RefreshThreadInformationRecords(MainThreadDescription, RunResult,,, True);
	EndIf;
	
	// Delete from the pool of running jobs.
	Properties = New Structure(SessionParameters.TimeConsumingOperations);
	RunOnes = New Map(Properties.RunOnes);
	RunOnes.Delete(JobID);
	Properties.RunOnes = New FixedMap(RunOnes);
	SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
	
EndProcedure

Procedure DeleteDataAboutThreads(ProcessID)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
	RecordSet.Filter.ProcessID.Set(ProcessID);
	
	RecordSet.Write();
	
EndProcedure

Procedure ScheduleStartOfLongRunningOperationThreads(RunResult, OperationParametersList)
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ThreadID   = CommonClientServer.BlankUUID();
	ProcessID = OperationParametersList.ProcessID;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.TimeConsumingOperations"); 
	LockItem.SetValue("ProcessID", ProcessID);
	LockItem.SetValue("ThreadID", ThreadID);
	
	RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
	RecordSet.Filter.ProcessID.Set(ProcessID);
	RecordSet.Filter.ThreadID.Set(ThreadID);
	
	BeginTransaction();
	Try
		Block.Lock();
		RecordSet.Read();
		
		If RecordSet.Count() > 0 Then
			Record = RecordSet[0];
		Else
			Record                       = RecordSet.Add();
			Record.ProcessID = ProcessID;
			Record.ThreadID   = ThreadID;
			Record.AttemptNumber          = 0;
			Record.CreationDate          = CurrentSessionDate();
			Record.UserName       = UserName();
		EndIf;
		Record.ResultAddress       = RunResult.ResultAddress;
		Record.JobID  = RunResult.JobID;
		Record.Status                = RunResult.Status;
		Record.ExecutionParameters   = New ValueStorage(OperationParametersList, New Deflation(9));
		
		RecordSet.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#Region EventLog

Procedure WriteError(Val Text)
	
	EventLog.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Error,,, Text);
	
EndProcedure

// Returns a string constant for generating event log messages.
//
// Returns:
//   String
//
Function EventLogEvent() Export
	
	Return NStr("vi = 'Giao dịch kéo dài đa luồng';
				|ru = 'Многопоточные длительные операции';
				|en = 'Multithreaded long-running operations'; fa = 'Multithreaded long-running operations';
				|it = 'Operazioni complesse multiflusso';
				|pl = 'Wielopotokowe operacje długotrwałe';
				|tr = 'Çoklu kullanımlı uzun işlemler'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

// See CommonOverridable.OnSetUpValidationOfMethodsCalledAsArbitraryCode.
Procedure OnSetUpValidationOfMethodsCalledAsArbitraryCode(Settings) Export
	
	// Exceptions.
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "ExecuteFunction";
	CheckException.ContentFragment = "Return ExecuteInBackground(FunctionName, CallParameters, ExecutionParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "ExecuteProcedure";
	CheckException.ContentFragment = "Return ExecuteInBackground(ProcedureName, CallParameters, ExecutionParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "CallProcedure";
	CheckException.ContentFragment = "Common.ExecuteConfigurationMethod(ProcedureName, CallParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "CallProcedure";
	CheckException.ContentFragment = "Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], CallParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "CallFunction";
	CheckException.ContentFragment = "Result = Common.ExecuteConfigurationMethod(FunctionName, ProcedureParameters, True)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "CallFunction";
	CheckException.ContentFragment = "Result = Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], ProcedureParameters, True)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "ExecuteMultithreadedProcess";
	CheckException.ContentFragment = "Common.ExecuteConfigurationMethod(NameOfBatchAcquisitionMethod, BatchesAcquisitionParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "ExecuteThread";
	CheckException.ContentFragment = "RunResult = ExecuteInBackground(OperationParametersList.MethodName, MethodParameters, ExecutionParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "RunReportObjectModuleProcedure";
	CheckException.ContentFragment = "Common.ExecuteObjectMethod(Report, Parameters.MethodName, MethodParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "RunDataProcessorObjectModuleProcedure";
	CheckException.ContentFragment = "Common.ExecuteObjectMethod(DataProcessor, Parameters.MethodName, MethodParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "StartBackgroundExecution";
	CheckException.ContentFragment = "Common.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters)";
	
	CheckException = Settings.CheckExceptions.Add();
	CheckException.FullObjectName   = "CommonModule.TimeConsumingOperations";
	CheckException.ProcedureName       = "StartBackgroundExecution";
	CheckException.ContentFragment = "Common.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters)";
	
	Methods = New Map;
	Methods.Insert("RunDataProcessorObjectModuleProcedure", True);
	Methods.Insert("RunReportObjectModuleProcedure", True);
	Settings.ExclusionsWhenSpecifiedMethodNotCalled.Insert("CommonModule.TimeConsumingOperations", Methods);
	
EndProcedure

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("SessionParametersSetting");
	Methods.Insert("ExecuteMultithreadedProcess", True);
	Methods.Insert("RunDataProcessorObjectModuleProcedure", True);
	Methods.Insert("RunReportObjectModuleProcedure", True);
	
EndProcedure

#EndRegion