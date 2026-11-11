#Region Internal

#Region MultithreadedCalculationProcessingManager

Function MultithreadedDataParameters() Export
	
	DataProcessorData = New Structure;
	DataProcessorData.Insert("LatestRecord", Undefined);
	DataProcessorData.Insert("PortionSize", Undefined);
	DataProcessorData.Insert("QueryCondition", "");
	DataProcessorData.Insert("QueryOptions", New Structure);
	
	TuplesInProcessing = New ValueTable();
	TuplesInProcessing.Columns.Add("ThreadID", New TypeDescription("UUID"));
	TuplesInProcessing.Columns.Add("PaymentType_", New TypeDescription("EnumRef.PartnersARAPAccountingTypes"));
	TuplesInProcessing.Columns.Add("AccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
	TuplesInProcessing.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	TuplesInProcessing.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	
	DataProcessorData.Insert("TuplesInProcessing", TuplesInProcessing);
	
	Return DataProcessorData;
	
EndFunction

Function DataForProcessing(Parameters, ThisIsTransitionFromOffline = False) Export
	
	QueryText = 
	"SELECT
	|	Tuples.PaymentType_ AS PaymentType_,
	|	Tuples.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Tuples.ARAPObject AS ARAPObject,
	|	Tuples.Currency AS Currency
	|INTO TTTuplesInOperation
	|FROM
	|	&TuplesInProcessing AS Tuples
	|INDEX BY
	|	PaymentType_,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|	
	|;
	|
	|SELECT TOP 1000
	|	Jobs.DocumentsCount AS DocumentsCount,
	|	Jobs.PaymentType_ AS PaymentType_,
	|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Jobs.ARAPObject AS ARAPObject,
	|	Jobs.Currency AS Currency
	|INTO TTTuplesToBeProcessed
	|FROM
	|	InformationRegister.JobsForAllocatingARAP AS Jobs
	|	LEFT JOIN TTTuplesInOperation AS TuplesInProgress
	|	ON Jobs.PaymentType_ = TuplesInProgress.PaymentType_
	|		AND Jobs.PaymentType_ = TuplesInProgress.PaymentType_
	|		AND Jobs.AccountingDimensionByPartners = TuplesInProgress.AccountingDimensionByPartners
	|		AND Jobs.ARAPObject = TuplesInProgress.ARAPObject
	|		AND Jobs.Currency = TuplesInProgress.Currency
	|WHERE 
	|	TuplesInProgress.ARAPObject IS NULL
	|	AND (Jobs.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|			AND Jobs.ARAPObject > &ARAPObject
	|		OR Jobs.AccountingDimensionByPartners > &AccountingDimensionByPartners
	|		OR &WithoutDimension)
	|
	|GROUP BY
	|	Jobs.DocumentsCount,
	|	Jobs.PaymentType_,
	|	Jobs.AccountingDimensionByPartners,
	|	Jobs.ARAPObject,
	|	Jobs.Currency
	|
	|INDEX BY
	|	PaymentType_,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|SELECT
	|	COUNT(*) AS TasksLeft
	|FROM
	|	InformationRegister.JobsForAllocatingARAP AS Jobs
	|;
	|
	|SELECT
	|	TuplesToBeProcessed.DocumentsCount AS DocumentsCount,
	|	TuplesToBeProcessed.PaymentType_ AS PaymentType_,
	|	TuplesToBeProcessed.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TuplesToBeProcessed.ARAPObject AS ARAPObject,
	|	TuplesToBeProcessed.Currency AS Currency
	|FROM
	|	TTTuplesToBeProcessed AS TuplesToBeProcessed
	|
	|ORDER BY
	|	DocumentsCount DESC,
	|	AccountingDimensionByPartners,
	|	ARAPObject
	|;
	|
	|SELECT
	|	Jobs.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS TheseAreSettlementsWithCustomers,
	|	Jobs.PaymentType_ AS PaymentType_,
	|	Jobs.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Jobs.ARAPObject AS ARAPObject,
	|	Jobs.ARAPObject.Object AS Object,
	|	Jobs.Currency AS Currency,
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CalculationObjectReceiver,
	|	VALUE(Catalog.Currencies.EmptyRef) AS CurrencyReceiver,
	|	Jobs.Document AS Document,
	|	MAX(Jobs.Priority) AS Priority,
	|	CASE WHEN MAX(Jobs.Priority) = 2
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ByDataOfSourceARAPObject,
	|	MIN(Jobs.RecountDate) AS RecountDate,
	|	MIN(Jobs.RecountDate) AS RecalculationStartDate,
	|	MIN(CASE WHEN &ThisIsTransitionFromOffline
	|					OR VALUETYPE(Jobs.Document) IN (&ListOfPlanRegistrarTypes)
	|				THEN DATETIME(3999,1,1)
	|				ELSE Jobs.ChangeControlPeriod
	|			END) AS PeriodForMonitoringChangesAndCreatingTasks,
	|	TuplesToBeProcessed.DocumentsCount AS DocumentsCount
	|FROM
	|	InformationRegister.JobsForAllocatingARAP AS Jobs
	|	INNER JOIN TTTuplesToBeProcessed AS TuplesToBeProcessed
	|	ON Jobs.PaymentType_ = TuplesToBeProcessed.PaymentType_
	|		AND Jobs.AccountingDimensionByPartners = TuplesToBeProcessed.AccountingDimensionByPartners
	|		AND Jobs.ARAPObject = TuplesToBeProcessed.ARAPObject
	|		AND Jobs.Currency = TuplesToBeProcessed.Currency
	|WHERE
	|	&Condition
	|
	|GROUP BY
	|	Jobs.PaymentType_,
	|	Jobs.AccountingDimensionByPartners,
	|	Jobs.ARAPObject,
	|	Jobs.Currency,
	|	Jobs.Document,
	|	TuplesToBeProcessed.DocumentsCount
	|
	|ORDER BY
	|	MAX(Jobs.Priority) ASC,
	|	DocumentsCount DESC,
	|	AccountingDimensionByPartners,
	|	ARAPObject";

	If Parameters.PortionSize = Undefined Then
		QueryText = StrReplace(QueryText, " TOP 1000", "");
	EndIf;

	QueryText = StrReplace(QueryText, "1000", Format(Parameters.PortionSize, "NZ=0; NG=0"));
	QueryCondition = Parameters.QueryCondition;
	If Not ValueIsFilled(QueryCondition) Then
		QueryCondition = "TRUE";
	EndIf;
	QueryText = StrReplace(QueryText, "&Condition", QueryCondition);

	Query = New Query(QueryText);
	Query.SetParameter("DocumentsCount", 0);
	Query.SetParameter("AccountingDimensionByPartners", Undefined);
	Query.SetParameter("ARAPObject", Undefined);
	Query.SetParameter("WithoutDimension", True);
	Query.SetParameter("TuplesInProcessing", Parameters.TuplesInProcessing);
	Query.SetParameter("ThisIsTransitionFromOffline", ThisIsTransitionFromOffline);
	Query.SetParameter("ListOfPlanRegistrarTypes", OnlineARAPAccountingServer.ListOfPlanRegistrarTypes());

	LatestRecord = Parameters.LatestRecord;
	If LatestRecord <> Undefined Then
		Query.SetParameter("DocumentsCount", LatestRecord.DocumentsCount);
		Query.SetParameter("AccountingDimensionByPartners", LatestRecord.AccountingDimensionByPartners);
		Query.SetParameter("ARAPObject", LatestRecord.ARAPObject);
		Query.SetParameter("WithoutDimension", Not ValueIsFilled(LatestRecord.AccountingDimensionByPartners));
	EndIf;

	For Each Parameter In Parameters.QueryOptions Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;

	QueryResult = Query.ExecuteBatch();
	Data = QueryResult[QueryResult.UBound()].Unload();
	Data.Indexes.Add("PaymentType_,AccountingDimensionByPartners,ARAPObject,Currency");
	Tuples = QueryResult[QueryResult.UBound()-1].Unload();
	Jobs = QueryResult[QueryResult.UBound()-2].Select();
	If Jobs.Next() Then
		LeftToProcess = Jobs.TasksLeft;
	Else
		LeftToProcess = 0;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Tuples", Tuples);
	Result.Insert("Data", Data);
	Result.Insert("LeftToProcess", LeftToProcess);

	Return Result;
	
EndFunction

#EndRegion

#Region FillingAndClearingRegisters

// Registers calculation objects for deferred calculation by time and plan
// 
// Parameters:
// 	Recorder - DocumentRef - The registrar, the initiator of registration of tasks (the conducted document).
// 	ChangesTable - See OnlineARAPAccountingServer.TableToDistribution
Procedure RegisterChangesToDeferredAllocation(Recorder, ChangesTable) Export
	
	For Each ChangesRow In ChangesTable Do
		
		RecordSet = InformationRegisters.JobsForAllocatingARAP.CreateRecordSet();
		
		RecordSet.Filter.PaymentType_.Set(ChangesRow.PaymentType_);
		RecordSet.Filter.AccountingDimensionByPartners.Set(ChangesRow.AccountingDimensionByPartners);
		RecordSet.Filter.ARAPObject.Set(ChangesRow.ARAPObject);
		RecordSet.Filter.Currency.Set(ChangesRow.Currency);
		
		RecordSet.Filter.RecountDate.Set(ChangesRow.RecalculationStartDate);
		RecordSet.Filter.Document.Set(Recorder);
		
		NwRw = RecordSet.Add();
		NwRw.PaymentType_ = ChangesRow.PaymentType_;
		NwRw.AccountingDimensionByPartners = ChangesRow.AccountingDimensionByPartners;
		NwRw.ARAPObject = ChangesRow.ARAPObject;
		NwRw.Currency = ChangesRow.Currency;
		NwRw.RecountDate = ChangesRow.RecalculationStartDate;
		NwRw.Document = Recorder;
		NwRw.Priority = ?(ChangesRow.ByDataOfSourceARAPObject, 2, 1);
		NwRw.DocumentsCount = 1;
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

// Performs the distribution of calculations for current tasks to be distributed in the registers of the assignment of the distribution of settlements and the assignment of the distribution of mutual settlements
// 
// Parameters:
// 	Parameters - Structure, Undefined - The structure passes a table of tasks for distribution:
// 	 *DataForDevelopment - See DataForProcessing.
// 	ResultAddress - String - address of the temporary storage where the result of the procedure will be placed.
Procedure PerformDeferredAllocation(Parameters = Undefined, ResultAddress = Undefined) Export
	
	SetPrivilegedMode(True);

	If Not Constants.NewOnlineARAPAccounting.Get() Then
		Return;
	EndIf;
	
	If Parameters <> Undefined And Parameters.Property("DataForProcessing_") Then
		DataForProcessing_ = Parameters.DataForProcessing_;
	Else
		DataParameters = MultithreadedDataParameters();
		DataForProcessing_ = DataForProcessing(DataParameters).Data;
	EndIf;
	
	TableOfPaymentObjects = New ValueTable;
	TableOfPaymentObjects.Columns.Add("PaymentObject", New TypeDescription(Metadata.DefinedTypes.ARAPObject.Type));
	TableOfPaymentObjects.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
	TableOfPaymentObjects.Columns.Add("TheseAreSettlementsWithCustomers", New TypeDescription("Boolean"));
	TableOfPaymentObjects.Indexes.Add("TheseAreSettlementsWithCustomers, PaymentObject, ARAPObject");
	
	SelectionParametersInTableOfPaymentObjects = New Structure;
	SelectionParametersInTableOfPaymentObjects.Insert("PaymentObject", Undefined);
	SelectionParametersInTableOfPaymentObjects.Insert("ARAPObject", Catalogs.ARAPObjects.EmptyRef());
	SelectionParametersInTableOfPaymentObjects.Insert("TheseAreSettlementsWithCustomers", False);
	
	ItIsNecessaryToSupplementTableOfChanges = True;
	If Parameters <> Undefined Then
		ItIsNecessaryToSupplementTableOfChanges = Parameters.SupplementDistributeReceivers;
	EndIf;
	RegisterTasksByReceivers = False;
	If Parameters <> Undefined Then
		Parameters.Property("RegisterTasksByReceivers", RegisterTasksByReceivers);
	EndIf;
	
	If ItIsNecessaryToSupplementTableOfChanges Then
		For Each TableRow In DataForProcessing_ Do
			TableRow.ByDataOfSourceARAPObject = TableRow.Priority = 2;
		EndDo;
	EndIf;
	
	DistributionParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
	DistributionParameters.SupplementDistributeReceivers = ItIsNecessaryToSupplementTableOfChanges;
	DistributionParameters.RegisterTasksByReceivers = RegisterTasksByReceivers;
	
	BeginTransaction();
	
	Try
		
		OnlineARAPAccountingServer.FillInOperationalARAPAccountsAccordingToTable(DistributionParameters, DataForProcessing_);
		
		For Each Record In DataForProcessing_ Do
			
			OnlineARAPAccountingServer.MarkTaskCompletion(Record,"Document");
			
			If ValueIsFilled(Record.Object) Then
				
				FillPropertyValues(SelectionParametersInTableOfPaymentObjects, Record);
				SelectionParametersInTableOfPaymentObjects.PaymentObject = Record.Object;
				
				FoundRows = TableOfPaymentObjects.FindRows(SelectionParametersInTableOfPaymentObjects);
				
				If FoundRows.Count() = 0 Then
					NwRw = TableOfPaymentObjects.Add();
					NwRw.TheseAreSettlementsWithCustomers = Record.TheseAreSettlementsWithCustomers;
					NwRw.ARAPObject = Record.ARAPObject;
					NwRw.PaymentObject = Record.Object;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		ErrorText = DetailErrorDescription(ErrorInfo());
		Raise ErrorText;
		
	EndTry;
	
	// Distributed calculation data is used to determine the States of orders
	ReflectOrderStates(DataForProcessing_);
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithCustomers(
				TableOfPaymentObjects.Copy(New Structure("TheseAreSettlementsWithCustomers", True)));
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithSuppliers(
				TableOfPaymentObjects.Copy(New Structure("TheseAreSettlementsWithCustomers", False)));
EndProcedure

// Clears operational settlement registers and deletes service registrars.
// 
// Parameters:
//  ARAPObject - CatalogRef.ARAPObjects - The object of the calculations
//  AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting analytics by partners
Procedure ClearSettlementRegistersAndDeleteServiceRecorders(ARAPObject = Undefined, AccountingDimensionByPartners = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("ARAPObject", ARAPObject);
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	Query.Text = "SELECT
	|	ARAPAccountingRecorder.Ref AS Ref,
	|	ARAPAccountingRecorder.PaymentType_ AS PaymentType_
	|FROM
	|	Document.ARAPAccountingRecorder AS ARAPAccountingRecorder
	|WHERE
	|	ARAPAccountingRecorder.ARAPObject = &ARAPObject
	|	AND ARAPAccountingRecorder.AccountingDimensionByPartners = &AccountingDimensionByPartners";
	
	If ARAPObject = Undefined Then
		Query.Text = StrReplace(Query.Text, "ARAPAccountingRecorder.ARAPObject = &ARAPObject", "True");
	EndIf;

	If AccountingDimensionByPartners = Undefined Then
		Query.Text = StrReplace(Query.Text,
			"ARAPAccountingRecorder.AccountingDimensionByPartners = &AccountingDimensionByPartners", "True");
	EndIf;
	
	CalculationLoggerTable = Query.Execute().Unload();
	
	For Each CurrentDocument In CalculationLoggerTable Do

		If CurrentDocument.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			ClearRegisterOfMutualSettlementsOnDocument(CurrentDocument.Ref, "CustomersARAPAccountingByDueDates");
			ClearRegisterOfMutualSettlementsOnDocument(CurrentDocument.Ref, "CustomersARAPAccountingCashFlowPlan");
			ClearRegisterOfMutualSettlementsOnDocument(CurrentDocument.Ref, "CustomersARAPAccountingPlannedShipments");
		Else
			ClearRegisterOfMutualSettlementsOnDocument(CurrentDocument.Ref, "VendorsARAPAccountingByDueDates");
			ClearRegisterOfMutualSettlementsOnDocument(CurrentDocument.Ref, "VendorsARAPAccountingCashFlowPlan");
			ClearRegisterOfMutualSettlementsOnDocument(CurrentDocument.Ref, "VendorsARAPAccountingPlannedDeliveries");
		EndIf;

	EndDo;
	
	ListOfDocumentsToBeProcessed = CommonClientServer.CollapseArray(
		CalculationLoggerTable.UnloadColumn("Ref"));
		
	If ListOfDocumentsToBeProcessed.Count() > 0 Then

		Parameters = New Structure;
		Parameters.Insert("DataForProcessing_", ListOfDocumentsToBeProcessed);

		RemoveServiceLoggers(Parameters);

	EndIf;
	
EndProcedure

// Clears registers of AR/AP accounts.
// 
// Parameters:
//  OnlyPlannedCalculations - Boolean - No need to clean up the actual calculations.
Procedure ClearSettlementRegisters(OnlyPlannedCalculations = False) Export
	
	DescriptionOfCleaningMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccounting.ClearingRegisters.Multithreaded");
	If Common.FileInfobase() Then
		DescriptionOfCleaningMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccounting.ClearingRegisters.FileInforbaseFind");
	EndIf;
	
	ProcessedItemsTotal = 0;
	If OnlyPlannedCalculations Then
		ClearRegister("CustomersARAPAccountingCashFlowPlan", ProcessedItemsTotal);
		ClearRegister("CustomersARAPAccountingPlannedShipments", ProcessedItemsTotal);
		ClearRegister("VendorsARAPAccountingCashFlowPlan", ProcessedItemsTotal);
		ClearRegister("VendorsARAPAccountingPlannedDeliveries", ProcessedItemsTotal);
	Else
		MeasurementDescriptionDisablingTotals = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccounting.ClearingRegisters.DisablingTotals");
		DisableCalculationRegisterTotals();
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDescriptionDisablingTotals, 1);
		
		DescriptionOfMeasurementRemovalOfRegisteredRecords = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccounting.ClearingRegisters.RegisterRecordsDeletion");
		ClearRegister("CustomersARAPAccountingByDueDates", ProcessedItemsTotal);
		ClearRegister("CustomersARAPAccountingCashFlowPlan", ProcessedItemsTotal);
		ClearRegister("CustomersARAPAccountingPlannedShipments", ProcessedItemsTotal);
		ClearRegister("VendorsARAPAccountingByDueDates", ProcessedItemsTotal);
		ClearRegister("VendorsARAPAccountingCashFlowPlan", ProcessedItemsTotal);
		ClearRegister("VendorsARAPAccountingPlannedDeliveries", ProcessedItemsTotal);
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(DescriptionOfMeasurementRemovalOfRegisteredRecords, ProcessedItemsTotal / 100);
		
		MeasurementDescriptionIncludeTotals = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ARAPAccounting.ClearingRegisters.InclusionOfTotals");
		IncludeCalculationRegisterTotals();
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDescriptionIncludeTotals, 1);
		
		RemoveServiceLoggersMultithreaded();
		RemoveSystemRegisterAdjustments(Date(1,1,1));
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(DescriptionOfCleaningMeasurement, ProcessedItemsTotal / 100);
	EndIf;
	
	MessageText = NStr("ru = 'Завершена очистка новых регистров';
						|vi = 'New registers are cleared';
						|en = 'New registers are cleared'; fa = 'New registers are cleared';
						|it = 'New registers are cleared';
						|pl = 'New registers are cleared';
						|tr = 'Yeni kayıt tablolarının temizlenmesi tamamlandı'");
	WriteLogEvent(EventLogEventName(),
		EventLogLevel.Information,,,MessageText);
		
EndProcedure

//Clears the passed calculation register.
Procedure ClearRegister(RegisterName, ProcessedItemsTotal = 0) Export
	
	If Not Common.FileInfobase() Then
		RecordsCount = PerformRegisterCleanupMultithreaded(RegisterName);
		ProcessedItemsTotal = ProcessedItemsTotal + RecordsCount;
		
	Else
		QueryText = "
		|SELECT DISTINCT
		|	Calculations.Recorder AS Recorder
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
		|WHERE
		|	Calculations.Recorder REFS Document.ARAPAccountingRecorder";
		
		QueryText = StrReplace(QueryText, "AccumulationRegister.CustomersARAPAccountingByDueDates", "AccumulationRegister." + RegisterName);
		Query = New Query(QueryText);
		Selection = Query.Execute().Select();
		ProcessedItemsTotal = ProcessedItemsTotal + Selection.Count();
		While Selection.Next() Do
			RecordSet = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.DataExchange.Load = True;
			RecordSet.Write();
		EndDo;
	EndIf;
	
	MessageText = NStr("ru = 'Завершена очистка регистра';
						|vi = 'The register is cleared';
						|en = 'The register is cleared'; fa = 'The register is cleared';
						|it = 'The register is cleared';
						|pl = 'The register is cleared';
						|tr = 'Kayıt tablosunun temizlenmesi tamamlandı'") + ": " + RegisterName;
	WriteLogEvent(EventLogEventName(),
		EventLogLevel.Information,,,MessageText);
	
EndProcedure

//Clears the transferred register of calculations by the registrar
Procedure ClearRegisterOfMutualSettlementsOnDocument(Recorder, RegisterName) Export
	
	RecordSet = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet
	RecordSet.Filter.Recorder.Set(Recorder);
	RecordSet.DataExchange.Load = True;
	RecordSet.Write();

EndProcedure

//Clears the passed register of the calculations in multiple threads.
// 
// Parameters:
// 	RegisterName - String - Name of the accumulation register to clear
// Returns:
// 	Number - Number of registrars processed
//
Function PerformRegisterCleanupMultithreaded(RegisterName) Export
	
	Threads = New Array;
	FreeThreadsCount = 1; // The number of streams distributed by the accounts(); before correction 10231410
	NumberOfObjectsToCleanUp = ChunkSizeOfProcessingInSingleThread() * FreeThreadsCount;
	// to avoid deadlocks when writing the date of the minimum totals to the AccumRegOpt table
	First = DataToCleanUp(RegisterName, Undefined, 1);
	If First.Next() Then
		RecordSet = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet
		RecordSet.Filter.Recorder.Set(First.Recorder);
		RecordSet.DataExchange.Load = True;
		RecordSet.Write();
	EndIf;
	PointInTime = Undefined;
	TestLaunch = 3;
	NumberOfRecordsProcessed = 0;
	While NumberOfObjectsToCleanUp > 0 And TestLaunch > 0 Do
		
		If FreeThreadsCount > 0 Then
			
			SelectionSize = ChunkSizeOfProcessingInSingleThread() * FreeThreadsCount;
			SamplingForCleaning = DataToCleanUp(RegisterName, PointInTime, SelectionSize);
			NumberOfRecordsProcessed = NumberOfRecordsProcessed + SamplingForCleaning.Count();
			NumberOfObjectsToCleanUp = SamplingForCleaning.Count();
			If NumberOfObjectsToCleanUp > 0 Then
				
				StreamData = New Array;
				While SamplingForCleaning.Next() Do
					
					PointInTime = SamplingForCleaning.PointInTime;
					StreamData.Add(SamplingForCleaning.Recorder);
					If StreamData.Count() = ChunkSizeOfProcessingInSingleThread() Then
						Stream = NewFlowDescription("OnlineARAPAccountingServer.DeleteDocumentEntries");
						Stream.JobDescription = NStr("vi = 'Xóa biểu ghi';
													|ru = 'Очистка регистра';
													|en = 'Clearing register'; fa = 'Clearing register';
													|it = 'Cancellazione del registro';
													|pl = 'Oczyszczenie rejestru';
													|tr = 'Sicil temizleme'") + " " + RegisterName;
						Stream.ProcedureParameters.Insert("DataForProcessing_", StreamData);
						Stream.ProcedureParameters.Insert("RegisterName", RegisterName);
						StartProcessingInBackground(Stream);
						Threads.Add(Stream);
						StreamData = New Array;
					EndIf;
					
				EndDo;
				
				If StreamData.Count() > 0 Then
					Stream = NewFlowDescription("OnlineARAPAccountingServer.DeleteDocumentEntries");
					Stream.JobDescription = NStr("vi = 'Xóa biểu ghi';
												|ru = 'Очистка регистра';
												|en = 'Clearing register'; fa = 'Clearing register';
												|it = 'Cancellazione del registro';
												|pl = 'Oczyszczenie rejestru';
												|tr = 'Sicil temizleme'") + " " + RegisterName;
					Stream.ProcedureParameters.Insert("DataForProcessing_", StreamData);
					Stream.ProcedureParameters.Insert("RegisterName", RegisterName);
					StartProcessingInBackground(Stream);
					Threads.Add(Stream);
				EndIf;
				
			ElsIf TestLaunch > 0 Then
				PointInTime = Undefined;
				TestLaunch = TestLaunch - 1;
			EndIf;
			
		EndIf;
		
		WaitForThreadCompletion(Stream);
		
		StopThreadsWithCompletedBackgroundJobs(Threads);
		
		NumberOfAvailableStreams = 1; // The number of streams distributed by the accounts(); before correction 10231410
		FreeThreadsCount = Max(NumberOfAvailableStreams - Threads.Count(), 0);
		
	EndDo;
	
	WaitForAllThreadsCompletion(Threads);
	
	Return NumberOfRecordsProcessed;
	
EndFunction

Procedure RemoveServiceLoggersMultithreaded()
	
	QueryText = 
	"SELECT
	|	ARAPAccountingRecorder.Ref AS Ref
	|FROM
	|	Document.ARAPAccountingRecorder AS ARAPAccountingRecorder";
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	
	NumberOfRecordsProcessed = Selection.Count();
	SingleStreamPortionSize = Int(Selection.Count()/NumberOfSettlementsAllocationThreads()) + 1;
	Threads = New Array;
	StreamData = New Array;
	While Selection.Next() Do
		StreamData.Add(Selection.Ref);
		If StreamData.Count() = SingleStreamPortionSize Then
			Stream = NewFlowDescription("OnlineARAPAccountingServer.RemoveServiceLoggers");
			Stream.JobDescription = NStr("vi = 'Xóa nguồn ghi hệ thống';
										|ru = 'Удаление служебных регистраторов';
										|en = 'Deleting internal recorders'; fa = 'Deleting internal recorders';
										|it = 'Eliminazione dei registratori di servizio';
										|pl = 'Usunięcie rejestratorów służbowych';
										|tr = 'Özel sicillerin silinmesi'");
			Stream.ProcedureParameters.Insert("DataForProcessing_", StreamData);
			StartProcessingInBackground(Stream);
			Threads.Add(Stream);
			StreamData = New Array;
		EndIf;
	EndDo;
	
	If StreamData.Count() > 0 Then
		Stream = NewFlowDescription("OnlineARAPAccountingServer.RemoveServiceLoggers");
		Stream.JobDescription = NStr("vi = 'Xóa nguồn ghi hệ thống';
									|ru = 'Удаление служебных регистраторов';
									|en = 'Deleting internal recorders'; fa = 'Deleting internal recorders';
									|it = 'Eliminazione dei registratori di servizio';
									|pl = 'Usunięcie rejestratorów służbowych';
									|tr = 'Özel sicillerin silinmesi'");
		Stream.ProcedureParameters.Insert("DataForProcessing_", StreamData);
		StartProcessingInBackground(Stream);
		Threads.Add(Stream);
		StreamData = New Array;
	EndIf;
	
	WaitForAllThreadsCompletion(Threads,,NumberOfRecordsProcessed);
	
EndProcedure

Function DataToCleanUp(RegisterName, PointInTime, PortionSize = 0)
	
	QueryText = 
	"SELECT TOP 1000
	|	Calculations.PointInTime AS PointInTime,
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.Recorder REFS Document.ARAPAccountingRecorder
	|	AND (&NoFilter OR Calculations.PointInTime > &PointInTime)
	|GROUP BY
	|	Calculations.PointInTime,
	|	Calculations.Recorder
	|ORDER BY
	|	Calculations.PointInTime"; // sort only in ascending order of the period to avoid deadlocks when writing the date of the minimum totals to the AccumRegOpt table 
	QueryText = StrReplace(QueryText, "AccumulationRegister.CustomersARAPAccountingByDueDates", "AccumulationRegister."+RegisterName);
	If PortionSize > 0 Then
		QueryText = StrReplace(QueryText, "1000", Format(PortionSize, "NZ=0; NG=0"));
	EndIf;
	Query = New Query(QueryText);
	Query.SetParameter("PointInTime", PointInTime);
	If PointInTime = Undefined Then
		Query.SetParameter("PointInTime", New PointInTime('00010101'));
	EndIf;
	Query.SetParameter("NoFilter", PointInTime = Undefined);
	Selection = Query.Execute().Select();
	Return Selection;
	
EndFunction

//Filling in the new registers all objects in the calculations.
// 
// Parameters:
//  OnlyPlannedCalculations - Boolean - Only Planned Calculations
Procedure FillInAllCalculations(OnlyPlannedCalculations = False) Export
	
	ClearSettlementRegisters(OnlyPlannedCalculations);
	
	DistributionParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
	DistributionParameters.SupplementDistributeReceivers = True;
	DistributionParameters.OnlyPlannedCalculations = OnlyPlannedCalculations;
	
	OnlineARAPAccountingServer.FillInOperationalARAPAccountsAccordingToTable(DistributionParameters,GetAllObjects());

EndProcedure

Procedure DeleteDocumentEntries(Parameters, ResultAddress = Undefined) Export
	
	DataForProcessing_ = Parameters.DataForProcessing_;
	RegisterName = Parameters.RegisterName;
	NumberOfRegistrars = DataForProcessing_.Count();
	For Each Recorder In DataForProcessing_ Do
		RecordSet = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet
		RecordSet.Filter.Recorder.Set(Recorder);
		RecordSet.DataExchange.Load = True;
		RecordSet.Write();
	EndDo;
	
	If ResultAddress <> Undefined Then
		Result = New Structure("NumberOfRecordsProcessed", NumberOfRegistrars);
		PutToTempStorage(Result, ResultAddress);
	EndIf;
	
EndProcedure

Procedure RemoveServiceLoggers(Parameters, ResultAddress = Undefined) Export
	
	DataForProcessing_ = Parameters.DataForProcessing_;
	NumberOfRegistrars = DataForProcessing_.Count();
	For Each Recorder In DataForProcessing_ Do
		
		DocumentObject = Recorder.GetObject();
		DocumentObject.DataExchange.Load = True;
		DocumentObject.Delete();
		
	EndDo;
	
	If ResultAddress <> Undefined Then
		Result = New Structure("NumberOfRecordsProcessed", NumberOfRegistrars);
		PutToTempStorage(Result, ResultAddress);
	EndIf;
	
EndProcedure

#EndRegion

#Region ErrorCorrection

// Generates the query text to search for incorrect data in calculation registers. 
// 
// Parameters:
// 	TTName - String - Name of the temporary table to place the result in
// 	NoManualAdjustments - Boolean - the need to exclude from the result of the request the Calculation Analysts for partners 
// 	                                  and Settlement Objects for which manual register adjustments have been introduced.
// Returns:
// 	String - Query text
Function TextOfRequestForIncorrectBalancesOfSettlementsByTerms(TTName = "", NoManualAdjustments = True) Export
	
	QueryTextArray = New Array;
	
	QueryText = "
		|SELECT
		|	Keys.Ref      AS AccountingDimensionByPartners,
		|	Keys.Organization AS Organization
		|INTO TTAnalytics_
		|FROM
		|	Catalog.DimensionKeysOfAccountingByPartners AS Keys
		|WHERE
		|	Keys.Organization IN (&CompanyArray)
		|INDEX BY
		|	AccountingDimensionByPartners";
	QueryTextArray.Add(QueryText);
	
	QueryText = "
		|SELECT
		|	MIN(NestedQuery.Period) AS Period
		|INTO PeriodForEnteringBalances
		|FROM (
		|	SELECT
		|		Return.Date AS Period
		|	FROM
		|		Document.OBEntryARAP AS Return
		|	WHERE
		|		Return.Posted
		|	) AS NestedQuery
		|;
		|
		|SELECT
		|	NestedQuery.PaymentType_                           AS PaymentType_,
		|	NestedQuery.AccountingDimensionByPartners             AS AccountingDimensionByPartners,
		|	NestedQuery.ARAPObject                        AS ARAPObject,
		|	NestedQuery.Currency                                AS Currency,
		|	SUM(NestedQuery.Sum)                          AS Sum,
		|	SUM(NestedQuery.AmountByTimeFrame)                  AS AmountByTimeFrame
		|INTO TTBalance
		|FROM (SELECT
		|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
		|		CustomersARAPAccounting.AccountingDimensionByPartners                     AS AccountingDimensionByPartners,
		|		CustomersARAPAccounting.ARAPObject                                AS ARAPObject,
		|		CustomersARAPAccounting.Currency                                        AS Currency,
		|		
		|		CustomersARAPAccounting.SumBalance                                  AS Sum,
		|		0                                                               AS AmountByTimeFrame
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS CustomersARAPAccounting
		|	WHERE
		|		CustomersARAPAccounting.SumBalance <> 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)                     AS PaymentType_,
		|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners                                 AS AccountingDimensionByPartners,
		|		CustomersARAPAccountingByDueDates.ARAPObject                                            AS ARAPObject,
		|		CustomersARAPAccountingByDueDates.Currency                                                    AS Currency,
		|		
		|		0                                                                                   AS Sum,
		|		CustomersARAPAccountingByDueDates.DebtBalance - CustomersARAPAccountingByDueDates.PrepaymentBalance AS AmountByTimeFrame
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS CustomersARAPAccountingByDueDates
		|	WHERE
		|		CustomersARAPAccountingByDueDates.DebtBalance <> 0
		|		OR CustomersARAPAccountingByDueDates.PrepaymentBalance <> 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
		|		VendorsARAPAccounting.AccountingDimensionByPartners                     AS AccountingDimensionByPartners,
		|		VendorsARAPAccounting.ARAPObject                                AS ARAPObject,
		|		VendorsARAPAccounting.Currency                                        AS Currency,
		|		
		|		VendorsARAPAccounting.SumBalance                                  AS Sum,
		|		0                                                                  AS AmountByTimeFrame
		|	FROM
		|		AccumulationRegister.VendorsARAPAccounting.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS VendorsARAPAccounting
		|	WHERE
		|		VendorsARAPAccounting.SumBalance <> 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)                        AS PaymentType_,
		|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners                                    AS AccountingDimensionByPartners,
		|		VendorsARAPAccountingByDueDates.ARAPObject                                               AS ARAPObject,
		|		VendorsARAPAccountingByDueDates.Currency                                                       AS Currency,
		|		
		|		0                                                                                         AS Sum,
		|		VendorsARAPAccountingByDueDates.PrepaymentBalance - VendorsARAPAccountingByDueDates.DebtBalance AS AmountByTimeFrame
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS VendorsARAPAccountingByDueDates
		|	WHERE
		|		VendorsARAPAccountingByDueDates.DebtBalance <> 0
		|		OR VendorsARAPAccountingByDueDates.PrepaymentBalance <> 0) AS NestedQuery
		|	LEFT JOIN PeriodForEnteringBalances AS PeriodForEnteringBalances
		|		ON TRUE
		|WHERE
		|	&BegOfMonth > ISNULL(PeriodForEnteringBalances.Period, DATETIME(1,1,1))
		|GROUP BY 
		|	NestedQuery.PaymentType_,
		|	NestedQuery.AccountingDimensionByPartners,
		|	NestedQuery.ARAPObject,
		|	NestedQuery.Currency
		|HAVING
		|	SUM(NestedQuery.AmountByTimeFrame) <> SUM(NestedQuery.Sum)
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)    AS PaymentType_,
		|	CalculationsByTerms.AccountingDimensionByPartners                          AS AccountingDimensionByPartners,
		|	CalculationsByTerms.ARAPObject                                     AS ARAPObject,
		|	CalculationsByTerms.Currency                                             AS Currency,
		|	CASE WHEN NOT CalculationsByTerms.ARAPDocument IS NULL
		|		AND NOT CalculationsByTerms.PlannedRepaymentDate IS NULL
		|		AND NOT CalculationsByTerms.OccurrenceDate IS NULL
		|		THEN 0
		|		ELSE 0 
		|	END                                                              AS Sum,
		|	CalculationsByTerms.DebtBalance + CalculationsByTerms.PrepaymentBalance    AS AmountByTimeFrame
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS CalculationsByTerms
		|WHERE
		|	CalculationsByTerms.DebtBalance < 0
		|	OR CalculationsByTerms.PrepaymentBalance < 0
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
		|	CalculationsByTerms.AccountingDimensionByPartners                          AS AccountingDimensionByPartners,
		|	CalculationsByTerms.ARAPObject                                     AS ARAPObject,
		|	CalculationsByTerms.Currency                                             AS Currency,
		|	CASE WHEN NOT CalculationsByTerms.ARAPDocument IS NULL
		|		AND NOT CalculationsByTerms.PlannedRepaymentDate IS NULL
		|		AND NOT CalculationsByTerms.OccurrenceDate IS NULL
		|		THEN 0
		|		ELSE 0 
		|	END                                                              AS Sum,
		|	CalculationsByTerms.DebtBalance + CalculationsByTerms.PrepaymentBalance    AS AmountByTimeFrame
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS CalculationsByTerms
		|WHERE
		|	CalculationsByTerms.DebtBalance < 0
		|	OR CalculationsByTerms.PrepaymentBalance < 0";
	If Not NoManualAdjustments Then
		QueryText = StrReplace(QueryText, "&BegOfMonth", "&BeginOfPeriod");
	EndIf;
	QueryTextArray.Add(QueryText);
	
	QueryText = "DROP PeriodForEnteringBalances";
	QueryTextArray.Add(QueryText);
	
	QueryText = TextOfRequestTTManualAdjustments();
	If Not NoManualAdjustments Then
		QueryText = StrReplace(QueryText, "&BegOfMonth", "&BeginOfPeriod");
	EndIf;
	QueryTextArray.Add(QueryText);
	
	If NoManualAdjustments Then
		QueryText = "
			|SELECT DISTINCT
			|	Dimension.Organization             AS Organization,
			|	Balance.PaymentType_               AS PaymentType_,
			|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	Balance.ARAPObject            AS ARAPObject,
			|	Balance.Currency                    AS Currency
			|INTO TTName
			|FROM TTBalance AS Balance
			|	INNER JOIN TTAnalytics_ AS Dimension
			|		ON Dimension.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
			|WHERE
			|	NOT (Balance.AccountingDimensionByPartners, Balance.ARAPObject) IN
			|				(SELECT
			|					TTManualAdjustments.AccountingDimensionByPartners,
			|					TTManualAdjustments.ARAPObject
			|				FROM
			|					TTManualAdjustments)
			|	AND NOT Balance.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)";
	Else
		QueryText = "
			|SELECT DISTINCT
			|	Dimension.Organization             AS Organization,
			|	Balance.PaymentType_               AS PaymentType_,
			|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	Balance.ARAPObject            AS ARAPObject,
			|	Balance.Currency                    AS Currency,
			|	TTManualAdjustments.Recorder AS ManualAdjustment
			|INTO TTName
			|FROM
			|	TTBalance AS Balance
			|		INNER JOIN TTAnalytics_ AS Dimension
			|		ON (Dimension.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners)
			|		INNER JOIN TTManualAdjustments AS TTManualAdjustments
			|		ON Balance.AccountingDimensionByPartners = TTManualAdjustments.AccountingDimensionByPartners
			|			AND Balance.ARAPObject = TTManualAdjustments.ARAPObject
			|WHERE
			|	&PeriodInRecalculationRange";
		
	EndIf;
	
	If ValueIsFilled(TTName) Then
		QueryText = StrReplace(QueryText,"INTO TTName","INTO "+TTName);
	Else
		QueryText = StrReplace(QueryText,"INTO TTName","");
	EndIf;
	
	QueryTextArray.Add(QueryText);
	
	QueryText = StrConcat(QueryTextArray, ";");
	
	Return QueryText;
	
EndFunction

// Generates a text query to search for records with a detailed balance calculation in the registers. 
// 
// Parameters:
// 	TTName - String - Name of the temporary table to place the result in
// 	NoManualAdjustments - Boolean - the need to exclude Partner Settlement Analysts from the query result 
// Returns:
// 	String - Query text
Function QueryTextDetailedBalance(TTName = "", NoManualAdjustments = True) Export
	
	QueryTextArray = New Array;
	
	QueryText = "
		|SELECT
		|	Keys.Ref      AS AccountingDimensionByPartners,
		|	Keys.Organization AS Organization
		|INTO TTAnalytics_
		|FROM
		|	Catalog.DimensionKeysOfAccountingByPartners AS Keys
		|WHERE
		|	Keys.Organization IN (&CompanyArray)
		|INDEX BY
		|	AccountingDimensionByPartners";
	QueryTextArray.Add(QueryText);
	
	QueryText = "
		|SELECT
		|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
		|	CustomersARAPAccountingBalance.AccountingDimensionByPartners              AS AccountingDimensionByPartners,
		|	CustomersARAPAccountingBalance.ARAPObject                         AS ARAPObject,
		|	CustomersARAPAccountingBalance.Currency                                 AS Currency,
		|	CustomersARAPAccountingBalance.DebtBalance                            AS DebtBalance,
		|	CustomersARAPAccountingBalance.PrepaymentBalance                      AS PrepaymentBalance
		|INTO TTBalance_
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS CustomersARAPAccountingBalance
		|WHERE
		|	CustomersARAPAccountingBalance.DebtBalance > 0 
		|	AND CustomersARAPAccountingBalance.PrepaymentBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
		|	VendorsARAPAccountingBalance.AccountingDimensionByPartners              AS AccountingDimensionByPartners,
		|	VendorsARAPAccountingBalance.ARAPObject                         AS ARAPObject,
		|	VendorsARAPAccountingBalance.Currency                                 AS Currency,
		|	VendorsARAPAccountingBalance.DebtBalance                            AS DebtBalance,
		|	VendorsARAPAccountingBalance.PrepaymentBalance                      AS PrepaymentBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&BegOfMonth, AccountingDimensionByPartners IN
		|			(SELECT
		|				TTAnalytics_.AccountingDimensionByPartners
		|			FROM
		|				TTAnalytics_ AS TTAnalytics_)) AS VendorsARAPAccountingBalance
		|WHERE
		|	VendorsARAPAccountingBalance.DebtBalance > 0 
		|	AND VendorsARAPAccountingBalance.PrepaymentBalance > 0";
	If Not NoManualAdjustments Then
		QueryText = StrReplace(QueryText, "&BegOfMonth", "&BeginOfPeriod");
	EndIf;
	QueryTextArray.Add(QueryText);
	
	QueryText = TextOfRequestTTManualAdjustments();
	If Not NoManualAdjustments Then
		QueryText = StrReplace(QueryText, "&BegOfMonth", "&BeginOfPeriod");
	EndIf;
	QueryTextArray.Add(QueryText);
	
	If NoManualAdjustments Then
		QueryText = "
			|SELECT
			|	Dimension.Organization             AS Organization,
			|	Balance_.PaymentType_                AS PaymentType_,
			|	Balance_.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
			|	Balance_.ARAPObject             AS ARAPObject,
			|	Balance_.Currency                     AS Currency,
			|	Balance_.DebtBalance                AS DebtBalance,
			|	Balance_.PrepaymentBalance          AS PrepaymentBalance
			|INTO TTName
			|FROM TTBalance_ AS Balance_
			|	INNER JOIN TTAnalytics_ AS Dimension
			|		ON Dimension.AccountingDimensionByPartners = Balance_.AccountingDimensionByPartners
			|WHERE
			|	NOT (Balance_.AccountingDimensionByPartners, Balance_.ARAPObject) IN
			|				(SELECT
			|					TTManualAdjustments.AccountingDimensionByPartners,
			|					TTManualAdjustments.ARAPObject
			|				FROM
			|					TTManualAdjustments)
			|	AND NOT Balance_.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)";
	Else
		QueryText = "
			|SELECT
			|	Dimension.Organization             AS Organization,
			|	Balance_.PaymentType_                AS PaymentType_,
			|	Balance_.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
			|	Balance_.ARAPObject             AS ARAPObject,
			|	Balance_.Currency                     AS Currency,
			|	Balance_.DebtBalance                AS DebtBalance,
			|	Balance_.PrepaymentBalance          AS PrepaymentBalance,
			|	TTManualAdjustments.Recorder AS ManualAdjustment
			|INTO TTName
			|FROM
			|	TTBalance_ AS Balance_
			|		INNER JOIN TTAnalytics_ AS Dimension
			|		ON (Dimension.AccountingDimensionByPartners = Balance_.AccountingDimensionByPartners)
			|		INNER JOIN TTManualAdjustments AS TTManualAdjustments
			|		ON Balance_.AccountingDimensionByPartners = TTManualAdjustments.AccountingDimensionByPartners
			|			AND Balance_.ARAPObject = TTManualAdjustments.ARAPObject
			|WHERE
			|	&PeriodInRecalculationRange";
	EndIf;
	
	If TTName <> "" Then
		QueryText = StrReplace(QueryText,"INTO TTName","INTO "+TTName);
	Else
		QueryText = StrReplace(QueryText,"INTO TTName","");
	EndIf;
	
	QueryTextArray.Add(QueryText);
	
	QueryText = StrConcat(QueryTextArray, ";");
	
	Return QueryText;
	
EndFunction

// Correction of settlement balances
// 
// Parameters:
// 	Period - Date - The verification period, at the beginning of the month of the period, the balances will be checked, 
//		if they are incorrect, an adjustment will be created for the end of the previous month.
//		If the balances are in order at the beginning of the period, but not at the beginning of the next month, then a partial recalculation of the calculations will be launched.
// 	CompanyArray - Array of CatalogRef.Companies - Array of organizations that need to correct settlement balances
Procedure FixSettlementBalances(Period, Val CompanyArray = Undefined) Export
	
	AdjustmentDate    = BegOfMonth(Period)-1; //For adjustments and movements
	AdjustmentProcedure = Format(AdjustmentDate,"DF=yyyyMMdd9HHmmss99"); //To request balance data.
	CalculationPeriod        = BegOfMonth(Period); //To compare the balances
	
	CompanyArray = ?(CompanyArray = Undefined,
							Catalogs.Companies.AvailableCompanies(),
							CompanyArray);
	
	TypesOfCalculations_ = New Array;
	TypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	TypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = TextOfRequestForIncorrectBalancesOfSettlementsByTerms();
	Query.SetParameter("BegOfMonth",       CalculationPeriod);
	Query.SetParameter("CompanyArray",  CompanyArray);
	Query.SetParameter("Order",            AdjustmentProcedure);
	
	//Remove the adjustments
	IncorrectBalances = Query.Execute().Unload();
	
	If IncorrectBalances.Count() > 0 Then
		ArrayOfOrganizationsToProcess = IncorrectBalances.Copy(,"Organization");
		ArrayOfOrganizationsToProcess.GroupBy("Organization");
		ArrayOfOrganizationsToProcess = ArrayOfOrganizationsToProcess.UnloadColumn("Organization");
		For Each Organization In ArrayOfOrganizationsToProcess Do
			RemoveSystemRegisterAdjustments(AdjustmentDate,Organization)
		EndDo;
		
		Query.Text = "DROP TTAnalytics_; DROP TTBalance; DROP TTManualAdjustments";
		Query.Execute();
		
		//Rereading the leftovers
		Query.Text = TextOfRequestForIncorrectBalancesOfSettlementsByTerms();
		
		IncorrectBalances = Query.Execute().Unload();
		IncorrectBalances.Indexes.Add("PaymentType_, Organization");
		TheStructureOfTheSearch = New Structure("PaymentType_, Organization");
		
		ArrayOfOrganizationsToProcess = IncorrectBalances.Copy(,"Organization");
		ArrayOfOrganizationsToProcess.GroupBy("Organization");
		ArrayOfOrganizationsToProcess = ArrayOfOrganizationsToProcess.UnloadColumn("Organization");
		
		For Each Organization In ArrayOfOrganizationsToProcess Do
			
			AdjustingObject = RegisterAdjustment(AdjustmentDate, Organization, Enums.RegisterAdjustmentOperations.CorrectionOfBalanceGapsInARAPAccounting);
			
			For Each PaymentType_ In TypesOfCalculations_ Do
				
				If PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
					RegisterRecords = AdjustingObject.RegisterRecords["CustomersARAPAccountingByDueDates"]; // AccumulationRegisterRecordSet
					TheseAreSettlementsWithCustomers = True;
				Else
					RegisterRecords = AdjustingObject.RegisterRecords["VendorsARAPAccountingByDueDates"]; // AccumulationRegisterRecordSet
					TheseAreSettlementsWithCustomers = False;
				EndIf;
				
				TheStructureOfTheSearch.PaymentType_ = PaymentType_;
				TheStructureOfTheSearch.Organization = Organization;
				RecordsOfIncorrectBalances = IncorrectBalances.FindRows(TheStructureOfTheSearch);
				
				For Each RecordingIncorrectBalances In RecordsOfIncorrectBalances Do
					
					//Calculate the correct balances.
					
					CalculatedRegisteredRecords = New Structure();
					DistributionParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
					DistributionParameters.RecordChanges_              = False;
					DistributionParameters.Insert("CalculatedRegisteredRecords",CalculatedRegisteredRecords);
					DistributionParameters.Insert("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
					
					TableToDistribution = OnlineARAPAccountingServer.TableToDistribution();
					TableEntry = TableToDistribution.Add();
					FillPropertyValues(TableEntry, RecordingIncorrectBalances);
					
					OnlineARAPAccountingServer.CompleteOperationalSettlements(DistributionParameters, TableToDistribution);
					
					//Let's compare with the balances before and calculate the adjustment records.
					
					Query.SetParameter("AccountingDimensionByPartners", RecordingIncorrectBalances.AccountingDimensionByPartners);
					Query.SetParameter("ARAPObject",            RecordingIncorrectBalances.ARAPObject);
					Query.SetParameter("Currency",                    RecordingIncorrectBalances.Currency);
					If PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
						Query.SetParameter("CalculationsByTerms",           CalculatedRegisteredRecords["CustomersARAPAccountingByDueDates"]);
					Else
						Query.SetParameter("CalculationsByTerms",           CalculatedRegisteredRecords["VendorsARAPAccountingByDueDates"]);
					EndIf;
					
					Query.Text = "
						//Recordings after
						|SELECT
						|	CalculationsForTermsAfter.Period                        AS Period,
						|	CalculationsForTermsAfter.RecordType                   AS RecordType,
						|	
						|	CalculationsForTermsAfter.AccountingDimensionByPartners     AS AccountingDimensionByPartners,
						|	CalculationsForTermsAfter.ARAPObject                AS ARAPObject,
						|	CalculationsForTermsAfter.Currency                        AS Currency,
						|	CalculationsForTermsAfter.ARAPDocument             AS ARAPDocument,
						|	CalculationsForTermsAfter.PlannedRepaymentDate        AS PlannedRepaymentDate,
						|	CalculationsForTermsAfter.OccurrenceDate             AS OccurrenceDate,
						|	
						|	CAST(CalculationsForTermsAfter.Prepayment AS NUMBER(31,2))     AS Prepayment,
						|	CAST(CalculationsForTermsAfter.PrepaymentLocal AS NUMBER(31,2)) AS PrepaymentLocal,
						|	CAST(CalculationsForTermsAfter.PrepaymentMan AS NUMBER(31,2))  AS PrepaymentMan,
						|	CAST(CalculationsForTermsAfter.Debt AS NUMBER(31,2))           AS Debt,
						|	CAST(CalculationsForTermsAfter.DebtLocal AS NUMBER(31,2))       AS DebtLocal,
						|	CAST(CalculationsForTermsAfter.ARAPMan AS NUMBER(31,2))        AS ARAPMan,
						|	
						|	CalculationsForTermsAfter.SettlementProcedure                 AS SettlementProcedure,
						|	CalculationsForTermsAfter.OperationProcedure               AS OperationProcedure,
						|	CalculationsForTermsAfter.LinkedDocument             AS LinkedDocument,
						|	CalculationsForTermsAfter.DocumentCurrency               AS DocumentCurrency,
						|	CalculationsForTermsAfter.CashFlowItem AS CashFlowItem
						|INTO CalculationsForTermsAfter
						|FROM &CalculationsByTerms AS CalculationsForTermsAfter
						|INDEX BY
						|	AccountingDimensionByPartners, ARAPObject, Currency, ARAPDocument
						|;
						//Discrepancies
						|SELECT
						|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
						|	NestedQuery.ARAPObject            AS ARAPObject,
						|	NestedQuery.Currency                    AS Currency,
						|	NestedQuery.ARAPDocument         AS ARAPDocument,
						|	NestedQuery.PlannedRepaymentDate    AS PlannedRepaymentDate,
						|	NestedQuery.OccurrenceDate         AS OccurrenceDate,
						|	SUM(NestedQuery.Prepayment)         AS Prepayment,
						|	SUM(NestedQuery.PrepaymentLocal)     AS PrepaymentLocal,
						|	SUM(NestedQuery.PrepaymentMan)      AS PrepaymentMan,
						|	SUM(NestedQuery.Debt)               AS Debt,
						|	SUM(NestedQuery.DebtLocal)           AS DebtLocal,
						|	SUM(NestedQuery.ARAPMan)            AS ARAPMan
						|INTO ChangesTable
						|FROM
						|	(SELECT
						|		CalculationsForTermsUpTo.AccountingDimensionByPartners AS AccountingDimensionByPartners,
						|		CalculationsForTermsUpTo.ARAPObject            AS ARAPObject,
						|		CalculationsForTermsUpTo.Currency                    AS Currency,
						|		CalculationsForTermsUpTo.ARAPDocument         AS ARAPDocument,
						|		CalculationsForTermsUpTo.PlannedRepaymentDate    AS PlannedRepaymentDate,
						|		CalculationsForTermsUpTo.OccurrenceDate         AS OccurrenceDate,
						|		-CalculationsForTermsUpTo.PrepaymentBalance        AS Prepayment,
						|		-CalculationsForTermsUpTo.PrepaymentLocalBalance    AS PrepaymentLocal,
						|		-CalculationsForTermsUpTo.PrepaymentManBalance     AS PrepaymentMan,
						|		-CalculationsForTermsUpTo.DebtBalance              AS Debt,
						|		-CalculationsForTermsUpTo.DebtLocalBalance          AS DebtLocal,
						|		-CalculationsForTermsUpTo.ARAPManBalance           AS ARAPMan
						|	FROM
						|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&BegOfMonth, 
						|			AccountingDimensionByPartners = &AccountingDimensionByPartners
						|			AND ARAPObject = &ARAPObject
						|			AND Currency = &Currency) AS CalculationsForTermsUpTo
						|		
						|	UNION ALL
						|	
						|	SELECT
						|		CalculationsForTermsAfter.AccountingDimensionByPartners AS AccountingDimensionByPartners,
						|		CalculationsForTermsAfter.ARAPObject            AS ARAPObject,
						|		CalculationsForTermsAfter.Currency                    AS Currency,
						|		CalculationsForTermsAfter.ARAPDocument         AS ARAPDocument,
						|		CalculationsForTermsAfter.PlannedRepaymentDate    AS PlannedRepaymentDate,
						|		CalculationsForTermsAfter.OccurrenceDate         AS OccurrenceDate,
						|		CASE WHEN CalculationsForTermsAfter.RecordType = VALUE(AccumulationRecordType.Expense) 
						|				THEN -CalculationsForTermsAfter.Prepayment
						|			ELSE CalculationsForTermsAfter.Prepayment
						|		END                                          AS Prepayment,
						|		CASE WHEN CalculationsForTermsAfter.RecordType = VALUE(AccumulationRecordType.Expense) 
						|				THEN -CalculationsForTermsAfter.PrepaymentLocal
						|			ELSE CalculationsForTermsAfter.PrepaymentLocal
						|		END                                          AS PrepaymentLocal,
						|		CASE WHEN CalculationsForTermsAfter.RecordType = VALUE(AccumulationRecordType.Expense) 
						|				THEN -CalculationsForTermsAfter.PrepaymentMan
						|			ELSE CalculationsForTermsAfter.PrepaymentMan
						|		END                                          AS PrepaymentMan,
						|		CASE WHEN CalculationsForTermsAfter.RecordType = VALUE(AccumulationRecordType.Expense) 
						|				THEN -CalculationsForTermsAfter.Debt
						|			ELSE CalculationsForTermsAfter.Debt
						|		END                                          AS Debt,
						|		CASE WHEN CalculationsForTermsAfter.RecordType = VALUE(AccumulationRecordType.Expense) 
						|				THEN -CalculationsForTermsAfter.DebtLocal
						|			ELSE CalculationsForTermsAfter.DebtLocal
						|		END                                          AS DebtLocal,
						|		CASE WHEN CalculationsForTermsAfter.RecordType = VALUE(AccumulationRecordType.Expense) 
						|				THEN -CalculationsForTermsAfter.ARAPMan
						|			ELSE CalculationsForTermsAfter.ARAPMan
						|		END                                          AS ARAPMan
						|	FROM
						|		CalculationsForTermsAfter AS CalculationsForTermsAfter
						|	WHERE
						|		CalculationsForTermsAfter.Period < &BegOfMonth) AS NestedQuery
						|GROUP BY
						|	NestedQuery.AccountingDimensionByPartners,
						|	NestedQuery.ARAPObject,
						|	NestedQuery.Currency,
						|	NestedQuery.ARAPDocument,
						|	NestedQuery.PlannedRepaymentDate,
						|	NestedQuery.OccurrenceDate
						|HAVING
						|	SUM(NestedQuery.Prepayment) <> 0 OR SUM(NestedQuery.Debt) <> 0
						|INDEX BY
						|	AccountingDimensionByPartners, ARAPObject, Currency, ARAPDocument
						|;
						|
						//Data for movements
						|SELECT
						|	VALUE(AccumulationRecordType.Receipt)                       AS RecordType,
						|	
						|	Changes.AccountingDimensionByPartners                          AS AccountingDimensionByPartners,
						|	Changes.ARAPObject                                     AS ARAPObject,
						|	Changes.Currency                                             AS Currency,
						|	Changes.ARAPDocument                                  AS ARAPDocument,
						|	Changes.PlannedRepaymentDate                             AS PlannedRepaymentDate,
						|	Changes.OccurrenceDate                                  AS OccurrenceDate,
						|	
						|	Changes.Prepayment                                         AS Prepayment,
						|	Changes.PrepaymentLocal                                     AS PrepaymentLocal,
						|	Changes.PrepaymentMan                                      AS PrepaymentMan,
						|	Changes.Debt                                               AS Debt,
						|	Changes.DebtLocal                                           AS DebtLocal,
						|	Changes.ARAPMan                                            AS ARAPMan,
						|	
						|	MIN(CalculationsForTermsAfter.SettlementProcedure)                  AS SettlementProcedure,
						|	MIN(CalculationsForTermsAfter.OperationProcedure)                AS OperationProcedure,
						|	MAX(CalculationsForTermsAfter.LinkedDocument)             AS LinkedDocument,
						|	MIN(CalculationsForTermsAfter.DocumentCurrency)                AS DocumentCurrency,
						|	MAX(CalculationsForTermsAfter.CashFlowItem) AS CashFlowItem,
						|	VALUE(Enum.BusinessTransactions.EmptyRef)    AS BusinessOperation
						|
						|FROM
						|	ChangesTable AS Changes
						|		LEFT JOIN CalculationsForTermsAfter AS CalculationsForTermsAfter
						|			ON CalculationsForTermsAfter.AccountingDimensionByPartners    = Changes.AccountingDimensionByPartners
						|				AND CalculationsForTermsAfter.ARAPObject            = Changes.ARAPObject
						|				AND CalculationsForTermsAfter.Currency                    = Changes.Currency
						|				AND CalculationsForTermsAfter.ARAPDocument         = Changes.ARAPDocument
						|WHERE
						|	Changes.Prepayment > 0 OR Changes.Debt > 0
						|GROUP BY
						|	Changes.AccountingDimensionByPartners,
						|	Changes.ARAPObject,
						|	Changes.Currency,
						|	Changes.ARAPDocument,
						|	Changes.PlannedRepaymentDate,
						|	Changes.OccurrenceDate,
						|	Changes.Prepayment,
						|	Changes.PrepaymentLocal,
						|	Changes.PrepaymentMan,
						|	Changes.Debt,
						|	Changes.DebtLocal,
						|	Changes.ARAPMan
						|	
						|UNION ALL
						|	
						|SELECT
						|	VALUE(AccumulationRecordType.Expense) AS RecordType,
						|	
						|	Changes.AccountingDimensionByPartners                       AS AccountingDimensionByPartners,
						|	Changes.ARAPObject                                  AS ARAPObject,
						|	Changes.Currency                                          AS Currency,
						|	Changes.ARAPDocument                               AS ARAPDocument,
						|	Changes.PlannedRepaymentDate                          AS PlannedRepaymentDate,
						|	Changes.OccurrenceDate                               AS OccurrenceDate,
						|	
						|	-Changes.Prepayment                                     AS Prepayment,
						|	-Changes.PrepaymentLocal                                 AS PrepaymentLocal,
						|	-Changes.PrepaymentMan                                  AS PrepaymentMan,
						|	-Changes.Debt                                           AS Debt,
						|	-Changes.DebtLocal                                       AS DebtLocal,
						|	-Changes.ARAPMan                                        AS ARAPMan,
						|	
						|	MIN(CalculationsForTermsUpTo.SettlementProcedure)                  AS SettlementProcedure,
						|	MIN(CalculationsForTermsUpTo.OperationProcedure)                AS OperationProcedure,
						|	MAX(CalculationsForTermsUpTo.LinkedDocument)             AS LinkedDocument,
						|	MIN(CalculationsForTermsUpTo.DocumentCurrency)                AS DocumentCurrency,
						|	MAX(CalculationsForTermsUpTo.CashFlowItem) AS CashFlowItem,
						|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation
						|
						|FROM
						|	ChangesTable AS Changes
						|		LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsForTermsUpTo
						|			ON CalculationsForTermsUpTo.AccountingDimensionByPartners    = Changes.AccountingDimensionByPartners
						|				AND CalculationsForTermsUpTo.ARAPObject            = Changes.ARAPObject
						|				AND CalculationsForTermsUpTo.Currency                    = Changes.Currency
						|				AND CalculationsForTermsUpTo.ARAPDocument         = Changes.ARAPDocument
						|				AND CalculationsForTermsUpTo.Period                    < &BegOfMonth
						|				AND CalculationsForTermsUpTo.Active
						|WHERE
						|	Changes.Prepayment < 0 OR Changes.Debt < 0
						|GROUP BY
						|	Changes.AccountingDimensionByPartners,
						|	Changes.ARAPObject,
						|	Changes.Currency,
						|	Changes.ARAPDocument,
						|	Changes.PlannedRepaymentDate,
						|	Changes.OccurrenceDate,
						|	-Changes.Prepayment,
						|	-Changes.PrepaymentLocal,
						|	-Changes.PrepaymentMan,
						|	-Changes.Debt,
						|	-Changes.DebtLocal,
						|	-Changes.ARAPMan";
						
						If PaymentType_ <> Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
							Query.Text = StrReplace(Query.Text,
								"AccumulationRegister.CustomersARAPAccountingByDueDates",
								"AccumulationRegister.VendorsARAPAccountingByDueDates");
						EndIf;
						
						Result = Query.Execute();
						Selection = Result.Select();
						
						Query.Text = "DROP CalculationsForTermsAfter; DROP ChangesTable";
						Query.Execute();
						
						While Selection.Next() Do
							
							NwRw = RegisterRecords.Add();
							FillPropertyValues(NwRw, Selection);
							
							NwRw.DocumentRecorder = AdjustingObject.Ref;
							NwRw.Period = AdjustmentDate;
							If Selection.RecordType = AccumulationRecordType.Receipt Then
								If Selection.Debt <> 0 Then
									NwRw.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease;
								Else
									NwRw.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease;
								EndIf;
							Else
								If Selection.Debt <> 0 Then
									NwRw.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;
								Else
									NwRw.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease;
								EndIf;
							EndIf;
							
						EndDo;
						
				EndDo;
				
				RegisterRecords.Write();
				
				TableToDistribution = OnlineARAPAccountingServer.TableToDistribution();
				DistributionParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
				DistributionParameters.Insert("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
				For Each RecordingIncorrectBalances In RecordsOfIncorrectBalances Do
					NwRw = TableToDistribution.Add();
					FillPropertyValues(NwRw, RecordingIncorrectBalances);
					NwRw.RecalculationStartDate = CalculationPeriod;
				EndDo;
				OnlineARAPAccountingServer.CompleteOperationalSettlements(DistributionParameters, TableToDistribution);
				
			EndDo;
			
			If AdjustingObject.RegisterRecords.CustomersARAPAccountingByDueDates.Count() = 0 
				And AdjustingObject.RegisterRecords.VendorsARAPAccountingByDueDates.Count() = 0 Then
				AdjustingObject.Delete();
			Else
				SupplementAdjustmentWithRegisteredRecordsInOtherIncomeExpenses(AdjustingObject);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Query.Text = "DROP TTAnalytics_; DROP TTBalance; DROP TTManualAdjustments";
	Query.Execute();
	
	// If everything is fine at the beginning of the period, but there are incorrect balances at the end, we will recalculate them.
	Query.Text = TextOfRequestForIncorrectBalancesOfSettlementsByTerms();
	Query.SetParameter("BegOfMonth",       EndOfMonth(CalculationPeriod));
	Query.SetParameter("Order",            Format(EndOfMonth(CalculationPeriod),"DF=yyyyMMdd9HHmmss99"));
	IncorrectBalances = Query.Execute().Unload();
	
	TableToDistribution = OnlineARAPAccountingServer.TableToDistribution();
	For Each Page1 In IncorrectBalances Do
		NwRw = TableToDistribution.Add();
		FillPropertyValues(NwRw, Page1);
		NwRw.RecalculationStartDate = CalculationPeriod;
		NwRw.PeriodForMonitoringChangesAndCreatingTasks = CalculationPeriod;
	EndDo;
	MainParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
	OnlineARAPAccountingServer.CompleteOperationalSettlements(MainParameters, TableToDistribution);
	
EndProcedure

// Correction of the expanded balance on mutual settlements
// 
// Parameters:
// 	Period - Date - Verification period, you must specify the end of the month
// 	CompanyArray - Array of CatalogRef.Companies - The array organization for which you want to fix a detailed balance of payments
Procedure CorrectReversedBalance(Period, Val CompanyArray = Undefined) Export
	
	AdjustmentDate    = BegOfMonth(Period)-1; //For adjustments and movements
	AdjustmentProcedure = Format(AdjustmentDate,"DF=yyyyMMdd9HHmmss99"); //To request balance data.
	CalculationPeriod        = BegOfMonth(Period); //To compare the balances
	
	CompanyArray = ?(CompanyArray = Undefined,
							Catalogs.Companies.AvailableCompanies(),
							CompanyArray);
	
	TypesOfCalculations_ = New Array;
	TypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	TypesOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = QueryTextDetailedBalance("TotalAmountAnalytics");
	Query.SetParameter("BegOfMonth",       CalculationPeriod);
	Query.SetParameter("CompanyArray",  CompanyArray);
	Query.SetParameter("Order",            AdjustmentProcedure);
	Query.Execute();
	
	DetailedBalance = Query.TempTablesManager.Tables["TotalAmountAnalytics"].GetData().Unload();
	
	ArrayOfOrganizationsToProcess = DetailedBalance.Copy(,"Organization");
	ArrayOfOrganizationsToProcess.GroupBy("Organization");
	ArrayOfOrganizationsToProcess = ArrayOfOrganizationsToProcess.UnloadColumn("Organization");
	
	If DetailedBalance.Count() > 0 Then
		For Each Organization In ArrayOfOrganizationsToProcess Do
			RemoveSystemRegisterAdjustments(AdjustmentDate, Organization, Enums.RegisterAdjustmentOperations.CorrectionOfSidedBalanceInARAPAccounting)
		EndDo;
		
		Query.Text = "DROP TTAnalytics_; DROP TTBalance_; DROP TotalAmountAnalytics; DROP TTManualAdjustments";
		Query.Execute();
		
		//Rereading the leftovers
		
		Query.Text = QueryTextDetailedBalance("TotalAmountAnalytics");
		Query.Execute();
		DetailedBalance = Query.TempTablesManager.Tables["TotalAmountAnalytics"].GetData().Unload(); //ValueTable
		
		DetailedBalance.Indexes.Add("PaymentType_, Organization");
		TheStructureOfTheSearch = New Structure("PaymentType_, Organization");
		
		Query.Text = "SELECT
			|	CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	CustomersARAPAccountingByDueDatesBalance.ARAPObject AS ARAPObject,
			|	CustomersARAPAccountingByDueDatesBalance.Currency AS Currency,
			|	CustomersARAPAccountingByDueDatesBalance.ARAPDocument AS ARAPDocument,
			|	CustomersARAPAccountingByDueDatesBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
			|	CustomersARAPAccountingByDueDatesBalance.OccurrenceDate AS OccurrenceDate,
			|	CustomersARAPAccountingByDueDatesBalance.PrepaymentBalance AS Prepayment,
			|	CustomersARAPAccountingByDueDatesBalance.PrepaymentLocalBalance AS PrepaymentLocal,
			|	CustomersARAPAccountingByDueDatesBalance.PrepaymentManBalance AS PrepaymentMan,
			|	CustomersARAPAccountingByDueDatesBalance.DebtBalance AS Debt,
			|	CustomersARAPAccountingByDueDatesBalance.DebtLocalBalance AS DebtLocal,
			|	CustomersARAPAccountingByDueDatesBalance.ARAPManBalance AS ARAPMan
			|INTO TTSettlementsWithClientsOnTimeBalance
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&BegOfMonth, 
			|		(AccountingDimensionByPartners, ARAPObject, Currency)
			|			IN (SELECT AccountingDimensionByPartners, ARAPObject, Currency 
			|				FROM TotalAmountAnalytics
			|				WHERE PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
			|				)) AS CustomersARAPAccountingByDueDatesBalance
			|
			|INDEX BY
			|	AccountingDimensionByPartners, ARAPObject, Currency, ARAPDocument
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	VendorsARAPAccountingByDueDatesBalance.ARAPObject AS ARAPObject,
			|	VendorsARAPAccountingByDueDatesBalance.Currency AS Currency,
			|	VendorsARAPAccountingByDueDatesBalance.ARAPDocument AS ARAPDocument,
			|	VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
			|	VendorsARAPAccountingByDueDatesBalance.OccurrenceDate AS OccurrenceDate,
			|	VendorsARAPAccountingByDueDatesBalance.PrepaymentBalance AS PrepaymentBalance,
			|	VendorsARAPAccountingByDueDatesBalance.PrepaymentLocalBalance AS PrepaymentLocalBalance,
			|	VendorsARAPAccountingByDueDatesBalance.PrepaymentManBalance AS PrepaymentManBalance,
			|	VendorsARAPAccountingByDueDatesBalance.DebtBalance AS DebtBalance,
			|	VendorsARAPAccountingByDueDatesBalance.DebtLocalBalance AS DebtLocalBalance,
			|	VendorsARAPAccountingByDueDatesBalance.ARAPManBalance AS ARAPManBalance
			|INTO TTSettlementsWithSuppliersOnTimeBalance
			|FROM
			|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&BegOfMonth, 
			|		(AccountingDimensionByPartners, ARAPObject, Currency)
			|			IN (SELECT AccountingDimensionByPartners, ARAPObject, Currency
			|					FROM TotalAmountAnalytics
			|					WHERE PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
			|					)) AS VendorsARAPAccountingByDueDatesBalance
			|
			|INDEX BY
			|	AccountingDimensionByPartners, ARAPObject, Currency, ARAPDocument
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
			|	CalculationsByTermsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
			|	CalculationsByTermsBalance.ARAPObject AS ARAPObject,
			|	CalculationsByTermsBalance.Currency AS Currency,
			|	CalculationsByTermsBalance.ARAPDocument AS ARAPDocument,
			|	CalculationsByTermsBalance.PlannedRepaymentDate AS PlannedRepaymentDate,
			|	CalculationsByTermsBalance.OccurrenceDate AS OccurrenceDate,
			|	CalculationsByTermsBalance.Prepayment AS Prepayment,
			|	CalculationsByTermsBalance.PrepaymentLocal AS PrepaymentLocal,
			|	CalculationsByTermsBalance.PrepaymentMan AS PrepaymentMan,
			|	CalculationsByTermsBalance.Debt AS Debt,
			|	CalculationsByTermsBalance.DebtLocal AS DebtLocal,
			|	CalculationsByTermsBalance.ARAPMan AS ARAPMan,
			|	MIN(CalculationsForTermsUpTo.SettlementProcedure) AS SettlementProcedure,
			|	MIN(CalculationsForTermsUpTo.OperationProcedure) AS OperationProcedure,
			|	MAX(CalculationsForTermsUpTo.LinkedDocument) AS LinkedDocument,
			|	MIN(CalculationsForTermsUpTo.DocumentCurrency) AS DocumentCurrency,
			|	MAX(CalculationsForTermsUpTo.CashFlowItem) AS CashFlowItem,
			|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation
			|FROM
			|	TTSettlementsWithClientsOnTimeBalance AS CalculationsByTermsBalance
			|		LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsForTermsUpTo
			|		ON (CalculationsForTermsUpTo.AccountingDimensionByPartners = CalculationsByTermsBalance.AccountingDimensionByPartners)
			|			AND (CalculationsForTermsUpTo.ARAPObject = CalculationsByTermsBalance.ARAPObject)
			|			AND (CalculationsForTermsUpTo.Currency = CalculationsByTermsBalance.Currency)
			|			AND (CalculationsForTermsUpTo.ARAPDocument = CalculationsByTermsBalance.ARAPDocument)
			|			AND (CalculationsForTermsUpTo.Period < &BegOfMonth)
			|			AND (CalculationsForTermsUpTo.Active)
			|
			|GROUP BY
			|	CalculationsByTermsBalance.AccountingDimensionByPartners,
			|	CalculationsByTermsBalance.ARAPObject,
			|	CalculationsByTermsBalance.Currency,
			|	CalculationsByTermsBalance.ARAPDocument,
			|	CalculationsByTermsBalance.PlannedRepaymentDate,
			|	CalculationsByTermsBalance.OccurrenceDate,
			|	CalculationsByTermsBalance.Prepayment,
			|	CalculationsByTermsBalance.PrepaymentLocal,
			|	CalculationsByTermsBalance.PrepaymentMan,
			|	CalculationsByTermsBalance.Debt,
			|	CalculationsByTermsBalance.DebtLocal,
			|	CalculationsByTermsBalance.ARAPMan
			|
			|UNION ALL
			|
			|SELECT
			|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting),
			|	CalculationsByTermsBalance.AccountingDimensionByPartners,
			|	CalculationsByTermsBalance.ARAPObject,
			|	CalculationsByTermsBalance.Currency,
			|	CalculationsByTermsBalance.ARAPDocument,
			|	CalculationsByTermsBalance.PlannedRepaymentDate,
			|	CalculationsByTermsBalance.OccurrenceDate,
			|	CalculationsByTermsBalance.PrepaymentBalance,
			|	CalculationsByTermsBalance.PrepaymentLocalBalance,
			|	CalculationsByTermsBalance.PrepaymentManBalance,
			|	CalculationsByTermsBalance.DebtBalance,
			|	CalculationsByTermsBalance.DebtLocalBalance,
			|	CalculationsByTermsBalance.ARAPManBalance,
			|	MIN(CalculationsForTermsUpTo.SettlementProcedure),
			|	MIN(CalculationsForTermsUpTo.OperationProcedure),
			|	MAX(CalculationsForTermsUpTo.LinkedDocument),
			|	MIN(CalculationsForTermsUpTo.DocumentCurrency),
			|	MAX(CalculationsForTermsUpTo.CashFlowItem),
			|	VALUE(Enum.BusinessTransactions.EmptyRef)
			|FROM
			|	TTSettlementsWithSuppliersOnTimeBalance AS CalculationsByTermsBalance
			|		LEFT JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsForTermsUpTo
			|		ON (CalculationsForTermsUpTo.AccountingDimensionByPartners = CalculationsByTermsBalance.AccountingDimensionByPartners)
			|			AND (CalculationsForTermsUpTo.ARAPObject = CalculationsByTermsBalance.ARAPObject)
			|			AND (CalculationsForTermsUpTo.Currency = CalculationsByTermsBalance.Currency)
			|			AND (CalculationsForTermsUpTo.ARAPDocument = CalculationsByTermsBalance.ARAPDocument)
			|			AND (CalculationsForTermsUpTo.Period < &BegOfMonth)
			|			AND (CalculationsForTermsUpTo.Active)
			|
			|GROUP BY
			|	CalculationsByTermsBalance.AccountingDimensionByPartners,
			|	CalculationsByTermsBalance.ARAPObject,
			|	CalculationsByTermsBalance.Currency,
			|	CalculationsByTermsBalance.ARAPDocument,
			|	CalculationsByTermsBalance.PlannedRepaymentDate,
			|	CalculationsByTermsBalance.OccurrenceDate,
			|	CalculationsByTermsBalance.PrepaymentBalance,
			|	CalculationsByTermsBalance.PrepaymentLocalBalance,
			|	CalculationsByTermsBalance.PrepaymentManBalance,
			|	CalculationsByTermsBalance.DebtBalance,
			|	CalculationsByTermsBalance.DebtLocalBalance,
			|	CalculationsByTermsBalance.ARAPManBalance
			|
			|ORDER BY
			|	MIN(CalculationsForTermsUpTo.OperationProcedure)";
		
		DetailedRecords = Query.Execute().Unload();
		DetailedRecords.Indexes.Add("PaymentType_, AccountingDimensionByPartners, ARAPObject, Currency");
		DetailedRecordSearchStructure = New Structure("PaymentType_, AccountingDimensionByPartners, ARAPObject, Currency");
		
		ArrayOfOrganizationsToProcess = DetailedBalance.Copy(,"Organization");
		ArrayOfOrganizationsToProcess.GroupBy("Organization");
		ArrayOfOrganizationsToProcess = ArrayOfOrganizationsToProcess.UnloadColumn("Organization");
		
		For Each Organization In ArrayOfOrganizationsToProcess Do
			
			AdjustingObject = RegisterAdjustment(AdjustmentDate, Organization, Enums.RegisterAdjustmentOperations.CorrectionOfSidedBalanceInARAPAccounting);
			
			For Each PaymentType_ In TypesOfCalculations_ Do
				
				TypeOfCalculationsByString = ?(PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting,"CustomersARAPAccounting","VendorsARAPAccounting");
				
				RegisterRecords = AdjustingObject.RegisterRecords[TypeOfCalculationsByString + "ByTerms"]; // AccumulationRegisterRecordSet
				
				TheStructureOfTheSearch.PaymentType_ = PaymentType_;
				TheStructureOfTheSearch.Organization = Organization;
				RecordsOfExpandedBalance = DetailedBalance.FindRows(TheStructureOfTheSearch);
				
				For Each RecordExpandedBalance In RecordsOfExpandedBalance Do
					FillPropertyValues(DetailedRecordSearchStructure, RecordExpandedBalance);
					DetailedRecordSearchStructure.Currency = RecordExpandedBalance.Currency;
					DetailedAnalyticsRecords = DetailedRecords.FindRows(DetailedRecordSearchStructure);
					
					AmountToDistributeDebt = Min(RecordExpandedBalance.DebtBalance, RecordExpandedBalance.PrepaymentBalance);
					AmountToBeDistributedPrepayment = AmountToDistributeDebt;
					
					For Each RowOfDetailedRecords In DetailedAnalyticsRecords Do
						
						If AmountToDistributeDebt = 0 And AmountToBeDistributedPrepayment = 0 Then
							Break;
						EndIf;
						
						NwRw = RegisterRecords.Add();
						FillPropertyValues(NwRw, RowOfDetailedRecords);
						
						NwRw.Period              = AdjustmentDate;
						NwRw.RecordType         = AccumulationRecordType.Expense;
						NwRw.DocumentRecorder = AdjustingObject.Ref;
						NwRw.OperationProcedure     = AdjustmentProcedure;
						
						If RowOfDetailedRecords.Debt > 0 Then
							DebitedAmount = Min(AmountToDistributeDebt, RowOfDetailedRecords.Debt);
							
							NwRw.DebtLocal = RowOfDetailedRecords.DebtLocal / RowOfDetailedRecords.Debt * DebitedAmount;
							NwRw.ARAPMan  = RowOfDetailedRecords.ARAPMan / RowOfDetailedRecords.Debt * DebitedAmount;
							NwRw.Debt     = DebitedAmount;
							NwRw.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;
							
							AmountToDistributeDebt = AmountToDistributeDebt - DebitedAmount;
						EndIf;
						
						If RowOfDetailedRecords.Prepayment > 0 Then
							DebitedAmount = Min(AmountToBeDistributedPrepayment, RowOfDetailedRecords.Prepayment);
							
							NwRw.PrepaymentLocal = RowOfDetailedRecords.PrepaymentLocal / RowOfDetailedRecords.Prepayment * DebitedAmount;
							NwRw.PrepaymentMan  = RowOfDetailedRecords.PrepaymentMan / RowOfDetailedRecords.Prepayment * DebitedAmount;
							NwRw.Prepayment     = DebitedAmount;
							NwRw.SettlementRecordType = Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease;
							
							AmountToBeDistributedPrepayment = AmountToBeDistributedPrepayment - DebitedAmount;
						EndIf;
						
					EndDo;
				EndDo;
				
				RegisterRecords.Write();
				TableToDistribution = OnlineARAPAccountingServer.TableToDistribution();
				For Each AnalyticsLine_ In RecordsOfExpandedBalance Do
					NwRw = TableToDistribution.Add();
					FillPropertyValues(NwRw, AnalyticsLine_);
					NwRw.RecalculationStartDate = CalculationPeriod;
				EndDo;
				MainParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
				OnlineARAPAccountingServer.CompleteOperationalSettlements(MainParameters, TableToDistribution);
			EndDo;
			
			If AdjustingObject.RegisterRecords.CustomersARAPAccountingByDueDates.Count() = 0 
				And AdjustingObject.RegisterRecords.VendorsARAPAccountingByDueDates.Count() = 0 Then
				AdjustingObject.Delete();
			Else
				SupplementAdjustmentWithRegisteredRecordsInOtherIncomeExpenses(AdjustingObject);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Query.Text = "DROP TTAnalytics_; DROP TTBalance_; DROP TTManualAdjustments";
	Query.Execute();
	
	// If everything is fine at the beginning of the period, but there is an expanded balance at the end, we will recalculate them.
	Query.Text = QueryTextDetailedBalance();
	Query.SetParameter("BegOfMonth",       EndOfMonth(CalculationPeriod));
	Query.SetParameter("Order",            Format(EndOfMonth(CalculationPeriod),"DF=yyyyMMdd9HHmmss99"));
	IncorrectBalances = Query.Execute().Unload();
	
	TableToDistribution = OnlineARAPAccountingServer.TableToDistribution();
	For Each Page1 In IncorrectBalances Do
		NwRw = TableToDistribution.Add();
		FillPropertyValues(NwRw, Page1);
		NwRw.RecalculationStartDate = CalculationPeriod;
		NwRw.PeriodForMonitoringChangesAndCreatingTasks = CalculationPeriod;
	EndDo;
	MainParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
	OnlineARAPAccountingServer.CompleteOperationalSettlements(MainParameters,TableToDistribution);
	
EndProcedure

Procedure RemoveSystemRegisterAdjustments(RecountDate, Organization = Undefined, Operation = Undefined, Counterparty = Undefined) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	RegisterAdjustment.Ref AS Ref
	|FROM
	|	Document.RegisterAdjustment AS RegisterAdjustment
	|WHERE
	|	RegisterAdjustment.Date >= &Date
	|	AND (RegisterAdjustment.Organization = &Organization OR &ByAllCompanies)
	|	AND RegisterAdjustment.Operation IN (&Operations)
	|	AND &ForAllCounterparties
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Calculations.Recorder AS Ref
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKey
	|			ON DimensionKey.Ref = Calculations.AccountingDimensionByPartners
	|WHERE
	|	Calculations.Period >= &Date
	|	AND DimensionKey.Counterparty = &Counterparty
	|	AND (DimensionKey.Organization = &Organization OR &ByAllCompanies)
	|	AND NOT &ForAllCounterparties
	|	AND Calculations.Recorder REFS Document.RegisterAdjustment
	|	AND CAST(Calculations.Recorder AS Document.RegisterAdjustment).Operation IN (&Operations)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Calculations.Recorder AS Ref
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKey
	|			ON DimensionKey.Ref = Calculations.AccountingDimensionByPartners
	|WHERE
	|	Calculations.Period >= &Date
	|	AND DimensionKey.Counterparty = &Counterparty
	|	AND (DimensionKey.Organization = &Organization OR &ByAllCompanies)
	|	AND NOT &ForAllCounterparties
	|	AND Calculations.Recorder REFS Document.RegisterAdjustment
	|	AND CAST(Calculations.Recorder AS Document.RegisterAdjustment).Operation IN (&Operations)
	|
	|;
	|
	|SELECT
	|	DimensionKeysOfAccountingByPartners.Ref AS AccountingDimensionByPartners
	|FROM
	|	Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|WHERE
	|	(DimensionKeysOfAccountingByPartners.Organization = &Organization OR &ByAllCompanies)
	|	AND DimensionKeysOfAccountingByPartners.Counterparty = &Counterparty
	|	AND NOT &ForAllCounterparties";
	Query.SetParameter("Date", BegOfDay(RecountDate));
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ByAllCompanies", Organization = Undefined);
	Query.SetParameter("ForAllCounterparties", Counterparty = Undefined);
	Query.SetParameter("Counterparty", Counterparty);
	Operations = New Array;
	If ValueIsFilled(Operation) Then
		Operations.Add(Operation);
	Else
		Operations.Add(Enums.RegisterAdjustmentOperations.CorrectionOfBalanceGapsInARAPAccounting);
		Operations.Add(Enums.RegisterAdjustmentOperations.CorrectionOfSidedBalanceInARAPAccounting);
	EndIf;
	Query.SetParameter("Operations", Operations);
	
	Result = Query.ExecuteBatch();
	Selection = Result[0].Select();
	AnalystTable = Result[1].Unload();
	AnalystTable.Indexes.Add("AccountingDimensionByPartners");
	
	InDownloadMode = RecountDate = Date(1,1,1);
	
	While Selection.Next() Do
		
		DocumentObject = Selection.Ref.GetObject(); // DocumentObject.RegisterAdjustment
		
		For Each Register In DocumentObject.RegistersTable Do
			RegisterRecords = DocumentObject.RegisterRecords[Register.Name]; // AccumulationRegisterRecordSet
			RegisterRecords.DataExchange.Load = InDownloadMode;
			If ValueIsFilled(Counterparty) 
				And (Register.Name = Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name 
					Or Register.Name = Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name) Then
					RegisterRecords.Read();
					Counter = RegisterRecords.Count();
					While Counter > 0 Do
						Counter = Counter - 1;
						If AnalystTable.Find(RegisterRecords[Counter].AccountingDimensionByPartners) <> Undefined Then
							RegisterRecords.Delete(Counter);
						EndIf;
					EndDo;
					
			EndIf;
			RegisterRecords.Write();
		EndDo;
		
		If DocumentObject.RegisterRecords.CustomersARAPAccountingByDueDates.Count() = 0 
			And DocumentObject.RegisterRecords.VendorsARAPAccountingByDueDates.Count() = 0 Then
			DocumentObject.DataExchange.Load = InDownloadMode;
			DocumentObject.Delete();
		Else
			SupplementAdjustmentWithRegisteredRecordsInOtherIncomeExpenses(DocumentObject);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region GetData

