#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region CompletedCalculations

Function GetInformationAboutStageCompletion(CompanyArray, CalculationPeriod, Operation) Export
	
	Result = New Structure("StartDate, EndDate, HadErrors");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ISNULL(MIN(Statistics.StartDate), UNDEFINED) 		AS StartDate,
	|	ISNULL(MAX(Statistics.EndDate), UNDEFINED) 	AS EndDate,
	|	ISNULL(MAX(Statistics.HadErrors), FALSE) 		   	AS HadErrors
	|FROM
	|	InformationRegister.PerformMonthEndClosingOperations AS Statistics
	|WHERE
	|	Statistics.Organization IN(&CompanyArray)
	|	AND Statistics.CalculationPeriod = &CalculationPeriod
	|	AND Statistics.Operation = &Operation
	|	AND NOT Statistics.CalculationIsInProgress";
	
	Query.SetParameter("CompanyArray", OrganizationsToCalculate(CompanyArray));
	Query.SetParameter("CalculationPeriod", 	   CalculationPeriod);
	Query.SetParameter("Operation", 		   Operation);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Selection.Next();
	
	FillPropertyValues(Result, Selection);
	
	Return Result;
	
EndFunction

Procedure SaveStageCompletionInformation(CompanyArray, CalculationPeriod, DescriptionOfStageExecution, HadErrors) Export
	
	SetPrivilegedMode(True);
	
	If MonthEndTransactionsServer.SimplifiedAutoTesting() Then
		
		// Performed for all organizations
		RecordSet = InformationRegisters.PerformMonthEndClosingOperations.CreateRecordSet();
		
		RecordSet.Filter.CalculationPeriod.Set(CalculationPeriod);
		RecordSet.Filter.Operation.Set(DescriptionOfStageExecution.Operation);
		RecordSet.Filter.CalculationIsInProgress.Set(False);
			
		For Each CurrentCompany In OrganizationsToCalculate(CompanyArray) Do
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, DescriptionOfStageExecution);
			
			Record.Organization 	     = CurrentCompany;
			Record.CalculationPeriod     = CalculationPeriod;
			Record.HadErrors 	     = HadErrors;
			Record.CalculationIsInProgress = False;
			
		EndDo;
		
		RecordSet.Write(True);
		
	Else
		
		For Each CurrentCompany In OrganizationsToCalculate(CompanyArray) Do
			
			RecordSet = InformationRegisters.PerformMonthEndClosingOperations.CreateRecordSet();
			
			RecordSet.Filter.Organization.Set(CurrentCompany);
			RecordSet.Filter.CalculationPeriod.Set(CalculationPeriod);
			RecordSet.Filter.Operation.Set(DescriptionOfStageExecution.Operation);
			RecordSet.Filter.CalculationIsInProgress.Set(False);
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, DescriptionOfStageExecution);
			
			Record.Organization 	     = CurrentCompany;
			Record.CalculationPeriod     = CalculationPeriod;
			Record.HadErrors 	     = HadErrors;
			Record.CalculationIsInProgress = False;
			
			RecordSet.Write(True);
			
		EndDo;
		
	EndIf;
	
	MeasurementData = New Structure("StartDate, EndDate, Duration");
	FillPropertyValues(MeasurementData, DescriptionOfStageExecution);
	
	TextForLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thời gian chung: %1
			|Ngày bắt đầu: %2
			|Ngày kết thúc: %3
			|Doanh nghiệp: %4';
			|ru = 'Общее время: %1
			|Дата начала: %2
			|Дата окончания: %3
			|Организации: %4';
			|en = 'Total time: %1
			|Start date: %2
			|End date: %3
			|Companies: %4'; fa = 'Total time: %1
			|Start date: %2
			|End date: %3
			|Companies: %4';
			|it = 'Общее время: %1
			|Дата начала: %2
			|Дата окончания: %3
			|Организации: %4';
			|pl = 'Total time: %1
			|Start date: %2
			|End date: %3
			|Companies: %4';
			|tr = 'Toplam süre: %1
			|Başlangıç tarihi: %2
			|Bitiş tarihi: %3
			|İş yerleri: %4'", Common.DefaultLanguageCode()),
		CostCalculationProtocol.TimePresentation(MeasurementData.Duration/1000),
		MeasurementData.StartDate,
		MeasurementData.EndDate,
		CostCalculationAppliedAlgorithms.CalculatedCompanies(OrganizationsToCalculate(CompanyArray), ", "));
	
	WriteLogEvent(
		MonthEndTransactionsServer.EventLogEventName(
			NStr("vi = 'Tính giai đoạn';
				|ru = 'Расчет этапа';
				|en = 'Step calculation'; fa = 'Step calculation';
				|it = 'Расчет этапа';
				|pl = 'Step calculation';
				|tr = 'Aşama mutabakatı'", Common.DefaultLanguageCode())
				+ "." + Catalogs.MonthEndClosingOperations.GetPredefinedItemName(DescriptionOfStageExecution.Operation)),
		EventLogLevel.Information,
		,
		,
		TextForLog);
	
EndProcedure

#EndRegion

#Region PerformedCalculations

Function CheckForActiveCalculations(CompanyArray = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Companies.Ref AS Ref
	|INTO TTOrganizations
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref IN(&CompanyArray)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PerformingCalculation.Organization AS Organization,
	|	PerformingCalculation.CalculationPeriod AS CalculationPeriod,
	|	PerformingCalculation.Operation AS Operation,
	|	PerformingCalculation.StartDate AS StartDate,
	|	PerformingCalculation.InformationAboutCalculationStart AS InformationAboutCalculationStart,
	|	PerformingCalculation.CalculationID AS CalculationID
	|INTO TTPerformingCalculation
	|FROM
	|	InformationRegister.PerformMonthEndClosingOperations AS PerformingCalculation
	|		INNER JOIN TTOrganizations AS Companies
	|		ON PerformingCalculation.Organization = Companies.Ref
	|WHERE
	|	PerformingCalculation.CalculationIsInProgress
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Companies.Ref AS Ref
	|FROM
	|	TTOrganizations AS Companies
	|		LEFT JOIN TTPerformingCalculation AS PerformingCalculation
	|		ON Companies.Ref = PerformingCalculation.Organization
	|WHERE
	|	PerformingCalculation.Organization IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PerformingCalculation.Organization AS Organization,
	|	PerformingCalculation.CalculationPeriod AS CalculationPeriod,
	|	PerformingCalculation.Operation AS Operation,
	|	PerformingCalculation.StartDate AS StartDate,
	|	PerformingCalculation.InformationAboutCalculationStart AS InformationAboutCalculationStart,
	|	PerformingCalculation.CalculationID AS CalculationID
	|FROM
	|	TTPerformingCalculation AS PerformingCalculation
	|
	|ORDER BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PerformingCalculation.InformationAboutCalculationStart AS InformationAboutCalculationStart,
	|	PerformingCalculation.CalculationID AS CalculationID
	|FROM
	|	TTPerformingCalculation AS PerformingCalculation
	|
	|ORDER BY
	|	InformationAboutCalculationStart";
	
	Query.SetParameter("CompanyArray", OrganizationsToCalculate(CompanyArray));
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.ExecuteBatch();
	
	CalculationForAllOrganizations = QueryResult[2].IsEmpty();
	Calculations 				 = QueryResult[3].Unload();
	CalculationsByIDs = QueryResult[4].Unload();
	
	SetPrivilegedMode(False);
	
	DescriptionOfCalculations = "";
	
	For Each CurrRow In CalculationsByIDs Do
		DescriptionOfCalculations = DescriptionOfCalculations + Chars.LF + "  - " + TrimAll(CurrRow.InformationAboutCalculationStart);
	EndDo;
	
	Result = New Structure;
	Result.Insert("ThereAreActiveCalculations", 		(Calculations.Count() > 0));
	Result.Insert("ErrorText", 				"");
	Result.Insert("Calculations", 		      		Calculations);
	Result.Insert("CalculationForAllOrganizations", 	TrimAll(CalculationForAllOrganizations));
	
	If Result.ThereAreActiveCalculations Then
		
		OneTask = (CalculationsByIDs.Count() < 2);
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 đóng tháng:
				|%2
				|Đã dừng thực hiện giao dịch đóng tháng.';
				|ru = '%1 закрытия месяца:
				|%2
				|Выполнение операций закрытия месяца остановлено.';
				|en = '%1 month-end closing:
				|%2
				|Execution of month-end closing operations is stopped.'; fa = '%1 month-end closing:
				|%2
				|Execution of month-end closing operations is stopped.';
				|it = '%1 chiusura del mese:
				|%2
				| Esecuzione delle operazioni di fine mese è stato arrestato.';
				|pl = '%1 zamknięcie miesiąca: 
				|%2
				|Wykonanie operacji zamykanie miesiąca jest zatrzymane.';
				|tr = '%1ay sonu kapanışı:
				|%2
				|Ay sonu kapanış işlemleri durduruldu.'"),
			?(OneTask, NStr("vi = 'Phát hiện nhiệm vụ tích cực';
							|ru = 'Обнаружено активное задание';
							|en = 'Active job is found'; fa = 'Active job is found';
							|it = 'Trovato il task attivo';
							|pl = 'Wykryto aktywne zadanie';
							|tr = 'Aktif görev tespit edildi'"), NStr("vi = 'Phát hiện nhiệm vụ tích cực';
																|ru = 'Обнаружены активные задания';
																|en = 'Active jobs are found'; fa = 'Active jobs are found';
																|it = 'Trovati i task attivi';
																|pl = 'Wykryto aktywne zadania';
																|tr = 'Aktif görevler tespit edildi'")),
			TrimAll(DescriptionOfCalculations));
		
		If Common.FileInfobase()
		 And AccessRight("Edit", Metadata.InformationRegisters.PerformMonthEndClosingOperations) Then
			ErrorText = ErrorText + Chars.LF
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Có lẽ %1 không thành công, trong trường hợp đó, thông tin về %2 phải được cập nhật thủ công.';
						|ru = 'Возможно %1 аварийно, в этом случае информацию об %2 необходимо актуализировать вручную.';
						|en = '%1 was aborted. Update information on %2 manually.'; fa = '%1 was aborted. Update information on %2 manually.';
						|it = 'Probabilmente %1 è anomalo, in tal caso è necessario attualizzare le informazioni sul %2 manualmente.';
						|pl = 'Możliwe jest %1 awaryjne, w tym przypadku, informacje o %2 konieczności ręcznej aktualizacji.';
						|tr = '%1 kazalı olması mümkündür, bu durumda %2 hakkındaki bilgiler manuel olarak güncellenmelidir.'"),
					?(OneTask, NStr("vi = 'nhiệm vụ đã hoàn thành';
									|ru = 'задание завершено';
									|en = 'job is completed'; fa = 'job is completed';
									|it = 'task concluso';
									|pl = 'zadanie zakończono';
									|tr = 'görev tamamlandı'"), NStr("vi = 'nhiệm vụ đã hoàn thành';
																	|ru = 'задания завершены';
																	|en = 'jobs are completed'; fa = 'jobs are completed';
																	|it = 'task conclusi';
																	|pl = 'zadanie zakończone';
																	|tr = 'görevler tamamlandı'")),
					?(OneTask, NStr("vi = 'nhiệm vụ tích cực';
									|ru = 'активном задании';
									|en = 'active job'; fa = 'active job';
									|it = 'task attivo';
									|pl = 'aktywny zadaniem';
									|tr = 'aktif görev'"), NStr("vi = 'nhiệm vụ tích cực';
																|ru = 'активных заданиях';
																|en = 'active jobs'; fa = 'active jobs';
																|it = 'task attivi';
																|pl = 'aktywnych zadań';
																|tr = 'aktif görevler'")));
		EndIf;
		
		ErrorText = ErrorText + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để biết thêm thông tin, hãy xem biểu mẫu ""%1"", ""Hơn nữa"" - ""Phiên làm việc hiện tại đóng tháng""';
					|ru = 'Подробнее см. в форме ""%1"", ""Еще"" - ""Активные сеансы закрытия месяца""';
					|en = 'For more information, see the ""%1"" form, ""More"" - ""Active sessions of month-end closing""'; fa = 'For more information, see the ""%1"" form, ""More"" - ""Active sessions of month-end closing""';
					|it = 'Per dettagli consultate il modulo ""%1"", ""Ancora"" - ""Sessioni di chiusura del mese attive""';
					|pl = 'Szczegółowe informacje zobacz formularzu ""%1"", ""Więcej"" - ""Aktywne seansy zamknięcia miesiąca""';
					|tr = 'Daha fazla ayrıntı için, ""%1"" formunda bak, ""Daha"" - ""Aktif ay sonu kapanış oturumları"" formuna bak'"),
				Metadata.DataProcessors.MonthEndClosingOperations.Forms.MonthEndTransactions.Synonym);
		
		Result.ErrorText = ErrorText;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function UpdateStateOfActiveCalculations() Export
	
	IsFileIB = Common.FileInfobase();
	IsFullUser = Users.IsFullUser(,, False);
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	PerformingCalculation.CalculationID AS CalculationID
	|FROM
	|	InformationRegister.PerformMonthEndClosingOperations AS PerformingCalculation
	|WHERE
	|	PerformingCalculation.CalculationIsInProgress";
	
	Calculations = Query.Execute().Unload();
	
	For Each CurrRow In Calculations Do
		
		JobState = MonthEndTransactionsServer.CurStateOfBackgroundJob(
			MonthEndTransactionsServer.NameOfBackgroundJob(CurrRow.CalculationID));
		
		If Not JobState.Active Then
			
			// If the calculation task is not found by GUID, then it cannot be considered completed:
			// - in the file IB, because the platform "does not see" background tasks of another session
			// - if the current user is not an administrator, because the background task manager does not show
			// other users' tasks to such a user.
			If Not (JobState.NotFound4 And (IsFileIB Or Not IsFullUser))
			 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
				SetEndOfCalculationFlag(CurrRow.CalculationID);
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Calculations.Count();
	
EndFunction


Function SetFlagForStartingCalculation(CompanyArray, CalculationID,
			InformationAboutCalculationStart = "", CalculationPeriod = Undefined, Operation = Undefined) Export
	
	Companies = OrganizationsToCalculate(CompanyArray);
	
	LockSource = New ValueTable;
	LockSource.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	
	For Each CurrentCompany In Companies Do
		LockSource.Add().Organization = CurrentCompany;
	EndDo;
	
	StartDate = CurrentSessionDate();
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PerformMonthEndClosingOperations");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("Organization", "Organization");
		Block.Lock();		
		
		// You can set the calculation attribute (and start the calculation) only if there are no other active calculations for the specified organizations.
		ActiveCalculations = CheckForActiveCalculations(Companies);
		
		If Not ActiveCalculations.ThereAreActiveCalculations Then
			
			RecordSet = InformationRegisters.PerformMonthEndClosingOperations.CreateRecordSet();
			
			For Each CurrentCompany In Companies Do
				
				Record = RecordSet.Add();
				
				Record.Organization 	        	 = CurrentCompany;
				Record.CalculationIsInProgress    	 = True;
				Record.CalculationID 	 = CalculationID;
				Record.StartDate		    	 = StartDate;
				Record.InformationAboutCalculationStart = Format(StartDate, "DLF=DT") + "; " + TrimAll(InformationAboutCalculationStart);
				Record.CalculationPeriod 	         = CalculationPeriod;
				Record.Operation 	        	 = Operation;
				
			EndDo;
			
			RecordSet.Write(False);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(
			MonthEndTransactionsServer.EventLogEventName(
				NStr("vi = 'Đặt dấu hiệu tính toán';
					|ru = 'Установка признака выполнения расчета';
					|en = 'Set the accounting performing indicator'; fa = 'Set the accounting performing indicator';
					|it = 'Installare il criterio di esecuzione del calcolo';
					|pl = 'Ustawianie znaku wykonania rozliczenia';
					|tr = 'Mutabakat gerçekleştirilmesi işaretinin ayarlanması'", CommonClientServer.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			ErrorInfo);
		
		Raise ErrorInfo;
		
	EndTry;
	
	Return ActiveCalculations;
	
EndFunction

Function SetEndOfCalculationFlag(CalculationID = Undefined) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	
	Try
		
		// We will save information about all other calculations currently being performed except for the current (completed) one.
		// This will be faster than clearing records for each calculated organization one by one,
		// especially since in the vast majority of cases there will be no other calculations - only one record of an empty set will be performed.
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PerformMonthEndClosingOperations");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("CalculationIsInProgress", True);
		Block.Lock();		
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	PerformingCalculation.Organization AS Organization,
		|	PerformingCalculation.CalculationPeriod AS CalculationPeriod,
		|	PerformingCalculation.Operation AS Operation,
		|	PerformingCalculation.CalculationIsInProgress AS CalculationIsInProgress,
		|	PerformingCalculation.StartDate AS StartDate,
		|	PerformingCalculation.EndDate AS EndDate,
		|	PerformingCalculation.HadErrors AS HadErrors,
		|	PerformingCalculation.Duration AS Duration,
		|	PerformingCalculation.CalculationID AS CalculationID,
		|	PerformingCalculation.InformationAboutCalculationStart AS InformationAboutCalculationStart
		|FROM
		|	InformationRegister.PerformMonthEndClosingOperations AS PerformingCalculation
		|WHERE
		|	PerformingCalculation.CalculationIsInProgress
		|	AND PerformingCalculation.CalculationID <> &CalculationID
		|	AND NOT &EndOfAllCalculations";
		
		Query.SetParameter("CalculationID",  ?(CalculationID = Undefined, New UUID, CalculationID));
		Query.SetParameter("EndOfAllCalculations", CalculationID = Undefined);
		
		Query.Execute().Unload();
		
		RecordSet = InformationRegisters.PerformMonthEndClosingOperations.CreateRecordSet();
		RecordSet.Filter.CalculationIsInProgress.Set(True);
		
		RecordSet.Load(Query.Execute().Unload());
		
		RecordSet.Write(True);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(
			MonthEndTransactionsServer.EventLogEventName(
				NStr("vi = 'Đặt dấu hiệu tính toán';
					|ru = 'Установка признака выполнения расчета';
					|en = 'Set the accounting performing indicator'; fa = 'Set the accounting performing indicator';
					|it = 'Installare il criterio di esecuzione del calcolo';
					|pl = 'Ustawianie znaku wykonania rozliczenia';
					|tr = 'Mutabakat gerçekleştirilmesi işaretinin ayarlanması'", CommonClientServer.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			ErrorInfo);
		
		Raise ErrorInfo;
		
	EndTry;
	
	Return True;
	
EndFunction

Function UpdateFlagForStartingCalculation(CompanyArray, CalculationID,
			InformationAboutCalculationStart = "", CalculationPeriod = Undefined, Operation = Undefined) Export
	
	SetEndOfCalculationFlag(CalculationID);
	
	ActiveCalculations = SetFlagForStartingCalculation(
		CompanyArray,
		CalculationID,
		InformationAboutCalculationStart,
		CalculationPeriod,
		Operation);
	
	If ActiveCalculations.ThereAreActiveCalculations Then
		Raise ActiveCalculations.ErrorText;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Adds information security update procedures to the list for all supported library versions or configurations.
// 
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Value tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly mode = False.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.PerformMonthEndClosingOperations.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.9";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("7716a37d-637b-4cf0-9b3e-33816ccc95c2");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure =
		"InformationRegisters.PerformMonthEndClosingOperations.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment =
		NStr("vi = 'Điền chiều đo ""Giao dịch"" của biểu ghi thông tin ""Thực hiện giao dịch kết chuyển cuối tháng"".';
			|ru = 'Заполнение измерения ""Операция"" регистра сведений ""Выполнение операций закрытия месяца"".';
			|en = 'Fill in the ""Operation"" dimension of the ""Perform month-end closing operations"" information register.'; fa = 'Fill in the ""Operation"" dimension of the ""Perform month-end closing operations"" information register.';
			|it = 'Fill in the ""Operation"" dimension of the ""Perform month-end closing operations"" information register.';
			|pl = 'Fill in the ""Operation"" dimension of the ""Perform month-end closing operations"" information register.';
			|tr = '""Ay sonu kapanış işlemlerinin gerçekleştirilmesi"" bilgi kaydının ""İşlem"" boyutunun doldurulması.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.PerformMonthEndClosingOperations.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.PerformMonthEndClosingOperations.FullName());
	
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
	"SELECT DISTINCT
	|	Register.DeleteUseOperation AS DeleteUseOperation,
	|	Register.Organization AS Organization,
	|	Register.CalculationPeriod AS CalculationPeriod,
	|	Register.CalculationIsInProgress AS CalculationIsInProgress
	|FROM
	|	InformationRegister.PerformMonthEndClosingOperations AS Register
	|WHERE
	|	DeleteUseOperation <> VALUE(Enum.DeleteMonthEndClosingOperations.EmptyRef)
	|	AND Register.Operation = VALUE(Catalog.MonthEndClosingOperations.EmptyRef)";
	
	Result = Query.Execute().Select();

	Batch = IsEmptySet.Unload(, "DeleteUseOperation, Organization, CalculationPeriod, CalculationIsInProgress");
	Counter = 0;
	
	Selection = Result;
	While Selection.Next() Do
		If Counter = 1000 Then
			InfobaseUpdate.MarkForProcessing(Parameters, Batch, AdditionalParameters);
			Batch.Clear();
			Counter = 0;
		EndIf;
		FillPropertyValues(Batch.Add(), Selection);
		Counter = Counter + 1;
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

	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			DataLock = New DataLock;
	
			LockItem = DataLock.Add("InformationRegister.PerformMonthEndClosingOperations");
			LockItem.SetValue("DeleteUseOperation", Selection.DeleteUseOperation);
			LockItem.SetValue("Organization", Selection.Organization);
			LockItem.SetValue("CalculationPeriod", Selection.CalculationPeriod);
			LockItem.SetValue("CalculationIsInProgress", Selection.CalculationIsInProgress);
			LockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();
			
			RecordSet = InformationRegisters.PerformMonthEndClosingOperations.CreateRecordSet();
			RecordSet.Filter.DeleteUseOperation.Set(Selection.DeleteUseOperation);
			RecordSet.Filter.Organization.Set(Selection.Organization);
			RecordSet.Filter.CalculationPeriod.Set(Selection.CalculationPeriod);
			RecordSet.Filter.CalculationIsInProgress.Set(Selection.CalculationIsInProgress);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				If Not ValueIsFilled(Record.Operation) Then
					Record.Operation = Common.PredefinedItem(
						"Catalog.MonthEndClosingOperations." + XMLString(Record.DeleteUseOperation));
			EndIf;
			EndDo;
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StrTemplate(
					NStr("vi = 'Không thể xử lý dữ liệu trong biểu ghi ""Thực hiện giao dịch kết chuyển cuối tháng""
					| theo tập hợp bản ghi ""%1"", do nguyên nhân: %2';
					|ru = 'Не удалось обработать данные в регистре ""Выполнение операций закрытия месяца""
					| по набору записей ""%1"", по причине: %2';
					|en = 'Cannot process the data in the ""Perform month-end closing operations""
					| register for the ""%1"" record set. Reason: %2'; fa = 'Cannot process the data in the ""Perform month-end closing operations""
					| register for the ""%1"" record set. Reason: %2';
					|it = 'Cannot process the data in the ""Perform month-end closing operations""
					| register for the ""%1"" record set. Reason: %2';
					|pl = 'Cannot process the data in the ""Perform month-end closing operations""
					| register for the ""%1"" record set. Reason: %2';
					|tr = '""Ay sonu kapanış işlemlerinin gerçekleştirilmesi"" kaydındaki veriler,
					|""%1"" kayıt kümesi kapsamında şu nedenden dolayı işlenemedi: %2'"),
					String(RecordSet.Filter),
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				RegisterMetadata,
				MessageText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
		Parameters.Queue,
		FullObjectName);
	
EndProcedure

#EndRegion


#Region OtherItems

Function OrganizationsToCalculate(CompanyArray)
	
	Companies = ?(Not ValueIsFilled(CompanyArray),
		Catalogs.Companies.AvailableCompanies(),
		TMCommonUseClientServer.Array(CompanyArray));
	
	Return Companies;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
