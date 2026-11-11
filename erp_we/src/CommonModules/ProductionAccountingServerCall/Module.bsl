////////////////////////////////////////////////////////////////////////////////
// OUP: Procedures of the subsystem of operational accounting of production
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


#Region RegistrationOfOperations

// Returns the transaction data from the queue
//
// Parameters:
//  OperationKey - InformationRegisterRecordKey.QueueOfProductionOperations - the recording key.
// 
// Returns:
//   - Structure - operation data from the queue.
//
Function OperationDataFromQueue(OperationKey) Export
	
	OperationData_ = OperationDataFromQueue_(OperationKey);
	
	If OperationData_.Count() <> 1 Then
		Return Undefined;
	EndIf;
	
	Return OperationData_[0];
	
EndFunction

// Returns operation data from the queue
//
// Parameters:
//  OperationKeys	 - Array, InformationRegisterRecordKey.QueueOfProductionOperations - the recording key.
// 
// Returns:
//  Array - list of operation data from the queue.
//
Function OperationDataFromQueue_(OperationKeys) Export
	
	IDs = TMCommonUseClientServer.Array(OperationKeys);
	
	QueryText = 
	"SELECT TOP 0
	|	
	|	ID.Department            AS Department,
	|	ID.Stage                     AS Stage,
	|	ID.Operation                 AS Operation,
	|	ID.OperationID    AS OperationID,
	|	ID.ProductionOperation AS ProductionOperation,
	|	ID.State                AS State
	|FROM
	|	InformationRegister.QueueOfProductionOperations AS ID
	|WHERE
	|	FALSE
	|;
	|SELECT
	|
	|	ID.Department            AS Department,
	|	ID.Stage                     AS Stage,
	|	ID.Operation                 AS Operation,
	|	ID.OperationID    AS OperationID,
	|	ID.ProductionOperation AS ProductionOperation,
	|	ID.State                AS State
	|
	|INTO ID
	|FROM
	|	&DataSource AS ID
	|;
	|SELECT
	|	Queue.Department             AS Department,
	|	Queue.TechnologicalProcess    AS TechnologicalProcess,
	//
	|	Queue.Operation                  AS Operation,
	|	Queue.OperationID     AS OperationID,
	|	Queue.ProductionOperation  AS ProductionOperation,
	|	Queue.State                 AS State,
	//
	|	CASE
	|		WHEN Queue.Operation.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN Queue.Operation.WorkCenter
	|		ELSE Queue.Operation.WorkCenter.WorkCenterType
	|	END AS WorkCenterType,
	|
	|	CASE
	|		WHEN Queue.Operation.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN ISNULL(Queue.Operation.WorkCenter.ParallelLoad, FALSE)
	|		ELSE ISNULL(Queue.Operation.WorkCenter.WorkCenterType.ParallelLoad, FALSE)
	|	END AS ParallelLoad,
	|	
	|	CASE
	|		WHEN Queue.Operation.WorkCenter REFS Catalog.WorkCenters
	|			THEN Queue.Operation.WorkCenter
	|		ELSE VALUE(Catalog.WorkCenters.EmptyRef)
	|	END AS WorkCenter,
	|
	|	CASE
	|		WHEN Queue.Operation.WorkCenter REFS Catalog.WorkCenters
	|			THEN CASE
	|					WHEN CAST(Queue.Operation.WorkCenter AS Catalog.WorkCenters) = VALUE(Catalog.WorkCenters.EmptyRef)
	|						THEN 1
	|					ELSE  CAST(Queue.Operation.WorkCenter AS Catalog.WorkCenters).WorkTimeFactor
	|				END
	|			ELSE 1
	|	END AS WorkTimeFactor,
	|	
	|	Queue.Operation.ProductionArea                         AS ProductionArea,
	|	Queue.Operation.UnitOfMeasure                AS UnitOfMeasure,
	|	Queue.Operation.Count                      AS NumberOfPieces,
	|	ISNULL(Queue.Operation.Skippable, FALSE) AS Skippable,
	//
	|	Queue.Stage                   AS Stage,
	|	Queue.Stage.Organization       AS Organization,
	//
	|	Queue.Scheduled          AS Scheduled,
	|	CASE
	|		WHEN Queue.Scheduled + Queue.RepetitionIsRequired > Queue.CreatedOn
	|			THEN Queue.Scheduled + Queue.RepetitionIsRequired - Queue.CreatedOn
	|		ELSE 0
	|	END                          AS WaitingForCreation,
	|	Queue.PendingPredecessorCompletion AS PendingPredecessorCompletion,
	|	Queue.PreviousOnesStarted   AS PreviousOnesStarted,
	|	Queue.ExecutionIsAllowed         AS ExecutionIsAllowed,
	|	Queue.Running            AS Running,
	|	Queue.Completed2              AS Completed2,
	|	Queue.RepetitionIsRequired      AS RepetitionIsRequired,
	|	Queue.Skipped3              AS Skipped3,
	//
	|	Queue.TimePerPiece           AS TimePerPiece,
	|	Queue.SetupTime                AS SetupTime,
	|	Queue.TimeUnitsOfMeasure             AS TimeUnitsOfMeasure,
	//
	|	Queue.Operation.Owner      AS OperationOwner,
	|	Queue.InArchive                AS InArchive
	|
	|FROM
	|	ID AS ID
	|		INNER JOIN InformationRegister.QueueOfProductionOperations AS Queue
	|		ON ID.Department            = Queue.Department
	|			AND ID.Stage                  = Queue.Stage
	|			AND ID.Operation              = Queue.Operation
	|			AND ID.OperationID = Queue.OperationID
	|			AND ID.ProductionOperation = Queue.ProductionOperation
	|			AND ID.State = Queue.State
	|";
	QueriesTexts = StrSplit(QueryText, ";", False);
	
	Query = New Query(QueriesTexts[0]);
	DataSource = Query.Execute().Unload();
	
	For Each Id In IDs Do
		NewRow = DataSource.Add();
		FillPropertyValues(NewRow, Id, "Department,Stage,Operation,OperationID,ProductionOperation,State");
	EndDo;
	
	Query = New Query(QueriesTexts[1] + ";" + QueriesTexts[2]);
	Query.SetParameter("DataSource", DataSource);
	
	Result = Common.ValueTableToArray(Query.Execute().Unload());
	Return Result;
	
