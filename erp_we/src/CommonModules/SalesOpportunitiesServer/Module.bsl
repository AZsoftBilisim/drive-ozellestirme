
#Region Public

// Returns the current stage of the sales process
//
// Parameters:
// SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer - link to the transaction for which you need to determine the current stage.
//
// Returns:
//   CatalogRef.ProcessesStates - the current stage of the transaction.
//
Function GetCurStage(SalesOpportunity) Export

	Query = New Query(
		"SELECT TOP 1
		|	StatisticsOfCustomerOpportunities.ProcessStep AS ProcessStep
		|FROM
		|	InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
		|WHERE
		|	StatisticsOfCustomerOpportunities.SalesOpportunity = &SalesOpportunity
		|	AND StatisticsOfCustomerOpportunities.Result = VALUE(Enum.OpportunityStatuses.InProgress)
		|
		|ORDER BY
		|	StatisticsOfCustomerOpportunities.ProcessStep.AddlOrderingAttribute DESC");
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Stages = Query.Execute().Select();
	Return ?(Stages.Next(), Stages.ProcessStep, Catalogs.ProcessesStates.EmptyRef());

EndFunction

// Returns a structure with the estimated probability of winning a trade and its components
//
// Parameters:
//  SalesOpportunity    - CatalogRef.SalesOpportunitiesToCustomer       - a transaction whose probability of successful completion is calculated.
//
// Returns:
//   Structure - contains the following fields:
//    *StepTotal  - Number - the probability based on the statistics of the stage.
//    *ByManager  - Number - probability based on the Manager's statistics.
//    *ByPartner   - Number - the probability based on the statistics of the partner.
//    *ByTransactionKind - Number - probability based on statistics for the type of transaction.
//    *Medium      - Number - average value of the previous parameters.
//    *Calculated    - Number - 100 if the deal is closed and won and the average if in progress.
//
Function CalculateProbability(SalesOpportunity) Export

	// get the necessary transaction details
	INFTransaction = Common.ObjectAttributesValues(SalesOpportunity, New Structure("Status,ProbabilityOfSuccessfulCompletion, Closed_"));

	// Get a probability estimate by the manager
	If ValueIsFilled(INFTransaction.ProbabilityOfSuccessfulCompletion) Then
		NumberOfComponents_1 = 1;
		EstimatedProbability   = INFTransaction.ProbabilityOfSuccessfulCompletion;
	Else
		NumberOfComponents_1 = 0;
		EstimatedProbability   = 0;
	EndIf;
	
	SetPrivilegedMode(True);

	// Get statistical probabilities
	Query = New Query(
		"SELECT
		|	SalesOpportunitiesToCustomer.Ref,
		|	SalesOpportunitiesToCustomer.SalesOpportunityKind,
		|	SalesOpportunitiesToCustomer.EmployeeResponsible,
		|	SalesOpportunitiesToCustomer.Partner
		|INTO CurDeal
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	StatisticsOfCustomerOpportunities.ProcessStep
		|INTO CurrentStep
		|FROM
		|	CurDeal AS CurDeal
		|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
		|		ON CurDeal.Ref = StatisticsOfCustomerOpportunities.SalesOpportunity
		|
		|ORDER BY
		|	StatisticsOfCustomerOpportunities.ProcessStep.AddlOrderingAttribute DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(StatisticsOfCustomerOpportunities.SalesOpportunity) AS Count
		|INTO WonFromStage
		|FROM
		|	CurrentStep AS CurrentStep
		|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
		|		ON CurrentStep.ProcessStep = StatisticsOfCustomerOpportunities.ProcessStep
		|WHERE
		|	StatisticsOfCustomerOpportunities.SalesOpportunity.Status = VALUE(Enum.OpportunityStatuses.Won)
		|	AND (NOT StatisticsOfCustomerOpportunities.SalesOpportunity.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(StatisticsOfCustomerOpportunities.SalesOpportunity) AS Count
		|INTO DefinedFromStage
		|FROM
		|	CurrentStep AS CurrentStep
		|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
		|		ON CurrentStep.ProcessStep = StatisticsOfCustomerOpportunities.ProcessStep
		|WHERE
		|	StatisticsOfCustomerOpportunities.SalesOpportunity.Status <> VALUE(Enum.OpportunityStatuses.InProgress)
		|	AND (NOT StatisticsOfCustomerOpportunities.SalesOpportunity.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(*) AS Count
		|INTO WonByManager
		|FROM
		|	CurDeal AS CurDeal
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON CurDeal.EmployeeResponsible = SalesOpportunitiesToCustomer.EmployeeResponsible
		|WHERE
		|	SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(*) AS Count
		|INTO DefinedByManager
		|FROM
		|	CurDeal AS CurDeal
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON CurDeal.EmployeeResponsible = SalesOpportunitiesToCustomer.EmployeeResponsible
		|WHERE
		|	SalesOpportunitiesToCustomer.Status <> VALUE(Enum.OpportunityStatuses.InProgress)
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(*) AS Count
		|INTO WonBySight
		|FROM
		|	CurDeal AS CurDeal
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON CurDeal.SalesOpportunityKind = SalesOpportunitiesToCustomer.SalesOpportunityKind
		|WHERE
		|	SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(*) AS Count
		|INTO DefinedBySpecies
		|FROM
		|	CurDeal AS CurDeal
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON CurDeal.SalesOpportunityKind = SalesOpportunitiesToCustomer.SalesOpportunityKind
		|WHERE
		|	SalesOpportunitiesToCustomer.Status <> VALUE(Enum.OpportunityStatuses.InProgress)
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(*) AS Count
		|INTO WonByPartner
		|FROM
		|	CurDeal AS CurDeal
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON CurDeal.Partner = SalesOpportunitiesToCustomer.Partner
		|WHERE
		|	SalesOpportunitiesToCustomer.Status = VALUE(Enum.OpportunityStatuses.Won)
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(*) AS Count
		|INTO DefinedByPartner
		|FROM
		|	CurDeal AS CurDeal
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		ON CurDeal.Partner = SalesOpportunitiesToCustomer.Partner
		|WHERE
		|	SalesOpportunitiesToCustomer.Status <> VALUE(Enum.OpportunityStatuses.InProgress)
		|	AND (NOT SalesOpportunitiesToCustomer.DeletionMark)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN ISNULL(DefinedFromStage.Count, 1) = 0
		|			THEN 0
		|		ELSE ISNULL(WonFromStage.Count, 0) / ISNULL(DefinedFromStage.Count, 1) * 100
		|	END AS ByStep,
		|	CASE
		|		WHEN ISNULL(DefinedByManager.Count, 1) = 0
		|			THEN 0
		|		ELSE ISNULL(WonByManager.Count, 0) / ISNULL(DefinedByManager.Count, 1) * 100
		|	END AS ByManager,
		|	CASE
		|		WHEN ISNULL(DefinedBySpecies.Count, 1) = 0
		|			THEN 0
		|		ELSE ISNULL(WonBySight.Count, 0) / ISNULL(DefinedBySpecies.Count, 1) * 100
		|	END AS ByTransactionKind,
		|	CASE
		|		WHEN ISNULL(DefinedByPartner.Count, 1) = 0
		|			THEN 0
		|		ELSE ISNULL(WonByPartner.Count, 0) / ISNULL(DefinedByPartner.Count, 1) * 100
		|	END AS ByPartner
		|FROM
		|	WonBySight AS WonBySight,
		|	WonByManager AS WonByManager,
		|	WonByPartner AS WonByPartner,
		|	WonFromStage AS WonFromStage,
		|	DefinedBySpecies AS DefinedBySpecies,
		|	DefinedByManager AS DefinedByManager,
		|	DefinedByPartner AS DefinedByPartner,
		|	DefinedFromStage AS DefinedFromStage");
	Query.SetParameter("SalesOpportunity",SalesOpportunity);
	Selection = Query.Execute().Select();

	// Initial values
	Result = New Structure("StepTotal,ByManager,ByPartner,ByTransactionKind,Medium,Calculated");

	// fill in the result with statistical data
	If Selection.Next() Then
		If Selection.ByStep > 0 Then
			Result.StepTotal  = Round(Selection.ByStep,2);
			EstimatedProbability   = EstimatedProbability + Result.StepTotal; 
			NumberOfComponents_1 = NumberOfComponents_1 + 1;
		EndIf;
		If Selection.ByManager > 0 Then
			Result.ByManager  = Round(Selection.ByManager,2);
			EstimatedProbability   = EstimatedProbability + Result.ByManager; 
			NumberOfComponents_1 = NumberOfComponents_1 + 1;
		EndIf;
		If Selection.ByPartner > 0 Then
			Result.ByPartner   = Round(Selection.ByPartner,2);
			EstimatedProbability   = EstimatedProbability + Result.ByPartner; 
			NumberOfComponents_1 = NumberOfComponents_1 + 1;
		EndIf;
		If Selection.ByTransactionKind > 0 Then
			Result.ByTransactionKind = Round(Selection.ByTransactionKind,2);
			EstimatedProbability   = EstimatedProbability + Result.ByTransactionKind;
			NumberOfComponents_1 = NumberOfComponents_1 + 1;
		EndIf;
	EndIf;

	// fill in the result with calculated data
	If NumberOfComponents_1 > 0 Then
		Result.Medium = EstimatedProbability/NumberOfComponents_1;
	EndIf;
	
	If INFTransaction.Status = Enums.OpportunityStatuses.Lost Then
		Result.Calculated = 0;
	ElsIf INFTransaction.Closed_ Then
		Result.Calculated = 100;
	Else
		Result.Calculated = Result.Medium;
	EndIf;

	Return Result;

EndFunction

// Sets the stage of the sale process for the transaction.
// Parameters:
//  SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer   - link to the transaction for which the transition is made.
//  Stage   - CatalogRef.ProcessesStates - the stage, which is necessary to translate the deal.
//
Procedure SetProcessStage(SalesOpportunity, Stage) Export

	// find the current stage of the transaction
	CurrentStep = GetCurStage(SalesOpportunity);

	// fill in statistics
	If CurrentStep = Catalogs.ProcessesStates.EmptyRef() Then
		
		// the first record of the transaction
		Record = GetStatisticsRecord(SalesOpportunity, Stage);
		Record.Write();
	Else
		
		// get information about the transaction
		Query = New Query(
			"SELECT
			|	SalesOpportunitiesToCustomer.SalesOpportunityKind,
			|	SalesOpportunitiesToCustomer.SalesOpportunityKind.SalesOpportunityType AS SalesOpportunityType,
			|	SalesOpportunitiesToCustomer.Status,
			|	SalesOpportunitiesToCustomer.ManualControlEnabled
			|FROM
			|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
			|WHERE
			|	SalesOpportunitiesToCustomer.Ref = &SalesOpportunity");
		Query.SetParameter("SalesOpportunity", SalesOpportunity);
		InfTransactions = Query.Execute().Select();
		InfTransactions.Next();
		
		If InfTransactions.SalesOpportunityType = Enums.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement
			Or InfTransactions.ManualControlEnabled Then
			// transactions with process management "manually"
			
			// get stages by type of transaction
			Query = New Query(
				"SELECT
				|	CustomerOpportunityKindsSalesOpportunityStages.SaleProcessStage
				|FROM
				|	Catalog.CustomerOpportunityKinds.SalesOpportunityStages AS CustomerOpportunityKindsSalesOpportunityStages
				|WHERE
				|	CustomerOpportunityKindsSalesOpportunityStages.Ref = &SalesOpportunityKind
				|
				|ORDER BY
				|	CustomerOpportunityKindsSalesOpportunityStages.LineNumber");
			Query.SetParameter("SalesOpportunityKind", InfTransactions.SalesOpportunityKind);
			Stages = Query.Execute().Unload();

			// determine the direction of movement
			// determine the direction of movement
			CurStageLine = Stages.Find(CurrentStep, "SaleProcessStage");
			If CurStageLine = Undefined Then
				IndexOfCurrentStage = -1;
			Else
				IndexOfCurrentStage = Stages.IndexOf(CurStageLine);
			EndIf;
			IndexOfStage = Stages.IndexOf(Stages.Find(Stage, "SaleProcessStage"));
			If IndexOfStage > IndexOfCurrentStage Then
				// transition to the next stage
				CloseStatistics(SalesOpportunity, CurrentStep);
				For StageCounter = IndexOfCurrentStage + 1 To IndexOfStage Do
					StageToAdd = Stages[StageCounter].SaleProcessStage;
					Record = GetStatisticsRecord(SalesOpportunity, StageToAdd);
					If StageCounter < IndexOfStage Then
						Record.EndDate     = Record.StartDate;
						Record.Duration = Duration(Record.StartDate, Record.EndDate);
						Record.Result         = Enums.OpportunityStatuses.Won;
					EndIf;
					Record.Write();
				EndDo;
			Else
				// return to the previous stage

				// adjust statistics
				// delete canceled stages
				Selection = InformationRegisters.StatisticsOfCustomerOpportunities.Select(New Structure("SalesOpportunity",SalesOpportunity));
				While Selection.Next() Do
					CurrentIndex = Stages.IndexOf(Stages.Find(Selection.ProcessStep, "SaleProcessStage"));
					If CurrentIndex <= IndexOfCurrentStage And CurrentIndex > IndexOfStage Then
						Record = Selection.GetRecordManager();
						Record.Delete();
					EndIf;
				EndDo;
				
				// reset the closure of the current stage
				Record = GetStatisticsRecord(SalesOpportunity, Stage);
				Record.EmployeeResponsible     = Users.CurrentUser();
				Record.EndDate     = Undefined;
				Record.Duration = Undefined;
				Record.Result         = ?(
					InfTransactions.Status = Enums.OpportunityStatuses.Lost,
					Enums.OpportunityStatuses.Lost, Enums.OpportunityStatuses.InProgress);
				Record.Write();
			EndIf;
		Else
			// transactions with business process management
			
			CloseStatistics(SalesOpportunity, CurrentStep);
			Record = GetStatisticsRecord(SalesOpportunity, Stage);
			Record.Write();
		EndIf;

	EndIf;

EndProcedure

// Find or create a record of transaction statistics
// Parameters:
//  SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer   - the transaction for which the record is created.
//  Stage   - CatalogRef.ProcessesStates - stage of the sales process.
//
// Returns:
//   InformationRegisterRecordManager.StatisticsOfCustomerOpportunities - a record found or created.
//
Function GetStatisticsRecord(SalesOpportunity, Stage) Export

	Record = InformationRegisters.StatisticsOfCustomerOpportunities.CreateRecordManager();
	Record.SalesOpportunity       = SalesOpportunity;
	Record.ProcessStep = Stage;
	Record.Read();
	If Not Record.Selected() Then
		Record.SalesOpportunity        = SalesOpportunity;
		Record.Result     = Enums.OpportunityStatuses.InProgress;
		Record.Potential     = Common.ObjectAttributeValue(SalesOpportunity, "PotentialSaleAmount");
		Record.StartDate    = CurrentSessionDate();
		Record.ProcessStep  = Stage;
		Record.EmployeeResponsible = Users.CurrentUser();
	EndIf;

	Return Record;

EndFunction

// Record the completion of a stage in statistics
// Parameters:
//  SalesOpportunity          - CatalogRef.SalesOpportunitiesToCustomer - the transaction for which the record is created.
//  Stage            - CatalogRef.ProcessesStates - the closing stage of the sales process.
//  CancelingLoss - Boolean - indicates that the loss of the trade is being canceled.
//
Procedure CloseStatistics(SalesOpportunity, Stage, CancelingLoss = False) Export

	PotentialSaleAmount = Common.ObjectAttributeValue(SalesOpportunity, "PotentialSaleAmount");

	Record = GetStatisticsRecord(SalesOpportunity, Stage);
	Record.EndDate     = CurrentSessionDate();
	Record.Potential         = PotentialSaleAmount;
	Record.Duration = Duration(Record.StartDate, Record.EndDate);
	Record.Result         = ?(
		Record.Result = Enums.OpportunityStatuses.InProgress Or CancelingLoss,
		Enums.OpportunityStatuses.Won,
		Record.Result);
	Record.Write();

EndProcedure

// Fills in the details of sales process tasks when they are created.
//
// Parameters:
//  SalesOpportunity                      - CatalogRef.SalesOpportunitiesToCustomer - the transaction that the process was created for.
//  Process_                     - BusinessProcessRef.StandardSale - business process of sale.
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef - point of the route that created the problem.
//  TasksBeingFormed           - Array of TaskRef.PerformerTask - array of generated tasks.
//
Procedure FillInProcessTaskDetails(SalesOpportunity, Process_, BusinessProcessRoutePoint, TasksBeingFormed) Export

	// form the name of the tasks
	TaskDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 theo vụ việc %2';
			|ru = '%1 по сделке %2';
			|en = '%1 under the sales opportunity %2'; fa = '%1 under the sales opportunity %2';
			|it = '%1 secondo la transazione %2';
			|pl = '%1 wg umowy %2';
			|tr = '%1 satış fırsatına göre %2'"),
		BusinessProcessRoutePoint,
		SalesOpportunity);

	ResponsibleForTransaction = Common.ObjectAttributeValue(SalesOpportunity,"EmployeeResponsible");
	
	// fill in the banking details
	For Each ProcessTask In TasksBeingFormed Do
		
		Task = ProcessTask; // TaskObject.PerformerTask - 
		Task.Description      = TaskDescription;
		Task.Importance          = Enums.TaskImportanceOptions.Ordinary;
		Task.LongDesc          = Process_.PointDescription(BusinessProcessRoutePoint);
		Task.TaskDueDate    = CurrentSessionDate() + Process_.TaskDueDate(BusinessProcessRoutePoint)*86400;
		Task.Author             = ResponsibleForTransaction;
		Task.Performer       = ResponsibleForTransaction;
		Task.SubjectOf           = SalesOpportunity;
	EndDo;

EndProcedure

// Creates and runs an instance of the business process for a transaction
// Parameters:
//  SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer - the transaction that the process is created for.
//
Procedure StartProcess(Val SalesOpportunity) Export
	
	// get the necessary transaction details
	Query = New Query(
		"SELECT
		|	SalesOpportunitiesToCustomer.Description,
		|	SalesOpportunitiesToCustomer.EmployeeResponsible,
		|	SalesOpportunitiesToCustomer.SalesOpportunityKind.SalesOpportunityType AS SalesOpportunityType
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &Ref");
	Query.SetParameter("Ref", SalesOpportunity);
	INFTransaction = Query.Execute().Select();
	INFTransaction.Next();

	// determine the number of active processes for a transaction
	ProcessName = GetDescriptionOfTransactionType(INFTransaction.SalesOpportunityType).Name;
	Query = New Query;
	
	Query.Text = "
		|SELECT
		|	COUNT(*) AS NumberOfProcesses
		|FROM
		|	&BusinessProcessName AS SalesProcess
		|WHERE
		|	SalesProcess.Started
		|	AND NOT SalesProcess.Completed
		|	AND SalesProcess.SubjectOf = &SalesOpportunity";
	
	Query.Text = StrReplace(Query.Text, "&BusinessProcessName", "BusinessProcess." + ProcessName);	
	Query.SetParameter("SalesOpportunity", SalesOpportunity);

	// start the business process of selling, if not started
	Selection = Query.Execute().Select();
	Selection.Next();
	If Selection.NumberOfProcesses = 0 Then
		
		BeginTransaction();
		
		Try
			
			Process_ = BusinessProcesses[ProcessName].CreateBusinessProcess(); // BusinessProcessObject.StandardSale 
			Process_.Date         = CurrentSessionDate();
			Process_.SubjectOf      = SalesOpportunity;
			Process_.Author        = INFTransaction.EmployeeResponsible;
			Process_.Description = INFTransaction.Description;
			Process_.Write();
			Process_.Start();
			
			CommitTransaction();
		Except
			
			RollbackTransaction();
			WriteLogEvent(EventLogEvent(), EventLogLevel.Error, , , ErrorInfo());
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
			
		EndTry;
	EndIf;

EndProcedure

// Negate (affix marks removal) the current problem and restarts the business process
// Parameters:
//  SalesOpportunity    - CatalogRef.SalesOpportunitiesToCustomer - a transaction that needs to be restarted.
//  SalesOpportunityType - EnumRef.TypesOfCustomerOpportunities - the transaction type defines the process metadata.
//
Procedure RestartSalesProcess(SalesOpportunity, SalesOpportunityType) Export

	// find instances of transaction processes
	Query = New Query;
	
	Query.Text = "
		|SELECT
		|	SalesProcess.Ref
		|FROM
		|	&BusinessProcessName AS SalesProcess
		|WHERE
		|	SalesProcess.Started
		|	AND NOT SalesProcess.Completed
		|	AND SalesProcess.SubjectOf = &SalesOpportunity";
		
	Query.Text = StrReplace(Query.Text, "&BusinessProcessName", "BusinessProcess." + GetDescriptionOfTransactionType(SalesOpportunityType).Name);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Processes = Query.Execute().Select();
	
	BeginTransaction();
	
	Try
		
		While Processes.Next() Do
			CancelProcessTasks(Processes.Ref);
			ProcessObject_ = Processes.Ref.GetObject();
			ProcessObject_.Started = False;
			ProcessObject_.Start();
		EndDo;
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error, , , ErrorInfo());
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		
	EndTry;

EndProcedure

// Cancels current tasks and completes the business process of the transaction
//
// Parameters:
//  SalesOpportunity    - CatalogRef.SalesOpportunitiesToCustomer       - the transaction that needs to be completed.
//  SalesOpportunityType - EnumRef.TypesOfCustomerOpportunities - the transaction type defines the process metadata.
//
Procedure CompleteSaleProcess(SalesOpportunity, SalesOpportunityType) Export

	// find instances of transaction processes
	Query = New Query;
	
	Query.Text = "
		|SELECT
		|	SalesProcess.Ref
		|FROM
		|	&BusinessProcessName AS SalesProcess
		|WHERE
		|	SalesProcess.Started
		|	AND NOT SalesProcess.Completed
		|	AND SalesProcess.SubjectOf = &SalesOpportunity";
		
	Query.Text = StrReplace(Query.Text, "&BusinessProcessName", "BusinessProcess." + GetDescriptionOfTransactionType(SalesOpportunityType).Name);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Processes = Query.Execute().Select();
	
	BeginTransaction();
	
	Try
		While Processes.Next() Do
			CompleteBusinessProcess(Processes.Ref);
		EndDo;
		CommitTransaction();
	Except
		
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error, , , ErrorInfo());
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		
	EndTry;

EndProcedure

// You can get the name and view from the link to the list of types of transactions.
//
// Parameters:
//  SalesOpportunityType - EnumRef.TypesOfCustomerOpportunities - the transaction type defines the process metadata.
//
// Returns:
//   Structure - has the following fields:
//    * Name - String - name of the enumeration value.
//    * Presentation - String - representation of the enumeration value.
//
Function GetDescriptionOfTransactionType(SalesOpportunityType) Export

	For Each Item In Metadata.Enums.TypesOfCustomerOpportunities.EnumValues Do
		If Enums.TypesOfCustomerOpportunities[Item.Name] = SalesOpportunityType Then
			Result = New Structure;
			Result.Insert("Name", Item.Name);
			Result.Insert(
				"Presentation",
				?(IsBlankString(Item.Synonym), Item.Name, Item.Synonym));

			Return Result;

		EndIf;
	EndDo;

	Return New Structure("Name,Presentation", "", "");

EndFunction

// Returns the value of the order of the stage completion result in the sales funnel report.
//
// Parameters:
//  Result - EnumRef.OpportunityStatuses -current status of the transaction.
//
// Returns:
//   Number - the value of ordering the transaction status in the report.
//
Function GetOrderOfResult(Result) Export

	If Result = Enums.OpportunityStatuses.Won Then
		Return 1;
	ElsIf Result = Enums.OpportunityStatuses.InProgress Then
		Return 2;
	Else
		Return 3;
	EndIf;

EndFunction

// Gets interaction participants by the tabular part of the interaction subject
//
// Parameters:
//  Ref            - DefinedType.InteractionSubject - subject of interaction
//  MainParticipant  - DefinedType.InteractionContact - the interaction participant that should be included in the resulting
//   array, regardless of whether it is contained in the tabular part of the interaction subject or not.
//
// Returns:
//   Array             - an array of interaction participants.
//
Function GetParticipantsOnTabularPartOfSubjectOfInteraction(Ref, MainParticipant = Undefined) Export
	
	If Not ValueIsFilled(Ref) Then
		Return New Array;
	EndIf;
	
	FullName = Ref.Metadata().FullName();
	
	QueryText = 
	"SELECT
	|	PartnersAndContactPersons.Partner AS Owner,
	|	PartnersAndContactPersons.ContactPerson AS Subordinated
	|FROM
	|	&TableName AS PartnersAndContactPersons
	|WHERE
	|	PartnersAndContactPersons.Ref = &Ref";
	
	QueryText = StrReplace(QueryText, "&TableName", FullName + ".PartnersAndContactPersons");
	
	Result = New Array;
	If ValueIsFilled(MainParticipant) Then
		Result.Add(MainParticipant);
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Contact = ?(ValueIsFilled(Selection.Subordinated), Selection.Subordinated, Selection.Owner);
		If Contact <> MainParticipant Then
			Result.Add(Contact);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Completes task processes for the task and sets the delete mark
// Parameters:
// Task - TaskRef.PerformerTask - a link to the task that is being canceled.
//
Procedure CancelTask(Task)

	TaskObject = Task.GetObject();
	TaskObject.DeletionMark = True;
	TaskObject.Write();

EndProcedure

// Cancels (marks deletion) current tasks and ends the process
// Parameters:
// Process_ - BusinessProcessRef.StandardSale -a link to the process being terminated.
//
Procedure CompleteBusinessProcess(Process_)

	CancelProcessTasks(Process_);
	ProcessObject_ = Process_.GetObject();
	ProcessObject_.Completed = True;
	ProcessObject_.Write();

EndProcedure

// Cancels (marks deletion) the current tasks of the process
Procedure CancelProcessTasks(Process_)

	Query = New Query(
		"SELECT
		|	PerformerTask.Ref
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.BusinessProcess = &BusinessProcess
		|	AND (NOT PerformerTask.Executed)");
	Query.SetParameter("BusinessProcess", Process_);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CancelTask(Selection.Ref);
	EndDo;

EndProcedure

// Calculate the duration of stay at the stage in days
// Parameters:
// Start - Date - start of the process.
// Finish - Date - end of the process.
//
// Returns:
//   Number - the duration of the stage in days.
//
Function Duration(Start, Finish) Export
	
	Return Round((Finish - Start)/84600,0);

EndFunction

Function EventLogEvent() Export
	
	Return NStr("vi = 'Vụ việc với khách hàng';
				|ru = 'Сделки с клиентами';
				|en = 'Sales opportunities'; fa = 'فرصت‌های فروش';
				|it = 'Affari con i clienti';
				|pl = 'Umowy z klientami';
				|tr = 'Müşterilerle satış fırsatları'", CommonClientServer.DefaultLanguageCode());
	
EndFunction

#EndRegion
