#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		PrepareDataForRegisteringTasksInNonOperationalQueue();
		Return;
	EndIf;
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	PrepareDataForRegisteringTasksInNonOperationalQueue();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("DocumentProperties") Then
		InfobaseUpdate.CheckObjectProcessed(ThisObject);
	EndIf;
	
	For Each Record In ThisObject Do
		If Not ValueIsFilled(Record.Dimension) Then
			Record.Dimension = Undefined;
		EndIf;
	EndDo;
	
	Query = New Query(
	"SELECT
	|	T.LineNumber
	|INTO TT
	|FROM
	|	&OtherAssetsLiabilities AS T
	|WHERE
	|	T.Organization = VALUE(Catalog.Companies.EmptyRef)
	|	AND T.SourceKind = VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TT.LineNumber
	|FROM
	|	TT AS TT
	|
	|ORDER BY
	|	TT.LineNumber");
	
	Query.SetParameter("OtherAssetsLiabilities", ThisObject.Unload());
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Template = NStr("vi = 'Bản ghi không đúng! Giá trị của trường ""Doanh nghiệp"" không thể để trống! (Biểu ghi tích lũy: Tài sản và nguồn vốn; Số dòng: %1)';
						|ru = 'Запись не верна! Значение поля ""Организация"" не может быть пустым! (Регистр накопления: Активы и пассивы; Номер строки: %1)';
						|en = 'The record is invalid. Fill in the ""Company"" field. (Accumulation register: Assets and liabilities; Line number: %1)'; fa = 'The record is invalid. Fill in the ""Company"" field. (Accumulation register: Assets and liabilities; Line number: %1)';
						|it = 'La scrittura non è corretta! Il valore del campo ""Azienda"" non può essere vuoto! (Registro di accumulo: Attivi e passivi; Numero riga: %1)';
						|pl = 'Nieprawidłowy zapis! Wartość pola ""Firma"" nie może być pusta! (Rejestr kumulacji: Aktywa i pasywa; Numer wiersza: %1)';
						|tr = 'Kayıt doğru değil! ""İş yeri"" alanının değeri boş olamaz! (Birikim kaydı: Varlıklar ve yükümlülükler; Satır numarası: %1)'");
		Raise StrTemplate(Template, Selection.LineNumber);
	EndIf;
	
	CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
	If AdditionalProperties.Property("FormationOfManagementBalance") Then
		Return;
	EndIf;
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	AdditionalParameters = Testing.AdditionalParametersForFormingComparisonRequest();
	AdditionalParameters.CheckChecksum = False;
	QueryTextsForGettingChangeTable = 
		MonthEndTransactionsServer.QueryTextsForCaseChangeTable(Metadata(), Filter,AdditionalParameters);
	
	Query = New Query;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Text = QueryTextsForGettingChangeTable.InitialDataSampleText;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
	AdditionalProperties.Insert("SampleTextOfChangeTable", QueryTextsForGettingChangeTable.SampleTextOfChangeTable);
		
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		CreateNonOperationalQueueJobsWhenWriting();
		Return;
	EndIf;
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject)
		Or AdditionalProperties.Property("FormationOfManagementBalance") Then
		Return;
	EndIf;
	
	CreateNonOperationalQueueJobsWhenWriting();
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and is placed in a temporary table for subsequent recording in the task registers.
	Query = New Query;
	Query.Text = AdditionalProperties.SampleTextOfChangeTable;
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Private

#Region BackdateJobQueue

Procedure PrepareDataForRegisteringTasksInNonOperationalQueue()
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DonTRegisterNonOperationalQueueTasks") Then
		Return;
	EndIf;
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.Text = "
		|SELECT
		|	InitialEntries.Recorder AS Recorder,
		|	InitialEntries.Period AS Period,
		|	InitialEntries.Active AS Active,
		|	InitialEntries.RecordType AS RecordType,
		|	InitialEntries.Organization AS Organization,
		|	InitialEntries.Department AS Department,
		|	InitialEntries.LineOfBusiness AS LineOfBusiness,
		|	InitialEntries.AssetRef AS AssetRef,
		|	InitialEntries.Dimension AS Dimension,
		|	InitialEntries.Sum AS Sum,
		|	InitialEntries.SourceKind AS SourceKind,
		|	InitialEntries.Source AS Source,
		|	InitialEntries.CalculationOfCost AS CalculationOfCost,
		|	InitialEntries.LotCalculation AS LotCalculation,
		|	InitialEntries.ReversingEntry AS ReversingEntry
		|INTO VT_TaskQueueInitialEntries
		|FROM
		|	AccumulationRegister.OtherAssetsLiabilities AS InitialEntries
		|WHERE
		|	InitialEntries.Recorder = &Recorder";
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Execute();
		
		AdditionalProperties.Insert("TemporaryTableManagerJobQueue", Query.TempTablesManager);
		
	EndIf;
	
EndProcedure

Procedure CreateNonOperationalQueueJobsWhenWriting()
	
	If CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DonTRegisterNonOperationalQueueTasks")
		Or AdditionalProperties.Property("FormationOfManagementBalance") Then
		Return;
	EndIf;
	
	If Not BackdateJobQueue.CreationOfNonOperationalQueueTasksIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	If GetFunctionalOption("NewOnlineARAPAccounting") 
		And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		Query = New Query;
		Query.TempTablesManager = AdditionalProperties.TemporaryTableManagerJobQueue;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		Query.Text = "
		|SELECT DISTINCT
		|	Table.Recorder AS Document,
		|	Table.Period AS TaskPeriod,
		|	Table.Organization AS Organization,
		|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
		|FROM
		|	(SELECT
		|		InitialEntries.Recorder AS Recorder,
		|		InitialEntries.Period AS Period,
		|		InitialEntries.Active AS Active,
		|		InitialEntries.RecordType AS RecordType,
		|		InitialEntries.Organization AS Organization,
		|		InitialEntries.Department AS Department,
		|		InitialEntries.LineOfBusiness AS LineOfBusiness,
		|		InitialEntries.AssetRef AS AssetRef,
		|		InitialEntries.Dimension AS Dimension,
		|		InitialEntries.Sum AS Sum,
		|		InitialEntries.SourceKind AS SourceKind,
		|		InitialEntries.Source AS Source,
		|		InitialEntries.CalculationOfCost AS CalculationOfCost,
		|		InitialEntries.LotCalculation AS LotCalculation,
		|		InitialEntries.ReversingEntry AS ReversingEntry
		|	FROM
		|		VT_TaskQueueInitialEntries AS InitialEntries
		|
		|	UNION ALL
		|
		|	SELECT
		|		Records.Recorder AS Recorder,
		|		Records.Period AS Period,
		|		Records.Active AS Active,
		|		Records.RecordType AS RecordType,
		|		Records.Organization AS Organization,
		|		Records.Department AS Department,
		|		Records.LineOfBusiness AS LineOfBusiness,
		|		Records.AssetRef AS AssetRef,
		|		Records.Dimension AS Dimension,
		|		-Records.Sum AS Sum,
		|		Records.SourceKind AS SourceKind,
		|		Records.Source AS Source,
		|		Records.CalculationOfCost AS CalculationOfCost,
		|		Records.LotCalculation AS LotCalculation,
		|		Records.ReversingEntry AS ReversingEntry
		|	FROM
		|		AccumulationRegister.OtherAssetsLiabilities AS Records
		|	WHERE
		|		Records.Recorder = &Recorder) AS Table
		|WHERE 
		|	Table.SourceKind = VALUE(Enum.MovementSourcesKinds.EmptyRef)
		|	AND NOT Table.Organization = VALUE(Catalog.Companies.EmptyRef)
		|
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.Active,
		|	Table.RecordType,
		|	Table.Organization,
		|	Table.Department,
		|	Table.LineOfBusiness,
		|	Table.AssetRef,
		|	Table.Dimension,
		|	Table.SourceKind,
		|	Table.Source,
		|	Table.CalculationOfCost,
		|	Table.LotCalculation,
		|	Table.ReversingEntry
		|HAVING
		|	SUM(Table.Sum) <> 0
		|;
		|DROP VT_TaskQueueInitialEntries";

		DataForRegisteringTasks = Query.Execute().Unload();

		BackdateJobQueue.CreateNonOperationalQueueJobsWhenRecordingRecordset(ThisObject, Undefined,
			DataForRegisteringTasks);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
