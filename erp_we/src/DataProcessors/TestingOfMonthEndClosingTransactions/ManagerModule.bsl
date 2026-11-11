#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
// Performs testing operations the closure of the month.
// 
// Parameters:
// 	InputParameters - Structure - 
// Returns:
// 	Structure - LongDesc:
// * Cancel - Boolean - success/not success of the test
// * ErrorDescription - String - detailed representation of the error
// * NameOfTestingStage - Map - stage testing data
Function Testing(InputParameters) Export
	
	If InputParameters.Property("StartupParameters") Then // program launch, there are startup parameters
		TestingParameters = TestStartupParameters(InputParameters.StartupParameters);
		
		Log_ = Undefined;
		If InputParameters.Property("Log_", Log_) Then
			TestingParameters.Insert("Log_", Log_);
		EndIf;
		
		If InputParameters.Property("ReferenceData") Then
			TestingParameters.Insert("ReferenceData", InputParameters.ReferenceData);
		EndIf;
		
	Else
		TestingParameters = InputParameters;
	EndIf;
	
	MeasurementStart = StartTimeMeasurement(TestingParameters, "Testing");
	
	Try
		If TestingParameters.Property("TestPlanTree") Then
			TestPlanTree = ValueFromFile(TestingParameters.TestPlanTree);
			TestResult_ = TestAccordingToTestPlan(TestPlanTree, TestingParameters);
			ValueToFile(TestingParameters.TestPlanTree, TestPlanTree);
			TestResult_.Insert("ResultTree", TestPlanTree);
		Else
			TestResult_ = TestForPeriod(TestingParameters);
		EndIf;
	Except
		TestResult_ = New Structure;
		TestResult_.Insert("Cancel", True);
		ReportError();
		ErrorInfo = ErrorInfo();
		TestResult_.Insert("SourceInformation", ErrorInfo.Description);
		TestResult_.Insert("MetadataObject", ErrorInfo.ModuleName);
		TestResult_.Insert("LocationClarification", ErrorInfo.SourceLine);
		//The test result.Insert("Error description", detailed error presentation(Error information()));
		Raise;
	EndTry;
	
	StopTimeMeasurement(TestingParameters, "Testing", MeasurementStart);
	If TestingParameters.Property("Log_") Then
		InputParameters.Log_ = TestingParameters.Log_;
	EndIf;
	
	If TestingParameters.Property("TestPlanTree") Then
		PutToTempStorage(TestResult_, TestingParameters.StorageAddress);
	EndIf;
	
	Return TestResult_;
	
EndFunction

