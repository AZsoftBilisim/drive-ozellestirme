#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region JobsSearch

// Defines the current period of calculated AR/AP accounting data
// 
// Parameters:
//  ArrayAnalytics - Undefined, Array of CatalogRef.DimensionKeysOfAccountingByPartners - List Of Accounting Analysts By Partners
//  ArrayOfCalculationObjects_ - Undefined, Array of CatalogRef.ARAPObjects - List of calculation objects
//  MaxDate - Undefined, Date - Maximum date
// 
// Returns:
//  Date, Undefined - The period of relevance of mutual settlements
Function CurrentPeriodOfCalculatedDataOnMutualSettlements(ArrayAnalytics = Undefined, ArrayOfCalculationObjects_ = Undefined, MaxDate = Undefined) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT 
	|	MIN(Register.RecordDate) DateOfFirstTask
	|FROM
	|	InformationRegister.JobsForARAPAllocating AS Register
	|WHERE
	|	(Register.AccountingDimensionByPartners IN (&ArrayAnalytics)
	|		OR &AllAnalytics)
	|	AND (Register.ARAPObject IN (&ArrayOfCalculationObjects_)
	|		OR &AllCalculationObjects)
	|	AND (Register.TaskPeriod <= &MaxDate
	|		OR &NoLimitByPeriod)
	|HAVING
	|	NOT MIN(Register.RecordDate) IS NULL";
	Query.SetParameter("ArrayAnalytics", ArrayAnalytics);
	Query.SetParameter("AllAnalytics", ArrayAnalytics = Undefined);
	Query.SetParameter("ArrayOfCalculationObjects_", ArrayOfCalculationObjects_);
	Query.SetParameter("AllCalculationObjects", ArrayOfCalculationObjects_ = Undefined);
	Query.SetParameter("MaxDate", MaxDate);
	Query.SetParameter("NoLimitByPeriod", MaxDate = Undefined);
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		If ValueIsFilled(Selection.DateOfFirstTask) Then
			Return Selection.DateOfFirstTask - 1;
		Else
			Return Selection.DateOfFirstTask;
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns a list of documents for which there are tasks for the distribution of mutual settlements, taking into account the passed parameters.
// 
// Parameters:
//  ArrayAnalytics - Undefined, Array of CatalogRef.DimensionKeysOfAccountingByPartners - List Of Accounting Analysts By Partners
//  ArrayOfCalculationObjects_ - Undefined, Array of CatalogRef.ARAPObjects - List of calculation objects
//  MaxDate - Undefined, Date - Maximum date
// 
// Returns:
//  Array of DocumentRef - List of documents for the distribution of settlements
Function DocumentsForDistributionOfSettlementsByTime(ArrayAnalytics = Undefined, ArrayOfCalculationObjects_ = Undefined, MaxDate = Undefined) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	Register.Document AS Document
	|FROM
	|	InformationRegister.JobsForARAPAllocating AS Register
	|WHERE
	|	(Register.AccountingDimensionByPartners IN (&ArrayAnalytics)
	|		OR &AllAnalytics)
	|	AND (Register.ARAPObject IN (&ArrayOfCalculationObjects_)
	|		OR &AllCalculationObjects)
	|	AND (Register.TaskPeriod <= &MaxDate
	|		OR &NoLimitByPeriod)";
	
	Query.SetParameter("ArrayAnalytics", ArrayAnalytics);
	Query.SetParameter("AllAnalytics", ArrayAnalytics = Undefined);
	Query.SetParameter("ArrayOfCalculationObjects_", ArrayOfCalculationObjects_);
	Query.SetParameter("AllCalculationObjects", ArrayOfCalculationObjects_ = Undefined);
	Query.SetParameter("MaxDate", MaxDate);
	Query.SetParameter("NoLimitByPeriod", MaxDate = Undefined);
	SetPrivilegedMode(True);
	DocumentsArray = Query.Execute().Unload().UnloadColumn("Document");
	SetPrivilegedMode(False);
	
	Return DocumentsArray;
	
EndFunction

#EndRegion

#Region JobGeneration

// Creating tasks in a non-operational queue.
// Called when writing a set of register entries.
// 
// Parameters:
//  RegisterManager - AccumulationRegisterManager, InformationRegisterManager - Manager of the recorded register
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
//
Procedure CreateJobs(RegisterManager, KindsOfTasks, RecordSet, TempTablesManager = Undefined,
	DataForRegisteringTasks = Undefined) Export

	If KindsOfTasks.Count() = 0 
		Or (RecordSet.AdditionalProperties.Property("NotCreateTasksForDistributionOfMutualSettlements")
		And RecordSet.AdditionalProperties.NotCreateTasksForDistributionOfMutualSettlements) Then
		Return;
	EndIf;

	DataForCreatingTasks = RegisterManager.DataForFormationOfTasksForNonOperationalDocumentVerification(
			RecordSet, CommonClientServer.ValueInArray(
		Catalogs.BackdateJobKinds.ARAPAllocationByDueDates), TempTablesManager, DataForRegisteringTasks);

	If DataForCreatingTasks.Count() > 0 Then

		CreateTasksBasedOnDataFromValueTable(DataForCreatingTasks);

	EndIf;

EndProcedure

// Create tasks when exchanging RIB data.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
//
Procedure CreateTasksWhenExchangingData(RecordSet, TempTablesManager = Undefined,
	DataForRegisteringTasks = Undefined) Export

	RegisterMetadata = RecordSet.Metadata();
	RegisterManager = Common.ObjectManagerByFullName(RegisterMetadata.FullName());

	KindsOfTasks = New Array;
	KindsOfTasks.Add(Catalogs.BackdateJobKinds.ARAPAllocationByDueDates);

	RecordSet.AdditionalProperties.Insert("NotCreateTasksForDistributionOfMutualSettlements", False);
	CreateJobs(RegisterManager, KindsOfTasks, RecordSet, TempTablesManager, DataForRegisteringTasks);
		
EndProcedure

// Creating tasks in a non-operational queue when recording a set of records of the register of settlements by time.
// This procedure is a special case of job registration and is called after filling in the AR/AP accounts registers in the new architecture.
// See OnlineARAPAccountingServer.CompleteOperationalSettlements.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - The data from the temporary tables will be used when creating new tasks.
//  TheseAreSettlementsWithCustomers - Boolean - Settlements with clients
//
Procedure CreateNonOperationalQueueTasksONChangeOfDueDateCalculations(TempTablesManager,
	TheseAreSettlementsWithCustomers = True) Export

	If TheseAreSettlementsWithCustomers Then
		RegisterMetadata = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates;
		TableName = "ChangesTableCustomersARAPAccountingByDueDates";
	Else
		RegisterMetadata = Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates;
		TableName = "ChangesTableVendorsARAPAccountingByDueDates";
	EndIf;

	If TempTablesManager.Tables.Find(TableName) = Undefined Then
		Return;
	EndIf;

	RegisterManager = Common.ObjectManagerByFullName(RegisterMetadata.FullName());

	TypesOfTasksToRegisterInQueue = BackdateJobQueue.TypesOfTasksToRegisterInQueue(RegisterMetadata);
	For Each CurrentData In TypesOfTasksToRegisterInQueue Do

		TaskRegisterMetadata = Common.MetadataObjectByID(CurrentData.QueueRegister);
		TaskRegisterManager = Common.ObjectManagerByFullName(TaskRegisterMetadata.FullName());

		TaskRegisterManager.CreateTasksBasedOnTemporaryTableData(RegisterManager, CurrentData.KindsOfTasks,
			TempTablesManager, TableName);

	EndDo;

EndProcedure

