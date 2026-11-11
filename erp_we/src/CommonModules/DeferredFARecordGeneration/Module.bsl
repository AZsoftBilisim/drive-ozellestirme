////////////////////////////////////////////////////////////////////////////////
// Procedures of the mechanism of deferred formation of RegisteredRecords on documents of non-current assets.
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
		Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords,,,,
		Catalogs.MonthEndClosingOperations.AccrualOfLeaseInterest);
		
	NewRow.MultilingualName = "vi = 'Lập các luân chuyển trong TSCĐ hữu hình và TSCĐ vô hình';
								|ru = 'Формирование движений по ОС и НМА';
								|en = 'Generate fixed asset and intangible asset records';
								|it = 'Generazione dei movimenti relativi al capitale fisso e attività immateriali';
								|pl = 'Formowanie ruchu dla ŚT oraz WNM';
								|tr = 'SV ve GMA doğrultusunda hareketlerin düzenlenmesi'"; // @NStr-1
	
	NewRow.PreviousStages_.Add(NonCurrentAssetsLocalization.OperationOfSwitchingToFixedAndIntangibleAssets2_4());
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.AccrualOfLeaseInterest);
	
	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Perform'; fa = 'اجرا';
								|it = 'Perform';
								|pl = 'Perform';
								|tr = 'Uygula'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"DeferredFARecordGeneration.DetermineStatusOfOperationClosingMonth");
		
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"DeferredFARecordGeneration.PerformMonthClosingOfOperation");

EndProcedure

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_UpdatingFARecordsBeforeCalculatingDepreciation(StepsTable,CurrentParent) Export

	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.UpdatingFARecordsBeforeCalculatingDepreciation);
	
	NewRow.MultilingualName = "vi = 'Cập nhật các bản ghi kết chuyển về TSCĐ và TSCĐVH';
								|ru = 'Актуализация движений по ОС и НМА';
								|en = 'Updating records of fixed assets and intangible assets';
								|it = 'Updating records of fixed assets and intangible assets';
								|pl = 'Updating records of fixed assets and intangible assets';
								|tr = 'SV ve GMA doğrultusunda hareketlerin gerçekleştirilmesi'"; // @NStr-1
	
	NewRow.PreviousStages_.Add(NonCurrentAssetsLocalization.OperationOfSwitchingToFixedAndIntangibleAssets2_4());
	
	NewRow.TextExecute = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Выполнить';
								|pl = 'Run';
								|tr = 'Gerçekleştir'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"DeferredFARecordGeneration.ToDetermineStatusOfOperationFormationOfRegisteredRecordedHPABeforeCalculatingDepreciation");
		
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"DeferredFARecordGeneration.PerformMonthClosingOfOperation");

EndProcedure

// Determines the Status of operations of the closing of the month "Formation of movement", "Formation of movement", Transfer of amortization".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure DetermineStatusOfOperationClosingMonth(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(CalculationParameters.Period) Then
		
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
	
	If NonCurrentAssets.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords.Name) Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not ThereAreDocumentsAccordingToWhichRegisteredRecordsAreFormed(HandlerParameters) Then
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có chứng từ mà theo đó cần lập bản ghi kết chuyển.';
				|ru = 'Нет документов по которым требуется сформировать движения.';
				|en = 'No documents that require record generation.'; fa = 'No documents that require record generation.';
				|it = 'Non ci sono documenti per i quali è necessario creare dei movimenti.';
				|pl = 'Brak dokumentów, z tytułu których jest wymagane tworzenie ruchu.';
				|tr = 'Hareket oluşturulması gereken herhangi bir belge bulunmamaktadır.'", Common.DefaultLanguageCode()));
	EndIf; 
	
EndProcedure

// Determines the Status of operations of the closing of the month "Formation of movement", "Formation of movement", Transfer of amortization".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure ToDetermineStatusOfOperationFormationOfRegisteredRecordedHPABeforeCalculatingDepreciation(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(CalculationParameters.Period) Then
		
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
	
	Result = UpdatingOfRegisteredRecordsIsRequiredBeforeCalculatingDepreciation(HandlerParameters);
	
	If Result.UpdatingOfRegisteredRecordsIsRequired Then
		Return;
	EndIf;
	
	// The Operation is completed if the depreciation calculation is displayed as completed and there are documents on which Registered Records are generated.
	If Not Result.ThereAreTasksForFADepreciationCalculation 
		And Not Result.ThereAreTasksForTasksForCalculatingDepreciationOfIA Then
		
		NumberOfFADocuments = MonthEndTransactionsServer.NumberOfRegulatoryDocumentsOfClosingStageOfMonth(
			HandlerParameters, Metadata.Documents.FixedAssetsDepreciationCharge2_4.Name);
	
		NumberOfIADocuments = MonthEndTransactionsServer.NumberOfRegulatoryDocumentsOfClosingStageOfMonth(
			HandlerParameters, Metadata.Documents.IntangibleAssetsAmortizationCharge2_4.Name);

		If (NumberOfFADocuments <> 0 Or NumberOfIADocuments <> 0) 
			And ThereAreDocumentsAccordingToWhichRegisteredRecordsAreFormed(HandlerParameters) Then
			
			Return;
		EndIf;
		
	EndIf;
	
	MonthEndTransactionsServer.NoNeedToSetState(
		HandlerParameters,
		NStr("vi = 'Không yêu cầu thực hiện thao tác';
			|ru = 'Выполнение операции не требуется.';
			|en = 'Operation is not required.'; fa = 'Operation is not required.';
			|it = 'Operation is not required.';
			|pl = 'Operation is not required.';
			|tr = 'İşlemin uygulanması gerekmiyor.'", Common.DefaultLanguageCode()));
			
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
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.DelayedFormationOfRegisteredRecordsAlongVNA");
	
	NumberBeforeSettlement = InformationRegisters.JobsForGeneratingFixedAssetRecords.IncreaseTaskNumber();
	
	AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(
		CalculationParameters.Period, CalculationParameters.CompanyArray);
	
	JobsForCalculating = InformationRegisters.JobsForGeneratingFixedAssetRecords.JobsForCalculating(
			'000101010000', EndOfMonth(CalculationParameters.Period), NumberBeforeSettlement, AvailableCompanies);
	
	Result = ExecuteOperation(
		JobsForCalculating.BeginOfPeriod, 
		EndOfMonth(CalculationParameters.Period), 
		JobsForCalculating.CompaniesList,
		NumberBeforeSettlement,
		JobsForCalculating.TempTablesManager,
		HandlerParameters.CalculationID,
		HandlerParameters.Data_Stage.Code);
		
	If Result.HasErrors Then
		
		For Each Organization In JobsForCalculating.CompaniesList Do
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				HandlerParameters.Data_Stage.Code, 
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
	ParameterDetails.Description = NStr("vi = 'Số lượng các nhiệm vụ được thực hiện cùng lúc khi tạo bản ghi kết chuyển theo TSCĐ hữu hình và TSCĐ vô hình';
										|ru = 'Количество одновременно выполняемых заданий формирования движений по ОС и НМА';
										|en = 'Number of simultaneous jobs for generating records of FA and IA'; fa = 'Number of simultaneous jobs for generating records of FA and IA';
										|it = 'Количество одновременно выполняемых заданий формирования движений по ОС и НМА';
										|pl = 'Number of simultaneous jobs for generating records of FA and IA';
										|tr = 'Maddi olmayan varlıklar ve sabit kıymetler kapsamında hareketlerin oluşturulması için eş zamanlı olarak gerçekleştirilen görevlerin sayısı'");
	ParameterDetails.ValueType = New TypeDescription("Number",,, New NumberQualifiers(2, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith = 1;
	ParameterDetails.DefaultValue = 4;
	ParameterDetails.LongDesc =
		NStr("vi = 'Việc tạo các bản ghi kết chuyển theo TSCĐ hữu hình và TSCĐ vô hình có thể được thực hiện bằng một số nhiệm vụ nền.
              |Việc tăng số lượng nhiệm vụ có thể làm giảm thời gian thực hiện hoạt động.
              |Nên thiết lập số lượng nhiệm vụ phụ thuộc vào cấu hình server của hệ thống quản trị CSDL và server 1C:Enterprise.';
              |ru = 'Формирование движений по ОС и НМА может выполняться одновременно несколькими фоновыми заданиями.
              |Увеличение количества заданий может уменьшить время выполнения операции.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'Records of fixed assets and intangible assets can be generated simultaneously by several background jobs.
              |Increasing the number of jobs can reduce the operation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'Records of fixed assets and intangible assets can be generated simultaneously by several background jobs.
              |Increasing the number of jobs can reduce the operation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'Формирование движений по ОС и НМА может выполняться одновременно несколькими фоновыми заданиями.
              |Увеличение количества заданий может уменьшить время выполнения операции.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'Records of fixed assets and intangible assets can be generated simultaneously by several background jobs.
              |Increasing the number of jobs can reduce the operation execution time.
              |Configure the number of jobs depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'Sabit kıymetler ve maddi olmayan varlıklar kapsamında hareketlerin oluşturulması birden fazla arka plan işi tarafından eş zamanlı olarak gerçekleştirilebilir.
              |Görev sayısının artırılması işlem yürütme süresini azaltabilir.
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
		NStr("vi = 'Trong một nhiệm vụ, việc tạo các bản ghi kết chuyển có thể được thực hiện cùng lúc theo một số chứng từ.
              |Việc tăng số lượng chứng từ có thể giảm thời gian thực hiện hoạt động, nhưng tăng yêu cầu về bộ nhớ.
              |Nên thiết lập số lượng nhiệm vụ phụ thuộc vào cấu hình server trong hệ quản trị CSDL và server 1C:Enterprise.';
              |ru = 'В одном задании формирование движений может выполняться одновременно по нескольким документам.
              |Увеличение количества документов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'In one job, records can be generated simultaneously by several documents.
              |Increasing the number of documents can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'In one job, records can be generated simultaneously by several documents.
              |Increasing the number of documents can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'В одном задании формирование движений может выполняться одновременно по нескольким документам.
              |Увеличение количества документов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'In one job, records can be generated simultaneously by several documents.
              |Increasing the number of documents can reduce the operation execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'Bir görevde, hareketlerin oluşturulması birden fazla belge üzerinde eş zamanlı olarak gerçekleştirilebilir.
              |Belge sayısının artırılması işlem yürütme süresini azaltabilir, ancak bellek tüketimini artırabilir.
              |Veritabanı yönetim sistemi sunucusunun ve 1C:Enterprise sunucularının konfigürasyonuna bağlı olarak sayısın yapılandırılması önerilmektedir.'");
		
	#EndRegion
	
	Return ParametersDetails;
	
EndFunction

#EndRegion

#Region PerformingTransaction

// Generates deferred RegisteredRecords in several streams.
// 
// Parameters:
//  BeginOfPeriod - Date - The period from which the Operation is required to be performed
//  EndOfPeriod - Date - The period for which the operation is required to be performed of operation
//  CompaniesList - Array of CatalogRef.Companies - List of organizations
//  NumberBeforeSettlement - Number - Task number
//  TempTablesManager - TempTablesManager - Contains a list of objects
//  CalculationID - UUID - calculation ID
//  MonthClosingOperation - CatalogRef.MonthEndClosingOperations - Operation
// 
// Returns:
//  Structure - the result of Registering Recorded movements:
// 		* HasErrors - Boolean - True if errors were registered during execution
// 		* ErrorText - String - error text
// 		* DataVolume - Number - The number of objects for which Registered Records have been generated
//
Function ExecuteOperation(BeginOfPeriod, EndOfPeriod, CompaniesList, NumberBeforeSettlement, TempTablesManager, CalculationID, MonthClosingOperation = Undefined) Export

	Result = New Structure;
	Result.Insert("HasErrors", False);
	Result.Insert("ErrorText", "");
	Result.Insert("DataVolume", 0);

	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(EndOfPeriod) Then
		Return Result;
	EndIf; 
	
	If Not ValueIsFilled(MonthClosingOperation) Then
		MonthClosingOperation = Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords;
	EndIf;
	
	If MonthClosingOperation = Catalogs.MonthEndClosingOperations.UpdatingRecordsOfFixedAssetsAndIntangibleAssets Then
		TaskRegisterName = Metadata.InformationRegisters.JobsForUpdatingFixedAssetRecords.Name;
		DeleteTasks = False;
	ElsIf MonthClosingOperation = Catalogs.MonthEndClosingOperations.UpdatingFARecordsBeforeCalculatingDepreciation Then
		TaskRegisterName = Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords.Name;
		DeleteTasks = True;
	Else
		TaskRegisterName = Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords.Name;
		DeleteTasks = True;
	EndIf;
	
	TaskQueue = CreateTaskQueue(
		BeginOfPeriod, EndOfPeriod, CompaniesList, NumberBeforeSettlement, TempTablesManager, MonthClosingOperation, DeleteTasks);

	If TaskQueue.Count() = 0 Then
		
		If DeleteTasks Then
			
			InformationRegisters[TaskRegisterName].FixCalculation(
				EndOfPeriod,
				CompaniesList, 
				NumberBeforeSettlement,
				TempTablesManager,
				"JobsForCalculating");
			
		EndIf;

		Return Result;
		
	EndIf;

	ExecutionResult = NonCurrentAssets.ExecuteTaskQueue(TaskQueue, MaximumNumberOfTasks(), CalculationID);
	
	Result.HasErrors = ExecutionResult.HasErrors;
	Result.ErrorText = ExecutionResult.ErrorText;
	Result.DataVolume = ExecutionResult.DataVolume;
	
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

	If ExecutionParameters.ListOfObjects.Count() = 0 Then
		Return 0;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.PerformOfOperationOnObjects");
	
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
		NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic(), 
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

		BeginOfPeriod = EndOfMonth(BeginOfPeriod) + 1;
		
	EndDo;
	
	DeleteTasksByDate(ExecutionParameters);
	
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
	
	TTUsed = New Array;
	TTUsed.Add("JobsForCalculating");
	
	TempTablesManager = New TempTablesManager();
	
	QueryText = 
	"SELECT DISTINCT
	|	AllDocuments.Ref AS Ref,
	|	AllDocuments.Date AS Date,
	|	AllDocuments.Organization AS Organization,
	|	CAST(AllDocuments.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
	|	AllDocuments.AccountingObject AS AccountingObject,
	|	AllDocuments.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	AllDocuments.RecordInManAccounting AS RecordInManAccounting,
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
	|		CurrentDocuments.FixedAsset AS AccountingObject
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS CurrentDocuments
	|
	|	WHERE
	|		CurrentDocuments.Ref IN (&DocumentsList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.Posted
	|
	|		AND TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
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
	|		CurrentDocuments.IntangibleAsset AS AccountingObject
	|	FROM
	|		InformationRegister.IntangibleAssetsDocuments AS CurrentDocuments
	|
	|	WHERE
	|		CurrentDocuments.Ref IN (&DocumentsList)
	|		AND CurrentDocuments.RefType IN (&DocumentIDs)
	|		AND CurrentDocuments.Posted
	|
	|		AND TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
	|			WHERE
	|				Jobs.Organization = CurrentDocuments.Organization
	|				AND Jobs.AccountingObject = CurrentDocuments.IntangibleAsset
	|				AND Jobs.Month <= CurrentDocuments.Date)
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
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("DocumentsList", ListOfAvailableDocuments);
	Query.SetParameter("DocumentIDs", NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	
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
		ProcedureParameters.EndOfPeriod = Selection.Month;
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
// 		* OperationName - String - Name of operation
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
	ExecutionParameters.Insert("OperationName", NameOfFlagOfOperation());
	ExecutionParameters.Insert("MonthClosingOperation", Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords);
	ExecutionParameters.Insert("NumberBeforeSettlement", 0);
	ExecutionParameters.Insert("ExecuteCheck", False);
	ExecutionParameters.Insert("TempTablesManager", Undefined);
	ExecutionParameters.Insert("DataVolume", 0);

	ListOfObjects = New ValueTable();
	ListOfObjects.Columns.Add("AccountingObject", Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords.Dimensions.AccountingObject.Type);
	ExecutionParameters.Insert("ListOfObjects", ListOfObjects);

	Return ExecutionParameters;
	
EndFunction

// The name of the flag for performing the Operation.
// 
// Returns:
//  String -  The Name Of The Flag of Operation
Function NameOfFlagOfOperation() Export
	Return "DeferredFARecordGeneration";
EndFunction

#EndRegion

#Region Other

// Determines whether movements are recorded during delayed formation.
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

// Returns objects for which the Registered Records are not relevant.
// 
// Parameters:
//  DocumentsList - Array of DocumentRef - List of documents
// 
// Returns:
//  Array - Objects for which Registered Records are not relevant
Function ObjectsForWhichRegisteredRecordsAreNotRelevant(DocumentsList) Export
	
	QueryText = 
	"SELECT DISTINCT
	|	ListOfObjects.AccountingObject AS AccountingObject
	|FROM
	|	(SELECT
	|		Jobs.AccountingObject AS AccountingObject
	|
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|
	|			INNER JOIN InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
	|			ON (Jobs.Organization = FixedAssetsDocuments.Organization)
	|				AND (Jobs.AccountingObject = FixedAssetsDocuments.FixedAsset)
	|				AND (Jobs.Month <= FixedAssetsDocuments.Date)
	|
	|	WHERE
	|		FixedAssetsDocuments.Ref IN (&DocumentsList)
	|		AND FixedAssetsDocuments.Posted
	|		AND FixedAssetsDocuments.RefType IN(&DocumentTypes)
	|		AND &MasterNode
	|
	|	UNION ALL
	|
	|	SELECT
	|		FixedAssetsDocuments.FixedAsset AS AccountingObject
	|	FROM
	|		InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|
	|			LEFT JOIN AccumulationRegister.FACost AS CostOfOS_CostCalculation
	|			ON CostOfOS_CostCalculation.Recorder = FixedAssetsDocuments.Ref
	|	WHERE
	|		FixedAssetsDocuments.Ref IN (&DocumentsList)
	|		AND FixedAssetsDocuments.Posted
	|		AND FixedAssetsDocuments.RefType IN(&DocumentTypes)
	|		AND CostOfOS_CostCalculation.Recorder IS NULL
	|		AND NOT &MasterNode
	|
	|	UNION ALL
	|
	|	SELECT
	|		Jobs.AccountingObject AS AccountingObject
	|	FROM
	|		InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|
	|			INNER JOIN InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
	|			ON (Jobs.Organization = IntangibleAssetsDocuments.Organization)
	|			AND (Jobs.AccountingObject = IntangibleAssetsDocuments.IntangibleAsset)
	|			AND (Jobs.Month <= IntangibleAssetsDocuments.Date)
	|	WHERE
	|		IntangibleAssetsDocuments.Ref IN (&DocumentsList)
	|		AND IntangibleAssetsDocuments.Posted
	|		AND IntangibleAssetsDocuments.RefType IN(&DocumentTypes)
	|		AND &MasterNode
	|
	|	UNION ALL
	|
	|	SELECT
	|		IntangibleAssetsDocuments.IntangibleAsset AS AccountingObject
	|	FROM
	|		InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|
	|			LEFT JOIN AccumulationRegister.IACost AS CostNMA_CostCalculation
	|			ON CostNMA_CostCalculation.Recorder = IntangibleAssetsDocuments.Ref
	|	WHERE
	|		IntangibleAssetsDocuments.Ref IN (&DocumentsList)
	|		AND IntangibleAssetsDocuments.Posted
	|		AND IntangibleAssetsDocuments.RefType IN(&DocumentTypes)
	|		AND CostNMA_CostCalculation.Recorder IS NULL
	|		AND NOT &MasterNode
	|
	|	) AS ListOfObjects
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsList", DocumentsList);
	Query.SetParameter("DocumentTypes", NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	Query.SetParameter("MasterNode", ExchangePlans.MasterNode() = Undefined);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload().UnloadColumn("AccountingObject");
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// Generates tasks for the deferred formation of movements on the OS, if the original data has changed.
//
// Parameters:
// 	Document - DocumentObject, Undefined - The document that is being modified.
// 	TablesData - See DocumentsPosting.OldStructureTableData
Procedure GenerateJobs(Document, TablesData) Export

	If Not GetFunctionalOption("UseNonCurrentAssets2_4")
		Or RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document) Then
		Return;
	EndIf; 
	
	TablesToUse = TMCommonUse.ListOfTemporaryTables(TablesData.TempTablesManager);
	
	// Of operations that are performed after the Cur of operation
	RegisteredRecordsAreFormedAtCloseOfMonth =
		FACostCalculation.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document)
		Or FACostCalculation.RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA(Document)
		Or ClosingExpensesFromDisposalOfFixedAssets.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document);
	
	GenerateTableOfCalculationsForFinancialInstrumentsByFA(TablesData);
	
	TablesList = New Array;
	TablesList.Add("FixedAssetsDepreciationCharge");
	TablesList.Add("LeasedAsset");
	TablesList.Add("InvestmentInRent");
	TablesList.Add("FALocation");
	TablesList.Add("OSBUDepreciationParameters");
	TablesList.Add("FixedAssetDepreciationParametersManagementAccounting");
	TablesList.Add("AssetsLeasedOut");
	TablesList.Add("FixedAssetsAccountingProcedure");
	TablesList.Add("AccountingProcedureForOSBU");
	TablesList.Add("FixedAssetsAccountingProcedureManagementAccounting");
	TablesList.Add("SettlementsOnFinancialInstrumentsByFA");
	TablesList.Add("FACost");
	TablesList.Add("SubAssetsComponentsOfDepreciation");
	
	DeferredFARecordGenerationLocalization.CompleteListOfTablesForCreatingTasksForCreatingRegisteredRecords(TablesList);
	
	Add_Fields = New Structure("AccountingObject", "FixedAsset");
	FADataPoolingText = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TablesData, Add_Fields);
	
	TablesList = New Array;
	TablesList.Add("IntangibleAssetsAmortizationCharge");
	TablesList.Add("IntangibleAssetsRegistrationPlace");
	TablesList.Add("IADepreciationParametersBookkeepingAndTaxAccounting");
	TablesList.Add("IntangibleAssetAmortizationParametersManagementAccounting");
	TablesList.Add("InitialIntangibleAssetsInformation");
	TablesList.Add("IntangibleAssetsAccountingProcedure");
	TablesList.Add("IABookkeepingProcedureBookkeepingAndTaxAccounting");
	TablesList.Add("IntangibleAssetsAccountingProcedureManagementAccounting");
	TablesList.Add("IACost");
	
	Add_Fields = New Structure("AccountingObject", "IntangibleAsset");
	TextOfIaDataPooling = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TablesData, Add_Fields);
	
	TablesList = New Array;
	TablesList.Add("CustomerInvoiceServicesAndAssets");
	TablesList.Add("FARevaluation2_4");
	TablesList.Add("IARevaluation2_4");
	Add_Fields = New Structure("AccountingObject", "NonCurrentAsset");
	TextOfDataAssociationIn = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TablesData, Add_Fields);
	
	DataTexts = New Array;
	If FADataPoolingText <> "" Then
		DataTexts.Add(FADataPoolingText);
	EndIf;
	If TextOfIaDataPooling <> "" Then
		DataTexts.Add(TextOfIaDataPooling);
	EndIf; 
	If TextOfDataAssociationIn <> "" Then
		DataTexts.Add(TextOfDataAssociationIn);
	EndIf; 
	DataJoinText = StrConcat(DataTexts, TMCommonUse.QuerySeparatorInJoin());
	
	If Document <> Undefined
		And Not RegisteredRecordsAreFormedAtCloseOfMonth Then
		
		DocumentType = TypeOf(Document.Ref);

		// It is necessary to register a document if, during the execution, it does not generate movements in the registers for which tasks are generated.
		RegisterDocument = 
			DocumentType = Type("DocumentRef.LeaseTermAdjustment")
			Or DocumentType = Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment")
			Or DocumentType = Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment")
			Or DocumentType = Type("DocumentRef.FixedAssetsCostAdditions2_4")
			Or DocumentType = Type("DocumentRef.AllocateVariancesToFixedAssetCost")
			Or DocumentType = Type("DocumentRef.FATransfer2_4")
			Or DocumentType = Type("DocumentRef.IATransfer2_4")
			Or DocumentType = Type("DocumentRef.FARevaluation2_4")
			Or DocumentType = Type("DocumentRef.IARevaluation2_4")
			Or DocumentType = Type("DocumentRef.DisposeFixedAssets2_4")
			Or DocumentType = Type("DocumentRef.DisposeIntangibleAssets2_4");
			
	Else
		RegisterDocument = False;
	EndIf;
	
	If DataJoinText = "" And Not RegisterDocument Then
		TMCommonUse.DestroyTemporaryTables(TablesData.TempTablesManager,, TablesToUse);
		Return;
	EndIf;
	
	ListOfRequests = New Array;
	If DataJoinText = "" Then
		
		QueryText =
		"SELECT
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Document AS Document,
		|	ChangedData.AccountingObject AS AccountingObject,
		|
		|	MIN(CASE
		|				WHEN VALUETYPE(ChangedData.Document) = TYPE(Document.EntryOfCapitalAssetsBalance2_4)
		|						OR VALUETYPE(ChangedData.Document) = TYPE(Document.OBEntryOfLeaseSettlements)
		|						OR VALUETYPE(ChangedData.Document) = TYPE(Document.EnterRentalInvestmentBalance)
		|					THEN BEGINOFPERIOD(DATEADD(ENDOFPERIOD(ChangedData.Period, MONTH), DAY, 1), MONTH)
		|				ELSE BEGINOFPERIOD(ChangedData.Period, MONTH)
		|			END) AS Month
		|
		|INTO TTTasksForFormationOfRegisteredRecordsOfVNA
		|
		|FROM
		|	(SELECT
		|		ChangedData.Organization,
		|		ChangedData.Ref AS Document,
		|		ChangedData.FixedAsset AS AccountingObject,
		|		ChangedData.Date AS Period
		|
		|	FROM
		|		InformationRegister.FixedAssetsDocuments AS ChangedData
		|
		|	WHERE
		|		ChangedData.Ref = &Ref
		|		AND ChangedData.Date >= &AccountingStartDate
		|
		|	UNION ALL
		|
		|	SELECT
		|		ChangedData.Organization,
		|		ChangedData.Ref AS Document,
		|		ChangedData.IntangibleAsset AS AccountingObject,
		|		ChangedData.Date AS Period
		|
		|	FROM
		|		InformationRegister.IntangibleAssetsDocuments AS ChangedData
		|
		|	WHERE
		|		ChangedData.Ref = &Ref
		|		AND ChangedData.Date >= &AccountingStartDate
		|
		|	) AS ChangedData
		|
		|GROUP BY
		|	ChangedData.Organization,
		|	ChangedData.Document,
		|	ChangedData.AccountingObject
		|
		|INDEX BY
		|	Month,
		|	Organization,
		|	AccountingObject,
		|	Document
		|";
		
		ListOfRequests.Add(QueryText);
		
	Else
		
		QueryText =
		"SELECT
		|	ChangedData.Organization       AS Organization,
		|	ChangedData.AccountingObject       AS AccountingObject,
		|	ChangedData.Document          AS Document,
		|	ChangedData.Period            AS Period
		|
		|INTO ChangedData
		|
		|FROM
		|	DataUnionText_Redefined AS ChangedData
		|
		|INDEX BY
		|	AccountingObject";
		
		QueryText = StrReplace(QueryText, "DataUnionText_Redefined", "(" + DataJoinText + ")");
		ListOfRequests.Add(QueryText);
		
		QueryText =
		"SELECT
		|	ChangedData.Period AS Period,
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Document AS Document,
		|	SubAssetsComponentsOfDepreciation.FixedAsset AS AccountingObject
		|
		|INTO SubAssetsComponentsOfDepreciation
		|
		|FROM
		|	ChangedData AS ChangedData
		|
		|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
		|		ON SubAssetsComponentsOfDepreciation.SubAssetComponent = ChangedData.AccountingObject
		|
		|";
		ListOfRequests.Add(QueryText);
	
		QueryText =
		"SELECT
		|	ChangedData.Organization,
		|	ChangedData.Document,
		|	ChangedData.AccountingObject,
		|
		|	MIN(CASE
		|				WHEN &RegisteredRecordsAreFormedAtCloseOfMonth
		|						OR VALUETYPE(ChangedData.Document) = TYPE(Document.EntryOfCapitalAssetsBalance2_4)
		|						OR VALUETYPE(ChangedData.Document) = TYPE(Document.OBEntryOfLeaseSettlements)
		|						OR VALUETYPE(ChangedData.Document) = TYPE(Document.EnterRentalInvestmentBalance)
		|					THEN BEGINOFPERIOD(DATEADD(ENDOFPERIOD(ChangedData.Period, MONTH), DAY, 1), MONTH)
		|				ELSE BEGINOFPERIOD(ChangedData.Period, MONTH)
		|			END) AS Month
		|
		|INTO TTTasksForFormationOfRegisteredRecordsOfVNA
		|
		|FROM
		|	(SELECT
		|		ChangedData.Organization AS Organization,
		|		ChangedData.Document AS Document,
		|		ChangedData.AccountingObject AS AccountingObject,
		|		ChangedData.Period AS Period
		|	FROM
		|		ChangedData AS ChangedData
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SubAssetsComponentsOfDepreciation.Organization AS Organization,
		|		SubAssetsComponentsOfDepreciation.Document AS Document,
		|		SubAssetsComponentsOfDepreciation.AccountingObject AS AccountingObject,
		|		SubAssetsComponentsOfDepreciation.Period AS Period
		|	FROM
		|		SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
		|	
		|	) AS ChangedData
		|
		|GROUP BY
		|	ChangedData.Organization,
		|	ChangedData.Document,
		|	ChangedData.AccountingObject
		|
		|INDEX BY
		|	Month,
		|	Organization,
		|	AccountingObject,
		|	Document
		|";
		
		ListOfRequests.Add(QueryText);
			
	EndIf; 
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TablesData.TempTablesManager;
	Query.SetParameter("Ref", Document.Ref);
	Query.SetParameter("DocumentTypes", NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	Query.SetParameter("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	Query.SetParameter("RegisteredRecordsAreFormedAtCloseOfMonth", RegisteredRecordsAreFormedAtCloseOfMonth);
	
	SetPrivilegedMode(True);
	
	Query.Execute();
	
	InformationRegisters.JobsForGeneratingFixedAssetRecords.CreateRegisterEntriesOnTemporaryTable(Query.TempTablesManager);
	
	SetPrivilegedMode(False);
	
	TMCommonUse.DestroyTemporaryTables(TablesData.TempTablesManager,, TablesToUse);
	
EndProcedure

// Generates the Query Text of empty tables of deferred Registered Records.
// 
// Parameters:
//  Query - Query - 
// 	QueryTexts - ValueList of String -
Procedure QueryTextEmptyDeferredMovementTables(Query, QueryTexts) Export

	If Query.TempTablesManager.Tables.Find("TT_CostOfVNA") = Undefined
		And Not DocumentsPosting.ThereIsQueryTable("TT_CostOfVNA", QueryTexts) Then
	
		QueryText = 
		"SELECT
		|	NULL   AS Ref,
		|	NULL   AS AccountingObject,
		|	0      AS Cost,
		|	0      AS LocalCost,
		|	0      AS CostInTaxAccounting,
		|	0      AS CostTargetFinancing,
		|	0      AS CostPermanentDifference,
		|	0      AS CostTemporaryDifference,
		|	0      AS CostTargetFinancingTA,
		|	0      AS CostTargetFinancingPD,
		|	0      AS CostTargetFinancingTD,
		|	0      AS DisregardedCostTA,
		|	0      AS DepreciationAllowance,
		|	0      AS PreliminaryCostMan,
		|	0      AS PreliminaryCostLocal,
		|	0      AS CostGainMA,
		|	0      AS CostGainLocal,
		|	0      AS ShareOfCentralBank,
		|	0      AS CFNUShare,
		|	0      AS CfprShare,
		|	0      AS SecurityDepositValue,
		|	0      AS CostRevaluationReserve,
		|	0      AS CostRevaluationReserveLocal
		|
		|INTO TT_CostOfVNA 
		|WHERE
		|	FALSE";
		
		QueryTexts.Add(QueryText, "TT_CostOfVNA");
		
	EndIf;
	
	If Query.TempTablesManager.Tables.Find("TT_DepreciationOfVNA") = Undefined
		And Not DocumentsPosting.ThereIsQueryTable("TT_DepreciationOfVNA", QueryTexts) Then
	
		QueryText = 
		"SELECT
		|	NULL   AS Ref,
		|	NULL   AS AccountingObject,
		|	0      AS Depreciation,
		|	0      AS DepreciationLocal,
		|	0      AS DepreciationInTaxAccounting,
		|	0      AS DepreciationPermanentDifferences,
		|	0      AS DepreciationTD,
		|	0      AS FixedAssetDepreciationTargetFinancing,
		|	0      AS DepreciationRevaluationReserve,
		|	0      AS DepreciationRevaluationReserveLocal,
		|	0      AS DepreciationTaxAccountingTargetFinancing,
		|	0      AS DepreciationTargetFinancingPD,
		|	0      AS DepreciationOfTargetFinancingTD,
		|	FALSE   AS AccrueDepreciation
		|INTO TT_DepreciationOfVNA 
		|WHERE
		|	FALSE";
		
		QueryTexts.Add(QueryText, "TT_DepreciationOfVNA");
		
	EndIf;
	
	If Query.TempTablesManager.Tables.Find("TT_ImpairmentFA") = Undefined
		And Not DocumentsPosting.ThereIsQueryTable("TT_ImpairmentFA", QueryTexts) Then
	
		QueryText = 
		"SELECT
		|	NULL AS Ref,
		|	NULL AS Date,
		|	NULL AS Organization,
		|	NULL AS AccountingObject,
		|	NULL AS CGU,
		|	0 AS ImpairmenMan,
		|	0 AS ImpairmentLocalAssets
		|
		|INTO TT_ImpairmentFA
		|WHERE
		|	FALSE";
		
		QueryTexts.Add(QueryText, "TT_ImpairmentFA");
		
	EndIf;
	
	If Query.TempTablesManager.Tables.Find("TT_FinancialInstrumentsARAP") = Undefined
		And Not DocumentsPosting.ThereIsQueryTable("TT_FinancialInstrumentsARAP", QueryTexts) Then
	
		QueryText = 
		"SELECT
		|	UNDEFINED AS Ref,
		|	DATETIME(1,1,1) AS Date,
		|	UNDEFINED AS AccountingDimensionByPartners,
		|	VALUE(Catalog.LeaseContract.EmptyRef) AS Contract,
		|	UNDEFINED AS AmountType,
		|	UNDEFINED AS ARAPDocument,
		|	UNDEFINED AS Currency,
		|	0 AS Sum,
		|	0 AS SumMan,
		|	0 AS SumCompl
		|INTO TT_FinancialInstrumentsARAP 
		|WHERE
		|	FALSE";
		
		QueryTexts.Add(QueryText, "TT_FinancialInstrumentsARAP");
		
	EndIf;
	
	If Query.TempTablesManager.Tables.Find("TT_InvestmentInRent") = Undefined
		And Not DocumentsPosting.ThereIsQueryTable("TT_InvestmentInRent", QueryTexts) Then
	
		QueryText = 
		"SELECT
		|	UNDEFINED AS Ref,
		|	DATETIME(1,1,1) AS Date,
		|	UNDEFINED AS AccountingObject,
		|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	UNDEFINED AS FinancialAccountingGroup,
		|	0 AS RentalPayments,
		|	0 AS RentalPaymentsLocal,
		|	0 AS RentalPaymentsManag,
		|	0 AS NonGuaranteedResidualValueLocal,
		|	0 AS NonGuaranteedResidualValueManag,
		|	0 AS InterestDiscount,
		|	0 AS InterestDiscountMan,
		|	0 AS InterestDiscountLocal
		|INTO TT_InvestmentInRent 
		|WHERE
		|	FALSE";
		
		QueryTexts.Add(QueryText, "TT_InvestmentInRent");
		
	EndIf;
	
EndProcedure

// Determines whether the formation of Registered Recorded movements has been completed on the specified date.
// 
// Parameters:
//  Period - Date - Period
//  CompaniesList - CatalogRef.Companies, Array of CatalogRef.Companies - List of organizations
// 
// Returns:
//  Boolean - True if the formation of RegisteredRecorded.
Function DelayedFormationOfRegisteredRecordedMovementsHasBeenPerformed(Period, CompaniesList) Export
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.JobsForGeneratingFixedAssetRecords AS Jobs
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

Function GetPortionOfDataToBeCalculated(BeginOfPeriod, ExecutionParameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.GetPortionOfDataToBeCalculated");
	
	DataVolume = NonCurrentAssets.CreateTTTablePortionOfDataToBeCalculated(
		BeginOfPeriod, 
		ExecutionParameters.TempTablesManager,
		DataChunkSize());
	
	ExecutionParameters.DataVolume = ExecutionParameters.DataVolume + DataVolume;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
	Return (DataVolume <> 0);
	
EndFunction

Procedure GenerateRegisteredRecordsBasedOnDocuments(Period, ExecutionParameters)
	
	TempTablesManager = ExecutionParameters.TempTablesManager;
	
	PrepareParameters(Period, TempTablesManager);
	MovementTables = PrepareTablesOfRegisteredRecords(Period, TempTablesManager);
	WriteMotionTables(MovementTables, ExecutionParameters);
	
EndProcedure

Procedure PrepareParameters(Period, TempTablesManager)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.PrepareParameters");
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	TTUsed.Add("TT_CostOfVNA");
	TTUsed.Add("TT_DepreciationOfVNA");
	TTUsed.Add("TT_DepreciationForPeriod");
	
	NonCurrentAssets.CreateTTTableOfDataToBeCalculated(TempTablesManager);

	ListOfRequests = New Array;
		
	#Region WearAccrual
	
	QueryText = 
	"SELECT
	|	VALUE(Catalog.Assets.EmptyRef) AS AccountingObject
	|INTO WearAccrual
	|
	|INDEX BY
	|	AccountingObject";
		
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region OffBalanceSheetAccounting
	
	QueryText =
	"SELECT
	|	VALUE(Catalog.Assets.EmptyRef) AS AccountingObject
	|INTO OffBalanceSheetAccounting
	|
	|INDEX BY
	|	AccountingObject";
	
	
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AccountingPolicyOfBU
	QueryText =
	"SELECT
	|	AccountingPolicy.Organization AS Organization,
	|	AccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal AS ProcedureOfFixedAssetDepreciationCharge,
	|	AccountingPolicy.ProcedureOfIntangibleAssetAmortizationChargeLocal AS ProcedureOfIntangibleAssetAmortizationCharge
	|
	|INTO AccountingPolicyOfBU
	|
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&BegOfMonth,
	|		Organization IN (SELECT TTDataToBeCalculated.ParentCompany FROM TTDataToBeCalculated AS TTDataToBeCalculated)) AS AccountingPolicy
	|
	|INDEX BY
	|	Organization";

	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region AccountingPolicyOfMa
	QueryText =
	"SELECT
	|	AccountingPolicy.Organization AS Organization,
	|	AccountingPolicy.ProcedureOfFixedAssetDepreciationCharge AS ProcedureOfFixedAssetDepreciationCharge,
	|	AccountingPolicy.ProcedureOfIntangibleAssetAmortizationCharge AS ProcedureOfIntangibleAssetAmortizationCharge
	|
	|INTO AccountingPolicyOfMa
	|
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(
	|		&BegOfMonth,
	|		Organization IN (SELECT TTDataToBeCalculated.ParentCompany FROM TTDataToBeCalculated AS TTDataToBeCalculated)) AS AccountingPolicy
	|
	|INDEX BY
	|	Organization";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CostOfVNA_Balance
	QueryText = 
	"SELECT
	|	FACostBalance.Organization AS Organization,
	|	FACostBalance.FixedAsset AS AccountingObject,
	|
	|	FACostBalance.CostBalance AS Cost,
	|	FACostBalance.LocalCostBalance AS LocalCost,
	|	FACostBalance.CostInTaxAccountingBalance AS CostInTaxAccounting,
	|	FACostBalance.CostPermanentDifferenceBalance AS CostPermanentDifference,
	|	FACostBalance.CostTemporaryDifferenceBalance AS CostTemporaryDifference,
	|	FACostBalance.CostTargetFinancingBalance AS CostTargetFinancing,
	|	FACostBalance.CostTargetFinancingTABalance AS CostTargetFinancingTA,
	|	FACostBalance.CostTargetFinancingPDBalance AS CostTargetFinancingPD,
	|	FACostBalance.CostTargetFinancingTDBalance AS CostTargetFinancingTD,
	|
	|	FACostBalance.TAExpenseAmountOfInvestmentTaxDeductionBalance AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	FACostBalance.DisregardedCostTABalance AS DisregardedCostTA,
	|	FACostBalance.DepreciationAllowanceBalance AS DepreciationAllowance,
	|	FACostBalance.SecurityDepositValueBalance AS SecurityDepositValue,
	|
	|	FACostBalance.PreliminaryCostManBalance AS PreliminaryCostMan,
	|	FACostBalance.PreliminaryCostLocalBalance AS PreliminaryCostLocal,
	|
	|	FACostBalance.CostRevaluationReserveBalance AS CostRevaluationReserve,
	|	FACostBalance.CostRevaluationReserveLocalBalance AS CostRevaluationReserveLocal,
	|
	|	-FACostBalance.CostGainMABalance AS CostGainMA,
	|	-FACostBalance.CostGainLocalBalance AS CostGainLocal
	|
	|INTO CostOfVNA_Balance
	|
	|FROM
	|	AccumulationRegister.FACost.Balance(
	|			&BegOfMonth,
	|			(Organization, FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS FACostBalance
	|
	|UNION ALL
	|
	|SELECT
	|	IACostBalance.Organization AS Organization,
	|	IACostBalance.IntangibleAsset AS AccountingObject,
	|
	|	IACostBalance.CostBalance AS Cost,
	|	IACostBalance.LocalCostBalance AS LocalCost,
	|	IACostBalance.CostInTaxAccountingBalance AS CostInTaxAccounting,
	|	IACostBalance.CostPermanentDifferenceBalance AS CostPermanentDifference,
	|	IACostBalance.CostTemporaryDifferenceBalance AS CostTemporaryDifference,
	|	IACostBalance.CostTargetFinancingBalance AS CostTargetFinancing,
	|	IACostBalance.CostTargetFinancingTABalance AS CostTargetFinancingTA,
	|	IACostBalance.CostTargetFinancingPDBalance AS CostTargetFinancingPD,
	|	IACostBalance.CostTargetFinancingTDBalance AS CostTargetFinancingTD,
	|
	|	IACostBalance.TAExpenseAmountOfInvestmentTaxDeductionBalance AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0 AS DisregardedCostTA,
	|	0 AS DepreciationAllowance,
	|	0 AS SecurityDepositValue,
	|
	|	IACostBalance.PreliminaryCostManBalance AS PreliminaryCostMan,
	|	IACostBalance.PreliminaryCostLocalBalance AS PreliminaryCostLocal,
	|
	|	IACostBalance.CostRevaluationReserveBalance AS CostRevaluationReserve,
	|	IACostBalance.CostRevaluationReserveLocalBalance AS CostRevaluationReserveLocal,
	|
	|	-IACostBalance.CostGainMABalance AS CostGainMA,
	|	-IACostBalance.CostGainLocalBalance AS CostGainLocal
	|
	|FROM
	|	AccumulationRegister.IACost.Balance(
	|			&BegOfMonth,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS IACostBalance
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region Vna_TrafficCost
	QueryText = 
	"SELECT
	|	FACost.Period AS Period,
	|	FACost.Recorder AS Recorder,
	|	FACost.Organization AS Organization,
	|	FACost.FixedAsset AS AccountingObject,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.Cost
	|		ELSE -FACost.Cost
	|	END AS Cost,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.LocalCost
	|		ELSE -FACost.LocalCost
	|	END AS LocalCost,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostInTaxAccounting
	|		ELSE -FACost.CostInTaxAccounting
	|	END AS CostInTaxAccounting,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostPermanentDifference
	|		ELSE -FACost.CostPermanentDifference
	|	END AS CostPermanentDifference,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTemporaryDifference
	|		ELSE -FACost.CostTemporaryDifference
	|	END AS CostTemporaryDifference,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancing
	|		ELSE -FACost.CostTargetFinancing
	|	END AS CostTargetFinancing,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancingTA
	|		ELSE -FACost.CostTargetFinancingTA
	|	END AS CostTargetFinancingTA,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancingPD
	|		ELSE -FACost.CostTargetFinancingPD
	|	END AS CostTargetFinancingPD,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostTargetFinancingTD
	|		ELSE -FACost.CostTargetFinancingTD
	|	END AS CostTargetFinancingTD,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.TAExpenseAmountOfInvestmentTaxDeduction
	|		ELSE -FACost.TAExpenseAmountOfInvestmentTaxDeduction
	|	END AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.DisregardedCostTA
	|		ELSE -FACost.DisregardedCostTA
	|	END AS DisregardedCostTA,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.DepreciationAllowance
	|		ELSE -FACost.DepreciationAllowance
	|	END AS DepreciationAllowance,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.SecurityDepositValue
	|		ELSE -FACost.SecurityDepositValue
	|	END AS SecurityDepositValue,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.PreliminaryCostMan
	|		ELSE -FACost.PreliminaryCostMan
	|	END AS PreliminaryCostMan,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.PreliminaryCostLocal
	|		ELSE -FACost.PreliminaryCostLocal
	|	END AS PreliminaryCostLocal,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostRevaluationReserve
	|		ELSE -FACost.CostRevaluationReserve
	|	END AS CostRevaluationReserve,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN FACost.CostRevaluationReserveLocal
	|		ELSE -FACost.CostRevaluationReserveLocal
	|	END AS CostRevaluationReserveLocal,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FACost.CostGainMA
	|		ELSE FACost.CostGainMA
	|	END AS CostGainMA,
	|
	|	CASE WHEN FACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -FACost.CostGainLocal
	|		ELSE FACost.CostGainLocal
	|	END AS CostGainLocal
	|
	|INTO Vna_TrafficCost
	|
	|FROM
	|	AccumulationRegister.FACost AS FACost
	|
	|WHERE
	|	FACost.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FACost.Active
	|
	|	AND (FACost.Organization, FACost.FixedAsset) IN
	|			(SELECT
	|				TTDataToBeCalculated.Organization,
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	IACost.Period AS Period,
	|	IACost.Recorder AS Recorder,
	|	IACost.Organization AS Organization,
	|	IACost.IntangibleAsset AS AccountingObject,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.Cost
	|		ELSE -IACost.Cost
	|	END AS Cost,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.LocalCost
	|		ELSE -IACost.LocalCost
	|	END AS LocalCost,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostInTaxAccounting
	|		ELSE -IACost.CostInTaxAccounting
	|	END AS CostInTaxAccounting,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostPermanentDifference
	|		ELSE -IACost.CostPermanentDifference
	|	END AS CostPermanentDifference,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostTemporaryDifference
	|		ELSE -IACost.CostTemporaryDifference
	|	END AS CostTemporaryDifference,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostTargetFinancing
	|		ELSE -IACost.CostTargetFinancing
	|	END AS CostTargetFinancing,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostTargetFinancingTA
	|		ELSE -IACost.CostTargetFinancingTA
	|	END AS CostTargetFinancingTA,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostTargetFinancingPD
	|		ELSE -IACost.CostTargetFinancingPD
	|	END AS CostTargetFinancingPD,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostTargetFinancingTD
	|		ELSE -IACost.CostTargetFinancingTD
	|	END AS CostTargetFinancingTD,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.TAExpenseAmountOfInvestmentTaxDeduction
	|		ELSE -IACost.TAExpenseAmountOfInvestmentTaxDeduction
	|	END AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	0 AS DisregardedCostTA,
	|	0 AS DepreciationAllowance,
	|	0 AS SecurityDepositValue,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.PreliminaryCostMan
	|		ELSE -IACost.PreliminaryCostMan
	|	END AS PreliminaryCostMan,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.PreliminaryCostLocal
	|		ELSE -IACost.PreliminaryCostLocal
	|	END AS PreliminaryCostLocal,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostRevaluationReserve
	|		ELSE -IACost.CostRevaluationReserve
	|	END AS CostRevaluationReserve,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN IACost.CostRevaluationReserveLocal
	|		ELSE -IACost.CostRevaluationReserveLocal
	|	END AS CostRevaluationReserveLocal,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -IACost.CostGainMA
	|		ELSE IACost.CostGainMA
	|	END AS CostGainMA,
	|
	|	CASE WHEN IACost.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -IACost.CostGainLocal
	|		ELSE IACost.CostGainLocal
	|	END AS CostGainLocal
	|
	|FROM
	|	AccumulationRegister.IACost AS IACost
	|
	|WHERE
	|	IACost.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND IACost.Active
	|
	|	AND (IACost.Organization, IACost.IntangibleAsset) IN
	|			(SELECT
	|				TTDataToBeCalculated.Organization,
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|INDEX BY
	|	AccountingObject,
	|	Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region TT_CostOfVNA
	QueryText = 
	"SELECT
	|	DataForCalculation.Ref AS Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization AS Organization,
	|	DataForCalculation.AccountingObject AS AccountingObject,
	|
	|	DataForCalculation.OffBalanceSheetAccounting AS OffBalanceSheetAccounting,
	|
	|	SUM(DataForCalculation.Cost) AS Cost,
	|	SUM(DataForCalculation.LocalCost) AS LocalCost,
	|	SUM(DataForCalculation.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(DataForCalculation.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(DataForCalculation.CostTemporaryDifference) AS CostTemporaryDifference,
	|	SUM(DataForCalculation.CostTargetFinancing) AS CostTargetFinancing,
	|	SUM(DataForCalculation.CostTargetFinancingTA) AS CostTargetFinancingTA,
	|	SUM(DataForCalculation.CostTargetFinancingPD) AS CostTargetFinancingPD,
	|	SUM(DataForCalculation.CostTargetFinancingTD) AS CostTargetFinancingTD,
	|
	|	SUM(DataForCalculation.TAExpenseAmountOfInvestmentTaxDeduction) AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	SUM(DataForCalculation.DisregardedCostTA) AS DisregardedCostTA,
	|	SUM(DataForCalculation.DepreciationAllowance) AS DepreciationAllowance,
	|	SUM(DataForCalculation.SecurityDepositValue) AS SecurityDepositValue,
	|
	|	SUM(DataForCalculation.PreliminaryCostMan) AS PreliminaryCostMan,
	|	SUM(DataForCalculation.PreliminaryCostLocal) AS PreliminaryCostLocal,
	|
	|	SUM(DataForCalculation.CostRevaluationReserve) AS CostRevaluationReserve,
	|	SUM(DataForCalculation.CostRevaluationReserveLocal) AS CostRevaluationReserveLocal,
	|
	|	SUM(DataForCalculation.CostGainMA) AS CostGainMA,
	|	SUM(DataForCalculation.CostGainLocal) AS CostGainLocal,
	|
	|	CASE WHEN SUM(DataForCalculation.CostTargetFinancing) = 0 OR (SUM(DataForCalculation.LocalCost) + SUM(DataForCalculation.CostTargetFinancing)) = 0
	|		THEN 0
	|		ELSE SUM(DataForCalculation.CostTargetFinancing) / (SUM(DataForCalculation.LocalCost) + SUM(DataForCalculation.CostTargetFinancing))
	|	END AS ShareOfCentralBank,
	|
	|	CASE WHEN SUM(DataForCalculation.CostTargetFinancingTA) = 0 OR (SUM(DataForCalculation.CostInTaxAccounting) + SUM(DataForCalculation.CostTargetFinancingTA)) = 0
	|		THEN 0
	|		ELSE SUM(DataForCalculation.CostTargetFinancingTA) / (SUM(DataForCalculation.CostInTaxAccounting) + SUM(DataForCalculation.CostTargetFinancingTA))
	|	END AS CFNUShare,
	|
	|	CASE WHEN SUM(DataForCalculation.CostTargetFinancingPD) = 0 OR (SUM(DataForCalculation.CostPermanentDifference) + SUM(DataForCalculation.CostTargetFinancingPD)) = 0
	|		THEN 0
	|		ELSE SUM(DataForCalculation.CostTargetFinancingPD) / (SUM(DataForCalculation.CostPermanentDifference) + SUM(DataForCalculation.CostTargetFinancingPD))
	|	END AS CfprShare
	|
	|INTO TT_CostOfVNA
	|
	|FROM
	|	(SELECT
	|		DataForCalculation.Ref AS Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization AS Organization,
	|		DataForCalculation.AccountingObject AS AccountingObject,
	|
	|		NOT OffBalanceSheetAccounting.AccountingObject IS NULL AS OffBalanceSheetAccounting,
	|
	|		ISNULL(CostOfVNA.Cost, 0) AS Cost,
	|		ISNULL(CostOfVNA.LocalCost, 0) AS LocalCost,
	|		ISNULL(CostOfVNA.CostInTaxAccounting, 0) AS CostInTaxAccounting,
	|		ISNULL(CostOfVNA.CostPermanentDifference, 0) AS CostPermanentDifference,
	|		ISNULL(CostOfVNA.CostTemporaryDifference, 0) AS CostTemporaryDifference,
	|		ISNULL(CostOfVNA.CostTargetFinancing, 0) AS CostTargetFinancing,
	|		ISNULL(CostOfVNA.CostTargetFinancingTA, 0) AS CostTargetFinancingTA,
	|		ISNULL(CostOfVNA.CostTargetFinancingPD, 0) AS CostTargetFinancingPD,
	|		ISNULL(CostOfVNA.CostTargetFinancingTD, 0) AS CostTargetFinancingTD,
	|
	|		ISNULL(CostOfVNA.TAExpenseAmountOfInvestmentTaxDeduction, 0) AS TAExpenseAmountOfInvestmentTaxDeduction,
	|		ISNULL(CostOfVNA.DisregardedCostTA, 0) AS DisregardedCostTA,
	|		ISNULL(CostOfVNA.DepreciationAllowance, 0) AS DepreciationAllowance,
	|		ISNULL(CostOfVNA.SecurityDepositValue, 0) AS SecurityDepositValue,
	|
	|		ISNULL(CostOfVNA.PreliminaryCostMan, 0) AS PreliminaryCostMan,
	|		ISNULL(CostOfVNA.PreliminaryCostLocal, 0) AS PreliminaryCostLocal,
	|
	|		ISNULL(CostOfVNA.CostRevaluationReserve, 0) AS CostRevaluationReserve,
	|		ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0) AS CostRevaluationReserveLocal,
	|
	|		ISNULL(CostOfVNA.CostGainMA, 0) AS CostGainMA,
	|		ISNULL(CostOfVNA.CostGainLocal, 0) AS CostGainLocal
	|
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN CostOfVNA_Balance AS CostOfVNA
	|			ON (CostOfVNA.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (CostOfVNA.Organization = DataForCalculation.Organization)
	|
	|			LEFT JOIN OffBalanceSheetAccounting AS OffBalanceSheetAccounting
	|			ON (OffBalanceSheetAccounting.AccountingObject = DataForCalculation.AccountingObject)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataForCalculation.Ref AS Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization AS Organization,
	|		DataForCalculation.AccountingObject AS AccountingObject,
	|
	|		NOT OffBalanceSheetAccounting.AccountingObject IS NULL,
	|
	|		ISNULL(CostOfVNA.Cost, 0),
	|		ISNULL(CostOfVNA.LocalCost, 0),
	|		ISNULL(CostOfVNA.CostInTaxAccounting, 0),
	|		ISNULL(CostOfVNA.CostPermanentDifference, 0),
	|		ISNULL(CostOfVNA.CostTemporaryDifference, 0),
	|		ISNULL(CostOfVNA.CostTargetFinancing, 0),
	|		ISNULL(CostOfVNA.CostTargetFinancingTA, 0),
	|		ISNULL(CostOfVNA.CostTargetFinancingPD, 0),
	|		ISNULL(CostOfVNA.CostTargetFinancingTD, 0),
	|
	|		ISNULL(CostOfVNA.TAExpenseAmountOfInvestmentTaxDeduction, 0),
	|		ISNULL(CostOfVNA.DisregardedCostTA, 0),
	|		ISNULL(CostOfVNA.DepreciationAllowance, 0),
	|		ISNULL(CostOfVNA.SecurityDepositValue, 0),
	|
	|		ISNULL(CostOfVNA.PreliminaryCostMan, 0),
	|		ISNULL(CostOfVNA.PreliminaryCostLocal, 0),
	|
	|		ISNULL(CostOfVNA.CostRevaluationReserve, 0),
	|		ISNULL(CostOfVNA.CostRevaluationReserveLocal, 0),
	|
	|		ISNULL(CostOfVNA.CostGainMA, 0),
	|		ISNULL(CostOfVNA.CostGainLocal, 0)
	|
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN Vna_TrafficCost AS CostOfVNA
	|			ON (CostOfVNA.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (CostOfVNA.Organization = DataForCalculation.Organization)
	|				AND (CostOfVNA.Period <= DataForCalculation.Date
	|					OR VALUETYPE(CostOfVNA.Recorder) IN (&TypesOfDocumentsThatChangeValueAtEndOfMonth))
	|				AND (CostOfVNA.Recorder <> DataForCalculation.Ref)
	|
	|			LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|			ON (IntangibleAssets.Ref = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN OffBalanceSheetAccounting AS OffBalanceSheetAccounting
	|			ON (OffBalanceSheetAccounting.AccountingObject = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS FAAdjustment
	|			ON FAAdjustment.Ref = DataForCalculation.Ref
	|
	|			LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS IAAdjustment
	|			ON IAAdjustment.Ref = DataForCalculation.Ref
	|
	|	WHERE
	|		(NOT ISNULL(FAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE)
	|				AND NOT ISNULL(IAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE)
	|			OR ISNULL(IntangibleAssets.KindOfAccountingObject, UNDEFINED) <> VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		DataForCalculation.Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization,
	|		DataForCalculation.AccountingObject,
	|		NOT OffBalanceSheetAccounting.AccountingObject IS NULL,
	|
	|		ISNULL(FACost.Cost, 0),
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		ISNULL(FACost.PreliminaryCostMan, 0),
	|		0,
	|		ISNULL(FACost.CostRevaluationReserve, 0),
	|		0,
	|		ISNULL(FACost.CostGainMA, 0),
	|		0
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN Vna_TrafficCost AS FACost
	|			ON (FACost.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (FACost.Organization = DataForCalculation.Organization)
	|				AND (FACost.Recorder <> DataForCalculation.Ref)
	|
	|			LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|			ON (IntangibleAssets.Ref = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN OffBalanceSheetAccounting AS OffBalanceSheetAccounting
	|			ON (OffBalanceSheetAccounting.AccountingObject = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS FAAdjustment
	|			ON FAAdjustment.Ref = DataForCalculation.Ref
	|
	|			LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS IAAdjustment
	|			ON IAAdjustment.Ref = DataForCalculation.Ref
	|
	|	WHERE
	|		(ISNULL(FAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE)
	|			OR ISNULL(IAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE))
	|		AND DataForCalculation.RecordInManAccounting
	|		AND ISNULL(IntangibleAssets.KindOfAccountingObject, UNDEFINED) = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataForCalculation.Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization,
	|		DataForCalculation.AccountingObject,
	|		NOT OffBalanceSheetAccounting.AccountingObject IS NULL,
	|
	|		0,
	|
	|		ISNULL(FACost.LocalCost, 0),
	|		ISNULL(FACost.CostInTaxAccounting, 0),
	|		ISNULL(FACost.CostPermanentDifference, 0),
	|		ISNULL(FACost.CostTemporaryDifference, 0),
	|		ISNULL(FACost.CostTargetFinancing, 0),
	|		ISNULL(FACost.CostTargetFinancingTA, 0),
	|		ISNULL(FACost.CostTargetFinancingPD, 0),
	|		ISNULL(FACost.CostTargetFinancingTD, 0),
	|
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN Vna_TrafficCost AS FACost
	|			ON (FACost.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (FACost.Organization = DataForCalculation.Organization)
	|				AND (FACost.Recorder <> DataForCalculation.Ref)
	|
	|			LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|			ON (IntangibleAssets.Ref = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN OffBalanceSheetAccounting AS OffBalanceSheetAccounting
	|			ON (OffBalanceSheetAccounting.AccountingObject = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS FAAdjustment
	|			ON FAAdjustment.Ref = DataForCalculation.Ref
	|
	|			LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS IAAdjustment
	|			ON IAAdjustment.Ref = DataForCalculation.Ref
	|
	|	WHERE
	|		(ISNULL(FAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE)
	|			OR ISNULL(IAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE))
	|		AND DataForCalculation.RecordInLocalAccounting
	|		AND ISNULL(IntangibleAssets.KindOfAccountingObject, UNDEFINED) = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataForCalculation.Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization,
	|		DataForCalculation.AccountingObject,
	|		NOT OffBalanceSheetAccounting.AccountingObject IS NULL,
	|
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|
	|		0 AS TAExpenseAmountOfInvestmentTaxDeduction,
	|		ISNULL(FACost.DisregardedCostTA, 0),
	|		ISNULL(FACost.DepreciationAllowance, 0),
	|		ISNULL(FACost.SecurityDepositValue, 0),
	|		ISNULL(FACost.PreliminaryCostMan, 0),
	|		ISNULL(FACost.PreliminaryCostLocal, 0),
	|		ISNULL(FACost.CostRevaluationReserve, 0),
	|		ISNULL(FACost.CostRevaluationReserveLocal, 0),
	|		ISNULL(FACost.CostGainMA, 0),
	|		ISNULL(FACost.CostGainLocal, 0)
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN Vna_TrafficCost AS FACost
	|			ON (FACost.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (FACost.Organization = DataForCalculation.Organization)
	|				AND (FACost.Recorder <> DataForCalculation.Ref)
	|				AND (FACost.Period <= DataForCalculation.Date
	|					OR VALUETYPE(FACost.Recorder) IN (&TypesOfDocumentsThatChangeValueAtEndOfMonth))
	|
	|			LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|			ON (IntangibleAssets.Ref = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN OffBalanceSheetAccounting AS OffBalanceSheetAccounting
	|			ON (OffBalanceSheetAccounting.AccountingObject = DataForCalculation.AccountingObject)
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS FAAdjustment
	|			ON FAAdjustment.Ref = DataForCalculation.Ref
	|
	|			LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS IAAdjustment
	|			ON IAAdjustment.Ref = DataForCalculation.Ref
	|
	|	WHERE
	|		(ISNULL(FAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE)
	|			OR ISNULL(IAAdjustment.IncludesDepreciationOfCurrentMonth, FALSE))
	|		AND DataForCalculation.RecordInLocalAccounting
	|		AND ISNULL(IntangibleAssets.KindOfAccountingObject, UNDEFINED) = VALUE(Enum.IntangibleAssetsAccountingItemKinds.RDExpenses)
	|
	|	) AS DataForCalculation
	|
	|GROUP BY
	|	DataForCalculation.Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization,
	|	DataForCalculation.AccountingObject,
	|	DataForCalculation.OffBalanceSheetAccounting
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion

	#Region DepreciationOfVNA_Balance
	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.Organization AS Organization,
	|	FixedAssetsDepreciationCharge.FixedAsset AS AccountingObject,
	|	-FixedAssetsDepreciationCharge.DepreciationBalance AS Depreciation,
	|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS DepreciationLocal,
	|	-FixedAssetsDepreciationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|	-FixedAssetsDepreciationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|	-FixedAssetsDepreciationCharge.DepreciationTDBalance AS DepreciationTD,
	|	-FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing,
	|	-FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancingBalance AS DepreciationTaxAccountingTargetFinancing,
	|	-FixedAssetsDepreciationCharge.DepreciationTargetFinancingPDBalance AS DepreciationTargetFinancingPD,
	|	-FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTDBalance AS DepreciationOfTargetFinancingTD,
	|	-FixedAssetsDepreciationCharge.DepreciationRevaluationReserveBalance AS DepreciationRevaluationReserve,
	|	-FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocalBalance AS DepreciationRevaluationReserveLocal
	|
	|INTO DepreciationOfVNA_Balance
	|
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|			&BegOfMonth,
	|			(Organization, FixedAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS FixedAssetsDepreciationCharge
	|
	|UNION ALL
	|
	|SELECT
	|	IntangibleAssetsAmortizationCharge.Organization AS Organization,
	|	IntangibleAssetsAmortizationCharge.IntangibleAsset AS AccountingObject,
	|	-IntangibleAssetsAmortizationCharge.DepreciationBalance AS Depreciation,
	|	-IntangibleAssetsAmortizationCharge.DepreciationLocalBalance AS DepreciationLocal,
	|	-IntangibleAssetsAmortizationCharge.DepreciationInTaxAccountingBalance AS DepreciationInTaxAccounting,
	|	-IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferencesBalance AS DepreciationPermanentDifferences,
	|	-IntangibleAssetsAmortizationCharge.DepreciationTDBalance AS DepreciationTD,
	|	-IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancingBalance AS FixedAssetDepreciationTargetFinancing,
	|	-IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancingBalance AS DepreciationTaxAccountingTargetFinancing,
	|	-IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPDBalance AS DepreciationTargetFinancingPD,
	|	-IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTDBalance AS DepreciationOfTargetFinancingTD,
	|	-IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveBalance AS DepreciationRevaluationReserve,
	|	-IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveLocalBalance AS DepreciationRevaluationReserveLocal
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge.Balance(
	|			&BegOfMonth,
	|			(Organization, IntangibleAsset) IN
	|				(SELECT
	|					TTDataToBeCalculated.Organization,
	|					TTDataToBeCalculated.AccountingObject
	|				FROM
	|					TTDataToBeCalculated AS TTDataToBeCalculated)) AS IntangibleAssetsAmortizationCharge
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region Vna_Depreciation
	QueryText = 
	"SELECT
	|	DepreciationOfVNA.Period AS Period,
	|	DepreciationOfVNA.Recorder AS Recorder,
	|	DepreciationOfVNA.Organization AS Organization,
	|	DepreciationOfVNA.FixedAsset AS AccountingObject,
	|	DepreciationOfVNA.AccountingProcedureMA AS AccountingProcedureMA,
	|	DepreciationOfVNA.AccountingProcedureAC AS AccountingProcedureAC,
	|	DepreciationOfVNA.ThisIsAnAdditionalAccrual OR DepreciationOfVNA.ThisIsAdditionalChargeAccounting AS ThisIsAnAdditionalAccrual,
	|
	|	CASE
	|		WHEN DepreciationOfVNA.ProcedureForCalculatingDepreciationOfMa = VALUE(Enum.DepreciationProcedure.EmptyRef)
	|			THEN ISNULL(AccountingPolicyOfMa.ProcedureOfFixedAssetDepreciationCharge, UNDEFINED)
	|		ELSE DepreciationOfVNA.ProcedureForCalculatingDepreciationOfMa 
	|	END AS ProcedureForCalculatingDepreciationOfMa,
	|
	|	CASE
	|		WHEN DepreciationOfVNA.ProcedureForCalculatingDepreciationAC = VALUE(Enum.DepreciationProcedure.EmptyRef)
	|			THEN ISNULL(AccountingPolicyOfBU.ProcedureOfFixedAssetDepreciationCharge, UNDEFINED)
	|		ELSE DepreciationOfVNA.ProcedureForCalculatingDepreciationAC 
	|	END AS ProcedureForCalculatingDepreciationAC,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.Depreciation 
	|		ELSE -DepreciationOfVNA.Depreciation 
	|	END AS Depreciation,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationLocal 
	|		ELSE -DepreciationOfVNA.DepreciationLocal 
	|	END AS DepreciationLocal,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationInTaxAccounting 
	|		ELSE -DepreciationOfVNA.DepreciationInTaxAccounting 
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationPermanentDifferences 
	|		ELSE -DepreciationOfVNA.DepreciationPermanentDifferences 
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationTD 
	|		ELSE -DepreciationOfVNA.DepreciationTD 
	|	END AS DepreciationTD,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|		ELSE -DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing 
	|		ELSE -DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing 
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationTargetFinancingPD 
	|		ELSE -DepreciationOfVNA.DepreciationTargetFinancingPD 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationOfTargetFinancingTD 
	|		ELSE -DepreciationOfVNA.DepreciationOfTargetFinancingTD 
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationRevaluationReserve 
	|		ELSE -DepreciationOfVNA.DepreciationRevaluationReserve 
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN DepreciationOfVNA.DepreciationRevaluationReserveLocal 
	|		ELSE -DepreciationOfVNA.DepreciationRevaluationReserveLocal 
	|	END AS DepreciationRevaluationReserveLocal
	|
	|INTO Vna_Depreciation
	|
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge AS DepreciationOfVNA
	|
	|		LEFT JOIN AccountingPolicyOfBU AS AccountingPolicyOfBU
	|		ON AccountingPolicyOfBU.Organization = DepreciationOfVNA.Organization.ParentCompany
	|
	|		LEFT JOIN AccountingPolicyOfMa AS AccountingPolicyOfMa
	|		ON AccountingPolicyOfMa.Organization = DepreciationOfVNA.Organization.ParentCompany
	|
	|WHERE
	|	DepreciationOfVNA.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND DepreciationOfVNA.Active
	|
	|	AND (DepreciationOfVNA.Organization, DepreciationOfVNA.FixedAsset) IN
	|			(SELECT
	|				TTDataToBeCalculated.Organization,
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|UNION ALL
	|
	|SELECT
	|	IntangibleAssetsAmortizationCharge.Period AS Period,
	|	IntangibleAssetsAmortizationCharge.Recorder AS Recorder,
	|	IntangibleAssetsAmortizationCharge.Organization AS Organization,
	|	IntangibleAssetsAmortizationCharge.IntangibleAsset AS AccountingObject,
	|	IntangibleAssetsAmortizationCharge.AccountingProcedureMA AS AccountingProcedureMA,
	|	IntangibleAssetsAmortizationCharge.AccountingProcedureAC AS AccountingProcedureAC,
	|	IntangibleAssetsAmortizationCharge.ThisIsAnAdditionalAccrual OR IntangibleAssetsAmortizationCharge.ThisIsAdditionalChargeAccounting AS ThisIsAnAdditionalAccrual,
	|
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.ProcedureForCalculatingDepreciationOfMa = VALUE(Enum.DepreciationProcedure.EmptyRef)
	|			THEN ISNULL(AccountingPolicyOfMa.ProcedureOfIntangibleAssetAmortizationCharge, UNDEFINED)
	|		ELSE IntangibleAssetsAmortizationCharge.ProcedureForCalculatingDepreciationOfMa 
	|	END AS ProcedureForCalculatingDepreciationOfMa,
	|
	|	CASE
	|		WHEN IntangibleAssetsAmortizationCharge.ProcedureForCalculatingDepreciationAC = VALUE(Enum.DepreciationProcedure.EmptyRef)
	|			THEN ISNULL(AccountingPolicyOfBU.ProcedureOfIntangibleAssetAmortizationCharge, UNDEFINED)
	|		ELSE IntangibleAssetsAmortizationCharge.ProcedureForCalculatingDepreciationAC 
	|	END AS ProcedureForCalculatingDepreciationAC,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.Depreciation 
	|		ELSE -IntangibleAssetsAmortizationCharge.Depreciation 
	|	END AS Depreciation,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationLocal 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationLocal 
	|	END AS DepreciationLocal,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationInTaxAccounting 
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences 
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationTD 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationTD 
	|	END AS DepreciationTD,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing 
	|		ELSE -IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancing 
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancing 
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationTargetFinancingPD 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationOfTargetFinancingTD 
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserve 
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE WHEN IntangibleAssetsAmortizationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|		THEN IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveLocal 
	|		ELSE -IntangibleAssetsAmortizationCharge.DepreciationRevaluationReserveLocal 
	|	END AS DepreciationRevaluationReserveLocal
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge AS IntangibleAssetsAmortizationCharge
	|
	|		LEFT JOIN AccountingPolicyOfBU AS AccountingPolicyOfBU
	|		ON AccountingPolicyOfBU.Organization = IntangibleAssetsAmortizationCharge.Organization.ParentCompany
	|
	|		LEFT JOIN AccountingPolicyOfMa AS AccountingPolicyOfMa
	|		ON AccountingPolicyOfMa.Organization = IntangibleAssetsAmortizationCharge.Organization.ParentCompany
	|
	|WHERE
	|	IntangibleAssetsAmortizationCharge.Period BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND IntangibleAssetsAmortizationCharge.Active
	|
	|	AND (IntangibleAssetsAmortizationCharge.Organization, IntangibleAssetsAmortizationCharge.IntangibleAsset) IN
	|			(SELECT
	|				TTDataToBeCalculated.Organization,
	|				TTDataToBeCalculated.AccountingObject
	|			FROM
	|				TTDataToBeCalculated AS TTDataToBeCalculated)
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region TT_DepreciationOfVNA
	QueryText =
	"SELECT
	|	DataForCalculation.Ref AS Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization AS Organization,
	|	DataForCalculation.AccountingObject AS AccountingObject,
	|	DataForCalculation.AccrueDepreciation AS AccrueDepreciation,
	|	SUM(DataForCalculation.Depreciation) AS Depreciation,
	|	SUM(DataForCalculation.DepreciationLocal) AS DepreciationLocal,
	|	SUM(DataForCalculation.DepreciationInTaxAccounting) AS DepreciationInTaxAccounting,
	|	SUM(DataForCalculation.DepreciationPermanentDifferences) AS DepreciationPermanentDifferences,
	|	SUM(DataForCalculation.DepreciationTD) AS DepreciationTD,
	|	SUM(DataForCalculation.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing,
	|	SUM(DataForCalculation.DepreciationTaxAccountingTargetFinancing) AS DepreciationTaxAccountingTargetFinancing,
	|	SUM(DataForCalculation.DepreciationTargetFinancingPD) AS DepreciationTargetFinancingPD,
	|	SUM(DataForCalculation.DepreciationOfTargetFinancingTD) AS DepreciationOfTargetFinancingTD,
	|	SUM(DataForCalculation.DepreciationRevaluationReserve) AS DepreciationRevaluationReserve,
	|	SUM(DataForCalculation.DepreciationRevaluationReserveLocal) AS DepreciationRevaluationReserveLocal
	|
	|INTO TT_DepreciationOfVNA
	|
	|FROM
	|	(SELECT
	|		DataForCalculation.Ref AS Ref,
	|		DataForCalculation.Date AS Date,
	|		DataForCalculation.Organization AS Organization,
	|		DataForCalculation.AccountingObject AS AccountingObject,
	|		ISNULL(DepreciationOfVNA.Depreciation, 0) AS Depreciation,
	|		ISNULL(DepreciationOfVNA.DepreciationLocal, 0) AS DepreciationLocal,
	|		ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0) AS DepreciationInTaxAccounting,
	|		ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0) AS DepreciationPermanentDifferences,
	|		ISNULL(DepreciationOfVNA.DepreciationTD, 0) AS DepreciationTD,
	|		ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) AS FixedAssetDepreciationTargetFinancing,
	|		ISNULL(DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing, 0) AS DepreciationTaxAccountingTargetFinancing,
	|		ISNULL(DepreciationOfVNA.DepreciationTargetFinancingPD, 0) AS DepreciationTargetFinancingPD,
	|		ISNULL(DepreciationOfVNA.DepreciationOfTargetFinancingTD, 0) AS DepreciationOfTargetFinancingTD,
	|		ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0) AS DepreciationRevaluationReserve,
	|		ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0) AS DepreciationRevaluationReserveLocal,
	|		NOT WearAccrual.AccountingObject IS NULL AS AccrueDepreciation
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN DepreciationOfVNA_Balance AS DepreciationOfVNA
	|			ON (DepreciationOfVNA.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (DepreciationOfVNA.Organization = DataForCalculation.Organization)
	|
	|			LEFT JOIN WearAccrual AS WearAccrual
	|			ON WearAccrual.AccountingObject = DataForCalculation.AccountingObject
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataForCalculation.Ref,
	|		DataForCalculation.Date,
	|		DataForCalculation.Organization,
	|		DataForCalculation.AccountingObject,
	|
	|		CASE 
	|			WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|					OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|						AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|							OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|					OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|					OR ISNULL(DepreciationOfVNA.AccountingProcedureMA, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|					OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationOfMa, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|				THEN ISNULL(DepreciationOfVNA.Depreciation, 0)
	| 
	|			ELSE 0
	|		END AS Depreciation,
	|
	|		CASE
	|			WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|					OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|						AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|							OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|					OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|					OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|					OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|				THEN ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|
	|			ELSE 0
	|		END AS DepreciationLocal,
	|
	|		ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0) AS DepreciationInTaxAccounting,
	|
	|		CASE
	|			WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|					OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|						AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|							OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|					OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|					OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|					OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|				THEN ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0)
	|
	|			ELSE 0
	|		END AS DepreciationPermanentDifferences,
	|
	|		CASE
	|			WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|					OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|						AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|							OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|					OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|					OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|					OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|				THEN ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|
	|			ELSE 0
	|		END 
	|			- ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0) 
	|			- CASE
	|					WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|						OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|							AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|								OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|						OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|						OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|						OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|					THEN ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0)
	|
	|				ELSE 0
	|			END AS DepreciationTD,
	|
	|		CASE
	|			WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|					OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|						AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|							OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|					OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|					OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|					OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|				THEN ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|
	|			ELSE 0
	|		END AS FixedAssetDepreciationTargetFinancing,
	|
	|		ISNULL(DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing, 0) AS DepreciationTaxAccountingTargetFinancing,
	|
	|		CASE
	|			WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|					OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|						AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|							OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|					OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|					OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|					OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|				THEN ISNULL(DepreciationOfVNA.DepreciationTargetFinancingPD, 0)
	|
	|			ELSE 0
	|		END AS DepreciationTargetFinancingPD,
	|
	|		CASE
	|			WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|					OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|						AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|							OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|					OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|					OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|					OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|				THEN ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|
	|			ELSE 0
	|		END 
	|			- ISNULL(DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing, 0) 
	|			- CASE
	|					WHEN ISNULL(BEGINOFPERIOD(DepreciationOfVNA.Period, DAY), DATETIME(1, 1, 1)) < BEGINOFPERIOD(DataForCalculation.Date, DAY)
	|						OR ISNULL(DepreciationOfVNA.Period, DATETIME(1, 1, 1)) < DataForCalculation.Date
	|							AND (NOT VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4))
	|								OR VALUETYPE(DataForCalculation.Ref) IN (&TypesOfWriteOffDocuments))
	|						OR ISNULL(DepreciationOfVNA.ThisIsAnAdditionalAccrual, FALSE) 
	|						OR ISNULL(DepreciationOfVNA.AccountingProcedureAC, UNDEFINED) = VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards)
	|						OR ISNULL(DepreciationOfVNA.ProcedureForCalculatingDepreciationAC, UNDEFINED) = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
	|
	|					THEN ISNULL(DepreciationOfVNA.DepreciationTargetFinancingPD, 0)
	|
	|				ELSE 0
	|			END AS DepreciationOfTargetFinancingTD,
	|
	|		ISNULL(DepreciationOfVNA.DepreciationRevaluationReserve, 0),
	|		ISNULL(DepreciationOfVNA.DepreciationRevaluationReserveLocal, 0),
	|		NOT WearAccrual.AccountingObject IS NULL AS AccrueDepreciation
	|
	|	FROM
	|		TTDataToBeCalculated AS DataForCalculation
	|
	|			LEFT JOIN Vna_Depreciation AS DepreciationOfVNA
	|			ON (DepreciationOfVNA.AccountingObject = DataForCalculation.AccountingObject)
	|				AND (DepreciationOfVNA.Organization = DataForCalculation.Organization)
	|				AND (DepreciationOfVNA.Recorder <> DataForCalculation.Ref)
	|				AND (DepreciationOfVNA.Period <= DataForCalculation.Date
	|					OR VALUETYPE(DepreciationOfVNA.Recorder) IN (TYPE(Document.FixedAssetsDepreciationCharge2_4), TYPE(Document.IntangibleAssetsAmortizationCharge2_4)))
	|
	|			LEFT JOIN WearAccrual AS WearAccrual
	|			ON WearAccrual.AccountingObject = DataForCalculation.AccountingObject
	|
	|	) AS DataForCalculation
	|
	|GROUP BY
	|	DataForCalculation.Ref,
	|	DataForCalculation.Date,
	|	DataForCalculation.Organization,
	|	DataForCalculation.AccountingObject,
	|	DataForCalculation.AccrueDepreciation
	|
	|HAVING
	|	SUM(DataForCalculation.Depreciation) <> 0
	|		OR SUM(DataForCalculation.DepreciationLocal) <> 0
	|		OR SUM(DataForCalculation.DepreciationInTaxAccounting) <> 0
	|		OR SUM(DataForCalculation.DepreciationPermanentDifferences) <> 0
	|		OR SUM(DataForCalculation.DepreciationTD) <> 0
	|		OR SUM(DataForCalculation.FixedAssetDepreciationTargetFinancing) <> 0
	|		OR SUM(DataForCalculation.DepreciationTaxAccountingTargetFinancing) <> 0
	|		OR SUM(DataForCalculation.DepreciationTargetFinancingPD) <> 0
	|		OR SUM(DataForCalculation.DepreciationOfTargetFinancingTD) <> 0
	|		OR SUM(DataForCalculation.DepreciationRevaluationReserve) <> 0
	|		OR SUM(DataForCalculation.DepreciationRevaluationReserveLocal) <> 0
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject,
	|	Organization";
	
	ListOfRequests.Add(QueryText);
	
	#EndRegion
	
	#Region TT_DepreciationForPeriod
	
	QueryText =
	"SELECT
	|	DataForCalculation.Ref AS Ref,
	|	DataForCalculation.AccountingObject AS AccountingObject,
	|	MIN(BEGINOFPERIOD(AdjustmentOfFADepreciation.BeginOfPeriod, MONTH)) AS BeginOfPeriod,
	|	MAX(BEGINOFPERIOD(DataForCalculation.Date, MONTH)) AS EndOfPeriod
	|
	|INTO TTIsAdjustmentPeriod
	|
	|FROM
	|	TTDataToBeCalculated AS DataForCalculation
	|
	|		INNER JOIN Document.FixedAssetCostAndDepreciationAdjustment AS AdjustmentOfFADepreciation
	|		ON AdjustmentOfFADepreciation.Ref = DataForCalculation.Ref
	|
	|WHERE
	|	AdjustmentOfFADepreciation.AdjustmentModeFromPreviousDate
	|	AND AdjustmentOfFADepreciation.DepreciationAdjustmentForPeriod
	|
	|GROUP BY
	|	DataForCalculation.Ref,
	|	DataForCalculation.AccountingObject
	|
	|INDEX BY
	|	BeginOfPeriod,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DepreciationForPeriod.Ref AS Ref,
	|	DepreciationForPeriod.EndOfMonth AS EndOfMonth,
	|	DepreciationForPeriod.AccountingObject AS AccountingObject,
	|
	|	SUM(DepreciationForPeriod.Depreciation) AS Depreciation,
	|	SUM(DepreciationForPeriod.DepreciationLocal) AS DepreciationLocal,
	|	SUM(DepreciationForPeriod.DepreciationInTaxAccounting) AS DepreciationInTaxAccounting,
	|	SUM(DepreciationForPeriod.DepreciationPermanentDifferences) AS DepreciationPermanentDifferences,
	|	SUM(DepreciationForPeriod.FixedAssetDepreciationTargetFinancing) AS FixedAssetDepreciationTargetFinancing
	|
	|INTO TT_DepreciationForPeriod
	|
	|FROM
	|	(SELECT
	|		TTIsAdjustmentPeriod.Ref AS Ref,
	|		ENDOFPERIOD(DepreciationOfVNA.Period, MONTH) AS EndOfMonth,
	|		DepreciationOfVNA.FixedAsset AS AccountingObject,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.Depreciation 
	|			ELSE -DepreciationOfVNA.Depreciation 
	|		END AS Depreciation,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.DepreciationLocal 
	|			ELSE -DepreciationOfVNA.DepreciationLocal 
	|		END AS DepreciationLocal,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.DepreciationInTaxAccounting 
	|			ELSE -DepreciationOfVNA.DepreciationInTaxAccounting 
	|		END AS DepreciationInTaxAccounting,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.DepreciationPermanentDifferences 
	|			ELSE -DepreciationOfVNA.DepreciationPermanentDifferences 
	|		END AS DepreciationPermanentDifferences,
	|
	|		CASE WHEN DepreciationOfVNA.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|			ELSE -DepreciationOfVNA.FixedAssetDepreciationTargetFinancing 
	|		END AS FixedAssetDepreciationTargetFinancing
	|
	|	FROM
	|		TTIsAdjustmentPeriod AS TTIsAdjustmentPeriod
	|
	|			INNER JOIN AccumulationRegister.FixedAssetsDepreciationCharge AS DepreciationOfVNA
	|			ON DepreciationOfVNA.FixedAsset = TTIsAdjustmentPeriod.AccountingObject
	|				AND DepreciationOfVNA.Period >= TTIsAdjustmentPeriod.BeginOfPeriod
	|				AND DepreciationOfVNA.Period < TTIsAdjustmentPeriod.EndOfPeriod
	|				AND DepreciationOfVNA.Recorder <> TTIsAdjustmentPeriod.Ref
	|				AND DepreciationOfVNA.Active
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS Adjusting
	|			ON Adjusting.Ref = DepreciationOfVNA.Recorder
	|
	|		WHERE
	|			Adjusting.Ref IS NULL
	|				OR Adjusting.DocumentBasis = UNDEFINED
	|					AND NOT Adjusting.DocumentBasis REFS Document.MergeOfFixedAssets
	|					AND NOT Adjusting.DocumentBasis REFS Document.SplitFixedAssets
	|					AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsCostAdditions2_4
	|					AND NOT Adjusting.DocumentBasis REFS Document.AllocateVariancesToFixedAssetCost
	|					AND NOT Adjusting.DocumentBasis REFS Document.FARevaluation2_4
	|					AND NOT Adjusting.DocumentBasis REFS Document.FixedAssetsInitialRecognition2_4
	|
	|	) AS DepreciationForPeriod
	|
	|GROUP BY
	|	DepreciationForPeriod.Ref,
	|	DepreciationForPeriod.EndOfMonth,
	|	DepreciationForPeriod.AccountingObject
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject,
	|	EndOfMonth
	|";
	
	ListOfRequests.Add(QueryText);

	#EndRegion
	
	ImpairmentFAServer.ToSupplementParametersOfDelayedFormationOfRegisteredRecorded(ListOfRequests, TTUsed);
	LeasedAssetAccounting.ToSupplementParametersOfDelayedFormationOfRegisteredRecorded(ListOfRequests, TTUsed);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BegOfMonth", BegOfMonth(Period));
	Query.SetParameter("EndOfMonth", EndOfMonth(Period));
	Query.SetParameter("EndOfPreviousMonth", BegOfMonth(Period)-1);
	Query.SetParameter("DocumentTypes", NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	Query.SetParameter("TypesOfDocumentsThatCanAccrueDepreciation", TypesOfDocumentsThatCanAccrueDepreciation());
	Query.SetParameter("TypesOfDocumentsThatChangeValueAtEndOfMonth", TypesOfDocumentsThatChangeValueAtEndOfMonth());
	Query.SetParameter("TypesOfWriteOffDocuments", TypesOfWriteOffDocuments());
	Query.SetParameter("LocalFAAccounting", GetFunctionalOption("LocalFAAccounting"));
	
	Query.Execute();
	
	DataVolume = NonCurrentAssets.NumberOfDataToBeCalculated(TempTablesManager);

	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

Function PrepareTablesOfRegisteredRecords(Period, TempTablesManager)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.PrepareTablesOfRegisteredRecords");

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
	|	CASE
	|		WHEN VALUETYPE(TTPortionOfDataToBeCalculated.Ref) IN (&TypesOfDocumentsThatDoNotSupportBatchMode)
	|			THEN TTPortionOfDataToBeCalculated.Ref
	|		ELSE VALUETYPE(TTPortionOfDataToBeCalculated.Ref) 
	|	END AS DocumentTypeOrLink
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	TypesOfDocumentsThatDoNotSupportBatchMode = TypesOfDocumentsThatDoNotSupportBatchMode();
	Query.SetParameter("TypesOfDocumentsThatDoNotSupportBatchMode", TypesOfDocumentsThatDoNotSupportBatchMode);
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound()-1].Select();
	Selection.Next();
	DataVolume = Selection.Count;
	
	MovementTables = New Map;
	
	Selection = Result[Result.UBound()].Select();
	While Selection.Next() Do
		
		If TypesOfDocumentsThatDoNotSupportBatchMode.Find(TypeOf(Selection.DocumentTypeOrLink)) <> Undefined Then
			
			ManagerOfDocument = Documents[Metadata.FindByType(TypeOf(Selection.DocumentTypeOrLink)).Name];
			TablesOfRegisteredRecordsOfDocuments = ManagerOfDocument.TablesOfDeferredMotionFormation(Selection.DocumentTypeOrLink, TempTablesManager); // Structure
			
		Else
			
			ManagerOfDocument = Documents[Metadata.FindByType(Selection.DocumentTypeOrLink).Name];
			
			If Selection.DocumentTypeOrLink = Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment")
				Or Selection.DocumentTypeOrLink = Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment") Then
				
				TablesOfRegisteredRecordsOfDocuments = ManagerOfDocument.TablesOfDeferredMotionFormation(Period, TempTablesManager); // Structure
			Else	
				TablesOfRegisteredRecordsOfDocuments = ManagerOfDocument.TablesOfDeferredMotionFormation(TempTablesManager); // Structure
			EndIf;
			
			For Each KeyAndValue In TablesOfRegisteredRecordsOfDocuments Do
	
				RegisterName = NonCurrentAssetsInternal.NameOfRegisterByNameOfRegisteredRecordsTable(KeyAndValue.Key);
				
				If Metadata.InformationRegisters.Find(RegisterName) <> Undefined 
					Or Metadata.AccumulationRegisters.Find(RegisterName) <> Undefined Then
				
					Table = KeyAndValue.Value; // ValueTable
					Table.Indexes.Add("Recorder");
	
				EndIf;
				
			EndDo;
		
		EndIf;
		
		MovementTables.Insert(Selection.DocumentTypeOrLink, TablesOfRegisteredRecordsOfDocuments);
		
		TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	EndDo;
	
	TTUsed.Delete(TTUsed.Find("TTListOfDocuments"));
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

	Return MovementTables;
	
EndFunction

Procedure WriteMotionTables(MovementTables, ExecutionParameters)

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.WriteMotionTables");

	TTUsed = TMCommonUse.ListOfTemporaryTables(ExecutionParameters.TempTablesManager);
	
	TypesOfDocumentsThatDoNotSupportBatchMode = TypesOfDocumentsThatDoNotSupportBatchMode();

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
			SetFlagForOperation(DocumentObject, ExecutionParameters.OperationName);
			
			If TypesOfDocumentsThatDoNotSupportBatchMode.Find(TypeOf(Selection.Ref)) <> Undefined Then
				TablesOfRegisteredRecordsOfDocuments = MovementTables.Get(Selection.Ref);
			Else
				TablesOfRegisteredRecordsOfDocuments = MovementTables.Get(TypeOf(Selection.Ref));
			EndIf;
			
			NonCurrentAssetsInternal.WriteMotionTables(
				TablesOfRegisteredRecordsOfDocuments, 
				DocumentObject, 
				ExecutionParameters.TempTablesManager,
				ExecutionParameters.ReturnDocumentsToReflection, 
				ExecutionParameters.OperationName);
				
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
	
	NonCurrentAssetsInternal.ReflectInManagementBalanceSheet(MovementTables, ExecutionParameters.TempTablesManager);
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

Procedure RegisterErrors(Period, ExecutionParameters)

	If Not ValueIsFilled(ExecutionParameters.ExecuteCheck) Then
		Return;
	EndIf;

	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.RegisterErrors");
	
	TTUsed = TMCommonUse.ListOfTemporaryTables(ExecutionParameters.TempTablesManager);
	TTUsed.Add("TTErrors");
	
	Documents_With_Errors = New Array;
	
	Query = New Query();
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	Query.SetParameter("BegOfMonth", BegOfMonth(ExecutionParameters.EndOfPeriod));
	Query.SetParameter("EndOfMonth", EndOfMonth(ExecutionParameters.EndOfPeriod));
	Query.SetParameter("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	#Region NoItemOfExpenditureInImplementationSpecified
	QueryText =
	"SELECT DISTINCT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref,
	|	TTPortionOfDataToBeCalculated.Organization AS Organization,
	|	DocumentTable.Number AS DocumentNumber,
	|	DocumentTable.Date AS DocumentDate,
	|	TTPortionOfDataToBeCalculated.Date AS Date,
	|	TableExpenses.NonCurrentAsset AS NonCurrentAsset,
	|	ISNULL(TableExpenses.LineNumber, 0) AS LineNumber
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|		LEFT JOIN Document.CustomerInvoiceServicesAndAssets AS DocumentTable
	|		ON (DocumentTable.Ref = TTPortionOfDataToBeCalculated.Ref)
	|
	|		LEFT JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS TableExpenses
	|		ON (TableExpenses.Ref = TTPortionOfDataToBeCalculated.Ref)
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON (CostOfVNA.Ref = TableExpenses.Ref)
	|			AND (CostOfVNA.AccountingObject = TableExpenses.NonCurrentAsset)
	|WHERE
	|	VALUETYPE(TTPortionOfDataToBeCalculated.Ref) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|	AND TableExpenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	AND NOT CostOfVNA.Ref IS NULL
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		Documents_With_Errors.Add(Selection.Ref);
		
		IssueDetails = NStr("vi = 'Trong chứng từ Bán hàng dịch vụ và các tài sản khác Số %1 ngày %2 cho tài sản dài hạn %3, cần chỉ ra dạng chi phí mà sẽ ghi giảm chi phí vào đó.';
							|ru = 'В документе Реализация услуг и прочих активов №%1 от %2 для внеоборотного актива %3 необходимо указать статью расходов, на которую будет списана стоимость.';
							|en = 'Specify an expense item to which the cost will be written off in the ""Customer invoice — Services and Assets"" document No. %1 dated %2 for the %3 fixed asset.'; fa = 'Specify an expense item to which the cost will be written off in the ""Customer invoice — Services and Assets"" document No. %1 dated %2 for the %3 fixed asset.';
							|it = 'Nel documento Vendita servizi e altri attivi №%1 di %2 per l''attivo non circolante %3è necessario indicare la voce di spesa alla quale sarà stornato il costo.';
							|pl = 'W dokumencie Realizacja usług i innych aktywów nr%1 z dnia %2 dla aktywu nieobrotowego%3 należy wskazać pozycję rozchodów, na którą będzie rozchodowana wartość.';
							|tr = 'Duran varlık %3 için %2''nin %1 numaralı hizmet ve diğer varlıkların satışı belgesinde maliyetin silineceği gider kaleminin belirtilmesi gerekmektedir.'");
		IssueDetails = StrTemplate(IssueDetails, 
									Selection.DocumentNumber, 
									Format(Selection.DocumentDate, "DLF=D"), 
									Selection.NonCurrentAsset);
		
		NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
			Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords, 
			Period,
			Selection.Organization,
			IssueDetails,,
			Selection.Ref);
				
	EndDo; 
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);

	#EndRegion
	
	#Region CostOfNewFAExceedsCostOfOriginal
	QueryText =
	"SELECT DISTINCT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref
	|
	|INTO TT_SplitFixedAssets
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|WHERE
	|	VALUETYPE(TTPortionOfDataToBeCalculated.Ref) = TYPE(Document.SplitFixedAssets)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.FixedAsset AS FixedAsset,
	|	DocumentData.WriteOffNodes AS WriteOffNodes
	|
	|INTO TableVNA
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (SELECT T.Ref FROM TT_SplitFixedAssets AS T)
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableVNA.Ref AS Ref,
	|	TableVNA.Date AS Date,
	|	TableVNA.FixedAsset AS FixedAsset,
	|	RegisterData.SubAssetComponent AS SubAssetComponent
	|
	|INTO TableAllNodesComponentsOfDepreciation
	|
	|FROM
	|	TableVNA AS TableVNA
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.FixedAsset = TableVNA.FixedAsset
	|			AND RegisterData.Period <= TableVNA.Date
	|			AND RegisterData.Recorder <> TableVNA.Ref
	|			AND RegisterData.Active
	|
	|WHERE
	|	TableVNA.WriteOffNodes
	|		OR RegisterData.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
	|
	|INDEX BY
	|	SubAssetComponent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableAllNodesComponentsOfDepreciation.Ref AS Ref,
	|	TableAllNodesComponentsOfDepreciation.FixedAsset AS FixedAsset,
	|	TableAllNodesComponentsOfDepreciation.SubAssetComponent AS SubAssetComponent,
	|	MAX(RegisterData.Period) AS Period
	|
	|INTO RegisterData_Period
	|
	|FROM
	|	TableAllNodesComponentsOfDepreciation AS TableAllNodesComponentsOfDepreciation
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = TableAllNodesComponentsOfDepreciation.SubAssetComponent
	|			AND RegisterData.Period <= TableAllNodesComponentsOfDepreciation.Date
	|			AND RegisterData.Recorder <> TableAllNodesComponentsOfDepreciation.Ref
	|			AND RegisterData.Active
	|
	|GROUP BY
	|	TableAllNodesComponentsOfDepreciation.Ref,
	|	TableAllNodesComponentsOfDepreciation.FixedAsset,
	|	TableAllNodesComponentsOfDepreciation.SubAssetComponent
	|
	|INDEX BY
	|	SubAssetComponent,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData_Period.Ref AS Ref,
	|	RegisterData_Period.FixedAsset AS FixedAsset,
	|	RegisterData_Period.SubAssetComponent AS SubAssetComponent,
	|	RegisterData_Period.Period AS Period,
	|	MAX(RegisterData.Recorder) AS Recorder
	|
	|INTO RegisterData_Recorder
	|
	|FROM
	|	RegisterData_Period AS RegisterData_Period
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = RegisterData_Period.SubAssetComponent
	|			AND RegisterData.Period = RegisterData_Period.Period
	|			AND RegisterData.Recorder <> RegisterData_Period.Ref
	|			AND RegisterData.Active
	|
	|GROUP BY
	|	RegisterData_Period.Ref,
	|	RegisterData_Period.FixedAsset,
	|	RegisterData_Period.SubAssetComponent,
	|	RegisterData_Period.Period
	|
	|INDEX BY
	|	SubAssetComponent,
	|	Period,
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData_Recorder.Ref AS Ref,
	|	RegisterData_Recorder.SubAssetComponent AS SubAssetComponent,
	|	RegisterData.FixedAsset AS FixedAsset
	|
	|INTO SubAssetsComponentsOfDepreciation
	|
	|FROM
	|	RegisterData_Recorder AS RegisterData_Recorder
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = RegisterData_Recorder.SubAssetComponent
	|			AND RegisterData.Period = RegisterData_Recorder.Period
	|			AND RegisterData.Recorder = RegisterData_Recorder.Recorder
	|			AND RegisterData.FixedAsset = RegisterData_Recorder.FixedAsset
	|			AND RegisterData.Active
	|
	|INDEX BY
	|	Ref,
	|	SubAssetComponent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_SplitFixedAssets.Ref AS Ref,
	|	SUM(FATable.CostInAccounting) AS CostInAccounting,
	|	SUM(FATable.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(FATable.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(FATable.CostInManagementAccounting) AS CostInManagementAccounting
	|
	|INTO TT_TotalCostOfNewFA
	|
	|FROM
	|
	|	TT_SplitFixedAssets AS TT_SplitFixedAssets
	|
	|		INNER JOIN Document.SplitFixedAssets.FA AS FATable
	|		ON FATable.Ref = TT_SplitFixedAssets.Ref
	|
	|GROUP BY
	|	TT_SplitFixedAssets.Ref
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FACost.Ref AS Ref,
	|	SUM(FACost.CostInAccounting) AS CostInAccounting,
	|	SUM(FACost.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(FACost.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(FACost.CostInManagementAccounting) AS CostInManagementAccounting
	|
	|INTO TT_TotalCostOfOriginalFA
	|
	|FROM
	|	(SELECT
	|		TT_SplitFixedAssets.Ref AS Ref,
	|		FACost.LocalCost + FACost.CostTargetFinancing AS CostInAccounting,
	|		FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA AS CostInTaxAccounting,
	|		FACost.CostPermanentDifference + FACost.CostTargetFinancingPD AS CostPermanentDifference,
	|		FACost.Cost AS CostInManagementAccounting
	|	FROM
	|
	|		TT_SplitFixedAssets AS TT_SplitFixedAssets
	|
	|			INNER JOIN Document.SplitFixedAssets AS DocumentTable
	|			ON DocumentTable.Ref = TT_SplitFixedAssets.Ref
	|
	|			INNER JOIN TT_CostOfVNA AS FACost
	|			ON FACost.Ref = DocumentTable.Ref
	|				AND FACost.AccountingObject = DocumentTable.FixedAsset
	|
	|	UNION ALL
	|
	|	SELECT
	|		SubAssetsComponentsOfDepreciation.Ref AS Ref,
	|		FACost.LocalCost + FACost.CostTargetFinancing AS CostInAccounting,
	|		FACost.CostInTaxAccounting + FACost.CostTargetFinancingTA AS CostInTaxAccounting,
	|		FACost.CostPermanentDifference + FACost.CostTargetFinancingPD AS CostPermanentDifference,
	|		FACost.Cost AS CostInManagementAccounting
	|	FROM
	|
	|		SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|
	|			INNER JOIN TT_CostOfVNA AS FACost
	|			ON FACost.Ref = SubAssetsComponentsOfDepreciation.Ref
	|				AND FACost.AccountingObject = SubAssetsComponentsOfDepreciation.SubAssetComponent
	|
	|	) AS FACost
	|
	|GROUP BY
	|	FACost.Ref
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.BusinessOperation AS BusinessOperation,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Number AS DocumentNumber,
	|	DocumentTable.Date AS DocumentDate,
	|	DocumentTable.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentTable.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentTable.WriteOffNodes AS WriteOffNodes,
	|
	|	ISNULL(TotalCostOfNewFA.CostInAccounting, 0) AS TotalCostOfAC,
	|	ISNULL(TotalCostOfNewFA.CostInTaxAccounting, 0) AS TotalCostTa,
	|	ISNULL(TotalCostOfNewFA.CostPermanentDifference, 0) AS TotalCostOfPD,
	|	ISNULL(TotalCostOfNewFA.CostInManagementAccounting, 0) AS TotalCostOfMa,
	|
	|	ISNULL(TotalCostOfOriginalFA.CostInAccounting, 0) AS InitialCostOfAC,
	|	ISNULL(TotalCostOfOriginalFA.CostInTaxAccounting, 0) AS InitialCostTa_,
	|	ISNULL(TotalCostOfOriginalFA.CostPermanentDifference, 0) AS InitialCostOfPD,
	|	ISNULL(TotalCostOfOriginalFA.CostInManagementAccounting, 0) AS InitialCostOfMa
	|
	|FROM
	|	TT_SplitFixedAssets AS TT_SplitFixedAssets
	|
	|		INNER JOIN Document.SplitFixedAssets AS DocumentTable
	|		ON (DocumentTable.Ref = TT_SplitFixedAssets.Ref)
	|
	|		LEFT JOIN TT_TotalCostOfNewFA AS TotalCostOfNewFA
	|		ON (TotalCostOfNewFA.Ref = DocumentTable.Ref)
	|
	|		LEFT JOIN TT_TotalCostOfOriginalFA AS TotalCostOfOriginalFA
	|		ON (TotalCostOfOriginalFA.Ref = DocumentTable.Ref)
	|
	|WHERE
	|	DocumentTable.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit), 
	|				VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|		AND (ISNULL(TotalCostOfNewFA.CostInManagementAccounting, 0) >= ISNULL(TotalCostOfOriginalFA.CostInManagementAccounting, 0)
	|					AND DocumentTable.RecordInManAccounting
	|			OR ISNULL(TotalCostOfNewFA.CostInAccounting, 0) >= ISNULL(TotalCostOfOriginalFA.CostInAccounting, 0)
	|					AND DocumentTable.RecordInLocalAccounting
	|			OR ISNULL(TotalCostOfNewFA.CostInTaxAccounting, 0) >= ISNULL(TotalCostOfOriginalFA.CostInTaxAccounting, 0)
	|					AND DocumentTable.RecordInLocalAccounting)
	|
	|	OR DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|		AND (ISNULL(TotalCostOfNewFA.CostInManagementAccounting, 0) <> ISNULL(TotalCostOfOriginalFA.CostInManagementAccounting, 0)
	|					AND DocumentTable.RecordInManAccounting
	|			OR ISNULL(TotalCostOfNewFA.CostInAccounting, 0) <> ISNULL(TotalCostOfOriginalFA.CostInAccounting, 0)
	|					AND DocumentTable.RecordInLocalAccounting
	|			OR ISNULL(TotalCostOfNewFA.CostInTaxAccounting, 0) <> ISNULL(TotalCostOfOriginalFA.CostInTaxAccounting, 0)
	|					AND DocumentTable.RecordInLocalAccounting
	|			OR ISNULL(TotalCostOfNewFA.CostPermanentDifference, 0) <> ISNULL(TotalCostOfOriginalFA.CostPermanentDifference, 0)
	|					AND DocumentTable.RecordInLocalAccounting)
	|
	|ORDER BY
	|	Organization,
	|	DocumentDate,
	|	Number,
	|	Ref
	|";
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	CurrencyOfMan = String(Constants.ManagementAccountingCurrency.Get());
	
	While Selection.Next() Do
		
		#Region MA
		If (Selection.BusinessOperation = Enums.BusinessTransactions.PartialFixedAssetsSplit
			Or Selection.BusinessOperation = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
			And Selection.TotalCostOfMa >= Selection.InitialCostOfMa
			And Selection.TotalCostOfMa <> 0
			And Selection.RecordInManAccounting Then
			
			Documents_With_Errors.Add(Selection.Ref);
			
			IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số%1 ngày %2, tổng chi phí được chấp nhận cho TSCĐ kế toán trong kế toán quản trị (%3%4) phải thấp hơn chi phí của TSCĐ gốc (%5%6).';
								|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в управленческом учете (%3 %4) должна быть меньше стоимости исходного ОС (%5 %6).';
								|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be less than the original fixed asset value (%5 %6).'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be less than the original fixed asset value (%5 %6).';
								|it = 'Nel documento Smantellamento del capitale fisso №%1 di %2 il costo complessivo preso in considerazione per il capitale fisso nella contabilità gestionale (%3 %4) deve essere inferiore al prezzo iniziale del capitale fisso (%5%6).';
								|pl = 'W dokumencie Dokompletowanie środku trwałego nr.%1 z dnia %2 wartość ogólna, przyjmowanych do ewidencji środków trwałych w ewidencji zarządczej (%3 %4) musi być mniej wartości źródłowego środku trwałego (%5 %6).';
								|tr = '%2''nin %1 numaralı Sabit kıymetlerin Ayrılması belgesinde, yönetim muhasebesinde muhasebeleştirilmek üzere kabul edilen sabit kıymetlerin toplam maliyeti (%3 %4), orijinal sabit kıymetin maliyetinden (%5 %6) daha az olmalıdır.'");
			
			IssueDetails = StrTemplate(IssueDetails, 
										Selection.DocumentNumber, 
										Format(Selection.DocumentDate, "DLF=D"), 
										Selection.TotalCostOfMa,
										CurrencyOfMan,
										Selection.InitialCostOfMa,
										CurrencyOfMan);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
			
		EndIf; 
				
		If Selection.BusinessOperation = Enums.BusinessTransactions.CompleteSplitFixedAssets
			And Selection.TotalCostOfMa <> Selection.InitialCostOfMa
			And Selection.RecordInManAccounting Then
			
			Documents_With_Errors.Add(Selection.Ref);
			
			If Selection.WriteOffNodes Then
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số%1 ngày %2, tổng chi phí được tiếp nhận vào kế toán TSCĐ trong kế toán quản trị (%3 %4) phải bằng chi phí của TSCĐ gốc (%5 %6) có tính đến giá trị của các cụm linh kiện và thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в управленческом учете (%3 %4) должна равняться стоимости исходного ОС (%5 %6) с учетом стоимости узлов и компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.';
									|it = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Ayrılması belgesinde, yönetim muhasebesinde muhasebeleştirilecek sabit kıymetlerin toplam maliyeti (%3 %4), alt ünitelerin ve amortisman unsurlarının maliyeti dikkate alınarak orijinal sabit kıymetin maliyetine (%5 %6) eşit olmalıdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số%1 ngày %2, tổng chi phí được tiếp nhận vào kế toán TSCĐ trong kế toán quản trị (%3 %4) phải bằng chi phí của TSCĐ gốc (%5 %6) có tính đến giá trị của các thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в управленческом учете (%3 %4) должна равняться стоимости исходного ОС (%5 %6) с учетом стоимости компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|it = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in management accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Parçalara Ayrılması belgesinde, yönetim muhasebesinde muhasebeleştirilecek sabit kıymetlerin toplam maliyeti (%3%4), amortisman bileşenlerinin maliyeti dikkate alınarak orijinal sabit kıymetin maliyetine (%5%6) eşit olmalıdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, 
										Selection.DocumentNumber, 
										Format(Selection.DocumentDate, "DLF=D"), 
										Selection.TotalCostOfMa,
										CurrencyOfMan,
										Selection.InitialCostOfMa,
										CurrencyOfMan);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
			
		EndIf; 
		#EndRegion
				
		#Region ACC
		If (Selection.BusinessOperation = Enums.BusinessTransactions.PartialFixedAssetsSplit
			Or Selection.BusinessOperation = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
			And Selection.TotalCostOfAC >= Selection.InitialCostOfAC
			And Selection.TotalCostOfAC <> 0
			And Selection.RecordInLocalAccounting Then
			
			Documents_With_Errors.Add(Selection.Ref);
			
			IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số  %1 ngày  %2, tổng chi phí được chấp nhận cho TSCĐ kế toán (%3%4) phải thấp hơn chi phí của TSCĐ gốc (%5%6).';
								|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в бухгалтерском учете (%3 %4) должна быть меньше стоимости исходного ОС (%5 %6).';
								|en = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in local accounting (%3 %4) must be less than the original fixed asset cost (%5 %6).'; fa = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in local accounting (%3 %4) must be less than the original fixed asset cost (%5 %6).';
								|it = 'Nel documento Smantellamento del capitale fisso №%1 di %2 il costo complessivo preso in considerazione per il capitale fisso nella contabilità generale (%3 %4) deve essere inferiore al prezzo iniziale del capitale fisso (%5%6).';
								|pl = 'W dokumencie Dokompletowanie środku trwałego nr.%1 z dnia %2 wartość ogólna, przyjmowanych do ewidencji środków trwałych w księgowości (%3 %4) musi być mniej wartości źródłowego środku trwałego (%5 %6).';
								|tr = '%2''nin %1 numaralı Sabit kıymetlerin Ayrılması belgesinde, genel muhasebede muhasebeleştirilmek üzere kabul edilen sabit kıymetlerin toplam maliyeti (%3 %4), orijinal sabit kıymetlerin maliyetinden (%5 %6) daha az olmalıdır.'");
			
			IssueDetails = StrTemplate(IssueDetails, 
										Selection.DocumentNumber, 
										Format(Selection.DocumentDate, "DLF=D"), 
										Selection.TotalCostOfAC,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
										Selection.InitialCostOfAC,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization));
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
			
		EndIf; 
				
		If Selection.BusinessOperation = Enums.BusinessTransactions.CompleteSplitFixedAssets
			And Selection.TotalCostOfAC <> Selection.InitialCostOfAC
			And Selection.RecordInLocalAccounting Then
			
			If Selection.WriteOffNodes Then
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số%1 ngày %2, tổng chi phí được tiếp nhận vào kế toán TSCĐ trong kế toán doanh nghiệp (%3 %4) phải bằng chi phí của TSCĐ gốc (%5 %6) có tính đến giá trị của các cụm linh kiện và thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в бухгалтерском учете (%3 %4) должна равняться стоимости исходного ОС (%5 %6) с учетом стоимости узлов и компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.'; fa = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.';
									|it = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Parçalara Ayrılması belgesinde, genel muhasebede muhasebeleştirilecek sabit kıymetlerin toplam maliyeti (%3 %4), alt ünitelerin ve amortisman unsurlarının maliyeti dikkate alınarak orijinal sabit kıymetin maliyetine (%5 %6) eşit olmalıdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số%1 ngày %2, tổng chi phí được tiếp nhận vào kế toán TSCĐ trong kế toán doanh nghiệp (%3 %4) phải bằng chi phí của TSCĐ gốc (%5 %6) có tính đến giá trị của các thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в бухгалтерском учете (%3 %4) должна равняться стоимости исходного ОС (%5 %6) с учетом стоимости компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|it = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in local accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Parçalara Ayrılması belgesinde, genel muhasebede muhasebeleştirilecek sabit kıymetlerin toplam maliyeti (%3 %4), alt ünitelerin ve amortisman bileşenlerinin maliyeti dikkate alınarak orijinal sabit kıymetin maliyetine (%5 %6) eşit olmalıdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, 
										Selection.DocumentNumber, 
										Format(Selection.DocumentDate, "DLF=D"), 
										Selection.TotalCostOfAC,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
										Selection.InitialCostOfAC,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization));
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
			
		EndIf; 
		#EndRegion
		
		#Region TA
		If (Selection.BusinessOperation = Enums.BusinessTransactions.PartialFixedAssetsSplit
			Or Selection.BusinessOperation = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
			And Selection.TotalCostTa >= Selection.InitialCostTa_
			And Selection.TotalCostTa <> 0
			And Selection.RecordInLocalAccounting Then
			
			Documents_With_Errors.Add(Selection.Ref);
			
			IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số %1 ngày %2, tổng chi phí được chấp nhận cho TSCĐ kế toán trong kế toán thuế (%3%4) phải thấp hơn chi phí của TSCĐ gốc (%5%6).';
								|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в налоговом учете (%3 %4) должна быть меньше стоимости исходного ОС (%5 %6).';
								|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in tax accounting (%3 %4) must be less than the original fixed asset value (%5 %6).'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in tax accounting (%3 %4) must be less than the original fixed asset value (%5 %6).';
								|it = 'Nel documento Smantellamento del capitale fisso №%1 di %2 il costo complessivo preso in considerazione per il capitale fisso nella contabilità fiscale (%3 %4) deve essere inferiore al prezzo iniziale del capitale fisso (%5%6).';
								|pl = 'W dokumencie Dokompletowanie środku trwałego nr.%1 z dnia %2 wartość ogólna, przyjmowanych do ewidencji środków trwałych w ewidencji podatkowej (%3 %4) musi być mniej wartości źródłowego środku trwałego (%5 %6).';
								|tr = '%2''nin %1 numaralı Sabit kıymetlerin Ayrılması belgesinde, vergi muhasebesinde muhasebeleştirilmek üzere kabul edilen sabit kıymetlerin toplam maliyeti (%3 %4), orijinal sabit kıymetlerin maliyetinden (%5 %6) daha az olmalıdır.'");
			
			IssueDetails = StrTemplate(IssueDetails, 
										Selection.DocumentNumber, 
										Format(Selection.DocumentDate, "DLF=D"), 
										Selection.TotalCostTa,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
										Selection.InitialCostTa_,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization));
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
			
		EndIf; 
				
		If Selection.BusinessOperation = Enums.BusinessTransactions.CompleteSplitFixedAssets
			And Selection.TotalCostTa <> Selection.InitialCostTa_
			And Selection.RecordInLocalAccounting Then
			
			Documents_With_Errors.Add(Selection.Ref);
			
			If Selection.WriteOffNodes Then
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số%1 ngày %2, tổng chi phí được tiếp nhận vào kế toán TSCĐ trong kế toán thuế (%3 %4) phải bằng chi phí của TSCĐ gốc (%5 %6) có tính đến giá trị của các cụm linh kiện và thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в налоговом учете (%3 %4) должна равняться стоимости исходного ОС (%5 %6) с учетом стоимости узлов и компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.'; fa = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.';
									|it = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No. %1 dated %2, the total cost of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset cost (%5 %6) including the cost of sub-assets and depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Parçalara Ayrılması belgesinde, vergi muhasebesinde muhasebeleştirilecek sabit kıymetlerin toplam maliyeti (%3 %4), alt ünitelerin ve amortisman bileşenlerinin maliyeti dikkate alınarak orijinal sabit kıymetin maliyetine (%5 %6) eşit olmalıdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số%1 ngày %2, tổng chi phí được tiếp nhận vào kế toán TSCĐ trong kế toán thuế (%3 %4) phải bằng chi phí của TSCĐ gốc (%5 %6) có tính đến giá trị của các thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 общая стоимость, принимаемых к учету ОС в налоговом учете (%3 %4) должна равняться стоимости исходного ОС (%5 %6) с учетом стоимости компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|it = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No.%1 dated %2, the total value of recognized fixed assets in tax accounting (%3 %4) must be equal to the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Parçalara Ayrılması belgesinde, vergi muhasebesinde muhasebeleştirilecek sabit kıymetlerin toplam maliyeti (%3 %4), amortisman bileşenlerinin maliyeti dikkate alınarak orijinal sabit kıymetin maliyetine (%5 %6) eşit olmalıdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, 
										Selection.DocumentNumber, 
										Format(Selection.DocumentDate, "DLF=D"), 
										Selection.TotalCostTa,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
										Selection.InitialCostTa_,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization));
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
			
		EndIf; 
		#EndRegion
				
		#Region PD
				
		If Selection.BusinessOperation = Enums.BusinessTransactions.CompleteSplitFixedAssets
			And Selection.TotalCostOfPD <> Selection.InitialCostOfPD
			And Selection.RecordInLocalAccounting Then
			
			Documents_With_Errors.Add(Selection.Ref);
			
			If Selection.WriteOffNodes Then
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số %1 ngày %2, chênh lệch vĩnh viễn trong tổng giá trị TSCĐ được ghi nhận vào kế toán (%3 %4) phải bằng chênh lệch vĩnh viễn trong giá trị TSCĐ ban đầu (%5 %6) có tính đến giá trị của các cụm linh kiện và thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 постоянная разница в общей стоимости, принимаемых к учету ОС (%3 %4) должна равняться постоянной разнице в стоимости исходного ОС (%5 %6) с учетом стоимости узлов и компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.';
									|it = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of sub-assets and depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Parçalara Ayrılması belgesinde, muhasebeleştirilecek sabit kıymetlerin toplam maliyetindeki kalıcı fark (%3%4), alt ünitelerin ve amortisman bileşenlerinin maliyeti dikkate alınarak orijinal sabit kıymetin maliyetindeki kalıcı farka (%5%6) eşit olmalıdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong chứng từ Tháo dỡ TSCĐ số %1 ngày %2, chênh lệch vĩnh viễn trong tổng giá trị TSCĐ được ghi nhận vào kế toán (%3 %4) phải bằng chênh lệch vĩnh viễn trong giá trị TSCĐ ban đầu (%5 %6) có tính đến giá trị của các thành phần khấu hao.';
									|ru = 'В документе Разукомплектация ОС №%1 от %2 постоянная разница в общей стоимости, принимаемых к учету ОС (%3 %4) должна равняться постоянной разнице в стоимости исходного ОС (%5 %6) с учетом стоимости компонент амортизации.';
									|en = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of depreciation components.'; fa = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|it = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|pl = 'In the ""Split fixed assets"" document No.%1 dated %2, the permanent difference in the total value of recognized fixed assets (%3 %4) must be equal to the permanent difference in the original fixed asset value (%5 %6) including the cost of depreciation components.';
									|tr = '%2 tarihli ve %1 numaralı Sabit Kıymetlerin Parçalara Ayrılması belgesinde, muhasebeleştirilecek sabit kıymetlerin toplam maliyetindeki kalıcı fark (%3%4), amortisman bileşenlerinin maliyeti dikkate alınarak orijinal sabit kıymetin maliyetindeki kalıcı farka (%5%6) eşit olmalıdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, 
										Selection.DocumentNumber, 
										Format(Selection.DocumentDate, "DLF=D"), 
										Selection.TotalCostOfPD,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization),
										Selection.InitialCostOfPD,
										SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization));
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
			
		EndIf; 
		#EndRegion

	EndDo; 
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);

	#EndRegion
	
	#Region ImplementationPriorToPreparationForTransfer
	QueryText =
	"SELECT
	|	TableExpenses.NonCurrentAsset
	|
	|INTO TableVNA
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets.Expenses AS TableExpenses
	|
	|WHERE
	|	TableExpenses.Ref IN (
	|		SELECT
	|			TTPortionOfDataToBeCalculated.Ref
	|		FROM
	|			TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|		WHERE
	|			VALUETYPE(TTPortionOfDataToBeCalculated.Ref) = TYPE(Document.CustomerInvoiceServicesAndAssets))
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InitialInformation.Organization AS Organization,
	|	InitialInformation.FixedAsset AS NonCurrentAsset,
	|	ISNULL(PreparationForACTransfer.Date, DATETIME(1,1,1)) AS DateOfACDebiting,
	|	ISNULL(PreparingForTransferOfTA.Date, DATETIME(1,1,1)) AS DateOfDebitingTA,
	|	ISNULL(PreparationForTransferOfMA.Date, DATETIME(1,1,1)) AS DateOfMADebiting,
	|	InitialInformation.CommissioningDateAC AS CommissioningDateAC,
	|	InitialInformation.CommissioningDateTA AS CommissioningDateTA,
	|	InitialInformation.CommissioningDateMA AS CommissioningDateMA
	|
	|INTO InitialInformation
	|
	|FROM
	|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
	|		&EndOfMonth,
	|		FixedAsset IN (
	|			SELECT
	|				TableVNA.NonCurrentAsset
	|			FROM
	|				TableVNA AS TableVNA)) AS InitialInformation
	|
	|		LEFT JOIN Document.PreparingForFixedAssetSale2_4 AS PreparationForACTransfer
	|		ON PreparationForACTransfer.Ref = InitialInformation.DeregistrationDocumentACC
	|
	|		LEFT JOIN Document.PreparingForFixedAssetSale2_4 AS PreparingForTransferOfTA
	|		ON PreparingForTransferOfTA.Ref = InitialInformation.DeregistrationDocumentTA
	|
	|		LEFT JOIN Document.PreparingForFixedAssetSale2_4 AS PreparationForTransferOfMA
	|		ON PreparationForTransferOfMA.Ref = InitialInformation.DeregistrationDocumentMA
	|
	|UNION ALL
	|
	|SELECT
	|	InitialInformation.Organization AS Organization,
	|	InitialInformation.IntangibleAsset AS NonCurrentAsset,
	|	ISNULL(PreparingForSale.Date, DATETIME(1,1,1)) AS DateOfACDebiting,
	|	ISNULL(PreparingForSale.Date, DATETIME(1,1,1)) AS DateOfDebitingTA,
	|	ISNULL(PreparingForSale.Date, DATETIME(1,1,1)) AS DateOfMADebiting,
	|	InitialInformation.DateOfRecognitionAccounting AS CommissioningDateAC,
	|	InitialInformation.DateOfRecognitionInTaxAccounting AS CommissioningDateTA,
	|	InitialInformation.DateOfRecognitionManagementAccounting AS CommissioningDateMA
	|
	|FROM
	|	InformationRegister.InitialIntangibleAssetsInformation.SliceLast(
	|		&EndOfMonth,
	|		IntangibleAsset IN (
	|			SELECT
	|				TableVNA.NonCurrentAsset
	|			FROM
	|				TableVNA AS TableVNA)) AS InitialInformation
	|
	|		LEFT JOIN Document.PreparingForIntangibleAssetSale2_4 AS PreparingForSale
	|		ON (PreparingForSale.Ref = InitialInformation.DocumentWriteOffs)
	|
	|INDEX BY
	|	Organization,
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref,
	|	TTPortionOfDataToBeCalculated.Organization AS Organization,
	|	DocumentTable.Number AS DocumentNumber,
	|	DocumentTable.Date AS DocumentDate,
	|	TTPortionOfDataToBeCalculated.Date AS Date,
	|	TableExpenses.NonCurrentAsset AS NonCurrentAsset,
	|	ISNULL(TableExpenses.LineNumber, 0) AS LineNumber
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|		LEFT JOIN Document.CustomerInvoiceServicesAndAssets AS DocumentTable
	|		ON (DocumentTable.Ref = TTPortionOfDataToBeCalculated.Ref)
	|
	|		LEFT JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS TableExpenses
	|		ON (TableExpenses.Ref = TTPortionOfDataToBeCalculated.Ref)
	|
	|		LEFT JOIN InitialInformation AS InitialInformation
	|		ON (InitialInformation.NonCurrentAsset = TableExpenses.NonCurrentAsset)
	|			AND (InitialInformation.Organization = DocumentTable.Organization)
	|
	|WHERE
	|	VALUETYPE(TTPortionOfDataToBeCalculated.Ref) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|
	|	AND (ISNULL(InitialInformation.CommissioningDateAC, DATETIME(1,1,1)) <> DATETIME(1,1,1)
	|			AND ISNULL(InitialInformation.DateOfACDebiting, DATETIME(1,1,1)) <> DATETIME(1,1,1)
	|			AND ISNULL(BEGINOFPERIOD(InitialInformation.DateOfACDebiting, DAY), DATETIME(1,1,1)) > BEGINOFPERIOD(DocumentTable.Date, DAY)
	|
	|		OR ISNULL(InitialInformation.CommissioningDateTA, DATETIME(1,1,1)) <> DATETIME(1,1,1)
	|			AND ISNULL(InitialInformation.DateOfDebitingTA, DATETIME(1,1,1)) <> DATETIME(1,1,1)
	|			AND ISNULL(BEGINOFPERIOD(InitialInformation.DateOfDebitingTA, DAY), DATETIME(1,1,1)) > BEGINOFPERIOD(DocumentTable.Date, DAY)
	|
	|		OR ISNULL(InitialInformation.CommissioningDateMA, DATETIME(1,1,1)) <> DATETIME(1,1,1)
	|			AND ISNULL(InitialInformation.DateOfMADebiting, DATETIME(1,1,1)) <> DATETIME(1,1,1)
	|			AND ISNULL(BEGINOFPERIOD(InitialInformation.DateOfMADebiting, DAY), DATETIME(1,1,1)) > BEGINOFPERIOD(DocumentTable.Date, DAY))
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		Documents_With_Errors.Add(Selection.Ref);
		
		IssueDetails = NStr("vi = 'Chứng từ cung cấp dịch vụ và tài sản khác số %1 ngày %2 đối với tài sản dài hạn %3 đã lập trước khi chuẩn bị chuyển giao.';
							|ru = 'Реализация услуг и прочих активов №%1 от %2 для внеоборотного актива %3 оформлена раньше чем подготовка к передаче.';
							|en = 'Customer invoice — Services and Assets No. %1 dated %2 for the %3 fixed asset is registered earlier than the preparation for transfer.'; fa = 'Customer invoice — Services and Assets No. %1 dated %2 for the %3 fixed asset is registered earlier than the preparation for transfer.';
							|it = 'Vendita di servizi e altri attivi №%1 di %2 per attivo non corrente %3 compilata prima della preparazione per il trasferimento.';
							|pl = 'Sprzedaż usług i innych aktywów nr %1 z dn. %2 dla aktywu trwałego %3 została utworzona wcześniej niż przygotowanie do przekazania.';
							|tr = 'Hizmetlerin ve diğer varlıkların satışı  %1no''lu %2 tarihli duran varlık için, %3transfer hazırlığından daha önce resmileştirilir.'");
		
		IssueDetails = StrTemplate(IssueDetails, 
									Selection.DocumentNumber, 
									Format(Selection.DocumentDate, "DLF=D"), 
									Selection.NonCurrentAsset);
		
		NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
			ExecutionParameters.MonthClosingOperation, 
			Period,
			Selection.Organization,
			IssueDetails,,
			Selection.Ref);
				
	EndDo; 
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	#EndRegion
	
	#Region WriteOffOfLeasedAssets
	
	If GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		
		QueryTexts = New ValueList;

		QueryText = 
		"SELECT DISTINCT
		|	TTPortionOfDataToBeCalculated.Ref AS Ref,
		|	TTPortionOfDataToBeCalculated.Period AS Period,
		|	TTPortionOfDataToBeCalculated.Organization AS Organization,
		|	TTPortionOfDataToBeCalculated.AccountingObject AS FixedAsset
		|
		|INTO TTFAList
		|
		|FROM
		|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
		|
		|WHERE
		|	VALUETYPE(TTPortionOfDataToBeCalculated.Ref) IN (
		|		TYPE(Document.MergeOfFixedAssets),
		|		TYPE(Document.SplitFixedAssets),
		|		TYPE(Document.DisposeFixedAssets2_4),
		|		TYPE(Document.PreparingForFixedAssetSale2_4))
		|	
		|INDEX BY
		|	FixedAsset,
		|	Organization
		|";
		QueryTexts.Add(QueryText, "TTFAList");
		
		NonCurrentAssetsInternal.QueryTextTableTTLeasedToFA(QueryTexts, "TTPortionOfDataToBeCalculated");
			
		QueryText =
		"SELECT
		|	TTFAList.Ref AS Ref,
		|	TTFAList.Organization AS Organization,
		|	TTFAList.FixedAsset AS FixedAsset,
		|	CAST(TTFAList.FixedAsset AS Catalog.Assets).Description AS FixedAssetName
		|
		|FROM
		|	TTFAList AS TTFAList
		|
		|		INNER JOIN TTLeasedToFA AS TTLeasedToFA
		|		ON TTLeasedToFA.Ref = TTFAList.Ref
		|			AND TTLeasedToFA.Organization = TTFAList.Organization
		|			AND TTLeasedToFA.FixedAsset = TTFAList.FixedAsset
		|
		|WHERE
		|	TTLeasedToFA.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
		|	AND CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
		|
		|ORDER BY
		|	Ref,
		|	FixedAsset";
		QueryTexts.Add(QueryText);
		
		QueryText = StrConcat(QueryTexts.UnloadValues(), Common.QueryBatchSeparator());
		
		Query.Text = QueryText;
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			Documents_With_Errors.Add(Selection.Ref);
			
			If TypeOf(Selection.Ref) = Type("DocumentRef.PreparingForFixedAssetSale2_4") Then
				IssueDetails = NStr("vi = 'Trước khi chuẩn bị chuyển tài sản cố định ""%1"" được chuyển sang cho thuê, cần tạo chứng từ trả lại đã thuê.';
									|ru = 'Перед подготовкой к передаче основного средства ""%1"" переданного в аренду, необходимо оформить возврат из аренды.';
									|en = 'Before you prepare for sale of the %1 fixed asset provided to the lessee, register the return from the lessee.'; fa = 'Before you prepare for sale of the %1 fixed asset provided to the lessee, register the return from the lessee.';
									|it = 'Перед подготовкой к передаче основного средства ""%1"" переданного в аренду, необходимо оформить возврат из аренды.';
									|pl = 'Before you prepare for sale of the %1 fixed asset provided to the lessee, register the return from the lessee.';
									|tr = 'Kiralanan ""%1"" sabit kıymetin devrine hazırlanmadan önce, kiralamadan iade düzenlenmesi gerekmektedir.'");
			Else
				IssueDetails = NStr("vi = 'Trước khi ghi giảm tài sản cố định ""%1"" được chuyển cho thuê, cần tạo chứng từ trả lại đã thuê.';
									|ru = 'Перед списанием основного средства ""%1"" переданного в аренду, необходимо оформить возврат из аренды.';
									|en = 'Before you write off the %1 fixed asset provided to the lessee, register the return from the lessee.'; fa = 'Before you write off the %1 fixed asset provided to the lessee, register the return from the lessee.';
									|it = 'Перед списанием основного средства ""%1"" переданного в аренду, необходимо оформить возврат из аренды.';
									|pl = 'Before you write off the %1 fixed asset provided to the lessee, register the return from the lessee.';
									|tr = 'Kiralanan ""%1"" sabit kıymetin gider yazılmasından önce, kiralamadan iade düzenlenmesi gerekmektedir.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.FixedAssetName);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
					
		EndDo; 

		TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);

	EndIf;
	#EndRegion
	
	#Region SplitFixedAssets
	QueryText =
	"SELECT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref,
	|	TTPortionOfDataToBeCalculated.Date AS Date,
	|	TTPortionOfDataToBeCalculated.Organization AS Organization,
	|	TTPortionOfDataToBeCalculated.AccountingObject AS AccountingObject,
	|	TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting
	|
	|INTO TableVNA
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|WHERE
	|	VALUETYPE(TTPortionOfDataToBeCalculated.Ref) = TYPE(Document.SplitFixedAssets)
	|	AND CAST(TTPortionOfDataToBeCalculated.AccountingObject AS Catalog.Assets).OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableVNA.Ref AS Ref,
	|	TableVNA.Date AS Date,
	|	TableVNA.AccountingObject AS AccountingObject,
	|	RegisterData.SubAssetComponent AS SubAssetComponent
	|
	|INTO TableAllNodesComponentsOfDepreciation
	|
	|FROM
	|	TableVNA AS TableVNA
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.FixedAsset = TableVNA.AccountingObject
	|			AND RegisterData.Period <= TableVNA.Date
	|			AND RegisterData.Recorder <> TableVNA.Ref
	|			AND RegisterData.Active
	|
	|INDEX BY
	|	SubAssetComponent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableAllNodesComponentsOfDepreciation.Ref AS Ref,
	|	TableAllNodesComponentsOfDepreciation.AccountingObject AS AccountingObject,
	|	TableAllNodesComponentsOfDepreciation.SubAssetComponent AS SubAssetComponent,
	|	MAX(RegisterData.Period) AS Period
	|
	|INTO RegisterData_Period
	|
	|FROM
	|	TableAllNodesComponentsOfDepreciation AS TableAllNodesComponentsOfDepreciation
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = TableAllNodesComponentsOfDepreciation.SubAssetComponent
	|			AND RegisterData.Period <= TableAllNodesComponentsOfDepreciation.Date
	|			AND RegisterData.Recorder <> TableAllNodesComponentsOfDepreciation.Ref
	|			AND RegisterData.Active
	|
	|GROUP BY
	|	TableAllNodesComponentsOfDepreciation.Ref,
	|	TableAllNodesComponentsOfDepreciation.AccountingObject,
	|	TableAllNodesComponentsOfDepreciation.SubAssetComponent
	|
	|INDEX BY
	|	SubAssetComponent,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData_Period.Ref AS Ref,
	|	RegisterData_Period.AccountingObject AS AccountingObject,
	|	RegisterData_Period.SubAssetComponent AS SubAssetComponent,
	|	RegisterData_Period.Period AS Period,
	|	MAX(RegisterData.Recorder) AS Recorder
	|
	|INTO RegisterData_Recorder
	|
	|FROM
	|	RegisterData_Period AS RegisterData_Period
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = RegisterData_Period.SubAssetComponent
	|			AND RegisterData.Period = RegisterData_Period.Period
	|			AND RegisterData.Recorder <> RegisterData_Period.Ref
	|			AND RegisterData.Active
	|
	|GROUP BY
	|	RegisterData_Period.Ref,
	|	RegisterData_Period.AccountingObject,
	|	RegisterData_Period.SubAssetComponent,
	|	RegisterData_Period.Period
	|
	|INDEX BY
	|	SubAssetComponent,
	|	Period,
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData_Recorder.Ref AS Ref,
	|	RegisterData_Recorder.AccountingObject AS AccountingObject,
	|	RegisterData_Recorder.SubAssetComponent AS SubAssetComponent,
	|	RegisterData.FixedAsset AS FixedAsset
	|
	|INTO SubAssetsComponentsOfDepreciation
	|
	|FROM
	|	RegisterData_Recorder AS RegisterData_Recorder
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = RegisterData_Recorder.SubAssetComponent
	|			AND RegisterData.Period = RegisterData_Recorder.Period
	|			AND RegisterData.Recorder = RegisterData_Recorder.Recorder
	|			AND RegisterData.Active
	|
	|INDEX BY
	|	Ref,
	|	SubAssetComponent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NetBookValue.Ref AS Ref,
	|	NetBookValue.AccountingObject AS AccountingObject,
	|	SUM(NetBookValue.Cost) AS NetBookValueMan,
	|	SUM(NetBookValue.LocalCost) AS ACResidualValue
	|
	|INTO NetBookValue
	|
	|FROM
	|	(SELECT
	|		TT_CostOfVNA.Ref AS Ref,
	|		TT_CostOfVNA.AccountingObject AS AccountingObject,
	|		TT_CostOfVNA.Cost AS Cost,
	|		TT_CostOfVNA.LocalCost + TT_CostOfVNA.CostTargetFinancing AS LocalCost
	|	FROM
	|		TT_CostOfVNA AS TT_CostOfVNA
	|	WHERE
	|		TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|				WHERE
	|					SubAssetsComponentsOfDepreciation.Ref = TT_CostOfVNA.Ref
	|					AND SubAssetsComponentsOfDepreciation.SubAssetComponent = TT_CostOfVNA.AccountingObject)
	|				
	|	UNION ALL
	|				
	|	SELECT
	|		TT_DepreciationOfVNA.Ref AS Ref,
	|		TT_DepreciationOfVNA.AccountingObject AS AccountingObject,
	|		-TT_DepreciationOfVNA.Depreciation AS Cost,
	|		-(TT_DepreciationOfVNA.DepreciationLocal + TT_DepreciationOfVNA.FixedAssetDepreciationTargetFinancing) AS DepreciationLocal
	|	FROM
	|		TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|	WHERE
	|		TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|				WHERE
	|					SubAssetsComponentsOfDepreciation.Ref = TT_DepreciationOfVNA.Ref
	|					AND SubAssetsComponentsOfDepreciation.SubAssetComponent = TT_DepreciationOfVNA.AccountingObject)
	|				
	|	) AS NetBookValue
	|
	|GROUP BY
	|	NetBookValue.Ref,
	|	NetBookValue.AccountingObject
	|	
	|HAVING
	|	SUM(NetBookValue.Cost) < 0
	|		OR SUM(NetBookValue.LocalCost) < 0
	|	
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableVNA.Ref AS Ref,
	|	TableVNA.Organization AS Organization,
	|	CAST(TableVNA.AccountingObject AS Catalog.Assets).Presentation AS AccountingObjectPresentation
	|
	|FROM
	|	TableVNA AS TableVNA
	|
	|WHERE
	|	TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|		WHERE
	|			SubAssetsComponentsOfDepreciation.Ref = TableVNA.Ref
	|			AND SubAssetsComponentsOfDepreciation.FixedAsset = TableVNA.AccountingObject
	|			AND SubAssetsComponentsOfDepreciation.SubAssetComponent IN (
	|				SELECT
	|					NetBookValue.AccountingObject
	|				FROM
	|					NetBookValue AS NetBookValue
	|				WHERE
	|					NetBookValue.Ref = TableVNA.Ref
	|					AND (TableVNA.RecordInLocalAccounting
	|							AND NetBookValue.ACResidualValue < 0
	|						OR TableVNA.RecordInManAccounting
	|							AND NetBookValue.NetBookValueMan < 0)))
	|
	|ORDER BY
	|	Ref
	|";
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		Documents_With_Errors.Add(Selection.Ref);
		
		IssueDetails = NStr("vi = 'Không hỗ trợ tháo dỡ tài sản cố định ""%1"" với các bộ phận và thành phần mà có giá trị số dư âm.';
							|ru = 'Не поддерживается разукомплектация основного средства ""%1"" с узлами и компонентами, имеющих отрицательную остаточную стоимость.';
							|en = 'Splitting the ""%1"" fixed asset with sub-assets and components that have a negative net book value is not supported.'; fa = 'Splitting the ""%1"" fixed asset with sub-assets and components that have a negative net book value is not supported.';
							|it = 'Не поддерживается разукомплектация основного средства ""%1"" с узлами и компонентами, имеющих отрицательную остаточную стоимость.';
							|pl = 'Splitting the ""%1"" fixed asset with sub-assets and components that have a negative net book value is not supported.';
							|tr = 'Negatif net defter değeri olan alt varlıklar ve bileşenlerle ""%1"" sabit kıymetinin ürün setinden çıkarılması desteklenmemektedir.'");
		IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
		
		NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
			ExecutionParameters.MonthClosingOperation, 
			Period,
			Selection.Organization,
			IssueDetails,,
			Selection.Ref);
				
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	#EndRegion
	
	#Region CostAndDepreciationAdjustmentOS_NegativeCost
	QueryText =
	"SELECT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref,
	|	TTPortionOfDataToBeCalculated.Date AS Date,
	|	TTPortionOfDataToBeCalculated.Organization AS Organization,
	|	TTPortionOfDataToBeCalculated.AccountingObject AS AccountingObject,
	|	TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting
	|
	|INTO TableVNA
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|WHERE
	|	VALUETYPE(TTPortionOfDataToBeCalculated.Ref) = TYPE(Document.FixedAssetCostAndDepreciationAdjustment)
	|
	|INDEX BY
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableVNA.Ref AS Ref,
	|	TableVNA.Date AS Date,
	|	TableVNA.SubAssetComponent AS SubAssetComponent
	|
	|INTO TableAllNodesComponentsOfDepreciation
	|
	|FROM
	|	(SELECT
	|		TableVNA.Ref AS Ref,
	|		TableVNA.Date AS Date,
	|		TableVNA.AccountingObject AS AccountingObject,
	|		RegisterData.SubAssetComponent AS SubAssetComponent
	|	FROM
	|		TableVNA AS TableVNA
	|
	|			INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|			ON RegisterData.FixedAsset = TableVNA.AccountingObject
	|				AND RegisterData.Period <= TableVNA.Date
	|				AND RegisterData.Recorder <> TableVNA.Ref
	|				AND RegisterData.Active
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableVNA.Ref AS Ref,
	|		TableVNA.Date AS Date,
	|		TableVNA.AccountingObject AS AccountingObject,
	|		RegisterData.SubAssetComponent AS SubAssetComponent
	|
	|	FROM
	|		TableVNA AS TableVNA
	|
	|			INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|			ON RegisterData.SubAssetComponent = TableVNA.AccountingObject
	|				AND RegisterData.Period <= TableVNA.Date
	|				AND RegisterData.Recorder <> TableVNA.Ref
	|				AND RegisterData.Active
	|
	|	) AS TableVNA
	|
	|INDEX BY
	|	SubAssetComponent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableAllNodesComponentsOfDepreciation.Ref AS Ref,
	|	TableAllNodesComponentsOfDepreciation.SubAssetComponent AS SubAssetComponent,
	|	MAX(RegisterData.Period) AS Period
	|
	|INTO RegisterData_Period
	|
	|FROM
	|	TableAllNodesComponentsOfDepreciation AS TableAllNodesComponentsOfDepreciation
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = TableAllNodesComponentsOfDepreciation.SubAssetComponent
	|			AND RegisterData.Period <= TableAllNodesComponentsOfDepreciation.Date
	|			AND RegisterData.Recorder <> TableAllNodesComponentsOfDepreciation.Ref
	|			AND RegisterData.Active
	|
	|GROUP BY
	|	TableAllNodesComponentsOfDepreciation.Ref,
	|	TableAllNodesComponentsOfDepreciation.SubAssetComponent
	|
	|INDEX BY
	|	SubAssetComponent,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData_Period.Ref AS Ref,
	|	RegisterData_Period.SubAssetComponent AS SubAssetComponent,
	|	RegisterData_Period.Period AS Period,
	|	MAX(RegisterData.Recorder) AS Recorder
	|
	|INTO RegisterData_Recorder
	|
	|FROM
	|	RegisterData_Period AS RegisterData_Period
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = RegisterData_Period.SubAssetComponent
	|			AND RegisterData.Period = RegisterData_Period.Period
	|			AND RegisterData.Recorder <> RegisterData_Period.Ref
	|			AND RegisterData.Active
	|
	|GROUP BY
	|	RegisterData_Period.Ref,
	|	RegisterData_Period.SubAssetComponent,
	|	RegisterData_Period.Period
	|
	|INDEX BY
	|	SubAssetComponent,
	|	Period,
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData_Recorder.Ref AS Ref,
	|	RegisterData_Recorder.SubAssetComponent AS SubAssetComponent,
	|	RegisterData.FixedAsset AS FixedAsset
	|
	|INTO SubAssetsComponentsOfDepreciation
	|
	|FROM
	|	RegisterData_Recorder AS RegisterData_Recorder
	|
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS RegisterData
	|		ON RegisterData.SubAssetComponent = RegisterData_Recorder.SubAssetComponent
	|			AND RegisterData.Period = RegisterData_Recorder.Period
	|			AND RegisterData.Recorder = RegisterData_Recorder.Recorder
	|			AND RegisterData.Active
	|
	|INDEX BY
	|	Ref,
	|	SubAssetComponent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NetBookValue.Ref AS Ref,
	|	NetBookValue.AccountingObject AS AccountingObject,
	|	SUM(NetBookValue.Cost) AS NetBookValueMan,
	|	SUM(NetBookValue.LocalCost) AS ACResidualValue
	|
	|INTO NetBookValue
	|
	|FROM
	|	(SELECT
	|		TT_CostOfVNA.Ref AS Ref,
	|		TT_CostOfVNA.AccountingObject AS AccountingObject,
	|		TT_CostOfVNA.Cost AS Cost,
	|		TT_CostOfVNA.LocalCost + TT_CostOfVNA.CostTargetFinancing AS LocalCost
	|	FROM
	|		TT_CostOfVNA AS TT_CostOfVNA
	|	WHERE
	|		TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					TableVNA AS TableVNA
	|				WHERE
	|					TableVNA.Ref = TT_CostOfVNA.Ref)
	|				
	|	UNION ALL
	|				
	|	SELECT
	|		TT_DepreciationOfVNA.Ref AS Ref,
	|		TT_DepreciationOfVNA.AccountingObject AS AccountingObject,
	|		-TT_DepreciationOfVNA.Depreciation AS Cost,
	|		-(TT_DepreciationOfVNA.DepreciationLocal + TT_DepreciationOfVNA.FixedAssetDepreciationTargetFinancing) AS DepreciationLocal
	|	FROM
	|		TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|	WHERE
	|		TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					TableVNA AS TableVNA
	|				WHERE
	|					TableVNA.Ref = TT_DepreciationOfVNA.Ref)
	|				
	|	) AS NetBookValue
	|
	|GROUP BY
	|	NetBookValue.Ref,
	|	NetBookValue.AccountingObject
	|	
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableVNA.Ref AS Ref,
	|	TableVNA.Organization AS Organization,
	|	CAST(TableVNA.AccountingObject AS Catalog.Assets).Presentation AS AccountingObjectPresentation
	|
	|FROM
	|	TableVNA AS TableVNA
	|
	|WHERE
	|	TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			SubAssetsComponentsOfDepreciation AS SubAssetsComponentsOfDepreciation
	|		WHERE
	|			SubAssetsComponentsOfDepreciation.Ref = TableVNA.Ref
	|			AND SubAssetsComponentsOfDepreciation.FixedAsset = TableVNA.AccountingObject
	|			AND SubAssetsComponentsOfDepreciation.SubAssetComponent IN (
	|				SELECT
	|					NetBookValue.AccountingObject
	|				FROM
	|					NetBookValue AS NetBookValue
	|				WHERE
	|					NetBookValue.Ref = TableVNA.Ref
	|					AND (TableVNA.RecordInLocalAccounting
	|							AND NetBookValue.ACResidualValue < 0
	|						OR TableVNA.RecordInManAccounting
	|							AND NetBookValue.NetBookValueMan < 0)))
	|
	|ORDER BY
	|	Ref
	|";
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		Documents_With_Errors.Add(Selection.Ref);
		
		IssueDetails = NStr("vi = 'Không hỗ trợ điều chỉnh giá trị và khấu hao tài sản cố định ""%1"" với các bộ phận và thành phần mà có giá trị số dư âm.';
							|ru = 'Не поддерживается корректировка стоимости и амортизации основного средства ""%1"" с узлами и компонентами, имеющих отрицательную остаточную стоимость.';
							|en = 'Adjusting the cost and depreciation of the ""%1"" fixed asset with sub-assets and components that have a negative net book value is not supported.'; fa = 'Adjusting the cost and depreciation of the ""%1"" fixed asset with sub-assets and components that have a negative net book value is not supported.';
							|it = 'Не поддерживается корректировка стоимости и амортизации основного средства ""%1"" с узлами и компонентами, имеющих отрицательную остаточную стоимость.';
							|pl = 'Adjusting the cost and depreciation of the ""%1"" fixed asset with sub-assets and components that have a negative net book value is not supported.';
							|tr = 'Negatif kalıntı maliyeti  olan alt varlıklar ve bileşenlerle ""%1"" sabit varlığın maliyetin ve amortismanının düzeltilmesi desteklenmemektedir.'");
		IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
		
		NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
			ExecutionParameters.MonthClosingOperation, 
			Period,
			Selection.Organization,
			IssueDetails,,
			Selection.Ref);
				
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	#EndRegion	

	#Region CostAndDepreciationAdjustment_IncreaseDecrease
	QueryText =
	"SELECT
	|	TTPortionOfDataToBeCalculated.Ref AS Ref,
	|	TTPortionOfDataToBeCalculated.Date AS Date,
	|	TTPortionOfDataToBeCalculated.Organization AS Organization,
	|	TTPortionOfDataToBeCalculated.AccountingObject AS AccountingObject,
	|	TTPortionOfDataToBeCalculated.RecordInManAccounting AS RecordInManAccounting,
	|	TTPortionOfDataToBeCalculated.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	ISNULL(FAAdjustment.PostInAccounting, ISNULL(IAAdjustment.RecordInLocalAccounting, FALSE)) AS PostInAccounting,
	|	ISNULL(FAAdjustment.RecordInTA, ISNULL(IAAdjustment.RecordInLocalAccounting, FALSE)) AS RecordInTA,
	|
	|	BEGINOFPERIOD(TTPortionOfDataToBeCalculated.Date, MONTH) AS BeginningOfDocumentPeriod,
	|	ENDOFPERIOD(TTPortionOfDataToBeCalculated.Date, MONTH) AS EndOfDocumentPeriod,
	|
	|	ISNULL(FAAdjustment.FixedAssetKind, VALUE(Enum.PropertyKinds.Own)) AS FixedAssetKind,
	|	ISNULL(FAAdjustment.DepreciationAdjustmentForPeriod, FALSE) AS DepreciationAdjustmentForPeriod,
	|
	|	ISNULL(FAAdjustment.CostAdjustment, ISNULL(IAAdjustment.CostAdjustment, FALSE)) AS CostAdjustment,
	|	ISNULL(FAAdjustment.CostIncreaseRecording, ISNULL(IAAdjustment.CostIncreaseRecording, FALSE)) AS CostIncreaseRecording,
	|	ISNULL(FAAdjustment.CostDecreaseRecording, ISNULL(IAAdjustment.CostDecreaseRecording, FALSE)) AS CostDecreaseRecording,
	|	ISNULL(FAAdjustment.RecordCostChangeInTADueToPD, FALSE) AS RecordCostChangeInTADueToPD,
	|
	|	ISNULL(FAAdjustment.DepreciationAdjustment, ISNULL(IAAdjustment.DepreciationAdjustment, FALSE)) AS DepreciationAdjustment,
	|	ISNULL(FAAdjustment.DepreciationIncreaseRecording, ISNULL(IAAdjustment.DepreciationIncreaseRecording, FALSE)) AS DepreciationIncreaseRecording,
	|	ISNULL(FAAdjustment.DepreciationDecreaseRecording, ISNULL(IAAdjustment.DepreciationDecreaseRecording, FALSE)) AS DepreciationDecreaseRecording,
	|
	|	ISNULL(FAAdjustment.BonusDepreciationAdjustment, FALSE) AS BonusDepreciationAdjustment,
	|	ISNULL(FAAdjustment.BonusDepreciationIncreaseRecording, FALSE) AS BonusDepreciationIncreaseRecording,
	|	ISNULL(FAAdjustment.BonusDepreciationDecreaseRecording, FALSE) AS BonusDepreciationDecreaseRecording,
	|
	|	ISNULL(FATable.CostInAccounting, ISNULL(TableOfIA.CostInAccounting, 0)) AS CostInAccounting,
	|	ISNULL(FATable.CostInTaxAccounting, ISNULL(TableOfIA.CostInTaxAccounting, 0)) AS CostInTaxAccounting,
	|	ISNULL(FATable.CostPermanentDifference, ISNULL(TableOfIA.CostPermanentDifference, 0)) AS CostPermanentDifference,
	|	ISNULL(FATable.CostInManagementAccounting, ISNULL(TableOfIA.CostInManagementAccounting, 0)) AS CostInManagementAccounting,
	|	ISNULL(FATable.CostTargetFinancing, ISNULL(TableOfIA.CostTargetFinancing, 0)) AS CostTargetFinancing,
	|
	|	ISNULL(FATable.DepreciationInAccounting, ISNULL(TableOfIA.DepreciationInAccounting, 0)) AS DepreciationInAccounting,
	|	ISNULL(FATable.DepreciationInTaxAccounting, ISNULL(TableOfIA.DepreciationInTaxAccounting, 0)) AS DepreciationInTaxAccounting,
	|	ISNULL(FATable.DepreciationPermanentDifferences, ISNULL(TableOfIA.DepreciationPermanentDifferences, 0)) AS DepreciationPermanentDifferences,
	|	ISNULL(FATable.DepreciationManagementAccounting, ISNULL(TableOfIA.DepreciationManagementAccounting, 0)) AS DepreciationManagementAccounting,
	|	ISNULL(FATable.FixedAssetDepreciationTargetFinancing, ISNULL(TableOfIA.FixedAssetDepreciationTargetFinancing, 0)) AS FixedAssetDepreciationTargetFinancing,
	|
	|	ISNULL(FATable.DepreciationAllowance, 0) AS DepreciationAllowance,
	|
	|	ISNULL(FAAdjustment.PeriodAdjustment, 0) AS PeriodAdjustment,
	|	ISNULL(FAAdjustment.FixedAssetsEvent.EventKindWithFixedAssets, UNDEFINED) AS EventKindWithFixedAssets
	|
	|INTO TableVNA
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment AS FAAdjustment
	|			ON FAAdjustment.Ref = TTPortionOfDataToBeCalculated.Ref
	|
	|			LEFT JOIN Document.FixedAssetCostAndDepreciationAdjustment.FA AS FATable
	|			ON FATable.Ref = TTPortionOfDataToBeCalculated.Ref
	|				AND FATable.FixedAsset = TTPortionOfDataToBeCalculated.AccountingObject
	|
	|			LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment AS IAAdjustment
	|			ON IAAdjustment.Ref = TTPortionOfDataToBeCalculated.Ref
	|
	|			LEFT JOIN Document.IntangibleAssetsCostAndAmortizationAdjustment.IA AS TableOfIA
	|			ON TableOfIA.Ref = TTPortionOfDataToBeCalculated.Ref
	|				AND TableOfIA.IntangibleAsset = TTPortionOfDataToBeCalculated.AccountingObject
	|
	|WHERE
	|	VALUETYPE(TTPortionOfDataToBeCalculated.Ref) IN (
	|		TYPE(Document.FixedAssetCostAndDepreciationAdjustment),
	|		TYPE(Document.IntangibleAssetsCostAndAmortizationAdjustment))
	|
	|	AND (ISNULL(FAAdjustment.CostAdjustment, FALSE)
	|			AND (NOT ISNULL(FAAdjustment.CostIncreaseRecording, FALSE)
	|				OR NOT ISNULL(FAAdjustment.CostDecreaseRecording, FALSE))
	|
	|		OR ISNULL(FAAdjustment.DepreciationAdjustment, FALSE)
	|			AND (NOT ISNULL(FAAdjustment.DepreciationIncreaseRecording, FALSE)
	|				OR NOT ISNULL(FAAdjustment.DepreciationDecreaseRecording, FALSE))
	|
	|		OR ISNULL(IAAdjustment.CostAdjustment, FALSE)
	|			AND (NOT ISNULL(IAAdjustment.CostIncreaseRecording, FALSE)
	|				OR NOT ISNULL(IAAdjustment.CostDecreaseRecording, FALSE))
	|
	|		OR ISNULL(IAAdjustment.DepreciationAdjustment, FALSE)
	|			AND (NOT ISNULL(IAAdjustment.DepreciationIncreaseRecording, FALSE)
	|				OR NOT ISNULL(IAAdjustment.DepreciationDecreaseRecording, FALSE)))
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableVNA.Ref       AS Ref,
	|	TableVNA.AccountingObject  AS AccountingObject,
	|
	// Cost
	|	CASE 
	|		WHEN ISNULL(CostOfVNA.Cost, 0) <> TableVNA.CostInManagementAccounting 
	|				AND TableVNA.RecordInManAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN TableVNA.CostInManagementAccounting - ISNULL(CostOfVNA.Cost, 0)
	|		ELSE 0
	|	END AS Cost,
	|
	// LocalCost
	|	CASE 
	|		WHEN ISNULL(CostOfVNA.LocalCost, 0) <> TableVNA.CostInAccounting 
	|				AND TableVNA.PostInAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN TableVNA.CostInAccounting - ISNULL(CostOfVNA.LocalCost, 0)
	|		ELSE 0
	|	END AS LocalCost,
	|
	// CostInTaxAccounting
	|	CASE 
	|		WHEN ISNULL(CostOfVNA.CostInTaxAccounting, 0) <> TableVNA.CostInTaxAccounting
	|				AND NOT TableVNA.BonusDepreciationAdjustment
	|				AND TableVNA.RecordInTA 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|			THEN TableVNA.CostInTaxAccounting - ISNULL(CostOfVNA.CostInTaxAccounting, 0)
	|
	|		WHEN ISNULL(CostOfVNA.CostInTaxAccounting, 0) <> (TableVNA.CostInTaxAccounting + TableVNA.DepreciationAllowance)
	|				AND TableVNA.BonusDepreciationAdjustment
	|				AND TableVNA.BonusDepreciationIncreaseRecording
	|				AND TableVNA.RecordInTA 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|			THEN (TableVNA.CostInTaxAccounting + TableVNA.DepreciationAllowance) - ISNULL(CostOfVNA.CostInTaxAccounting, 0)
	|
	|		WHEN ISNULL(CostOfVNA.CostInTaxAccounting, 0) <> (TableVNA.CostInTaxAccounting - TableVNA.DepreciationAllowance)
	|				AND TableVNA.BonusDepreciationAdjustment
	|				AND TableVNA.BonusDepreciationDecreaseRecording
	|				AND TableVNA.RecordInTA 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|			THEN (TableVNA.CostInTaxAccounting - TableVNA.DepreciationAllowance) - ISNULL(CostOfVNA.CostInTaxAccounting, 0)
	|
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	// CostPermanentDifference
	|	CASE 
	|		WHEN ISNULL(CostOfVNA.CostPermanentDifference, 0) <> TableVNA.CostPermanentDifference 
	|				AND TableVNA.RecordInLocalAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|				AND NOT TableVNA.RecordCostChangeInTADueToPD
	|			THEN TableVNA.CostPermanentDifference - ISNULL(CostOfVNA.CostPermanentDifference, 0)
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	// CostTargetFinancing
	|	CASE 
	|		WHEN ISNULL(CostOfVNA.CostTargetFinancing, 0) <> TableVNA.CostTargetFinancing 
	|				AND TableVNA.PostInAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|			THEN TableVNA.CostTargetFinancing - ISNULL(CostOfVNA.CostTargetFinancing, 0)
	|		ELSE 0
	|	END AS CostTargetFinancing
	|
	|INTO TTCostAdjustment
	|
	|FROM
	|	TableVNA AS TableVNA
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = TableVNA.Ref
	|			AND CostOfVNA.AccountingObject = TableVNA.AccountingObject
	|
	|WHERE
	|	TableVNA.CostAdjustment
	|
	|	AND (ISNULL(CostOfVNA.Cost, 0) <> TableVNA.CostInManagementAccounting 
	|				AND TableVNA.RecordInManAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(CostOfVNA.LocalCost, 0) <> TableVNA.CostInAccounting 
	|				AND TableVNA.PostInAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(CostOfVNA.CostInTaxAccounting, 0) <> TableVNA.CostInTaxAccounting 
	|				AND NOT TableVNA.BonusDepreciationAdjustment
	|				AND TableVNA.RecordInTA 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(CostOfVNA.CostInTaxAccounting, 0) <> (TableVNA.CostInTaxAccounting + TableVNA.DepreciationAllowance) 
	|				AND TableVNA.BonusDepreciationAdjustment
	|				AND TableVNA.BonusDepreciationIncreaseRecording
	|				AND TableVNA.RecordInTA 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(CostOfVNA.CostInTaxAccounting, 0) <> (TableVNA.CostInTaxAccounting - TableVNA.DepreciationAllowance) 
	|				AND TableVNA.BonusDepreciationAdjustment
	|				AND TableVNA.BonusDepreciationDecreaseRecording
	|				AND TableVNA.RecordInTA 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|
	|		OR ISNULL(CostOfVNA.CostPermanentDifference, 0) <> TableVNA.CostPermanentDifference 
	|				AND TableVNA.RecordInLocalAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|				AND NOT TableVNA.RecordCostChangeInTADueToPD
	|
	|		OR ISNULL(CostOfVNA.CostTargetFinancing, 0) <> TableVNA.CostTargetFinancing 
	|				AND TableVNA.PostInAccounting 
	|				AND TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own))
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableVNA.Ref AS Ref,
	|	TableVNA.AccountingObject AS AccountingObject,
	|
	|	SUM(CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|				THEN -FixedAssetsDepreciationCharge.Depreciation 
	|			ELSE FixedAssetsDepreciationCharge.Depreciation 
	|		END) AS Depreciation,
	|
	|	SUM(CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|				THEN -FixedAssetsDepreciationCharge.DepreciationLocal 
	|			ELSE FixedAssetsDepreciationCharge.DepreciationLocal 
	|		END) AS DepreciationLocal,
	|
	|	SUM(CASE 
	|			WHEN FixedAssetsDepreciationCharge.RecordType = VALUE(AccumulationRecordType.Expense) 
	|				THEN -FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing 
	|			ELSE FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing 
	|		END) AS FixedAssetDepreciationTargetFinancing
	|
	|INTO TueDepreciationOfCurrentMonth
	|
	|FROM
	|	TableVNA AS TableVNA
	|
	|		INNER JOIN AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Organization = TableVNA.Organization
	|			AND FixedAssetsDepreciationCharge.FixedAsset = TableVNA.AccountingObject
	|			AND FixedAssetsDepreciationCharge.Period >= TableVNA.BeginningOfDocumentPeriod
	|			AND FixedAssetsDepreciationCharge.Period <= TableVNA.EndOfDocumentPeriod
	|			AND VALUETYPE(FixedAssetsDepreciationCharge.Recorder) = TYPE(Document.FixedAssetsDepreciationCharge2_4)
	|
	|WHERE
	|	TableVNA.PeriodAdjustment <> 0
	|	AND TableVNA.EventKindWithFixedAssets = VALUE(Enum.EventKindsWithFixedAssets.Other)
	|
	|GROUP BY
	|	TableVNA.Ref,
	|	TableVNA.AccountingObject
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableVNA.Ref            AS Ref,
	|	TableVNA.AccountingObject       AS AccountingObject,
	|
	// Depreciation
	|	CASE 
	|		WHEN ISNULL(DepreciationOfVNA.Depreciation, 0) <> TableVNA.DepreciationManagementAccounting 
	|				AND TableVNA.RecordInManAccounting 
	|			THEN TableVNA.DepreciationManagementAccounting 
	|					- ISNULL(DepreciationOfVNA.Depreciation, 0)
	|					+ ISNULL(TueDepreciationOfCurrentMonth.Depreciation, 0)
	|		ELSE 0
	|	END AS Depreciation,
	|
	// DepreciationLocal
	|	CASE 
	|		WHEN ISNULL(DepreciationOfVNA.DepreciationLocal, 0) <> TableVNA.DepreciationInAccounting 
	|				AND TableVNA.PostInAccounting 
	|			THEN TableVNA.DepreciationInAccounting 
	|					- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|					+ ISNULL(TueDepreciationOfCurrentMonth.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	// DepreciationInTaxAccounting
	|	CASE 
	|		WHEN ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0) <> TableVNA.DepreciationInTaxAccounting 
	|				AND TableVNA.RecordInTA 
	|			THEN TableVNA.DepreciationInTaxAccounting 
	|					- ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0)
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	// DepreciationPermanentDifferences
	|	CASE 
	|		WHEN ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0) <> TableVNA.DepreciationPermanentDifferences 
	|				AND TableVNA.RecordInLocalAccounting 
	|			THEN TableVNA.DepreciationPermanentDifferences 
	|					- ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0)
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	// FixedAssetDepreciationTargetFinancing
	|	CASE 
	|		WHEN ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) <> TableVNA.FixedAssetDepreciationTargetFinancing 
	|				AND TableVNA.RecordInLocalAccounting 
	|			THEN TableVNA.FixedAssetDepreciationTargetFinancing 
	|					- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
	|					+ ISNULL(TueDepreciationOfCurrentMonth.FixedAssetDepreciationTargetFinancing, 0)
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing
	|
	|INTO TTDepreciationAdjustment
	|
	|FROM
	|	TableVNA AS TableVNA
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = TableVNA.Ref
	|			AND DepreciationOfVNA.AccountingObject = TableVNA.AccountingObject
	|
	|		LEFT JOIN TueDepreciationOfCurrentMonth AS TueDepreciationOfCurrentMonth
	|		ON TueDepreciationOfCurrentMonth.Ref = TableVNA.Ref
	|			AND TueDepreciationOfCurrentMonth.AccountingObject = TableVNA.AccountingObject
	|
	|WHERE
	|	TableVNA.FixedAssetKind = VALUE(Enum.PropertyKinds.Own)
	|	AND TableVNA.DepreciationAdjustment
	|
	|	AND (ISNULL(DepreciationOfVNA.Depreciation, 0) <> TableVNA.DepreciationManagementAccounting 
	|				AND TableVNA.RecordInManAccounting 
	|
	|		OR ISNULL(DepreciationOfVNA.DepreciationLocal, 0) <> TableVNA.DepreciationInAccounting 
	|				AND TableVNA.PostInAccounting 
	|
	|		OR ISNULL(DepreciationOfVNA.DepreciationInTaxAccounting, 0) <> TableVNA.DepreciationInTaxAccounting 
	|				AND TableVNA.RecordInTA 
	|
	|		OR ISNULL(DepreciationOfVNA.DepreciationPermanentDifferences, 0) <> TableVNA.DepreciationPermanentDifferences 
	|				AND TableVNA.RecordInLocalAccounting 
	|
	|		OR ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0) <> TableVNA.FixedAssetDepreciationTargetFinancing 
	|				AND TableVNA.RecordInLocalAccounting)
	|
	|INDEX BY
	|	Ref,
	|	AccountingObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableVNA.Ref AS Ref,
	|	TableVNA.Organization AS Organization,
	|	TableVNA.AccountingObject AS AccountingObject,
	|	ISNULL(Assets.Presentation, IntangibleAssets.Presentation) AS AccountingObjectPresentation,
	|
	|	MAX(TableVNA.ReflectionOfIncreaseInCostOfMA) AS ReflectionOfIncreaseInCostOfMA,
	|	MAX(TableVNA.ReflectionOfACCostIncrease) AS ReflectionOfACCostIncrease,
	|	MAX(TableVNA.ReflectionOfTACostIncrease) AS ReflectionOfTACostIncrease,
	|	MAX(TableVNA.ReflectionOfIncreaseInCostOfTF) AS ReflectionOfIncreaseInCostOfTF,
	|
	|	MAX(TableVNA.ReflectionOfMACostReduction) AS ReflectionOfMACostReduction,
	|	MAX(TableVNA.ReflectionOfACCostReduction) AS ReflectionOfACCostReduction,
	|	MAX(TableVNA.ReflectionOfCostReductionTA) AS ReflectionOfCostReductionTA,
	|	MAX(TableVNA.ReflectionOfDecreaseInCostOfTF) AS ReflectionOfDecreaseInCostOfTF,
	|
	|	MAX(TableVNA.ReflectionOfIncreaseInMADepreciation) AS ReflectionOfIncreaseInMADepreciation,
	|	MAX(TableVNA.ReflectionOfIncreaseInACDepreciation) AS ReflectionOfIncreaseInACDepreciation,
	|	MAX(TableVNA.ReflectionOfIncreaseInDepreciationTA) AS ReflectionOfIncreaseInDepreciationTA,
	|	MAX(TableVNA.ReflectionOfIncreaseInTFDepreciation) AS ReflectionOfIncreaseInTFDepreciation,
	|
	|	MAX(TableVNA.ReflectionOfDecreaseInMADepreciation) AS ReflectionOfDecreaseInMADepreciation,
	|	MAX(TableVNA.ReflectionOfDecreaseInACDepreciation) AS ReflectionOfDecreaseInACDepreciation,
	|	MAX(TableVNA.ReflectionOfDepreciationReductionTA) AS ReflectionOfDepreciationReductionTA,
	|	MAX(TableVNA.ReflectionOfDecreaseInTFDepreciation) AS ReflectionOfDecreaseInTFDepreciation
	|
	|FROM
	|	(SELECT
	|		TableVNA.Ref AS Ref,
	|		TableVNA.Organization AS Organization,
	|		TableVNA.AccountingObject AS AccountingObject,
	|
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostDecreaseRecording
	|					AND TTCostAdjustment.Cost < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfIncreaseInCostOfMA,
	|	
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostDecreaseRecording
	|					AND TTCostAdjustment.LocalCost < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfACCostIncrease,
	|	
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostDecreaseRecording
	|					AND TTCostAdjustment.CostInTaxAccounting < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfTACostIncrease,
	|	
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostDecreaseRecording
	|					AND TTCostAdjustment.CostTargetFinancing < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfIncreaseInCostOfTF,
	|	
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostIncreaseRecording
	|					AND TTCostAdjustment.Cost > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfMACostReduction,
	|
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostIncreaseRecording
	|					AND TTCostAdjustment.LocalCost > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfACCostReduction,
	|
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostIncreaseRecording
	|					AND TTCostAdjustment.CostInTaxAccounting > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfCostReductionTA,
	|
	|		CASE
	|			WHEN TableVNA.CostAdjustment
	|					AND NOT TableVNA.CostIncreaseRecording
	|					AND TTCostAdjustment.CostTargetFinancing > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfDecreaseInCostOfTF,
	|
	|		FALSE AS ReflectionOfIncreaseInMADepreciation,
	|		FALSE AS ReflectionOfIncreaseInACDepreciation,
	|		FALSE AS ReflectionOfIncreaseInDepreciationTA,
	|		FALSE AS ReflectionOfIncreaseInTFDepreciation,
	|
	|		FALSE AS ReflectionOfDecreaseInMADepreciation,
	|		FALSE AS ReflectionOfDecreaseInACDepreciation,
	|		FALSE AS ReflectionOfDepreciationReductionTA,
	|		FALSE AS ReflectionOfDecreaseInTFDepreciation
	|
	|	FROM
	|		TableVNA AS TableVNA
	|
	|			INNER JOIN TTCostAdjustment AS TTCostAdjustment
	|			ON TTCostAdjustment.Ref = TableVNA.Ref
	|				AND TTCostAdjustment.AccountingObject = TableVNA.AccountingObject
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableVNA.Ref AS Ref,
	|		TableVNA.Organization AS Organization,
	|		TableVNA.AccountingObject AS AccountingObject,
	|
	|		FALSE AS ReflectionOfIncreaseInCostOfMA,
	|		FALSE AS ReflectionOfACCostIncrease,
	|		FALSE AS ReflectionOfTACostIncrease,
	|		FALSE AS ReflectionOfIncreaseInCostOfTF,
	|
	|		FALSE AS ReflectionOfMACostReduction,
	|		FALSE AS ReflectionOfACCostReduction,
	|		FALSE AS ReflectionOfCostReductionTA,
	|		FALSE AS ReflectionOfDecreaseInCostOfTF,
	|
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationDecreaseRecording
	|					AND TTDepreciationAdjustment.Depreciation < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfIncreaseInMADepreciation,
	|	
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationDecreaseRecording
	|					AND TTDepreciationAdjustment.DepreciationLocal < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfIncreaseInACDepreciation,
	|	
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationDecreaseRecording
	|					AND TTDepreciationAdjustment.DepreciationInTaxAccounting < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfIncreaseInDepreciationTA,
	|	
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationDecreaseRecording
	|					AND TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing < 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfIncreaseInTFDepreciation,
	|	
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationIncreaseRecording
	|					AND TTDepreciationAdjustment.Depreciation > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfDecreaseInMADepreciation,
	|	
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationIncreaseRecording
	|					AND TTDepreciationAdjustment.DepreciationLocal > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfDecreaseInACDepreciation,
	|	
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationIncreaseRecording
	|					AND TTDepreciationAdjustment.DepreciationInTaxAccounting > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfDepreciationReductionTA,
	|	
	|		CASE
	|			WHEN TableVNA.DepreciationAdjustment
	|					AND NOT TableVNA.DepreciationIncreaseRecording
	|					AND TTDepreciationAdjustment.FixedAssetDepreciationTargetFinancing > 0
	|				THEN TRUE 
	|			ELSE FALSE
	|		END AS ReflectionOfDecreaseInTFDepreciation
	|
	|	FROM
	|		TableVNA AS TableVNA
	|
	|			INNER JOIN TTDepreciationAdjustment AS TTDepreciationAdjustment
	|			ON TTDepreciationAdjustment.Ref = TableVNA.Ref
	|				AND TTDepreciationAdjustment.AccountingObject = TableVNA.AccountingObject
	|
	|	) AS TableVNA
	|
	|		LEFT JOIN Catalog.Assets AS Assets
	|		ON Assets.Ref = TableVNA.AccountingObject
	|
	|		LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|		ON IntangibleAssets.Ref = TableVNA.AccountingObject
	|
	|GROUP BY
	|	TableVNA.Ref,
	|	TableVNA.Organization,
	|	TableVNA.AccountingObject,
	|	ISNULL(Assets.Presentation, IntangibleAssets.Presentation)
	|
	|HAVING
	|	(MAX(TableVNA.ReflectionOfIncreaseInCostOfMA)
	|		OR MAX(TableVNA.ReflectionOfACCostIncrease)
	|		OR MAX(TableVNA.ReflectionOfTACostIncrease)
	|		OR MAX(TableVNA.ReflectionOfIncreaseInCostOfTF)
	|
	|		OR MAX(TableVNA.ReflectionOfMACostReduction)
	|		OR MAX(TableVNA.ReflectionOfACCostReduction)
	|		OR MAX(TableVNA.ReflectionOfCostReductionTA)
	|		OR MAX(TableVNA.ReflectionOfDecreaseInCostOfTF)
	|
	|		OR MAX(TableVNA.ReflectionOfIncreaseInMADepreciation)
	|		OR MAX(TableVNA.ReflectionOfIncreaseInACDepreciation)
	|		OR MAX(TableVNA.ReflectionOfIncreaseInDepreciationTA)
	|		OR MAX(TableVNA.ReflectionOfIncreaseInTFDepreciation)
	|
	|		OR MAX(TableVNA.ReflectionOfDecreaseInMADepreciation)
	|		OR MAX(TableVNA.ReflectionOfDecreaseInACDepreciation)
	|		OR MAX(TableVNA.ReflectionOfDepreciationReductionTA)
	|		OR MAX(TableVNA.ReflectionOfDecreaseInTFDepreciation))
	|
	|ORDER BY
	|	Ref,
	|	AccountingObject
	|";
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		ThisIsIA = (TypeOf(Selection.Ref) = Type("DocumentRef.IntangibleAssetsCostAndAmortizationAdjustment"));
		
		If Selection.ReflectionOfIncreaseInCostOfMA Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (KTQT) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для нематериального актива ""%1"" стоимость (УУ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (YM), gerçek değerden daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (KTQT) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для основного средства ""%1"" стоимость (УУ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (YM), gerçek değerden daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);

			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
				
		ElsIf Selection.ReflectionOfMACostReduction Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (KTQT) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для нематериального актива ""%1"" стоимость (УУ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (MA) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (YM), gerçek değerden daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (KTQT) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для основного средства ""%1"" стоимость (УУ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (MA) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (YM), gerçek değerden daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
		If Selection.ReflectionOfACCostIncrease Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (KTDN) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для нематериального актива ""%1"" стоимость (БУ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (Muhasebe), gerçek değerden daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (KTDN) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для основного средства ""%1"" стоимость (БУ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (Muhasebe), gerçek değerden daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);

			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
				
		ElsIf Selection.ReflectionOfACCostReduction Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (KTDN) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для нематериального актива ""%1"" стоимость (БУ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (LA) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (Muhasebe), gerçek değerden daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (KTDN) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для основного средства ""%1"" стоимость (БУ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (LA) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (Muhasebe), gerçek değerden daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
		If Selection.ReflectionOfTACostIncrease Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (KTTh) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для нематериального актива ""%1"" стоимость (НУ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (VM), gerçek değerden daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (KTTh) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для основного средства ""%1"" стоимость (НУ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (VM), gerçek değerden daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);

			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
				
		ElsIf Selection.ReflectionOfCostReductionTA Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (KTTh) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для нематериального актива ""%1"" стоимость (НУ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TA) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (VM), gerçek değerden daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (KTTh) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для основного средства ""%1"" стоимость (НУ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TA) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (VM), gerçek değerden daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
		If Selection.ReflectionOfIncreaseInCostOfTF Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (CF) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для нематериального актива ""%1"" стоимость (ЦФ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (HF), gerçek değerden daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (CF) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения стоимости, но для основного средства ""%1"" стоимость (ЦФ), указанная в документе, меньше фактической.';
									|en = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is less than the actual cost.'; fa = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is less than the actual cost.';
									|it = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is less than the actual cost.';
									|pl = 'Only cost increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is less than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer artışını yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (HF), gerçek değerden daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);

			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);
				
		ElsIf Selection.ReflectionOfDecreaseInCostOfTF Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản vô hình ""%1"" giá trị (CF) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для нематериального актива ""%1"" стоимость (ЦФ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the cost (TF) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen değer (HF), gerçek değerden daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm giá trị, nhưng đối với tài sản hữu hình ""%1"" giá trị (CF) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только уменьшения стоимости, но для основного средства ""%1"" стоимость (ЦФ), указанная в документе, больше фактической.';
									|en = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is greater than the actual cost.'; fa = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is greater than the actual cost.';
									|it = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is greater than the actual cost.';
									|pl = 'Only cost decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the cost (TF) specified in the document is greater than the actual cost.';
									|tr = 'Belge parametrelerinde sadece değer düşüşünü yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen değer (HF), gerçek değerden daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
		If Selection.ReflectionOfIncreaseInMADepreciation Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (KTQT) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для нематериального актива ""%1"" амортизация (УУ), указанная в документе, меньше фактической.';
									|en = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is less than the actual amortization.'; fa = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is less than the actual amortization.';
									|it = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is less than the actual amortization.';
									|pl = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is less than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen amortisman (YM), gerçek amortismandan daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (KTQT) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для основного средства ""%1"" амортизация (УУ), указанная в документе, меньше фактической.';
									|en = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is less than the actual depreciation.'; fa = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is less than the actual depreciation.';
									|it = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is less than the actual depreciation.';
									|pl = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is less than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen amortisman (YM), gerçek amortismandan daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		ElsIf Selection.ReflectionOfDecreaseInMADepreciation Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (KTQT) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для нематериального актива ""%1"" амортизация (УУ), указанная в документе, больше фактической.';
									|en = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is greater than the actual amortization.'; fa = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is greater than the actual amortization.';
									|it = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is greater than the actual amortization.';
									|pl = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (MA) specified in the document is greater than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman düşüşünü yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen amortisman (YM), gerçek amortismandan daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (KTQT) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для основного средства ""%1"" амортизация (УУ), указанная в документе, больше фактической.';
									|en = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is greater than the actual depreciation.'; fa = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is greater than the actual depreciation.';
									|it = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is greater than the actual depreciation.';
									|pl = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (MA) specified in the document is greater than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman düşüşünü yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen amortisman (YM), gerçek amortismandan daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
		If Selection.ReflectionOfIncreaseInACDepreciation Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (KTDN) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для нематериального актива ""%1"" амортизация (БУ), указанная в документе, меньше фактической.';
									|en = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is less than the actual amortization.'; fa = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is less than the actual amortization.';
									|it = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is less than the actual amortization.';
									|pl = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is less than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen amortisman (Muhasebe), gerçek amortismandan daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (KTQT) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для основного средства ""%1"" амортизация (БУ), указанная в документе, меньше фактической.';
									|en = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is less than the actual depreciation.'; fa = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is less than the actual depreciation.';
									|it = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is less than the actual depreciation.';
									|pl = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is less than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, fakat ""%1"" ana sabit kıymeti için belgede belirtilen amortisman (muhasebe), gerçek amortismandan daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		ElsIf Selection.ReflectionOfDecreaseInACDepreciation Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (KTDN) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для нематериального актива ""%1"" амортизация (БУ), указанная в документе, больше фактической.';
									|en = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is greater than the actual amortization.'; fa = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is greater than the actual amortization.';
									|it = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is greater than the actual amortization.';
									|pl = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (LA) specified in the document is greater than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, fakat ""%1"" gayrimaddi varlığı için belgede belirtilen amortisman (muhasebe), gerçek amortismandan daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (KTDN) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для основного средства ""%1"" амортизация (БУ), указанная в документе, больше фактической.';
									|en = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is greater than the actual depreciation.'; fa = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is greater than the actual depreciation.';
									|it = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is greater than the actual depreciation.';
									|pl = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (LA) specified in the document is greater than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman düşüşünü yansıtacak şekilde seçilmiştir, fakat sabit kıymet ""%1"" için belgede belirtilen amortisman (muhasebe), gerçek amortismandan daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
		If Selection.ReflectionOfIncreaseInDepreciationTA Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (KTTh) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для нематериального актива ""%1"" амортизация (НУ), указанная в документе, меньше фактической.';
									|en = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is less than the actual amortization.'; fa = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is less than the actual amortization.';
									|it = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is less than the actual amortization.';
									|pl = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is less than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, fakat gayrimaddi varlık ""%1"" için belgede belirtilen amortisman (muhasebe), gerçek amortismandan daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (KTTh) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для основного средства ""%1"" амортизация (НУ), указанная в документе, меньше фактической.';
									|en = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is less than the actual depreciation.'; fa = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is less than the actual depreciation.';
									|it = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is less than the actual depreciation.';
									|pl = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is less than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, fakat gayrimaddi varlık ""%1"" için belgede belirtilen amortisman (muhasebe), gerçek amortismandan daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		ElsIf Selection.ReflectionOfDepreciationReductionTA Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (KTTh) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для нематериального актива ""%1"" амортизация (НУ), указанная в документе, больше фактической.';
									|en = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is greater than the actual amortization.'; fa = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is greater than the actual amortization.';
									|it = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is greater than the actual amortization.';
									|pl = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TA) specified in the document is greater than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman düşüşünü yansıtacak şekilde seçilmiştir, fakat gayrimaddi varlık ""%1"" için belgede belirtilen amortisman (muhasebe), gerçek amortismandan daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (KTTh) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для основного средства ""%1"" амортизация (НУ), указанная в документе, больше фактической.';
									|en = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is greater than the actual depreciation.'; fa = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is greater than the actual depreciation.';
									|it = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is greater than the actual depreciation.';
									|pl = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TA) specified in the document is greater than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman düşüşünü yansıtacak şekilde seçilmiştir, fakat sabit kıymet ""%1"" için belgede belirtilen amortisman (muhasebe), gerçek amortismandan daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
		If Selection.ReflectionOfIncreaseInTFDepreciation Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (CF) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для нематериального актива ""%1"" амортизация (ЦФ), указанная в документе, меньше фактической.';
									|en = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is less than the actual amortization.'; fa = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is less than the actual amortization.';
									|it = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is less than the actual amortization.';
									|pl = 'Only amortization increase recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is less than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen amortisman (HF), gerçek amortismandan daha azdır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ tăng khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (CF) được chỉ ra trong chứng từ nhỏ hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано отражение только увеличения амортизации, но для основного средства ""%1"" амортизация (ЦФ), указанная в документе, меньше фактической.';
									|en = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is less than the actual depreciation.'; fa = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is less than the actual depreciation.';
									|it = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is less than the actual depreciation.';
									|pl = 'Only depreciation increase recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is less than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman artışını yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen amortisman (HF), gerçek amortismandan daha azdır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		ElsIf Selection.ReflectionOfDecreaseInTFDepreciation Then
			
			If ThisIsIA Then
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm khấu hao, nhưng đối với tài sản vô hình ""%1"" khấu hao (CF) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для нематериального актива ""%1"" амортизация (ЦФ), указанная в документе, больше фактической.';
									|en = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is greater than the actual amortization.'; fa = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is greater than the actual amortization.';
									|it = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is greater than the actual amortization.';
									|pl = 'Only amortization decrease recording is selected in the document parameters, but for the ""%1"" intangible asset, the amortization (TF) specified in the document is greater than the actual amortization.';
									|tr = 'Belge parametrelerinde sadece amortisman düşüşünü yansıtacak şekilde seçilmiştir, ancak maddi olmayan varlık “%1” için belgede belirtilen amortisman (HF), gerçek amortismandan daha fazladır.'");
			Else
				IssueDetails = NStr("vi = 'Trong các tham số chứng từ, đã chọn phản ánh chỉ giảm khấu hao, nhưng đối với tài sản hữu hình ""%1"" khấu hao (CF) được chỉ ra trong chứng từ lớn hơn giá trị thực tế.';
									|ru = 'В параметрах документа выбрано только отражение уменьшения амортизации, но для основного средства ""%1"" амортизация (ЦФ), указанная в документе, больше фактической.';
									|en = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is greater than the actual depreciation.'; fa = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is greater than the actual depreciation.';
									|it = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is greater than the actual depreciation.';
									|pl = 'Only depreciation decrease recording is selected in the document parameters, but for the ""%1"" fixed asset, the depreciation (TF) specified in the document is greater than the actual depreciation.';
									|tr = 'Belge parametrelerinde sadece amortisman düşüşünü yansıtacak şekilde seçilmiştir, ancak sabit kıymet “%1” için belgede belirtilen amortisman (HF), gerçek amortismandan daha fazladır.'");
			EndIf;
			
			IssueDetails = StrTemplate(IssueDetails, Selection.AccountingObjectPresentation);
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionWarning(
				ExecutionParameters.MonthClosingOperation, 
				Period,
				Selection.Organization,
				IssueDetails,,
				Selection.Ref);

		EndIf;
		
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	#EndRegion	

	DeferredFARecordGenerationLocalization.CheckDeferredMovementFormation(Period, ExecutionParameters);
	
	Query.Text =
	"SELECT
	|	TTPortionOfDataToBeCalculated.AccountingObject
	|
	|INTO TTErrors
	|
	|FROM
	|	TTPortionOfDataToBeCalculated AS TTPortionOfDataToBeCalculated
	|
	|WHERE
	|	TTPortionOfDataToBeCalculated.Ref IN (&Documents_With_Errors)
	|";
	Query.SetParameter("Documents_With_Errors", Documents_With_Errors);
	Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Procedure DeleteTasksPortionsOfData(Period, ExecutionParameters)
	
	If Not ExecutionParameters.DeleteTasks Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.DeleteTasksPortionsOfData");

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
	
	InformationRegisters.JobsForGeneratingFixedAssetRecords.FixCalculation(
		Period,
		ExecutionParameters.CompaniesList, 
		ExecutionParameters.NumberBeforeSettlement, 
		ExecutionParameters.TempTablesManager,
		"TTTasksToDelete");

	TMCommonUse.DestroyTemporaryTables(ExecutionParameters.TempTablesManager,, TTUsed);

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Procedure DeleteTasksByDate(ExecutionParameters)
	
	If Not ExecutionParameters.DeleteTasks Then
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("DeferredFARecordGeneration.DeleteTasksByDate");

	InformationRegisters.JobsForGeneratingFixedAssetRecords.FixCalculation(
		ExecutionParameters.EndOfPeriod,
		ExecutionParameters.CompaniesList, 
		ExecutionParameters.NumberBeforeSettlement, 
		ExecutionParameters.TempTablesManager,
		"ListOfObjects");
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Procedure RememberProcessedData(ExecutionParameters)
	
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
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProcessedOneData
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
		
	Query = New Query(QueryText);
	Query.TempTablesManager = ExecutionParameters.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

Function CreateTaskQueue(BeginOfPeriod, EndOfPeriod, CompaniesList, NumberBeforeSettlement, TempTablesManager, MonthClosingOperation, DeleteTasks)

	TTUsed = TMCommonUse.ListOfTemporaryTables(TempTablesManager);

	MaximumNumberOfTasks = MaximumNumberOfTasks();

	TaskQueue = NonCurrentAssets.InitiateTaskQueue();
	
	CreateTTTableWithListOfDocuments(BeginOfPeriod, EndOfPeriod, CompaniesList, TempTablesManager);

	ObjectQueue = NonCurrentAssets.QueueOfSLEObjects(TempTablesManager, MaximumNumberOfTasks);
	
	MaximumQueueNumber = 1;
	For Each Selection In ObjectQueue Do
		MaximumQueueNumber = Max(Selection.QueueNumber, MaximumQueueNumber);
	EndDo;
	
	For Each Selection In ObjectQueue Do
		
		If TaskQueue.Count() < Selection.QueueNumber Then
			
			TaskData_ = TaskQueue.Add();
			TaskData_.CalculationProcedure_ = "DeferredFARecordGeneration.PerformOfOperationOnObjects";
			
			If MaximumNumberOfTasks > 1 Then
				TaskData_.BackgroundJobDescription = 
					StrTemplate(
					NStr("vi = 'Tạo bản ghi kết chuyển theo TSCĐ hữu hình và TSCĐ vô hình (nhiệm vụ %1 trong số %2)';
						|ru = 'Формирование движений по ОС и НМА (задание %1 из %2)';
						|en = 'Generate fixed asset and intangible asset records (job %1 out of %2)'; fa = 'Generate fixed asset and intangible asset records (job %1 out of %2)';
						|it = 'Формирование движений по ОС и НМА (задание %1 из %2)';
						|pl = 'Generate fixed asset and intangible asset records (job %1 out of %2)';
						|tr = 'Sabit kıymetler ve maddi olmayan varlıklar kapsamındaki hareketlerin oluşturulması (%2 üzerindeki %1 görevi)'"), 
					Format(Selection.QueueNumber, "ND=2; NLZ=; NG=;"), 
					MaximumQueueNumber); 
			Else
				TaskData_.BackgroundJobDescription = NStr("vi = 'Lập các lưu chuyển trong TSCĐ hữu hình và TSCĐ vô hình';
															|ru = 'Формирование движений по ОС и НМА';
															|en = 'Generate fixed asset and intangible asset records'; fa = 'ایجاد سوابق دارایی ثابت و دارایی نامشهود';
															|it = 'Generazione dei movimenti relativi al capitale fisso e attività immateriali';
															|pl = 'Formowanie ruchu dla ŚT oraz WNM';
															|tr = 'SV ve GMA doğrultusunda hareketlerin düzenlenmesi'"); 
			EndIf;

			ExecutionParameters = ExecutionParameters();
			ExecutionParameters.BeginOfPeriod = BegOfMonth(BeginOfPeriod);
			ExecutionParameters.EndOfPeriod = EndOfMonth(EndOfPeriod);
			ExecutionParameters.CompaniesList = CompaniesList;
			ExecutionParameters.ExecuteCheck = True;
			ExecutionParameters.NumberBeforeSettlement = NumberBeforeSettlement;
			ExecutionParameters.MonthClosingOperation = MonthClosingOperation;
			ExecutionParameters.DeleteTasks = DeleteTasks;
			
			TaskData_.JobParameters = ExecutionParameters;
			
		Else
			TaskData_ = TaskQueue[Selection.QueueNumber - 1];
		EndIf;
		
		ObjectParameters = TaskData_.JobParameters.ListOfObjects.Add();
		ObjectParameters.AccountingObject = Selection.AccountingObject;
		
	EndDo;

	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TTUsed);
	
	Return TaskQueue;
	
EndFunction

Procedure CreateTTTableWithListOfDocuments(BeginOfPeriod, EndOfPeriod, CompaniesList, TempTablesManager)
	
	QueryText =
	"SELECT DISTINCT
	|	CurrentDocuments.Ref AS Ref
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS CurrentDocuments
	|
	|WHERE
	|	CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CurrentDocuments.Organization IN (&CompaniesList)
	|	AND CurrentDocuments.RefType IN (&DocumentIDs)
	|	AND CurrentDocuments.Posted
	|
	|	AND CurrentDocuments.FixedAsset IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CurrentDocuments.Ref AS Ref
	|FROM
	|	InformationRegister.IntangibleAssetsDocuments AS CurrentDocuments
	|
	|WHERE
	|	CurrentDocuments.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CurrentDocuments.Organization IN (&CompaniesList)
	|	AND CurrentDocuments.RefType IN (&DocumentIDs)
	|	AND CurrentDocuments.Posted
	|
	|	AND CurrentDocuments.IntangibleAsset IN (
	|			SELECT
	|				JobsForCalculating.AccountingObject
	|			FROM
	|				JobsForCalculating AS JobsForCalculating)
	|
	|INDEX BY
	|	Ref
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("CompaniesList", CompaniesList);
	
	Query.SetParameter("DocumentIDs", 
		NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	
	Query.Execute();
	
EndProcedure

Function ThereAreDocumentsAccordingToWhichRegisteredRecordsAreFormed(HandlerParameters)

	CalculationParameters = HandlerParameters.CalculationParameters;
	
	If Not NonCurrentAssets.VNAManagementIsUsed_2_4(CalculationParameters.Period) Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	1
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|WHERE
	|	FixedAssetsDocuments.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND FixedAssetsDocuments.Organization IN(&Organization)
	|	AND FixedAssetsDocuments.Posted
	|	AND FixedAssetsDocuments.RefType IN(&DocumentTypes)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|WHERE
	|	IntangibleAssetsDocuments.Date BETWEEN &BegOfMonth AND &EndOfMonth
	|	AND IntangibleAssetsDocuments.Organization IN(&Organization)
	|	AND IntangibleAssetsDocuments.Posted
	|	AND IntangibleAssetsDocuments.RefType IN(&DocumentTypes)";
	
	Query = New Query(QueryText);
	Query.SetParameter("BegOfMonth", BegOfMonth(CalculationParameters.Period));
	Query.SetParameter("EndOfMonth", EndOfMonth(CalculationParameters.Period));
	Query.SetParameter("Organization", CalculationParameters.CompanyArray);
	Query.SetParameter("DocumentTypes", NonCurrentAssetsCached.IdsOfDocumentsForGeneratingDeferredTraffic());
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

Function UpdatingOfRegisteredRecordsIsRequiredBeforeCalculatingDepreciation(HandlerParameters)
	
	Result = New Structure;
	Result.Insert("UpdatingOfRegisteredRecordsIsRequired", False);
	Result.Insert("ThereAreTasksForFADepreciationCalculation", False);
	Result.Insert("ThereAreTasksForTasksForCalculatingDepreciationOfIA", False);
	
	DataOfTasks = NonCurrentAssets.TaskDataByEndOfMonth(
		HandlerParameters.CalculationParameters.EndOfPeriod, 
		HandlerParameters.CalculationParameters.CompanyArray, 
		Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords.Name);
	
	If DataOfTasks.ObjectCount = 0
		Or DataOfTasks.SettlementStartDate = '00010101' Then
		Return Result;
	EndIf;
	
	TaskDataDepreciationOfFA = NonCurrentAssets.TaskDataByEndOfMonth(
		HandlerParameters.CalculationParameters.EndOfPeriod, 
		HandlerParameters.CalculationParameters.CompanyArray, 
		Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation.Name);
		
	DataOfTasksIsIntangibleAssetAmortizationCharge = NonCurrentAssets.TaskDataByEndOfMonth(
		HandlerParameters.CalculationParameters.EndOfPeriod, 
		HandlerParameters.CalculationParameters.CompanyArray,
		Metadata.InformationRegisters.JobsForCalculatingIntangibleAssetAmortization.Name);
	
	Result.ThereAreTasksForFADepreciationCalculation = 
		TaskDataDepreciationOfFA.ObjectCount <> 0
		And TaskDataDepreciationOfFA.SettlementStartDate <> '00010101';
			
	Result.ThereAreTasksForTasksForCalculatingDepreciationOfIA = 
		DataOfTasksIsIntangibleAssetAmortizationCharge.ObjectCount <> 0
		And DataOfTasksIsIntangibleAssetAmortizationCharge.SettlementStartDate <> '00010101';

	If Not Result.ThereAreTasksForFADepreciationCalculation 
		And Not Result.ThereAreTasksForTasksForCalculatingDepreciationOfIA Then
		Return Result;
	EndIf;
	
	ThereIsCalculationFromDateOfFARegistration = False;
	ThereIsCalculationFromDateOfAcceptanceOfIA = False;
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
		
	MAAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesForOrganizations(
		Metadata.InformationRegisters.FinancialAccountingPolicy.Name, 
		HandlerParameters.CalculationParameters.CompanyArray, 
		HandlerParameters.CalculationParameters.EndOfPeriod);
	
	For Each Item In MAAccountingSettings Do
		
		If Result.ThereAreTasksForFADepreciationCalculation
				And (Item.ProcedureOfFixedAssetDepreciationCharge = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
					Or Item.LeasedAssetDepreciationChargeProcedureManag = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
					Or Item.ProcedureOfFixedAssetDepreciationChargeLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
						And Not ComplianceCAAccountingIsKept
					Or Item.LeasedFixedAssetDepreciationChargeProcedureLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
						And Not ComplianceCAAccountingIsKept) Then
						
			ThereIsCalculationFromDateOfFARegistration = True;
			Break;
		EndIf;
		
		If Result.ThereAreTasksForTasksForCalculatingDepreciationOfIA
				And (Item.ProcedureOfIntangibleAssetAmortizationCharge = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
					Or Item.ProcedureOfIntangibleAssetAmortizationChargeLocal = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting
						And Not ComplianceCAAccountingIsKept) Then
						
			ThereIsCalculationFromDateOfAcceptanceOfIA = True;
			Break;
		EndIf;
		
	EndDo;
	
	
	If Not (BegOfMonth(DataOfTasks.SettlementStartDate) < BegOfMonth(TaskDataDepreciationOfFA.SettlementStartDate)
				Or BegOfMonth(DataOfTasks.SettlementStartDate) = BegOfMonth(TaskDataDepreciationOfFA.SettlementStartDate)
					And ThereIsCalculationFromDateOfFARegistration
				Or BegOfMonth(DataOfTasks.SettlementStartDate) < BegOfMonth(DataOfTasksIsIntangibleAssetAmortizationCharge.SettlementStartDate)
				Or BegOfMonth(DataOfTasks.SettlementStartDate) = BegOfMonth(DataOfTasksIsIntangibleAssetAmortizationCharge.SettlementStartDate)
					And ThereIsCalculationFromDateOfAcceptanceOfIA) Then
	
		Return Result;
	EndIf;
	
	HandlerParameters.Data_Stage.SettlementStartDate = DataOfTasks.SettlementStartDate;

	StateTemplate = ?(DataOfTasks.ObjectCount = 1,
		NStr("vi = 'Cần thực hiện giao dịch bắt đầu từ kỳ %1 theo đối tượng %2';
			|ru = 'Требуется выполнение операции начиная с периода %1 по %2 объекту';
			|en = 'Perform month-end closing starting from %1 for the %2 object'; fa = 'Perform month-end closing starting from %1 for the %2 object';
			|it = 'Требуется выполнение операции начиная с периода %1 по %2 объекту';
			|pl = 'Perform month-end closing starting from %1 for the %2 object';
			|tr = '%2 nesnesine göre %1 döneminden bir işlem gerçekleştirilmesi gerekmektedir'", Common.DefaultLanguageCode()),
		NStr("vi = 'Cần thực hiện giao dịch bắt đầu từ kỳ %1 theo các đối tượng %2';
			|ru = 'Требуется выполнение операции начиная с периода %1 по %2 объектам';
			|en = 'Perform month-end closing starting from %1 for the %2 objects'; fa = 'Perform month-end closing starting from %1 for the %2 objects';
			|it = 'Требуется выполнение операции начиная с периода %1 по %2 объектам';
			|pl = 'Perform month-end closing starting from %1 for the %2 objects';
			|tr = '%2 nesnelerine göre %1 döneminden bir işlem gerçekleştirilmesi gerekmektedir'", Common.DefaultLanguageCode()));
			
	MonthEndTransactionsServer.SetStateFailed(
		HandlerParameters,
		StringFunctionsClientServer.SubstituteParametersToString(
			StateTemplate,
			CostCalculationProtocol.PresentationOfCalculationPeriod(DataOfTasks.SettlementStartDate),
			Format(DataOfTasks.ObjectCount, "NG=3,0;")));
	
	Result.UpdatingOfRegisteredRecordsIsRequired = True;
	
	Return Result;
		
EndFunction

#EndRegion

#Region Other

Procedure SetFlagForOperation(DocumentObject, OperationName = "") Export
	
	If OperationName = "" Then
		OperationName = NameOfFlagOfOperation();
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert(OperationName, True);
	
EndProcedure

Function MaximumNumberOfTasks()

	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords); // Number
							
	MaximumNumberOfTasks = ParameterValues.MaximumNumberOfTasks; // Number
	
	Return MaximumNumberOfTasks;

EndFunction

Function DataChunkSize()
	
	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.GenerateFixedAssetAndIntangibleAssetRecords);
  							
	DataChunkSize = ParameterValues.DataChunkSize; // Number
	 		
	Return DataChunkSize;
	
EndFunction

Function TypesOfDocumentsThatCanAccrueDepreciation() Export

	ObjectsTypes = New Array;
	
	NonCurrentAssetsInternal.AddMetadataObjectType("FixedAssetsDepreciationCharge2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("IntangibleAssetsAmortizationCharge2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("RegisterAdjustment", False, ObjectsTypes);
	
	Return ObjectsTypes;
	
EndFunction

Function TypesOfDocumentsThatChangeValueAtEndOfMonth() Export
	
	ObjectsTypes = New Array;
	
	NonCurrentAssetsInternal.AddMetadataObjectType("FixedAssetsDepreciationCharge2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("IntangibleAssetsAmortizationCharge2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("RegisterAdjustment", False, ObjectsTypes);
	
	DeferredFARecordGenerationLocalization.SupplementTypesOfDocumentsThatChangeValueAtEndOfMonth(ObjectsTypes);

	Return ObjectsTypes;
	
EndFunction

Function TypesOfWriteOffDocuments()
	
	ObjectsTypes = New Array;
	
	NonCurrentAssetsInternal.AddMetadataObjectType("DisposeFixedAssets2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("DisposeIntangibleAssets2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("PreparingForFixedAssetSale2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("PreparingForIntangibleAssetSale2_4", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("LeaseTermination", False, ObjectsTypes);
	NonCurrentAssetsInternal.AddMetadataObjectType("ProvideAssetsToLeasee2_4", False, ObjectsTypes);
	
	Return ObjectsTypes;
	
EndFunction

Function TypesOfDocumentsThatDoNotSupportBatchMode()
	
	DocumentTypes = New Array;
	DocumentTypes.Add(Type("DocumentRef.VendorInvoiceLeasedAssets"));
	DocumentTypes.Add(Type("DocumentRef.SigningOfLeaseContract"));
	DocumentTypes.Add(Type("DocumentRef.LeaseTermAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.FutureExpenseCommitmentsAccrualWriteOff"));
	DocumentTypes.Add(Type("DocumentRef.LeaseTermination"));
	
	Return DocumentTypes;
	
EndFunction

Procedure GenerateTableOfCalculationsForFinancialInstrumentsByFA(TablesData)

	If TablesData.TempTablesManager.Tables.Find("FinancialInstrumentsARAPUpdate") = Undefined Then
		Return;	
	EndIf;
		
	QueryText =
	"SELECT DISTINCT
	|	Table.Period                  AS Period,
	|	Table.Organization             AS Organization,
	|	LeasedAsset.FixedAsset AS AccountingObject,
	|	Table.Recorder             AS Document
	|
	|INTO SettlementsOnFinancialInstrumentsByFAUpdate
	|
	|FROM
	|	FinancialInstrumentsARAPUpdate AS Table
	|
	|		INNER JOIN InformationRegister.LeasedAsset AS LeasedAsset
	|		ON LeasedAsset.Contract = Table.Contract
	|WHERE
	|	Table.Contract REFS Catalog.LeaseContract
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TablesData.TempTablesManager;
		
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	TablesData.Insert("SettlementsOnFinancialInstrumentsByFAUpdate", Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndRegion
