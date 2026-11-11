
#Region Public

#Region ProceduresAndFunctionsOfFormationOfDelayedRegisteredRecords

// The method is called from the routine task "forming movements based on calculation with partners".
Procedure DeferredSettlementWithPartners() Export
	
	ScheduledJob = Metadata.ScheduledJobs.PostingToPartnersARAPAccounting;
	
	Common.OnStartExecuteScheduledJob(ScheduledJob);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
		
	CalculationEnd = EndOfMonth(CurrentSessionDate())+1;
	CalculationAnalysts = CalculationAnalysts();
	CalculateEverything(CalculationEnd, CalculationAnalysts);
	
EndProcedure

// Returns the default field names for use in reports.
// Returns:
//  Structure:
//   * Organization - String - "Organization".
//   * Partner     - String - "Partner".
//   * Counterparty  - String - "Counterparty".
//   * Period      - String - "Period".
//
Function DefaultSelectionFields() Export
	
	FilterFields = New Structure();
	FilterFields.Insert("Organization", "Organization");
	FilterFields.Insert("Partner", "Partner");
	FilterFields.Insert("Counterparty", "Counterparty");
	FilterFields.Insert("Contract", "Contract");
	FilterFields.Insert("Period", "Period");
	
	Return FilterFields;
EndFunction

// The method is called from reports. Restores the specified calculations only for the specified selections in the report.
// Parameters:
//		SettingsComposer - DataCompositionSettingsComposer -  Report Settings builder.
//		FilterFields - Structure - It contains required fields for Analytics and specifies
//								 how these fields are called in the report.
//		AuxProperties - Structure - Contains additional properties of the report. When starting the calculation 
//								  in the additional properties, the "borders of mutual Settlements" attribute is set.
//								  Checked by other mechanisms, shows that the calculation is not relevant.
//		CalculationForRecovery - String - Name of the calculation to be restored. If the parameter is not filled in, 
//										all calculations are performed.
Procedure RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties, CalculationForRecovery = Undefined) Export
	
	CalculationEnd = TMReportFunctionsClientServer.CalculationBoundary(SettingsComposer, FilterFields.Period);
	
	FieldValues = New Structure;
	ComparisonOperation = New Array();
	ComparisonOperation.Add(DataCompositionComparisonType.Equal);
	ComparisonOperation.Add(DataCompositionComparisonType.InList);
	
	For Each Field In FilterFields Do
		Value = TMReportFunctionsClientServer.GetSelectionValue(SettingsComposer, Field.Key, ComparisonOperation);
		FieldValues.Insert(Field.Key, Value);
	EndDo;

	ArrayOfKeysForSelectionPartners = ArrayOfKeysForSelectionPartners(FieldValues);
	CalculationAnalysts = CalculationAnalysts();
	CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfKeysForSelectionPartners;
	If Constants.UpdateARAPAccountingWhileGeneratingReports.Get() Then
		DistributeCalculationsByBackgroundJob(CalculationEnd, CalculationAnalysts, CalculationForRecovery);
	EndIf;
	
	CalculationStart = StartOfCalculations(CalculationEnd, CalculationAnalysts, CalculationForRecovery);
	AuxProperties.Insert("BorderOfMutualSettlements", CalculationStart);
	If ValueIsFilled(CalculationStart) Then
		CalculationName = ?(ValueIsFilled(CalculationForRecovery), CalculationForRecovery, "ARAPAccounting");
		AuxProperties.Insert("JobNumber", 0);
		AuxProperties.Insert("ReadyForCalculation", CalculationAnalysts);
		AuxProperties.Insert("CalculationName", CalculationName);
	EndIf;
EndProcedure

// Returns the minimum date on which the calculation (s) is inactive.
// Parameters:
//		CalculationEnd - Date - Upper bound of the analysis of the relevance of calculations. 
//		ReadyForCalculation - Structure - Contains analytics for partners or organizations that need to be calculated:
//			* AccountingAnalyticsForPartners - Array - Contains an array of partner Analytics keys.
//			* Companies - Array - Contains an array of organizations.
//		CalculationForRecovery - String - Name of the calculation to analyze. If this parameter is omitted,
//										 all calculations are analyzed.
//		JobNumber - Number - If filled in, calculations are analyzed only for this number.
// Returns:
//  Date - The minimum date on which the calculation is irrelevant.
Function StartOfCalculations(CalculationEnd, ReadyForCalculation = Undefined, CalculationForRecovery = Undefined, JobNumber = Undefined) Export
	
	If ReadyForCalculation = Undefined Then
		ReadyForCalculation = CalculationAnalysts();
	EndIf;
	
	If CalculationForRecovery = "CustomersARAPAccounting" Then
		JobNumber = ?(ValueIsFilled(JobNumber), JobNumber, Constants.NumberOfJobForAllocatingCustomersARAP.Get());
		BoundaryOfSettlementsWithCustomers = CalculationStart("JobsForAllocatingCustomersARAP", CalculationEnd, ReadyForCalculation, JobNumber);
		BorderSettlementsWithSuppliers = Date("39991212");
	ElsIf CalculationForRecovery = "VendorsARAPAccounting" Then
		JobNumber = ?(ValueIsFilled(JobNumber), JobNumber, Constants.NumberOfJobForAllocatingVendorsARAPAccounting.Get());
		BorderSettlementsWithSuppliers = CalculationStart("JobsForAllocatingVendorsARAP", CalculationEnd, ReadyForCalculation, JobNumber);
		BoundaryOfSettlementsWithCustomers = Date("39991212");
	Else
		JobNumber = Constants.NumberOfJobForAllocatingCustomersARAP.Get();
		BoundaryOfSettlementsWithCustomers = CalculationStart("JobsForAllocatingCustomersARAP", CalculationEnd, ReadyForCalculation, JobNumber);
		JobNumber = Constants.NumberOfJobForAllocatingVendorsARAPAccounting.Get();
		BorderSettlementsWithSuppliers = CalculationStart("JobsForAllocatingVendorsARAP", CalculationEnd, ReadyForCalculation, JobNumber);
	EndIf;
	
	If Min(BoundaryOfSettlementsWithCustomers, BorderSettlementsWithSuppliers) < CalculationEnd Then
		CalculationBoundary_ = Min(BoundaryOfSettlementsWithCustomers, BorderSettlementsWithSuppliers);
	Else
		CalculationBoundary_ = Undefined;
	EndIf;
	Return CalculationBoundary_;
EndFunction

// Performs full settlements with customers and suppliers on the specified date.
// Parameters:
//		EndOfSettlementPeriod_ - Date - The boundary that the calculation is performed on.
// 		CalculationAnalysts - Structure - The list of analysts for which you want to perform the calculation. See the Account Analyst method.
Procedure CalculateEverything(EndOfSettlementPeriod_, CalculationAnalysts = Undefined) Export
	
	SetPrivilegedMode(True);
	
	DistributeAllSettlementsWithCustomers(EndOfSettlementPeriod_, CalculationAnalysts);
	DistributeAllSettlementsWithSuppliers(EndOfSettlementPeriod_, CalculationAnalysts);
	
EndProcedure

// Performs a full settlement with clients on the specified date.
// Parameters:
//		EndOfSettlementPeriod_ - Date - The boundary that the calculation is performed on.
//		CalculationAnalysts - Structure - Contains analytics for partners or organizations that need to be calculated:
//			* AccountingAnalyticsForPartners - Array - Contains an array of partner Analytics keys.
//			* Companies - Array - Contains an array of organizations.
//		CheckBeginningOfTransitionToNewSettlementArchitecture - Boolean - A sign that the transition to a new settlement architecture has already begun.
//
Procedure DistributeAllSettlementsWithCustomers(EndOfSettlementPeriod_, CalculationAnalysts = Undefined, CheckBeginningOfTransitionToNewSettlementArchitecture = True) Export
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return;
	EndIf;
	
	If CheckBeginningOfTransitionToNewSettlementArchitecture
		And Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		Raise NStr("ru = 'Начат переход на новую архитектуру взаиморасчетов. 
						|Распределение расчетов с клиентами не может быть выполнено до окончания перехода.';
						|vi = 'Migration to online AR/AP accounting has started.
						|Allocation of customer AR/AP cannot be performed before the end of migration.';
						|en = 'Migration to online AR/AP accounting has started.
						|Allocation of customer AR/AP cannot be performed before the end of migration.'; fa = 'Migration to online AR/AP accounting has started.
						|Allocation of customer AR/AP cannot be performed before the end of migration.';
						|it = 'Migration to online AR/AP accounting has started.
						|Allocation of customer AR/AP cannot be performed before the end of migration.';
						|pl = 'Migration to online AR/AP accounting has started.
						|Allocation of customer AR/AP cannot be performed before the end of migration.';
						|tr = 'Yeni alacak/borç mimarisine geçiş başlatıldı. 
						|  Müşterilerle hesaplaşmaların dağıtımı, geçiş tamamlanana kadar gerçekleştirilemez.'");
	EndIf;
	
	SetPrivilegedMode(True);
	LevelInformation = EventLogLevel.Information;
	PeriodFormat = "DF='yyyy.MM.dd HH:mm:ss'";
	LanguageCode = Metadata.DefaultLanguage.LanguageCode;
	
	Comment = NStr("vi = 'Phân bổ các khoản thanh toán với khách hàng theo %PeriodEnding%';
					|ru = 'Выполняется распределение расчетов с клиентами по %PeriodEnding%';
					|en = 'Allocating customer AR/AP till %PeriodEnding%'; fa = 'Allocating customer AR/AP till %PeriodEnding%';
					|it = 'Ripartizione di regolamenti con i clienti secondo %PeriodEnding% è in corso';
					|pl = 'Odbywa się przydział rozliczeń z klientami za %PeriodEnding%';
					|tr = 'Müşterilerle yapılan anlaşmaların %PeriodEnding% itibarıyla dağılımı'", LanguageCode);
	Comment = StrReplace(Comment, "%PeriodEnding%", Format(EndOfSettlementPeriod_, PeriodFormat));
	WriteLogEvent(
		NStr("vi = 'Hạch toán công nợ. Bắt đầu phân bổ hạch toán';
			|ru = 'Взаиморасчеты. Начало распределение расчетов';
			|en = 'AR/AP accounting. Start payment allocation'; fa = 'AR/AP accounting. Start payment allocation';
			|it = 'Conti reciproci. Avvio distribuzione dei conti';
			|pl = 'Wzajemne rozliczenia. Początek przydziału rozliczeń';
			|tr = 'Yerleşmeler. Dağıtım hesaplamalarını başlat'", LanguageCode), LevelInformation, , EndOfSettlementPeriod_, Comment);
		
	UsedMetadata = New Structure("TaskRegisterName, JobConstantName, NameOfOperationalRegister");
	UsedMetadata.TaskRegisterName = "JobsForAllocatingCustomersARAP";
	UsedMetadata.JobConstantName = "NumberOfJobForAllocatingCustomersARAP";
	UsedMetadata.NameOfOperationalRegister = "CustomersARAPAccounting";
	
	KeyOperation = "ARAPAllocationServerCall.DistributionOfSettlementsWithCustomers";
	
	If CalculationAnalysts = Undefined Then
		CalculationAnalysts = CalculationAnalysts();
	EndIf;
	
	FirstPeriod = CalculationStart(UsedMetadata.TaskRegisterName, EndOfSettlementPeriod_, CalculationAnalysts);
	BeginOfPeriod = BegOfMonth(FirstPeriod);
	
	If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		If BeginOfPeriod < EndOfSettlementPeriod_ Then
			CheckBanDate(FirstPeriod);
		EndIf;
	EndIf;
	
	FirstPass = True;
	While BeginOfPeriod < EndOfSettlementPeriod_ Do
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
		NumberOfDuplicateData = 0;
		
		If FirstPass Then
			TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber(UsedMetadata.JobConstantName);
			FirstPass = False;
		EndIf;
		
		PeriodEnding = EndOfMonth(BeginOfPeriod);
		If Not Common.FileInfobase() Then
			BeginTransaction();
			Try
				BlockTaskRegister(UsedMetadata.TaskRegisterName, TaskNumberBeforeCalculation, CalculationAnalysts);
				DataForSettlementWithClientsForMonth = DataForSettlementWithClientsForMonth(BeginOfPeriod, PeriodEnding, CalculationAnalysts, UsedMetadata, TaskNumberBeforeCalculation);
				CommitTransaction();
			Except
				RollbackTransaction();
				WriteLogEvent(
					NStr("vi = 'Không thể khóa đăng ký công việc';
						|ru = 'Не удалось заблокировать регистр заданий';
						|en = 'Cannot lock the job register'; fa = 'Cannot lock the job register';
						|it = 'Non è stato possibile bloccare il registro di task';
						|pl = 'Nie udało się zablokować rejestr zadań';
						|tr = 'Görev kaydı kilitlenemedi'", LanguageCode), EventLogLevel.Error);
				Raise;
			EndTry;
		Else
			DataForSettlementWithClientsForMonth = DataForSettlementWithClientsForMonth(BeginOfPeriod, PeriodEnding, CalculationAnalysts, UsedMetadata, TaskNumberBeforeCalculation);
		EndIf;
		CompaniesList = DataForSettlementWithClientsForMonth.Companies;
		
		// Stage 1X: distribution of payments to clients
		CalculateSettlementsWithCustomers(BeginOfPeriod, PeriodEnding, DataForSettlementWithClientsForMonth, NumberOfDuplicateData);
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "CalculateSettlementsWithCustomers");
		NumberOfDuplicateData = 0;
		
		// Stage 2X: Revaluation of calculations at the end of the period
		Documents.ExchangeDifferenceCalculation.ReassessCustomerSettlements(CompaniesList, EndOfMonth(BeginOfPeriod), DataForSettlementWithClientsForMonth.AccountingAnalyticsForPartners, NumberOfDuplicateData);
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "ReassessCustomerSettlements");
		NumberOfDuplicateData = 0;
		LocalAccntingServer.UpdateTasksByEndOfMonthWhenPerformingLocalOperation(FirstPeriod, CompaniesList, False, NumberOfDuplicateData);
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "UpdateTasksByEndOfMonthWhenPerformingLocalOperation");
		NumberOfDuplicateData = 0;
		// Stage 3X: Setting new calculation boundaries
		If Not Common.FileInfobase() Then
			BeginTransaction();
			Try
				BlockTaskRegister(UsedMetadata.TaskRegisterName, TaskNumberBeforeCalculation, CalculationAnalysts);
				SetCalculationBoundaries(BeginOfPeriod, PeriodEnding, UsedMetadata.TaskRegisterName, CalculationAnalysts, DataForSettlementWithClientsForMonth.TemporaryTable, TaskNumberBeforeCalculation, NumberOfDuplicateData);
				CommitTransaction();
			Except
				RollbackTransaction();
				WriteLogEvent(
					NStr("vi = 'Không thể đặt ranh giới tính toán';
						|ru = 'Не удалось установить границы расчетов';
						|en = 'Cannot set calculation limits'; fa = 'Cannot set calculation limits';
						|it = 'Non è stato possibile impostare i limiti dei regolamenti';
						|pl = 'Nie udało się ustalić granicy rozliczeń';
						|tr = 'Hesaplama sınırları ayarlanamadı'", LanguageCode), EventLogLevel.Error);
				Raise;
			EndTry
		Else
			SetCalculationBoundaries(BeginOfPeriod, PeriodEnding, UsedMetadata.TaskRegisterName, CalculationAnalysts, DataForSettlementWithClientsForMonth.TemporaryTable, TaskNumberBeforeCalculation, NumberOfDuplicateData);
		EndIf;
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "SetCalculationBoundaries");
		NumberOfDuplicateData = 0;
		
		WriteLogEvent(
			NStr("vi = 'Hạch toán công nợ. Đã phân bổ hạch toán với khách hàng trong kỳ';
				|ru = 'Взаиморасчеты. Распределены расчеты с клиентами за период';
				|en = 'AR/AP accounting. Customer AR/AP are allocated for the period'; fa = 'AR/AP accounting. Customer AR/AP are allocated for the period';
				|it = 'Conti reciproci. Conti distribuiti con clienti per periodo';
				|pl = 'Wzajemne rozliczenia. Przydzielono rozliczenia z klientami za okres';
				|tr = 'Yerleşmeler. Dönem için müşterilerle dağıtılmış yerleşimler'", LanguageCode), LevelInformation, , Format(BeginOfPeriod, NStr("vi = 'ДФ=''гггг.ММ''';
																																						|ru = 'ДФ=''yyyy.MM''';
																																						|en = 'DF=''yyyy.MM'''; fa = 'DF=''yyyy.MM''';
																																						|it = 'ДФ=''гггг.ММ''';
																																						|pl = 'DF=''yyyy.MM''';
																																						|tr = 'ДФ=''гггг.ММ'''")));
		
		BeginOfPeriod = CalculationStart(UsedMetadata.TaskRegisterName, EndOfSettlementPeriod_, CalculationAnalysts, TaskNumberBeforeCalculation);
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, NumberOfDuplicateData);
		NumberOfDuplicateData = 0;
	EndDo;
	
	Comment = NStr("vi = 'Phân bổ hạch toán với khách hàng từ %BeginOfPeriod% đến %PeriodEnding%';
					|ru = 'Распределены расчеты с клиентами с %BeginOfPeriod% по %PeriodEnding%';
					|en = 'Customer AR/AP are allocated from %BeginOfPeriod% to %PeriodEnding%'; fa = 'Customer AR/AP are allocated from %BeginOfPeriod% to %PeriodEnding%';
					|it = 'Sono stati ripartiti i regolamenti con i clienti da %BeginOfPeriod% a %PeriodEnding%';
					|pl = 'Przydzielono rozliczenia z klientami od %BeginOfPeriod% do %PeriodEnding%';
					|tr = '%BeginOfPeriod% ile %PeriodEnding% arasında müşterilerle dağıtılmış yerleşimler'", LanguageCode);
	Comment = StrReplace(Comment, "%BeginOfPeriod%", Format(FirstPeriod, PeriodFormat));
	Comment = StrReplace(Comment, "%PeriodEnding%", Format(EndOfSettlementPeriod_, PeriodFormat));
	WriteLogEvent(
		NStr("vi = 'Hạch toán công nợ. Kết thúc phân bổ hạch toán';
			|ru = 'Взаиморасчеты. Окончание распределения расчетов';
			|en = 'AR/AP accounting. End payment allocation'; fa = 'AR/AP accounting. End payment allocation';
			|it = 'Conti reciproci. Fine distribuzione dei conti';
			|pl = 'Wzajemne rozliczenia. Koniec przydziału rozliczeń';
			|tr = 'Mutabakatlar. Mutabakat sonu dağılımı'", LanguageCode), LevelInformation, , EndOfSettlementPeriod_, Comment);
EndProcedure

// Performs a full payment with suppliers on the specified date.
// Parameters:
//		EndOfSettlementPeriod_ - Date - The boundary that the calculation is performed on.
//		CalculationAnalysts - Structure - Contains analytics for partners or organizations that need to be calculated:
//			* AccountingAnalyticsForPartners - Array - Contains an array of partner Analytics keys.
//			* Companies - Array - Contains an array of organizations.
//		CheckBeginningOfTransitionToNewSettlementArchitecture - Boolean - A sign that the transition to a new settlement architecture has already begun.
//
Procedure DistributeAllSettlementsWithSuppliers(EndOfSettlementPeriod_, CalculationAnalysts = Undefined, CheckBeginningOfTransitionToNewSettlementArchitecture = True) Export
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		Return;
	EndIf;
	
	If CheckBeginningOfTransitionToNewSettlementArchitecture 
		And Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		Raise NStr("ru = 'Начат переход на новую архитектуру взаиморасчетов. 
						|Распределение расчетов с поставщиками не может быть выполнено до окончания перехода.';
						|vi = 'Migration to new online AR/AP accounting has started.
						|Allocation of vendor AR/AP cannot be performed before the end of migration.';
						|en = 'Migration to new online AR/AP accounting has started.
						|Allocation of vendor AR/AP cannot be performed before the end of migration.'; fa = 'Migration to new online AR/AP accounting has started.
						|Allocation of vendor AR/AP cannot be performed before the end of migration.';
						|it = 'Migration to new online AR/AP accounting has started.
						|Allocation of vendor AR/AP cannot be performed before the end of migration.';
						|pl = 'Migration to new online AR/AP accounting has started.
						|Allocation of vendor AR/AP cannot be performed before the end of migration.';
						|tr = 'Yeni alacak/borç mimarisine geçiş başlatıldı. 
						|  Tedarikçilerle hesaplaşmaların dağıtımı, geçiş tamamlanana kadar gerçekleştirilemez.'");
	EndIf;
	
	SetPrivilegedMode(True);
	LevelInformation = EventLogLevel.Information;
	PeriodFormat = "DF='yyyy.MM.dd HH:mm:ss'";
	LanguageCode = Metadata.DefaultLanguage.LanguageCode;
	
	Comment = NStr("vi = 'Phân bổ các khoản thanh toán với các nhà cung cấp theo %PeriodEnding%';
					|ru = 'Выполняется распределение расчетов с поставщиками по %PeriodEnding%';
					|en = 'Allocating vendor AR/AP till %PeriodEnding%'; fa = 'Allocating vendor AR/AP till %PeriodEnding%';
					|it = 'Ripartizione di regolamenti con i fornitori secondo %PeriodEnding% è in corso';
					|pl = 'Odbywa się przydział rozliczeń z dostawcami do %PeriodEnding%';
					|tr = 'Tedarikçilerle yerleşimlerin %PeriodEnding%''a göre dağılımı'", LanguageCode);
	Comment = StrReplace(Comment, "%PeriodEnding%", Format(EndOfSettlementPeriod_, PeriodFormat));
	WriteLogEvent(
		NStr("vi = 'Hạch toán công nợ. Bắt đầu phân bổ hạch toán';
			|ru = 'Взаиморасчеты. Начало распределение расчетов';
			|en = 'AR/AP accounting. Start payment allocation'; fa = 'AR/AP accounting. Start payment allocation';
			|it = 'Conti reciproci. Inizio distribuzione dei conti';
			|pl = 'Wzajemne rozliczenia. Początek przydziału rozliczeń';
			|tr = 'Yerleşmeler. Dağıtım hesaplamalarını başlat'", LanguageCode), LevelInformation, , EndOfSettlementPeriod_, Comment);
		
	UsedMetadata = New Structure("TaskRegisterName, JobConstantName, NameOfOperationalRegister");
	UsedMetadata.TaskRegisterName = "JobsForAllocatingVendorsARAP";
	UsedMetadata.JobConstantName = "NumberOfJobForAllocatingVendorsARAPAccounting";
	UsedMetadata.NameOfOperationalRegister = "VendorsARAPAccounting";
	
	KeyOperation = "ARAPAllocationServerCall.DistributionOfSettlementsWithSuppliers";
	
	If CalculationAnalysts = Undefined Then
		CalculationAnalysts = CalculationAnalysts();
	EndIf;
	
	FirstPeriod = CalculationStart(UsedMetadata.TaskRegisterName, EndOfSettlementPeriod_, CalculationAnalysts);
	BeginOfPeriod = BegOfMonth(FirstPeriod);
	
	If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		If BeginOfPeriod < EndOfSettlementPeriod_ Then
			CheckBanDate(FirstPeriod);
		EndIf;
	EndIf;
	
	FirstPass = True;
	While BeginOfPeriod < EndOfSettlementPeriod_ Do
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
		NumberOfDuplicateData = 0;
		If FirstPass Then
			TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber(UsedMetadata.JobConstantName);
			FirstPass = False;
		EndIf;
		
		PeriodEnding = EndOfMonth(BeginOfPeriod);
		If Not Common.FileInfobase() Then
			BeginTransaction();
			Try
				BlockTaskRegister(UsedMetadata.TaskRegisterName, TaskNumberBeforeCalculation, CalculationAnalysts);
				DataForSettlementWithSuppliersForMonth = DataForSettlementWithSuppliersForMonth(BeginOfPeriod, PeriodEnding, CalculationAnalysts, UsedMetadata, TaskNumberBeforeCalculation);
				CommitTransaction();
			Except
				RollbackTransaction();
				WriteLogEvent(
					NStr("vi = 'Không thể khóa đăng ký công việc';
						|ru = 'Не удалось заблокировать регистр заданий';
						|en = 'Cannot lock the job register'; fa = 'Cannot lock the job register';
						|it = 'Non è stato possibile bloccare il registro di task';
						|pl = 'Nie udało się zablokować rejestr zadań';
						|tr = 'Görev kaydı kilitlenemedi'", LanguageCode), EventLogLevel.Error);
				Raise;
			EndTry
		Else
			DataForSettlementWithSuppliersForMonth = DataForSettlementWithSuppliersForMonth(BeginOfPeriod, PeriodEnding, CalculationAnalysts, UsedMetadata, TaskNumberBeforeCalculation);
		EndIf;
		CompaniesList = DataForSettlementWithSuppliersForMonth.Companies;
		
		// Stage 1X: distribution of payments to clients
		CalculateSettlementsWithSuppliers(BeginOfPeriod, PeriodEnding, DataForSettlementWithSuppliersForMonth, NumberOfDuplicateData);
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "CalculateSettlementsWithSuppliers");
		NumberOfDuplicateData = 0;
		
		// Stage 2X: Revaluation of calculations at the end of the period
		Documents.ExchangeDifferenceCalculation.ReassessSettlementsWithSuppliers(CompaniesList, EndOfMonth(BeginOfPeriod), DataForSettlementWithSuppliersForMonth.AccountingAnalyticsForPartners, NumberOfDuplicateData);
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "ReassessSettlementsWithSuppliers");
		NumberOfDuplicateData = 0;
		LocalAccntingServer.UpdateTasksByEndOfMonthWhenPerformingLocalOperation(FirstPeriod, CompaniesList,, NumberOfDuplicateData);
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "UpdateTasksByEndOfMonthWhenPerformingLocalOperation");
		NumberOfDuplicateData = 0;
		// Stage 3X: Setting new calculation boundaries
		If Not Common.FileInfobase() Then
			BeginTransaction();
			Try
				BlockTaskRegister(UsedMetadata.TaskRegisterName, TaskNumberBeforeCalculation, CalculationAnalysts);
				SetCalculationBoundaries(BeginOfPeriod, PeriodEnding, UsedMetadata.TaskRegisterName, CalculationAnalysts, DataForSettlementWithSuppliersForMonth.TemporaryTable, TaskNumberBeforeCalculation, NumberOfDuplicateData);
				CommitTransaction();
			Except
				RollbackTransaction();
				WriteLogEvent(
					NStr("vi = 'Không thể đặt ranh giới tính toán';
						|ru = 'Не удалось установить границы расчетов';
						|en = 'Cannot set calculation limits'; fa = 'Cannot set calculation limits';
						|it = 'Non è stato possibile impostare i limiti dei regolamenti';
						|pl = 'Nie udało się ustalić granicy rozliczeń';
						|tr = 'Hesaplama sınırları ayarlanamadı'", LanguageCode), EventLogLevel.Error);
				Raise;
			EndTry
		Else
			SetCalculationBoundaries(BeginOfPeriod, PeriodEnding, UsedMetadata.TaskRegisterName, CalculationAnalysts, DataForSettlementWithSuppliersForMonth.TemporaryTable, TaskNumberBeforeCalculation, NumberOfDuplicateData);
		EndIf;
		PerformanceMonitor.FixTimeConsumingOperationMeasure(MeasurementDetails, NumberOfDuplicateData, "SetCalculationBoundaries");
		NumberOfDuplicateData = 0;
		
		WriteLogEvent(
			NStr("vi = 'Hạch toán công nợ. Đã phân bổ hạch toán với nhà cung cấp trong kỳ';
				|ru = 'Взаиморасчеты. Распределены расчеты с поставщиками за период';
				|en = 'AR/AP accounting. Vendor AR/AP are allocated for the period'; fa = 'AR/AP accounting. Vendor AR/AP are allocated for the period';
				|it = 'Conti reciproci. Conti distribuiti con fornitori per periodo';
				|pl = 'Wzajemne rozliczenia. Przydzielono rozliczenia z dostawcami za okres';
				|tr = 'Yerleşmeler. Dönem için tedarikçilerle dağıtılmış yerleşimler'", LanguageCode), LevelInformation, , Format(BeginOfPeriod, NStr("vi = 'ДФ=''гггг.ММ''';
																																					|ru = 'ДФ=''yyyy.MM''';
																																					|en = 'DF=''yyyy.MM'''; fa = 'DF=''yyyy.MM''';
																																					|it = 'ДФ=''гггг.ММ''';
																																					|pl = 'DF=''yyyy.MM''';
																																					|tr = 'ДФ=''гггг.ММ'''")));
		
		BeginOfPeriod = CalculationStart(UsedMetadata.TaskRegisterName, EndOfSettlementPeriod_, CalculationAnalysts, TaskNumberBeforeCalculation);
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, NumberOfDuplicateData);
		NumberOfDuplicateData = 0;
	EndDo;
	
	Comment = NStr("vi = 'Phân bổ hạch toán với khách hàng từ %BeginOfPeriod% đến %PeriodEnding%';
					|ru = 'Распределены расчеты с клиентами с %BeginOfPeriod% по %PeriodEnding%';
					|en = 'Customer AR/AP are allocated from %BeginOfPeriod% to %PeriodEnding%'; fa = 'Customer AR/AP are allocated from %BeginOfPeriod% to %PeriodEnding%';
					|it = 'Sono stati ripartiti i regolamenti con i clienti da %BeginOfPeriod% a %PeriodEnding%';
					|pl = 'Przydzielono rozliczenia z klientami od %BeginOfPeriod% do %PeriodEnding%';
					|tr = '%BeginOfPeriod% ile %PeriodEnding% arasında müşterilerle dağıtılmış yerleşimler'", LanguageCode);
	Comment = StrReplace(Comment, "%BeginOfPeriod%", Format(FirstPeriod, PeriodFormat));
	Comment = StrReplace(Comment, "%PeriodEnding%", Format(EndOfSettlementPeriod_, PeriodFormat));
	WriteLogEvent(
		NStr("vi = 'Hạch toán công nợ. Kết thúc phân bổ hạch toán';
			|ru = 'Взаиморасчеты. Окончание распределения расчетов';
			|en = 'AR/AP accounting. End payment allocation'; fa = 'AR/AP accounting. End payment allocation';
			|it = 'Conti reciproci. Fine distribuzione dei conti';
			|pl = 'Wzajemne rozliczenia. Koniec przydziału rozliczeń';
			|tr = 'Mutabakatlar. Mutabakat sonu dağılımı'", LanguageCode), LevelInformation, , EndOfSettlementPeriod_, Comment);
EndProcedure

// Performs the updating of the calculations in a background job.
// Parameters:
//		CalculationEnd - Date - The end date is updated.
//		CalculationAnalysts - Structure - Contains analytics for partners or organizations that need to be calculated:
//			* AccountingAnalyticsForPartners - Array - Contains an array of partner Analytics keys.
//			* Companies - Array - Contains an array of organizations.
//		CalculationForRecovery - String - Name of the calculation to update. If it is not filled in, all calculations are updated.
//		Var_Key - String - the key of the background task.
Procedure DistributeCalculationsByBackgroundJob(CalculationEnd = Undefined, CalculationAnalysts = Undefined, CalculationForRecovery = Undefined, Var_Key = "") Export
	
	If Not ValueIsFilled(CalculationEnd) Then
		CalculationEnd = CurrentSessionDate();
	EndIf;
	
	If CalculationForRecovery = "CustomersARAPAccounting" Then
		DistributeSettlementsWithCustomersByBackgroundJob(CalculationEnd, CalculationAnalysts, CalculationForRecovery, Var_Key);
	ElsIf CalculationForRecovery = "VendorsARAPAccounting" Then
		DistributeCalculationsWithSuppliersBackgroundJob(CalculationEnd, CalculationAnalysts, CalculationForRecovery, Var_Key);
	Else
		DistributeSettlementsWithCustomersByBackgroundJob(CalculationEnd, CalculationAnalysts, CalculationForRecovery, ?(Var_Key = "", NameOfCustomerSettlementBackgroundJob(), Var_Key));
		DistributeCalculationsWithSuppliersBackgroundJob(CalculationEnd, CalculationAnalysts, CalculationForRecovery, ?(Var_Key = "", NameOfBackgroundTaskForSettlementsWithSuppliers(), Var_Key));
	EndIf;
EndProcedure

// Displays an information label about a running background task in the layout.
Procedure DeduceRelevanceOfCalculations(Template, CalculationParameters) Export
	If ValueIsFilled(CalculationParameters) And CalculationParameters.Property("BorderOfMutualSettlements") Then
		If ValueIsFilled(CalculationParameters.BorderOfMutualSettlements) Then
			WarningTable_ = New SpreadsheetDocument;
			AreaWarning = WarningTable_.Area(1,1,1,1);
			WarningText = NStr("vi = 'Đã phân bổ hạch toán đến %UpdateDate%. 
										|Đã khởi động nhiệm vụ phân bổ hạch toán từ %DistributionStartDate% (cần phân bổ hạch toán đối với %DocumentsCount%). 
										|Sau khi phân bổ, chương trình sẽ đề xuất lập lại báo cáo.';
										|ru = 'Распределение расчетов выполнено до %UpdateDate%. 
										|Запущено задание по распределению расчетов с %DistributionStartDate% (требуется распределить расчеты для %DocumentsCount%). 
										|После распределения Вам будет предложено переформировать отчет.';
										|en = 'Settlements are allocated up to %UpdateDate%.
										|Settlements allocation job runs from %DistributionStartDate% (settlements should be allocated for %DocumentsCount%). 
										|After that, you will be prompted to rebuild the report.'; fa = 'Settlements are allocated up to %UpdateDate%.
										|Settlements allocation job runs from %DistributionStartDate% (settlements should be allocated for %DocumentsCount%). 
										|After that, you will be prompted to rebuild the report.';
										|it = 'La distribuzione dei pagamenti è stata effettuata fino al %UpdateDate%
										|È stato avviato il task di distribuzione dei pagamenti dal %DistributionStartDate% (è necessario allocare i pagamenti per il%DocumentsCount%). 
										|Dopo la distribuzione verrà richiesto di rigenerare il report.';
										|pl = 'Rozdysponowanie obliczeń wykonane do %UpdateDate%. 
										|Rozpoczęto zadanie od rozdysponowania obliczeń od%DistributionStartDate% (wymagane jest rozdysponować obliczenia dla %DocumentsCount%). 
										|Po rozdysponowaniu zostaniesz poproszony o ponowne przeformowanie raportu.';
										|tr = 'Hesaplamaların dağıtımı %UpdateDate%''den önce gerçekleştirilmiştir. 
										| Hesaplamaların dağıtımı görevi %DistributionStartDate% tarihinden itibaren başlatılmıştır (%DocumentsCount% için hesaplamaların dağıtılması gerekmektedir). 
										|Dağıtımdan sonra raporu yeniden biçimlendirmeniz istenecektir.'");
			UpdateDate = EndOfMonth(CalculationParameters.BorderOfMutualSettlements - 1);
			WarningText = StrReplace(WarningText,"%UpdateDate%", Format(UpdateDate, "DLF=D"));
			WarningText = StrReplace(WarningText,"%DistributionStartDate%", Format(CalculationParameters.BorderOfMutualSettlements, "DLF=D"));
			WarningText = StrReplace(WarningText,"%DocumentsCount%", TMCommonUse.NumberOfDocumentsInWords(CalculationParameters.ToCalculation));
			AreaWarning.Text = WarningText;
			AreaWarning.TextColor = StyleColors.NegativeTextColor;
			Template.InsertArea(AreaWarning, Template.Area(1,1,1,1), SpreadsheetDocumentShiftType.Vertical);
		Else
			CalculationParameters.Delete("BorderOfMutualSettlements");
			CalculationParameters.Delete("JobNumber");
		EndIf;
	EndIf;
EndProcedure

// Returns the name of the background task for distributing settlements with clients.
// Returns:
//  String - The name of the background task.
Function NameOfCustomerSettlementBackgroundJob() Export
	Return "SettlementsWithClients";
EndFunction

// Returns the name of the background task for distributing settlements with suppliers.
// Returns:
//  String - The name of the background task.
Function NameOfBackgroundTaskForSettlementsWithSuppliers() Export
	Return "SettlementsWithSuppliers";
EndFunction

// Returns whether the calculation distribution task is active
// Returns:
//  Boolean - The background task is active.
Function ActiveBackgroundTaskForSettlements() Export
	
	Var_Key = ARAPAllocationServerCall.NameOfBackgroundTaskForSettlementsWithSuppliers();
	
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	If ActiveTasks.Count() > 0 Then
		Return True;
	EndIf;
	
	Var_Key = ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob();
	
	Filter = New Structure();
	Filter.Insert("Key", Var_Key);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	If ActiveTasks.Count() > 0 Then
		Return True;
	EndIf;
	
	Return False;
EndFunction


#EndRegion

#EndRegion

#Region Private

#Region CalculationInBackground

Procedure DistributeCalculationsWithSuppliersBackgroundJob(Period, ReadyForCalculation, CalculationForRecovery, Var_Key = "")
	
	SetPrivilegedMode(True);
	
	If Not InfobaseUpdate.ObjectProcessed("VendorsARAPAccounting").Processed Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Phân bổ các khoản thanh toán với các nhà cung cấp';
							|ru = 'Выполняется распределение расчетов с поставщиками';
							|en = 'Allocating vendor AR/AP'; fa = 'Allocating vendor AR/AP';
							|it = 'Distribuzione dei pagamenti con i fornitori in corso';
							|pl = 'Odbywa się przydział rozliczeń z dostawcami';
							|tr = 'Tedarikçilerle yapılan mutabakatların dağıtımı gerçekleştirilir'");
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(Period);
	ExportProcedureParameters.Add(ReadyForCalculation);
	
	JobParameters = New Array();
	JobParameters.Add("ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers");
	JobParameters.Add(ExportProcedureParameters);

	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
EndProcedure

Procedure DistributeSettlementsWithCustomersByBackgroundJob(Period, ReadyForCalculation, CalculationForRecovery, Var_Key = "")
	
	SetPrivilegedMode(True);
	
	If Not InfobaseUpdate.ObjectProcessed("CustomersARAPAccounting").Processed Then
		Return;
	EndIf;
	
	JobDescription = NStr("vi = 'Phân bổ các khoản thanh toán với khách hàng';
							|ru = 'Выполняется распределение расчетов с клиентами';
							|en = 'Allocating customer AR/AP'; fa = 'Allocating customer AR/AP';
							|it = 'Distribuzione dei pagamenti con i clienti in corso';
							|pl = 'Odbywa się przydział rozliczeń z klientami';
							|tr = 'Müşterilerle yapılan mutabakatların dağıtımı gerçekleştirilir'");
	
	ExportProcedureParameters = New Array();
	ExportProcedureParameters.Add(Period);
	ExportProcedureParameters.Add(ReadyForCalculation);
	
	JobParameters = New Array();
	JobParameters.Add("ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers");
	JobParameters.Add(ExportProcedureParameters);

	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters,  Var_Key, JobDescription);
	
EndProcedure

#EndRegion // CalculationInBackground

#Region LimitsOfAnalystToCalculation
Function CalculationStart(TaskRegisterName, CalculationEnd, CalculationAnalysts, JobNumber = 0)
	
	QueryText = "
	|SELECT
	|	MIN(Jobs.Month) AS StartOfSettlementPeriod
	|FROM
	|	TaskRegisterName AS Jobs
	|WHERE
	|	Jobs.Month <= &CalculationEnd
	|	AND (Jobs.AccountingDimensionByPartners IN (&AccountingAnalyticsForPartners)
	|		OR &ForAllAnalysts)
	|	AND (Jobs.Organization IN (&Companies)
	|		OR &ByAllCompanies)
	|	AND (Jobs.JobNumber <= &JobNumber
	|		OR &ForAllTaskNumbers)
	|HAVING 
	|	NOT (MIN(Jobs.Month) IS NULL)
	|";
	
	QueryText = StrReplace(QueryText,"TaskRegisterName", "InformationRegister."+TaskRegisterName);
	
	Query = New Query(QueryText);
	Query.SetParameter("CalculationEnd", CalculationEnd);
	Query.SetParameter("AccountingAnalyticsForPartners", CalculationAnalysts.AccountingAnalyticsForPartners);
	Query.SetParameter("ForAllAnalysts", Not ValueIsFilled(CalculationAnalysts.AccountingAnalyticsForPartners));
	Query.SetParameter("Companies", CalculationAnalysts.Companies);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(CalculationAnalysts.Companies));
	Query.SetParameter("JobNumber", JobNumber);
	Query.SetParameter("ForAllTaskNumbers", JobNumber = 0);

	Selection = Query.Execute().Select();
	Return ?(Selection.Next(), Selection.StartOfSettlementPeriod, EndOfMonth(CalculationEnd) + 1);
EndFunction

// Returns the structure of the calculation analyst fields
// Returns:
//	Structure:
//		* AccountingAnalyticsForPartners - Undefined - Key for partner accounting Analytics.
//		* Companies - Undefined - Organization of the calculation.
//
Function CalculationAnalysts() Export
	Return New Structure("AccountingAnalyticsForPartners, Companies", Undefined, Undefined);
EndFunction

#EndRegion // DocumentsForSettlement

#Region CalculationStages

Function DataForSettlementWithClientsForMonth(BeginOfPeriod, PeriodEnding, CalculationAnalysts, UsedMetadata, TaskNumberBeforeCalculation);
	Context = "CustomersARAPAccounting";
	TemporaryTable = New TempTablesManager;
	DataForCalculation = New Structure("DataForSettlementsWithCustomers, Recorders, BorderCache");
	
	FillInFormForCalculationForMonth(UsedMetadata.TaskRegisterName, BeginOfPeriod, PeriodEnding, TaskNumberBeforeCalculation, CalculationAnalysts, DataForCalculation);
	
	// PHASE 10: Sampling of source data for distribution of settlements with customers
	DataForCalculation.DataForSettlementsWithCustomers = DataForSettlementsWithCustomers(BeginOfPeriod, PeriodEnding, DataForCalculation.AccountingAnalyticsForPartners, TemporaryTable);
	// PHASE 12: Distribution of settlements with clients based on the initial data
	ExcludedLoggerTypes = TypesToExclude(); // these types of registrars will not be checked and will not be returned using the Registrars() method
	DataForCalculation.Recorders = Recorders(BeginOfPeriod, PeriodEnding, DataForCalculation.AccountingAnalyticsForPartners, Context, ExcludedLoggerTypes);
	Return DataForCalculation;
EndFunction

Function DataForSettlementWithSuppliersForMonth(BeginOfPeriod, PeriodEnding, CalculationAnalysts, UsedMetadata, TaskNumberBeforeCalculation);
	Context = "VendorsARAPAccounting";
	TemporaryTable = New TempTablesManager;
	DataForCalculation = New Structure("DataForSettlementsWithSuppliers, Recorders, BorderCache");
	
	FillInFormForCalculationForMonth(UsedMetadata.TaskRegisterName, BeginOfPeriod, PeriodEnding, TaskNumberBeforeCalculation, CalculationAnalysts, DataForCalculation);
	
	// PHASE 10: Sampling of source data for distribution of settlements with customers
	DataForCalculation.DataForSettlementsWithSuppliers = DataForSettlementsWithSuppliers(BeginOfPeriod, PeriodEnding, DataForCalculation.AccountingAnalyticsForPartners, TemporaryTable);
	// PHASE 12: Distribution of settlements with clients based on the initial data
	ExcludedLoggerTypes = TypesToExclude(); // these types of registrars will not be checked and will not be returned using the Registrars() method
	DataForCalculation.Recorders = Recorders(BeginOfPeriod, PeriodEnding, DataForCalculation.AccountingAnalyticsForPartners, Context, ExcludedLoggerTypes);
	Return DataForCalculation;
EndFunction

Procedure FillInFormForCalculationForMonth(TaskRegisterName, BeginOfPeriod, PeriodEnding, JobNumber, CalculationAnalysts, RawData)
	
	Query = New Query("
	|SELECT
	|	Jobs.Month,
	|	Jobs.JobNumber,
	|	Jobs.Organization,
	|	Jobs.AccountingDimensionByPartners,
	|	Jobs.ARAPObject,
	|	Jobs.Document
	|INTO BorderCache
	|FROM
	|	TaskRegister AS Jobs
	|WHERE
	|	Jobs.Month BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND Jobs.JobNumber <= &JobNumber
	|	AND (Jobs.AccountingDimensionByPartners IN (&AccountingAnalyticsForPartners) OR &ForAllAnalysts)
	|	AND (Jobs.Organization IN (&Companies) OR &ByAllCompanies)
	|;
	|////////////////////////////////////////////
	|SELECT DISTINCT
	|	BorderCache.AccountingDimensionByPartners
	|FROM
	|	BorderCache AS BorderCache
	|;
	|////////////////////////////////////////////
	|SELECT DISTINCT
	|	BorderCache.Organization
	|FROM
	|	BorderCache AS BorderCache
	|");
	
	Query.Text = StrReplace(Query.Text, "TaskRegister", "InformationRegister." + TaskRegisterName);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("JobNumber", JobNumber);
	Query.SetParameter("AccountingAnalyticsForPartners", CalculationAnalysts.AccountingAnalyticsForPartners);
	Query.SetParameter("ForAllAnalysts", CalculationAnalysts.AccountingAnalyticsForPartners = Undefined);
	Query.SetParameter("Companies", CalculationAnalysts.Companies);
	Query.SetParameter("ByAllCompanies", CalculationAnalysts.Companies = Undefined);
	Query.TempTablesManager = New TempTablesManager;
	
	Result = Query.ExecuteBatch();
	
	RawData.Insert("AccountingAnalyticsForPartners", Result[1].Unload().UnloadColumn("AccountingDimensionByPartners"));
	RawData.Insert("Companies", Result[2].Unload().UnloadColumn("Organization"));
	RawData.Insert("TemporaryTable", Query.TempTablesManager);
	
EndProcedure

Procedure BlockTaskRegister(TaskRegisterName, TaskNumberBeforeCalculation, CalculationAnalysts)
	
	Block = New DataLock;
	
	RegisterName = "InformationRegister."+TaskRegisterName;
	LockItem = Block.Add(RegisterName);
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("JobNumber", New Range(Undefined, TaskNumberBeforeCalculation));
	
	If CalculationAnalysts.AccountingAnalyticsForPartners <> Undefined 
		Or CalculationAnalysts.Companies <> Undefined Then
		
		NumberOfAnalyticsByPartner = NumberOfAnalyticsLines(CalculationAnalysts.AccountingAnalyticsForPartners);
		NumberOfOrganizations = NumberOfAnalyticsLines(CalculationAnalysts.Companies);
		
		RowsCount = Max(NumberOfOrganizations, NumberOfAnalyticsByPartner);
		
		LockSource = New ValueTable;
		Counter = 0;
		While Counter < RowsCount Do
			LockSource.Add();
			Counter = Counter + 1;
		EndDo;
		
		LockItem.DataSource = LockSource;
		If CalculationAnalysts.AccountingAnalyticsForPartners <> Undefined Then
			LockSource.Columns.Add("AccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
			LockSource.LoadColumn(CalculationAnalysts.AccountingAnalyticsForPartners, "AccountingDimensionByPartners");
			LockItem.UseFromDataSource("AccountingDimensionByPartners", "AccountingDimensionByPartners");
		EndIf;
		If CalculationAnalysts.Companies <> Undefined Then
			LockSource.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
			If TypeOf(CalculationAnalysts.Companies) = Type("ValueList") Then
				LockSource.LoadColumn(CalculationAnalysts.Companies.UnloadValues(), "Organization");
			Else
				LockSource.LoadColumn(CalculationAnalysts.Companies, "Organization");
			EndIf;
			LockItem.UseFromDataSource("Organization", "Organization");
		EndIf;
	EndIf;
	
	Block.Lock();
EndProcedure

Function NumberOfAnalyticsLines(DimensionCalculation)
	
	If DimensionCalculation = Undefined Then
		 NumberOfAnalyticsLines = 0;
	ElsIf TypeOf(DimensionCalculation) = Type("CatalogRef.Companies")
		Or TypeOf(DimensionCalculation) = Type("CatalogRef.DimensionKeysOfAccountingByPartners") Then
		NumberOfAnalyticsLines = 1;
	Else
		NumberOfAnalyticsLines = DimensionCalculation.Count();
	EndIf;
	
	Return NumberOfAnalyticsLines;
EndFunction

// Stage 1X: distribution of payments to clients
Procedure CalculateSettlementsWithCustomers(BeginOfPeriod, PeriodEnding, RawData, RecordsCount = 0)
	Context = "CustomersARAPAccounting";
	SettlementSettlementsWithCustomers = SettlementSettlementsWithCustomers(RawData.DataForSettlementsWithCustomers, RawData.Recorders, Undefined, False, RecordsCount);
	// PHASE 14: Register entry calculationreferences
	RecordCalculatedBatches(AccumulationRegisters.CustomersARAPAccountingByDocuments, SettlementSettlementsWithCustomers, RawData.Recorders);
	ClearRegisterOnServer(RawData.Recorders, "CustomersARAPAccountingByDocuments");
	If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(SettlementSettlementsWithCustomers);
	EndIf;
	LoggersToReflection = SettlementSettlementsWithCustomers.UnloadColumn("Recorder");
	// Updating the amounts in the data register and the balance management registers
	If LoggersToReflection.Count() > 0 Then
		InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateDocumentAmountsInAccountingCurrencies(LoggersToReflection);
	EndIf;
	// Updating the upr. balance
	GenerateRegisteredRecordsOnManagementAccounting(Context, SettlementSettlementsWithCustomers);
EndProcedure

// Stage 2X: distribution of payments to suppliers
Procedure CalculateSettlementsWithSuppliers(BeginOfPeriod, PeriodEnding, RawData, RecordsCount = 0)
	Context = "VendorsARAPAccounting";
	SettlementSettlementsWithSuppliers = SettlementSettlementsWithSuppliers(RawData.DataForSettlementsWithSuppliers, RawData.Recorders, Undefined, False, RecordsCount);
	// PHASE 14: Recording the register of settlements to suppliers and documents
	RecordCalculatedBatches(AccumulationRegisters.VendorsARAPAccountingByDocuments, SettlementSettlementsWithSuppliers, RawData.Recorders);
	ClearRegisterOnServer(RawData.Recorders, "VendorsARAPAccountingByDocuments");
	If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(SettlementSettlementsWithSuppliers);
	EndIf;
	LoggersToReflection = SettlementSettlementsWithSuppliers.UnloadColumn("Recorder");
	// Updating the amounts in the data register and the balance management registers
	If LoggersToReflection.Count() > 0 Then
		InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateDocumentAmountsInAccountingCurrencies(LoggersToReflection);
	EndIf;
	// Updating the upr. balance
	GenerateRegisteredRecordsOnManagementAccounting(Context, SettlementSettlementsWithSuppliers);
EndProcedure

// Step 4: Record the new boundaries calculation
Procedure SetCalculationBoundaries(CalculatedPeriod, EndOfSettlementPeriod_, TaskRegisterName, CalculationAnalysts, TemporaryTable, TaskNumberBeforeCalculation, ProcessedItemsCount = 0)
	SetPrivilegedMode(True);
	
	If CalculationStart(TaskRegisterName, EndOfSettlementPeriod_, CalculationAnalysts, TaskNumberBeforeCalculation) < CalculatedPeriod Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Jobs.Month,
	|	Jobs.JobNumber,
	|	Jobs.Organization,
	|	Jobs.AccountingDimensionByPartners,
	|	Jobs.ARAPObject,
	|	Jobs.Document
	|FROM
	|	BorderCache AS Jobs
	|;
	|/////////////////////////////////////////////
	|SELECT DISTINCT
	|	&NextMonth                   AS Month,
	|	MAX(Boundaries.JobNumber)    AS JobNumber,
	|	Boundaries.Organization               AS Organization,
	|	Boundaries.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Boundaries.ARAPObject            AS ARAPObject,
	|	UNDEFINED                      AS Document
	|FROM
	|	BorderCache AS Boundaries
	|
	|	LEFT JOIN TaskRegisterName AS Jobs
	|	ON &NextMonth = Jobs.Month
	|		AND Boundaries.JobNumber = Jobs.JobNumber
	|		AND Boundaries.Organization = Jobs.Organization
	|		AND Boundaries.AccountingDimensionByPartners = Jobs.AccountingDimensionByPartners
	|		AND Boundaries.ARAPObject = Jobs.ARAPObject
	|		AND UNDEFINED = Jobs.Document
	|WHERE
	|	Jobs.Month IS NULL
	|
	|GROUP BY
	|	Boundaries.Organization,
	|	Boundaries.AccountingDimensionByPartners,
	|	Boundaries.ARAPObject
	|");
	
	Query.Text = StrReplace(Query.Text, "TaskRegisterName", "InformationRegister." + TaskRegisterName);
	Query.TempTablesManager = TemporaryTable;
	Query.SetParameter("NextMonth", EndOfMonth(CalculatedPeriod) + 1);
	
	Result = Query.ExecuteBatch();
	Selection = Result[0].Select();
	While Selection.Next() Do
		Set = InformationRegisters[TaskRegisterName].CreateRecordSet(); // InformationRegisterRecordSet.JobsForAllocatingCustomersARAP
		Set.Filter.Month.Set(Selection.Month);
		Set.Filter.JobNumber.Set(Selection.JobNumber);
		Set.Filter.Organization.Set(Selection.Organization);
		Set.Filter.AccountingDimensionByPartners.Set(Selection.AccountingDimensionByPartners);
		Set.Filter.ARAPObject.Set(Selection.ARAPObject);
		Set.Filter.Document.Set(Selection.Document);
		Set.Write(); // Cleared calculated analysts in the last period
		ProcessedItemsCount = ProcessedItemsCount + 1;
	EndDo;
	
	Selection = Result[1].Select();
	While Selection.Next() Do
		Set = InformationRegisters[TaskRegisterName].CreateRecordSet(); // InformationRegisterRecordSet.JobsForAllocatingCustomersARAP
		Set.Filter.Month.Set(Selection.Month);
		Set.Filter.JobNumber.Set(Selection.JobNumber);
		Set.Filter.Organization.Set(Selection.Organization);
		Set.Filter.AccountingDimensionByPartners.Set(Selection.AccountingDimensionByPartners);
		Set.Filter.ARAPObject.Set(Selection.ARAPObject);
		Set.Filter.Document.Set(Selection.Document);
		SetRow = Set.Add();
		FillPropertyValues(SetRow, Selection);
		Set.Write(True); // Moved calculated analytics to a new period
		ProcessedItemsCount = ProcessedItemsCount + 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region CustomersARAPAccounting

// Text of the request for initial movements for the distribution of settlements with clients
Function DataForSettlementsWithCustomers(BeginOfPeriod, PeriodEnding, CalculationAnalysts, TemporaryTable)
	TextSorting = "
		|ORDER BY
		|	PriorityOfBillingObject, Period, Priority, Recorder
		|";
	
	RequestSourceText =
		TextSettlementsWithClientsInitialization() + ";"
		+ ImplementationAdjustmentText() + ";"
		+ TextDescriptionSettlementsWithClients()
		+ "UNION ALL" + TextForSettlementsWithClients()
		+ "UNION ALL" + TextOfPreviousShipmentPeriods()
		+ "UNION ALL" + TextOfMovementOfSettlementsWithClients()
		+ "UNION ALL" + TextCurrentRecordsOfSettlementsWithCustomers()
		+ TextSorting;
	InitialQuery = New Query(RequestSourceText);
	InitialQuery.SetParameter("BeginOfPeriod", BeginOfPeriod);
	InitialQuery.SetParameter("PeriodEnding", PeriodEnding);
	InitialQuery.SetParameter("CalculationAnalysts", CalculationAnalysts);
	InitialQuery.SetParameter("ForAllAnalysts", CalculationAnalysts = Undefined);
	InitialQuery.SetParameter("CurrencyOfManAccounting", Constants.ManagementAccountingCurrency.Get());
	ListOfOrderTypes = New ValueList;
	ListOfOrderTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	ListOfOrderTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	ListOfOrderTypes.Add(Type("DocumentRef.SalesOrder"));
	ListOfOrderTypes.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	ListOfOrderTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	InitialQuery.SetParameter("ListOfOrderTypes", ListOfOrderTypes);
	InitialQuery.TempTablesManager = TemporaryTable;
	DataForCalculation = InitialQuery.Execute();

	Return DataForCalculation;
EndFunction

Function SettlementSettlementsWithCustomers(DataForCalculation, Recorders, ChainsOfRegisteredRecords = Undefined, Test = False, RecordsCount = 0) // The data for the calculation will be changed
	// Step 1: create an accumulation buffer of calculated batches
	Query = New Query(TextDescriptionSettlementsWithClients());
	SettlementBatches = Query.Execute().Unload();
	
	// Step 2: prepare a description of the calculation
	ContextOfChains = DescriptionOfChains("BalanceOfPayments, BalanceOfShipments, PastShipment, Payment, PaymentReversal, StornoShipment, Shipment, ReturnOfGoods, Relevant");
	
	ConsumptionFields = "AccountingDimensionByPartners, SalesOrder, Currency";
	ContextOfRegisteredRecords = RegisterRecordsDetails(
		"CustomersARAPAccounting", ListOfFields(SettlementBatches.Columns),
		ConsumptionFields,
		"ForReturn, Debt, ARAPMan, DebtLocal, Prepayment, PrepaymentMan, PrepaymentLocal, DepositForPackage, DepositForPackageLocal, Sum",
		"Sum", "Sum", "ARAPDocument", "Period", "Period, PriorityOfSettlementDocument DESC, Priority ASC, Recorder");
		
	// Step 3: we calculate the consumption from the batches
	AddReceiverDescription(ContextOfChains, "Payment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Payment", "BalanceOfShipments", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Payment", "Shipment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Payment", "PaymentReversal", ConsumptionFields);
	
	AddReceiverDescription(ContextOfChains, "Shipment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Shipment", "BalanceOfPayments", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Shipment", "Payment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Shipment", "StornoShipment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Shipment", "ReturnOfGoods", ConsumptionFields);
	
	AddReceiverDescription(ContextOfChains, "PaymentReversal", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "BalanceOfPayments", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "Payment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "ReturnOfGoods", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "StornoShipment", ConsumptionFields);
	
	AddReceiverDescription(ContextOfChains, "ReturnOfGoods", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "ReturnOfGoods", "BalanceOfShipments", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "ReturnOfGoods", "Shipment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "ReturnOfGoods", "PaymentReversal", ConsumptionFields);
	
	AddReceiverDescription(ContextOfChains, "StornoShipment", "AccountingDimensionByPartners, SalesOrder, Currency, DocumentShipments");
	AddSourceDescription(ContextOfChains, "StornoShipment", "BalanceOfShipments", "AccountingDimensionByPartners, SalesOrder, Currency, DocumentShipments");
	AddSourceDescription(ContextOfChains, "StornoShipment", "PastShipment", "AccountingDimensionByPartners, SalesOrder, Currency, DocumentShipments");
	AddSourceDescription(ContextOfChains, "StornoShipment", "Shipment", "AccountingDimensionByPartners, SalesOrder, Currency, DocumentShipments");
	
	ChainsOfRegisteredRecords = ChainsOfRegisteredRecordsFromSample(ContextOfChains, DataForCalculation);
	CalculateBatchesByChainsFromSample(ContextOfRegisteredRecords, DataForCalculation, SettlementBatches, ChainsOfRegisteredRecords, Recorders, Test, RecordsCount);
	
	// Step 4: Delete the lines that do not require writing to the database.
	DeleteUnwrittenLines(ContextOfRegisteredRecords.Context, SettlementBatches);
	
	// Step 5: Sorting batches for further recording
	SettlementBatches.Sort("Recorder, Priority", New CompareValues);
	Return SettlementBatches;
	
EndFunction

Function TextSettlementsWithClientsInitialization()
	Return "
		|SELECT DISTINCT
		|	Analysts.DimensionKey
		|INTO CalculationAnalysts
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS Analysts
		|WHERE
		|	(Analysts.DimensionKey IN (&CalculationAnalysts)
		|		OR &ForAllAnalysts)
		|;
		|///////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.Recorder                             AS Recorder,
		|	Calculations.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                          AS SalesOrder,
		|	Calculations.Currency                                  AS Currency,
		|	ISNULL(Amounts.Currency, Calculations.Currency)          AS DocumentCurrency
		|INTO RegistrarsToCalculate
		|FROM 
		|	(SELECT DISTINCT
		|		Calculations.Recorder               AS Recorder,
		|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		Calculations.ARAPObject            AS ARAPObject,
		|		Calculations.Currency                    AS Currency
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting AS Calculations 
		|			INNER JOIN CalculationAnalysts AS Analysts
		|				ON Calculations.AccountingDimensionByPartners = Analysts.DimensionKey
		|	WHERE
		|		Calculations.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND Calculations.Sum <> 0
		|
		|	UNION
		|
		|	SELECT DISTINCT
		|		CalculationsAccordingToDocuments.Recorder               AS Recorder,
		|		CalculationsAccordingToDocuments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		CalculationsAccordingToDocuments.SalesOrder              AS ARAPObject,
		|		CalculationsAccordingToDocuments.Currency                    AS Currency
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDocuments AS CalculationsAccordingToDocuments 
		|			INNER JOIN CalculationAnalysts AS Analysts
		|				ON CalculationsAccordingToDocuments.AccountingDimensionByPartners = Analysts.DimensionKey
		|	WHERE
		|		CalculationsAccordingToDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND (CalculationsAccordingToDocuments.Debt <> 0 OR CalculationsAccordingToDocuments.Prepayment <> 0)
		|	) AS Calculations
		|
		|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
		|	ON Calculations.Recorder = Amounts.Recorder
		|		AND Calculations.ARAPObject = Amounts.ARAPObject
		|		AND Amounts.PaymentType_ IN (VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting), VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef))
		|		AND NOT Amounts.Recorder REFS Document.ARAPSettlement
		|;
		|///////////////////////////////////////
		|SELECT DISTINCT
		|	CAST(Calculations.Recorder AS Document.SaleAdjustment).DocumentBasis AS Recorder
		|INTO ShippingDocuments
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|
		|	INNER JOIN CalculationAnalysts AS Analysts
		|	ON Calculations.AccountingDimensionByPartners = Analysts.DimensionKey
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND Calculations.Sum <> 0
		|	AND Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|;
		|////////////////////////////////////////
		|SELECT DISTINCT
		|	DD.ARAPDocument AS Ref,
		|	MAX(Periodicals.Recorder) AS Recorder,
		|	MAX(CASE 
		|				WHEN Periodicals.ARAPDocument REFS Document.SourceDocument 
		|						THEN CAST(Periodicals.ARAPDocument AS Document.SourceDocument).Date 
		|					ELSE Periodicals.Period 
		|			END) AS Period
		|INTO LeftoversOnLIFO
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&BeginOfPeriod) AS DD
		|	INNER JOIN AccumulationRegister.CustomersARAPAccountingByDocuments AS Periodicals
		|		ON Periodicals.Period < &BeginOfPeriod
		|		AND Periodicals.ARAPDocument = DD.ARAPDocument
		|WHERE
		|	DD.ARAPDocument <> UNDEFINED
		|	AND ((Periodicals.RecordType = VALUE(AccumulationRecordType.Receipt) AND Periodicals.Debt > 0)
		|		OR (Periodicals.RecordType = VALUE(AccumulationRecordType.Expense) AND Periodicals.Prepayment > 0)
		|	)
		|GROUP BY
		|	DD.ARAPDocument
		|;
		|///////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.Recorder AS Recorder,
		|	Calculations.ARAPDocument AS ARAPDocument,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	ShippingDocuments.Recorder AS DocumentShipments
		|INTO PastShipments
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
		|
		|	INNER JOIN ShippingDocuments AS ShippingDocuments
		|	ON Calculations.Recorder = ShippingDocuments.Recorder
		|
		|	INNER JOIN CalculationAnalysts AS FilterByAnalysts
		|	ON Calculations.AccountingDimensionByPartners = FilterByAnalysts.DimensionKey
		|
		|	LEFT JOIN LeftoversOnLIFO AS LeftoversOnLIFO
		|	ON Calculations.ARAPDocument = LeftoversOnLIFO.Ref
		|WHERE
		|	Calculations.Period < &BeginOfPeriod
		|	AND LeftoversOnLIFO.Ref IS NULL
		|	AND Calculations.ARAPDocument <> ShippingDocuments.Recorder
		|;
		|////////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.Recorder               AS Recorder,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject            AS SalesOrder,
		|	Calculations.Currency                    AS Currency
		|INTO CurrentAnalytics
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|
		|	INNER JOIN RegistrarsToCalculate AS Recorders
		|	ON Calculations.Recorder = Recorders.Recorder
		|
		|	LEFT JOIN CalculationAnalysts AS ReadyForCalculation
		|	ON Calculations.AccountingDimensionByPartners = ReadyForCalculation.DimensionKey
		|WHERE
		|	ReadyForCalculation.DimensionKey IS NULL
		|	AND NOT Calculations.Recorder REFS Document.RegisterAdjustment
		|;
		|////////////////////////////////////////
		|SELECT 
		|	AdjustingEntries.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	AdjustingEntries.SalesOrder              AS SalesOrder,
		|	AdjustingEntries.ARAPDocument         AS ARAPDocument,
		|	AdjustingEntries.Currency                    AS Currency,
		|	SUM(AdjustingEntries.ForReturn)          AS ForReturn,
		|	SUM(AdjustingEntries.Debt)               AS Debt,
		|	SUM(AdjustingEntries.ARAPMan)            AS ARAPMan,
		|	SUM(AdjustingEntries.DebtLocal)           AS DebtLocal,
		|	SUM(AdjustingEntries.Prepayment)         AS Prepayment,
		|	SUM(AdjustingEntries.PrepaymentMan)      AS PrepaymentMan,
		|	SUM(AdjustingEntries.PrepaymentLocal)     AS PrepaymentLocal,
		|	SUM(AdjustingEntries.DepositForPackage)        AS DepositForPackage,
		|	SUM(AdjustingEntries.DepositForPackageLocal)    AS DepositForPackageLocal
		|INTO TTAdjustmentsForDocuments
		|FROM	
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS AdjustingEntries
		|WHERE
		|	AdjustingEntries.Recorder REFS Document.RegisterAdjustment
		|	AND AdjustingEntries.Period BETWEEN  &BeginOfPeriod AND &PeriodEnding
		|	AND AdjustingEntries.Active
		|GROUP BY 
		|	AdjustingEntries.AccountingDimensionByPartners,
		|	AdjustingEntries.SalesOrder,
		|	AdjustingEntries.ARAPDocument,
		|	AdjustingEntries.Currency
		|;
		|/////////////////////////////////////////////
		|SELECT
		|	10 AS Priority,
		|	1 AS PriorityOfBillingObject,
		|	CASE WHEN DD.PrepaymentBalance <> 0 
		|		THEN ""BalanceOfPayments""
		|		ELSE ""BalanceOfShipments""
		|	END AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	ISNULL(Periodicals.Period, &BeginOfPeriod) AS Period,
		|	ISNULL(Periodicals.Recorder, DD.ARAPDocument) AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CASE WHEN DD.SalesOrder = UNDEFINED
		|		THEN NULL
		|		ELSE DD.SalesOrder
		|	END AS SalesOrder,
		|	DD.ARAPDocument AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	CASE WHEN (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0) + DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0)) < 0
		|		THEN 0 - (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0) + DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0))
		|		ELSE (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0)  + DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0))
		|	END AS Sum,
		|	CASE WHEN DD.ForReturnBalance + ISNULL(AdjustingEntries.ForReturn,0) < 0
		|		THEN 0 - (DD.ForReturnBalance + ISNULL(AdjustingEntries.ForReturn,0))
		|		ELSE DD.ForReturnBalance + ISNULL(AdjustingEntries.ForReturn,0)
		|	END AS ForReturn,
		|	CASE WHEN DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0) < 0
		|		THEN 0 - (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0))
		|		ELSE DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0)
		|	END AS Debt,
		|	CASE WHEN DD.ARAPManBalance + ISNULL(AdjustingEntries.ARAPMan,0) < 0
		|		THEN 0 - (DD.ARAPManBalance + ISNULL(AdjustingEntries.ARAPMan,0))
		|		ELSE DD.ARAPManBalance + ISNULL(AdjustingEntries.ARAPMan,0)
		|	END AS ARAPMan,
		|	CASE WHEN DD.DebtLocalBalance + ISNULL(AdjustingEntries.DebtLocal,0) < 0
		|		THEN 0 - (DD.DebtLocalBalance + ISNULL(AdjustingEntries.DebtLocal,0))
		|		ELSE DD.DebtLocalBalance + ISNULL(AdjustingEntries.DebtLocal,0)
		|	END AS DebtLocal,
		|	CASE WHEN DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0) < 0
		|		THEN 0 - (DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0))
		|		ELSE DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0)
		|	END AS Prepayment,
		|	CASE WHEN DD.PrepaymentManBalance + ISNULL(AdjustingEntries.PrepaymentMan,0) < 0
		|		THEN 0 - (DD.PrepaymentManBalance + ISNULL(AdjustingEntries.PrepaymentMan,0))
		|		ELSE DD.PrepaymentManBalance + ISNULL(AdjustingEntries.PrepaymentMan,0)
		|	END AS PrepaymentMan,
		|	CASE WHEN DD.PrepaymentLocalBalance + ISNULL(AdjustingEntries.PrepaymentLocal,0) < 0
		|		THEN 0 - (DD.PrepaymentLocalBalance + ISNULL(AdjustingEntries.PrepaymentLocal,0))
		|		ELSE DD.PrepaymentLocalBalance + ISNULL(AdjustingEntries.PrepaymentLocal,0)
		|	END AS PrepaymentLocal,
		|	CASE WHEN DD.DepositForPackageBalance + ISNULL(AdjustingEntries.DepositForPackage,0) < 0
		|		THEN 0 - (DD.DepositForPackageBalance + ISNULL(AdjustingEntries.DepositForPackage,0))
		|		ELSE DD.DepositForPackageBalance + ISNULL(AdjustingEntries.DepositForPackage,0)
		|	END AS DepositForPackage,
		|	CASE WHEN DD.DepositForPackageLocalBalance + ISNULL(AdjustingEntries.DepositForPackageLocal,0)< 0
		|		THEN 0 - (DD.DepositForPackageLocalBalance + ISNULL(AdjustingEntries.DepositForPackageLocal,0))
		|		ELSE DD.DepositForPackageLocalBalance + ISNULL(AdjustingEntries.DepositForPackageLocal,0)
		|	END AS DepositForPackageLocal,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	VALUE(Catalog.CashFlowReportItems.EmptyRef) AS CashFlowItem,
		|	DATETIME(1, 1, 1, 0, 0, 0) AS PaymentDate,
		|	ISNULL(Periodicals.Recorder, DD.ARAPDocument) AS DocumentShipments,
		|	1 AS NettingMovementIndex,
		|	CASE WHEN ISNULL(Periodicals.Recorder, 0) = DD.ARAPDocument 
		|		THEN 1 
		|			ELSE 0 
		|	END AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|INTO TTBalancesWithCustomers
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&BeginOfPeriod) AS DD
		|
		|	INNER JOIN CalculationAnalysts AS Analysts
		|	ON DD.AccountingDimensionByPartners = Analysts.DimensionKey
		|
		|	LEFT JOIN LeftoversOnLIFO AS Periodicals
		|		ON Periodicals.Ref = DD.ARAPDocument
		|	
		|	LEFT JOIN TTAdjustmentsForDocuments AS AdjustingEntries
		|		ON DD.AccountingDimensionByPartners = AdjustingEntries.AccountingDimensionByPartners
		|			AND DD.SalesOrder           = AdjustingEntries.SalesOrder
		|			AND DD.ARAPDocument      = AdjustingEntries.ARAPDocument
		|			AND DD.Currency                 = AdjustingEntries.Currency
		|";
EndFunction

Function ImplementationAdjustmentText()
	Return "
		|SELECT
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.ARAPObject AS SalesOrder,
		|	DD.Currency AS Currency,
		|
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN - DD.Sum
		|		ELSE DD.Sum
		|	END) AS Sum,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN - DD.SumMan
		|		ELSE DD.SumMan
		|	END) AS SumMan,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN - DD.SumCompl
		|		ELSE DD.SumCompl
		|	END) AS SumCompl,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN - DD.DepositForPackage
		|		ELSE DD.DepositForPackage
		|	END) AS DepositForPackage,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN - DD.AmountDue
		|		ELSE DD.AmountDue
		|	END) AS AmountDue,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN - DD.BeingPaid
		|		ELSE DD.BeingPaid
		|	END) AS BeingPaid,
		|
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	DD.PaymentDate AS PaymentDate,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ToCalculation.DocumentCurrency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfLocalDocument,
		|	CASE WHEN ToCalculation.Currency = &CurrencyOfManAccounting
		|		OR ToCalculation.DocumentCurrency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfDocumentMan
		|INTO TTAdjustments
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS DD
		|
		|	INNER JOIN RegistrarsToCalculate AS ToCalculation
		|	ON DD.Recorder = ToCalculation.Recorder
		|		AND DD.AccountingDimensionByPartners = ToCalculation.AccountingDimensionByPartners
		|		AND DD.ARAPObject = ToCalculation.SalesOrder
		|		AND DD.Currency = ToCalculation.Currency
		|WHERE
		|	DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND DD.Sum <> 0
		|	AND VALUETYPE(DD.Recorder) = VALUE(Document.SaleAdjustment)
		|
		|GROUP BY
		|	DD.Period,
		|	DD.Recorder,
		|	DD.AccountingDimensionByPartners,
		|	DD.ARAPObject,
		|	DD.Currency,
		|	DD.BusinessOperation,
		|	DD.CashFlowItem,
		|	DD.PaymentDate,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ToCalculation.DocumentCurrency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END,
		|	CASE WHEN ToCalculation.Currency = &CurrencyOfManAccounting
		|		OR ToCalculation.DocumentCurrency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END
		|;
		|/////////////////////////////////////////////
		|SELECT
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	CASE WHEN DD.Sum < 0 
		|		THEN VALUE(AccumulationRecordType.Expense)
		|		ELSE VALUE(AccumulationRecordType.Receipt)
		|	END AS RecordType,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.SalesOrder AS SalesOrder,
		|	DD.Currency AS Currency,
		|
		|	CASE WHEN DD.Sum < 0
		|		THEN 0 - DD.Sum
		|		ELSE DD.Sum
		|	END AS Sum,
		|	CASE WHEN DD.SumMan < 0
		|		THEN 0 - DD.SumMan
		|		ELSE DD.SumMan
		|	END AS SumMan,
		|	CASE WHEN DD.SumCompl < 0
		|		THEN 0 - DD.SumCompl
		|		ELSE DD.SumCompl
		|	END AS SumCompl,
		|
		|	CASE WHEN DD.DepositForPackage < 0
		|		THEN 0 - DD.DepositForPackage
		|		ELSE DD.DepositForPackage
		|	END AS DepositForPackage,
		|	CASE WHEN DD.AmountDue < 0
		|		THEN 0 - DD.AmountDue
		|		ELSE DD.AmountDue
		|	END AS AmountDue,
		|	CASE WHEN DD.BeingPaid < 0
		|		THEN 0 - DD.BeingPaid
		|		ELSE DD.BeingPaid
		|	END AS BeingPaid,
		|
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	DD.PaymentDate AS PaymentDate,
		|	DD.CalculationAtRateOfLocalDocument AS CalculationAtRateOfLocalDocument,
		|	DD.CalculationAtRateOfDocumentMan AS CalculationAtRateOfDocumentMan
		|INTO AdjustingEntries
		|FROM TTAdjustments AS DD
		|;
		|////////////////////////////////////
		|DROP TTAdjustments
		|";
EndFunction

Function TextDescriptionSettlementsWithClients()
	Return "
		|SELECT TOP 0
		|	0 AS Priority,
		|	0 AS PriorityOfBillingObject,
		|	""XXXXXXXXXXXXXXXX"" AS EntryType,
		|	FALSE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DATETIME(1, 1, 1, 0, 0, 0) AS Period,
		|	DD.Recorder AS Recorder,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	DD.SalesOrder AS SalesOrder,
		|	DD.ARAPDocument AS ARAPDocument,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	0. AS Sum,
		|	0. AS ForReturn,
		|	0. AS Debt,
		|	0. AS ARAPMan,
		|	0. AS DebtLocal,
		|	0. AS Prepayment,
		|	0. AS PrepaymentMan,
		|	0. AS PrepaymentLocal,
		|	0. AS DepositForPackage,
		|	0. AS DepositForPackageLocal,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	VALUE(Catalog.CashFlowReportItems.EmptyRef) AS CashFlowItem,
		|	DATETIME(1, 1, 1, 0, 0, 0) AS PaymentDate,
		|	UNDEFINED AS DocumentShipments,
		|	UNDEFINED AS CalculationAtRateOfLocalDocument,
		|	UNDEFINED AS CalculationAtRateOfDocumentMan,
		|	1 AS NettingMovementIndex,
		|	0 AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS DD
		|";
EndFunction
	
Function TextForSettlementsWithClients()
	Return "
		|SELECT
		|	Balance.Priority AS Priority,
		|	Balance.PriorityOfBillingObject AS PriorityOfBillingObject,
		|	Balance.EntryType AS EntryType,
		|	Balance.CalculationIsCompleted AS CalculationIsCompleted,
		|	Balance.RecordType AS RecordType,
		|	Balance.Period AS Period,
		|	Balance.Recorder AS Recorder,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Balance.SalesOrder AS SalesOrder,
		|	Balance.ARAPDocument AS ARAPDocument,
		|	Balance.Currency AS Currency,
		|	Balance.Sum AS Sum,
		|	Balance.ForReturn AS ForReturn,
		|	Balance.Debt AS Debt,
		|	Balance.ARAPMan AS ARAPMan,
		|	Balance.DebtLocal AS DebtLocal,
		|	Balance.Prepayment AS Prepayment,
		|	Balance.PrepaymentMan AS PrepaymentMan,
		|	Balance.PrepaymentLocal AS PrepaymentLocal,
		|	Balance.DepositForPackage AS DepositForPackage,
		|	Balance.DepositForPackageLocal AS DepositForPackageLocal,
		|	Balance.BusinessOperation AS BusinessOperation,
		|	Balance.CashFlowItem AS CashFlowItem,
		|	Balance.PaymentDate AS PaymentDate,
		|	Balance.DocumentShipments AS DocumentShipments,
		|	CASE WHEN Balance.Currency = Balance.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ISNULL(MAX(Amounts.Currency), VALUE(Catalog.Currencies.EmptyRef)) = Balance.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR VALUETYPE(Balance.ARAPDocument) <> TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfLocalDocument,
		|	CASE WHEN Balance.Currency = &CurrencyOfManAccounting
		|		OR ISNULL(MAX(Amounts.Currency), VALUE(Catalog.Currencies.EmptyRef)) = &CurrencyOfManAccounting
		|		OR VALUETYPE(Balance.ARAPDocument) <> TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfDocumentMan,
		|	NettingMovementIndex AS NettingMovementIndex,
		|	PriorityOfSettlementDocument AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|
		|FROM TTBalancesWithCustomers AS Balance
		|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
		|		ON Balance.Recorder = Amounts.Recorder
		|			AND Balance.SalesOrder = Amounts.ARAPObject
		|			AND VALUETYPE(Amounts.Recorder) <> TYPE(Document.ARAPSettlement)
		|GROUP BY
		|	Balance.Priority,
		|	Balance.PriorityOfBillingObject,
		|	Balance.EntryType,
		|	Balance.CalculationIsCompleted,
		|	Balance.RecordType,
		|	Balance.Period,
		|	Balance.Recorder,
		|	Balance.AccountingDimensionByPartners,
		|	Balance.SalesOrder,
		|	Balance.ARAPDocument,
		|	Balance.Currency,
		|	Balance.Sum,
		|	Balance.ForReturn,
		|	Balance.Debt,
		|	Balance.ARAPMan,
		|	Balance.DebtLocal,
		|	Balance.Prepayment,
		|	Balance.PrepaymentMan,
		|	Balance.PrepaymentLocal,
		|	Balance.DepositForPackage,
		|	Balance.DepositForPackageLocal,
		|	Balance.BusinessOperation,
		|	Balance.CashFlowItem,
		|	Balance.PaymentDate,
		|	Balance.DocumentShipments,
		|	NettingMovementIndex,
		|	PriorityOfSettlementDocument
		|	
		|";
EndFunction
	
Function TextOfPreviousShipmentPeriods()
	Return "
		|SELECT
		|	CASE WHEN DD.Recorder <> DD.ARAPDocument
		|		THEN 9
		|		ELSE 10
		|	END AS Priority,
		|	1 AS PriorityOfBillingObject,
		|	""PastShipment"" AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	DD.RecordType AS RecordType,
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CASE WHEN DD.SalesOrder.Object = UNDEFINED
		|		THEN NULL
		|		ELSE DD.SalesOrder
		|	END AS SalesOrder,
		|	CASE WHEN DD.ARAPDocument = PastShipments.DocumentShipments
		|		THEN DD.Recorder
		|		ELSE DD.ARAPDocument
		|	END AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	SUM(CASE WHEN (DD.Debt + DD.Prepayment) < 0
		|		THEN 0 - (DD.Debt + DD.Prepayment)
		|		ELSE (DD.Debt + DD.Prepayment)
		|	END) AS Sum,
		|	SUM(DD.ForReturn) AS ForReturn,
		|	SUM(CASE WHEN DD.ARAPDocument = DD.Recorder
		|			THEN DD.Debt
		|			ELSE 0
		|	END) AS Debt,
		|	SUM(CASE WHEN DD.ARAPDocument = DD.Recorder
		|			THEN DD.ARAPMan
		|			ELSE 0
		|	END) AS ARAPMan,
		|	SUM(CASE WHEN DD.ARAPDocument = DD.Recorder
		|			THEN DD.DebtLocal
		|			ELSE 0
		|	END) AS DebtLocal,
		|	SUM(CASE WHEN DD.ARAPDocument <> DD.Recorder AND DD.Debt <> 0
		|			THEN DD.Debt
		|			ELSE DD.Prepayment
		|	END) AS Prepayment,
		|	SUM(CASE WHEN DD.ARAPDocument <> DD.Recorder AND DD.ARAPMan <> 0
		|			THEN DD.ARAPMan
		|			ELSE DD.PrepaymentMan
		|	END) AS PrepaymentMan,
		|	SUM(CASE WHEN DD.ARAPDocument <> DD.Recorder AND DD.DebtLocal <> 0
		|			THEN DD.DebtLocal
		|			ELSE DD.PrepaymentLocal
		|	END) AS PrepaymentLocal,
		|	SUM(DD.DepositForPackage) AS DepositForPackage,
		|	SUM(DD.DepositForPackageLocal) AS DepositForPackageLocal,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	DD.PaymentDate AS PaymentDate,
		|	PastShipments.DocumentShipments AS DocumentShipments,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR Amounts.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfLocalDocument,
		|	CASE WHEN DD.Currency = &CurrencyOfManAccounting
		|		OR Amounts.Currency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfDocumentMan,
		|	1 AS NettingMovementIndex,
		|	CASE WHEN DD.Recorder = DD.ARAPDocument 
		|		THEN 1
		|			ELSE 0 
		|	END AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS DD
		|
		|	INNER JOIN PastShipments AS PastShipments
		|	ON DD.Recorder = PastShipments.Recorder
		|		AND DD.ARAPDocument = PastShipments.ARAPDocument
		|		AND DD.AccountingDimensionByPartners = PastShipments.AccountingDimensionByPartners
		|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
		|	ON CASE WHEN DD.ARAPDocument = PastShipments.DocumentShipments
		|				THEN DD.Recorder
		|			ELSE DD.ARAPDocument
		|		END = Amounts.Recorder
		|		AND DD.SalesOrder = Amounts.ARAPObject
		|		AND Amounts.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|GROUP BY
		|	CASE WHEN DD.Recorder <> DD.ARAPDocument
		|		THEN 9
		|		ELSE 10
		|	END,
		|	DD.RecordType,
		|	DD.Period,
		|	DD.Recorder,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.ARAPDocument,
		|	DD.Currency,
		|	DD.PaymentDate,
		|	DD.BusinessOperation,
		|	DD.CashFlowItem,
		|	DD.PaymentDate,
		|	PastShipments.DocumentShipments,
		|	CASE WHEN DD.Recorder = DD.ARAPDocument 
		|		THEN 1
		|			ELSE 0 
		|	END,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR Amounts.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END,
		|	CASE WHEN DD.Currency = &CurrencyOfManAccounting
		|		OR Amounts.Currency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END
		|";
EndFunction

Function TextOfMovementOfSettlementsWithClients()
	Return "
		| // Movements in Settlements with clients without adjustments to implementations
		|SELECT
		|	CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0)
		|			THEN 12
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND (DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction))
		|		THEN 14
		|		ELSE 11
		|	END,
		|	CASE WHEN DD.ARAPObject.Object REFS Document.BankAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.CashAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.SourceDocument
		|		OR DD.ARAPObject.Object REFS Document.SalesOrder
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|		OR DD.ARAPObject.Object REFS Catalog.CounterpartyContracts 
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN 1
		|		ELSE 2
		|	END AS PriorityOfBillingObject,
		|	CASE
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|				AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|													VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|													VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|													VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor),
		|													VALUE(Enum.BusinessTransactions.ARAPAdjustment))
		|				AND NOT (DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|						AND VALUETYPE(DD.Recorder) <> TYPE(Document.ARAPSettlement))
		|			THEN ""Payment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN ""Shipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND (DD.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|				VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|				VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor))
		|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|					AND VALUETYPE(DD.Recorder) <> TYPE(Document.ARAPSettlement))
		|			THEN ""ReturnOfGoods""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|			THEN ""StornoShipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|			THEN ""PaymentReversal""
		|	END AS EntryType,
		|	FALSE AS CalculationIsCompleted,
		|	DD.RecordType AS RecordType,
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.ARAPObject  SalesOrder,
		|	CASE WHEN DD.ARAPDocument <> UNDEFINED
		|		THEN DD.ARAPDocument
		|		ELSE DD.Recorder
		|	END AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	SUM(DD.Sum) AS Sum,
		|	0. AS ForReturn,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|					 AND DD.Sum < 0)
		|			THEN DD.Sum
		|			ELSE 0
		|		END
		|	) AS Debt,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|					 AND DD.Sum < 0)
		|			THEN DD.SumMan
		|			ELSE 0
		|		END
		|	) AS ARAPMan,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|					 AND DD.Sum < 0)
		|			THEN DD.SumCompl
		|			ELSE 0
		|		END
		|	) AS DebtLocal,
		|	SUM(
		|		CASE WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0)
		|				THEN DD.Sum
		|			ELSE 0
		|		END
		|	) AS Prepayment,
		|	SUM(
		|		CASE WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0)
		|				THEN DD.SumMan
		|			ELSE 0
		|		END
		|	) AS PrepaymentMan,
		|	SUM(
		|		CASE WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0)
		|				THEN DD.SumCompl
		|			ELSE 0
		|		END
		|	) AS PrepaymentLocal,
		|	SUM(DD.DepositForPackage) AS DepositForPackage,
		|	0. AS DepositForPackageLocal,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	DD.PaymentDate AS PaymentDate,
		|	CASE WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		AND DD.Recorder REFS Document.SaleAdjustment
		|			THEN CAST(DD.Recorder AS Document.SaleAdjustment).DocumentBasis
		|		ELSE DD.Recorder
		|	END AS DocumentShipments,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ToCalculation.DocumentCurrency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfLocalDocument,
		|	CASE WHEN ToCalculation.Currency = &CurrencyOfManAccounting
		|		OR ToCalculation.DocumentCurrency = &CurrencyOfManAccounting
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfDocumentMan,
		|
		|	CASE WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			AND DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|		THEN 0
		|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			AND DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|		THEN -1
		|		ELSE 1
		|	END AS NettingMovementIndex,
		|	0 AS PriorityOfSettlementDocument,
		|	DD.CorARAPObject AS CorARAPObject,
		|	DD.CorPartnerAccountingDimension AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS DD
		|
		|	INNER JOIN RegistrarsToCalculate AS ToCalculation
		|	ON DD.Recorder = ToCalculation.Recorder
		|		AND (DD.AccountingDimensionByPartners = ToCalculation.AccountingDimensionByPartners 
		|			OR ToCalculation.AccountingDimensionByPartners = VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef))
		|		AND DD.ARAPObject = ToCalculation.SalesOrder
		|		AND DD.Currency = ToCalculation.Currency
		|WHERE
		|	DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND DD.Sum <> 0
		|	AND VALUETYPE(DD.Recorder) <> VALUE(Document.SaleAdjustment)
		|	AND NOT DD.Recorder REFS Document.RegisterAdjustment
		|GROUP BY
		|	CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0)
		|			THEN 12
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND (DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction))
		|		THEN 14
		|		ELSE 11
		|	END,
		|	CASE WHEN DD.ARAPObject.Object REFS Document.BankAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.CashAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.SourceDocument
		|		OR DD.ARAPObject.Object REFS Document.SalesOrder
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|		OR DD.ARAPObject.Object REFS Catalog.CounterpartyContracts 
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN 1
		|		ELSE 2
		|	END,
		|	CASE
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|				AND NOT DD.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|													VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|													VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|													VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor),
		|													VALUE(Enum.BusinessTransactions.ARAPAdjustment))
		|				AND NOT (DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|						AND VALUETYPE(DD.Recorder) <> TYPE(Document.ARAPSettlement))
		|			THEN ""Payment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN ""Shipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND (DD.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|				VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|				VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor))
		|				OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPSettlement)
		|					AND VALUETYPE(DD.Recorder) <> TYPE(Document.ARAPSettlement))
		|			THEN ""ReturnOfGoods""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|			THEN ""StornoShipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|			THEN ""PaymentReversal""
		|	END,
		|	DD.Period,
		|	DD.Recorder,
		|	CASE WHEN DD.ARAPDocument <> UNDEFINED
		|		THEN DD.ARAPDocument
		|		ELSE DD.Recorder
		|	END,
		|	DD.RecordType,
		|	DD.AccountingDimensionByPartners,
		|	DD.ARAPObject,
		|	DD.Currency,
		|	DD.PaymentDate,
		|	DD.BusinessOperation,
		|	DD.CashFlowItem,
		|	DD.PaymentDate,
		|	CASE WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		AND DD.Recorder REFS Document.SaleAdjustment
		|			THEN CAST(DD.Recorder AS Document.SaleAdjustment).DocumentBasis
		|		ELSE DD.Recorder
		|	END,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ToCalculation.DocumentCurrency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END,
		|	CASE WHEN ToCalculation.Currency = &CurrencyOfManAccounting
		|		OR ToCalculation.DocumentCurrency = &CurrencyOfManAccounting
		|		OR VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END,
		|	CASE WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			AND DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|		THEN 0
		|		WHEN VALUETYPE(DD.Recorder) = TYPE(Document.ARAPSettlement)
		|			AND DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|		THEN -1
		|		ELSE 1
		|	END,
		|	0,
		|	DD.CorARAPObject,
		|	DD.CorPartnerAccountingDimension
		|
		|UNION ALL
		|
		| // Document Movement Implementation Adjustment
		|SELECT
		|	CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0)
		|			THEN 12
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		THEN 14
		|		ELSE 13
		|	END,
		|	2 AS PriorityOfBillingObject,
		|	CASE
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.BeingPaid > 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.AmountDue > 0)
		|				AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|			THEN ""Payment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN ""Shipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0 AND DD.AmountDue <> 0
		|			AND DD.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|				VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer))
		|			THEN ""ReturnOfGoods""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|			THEN ""StornoShipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.BeingPaid = 0
		|			THEN ""PaymentReversal""
		|	END AS EntryType,
		|	FALSE AS CalculationIsCompleted,
		|	DD.RecordType AS RecordType,
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CASE WHEN DD.SalesOrder.OBJECT = UNDEFINED
		|		THEN NULL
		|		ELSE DD.SalesOrder
		|	END AS SalesOrder,
		|	DD.Recorder AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	SUM(DD.Sum) AS Sum,
		|	0. AS ForReturn,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0)
		|			THEN DD.Sum
		|			ELSE 0
		|		END
		|	) AS Debt,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0)
		|			THEN DD.SumMan
		|			ELSE 0
		|		END
		|	) AS ARAPMan,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0)
		|			THEN DD.SumCompl
		|			ELSE 0
		|		END
		|	) AS DebtLocal,
		|	SUM(
		|		CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			THEN DD.Sum
		|			ELSE 0
		|		END
		|	) AS Prepayment,
		|	SUM(
		|		CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			THEN DD.SumMan
		|			ELSE 0
		|		END
		|	) AS PrepaymentMan,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			THEN DD.SumCompl
		|			ELSE 0
		|		END
		|	) AS PrepaymentLocal,
		|	SUM(DD.DepositForPackage) AS DepositForPackage,
		|	0. AS DepositForPackageLocal,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	DD.PaymentDate AS PaymentDate,
		|	CASE WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		AND DD.Recorder REFS Document.SaleAdjustment
		|			THEN CAST(DD.Recorder AS Document.SaleAdjustment).DocumentBasis
		|		ELSE DD.Recorder
		|	END AS DocumentShipments,
		|	DD.CalculationAtRateOfLocalDocument AS CalculationAtRateOfLocalDocument,
		|	DD.CalculationAtRateOfDocumentMan AS CalculationAtRateOfDocumentMan,
		|	1 AS NettingMovementIndex,
		|	0 AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|FROM
		|	AdjustingEntries AS DD
		|GROUP BY
		|	CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) 
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0)
		|			THEN 12
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		THEN 14
		|		ELSE 13
		|	END,
		|	CASE
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.BeingPaid > 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.AmountDue > 0)
		|				AND DD.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|			THEN ""Payment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN ""Shipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0 AND DD.AmountDue <> 0
		|			AND DD.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
		|				VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer))
		|			THEN ""ReturnOfGoods""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|			THEN ""StornoShipment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.BeingPaid = 0
		|			THEN ""PaymentReversal""
		|	END,
		|	DD.Period,
		|	DD.Recorder,
		|	DD.RecordType,
		|	DD.AccountingDimensionByPartners,
		|	DD.SalesOrder,
		|	DD.Currency,
		|	DD.PaymentDate,
		|	DD.BusinessOperation,
		|	DD.CashFlowItem,
		|	DD.PaymentDate,
		|	CASE WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		AND DD.Recorder REFS Document.SaleAdjustment
		|			THEN CAST(DD.Recorder AS Document.SaleAdjustment).DocumentBasis
		|		ELSE DD.Recorder
		|	END,
		|	DD.CalculationAtRateOfLocalDocument,
		|	DD.CalculationAtRateOfDocumentMan,
		|	0
		|";
EndFunction

Function TextCurrentRecordsOfSettlementsWithCustomers()
	Return "
		|SELECT
		|	11 AS Priority,
		|	1 AS PriorityOfBillingObject,
		|	""Relevant"" AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	DD.RecordType AS RecordType,
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.SalesOrder AS SalesOrder,
		|	DD.ARAPDocument AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	0. AS Sum,
		|	DD.ForReturn AS ForReturn,
		|	DD.Debt AS Debt,
		|	DD.ARAPMan AS ARAPMan,
		|	DD.DebtLocal AS DebtLocal,
		|	DD.Prepayment AS Prepayment,
		|	DD.PrepaymentMan AS PrepaymentMan,
		|	DD.PrepaymentLocal AS PrepaymentLocal,
		|	DD.DepositForPackage AS DepositForPackage,
		|	DD.DepositForPackageLocal AS DepositForPackageLocal,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	DD.PaymentDate AS PaymentDate,
		|	UNDEFINED AS DocumentShipments,
		|	FALSE AS CalculationAtRateOfLocalDocument,
		|	FALSE AS CalculationAtRateOfDocumentMan,
		|	1 AS NettingMovementIndex,
		|	0 AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS DD
		|
		|	INNER JOIN CurrentAnalytics AS CurrentAnalytics
		|	ON DD.Recorder = CurrentAnalytics.Recorder
		|		AND DD.AccountingDimensionByPartners = CurrentAnalytics.AccountingDimensionByPartners
		|		AND DD.SalesOrder = CurrentAnalytics.SalesOrder
		|		AND DD.Currency = CurrentAnalytics.Currency
		|";
EndFunction

#EndRegion

#Region VendorsARAPAccounting

// Request text for source movements for distribution of payments to suppliers
Function DataForSettlementsWithSuppliers(BeginOfPeriod, PeriodEnding, CalculationAnalysts, TemporaryTable)
	// SORTING by analysts, priority and moment of movement is a requirement of the calculation calculation algorithm
	TextSorting = "
		|ORDER BY
		|	PriorityOfBillingObject, Period, Priority, Recorder
		|";
	
	RequestSourceText =
		TextSettlementsWithSuppliersInitialization() + ";"
		+  TextDescriptionSettlementsWithSuppliers()
		+ "UNION ALL" +  TextOfSettlementsWithSuppliers()
		+ "UNION ALL" +  TextOfReceiptsFromPastPeriods()
		+ "UNION ALL" +  TextOfMovementOfSettlementsWithSuppliers()
		+ TextSorting;
	InitialQuery = New Query(RequestSourceText);
	InitialQuery.SetParameter("BeginOfPeriod", BeginOfPeriod);
	InitialQuery.SetParameter("PeriodEnding", PeriodEnding);
	InitialQuery.SetParameter("CalculationAnalysts", CalculationAnalysts);
	InitialQuery.SetParameter("ForAllAnalysts", CalculationAnalysts = Undefined);
	InitialQuery.SetParameter("CurrencyOfManAccounting", Constants.ManagementAccountingCurrency.Get());
	ListOfOrderTypes = New ValueList;
	ListOfOrderTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	ListOfOrderTypes.Add(Type("DocumentRef.SubcontractOrder2_5"));
	ListOfOrderTypes.Add(Type("DocumentRef.PurchaseOrder"));
	ListOfOrderTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	InitialQuery.SetParameter("ListOfOrderTypes", ListOfOrderTypes);
	InitialQuery.TempTablesManager = TemporaryTable;
	DataForCalculation = InitialQuery.Execute();

	Return DataForCalculation;
EndFunction

Function SettlementSettlementsWithSuppliers(DataForCalculation, Recorders, ChainsOfRegisteredRecords = Undefined, Test = False, RecordsCount = 0) // The data for the calculation will be changed
	// Step 1: create an accumulation buffer of calculated batches
	Query = New Query(TextDescriptionSettlementsWithSuppliers());
	SettlementBatches = Query.Execute().Unload();
	
	// Step 2: prepare a description of the calculation
	ContextOfChains = DescriptionOfChains("BalanceOfPayments, BalanceOfReceipts, PastAdmission, Payment, ReverseOfReceipt, PaymentReversal, UninvoicedReceipt, ReturnOfGoods, Relevant");
	
	ConsumptionFields = "AccountingDimensionByPartners, PurchaseOrder, Currency";
	ContextOfRegisteredRecords = RegisterRecordsDetails(
		"VendorsARAPAccounting", ListOfFields(SettlementBatches.Columns),
		ConsumptionFields,
		"ForReturn, Debt, ARAPMan, DebtLocal, Prepayment, PrepaymentMan, PrepaymentLocal, DepositForPackage, DepositForPackageLocal, Sum",
		"Sum", "Sum", "ARAPDocument", "Period", "Period, PriorityOfSettlementDocument DESC, Priority ASC");
		
	// Step 3: we calculate the consumption from the batches
	AddReceiverDescription(ContextOfChains, "Payment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Payment", "BalanceOfReceipts", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Payment", "UninvoicedReceipt", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "Payment", "PaymentReversal", ConsumptionFields);
	
	AddReceiverDescription(ContextOfChains, "UninvoicedReceipt", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "UninvoicedReceipt", "BalanceOfPayments", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "UninvoicedReceipt", "Payment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "UninvoicedReceipt", "ReturnOfGoods", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "UninvoicedReceipt", "ReverseOfReceipt", ConsumptionFields);
	
	AddReceiverDescription(ContextOfChains, "PaymentReversal", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "BalanceOfPayments", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "Payment", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "ReturnOfGoods", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "PaymentReversal", "ReverseOfReceipt", ConsumptionFields); // refund of payment from the supplier
	
	AddReceiverDescription(ContextOfChains, "ReturnOfGoods", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "ReturnOfGoods", "BalanceOfReceipts", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "ReturnOfGoods", "UninvoicedReceipt", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "ReturnOfGoods", "BalanceOfReceipts", ConsumptionFields);
	AddSourceDescription(ContextOfChains, "ReturnOfGoods", "PaymentReversal", ConsumptionFields);
	
	AddReceiverDescription(ContextOfChains, "ReverseOfReceipt", "AccountingDimensionByPartners, PurchaseOrder, Currency, DocumentInflow");
	AddSourceDescription(ContextOfChains, "ReverseOfReceipt", "BalanceOfReceipts", "AccountingDimensionByPartners, PurchaseOrder, Currency, DocumentInflow");
	AddSourceDescription(ContextOfChains, "ReverseOfReceipt", "PastAdmission", "AccountingDimensionByPartners, PurchaseOrder, Currency, DocumentInflow");
	AddSourceDescription(ContextOfChains, "ReverseOfReceipt", "UninvoicedReceipt", "AccountingDimensionByPartners, PurchaseOrder, Currency, DocumentInflow");
	
	ChainsOfRegisteredRecords = ChainsOfRegisteredRecordsFromSample(ContextOfChains, DataForCalculation);
	CalculateBatchesByChainsFromSample(ContextOfRegisteredRecords, DataForCalculation, SettlementBatches, ChainsOfRegisteredRecords, Recorders, Test, RecordsCount);
	
	// Step 4: Delete the lines that do not require writing to the database.
	DeleteUnwrittenLines(ContextOfRegisteredRecords.Context, SettlementBatches);
	
	// Step 5: Sorting batches for further recording
	SettlementBatches.Sort("Recorder, Priority", New CompareValues);
	Return SettlementBatches;
EndFunction

Function TextSettlementsWithSuppliersInitialization()
	Return "
		|SELECT DISTINCT
		|	Analysts.DimensionKey AS DimensionKey,
		|	Analysts.Organization   AS Organization,
		|	Analysts.Partner       AS Partner,
		|	Analysts.Counterparty    AS Counterparty,
		|	Analysts.Contract       AS Contract
		|INTO CalculationAnalysts
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS Analysts
		|WHERE
		|	(Analysts.DimensionKey IN (&CalculationAnalysts)
		|		OR &ForAllAnalysts)
		|;
		|///////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.Recorder                             AS Recorder,
		|	Calculations.AccountingDimensionByPartners               AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject                         AS PurchaseOrder,
		|	Calculations.Currency                                  AS Currency,
		|	ISNULL(Amounts.Currency, Calculations.Currency)          AS DocumentCurrency
		|INTO RegistrarsToCalculate
		|FROM (SELECT DISTINCT
		|		Calculations.Recorder               AS Recorder,
		|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		Calculations.ARAPObject           AS ARAPObject,
		|		Calculations.Currency                    AS Currency
		|	FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|		INNER JOIN CalculationAnalysts AS Analysts
		|			ON Calculations.AccountingDimensionByPartners = Analysts.DimensionKey
		|	WHERE
		|		Calculations.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND Calculations.Sum <> 0
		|
		|	UNION
		|
		|	SELECT DISTINCT
		|		CalculationsAccordingToDocuments.Recorder               AS Recorder,
		|		CalculationsAccordingToDocuments.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|		CalculationsAccordingToDocuments.PurchaseOrder           AS ARAPObject,
		|		CalculationsAccordingToDocuments.Currency                    AS Currency
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingByDocuments AS CalculationsAccordingToDocuments 
		|			INNER JOIN CalculationAnalysts AS Analysts
		|				ON CalculationsAccordingToDocuments.AccountingDimensionByPartners = Analysts.DimensionKey
		|	WHERE
		|		CalculationsAccordingToDocuments.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|		AND (CalculationsAccordingToDocuments.Debt <> 0 OR CalculationsAccordingToDocuments.Prepayment <> 0)
		|	) AS Calculations
		|
		|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
		|	ON Calculations.Recorder = Amounts.Recorder
		|		AND Calculations.ARAPObject = Amounts.ARAPObject
		|		AND Amounts.PaymentType_ IN (VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting), VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef))
		|		AND NOT Amounts.Recorder REFS Document.ARAPSettlement
		|;
		|///////////////////////////////////////
		|SELECT DISTINCT
		|	CAST(Calculations.Recorder AS Document.PurchaseAdjustment).DocumentBasis AS Recorder
		|INTO ReceiptDocuments
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|
		|	INNER JOIN CalculationAnalysts AS Analysts
		|	ON Calculations.AccountingDimensionByPartners = Analysts.DimensionKey
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND Calculations.Sum <> 0
		|	AND Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|;
		|///////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.Recorder AS Recorder,
		|	Calculations.ARAPDocument AS ARAPDocument,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	ReceiptDocuments.Recorder AS DocumentInflow
		|INTO PastReceipts
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
		|
		|	INNER JOIN ReceiptDocuments AS ReceiptDocuments
		|	ON Calculations.Recorder = ReceiptDocuments.Recorder
		|
		|	INNER JOIN CalculationAnalysts AS FilterByAnalysts
		|	ON Calculations.AccountingDimensionByPartners = FilterByAnalysts.DimensionKey
		|WHERE
		|	Calculations.Period < &BeginOfPeriod
		|	AND Calculations.ARAPDocument <> ReceiptDocuments.Recorder
		|;
		|////////////////////////////////////////
		|SELECT DISTINCT
		|	Calculations.Recorder               AS Recorder,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.ARAPObject            AS PurchaseOrder,
		|	Calculations.Currency                    AS Currency
		|INTO CurrentAnalytics
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|
		|	INNER JOIN RegistrarsToCalculate AS Recorders
		|	ON Calculations.Recorder = Recorders.Recorder
		|
		|	LEFT JOIN CalculationAnalysts AS ReadyForCalculation
		|	ON Calculations.AccountingDimensionByPartners = ReadyForCalculation.DimensionKey
		|WHERE
		|	ReadyForCalculation.DimensionKey IS NULL
		|	AND NOT Calculations.Recorder REFS Document.RegisterAdjustment
		|;
		|////////////////////////////////////////
		|SELECT DISTINCT
		|	DD.ARAPDocument AS Ref,
		|	MAX(Periodicals.Recorder) AS Recorder,
		|	MAX(CASE 
		|				WHEN Periodicals.ARAPDocument REFS Document.SourceDocument 
		|						THEN CAST(Periodicals.ARAPDocument AS Document.SourceDocument).Date 
		|					ELSE Periodicals.Period 
		|			END) AS Period
		|INTO LeftoversOnLIFO
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(&BeginOfPeriod) AS DD
		|	INNER JOIN AccumulationRegister.VendorsARAPAccountingByDocuments AS Periodicals
		|		ON Periodicals.Period < &BeginOfPeriod
		|		AND Periodicals.ARAPDocument = DD.ARAPDocument
		|WHERE
		|	DD.ARAPDocument <> UNDEFINED
		|	AND ((Periodicals.RecordType = VALUE(AccumulationRecordType.Expense) AND Periodicals.Debt > 0)
		|		OR (Periodicals.RecordType = VALUE(AccumulationRecordType.Receipt) AND Periodicals.Prepayment > 0)
		|	)
		|GROUP BY
		|	DD.ARAPDocument
		|;
		|////////////////////////////////////////
		|SELECT 
		|	AdjustingEntries.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	AdjustingEntries.PurchaseOrder           AS PurchaseOrder,
		|	AdjustingEntries.ARAPDocument         AS ARAPDocument,
		|	AdjustingEntries.Currency                    AS Currency,
		|	SUM(AdjustingEntries.ForReturn)          AS ForReturn,
		|	SUM(AdjustingEntries.Debt)               AS Debt,
		|	SUM(AdjustingEntries.ARAPMan)            AS ARAPMan,
		|	SUM(AdjustingEntries.DebtLocal)           AS DebtLocal,
		|	SUM(AdjustingEntries.Prepayment)         AS Prepayment,
		|	SUM(AdjustingEntries.PrepaymentMan)      AS PrepaymentMan,
		|	SUM(AdjustingEntries.PrepaymentLocal)     AS PrepaymentLocal,
		|	SUM(AdjustingEntries.DepositForPackage)        AS DepositForPackage,
		|	SUM(AdjustingEntries.DepositForPackageLocal)    AS DepositForPackageLocal
		|INTO TTAdjustmentsForDocuments
		|FROM	
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS AdjustingEntries
		|WHERE
		|	AdjustingEntries.Recorder REFS Document.RegisterAdjustment
		|	AND AdjustingEntries.Period BETWEEN  &BeginOfPeriod AND &PeriodEnding
		|	AND AdjustingEntries.Active
		|GROUP BY 
		|AdjustingEntries.AccountingDimensionByPartners,
		|AdjustingEntries.PurchaseOrder,
		|AdjustingEntries.ARAPDocument,
		|AdjustingEntries.Currency
		|;
		|////////////////////////////////////////
		|SELECT
		|	11 AS Priority,
		|	1 AS PriorityOfBillingObject,
		|	CASE WHEN DD.DebtBalance <> 0 
		|		THEN ""BalanceOfReceipts""
		|		ELSE ""BalanceOfPayments""
		|	END AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	ISNULL(Periodicals.Period, &BeginOfPeriod) AS Period,
		|	ISNULL(Periodicals.Recorder, DD.ARAPDocument) AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CASE WHEN DD.PurchaseOrder.Object = UNDEFINED
		|		THEN NULL
		|		ELSE DD.PurchaseOrder
		|	END AS PurchaseOrder,
		|	DD.ARAPDocument AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	CASE WHEN (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0) + DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0)) < 0
		|		THEN 0 - (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0) + DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0))
		|		ELSE (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0)  + DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0))
		|	END AS Sum,
		|	CASE WHEN DD.ForReturnBalance + ISNULL(AdjustingEntries.ForReturn,0) < 0
		|		THEN 0 - (DD.ForReturnBalance + ISNULL(AdjustingEntries.ForReturn,0))
		|		ELSE DD.ForReturnBalance + ISNULL(AdjustingEntries.ForReturn,0)
		|	END AS ForReturn,
		|	CASE WHEN DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0) < 0
		|		THEN 0 - (DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0))
		|		ELSE DD.DebtBalance + ISNULL(AdjustingEntries.Debt,0)
		|	END AS Debt,
		|	CASE WHEN DD.ARAPManBalance + ISNULL(AdjustingEntries.ARAPMan,0) < 0
		|		THEN 0 - (DD.ARAPManBalance + ISNULL(AdjustingEntries.ARAPMan,0))
		|		ELSE DD.ARAPManBalance + ISNULL(AdjustingEntries.ARAPMan,0)
		|	END AS ARAPMan,
		|	CASE WHEN DD.DebtLocalBalance + ISNULL(AdjustingEntries.DebtLocal,0) < 0
		|		THEN 0 - (DD.DebtLocalBalance + ISNULL(AdjustingEntries.DebtLocal,0))
		|		ELSE DD.DebtLocalBalance + ISNULL(AdjustingEntries.DebtLocal,0)
		|	END AS DebtLocal,
		|	CASE WHEN DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0) < 0
		|		THEN 0 - (DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0))
		|		ELSE DD.PrepaymentBalance + ISNULL(AdjustingEntries.Prepayment,0)
		|	END AS Prepayment,
		|	CASE WHEN DD.PrepaymentManBalance + ISNULL(AdjustingEntries.PrepaymentMan,0) < 0
		|		THEN 0 - (DD.PrepaymentManBalance + ISNULL(AdjustingEntries.PrepaymentMan,0))
		|		ELSE DD.PrepaymentManBalance + ISNULL(AdjustingEntries.PrepaymentMan,0)
		|	END AS PrepaymentMan,
		|	CASE WHEN DD.PrepaymentLocalBalance + ISNULL(AdjustingEntries.PrepaymentLocal,0) < 0
		|		THEN 0 - (DD.PrepaymentLocalBalance + ISNULL(AdjustingEntries.PrepaymentLocal,0))
		|		ELSE DD.PrepaymentLocalBalance + ISNULL(AdjustingEntries.PrepaymentLocal,0)
		|	END AS PrepaymentLocal,
		|	CASE WHEN DD.DepositForPackageBalance + ISNULL(AdjustingEntries.DepositForPackage,0) < 0
		|		THEN 0 - (DD.DepositForPackageBalance + ISNULL(AdjustingEntries.DepositForPackage,0))
		|		ELSE DD.DepositForPackageBalance + ISNULL(AdjustingEntries.DepositForPackage,0)
		|	END AS DepositForPackage,
		|	CASE WHEN DD.DepositForPackageLocalBalance + ISNULL(AdjustingEntries.DepositForPackageLocal,0)< 0
		|		THEN 0 - (DD.DepositForPackageLocalBalance + ISNULL(AdjustingEntries.DepositForPackageLocal,0))
		|		ELSE DD.DepositForPackageLocalBalance + ISNULL(AdjustingEntries.DepositForPackageLocal,0)
		|	END AS DepositForPackageLocal,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	VALUE(Catalog.CashFlowReportItems.EmptyRef) AS CashFlowItem,
		|	ISNULL(Periodicals.Recorder, DD.ARAPDocument) AS DocumentInflow,
		|	CASE WHEN ISNULL(Periodicals.Recorder, 0) = DD.ARAPDocument 
		|		THEN 1 
		|			ELSE 0 
		|	END AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|
		|INTO TTBalancesSettlementsWithSuppliers
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(&BeginOfPeriod) AS DD
		|
		|	INNER JOIN CalculationAnalysts AS Analysts
		|	ON DD.AccountingDimensionByPartners = Analysts.DimensionKey
		|
		|	LEFT JOIN LeftoversOnLIFO AS Periodicals
		|		ON Periodicals.Ref = DD.ARAPDocument
		|
		|	LEFT JOIN TTAdjustmentsForDocuments AS AdjustingEntries
		|		ON DD.AccountingDimensionByPartners = AdjustingEntries.AccountingDimensionByPartners
		|			AND DD.PurchaseOrder        = AdjustingEntries.PurchaseOrder
		|			AND DD.ARAPDocument      = AdjustingEntries.ARAPDocument
		|			AND DD.Currency                 = AdjustingEntries.Currency
		|";
EndFunction

Function TextDescriptionSettlementsWithSuppliers()
	Return "
		|SELECT TOP 0
		|	0 AS Priority,
		|	0 AS PriorityOfBillingObject,
		|	""XXXXXXXXXXXXXXXX"" AS EntryType,
		|	FALSE AS CalculationIsCompleted,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	DATETIME(1, 1, 1, 0, 0, 0) AS Period,
		|	DD.Recorder AS Recorder,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	DD.PurchaseOrder AS PurchaseOrder,
		|	DD.ARAPDocument AS ARAPDocument,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	0. AS Sum,
		|	0. AS ForReturn,
		|	0. AS Debt,
		|	0. AS ARAPMan,
		|	0. AS DebtLocal,
		|	0. AS Prepayment,
		|	0. AS PrepaymentMan,
		|	0. AS PrepaymentLocal,
		|	0. AS DepositForPackage,
		|	0. AS DepositForPackageLocal,
		|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
		|	VALUE(Catalog.CashFlowReportItems.EmptyRef) AS CashFlowItem,
		|	UNDEFINED AS DocumentInflow,
		|	UNDEFINED AS CalculationAtRateOfLocalDocument,
		|	UNDEFINED AS CalculationAtRateOfDocumentMan,
		|	0 AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS DD
		|";
EndFunction
	
Function TextOfSettlementsWithSuppliers()
	Return "
		|SELECT
		|	Balance.Priority AS Priority,
		|	Balance.PriorityOfBillingObject AS PriorityOfBillingObject,
		|	Balance.EntryType AS EntryType,
		|	Balance.CalculationIsCompleted AS CalculationIsCompleted,
		|	Balance.RecordType AS RecordType,
		|	Balance.Period AS Period,
		|	Balance.Recorder AS Recorder,
		|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Balance.PurchaseOrder AS PurchaseOrder,
		|	Balance.ARAPDocument AS ARAPDocument,
		|	Balance.Currency AS Currency,
		|	Balance.Sum AS Sum,
		|	Balance.ForReturn AS ForReturn,
		|	Balance.Debt AS Debt,
		|	Balance.ARAPMan AS ARAPMan,
		|	Balance.DebtLocal AS DebtLocal,
		|	Balance.Prepayment AS Prepayment,
		|	Balance.PrepaymentMan AS PrepaymentMan,
		|	Balance.PrepaymentLocal AS PrepaymentLocal,
		|	Balance.DepositForPackage AS DepositForPackage,
		|	Balance.DepositForPackageLocal AS DepositForPackageLocal,
		|	Balance.BusinessOperation AS BusinessOperation,
		|	Balance.CashFlowItem AS CashFlowItem,
		|	Balance.DocumentInflow AS DocumentInflow,
		|	CASE WHEN Balance.Currency = Balance.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ISNULL(MAX(Amounts.Currency), VALUE(Catalog.Currencies.EmptyRef)) = Balance.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR VALUETYPE(Balance.ARAPDocument) = TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfLocalDocument,
		|	CASE WHEN Balance.Currency = Balance.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ISNULL(MAX(Amounts.Currency), VALUE(Catalog.Currencies.EmptyRef)) = &CurrencyOfManAccounting
		|		OR VALUETYPE(Balance.ARAPDocument) = TYPE(Document.ARAPSettlement)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfDocumentMan,
		|	Balance.PriorityOfSettlementDocument AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|
		|FROM TTBalancesSettlementsWithSuppliers AS Balance
		|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
		|		ON Balance.Recorder = Amounts.Recorder
		|			AND Balance.PurchaseOrder = Amounts.ARAPObject
		|			AND VALUETYPE(Amounts.Recorder) <> TYPE(Document.ARAPSettlement)
		|
		|GROUP BY
		|	Balance.Priority,
		|	Balance.PriorityOfBillingObject,
		|	Balance.EntryType,
		|	Balance.CalculationIsCompleted,
		|	Balance.RecordType,
		|	Balance.Period,
		|	Balance.Recorder,
		|	Balance.AccountingDimensionByPartners,
		|	Balance.PurchaseOrder,
		|	Balance.ARAPDocument,
		|	Balance.Currency,
		|	Balance.Sum,
		|	Balance.ForReturn,
		|	Balance.Debt ,
		|	Balance.ARAPMan,
		|	Balance.DebtLocal,
		|	Balance.Prepayment,
		|	Balance.PrepaymentMan,
		|	Balance.PrepaymentLocal,
		|	Balance.DepositForPackage,
		|	Balance.DepositForPackageLocal,
		|	Balance.BusinessOperation,
		|	Balance.CashFlowItem,
		|	Balance.DocumentInflow,
		|	Balance.PriorityOfSettlementDocument
		|";
EndFunction
	
Function TextOfReceiptsFromPastPeriods()
	Return "
		|SELECT
		|	CASE WHEN DD.Recorder <> DD.ARAPDocument
		|		THEN 9
		|		ELSE 10
		|	END AS Priority,
		//
		|	1 AS PriorityOfBillingObject,
		//
		|	""PastAdmission"" AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	DD.RecordType AS RecordType,
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CASE WHEN DD.PurchaseOrder.Object = UNDEFINED
		|		THEN NULL
		|		ELSE DD.PurchaseOrder
		|	END AS PurchaseOrder,
		|	CASE WHEN DD.ARAPDocument = PastReceipts.DocumentInflow
		|		THEN DD.Recorder
		|		ELSE DD.ARAPDocument
		|	END AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	SUM(CASE WHEN (DD.Debt + DD.Prepayment) < 0
		|		THEN 0 - (DD.Debt + DD.Prepayment)
		|		ELSE (DD.Debt + DD.Prepayment)
		|	END) AS Sum,
		|	SUM(DD.ForReturn) AS ForReturn,
		|	SUM(CASE WHEN DD.ARAPDocument = DD.Recorder
		|			THEN DD.Debt
		|			ELSE 0
		|	END) AS Debt,
		|	SUM(CASE WHEN DD.ARAPDocument = DD.Recorder
		|			THEN DD.ARAPMan
		|			ELSE 0
		|	END) AS ARAPMan,
		|	SUM(CASE WHEN DD.ARAPDocument = DD.Recorder
		|			THEN DD.DebtLocal
		|			ELSE 0
		|	END) AS DebtLocal,
		|	SUM(CASE WHEN DD.ARAPDocument <> DD.Recorder AND DD.Debt <> 0
		|			THEN DD.Debt
		|			ELSE DD.Prepayment
		|	END) AS Prepayment,
		|	SUM(CASE WHEN DD.ARAPDocument <> DD.Recorder AND DD.ARAPMan <> 0
		|			THEN DD.ARAPMan
		|			ELSE DD.PrepaymentMan
		|	END) AS PrepaymentMan,
		|	SUM(CASE WHEN DD.ARAPDocument <> DD.Recorder AND DD.DebtLocal <> 0
		|			THEN DD.DebtLocal
		|			ELSE DD.PrepaymentLocal
		|	END) AS PrepaymentLocal,
		|	SUM(DD.DepositForPackage) AS DepositForPackage,
		|	SUM(DD.DepositForPackageLocal) AS DepositForPackageLocal,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	PastReceipts.DocumentInflow AS DocumentInflow,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR Amounts.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfLocalDocument,
		|	CASE WHEN DD.Currency = &CurrencyOfManAccounting
		|		OR Amounts.Currency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfDocumentMan,
		|	CASE WHEN DD.Recorder = DD.ARAPDocument 
		|		THEN 1
		|			ELSE 0 
		|	END AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS DD
		|
		|	INNER JOIN PastReceipts AS PastReceipts
		|	ON DD.Recorder = PastReceipts.Recorder
		|		AND DD.ARAPDocument = PastReceipts.ARAPDocument
		|		AND DD.AccountingDimensionByPartners = PastReceipts.AccountingDimensionByPartners
		|	LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
		|
		|	ON CASE WHEN DD.ARAPDocument = PastReceipts.DocumentInflow
		|				THEN DD.Recorder
		|			ELSE DD.ARAPDocument
		|		END = Amounts.Recorder
		|		AND DD.PurchaseOrder = Amounts.ARAPObject
		|		AND Amounts.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
		|GROUP BY
		|	DD.RecordType,
		|	DD.Period,
		|	DD.Recorder,
		|	DD.AccountingDimensionByPartners,
		|	DD.PurchaseOrder,
		|	DD.ARAPDocument,
		|	DD.Currency,
		|	DD.PaymentDate,
		|	DD.BusinessOperation,
		|	DD.CashFlowItem,
		|	DD.PaymentDate,
		|	PastReceipts.DocumentInflow,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR Amounts.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END,
		|	CASE WHEN DD.Currency = &CurrencyOfManAccounting
		|		OR Amounts.Currency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END
		|";
EndFunction

Function TextOfMovementOfSettlementsWithSuppliers()
	Return "
		|SELECT
		|	CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum >= 0 AND DD.AmountDue >= 0 AND DD.BeingPaid >= 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		THEN 10 // this is the reverse of the receipt
		|	WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue <= 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.AmountDue < 0
		|						AND DD.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.ARAPAdjustment),
		|							VALUE(Enum.BusinessTransactions.EmptyRef)))
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue < 0
		|						AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
		|		THEN 10 // this is a payment reversal
		|	WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0 // It's a duty
		|		THEN 11
		|	WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 // It's a duty
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.ARAPSettlement),
		|							VALUE(Enum.BusinessTransactions.ARWriteOff)))
		|		THEN 11
		|		ELSE 9
		|	END AS Priority,
		|	CASE WHEN DD.ARAPObject.Object REFS Document.BankAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.CashAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.SourceDocument
		|		OR DD.ARAPObject.Object REFS Document.PurchaseOrder
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|		OR DD.ARAPObject.Object REFS Catalog.CounterpartyContracts 
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN 1
		|		ELSE 2
		|	END AS PriorityOfBillingObject,
		|	CASE
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN ""UninvoicedReceipt""
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum >= 0 AND DD.AmountDue >= 0 AND DD.BeingPaid >= 0)
		|				AND NOT DD.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor),
		|					VALUE(Enum.BusinessTransactions.ARAPAdjustment))
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.ToReceive < 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum > 0 AND DD.AmountDue = 0 AND DD.BeingPaid = 0 
		|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor))
		|			THEN ""Payment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum >= 0 AND DD.AmountDue >= 0 AND DD.BeingPaid >= 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|			THEN ""ReverseOfReceipt""
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum > 0 AND DD.AmountDue > 0
		|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
		|				) OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.AmountDue = 0)
		|			THEN ""ReturnOfGoods""
		|		WHEN ((DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue <= 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.AmountDue < 0
		|					AND DD.BusinessOperation IN (
		|						VALUE(Enum.BusinessTransactions.ARAPAdjustment),
		|						VALUE(Enum.BusinessTransactions.EmptyRef))
		|					))
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue < 0
		|						AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
		|			THEN ""PaymentReversal""
		|	END AS EntryType,
		|	FALSE AS CalculationIsCompleted,
		|	CASE WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|				AND (DD.ToReceive < 0 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)))
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE DD.RecordType
		|	END AS RecordType,
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.ARAPObject  PurchaseOrder,
		|	CASE WHEN DD.ARAPDocument <> UNDEFINED
		|		THEN DD.ARAPDocument
		|		ELSE DD.Recorder
		|	END AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	SUM(
		|		CASE 
		|			WHEN DD.Sum < 0 AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|			THEN 0 - DD.Sum
		|			ELSE DD.Sum
		|		END
		|	) AS Sum,
		|	0. AS ForReturn,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			THEN DD.Sum
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.ARAPSettlement),
		|							VALUE(Enum.BusinessTransactions.DebtTransfer),
		|							VALUE(Enum.BusinessTransactions.ARWriteOff),
		|							VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
		|				))
		|			THEN DD.Sum
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
		|			THEN DD.Sum
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue < 0
		|				AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
		|			THEN DD.Sum
		|			ELSE 0
		|		END
		|	) AS Debt,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			THEN DD.SumMan
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.ARAPSettlement),
		|							VALUE(Enum.BusinessTransactions.ARWriteOff),
		|							VALUE(Enum.BusinessTransactions.DebtTransfer),
		|							VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
		|				))
		|			THEN DD.SumMan
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
		|			THEN DD.SumMan
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue < 0
		|				AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
		|			THEN DD.SumMan
		|			ELSE 0
		|		END
		|	) AS ARAPMan,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|			THEN DD.SumCompl
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.ARAPSettlement),
		|							VALUE(Enum.BusinessTransactions.DebtTransfer),
		|							VALUE(Enum.BusinessTransactions.ARWriteOff),
		|							VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
		|				))
		|			THEN DD.SumCompl
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany)
		|			THEN DD.SumCompl
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue < 0
		|				AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromVendor)
		|			THEN DD.SumCompl
		|			ELSE 0
		|		END
		|	) AS DebtLocal,
		|	SUM(
		|		CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum > 0
		|				THEN DD.Sum
		|			WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|						OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost)))
		|				THEN 0 - DD.Sum
		|			ELSE 0
		|		END
		|	) AS Prepayment,
		|	SUM(
		|		CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum > 0
		|				THEN DD.SumMan
		|			WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|						OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost)))
		|				THEN 0 - DD.SumMan
		|			ELSE 0
		|		END
		|	) AS PrepaymentMan,
		|	SUM(CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum > 0
		|				THEN DD.SumCompl
		|			WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|						OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost)))
		|				THEN 0 - DD.SumCompl
		|			ELSE 0
		|		END
		|	) AS PrepaymentLocal,
		|	SUM(DD.DepositForPackage) AS DepositForPackage,
		|	0. AS DepositForPackageLocal,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	CASE WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		AND DD.Recorder REFS Document.PurchaseAdjustment
		|			THEN CAST(DD.Recorder AS Document.PurchaseAdjustment).DocumentBasis
		|		ELSE DD.Recorder
		|	END AS DocumentInflow,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ToCalculation.DocumentCurrency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfLocalDocument,
		|	CASE WHEN ToCalculation.Currency = &CurrencyOfManAccounting
		|		OR ToCalculation.DocumentCurrency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS CalculationAtRateOfDocumentMan,
		|	0 AS PriorityOfSettlementDocument,
		|	DD.CorARAPObject AS CorARAPObject,
		|	DD.CorPartnerAccountingDimension AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS DD
		|
		|	INNER JOIN RegistrarsToCalculate AS ToCalculation
		|	ON DD.Recorder = ToCalculation.Recorder
		|		AND (DD.AccountingDimensionByPartners = ToCalculation.AccountingDimensionByPartners 
		|			OR ToCalculation.AccountingDimensionByPartners = VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef))
		|		AND DD.ARAPObject = ToCalculation.PurchaseOrder
		|		AND DD.Currency = ToCalculation.Currency
		|WHERE
		|	DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND DD.Sum <> 0 
		|	AND NOT DD.Recorder REFS Document.RegisterAdjustment
		|GROUP BY
		|	CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum >= 0 AND DD.AmountDue >= 0 AND DD.BeingPaid >= 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		THEN 10
		|	WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue <= 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.AmountDue < 0
		|					AND DD.BusinessOperation IN (
		|						VALUE(Enum.BusinessTransactions.ARAPAdjustment),
		|						VALUE(Enum.BusinessTransactions.EmptyRef)))
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue < 0
		|						AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
		|		THEN 10
		|	WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum > 0
		|		THEN 11
		|	WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0
		|					AND (DD.ToReceive < 0 OR DD.BusinessOperation IN (
		|							VALUE(Enum.BusinessTransactions.ARAPSettlement),
		|							VALUE(Enum.BusinessTransactions.ARWriteOff)))
		|		THEN 11
		|		ELSE 9
		|	END,
		|	CASE WHEN DD.ARAPObject.Object REFS Document.BankAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.CashAccountReceiptNote
		|		OR DD.ARAPObject.Object REFS Document.SourceDocument
		|		OR DD.ARAPObject.Object REFS Document.PurchaseOrder
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|		OR DD.ARAPObject.Object REFS Catalog.CounterpartyContracts 
		|			AND CAST(ARAPObject.Object AS Catalog.CounterpartyContracts).ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
		|			THEN 1
		|		ELSE 2
		|	END,
		|	CASE
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN ""UninvoicedReceipt""
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum >= 0 AND DD.AmountDue >= 0 AND DD.BeingPaid >= 0)
		|				AND NOT DD.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor),
		|					VALUE(Enum.BusinessTransactions.ARAPAdjustment))
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.ToReceive < 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum > 0 AND DD.AmountDue = 0 AND DD.BeingPaid = 0 
		|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor))
		|			THEN ""Payment""
		|		WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum >= 0 AND DD.AmountDue >= 0 AND DD.BeingPaid >= 0
		|			AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|			THEN ""ReverseOfReceipt""
		|		WHEN (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum > 0 AND DD.AmountDue > 0
		|					AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
		|				) OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.AmountDue = 0)
		|			THEN ""ReturnOfGoods""
		|		WHEN ((DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue <= 0)
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0 AND DD.AmountDue < 0
		|					AND DD.BusinessOperation IN (
		|						VALUE(Enum.BusinessTransactions.ARAPAdjustment),
		|						VALUE(Enum.BusinessTransactions.EmptyRef))
		|					))
		|				OR (DD.RecordType = VALUE(AccumulationRecordType.Receipt) AND DD.Sum < 0 AND DD.AmountDue < 0
		|						AND DD.BusinessOperation = VALUE(Enum.BusinessTransactions.RefundFromAnotherCompany))
		|			THEN ""PaymentReversal""
		|	END,
		|	DD.Period,
		|	DD.Recorder,
		|	CASE WHEN DD.ARAPDocument <> UNDEFINED
		|		THEN DD.ARAPDocument
		|		ELSE DD.Recorder
		|	END,
		|	CASE WHEN (DD.RecordType = VALUE(AccumulationRecordType.Expense) AND DD.Sum < 0
		|				AND (DD.ToReceive < 0 OR DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)))
		|		THEN VALUE(AccumulationRecordType.Receipt)
		|		ELSE DD.RecordType
		|	END,
		|	DD.AccountingDimensionByPartners,
		|	DD.ARAPObject,
		|	DD.Currency,
		|	DD.PaymentDate,
		|	DD.BusinessOperation,
		|	DD.CashFlowItem,
		|	DATETIME(1, 1, 1, 0, 0, 0),
		|	CASE WHEN DD.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
		|		AND DD.Recorder REFS Document.PurchaseAdjustment
		|			THEN CAST(DD.Recorder AS Document.PurchaseAdjustment).DocumentBasis
		|		ELSE DD.Recorder
		|	END,
		|	CASE WHEN DD.Currency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		OR ToCalculation.DocumentCurrency = DD.AccountingDimensionByPartners.Organization.LocalAccountingCurrency
		|		THEN TRUE
		|		ELSE FALSE
		|	END,
		|	CASE WHEN ToCalculation.Currency = &CurrencyOfManAccounting
		|		OR ToCalculation.DocumentCurrency = &CurrencyOfManAccounting
		|		THEN TRUE
		|		ELSE FALSE
		|	END,
		|	0,
		|	DD.CorARAPObject,
		|	DD.CorPartnerAccountingDimension
		|
		|UNION ALL
		|
		|SELECT
		|	10 AS Priority,
		//
		|	1 AS PriorityOfBillingObject,
		//
		|	""Relevant"" AS EntryType,
		|	TRUE AS CalculationIsCompleted,
		|	DD.RecordType AS RecordType,
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DD.PurchaseOrder AS PurchaseOrder,
		|	DD.ARAPDocument AS ARAPDocument,
		|	DD.Currency AS Currency,
		|	0. AS Sum,
		|	DD.ForReturn AS ForReturn,
		|	DD.Debt AS Debt,
		|	DD.ARAPMan AS ARAPMan,
		|	DD.DebtLocal AS DebtLocal,
		|	DD.Prepayment AS Prepayment,
		|	DD.PrepaymentMan AS PrepaymentMan,
		|	DD.PrepaymentLocal AS PrepaymentLocal,
		|	DD.DepositForPackage AS DepositForPackage,
		|	DD.DepositForPackageLocal AS DepositForPackageLocal,
		|	DD.BusinessOperation AS BusinessOperation,
		|	DD.CashFlowItem AS CashFlowItem,
		|	UNDEFINED AS DocumentInflow,
		|	FALSE AS CalculationAtRateOfLocalDocument,
		|	FALSE AS CalculationAtRateOfDocumentMan,
		|	0 AS PriorityOfSettlementDocument,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	UNDEFINED AS CorPartnerAccountingDimension
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS DD
		|
		|	INNER JOIN CurrentAnalytics AS CurrentAnalytics
		|	ON DD.Recorder = CurrentAnalytics.Recorder
		|		AND DD.AccountingDimensionByPartners = CurrentAnalytics.AccountingDimensionByPartners
		|		AND DD.PurchaseOrder = CurrentAnalytics.PurchaseOrder
		|		AND DD.Currency = CurrentAnalytics.Currency
		|";
EndFunction

#EndRegion

// Contextual methods of filling in the calculation document for the expense line and the receipt line.
#Region FillInCalculationDocument

// Used FOR all calls to fill in the billing batch
Procedure FillInSettlementBatch(Context, SettlementBatch, Expense, Receipt, Currencies, SettlementBatches)
	If Context = "CustomersARAPAccounting" Then
		FillOutSettlementsWithCustomers(SettlementBatch, Expense, Receipt, Currencies, SettlementBatches);
	ElsIf Context = "VendorsARAPAccounting" Then
		FillOutSettlementsWithSuppliers(SettlementBatch, Expense, Receipt, Currencies, SettlementBatches);
	EndIf;
EndProcedure

Procedure FillOutSettlementsWithCustomers(SettlementBatch, Expense, Receipt, Currencies, SettlementBatches) // CustomersARAPAccountingByDocuments
	FillPropertyValues(SettlementBatch, Expense);
	TypesOfResidueInput = OBEntryServer.AvailableTypesOfResidueInput();
	If Undefined = Receipt // the balances on payment and shipment should not "close" on each other
		Or (TypesOfResidueInput.Find(TypeOf(Expense.Recorder)) <> Undefined
				And TypesOfResidueInput.Find(TypeOf(Receipt.Recorder)) <> Undefined)
		Or (Expense.EntryType = "Shipment" And Receipt.Debt <> 0) // Shipment is closed only for prepayment
		Or (Expense.EntryType = "PaymentReversal" And Receipt.Prepayment = 0) // The payment reverse is closed only for prepayment
		Or (Expense.EntryType = "Payment" And Receipt.Prepayment <> 0) // Payment is closed only for debt
	Then
		Return;
	EndIf;
	
	DebitedAmount = Min(Expense.Sum, Receipt.Sum);
	
	ConsumptionBasis = ?(Expense.Sum <> 0, DebitedAmount / Expense.Sum, 0);
	ParishBasis = ?(Receipt.Sum <> 0, DebitedAmount / Receipt.Sum, 0);
	
	CourseOfManSDebtOfSpendingParty  = ?(Expense.Debt <> 0, Expense.ARAPMan / Expense.Debt, 0);
	LocalDebtRateOfSpendingParty = ?(Expense.Debt <> 0, Expense.DebtLocal / Expense.Debt, 0);
	
	// we fill in the indicators of the settlement batch
	SettlementBatch.Sum = Round(ParishBasis * Receipt.Sum, 2);
	SettlementBatch.ForReturn = Round(ParishBasis * Receipt.ForReturn, 2);
	If Expense.EntryType = "Shipment"
		Or Expense.EntryType = "StornoShipment"
		Or Expense.EntryType = "ReturnOfGoods"
	Then
		SettlementBatch.DepositForPackage = Round(ParishBasis * Receipt.DepositForPackage, 2);
	Else
		SettlementBatch.DepositForPackage = 0;
	EndIf;
	SettlementBatch.Prepayment = Round(ParishBasis * Receipt.Prepayment, 2);
	If SettlementBatch.Prepayment = 0 Then
		SettlementBatch.PrepaymentMan = 0;
		SettlementBatch.PrepaymentLocal = 0;
	Else
		If Expense.CalculationAtRateOfLocalDocument And (TypeOf(Expense.Recorder) = Type("DocumentRef.BankAccountIssue")
			Or TypeOf(Expense.Recorder) = Type("DocumentRef.CashVoucher")) Then
			SettlementBatch.PrepaymentLocal = Min(Receipt.PrepaymentLocal, ?(Expense.DebtLocal=0,Expense.PrepaymentLocal, Expense.DebtLocal));
		ElsIf Expense.Debt <> 0 And TypeOf(Expense.Recorder) = Type("DocumentRef.ARAPSettlement") Then
			SettlementBatch.PrepaymentLocal = Round(ConsumptionBasis * Expense.DebtLocal, 2);
		Else
			SettlementBatch.PrepaymentLocal = Round(ParishBasis * Receipt.PrepaymentLocal, 2);
		EndIf;
		
		If Expense.CalculationAtRateOfDocumentMan And (TypeOf(Expense.Recorder) = Type("DocumentRef.BankAccountIssue")
			Or TypeOf(Expense.Recorder) = Type("DocumentRef.CashVoucher")) Then
			SettlementBatch.PrepaymentMan = Min(Receipt.PrepaymentMan, ?(Expense.ARAPMan = 0, Expense.PrepaymentMan, Expense.ARAPMan));
		ElsIf Expense.Debt <> 0 And TypeOf(Expense.Recorder) = Type("DocumentRef.ARAPSettlement") Then
			SettlementBatch.PrepaymentMan = Round(ConsumptionBasis * Expense.ARAPMan, 2);
		Else
			SettlementBatch.PrepaymentMan = Round(ParishBasis * Receipt.PrepaymentMan, 2);
		EndIf;
		
	EndIf;
	SettlementBatch.Debt = Round(ParishBasis * Receipt.Debt, 2);
	If SettlementBatch.Debt <> 0 Then
		If Expense.EntryType = "Payment"
			Or Expense.EntryType = "StornoShipment"
			Or Expense.EntryType = "ReturnOfGoods"
		Then // the amounts of Upr and Regl are calculated according to the payment rate
			SettlementBatch.ARAPMan = Round(ConsumptionBasis * Expense.PrepaymentMan, 2);
			SettlementBatch.DebtLocal = Round(ConsumptionBasis * Expense.PrepaymentLocal, 2);
		Else
			SettlementBatch.ARAPMan = Round(ParishBasis * Receipt.ARAPMan, 2);
			SettlementBatch.DebtLocal = Round(ParishBasis * Receipt.DebtLocal, 2);
		EndIf;
		SettlementBatch.Priority = 12;
	Else
		SettlementBatch.ARAPMan = 0;
		SettlementBatch.DebtLocal = 0;
		SettlementBatch.Priority = 13;
	EndIf;
	
	// adjusting the calculation base in consumption
	Expense.Sum = Expense.Sum - Round(ConsumptionBasis * Expense.Sum, 2);
	Expense.ForReturn = Expense.ForReturn - Round(ConsumptionBasis * Expense.ForReturn, 2);
	Expense.DepositForPackage = Expense.DepositForPackage - Round(ConsumptionBasis * Expense.DepositForPackage, 2);
	Expense.Prepayment = Expense.Prepayment - Round(ConsumptionBasis * Expense.Prepayment, 2);
	If Expense.EntryType = "Payment"
		Or Expense.EntryType = "StornoShipment"
		Or Expense.EntryType = "ReturnOfGoods"
	Then
		If SettlementBatch.Debt <> 0 Then
			Expense.PrepaymentMan = Expense.PrepaymentMan - SettlementBatch.ARAPMan;
			Expense.PrepaymentLocal = Expense.PrepaymentLocal - SettlementBatch.DebtLocal;
		ElsIf SettlementBatch.Prepayment <> 0 Then
			Expense.PrepaymentMan = Expense.PrepaymentMan - SettlementBatch.PrepaymentMan;
			Expense.PrepaymentLocal = Expense.PrepaymentLocal - SettlementBatch.PrepaymentLocal;
		EndIf;
	Else
		Expense.PrepaymentMan = Expense.PrepaymentMan - Round(ConsumptionBasis * Expense.PrepaymentMan, 2);
		Expense.PrepaymentLocal = Expense.PrepaymentLocal - Round(ConsumptionBasis * Expense.PrepaymentLocal, 2);
	EndIf;
	Expense.Debt = Expense.Debt - Round(ConsumptionBasis * Expense.Debt, 2);
	
	// If the regl course is fixed in the document
	If Expense.CalculationAtRateOfLocalDocument And Not ValueIsFilled(Expense.CorARAPObject) Then
		Expense.DebtLocal = Max(0,Expense.DebtLocal - SettlementBatch.PrepaymentLocal); 
	// If there is a debt balance after the offset
	ElsIf Expense.Debt <> 0 And SettlementBatch.Prepayment <> 0 Then
		Expense.DebtLocal = Expense.Debt * LocalDebtRateOfSpendingParty;
	Else
		Expense.DebtLocal = Expense.DebtLocal - Round(ConsumptionBasis * Expense.DebtLocal, 2);
	EndIf;
	
	If Expense.CalculationAtRateOfDocumentMan And Not ValueIsFilled(Expense.CorARAPObject) Then
		Expense.ARAPMan = Max(0,Expense.ARAPMan - SettlementBatch.PrepaymentMan);
	ElsIf Expense.Debt <> 0 And SettlementBatch.Prepayment <> 0 Then
		Expense.ARAPMan = Expense.Debt * CourseOfManSDebtOfSpendingParty;
	Else
		Expense.ARAPMan = Expense.ARAPMan - Round(ConsumptionBasis * Expense.ARAPMan, 2);
	EndIf;
	
	Receipt.Sum = Receipt.Sum - SettlementBatch.Sum;
	Receipt.ForReturn = Receipt.ForReturn - SettlementBatch.ForReturn;
	Receipt.DepositForPackage = Receipt.DepositForPackage - SettlementBatch.DepositForPackage;
	If Expense.EntryType = "Payment"
		Or Expense.EntryType = "StornoShipment"
		Or Expense.EntryType = "ReturnOfGoods"
	Then
		Receipt.Debt = Receipt.Debt - Round(ParishBasis * Receipt.Debt, 2);
		Receipt.ARAPMan = Receipt.ARAPMan - Round(ParishBasis * Receipt.ARAPMan, 2);
		Receipt.DebtLocal = Receipt.DebtLocal - Round(ParishBasis * Receipt.DebtLocal, 2);
	Else
		Receipt.Debt = Receipt.Debt - SettlementBatch.Debt;
		Receipt.ARAPMan = Receipt.ARAPMan - SettlementBatch.ARAPMan;
		Receipt.DebtLocal = Receipt.DebtLocal - SettlementBatch.DebtLocal;
	EndIf;
	Receipt.Prepayment = Receipt.Prepayment - SettlementBatch.Prepayment;
	Receipt.PrepaymentMan = Receipt.PrepaymentMan - SettlementBatch.PrepaymentMan;
	Receipt.PrepaymentLocal = Receipt.PrepaymentLocal - SettlementBatch.PrepaymentLocal;
	
	SettlementBatch.CalculationIsCompleted = True;
	SettlementBatch.Priority = Receipt.Priority;
	ThisIsAdjustment = ?(TypeOf(Expense.Recorder) = Type("DocumentRef.SaleAdjustment"), True, False);
	If (ThisIsAdjustment And SettlementBatch.Debt <> 0 And Expense.RecordType = AccumulationRecordType.Receipt)
		Or (ThisIsAdjustment And SettlementBatch.Prepayment <> 0 And Expense.RecordType = AccumulationRecordType.Expense
			And Receipt.Recorder = Receipt.DocumentShipments) Then
		SettlementBatch.ARAPDocument = Expense.ARAPDocument; // for an advance payment, the settlement document will be an adjustment
	Else
		ThisIsReverseTransaction = ThisIsReverseTransaction(Expense.EntryType);
		ParishIsStorno = ThisIsReverseTransaction(Receipt.EntryType);
		If Receipt.Recorder = Undefined Or Receipt.EntryType = "BalanceOfPayments" Or Receipt.EntryType = "BalanceOfShipments" 
			Or (TypesOfResidueInput.Find(TypeOf(Receipt.Recorder)) <> Undefined)
			Or ThisIsReverseTransaction
			Or ParishIsStorno
			Or ThisIsAdjustment Then
			SettlementBatch.ARAPDocument = Receipt.ARAPDocument;
		Else
			SettlementBatch.ARAPDocument = Receipt.Recorder; // we keep the settlement document for the debt
		EndIf;
	EndIf;
	
	If SettlementBatch.DepositForPackage <> 0 Then
		FillOutDepositForTaraLocal(Currencies, SettlementBatch);
	EndIf;
EndProcedure

Procedure FillOutSettlementsWithSuppliers(SettlementBatch, Expense, Receipt, Currencies, SettlementBatches) // VendorsARAPAccountingByDocuments
	
	FillPropertyValues(SettlementBatch, Expense);
	TypesOfResidueInput = OBEntryServer.AvailableTypesOfResidueInput();
	If Undefined = Receipt 
		Or (TypesOfResidueInput.Find(TypeOf(Expense.Recorder)) <> Undefined // the balances on payment and shipment should not "close" on each other
				And TypesOfResidueInput.Find(TypeOf(Receipt.Recorder)) <> Undefined)
		Or (Expense.EntryType = "Payment" And Receipt.Prepayment <> 0) // Payment is closed only for debt
		Or (Expense.EntryType = "PaymentReversal" And Receipt.Prepayment = 0) // The payment reverse is closed only for prepayment
		Or (Expense.EntryType = "UninvoicedReceipt" And Receipt.Debt <> 0) // The receipt is closed only for prepayment
		Or (Expense.EntryType = "UninvoicedReceipt" And Receipt.EntryType = "ReverseOfReceipt" 
			And Expense.BusinessOperation = Receipt.BusinessOperation And Expense.Recorder <> Receipt.Recorder)
	Then
		Return;
	EndIf;
	
	DebitedAmount = Min(Expense.Sum, Receipt.Sum);
	
	ConsumptionBasis = ?(Expense.Sum <> 0, DebitedAmount / Expense.Sum, 0);
	ParishBasis = ?(Receipt.Sum <> 0, DebitedAmount / Receipt.Sum, 0);
	
	CourseOfManSDebtOfSpendingParty  = ?(Expense.Debt <> 0, Expense.ARAPMan / Expense.Debt, 0);
	LocalDebtRateOfSpendingParty = ?(Expense.Debt <> 0, Expense.DebtLocal / Expense.Debt, 0);
	
	// we fill in the indicators of the settlement batch
	SettlementBatch.Sum = Round(ParishBasis * Receipt.Sum, 2);
	SettlementBatch.ForReturn = Round(ParishBasis * Receipt.ForReturn, 2);
	If Expense.EntryType = "Inpayment"
		Or Expense.EntryType = "ReverseOfReceipt"
		Or Expense.EntryType = "ReturnOfGoods"
	Then
		SettlementBatch.DepositForPackage = Round(ParishBasis * Receipt.DepositForPackage, 2);
	Else
		SettlementBatch.DepositForPackage = 0;
	EndIf;
	SettlementBatch.Debt = Round(ParishBasis * Receipt.Debt, 2);
	SettlementBatch.Prepayment = Round(ParishBasis * Receipt.Prepayment, 2);
	
	If SettlementBatch.Prepayment = 0 Then
		SettlementBatch.PrepaymentMan = 0;
		SettlementBatch.PrepaymentLocal = 0;
		SettlementBatch.Priority = 12;
	Else
		If Expense.CalculationAtRateOfLocalDocument And (TypeOf(Expense.Recorder) = Type("DocumentRef.BankAccountReceiptNote")
			Or TypeOf(Expense.Recorder) = Type("DocumentRef.CashAccountReceiptNote")) Then
			SettlementBatch.PrepaymentLocal = Min(Receipt.PrepaymentLocal, ?(Expense.DebtLocal=0,Expense.PrepaymentLocal, Expense.DebtLocal));
		ElsIf Expense.Debt <> 0 And TypeOf(Expense.Recorder) = Type("DocumentRef.ARAPSettlement") Then
			SettlementBatch.PrepaymentLocal = Round(ConsumptionBasis * Expense.DebtLocal, 2);
		Else
			SettlementBatch.PrepaymentLocal = Round(ParishBasis * Receipt.PrepaymentLocal, 2);
		EndIf;
		If Expense.CalculationAtRateOfDocumentMan And (TypeOf(Expense.Recorder) = Type("DocumentRef.BankAccountReceiptNote")
			Or TypeOf(Expense.Recorder) = Type("DocumentRef.CashAccountReceiptNote")) Then
			SettlementBatch.PrepaymentMan = Min(Receipt.PrepaymentMan,?(Expense.ARAPMan=0,Expense.PrepaymentMan, Expense.ARAPMan));
		ElsIf Expense.Debt <> 0 And TypeOf(Expense.Recorder) = Type("DocumentRef.ARAPSettlement") Then
			SettlementBatch.PrepaymentMan = Round(ConsumptionBasis * Expense.ARAPMan, 2);
		Else
			SettlementBatch.PrepaymentMan = Round(ParishBasis * Receipt.PrepaymentMan, 2);;
		EndIf;
		SettlementBatch.Priority = 13;
	EndIf;
	If Expense.EntryType = "Payment"
		Or Expense.EntryType = "ReturnOfGoods" Then // the amounts of Upr and Regl are calculated according to the payment rate
		If SettlementBatch.Debt = 0 Then
			SettlementBatch.ARAPMan = 0;
			SettlementBatch.DebtLocal = 0;
		Else
			SettlementBatch.ARAPMan = Round(ConsumptionBasis * Expense.PrepaymentMan, 2);
			SettlementBatch.DebtLocal = Round(ConsumptionBasis * Expense.PrepaymentLocal, 2);
		EndIf;
	Else
		SettlementBatch.ARAPMan = Round(ParishBasis * Receipt.ARAPMan, 2);
		SettlementBatch.DebtLocal = Round(ParishBasis * Receipt.DebtLocal, 2);
	EndIf;
	
	// adjusting the calculation base in consumption
	Expense.Sum = Expense.Sum - Round(ConsumptionBasis * Expense.Sum, 2);
	Expense.ForReturn = Expense.ForReturn - Round(ConsumptionBasis * Expense.ForReturn, 2);
	Expense.DepositForPackage = Expense.DepositForPackage - Round(ConsumptionBasis * Expense.DepositForPackage, 2);
	Expense.Debt = Expense.Debt - Round(ConsumptionBasis * Expense.Debt, 2);
	If Expense.CalculationAtRateOfLocalDocument And Not ValueIsFilled(Expense.CorARAPObject) Then 
		Expense.DebtLocal = Max(0,Expense.DebtLocal - SettlementBatch.PrepaymentLocal);
	ElsIf Expense.Debt <> 0 And SettlementBatch.Prepayment <> 0 Then
		Expense.DebtLocal = Expense.Debt * LocalDebtRateOfSpendingParty; 
	Else
		Expense.DebtLocal = Expense.DebtLocal - Round(ConsumptionBasis * Expense.DebtLocal, 2);
	EndIf;
	If Expense.CalculationAtRateOfDocumentMan And Not ValueIsFilled(Expense.CorARAPObject) Then
		Expense.ARAPMan = Max(0,Expense.ARAPMan - SettlementBatch.PrepaymentMan);
	ElsIf Expense.Debt <> 0 And SettlementBatch.Prepayment <> 0 Then
		Expense.ARAPMan = Expense.Debt * CourseOfManSDebtOfSpendingParty; 
	Else
		Expense.ARAPMan = Expense.ARAPMan - Round(ConsumptionBasis * Expense.ARAPMan, 2);
	EndIf;
	Expense.Prepayment = Expense.Prepayment - Round(ConsumptionBasis * Expense.Prepayment, 2);
	If Expense.EntryType = "Payment" Then
		Expense.PrepaymentMan = Expense.PrepaymentMan - SettlementBatch.ARAPMan;
		Expense.PrepaymentLocal = Expense.PrepaymentLocal - SettlementBatch.DebtLocal;
	Else
		Expense.PrepaymentMan = Expense.PrepaymentMan - Round(ConsumptionBasis * Expense.PrepaymentMan, 2);
		Expense.PrepaymentLocal = Expense.PrepaymentLocal - Round(ConsumptionBasis * Expense.PrepaymentLocal, 2);
	EndIf;
	
	Receipt.Sum = Receipt.Sum - SettlementBatch.Sum;
	Receipt.ForReturn = Receipt.ForReturn - SettlementBatch.ForReturn;
	Receipt.DepositForPackage = Receipt.DepositForPackage - SettlementBatch.DepositForPackage;
	If Expense.EntryType = "Payment" Then
		Receipt.Debt = Receipt.Debt - Round(ParishBasis * Receipt.Debt, 2);
		Receipt.ARAPMan = Receipt.ARAPMan - Round(ParishBasis * Receipt.ARAPMan, 2);
		Receipt.DebtLocal = Receipt.DebtLocal - Round(ParishBasis * Receipt.DebtLocal, 2);
	Else
		Receipt.Debt = Receipt.Debt - SettlementBatch.Debt;
		Receipt.ARAPMan = Receipt.ARAPMan - SettlementBatch.ARAPMan;
		Receipt.DebtLocal = Receipt.DebtLocal - SettlementBatch.DebtLocal;
	EndIf;
	Receipt.Prepayment = Receipt.Prepayment - SettlementBatch.Prepayment;
	Receipt.PrepaymentMan = Receipt.PrepaymentMan - SettlementBatch.PrepaymentMan;
	Receipt.PrepaymentLocal = Receipt.PrepaymentLocal - SettlementBatch.PrepaymentLocal;
	
	ThisIsAdjustment = ?(TypeOf(Expense.Recorder) = Type("DocumentRef.PurchaseAdjustment"), True, False);
	ThisIsBalanceOnRefunds = Receipt.EntryType = "BalanceOfPayments" And TypeOf(Receipt.Recorder) = Type("DocumentRef.ReturnOfGoodsToVendor")
		And Receipt.Recorder <> Receipt.ARAPDocument;
	If (ThisIsAdjustment And SettlementBatch.Debt <> 0 And Expense.RecordType = AccumulationRecordType.Expense)
		Or (ThisIsAdjustment And SettlementBatch.Prepayment <> 0 And Expense.RecordType = AccumulationRecordType.Receipt
			And Receipt.Recorder = Receipt.DocumentInflow) Then
		SettlementBatch.ARAPDocument = Expense.ARAPDocument; // for an advance payment, the settlement document will be an adjustment
	Else
		ThisIsReverseTransaction = ThisIsReverseTransaction(Expense.EntryType);
		ParishIsStorno = ThisIsReverseTransaction(Receipt.EntryType);
		If Receipt.Recorder = Undefined
			Or (TypesOfResidueInput.Find(TypeOf(Receipt.Recorder)) <> Undefined)
			Or ThisIsReverseTransaction
			Or ParishIsStorno
			Or ThisIsBalanceOnRefunds
			Or Expense.BusinessOperation = Receipt.BusinessOperation
			Or Receipt.EntryType = "ReverseOfReceipt"
			Or Receipt.EntryType = "BalanceOfReceipts" 
				And ValueIsFilled(Receipt.PurchaseOrder)
				And Receipt.ARAPDocument = Receipt.PurchaseOrder.Object Then
			SettlementBatch.ARAPDocument = Receipt.ARAPDocument;
		Else
			SettlementBatch.ARAPDocument = Receipt.Recorder;
		EndIf;
	EndIf;
	
	SettlementBatch.CalculationIsCompleted = True;
	SettlementBatch.Priority = Receipt.Priority;
	If SettlementBatch.DepositForPackage <> 0 Then
		FillOutDepositForTaraLocal(Currencies, SettlementBatch);
	EndIf;
EndProcedure

#EndRegion

// General batch calculation algorithms
#Region GeneralCalculationMethods