// Creating tasks based on the data from the passed table of values.
// 
// Parameters:
//  TaskGenerationTable - See TaskGenerationTable
Procedure CreateTasksBasedOnDataFromValueTable(TaskGenerationTable) Export

	Jobs = CreateRecordSet();

	For Each CurrentData In TaskGenerationTable Do
		
		If Not ValueIsFilled(CurrentData.Document) Then
			ExceptionText = NStr(
				"vi = 'Trong nhiệm vụ được đăng ký để phân bổ hạch toán công nợ, chưa điền trường ""Chứng từ"".';
				|ru = 'У регистрируемого задания к распределению взаиморасчетов поле ""Документ"" не заполнено.';
				|en = 'The ""Document"" field is not filled in for the registered job for allocating AR/AP.'; fa = 'The ""Document"" field is not filled in for the registered job for allocating AR/AP.';
				|it = 'The ""Document"" field is not filled in for the registered job for allocating AR/AP.';
				|pl = 'The ""Document"" field is not filled in for the registered job for allocating AR/AP.';
				|tr = 'Kaydedilen mahsuplaştırma görevinin ""Belge"" alanı doldurulmadı.'");
			Raise ExceptionText;
		EndIf;
		
		NewJob = Jobs.Add();
		FillPropertyValues(NewJob, CurrentData);
		NewJob.RecordID = New UUID;

	EndDo;
	SetPrivilegedMode(True);
	Jobs.Write(False);
	SetPrivilegedMode(False);

EndProcedure

// A data table for the formation of tasks for the distribution of AR/AP accounts.
// 
// Returns:
//  ValueTable - The data table for the formation of tasks for the distribution of settlements:
// * Organization - CatalogRef.Companies - The organization for which the task will be generated
// * TaskPeriod - Date - the period of the task
// * Document - DocumentRef - Link to the document that the task is generated from
// * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting analytics by partners
// * ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
// * Currency - CatalogRef.Currencies - Settlement currency
// * RecordDate - Date - Date the task was recorded
// * ChangeControlPeriod - Date - The period from which changes should be checked
//
Function TaskGenerationTable() Export

	Table = New ValueTable;
	Table.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	Table.Columns.Add("TaskPeriod", Common.DateTypeDetails(DateFractions.DateTime));
	Table.Columns.Add("Document", Documents.AllRefsType());
	Table.Columns.Add("AccountingDimensionByPartners",
		New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
	Table.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	Table.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	Table.Columns.Add("RecordDate", Common.DateTypeDetails(DateFractions.DateTime));
	Table.Columns.Add("ChangeControlPeriod", Common.DateTypeDetails(DateFractions.DateTime));

	Return Table;

EndFunction

#EndRegion

#Region DataProcessing

// Retrieves data from calculation granules for multithreaded background processing.
// 
// Parameters:
//  ThreadFormationStructure - See BackdateJobQueue.StructureOfFormationOfDataPortions
//  FreeThreadsCount - Number - Number of free threads
// 
// Returns:
//  ValueTable - Data For Multithreaded Background Processing:
// * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting analytics by partners
// * ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
// * Currency - CatalogRef.Currencies - Settlement currency
// * Batch - Number - Portion Number
//
Function DataForMultithreadedBackgroundProcessing(ThreadFormationStructure, FreeThreadsCount) Export
	
	If ThreadFormationStructure.BackgroundJobProcessing Then
		
		DeferredJobs.Run(Metadata.InformationRegisters.JobsForARAPAllocating.Name);
		
		Return TableOfCalculationGranules();
		
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	DocumentsForProcessing_.Document AS Document
	|INTO TTDocumentsForProcessing
	|FROM
	|	&DocumentsTable AS DocumentsForProcessing_
	|
	|INDEX BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Jobs.ARAPObject            AS ARAPObject,
	|	Jobs.Currency                    AS Currency,
	|	MIN(Jobs.TaskPeriod)    AS RecalculationStartDate
	|INTO AllTasks_
	|FROM
	|	InformationRegister.JobsForARAPAllocating AS Jobs
	|		INNER JOIN TTDocumentsForProcessing AS DocumentsForProcessing_
	|		ON Jobs.Document = DocumentsForProcessing_.Document
	|WHERE
	|	Jobs.CompletedWithAnError = FALSE
	|
	|GROUP BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                        AS ARAPObject,
	|	Calculations.Currency                                AS Currency,
	|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
	|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
	|	BEGINOFPERIOD(Calculations.RecorderDate, DAY) AS Period
	|INTO TableOfCalculationRelationships
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.Active
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AllTasks_ AS Jobs
	|		WHERE
	|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
	|			AND Jobs.ARAPObject = Calculations.ARAPObject
	|			AND Jobs.Currency = Calculations.Currency
	|			AND Jobs.RecalculationStartDate <= Calculations.RecorderDate)
	|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
	|
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver,
	|	BEGINOFPERIOD(Calculations.RecorderDate, DAY)
	|
	|UNION ALL 
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                        AS ARAPObject,
	|	Calculations.Currency                                AS Currency,
	|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
	|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
	|	BEGINOFPERIOD(Calculations.Period, DAY)           AS Period
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.Active
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AllTasks_ AS Jobs
	|		WHERE
	|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
	|			AND Jobs.ARAPObject = Calculations.ARAPObject
	|			AND Jobs.Currency = Calculations.Currency
	|			AND Jobs.RecalculationStartDate <= Calculations.Period)
	|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
	|
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver,
	|	BEGINOFPERIOD(Calculations.Period, DAY)
	|
	|UNION ALL 
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                        AS ARAPObject,
	|	Calculations.Currency                                AS Currency,
	|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
	|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
	|	BEGINOFPERIOD(Calculations.RecorderDate, DAY) AS Period
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.Active
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AllTasks_ AS Jobs
	|		WHERE
	|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
	|			AND Jobs.ARAPObject = Calculations.ARAPObject
	|			AND Jobs.Currency = Calculations.Currency
	|			AND Jobs.RecalculationStartDate <= Calculations.RecorderDate)
	|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
	|
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver,
	|	BEGINOFPERIOD(Calculations.RecorderDate, DAY)
	|
	|UNION ALL 
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject                        AS ARAPObject,
	|	Calculations.Currency                                AS Currency,
	|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
	|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
	|	BEGINOFPERIOD(Calculations.Period, DAY)           AS Period
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.Active
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			AllTasks_ AS Jobs
	|		WHERE
	|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
	|			AND Jobs.ARAPObject = Calculations.ARAPObject
	|			AND Jobs.Currency = Calculations.Currency
	|			AND Jobs.RecalculationStartDate <= Calculations.Period)
	|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
	|
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.DestinationAccountingDimensionByPartners,
	|	Calculations.CalculationObjectReceiver,
	|	Calculations.CurrencyReceiver,
	|	BEGINOFPERIOD(Calculations.Period, DAY)
	|
	|INDEX BY SETS
	|(
	|	(AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	Period),
	|	(DestinationAccountingDimensionByPartners,
	|	CalculationObjectReceiver,
	|	CurrencyReceiver,
	|	Period,
	|	OperationProcedure)
	|)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.AccountingDimensionByPartners                        AS AccountingDimensionByPartners,
	|	Jobs.ARAPObject                                   AS ARAPObject,
	|	Jobs.Currency                                           AS Currency,
	|	MIN(ISNULL(Calculations.OperationProcedure, ""39990101"")) AS OperationProcedure,
	|	MIN(Jobs.RecalculationStartDate)                     AS RecalculationStartDate
	|INTO TasksWithOrdersOfOperations
	|FROM
	|	AllTasks_ AS Jobs
	|	LEFT JOIN TableOfCalculationRelationships AS Calculations
	|	ON Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
	|		AND Jobs.ARAPObject = Calculations.ARAPObject
	|		AND Jobs.Currency = Calculations.Currency
	|		AND Jobs.Currency = Calculations.Currency
	|		AND Jobs.RecalculationStartDate <= Calculations.Period
	|		
	|GROUP BY
	|	Jobs.AccountingDimensionByPartners,
	|	Jobs.ARAPObject,
	|	Jobs.Currency
	|	
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	OperationProcedure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1000
	|	Table.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
	|	Table.ARAPObject               AS ARAPObject,
	|	Table.Currency                       AS Currency,
	|	MIN(Table.RecalculationStartDate) AS RecalculationStartDate
	|FROM
	|	TasksWithOrdersOfOperations AS Table
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TableOfCalculationRelationships AS TableOfReceivers
	|		WHERE
	|			TableOfReceivers.DestinationAccountingDimensionByPartners = Table.AccountingDimensionByPartners
	|			AND TableOfReceivers.CalculationObjectReceiver = Table.ARAPObject
	|			AND TableOfReceivers.CurrencyReceiver = Table.Currency
	|			AND TableOfReceivers.Period <= Table.RecalculationStartDate
	|			AND TableOfReceivers.OperationProcedure < Table.OperationProcedure)
	|
	|GROUP BY
	|	Table.AccountingDimensionByPartners,
	|	Table.ARAPObject,
	|	Table.Currency
	|
	|ORDER BY
	|	RecalculationStartDate,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|
	|";
	
	Query.SetParameter("DocumentsTable", ThreadFormationStructure.DocumentsTable);

	MaximumNumberOfTuples = FreeThreadsCount * ThreadFormationStructure.MaximumBatch;
	
	Query.Text = StrReplace(Query.Text, "1000", Format(MaximumNumberOfTuples, "NZ=0; NG=0"));
	
	SetPrivilegedMode(True);
	TuplesToBeProcessed = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	PortionsOfTuplesToBeProcessed = TableOfCalculationGranules();
	PortionsOfTuplesToBeProcessed.Columns.Add("Batch", Common.TypeDescriptionNumber(10, 0));

	PortionNumber = 1;
	
	While TuplesToBeProcessed.Next() Do
	
		PortionTuple = PortionsOfTuplesToBeProcessed.Add();
		PortionTuple.AccountingDimensionByPartners = TuplesToBeProcessed.AccountingDimensionByPartners;
		PortionTuple.ARAPObject = TuplesToBeProcessed.ARAPObject;
		PortionTuple.Currency = TuplesToBeProcessed.Currency;
		PortionTuple.Batch = PortionNumber;
		
		If PortionsOfTuplesToBeProcessed.Count() >= ThreadFormationStructure.MaximumBatch Then
			PortionNumber = PortionNumber + 1;
		EndIf;
		
		If PortionNumber > FreeThreadsCount Then
			Break;
		EndIf;
		
	EndDo;
	
	Return PortionsOfTuplesToBeProcessed;
	
EndFunction

