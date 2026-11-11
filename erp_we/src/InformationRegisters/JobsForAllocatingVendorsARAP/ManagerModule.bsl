#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
// This method displays a warning in a tabular document
// if the report is generated based on irrelevant data
// Parameters:
//	Template - SpreadsheetDocument - Layout where the warning is displayed
//	CalculationParameters - Structure - Properties which contain the data about the boundaries of the calculation.
Procedure DisplayRelevanceOfCalculation(Template, CalculationParameters) Export
	If  ValueIsFilled(CalculationParameters) And CalculationParameters.Property("BorderOfMutualSettlements") Then
		If ValueIsFilled(CalculationParameters.BorderOfMutualSettlements) Then
			WarningTable_ = New SpreadsheetDocument;
			AreaWarning = WarningTable_.Area(2,1,2,1);
			If Constants.UpdateARAPAccountingWhileGeneratingReports.Get() Then
				WarningText = NStr("vi = 'Đã phân bổ hạch toán đến %UpdateDate%. 
										|Đã khởi động nhiệm vụ phân bổ hạch toán từ %DistributionStartDate%. 
										|Sau khi phân bổ, chương trình sẽ đề xuất lập lại báo cáo.';
										|ru = 'Распределение расчетов выполнено до %UpdateDate%. 
										|Запущено задание по распределению расчетов с %DistributionStartDate%. 
										|После распределения Вам будет предложено переформировать отчет.';
										|en = 'Settlements are allocated up to %UpdateDate%.
										|Settlements allocation job runs from %DistributionStartDate%. 
										|After that, you will be prompted to rebuild the report.'; fa = 'Settlements are allocated up to %UpdateDate%.
										|Settlements allocation job runs from %DistributionStartDate%. 
										|After that, you will be prompted to rebuild the report.';
										|it = 'Settlements are allocated up to %UpdateDate%.
										|Settlements allocation job runs from %DistributionStartDate%. 
										|After that, you will be prompted to rebuild the report.';
										|pl = 'Settlements are allocated up to %UpdateDate%.
										|Settlements allocation job runs from %DistributionStartDate%. 
										|After that, you will be prompted to rebuild the report.';
										|tr = 'Hesaplamaların dağıtımı %UpdateDate% öncesinde gerçekleştirilmiştir. 
										|Hesaplamaların dağıtımı görevi %DistributionStartDate% tarihinden itibaren başlatılmıştır. 
										|Dağıtımdan sonra raporu yeniden biçimlendirmeniz istenecektir.'");
			Else
				WarningText = NStr("vi = 'Đã phân bổ hạch toán đến %UpdateDate%. 
										|Cần phục hồi hạch toán công nợ từ biểu mẫu đóng tháng (mục ""Tạo bản ghi kết chuyển hạch toán với bạn hàng (đối tác)"",
										|hoặc khởi động nhiệm vụ thường kỳ ""Thực hiện kết chuyển hoãn lại theo hạch toán với khách hàng\ nhà cung cấp"".';
										|ru = 'Распределение расчетов выполнено до %UpdateDate%. 
										|Необходимо восстановить взаиморасчеты из формы закрытия месяца (пункт ""Формирование движений по расчетам с партнерами (контрагентами)"",
										|либо запустить регламентное задание ""Выполнение отложенных движений по расчетам с клиентами\поставщиками"".';
										|en = 'AR/AP are allocated up to %UpdateDate%.
										|Restore AR/AP from the month-end closing form (the ""Generate records of AR/AP with partners (counterparties)"" item) 
										|or run the ""Execute deferred records of AR/AP with customers/vendors"" scheduled job.'; fa = 'AR/AP are allocated up to %UpdateDate%.
										|Restore AR/AP from the month-end closing form (the ""Generate records of AR/AP with partners (counterparties)"" item) 
										|or run the ""Execute deferred records of AR/AP with customers/vendors"" scheduled job.';
										|it = 'L''allocazione dei pagamenti è stata effettuata fino al %UpdateDate%. 
										|È necessario ripristinare i regolamenti dal modulo di chiusura di fine periodo (voce ""Generazione dei movimenti relativi ai regolamenti con partner (contraenti)"",
										|oppure avviare il task pianificato ""Esecuzione dei movimenti sospesi relativi ai regolamenti con clienti\fornitori"".';
										|pl = 'Rozkład obliczeń wykonywany jest dla%UpdateDate%. 
										|Konieczne jest przywrócenie wzajemnych rozliczeń z formularza zamknięcia miesiąca (pozycja „Tworzenie ruchów przy rozliczeniach z partnerami (kontrahentami)”,
										| lub rozpoczęcie zaplanowanego zadania „Realizacja odroczonych zmian w rozliczeniach z klientami\dostawcami”.';
										|tr = 'Mutabakatların dağıtımı %UpdateDate%''e kadar gerçekleştirilmiştir. 
										|Mutabakatların ay sonu kapanış formundan (""İş ortaklarıyla (cari hesaplarla)"" mutabakatlara ilişkin kayıt tabloların oluşturulması"" maddesi) geri yüklenmesi
										|veya ""Müşterilerle\ tedarikçilerle mutabakatlara ilişkin ertelenmiş kayıt tabloların yürütülmesi"" zamanlanmış görevin başlatılması gerekir.'");
			EndIf;
			UpdateDate = EndOfMonth(CalculationParameters.BorderOfMutualSettlements - 1);
			WarningText = StrReplace(WarningText,"%UpdateDate%", Format(UpdateDate, "DLF=D"));
			WarningText = StrReplace(WarningText,"%DistributionStartDate%", Format(CalculationParameters.BorderOfMutualSettlements, "DLF=D"));
			AreaWarning.Text = WarningText;
			AreaWarning.TextColor = StyleColors.NegativeTextColor;
			Template.InsertArea(AreaWarning, Template.Area(2,1,2,1), SpreadsheetDocumentShiftType.Vertical);
		Else
			CalculationParameters.Delete("BorderOfMutualSettlements");
			CalculationParameters.Delete("JobNumber");
		EndIf;
	EndIf;
EndProcedure

// The method returns the value of the "task Number" constant
// that was read during shared locking.
//
// Returns:
//	Number - The number of the current task from the constant "Number of the task for the distribution of payments with suppliers".
Function GetTaskNumber() Export
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForAllocatingVendorsARAPAccounting");
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
		JobNumber = Constants.NumberOfJobForAllocatingVendorsARAPAccounting.Get();
	
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(
			NStr("vi = 'Không thể phong tỏa hằng Số thứ tự nhiệm vụ cần phân bổ hạch toán với nhà cung cấp';
				|ru = 'Не удалось заблокировать константу Номер задания к распределению расчетов с поставщиками';
				|en = 'Cannot lock the ""Number of job for allocating vendor AR/AP"" constant'; fa = 'Cannot lock the ""Number of job for allocating vendor AR/AP"" constant';
				|it = 'Non è stato possibile bloccare la costante Numero del task per l''allocazione dei debiti contabili';
				|pl = 'Nie udało się zablokować liczbę stałą Numer zadania do podziału rozliczeń z dostawcami';
				|tr = 'Tedarikçilerle yapılan mutabakatların dağıtımı için sabit İş numarası engellenemedi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error);
		Raise;
	EndTry;
	
	Return JobNumber;
EndFunction

// This method creates a register entry for the specified period for all analysts for the month.
//
// Parameters:
//	TaskPeriod   - Date - The beginning of the period for which you need to register the task for calculation.
//	CompanyArray - Array of CatalogRef.Companies - organizations to register a task for
//
Procedure CreateRegisterEntry(TaskPeriod, CompanyArray = Undefined) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
		
	Query = New Query("
	|SELECT DISTINCT
	|	ToCalculation.Organization AS Organization,
	|	ToCalculation.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|FROM
	|	(SELECT DISTINCT
	|		Calculations.AccountingDimensionByPartners,
	|		Keys.Organization
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Keys
	|		ON Calculations.AccountingDimensionByPartners = Keys.Ref
	|	WHERE
	|		Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (&AllCompanies
	|			OR Keys.Organization IN (&CompanyArray))
	|		AND Calculations.Active
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		OfflineCalculations.AccountingDimensionByPartners,
	|		Keys.Organization
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS OfflineCalculations
	|		
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS Keys
	|		ON OfflineCalculations.AccountingDimensionByPartners = Keys.Ref
	|	WHERE
	|		OfflineCalculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND (&AllCompanies
	|			OR Keys.Organization IN (&CompanyArray))
	|		AND OfflineCalculations.Active
	|
	|	) AS ToCalculation
	|");
	
	Query.SetParameter("BeginOfPeriod", BegOfMonth(TaskPeriod));
	Query.SetParameter("EndOfPeriod", EndOfMonth(TaskPeriod));
	Query.SetParameter("AllCompanies", Not ValueIsFilled(CompanyArray));
	Query.SetParameter("CompanyArray", ?(ValueIsFilled(CompanyArray), CompanyArray, New Array));

	AnalystTable = Query.Execute().Unload();
	
	// Let's write down the tasks
	BeginTransaction();
	Try
		JobNumber = Constants.NumberOfJobForAllocatingVendorsARAPAccounting.Get();
		For Each CurAnalytics In AnalystTable Do
			RecordSet = InformationRegisters.JobsForAllocatingVendorsARAP.CreateRecordManager();
			RecordSet.Month = BegOfMonth(TaskPeriod);
			RecordSet.Organization = CurAnalytics.Organization;
			RecordSet.AccountingDimensionByPartners = CurAnalytics.AccountingDimensionByPartners;
			RecordSet.JobNumber = JobNumber;
			RecordSet.Write(True);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(
			NStr("vi = 'Không thể ghi nhiệm vụ để phân bổ hạch toán với các nhà cung cấp';
				|ru = 'Не удалось записать задания к распределению расчетов с поставщиками';
				|en = 'Cannot save jobs for allocating vendor AR/AP'; fa = 'Cannot save jobs for allocating vendor AR/AP';
				|it = 'Non è stato possibile registrare i task per l''allocazione dei debiti contabili';
				|pl = 'Nie udało się zapisać zadania do podziału rozliczeń z dostawcami';
				|tr = 'Tedarikçilerle yapılan mutabakatların dağıtımına ilişkin görevlerin kaydedilmemesi'", CommonClientServer.DefaultLanguageCode()
			), EventLogLevel.Error);
		Raise;
	EndTry
EndProcedure

// Adds descriptions of registers for connecting them to the no-change date mechanism.
//
Procedure DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources) Export
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName(),
										"Period",
										"RoutineOperations",
										"AccountingDimensionByPartners.Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments.FullName(),
										"Period",
										"RoutineOperations",
										"AccountingDimensionByPartners.Organization");
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS T1 
	|	ON T.AccountingDimensionByPartners = T1.DimensionKey
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T1.Organization)
	|	AND ValueAllowed(T1.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