// Document amounts.
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject, CatalogObject - Object
//  ParametersStructure - Structure  - parameter structure
// 
// Returns:
//   Structure:
//      * AmountOfSettlementsWithoutCollateral - Number
//      * AmountOfDocumentWithoutCollateral - Number
//      * PackageDepositValue - Number
//      * AmountARAPByPackage - Number
//      * AmountARAP - Number
//      * DocumentAmount - Number
Function DocumentAmounts(Object, ParametersStructure, OrderAmounts = Undefined) Export
	
	If ParametersStructure.Property("DocumentAmounts") Then
		Return ParametersStructure.DocumentAmounts;
	EndIf;
	
	Result = New Structure;
	
	If ParametersStructure.SourceOfAmountsTabularPart Then
		If OrderAmounts = Undefined Then
			OrderAmounts                = ARAPAccountingServer.TableOfOrderAmounts(Object,ParametersStructure);
		EndIf;
		PackageDepositValue            = OrderAmounts.Total("PackageDepositValue");
		AmountOfDocumentWithoutCollateral      = OrderAmounts.Total("PaymentAmount");
		AmountARAPByPackage    = OrderAmounts.Total("AmountARAPByPackage");
		AmountOfSettlementsWithoutCollateral = OrderAmounts.Total("AmountARAP");
	ElsIf ValueIsFilled(ParametersStructure.PathToTSData) Then
		TabularSection = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData);
		AmountOfDocumentWithoutCollateral      = ARAPAccountingClientServer.TotalForSumsOfOneCharacter(TabularSection,ParametersStructure.PropsNameTSAmountWithVAT);
		AmountOfSettlementsWithoutCollateral = 0;
		If TabularSection.Count() > 0 Then
			If CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0],"AmountARAP") Then
				AmountOfSettlementsWithoutCollateral = ARAPAccountingClientServer.TotalForSumsOfOneCharacter(TabularSection, "AmountARAP");
			Else
				AmountOfSettlementsWithoutCollateral = ARAPAccountingClientServer.TotalForSumsOfOneCharacter(TabularSection, ParametersStructure.PropsNameTSAmountWithVAT);
			EndIf;
		EndIf;
		PackageDepositValue = 0;
		AmountARAPByPackage = 0;
	Else
		PackageDepositValue            = 0;
		AmountOfDocumentWithoutCollateral      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentAmount);
		AmountOfSettlementsWithoutCollateral = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.AmountARAP, , 0);
		AmountARAPByPackage    = 0;
	EndIf;
	
	Result.Insert("AmountOfSettlementsWithoutCollateral", AmountOfSettlementsWithoutCollateral);
	Result.Insert("AmountOfDocumentWithoutCollateral", AmountOfDocumentWithoutCollateral);
	Result.Insert("PackageDepositValue", PackageDepositValue);
	Result.Insert("AmountARAPByPackage", AmountARAPByPackage);
	Result.Insert("AmountARAP", AmountOfSettlementsWithoutCollateral + AmountARAPByPackage);
	Result.Insert("DocumentAmount", ?(AmountOfDocumentWithoutCollateral = Undefined,0,AmountOfDocumentWithoutCollateral + PackageDepositValue));
	
	Return Result;
	