// To process a portion of calculation granules.
// 
// Parameters:
//  DataParameters - See BackdateJobQueue.DataPortionProcessingParameters
//
Procedure PerformPortionProcessing(DataParameters) Export
	
	If DataParameters.DataPortion.Count() = 0 Then
		Return;
	EndIf;
	
	QueueRegisterMetadata = Metadata.InformationRegisters.JobsForARAPAllocating;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	PortionTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	PortionTable.ARAPObject AS ARAPObject,
	|	PortionTable.Currency AS Currency
	|INTO TTTuplesToBeProcessed
	|FROM
	|	&PortionTable AS PortionTable
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTuplesToBeProcessed.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTTuplesToBeProcessed.ARAPObject AS ARAPObject,
	|	TTTuplesToBeProcessed.Currency AS Currency,
	|	ISNULL(ARAPObjects.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) AS PaymentType_,
	|	CASE
	|		WHEN ISNULL(ARAPObjects.PaymentType_,
	|			VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TheseAreSettlementsWithCustomers,
	|	ISNULL(ARAPObjects.Object, UNDEFINED) AS Object,
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CalculationObjectReceiver,
	|	VALUE(Catalog.Currencies.EmptyRef) AS CurrencyReceiver,
	|	JobsForARAPAllocating.Document AS Document,
	|	JobsForARAPAllocating.Document AS Recorder,
	|	JobsForARAPAllocating.Organization AS Organization,
	|	MIN(JobsForARAPAllocating.TaskPeriod) AS RecountDate,
	|	MIN(JobsForARAPAllocating.TaskPeriod) AS RecalculationStartDate,
	|	MIN(JobsForARAPAllocating.ChangeControlPeriod) AS PeriodForMonitoringChangesAndCreatingTasks,
	|	1 AS Priority,
	|	FALSE AS ByDataOfSourceARAPObject
	|FROM
	|	TTTuplesToBeProcessed AS TTTuplesToBeProcessed
	|		INNER JOIN InformationRegister.JobsForARAPAllocating AS JobsForARAPAllocating
	|		ON TTTuplesToBeProcessed.AccountingDimensionByPartners = JobsForARAPAllocating.AccountingDimensionByPartners
	|		AND TTTuplesToBeProcessed.ARAPObject = JobsForARAPAllocating.ARAPObject
	|		AND TTTuplesToBeProcessed.Currency = JobsForARAPAllocating.Currency
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON TTTuplesToBeProcessed.ARAPObject = ARAPObjects.Ref
	|GROUP BY
	|	TTTuplesToBeProcessed.AccountingDimensionByPartners,
	|	TTTuplesToBeProcessed.ARAPObject,
	|	TTTuplesToBeProcessed.Currency,
	|	ISNULL(ARAPObjects.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)),
	|	CASE
	|		WHEN ISNULL(ARAPObjects.PaymentType_,
	|			VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	ISNULL(ARAPObjects.Object, UNDEFINED),
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef),
	|	VALUE(Catalog.ARAPObjects.EmptyRef),
	|	VALUE(Catalog.Currencies.EmptyRef),
	|	JobsForARAPAllocating.Document,
	|	JobsForARAPAllocating.Organization
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TuplesToBeProcessed.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TuplesToBeProcessed.ARAPObject AS ARAPObject,
	|	TuplesToBeProcessed.Currency AS Currency,
	|	JobsForARAPAllocating.RecordID AS RecordID,
	|	JobsForARAPAllocating.CompletedWithAnError AS CompletedWithAnError
	|FROM
	|	TTTuplesToBeProcessed AS TuplesToBeProcessed
	|		INNER JOIN InformationRegister.JobsForARAPAllocating AS JobsForARAPAllocating
	|		ON TuplesToBeProcessed.AccountingDimensionByPartners = JobsForARAPAllocating.AccountingDimensionByPartners
	|		AND TuplesToBeProcessed.ARAPObject = JobsForARAPAllocating.ARAPObject
	|		AND TuplesToBeProcessed.Currency = JobsForARAPAllocating.Currency";
	
	Query.SetParameter("PortionTable", DataParameters.DataPortion);
	
	SetPrivilegedMode(True);
	DataByTuple = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	InitialDataForDistribution = DataByTuple[DataByTuple.UBound() - 1].Unload(); // ValueTable
	InitialDataForDistribution.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
	
	IdsOfTupleTasks = DataByTuple[DataByTuple.UBound()].Unload();
	IdsOfTupleTasks.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
	
	ParametersOfDataProcessing = New Structure;
	PortionProcessedSuccessfully = True;
	If Not DataParameters.CompletingTasksInTransaction Then
		
		BeginTransaction();
		Try
			
			ExceptionReason = "Block";
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.JobsForARAPAllocating");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.DataSource = IdsOfTupleTasks.Copy(New Structure("CompletedWithAnError", False));
			LockItem.UseFromDataSource("RecordID", "RecordID");
			Block.Lock();
			
			ExceptionReason = "BadData";
			
			ParametersOfDataProcessing.Insert("DataForProcessing_", InitialDataForDistribution);
			ParametersOfDataProcessing.Insert("SupplementDistributeReceivers", True);
			ParametersOfDataProcessing.Insert("RegisterTasksByReceivers", True);
			SetPrivilegedMode(True);
			ARAPAccountingInternal.PerformDeferredAllocation(ParametersOfDataProcessing);
			BackdateJobQueue.DeleteQueueTasks(DataParameters.QueueRegisterName,
				IdsOfTupleTasks.UnloadColumn("RecordID"));
			SetPrivilegedMode(False);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			PortionProcessedSuccessfully = False;
		EndTry;
		
		If PortionProcessedSuccessfully Then
			SetPrivilegedMode(True);
			BackdateJobQueue.UncheckCompletedWithErrorBasedOnDocuments(
				CommonClientServer.CollapseArray(InitialDataForDistribution.UnloadColumn("Document")),
				DataParameters.JobKind);
			SetPrivilegedMode(False);
			Return;
		EndIf;
		
	EndIf;
	
	ErrorsTable = TableOfCalculationGranules();
	ErrorsTable.Columns.Add("ErrorDescription", New TypeDescription("String"));
	
	DataSelectionStructure = New Structure("AccountingDimensionByPartners, ARAPObject, Currency");

	ProcessedRowsPortionsOfData = New Array;
	ProcessedTupleIds = New Array;

	AttemptNumber = 1;
	AttemptsNumber = ?(DataParameters.CompletingTasksInTransaction, 1, 3);
	While AttemptNumber <= AttemptsNumber Do

		If DataParameters.DataPortion.Count() = 0 Then
			Break;
		EndIf;
		
		For Each TupleToBeProcessed In DataParameters.DataPortion Do
			
			TupleProcessingCompletedSuccessfully = True;
			ExceptionReason = "BadData";
			
			DataSelectionStructure.AccountingDimensionByPartners = TupleToBeProcessed.AccountingDimensionByPartners;
			DataSelectionStructure.ARAPObject = TupleToBeProcessed.ARAPObject;
			DataSelectionStructure.Currency = TupleToBeProcessed.Currency;
			
			DataForProcessing_ = InitialDataForDistribution.Copy(DataSelectionStructure);
			TupleIdTable = IdsOfTupleTasks.Copy(DataSelectionStructure);
			ListOfTaskIdsToProcess = TupleIdTable.UnloadColumn("RecordID");
			DocumentsForMotorcade = CommonClientServer.CollapseArray(DataForProcessing_.UnloadColumn("Document"));
			
			BeginTransaction();

			Try
				
				ExceptionReason = "Block";
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.JobsForARAPAllocating");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.DataSource = TupleIdTable.Copy(New Structure("CompletedWithAnError", False));
				LockItem.UseFromDataSource("RecordID", "RecordID");
				Block.Lock();
				
				ExceptionReason = "BadData";
				
				ParametersOfDataProcessing.Insert("DataForProcessing_", DataForProcessing_);
				ParametersOfDataProcessing.Insert("SupplementDistributeReceivers", True);
				ParametersOfDataProcessing.Insert("RegisterTasksByReceivers", True);
				SetPrivilegedMode(True);
				ARAPAccountingInternal.PerformDeferredAllocation(ParametersOfDataProcessing);
				BackdateJobQueue.DeleteQueueTasks(DataParameters.QueueRegisterName,
					ListOfTaskIdsToProcess);
				SetPrivilegedMode(False);

				CommitTransaction();

			Except

				RollbackTransaction();
				
				TupleProcessingCompletedSuccessfully = False;
				
				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				DocumentsOfProcessingGroup = CommonClientServer.CollapseArray(
					DataForProcessing_.UnloadColumn("Document"));
				
				For Each CurrentDocument In DocumentsOfProcessingGroup Do
					BackdateJobQueue.WriteErrorToEventLog(
						QueueRegisterMetadata, DataParameters.JobKind, ErrorText, CurrentDocument);
				EndDo;
				
				If ExceptionReason = "BadData" Or DataParameters.CompletingTasksInTransaction Then
					
					ErrorRecord = ErrorsTable.Add();
					ErrorRecord.AccountingDimensionByPartners = TupleToBeProcessed.AccountingDimensionByPartners;
					ErrorRecord.ARAPObject = TupleToBeProcessed.ARAPObject;
					ErrorRecord.Currency = TupleToBeProcessed.Currency;
					ErrorRecord.ErrorDescription = ErrorText;
					
				EndIf;
				
			EndTry;
			
			If TupleProcessingCompletedSuccessfully 
				Or (Not DataParameters.CompletingTasksInTransaction 
					And ExceptionReason = "Block" And AttemptNumber = AttemptsNumber) Then
				
				ProcessedRowsPortionsOfData.Add(TupleToBeProcessed);
				
				CommonClientServer.SupplementArray(ProcessedTupleIds,
						ListOfTaskIdsToProcess);
				
				If TupleProcessingCompletedSuccessfully Then
					SetPrivilegedMode(True);
					BackdateJobQueue.UncheckCompletedWithErrorBasedOnDocuments(DocumentsForMotorcade,
						DataParameters.JobKind);
					SetPrivilegedMode(False);
				EndIf;
					
			EndIf;

		EndDo;

		If ProcessedRowsPortionsOfData.Count() > 0 Then

			For Each DataToDelete_1 In ProcessedRowsPortionsOfData Do
				DataParameters.DataPortion.Delete(DataToDelete_1);
			EndDo;
			
			ProcessedRowsPortionsOfData.Clear();

		EndIf;

		AttemptNumber = AttemptNumber + 1;

	EndDo;
	
	If Not DataParameters.CompletingTasksInTransaction Then
		
		If DataParameters.DataPortion.Count() > 0 Then
			RegisterDataProcessingErrors(CommonClientServer.ArraysDifference(
				IdsOfTupleTasks.UnloadColumn("RecordID"),
				ProcessedTupleIds), ErrorsTable);
		EndIf;
		
	Else
		
		ReportDataProcessingErrors(ErrorsTable);
		
	EndIf;
	
