#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the name of a constant that stores the task number for this register.
//
// Returns:
//	String - String representation of the name of the constant of the task number of the closing month.
//
Function NameOfJobNumberConstant() Export
	
	Return Metadata.Constants.NumberOfJobForMonthEndClosing.Name;
	
EndFunction

// Increases the task number in a constant.
//
// Returns:
//	Number - The previous task number from the constant "Task number by the end of the month".
//
Function IncreaseTaskNumber() Export
	
	Return MonthEndTransactionsServer.IncreaseTaskNumber(NameOfJobNumberConstant());
	
EndFunction

// Returns the task number from a constant.
//
// Returns:
//	Number - The number of the current task from the constant "The number of the task to close the month".
//
Function GetTaskNumber() Export
	
	Return MonthEndTransactionsServer.CurTaskNumber(NameOfJobNumberConstant());
	
EndFunction

// This method creates a register entry with the specified parameters.
//
// Parameters:
//	TaskPeriod   - Date - Start of the period for which you need to register a task for calculation
//	DocumentJobs - DocumentRef - document the Registrar who created the movement in the dependent registers
//	Organization - CatalogRef.Companies - organization that needs to be recalculated
//  Operation - CatalogRef.MonthEndClosingOperations - routine operation 
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set.
//
Procedure CreateRegisterEntry(TaskPeriod, DocumentJobs = Undefined, Organization = Undefined,
				Operation = Undefined, JobNumber = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(DocumentJobs) And Not ValueIsFilled(Organization) Then
		
		// Creating a task for each information security organization
		CompanyArray = Catalogs.Companies.AvailableCompanies();
		
	Else
		
		CompanyArray = New Array;
		
		If Not ValueIsFilled(Organization) Then
			// Let's try to define the default organization.
			// If it fails, a platform exception will be thrown when writing.
			CompanyArray.Add(Catalogs.Companies.DefaultCompany());
		Else
			CompanyArray.Add(Organization);
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Operation) Then
		
		// Create a task for each possible operation
		OperationArray = New Array;
		
		SelectionOfOperations = Catalogs.MonthEndClosingOperations.Select();
		
		While SelectionOfOperations.Next() Do
			OperationArray.Add(SelectionOfOperations.Ref);
		EndDo;
		
	Else
		
		OperationArray = TMCommonUseClientServer.Array(Operation)
		
	EndIf;
	
	// Let's write down the tasks.
	RecordSetSet = InformationRegisters.JobsForMonthEndClosing.CreateRecordSet();
	
	Try
		
		If JobNumber = Undefined Then
			JobNumber = GetTaskNumber();
		EndIf;
		
		For Each CurrentCompany In CompanyArray Do
			
			For Each CurrentOperation In OperationArray Do
				
				Month = MonthEndTransactionsServer.TaskDateForCurPeriod(CurrentOperation, CurrentCompany, DocumentJobs, TaskPeriod);
				
				RecordSet = RecordSetSet.Add();
				RecordSet.Month        = Month;
				RecordSet.Operation     = CurrentOperation;
				RecordSet.Organization  = CurrentCompany;
				RecordSet.Document     = DocumentJobs;
				RecordSet.JobNumber = JobNumber;
				
			EndDo;
			
		EndDo;
		
		If RecordSetSet.Count() > 0 Then
			RecordSetSet.Write(ReplacementMode.Merge);
		EndIf;
		
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
		Raise ErrorText;
	EndTry;
	
EndProcedure

