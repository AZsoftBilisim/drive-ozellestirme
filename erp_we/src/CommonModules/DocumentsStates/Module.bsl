#Region Public

// Reflects the state changes of documents in the status registers.
//
// Parameters:
//  DocumentSource - DocumentObject - Document that initiates the state change.
//  TempTablesManager - TempTablesManager - a temporary table Manager that contains tables of register changes.
//  Run - See AddTasksToStateOfOrders.Run.
//
Procedure ReflectDocumentStates(DocumentSource, TempTablesManager, Run = True) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DocumentsStates.ReflectDocumentStates");
	RunInCurrentSession = DocumentsStatesCached.PerformReflectionInCurrentSession(DocumentSource.Ref.Metadata().Name);
	
	If RunInCurrentSession Then
		
		RegisterName = DocumentsStatesCached.NameOfRegisterToReflectDocument(DocumentSource.Ref.Metadata().Name);
		If ValueIsFilled(RegisterName) Then
			
			DocumentsArray = New Array;
			DocumentsArray.Add(DocumentSource.Ref);
			ReflectionErrors = New Map;
			
			InformationRegisters[RegisterName].ReflectOrderStates(DocumentsArray, ReflectionErrors);
			
			ReflectionErrorText = ReflectionErrors.Get(DocumentSource.Ref);
			
			If ReflectionErrorText <> Undefined Then
			
				Raise ReflectionErrorText;	
			
			EndIf;
			
		EndIf;
	
	EndIf;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	QueryTemplate = "
	|SELECT DISTINCT
	|	Table.ReflectedDocument AS ReflectedDocument
	|FROM
	|	&DataCollection AS Table
	|;
	|";
	
	TheTextOfASubquery = "";
	TempTablesQueryText = "";
	TemporaryTableNames = "";
	
	AddTaskRequestText(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames);
	
	TextDestroyW = MonthEndTransactionsServer.TemporaryTableDestructionQueryTest(TemporaryTableNames);
	
	If ValueIsFilled(TheTextOfASubquery) Then // there is at least one control register.
		Query.Text = TempTablesQueryText
			+ StrReplace(QueryTemplate, "&DataCollection", "(" + TheTextOfASubquery + ")")
			+ TextDestroyW;
			
		ArrayOfReflectedDocuments = Query.Execute().Unload().UnloadColumn("ReflectedDocument");
		InventoryAllocation.ExcludeLinksThatRequireDeferredUpdates(ArrayOfReflectedDocuments);
		
		If RunInCurrentSession Then // The initiator document of the State change has already been reflected.
			CommonClientServer.DeleteValueFromArray(ArrayOfReflectedDocuments, DocumentSource.Ref);
		EndIf;
		
		AddTasksToStateOfOrders(DocumentSource, ArrayOfReflectedDocuments,,, Run);
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

// Adds tasks to the State of orders.
// 
// Parameters:
//  Source - DocumentObject - the document being held, the source of information to reflect.
//  Reflected_Documents - Array of DocumentRef - an array of references to the documents that need to reflect.
//  Action - String - action to reflect the State of orders. Possible actions are indicated in the "Actions to reflect the status of orders" method
//                      of the manager module of the corresponding
//                      information register of the State of orders.
//                      More details can be found in the description of the method
//                      "Initialize the Action table to reflect the status of orders."
//                      By default, an empty string.
//  RegistersToBeReflected - String - the names of the registers reflect the state of orders (structure keys from 
//                                Registers of order status displays) separated by commas.
//                     - See RegistersToReflectStateOfOrders
//  Run - Boolean - indicates that tasks are running.
//                       The default is TRUE.
//
Procedure AddTasksToStateOfOrders(
			Source,
			Reflected_Documents,
			Action = "",
			RegistersToBeReflected = Undefined,
			Run = True) Export
	
	If TypeOf(RegistersToBeReflected) = Type("String") Then
		
		Registers = RegistersToReflectStateOfOrders();
		
		StructureOfRegistersForReflection = New Structure(RegistersToBeReflected);
		For Each CaseElement In StructureOfRegistersForReflection Do
			
			RegisterName = CaseElement.Key;
			If Registers.Property(RegisterName) Then
				Registers[RegisterName] = True;
			EndIf;
			
		EndDo;
		
	Else
		
		Registers = RegistersToBeReflected;
		
	EndIf;
	
	Queue = "JobsToReflectOrderState";
	
	TaskTable = ?(Run,
						DeferredJobs.InitializeTaskTable(Queue),
						DocumentsPosting.TaskQueueTable(Source, Queue));
	
	For Each RegisterName In MaintainedRegisters(Registers) Do
		
		InformationRegisters[RegisterName].AddTasksToStateOfOrders(
			Source,
			Reflected_Documents,
			Action,
			TaskTable);
		
	EndDo;
	
	If Run And ValueIsFilled(Reflected_Documents) Then
		DeferredJobs.Run(TaskTable);
	EndIf;
	