// Starts testing routine tasks at the end of the month in the background task.
//
// Parameters:
//	TestingParameters - Structure - Parameters for closing the month: period, organization to close.
//
// Returns:
//  UUID - id of the running task
//	String - description of the reason why the task cannot be started.
//
Function RunTestingInBackground(TestingParameters) Export
	
	// Let's check the possibility of starting the calculation.
	CalculationID = New UUID; // it is written to the key of the background task
	
	ActiveCalculations = InformationRegisters.PerformMonthEndClosingOperations.CheckForActiveCalculations();
	
	If ActiveCalculations.ThereAreActiveCalculations Then
		Return ActiveCalculations.ErrorText;
	EndIf;
	
	// Let's start the calculation.
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(TestingParameters);
	
	JobParameters = New Array;
	JobParameters.Add("DataProcessors.TestingOfMonthEndClosingTransactions.Testing");
	JobParameters.Add(ExportProcedureParameters);
	
	SetPrivilegedMode(True);
	
	Job = BackgroundJobs.Execute(
		"Common.ExecuteConfigurationMethod",
		JobParameters,
		MonthEndTransactionsServer.NameOfBackgroundJob(CalculationID),
		NStr("vi = 'Thử nghiệm thao tác đóng tháng';
			|ru = 'Тестирование операций закрытие месяца';
			|en = 'Test month-end closing operations'; fa = 'Test month-end closing operations';
			|it = 'Testing delle operazioni di chiusura del mese';
			|pl = 'Testowanie operacji zamknięcia miesiąca';
			|tr = 'Ay sonu kapanış işleminin test edilmesi'"));
	
	Return Job.UUID;
	
EndFunction

Function TestStartupParameters(InputParameters = Undefined) Export
	
	JobParameters = New Structure;
	JobParameters.Insert("CompaniesList", New ValueList);
	JobParameters.Insert("CalculationStart", CostPerPeriod());
	JobParameters.Insert("CalculationEnd", CurrentSessionDate());
	JobParameters.Insert("RegistrationPeriod", CurrentSessionDate());
	JobParameters.Insert("Period", CurrentSessionDate());
	JobParameters.Insert("ControlRegisters", Undefined);
	JobParameters.Insert("StorageAddress", Undefined);
	JobParameters.Insert("TestingStages", TestingStages());
	JobParameters.Insert("Sections", TestSections().UnloadValues());
	JobParameters.Insert("ActionInCaseOfDivergence", "Stop");
	JobParameters.Insert("DiscrepancyLimit", 5000);
	JobParameters.Insert("AllowableVariance", "0.5");
	JobParameters.Insert("AutoTesting", False);
	
	If ValueIsFilled(InputParameters) Then
		
		ParameterValue = Undefined;
		ParametersStructure = StringFunctionsClientServer.ParametersFromString(InputParameters);
		
		If ParametersStructure.Property("CalculationStart", ParameterValue) And ValueIsFilled(ParameterValue) Then
			JobParameters.CalculationStart = Date(StrReplace(ParameterValue, """", ""));
		EndIf;
		
		If ParametersStructure.Property("CalculationEnd", ParameterValue) And ValueIsFilled(ParameterValue) Then
			JobParameters.CalculationEnd = Date(StrReplace(ParameterValue, """", ""));
		EndIf;
		
		If ParametersStructure.Property("Sections", ParameterValue) And ValueIsFilled(ParameterValue) Then
			JobParameters.Sections = StrSplit(ParameterValue, ",");
		EndIf;
		
		If ParametersStructure.Property("TestingStages", ParameterValue) And ValueIsFilled(ParameterValue) Then
			TestingStages = StrSplit(ParameterValue, ",");
			For Each TestingPhase In JobParameters.TestingStages Do
				TestingPhase.Check = TestingStages.Find(TestingPhase.Value) <> Undefined;
			EndDo;
		EndIf;
		
		If ParametersStructure.Property("ActionInCaseOfDivergence", ParameterValue) And ValueIsFilled(ParameterValue) Then
			JobParameters.ActionInCaseOfDivergence = ParameterValue;
		EndIf;
		
		If ParametersStructure.Property("DiscrepancyLimit", ParameterValue) And ValueIsFilled(ParameterValue) Then
			JobParameters.DiscrepancyLimit = Number(StrReplace(ParameterValue, """", ""));
		EndIf;
		
		If ParametersStructure.Property("AllowableVariance", ParameterValue) And ValueIsFilled(ParameterValue) Then
			JobParameters.AllowableVariance = ParameterValue;
		EndIf;
		
		JobParameters.AutoTesting = True;
	
	EndIf;
	
	JobParameters.ControlRegisters = ControlRegisters(JobParameters.Sections);
	
	Return JobParameters;
	
EndFunction

#Region TestingSettings

// List of testing stages that can be used during testing.
// For them, the borders will be reset before the start of testing processing and the corresponding tasks from the end
// of the month will be completed during processing.
//
// Returns:
// ValueList - a list of stages for which testing can be performed.
//
Function TestSections() Export
	
	TestSections = New ValueList;
	TestSections.Add("MutualSettlementsWithPartners", " " + NStr("vi = 'Đối trừ lẫn nhau với các đối tác';
																|ru = 'Взаиморасчеты с партнерами';
																|en = 'AR/AP accounting with partners'; fa = 'AR/AP accounting with partners';
																|it = 'Regolazioni con i partner';
																|pl = 'Rozliczenia wzajemne z partnerami';
																|tr = 'İş ortaklarıyla mutabakatlar'"), True);
	TestSections.Add("Cost_", " " + NStr("vi = 'Giá vốn';
										|ru = 'Себестоимость';
										|en = 'Cost'; fa = 'بهای تمام‌شده';
										|it = 'Costi di produzione';
										|pl = 'Koszty własne';
										|tr = 'Maliyet'"), True);
	If GetFunctionalOption("UseFinancialAccounting") Then
		TestSections.Add("FinancialAccounting", " " + NStr("vi = 'Phản ánh vào kế toán quốc tế';
															|ru = 'Отражение в международном учете';
															|en = 'General ledger posting'; fa = 'ثبت در دفتر کل';
															|it = 'Visualizzazione in contabilità internazionale';
															|pl = 'Odzwierciedlenie w ewidencji międzynarodowej';
															|tr = 'Uluslararası muhasebede geçerlilik'"), True);
	EndIf;
	Return TestSections;
	
EndFunction

Function TestingStages(TestNewMechanisms = False) Export
	
	TestingStages = New ValueList;
	// By default, we always close the month:
	TestingStages.Add("ReOrderMonth", " " + NStr("vi = 'Đóng lại tháng';
												|ru = 'Перезакрытие месяца';
												|en = 'Month-end reclosing'; fa = 'Month-end reclosing';
												|it = 'Richiusura del mese';
												|pl = 'Ponowne zamknięcie miesiąca';
												|tr = 'Ayın tekrar kapanışı'"), True);
	If TestNewMechanisms Then
	EndIf;
	//The testing stage.Add("Save personal data", "Save reference data");
	//The testing stage.Add("Compare with reference data", "Compare with reference data");
		
	Return TestingStages;
	
EndFunction

// Compliance with the registers used for monitoring movements before and after the month closing.
// If differences are detected, they are recorded and displayed in the "test Results" report.
//
// Returns:
//	Map - matching metadata and section names.
Function ComplianceOfControlRegisters(SelectedSections = Undefined) Export
	
	If SelectedSections = Undefined Then
		SelectedSections = TestSections().UnloadValues();
	EndIf;
	
	ControlRegisters_ = New Map;
	
	If SelectedSections.Find("MutualSettlementsWithPartners") <> Undefined Then // ARAPAccounting
		If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
			ControlRegisters_.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments.FullName(), "MutualSettlementsWithPartners");
			ControlRegisters_.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments.FullName(), "MutualSettlementsWithPartners");
		EndIf;
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.RecordsCashCounterparty.FullName(), "MutualSettlementsWithPartners");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.RecordsCounterpartyCounterparty.FullName(), "MutualSettlementsWithPartners");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.RecordsCounterpartyIncomeExpenses.FullName(), "MutualSettlementsWithPartners");
	EndIf;
	
	If SelectedSections.Find("Cost_") <> Undefined Then // Cost_
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.InventoryCost.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.RevenueAndCOGS.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.Purchases.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.RecordsProductsProducts.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.OtherIncome.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.OtherAssetsLiabilities.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.FinancialResults.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.RevenueServicesAndAssets.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.GoodsCostVariances.FullName(), "Cost_");
		
		// BatchAccounting
		ControlRegisters_.Insert(Metadata.InformationRegisters.ItemizeGoodsLotCost.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.InformationRegisters.ItemizeLotCostItemizedAndOtherCosts.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.OtherExpenses.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.WIPLaborCosts.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.AccumulationRegisters.MaterialsAndWorksInProduction.FullName(), "Cost_");
		ControlRegisters_.Insert(Metadata.InformationRegisters.AllocationBaseForIndirectExpensesAllocation.FullName(), "Cost_");
		
	EndIf;
	
	
	If SelectedSections.Find("FinancialAccounting") <> Undefined Then //International accounting
		ControlRegisters_.Insert(Metadata.AccountingRegisters.International.FullName(), "FinancialAccounting");
	EndIf;
	Return ControlRegisters_;
	
EndFunction

// A list of registers used for monitoring movements before and after the month close.
// If differences are detected, they are recorded and displayed in the "test Results" report.
//
// Returns:
//	Array - an array of metadata names.
Function ControlRegisters(SelectedSections = Undefined) Export
	
	ControlRegisters_ = New Array;
	For Each String In ComplianceOfControlRegisters(SelectedSections) Do
		ControlRegisters_.Add(String.Key);
	EndDo; 
	
	Return ControlRegisters_;
	
EndFunction

Function MatchingRegistersToSections()
	
	MatchingSectionsToRegisters = New Map;
	For Each Section In TestSections().UnloadValues() Do
		SectionRegisters = ControlRegisters(CommonClientServer.ValueInArray(Section));
		For Each Register In SectionRegisters Do
			MatchingSectionsToRegisters.Insert(Register, Section);
		EndDo;
	EndDo;
	
	Return MatchingSectionsToRegisters;
	
EndFunction

Function ActionsForDiscrepancies() Export
	
	ReturnList_ = New ValueList;
	ReturnList_.Add("Continue", NStr("vi = 'Tiếp tục thử nghiệm';
									|ru = 'Продолжить тестирование';
									|en = 'Continue testing'; fa = 'Continue testing';
									|it = 'Continuare il test';
									|pl = 'Kontynuuj testowanie';
									|tr = 'Test etmeyi devam et'"));
	ReturnList_.Add("Stop", NStr("vi = 'Dừng thử nghiệm';
								|ru = 'Остановить тестирование';
								|en = 'Stop testing'; fa = 'Stop testing';
								|it = 'Sospendere il test';
								|pl = 'Zatrzymaj testowanie';
								|tr = 'Test etmeyi durdur'"));
	ReturnList_.Add("StopCondition", NStr("vi = 'Dừng thử nghiệm khi đạt đến hạn mức sai lệch';
											|ru = 'Остановить тестирование при достижении лимита расхождений';
											|en = 'Stop testing when reaching discrepancy limit'; fa = 'Stop testing when reaching discrepancy limit';
											|it = 'Sospendere il test al raggiungimento del limite di discrepanze';
											|pl = 'Zatrzymaj testowanie po osiągnięciu limitu odchylenia';
											|tr = 'Tutarsızlık sınırına ulaşıldığında testi durdur'"));
	ReturnList_.Add("SplitFile", NStr("vi = 'Khi đạt đến hạn mức sai lệch, hãy tách tệp sai lệch';
										|ru = 'При достижении лимита расхождений разбивать файл расхождений';
										|en = 'Split discrepancy file when reaching discrepancy limit'; fa = 'Split discrepancy file when reaching discrepancy limit';
										|it = 'Al raggiungimento del limite di discrepanze suddividere il file delle discrepanze';
										|pl = 'Po osiągnięciu limitu odchylenia podziel plik odchylenia';
										|tr = 'Tutarsızlık sınırına ulaşıldığında tutarsızlık dosyasını bölme'"));
	
	Return ReturnList_;
	
EndFunction

// Returns the period of the very first movement in the "Cost of goods" register.
// 
// Returns:
//	Date - 
Function CostPerPeriod() Export
	Query = New Query("
	|SELECT
	|	MIN(DD.Period) AS Period
	|FROM
	|	AccumulationRegister.InventoryCost AS DD
	|HAVING
	|	NOT (MIN(DD.Period) IS NULL)
	|");
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Period = BegOfMonth(CurrentSessionDate());
	Else
		Period = BegOfMonth(Result.Unload()[0].Period);
	EndIf;
	
	Return Period;
EndFunction

#EndRegion // TestingSettings

Function StartTimeMeasurement(Parameters, OutputText_) Export
	
	MeasurementStart = Undefined;
	If Parameters.Property("Log_") Then
		MeasurementStart = CurrentUniversalDateInMilliseconds();
		Parameters.Log_ = Parameters.Log_ + Chars.LF + "Begin" + " """ + OutputText_ + """";
	EndIf;
	WriteLogEvent("Begin" + " """ + OutputText_ + """", EventLogLevel.Information);
	
	Return MeasurementStart;
	
EndFunction

Procedure StopTimeMeasurement(Parameters, OutputText_, MeasurementStart) Export
	
	If Parameters.Property("Log_") Then
		Duration = RunTime(MeasurementStart, CurrentUniversalDateInMilliseconds());
		Parameters.Log_ = Parameters.Log_ + Chars.LF + "End" + " """ + OutputText_ + """, " + "duration:" + " " + Duration;
	EndIf;
	WriteLogEvent("End" + " """ + OutputText_ + """, " + "duration:" + " " + Duration, EventLogLevel.Information);
	
EndProcedure

#EndRegion

#Region ServiceProceduresFunctions

Function TestForPeriod(ProcessingParameters)
	
	TestResult_ = New Structure("Cancel", False);
	
	ParameterValues = CalculationOfCostCached.ValuesOfTechnologicalParameters();
	
	MeasurementStart = StartTimeMeasurement(ProcessingParameters, "TestForPeriod");
	
	CostRecordPeriod = BatchAccountingServer.PeriodOfFirstRegisteredRecordsOfRegisterCost();
	If ValueIsFilled(ParameterValues.TestingStartPeriod)
	 And BegOfDay(ParameterValues.TestingStartPeriod) <> CostRecordPeriod Then
		ProcessingParameters.CalculationStart = Max(BegOfDay(ParameterValues.TestingStartPeriod), CostRecordPeriod);
	ElsIf ValueIsFilled(CostRecordPeriod) 
	 And ProcessingParameters.CalculationStart < CostRecordPeriod Then
		ProcessingParameters.CalculationStart = CostRecordPeriod;
	EndIf;
	 
	PeriodOfRecentRegisteredRecords = BatchAccountingServer.PeriodOfLastRegisteredRecordsOfRegisterCost();
	If ValueIsFilled(ParameterValues.EndOfTestingPeriod)
	 And BegOfMonth(ParameterValues.EndOfTestingPeriod) <> PeriodOfRecentRegisteredRecords Then
		ProcessingParameters.CalculationEnd = Min(BegOfMonth(ParameterValues.EndOfTestingPeriod), PeriodOfRecentRegisteredRecords);
	ElsIf ValueIsFilled(PeriodOfRecentRegisteredRecords) 
	 And ProcessingParameters.CalculationEnd > PeriodOfRecentRegisteredRecords Then
		ProcessingParameters.CalculationEnd = PeriodOfRecentRegisteredRecords;
	EndIf;
	
	ProcessingParameters.CalculationEnd = EndOfMonth(ProcessingParameters.CalculationEnd);
	
	For Each TestingPhase In ProcessingParameters.TestingStages Do
		
		If Not TestingPhase.Check Then
			Continue;
		EndIf;
		
		DataComparisonParameters = Testing.QueryOptions(ProcessingParameters.CalculationStart);
		DataComparisonParameters.EndOfPeriod = ProcessingParameters.CalculationEnd;
		If ProcessingParameters.Property("AllowableVariance") Then
			DataComparisonParameters.Insert("AllowableVariance", ProcessingParameters.AllowableVariance);
			DataComparisonParameters.Insert("DetermineOverallDiscrepancy", True);
		EndIf;
		ExcludedFields = New Structure("FinRecordID, Content");
		ExcludedFields.Insert("CostDefiningMethod");
		ExcludedFields.Insert("CostCalculationDate");
		ExcludedFields.Insert("CostAccountingTransaction");
		ExcludedFields.Insert("AdjustmentSet");
		DataComparisonParameters.Insert("ExcludedFields", ExcludedFields);
		
		MeasurementStart1 = StartTimeMeasurement(ProcessingParameters, "SaveReferenceData");
		
		TemporaryReferenceDataTables = Undefined;
		PerformComparisonOfReferenceData = Not ProcessingParameters.Property("SkipComparisonOfReferenceData");
		If PerformComparisonOfReferenceData Then
			If ProcessingParameters.Property("ReferenceData") Then
				TemporaryReferenceDataTables = Testing.SaveReferenceData(ProcessingParameters.ControlRegisters, DataComparisonParameters, ,ProcessingParameters.ReferenceData);
			Else 
				TemporaryReferenceDataTables = Testing.SaveReferenceData(ProcessingParameters.ControlRegisters, DataComparisonParameters);
			EndIf; 
		EndIf;

		StopTimeMeasurement(ProcessingParameters, "SaveReferenceData", MeasurementStart1);
		
		
		If TestingPhase.Value = "ReOrderMonth" Then
			
			ClosingMonthFromDate(ProcessingParameters, ProcessingParameters.Sections);
			
		EndIf;

		Discrepancies = New Map;
		MeasurementStart4 = StartTimeMeasurement(ProcessingParameters, "CompareWithReferenceData");

		If PerformComparisonOfReferenceData And TemporaryReferenceDataTables <> Undefined Then
			If ProcessingParameters.Property("ReferenceData") Then
				Discrepancies = Testing.CompareWithReferenceData(TemporaryReferenceDataTables, ProcessingParameters.ControlRegisters, DataComparisonParameters,, ProcessingParameters.ReferenceData);
			Else
				Discrepancies = Testing.CompareWithReferenceData(TemporaryReferenceDataTables, ProcessingParameters.ControlRegisters, DataComparisonParameters);
			EndIf;
		EndIf;
	
		StopTimeMeasurement(ProcessingParameters, "CompareWithReferenceData", MeasurementStart4);

		DataOfDiscrepanciesBySection = DataOfDiscrepanciesBySection(TestingPhase.Value, Discrepancies);
		
		StageKey = "DiscrepancyData";
		If Not TestingPhase.Value = "ReOrderMonth" Then
			StageKey = StageKey + "_" + TestingPhase.Value;
		EndIf;
		TestResult_.Insert(StageKey, DataOfDiscrepanciesBySection);
		
		If Discrepancies.Get("NumberOfDiscrepancies") > 0 And ProcessingParameters.ActionInCaseOfDivergence = "Stop" Then
			Break;
		EndIf;
		
		If Discrepancies.Get("NumberOfDiscrepancies") > ProcessingParameters.DiscrepancyLimit And ProcessingParameters.ActionInCaseOfDivergence = "StopCondition" Then
			Break;
		EndIf;
		
	EndDo;
	
	NumberOfDiscrepancies = 0;
	
	StopTimeMeasurement(ProcessingParameters, "TestForPeriod", MeasurementStart);
	
	Return TestResult_;
	
EndFunction

Function TestAccordingToTestPlan(TestPlan, ProcessingParameters)
	
	TestResult_ = New Structure("Cancel", False);
	ReturnToOldSettlementArchitecture = False;
	
	For Each StageString_ In TestPlan.Rows Do
		
		If Not StageString_.Use Then
			Continue;
		EndIf;
		
		TimeConsumingOperations.ReportProgress(15, StageString_.NodeName);
		
		DataComparisonParameters = Testing.QueryOptions(ProcessingParameters.CalculationStart);
		DataComparisonParameters.EndOfPeriod = ProcessingParameters.CalculationEnd;
		ExcludedFields = New Structure("FinRecordID, Content");
		ExcludedFields.Insert("CostDefiningMethod");
		ExcludedFields.Insert("CostCalculationDate");
		ExcludedFields.Insert("AdjustmentSet");
		DataComparisonParameters.Insert("ExcludedFields", ExcludedFields);
		
		TimeConsumingOperations.ReportProgress(15, NStr("vi = 'Lưu dữ liệu tiêu chuẩn';
														|ru = 'Сохранение эталонных данных';
														|en = 'Save reference data'; fa = 'Save reference data';
														|it = 'Сохранение эталонных данных';
														|pl = 'Save reference data';
														|tr = 'Referans verilerini kaydetme'"));
		
		ControlRegisters = New Array;
		TestSections = New Array;
		For Each SectionRow In StageString_.Rows Do
			If Not SectionRow.Use Then
				Continue;
			EndIf;
			TestSections.Add(SectionRow.NodeName);
			For Each RegisterLine In SectionRow.Rows Do
				If RegisterLine.Use Then
					ControlRegisters.Add(RegisterLine.NodeName);
				EndIf;
			EndDo;
		EndDo;
		
		TemporaryReferenceDataTables = Testing.SaveReferenceData(ControlRegisters, DataComparisonParameters);
		
		If StageString_.NodeName = "SwitchingToNewSettlements" Then
			
			TimeConsumingOperations.ReportProgress(15, NStr("vi = 'Điền biểu ghi theo chứng từ hạch toán';
															|ru = 'Заполнение регистров по расчетным документам';
															|en = 'Fill registers by AR/AP documents'; fa = 'Fill registers by AR/AP documents';
															|it = 'Заполнение регистров по расчетным документам';
															|pl = 'Fill registers by AR/AP documents';
															|tr = 'Alacak/Borç belgeleri için kayıtların doldurulması'"));
		
			JobParameters = New Structure("Date", ProcessingParameters.CalculationStart);
			OnlineARAPAccountingServer.FillRegistersWhenEnablingNewArchitecture(JobParameters, Undefined);
		
			ClosingMonthFromDate(ProcessingParameters, TestSections);
			
		EndIf;
		
		If StageString_.NodeName = "ReFillInNewSettlements" Then
			
			TimeConsumingOperations.ReportProgress(15, NStr("vi = 'Điền lại hạch toán';
															|ru = 'Перезаполнение взаиморасчетов';
															|en = 'Refill AR/AP accounting'; fa = 'Refill AR/AP accounting';
															|it = 'Перезаполнение взаиморасчетов';
															|pl = 'Refill AR/AP accounting';
															|tr = 'Mutabakatların yeniden doldurulması'"));
		
			OnlineARAPAccountingServer.FillInAllCalculations();
		
			ClosingMonthFromDate(ProcessingParameters, TestSections);
			
		EndIf;
		
		If StageString_.NodeName = "ReOrderMonth" Then
			
			ClosingMonthFromDate(ProcessingParameters, TestSections);
			
		EndIf;
		
		TimeConsumingOperations.ReportProgress(15, NStr("vi = 'So sánh dữ liệu tiêu chuẩn';
														|ru = 'Сравнение эталонных данных';
														|en = 'Compare reference data'; fa = 'Compare reference data';
														|it = 'Сравнение эталонных данных';
														|pl = 'Compare reference data';
														|tr = 'Kıyaslama verilerinin karşılaştırılması'"));
		
		Discrepancies = Testing.CompareWithReferenceData(TemporaryReferenceDataTables, ControlRegisters, DataComparisonParameters);
		StageString_.NumberOfDiscrepancies = Discrepancies.Get("NumberOfDiscrepancies");
		
		TimeConsumingOperations.ReportProgress(15, NStr("vi = 'Điền dữ liệu chênh lệch';
														|ru = 'Заполнение данных расхождений';
														|en = 'Fill discrepancy data'; fa = 'Fill discrepancy data';
														|it = 'Заполнение данных расхождений';
														|pl = 'Fill discrepancy data';
														|tr = 'Tutarsızlık verilerinin doldurulması'"));
		
		FillInTestResults(StageString_, Discrepancies);
		
		If StageString_.NumberOfDiscrepancies > 0 And ProcessingParameters.ActionInCaseOfDivergence = "Stop" Then
			Break;
		EndIf;
		
		If StageString_.NumberOfDiscrepancies > ProcessingParameters.DiscrepancyLimit And ProcessingParameters.ActionInCaseOfDivergence = "StopCondition" Then
			Break;
		EndIf;
		
		If StageString_.NodeName = "SwitchingToNewSettlements" And StageString_.NumberOfDiscrepancies = 0 Then
			ReturnToOldSettlementArchitecture = True;
		EndIf;
		
		If StageString_.NodeName = "ReFillInNewSettlements" And StageString_.NumberOfDiscrepancies <> 0 And ReturnToOldSettlementArchitecture Then
			ReturnToOldSettlementArchitecture = False;
		EndIf;
		
	EndDo;
	
	If ReturnToOldSettlementArchitecture Then
		Constants.NewOnlineARAPAccounting.Set(False);
	EndIf;
	
	Return TestResult_;
	
EndFunction

Procedure ReportError()
	WriteLogEvent(NStr("vi = 'Kiểm tra';
						|ru = 'Тестирование';
						|en = 'Testing'; fa = 'آزمون';
						|it = 'Testing';
						|pl = 'Testing';
						|tr = 'Test'", Common.DefaultLanguageCode())
		 	+ "." + NStr("vi = 'Lỗi kiểm tra';
							|ru = 'Ошибка тестирования';
							|en = 'Test error'; fa = 'Test error';
							|it = 'Errore di test';
							|pl = 'Błąd testowania';
							|tr = 'Test hatası'", Common.DefaultLanguageCode()),
		EventLogLevel.Error, , , DetailErrorDescription(ErrorInfo()));
EndProcedure

Function DataOfDiscrepanciesBySection(TestingPhase, Discrepancies)
	
	DiscrepancyData = New Map;
	
	If ValueIsFilled(Discrepancies) And Discrepancies.Get("NumberOfDiscrepancies") <> 0 Then
		
		MatchingRegistersToSections = MatchingRegistersToSections();
		
		SectionDiscrepancyData = New Map;
		AllDocumentsDiverge = New Array;
		// we collect documents with discrepancies by sections and separately a common array
		For Each String In Discrepancies Do
			CurDivergenceSection = MatchingRegistersToSections[String.Key];
			If CurDivergenceSection <> Undefined Then
				If SectionDiscrepancyData.Get(CurDivergenceSection) = Undefined Then
					SectionDiscrepancyData.Insert(CurDivergenceSection, New Array);
				EndIf;
				
				If String.Value.Property("Documents") Then
					CommonClientServer.SupplementArray(
						SectionDiscrepancyData[CurDivergenceSection],
						String.Value.Documents,
						True);
					CommonClientServer.SupplementArray(
						AllDocumentsDiverge,
						String.Value.Documents,
						True);
				Else
					CommonClientServer.ValueInArray(Undefined);
					CommonClientServer.SupplementArray(
						SectionDiscrepancyData[CurDivergenceSection],
						CommonClientServer.ValueInArray(Undefined),
						True);
					CommonClientServer.SupplementArray(
						AllDocumentsDiverge,
						CommonClientServer.ValueInArray(Undefined),
						True);
				EndIf;
				
			EndIf;
		EndDo;
		
		For Each SectionDiscrepancies In SectionDiscrepancyData Do
			Section = SectionDiscrepancies.Key;
			DocumentDiscrepancyData_ = New Map;
			For Each DocumentDiscrepancies In SectionDiscrepancies.Value Do
				StructureOfDiscrepancies = SectionDivergenceStructure(Section);
				DocumentDiscrepancyData_.Insert(DocumentDiscrepancies, StructureOfDiscrepancies);
				For Each String In Discrepancies Do
					If MatchingRegistersToSections[String.Key] = Section Then
						
						StructureOfDiscrepancies.File.WriteStartElement("MetadataObject");
						XMLLine = Common.ValueToXMLString(String.Key); // Register name
						StructureOfDiscrepancies.File.WriteText(XMLLine);
						NameOfRegistrar = Testing.NameOfRegisterRegistrarField(String.Key);
							
						If String.Value.Property("Table") Then
							
							TableOfDiscrepancies = String.Value.Table;
							LinesByDocument = TableOfDiscrepancies.FindRows(New Structure(NameOfRegistrar, DocumentDiscrepancies));
							DocumentDiscrepancyTable = TableOfDiscrepancies.Copy(LinesByDocument);
							
							StructureOfDiscrepancies.File.WriteStartElement("Records");
							StructureOfDiscrepancies.File.WriteText(Common.ValueToXMLString(DocumentDiscrepancyTable));
							StructureOfDiscrepancies.File.WriteEndElement(); // Records
							
						Else
							
							StructureOfDiscrepancies.File.WriteStartElement("Records");
							StructureOfDiscrepancies.File.WriteText(String.Value.Records);
							StructureOfDiscrepancies.File.WriteEndElement(); // Records
							
						EndIf;
						
						StructureOfDiscrepancies.File.WriteEndElement(); // Register name
							
						StructureOfDiscrepancies.Count = String.Value.Count; // maximum by case
						
					EndIf;
				EndDo;
			EndDo;
			
			StructureOfDiscrepancies = SectionDivergenceStructure(Section);
			DocumentDiscrepancyData_.Insert("GeneralSectionDiscrepancies", StructureOfDiscrepancies);
			
			For Each String In Discrepancies Do
				If MatchingRegistersToSections[String.Key] = Section Then
					
					StructureOfDiscrepancies.File.WriteStartElement("MetadataObject");
					XMLLine = Common.ValueToXMLString(String.Key); // Register name
					StructureOfDiscrepancies.File.WriteText(XMLLine);
					NameOfRegistrar = Testing.NameOfRegisterRegistrarField(String.Key);
					
					If String.Value.Property("Table") Then
						
						TableOfDiscrepancies = String.Value.Table;
						RowsByDocuments = New Array;
						For Each DocumentDiscrepancies In AllDocumentsDiverge Do
							CommonClientServer.SupplementArray(
								RowsByDocuments,
								TableOfDiscrepancies.FindRows(New Structure(NameOfRegistrar, DocumentDiscrepancies)));
						EndDo;
					
						StructureOfDiscrepancies.File.WriteStartElement("Records");
						StructureOfDiscrepancies.File.WriteText(Common.ValueToXMLString(TableOfDiscrepancies.Copy(RowsByDocuments)));
						StructureOfDiscrepancies.File.WriteEndElement(); // Records
						
					Else
						
						StructureOfDiscrepancies.File.WriteStartElement("Records");
						StructureOfDiscrepancies.File.WriteText(String.Value.Records);
						StructureOfDiscrepancies.File.WriteEndElement(); // Records
						
					EndIf;
					
					StructureOfDiscrepancies.File.WriteEndElement(); // Register name
					
					StructureOfDiscrepancies.Count = String.Value.Count; // maximum by case
					
				EndIf;
			EndDo;
			
			For Each DocumentDiscrepancyData In DocumentDiscrepancyData_ Do
				
				WriteReportFile(DocumentDiscrepancyData.Value.File);
				TestData_ = New BinaryData(DocumentDiscrepancyData.Value.PathToFile);
				StorageAddress = PutToTempStorage(TestData_, New UUID);
				DocumentDiscrepancyData.Value.Insert("StorageAddress", StorageAddress);
				DeleteFiles(DocumentDiscrepancyData.Value.PathToFile);
				DocumentDiscrepancyData.Value.Delete("File");
				
			EndDo;
			
			DiscrepancyData.Insert(Section, DocumentDiscrepancyData_);
			
		EndDo;
	EndIf;
	
	Return DiscrepancyData;
	
EndFunction

Procedure FillInTestResults(StageString_, Discrepancies)
	
	If Not ValueIsFilled(Discrepancies) Or Discrepancies.Get("NumberOfDiscrepancies") = 0 Then
		Return;
	EndIf;
	
	StageDivergenceFile = CreateReportFileAndSaveFilePath(StageString_);
	
	For Each SectionRow In StageString_.Rows Do
		If Not SectionRow.Use Then
			Continue;
		EndIf;
		
		SectionDiscrepanciesFile = CreateReportFileAndSaveFilePath(SectionRow);
		
		For Each RegisterLine In SectionRow.Rows Do
			If Not RegisterLine.Use Then
				Continue;
			EndIf;
			CaseDiscrepancies = Discrepancies.Get(RegisterLine.NodeName);
			If CaseDiscrepancies = Undefined Then
				Continue;
			EndIf;
			
			RegisterDiscrepanciesFile = CreateReportFileAndSaveFilePath(RegisterLine);
			
			AddCaseDiscrepanciesToReportFile(RegisterLine.NodeName, SectionRow.NumberOfDiscrepancies, SectionDiscrepanciesFile, CaseDiscrepancies);
			AddCaseDiscrepanciesToReportFile(RegisterLine.NodeName, RegisterLine.NumberOfDiscrepancies, RegisterDiscrepanciesFile, CaseDiscrepancies);
			AddCaseDiscrepanciesToReportFile(RegisterLine.NodeName, StageString_.NumberOfDiscrepancies, StageDivergenceFile, CaseDiscrepancies);
			
			WriteFileAndSaveData(RegisterLine, RegisterDiscrepanciesFile);
			
		EndDo;
		
		WriteFileAndSaveData(SectionRow, SectionDiscrepanciesFile);
		
	EndDo;
	
	WriteFileAndSaveData(StageString_, StageDivergenceFile);
	
EndProcedure

Function SectionDivergenceStructure(CurDivergenceSection)
	
	ReturnStructure = New Structure;
	
	PathToFile = GetTempFileName("xml");
	ReportFile = CreateReportFile(PathToFile);
	ReturnStructure.Insert("Count", 0);
	ReturnStructure.Insert("File", ReportFile);
	ReturnStructure.Insert("MetadataObject", SectionDiscrepancyMetadata(CurDivergenceSection));
	ReturnStructure.Insert("PathToFile", PathToFile);
	
	Return ReturnStructure;
	
EndFunction

Function SectionDiscrepancyMetadata(Section)
	
	MatchingMetadataAndSections = New Map;
	MatchingMetadataAndSections.Insert("Cost_", "AccumulationRegisters.InventoryCost");
	MatchingMetadataAndSections.Insert("MutualSettlementsWithPartners", "AccumulationRegisters.VendorsARAPAccounting");
	MatchingMetadataAndSections.Insert("FinancialAccounting", "AccountingRegisters.International");
	Return MatchingMetadataAndSections.Get(Section);
	
EndFunction

#Region MonthEndTransactions

Procedure ClosingMonthFromDate(Parameters, Sections = Undefined)
	
	SetTasksToBeCalculatedOnDate(Parameters, Sections);
	TestMonth = Parameters.CalculationStart;
	
	TestingClosingOfMonth = True;
	
	While TestMonth <= Parameters.CalculationEnd Do
		
		MeasurementStart = StartTimeMeasurement(Parameters, "TestingClosingOfMonth" + " " + TestMonth);
		
		
		If TestingClosingOfMonth Then
			MonthEndTransactionsServer.TestingClosingOfMonth(TestMonth);
		EndIf;
		
		StopTimeMeasurement(Parameters, "TestingClosingOfMonth" + " " + TestMonth, MeasurementStart);
		
		TestMonth = EndOfMonth(TestMonth) + 1;
		
	EndDo;
	
EndProcedure

Procedure SetTasksToBeCalculatedOnDate(Parameters, SelectedSections = Undefined)
	
	If SelectedSections = Undefined Then
		SelectedSections = TestSections().UnloadValues();
	EndIf;
	
	CompanyArray 	= Catalogs.Companies.AvailableCompanies();
	InfoAboutLock = InformationRegisters.SetUpLockFromChanges.InformationAboutBlockingChanges(CompanyArray);
	TableOfLocks 	= InfoAboutLock.TableOfLocks;
	
	TableOfLocks.Sort("BlockingPeriod");
	TableOfLocks.Indexes.Add("BlockingPeriod");
	
	PeriodsTable = TableOfLocks.Copy(, "BlockingPeriod");
	PeriodsTable.GroupBy("BlockingPeriod", "");
	
	For Each PeriodString_ In PeriodsTable Do
		
		CompaniesByPeriod = New Array;
		RowsOfOrganizations = TableOfLocks.FindRows(New Structure("BlockingPeriod", PeriodString_.BlockingPeriod));
		
		For Each CurrRow In RowsOfOrganizations Do
			CompaniesByPeriod.Add(CurrRow.Organization);
		EndDo;
		
		If Not ValueIsFilled(PeriodString_.BlockingPeriod) Then
			Period = Parameters.CalculationStart;
		Else
			Period = Max(Parameters.CalculationStart, AddMonth(PeriodString_.BlockingPeriod, 1));
		EndIf;
		
		If BegOfMonth(Period) > BegOfMonth(Parameters.CalculationEnd) Then
			Continue; // a lock has been set for the entire settlement period 
		EndIf;
		
		For Each CalculationSection In SelectedSections Do
			
			If CalculationSection = "Cost_" Then
				MeasurementStart1 = StartTimeMeasurement(Parameters, "Set-Cost_");
				InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(Period,, CompaniesByPeriod); // for all organizations
				StopTimeMeasurement(Parameters, "Set-Cost_", MeasurementStart1);
			EndIf;
			
			If CalculationSection = "MutualSettlementsWithPartners" Then
				MeasurementStart2 = StartTimeMeasurement(Parameters, "Set-MutualSettlementsWithPartners");
				If GetFunctionalOption("NewOnlineARAPAccounting") Then
					InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(Period,, CompaniesByPeriod, Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation);
				Else
					InformationRegisters.JobsForAllocatingCustomersARAP.CreateRegisterEntry(Period, CompaniesByPeriod); // for all organizations
					InformationRegisters.JobsForAllocatingVendorsARAP.CreateRegisterEntry(Period, CompaniesByPeriod); // for all organizations
				EndIf;
				StopTimeMeasurement(Parameters, "Set-MutualSettlementsWithPartners", MeasurementStart2);
			EndIf;
				
			
			If CalculationSection = "FinancialAccounting" Then
				MeasurementStart7 = StartTimeMeasurement(Parameters, "Set-FinancialAccounting");
				InternationalAccountingToRegisterDocumentsForReflection(BegOfMonth(Period), EndOfMonth(Parameters.CalculationEnd), CompaniesByPeriod);
				StopTimeMeasurement(Parameters, "Set-FinancialAccounting", MeasurementStart7);
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure


Procedure InternationalAccountingToRegisterDocumentsForReflection(BeginOfPeriod, EndOfPeriod, Organization = Undefined, DocumentTypes = Undefined)
	
	If DocumentTypes = Undefined Then
		DocumentTypes = New Array;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentPostingInFinancialAccounting.Period AS Period,
	|	DocumentPostingInFinancialAccounting.Recorder AS Document,
	|	DocumentPostingInFinancialAccounting.Organization AS Organization,
	|	DocumentPostingInFinancialAccounting.DateRecord AS DateRecord
	|INTO DocumentsToBeReflected
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|WHERE
	|	DocumentPostingInFinancialAccounting.DateRecord BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (&AllCompanies
	|			OR DocumentPostingInFinancialAccounting.Organization IN (&Organization))
	|	AND (&AllDocuments
	|			OR VALUETYPE(DocumentPostingInFinancialAccounting.Recorder) IN (&DocumentTypes))
	|
	|INDEX BY
	|	Period,
	|	Document,
	|	Organization,
	|	DateRecord";
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfPeriod);
	Query.SetParameter("AllCompanies", Not ValueIsFilled(Organization));
	Query.SetParameter("Organization", ?(ValueIsFilled(Organization), Organization, New Array));
	Query.SetParameter("DocumentTypes", DocumentTypes);
	Query.SetParameter("AllDocuments", DocumentTypes.Count() = 0);
	
	Query.TempTablesManager = New TempTablesManager;
	Query.Execute();
	FinancialAccountingPostingServer.ReturnDocumentsToReflection(Query.TempTablesManager);
	
EndProcedure
#EndRegion

#Region FilesOperations

Function CreateReportFile(PathToFile) Export
	ReportFile = New XMLWriter;
	ReportFile.OpenFile(PathToFile);
	
	ReportFile.WriteXMLDeclaration();
	
	ReportFile.WriteStartElement("Root");
	Return ReportFile;
EndFunction

Procedure WriteReportFile(ReportFile)
	If ReportFile <> Undefined Then
		ReportFile.WriteEndElement(); // Root
		ReportFile.Close();
	EndIf;
EndProcedure

Function CreateReportFileAndSaveFilePath(TestPlanLine)
	
	PathToFile = GetTempFileName("xml");
	DiscrepancyFile = CreateReportFile(PathToFile);
	TestPlanLine.PathToFile = PathToFile;
	
	Return DiscrepancyFile;
	
EndFunction

Procedure AddCaseDiscrepanciesToReportFile(RegisterName, NumberOfDiscrepanciesInTestPlan, ReportFile, CaseDiscrepancies)
	
	ReportFile.WriteStartElement("MetadataObject");
	XMLLine = Common.ValueToXMLString(RegisterName); // Register name
	ReportFile.WriteText(XMLLine);
	
	ReportFile.WriteStartElement("Records");
	ReportFile.WriteText(CaseDiscrepancies.Records);
	ReportFile.WriteEndElement(); // Records
	
	ReportFile.WriteEndElement(); // Register name
	
	NumberOfDiscrepanciesInTestPlan = NumberOfDiscrepanciesInTestPlan + CaseDiscrepancies.Count;
	
EndProcedure

Procedure WriteFileAndSaveData(TestPlanLine, ReportFile)
	
	If TestPlanLine.NumberOfDiscrepancies > 0 Then
		WriteReportFile(ReportFile);
		TestData_ = New BinaryData(TestPlanLine.PathToFile);
		PutToTempStorage(TestData_, TestPlanLine.StorageAddressOfDiscrepancy);
		DeleteFiles(TestPlanLine.PathToFile);
	EndIf;
	
EndProcedure

#EndRegion

Function RunTime(BeginTime, EndTime)
	
	TimeInSeconds = (EndTime - BeginTime) / 1000;
	
	Hours1 = Int(TimeInSeconds/3600);
	Minutes1 = Int((TimeInSeconds - Hours1 * 3600) / 60);
	Seconds = TimeInSeconds - Hours1 * 3600 - Minutes1 * 60;
	
	DurationHours = ?(Hours1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giờ';
																									|ru = '%1 час';
																									|en = '%1 h'; fa = '%1 h';
																									|it = '%1 ora';
																									|pl = '%1 godzina';
																									|tr = '%1 saat'"), Hours1));
	DurationMinutes = ?(Minutes1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 phút';
																										|ru = '%1 мин';
																										|en = '%1 min'; fa = '%1 min';
																										|it = '%1 minuto';
																										|pl = '%1 min';
																										|tr = '%1 dk'"), Minutes1));
	DurationSeconds = ?(Seconds = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giây';
																										|ru = '%1 сек';
																										|en = '%1 sec'; fa = '%1 sec';
																										|it = '%1 sec-';
																										|pl = '%1 sek';
																										|tr = '%1 sn'"), Seconds));
	UpdateDuration = DurationHours + " " + DurationMinutes + " " + DurationSeconds;
	
	Return UpdateDuration;
	
EndFunction

#EndRegion

#EndIf
