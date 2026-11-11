#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region DistributionToFinancialResult
// Distributes expenses for the financial result.
// Parameters:
//	HandlerParameters - Structure -
//	DocumentDistributions - DocumentRef.AllocationOfOtherCosts - selection by document to generate a report.
// Returns:
//	Array of CatalogRef.Companies, Undefined - organizations for which the distribution was performed.
Function AllocateExpensesToFinancialResult(HandlerParameters, DocumentDistributions = Undefined) Export
	
	Period = HandlerParameters.CalculationParameters.RegistrationPeriod;
	Companies = HandlerParameters.CalculationParameters.CompanyArray;
	
	TimeConsumingOperation = "Document.AllocationOfOtherCosts.ManagerModule.AllocateExpensesToFinancialResult";
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(TimeConsumingOperation);
	
	StructureOfRequestParameters = InitializeParametersOfDistributionOfExpensesForFinancial(Period, Companies, DocumentDistributions);
	TemporaryTable = TemporaryTablesOfDistributionOfExpensesForProfitabilityAndCosts(StructureOfRequestParameters);
	
	NumberOfFederalLaws = CalculationOfCostCached.ValuesOfTechnologicalParameters(Catalogs.MonthEndClosingOperations.EmptyRef()).MaximumNumberOfFederalLawsForFormationOfDocuments;
	NumberOfFederalLaws = ?(NumberOfFederalLaws < 2 Or ValueIsFilled(DocumentDistributions), 1, NumberOfFederalLaws);
	ProcessedItemsTotal = CostCalculationAppliedAlgorithms.TemporaryTableSize(TemporaryTable, "AllocationResult");
	
	If NumberOfFederalLaws = 1 Then
		
		CalculatedOrganizations = DistributeNextPortionOfExpensesForFinancialResult(HandlerParameters, TemporaryTable, Period);
		
	Else
		
		//Multithreaded distribution
		Query = New Query;
		Query.TempTablesManager = TemporaryTable;
		
		Query.Text =
		"SELECT DISTINCT
		|	T.Recorder
		|FROM
		|	AllocationResult AS T
		|";
		
		ResultLoggers = Query.Execute().Unload().UnloadColumn("Recorder");
		
		RowsCount = ResultLoggers.Count();
		LinesOfVFZ = Int(RowsCount / ?(NumberOfFederalLaws = 0, 1, NumberOfFederalLaws));
		
		If LinesOfVFZ < 1 Then
			
			// Single-threaded distribution
			CalculatedOrganizations = DistributeNextPortionOfExpensesForFinancialResult(HandlerParameters, TemporaryTable, Period);
			
		Else

			//Multithreaded distribution
			HadErrors 			= False;
			ProcessedRows_     = 0;
			ArrayOfTasks       = New Array;
			ArrayOfLoggers = New Array;
			
			While ProcessedRows_ <= RowsCount Do
				
				If ProcessedRows_ = 0 Or ProcessedRows_ = RowsCount
				 // The task is started when the result table is filled with the number of registrars equal to the number of columns.
				 // All the remaining registrars are placed in the last task, even if there are more of them than the row of the register.
				 Or (Int(ProcessedRows_/LinesOfVFZ) = ProcessedRows_/LinesOfVFZ And ArrayOfTasks.Count() < NumberOfFederalLaws-1) Then
					
					If ProcessedRows_ > 0 Then
						
						// We are launching a new Federal law
						Query.SetParameter("ArrayOfLoggers", ArrayOfLoggers);
						
						Query.Text =
						"SELECT
						|	*
						|FROM
						|	AllocationResult AS T
						|WHERE
						|	T.Recorder IN (&ArrayOfLoggers)
						|";
						
						ResultTable2 = New ValueStorage(
							Query.Execute().Unload(),
							New Deflation(9));
						
						Query.Text =
						"SELECT
						|	T.Recorder
						|FROM
						|	DocumentsWithNewRegisteredRecords AS T
						|WHERE
						|	T.Recorder IN (&ArrayOfLoggers)
						|";
						
						DocumentsWithNewRegisteredRecords = New ValueStorage(
							Query.Execute().Unload(),
							New Deflation(9));
						
						ParametersArray = New Array;                                                                      
						ParametersArray.Add(HandlerParameters);
						ParametersArray.Add(ResultTable2);
						ParametersArray.Add(DocumentsWithNewRegisteredRecords);
						
						JobKey = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Nhiệm vụ nền số %1 - %2 (%3)';
								|ru = 'ФЗ №%1 - %2 (%3)';
								|en = 'FZ No.%1 - %2 (%3)'; fa = 'FZ No.%1 - %2 (%3)';
								|it = 'ФЗ №%1 - %2 (%3)';
								|pl = 'UF nr%1 - %2 (%3)';
								|tr = 'FZ №%1 - %2 (%3)'", Common.DefaultLanguageCode()),
							TrimAll(ArrayOfTasks.Count() + 1),
							TrimAll(HandlerParameters.Data_Stage.Code),
							TrimAll(HandlerParameters.CalculationID));
						
						Job = MonthEndTransactionsServer.StartSubordinateBackgroundTaskOfCalculationStage(
							HandlerParameters.CalculationID,
							"AllocationOfOtherCostsLocalization.ExpenseAllocationToFinancialResult",
							ParametersArray,
							JobKey,
							NStr("vi = 'Tạo hàng loạt chứng từ';
								|ru = 'Пакетное формирование документов';
								|en = 'Package document generation'; fa = 'Package document generation';
								|it = 'Пакетное формирование документов';
								|pl = 'Tworzenie pakietów dokumentów';
								|tr = 'Toplu belge oluşturma'"));
							
				        ArrayOfTasks.Add(Job);
						
					EndIf;
					
					If ProcessedRows_ = RowsCount Then
						// All tasks are running
						Break;
					EndIf;
					
					ArrayOfLoggers = New Array;
					
				EndIf;
				
				ArrayOfLoggers.Add(ResultLoggers[ProcessedRows_]);
				
				ProcessedRows_ = ProcessedRows_ + 1;
				
			EndDo;
			
			TasksAreCompleted = False;;
			
			While Not TasksAreCompleted Do
				
				Tasks_Completed = BackgroundJobs.WaitForExecutionCompletion(ArrayOfTasks);
				
				ArrayOfTasks = New Array;
				
				For Each Job In Tasks_Completed Do
					
					If Job.State = BackgroundJobState.Active Then
						
						ArrayOfTasks.Add(Job);
						
					ElsIf Job.State <> BackgroundJobState.Completed Then

						HadErrors = True;
						ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Nhiệm vụ nền tạo chứng từ %1
							|%2';
							|ru = 'Фоновое задание формирования документов %1
							|%2';
							|en = 'Background job of creating documents: %1
							|%2'; fa = 'Background job of creating documents: %1
							|%2';
							|it = 'Фоновое задание формирования документов %1
							|%2';
							|pl = 'Background job of creating documents: %1
							|%2';
							|tr = 'Arka plan belgesi oluşturma işi %1
							|%2'", Common.DefaultLanguageCode()),
							?(Job.State = BackgroundJobState.Canceled,
								NStr("vi = 'đã hủy';
									|ru = 'отменено';
									|en = 'canceled'; fa = 'canceled';
									|it = 'отменено';
									|pl = 'anulowano';
									|tr = 'iptal edildi'", Common.DefaultLanguageCode()),
								NStr("vi = 'kết thúc bất thường';
									|ru = 'завершено аварийно';
									|en = 'aborted'; fa = 'aborted';
									|it = 'завершено аварийно';
									|pl = 'zakończone awaryjnie';
									|tr = 'arızalı tamamlandı'", Common.DefaultLanguageCode())),
							?(Job.ErrorInfo = Undefined,
								NStr("vi = '<Không có mô tả lỗi>';
									|ru = '<Нет описания ошибки>';
									|en = '<No error description>'; fa = '<No error description>';
									|it = '<Нет описания ошибки>';
									|pl = '<Brak opisu błędu>';
									|tr = '<Hata ayrıntıları mevcut değil>'", Common.DefaultLanguageCode()),
								DetailErrorDescription(Job.ErrorInfo)));
								
						MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
							HandlerParameters,
							ErrorText);
						
					EndIf;
					
				EndDo;
				
				TasksAreCompleted = (ArrayOfTasks.Count() = 0);
				
			EndDo;
			
			If HadErrors Then
				
				CalculatedOrganizations = New Array;
				
			Else
				
				Query.Text =
				"SELECT DISTINCT
				|	T.Organization
				|FROM
				|	AllocationResult AS T
				|";
				
				CalculatedOrganizations = Query.Execute().Unload();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProcessedItemsTotal);
	
	DeleteRegisteredRecordsOfAllocatedExpensesInOldDocument(StructureOfRequestParameters, TemporaryTable);
	
	Return CalculatedOrganizations;
	
EndFunction

// Distributes expenses for the financial result.
// 
// Parameters:
//  HandlerParameters - Structure -
//  TemporaryTable - TempTablesManager -
//  Period - Date -
// 
// Returns:
//  Array of CatalogRef.Companies - processed organizations
Function DistributeNextPortionOfExpensesForFinancialResult(HandlerParameters, TemporaryTable, Period) Export
	
	SetPrivilegedMode(True);
	
	CalculatedOrganizations = New Array;
	
	Result = SamplingOfDistributionOfExpensesForProfitabilityAndCosts(TemporaryTable);
	SelectionByOrganization_ = Result[Result.Count() - 1].Select(QueryResultIteration.ByGroups);
	MovementSamplingOtherAssetsLiabilities = Result[Result.Count() - 2].Select();
	SamplingOfRegisteredRecordsOtherExpensesUnfinishedProduction = Result[Result.Count() - 3].Select(QueryResultIteration.ByGroups);
	SamplingAndOtherExpenses = Result[Result.Count() - 4].Select(QueryResultIteration.ByGroups);
	UseBalanceSheetStatement = GetFunctionalOption("UseBalanceSheetStatement");
	DocumentsToBeReflected = New ValueTable();
	DocumentsToBeReflected.Columns.Add("Document", New TypeDescription("DocumentRef.AllocationOfOtherCosts"));
	DocumentsToBeReflected.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DocumentsToBeReflected.Columns.Add("Period", New TypeDescription("Date"));
	DocumentsToBeReflected.Columns.Add("DateRecord", New TypeDescription("Date"));
	IDOfUnusedFinRecord = DocumentsPosting.IDOfUnusedFinRecord();
	While SelectionByOrganization_.Next() Do
		
		HadErrors = False;
		
		SelectingRegistrars = SelectionByOrganization_.Select(QueryResultIteration.ByGroups);
		
		While SelectingRegistrars.Next() Do 
			
			FinancialResults = AccumulationRegisters.FinancialResults.CreateRecordSet();
			FinancialResults.Filter.Recorder.Set(SelectingRegistrars.Recorder);
			
			OtherExpenses = AccumulationRegisters.OtherExpenses.CreateRecordSet();
			OtherExpenses.Filter.Recorder.Set(SelectingRegistrars.Recorder);
			OtherExpensesOfUnfinishedProduction = AccumulationRegisters.OtherWorkInProgressExpenses.CreateRecordSet();
			OtherExpensesOfUnfinishedProduction.Filter.Recorder.Set(SelectingRegistrars.Recorder);
			OtherAssetsLiabilities_ = AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet();
			OtherAssetsLiabilities_.Filter.Recorder.Set(SelectingRegistrars.Recorder);
			
			RecordsIncomeExpensesOtherAssetsLiabilities = AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities.CreateRecordSet();
			RecordsIncomeExpensesOtherAssetsLiabilities.Filter.Recorder.Set(SelectingRegistrars.Recorder);
			
			OtherAssetsAndLiabilitiesRecords = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
			OtherAssetsAndLiabilitiesRecords.Filter.Recorder.Set(SelectingRegistrars.Recorder);
			
			DetailedSampling = SelectingRegistrars.Select();
			While DetailedSampling.Next() Do
				
				If DetailedSampling.CurrentPeriodExpenses Then
					FinRecordID = IDOfUnusedFinRecord;
				Else
					FinRecordID = String(New UUID());
				EndIf;
				
				If Not (DetailedSampling.Sum = 0
					And DetailedSampling.AmountExcludingVAT = 0
					And DetailedSampling.SumMan = 0
					And DetailedSampling.SumCompl = 0
					And DetailedSampling.PermanentDifference = 0
					And DetailedSampling.CostTD = 0) Then
					
					NewRecord = OtherExpenses.Add();
					FillPropertyValues(NewRecord, DetailedSampling);
					NewRecord.CorLineOfBusiness = DetailedSampling.FieldOfActivityReceiver;
					NewRecord.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.AllocationOfExpensesByLinesOfBusiness;
					NewRecord.FinRecordID = FinRecordID;
					NewRecord.CalculationOfCost = True;
					
				EndIf;
				
				If Not DetailedSampling.Sum = 0 Then
					
					NewRecord = OtherAssetsLiabilities_.Add();
					FillPropertyValues(NewRecord, DetailedSampling, "Period, Recorder, Organization, Department, LineOfBusiness, Sum");
					NewRecord.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss;
					NewRecord.Dimension = Undefined;
					NewRecord.CalculationOfCost = True;
					
				EndIf;
				
				If Not (DetailedSampling.Sum = 0
					And DetailedSampling.AmountExcludingVAT = 0
					And DetailedSampling.SumMan = 0
					And DetailedSampling.SumCompl = 0) Then
					
					NewRecord = RecordsIncomeExpensesOtherAssetsLiabilities.Add();
					FillPropertyValues(NewRecord, DetailedSampling, 
						"Period, Recorder, Organization, Department, LineOfBusiness, 
						|DimensionOfExpenses, BusinessOperation, Sum, SumMan, SumCompl");
					NewRecord.AssetRef = DetailedSampling.ExpenseItem;
					NewRecord.CorItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss;
					NewRecord.CorLineOfBusiness = DetailedSampling.FieldOfActivityReceiver;
					
				EndIf;
				
				If Not DetailedSampling.Expenses = 0 
					Or DetailedSampling.CurrentPeriodExpenses Then
					
					NewRecord = FinancialResults.Add();
					FillPropertyValues(NewRecord, DetailedSampling);
					NewRecord.LineOfBusiness = DetailedSampling.FieldOfActivityReceiver;
					NewRecord.CalculationOfCost = True;
					
				EndIf;
				
				If Not (DetailedSampling.Sum = 0
					And DetailedSampling.SumMan = 0
					And DetailedSampling.SumCompl = 0
					And DetailedSampling.PermanentDifference = 0
					And DetailedSampling.CostTD = 0) Then
					
					NewRecord = OtherAssetsAndLiabilitiesRecords.Add();
					FillPropertyValues(NewRecord, DetailedSampling);
					If DetailedSampling.RecordType = AccumulationRecordType.Expense Then
						NewRecord.DebitCredit = Enums.RecordKindsOfOtherAssetsAndLiabilities.Debit;
					Else
						NewRecord.DebitCredit = Enums.RecordKindsOfOtherAssetsAndLiabilities.Credit;
					EndIf;
					NewRecord.LineOfBusiness = DetailedSampling.FieldOfActivityReceiver;
					NewRecord.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss;
					NewRecord.Dimension = Undefined;
					NewRecord.AmountIncludingVAT = DetailedSampling.Sum;
					NewRecord.BusinessTransactionSetting = Catalogs.BusinessTransactionsSettings.AllocationOfExpensesByLinesOfBusiness;
					NewRecord.FinRecordID = FinRecordID;
					NewRecord.CalculationOfCost = True;
					
				EndIf;
				
			EndDo;
			SamplingAndOtherExpenses.Reset();
			MotionSearchKey = New Structure("Recorder", SelectingRegistrars.Recorder);
			While SamplingAndOtherExpenses.FindNext(MotionSearchKey) Do
				
				SelectionDetailRecords = SamplingAndOtherExpenses.Select();
				While SelectionDetailRecords.Next() Do
					FillPropertyValues(OtherExpenses.Add(), SelectionDetailRecords);
				EndDo;
				
			EndDo;
			
			SamplingOfRegisteredRecordsOtherExpensesUnfinishedProduction.Reset();
			MotionSearchKey = New Structure("Recorder", SelectingRegistrars.Recorder);
			While SamplingOfRegisteredRecordsOtherExpensesUnfinishedProduction.FindNext(MotionSearchKey) Do
				
				SelectionDetailRecords = SamplingOfRegisteredRecordsOtherExpensesUnfinishedProduction.Select();
				While SelectionDetailRecords.Next() Do
					FillPropertyValues(OtherExpensesOfUnfinishedProduction.Add(), SelectionDetailRecords);
				EndDo;
				
			EndDo;
	
			MovementSamplingOtherAssetsLiabilities.Reset();
			MotionSearchKey = New Structure("Recorder", SelectingRegistrars.Recorder);
			While MovementSamplingOtherAssetsLiabilities.FindNext(MotionSearchKey) Do
				FillPropertyValues(OtherAssetsLiabilities_.Add(), MovementSamplingOtherAssetsLiabilities);
			EndDo;
			BeginTransaction();
			Try
			
				If UseBalanceSheetStatement Then
					BalanceManRegisteredRecords = New Structure;
					BalanceManRegisteredRecords.Insert("OtherExpenses", OtherExpenses.Unload());
					BalanceManRegisteredRecords.Insert("OtherWorkInProgressExpenses", OtherExpensesOfUnfinishedProduction.Unload());
					BalanceManRegisteredRecords.Insert("OtherAssetsLiabilities", OtherAssetsLiabilities_.Unload());
					
					ManagementAccountingPostingServer.UpdateRegisteredRecordsOfAssetsLiabilities(SelectingRegistrars.Recorder, BalanceManRegisteredRecords);
					
					OtherAssetsLiabilities_.Load(BalanceManRegisteredRecords.OtherAssetsLiabilities);
				EndIf;
				
				FinancialResults.Write();
				OtherExpenses.Write();
				OtherAssetsLiabilities_.Write();
				RecordsIncomeExpensesOtherAssetsLiabilities.Write();
				OtherAssetsAndLiabilitiesRecords.Write();
				AllocationOfOtherCostsLocalization.RegisterDocumentReflection(
					SelectingRegistrars.Recorder);
				ForRecord = DocumentsToBeReflected.Add();
				ForRecord.Document = SelectingRegistrars.Recorder;
				ForRecord.Organization = SelectingRegistrars.Organization;
				ForRecord.Period = Period;
				ForRecord.DateRecord = EndOfMonth(Period);
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				HadErrors = True;

				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể xử lý chứng từ ""%1"" do lỗi:
						|%2';
						|ru = 'Не удалось обработать документ ""%1"" из-за ошибки:
						|%2';
						|en = 'Cannot process the ""%1"" document due to an error:
						|%2'; fa = 'Cannot process the ""%1"" document due to an error:
						|%2';
						|it = 'Не удалось обработать документ ""%1"" из-за ошибки:
						|%2';
						|pl = 'Cannot process the ""%1"" document due to an error:
						|%2';
						|tr = 'Hata nedeniyle ''%1'' belgesi işlenemedi:
						|%2'", Common.DefaultLanguageCode()),
					SelectingRegistrars.Recorder,
					DetailErrorDescription(ErrorInfo()));
				
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText,
					SelectingRegistrars.Organization,
					,
					,
					SelectingRegistrars.Recorder);
					
			EndTry;
			
		EndDo;
		
		If Not HadErrors Then
			CalculatedOrganizations.Add(SelectionByOrganization_.Organization);
		EndIf;
		
	EndDo;
	FinancialAccountingPostingServer.ReturnDocumentsToReflection(DocumentsToBeReflected);
	DataProcessors.MonthEndClosingOperations.RegisterStageCalculationProblems(HandlerParameters);
	
	Return CalculatedOrganizations;
	
EndFunction

	
// Adds service tables to the temporary table Manager that are necessary for calculating
// the direct production cost base.
// Parameters:
//	CalculationParameters - See CostCalculationAppliedAlgorithms.InitializeGeneralCalculationParameters
//	Query - Query - previously initialized request.
Procedure PrepareTablesForCalculation(CalculationParameters, Query = Undefined) Export
	
	If Query = Undefined Then
		
		Query = New Query;
		CostCalculationAppliedAlgorithms.InitializeRequestProperties(
			Query,
			CalculationParameters);
			
	EndIf;
	
	If TypeOf(CalculationParameters) = Type("Structure") And CalculationParameters.Property("Recorder") Then
		
		Query.SetParameter("Recorder", CalculationParameters.Recorder);
		Query.SetParameter("AccordingToAllDocuments", CalculationParameters.Recorder = Undefined);
		
	Else
		
		Query.SetParameter("Recorder", Undefined);
		Query.SetParameter("AccordingToAllDocuments", True);
		
	EndIf;
	
	Query.Text = 
		"SELECT
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS Date,
		|	Attributes.AssignAllocationSetting,
		|	Attributes.AllocationDirection,
		|	CASE
		|		WHEN Attributes.AllocationDirection = VALUE(Enum.AllocationDirectionByBusinessUnits.ByRates)
		|			THEN VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
		|		ELSE	
		|			Attributes.BaseOfAllocationByLots
		|	END AS BaseOfAllocationByLots,
		|	Attributes.ToAnyLinesOfBusiness,
		|	Attributes.BaseOfAllocationByBusinessUnits,
		|	Attributes.Factor,
		|	Attributes.ProductCostElement,
		|	Attributes.AllocateByLots,
		|	Attributes.AllocateToBusinessUnits,
		|	Attributes.AllocateToExpenseItems,
		|	Attributes.LeaveAsWIP,
		|	Attributes.ForReleaseOfCurrentMonth,
		|	Attributes.LotsAreSpecifiedManually,
		|	Attributes.BusinessUnitsAreSpecifiedManually,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|	ISNULL(TTOvz.ThisIsOVZ,FALSE) AS ThisIsOVZ,
		|	Attributes.Organization AS Organization,
		|	Attributes.Department AS Department,
		|	Attributes.ExpenseItem AS ExpenseItem,
		|	Attributes.DimensionOfExpenses AS DimensionOfExpenses,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	(NOT Attributes.AllocationDirection = VALUE(Enum.AllocationDirectionByBusinessUnits.CurrentBusinessUnit)) AS DistributionRequired,
		|	Attributes.ManagementAccounting AS ManagementAccounting,
		|	Attributes.LocalAccounting AS LocalAccounting,
		|	Attributes.TaxAccounting AS TaxAccounting, 
		|	Attributes.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.WithoutExpenseAllocation) AS CurrentPeriodExpenses,
		|	CASE // The data source is relevant only for NaFinRez distribution settings
		|		WHEN Attributes.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
		|		THEN Attributes.DataSource
		|		ELSE VALUE(Enum.DataSourcesForExpenseAllocation.EmptyRef)
		|	END AS DataSource
		|INTO Recorders
		|FROM
		|	Document.AllocationOfOtherCosts AS Attributes
		|	LEFT JOIN TTOvz AS TTOvz
		|		ON Attributes.DimensionOfExpenses = TTOvz.ConstCenter
		|			AND Attributes.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|WHERE
		|	Attributes.Posted
		|	AND (
		|		Attributes.AssignAllocationSetting IN (
		|			VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult),
		|			VALUE(Enum.AssignmentOfCostAllocationRules.WithoutExpenseAllocation))
		|		OR (
		|			Attributes.AssignAllocationSetting IN (
		|				VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost), 
		|				VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|				) 
		|			AND Attributes.TaxAccounting
		|			AND Attributes.ExpenseItem.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|		)
		|	)
		|	AND Attributes.Organization IN (&CompanyArray)
		|	AND Attributes.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (Attributes.Ref = &Recorder
		|		OR &AccordingToAllDocuments)
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	LineOfBusiness,
		|	Department,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VALUE(Document.AllocationOfOtherCosts.EmptyRef) AS Recorder,
		|	VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef) AS BaseOfAllocationByBusinessUnits,
		|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS Factor,
		|	FALSE AS BusinessUnitsAreSpecifiedManually
		|INTO DistributeByDivisions
		|;
		|
		|SELECT
		|	T.Recorder
		|INTO DistributeByStages
		|FROM
		|	Recorders AS T
		|WHERE
		|	T.DistributionRequired
		|	AND NOT T.BaseOfAllocationByLots IN (
		|		VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef),
		|		VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity),
		|		VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue),
		|		VALUE(Enum.TypesOfCostAllocatingBase.GrossProfit),
		|		VALUE(Enum.TypesOfCostAllocatingBase.SaleCost))
		|";
	
	Query.Execute();
	
EndProcedure

// Initializes the parameters of the request for allocation of expenses for the financial result.
// Parameters:
// 	Period - Date - the period of allocation of costs.
//	Companies - Array of CatalogRef.Companies - list of organizations to distribute to.
//	DocumentDistributions - DocumentRef.AllocationOfOtherCosts - selection by document to generate a report.
// Returns:
//	Structure:
//		* Period - Date - data generation period;
//		* BeginOfPeriod - Date - the beginning of the month of the data generation period;
//		* EndOfPeriod - Date - end of the month of the data generation period;
//		* CompanyArray - Array of CatalogRef.Companies - array of organizations (reference link.Organizations);
//		* DocumentDistributions - DocumentRef.AllocationOfOtherCosts,Undefined - selection by document to generate a report.
Function InitializeParametersOfDistributionOfExpensesForFinancial(Period, Companies, DocumentDistributions = Undefined) Export
	
	StructureOfRequestParameters = New Structure;
	StructureOfRequestParameters.Insert("Period", Period);
	StructureOfRequestParameters.Insert("BeginOfPeriod", BegOfMonth(Period));
	StructureOfRequestParameters.Insert("EndOfPeriod", EndOfMonth(Period));
	StructureOfRequestParameters.Insert("CompanyArray", Companies);
	StructureOfRequestParameters.Insert("DocumentDistributions", DocumentDistributions);
	
	Return StructureOfRequestParameters;
	
EndFunction

// Generates temp tables for allocating expenses to the financial result.
// Parameters:
//	Parameters - Structure - See InitializeParametersOfDistributionOfExpensesForFinancial()
// Returns:
//	TempTablesManager - temp tables for the formation of a sample according to which further
//		allocation of expenses will be made.
Function TemporaryTablesOfDistributionOfExpensesForProfitabilityAndCosts(Parameters) Export
	
	CalculationParameters = Undefined;
	CalculationParameters = CostCalculationItemizedCosts.PrepareCostBase(Parameters);
	TemporaryTable = ?(CalculationParameters = Undefined, New TempTablesManager, CalculationParameters.TempTablesManager);
	
	AddDefaultParametersToDistributionOfExpensesForProfitabilityAndCost(Parameters);
	
	Query = CostCalculationAppliedAlgorithms.InitializeRequestBasedOnParameters(Parameters, TemporaryTable);
	
	PrepareServiceTables(Parameters.Period, Parameters.CompanyArray, Query);
	
	SourceDebuggingMode = CalculationOfCostCached.ValuesOfTechnologicalParameters().GenerateTTSourcesOfExpenses;
	
	Query.Text = QueryTextOfTemporaryDistributionTablesForProfitabilityAndCosts(SourceDebuggingMode);
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

// Returns the Query Text to get temp tables for distribution to the financial result.
// Parameters:
// SourceDebuggingMode - Boolean - indicates that the request will be analyzed in debug mode. If the parameter
//		is set to "True", all nested tables will be displayed separately in temp tables (which can
//		be viewed separately), and all subqueries of the join will contain the "Source" field with a brief description
//		of the Cur sample.
// Returns:
//	String - The Query Text for getting temp tables.
Function QueryTextOfTemporaryDistributionTablesForProfitabilityAndCosts(SourceDebuggingMode = False) Export
	
	TemporaryTableQueries = New Array;
	
	TemporaryTableQueries.Add(TextPreliminaryBalancesOfExpenses());
	TemporaryTableQueries.Add(TextExpenseBalances(SourceDebuggingMode));

	
	TemporaryTableQueries.Add(TextExpensesForDistribution(SourceDebuggingMode));
	TemporaryTableQueries.Add(TTTextCurrentAreasOfActivity());
	TemporaryTableQueries.Add(TextProfitabilityAndCosts());
	TemporaryTableQueries.Add(TextRevenueAndCostOfGoodsSold());
	TemporaryTableQueries.Add(TextDistributionBase());
	TemporaryTableQueries.Add(TextOfDistributionBaseIsSummarized());
	TemporaryTableQueries.Add(TextDistributedExpenses());
	TemporaryTableQueries.Add(TextDistributionDocuments());
	TemporaryTableQueries.Add(TextMaximumCoefficientsForRecorders());
	TemporaryTableQueries.Add(TextOfDirectionOfActivityForError());
	TemporaryTableQueries.Add(TextOfRoundingError());
	TemporaryTableQueries.Add(TextRecordersToCleanUpRegisterRecords(SourceDebuggingMode));
	TemporaryTableQueries.Add(TextDistributedCostAnalytics());
	TemporaryTableQueries.Add(TextDocumentsWithNewRegisteredRecords());
	TemporaryTableQueries.Add(TextDocumentsToBeReflected());
	TemporaryTableQueries.Add(TextDistributionResult(SourceDebuggingMode));
	
	QueryText = StrConcat(TemporaryTableQueries, Common.QueryBatchSeparator());
	
	If SourceDebuggingMode Then
		QueryText = StrReplace(QueryText, "//DebugMode", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the Query Text for a selection of data to be distributed to the financial result.
// Returns:
//	String - The text of the data selection request.
Function QueryTextOfDistributionSelectionForProfitabilityAndCost() Export
	
	SampleRequests = New Array;
	
	SampleRequests.Add(TextSelectionOtherExpenses());
	SampleRequests.Add(TextSelectionOtherExpensesUnfinishedProduction());
	SampleRequests.Add(TextSelectionOtherAssetsLiabilities());
	
	SampleRequests.Add(TextSelectionDistributionResult());
	
	Return StrConcat(SampleRequests, Common.QueryBatchSeparator());
	
EndFunction

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	
	AllocationOfOtherCostsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AllocationOfOtherCosts") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		AllocationOfOtherCostsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region Description_ArticlesForDistribution

// Filling in the data of the cost allocation workplace:
// The main function that starts getting the list: See ArticlesForDistribution.
// The output data is generated in the TT state of the spending allocation. See QueryTextDataForDistribution.
// 
// The order of execution:
// 1. Data preparation:
// 1.1 Request initialization: See InitializeRequestToGetDataForDistribution.
// 
// 1.2. Formation of service tables: See PrepareServiceTables.
//	- Additional transportation expenses - see Tax accounting.dolyattransportspendingcurrent months
//	It will be empty if you exclude transport costs = True (the last parameter of the procedure).
//	
//	- In the list of public spending - see Tax accounting.Create a temporary table with a list of available expenses.
//	The share of write-off of indirect expenses in the context of expenditure items.
//	
//	- VtOVZ - See CostCalculationItemizedCosts.TextInTPOOvz
//	A table with HIA settings (options and distribution rules).
//	
//	- The values of the indicator S - See CostCalculationItemizedCosts.TextValuesOfDistributionIndicatorsForHIA.
//	On the database of the RS Register of entries.The values of indicators for the distribution of HIA expenditures and distribution rules collect distribution indicators for HIA.
//	
//	- Registrars - See PrepareTablesForCalculation
//	Completed documents of the distribution of other costs with selections according to the distribution settings.
//	
//	- Distribute to divisions - See PrepareTablesForCalculation.
//	At this stage an empty table.
//	
//	- Distribute by stages - See PrepareTablesForCalculation
//	Sampling of registrars from TT Registrars with selection by BazaRasdistributiOnParties.
//	
//	
// 2. Formation of the text of the request for expenses for distribution: See QueryTextDataForDistribution.
//	
// 2.1 First, the text of the request for received expenses is generated: See QueryTextReceivedOtherExpenses.
//	Selection tables are generated:
//	- The article of expenditure by distribution (by type of accounting and general).
// A list of items of expenditure for which the distribution option in one of the types of accounting is included in the Cost distribution options.
// 
//	- HIA distribution (by type of accounting and general).
// A list of HIA whose distribution option in one of the types of accounting is included in the & Spending distribution options.
// 
//	
// 2.2 The text of the request is generated based on the sources of received expenses
//	The source data is divided into areas:
//	- Text description of data
//	
//	- Textual statistics of other expenses (Man, Local, TA)
//	The Balance of the PH is other waste.
//	
//	- The text of the movement of other expenses (Man, Local, TA)
//	of movement along the PH other expenses.
//	
//	- The text of the movement of the party and other expenses (Men's Upr, Local, TA)
//	Incoming movements on the RN pariand other expenses according to the documents accrualreversivnogonds.
//	
//	- The text of the movement of other spending in a single texture (Man, Local, TA)
//	Incoming movements of the secondary circuit according to the PH of the other expenses.
//	
//	- The text of the movement on the cost of production (Man, Local, TA)
//	Expenditure movements according to PH Other expenditures according to production documents.
//	
//	- The text of the descriptiondistributionetmc
//	Movements on the PH Cost of goods for the write-off of Inventory in production.
//	
//	- The text of the descriptiondistribution to other organizations
//	Movements according to the PH Cost of goods for the write-off of Inventory in production with the completed Organization field.
//	
//	- textdistributionmaterialsworks
//	Movements on the PH of materials and production according to the documents of the distribution of production costs.
//	
//	- Textual statistics of other expenses (Man, Local, TA, NDD)
//	The Balance of the PH of other expenses with the selection of HIA.
//	
//	- The text of the movement of other expenses (Man, Local, TA, NDT)
//	Expenditure movements on PH Other expenses with selection on HIA.
//	
//	- The text of the descriptiondistributionmtsnaovz
//	Movements according to the PH Cost of goods for the write-off of Inventory in production with selection for HIA.
//	
//	- textdistributionmaterialswork
//	Movements on PH materials and production work according to the documents of the distribution of production costs with selection by HIA.
//	
//	- The text of the movement of other expenditures between each expenditure
//	Expenditure movements according to the PH Other expenditures according to the documents of the distribution of other expenses with selection by HIA and transit expenditure operations between HIA.
//	
//	- The text of other movements of expenditures between each arrival
//	Incoming movements on the RN Other expenses according to the documents of the distribution of other expenses with selection by HIA and operations of transit expenses between HIA.
//	
//	- Texttranslation of expenses between the graph (general, personal data)
//	A sample of TT vttransitrandings between VZ and selection by HIA.
//	
//	The division into types of accounting for Man, Local and TA goes through separate functions: See ReplacementPatternSee ReplaceByPattern. 
//	and
//	
//	
// for NDT they are selected by separate requests.
//	2.3 According to the sources, tables of distribution expenses and distribution expenses are generated by water.
//	
// According to the data of the distribution expenses, the distribution settings for the personal income tax are formed.
//	- 2.4 Further formation of tables:
//	- Adjustment Distribution rules
//	
//	- Rules for the distribution of other expenses by analysts.
//	- Manual water distribution rules
//	
//	- Distribution rules with manual input.
//	- The article of expenditure without the article of articulation
//	
//	- Items of expenditure that do not have calculation items and a distribution option for non-production costs or the cost of production in one of the types of accounting.
//	- Movements of expenditure statistics
//	Table with signs of movements by analysts of other expenses by type of accounting:
//	1) There are movements between the VZ (Man, Local, TA, NDD).
//	2) There is a movement for Financial results (Man, Local, TA, NDD).
//	3) There is a movement for production (Man, Local, TA, NDD).
//	4) There are movements in other states (Man, Local, TA, NDD).
//	
//	- 5) There is a description (only TA).
//	- Distribution documents
//	
//	- The conducted documents of the distribution of the total costs in the selected period.
//	- Rationing of accounting accounts
//	
// Movements along the PH are other expenses for the operation of distributionenormalizable expenses. See RequestTextExpensesAfterDistributionSources.
//	- 2.5 Data on unallocated expenses is collected by calling a separate function:
//	- Up-to-date statistics of the end-of-month expenses
//	The Balance of the PH other expenses according to analysts from the TT expenses are distributed by water.
//	
//	- Flags are a miscalculation error = Lies
//	- Adjustment of the closing period
//	Movements on the PH Other expenses according to analysts from TT expenses are distributed according to the documents of the regulatory operation and write-off operations of the above-mentioned expenses.
//	Of the amounts, only the sum and the constant difference are filled in.
//	
//	- Flags are a miscalculation error = Lies
//	- Correctioncan fixableeostatkinzp
//	A sample of TT expenses is distributed in a water manner with selection based on the availability of distribution documents
//	
//	- Flags are a miscalculation error = True when there is a distribution document
//	- Correctioncanormalization of expenses
//	Selection from TT expenses by distribution with selection by analysts (expense item, organization) from vtdolisisioncompensated expenses 
//	Flags are a miscalculation error = False when the amount or percentage of the write-off = 0 or when there are no matching analysts for the TT of the movement of the expenditure stat.
//	
//	- There is a miscalculation error = The truth is when there are matching analysts on the TT movement of the spending stat.
//	- Up-to-date statistics for the end of the monthreferences
//	The Balance of the PH other expenses according to analysts from the TT expenses are distributed water-wise. Spending analytics = HIA. The expenditure article is empty.
//	
// Flags are a miscalculation error = Lies
//	- 2.6 Further formation of tables:
//	- Consumption after distribution
//	Data on unallocated expenses from the previous item, supplemented with the Distributed flag.. by type of accounting.
//	
//	- Distributed.. = True when the variant distribution is included in the list, there is no error and the sum = 0 and when the sum is within &error values are correct.
//	- Tasks
//	
//	- Tasks from the RS taskscountainability. For organizations, the minimum month is selected in which there are tasks to be calculated.
//	- Unallocated expenses for your own cost of goods
//	Sampling from the consumption distribution is carried out according to the variant of distribution of the highest cost of goods.
//	
//	The Unallocated flag is set.. by type of accounting, if by type of accounting option = Nasebostost of goods.
//	2.7 Formation of the VTDANNYDISTRIBUTION table
//	The main table with data on the distribution of expenses. 
//	States are filled in by type of accounting.
//	
//	It is divided into 2 parts in the association - the main and the HIA.
//	- The principle of determining the State of cost allocation for the 1st part of the request is as follows:
//	- Not required if the distribution option is not included in the Cost & Distribution options.
//	- It is not required if the analytics falls into the TT of the non-distributable costs of your high-value goods.
//	
//	- Most likely, incorrect cost analytics or expenses relate to future periods.
//	- It is not required if the expense item is filled in and the distribution option is for HIA.
//	
//	- Articles with a distribution option ""On HIA"" are processed in summary, the document is not required.
//	- There are no expenses available if the month is closed, there are no Balances and no movements.
//	- Distributed if the month is closed and there are no expenses. 
//	- A manual document is required, if the distribution of shares is not configured, there is a Balance for distribution and a rule with manual filling,
//	
//	- then manual configuration is required. State - Requires a hand-written document.
//	- Unallocated if the distribution of shares is not configured, but the month is closed.
//	- It is required to form a document if the distribution of shares is not configured, and there is a Balance to the distribution.
//	- Distribution error, if there is a distribution of shares, the distribution document has made movements to production, but there is a Balance to the distribution, that is, an error.
//	- Distribution error, if there is a distribution between HIA, the distribution document has made movements, but there is a Balance to the distribution.
//	- Distribution error, if there is a distribution of shares, the distribution document has made movements on the fin. res., but there is a Balance to the distribution.
//	- Distributed, if there is a distribution of shares, the distribution document has made movements and the article is fully distributed.
//	- Not required if the month is not closed, there is no Balance for distribution and the amount is not calculated.
//	
//	- Cooking distribution at the base if none of the conditions are met.
//	- For the second part (HIA), the principle is as follows:
//	- Not required if the distribution option is not included in the Cost & Distribution options. 
//		- Non-available expenses if the month is closed and the distribution option is in the list: 
//		Unproductive costs, 
//		Our 
//		cost of production, our direction of activity,
//	- On the object of importation of new costs.
//	- A manual document is required, if the distribution document has not been created, the HIA distribution option = Non-production costs and the rule is selected according to the type of accounting.
//	- It is required to form a document if the distribution document has not been created and the previous condition has not been fulfilled.
//	
// - Cooking distribution at the base if none of the conditions are met.
//	2.8 Formation of the state table of spending allocation.
//	- Sampling data from the data distribution with additional selections:
//	- the rows are eliminated, in which the State is not required in all types of accounting.
// - for all types of accounting, a filter & State filter is applied to the State and an additional check of the occurrence of the distribution option in &cost distribution options.
//	

#EndRegion 

// Returns a list of articles to distribute to.
//
// Parameters:
//		Period - Date - Sampling period.
//		Companies - Array - List of organizations for which articles are analyzed.
//		Departments - Array - The list of divisions for which articles are analyzed.
//		State - EnumRef.CostAllocationStates - filter by State.
//
//	Returns:
//		ValueTable - Table of articles to be distributed.
//
Function ArticlesForDistribution(Period, Companies, Departments, State, AllocationOption = Undefined) Export
	
	QueryOptions = DescriptionOfParametersForRequestingDataForDistribution();
	QueryOptions.Period = Period;
	QueryOptions.Companies = Companies;
	QueryOptions.Departments = Departments;
	QueryOptions.State = State;
	QueryOptions.AllocationOption = AllocationOption;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	InitializeRequestToGetDataForDistribution(Query, QueryOptions);
	
	Query.Text = QueryTextDataForDistribution();
	
	SetPrivilegedMode(True);
	
	Result = Query.Execute();
	
	Return Result.Unload();
	
EndFunction

// Retrieves and places a table of expense items for setting up distribution in temporary storage.
// Parameters:
//	Parameters - Structure - parameters for receiving items of expenditure:
//		* Period - Date - month of distribution.
//		* Companies - CatalogRef.Companies - organization of expenses.
//		* Departments - Array of CatalogRef.BusinessStructure - expense divisions.
//		* State - EnumRef.CostAllocationStates - the State of the flow distribution.
//	StorageAddress - String - the address in the temporary storage where the work result should be placed.
//
Procedure ArticlesToBeDistributedInBackground(Parameters, StorageAddress) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.AllocationOfOtherCosts.ManagerModule.ArticlesToBeDistributedInBackground");
	
	Departments = New Array;
	If ValueIsFilled(Parameters.Department) Then
		Departments.Add(Parameters.Department);
	EndIf;
	
	Companies = New Array;
	If ValueIsFilled(Parameters.Organization) Then
		Companies.Add(Parameters.Organization);
	EndIf;
	
	ARTICLES__ = ArticlesForDistribution(Parameters.Period, Companies, 
		Departments, Parameters.State);
		
	PutToTempStorage(ARTICLES__, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ARTICLES__.Count() / 100);
	
EndProcedure

// Generates the document "Distribution of other costs" according to the specified conditions.
// Parameters:
//	FillParameters - Structure - Parameters for filling in the document.
// Returns:
//	Structure - Contains information about the document and the State of the distribution:
//		* UPRStatus - EnumRef.CostAllocationStates - the State of expense distribution in management accounting.
//		* ReglStatus - EnumRef.CostAllocationStates - the State of the distribution of expenses in regulated accounting.
//		* DocumentMan - DocumentRef.AllocationOfOtherCosts - created a distribution document for management accounting.
//		* DocumentCompl - DocumentRef.AllocationOfOtherCosts - created a distribution document for regulated accounting.
//		* ManErrorDescription - String - the text of the error resulting from the creation of a document for management accounting.
//		* LocalErrorDescription - String - the text of the error that occurred as a result of creating a document for regulated accounting.
//
Function GenerateDocument(FillParameters) Export
	
	CheckBlockingIncomingDataWhenUpdatingInformationSecurity(NStr("vi = 'Phân bổ các chi phí khác';
																	|ru = 'Распределение прочих затрат';
																	|en = 'Allocation of other costs'; fa = 'Allocation of other costs';
																	|it = 'Ripartizione di altre uscite';
																	|pl = 'Przydzielenia innych wydatków';
																	|tr = 'Diğer maliyet dağıtımı'"));
	
	AccountingTypeParameters = New Structure;
	AccountingTypeParameters.Insert("ManagementAccounting", 
		New Structure("State, Document, ErrorDescription", "UPRStatus", "DocumentMan", "ManErrorDescription"));
	AccountingTypeParameters.Insert("LocalAccounting", 
		New Structure("State, Document, ErrorDescription", "ReglStatus", "DocumentCompl", "LocalErrorDescription"));

	If CalculationOfCostLocalization.GetFunctionalOptionAITAccounting() Then
		AccountingTypeParameters.Insert("AIT", 
			New Structure("State, Document, ErrorDescription", "NDDState", "DocumentAIT", "AITErrorDescription"));
	EndIf;
	
	DocumentsForHolding = New Array; // Array of DocumentObject.AllocationOfOtherCosts
	TransferParameters = New Structure;
	
	For Each AccountingKind In AccountingTypeParameters Do
		
		DetailsOfAccountingType = AccountingKind.Value;
		
		If ValueIsFilled(FillParameters[DetailsOfAccountingType.Document])
			Or FillParameters[AccountingTypeParameters[AccountingKind.Key].State] = Enums.CostAllocationStates.RequiresManualDocumentInput
			Or FillParameters[AccountingTypeParameters[AccountingKind.Key].State] = Enums.CostAllocationStates.NotRequired Then
			Continue;
		EndIf;
		
		Doc = FindRightDocument(DocumentsForHolding, AccountingKind.Key, FillParameters);
		
		If Not Doc = Undefined Then
			
			If ValueIsFilled(FillParameters[DetailsOfAccountingType.Document]) 
				And Not FillParameters[DetailsOfAccountingType.Document] = Doc.Ref Then
						
				Try
					
					PreviousDocument = FillParameters[DetailsOfAccountingType.Document].GetObject(); // DocumentObject
					PreviousDocument.Write(DocumentWriteMode.UndoPosting);
					
				Except
					
					WriteLogEvent(Doc.Metadata().Name, 
						EventLogLevel.Error,,,
						DetailErrorDescription(ErrorInfo()));
					
					ErrorTemplate = NStr("vi = 'Không thể cập nhật cài đặt phân bổ cho dạng hạch toán ''''%1'''' do: %2.';
										|ru = 'Не удалось обновить настройки распределения по виду учета ""%1"" по причине: %2.';
										|en = 'Cannot update allocation settings by accounting kind ""%1"". Reason: %2.'; fa = 'Cannot update allocation settings by accounting kind ""%1"". Reason: %2.';
										|it = 'Non è stato possibile aggiornare le impostazioni della ripartizione per tipo di contabilità""%1"" a causa di: %2.';
										|pl = 'Nie można zaktualizować ustawień dystrybucji według typu ewidencji „%1” z powodu: %2.';
										|tr = '""%1"" hesap türüne göre dağıtım ayarlarının güncellenememe nedeni: %2.'", Common.DefaultLanguageCode());
					
					TransferParameters.Insert(DetailsOfAccountingType["State"], 
						Enums.CostAllocationStates.ReadyForAllocation);
					TransferParameters.Insert(DetailsOfAccountingType["Document"], 
						FillParameters[DetailsOfAccountingType.Document]);
					TransferParameters.Insert(DetailsOfAccountingType["ErrorDescription"], 
						StrTemplate(ErrorTemplate, AccountingKind.Key, DetailErrorDescription(ErrorInfo())));
					
					Continue;
					
				EndTry;
				
			EndIf;
			
			Doc[AccountingKind.Key] = True;
			
			Continue;
			
		EndIf;
		
		If Not ValueIsFilled(FillParameters[DetailsOfAccountingType.Document])
			Or (Not Doc = Undefined 
				And Doc.Ref = FillParameters[DetailsOfAccountingType.Document]) Then
			Doc = Documents.AllocationOfOtherCosts.CreateDocument();
		Else
			
			Doc = FillParameters[DetailsOfAccountingType.Document].GetObject();
			Doc.ManagementAccounting = False;
			Doc.LocalAccounting = False;
			Doc.AIT = False;
			
		EndIf;
			
		Doc[AccountingKind.Key] = True;
		
		Doc.Fill(FillParameters);
		
		DocumentsForHolding.Insert(0, Doc);
				
	EndDo;
	
	For Each DocumentForCarryingOut In DocumentsForHolding Do
		
		If DocumentForCarryingOut.CheckFilling() Then
			Try
				DocumentForCarryingOut.Write(DocumentWriteMode.Posting);
			Except
				ErrorInfo = ErrorInfo();
				WriteLogEvent(DocumentForCarryingOut.Metadata().Name, 
					EventLogLevel.Error,,, 
					DetailErrorDescription(ErrorInfo));
				Message = New UserMessage();
				Message.Text = BriefErrorDescription(ErrorInfo);
				Message.SetData(DocumentForCarryingOut);
				Message.Message();
			EndTry;
		EndIf;
		
		ErrorText = "";
		ErrorsTexts = New Array;
		Errors = GetUserMessages(True);
		For IndexOf = 0 To Errors.Count() - 1 Do
			ErrorsTexts.Add(Errors[IndexOf].Text);
		EndDo;
		
		ErrorText = Chars.Tab + StrConcat(ErrorsTexts, Chars.LF + Chars.Tab);
			
		For Each AccountingKind In AccountingTypeParameters Do
			
			If Not DocumentForCarryingOut[AccountingKind.Key] Then
				Continue;
			EndIf;
			
			DetailsOfAccountingType = AccountingKind.Value;
			
			If Not IsBlankString(ErrorText) Then
				
				TransferParameters.Insert(DetailsOfAccountingType["State"], 
					Enums.CostAllocationStates.DocumentGenerationIsRequired);
				TransferParameters.Insert(DetailsOfAccountingType["ErrorDescription"], ErrorText);
				
			Else
				
				TransferParameters.Insert(DetailsOfAccountingType["State"], Enums.CostAllocationStates.ReadyForAllocation);
				TransferParameters.Insert(DetailsOfAccountingType["Document"], DocumentForCarryingOut.Ref);
				
			EndIf;
			
		EndDo;
		
		
	EndDo;
	
	Return TransferParameters;
	
EndFunction

// Returns the text of the request for data on other expenses.
//
// Returns:
//	String - query text.
//
Function QueryTextReceivedOtherExpenses(CalculationOption = "PreliminaryCalculation", InitializationOfHIA = True) Export
	
	TextOfExpenditureItemToBeDistributedByTypeOfAccounting = 
		"SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	Attributes.CostAllocationOptionManag AS CostAllocationOption
		|INTO ItemsOfExpenditureForDistributionOfMan
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionManag IN (&CostAllocationOptions)
		|	AND Attributes.CostAllocationOptionManag <> VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	Attributes.CostAllocationOptionLocal AS CostAllocationOption
		|INTO ExpenditureItemsForLocalDistribution
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|	AND Attributes.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|
		|INDEX BY
		|	Ref
		|
		|;
		|SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	Attributes.CostAllocationOptionTax AS CostAllocationOption
		|INTO ItemsOfExpenditureToBeAllocatedTa
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionTax IN (&CostAllocationOptions)
		|	AND Attributes.CostAllocationOptionTax <> VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|
		|INDEX BY
		|	Ref
		|";
		
		TextOfArticleCOByTypesOfAccounting = 
		"SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	Attributes.CostAllocationOptionManag AS CostAllocationOption
		|INTO ArticlesCOMan
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	Attributes.CostAllocationOptionLocal AS CostAllocationOption
		|INTO ArticlesCOLocal
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|
		|INDEX BY
		|	Ref
		|
		|;
		|SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	Attributes.CostAllocationOptionTax AS CostAllocationOption
		|INTO ArticlesCOTA
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|
		|INDEX BY
		|	Ref
		|";
		
	TextOfExpenditureItemForAITDistribution = CalculationOfCostLocalization.QueryTextOfArticleForAITDistribution();
	
	TextOfExpenditureItemToBeDistributed = 
		"SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOption
		|INTO ItemsOfExpenditureToBeDistributed
		|FROM
		|	ItemsOfExpenditureForDistributionOfMan AS Attributes
		|
		|UNION
		|
		|SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef)
		|FROM
		|	ExpenditureItemsForLocalDistribution AS Attributes
		|
		|UNION
		|
		|SELECT
		|	Attributes.Ref AS Ref,
		|	Attributes.Predefined AS Predefined,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOption
		|FROM
		|	ItemsOfExpenditureToBeAllocatedTa AS Attributes
		|
		|INDEX BY
		|	Ref
		|";
	TextOfCOToDistributionByTypeOfAccounting = "
		|SELECT DISTINCT
		|	Attributes.ConstCenter AS ConstCenter
		|INTO OVZKManDistribution
		|FROM
		|	TTOvz AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionManag IN (&CostAllocationOptions)
		|
		|INDEX BY
		|	ConstCenter
		|;
		|
		|SELECT DISTINCT
		|	Attributes.ConstCenter AS ConstCenter
		|INTO OVZKLocalDistribution
		|FROM
		|	TTOvz AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|
		|INDEX BY
		|	ConstCenter
		|;
		|
		|SELECT DISTINCT
		|	Attributes.ConstCenter AS ConstCenter
		|INTO OVZKDistributionTa
		|FROM
		|	TTOvz AS Attributes
		|WHERE
		|	Attributes.CostAllocationOptionTax IN (&CostAllocationOptions)
 		|
 		|INDEX BY
 		|	ConstCenter
 		|";
 		
 	AITTextOfCostCentersToForDistribution = CalculationOfCostLocalization.AITTextOfCostCentersToForDistribution();
	
 	TextOfCOToDistribution = "
		|SELECT
		|	Attributes.ConstCenter AS ConstCenter
		|INTO OVZKDistribution
		|FROM
		|	OVZKManDistribution AS Attributes
		|UNION
		|SELECT
		|	Attributes.ConstCenter
		|FROM
		|	OVZKLocalDistribution AS Attributes
		|UNION
		|SELECT
		|	Attributes.ConstCenter
		|FROM
		|	OVZKDistributionTa AS Attributes
		|UNION
		|SELECT
		|	Attributes.ConstCenter
		|FROM
		|	CostCentersToAITDistribution AS Attributes
		|	
		|INDEX BY
		|	ConstCenter
		|";
	TextExpensesForDistribution = 
		"////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.SumBalance AS SumBalance,
		|	T.AmountExcludingVATBalance AS AmountExcludingVATBalance,
		|	T.SumManBalance AS SumManBalance,
		|	T.SumComplBalance AS SumComplBalance,
		|	T.PermanentDifferenceBalance AS PermanentDifferenceBalance,
		|	T.CostTDBalance AS CostTDBalance,
		|	T.AITAmountBalance AS AITAmountBalance
		|INTO TTOtherExpenses_Balance
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(
		|			&BorderEndOfPeriod,
		|				(&ByAllCompanies
		|					OR Organization IN (&CompanyArray))
		|					AND (&ByAllBusinessUnits
		|						OR Department IN (&DepartmentList))
		|) AS T
		|
		|INDEX BY
		|	ExpenseItem,
		|	Organization,
		|	Department,
		|	LineOfBusiness,
		|	DimensionOfExpenses
		|;
		|
		|// For debugging purposes, the output of sources of expenses in the original form is provided
		|// The source of the expenses
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Expenses.Organization 					AS Organization,
		|	Expenses.Department 					AS Department,
		|	Expenses.LineOfBusiness 		AS LineOfBusiness,
		|	Expenses.ExpenseItem 					AS ExpenseItem,
		|	Expenses.DimensionOfExpenses 				AS DimensionOfExpenses,
		|	Expenses.DirectionOfActivityForCommunication	AS DirectionOfActivityForCommunication,
		|	Expenses.ItemOfExpenditureForCommunication			AS ItemOfExpenditureForCommunication,
		|	NOT Expenses.ItemOfExpenditureForCommunication = Expenses.ExpenseItem AS ThisIsExpenseOfHIA,
		|	SUM(Expenses.EstimatedQuantity) <> 0 OR
		|		MAX(Expenses.EstimatedAmount)	AS EstimatedAmount,
		|	SUM(Expenses.Sum) 					AS Sum,
		|	SUM(Expenses.AmountExcludingVAT) 				AS AmountExcludingVAT,
		|	SUM(Expenses.SumCompl) 				AS SumCompl,
		|	SUM(Expenses.PermanentDifference) 		AS PermanentDifference,
		|	SUM(Expenses.CostTD) 		AS CostTD,
		|	SUM(Expenses.AITAmount) 				AS AITAmount,
		|	SUM(Expenses.SumMan) 				AS SumMan,
		|	SUM(Expenses.SumComplExpense) 			AS SumComplExpense,
		|	SUM(Expenses.PermanentDifferenceExpense) 	AS PermanentDifferenceExpense,
		|	SUM(Expenses.CostTDExpense) 	AS CostTDExpense,
		|	SUM(Expenses.AITAmountExpense) 			AS AITAmountExpense
		|INTO ExpenseForAllocation
		|FROM
		|	&SourcesOfExpenses AS Expenses
		|
		|GROUP BY
		|	Expenses.Organization,
		|	Expenses.Department,
		|	Expenses.LineOfBusiness,
		|	Expenses.ExpenseItem,
		|	Expenses.DimensionOfExpenses,
		|	Expenses.DirectionOfActivityForCommunication,
		|	Expenses.ItemOfExpenditureForCommunication,
		|	NOT Expenses.ItemOfExpenditureForCommunication = Expenses.ExpenseItem
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	LineOfBusiness,
		|	Organization
		|";
		
	TextOfAITArticleDistributionSettings = CalculationOfCostLocalization.AITSettingsQueryText("ExpenseForAllocation", 
																	"DistributionOfOtherExpenses_QueryTextReceivedOtherExpenses");
	
	TextExpensesForDistributionAreSummarized = 
		"SELECT ALLOWED
		|	Expenses.Organization 					AS Organization,
		|	Expenses.Department 					AS Department,
		|	Expenses.DirectionOfActivityForCommunication	AS LineOfBusiness,
		|	Expenses.ItemOfExpenditureForCommunication			AS ExpenseItem,
		|	Expenses.DimensionOfExpenses 				AS DimensionOfExpenses,
		|	&CostAllocationOptionManag AS CostAllocationOptionManag,
		|	&CostAllocationOptionLocal AS CostAllocationOptionLocal,
		|	&CostAllocationOptionTax AS CostAllocationOptionTax,
		|	&AITCostAllocationOption AS AITCostAllocationOption,
		|	MAX(Expenses.EstimatedAmount)		AS EstimatedAmount,
		|	SUM(Expenses.Sum) 					AS Sum,
		|	SUM(Expenses.AmountExcludingVAT) 				AS AmountExcludingVAT,
		|	SUM(Expenses.SumCompl) 				AS SumCompl,
		|	SUM(Expenses.PermanentDifference) 		AS PermanentDifference,
		|	SUM(Expenses.CostTD) 		AS CostTD,
		|	SUM(Expenses.AITAmount) 				AS AITAmount,
		|	SUM(Expenses.SumMan) 				AS SumMan,
		|	SUM(Expenses.SumComplExpense) 			AS SumComplExpense,
		|	SUM(Expenses.PermanentDifferenceExpense) 	AS PermanentDifferenceExpense,
		|	SUM(Expenses.CostTDExpense) 	AS CostTDExpense,
		|	SUM(Expenses.AITAmountExpense) 			AS AITAmountExpense
		|INTO ExpensesForDistributionAreSummarized
		|FROM
		|	ExpenseForAllocation AS Expenses
		|		LEFT JOIN AITArticleDistributionSettings AS AITSettings
		|			ON Expenses.ExpenseItem = AITSettings.ExpenseItem
		|			AND &Expenses_ObjectOfSeparateAccountingAIT = AITSettings.ObjectOfSeparateAccountingAIT
		|			AND Expenses.Organization = AITSettings.Organization
		|			AND AITSettings.ExpensesAreIncludedInCost
		|		LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS SettingsForDistributionOfAITArticlesByCostCenter
		|			ON Expenses.DimensionOfExpenses = SettingsForDistributionOfAITArticlesByCostCenter.ConstCenter
		|			AND SettingsForDistributionOfAITArticlesByCostCenter.ExpensesAreIncludedInCost
		|
		|GROUP BY
		|	Expenses.Organization,
		|	Expenses.Department,
		|	Expenses.DimensionOfExpenses,
		|	Expenses.DirectionOfActivityForCommunication,
		|	Expenses.ItemOfExpenditureForCommunication,
		|	&CostAllocationOptionManag,
		|	&CostAllocationOptionLocal,
		|	&CostAllocationOptionTax,
		|	&AITCostAllocationOption
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Expenses.Organization 			AS Organization,
		|	Expenses.Department 			AS Department,
		|	Expenses.LineOfBusiness	AS LineOfBusiness,
		|	Expenses.ExpenseItem			AS ExpenseItem,
		|	Expenses.DimensionOfExpenses 		AS DimensionOfExpenses
		|INTO ExpensesForDistributionAreSummarizedArticleIsFilledIn
		|FROM
		|	ExpensesForDistributionAreSummarized AS Expenses
		|WHERE
		|	Expenses.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	LineOfBusiness,
		|	Department, 
		|	Organization
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Expenses.Organization			AS Organization,
		|	Expenses.Department		AS Department,
		|	Expenses.DimensionOfExpenses	AS DimensionOfExpenses
		|INTO ExpensesForDistributionAreSummarizedByHIA
		|FROM
		|	ExpensesForDistributionAreSummarized AS Expenses
		|WHERE
		|	Expenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|	AND VALUETYPE(Expenses.DimensionOfExpenses) = TYPE(Catalog.CostCenters)
		|	AND Expenses.DimensionOfExpenses <> VALUE(Catalog.CostCenters.EmptyRef)
		|
		|INDEX BY
		|	DimensionOfExpenses,
		|	Department, 
		|	Organization
		|;
		|";
		
		QueryTexts = New Array;
		
		QueryTexts.Add(TextOfExpenditureItemToBeDistributedByTypeOfAccounting);
		QueryTexts.Add(TextOfArticleCOByTypesOfAccounting);
		QueryTexts.Add(TextOfExpenditureItemForAITDistribution);
		QueryTexts.Add(TextOfExpenditureItemToBeDistributed);
		QueryTexts.Add(TextOfCOToDistributionByTypeOfAccounting);
		QueryTexts.Add(AITTextOfCostCentersToForDistribution);
		QueryTexts.Add(TextOfCOToDistribution);
		QueryTexts.Add(QueryTextTTOfRegisteredRecordsOfOtherExpensesByItemOfExpenditure());
				
		QueryTexts.Add(TextExpensesForDistribution);
		QueryTexts.Add(TextOfAITArticleDistributionSettings);
		QueryTexts.Add(TextExpensesForDistributionAreSummarized);
		
		QueryText = StrConcat(QueryTexts, TMCommonUse.RequestSeparatorInPacket_());
		
		ManSVersion = "Expenses.ExpenseItem.CostAllocationOptionManag";
		VariantLocal = "Expenses.ExpenseItem.CostAllocationOptionLocal";
		OptionTa = "Expenses.ExpenseItem.CostAllocationOptionTax";
		AITOption = "ISNULL(AITSettings.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef))";
		If GetFunctionalOption("UseAccountingByExpenseObjects") Then
			ManSVersion = "
			|CASE 
			|		WHEN 
			|			Expenses.ItemOfExpenditureForCommunication = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		THEN Expenses.DimensionOfExpenses.CostAllocationOptionManag
			|		ELSE Expenses.ExpenseItem.CostAllocationOptionManag
			|	END";
			
			VariantLocal = "
			|CASE 
			|		WHEN 
			|			Expenses.ItemOfExpenditureForCommunication = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		THEN Expenses.DimensionOfExpenses.CostAllocationOptionLocal
			|		ELSE Expenses.ExpenseItem.CostAllocationOptionLocal
			|	END";
			
			OptionTa = "
			|CASE 
			|		WHEN 
			|			Expenses.ItemOfExpenditureForCommunication = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		THEN Expenses.DimensionOfExpenses.CostAllocationOptionTax
			|		ELSE Expenses.ExpenseItem.CostAllocationOptionTax
			|	END";
			
			AITOption = "
			|	CASE
			|		WHEN
			|			Expenses.ItemOfExpenditureForCommunication = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
			|		THEN ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef))
			|		ELSE ISNULL(AITSettings.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef))
			|	END";
		EndIf;
		QueryText = StrReplace(QueryText, "&CostAllocationOptionManag", ManSVersion);
		QueryText = StrReplace(QueryText, "&CostAllocationOptionLocal", VariantLocal);
		QueryText = StrReplace(QueryText, "&CostAllocationOptionTax", 
			?(GetFunctionalOption("UseLocal"), OptionTa, VariantLocal));
		QueryText = StrReplace(QueryText, "&AITCostAllocationOption", AITOption);
		
		CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(QueryText, "Expenses_ObjectOfSeparateAccountingAIT");
		
		SourceDebuggingMode = CalculationOfCostCached.ValuesOfTechnologicalParameters().GenerateTTSourcesOfExpenses;
		If SourceDebuggingMode Then
			QueryText = StrReplace(QueryText, 
				"// TTSourcesOfExpenditure",
				RequestTextReceivedOtherExpensesSources(CalculationOption)+";"); //@Query-part
			QueryText = StrReplace(QueryText, 
				"&SourcesOfExpenses",
				"TTSourcesOfExpenditure"
				); //@Query-part-1 @Query-part-2
			QueryText = StrReplace(QueryText, 
				"//DebugMode",
				""
				); //@Query-part-1
		Else
			QueryText = StrReplace(QueryText, 
				"&SourcesOfExpenses",
				"("+RequestTextReceivedOtherExpensesSources(CalculationOption)+")"); //@Query-part-1
		EndIf;
		
	Return 
		?(InitializationOfHIA, CostCalculationItemizedCosts.TextInTPOOvz() 
			+ CostCalculationItemizedCosts.TextValuesOfDistributionIndicatorsForHIA(),"") +
		QueryText;
	
EndFunction

// Returns the text of the request for getting data for the cost allocation workplace.
//
// Returns:
//	String - query text.
//
Function QueryTextDataForDistribution(ChooseFirst = 0, CurrentStateOfIWTExpenditure = False, ChallengeForDCS = False) Export
	
	// Distributed documents.
	QueryText = QueryTextReceivedOtherExpenses("Workplace", ChallengeForDCS);
	QueryText = QueryText + "
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT 
		|	ExpenditureData.Organization 				AS Organization,
		|	ExpenditureData.Department 				AS Department,
		|	ExpenditureData.LineOfBusiness	AS LineOfBusiness,
		|	ExpenditureData.ExpenseItem				AS ExpenseItem,
		|	ExpenditureData.DimensionOfExpenses 			AS DimensionOfExpenses,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsLocal, 
		|		ISNULL(OrganizationSettings.SettingsLocal, 
		|			ISNULL(SettingsByDepartment.SettingsLocal, 
		|					ArticleDetails_1.CostAllocationRuleLocal
		|	)))
		|		AS LocalDistributionRule,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsManAccounting, 
		|		ISNULL(OrganizationSettings.SettingsManAccounting,
		|			ISNULL(SettingsByDepartment.SettingsManAccounting, 
		|					ArticleDetails_1.CostAllocationRuleManag
		|	)))
		|		AS ManDistributionRule,
		|	AITSettings.CostAllocationRuleAIT AS RuleOfDistributionOfPersonalIncomeTax
		|INTO RulesForDistributionBySettings
		|FROM
		|	ExpensesForDistributionAreSummarized AS ExpenditureData
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleDetails_1
		|		ON ExpenditureData.ExpenseItem = ArticleDetails_1.Ref
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS OrganizationSettings
		|		ON ExpenditureData.ExpenseItem = OrganizationSettings.ExpenseItem
		|			AND ExpenditureData.Organization = OrganizationSettings.Organization
		|			AND (OrganizationSettings.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByDepartment
		|		ON ExpenditureData.ExpenseItem = SettingsByDepartment.ExpenseItem
		|			AND ExpenditureData.Department = SettingsByDepartment.Department
		|			AND (SettingsByDepartment.Organization = VALUE(Catalog.Companies.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByOrganizationAndDivision
		|		ON ExpenditureData.ExpenseItem = SettingsByOrganizationAndDivision.ExpenseItem
		|			AND ExpenditureData.Organization = SettingsByOrganizationAndDivision.Organization
		|			AND ExpenditureData.Department = SettingsByOrganizationAndDivision.Department
		|		LEFT JOIN AITArticleDistributionSettings AS AITSettings
		|			ON ExpenditureData.ExpenseItem = AITSettings.ExpenseItem
		|			AND &DataOnExpenses_ObjectOfSeparateAccountingAIT = AITSettings.ObjectOfSeparateAccountingAIT
		|			AND ExpenditureData.Organization = AITSettings.Organization
		|			AND AITSettings.ExpensesAreIncludedInCost
		|			
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	LineOfBusiness,
		|	Organization;
		|
		|
		|SELECT 
		|	Rules.Ref AS Rule,
		|	VALUE(Enum.CostAllocationOptions.ToProductionCosts) AS AllocationOption
		|INTO DistributionRulesWithManualEntryOfDivisions
		|FROM Catalog.CostAllocationRules AS Rules
		|	LEFT JOIN Catalog.CostAllocationRules.Departments AS TS
		|	ON TS.Ref = Rules.Ref
		|WHERE 
		|	Rules.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|	AND Rules.BusinessUnitsAreSpecifiedManually
		|	AND NOT Rules.LotsAreSpecifiedInDocument
		|GROUP BY
		|	Rules.Ref
		|HAVING
		|	COUNT(TS.Department) = 0
		|;
		|
		|SELECT 
		|	Rules.Ref AS Rule,
		|	VALUE(Enum.CostAllocationOptions.ToProductionCosts) AS AllocationOption
		|INTO ManualDistributionRules
		|FROM Catalog.CostAllocationRules AS Rules
		|WHERE Rules.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|	AND Rules.LotsAreSpecifiedInDocument
		|UNION ALL
		|SELECT 
		|	Rules.Rule AS Rule,
		|	Rules.AllocationOption AS AllocationOption
		|FROM DistributionRulesWithManualEntryOfDivisions AS Rules
		|UNION ALL
		|SELECT 
		|	Rules.Ref AS Rule,
		|	VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
		|FROM Catalog.CostAllocationRules AS Rules
		|WHERE Rules.AssignRule = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
		|	AND Rules.AllocationDirection = VALUE(Enum.AllocationDirectionByBusinessUnits.ByRates)
		|GROUP BY
		|	Rules.Ref
		|HAVING COUNT(Rules.LinesOfBusiness.LineNumber) = 0
		|UNION ALL
		|SELECT 
		|	VALUE(Catalog.CostAllocationRules.EmptyRef),
		|	VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|WHERE &AccountingByLinesOfBusiness
		|INDEX BY
		|	Rule,
		|	AllocationOption
		|;
		|
		|SELECT DISTINCT
		|	Attributes.Ref AS Ref,
		|	Attributes.CostAllocationOptionManag IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)) AS WithoutManSCalculationArticle,
		|	Attributes.CostAllocationOptionTax IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)) AS WithoutCalculationArticleTA,
		|	Attributes.CostAllocationOptionLocal IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)) AS WithoutLocalCalculationArticle,
		|	ISNULL(AITSettings.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)) AS WithoutAITCalculationArticle
		|INTO ExpenditureItemsWithoutCalculationItems
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|		LEFT JOIN AITArticleDistributionSettings AS AITSettings
		|		ON Attributes.Ref = AITSettings.ExpenseItem
		|		AND AITSettings.ExpensesAreIncludedInCost
		|WHERE
		|	Attributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|	AND (Attributes.CostAllocationOptionManag IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|	OR Attributes.CostAllocationOptionTax IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|	OR Attributes.CostAllocationOptionLocal IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|	OR ISNULL(AITSettings.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|		VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|	)
		|INDEX BY
		|	Ref
		|;
		|
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	DD.Organization			AS Organization,
		|	DD.Department		AS Department,
		|	ISNULL(CostAllocation.LineOfBusiness, DD.LineOfBusiness) AS LineOfBusiness,
		|	ISNULL(CostAllocation.ExpenseItem, DD.ExpenseItem) AS ExpenseItem,
		|	DD.DimensionOfExpenses	AS DimensionOfExpenses,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND (DD.Sum <> 0 OR DD.AmountExcludingVAT <> 0 OR DD.SumMan <> 0))) AS ThereAreRegisteredRecordsBetweenHIAMan,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND DD.SumCompl <> 0)) AS ThereAreRegisteredRecordsBetweenHIAAndLocal,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND (DD.SumCompl - DD.PermanentDifference - DD.CostTD <> 0))) AS ThereAreRegisteredRecordsBetweenHIANal,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND (DD.AITAmount <> 0))) AS ThereAreRegisteredRecordsBetweenCostCenterAIT,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND (DD.Sum <> 0 OR DD.AmountExcludingVAT <> 0 OR DD.SumMan <> 0))) AS ThereAreRegisteredRecordsOnFinancialResultOfMan,
		|	MAX(NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND (DD.Sum <> 0 OR DD.AmountExcludingVAT <> 0 OR DD.SumMan <> 0)) AS ThereAreRegisteredRecordsForProductionOfMan,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND DD.SumCompl <> 0)) AS ThereAreRegisteredRecordsOnFinancialResultOfLocal,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND (DD.SumCompl - DD.PermanentDifference - DD.CostTD <> 0))) AS ThereAreRegisteredRecordsOnFinancialResultOfNal,
		|	MAX((DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND (DD.AITAmount <> 0))) AS ThereIsRegisteredRecordOfProfitabilityAndCostOfAIT,
		|	MAX(NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND DD.SumCompl <> 0) ThereAreRegisteredRecordsOnLocalProduction,
		|	MAX(NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND (DD.SumCompl - DD.PermanentDifference - DD.CostTD <> 0)) ThereAreRegisteredRecordsOnNalProduction,
		|	MAX(NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA)
		|				AND NOT DD.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
		|				AND (DD.AITAmount <> 0)) HasRegisteredRecordForProductionAIT,
		|	MAX(DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND (DD.Sum <> 0 OR DD.AmountExcludingVAT <> 0 OR DD.SumMan <> 0)) ThereAreLinksToOtherManArticles,
		|	MAX(DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND DD.SumCompl <> 0) ThereAreLinksToOtherLocalArticles,
		|	MAX(DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND (DD.SumCompl - DD.PermanentDifference - DD.CostTD <> 0)) ThereAreLinksToOtherNalArticles,
		|	MAX(DD.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
		|				AND (DD.AITAmount <> 0)) ThereIsRegisteredRecordsForOtherArticlesAIT,
		|	MAX(DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA)
		|				AND (DD.PermanentDifference <> 0 OR DD.CostTD <> 0)) AS ThereIsWriteOffTa,
		|	MAX(DD.BusinessOperation = VALUE(Enum.BusinessTransactions.AITAmountWriteOff)
		|				AND DD.AITAmount <> 0) AS ThereIsWriteOffOfAIT
		|INTO RegisteredRecordsOfExpenditureItems
		|FROM
		|	AccumulationRegister.OtherExpenses AS DD
		|		LEFT JOIN Document.AllocationOfOtherCosts AS CostAllocation
		|		ON DD.Recorder = CostAllocation.Ref
		|		LEFT JOIN Document.AllocationOfIncomeByLinesOfBusiness AS IncomeDistribution
		|		ON DD.Recorder = IncomeDistribution.Ref
		|WHERE
		|	DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND (&ByAllCompanies OR DD.Organization IN (&CompanyArray))
		|	AND (&ByAllBusinessUnits OR DD.Department IN (&DepartmentList))
		|	AND DD.Active
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND NOT (CostAllocation.Ref IS NULL
		|		AND IncomeDistribution.Ref IS NULL)
		|
		|GROUP BY
		|	DD.Organization,
		|	DD.Department,
		|	ISNULL(CostAllocation.LineOfBusiness, DD.LineOfBusiness),
		|	ISNULL(CostAllocation.ExpenseItem, DD.ExpenseItem),
		|	DD.DimensionOfExpenses
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Attributes.Ref AS Document,
		|	Attributes.ManagementAccounting,
		|	Attributes.LocalAccounting,
		|	Attributes.TaxAccounting,
		|	Attributes.AIT,
		|	Attributes.LeaveAsWIP,
		|	Attributes.CostShareOfWIP,
		|	Attributes.TotalCostShares,
		|	Attributes.AssignAllocationSetting AS AssignAllocationSetting,
		|	Attributes.Organization AS Organization,
		|	Attributes.Date AS Date,
		|	Attributes.Department AS Department,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	Attributes.ExpenseItem AS ExpenseItem,
		|	Attributes.DimensionOfExpenses AS DimensionOfExpenses
		|INTO DistributionDocuments
		|FROM
		|	Document.AllocationOfOtherCosts AS Attributes
		|WHERE
		|	Attributes.Date BETWEEN &BeginOfPeriod AND ENDOFPERIOD(&EndOfPeriod, MONTH)
		|	AND (&ByAllCompanies OR Attributes.Organization IN (&CompanyArray))
		|	AND (&ByAllBusinessUnits OR Attributes.Department IN (&DepartmentList))
		|	AND Attributes.Posted
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	Organization,
		|	LineOfBusiness
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|INTO RationingOnAccountsAccounts
		|FROM
		|	AccumulationRegister.OtherExpenses AS T
		|WHERE
		|	T.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND T.Active
		|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA)
		|;
		|
		|// TTSourcesOfUnallocatedExpenses
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Unallocated_.Organization AS Organization,
		|	Unallocated_.Department AS Department,
		|	Unallocated_.ExpenseItem AS ExpenseItem,
		|	Unallocated_.DimensionOfExpenses AS DimensionOfExpenses,
		|	Unallocated_.LineOfBusiness AS LineOfBusiness,
		|	SUM(Unallocated_.SumBalance) AS SumBalance,
		|	SUM(Unallocated_.AmountExcludingVATBalance) AS AmountExcludingVATBalance,
		|	SUM(Unallocated_.SumManBalance) AS SumManBalance,
		|	SUM(Unallocated_.SumComplBalance) AS SumComplBalance,
		|	SUM(Unallocated_.AmountFABalance) AS AmountFABalance,
		|	CASE
		|		WHEN NOT Unallocated_.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|				VALUE(Enum.CostAllocationOptions.ToInventoryCost),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness))
		|			THEN TRUE
		|		WHEN NOT MAX(Unallocated_.ThereIsErrorInCalculationOfMa)
		|			THEN (SUM(Unallocated_.SumBalance) = 0
		|					AND SUM(Unallocated_.AmountExcludingVATBalance) = 0
		|					AND SUM(Unallocated_.SumManBalance) = 0)
		|		ELSE (SUM(Unallocated_.SumBalance) BETWEEN -&ManErrorValue AND &ManErrorValue
		|			AND SUM(Unallocated_.AmountExcludingVATBalance) BETWEEN -&ManErrorValue AND &ManErrorValue
		|			AND SUM(Unallocated_.SumManBalance) BETWEEN -&ManErrorValue AND &ManErrorValue)
		|	END AS DistributedByVUU,
		|	CASE
		|		WHEN NOT Unallocated_.CostAllocationOptionLocal IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToInventoryCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness))
		|			THEN TRUE
		|		WHEN SUM(Unallocated_.SumComplBalance) = 0 AND SUM(Unallocated_.AmountFABalance) = 0
		|			THEN SUM(Unallocated_.PermanentDifferenceBalance) = 0
		|		WHEN NOT MAX(Unallocated_.ThereIsErrorInCalculationOfAC)
		|			THEN SUM(Unallocated_.SumComplBalance) = 0
		|		ELSE SUM(Unallocated_.SumComplBalance) BETWEEN -&LocalErrorValue AND &LocalErrorValue
		|	END AS DistributedByWBU,
		|	CASE
		|		WHEN NOT Unallocated_.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToInventoryCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness))
		|			THEN TRUE
		|		WHEN NOT MAX(Unallocated_.ThereIsCalculationErrorTa)
		|			THEN (SUM(Unallocated_.AmountFABalance) = 0)
		|		ELSE (SUM(Unallocated_.AmountFABalance) BETWEEN -&LocalErrorValue AND &LocalErrorValue)
		|	END AS  DistributedByVNU,
		|	CASE
		|		WHEN NOT Unallocated_.AITCostAllocationOption IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToInventoryCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness))
		|			THEN TRUE
		|		WHEN NOT MAX(Unallocated_.ThereIsErrorInAITCalculation)
		|			THEN (SUM(Unallocated_.AITAmountBalance) = 0)
		|		ELSE (SUM(Unallocated_.AITAmountBalance) BETWEEN -&LocalErrorValue AND &LocalErrorValue)
		|	END AS  DistributedGNI
		|INTO PostDistributionExpenses
		|FROM
		|	&SourcesOfUnallocatedExpenses AS Unallocated_
		|
		|GROUP BY
		|	Unallocated_.Organization,
		|	Unallocated_.Department,
		|	Unallocated_.LineOfBusiness,
		|	Unallocated_.ExpenseItem,
		|	Unallocated_.DimensionOfExpenses,
		|	Unallocated_.CostAllocationOptionManag,
		|	Unallocated_.CostAllocationOptionLocal,
		|	Unallocated_.CostAllocationOptionTax,
		|	Unallocated_.AITCostAllocationOption
		|
		|INDEX BY
		|	Unallocated_.ExpenseItem,
		|	Unallocated_.DimensionOfExpenses,
		|	Unallocated_.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	T.Organization AS Organization,
		|	MIN(T.Month) AS Month
		|INTO Jobs
		|FROM
		|	(SELECT
		|		Jobs.Organization AS Organization,
		|		BEGINOFPERIOD(Jobs.Month, Month) AS Month
		|	FROM
		|		InformationRegister.JobsForCalculatingCost AS Jobs
		|	WHERE
		|		(&ByAllCompanies
		|				OR Jobs.Organization IN (&CompanyArray))
		|
		|	UNION ALL
		|
		// The Query Text should be similar to the function There is a document for the Preliminary Cost calculation()
		// of the general Cost calculation module for the Payment algorithms.
		|	SELECT TOP 1
		|		InventoryCostCalculation.Organization AS Organization,
		|		BEGINOFPERIOD(InventoryCostCalculation.Date, MONTH) AS Month
		|	FROM
		|		Document.InventoryCostCalculation AS InventoryCostCalculation
		|	WHERE
		|		InventoryCostCalculation.Organization.Ref IN (&CompanyArray)
		|		AND InventoryCostCalculation.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|		AND InventoryCostCalculation.Posted
		|		AND InventoryCostCalculation.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
		|		AND InventoryCostCalculation.MonthEndClosingMode
		|			= VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|	) AS T
		|
		|GROUP BY
		|	T.Organization
		|;
		|
		|SELECT
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost) AS NotDistributedInMan,
		|	ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost) AS NotDistributedInLocal,
		|	ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToInventoryCost) AS NotDistributedInRussia,
		|	T.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToInventoryCost) AS GNIIsNotDistributed
		|INTO UnallocatedExpensesOnCostOfGoods
		|FROM
		|	ExpensesForDistributionAreSummarized AS T
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON T.ExpenseItem = ExpenseItems.Ref
		|WHERE
		|	(ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		OR ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		OR ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|		OR T.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|	)
		|	AND TRUE IN (SELECT TOP 1 TRUE
		|		FROM InformationRegister.DocumentsRegistry AS DD
		|		WHERE DD.Ref = T.DimensionOfExpenses
		|		AND (DD.IBDocumentDate > &EndOfPeriod 
		|			OR NOT DD.Posted)
		|	)
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	Organization,
		|	LineOfBusiness
		|;
		|
		|SELECT
		|	Source.Organization AS Organization,
		|	Source.Department AS Department,
		|	Source.LineOfBusiness AS LineOfBusiness,
		|	Source.ExpenseItem AS ExpenseItem,
		|	Source.DimensionOfExpenses AS DimensionOfExpenses,
		|	ISNULL(ManDocuments.Document, VALUE(Document.AllocationOfOtherCosts.EmptyRef)) AS DocumentMan,
		|	ISNULL(LocalDocuments.Document, VALUE(Document.AllocationOfOtherCosts.EmptyRef)) AS DocumentCompl,
		|	ISNULL(AITDocuments.Document, VALUE(Document.AllocationOfOtherCosts.EmptyRef)) AS DocumentAIT,
		|	Source.CostAllocationOptionManag AS CostAllocationOptionManag,
		|	Source.CostAllocationOptionLocal AS CostAllocationOptionLocal,
		|	Source.CostAllocationOptionTax AS CostAllocationOptionTax,
		|	Source.AITCostAllocationOption AS AITCostAllocationOption,
		|	Source.Sum AS Sum,
		|	Source.AmountExcludingVAT AS AmountExcludingVAT,
		|	Source.SumCompl AS SumCompl,
		|	Source.AITAmount AS AITAmount,
		|	Source.SumMan AS SumMan,
		|	Source.PermanentDifference AS PermanentDifference,
		|	Source.CostTD AS CostTD,
		|	(CASE
		|		WHEN NOT ISNULL(Balance.DistributedByVUU, TRUE)
		|			THEN ISNULL(Balance.SumBalance, 0)
		|		ELSE 0 END) AS SumBalance,
		|	(CASE
		|		WHEN NOT ISNULL(Balance.DistributedByVUU, TRUE)
		|			THEN ISNULL(Balance.AmountExcludingVATBalance, 0)
		|		ELSE 0 END) AS AmountExcludingVATBalance,
		|	(CASE
		|		WHEN NOT ISNULL(Balance.DistributedByVUU, TRUE)
		|			THEN ISNULL(Balance.SumManBalance, 0)
		|		ELSE 0 END) AS SumManBalance,
		|	(CASE
		|		WHEN NOT ISNULL(Balance.DistributedByWBU, TRUE)
		|			THEN ISNULL(Balance.SumComplBalance, 0)
		|		ELSE 0 END) AS SumComplBalance,
		|	(CASE
		|		WHEN NOT ISNULL(Balance.DistributedByVNU, TRUE)
		|			THEN ISNULL(Balance.AmountFABalance, 0)
		|		ELSE 0 END) AS AmountFABalance,
		|	ISNULL(Balance.DistributedByVUU, TRUE) AS DistributedByVUU,
		|	ISNULL(Balance.DistributedByWBU, TRUE) AS DistributedByWBU,
		|	ISNULL(Balance.DistributedByVNU, TRUE) AS DistributedByVNU,
		|	ISNULL(Balance.DistributedGNI, TRUE) AS DistributedGNI,
		
		//////////////////////////////////////////////////////////////////
		// MA State
		//////////////////////////////////////////////////////////////////
		|	CASE
		// excellent distribution options from those listed, the workplace does not serve.
		|		WHEN NOT Source.CostAllocationOptionManag IN (&CostAllocationOptions)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// the distribution analysis is incorrect or refers to future closing periods
		|		WHEN ISNULL(UnallocatedExpenses.NotDistributedInMan, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// articles with a distribution option ""On HIA"" are processed in summary, no document is required
		|		WHEN NOT Source.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND Source.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// if the month is closed, there are no Balances and no movements
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL)
		|			AND ISNULL(Balance.DistributedByVUU, TRUE)
		|			AND NOT (
		|				ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnFinancialResultOfMan, FALSE) 
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsForProductionOfMan, FALSE)
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreLinksToOtherManArticles, FALSE)
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenHIAMan, FALSE)
		|			)
		|			THEN VALUE(Enum.CostAllocationStates.ExpensesNotReceived)
		// if the month is closed and there are no expenses, then the state is distributed
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL) 
		|			AND ISNULL(Balance.DistributedByVUU, TRUE)
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		// If the distribution of shares is not configured, there is a Balance to the distribution and a rule with manual filling,
		// then manual adjustment is required.
		|		WHEN ManDocuments.Document IS NULL
		|				AND NOT (
		|					ManSRules.Rule IS NULL 
		|					AND RulesOfManOvz.Rule IS NULL
		|				)
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		// If the distribution of shares is not configured, there is a Balance for distribution and the calculation item is not filled in in the expense
		// item, then manual configuration is required.
		|		WHEN ManDocuments.Document IS NULL
		|			AND ISNULL(WithoutCalculationArticle.WithoutManSCalculationArticle, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		// If the distribution of shares is not configured, but the month is closed, then it is not distributed.
		|		WHEN Jobs.Month > &EndOfPeriod AND ManDocuments.Document IS NULL
		|		 AND Source.CostAllocationOptionManag <> VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
		|		 AND Source.CostAllocationOptionManag <> VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN VALUE(Enum.CostAllocationStates.NotAllocated)
		// If the distribution of shares is not configured, and there is a remainder to the distribution, then configuration is required.
		|		WHEN ManDocuments.Document IS NULL AND (NOT ISNULL(Balance.DistributedByVUU, TRUE) OR Source.EstimatedAmount)
		|			THEN VALUE(Enum.CostAllocationStates.DocumentGenerationIsRequired)
		// If there is a distribution of shares, the distribution document has made a RegisteredRecord for production, but there is a Balance to the distribution, that is, an error.
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedByVUU, TRUE)
		|			AND Source.CostAllocationOptionManag 
		|				IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|					VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsForProductionOfMan, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		// If there is a distribution between the HIA, the distribution document has RegisteredRecords, but there is a Balance to the distribution, that is, an error.
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedByVUU, TRUE)
		|			AND Source.CostAllocationOptionManag
		|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenHIAMan, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		// If there is a distribution of shares, the distribution document has made RegisteredRecords on the fin. res., but there is a Balance to the distribution, that is, an error.
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedByVUU, TRUE)
		|			AND Source.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|														VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnFinancialResultOfMan, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		// If there is a distribution of shares, the distribution document has made movements and the article is fully distributed, then the costs are distributed.
		|		WHEN ISNULL(Balance.DistributedByVUU, TRUE)
		|			AND (ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnFinancialResultOfMan, FALSE) 
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsForProductionOfMan, FALSE) 
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreLinksToOtherManArticles, FALSE)
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenHIAMan, FALSE)
		|			)
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		// If the Unfinished production is 100%, then by default it is distributed
		|		WHEN ManDocuments.LeaveAsWIP AND ManDocuments.CostShareOfWIP = ManDocuments.TotalCostShares
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		// If the month is not closed, there is no Balance for distribution and the amount is not calculated
		|		WHEN Jobs.Month < &EndOfPeriod AND ISNULL(Balance.DistributedByVUU, TRUE) AND NOT Source.EstimatedAmount
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		ELSE VALUE(Enum.CostAllocationStates.ReadyForAllocation)
		|	END AS StateOfTheUU,
		//////////////////////////////////////////////////////////////////
		// AC State
		//////////////////////////////////////////////////////////////////
		|	CASE
		// If the Source.The expenditure article is filled in with the option ""On HIA"", which means that the setting will be in the context of HIA, not articles
		|		WHEN Source.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				AND NOT Source.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN NOT Source.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN ISNULL(UnallocatedExpenses.NotDistributedInLocal, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL) 
		|			AND ISNULL(Balance.DistributedByWBU, TRUE)
		|			AND NOT (ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnFinancialResultOfLocal, FALSE) OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnLocalProduction, FALSE)
		|					OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreLinksToOtherLocalArticles, FALSE)
		|					OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenHIAAndLocal, FALSE)
		|				)
		|			THEN VALUE(Enum.CostAllocationStates.ExpensesNotReceived)
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL) 
		|			AND Source.ExpenseItem.ExpenseKind = VALUE(Enum.ExpenseKindsTA.TransportationExpenses)
		|						AND WriteOffShares.PercentageOfWriteOffs = 0
		|			AND NOT ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnFinancialResultOfLocal, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL) 
		|			AND ISNULL(Balance.DistributedByWBU, TRUE)
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		|		WHEN LocalDocuments.Document IS NULL
		|				AND NOT (
		|					LocalRules.Rule IS NULL
		|					AND RulesOfLocalOvz.Rule IS NULL
		|				)
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		|		WHEN LocalDocuments.Document IS NULL
		|			AND ISNULL(WithoutCalculationArticle.WithoutLocalCalculationArticle, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		|		WHEN Jobs.Month > &EndOfPeriod AND LocalDocuments.Document IS NULL
		|		 AND Source.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
		|		 AND Source.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN VALUE(Enum.CostAllocationStates.NotAllocated)
		|		WHEN LocalDocuments.Document IS NULL AND (NOT ISNULL(Balance.DistributedByWBU, TRUE) OR Source.EstimatedAmount)
		|			THEN VALUE(Enum.CostAllocationStates.DocumentGenerationIsRequired)
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedByWBU, TRUE)
		|			AND Source.CostAllocationOptionLocal 
		|				IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|					VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnLocalProduction, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedByWBU, TRUE)
		|			AND Source.CostAllocationOptionLocal 
		|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenHIAAndLocal, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedByWBU, TRUE)
		|			AND Source.CostAllocationOptionLocal IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|															VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnFinancialResultOfLocal, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		|		WHEN ISNULL(UnallocatedExpenses.NotDistributedInRussia, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN ISNULL(Balance.DistributedByWBU, TRUE)
		|			AND (ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnFinancialResultOfLocal, FALSE) 
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsOnLocalProduction, FALSE) 
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenHIAAndLocal, FALSE)
		|			)
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		|		WHEN LocalDocuments.LeaveAsWIP AND LocalDocuments.CostShareOfWIP = LocalDocuments.TotalCostShares
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		|		WHEN Jobs.Month < &EndOfPeriod AND ISNULL(Balance.DistributedByWBU, TRUE) AND NOT Source.EstimatedAmount
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		ELSE VALUE(Enum.CostAllocationStates.ReadyForAllocation)
		|	END AS BUState

		//////////////////////////////////////////////////////////////////
		// The State of the personal income tax
		//////////////////////////////////////////////////////////////////
		|	,CASE
		// If the option for RBP or HPA has been selected in the WELL, then distribution is not required at this stage.
		|		WHEN Source.CostAllocationOptionTax IN (VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|													 		VALUE(Enum.CostAllocationOptions.ToDeferredExpenses))
		|			AND Source.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// If the recognition settings have an empty recognition option, then AIT expenses for the item are not included in the cost (recognized or not recognized).
		|		WHEN Source.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND AITArticleDistributionSettings.ExpenseRecognitionOption IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// If CO expenses are allocated and the recognition option is not selected, AIT expenses for this CO are not included in the cost (recognized or not recognized).
		|		WHEN Source.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND TTOvz.ConstCenter IS NOT NULL
		|				AND SettingsForDistributionOfAITArticlesByCostCenter.ExpenseRecognitionOption IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN Source.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND NOT Source.ExpenseItem.RecognizedInAITExpenses
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// If the Source.The expenditure article is filled in with the option ""For CO"", which means that the setting will be in the context of the CO, and not the article.
		|		WHEN Source.AITCostAllocationOption = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				AND NOT Source.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// excellent distribution options from those listed, the workplace does not serve.
		|		WHEN NOT Source.AITCostAllocationOption IN (&CostAllocationOptions)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// If the month is closed, there are no Balances and no Registered Records.
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL) 
		|			AND ISNULL(Balance.DistributedGNI, TRUE)
		|			AND NOT (ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsRegisteredRecordOfProfitabilityAndCostOfAIT, FALSE) 
		|					OR ISNULL(RegisteredRecordsOfExpenditureItems.HasRegisteredRecordForProductionAIT, FALSE)
		|					OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsWriteOffOfAIT, FALSE)
		|					OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsRegisteredRecordsForOtherArticlesAIT, FALSE)
		|					OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenCostCenterAIT, FALSE)
		|				)
		|			THEN VALUE(Enum.CostAllocationStates.ExpensesNotReceived)
		// If the month is closed, these are transportation costs, the share of write-off = 0, and there are no Registered Records on the fin. res., then the State is not required.
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL) 
		|			AND Source.ExpenseItem.ExpenseKind = VALUE(Enum.ExpenseKindsTA.TransportationExpenses)
		|						AND WriteOffShares.PercentageOfWriteOffs = 0
		|			AND NOT ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsRegisteredRecordOfProfitabilityAndCostOfAIT, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// If the month is closed and there are no expenses, then the State is distributed.
		|		WHEN (Jobs.Month > &EndOfPeriod OR Jobs.Month IS NULL) 
		|			AND ISNULL(Balance.DistributedGNI, TRUE)
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		// If the distribution of shares is not configured, there is a Balance to the distribution and a rule with manual filling,
		// then manual adjustment is required.
		|		WHEN AITDocuments.Document IS NULL
		|				AND NOT (
		|					AITRules.Rule IS NULL
		|					AND AITCostCentersRules.Rule IS NULL
		|				)
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		// If the distribution of shares is not configured, there is a Balance for distribution and the calculation item is not filled in in the expense
		// item, then manual configuration is required.
		|		WHEN AITDocuments.Document IS NULL
		|			AND ISNULL(WithoutCalculationArticle.WithoutAITCalculationArticle, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		// If the distribution of shares is not configured, but the month is closed, then it is not distributed.
		|		WHEN Jobs.Month > &EndOfPeriod AND AITDocuments.Document IS NULL
		|		 AND Source.AITCostAllocationOption <> VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
		|		 AND Source.AITCostAllocationOption <> VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN VALUE(Enum.CostAllocationStates.NotAllocated)
		// If the distribution of shares is not configured, and there is a remainder to the distribution, then configuration is required.
		|		WHEN AITDocuments.Document IS NULL 
		|			AND (NOT ISNULL(Balance.DistributedGNI, TRUE) 
		|				OR Source.EstimatedAmount)
		|			THEN VALUE(Enum.CostAllocationStates.DocumentGenerationIsRequired)
		// If there is a distribution of shares, the distribution document has made RegisteredRecords on the fin. res. or to write-off AIT amounts, but there is a Balance for distribution, that is, an error.
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedGNI, TRUE)
		|			AND (ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsRegisteredRecordOfProfitabilityAndCostOfAIT, FALSE)
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsWriteOffOfAIT, FALSE))
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		// If there is a distribution of shares, the distribution document has made a RegisteredRecord for production, but there is a Balance to the distribution, that is, an error.
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedGNI, TRUE)
		|			AND Source.AITCostAllocationOption 
		|				= VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.HasRegisteredRecordForProductionAIT, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		// If there is a distribution between the HIA, the distribution document has RegisteredRecords, but there is a Balance to the distribution, that is, an error.
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedGNI, TRUE)
		|			AND Source.AITCostAllocationOption 
		|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenCostCenterAIT, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		// If there is a distribution of shares, the distribution document has made RegisteredRecords on the fin. res., but there is a Balance to the distribution, that is, an error.
		|		WHEN Jobs.Month > &EndOfPeriod AND NOT ISNULL(Balance.DistributedGNI, TRUE)
		|			AND Source.AITCostAllocationOption IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|														VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			AND ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsRegisteredRecordOfProfitabilityAndCostOfAIT, FALSE)
		|			THEN VALUE(Enum.CostAllocationStates.AllocationError)
		// If there is a distribution of shares, the distribution document has made movements and the article is fully distributed, then the costs are distributed.
		|		WHEN ISNULL(Balance.DistributedGNI, TRUE)
		|			AND (ISNULL(RegisteredRecordsOfExpenditureItems.ThereIsRegisteredRecordOfProfitabilityAndCostOfAIT, FALSE) 
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.HasRegisteredRecordForProductionAIT, FALSE) 
		|				OR ISNULL(RegisteredRecordsOfExpenditureItems.ThereAreRegisteredRecordsBetweenCostCenterAIT, FALSE)
		|			)
		|			THEN VALUE(Enum.CostAllocationStates.Allocated)
		// If the month is not closed, there is no Balance for distribution and the amount is not calculated.
		|		WHEN Jobs.Month < &EndOfPeriod AND ISNULL(Balance.DistributedGNI, TRUE) AND NOT Source.EstimatedAmount
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// For ease of tagging.
		|		WHEN TRUE
		|			THEN VALUE(Enum.CostAllocationStates.ReadyForAllocation)
		|		WHEN TRUE
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|	END AS NDDState
		|
		|INTO TTDataForDistribution
		|FROM
		|	ExpensesForDistributionAreSummarized AS Source
		|		LEFT JOIN Jobs AS Jobs
		|		ON Source.Organization = Jobs.Organization
		|
		|		LEFT JOIN TTOvz AS TTOvz
		|		ON Source.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			AND Source.DimensionOfExpenses = TTOvz.ConstCenter
		|
		|		LEFT JOIN PostDistributionExpenses AS Balance
		|		ON	Source.ExpenseItem 			= Balance.ExpenseItem
		|			AND Source.DimensionOfExpenses 		= Balance.DimensionOfExpenses
		|			AND Source.Department			= Balance.Department
		|			AND Source.Organization				= Balance.Organization
		|			AND Source.LineOfBusiness	= Balance.LineOfBusiness
		|		
		|		LEFT JOIN DistributionDocuments AS ManDocuments
		|		ON	Source.ExpenseItem				= ManDocuments.ExpenseItem
		|			AND Source.DimensionOfExpenses 		= ManDocuments.DimensionOfExpenses
		|			AND Source.Department			= ManDocuments.Department
		|			AND Source.LineOfBusiness	= ManDocuments.LineOfBusiness
		|			AND Source.Organization				= ManDocuments.Organization
		|			AND ManDocuments.ManagementAccounting
		|
		|		LEFT JOIN DistributionDocuments AS LocalDocuments
		|		ON	Source.ExpenseItem				= LocalDocuments.ExpenseItem
		|			AND Source.DimensionOfExpenses 		= LocalDocuments.DimensionOfExpenses
		|			AND Source.Department			= LocalDocuments.Department
		|			AND Source.LineOfBusiness	= LocalDocuments.LineOfBusiness
		|			AND Source.Organization				= LocalDocuments.Organization
		|			AND LocalDocuments.LocalAccounting
		|
		|
		|		LEFT JOIN DistributionDocuments AS AITDocuments
		|		ON	Source.ExpenseItem				= AITDocuments.ExpenseItem
		|			AND Source.DimensionOfExpenses 		= AITDocuments.DimensionOfExpenses
		|			AND Source.Department			= AITDocuments.Department
		|			AND Source.LineOfBusiness	= AITDocuments.LineOfBusiness
		|			AND Source.Organization				= AITDocuments.Organization
		|			AND AITDocuments.AIT
		|
		|		LEFT JOIN RegisteredRecordsOfExpenditureItems AS RegisteredRecordsOfExpenditureItems
		|		ON	Source.ExpenseItem				= RegisteredRecordsOfExpenditureItems.ExpenseItem
		|			AND Source.DimensionOfExpenses 		= RegisteredRecordsOfExpenditureItems.DimensionOfExpenses
		|			AND Source.Department			= RegisteredRecordsOfExpenditureItems.Department
		|			AND Source.LineOfBusiness	= RegisteredRecordsOfExpenditureItems.LineOfBusiness
		|			AND Source.Organization				= RegisteredRecordsOfExpenditureItems.Organization
		|
		|		LEFT JOIN UnallocatedExpensesOnCostOfGoods AS UnallocatedExpenses
		|		ON	Source.ExpenseItem				= UnallocatedExpenses.ExpenseItem
		|			AND Source.DimensionOfExpenses 		= UnallocatedExpenses.DimensionOfExpenses
		|			AND Source.Department			= UnallocatedExpenses.Department
		|			AND Source.LineOfBusiness	= UnallocatedExpenses.LineOfBusiness
		|			AND Source.Organization				= UnallocatedExpenses.Organization
		|		LEFT JOIN TTShareOfWriteOffOfIndirectExpenses AS WriteOffShares
		|		ON Source.ExpenseItem = WriteOffShares.ExpenseItem
		|			AND Source.Organization = WriteOffShares.Organization
		|			AND WriteOffShares.Transportation
		|		LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS SettingsForDistributionOfAITArticlesByCostCenter
		|		ON Source.DimensionOfExpenses  = SettingsForDistributionOfAITArticlesByCostCenter.ConstCenter
		|			AND SettingsForDistributionOfAITArticlesByCostCenter.ExpensesAreIncludedInCost
		|		LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|		ON Source.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|			AND &Source_ObjectOfSeparateAccountingAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|			AND Source.Organization = AITArticleDistributionSettings.Organization
		|			AND AITArticleDistributionSettings.ExpensesAreIncludedInCost
		|		LEFT JOIN RulesForDistributionBySettings AS Rules
		|		ON	Source.ExpenseItem				= Rules.ExpenseItem
		|			AND Source.DimensionOfExpenses 		= Rules.DimensionOfExpenses
		|			AND Source.Department			= Rules.Department
		|			AND Source.LineOfBusiness	= Rules.LineOfBusiness
		|			AND Source.Organization				= Rules.Organization
		|		LEFT JOIN ExpenditureItemsWithoutCalculationItems AS WithoutCalculationArticle
		|		ON	Source.ExpenseItem = WithoutCalculationArticle.Ref
		|		LEFT JOIN ManualDistributionRules AS ManSRules
		|		ON	Rules.ManDistributionRule = ManSRules.Rule
		|			AND Source.CostAllocationOptionManag = ManSRules.AllocationOption
		|		LEFT JOIN ManualDistributionRules AS LocalRules
		|		ON	Rules.LocalDistributionRule = LocalRules.Rule
		|			AND Source.CostAllocationOptionLocal = LocalRules.AllocationOption
		|		LEFT JOIN ManualDistributionRules AS AITRules
		|		ON	AITArticleDistributionSettings.CostAllocationRuleAIT = AITRules.Rule
		|			AND AITArticleDistributionSettings.ExpensesAreIncludedInCost
		|		LEFT JOIN ManualDistributionRules AS RulesOfManOvz
		|		ON	TTOvz.CostAllocationRuleManag = RulesOfManOvz.Rule
		|		LEFT JOIN ManualDistributionRules AS RulesOfLocalOvz
		|		ON	TTOvz.CostAllocationRuleLocal = RulesOfLocalOvz.Rule
		|		LEFT JOIN ManualDistributionRules AS AITCostCentersRules
		|		ON SettingsForDistributionOfAITArticlesByCostCenter.CostAllocationRuleAIT = AITCostCentersRules.Rule
		|			AND SettingsForDistributionOfAITArticlesByCostCenter.ExpensesAreIncludedInCost
		|
		|UNION
		|
		|SELECT DISTINCT
		|	CostCenters.Organization,
		|	CostCenters.Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
		|	CostCenters.Ref,
		|	ManDocuments.Ref,
		|	LocalDocuments.Ref,
		|	AITDocuments.Ref,
		|	CostCenters.CostAllocationOptionManag,
		|	CostCenters.CostAllocationOptionLocal,
		|	CostCenters.CostAllocationOptionTax,
		|	ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption,
		|		VALUE(Enum.CostAllocationOptions.EmptyRef)) AS AITCostAllocationOption,
		|	0 AS Sum,
		|	0 AS AmountExcludingVAT,
		|	0 AS SumCompl,
		|	0 AS AITAmount,
		|	0 AS SumMan,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS SumBalance,
		|	0 AS AmountExcludingVATBalance,
		|	0 AS SumManBalance,
		|	0 AS SumComplBalance,
		|	0 AS AmountFABalance,
		|	Jobs.Month > &EndOfPeriod AS DistributedByVUU,
		|	Jobs.Month > &EndOfPeriod AS DistributedByWBU,
		|	Jobs.Month > &EndOfPeriod AS DistributedByVNU,
		|	Jobs.Month > &EndOfPeriod AS DistributedGNI,
		|	CASE
		|		WHEN NOT CostCenters.CostAllocationOptionManag IN (&CostAllocationOptions)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN Jobs.Month > &EndOfPeriod
		|			AND CostCenters.CostAllocationOptionManag 
		|				IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|					VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
		|					VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|					VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|					VALUE(Enum.CostAllocationOptions.ToCostCenters))
		|			THEN VALUE(Enum.CostAllocationStates.ExpensesNotReceived)
		|		WHEN ManDocuments.Ref IS NULL
		|				AND CostCenters.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|				AND NOT ManSRules.Rule IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		|		WHEN ManDocuments.Ref IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.DocumentGenerationIsRequired)
		|		ELSE VALUE(Enum.CostAllocationStates.ReadyForAllocation)
		|	END,
		|	CASE
		|		WHEN NOT CostCenters.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN Jobs.Month > &EndOfPeriod
		|			AND CostCenters.CostAllocationOptionLocal 
		|				IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|					VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
		|					VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|					VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|					VALUE(Enum.CostAllocationOptions.ToCostCenters))
		|			THEN VALUE(Enum.CostAllocationStates.ExpensesNotReceived)
		|		WHEN LocalDocuments.Ref IS NULL
		|				AND CostCenters.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|				AND NOT LocalRules.Rule IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		|		WHEN LocalDocuments.Ref IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.DocumentGenerationIsRequired)
		|		ELSE VALUE(Enum.CostAllocationStates.ReadyForAllocation)
		|	END
		
		|	,CASE
		|		WHEN NOT ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (&CostAllocationOptions)
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		// If the recognition option is not selected for the CO, then AIT expenses for this CO are not included in the cost (recognized or not recognized).
		|		WHEN SettingsForDistributionOfAITArticlesByCostCenter.ExpenseRecognitionOption IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.NotRequired)
		|		WHEN Jobs.Month > &EndOfPeriod
		|			AND ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef)) 
		|				IN (VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|					VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
		|					VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|					VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|					VALUE(Enum.CostAllocationOptions.ToCostCenters))
		|			THEN VALUE(Enum.CostAllocationStates.ExpensesNotReceived)
		|		WHEN AITDocuments.Ref IS NULL
		|				AND ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|				AND AITCostCentersRules.Rule IS NOT NULL
		|			THEN VALUE(Enum.CostAllocationStates.RequiresManualDocumentInput)
		|		WHEN AITDocuments.Ref IS NULL
		|			THEN VALUE(Enum.CostAllocationStates.DocumentGenerationIsRequired)
		|		ELSE VALUE(Enum.CostAllocationStates.ReadyForAllocation)
		|	END
		|FROM
		|	InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast(&EndOfPeriod) AS ValuesForHIA
		|	INNER JOIN Catalog.CostCenters AS CostCenters
		|		ON	CostCenters.Ref = ValuesForHIA.ConstCenter
		|	LEFT JOIN Jobs AS Jobs
		|		ON CostCenters.Organization = Jobs.Organization
		|	LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS SettingsForDistributionOfAITArticlesByCostCenter
		|		ON ValuesForHIA.ConstCenter  = SettingsForDistributionOfAITArticlesByCostCenter.ConstCenter
		|		AND SettingsForDistributionOfAITArticlesByCostCenter.ExpensesAreIncludedInCost
		|	LEFT JOIN Document.AllocationOfOtherCosts AS ManDocuments
		|		ON	ManDocuments.DimensionOfExpenses = CostCenters.Ref
		|			AND ManDocuments.Organization = CostCenters.Organization
		|			AND ManDocuments.Department = CostCenters.Department
		|			AND ManDocuments.ManagementAccounting
		|			AND ManDocuments.Posted
		|			AND BEGINOFPERIOD(ManDocuments.Date, Month) = &BeginOfPeriod
		|	LEFT JOIN Document.AllocationOfOtherCosts AS LocalDocuments
		|		ON	LocalDocuments.DimensionOfExpenses = CostCenters.Ref 
		|			AND LocalDocuments.Organization = CostCenters.Organization
		|			AND LocalDocuments.Department = CostCenters.Department
		|			AND LocalDocuments.LocalAccounting
		|			AND LocalDocuments.Posted
		|			AND BEGINOFPERIOD(LocalDocuments.Date, Month) = &BeginOfPeriod
		|	LEFT JOIN Document.AllocationOfOtherCosts AS AITDocuments
		|		ON	AITDocuments.DimensionOfExpenses = CostCenters.Ref 
		|			AND AITDocuments.Organization = CostCenters.Organization
		|			AND AITDocuments.Department = CostCenters.Department
		|			AND AITDocuments.AIT
		|			AND AITDocuments.Posted
		|			AND BEGINOFPERIOD(AITDocuments.Date, Month) = &BeginOfPeriod
		|	LEFT JOIN ExpenseForAllocation AS OtherSegmentExpenses
		|		ON	CostCenters.Ref 			= OtherSegmentExpenses.DimensionOfExpenses
		|			AND CostCenters.Department	= OtherSegmentExpenses.Department
		|			AND CostCenters.Organization	= OtherSegmentExpenses.Organization
		|	LEFT JOIN ManualDistributionRules AS ManSRules
		|		ON	CostCenters.CostAllocationRuleManag = ManSRules.Rule
		|	LEFT JOIN ManualDistributionRules AS LocalRules
		|		ON	CostCenters.CostAllocationRuleLocal = LocalRules.Rule
		|		LEFT JOIN ManualDistributionRules AS AITCostCentersRules
		|		ON SettingsForDistributionOfAITArticlesByCostCenter.CostAllocationRuleAIT = AITCostCentersRules.Rule
		|WHERE
		|	(ValuesForHIA.Factor.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis) 
		|	AND ValuesForHIA.Period = &BeginOfPeriod
		|	OR ValuesForHIA.Factor.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand))
		|	AND NOT ValuesForHIA.IndicatorValue = 0
		|	AND (&ByAllCompanies
		|		OR CostCenters.Organization IN (&CompanyArray))
		|	AND (&ByAllBusinessUnits
		|		OR CostCenters.Department IN (&DepartmentList))
		|	AND OtherSegmentExpenses.Organization IS NULL 
		|	AND (CostCenters.CostAllocationOptionManag IN (&CostAllocationOptions)
		|	OR CostCenters.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|	OR ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption, VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (&CostAllocationOptions)
		|	)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT TOP 100
		|	TTDataToDownload.Organization AS Organization,
		|	TTDataToDownload.Department AS Department,
		|	&LineOfBusiness AS LineOfBusiness,
		|	&ExpenseItem AS ExpenseItem,
		|	ISNULL(ExpenseItems.Parent, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) AS GroupItem,
		|	TTDataToDownload.DimensionOfExpenses AS DimensionOfExpenses,
		|	TTDataToDownload.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ThisIsOVZ,
		|	TTDataToDownload.DocumentMan AS DocumentMan,
		|	TTDataToDownload.DocumentCompl AS DocumentCompl,
		|	TTDataToDownload.SumBalance AS SumBalance,
		|	TTDataToDownload.AmountExcludingVATBalance AS AmountExcludingVATBalance,
		|	TTDataToDownload.SumManBalance AS SumManBalance,
		|	TTDataToDownload.SumComplBalance AS SumComplBalance,
		|
		|	TTDataToDownload.DocumentAIT AS DocumentAIT,
		|	TTDataToDownload.StateOfTheUU AS UPRStatus,
		|	TTDataToDownload.BUState AS ReglStatus
		|	,
		|	TTDataToDownload.NDDState AS NDDState
		|INTO StateOfCostAllocation
		|FROM
		|	TTDataForDistribution AS TTDataToDownload
		|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON TTDataToDownload.ExpenseItem = ExpenseItems.Ref
		|		LEFT JOIN Catalog.LinesOfBusiness AS CatLinesOfBusiness
		|		ON TTDataToDownload.LineOfBusiness = CatLinesOfBusiness.Ref
		|WHERE
		|	CASE
		|		WHEN &FilterByState = VALUE(Enum.CostAllocationStates.EmptyRef)
		|			THEN TRUE
		|		ELSE 
		|			(TTDataToDownload.CostAllocationOptionManag IN (&CostAllocationOptions)
		|				 AND TTDataToDownload.StateOfTheUU = &FilterByState)
		|			OR
		|			(TTDataToDownload.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|				 AND TTDataToDownload.BUState = &FilterByState)
		|			OR
		|			(TTDataToDownload.AITCostAllocationOption IN (&CostAllocationOptions)
		|				 AND TTDataToDownload.NDDState = &FilterByState)
		|	END
		|	AND NOT (
		|		TTDataToDownload.StateOfTheUU IN (
		|			VALUE(Enum.CostAllocationStates.NotRequired), 
		|			VALUE(Enum.CostAllocationStates.ExpensesNotReceived))
		|		AND TTDataToDownload.BUState IN (
		|			VALUE(Enum.CostAllocationStates.NotRequired), 
		|			VALUE(Enum.CostAllocationStates.ExpensesNotReceived))
		|		AND TTDataToDownload.NDDState = VALUE(Enum.CostAllocationStates.NotRequired)
		|		)
		|;
		|";
	
	SourceDebuggingMode = CalculationOfCostCached.ValuesOfTechnologicalParameters().GenerateTTSourcesOfExpenses;
	If SourceDebuggingMode Then
		QueryText = StrReplace(QueryText, 
			"// TTSourcesOfUnallocatedExpenses",
			RequestTextExpensesAfterDistributionSources()+";"); //@Query-part
		QueryText = StrReplace(QueryText,
			"&SourcesOfUnallocatedExpenses",
			"TTSourcesOfUnallocatedExpenses"
			); //@Query-part-1 @Query-part-2
		QueryText = StrReplace(QueryText, 
			"//DebugMode", //@Query-part
			""
			);  //@Query-part-1
	Else
		QueryText = StrReplace(QueryText, 
			"&SourcesOfUnallocatedExpenses",
			"("+RequestTextExpensesAfterDistributionSources()+")"); //@Query-part 
	EndIf;
	
	TextToReplace = 
		"TOP 100"; //@Query-part
	If ChooseFirst > 0 Then
		ReplacementText_ = 
			"TOP "
			+ String(ChooseFirst); //@Query-part
	Else
		ReplacementText_ = ""; 
	EndIf;
	QueryText = StrReplace(QueryText, TextToReplace, ReplacementText_);
	
	// The item of expenditure and line of business may be empty links. 
	// For checks, you need to replace it with NULL so that you don't get into the selections by registers.
	If Not CurrentStateOfIWTExpenditure Then
		QueryText = StrReplace(QueryText, 
			"INTO StateOfCostAllocation",
			"");  //@Query-part
			
		QueryText = StrReplace(QueryText, 
			"&ExpenseItem AS ExpenseItem",
			"TTDataToDownload.ExpenseItem AS ExpenseItem"
			); //@Query-part-1 @Query-part-2
		QueryText = StrReplace(QueryText, 
			"&LineOfBusiness AS LineOfBusiness",
			"TTDataToDownload.LineOfBusiness AS LineOfBusiness"
			); //@Query-part-1 @Query-part-2
	Else
		QueryText = StrReplace(QueryText, 
			"&ExpenseItem AS ExpenseItem",
			"ExpenseItems.Ref AS ExpenseItem"
			); //@Query-part-1 @Query-part-2
		QueryText = StrReplace(QueryText, 
			"&LineOfBusiness AS LineOfBusiness",
			"CatLinesOfBusiness.Ref AS LineOfBusiness"
			); //@Query-part-1 @Query-part-2
	EndIf;
	
	// A list of AIT parameter names in the connections to replace. 
	ParametersOfSeparateAccountingObjectAIT = New Array; //Array of String
	ParametersOfSeparateAccountingObjectAIT.Add("Source_ObjectOfSeparateAccountingAIT");
	ParametersOfSeparateAccountingObjectAIT.Add("NonDistributed_SeparateAccountingObjectAIT");
	ParametersOfSeparateAccountingObjectAIT.Add("DataOnExpenses_ObjectOfSeparateAccountingAIT");
	ParametersOfSeparateAccountingObjectAIT.Add("ScheduledRegisterRecords_ObjectOfSeparateAccountingOfAIT");
	ParametersOfSeparateAccountingObjectAIT.Add("Expenses_ObjectOfSeparateAccountingAIT");
	
	ListOfParametersOfSeparateAccountingObjectAIT = StrConcat(ParametersOfSeparateAccountingObjectAIT, ",");
	
	CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(QueryText, ListOfParametersOfSeparateAccountingObjectAIT);
	
	Return QueryText;
	
EndFunction

// Sets the required parameters for the textquery request for Distribution().
// Parameters:
//	Query - Query - request with text See QueryTextDataForDistribution.
//	QueryOptions - See DescriptionOfParametersForRequestingDataForDistribution.
//
Procedure InitializeRequestToGetDataForDistribution(Query, QueryOptions) Export
	
	ClosingParameters = CalculationOfCostCached.ValuesOfTechnologicalParameters();
	
	SupportedDistributionOptions = New Array;
	If QueryOptions.AllocationOption = Undefined Then
		SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCosts);
		SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
		If (GetFunctionalOption("UseAccountingByExpenseObjects")) Then
			SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToCostCenters);
		EndIf;
		SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
		SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
		If CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(QueryOptions.Period)) Then
			SupportedDistributionOptions.Add(Enums.CostAllocationOptions.ToInventoryCost);
		EndIf;
		
	ElsIf TypeOf(QueryOptions.AllocationOption) = Type("Array") Then
		
		For Each ArrayValue In QueryOptions.AllocationOption Do
			SupportedDistributionOptions.Add(ArrayValue);
		EndDo;
		
	Else
		SupportedDistributionOptions.Add(QueryOptions.AllocationOption);
	EndIf;
	
	If Not Query.Parameters.Property("BeginOfPeriod")
		Or Not ValueIsFilled(Query.Parameters.BeginOfPeriod) Then
		
		If ValueIsFilled(QueryOptions.BeginOfPeriod) Then
			Query.SetParameter("BeginOfPeriod", QueryOptions.BeginOfPeriod);
		Else
			Query.SetParameter("BeginOfPeriod", BegOfMonth(QueryOptions.Period));
		EndIf;
		
	EndIf;
	
	If Not Query.Parameters.Property("EndOfPeriod") 
		Or Not ValueIsFilled(Query.Parameters.EndOfPeriod) Then
		
		If ValueIsFilled(QueryOptions.EndOfPeriod) Then
			Query.SetParameter("EndOfPeriod", QueryOptions.EndOfPeriod);
		Else
			Query.SetParameter("EndOfPeriod", EndOfMonth(QueryOptions.Period));
		EndIf;
		
	EndIf;
	
	If Not Query.Parameters.Property("CompanyArray") 
		Or Query.Parameters.CompanyArray.Count() = 0	Then
		
		If QueryOptions.Companies.Count() = 0 Then
			Query.SetParameter("CompanyArray", Catalogs.Companies.AvailableCompanies(True));
		Else
			Query.SetParameter("CompanyArray", QueryOptions.Companies);
		EndIf;
		
	EndIf;
	
	Query.SetParameter("BorderEndOfPeriod",  
		New Boundary(Query.Parameters.EndOfPeriod, BoundaryType.Including));		
	Query.SetParameter("DepartmentList",  QueryOptions.Departments);
	Query.SetParameter("ByAllBusinessUnits", Query.Parameters.DepartmentList.Count() = 0);
	Query.SetParameter("ByAllCompanies",   Query.Parameters.CompanyArray.Count() = 0);
	Query.SetParameter("FilterByState",    QueryOptions.State);
	Query.SetParameter("ExcludeDifferencesFromControl", QueryOptions.ExcludeDifferencesFromControl);
	Query.SetParameter("ManErrorValue",  ClosingParameters.ErrorValueManCosts);
	Query.SetParameter("LocalErrorValue",  ClosingParameters.ValueOfErrorCostsRegl);
	Query.SetParameter("CostAllocationOptions", SupportedDistributionOptions);
	Query.SetParameter("AccountingByLinesOfBusiness", GetFunctionalOption("GenerateFinancialResult"));
	Query.SetParameter("UseCostAccountingByLinesOfBusiness", GetFunctionalOption("UseCostAccountingByLinesOfBusiness"));
	Query.SetParameter("UseLocal", GetFunctionalOption("UseLocal"));
	Query.SetParameter("TypesOfExpensesNormalized", Enums.ExpenseKindsTA.RationingExpenses());
	PrepareServiceTables(Query.Parameters.EndOfPeriod, 
		Query.Parameters.CompanyArray, Query, QueryOptions.ExcludeTransportationCosts);
EndProcedure

// Returns the structure of the query parameters textquery for Distribution () required for execution.
// Returns:
//	Structure - parameters for executing a request to receive distribution data:
//		* Period - Date - the date on which the Balance of expenses is required.
//		* BeginOfPeriod - Date - the beginning of the cost analysis period.
//		* EndOfPeriod - Date - end of the expense analysis period.
//		* Companies - Array of CatalogRef.Companies - organization of expenses.
//		* Departments - Array of CatalogRef.BusinessStructure - expense divisions.
//		* State - EnumRef.CostAllocationStates - selection according to the State of distribution.
//		* ExcludeDifferencesFromControl - Boolean - exclude constant and variable differences in Balances.
//		* ExcludeTransportationCosts - Boolean - exclude transportation costs.
//		* AllocationOption - Array of EnumRef.CostAllocationOptions - selection according to the distribution option.
Function DescriptionOfParametersForRequestingDataForDistribution() Export
	
	ParametersDetails = New Structure;
	ParametersDetails.Insert("Period", Date(1, 1, 1));
	ParametersDetails.Insert("BeginOfPeriod", Date(1, 1, 1));
	ParametersDetails.Insert("EndOfPeriod", Date(1, 1, 1));
	ParametersDetails.Insert("Companies", New Array); // The type of the elements is a reference link.Organizations.
	ParametersDetails.Insert("Departments", New Array); // The type of the elements is a reference link.The structure of the enterprise.
	ParametersDetails.Insert("State", Enums.CostAllocationStates.EmptyRef());
	ParametersDetails.Insert("ExcludeDifferencesFromControl", False);
	ParametersDetails.Insert("ExcludeTransportationCosts", False);
	// Can be redefined to an Array with Enumeration elements.Options for the distribution of expenses.
	ParametersDetails.Insert("AllocationOption", Undefined);
	
	Return ParametersDetails;
	
EndFunction

// Returns the distribution settings for a set of parameters.
// Parameters:
//	ExpenseParameters - Array of Structure, ValueTable - contains a structure with properties or a table with columns:
//		* Date - Date - Document date
//		* LineID - Number - ID of the line in PM
//		* Document - DocumentRef.AllocationOfOtherCosts - create document
//		* ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - item of expenditure
//		* DimensionOfExpenses - Characteristic.ExpenseItems - expense analysis items
//		* Organization - CatalogRef.Companies - the organization, in which there is a flow
//		* Department - CatalogRef.BusinessStructure - unit, in which there was a consumption
//		* LineOfBusiness - CatalogRef.LinesOfBusiness - Direction of activity
//	CompanyArray - Array of CatalogRef.Companies - array of organizations
//	RegistrationPeriod - Date - registration period
//
// Returns:
//	Array of Structure - Array of distribution parameters (the composition of the output parameters depends on the configuration):
//		* Date - Date - Document date
//		* LineID - Number - ID of the line in PM
//		* DocumentMan - DocumentRef.AllocationOfOtherCosts - the created document on Man. accounting
//		* DocumentCompl - DocumentRef.AllocationOfOtherCosts - the created document on Local accounting
//		* NalDocument - DocumentRef.AllocationOfOtherCosts - the created document on nal. accounting
//		* DocumentAIT - DocumentRef.AllocationOfOtherCosts - created document on personal data
//		* UPRStatus - String - State of distribution by management accounting
//		* ReglStatus - String - The State of distribution according to Local accounting
//		* StateOfNal - String - The State of distribution by nal. accounting
//		* NDDState - String - The State of distribution by personal income tax
//		* ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - item of expenditure
//		* DimensionOfExpenses - Characteristic.ExpenseItems - expense analysis items
//		* ProductCostElement - CatalogRef.ProductCostElements - item of expenditure
//		* LocalDistributionOption - EnumRef.CostAllocationOptions - Local accounting distribution option
//		* CashDistributionOption - EnumRef.CostAllocationOptions - the option of distribution by nal. accounting
//		* ManDistributionOption - EnumRef.CostAllocationOptions - option of distribution according to management accounting
//		* NDTDistributionOption - EnumRef.CostAllocationOptions - the option of distribution by personal income tax
//		* Organization - CatalogRef.Companies - the organization, in which there is a flow
//		* Department - CatalogRef.BusinessStructure - unit, in which there was a consumption
//		* LineOfBusiness - CatalogRef.LinesOfBusiness - Direction of activity
//		* ManDistributionRule - CatalogRef.CostAllocationRules - the rule of distribution by Man. accounting
//		* LocalDistributionRule - CatalogRef.CostAllocationRules - Local accounting distribution rule
//		* RuleOfNalDistribution - CatalogRef.CostAllocationRules - the rule of distribution by nal. accounting
//		* RuleOfDistributionOfPersonalIncomeTax - CatalogRef.CostAllocationRules - the rule of distribution by personal income tax.
Function GetCostItemAllocationSettings(ExpenseParameters, CompanyArray, RegistrationPeriod) Export

	If TypeOf(ExpenseParameters) = Type("Array") Then
		DataTable = ToConvertData(ExpenseParameters);
	Else
		DataTable = ExpenseParameters;
	EndIf;
	
	QueryTextExpenditureData = "
		|SELECT
		|	ExpenditureData.Date AS Date,
		|	ExpenditureData.LineID AS LineID,
		|	ExpenditureData.DocumentMan AS DocumentMan,
		|	ExpenditureData.DocumentCompl AS DocumentCompl,
		|	ExpenditureData.DocumentAIT AS DocumentAIT,
		|	ExpenditureData.ExpenseItem AS ExpenseItem,
		|	ExpenditureData.DimensionOfExpenses AS DimensionOfExpenses,
		|	ExpenditureData.Organization AS Organization,
		|	ExpenditureData.Department AS Department,
		|	ExpenditureData.LineOfBusiness AS LineOfBusiness,
		|	ExpenditureData.UPRStatus AS UPRStatus,
		|	ExpenditureData.ReglStatus AS ReglStatus,
		|	ExpenditureData.NDDState AS NDDState
		|INTO ExpenditureData
		|FROM
		|	&ExpenditureData AS ExpenditureData
		|";
	
	QueryTextPreliminarySettings = "
		|SELECT DISTINCT
		|	ExpenditureData.Date AS Date,
		|	ExpenditureData.LineID AS LineID,
		|	ExpenditureData.DocumentMan AS DocumentMan,
		|	ExpenditureData.DocumentCompl AS DocumentCompl,
		|	ExpenditureData.DocumentAIT AS DocumentAIT,
		|	ExpenditureData.ExpenseItem AS ExpenseItem,
		|	ExpenditureData.DimensionOfExpenses AS DimensionOfExpenses,
		|	ExpenditureData.UPRStatus AS UPRStatus,
		|	ExpenditureData.ReglStatus AS ReglStatus,
		|	ExpenditureData.NDDState AS NDDState,
		|	ArticleDetails_1.ProductCostElement AS ProductCostElement,
		|	ArticleDetails_1.CostAllocationOptionLocal AS LocalDistributionOption,
		|	ArticleDetails_1.CostAllocationOptionManag AS ManDistributionOption,
		|	ExpenditureData.Organization AS Organization,
		|	ExpenditureData.Department AS Department,
		|	ExpenditureData.LineOfBusiness AS LineOfBusiness,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsLocal, 
		|		ISNULL(OrganizationSettings.SettingsLocal, 
		|			ISNULL(SettingsByDepartment.SettingsLocal, 
		|					ArticleDetails_1.CostAllocationRuleLocal
		|	)))
		|		AS LocalDistributionRule,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsManAccounting, 
		|		ISNULL(OrganizationSettings.SettingsManAccounting,
		|			ISNULL(SettingsByDepartment.SettingsManAccounting, 
		|					ArticleDetails_1.CostAllocationRuleManag
		|	)))
		|		AS ManDistributionRule		
		|INTO PreliminarySettings
		|FROM
		|	ExpenditureData AS ExpenditureData
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleDetails_1
		|		ON ExpenditureData.ExpenseItem = ArticleDetails_1.Ref
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS OrganizationSettings
		|		ON ExpenditureData.ExpenseItem = OrganizationSettings.ExpenseItem
		|			AND ExpenditureData.Organization = OrganizationSettings.Organization
		|			AND (OrganizationSettings.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByDepartment
		|		ON ExpenditureData.ExpenseItem = SettingsByDepartment.ExpenseItem
		|			AND ExpenditureData.Department = SettingsByDepartment.Department
		|			AND (SettingsByDepartment.Organization = VALUE(Catalog.Companies.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByOrganizationAndDivision
		|		ON ExpenditureData.ExpenseItem = SettingsByOrganizationAndDivision.ExpenseItem
		|			AND ExpenditureData.Organization = SettingsByOrganizationAndDivision.Organization
		|			AND ExpenditureData.Department = SettingsByOrganizationAndDivision.Department
		|
		|UNION
		|
		|SELECT DISTINCT
		|	ExpenditureData.Date AS Date,
		|	ExpenditureData.LineID AS LineID,
		|	ExpenditureData.DocumentMan AS DocumentMan,
		|	ExpenditureData.DocumentCompl AS DocumentCompl,
		|	ExpenditureData.DocumentAIT AS DocumentAIT,
		|	ExpenditureData.ExpenseItem AS ExpenseItem,
		|	ExpenditureData.DimensionOfExpenses AS DimensionOfExpenses,
		|	ExpenditureData.UPRStatus AS UPRStatus,
		|	ExpenditureData.ReglStatus AS ReglStatus,
		|	ExpenditureData.NDDState AS NDDState,
		|	COAttributes.ProductCostElement AS ProductCostElement,
		|	COAttributes.CostAllocationOptionLocal AS LocalDistributionOption,
		|	COAttributes.CostAllocationOptionManag AS ManDistributionOption,
		|	ExpenditureData.Organization AS Organization,
		|	ExpenditureData.Department AS Department,
		|	ExpenditureData.LineOfBusiness AS LineOfBusiness,
		|	COAttributes.CostAllocationRuleLocal AS LocalDistributionRule,
		|	COAttributes.CostAllocationRuleManag AS ManDistributionRule
		|FROM
		|	ExpenditureData AS ExpenditureData
		|		INNER JOIN Catalog.CostCenters AS COAttributes
		|		ON ExpenditureData.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		AND ExpenditureData.DimensionOfExpenses = COAttributes.Ref
		|";
		
	QueryTextAITArticleDistributionSettings = CalculationOfCostLocalization.AITSettingsQueryText("ExpenditureData", "DistributionOfOtherExpenses_GetSettingsForDistributionOfItemsOfExpenses");
	
	QueryTextSettings = "
		|SELECT
		|	Settings.Date AS Date,
		|	Settings.LineID AS LineID,
		|	Settings.DocumentMan AS DocumentMan,
		|	Settings.DocumentCompl AS DocumentCompl,
		|	Settings.DocumentAIT AS DocumentAIT,
		|	Settings.ExpenseItem AS ExpenseItem,
		|	Settings.DimensionOfExpenses AS DimensionOfExpenses,
		|	Settings.UPRStatus AS UPRStatus,
		|	Settings.ReglStatus AS ReglStatus,
		|	Settings.NDDState AS NDDState,
		|	Settings.ProductCostElement AS ProductCostElement,
		|	Settings.LocalDistributionOption,
		|	Settings.ManDistributionOption,
		|	ISNULL(AITArticleDistributionSettings.AITCostAllocationOption, 
		|		ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.AITCostAllocationOption, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)))  AS NDTDistributionOption,
		|	Settings.Organization AS Organization,
		|	Settings.Department AS Department,
		|	Settings.LineOfBusiness AS LineOfBusiness,
		|	Settings.LocalDistributionRule,
		|	ISNULL(AITArticleDistributionSettings.CostAllocationRuleAIT, 
		|		ISNULL(SettingsForDistributionOfAITArticlesByCostCenter.CostAllocationRuleAIT, 
		|			VALUE(Catalog.CostAllocationRules.EmptyRef)))  AS RuleOfDistributionOfPersonalIncomeTax,
		|	Settings.ManDistributionRule
		|FROM PreliminarySettings AS Settings
		|
		|	LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|		ON Settings.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|		AND &Settings_SeparateAccountingObjectAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|		AND Settings.Organization = AITArticleDistributionSettings.Organization
		|
		|	LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS SettingsForDistributionOfAITArticlesByCostCenter
		|		ON Settings.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		AND Settings.DimensionOfExpenses = SettingsForDistributionOfAITArticlesByCostCenter.ConstCenter
		|";
	
	QueryTexts = New Array; // Array of String
	
	QueryTexts.Add(QueryTextExpenditureData);
	QueryTexts.Add(QueryTextPreliminarySettings);
	QueryTexts.Add(QueryTextAITArticleDistributionSettings);
	QueryTexts.Add(QueryTextSettings);
		
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	CalculationOfCostLocalization.SubstituteAITTypeOfSeparateAccountingObjectInRequest(QueryText, "Settings_SeparateAccountingObjectAIT");
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("ExpenditureData", DataTable);
	Query.SetParameter("Period",           RegistrationPeriod);
	Query.SetParameter("Organization",      CompanyArray);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	SettingsArray = New Array;
	While Selection.Next() Do
		
		FormatOfExpenditureItemAllocationData = FormatOfExpenditureItemAllocationData();
		FillPropertyValues(FormatOfExpenditureItemAllocationData, Selection);
		
		SettingsArray.Add(FormatOfExpenditureItemAllocationData);
		
	EndDo;
		
	Return SettingsArray;//
	
EndFunction

// Generates expense allocation documents based on the passed parameters
// and places the result of creating documents in temporary storage.
// Parameters:
//	Parameters - Structure - parameters for receiving items of expenditure:
//		* ExpenseParameters - ValueTable - Table of articles to be distributed.
//	StorageAddress - String - address in temporary storage where the result of creating documents should be placed.
// Returns:
//	Map - as the key of the document, and as the value of the structure.
Function GenerateDocuments(Parameters, StorageAddress) Export
	
	Var ExpenseParameters, CompanyArray, RegistrationPeriod;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.AllocationOfOtherCosts.ManagerModule.GenerateDocuments");
	
	Parameters.Property("ExpenseParameters", ExpenseParameters);
	Parameters.Property("CompanyArray", CompanyArray);
	Parameters.Property("RegistrationPeriod", RegistrationPeriod);
	
	ResultsOfDocumentGeneration = New Map();
	
	MessageTemplate = NStr("vi = '%6 (%7): không thể tạo chứng từ phân bổ theo %1 kế toán đối với dạng %2 có đối tượng phân tích %3 theo nguyên nhân: %4 %5.';
							|ru = '%6 (%7): не удалось создать документ распределения по %1 учету для статьи %2 с аналитикой %3 по причине: %4 %5.';
							|en = '%6 (%7): cannot generate the allocation document by %1 accounting for the item %2 with dimension %3. Reason: %4 %5.'; fa = '%6 (%7): cannot generate the allocation document by %1 accounting for the item %2 with dimension %3. Reason: %4 %5.';
							|it = '%6 (%7): non è stato possibile creare un documento di ripartizione per %1 contabilità per la voce %2 сon l''analitica %3 a causa di: %4 %5.';
							|pl = '%6 (%7): nie udało się utworzyć dokumentu dystrybucji %1 ewidencji dla pozycji %2 z analityką %3 z powodu: %4 %5.';
							|tr = '%6 (%7): %3 boyutu ile %2 kalemi için %1 muhasebesi dağıtım belgesi oluşturulamadı çünkü: %4 %5.'", Common.DefaultLanguageCode());
	
	CostItemAllocationSettings = 
		GetCostItemAllocationSettings(ExpenseParameters, CompanyArray, RegistrationPeriod);

	For Each SettingUpDistribution In CostItemAllocationSettings Do
		
		DetailingResultsOfFormation = ResultsOfDocumentGeneration.Get(SettingUpDistribution.Organization);
		If DetailingResultsOfFormation = Undefined Then
			
			DetailingResults = New Structure;
			DetailingResults.Insert("GeneratedDocuments_", 0);
			DetailingResults.Insert("UpdatedData_", New Array);
			DetailingResults.Insert("ErrorsDescription", New Array);
			
			ResultsOfDocumentGeneration.Insert(SettingUpDistribution.Organization,
				DetailingResults);
				
		EndIf;
		
		Result = GenerateDocument(SettingUpDistribution);
		
		MonthOfSetup = Title(Format(SettingUpDistribution.Date, "DF='MMMM yyyy';"));
		
		If Result.Property("LocalErrorDescription") Then
			
			MessageText = StrTemplate(
				MessageTemplate,
				NStr("vi = 'kế toán';
					|ru = 'бухгалтерскому';
					|en = 'accounting'; fa = 'accounting';
					|it = 'contabile';
					|pl = 'księgowego';
					|tr = 'genel'", Common.DefaultLanguageCode()),
				SettingUpDistribution.ExpenseItem,
				SettingUpDistribution.DimensionOfExpenses,
				Chars.LF,
				Result.LocalErrorDescription,
				SettingUpDistribution.Organization,
				MonthOfSetup);

			ErrorDescription = New Structure;
			ErrorDescription.Insert("ExpenseItem", SettingUpDistribution.ExpenseItem);
			ErrorDescription.Insert("ErrorText", MessageText);
			
			DetailingResults.ErrorsDescription.Add(ErrorDescription);
			
		Else
			DetailingResults.GeneratedDocuments_ = DetailingResults.GeneratedDocuments_ + 1;
		EndIf;
		
		If Result.Property("DescriptionOfErrorNal") Then
			
			MessageText = StrTemplate(
				MessageTemplate,
				NStr("vi = 'thuế';
					|ru = 'налоговому';
					|en = 'Tax'; fa = 'مالیات';
					|it = 'fiscale';
					|pl = 'podatkowego';
					|tr = 'vergi'", Common.DefaultLanguageCode()),
				SettingUpDistribution.ExpenseItem,
				SettingUpDistribution.DimensionOfExpenses,
				Chars.LF,
				Result.DescriptionOfErrorNal,
				SettingUpDistribution.Organization,
				MonthOfSetup);

			ErrorDescription = New Structure;
			ErrorDescription.Insert("ExpenseItem", SettingUpDistribution.ExpenseItem);
			ErrorDescription.Insert("ErrorText", MessageText);
			
			DetailingResults.ErrorsDescription.Add(ErrorDescription);
			
		Else
			DetailingResults.GeneratedDocuments_ = DetailingResults.GeneratedDocuments_ + 1;
		EndIf;
		
		If Result.Property("ManErrorDescription") Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				NStr("vi = 'quản lý';
					|ru = 'управленческому';
					|en = 'management'; fa = 'management';
					|it = 'gestionale';
					|pl = 'zarządczego';
					|tr = 'yönetim'", Common.DefaultLanguageCode()),
				SettingUpDistribution.ExpenseItem,
				SettingUpDistribution.DimensionOfExpenses,
				Chars.LF,
				Result.ManErrorDescription,
				SettingUpDistribution.Organization,
				MonthOfSetup);

			ErrorDescription = New Structure;
			ErrorDescription.Insert("ExpenseItem", SettingUpDistribution.ExpenseItem);
			ErrorDescription.Insert("ErrorText", MessageText);
			
			DetailingResults.ErrorsDescription.Add(ErrorDescription);
			
		Else
			DetailingResults.GeneratedDocuments_ = DetailingResults.GeneratedDocuments_ + 1;
		EndIf;
		
		If Result.Property("AITErrorDescription") Then
			
			MessageText = StrTemplate(
				MessageTemplate,
				NStr("vi = 'Thuế thu nhập bổ sung';
					|ru = 'НДД';
					|en = 'AIT'; fa = 'AIT';
					|it = 'НДД';
					|pl = 'AIT';
					|tr = 'EGV'", Common.DefaultLanguageCode()),
				SettingUpDistribution.ExpenseItem,
				SettingUpDistribution.DimensionOfExpenses,
				Chars.LF,
				Result.AITErrorDescription,
				SettingUpDistribution.Organization,
				MonthOfSetup);

			ErrorDescription = New Structure;
			ErrorDescription.Insert("ExpenseItem", SettingUpDistribution.ExpenseItem);
			ErrorDescription.Insert("ErrorText", MessageText);
			
			DetailingResults.ErrorsDescription.Add(ErrorDescription);
			
		Else
			DetailingResults.GeneratedDocuments_ = DetailingResults.GeneratedDocuments_ + 1;
		EndIf;
		
		NewValues = New Structure("ExpenseItem, DimensionOfExpenses, Organization, Department, LineOfBusiness, LineID");
		FillPropertyValues(NewValues, SettingUpDistribution);
		
		For Each KeyAndValue In Result Do
			NewValues.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
		
		DetailingResults.UpdatedData_.Add(NewValues);
		
	EndDo;
		
	If Not StorageAddress = Undefined Then
		PutToTempStorage(ResultsOfDocumentGeneration, StorageAddress);
	EndIf;
	
	GeneratedDocuments_ = 0;
	For Each OrganizationResults In ResultsOfDocumentGeneration Do
		GeneratedDocuments_ = GeneratedDocuments_ + OrganizationResults.Value.GeneratedDocuments_;
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, GeneratedDocuments_);
	
	Return ResultsOfDocumentGeneration;
	
EndFunction

// Returns a list of the units in the direction of the distribution.
// Parameters:
//	Department - CatalogRef.BusinessStructure - the division from which you want to get divisions in the distribution direction.
//	AllocationDirection - EnumRef.AllocationDirectionByBusinessUnits - the distribution direction.
// Returns:
//	Array - divisions by direction.
//
Function DivisionsByDirection(Department, AllocationDirection) Export
	
	If Not ValueIsFilled(AllocationDirection) Then
		Return New Array;
	EndIf;
	
	If AllocationDirection = Enums.AllocationDirectionByBusinessUnits.CurrentBusinessUnit Then
		
		ArrayOfDivisions = New Array;
		ArrayOfDivisions.Add(Department);
		
		Return ArrayOfDivisions;
		
	EndIf;
		
	If AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Superior Then
		
		QueryText = 
			"SELECT
			|	BusinessStructure.Parent AS Department
			|FROM
			|	Catalog.BusinessStructure AS BusinessStructure
			|WHERE
			|	BusinessStructure.Ref = &Department";
		
		
	ElsIf AllocationDirection = Enums.AllocationDirectionByBusinessUnits.Subordinate Then
	
		QueryText = 
			"SELECT
			|	BusinessStructure.Ref AS Department
			|FROM
			|	Catalog.BusinessStructure AS BusinessStructure
			|WHERE
			|	BusinessStructure.Ref IN HIERARCHY(&Department)
			|	AND BusinessStructure.Ref <> &Department";
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Department", Department);
	
	ArrayOfDivisions = New Array;
	SuitableDivisions = Query.Execute().Select();
	While SuitableDivisions.Next() Do
		ArrayOfDivisions.Add(SuitableDivisions.Department);
	EndDo;
	
	Return ArrayOfDivisions;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//	See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.DataPath           = "Object.WriteOff";
	SetupParameters.ArticleType             = "ArticleType";
	
	SetupParameters.FormItems.Add("WriteOffTransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction
// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export 
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.WriteOff";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.DimensionOfExpenses 		 = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	OptionsArray.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	OptionsArray.Add(Enums.CostAllocationOptions.ToInventoryCost);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostOfGoodsSold);
	OptionsArray.Add(Enums.CostAllocationOptions.OnOtherAssets);
	OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
	
	ChoiceParameters.SelectionOfExpenditureItems.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = OptionsArray;
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	
	ChoiceParameters.FormItems.AssetRef.Add("WriteOffExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("WriteOffDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("WriteOffAssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

// Sets the availability of document usage flags for accounting types, depending on the settings of the expense item
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the object of the document "Cost allocation"
//
Procedure SetAvailabilityOfAccountingTypes(Form) Export
	
	Items = Form.Items;
	Object = Form.Object;
	
	AITAccounting = CalculationOfCostLocalization.GetFunctionalOptionAITAccounting();
	
	Items.ManagementAccounting.Enabled = True;
	Items.LocalAccounting.Enabled = True;
	DistributionSettings = GetDistributionSettingsForDocument(Object);
	
	If Object.ManagementAccounting Then
		Items.LocalAccounting.Enabled = Object.LocalAccounting
			Or DistributionSettings.CostAllocationOptionManag = DistributionSettings.CostAllocationOptionLocal;
		
		
		Items.AIT.Enabled = AITAccounting And (Object.AIT
			Or DistributionSettings.AITCostAllocationOption = DistributionSettings.CostAllocationOptionManag);
	ElsIf Object.LocalAccounting Then
		Items.ManagementAccounting.Enabled =
			DistributionSettings.CostAllocationOptionManag = DistributionSettings.CostAllocationOptionLocal;
	EndIf;
	
EndProcedure

// Sets or removes the sign of reflection in the BU, depending on the sign of WELL and the settings of the expense item and vice versa.// 
// Parameters:
//  Form - ClientApplicationForm - the form of the object of the document "Cost allocation"
//  AccountingKind - String - the name of the type of accounting for which the user has set or removed the feature of reflection in the document.
//
Procedure SynchronizeTypesOfAccountingBUAndTa(Form, AccountingKind) Export
	
	If AccountingKind = "ManagementAccounting" Then
		Return;
	EndIf;
	
	Object = Form.Object;
	SetSignsOfBUITa(Object, AccountingKind);
	
EndProcedure

#Region StandardSubsystems

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	AllocationOfOtherCostsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Distribution of expenses for the cost of production".
//
// Parameters:
//  GenerationCommands - ValueTable - The description in the creation of the base is undefined.Before adding a command to create a base.Teamsreferences
// Returns:
// 	ValueTableRow - The description in the creation of the base is undefined.Before adding a command to create a base.Teamsreferences 
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.AllocationOfOtherCosts) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AllocationOfOtherCosts.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AllocationOfOtherCosts);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProduction,UseAccountingOfOtherIncomeExpenses";
	
		Return CreateBasedOnCommand;
		
	EndIf;

	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Reports.ProductionCostsAllocationBase.AddReportCommand(ReportsCommands);
	AllocationOfOtherCostsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	AllocationOfOtherCostsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion
#Region LocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//   String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return AllocationOfOtherCostsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - The text of the temporary table query.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return AllocationOfOtherCostsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Not FormType = "ObjectForm" Then
		Return;
	EndIf;
	
	InFrench = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult"); 
	InFrenchWithoutDistribution = PredefinedValue("Enum.AssignmentOfCostAllocationRules.WithoutExpenseAllocation");
	ToBatches = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots");
	OnOvz = PredefinedValue("Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter");
	ToProduction = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost");
	AtCostPrice = PredefinedValue("Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts");
	
	DestinationForms = New Map;
	DestinationForms.Insert(InFrench, "FormOfSettingsForFR");
	DestinationForms.Insert(InFrenchWithoutDistribution, "FormOfSettingsForFR");
	DestinationForms.Insert(ToBatches, "SettingsFormToLots");
	DestinationForms.Insert(OnOvz, "SettingsFormOfCostCenters");
	DestinationForms.Insert(ToProduction, "SettingsFormToProductionDirect");
	DestinationForms.Insert(AtCostPrice, "SettingsFormToInventoryCost");
	
	If Parameters.Property("Key") Then
		
		SelectedForm = DestinationForms.Get(
			GeneralPurposeTMServerCall.ObjectAttributeValue(
				Parameters.Key, 
				"AssignAllocationSetting"));
				
	ElsIf Parameters.Property("Basis") Then
		
		AssignmentsByOption = New Map;
		AssignmentsByOption.Insert(
			PredefinedValue("Enum.CostAllocationOptions.ToLinesOfBusiness"),
			InFrench);
		AssignmentsByOption.Insert(
			PredefinedValue("Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly"),
			InFrenchWithoutDistribution);
		AssignmentsByOption.Insert(
			PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts"),
			ToBatches);
		AssignmentsByOption.Insert(
			PredefinedValue("Enum.CostAllocationOptions.ToCostCenters"),
			OnOvz);
		AssignmentsByOption.Insert(
			PredefinedValue("Enum.CostAllocationOptions.ToProductionCostDirect"),
			ToProduction);
		AssignmentsByOption.Insert(
			PredefinedValue("Enum.CostAllocationOptions.ToInventoryCost"),
			AtCostPrice);
			

		If Parameters.Basis.ManagementAccounting Then
			SelectedForm = DestinationForms.Get(AssignmentsByOption.Get(Parameters.Basis.ManDistributionOption));
		EndIf;
		
		If Parameters.Basis.LocalAccounting Then
			SelectedForm = DestinationForms.Get(AssignmentsByOption.Get(Parameters.Basis.LocalDistributionOption));
		EndIf;
		
		If Parameters.Basis.AIT Then
			SelectedForm = DestinationForms.Get(AssignmentsByOption.Get(Parameters.Basis.NDTDistributionOption));
		EndIf;
		
	ElsIf Parameters.Property("FillingValues")
		And Parameters.FillingValues.Property("AssignAllocationSetting") Then
		SelectedForm = DestinationForms.Get(Parameters.FillingValues.AssignAllocationSetting);
	EndIf;
	
	If ValueIsFilled(SelectedForm) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Internal

#Region HandlersForMonthClosingStages

#Region RegistrationOfCostAllocationDocuments

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
//	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
//	CurrentParent - String - group ID.
Procedure AddStage_RegistrationOfCostAllocationDocuments(StepsTable, CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.RegistrationOfCostAllocationDocuments);
	
	NewRow.MultilingualName = "vi = 'Lập chứng từ phân bổ chi phí';
								|ru = 'Оформление документов распределения расходов';
								|en = 'Generate expense allocation documents';
								|it = 'Formalizzazione dei documenti dell''allocazione delle spese';
								|pl = 'Sporządzenie dokumentów podziału rozchodów';
								|tr = 'Giderlerin dağıtımına ilişkin belgelerin düzenlenmesi'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Tạo';
								|ru = 'Оформить';
								|en = 'Register'; fa = 'ثبات';
								|it = 'Preparare';
								|pl = 'Register';
								|tr = 'Düzenle'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.AllocationOfOtherCosts.Use_ExecutionOfDocumentsForDistributionOfExpensesByAreasOfActivity");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.AllocationOfOtherCosts.Perform_ExecutionOfDocumentsForDistributionOfExpensesInAreasOfActivity");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AllocationOfOtherCosts.Forms.WorkplaceForm.FullName());
	NewRow.ActionMoreDetails.FormParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	NewRow.ActionMoreDetails.FormParameters.Insert("State", Enums.CostAllocationStates.DocumentGenerationIsRequired);
		
EndProcedure

// Stage handlers.

Procedure Use_ExecutionOfDocumentsForDistributionOfExpensesByAreasOfActivity(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	QueryOptions = DescriptionOfParametersForRequestingDataForDistribution();
	QueryOptions.State = Enums.CostAllocationStates.DocumentGenerationIsRequired;
	DistributionOptions = New Array;
	DistributionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	DistributionOptions.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	QueryOptions.AllocationOption = DistributionOptions;
	Documents.AllocationOfOtherCosts.InitializeRequestToGetDataForDistribution(Query, QueryOptions);
	
	Query.Text = QueryTextDataForDistribution(, True);
	Query.Execute();	
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	// The "Not required" status has already been set for the stage, so we do not perform a status check.
	If HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		Return;
	EndIf;
	
	If TemporaryTableSizes.TTDataForDistribution = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	If TemporaryTableSizes.StateOfCostAllocation = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Cài đặt phân bổ tất cả các chi phí được thiết lập.';
				|ru = 'По всем расходам заданы настройки распределения.';
				|en = 'Allocation settings are set up for all expenses.'; fa = 'Allocation settings are set up for all expenses.';
				|it = 'Le impostazioni di distribuzione sono impostate per tutte le spese.';
				|pl = 'Ustawienia dystrybucji są ustawione dla wszystkich wydatków.';
				|tr = 'Tüm giderler için dağıtım ayarları yapıldı.'", Common.DefaultLanguageCode()));
	Else
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			NStr("vi = 'Yêu cầu lập chứng từ phân bổ chi phí.';
				|ru = 'Требуется оформление документов распределения расходов.';
				|en = 'Generation of expense allocation documents is required.'; fa = 'Generation of expense allocation documents is required.';
				|it = 'È richiesta l''emissione di documenti di allocazione delle spese.';
				|pl = 'Jest wymagane sporządzenie dokumentów podziału rozchodów';
				|tr = 'Giderlerin dağılımına ilişkin belgelerin düzenlenmesi gerekmektedir.'"));	
	EndIf;
	
EndProcedure

Procedure Perform_ExecutionOfDocumentsForDistributionOfExpensesInAreasOfActivity(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	DistributionOptions = New Array;
	DistributionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	DistributionOptions.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	
	ArticlesForDistribution = ArticlesForDistribution(
		CalculationParameters.RegistrationPeriod,
		CalculationParameters.CompanyArray,
		New Array,
		Enums.CostAllocationStates.DocumentGenerationIsRequired,
		DistributionOptions);
		
	RowsCount = ArticlesForDistribution.Count();
	If RowsCount = 0 Then // there is no data for distribution
		Return;
	EndIf;
	
	ArticlesForDistribution.Columns.Add("Date", New TypeDescription("Date"));
	ArticlesForDistribution.Columns.Add("LineID", New TypeDescription("Number"));
	ArticlesForDistribution.FillValues(EndOfMonth(CalculationParameters.RegistrationPeriod), "Date");
	
	NumberOfFederalLaws = CalculationOfCostCached.ValuesOfTechnologicalParameters(Catalogs.MonthEndClosingOperations.EmptyRef()).MaximumNumberOfFederalLawsForFormationOfDocuments;
	LinesOfVFZ = Int(RowsCount / ?(NumberOfFederalLaws = 0, 1, NumberOfFederalLaws));
	
	If NumberOfFederalLaws < 2 Or LinesOfVFZ < 1 Then
		
		// Single-threaded document generation, without background tasks.
		AllocationOfOtherCostsLocalization.FormationOfDocumentsAndDistributionOfOtherCosts(HandlerParameters, ArticlesForDistribution);
		
		Return;
		
	EndIf;
	
	ProcessedRows_ = 0;
	ArrayOfTasks   = New Array;
	ItemsTable   = Undefined;
	
	// Multithreaded document generation.
	While ProcessedRows_ <= RowsCount Do
		
		If ProcessedRows_ = 0 Or ProcessedRows_ = RowsCount
		 // The task is started when the tables are filled with the number of rows equal to the number of rows.
		 // All remaining lines are placed in the last task, even if there are more of them than the lines in the table.
		 Or (Int(ProcessedRows_/LinesOfVFZ) = ProcessedRows_/LinesOfVFZ And ArrayOfTasks.Count() < NumberOfFederalLaws-1) Then
			
			If ProcessedRows_ > 0 Then
				
				// We are launching a new Federal law
				ParametersArray = New Array;                                                                      
				ParametersArray.Add(HandlerParameters);
				ParametersArray.Add(ItemsTable);
				
				JobKey = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nhiệm vụ nền số %1 - %2 (%3)';
						|ru = 'ФЗ №%1 - %2 (%3)';
						|en = 'FZ No.%1 - %2 (%3)'; fa = 'FZ No.%1 - %2 (%3)';
						|it = 'ФЗ №%1 - %2 (%3)';
						|pl = 'UF nr%1 - %2 (%3)';
						|tr = 'FZ №%1 - %2 (%3)'", Common.DefaultLanguageCode()),
					TrimAll(ArrayOfTasks.Count() + 1),
					TrimAll(HandlerParameters.Data_Stage.Code),
					TrimAll(HandlerParameters.CalculationID));
				
				Job = MonthEndTransactionsServer.StartSubordinateBackgroundTaskOfCalculationStage(
					HandlerParameters.CalculationID,
					"AllocationOfOtherCostsLocalization.FormationOfDocumentsAndDistributionOfOtherCosts",
					ParametersArray,
					JobKey,
					NStr("vi = 'Tạo hàng loạt chứng từ';
						|ru = 'Пакетное формирование документов';
						|en = 'Package document generation'; fa = 'Package document generation';
						|it = 'Пакетное формирование документов';
						|pl = 'Tworzenie pakietów dokumentów';
						|tr = 'Toplu belge oluşturma'"));
					
		        ArrayOfTasks.Add(Job);
				
			EndIf;
			
			If ProcessedRows_ = RowsCount Then
				// All tasks are running
				Break;
			EndIf;
			
			ItemsTable = ArticlesForDistribution.CopyColumns();
			
		EndIf;
		
		FillPropertyValues(ItemsTable.Add(), ArticlesForDistribution[ProcessedRows_]);
		
		ProcessedRows_ = ProcessedRows_ + 1;
		
	EndDo;
	
	TasksAreCompleted = False;;
	
	While Not TasksAreCompleted Do
		
		Tasks_Completed = BackgroundJobs.WaitForExecutionCompletion(ArrayOfTasks);
		
		ArrayOfTasks = New Array;
		
		For Each Job In Tasks_Completed Do
			
			If Job.State = BackgroundJobState.Active Then
				
				ArrayOfTasks.Add(Job);
				
			ElsIf Job.State <> BackgroundJobState.Completed Then

				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nhiệm vụ nền tạo chứng từ %1
					|%2';
					|ru = 'Фоновое задание формирования документов %1
					|%2';
					|en = 'Background job of creating documents: %1
					|%2'; fa = 'Background job of creating documents: %1
					|%2';
					|it = 'Фоновое задание формирования документов %1
					|%2';
					|pl = 'Background job of creating documents: %1
					|%2';
					|tr = 'Arka plan belgesi oluşturma işi %1
					|%2'", Common.DefaultLanguageCode()),
					?(Job.State = BackgroundJobState.Canceled,
						NStr("vi = 'đã hủy';
							|ru = 'отменено';
							|en = 'canceled'; fa = 'canceled';
							|it = 'отменено';
							|pl = 'anulowano';
							|tr = 'iptal edildi'", Common.DefaultLanguageCode()),
						NStr("vi = 'kết thúc bất thường';
							|ru = 'завершено аварийно';
							|en = 'aborted'; fa = 'aborted';
							|it = 'завершено аварийно';
							|pl = 'zakończone awaryjnie';
							|tr = 'arızalı tamamlandı'", Common.DefaultLanguageCode())),
					?(Job.ErrorInfo = Undefined,
						NStr("vi = '<Không có mô tả lỗi>';
							|ru = '<Нет описания ошибки>';
							|en = '<No error description>'; fa = '<No error description>';
							|it = '<Нет описания ошибки>';
							|pl = '<Brak opisu błędu>';
							|tr = '<Hata ayrıntıları mevcut değil>'", Common.DefaultLanguageCode()),
						DetailErrorDescription(Job.ErrorInfo)));
						
				MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
					HandlerParameters,
					ErrorText);
				
			EndIf;
			
		EndDo;
		
		TasksAreCompleted = (ArrayOfTasks.Count() = 0);
		
	EndDo;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfInspections_RegistrationOfDocumentsForDistributionOfExpensesByAreasOfActivity(TableOfChecks) Export
	
	// Setting up cost allocation.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"PaperworkForDistributionOfExpensesInAreasOfActivityHasNotBeenCompleted",
		Catalogs.MonthEndClosingOperations.RegistrationOfCostAllocationDocuments,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation,
		"Documents.AllocationOfOtherCosts.VerificationOfNeedForPaperworkForDistributionOfExpensesInAreasOfActivity");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Có những chứng từ chưa được định dạng để phân bổ chi phí';
			|ru = 'Есть неоформленные документы распределения расходов';
			|en = 'There are unregistered expense allocation documents'; fa = 'There are unregistered expense allocation documents';
			|it = 'Ci sono documenti di allocazione delle spese non ufficiali.';
			|pl = 'Istnieją nieoficjalne dokumenty dotyczące dystrybucji wydatków';
			|tr = 'Gider dağıtımının düzenlenmediği belgeler mevcut'", Common.DefaultLanguageCode()),
		NStr("vi = 'Tất cả các chi phí sản xuất nên được phân bổ cho các lĩnh vực hoạt động.';
			|ru = 'Все производственные расходы должны быть распределены по направлениям деятельности.';
			|en = 'All production costs must be allocated by lines of business.'; fa = 'All production costs must be allocated by lines of business.';
			|it = 'Tutti i costi di produzione devono essere interamente allocati sui settori di attività';
			|pl = 'Wszystkie koszty produkcji powinny być rozdzielane według kierunków działalności.';
			|tr = 'Tüm üretim giderleri, iş koluna göre dağıtılmalıdır.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure VerificationOfNeedForPaperworkForDistributionOfExpensesInAreasOfActivity(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Firma';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department", 			NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
										|ru = 'Направление деятельности';
										|en = 'Line of business'; fa = 'خط کسب‌وکار';
										|it = 'Settore di attività';
										|pl = 'Rodzaj działalności';
										|tr = 'İş kolu'", Common.DefaultLanguageCode()));
	FieldList.Add("ExpenseItem", 			NStr("vi = 'Dạng chi phí';
													|ru = 'Статья расходов';
													|en = 'Expense item'; fa = 'قلم هزینه';
													|it = 'Voce di spese';
													|pl = 'Rodzaj kosztu';
													|tr = 'Gider kalemi'", Common.DefaultLanguageCode()));
	FieldList.Add("DimensionOfExpenses", 		NStr("vi = 'Chỉ số chi phí';
														|ru = 'Аналитика расходов';
														|en = 'Expense dimension'; fa = 'بُعد هزینه';
														|it = 'Analitica delle uscite';
														|pl = 'Analityka kosztów';
														|tr = 'Gider boyutu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"StateOfCostAllocation",
		NStr("vi = 'Có các chứng từ chưa được định dạng để phân bổ chi phí cho doanh nghiệp ""%1"" vào cuối giai đoạn %2';
			|ru = 'Есть неоформленные документы распределения расходов по организации ""%1"" на конец периода %2';
			|en = 'There are unregistered expense allocation documents for the company ""%1"" at the end of the period %2'; fa = 'There are unregistered expense allocation documents for the company ""%1"" at the end of the period %2';
			|it = 'Esistono documenti non ufficiali sulla distribuzione delle spese per aziende ""%1"" alla fine del periodo %2';
			|pl = 'Istnieją niewypełnione dokumenty podziału rozchodów wg firmy ""%1"" na koniec okresu %2';
			|tr = '%2 döneminin sonuna kadar ""%1"" iş yerine göre gider dağıtımının düzenlenmediği belgeler mevcut'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
		
EndProcedure

#EndRegion

#Region AllocationOfExpensesByLinesOfBusiness

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
//
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_AllocationOfExpensesByLinesOfBusiness(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.AllocationOfExpensesByLinesOfBusiness);
		
	NewRow.MultilingualName = "vi = 'Phân bổ chi phí theo lĩnh vực hoạt động';
								|ru = 'Распределение расходов по направлениям деятельности';
								|en = 'Allocation of expenses by lines of business';
								|it = 'Ripartizione delle spese e delle nei settori di attività';
								|pl = 'Podział wydatków według kierunków działalności';
								|tr = 'Giderlerin iş kollarına göre dağıtımı'"; // @NStr-1
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.VATAllocation);
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.RegistrationOfCostAllocationDocuments);
	NewRow.TextExecute = NStr("vi = 'Phân bổ';
								|ru = 'Распределить';
								|en = 'Allocate'; fa = 'تسهیم';
								|it = 'Ripartire';
								|pl = 'Allocate';
								|tr = 'Dağıt'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"Documents.AllocationOfOtherCosts.Use_DistributionOfExpensesByAreasOfActivity");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"Documents.AllocationOfOtherCosts.Perform_DistributionOfExpensesByAreasOfActivity");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AllocationOfOtherCosts.Forms.WorkplaceForm.FullName());
		
EndProcedure

// Stage handlers.

Procedure Use_DistributionOfExpensesByAreasOfActivity(HandlerParameters) Export
	
	If HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		Return;
	EndIf;

	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	QueryOptions = DescriptionOfParametersForRequestingDataForDistribution();  
	DistributionOptions = New Array;
	DistributionOptions.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	DistributionOptions.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	QueryOptions.AllocationOption = DistributionOptions;
	
	InitializeRequestToGetDataForDistribution(Query, QueryOptions);
	
	Query.Text = QueryTextDataForDistribution();
	Result = Query.Execute();	
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTDataForDistribution = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có dữ liệu để phân bổ chi phí.';
				|ru = 'Нет данных для распределения расходов.';
				|en = 'No data for expense allocation.'; fa = 'No data for expense allocation.';
				|it = 'Non ci sono dati per l''allocazione delle spese.';
				|pl = 'Brak danych do przydziału rozchodów.';
				|tr = 'Gider dağıtımı için veri yoktur.'", Common.DefaultLanguageCode()));
		
		Return;
		
	EndIf;
	
	Query.Text =
		"SELECT
		|	*
		|INTO TTBalancesOfOtherExpensesPreliminary
		|FROM
		|	TTDataForDistribution AS T
		|WHERE
		|	NOT T.DistributedByVUU
		|		AND (T.DocumentMan.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
		|			OR T.DocumentMan.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.WithoutExpenseAllocation))

		|	OR NOT T.DistributedByWBU
		|		AND (T.DocumentCompl.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
		|			OR T.DocumentCompl.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.WithoutExpenseAllocation))
		//		Additional check of the State of distribution for normalized expenses, including transportation
		|		AND NOT T.BUState IN (
		|			VALUE(Enum.CostAllocationStates.Allocated), 
		|			VALUE(Enum.CostAllocationStates.NotAllocated), 
		|			VALUE(Enum.CostAllocationStates.NotRequired)
		|		)
		|;	
		|SELECT
		|	*
		|INTO TTBalancesOfOtherHIAExpenses
		|FROM
		|	TTBalancesOfOtherExpensesPreliminary AS T
		|WHERE
		|	T.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|;	
		|SELECT
		|	*
		|INTO TTBalancesOfOtherExpenses
		|FROM
		|	TTBalancesOfOtherExpensesPreliminary AS T
		|WHERE
		|	T.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|;	
		|SELECT TOP 1
		|	*
		|FROM
		|	TTBalancesOfOtherExpensesPreliminary";
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Yêu cầu tính toán lại cho giai đoạn %1';
					|ru = 'Требуется пересчет за период %1.';
					|en = 'Recalculation for period %1 is required.'; fa = 'Recalculation for period %1 is required.';
					|it = 'È necessario un ricalcolo per il periodo %1.';
					|pl = 'Potrzebne jest przeliczenie za okres %1.';
					|tr = '%1 dönemi için yeniden hesaplama gerekmektedir.'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod)));
			
	EndIf;
			
EndProcedure

Procedure Perform_DistributionOfExpensesByAreasOfActivity(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	BeginOfPeriod = BegOfMonth(CalculationParameters.RegistrationPeriod);
	EndOfPeriod  = EndOfMonth(CalculationParameters.RegistrationPeriod);
	
	TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
	
	Try
		CalculatedOrganizations = AllocateExpensesToFinancialResult(HandlerParameters);
	Except
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Việc phân bổ chi phí cho các mảng hoạt động trong kỳ %1 đã kết thúc bị lỗi
					|%2';
					|ru = 'Распределение расходов по направлениям деятельности за период %1 завершилось с ошибкой:
					|%2';
					|en = 'Expense allocation by lines of business for the period %1 ended with the error:
					|%2'; fa = 'Expense allocation by lines of business for the period %1 ended with the error:
					|%2';
					|it = 'L''allocazione delle entrate e delle spese sulla direzione delle attività per il periodo %1 si è conclusa con l''errore:
					|%2';
					|pl = 'Podział rozchodów wg kierunków działalności za okres %1 jest zakończony z błędem:
					|%2';
					|tr = '%1 dönemi için giderlerin iş koluna göre dağıtımı hatayla sona erdi:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(HandlerParameters.CalculationParameters.RegistrationPeriod),
				DetailErrorDescription(ErrorInfo()));
			
		MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText);
				
	EndTry;
	
	
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfInspections_DistributionOfExpensesByAreasOfActivity(TableOfChecks) Export
	
	// Setting up cost allocation.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"CheckingBalancesOfOtherExpenses",
		Catalogs.MonthEndClosingOperations.AllocationOfExpensesByLinesOfBusiness,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation,
		"Documents.AllocationOfOtherCosts.CheckingBalancesOfOtherExpenses");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chi phí không phân bổ khác trên kết quả kinh doanh';
			|ru = 'Не распределены прочие расходы на финансовый результат';
			|en = 'Other expenses for the financial results are not allocated'; fa = 'Other expenses for the financial results are not allocated';
			|it = 'Le altre entrate e spese non sono state allocate sul risultato finanziario';
			|pl = 'Nie są podzielone inne rozchody do wyniku finansowego';
			|tr = 'Diğer giderler, karlılık ve maliyete dağıtılmadı'", Common.DefaultLanguageCode()),
		NStr("vi = 'Tất cả các chi phí khác nên được phân bổ cho kết quả kinh doanh.';
			|ru = 'Все прочие расходы должны быть распределены на финансовый результат.';
			|en = 'All other expenses must be allocated for the financial result.'; fa = 'All other expenses must be allocated for the financial result.';
			|it = 'Tutte le altre entrate e spese devono essere allocate sul risultato finanziario.';
			|pl = 'Wszystkie inne rozchody powinny być podzielone do wyniku finansowego.';
			|tr = 'Tüm diğer giderler, karlılık ve maliyete dağıtılmalıdır.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure CheckingBalancesOfOtherExpenses(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Firma';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department", 			NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
										|ru = 'Направление деятельности';
										|en = 'Line of business'; fa = 'خط کسب‌وکار';
										|it = 'Settore di attività';
										|pl = 'Rodzaj działalności';
										|tr = 'İş kolu'", Common.DefaultLanguageCode()));
	FieldList.Add("ExpenseItem", 			NStr("vi = 'Dạng chi phí';
													|ru = 'Статья расходов';
													|en = 'Expense item'; fa = 'قلم هزینه';
													|it = 'Voce di spese';
													|pl = 'Rodzaj kosztu';
													|tr = 'Gider kalemi'", Common.DefaultLanguageCode()));
	FieldList.Add("DimensionOfExpenses", 		NStr("vi = 'Chỉ số chi phí';
														|ru = 'Аналитика расходов';
														|en = 'Expense dimension'; fa = 'بُعد هزینه';
														|it = 'Analitica delle uscite';
														|pl = 'Analityka kosztów';
														|tr = 'Gider boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("SumBalance", 			NStr("vi = 'Số dư gồm thuế GTGT';
												|ru = 'Остаток с НДС';
												|en = 'Balance including VAT'; fa = 'Balance including VAT';
												|it = 'Balance including VAT';
												|pl = 'Balance including VAT';
												|tr = 'KDV''li bakiye'", Common.DefaultLanguageCode()));
	FieldList.Add("AmountExcludingVATBalance", 		NStr("vi = 'Số dư không gồm thuế GTGT';
															|ru = 'Остаток без НДС';
															|en = 'Balance excluding VAT'; fa = 'Balance excluding VAT';
															|it = 'Balance excluding VAT';
															|pl = 'Balance excluding VAT';
															|tr = 'KDV''siz bakiye'", Common.DefaultLanguageCode()));
	FieldList.Add("SumComplBalance", 		NStr("vi = 'Số dư tài chính';
													|ru = 'Остаток регл';
													|en = 'Balance local'; fa = 'Balance local';
													|it = 'Balance local';
													|pl = 'Balance local';
													|tr = 'Yerel bakiye'", Common.DefaultLanguageCode()));
	FieldList.Add("AmountFABalance", 			NStr("vi = 'Số dư KTTh';
														|ru = 'Остаток НУ';
														|en = 'TA balance'; fa = 'TA balance';
														|it = 'TA balance';
														|pl = 'TA balance';
														|tr = 'Vergi bakiyesi'", Common.DefaultLanguageCode()));
	FieldList.Add("SumManBalance", 		NStr("vi = 'Số dư quản trị';
												|ru = 'Остаток упр';
												|en = 'Balance mgmt'; fa = 'Balance mgmt';
												|it = 'Balance mgmt';
												|pl = 'Balance mgmt';
												|tr = 'Yönetim bakiyesi'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTBalancesOfOtherExpenses",
		NStr("vi = 'Theo doanh nghiệp ""%1"" vào cuối giai đoạn %2, có số dư trong biểu ghi các chi phí khác.';
			|ru = 'По организации ""%1"" на конец периода %2 есть остатки в регистре прочих расходов по статьям.';
			|en = 'There is balance in the register of other item expenses for the ""%1"" company as of the end of period %2.'; fa = 'There is balance in the register of other item expenses for the ""%1"" company as of the end of period %2.';
			|it = 'По организации ""%1"" на конец периода %2 есть остатки в регистре прочих расходов по статьям.';
			|pl = 'There is balance in the register of other item expenses for the ""%1"" company as of the end of period %2.';
			|tr = '""%1"" iş yerinde, %2 döneminin sonunda kaleme göre diğer giderlerin kaydında bakiyeler bulunmaktadır.'", Common.DefaultLanguageCode()),
		FieldList,
		,
		Metadata.AccumulationRegisters.OtherExpenses.FullName());
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Firma';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department", 			NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("DimensionOfExpenses", 		NStr("vi = 'Chỉ số chi phí';
														|ru = 'Аналитика расходов';
														|en = 'Expense dimension'; fa = 'بُعد هزینه';
														|it = 'Analitica delle uscite';
														|pl = 'Analityka kosztów';
														|tr = 'Gider boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("SumBalance", 			NStr("vi = 'Số dư gồm thuế GTGT';
												|ru = 'Остаток с НДС';
												|en = 'Balance including VAT'; fa = 'Balance including VAT';
												|it = 'Balance including VAT';
												|pl = 'Balance including VAT';
												|tr = 'KDV''li bakiye'", Common.DefaultLanguageCode()));
	FieldList.Add("AmountExcludingVATBalance", 		NStr("vi = 'Số dư không gồm thuế GTGT';
															|ru = 'Остаток без НДС';
															|en = 'Balance excluding VAT'; fa = 'Balance excluding VAT';
															|it = 'Balance excluding VAT';
															|pl = 'Balance excluding VAT';
															|tr = 'KDV''siz bakiye'", Common.DefaultLanguageCode()));
	FieldList.Add("SumComplBalance", 		NStr("vi = 'Số dư tài chính';
													|ru = 'Остаток регл';
													|en = 'Balance local'; fa = 'Balance local';
													|it = 'Balance local';
													|pl = 'Balance local';
													|tr = 'Yerel bakiye'", Common.DefaultLanguageCode()));
	FieldList.Add("AmountFABalance", 			NStr("vi = 'Số dư KTTh';
														|ru = 'Остаток НУ';
														|en = 'TA balance'; fa = 'TA balance';
														|it = 'TA balance';
														|pl = 'TA balance';
														|tr = 'Vergi bakiyesi'", Common.DefaultLanguageCode()));
	FieldList.Add("SumManBalance", 		NStr("vi = 'Số dư quản trị';
												|ru = 'Остаток упр';
												|en = 'Balance mgmt'; fa = 'Balance mgmt';
												|it = 'Balance mgmt';
												|pl = 'Balance mgmt';
												|tr = 'Yönetim bakiyesi'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTBalancesOfOtherHIAExpenses",
		NStr("vi = 'Theo doanh nghiệp ""%1"" vào cuối giai đoạn %2, có số dư trong biểu ghi các chi phí khác về SXDD.';
			|ru = 'По организации ""%1"" на конец периода %2 есть остатки в регистре прочих расходов по ОВЗ.';
			|en = 'There is balance in the register of other cost center expenses for the ""%1"" company as of the end of period %2.'; fa = 'There is balance in the register of other cost center expenses for the ""%1"" company as of the end of period %2.';
			|it = 'По организации ""%1"" на конец периода %2 есть остатки в регистре прочих расходов по ОВЗ.';
			|pl = 'There is balance in the register of other cost center expenses for the ""%1"" company as of the end of period %2.';
			|tr = '""%1"" iş yeri için %2 döneminin sonunda gider oluşum nesnesine ilişkin diğer giderler kayıtlarında bakiyeler bulunmaktadır.'", Common.DefaultLanguageCode()),
		FieldList,
		,
		Metadata.AccumulationRegisters.OtherExpenses.FullName());
	
	MonthEndTransactionsServer.RegisterValidationIssues(
	 	CheckParameters,
		RegistrationParameters);
EndProcedure

#EndRegion

#EndRegion

Procedure AddDefaultParametersToDistributionOfExpensesForProfitabilityAndCost(Parameters) Export
	
	Parameters.Insert("PeriodBoundary", New Boundary(Parameters.EndOfPeriod, BoundaryType.Including));
	If TypeOf(Parameters.CompanyArray) = Type("Array") Then
		Parameters.Insert("ByAllCompanies", Parameters.CompanyArray.Count() = 0);
	ElsIf TypeOf(Parameters.CompanyArray) = Type("CatalogRef.Companies") Then
		Parameters.Insert("CompanyArray", CommonClientServer.ValueInArray(Parameters.CompanyArray));
		Parameters.Insert("ByAllCompanies", False);
	Else
		Parameters.Insert("ByAllCompanies", True);
	EndIf;
	Parameters.Insert("GenerateFinancialResult", GetFunctionalOption("GenerateFinancialResult"));
	Parameters.Insert("PreliminaryCalculation", Not Parameters.DocumentDistributions = Undefined);
	Parameters.Insert("TypesOfExpensesNormalized", Enums.ExpenseKindsTA.RationingExpenses());
EndProcedure

#EndRegion

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.AllocationOfOtherCosts AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("MetadataIdentifier",
								Common.MetadataObjectID(Type("DocumentRef.AllocationOfOtherCosts")));
								
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref						AS Ref,
	|	UNDEFINED				AS RecordSeparator,
	|	&Period						AS IBDocumentDate,
	|	&Number						AS IBDocumentNumber,
	|	&MetadataIdentifier	AS RefType,
	|	&Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.ExpensingToProductionLots) AS BusinessOperation,
	|	&LineOfBusiness	AS LineOfBusiness,
	|	&Department				AS Department,
	|	&EmployeeResponsible				AS EmployeeResponsible,
	|	&Comment				AS Comment,
	|	0							AS Sum,
	|	&Posted					AS Posted,
	|	&DeletionMark			AS DeletionMark,
	|	FALSE						AS AdditionalRecord,
	|	""""						AS More,
	|	&Period						AS SourceDocumentDate,
	|	&NumberForPrinting				AS SourceDocumentNumber,
	|	&Department				AS StorageLocation,
	|	&Period						AS RecordingInAccountingDate,
	|	UNDEFINED                AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.AllocationOfOtherCosts";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInProductionLog
// Generates a hyperlink text for workplaces serving a document about the need for paperwork.
// Returns:
//	FormattedString - hyperlink representation.
Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.AllocationOfOtherCosts) Then
		Return Undefined;
	EndIf;
	
	Return New FormattedString(NStr("vi = 'Phân bổ chi phí';
									|ru = 'Распределение расходов';
									|en = 'Line of business — allocation base'; fa = 'خط کسب‌وکار — مبنای تسهیم';
									|it = 'Ripartizione delle spese';
									|pl = 'Podział kosztów';
									|tr = 'Giderlerin dağıtımı'"),,,,
		"Document.AllocationOfOtherCosts.Form.WorkplaceForm");
	
EndFunction
Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export
	
	ToRegister = TMCommonUse.CreateHyperlinkToDesign(Parameters[0], Parameters[1]);
	PutToTempStorage(ToRegister, StorageAddress);
	
EndProcedure

#EndRegion

#Region FillType

Function ToConvertData(ExpenditureData)
	
	DataTable = New ValueTable;
	DataTable.Columns.Add("Date", New TypeDescription("Date"));
	DataTable.Columns.Add("LineID", New TypeDescription("Number"));
	DataTable.Columns.Add("DocumentMan", New TypeDescription("DocumentRef.AllocationOfOtherCosts"));
	DataTable.Columns.Add("DocumentCompl", New TypeDescription("DocumentRef.AllocationOfOtherCosts"));
	DataTable.Columns.Add("DocumentAIT", New TypeDescription("DocumentRef.AllocationOfOtherCosts"));
	DataTable.Columns.Add("UPRStatus", New TypeDescription("EnumRef.CostAllocationStates"));
	DataTable.Columns.Add("ReglStatus", New TypeDescription("EnumRef.CostAllocationStates"));
	DataTable.Columns.Add("NDDState", New TypeDescription("EnumRef.CostAllocationStates"));
	DataTable.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
	DataTable.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
	DataTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DataTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	DataTable.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));

	For Each ConsumptionData In ExpenditureData Do
		FillPropertyValues(DataTable.Add(), ConsumptionData);
	EndDo;
	
	Return DataTable;
	
EndFunction

Function FormatOfExpenditureItemAllocationData()
	
	FillingStructure = New Structure;
	FillingStructure.Insert("Date");
	FillingStructure.Insert("LineID");
	FillingStructure.Insert("DocumentMan");
	FillingStructure.Insert("DocumentCompl");
	FillingStructure.Insert("DocumentAIT");
	FillingStructure.Insert("UPRStatus");
	FillingStructure.Insert("ReglStatus");
	FillingStructure.Insert("NDDState");
	FillingStructure.Insert("ExpenseItem");
	FillingStructure.Insert("DimensionOfExpenses");
	FillingStructure.Insert("ProductCostElement");
	FillingStructure.Insert("LocalDistributionOption");
	FillingStructure.Insert("ManDistributionOption");
	FillingStructure.Insert("NDTDistributionOption");
	FillingStructure.Insert("Organization");
	FillingStructure.Insert("Department");
	FillingStructure.Insert("LineOfBusiness");
	FillingStructure.Insert("ManDistributionRule");
	FillingStructure.Insert("LocalDistributionRule");
	FillingStructure.Insert("RuleOfDistributionOfPersonalIncomeTax");
	
	Return FillingStructure;
	
EndFunction

Procedure SetSignsOfBUITa(Object, AccountingKind)
	

	If AccountingKind = "LocalAccounting" Then
		Object.TaxAccounting = Object.LocalAccounting;
	EndIf;
	
EndProcedure

#EndRegion

#Region BlockingWhenUpdatingInformationSecurity

Procedure CheckBlockingIncomingDataWhenUpdatingInformationSecurity(PresentationOperation)
	
	IncomingData = New Map;
	
	IncomingData.Insert(Metadata.Documents.AllocationOfOtherCosts);
	IncomingData.Insert(Metadata.AccumulationRegisters.MaterialsAndWorksInProduction);
	IncomingData.Insert(Metadata.AccumulationRegisters.OtherExpenses);
	IncomingData.Insert(Metadata.AccumulationRegisters.InventoryCost);
	IncomingData.Insert(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses);
	MonthEndTransactionsServer.CheckBlockingIncomingDataWhenUpdatingInformationSecurity(IncomingData, PresentationOperation);
	
EndProcedure

#EndRegion

#Region DistributionToFinancialResult

Procedure PrepareServiceTables(Period, Val Companies, Val Query, ExcludeTransportationCosts = False) Export
	

	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query.TempTablesManager, "TTShareOfWriteOffOfIndirectExpenses") Then
		Query.Text = 
			"SELECT
			|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
			|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
			|	FALSE AS NewCostingAlgorithm,
			|	FALSE AS Normalized,
			|	FALSE AS Transportation,
			|	1 AS PercentageOfWriteOffs
			|INTO TTShareOfWriteOffOfIndirectExpenses";
		Query.Execute();
	EndIf;
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query.TempTablesManager, "TTOvz") Then
		Query.Text = CostCalculationItemizedCosts.TextInTPOOvz();
		SetPrivilegedMode(True);
		Query.Execute();
		SetPrivilegedMode(False);
	EndIf;

	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query.TempTablesManager, "ValuesOfHIAIndicators") Then
		Query.Text = CostCalculationItemizedCosts.TextValuesOfDistributionIndicatorsForHIA();
		SetPrivilegedMode(True);
		Query.Execute();
		SetPrivilegedMode(False);
	EndIf;
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query.TempTablesManager, "Recorders") Then
		PrepareTablesForCalculation(Undefined, Query);
	EndIf;
	
EndProcedure

Function SamplingOfDistributionOfExpensesForProfitabilityAndCosts(TemporaryTable)
	
	Query = New Query;
	Query.TempTablesManager = TemporaryTable;
	
	Query.Text = QueryTextOfDistributionSelectionForProfitabilityAndCost();
	
	QueryResult = Query.ExecuteBatch();
	
	Return QueryResult;
	
EndFunction

#EndRegion

#Region CorrectingOutdatedDocuments

Function ThereAreOutdatedDocumentsWithExpenses(Query)
	
	Query.Text =
		"SELECT TOP 1
		|	AllocationOfIncomeByLinesOfBusinessExpenses.Ref AS Ref
		|FROM
		|	Document.AllocationOfIncomeByLinesOfBusiness.Expenses AS AllocationOfIncomeByLinesOfBusinessExpenses
		|		INNER JOIN Document.AllocationOfIncomeByLinesOfBusiness AS AllocationOfIncomeByLinesOfBusiness
		|		ON AllocationOfIncomeByLinesOfBusinessExpenses.Ref = AllocationOfIncomeByLinesOfBusiness.Ref
		|WHERE
		|	AllocationOfIncomeByLinesOfBusiness.Organization IN(&CompanyArray)
		|	AND AllocationOfIncomeByLinesOfBusiness.Posted
		|	AND AllocationOfIncomeByLinesOfBusiness.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure DeleteRegisteredRecordsOfAllocatedExpensesInOldDocument(Parameters, TempTable)
	
	Query = CostCalculationAppliedAlgorithms.InitializeRequestBasedOnParameters(Parameters, TempTable);
	
	If Not ThereAreOutdatedDocumentsWithExpenses(Query) Then
		Return;
	EndIf;
	
	// Removal of movements of distributed expenses in the old document "Distribution of income by line of business".
	Query.Text =
		"SELECT DISTINCT
		|	RegisterRecords.Recorder
		|INTO RecordersToRewriteRegisteredRecords
		|FROM
		|	AccumulationRegister.OtherExpenses AS RegisterRecords
		|		INNER JOIN DistributedExpenseAnalytics AS Analysts
		|		ON RegisterRecords.Organization = Analysts.Organization
		|			AND RegisterRecords.Department = Analysts.Department
		|			AND RegisterRecords.LineOfBusiness = Analysts.LineOfBusiness
		|			AND RegisterRecords.ExpenseItem = Analysts.ExpenseItem
		|			AND RegisterRecords.DimensionOfExpenses = Analysts.DimensionOfExpenses
		|WHERE
		|	RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND RegisterRecords.Active
		|	AND VALUETYPE(RegisterRecords.Recorder) = TYPE(Document.AllocationOfIncomeByLinesOfBusiness)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterRecords.*,
		|	(NOT Analysts.Organization IS NULL) AS SkipRecording
		|FROM
		|	AccumulationRegister.OtherExpenses AS RegisterRecords
		|		INNER JOIN RecordersToRewriteRegisteredRecords AS Recorders
		|		ON RegisterRecords.Recorder = Recorders.Recorder
		|		LEFT JOIN DistributedExpenseAnalytics AS Analysts
		|		ON RegisterRecords.Organization = Analysts.Organization
		|			AND RegisterRecords.Department = Analysts.Department
		|			AND RegisterRecords.LineOfBusiness = Analysts.LineOfBusiness
		|			AND RegisterRecords.ExpenseItem = Analysts.ExpenseItem
		|			AND RegisterRecords.DimensionOfExpenses = Analysts.DimensionOfExpenses
		|
		|TOTALS BY
		|	RegisterRecords.Recorder";
		
	Result = Query.Execute();
	
	BusinessesToRecalculate = New ValueList;
	SelectionOfRecordersOfNewRegisteredRecords = Result.Select(QueryResultIteration.ByGroups);
	While SelectionOfRecordersOfNewRegisteredRecords.Next() Do
		
		BusinessesToRecalculate.Clear();
		
		OtherExpenses = AccumulationRegisters.OtherExpenses.CreateRecordSet();
		OtherExpenses.Filter.Recorder.Set(SelectionOfRecordersOfNewRegisteredRecords.Recorder);
		
		DetailedSampling = SelectionOfRecordersOfNewRegisteredRecords.Select();
		While DetailedSampling.Next() Do
			
			If BusinessesToRecalculate.FindByValue(DetailedSampling.Organization) = Undefined Then
				BusinessesToRecalculate.Add(DetailedSampling.Organization);
			EndIf;
			
			If DetailedSampling.SkipRecording Then
				Continue;
			EndIf;
			
			FillPropertyValues(OtherExpenses.Add(), DetailedSampling);
			
		EndDo;
		
		OtherExpenses.Write();
		
		For Each RecalculatedOrganization In BusinessesToRecalculate Do
			InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(Parameters.BeginOfPeriod, 
				SelectionOfRecordersOfNewRegisteredRecords.Recorder,
				RecalculatedOrganization.Value, 
				Catalogs.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness);
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ReceivedOtherExpenses

// Returns the text of the data source with a template replacement.
//
// Returns:
//	String - query text.
//
Function ReplaceByPattern(QueryText, Template, Setting) Export

	QueryTextResult = QueryText;
	Substitutions_3 = Undefined;
	Template.Property(Setting, Substitutions_3);
	For Each Replacement In Substitutions_3 Do
		QueryTextResult = StrReplace(QueryTextResult, Replacement.Key, Replacement.Value);
	EndDo;
	Return QueryTextResult;
	
EndFunction

// Generates a Query Text to get RegisteredRecords of other expenses by expense items.
//
// Returns:
//   String - a package of requests for the formation of temporary tables, Registered Records of other expenses, for various types of accounting.
//
Function QueryTextTTOfRegisteredRecordsOfOtherExpensesByItemOfExpenditure()
	
	QueryTextTemplate2 = "
	|SELECT 
	|	RegisterRecords.Period AS Period,
	|	RegisterRecords.Recorder AS Recorder,
	|	RegisterRecords.LineNumber AS LineNumber,
	|	ArticlesForDistribution.CostAllocationOption AS CostAllocationOption,
	|	ArticlesForDistribution.Predefined AS Predefined,
	|	RegisterRecords.ExpenseItem AS ExpenseItem
	|INTO TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure
	|	FROM
	|		ItemsOfExpenditureToBeDistributed AS ArticlesForDistribution
	|			INNER JOIN AccumulationRegister.OtherExpenses AS RegisterRecords
	|			ON RegisterRecords.ExpenseItem = ArticlesForDistribution.Ref
	|	WHERE
	|		RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod 
	|		
	|INDEX BY
	|	Period,
	|	Recorder,
	|	LineNumber,
	|	ExpenseItem
	|";
	
	ReplacementPattern = ReplacementPattern();
	TextOfMovementOfOtherExpensesOfMan = ReplaceByPattern(QueryTextTemplate2, ReplacementPattern, "TextOfMovementOfOtherExpensesOfMan");
	TextOfMovementOfOtherLocalExpenses = ReplaceByPattern(QueryTextTemplate2, ReplacementPattern, "TextOfMovementOfOtherLocalExpenses");
	TextOfMovementOfOtherExpensesTa = ReplaceByPattern(QueryTextTemplate2, ReplacementPattern, "TextOfMovementOfOtherExpensesTa");
	AITTextOfRegisteredRecordsOfOtherExpenses = ReplaceByPattern(QueryTextTemplate2, ReplacementPattern, "AITTextOfRegisteredRecordsOfOtherExpenses");
	
	QueryTexts = New Array();
	QueryTexts.Add(TextOfMovementOfOtherExpensesOfMan);
	QueryTexts.Add(TextOfMovementOfOtherLocalExpenses);
	QueryTexts.Add(TextOfMovementOfOtherExpensesTa);
	QueryTexts.Add(AITTextOfRegisteredRecordsOfOtherExpenses);
	
	Return StrConcat(QueryTexts, Common.QueryBatchSeparator());
EndFunction

// Returns the text of the subquery for getting data sources for other expenses.
// 
// Parameters:
//  CalculationOption - String - Variant of calculation
// 
// Returns:
//  String -- query text.
Function RequestTextReceivedOtherExpensesSources(CalculationOption) Export
	
	ReplacementPattern = ReplacementPattern();

	#Region TextDescriptionOfData
	TextDescriptionOfData = "
	|	SELECT TOP 0
	|		//Settings """" AS REQUESTED Source,
	|		VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|		VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)  AS LineOfBusiness,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|		UNDEFINED AS DimensionOfExpenses,
	|		0 AS Sum,
	|		0 AS AmountExcludingVAT,
	|		0 AS SumCompl,
	|		0 AS PermanentDifference,
	|		0 AS CostTD,
	|		0 AS AITAmount,
	|		0 AS SumMan,
	|		0 AS SumComplExpense,
	|		0 AS PermanentDifferenceExpense,
	|		0 AS CostTDExpense,
	|		0 AS AITAmountExpense,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef) AS DirectionOfActivityForCommunication,
	// Article of expenditure for Communication = Empty link only in the description and for HIA blocks. 
	// Participates in the verification of articles for distribution to HIA. For example, See QueryTextReceivedOtherExpenses
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureForCommunication
	|	//PLACE THE SETTINGS in the SOURCE of the inputs
	|";
	#EndRegion

	#Region TextBalancesOfOtherExpenses
	TextBalancesOfOtherExpenses = "
	|	SELECT
	|		//Settings for ""textostatkiproch expenses"",
	|		Expenses.Organization,
	|		Expenses.Department,
	|		Expenses.LineOfBusiness,
	|		Expenses.ExpenseItem,
	|		Expenses.DimensionOfExpenses,
	|		Expenses.SumBalance,
	|		Expenses.AmountExcludingVATBalance,
	|		Expenses.SumComplBalance,
	|		Expenses.PermanentDifferenceBalance,
	|		Expenses.CostTDBalance,
	|		Expenses.AITAmountBalance,
	|		Expenses.SumManBalance,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		Expenses.LineOfBusiness,
	|		Expenses.ExpenseItem
	|	FROM
	|		ItemsOfExpenditureToBeDistributed AS T
	|		INNER JOIN TTOtherExpenses_Balance AS Expenses
	|		ON Expenses.ExpenseItem = T.Ref
	|";
	TextBalancesOfOtherManSExpenses =		ReplaceByPattern(TextBalancesOfOtherExpenses, ReplacementPattern, "TextBalancesOfOtherManSExpenses");
	TextBalancesOfOtherLocalExpenses =	ReplaceByPattern(TextBalancesOfOtherExpenses, ReplacementPattern, "TextBalancesOfOtherLocalExpenses");
	TextBalancesOfOtherExpensesTa =		ReplaceByPattern(TextBalancesOfOtherExpenses, ReplacementPattern, "TextBalancesOfOtherExpensesTa");
	TextBalancesOfOtherExpensesAIT =		CalculationOfCostLocalization.TextBalancesOfOtherExpensesAIT();
	
	#EndRegion
	
	#Region TextOfMovementOfOtherExpenses
	TextOfMovementOfOtherExpenses = "
	|	SELECT
	|		//Settings for ""Textmovement of other expenses"",
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
	|		RegisterRecords.Sum,
	|		RegisterRecords.AmountExcludingVAT,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		RegisterRecords.AITAmount,
	|		RegisterRecords.SumMan,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		RegisterRecords.AITAmount,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		ISNULL(DD.LineOfBusiness, RegisterRecords.LineOfBusiness),
	|		ISNULL(DD.ExpenseItem, RegisterRecords.ExpenseItem)
	|	FROM
	|		TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure AS RegisteringRecordsOfOtherExpenses
	|			INNER JOIN AccumulationRegister.OtherExpenses AS RegisterRecords
	|			ON RegisterRecords.Period = RegisteringRecordsOfOtherExpenses.Period
	|				AND RegisterRecords.Recorder = RegisteringRecordsOfOtherExpenses.Recorder
	|				AND RegisterRecords.LineNumber = RegisteringRecordsOfOtherExpenses.LineNumber
	|				AND RegisterRecords.ExpenseItem = RegisteringRecordsOfOtherExpenses.ExpenseItem 
	|			
	|			LEFT JOIN Document.AllocationOfOtherCosts AS DD
	|			ON RegisteringRecordsOfOtherExpenses.Recorder = DD.Ref
	|				AND DD.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	WHERE
	|		RegisterRecords.Active
	|		AND (VALUETYPE(RegisterRecords.Recorder) IN (
	|			TYPE(Document.InventoryCostCalculation), 
	|			TYPE(Document.AllocationOfOtherCosts), 
	|			TYPE(Document.AllocationOfIncomeByLinesOfBusiness))
	|			AND NOT RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
	|		OR RegisteringRecordsOfOtherExpenses.CostAllocationOption = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		)
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND RegisterRecords.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffRoundingErrors)
	|		AND (&ByAllCompanies
	|			OR RegisterRecords.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR RegisterRecords.Department IN (&DepartmentList))
	|";
	TextOfMovementOfOtherExpensesOfMan = ReplaceByPattern(TextOfMovementOfOtherExpenses, ReplacementPattern, "TextOfMovementOfOtherExpensesOfMan");
	TextOfMovementOfOtherLocalExpenses = ReplaceByPattern(TextOfMovementOfOtherExpenses, ReplacementPattern, "TextOfMovementOfOtherLocalExpenses");
	TextOfMovementOfOtherExpensesTa = ReplaceByPattern(TextOfMovementOfOtherExpenses, ReplacementPattern, "TextOfMovementOfOtherExpensesTa");
	AITTextOfRegisteredRecordsOfOtherExpenses = ReplaceByPattern(TextOfMovementOfOtherExpenses, ReplacementPattern, "AITTextOfRegisteredRecordsOfOtherExpenses");
	#EndRegion
	
	#Region TextOfMovementOfLotsOfOtherExpenses
	TextOfMovementOfLotsOfOtherExpenses = "
	|	SELECT
	|		//""Textmovement of Party and other expenses"" settings,
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
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
	|		0 AS EstimatedQuantity,
	|		TRUE AS EstimatedAmount,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem
	|	FROM
	|		AccumulationRegister.ItemisedExpensesLots AS RegisterRecords
	|			INNER JOIN ItemsOfExpenditureToBeDistributed AS ArticlesForDistribution
	|			ON RegisterRecords.ExpenseItem = ArticlesForDistribution.Ref
	|	WHERE
	|		RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND RegisterRecords.Active
	|		AND RegisterRecords.Recorder REFS Document.ReverseVATAccrual
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (&ByAllCompanies
	|			OR RegisterRecords.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR RegisterRecords.Department IN (&DepartmentList))
	|";
	TextOfMovementOfLotsOfOtherExpensesMen = ReplaceByPattern(TextOfMovementOfLotsOfOtherExpenses, ReplacementPattern, "TextOfMovementOfOtherExpensesOfMan");
	TextOfMovementOfLotsOfOtherExpensesLocal = ReplaceByPattern(TextOfMovementOfLotsOfOtherExpenses, ReplacementPattern, "TextOfMovementOfOtherLocalExpenses");
	TextOfMovementOfLotsOfOtherExpensesTA = ReplaceByPattern(TextOfMovementOfLotsOfOtherExpenses, ReplacementPattern, "TextOfMovementOfOtherExpensesTa");
	AITTextOfPartySRegisteredRecordsOfOtherExpenses = ReplaceByPattern(TextOfMovementOfLotsOfOtherExpenses, ReplacementPattern, "AITTextOfRegisteredRecordsOfOtherExpenses");
	#EndRegion
	#Region TextOfMovementOfOtherExpensesOfSecondaryPolygon
	TextOfMovementOfOtherExpensesOfSecondaryPolygon = "
	|	SELECT
	|		//Settings of the ""textmovementprochihspendingsvtorichnogokontura"",
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
	|		-RegisterRecords.Sum,
	|		-RegisterRecords.AmountExcludingVAT,
	|		-RegisterRecords.SumCompl,
	|		-RegisterRecords.PermanentDifference,
	|		-RegisterRecords.CostTD,
	|		-RegisterRecords.AITAmount,
	|		-RegisterRecords.SumMan,
	|		-RegisterRecords.SumCompl,
	|		-RegisterRecords.PermanentDifference,
	|		-RegisterRecords.CostTD,
	|		-RegisterRecords.AITAmount,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem
	|	FROM
	|		TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure AS RegisteringRecordsOfOtherExpenses
	|			INNER JOIN AccumulationRegister.OtherExpenses AS RegisterRecords
	|			ON RegisterRecords.Period = RegisteringRecordsOfOtherExpenses.Period
	|				AND RegisterRecords.Recorder = RegisteringRecordsOfOtherExpenses.Recorder
	|				AND RegisterRecords.LineNumber = RegisteringRecordsOfOtherExpenses.LineNumber
	|				AND RegisterRecords.ExpenseItem = RegisteringRecordsOfOtherExpenses.ExpenseItem 
	|	WHERE
	|		RegisterRecords.Active
	|		AND (VALUETYPE(RegisterRecords.Recorder) IN (
	|			TYPE(Document.InventoryCostCalculation), 
	|			TYPE(Document.AllocationOfOtherCosts), 
	|			TYPE(Document.AllocationOfIncomeByLinesOfBusiness))
	|		AND RegisteringRecordsOfOtherExpenses.CostAllocationOption IN (
	|			VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|			VALUE(Enum.CostAllocationOptions.ToProductionCostDirect)
	|			)
	|		AND RegisteringRecordsOfOtherExpenses.Predefined
	|		)
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (&ByAllCompanies
	|			OR RegisterRecords.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR RegisterRecords.Department IN (&DepartmentList))
	|";
	TextOfMovementOfOtherExpensesOfSecondaryContourOfMan = ReplaceByPattern(TextOfMovementOfOtherExpensesOfSecondaryPolygon, ReplacementPattern, "TextOfMovementOfOtherExpensesOfMan");
	TextOfMovementOfOtherExpensesOfSecondaryLocalPolygon = ReplaceByPattern(TextOfMovementOfOtherExpensesOfSecondaryPolygon, ReplacementPattern, "TextOfMovementOfOtherLocalExpenses");
	TextOfMovementOfOtherExpensesOfSecondaryPolygonTa = ReplaceByPattern(TextOfMovementOfOtherExpensesOfSecondaryPolygon, ReplacementPattern, "TextOfMovementOfOtherExpensesTa");
	AITTextOfRegisteredRecordsOfOtherExpensesOfSecondaryContour = ReplaceByPattern(TextOfMovementOfOtherExpensesOfSecondaryPolygon, ReplacementPattern, "AITTextOfRegisteredRecordsOfOtherExpenses");
	#EndRegion
	
	#Region ImpactOfMovementOnProductionCosts
	ImpactOfMovementOnProductionCosts = "
	|	SELECT
	|		//Modes of the ""Textmovement of the highest value of production"",
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
	|		RegisterRecords.Sum,
	|		RegisterRecords.AmountExcludingVAT,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		RegisterRecords.AITAmount,
	|		RegisterRecords.SumMan,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		RegisterRecords.AITAmount,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem
	|	FROM
	|		TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure AS RegisteringRecordsOfOtherExpenses
	|			INNER JOIN AccumulationRegister.OtherExpenses AS RegisterRecords
	|			ON RegisterRecords.Period = RegisteringRecordsOfOtherExpenses.Period
	|				AND RegisterRecords.Recorder = RegisteringRecordsOfOtherExpenses.Recorder
	|				AND RegisterRecords.LineNumber = RegisteringRecordsOfOtherExpenses.LineNumber
	|				AND RegisterRecords.ExpenseItem = RegisteringRecordsOfOtherExpenses.ExpenseItem 
	|	WHERE
	|		RegisterRecords.Active
	|		AND (VALUETYPE(RegisterRecords.Recorder) IN (
	|			TYPE(Document.ProductionStage2_2),
	|			TYPE(Document.BackflushProduction))
	|		)
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseAllocationToProductionCost)
	|		AND (&ByAllCompanies
	|			OR Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR Department IN (&DepartmentList))
	|";
	TextOfMovementOnCostOfProductionOfMan = ReplaceByPattern(ImpactOfMovementOnProductionCosts, ReplacementPattern, "TextOfMovementOfOtherExpensesOfMan");
	TextOfMovementOnCostOfProductionOfLocal = ReplaceByPattern(ImpactOfMovementOnProductionCosts, ReplacementPattern, "TextOfMovementOfOtherLocalExpenses");
	TextOfMovementOnCostOfProductionTa = ReplaceByPattern(ImpactOfMovementOnProductionCosts, ReplacementPattern, "TextOfMovementOfOtherExpensesTa");
	AITTextOfRegisteredRecordsForCostOfProduction = ReplaceByPattern(ImpactOfMovementOnProductionCosts, ReplacementPattern, "AITTextOfRegisteredRecordsOfOtherExpenses");
	#EndRegion
	#Region TextWriteOffInventoryAllocation
	TextWriteOffInventoryAllocation = "
	|	SELECT DISTINCT
	|		//Settings for ""TextsPisanierDistributioneTMC"",
	|		InventoryCost.Organization,
	|		InventoryCost.Department,
	|		InventoryCost.CorLineOfBusiness,
	|		InventoryCost.ExpenseItemOfWriteOff,
	|		InventoryCost.DimensionOfExpenses,
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
	|		InventoryCost.Count AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		InventoryCost.CorLineOfBusiness,
	|		InventoryCost.ExpenseItemOfWriteOff
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|			INNER JOIN ItemsOfExpenditureToBeDistributed AS ARTICLES__
	|			ON (ARTICLES__.Ref = InventoryCost.ExpenseItemOfWriteOff)
	|	WHERE
	|		InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND InventoryCost.Active
	|		AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VALUETYPE(InventoryCost.Recorder) IN (
	|			TYPE(Document.ReversingEntry),
	|			TYPE(Document.InventoryConsumption),
	|			TYPE(Document.ReportOnVMIAdjustment),


	|			TYPE(Document.ProductionCostAllocation),
	|			TYPE(Document.BackflushProduction),
	|			TYPE(Document.WriteOffOfShippedGoods),
	|			TYPE(Document.ReportToMaterialProvider2_5),
	|			TYPE(Document.ProductionStage2_2),
	|			TYPE(Document.OtherGoodsRecordingAsReceived),
	|			TYPE(Document.WriteOffOfGoodsShortages))
	|		AND NOT InventoryCost.CalculationOfCost
	|		AND (&ByAllCompanies
	|				OR InventoryCost.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|				OR InventoryCost.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	#Region TextWriteOffDistributionOfTrademarkToAnotherOrganization
	TextWriteOffDistributionOfTrademarkToAnotherOrganization = "
	|	SELECT DISTINCT
	|		//Settings for ""textspisdistribution to other organizations"",
	|		InventoryCost.CorCompany,
	|		InventoryCost.Department,
	|		InventoryCost.CorLineOfBusiness,
	|		InventoryCost.ExpenseItemOfWriteOff,
	|		InventoryCost.DimensionOfExpenses,
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
	|		InventoryCost.Count AS EstimatedQuantity,
	|		TRUE AS EstimatedAmount,
	|		InventoryCost.CorLineOfBusiness,
	|		InventoryCost.ExpenseItemOfWriteOff
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|			INNER JOIN ItemsOfExpenditureToBeDistributed AS ARTICLES__
	|			ON (ARTICLES__.Ref = InventoryCost.ExpenseItemOfWriteOff)
	|	WHERE
	|		InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND InventoryCost.Active
	|		AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VALUETYPE(InventoryCost.Recorder) IN (
	|			TYPE(Document.ReversingEntry),
	|			TYPE(Document.InventoryConsumption),

	|			TYPE(Document.ProductionCostAllocation),
	|			TYPE(Document.BackflushProduction),
	|			TYPE(Document.WriteOffOfShippedGoods),
	|			TYPE(Document.ProductionStage2_2),
	|			TYPE(Document.OtherGoodsRecordingAsReceived),
	|			TYPE(Document.WriteOffOfGoodsShortages))
	|		AND NOT InventoryCost.CalculationOfCost
	|		AND NOT InventoryCost.CorCompany = VALUE(Catalog.Companies.EmptyRef)
	|		AND NOT InventoryCost.CorCompany = InventoryCost.Organization
	|		AND (&ByAllCompanies
	|				OR InventoryCost.CorCompany IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|				OR InventoryCost.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	#Region TextMaterialsAndWorks_
	TextMaterialsAndWorks_ = "
	|	SELECT DISTINCT
	|		//Settings ""textdistributionmaterialsworks"",
	|		Costs.Organization,
	|		Costs.Department,
	|		ISNULL(Costs.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|		CAST(Costs.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems),
	|		Costs.DimensionOfExpenses,
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
	|		0 AS EstimatedQuantity,
	|		TRUE AS EstimatedAmount,
	|		ISNULL(Costs.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|		CAST(Costs.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems)
	|	FROM
	|		AccumulationRegister.MaterialsAndWorksInProduction AS Costs
	|			INNER JOIN ItemsOfExpenditureToBeDistributed AS ARTICLES__
	|			ON (ARTICLES__.Ref = Costs.ExpenseItem)
	|	WHERE
	|		Costs.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Costs.Active
	|		AND Costs.Recorder REFS Document.ProductionCostAllocation
	|		AND (&ByAllCompanies
	|				OR Costs.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|				OR Costs.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	#Region TextBalancesOfOtherHIAExpenses
	TextBalancesOfOtherHIAExpenses = "
	|	SELECT 
	|		//Settings for ""textostatkiproch expenditures"",
	|		Expenses.Organization,
	|		Expenses.Department,
	|		Expenses.LineOfBusiness,
	|		Expenses.ExpenseItem,
	|		Expenses.DimensionOfExpenses,
	|		Expenses.SumBalance,
	|		Expenses.AmountExcludingVATBalance,
	|		Expenses.SumComplBalance,
	|		Expenses.PermanentDifferenceBalance,
	|		Expenses.CostTDBalance,
	|		0,
	|		Expenses.SumManBalance,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	FROM
	|		OVZKDistribution AS T
	|		INNER JOIN TTOtherExpenses_Balance AS Expenses
	|		ON Expenses.DimensionOfExpenses = T.ConstCenter
	|					AND ExpenseItem IN
	|						(SELECT
	|							T.Ref
	|						FROM
	|							ArticlesCO AS T)
	|";
	TextBalancesOfOtherExpensesOfHIAMan = ReplaceByPattern(TextBalancesOfOtherHIAExpenses, ReplacementPattern, "TextBalancesOfOtherManSExpenses");
	TextBalancesOfOtherExpensesOfHIALocal = ReplaceByPattern(TextBalancesOfOtherHIAExpenses, ReplacementPattern, "TextBalancesOfOtherLocalExpenses");
	TextBalancesOfOtherExpensesOfOVZNU = ReplaceByPattern(TextBalancesOfOtherHIAExpenses, ReplacementPattern, "TextBalancesOfOtherExpensesTa");
	TextBalancesOfOtherExpensesOfInternalRevenueService = CalculationOfCostLocalization.TextBalancesOfOtherExpensesOfInternalRevenueService();
	#EndRegion
	
	#Region TextOfMovementOfOtherExpensesFromHIA
	TextOfMovementOfOtherExpensesFromHIA = "
	|	SELECT 
	|		//Settings for ""TextmOvementpRochihRashodovIzOVZ"",
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
	|		RegisterRecords.Sum,
	|		RegisterRecords.AmountExcludingVAT,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		0,
	|		RegisterRecords.SumMan,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		0,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	FROM
	|		AccumulationRegister.OtherExpenses AS RegisterRecords
	|			INNER JOIN OVZKDistribution AS OVZKDistribution
	|			ON RegisterRecords.DimensionOfExpenses = OVZKDistribution.ConstCenter
	|	WHERE
	|		RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND RegisterRecords.Active
	|		AND (VALUETYPE(RegisterRecords.Recorder) IN (
	|			TYPE(Document.AllocationOfOtherCosts), 
	|			TYPE(Document.AllocationOfIncomeByLinesOfBusiness))
	|		)
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND (&ByAllCompanies
	|			OR Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR Department IN (&DepartmentList))
	|";
	TextOfMovementOfOtherExpensesFromHIAMan = ReplaceByPattern(TextOfMovementOfOtherExpensesFromHIA, ReplacementPattern, "TextOfMovementOfOtherExpensesOfMan");
	TextOfMovementOfOtherExpensesFromHIALocal = ReplaceByPattern(TextOfMovementOfOtherExpensesFromHIA, ReplacementPattern, "TextOfMovementOfOtherLocalExpenses");
	TextOfMovementOfOtherExpensesFromOVZNU = ReplaceByPattern(TextOfMovementOfOtherExpensesFromHIA, ReplacementPattern, "TextOfMovementOfOtherExpensesTa");
	TextOfRegisteredRecordsOfOtherExpensesFromAIT = CalculationOfCostLocalization.TextOfRegisteredRecordsOfOtherExpensesFromAIT();
	#EndRegion
	
	#Region TextWriteOffDistributionOfInventoryForHIA
	TextWriteOffDistributionOfInventoryForHIA = "
	|	SELECT DISTINCT 
	|		//Settings ""textspisanierdistributionetmtsnaovz"",
	|		InventoryCost.Organization,
	|		InventoryCost.Department,
	|		InventoryCost.CorLineOfBusiness,
	|		InventoryCost.ExpenseItemOfWriteOff,
	|		InventoryCost.DimensionOfExpenses,
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
	|		0 AS EstimatedQuantity,
	|		TRUE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|			INNER JOIN OVZKDistribution AS OVZKDistribution
	|			ON InventoryCost.DimensionOfExpenses = OVZKDistribution.ConstCenter
	|	WHERE
	|		InventoryCost.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND InventoryCost.Active
	|		AND VALUETYPE(InventoryCost.Recorder) IN (
	|			TYPE(Document.InventoryConsumption),
	|			TYPE(Document.ProductionCostAllocation),
	|			TYPE(Document.BackflushProduction),
	|			TYPE(Document.ProductionStage2_2),
	|			TYPE(Document.OtherGoodsRecordingAsReceived),
	|			TYPE(Document.WriteOffOfGoodsShortages))
	|		AND NOT InventoryCost.CalculationOfCost
	|		AND (&ByAllCompanies
	|				OR InventoryCost.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|				OR InventoryCost.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	#Region TextMaterialsAndWorksOnHIA
	TextMaterialsAndWorksOnHIA = "
	|	SELECT DISTINCT 
	|		//""textdistributionmaterialsworkings"",
	|		Costs.Organization,
	|		Costs.Department,
	|		ISNULL(Costs.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	|		CAST(Costs.ExpenseItem AS ChartOfCharacteristicTypes.ExpenseItems),
	|		Costs.DimensionOfExpenses,
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
	|		0 AS EstimatedQuantity,
	|		TRUE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	FROM
	|		AccumulationRegister.MaterialsAndWorksInProduction AS Costs
	|			INNER JOIN OVZKDistribution AS OVZKDistribution
	|			ON Costs.DimensionOfExpenses = OVZKDistribution.ConstCenter
	|	WHERE
	|		Costs.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Costs.Active
	|		AND Costs.Recorder REFS Document.ProductionCostAllocation
	|		AND (&ByAllCompanies
	|				OR Costs.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|				OR Costs.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	#Region TextOfMovementOfOtherExpensesBetweenHIAExpenses
	TextOfMovementOfOtherExpensesBetweenHIAExpenses = "
	|	SELECT 
	|		//Settings for ""Textmovement of other expenditures between each expenditure"",
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
	|		RegisterRecords.Sum,
	|		RegisterRecords.AmountExcludingVAT,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		RegisterRecords.AITAmount,
	|		RegisterRecords.SumMan,
	|		RegisterRecords.SumCompl,
	|		RegisterRecords.PermanentDifference,
	|		RegisterRecords.CostTD,
	|		RegisterRecords.AITAmount,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	FROM
	|		AccumulationRegister.OtherExpenses AS RegisterRecords
	|			INNER JOIN Catalog.CostCenters AS ConstCenter
	|			ON RegisterRecords.DimensionOfExpenses = ConstCenter.Ref
	|	WHERE
	|		RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND RegisterRecords.Active
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VALUETYPE(RegisterRecords.Recorder) = TYPE(Document.AllocationOfOtherCosts)
	|		AND RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
	|		AND (&ByAllCompanies
	|			OR RegisterRecords.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR RegisterRecords.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	#Region TextOfOtherMovementOfExpensesBetweenHIAParish
	TextOfMovementOfOtherExpensesBetweenHIAParish = "
	|	SELECT 
	|		//Settings for ""Textmovement of other expenses between each arrival"",
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		RegisterRecords.LineOfBusiness,
	|		RegisterRecords.ExpenseItem,
	|		RegisterRecords.DimensionOfExpenses,
	|		-RegisterRecords.Sum,
	|		-RegisterRecords.AmountExcludingVAT,
	|		-RegisterRecords.SumCompl,
	|		-RegisterRecords.PermanentDifference,
	|		-RegisterRecords.CostTD,
	|		-RegisterRecords.AITAmount,
	|		-RegisterRecords.SumMan,
	|		-RegisterRecords.SumCompl,
	|		-RegisterRecords.PermanentDifference,
	|		-RegisterRecords.CostTD,
	|		-RegisterRecords.AITAmount,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	FROM
	|		AccumulationRegister.OtherExpenses AS RegisterRecords
	|			INNER JOIN Catalog.CostCenters AS ConstCenter
	|			ON RegisterRecords.DimensionOfExpenses = ConstCenter.Ref
	|	WHERE
	|		RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND RegisterRecords.Active
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND VALUETYPE(RegisterRecords.Recorder) = TYPE(Document.AllocationOfOtherCosts)
	|		AND RegisterRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
	|		AND (&ByAllCompanies
	|			OR RegisterRecords.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR RegisterRecords.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	#Region TextTransitOfExpensesBetweenSPoColumn
	TextTransitOfExpensesBetweenSPoColumn = "
	|	 SELECT 
	|		//Settings for ""Textransit spending between every Typograph"",
	|	 	Expenses.Organization,
	|	 	Expenses.DebitBusinessUnit,
	|	 	Expenses.LineOfBusiness,
	|	 	Expenses.ExpenseItem,
	|	 	Expenses.CorExpenditureDimension,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|	 	0,
	|		0 AS EstimatedQuantity,
	|		TRUE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	 FROM
	|	 	TTTransitOfExpensesBetweenHIA AS Expenses
	|	 		INNER JOIN OVZKDistribution AS OVZKDistribution
	|	 			ON Expenses.CorExpenditureDimension = OVZKDistribution.ConstCenter
	|";
	TextTransitOfExpensesBetweenCostCenterByColumnAIT = CalculationOfCostLocalization.TextTransitOfExpensesBetweenCostCenterByColumnAIT();
	#EndRegion
	
	#Region TextOfStornoOfProductionCosts
	TextOfStornoOfProductionCosts = "
	|	SELECT
	|		//""Textstory Production Costs"" settings,
	|		RegisterRecords.Organization,
	|		RegisterRecords.Department,
	|		ProductionLots.LineOfBusiness AS LineOfBusiness,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.ProductionCostsReverseTransaction) AS ExpenseItem,
	|		ProductionLots.MainProductProducts AS DimensionOfExpenses,
	|		0 AS Sum,
	|		0 AS AmountExcludingVAT,
	|		0 AS SumCompl,
	|		0 AS PermanentDifference,
	|		0 AS CostTD,
	|		0 AS AITAmount,
	|		0 AS SumMan,
	|		0 AS SumComplExpense,
	|		0 AS PermanentDifferenceExpense,
	|		0 AS CostTDExpense,
	|		0 AS AITAmountExpense,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef) AS DirectionOfActivityForCommunication,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureForCommunication
	|	FROM
	|		AccumulationRegister.WIPLaborCosts AS RegisterRecords
	|		INNER JOIN Catalog.ProductionLots AS ProductionLots
	|			ON ProductionLots.Ref = RegisterRecords.ProductionLot
	|	WHERE
	|		RegisterRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND RegisterRecords.Active
	|		AND VALUETYPE(RegisterRecords.Recorder) = TYPE(Document.ReversingEntry) 
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (&ByAllCompanies
	|			OR RegisterRecords.Organization IN (&CompanyArray))
	|		AND (&ByAllBusinessUnits
	|			OR RegisterRecords.Department IN (&DepartmentList))
	|";
	#EndRegion
	
	QueryTexts = New Array;
	QueryTexts.Add(TextDescriptionOfData);
	
	QueryTexts.Add(TextBalancesOfOtherManSExpenses);
	QueryTexts.Add(TextBalancesOfOtherLocalExpenses);
	QueryTexts.Add(TextBalancesOfOtherExpensesTa);
	QueryTexts.Add(TextBalancesOfOtherExpensesAIT);
	
	QueryTexts.Add(TextOfMovementOfOtherExpensesOfMan);
	QueryTexts.Add(TextOfMovementOfOtherLocalExpenses);
	QueryTexts.Add(TextOfMovementOfOtherExpensesTa);
	QueryTexts.Add(AITTextOfRegisteredRecordsOfOtherExpenses);
	
	QueryTexts.Add(TextOfMovementOfLotsOfOtherExpensesMen);
	QueryTexts.Add(TextOfMovementOfLotsOfOtherExpensesLocal);
	QueryTexts.Add(TextOfMovementOfLotsOfOtherExpensesTA);
	QueryTexts.Add(AITTextOfPartySRegisteredRecordsOfOtherExpenses);
	
	QueryTexts.Add(TextWriteOffInventoryAllocation);
	QueryTexts.Add(TextWriteOffDistributionOfTrademarkToAnotherOrganization);
	QueryTexts.Add(TextOfMovementOnCostOfProductionOfMan);
	QueryTexts.Add(TextOfMovementOnCostOfProductionOfLocal);
	QueryTexts.Add(TextOfMovementOnCostOfProductionTa);
	QueryTexts.Add(AITTextOfRegisteredRecordsForCostOfProduction);
	QueryTexts.Add(TextMaterialsAndWorks_);
	QueryTexts.Add(TextOfMovementOfOtherExpensesOfSecondaryContourOfMan);
	QueryTexts.Add(TextOfMovementOfOtherExpensesOfSecondaryLocalPolygon);
	QueryTexts.Add(TextOfMovementOfOtherExpensesOfSecondaryPolygonTa);
	QueryTexts.Add(AITTextOfRegisteredRecordsOfOtherExpensesOfSecondaryContour);
	
	QueryTexts.Add(TextOfStornoOfProductionCosts);
	
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		QueryTexts.Add(TextBalancesOfOtherExpensesOfHIAMan);
		QueryTexts.Add(TextBalancesOfOtherExpensesOfHIALocal);
		QueryTexts.Add(TextBalancesOfOtherExpensesOfOVZNU);
		QueryTexts.Add(TextBalancesOfOtherExpensesOfInternalRevenueService);
		QueryTexts.Add(TextOfMovementOfOtherExpensesFromHIAMan);
		QueryTexts.Add(TextOfMovementOfOtherExpensesFromHIALocal);
		QueryTexts.Add(TextOfMovementOfOtherExpensesFromOVZNU);
		QueryTexts.Add(TextOfRegisteredRecordsOfOtherExpensesFromAIT);
		QueryTexts.Add(TextWriteOffDistributionOfInventoryForHIA);
		QueryTexts.Add(TextMaterialsAndWorksOnHIA);
		QueryTexts.Add(TextOfMovementOfOtherExpensesBetweenHIAExpenses);
		QueryTexts.Add(TextOfMovementOfOtherExpensesBetweenHIAParish);
		If CalculationOption = "ActualCalculation" Then
			QueryTexts.Add(TextTransitOfExpensesBetweenSPoColumn);
			QueryTexts.Add(TextTransitOfExpensesBetweenCostCenterByColumnAIT);
		EndIf;
		
	EndIf;
	Return StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin())
	
EndFunction

Function ReplacementPattern()
	
	ReturnStructure = New Structure;
	
	ItemsOfExpenditureForDistributionOfMan = New Map;
	ItemsOfExpenditureForDistributionOfMan.Insert("ItemsOfExpenditureToBeDistributed", "ItemsOfExpenditureForDistributionOfMan");
	ReturnStructure.Insert("ItemsOfExpenditureForDistributionOfMan", ItemsOfExpenditureForDistributionOfMan);
	
	ExpenditureItemsForLocalDistribution = New Map;
	ExpenditureItemsForLocalDistribution.Insert("ItemsOfExpenditureToBeDistributed", "ExpenditureItemsForLocalDistribution");
	ReturnStructure.Insert("ExpenditureItemsForLocalDistribution", ExpenditureItemsForLocalDistribution);
	
	ItemsOfExpenditureToBeAllocatedTa = New Map;
	ItemsOfExpenditureToBeAllocatedTa.Insert("ItemsOfExpenditureToBeDistributed", "ExpenditureItemsForLocalDistribution");
	ReturnStructure.Insert("ExpenditureItemsForLocalDistribution", ExpenditureItemsForLocalDistribution);
	
	TextBalancesOfOtherManSExpenses = New Map;
	TextBalancesOfOtherManSExpenses.Insert("Expenses.SumComplBalance,", "0,");
	TextBalancesOfOtherManSExpenses.Insert("Expenses.PermanentDifferenceBalance,", "0,");
	TextBalancesOfOtherManSExpenses.Insert("Expenses.CostTDBalance,", "0,");
	TextBalancesOfOtherManSExpenses.Insert("Expenses.AITAmountBalance,", "0,");
	TextBalancesOfOtherManSExpenses.Insert("Expenses.AITAmount,", "0,");
	TextBalancesOfOtherManSExpenses.Insert("ItemsOfExpenditureToBeDistributed", "ItemsOfExpenditureForDistributionOfMan");
	TextBalancesOfOtherManSExpenses.Insert("ArticlesCO", "ArticlesCOMan");
	TextBalancesOfOtherManSExpenses.Insert("OVZKDistribution", "OVZKManDistribution");
	ReturnStructure.Insert("TextBalancesOfOtherManSExpenses", TextBalancesOfOtherManSExpenses);
	
	TextBalancesOfOtherLocalExpenses = New Map;
	TextBalancesOfOtherLocalExpenses.Insert("Expenses.SumBalance,", "0,");
	TextBalancesOfOtherLocalExpenses.Insert("Expenses.AmountExcludingVATBalance,", "0,");
	TextBalancesOfOtherLocalExpenses.Insert("Expenses.SumManBalance,", "0,");
	TextBalancesOfOtherLocalExpenses.Insert("Expenses.CostTDBalance,", "Expenses.SumComplBalance - Expenses.PermanentDifferenceBalance ,"); // space before comma to exclude substitution
	TextBalancesOfOtherLocalExpenses.Insert("Expenses.AITAmountBalance,", "0,");
	TextBalancesOfOtherLocalExpenses.Insert("Expenses.AITAmount,", "0,"); 
	TextBalancesOfOtherLocalExpenses.Insert("ItemsOfExpenditureToBeDistributed", "ExpenditureItemsForLocalDistribution");
	TextBalancesOfOtherLocalExpenses.Insert("ArticlesCO", "ArticlesCOLocal");
	TextBalancesOfOtherLocalExpenses.Insert("OVZKDistribution", "OVZKLocalDistribution");
	ReturnStructure.Insert("TextBalancesOfOtherLocalExpenses", TextBalancesOfOtherLocalExpenses);
	
	TextBalancesOfOtherExpensesTa = New Map;
	TextBalancesOfOtherExpensesTa.Insert("Expenses.SumBalance,", "0,");
	TextBalancesOfOtherExpensesTa.Insert("Expenses.AmountExcludingVATBalance,", "0,");
	TextBalancesOfOtherExpensesTa.Insert("Expenses.SumManBalance,", "0,");
	TextBalancesOfOtherExpensesTa.Insert("Expenses.SumComplBalance,", "0,");
	TextBalancesOfOtherExpensesTa.Insert("Expenses.PermanentDifferenceBalance,", "0,");
	TextBalancesOfOtherExpensesTa.Insert("Expenses.CostTDBalance,", "Expenses.PermanentDifferenceBalance + Expenses.CostTDBalance - Expenses.SumComplBalance ,"); // space before comma to exclude substitution
	TextBalancesOfOtherExpensesTa.Insert("Expenses.AITAmountBalance,", "0,");
	TextBalancesOfOtherExpensesTa.Insert("Expenses.AITAmount,", "0,"); 
	TextBalancesOfOtherExpensesTa.Insert("ItemsOfExpenditureToBeDistributed", "ItemsOfExpenditureToBeAllocatedTa");
	TextBalancesOfOtherExpensesTa.Insert("ArticlesCO", "ArticlesCOTA");
	TextBalancesOfOtherExpensesTa.Insert("OVZKDistribution", "OVZKDistributionTa");
	ReturnStructure.Insert("TextBalancesOfOtherExpensesTa", TextBalancesOfOtherExpensesTa);
	
	TextBalancesOfOtherExpensesAIT = New Map;
	TextBalancesOfOtherExpensesAIT.Insert("Expenses.SumBalance,", "0,");
	TextBalancesOfOtherExpensesAIT.Insert("Expenses.AmountExcludingVATBalance,", "0,");
	TextBalancesOfOtherExpensesAIT.Insert("Expenses.SumManBalance,", "0,");
	TextBalancesOfOtherExpensesAIT.Insert("Expenses.SumComplBalance,", "0,");
	TextBalancesOfOtherExpensesAIT.Insert("Expenses.PermanentDifferenceBalance,", "0,");
	TextBalancesOfOtherExpensesAIT.Insert("Expenses.CostTDBalance,", "0,");
	TextBalancesOfOtherExpensesAIT.Insert("ItemsOfExpenditureToBeDistributed", "ItemsOfExpensesForAITDistribution");
	TextBalancesOfOtherExpensesAIT.Insert("OVZKDistribution", "CostCentersToAITDistribution");
	ReturnStructure.Insert("TextBalancesOfOtherExpensesAIT", TextBalancesOfOtherExpensesAIT);
	
	TextOfMovementOfOtherExpensesOfMan = New Map;
	TextOfMovementOfOtherExpensesOfMan.Insert("RegisterRecords.SumCompl,", "0,");
	TextOfMovementOfOtherExpensesOfMan.Insert("RegisterRecords.PermanentDifference,", "0,");
	TextOfMovementOfOtherExpensesOfMan.Insert("RegisterRecords.CostTD,", "0,");
	TextOfMovementOfOtherExpensesOfMan.Insert("RegisterRecords.AITAmount,", "0,");
	TextOfMovementOfOtherExpensesOfMan.Insert("ItemsOfExpenditureToBeDistributed", "ItemsOfExpenditureForDistributionOfMan");
	TextOfMovementOfOtherExpensesOfMan.Insert("OVZKDistribution", "OVZKManDistribution");
	TextOfMovementOfOtherExpensesOfMan.Insert("TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure",
		"TTOfRegisteredRecordsOfOtherExpensesByManSExpenseItems");
	ReturnStructure.Insert("TextOfMovementOfOtherExpensesOfMan", TextOfMovementOfOtherExpensesOfMan);
	
	TextOfMovementOfOtherLocalExpenses = New Map;
	TextOfMovementOfOtherLocalExpenses.Insert("RegisterRecords.Sum,", "0,");
	TextOfMovementOfOtherLocalExpenses.Insert("RegisterRecords.AmountExcludingVAT,", "0,");
	TextOfMovementOfOtherLocalExpenses.Insert("RegisterRecords.SumMan,", "0,");
	TextOfMovementOfOtherLocalExpenses.Insert("RegisterRecords.CostTD,", "RegisterRecords.SumCompl - RegisterRecords.PermanentDifference ,"); // space before comma to exclude substitution
	TextOfMovementOfOtherLocalExpenses.Insert("RegisterRecords.AITAmount,", "0,");
	TextOfMovementOfOtherLocalExpenses.Insert("ItemsOfExpenditureToBeDistributed", "ExpenditureItemsForLocalDistribution");
	TextOfMovementOfOtherLocalExpenses.Insert("OVZKDistribution", "OVZKLocalDistribution");
	TextOfMovementOfOtherLocalExpenses.Insert("TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure",
		"TTOfRegisteredRecordedOtherExpensesByLocalExpenditureItems");
	ReturnStructure.Insert("TextOfMovementOfOtherLocalExpenses", TextOfMovementOfOtherLocalExpenses);
	TextOfMovementOfOtherExpensesTa = New Map;
	TextOfMovementOfOtherExpensesTa.Insert("RegisterRecords.Sum,", "0,");
	TextOfMovementOfOtherExpensesTa.Insert("RegisterRecords.AmountExcludingVAT,", "0,");
	TextOfMovementOfOtherExpensesTa.Insert("RegisterRecords.SumMan,", "0,");
	TextOfMovementOfOtherExpensesTa.Insert("RegisterRecords.SumCompl,", "0,");
	TextOfMovementOfOtherExpensesTa.Insert("RegisterRecords.PermanentDifference,", "0,");
	TextOfMovementOfOtherExpensesTa.Insert("RegisterRecords.CostTD,", "RegisterRecords.PermanentDifference + RegisterRecords.CostTD - RegisterRecords.SumCompl ,"); // space before comma to exclude substitution 
	TextOfMovementOfOtherExpensesTa.Insert("RegisterRecords.AITAmount,", "0,");
	TextOfMovementOfOtherExpensesTa.Insert("ItemsOfExpenditureToBeDistributed", "ItemsOfExpenditureToBeAllocatedTa");
	TextOfMovementOfOtherExpensesTa.Insert("OVZKDistribution", "OVZKDistributionTa");
	TextOfMovementOfOtherExpensesTa.Insert("TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure",
		"TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditureTA");
	ReturnStructure.Insert("TextOfMovementOfOtherExpensesTa", TextOfMovementOfOtherExpensesTa);
	AITTextOfRegisteredRecordsOfOtherExpenses = New Map;
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("RegisterRecords.Sum,", "0,");
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("RegisterRecords.AmountExcludingVAT,", "0,");
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("RegisterRecords.SumMan,", "0,");
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("RegisterRecords.SumCompl,", "0,");
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("RegisterRecords.PermanentDifference,", "0,");
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("RegisterRecords.CostTD,", "0,"); 
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("ItemsOfExpenditureToBeDistributed", "ItemsOfExpensesForAITDistribution");
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("OVZKDistribution", "CostCentersToAITDistribution");
	AITTextOfRegisteredRecordsOfOtherExpenses.Insert("TTOfRegisteredRecordedOtherExpensesByItemsOfExpenditure",
		"AITIsTTOfRegisteredRecordsOfOtherExpensesByItemsOfExpenditure");
	ReturnStructure.Insert("AITTextOfRegisteredRecordsOfOtherExpenses", AITTextOfRegisteredRecordsOfOtherExpenses);
	
	Return ReturnStructure
	
EndFunction

#EndRegion

#Region PostDistributionExpenses
// Returns the text of the subquery for getting data sources for other expenses.
//
// Returns:
//	String - query text.
//
Function RequestTextExpensesAfterDistributionSources() Export
	
	Return "
		|SELECT
		|//Settings for ""Up-to-date statistics for the end of the month"" AS A requestsource,
		|		Unallocated_.Organization AS Organization,
		|		Unallocated_.Department AS Department,
		|		Unallocated_.ExpenseItem AS ExpenseItem,
		|		Unallocated_.DimensionOfExpenses AS DimensionOfExpenses,
		|		Unallocated_.LineOfBusiness AS LineOfBusiness,
		|		ARTICLES__.CostAllocationOptionManag,
		|		ARTICLES__.CostAllocationOptionLocal,
		|		ARTICLES__.CostAllocationOptionTax,
		|		AITArticleDistributionSettings.AITCostAllocationOption,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionManag IN (&CostAllocationOptions)
		|					OR ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				THEN 0
		|			ELSE
		|				Unallocated_.SumBalance
		|		END AS SumBalance,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionManag IN (&CostAllocationOptions)
		|					OR ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				THEN 0
		|			ELSE
		|				Unallocated_.AmountExcludingVATBalance
		|		END AS AmountExcludingVATBalance,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionManag IN (&CostAllocationOptions)
		|					OR ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				THEN 0
		|			ELSE
		|				Unallocated_.SumManBalance
		|		END AS SumManBalance,
		|		CASE
		|			WHEN ARTICLES__.CostAllocationOptionTax IN (&CostAllocationOptions)
		|				THEN Unallocated_.SumComplBalance - Unallocated_.PermanentDifferenceBalance - Unallocated_.CostTDBalance
		|			ELSE
		|				0
		|		END +
		|		0 AS AmountFABalance,
		|		CASE
		|			WHEN AITArticleDistributionSettings.AITCostAllocationOption IN (&CostAllocationOptions)
		|				THEN Unallocated_.AITAmountBalance
		|			ELSE
		|				0
		|		END AS AITAmountBalance,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|					OR ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				THEN 0
		|			ELSE
		|				Unallocated_.SumComplBalance
		|		END AS SumComplBalance,
		|		CASE
		|			WHEN &ExcludeDifferencesFromControl
		|				THEN 0
		|			WHEN NOT ARTICLES__.CostAllocationOptionTax IN (&CostAllocationOptions)
		|					OR ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				THEN 0
		|			ELSE
		|				Unallocated_.PermanentDifferenceBalance
		|		END +
		|		0 AS PermanentDifferenceBalance,
		|		FALSE AS ThereIsErrorInCalculationOfMa,
		|		FALSE AS ThereIsErrorInCalculationOfAC,
		|		FALSE AS ThereIsCalculationErrorTa,
		|		FALSE AS ThereIsErrorInAITCalculation
		|//The SETTINGS should BE PLACED in the source of UNALLOCATED EXPENSES
		|	FROM
		|		ExpensesForDistributionAreSummarizedArticleIsFilledIn AS ExpensesForDistributionAreSummarized
		|
		|		INNER JOIN TTOtherExpenses_Balance AS Unallocated_
		|		ON ExpensesForDistributionAreSummarized.Organization = Unallocated_.Organization
		|			AND ExpensesForDistributionAreSummarized.Department = Unallocated_.Department
		|			AND ExpensesForDistributionAreSummarized.LineOfBusiness = Unallocated_.LineOfBusiness
		|			AND ExpensesForDistributionAreSummarized.ExpenseItem = Unallocated_.ExpenseItem
		|			AND ExpensesForDistributionAreSummarized.DimensionOfExpenses = Unallocated_.DimensionOfExpenses
		|
		|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ExpensesForDistributionAreSummarized.ExpenseItem = ARTICLES__.Ref
		|
		|			LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|			ON Unallocated_.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|				AND &NonDistributed_SeparateAccountingObjectAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|				AND Unallocated_.Organization = AITArticleDistributionSettings.Organization
		|		LEFT JOIN TTShareOfWriteOffOfIndirectExpenses AS WriteOffShares
		|		ON Unallocated_.ExpenseItem = WriteOffShares.ExpenseItem
		|			AND Unallocated_.Organization = WriteOffShares.Organization
		|		LEFT JOIN RationingOnAccountsAccounts AS RationingOnAccountsAccounts
		|		ON Unallocated_.Organization = RationingOnAccountsAccounts.Organization
		|			AND Unallocated_.Department = RationingOnAccountsAccounts.Department
		|			AND Unallocated_.LineOfBusiness = RationingOnAccountsAccounts.LineOfBusiness
		|			AND Unallocated_.ExpenseItem = RationingOnAccountsAccounts.ExpenseItem
		|			AND Unallocated_.DimensionOfExpenses = RationingOnAccountsAccounts.DimensionOfExpenses
		|		
		|	UNION ALL
		|	
		|	SELECT
		|//Settings for ""correctioncanafixableeostatkinzp"" AS A request source,
		|		Expenses.Organization,
		|		Expenses.Department,
		|		Expenses.ExpenseItem,
		|		Expenses.DimensionOfExpenses,
		|		Expenses.LineOfBusiness,
		|		ARTICLES__.CostAllocationOptionManag,
		|		ARTICLES__.CostAllocationOptionLocal,
		|		ARTICLES__.CostAllocationOptionTax,
		|		AITArticleDistributionSettings.AITCostAllocationOption,
		|		CASE
		|			WHEN NOT MaDistributionDocuments.Document IS NULL
		|				THEN -Expenses.Sum * MaDistributionDocuments.CostShareOfWIP / MaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN NOT MaDistributionDocuments.Document IS NULL
		|				THEN -Expenses.AmountExcludingVAT * MaDistributionDocuments.CostShareOfWIP / MaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN NOT MaDistributionDocuments.Document IS NULL
		|				THEN -Expenses.SumMan * MaDistributionDocuments.CostShareOfWIP / MaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN NOT TaDistributionDocuments.Document IS NULL
		|				THEN (
		|					CASE
		|						WHEN TaDistributionDocuments.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|							AND ARTICLES__.CostAllocationOptionTax = ARTICLES__.CostAllocationOptionLocal
		|						THEN 
		|							Expenses.SumCompl - Expenses.PermanentDifference - Expenses.CostTD
		|						ELSE
		|							0
		|					END) * TaDistributionDocuments.CostShareOfWIP / TaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END * -1,
		|		CASE
		|			WHEN NOT AITDistributionDocuments.Document IS NULL
		|				THEN (
		|					CASE
		|						WHEN AITDistributionDocuments.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|							AND AITArticleDistributionSettings.AITCostAllocationOption = ARTICLES__.CostAllocationOptionLocal
		|						THEN 
		|							Expenses.AITAmount
		|						ELSE
		|							0
		|					END) * AITDistributionDocuments.CostShareOfWIP / AITDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END * -1,
		|		CASE
		|			WHEN NOT ACDistributionDocuments.Document IS NULL
		|				THEN -Expenses.SumCompl * ACDistributionDocuments.CostShareOfWIP / ACDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN &ExcludeDifferencesFromControl
		|				THEN 0
		|			WHEN NOT ACDistributionDocuments.Document IS NULL
		|				THEN -Expenses.PermanentDifference * ACDistributionDocuments.CostShareOfWIP / ACDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		(NOT MaDistributionDocuments.Document IS NULL),
		|		(NOT ACDistributionDocuments.Document IS NULL),
		|		(NOT TaDistributionDocuments.Document IS NULL),
		|		(NOT AITDistributionDocuments.Document IS NULL)
		|	FROM
		|		ExpensesForDistributionAreSummarized AS Expenses
		|			INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|			ON Expenses.ExpenseItem = ARTICLES__.Ref
		|			LEFT JOIN DistributionDocuments AS MaDistributionDocuments
		|			ON Expenses.Organization = MaDistributionDocuments.Organization
		|				AND Expenses.Department = MaDistributionDocuments.Department
		|				AND Expenses.LineOfBusiness = MaDistributionDocuments.LineOfBusiness
		|				AND Expenses.ExpenseItem = MaDistributionDocuments.ExpenseItem
		|				AND Expenses.DimensionOfExpenses = MaDistributionDocuments.DimensionOfExpenses
		|				AND MaDistributionDocuments.ManagementAccounting
		|				AND (MaDistributionDocuments.LeaveAsWIP)
		|			LEFT JOIN DistributionDocuments AS ACDistributionDocuments
		|			ON Expenses.Organization = ACDistributionDocuments.Organization
		|				AND Expenses.Department = ACDistributionDocuments.Department
		|				AND Expenses.LineOfBusiness = ACDistributionDocuments.LineOfBusiness
		|				AND Expenses.ExpenseItem = ACDistributionDocuments.ExpenseItem
		|				AND Expenses.DimensionOfExpenses = ACDistributionDocuments.DimensionOfExpenses
		|				AND ACDistributionDocuments.LocalAccounting
		|				AND (ACDistributionDocuments.LeaveAsWIP)
		|			LEFT JOIN DistributionDocuments AS TaDistributionDocuments
		|			ON Expenses.Organization = TaDistributionDocuments.Organization
		|				AND Expenses.Department = TaDistributionDocuments.Department
		|				AND Expenses.LineOfBusiness = TaDistributionDocuments.LineOfBusiness
		|				AND Expenses.ExpenseItem = TaDistributionDocuments.ExpenseItem
		|				AND Expenses.DimensionOfExpenses = TaDistributionDocuments.DimensionOfExpenses
		|				AND TaDistributionDocuments.TaxAccounting
		|				AND (TaDistributionDocuments.LeaveAsWIP)
		|			LEFT JOIN DistributionDocuments AS AITDistributionDocuments
		|			ON Expenses.Organization = AITDistributionDocuments.Organization
		|				AND Expenses.Department = AITDistributionDocuments.Department
		|				AND Expenses.LineOfBusiness = AITDistributionDocuments.LineOfBusiness
		|				AND Expenses.ExpenseItem = AITDistributionDocuments.ExpenseItem
		|				AND Expenses.DimensionOfExpenses = AITDistributionDocuments.DimensionOfExpenses
		|				AND AITDistributionDocuments.AIT
		|				AND (AITDistributionDocuments.LeaveAsWIP)
		|			LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|			ON Expenses.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|				AND &Expenses_ObjectOfSeparateAccountingAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|				AND Expenses.Organization = AITArticleDistributionSettings.Organization
		|	WHERE
		|		NOT MaDistributionDocuments.Document IS NULL
		|		OR NOT ACDistributionDocuments.Document IS NULL
		|		OR NOT TaDistributionDocuments.Document IS NULL
		|		OR NOT AITDistributionDocuments.Document IS NULL
		|	
		|	UNION ALL
		|	
		|	SELECT
		|//Settings for ""Correctioncanormalization of expenditures"" AS A requestsource,
		|		Expenses.Organization,
		|		Expenses.Department,
		|		Expenses.ExpenseItem,
		|		Expenses.DimensionOfExpenses,
		|		Expenses.LineOfBusiness,
		|		ARTICLES__.CostAllocationOptionManag,
		|		ARTICLES__.CostAllocationOptionLocal,
		|		ARTICLES__.CostAllocationOptionTax,
		|		AITArticleDistributionSettings.AITCostAllocationOption,
		|		0 AS SumBalance,
		|		0 AS AmountExcludingVATBalance,
		|		0 AS SumManBalance,
		|		CASE
		|			WHEN NOT WriteOffShares.Transportation
		|				THEN 0
		|			ELSE
		|				CAST((Expenses.SumCompl - Expenses.PermanentDifference - Expenses.CostTD) * (WriteOffShares.PercentageOfWriteOffs - 1) AS NUMBER(31, 2))
		|		END AS AmountFABalance,
		|		CASE
		|			WHEN NOT WriteOffShares.Transportation
		|				THEN 0
		|			ELSE
		|				CAST((Expenses.AITAmount) * (WriteOffShares.PercentageOfWriteOffs - 1) AS NUMBER(31, 2))
		|		END AS AITAmountBalance,
		|		CASE
		|			WHEN NOT WriteOffShares.Transportation
		|				THEN 0
		|			ELSE
		|				CAST(Expenses.SumCompl * (WriteOffShares.PercentageOfWriteOffs - 1) AS NUMBER(31, 2))
		|		END AS SumComplBalance,
		|		CASE
		|			WHEN NOT WriteOffShares.Transportation
		|				THEN 0
		|			ELSE
		|				CAST(Expenses.PermanentDifference * (WriteOffShares.PercentageOfWriteOffs - 1) AS NUMBER(31, 2))
		|		END AS PermanentDifferenceBalance,
		|		FALSE,
		|		CASE
		|			WHEN CAST(Expenses.SumCompl * WriteOffShares.PercentageOfWriteOffs AS NUMBER(31, 2)) = 0
		|				AND CAST(Expenses.PermanentDifference * WriteOffShares.PercentageOfWriteOffs AS NUMBER(31, 2)) = 0
		|			THEN FALSE
		|			ELSE 
		|				ISNULL(PossibleRegisteredRecords.ThereAreRegisteredRecordsOnFinancialResultOfLocal, FALSE)
		|		END,
		|		CASE
		|			WHEN CAST(
		|				(Expenses.SumCompl - Expenses.PermanentDifference - Expenses.CostTD) * WriteOffShares.PercentageOfWriteOffs AS NUMBER(31, 2)) = 0
		|			THEN FALSE
		|			ELSE 
		|				ISNULL(PossibleRegisteredRecords.ThereAreRegisteredRecordsOnFinancialResultOfNal, FALSE)
		|		END,
		|		CASE
		|			WHEN CAST(
		|				(Expenses.AITAmount) * WriteOffShares.PercentageOfWriteOffs AS NUMBER(31, 2)) = 0
		|			THEN FALSE
		|			ELSE 
		|				ISNULL(PossibleRegisteredRecords.ThereIsRegisteredRecordOfProfitabilityAndCostOfAIT, FALSE)
		|		END
		|	FROM
		|		ExpenseForAllocation AS Expenses
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON Expenses.ExpenseItem = ARTICLES__.Ref
		|		INNER JOIN TTShareOfWriteOffOfIndirectExpenses AS WriteOffShares
		|		ON Expenses.ExpenseItem = WriteOffShares.ExpenseItem
		|			AND Expenses.Organization = WriteOffShares.Organization
		|		LEFT JOIN RegisteredRecordsOfExpenditureItems AS PossibleRegisteredRecords
		|		ON Expenses.Organization = PossibleRegisteredRecords.Organization
		|			AND Expenses.Department = PossibleRegisteredRecords.Department
		|			AND Expenses.LineOfBusiness = PossibleRegisteredRecords.LineOfBusiness
		|			AND Expenses.ExpenseItem = PossibleRegisteredRecords.ExpenseItem
		|			AND Expenses.DimensionOfExpenses = PossibleRegisteredRecords.DimensionOfExpenses
		|		LEFT JOIN AITArticleDistributionSettings AS AITArticleDistributionSettings
		|		ON Expenses.ExpenseItem = AITArticleDistributionSettings.ExpenseItem
		|			AND &Expenses_ObjectOfSeparateAccountingAIT = AITArticleDistributionSettings.ObjectOfSeparateAccountingAIT
		|			AND Expenses.Organization = AITArticleDistributionSettings.Organization
		|
		|	UNION ALL
		|	
		|	SELECT
		|//Settings for ""Up-to-date statistics for the end of the month"" AS A requestersource,
		|		Unallocated_.Organization AS Organization,
		|		Unallocated_.Department AS Department,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|		Unallocated_.DimensionOfExpenses AS DimensionOfExpenses,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|		T.CostAllocationOptionManag,
		|		T.CostAllocationOptionLocal,
		|		T.CostAllocationOptionTax,
		|		AITArticleDistributionSettings.AITCostAllocationOption,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|					OR NOT T.CostAllocationOptionManag IN (&CostAllocationOptions)
		|				THEN 0
		|			ELSE
		|				Unallocated_.SumBalance
		|		END AS SumBalance,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|					OR NOT T.CostAllocationOptionManag IN (&CostAllocationOptions)
		|				THEN 0
		|			ELSE
		|				Unallocated_.AmountExcludingVATBalance
		|		END AS AmountExcludingVATBalance,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|					OR NOT T.CostAllocationOptionManag IN (&CostAllocationOptions)
		|				THEN 0
		|			ELSE
		|				Unallocated_.SumManBalance
		|		END AS SumManBalance,
		|		CASE
		|			WHEN &ExcludeDifferencesFromControl
		|				THEN 0
		|			WHEN NOT ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|					OR NOT T.CostAllocationOptionTax IN (&CostAllocationOptions)
		|				THEN 0
		|			ELSE
		|				Unallocated_.SumComplBalance - Unallocated_.PermanentDifferenceBalance - Unallocated_.CostTDBalance
		|		END AS AmountFABalance,
		|		CASE
		|			WHEN NOT (ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|					OR ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters))
		|				THEN 0
		|			WHEN NOT AITArticleDistributionSettings.AITCostAllocationOption IN (&CostAllocationOptions)
		|				THEN 0
		|			ELSE
		|				Unallocated_.AITAmountBalance
		|		END AS AITAmountBalance,
		|		CASE
		|			WHEN NOT ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|					OR NOT T.CostAllocationOptionLocal IN (&CostAllocationOptions)
		|				THEN 0
		|			ELSE
		|				Unallocated_.SumComplBalance
		|		END AS SumComplBalance,
		|		CASE
		|			WHEN &ExcludeDifferencesFromControl
		|				THEN 0
		|			WHEN ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|					AND T.CostAllocationOptionTax IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|														 VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness))
		|				THEN Unallocated_.PermanentDifferenceBalance
		|			ELSE
		|				0
		|		END AS PermanentDifferenceBalance,
		|		FALSE AS ThereIsErrorInCalculationOfMa,
		|		FALSE AS ThereIsErrorInCalculationOfAC,
		|		FALSE AS ThereIsCalculationErrorTa,
		|		FALSE AS ThereIsErrorInAITCalculation
		|	FROM
		|		ExpensesForDistributionAreSummarizedByHIA AS ExpensesForDistributionAreSummarized
		|
		|		INNER JOIN TTOtherExpenses_Balance AS Unallocated_
		|		ON ExpensesForDistributionAreSummarized.Organization = Unallocated_.Organization
		|			AND ExpensesForDistributionAreSummarized.Department = Unallocated_.Department
		|			AND ExpensesForDistributionAreSummarized.DimensionOfExpenses = Unallocated_.DimensionOfExpenses
		|
		|		LEFT JOIN Catalog.CostCenters AS T
		|			ON ExpensesForDistributionAreSummarized.DimensionOfExpenses = T.Ref
		|
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON Unallocated_.ExpenseItem = ARTICLES__.Ref
		|
		|		LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS AITArticleDistributionSettings
		|		ON Unallocated_.DimensionOfExpenses = AITArticleDistributionSettings.ConstCenter
		|		
		|	UNION ALL
		|	
		|	SELECT
		|//Settings for ""correctioncanafixableeostatkinzppoovz"" AS A request source,
		|		Expenses.Organization,
		|		Expenses.Department,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
		|		Expenses.DimensionOfExpenses,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
		|		T.CostAllocationOptionManag,
		|		T.CostAllocationOptionLocal,
		|		T.CostAllocationOptionTax,
		|		AITArticleDistributionSettings.AITCostAllocationOption,
		|		CASE
		|			WHEN NOT MaDistributionDocuments.Document IS NULL
		|				THEN -Expenses.Sum * MaDistributionDocuments.CostShareOfWIP / MaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN NOT MaDistributionDocuments.Document IS NULL
		|				THEN -Expenses.AmountExcludingVAT * MaDistributionDocuments.CostShareOfWIP / MaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN NOT MaDistributionDocuments.Document IS NULL
		|				THEN -Expenses.SumMan * MaDistributionDocuments.CostShareOfWIP / MaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN &ExcludeDifferencesFromControl
		|				THEN 0
		|			WHEN NOT TaDistributionDocuments.Document IS NULL
		|				THEN (
		|					CASE
		|						WHEN TaDistributionDocuments.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|							AND T.CostAllocationOptionTax = T.CostAllocationOptionLocal
		|						THEN 
		|							Expenses.SumCompl - Expenses.PermanentDifference - Expenses.CostTD
		|						ELSE
		|							0
		|					END) * TaDistributionDocuments.CostShareOfWIP / TaDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END * -1,
		|		CASE
		|			WHEN NOT AITDistributionDocuments.Document IS NULL
		|				THEN (
		|					CASE
		|						WHEN AITDistributionDocuments.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)
		|							AND AITArticleDistributionSettings.AITCostAllocationOption = T.CostAllocationOptionLocal
		|						THEN 
		|							Expenses.AITAmount
		|						ELSE
		|							0
		|					END) * AITDistributionDocuments.CostShareOfWIP / AITDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END * -1,
		|		CASE
		|			WHEN NOT ACDistributionDocuments.Document IS NULL
		|				THEN -Expenses.SumCompl * ACDistributionDocuments.CostShareOfWIP / ACDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		CASE
		|			WHEN &ExcludeDifferencesFromControl
		|				THEN 0
		|			WHEN NOT ACDistributionDocuments.Document IS NULL
		|				THEN -Expenses.PermanentDifference * ACDistributionDocuments.CostShareOfWIP / ACDistributionDocuments.TotalCostShares
		|			ELSE 0
		|		END,
		|		(NOT MaDistributionDocuments.Document IS NULL),
		|		(NOT ACDistributionDocuments.Document IS NULL),
		|		(NOT TaDistributionDocuments.Document IS NULL),
		|		(NOT AITDistributionDocuments.Document IS NULL)
		|	FROM
		|		ExpensesForDistributionAreSummarized AS Expenses
		|
		|			INNER JOIN ExpensesForDistributionAreSummarizedByHIA AS ExpensesForDistributionAreSummarizedByHIA
		|			ON Expenses.Organization = ExpensesForDistributionAreSummarizedByHIA.Organization
		|				AND Expenses.Department = ExpensesForDistributionAreSummarizedByHIA.Department
		|				AND Expenses.DimensionOfExpenses = ExpensesForDistributionAreSummarizedByHIA.DimensionOfExpenses
		|				AND Expenses.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|
		|			LEFT JOIN DistributionDocuments AS MaDistributionDocuments
		|			ON Expenses.Organization = MaDistributionDocuments.Organization
		|				AND Expenses.Department = MaDistributionDocuments.Department
		|				AND MaDistributionDocuments.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND Expenses.DimensionOfExpenses = MaDistributionDocuments.DimensionOfExpenses
		|				AND MaDistributionDocuments.ManagementAccounting
		|				AND (MaDistributionDocuments.LeaveAsWIP)
		|			LEFT JOIN DistributionDocuments AS ACDistributionDocuments
		|			ON Expenses.Organization = ACDistributionDocuments.Organization
		|				AND Expenses.Department = ACDistributionDocuments.Department
		|				AND ACDistributionDocuments.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND Expenses.DimensionOfExpenses = ACDistributionDocuments.DimensionOfExpenses
		|				AND ACDistributionDocuments.LocalAccounting
		|				AND (ACDistributionDocuments.LeaveAsWIP)
		|			LEFT JOIN DistributionDocuments AS TaDistributionDocuments
		|			ON Expenses.Organization = TaDistributionDocuments.Organization
		|				AND Expenses.Department = TaDistributionDocuments.Department
		|				AND TaDistributionDocuments.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND Expenses.DimensionOfExpenses = TaDistributionDocuments.DimensionOfExpenses
		|				AND TaDistributionDocuments.TaxAccounting
		|				AND (TaDistributionDocuments.LeaveAsWIP)
		|			LEFT JOIN DistributionDocuments AS AITDistributionDocuments
		|			ON Expenses.Organization = AITDistributionDocuments.Organization
		|				AND Expenses.Department = AITDistributionDocuments.Department
		|				AND AITDistributionDocuments.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|				AND Expenses.DimensionOfExpenses = AITDistributionDocuments.DimensionOfExpenses
		|				AND AITDistributionDocuments.AIT
		|				AND (AITDistributionDocuments.LeaveAsWIP)
		|
		|			LEFT JOIN Catalog.CostCenters AS T
		|			ON Expenses.DimensionOfExpenses = T.Ref
		|
		|			LEFT JOIN SettingsForDistributionOfAITArticlesByCostCenter AS AITArticleDistributionSettings
		|			ON Expenses.DimensionOfExpenses = AITArticleDistributionSettings.ConstCenter
		|
		|	WHERE
		|		NOT MaDistributionDocuments.Document IS NULL
		|		OR NOT ACDistributionDocuments.Document IS NULL
		|		OR NOT TaDistributionDocuments.Document IS NULL
		|		OR NOT AITDistributionDocuments.Document IS NULL
		|";
		
EndFunction
#EndRegion

#Region DocumentGeneration

Function FindRightDocument(DocumentsForHolding, AccountingKind, FillParameters)
	
	SuitableDocument = Undefined;
	
	For Each DocumentDistributions In DocumentsForHolding Do
		
		DocumentFound = False;
		
		If AccountingKind = "ManagementAccounting" Then
			If DocumentDistributions.LocalAccounting Then
				DocumentFound = CheckComplianceOfManLocalSettings(FillParameters);
			EndIf;
		ElsIf AccountingKind = "LocalAccounting" Then
			If DocumentDistributions.ManagementAccounting Then
				DocumentFound = CheckComplianceOfManLocalSettings(FillParameters);
			EndIf;
		
		
		ElsIf AccountingKind = "AIT" Then
			
			DocumentFound = AllocationOfOtherCostsLocalization.FindRightDocument(
				DocumentDistributions,
				AccountingKind,
				FillParameters
				);
			
		EndIf;
		
		If DocumentFound Then
			SuitableDocument = DocumentDistributions;
			Break;
		EndIf;
		
	EndDo;
	
	Return SuitableDocument;
	
EndFunction

Function CheckComplianceOfManLocalSettings(FillParameters)
	
	SettingsCorrespondTo = 
		Not CalculationOfCostCached.BatchAccountingVersion22(FillParameters.Date)
		And FillParameters.LocalDistributionOption = FillParameters.ManDistributionOption
		And FillParameters.LocalDistributionOption = Enums.CostAllocationOptions.ToProductionCosts
		Or FillParameters.LocalDistributionOption = FillParameters.ManDistributionOption
		And FillParameters.LocalDistributionRule = FillParameters.ManDistributionRule
		And FillParameters.DocumentMan = FillParameters.DocumentCompl;
		
	Return SettingsCorrespondTo;
	
EndFunction


Function GetDistributionSettingsForDocument(DocumentDistributions)
	
	SourceOfDistributionOptions = DocumentDistributions.ExpenseItem;
	
	CostAllocationFromCostCenter = False;
	If Not ValueIsFilled(SourceOfDistributionOptions)
			And TypeOf(DocumentDistributions.DimensionOfExpenses) = Type("CatalogRef.CostCenters")
	Then
		SourceOfDistributionOptions = DocumentDistributions.DimensionOfExpenses;
		CostAllocationFromCostCenter = True;
	EndIf;
	DistributionSettings = GeneralPurposeTMServerCall.ObjectAttributesValues(SourceOfDistributionOptions, 
		"CostAllocationOptionManag,CostAllocationOptionLocal,CostAllocationRuleManag,CostAllocationRuleLocal
		|");	
		

	If CalculationOfCostLocalization.GetFunctionalOptionAITAccounting() Then
		AITDistributionSettings = CalculationOfCostLocalization.GetDistributionSettingsForDocument(DocumentDistributions, CostAllocationFromCostCenter);
		If ValueIsFilled(AITDistributionSettings) Then
			DistributionSettings.Insert("AITCostAllocationOption", AITDistributionSettings.AITCostAllocationOption);
			DistributionSettings.Insert("CostAllocationRuleAIT", AITDistributionSettings.CostAllocationRuleAIT);
		Else
			DistributionSettings.Insert("AITCostAllocationOption", Enums.CostAllocationOptions.EmptyRef());
			DistributionSettings.Insert("CostAllocationRuleAIT", Catalogs.CostAllocationRules.EmptyRef());
		EndIf;
	EndIf;
	
	Return DistributionSettings;
	
EndFunction
	
#EndRegion

#Region QueriesTexts

#Region ExpenseAllocationToFinancialResult

Function TextPreliminaryBalancesOfExpenses()
	
	QueryText =
	"SELECT
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.SumBalance AS Sum,
	|	Expenses.AmountExcludingVATBalance AS AmountExcludingVAT,
	|	Expenses.SumComplBalance AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	Expenses.SumComplBalance - Expenses.PermanentDifferenceBalance - Expenses.CostTDBalance AS AmountFA,
	|	Expenses.SumManBalance AS SumMan
	|INTO PreliminaryExpenseBalances
	|FROM
	|	AccumulationRegister.OtherExpenses.Balance(
	|			&PeriodBoundary,
	|			(Organization, Department, LineOfBusiness, ExpenseItem, DimensionOfExpenses) IN
	|				(SELECT
	|					ConfiguredExpenses.Organization,
	|					ConfiguredExpenses.Department,
	|					ConfiguredExpenses.LineOfBusiness,
	|					ConfiguredExpenses.ExpenseItem,
	|					ConfiguredExpenses.DimensionOfExpenses
	|				FROM
	|					Recorders AS ConfiguredExpenses
	|				WHERE NOT ConfiguredExpenses.ThisIsOVZ
	|				)
	|			OR
	|			(Organization, Department, DimensionOfExpenses) IN
	|				(SELECT
	|					ConfiguredExpenses.Organization,
	|					ConfiguredExpenses.Department,
	|					ConfiguredExpenses.DimensionOfExpenses
	|				FROM
	|					Recorders AS ConfiguredExpenses
	|				WHERE ConfiguredExpenses.ThisIsOVZ
	|				)
	|) AS Expenses
	|
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	LineOfBusiness,
	|	Department,
	|	Organization";
	
	Return QueryText;
	
EndFunction

Function TextExpenseBalances(SourceDebuggingMode)
	
	NestedRequestTexts = New Array;
	
	#Region InitializationOfTemporaryTableExpenseBalancesPreliminary
	QueryText =
	"SELECT TOP 0
	|	//The ""Initialization"" tab mode AS A data SourceData,
	|	UNDEFINED AS Organization,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS AmountFA,
	|	0 AS SumMan
	|INTO ExpenseBalancesPreliminary";
	If SourceDebuggingMode Then
		NestedRequestTexts.Add(QueryText);
	EndIf;
	#EndRegion
	
	#Region PreliminaryExpenseBalances
	QueryText =
	"SELECT
	|	//Mode settings of ""Preliminary statistics of inputs"" AS A data SourceData,
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.Sum AS Sum,
	|	Expenses.AmountExcludingVAT AS AmountExcludingVAT,
	|	Expenses.SumCompl AS SumCompl,
	|	Expenses.PermanentDifference AS PermanentDifference,
	|	Expenses.CostTD AS CostTD,
	|	Expenses.AmountFA AS AmountFA,
	|	Expenses.SumMan AS SumMan
	|FROM PreliminaryExpenseBalances AS Expenses";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CurRegisteredRecords
	QueryText =
	"SELECT
	|	//Current Movement settings AS A DATA source,
	|	CurRegisteredRecords.Organization,
	|	CurRegisteredRecords.Department,
	|	CurRegisteredRecords.LineOfBusiness,
	|	CurRegisteredRecords.ExpenseItem,
	|	CurRegisteredRecords.DimensionOfExpenses,
	|	CurRegisteredRecords.Sum AS Sum,
	|	CurRegisteredRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|	CurRegisteredRecords.SumCompl AS SumCompl,
	|	CurRegisteredRecords.PermanentDifference AS PermanentDifference,
	|	CurRegisteredRecords.CostTD AS CostTD,
	|	CurRegisteredRecords.SumCompl - CurRegisteredRecords.PermanentDifference - CurRegisteredRecords.CostTD AS AmountFA,
	|	CurRegisteredRecords.SumMan AS SumMan
	|FROM
	|	PreliminaryExpenseBalances AS Balance
	|		INNER JOIN AccumulationRegister.OtherExpenses AS CurRegisteredRecords
	|		ON CurRegisteredRecords.Organization = Balance.Organization
	|			AND CurRegisteredRecords.Department = Balance.Department
	|			AND CurRegisteredRecords.LineOfBusiness = Balance.LineOfBusiness
	|			AND CurRegisteredRecords.ExpenseItem = Balance.ExpenseItem
	|			AND CurRegisteredRecords.DimensionOfExpenses = Balance.DimensionOfExpenses
	|		LEFT JOIN Document.AllocationOfOtherCosts AS DetailsOfDistributionDocument
	|		ON DetailsOfDistributionDocument.Ref = CurRegisteredRecords.Recorder
	|WHERE
	|	NOT &PreliminaryCalculation AND
	|	CurRegisteredRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CurRegisteredRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND CurRegisteredRecords.Active
	|	AND (
	//			The registrar is the document of the distribution of the total costs
	|			CurRegisteredRecords.Recorder REFS Document.AllocationOfOtherCosts
	|				AND CurRegisteredRecords.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness),
	|					VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA))

	//			The registrar is a document of income distributiondirectionsactivity
	|			OR CurRegisteredRecords.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|				AND CurRegisteredRecords.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
	|		)";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CurrentRegisteredRecordsOfSpecifiedDocument
	QueryText =
	"SELECT
	|	//The ""Current movement of the specified Document"" AS A data sourcesreferences,
	|	CurRegisteredRecords.Organization,
	|	CurRegisteredRecords.Department,
	|	CurRegisteredRecords.LineOfBusiness,
	|	CurRegisteredRecords.ExpenseItem,
	|	CurRegisteredRecords.DimensionOfExpenses,
	|	CurRegisteredRecords.Sum,
	|	CurRegisteredRecords.AmountExcludingVAT,
	|	CurRegisteredRecords.SumCompl,
	|	CurRegisteredRecords.PermanentDifference,
	|	CurRegisteredRecords.CostTD,
	|	CurRegisteredRecords.SumCompl
	|	- CurRegisteredRecords.PermanentDifference
	|	- CurRegisteredRecords.CostTD,
	|	CurRegisteredRecords.SumMan
	|FROM
	|	AccumulationRegister.OtherExpenses AS CurRegisteredRecords
	|WHERE
	|	&PreliminaryCalculation AND
	|	CurRegisteredRecords.Recorder = &DocumentDistributions";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	NestedQueryString = StrConcat(NestedRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
	"SELECT
	|	Expenses.Organization AS Organization,
	|	Expenses.Department AS Department,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(Expenses.Sum) AS Sum,
	|	SUM(Expenses.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(Expenses.SumCompl) AS SumCompl,
	|	SUM(Expenses.PermanentDifference) AS PermanentDifference,
	|	SUM(Expenses.CostTD) AS CostTD,
	|	SUM(Expenses.AmountFA) AS AmountFA,
	|	SUM(Expenses.SumMan) AS SumMan
	|INTO ExpenseBalances
	|FROM
	|	ExpenseBalancesPreliminary AS Expenses
	|
	|GROUP BY
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	Expenses.LineOfBusiness,
	|	Expenses.Department,
	|	Expenses.Organization
	|
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	LineOfBusiness,
	|	Department,
	|	Organization";
	
	If SourceDebuggingMode Then
		
		QueryTexts = New Array;
		QueryTexts.Add(NestedQueryString);
		QueryTexts.Add(QueryText);
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Else
		QueryText = StrReplace(QueryText, "ExpenseBalancesPreliminary", "(" + NestedQueryString + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction


// TT expenses for distribution: formation of Balances for distribution by LB
Function TextExpensesForDistribution(SourceDebuggingMode)
	
	NestedRequestTexts = New Array;
	
	#Region InitializationOfTemporaryTableExpensesForDistributionIsPreliminary
	QueryText =
	"SELECT TOP 0
	|	//The ""Initialization"" tab mode AS A data SourceData,
	|	UNDEFINED AS Organization,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS Date,
	|	UNDEFINED AS AllocationBaseType,
	|	FALSE AS CurrentPeriodExpenses,
	|	FALSE AS DistributionRequired
	|INTO ExpenseForAllocationPreliminary";
	If SourceDebuggingMode Then
		NestedRequestTexts.Add(QueryText);
	EndIf;
	#EndRegion
	
	// To the distribution of MA and AC
	#Region DistributionOfUUiAC
	QueryText =
	"SELECT
	|	//The ""Distribution UUIBU"" tab AS A data source,
	|	ExpenseBalances.Organization AS Organization,
	|	ExpenseBalances.Department AS Department,
	|	ExpenseBalances.LineOfBusiness AS LineOfBusiness,
	|	ExpenseBalances.ExpenseItem AS ExpenseItem,
	|	ExpenseBalances.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE
	|		WHEN NOT Recorders.ManagementAccounting
	|			OR NOT SettingsSource.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		ELSE ExpenseBalances.Sum
	|	END AS Sum,
	|	CASE
	|		WHEN NOT Recorders.ManagementAccounting
	|			OR NOT SettingsSource.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		ELSE ExpenseBalances.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|	CASE
	|		WHEN NOT Recorders.ManagementAccounting
	|			OR NOT SettingsSource.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		ELSE ExpenseBalances.SumMan
	|	END AS SumMan,
	|	CASE
	|		WHEN NOT Recorders.LocalAccounting
	|			OR NOT SettingsSource.CostAllocationOptionLocal IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		WHEN ISNULL(WriteOffShares.Transportation, FALSE)
	|				AND SettingsSource.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
	|			THEN CAST(ExpenseBalances.SumCompl * CAST(WriteOffShares.PercentageOfWriteOffs AS NUMBER(10,6)) AS NUMBER(31, 2))
	|		ELSE ExpenseBalances.SumCompl
	|	END AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	Recorders.Recorder AS Recorder,
	|	Recorders.Date AS Date,
	|	Recorders.BaseOfAllocationByLots AS AllocationBaseType,
	|	Recorders.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	Recorders.DistributionRequired
	|FROM
	|	ExpenseBalances AS ExpenseBalances
	|		INNER JOIN Recorders AS Recorders
	|		ON ExpenseBalances.ExpenseItem = Recorders.ExpenseItem
	|			AND ExpenseBalances.DimensionOfExpenses = Recorders.DimensionOfExpenses
	|			AND ExpenseBalances.Organization = Recorders.Organization
	|			AND ExpenseBalances.Department = Recorders.Department
	|			AND ExpenseBalances.LineOfBusiness = Recorders.LineOfBusiness
	|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS SettingsSource
	|		ON ExpenseBalances.ExpenseItem = SettingsSource.Ref
	|		LEFT JOIN TTShareOfWriteOffOfIndirectExpenses AS WriteOffShares
	|		ON ExpenseBalances.ExpenseItem = WriteOffShares.ExpenseItem
	|			AND ExpenseBalances.Organization = WriteOffShares.Organization
	|WHERE
	|	(NOT(ExpenseBalances.Sum = 0 AND ExpenseBalances.AmountExcludingVAT = 0
	|		AND ExpenseBalances.SumMan = 0) AND Recorders.ManagementAccounting 
	|		AND SettingsSource.CostAllocationOptionManag IN 
	|			(VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)))
	|	OR
	|	(NOT ExpenseBalances.SumCompl = 0 AND Recorders.LocalAccounting 
	|		AND SettingsSource.CostAllocationOptionLocal IN
	|				(VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)))";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	// To distribute the amount of PD and TD, when the use of RU is turned off, a simple logic of translation of differences from Balances is applied:
	// all generated differences are distributed by a document with the Regulated Account flag without dividing into AC and TA
	#Region DistributionOfPRiTDWithoutLocalAccounting
	QueryText =
	"SELECT
	|	//Settings of the ""distributionprivrbezregluchet"" AS A source of data,
	|	ExpenseBalances.Organization AS Organization,
	|	ExpenseBalances.Department AS Department,
	|	ExpenseBalances.LineOfBusiness AS LineOfBusiness,
	|	ExpenseBalances.ExpenseItem AS ExpenseItem,
	|	ExpenseBalances.DimensionOfExpenses AS DimensionOfExpenses,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	CAST (ExpenseBalances.PermanentDifference AS NUMBER(31, 2))	AS PermanentDifference,
	|	CAST (ExpenseBalances.CostTD AS NUMBER(31, 2))	AS CostTD,
	|	Recorders.Recorder AS Recorder,
	|	Recorders.Date AS Date,
	|	Recorders.BaseOfAllocationByLots AS AllocationBaseType,
	|	Recorders.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	Recorders.DistributionRequired
	|FROM
	|	ExpenseBalances AS ExpenseBalances
	|		INNER JOIN Recorders AS Recorders
	|		ON ExpenseBalances.ExpenseItem = Recorders.ExpenseItem
	|			AND ExpenseBalances.DimensionOfExpenses = Recorders.DimensionOfExpenses
	|			AND ExpenseBalances.Organization = Recorders.Organization
	|			AND ExpenseBalances.Department = Recorders.Department
	|			AND ExpenseBalances.LineOfBusiness = Recorders.LineOfBusiness
	|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS SettingsSource
	|		ON ExpenseBalances.ExpenseItem = SettingsSource.Ref
	|WHERE
	|	Recorders.LocalAccounting";
	If Not GetFunctionalOption("UseLocal") Then
		NestedRequestTexts.Add(QueryText);
	EndIf;
	#EndRegion
	
	
	// HIA: To the distribution of MA and AC
	#Region OVZ_DistributionAtUiAC
	QueryText =
	"SELECT
	|	//Settings of ""OVZ_DISTRIBUTIONUUIBU"" AS A data source,
	|	ExpenseBalances.Organization AS Organization,
	|	ExpenseBalances.Department AS Department,
	|	ExpenseBalances.LineOfBusiness AS LineOfBusiness,
	|	ExpenseBalances.ExpenseItem AS ExpenseItem,
	|	ExpenseBalances.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE
	|		WHEN NOT Recorders.ManagementAccounting
	|			OR NOT ExpenseItems.CostAllocationOptionManag = 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			OR NOT SettingsSource.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		ELSE ExpenseBalances.Sum
	|	END AS Sum,
	|	CASE
	|		WHEN NOT Recorders.ManagementAccounting
	|			OR NOT ExpenseItems.CostAllocationOptionManag = 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			OR NOT SettingsSource.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		ELSE ExpenseBalances.AmountExcludingVAT
	|	END AS AmountExcludingVAT,
	|	CASE
	|		WHEN NOT Recorders.ManagementAccounting
	|			OR NOT ExpenseItems.CostAllocationOptionManag = 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			OR NOT SettingsSource.CostAllocationOptionManag IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		ELSE ExpenseBalances.SumMan
	|	END AS SumMan,
	|	CASE
	|		WHEN NOT Recorders.LocalAccounting
	|			OR NOT ExpenseItems.CostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			OR NOT SettingsSource.CostAllocationOptionLocal IN (VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|																		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
	|			THEN 0
	|		WHEN ISNULL(WriteOffShares.Transportation, FALSE)
	|			AND SettingsSource.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
	|			THEN CAST(ExpenseBalances.SumCompl * WriteOffShares.PercentageOfWriteOffs AS NUMBER(31, 2))
	|		ELSE ExpenseBalances.SumCompl
	|	END AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	Recorders.Recorder AS Recorder,
	|	Recorders.Date AS Date,
	|	Recorders.BaseOfAllocationByLots AS AllocationBaseType,
	|	Recorders.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	Recorders.DistributionRequired
	|FROM
	|	ExpenseBalances AS ExpenseBalances
	|		INNER JOIN Recorders AS Recorders
	|		ON ExpenseBalances.DimensionOfExpenses = Recorders.DimensionOfExpenses
	|			AND ExpenseBalances.Organization = Recorders.Organization
	|			AND ExpenseBalances.Department = Recorders.Department
	|			AND Recorders.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			AND Recorders.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|		INNER JOIN TTOvz AS SettingsSource
	|		ON ExpenseBalances.DimensionOfExpenses = SettingsSource.ConstCenter
	|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseBalances.ExpenseItem = ExpenseItems.Ref
	|		LEFT JOIN TTShareOfWriteOffOfIndirectExpenses AS WriteOffShares
	|		ON ExpenseBalances.ExpenseItem = WriteOffShares.ExpenseItem
	|			AND ExpenseBalances.Organization = WriteOffShares.Organization
	|WHERE
	|	(NOT(ExpenseBalances.Sum = 0 AND ExpenseBalances.AmountExcludingVAT = 0
	|		AND ExpenseBalances.SumMan = 0) AND Recorders.ManagementAccounting 
	|		AND ExpenseItems.CostAllocationOptionManag = 
	|			VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|		AND SettingsSource.CostAllocationOptionManag IN
	|			(VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)))
	|	OR
	|	(NOT ExpenseBalances.SumCompl = 0 AND Recorders.LocalAccounting 
	|		AND ExpenseItems.CostAllocationOptionLocal = 
	|			VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|		AND SettingsSource.CostAllocationOptionLocal IN
	|			(VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)))	";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	NestedQueryString = StrConcat(NestedRequestTexts, TMCommonUse.QuerySeparatorInJoin(True));
	
	QueryText =
	"SELECT
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ExpenseItem AS ExpenseItem,
	|	NestedQuery.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumMan) AS SumMan,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	SUM(NestedQuery.PermanentDifference) AS PermanentDifference,
	|	SUM(NestedQuery.CostTD) AS CostTD,
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.Date AS Date,
	|	NestedQuery.AllocationBaseType AS AllocationBaseType,
	|	NestedQuery.DistributionRequired AS DistributionRequired
	|INTO ExpenseForAllocation
	|FROM
	|	ExpenseForAllocationPreliminary AS NestedQuery
	|
	|GROUP BY
	|		NestedQuery.Organization,
	|		NestedQuery.Department,
	|		NestedQuery.LineOfBusiness,
	|		NestedQuery.ExpenseItem, 
	|		NestedQuery.CurrentPeriodExpenses,
	|		NestedQuery.DimensionOfExpenses,
	|		NestedQuery.Recorder,
	|		NestedQuery.Date,
	|		NestedQuery.AllocationBaseType,
	|		NestedQuery.DistributionRequired
	|
	|INDEX BY
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	LineOfBusiness,
	|	Department,
	|	Organization";
	
	
	If SourceDebuggingMode Then
		
		QueryTexts = New Array;
		QueryTexts.Add(NestedQueryString);
		QueryTexts.Add(QueryText);
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Else
		QueryText = StrReplace(QueryText, "ExpenseForAllocationPreliminary", "(" + NestedQueryString + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TTTextCurrentAreasOfActivity()
	
	QueryText =
	"SELECT
	|	LB.Ref AS LineOfBusiness
	|INTO TTCurrentLinesOfBusiness
	|FROM Catalog.LinesOfBusiness AS LB 
	|WHERE
	|	(LB.StartDateOfActivity <= &EndOfPeriod OR LB.StartDateOfActivity = DATETIME(1,1,1))
	|	AND (LB.EndDateOfActivity >= &BeginOfPeriod OR LB.EndDateOfActivity = DATETIME(1,1,1))
	|UNION
	|SELECT
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|INDEX BY
	|	LineOfBusiness";
	
	Return QueryText;
	
EndFunction

Function TextProfitabilityAndCosts()
	
	QueryText =
	"SELECT
	|	FinancialResults.Organization AS Organization,
	|	FinancialResults.LineOfBusiness AS LineOfBusiness,
	|	SUM(CASE
	|		WHEN FinancialResults.IncomeItem = VALUE(ChartOfCharacteristicTypes.IncomeItems.SalesRevenue)
	|		THEN FinancialResults.Income
	|		ELSE 0 END) AS Income,
	|	SUM(CASE
	|		WHEN FinancialResults.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.SaleCost)
	|			THEN FinancialResults.Expenses
	|		ELSE 0 END) AS Expenses
	|INTO FinancialResults
	|FROM
	|	AccumulationRegister.FinancialResults AS FinancialResults
	|	INNER JOIN TTCurrentLinesOfBusiness AS LB
	|		ON FinancialResults.LineOfBusiness = LB.LineOfBusiness
	|WHERE
	|	FinancialResults.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND FinancialResults.Organization IN(&CompanyArray)
	|	AND FinancialResults.Active
	|	AND (VALUETYPE(FinancialResults.Recorder) = TYPE(Document.InventoryCostCalculation)
	|			OR FinancialResults.CalculationOfCost)
	|
	|GROUP BY
	|	FinancialResults.Organization,
	|	FinancialResults.LineOfBusiness
	|INDEX BY
	|	LineOfBusiness,
	|	Organization";
	
	Return QueryText;
	
EndFunction

Function TextRevenueAndCostOfGoodsSold()
	
	QueryText =
	"SELECT
	|	Data.AccountingDimensionByPartners.Organization AS Organization,
	|	Data.CounterpartyLineOfBusiness AS LineOfBusiness,
	|	SUM(Data.RevenueAmountExcludingVAT) AS Income,
	|	SUM(Data.CostMan + Data.AddExpensesMan + Data.ProvisionForImpairmentMan
	|		+ Data.ItemizedFixedCostsManag + Data.ItemizedVariableCostsManag + Data.LaborCostsMan
	|		+ Data.SellingExpensesMan) AS Expenses,
	|	SUM(Data.RevenueAmountExclVATLocal) AS LocalRevenues,
	|	SUM(Data.LocalCost + Data.AddExpensesLocal + Data.ProvisionForImpairmentLocal
	|		+ Data.ItemizedFixedCostsCompl + Data.ItemizedVariableCostsCompl + Data.LaborCostsLocal
	|		+ Data.SellingExpensesLocal) AS LocalExpenses
	|INTO RevenueAndCOGS
	|FROM
	|	AccumulationRegister.RevenueAndCOGS AS Data
	|	INNER JOIN TTCurrentLinesOfBusiness AS LB
	|		ON LB.LineOfBusiness = Data.CounterpartyLineOfBusiness
	|WHERE
	|	Data.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND Data.AccountingDimensionByPartners.Organization IN(&CompanyArray)
	|	AND Data.Active
	|	AND TRUE IN (SELECT DISTINCT TRUE FROM Recorders AS T WHERE T.DistributionRequired
	|		AND T.DataSource = VALUE(Enum.DataSourcesForExpenseAllocation.RevenueAndCOGS)
	|		AND T.BaseOfAllocationByLots IN (VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue),
	|										VALUE(Enum.TypesOfCostAllocatingBase.SaleCost),
	|										VALUE(Enum.TypesOfCostAllocatingBase.GrossProfit)))
	|	AND Data.RevenueAmountExclVATLocal + Data.LocalCost + Data.AddExpensesLocal + Data.ProvisionForImpairmentLocal
	|	+ Data.ItemizedFixedCostsCompl + Data.ItemizedVariableCostsCompl + Data.LaborCostsLocal
	|	+ Data.RevenueAmountExcludingVAT + Data.CostMan + Data.AddExpensesMan + Data.ProvisionForImpairmentMan
	|	+ Data.SellingExpensesMan + Data.SellingExpensesLocal
	|	+ Data.ItemizedFixedCostsManag + Data.ItemizedVariableCostsManag + Data.LaborCostsMan <> 0
	|
	|GROUP BY
	|	Data.AccountingDimensionByPartners.Organization,
	|	Data.CounterpartyLineOfBusiness
	|
	|INDEX BY
	|	LineOfBusiness,
	|	Organization";
	
	Return QueryText;
	
EndFunction

Function TextDistributionBase()
	
	QueryTextsOfAssociation = New Array;
	
	#Region ZeroSelectionIsPlacedInTemporaryTable
	QueryText =
	"SELECT TOP 0
	|	//The ""Initialization"" tab mode AS A data SourceData,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS AllocationBaseType,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ProductionOrder,
	|	UNDEFINED AS RowCodeProducts,
	|	UNDEFINED AS ProductionLot,
	|	0 AS Base,
	|	0 AS BaseLocal
	|INTO AllocationBase";
	QueryTextsOfAssociation.Add(QueryText);
	#EndRegion
	
	#Region Distribution_FinancialResults
	QueryText =
	"SELECT
	|	//The ""Distribution_financial Results"" tab AS A data source,
	|	Recorders.Recorder AS Recorder,
	|	Recorders.BaseOfAllocationByLots AS AllocationBaseType,
	|	ISNULL(FinancialResults.LineOfBusiness, 
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	UNDEFINED AS ProductionOrder,
	|	UNDEFINED AS RowCodeProducts,
	|	UNDEFINED AS ProductionLot,
	|	CASE
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue)
	|		THEN ISNULL(FinancialResults.Income, 0)
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SaleCost)
	|		THEN ISNULL(FinancialResults.Expenses, 0)
	|		ELSE ISNULL(FinancialResults.Income, 0) - ISNULL(FinancialResults.Expenses, 0)
	|	END AS Base,
	|	CASE
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue)
	|		THEN ISNULL(FinancialResults.Income, 0)
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SaleCost)
	|		THEN ISNULL(FinancialResults.Expenses, 0)
	|		ELSE ISNULL(FinancialResults.Income, 0) - ISNULL(FinancialResults.Expenses, 0)
	|	END AS BaseLocal
	|FROM
	|	Recorders AS Recorders
	|		LEFT JOIN Document.AllocationOfOtherCosts.FilterByLinesOfBusiness AS LinesOfBusiness
	|		ON Recorders.Recorder = LinesOfBusiness.Ref
	|		LEFT JOIN FinancialResults AS FinancialResults
	|		ON Recorders.Organization = FinancialResults.Organization
	|			AND (LinesOfBusiness.LineOfBusiness = FinancialResults.LineOfBusiness
	|				OR LinesOfBusiness.LineOfBusiness IS NULL)
	|WHERE
	|	Recorders.DistributionRequired
	|	AND Recorders.BaseOfAllocationByLots IN (
	|		VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue),
	|		VALUE(Enum.TypesOfCostAllocatingBase.SaleCost),
	|		VALUE(Enum.TypesOfCostAllocatingBase.GrossProfit))
	|	AND Recorders.DataSource <> VALUE(Enum.DataSourcesForExpenseAllocation.RevenueAndCOGS)";
	QueryTextsOfAssociation.Add(QueryText);
	#EndRegion
	
	#Region Distribution_RevenueAndCostOfGoodsSold
	QueryText =
	"SELECT
	|	//Mode settings""Distribution_Revenue and value of sales"" AS A source of data,
	|	Recorders.Recorder AS Recorder,
	|	Recorders.BaseOfAllocationByLots AS AllocationBaseType,
	|	ISNULL(RevenueAndCOGS.LineOfBusiness, 
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	UNDEFINED AS ProductionOrder,
	|	UNDEFINED AS RowCodeProducts,
	|	UNDEFINED AS ProductionLot,
	|	CASE
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue)
	|		THEN ISNULL(RevenueAndCOGS.Income, 0)
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SaleCost)
	|		THEN ISNULL(RevenueAndCOGS.Expenses, 0)
	|		ELSE ISNULL(RevenueAndCOGS.Income, 0) - ISNULL(RevenueAndCOGS.Expenses, 0)
	|	END AS Base,
	|	CASE
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue)
	|		THEN ISNULL(RevenueAndCOGS.LocalRevenues, 0)
	|		WHEN Recorders.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.SaleCost)
	|		THEN ISNULL(RevenueAndCOGS.LocalExpenses, 0)
	|		ELSE ISNULL(RevenueAndCOGS.LocalRevenues, 0) - ISNULL(RevenueAndCOGS.LocalExpenses, 0)
	|	END AS BaseLocal
	|FROM
	|	Recorders AS Recorders
	|		LEFT JOIN Document.AllocationOfOtherCosts.FilterByLinesOfBusiness AS LinesOfBusiness
	|		ON Recorders.Recorder = LinesOfBusiness.Ref
	|		LEFT JOIN RevenueAndCOGS AS RevenueAndCOGS
	|		ON Recorders.Organization = RevenueAndCOGS.Organization
	|			AND (LinesOfBusiness.LineOfBusiness = RevenueAndCOGS.LineOfBusiness
	|				OR LinesOfBusiness.LineOfBusiness IS NULL)
	|WHERE
	|	Recorders.DistributionRequired
	|	AND Recorders.BaseOfAllocationByLots IN (
	|		VALUE(Enum.TypesOfCostAllocatingBase.SalesRevenue),
	|		VALUE(Enum.TypesOfCostAllocatingBase.SaleCost),
	|		VALUE(Enum.TypesOfCostAllocatingBase.GrossProfit))
	|	AND Recorders.DataSource = VALUE(Enum.DataSourcesForExpenseAllocation.RevenueAndCOGS)";
	QueryTextsOfAssociation.Add(QueryText);
	#EndRegion
	
	#Region Distribution_InIndicatedDirections
	QueryText =
	"SELECT
	|	//Mode settings""Distribution_By the specified directions"" AS A SOURCE OF data,
	|	LinesOfBusiness.Ref,
	|	VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef),
	|	LinesOfBusiness.LineOfBusiness,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	LinesOfBusiness.CostShare,
	|	LinesOfBusiness.CostShare
	|FROM
	|	Recorders AS Recorders
	|		INNER JOIN Document.AllocationOfOtherCosts.LinesOfBusiness AS LinesOfBusiness
	|		ON Recorders.Recorder = LinesOfBusiness.Ref
	|		INNER JOIN TTCurrentLinesOfBusiness AS LB
	|			ON LinesOfBusiness.LineOfBusiness = LB.LineOfBusiness
	|WHERE
	|	Recorders.DistributionRequired";
	QueryTextsOfAssociation.Add(QueryText);
	#EndRegion
	
	#Region DistributionFromDatabaseByStages
	QueryText =
	"SELECT
	|	//The ""Distribution of Database steps"" mode AS A data source,
	|	BaseByStages.Recorder,
	|	Recorders.BaseOfAllocationByLots,
	|	BaseByStages.LineOfBusiness,
	|	CASE
	|		WHEN &PreliminaryCalculation
	|			THEN BaseByStages.ProductionOrder
	|		ELSE
	|			UNDEFINED
	|	END,
	|	CASE
	|		WHEN &PreliminaryCalculation
	|			THEN BaseByStages.RowCodeProducts
	|		ELSE
	|			UNDEFINED
	|	END,
	|	CASE
	|		WHEN &PreliminaryCalculation
	|			THEN BaseByStages.ProductionLot
	|		ELSE
	|			UNDEFINED
	|	END,
	|	SUM(BaseByStages.Cost),
	|	SUM(BaseByStages.LocalCost)
	|FROM
	|	BaseByStages AS BaseByStages
	|		INNER JOIN Recorders AS Recorders
	|		ON BaseByStages.Recorder = Recorders.Recorder
	|			AND Recorders.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationToFinancialResult)
	|		LEFT JOIN Document.AllocationOfOtherCosts.FilterByLinesOfBusiness AS LinesOfBusiness
	|		ON Recorders.Recorder = LinesOfBusiness.Ref
	|		INNER JOIN TTCurrentLinesOfBusiness AS LB
	|			ON BaseByStages.LineOfBusiness = LB.LineOfBusiness
	|WHERE
	|	LinesOfBusiness.LineOfBusiness = BaseByStages.LineOfBusiness
	|	OR LinesOfBusiness.LineOfBusiness IS NULL
	|
	|GROUP BY
	|	BaseByStages.LineOfBusiness,
	|	BaseByStages.Recorder,
	|	Recorders.BaseOfAllocationByLots,
	|	CASE
	|		WHEN &PreliminaryCalculation
	|			THEN BaseByStages.ProductionOrder
	|		ELSE
	|			UNDEFINED
	|	END,
	|	CASE
	|		WHEN &PreliminaryCalculation
	|			THEN BaseByStages.RowCodeProducts
	|		ELSE
	|			UNDEFINED
	|	END,
	|	CASE
	|		WHEN &PreliminaryCalculation
	|			THEN BaseByStages.ProductionLot
	|		ELSE
	|			UNDEFINED
	|	END";
	QueryTextsOfAssociation.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(QueryTextsOfAssociation, TMCommonUse.QuerySeparatorInJoin());
	
	Return QueryText;
	
EndFunction

Function TextOfDistributionBaseIsSummarized()
	
	QueryText =
	"SELECT
	|	AllocationBase.Recorder AS Recorder,
	|	AllocationBase.AllocationBaseType AS AllocationBaseType,
	|	SUM(AllocationBase.Base) AS Base,
	|	SUM(AllocationBase.BaseLocal) AS BaseLocal
	|INTO DistributionBasesAreSummarized
	|FROM
	|	AllocationBase AS AllocationBase
	|
	|GROUP BY
	|	AllocationBase.Recorder,
	|	AllocationBase.AllocationBaseType
	|
	|INDEX BY
	|	Recorder,
	|	AllocationBaseType";
	
	Return QueryText;
	
EndFunction

Function TextDistributedExpenses()
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN NOT ExpenseForAllocation.DistributionRequired
	|				OR NOT &GenerateFinancialResult 
	|			THEN ExpenseForAllocation.Sum
	|		WHEN ISNULL(DistributionBasesAreSummarized.Base, 0) = 0
	|			THEN 0
	|		ELSE CAST(ExpenseForAllocation.Sum * (AllocationBase.Base / DistributionBasesAreSummarized.Base) AS NUMBER(31, 2))
	|	END AS Sum,
	|	CASE
	|		WHEN NOT ExpenseForAllocation.DistributionRequired
	|				OR NOT &GenerateFinancialResult
	|			THEN ExpenseForAllocation.AmountExcludingVAT
	|		WHEN ISNULL(DistributionBasesAreSummarized.Base, 0) = 0
	|			THEN 0
	|		ELSE CAST(ExpenseForAllocation.AmountExcludingVAT * (AllocationBase.Base / DistributionBasesAreSummarized.Base) AS NUMBER(31, 2))
	|	END AS AmountExcludingVAT,
	|	CASE
	|		WHEN NOT ExpenseForAllocation.DistributionRequired
	|				OR NOT &GenerateFinancialResult
	|			THEN ExpenseForAllocation.SumMan
	|		WHEN ISNULL(DistributionBasesAreSummarized.Base, 0) = 0
	|			THEN 0
	|		ELSE CAST(ExpenseForAllocation.SumMan * (AllocationBase.Base / DistributionBasesAreSummarized.Base) AS NUMBER(31, 2))
	|	END AS SumMan,
	|	CASE
	|		WHEN NOT ExpenseForAllocation.DistributionRequired
	|				OR NOT &GenerateFinancialResult
	|			THEN ExpenseForAllocation.SumCompl
	|		WHEN ISNULL(DistributionBasesAreSummarized.Base, 0) = 0
	|			THEN 0
	|		ELSE CAST(ExpenseForAllocation.SumCompl * (AllocationBase.BaseLocal / DistributionBasesAreSummarized.BaseLocal) AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	CASE
	|		WHEN NOT ExpenseForAllocation.DistributionRequired
	|				OR NOT &GenerateFinancialResult
	|			THEN ExpenseForAllocation.PermanentDifference
	|		WHEN ISNULL(DistributionBasesAreSummarized.Base, 0) = 0
	|			THEN 0
	|		ELSE CAST(ExpenseForAllocation.PermanentDifference * (AllocationBase.BaseLocal / DistributionBasesAreSummarized.BaseLocal) AS NUMBER(31, 2))
	|	END AS PermanentDifference,
	|	CASE
	|		WHEN NOT ExpenseForAllocation.DistributionRequired
	|				OR NOT &GenerateFinancialResult
	|			THEN ExpenseForAllocation.CostTD
	|		WHEN ISNULL(DistributionBasesAreSummarized.Base, 0) = 0
	|			THEN 0
	|		ELSE CAST(ExpenseForAllocation.CostTD * (AllocationBase.BaseLocal / DistributionBasesAreSummarized.BaseLocal) AS NUMBER(31, 2))
	|	END AS CostTD,
	|	CASE
	|		WHEN ISNULL(DistributionBasesAreSummarized.Base, 0) = 0
	|			THEN 0
	|		ELSE AllocationBase.Base / DistributionBasesAreSummarized.Base
	|	END AS DistributionCoefficient,
	|	ISNULL(AllocationBase.Base, 0) AS Base,
	|	ISNULL(AllocationBase.BaseLocal, 0) AS BaseLocal,
	|	ExpenseForAllocation.Recorder AS Recorder,
	|	ExpenseForAllocation.Organization AS Organization,
	|	ExpenseForAllocation.Date AS Date,
	|	ExpenseForAllocation.Department AS Department,
	|	ExpenseForAllocation.LineOfBusiness AS LineOfBusiness,
	|	ExpenseForAllocation.ExpenseItem AS ExpenseItem,
	|	ExpenseForAllocation.DimensionOfExpenses AS DimensionOfExpenses,
	|	ISNULL(AllocationBase.ProductionOrder, UNDEFINED) AS ProductionOrder,
	|	ISNULL(AllocationBase.RowCodeProducts, UNDEFINED) AS RowCodeProducts,
	|	ISNULL(AllocationBase.ProductionLot, UNDEFINED) AS ProductionLot,
	|	CASE
	|		WHEN NOT ExpenseForAllocation.DistributionRequired
	|			THEN 
	|				CASE 
	|					WHEN NOT ExpenseForAllocation.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|						THEN ExpenseForAllocation.LineOfBusiness
	|					WHEN VALUETYPE(ExpenseForAllocation.DimensionOfExpenses) = TYPE(Catalog.LinesOfBusiness)
	|						AND NOT ExpenseForAllocation.DimensionOfExpenses = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|						THEN ExpenseForAllocation.DimensionOfExpenses
	|					ELSE
	|						VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|				END
	|		ELSE
	|			AllocationBase.LineOfBusiness
	|	END AS FieldOfActivityReceiver,
	|	ExpenseForAllocation.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness) AS BusinessOperation
	|INTO DistributedExpenses
	|FROM
	|	ExpenseForAllocation AS ExpenseForAllocation
	|		LEFT JOIN AllocationBase AS AllocationBase
	|		ON ExpenseForAllocation.Recorder = AllocationBase.Recorder
	|			AND ExpenseForAllocation.AllocationBaseType = AllocationBase.AllocationBaseType
	|			AND (AllocationBase.Base <> 0 OR AllocationBase.BaseLocal <> 0)
	|		LEFT JOIN DistributionBasesAreSummarized AS DistributionBasesAreSummarized
	|		ON ExpenseForAllocation.Recorder = DistributionBasesAreSummarized.Recorder
	|			AND ExpenseForAllocation.AllocationBaseType = DistributionBasesAreSummarized.AllocationBaseType
	|
	|INDEX BY
	|	Recorder,
	|	DistributionCoefficient";
	
	Return QueryText;
	
EndFunction

Function TextDistributionDocuments()
	
	QueryText =
	"SELECT DISTINCT
	|	DistributedExpenses.Recorder AS Recorder,
	|	DistributedExpenses.Organization AS Organization,
	|	DistributedExpenses.Date AS Date
	|INTO DistributionDocuments
	|FROM
	|	DistributedExpenses AS DistributedExpenses
	|		LEFT JOIN DistributionBasesAreSummarized AS AllocationBase
	|		ON DistributedExpenses.Recorder = AllocationBase.Recorder
	|WHERE
	|	NOT (DistributedExpenses.Sum = 0
	|	AND DistributedExpenses.AmountExcludingVAT = 0
	|	AND DistributedExpenses.SumMan = 0
	|	AND DistributedExpenses.SumCompl = 0
	|	AND DistributedExpenses.PermanentDifference = 0
	|	AND DistributedExpenses.CostTD = 0)
	|		OR NOT AllocationBase.Recorder IS NULL
	|	
	|INDEX BY
	|	Recorder";
	
	Return QueryText;
	
EndFunction

Function TextMaximumCoefficientsForRecorders()
	
	QueryText =
	"SELECT
	|	DistributedExpenses.Recorder AS Recorder,
	|	MAX(DistributedExpenses.DistributionCoefficient) AS DistributionCoefficient
	|INTO MaximumCoefficientsForRegistrars
	|FROM
	|	DistributedExpenses AS DistributedExpenses
	|
	|GROUP BY
	|	DistributedExpenses.Recorder
	|
	|INDEX BY
	|	Recorder";
	
	Return QueryText;
	
EndFunction

Function TextOfDirectionOfActivityForError()
	
	QueryText =
	"SELECT
	|	MaximumCoefficientsForRegistrars.Recorder AS Recorder,
	|	MAX(DistributedExpenses.FieldOfActivityReceiver) AS FieldOfActivityReceiver
	|INTO AreasOfActivityForError
	|FROM
	|	MaximumCoefficientsForRegistrars AS MaximumCoefficientsForRegistrars
	|		INNER JOIN DistributedExpenses AS DistributedExpenses
	|		ON MaximumCoefficientsForRegistrars.Recorder = DistributedExpenses.Recorder
	|			AND MaximumCoefficientsForRegistrars.DistributionCoefficient = DistributedExpenses.DistributionCoefficient
	|
	|GROUP BY
	|	MaximumCoefficientsForRegistrars.Recorder
	|
	|INDEX BY
	|	Recorder";
	
	Return QueryText;
	
EndFunction

Function TextOfRoundingError()
	
	QueryText =
	"SELECT
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumMan) AS SumMan,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	SUM(NestedQuery.PermanentDifference) AS PermanentDifference,
	|	SUM(NestedQuery.CostTD) AS CostTD,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ExpenseItem AS ExpenseItem,
	|	NestedQuery.Recorder AS Recorder
	|INTO RoundingErrors_
	|FROM
	|	(SELECT
	|		ExpenseForAllocation.Sum,
	|		ExpenseForAllocation.AmountExcludingVAT,
	|		ExpenseForAllocation.SumMan,
	|		ExpenseForAllocation.SumCompl,
	|		0 AS PermanentDifference,
	|		0 AS CostTD,
	|		ExpenseForAllocation.LineOfBusiness AS LineOfBusiness,
	|		ExpenseForAllocation.ExpenseItem AS ExpenseItem,
	|		ExpenseForAllocation.Recorder AS Recorder
	|	FROM
	|		ExpenseForAllocation AS ExpenseForAllocation
	|			INNER JOIN DistributionDocuments AS DistributionDocuments
	|			ON ExpenseForAllocation.Recorder = DistributionDocuments.Recorder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		-DistributedExpenses.Sum,
	|		-DistributedExpenses.AmountExcludingVAT,
	|		-DistributedExpenses.SumMan,
	|		-DistributedExpenses.SumCompl,
	|		0,
	|		0,
	|		DistributedExpenses.LineOfBusiness AS LineOfBusiness,
	|		DistributedExpenses.ExpenseItem AS ExpenseItem,
	|		DistributedExpenses.Recorder
	|	FROM
	|		DistributedExpenses AS DistributedExpenses) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ExpenseItem,
	|	NestedQuery.Recorder
	|
	|HAVING
	|	NOT (SUM(NestedQuery.Sum) = 0
	|		AND SUM(NestedQuery.AmountExcludingVAT) = 0
	|		AND SUM(NestedQuery.SumMan) = 0
	|		AND SUM(NestedQuery.SumCompl) = 0
	|		AND SUM(NestedQuery.PermanentDifference) = 0
	|		AND SUM(NestedQuery.CostTD) = 0)
	|
	|INDEX BY
	|	Recorder,
	|	LineOfBusiness,
	|	ExpenseItem";
	
	Return QueryText;
	
EndFunction

Function TextRecordersToCleanUpRegisterRecords(SourceDebuggingMode)
	
	NestedRequestTexts = New Array;
	
	#Region InitializationOfTemporaryTableRecordersForClearingRegisterRecordsPreliminary
	QueryText =
	"SELECT TOP 0
	|	//The ""Initialization"" tab mode AS A data SourceData,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS Organization,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	0 AS SumCompl,
	|	0 AS AmountFA,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan
	|INTO RecordersToCleanUpRegisteredRecordsPreliminary";
	If SourceDebuggingMode Then
		NestedRequestTexts.Add(QueryText);
	EndIf;
	#EndRegion
	
	#Region ExpenseBalances
	QueryText =
	"SELECT
	|	//The mode of setting the ""remainder of expenditures"" AS A data SourceData,
	|	Recorders.Recorder 				AS Recorder,
	|	ExpenseBalances.Organization 			AS Organization,
	|	ExpenseBalances.Department 			AS Department,
	|	ExpenseBalances.LineOfBusiness AS LineOfBusiness,
	|	ExpenseBalances.ExpenseItem			AS ExpenseItem,
	|	ExpenseBalances.DimensionOfExpenses		AS DimensionOfExpenses,
	|	CASE
	|		WHEN Attributes.LocalAccounting
	|			THEN ExpenseBalances.SumCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	CASE
	|		WHEN Attributes.TaxAccounting
	|			THEN ExpenseBalances.AmountFA
	|		ELSE 0
	|	END AS AmountFA,
	|	CASE
	|		WHEN Attributes.ManagementAccounting
	|			THEN ExpenseBalances.Sum
	|		ELSE 0
	|	END AS Sum,
	|	CASE
	|		WHEN Attributes.ManagementAccounting
	|			THEN ExpenseBalances.AmountExcludingVAT
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|	CASE
	|		WHEN Attributes.ManagementAccounting
	|			THEN ExpenseBalances.SumMan
	|		ELSE 0
	|	END AS SumMan
	|FROM
	|	PreliminaryExpenseBalances AS ExpenseBalances
	|		INNER JOIN Recorders AS Recorders
	|		ON ExpenseBalances.Organization = Recorders.Organization
	|			AND ExpenseBalances.Department = Recorders.Department
	|			AND ExpenseBalances.LineOfBusiness = Recorders.LineOfBusiness
	|			AND ExpenseBalances.ExpenseItem = Recorders.ExpenseItem
	|			AND ExpenseBalances.DimensionOfExpenses = Recorders.DimensionOfExpenses
	|		INNER JOIN Document.AllocationOfOtherCosts AS Attributes
	|		ON Recorders.Recorder = Attributes.Ref";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CurRegisteredRecords
	QueryText =
	"SELECT
	|	//Current Movement settings AS A DATA source,
	|	Recorders.Recorder 				AS Recorder,
	|	ExpenseBalances.Organization 			AS Organization,
	|	ExpenseBalances.Department 			AS Department,
	|	ExpenseBalances.LineOfBusiness AS LineOfBusiness,
	|	ExpenseBalances.ExpenseItem			AS ExpenseItem,
	|	ExpenseBalances.DimensionOfExpenses		AS DimensionOfExpenses,
	|	CASE
	|		WHEN Attributes.LocalAccounting
	|			THEN CurRegisteredRecords.SumCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	CASE
	|		WHEN Attributes.LocalAccounting
	|			THEN CurRegisteredRecords.SumCompl
	|		ELSE 0
	|	END 
	|	AS AmountFA,
	|	CASE
	|		WHEN Attributes.ManagementAccounting
	|			THEN CurRegisteredRecords.Sum
	|		ELSE 0
	|	END AS Sum,
	|	CASE
	|		WHEN Attributes.ManagementAccounting
	|			THEN CurRegisteredRecords.AmountExcludingVAT
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|	CASE
	|		WHEN Attributes.ManagementAccounting
	|			THEN CurRegisteredRecords.SumMan
	|		ELSE 0
	|	END AS SumMan
	|FROM
	|	PreliminaryExpenseBalances AS ExpenseBalances
	|		INNER JOIN Recorders AS Recorders
	|		ON ExpenseBalances.Organization = Recorders.Organization
	|			AND ExpenseBalances.Department = Recorders.Department
	|			AND ExpenseBalances.LineOfBusiness = Recorders.LineOfBusiness
	|			AND ExpenseBalances.ExpenseItem = Recorders.ExpenseItem
	|			AND ExpenseBalances.DimensionOfExpenses = Recorders.DimensionOfExpenses
	|		INNER JOIN AccumulationRegister.OtherExpenses AS CurRegisteredRecords
	|		ON Recorders.Recorder = CurRegisteredRecords.Recorder
	|			AND (CurRegisteredRecords.RecordType = VALUE(AccumulationRecordType.Expense))
	|			AND (CurRegisteredRecords.Organization = ExpenseBalances.Organization)
	|			AND (CurRegisteredRecords.Department = ExpenseBalances.Department)
	|			AND (CurRegisteredRecords.LineOfBusiness = ExpenseBalances.LineOfBusiness)
	|			AND (CurRegisteredRecords.ExpenseItem = ExpenseBalances.ExpenseItem)
	|			AND (CurRegisteredRecords.DimensionOfExpenses = ExpenseBalances.DimensionOfExpenses)
	|		INNER JOIN Document.AllocationOfOtherCosts AS Attributes
	|		ON Attributes.Ref = CurRegisteredRecords.Recorder
	|WHERE
	|	CurRegisteredRecords.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND CurRegisteredRecords.Active";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	NestedQueryString = StrConcat(NestedRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
	"SELECT
	|	Calculated_1Balance.Recorder 				AS Recorder,
	|	Calculated_1Balance.Organization 				AS Organization,
	|	Calculated_1Balance.Department 				AS Department,
	|	Calculated_1Balance.LineOfBusiness	AS LineOfBusiness,
	|	Calculated_1Balance.ExpenseItem				AS ExpenseItem,
	|	Calculated_1Balance.DimensionOfExpenses			AS DimensionOfExpenses
	|INTO RecordersToCleanUpRegisteredRecords
	|FROM
	|	RecordersToCleanUpRegisteredRecordsPreliminary AS Calculated_1Balance
	|
	|GROUP BY
	|	Calculated_1Balance.Recorder,
	|	Calculated_1Balance.Organization,
	|	Calculated_1Balance.Department,
	|	Calculated_1Balance.LineOfBusiness,
	|	Calculated_1Balance.ExpenseItem,
	|	Calculated_1Balance.DimensionOfExpenses
	|
	|HAVING
	|	SUM(Calculated_1Balance.Sum) = 0
	|	AND SUM(Calculated_1Balance.AmountExcludingVAT) = 0
	|	AND SUM(Calculated_1Balance.SumMan) = 0
	|	AND SUM(Calculated_1Balance.SumCompl) = 0
	|	AND SUM(Calculated_1Balance.AmountFA) = 0";
	
	If SourceDebuggingMode Then
		
		QueryTexts = New Array;
		QueryTexts.Add(NestedQueryString);
		QueryTexts.Add(QueryText);
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Else
		QueryText = StrReplace(QueryText, "RecordersToCleanUpRegisteredRecordsPreliminary", "(" + NestedQueryString + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextDistributedCostAnalytics()
	
	QueryText =
	"SELECT DISTINCT
	|	ExpenseAnalysts.Organization AS Organization,
	|	ExpenseAnalysts.Department AS Department,
	|	ExpenseAnalysts.LineOfBusiness AS LineOfBusiness,
	|	ExpenseAnalysts.ExpenseItem AS ExpenseItem,
	|	ExpenseAnalysts.DimensionOfExpenses AS DimensionOfExpenses
	|INTO DistributedExpenseAnalytics
	|FROM
	|	(SELECT
	|		DistributedExpenses.Organization AS Organization,
	|		DistributedExpenses.Department AS Department,
	|		DistributedExpenses.LineOfBusiness AS LineOfBusiness,
	|		DistributedExpenses.ExpenseItem AS ExpenseItem,
	|		DistributedExpenses.DimensionOfExpenses AS DimensionOfExpenses
	|	FROM
	|		DistributedExpenses AS DistributedExpenses
	|			INNER JOIN DistributionDocuments AS Documents
	|			ON DistributedExpenses.Recorder = Documents.Recorder
	|
	|	UNION ALL
	|
	|	SELECT
	|		ExpenseAnalysts.Organization AS Organization,
	|		ExpenseAnalysts.Department AS Department,
	|		ExpenseAnalysts.LineOfBusiness AS LineOfBusiness,
	|		ExpenseAnalysts.ExpenseItem AS ExpenseItem,
	|		ExpenseAnalysts.DimensionOfExpenses AS DimensionOfExpenses
	|	FROM
	|		RecordersToCleanUpRegisteredRecords AS ExpenseAnalysts
	|	) AS ExpenseAnalysts
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	ExpenseItem,
	|	DimensionOfExpenses";
	
	Return QueryText;
	
EndFunction

Function TextDocumentsWithNewRegisteredRecords()
	
	QueryText =
	"SELECT DISTINCT
	|	T.Recorder,
	|	T.Organization,
	|	T.Date
	|INTO DocumentsWithNewRegisteredRecords
	|FROM
	|	(SELECT
	|		T.Recorder,
	|		T.Organization,
	|		T.Date
	|	FROM
	|		DistributionDocuments AS T
	|) AS T";
	
	Return QueryText;
	
EndFunction

// TT Reflection Document: A temp table for reflection in international accounting
Function TextDocumentsToBeReflected()
	
	QueryText =
	"SELECT 
	|	T.Recorder AS Document,
	|	T.Organization AS Organization,
	|	T.Date AS DateRecord
	|INTO DocumentsToBeReflected
	|FROM DocumentsWithNewRegisteredRecords AS T";
	
	Return QueryText;
	
EndFunction

Function TextSelectionOtherExpenses()
	
	QueryText =
	"SELECT
	|	OtherExpenses.*
	|FROM
	|	DocumentsWithNewRegisteredRecords AS DocumentsWithNewRegisteredRecords
	|		INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
	|		ON DocumentsWithNewRegisteredRecords.Recorder = OtherExpenses.Recorder
	|WHERE
	|	NOT OtherExpenses.BusinessOperation IN (VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness),
	|												VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA))
	|
	|TOTALS BY
	|	OtherExpenses.Recorder";
	
	Return QueryText;
	
EndFunction

Function TextSelectionOtherExpensesUnfinishedProduction()
	
	QueryText =
	"SELECT
	|	OtherExpensesOfUnfinishedProduction.*
	|FROM
	|	DocumentsWithNewRegisteredRecords AS DocumentsWithNewRegisteredRecords
	|		INNER JOIN AccumulationRegister.OtherWorkInProgressExpenses AS OtherExpensesOfUnfinishedProduction
	|		ON DocumentsWithNewRegisteredRecords.Recorder = OtherExpensesOfUnfinishedProduction.Recorder
	|
	|TOTALS BY
	|	OtherExpensesOfUnfinishedProduction.Recorder";
	
	Return QueryText;
	
EndFunction

Function TextSelectionOtherAssetsLiabilities()
	
	QueryText =
	"SELECT
	|	OtherAssetsLiabilities.*
	|FROM
	|	DocumentsWithNewRegisteredRecords AS DocumentsWithNewRegisteredRecords
	|		INNER JOIN AccumulationRegister.OtherAssetsLiabilities AS OtherAssetsLiabilities
	|		ON DocumentsWithNewRegisteredRecords.Recorder = OtherAssetsLiabilities.Recorder
	|WHERE
	|	OtherAssetsLiabilities.CalculationOfCost
	|	AND NOT OtherAssetsLiabilities.Source = VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef)";
	
	Return QueryText;
	
EndFunction

Function TextDistributionResult(SourceDebuggingMode)
	
	NestedRequestTexts = New Array;
	
	#Region InitializationOfTemporaryTableResultOfDistributionIsPreliminary
	QueryText =
	"SELECT TOP 0
	|	//The ""Initialization"" tab mode AS A data SourceData,
	|	UNDEFINED AS Period,
	|	UNDEFINED AS RecordType,
	|	UNDEFINED AS Recorder,
	|	UNDEFINED AS Organization,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS FieldOfActivityReceiver,
	|	UNDEFINED AS BusinessOperation,
	|	FALSE AS CurrentPeriodExpenses,
	|	UNDEFINED AS ProductionOrder,
	|	UNDEFINED AS RowCodeProducts,
	|	UNDEFINED AS ProductionLot,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS Expenses,
	|	0 AS AllocationBase
	|INTO AllocationResultPreliminary";
	If SourceDebuggingMode Then
		NestedRequestTexts.Add(QueryText);
	EndIf;
	#EndRegion
	
	#Region DistributedExpenses
	QueryText =
	"SELECT
	|	//Mode settings ""Distributed inputs"" AS A data SourceData,
	|	&EndOfPeriod AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DistributedExpenses.Recorder AS Recorder,
	|	DistributedExpenses.Organization AS Organization,
	|	DistributedExpenses.Department AS Department,
	|	DistributedExpenses.LineOfBusiness AS LineOfBusiness,
	|	DistributedExpenses.FieldOfActivityReceiver AS FieldOfActivityReceiver,
	|	DistributedExpenses.BusinessOperation AS BusinessOperation,
	|	DistributedExpenses.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	DistributedExpenses.ProductionOrder AS ProductionOrder,
	|	DistributedExpenses.RowCodeProducts AS RowCodeProducts,
	|	DistributedExpenses.ProductionLot AS ProductionLot,
	|	DistributedExpenses.ExpenseItem AS ExpenseItem,
	|	DistributedExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	DistributedExpenses.Sum AS Sum,
	|	DistributedExpenses.AmountExcludingVAT AS AmountExcludingVAT,
	|	DistributedExpenses.SumMan AS SumMan,
	|	DistributedExpenses.SumCompl AS SumCompl,
	// The normalized expenses in TA are distributed separately and stored in the temporary write-off table.
	// Therefore, in the cost allocation line, the amount of TA should be equal to 0. To do this, the entire amount of AC should
	// A time difference can be formed. 
	// The permanent difference in the normalized expenses has already been distributed and reflected in the temporary write-off table,
	// therefore, in the movement to write off the normalized expenses, the post-season difference should be equal to 0.  
	|	CASE 
	|		WHEN ISNULL(WriteOffShares.Normalized, FALSE) THEN 0 
	|		ELSE DistributedExpenses.PermanentDifference 
	|	END AS PermanentDifference,
	|	CASE 
	|		WHEN ISNULL(WriteOffShares.Normalized, FALSE) 
	|			THEN DistributedExpenses.SumCompl 
	|		ELSE DistributedExpenses.CostTD 
	|	END AS CostTD,
	|	DistributedExpenses.Sum AS Expenses,
	|	DistributedExpenses.Base AS AllocationBase
	|FROM
	|	DistributedExpenses AS DistributedExpenses
	|	LEFT JOIN TTShareOfWriteOffOfIndirectExpenses AS WriteOffShares
	|	ON DistributedExpenses.ExpenseItem = WriteOffShares.ExpenseItem
	|		AND DistributedExpenses.Organization = WriteOffShares.Organization";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	
	#Region ExpenseForAllocation
	QueryText =
	"SELECT
	|	//Modes of ""Expenses for distribution"" AS A source of data,
	|	&EndOfPeriod,
	|	VALUE(AccumulationRecordType.Expense),
	|	ExpenseForAllocation.Recorder,
	|	ExpenseForAllocation.Organization,
	|	ExpenseForAllocation.Department,
	|	ExpenseForAllocation.LineOfBusiness,
	|	AreasOfActivityForError.FieldOfActivityReceiver,
	|	VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness),
	|	ExpenseForAllocation.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	ExpenseForAllocation.ExpenseItem,
	|	ExpenseForAllocation.DimensionOfExpenses,
	|	RoundingErrors_.Sum,
	|	RoundingErrors_.AmountExcludingVAT,
	|	RoundingErrors_.SumMan,
	|	RoundingErrors_.SumCompl,
	// The normalized expenses in TA are distributed separately and stored in the temporary write-off table.
	// Therefore, in the cost allocation line, the amount of TA should be equal to 0. To do this, the entire amount of AC should
	// A time difference can be formed. 
	// The permanent difference in the normalized expenses has already been distributed and reflected in the temporary write-off table,
	// therefore, in the movement to write off the normalized expenses, the post-season difference should be equal to 0.  
	|	CASE 
	|		WHEN ISNULL(WriteOffShares.Normalized, FALSE) THEN 0 
	|		ELSE RoundingErrors_.PermanentDifference 
	|	END AS PermanentDifference,
	|	CASE 
	|		WHEN ISNULL(WriteOffShares.Normalized, FALSE) 
	|			THEN RoundingErrors_.SumCompl 
	|		ELSE RoundingErrors_.CostTD 
	|	END AS CostTD,
	|	RoundingErrors_.Sum AS Expenses,
	|	0 AS AllocationBase
	|FROM
	|	ExpenseForAllocation AS ExpenseForAllocation
	|	INNER JOIN RoundingErrors_ AS RoundingErrors_
	|		ON ExpenseForAllocation.Recorder = RoundingErrors_.Recorder
	|			AND ExpenseForAllocation.ExpenseItem = RoundingErrors_.ExpenseItem
	|			AND ExpenseForAllocation.LineOfBusiness = RoundingErrors_.LineOfBusiness
	|	INNER JOIN AreasOfActivityForError AS AreasOfActivityForError
	|		ON ExpenseForAllocation.Recorder = AreasOfActivityForError.Recorder
	|	LEFT JOIN TTShareOfWriteOffOfIndirectExpenses AS WriteOffShares
	|	ON ExpenseForAllocation.ExpenseItem = WriteOffShares.ExpenseItem
	|		AND ExpenseForAllocation.Organization = WriteOffShares.Organization";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region RecordersToCleanUpRegisteredRecords
	QueryText =
	"SELECT
	|	//The settings of the ""Registratorycleaning movements"" AS a source of data,
	|	&EndOfPeriod,
	|	VALUE(AccumulationRecordType.Expense),
	|	RegistrarsAndAnalysts.Recorder,
	|	RegistrarsAndAnalysts.Organization,
	|	RegistrarsAndAnalysts.Department,
	|	RegistrarsAndAnalysts.LineOfBusiness,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|	VALUE(Enum.BusinessTransactions.EmptyRef),
	|	FALSE,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	RegistrarsAndAnalysts.ExpenseItem,
	|	RegistrarsAndAnalysts.DimensionOfExpenses,
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS Expenses,
	|	0 AS AllocationBase
	|FROM
	|	RecordersToCleanUpRegisteredRecords AS RegistrarsAndAnalysts";
	NestedRequestTexts.Add(QueryText);
	#EndRegion
	
	NestedQueryString = StrConcat(NestedRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText =
	"SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.RecordType AS RecordType,
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.FieldOfActivityReceiver AS FieldOfActivityReceiver,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	NestedQuery.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	NestedQuery.ProductionOrder AS ProductionOrder,
	|	NestedQuery.RowCodeProducts AS RowCodeProducts,
	|	NestedQuery.ProductionLot AS ProductionLot,
	|	NestedQuery.ExpenseItem AS ExpenseItem,
	|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumMan) AS SumMan,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	SUM(NestedQuery.PermanentDifference) AS PermanentDifference,
	|	SUM(NestedQuery.CostTD) AS CostTD,
	|	SUM(NestedQuery.Expenses) AS Expenses,
	|	SUM(NestedQuery.AllocationBase) AS AllocationBase
	|INTO AllocationResult
	|FROM
	|	AllocationResultPreliminary AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Period,
	|	NestedQuery.Recorder,
	|	NestedQuery.Organization,
	|	NestedQuery.RecordType,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.FieldOfActivityReceiver,
	|	NestedQuery.BusinessOperation,
	|	NestedQuery.CurrentPeriodExpenses,
	|	NestedQuery.ProductionOrder,
	|	NestedQuery.RowCodeProducts,
	|	NestedQuery.ProductionLot,
	|	NestedQuery.ExpenseItem,
	|	NestedQuery.DimensionOfExpenses";
	
	If SourceDebuggingMode Then
		
		QueryTexts = New Array;
		QueryTexts.Add(NestedQueryString);
		QueryTexts.Add(QueryText);
		QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Else
		QueryText = StrReplace(QueryText, "AllocationResultPreliminary", "(" + NestedQueryString + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextSelectionDistributionResult()
	
	QueryText =
	"SELECT
	|	AllocationResult.Period AS Period,
	|	AllocationResult.RecordType AS RecordType,
	|	AllocationResult.Recorder AS Recorder,
	|	AllocationResult.Organization AS Organization,
	|	AllocationResult.Department AS Department,
	|	AllocationResult.LineOfBusiness AS LineOfBusiness,
	|	AllocationResult.FieldOfActivityReceiver AS FieldOfActivityReceiver,
	|	AllocationResult.BusinessOperation AS BusinessOperation,
	|	AllocationResult.CurrentPeriodExpenses AS CurrentPeriodExpenses,
	|	AllocationResult.ProductionOrder AS ProductionOrder,
	|	AllocationResult.RowCodeProducts AS RowCodeProducts,
	|	AllocationResult.ProductionLot AS ProductionLot,
	|	AllocationResult.ExpenseItem AS ExpenseItem,
	|	AllocationResult.DimensionOfExpenses AS DimensionOfExpenses,
	|	(AllocationResult.Sum) AS Sum,
	|	(AllocationResult.AmountExcludingVAT) AS AmountExcludingVAT,
	|	(AllocationResult.SumMan) AS SumMan,
	|	(AllocationResult.SumCompl) AS SumCompl,
	|	(AllocationResult.PermanentDifference) AS PermanentDifference,
	|	(AllocationResult.CostTD) AS CostTD,
	|	(AllocationResult.Expenses) AS Expenses,
	|	(AllocationResult.AllocationBase) AS AllocationBase
	|FROM
	|	AllocationResult AS AllocationResult
	|
	|TOTALS BY
	|	Organization,
	|	Recorder";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