EndProcedure

// Returns the structure of parameters describing registers to reflect the State of orders.
//
// Returns:
//  Structure - Registers To Reflect The State Of Orders:
//   * SalesOrderStates       - Boolean - 
//   * PurchaseOrderStates    - Boolean - 
//   * StatusesOfInternalOrders     - Boolean - 
//   * ProductionStageStates    - Boolean - 
//   * StatesOfProductionOrders - Boolean - 
//
Function RegistersToReflectStateOfOrders() Export
	
	Parameters = New Structure;
	Parameters.Insert("SalesOrderStates",       False);
	Parameters.Insert("PurchaseOrderStates",    False);
	Parameters.Insert("StatusesOfInternalOrders",     False);
	Parameters.Insert("ProductionStageStates",    False);
	Parameters.Insert("StatesOfProductionOrders", False);
	Return Parameters;
	
EndFunction

// Returns the Query Text for the presence of tasks in the register "tasksreferences and order status".
// 
// Parameters:
//  ParameterName - String - The name of the parameter that defines the document for which the job check is being performed.
//                          The name of the request parameter is passed along with "&" (example "&Customer order").
// 
// Returns:
//  String - Query text
//
Function QueryTextThereAreTasksToReflectStateOfOrders(ParameterName) Export
	
	QueryText =
	"SELECT TOP 1
	|	TRUE AS ThereAreTasksToReflectStateOfOrders
	|FROM
	|	InformationRegister.JobsToReflectOrderState AS Jobs
	|WHERE
	|	Jobs.Document = &OrderDocument";
	
	QueryText = StrReplace(QueryText, "&OrderDocument", ParameterName);
	
	Return QueryText;
	
EndFunction

// Handler after recording on the server for order forms.
// Checks whether it is possible to start checking whether there is a task to reflect the State of orders, and, if possible, sets
// the sign of the start of this check (the value of the Attribute of the form "Start checking the task to display the status of orders" to 0).
// 
// Parameters:
//  Form - ClientApplicationForm - with the Attribute "checkingchartingreferences and Order status":
//                                        1. 0 - the task check to reflect the State of orders is not running,
//                                        2. 1 - run the task check to reflect the State of orders,
//                                        3. 2 - start of task verification to reflect the State of orders,
//                                        4. 3 - the task is being checked to reflect the State of orders.
//  WriteParameters - Structure - standard parameter passed to the event handler.
//  NameOfElementState - See DocumentsStatesClientServer.SetItemsVisibility.NameOfElementState
//  GroupNameStateIsCalculated - See DocumentsStatesClientServer.SetItemsVisibility.GroupNameStateIsCalculated
//  AdditionalCondition - Boolean - if False, then the task check to reflect the State of orders does not start.
//                                   The default is TRUE.
//
Procedure AfterWriteAtServer(
			Form,
			WriteParameters,
			NameOfElementState = "State",
			GroupNameStateIsCalculated = "GroupStateIsCalculated",
			AdditionalCondition = True) Export
	
	If WriteParameters.WriteMode <> DocumentWriteMode.Posting
	 Or Common.FileInfobase()
	 Or Common.DebugMode()
	 Or Not AdditionalCondition
	 Or Not TaskCheckForReflectingStateOfOrdersIsNotRunning(Form) Then
		Return;
	EndIf;
	
	Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 1;
	
	DocumentsStatesClientServer.SetItemsVisibility(
		Form.Items,
		NameOfElementState,
		GroupNameStateIsCalculated,
		True);
	
EndProcedure

// Returns an indication that the task has not been checked to reflect the State of orders.
// 
// Parameters:
//  Form - See AfterWriteAtServer.Form
// 
// Returns:
//  Boolean - indicates whether the task is being checked to reflect the State of orders.
//
Function TaskCheckForReflectingStateOfOrdersIsNotRunning(Form) Export
	
	Return Form.IndicatesWhetherTaskIsBeingCheckedToReflectStateOfOrders = 0;
	
EndFunction

#EndRegion

#Region Internal

