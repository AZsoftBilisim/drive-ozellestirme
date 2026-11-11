////////////////////////////////////////////////////////////////////////////////
// Procedures related to the operation "Closing expenses from the disposal of fixed assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region HandlersForMonthClosingStages

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage(StepsTable, CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets);
		
	NewRow.MultilingualName = "vi = 'Đóng chi phí thanh lý TSCĐ';
								|ru = 'Закрытие расходов от выбытия ОС';
								|en = 'Close fixed asset retirement expenses';
								|it = 'Chiusura uscite da dismissione Immobilizzazione';
								|pl = 'Zamknięcie rozchodów od wyrejestrowania ŚT';
								|tr = 'Sabit kıymetlerin elden çıkarılmasından kaynaklanan giderlerin kapatılması'"; // @NStr-1
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords);
	
	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Calculate'; fa = 'محاسبه';
								|it = 'Eseguire';
								|pl = 'Calculate';
								|tr = 'Tamamla'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ClosingExpensesFromDisposalOfFixedAssets.DetermineOperationStatus");
		
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"ClosingExpensesFromDisposalOfFixedAssets.PerformMonthClosingOfOperation");
		
EndProcedure

// Determines the status of the operation "Usage_Close the outflow of the outflow of the ".
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
Procedure DetermineOperationStatus(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(HandlerParameters.CalculationParameters.Period) Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Kế toán tài sản dài hạn bị vô hiệu hóa.';
				|ru = 'Учет внеоборотных активов отключен.';
				|en = 'Accounting of fixed assets disabled.'; fa = 'Accounting of fixed assets disabled.';
				|it = 'La contabilità degli attivi non circolanti è disattivata.';
				|pl = 'Ewidencja aktyw pozaobrotowych jest odłączona.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi devre dışı bırakılmıştır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.DisposeFixedAssets2_4 AS DisposeFixedAssets
	|WHERE
	|	DisposeFixedAssets.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND DisposeFixedAssets.Organization IN (&CompanyArray)
	|	AND DisposeFixedAssets.Posted
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS FixedAssetSale
	|WHERE
	|	(FixedAssetSale.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		OR FixedAssetSale.DateOfTransferOfTitleToGoods BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|	AND FixedAssetSale.Organization IN (&CompanyArray)
	|	AND FixedAssetSale.Posted
	|
	|	AND FixedAssetSale.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))";
	
	Query = New Query(QueryText);
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then

		ExplanationText = StrTemplate(
			NStr("vi = 'Trong kỳ %1 không có nhiệm vụ để hạch toán giao dịch này.';
				|ru = 'За период %1 нет заданий для расчета данной операции.';
				|en = 'No jobs to calculate this operation for the %1 period.'; fa = 'No jobs to calculate this operation for the %1 period.';
				|it = 'Per il periodo %1 non ci sono compiti per il calcolo di questa operazione.';
				|pl = 'Za okres %1 nie ma zadań do obliczenia danej operacji.';
				|tr = 'Bu işlemi hesaplamak için dönem %1 için herhangi bir görev yoktur.'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod));
			
		MonthEndTransactionsServer.NoNeedToSetState(HandlerParameters, ExplanationText);
			
	EndIf;
		
EndProcedure

// Performs the operation "Close the expenses of the withdrawal".
// 
// Parameters:
//  HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure PerformMonthClosingOfOperation(HandlerParameters) Export

	CalculationParameters = HandlerParameters.CalculationParameters;
			
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.ClosingExpensesFromDisposalOfFixedAssets");
	
	NumberBeforeSettlement = InformationRegisters.JobsForMonthEndClosing.IncreaseTaskNumber();
	
	JobsForCalculating = JobsForCalculating(CalculationParameters, NumberBeforeSettlement);
	
	ExecutionParameters = ExecutionParameters();
	ExecutionParameters.BeginOfPeriod = BegOfMonth(JobsForCalculating.BeginOfPeriod);
	ExecutionParameters.EndOfPeriod = EndOfMonth(CalculationParameters.Period);
	ExecutionParameters.CompaniesList = JobsForCalculating.CompaniesList;
	ExecutionParameters.ExecuteCheck = True;
	ExecutionParameters.NumberBeforeSettlement = NumberBeforeSettlement;
	ExecutionParameters.TaskRegisterName = Metadata.InformationRegisters.JobsForMonthEndClosing.Name;
	ExecutionParameters.DeleteTasks = True;

	Result = ExecuteOperation(
		ExecutionParameters,
		JobsForCalculating.TempTablesManager,
		HandlerParameters.CalculationID);
		
	If Result.HasErrors Then
		
		For Each Organization In JobsForCalculating.CompaniesList Do
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets, 
				CalculationParameters.Period,
				Organization,
				Result.ErrorText);
		
		EndDo;
		
	EndIf;
		
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Result.DataVolume);
			
EndProcedure