EndProcedure

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
	
	QueryText = "
		|SELECT DISTINCT
		|	JobsForARAPAllocating.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	JobsForARAPAllocating.ARAPObject AS ARAPObject,
		|JobsForARAPAllocating.Currency AS Currency
		|INTO TT_ProcessedTuples
		|FROM
		|	InformationRegister.JobsForARAPAllocating AS JobsForARAPAllocating
		|WHERE
		|	JobsForARAPAllocating.RecordID IN(&IdsPassedToWorkStreams)
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|	Jobs.ARAPObject               AS ARAPObject,
		|	Jobs.Currency                       AS Currency,
		|	MIN(Jobs.RecordID) AS JobID,
		|	FALSE                                 AS CompletedWithAnError,
		|	MIN(Jobs.TaskPeriod)       AS RecalculationStartDate
		|INTO AllTasks_
		|FROM
		|	InformationRegister.JobsForARAPAllocating AS Jobs
		|
		|WHERE
		|	Jobs.CompletedWithAnError = FALSE
		|	AND NOT TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|			FROM
		|				TT_ProcessedTuples AS ProcessedTuples
		|			WHERE
		|				Jobs.AccountingDimensionByPartners = ProcessedTuples.AccountingDimensionByPartners
		|				AND Jobs.ARAPObject = ProcessedTuples.ARAPObject
		|				AND Jobs.Currency = ProcessedTuples.Currency)
		|
		|GROUP BY
		|	Jobs.AccountingDimensionByPartners,
		|	Jobs.ARAPObject,
		|	Jobs.Currency
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                        AS ARAPObject,
		|	Calculations.Currency                                AS Currency,
		|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
		|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
		|	BEGINOFPERIOD(Calculations.RecorderDate, DAY) AS Period
		|INTO TableOfCalculationRelationships
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|WHERE
		|	Calculations.Active
		|	AND TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			AllTasks_ AS Jobs
		|		WHERE
		|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
		|			AND Jobs.ARAPObject = Calculations.ARAPObject
		|			AND Jobs.Currency = Calculations.Currency
		|			AND Jobs.RecalculationStartDate <= Calculations.RecorderDate)
		|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
		|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	Calculations.DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver,
		|	BEGINOFPERIOD(Calculations.RecorderDate, DAY)
		|
		|UNION ALL 
		|
		|SELECT
		|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                        AS ARAPObject,
		|	Calculations.Currency                                AS Currency,
		|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
		|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
		|	BEGINOFPERIOD(Calculations.Period, DAY)           AS Period
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
		|WHERE
		|	Calculations.Active
		|	AND TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			AllTasks_ AS Jobs
		|		WHERE
		|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
		|			AND Jobs.ARAPObject = Calculations.ARAPObject
		|			AND Jobs.Currency = Calculations.Currency
		|			AND Jobs.RecalculationStartDate <= Calculations.Period)
		|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
		|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	Calculations.DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver,
		|	BEGINOFPERIOD(Calculations.Period, DAY)
		|
		|UNION ALL 
		|
		|SELECT
		|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                        AS ARAPObject,
		|	Calculations.Currency                                AS Currency,
		|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
		|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
		|	BEGINOFPERIOD(Calculations.RecorderDate, DAY) AS Period
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|WHERE
		|	Calculations.Active
		|	AND TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			AllTasks_ AS Jobs
		|		WHERE
		|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
		|			AND Jobs.ARAPObject = Calculations.ARAPObject
		|			AND Jobs.Currency = Calculations.Currency
		|			AND Jobs.RecalculationStartDate <= Calculations.RecorderDate)
		|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
		|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	Calculations.DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver,
		|	BEGINOFPERIOD(Calculations.RecorderDate, DAY)
		|
		|UNION ALL 
		|
		|SELECT
		|	Calculations.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                        AS ARAPObject,
		|	Calculations.Currency                                AS Currency,
		|	Calculations.DestinationAccountingDimensionByPartners     AS DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver                AS CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver                        AS CurrencyReceiver,
		|	MIN(Calculations.OperationProcedure)              AS OperationProcedure,
		|	BEGINOFPERIOD(Calculations.Period, DAY)           AS Period
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
		|WHERE
		|	Calculations.Active
		|	AND TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			AllTasks_ AS Jobs
		|		WHERE
		|			Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
		|			AND Jobs.ARAPObject = Calculations.ARAPObject
		|			AND Jobs.Currency = Calculations.Currency
		|			AND Jobs.RecalculationStartDate <= Calculations.Period)
		|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
		|	AND Calculations.CalculationObjectReceiver <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|	AND Calculations.CurrencyReceiver <> VALUE(Catalog.Currencies.EmptyRef)
		|
		|GROUP BY
		|	Calculations.AccountingDimensionByPartners,
		|	Calculations.ARAPObject,
		|	Calculations.Currency,
		|	Calculations.DestinationAccountingDimensionByPartners,
		|	Calculations.CalculationObjectReceiver,
		|	Calculations.CurrencyReceiver,
		|	BEGINOFPERIOD(Calculations.Period, DAY)
		|
		|INDEX BY SETS
		|(
		|	(AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency,
		|	Period),
		|	(DestinationAccountingDimensionByPartners,
		|	CalculationObjectReceiver,
		|	CurrencyReceiver,
		|	Period,
		|	OperationProcedure)
		|)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.AccountingDimensionByPartners                        AS AccountingDimensionByPartners,
		|	Jobs.ARAPObject                                   AS ARAPObject,
		|	Jobs.Currency                                           AS Currency,
		|	Jobs.CompletedWithAnError                                AS CompletedWithAnError,
		|	MIN(ISNULL(Calculations.OperationProcedure, ""39990101"")) AS OperationProcedure,
		|	MIN(Jobs.RecalculationStartDate)                     AS RecalculationStartDate,
		|	MIN(Jobs.JobID)                    AS JobID
		|INTO TasksWithOrdersOfOperations
		|FROM
		|	AllTasks_ AS Jobs
		|	LEFT JOIN TableOfCalculationRelationships AS Calculations
		|	ON Jobs.AccountingDimensionByPartners = Calculations.AccountingDimensionByPartners
		|		AND Jobs.ARAPObject = Calculations.ARAPObject
		|		AND Jobs.Currency = Calculations.Currency
		|		AND Jobs.Currency = Calculations.Currency
		|		AND Jobs.RecalculationStartDate <= Calculations.Period
		|		
		|GROUP BY
		|	Jobs.AccountingDimensionByPartners,
		|	Jobs.ARAPObject,
		|	Jobs.Currency,
		|	Jobs.CompletedWithAnError
		|	
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency,
		|	OperationProcedure
		|;
		|
		|////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 999
		|	Table.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
		|	Table.ARAPObject                AS ARAPObject,
		|	Table.Currency                        AS Currency,
		|	MIN(Table.RecalculationStartDate)  AS RecalculationStartDate,
		|	MIN(Table.JobID) AS JobID
		|INTO Jobs
		|FROM
		|	TasksWithOrdersOfOperations AS Table
		|WHERE
		|	NOT TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			TT_ProcessedTuples AS Jobs
		|		WHERE
		|			Jobs.AccountingDimensionByPartners = Table.AccountingDimensionByPartners
		|			AND Jobs.ARAPObject = Table.ARAPObject
		|			AND Jobs.Currency = Table.Currency)
		|	AND NOT TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			TableOfCalculationRelationships AS TableOfReceivers
		|		WHERE
		|			TableOfReceivers.DestinationAccountingDimensionByPartners = Table.AccountingDimensionByPartners
		|			AND TableOfReceivers.CalculationObjectReceiver = Table.ARAPObject
		|			AND TableOfReceivers.CurrencyReceiver = Table.Currency
		|			AND TableOfReceivers.Period <= Table.RecalculationStartDate
		|			AND TableOfReceivers.OperationProcedure < Table.OperationProcedure)
		|	AND Table.CompletedWithAnError = FALSE
		|
		|GROUP BY
		|	Table.AccountingDimensionByPartners,
		|	Table.ARAPObject,
		|	Table.Currency
		|
		|ORDER BY
		|	RecalculationStartDate,
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|
		|INDEX BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.JobID  AS JobID,
		|	Table.TaskPeriod        AS TaskDate_,
		|	Table.*
		|FROM
		|	InformationRegister.JobsForARAPAllocating AS Table
		|		INNER JOIN Jobs AS Jobs
		|		ON (Jobs.AccountingDimensionByPartners = Table.AccountingDimensionByPartners)
		|			AND (Jobs.ARAPObject = Table.ARAPObject)
		|			AND (Jobs.Currency = Table.Currency)
		|WHERE
		|	Table.CompletedWithAnError = FALSE
		|
		|ORDER BY
		|	TaskDate_,
		|	Table.AccountingDimensionByPartners,
		|	Table.ARAPObject,
		|	Table.Currency";
	
	QueryText = StrReplace(QueryText, "999", Format(JobsCount, "NZ=0; NG=;"));
	
	Return QueryText;
	
EndFunction