// Performs the necessary actions in turn of tasks to reflect the State of orders.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the information Register
//                              of the "Task of displaying the status of orders", there are also service columns:
//             * Document               - DocumentRef          - link to the document to be reflected
//             * RecordID    - UUID -
//             * RecordDate             - Date                    -
//             * Action               - String                  -
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
Procedure ReflectDocumentStatesInStateRegisters(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	MaintainedRegisters = MaintainedRegisters();
	
	Query = New Query;
	Query.SetParameter("Jobs", Jobs);
	
	StateRequestTexts = New Array;
	
	For Each RegisterName In MaintainedRegisters Do
		
		ParameterName = StrTemplate("Types%1", RegisterName);
		
		StateRequestText = StrTemplate("VALUETYPE(Jobs.Document) IN (&%1) AS %2",
											ParameterName,
											RegisterName);
		
		StateRequestTexts.Add(StateRequestText);
		
		Query.SetParameter(ParameterName, InformationRegisters[RegisterName].TypesOfOrdersToReflectStates());
		
	EndDo;
	
	QueryText =
	"SELECT
	|	Jobs.Document            AS Document,
	|	Jobs.Action            AS Action,
	|	Jobs.RecordID AS RecordID,
	|	Jobs.RecordDate          AS RecordDate
	|INTO Jobs
	|FROM
	|	&Jobs AS Jobs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.Document            AS Document,
	|	Jobs.Action            AS Action,
	|	Jobs.RecordID AS RecordID,
	|	&StateFields
	|FROM
	|	Jobs AS Jobs
	|
	|ORDER BY
	|	RecordDate
	|";
	
	Separator =
	",
	|	";
	
	Query.Text = StrReplace(QueryText, "&StateFields", StrConcat(StateRequestTexts, Separator));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	TaskTable = Result.Unload();
	
	For Each RegisterName In MaintainedRegisters Do
		TaskTable.Indexes.Add(RegisterName);
		TaskTable.Indexes.Add(StrTemplate("%1, Action", RegisterName));
	EndDo;
	
	For Each RegisterName In MaintainedRegisters Do
		
		FilerByRegister = New Structure(RegisterName, True);
		
		NumberOfRowsTotal = TaskTable.FindRows(FilerByRegister).Count();
		If NumberOfRowsTotal = 0 Then
			Continue;
		EndIf;
		
		DefaultMethodName = StrTemplate("InformationRegisters.%1.ReflectOrderStates", RegisterName);
		
		FilerByRegister.Insert("Action", "");
		TheOrdersTable = TaskTable.Copy(FilerByRegister, "Document, RecordID");
		
		If NumberOfRowsTotal = TheOrdersTable.Count() Then
			
			Reflected_Documents = Common.UnloadColumn(TheOrdersTable, "Document", True);
			
			PerformMethodToReflectStateOfDocuments(
				DefaultMethodName,
				Reflected_Documents,
				TheOrdersTable,
				IdsOfUnprocessedRecords);
			
		Else
			
			Action = TaskTable[0].Action;
			
			ActionsTable = InformationRegisters[RegisterName].ActionsToReflectStateOfOrders();
			
			Reflected_Documents = New Array;
			ProcessedRows  = New Array;
			
			For Each TableRow In TaskTable Do
				
				If Action <> TableRow.Action Then
					
					PerformMethodToReflectStateOfDocuments(
						NameOfMethodForReflectingStateOfDocuments(Action, ActionsTable, DefaultMethodName),
						Reflected_Documents,
						TaskTable.Copy(ProcessedRows),
						IdsOfUnprocessedRecords);
					
					Action = TableRow.Action;
					
					Reflected_Documents.Clear();
					ProcessedRows.Clear();
					
				EndIf;
				
				CurrentDocument = TableRow.Document;
				
				If Reflected_Documents.Find(CurrentDocument) = Undefined Then
					Reflected_Documents.Add(CurrentDocument);
				EndIf;
				
				ProcessedRows.Add(TableRow);
				
			EndDo;
			
			PerformMethodToReflectStateOfDocuments(
				NameOfMethodForReflectingStateOfDocuments(Action, ActionsTable, DefaultMethodName),
				Reflected_Documents,
				TaskTable.Copy(ProcessedRows),
				IdsOfUnprocessedRecords);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Initializes the action table to reflect the State of orders. It is used if you need to call the method for reflecting
// the State of orders, which differs from the standard "Ledgers [Register name].Reflect the status of orders."
// Methods of reflection are determined by the value of the Attribute "Action" of the Information register of the "Task of displaying the status of orders".
// 
// Returns:
//  ValueTable - action table for to reflect States:
//   * Action  - String - the action to perform the reflection method for.
//                          Required to fill in.
//   * MethodName - String - reflection method, the name of the export procedure in the format
//                          <object name>.<procedure name>, where <object name> is
//                          a generic module or object manager module.
//                          Required to fill in.
//
Function InitializeActionTableToReflectStateOfOrders() Export
	
	ActionsTable = New ValueTable;
	ActionsTable.Columns.Add("Action",  Common.StringTypeDetails(150));
	ActionsTable.Columns.Add("MethodName", Common.StringTypeDetails(1000));
	
	Return ActionsTable;
	
EndFunction

#EndRegion

#Region Private

// Returns an array of metadata of registers reflecting the State of orders.
//
// Parameters:
//  RegistersToReflectStateOfOrders - See RegistersToReflectStateOfOrders
//
// Returns:
//  Array of MetadataObject -
//
Function MaintainedRegisters(RegistersToReflectStateOfOrders = Undefined)
	
	ArrayOfRegisters = New Array();
	
	If RegistersToReflectStateOfOrders = Undefined Then
		
		ArrayOfRegisters.Add(Metadata.InformationRegisters.SalesOrderStates.Name);
		ArrayOfRegisters.Add(Metadata.InformationRegisters.PurchaseOrderStates.Name);
		ArrayOfRegisters.Add(Metadata.InformationRegisters.StatusesOfInternalOrders.Name);
		ArrayOfRegisters.Add(Metadata.InformationRegisters.ProductionStageStates.Name);
		ArrayOfRegisters.Add(Metadata.InformationRegisters.StatesOfProductionOrders.Name);
	Else
		
		If RegistersToReflectStateOfOrders.SalesOrderStates Then
			ArrayOfRegisters.Add(Metadata.InformationRegisters.SalesOrderStates.Name);
		EndIf;
		
		If RegistersToReflectStateOfOrders.PurchaseOrderStates Then
			ArrayOfRegisters.Add(Metadata.InformationRegisters.PurchaseOrderStates.Name);
		EndIf;
		
		If RegistersToReflectStateOfOrders.StatusesOfInternalOrders Then
			ArrayOfRegisters.Add(Metadata.InformationRegisters.StatusesOfInternalOrders.Name);
		EndIf;
		If RegistersToReflectStateOfOrders.ProductionStageStates Then
			ArrayOfRegisters.Add(Metadata.InformationRegisters.ProductionStageStates.Name);
		EndIf;
		
		If RegistersToReflectStateOfOrders.StatesOfProductionOrders Then
			ArrayOfRegisters.Add(Metadata.InformationRegisters.StatesOfProductionOrders.Name);
		EndIf;
	EndIf;
	
	Return ArrayOfRegisters
	
EndFunction

// Complements the request text of the state calculation engine.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTaskRequestText(Query, QueryText, TempTablesQueryText, TemporaryTableNames)
	For Each RegisterName In MaintainedRegisters() Do
		MatchingRequests = InformationRegisters[RegisterName].MatchingRequestsToControlRegisters(Query);
		
		For Each MapItem In MatchingRequests Do
			MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
				MapItem.Value,
				Query.TempTablesManager.Tables,
				QueryText,
				TempTablesQueryText,
				TemporaryTableNames);
		EndDo;
	EndDo;