// Generates a description of technological parameters.
// 
// Returns:
//  ValueTable - Description of parameters for the month closing operation
Function DescriptionOfParametersOfMonthClosingOperation() Export
	
	If Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		Return Undefined;
	EndIf;
	
	ParametersDetails = Constants.MonthEndClosingSettings.CreateValueManager().InitializeDescriptionOfOperationParameters();
	
	#Region MaximumNumberOfTasks
		
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Name = "MaximumNumberOfTasks";
	ParameterDetails.Description = NStr("vi = 'Số lượng nhiệm vụ được thực hiện đồng thời';
										|ru = 'Количество одновременно выполняемых заданий';
										|en = 'The number of simultaneously performed jobs'; fa = 'The number of simultaneously performed jobs';
										|it = 'Количество одновременно выполняемых заданий';
										|pl = 'The number of simultaneously performed jobs';
										|tr = 'Eş zamanlı görev sayısı'");
	ParameterDetails.ValueType = New TypeDescription("Number",,, New NumberQualifiers(2, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith = 1;
	ParameterDetails.DefaultValue = 4;
	ParameterDetails.LongDesc =
		NStr("vi = 'Có thể thực hiện đồng thời giao dịch bởi một số nhiệm vụ nền.
              |Việc tăng số lượng nhiệm vụ có thể giảm thời gian thực hiện giao dịch.
              |Nên tùy chỉnh số lượng nhiệm vụ tùy thuộc vào cấu hình server Hệ quản trị CSDL và Server 1C:Enterprise.';
              |ru = 'Операция может выполняться одновременно несколькими фоновыми заданиями.
              |Увеличение количества заданий может уменьшить время выполнения операции.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'Several background jobs can simultaneously run the operation.
              |Increasing the number of jobs can reduce the operation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'Several background jobs can simultaneously run the operation.
              |Increasing the number of jobs can reduce the operation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'Операция может выполняться одновременно несколькими фоновыми заданиями.
              |Увеличение количества заданий может уменьшить время выполнения операции.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'Several background jobs can simultaneously run the operation.
              |Increasing the number of jobs can reduce the operation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'İşlem, birden fazla arka plan işi tarafından eş zamanlı olarak gerçekleştirilebilir.
              |Görev sayısının artırılması işlem yürütme süresini azaltabilir.
              |Veri tabanı yönetim sistemi sunucusunun ve 1C:Enterprise sunucularının konfigürasyonuna bağlı olarak görev sayısının yapılandırılması önerilmektedir.'");
		
	#EndRegion
	
	#Region DataChunkSize
		
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Name = "DataChunkSize";
	ParameterDetails.Description = NStr("vi = 'Số lượng đối tượng được xử lý cùng lúc';
										|ru = 'Количество объектов обрабатываемых одновременно';
										|en = 'Number of objects processed simultaneously'; fa = 'Number of objects processed simultaneously';
										|it = 'Количество объектов обрабатываемых одновременно';
										|pl = 'Number of objects processed simultaneously';
										|tr = 'Eş zamanlı olarak işlenecek nesne sayısı'");
	ParameterDetails.ValueType = New TypeDescription("Number",,, New NumberQualifiers(6, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith = 1;
	ParameterDetails.DefaultValue = 100;
	ParameterDetails.LongDesc =
		NStr("vi = 'Giao dịch có thể được thực hiện đồng thời theo một số đối tượng (tài sản chính).
              |Việc tăng số lượng đối tượng có thể làm giảm thời gian thực hiện giao dịch, nhưng tăng yêu cầu về bộ nhớ.
              |Nên thiết lập số lượng nhiệm vụ tùy thuộc vào cấu hình server của hệ thống quản trị CSDL và server 1C:Enterprise.';
              |ru = 'Операция может выполняться одновременно по нескольким объектам (основным средствам).
              |Увеличение количества объектов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'The operation can be performed for several objects (fixed assets) simultaneously.
              |Increasing the number of objects can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'The operation can be performed for several objects (fixed assets) simultaneously.
              |Increasing the number of objects can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'Операция может выполняться одновременно по нескольким объектам (основным средствам).
              |Увеличение количества объектов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'The operation can be performed for several objects (fixed assets) simultaneously.
              |Increasing the number of objects can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'İşlemde hareketlerin oluşturulması birden fazla belge üzerinde eş zamanlı olarak gerçekleştirilebilir.
              |Belge sayısının artırılması işlem yürütme süresini azaltabilir, ancak bellek tüketimini artırabilir.
              |Veri tabanı yönetim sistemi sunucusunun ve 1C:Enterprise sunucularının konfigürasyonuna bağlı olarak sayısın yapılandırılması önerilmektedir.'");
		
	#EndRegion
	
	Return ParametersDetails;
	
EndFunction

#EndRegion

#Region PerformingTransaction

// Closes expenses related to the disposal of FA.
// 
// Parameters:
//  ExecutionParameters - See ExecutionParameters
//  TempTablesManager - TempTablesManager - Contains a list of objects
//  CalculationID - UUID - calculation ID
//  ForSpecifiedAccountingObjects - Boolean - True, if you need to perform an operation of operation on the FA in the table 
// 
// Returns:
//  Structure - the result of Registering Recorded movements:
// 		* HasErrors - Boolean - True if errors were registered during execution
// 		* ErrorText - String - error text
// 		* DataVolume - Number - The number of objects for which Registered Records have been generated
//
Function ExecuteOperation(ExecutionParameters, TempTablesManager, CalculationID, ForSpecifiedAccountingObjects = False) Export
	
	Result = New Structure;
	Result.Insert("HasErrors", False);
	Result.Insert("ErrorText", "");
	Result.Insert("DataVolume", 0);

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(ExecutionParameters.EndOfPeriod) Then
		Return Result;
	EndIf; 
	
	TaskQueue = CreateTaskQueue(ExecutionParameters, ForSpecifiedAccountingObjects, TempTablesManager);

	If TaskQueue.Count() <> 0 Then
		
		ExecutionResult = NonCurrentAssets.ExecuteTaskQueue(TaskQueue, MaximumNumberOfTasks(), CalculationID);
		
		Result.HasErrors = ExecutionResult.HasErrors;
		Result.ErrorText = ExecutionResult.ErrorText;
		Result.DataVolume = ExecutionResult.DataVolume;
	
	EndIf;

	If ExecutionParameters.DeleteTasks
		And Not Result.HasErrors Then
		
		DeleteTasksByDate(ExecutionParameters);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Generates Registered Records based on documents that contain the specified objects.
// 
// Parameters:
//  ExecutionParameters - See ExecutionParameters
// 
// Returns:
//  Number - The number of objects for which Registered Records have been generated
Function PerformOfOperationOnObjects(ExecutionParameters) Export
	
	If ExecutionParameters.ListOfObjects.Count() = 0
		Or ExecutionParameters.BeginOfPeriod = '000101010000' Then
		Return 0;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ClosingExpensesFromDisposalOfFixedAssets.PerformOfOperationOnObjects");
	
	SetPrivilegedMode(True);

	If ExecutionParameters.TempTablesManager = Undefined Then
		ExecutionParameters.TempTablesManager = New TempTablesManager;
	EndIf;
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(ExecutionParameters.TempTablesManager);
	TTUsed.Add("ListOfObjects");
	TTUsed.Add("TTAllDataToBeCalculated");
	TTUsed.Add("ProcessedOneData");

	BeginOfPeriod = ExecutionParameters.BeginOfPeriod; 

	CreateListOfObjects(ExecutionParameters);
	
	CreateTTTableWithAllDataToBeCalculated(
		BeginOfPeriod, 
		ExecutionParameters.EndOfPeriod, 
		ExecutionParameters.CompaniesList, 
		ExecutionParameters.TempTablesManager);
		
	// @skip-check query-in-loop
	// Verification is disabled because processing is performed in chunks for optimization
	While BeginOfPeriod <= ExecutionParameters.EndOfPeriod Do
		
		GetPortionOfDataToBeCalculated(BeginOfPeriod, ExecutionParameters);
			
		GenerateRegisteredRecordsBasedOnDocuments(BeginOfPeriod, ExecutionParameters);
	
		TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
			
		BeginOfPeriod = EndOfMonth(BeginOfPeriod) + 1;
		
	EndDo;
	
	TTUsed.Delete(TTUsed.Find("ListOfObjects"));
	TTUsed.Delete(TTUsed.Find("TTAllDataToBeCalculated"));
	TTUsed.Delete(TTUsed.Find("ProcessedOneData"));
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);

	SetPrivilegedMode(False);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, ExecutionParameters.DataVolume);
	
	Return ExecutionParameters.DataVolume;
	
EndFunction

// Generates Registered Records for documents.
//
// Parameters:
//  DocumentsList - Array of DocumentRef - A list of documents that need to be RegisteredRecorded.
//
Procedure PerformOperationOfOperationOnDocuments(DocumentsList) Export
	
	If Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		Return;
	EndIf; 
	
	ListOfAvailableDocuments = New Array;
	For Each DocumentRef In DocumentsList Do
		If Not PeriodClosingDates.DataChangesDenied(Common.TableNameByRef(DocumentRef), DocumentRef) Then
			ListOfAvailableDocuments.Add(DocumentRef);
		EndIf;
	EndDo;
	
	If ListOfAvailableDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	AllDocuments.Ref AS Ref,
	|	AllDocuments.Date AS Date,
	|	AllDocuments.Organization AS Organization,
	|	CAST(AllDocuments.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|	AllDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	AllDocuments.RecordInManAccounting AS RecordInManAccounting,
	|	AllDocuments.AccountingObject AS AccountingObject,
	|	1 AS Priority
	|
	|INTO JobsForCalculating
	|
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref,
	|		DocumentData.Organization AS Organization,
	|		BEGINOFPERIOD(DocumentData.Date, MONTH) AS Date,
	|		DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|		FATable.FixedAsset AS AccountingObject
	|
	|	FROM
	|		Document.DisposeFixedAssets2_4 AS DocumentData
	|		
	|			INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Ref IN (&DocumentsList)
	|		AND DocumentData.Posted
	|
	|		AND NOT (TRUE IN (
	|			SELECT TOP 1 
	|				TRUE 
	|			FROM 
	|				AccumulationRegister.OtherExpenses AS OtherExpenses 
	|			WHERE 
	|				OtherExpenses.Recorder = DocumentData.Ref
	|				AND OtherExpenses.BusinessOperation IN (&ListBT)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Ref AS Ref,
	|		DocumentData.Organization AS Organization,
	|		BEGINOFPERIOD(DocumentData.Date, MONTH) AS Date,
	|		TRUE AS RecordInLocalAccounting,
	|		TRUE AS RecordInManAccounting,
	|		FATable.NonCurrentAsset AS AccountingObject
	|
	|	FROM
	|		Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|		
	|			INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|				AND FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|
	|	WHERE
	|		DocumentData.Ref IN (&DocumentsList)
	|		AND DocumentData.Posted
	|		AND DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|			VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|
	|		AND NOT (TRUE IN (
	|			SELECT TOP 1 
	|				TRUE 
	|			FROM 
	|				AccumulationRegister.OtherExpenses AS OtherExpenses 
	|			WHERE 
	|				OtherExpenses.Recorder = DocumentData.Ref
	|				AND OtherExpenses.BusinessOperation IN (&ListBT)))
	|
	|	) AS AllDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BEGINOFPERIOD(JobsForCalculating.Date, MONTH) AS Month
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|
	|ORDER BY
	|	Month
	|";
	
	TempTablesManager = New TempTablesManager();
	
	TTUsed = New Array;
	TTUsed.Add("JobsForCalculating");
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("DocumentsList", ListOfAvailableDocuments);
	
	ListBT = New Array;
	ListBT.Add(Enums.BusinessTransactions.CloseFixedAssetWriteOffExpenses);
	ListBT.Add(Enums.BusinessTransactions.CloseFixedAssetSalesExpenses);
	ListBT.Add(Enums.BusinessTransactions.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer);
	ListBT.Add(Enums.BusinessTransactions.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets);
	ListBT.Add(Enums.BusinessTransactions.AdjustmentOfExpensesFromDisposalOfFixedAssets);
	Query.SetParameter("ListBT", ListBT);

	Result = Query.Execute();
	Selection = Result.Select();
	
	// Verification is disabled because processing must be performed in chunks
	//@skip-check query-in-loop
	While Selection.Next() Do
	
		QueryText =	
		"SELECT 
		|	JobsForCalculating.Ref AS Ref,
		|	JobsForCalculating.Date AS Date,
		|	JobsForCalculating.Organization AS Organization,
		|	JobsForCalculating.ParentCompany AS ParentCompany,
		|	JobsForCalculating.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	JobsForCalculating.RecordInManAccounting AS RecordInManAccounting,
		|	JobsForCalculating.AccountingObject AS AccountingObject,
		|
		|	JobsForCalculating.Priority AS Priority
		|
		|INTO TTPortionOfDataToBeCalculated
		|
		|FROM
		|	JobsForCalculating AS JobsForCalculating
		|
		|WHERE
		|	JobsForCalculating.Date BETWEEN &BegOfMonth AND &EndOfMonth
		|";
			
		Query.Text = QueryText;
		Query.SetParameter("BegOfMonth", BegOfMonth(Selection.Month));
		Query.SetParameter("EndOfMonth", EndOfMonth(Selection.Month));
		Query.Execute();
		
		ProcedureParameters = ExecutionParameters();
		ProcedureParameters.EndOfPeriod = EndOfMonth(Selection.Month);
		ProcedureParameters.ReturnDocumentsToReflection = False;
		ProcedureParameters.GenerateJobs = False;
		ProcedureParameters.DeleteTasks = False;
		ProcedureParameters.TempTablesManager = TempTablesManager;
		
		GenerateRegisteredRecordsBasedOnDocuments(Selection.Month, ProcedureParameters);

		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
		
	EndDo;
	
EndProcedure

// parameters for performing the operation.
// 
// Returns:
//  Structure - Execution parameters:
// 		* BeginOfPeriod - Date - Start of the of operation execution period
// 		* EndOfPeriod - Date - End of the Operation execution period
// 		* CompaniesList - Array of CatalogRef.Companies - Organizations for which the Operation is being performed
// 		* ListOfObjects - ValueTable - Objects for which the operation is performed of operation
// 		* ReturnDocumentsToReflection - Boolean - True, if you need to return the documents for reflection in Local accounting
// 		* GenerateJobs - Boolean - True if you need to create tasks
// 		* DeleteTasks - Boolean - True if you need to delete tasks
// 		* TaskRegisterName - String - Task Register Name
// 		* NumberBeforeSettlement - Number - Task number
// 		* ExecuteCheck - Boolean - True if you need to perform a check and register errors closing the month
// 		* TempTablesManager - Undefined - temporary table Manager
//		* DataVolume -Number - Number Of Processed Data
Function ExecutionParameters() Export

	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("BeginOfPeriod", '000101010000');
	ExecutionParameters.Insert("EndOfPeriod", '000101010000');
	ExecutionParameters.Insert("CompaniesList", New Array);
	ExecutionParameters.Insert("ReturnDocumentsToReflection", True);
	ExecutionParameters.Insert("GenerateJobs", True);
	ExecutionParameters.Insert("DeleteTasks", True);
	ExecutionParameters.Insert("TaskRegisterName", Undefined);
	ExecutionParameters.Insert("NumberBeforeSettlement", 0);
	ExecutionParameters.Insert("ExecuteCheck", False);
	ExecutionParameters.Insert("TempTablesManager", Undefined);
	ExecutionParameters.Insert("DataVolume", 0);

	ListOfObjects = New ValueTable();
	ListOfObjects.Columns.Add("AccountingObject", New TypeDescription("CatalogRef.Assets"));
	ExecutionParameters.Insert("ListOfObjects", ListOfObjects);

	Return ExecutionParameters;
	
EndFunction

#EndRegion

#Region JobsForMonthEndClosing

// Defines the period starting from which the operation "Closing the outflow of the outflow" is to be performed.
//
// Parameters:
//  Organization   - CatalogRef.Companies - 
//  BeginOfPeriod - Date - The period being checked.
// 
// Returns:
//  Date - The date from which the calculation is required.
//
Function NextPeriodOfOperation(Organization, BeginOfPeriod) Export
	
	QueryText =
	"SELECT
	|	MIN(DocumentsTable.Period) AS Period
	|FROM
	|	(SELECT
	|		DisposeFixedAssets.Date AS Period
	|	FROM
	|		Document.DisposeFixedAssets2_4 AS DisposeFixedAssets
	|	WHERE
	|		DisposeFixedAssets.Date >= &BeginOfPeriod
	|		AND DisposeFixedAssets.Organization IN (&Organization)
	|		AND DisposeFixedAssets.Posted
	|	
	|	UNION ALL
	|
	|	SELECT
	|		OtherRegistration.Date AS Period
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived AS OtherRegistration
	|	WHERE
	|		OtherRegistration.BusinessOperation = VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal)
	|		AND OtherRegistration.Date >= &BeginOfPeriod
	|		AND OtherRegistration.Organization IN (&Organization)
	|		AND OtherRegistration.Posted
	|	
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN FixedAssetSale.Date >= &BeginOfPeriod
	|				THEN FixedAssetSale.Date
	|			ELSE FixedAssetSale.DateOfTransferOfTitleToGoods 
	|		END AS Period
	|	FROM
	|		Document.CustomerInvoiceServicesAndAssets AS FixedAssetSale
	|
	|			INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS FATable
	|			ON FATable.Ref = FixedAssetSale.Ref
	|				AND FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|
	|	WHERE
	|		FixedAssetSale.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|			VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|
	|		AND (FixedAssetSale.Date >= &BeginOfPeriod
	|			OR FixedAssetSale.DateOfTransferOfTitleToGoods >= &BeginOfPeriod)
	|
	|		AND FixedAssetSale.Organization IN (&Organization)
	|		AND FixedAssetSale.Posted
	|
	|	) AS DocumentsTable";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(BeginOfPeriod));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	If Selection.Next() Then
		Return ?(ValueIsFilled(Selection.Period), BegOfMonth(Selection.Period), '000101010000');
	EndIf;

	Return '000101010000';
	
EndFunction

// Generates tasks for performing an operation when the source data changes.
// 
// Parameters:
//  Document - DocumentObject - Document.
//  TempTablesManager - TempTablesManager - Table data.
Procedure GenerateJobs(Document, TempTablesManager) Export
	
	If RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) Then
		Return;
	EndIf;
	
	TablesToUse = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	
	// Of operations that are performed after the Cur of operation
	RegisteredRecordsAreFormedAtCloseOfMonth = 
		FACostCalculation.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document)
		Or FACostCalculation.RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA(Document);

	TablesList = New Array;
	TablesList.Add("OtherExpenses_AssignmentsToCloseFADisposalExpenses");
	TablesList.Add("SaleOfServicesOfOtherAssets_AssignmentsForClosingExpensesFromDisposalOfFA");

	DefineChangesForGeneratingTasks(TempTablesManager);

	DataJoinText = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TempTablesManager);
	
	OnlyStateOfTransferOfOwnershipHasChanged = 
		TypeOf(Document.Ref) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		And Document.AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And Document.AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged;
		
	// Documents are always registered, because during the execution, deferred movements are deleted.
	RegisterDocument = 
		Not RegisteredRecordsAreFormedAtCloseOfMonth
		And (TypeOf(Document.Ref) = Type("DocumentRef.DisposeFixedAssets2_4")
			Or TypeOf(Document.Ref) = Type("DocumentRef.OtherGoodsRecordingAsReceived")
			Or TypeOf(Document.Ref) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
				And OnlyStateOfTransferOfOwnershipHasChanged);
	
	If RegisterDocument Then
		
		ListOfMergeRequests = New Array;
		
		If DataJoinText <> "" Then
			ListOfMergeRequests.Add(DataJoinText);
		EndIf; 
			
		QueryText =
		"SELECT
		|	CASE
		|		WHEN ISNULL(FixedAssetSale.BusinessOperation, UNDEFINED) = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
		|				AND &OnlyStateOfTransferOfOwnershipHasChanged
		|				AND FixedAssetSale.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|			THEN FixedAssetSale.DateOfTransferOfTitleToGoods
		|		ELSE ChangedData.IBDocumentDate 
		|	END AS Period,
		|
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Ref AS Document,
		|	"""" AS TableName
		|FROM
		|	InformationRegister.DocumentsRegistry AS ChangedData
		|
		|		LEFT JOIN Document.CustomerInvoiceServicesAndAssets AS FixedAssetSale
		|		ON FixedAssetSale.Ref = ChangedData.Ref
		|
		|WHERE
		|	ChangedData.Ref = &Ref
		|	AND ChangedData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.DisposeFixedAssets),
		|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal),
		|		VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal),
		|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
		|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
		|
		|UNION ALL
		|
		|SELECT
		|	ChangedData.DateOfTransferOfTitleToGoods AS Period,
		|
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Ref AS Document,
		|	"""" AS TableName
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets AS ChangedData
		|
		|WHERE
		|	ChangedData.Ref = &Ref
		|	AND ChangedData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
		|	AND NOT &OnlyStateOfTransferOfOwnershipHasChanged
		|	AND ChangedData.DateOfTransferOfTitleToGoods <> DATETIME(1,1,1)
		|
		|UNION ALL
		|
		|SELECT
		|	&OldDateOfTransferOfOwnership AS Period,
		|
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Ref AS Document,
		|	"""" AS TableName
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets AS ChangedData
		|
		|WHERE
		|	ChangedData.Ref = &Ref
		|	AND ChangedData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
		|	AND &OnlyStateOfTransferOfOwnershipHasChanged
		|	AND &OldDateOfTransferOfOwnership <> DATETIME(1,1,1)
		|";
		
		ListOfMergeRequests.Add(QueryText);
		
		DataJoinText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf; 
	
	If DataJoinText = "" Then
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TablesToUse);
		Return;
	EndIf;

	QueryText =
	"SELECT DISTINCT
	|	VALUE(Catalog.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets) AS Operation,
	|	ChangedData.Organization AS Organization,
	|	ChangedData.Document AS Document,
	|
	|	CASE 
	|		WHEN ChangedData.Period < &AccountingStartDate24
	|			THEN &AccountingStartDate24
	|		WHEN NOT OBEntry.Date IS NULL
	|			THEN DATEADD(BEGINOFPERIOD(OBEntry.Date, MONTH), MONTH, 1)
	|		WHEN &RegisteredRecordsAreFormedAtCloseOfMonth
	|			THEN DATEADD(BEGINOFPERIOD(ChangedData.Period, MONTH), MONTH, 1)
	|		ELSE ChangedData.Period
	|	END AS Month
	|
	|FROM
	|	&DataJoinText AS ChangedData
	|
	|		LEFT JOIN Document.OBEntryOtherExpenses AS OBEntry
	|		ON OBEntry.Ref = ChangedData.Document
	|";
	
	QueryText = StrReplace(QueryText, "&DataJoinText", "(" + DataJoinText + ")");

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("AccountingStartDate24", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	Query.SetParameter("Ref", Document.Ref);
	Query.SetParameter("OnlyStateOfTransferOfOwnershipHasChanged", OnlyStateOfTransferOfOwnershipHasChanged);
	Query.SetParameter("RegisteredRecordsAreFormedAtCloseOfMonth", RegisteredRecordsAreFormedAtCloseOfMonth);

	If TypeOf(Document.Ref) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		And Document.AdditionalProperties.Property("OldDateOfTransferOfOwnership") Then
						
		Query.SetParameter(
			"OldDateOfTransferOfOwnership", 
			Document.AdditionalProperties.OldDateOfTransferOfOwnership);
	Else
		Query.SetParameter("OldDateOfTransferOfOwnership", '000101010000');
	EndIf;
					
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntriesBasedOnSampleData(Selection);
	
	SetPrivilegedMode(False);
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TablesToUse);
	
EndProcedure

// Determines whether movements are recorded when performing an operation.
// 
// Parameters:
//  Document - DocumentObject -
// 
// Returns:
//  Boolean
Function RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) Export

	Return Document <> Undefined
			And Document.AdditionalProperties.Property(NameOfFlagOfOperation());
	
EndFunction

#EndRegion

#Region FormationOfTablesForCarryingOut

// Generates the query text for the "Other expenses" register table.
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableOtherExpenses(QueryTexts) Export
	
	Add_Fields = "RowID,Recorder";
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	#Region WriteOffOfExpenses // - Cr 01.09
	QueryText =
	"SELECT
	|	WriteOffOfExpenses.Period                         AS Period,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	WriteOffOfExpenses.Organization                    AS Organization,
	|	WriteOffOfExpenses.Department                  AS Department,
	|	WriteOffOfExpenses.ExpenseItem                 AS ExpenseItem,
	|	WriteOffOfExpenses.DimensionOfExpenses              AS DimensionOfExpenses,
	|	WriteOffOfExpenses.LineOfBusiness        AS LineOfBusiness,
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	WriteOffOfExpenses.Sum                          AS AmountIncludingVAT,
	|	WriteOffOfExpenses.AmountExcludingVAT                    AS AmountExcludingVAT,
	|	WriteOffOfExpenses.SumMan                       AS AmountExcludingVATMan,
	|	WriteOffOfExpenses.SumCompl                      AS AmountIncludingVATCompl,
	|	WriteOffOfExpenses.SumCompl                      AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		ELSE WriteOffOfExpenses.PermanentDifference
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		ELSE WriteOffOfExpenses.SumCompl 
	|				- WriteOffOfExpenses.AmountFA 
	|				- WriteOffOfExpenses.PermanentDifference
	|	END AS CostTD,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|			THEN &BO_CloseFixedAssetSalesExpensesWithDeferredTitleTransfer
	|		WHEN WriteOffOfExpenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses)
	|			THEN &BO_CloseFixedAssetSalesExpenses
	|		ELSE &BO_CloseFixedAssetWriteOffExpenses
	|	END AS BusinessOperation,
	|
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	
	|	WriteOffOfExpenses.RowID AS FinRecordID,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|			THEN &SettingUpHO_ClosingExpensesFromOSSImplementationByDeferredTransferOfRights
	|		WHEN WriteOffOfExpenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses)
	|			THEN &SettingUpHO_ClosingExpensesFromFAImplementation
	|		ELSE &SettingUpHO_ClosingExpensesFromFADebiting
	|	END AS BusinessTransactionSetting,
	|
	|	WriteOffOfExpenses.RowID AS RowID,
	|	WriteOffOfExpenses.Recorder AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryCostAdjustment.Period                AS Period,
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	InventoryCostAdjustment.Organization           AS Organization,
	|	InventoryCostAdjustment.Department         AS Department,
	|	InventoryCostAdjustment.ExpenseItem        AS ExpenseItem,
	|	InventoryCostAdjustment.DimensionOfExpenses     AS DimensionOfExpenses,
	|	InventoryCostAdjustment.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	-InventoryCostAdjustment.Sum                AS AmountIncludingVAT,
	|	-InventoryCostAdjustment.AmountExcludingVAT          AS AmountExcludingVAT,
	|	-InventoryCostAdjustment.SumMan             AS AmountExcludingVATMan,
	|	-InventoryCostAdjustment.SumCompl            AS AmountIncludingVATCompl,
	|	-InventoryCostAdjustment.SumCompl            AS AmountExcludingVATCompl,
	|	0                                               AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		ELSE -InventoryCostAdjustment.SumCompl
	|	END AS CostTD,
	|
	|	&BO_CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets AS BusinessOperation,
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	
	|	InventoryCostAdjustment.RowID   AS FinRecordID,
	|	&SettingHO_AdjustmentOfCostOfInventoryRegisteredAtDisposalOfFA AS BusinessTransactionSetting,
	|
	|	InventoryCostAdjustment.RowID   AS RowID,
	|	InventoryCostAdjustment.Recorder           AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN InventoryCostAdjustment AS InventoryCostAdjustment
	|		ON InventoryCostAdjustment.Recorder = DocumentData.Ref
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region CloseFixedAssetSalesExpenses // Dt 91 - 
	QueryText =
	"SELECT
	|	WriteOffOfExpenses.Period                         AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	WriteOffOfExpenses.Organization                    AS Organization,
	|	WriteOffOfExpenses.DebitBusinessUnit               AS Department,
	|	WriteOffOfExpenses.CorExpenseItem              AS ExpenseItem,
	|	WriteOffOfExpenses.CorExpenditureDimension           AS DimensionOfExpenses,
	|	WriteOffOfExpenses.CorLineOfBusiness     AS LineOfBusiness,
	|	UNDEFINED                                    AS VATActivityType,
	|	
	|	WriteOffOfExpenses.Sum                          AS AmountIncludingVAT,
	|	WriteOffOfExpenses.AmountExcludingVAT                    AS AmountExcludingVAT,
	|	WriteOffOfExpenses.SumMan                       AS AmountExcludingVATMan,
	|	WriteOffOfExpenses.SumCompl                      AS AmountIncludingVATCompl,
	|	WriteOffOfExpenses.SumCompl                      AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		ELSE WriteOffOfExpenses.PermanentDifference
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		ELSE WriteOffOfExpenses.SumCompl 
	|				- WriteOffOfExpenses.AmountFA 
	|				- WriteOffOfExpenses.PermanentDifference
	|	END AS CostTD,
	|
	|	CASE
	|		WHEN WriteOffOfExpenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses)
	|			THEN &BO_CloseFixedAssetSalesExpenses
	|		ELSE &BO_CloseFixedAssetWriteOffExpenses
	|	END AS BusinessOperation,
	|
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	
	|	WriteOffOfExpenses.RowID            AS FinRecordID,
	|
	|	CASE
	|		WHEN WriteOffOfExpenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses)
	|			THEN &SettingUpHO_ClosingExpensesFromFAImplementation
	|		ELSE &SettingUpHO_ClosingExpensesFromFADebiting
	|	END AS BusinessTransactionSetting,
	|
	|	WriteOffOfExpenses.RowID AS RowID,
	|	WriteOffOfExpenses.Recorder AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(WriteOffOfExpenses.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
		
	#Region CloseFixedAssetSalesExpensesWithDeferredTitleTransfer // Dt 91 - 
	QueryText =
	// Before the transfer of rights (only in TA for real estate)
	"SELECT
	|	TransferredObjects.Period                         AS Period,
	|	VALUE(AccumulationRecordType.Receipt)           AS RecordType,
	|	TransferredObjects.Organization                    AS Organization,
	|	TransferredObjects.DebitBusinessUnit               AS Department,
	|	TransferredObjects.CorExpenseItem              AS ExpenseItem,
	|	TransferredObjects.CorExpenditureDimension           AS DimensionOfExpenses,
	|	TransferredObjects.CorLineOfBusiness     AS LineOfBusiness,
	|	UNDEFINED                                     AS VATActivityType,
	|	
	|	0                                                AS AmountIncludingVAT,
	|	0                                                AS AmountExcludingVAT,
	|	0                                                AS AmountExcludingVATMan,
	|	0                                                AS AmountIncludingVATCompl,
	|	0                                                AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		ELSE TransferredObjects.PermanentDifference
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept 
	|			THEN 0
	|		ELSE - TransferredObjects.AmountFA - TransferredObjects.PermanentDifference
	|	END AS CostTD,
	|
	|	&BO_CloseFixedAssetSalesExpensesWithDeferredTitleTransfer AS BusinessOperation,
	|
	|	UNDEFINED                                     AS ItemsLocationAttributes,
	|	
	|	&IDOfUnusedFinRecord            AS FinRecordID,
	|
	|	&SettingUpHO_ClosingExpensesFromOSSImplementationByDeferredTransferOfRights AS BusinessTransactionSetting,
	|
	|	TransferredObjects.RowID AS RowID,
	|	TransferredObjects.Recorder AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TransferredObjects AS TransferredObjects
	|		ON TransferredObjects.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(TransferredObjects.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND TransferredObjects.RealEstate
	|	AND (TransferredObjects.AmountFA <> 0
	|		OR TransferredObjects.AmountFA = 0
	|			AND TransferredObjects.PermanentDifference <> 0)
	|
	|UNION ALL
	|
	// After the transfer of rights (in MA, AC for any property and in TA for movable property)
	|SELECT
	|	TransferredObjects.DateRightsWereTransferred               AS Period,
	|	VALUE(AccumulationRecordType.Receipt)           AS RecordType,
	|	TransferredObjects.Organization                    AS Organization,
	|	TransferredObjects.DebitBusinessUnit               AS Department,
	|	TransferredObjects.CorExpenseItem              AS ExpenseItem,
	|	TransferredObjects.CorExpenditureDimension           AS DimensionOfExpenses,
	|	TransferredObjects.CorLineOfBusiness     AS LineOfBusiness,
	|	UNDEFINED                                     AS VATActivityType,
	|	
	|	TransferredObjects.Sum                          AS AmountIncludingVAT,
	|	TransferredObjects.AmountExcludingVAT                    AS AmountExcludingVAT,
	|	TransferredObjects.SumMan                       AS AmountExcludingVATMan,
	|	TransferredObjects.SumCompl                      AS AmountIncludingVATCompl,
	|	TransferredObjects.SumCompl                      AS AmountExcludingVATCompl,
	|
	|	CASE
	|		WHEN TransferredObjects.RealEstate
	|				OR NOT &ComplianceCAAccountingIsKept
	|			THEN 0
	|		ELSE TransferredObjects.PermanentDifference 
	|	END AS PermanentDifference,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept
	|			THEN 0
	|		WHEN TransferredObjects.RealEstate
	|			THEN TransferredObjects.SumCompl
	|		ELSE TransferredObjects.SumCompl 
	|				- TransferredObjects.AmountFA 
	|				- TransferredObjects.PermanentDifference 
	|	END AS CostTD,
	|
	|	&BO_CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer AS BusinessOperation,
	|
	|	UNDEFINED                                    AS ItemsLocationAttributes,
	|	
	|	TransferredObjects.RowID           AS FinRecordID,
	|
	|	&SettingUpHo_ClosingExpensesFromFAImplementationAfterTransferOfRights AS BusinessTransactionSetting,
	|
	|	TransferredObjects.RowID AS RowID,
	|	TransferredObjects.Recorder AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TransferredObjects AS TransferredObjects
	|		ON TransferredObjects.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(TransferredObjects.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND BEGINOFPERIOD(TransferredObjects.DateRightsWereTransferred, MONTH) = &RegisterRecordsPeriod
	|	AND TransferredObjects.RightsTransferred
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, "TTInitialOtherExpenses");
	
	QueryTexts.Add(AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True), "TTOtherExpenses_");
	QueryTexts.Add(AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True), "OtherExpenses", True);
	
EndProcedure

// Generates the query text for the "Other Income" register table.
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableOtherIncome(QueryTexts) Export
	
	#Region CostAdjustment_ // Dt 01.09 - Ct 91
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	CostAdjustment_.Recorder AS Recorder,
	|	CostAdjustment_.Period AS Period,
	|	
	|	CostAdjustment_.Organization AS Organization,
	|	CostAdjustment_.Department AS Department,
	|	CostAdjustment_.IncomeItem AS IncomeItem,
	|	CostAdjustment_.DimensionOfRevenue AS DimensionOfRevenue,
	|	
	|	0 AS Sum,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	
	|	&BO_AdjustmentOfExpensesFromDisposalOfFixedAssets AS BusinessOperation,
	|	CostAdjustment_.LineOfBusiness AS LineOfBusiness,
	|	
	|	CostAdjustment_.RowID AS FinRecordID,
	|	&SettingHO_AdjustmentOfExpensesFromDisposalOfFA AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN CostAdjustment_ AS CostAdjustment_
	|		ON CostAdjustment_.Recorder = DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, "OtherIncome", True);
	#EndRegion
	
EndProcedure

// Generates the query text for the register table "Lots of other expenses".
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableItemisedExpensesLots(QueryTexts) Export
	
	Add_Fields = "Recorder";

	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.ItemisedExpensesLots.TextDescriptionTTInitialBatchesOfOtherExpenses(Add_Fields));
	
	#Region RecognitionOfWriteOffOfExpensesFromDisposalInExpenses
	
	QueryText =
	"SELECT
	|	WriteOffOfExpenses.Period                     AS Period,
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|
	|	WriteOffOfExpenses.Organization                AS Organization,
	|	WriteOffOfExpenses.DebitBusinessUnit           AS Department,
	|	WriteOffOfExpenses.CorExpenseItem          AS ExpenseItem,
	|	WriteOffOfExpenses.CorExpenditureDimension       AS DimensionOfExpenses,
	|	UNDEFINED                                AS AssetsLiabilitiesDimension,
	|	DocumentData.Ref                      AS ExpenseReceiptDocument,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	WriteOffOfExpenses.CorLineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                                AS ItemsLocationAttributes,
	|	UNDEFINED                                AS VATActivityType,
	|
	|	WriteOffOfExpenses.SumMan                   AS Cost,
	|	WriteOffOfExpenses.AmountExcludingVAT                AS CostExcludingVAT,
	|	0                                           AS VATManag,
	|	WriteOffOfExpenses.SumCompl                  AS LocalCost,
	|	0                                           AS VATLocal,
	|	WriteOffOfExpenses.PermanentDifference          AS PermanentDifference,
	|
	|	WriteOffOfExpenses.SumCompl 
	|		- WriteOffOfExpenses.AmountFA 
	|		- WriteOffOfExpenses.PermanentDifference    AS CostTD,
	|
	|	&BO_CloseFixedAssetWriteOffExpenses            AS BusinessOperation,
	|	
	|	WriteOffOfExpenses.RowID        AS FinRecordID,
	|	&SettingUpHO_ClosingExpensesFromFADebiting   AS BusinessTransactionSetting,
	|	WriteOffOfExpenses.Recorder                AS Recorder
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(WriteOffOfExpenses.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, "TTInitialBatchesOfOtherExpenses");

	QueryTexts.Add(AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses(Add_Fields, True), "TTLotsOfOtherExpenses");
	QueryTexts.Add(AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots(Add_Fields), "ItemisedExpensesLots", True);
	
EndProcedure

// Generates the query text for the "Other Active Arrays" register table.
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableOtherAssetsLiabilities(QueryTexts) Export
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	WriteOffOfExpenses.Recorder                 AS Recorder,
	|	WriteOffOfExpenses.Period                      AS Period,
	|	&BO_CloseFixedAssetWriteOffExpenses             AS BusinessOperation,
	|	WriteOffOfExpenses.Organization                 AS Organization,
	|	WriteOffOfExpenses.Department               AS Department,
	|	WriteOffOfExpenses.LineOfBusiness     AS LineOfBusiness,
	|
	|	WriteOffOfExpenses.CorExpenseItem           AS AssetRef,
	|	WriteOffOfExpenses.CorDimensionOfAssetsLiabilities AS Dimension,
	|
	|	WriteOffOfExpenses.SumMan                    AS Sum
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|WHERE
	|	WriteOffOfExpenses.SumMan <> 0
	|	AND VALUETYPE(WriteOffOfExpenses.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)";
	
	QueryTexts.Add(QueryText, "OtherAssetsLiabilities", True);
	
EndProcedure

// Generates the query text for the register table "Movementprochimactivampassivam".
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts) Export
	
	QueryText = 
	"SELECT
	|	WriteOffOfExpenses.Recorder              AS Recorder,
	|	WriteOffOfExpenses.Period                   AS Period,
	|	WriteOffOfExpenses.Organization              AS Organization,
	|	WriteOffOfExpenses.DebitBusinessUnit         AS Department,
	|	WriteOffOfExpenses.CorLineOfBusiness AS LineOfBusiness,
	|	WriteOffOfExpenses.CorExpenseItem        AS AssetRef,
	|	WriteOffOfExpenses.CorExpenditureDimension     AS Dimension,
	|	WriteOffOfExpenses.CorSettingUpAccountingAccounts  AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	WriteOffOfExpenses.SumMan                 AS SumMan,
	|	WriteOffOfExpenses.SumMan                 AS AmountIncludingVAT,
	|	WriteOffOfExpenses.AmountExcludingVAT              AS AmountExcludingVAT,
	|
	|	WriteOffOfExpenses.SumCompl                AS SumCompl,
	|	WriteOffOfExpenses.PermanentDifference        AS PermanentDifference,
	|
	|	WriteOffOfExpenses.SumCompl 
	|		- WriteOffOfExpenses.AmountFA 
	|		- WriteOffOfExpenses.PermanentDifference  AS CostTD,
	|
	|	WriteOffOfExpenses.RowID AS FinRecordID,
	|	&SettingUpHO_ClosingExpensesFromFADebiting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(WriteOffOfExpenses.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|
	|UNION ALL
	|
	|SELECT
	|	WriteOffOfExpenses.Recorder              AS Recorder,
	|	WriteOffOfExpenses.Period                   AS Period,
	|	WriteOffOfExpenses.Organization              AS Organization,
	|	WriteOffOfExpenses.DebitBusinessUnit         AS Department,
	|	WriteOffOfExpenses.CorLineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.FixedAssetSaleWithDeferredTransferOfTitleIs) AS AssetRef,
	|	WriteOffOfExpenses.FixedAsset         AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	WriteOffOfExpenses.SumMan                 AS SumMan,
	|	WriteOffOfExpenses.SumMan                 AS AmountIncludingVAT,
	|	WriteOffOfExpenses.AmountExcludingVAT              AS AmountExcludingVAT,
	|
	|	WriteOffOfExpenses.SumCompl                AS SumCompl,
	|	WriteOffOfExpenses.PermanentDifference        AS PermanentDifference,
	|
	|	WriteOffOfExpenses.SumCompl 
	|		- WriteOffOfExpenses.AmountFA 
	|		- WriteOffOfExpenses.PermanentDifference  AS CostTD,
	|
	|	WriteOffOfExpenses.RowID      AS FinRecordID,
	|	&SettingUpHO_ClosingExpensesFromOSSImplementationByDeferredTransferOfRights AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|
	|UNION ALL
	|
	|SELECT
	|	TransferredObjects.Recorder             AS Recorder,
	|	TransferredObjects.DateRightsWereTransferred        AS Period,
	|	TransferredObjects.Organization             AS Organization,
	|	TransferredObjects.DebitBusinessUnit        AS Department,
	|	TransferredObjects.CorLineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.FixedAssetSaleWithDeferredTransferOfTitleIs) AS AssetRef,
	|	TransferredObjects.FixedAsset        AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TransferredObjects.SumMan                AS SumMan,
	|	TransferredObjects.SumMan                AS AmountIncludingVAT,
	|	TransferredObjects.AmountExcludingVAT             AS AmountExcludingVAT,
	|
	|	TransferredObjects.SumCompl               AS SumCompl,
	|	TransferredObjects.PermanentDifference       AS PermanentDifference,
	|
	|	TransferredObjects.SumCompl 
	|		- TransferredObjects.AmountFA 
	|		- TransferredObjects.PermanentDifference AS CostTD,
	|
	|	TransferredObjects.RowID     AS FinRecordID,
	|	&SettingUpHo_ClosingExpensesFromFAImplementationAfterTransferOfRights AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TransferredObjects AS TransferredObjects
	|		ON TransferredObjects.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(TransferredObjects.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND BEGINOFPERIOD(TransferredObjects.DateRightsWereTransferred, MONTH) = &RegisterRecordsPeriod
	|	AND TransferredObjects.RightsTransferred
	|";
	
	QueryTexts.Add(QueryText, "OtherAssetsAndLiabilitiesRecords", True);
	
EndProcedure

// Generates the query text for the register table "Movement of income and expenditure of other assets".
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts) Export
	
	ListOfMergeRequests = New Array;
	
	#Region WriteOffOfExpenses_PerCostItem // Dt <costs> - Ct 01.09
	QueryText =
	"SELECT
	|	WriteOffOfExpenses.Recorder                 AS Recorder,
	|	WriteOffOfExpenses.Period                      AS Period,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|			THEN &BO_CloseFixedAssetSalesExpensesWithDeferredTitleTransfer
	|		ELSE &BO_CloseFixedAssetWriteOffExpenses
	|	END AS BusinessOperation,
	|
	|	WriteOffOfExpenses.Organization                 AS Organization,
	|
	|	WriteOffOfExpenses.Department               AS Department,
	|	WriteOffOfExpenses.LineOfBusiness     AS LineOfBusiness,
	|	WriteOffOfExpenses.ExpenseItem              AS AssetRef,
	|	WriteOffOfExpenses.DimensionOfExpenses           AS DimensionOfExpenses,
	|	UNDEFINED                                 AS AssetsLiabilitiesDimension,
	|
	|	WriteOffOfExpenses.DebitBusinessUnit            AS DebitBusinessUnit,
	|	WriteOffOfExpenses.CorLineOfBusiness  AS CorLineOfBusiness,
	|	WriteOffOfExpenses.CorExpenseItem           AS CorItem,
	|	WriteOffOfExpenses.CorExpenditureDimension        AS CorExpenditureDimension,
	|	UNDEFINED                                 AS CorDimensionOfAssetsLiabilities,
	|
	|	WriteOffOfExpenses.Sum                       AS Sum,
	|	WriteOffOfExpenses.SumMan                    AS SumMan,
	|	WriteOffOfExpenses.SumCompl                   AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(WriteOffOfExpenses.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region WriteOffOfExpenses_ForItemOfAssets // Dt <costs> - Ct 01.09
	QueryText =
	"SELECT
	|	WriteOffOfExpenses.Recorder                 AS Recorder,
	|	WriteOffOfExpenses.Period                      AS Period,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|			THEN &BO_CloseFixedAssetSalesExpensesWithDeferredTitleTransfer
	|		ELSE &BO_CloseFixedAssetWriteOffExpenses
	|	END AS BusinessOperation,
	|
	|	WriteOffOfExpenses.Organization                 AS Organization,
	|
	|	WriteOffOfExpenses.Department               AS Department,
	|	WriteOffOfExpenses.LineOfBusiness     AS LineOfBusiness,
	|	WriteOffOfExpenses.ExpenseItem              AS AssetRef,
	|	WriteOffOfExpenses.DimensionOfExpenses           AS DimensionOfExpenses,
	|	UNDEFINED                                 AS AssetsLiabilitiesDimension,
	|
	|	WriteOffOfExpenses.DebitBusinessUnit            AS DebitBusinessUnit,
	|	WriteOffOfExpenses.CorLineOfBusiness  AS CorLineOfBusiness,
	|	WriteOffOfExpenses.CorExpenseItem           AS CorItem,
	|	UNDEFINED                                 AS CorExpenditureDimension,
	|	WriteOffOfExpenses.CorDimensionOfAssetsLiabilities AS CorDimensionOfAssetsLiabilities,
	|
	|	WriteOffOfExpenses.Sum                       AS Sum,
	|	WriteOffOfExpenses.SumMan                    AS SumMan,
	|	WriteOffOfExpenses.SumCompl                   AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|		ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|WHERE
	|	VALUETYPE(WriteOffOfExpenses.CorExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(QueryText, "RecordsIncomeExpensesOtherAssetsLiabilities", True);
	
EndProcedure

// Generates the query text for the register table "Movement Nomenclature Income Expenses".
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableRegisterRecordsProductsIncomeExpenses(QueryTexts) Export
	
	QueryText =
	"SELECT
	|	InventoryCostAdjustment.Recorder             AS Recorder,
	|	InventoryCostAdjustment.Period                  AS Period,
	|	&BO_CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets AS BusinessOperation,
	|	InventoryCostAdjustment.Organization             AS Organization,
	|	InventoryCostAdjustment.DebitBusinessUnit        AS Department,
	|
	|	CASE 
	|		WHEN ISNULL(BatchAccountingParameters.KeepRecordsOfInventoryCostByAssignments, FALSE)
	|			THEN InventoryCostAdjustment.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END AS ItemsLocationAttributes,
	|
	|	InventoryCostAdjustment.Warehouse                   AS Warehouse,
	|	InventoryCostAdjustment.InventoryOwnerAttribute.InventoryType   AS InventoryType,
	|	InventoryCostAdjustment.InventoryOwnerAttribute              AS InventoryOwnerAttribute,
	|
	|	InventoryCostAdjustment.ExpenseItem          AS IncomeAndExpenseItem,
	|	InventoryCostAdjustment.DimensionOfExpenses       AS DimensionOfExpenses,
	|
	|	-InventoryCostAdjustment.SumMan               AS Cost,
	|	-InventoryCostAdjustment.SumMan               AS CostExcludingVAT,
	|	-InventoryCostAdjustment.SumCompl              AS LocalCost,
	|
	|	CASE
	|		WHEN ISNULL(BatchAccountingParameters.GenerateInventoryOwnerAttributesByFinancialAccountingGroups, FALSE)
	|			THEN InventoryCostAdjustment.InventoryOwnerAttribute
	|		ELSE InventoryCostAdjustment.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	InventoryCostAdjustment.CorLineOfBusiness AS LineOfBusinessItems,
	|	InventoryCostAdjustment.Purpose.LineOfBusiness AS ProductLineOfBusiness
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN InventoryCostAdjustment AS InventoryCostAdjustment
	|		ON InventoryCostAdjustment.Recorder = DocumentData.Ref
	|
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryCostAdjustment.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN TTParametersOfBatchAccountingForConducting AS BatchAccountingParameters
	|		ON BatchAccountingParameters.Period = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|			AND BatchAccountingParameters.Organization = DocumentData.Organization
	|";
	
	QueryTexts.Add(QueryText, "RegisterRecordsProductsIncomeExpenses", True);
	
EndProcedure

// Generates the Query Text for the table of the register "Reflection of documents in the register".
// 
// Parameters:
//  QueryTexts - ValueList - Request texts
Procedure QueryTextTableReflectionOfDocumentsInLocalAccounting(QueryTexts) Export

	QueryText =
	"SELECT DISTINCT
	|	DocumentData.Recorder AS Recorder,
	|	DocumentData.Recorder AS Document,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.DateRecord AS DateRecord
	|
	|FROM
	|	(SELECT 
	|		WriteOffOfExpenses.Recorder AS Recorder,
	|		WriteOffOfExpenses.Organization AS Organization,
	|		BEGINOFPERIOD(WriteOffOfExpenses.Period, DAY) AS DateRecord
	|
	|	FROM
	|		DocumentDataDetails AS DocumentData
	|
	|			INNER JOIN WriteOffOfExpenses AS WriteOffOfExpenses
	|			ON WriteOffOfExpenses.Recorder = DocumentData.Ref
	|
	|	UNION ALL
	|
	|	SELECT 
	|		InventoryCostAdjustment.Recorder AS Recorder,
	|		InventoryCostAdjustment.Organization AS Organization,
	|		BEGINOFPERIOD(InventoryCostAdjustment.Period, DAY) AS DateRecord
	|
	|	FROM
	|		DocumentDataDetails AS DocumentData
	|
	|			INNER JOIN InventoryCostAdjustment AS InventoryCostAdjustment
	|			ON InventoryCostAdjustment.Recorder = DocumentData.Ref
	|
	|	UNION ALL
	|
	|	SELECT 
	|		TransferredObjects.Recorder AS Recorder,
	|		TransferredObjects.Organization AS Organization,
	|		BEGINOFPERIOD(TransferredObjects.Period, DAY) AS DateRecord
	|
	|	FROM
	|		DocumentDataDetails AS DocumentData
	|
	|			INNER JOIN TransferredObjects AS TransferredObjects
	|			ON TransferredObjects.Recorder = DocumentData.Ref
	|
	|	WHERE
	|		TransferredObjects.RealEstate
	|		AND (TransferredObjects.AmountFA <> 0
	|			OR TransferredObjects.AmountFA = 0
	|				AND TransferredObjects.PermanentDifference <> 0)
	|
	|	UNION ALL
	|
	|	SELECT 
	|		TransferredObjects.Recorder AS Recorder,
	|		TransferredObjects.Organization AS Organization,
	|		BEGINOFPERIOD(TransferredObjects.DateRightsWereTransferred, DAY) AS DateRecord
	|
	|	FROM
	|		DocumentDataDetails AS DocumentData
	|
	|			INNER JOIN TransferredObjects AS TransferredObjects
	|			ON TransferredObjects.Recorder = DocumentData.Ref
	|
	|	WHERE
	|		TransferredObjects.RightsTransferred
	|
	|	) AS DocumentData
	|";
	
	QueryTexts.Add(QueryText, "ReflectionOfDocumentsInLocalAccounting", True);
	
EndProcedure

// Sets the request parameters that are used when performing the operation.
// 
// Parameters:
//  Query - Query - Query
Procedure SetRequestParameters(Query) Export
	
	Query.SetParameter(
		"BO_CloseFixedAssetWriteOffExpenses",
		Enums.BusinessTransactions.CloseFixedAssetWriteOffExpenses);
	
	Query.SetParameter(
		"SettingUpHO_ClosingExpensesFromFADebiting", 
		Catalogs.BusinessTransactionsSettings.CloseFixedAssetWriteOffExpenses);
	
	Query.SetParameter(
		"BO_CloseFixedAssetSalesExpenses", 
		Enums.BusinessTransactions.CloseFixedAssetSalesExpenses);
		
	Query.SetParameter(
		"SettingUpHO_ClosingExpensesFromFAImplementation", 
		Catalogs.BusinessTransactionsSettings.CloseFixedAssetSalesExpenses);
	
	Query.SetParameter(
		"BO_CloseFixedAssetSalesExpensesWithDeferredTitleTransfer", 
		Enums.BusinessTransactions.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer);
	
	Query.SetParameter(
		"SettingUpHO_ClosingExpensesFromOSSImplementationByDeferredTransferOfRights", 
		Catalogs.BusinessTransactionsSettings.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer);
	
	Query.SetParameter(
		"BO_CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer", 
		Enums.BusinessTransactions.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer);
	
	Query.SetParameter(
		"SettingUpHo_ClosingExpensesFromFAImplementationAfterTransferOfRights", 
		Catalogs.BusinessTransactionsSettings.CloseExpensesOnFixedAssetSalesAfterTheTitleTransfer);
	
	Query.SetParameter(
		"BO_CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets", 
		Enums.BusinessTransactions.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets);
	
	Query.SetParameter(
		"SettingHO_AdjustmentOfCostOfInventoryRegisteredAtDisposalOfFA", 
		Catalogs.BusinessTransactionsSettings.CostAdjustmentOfInventoryRecordedAtDisposalOfFixedAssets);
	
	Query.SetParameter(
		"BO_AdjustmentOfExpensesFromDisposalOfFixedAssets", 
		Enums.BusinessTransactions.AdjustmentOfExpensesFromDisposalOfFixedAssets);
	
	Query.SetParameter(
		"SettingHO_AdjustmentOfExpensesFromDisposalOfFA", 
		Catalogs.BusinessTransactionsSettings.AdjustmentOfExpensesFromDisposalOfFixedAssets);
	
	Query.SetParameter(
		"GenerateInventoryOwnerAttributesByFinancialAccountingGroups", 
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.SetParameter(
		"IDOfUnusedFinRecord", 
		DocumentsPosting.IDOfUnusedFinRecord());
		
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region PerformingTransaction

Procedure CreateListOfObjects(ExecutionParameters)
	
	QueryText = 
	"SELECT
	|	ListOfObjects.AccountingObject AS AccountingObject
	|
	|INTO ListOfObjects
	|
	|FROM
	|	&ListOfObjects AS ListOfObjects
	|
	|INDEX BY
	|	AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.SetParameter("ListOfObjects", ExecutionParameters.ListOfObjects);
	
	Query.Execute();
	
EndProcedure

Procedure CreateTTTableWithAllDataToBeCalculated(BeginOfPeriod, EndOfPeriod, CompaniesList, TempTablesManager)

	QueryText =
	"SELECT DISTINCT
	|	AllDocuments.Ref AS Ref,
	|	AllDocuments.Date AS Date,
	|	AllDocuments.Organization AS Organization,
	|	CAST(AllDocuments.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|	AllDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	AllDocuments.RecordInManAccounting AS RecordInManAccounting,
	|	AllDocuments.BusinessOperation AS BusinessOperation,
	|	AllDocuments.AccountingObject AS AccountingObject,
	|	1 AS Priority
	|
	|INTO TTAllDataToBeCalculated
	|
	|FROM	
	|	(SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		FATable.FixedAsset AS AccountingObject
	|
	|	FROM
	|		Document.DisposeFixedAssets2_4 AS CurrentDocuments
	|		
	|			INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|			ON FATable.Ref = CurrentDocuments.Ref
	|
	|	WHERE
	|		CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND CurrentDocuments.Posted
	|
	|		AND FATable.FixedAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		TRUE AS RecordInLocalAccounting,
	|		TRUE AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		FATable.NonCurrentAsset AS AccountingObject
	|
	|	FROM
	|		Document.CustomerInvoiceServicesAndAssets AS CurrentDocuments
	|		
	|			INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS FATable
	|			ON FATable.Ref = CurrentDocuments.Ref
	|				AND FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|
	|	WHERE
	|		CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND CurrentDocuments.Posted
	|
	|		AND CurrentDocuments.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|			VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|
	|		AND FATable.NonCurrentAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.DateOfTransferOfTitleToGoods AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		TRUE AS RecordInLocalAccounting,
	|		TRUE AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		FATable.NonCurrentAsset AS AccountingObject
	|
	|	FROM
	|		Document.CustomerInvoiceServicesAndAssets AS CurrentDocuments
	|		
	|			INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS FATable
	|			ON FATable.Ref = CurrentDocuments.Ref
	|				AND FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|
	|	WHERE
	|		CurrentDocuments.DateOfTransferOfTitleToGoods BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|       AND BEGINOFPERIOD(CurrentDocuments.DateOfTransferOfTitleToGoods, MONTH) <> BEGINOFPERIOD(CurrentDocuments.Date, MONTH)
	|		AND CurrentDocuments.Organization IN (&CompaniesList)
	|		AND CurrentDocuments.Posted
	|
	|		AND CurrentDocuments.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|			VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|
	|		AND FATable.NonCurrentAsset IN (
	|				SELECT
	|					ListOfObjects.AccountingObject
	|				FROM
	|					ListOfObjects AS ListOfObjects)
	|
	|	) AS AllDocuments
	|
	|INDEX BY
	|	AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("CompaniesList", CompaniesList);
	
	Query.Execute();
	
EndProcedure

Procedure GenerateRegisteredRecordsBasedOnDocuments(Period, ExecutionParameters)
	
	TempTablesManager = ExecutionParameters.TempTablesManager;
	
	PrepareParameters(Period, TempTablesManager);
	MovementTables = PrepareTablesOfRegisteredRecords(Period, TempTablesManager);
	WriteMotionTables(Period, MovementTables, ExecutionParameters);
	
EndProcedure

Procedure PrepareParameters(Period, TempTablesManager)
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("WriteOffOfExpenses");
	TTUsed.Add("InventoryCostAdjustment");
	TTUsed.Add("CostAdjustment_");
	TTUsed.Add("TransferredObjects");

	NonCurrentAssets.CreateTTTableOfDataToBeCalculated(TempTablesManager);
	
	ListOfRequests = New Array;
	
	#Region DisposalsAndBalances
	
	QueryText = 
	"SELECT
	|	DisposeFixedAssets.Ref AS Ref,
	|	DisposeFixedAssets.Date AS Date,
	|	DisposeFixedAssets.Organization AS Organization,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.RowID AS RowID,
	|	VALUE(Enum.BusinessTransactions.DisposeFixedAssets) AS DisposalOperation,
	|
	|	FALSE AS RightsTransferred,
	|	DisposeFixedAssets.Date AS DateRightsWereTransferred,
	|
	|	DisposeFixedAssets.BusinessOperation AS BusinessOperation,
	|	DisposeFixedAssets.ExpenseItem AS ExpenseItem,
	|	DisposeFixedAssets.DimensionOfExpenses AS DimensionOfExpenses,
	|	DisposeFixedAssets.DimensionCorrespondsToFAToWriteOff AS AnalyticsCorrespondsToItemBeingWrittenOff,
	|
	|	DisposeFixedAssets.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DisposeFixedAssets.GLAccountSettings AS GLAccountSettings,
	|
	|	DisposeFixedAssets.ExpensesBusinessUnit AS ExpensesBusinessUnit,
	|	DisposeFixedAssets.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DisposeFixedAssets.BusinessUnitAndLineOfBusinessMatchAccountingData AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|
	|	FATable.AmountManagementAccounting AS AmountManagementAccounting,
	|	FATable.ChargeAmountAccounting AS ChargeAmountAccounting,
	|	FATable.AmountTaxAccounting AS AmountTaxAccounting,
	|	FATable.AmountPermanentDifference AS AmountPermanentDifference
	|
	|INTO FADisposal
	|
	|FROM
	|	Document.DisposeFixedAssets2_4 AS DisposeFixedAssets
	|		
	|		INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|		ON FATable.Ref = DisposeFixedAssets.Ref
	|
	|WHERE
	|	DisposeFixedAssets.Ref IN
	|		(SELECT
	|			TTDataToBeCalculated.Ref
	|		FROM
	|			TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	FixedAssetSale.Ref AS Ref,
	|	FixedAssetSale.Date AS Date,
	|	FixedAssetSale.Organization AS Organization,
	|	FATable.NonCurrentAsset AS FixedAsset,
	|	FATable.RowID AS RowID,
	|	VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale) AS DisposalOperation,
	|
	|	FixedAssetSale.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|		AND FixedAssetSale.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped) AS RightsTransferred,
	|
	|	FixedAssetSale.DateOfTransferOfTitleToGoods AS DateRightsWereTransferred,
	|
	|	FixedAssetSale.BusinessOperation AS BusinessOperation,
	|	FATable.ExpenseItem AS ExpenseItem,
	|	FATable.DimensionOfExpenses AS DimensionOfExpenses,
	|	FALSE AS AnalyticsCorrespondsToItemBeingWrittenOff,
	|
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS GLAccountSettings,
	|
	|	UNDEFINED AS ExpensesBusinessUnit,
	|	UNDEFINED AS ExpenseLineOfBusiness,
	|	TRUE AS BusinessUnitAndLineOfBusinessMatchAccountingData,
	|
	|	0 AS AmountManagementAccounting,
	|	0 AS ChargeAmountAccounting,
	|	0 AS AmountTaxAccounting,
	|	0 AS AmountPermanentDifference
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS FixedAssetSale
	|		
	|		INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS FATable
	|		ON FATable.Ref = FixedAssetSale.Ref
	|			AND FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|
	|WHERE
	|	FixedAssetSale.Ref IN
	|		(SELECT
	|			TTDataToBeCalculated.Ref
	|		FROM
	|			TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	FADisposal.Organization AS Organization,
	|	FADisposal.FixedAsset AS FixedAsset
	|
	|INTO FilterObjects_
	|
	|FROM
	|	FADisposal AS FADisposal
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem IN (
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses),
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.LongTermAssetsToBeSold),
	|				VALUE(ChartOfCharacteristicTypes.ExpenseItems.TangibleAssetSale))
	|			THEN VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|		ELSE VALUE(Enum.BusinessTransactions.DisposeFixedAssets)
	|	END AS DisposalOperation,
	|
	|	SUM(OtherExpenses.Sum) AS Sum,
	|	SUM(OtherExpenses.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(OtherExpenses.SumMan) AS SumMan,
	|
	|	SUM(OtherExpenses.SumCompl) AS SumCompl,
	|	SUM(OtherExpenses.SumCompl - OtherExpenses.PermanentDifference - OtherExpenses.CostTD) AS AmountFA,
	|	SUM(OtherExpenses.PermanentDifference) AS PermanentDifference
	|
	|INTO FAWriteOffExpenses
	|
	|FROM
	|	(SELECT
	|		OtherExpenses.Organization AS Organization,
	|		OtherExpenses.Department AS Department,
	|		OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|		OtherExpenses.ExpenseItem AS ExpenseItem,
	|		OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|		OtherExpenses.SumBalance AS Sum,
	|		OtherExpenses.AmountExcludingVATBalance AS AmountExcludingVAT,
	|		OtherExpenses.SumManBalance AS SumMan,
	|
	|		OtherExpenses.SumComplBalance AS SumCompl,
	|		OtherExpenses.PermanentDifferenceBalance AS PermanentDifference,
	|		OtherExpenses.CostTDBalance AS CostTD
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(
	|			&BeginningOfNextPeriod,
	|			 ExpenseItem IN (&ArticleFADisposal)
	|				AND (Organization, DimensionOfExpenses) IN (
	|					SELECT
	|						FilterObjects_.Organization,
	|						FilterObjects_.FixedAsset
	|					FROM
	|						FilterObjects_ AS FilterObjects_)
	|		) AS OtherExpenses
	|
	|	UNION ALL
	|
	|	SELECT
	|		OtherExpenses.Organization AS Organization,
	|		OtherExpenses.Department AS Department,
	|		OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|		OtherExpenses.ExpenseItem AS ExpenseItem,
	|		OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.Sum
	|			ELSE -OtherExpenses.Sum
	|		END AS Sum,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.AmountExcludingVAT
	|			ELSE -OtherExpenses.AmountExcludingVAT
	|		END AS AmountExcludingVAT,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.SumMan
	|			ELSE -OtherExpenses.SumMan
	|		END AS SumMan,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.SumCompl
	|			ELSE -OtherExpenses.SumCompl
	|		END AS SumCompl,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.PermanentDifference
	|			ELSE -OtherExpenses.PermanentDifference
	|		END AS PermanentDifference,
	|
	|		CASE
	|			WHEN OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN OtherExpenses.CostTD
	|			ELSE -OtherExpenses.CostTD
	|		END AS CostTD
	|
	|	FROM
	|		AccumulationRegister.OtherExpenses AS OtherExpenses
	|	WHERE
	|		OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND OtherExpenses.Active
	|		AND OtherExpenses.ExpenseItem IN (&ArticleFADisposal)
	|		AND OtherExpenses.SourceKind = VALUE(Enum.MovementSourcesKinds.ClosingExpensesFromDisposalOfFixedAssets)
	|		AND (OtherExpenses.Organization, OtherExpenses.DimensionOfExpenses) IN (
	|				SELECT
	|					FilterObjects_.Organization,
	|					FilterObjects_.FixedAsset
	|				FROM
	|					FilterObjects_ AS FilterObjects_)
	|
	|		) AS OtherExpenses
	|
	|GROUP BY
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses)
	|			THEN VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale)
	|		ELSE VALUE(Enum.BusinessTransactions.DisposeFixedAssets)
	|	END
	|
	|INDEX BY
	|	DimensionOfExpenses
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AuxiliaryData
	QueryText =
	"SELECT TOP 0
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|	VALUE(Catalog.Assets.EmptyRef) AS FixedAsset,
	|	FALSE AS RealEstate
	|
	|INTO AuxiliaryData";
	

	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DisposalOfOS_Distribution
	QueryText =
	"SELECT
	|	FADisposal.FixedAsset AS FixedAsset,
	|	FADisposal.DisposalOperation AS DisposalOperation,
	|
	|	SUM(FADisposal.AmountManagementAccounting) AS SumOfMaBase,
	|	SUM(FADisposal.ChargeAmountAccounting) AS SumOfBaseAC,
	|	SUM(FADisposal.AmountTaxAccounting) AS BaseSumTa,
	|	SUM(FADisposal.AmountPermanentDifference) AS AmountOfPDDatabase
	|
	|INTO DisposalOfOS_AmountOfBase
	|FROM
	|	FADisposal AS FADisposal
	|
	|GROUP BY
	|	FADisposal.FixedAsset,
	|	FADisposal.DisposalOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FADisposal.FixedAsset AS FixedAsset,
	|	FADisposal.DisposalOperation AS DisposalOperation,
	|
	|	SUM(ISNULL(DisposalOfOS_Previous.AmountManagementAccounting, 0)) AS BaseAccumulatedMa,
	|	SUM(ISNULL(DisposalOfOS_Previous.ChargeAmountAccounting, 0)) AS BaseAccumulatedAC,
	|	SUM(ISNULL(DisposalOfOS_Previous.AmountTaxAccounting, 0)) AS BaseAccumulatedTa,
	|	SUM(ISNULL(DisposalOfOS_Previous.AmountPermanentDifference, 0)) AS BaseAccumulatedPD
	|	
	|INTO DisposalOfOS_BaseAccumulated
	|
	|FROM
	|	FADisposal AS FADisposal
	|		
	|		LEFT JOIN FADisposal AS DisposalOfOS_Previous
	|		ON DisposalOfOS_Previous.FixedAsset = FADisposal.FixedAsset
	|			AND DisposalOfOS_Previous.DisposalOperation = FADisposal.DisposalOperation
	|			AND DisposalOfOS_Previous.Ref < FADisposal.Ref
	|
	|GROUP BY
	|	FADisposal.FixedAsset,
	|	FADisposal.DisposalOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FADisposal.Ref AS Ref,
	|	FADisposal.FixedAsset AS FixedAsset,
	|	FADisposal.DisposalOperation AS DisposalOperation,
	|
	|	1 AS MaBase,
	|	0 AS BaseAccumulatedMa,
	|	1 AS SumOfMaBase,
	|
	|	1 AS BaseAC,
	|	0 AS BaseAccumulatedAC,
	|	1 AS SumOfBaseAC,
	|
	|	1 AS BaseTa,
	|	0 AS BaseAccumulatedTa,
	|	1 AS BaseSumTa,
	|
	|	1 AS BasePD,
	|	0 AS BaseAccumulatedPD,
	|	1 AS AmountOfPDDatabase
	|
	|INTO DisposalOfOS_Distribution
	| 
	|FROM
	|	FADisposal AS FADisposal
	|
	|WHERE
	|	FADisposal.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.DisposeFixedAssets),
	|		VALUE(Enum.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation),
	|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|
	|UNION ALL
	|
	|SELECT
	|	FADisposal.Ref AS Ref,
	|	FADisposal.FixedAsset AS FixedAsset,
	|	FADisposal.DisposalOperation AS DisposalOperation,
	|
	|	FADisposal.AmountManagementAccounting AS MaBase,
	|	DisposalOfOS_BaseAccumulated.BaseAccumulatedMa AS BaseAccumulatedMa,
	|	DisposalOfOS_AmountOfBase.SumOfMaBase AS SumOfMaBase,
	|
	|	FADisposal.ChargeAmountAccounting AS BaseAC,
	|	DisposalOfOS_BaseAccumulated.BaseAccumulatedAC AS BaseAccumulatedAC,
	|	DisposalOfOS_AmountOfBase.SumOfBaseAC AS SumOfBaseAC,
	|
	|	FADisposal.AmountTaxAccounting AS BaseTa,
	|	DisposalOfOS_BaseAccumulated.BaseAccumulatedTa AS BaseAccumulatedTa,
	|	DisposalOfOS_AmountOfBase.BaseSumTa AS BaseSumTa,
	|	
	|	FADisposal.AmountPermanentDifference AS BasePD,
	|	DisposalOfOS_BaseAccumulated.BaseAccumulatedPD AS BaseAccumulatedPD,
	|	DisposalOfOS_AmountOfBase.AmountOfPDDatabase AS AmountOfPDDatabase
	|
	|FROM
	|	FADisposal AS FADisposal
	|		
	|		LEFT JOIN DisposalOfOS_AmountOfBase AS DisposalOfOS_AmountOfBase
	|		ON DisposalOfOS_AmountOfBase.FixedAsset = FADisposal.FixedAsset
	|			AND DisposalOfOS_AmountOfBase.DisposalOperation = FADisposal.DisposalOperation
	|
	|		LEFT JOIN DisposalOfOS_BaseAccumulated AS DisposalOfOS_BaseAccumulated
	|		ON DisposalOfOS_BaseAccumulated.FixedAsset = FADisposal.FixedAsset
	|			AND DisposalOfOS_BaseAccumulated.DisposalOperation = FADisposal.DisposalOperation
	|
	|WHERE
	|	FADisposal.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsDisposal)
	|	AND NOT FADisposal.FixedAsset IN (
	|			SELECT
	|				TotalFADisposal.FixedAsset
	|			FROM
	|				FADisposal AS TotalFADisposal
	|			WHERE
	|				TotalFADisposal.FixedAsset = FADisposal.FixedAsset
	|				AND TotalFADisposal.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation),
	|					VALUE(Enum.BusinessTransactions.DisposeFixedAssets)))
	|
	|INDEX BY
	|	FixedAsset,
	|	Ref";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ClosingPositiveRemainder
	QueryText =
	"SELECT
	|	FADisposal.Ref                                  AS Recorder,
	|	DisposalOfOS_Distribution.Period                    AS Period,
	|
	|	FADisposal.RowID                     AS RowID,
	|
	|	FADisposal.ExpenseItem                          AS CorExpenseItem,
	|
	|	CASE
	|		WHEN FADisposal.AnalyticsCorrespondsToItemBeingWrittenOff
	|			THEN FADisposal.FixedAsset
	|		ELSE FADisposal.DimensionOfExpenses
	|	END AS CorExpenditureDimension,
	|
	|	FADisposal.AssetsLiabilitiesDimension                AS CorDimensionOfAssetsLiabilities,
	|	FADisposal.GLAccountSettings                    AS CorSettingUpAccountingAccounts,
	|
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DisposalOfOS_Distribution.Department
	|		ELSE FADisposal.ExpensesBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DisposalOfOS_Distribution.LineOfBusiness
	|		ELSE FADisposal.ExpenseLineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	FADisposal.BusinessOperation                   AS BusinessOperation,
	|	FADisposal.FixedAsset                        AS FixedAsset,
	|
	|	DisposalOfOS_Distribution.Organization               AS Organization,
	|	DisposalOfOS_Distribution.Department             AS Department,
	|	DisposalOfOS_Distribution.ExpenseItem            AS ExpenseItem,
	|	DisposalOfOS_Distribution.DimensionOfExpenses         AS DimensionOfExpenses,
	|	DisposalOfOS_Distribution.LineOfBusiness   AS LineOfBusiness,
	|
	|	ISNULL(AuxiliaryData.RealEstate, FALSE) AS RealEstate,
	|	FADisposal.RightsTransferred AS RightsTransferred,
	|	FADisposal.DateRightsWereTransferred AS DateRightsWereTransferred,
	|
	|	SUM(DisposalOfOS_Distribution.Sum) AS Sum,
	|	SUM(DisposalOfOS_Distribution.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(DisposalOfOS_Distribution.SumMan) AS SumMan,
	|	SUM(DisposalOfOS_Distribution.SumCompl) AS SumCompl,
	|	SUM(DisposalOfOS_Distribution.AmountFA) AS AmountFA,
	|	SUM(DisposalOfOS_Distribution.PermanentDifference) AS PermanentDifference
	|
	|INTO WriteOffOfExpenses
	|
	|FROM
	|	(SELECT
	|		DisposalOfOS_Distribution.Ref                    AS Ref,
	|		DisposalOfOS_Distribution.FixedAsset          AS FixedAsset,
	|		DisposalOfOS_Distribution.DisposalOperation           AS DisposalOperation,
	|		FADisposal.Date                                    AS Period,
	|		FAWriteOffExpenses.Organization                  AS Organization,
	|		FAWriteOffExpenses.Department                AS Department,
	|		FAWriteOffExpenses.ExpenseItem               AS ExpenseItem,
	|		FAWriteOffExpenses.DimensionOfExpenses            AS DimensionOfExpenses,
	|		FAWriteOffExpenses.LineOfBusiness      AS LineOfBusiness,
	|
	|		CASE
	|			WHEN FAWriteOffExpenses.SumMan > 0
	|				THEN &Sum_Distribution
	|			ELSE 0
	|		END AS Sum,
	|
	|		CASE
	|			WHEN FAWriteOffExpenses.SumMan > 0
	|				THEN &SumWithoutNDS_Distribution
	|			ELSE 0
	|		END AS AmountExcludingVAT,
	|
	|		CASE
	|			WHEN FAWriteOffExpenses.SumMan > 0
	|				THEN &AmountOfMan_Distribution
	|			ELSE 0
	|		END AS SumMan,
	|
	|		CASE
	|			WHEN FAWriteOffExpenses.SumCompl > 0
	|				THEN &SumOfLocal_Distribution
	|			ELSE 0
	|		END AS SumCompl,
	|
	|		CASE
	|			WHEN FAWriteOffExpenses.AmountFA > 0
	|					OR FAWriteOffExpenses.AmountFA = 0
	|						AND FAWriteOffExpenses.PermanentDifference <> 0
	|				THEN &SumOfNUL_Distribution
	|			ELSE 0
	|		END AS AmountFA,
	|
	|		CASE
	|			WHEN FAWriteOffExpenses.AmountFA > 0
	|					OR FAWriteOffExpenses.AmountFA = 0
	|						AND FAWriteOffExpenses.PermanentDifference <> 0
	|				THEN &ConstantDifference_Distribution
	|			ELSE 0
	|		END AS PermanentDifference
	| 
	|	FROM
	|		FAWriteOffExpenses AS FAWriteOffExpenses
	|
	|			INNER JOIN DisposalOfOS_Distribution AS DisposalOfOS_Distribution
	|			ON DisposalOfOS_Distribution.FixedAsset = FAWriteOffExpenses.DimensionOfExpenses
	|				AND DisposalOfOS_Distribution.DisposalOperation = FAWriteOffExpenses.DisposalOperation
	|
	|			INNER JOIN FADisposal AS FADisposal
	|			ON FADisposal.Ref = DisposalOfOS_Distribution.Ref
	|				AND FADisposal.FixedAsset = DisposalOfOS_Distribution.FixedAsset
	|				AND FADisposal.DisposalOperation = DisposalOfOS_Distribution.DisposalOperation
	|
	|	WHERE
	|		(FAWriteOffExpenses.SumMan > 0
	|			OR FAWriteOffExpenses.SumCompl > 0
	|			OR FAWriteOffExpenses.AmountFA > 0
	|			OR FAWriteOffExpenses.AmountFA = 0
	|				AND FAWriteOffExpenses.PermanentDifference <> 0)
	|
	|		AND FADisposal.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|
	|	) AS DisposalOfOS_Distribution
	|
	|		INNER JOIN FADisposal AS FADisposal
	|		ON FADisposal.Ref = DisposalOfOS_Distribution.Ref
	|			AND FADisposal.FixedAsset = DisposalOfOS_Distribution.FixedAsset
	|			AND FADisposal.DisposalOperation = DisposalOfOS_Distribution.DisposalOperation
	|
	|		LEFT JOIN AuxiliaryData AS AuxiliaryData
	|		ON AuxiliaryData.Organization = FADisposal.Organization
	|			AND AuxiliaryData.FixedAsset = FADisposal.FixedAsset
	|
	|GROUP BY
	|	FADisposal.Ref,
	|	DisposalOfOS_Distribution.Period,
	|	FADisposal.RowID,
	|	FADisposal.ExpenseItem,
	|	CASE
	|		WHEN FADisposal.AnalyticsCorrespondsToItemBeingWrittenOff
	|			THEN FADisposal.FixedAsset
	|		ELSE FADisposal.DimensionOfExpenses
	|	END,
	|	FADisposal.AssetsLiabilitiesDimension,
	|	FADisposal.GLAccountSettings,
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DisposalOfOS_Distribution.Department
	|		ELSE FADisposal.ExpensesBusinessUnit
	|	END,
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN DisposalOfOS_Distribution.LineOfBusiness
	|		ELSE FADisposal.ExpenseLineOfBusiness
	|	END,
	|	FADisposal.BusinessOperation,
	|	FADisposal.FixedAsset,
	|	DisposalOfOS_Distribution.Organization,
	|	DisposalOfOS_Distribution.Department,
	|	DisposalOfOS_Distribution.ExpenseItem,
	|	DisposalOfOS_Distribution.DimensionOfExpenses,
	|	DisposalOfOS_Distribution.LineOfBusiness,
	|	ISNULL(AuxiliaryData.RealEstate, FALSE),
	|	FADisposal.RightsTransferred,
	|	FADisposal.DateRightsWereTransferred
	|";
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"FAWriteOffExpenses.Sum",
		"DisposalOfOS_Distribution.MaBase",
		"DisposalOfOS_Distribution.BaseAccumulatedMa",
		"DisposalOfOS_Distribution.SumOfMaBase");
	QueryText = StrReplace(QueryText, "&Sum_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"FAWriteOffExpenses.AmountExcludingVAT",
		"DisposalOfOS_Distribution.MaBase",
		"DisposalOfOS_Distribution.BaseAccumulatedMa",
		"DisposalOfOS_Distribution.SumOfMaBase");
	QueryText = StrReplace(QueryText, "&SumWithoutNDS_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"FAWriteOffExpenses.SumMan",
		"DisposalOfOS_Distribution.MaBase",
		"DisposalOfOS_Distribution.BaseAccumulatedMa",
		"DisposalOfOS_Distribution.SumOfMaBase");
	QueryText = StrReplace(QueryText, "&AmountOfMan_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"FAWriteOffExpenses.SumCompl",
		"DisposalOfOS_Distribution.BaseAC",
		"DisposalOfOS_Distribution.BaseAccumulatedAC",
		"DisposalOfOS_Distribution.SumOfBaseAC");
	QueryText = StrReplace(QueryText, "&SumOfLocal_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"FAWriteOffExpenses.AmountFA",
		"DisposalOfOS_Distribution.BaseTa",
		"DisposalOfOS_Distribution.BaseAccumulatedTa",
		"DisposalOfOS_Distribution.BaseSumTa");
	QueryText = StrReplace(QueryText, "&SumOfNUL_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"FAWriteOffExpenses.PermanentDifference",
		"DisposalOfOS_Distribution.BasePD",
		"DisposalOfOS_Distribution.BaseAccumulatedPD",
		"DisposalOfOS_Distribution.AmountOfPDDatabase");
	QueryText = StrReplace(QueryText, "&ConstantDifference_Distribution", AmountDistributionText);
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region ClosingNegativeBalance
	QueryText =
	"SELECT
	|	OtherRegistration.Ref AS Ref,
	|	OtherRegistration.Date AS Date,
	|
	|	GoodsTable.Products AS Products,
	|	GoodsTable.FixedAsset AS FixedAsset,
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.ExpenseAndIncomeItem AS IncomeItem,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.Purpose AS Purpose,
	|	OtherRegistration.Warehouse AS Warehouse,
	|	OtherRegistration.Department AS Department,
	|
	|	GoodsTable.Sum AS Sum
	|	
	|INTO OtherRegistration
	|
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS OtherRegistration
	|		
	|		INNER JOIN Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|		ON GoodsTable.Ref = OtherRegistration.Ref
	|WHERE
	|	OtherRegistration.BusinessOperation = VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal)
	|	AND OtherRegistration.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND OtherRegistration.Posted
	|
	|	AND GoodsTable.FixedAsset IN (
	|			SELECT
	|				FAWriteOffExpenses.DimensionOfExpenses
	|			FROM
	|				FAWriteOffExpenses AS FAWriteOffExpenses
	|			WHERE
	|				(FAWriteOffExpenses.SumMan < 0
	|					OR FAWriteOffExpenses.SumCompl < 0))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherRegistration.FixedAsset AS FixedAsset,
	|	SUM(OtherRegistration.Sum) AS BaseAmount
	|
	|INTO OtherRegistration_DatabaseAmount
	|FROM
	|	OtherRegistration AS OtherRegistration
	|
	|GROUP BY
	|	OtherRegistration.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherRegistration.FixedAsset AS FixedAsset,
	|	OtherRegistration.Ref AS Ref,
	|	OtherRegistration.RowID AS RowID,
	|	SUM(ISNULL(OtherRegistration_Previous.Sum, 0)) AS BaseAccumulated
	|	
	|INTO OtherRegistration_AccumulatedBase
	|FROM
	|	OtherRegistration AS OtherRegistration
	|		
	|		LEFT JOIN OtherRegistration AS OtherRegistration_Previous
	|		ON OtherRegistration_Previous.FixedAsset = OtherRegistration.FixedAsset
	|			AND (OtherRegistration_Previous.Ref < OtherRegistration.Ref
	|				OR OtherRegistration_Previous.Ref = OtherRegistration.Ref
	|					AND OtherRegistration_Previous.LineNumber < OtherRegistration.LineNumber)
	|
	|GROUP BY
	|	OtherRegistration.FixedAsset,
	|	OtherRegistration.Ref,
	|	OtherRegistration.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherRegistration.Ref AS Ref,
	|	OtherRegistration.FixedAsset AS FixedAsset,
	|	OtherRegistration.RowID AS RowID,
	|
	|	OtherRegistration.Sum AS Base,
	|	OtherRegistration_AccumulatedBase.BaseAccumulated AS BaseAccumulated,
	|	OtherRegistration_DatabaseAmount.BaseAmount AS BaseAmount
	|
	|INTO OtherRegistration_Distribution
	|	
	|FROM
	|	OtherRegistration AS OtherRegistration
	|		
	|		LEFT JOIN OtherRegistration_DatabaseAmount AS OtherRegistration_DatabaseAmount
	|		ON OtherRegistration_DatabaseAmount.FixedAsset = OtherRegistration.FixedAsset
	|
	|		LEFT JOIN OtherRegistration_AccumulatedBase AS OtherRegistration_AccumulatedBase
	|		ON OtherRegistration_AccumulatedBase.FixedAsset = OtherRegistration.FixedAsset
	|			AND OtherRegistration_AccumulatedBase.Ref = OtherRegistration.Ref
	|			AND OtherRegistration_AccumulatedBase.RowID = OtherRegistration.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherRegistration.Ref                        AS Recorder,
	|	OtherRegistration.Date                          AS Period,
	|
	|	OtherRegistration.RowID           AS RowID,
	|	OtherRegistration.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	OtherRegistration.Warehouse                         AS Warehouse,
	|	OtherRegistration.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	OtherRegistration.Products                  AS Products,
	|	OtherRegistration.Department                 AS DebitBusinessUnit,
	|	OtherRegistration.LineOfBusiness       AS CorLineOfBusiness,
	|	OtherRegistration.Purpose                    AS Purpose,
	|
	|	FAWriteOffExpenses.Organization                  AS Organization,
	|	FAWriteOffExpenses.Department                AS Department,
	|	FAWriteOffExpenses.ExpenseItem               AS ExpenseItem,
	|	FAWriteOffExpenses.DimensionOfExpenses            AS DimensionOfExpenses,
	|	FAWriteOffExpenses.LineOfBusiness      AS LineOfBusiness,
	|
	|	CASE
	|		WHEN FAWriteOffExpenses.SumMan < 0
	|			THEN &Sum_Distribution
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE
	|		WHEN FAWriteOffExpenses.SumMan < 0
	|			THEN &SumWithoutNDS_Distribution
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE
	|		WHEN FAWriteOffExpenses.SumMan < 0
	|			THEN &AmountOfMan_Distribution
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN FAWriteOffExpenses.SumCompl < 0
	|			THEN &SumOfLocal_Distribution
	|		ELSE 0
	|	END AS SumCompl
	|
	|INTO InventoryCostAdjustment
	| 
	|FROM
	|	FAWriteOffExpenses AS FAWriteOffExpenses
	|
	|		INNER JOIN OtherRegistration_Distribution AS OtherRegistration_Distribution
	|		ON OtherRegistration_Distribution.FixedAsset = FAWriteOffExpenses.DimensionOfExpenses
	|
	|		INNER JOIN OtherRegistration AS OtherRegistration
	|		ON OtherRegistration.Ref = OtherRegistration_Distribution.Ref
	|			AND OtherRegistration.RowID = OtherRegistration_Distribution.RowID
	|
	|WHERE
	|	(FAWriteOffExpenses.SumMan < 0
	|		OR FAWriteOffExpenses.SumCompl < 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OtherRegistration.Ref                        AS Recorder,
	|	OtherRegistration.Date                          AS Period,
	|
	|	OtherRegistration.RowID           AS RowID,
	|	OtherRegistration.IncomeItem                 AS IncomeItem,
	|	OtherRegistration.DimensionOfRevenue              AS DimensionOfRevenue,
	|
	|	FAWriteOffExpenses.Organization                  AS Organization,
	|	FAWriteOffExpenses.Department                AS Department,
	|	FAWriteOffExpenses.ExpenseItem               AS ExpenseItem,
	|	FAWriteOffExpenses.DimensionOfExpenses            AS DimensionOfExpenses,
	|	FAWriteOffExpenses.LineOfBusiness      AS LineOfBusiness,
	|
	|	&SumOfNUL_Distribution AS AmountFA,
	|
	|	&ConstantDifference_Distribution AS PermanentDifference
	|
	|INTO CostAdjustment_
	| 
	|FROM
	|	FAWriteOffExpenses AS FAWriteOffExpenses
	|
	|		INNER JOIN OtherRegistration_Distribution AS OtherRegistration_Distribution
	|		ON OtherRegistration_Distribution.FixedAsset = FAWriteOffExpenses.DimensionOfExpenses
	|
	|		INNER JOIN OtherRegistration AS OtherRegistration
	|		ON OtherRegistration.Ref = OtherRegistration_Distribution.Ref
	|			AND OtherRegistration.RowID = OtherRegistration_Distribution.RowID
	|
	|WHERE
	|	(FAWriteOffExpenses.AmountFA < 0)";
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"-FAWriteOffExpenses.Sum",
		"OtherRegistration_Distribution.Base",
		"OtherRegistration_Distribution.BaseAccumulated",
		"OtherRegistration_Distribution.BaseAmount");
	QueryText = StrReplace(QueryText, "&Sum_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"-FAWriteOffExpenses.AmountExcludingVAT",
		"OtherRegistration_Distribution.Base",
		"OtherRegistration_Distribution.BaseAccumulated",
		"OtherRegistration_Distribution.BaseAmount");
	QueryText = StrReplace(QueryText, "&SumWithoutNDS_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"-FAWriteOffExpenses.SumMan",
		"OtherRegistration_Distribution.Base",
		"OtherRegistration_Distribution.BaseAccumulated",
		"OtherRegistration_Distribution.BaseAmount");
	QueryText = StrReplace(QueryText, "&AmountOfMan_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"-FAWriteOffExpenses.SumCompl",
		"OtherRegistration_Distribution.Base",
		"OtherRegistration_Distribution.BaseAccumulated",
		"OtherRegistration_Distribution.BaseAmount");
	QueryText = StrReplace(QueryText, "&SumOfLocal_Distribution", AmountDistributionText);
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"-FAWriteOffExpenses.AmountFA",
		"OtherRegistration_Distribution.Base",
		"OtherRegistration_Distribution.BaseAccumulated",
		"OtherRegistration_Distribution.BaseAmount");
	QueryText = StrReplace(QueryText, "&SumOfNUL_Distribution", AmountDistributionText);

	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"-FAWriteOffExpenses.PermanentDifference",
		"OtherRegistration_Distribution.Base",
		"OtherRegistration_Distribution.BaseAccumulated",
		"OtherRegistration_Distribution.BaseAmount");
	QueryText = StrReplace(QueryText, "&ConstantDifference_Distribution", AmountDistributionText);
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	// Emulation Of The Balance on account 45 at the time of the operation
	#Region TransferredObjects
	QueryText =
	"SELECT
	|	TransferredObjects.Recorder               AS Recorder,
	|	TransferredObjects.Period                    AS Period,
	|
	|	TransferredObjects.RowID       AS RowID,
	|	FADisposal.FixedAsset                  AS FixedAsset,
	|
	|	TransferredObjects.CorExpenseItem         AS CorExpenseItem,
	|	TransferredObjects.CorExpenditureDimension      AS CorExpenditureDimension,
	|
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TransferredObjects.Department
	|		ELSE FADisposal.ExpensesBusinessUnit
	|	END AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TransferredObjects.LineOfBusiness
	|		ELSE FADisposal.ExpenseLineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	|	TransferredObjects.Organization               AS Organization,
	|	TransferredObjects.Department             AS Department,
	|	TransferredObjects.LineOfBusiness   AS LineOfBusiness,
	|
	|	ISNULL(AuxiliaryData.RealEstate, FALSE) AS RealEstate,
	|	FADisposal.RightsTransferred AS RightsTransferred,
	|	FADisposal.DateRightsWereTransferred AS DateRightsWereTransferred,
	|
	|	SUM(TransferredObjects.Sum)                     AS Sum,
	|	SUM(TransferredObjects.AmountExcludingVAT)               AS AmountExcludingVAT,
	|	SUM(TransferredObjects.SumMan)                  AS SumMan,
	|	SUM(TransferredObjects.SumCompl)                 AS SumCompl,
	|	SUM(TransferredObjects.AmountFA)                   AS AmountFA,
	|	SUM(TransferredObjects.PermanentDifference)         AS PermanentDifference
	|
	|INTO TransferredObjects
	|
	|FROM
	|	(
		// Movements that are generated during the execution (they are not yet included in other expenses) Dr 45 - Cr 01.09
	|	SELECT
	|		WriteOffOfExpenses.Recorder               AS Recorder,
	|		WriteOffOfExpenses.Period                    AS Period,
	|
	|		WriteOffOfExpenses.RowID       AS RowID,
	|
	|		WriteOffOfExpenses.CorExpenseItem         AS CorExpenseItem,
	|		WriteOffOfExpenses.CorExpenditureDimension      AS CorExpenditureDimension,
	|
	|		WriteOffOfExpenses.Organization               AS Organization,
	|		WriteOffOfExpenses.Department             AS Department,
	|		WriteOffOfExpenses.LineOfBusiness   AS LineOfBusiness,
	|
	|		WriteOffOfExpenses.Sum                     AS Sum,
	|		WriteOffOfExpenses.AmountExcludingVAT               AS AmountExcludingVAT,
	|		WriteOffOfExpenses.SumMan                  AS SumMan,
	|		WriteOffOfExpenses.SumCompl                 AS SumCompl,
	|
	|		WriteOffOfExpenses.AmountFA                   AS AmountFA,
	|		WriteOffOfExpenses.PermanentDifference         AS PermanentDifference
	|	FROM
	|		WriteOffOfExpenses AS WriteOffOfExpenses
	| 
	|	WHERE
	|		WriteOffOfExpenses.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|
	|	UNION ALL
	|
		// Movements generated in other expenses Dr 45 - Cr 01.09
	|	SELECT
	|		FADisposal.Ref                           AS Recorder,
	|		FADisposal.Date                             AS Period,
	|
	|		FADisposal.RowID              AS RowID,
	|
	|		FADisposal.ExpenseItem                   AS CorExpenseItem,
	|		FADisposal.DimensionOfExpenses                AS CorExpenditureDimension,
	|
	|		FADisposal.Organization                      AS Organization,
	|		OtherExpenses.Department                AS Department,
	|		OtherExpenses.LineOfBusiness      AS LineOfBusiness,
	|
	|		OtherExpenses.Sum                        AS Sum,
	|		OtherExpenses.AmountExcludingVAT                  AS AmountExcludingVAT,
	|		OtherExpenses.SumMan                     AS SumMan,
	|		OtherExpenses.SumCompl                    AS SumCompl,
	|
	|		CASE
	|			WHEN ISNULL(AuxiliaryData.RealEstate, FALSE)
	|				THEN 0
	|			ELSE OtherExpenses.SumCompl
	|					- OtherExpenses.PermanentDifference
	|					- OtherExpenses.PermanentDifference
	|		END AS AmountFA,
	|
	|		CASE
	|			WHEN ISNULL(AuxiliaryData.RealEstate, FALSE)
	|				THEN 0
	|			ELSE OtherExpenses.PermanentDifference
	|		END AS PermanentDifference
	|
	|	FROM
	|		FADisposal AS FADisposal
	|
	|			LEFT JOIN AuxiliaryData AS AuxiliaryData
	|			ON AuxiliaryData.Organization = FADisposal.Organization
	|				AND AuxiliaryData.FixedAsset = FADisposal.FixedAsset
	|	
	|			INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
	|			ON OtherExpenses.Recorder = FADisposal.Ref
	|				AND OtherExpenses.DimensionOfExpenses = FADisposal.FixedAsset
	|				AND OtherExpenses.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.CloseFixedAssetSalesExpensesWithDeferredTitleTransfer)
	|				AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND OtherExpenses.Active
	|
	|	WHERE
	|		FADisposal.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	|		AND FADisposal.RightsTransferred
	|		AND FADisposal.DateRightsWereTransferred > ENDOFPERIOD(FADisposal.Date, MONTH)
	|		AND FADisposal.DateRightsWereTransferred BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|
	|	) AS TransferredObjects
	|
	|		INNER JOIN FADisposal AS FADisposal
	|		ON FADisposal.Ref = TransferredObjects.Recorder
	|			AND FADisposal.RowID = TransferredObjects.RowID
	|
	|		LEFT JOIN AuxiliaryData AS AuxiliaryData
	|		ON AuxiliaryData.Organization = FADisposal.Organization
	|			AND AuxiliaryData.FixedAsset = FADisposal.FixedAsset
	|
	|GROUP BY
	|	TransferredObjects.Recorder,
	|	TransferredObjects.Period,
	|	TransferredObjects.RowID,
	|	TransferredObjects.CorExpenseItem,
	|	TransferredObjects.CorExpenditureDimension,
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TransferredObjects.Department
	|		ELSE FADisposal.ExpensesBusinessUnit
	|	END,
	|	CASE
	|		WHEN FADisposal.BusinessUnitAndLineOfBusinessMatchAccountingData
	|			THEN TransferredObjects.LineOfBusiness
	|		ELSE FADisposal.ExpenseLineOfBusiness
	|	END,
	|	FADisposal.FixedAsset,
	|	TransferredObjects.Organization,
	|	TransferredObjects.Department,
	|	TransferredObjects.LineOfBusiness,
	|	ISNULL(AuxiliaryData.RealEstate, FALSE),
	|	FADisposal.RightsTransferred,
	|	FADisposal.DateRightsWereTransferred
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Period));
	Query.SetParameter("BeginningOfNextPeriod", EndOfMonth(Period) + 1);
	
	ArticleFADisposal = New Array;
	ArticleFADisposal.Add(ChartsOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses);
	ArticleFADisposal.Add(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetRetirement);
	ArticleFADisposal.Add(ChartsOfCharacteristicTypes.ExpenseItems.TangibleAssetSale);
	ArticleFADisposal.Add(ChartsOfCharacteristicTypes.ExpenseItems.FASellingExpenses);
	ArticleFADisposal.Add(ChartsOfCharacteristicTypes.ExpenseItems.LongTermAssetsToBeSold);
	Query.SetParameter("ArticleFADisposal", ArticleFADisposal);
	
	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
EndProcedure

Function PrepareTablesOfRegisteredRecords(Period, TempTablesManager)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ClosingExpensesFromDisposalOfFixedAssets.PrepareTablesOfRegisteredRecords");

	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TTListOfDocuments");

	QueryText = 
	"SELECT DISTINCT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Period AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	(SELECT
	|		TTPortionOfDataToBeCalculated.Ref AS Ref,
	|		TTPortionOfDataToBeCalculated.Date AS Period,
	|		TTPortionOfDataToBeCalculated.Organization AS Organization
	|	FROM
	|		TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|	UNION ALL
	|
	|	SELECT
	|		WriteOffOfExpenses.Recorder AS Ref,
	|		WriteOffOfExpenses.Period AS Period,
	|		WriteOffOfExpenses.Organization AS Organization
	|	FROM
	|		WriteOffOfExpenses AS WriteOffOfExpenses
	|
	|	UNION ALL
	|
	|	SELECT
	|		InventoryCostAdjustment.Recorder AS Ref,
	|		InventoryCostAdjustment.Period AS Period,
	|		InventoryCostAdjustment.Organization AS Organization
	|	FROM
	|		InventoryCostAdjustment AS InventoryCostAdjustment
	|
	|	UNION ALL
	|
	|	SELECT
	|		CostAdjustment_.Recorder AS Ref,
	|		CostAdjustment_.Period AS Period,
	|		CostAdjustment_.Organization AS Organization
	|	FROM
	|		CostAdjustment_ AS CostAdjustment_
	|
	|	UNION ALL
	|
	|	SELECT
	|		TransferredObjects.Recorder AS Ref,
	|		TransferredObjects.Period AS Period,
	|		TransferredObjects.Organization AS Organization
	|	FROM
	|		TransferredObjects AS TransferredObjects
	|
	|	) AS DocumentsList
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(COUNT(DISTINCT TTListOfDocuments.Ref), 0) AS Count
	|FROM
	|	TTListOfDocuments AS TTListOfDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VALUETYPE(TTListOfDocuments.Ref) AS DocumentTypeOrLink
	|FROM
	|	TTListOfDocuments AS TTListOfDocuments
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound()-1].Select();
	Selection.Next();
	DataVolume = Selection.Count;
	
	MovementTables = New Map;
	
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		
		ManagerOfDocument = Documents[Metadata.FindByType(Selection.DocumentTypeOrLink).Name];
		
		TablesOfRegisteredRecordsOfDocuments = ManagerOfDocument.TablesOfRegisteredRecordsInClosingExpensesFromDisposalOfFA(TempTablesManager, Period); // Structure
		
		For Each KeyAndValue In TablesOfRegisteredRecordsOfDocuments Do

			RegisterName = NonCurrentAssetsInternal.NameOfRegisterByNameOfRegisteredRecordsTable(KeyAndValue.Key);
			
			If Metadata.InformationRegisters.Find(RegisterName) <> Undefined 
				Or Metadata.AccumulationRegisters.Find(RegisterName) <> Undefined Then
			
				Table = KeyAndValue.Value; // ValueTable
				Table.Indexes.Add("Recorder");

			EndIf;
			
		EndDo;
		
		MovementTables.Insert(Selection.DocumentTypeOrLink, TablesOfRegisteredRecordsOfDocuments);
		
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

	Return MovementTables;
	
EndFunction

Procedure WriteMotionTables(Period, MovementTables, ExecutionParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ClosingExpensesFromDisposalOfFixedAssets.WriteMotionTables");

	TTUsed = TMCommonUse.ListOfTemporaryTables(ExecutionParameters.TempTablesManager);
	
	QueryText = 
	"SELECT DISTINCT
	|	TTListOfDocuments.Ref AS Ref,
	|	TTListOfDocuments.Period AS Period
	|FROM
	|	TTListOfDocuments AS TTListOfDocuments
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Result = Query.Execute();
	Selection = Result.Select();
	
	DataVolume = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			DocumentObject = DocumentsPosting.DocumentEmulation(Selection.Ref, Selection.Period);
			SetFlagForOperation(DocumentObject);
			
			TablesOfRegisteredRecordsOfDocuments = MovementTables.Get(TypeOf(Selection.Ref));
			
			NonCurrentAssetsInternal.WriteMotionTables(
				TablesOfRegisteredRecordsOfDocuments, 
				DocumentObject, 
				ExecutionParameters.TempTablesManager,
				ExecutionParameters.ReturnDocumentsToReflection, 
				NameOfFlagOfOperation(),
				Enums.MovementSourcesKinds.ClosingExpensesFromDisposalOfFixedAssets,
				Period);
				
			NonCurrentAssetsInternal.UpdateRegisteredRecordsOfAssetsLiabilities(Selection.Ref);
				
			DataVolume = DataVolume + 1;
			
			TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			Raise ErrorText;
			
		EndTry;
		
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

Function JobsForCalculating(CalculationParameters, NumberBeforeSettlement)
	
	AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(
		CalculationParameters.Period, CalculationParameters.CompanyArray);
	
	QueryText =
	"SELECT 
	|	BEGINOFPERIOD(Jobs.Month, Month) AS BeginOfPeriod,
	|	ENDOFPERIOD(Jobs.Month, Month) AS PeriodEnding,
	|	Jobs.Organization AS Organization
	|
	|INTO Jobs
	|
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|
	|WHERE
	|	Jobs.Operation = &Operation
	|	AND (Jobs.Month <= &PeriodEnding
	|		OR &PeriodEnding = DATETIME(1,1,1))
	|
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND (Jobs.Organization IN (&Companies)
	|			OR &ByAllCompanies)
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	PeriodEnding,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Jobs.BeginOfPeriod       AS Month,
	|	Jobs.Organization         AS Organization,
	|	FATable.FixedAsset  AS AccountingObject
	|
	|INTO JobsForCalculating
	|
	|FROM
	|	Jobs AS Jobs
	|
	|		INNER JOIN Document.DisposeFixedAssets2_4 AS CurrentDocuments
	|		ON CurrentDocuments.Organization = Jobs.Organization
	|			AND CurrentDocuments.Date >= Jobs.BeginOfPeriod
	|			AND CurrentDocuments.Date <= &PeriodEnding
	|			AND CurrentDocuments.Posted
	|		
	|		INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|		ON FATable.Ref = CurrentDocuments.Ref
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Jobs.BeginOfPeriod       AS Month,
	|	Jobs.Organization         AS Organization,
	|	FATable.NonCurrentAsset AS AccountingObject
	|
	|FROM
	|	Jobs AS Jobs
	|
	|		INNER JOIN Document.CustomerInvoiceServicesAndAssets AS CurrentDocuments
	|		ON CurrentDocuments.Organization = Jobs.Organization
	|			AND (CurrentDocuments.Date >= Jobs.BeginOfPeriod
	|					AND CurrentDocuments.Date <= &PeriodEnding
	|				OR CurrentDocuments.DateOfTransferOfTitleToGoods >= Jobs.BeginOfPeriod
	|					AND CurrentDocuments.DateOfTransferOfTitleToGoods <= &PeriodEnding)
	|			AND CurrentDocuments.Posted
	|			AND CurrentDocuments.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|				VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|		
	|		INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS FATable
	|		ON FATable.Ref = CurrentDocuments.Ref
	|			AND FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MIN(JobsForCalculating.Month), DATETIME(1,1,1)) AS BeginOfPeriod
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Jobs.Organization
	|FROM
	|	Jobs AS Jobs
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Operation", Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets);
	Query.SetParameter("PeriodEnding", EndOfMonth(CalculationParameters.Period));
	Query.SetParameter("JobNumber", NumberBeforeSettlement);
	Query.SetParameter("Companies", AvailableCompanies);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(AvailableCompanies));
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound()-1].Select();
	If Selection.Next() Then
		BeginningOfTaskPeriod = Selection.BeginOfPeriod;
	Else
		BeginningOfTaskPeriod = '000101010000';
	EndIf;
	
	JobsForCalculating = New Structure;
	JobsForCalculating.Insert("CompaniesList", Result[Result.UBound()].Unload().UnloadColumn("Organization"));
	JobsForCalculating.Insert("BeginOfPeriod", BeginningOfTaskPeriod);
	JobsForCalculating.Insert("TempTablesManager", Query.TempTablesManager);
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager,, "JobsForCalculating");

	Return JobsForCalculating;
			
EndFunction

Procedure DeleteTasksByDate(ExecutionParameters)
	
	If Not ExecutionParameters.DeleteTasks Then
		Return;
	EndIf;

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ClosingExpensesFromDisposalOfFixedAssets.DeleteTasksByDate");

	QueryText =
	"SELECT DISTINCT
	|	Jobs.Month AS Month,
	|	Jobs.Organization AS Organization,
	|	Jobs.Operation AS Operation,
	|	Jobs.JobNumber AS JobNumber
	|
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS Jobs
	|
	|WHERE
	|	Jobs.Month <= &PeriodEnding
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND Jobs.Organization IN (&CompaniesList)
	|	AND Jobs.Operation = VALUE(Catalog.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets)
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.SetParameter("PeriodEnding", ExecutionParameters.EndOfPeriod);
	Query.SetParameter("CompaniesList", ExecutionParameters.CompaniesList);
	Query.SetParameter("JobNumber", ExecutionParameters.NumberBeforeSettlement);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		Set = InformationRegisters.JobsForMonthEndClosing.CreateRecordSet();
		Set.Filter.Month.Set(Selection.Month);
		Set.Filter.Organization.Set(Selection.Organization);
		Set.Filter.Operation.Set(Selection.Operation);
		Set.Filter.JobNumber.Set(Selection.JobNumber);
		Set.Write(); 
		
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Function CreateTaskQueue(ExecutionParameters, ForSpecifiedAccountingObjects, TempTablesManager)

	DataChunkSize = DataChunkSize();
	
	TaskQueue = NonCurrentAssets.InitiateTaskQueue();
	
	CreateTTTableWithListOfDocuments(
		ExecutionParameters.BeginOfPeriod, ExecutionParameters.EndOfPeriod, ExecutionParameters.CompaniesList, ForSpecifiedAccountingObjects, TempTablesManager);

	ObjectQueue = NonCurrentAssets.QueueOfSLEObjects(TempTablesManager);
	
	TaskQueue = NonCurrentAssets.CreateTasksFromQueueOfObjects(
		ObjectQueue, 
		DataChunkSize, 
		"ClosingExpensesFromDisposalOfFixedAssets.PerformOfOperationOnObjects",
		ExecutionParameters, 
		NStr("vi = 'Đóng chi phí thanh lý tài sản cố định (đối tượng từ %1 đến %2, tổng số %3)';
			|ru = 'Закрытие расходов от выбытия ОС (объекты с %1 по %2, всего %3)';
			|en = 'Close fixed asset retirement expenses (objects from %1 to %2, %3 in total)'; fa = 'Close fixed asset retirement expenses (objects from %1 to %2, %3 in total)';
			|it = 'Закрытие расходов от выбытия ОС (объекты с %1 по %2, всего %3)';
			|pl = 'Close fixed asset retirement expenses (objects from %1 to %2, %3 in total)';
			|tr = 'Sabit kıymet çekerek giderlerin kapatılması (%1 ila %2 aralığı, %3 kısmının tümü)'"));
	
	Return TaskQueue;
	
EndFunction

Procedure CreateTTTableWithListOfDocuments(BeginOfPeriod, EndOfPeriod, CompaniesList, ForSpecifiedAccountingObjects, TempTablesManager)
	
	QueryText =
	"SELECT DISTINCT
	|	CurrentDocuments.Ref AS Ref
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.DisposeFixedAssets2_4 AS CurrentDocuments
	|		
	|		INNER JOIN Document.DisposeFixedAssets2_4.FA AS FATable
	|		ON FATable.Ref = CurrentDocuments.Ref
	|
	|WHERE
	|	CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CurrentDocuments.Organization IN (&CompaniesList)
	|	AND CurrentDocuments.Posted
	|
	|	AND (NOT &ForSpecifiedAccountingObjects
	|		OR FATable.FixedAsset IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CurrentDocuments.Ref AS Ref
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS CurrentDocuments
	|		
	|		INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS FATable
	|		ON FATable.Ref = CurrentDocuments.Ref
	|			AND FATable.AssetKind = VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset)
	|
	|WHERE
	|	(CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		OR CurrentDocuments.DateOfTransferOfTitleToGoods BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|
	|	AND CurrentDocuments.Organization IN (&CompaniesList)
	|	AND CurrentDocuments.Posted
	|
	|	AND CurrentDocuments.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale),
	|		VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))
	|
	|	AND (NOT &ForSpecifiedAccountingObjects
	|		OR FATable.NonCurrentAsset IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating))
	|
	|INDEX BY
	|	Ref
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("ForSpecifiedAccountingObjects", ForSpecifiedAccountingObjects);
	
	Query.Execute();
	
EndProcedure

Procedure GetPortionOfDataToBeCalculated(BeginOfPeriod, ExecutionParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("ClosingExpensesFromDisposalOfFixedAssets.GetPortionOfDataToBeCalculated");
	
	QueryText =
	"SELECT DISTINCT
	|	TTAllDataToBeCalculated.Ref AS Ref,
	|	TTAllDataToBeCalculated.Date AS Date,
	|	TTAllDataToBeCalculated.Date AS Period,
	|	TTAllDataToBeCalculated.Organization AS Organization,
	|	TTAllDataToBeCalculated.ParentCompany AS ParentCompany,
	|	TTAllDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TTAllDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|	TTAllDataToBeCalculated.BusinessOperation AS BusinessOperation,
	|	TTAllDataToBeCalculated.AccountingObject AS AccountingObject,
	|	TTAllDataToBeCalculated.Priority AS Priority
	|
	|INTO TTPortionOfDataToBeCalculated
	|
	|FROM
	|	TTAllDataToBeCalculated AS TTAllDataToBeCalculated
	|
	|WHERE
	|	TTAllDataToBeCalculated.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|";

	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfMonth(BeginOfPeriod));
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();

	DataVolume = Selection.Count;
	
	ExecutionParameters.DataVolume = ExecutionParameters.DataVolume + DataVolume;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

// The name of the flag for performing the Operation.
// 
// Returns:
//  String -  The Name Of The Flag of Operation
Function NameOfFlagOfOperation() Export
	Return "ClosingExpensesFromDisposalOfFixedAssets";
EndFunction

#EndRegion

#Region Other

Procedure DefineChangesForGeneratingTasks(TempTablesManager)
	
	ListOfRequests = New Array;
	
	If TempTablesManager.Tables.Find("ChangesTableOtherExpenses") <> Undefined Then
		
		QueryText =
		"SELECT DISTINCT
		|	Table.Period            AS Period,
		|	Table.Organization       AS Organization,
		|	Table.Recorder       AS Document
		|INTO OtherExpenses_AssignmentsToCloseFADisposalExpensesUpdate
		|FROM
		|	ChangesTableOtherExpenses AS Table
		|WHERE
		|	Table.ExpenseItem IN (
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.FAWriteOffExpenses),
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.TangibleAssetRetirement),
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.TangibleAssetSale),
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.FASellingExpenses),
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.LongTermAssetsToBeSold))
		|	AND NOT Table.Recorder REFS Document.ProvideAssetsToLeasee2_4";
	
		ListOfRequests.Add(QueryText);
		
	EndIf;

	If TempTablesManager.Tables.Find("CustomerInvoiceServicesAndAssetsUpdate") <> Undefined Then
		
		QueryText =
		"SELECT DISTINCT
		|	Table.Period AS Period,
		|	Table.Organization AS Organization,
		|	Table.Document AS Document
		|INTO SaleOfServicesOfOtherAssets_AssignmentsForClosingExpensesFromDisposalOfFAUpdate
		|FROM
		|	CustomerInvoiceServicesAndAssetsUpdate AS Table
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Table.DateOfTransferOfTitleToGoods AS Period,
		|	Table.Organization AS Organization,
		|	Table.Document AS Document
		|FROM
		|	CustomerInvoiceServicesAndAssetsUpdate AS Table
		|WHERE
		|	Table.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
		|	AND Table.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|	AND Table.DateOfTransferOfTitleToGoods <> DATETIME(1,1,1)
		|";
	
		ListOfRequests.Add(QueryText);
		
	EndIf;

	If ListOfRequests.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = StrConcat(ListOfRequests,  Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure SetFlagForOperation(DocumentObject) Export
	
	DocumentObject.AdditionalProperties.Insert(NameOfFlagOfOperation(), True);
	
EndProcedure

Function MaximumNumberOfTasks()

	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets); // Number
							
	MaximumNumberOfTasks = ParameterValues.MaximumNumberOfTasks; // Number
	
	Return MaximumNumberOfTasks;

EndFunction

Function DataChunkSize()
	
	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets);
  							
	DataChunkSize = ParameterValues.DataChunkSize; // Number
	 		
	Return DataChunkSize;
	
EndFunction

#EndRegion

#EndRegion