// This method creates register entries with the parameters received by the request.
//
// Parameters:
//	Selection - QueryResultSelection - a sample of the data to generate the records.
//  JobNumber - Number - task number; if omitted, the value from the corresponding constant will be set.
//
Procedure CreateRegisterEntriesBasedOnSampleData(Selection, JobNumber = Undefined) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		FieldsStructure = New Structure("Month, Organization, Operation, Document");
		
		If JobNumber = Undefined Then
			JobNumber = GetTaskNumber();
		EndIf;
		
		While Selection.Next() Do
			
			FillPropertyValues(FieldsStructure, Selection);
			
			CreateRegisterEntry(FieldsStructure.Month, FieldsStructure.Document, FieldsStructure.Organization, FieldsStructure.Operation, JobNumber);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText    = DetailErrorDescription(ErrorInfo());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo tác vụ đóng tháng cho %1 trong doanh nghiệp %2 do: %3';
				|ru = 'Не удалось сформировать задание к закрытию месяца за %1 в организации %2 по причине: %3';
				|en = 'Cannot generate the job for month-end closing for %1 in company %2. Reason: %3'; fa = 'Cannot generate the job for month-end closing for %1 in company %2. Reason: %3';
				|it = 'Impossibile creare un''attività per la chiusura del mese per %1 l''organizzazione %2 a causa di:%3';
				|pl = 'Nie udało się utworzyć zadanie do zamknięcia miesiąca za %1 w firmie %2 z powodu: %3';
				|tr = '%3''ten dolayı %2 iş yerinde %1 ay sonu kapanışı için bir görev oluşturulamadı'"),
			Selection.Month,
			Selection.Organization,
			ErrorText);
			
		WriteLogEvent(NStr("vi = 'Kết chuyển cuối tháng';
							|ru = 'Закрытие месяца';
							|en = 'Month-end closing'; fa = 'بستن پایان ماه';
							|it = 'Chiusura del mese';
							|pl = 'Zamknięcie miesiąca';
							|tr = 'Ay sonu kapanışı'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , MessageText);
		
	EndTry;
	
EndProcedure

// The method clears all jobs for the specified operation.
//
// Parameters:
//	Operation - CatalogRef.MonthEndClosingOperations - operation to clear tasks
//
Procedure DeleteRecordsByOperation(Operation) Export
	
	RecordSet = InformationRegisters.JobsForMonthEndClosing.CreateRecordSet();
	RecordSet.Filter.Operation.Set(Operation);
	RecordSet.Write(True);
	
EndProcedure

// In rib, month closure is performed only in the master node, while
// register entries are sent from the slave nodes to the master node. When receiving records from the PO in the GU,
// they are registered with the current task number of the GU. When the PO receives a receipt for receiving
// data from the GU, the register entries in the PO are removed from registration for exchange and deleted, because
// they cannot be deleted by regular means (after the month is closed, or when they are deleted from the GU) in the PO.
//
Procedure DeleteRecordsInRibSlaveNode() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	JobsForMonthEndClosing.Month AS Month,
		|	JobsForMonthEndClosing.Operation AS Operation,
		|	JobsForMonthEndClosing.Organization AS Organization,
		|	JobsForMonthEndClosing.Document AS Document,
		|	JobsForMonthEndClosing.JobNumber AS JobNumber
		|FROM
		|	InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
		|		LEFT JOIN InformationRegister.JobsForMonthEndClosing.Changes AS JobsForMonthEndClosingChanges
		|		ON JobsForMonthEndClosing.Month = JobsForMonthEndClosingChanges.Month
		|			AND JobsForMonthEndClosing.Organization = JobsForMonthEndClosingChanges.Organization
		|			AND JobsForMonthEndClosing.Operation = JobsForMonthEndClosingChanges.Operation
		|			AND JobsForMonthEndClosing.Document = JobsForMonthEndClosingChanges.Document
		|			AND JobsForMonthEndClosing.JobNumber = JobsForMonthEndClosingChanges.JobNumber
		|WHERE
		|	JobsForMonthEndClosingChanges.Month IS NULL";
	
	QueryResult = Query.Execute();
	
	RecordsTable = QueryResult.Unload();
	For Cnt = 1-RecordsTable.Count() To 0 Do
		Selection = RecordsTable[-Cnt];
		RecordSet = InformationRegisters.JobsForMonthEndClosing.CreateRecordSet();
		RecordSet.Filter.Month.Set(Selection.Month);
		RecordSet.Filter.Organization.Set(Selection.Organization);
		RecordSet.Filter.Operation.Set(Selection.Operation);
		RecordSet.Filter.Document.Set(Selection.Document);
		RecordSet.Filter.JobNumber.Set(Selection.JobNumber);
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		RecordSet.DataExchange.Load = True;
		RecordSet.Write();
	EndDo;
	
EndProcedure

// Creates tasks for the next period.
//
// Parameters:
//  TemporaryTable	- TempTablesManager - Contains a table of cache Borders.
//  NextMonth		- Date - The date from which the tasks should be generated.
//
Procedure CreateTasksForNextPeriod(TemporaryTable, NextMonth) Export

	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	Jobs.Operation,
	|	Jobs.Organization,
	|	MAX(Jobs.JobNumber) AS JobNumber
	|FROM
	|	BorderCache AS Jobs
	|
	|GROUP BY
	|	Jobs.Operation,
	|	Jobs.Organization";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TemporaryTable;
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		NextPeriod = MonthEndTransactionsServer.TaskDateForNextPeriod(Selection.Operation, Selection.Organization, Undefined, NextMonth);
		
		If ValueIsFilled(NextPeriod) Then
			NewRecord = InformationRegisters.JobsForMonthEndClosing.CreateRecordManager();
			FillPropertyValues(NewRecord, Selection);
			NewRecord.Month = NextPeriod;
			NewRecord.Write(True);
		EndIf; 
		
	EndDo;
	
EndProcedure

// Adds descriptions of registers for connecting them to the no-change date mechanism.
//
// Parameters:
//  DataSources - ValueTable - see the description in the BSP mechanism.
//
Procedure DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources) Export

	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.RecordsCashIncomeExpenses.FullName(),
										"Period",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.FullName(),
										"Period",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.BankAccountCash.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.CashInCashRegistersCR.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.CashInTransit.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.CashAccountBalance.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.AdvanceHolderCash.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.ItemisedExpensesLots.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.FinancialInstrumentsARAP.FullName(),
										"Period",
										"FinancialOutline");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.RevenueServicesAndAssets.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	MonthEndTransactionsLocalization.SupplementDescriptionOfRegistersForMonitoringDatesOfProhibitionOfChanges(DataSources);
EndProcedure

// Returns a list of metadata objects that are used for generating register entries.
// 
// Parameters:
//  Operation - CatalogRef.MonthEndClosingOperations - Operation
// 
// Returns:
//  Array of MetadataObject - Incoming Mechanism Data
Function IncomingMechanismData(Operation = Undefined) Export
	
	IncomingData = New Array;
	
	If Operation = Undefined
		Or Operation = Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets
		Then
		
		IncomingData.Add(Metadata.AccumulationRegisters.OtherExpenses);
		IncomingData.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets);
	EndIf;
	
	Return IncomingData;
	
EndFunction

#EndRegion

#Region Private

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.JobsForMonthEndClosing.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.32";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("6fba64e6-493d-4268-8dfa-693e979e7a89");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.JobsForMonthEndClosing.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Điền chiều đo Giao dịch bởi giá trị có kiểu ""%1"".';
			|ru = 'Заполняет измерение Операция значением с типом ""%1"".';
			|en = 'Fills the Operation dimension with a value of the ""%1"" type.'; fa = 'Fills the Operation dimension with a value of the ""%1"" type.';
			|it = 'Fills the Operation dimension with a value of the ""%1"" type.';
			|pl = 'Fills the Operation dimension with a value of the ""%1"" type.';
			|tr = 'İşlem boyutunu ""%1"" tipindeki değerle doldurur.'", Common.DefaultLanguageCode()),
		Metadata.Catalogs.MonthEndClosingOperations.FullName());
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.JobsForMonthEndClosing.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.JobsForMonthEndClosing.FullName());
	
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	IsEmptySet = CreateRecordSet();
	FullRegisterName = IsEmptySet.Metadata().FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Jobs.Month,
	|	Jobs.Organization,
	|	Jobs.DeleteUseOperation,
	|	Jobs.Document,
	|	Jobs.JobNumber
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|WHERE
	|	Jobs.Operation = VALUE(Catalog.MonthEndClosingOperations.EmptyRef)
	|	AND Jobs.DeleteUseOperation <> VALUE(Enum.DeleteMonthEndClosingOperations.EmptyRef)";
	
	Selection= Query.Execute().Select();
	
	Batch = IsEmptySet.Unload(, "Month, Organization, DeleteUseOperation, Document, JobNumber");
	
	Counter = 0;
	
	While Selection.Next() Do
		FillPropertyValues(Batch.Add(), Selection);
		Counter = Counter + 1;

		If Counter = 1000 Then
			InfobaseUpdate.MarkForProcessing(Parameters, Batch, AdditionalParameters);
			Batch.Clear();
			Counter = 0;
		EndIf;
		
	EndDo;
	
	If Batch.Count() > 0 Then
		InfobaseUpdate.MarkForProcessing(Parameters, Batch, AdditionalParameters);
	EndIf;

EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	RegisterMetadata = CreateRecordSet().Metadata();
	
	FullObjectName = RegisterMetadata.FullName();
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	MonthEndClosingOperations.Ref,
	|	MonthEndClosingOperations.PredefinedDataName
	|FROM
	|	Catalog.MonthEndClosingOperations AS MonthEndClosingOperations";
	
	SelectionOfMonthClosingOperations = Query.Execute().Select();
	
	MatchingOperations = New Map();
	
	While SelectionOfMonthClosingOperations.Next() Do
		MatchingOperations.Insert(
			SelectionOfMonthClosingOperations.PredefinedDataName,
			SelectionOfMonthClosingOperations.Ref);
	EndDo;

	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý nhiệm vụ theo hàm sự kiện của biểu ghi thông tin ""%1"".';
				|ru = 'Не удалось обработать задания по обработчику регистра сведений  ""%1"".';
				|en = 'Cannot process the jobs of the ""%1"" information register handler.'; fa = 'Cannot process the jobs of the ""%1"" information register handler.';
				|it = 'Cannot process the jobs of the ""%1"" information register handler.';
				|pl = 'Cannot process the jobs of the ""%1"" information register handler.';
				|tr = '""%1"" bilgi kayıt işleyicisi kapsamında görevler işlenemedi.'",
				Common.DefaultLanguageCode()),
					FullObjectName));
		
	For Each Selection In UpdatedData Do
		
		ExceptionReason = "";
			
		BeginTransaction();
		
		Try
			
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Month.Set(Selection.Month);
			RecordSet.Filter.Organization.Set(Selection.Organization);
			RecordSet.Filter.DeleteUseOperation.Set(Selection.DeleteUseOperation);
			RecordSet.Filter.Document.Set(Selection.Document);
			RecordSet.Filter.JobNumber.Set(Selection.JobNumber);
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			// Blocking of the register "Tasks for the distribution of calculations".
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Month", Selection.Month);
			LockItem.SetValue("Organization", Selection.Organization);
			LockItem.SetValue("DeleteUseOperation", Selection.DeleteUseOperation);
			LockItem.SetValue("Document", Selection.Document);
			LockItem.SetValue("JobNumber", Selection.JobNumber);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			ExceptionReason = "DataProcessor data_";

			RecordSet.Read();
			
			For Each Record In RecordSet Do

				If Not ValueIsFilled(Selection.Operation) Then
					Record.Operation = MatchingOperations.Get(XMLString(Record.DeleteUseOperation));
				EndIf;

			EndDo;
			
			ExceptionReason = "Record";
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();

		Except

			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			FilterAsString = String(RecordSet.Filter);
			
			MessageText = NStr("vi = 'Không thể xử lý tập hợp bản ghi %Set% của biểu ghi
										|""Nhiệm vụ phân bổ thanh toán"" do nguyên nhân: %Cause%';
										|ru = 'Не удалось обработать набор записей %Set% регистра 
										|""Задания к распределению расчетов"" по причине:  по причине: %Cause%';
										|en = 'Cannot process the %Set% record set of the 
										|""Jobs for allocating AR/AP"" register. Reason: %Cause%'; fa = 'Cannot process the %Set% record set of the 
										|""Jobs for allocating AR/AP"" register. Reason: %Cause%';
										|it = 'Cannot process the %Set% record set of the 
										|""Jobs for allocating AR/AP"" register. Reason: %Cause%';
										|pl = 'Cannot process the %Set% record set of the 
										|""Jobs for allocating AR/AP"" register. Reason: %Cause%';
										|tr = '""Hesaplamaların dağıtım görevleri"" kaydının %Set% kayıt kümesi
										|şu nedenden dolayı işlenemedi: %Cause%'");
			MessageText = StrReplace(MessageText, "%Set%", FilterAsString);
			MessageText = StrReplace(MessageText, "%Cause%", 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
									EventLogLevel.Warning,
									RegisterMetadata,
									FilterAsString,
									MessageText);

			If ExceptionReason = "DataProcessor data_" Then

				InfobaseUpdate.MarkProcessingCompletion(RecordSet);

			ElsIf ExceptionReason = "Record" Then

				Raise StrConcat(ListOfDescriptions, Chars.LF);

			EndIf;
			
		EndTry;

	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then

		ListOfDescriptions.Add(NStr("vi = 'Tổng số bỏ qua: %1';
									|ru = 'Всего пропущено: %1';
									|en = 'Skipped: %1'; fa = 'Skipped: %1';
									|it = 'Всего пропущено: %1';
									|pl = 'Skipped: %1';
									|tr = 'Toplam atlanan: %1'"));
		MessageText = StrTemplate(StrConcat(ListOfDescriptions, Chars.LF), ObjectsWithIssuesCount);
		Raise MessageText;

	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndIf
