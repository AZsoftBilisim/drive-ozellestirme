////////////////////////////////////////////////////////////////////////////////
// Procedures related to the calculation of depreciation of the FA
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
		Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual);
		
	NewRow.MultilingualName = "vi = 'Trích khấu hao tài sản cố định hữu hình';
								|ru = 'Начисление амортизации ОС';
								|en = 'Fixed asset depreciation charge';
								|it = 'Maturazione dell''ammortamento capitale fisso';
								|pl = 'Naliczenie amortyzacji środków trwałych';
								|tr = 'SV amortisman gideri'"; // @NStr-1
	NewRow.PreviousStages_.Add(NonCurrentAssetsLocalization.OperationOfSwitchingToFixedAndIntangibleAssets2_4());
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.UpdatingFARecordsBeforeCalculatingDepreciation);
	
	NewRow.TextExecute = NStr("vi = 'Tính';
								|ru = 'Начислить';
								|en = 'Charge'; fa = 'Charge';
								|it = 'Начислить';
								|pl = 'Charge';
								|tr = 'Tahakkuk et'");
	
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"FixedAssetDepreciationCalculation.DetermineStatusOfOperationClosingMonth");
		
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"FixedAssetDepreciationCalculation.PerformMonthClosingOfOperation");
		
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_ClientProcedure(
		"NonCurrentAssetsClient.ProcessingActionDetailsOfMonthClosingFormAndFADepreciation");
	
EndProcedure

// Determines the status of the operation "Accrual of Amortization".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure DetermineStatusOfOperationClosingMonth(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseNonCurrentAssets2_2")
		And Not GetFunctionalOption("UseNonCurrentAssets2_4") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Kế toán tài sản dài hạn bị vô hiệu hóa.';
				|ru = 'Учет внеоборотных активов отключен.';
				|en = 'Accounting of fixed assets is disabled.'; fa = 'Accounting of fixed assets is disabled.';
				|it = 'La contabilità degli attivi non circolanti è disattivata.';
				|pl = 'Ewidencja aktyw pozaobrotowych jest odłączona.';
				|tr = 'Duran varlıkların muhasebeleştirilmesi devre dışı bırakılmıştır.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If NonCurrentAssets.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation.Name) Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If NonCurrentAssets.VNAManagementIsUsed_2_4(HandlerParameters.CalculationParameters.BeginOfPeriod) Then
		DocumentName = Metadata.Documents.FixedAssetsDepreciationCharge2_4.Name;
	Else
		DocumentName = NonCurrentAssetsLocalization.DocumentNameDepreciationFA();
	EndIf; 
	
	MonthEndTransactionsServer.CheckAvailabilityOfRegulatoryDocumentOfClosingStageOfMonth(HandlerParameters, DocumentName);
	
EndProcedure

// Performs the operation "Accrual of Amortization".
// 
// Parameters:
//  HandlerParameters - Structure - Handler Parameters
Procedure PerformMonthClosingOfOperation(HandlerParameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("MonthEndTransactions.FixedAssetDepreciationAccrual");

	CalculationParameters = HandlerParameters.CalculationParameters;
	
	DataVolume = 0;
	
	Try
		
		InformationRegisters.FixedAssetDepreciationPackages.CreateDepreciationPackages(CalculationParameters.CompanyArray);
		
		CalculationEnd = EndOfMonth(CalculationParameters.Period);
		CalculationStart = InformationRegisters.JobsForCalculatingFixedAssetDepreciation.CalculationStart(CalculationParameters.CompanyArray);
		
		Result = ExecuteOperation(
			CalculationStart, 
			CalculationEnd, 
			CalculationParameters.CompanyArray,
			HandlerParameters.CalculationID);
			
		DataVolume = Result.DataVolume;
		
	Except
		
		ErrorInfo = ErrorInfo();
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
		For Each Organization In CalculationParameters.CompanyArray Do
			
			NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
				Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
				CalculationParameters.Period,
				Organization,
				ErrorText);
		
		EndDo;
		
	EndTry;

	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
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
	ParameterDetails.Description = NStr("vi = 'Số lượng các nhiệm vụ (luồng) tính khấu hao được thực hiện đồng thời';
										|ru = 'Количество одновременно выполняемых заданий (потоков) расчета амортизации';
										|en = 'Number of simultaneous depreciation calculation jobs (threads)'; fa = 'Number of simultaneous depreciation calculation jobs (threads)';
										|it = 'Количество одновременно выполняемых заданий (потоков) расчета амортизации';
										|pl = 'Number of simultaneous depreciation calculation jobs (threads)';
										|tr = 'Eş zamanlı gerçekleştirilen amortisman hesaplama görevlerinin (iş parçacıklarının) sayısı'");
	ParameterDetails.ValueType = New TypeDescription("Number",,, New NumberQualifiers(2, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith = 1;
	ParameterDetails.DefaultValue = 4;
	ParameterDetails.LongDesc =
		NStr("vi = 'Có thể tính khấu hao khi đóng tháng đồng thời bởi nhiều nhiệm vụ (luồng).
              |Khi tăng số nhiệm vụ có thể giảm thời gian tính khấu hao.
              |Nên tùy chỉnh số lượng nhiệm vụ tùy thuộc vào cấu hình server Hệ quản trị CSDL và server 1C:Enterprise.';
              |ru = 'Расчет амортизации в закрытии месяца может выполняться одновременно несколькими заданиями (потоками).
              |Увеличение количества заданий может уменьшить время расчета амортизации.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'Depreciation upon month-end closing can be calculated simultaneously by several jobs (threads).
              |Increasing the number of jobs can reduce the depreciation calculation time.
              |Set the job number depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'Depreciation upon month-end closing can be calculated simultaneously by several jobs (threads).
              |Increasing the number of jobs can reduce the depreciation calculation time.
              |Set the job number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'Расчет амортизации в закрытии месяца может выполняться одновременно несколькими заданиями (потоками).
              |Увеличение количества заданий может уменьшить время расчета амортизации.
              |Количество заданий рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'Depreciation upon month-end closing can be calculated simultaneously by several jobs (threads).
              |Increasing the number of jobs can reduce the depreciation calculation time.
              |Set the job number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'Ay sonu kapanışındaki amortisman hesaplaması eş zamanlı olarak birden fazla görev (iş parçacığı) tarafından gerçekleştirilebilir.
              |Görev sayısının artırılması amortisman hesaplama süresini azaltabilir.
              |Veritabanı yönetim sistemi sunucusunun ve 1C:Enterprise sunucularının konfigürasyonuna bağlı olarak görev sayısının yapılandırılması önerilmektedir.'");
		
	#EndRegion
	
	#Region DataChunkSize
		
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Name = "DataChunkSize";
	ParameterDetails.Description = NStr("vi = 'Số lượng gói được xử lý đồng thời';
										|ru = 'Количество пакетов обрабатываемых одновременно';
										|en = 'Number of packages processed simultaneously'; fa = 'Number of packages processed simultaneously';
										|it = 'Количество пакетов обрабатываемых одновременно';
										|pl = 'Number of packages processed simultaneously';
										|tr = 'Eş zamanlı olarak işlenecek paket sayısı'");
	ParameterDetails.ValueType = New TypeDescription("Number",,, New NumberQualifiers(3, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith = 1;
	ParameterDetails.DefaultValue = 10;
	ParameterDetails.LongDesc =
		NStr("vi = 'Trong một nhiệm vụ, việc tính khấu hao có thể được thực hiện cùng lúc theo nhiều gói.
              |Việc tăng số lượng chứng từ có thể giảm thời gian thực hiện hoạt động, nhưng tăng yêu cầu về bộ nhớ.
              |Nên thiết lập số lượng nhiệm vụ phụ thuộc vào cấu hình server trong hệ quản trị CSDL và server 1C:Enterprise.';
              |ru = 'В одном задании расчет амортизации может выполняться одновременно по нескольким пакетам.
              |Увеличение количества пакетов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |en = 'In one job, depreciation can be calculated simultaneously by several packages.
              |Increasing the number of packages can reduce the operation, execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.'; fa = 'In one job, depreciation can be calculated simultaneously by several packages.
              |Increasing the number of packages can reduce the operation, execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |it = 'В одном задании расчет амортизации может выполняться одновременно по нескольким пакетам.
              |Увеличение количества пакетов может уменьшить время выполнения операции, но увеличить потребление памяти.
              |Количество рекомендуется настраивать в зависимости от конфигурации сервера СУБД и серверов 1С:Предприятие.';
              |pl = 'In one job, depreciation can be calculated simultaneously by several packages.
              |Increasing the number of packages can reduce the operation, execution time but increase memory consumption.
              |Configure the number depending on the DBMS server configuration and 1C:Enterprise servers.';
              |tr = 'Bir görevde, amortisman hesaplaması eş zamanlı olarak birden fazla paket üzerinde gerçekleştirilebilir.
              |Paket sayısının artırılması işlem yürütme süresini azaltabilir, ancak bellek tüketimini artırabilir.
              |Veritabanı yönetim sistemi sunucusunun ve 1C:Enterprise sunucularının konfigürasyonuna bağlı olarak sayısın yapılandırılması önerilmektedir.'");
		
	#EndRegion

	Return ParametersDetails;
	
EndFunction

#EndRegion

#Region PerformingTransaction

// Performs depreciation calculation for the specified period.
//
// Parameters:
//  CalculationStart - Date - The beginning of the period of operation to be performed
//  CalculationEnd - Date - End of the period of operation to be performed
//  CompaniesList - Array of CatalogRef.Companies - List of organizations
//  CalculationID - UUID - calculation ID
// 
// Returns:
//  Structure - the result of the depreciation calculation:
// 		* HasErrors - Boolean - True if errors were registered during execution
// 		* ErrorText - String - error text
// 		* DataVolume - Number - The number of objects for which depreciation is calculated
//
Function ExecuteOperation(CalculationStart, CalculationEnd, CompaniesList, CalculationID) Export

	Result = New Structure;
	Result.Insert("HasErrors", False);
	Result.Insert("ErrorText", "");
	Result.Insert("DataVolume", 0);

	If Not NonCurrentAssets.VNAManagementIsUsed()
		Or Not ValueIsFilled(CalculationStart) 
		Or CalculationStart > CalculationEnd Then
			
		Return Result;
	EndIf; 
	
	CurrentMonthOfSettlement = BegOfMonth(CalculationStart);
	UseNonCurrentAssets2_4 = GetFunctionalOption("UseNonCurrentAssets2_4");
	StartOfDepreciationCalculationOS2_4 = NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24(); 
	
	// @skip-check query-in-loop
	// Verification is disabled because of operation must be performed "monthly"
	While CurrentMonthOfSettlement <= CalculationEnd Do
		
		NumberBeforeSettlement = InformationRegisters.JobsForCalculatingFixedAssetDepreciation.IncreaseTaskNumber();
	
		MonthEndTransactionsServer.ClearCalculationExecutionProblems(
			Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual,
			CompaniesList,
			CurrentMonthOfSettlement);
		
		If UseNonCurrentAssets2_4 And CurrentMonthOfSettlement >= StartOfDepreciationCalculationOS2_4 Then
			
			AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(
				CurrentMonthOfSettlement, CompaniesList);
			
			JobsForCalculating = InformationRegisters.JobsForCalculatingFixedAssetDepreciation.JobsForCalculating(
					CurrentMonthOfSettlement, EndOfMonth(CurrentMonthOfSettlement), NumberBeforeSettlement, AvailableCompanies);
			
			TaskQueue = CreateTaskQueue(
				CurrentMonthOfSettlement, CompaniesList, NumberBeforeSettlement, JobsForCalculating.TempTablesManager, "JobsForCalculating");
		
			ExecutionResult = NonCurrentAssets.ExecuteTaskQueue(TaskQueue, MaximumNumberOfTasks(), CalculationID);
			
			Result.HasErrors = ExecutionResult.HasErrors;
			Result.ErrorText = ExecutionResult.ErrorText;
			Result.DataVolume = Result.DataVolume + ExecutionResult.DataVolume;
			
		Else
			
			FixedAssetDepreciationCalculationLocalization.CreateFADepreciationDocuments(CalculationStart, CompaniesList, Result.HasErrors);
			
			If Not Result.HasErrors Then
				
				InformationRegisters.JobsForCalculatingFixedAssetDepreciation.FixCalculation(
					CurrentMonthOfSettlement, CompaniesList, NumberBeforeSettlement);
				
			EndIf;
			
		EndIf;
		
		If Result.HasErrors 
			And ValueIsFilled(Result.ErrorText) Then
			
			For Each Organization In CompaniesList Do
				
				NonCurrentAssetsInternal.RegisterCalculationExecutionProblem(
					Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual, 
					CurrentMonthOfSettlement,
					Organization,
					Result.ErrorText);
			
			EndDo;
			
		EndIf;
		
		CurrentMonthOfSettlement = EndOfMonth(CurrentMonthOfSettlement) + 1;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Used to calculate the depreciation of the FA in the background.
//
// Parameters:
//  CalculationParameters - See ExecutionParameters
//  FormIdentifier - UUID -
// 
// Returns:
//  See TimeConsumingOperations.ExecuteFunction
// 
Function RunDepreciationCalculationInBackground(CalculationParameters, FormIdentifier) Export

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tính toán khấu hao TSCĐ hữu hình';
														|ru = 'Расчет амортизации ОС';
														|en = 'Fixed asset depreciation calculation'; fa = 'محاسبه استهلاک دارایی ثابت';
														|it = 'Calcolo ammortamento di immobilizzazioni materiali';
														|pl = 'Rozliczenie amortyzacji środków trwałych';
														|tr = 'SV amortismanının hesaplanması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "Documents.FixedAssetsDepreciationCharge2_4.CalculateDepreciation", CalculationParameters);
	
	Return TimeConsumingOperation;

EndFunction

// Generates parameters required for calculating depreciation
// 
// Returns:
//  Structure - contains fields:
//      * Period - Date - The period in which you want to calculate depreciation (required).
//      * CompaniesList - Array of CatalogRef.Companies -
//      * HasErrors - Boolean - Indicates the presence of errors.
//      * ErrorText - String - The text of the exception caused by the error.
//      * ReturnCalculationParameters - Boolean - The truth is, if you want to return the parameters of the depreciation calculation.
//      * AddressOfCalculationParameters - String - the address of the temporary storage.
//      * WriteData - Boolean - Write down the depreciation calculation.
//      * FixCalculation - Boolean - Fix the depreciation calculation.
//      * RegisterErrors - Boolean - True if you need to register errors closing the month.
//      * TempTablesManager - TempTablesManager - temporary table manager.
//      * TablesToUse - String - Tables that are formed during the calculation.
//      * NumberOfProcessedData - Number - The amount of data processed during the calculation is used for measurement.
//      * CalculationParametersRedefined - Boolean - True if the calculation parameters are defined in the calling procedure.
//      * PackageNumber - Number - Package number.
//      * Ref - DocumentRef.FixedAssetsDepreciationCharge2_4, DocumentRef.IntangibleAssetsAmortizationCharge2_4 - link to the document.
//      * EmployeeResponsible	- CatalogRef.Users - Responsible for the document (may not be filled in).
//      * Comment - String - Review of the document.
//      * NumberBeforeSettlement - Number - The task number before the calculation starts.
//      * DepreciationPackages - ValueTable - Contains a list of organizations and package numbers (may not be filled in):
//             ** Organization - CatalogRef.Companies -
//             ** PackageNumber - Number -
//
Function ExecutionParameters() Export

	CalculationParameters = New Structure;
	CalculationParameters.Insert("Period", '000101010000');
	CalculationParameters.Insert("CompaniesList", New Array);
	CalculationParameters.Insert("ReturnCalculationParameters", False);
	CalculationParameters.Insert("AddressOfCalculationParameters", Undefined);
	CalculationParameters.Insert("WriteData", True);
	CalculationParameters.Insert("FixCalculation", False);
	CalculationParameters.Insert("TempTablesManager", Undefined);
	CalculationParameters.Insert("CalculationParametersRedefined", False);
	CalculationParameters.Insert("NumberBeforeSettlement", Undefined);
	CalculationParameters.Insert("RegisterErrors", True);
	
	// Return parameter
	CalculationParameters.Insert("HasErrors", False);
	CalculationParameters.Insert("ErrorText", "");
	CalculationParameters.Insert("TablesToUse", "AccruedDepreciation");
	CalculationParameters.Insert("NumberOfProcessedData", 0);
	
	// The values used in the calculation from the document form.
	CalculationParameters.Insert("PackageNumber", Undefined);
	CalculationParameters.Insert("Ref", Undefined);
	CalculationParameters.Insert("EmployeeResponsible", Undefined);
	CalculationParameters.Insert("Comment", Undefined);
	
	// Describes which packages to use to perform the calculation.
	DepreciationPackages = New ValueTable;
	DepreciationPackages.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DepreciationPackages.Columns.Add("PackageNumber", New TypeDescription("Number", New NumberQualifiers(10,0)));
	CalculationParameters.Insert("DepreciationPackages", DepreciationPackages);
	
	//@skip-check constructor-function-return-section
	Return CalculationParameters;
	
EndFunction

#EndRegion

#Region Other

// determines whether depreciation can accrue from the date of acceptance for accounting by at least one organization.
// 
// Parameters:
//  CompaniesList - Array of CatalogRef.Companies - List of organizations
//  Period - Date - Period.
// 
// Returns:
//  Boolean - true if depreciation can accrue from the date of acceptance for accounting..
Function DepreciationMayAccrueFromDateOfAcceptanceForAccounting(CompaniesList, Period) Export
	
	QueryText = FixedAssetDepreciationCalculationLocalization.QueryTextDepreciationMayAccrueFromDateOfAcceptanceForAccounting();
	
	If QueryText = Undefined Then
		QueryText = 
		"SELECT
		|	Companies.ParentCompany AS ParentCompany
		|INTO Companies
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref IN (&CompaniesList)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	1 Priority,
		|	VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting) AS DepreciationProcedure
		|FROM
		|	InformationRegister.FinancialAccountingPolicy.SliceLast(
		|		&Period, 
		|		Organization IN
		|			(SELECT
		|				Companies.ParentCompany
		|			FROM
		|				Companies AS Companies)) AS FinancialAccountingPolicy
		|WHERE
		|	FinancialAccountingPolicy.ProcedureOfFixedAssetDepreciationCharge = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|		OR FinancialAccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|		OR FinancialAccountingPolicy.LeasedAssetDepreciationChargeProcedureManag = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	2 Priority,
		|	VALUE(Enum.DepreciationProcedure.StartingNextMonth) AS DepreciationProcedure
		|FROM
		|	InformationRegister.FinancialAccountingPolicy.SliceLast(
		|		&Period, 
		|		Organization IN
		|			(SELECT
		|				Companies.ParentCompany
		|			FROM
		|				Companies AS Companies)) AS FinancialAccountingPolicy
		|WHERE
		|	FinancialAccountingPolicy.ProcedureOfFixedAssetDepreciationCharge = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
		|		OR FinancialAccountingPolicy.ProcedureOfFixedAssetDepreciationChargeLocal = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
		|		OR FinancialAccountingPolicy.LeasedAssetDepreciationChargeProcedureManag = VALUE(Enum.DepreciationProcedure.StartingNextMonth)
		|
		|ORDER BY
		|	Priority";
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("CompaniesList", CompaniesList);
	Query.SetParameter("Period", Period);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.DepreciationProcedure = Enums.DepreciationProcedure.FromDateOfRecognitionInAccounting;
	Else
		Return True;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region PerformingTransaction

// Calculate depreciation by packages.
// 
// Parameters:
//  ExecutionParameters - See ExecutionParameters
// 
// Returns:
//  Number - Number Of Processed Data
Function CalculateDepreciationByPackages(ExecutionParameters) Export
	
	If ExecutionParameters.DepreciationPackages.Count() = 0 Then
		Return 0;
	EndIf;
	
	CalculationResult2 = Documents.FixedAssetsDepreciationCharge2_4.CalculateDepreciation(ExecutionParameters);
	
	Return CalculationResult2.NumberOfProcessedData;
	
EndFunction

// Sets the request parameters for calculating depreciation.
// 
// Parameters:
//  Query - Query -
//  CalculationParameters - See ExecutionParameters
Procedure SetQueryParametersForCalculatingDepreciation(Query, CalculationParameters = Undefined) Export

	If CalculationParameters <> Undefined Then
		
		Query.SetParameter("BegOfMonth", BegOfMonth(CalculationParameters.Period));
		Query.SetParameter("EndOfMonth",  EndOfMonth(CalculationParameters.Period));
		Query.SetParameter("BegOfYear", BegOfYear(CalculationParameters.Period));
		Query.SetParameter("BeginningOfPreviousMonth", BegOfMonth(BegOfMonth(CalculationParameters.Period)-1));
		Query.SetParameter("BeginningOfNextMonth", BegOfMonth(EndOfMonth(CalculationParameters.Period)+1));
		Query.SetParameter("EndOfPreviousMonth", EndOfMonth(BegOfMonth(CalculationParameters.Period)-1));
		Query.SetParameter("EndOfPreviousMonthBorder", New Boundary(EndOfMonth(BegOfMonth(CalculationParameters.Period)-1), BoundaryType.Including));
		Query.SetParameter("BeginningOfMonthBeforeLast", BegOfMonth(AddMonth(CalculationParameters.Period, -2)));
		Query.SetParameter("EndOfMonthBeforeLast", EndOfMonth(AddMonth(CalculationParameters.Period, -2)));
		
		If CalculationParameters.Property("DepreciationPackages") Then
			Query.SetParameter("DepreciationPackages", CalculationParameters.DepreciationPackages);
		EndIf;

	EndIf;
	
	Query.SetParameter("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	Query.SetParameter("MinimumResidualValueOfRegl", NonCurrentAssetsInternal.MinimumResidualValueOfRegl());
	Query.SetParameter("MinimumResidualValueOfUpr", NonCurrentAssetsInternal.MinimumResidualValueOfUpr());
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("UseFixedAssetImpairment", GetFunctionalOption("UseFixedAssetImpairment"));
	Query.SetParameter("ThisIsInternationalVersion", Not GetFunctionalOption("LocalizationRFService"));
	
	Query.SetParameter(
		"AddImpairmentAdjustment", 
		Enums.PostingOptionsForImpairedFADepreciation.AddImpairmentAdjustment);
	
	Query.SetParameter(
		"ReverseImpairmentAdjustment", 
		Enums.PostingOptionsForImpairedFADepreciation.ReverseImpairmentAdjustment);
	
	DocumentTypes = New Array;
	DocumentTypes.Add(Type("DocumentRef.FixedAssetsInitialRecognition2_4"));
	DocumentTypes.Add(Type("DocumentRef.RecognizeSubAssetsComponentsOfDepreciation"));
	Query.SetParameter("TypeAcceptanceForAccounting", DocumentTypes);

	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.FixedAssetsInitialRecognition2_4"));
	TypesArray.Add(Type("DocumentRef.RecognizeSubAssetsComponentsOfDepreciation"));
	TypesArray.Add(Type("DocumentRef.FixedAssetsCostAdditions2_4"));
	TypesArray.Add(Type("DocumentRef.AllocateVariancesToFixedAssetCost"));
	Query.SetParameter("TypeOfDocumentsForAdditionalCharges", TypesArray);

	TypicalDepreciationMethods = New Array;
	TypicalDepreciationMethods.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.Linear);
	TypicalDepreciationMethods.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.ReducedBalance);
	TypicalDepreciationMethods.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.BySumOfUsefulLifeYearNumbers);
	TypicalDepreciationMethods.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction);
	TypicalDepreciationMethods.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRates);
	TypicalDepreciationMethods.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage);
	Query.SetParameter("TypicalDepreciationMethods", TypicalDepreciationMethods);
	
	Query.SetParameter("EmptyWaysToReflectDepreciation", NonCurrentAssets.EmptyWaysToReflectDepreciation());
	DocumentTypes = New Array;
	DocumentTypes.Add(Type("DocumentRef.VendorInvoiceLeasedAssets"));
	DocumentTypes.Add(Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4"));
	DocumentTypes.Add(Type("DocumentRef.MergeOfFixedAssets"));
	DocumentTypes.Add(Type("DocumentRef.ProvideAssetsToLeasee2_4"));
	DocumentTypes.Add(Type("DocumentRef.FATransfer2_4"));
	DocumentTypes.Add(Type("DocumentRef.PreparingForFixedAssetSale2_4"));
	DocumentTypes.Add(Type("DocumentRef.LeaseTermination"));
	DocumentTypes.Add(Type("DocumentRef.SplitFixedAssets"));
	DocumentTypes.Add(Type("DocumentRef.DisposeFixedAssets2_4"));
	Query.SetParameter("TypesOfDocumentsCountedAfterAdditionalCharges", DocumentTypes);

	FixedAssetDepreciationCalculationLocalization.AddRequestParametersForCalculatingDepreciation(Query, CalculationParameters);
	
EndProcedure

Function CreateTaskQueue(Period, CompaniesList, NumberBeforeSettlement, TempTablesManager, ObjectsTableName)

	TaskQueue = NonCurrentAssets.InitiateTaskQueue();
	
	NumberOfPackagesPerJob = NumberOfPackagesPerJob();
	
	QueryText =
	"SELECT DISTINCT
	|	JobsForCalculating.Organization AS Organization,
	|	JobsForCalculating.PackageNumber AS PackageNumber
	|FROM
	|	JobsForCalculating AS JobsForCalculating
	|
	|ORDER BY
	|	Organization,
	|	PackageNumber";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		TaskData_ = Undefined;
		
		If NumberOfPackagesPerJob > 1 Then
			For Each ExistingJobData In TaskQueue Do
				If ExistingJobData.JobParameters.DepreciationPackages.Count() < NumberOfPackagesPerJob
					And ExistingJobData.JobParameters.CompaniesList.Find(Selection.Organization) <> Undefined Then
					TaskData_ = ExistingJobData;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If TaskData_ = Undefined Then
			
			TaskData_ = TaskQueue.Add();
			TaskData_.CalculationProcedure_ = "FixedAssetDepreciationCalculation.CalculateDepreciationByPackages";
			
			ExecutionParameters = ExecutionParameters();
			ExecutionParameters.Period = BegOfMonth(Period);
			ExecutionParameters.CompaniesList = New Array;
			ExecutionParameters.NumberBeforeSettlement = NumberBeforeSettlement;
			ExecutionParameters.FixCalculation = True;
			
			TaskData_.JobParameters = ExecutionParameters;
			
		EndIf;
		
		If TaskData_.JobParameters.CompaniesList.Find(Selection.Organization) = Undefined Then
			TaskData_.JobParameters.CompaniesList.Add(Selection.Organization);
		EndIf;
		
		PackageParameters = TaskData_.JobParameters.DepreciationPackages.Add();
		PackageParameters.Organization = Selection.Organization;
		PackageParameters.PackageNumber = Selection.PackageNumber;
		
	EndDo;
	
	For Each TaskData_ In TaskQueue Do

		If NumberOfPackagesPerJob = 1 Then
			
			TaskData_.BackgroundJobDescription = 
				StrTemplate(NStr("vi = 'Tính khấu hao TSCĐ hữu hình (doanh nghiệp ""%1"", gói %2)';
								|ru = 'Расчет амортизации ОС (организация ""%1"", пакет %2)';
								|en = 'Fixed asset depreciation calculation (the ""%1"" company, the %2 package)'; fa = 'Fixed asset depreciation calculation (the ""%1"" company, the %2 package)';
								|it = 'Расчет амортизации ОС (организация ""%1"", пакет %2)';
								|pl = 'Fixed asset depreciation calculation (the ""%1"" company, the %2 package)';
								|tr = 'Sabit kıymet amortismanının hesaplanması (iş yeri ""%1"", paket %2)'"), 
						TaskData_.JobParameters.DepreciationPackages[0].Organization, 
						Format(TaskData_.JobParameters.DepreciationPackages[0].PackageNumber, "ND=4; NLZ=; NG=;"));
				
		Else
			 
			TaskData_.BackgroundJobDescription = 
				StrTemplate(NStr("vi = 'Tính khấu hao TSCĐ hữu hình (doanh nghiệp ""%1"", gói %2-%3)';
								|ru = 'Расчет амортизации ОС (организация ""%1"", пакеты %2-%3)';
								|en = 'Fixed asset depreciation calculation (the ""%1"" company, the %2-%3 packages)'; fa = 'Fixed asset depreciation calculation (the ""%1"" company, the %2-%3 packages)';
								|it = 'Расчет амортизации ОС (организация ""%1"", пакеты %2-%3)';
								|pl = 'Fixed asset depreciation calculation (the ""%1"" company, the %2-%3 packages)';
								|tr = 'Sabit kıymet amortismanının hesaplanması (iş yeri ""%1"", paketler %2-%3)'"),
					TaskData_.JobParameters.DepreciationPackages[0].Organization,  
					Format(TaskData_.JobParameters.DepreciationPackages[0].PackageNumber, "ND=4; NLZ=; NG=;"), 
					Format(TaskData_.JobParameters.DepreciationPackages[TaskData_.JobParameters.DepreciationPackages.Count() -1].PackageNumber, "ND=4; NLZ=; NG=;"));
				 
		EndIf;
	
	EndDo;
	
	Return TaskQueue;
	
EndFunction

#EndRegion

#Region Other

// 
// Parameters:
// 	Document - DocumentObject -
// 	TablesData - See DocumentsPosting.OldStructureTableData
Procedure GenerateJobs(Document, TablesData) Export
	
	TablesList = New Array;
	TablesList.Add("LeasedAsset");
	TablesList.Add("FALocation");
	TablesList.Add("AssetActivityRecords");
	TablesList.Add("OSBUDepreciationParameters");
	TablesList.Add("FixedAssetDepreciationParametersManagementAccounting");
	TablesList.Add("InitialFixedAssetsInformation");
	TablesList.Add("FixedAssetsAccountingProcedure");
	TablesList.Add("AccountingProcedureForOSBU");
	TablesList.Add("FixedAssetsAccountingProcedureManagementAccounting");
	TablesList.Add("FACost");
	
	ListOfAddFields = "FixedAsset";
	FADataPoolingText = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TablesData, ListOfAddFields);
	
	TablesList = New Array;
	TablesList.Add("FARevaluation2_4");
	ListOfAddFields = New Structure;
	ListOfAddFields.Insert("FixedAsset", "NonCurrentAsset");
	TextOfDataAssociationIn = NonCurrentAssets.GenerateTextForCombiningDataToFormTask(TablesList, TablesData, ListOfAddFields);
	
	DataTexts = New Array;
	If FADataPoolingText <> "" Then
		DataTexts.Add(FADataPoolingText);
	EndIf; 
	If TextOfDataAssociationIn <> "" Then
		DataTexts.Add(TextOfDataAssociationIn);
	EndIf; 
	DataJoinText = StrConcat(DataTexts, TMCommonUse.QuerySeparatorInJoin());
	
	// When recording these documents, you should always create a task.
	// For example, due to the fact that the document data can be used to calculate depreciation.
	RegisterDocument = 
		Document <> Undefined
		And (TypeOf(Document.Ref) = Type("DocumentRef.FixedAssetsInitialRecognition2_4")
			Or TypeOf(Document.Ref) = Type("DocumentRef.FixedAssetsCostAdditions2_4")
			Or TypeOf(Document.Ref) = Type("DocumentRef.AllocateVariancesToFixedAssetCost")
			Or TypeOf(Document.Ref) = Type("DocumentRef.FixedAssetCostAndDepreciationAdjustment"));
		
	If DataJoinText = "" And Not RegisterDocument Then
		Return;
	EndIf;
		
	If RegisterDocument Then
		
		ListOfMergeRequests = New Array;
		
		If DataJoinText <> "" Then
			ListOfMergeRequests.Add(DataJoinText);
		EndIf; 
			
		QueryText =
		"SELECT
		|	ChangedData.Date AS Period,
		|	ChangedData.Organization AS Organization,
		|	ChangedData.Ref AS Document,
		|	"""" AS TableName,
		|	ChangedData.FixedAsset AS FixedAsset
		|FROM
		|	InformationRegister.FixedAssetsDocuments AS ChangedData
		|WHERE
		|	ChangedData.Ref = &Ref";
		
		ListOfMergeRequests.Add(QueryText);
		
		DataJoinText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf; 
		
	QueryText = NonCurrentAssetsLocalization.RequestTextForGeneratingTasksForCalculatingFADepreciation(
						TablesData, DataJoinText);
	
	If QueryText = Undefined Then
		
		ListOfRequests = New Array;
		
		#Region ChangedData
		QueryText =
		"SELECT
		|	ChangedData.TableName                      AS TableName,
		|	ChangedData.Organization                     AS Organization,
		|	CAST(ChangedData.Organization AS Catalog.Companies).ParentCompany AS ParentCompany,
		|	ChangedData.FixedAsset                AS FixedAsset,
		|	ChangedData.Document                        AS Document,
		|
		|	MIN(CASE
		|				WHEN VALUETYPE(ChangedData.Document) = TYPE(Document.FixedAssetsDepreciationCharge2_4)
		|					THEN DATEADD(ChangedData.Period, MONTH, 1)
		|				ELSE ChangedData.Period
		|			END) AS Period
		|
		|INTO AllChangedData
		|
		|FROM
		|	DataUnionText_Redefined AS ChangedData
		|
		|GROUP BY
		|	ChangedData.TableName,
		|	ChangedData.Organization,
		|	CAST(ChangedData.Organization AS Catalog.Companies).ParentCompany,
		|	ChangedData.FixedAsset,
		|	ChangedData.Document
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllChangedData.Organization                   AS Organization,
		|	AllChangedData.FixedAsset              AS FixedAsset,
		|	AllChangedData.Document                      AS Document,
		|
		|	MIN(CASE 
		|				WHEN VALUETYPE(AllChangedData.Document) = TYPE(Document.EntryOfCapitalAssetsBalance2_4)
		|						OR &RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA
		|						OR &RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA
		|						OR &RegisteredRecordsAreRecordedWhenFormationOfRegisteredRecordsIsDelayed
		|
		|					THEN DATEADD(BEGINOFPERIOD(AllChangedData.Period, MONTH), MONTH, 1) 
		|
		|				ELSE BEGINOFPERIOD(AllChangedData.Period, MONTH)
		| 
		|			END) AS ACPeriod,
		|
		|	MIN(CASE 
		|				WHEN VALUETYPE(AllChangedData.Document) = TYPE(Document.EntryOfCapitalAssetsBalance2_4)
		|						OR &RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA
		|						OR &RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA
		|						OR &RegisteredRecordsAreRecordedWhenFormationOfRegisteredRecordsIsDelayed
		|
		|					THEN DATEADD(BEGINOFPERIOD(AllChangedData.Period, MONTH), MONTH, 1) 
		|
		|				ELSE BEGINOFPERIOD(AllChangedData.Period, MONTH)
		| 
		|			END) AS MAPEriOd
		|
		|INTO ChangedData
		|
		|FROM
		|	AllChangedData AS AllChangedData
		|
		|GROUP BY
		|	AllChangedData.Organization,
		|	AllChangedData.FixedAsset,
		|	AllChangedData.Document
		|
		|INDEX BY
		|	Organization,
		|	FixedAsset";
		
		QueryText = StrReplace(QueryText, "DataUnionText_Redefined", "(" + DataJoinText + ")");
		ListOfRequests.Add(QueryText);
		#EndRegion
		
		#Region JobGeneration
		QueryText =
		"SELECT
		|	ChangedData.Organization,
		|	ChangedData.Document,
		|	ISNULL(FixedAssetDepreciationPackages.PackageNumber, 0) AS PackageNumber,
		|	MIN(CASE 
		|				WHEN ChangedData.ACPeriod <= ChangedData.MAPEriOd
		|						OR ChangedData.MAPEriOd IS NULL
		|					THEN ChangedData.ACPeriod
		|				ELSE ChangedData.MAPEriOd
		|			END) AS Month
		|FROM
		|	ChangedData AS ChangedData
		|
		|		LEFT JOIN InformationRegister.FixedAssetDepreciationPackages AS FixedAssetDepreciationPackages
		|		ON (FixedAssetDepreciationPackages.Organization = ChangedData.Organization)
		|			AND (FixedAssetDepreciationPackages.FixedAsset = ChangedData.FixedAsset)
		|
		|GROUP BY
		|	ChangedData.Organization,
		|	ChangedData.Document,
		|	ISNULL(FixedAssetDepreciationPackages.PackageNumber, 0)";
		
		ListOfRequests.Add(QueryText);
		
		#EndRegion
		
		QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	EndIf; 
	
	TemporaryTablesUsed = TMCommonUse.ListOfTemporaryTables(TablesData.TempTablesManager);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TablesData.TempTablesManager;
	Query.SetParameter("AccountingStartDate24", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	Query.SetParameter("Ref", Document.Ref);
	
	Query.SetParameter(
		"RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA", 
		FACostCalculation.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document));
	
	Query.SetParameter(
		"RegisteredRecordsAreRecordedWhenFormationOfRegisteredRecordsIsDelayed", 
		DeferredFARecordGeneration.RegisteredRecordsAreRecordedWhenOperationIsPerformed(Document));
	
	Query.SetParameter(
		"RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA", 
		FACostCalculation.RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA(Document));
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	TMCommonUse.DestroyTemporaryTables(TablesData.TempTablesManager,, TemporaryTablesUsed);
	
	InformationRegisters.JobsForCalculatingFixedAssetDepreciation.CreateRegisterEntriesBasedOnSampleData(QueryResult.Select());
	
	SetPrivilegedMode(False);
	
EndProcedure

Function MaximumNumberOfTasks()

	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual);
							
	Return ParameterValues.MaximumNumberOfTasks;

EndFunction

Function NumberOfPackagesPerJob()

	ParameterValues = Constants.MonthEndClosingSettings.CreateValueManager().SetValuesOfOperationParameters(
  							Catalogs.MonthEndClosingOperations.FixedAssetDepreciationAccrual);
							
	Return ParameterValues.DataChunkSize;

EndFunction

#EndRegion

#EndRegion
