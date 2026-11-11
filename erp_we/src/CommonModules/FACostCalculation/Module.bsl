////////////////////////////////////////////////////////////////////////////////
// Procedures of the mechanism for calculating the value of non-current assets.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region MonthEndTransactions

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost);
		
	NewRow.MultilingualName = "vi = 'Tính toán giá trị tài sản cố định và tài sản cố định vô hình';
								|ru = 'Расчет стоимости ОС и НМА';
								|en = 'Calculation of fixed asset and intangible asset value';
								|it = 'Calcolo del costo capitale fisso e attività immateriali';
								|pl = 'Obliczenie kosztów ŚT oraz WNM';
								|tr = 'SV ve GMA maliyetinin hesaplanması'"; // @NStr-1
	NewRow.PreviousStages_.Add(
		NonCurrentAssetsLocalization.OperationOfSwitchingToFixedAndIntangibleAssets2_4());
	
	NewRow.TextExecute = NStr("vi = 'Tính toán';
								|ru = 'Рассчитать';
								|en = 'Calculate'; fa = 'محاسبه';
								|it = 'Рассчитать';
								|pl = 'Calculate';
								|tr = 'Hesapla'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FACostCalculation.DetermineStatusOfOperationClosingMonth");
		
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FACostCalculation.PerformMonthClosingOfOperation");
		
EndProcedure

// Determines the Status of operation of the closing of the month "Formation of Movement".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure DetermineStatusOfOperationClosingMonth(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(HandlerParameters.CalculationParameters.Period) Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Kế toán cho tài sản dài hạn phiên bản 2.4 không được sử dụng.';
				|ru = 'Учет внеоборотных активов версии 2.4 не используется.';
				|en = 'Accounting of fixed assets 2.4 is not used.'; fa = 'Accounting of fixed assets 2.4 is not used.';
				|it = 'La contabilità degli attivi non circolanti versione 2.4 non viene utilizzata.';
				|pl = 'Ewidencja aktyw pozaobrotowych wersji 2.4 nie jest używana.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi versiyon 2.4 kullanılmamaktadır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If Not CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(HandlerParameters.CalculationParameters.Period) Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Kế toán chi phí bị vô hiệu hóa, chi phí không có sẵn.';
				|ru = 'Учет себестоимости отключен, расчет стоимости недоступен.';
				|en = 'Cost accounting is disabled. Cost calculation is unavailable.'; fa = 'Cost accounting is disabled. Cost calculation is unavailable.';
				|it = 'Il registro del costo è disabilitato, il calcolo del costo non è disponibile.';
				|pl = 'Rachunek kosztów własnych jest wyłączony, kalkulacja wartości nie jest dostępna.';
				|tr = 'Maliyet muhasebesi devre dışı bırakılmıştır ve maliyetlendirme mevcut değildir.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If NonCurrentAssets.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, Metadata.InformationRegisters.JobsForCalculatingNonCurrentAssetCost.Name) Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not ThereAreDocumentsAccordingToWhichRegisteredRecordsAreFormed(HandlerParameters) Then
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có chứng từ nào để tính toán chi phí.';
				|ru = 'Нет документов по которым требуется расчет стоимости.';
				|en = 'No documents that require cost calculation.'; fa = 'No documents that require cost calculation.';
				|it = 'Non ci sono documenti per i quali è richiesto il calcolo dei costi.';
				|pl = 'Nie ma dokumentów, według których wymagane jest obliczenie kosztów własnych.';
				|tr = 'Maliyetlendirilmesi gereken herhangi bir belge bulunmamaktadır.'", Common.DefaultLanguageCode()));
	EndIf;
	
EndProcedure

// Performs the Operation of closing the month "Formation of Movement".
// 
// Parameters:
//  HandlerParameters - See DataProcessors.MonthEndClosingOperations.InitializeStageHandlerParameters
Procedure PerformMonthClosingOfOperation(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;

	If Not NonCurrentAssets.TransitionToVNAHasBeenCompleted24(CalculationParameters.Period, CalculationParameters.CompanyArray)
		Or Not NonCurrentAssets.VNAManagementIsUsed_2_4(EndOfMonth(CalculationParameters.Period)) Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.CalculationOfNonCurrentAssetsCost");
	
	NumberBeforeSettlement = InformationRegisters.JobsForCalculatingNonCurrentAssetCost.IncreaseTaskNumber();
	
	AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(
		CalculationParameters.Period, CalculationParameters.CompanyArray);
	
	JobsForCalculating = InformationRegisters.JobsForCalculatingNonCurrentAssetCost.JobsForCalculating(
			'000101010000', EndOfMonth(CalculationParameters.Period), NumberBeforeSettlement, AvailableCompanies);
	
	Result = ExecuteOperation(
		JobsForCalculating.BeginOfPeriod, 
		EndOfMonth(CalculationParameters.Period), 
		JobsForCalculating.CompaniesList, 
		NumberBeforeSettlement,
		JobsForCalculating.TempTablesManager,
		HandlerParameters.CalculationID);
		
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
	ParameterDetails.Description = NStr("vi = 'Số lượng các nhiệm vụ được thực hiện cùng lúc khi tạo bản ghi kết chuyển theo TSCĐ hữu hình và TSCĐ vô hình';
										|ru = 'Количество одновременно выполняемых заданий расчета стоимости ОС и НМА';
										|en = 'Number of simultaneous jobs for cost calculation of FA and IA'; fa = 'Number of simultaneous jobs for cost calculation of FA and IA';
										|it = 'Количество одновременно выполняемых заданий расчета стоимости ОС и НМА';
										|pl = 'Number of simultaneous jobs for cost calculation of FA and IA';
										|tr = 'Sabit kıymetlerin ve maddi olmayan varlıkların maliyetinin hesaplanması için eş zamanlı olarak gerçekleştirilen görevlerin sayısı'");
	ParameterDetails.ValueType = New TypeDescription("Number",,, New NumberQualifiers(2, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith = 1;
	ParameterDetails.DefaultValue = 4;
	ParameterDetails.LongDesc =
		NStr("vi = 'Việc tính giá trị TSCĐ hữu hình và TSCĐ vô hình có thể được thực hiện cùng lúc bởi một số nhiệm vụ nền.
              |Việc tăng số lượng nhiệm vụ có thể làm giảm tính toán.
              |Nên thiết lập số lượng nhiệm vụ tùy thuộc vào cấu hình server của hệ thống quản trị CSDL và server 1C:Enterprise.';
              |ru = 'Расчет стоимости ОС и НМА может выполняться одновременно несколькими фоновыми заданиями.
              |Увеличение количества заданий может уменьшить время расчета.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'Cost of fixed assets and intangible assets can be calculated simultaneously by several background jobs.
              |Increasing the number of jobs can reduce the calculation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'Cost of fixed assets and intangible assets can be calculated simultaneously by several background jobs.
              |Increasing the number of jobs can reduce the calculation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'Расчет стоимости ОС и НМА может выполняться одновременно несколькими фоновыми заданиями.
              |Увеличение количества заданий может уменьшить время расчета.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'Cost of fixed assets and intangible assets can be calculated simultaneously by several background jobs.
              |Increasing the number of jobs can reduce the calculation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'Sabit kıymetlerin ve maddi olmayan varlıkların maliyetinin hesaplanması birden fazla arka plan işi tarafından eş zamanlı olarak gerçekleştirilebilir.
              |Görev sayısının artırılması hesaplama süresini azaltabilir.
              |Veritabanı yönetim sistemi sunucusunun ve 1C:Enterprise sunucularının konfigürasyonuna bağlı olarak görev sayısının yapılandırılması önerilmektedir.'");
		
	#EndRegion
	
	#Region DataChunkSize
		
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Name = "DataChunkSize";
	ParameterDetails.Description = NStr("vi = 'Số lượng chứng từ được xử lý cùng lúc';
										|ru = 'Количество документов обрабатываемых одновременно';
										|en = 'Number of documents processed simultaneously'; fa = 'Number of documents processed simultaneously';
										|it = 'Количество документов обрабатываемых одновременно';
										|pl = 'Number of documents processed simultaneously';
										|tr = 'Eş zamanlı olarak işlenecek belge sayısı'");
	ParameterDetails.ValueType = New TypeDescription("Number",,, New NumberQualifiers(6, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith = 1;
	ParameterDetails.DefaultValue = 100;
	ParameterDetails.LongDesc =
		NStr("vi = 'Trong một nhiệm vụ, việc tính giá trị có thể được thực hiện cùng lúc theo một số chứng từ.
              |Việc tăng số lượng chứng từ có thể làm giảm thời gian thực hiện hoạt động, nhưng tăng yêu cầu về bộ nhớ.
              |Nên thiết lập số lượng nhiệm vụ tùy thuộc vào cấu hình server của hệ thống quản trị CSDL và server 1C:Enterprise.';
              |ru = 'В одном задании расчет стоимости может выполняться одновременно по нескольким документам.
              |Увеличение количества документов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'In one job, cost can be calculated simultaneously by several documents.
              |Increasing the number of documents can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'In one job, cost can be calculated simultaneously by several documents.
              |Increasing the number of documents can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'В одном задании расчет стоимости может выполняться одновременно по нескольким документам.
              |Увеличение количества документов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'In one job, cost can be calculated simultaneously by several documents.
              |Increasing the number of documents can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'Bir görevde, maliyet hesaplaması birden fazla belge üzerinde eş zamanlı olarak gerçekleştirilebilir.
              |Belge sayısının artırılması işlem yürütme süresini azaltabilir, ancak bellek tüketimini artırabilir.
              |Veritabanı yönetim sistemi sunucusunun ve 1C:Enterprise sunucularının konfigürasyonuna bağlı olarak sayının yapılandırılması önerilmektedir.'");
		
	#EndRegion

	Return ParametersDetails;
	
EndFunction

#EndRegion

#Region PerformingTransaction

// Performs cost calculation in several threads.
// 
// Parameters:
//  BeginOfPeriod - Date - The period from which the Operation is required to be performed
//  EndOfPeriod - Date - The period for which the operation is required to be performed of operation
//  CompaniesList - Array of CatalogRef.Companies - List of organizations
//  NumberBeforeSettlement - Number - Task number
//  TempTablesManager - TempTablesManager - Contains a list of objects
//  CalculationID - UUID - calculation ID
// 
// Returns:
//  Structure - the result of Registering Recorded movements:
// 		* HasErrors - Boolean - True if errors were registered during execution
// 		* ErrorText - String - error text
// 		* DataVolume - Number - The number of objects for which Registered Records have been generated
//
Function ExecuteOperation(BeginOfPeriod, EndOfPeriod, CompaniesList, NumberBeforeSettlement, TempTablesManager, CalculationID) Export

	Result = New Structure;
	Result.Insert("HasErrors", False);
	Result.Insert("ErrorText", "");
	Result.Insert("DataVolume", 0);

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(EndOfPeriod) Then
		Return Result;
	EndIf; 
	
	TaskQueue = CreateTaskQueue(
		BeginOfPeriod, EndOfPeriod, CompaniesList, NumberBeforeSettlement, TempTablesManager);

	If TaskQueue.Count() = 0 Then
		
		InformationRegisters.JobsForCalculatingNonCurrentAssetCost.FixCalculation(
			EndOfPeriod,
			CompaniesList, 
			NumberBeforeSettlement,
			TempTablesManager,
			"JobsForCalculating");
			
		Return Result;
		
	EndIf;
	
	ExecutionResult = NonCurrentAssets.ExecuteTaskQueue(TaskQueue, MaximumNumberOfTasks(), CalculationID);
	
	Result.HasErrors = ExecutionResult.HasErrors;
	Result.ErrorText = ExecutionResult.ErrorText;
	Result.DataVolume = ExecutionResult.DataVolume;
	
	If Result.HasErrors 
		And ValueIsFilled(Result.ErrorText) Then
		
		For Each Organization In CompaniesList Do
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost, 
				EndOfPeriod,
				Organization,
				Result.ErrorText);
		
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Performs cost calculation for the specified objects.
//
// Parameters:
//  ExecutionParameters - See ExecutionParameters
// 
// Returns:
//  Number - The number of objects for which Registered Records have been generated
Function PerformOfOperationOnObjects(ExecutionParameters) Export

	If ExecutionParameters.ListOfObjects.Count() = 0 Then
		Return 0;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.PerformOfOperationOnObjects");
	
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
	
	NonCurrentAssets.CreateTTTableWithAllDataToBeCalculated(
		BeginOfPeriod, 
		ExecutionParameters.EndOfPeriod, 
		ExecutionParameters.CompaniesList, 
		NonCurrentAssetsCached.IdsOfDocumentsForWhichCostIsCalculated(), 
		ExecutionParameters.TempTablesManager);
	
	// @skip-check query-in-loop
	// Verification is disabled because processing is performed in chunks for optimization
	While BeginOfPeriod <= ExecutionParameters.EndOfPeriod Do
		
		While GetPortionOfDataToBeCalculated(BeginOfPeriod, ExecutionParameters) Do
			
			GenerateRegisteredRecordsBasedOnDocuments(BeginOfPeriod, ExecutionParameters);
			RegisterErrors(BeginOfPeriod, ExecutionParameters);
			RememberProcessedData(ExecutionParameters);
			DeleteTasksPortionsOfData(BeginOfPeriod, ExecutionParameters);
		
			TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
			
		EndDo;

		DeleteTasksByDate(BeginOfPeriod, ExecutionParameters);
		
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

// Performs the calculation of the cost of FA and IA according to documents.
//
// Parameters:
//  DocumentsList - Array of DocumentRef - A list of documents for which you want to calculate the cost.
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
	|	AllDocuments.AccountingObject AS AccountingObject,
	|	AllDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	AllDocuments.RecordInManAccounting AS RecordInManAccounting,
	|	AllDocuments.BusinessOperation AS BusinessOperation,
	|
	|	CASE
	|		WHEN VALUETYPE(AllDocuments.Ref) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|				OR VALUETYPE(AllDocuments.Ref) = TYPE(Document.DisposeFixedAssets2_4)
	|				OR VALUETYPE(AllDocuments.Ref) = TYPE(Document.DisposeIntangibleAssets2_4)
	|			THEN 999999
	|		ELSE HOUR(AllDocuments.Date)*10000 + MINUTE(AllDocuments.Date)*100 + SECOND(AllDocuments.Date)
	|	END AS Priority
	|
	|INTO JobsForCalculating
	|
	|FROM
	|	(SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		CurrentDocuments.FixedAsset AS AccountingObject
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS CurrentDocuments
	|
	|	WHERE
	|		CurrentDocuments.Ref IN (&DocumentsList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.BusinessOperation IN (&BusinessTransactions)
	|		AND CurrentDocuments.Posted
	|
	|		AND TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.JobsForCalculatingNonCurrentAssetCost AS Jobs
	|			WHERE
	|				Jobs.Organization = CurrentDocuments.Organization
	|				AND Jobs.AccountingObject = CurrentDocuments.FixedAsset
	|				AND Jobs.Month <= CurrentDocuments.Date)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CurrentDocuments.Ref AS Ref,
	|		CurrentDocuments.Date AS Date,
	|		CurrentDocuments.Organization AS Organization,
	|		CurrentDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|		CurrentDocuments.RecordInManAccounting AS RecordInManAccounting,
	|		CurrentDocuments.BusinessOperation AS BusinessOperation,
	|		CurrentDocuments.IntangibleAsset AS AccountingObject
	|	FROM
	|		InformationRegister.IntangibleAssetsDocuments AS CurrentDocuments
	|
	|	WHERE
	|		CurrentDocuments.Ref IN (&DocumentsList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.BusinessOperation IN (&BusinessTransactions)
	|		AND CurrentDocuments.Posted
	|
	|		AND TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.JobsForCalculatingNonCurrentAssetCost AS Jobs
	|			WHERE
	|				Jobs.Organization = CurrentDocuments.Organization
	|				AND Jobs.AccountingObject = CurrentDocuments.IntangibleAsset
	|				AND Jobs.Month <= CurrentDocuments.Date)
	|
	|	) AS AllDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	JobsForCalculating.Ref AS Ref,
	|	JobsForCalculating.Date AS Date,
	|	JobsForCalculating.Organization AS Organization,
	|	JobsForCalculating.ParentCompany AS ParentCompany,
	|	JobsForCalculating.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	JobsForCalculating.RecordInManAccounting AS RecordInManAccounting,
	|	JobsForCalculating.BusinessOperation AS BusinessOperation,
	|	JobsForCalculating.AccountingObject AS AccountingObject,
	|	JobsForCalculating.Priority AS Priority
	|
	|INTO TTAllDataToBeCalculated
	|
	|FROM
	|	JobsForCalculating AS JobsForCalculating
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
	TTUsed.Add("TTAllDataToBeCalculated");
	TTUsed.Add("ProcessedOneData");

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("DocumentsList", ListOfAvailableDocuments);
	Query.SetParameter("DocumentIDs", NonCurrentAssetsCached.IdsOfDocumentsForWhichCostIsCalculated());
	Query.SetParameter("BusinessTransactions", BusinessOperationsForWhichCostIsCalculated());
	
	Result = Query.Execute();
	Selection = Result.Select();

	// Verification is disabled because of operation can only be performed in one month
	//@skip-check query-in-loop
	While Selection.Next() Do
	
		ExecutionParameters = ExecutionParameters();
		ExecutionParameters.EndOfPeriod = EndOfMonth(Selection.Month);
		ExecutionParameters.ReturnDocumentsToReflection = False;
		ExecutionParameters.GenerateJobs = False;
		ExecutionParameters.DeleteTasks = False;
		ExecutionParameters.TempTablesManager = TempTablesManager;
	
		// Verification disabled
		//@skip-check query-in-loop
		While GetPortionOfDataToBeCalculated(Selection.Month, ExecutionParameters) Do
			
			GenerateRegisteredRecordsBasedOnDocuments(Selection.Month, ExecutionParameters);
			RememberProcessedData(ExecutionParameters);
		
			TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
			
		EndDo;

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
	ExecutionParameters.Insert("NumberBeforeSettlement", 0);
	ExecutionParameters.Insert("ExecuteCheck", False);
	ExecutionParameters.Insert("TempTablesManager", Undefined);
	ExecutionParameters.Insert("DataVolume", 0);

	ListOfObjects = New ValueTable();
	ListOfObjects.Columns.Add("AccountingObject", Metadata.InformationRegisters.JobsForCalculatingNonCurrentAssetCost.Dimensions.AccountingObject.Type);
	ExecutionParameters.Insert("ListOfObjects", ListOfObjects);

	Return ExecutionParameters;
	
EndFunction

#EndRegion

#Region UpdatingRecordsOfFixedAssetsAndIntangibleAssets

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_UpdatingRecordsOfFixedAssetsAndIntangibleAssets(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.UpdatingRecordsOfFixedAssetsAndIntangibleAssets,,,,
		Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost);
		
	NewRow.MultilingualName = "vi = 'Cập nhật các bản ghi kết chuyển về TSCĐ và TSCĐVH';
								|ru = 'Актуализация движений по ОС и НМА';
								|en = 'Updating records of fixed assets and intangible assets';
								|it = 'Updating records of fixed assets and intangible assets';
								|pl = 'Updating records of fixed assets and intangible assets';
								|tr = 'SV ve GMA doğrultusunda hareketlerin gerçekleştirilmesi'"; // @NStr-1
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost);

	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Выполнить';
								|pl = 'Run';
								|tr = 'Gerçekleştir'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FACostCalculation.Use_ActualizationOfRegisteredRecordsOnNonCurrentAssets");
		
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FACostCalculation.Execute_ActualizationOfRegisteredRecordsOnNonCurrentAssets");
		
EndProcedure

// Determines the Status of Operation "Actualizationmovement to non-current assets".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Use_ActualizationOfRegisteredRecordsOnNonCurrentAssets(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(HandlerParameters.CalculationParameters.Period) Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Kế toán cho tài sản dài hạn phiên bản 2.4 không được sử dụng.';
				|ru = 'Учет внеоборотных активов версии 2.4 не используется.';
				|en = 'Accounting of fixed assets 2.4 is not used.'; fa = 'Accounting of fixed assets 2.4 is not used.';
				|it = 'La contabilità degli attivi non circolanti versione 2.4 non viene utilizzata.';
				|pl = 'Ewidencja aktyw pozaobrotowych wersji 2.4 nie jest używana.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi versiyon 2.4 kullanılmamaktadır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If NonCurrentAssets.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, Metadata.InformationRegisters.JobsForUpdatingFixedAssetRecords.Name) Then
		Return;
	EndIf;
	
	If Not ThereAreDocumentsAccordingToWhichRegisteredRecordsAreFormed(HandlerParameters) Then
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có chứng từ nào để tính toán chi phí.';
				|ru = 'Нет документов по которым требуется расчет стоимости.';
				|en = 'No documents that require cost calculation.'; fa = 'No documents that require cost calculation.';
				|it = 'Non ci sono documenti per i quali è richiesto il calcolo dei costi.';
				|pl = 'Nie ma dokumentów, według których wymagane jest obliczenie kosztów własnych.';
				|tr = 'Maliyetlendirilmesi gereken herhangi bir belge bulunmamaktadır.'", Common.DefaultLanguageCode()));
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
		
EndProcedure

// Performs the Operation "Updating Register Records for FA and IA".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure Execute_ActualizationOfRegisteredRecordsOnNonCurrentAssets(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;

	If Not NonCurrentAssets.TransitionToVNAHasBeenCompleted24(CalculationParameters.Period, CalculationParameters.CompanyArray)
		Or Not NonCurrentAssets.VNAManagementIsUsed_2_4(EndOfMonth(CalculationParameters.Period)) Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.UpdatingRecordsOfFixedAssetsAndIntangibleAssets");
	
	NumberBeforeSettlement = InformationRegisters.JobsForUpdatingFixedAssetRecords.IncreaseTaskNumber();
	
	AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(
		CalculationParameters.Period, CalculationParameters.CompanyArray);
	
	JobsForCalculating = InformationRegisters.JobsForUpdatingFixedAssetRecords.JobsForCalculating(
			'000101010000', CalculationParameters.Period, NumberBeforeSettlement, AvailableCompanies);
	
	DataVolume = 0;
	HasErrors = False;
	
	Result = DeferredFARecordGeneration.ExecuteOperation(
		JobsForCalculating.BeginOfPeriod,
		EndOfMonth(CalculationParameters.Period), 
		JobsForCalculating.CompaniesList,
		NumberBeforeSettlement, 
		JobsForCalculating.TempTablesManager,
		HandlerParameters.CalculationID,
		Catalogs.MonthEndClosingOperations.UpdatingRecordsOfFixedAssetsAndIntangibleAssets);
	
	DataVolume = DataVolume + Result.DataVolume;
	HasErrors = Result.HasErrors Or HasErrors;
	
	ExecutionParameters = ClosingExpensesFromDisposalOfFixedAssets.ExecutionParameters();
	ExecutionParameters.BeginOfPeriod = BegOfMonth(JobsForCalculating.BeginOfPeriod);
	ExecutionParameters.EndOfPeriod = EndOfMonth(CalculationParameters.Period);
	ExecutionParameters.CompaniesList = JobsForCalculating.CompaniesList;
	ExecutionParameters.ExecuteCheck = False;
	ExecutionParameters.NumberBeforeSettlement = NumberBeforeSettlement;
	ExecutionParameters.TaskRegisterName = Metadata.InformationRegisters.JobsForUpdatingFixedAssetRecords.Name;
	ExecutionParameters.DeleteTasks = False;

	Result = ClosingExpensesFromDisposalOfFixedAssets.ExecuteOperation(
		ExecutionParameters,
		JobsForCalculating.TempTablesManager,
		HandlerParameters.CalculationID,
		True);
	
	DataVolume = DataVolume + Result.DataVolume;
	HasErrors = Result.HasErrors Or HasErrors;

	If HasErrors Then
	
		For Each Organization In JobsForCalculating.CompaniesList Do
		
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.UpdatingRecordsOfFixedAssetsAndIntangibleAssets, 
				CalculationParameters.Period,
				Organization,
				Result.ErrorText);
	
		EndDo;
	
	Else
		
		InformationRegisters.JobsForUpdatingFixedAssetRecords.FixCalculation(
			EndOfMonth(CalculationParameters.Period),
			JobsForCalculating.CompaniesList, 
			NumberBeforeSettlement, 
			JobsForCalculating.TempTablesManager,
			"JobsForCalculating");
			
	EndIf;

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

#EndRegion

#Region Other

// Generates tasks for calculating the cost of fixed assets and IA, if the original data has changed.
//
// Parameters:
// 	Document - DocumentObject, Undefined - The document that is being modified.
// 	TablesData - See DocumentsPosting.OldStructureTableData
Procedure GenerateJobs(Document, TablesData) Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_4")
		Or DeferredFARecordGeneration.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) 
		Or ClosingExpensesFromDisposalOfFixedAssets.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document)
		Or CalculateRentalInvestmentCost.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document)
		Or RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) Then
		Return;
	EndIf;
	
	TablesToUse = TMCommonUse.ListOfTemporaryTables(TablesData.TempTablesManager);
	
	TablesList = New Array;
	TablesList.Add("CostOfOS_TasksForCalculatingCostOfVNA");
	TablesList.Add("CostOfNMA_AssignmentsForCalculatingCostOfVNA");
	TablesList.Add("OtherExpenses_TasksForCalculatingCostOfHPA");
	
	DetermineChangeInOtherExpenses(TablesData);
	
	DataJoinText = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(
		TablesList, TablesData, "AccountingObject");
	
	If DataJoinText = "" Then
		TMCommonUse.DestroyTemporaryTables(TablesData.TempTablesManager,, TablesToUse);
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	ChangedData.Organization,
	|	ChangedData.Document,
	|	ChangedData.AccountingObject,
	|
	|	MIN(CASE
	|			WHEN ChangedData.Period < &AccountingStartDate
	|				THEN &AccountingStartDate
	|			WHEN VALUETYPE(ChangedData.Document) = TYPE(Document.EntryOfCapitalAssetsBalance2_4)
	|					OR VALUETYPE(ChangedData.Document) = TYPE(Document.OBEntryOfLeaseSettlements)
	|					OR VALUETYPE(ChangedData.Document) = TYPE(Document.EnterRentalInvestmentBalance)
	|				THEN BEGINOFPERIOD(DATEADD(ENDOFPERIOD(ChangedData.Period, MONTH), DAY, 1), MONTH)
	|			ELSE ChangedData.Period
	|		END) AS Month
	|FROM
	|	DataUnionText_Redefined AS ChangedData
	|
	|WHERE
	|   ChangedData.AccountingObject <> UNDEFINED
	|	AND ChangedData.AccountingObject <> VALUE(Catalog.Assets.EmptyRef)
	|	AND ChangedData.AccountingObject <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|	AND ChangedData.AccountingObject <> VALUE(Catalog.ConstructionObjects.EmptyRef)
	|
	|	AND ChangedData.Period >= &CostAccountingStartDate
	|	AND &UseCostAccounting
	|
	|GROUP BY
	|	ChangedData.Organization,
	|	ChangedData.Document,
	|	ChangedData.AccountingObject
	|";
		
	QueryText = StrReplace(QueryText, "DataUnionText_Redefined", "(" + DataJoinText + ")");
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TablesData.TempTablesManager;
	Query.SetParameter("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	Query.SetParameter("CostAccountingStartDate", BegOfMonth(Constants.CostAccountingStartDate.Get()));
	Query.SetParameter("UseCostAccounting", GetFunctionalOption("UseCostAccounting"));
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	InformationRegisters.JobsForCalculatingNonCurrentAssetCost.CreateRegisterEntriesBasedOnSampleData(QueryResult.Select());
	
	SetPrivilegedMode(False);
	
	TMCommonUse.DestroyTemporaryTables(TablesData.TempTablesManager,, TablesToUse);
	
EndProcedure

// Generates a table that contains accumulated expenses for accounting items.
// 
// Parameters:
//  Period - Date - Period
//  TempTablesManager - TempTablesManager - Contains a table with the following fields:
//			* Ref - DocumentRef -
//			* Date - Date -
//			* Organization - CatalogRef.Companies -
//			* AccountingObject - CatalogRef.Assets, CatalogRef.IntangibleAssets -
//
Procedure GenerateTTCurrentExpenses(Period, TempTablesManager) Export
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TTCurExpenses");
	TTUsed.Add("TTTableOfObjects");
	
	NonCurrentAssets.CreateTTTableOfDataToBeCalculated(TempTablesManager);
	
	ListOfRequests = New Array;
		
	#Region TTAccountingPolicy
	If TempTablesManager.Tables.Find("TTAccountingPolicy") = Undefined Then
		CreateTTAccountingPolicy(Period, TempTablesManager);
	EndIf;
	#EndRegion
		
	#Region TTExpensesAreDistributedByObjects
	QueryText =
	"SELECT
	|	ObjectsTable.AccountingObject AS AccountingObject
	|
	|INTO TTExpensesAreDistributedByObjects
	|
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN ObjectsTable.Ref
	|			ELSE UNDEFINED
	|		END AS DocumentMA,
	|
	|		CASE
	|			WHEN DocumentData.PostInAccounting
	|				THEN ObjectsTable.Ref
	|			ELSE UNDEFINED
	|		END AS DocumentACC,
	|
	|		ObjectsTable.FixedAsset AS AccountingObject
	|
	|	FROM
	|		Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|			INNER JOIN Document.FixedAssetsInitialRecognition2_4.FA AS ObjectsTable
	|			ON ObjectsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN ObjectsTable.Ref
	|			ELSE UNDEFINED
	|		END AS DocumentMA,
	|
	|		CASE
	|			WHEN DocumentData.RecordInLocalAccounting
	|				THEN ObjectsTable.Ref
	|			ELSE UNDEFINED
	|		END AS DocumentACC,
	|
	|		ObjectsTable.FixedAsset AS AccountingObject
	|
	|	FROM
	|		Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|			INNER JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS ObjectsTable
	|			ON ObjectsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
	|		AND ObjectsTable.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
	|		AND NOT ObjectsTable.DepreciationComponent.ConsiderResidualLiabilityValue
	|
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN ObjectsTable.Ref
	|			ELSE UNDEFINED
	|		END AS DocumentMA,
	|
	|		CASE
	|			WHEN DocumentData.PostInAccounting
	|				THEN ObjectsTable.Ref
	|			ELSE UNDEFINED
	|		END AS DocumentACC,
	|
	|		ObjectsTable.FixedAsset AS AccountingObject
	|
	|	FROM
	|		Document.AllocateVariancesToFixedAssetCost AS DocumentData
	|
	|			INNER JOIN Document.AllocateVariancesToFixedAssetCost.FA AS ObjectsTable
	|			ON ObjectsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
	|		AND ObjectsTable.FixedAsset.OSType = VALUE(Enum.FATypes.DepreciationComponent)
	|		AND NOT ObjectsTable.FixedAsset.ConsiderResidualLiabilityValue
	|
	|	) AS ObjectsTable
	|
	|GROUP BY
	|	ObjectsTable.AccountingObject
	|
	|HAVING 
	|	(COUNT(DISTINCT ObjectsTable.DocumentMA) > 1
	|		OR COUNT(DISTINCT ObjectsTable.DocumentACC) > 1)
	|
	|INDEX BY
	|	AccountingObject
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region TTTableOfObjects
	If TempTablesManager.Tables.Find("TTTableOfObjects") = Undefined Then
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|
		|	ObjectsTable.LineNumber AS LineNumber,
		|	ObjectsTable.FixedAsset AS AccountingObject,
		|
		|	DocumentData.CostGenerationProcedure AS CostGenerationProcedure,
		|
		|	CASE
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
		|			THEN TRUE
		|		WHEN TRUE IN (
		|				SELECT TOP 1
		|					TRUE
		|				FROM
		|					TTExpensesAreDistributedByObjects AS TTExpensesAreDistributedByObjects
		|				WHERE
		|					TTExpensesAreDistributedByObjects.AccountingObject = ObjectsTable.FixedAsset)
		|	
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ExpensesAreDistributedByObjects,
		|
		|	CASE
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
		|			THEN DocumentData.ConstructionObject
		|		ELSE ObjectsTable.FixedAsset
		|	END AS ExpensesCapitalizationDimension,
		|
		|	ObjectsTable.CostInManagementAccounting AS AmountOfUU,
		|	ObjectsTable.CostInAccounting AS AmountAccounting,
		|	ObjectsTable.CostInTaxAccounting AS AmountFA,
		|
		|	DocumentData.PartialCommissioning 
		|		OR DocumentData.AccountingProcedureMA = VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|		OR DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|		OR DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognitionByInventoryCount) AS ActualCost,
		|
		|	FALSE AS AttributingDeviationsToCost,
		|	DATETIME(1,1,1) AS SourceDocumentDate,
		|
		|	DocumentData.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
		|	ObjectsTable.AmountOfTargetFunds AS AmountOfTargetFunds,
		|
		|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
		|	DocumentData.PostInAccounting AS PostInAccounting,
		|	DocumentData.RecordInTA AS RecordInTA,
		|	DocumentData.PostInAccounting AS TakeIntoAccountPD,
		|
		|	ObjectsTable.RowID AS RowID
		|
		|INTO TTTableOfObjects
		|
		|FROM
		|	Document.FixedAssetsInitialRecognition2_4.FA AS ObjectsTable
		|
		|		INNER JOIN Document.FixedAssetsInitialRecognition2_4 AS DocumentData
		|		ON DocumentData.Ref = ObjectsTable.Ref
		|
		|WHERE
		|	ObjectsTable.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|
		|	ObjectsTable.LineNumber AS LineNumber,
		|	ObjectsTable.DepreciationComponent AS AccountingObject,
		|
		|	DocumentData.CostGenerationProcedure AS CostGenerationProcedure,
		|
		|	CASE
		|		WHEN ObjectsTable.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
		|				AND NOT ObjectsTable.DepreciationComponent.ConsiderResidualLiabilityValue
		|				AND TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						TTExpensesAreDistributedByObjects AS TTExpensesAreDistributedByObjects
		|					WHERE
		|						TTExpensesAreDistributedByObjects.AccountingObject = ObjectsTable.FixedAsset)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ExpensesAreDistributedByObjects,
		|
		|	CASE
		|		WHEN ObjectsTable.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
		|				AND NOT ObjectsTable.DepreciationComponent.ConsiderResidualLiabilityValue
		|			THEN ObjectsTable.FixedAsset
		|		ELSE ObjectsTable.DepreciationComponent
		|	END AS ExpensesCapitalizationDimension,
		|
		|	ObjectsTable.CostInManagementAccounting AS AmountOfUU,
		|	ObjectsTable.CostInAccounting AS AmountAccounting,
		|	0 AS AmountFA,
		|
		|	FALSE AS ActualCost,
		|	FALSE AS AttributingDeviationsToCost,
		|	DATETIME(1,1,1) AS SourceDocumentDate,
		|
		|	UNDEFINED AS TargetFinancingApplicationOption,
		|	0 AS AmountOfTargetFunds,
		|
		|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
		|	DocumentData.RecordInLocalAccounting AS PostInAccounting,
		|	FALSE AS RecordInTA,
		|
		|	CASE
		|		WHEN ObjectsTable.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
		|				AND NOT ObjectsTable.DepreciationComponent.ConsiderResidualLiabilityValue
		|				AND TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						TTExpensesAreDistributedByObjects AS TTExpensesAreDistributedByObjects
		|					WHERE
		|						TTExpensesAreDistributedByObjects.AccountingObject = ObjectsTable.FixedAsset)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS TakeIntoAccountPD,
		|
		|	ObjectsTable.RowID AS RowID
		|	
		|FROM
		|	Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS ObjectsTable
		|
		|		INNER JOIN Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
		|		ON DocumentData.Ref = ObjectsTable.Ref
		|
		|WHERE
		|	ObjectsTable.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|
		|	ObjectsTable.LineNumber AS LineNumber,
		|	ObjectsTable.FixedAsset AS AccountingObject,
		|
		|	DocumentData.CostGenerationProcedure AS CostGenerationProcedure,
		|
		|	CASE
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ExpensesAreDistributedByObjects,
		|
		|	CASE
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
		|			THEN DocumentData.ConstructionObject
		|		ELSE ObjectsTable.FixedAsset
		|	END AS ExpensesCapitalizationDimension,
		|
		|	ObjectsTable.CostInManagementAccounting AS AmountOfUU,
		|	ObjectsTable.CostInAccounting AS AmountAccounting,
		|	ObjectsTable.CostInTaxAccounting AS AmountFA,
		|
		|	DocumentData.FixedAssetCostAdditionsPartial AS ActualCost,
		|	FALSE AS AttributingDeviationsToCost,
		|	DATETIME(1,1,1) AS SourceDocumentDate,
		|
		|	DocumentData.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
		|	ObjectsTable.AmountOfTargetFunds AS AmountOfTargetFunds,
		|
		|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
		|	DocumentData.PostInAccounting AS PostInAccounting,
		|	DocumentData.RecordInTA AS RecordInTA,
		|	DocumentData.PostInAccounting AS TakeIntoAccountPD,
		|
		|	ObjectsTable.RowID AS RowID
		|
		|FROM
		|	Document.FixedAssetsCostAdditions2_4.FA AS ObjectsTable
		|
		|		INNER JOIN Document.FixedAssetsCostAdditions2_4 AS DocumentData
		|		ON DocumentData.Ref = ObjectsTable.Ref
		|
		|WHERE
		|	ObjectsTable.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.AllocateVariancesToFixedAssetCost) AS BusinessOperation,
		|
		|	ObjectsTable.LineNumber AS LineNumber,
		|	ObjectsTable.FixedAsset AS AccountingObject,
		|
		|	DocumentData.CostGenerationProcedure AS CostGenerationProcedure,
		|
		|	CASE
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
		|			THEN TRUE
		|
		|		WHEN ObjectsTable.FixedAsset.OSType = VALUE(Enum.FATypes.DepreciationComponent)
		|				AND NOT ObjectsTable.FixedAsset.ConsiderResidualLiabilityValue
		|				AND TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						TTExpensesAreDistributedByObjects AS TTExpensesAreDistributedByObjects
		|					WHERE
		|						TTExpensesAreDistributedByObjects.AccountingObject = ObjectsTable.FixedAsset)
		|			THEN TRUE
		|
		|		ELSE FALSE
		|	END AS ExpensesAreDistributedByObjects,
		|
		|	CASE
		|		WHEN ObjectsTable.FixedAsset.OSType = VALUE(Enum.FATypes.DepreciationComponent)
		|				AND NOT ObjectsTable.FixedAsset.ConsiderResidualLiabilityValue
		|				AND NOT Table_DepreciationComponents.FixedAsset IS NULL
		|			THEN Table_DepreciationComponents.FixedAsset
		|
		|		WHEN DocumentData.DimensionKindExpenseCapitalization = VALUE(Enum.KindsOfExpenseCapitalizationDimension.ConstructionObject)
		|			THEN DocumentData.ConstructionObject
		|
		|		ELSE ObjectsTable.FixedAsset
		|	END AS ExpensesCapitalizationDimension,
		|
		|	ObjectsTable.AmountOfUU AS AmountOfUU,
		|	ObjectsTable.AmountAccounting AS AmountAccounting,
		|	ObjectsTable.AmountFA AS AmountFA,
		|
		|	FALSE AS ActualCost,
		|	TRUE AS AttributingDeviationsToCost,
		|	ISNULL(DocumentData.SourceDocument.Date, DATETIME(1,1,1)) AS SourceDocumentDate,
		|
		|	DocumentData.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
		|	ObjectsTable.AmountOfTargetFunds AS AmountOfTargetFunds,
		|
		|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
		|	DocumentData.RecordInLocalAccounting AS PostInAccounting,
		|	DocumentData.RecordInLocalAccounting AS RecordInTA,
		|	DocumentData.RecordInLocalAccounting AS TakeIntoAccountPD,
		|
		|	ObjectsTable.RowID AS RowID
		|
		|FROM
		|	Document.AllocateVariancesToFixedAssetCost.FA AS ObjectsTable
		|
		|		INNER JOIN Document.AllocateVariancesToFixedAssetCost AS DocumentData
		|		ON DocumentData.Ref = ObjectsTable.Ref
		|
		|		LEFT JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS Table_DepreciationComponents
		|		ON Table_DepreciationComponents.Ref = DocumentData.SourceDocument
		|			AND Table_DepreciationComponents.DepreciationComponent = ObjectsTable.FixedAsset
		|
		|WHERE
		|	ObjectsTable.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
		|
		|UNION ALL
		|
		|SELECT
		|	ObjectsTable.Ref AS Ref,
		|	ObjectsTable.Date AS Date,
		|	ObjectsTable.Organization AS Organization,
		|	ObjectsTable.BusinessOperation AS BusinessOperation,
		|
		|	1 AS LineNumber,
		|	ObjectsTable.IntangibleAsset AS AccountingObject,
		|
		|	ObjectsTable.CostGenerationProcedure AS CostGenerationProcedure,
		|
		|	FALSE AS ExpensesAreDistributedByObjects,
		|	ObjectsTable.IntangibleAsset AS ExpensesCapitalizationDimension,
		|
		|	ObjectsTable.InitialCostMA AS CostInManagementAccounting,
		|	ObjectsTable.InitialCostLocalAccounting AS CostInAccounting,
		|	0 AS CostInTaxAccounting,
		|
		|	FALSE AS ActualCost,
		|	FALSE AS AttributingDeviationsToCost,
		|	DATETIME(1,1,1) AS SourceDocumentDate,
		|
		|	ObjectsTable.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
		|	ObjectsTable.AmountOfTargetFunds AS AmountOfTargetFunds,
		|
		|	ObjectsTable.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	ObjectsTable.RecordInManAccounting AS RecordInManAccounting,
		|	ObjectsTable.PostInAccounting AS PostInAccounting,
		|	ObjectsTable.RecordInTA AS RecordInTA,
		|	ObjectsTable.PostInAccounting AS TakeIntoAccountPD,
		|
		|	ObjectsTable.DocumentID AS RowID
		|
		|FROM
		|	Document.IntangibleAssetsInitialRecognition2_4 AS ObjectsTable
		|
		|WHERE
		|	ObjectsTable.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|
		|	ObjectsTable.LineNumber AS LineNumber,
		|	ObjectsTable.IntangibleAsset AS AccountingObject,
		|
		|	DocumentData.CostGenerationProcedure AS CostGenerationProcedure,
		|
		|	FALSE AS ExpensesAreDistributedByObjects,
		|	ObjectsTable.IntangibleAsset AS ExpensesCapitalizationDimension,
		|
		|	ObjectsTable.CostInManagementAccounting AS CostInManagementAccounting,
		|	ObjectsTable.CostInAccounting AS CostInAccounting,
		|	0 AS CostInTaxAccounting,
		|
		|	FALSE AS ActualCost,
		|	FALSE AS AttributingDeviationsToCost,
		|	DATETIME(1,1,1) AS SourceDocumentDate,
		|
		|	UNDEFINED AS TargetFinancingApplicationOption,
		|	0 AS AmountOfTargetFunds,
		|
		|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
		|	DocumentData.PostInAccounting AS PostInAccounting,
		|	DocumentData.RecordInTA AS RecordInTA,
		|	DocumentData.PostInAccounting AS TakeIntoAccountPD,
		|
		|	ObjectsTable.RowID AS RowID
		|
		|FROM
		|	Document.IntangibleAssetImprovement.IA AS ObjectsTable
		|
		|		INNER JOIN Document.IntangibleAssetImprovement AS DocumentData
		|		ON DocumentData.Ref = ObjectsTable.Ref
		|
		|WHERE
		|	ObjectsTable.Ref IN (SELECT TTDataToBeCalculated.Ref FROM TTDataToBeCalculated AS TTDataToBeCalculated)
		|
		|INDEX BY
		|	ExpensesCapitalizationDimension
		|";	
		ListOfRequests.Add(QueryText);
	EndIf;
	#EndRegion
		
	#Region VNAArticles
	QueryText =
	"SELECT
	|	ExpenseItems.Ref
	|INTO VNAArticles
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OtherExpensesBalance
	QueryText =
	"SELECT
	|	OtherExpensesBalance.Organization AS Organization,
	|	OtherExpensesBalance.Department AS Department,
	|	OtherExpensesBalance.LineOfBusiness AS LineOfBusiness,
	|	OtherExpensesBalance.ExpenseItem AS ExpenseItem,
	|	OtherExpensesBalance.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN OtherExpensesBalance.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpensesBalance.SumBalance
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE
	|		WHEN OtherExpensesBalance.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpensesBalance.SumManBalance
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN OtherExpensesBalance.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpensesBalance.AmountExcludingVATBalance
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE
	|		WHEN OtherExpensesBalance.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpensesBalance.SumComplBalance
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	CASE
	|		WHEN OtherExpensesBalance.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpensesBalance.SumComplBalance - OtherExpensesBalance.PermanentDifferenceBalance - OtherExpensesBalance.CostTDBalance
	|		ELSE 0
	|	END AS AmountFA,
	|
	|	OtherExpensesBalance.PermanentDifferenceBalance AS PermanentDifference,
	|	OtherExpensesBalance.AITAmountBalance AS AITAmount
	|
	|INTO OtherExpensesBalance
	|
	|FROM
	|	AccumulationRegister.OtherExpenses.Balance(
	|			&BegOfMonth,
	|			ExpenseItem IN
	|				(SELECT
	|					VNAArticles.Ref
	|				FROM
	|					VNAArticles)
	|			AND (Organization, DimensionOfExpenses) IN
	|				(SELECT
	|					TTTableOfObjects.Organization,
	|					TTTableOfObjects.ExpensesCapitalizationDimension
	|				FROM
	|					TTTableOfObjects)) AS OtherExpensesBalance
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OtherTrafficExpenses
	QueryText =
	"SELECT
	|	CASE
	|		WHEN VALUETYPE(OtherExpenses.Recorder) IN (&TypesOfDocumentsToMoveToBeginningOfMonth)
	|			THEN BEGINOFPERIOD(OtherExpenses.Period, MONTH)
	|		ELSE BEGINOFPERIOD(OtherExpenses.Period, DAY)
	|	END AS DayPeriod,
	|
	|	OtherExpenses.Period AS Period,
	|	OtherExpenses.Recorder AS Recorder,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.VariancePeriod AS VariancePeriod,
	|	OtherExpenses.RecordType AS RecordType,
	|
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpenses.Sum
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpenses.SumMan
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpenses.AmountExcludingVAT
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpenses.SumCompl
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpenses.SumCompl - OtherExpenses.PermanentDifference - OtherExpenses.CostTD
	|		ELSE 0
	|	END AS AmountFA,
	|
	|	CASE
	|		WHEN OtherExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN OtherExpenses.PermanentDifference
	|		ELSE 0
	|	END AS PermanentDifference,
	|
	|	OtherExpenses.AITAmount AS AITAmount
	|
	|INTO OtherTrafficExpenses
	|
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|
	|WHERE
	|	OtherExpenses.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND OtherExpenses.Active
	|
	|	AND OtherExpenses.ExpenseItem IN
	|			(SELECT
	|				VNAArticles.Ref
	|			FROM
	|				VNAArticles)
	|
	|	AND (OtherExpenses.Organization, OtherExpenses.DimensionOfExpenses) IN
	|			(SELECT
	|				TTTableOfObjects.Organization,
	|				TTTableOfObjects.ExpensesCapitalizationDimension
	|			FROM
	|				TTTableOfObjects)
	|
	|	AND NOT OtherExpenses.Recorder IN 
	|			(SELECT
	|				TTDataToBeCalculated.Ref
	|			FROM
	|				TTDataToBeCalculated)
	|
	|INDEX BY
	|	Organization,
	|	DimensionOfExpenses
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region ExpensesTable
	QueryText =
	"SELECT
	|	TTTableOfObjects.ExpensesCapitalizationDimension AS ExpensesCapitalizationDimension,
	|	MAX(TTTableOfObjects.Ref) AS Ref,
	|	MAX(TTTableOfObjects.Date) AS Date,
	|	MAX(BEGINOFPERIOD(TTTableOfObjects.Date, DAY)) AS DateDay,
	|	MAX(TTTableOfObjects.CostGenerationProcedure) AS CostGenerationProcedure,
	|	MAX(TTTableOfObjects.AttributingDeviationsToCost) AS AttributingDeviationsToCost,
	|	MAX(TTTableOfObjects.SourceDocumentDate) AS SourceDocumentDate
	|
	|INTO TTAnalyticsOfCostCapitalization
	| 
	|FROM
	|	TTTableOfObjects AS TTTableOfObjects
	|
	|GROUP BY
	|	TTTableOfObjects.ExpensesCapitalizationDimension
	|
	|INDEX BY
	|	ExpensesCapitalizationDimension,
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BegOfMonth AS Period,
	|	&BegOfMonth AS DayPeriod,
	|	UNDEFINED AS Recorder,
	|	OtherExpensesBalance.Organization AS Organization,
	|	OtherExpensesBalance.LineOfBusiness AS LineOfBusiness,
	|	OtherExpensesBalance.Department AS Department,
	|	OtherExpensesBalance.ExpenseItem AS ExpenseItem,
	|	OtherExpensesBalance.DimensionOfExpenses AS DimensionOfExpenses,
	|	DATETIME(1,1,1) AS VariancePeriod,
	|
	|	OtherExpensesBalance.Sum AS Sum,
	|	OtherExpensesBalance.SumMan AS SumMan,
	|	OtherExpensesBalance.AmountExcludingVAT AS AmountExcludingVAT,
	|	OtherExpensesBalance.SumCompl AS SumCompl,
	|	OtherExpensesBalance.AmountFA AS AmountFA,
	|	OtherExpensesBalance.PermanentDifference AS PermanentDifference,
	|	OtherExpensesBalance.AITAmount AS AITAmount
	|
	|INTO TTExpenses
	|
	|FROM
	|	OtherExpensesBalance AS OtherExpensesBalance
	|
	|UNION ALL
	|	
	|SELECT
	|	OtherTrafficExpenses.Period AS Period,
	|	OtherTrafficExpenses.DayPeriod AS DayPeriod,
	|	OtherTrafficExpenses.Recorder AS Recorder,
	|	OtherTrafficExpenses.Organization AS Organization,
	|	OtherTrafficExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherTrafficExpenses.Department AS Department,
	|	OtherTrafficExpenses.ExpenseItem AS ExpenseItem,
	|	OtherTrafficExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherTrafficExpenses.VariancePeriod AS VariancePeriod,
	|
	|	CASE WHEN OtherTrafficExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN OtherTrafficExpenses.Sum
	|		ELSE -OtherTrafficExpenses.Sum
	|	END AS Sum,
	|
	|	CASE WHEN OtherTrafficExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN OtherTrafficExpenses.SumMan
	|		ELSE -OtherTrafficExpenses.SumMan
	|	END AS SumMan,
	|
	|	CASE WHEN OtherTrafficExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN OtherTrafficExpenses.AmountExcludingVAT
	|		ELSE -OtherTrafficExpenses.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|
	|	CASE WHEN OtherTrafficExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN OtherTrafficExpenses.SumCompl
	|		ELSE -OtherTrafficExpenses.SumCompl
	|	END AS SumCompl,
	|
	|	CASE WHEN OtherTrafficExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN OtherTrafficExpenses.AmountFA
	|		ELSE -OtherTrafficExpenses.AmountFA
	|	END AS AmountFA,
	|
	|	CASE WHEN OtherTrafficExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN OtherTrafficExpenses.PermanentDifference
	|		ELSE -OtherTrafficExpenses.PermanentDifference
	|	END AS PermanentDifference,
	|
	|	CASE WHEN OtherTrafficExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN OtherTrafficExpenses.AITAmount
	|		ELSE -OtherTrafficExpenses.AITAmount
	|	END AS AITAmount
	|
	|FROM
	|	OtherTrafficExpenses AS OtherTrafficExpenses
	|
	|INDEX BY
	|	DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTExpenses.Organization                AS Organization,
	|	TTExpenses.LineOfBusiness    AS LineOfBusiness,
	|	TTExpenses.Department              AS Department,
	|	TTExpenses.ExpenseItem             AS ExpenseItem,
	|	TTExpenses.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TTExpenses.VariancePeriod           AS VariancePeriod,
	|	
	|	SUM(TTExpenses.Sum)               AS Sum,
	|	SUM(TTExpenses.SumMan)            AS SumMan,
	|	SUM(TTExpenses.AmountExcludingVAT)         AS AmountExcludingVAT,
	|	SUM(TTExpenses.SumCompl)           AS SumCompl,
	|	SUM(TTExpenses.AmountFA)             AS AmountFA,
	|
	|	CASE
	|		WHEN SUM(TTExpenses.PermanentDifference) > 0
	|					AND ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR SUM(TTExpenses.PermanentDifference) < 0
	|					AND ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN SUM(TTExpenses.PermanentDifference)
	|		ELSE 0
	|	END AS PermanentDifference,
	|
	|	SUM(TTExpenses.SumCompl) 
	|		- SUM(TTExpenses.AmountFA) 
	|		- CASE
	|			WHEN SUM(TTExpenses.PermanentDifference) > 0
	|					AND ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR SUM(TTExpenses.PermanentDifference) < 0
	|					AND ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				THEN SUM(TTExpenses.PermanentDifference)
	|			ELSE 0
	|		END AS CostTD,
	|
	|	SUM(TTExpenses.AITAmount) AS AITAmount
	|
	|FROM
	|	TTAnalyticsOfCostCapitalization AS TTAnalyticsOfCostCapitalization
	|
	|		INNER JOIN TTExpenses AS TTExpenses
	|		ON TTExpenses.DimensionOfExpenses = TTAnalyticsOfCostCapitalization.ExpensesCapitalizationDimension
	|			AND (TTExpenses.DayPeriod < TTAnalyticsOfCostCapitalization.DateDay
	|				OR TTExpenses.DayPeriod = TTAnalyticsOfCostCapitalization.DateDay
	|						AND (TTExpenses.Recorder = UNDEFINED
	|							OR NOT VALUETYPE(TTExpenses.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|							OR TTExpenses.Recorder < TTAnalyticsOfCostCapitalization.Ref)
	|				OR TTAnalyticsOfCostCapitalization.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost))
	|			AND (NOT TTAnalyticsOfCostCapitalization.AttributingDeviationsToCost
	|				OR TTExpenses.VariancePeriod = DATETIME(1,1,1)
	|				OR TTExpenses.VariancePeriod <= TTAnalyticsOfCostCapitalization.SourceDocumentDate)
	|
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = TTExpenses.ExpenseItem
	|
	|GROUP BY
	|	TTExpenses.Organization,
	|	TTExpenses.LineOfBusiness,
	|	TTExpenses.Department,
	|	TTExpenses.ExpenseItem,
	|	TTExpenses.DimensionOfExpenses,
	|	TTExpenses.VariancePeriod,
	|	ExpenseItems.CostAllocationOptionLocal,
	|	ExpenseItems.CostAllocationOptionTax
	|
	|HAVING
	|	SUM(TTExpenses.Sum) <> 0
	|		OR SUM(TTExpenses.SumMan) <> 0
	|		OR SUM(TTExpenses.AmountExcludingVAT) <> 0
	|		OR SUM(TTExpenses.SumCompl) <> 0
	|		OR SUM(TTExpenses.AmountFA) <> 0
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region TableOfCostCapitalizationAnalysts
	QueryText =
	"SELECT
	|	TTTableOfObjects.ExpensesCapitalizationDimension AS ExpensesCapitalizationDimension,
	|	MAX(TTTableOfObjects.Date) AS Date,
	|	MAX(TTTableOfObjects.ExpensesAreDistributedByObjects) AS ExpensesAreDistributedByObjects,
	|	MAX(TTTableOfObjects.CostGenerationProcedure) AS CostGenerationProcedure,
	|	MAX(TTTableOfObjects.ActualCost) AS ActualCost
	|
	|FROM
	|	TTTableOfObjects AS TTTableOfObjects
	|
	|GROUP BY
	|	TTTableOfObjects.ExpensesCapitalizationDimension
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region ObjectsTable
	QueryText =
	"SELECT
	|	TTTableOfObjects.Ref AS Ref,
	|	TTTableOfObjects.AccountingObject AS AccountingObject,
	|	TTTableOfObjects.ExpensesCapitalizationDimension AS ExpensesCapitalizationDimension,
	|
	|	TTTableOfObjects.AmountOfUU AS AmountOfUU,
	|	TTTableOfObjects.AmountAccounting AS AmountAccounting,
	|	TTTableOfObjects.AmountFA AS AmountFA,
	|
	|	TTTableOfObjects.TargetFinancingApplicationOption AS TargetFinancingApplicationOption,
	|	TTTableOfObjects.AmountOfTargetFunds AS AmountOfTargetFunds,
	|
	|	TTTableOfObjects.BusinessOperation AS BusinessOperation,
	|	TTTableOfObjects.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TTTableOfObjects.RecordInManAccounting AS RecordInManAccounting,
	|	TTTableOfObjects.PostInAccounting AS PostInAccounting,
	|	TTTableOfObjects.RecordInTA AS RecordInTA,
	|	TTTableOfObjects.TakeIntoAccountPD AS TakeIntoAccountPD,
	|	TTTableOfObjects.AttributingDeviationsToCost AS AttributingDeviationsToCost,
	|
	|	TTTableOfObjects.RowID AS RowID,
	|
	|	ISNULL(TTAccountingPolicy.IncludeRentalPaymentsAsPartOfTaxExpenses , FALSE) AS IncludeRentalPaymentsAsPartOfTaxExpenses
	|	
	|FROM
	|	TTTableOfObjects AS TTTableOfObjects
	|
	|		LEFT JOIN TTAccountingPolicy AS TTAccountingPolicy
	|		ON TTAccountingPolicy.Organization = TTTableOfObjects.Organization
	|";	
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BegOfMonth", BegOfMonth(Period));
	Query.SetParameter("EndOfMonth", EndOfMonth(Period));
	
	Query.SetParameter(
		"TypesOfDocumentsToMoveToBeginningOfMonth", 
		TypesOfDocumentsToMoveToBeginningOfMonth());
	
	Query.SetParameter(
		"TypesOfDocumentsForWhichCostIsCalculated", 
		TypesOfDocumentsForWhichCostIsCalculated());
	
	Result = Query.ExecuteBatch();
	
	ExpensesTable = Result[Result.UBound()-2].Unload();
	TableOfCostCapitalizationAnalysts = Result[Result.UBound()-1].Unload();
	ObjectsTable = Result[Result.UBound()].Unload();
	
	ExpensesTable.Indexes.Add("DimensionOfExpenses");
	ObjectsTable.Indexes.Add("ExpensesCapitalizationDimension");
	
	CurExpenses = CalculateExpenses(TableOfCostCapitalizationAnalysts, ObjectsTable, ExpensesTable);
	
	QueryText =
	"SELECT
	|	CurExpenses.Ref                      AS Ref,
	|	CurExpenses.Organization                 AS Organization,
	|	CurExpenses.AccountingObject                 AS AccountingObject,
	|	CurExpenses.ExpenseItem              AS ExpenseItem,
	|	CurExpenses.DimensionOfExpenses           AS DimensionOfExpenses,
	|	CurExpenses.Department               AS Department,
	|	CurExpenses.LineOfBusiness     AS LineOfBusiness,
	|	CurExpenses.VariancePeriod            AS VariancePeriod,
	|
	|	CurExpenses.Sum                       AS Sum,
	|	CurExpenses.AmountExcludingVAT                 AS AmountExcludingVAT,
	|	CurExpenses.SumMan                    AS SumMan,
	|
	|	CurExpenses.SumCompl                   AS SumCompl,
	|	CurExpenses.PermanentDifference           AS PermanentDifference,
	|	CurExpenses.CostTD            AS CostTD,
	|
	|	CurExpenses.SumCompl
	|	 - CurExpenses.PermanentDifference
	|	 - CurExpenses.CostTD         AS AmountFA,
	|
	|	CurExpenses.DisregardedCostTA    AS DisregardedCostTA,
	|	CurExpenses.CFAmount                     AS CFAmount,
	|	CurExpenses.PRCFAmount                   AS PRCFAmount,
	|	CurExpenses.SumOfNUCF                   AS SumOfNUCF,
	|	CurExpenses.AITAmount                    AS AITAmount,
	|
	|	CurExpenses.RowID         AS RowID,
	|	CurExpenses.IdOfACLine       AS IdOfACLine,
	|	CurExpenses.RowIDTA       AS RowIDTA,
	|	CurExpenses.IdOfTFLine       AS IdOfTFLine
	|
	|INTO TTCurExpenses
	|
	|FROM
	|	&CurExpenses AS CurExpenses
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurExpenses", CurExpenses);
	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
EndProcedure

// Determines whether the calculation of the value of non-current assets has been completed as of the specified date.
// 
// Parameters:
//  Period - Date - Period
//  CompaniesList - CatalogRef.Companies, Array of CatalogRef.Companies - List of organizations
// 
// Returns:
//  Boolean - True if the calculation of the value of non-current assets is performed.
Function CalculationOfValueOfNonCurrentAssets(Period, CompaniesList) Export
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.JobsForCalculatingNonCurrentAssetCost AS Jobs
	|
	|WHERE
	|	Jobs.Month <= &Period
	|	AND Jobs.Organization IN (&CompaniesList)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", ?(Period <> '000101010000', Period, CurrentSessionDate()));
	Query.SetParameter(
		"CompaniesList", 
		?(TypeOf(CompaniesList) = Type("Array"), CompaniesList, CommonClientServer.ValueInArray(CompaniesList)));
	
	Result = Query.Execute();
	
	Return Result.IsEmpty();
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region PerformingTransaction

Function CreateTaskQueue(BeginOfPeriod, EndOfPeriod, CompaniesList, NumberBeforeSettlement, TempTablesManager)

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.CreateTaskQueue");

	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);

	MaximumNumberOfTasks = MaximumNumberOfTasks();

	TaskQueue = NonCurrentAssets.InitiateTaskQueue();

	CreateTTTableWithListOfDocuments(BeginOfPeriod, EndOfPeriod, CompaniesList, TempTablesManager);
	
	ObjectQueue = NonCurrentAssets.QueueOfSLEObjects(TempTablesManager, MaximumNumberOfTasks);
	
	MaximumQueueNumber = 1;
	For Each Selection In ObjectQueue Do
		MaximumQueueNumber = Max(Selection.QueueNumber, MaximumQueueNumber);
	EndDo;
	
	DataVolume = 0;
	
	For Each Selection In ObjectQueue Do
		
		If TaskQueue.Count() < Selection.QueueNumber Then
			
			TaskData_ = TaskQueue.Add();
			TaskData_.CalculationProcedure_ = "FACostCalculation.PerformOfOperationOnObjects";
			
			If MaximumNumberOfTasks > 1 Then
				TaskData_.BackgroundJobDescription = 
					StrTemplate(
					NStr("vi = 'Tính giá trị TSCĐ hữu hình và TSCĐ vô hình (nhiệm vụ %1 trong số %2)';
						|ru = 'Расчет стоимости ОС и НМА (задание %1 из %2)';
						|en = 'Calculation of fixed asset and intangible asset value (job %1 out of %2)'; fa = 'Calculation of fixed asset and intangible asset value (job %1 out of %2)';
						|it = 'Расчет стоимости ОС и НМА (задание %1 из %2)';
						|pl = 'Calculation of fixed asset and intangible asset value (job %1 out of %2)';
						|tr = 'SV ve MOV maliyetinin hesaplanması (%2 üzerindeki %1 görevi)'"), 
					Format(Selection.QueueNumber, "ND=2; NLZ=; NG=;"), 
					MaximumQueueNumber); 
			Else
				TaskData_.BackgroundJobDescription = NStr("vi = 'Tính toán giá trị tài sản cố định và tài sản cố định vô hình';
															|ru = 'Расчет стоимости ОС и НМА';
															|en = 'Calculation of fixed asset and intangible asset value'; fa = 'محاسبه ارزش دارایی ثابت و دارایی نامشهود';
															|it = 'Calcolo del costo capitale fisso e attività immateriali';
															|pl = 'Obliczenie kosztów ŚT oraz WNM';
															|tr = 'SV ve GMA maliyetinin hesaplanması'"); 
			EndIf;

			ExecutionParameters = ExecutionParameters();
			ExecutionParameters.BeginOfPeriod = BegOfMonth(BeginOfPeriod);
			ExecutionParameters.EndOfPeriod = EndOfMonth(EndOfPeriod);
			ExecutionParameters.CompaniesList = CompaniesList;
			ExecutionParameters.ExecuteCheck = True;
			ExecutionParameters.NumberBeforeSettlement = NumberBeforeSettlement;
			
			TaskData_.JobParameters = ExecutionParameters;
			
		Else
			TaskData_ = TaskQueue[Selection.QueueNumber - 1];
		EndIf;
		
		ObjectParameters = TaskData_.JobParameters.ListOfObjects.Add();
		ObjectParameters.AccountingObject = Selection.AccountingObject;
		
		DataVolume = DataVolume + 1;
		
	EndDo;

	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	Return TaskQueue;
	
EndFunction

Function GetPortionOfDataToBeCalculated(BeginOfPeriod, ExecutionParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.GetPortionOfDataToBeCalculated");

	DataVolume = NonCurrentAssets.CreateTTTablePortionOfDataToBeCalculated(
		BeginOfPeriod, 
		ExecutionParameters.TempTablesManager,
		DataChunkSize(),
		BusinessOperationsForWhichCostIsCalculated());
	
	ExecutionParameters.DataVolume = ExecutionParameters.DataVolume + DataVolume;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	Return (DataVolume <> 0);
	
EndFunction

Procedure GenerateRegisteredRecordsBasedOnDocuments(Period, ExecutionParameters)
	
	TempTablesManager = ExecutionParameters.TempTablesManager;
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TTTableOfObjects");
	TTUsed.Add("TTCostCalculation");
	TTUsed.Add("TTCostCalculationGrouped");
	TTUsed.Add("TTAccountingPolicy");
	
	PrepareParameters(Period, TempTablesManager);
	MovementTables = PrepareTablesOfRegisteredRecords(TempTablesManager);
	WriteMotionTables(MovementTables, ExecutionParameters);
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
EndProcedure

Procedure PrepareParameters(Period, TempTablesManager)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.PrepareParameters");

	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TTAccountingPolicy");
	TTUsed.Add("TTTableOfObjects");
	TTUsed.Add("TTCostCalculation");
	TTUsed.Add("TTCostCalculationGrouped");
	
	CreateTTAccountingPolicy(Period, TempTablesManager);
	GenerateTTCurrentExpenses(Period, TempTablesManager);
	GenerateCostTTCalculation(TempTablesManager);
	
	DataVolume = NonCurrentAssets.NumberOfDataToBeCalculated(TempTablesManager, "TTTableOfObjects");

	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

Function PrepareTablesOfRegisteredRecords(TempTablesManager)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.PrepareTablesOfRegisteredRecords");

	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TTListOfDocuments");
	
	QueryText = 
	"SELECT DISTINCT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref,
	|	TTPortionOfDataToBeCalculated.Organization AS Organization,
	|	TTPortionOfDataToBeCalculated.Date AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
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
	|	VALUETYPE(TTListOfDocuments.Ref) AS DocumentType
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

		ManagerOfDocument = Documents[Metadata.FindByType(Selection.DocumentType).Name];
		
		TablesOfRegisteredRecordsOfDocuments = ManagerOfDocument.TablesForCalculatingCost(TempTablesManager); // Structure
		
		For Each KeyAndValue In TablesOfRegisteredRecordsOfDocuments Do

			RegisterName = NonCurrentAssetsInternal.NameOfRegisterByNameOfRegisteredRecordsTable(KeyAndValue.Key);
			
			If Metadata.InformationRegisters.Find(RegisterName) <> Undefined 
				Or Metadata.AccumulationRegisters.Find(RegisterName) <> Undefined Then
			
				Table = KeyAndValue.Value; // ValueTable
				Table.Indexes.Add("Recorder");
				
			EndIf;
			
		EndDo;
		
		MovementTables.Insert(Selection.DocumentType, TablesOfRegisteredRecordsOfDocuments);
		
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	EndDo;
	
	TTUsed.Delete(TTUsed.Find("TTListOfDocuments"));
	
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

	Return MovementTables;
	
EndFunction

Procedure WriteMotionTables(MovementTables, ExecutionParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.WriteMotionTables");

	TTUsed = TMCommonUse.ListOfTemporaryTables(ExecutionParameters.TempTablesManager);
	
	QueryText = 
	"SELECT DISTINCT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref,
	|	TTPortionOfDataToBeCalculated.Date AS Date
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Result = Query.Execute();
	Selection = Result.Select();
	
	DataVolume = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			DocumentObject = DocumentsPosting.DocumentEmulation(Selection.Ref, Selection.Date);
			SetFlagForOperation(DocumentObject);
			
			TablesOfRegisteredRecordsOfDocuments = MovementTables.Get(TypeOf(Selection.Ref));
			
			NonCurrentAssetsInternal.WriteMotionTables(
				TablesOfRegisteredRecordsOfDocuments, 
				DocumentObject, 
				ExecutionParameters.TempTablesManager,
				ExecutionParameters.ReturnDocumentsToReflection, 
				NameOfFlagOfOperation());
				
			DataVolume = DataVolume + 1;
			
			If ExecutionParameters.GenerateJobs Then
				DocumentsPosting.CreateTasksForDeferredRegisteredRecords(DocumentObject, ExecutionParameters.TempTablesManager);
			EndIf;
		
			TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			Raise ErrorText;
			
		EndTry;
		
	EndDo;
	
	If ExecutionParameters.GenerateJobs Then
		CreateTasksToUpdateRegisterRecords(ExecutionParameters.TempTablesManager);
	EndIf;
	
	NonCurrentAssetsInternal.ReflectInManagementBalanceSheet(MovementTables, ExecutionParameters.TempTablesManager);
	
	FACostCalculationLocalization.WriteMotionTables(MovementTables, ExecutionParameters);
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

Procedure RegisterErrors(Period, ExecutionParameters)

	If Not ExecutionParameters.ExecuteCheck Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.RegisterErrors");

	TTUsed = TMCommonUse.ListOfTemporaryTables(ExecutionParameters.TempTablesManager);
	TTUsed.Add("TTErrors");
	
	#Region CostVerification
	
	QueryText = 
	"SELECT
	|	ErrorList.Ref AS Ref,
	|	ErrorList.AccountingObject AS AccountingObject,
	|	ErrorList.Organization AS Organization,
	|	ErrorList.PostInAccounting AS PostInAccounting,
	|	ErrorList.RecordInTA AS RecordInTA,
	|	ErrorList.RecordInManAccounting AS RecordInManAccounting,
	|	ErrorList.CostGenerationProcedure AS CostGenerationProcedure,
	|
	|	ErrorList.PreliminaryCostOfAC AS PreliminaryCostOfAC,
	|	ErrorList.PreliminaryCostOfMa AS PreliminaryCostOfMa,
	|	ErrorList.ActualCostOfAC AS ActualCostOfAC,
	|	ErrorList.ActualCostTa AS ActualCostTa,
	|	ErrorList.ActualCostOfMa AS ActualCostOfMa
	|
	|INTO ErrorList
	|
	|FROM
	|	(SELECT
	|		TTTableOfObjects.Ref AS Ref,
	|		TTTableOfObjects.AccountingObject AS AccountingObject,
	|		TTTableOfObjects.Organization AS Organization,
	|		MAX(TTTableOfObjects.CostGenerationProcedure) AS CostGenerationProcedure,
	|
	|		MAX(CASE
	|			WHEN VALUETYPE(TTTableOfObjects.Ref) IN (
	|						TYPE(Document.FixedAssetsCostAdditions2_4),
	|						TYPE(Document.AllocateVariancesToFixedAssetCost))
	|					AND TTTableOfObjects.PostInAccounting
	|					AND TTTableOfObjects.RecordInTA
	|					AND ISNULL(CostCalculation.AmountAccounting + CostCalculation.CFAmount, 0) = 0
	|					AND ISNULL(CostCalculation.AmountFA, 0) <> 0
	|			
	|				THEN FALSE
	|			ELSE TTTableOfObjects.PostInAccounting 
	|		END) AS PostInAccounting,
	|
	|		MAX(CASE
	|			WHEN NOT ISNULL(TTAccountingPolicy.IncomeTaxPayer, FALSE)
	|					OR TTTableOfObjects.TargetFinancingApplicationOption = &FullTF
	|				THEN FALSE
	|			ELSE TTTableOfObjects.RecordInTA 
	|		END) AS RecordInTA,
	|
	|		MAX(TTTableOfObjects.RecordInManAccounting) AS RecordInManAccounting,
	|
	|		SUM(TTTableOfObjects.AmountAccounting) AS PreliminaryCostOfAC,
	|		SUM(TTTableOfObjects.AmountOfUU) AS PreliminaryCostOfMa,
	|		SUM(ISNULL(CostCalculation.AmountAccounting + CostCalculation.CFAmount, 0)) AS ActualCostOfAC,
	|		SUM(ISNULL(CostCalculation.AmountFA, 0)) AS ActualCostTa,
	|		SUM(ISNULL(CostCalculation.AmountOfUU, 0)) AS ActualCostOfMa
	|
	|	FROM
	|		TTTableOfObjects AS TTTableOfObjects
	|
	|			LEFT JOIN TTCostCalculationGrouped AS CostCalculation
	|			ON CostCalculation.Ref = TTTableOfObjects.Ref
	|				AND CostCalculation.AccountingObject = TTTableOfObjects.AccountingObject
	|
	|			LEFT JOIN TTAccountingPolicy AS TTAccountingPolicy
	|			ON TTAccountingPolicy.Organization = TTTableOfObjects.Organization
	|
	|	GROUP BY
	|		TTTableOfObjects.Ref,
	|		TTTableOfObjects.AccountingObject,
	|		TTTableOfObjects.Organization
	|
	|	) AS ErrorList
	|
	|WHERE
	|	(ErrorList.ActualCostOfMa = 0
	|			AND ErrorList.RecordInManAccounting
	|		OR ErrorList.ActualCostOfAC = 0
	|			AND ErrorList.PostInAccounting
	|		OR ErrorList.ActualCostTa = 0
	|			AND ErrorList.RecordInTA)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ErrorList.Ref AS Ref,
	|	ErrorList.AccountingObject AS AccountingObject,
	|	Assets.OSType AS OSType,
	|	IntangibleAssets.KindOfAccountingObject AS KindOfAccountingObject,
	|	ErrorList.Organization AS Organization,
	|	ErrorList.CostGenerationProcedure AS CostGenerationProcedure,
	|	CAST(ErrorList.Organization AS Catalog.Companies).LocalAccountingCurrency AS LocalAccountingCurrency,
	|	ErrorList.PostInAccounting AS PostInAccounting,
	|	ErrorList.RecordInTA AS RecordInTA,
	|	ErrorList.RecordInManAccounting AS RecordInManAccounting,
	|
	|	ErrorList.PreliminaryCostOfAC AS PreliminaryCostOfAC,
	|	ErrorList.PreliminaryCostOfMa AS PreliminaryCostOfMa,
	|	ErrorList.ActualCostOfAC AS ActualCostOfAC,
	|	ErrorList.ActualCostTa AS ActualCostTa,
	|	ErrorList.ActualCostOfMa AS ActualCostOfMa
	|
	|FROM
	|	ErrorList AS ErrorList
	|
	|		LEFT JOIN Catalog.Assets AS Assets
	|		ON Assets.Ref = ErrorList.AccountingObject
	|
	|		LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|		ON IntangibleAssets.Ref = ErrorList.AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.SetParameter("FullTF", Undefined);

	
	Result = Query.Execute();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		If Selection.CostGenerationProcedure = Enums.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost Then
			
			If Selection.OSType = Enums.FATypes.DepreciationComponent Then
				
				MessageTemplateOS_BU_Null = NStr("vi = 'Theo thành phần tài sản cố định ""%1"" không có chi phí thực tế (kế toán doanh nghiệp) liên quan đến việc mua sắm và đã được hình thành trước cuối tháng.
			                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
			                              |ru = 'По компоненту основного средства ""%1"" отсутствуют фактические затраты (бух. учет), связанные с его приобретением и сформированные до конца месяца.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymet amortisman bileşeni için, satın alımıyla ilişkili olan ve ay sonuna kadar oluşan fiili giderler (genel muhasebe) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				OS_N_ZeroMessageTemplate = NStr("vi = 'Theo thành phần tài sản cố định ""%1"" không có chi phí thực tế (kế toán thuế) liên quan đến việc mua sắm và đã được hình thành trước cuối tháng.
			                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
			                              |ru = 'По компоненту основного средства ""%1"" отсутствуют фактические затраты (нал. учет), связанные с его приобретением и сформированные до конца месяца.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymet amortisman bileşeni için, satın alımıyla ilişkili olan ve ay sonuna kadar oluşan fiili giderler (vergi muhasebesi) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				MessageTemplateOS_U_Null = NStr("vi = 'Theo thành phần tài sản cố định ""%1"" không có chi phí thực tế (kế toán quản trị) liên quan đến việc mua sắm và đã được hình thành trước cuối tháng.
			                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
			                              |ru = 'По компоненту основного средства ""%1"" отсутствуют фактические затраты (упр. учет), связанные с его приобретением и сформированные до конца месяца.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymet amortisman bileşeni için, satın alımıyla ilişkili olan ve ay sonuna kadar oluşan fiili giderler (yönetim muhasebesi) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
			Else
				
				MessageTemplateOS_BU_Null = NStr("vi = 'Tài sản cố định ""%1"" không có chi phí thực tế (kế toán doanh nghiệp) đã được hình thành trước cuối tháng.
			                              |Cần kiểm tra các chứng từ đã phản ánh các chi phí này.';
			                              |ru = 'У основного средства ""%1"" отсутствуют фактические затраты (бух. учет), сформированные до конца месяца.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymeti için, ay sonuna kadar oluşan gerçek giderler (genel muhasebe) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				OS_N_ZeroMessageTemplate = NStr("vi = 'Tài sản cố định ""%1"" không có chi phí thực tế (kế toán thuế) đã được hình thành trước cuối tháng.
			                              |Cần kiểm tra các chứng từ đã phản ánh các chi phí này.';
			                              |ru = 'У основного средства ""%1"" отсутствуют фактические затраты (нал. учет), сформированные до конца месяца.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the end of the month.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymeti için, ay sonuna kadar oluşan fiili giderler (vergi muhasebesi) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				MessageTemplateOS_U_Null = NStr("vi = 'Đối với tài sản cố định ""%1"", không có chi phí thực tế (kế toán quản trị) đã được hình thành trước cuối tháng.
			                              |Cần kiểm tra việc điền thông tin trong các chứng từ đã phản ánh các chi phí này.';
			                              |ru = 'У основного средства ""%1"" отсутствуют фактические затраты (упр. учет), сформированные до конца месяца.
			                              |Необходимо проверить заполнение в документах, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the end of the month.
			                              |Check the documents in which the costs were recorded.'; fa = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the end of the month.
			                              |Check the documents in which the costs were recorded.';
			                              |it = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the end of the month.
			                              |Check the documents in which the costs were recorded.';
			                              |pl = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the end of the month.
			                              |Check the documents in which the costs were recorded.';
			                              |tr = '""%1"" sabit kıymeti için, ay sonuna kadar oluşan fiili giderler (yönetim muhasebesi) bulunmuyor.
			                              |Giderlerin yansıtıldığı belgelerin doldurulma durumunun kontrol edilmesi gerekir.'");
		                              
			EndIf;
			
			MessageTemplateNMA_BU_Null = NStr("vi = 'Đối với tài sản cố định vô hình ""%1"", không có chi phí thực tế (kế toán doanh nghiệp) liên quan đến việc mua sắm và đã được hình thành trước cuối tháng.
		                              |Cần kiểm tra các chứng từ đã phản ánh các chi phí này.';
		                              |ru = 'По нематериальному активу ""%1"" отсутствуют фактические затраты (бух. учет), связанные с его приобретением и сформированные до конца месяца.
		                              |Необходимо проверить документы, которыми были отражены затраты.';
		                              |en = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |it = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |pl = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |tr = '""%1"" maddi olmayan varlığı için, satın alımıyla ilişkili olan ve ay sonuna kadar oluşan fiili giderler (genel muhasebe) bulunmamaktadır.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateIsNMA_N_Null = NStr("vi = 'Đối với tài sản cố định vô hình ""%1"", không có chi phí thực tế (kế toán thuế) liên quan đến việc mua sắm và đã được hình thành trước cuối tháng.
		                              |Cần kiểm tra các chứng từ đã phản ánh các chi phí này.';
		                              |ru = 'По нематериальному активу ""%1"" отсутствуют фактические затраты (нал. учет), связанные с его приобретением и сформированные до конца месяца.
		                              |Необходимо проверить документы, которыми были отражены затраты.';
		                              |en = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |it = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |pl = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |tr = '""%1"" maddi olmayan varlığı için, satın alımıyla ilişkili olan ve ay sonuna kadar oluşan fiili giderler (vergi muhasebesi) bulunmamaktadır.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateNMA_U_Null = NStr("vi = 'Đối với tài sản cố định vô hình ""%1"", không có chi phí thực tế (kế toán quản trị) liên quan đến việc mua sắm và đã được hình thành trước cuối tháng.
		                              |Cần kiểm tra các chứng từ đã phản ánh các chi phí này.';
		                              |ru = 'По нематериальному активу ""%1"" отсутствуют фактические затраты (упр. учет), связанные с его приобретением и сформированные до конца месяца.
		                              |Необходимо проверить документы, которыми были отражены затраты.';
		                              |en = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |it = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |pl = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the end of the month.
		                              |Check the documents that recorded the expenses.';
		                              |tr = '""%1"" maddi olmayan varlığı için, satın alımıyla ilişkili olan ve ay sonuna kadar oluşan fiili giderler (yönetim muhasebesi) bulunmamaktadır.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
			MessageTemplateRAndD_BU_Null = NStr("vi = 'Theo chi phí nghiên cứu triển khai ""%1"" không có số tiền chi phí thực tế (kế toán doanh nghiệp) đã được hình thành trước cuối tháng.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По расходам на НИОКР ""%1"" отсутствуют фактические суммы расходов (бух. учет), сформированные до конца месяца.
		                              |Необходимо проверить документы, которыми были отражены расходы.';
		                              |en = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.'; fa = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |it = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |pl = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |tr = '""%1"" AR-GE giderleri için, ay sonuna kadar oluşan fiili gider tutarları (genel muhasebe) bulunmamaktadır.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateOfRAndDIsNull = NStr("vi = 'Theo chi phí nghiên cứu triển khai ""%1"" không có số tiền chi phí thực tế (kế toán thuế) đã được hình thành trước cuối tháng.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По расходам на НИОКР ""%1"" отсутствуют фактические суммы расходов (нал. учет), сформированные до конца месяца.
		                              |Необходимо проверить документы, которыми были отражены расходы.';
		                              |en = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.'; fa = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |it = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |pl = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |tr = '""%1"" AR-GE giderleri için, ay sonuna kadar oluşan fiili gider tutarları (vergi muhasebesi) bulunmamaktadır.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateRAndD_UU_Null = NStr("vi = 'Theo chi phí nghiên cứu triển khai ""%1"" không có số tiền chi phí thực tế (kế toán quản trị) đã được hình thành trước cuối tháng.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По расходам на НИОКР ""%1"" отсутствуют фактические суммы расходов (упр. учет), сформированные до конца месяца.
		                              |Необходимо проверить документы, которыми были отражены расходы.';
		                              |en = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.'; fa = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |it = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |pl = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the end of the month.
		                              |Check the documents in which the expenses were recorded.';
		                              |tr = '""%1"" AR-GE giderleri için, ay sonuna kadar oluşan fiili gider tutarları (yönetim muhasebesi) bulunmamaktadır.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
		                              
		Else
			
			If Selection.OSType = Enums.FATypes.DepreciationComponent Then
				
				MessageTemplateOS_BU_Null = NStr("vi = 'Theo thành phần tài sản cố định ""%1"" không có chi phí thực tế (kế toán doanh nghiệp) liên quan đến việc mua sắm và đã được hình thành tính đến ngày lập chứng từ.
			                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
			                              |ru = 'По компоненту основного средства ""%1"" отсутствуют фактические затраты (бух. учет), связанные с его приобретением и сформированные по дату оформления документа.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset component has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymet amortisman bileşeni için, satın alımıyla ilişkili olan ve belgenin oluşturulma tarihine kadar oluşan fiili giderler (genel muhasebe) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				OS_N_ZeroMessageTemplate = NStr("vi = 'Theo thành phần tài sản cố định ""%1"" không có chi phí thực tế (kế toán thuế) liên quan đến việc mua sắm và đã được hình thành tính đến ngày lập chứng từ.
			                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
			                              |ru = 'По компоненту основного средства ""%1"" отсутствуют фактические затраты (нал. учет), связанные с его приобретением и сформированные по дату оформления документа.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset component has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymet amortisman bileşeni için, satın alımıyla ilişkili olan ve belgenin oluşturulma tarihine kadar oluşan fiili giderler (vergi muhasebesi) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				MessageTemplateOS_U_Null = NStr("vi = 'Theo thành phần tài sản cố định ""%1"" không có chi phí thực tế (kế toán quản trị) liên quan đến việc mua sắm và đã được hình thành tính đến ngày lập chứng từ.
			                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
			                              |ru = 'По компоненту основного средства ""%1"" отсутствуют фактические затраты (упр. учет), связанные с его приобретением и сформированные по дату оформления документа.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset component has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymet amortisman bileşeni için, satın alımıyla ilişkili olan ve belgenin oluşturulma tarihine kadar oluşan fiili giderler (yönetim muhasebesi) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
			Else
				
				MessageTemplateOS_BU_Null = NStr("vi = 'Đối với tài sản cố định ""%1"", không có chi phí thực tế (kế toán doanh nghiệp) đã được hình thành tính đến ngày lập chứng từ.
			                              |Cần kiểm tra các chứng từ đã phản ánh các chi phí này.';
			                              |ru = 'У основного средства ""%1"" отсутствуют фактические затраты (бух. учет), сформированные по дату оформления документа.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset has no actual expenses (local accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymeti için, belgenin oluşturulma tarihine kadar oluşan fiili giderler (vergi muhasebesi) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				OS_N_ZeroMessageTemplate = NStr("vi = 'Đối với tài sản cố định ""%1"", không có chi phí thực tế (kế toán thuế) đã được hình thành tính đến ngày lập chứng từ.
			                              |Cần kiểm tra các chứng từ đã phản ánh các chi phí này.';
			                              |ru = 'У основного средства ""%1"" отсутствуют фактические затраты (нал. учет), сформированные по дату оформления документа.
			                              |Необходимо проверить документы, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |it = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |pl = 'The ""%1"" fixed asset has no actual expenses (tax accounting) generated before the document creation date.
			                              |Check the documents that recorded the expenses.';
			                              |tr = '""%1"" sabit kıymeti için, belgenin oluşturulma tarihine kadar oluşan fiili giderler (vergi muhasebesi) bulunmamaktadır.
			                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
				MessageTemplateOS_U_Null = NStr("vi = 'Đối với tài sản cố định ""%1"", không có chi phí thực tế (kế toán quản trị) đã được hình thành tính đến ngày lập chứng từ.
			                              |Cần kiểm tra việc điền thông tin trong các chứng từ đã phản ánh các chi phí này.';
			                              |ru = 'У основного средства ""%1"" отсутствуют фактические затраты (упр. учет), сформированные по дату оформления документа.
			                              |Необходимо проверить заполнение в документах, которыми были отражены затраты.';
			                              |en = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the document creation date.
			                              |Check the documents in which the costs were recorded.'; fa = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the document creation date.
			                              |Check the documents in which the costs were recorded.';
			                              |it = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the document creation date.
			                              |Check the documents in which the costs were recorded.';
			                              |pl = 'The ""%1"" fixed asset has no actual expenses (mgmt accounting) generated before the document creation date.
			                              |Check the documents in which the costs were recorded.';
			                              |tr = '""%1"" sabit kıymeti için, belgenin oluşturulma tarihine kadar oluşan fiili giderler (yönetim muhasebesi) bulunmuyor.
			                              | Giderlerin yansıtıldığı belgelerin doldurulma durumunun kontrol edilmesi gerekir.'");
			                              
			EndIf;
			
			MessageTemplateNMA_BU_Null = NStr("vi = 'Theo tài sản cố định vô hình ""%1"" không có chi phí thực tế (kế toán doanh nghiệp) liên quan đến việc mua sắm và đã được hình thành tính đến ngày lập chứng từ.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По нематериальному активу ""%1"" отсутствуют фактические затраты (бух. учет), связанные с его приобретением и сформированные по дату оформления документа.
		                              |Необходимо проверить документы, которыми были отражены затраты.';
		                              |en = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |it = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |pl = 'The ""%1"" intangible asset has no actual expenses (local accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |tr = '""%1"" maddi olmayan varlığı için, satın alımıyla ilişkili olan ve belgenin oluşturulma tarihine kadar oluşan fiili giderler (genel muhasebe) bulunmuyor.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateIsNMA_N_Null = NStr("vi = 'Theo tài sản cố định vô hình ""%1"" không có chi phí thực tế (kế toán thuế) liên quan đến việc mua sắm và đã được hình thành tính đến ngày lập chứng từ.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По нематериальному активу ""%1"" отсутствуют фактические затраты (нал. учет), связанные с его приобретением и сформированные по дату оформления документа.
		                              |Необходимо проверить документы, которыми были отражены затраты.';
		                              |en = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |it = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |pl = 'The ""%1"" intangible asset has no actual expenses (tax accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |tr = '""%1"" maddi olmayan varlığı için, satın alımıyla ilişkili olan ve belgenin oluşturulma tarihine kadar oluşan fiili giderler (vergi muhasebesi) bulunmuyor.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateNMA_U_Null = NStr("vi = 'Theo tài sản cố định vô hình ""%1"" không có chi phí thực tế (kế toán quản trị) liên quan đến việc mua sắm và đã được hình thành tính đến ngày lập chứng từ.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По нематериальному активу ""%1"" отсутствуют фактические затраты (упр. учет), связанные с его приобретением и сформированные по дату оформления документа.
		                              |Необходимо проверить документы, которыми были отражены затраты.';
		                              |en = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.'; fa = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |it = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |pl = 'The ""%1"" intangible asset has no actual expenses (mgmt accounting) associated with its acquisition and generated before the document creation date.
		                              |Check the documents that recorded the expenses.';
		                              |tr = '""%1"" maddi olmayan varlığı için, satın alımıyla ilişkili olan ve belgenin oluşturulma tarihine kadar oluşan fiili giderler (yönetim muhasebesi) bulunmuyor. 
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
				
			MessageTemplateRAndD_BU_Null = NStr("vi = 'Theo chi phí nghiên cứu triển khai ""%1"" không có số tiền chi phí thực tế (kế toán doanh nghiệp) đã được hình thành tính đến ngày lập chứng từ.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По расходам на НИОКР ""%1"" отсутствуют фактические суммы расходов (бух. учет), сформированные по дату оформления документа.
		                              |Необходимо проверить документы, которыми были отражены расходы.';
		                              |en = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.'; fa = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |it = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |pl = 'The ""%1"" R&D expenses have no actual expense amounts (local accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |tr = '""%1"" AR-GE giderleri için, belgenin oluşturulma tarihine kadar oluşan fiili gider tutarları (genel muhasebe) bulunmuyor.
		                              | Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateOfRAndDIsNull = NStr("vi = 'Theo chi phí nghiên cứu triển khai ""%1"" không có số tiền chi phí thực tế (kế toán thuế) đã được hình thành tính đến ngày lập chứng từ.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По расходам на НИОКР ""%1"" отсутствуют фактические суммы расходов (нал. учет), сформированные по дату оформления документа.
		                              |Необходимо проверить документы, которыми были отражены расходы.';
		                              |en = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.'; fa = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |it = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |pl = 'The ""%1"" R&D expenses have no actual expense amounts (tax accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |tr = '""%1"" AR-GE giderleri için, belgenin oluşturulma tarihine kadar oluşan fiili gider tutarları (yönetim muhasebesi) bulunmamaktadır.
		                              |Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
			
			MessageTemplateRAndD_UU_Null = NStr("vi = 'Theo chi phí nghiên cứu triển khai ""%1"" không có số tiền chi phí thực tế (kế toán quản trị) đã được hình thành tính đến ngày lập chứng từ.
		                              |Cần kiểm tra chứng từ đã phản ánh chi phí.';
		                              |ru = 'По расходам на НИОКР ""%1"" отсутствуют фактические суммы расходов (упр. учет), сформированные по дату оформления документа.
		                              |Необходимо проверить документы, которыми были отражены расходы.';
		                              |en = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.'; fa = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |it = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |pl = 'The ""%1"" R&D expenses have no actual expense amounts (mgmt accounting) generated before the document creation date.
		                              |Check the documents in which the expenses were recorded.';
		                              |tr = '""%1"" AR-GE giderleri için, belgenin oluşturulma tarihine kadar oluşan fiili gider tutarları (yönetim muhasebesi) bulunmamaktadır.
		                              |Giderlerin yansıtıldığı belgelerin kontrol edilmesi gerekir.'");
	
		EndIf;
		
		If TypeOf(Selection.AccountingObject) = Type("CatalogRef.Assets") Then
			
			ErrorText_ACC_Zero = MessageTemplateOS_BU_Null;
			ErrorText_N_Null = OS_N_ZeroMessageTemplate;
			ErrorText_MA_Zero = MessageTemplateOS_U_Null;
			
		ElsIf TypeOf(Selection.AccountingObject) = Type("CatalogRef.IntangibleAssets") Then
			
			If Selection.KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.IntangibleAsset Then
				ErrorText_ACC_Zero = MessageTemplateNMA_BU_Null;
				ErrorText_N_Null = MessageTemplateIsNMA_N_Null;
				ErrorText_MA_Zero = MessageTemplateNMA_U_Null;
			Else
				ErrorText_ACC_Zero = MessageTemplateRAndD_BU_Null;
				ErrorText_N_Null = MessageTemplateOfRAndDIsNull;
				ErrorText_MA_Zero = MessageTemplateRAndD_UU_Null;
			EndIf;
			 
		EndIf; 
		
		If Selection.ActualCostOfAC = 0
			And Selection.PostInAccounting Then
			
			ErrorText = StrTemplate(ErrorText_ACC_Zero, Selection.AccountingObject);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost, 
				Period,
				Selection.Organization,
				ErrorText,,
				Selection.Ref);
				
		EndIf; 
	
		If Selection.ActualCostTa = 0
			And Selection.RecordInTA Then
			
			ErrorText = StrTemplate(ErrorText_N_Null, Selection.AccountingObject);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost, 
				Period,
				Selection.Organization,
				ErrorText,,
				Selection.Ref);
				
		EndIf; 
	
		If Selection.ActualCostOfMa = 0
			And Selection.RecordInManAccounting Then
			
			ErrorText = StrTemplate(ErrorText_MA_Zero, Selection.AccountingObject);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost, 
				Period,
				Selection.Organization,
				ErrorText,,
				Selection.Ref);
				
		EndIf; 
	
	EndDo;
	
	#EndRegion
	
	#Region CheckingProcedureForGeneratingCostOfBHA
	
	QueryText =
	"SELECT
	|	TTTableOfObjects.Ref AS Ref,
	|	TTTableOfObjects.Organization AS Organization,
	|	TTTableOfObjects.AccountingObject AS AccountingObject,
	|
	|	MAX(TTTableOfObjects.RecordInManAccounting) AS RecordInMA,
	|	MAX(TTTableOfObjects.PostInAccounting) AS PostInAccounting,
	|	MAX(TTTableOfObjects.RecordInTA) AS RecordInTA
	|
	|INTO TTListOfObjects_ProcedureForGeneratingCostOfVNA
	|
	|FROM
	|	TTTableOfObjects AS TTTableOfObjects
	|
	|WHERE
	|	TTTableOfObjects.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeEndOfMonthInWhichDocumentIsCreatedInCost)
	|
	|GROUP BY
	|	TTTableOfObjects.Ref,
	|	TTTableOfObjects.AccountingObject,
	|	TTTableOfObjects.Organization
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsList.AccountingObject AS AccountingObject,
	|	
	|	SUM(DocumentsList.PostInAccounting) AS PostInAccounting,
	|	SUM(DocumentsList.RecordInTA) AS RecordInTA,
	|	SUM(DocumentsList.RecordInMA) AS RecordInMA
	|
	|INTO TTListOfDocuments_CostFormationProcedure
	|
	|FROM
	|	(SELECT
	|		FATable.FixedAsset AS AccountingObject,
	|	
	|		CASE
	|			WHEN DocumentData.PostInAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS PostInAccounting,
	|
	|		CASE
	|			WHEN DocumentData.RecordInTA
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInTA,
	|
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInMA
	|
	|	FROM
	|		Document.FixedAssetsInitialRecognition2_4 AS DocumentData
	|
	|			INNER JOIN Document.FixedAssetsInitialRecognition2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.Posted
	|
	|		AND FATable.FixedAsset IN (
	|			SELECT
	|				TTListOfObjects.AccountingObject
	|			FROM
	|				TTListOfObjects_ProcedureForGeneratingCostOfVNA AS TTListOfObjects)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FATable.DepreciationComponent AS AccountingObject,
	|	
	|		CASE
	|			WHEN DocumentData.RecordInLocalAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS PostInAccounting,
	|
	|		0 AS RecordInTA,
	|
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInMA
	|
	|	FROM
	|		Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|			INNER JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.Posted
	|
	|		AND FATable.DepreciationComponent IN (
	|			SELECT
	|				TTListOfObjects.AccountingObject
	|			FROM
	|				TTListOfObjects_ProcedureForGeneratingCostOfVNA AS TTListOfObjects)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FATable.FixedAsset AS AccountingObject,
	|	
	|		CASE
	|			WHEN DocumentData.RecordInLocalAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS PostInAccounting,
	|
	|		
	|		CASE
	|			WHEN DocumentData.RecordInLocalAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInTA,
	|
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInMA
	|
	|	FROM
	|		Document.FixedAssetsCostAdditions2_4 AS DocumentData
	|
	|			INNER JOIN Document.FixedAssetsCostAdditions2_4.FA AS FATable
	|			ON FATable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.Posted
	|
	|		AND FATable.FixedAsset IN (
	|			SELECT
	|				TTListOfObjects.AccountingObject
	|			FROM
	|				TTListOfObjects_ProcedureForGeneratingCostOfVNA AS TTListOfObjects)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.IntangibleAsset AS AccountingObject,
	|	
	|		CASE
	|			WHEN DocumentData.PostInAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS PostInAccounting,
	|
	|		CASE
	|			WHEN DocumentData.RecordInTA
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInTA,
	|
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInMA
	|
	|	FROM
	|		Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.Posted
	|
	|		AND DocumentData.IntangibleAsset IN (
	|			SELECT
	|				TTListOfObjects.AccountingObject
	|			FROM
	|				TTListOfObjects_ProcedureForGeneratingCostOfVNA AS TTListOfObjects)
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableOfIA.IntangibleAsset AS AccountingObject,
	|	
	|		CASE
	|			WHEN DocumentData.PostInAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS PostInAccounting,
	|
	|		CASE
	|			WHEN DocumentData.RecordInTA
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInTA,
	|
	|		CASE
	|			WHEN DocumentData.RecordInManAccounting
	|				THEN 1
	|			ELSE 0
	|		END AS RecordInMA
	|
	|	FROM
	|		Document.IntangibleAssetImprovement AS DocumentData
	|
	|			INNER JOIN Document.IntangibleAssetImprovement.IA AS TableOfIA
	|			ON TableOfIA.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|		AND DocumentData.Posted
	|
	|		AND TableOfIA.IntangibleAsset IN (
	|			SELECT
	|				TTListOfObjects.AccountingObject
	|			FROM
	|				TTListOfObjects_ProcedureForGeneratingCostOfVNA AS TTListOfObjects)
	|
	|	) AS DocumentsList
	|
	|GROUP BY
	|	DocumentsList.AccountingObject
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTListOfObjects.Ref AS Ref,
	|	TTListOfObjects.Organization AS Organization,
	|	TTListOfObjects.AccountingObject AS AccountingObject
	|
	|INTO ListOfErrors_CostGenerationProcedure
	|
	|FROM
	|	TTListOfObjects_ProcedureForGeneratingCostOfVNA AS TTListOfObjects
	|
	|WHERE
	|	TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTListOfDocuments_CostFormationProcedure AS TTListOfDocuments
	|		WHERE
	|			TTListOfDocuments.AccountingObject = TTListOfObjects.AccountingObject
	|
	|			AND (TTListOfObjects.RecordInMA
	|					AND TTListOfDocuments.RecordInMA > 1
	|				OR TTListOfObjects.PostInAccounting
	|					AND TTListOfDocuments.PostInAccounting > 1
	|				OR TTListOfObjects.RecordInTA
	|					AND TTListOfDocuments.RecordInTA > 1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ErrorList.Ref AS Ref,
	|	ErrorList.Organization AS Organization,
	|	ErrorList.AccountingObject AS AccountingObject,
	|	ISNULL(Assets.Presentation, IntangibleAssets.Presentation) AS AccountingObjectPresentation
	|
	|FROM
	|	ListOfErrors_CostGenerationProcedure AS ErrorList
	|
	|		LEFT JOIN Catalog.Assets AS Assets
	|		ON Assets.Ref = ErrorList.AccountingObject
	|
	|		LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|		ON IntangibleAssets.Ref = ErrorList.AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.SetParameter("BegOfMonth", BegOfMonth(ExecutionParameters.EndOfPeriod));
	Query.SetParameter("EndOfMonth", EndOfMonth(ExecutionParameters.EndOfPeriod));
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		If TypeOf(Selection.AccountingObject) = Type("CatalogRef.IntangibleAssets") Then
			ErrorText = NStr("vi = 'Không hỗ trợ tính giá trị cho tài sản cố định vô hình ""%1"" theo chứng từ %2, vì có nhiều chứng từ được lập trong cùng một tháng và phương thức hình thành giá trị được chọn là ""Bao gồm chi phí phát sinh trước cuối tháng lập chứng từ"".';
							|ru = 'Не поддерживается расчет стоимости для нематериального актива ""%1"" по документу %2, т.к. оформлено несколько документов в одном месяце и выбран порядок формирования стоимости ""Включить в стоимость расходы, поступившие до конца месяца, в котором оформлен документ"".';
							|en = 'Cannot calculate the ""%1"" intangible asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".'; fa = 'Cannot calculate the ""%1"" intangible asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".';
							|it = 'Cannot calculate the ""%1"" intangible asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".';
							|pl = 'Cannot calculate the ""%1"" intangible asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".';
							|tr = 'Aynı ay içinde birden fazla belge oluşturulduğu ve ""Belgenin oluşturulduğu ayın sonuna kadar gelen giderleri maliyete dahil et"" maliyet oluşturma düzeni seçildiği için, %2 belgesi uyarınca ""%1"" maddi olmayan varlığının maliyet hesaplaması desteklenmemektedir.'");
			ErrorText = StrTemplate(ErrorText, Selection.AccountingObjectPresentation, Selection.Ref);
		Else
			ErrorText = NStr("vi = 'Không hỗ trợ tính giá trị cho tài sản cố định ""%1"" theo chứng từ %2, vì có nhiều chứng từ được lập trong cùng một tháng và phương thức hình thành giá trị được chọn là ""Bao gồm chi phí phát sinh trước cuối tháng lập chứng từ"".';
							|ru = 'Не поддерживается расчет стоимости для основного средства ""%1"" по документу %2, т.к. оформлено несколько документов в одном месяце и выбран порядок формирования стоимости ""Включить в стоимость расходы, поступившие до конца месяца, в котором оформлен документ"".';
							|en = 'Cannot calculate the ""%1"" fixed asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".'; fa = 'Cannot calculate the ""%1"" fixed asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".';
							|it = 'Cannot calculate the ""%1"" fixed asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".';
							|pl = 'Cannot calculate the ""%1"" fixed asset cost by the ""%2"" document as several documents were issued in one month and the cost generation procedure is ""Include expenses received before end of month in which document is created"".';
							|tr = 'Aynı ay içinde birden fazla belge oluşturulduğu ve ""Belgenin oluşturulduğu ayın sonuna kadar gelen giderleri maliyete dahil et"" maliyet oluşturma düzeni seçildiği için, %2 belgesi uyarınca ""%1"" sabit kıymetinin maliyet hesaplaması desteklenmemektedir.'");
			ErrorText = StrTemplate(ErrorText, Selection.AccountingObjectPresentation, Selection.Ref);
		EndIf;
		
		NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
			Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost, 
			Period,
			Selection.Organization,
			ErrorText,,
			Selection.Ref);
			
	EndDo;
	
	#EndRegion

	#Region SavingAllErrors
	
	If ExecutionParameters.TempTablesManager.Tables.Find("ErrorListLocalization") <> Undefined Then
		
		QueryText =
		"SELECT DISTINCT
		|	ErrorList.AccountingObject AS AccountingObject
		|
		|INTO TTErrors
		|
		|FROM
		|	ErrorList AS ErrorList
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ErrorList.AccountingObject AS AccountingObject
		|
		|FROM
		|	ListOfErrors_CostGenerationProcedure AS ErrorList
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ErrorList.AccountingObject AS AccountingObject
		|
		|FROM
		|	ErrorListLocalization AS ErrorList
		|
		|INDEX BY
		|	AccountingObject
		|";
		
	Else
		
		QueryText =
		"SELECT DISTINCT
		|	ErrorList.AccountingObject AS AccountingObject
		|
		|INTO TTErrors
		|
		|FROM
		|	ErrorList AS ErrorList
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ErrorList.AccountingObject AS AccountingObject
		|
		|FROM
		|	ListOfErrors_CostGenerationProcedure AS ErrorList
		|
		|INDEX BY
		|	AccountingObject
		|";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.Execute();

	#EndRegion				
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Procedure DeleteTasksPortionsOfData(Period, ExecutionParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.DeleteTasksPortionsOfData");

	TTUsed = TMCommonUse.ListOfTemporaryTables(ExecutionParameters.TempTablesManager);

	QueryText =
	"SELECT DISTINCT
	|	TTAllDataToBeCalculated.AccountingObject AS AccountingObject
	|
	|INTO TTUnprocessedData
	|
	|FROM
	|	TTAllDataToBeCalculated AS TTAllDataToBeCalculated
	|
	|WHERE
	|	NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				ProcessedOneData AS ProcessedOneData
	|			WHERE
	|				ProcessedOneData.Ref = TTAllDataToBeCalculated.Ref
	|				AND NOT ProcessedOneData.HasErrors)
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTPortionOfDataToBeCalculated.AccountingObject AS AccountingObject
	|
	|INTO TTTasksToDelete
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|WHERE
	|	NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTUnprocessedData AS TTUnprocessedData
	|			WHERE
	|				TTUnprocessedData.AccountingObject = TTPortionOfDataToBeCalculated.AccountingObject)
	|
	|INDEX BY
	|	AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.Execute();
	
	InformationRegisters.JobsForCalculatingNonCurrentAssetCost.FixCalculation(
		Period,
		ExecutionParameters.CompaniesList, 
		ExecutionParameters.NumberBeforeSettlement, 
		ExecutionParameters.TempTablesManager,
		"TTTasksToDelete");

	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Procedure DeleteTasksByDate(Period, ExecutionParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FACostCalculation.DeleteTasksByDate");
	
	InformationRegisters.JobsForCalculatingNonCurrentAssetCost.FixCalculation(
		Period,
		ExecutionParameters.CompaniesList, 
		ExecutionParameters.NumberBeforeSettlement, 
		ExecutionParameters.TempTablesManager,
		"ListOfObjects");

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Procedure RememberProcessedData(ExecutionParameters)
	
	ListOfRequests = New Array;
	
	If ExecutionParameters.TempTablesManager.Tables.Find("TTErrors") <> Undefined Then
		
		QueryText = 
		"SELECT
		|	TTPortionOfDataToBeCalculated.Ref AS Ref,
		|	TTPortionOfDataToBeCalculated.AccountingObject AS AccountingObject,
		|	CASE
		|		WHEN TRUE IN (
		|				SELECT TOP 1
		|					TRUE
		|				FROM
		|					TTErrors AS TTErrors
		|				WHERE
		|					TTErrors.AccountingObject = TTPortionOfDataToBeCalculated.AccountingObject)
		|			THEN TRUE
		|		ELSE FALSE
		|	END HasErrors
		|
		|INTO ProcessedOneData_Temporary
		|
		|FROM
		|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
		|
		|UNION ALL
		|
		|SELECT
		|	ProcessedOneData.Ref AS Ref,
		|	ProcessedOneData.AccountingObject AS AccountingObject,
		|	ProcessedOneData.HasErrors AS HasErrors
		|FROM
		|	ProcessedOneData AS ProcessedOneData
		|
		|INDEX BY
		|	Ref
		|";
		
	Else
		
		QueryText = 
		"SELECT
		|	TTPortionOfDataToBeCalculated.Ref AS Ref,
		|	TTPortionOfDataToBeCalculated.AccountingObject AS AccountingObject,
		|	FALSE HasErrors
		|
		|INTO ProcessedOneData_Temporary
		|
		|FROM
		|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
		|
		|UNION ALL
		|
		|SELECT
		|	ProcessedOneData.Ref AS Ref,
		|	ProcessedOneData.AccountingObject AS AccountingObject,
		|	ProcessedOneData.HasErrors AS HasErrors
		|FROM
		|	ProcessedOneData AS ProcessedOneData
		|
		|INDEX BY
		|	Ref
		|";
		
	EndIf;
	ListOfRequests.Add(QueryText);
	
	QueryText =
	"DROP ProcessedOneData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProcessedOneData.Ref AS Ref,
	|	ProcessedOneData.AccountingObject AS AccountingObject,
	|	ProcessedOneData.HasErrors AS HasErrors
	|
	|INTO ProcessedOneData
	|
	|FROM
	|	ProcessedOneData_Temporary AS ProcessedOneData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProcessedOneData_Temporary
	|";
	ListOfRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Function CalculateExpenses(TableOfCostCapitalizationAnalysts, ObjectsTable, ExpensesTable)

	CalculationOfExpenses = ExpensesTable.CopyColumns();
	CalculationOfExpenses.Columns.Add("Ref", ObjectsTable.Columns.Ref.ValueType);
	CalculationOfExpenses.Columns.Add("AccountingObject", New TypeDescription("CatalogRef.Assets,CatalogRef.IntangibleAssets"));
	CalculationOfExpenses.Columns.Add("CFAmount", TMCommonUse.MoneyFieldTypeDescription());
	CalculationOfExpenses.Columns.Add("SumOfNUCF", TMCommonUse.MoneyFieldTypeDescription());
	CalculationOfExpenses.Columns.Add("PRCFAmount", TMCommonUse.MoneyFieldTypeDescription());
	CalculationOfExpenses.Columns.Add("DisregardedCostTA", TMCommonUse.MoneyFieldTypeDescription());
	CalculationOfExpenses.Columns.Add("RowID", Common.StringTypeDetails(36));
	CalculationOfExpenses.Columns.Add("IdOfACLine", Common.StringTypeDetails(36));
	CalculationOfExpenses.Columns.Add("RowIDTA", Common.StringTypeDetails(36));
	CalculationOfExpenses.Columns.Add("IdOfTFLine", Common.StringTypeDetails(36));
	
	For Each AnalyticsData In TableOfCostCapitalizationAnalysts Do
		
		TheStructureOfTheSearch = New Structure("DimensionOfExpenses", AnalyticsData.ExpensesCapitalizationDimension);
		CapitalizationAnalyticsExpenses = ExpensesTable.Copy(TheStructureOfTheSearch);
		
		TheStructureOfTheSearch = New Structure("ExpensesCapitalizationDimension", AnalyticsData.ExpensesCapitalizationDimension);
		ObjectsByCapitalizationAnalytics = ObjectsTable.FindRows(TheStructureOfTheSearch);
		
		If AnalyticsData.ActualCost Then
			
			CalculateExpensesByActualCost(
				CalculationOfExpenses, AnalyticsData, ObjectsTable, CapitalizationAnalyticsExpenses);
			
		ElsIf AnalyticsData.ExpensesAreDistributedByObjects Then
				
			DistributeExpensesByObjects(
				CalculationOfExpenses, ObjectsByCapitalizationAnalytics, CapitalizationAnalyticsExpenses);
				
		Else
				
			CalculateExpensesForObjects(CalculationOfExpenses, ObjectsByCapitalizationAnalytics, CapitalizationAnalyticsExpenses);
				
		EndIf;
		
	EndDo;
	
	FACostCalculationLocalization.ProcessExpenseCalculation(CalculationOfExpenses, ObjectsTable);
	
	For Each RowData In CalculationOfExpenses Do
		RowData.RowID = New UUID();
		RowData.IdOfACLine = New UUID();
		RowData.RowIDTA = New UUID();
		RowData.IdOfTFLine = New UUID();
	EndDo;
	
	Return CalculationOfExpenses;

EndFunction

Procedure CreateTTTableWithListOfDocuments(BeginOfPeriod, EndOfPeriod, CompaniesList, TempTablesManager)
	
	QueryText =
	"SELECT DISTINCT
	|	CurrentDocuments.Recorder AS Ref
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	AccumulationRegister.FACost AS CurrentDocuments
	|
	|WHERE
	|	CurrentDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CurrentDocuments.Organization IN (&CompaniesList)
	|	AND VALUETYPE(CurrentDocuments.Recorder) IN (&DocumentTypes)
	|	AND CurrentDocuments.BusinessOperation IN (&BusinessTransactions)
	|	AND CurrentDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CurrentDocuments.Active
	|
	|	AND TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			JobsForCalculating AS JobsForCalculating
	|		WHERE
	|			JobsForCalculating.AccountingObject = CurrentDocuments.FixedAsset
	|			OR JobsForCalculating.AccountingObject = CurrentDocuments.ExpensesCapitalizationDimension)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CurrentDocuments.Recorder AS Ref
	|FROM
	|	AccumulationRegister.IACost AS CurrentDocuments
	|
	|WHERE
	|	CurrentDocuments.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CurrentDocuments.Organization IN (&CompaniesList)
	|	AND VALUETYPE(CurrentDocuments.Recorder) IN (&DocumentTypes)
	|	AND CurrentDocuments.BusinessOperation IN (&BusinessTransactions)
	|	AND CurrentDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CurrentDocuments.Active
	|
	|	AND TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			JobsForCalculating AS JobsForCalculating
	|		WHERE
	|			JobsForCalculating.AccountingObject = CurrentDocuments.IntangibleAsset)
	|
	|INDEX BY
	|	Ref
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("DocumentTypes", TypesOfDocumentsForWhichCostIsCalculated());
	Query.SetParameter("BusinessTransactions", BusinessOperationsForWhichCostIsCalculated());
	
	Query.Execute();
	
EndProcedure

Function ThereAreDocumentsAccordingToWhichRegisteredRecordsAreFormed(HandlerParameters)

	CalculationParameters = HandlerParameters.CalculationParameters;
	
	QueryText = 
	"SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	AccumulationRegister.FACost AS DataForCalculation
	|WHERE
	|	DataForCalculation.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DataForCalculation.Organization IN(&Organization)
	|	AND DataForCalculation.Active
	|	AND DataForCalculation.CostCalculation
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	AccumulationRegister.IACost AS DataForCalculation
	|WHERE
	|	DataForCalculation.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DataForCalculation.Organization IN(&Organization)
	|	AND DataForCalculation.Active
	|	AND DataForCalculation.CostCalculation";
	
	Query = New Query(QueryText);
	Query.SetParameter("BegOfMonth", BegOfMonth(CalculationParameters.Period));
	Query.SetParameter("EndOfMonth", EndOfMonth(CalculationParameters.Period));
	Query.SetParameter("Organization", CalculationParameters.CompanyArray);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

#EndRegion

#Region UpdatingRecordsOfFixedAssetsAndIntangibleAssets

Procedure CreateTasksToUpdateRegisterRecords(TempTablesManager)
	
	QueryText = 
	"SELECT
	|	TTTableOfObjects.Ref AS Document,
	|	TTTableOfObjects.Organization AS Organization,
	|	TTTableOfObjects.AccountingObject AS AccountingObject,
	|	MIN(TTTableOfObjects.Date) AS Month
	|
	|FROM
	|	TTTableOfObjects AS TTTableOfObjects
	|
	|GROUP BY
	|	TTTableOfObjects.Ref,
	|	TTTableOfObjects.Organization,
	|	TTTableOfObjects.AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	InformationRegisters.JobsForUpdatingFixedAssetRecords.CreateRegisterEntriesBasedOnSampleData(QueryResult.Select());
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Other

// Generates the query text in the table.
// 
// Parameters:
//  Query - Query -
//  QueryTexts - ValueList of String -
//  TableName - String, Undefined - table name
Procedure AddEmptyCostCalculationTables(Query, QueryTexts, TableName = Undefined) Export

	If TableName = Undefined Then
		TableName = "TTCostCalculation";
	EndIf; 
	
	If Query.TempTablesManager <> Undefined
		And Query.TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS AccountingObject,
	|	NULL   AS ExpenseItem,
	|	NULL   AS DimensionOfExpenses,
	|	NULL   AS Department,
	|	NULL   AS LineOfBusiness,
	|	0      AS Sum,
	|	0      AS AmountExcludingVAT,
	|	0      AS AmountOfUU,
	|	0      AS AmountAccounting,
	|	0      AS AmountFA,
	|	0      AS AmountPermanentDifferences,
	|	0      AS CFAmount,
	|	0      AS SumOfNUCF,
	|	0      AS PRCFAmount,
	|	0      AS DepreciationAllowance,
	|	0      AS CostRevaluationReserve,
	|	0      AS CostRevaluationReserveLocal,
	|	0      AS SecurityDepositValue,
	|	0      AS PreliminaryCostMan,
	|	0      AS PreliminaryCostLocal,
	|	0      AS DisregardedCostTA,
	|	0      AS AITAmount,
	|	0      AS LineNumber,
	|	NULL   AS VariancePeriod,
	|	""""   AS RowID,
	|	""""   AS IdOfACLine,
	|	""""   AS RowIDTA,
	|	""""   AS IdOfTFLine
	|
	|INTO TTTableName
	| 
	|WHERE
	|	FALSE
	|";
	
	QueryText = StrReplace(QueryText, "TTTableName", TableName);
	QueryTexts.Add(QueryText, TableName);
	
	QueryText =
	"SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS AccountingObject,
	|
	|	0 AS AmountOfUU,
	|	0 AS AmountAccounting,
	|	0 AS AmountFA,
	|	0 AS AmountPermanentDifferences,
	|	0 AS CFAmount,
	|	0 AS SumOfNUCF,
	|	0 AS PRCFAmount
	|
	|INTO TTCostCalculationGrouped
	| 
	|WHERE
	|	FALSE
	|";
	
	QueryTexts.Add(QueryText, "TTCostCalculationGrouped");
	
EndProcedure

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

Procedure CreateTTAccountingPolicy(Period, TempTablesManager)
	
	QueryText = FACostCalculationLocalization.QueryTextTTAccountingPolicy();
	
	If QueryText = Undefined Then
		QueryText =
		"SELECT
		|	UNDEFINED AS Organization,
		|	FALSE AS IncludeRentalPaymentsAsPartOfTaxExpenses,
		|	FALSE AS IncomeTaxPayer
		|INTO TTAccountingPolicy
		|";
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("EndOfMonth", EndOfMonth(Period));
	
	Query.Execute();

EndProcedure

// Used for preliminary calculation of the cost.
//
// Parameters:
//  ReferencesArrray			 - Array - list of documents.
//  TempTablesManager	 - TempTablesManager - temporary table manager.
// 
// Returns:
//  Structure - Contains data for the start of preliminary cost calculation:
//      * Result - QueryResult -
//      * ObjectsForWhichInformationIsNotRelevant - Array of CatalogRef.Assets, CatalogRef.IntangibleAssets -
//
Function DataForPreliminaryCalculationOfValueOfNonCurrentAssets(ReferencesArrray, TempTablesManager = Undefined) Export

	QueryText = 
	"SELECT DISTINCT
	|	FACost.Period    AS Period,
	|	Jobs.AccountingObject   AS AccountingObject,
	|	Jobs.Organization   AS Organization
	|
	|INTO BorderCache
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|		INNER JOIN InformationRegister.JobsForCalculatingNonCurrentAssetCost AS Jobs
	|		ON (Jobs.Organization = FACost.Organization)
	|			AND (Jobs.AccountingObject = FACost.ExpensesCapitalizationDimension)
	|			AND (Jobs.Month <= FACost.Period)
	|
	|WHERE
	|	FACost.Recorder IN (&ReferencesArrray)
	|	AND VALUETYPE(FACost.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|	AND &MasterNode
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	FACost.Period                          AS Period,
	|	FACost.ExpensesCapitalizationDimension  AS AccountingObject,
	|	FACost.Organization                     AS Organization
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|		LEFT JOIN AccumulationRegister.FACost AS CostOfOS_CostCalculation
	|		ON CostOfOS_CostCalculation.Recorder = FACost.Recorder
	|			AND CostOfOS_CostCalculation.CostCalculation
	|
	|WHERE
	|	FACost.Recorder IN (&ReferencesArrray)
	|	AND VALUETYPE(FACost.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|	AND CostOfOS_CostCalculation.Recorder IS NULL
	|	AND NOT &MasterNode
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	IACost.Period   AS Period,
	|	Jobs.AccountingObject   AS AccountingObject,
	|	Jobs.Organization   AS Organization
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|
	|		INNER JOIN InformationRegister.JobsForCalculatingNonCurrentAssetCost AS Jobs
	|		ON (Jobs.Organization = IACost.Organization)
	|			AND (Jobs.AccountingObject = IACost.IntangibleAsset)
	|			AND (Jobs.Month <= IACost.Period)
	|
	|WHERE
	|	IACost.Recorder IN (&ReferencesArrray)
	|	AND VALUETYPE(IACost.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|	AND &MasterNode
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	IACost.Period               AS Period,
	|	IACost.IntangibleAsset  AS AccountingObject,
	|	IACost.Organization          AS Organization
	|
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|
	|		LEFT JOIN AccumulationRegister.IACost AS CostNMA_CostCalculation
	|		ON CostNMA_CostCalculation.Recorder = IACost.Recorder
	|			AND CostNMA_CostCalculation.CostCalculation
	|
	|WHERE
	|	IACost.Recorder IN (&ReferencesArrray)
	|	AND VALUETYPE(IACost.Recorder) IN (&TypesOfDocumentsForWhichCostIsCalculated)
	|	AND CostNMA_CostCalculation.Recorder IS NULL
	|	AND NOT &MasterNode
	|
	|INDEX BY
	|	Organization,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BorderCache.AccountingObject AS AccountingObject
	|FROM
	|	BorderCache AS BorderCache
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BorderCache.Period
	|FROM
	|	BorderCache AS BorderCache";
	
	Query = New Query(QueryText);
	If TempTablesManager <> Undefined Then
		Query.TempTablesManager = TempTablesManager;
	EndIf;
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("MasterNode", ExchangePlans.MasterNode() = Undefined);
	Query.SetParameter("TypesOfDocumentsForWhichCostIsCalculated", TypesOfDocumentsForWhichCostIsCalculated(True));
	
	Result = Query.ExecuteBatch();

	ObjectsForWhichInformationIsNotRelevant = Result[Result.UBound()-1].Unload().UnloadColumn("AccountingObject");
	
	Return New Structure(
			"Result, ObjectsForWhichInformationIsNotRelevant", 
			Result[Result.UBound()],
			ObjectsForWhichInformationIsNotRelevant);
	
EndFunction

// Determines that movements are recorded when performing the operation "calculating the cost of fixed assets and IA".
// Used to control the logic of motion recording.
//
// Parameters:
//  Object	 - InformationRegisterRecordSet - a set of register entries.
// 
// Returns:
//  Boolean - It is true if the Registered Records are recorded during the execution of operation.
//
Function RegisteredRecordsAreRecordedWhenOperationIsPerformed(Object) Export

	Return Object <> Undefined 
		And Object.AdditionalProperties.Property(NameOfFlagOfOperation());

EndFunction

// Determines that the Registered Records are recorded of operation "Updating Registered Records for FA and IA.
// It is used to control the logic of recording Registered Recorded movements.
//
// Parameters:
//  Object	 - InformationRegisterRecordSet - a set of register entries.
// 
// Returns:
//  Boolean - It is true if the Registered Records are recorded during the execution of operation.
//
Function RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA(Object) Export

	Return Object <> Undefined 
		And Object.AdditionalProperties.Property(NameOfSignOfOperationOfOperationUpdatingRegisteredRecordsFA());

EndFunction

// Set a sign of performing the calculation of the value of non-current assets.
// 
// Parameters:
//  DocumentObject - DocumentObject - Document.
Procedure SetFlagForOperation(DocumentObject) Export
	
	DocumentObject.AdditionalProperties.Insert(NameOfFlagOfOperation(), True);
	
EndProcedure

// The name of the attribute for calculating the value of non-current assets.
// 
// Returns:
//  String - The Name Of The Attribute For Calculating The Value Of Non-Current Assets
Function NameOfFlagOfOperation() Export
	Return "CalculationOfNonCurrentAssetsCost";
EndFunction

// The name of the sign of the operation of operation updating the Registered Records of the VNA.
// 
// Returns:
//  String -  The Name Of The Flag of Operation
Function NameOfSignOfOperationOfOperationUpdatingRegisteredRecordsFA() Export
	Return "ActualizationOfFARegisteredRecords";
EndFunction

Function TypesOfDocumentsForWhichCostIsCalculated(CheckForRights = False) Export

	TypesList = New Array;
	
	NonCurrentAssetsInternal.AddMetadataObjectType(
		Metadata.Documents.FixedAssetsCostAdditions2_4.Name, CheckForRights, TypesList);
	
	NonCurrentAssetsInternal.AddMetadataObjectType(
		Metadata.Documents.AllocateVariancesToFixedAssetCost.Name, CheckForRights, TypesList);
	
	NonCurrentAssetsInternal.AddMetadataObjectType(
		Metadata.Documents.IntangibleAssetsInitialRecognition2_4.Name, CheckForRights, TypesList);
	
	NonCurrentAssetsInternal.AddMetadataObjectType(
		Metadata.Documents.FixedAssetsInitialRecognition2_4.Name, CheckForRights, TypesList);
	
	NonCurrentAssetsInternal.AddMetadataObjectType(
		Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.Name, CheckForRights, TypesList);
	
	NonCurrentAssetsInternal.AddMetadataObjectType(
		Metadata.Documents.IntangibleAssetImprovement.Name, CheckForRights, TypesList);
	
	Return TypesList;

EndFunction

Function BusinessOperationsForWhichCostIsCalculated() Export

	Operations = New Array;
	Operations.Add(Enums.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost);
	Operations.Add(Enums.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost);
	Operations.Add(Enums.BusinessTransactions.FixedAssetsCostAdditions);
	Operations.Add(Enums.BusinessTransactions.AllocateVariancesToFixedAssetCost);
	Operations.Add(Enums.BusinessTransactions.IntangibleAssetsInitialRecognition);
	Operations.Add(Enums.BusinessTransactions.FixedAssetsInitialRecognition);
	Operations.Add(Enums.BusinessTransactions.RecognitionOfLeaseItems);
	Operations.Add(Enums.BusinessTransactions.RecognizeSubAssetsComponentsOfDepreciation);
	Operations.Add(Enums.BusinessTransactions.IntangibleAssetImprovement);
	
	Return Operations;

EndFunction

Procedure CalculateExpensesByActualCost(CalculationOfExpenses, DocumentData, ObjectsTable, ExpensesTable)
	
	// It is necessary to distribute the actual cost of each object in proportion to the amount of expenses.
	//
	// For example, in the document: COSTU=1000, COSTU=1000
	// Expenses: Article 1: SUMAUPR=500, Sumareg=5000;
	//          Article 2: SummaUpr=1500, SummaRegl=15000;
	// Calculation: Cost per Article 1=1000*500/2000 =250
	//                     per Article 2=1000*1500/2000=750
	//         The cost per Article 1=1000*5000/2000 =2500
	//                     per Article 2=1000*15000/2000=7500.
	
	ExpenseInformation = New Map;
	For Each LineExpenses In ExpensesTable Do
		
		DataByAnalytics = ExpenseInformation.Get(DocumentData.ExpensesCapitalizationDimension);
		If DataByAnalytics = Undefined Then
			DataByAnalytics = New Structure;
			
			DataByAnalytics.Insert("ExpensesForAccountingObject", ExpensesTable.CopyColumns());

			DataByAnalytics.Insert("ArrayOfCoefficientsSum", New Array);
			DataByAnalytics.Insert("ArrayOfCoefficientsAmountWithoutVAT", New Array);
			DataByAnalytics.Insert("ArrayOfCoefficientsSumOfMan", New Array);
			DataByAnalytics.Insert("ArrayOfCoefficientsSumOfLocalCoefficients", New Array);
			
			DataByAnalytics.Insert("SumBalance", 0);
			DataByAnalytics.Insert("AmountExcludingVATBalance", 0);
			DataByAnalytics.Insert("SumManBalance", 0);
			DataByAnalytics.Insert("SumComplBalance", 0);
		EndIf;
		
		ExpensesForAccountingObject = DataByAnalytics.ExpensesForAccountingObject.Add();
		FillPropertyValues(ExpensesForAccountingObject, LineExpenses);
		
		DataByAnalytics.ArrayOfCoefficientsSum.Add(LineExpenses.Sum);
		DataByAnalytics.ArrayOfCoefficientsAmountWithoutVAT.Add(LineExpenses.AmountExcludingVAT);
		DataByAnalytics.ArrayOfCoefficientsSumOfMan.Add(LineExpenses.SumMan);
		DataByAnalytics.ArrayOfCoefficientsSumOfLocalCoefficients.Add(LineExpenses.SumCompl);
		
		DataByAnalytics.SumBalance = DataByAnalytics.SumBalance + LineExpenses.Sum;
		DataByAnalytics.AmountExcludingVATBalance = DataByAnalytics.AmountExcludingVATBalance + LineExpenses.AmountExcludingVAT;
		DataByAnalytics.SumManBalance = DataByAnalytics.SumManBalance + LineExpenses.SumMan;
		DataByAnalytics.SumComplBalance = DataByAnalytics.SumComplBalance + LineExpenses.SumCompl;
		
		ExpenseInformation.Insert(DocumentData.ExpensesCapitalizationDimension, DataByAnalytics);
		
	EndDo;
	
	For Each ObjectData In ObjectsTable Do
		
		DataByAnalytics = ExpenseInformation.Get(ObjectData.ExpensesCapitalizationDimension);
		
		If DataByAnalytics = Undefined Then
			Continue;
		EndIf;
		
		If ObjectData.RecordInManAccounting Then

			DistributionAmount = GetCostDistribution(
									ObjectData.AmountOfUU,
									DataByAnalytics.SumBalance,
									DataByAnalytics.ArrayOfCoefficientsSum);
			
			DistributionAmountWithoutVAT = GetCostDistribution(
									ObjectData.AmountOfUU,
									DataByAnalytics.AmountExcludingVATBalance,
									DataByAnalytics.ArrayOfCoefficientsAmountWithoutVAT);
									
			DistributionAmountOfMan = GetCostDistribution(
									ObjectData.AmountOfUU,
									DataByAnalytics.SumManBalance,
									DataByAnalytics.ArrayOfCoefficientsSumOfMan);
									
		Else
			DistributionAmount = Undefined;
			DistributionAmountWithoutVAT = Undefined;
			DistributionAmountOfMan = Undefined;
		EndIf;
		
		If ObjectData.RecordInLocalAccounting Then
			
			DistributionSumOfLocal = GetCostDistribution(
									ObjectData.AmountAccounting,
									DataByAnalytics.SumComplBalance,
									DataByAnalytics.ArrayOfCoefficientsSumOfLocalCoefficients);
			
		Else
			DistributionSumOfLocal = Undefined;
		EndIf;
		
		For Cnt = 0 To DataByAnalytics.ExpensesForAccountingObject.Count()-1 Do
			
			ExpensesForAccountingObject = DataByAnalytics.ExpensesForAccountingObject[Cnt];
			
			NewRow = CalculationOfExpenses.Add();
			FillPropertyValues(NewRow, ExpensesForAccountingObject);

			NewRow.Ref = ObjectData.Ref;
			NewRow.AccountingObject = ObjectData.AccountingObject;
			
			NewRow.Sum = ?(DistributionAmount <> Undefined, DistributionAmount[Cnt], 0);
			NewRow.AmountExcludingVAT = ?(DistributionAmountWithoutVAT <> Undefined, DistributionAmountWithoutVAT[Cnt], 0);
			NewRow.SumMan = ?(DistributionAmountOfMan <> Undefined, DistributionAmountOfMan[Cnt], 0);
			NewRow.SumCompl = ?(DistributionSumOfLocal <> Undefined, DistributionSumOfLocal[Cnt], 0);
			
			// PR and BP are calculated based on the received share of the sum of the
			If DistributionSumOfLocal <> Undefined Then
				If DistributionSumOfLocal[Cnt] <> ExpensesForAccountingObject.SumCompl Then
					
					NewRow.PermanentDifference = 
						Round(ExpensesForAccountingObject.PermanentDifference 
							* DistributionSumOfLocal[Cnt] 
							/ ExpensesForAccountingObject.SumCompl, 2);
					
					NewRow.CostTD = 
						Round(ExpensesForAccountingObject.CostTD 
							* DistributionSumOfLocal[Cnt] 
							/ ExpensesForAccountingObject.SumCompl, 2);
					
					NewRow.AITAmount = 
						Round(ExpensesForAccountingObject.AITAmount 
							* DistributionSumOfLocal[Cnt] 
							/ ExpensesForAccountingObject.SumCompl, 2);
					
				EndIf;
			Else
				NewRow.PermanentDifference = 0;
				NewRow.CostTD  = 0;
			EndIf;

			TakeIntoAccountReflectionInAccountingWhenCalculatingCost(NewRow, ObjectData);

			// Reducing costs
			ExpensesForAccountingObject.Sum = ExpensesForAccountingObject.Sum - NewRow.Sum;
			ExpensesForAccountingObject.AmountExcludingVAT = ExpensesForAccountingObject.AmountExcludingVAT - NewRow.AmountExcludingVAT;
			ExpensesForAccountingObject.SumMan = ExpensesForAccountingObject.SumMan - NewRow.SumMan;
			ExpensesForAccountingObject.SumCompl = ExpensesForAccountingObject.SumCompl - NewRow.SumCompl;
			ExpensesForAccountingObject.PermanentDifference = ExpensesForAccountingObject.PermanentDifference - NewRow.PermanentDifference;
			ExpensesForAccountingObject.CostTD = ExpensesForAccountingObject.CostTD - NewRow.CostTD;
			ExpensesForAccountingObject.AITAmount = ExpensesForAccountingObject.AITAmount - NewRow.AITAmount;

			DataByAnalytics.ArrayOfCoefficientsSum[Cnt] = DataByAnalytics.ArrayOfCoefficientsSum[Cnt] - NewRow.Sum;
			DataByAnalytics.ArrayOfCoefficientsAmountWithoutVAT[Cnt] = DataByAnalytics.ArrayOfCoefficientsAmountWithoutVAT[Cnt] - NewRow.AmountExcludingVAT;
			DataByAnalytics.ArrayOfCoefficientsSumOfMan[Cnt] = DataByAnalytics.ArrayOfCoefficientsSumOfMan[Cnt] - NewRow.SumMan;
			DataByAnalytics.ArrayOfCoefficientsSumOfLocalCoefficients[Cnt] = DataByAnalytics.ArrayOfCoefficientsSumOfLocalCoefficients[Cnt] - NewRow.SumCompl;

			DataByAnalytics.SumBalance = DataByAnalytics.SumBalance - NewRow.Sum;
			DataByAnalytics.AmountExcludingVATBalance = DataByAnalytics.AmountExcludingVATBalance - NewRow.AmountExcludingVAT;
			DataByAnalytics.SumManBalance = DataByAnalytics.SumManBalance - NewRow.SumMan;
			DataByAnalytics.SumComplBalance = DataByAnalytics.SumComplBalance - NewRow.SumCompl;
			 
		EndDo; 
		
	EndDo; 
	
EndProcedure

Procedure CalculateExpensesForObjects(CalculationOfExpenses, ObjectsByCapitalizationAnalytics, CapitalizationAnalyticsExpenses)
	
	For Each ExpenseLine_ In CapitalizationAnalyticsExpenses Do
		
		For Each DocumentLine In ObjectsByCapitalizationAnalytics Do
			
			NewRow = CalculationOfExpenses.Add();
			FillPropertyValues(NewRow, ExpenseLine_);
			
			NewRow.Ref = DocumentLine.Ref;
			NewRow.AccountingObject = DocumentLine.AccountingObject;
			
			TakeIntoAccountReflectionInAccountingWhenCalculatingCost(NewRow, DocumentLine);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure DistributeExpensesByObjects(CalculationOfExpenses, ObjectsByCapitalizationAnalytics, CapitalizationAnalyticsExpenses)

	ArrayOfCoefficientsSumOfMA = CreateArrayOfCoefficients(ObjectsByCapitalizationAnalytics, "AmountOfUU", "RecordInManAccounting");
	ArrayOfCoefficientsSumOfAC = CreateArrayOfCoefficients(ObjectsByCapitalizationAnalytics, "AmountAccounting", "PostInAccounting");
	ArrayOfCoefficientsSumTa = CreateArrayOfCoefficients(ObjectsByCapitalizationAnalytics, "AmountAccounting", "RecordInTA");
	ArrayOfCoefficientsSumOfPD = CreateArrayOfCoefficients(ObjectsByCapitalizationAnalytics, "AmountAccounting", "TakeIntoAccountPD");
	ArrayOfCoefficientsAmountAIT = CreateArrayOfCoefficients(ObjectsByCapitalizationAnalytics, "AmountAccounting", "RecordInTA");
	
	For Each ExpenseLine_ In CapitalizationAnalyticsExpenses Do
		
		DistributionAmount = TMCommonUseClientServer.DistributeProportionally(
										ExpenseLine_.Sum,  ArrayOfCoefficientsSumOfMA);
										
		DistributionAmountWithoutVAT = TMCommonUseClientServer.DistributeProportionally(
										ExpenseLine_.AmountExcludingVAT,  ArrayOfCoefficientsSumOfMA);
										
		DistributionAmountOfMan = TMCommonUseClientServer.DistributeProportionally(
										ExpenseLine_.SumMan,  ArrayOfCoefficientsSumOfMA);
		
		DistributionSumOfLocal = TMCommonUseClientServer.DistributeProportionally(
										ExpenseLine_.SumCompl, ArrayOfCoefficientsSumOfAC);
										
		DistributionSumTA = TMCommonUseClientServer.DistributeProportionally(
										ExpenseLine_.AmountFA, ArrayOfCoefficientsSumTa);
										
		DistributionAmountOfPD = TMCommonUseClientServer.DistributeProportionally(
										ExpenseLine_.PermanentDifference, ArrayOfCoefficientsSumOfPD);
										
		DistributionAITAmount = TMCommonUseClientServer.DistributeProportionally(
										ExpenseLine_.AITAmount, ArrayOfCoefficientsAmountAIT);
										
		For Cnt = 0 To ObjectsByCapitalizationAnalytics.Count()-1 Do
			
			DocumentLine = ObjectsByCapitalizationAnalytics[Cnt];
			
			NewRow = CalculationOfExpenses.Add();
			FillPropertyValues(NewRow, ExpenseLine_);
			
			NewRow.Ref = DocumentLine.Ref;
			NewRow.AccountingObject = DocumentLine.AccountingObject;
		
			If DocumentLine.RecordInManAccounting Then
				NewRow.Sum       = ?(DistributionAmount       <> Undefined, DistributionAmount[Cnt],    0);
				NewRow.AmountExcludingVAT = ?(DistributionAmountWithoutVAT <> Undefined, DistributionAmount[Cnt],    0);
				NewRow.SumMan    = ?(DistributionAmountOfMan    <> Undefined, DistributionAmountOfMan[Cnt], 0);
			Else
				NewRow.Sum       = 0;
				NewRow.AmountExcludingVAT = 0;
				NewRow.SumMan    = 0;
			EndIf;
			
			If DocumentLine.PostInAccounting Then
				NewRow.SumCompl         = ?(DistributionSumOfLocal <> Undefined, DistributionSumOfLocal[Cnt], 0);
				NewRow.PermanentDifference = ?(DistributionAmountOfPD   <> Undefined, DistributionAmountOfPD[Cnt],   0);
			Else
				NewRow.SumCompl         = 0;
				NewRow.PermanentDifference = 0;
			EndIf; 
			
			If DocumentLine.RecordInTA Then
				AmountFA = ?(DistributionSumTA <> Undefined, DistributionSumTA[Cnt], 0);
			Else
				AmountFA = 0;
			EndIf;
		
			NewRow.CostTD = NewRow.SumCompl - AmountFA - NewRow.PermanentDifference;
			
			If DocumentLine.RecordInTA Then
				NewRow.AITAmount = ?(DistributionAITAmount <> Undefined, DistributionAITAmount[Cnt], 0);
			Else
				NewRow.AITAmount = 0;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure GenerateCostTTCalculation(TempTablesManager)
	
	QueryText =
	"SELECT
	|	CurExpenses.Ref                    AS Ref,
	|	CurExpenses.Organization               AS Organization,
	|	CurExpenses.RowID       AS RowID,
	|	CurExpenses.IdOfACLine     AS IdOfACLine,
	|	CurExpenses.RowIDTA     AS RowIDTA,
	|	CurExpenses.IdOfTFLine     AS IdOfTFLine,
	|	CurExpenses.AccountingObject               AS AccountingObject,
	|	CurExpenses.ExpenseItem            AS ExpenseItem,
	|	CurExpenses.DimensionOfExpenses         AS DimensionOfExpenses,
	|	CurExpenses.Department             AS Department,
	|	CurExpenses.LineOfBusiness   AS LineOfBusiness,
	|	CurExpenses.VariancePeriod          AS VariancePeriod,
	|
	|	CurExpenses.Sum                     AS Sum,
	|	CurExpenses.AmountExcludingVAT               AS AmountExcludingVAT,
	|	CurExpenses.SumMan                  AS AmountOfUU,
	|
	// AmountAccounting
	|	CASE
	|		WHEN TTTableOfObjects.TargetFinancingApplicationOption = &FullTF
	|				AND &ComplianceCAAccountingIsKept
	|			THEN 0
	|		ELSE CurExpenses.SumCompl - CurExpenses.CFAmount
	|	END AS AmountAccounting,
	|
	// AmountFA
	|	CASE
	|		WHEN NOT ISNULL(TTAccountingPolicy.IncomeTaxPayer, FALSE)
	|				OR TTTableOfObjects.TargetFinancingApplicationOption = &FullTF
	|					AND &ComplianceCAAccountingIsKept
	|			THEN 0
	|		ELSE CurExpenses.AmountFA - CurExpenses.SumOfNUCF 
	|	END AS AmountFA,
	|
	// AmountPermanentDifferences
	|	CASE
	|		WHEN NOT ISNULL(TTAccountingPolicy.IncomeTaxPayer, FALSE)
	|				OR TTTableOfObjects.TargetFinancingApplicationOption = &FullTF
	|					AND &ComplianceCAAccountingIsKept
	|			THEN 0
	|		ELSE CurExpenses.PermanentDifference - CurExpenses.PRCFAmount
	|	END AS AmountPermanentDifferences,
	|
	// CFAmount
	|	CASE 
	|		WHEN TTTableOfObjects.TargetFinancingApplicationOption = &FullTF
	|				AND &ComplianceCAAccountingIsKept
	|
	|			THEN CurExpenses.SumCompl
	|
	|		WHEN TTTableOfObjects.TargetFinancingApplicationOption = &PartialTF
	|				AND &ComplianceCAAccountingIsKept
	|
	|			THEN CurExpenses.CFAmount
	|
	|		ELSE 0
	|	END AS CFAmount,
	|
	// SumOfNUCF
	|	CASE 
	|		WHEN TTTableOfObjects.TargetFinancingApplicationOption = &FullTF
	|				AND &ComplianceCAAccountingIsKept
	|
	|			THEN CurExpenses.AmountFA
	|
	|		WHEN TTTableOfObjects.TargetFinancingApplicationOption = &PartialTF
	|				AND &ComplianceCAAccountingIsKept
	|
	|			THEN CurExpenses.SumOfNUCF 
	|
	|		ELSE 0
	|	END AS SumOfNUCF,
	|
	// PRCFAmount
	|	CASE 
	|		WHEN TTTableOfObjects.TargetFinancingApplicationOption = &FullTF
	|				AND &ComplianceCAAccountingIsKept
	|
	|			THEN CurExpenses.PermanentDifference
	|
	|		WHEN TTTableOfObjects.TargetFinancingApplicationOption = &PartialTF
	|				AND &ComplianceCAAccountingIsKept
	|
	|			THEN CurExpenses.PRCFAmount 
	|
	|		ELSE 0
	|	END AS PRCFAmount,
	|
	|	CurExpenses.DisregardedCostTA AS DisregardedCostTA,
	|	CurExpenses.AITAmount AS AITAmount
	|
	|INTO TTCostCalculation
	|
	|FROM
	|	TTCurExpenses AS CurExpenses
	|
	|		INNER JOIN TTTableOfObjects AS TTTableOfObjects
	|		ON TTTableOfObjects.Ref = CurExpenses.Ref
	|			AND TTTableOfObjects.AccountingObject = CurExpenses.AccountingObject
	|
	|		LEFT JOIN TTAccountingPolicy AS TTAccountingPolicy
	|		ON TTAccountingPolicy.Organization = CurExpenses.Organization
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CostCalculation.Ref                AS Ref,
	|	CostCalculation.AccountingObject           AS AccountingObject,
	|
	|	SUM(CostCalculation.AmountOfUU)        AS AmountOfUU,
	|	SUM(CostCalculation.AmountAccounting)        AS AmountAccounting,
	|	SUM(CostCalculation.AmountFA)        AS AmountFA,
	|	SUM(CostCalculation.AmountPermanentDifferences)        AS AmountPermanentDifferences,
	|	SUM(CostCalculation.CFAmount)        AS CFAmount,
	|	SUM(CostCalculation.SumOfNUCF)      AS SumOfNUCF,
	|	SUM(CostCalculation.PRCFAmount)      AS PRCFAmount
	|
	|INTO TTCostCalculationGrouped
	| 
	|FROM
	|	TTCostCalculation AS CostCalculation
	|
	|GROUP BY
	|	CostCalculation.Ref,
	|	CostCalculation.AccountingObject
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|";

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("FullTF", Undefined);
	Query.SetParameter("PartialTF", Undefined);
	Query.SetParameter("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	
	Query.Execute();
	
EndProcedure

Function GetCostDistribution(Cost, SumBalance, ArrayOfCoefficientsSum)
	
	If Cost < SumBalance Then
		DistributionAmount = TMCommonUseClientServer.DistributeProportionally(
									Cost, 
									ArrayOfCoefficientsSum);
	Else
		DistributionAmount = ArrayOfCoefficientsSum;
	EndIf;
	
	Return DistributionAmount;
	
EndFunction

Procedure TakeIntoAccountReflectionInAccountingWhenCalculatingCost(RowData, DocumentLine)

	If Not DocumentLine.RecordInManAccounting Then
		RowData.Sum = 0;
		RowData.AmountExcludingVAT = 0;
		RowData.SumMan = 0;
	EndIf;
	
	If Not DocumentLine.RecordInLocalAccounting Then
		RowData.SumCompl = 0;
	EndIf;
	
	FACostCalculationLocalization.TakeIntoAccountReflectionInAccountingWhenCalculatingCost(RowData, DocumentLine);
	
EndProcedure

Function CreateArrayOfCoefficients(ObjectsByCapitalizationAnalytics, ColumnNameCoefficient, ColumnNameReflectedInAccounting)

	CoefficientsSum = 0;
	ArrayOfCoefficients = New Array;
	
	For Each DocumentLine In ObjectsByCapitalizationAnalytics Do
		
		If DocumentLine[ColumnNameReflectedInAccounting] Then
			ArrayOfCoefficients.Add(DocumentLine[ColumnNameCoefficient]);
			CoefficientsSum = CoefficientsSum + DocumentLine[ColumnNameCoefficient];
		Else
			ArrayOfCoefficients.Add(0);
		EndIf;
		
	EndDo;
	
	If CoefficientsSum = 0 Then
		For Cnt = 0 To ArrayOfCoefficients.UBound() Do
			DocumentLine = ObjectsByCapitalizationAnalytics[Cnt];
			If DocumentLine[ColumnNameReflectedInAccounting] Then
				ArrayOfCoefficients[Cnt] = 1;
			Else
				ArrayOfCoefficients[Cnt] = 0;
			EndIf;
		EndDo;
	EndIf;
	
	Return ArrayOfCoefficients;
	
EndFunction

Function MaximumNumberOfTasks()

	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost);
							
	MaximumNumberOfTasks = ParameterValues.MaximumNumberOfTasks; // Number
	
	Return MaximumNumberOfTasks;

EndFunction

Function DataChunkSize()
	
	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.CalculationOfNonCurrentAssetsCost);
  							
	DataChunkSize = ParameterValues.DataChunkSize; // Number
	 		
	Return DataChunkSize;
	
EndFunction

Procedure DetermineChangeInOtherExpenses(TablesData)
	
	If TablesData.TempTablesManager.Tables.Find("ChangesTableOtherExpenses") = Undefined Then
		Return;	
	EndIf;
		
	QueryText =
	"SELECT DISTINCT
	|	Table.Period AS Period,
	|	Table.Organization AS Organization,
	|	Table.DimensionOfExpenses AS AccountingObject,
	|	Table.Recorder AS Document
	|
	|INTO OtherExpenses_TasksForCalculatingCostOfHPAUpdate
	|
	|FROM
	|	ChangesTableOtherExpenses AS Table
	|
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = Table.ExpenseItem
	|
	|WHERE
	|	(Table.DimensionOfExpenses REFS Catalog.Assets
	|			AND Table.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)
	|		OR Table.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|			AND Table.DimensionOfExpenses <> VALUE(Catalog.ConstructionObjects.EmptyRef)
	|		OR Table.DimensionOfExpenses REFS Catalog.IntangibleAssets
	|			AND Table.DimensionOfExpenses <> VALUE(Catalog.IntangibleAssets.EmptyRef))
	|
	|	AND ExpenseItems.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|
	|	AND (ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|	AND (Table.Sum <> 0
	|		OR Table.AmountExcludingVAT <> 0
	|		OR Table.SumCompl <> 0
	|		OR Table.PermanentDifference <> 0
	|		OR Table.CostTD <> 0)
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TablesData.TempTablesManager;
		
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	TablesData.Insert("OtherExpenses_TasksForCalculatingCostOfHPAUpdate", Selection.Count > 0);
	
EndProcedure


Function TypesOfDocumentsToMoveToBeginningOfMonth()
	
	ObjectsTypes = New Array;
	
	FACostCalculationLocalization.AddTypesOfDocumentsToMoveToBeginningOfMonth(ObjectsTypes);
	
	Return ObjectsTypes;
	
EndFunction

#EndRegion

#EndRegion