EndFunction

Function DetailsOfAgreement(Terms) Export
	
	SetPrivilegedMode(True);
	If TypeOf(Terms) = Type("CatalogRef.TermsOfSale") Then
		DetailsOfAgreement = Common.ObjectAttributesValues(Terms,
			"ContractsAreUsed, ARAPObjectSettings,Calendar, DeadlineOfTransferOfTitleToGoods, PaymentSchedule");
	Else
		DetailsOfAgreement = Common.ObjectAttributesValues(Terms,
			"ContractsAreUsed, ARAPObjectSettings, Calendar, DeadlineOfTransferOfTitleToGoods");
	EndIf;
	SetPrivilegedMode(False);
	
	Return DetailsOfAgreement;
EndFunction

//Returns the default calculation order.
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject, CatalogObject - Object
//  ParametersStructure - Structure  - parameter structure
// 
// Returns:
//  EnumRef.ARAPObjectSettings - Calculation Procedure For Parameters
Function CalculationProcedureForParameters(Object, ParametersStructure) Export
	
	OrderBase = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
	If Not ValueIsFilled(OrderBase) Then
		AnArrayOfOrders = GetArrayOfOrdersFromTS(Object, ParametersStructure);
		If AnArrayOfOrders.Count() > 0 Then
			OrderBase = AnArrayOfOrders[0];
		EndIf;
	EndIf;
	Terms     = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Terms);
	If ValueIsFilled(ParametersStructure.CommissionAgentSAgreement) Then
		Contract        = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CommissionAgentSAgreement);
	Else
		
		If ParametersStructure.Contract = "Object.SalesContract"
			Or ParametersStructure.Contract = "Object.PurchasingContract" Then
			Contract = Undefined;
		Else
			Contract = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
		EndIf;
		
	EndIf;
	ThisIsOrder       = ParametersStructure.ThisIsOrder;
	
	Return ARAPAccountingServer.ARAPObjectSettings(ThisIsOrder, OrderBase, Terms, Contract);
	
EndFunction

//Returns the default payment order.
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject, CatalogObject - Object
//  ParametersStructure - Structure  - parameter structure
//  SystemSettings_ - Structure -System Settings
// 
// Returns:
//  CatalogRef.FinancialAccountingGroupsOfARAP - GFUPo default
Function DefaultHFCS(Object, ParametersStructure, SystemSettings_) Export
	
	ARAPObjectSettings = TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.ARAPObjectSettings);
	InvoiceForOrders = TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.InvoiceForOrders,,False);
	Terms = TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.Terms);
	Contract = TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.Contract);
	
	DefaultHFCS = PredefinedValue("Catalog.FinancialAccountingGroupsOfARAP.EmptyRef");
	
	If ParametersStructure.ThisIsOrder
		Or ParametersStructure.IsItPaymentOrOtherDocument
		Or ParametersStructure.ThisIsSalePurchase
			And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByOrders")
				And Not InvoiceForOrders
					Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
					Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")
					Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")) Then
		
		If ValueIsFilled(Terms) Then
			
			SetPrivilegedMode(True);
			DetailsOfAgreement = Common.ObjectAttributesValues(Terms, "ContractsAreUsed, FinancialAccountingGroup");
			SetPrivilegedMode(False);
			
			If DetailsOfAgreement.ContractsAreUsed
				And ValueIsFilled(Contract) Then
				DefaultHFCS = FAGByContract(Contract, ParametersStructure);
			Else
				DefaultHFCS = DetailsOfAgreement.FinancialAccountingGroup;
			EndIf;
			
		ElsIf ValueIsFilled(Contract) Then
			
			DefaultHFCS = FAGByContract(Contract, ParametersStructure);
			
		EndIf;
		
	EndIf;
	
	Return DefaultHFCS;
	
EndFunction

//Returns the default payment order.
// 
// Parameters:
//  Object - FormDataStructure, DocumentObject, CatalogObject - Object
//  ParametersStructure - Structure  - parameter structure
// 
// Returns:
//  Boolean, Arbitrary - Payment In Default Currency
Function PaymentInDefaultCurrency(Object, ParametersStructure) Export
	
	PaymentMethod               = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PaymentMethod);
	BankAccount            = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CompanyBankAccount);
	CashAccount                     = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.CashAccount);
	OrderBase            = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
	Terms                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Terms);
	Contract                   = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
	Organization               = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	CurrencyOfPayment = CashServer.GetPaymentCurrency(PaymentMethod, BankAccount, CashAccount);
	ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(CurrencyOfPayment, Organization);
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(OrderBase)
			And Common.HasObjectAttribute("ForeignCurrencyTransaction", OrderBase.Metadata()) Then
		ForeignCurrencyTransaction = Common.ObjectAttributeValue(OrderBase, "ForeignCurrencyTransaction");
	ElsIf ValueIsFilled(Terms) Then
		SetPrivilegedMode(True);
		DetailsOfAgreement = Common.ObjectAttributesValues(Terms, "ContractsAreUsed, ForeignCurrencyTransaction");
		SetPrivilegedMode(False);
		If DetailsOfAgreement.ContractsAreUsed And ValueIsFilled(Contract) Then
			ForeignCurrencyTransaction = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
		ElsIf DetailsOfAgreement.ContractsAreUsed = False Then
			ForeignCurrencyTransaction = DetailsOfAgreement.ForeignCurrencyTransaction;
		EndIf;
	ElsIf ValueIsFilled(Contract) Then
		ForeignCurrencyTransaction = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
	Else 
		CurrencyOfPayment = CashServer.GetPaymentCurrency(PaymentMethod, BankAccount, CashAccount);
		If Not ValueIsFilled(CurrencyOfPayment) Then
			CurrencyOfPayment = LocalAccountingCurrency;
		EndIf;
		
		If Not CurrencyOfPayment = LocalAccountingCurrency Then
			ForeignCurrencyTransaction = True;
		Else
			ForeignCurrencyTransaction = False;
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return ForeignCurrencyTransaction;
	
EndFunction

#EndRegion

#Region ClearingFields

//Clears the table of the stages of the schedule of payments.
Procedure ClearPaymentScheduleStages(Object, ParametersStructure) Export
	
	If ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
		PaymentScheduleSteps = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
		PaymentScheduleSteps.Clear();
	EndIf;
	
	If ValueIsFilled(ParametersStructure.PaymentDate) Then
		Attribute = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.PaymentDate);
		Attribute.Data[Attribute.Name] = Date(1,1,1);
	EndIf;
	
EndProcedure

//Clears references to the calculation Objects reference list.
Procedure ClearCalculationObject(Object, ParametersStructure) Export
	
	PaymentObjectDetails = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.ARAPObject);
	NumberOfOccurrences = StrOccurrenceCount(ParametersStructure.ARAPObject, ".");
	
	If NumberOfOccurrences = 0 Then
		Return;
	ElsIf NumberOfOccurrences = 1 Then
		PaymentObjectDetails.Data[PaymentObjectDetails.Name] = Catalogs.ARAPObjects.EmptyRef();
	Else 
		For Each TSRow In PaymentObjectDetails.Data Do
			TSRow[PaymentObjectDetails.Name] = Catalogs.ARAPObjects.EmptyRef();
		EndDo;
	EndIf;
	
EndProcedure

//Clears the settlement amounts in the table part of the document
// 
// Parameters:
// 	Form - Pharmaciestestosterone - Form configuration object.
// 	Patkanim - String - path to the data table portion, in which to clear the amount of the settlement.
//
Procedure ClearAmountsOfTSSettlements(Object, ParametersStructure) Export
	
	If Not ValueIsFilled(ParametersStructure.PathToTSData) Then
		Return;
	EndIf;
	
	TS = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData);
	
	If TS.Count() > 0 And CommonClientServer.HasAttributeOrObjectProperty(TS[0], "AmountARAP") Then
		ThereIsVAT = CommonClientServer.HasAttributeOrObjectProperty(TS[0], "AmountVATARAP");
		
		For Each Page1 In TS Do
			Page1.AmountARAP = 0;
			If ThereIsVAT Then
				Page1.AmountVATARAP = 0;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