EndProcedure

// Performs the method of reflecting the State of documents.
// 
// Parameters:
//  MethodName - String - the method of reflection.
//  Reflected_Documents - Array of DocumentRef - an array of references to the documents that need to reflect.
//  IDsTable - ValueTable - with columns:
//                            * Document - DocumentRef -
//                            * RecordID - UUID -
//  IdsOfUnprocessedRecords - See ReflectDocumentStatesInStateRegisters.IdsOfUnprocessedRecords
//
Procedure PerformMethodToReflectStateOfDocuments(
			MethodName,
			Reflected_Documents,
			IDsTable,
			IdsOfUnprocessedRecords)
	
	MethodParameters = New Array;
	MethodParameters.Add(Reflected_Documents);
	MethodParameters.Add(New Map); // Errors
	
	Common.ExecuteConfigurationMethod(MethodName, MethodParameters);
	
	Errors = MethodParameters[1];
	
	If Errors.Count() > 0 Then
		
		ErrorFields   = New Structure("Document");
		DataOfError = New Structure("Document");
		
		IDsTable.Indexes.Add("Document");
		
		For Each Error In Errors Do
			
			DataOfError.Document = Error.Key;
			
			ErrorText = DeferredJobs.ExecutionErrorText(ErrorFields, DataOfError, Error.Value);
			
			FoundRows = IDsTable.FindRows(DataOfError);
			For Each FoundRow In FoundRows Do
				
				IdsOfUnprocessedRecords.Insert(FoundRow.RecordID, ErrorText);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns the name of the method for reflecting the State of documents.
// 
// Parameters:
//  Action - String -
//  ActionsTable - See InitializeActionTableToReflectStateOfOrders
//  DefaultMethodName - String - the default reflection method.
// 
// Returns:
//  String - the method of reflection.
//  
Function NameOfMethodForReflectingStateOfDocuments(Action, ActionsTable, DefaultMethodName)
	
	If ValueIsFilled(Action) And ValueIsFilled(ActionsTable) Then
		
		FoundActionLines = ActionsTable.FindRows(New Structure("Action", Action));
		
		If FoundActionLines.Count() > 0 Then
			
			MethodName = FoundActionLines[0].MethodName;
			
		Else
			
			MethodName = DefaultMethodName;
			
		EndIf;
		
	Else
		
		MethodName = DefaultMethodName;
		
	EndIf;
	
	Return MethodName;
	
EndFunction

#EndRegion