Procedure DeleteUnwrittenLines(Context, SettlementBatches)
	
	DeletedTypes = New Structure;
	If Context = "CustomersARAPAccounting" Then
		DeletedTypes.Insert("BalanceOfPayments");
		DeletedTypes.Insert("BalanceOfShipments");
		DeletedTypes.Insert("PastShipment");
		DeleteIncompleteFiles = False;
	ElsIf Context = "VendorsARAPAccounting" Then
		DeletedTypes.Insert("BalanceOfPayments");
		DeletedTypes.Insert("BalanceOfReceipts");
		DeletedTypes.Insert("PastAdmission");
		DeleteIncompleteFiles = False;
	EndIf;
	
	MinimumIndex_ = 1 - SettlementBatches.Count();
	For IndexOf = MinimumIndex_ To 0 Do
		SettlementBatch = SettlementBatches[-IndexOf];
		If DeleteIncompleteFiles And SettlementBatch.CalculationIsCompleted <> True
			Or DeletedTypes.Property(SettlementBatch.EntryType)
		Then
			SettlementBatches.Delete(-IndexOf);
		EndIf;
	EndDo;
	
EndProcedure

Function Recorders(BeginOfPeriod, PeriodEnding, CalculationAnalysts, RegisterName, ArrayOfExcludedTypes = Undefined)
	QueryTemplate = "
		|SELECT DISTINCT
		|	DD.Recorder AS Recorder
		|FROM
		|	&CalculationRegisterTemplate AS DD
		|WHERE
		|	DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND DD.Sum <> 0
		|	AND NOT VALUETYPE(DD.Recorder) IN (&ArrayOfExcludedTypes)
		|	AND (DD.AccountingDimensionByPartners IN (&CalculationAnalysts) OR &ForAllAnalysts)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	DD.Recorder AS Recorder
		|FROM
		|	&RegisterTemplateForDocuments AS DD
		|WHERE
		|	DD.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND (DD.Debt <> 0 OR DD.Prepayment <> 0) 
		|	AND NOT VALUETYPE(DD.Recorder) IN (&ArrayOfExcludedTypes)
		|	AND (DD.AccountingDimensionByPartners IN (&CalculationAnalysts) OR &ForAllAnalysts)
		|";
	RegisterTemplate = "AccumulationRegister.";
	QueryText = StrReplace(QueryTemplate, "&CalculationRegisterTemplate", RegisterTemplate + RegisterName);
	If RegisterName = "CustomersARAPAccounting" Then
		QueryText = StrReplace(QueryText, "&RegisterTemplateForDocuments", RegisterTemplate + "CustomersARAPAccountingByDocuments");
	Else
		QueryText = StrReplace(QueryText, "&RegisterTemplateForDocuments", RegisterTemplate + "VendorsARAPAccountingByDocuments");
	EndIf;
	Recorders = New Map;
	If ArrayOfExcludedTypes = Undefined Then
		ArrayOfExcludedTypes = New Array;
	EndIf;
	Query = New Query(QueryText);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("ArrayOfExcludedTypes", ArrayOfExcludedTypes);
	Query.SetParameter("CalculationAnalysts", CalculationAnalysts);
	Query.SetParameter("ForAllAnalysts", CalculationAnalysts = Undefined);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Recorders.Insert(Selection.Recorder, True);
	EndDo;
	Return Recorders;
EndFunction

Procedure RecordCalculatedBatches(RegisterManager, SettlementBatches, Recorders)
	
	ChangesTable = GenerateTaxCalculationTasks(RegisterManager, SettlementBatches, Recorders);
	
	If Not SettlementBatches.Count() = 0 Then
		SettlementBatches.Sort("Recorder", New CompareValues);
		
		RegisterRecords = RegisterManager.CreateRecordSet();
		If Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
			RegisterRecords.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
		EndIf;
		
		Recorder = Undefined;
		Replace = True;
		Counter = 0;
		CounterMaximum = SettlementBatches.Count() - 1;
		While Counter <= CounterMaximum Do
			SettlementBatch = SettlementBatches[Counter];
			If Recorder <> SettlementBatch.Recorder Then
				Recorder = SettlementBatch.Recorder;
				
				RegisterRecords.Clear();
				RegisterRecords.Filter.Recorder.Set(Recorder);
				
				BeginTransaction();
				If Recorders <> Undefined Then
					If Recorders[Recorder] <> Undefined Then
						Replace = True;
						Recorders.Delete(Recorder);
					Else
						Replace = False;
					EndIf;
				EndIf;
			EndIf;

			Movement = RegisterRecords.Add();
			FillPropertyValues(Movement, SettlementBatch);
			Movement.Active = True;
			
			Counter = Counter + 1;
			If Counter > CounterMaximum Or (Recorder <> SettlementBatches[Counter].Recorder) Then
				RegisterRecords.Write(Replace);
				CommitTransaction();
			EndIf;
		EndDo;
	EndIf;
	
	If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		If RegisterManager = AccumulationRegisters.VendorsARAPAccountingByDocuments Then
			VATAccountingERP.ReflectChangesInSettlementsWithSuppliersInVATAccounting(ChangesTable);
		ElsIf RegisterManager = AccumulationRegisters.CustomersARAPAccountingByDocuments Then
			VATAccountingERP.ReflectChangesInSettlementsWithCustomersInVATAccounting(ChangesTable);
		EndIf;
	EndIf;
	#Region TasksForCalculationProvisionsForDoubtfulDebts
	
	NameOfChangeTable = "_ChangesTableCalculationsAccordingToDocuments";

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Period,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Document AS Document
	|INTO #ChangesTable
	|FROM
	|	&ChangesTable AS ChangesTable";
	
	Query.Text = StrReplace(Query.Text, "#ChangesTable", NameOfChangeTable);
	Query.SetParameter("ChangesTable", ChangesTable);
	Query.TempTablesManager = New TempTablesManager();
	Query.Execute();
	
	TaskSelection = AccrualAndWriteOffOfBadDebtAlowancesServer.SelectionOfTasksForEndOfMonthWhenCalculationsAreChanged(Query, NameOfChangeTable);
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, NameOfChangeTable);
	
	If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntriesBasedOnSampleData(TaskSelection);
	EndIf;
	
	#EndRegion
EndProcedure

Procedure GenerateRegisteredRecordsOnManagementAccounting(Context, SettlementDocuments)
	
	LoggersToReflection = SettlementDocuments.UnloadColumn("Recorder");
	FinancialAccountingPostingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInInternationalAccounting(SettlementDocuments);
	If Context = "CustomersARAPAccounting" Then
		ManagementAccountingPostingServer.GenerateCashFlowsCounterpartyToCustomers(LoggersToReflection);
	Else
		ManagementAccountingPostingServer.GenerateCashFlowsCounterpartyToSuppliers(LoggersToReflection);
	EndIf;
	ManagementAccountingPostingServer.GenerateRegisteredRecordsCounterpartyCounterparty(LoggersToReflection);
	If GetFunctionalOption("UseBalanceSheetStatement") Then
		ManagementAccountingPostingServer.UpdateMovementOfAssetsLiabilitiesOnSettlementsWithPartners(LoggersToReflection);
	EndIf;
	
EndProcedure

Procedure FillOutDepositForTaraLocal(Currencies, SettlementBatch)
	
	LocalCurrencyRatio = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
		SettlementBatch.AccountingDimensionByPartners.Organization.LocalAccountingCurrency,
		SettlementBatch.Period,
		Currencies.CurrencyExchangeRateCache);
		
	CoefficientOfCurrencyOfMutualSettlements = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
		SettlementBatch.Currency,
		SettlementBatch.Period,
		Currencies.CurrencyExchangeRateCache);
		
	If LocalCurrencyRatio <> 0 Then
		SettlementBatch.DepositForPackageLocal = SettlementBatch.DepositForPackage * CoefficientOfCurrencyOfMutualSettlements / LocalCurrencyRatio;
	EndIf;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Distribution of parishes for expenses

Function RegisterRecordsDetails(Context, CalculationFields, ComparisonKeys, Indicators, BasisOfArrival, BasisOfConsumption, ExpenseKey, OrderField_, SortFields = "", SortingByCondition = "")
	LongDesc = New Structure();
	LongDesc.Insert("Context", Context);
	LongDesc.Insert("CalculationFields", CalculationFields);
	LongDesc.Insert("ComparisonKeys", ComparisonKeys);
	LongDesc.Insert("Indicators", Indicators);
	LongDesc.Insert("BasisOfArrival", BasisOfArrival);
	LongDesc.Insert("BasisOfConsumption", BasisOfConsumption);
	LongDesc.Insert("ExpenseKey", ExpenseKey);
	LongDesc.Insert("OrderField_", OrderField_);
	LongDesc.Insert("SortFields", SortFields);
	LongDesc.Insert("SortingByCondition", SortingByCondition);
	
	Return LongDesc;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Building chains of movements for forwarding calculation documents

// Graph of comparison of indices of rows of flow and index row with the source of calculations.
// 
// Parameters:
// 	DescriptionOfChains - Structure - LongDesc
// 	SettlementBatches - QueryResultSelection - 
// Returns:
// 	Map - LongDesc
Function ChainsOfRegisteredRecordsFromSample(DescriptionOfChains, SettlementBatches)
	CalculationIndex = New Map;
	RecordTypes = New Map;
	
	Movement = SettlementBatches.Select();
	
	MovementKeys = New Array;
	// building an index of uncounted consumers
	LineNumber = -1;
	While Movement.Next() Do
		LineNumber = LineNumber + 1;
		If Movement.CalculationIsCompleted Then
			Continue;
		EndIf;
		
		MovementKeys.Clear();
		MovementKeys.Add(Movement.EntryType);
		For Each LinksField In DescriptionOfChains[Movement.EntryType].LinkFields Do
			MovementKeys.Add(Movement[LinksField]);
		EndDo;
		MovementKeys.Add(LineNumber);
		RecordTypes.Insert(LineNumber, Movement.EntryType);
		
		AddIndexNode(CalculationIndex, MovementKeys, LineNumber);
	EndDo;
	
	ChainsOfRegisteredRecords = New Map;
	
	// We are looking for index elements that can be receivers of the current movement data.
	Movement.Reset();
	LineNumber = -1;
	While Movement.Next() Do
		LineNumber = LineNumber + 1;
		ChainDescription = Undefined;
		If Not DescriptionOfChains.Property(Movement.EntryType, ChainDescription) Then
			Continue;
		EndIf;
		
		For Each ReceiverTypeDescription In ChainDescription.TypesOfReceivers Do
			Nodes = CalculationIndex[ReceiverTypeDescription.Key];
			If Nodes = Undefined Then
				Continue;
			EndIf;
			For Each SourceField In ReceiverTypeDescription.Value Do
				Nodes = Nodes[Movement[SourceField]];
				If Nodes = Undefined Then
					Break;
				EndIf;
			EndDo;
			If Nodes = Undefined Then
				Continue;
			EndIf;
			
			For Each Node In Nodes Do
				If ReceiverTypeDescription.Key = RecordTypes[Node.Key] Then // Comparing the type of record
					LinkChainNodes(ChainsOfRegisteredRecords, Node.Key, LineNumber);
				EndIf;
			EndDo;
		EndDo;
	EndDo;

	Return ChainsOfRegisteredRecords;
EndFunction

Function DescriptionOfChains(ListOfRecordTypes)
	DescriptionOfChains = New Structure(ListOfRecordTypes);
	For Each LongDesc In DescriptionOfChains Do
		DescriptionOfChains[LongDesc.Key] = New Structure("LinkFields, TypesOfReceivers");
		DescriptionOfChains[LongDesc.Key].LinkFields = New Array;
		DescriptionOfChains[LongDesc.Key].TypesOfReceivers = New Map;
	EndDo;
	Return DescriptionOfChains;
EndFunction

Procedure AddReceiverDescription(DescriptionOfChains, DestinationType, DestinationFields)
	For Each FieldDetails In New Structure(DestinationFields) Do
		LinkFields = DescriptionOfChains[DestinationType].LinkFields; //Array
		LinkFields.Add(FieldDetails.Key);
	EndDo;
EndProcedure

Procedure AddSourceDescription(DescriptionOfChains, DestinationType, SourceType, SourceFields)
	LinkFields = New Array;
	For Each FieldDetails In New Structure(SourceFields) Do
		LinkFields.Add(FieldDetails.Key);
	EndDo;
	DescriptionOfChains[SourceType].TypesOfReceivers.Insert(DestinationType, LinkFields);
EndProcedure

// The source is added to the receiver sources, and the receiver is added to the source receivers.
Procedure LinkChainNodes(ChainsOfRegisteredRecords, Receiver, Source, AfterSource = Undefined)
	// linking only different strings
	If Source = Receiver Then
		Return;
	EndIf;
	
	// The receiver is added to the mapping, sources are filled in for the receiver (a string with a false batch).
	If Undefined = ChainsOfRegisteredRecords[Receiver] Then
		ChainsOfRegisteredRecords.Insert(Receiver, New Structure("Sources, Destinations", New Array, New Array));
	EndIf;
	Sources = ChainsOfRegisteredRecords[Receiver].Sources;
	If AfterSource <> Undefined Then
		IndexOf = Sources.Find(AfterSource);
		If IndexOf <> Undefined Then
			Sources.Insert(IndexOf + 1, Source);
		EndIf;
	Else
		Sources.Add(Source);
	EndIf;
	
	// The source is added to the mapping, receivers are filled in for the source (a false batch line).
	If Undefined = ChainsOfRegisteredRecords[Source] Then
		ChainsOfRegisteredRecords.Insert(Source, New Structure("Sources, Destinations", New Array, New Array));
	EndIf;
	ChainsOfRegisteredRecords[Source].Destinations.Add(Receiver);
EndProcedure

// We expect that there will be less than a dozen sources and they will almost always be already ordered, so we sort by inserts.
Procedure SortSources(Sources, OrderField_, SettlementBatches)
	For Counter = 1 To Sources.UBound() Do
		If Undefined = SettlementBatches[Sources[Counter]] Then
			Continue;
		EndIf;
		Item = New Structure("Order, Source", SettlementBatches[Sources[Counter]][OrderField_], Sources[Counter]);
		PreviousIssue = Counter - 1;
		While PreviousIssue >= 0 Do
			If Undefined = SettlementBatches[Sources[PreviousIssue]] Then
				PreviousIssue = PreviousIssue - 1;
				Continue;
			EndIf;
			If SettlementBatches[Sources[PreviousIssue]][OrderField_] <= Item.Order Then
				Break;
			EndIf;
			Sources[PreviousIssue + 1] = Sources[PreviousIssue];
			PreviousIssue = PreviousIssue - 1;
		EndDo;
		Sources[PreviousIssue + 1] = Item.Source;
	EndDo;
EndProcedure

Procedure SortSourcesBySortFields(Sources, SortFields, Parishes, Var_SortDirection = "Desc")
	SortTable = New ValueTable;
	SortTable.Columns.Add("Key");
	SortingCondition = "";
	For Each SortField In SortFields Do
		SortingFieldParameters = StringFunctionsClientServer.SplitStringIntoWordArray(SortField, " ");
		SortTable.Columns.Add(SortingFieldParameters[0]);
		If ValueIsFilled(SortingCondition) Then
			SortingCondition = SortingCondition + ", ";
		EndIf;
		SortingCondition = SortingCondition + SortingFieldParameters[0] + " " + ?(SortingFieldParameters.Count() > 1, SortingFieldParameters[1], Var_SortDirection);
	EndDo;
	For Each Source In Sources Do
		ArrivalLine = Parishes.Get(Source);
		If ArrivalLine = Undefined Then
			Continue;
		EndIf;
		SortingLine = SortTable.Add();
		SortingLine.Key = Source;
		For Each SortField In SortFields Do
			SortingFieldParameters = StringFunctionsClientServer.SplitStringIntoWordArray(SortField, " ");
			SortingLine[SortingFieldParameters[0]] = ArrivalLine[SortingFieldParameters[0]];
		EndDo;
	EndDo;
	SortTable.Sort(SortingCondition);
	Sources = SortTable.UnloadColumn("Key");
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Calculation based on chains of movements and selections from the query result

Procedure CalculateBatchesByChainsFromSample(RegisterRecordsDetails, QueryResult, SettlementBatches, ChainsOfRegisteredRecords, Recorders,  Test = False, RecordsCount = 0)
	Parishes = New Map; // batch copy buffer to cover costs
	BatchLines = New Map; // buffer of uncalculated batches for calculation in the following iterations
	TraveledPath = New Map; // used to interrupt cycles
	
	Currencies = New Structure;
	Currencies.Insert("CurrencyExchangeRateCache", ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache());
	
	ExpenseIndex = -1;
	Selection = QueryResult.Select();
	DataTable = QueryResult.Unload();
	RecordsCount = Selection.Count();
	MaxIndex_ = Selection.Count() + 1;
	While Selection.Next() Do
		ExpenseIndex = ExpenseIndex + 1;
		If ChainsOfRegisteredRecords[ExpenseIndex] = Undefined Then
			SettlementBatch = SettlementBatches.Add();
			FillPropertyValues(SettlementBatch, Selection);
			FillOutDepositForTaraLocal(Currencies, SettlementBatch);;
			Continue; // the line to the calculation is NOT registered
		ElsIf Selection.CalculationIsCompleted Then
			If ChainsOfRegisteredRecords[ExpenseIndex].Destinations.Count() > 0 Then
				Receipt = CopyOfRecording(Selection, RegisterRecordsDetails.CalculationFields);
				ThisIsReverseTransaction = ThisIsReverseTransaction(Receipt.EntryType);
				InvertMetrics(Receipt, RegisterRecordsDetails.Indicators, ThisIsReverseTransaction);
				Parishes.Insert(ExpenseIndex, Receipt);
			EndIf;
			SettlementBatch = SettlementBatches.Add();
			FillPropertyValues(SettlementBatch, Selection);
			FillOutDepositForTaraLocal(Currencies, SettlementBatch);
			Continue; // the string is the original batch
		EndIf;
		TraveledPath.Clear();
		SettlementBatch = CopyOfRecording(Selection, RegisterRecordsDetails.CalculationFields);
		CalculateBatchByChainFromSample(RegisterRecordsDetails, SettlementBatch, SettlementBatches, ChainsOfRegisteredRecords, Parishes, ExpenseIndex, TraveledPath, MaxIndex_, False, BatchLines, Currencies);
		
		// Let's write down a portion of the movements in the register.
		If SettlementBatches.Count() > 1000
			And (ExpenseIndex = RecordsCount - 1 
				Or (ExpenseIndex < RecordsCount - 1
					And DataTable[ExpenseIndex + 1].Recorder <> Selection.Recorder)) Then
			DeleteUnwrittenLines(RegisterRecordsDetails.Context, SettlementBatches);
			If RegisterRecordsDetails.Context = "CustomersARAPAccounting" Then
				RecordCalculatedBatches(AccumulationRegisters.CustomersARAPAccountingByDocuments, SettlementBatches, Recorders);
			ElsIf RegisterRecordsDetails.Context = "VendorsARAPAccounting" Then
				RecordCalculatedBatches(AccumulationRegisters.VendorsARAPAccountingByDocuments, SettlementBatches, Recorders);
			EndIf;
			If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
				LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(SettlementBatches);
			EndIf;
			LoggersToReflection = SettlementBatches.UnloadColumn("Recorder");
			GenerateRegisteredRecordsOnManagementAccounting(RegisterRecordsDetails.Context, SettlementBatches);
			InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateAccordingToMutualSettlements(RegisterRecordsDetails.Context, LoggersToReflection);
			SettlementBatches.Clear();
		EndIf;
	EndDo;
	
	Counter = 0;
	While Counter < MaxIndex_ Do
		ExpenseIndex = Counter;
		Counter = Counter + 1;
		If BatchLines[ExpenseIndex] = Undefined Then
			Continue; // the line to the calculation is NOT registered
		EndIf;
		TraveledPath.Clear();
		SettlementBatch = CopyOfRecording(BatchLines[ExpenseIndex], RegisterRecordsDetails.CalculationFields);
		CalculateBatchByChainFromSample(RegisterRecordsDetails, SettlementBatch, SettlementBatches, ChainsOfRegisteredRecords, Parishes, ExpenseIndex, TraveledPath, MaxIndex_, True, BatchLines, Currencies);
		
		// Let's write down a portion of the movements in the register.
		If SettlementBatches.Count() > 1000
			And (ExpenseIndex = MaxIndex_ 
				Or (ExpenseIndex < MaxIndex_
					And BatchLines[ExpenseIndex + 1].Recorder <> BatchLines[ExpenseIndex].Recorder)) Then
			DeleteUnwrittenLines(RegisterRecordsDetails.Context, SettlementBatches);
			If RegisterRecordsDetails.Context = "CustomersARAPAccounting" Then
				RecordCalculatedBatches(AccumulationRegisters.CustomersARAPAccountingByDocuments, SettlementBatches, Recorders);
			ElsIf RegisterRecordsDetails.Context = "VendorsARAPAccounting" Then
				RecordCalculatedBatches(AccumulationRegisters.VendorsARAPAccountingByDocuments, SettlementBatches, Recorders);
			EndIf;
			If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
				LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(SettlementBatches);
			EndIf;
			LoggersToReflection = SettlementBatches.UnloadColumn("Recorder");
			GenerateRegisteredRecordsOnManagementAccounting(RegisterRecordsDetails.Context, SettlementBatches);
			InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateAccordingToMutualSettlements(RegisterRecordsDetails.Context, LoggersToReflection);
			SettlementBatches.Clear();
		EndIf;
	EndDo;
	
	For Each String In BatchLines Do
		SettlementBatch = SettlementBatches.Add();
		FillPropertyValues(SettlementBatch, String.Value);
		FillOutDepositForTaraLocal(Currencies, SettlementBatch);
		If SettlementBatches.Count() > 1000 Then
			DeleteUnwrittenLines(RegisterRecordsDetails.Context, SettlementBatches);
			If RegisterRecordsDetails.Context = "CustomersARAPAccounting" Then
				RecordCalculatedBatches(AccumulationRegisters.CustomersARAPAccountingByDocuments, SettlementBatches, Recorders);
			ElsIf RegisterRecordsDetails.Context = "VendorsARAPAccounting" Then
				RecordCalculatedBatches(AccumulationRegisters.VendorsARAPAccountingByDocuments, SettlementBatches, Recorders);
			EndIf;
			If Not Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
				LocalAccntingServer.RegisterDocumentsOfSettlementsWithPartnersForReflectionInLocalAccounting(SettlementBatches);
			EndIf;
			LoggersToReflection = SettlementBatches.UnloadColumn("Recorder");
			GenerateRegisteredRecordsOnManagementAccounting(RegisterRecordsDetails.Context, SettlementBatches);
			InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateAccordingToMutualSettlements(RegisterRecordsDetails.Context, LoggersToReflection);
			SettlementBatches.Clear();
		EndIf;
	EndDo;
EndProcedure

Procedure CalculateBatchByChainFromSample(RegisterRecordsDetails, SettlementBatch, SettlementBatches, ChainsOfRegisteredRecords, Parishes, ExpenseIndex, TraveledPath, MaxIndex_, Iteration, BatchLines, Currencies)
	If ChainsOfRegisteredRecords[ExpenseIndex] = Undefined Then
		Return;
	EndIf;
	InvertedIndicators = False;
	Sources = ChainsOfRegisteredRecords[ExpenseIndex].Sources;
	Expense = CopyOfRecording(SettlementBatch, RegisterRecordsDetails.CalculationFields);
	If ExpenseIndex = TraveledPath[ExpenseIndex] Then
		Return; //have we been here before or are there no sources registered for this line
	EndIf;
	If Sources.Count() = 0 Then
		Expense.CalculationIsCompleted = True;
		Expense.ARAPDocument = Expense.Recorder;
		Expense.PriorityOfSettlementDocument = 1;
		
		NewBatch_ = SettlementBatches.Add();
		FillPropertyValues(NewBatch_, Expense);
		FillOutDepositForTaraLocal(Currencies, NewBatch_);
		
		Receipt = CopyOfRecording(NewBatch_, RegisterRecordsDetails.CalculationFields);
		ThisIsReverseTransaction = ThisIsReverseTransaction(Receipt.EntryType);
		InvertMetrics(Receipt, RegisterRecordsDetails.Indicators, ThisIsReverseTransaction);
		Parishes.Insert(ExpenseIndex, Receipt);
		Return;
	EndIf;
	
	TraveledPath.Insert(ExpenseIndex, ExpenseIndex);
	ThisIsReverseTransaction = ThisIsReverseTransaction(Expense.EntryType);
	
	FieldValues = StringFunctionsClientServer.SplitStringIntoWordArray(RegisterRecordsDetails.SortFields, ",");
	If ThisIsReverseTransaction And SortingIsRequired(Expense, ThisIsReverseTransaction) Then
		SortSourcesBySortFields(Sources, FieldValues, Parishes);
	ElsIf ThisIsReverseTransaction Then
		SortSourcesBySortFields(Sources, FieldValues, Parishes, "Asc");
	EndIf;
	
	If ThisIsReverseTransaction And Iteration Then
		For Each TheIndexOfTheSource In Sources Do
			If Undefined = Parishes[TheIndexOfTheSource] And BatchLines[TheIndexOfTheSource] <> Undefined Then // this source has not been calculated yet
				CalculateBatchByChainFromSample(RegisterRecordsDetails, BatchLines[TheIndexOfTheSource], SettlementBatches, ChainsOfRegisteredRecords, Parishes, TheIndexOfTheSource, TraveledPath, MaxIndex_, Iteration, BatchLines, Currencies);
			EndIf;
		EndDo;
		SortSources(Sources, RegisterRecordsDetails.OrderField_, Parishes);
	EndIf;
	
	Counter = 0;
	UBound = Sources.UBound();
	AvailableSources = New Array;
	CalculationIsCompleted = New Array;
	
	IndexOfSettlementBatch = -1;
	If ThisIsReverseTransaction And Expense[RegisterRecordsDetails.BasisOfConsumption] < 0 Then
		InvertMetrics(Expense, RegisterRecordsDetails.Indicators, ThisIsReverseTransaction);
		InvertedIndicators = True;
	EndIf;
	While Counter <= UBound Do
		TheIndexOfTheSource = Sources[Counter];
		Counter = Counter + 1;
		
		If Not ThisIsReverseTransaction And TheIndexOfTheSource = TraveledPath[TheIndexOfTheSource] Then
			AvailableSources.Add(TheIndexOfTheSource);
			Continue; // this source has not been fully calculated yet
		EndIf;
		
		Receipt = Parishes[TheIndexOfTheSource];
		If Undefined = Receipt Then
			If Not Iteration Or Undefined = BatchLines[TheIndexOfTheSource] Then
				AvailableSources.Add(TheIndexOfTheSource);
				Continue;
			EndIf;
			Source = BatchLines[TheIndexOfTheSource];
			If Not Source.CalculationIsCompleted Then
				CalculateBatchByChainFromSample(RegisterRecordsDetails, Source, SettlementBatches, ChainsOfRegisteredRecords, Parishes, TheIndexOfTheSource, TraveledPath, MaxIndex_, Iteration, BatchLines, Currencies);
				UBound = Sources.UBound();
				Receipt = Parishes[TheIndexOfTheSource];
				If Undefined = Receipt Then
					AvailableSources.Add(TheIndexOfTheSource);
					Continue;
				EndIf;
			EndIf;
		EndIf;
		
		ParishIsStorno = ThisIsReverseTransaction(Receipt.EntryType);
		If Receipt[RegisterRecordsDetails.BasisOfArrival] < 0. Then
			InvertMetrics(Receipt, RegisterRecordsDetails.Indicators, ParishIsStorno);
		EndIf;
		If Receipt[RegisterRecordsDetails.BasisOfArrival] = 0. Then
			Parishes.Delete(TheIndexOfTheSource);
			Continue;
		EndIf;
		
		FillInSettlementBatch(RegisterRecordsDetails.Context, SettlementBatch, Expense, Receipt, Currencies, SettlementBatches);
		If InvertedIndicators Then
			InvertMetrics(SettlementBatch, RegisterRecordsDetails.Indicators, ThisIsReverseTransaction);
		EndIf;
		
		If Receipt[RegisterRecordsDetails.BasisOfArrival] <= 0. Then
			Parishes.Delete(TheIndexOfTheSource);
		EndIf;
		If SettlementBatch.CalculationIsCompleted Then
			NewBatch_ = SettlementBatches.Add();
			If SettlementBatch.Recorder = SettlementBatch.ARAPDocument Then
				SettlementBatch.PriorityOfSettlementDocument = 1;
			EndIf;
			FillPropertyValues(NewBatch_, SettlementBatch);
			FillOutDepositForTaraLocal(Currencies, NewBatch_);
			
			CurrentIndex = ?(IndexOfSettlementBatch >= 0, IndexOfSettlementBatch, ExpenseIndex);
			CalculationIsCompleted.Add(CurrentIndex);
			If BatchLines[CurrentIndex] <> Undefined Then
				BatchLines.Delete(CurrentIndex);
			EndIf;
			Receipt = CopyOfRecording(NewBatch_, RegisterRecordsDetails.CalculationFields);
			ThisIsReverseTransaction = ThisIsReverseTransaction(Receipt.EntryType);
			InvertMetrics(Receipt, RegisterRecordsDetails.Indicators, ThisIsReverseTransaction);
			Parishes.Insert(CurrentIndex, Receipt);
			// Let's add a new batch line.
			If Expense[RegisterRecordsDetails.BasisOfConsumption] > 0. Then
				SettlementBatch = CopyOfRecording(Expense, RegisterRecordsDetails.CalculationFields);
				SettlementBatch.CalculationIsCompleted = False;
				SettlementBatch[RegisterRecordsDetails.OrderField_] = Date(1,1,1);
				IndexOfSettlementBatch = MaxIndex_;
				TraveledPath.Insert(IndexOfSettlementBatch, IndexOfSettlementBatch);
				MaxIndex_ = MaxIndex_ + 1;
				// the current source will also be the source for the new settlement batch
				For Each ReceiverIndex_ In ChainsOfRegisteredRecords[ExpenseIndex].Destinations Do
					If Not ChainsOfRegisteredRecords[ReceiverIndex_].Property("CalculationIsCompleted") Then
						LinkChainNodes(ChainsOfRegisteredRecords, ReceiverIndex_, IndexOfSettlementBatch, ExpenseIndex);
					EndIf;
				EndDo; // the receivers of the current flow received a new batch in the sources
			EndIf;
		EndIf;
		If Expense[RegisterRecordsDetails.BasisOfConsumption] <= 0. Then
			Break;
		EndIf;
	EndDo;
	If BatchLines[ExpenseIndex] <> Undefined Then
		BatchLines.Delete(ExpenseIndex);
	EndIf;
	If Expense[RegisterRecordsDetails.BasisOfConsumption] <> 0 
		Or Expense.DebtLocal <> 0
		Or Expense.ARAPMan <> 0 Then
		Expense.CalculationIsCompleted = True;
		NewBatch_ = SettlementBatches.Add();
		FillPropertyValues(NewBatch_, Expense);
		
		If NewBatch_.Recorder = NewBatch_.ARAPDocument Then
			NewBatch_.PriorityOfSettlementDocument = 1;
		EndIf;

		If Expense.EntryType <> "Shipment" Then
			NewBatch_.DepositForPackage = 0;
			NewBatch_.DepositForPackageLocal = 0;
		Else
			FillOutDepositForTaraLocal(Currencies, NewBatch_);
		EndIf;
		
		If InvertedIndicators Then
			InvertMetrics(NewBatch_, RegisterRecordsDetails.Indicators, ThisIsReverseTransaction);
		EndIf;
		
		If ValueIsFilled(Expense.CorARAPObject) Then
			TheStructureOfTheSearch = New Structure();
			TheStructureOfTheSearch.Insert("Recorder", Expense.Recorder);
			TheStructureOfTheSearch.Insert("AccountingDimensionByPartners", Expense.CorPartnerAccountingDimension);
			If RegisterRecordsDetails.Context = "CustomersARAPAccounting" Then
				TheStructureOfTheSearch.Insert("SalesOrder", Expense.CorARAPObject);
			Else
				TheStructureOfTheSearch.Insert("PurchaseOrder", Expense.CorARAPObject);
			EndIf;
			MovementStrings = SettlementBatches.FindRows(TheStructureOfTheSearch);
			If MovementStrings.Count() > 0 Then
				PrepaymentLocal = 0;
				PrepaymentMan = 0;
				For Each Page1 In MovementStrings Do
					PrepaymentLocal = PrepaymentLocal + Page1.PrepaymentLocal * ?(NewBatch_.Prepayment > 0 And Page1.PrepaymentLocal < 0,(-1),1);
					PrepaymentMan = PrepaymentMan + Page1.PrepaymentMan * ?(NewBatch_.Prepayment > 0 And Page1.PrepaymentLocal < 0,(-1),1);
				EndDo;
				NewBatch_.PrepaymentLocal = PrepaymentLocal;
				NewBatch_.PrepaymentMan = PrepaymentMan;
			EndIf;
		EndIf;
		
		CurrentIndex = ?(IndexOfSettlementBatch >= 0, IndexOfSettlementBatch, ExpenseIndex);
		
		Receipt = CopyOfRecording(NewBatch_, RegisterRecordsDetails.CalculationFields);
		ThisIsReverseTransaction = ThisIsReverseTransaction(Receipt.EntryType);
		InvertMetrics(Receipt, RegisterRecordsDetails.Indicators, ThisIsReverseTransaction);
		Parishes.Insert(CurrentIndex, Receipt);
		
		If IndexOfSettlementBatch >= 0 And AvailableSources.Count() > 0 Then
			For Each TheIndexOfTheSource In AvailableSources Do
				LinkChainNodes(ChainsOfRegisteredRecords, CurrentIndex, TheIndexOfTheSource);
			EndDo;
		EndIf;
	EndIf;
	For Each IndexOf In CalculationIsCompleted Do
		If ChainsOfRegisteredRecords[IndexOf] <> Undefined Then
			ChainsOfRegisteredRecords[IndexOf].Insert("CalculationIsCompleted", True);
		EndIf;
	EndDo;
EndProcedure

#EndRegion

#Region UtilityMethods

Function CopyOfRecording(Record, ListOfFields)
	CopyOfString = New Structure(ListOfFields);
	FillPropertyValues(CopyOfString, Record);
	Return CopyOfString;
EndFunction

Function ThisIsReverseTransaction(EntryType)
	If EntryType = "PaymentReversal" Or EntryType = "StornoShipment"
		Or EntryType = "ReverseOfReceipt" Or EntryType = "ReturnOfGoods"
	Then
		ThisIsReverseTransaction = True;
	Else
		ThisIsReverseTransaction = False;
	EndIf;
	Return ThisIsReverseTransaction;
EndFunction

Function SortingIsRequired(Record, ThisIsReverseTransaction)
	If (ThisIsReverseTransaction
			And Record.EntryType <> "ReturnOfGoods"
			And Record.BusinessOperation <> Enums.BusinessTransactions.ARAPSettlement)
		Or (Record.EntryType = "UninvoicedReceipt"
			And Record.BusinessOperation = Enums.BusinessTransactions.ARAPAdjustment)
		Or (ThisIsReverseTransaction
			And Record.EntryType = "ReturnOfGoods"
			And (Record.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor
				Or Record.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer))
	Then
		SortingIsRequired = True;
	Else
		SortingIsRequired = False;
	EndIf;
	Return SortingIsRequired;
EndFunction

Procedure InvertMetrics(Record, ListOfIndicators, Invert)
	If Not Invert Then
		Return;
	EndIf;
	For Each Field In New Structure(ListOfIndicators) Do
		Record[Field.Key] = -Record[Field.Key];
	EndDo;
EndProcedure

Function ListOfFields(ColumnCollection_)
	ListOfFields = "";
	For Each Column In ColumnCollection_ Do
		ListOfFields = ListOfFields + ?(ValueIsFilled(ListOfFields), ", ", "") + Column.Name;
	EndDo;
	Return ListOfFields;
EndFunction

Function AddIndexNode(IndexOf, IndexKeys, Value)
	UBound = IndexKeys.UBound();
	If UBound < 0 Or IndexKeys[0] = Undefined Then
		Return Undefined;
	EndIf;
	IndexNode = IndexOf;
	Counter = 0;
	While Counter < UBound Do
		IndexSubNode = IndexNode[IndexKeys[Counter]];
		If IndexSubNode = Undefined Then
			IndexSubNode = New Map;
			IndexNode.Insert(IndexKeys[Counter], IndexSubNode);
		EndIf;
		IndexNode = IndexSubNode;
		Counter = Counter + 1;
		If IndexKeys[Counter] = Undefined Then
			Return Undefined;
		EndIf;
	EndDo;
	IndexNode.Insert(IndexKeys[Counter], Value);
	Return Value;
EndFunction

Function GenerateTaxCalculationTasks(RegisterManager, Calculations, Recorders)
	
	ChangesTable = VATAccountingERP.NewCalculationChangeTable();
	
	ArrayOfLoggers = New Array;
	For Each Recorder In Recorders Do
		ArrayOfLoggers.Add(Recorder.Key);
	EndDo;
	
	If RegisterManager = AccumulationRegisters.VendorsARAPAccountingByDocuments Then
		QueryText = 
		"SELECT DISTINCT
		|	Calculations.Period                    AS Period,
		|	Calculations.Recorder               AS Recorder,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.PurchaseOrder           AS PurchaseOrder,
		|	Calculations.ARAPDocument         AS ARAPDocument,
		|	Calculations.DebtLocal                  AS DebtLocal,
		|	Calculations.PrepaymentLocal            AS PrepaymentLocal,
		|	Calculations.ARAPMan                   AS ARAPMan,
		|	Calculations.PrepaymentMan             AS PrepaymentMan
		|INTO SettlementsWithSuppliersOnDocumentsNewRegisteredRecords
		|FROM
		|	&Calculations AS Calculations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Calculations.Period                    AS Period,
		|	Calculations.Recorder               AS Recorder,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.PurchaseOrder           AS PurchaseOrder,
		|	Calculations.ARAPDocument         AS ARAPDocument,
		|	Calculations.DebtLocal                  AS DebtLocal,
		|	Calculations.PrepaymentLocal            AS PrepaymentLocal,
		|	Calculations.ARAPMan                   AS ARAPMan,
		|	Calculations.PrepaymentMan             AS PrepaymentMan
		|INTO SettlementsWithSuppliersOnDocumentsInitialRegisteredRecords
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
		|WHERE
		|	Calculations.Recorder IN (&Recorders)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.Period                    AS Period,
		|	Table.Recorder               AS Recorder,
		|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Table.PurchaseOrder           AS PurchaseOrder,
		|	Table.ARAPDocument         AS ARAPDocument
		|INTO SettlementsWithSuppliersBasedOnChangeDocuments
		|FROM
		|	(SELECT
		|		Calculations.Period                       AS Period,
		|		Calculations.Recorder                  AS Recorder,
		|		Calculations.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|		Calculations.PurchaseOrder              AS PurchaseOrder,
		|		Calculations.ARAPDocument            AS ARAPDocument,
		|
		|		Calculations.DebtLocal                     AS DebtLocal,
		|		Calculations.PrepaymentLocal               AS PrepaymentLocal,
		|		Calculations.ARAPMan                      AS ARAPMan,
		|		Calculations.PrepaymentMan                AS PrepaymentMan
		|
		|	FROM
		|		SettlementsWithSuppliersOnDocumentsInitialRegisteredRecords AS Calculations
		|		
		|	UNION ALL
		|		
		|	SELECT
		|		Calculations.Period                       AS Period,
		|		Calculations.Recorder                  AS Recorder,
		|		Calculations.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|		Calculations.PurchaseOrder              AS PurchaseOrder,
		|		Calculations.ARAPDocument            AS ARAPDocument,
		|
		|		-Calculations.DebtLocal                    AS DebtLocal,
		|		-Calculations.PrepaymentLocal              AS PrepaymentLocal,
		|		-Calculations.ARAPMan                     AS ARAPMan,
		|		-Calculations.PrepaymentMan               AS PrepaymentMan
		|
		|	FROM
		|		SettlementsWithSuppliersOnDocumentsNewRegisteredRecords AS Calculations
		|
		|	) AS Table
		|
		|GROUP BY
		|	Table.Recorder,
		|	Table.Period,
		|	Table.AccountingDimensionByPartners,
		|	Table.PurchaseOrder,
		|	Table.ARAPDocument
		|
		|HAVING
		|	SUM(Table.DebtLocal) <> 0 OR SUM(Table.PrepaymentLocal) <> 0
		|	OR SUM(Table.ARAPMan) <> 0 OR SUM(Table.PrepaymentMan) <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	BEGINOFPERIOD(Changes.Period, MONTH)          AS Period,
		|	Changes.Recorder                           AS Document,
		|	Changes.AccountingDimensionByPartners.Counterparty  AS Counterparty,
		|	Changes.AccountingDimensionByPartners.Organization AS Organization
		|FROM
		|	SettlementsWithSuppliersBasedOnChangeDocuments AS Changes
		|
		|UNION
		|
		|SELECT DISTINCT
		|	BEGINOFPERIOD(Changes.Period, MONTH)          AS Period,
		|	Changes.ARAPDocument                     AS Document,
		|	Changes.AccountingDimensionByPartners.Counterparty  AS Counterparty,
		|	Changes.AccountingDimensionByPartners.Organization AS Organization
		|FROM
		|	SettlementsWithSuppliersBasedOnChangeDocuments AS Changes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SettlementsWithSuppliersOnDocumentsInitialRegisteredRecords
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SettlementsWithSuppliersOnDocumentsNewRegisteredRecords";
		
		Query = New Query(QueryText);
		Query.SetParameter("Calculations", Calculations);
		Query.SetParameter("Recorders", Calculations.UnloadColumn("Recorder"));
		Query.TempTablesManager = New TempTablesManager;
		
		QueryResult = Query.ExecuteBatch();
		
		ChangesTable = QueryResult[3].Unload();
		
		// IMPORTANT!
		// With several calls to the procedure, there should not be a situation when one motion recorder is recorded
		// several times. If this is not observed, the tasks for calculating the transport tax will be generated incorrectly.
		NonCurrentAssets.CreateTasksWhenRecordingRegisteredRecordsAndPayments(Query.TempTablesManager);
		TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, "SettlementsWithSuppliersBasedOnChangeDocuments");

	ElsIf RegisterManager = AccumulationRegisters.CustomersARAPAccountingByDocuments Then
		
		QueryText = 
		"SELECT DISTINCT
		|	Calculations.Period                    AS Period,
		|	Calculations.Recorder               AS Recorder,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.SalesOrder              AS SalesOrder,
		|	Calculations.ARAPDocument         AS ARAPDocument,
		|	Calculations.DebtLocal                  AS DebtLocal,
		|	Calculations.PrepaymentLocal            AS PrepaymentLocal,
		|	Calculations.ARAPMan                   AS ARAPMan,
		|	Calculations.PrepaymentMan             AS PrepaymentMan
		|INTO SettlementsWithClientsOnDocumentsNewRegisteredRecords
		|FROM
		|	&Calculations AS Calculations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Calculations.Period                    AS Period,
		|	Calculations.Recorder               AS Recorder,
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Calculations.SalesOrder              AS SalesOrder,
		|	Calculations.ARAPDocument         AS ARAPDocument,
		|	Calculations.DebtLocal                  AS DebtLocal,
		|	Calculations.PrepaymentLocal            AS PrepaymentLocal,
		|	Calculations.ARAPMan                   AS ARAPMan,
		|	Calculations.PrepaymentMan             AS PrepaymentMan
		|INTO SettlementsWithClientsOnDocumentsInitialRegisteredRecords
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
		|WHERE
		|	Calculations.Recorder IN (&Recorders)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.Period                    AS Period,
		|	Table.Recorder               AS Recorder,
		|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Table.SalesOrder              AS SalesOrder,
		|	Table.ARAPDocument         AS ARAPDocument
		|INTO SettlementsWithClientsOnDocumentsChanges
		|FROM
		|	(SELECT
		|		Calculations.Period                       AS Period,
		|		Calculations.Recorder                  AS Recorder,
		|		Calculations.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|		Calculations.SalesOrder                 AS SalesOrder,
		|		Calculations.ARAPDocument            AS ARAPDocument,
		|
		|		Calculations.DebtLocal                     AS DebtLocal,
		|		Calculations.PrepaymentLocal               AS PrepaymentLocal,
		|		Calculations.ARAPMan                      AS ARAPMan,
		|		Calculations.PrepaymentMan                AS PrepaymentMan
		|
		|	FROM
		|		SettlementsWithClientsOnDocumentsInitialRegisteredRecords AS Calculations
		|		
		|	UNION ALL
		|		
		|	SELECT
		|		Calculations.Period                       AS Period,
		|		Calculations.Recorder                  AS Recorder,
		|		Calculations.AccountingDimensionByPartners    AS AccountingDimensionByPartners,
		|		Calculations.SalesOrder                 AS SalesOrder,
		|		Calculations.ARAPDocument            AS ARAPDocument,
		|
		|		-Calculations.DebtLocal                    AS DebtLocal,
		|		-Calculations.PrepaymentLocal              AS PrepaymentLocal,
		|		-Calculations.ARAPMan                     AS ARAPMan,
		|		-Calculations.PrepaymentMan               AS PrepaymentMan
		|
		|	FROM
		|		SettlementsWithClientsOnDocumentsNewRegisteredRecords AS Calculations
		|
		|	) AS Table
		|
		|GROUP BY
		|	Table.Period,
		|	Table.Recorder,
		|	Table.AccountingDimensionByPartners,
		|	Table.SalesOrder,
		|	Table.ARAPDocument
		|
		|HAVING
		|	SUM(Table.DebtLocal) <> 0 OR SUM(Table.PrepaymentLocal) <> 0
		|	OR SUM(Table.ARAPMan) <> 0 OR SUM(Table.PrepaymentMan) <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	BEGINOFPERIOD(Changes.Period, MONTH)          AS Period,
		|	Changes.ARAPDocument                     AS Document,
		|	Changes.AccountingDimensionByPartners.Counterparty  AS Counterparty,
		|	Changes.AccountingDimensionByPartners.Organization AS Organization
		|FROM
		|	SettlementsWithClientsOnDocumentsChanges AS Changes
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("Calculations", Calculations);
		Query.SetParameter("Recorders", ArrayOfLoggers);
		
		QueryResult = Query.ExecuteBatch();
		ChangesTable = QueryResult[3].Unload();
	EndIf;
	
	Return ChangesTable;
	
EndFunction

Procedure CheckBanDate(Period)
	
	DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
	TemplateRow = DataBanTemplate.Add();
	TemplateRow.Date   = Period;
	TemplateRow.Section = "RoutineOperations";
	
	If PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate) Then
	
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể khởi động phân bổ hạch toán công nợ trong %1 do đã đặt ngày cấm.
				           |Hãy đặt ngày cấm thay đổi trước %1 hoặc liên hệ với người sử dụng,
				           |có quyền thay đổi chứng từ trong phân hệ ""Kế toán tài chính"" và ""Kế toán quy định"" bắt đầu từ kỳ %1';
				           |ru = 'Не удалось запустить распределение взаиморасчетов за %1 из-за установленной даты запрета.
				           |Установите дату запрета изменений ранее, чем %1 или обратитесь к пользователю,
				           |имеющему право изменения документов подсистемы ""Финансовый учет"" и ""Регламентированный учет"" начиная с периода %1';
				           |en = 'Cannot start AR/AP allocation for %1 due to the set period-end closing date.
				           |Set the period-end closing date earlier than %1 or contact the user
				           |who has the right to edit documents of the ""Financial accounting"" and ""Local accounting"" subsystems starting from %1'; fa = 'Cannot start AR/AP allocation for %1 due to the set period-end closing date.
				           |Set the period-end closing date earlier than %1 or contact the user
				           |who has the right to edit documents of the ""Financial accounting"" and ""Local accounting"" subsystems starting from %1';
				           |it = 'Non è stato possibile avviare la ripartizione di pagamenti reciproci del %1 a causa della data di divieto impostata.
				           |Impostare la data di divieto delle modifiche antecedente al %1 o rivolgersi all''utente 
				           | avente diritto di modificare i documenti dei sottosistemi ""Contabilità finanziaria"" e ""Contabilità regolamentata"" a partire dal %1';
				           |pl = 'Nie udało się uruchomić przydzielenia rozliczeń wzajemnych za %1 z powodu ustawionej daty zakazu.
				           |Ustaw datę zakazu zmian wcześniej niż  %1 lub zwróć się do użytkownika,
				           |który ma prawo do zmiany podsystemu ""Ewidencja finansowa"" i ""Ewidencja reglamentowana"" zaczynając z okresu %1';
				           |tr = 'Ayarlanan yasak tarihi nedeniyle %1 için karşılıklı ödemelerin dağıtımını başlatmak mümkün olmadı.
				           |Değişiklik yasağı tarihini %1''den daha önce ayarlayın veya 
				           | döneminden başlayarak ""Finansal muhasebe"" ve ""Yerel muhasebe"" alt sisteminin belgelerini değiştirme hakkına sahip olan kullanıcıyla iletişime geçin %1'"),
				Format(Period,NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
									|ru = 'ДФ=''MMMM yyyy''';
									|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
									|it = 'ДФ=''ММММ гггг''';
									|pl = 'DF=''MMMM yyyy''';
									|tr = 'DF=''MMMM yyyy'''")));
				
		WriteLogEvent(NStr("vi = 'Đối trừ';
							|ru = 'Взаиморасчеты';
							|en = 'AR/AP accounting'; fa = 'حسابداری دریافتنی/پرداختنی';
							|it = 'Regolamenti reciproci';
							|pl = 'AR/AP accounting';
							|tr = 'Alacak/Borç muhasebesi'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , MessageText);
		
		Raise MessageText;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ClearingRegisterRegisteredRecords

Procedure ClearRegisterOnServer(Recorders, RegisterName)
	For Each Item In Recorders Do 
		BeginTransaction();
		Try
			RegisterRecords = AccumulationRegisters[RegisterName].CreateRecordSet(); // AccumulationRegisterRecordSet.CustomersARAPAccountingByDocuments
			RegisterRecords.Filter.Recorder.Set(Item.Key);
			RegisterRecords.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa đăng ký: %1 tại chứng từ: %2 do: %3';
					|ru = 'Не удалось очистить регистр: %1 у документа: %2 по причине: %3';
					|en = 'Cannot clear register: %1 in document: %2. Reason: %3'; fa = 'Cannot clear register: %1 in document: %2. Reason: %3';
					|it = 'Non è stato possibile formattare il registro:%1 del documento: %2 a causa di:%3';
					|pl = 'Nie udało się wyczyścić rejestr: %1 w dokumencie: %2 z powodu: %3';
					|tr = 'Kayıt: %1, belge: %2''de neden: %3 için temizlenemedi'"),
				RegisterName,
				Item.Key,
				DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(), 
				EventLogLevel.Warning,
				Item.Key.Metadata(),
				Item.Key,
				MessageText);
			Raise;
		EndTry;
	EndDo;
EndProcedure

Function TypesToExclude()
	TypesToExclude = New Array;
	TypesToExclude.Add(Type("DocumentRef.RegisterAdjustment"));
	Return TypesToExclude;
EndFunction

#EndRegion

// The method returns an array of analysis keys that will be used for calculation.
// Parameters:
//	FilterFields - Structure - Contains the values of the fields: organization, partner, and counterparty.
// Returns:
//	Array of CatalogRef.DimensionKeysOfAccountingByPartners - An array of partner analyst keys.
Function ArrayOfKeysForSelectionPartners(FilterFields) Export
	Organization = Undefined;
	Partner = Undefined;
	Counterparty = Undefined;
	Contract = Undefined;
	
	FilterFields.Property("Organization", Organization);
	FilterFields.Property("Partner", Partner);
	FilterFields.Property("Counterparty", Counterparty);
	FilterFields.Property("Contract", Contract);
	
	Query = New Query("
	|SELECT
	|	Keys.DimensionKey AS Key
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS Keys
	|WHERE
	|	(Keys.Organization IN (&Organization) OR &ByAllCompanies)
	|	AND (Keys.Partner IN (&Partner) OR &ForAllPartners)
	|	AND (Keys.Counterparty IN (&Counterparty) OR &ForAllCounterparties)
	|	AND (Keys.Contract IN (&Contract) OR &ByAllContracts)
	|");

	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(FilterFields.Organization));
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("ForAllPartners", Not ValueIsFilled(FilterFields.Partner));
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("ForAllCounterparties", Not ValueIsFilled(FilterFields.Counterparty));
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("ByAllContracts", Not ValueIsFilled(FilterFields.Contract));
	
	Result = Query.Execute().Unload();
	Return Result.UnloadColumn("Key");
EndFunction

#EndRegion