// Performs the distribution of calculations for current assignments to the distribution in the register of assignments for the distribution of mutual settlements.
// The distribution of mutual settlements is performed by the managing thread of the operational job queue.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Assignment of the assignment of accounts", there are also service columns:
//             * Organization               - CatalogRef.Companies -
//             * TaskPeriod             - Date -
//             * RecordID       - UUID  -
//             * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners   -
//             * ARAPObject            - CatalogRef.ARAPObjects - 
//             * Currency                    - CatalogRef.Currencies - 
//             * Document                  - DocumentRef - 
//             * RecordDate                - Date -
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
Procedure PerformDeferredDistributionOfSettlements(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	QueueRegisterMetadata = Metadata.InformationRegisters.JobsForARAPAllocating;
	Jobs.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	TaskTable.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TaskTable.ARAPObject AS ARAPObject,
	|	TaskTable.Currency AS Currency
	|INTO TTTuplesToBeProcessed
	|FROM
	|	&TaskTable AS TaskTable
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTuplesToBeProcessed.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTTuplesToBeProcessed.ARAPObject AS ARAPObject,
	|	TTTuplesToBeProcessed.Currency AS Currency,
	|	ISNULL(ARAPObjects.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) AS PaymentType_,
	|	CASE
	|		WHEN ISNULL(ARAPObjects.PaymentType_,
	|			VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TheseAreSettlementsWithCustomers,
	|	ISNULL(ARAPObjects.Object, UNDEFINED) AS Object,
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CalculationObjectReceiver,
	|	VALUE(Catalog.Currencies.EmptyRef) AS CurrencyReceiver,
	|	JobsForARAPAllocating.Document AS Document,
	|	JobsForARAPAllocating.Document AS Recorder,
	|	JobsForARAPAllocating.Organization AS Organization,
	|	MIN(JobsForARAPAllocating.TaskPeriod) AS RecountDate,
	|	MIN(JobsForARAPAllocating.TaskPeriod) AS RecalculationStartDate,
	|	MIN(JobsForARAPAllocating.ChangeControlPeriod) AS PeriodForMonitoringChangesAndCreatingTasks,
	|	1 AS Priority,
	|	FALSE AS ByDataOfSourceARAPObject
	|FROM
	|	TTTuplesToBeProcessed AS TTTuplesToBeProcessed
	|		INNER JOIN InformationRegister.JobsForARAPAllocating AS JobsForARAPAllocating
	|		ON TTTuplesToBeProcessed.AccountingDimensionByPartners = JobsForARAPAllocating.AccountingDimensionByPartners
	|		AND TTTuplesToBeProcessed.ARAPObject = JobsForARAPAllocating.ARAPObject
	|		AND TTTuplesToBeProcessed.Currency = JobsForARAPAllocating.Currency
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON TTTuplesToBeProcessed.ARAPObject = ARAPObjects.Ref
	|GROUP BY
	|	TTTuplesToBeProcessed.AccountingDimensionByPartners,
	|	TTTuplesToBeProcessed.ARAPObject,
	|	TTTuplesToBeProcessed.Currency,
	|	ISNULL(ARAPObjects.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)),
	|	CASE
	|		WHEN ISNULL(ARAPObjects.PaymentType_,
	|			VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	ISNULL(ARAPObjects.Object, UNDEFINED),
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef),
	|	VALUE(Catalog.ARAPObjects.EmptyRef),
	|	VALUE(Catalog.Currencies.EmptyRef),
	|	JobsForARAPAllocating.Document,
	|	JobsForARAPAllocating.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TuplesToBeProcessed.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TuplesToBeProcessed.ARAPObject AS ARAPObject,
	|	TuplesToBeProcessed.Currency AS Currency
	|FROM
	|	TTTuplesToBeProcessed AS TuplesToBeProcessed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TuplesToBeProcessed.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TuplesToBeProcessed.ARAPObject AS ARAPObject,
	|	TuplesToBeProcessed.Currency AS Currency,
	|	JobsForARAPAllocating.RecordID AS RecordID,
	|	JobsForARAPAllocating.CompletedWithAnError AS CompletedWithAnError
	|FROM
	|	TTTuplesToBeProcessed AS TuplesToBeProcessed
	|		INNER JOIN InformationRegister.JobsForARAPAllocating AS JobsForARAPAllocating
	|		ON TuplesToBeProcessed.AccountingDimensionByPartners = JobsForARAPAllocating.AccountingDimensionByPartners
	|		AND TuplesToBeProcessed.ARAPObject = JobsForARAPAllocating.ARAPObject
	|		AND TuplesToBeProcessed.Currency = JobsForARAPAllocating.Currency";
	
	Query.SetParameter("TaskTable", Jobs);
	
	SetPrivilegedMode(True);
	DataByTuple = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	InitialDataForDistribution = DataByTuple[DataByTuple.UBound() - 2].Unload(); // ValueTable
	InitialDataForDistribution.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
	TuplesToBeProcessed = DataByTuple[DataByTuple.UBound()-1].Select();
	TupleIds = DataByTuple[DataByTuple.UBound()].Unload();
	TupleIds.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
	
	ParametersOfDataProcessing = New Structure;
	
	PortionProcessedSuccessfully = True;
	BeginTransaction();

	Try
		
		ExceptionReason = "Block";
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.JobsForARAPAllocating");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = TupleIds.Copy(New Structure("CompletedWithAnError", False));
		LockItem.UseFromDataSource("RecordID", "RecordID");
		Block.Lock();
		
		ExceptionReason = "BadData";
		ParametersOfDataProcessing.Insert("DataForProcessing_", InitialDataForDistribution);
		ParametersOfDataProcessing.Insert("SupplementDistributeReceivers", True);
		ParametersOfDataProcessing.Insert("RegisterTasksByReceivers", True);
		SetPrivilegedMode(True);
		ARAPAccountingInternal.PerformDeferredAllocation(ParametersOfDataProcessing);
		BackdateJobQueue.DeleteQueueTasks(QueueRegisterMetadata.Name,
			TupleIds.UnloadColumn("RecordID"));
		SetPrivilegedMode(False);
				
		CommitTransaction();
	Except
		RollbackTransaction();
		PortionProcessedSuccessfully = False;
	EndTry;
	
	If PortionProcessedSuccessfully Then
		SetPrivilegedMode(True);
		If InitialDataForDistribution.Count() > 0 Then
			BackdateJobQueue.UncheckCompletedWithErrorBasedOnDocuments(
				CommonClientServer.CollapseArray(InitialDataForDistribution.UnloadColumn("Document")),
				Catalogs.BackdateJobKinds.ARAPAllocationByDueDates);
		EndIf;
		SetPrivilegedMode(False);
		Return;
	EndIf;
	
	TupleSelectionStructure = New Structure("AccountingDimensionByPartners, ARAPObject, Currency");
	
	While TuplesToBeProcessed.Next() Do
		
		SuccessfullyProcessedDocuments = New Array;
		
		TupleSelectionStructure.AccountingDimensionByPartners = TuplesToBeProcessed.AccountingDimensionByPartners;
		TupleSelectionStructure.ARAPObject = TuplesToBeProcessed.ARAPObject;
		TupleSelectionStructure.Currency = TuplesToBeProcessed.Currency;

		DataToCurrentDistribution = InitialDataForDistribution.Copy(TupleSelectionStructure);
		PortionDocuments = CommonClientServer.CollapseArray(DataToCurrentDistribution.UnloadColumn("Document"));
		
		TupleIdTable = TupleIds.Copy(TupleSelectionStructure);
		
		BeginTransaction();

		Try
			
			ExceptionReason = "Block";
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.JobsForARAPAllocating");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.DataSource = TupleIdTable.Copy(New Structure("CompletedWithAnError", False));
			LockItem.UseFromDataSource("RecordID", "RecordID");
			Block.Lock();
			
			ExceptionReason = "BadData";
			ParametersOfDataProcessing.Insert("DataForProcessing_", DataToCurrentDistribution);
			ParametersOfDataProcessing.Insert("SupplementDistributeReceivers", True);
			ParametersOfDataProcessing.Insert("RegisterTasksByReceivers", True);
			SetPrivilegedMode(True);
			ARAPAccountingInternal.PerformDeferredAllocation(ParametersOfDataProcessing);
			BackdateJobQueue.DeleteQueueTasks(QueueRegisterMetadata.Name,
				TupleIdTable.UnloadColumn("RecordID"));
			SetPrivilegedMode(False);
					
			CommonClientServer.SupplementArray(SuccessfullyProcessedDocuments, PortionDocuments, True);
					
			CommitTransaction();

		Except

			RollbackTransaction();

			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			If ExceptionReason = "Block" Then
				Raise ErrorText;
			EndIf;

			For Each CurrentDocument In PortionDocuments Do
				BackdateJobQueue.WriteErrorToEventLog(QueueRegisterMetadata,
					Catalogs.BackdateJobKinds.ARAPAllocationByDueDates, ErrorText,
					CurrentDocument);
			EndDo;
			
			FoundJobs = Jobs.FindRows(TupleSelectionStructure);
			For Each FoundRow In FoundJobs Do
				IdsOfUnprocessedRecords.Insert(FoundRow.RecordID, ErrorText);
			EndDo;

		EndTry;
		
		SetPrivilegedMode(True);
		If SuccessfullyProcessedDocuments.Count() > 0 Then
			BackdateJobQueue.UncheckCompletedWithErrorBasedOnDocuments(SuccessfullyProcessedDocuments,
				Catalogs.BackdateJobKinds.ARAPAllocationByDueDates);
		EndIf;
		SetPrivilegedMode(False);
		
	EndDo;
	
EndProcedure

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
//  AdditionalProperties              - See additional properties
//
Procedure BeforeErrorHandling(
			QueueParameters,
			Data,
			IdsOfUnprocessedRecords,
			ExceptionText,
			AdditionalProperties) Export
	
	If IdsOfUnprocessedRecords.Count() > 0 Then

		QueueRegisterMetadata = Metadata.InformationRegisters.JobsForARAPAllocating;
		IdsOfTupleTasks = New Array;

		For Each Id In IdsOfUnprocessedRecords Do
			IdsOfTupleTasks.Add(Id.Key);
		EndDo;

		QueueRegisterName = QueueRegisterMetadata.Name;
		Query = New Query;
		Query.Text = "
		|SELECT
		|	Jobs.Document AS Document,
		|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Jobs.ARAPObject AS ARAPObject,
		|	Jobs.Currency AS Currency,
		|	Jobs.Organization AS Organization,
		|	Jobs.TaskPeriod AS TaskPeriod,
		|	Jobs.RecordID AS RecordID,
		|	Jobs.RecordDate AS RecordDate,
		|	Jobs.ChangeControlPeriod AS ChangeControlPeriod
		|INTO TT_IDs
		|FROM
		|	InformationRegister.JobsForARAPAllocating AS Jobs
		|WHERE
		|	Jobs.RecordID IN (&IdsOfTupleTasks)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_IDs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	TT_IDs.ARAPObject AS ARAPObject,
		|	TT_IDs.Currency AS Currency,
		|	TT_IDs.RecordID AS RecordID
		|FROM
		|	TT_IDs AS TT_IDs
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_IDs.Document AS Document,
		|	TT_IDs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	TT_IDs.ARAPObject AS ARAPObject,
		|	TT_IDs.Currency AS Currency,
		|	TT_IDs.Organization AS Organization,
		|	MIN(TT_IDs.TaskPeriod) AS TaskPeriod,
		|	MIN(TT_IDs.RecordDate) AS RecordDate,
		|	MIN(TT_IDs.ChangeControlPeriod) AS ChangeControlPeriod
		|FROM
		|	TT_IDs AS TT_IDs
		|GROUP BY
		|	TT_IDs.Document,
		|	TT_IDs.AccountingDimensionByPartners,
		|	TT_IDs.ARAPObject,
		|	TT_IDs.Currency,
		|	TT_IDs.Organization
		|TOTALS
		|BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency";

		Query.SetParameter("IdsOfTupleTasks", IdsOfTupleTasks);
		
		SetPrivilegedMode(True);
		Result = Query.ExecuteBatch();
		SetPrivilegedMode(False);

		TupleErrors = Result[Result.UBound() - 1].Unload();
		TupleErrors.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");

		SampleByAnalytics = Result[Result.UBound()].Select(QueryResultIteration.ByGroups);

		TaskSelectionStructure = New Structure;

		While SampleByAnalytics.Next() Do

			SamplingByARAPObject = SampleByAnalytics.Select(QueryResultIteration.ByGroups);

			While SamplingByARAPObject.Next() Do

				CurrencySelection_1 = SamplingByARAPObject.Select(QueryResultIteration.ByGroups);

				While CurrencySelection_1.Next() Do

					ErrorID = New UUID;

					TaskSelectionStructure.Insert("AccountingDimensionByPartners",
						CurrencySelection_1.AccountingDimensionByPartners);
					TaskSelectionStructure.Insert("ARAPObject", CurrencySelection_1.ARAPObject);
					TaskSelectionStructure.Insert("Currency", CurrencySelection_1.Currency);

					ErrorsTexts = New Array;
					TupleIdentifiers = New Array;
					ErrorsDetails = TupleErrors.FindRows(TaskSelectionStructure);
					For Each ErrorDescriptionString In ErrorsDetails Do
						ErrorsTexts.Add(IdsOfUnprocessedRecords.Get(
							ErrorDescriptionString.RecordID));
						TupleIdentifiers.Add(ErrorDescriptionString.RecordID);
					EndDo;
					ErrorsTexts = CommonClientServer.CollapseArray(ErrorsTexts);
					ErrorDescription = StrConcat(ErrorsTexts, Chars.LF);

					BeginTransaction();

					Try
						// Writing to the error register
						ErrorRecordset = InformationRegisters.JobQueueErrors.CreateRecordSet();
						ErrorRecording = ErrorRecordset.Add();
						ErrorRecording.ErrorID = ErrorID;
						ErrorRecording.ErrorDescription = ErrorDescription;
						ErrorRecording.RecordDate = CurrentSessionDate();
						SetPrivilegedMode(True);
						ErrorRecordset.Write(False);
						SetPrivilegedMode(False);

						DetailedRecords = CurrencySelection_1.Select();

						Jobs = CreateRecordSet();

						While DetailedRecords.Next() Do

							TaskWithError = Jobs.Add();
							FillPropertyValues(TaskWithError, DetailedRecords);
							TaskWithError.RecordID = New UUID;
							TaskWithError.CompletedWithAnError = True;
							TaskWithError.ErrorID = ErrorID;

						EndDo;
						
						SetPrivilegedMode(True);
						Jobs.Write(False);
						
						BackdateJobQueue.DeleteQueueTasks(QueueRegisterName, TupleIdentifiers);
						SetPrivilegedMode(False);
							
						CommitTransaction();
						
					Except

						RollbackTransaction();

						ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());

						BackdateJobQueue.WriteErrorToEventLog(QueueRegisterMetadata,
							Catalogs.BackdateJobKinds.ARAPAllocationByDueDates, ErrorText);
						
						Raise ErrorText;

					EndTry;
					
				EndDo;

			EndDo;

		EndDo;
		
		IdsOfUnprocessedRecords.Clear();
	
	EndIf;
	
EndProcedure

#EndRegion

// Overriding task queue parameters.
// 
// Parameters:
//  QueueName -String - Name Of the Task Queue
// 
// Returns:
//  Structure - Redefining job queue description parameters:
// * RequestParameterTaskType - String - The name of the parameter corresponding to the "Task view" field that will be used when generating query texts.
// It is overridden only if there is no "Task view" field in the task register. 
// The parameter name must be unique among all queue job registers.
// * TaskTypeValue - CatalogRef.BackdateJobKinds - The value that will be substituted in the parameter of the task request.
// The parameter is filled in only if there is no "Task view" field in the task register.
// * RequestParameterQueueNumber - String - The name of the parameter corresponding to the "Number field" that will be used when generating query texts.
// Redefined only if there is no "Task view" field in the task register.
// The parameter name must be unique among all queue job registers.
// * QueueNumberValue - Number - The value that will be substituted in the parametersprosanumeror.
// * QueryTextCalculationGranulesInProcessing - String - The Query Text that will be used to generate a temporary table with task calculation granules.
// The fields to be selected must correspond to the columns of the table of values obtained as a result of calling the Calculation table function of the Task register manager module.
// The name of the temporary table must be unique among all queue job registers.
// * QueryTextExcludedDocuments - String - The text of the request, the result of which gets a list of documents for which calculation granules are processed.
// The text of the request is generated based on the text of the request granulareadcounts in processing.
// * ProcessedGranulesTableName - String - The name of the query parameter whose value is a table of values with data of processed pellets.
// The table name must be unique among all queue job registers.
//
Function DescriptionOfQueueParameters(QueueName) Export
	
	QueueDescription = BackdateJobQueue.StructureOfDescriptionOfQueueParameters();
	QueueDescription.RequestParameterTaskType = "TypeOfTaskDistributionOfSettlementsByTime";
	QueueDescription.TaskTypeValue = Catalogs.BackdateJobKinds.ARAPAllocationByDueDates;
	QueueDescription.RequestParameterQueueNumber = "QueueNumberDistributionOfSettlementsByTime";
	QueueDescription.QueueNumberValue = Common.ObjectAttributeValue(Catalogs.BackdateJobKinds.ARAPAllocationByDueDates, "QueueNumber");
	
	#Region QueryTextCalculationGranulesInProcessing
	QueryTextCalculationGranulesInProcessing = "
	|SELECT DISTINCT
	|	ProcessedGranules.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ProcessedGranules.ARAPObject AS ARAPObject,
	|	ProcessedGranules.Currency AS Currency,
	|	ProcessedGranules.JobKind AS JobKind
	|INTO TTProcessedGranules
	|FROM
	|	&ProcessedGranules AS ProcessedGranules
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency";
	
	QueryTextCalculationGranulesInProcessing = StrReplace(QueryTextCalculationGranulesInProcessing, "TTProcessedGranules", "TT" + QueueName);
	QueryTextCalculationGranulesInProcessing = StrReplace(QueryTextCalculationGranulesInProcessing, "&ProcessedGranules", "&ProcessedGranules" + QueueName);
	QueueDescription.Insert("QueryTextCalculationGranulesInProcessing", QueryTextCalculationGranulesInProcessing);
	QueueDescription.Insert("ProcessedGranulesTableName", "ProcessedGranules" + QueueName);
	#EndRegion
	
	#Region QueryTextExcludedDocuments
	QueryTextExcludedDocuments = "
	|SELECT DISTINCT
	|	JobsForARAPAllocating.Document AS Document,
	|	ProcessedTuples.JobKind AS JobKind,
	|	ProcessedTuples.JobKind.QueueNumber AS QueueNumber
	|FROM
	|	InformationRegister.JobsForARAPAllocating AS JobsForARAPAllocating
	|		INNER JOIN TTProcessedGranules AS ProcessedTuples
	|		ON ProcessedTuples.AccountingDimensionByPartners = JobsForARAPAllocating.AccountingDimensionByPartners
	|		AND ProcessedTuples.ARAPObject = JobsForARAPAllocating.ARAPObject
	|		AND ProcessedTuples.Currency = JobsForARAPAllocating.Currency";
	
	QueryTextExcludedDocuments = StrReplace(QueryTextExcludedDocuments, "TTProcessedGranules", "TT" + QueueName);
	QueueDescription.Insert("QueryTextExcludedDocuments", QueryTextExcludedDocuments);
	#EndRegion
	
	Return QueueDescription;
	
