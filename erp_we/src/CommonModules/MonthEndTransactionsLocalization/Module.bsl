#Region Public

// Filling in the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
//
Procedure AddDescriptionOfClosingStagesOfMonth(StepsTable) Export
EndProcedure

// Filling in the table of groups of monthly closing stages.
// The elements in this table are the top-level elements in the stage tree in the month close form.
//
// Parameters:
//	TableOfStageGroups - See DataProcessors.MonthEndClosingOperations.InitializeStageGroupDescriptionTable
//
Procedure AddDescriptionOfGroupsOfStagesForClosingMonth(TableOfStageGroups) Export
EndProcedure

// Fills in checks that are performed during the closing of the month.
//
// Parameters:
//	TableOfChecks - See AuditOfSystemStateOverridable.FillOutChecksForRegistration.
//
Procedure AddChecksForRegistration(TableOfChecks) Export
EndProcedure

// Adds a list of month closing operations that use the month closing tasks mechanism.
// 
// Parameters:
// 	ChoiceData - ValueList -
//
Procedure AddDataForSelectingMonthClosingOperations(ChoiceData) Export
	
EndProcedure

// Checks the use of regulated accounting in the calculated period.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler.
//	ChangeStageState - Boolean -
//	
// Returns:
//	Boolean - a sign of the use of regulated accounting.
//
Function CheckUseOfRegulatedAccounting(HandlerParameters, ChangeStageState = True) Export
	
	Result = False;

	Return Result;
	
EndFunction

// Checks the availability of "Routine operation" documents.
//
// Parameters:
//	HandlerParameters 			   - Structure - parameters of the stage event handler
//	OperationType							- Undefined 		 			   
//											if omitted, the types of operations from the types of regulatory Operations property of this stage are analyzed
//	NameOfOrganizationSelectionTable 	   - String - the name of the temporary table for selecting documents for organizations
//											organizations in the specified table must be in the field named "Link"
//											if the table is not specified, then all organizations are selected from the array of Organizations property
//	TaskRegisterIsUsedForStage - Boolean - indicates that one of the "task ..." registers is used for this stage.
//	
// Returns:
//	Boolean - a sign of the availability of documents.
//
Function CheckAvailabilityOfDocumentRoutineOperation(HandlerParameters, Val OperationType = Undefined,
			NameOfOrganizationSelectionTable = "", TaskRegisterIsUsedForStage = True) Export
	
	HasErrors    = False;
	Return Not HasErrors;
	
EndFunction

// Description of the action "Open document list form ""Routine operation""".
// The selection by operation type is taken from the types of regular Operations property of the description of the month closing stage.
//
// Returns:
//	Structure - See MonthEndTransactionsServer.StructureOfActionDescription
//
Function ActionDescription_OpenListOfDocumentsRoutineOperation() Export
	LongDesc = MonthEndTransactionsServer.StructureOfActionDescription();
	Return LongDesc;
	
EndFunction


// Returns the text of the query to determine the status of the reflection of documents in regulatory accounting.
//
// Returns:
//	String - the text of the request to determine the status of the reflection of documents.
//
Function RequestTextDocumentReflectionState() Export
	
	ArrayOfRequestTexts = New Array;
	
	QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	QueryText = StrReplace(QueryText, "&UseLocal", ?(GetFunctionalOption("UseLocal"), "TRUE", "FALSE"));
	
	Return QueryText;
	
EndFunction
#Region CreatingTasksForEndOfMonth

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	
EndProcedure

// Determines the need to create tasks for the next period.
// 
// Parameters:
//	GenerateTasks - Boolean - indicates that tasks need to be generated.
//	HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters 
//	
Procedure CheckNeedToGenerateTasksForNextPeriod(GenerateTasks, HandlerParameters) Export
	
	
	Return;

EndProcedure

#EndRegion
#Region FormationOfRegulatoryDocuments

// Generates "Routine operation" documents starting from the first recalculated period to the current calculated period.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	ForOrganizationsThatHaveTasks	- Boolean - 
//	
Procedure CalculationOfRoutineOperationsStartingFromFirstTask(HandlerParameters, ForOrganizationsThatHaveTasks) Export
EndProcedure

// Generates "Routine operation" documents for a single period.
//
// Parameters:
//	HandlerParameters - Structure - parameters of the stage event handler
//	CompanyArray - Array -
//	OperationType 		 - Undefined
//							if omitted, documents are created with all types of operations from the types of regulatory Operations property of this stage
//	Period 				 - Date, Undefined - the period for the formation of documents;
//							if the period is not specified, documents are generated for the current calculated period.
//	
// Returns:
//  Undefined
//
Function GenerateDocumentRoutineOperation(HandlerParameters, CompanyArray, Val OperationType = Undefined, Val Period = Undefined) Export
	CalculationResult2 = Undefined;
	Return CalculationResult2;
EndFunction

// Returns the required frequency of the specified routine operation.
//
// Parameters:
//	OperationType - Undefined
//
// Returns:
//	 EnumRef.Periodicity - the frequency of the operation.
//
Function PeriodicityOfRoutineOperations(OperationType) Export
	Periodicity = Undefined;
	Return Periodicity;
	
EndFunction

// Checks whether the specified period matches the frequency of a routine operation.
//
// Parameters:
//	OperationType - Undefined
//	Period 		- Date - the period for generating a document for this operation.
//
// Returns:
//	 Boolean - a sign of the need to form a document.
//
Function RoutineOperationIsRequiredInSpecifiedPeriod(OperationType, Period) Export
	Result = False;
	
	Return Result;
	
EndFunction

#EndRegion
#Region SettingFunctionalLockWhenUpdatingInformationSecurity

// Update handlers that block month-end closing.
// Parameters:
//  Handlers - String - Update handlers that do not affect the month-ending closing.
// 
Procedure UpdateHandlersBlockingMonthEndClosing(Handlers) Export
	Handlers = Handlers + "
	
	|";
EndProcedure

// Update handlers that do not affect the month-ending closing.
// Parameters:
//  Handlers - String - Update handlers that do not affect the month-ending closing.
// 
Procedure UpdateHandlersThatDoNotAffectMonthEndClosing(Handlers) Export
	Handlers = Handlers +  "
	|";
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FormEventHandlers

Procedure WhenCreatingMonthClosingFormOnServer(Cancel, StandardProcessing, Form) Export
	Return;
EndProcedure


// Adjusts the shape of the end of the month.
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	LoadingSettings - Boolean -
//
Procedure ConfigureElementsDuringFormInitialization(Form, LoadingSettings = False) Export
EndProcedure

#EndRegion

#Region WorkingWithDates

// Adds descriptions of registers for connecting them to the no-change date mechanism.
//
// Parameters:
//  DataSources - ValueTable - see the description in the BSP mechanism.
//
Procedure SupplementDescriptionOfRegistersForMonitoringDatesOfProhibitionOfChanges(DataSources) Export
EndProcedure

// Returns the task date for the current period, depending on the operation.
// 
// Parameters:
// 	Operation - CatalogRef.MonthEndClosingOperations - the operation of closing the month.
// 	Organization - CatalogRef.Companies - link to the organization.
// 	DocumentJobs - DocumentRef - task document.
// 	Period - Date - date of the task.
// Returns:
// 	Date - Date of the task
//
Function TaskDateForCurPeriod(Operation, Organization, DocumentJobs, Val Period) Export
	Month = Period;
	Return Month
	
EndFunction

// Returns the task date for the next period, depending on the operation.
// 
// Parameters:
// 	Operation - CatalogRef.MonthEndClosingOperations - the operation of closing the month.
// 	Organization - CatalogRef.Companies - link to the organization.
// 	DocumentJobs - DocumentRef - task document.
// 	NextMonth - Date - date of the task.
// Returns:
// 	Date - Date of the task
//
Function TaskDateForNextPeriod(Operation, Organization, DocumentJobs, Val NextMonth) Export
	
	TaskDate_ = NextMonth;
	

	Return TaskDate_;
	
EndFunction

#EndRegion


#EndRegion