EndFunction

// Returns data for filling in production operations
//
// Parameters:
//  OperationKeys			 - Array of InformationRegisterRecordKey.QueueOfProductionOperations - write key
//  AssignmentParameters		 - See ProductionAccountingClientServer.ParametersOfAssignmentOfProductionOperationConstructor
//  SetStatus_	 - EnumRef.ProductionOperationStatuses						 - status of the new document
//  CheckParameters_1		 - Boolean															 - True if you need to check whether the destination parameters match
// 
// Returns:
//  Array - data for filling in production operations.
//
Function DataForNewProductionOperations(OperationKeys, AssignmentParameters, SetStatus_ = Undefined, CheckParameters_1 = True) Export
	
	Query = New Query(
		"SELECT
		|
		|	ID.Department            AS Department,
		|	ID.Stage                     AS Stage,
		|	ID.Operation                 AS Operation,
		|	ID.OperationID    AS OperationID,
		|	ID.ProductionOperation AS ProductionOperation,
		|	ID.State                AS State,
		|	ID.WorkCenterType        AS WorkCenterType,
		|	ID.ProductionArea                  AS ProductionArea,
		|	ID.ShiftTask           AS ShiftTask,
		|	ID.SetupSettings           AS SetupSettings,
		|	ID.WorkCenter             AS WorkCenter,
		|	ID.Performer              AS Performer,
		|	ID.Count               AS Count
		|
		|INTO ID
		|FROM
		|	&DataSource AS ID
		|;
		|SELECT
		|	
		|	CASE
		|		WHEN ID.Operation <> VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|			THEN &FillingMethod
		|		ELSE """"
		|	END   AS FillingMethod,
		|	&Status AS Status,
		|
		|	ID.Department            AS Department,
		|	ID.Stage                     AS Stage,
		|	ID.Operation                 AS Operation,
		|	ID.OperationID    AS OperationID,
		|	ID.ProductionOperation AS ProductionOperation,
		|
		|	Queue.Operation.Control                AS Control,
		|	Queue.OperationNumber                    AS OperationNumber,
		|	Queue.NextOperation           AS NextOperation,
		|	Queue.ControlOperationID AS ControlOperationID,
		|
		|	CASE
		|		WHEN ID.WorkCenter <> VALUE(Catalog.WorkCenters.EmptyRef)
		|			THEN CAST(ID.WorkCenter AS Catalog.WorkCenters).WorkCenterType
		|		WHEN ID.WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|			THEN ID.WorkCenterType
		|		ELSE CASE
		|				WHEN Queue.Operation.WorkCenter REFS Catalog.WorkCenterTypes
		|					THEN Queue.Operation.WorkCenter
		|				ELSE ISNULL(Queue.Operation.WorkCenter.WorkCenterType, VALUE(Catalog.WorkCenterTypes.EmptyRef))
		|			END
		|	END             AS WorkCenterType,
		|	CASE
		|		WHEN ID.ProductionArea <> VALUE(Catalog.ProductionSites.EmptyRef)
		|			THEN ID.ProductionArea
		|		WHEN ID.WorkCenter <> VALUE(Catalog.WorkCenters.EmptyRef)
		|			THEN CAST(ID.WorkCenter AS Catalog.WorkCenters).ProductionArea
		|		ELSE Queue.Operation.ProductionArea
		|	END             AS ProductionArea,
		|	ID.ShiftTask AS ShiftTask,
		|	ID.WorkCenter   AS WorkCenter,
		|	CASE
		|		WHEN (ID.WorkCenter <> VALUE(Catalog.WorkCenters.EmptyRef)
		|			OR ID.WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef))
		|			AND ID.SetupSettings <> VALUE(Catalog.SetupOptions.EmptyRef)
		|			THEN ID.SetupSettings
		|		ELSE CASE
		|				WHEN Queue.Operation.SetupSettings REFS Catalog.SetupOptions
		|					THEN Queue.Operation.SetupSettings
		|				ELSE ISNULL(Queue.Operation.WorkCenter.WorkCenterType, VALUE(Catalog.SetupOptions.EmptyRef))
		|			END
		|	END             AS SetupSettings,
		|	ID.Performer    AS Performer,
		|
		|	CASE
		|		WHEN ID.Count <> 0
		|			THEN ID.Count
		|		ELSE
		|			CASE
		|				WHEN &Status = VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
		|					THEN
		|						CASE
		|							WHEN Queue.Scheduled + Queue.RepetitionIsRequired > Queue.CreatedOn
		|								THEN Queue.Scheduled + Queue.RepetitionIsRequired - Queue.CreatedOn
		|							ELSE 0
		|						END
		|				ELSE Queue.ExecutionIsAllowed
		|			END
		|	END             AS Count
		|
		|FROM
		|	ID AS ID
		|		INNER JOIN InformationRegister.QueueOfProductionOperations AS Queue
		|		ON ID.Department               = Queue.Department
		|			AND ID.Stage                     = Queue.Stage
		|			AND ID.Operation                 = Queue.Operation
		|			AND ID.OperationID    = Queue.OperationID
		|			AND ID.ProductionOperation = Queue.ProductionOperation
		|			AND ID.State                = Queue.State
		|
		|WHERE
		|	(NOT &CheckParameters_1
		|			OR &CheckParameters_1
		|				AND CASE
		|						WHEN Queue.Operation.WorkCenter IN (UNDEFINED,
		|																	VALUE(Catalog.WorkCenters.EmptyRef),
		|																	VALUE(Catalog.WorkCenterTypes.EmptyRef))
		|								OR (ID.WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|										AND ID.WorkCenter = VALUE(Catalog.WorkCenters.EmptyRef))
		|							THEN TRUE
		|						WHEN ID.WorkCenter <> VALUE(Catalog.WorkCenters.EmptyRef)
		|								AND CAST(ID.WorkCenter AS Catalog.WorkCenters).WorkCenterType IN (Queue.Operation.WorkCenter, Queue.Operation.WorkCenter.WorkCenterType)
		|							THEN TRUE
		|						WHEN ID.WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|								AND ID.WorkCenterType IN (Queue.Operation.WorkCenter, Queue.Operation.WorkCenter.WorkCenterType)
		|							THEN TRUE
		|						ELSE FALSE
		|					END
		|					AND CASE
		|						WHEN NOT Queue.Department.UseProductionSites
		|							THEN TRUE
		|						WHEN Queue.Operation.WorkCenter IN (UNDEFINED,
		|																	VALUE(Catalog.WorkCenters.EmptyRef),
		|																	VALUE(Catalog.WorkCenterTypes.EmptyRef))
		|								OR NOT VALUETYPE(Queue.Operation.WorkCenter) = TYPE(Catalog.WorkCenters)
		|							THEN TRUE
		|						WHEN ID.ProductionArea IN (Queue.Operation.WorkCenter.ProductionArea,
		|												Queue.Operation.ProductionArea,
		|												VALUE(Catalog.ProductionSites.EmptyRef))
		|							THEN TRUE
		|						ELSE FALSE
		|					END
		|					AND CASE
		|						WHEN Queue.Operation.WorkCenter IN (UNDEFINED,
		|																	VALUE(Catalog.WorkCenters.EmptyRef),
		|																	VALUE(Catalog.WorkCenterTypes.EmptyRef))
		|								OR NOT VALUETYPE(Queue.Operation.WorkCenter) = TYPE(Catalog.WorkCenters)
		|							THEN TRUE
		|						WHEN ID.WorkCenter IN (Queue.Operation.WorkCenter,
		|													VALUE(Catalog.WorkCenters.EmptyRef))
		|							THEN TRUE
		|						ELSE FALSE
		|					END
		|					AND CASE
		|						WHEN &Status = VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
		|							THEN CASE
		|									WHEN Queue.Scheduled + Queue.RepetitionIsRequired > Queue.CreatedOn
		|										THEN Queue.Scheduled + Queue.RepetitionIsRequired - Queue.CreatedOn
		|									ELSE 0
		|								END
		|						ELSE Queue.ExecutionIsAllowed
		|					END > 0
		|					AND CASE
		|						WHEN &Status = VALUE(Enum.ProductionOperationStatuses.IsSkipped)
		|							AND NOT Queue.Operation.Skippable
		|							THEN FALSE
		|						ELSE TRUE
		|					END
		|			OR ID.ProductionOperation <> VALUE(Document.ProductionOperation2_2.EmptyRef))");
	
	DataSource = New ValueTable;
	DataSource.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	DataSource.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	DataSource.Columns.Add("Operation", New TypeDescription("CatalogRef.ManufacturingOperations"));
	DataSource.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers));
	DataSource.Columns.Add("ProductionOperation", New TypeDescription("DocumentRef.ProductionOperation2_2"));
	DataSource.Columns.Add("State", New TypeDescription("EnumRef.OperationStates"));
	DataSource.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	DataSource.Columns.Add("ProductionArea", New TypeDescription("CatalogRef.ProductionSites"));
	DataSource.Columns.Add("ShiftTask", New TypeDescription("DocumentRef.ShiftTask"));
	DataSource.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	DataSource.Columns.Add("SetupSettings", New TypeDescription("CatalogRef.SetupOptions"));
	DataSource.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers));
	DescriptionOfPerformerTypes = New TypeDescription("CatalogRef.Teams,CatalogRef.Persons");
	DataSource.Columns.Add("Performer", DescriptionOfPerformerTypes);
	
	For Each Id In TMCommonUseClientServer.Array(OperationKeys) Do
		NewRow = DataSource.Add();
		FillPropertyValues(NewRow, Id, "Department,Stage,Operation,OperationID,ProductionOperation,State");
		FillPropertyValues(NewRow, AssignmentParameters);
	EndDo;
	
	Query.SetParameter("FillingMethod", "FillInByOperation");
	Query.SetParameter("Status", ?(SetStatus_ <> Undefined,
		SetStatus_,
		Enums.ProductionOperationStatuses.CreatedOn_));
	Query.SetParameter("DataSource", DataSource);
	Query.SetParameter("CheckParameters_1", CheckParameters_1);
	
	Return Common.ValueTableToArray(Query.Execute().Unload());
	
EndFunction

// Forms production operations
//
// Parameters:
//  OperationKeys			 - Array of InformationRegisterRecordKey.QueueOfProductionOperations - write key
//  AssignmentParameters		 - See ProductionAccountingClientServer.ParametersOfAssignmentOfProductionOperationConstructor
//  SetStatus_	 - EnumRef.ProductionOperationStatuses						 - status of the new document
// 
// Returns:
//  See ProductionAccountingClientServer.ResultOfFormationOfProductionOfOperationsConstructor
//
Function GenerateProductionOperations(OperationKeys, AssignmentParameters, SetStatus_ = Undefined) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ShopManagement.FormationOfProductionOperations");
	
	Array = TMCommonUseClientServer.Array(OperationKeys);
	Result = FormProductionOperationsInsideTimeMeasurement(Array, AssignmentParameters, SetStatus_);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Array.Count());
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private


Function FormProductionOperationsInsideTimeMeasurement(OperationKeys, AssignmentParameters, SetStatus_)
	
	Result = ProductionAccountingClientServer.ResultOfFormationOfProductionOfOperationsConstructor();
	
	DataSource = InformationRegisters.QueueOfProductionOperations.CreateRecordSet().UnloadColumns("Department,Stage,Operation,OperationID");
	
	For Each Var_Key In OperationKeys Do
		FillPropertyValues(DataSource.Add(), Var_Key, "Department,Stage,Operation,OperationID");
	EndDo;
	
	ShiftJobsAreUsed = AssignmentParameters.Property("ShiftTask") And ValueIsFilled(AssignmentParameters.ShiftTask);
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		
		If ShiftJobsAreUsed Then
			LockItem = Block.Add("Document.ShiftTask");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Ref", AssignmentParameters.ShiftTask);
		EndIf;
		
		LockItem = Block.Add("InformationRegister.QueueOfProductionOperations");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = DataSource;
		LockItem.UseFromDataSource("Department", "Department");
		LockItem.UseFromDataSource("Stage", "Stage");
		LockItem.UseFromDataSource("Operation", "Operation");
		LockItem.UseFromDataSource("OperationID", "OperationID");
		
		Block.Lock();
		
		ListOfFillingData = DataForNewProductionOperations(
			OperationKeys,
			AssignmentParameters, 
			SetStatus_);
			
		If ListOfFillingData.Count() > 0 Then
			
			If ShiftJobsAreUsed Then
				ShiftTaskStatus = Common.ObjectAttributeValue(AssignmentParameters.ShiftTask, "Status");
				If ShiftTaskStatus = Enums.ShiftTaskStatuses.BeingGenerated Then
					Documents.ShiftTask.SetStatus(AssignmentParameters.ShiftTask, Enums.ShiftTaskStatuses.Generated_);
				EndIf;
			EndIf;
			
			For Each CurrentData In ListOfFillingData Do
				
				FillingData = CurrentData;
				
				If ValueIsFilled(FillingData.ProductionOperation) Then
					Result.SpecialTerms.Add(FillingData.ProductionOperation);
					OperationObject = FillingData.ProductionOperation.GetObject();
					ProductionAccounting.BlockProductionOperation(OperationObject);
					FillingData = ProductionAccountingClientServer.ParametersOfAssignmentOfProductionOperationConstructor(True);
					FillingData.Insert("Status");
					FillPropertyValues(FillingData, CurrentData);
					Counter = Result.UpdatedOperations;
				Else
					OperationObject = Documents.ProductionOperation2_2.CreateDocument();
					Counter = Result.OperationsAreCreated;
				EndIf;
				
				OperationObject.Fill(FillingData);
				
				If AssignmentParameters.Property("ActivityKinds") Then
					ActivityKinds = AssignmentParameters.ActivityKinds;// FormDataCollection
					Filter = New Structure("WorkKind");
					
					For Each String In OperationObject.LaborCosts Do
						
						Filter.WorkKind = String.WorkKind;
						LineActivityKind = ActivityKinds.FindRows(Filter);
						
						If LineActivityKind.Count() <> 0 Then
							String.Performer = LineActivityKind[0].Performer;
						EndIf;
						
					EndDo;
					
				EndIf;
				
				If OperationObject.CheckFilling() Then
					
					OperationObject.Write(DocumentWriteMode.Posting);
					Counter.Add(OperationObject.Ref);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Thực hiện giao dịch';
				|ru = 'Выполнение операции';
				|en = 'Performing operation'; fa = 'در حال اجرای عملیات';
				|it = 'Svolgimento dell''operazione';
				|pl = 'Wykonanie operacji';
				|tr = 'İşlemin gerçekleştirilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		Result.OperationsAreCreated.Clear();
		Result.UpdatedOperations.Clear();
		
	EndTry;
	
	Result.TotalCount1 = DataSource.Count();
	Result.ProcessedItemsCount = Result.UpdatedOperations.Count() + Result.OperationsAreCreated.Count();
	
	Return Result;
	
EndFunction

// Returns the filling structure for generating development documents based on the passed selection or order lines.
// The function analyzes the number of documents to be generated. if you need to generate a single document,
// the structure of filling is returned, otherwise the selection parameters for group generation are returned.
//
// Parameters:
//	Filter	- Structure - Contains data for selection:
//  						* References - Array - documents on the basis of which the development is executed
//  						* Departments - Array - divisions for which the output is issued
//	IDs	- Array - IDs if the following parameter is passed to the collection of Analytics for formatting
//	Collection	- FormDataCollection - collection of Analytics that are used for generating output.
//
// Returns:
//   Structure   - contains fields for filling in new documents.
//
Function DesignParametersForEmployees(Filter = Undefined, IDs = Undefined, Collection = Undefined) Export
	
	If Filter <> Undefined Then
		ToRegister = Documents.WorkOutput.LaborCostsToRegister(Filter);
		Rows = ToRegister.Unload();
	Else
		Rows = IDs;
	EndIf;
	
	If Rows.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Departments = New Array;
	TimeIntervals = New Array;
	Teams = New Array;
	Employees = New Array;
	EmployeesHR = New Array;
	Companies = New Array;
	References = New Array;
	WorkOrderKinds = New Array;
	StructuralSelection = New Array;
	
	// parameters for checking the number of documents
	CurrentCompany = Undefined;
	CurrentDepartment = Undefined;
	CurAttire = Undefined;
	CurBrigade = Undefined;
	CurrentStartOfThePeriod = Undefined;
	CurEndOfPeriod = Undefined;
	CurrentMonth = Undefined;
	
	OneDocumentIsRequired = True;
	
	For Each Iterator_SSLy In Rows Do
		
		If Collection <> Undefined Then
			String = Collection.FindByID(Iterator_SSLy);
		Else
			String = Iterator_SSLy;
		EndIf;
		
		If CurrentCompany = Undefined Then
			CurrentCompany = String.Organization;
		ElsIf CurrentCompany <> String.Organization Then
			OneDocumentIsRequired = False;
		EndIf;
		
		If CurrentDepartment = Undefined Then
			CurrentDepartment = String.Department;
		ElsIf CurrentDepartment <> String.Department Then
			OneDocumentIsRequired = False;
		EndIf;
		
		If CurAttire = Undefined Then
			CurAttire = String.WorkOrderKind;
		ElsIf CurAttire <> String.WorkOrderKind Then
			OneDocumentIsRequired = False;
		EndIf;
		
		If CurBrigade = Undefined And ValueIsFilled(String.Team) Then
			CurBrigade = String.Team;
		ElsIf CurBrigade <> String.Team And ValueIsFilled(String.Team) Then
			OneDocumentIsRequired = False;
		EndIf;
		
		If CurrentStartOfThePeriod = Undefined Then
			CurrentStartOfThePeriod = String.BeginOfPeriod;
		ElsIf CurrentStartOfThePeriod <> String.BeginOfPeriod Then
			OneDocumentIsRequired = False;
		EndIf;
		
		If CurEndOfPeriod = Undefined Then
			CurEndOfPeriod = EndOfDay(String.EndOfPeriod);
		ElsIf CurEndOfPeriod <> String.EndOfPeriod Then
			OneDocumentIsRequired = False;
		EndIf;
		
		Month = BegOfMonth(?(ValueIsFilled(String.ExecutionDate), String.ExecutionDate, String.BeginOfPeriod));
		If CurrentMonth = Undefined Then
			CurrentMonth = Month
		ElsIf CurrentMonth <> Month Then
			OneDocumentIsRequired = False;
		EndIf;

		Departments.Add(String.Department);
		TimeIntervals.Add(String.BeginOfPeriod);
		Companies.Add(String.Organization);
		WorkOrderKinds.Add(String.WorkOrderKind);
		
		If ValueIsFilled(String.Team) Then
			Teams.Add(String.Team);
		EndIf;
		
		If ValueIsFilled(String.Employee_) Then
			Employees.Add(String.Employee_);
		EndIf;
		
		If ValueIsFilled(String.Performer) And TypeOf(String.Performer) = Type("CatalogRef.EmployeesHR") Then
			EmployeesHR.Add(String.Performer);
		EndIf;
		
		If ValueIsFilled(String.ReferenceOrder) Then
			References.Add(String.ReferenceOrder);
		EndIf;
		
		If ValueIsFilled(String.WorkOrderKind) And ValueIsFilled(String.Department) Then
			FilterStructure1 = New Structure("Department, WorkOrderKind, Team");
			FilterStructure1.Department = String.Department;
			FilterStructure1.WorkOrderKind = String.WorkOrderKind;
			FilterStructure1.Team = ?(ValueIsFilled(String.Team), String.Team, PredefinedValue("Catalog.Teams.EmptyRef"));
			StructuralSelection.Add(FilterStructure1);
		EndIf;
		
	EndDo;
	
	Result = New Structure;
	
	Result.Insert("Departments",   Departments);
	Result.Insert("TimeIntervals",         TimeIntervals);
	Result.Insert("Teams",         Teams);
	Result.Insert("Employees",       Employees);
	Result.Insert("EmployeesHR",      EmployeesHR);
	Result.Insert("Companies",     Companies);
	Result.Insert("References",    References);
	Result.Insert("WorkOrderKinds",     WorkOrderKinds);
	
	Result.Insert("IncludeInPeriodOfWork", True);
	
	Result.Insert("StructuralSelection", StructuralSelection);
	
	Result.Insert("OneDocumentIsRequired", OneDocumentIsRequired);
	
	If OneDocumentIsRequired Then
		
		Result.Insert("Department",     CurrentDepartment);
		Result.Insert("Organization",       CurrentCompany);
		Result.Insert("WorkOrderKind",         CurAttire);
		Result.Insert("BeginOfPeriod",     CurrentStartOfThePeriod);
		Result.Insert("EndOfPeriod",      CurEndOfPeriod);
		Result.Insert("Month",             CurrentMonth);
		
		If ValueIsFilled(CurBrigade) Then
			Result.Insert("Team",       CurBrigade);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure RecordResultOfOFOperationControl(ProtocolEntries, RecalculateStandards, DocumentRef) Export
	
	SetPrivilegedMode(True);
	
	DocumentObject = DocumentRef.GetObject(); // DocumentObject.ProductionOperation2_2
	
	ResultsBeforeChange = ProductionAccountingClientServer.StructureOfResultsConstructor(DocumentObject);
	
	For Each RecordingProtocol In ProtocolEntries Do // See ProductionAccountingClientServer.RecordProtocolConstructor
		
		Documents.ProductionOperation2_2.AddProtocolEntry(
			DocumentObject,
			RecordingProtocol);
		
	EndDo;
	
	If RecalculateStandards Then
		If DocumentObject.BasedOnMasterData Then
			DocumentObject.FillInTransactionStandards(,True,True);
		Else
			DocumentObject.RecalculateResourcesOfIndividualOperation(ResultsBeforeChange);
		EndIf;
	EndIf;
	
	Documents.ProductionOperation2_2.CalculateStatusWhenAttributesAreChanged(DocumentObject);
	
	If DocumentObject.CheckFilling() Then
		DocumentObject.Write(DocumentWriteMode.Posting);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function ParametersForProcessingEmployeesWorkOnShiftAssignments(ShiftJobs) Export
	
	Query = New Query("
	|SELECT
	|	Operations.Ref AS Operation
	|FROM
	|	Document.ProductionOperation2_2 AS Operations
	|WHERE
	|	Operations.ShiftTask IN (&ShiftJobs)
	|
	|");
	
	Query.SetParameter("ShiftJobs", ShiftJobs);
	
	References = Query.Execute().Unload();
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("References", References);
	
	Return DesignParametersForEmployees(FilterStructure1);
	
EndFunction

// Generates the "employee Development" documents for the submitted selection.
//
// Parameters:
//	FilterStructure1	- Structure - Contains data for selection:
//  						* References - Array - documents on the basis of which the development is executed
//  						* Departments - Array -  the divisions for which the output is issued.
//
// Returns:
//   Structure   - contains arrays of generated documents and messages to the user.
//
Function FormDevelopmentOfSelectionStaff(FilterStructure1) Export
	
	AddressInStorage = PutToTempStorage(Undefined);
	Documents.WorkOutput.GenerateDocuments(FilterStructure1, AddressInStorage);
	
	Return GetFromTempStorage(AddressInStorage);
	
EndFunction

#EndRegion