EndFunction

// Register the problem of performing the calculation.
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
//
Procedure RegisterCalculationExecutionProblem(HandlerParameters, JobKind = Undefined) Export
	
	If Not HandlerParameters.Data_Stage.Code = Catalogs.MonthEndClosingOperations.AdditionalDocumentPosting Then
		Return;
	EndIf;
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	EndOfPeriod = CalculationParameters.EndOfPeriod;
	
	ProblemGroup = NStr("vi = 'Khi thực hiện thao tác, đã ghi nhận lỗi';
						|ru = 'При выполнении операции зарегистрированы ошибки';
						|en = 'Errors are registered while executing the operation'; fa = 'Errors are registered while executing the operation';
						|it = 'При выполнении операции зарегистрированы ошибки';
						|pl = 'Errors are registered while executing the operation';
						|tr = 'İşlemin gerçekleştirilmesi sırasında hatalar kaydedildi'",
		Common.DefaultLanguageCode());
		
	TaskTemplateWithError = NStr("vi = 'Thực hiện nhiệm vụ ""%1"" theo
	|Phân tích ghi nhận theo bạn hàng: %2, Đối tượng hạch toán: %3, tiền tệ hạch toán: %4 đã hoàn tất có lỗi.';
	|ru = 'Выполнение задания ""%1"" по
	|Аналитика учета по партнерам: %2, Объект расчетов: %3, валюта расчетов: %4 завершилось с ошибками.';
	|en = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was completed with errors.'; fa = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was completed with errors.';
	|it = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was completed with errors.';
	|pl = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was completed with errors.';
	|tr = 'İş ortakları kapsamındaki muhasebe boyutu
	|için ""%1"" görevinin gerçekleştirilmesi: %2, Alacak/Borç nesnesi: %3, Alacak/Borç muhasebesi para birimi: %4 hatalar ile sona erdi.'", Common.DefaultLanguageCode());
	
	TemplateTaskFailed = NStr("vi = 'Nhiệm vụ ""%1"" theo
	|Phân tích ghi nhận theo bạn hàng: %2, Đối tượng hạch toán: %3, tiền tệ hạch toán: %4 đã hoàn tất có lỗi.';
	|ru = 'Задание ""%1"" по
	|Аналитика учета по партнерам: %2, Объект расчетов: %3, валюта расчетов: %4 не было выполнено.';
	|en = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was not completed.'; fa = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was not completed.';
	|it = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was not completed.';
	|pl = 'The ""%1"" job of
	|Accounting dimension by partners: %2, AR/AP object: %3, payment currency: %4 was not completed.';
	|tr = 'İş ortakları kapsamındaki muhasebe
	|boyutunun ""%1"" görevi: %2, Alacak/Borç nesnesi: %3, Alacak/Borç muhasebesi para birimi: %4 gerçekleştirilmedi.  '", Common.DefaultLanguageCode());
		
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);

	Query.Text = "
	|SELECT
	|	JobsForARAPAllocating.Organization AS Organization,
	|	MIN(BEGINOFPERIOD(JobsForARAPAllocating.TaskPeriod, MONTH)) AS TaskPeriod,
	|	JobsForARAPAllocating.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	JobsForARAPAllocating.ARAPObject AS ARAPObject,
	|	JobsForARAPAllocating.Currency AS Currency,
	|	JobsForARAPAllocating.CompletedWithAnError
	|INTO TT_Errors
	|FROM
	|	InformationRegister.JobsForARAPAllocating AS JobsForARAPAllocating
	|WHERE
	|	JobsForARAPAllocating.Organization IN (&CompanyArray)
	|	AND JobsForARAPAllocating.TaskPeriod <= &EndOfPeriod
	|GROUP BY
	|	JobsForARAPAllocating.Organization,
	|	JobsForARAPAllocating.AccountingDimensionByPartners,
	|	JobsForARAPAllocating.ARAPObject,
	|	JobsForARAPAllocating.Currency,
	|	JobsForARAPAllocating.CompletedWithAnError
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Errors.Organization AS Organization,
	|	TT_Errors.TaskPeriod AS TaskPeriod,
	|	TT_Errors.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TT_Errors.ARAPObject AS ARAPObject,
	|	TT_Errors.Currency AS Currency,
	|	TT_Errors.CompletedWithAnError AS CompletedWithAnError
	|FROM
	|	TT_Errors AS TT_Errors
	|TOTALS
	|BY
	|	Organization,
	|	TaskPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_Errors";
	
	SetPrivilegedMode(True);
	SelectionByOrganization = Query.Execute().Select(QueryResultIteration.ByGroups);
	SetPrivilegedMode(False);

	While SelectionByOrganization.Next() Do

		SamplingByPeriod = SelectionByOrganization.Select(QueryResultIteration.ByGroups);

		While SamplingByPeriod.Next() Do

			RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
					HandlerParameters.Data_Stage.Code, SelectionByOrganization.Organization,
				?(ValueIsFilled(SamplingByPeriod.TaskPeriod), SamplingByPeriod.TaskPeriod, BegOfMonth(EndOfPeriod)));

			DetailedRecords = SamplingByPeriod.Select();

			While DetailedRecords.Next() Do

				FullTextOfProblem = StringFunctionsClientServer.SubstituteParametersToString(?(
					DetailedRecords.CompletedWithAnError, TaskTemplateWithError, TemplateTaskFailed),
					Catalogs.BackdateJobKinds.ARAPAllocationByDueDates,
					DetailedRecords.AccountingDimensionByPartners, DetailedRecords.ARAPObject, DetailedRecords.Currency);

				MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
							RegistrationParameters, ProblemGroup, Enums.AccountingIssueSeverity.Error,
					FullTextOfProblem, DetailedRecords.ARAPObject);

			EndDo;

		EndDo;

	EndDo;
	
EndProcedure

// Describes a table of calculation granules by queue register.
// 
// Returns:
//  ValueTable - The table of tuples of the register of the AR/AP accounts in processing:
// * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting analytics by partners
// * ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
// * Currency - CatalogRef.Currencies - Settlement currency
//
Function TableOfCalculationGranules() Export

	CalculationGranules = New ValueTable;
	CalculationGranules.Columns.Add("AccountingDimensionByPartners",
		New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
	CalculationGranules.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	CalculationGranules.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	CalculationGranules.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
	
	Return CalculationGranules;

EndFunction

// Error data is processed based on the submitted list of documents and the type of task.
//
// Parameters:
//  DocumentsList - Undefined, Array of DocumentRef - Processed Documents
//  ErrorIds - Undefined, Array of UUID - List of processed error identifiers
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
//
Procedure UncheckCompletedWithErrorBasedOnDocuments(DocumentsList, ErrorIds, JobKind = Undefined) Export
	
	If JobKind <> Undefined 
		And Not JobKind = Catalogs.BackdateJobKinds.ARAPAllocationByDueDates Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DocumentsList", DocumentsList);

	Query.Text = "
	|SELECT
	|	TableQueue.TaskPeriod AS TaskPeriod,
	|	TableQueue.Organization AS Organization,
	|	TableQueue.RecordID AS RecordID,
	|	TableQueue.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TableQueue.ARAPObject AS ARAPObject,
	|	TableQueue.Currency AS Currency,
	|	TableQueue.Document AS Document,
	|	TableQueue.RecordDate AS RecordDate,
	|	TableQueue.ErrorID AS ErrorID,
	|	TableQueue.ChangeControlPeriod AS ChangeControlPeriod
	|INTO ErrorsData
	|FROM
	|	InformationRegister.JobsForARAPAllocating AS TableQueue
	|WHERE
	|	TableQueue.CompletedWithAnError
	|	AND &FilterByDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ErrorsData.TaskPeriod AS TaskPeriod,
	|	ErrorsData.Organization AS Organization,
	|	ErrorsData.RecordID AS RecordID,
	|	ErrorsData.ErrorID AS ErrorID,
	|	ErrorsData.Document AS Document
	|FROM
	|	ErrorsData AS ErrorsData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(ErrorsData.TaskPeriod) AS TaskPeriod,
	|	ErrorsData.Organization AS Organization,
	|	ErrorsData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	ErrorsData.ARAPObject AS ARAPObject,
	|	ErrorsData.Currency AS Currency,
	|	ErrorsData.Document AS Document,
	|	MIN(ErrorsData.RecordDate) AS RecordDate,
	|	MIN(ErrorsData.ChangeControlPeriod) AS ChangeControlPeriod
	|FROM
	|	ErrorsData AS ErrorsData
	|GROUP BY
	|	ErrorsData.Organization,
	|	ErrorsData.AccountingDimensionByPartners,
	|	ErrorsData.ARAPObject,
	|	ErrorsData.Currency,
	|	ErrorsData.Document";
	
	If DocumentsList = Undefined Then
		Query.Text = StrReplace(Query.Text, "&FilterByDocuments", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "&FilterByDocuments", "TableQueue.Document IN (&DocumentsList)");
	EndIf;

	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	JobsWithErrors = Result[Result.UBound() - 1].Unload();
	JobsWithErrors.Indexes.Add("Document");
	EntriesForCreatingTasks = Result[Result.UBound()].Unload();
	EntriesForCreatingTasks.Indexes.Add("Document");
	SetPrivilegedMode(False);

	If JobsWithErrors.Count() = 0 Then
		Return;
	EndIf;
	
	QueueRegisterMetadata = Metadata.InformationRegisters.JobsForARAPAllocating;
	TaskRegisterManager = Common.ObjectManagerByFullName(QueueRegisterMetadata.FullName());
	
	Documents_With_Errors = CommonClientServer.CollapseArray(JobsWithErrors.UnloadColumn("Document"));
	
	SizeOfPortionOfTasksToDelete = 500;
	PortionOfTasksToDelete = JobsWithErrors.CopyColumns();
	PortionOfNewTasks = EntriesForCreatingTasks.CopyColumns();
	DocumentSelectionStructure = New Structure("Document");
	
	For Each DocumentWithError In Documents_With_Errors Do

		DocumentSelectionStructure.Document = DocumentWithError;
		CommonClientServer.SupplementTable(JobsWithErrors.Copy(DocumentSelectionStructure),
			PortionOfTasksToDelete);
		CommonClientServer.SupplementTable(EntriesForCreatingTasks.Copy(
			DocumentSelectionStructure), PortionOfNewTasks);

		If PortionOfTasksToDelete.Count() >= SizeOfPortionOfTasksToDelete Then

			BackdateJobQueue.DeleteTasksWithErrorsAndRegisterNewOnesWithoutErrors(TaskRegisterManager,
				PortionOfTasksToDelete, PortionOfNewTasks, ErrorIds);

		EndIf;

	EndDo;
	
	If PortionOfTasksToDelete.Count() > 0 Then
		BackdateJobQueue.DeleteTasksWithErrorsAndRegisterNewOnesWithoutErrors(TaskRegisterManager,
			PortionOfTasksToDelete, PortionOfNewTasks, ErrorIds);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

// In the queue register, it registers errors that occurred during the processing of calculation granules.
// In case of a processing error, calculation granules: related job records are minimized (and subsequently deleted), 
// and instead a new record is created marked "Completed with an error" and the assigned error ID. 
// A detailed description of the error with the same identifier will be recorded in the information register "Job Queue Errors".
// 
// Parameters:
//  RecordIds - Array of UUID - List of IDs of entries in the queue register.
//  ErrorDescriptionTable - ValueTable - Error description table:
// * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting analytics by partners
// * ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
// * Currency - CatalogRef.Currencies - Settlement currency
// * ErrorDescription - String - detailed description of the error.
Procedure RegisterDataProcessingErrors(RecordIds, ErrorDescriptionTable) Export
	
	If ErrorDescriptionTable.Count() > 0 Then

		Query = New Query;
		Query.Text = "
		|SELECT
		|	RegisterData.TaskPeriod AS TaskPeriod,
		|	RegisterData.Organization AS Organization,
		|	RegisterData.RecordID AS RecordID,
		|	RegisterData.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	RegisterData.ARAPObject AS ARAPObject,
		|	RegisterData.Currency AS Currency,
		|	RegisterData.Document AS Document,
		|	RegisterData.RecordDate AS RecordDate,
		|	RegisterData.ErrorID AS ErrorID,
		|	RegisterData.CompletedWithAnError AS CompletedWithAnError,
		|	RegisterData.ChangeControlPeriod AS ChangeControlPeriod
		|INTO CalculationGranulesWithErrors
		|FROM
		|	InformationRegister.JobsForARAPAllocating AS RegisterData
		|WHERE
		|	RegisterData.RecordID IN (&RecordIds)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.Document AS Document,
		|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Jobs.ARAPObject AS ARAPObject,
		|	Jobs.Currency AS Currency,
		|	Jobs.Organization AS Organization,
		|	MIN(Jobs.TaskPeriod) AS TaskPeriod,
		|	MIN(Jobs.RecordDate) AS RecordDate,
		|	MIN(Jobs.ChangeControlPeriod) AS ChangeControlPeriod
		|FROM
		|	CalculationGranulesWithErrors AS Jobs
		|GROUP BY
		|	Jobs.Document,
		|	Jobs.AccountingDimensionByPartners,
		|	Jobs.ARAPObject,
		|	Jobs.Currency,
		|	Jobs.Organization
		|TOTALS
		|BY
		|	AccountingDimensionByPartners,
		|	ARAPObject,
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.RecordID AS JobID,
		|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Jobs.ARAPObject AS ARAPObject,
		|	Jobs.Currency AS Currency
		|FROM
		|	CalculationGranulesWithErrors AS Jobs";
		
		Query.SetParameter("RecordIds", RecordIds);
		
		SetPrivilegedMode(True);
		Result = Query.ExecuteBatch();
		SetPrivilegedMode(False);

		TaskIds = Result[Result.UBound()].Unload();
		TaskIds.Indexes.Add("AccountingDimensionByPartners, ARAPObject, Currency");
		QueueRegisterMetadata = Metadata.InformationRegisters.JobsForARAPAllocating;

		SampleByAnalytics = Result[Result.UBound() - 1].Select(QueryResultIteration.ByGroups);

		TaskSelectionStructure = New Structure;

		While SampleByAnalytics.Next() Do

			SamplingByARAPObject = SampleByAnalytics.Select(QueryResultIteration.ByGroups);

			While SamplingByARAPObject.Next() Do

				CurrencySelection_1 = SamplingByARAPObject.Select(QueryResultIteration.ByGroups);

				While CurrencySelection_1.Next() Do

					ErrorID = New UUID;

					TaskSelectionStructure.Insert("AccountingDimensionByPartners",
						CurrencySelection_1.AccountingDimensionByPartners);
					TaskSelectionStructure.Insert("ARAPObject", CurrencySelection_1.ARAPObject);
					TaskSelectionStructure.Insert("Currency", CurrencySelection_1.Currency);

					ErrorsTexts = ErrorDescriptionTable.Copy(TaskSelectionStructure,
						"ErrorDescription").UnloadColumn("ErrorDescription");
					ErrorsTexts = CommonClientServer.CollapseArray(ErrorsTexts);
					ErrorDescription = StrConcat(ErrorsTexts, Chars.LF);

					BeginTransaction();

					Try
						
						// Writing to the error register
						ErrorRecordset = InformationRegisters.JobQueueErrors.CreateRecordSet();
						ErrorRecording = ErrorRecordset.Add();
						ErrorRecording.ErrorID = ErrorID;
						ErrorRecording.ErrorDescription = ErrorDescription;
						ErrorRecording.RecordDate = CurrentSessionDate();
						SetPrivilegedMode(True);
						ErrorRecordset.Write(False);
						SetPrivilegedMode(False);

						DetailedRecords = CurrencySelection_1.Select();

						Jobs = CreateRecordSet();

						While DetailedRecords.Next() Do

							TaskWithError = Jobs.Add();
							FillPropertyValues(TaskWithError, DetailedRecords);
							TaskWithError.RecordID = New UUID;
							TaskWithError.CompletedWithAnError = True;
							TaskWithError.ErrorID = ErrorID;

						EndDo;
						
						SetPrivilegedMode(True);
						Jobs.Write(False);
						SetPrivilegedMode(False);

						TupleIdentifiers = TaskIds.Copy(TaskSelectionStructure,
							"JobID").UnloadColumn("JobID");
						
						SetPrivilegedMode(True);
						BackdateJobQueue.DeleteQueueTasks(QueueRegisterMetadata.Name,
							TupleIdentifiers);
						SetPrivilegedMode(False);
						
						CommitTransaction();

					Except

						RollbackTransaction();

						ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());

						BackdateJobQueue.WriteErrorToEventLog(
							QueueRegisterMetadata,
							Catalogs.BackdateJobKinds.ARAPAllocationByDueDates, ErrorText);

					EndTry;

				EndDo;

			EndDo;

		EndDo;

	EndIf;
	
EndProcedure

Procedure ReportDataProcessingErrors(TupleErrors)
	
	If TupleErrors.Count() > 0 Then
	
		ErrorTemplate = NStr("vi = 'Không thể điền hạch toán công nợ hiện tại:
		|Đối tượng phân tích kế toán theo bạn hàng = %1
		|Đối tượng hạch toán = %2
		|Tiền tệ = %3
		|do nguyên nhân: %4';
		|ru = 'Не удалось выполнить заполнение оперативных взаиморасчетов:
		|Аналитика учета по партнерам = %1
		|Объект расчетов = %2
		|Валюта = %3
		|по причине: %4';
		|en = 'Cannot fill in real-time AR/AP:
		|Accounting dimension by partners = %1
		|AR/AP object = %2
		|Currency = %3
		|Reason: %4'; fa = 'Cannot fill in real-time AR/AP:
		|Accounting dimension by partners = %1
		|AR/AP object = %2
		|Currency = %3
		|Reason: %4';
		|it = 'Cannot fill in real-time AR/AP:
		|Accounting dimension by partners = %1
		|AR/AP object = %2
		|Currency = %3
		|Reason: %4';
		|pl = 'Cannot fill in real-time AR/AP:
		|Accounting dimension by partners = %1
		|AR/AP object = %2
		|Currency = %3
		|Reason: %4';
		|tr = 'Operasyonel hesaplamalar doldurulamadı:
		|İş ortaklarına göre hesap analizi = %1
		|Alacak/Borç nesnesi = %2
		|Para birimi = %3
		| nedeni: %4'", Common.DefaultLanguageCode());
				
		ErrorsArray = New Array;
		For Each TupleError In TupleErrors Do
			If ValueIsFilled(TupleError.ErrorDescription) Then
				ErrorTextByTuple = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
					TupleError.AccountingDimensionByPartners, TupleError.ARAPObject,
					TupleError.Currency, TupleError.ErrorDescription);
				ErrorsArray.Add(ErrorTextByTuple);
			EndIf;
		EndDo;
		
		If ErrorsArray.Count() > 0 Then
			ExceptionText = StrConcat(CommonClientServer.CollapseArray(ErrorsArray), Chars.LF);
			Raise ExceptionText;
		EndIf;

	EndIf;
	
EndProcedure

#EndRegion

#EndIf