Function AvailableRequestFields(QueryText) Export
	
	Keyword = "SELECT"; //@Query-part
	ENDTOCHOOSE = StrFind(QueryText, Keyword) + StrLen(Keyword);
	
	Keyword = "FROM"; //@Query-part
	StartingFrom = StrFind(QueryText, Keyword);
	
	SelectionText = Mid(QueryText, ENDTOCHOOSE, StartingFrom - ENDTOCHOOSE);
	
	SelectionSubstrings = StrSplit(SelectionText, ",", False);
	
	AvailableFields = New Array;
	
	Keyword = "AS"; //@Query-part
	LengthAS = StrLen(Keyword);
	// In the text of the selection fields, a comma may occur as a string in double quotes and a keyword AS inside the brackets of the EXPRESSION operator, it is
	// necessary to combine the substrings into a whole expression of the selection field together with the alias, and only after that to search for the keyword AS separating the alias
	SelectionFieldText = "";
	For Each Substring In SelectionSubstrings Do
		
		SelectionFieldText = SelectionFieldText + ?(SelectionFieldText = "", "", ",") + Substring;
		
		NumberOfOpeningsClosuresOfBrackets = StrOccurrenceCount(SelectionFieldText, "(") - StrOccurrenceCount(SelectionFieldText, ")");
		NumberOfDoubleQuotes = StrOccurrenceCount(SelectionFieldText, """");
		
		If NumberOfOpeningsClosuresOfBrackets = 0 And NumberOfDoubleQuotes%2 = 0 Then
			
			BeginningAS = StrFind(SelectionFieldText, Keyword, SearchDirection.FromEnd);
			If BeginningAS = 0 Then
				Raise NStr("ru = 'Для всех полей выборки должен быть задан псевдоним';
							|vi = 'All selection fields should have an alias';
							|en = 'All selection fields should have an alias'; fa = 'All selection fields should have an alias';
							|it = 'Deve essere fornito uno pseudonimo a tutti i campi';
							|pl = 'Wszystkie przykładowe pola muszą mieć aliasy';
							|tr = 'Tüm örnek alanlarının bir takma adı olmalıdır'");
			EndIf;
			
			Alias = TrimAll(Right(SelectionFieldText, StrLen(SelectionFieldText) - (BeginningAS + LengthAS)));
			AvailableFields.Add(Alias);
			
		EndIf;
		
	EndDo;
	
	Return AvailableFields;
	
EndFunction

// Checks the equality of tables by common columns
// 
// Parameters:
//  Table1 - ValueTable - the first table.
//  Table2 - ValueTable - the second table.
// 
// Returns:
//  Boolean - True if the tables are equal
Function TablesAreEqual(Table1, Table2) Export
	
	ColumnsArray1 = New Array;
	ColumnLineNumber = Table1.Columns.Find("LineNumber");
	ColumnOriginalLineNumber = Table1.Columns.Find("SourceLineNumber");
	If ColumnLineNumber <> Undefined Then
		Table1.Columns.Delete(ColumnLineNumber);
	EndIf;
	If ColumnOriginalLineNumber <> Undefined Then
		Table1.Columns.Delete(ColumnOriginalLineNumber);
	EndIf;
	For Each Column In Table1.Columns Do
		If TypeOf(Table2) = Type("ValueTable") 
			And Table2.Columns.Find(Column.Name) <> Undefined Then
			ColumnsArray1.Add(Column.Name);
		EndIf;
	EndDo;
	
	Result = True;
	If Table1.Count() <> Table2.Count() Then
		Result = False;
	EndIf;
	If Result Then
		For Counter = 0 To Table1.Count() - 1 Do
			If Not TMCommonUseClientServer.StructuresAreEqual(
						Table1[Counter],
						Table2[Counter],
						ColumnsArray1) Then
				Result = False;
				Break;
			EndIf;
		EndDo;
	EndIf; 
	Return Result;
	
EndFunction

// The procedure fills in the course of the document by default
//
// Required parameters:
//	Date
//	Currency of the document
//	Currency of the settlements
//
Procedure FillCourseMultiplicityByDefault(Object, AugmentedMechanismParameters) Export
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		If ParametersStructure.CourseNumerator = "" Or TypeOf(ParametersStructure.CourseNumerator)<> Type("String")
			Or ParametersStructure.CourseDenominator = "" Or TypeOf(ParametersStructure.CourseDenominator)<> Type("String") Then
			Continue;
		EndIf;
		
		Check_Parameters(ParametersStructure, "DocumentCurrency,ARAPCurrency");
		
		Date                 = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
		DocumentCurrency      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DocumentCurrency);
		ARAPCurrency = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPCurrency);
		Organization          = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Organization);
		CourseNumerator        = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.CourseNumerator);
		CourseDenominator      = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.CourseDenominator);
		ContractRateOption = ParametersStructure.ContractRateOption;
		Contract              = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Contract);
		
		CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		
		If Not ValueIsFilled(Date) Then
			Date = CurrentSessionDate();
		EndIf;
		
		If DocumentCurrency = ARAPCurrency 
			Or Not ValueIsFilled(DocumentCurrency) 
			Or Not ValueIsFilled(ARAPCurrency)
			Or Not ValueIsFilled(CurrencyOfComplianceAccounting) Then
			
			CourseNumerator.Data[CourseNumerator.Name]     = 1;
			CourseDenominator.Data[CourseDenominator.Name] = 1;
			Return;
			
		ElsIf DocumentCurrency = CurrencyOfComplianceAccounting And Not ARAPCurrency = CurrencyOfComplianceAccounting Then
			
			If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
				RateStructure = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, Date);
			Else
				RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(ARAPCurrency, Date, CurrencyOfComplianceAccounting);
			EndIf;
			
		ElsIf Not DocumentCurrency = CurrencyOfComplianceAccounting And ARAPCurrency = CurrencyOfComplianceAccounting Then
			
			RateStructure = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, Date, CurrencyOfComplianceAccounting);
			
		Else
			
			If ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
				MutualSettlementsExchangeRate = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(Contract, Date);
			Else
				MutualSettlementsExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ARAPCurrency, Date, CurrencyOfComplianceAccounting);
			EndIf;
			DocumentExchangeRate      = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, Date, CurrencyOfComplianceAccounting);
			RateStructure           = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentExchangeRate, MutualSettlementsExchangeRate);
			
		EndIf;
		
		CourseNumerator.Data[CourseNumerator.Name] = RateStructure.CourseNumerator;
		CourseDenominator.Data[CourseDenominator.Name] = RateStructure.CourseDenominator;
	EndDo;
	
EndProcedure

Procedure DisableCalculationRegisterTotals() Export
	
	AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.SetTotalsUsing(False);
	AccumulationRegisters.CustomersARAPAccountingPlannedShipments.SetTotalsUsing(False);
	AccumulationRegisters.CustomersARAPAccountingByDueDates.SetTotalsUsing(False);
	AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.SetTotalsUsing(False);
	AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.SetTotalsUsing(False);
	AccumulationRegisters.VendorsARAPAccountingByDueDates.SetTotalsUsing(False);
	
EndProcedure

Procedure IncludeCalculationRegisterTotals() Export
	
	AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.SetTotalsUsing(True);
	AccumulationRegisters.CustomersARAPAccountingPlannedShipments.SetTotalsUsing(True);
	AccumulationRegisters.CustomersARAPAccountingByDueDates.SetTotalsUsing(True);
	AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.SetTotalsUsing(True);
	AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.SetTotalsUsing(True);
	AccumulationRegisters.VendorsARAPAccountingByDueDates.SetTotalsUsing(True);
	
	AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.RecalcTotals();
	AccumulationRegisters.CustomersARAPAccountingPlannedShipments.RecalcTotals();
	AccumulationRegisters.CustomersARAPAccountingByDueDates.RecalcTotals();
	AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.RecalcTotals();
	AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries.RecalcTotals();
	AccumulationRegisters.VendorsARAPAccountingByDueDates.RecalcTotals();
	
EndProcedure

#EndRegion

#Region Private

#Region WorkingWithThreads

Function ChunkSizeOfProcessingInSingleThread() Export
	
	Return 1000;
	
EndFunction

Function NumberOfSettlementsAllocationThreads() Export
	
	Count = Constants.NumberOfSettlementsAllocationThreads.Get();
	If Count = 0 Then
		Count = 8;
	EndIf;
	If Common.DataSeparationEnabled() Then
		Count = 1;
	EndIf;
	Return Count;
	
EndFunction

// New flow description.
// 
// Parameters:
//  MethodName - String - Method name
// 
// Returns:
//  Structure - New Flow Description:
// * JobID - Undefined - 
// * Procedure - String - 
// * ResultAddress - String - 
// * JobDescription - String - 
// * ProcedureParameters - Structure - 
Function NewFlowDescription(MethodName = "") Export
	
	LongDesc = New Structure;
	LongDesc.Insert("JobID", Undefined);
	LongDesc.Insert("Procedure", MethodName);
	LongDesc.Insert("ResultAddress", "");
	LongDesc.Insert("JobDescription", "");
	LongDesc.Insert("ProcedureParameters", New Structure);
	Return LongDesc;
	
EndFunction

Procedure StartProcessingInBackground(Stream) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Undefined);
	ExecutionParameters.BackgroundJobDescription = Stream.JobDescription;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, New UUID);
	
	RunResult = TimeConsumingOperations.ExecuteInBackground(Stream.Procedure, Stream.ProcedureParameters, ExecutionParameters);
	
	Stream.ResultAddress = RunResult.ResultAddress;
	Status = RunResult.Status;
	
	If Status = "Running" Then
		Stream.JobID = RunResult.JobID;
	ElsIf Status <> "Running" And Status <> "Completed2" Then
		Raise RunResult.BriefErrorDescription;
	EndIf;
	
EndProcedure

Procedure WaitForAllThreadsCompletion(Threads, TuplesInProcessing = Undefined, NumberOfRecordsProcessed = 0) Export
	While Threads.Count() > 0 Do
		If Not StopThreadsWithCompletedBackgroundJobs(Threads, TuplesInProcessing, NumberOfRecordsProcessed) Then
			WaitForThreadCompletion(Threads[0]);
		EndIf;
	EndDo;
	
EndProcedure

Function StopThreadsWithCompletedBackgroundJobs(Threads, TuplesInProcessing = Undefined, NumberOfRecordsProcessed = 0) Export
	
	HasCompletedThreads = False;
	
	IndexOf = Threads.Count() - 1;
	While IndexOf >= 0 Do
		Stream = Threads[IndexOf];
		JobID = Stream.JobID;
		
		If JobID <> Undefined Then
			JobCompleted = TimeConsumingOperations.JobCompleted(JobID);
		EndIf;
		
		If JobID = Undefined Or JobCompleted Then
			If ValueIsFilled(Stream.ResultAddress) Then
				Result = GetFromTempStorage(Stream.ResultAddress);
				If Result <> Undefined And Result.Property("NumberOfRecordsProcessed") Then
					NumberOfRecordsProcessed = NumberOfRecordsProcessed + Result.NumberOfRecordsProcessed;
				EndIf;
				DeleteFromTempStorage(Stream.ResultAddress);
			EndIf;
			Filter = New Structure("ThreadID",JobID);
			If TuplesInProcessing <> Undefined Then
				TuplesToDelete = TuplesInProcessing.FindRows(Filter);
				For Each Tuple In TuplesToDelete Do
					TuplesInProcessing.Delete(Tuple);
				EndDo;
			EndIf;
			Threads.Delete(IndexOf);
			HasCompletedThreads = True;
		EndIf;
		
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return HasCompletedThreads;
	
EndFunction

Function WaitForThreadCompletion(Stream, Duration = 1) Export
	
	If Stream <> Undefined And Stream.JobID <> Undefined Then
		Job = BackgroundJobs.FindByUUID(Stream.JobID);
		
		If Job <> Undefined Then
			Try
				Job.WaitForExecutionCompletion(Duration);
				Return True;
			Except
				// Special processing is not required, the exception may be caused by a timeout.
				Return False;
			EndTry;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

// Finds register adjustments based on the specified parameters, clears them and returns a new adjustment.
//
// Parameters:
//   AdjustmentPeriod_ - Date - All adjustments later than this date will be cleared, and with an equal date they will also be deleted.
//   Organization - CatalogRef.Companies
//   Operation - EnumRef.RegisterAdjustmentOperations
//
// Returns:
//   DocumentObject.RegisterAdjustment - An empty adjustment document, with the details filled in.
//
Function RegisterAdjustment(AdjustmentPeriod_, Organization, Operation) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	RegisterAdjustment.Ref AS Ref,
	|	RegisterAdjustment.Date AS Date
	|FROM
	|	Document.RegisterAdjustment AS RegisterAdjustment
	|WHERE
	|	RegisterAdjustment.Date >= &Date
	|	AND RegisterAdjustment.Operation = &Operation
	|	AND RegisterAdjustment.Organization = &Organization
	|ORDER BY
	|	RegisterAdjustment.Date ASC";
	Query.SetParameter("Date", EndOfMonth(AdjustmentPeriod_));
	Query.SetParameter("Operation", Operation);
	Query.SetParameter("Organization", Organization);
	
	AdjustingObject = Undefined;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		DocumentObject = Selection.Ref.GetObject(); // DocumentObject.RegisterAdjustment
		For Each Register In DocumentObject.RegistersTable Do
			RegisterRecords = DocumentObject.RegisterRecords[Register.Name]; // AccumulationRegisterRecordSet
			RegisterRecords.Write();
		EndDo;
		
		If Selection.Date = EndOfMonth(AdjustmentPeriod_) Then
			AdjustingObject = DocumentObject;
			AdjustingObject.SetDeletionMark(False);
		Else
			DocumentObject.Delete();
		EndIf;
		
	EndDo;
	
	If AdjustingObject = Undefined Then
		AdjustingObject = Documents.RegisterAdjustment.CreateDocument();
		AdjustingObject.Date        = AdjustmentPeriod_;
		AdjustingObject.Operation    = Operation;
		AdjustingObject.Organization = Organization;
		AdjustingObject.SetNewObjectRef(Documents.RegisterAdjustment.GetRef());
		
		NwRw = AdjustingObject.RegistersTable.Add();
		NwRw.Name = "CustomersARAPAccountingByDueDates";
		NwRw = AdjustingObject.RegistersTable.Add();
		NwRw.Name = "VendorsARAPAccountingByDueDates";
		
		AdjustingObject.Write();
	EndIf;
	
	Return AdjustingObject;
	
EndFunction

// A temp table for determining the availability of manual register adjustments 
// when checking the expanded balance and incorrect Balances.
// 
// Returns:
//  String - Query text
//
Function TextOfRequestTTManualAdjustments()
	
	Return "
	|SELECT
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	MAX(NestedQuery.Recorder) AS Recorder
	|INTO TTManualAdjustments
	|FROM
	|	(SELECT
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccountingByDueDates.ARAPObject            AS ARAPObject,
	|		CustomersARAPAccountingByDueDates.Recorder               AS Recorder
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|	WHERE
	|		CustomersARAPAccountingByDueDates.AccountingDimensionByPartners IN
	|			(SELECT
	|				T.AccountingDimensionByPartners
	|			FROM
	|				TTAnalytics_ AS T)
	|		AND CustomersARAPAccountingByDueDates.Active
	|		AND CustomersARAPAccountingByDueDates.Recorder REFS Document.RegisterAdjustment
	|		AND CAST(CustomersARAPAccountingByDueDates.Recorder AS Document.RegisterAdjustment).Operation = VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
	|		AND CustomersARAPAccountingByDueDates.Period <= &BegOfMonth
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners,
	|		VendorsARAPAccountingByDueDates.ARAPObject,
	|		VendorsARAPAccountingByDueDates.Recorder
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|	WHERE
	|		VendorsARAPAccountingByDueDates.AccountingDimensionByPartners IN
	|			(SELECT
	|				T.AccountingDimensionByPartners
	|			FROM
	|				TTAnalytics_ AS T)
	|		AND VendorsARAPAccountingByDueDates.Active
	|		AND VendorsARAPAccountingByDueDates.Recorder REFS Document.RegisterAdjustment
	|		AND CAST(VendorsARAPAccountingByDueDates.Recorder AS Document.RegisterAdjustment).Operation = VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
	|		AND VendorsARAPAccountingByDueDates.Period <= &BegOfMonth
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CustomersARAPAccounting.AccountingDimensionByPartners,
	|		CustomersARAPAccounting.ARAPObject,
	|		CustomersARAPAccounting.Recorder
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|	WHERE
	|		CustomersARAPAccounting.AccountingDimensionByPartners IN
	|			(SELECT
	|				T.AccountingDimensionByPartners
	|			FROM
	|				TTAnalytics_ AS T)
	|		AND CustomersARAPAccounting.Active
	|		AND CustomersARAPAccounting.Recorder REFS Document.RegisterAdjustment
	|		AND CAST(CustomersARAPAccounting.Recorder AS Document.RegisterAdjustment).Operation = VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
	|		AND CustomersARAPAccounting.Period <= &BegOfMonth
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VendorsARAPAccounting.AccountingDimensionByPartners,
	|		VendorsARAPAccounting.ARAPObject,
	|		VendorsARAPAccounting.Recorder
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|	WHERE
	|		VendorsARAPAccounting.AccountingDimensionByPartners IN
	|			(SELECT
	|				T.AccountingDimensionByPartners
	|			FROM
	|				TTAnalytics_ AS T)
	|		AND VendorsARAPAccounting.Active
	|		AND VendorsARAPAccounting.Recorder REFS Document.RegisterAdjustment
	|		AND CAST(VendorsARAPAccounting.Recorder AS Document.RegisterAdjustment).Operation = VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment)
	|		AND VendorsARAPAccounting.Period <= &BegOfMonth) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject
	|";
	
EndFunction

// Adds data on other income / expenses to movements 
// 
// Parameters:
// 	AdjustingObject - DocumentObject.RegisterAdjustment - A document object with already recorded movements based on calculations.
Procedure SupplementAdjustmentWithRegisteredRecordsInOtherIncomeExpenses(AdjustingObject) Export
	
	If AdjustingObject.RegistersTable.Find("OtherIncome","Name") = Undefined Then
		NwRw = AdjustingObject.RegistersTable.Add();
		NwRw.Name = "OtherIncome";
	EndIf;
	
	If AdjustingObject.RegistersTable.Find("OtherExpenses","Name") = Undefined Then
		NwRw = AdjustingObject.RegistersTable.Add();
		NwRw.Name = "OtherExpenses";
	EndIf;
	
	If AdjustingObject.RegistersTable.Find("OtherAssetsLiabilities","Name") = Undefined Then
		NwRw = AdjustingObject.RegistersTable.Add();
		NwRw.Name = "OtherAssetsLiabilities";
	EndIf;
	
	CurrentPeriodStart = EndOfMonth(AdjustingObject.Date)+1;
	
	Query = New Query;
	Query.SetParameter("AdjustingLink", AdjustingObject.Ref);
	Query.SetParameter("Period", CurrentPeriodStart);
	Query.SetParameter("IncomeItem", ChartsOfCharacteristicTypes.IncomeItems.ProfitLossOfPreviousYears);
	Query.SetParameter("ExpenseItem", ChartsOfCharacteristicTypes.ExpenseItems.ProfitLossOfPreviousYears);
	Query.SetParameter("CompanyManagementAccounting", CalculationOfCostCached.CompanyManagementAccounting(CurrentPeriodStart));
	Query.Text = "
	|SELECT
	|	&Period                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	NestedQuery.Organization             AS Organization,
	|	NestedQuery.Department           AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	&IncomeItem                          AS IncomeItem,
	|	NestedQuery.Organization             AS DimensionOfRevenue,
	|	SUM(NestedQuery.Sum)            AS Sum,
	|	SUM(NestedQuery.SumCompl)        AS SumCompl,
	|	SUM(CASE WHEN &CompanyManagementAccounting 
	|				THEN NestedQuery.SumMan
	|				ELSE 0
	|		END)                              AS SumMan
	|FROM (SELECT
	|		Calculations.AccountingDimensionByPartners.Organization             AS Organization,
	|		ISNULL(Calculations.ARAPObject.Department,
	|			VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|		Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		
	|		CASE WHEN Calculations.Debt < 0
	|			THEN -Calculations.Debt
	|			ELSE Calculations.Debt
	|		END +
	|		CASE WHEN Calculations.Prepayment < 0
	|			THEN -Calculations.Prepayment
	|			ELSE Calculations.Prepayment
	|		END                                                     AS Sum,
	|		CASE WHEN Calculations.DebtLocal < 0
	|			THEN -Calculations.DebtLocal
	|			ELSE Calculations.DebtLocal
	|		END +
	|		CASE WHEN Calculations.PrepaymentLocal < 0
	|			THEN -Calculations.PrepaymentLocal
	|			ELSE Calculations.PrepaymentLocal
	|		END                                                     AS SumCompl,
	|		CASE WHEN Calculations.ARAPMan < 0
	|			THEN -Calculations.ARAPMan
	|			ELSE Calculations.ARAPMan
	|		END +
	|		CASE WHEN Calculations.PrepaymentMan < 0
	|			THEN -Calculations.PrepaymentMan
	|			ELSE Calculations.PrepaymentMan
	|		END                                                     AS SumMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|	WHERE
	|		Calculations.Active
	|		AND Calculations.Recorder = &AdjustingLink
	|		AND ((Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND (Calculations.Prepayment > 0 OR Calculations.Debt < 0))
	|			OR (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND (Calculations.Debt > 0 OR Calculations.Prepayment < 0)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization             AS Organization,
	|		ISNULL(Calculations.ARAPObject.Department,
	|			VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|		Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		
	|		CASE WHEN Calculations.Debt < 0
	|				THEN -Calculations.Debt
	|			ELSE Calculations.Debt
	|		END +
	|		CASE WHEN Calculations.Prepayment < 0
	|			THEN -Calculations.Prepayment
	|			ELSE Calculations.Prepayment
	|		END                                                     AS Sum,
	|		CASE WHEN Calculations.DebtLocal < 0
	|			THEN -Calculations.DebtLocal
	|			ELSE Calculations.DebtLocal
	|		END +
	|		CASE WHEN Calculations.PrepaymentLocal < 0
	|			THEN -Calculations.PrepaymentLocal
	|			ELSE Calculations.PrepaymentLocal
	|		END                                                     AS SumCompl,
	|		CASE WHEN Calculations.ARAPMan < 0
	|			THEN -Calculations.ARAPMan
	|			ELSE Calculations.ARAPMan
	|		END +
	|		CASE WHEN Calculations.PrepaymentMan < 0
	|			THEN -Calculations.PrepaymentMan
	|			ELSE Calculations.PrepaymentMan
	|		END                                                     AS SumMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|	WHERE	
	|		Calculations.Active
	|		AND Calculations.Recorder = &AdjustingLink
	|		AND ((Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND (Calculations.Prepayment > 0 OR Calculations.Debt < 0))
	|			OR (Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND (Calculations.Debt > 0 OR Calculations.Prepayment < 0)))) AS NestedQuery
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness
	|;
	|SELECT
	|	&Period                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	NestedQuery.Organization             AS Organization,
	|	NestedQuery.Department           AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	&ExpenseItem                         AS ExpenseItem,
	|	NestedQuery.Organization             AS DimensionOfExpenses,
	|	SUM(NestedQuery.Sum)            AS Sum,
	|	SUM(NestedQuery.Sum)            AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumCompl)        AS SumCompl,
	|	SUM(CASE WHEN &CompanyManagementAccounting
	|				THEN NestedQuery.SumMan
	|				ELSE 0
	|		END)                              AS SumMan,
	|	0                                       AS PermanentDifference,
	|	0                                       AS CostTD
	|FROM (SELECT
	|		Calculations.AccountingDimensionByPartners.Organization             AS Organization,
	|		ISNULL(Calculations.ARAPObject.Department,
	|			VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|		Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		
	|		CASE WHEN Calculations.Debt < 0
	|			THEN -Calculations.Debt
	|			ELSE Calculations.Debt
	|		END +
	|		CASE WHEN Calculations.Prepayment < 0
	|			THEN -Calculations.Prepayment
	|			ELSE Calculations.Prepayment
	|		END                                                     AS Sum,
	|		CASE WHEN Calculations.DebtLocal < 0
	|			THEN -Calculations.DebtLocal
	|			ELSE Calculations.DebtLocal
	|		END +
	|		CASE WHEN Calculations.PrepaymentLocal < 0
	|			THEN -Calculations.PrepaymentLocal
	|			ELSE Calculations.PrepaymentLocal
	|		END                                                     AS SumCompl,
	|		CASE WHEN Calculations.ARAPMan < 0
	|			THEN -Calculations.ARAPMan
	|			ELSE Calculations.ARAPMan
	|		END +
	|		CASE WHEN Calculations.PrepaymentMan < 0
	|			THEN -Calculations.PrepaymentMan
	|			ELSE Calculations.PrepaymentMan
	|		END                                                     AS SumMan
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|	WHERE
	|		Calculations.Active
	|		AND Calculations.Recorder = &AdjustingLink
	|		AND ((Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND (Calculations.Prepayment > 0 OR Calculations.Debt < 0))
	|			OR (Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND (Calculations.Debt > 0 OR Calculations.Prepayment < 0)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Calculations.AccountingDimensionByPartners.Organization             AS Organization,
	|		ISNULL(Calculations.ARAPObject.Department,
	|			VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|		Calculations.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|		
	|		CASE WHEN Calculations.Debt < 0
	|				THEN -Calculations.Debt
	|			ELSE Calculations.Debt
	|		END +
	|		CASE WHEN Calculations.Prepayment < 0
	|			THEN -Calculations.Prepayment
	|			ELSE Calculations.Prepayment
	|		END                                                     AS Sum,
	|		CASE WHEN Calculations.DebtLocal < 0
	|			THEN -Calculations.DebtLocal
	|			ELSE Calculations.DebtLocal
	|		END +
	|		CASE WHEN Calculations.PrepaymentLocal < 0
	|			THEN -Calculations.PrepaymentLocal
	|			ELSE Calculations.PrepaymentLocal
	|		END                                                     AS SumCompl,
	|		CASE WHEN Calculations.ARAPMan < 0
	|			THEN -Calculations.ARAPMan
	|			ELSE Calculations.ARAPMan
	|		END +
	|		CASE WHEN Calculations.PrepaymentMan < 0
	|			THEN -Calculations.PrepaymentMan
	|			ELSE Calculations.PrepaymentMan
	|		END                                                     AS SumMan
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS Calculations
	|	WHERE	
	|		Calculations.Active
	|		AND Calculations.Recorder = &AdjustingLink
	|		AND ((Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND (Calculations.Prepayment > 0 OR Calculations.Debt < 0))
	|			OR (Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND (Calculations.Debt > 0 OR Calculations.Prepayment < 0)))) AS NestedQuery
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness
	|";
	
	Results = Query.ExecuteBatch();
	
	Income = Results[0].Unload();
	Expenses = Results[1].Unload();
	
	RevenueRegisteredRecords = AdjustingObject.RegisterRecords.OtherIncome;
	RevenueRegisteredRecords.Load(Income);
	RevenueRegisteredRecords.Write();
	
	OtherExpenses_ = AdjustingObject.RegisterRecords.OtherExpenses;
	OtherExpenses_.Load(Expenses);
	OtherExpenses_.Write();
	
	AdjustingObject.Write();
	
	ManagementAccountingPostingServer.UpdateRegisteredRecordsOfAssetsLiabilities(AdjustingObject.Ref, AdjustingObject.RegisterRecords);
	
	AssetsLiabilities = AdjustingObject.RegisterRecords.OtherAssetsLiabilities.Unload();
	AssetsLiabilities.FillValues(CurrentPeriodStart, "Period");
	AdjustingObject.RegisterRecords.OtherAssetsLiabilities.Load(AssetsLiabilities);
	AdjustingObject.RegisterRecords.OtherAssetsLiabilities.Write();
	
EndProcedure

//Returns a table of calculations for which there are movements on the resources "Money", "Kopete", "Katruska"
//
//	Returns:
//		ValueTable - See the Distribution table - a table of all tuples of analytics and AR/AP objects to be recalculated.
//
Function GetAllObjects()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS Currency,
	|	DATETIME(1,1,1) AS RecalculationStartDate,
	|	DATETIME(3999,1,1) AS PeriodForMonitoringChangesAndCreatingTasks,
	|
	|	Calculations.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	Calculations.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|	Calculations.CurrencyReceiver AS CurrencyReceiver,
	|	Calculations.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	MIN(Calculations.Recorder) AS Document
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS RelatedSettlementsWithCustomers
	|			ON RelatedSettlementsWithCustomers.AccountingDimensionByPartners = Calculations.DestinationAccountingDimensionByPartners
	|			AND RelatedSettlementsWithCustomers.ARAPObject = Calculations.CalculationObjectReceiver
	|			AND RelatedSettlementsWithCustomers.Currency = Calculations.CurrencyReceiver
	|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS RelatedSettlementsWithSuppliers
	|			ON RelatedSettlementsWithSuppliers.AccountingDimensionByPartners = Calculations.DestinationAccountingDimensionByPartners
	|			AND RelatedSettlementsWithSuppliers.ARAPObject = Calculations.CalculationObjectReceiver
	|			AND RelatedSettlementsWithSuppliers.Currency = Calculations.CurrencyReceiver
	|WHERE
	|	(Calculations.Sum <> 0 OR Calculations.AmountDue <> 0 OR Calculations.ToShip <> 0)
	|	AND Calculations.Active
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners ,
	|	Calculations.ARAPObject ,
	|	Calculations.Currency ,
	|	Calculations.CalculationObjectReceiver ,
	|	Calculations.DestinationAccountingDimensionByPartners ,
	|	Calculations.CurrencyReceiver ,
	|	Calculations.ByDataOfSourceARAPObject
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS Currency,
	|	DATETIME(1,1,1) AS RecalculationStartDate,
	|	DATETIME(3999,1,1) AS PeriodForMonitoringChangesAndCreatingTasks,
	|
	|	Calculations.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	Calculations.DestinationAccountingDimensionByPartners AS DestinationAccountingDimensionByPartners,
	|	Calculations.CurrencyReceiver AS CurrencyReceiver,
	|	Calculations.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	MIN(Calculations.Recorder) AS Document
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS RelatedSettlementsWithCustomers
	|			ON RelatedSettlementsWithCustomers.AccountingDimensionByPartners = Calculations.DestinationAccountingDimensionByPartners
	|			AND RelatedSettlementsWithCustomers.ARAPObject = Calculations.CalculationObjectReceiver
	|			AND RelatedSettlementsWithCustomers.Currency = Calculations.CurrencyReceiver
	|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS RelatedSettlementsWithSuppliers
	|			ON RelatedSettlementsWithSuppliers.AccountingDimensionByPartners = Calculations.DestinationAccountingDimensionByPartners
	|			AND RelatedSettlementsWithSuppliers.ARAPObject = Calculations.CalculationObjectReceiver
	|			AND RelatedSettlementsWithSuppliers.Currency = Calculations.CurrencyReceiver
	|WHERE
	|	(Calculations.Sum <> 0 OR Calculations.AmountDue <> 0 OR Calculations.ToReceive <> 0)
	|	AND Calculations.Active
	|GROUP BY
	|	Calculations.AccountingDimensionByPartners ,
	|	Calculations.ARAPObject ,
	|	Calculations.Currency ,
	|	Calculations.CalculationObjectReceiver ,
	|	Calculations.DestinationAccountingDimensionByPartners ,
	|	Calculations.CurrencyReceiver ,
	|	Calculations.ByDataOfSourceARAPObject
	|";
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure ReflectOrderStates(ProcessedOneData)
	
	Query = New Query;
	Query.SetParameter("ProcessedOneData", ProcessedOneData);
	Query.Text = "
	|SELECT
	|	Table.ARAPObject AS ARAPObject,
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|INTO TTProcessedOneData
	|FROM
	|	&ProcessedOneData AS Table
	|
	|;
	|
	|SELECT
	|	ARAPObjects.Object AS ProcessedDocument
	|FROM
	|	TTProcessedOneData AS Table
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Ref = Table.ARAPObject
	|WHERE
	|	ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|
	|UNION ALL
	|
	|SELECT 
	|	CustomersARAPAccounting.SaleByOrder AS ProcessedDocument
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = CustomersARAPAccounting.SaleByOrder
	|		AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	(CustomersARAPAccounting.AccountingDimensionByPartners, CustomersARAPAccounting.ARAPObject)
	|	IN (SELECT T.AccountingDimensionByPartners, T.ARAPObject FROM TTProcessedOneData AS T)
	|	AND CustomersARAPAccounting.SaleByOrder <> UNDEFINED
	|
	|UNION ALL
	|
	|SELECT 
	|	VendorsARAPAccounting.PurchaseByOrder AS ProcessedDocument
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = VendorsARAPAccounting.PurchaseByOrder
	|		AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	(VendorsARAPAccounting.AccountingDimensionByPartners, VendorsARAPAccounting.ARAPObject)
	|	IN (SELECT T.AccountingDimensionByPartners, T.ARAPObject FROM TTProcessedOneData AS T)
	|	AND VendorsARAPAccounting.PurchaseByOrder <> UNDEFINED
	|";
	
	DocumentsArray = Query.Execute().Unload().UnloadColumn("ProcessedDocument");
	
	RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
	RegistersToBeReflected.SalesOrderStates    = True;
	RegistersToBeReflected.PurchaseOrderStates = True;
	
	DocumentsStates.AddTasksToStateOfOrders(Undefined, DocumentsArray,, RegistersToBeReflected);
	
EndProcedure

Function EventLogEventName()
	
	Return NStr("ru = 'Взаиморасчеты';
				|vi = 'AR/AP accounting';
				|en = 'AR/AP accounting'; fa = 'حسابداری دریافتنی/پرداختنی';
				|it = 'AR/AP accounting';
				|pl = 'AR/AP accounting';
				|tr = 'Alacak/Borç muhasebesi'", Common.DefaultLanguageCode());
	
EndFunction

// Returns the financial accounting group for the Contract
Function FAGByContract(Contract, ParametersStructure)
	
	If TypeOf(Contract) = Type("CatalogRef.IntercompanyContracts")
		And ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
		NameOfAttributeFAG = "FinancialAccountingGroupOfRecipient";
	Else
		NameOfAttributeFAG = "FinancialAccountingGroup";
	EndIf;
	
	FinancialAccountingGroup = Common.ObjectAttributeValue(Contract, NameOfAttributeFAG);
	
	Return FinancialAccountingGroup;
	
EndFunction

// Returns an array of these Orders for an INVOICE for MULTIPLE Orders
//
// Parameters:
//  Object - DocumentObject, CatalogObject, ClientApplicationForm - Order search OBJECT
//  ParametersStructure - See ARAPAccountingServer.MechanismParameters
// 
// Returns:
//  Array of DocumentRef
Function GetArrayOfOrdersFromTS(Object, ParametersStructure) Export
	
	AnArrayOfOrders = New Array;
	TS = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData);
	If ValueIsFilled(TS) And ValueIsFilled(ParametersStructure.PropsNameTSOrder) Then
		Orders = TS.Unload(, ParametersStructure.PropsNameTSOrder);
		Orders.GroupBy(ParametersStructure.PropsNameTSOrder,);
		AnArrayOfOrders = Orders.UnloadColumn(ParametersStructure.PropsNameTSOrder);
		
		Cnt = 0;
		While Cnt < AnArrayOfOrders.Count() Do
			If Not ValueIsFilled(AnArrayOfOrders[Cnt]) Then
				AnArrayOfOrders.Delete(Cnt);
			Else
				Cnt= Cnt + 1;
			EndIf;
		EndDo;
	EndIf;
	
	Return AnArrayOfOrders;
	
EndFunction

Procedure Check_Parameters(ParametersStructure, RequiredParameters2)
	
	Parameters = StrSplit(RequiredParameters2, ",");
	For Each Parameter In Parameters Do
		If Not ValueIsFilled(ParametersStructure[TrimAll(Parameter)]) Then
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đường dẫn đến tham số bắt buộc %1 không được điền vào mô-đun trình quản lý chứng từ';
					|ru = 'В модуле менеджера документа не заполнен путь к необходимому параметру %1';
					|en = 'Path to the required parameter %1 is not specified in the document manager module'; fa = 'Path to the required parameter %1 is not specified in the document manager module';
					|it = 'Nel modulo di manager del documento non è compilato il percorso al parametro necessario %1';
					|pl = 'W module menedżera dokumentu nie wypełniono ścieżki do potrzebnego parametru%1';
					|tr = '%1 gerekli parametresine yol, belge yöneticisi modülünde doldurulmadı'"),
				TrimAll(Parameter)))
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
