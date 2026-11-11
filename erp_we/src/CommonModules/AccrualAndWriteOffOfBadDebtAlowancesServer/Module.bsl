#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export

	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then

		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.LossAllowance);

	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then

		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.LossAllowance);

	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.LossAllowance);
	EndIf;

	Return Parameters;

EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export

	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map;

	RegisterMetadata = Metadata.AccumulationRegisters.LossAllowance;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(), DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;

	Return QueriesTexts;

EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map;
	MatchingQueryTexts.Insert("ChangesTableLossAllowance",
		AccumulationRegisters.LossAllowance.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;

EndFunction

// Procedure for forming movements in subordinate registers of reserves for doubtful debts.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export

	If Cancel Then
		Return;
	EndIf;

	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "LossAllowance");

EndProcedure

#EndRegion

#Region MonthEndTransactions
#Region ProcessingMonthClosingStages

// Adds the closing stage of the month For creating reserves for doubtful debts.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.InitializeStepDescriptionTable
// 	CurrentParent - String - group. to add a new stage to
//
Procedure AddStage_GenerateLossAllowance(StepsTable, CurrentParent) Export

	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.GenerateLossAllowance);
	
	NewRow.MultilingualName = "vi = 'Lập dự phòng theo công nợ khó đòi';
								|ru = 'Формирование резервов по сомнительным долгам';
								|en = 'Generate loss allowance';
								|it = 'Generare accantonamento per crediti di dubbia esigibilità';
								|pl = 'Tworzenie rezerw wg wątpliwych długów';
								|tr = 'Şüpheli borç rezervlerinin oluşturulması'"; // @NStr-1
	NewRow.PreviousStages_.Add(
		Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation);
	NewRow.TextExecute = NStr("vi = 'Lập báo cáo';
								|ru = 'Сформировать';
								|en = 'Generate'; fa = 'ایجاد';
								|it = 'Generare';
								|pl = 'Generate';
								|tr = 'Oluştur'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"AccrualAndWriteOffOfBadDebtAlowancesServer.Use_FormationOfProvisionsForDoubtfulDebts");
	NewRow.ActionExecute = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"AccrualAndWriteOffOfBadDebtAlowancesServer.Perform_FormationOfReservesForDoubtfulDebts");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.AccrualAndWriteOffOfBadDebtAlowances.Forms.ListForm.FullName());

EndProcedure

// Checking whether the month closing stage should be used.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler.
//
Procedure Use_FormationOfProvisionsForDoubtfulDebts(HandlerParameters) Export

	If MonthEndTransactionsServer.StageCalculationIsNotRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;

	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);

	Query.Text = RequestTextStateOfFormationOfProvisionsForDoubtfulDebts();

	Query.Execute();
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);

	If TemporaryTableSizes.Tt_OrganizationsWithReserves = 0 Then

		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters, NStr(
			"vi = 'Không có doanh nghiệp mà trong chính sách kế toán có sử dụng dự phòng';
			|ru = 'Нет организаций, для которых в учетной политике используется формирование резервов';
			|en = 'There are no companies for which the loss allowance generation is used in the accounting policy'; fa = 'There are no companies for which the loss allowance generation is used in the accounting policy';
			|it = 'Нет организаций, для которых в учетной политике используется формирование резервов';
			|pl = 'There are no companies for which the loss allowance generation is used in the accounting policy';
			|tr = 'Muhasebe politikasının rezerv oluşumunu kullandığı herhangi bir iş yeri yoktur'",
			Common.DefaultLanguageCode()));
	
	Else
		
		ThereIsScheduledJob = MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, True,
			"Tt_OrganizationsWithReserves");
		If TemporaryTableSizes.TT_OrganizationsWithoutDocument > 0 And (ThereIsScheduledJob Or TemporaryTableSizes.TT_OrganizationsPostedInPastPeriods > 0) Then

			TemporaryTableOfOrganizations = HandlerParameters.TempTablesManager.Tables.Find(
				"TT_OrganizationsWithoutDocument");
			If TemporaryTableOfOrganizations <> Undefined Then
				CompanyArray = TemporaryTableOfOrganizations.GetData().Unload().UnloadColumn("Organization");
				For Each Organization In CompanyArray Do

					MonthEndTransactionsServer.SetStateFailed(HandlerParameters, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Doanh nghiệp %1 không có chứng từ tính dự phòng nợ xấu trong %2';
						|ru = 'Для организации %1 нет документа начисления резервов по сомнительным долгам за %2';
						|en = 'The %1 company does not have a document that accrues loss allowance for %2'; fa = 'The %1 company does not have a document that accrues loss allowance for %2';
						|it = 'Per l''azienda %1 non esiste il documento di accredito riserve per crediti dubbi per %2';
						|pl = 'Dla firmy %1 nie ma dokumentów zaliczenia rezerw według wątpliwych długów za %2';
						|tr = '%1 iş yeri için, %2 için şüpheli borç karşılıklarının tahakkuk ettirilmesine ilişkin bir belge yok'"),
						Organization, CostCalculationProtocol.PresentationOfCalculationPeriod(
						HandlerParameters.CalculationParameters.EndOfPeriod)));
				EndDo;
			EndIf;
		ElsIf Not ThereIsScheduledJob And TemporaryTableSizes.TT_OrganizationsPostedInPastPeriods = 0 Then 
			MonthEndTransactionsServer.NoNeedToSetState(
				HandlerParameters, NStr(
				"vi = 'Trong tháng nhập số dư không cần lập dự phòng';
				|ru = 'В месяце ввода остатков формирование резервов не требуется';
				|en = 'Reserve generation is not required in the balance entry month'; fa = 'Reserve generation is not required in the balance entry month';
				|it = 'В месяце ввода остатков формирование резервов не требуется';
				|pl = 'Reserve generation is not required in the balance entry month';
				|tr = 'Bakiyelerin girildiği ayda karşılık ayrılması gerekmez'",
				Common.DefaultLanguageCode()));
		EndIf;
			
	EndIf;

	CompanyArray = HandlerParameters.CalculationParameters.CompanyArray;

	TemporaryTableOfOrganizations = HandlerParameters.TempTablesManager.Tables.Find("TT_OrganizationsToReflect");
	If Not TemporaryTableOfOrganizations = Undefined Then
		CompanyArray = TemporaryTableOfOrganizations.GetData().Unload().UnloadColumn("Organization");
	EndIf;

	MonthEndTransactionsServer.SetAdditionalHandlerProperty(HandlerParameters,
		"ArrayOfOrganizationsToReflect", CompanyArray);

EndProcedure

// The step of closing the month.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler.
//
Procedure PerformMonthClosingOfOperation(HandlerParameters) Export

	CalculationParameters = HandlerParameters.CalculationParameters;
	AdditionalProperties = HandlerParameters.Data_Stage.AdditionalProperties;

	BeginOfPeriod = MonthEndTransactionsServer.CalculationStart(HandlerParameters.Data_Stage.Code,
		CalculationParameters.EndOfPeriod, , CalculationParameters.CompanyArray);

	While BeginOfPeriod <= CalculationParameters.EndOfPeriod Do
		PeriodEnding = EndOfMonth(BeginOfPeriod);
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(BeginOfPeriod, CalculationParameters.CompanyArray);
		TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
		
		// Stage 1. Preparation of work with tasks.

		BeginTransaction();

		Try
			MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, AvailableCompanies,
				HandlerParameters.Data_Stage.Code);
			CalculationDataForMonth = MonthEndTransactionsServer.MonthlyTasks(BeginOfPeriod, PeriodEnding,
				TaskNumberBeforeCalculation, AvailableCompanies, HandlerParameters.Data_Stage.Code);

			CommitTransaction();
		Except
			RollbackTransaction();

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr(
					"vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));

			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(HandlerParameters, ErrorText,
				AvailableCompanies, BeginOfPeriod);
		EndTry;
		
		// Stage 2. The actual calculation by organizations and period.
		Try
			AccrualAndWriteOffOfBadDebtAlowancesLocalization.DeleteOldReservesAtCloseOfMonth(
				CalculationDataForMonth.Organization, BeginOfPeriod);
			UpdateDebtWriteOffRegisteredRecordsAgainstReserves(CalculationDataForMonth.Organization, BeginOfPeriod);
			GenerateReservesAtCloseOfMonth(CalculationDataForMonth.Organization, BeginOfPeriod);

			Documents.ExchangeDifferenceCalculation.RevaluationOfProvisionsForDoubtfulDebts(
					CalculationDataForMonth.Organization, BeginOfPeriod);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr(
					"vi = 'Đã thực hiện tạo dự phòng công nợ khó đòi trong kỳ %1 bị lỗi:
					|%2';
					|ru = 'Формирование резервов по сомнительным долгам за период %1 завершилось с ошибкой:
					|%2';
					|en = 'Generation of loss allowance for period %1 was completed with an error:
					|%2'; fa = 'Generation of loss allowance for period %1 was completed with an error:
					|%2';
					|it = 'Формирование резервов по сомнительным долгам за период %1 завершилось с ошибкой:
					|%2';
					|pl = 'Utworzenie rezerw na należności wątpliwe za okres %1 zakończony błędem:
					|%2';
					|tr = '%1 dönemi için şüpheli borç karşılığı oluşumu hatayla sonuçlandı:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));

			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(HandlerParameters, ErrorText,
				CalculationDataForMonth.Organization, BeginOfPeriod);
		EndTry;
		
		// Stage 3. Completion of work with tasks.

		MonthEndTransactionsServer.DeleteTasksToBeCalculatedForCurPeriod(HandlerParameters, CalculationDataForMonth);

		BeginOfPeriod = PeriodEnding + 1;
	EndDo;
	
	// Now we will find organizations that did not have tasks and there are no documents for the formation of reserves.
	// We will form additional documents for these organizations in the current period.

	ArrayOfOrganizationsToReflect = New Array;
	If AdditionalProperties.Property("ArrayOfOrganizationsToReflect") Then
		ArrayOfOrganizationsToReflect = AdditionalProperties.ArrayOfOrganizationsToReflect;
	EndIf;

	If Not ArrayOfOrganizationsToReflect.Count() = 0 Then
		
		// We remove from organizations to reflect those for which the tasks above were completed in the current month.
		If Not CalculationDataForMonth = Undefined Then
			For Each Organization In CalculationDataForMonth.Organization Do
				ReflectedOrganization = ArrayOfOrganizationsToReflect.Find(Organization);
				If ReflectedOrganization = Undefined Then
					Continue;
				EndIf;

				ArrayOfOrganizationsToReflect.Delete(ReflectedOrganization);
			EndDo;
		EndIf;
		
		// We form reserves for other organizations.
		AvailableCompanies = MonthEndTransactionsServer.CompaniesAvailableForSettlement(CalculationParameters.EndOfPeriod, CalculationParameters.CompanyArray);
		ArrayOfOrganizationsToReflect = TMCommonUseClientServer.IntersectionOfArrays(AvailableCompanies, ArrayOfOrganizationsToReflect);

		If Not ArrayOfOrganizationsToReflect.Count() = 0 Then
		
			AccrualAndWriteOffOfBadDebtAlowancesLocalization.DeleteOldReservesAtCloseOfMonth(
				ArrayOfOrganizationsToReflect, CalculationParameters.EndOfPeriod);
			UpdateDebtWriteOffRegisteredRecordsAgainstReserves(ArrayOfOrganizationsToReflect, BeginOfPeriod);
			GenerateReservesAtCloseOfMonth(ArrayOfOrganizationsToReflect, CalculationParameters.EndOfPeriod);

			Documents.ExchangeDifferenceCalculation.RevaluationOfProvisionsForDoubtfulDebts(
					ArrayOfOrganizationsToReflect, CalculationParameters.EndOfPeriod);
			
		EndIf;
		
	EndIf;

EndProcedure

// Completion of the month closing stage by organization.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler. 
//
Procedure Perform_FormationOfReservesForDoubtfulDebts(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	OrganizationsToCalculate_ = CalculationParameters.CompanyArray;
	NumberOfOrganizations = OrganizationsToCalculate_.Count();
	
	NumberOfFederalLaws = CalculationOfCostCached.ValuesOfTechnologicalParameters(Catalogs.MonthEndClosingOperations.EmptyRef()).MaximumNumberOfFederalLawsForFormationOfDocuments;
	OrganizationsBJ = Max(Int(NumberOfOrganizations / ?(NumberOfFederalLaws = 0, 1, NumberOfFederalLaws)), 1);

	If NumberOfFederalLaws <= 1 Then
		
		// Single-threaded document generation, without background tasks.
		AccrualAndWriteOffOfBadDebtAlowancesServer.PerformMonthClosingOfOperation(HandlerParameters);
		
		Return;
		
	EndIf;
	
	Processed        = 0;
	ArrayOfTasks     = New Array;
	CompanyArray = New Array;
	
	// Multithreaded document generation.
	While Processed <= NumberOfOrganizations Do
		
		If Processed = 0 Or Processed = NumberOfOrganizations
		 // The task is started by the number of organizations in the task equal to ORGANIZATIONSFZ.
		 // All remaining organizations are placed in the last task, even if there are more than ORGANIZATIONSFZ.
		 Or (Int(Processed/OrganizationsBJ) = Processed/OrganizationsBJ And ArrayOfTasks.Count() < NumberOfFederalLaws-1) Then
			
			If Processed > 0 Then

				// We are launching a new Federal law
				NewParametersOfHandler = Common.CopyRecursive(HandlerParameters, False);
				NewParametersOfHandler.CalculationParameters.CompanyArray = CompanyArray;
				
				ParametersArray = New Array;
				ParametersArray.Add(HandlerParameters);
				
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
					"AccrualAndWriteOffOfBadDebtAlowancesServer.PerformMonthClosingOfOperation",
					ParametersArray,
					JobKey,
					NStr("vi = 'Thực hiện giao dịch đa luồng';
						|ru = 'Многопоточное выполнение операции';
						|en = 'Multithreaded operation execution'; fa = 'Multithreaded operation execution';
						|it = 'Многопоточное выполнение операции';
						|pl = 'Multithreaded operation execution';
						|tr = 'Çoklu iş parçacıklı işlem gerçekleştirme'"));
					
				ArrayOfTasks.Add(Job);
				
			EndIf;
			
			If Processed = NumberOfOrganizations Then
					// All tasks are running
					Break;
			EndIf;
			
			CompanyArray = New Array;
			
		EndIf;
	
		Organization = OrganizationsToCalculate_.Get(Processed);
		CompanyArray.Add(Organization);
		
		Processed = Processed + 1;
		
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
					NStr("vi = 'Nhiệm vụ nền tạo dự phòng theo công nợ khó đòi %1
					|%2';
					|ru = 'Фоновое задание формирования резервов по сомнительным долгам %1
					|%2';
					|en = 'Background job for loss allowance generation %1
					|%2'; fa = 'Background job for loss allowance generation %1
					|%2';
					|it = 'Фоновое задание формирования резервов по сомнительным долгам %1
					|%2';
					|pl = 'Background job for loss allowance generation %1
					|%2';
					|tr = 'Şüpheli borç karşılıklarına göre rezerv oluşturma arka plan işi %1
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

// Description of checks for the month's closing stage.
//
// Parameters:
//	TableOfChecks - See AuditOfSystemStateOverridable.FillOutChecksForRegistration.
//
Procedure DescriptionOfInspections_FormationOfProvisionsForDoubtfulDebts(TableOfChecks) Export
	
	// Checking the documents that need to be created.

	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"VerificationOfNeedToFormReservesForDoubtfulDebts",
		Catalogs.MonthEndClosingOperations.GenerateLossAllowance,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.AfterCalculation,
		"AccrualAndWriteOffOfBadDebtAlowancesServer.VerificationOfNeedToFormReservesForDoubtfulDebts");

	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription, NStr(
		"vi = 'Lập dự phòng cho các khoản nợ nghi ngờ không được phản ánh';
		|ru = 'Не отражена операция формирования резервов по сомнительным долгам';
		|en = 'The transaction of generation of loss allowance is not recorded'; fa = 'The transaction of generation of loss allowance is not recorded';
		|it = 'Non si riflette l''operazione di formazione di riserve su debiti discutibili';
		|pl = 'Nie odnotowano operacji tworzenia rezerw na wątpliwe długi';
		|tr = 'Şüpheli borç için karşılık oluşturma işlemi yansıtılmamaktadır'", Common.DefaultLanguageCode()),
		NStr(
		"vi = 'Mỗi tháng, cần tạo một chứng từ ""Tính toán và ghi giảm dự phòng theo nợ khó đòi"".';
		|ru = 'В каждом месяце должен быть создан документ ""Начисление и списание резервов по сомнительным долгам"".';
		|en = 'Create the ""Accrual and write-off of loss allowance"" document for each month.'; fa = 'Create the ""Accrual and write-off of loss allowance"" document for each month.';
		|it = 'In ogni mese deve essere creato il documento ""Accredito e addebito su debiti inesigibili"".';
		|pl = 'W każdym miesiącu należy utworzyć dokument „Rozliczenia i odpisy rezerw na wątpliwe długi”.';
		|tr = 'Her ay, ""Şüpheli borç karşılıkların tahakkuku ve silinmesi"" belgesi oluşturulmalıdır.'",
		Common.DefaultLanguageCode()));
	
	// Checking documents that need to be corrected manually.

	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"VerificationOfChangesInAccountsReceivableProvisionsForDoubtfulDebts",
		Catalogs.MonthEndClosingOperations.GenerateLossAllowance,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"AccrualAndWriteOffOfBadDebtAlowancesServer.VerificationOfChangesInAccountsReceivableProvisionsForDoubtfulDebts");

	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription, NStr(
		"vi = 'Đã thay đổi các khoản phải thu cho các khoản nợ khó đòi';
		|ru = 'Изменилась дебиторская задолженность резервов по сомнительным долгам';
		|en = 'Receivables of loss allowance were changed'; fa = 'Receivables of loss allowance were changed';
		|it = 'Crediti inesigibili sono cambiati';
		|pl = 'Zmieniono należności za wątpliwe długi';
		|tr = 'Şüpheli borç karşılığı alacak hesabı değişti'",
		Common.DefaultLanguageCode()), NStr(
		"vi = 'Các khoản phải thu từ biểu ghi tính toán theo hoạt động phải trùng với chứng từ ""Tính và ghi giảm dự phòng đối với các khoản nợ khó đòi"".';
		|ru = 'Дебиторская задолженность по оперативным регистрам учета должна совпадать с документом ""Начисление и списание резервов по сомнительным долгам"".';
		|en = 'Receivables for operational accounting registers must match the ""Accrual and write-off of loss allowance"" document.'; fa = 'Receivables for operational accounting registers must match the ""Accrual and write-off of loss allowance"" document.';
		|it = 'I crediti operativi registri di contabilità deve coincidere con il documento ""Accredito e addebito su debiti inesigibili"".';
		|pl = 'Należności z tytułu ewidencji księgowości operacyjnej powinny pokrywać się z dokumentem „Rozliczenia i odpisy rezerw na wątpliwe długi”.';
		|tr = 'Operasyonel muhasebe kayıtları için alacak hesapları, ""Şüpheli borç karşılıklarının tahakkuku ve gider yazılması"" belgesiyle eşleşmelidir.'",
		Common.DefaultLanguageCode()));

EndProcedure

// This stage is required if there is no document for forming reserves for doubtful debts in the current month.
//
// Parameters:
//  CheckParameters - Structure - parameter of the verification handler procedure, See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfNeedToFormReservesForDoubtfulDebts(CheckParameters) Export

	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));

	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TT_OrganizationsToReflect", NStr(
		"vi = 'Chưa tạo chứng từ ""Tính và ghi giảm dự phòng theo nợ khó đòi"" theo doanh nghiệp ""%1"" trong kỳ %2';
		|ru = 'Не создан документ ""Начисление и списание резервов по сомнительным долгам"" по организации ""%1"" за период %2';
		|en = 'The ""Accrual and write-off of loss allowance"" document is not created for the ""%1"" company for period %2'; fa = 'The ""Accrual and write-off of loss allowance"" document is not created for the ""%1"" company for period %2';
		|it = 'Non è stato creato il documento ""Accantonamenti e addebiti delle riserve sui debiti discutibili"" sull''organizzazione ""%1"" per il periodo %2';
		|pl = 'Dokument „Naliczanie i odpisywanie rezerw na wątpliwe długi„ dla firmy ”%1” za okres %2';
		|tr = '""Şüpheli borç karşılıklarının tahakkuku ve gider yazılması"" belgesi ""%1"" iş yeri için %2 döneminde oluşturulmadı'",
		Common.DefaultLanguageCode()), FieldList);

	If ValueIsFilled(CheckParameters.AdditionalParameters) Then
		DataVolume = CostCalculationAppliedAlgorithms.TemporaryTableSize(
			CheckParameters.AdditionalParameters.TempTablesManager, "TT_OrganizationsToReflect");
		MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(
			CheckParameters.AdditionalParameters, DataVolume);
	EndIf;

	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters, RegistrationParameters);

EndProcedure

// This step is required if the accounts receivable saved in the document differs from the balance of accounts receivable in the accounting.
// 
// Parameters:
//  CheckParameters - Structure - parameter of the verification handler procedure, See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfChangesInAccountsReceivableProvisionsForDoubtfulDebts(CheckParameters) Export

	FieldList = New ValueList;
	FieldList.Add("Organization", NStr("vi = 'Doanh nghiệp';
										|ru = 'Организация';
										|en = 'Company'; fa = 'Company';
										|it = 'Azienda';
										|pl = 'Company';
										|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Document", NStr("vi = 'Chứng từ ""Tính và ghi giảm dự phòng theo nợ khó đòi""';
									|ru = 'Документ ""Начисление и списание резервов по сомнительным долгам""';
									|en = 'The ""Accrual and write-off of loss allowance"" document'; fa = 'The ""Accrual and write-off of loss allowance"" document';
									|it = 'Documento ""Maturazione e storno di riserve per crediti di dubbia esigibilità""';
									|pl = 'Dokument „Rozliczenia i odpisy rezerw na wątpliwe długi”';
									|tr = 'Belge ""Şüpheli borç karşılıklarının tahakkuku ve gider yazılması""'",
		Common.DefaultLanguageCode()));

	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TT_OrganizationsToReview", NStr("vi = 'Đối với chứng từ ""Tính và ghi giảm dự phòng nợ khó đòi"" theo doanh nghiệp ""%1"" trong kỳ %2 có những thay đổi trong nợ phải thu
										|Cần chuyển đến chứng từ ""Tính và ghi giảm dự phòng nợ khó đòi"" và sửa thủ công các dòng (sửa số tiền dự phòng, đánh giá, xóa dòng...), đánh dấu hộp kiểm ""Cần kiểm tra"".
										|Sau khi chỉnh sửa, cần bỏ dấu ""Cần kiểm tra"" tại các dòng này.';
										|ru = 'Для документа ""Начисление и списание резервов по сомнительным долгам"" по организации ""%1"" за период %2 есть изменения в дебиторской задолженности
										|Необходимо зайти в документ ""Начисление и списание резервов по сомнительным долгам"" и вручную поправить строки (поправить сумму резерва, оценку, удалить строку, ...), отмеченные флагом ""Нужна проверка"".
										|После исправления необходимо снять флаг ""Нужна проверка"" у данных строк.';
										|en = 'There are changes in receivables for the ""Accrual and write-off of loss allowance"" document for the ""%1"" company for period %2
										|Go to the ""Accrual and write-off of loss allowance"" document and correct the lines (correct reserve amount, valuation, remove the line, ...), marked by the ""Need check"" check box, manually.
										|After correction clear the ""Need check"" check box in these lines.'; fa = 'There are changes in receivables for the ""Accrual and write-off of loss allowance"" document for the ""%1"" company for period %2
										|Go to the ""Accrual and write-off of loss allowance"" document and correct the lines (correct reserve amount, valuation, remove the line, ...), marked by the ""Need check"" check box, manually.
										|After correction clear the ""Need check"" check box in these lines.';
										|it = 'Per il documento ""Accredito e addebito degli accantonamenti per svalutazione crediti"" per l''azienda ""%1"" per il periodo %2 di un cambiamento in crediti
										|Bisogna andare in un documento di ""Accredito e addebito inesigibili"" e correggere manualmente le righe (correggere l''importo della riserva, la valutazione, eliminare una riga ...) contrassegnato con il flag ""Occorre una verifica"".
										|Dopo l''hotfix, è necessario deselezionare la casella di controllo ""Occorre una verifica"" per i dati di riga.';
										|pl = 'Dla dokumentu ""Naliczenie i rozchód rezerwy wg wątpliwym zobowiązaniom"" wg firmy ""%1"" za okres %2 istnieją zmiany w należności
										|Należy wejść do dokumentu ""Naliczenie i rozchód rezerwy wg wątpliwym zobowiązaniom"" i od ręki poprawić wiersze (poprawić sumę rezerwy, ocenę, usunąć wiersz, ...), oznaczone flagą ""Wymaga sprawdzenia"".
										|Po poprawieniu należy usunąć flagę ""Wymaga sprawdzenia"" w danych wierszach.';
										|tr = '""%1"" iş yerinin ""Şüpheli borç karşılıklarının tahakkuku ve gider yazılması"" belgesinin %2 dönemi için alacaklarında değişiklik var
										|""Şüpheli borç karşılıklarının tahakkuku ve gider yazılması"" belgesine gidilmesi ve ""Kontrol gerekli"" bayrağıyla işaretlenmiş satırların manuel olarak düzeltilmesi (karşılık miktarını düzelt, tahmin et, satırı sil, ...) .
										|Düzeltmeden sonra, bu satırlar için ""Kontrol gerekli"" bayrağının işaretini kaldırmak gerekir.'",
		Common.DefaultLanguageCode()), FieldList, "Document");

	If ValueIsFilled(CheckParameters.AdditionalParameters) Then
		DataVolume = CostCalculationAppliedAlgorithms.TemporaryTableSize(
			CheckParameters.AdditionalParameters.TempTablesManager, "TT_OrganizationsToReview");
		MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(
			CheckParameters.AdditionalParameters, DataVolume);
	EndIf;

	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters, RegistrationParameters);

EndProcedure

#EndRegion

#Region JobsForMonthEndClosing

// Selects tasks for the end of the month.
// If the accounting policy does not create reserves, the tasks are not registered.
// 
// Parameters:
// 	Query - Query - a query containing a temporary table of calculation changes with columns:
// 	* Period - Date -
// 	* Organization - CatalogRef.Companies - 
// 	* Document - DocumentRef - 
// 	NameOfChangeTable - String - name of the temporary calculation change table.
//
// Returns:
//  QueryResultSelection - selection of tasks by the end of the month:
//  * Month - Date - the period of the task
//  * Organization - CatalogRef.Companies - the organization that the task will be generated for
//  * Operation - CatalogRef.MonthEndClosingOperations - always formingreferencesexternal Links
//  * Document - Undefined -
//
Function SelectionOfTasksForEndOfMonthWhenCalculationsAreChanged(Query, NameOfChangeTable) Export

	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfChangeTable;

	Query.Text = RequestTextForCurrentAccountingPolicies(NameOfChangeTable, NameOfCurrentAccountingPoliciesTable)
		+ Common.QueryBatchSeparator() + RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(
		NameOfCurrentAccountingPoliciesTable) + Common.QueryBatchSeparator() + "DROP "
		+ NameOfCurrentAccountingPoliciesTable + "; ";

	Return Query.Execute().Select();

EndFunction

// Text of the request for tasks to close the month of reserves for doubtful debts.
// 
// Parameters:
// 	NameOfCurrentAccountingPoliciesTable - String - name of the temporary table of current accounting policies.
//   (See RequestTextForCurrentAccountingPolicies).
//
// Returns:
//  String - Query text
//
Function RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable) Export
	
	// The order of the fields in the request is important because it is used in conjunction with other requests.
	// In particular, from the procedure of the record set module of the Accumulation Register
	// (See AccumulationRegister.RevenueAndCOGS)Recording.

	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Tt_CurrentAccountingPolicies.Period, MONTH) AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.GenerateLossAllowance) AS Operation,
	|	Tt_CurrentAccountingPolicies.Organization AS Organization,
	|	Tt_CurrentAccountingPolicies.Document AS Document
	|FROM
	|	#CurrentAccountingPolicies AS Tt_CurrentAccountingPolicies
	|WHERE
	|	VALUETYPE(Tt_CurrentAccountingPolicies.Document) <> TYPE(Document.OBEntry)
	|	AND (Tt_CurrentAccountingPolicies.ToGenerateLossAllowance
	|			OR Tt_CurrentAccountingPolicies.ToFormReservesForDoubtfulDebtsTa)";

	QueryText = StrReplace(QueryText, "#CurrentAccountingPolicies", NameOfCurrentAccountingPoliciesTable);

	Return QueryText;

EndFunction

// Text of the request for the current accounting policy of reserves for doubtful debts.
//
// Parameters:
// 	NameOfChangeTable - String - name of the temporary calculation change table.
// 	NameOfPreparedTable - String - name of the temporary table to place the current accounting policies in.
//
// Returns:
//  String - Query text
//
Function RequestTextForCurrentAccountingPolicies(NameOfChangeTable, NameOfPreparedTable) Export

	RequestTextsPackage = New Array;

	QueryText =
	"SELECT DISTINCT
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	ISNULL(Companies.ParentCompany, TT_TableOfChanges.Organization) AS OrganizationOfAccountingPolicy,
	|	TT_TableOfChanges.Document AS Document
	|INTO Tt_OrganizationOfAccountingPolicy
	|FROM
	|	#ChangesTable AS TT_TableOfChanges
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON TT_TableOfChanges.Organization = Companies.Ref
	|			AND Companies.BranchOffice";

	RequestTextsPackage.Add(QueryText);

	RequestTextsPackage.Add(TextOfRequestAccountingPoliciesOfFinancialAccounting());
	RequestTextsPackage.Add(
		AccrualAndWriteOffOfBadDebtAlowancesLocalization.RequestTextAccountingPoliciesAC());
	RequestTextsPackage.Add(
		AccrualAndWriteOffOfBadDebtAlowancesLocalization.RequestTextAccountingPoliciesTa());

	QueryText =
	"SELECT
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	TT_TableOfChanges.Document AS Document,
	|	TT_ACAccountingPolicies.TypeOfDifferencesInPBU18ProvisionsForDoubtfulDebts AS TypeOfDifferencesInPBU18ProvisionsForDoubtfulDebts,
	|	TT_AccountingPoliciesTa.ToFormReservesForDoubtfulDebtsTa AS ToFormReservesForDoubtfulDebtsTa,
	|	TT_AccountingPoliciesTa.PeriodicityOfProvisionsForDoubtfulDebtsTa AS PeriodicityOfProvisionsForDoubtfulDebtsTa,
	|	TT_AccountingPoliciesOfMa.ToGenerateLossAllowance AS ToGenerateLossAllowance,
	|	TT_AccountingPoliciesOfMa.FrequencyOfLossAllowance AS FrequencyOfLossAllowance
	|INTO #NameOfPreparedTable
	|FROM
	|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges
	|		LEFT JOIN TT_ACAccountingPolicies AS TT_ACAccountingPolicies
	|		ON TT_TableOfChanges.OrganizationOfAccountingPolicy = TT_ACAccountingPolicies.Organization
	|			AND TT_TableOfChanges.Period = TT_ACAccountingPolicies.Period
	|		LEFT JOIN TT_AccountingPoliciesTa AS TT_AccountingPoliciesTa
	|		ON TT_TableOfChanges.OrganizationOfAccountingPolicy = TT_AccountingPoliciesTa.Organization
	|			AND TT_TableOfChanges.Period = TT_AccountingPoliciesTa.Period
	|		LEFT JOIN TT_AccountingPoliciesOfMa AS TT_AccountingPoliciesOfMa
	|		ON TT_TableOfChanges.OrganizationOfAccountingPolicy = TT_AccountingPoliciesOfMa.Organization
	|			AND TT_TableOfChanges.Period = TT_AccountingPoliciesOfMa.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_ACAccountingPolicies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_AccountingPoliciesTa
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_AccountingPoliciesOfMa
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Tt_OrganizationOfAccountingPolicy";

	RequestTextsPackage.Add(QueryText);

	QueryText = StrConcat(RequestTextsPackage, Common.QueryBatchSeparator());

	QueryText = StrReplace(QueryText, "#ChangesTable", NameOfChangeTable);
	QueryText = StrReplace(QueryText, "#NameOfPreparedTable", NameOfPreparedTable);

	Return QueryText;

EndFunction

#EndRegion

#EndRegion

// Checks whether the specified period matches the frequency of reserve formation.
//
// Parameters:
//	Periodicity - EnumRef.Periodicity - the periodicity of the reserves
//	Period - Date - period for generating a document for this operation
//
// Returns:
//	 Boolean - a sign of the need to form a document
//
Function FormationOfReservesInSpecifiedPeriodIsRequired(Periodicity, Period) Export

	Result = False;

	If Periodicity = Enums.Periodicity.Month Then
		Result = True;
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Result = (Month(Period) % 3 = 0);
	ElsIf Periodicity = Enums.Periodicity.Year Then
		Result = (Month(Period) = 12);
	EndIf;

	Return Result;

EndFunction

Function GetDefaultDebtAssessmentIntervals() Export

	IntervalsTable = New ValueTable;
	IntervalsTable.Columns.Add("IntervalName");
	IntervalsTable.Columns.Add("LowerBoundOfInterval");
	IntervalsTable.Columns.Add("UpperBoundOfInterval");
	IntervalsTable.Columns.Add("Evaluation");

	EvaluationIntervals = New Array;
	EvaluationIntervals.Add(New Structure("Lower,Upper_,Evaluation", 1, 44, 0));
	EvaluationIntervals.Add(New Structure("Lower,Upper_,Evaluation", 45, 90, 50));
	EvaluationIntervals.Add(New Structure("Lower,Upper_,Evaluation", 91, 9999999999, 100));

	Descriptions = New Array;
	Descriptions.Add("dated 1 before 44 ofdays");
	Descriptions.Add("dated 45 before 90 ofdays");
	Descriptions.Add("Over 91 ofdays");

	NumberOfIntervals = EvaluationIntervals.Count();
	For IndexOf = 0 To NumberOfIntervals - 1 Do
		Interval = EvaluationIntervals[IndexOf];

		NewRow = IntervalsTable.Add();
		NewRow.IntervalName = Descriptions[IndexOf];
		NewRow.LowerBoundOfInterval = Interval.Lower;
		NewRow.UpperBoundOfInterval = Interval.Upper_;
		NewRow.Evaluation = Interval.Evaluation;
	EndDo;

	Return IntervalsTable;

EndFunction

#EndRegion

#Region Internal

#Region CreatingTasksForEndOfMonth

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
// 	UndoPosting - Boolean -
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText,
	TemporaryTableNames, UndoPosting) Export

	MatchingRequests = MatchingRequestsToControlRegisters(Query, UndoPosting);

	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTableNamesForTasks(Query, MapItem.Key);
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key, MapItem.Value,
			Query.TempTablesManager.Tables, QueryText, TempTablesQueryText, TemporaryTableNames);
	EndDo;

EndProcedure

#EndRegion

// Returns a table of debt estimates in accordance with the organization's accounting policy.
//
// Returns:
// 		ValueTable - empty evaluation table (See empty evaluation table)
//
Function MARatingTable(Organization, Period) Export
	
	EvaluationTable = Documents.AccrualAndWriteOffOfBadDebtAlowances.EmptyRatingTable();
	AccountingPolicyEvaluationTable = InformationRegisters.FinancialAccountingPolicy.DebtEvaluationProcedure(Organization, Period);
	If AccountingPolicyEvaluationTable <> Undefined Then
		CommonClientServer.SupplementTable(AccountingPolicyEvaluationTable, EvaluationTable);
	EndIf;
	Return EvaluationTable;
	
EndFunction

#EndRegion

#Region Private

// Creates or resets documents for Accrual and write-off of reserves for doubtful debts for transferred
// organizations for the specified period. If, according to the accounting policy, reserves are not formed, the document
// is either not created or canceled.
// 
// Parameters:
// 	Companies - Array - array of organizations for generating documents
// 	Period - Date - the period of formation documents
//
Procedure GenerateReservesAtCloseOfMonth(Companies, Period)

	Query = New Query;

	RequestTextsPackage = New Array;

	TempTablesManager = New TempTablesManager;
	AccountingPoliciesTaxSettings.AddParentOrganizationsToTemporaryTableManager(TempTablesManager,
		Companies);
	Query.TempTablesManager = TempTablesManager;
	
	QueryText = "SELECT DISTINCT
	|	TTParentOrganizations.Organization AS Organization
	|INTO OnlyParentOrganizations
	|FROM
	|	TTParentOrganizations AS TTParentOrganizations
	|
	|INDEX BY
	|	Organization";
	
	RequestTextsPackage.Add(QueryText);

	RequestTextsPackage.Add(QueryTextAccountingPolicyOfMa());
	RequestTextsPackage.Add(
		AccrualAndWriteOffOfBadDebtAlowancesLocalization.RequestTextAccountingPolicyTa());

	QueryText =
	"SELECT
	|	ParentOrganizations.BranchOffice AS Organization,
	|	ISNULL(TTAccountingPolicyTa.GenerateTA, FALSE) AS GenerateTA,
	|	ISNULL(TTAccountingPolicyTa.PeriodicityTa, FALSE) AS PeriodicityTa,
	|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FormingMa, FALSE) AS FormingMa,
	|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FrequencyOfMa, FALSE) AS FrequencyOfMa
	|INTO TTAccountingPoliciesOfOrganizations
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN TTAccountingPolicyTa AS TTAccountingPolicyTa
	|		ON ParentOrganizations.Organization = TTAccountingPolicyTa.Organization
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON ParentOrganizations.Organization = TTAccountingPolicyOfFinancialAccounting.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccountingPoliciesOfOrganizations.Organization,
	|	TTAccountingPoliciesOfOrganizations.GenerateTA AS GenerateTA,
	|	TTAccountingPoliciesOfOrganizations.FormingMa AS FormingMa,
	|	TTAccountingPoliciesOfOrganizations.PeriodicityTa AS PeriodicityTa,
	|	TTAccountingPoliciesOfOrganizations.FrequencyOfMa AS FrequencyOfMa,
	|	Documents.Ref AS Document,
	|	ISNULL(Documents.Posted, FALSE) AS DocumentPosted,
	|	CASE
	|		WHEN Documents.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS DocumentExists
	|FROM
	|	TTAccountingPoliciesOfOrganizations AS TTAccountingPoliciesOfOrganizations
	|		LEFT JOIN Document.AccrualAndWriteOffOfBadDebtAlowances AS Documents
	|		ON TTAccountingPoliciesOfOrganizations.Organization = Documents.Organization
	|		AND
	|		NOT Documents.DeletionMark
	|		AND Documents.Date = &EndOfMonth";

	RequestTextsPackage.Add(QueryText);

	Query.Text = StrConcat(RequestTextsPackage, Common.QueryBatchSeparator());

	Query.SetParameter("Companies", Companies);
	Query.SetParameter("BeginOfPeriod", Period);
	Query.SetParameter("EndOfMonth", EndOfMonth(Period));

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.DocumentExists Then
			DocumentObject = Selection.Document.GetObject();

		If Selection.DocumentPosted And Not Selection.GenerateTA
			And Not Selection.FormingMa Then
				DocumentObject.Write(DocumentWriteMode.UndoPosting);
				Continue;
			EndIf;
		ElsIf Not Selection.GenerateTA And Not Selection.FormingMa Then
			Continue;
		Else
			DocumentObject = Documents.AccrualAndWriteOffOfBadDebtAlowances.CreateDocument();
			DocumentObject.Date = EndOfMonth(Period);
			DocumentObject.Organization = Selection.Organization;
			DocumentObject.PostInFinancialAccounting = Selection.FormingMa
				And FormationOfReservesInSpecifiedPeriodIsRequired(Selection.FrequencyOfMa, Period);
			DocumentObject.RecordInTaxAccounting = Selection.GenerateTA
				And FormationOfReservesInSpecifiedPeriodIsRequired(Selection.PeriodicityTa, Period);
			DocumentObject.RecordInManagementAccounting = Selection.FormingMa
				And FormationOfReservesInSpecifiedPeriodIsRequired(Selection.FrequencyOfMa, Period);
			DocumentObject.EmployeeResponsible = Users.CurrentUser();
		EndIf;

		FillParameters = New Structure;
		FillParameters.Insert("Organization", DocumentObject.Organization);
		FillParameters.Insert("Date", DocumentObject.Date);
		FillParameters.Insert("EmptyDocument", DocumentObject.AccountsReceivable.Count() = 0);

		Result = Documents.AccrualAndWriteOffOfBadDebtAlowances.GetDataForFillingAccountsReceivable(
			FillParameters);

		DocumentObject.FillInDocument(Result.Unload());
		DocumentObject.Write(DocumentWriteMode.Posting);
	EndDo;

EndProcedure

Function QueryTextAccountingPolicyOfMa()

	Return "SELECT
			|	ParentOrganizations.Organization AS Organization,
			|	SliceTable.ToGenerateLossAllowance AS FormingMa,
			|	SliceTable.FrequencyOfLossAllowance AS FrequencyOfMa
			|INTO TTAccountingPolicyOfFinancialAccounting
			|FROM
			|	OnlyParentOrganizations AS ParentOrganizations
			|		LEFT JOIN InformationRegister.FinancialAccountingPolicy.SliceLast(&BeginOfPeriod, Organization IN
			|			(SELECT
			|				ParentOrganizations.Organization
			|			FROM
			|				OnlyParentOrganizations AS ParentOrganizations)) AS SliceTable
			|		ON ParentOrganizations.Organization = SliceTable.Organization
			|
			|INDEX BY
			|	Organization";

EndFunction

Function TextOfRequestAccountingPoliciesOfFinancialAccounting()

	Return "SELECT
			|	TT_TableOfChanges.Period AS Period,
			|	TT_TableOfChanges.Organization AS Organization,
			|	MAX(AccountingPolicyOfMa.Period) AS PeriodOfAccountingPolicyOfMa
			|INTO TT_PeriodsOfMaAccountingPolicy
			|FROM
			|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges
			|		LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicyOfMa
			|		ON TT_TableOfChanges.OrganizationOfAccountingPolicy = AccountingPolicyOfMa.Organization
			|			AND TT_TableOfChanges.Period >= AccountingPolicyOfMa.Period
			|
			|GROUP BY
			|	TT_TableOfChanges.Period,
			|	TT_TableOfChanges.Organization
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	ISNULL(AccountingPolicyOfMa.ToGenerateLossAllowance, FALSE) AS ToGenerateLossAllowance,
			|	AccountingPolicyOfMa.FrequencyOfLossAllowance AS FrequencyOfLossAllowance,
			|	TT_PeriodsOfMaAccountingPolicy.Period AS Period,
			|	TT_PeriodsOfMaAccountingPolicy.Organization AS Organization
			|INTO TT_AccountingPoliciesOfMa
			|FROM
			|	TT_PeriodsOfMaAccountingPolicy AS TT_PeriodsOfMaAccountingPolicy
			|		LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicyOfMa
			|		ON TT_PeriodsOfMaAccountingPolicy.Organization = AccountingPolicyOfMa.Organization
			|			AND TT_PeriodsOfMaAccountingPolicy.PeriodOfAccountingPolicyOfMa = AccountingPolicyOfMa.Period
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP TT_PeriodsOfMaAccountingPolicy";

EndFunction

// The function gets the parameters of the accounting and tax accounting policies in effect on the date.
// Parameters:
//  Organization - CatalogRef.Companies
//  Period - Date
// 
// Returns:
//  Structure - Cur current accounting parameters linked to the register of accounting policies:
// * FinancialAccountingPolicy - Undefined, Structure - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings
// * AccountingPolicyBuhAccounting - Undefined, Structure - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings
// * ProfitTaxAccountingSettings - Undefined, Structure - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings.
Function GetCurrentAccountingPolicySettings(Organization, Period) Export
	
	AccountingPolicySettings_ = New Structure;
	AccountingPolicySettings_.Insert("FinancialAccountingPolicy", Undefined);
	AccountingPolicySettings_.Insert("AccountingPolicyBuhAccounting", Undefined);
	AccountingPolicySettings_.Insert("ProfitTaxAccountingSettings", Undefined);

	AccountingPolicySettings_.FinancialAccountingPolicy = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Organization,
		Period,
		False);
	
	AccrualAndWriteOffOfBadDebtAlowancesLocalization.SupplementCurrentParametersOfAccountingPolicies(
		AccountingPolicySettings_,
		Organization,
		Period);
	
	Return AccountingPolicySettings_;
	
EndFunction


#Region FormationOfTasksForEndOfMonthServiceTasks

// The text of the request that converts the passed table of changes (required columns Period, analyticaccount to Partners, Registrar) to a new one
// (The Company, Organization, Registrar). The organization is taken from the partner accounting analysis.
// The result is saved to a new temporary table of the passed query.
// 
// Returns:
//   String - query text for the newly prepared table
//
Function TextOfChangeRequestForPartnerAccountingAnalytics(NameOfChangeTable, NameOfPreparedChangeTable,
	NameOfRegistrarSAccountDetails = "Recorder")

	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Period,
	|	ChangesTable.AccountingDimensionByPartners.Organization AS Organization,
	|	&Recorder AS Document
	|INTO #PreparedTableOfChanges
	|FROM
	|	#ChangesTable AS ChangesTable
	|WHERE
	|	&Condition
	|;
	|";

	QueryText = StrReplace(QueryText, "#ChangesTable", NameOfChangeTable);
	QueryText = StrReplace(QueryText, "#PreparedTableOfChanges", NameOfPreparedChangeTable);
	QueryText = StrReplace(QueryText, "&Recorder", StrTemplate("ChangesTable.%1", NameOfRegistrarSAccountDetails));
	If NameOfChangeTable = "ChangesTableFinancialInstrumentsARAP" Then
		QueryText = StrReplace(QueryText, "&Condition", "(ChangesTable.Contract.ContractType = VALUE(Enum.LoanAndDepositContractTypes.DepositWithoutInterestCapitalization)
															 |OR ChangesTable.AmountType IN (VALUE(Enum.TypesOfLeasePayments.DepositPayment),
															 |								  VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment)))
															 |AND (ChangesTable.Sum <> 0 OR ChangesTable.SumMan <> 0
															 |		OR ChangesTable.SumCompl <> 0)");
	Else
		QueryText = StrReplace(QueryText, "&Condition", "True");
	EndIf;

	Return QueryText;

EndFunction

Function MatchingRequestsToControlRegisters(Query, UndoPosting)

	MatchingQueryTexts = New Map;
	MatchingQueryTexts.Insert("ChangesTableRecordsCounterpartyIncomeExpenses",
		QueryTextRecordsCounterpartyIncomeExpenses(Query, UndoPosting));
	MatchingQueryTexts.Insert("ChangesTableRevenueAndCOGS",
		QueryTextRevenueAndCOGS(Query));
	MatchingQueryTexts.Insert("ChangesTableFinancialInstrumentsARAP",
		QueryTextFinancialInstrumentsARAP(Query));
	MatchingQueryTexts.Insert("ChangesTableCustomersARAPAccountingByDueDates",
		QueryTextCustomersARAPAccountingByDueDates(Query));
	MatchingQueryTexts.Insert("ChangesTableVendorsARAPAccountingByDueDates",
		QueryTextVendorsARAPAccountingByDueDates(Query));
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		MatchingQueryTexts.Insert("SettlementsWithClientsOnDocumentsChanges",
			QueryTextCustomersARAPAccountingByDocuments(Query));
		MatchingQueryTexts.Insert("SettlementsWithSuppliersBasedOnChangeDocuments",
			QueryTextVendorsARAPAccountingByDocuments(Query));
	EndIf;
	MatchingQueryTexts.Insert("ChangesTableLossAllowance",
		QueryTextLossAllowance(Query, UndoPosting));
	Return MatchingQueryTexts;

EndFunction

#Region RequestTextsForTasksAtEndOfMonth

Function QueryTextRecordsCounterpartyIncomeExpenses(Query, UndoPosting)

	NameOfChangeTable = "RecordsCounterpartyIncomeExpenses";
	NameOfPreparedChangeTable = "_" + NameOfChangeTable;
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfPreparedChangeTable;

	TempTablesQueryText =
	"SELECT DISTINCT
	|	DATEADD(BEGINOFPERIOD(ChangesTable.Period, MONTH), MONTH, CASE
	|			WHEN VALUETYPE(ChangesTable.Recorder) = TYPE(Document.AccrualAndWriteOffOfBadDebtAlowances) AND NOT &UndoPosting
	|				THEN 1
	|			ELSE 0
	|		END) AS Period,
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.Recorder AS Document
	|INTO NameOfPreparedChangeTable
	|FROM
	|	ChangesTableRecordsCounterpartyIncomeExpenses AS ChangesTable
	|WHERE
	|	NOT VALUETYPE(ChangesTable.Recorder) IN (TYPE(Document.OBEntry),
	|													TYPE(Document.ExchangeDifferenceCalculation))
	|;";
	TempTablesQueryText = StrReplace(TempTablesQueryText, "NameOfPreparedChangeTable",
		NameOfPreparedChangeTable);

	TempTablesQueryText =  TempTablesQueryText + RequestTextForCurrentAccountingPolicies(
		NameOfPreparedChangeTable, NameOfCurrentAccountingPoliciesTable) + ";";

	TemporaryTableNames = NameOfPreparedChangeTable + ", " + NameOfCurrentAccountingPoliciesTable;
	QueryText = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable);
	Query.SetParameter("UndoPosting", UndoPosting);

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, NameOfCurrentAccountingPoliciesTable);
	Return StructureOfQueryTexts_;

EndFunction

Function QueryTextRevenueAndCOGS(Query)

	ArrayOfTemporaryTableQueries = New Array;
	ArrayTemporaryTableNames = New Array;

	TextChangeInLocalRevenue = "
									 |SELECT
									 |	ChangesTable.Period AS Period,
									 |	PartnerAccountingAnalyticsKeys.Organization AS Organization,
									 |	ChangesTable.Recorder AS Document,
									 |	ChangesTable.RevenueAmountExclVATLocal
									 |INTO TTChangeInLocalRevenue
									 |FROM
									 |	ChangesTableRevenueAndCOGS AS ChangesTable
									 |	INNER JOIN
									 |		InformationRegister.AccountingDimensionByPartners AS PartnerAccountingAnalyticsKeys
									 |	ON
									 |		ChangesTable.AccountingDimensionByPartners = PartnerAccountingAnalyticsKeys.DimensionKey
									 |WHERE
									 |	VALUETYPE(ChangesTable.Recorder) <> TYPE(Document.OBEntry)
									 |";
	ArrayOfTemporaryTableQueries.Add(TextChangeInLocalRevenue);
	ArrayTemporaryTableNames.Add("TTChangeInLocalRevenue");

	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies__ChangeInLocalRevenue";
	ArrayOfTemporaryTableQueries.Add(RequestTextForCurrentAccountingPolicies("TTChangeInLocalRevenue",
		NameOfCurrentAccountingPoliciesTable));
	ArrayTemporaryTableNames.Add(NameOfCurrentAccountingPoliciesTable);

	TempTablesQueryText = StrConcat(ArrayOfTemporaryTableQueries,
		Common.QueryBatchSeparator());
	TempTablesQueryText = TempTablesQueryText + Common.QueryBatchSeparator();
	TemporaryTableNames_ = StrConcat(ArrayTemporaryTableNames, ",");

	QueryText = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable);
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, TemporaryTableNames_);

	Return StructureOfQueryTexts_

EndFunction

Function QueryTextFinancialInstrumentsARAP(Query)

	NameOfChangeTable = "ChangesTableFinancialInstrumentsARAP";
	NameOfPreparedChangeTable = "_" + NameOfChangeTable;
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfPreparedChangeTable;

	TempTablesQueryText = TextOfChangeRequestForPartnerAccountingAnalytics(NameOfChangeTable,
		NameOfPreparedChangeTable) + RequestTextForCurrentAccountingPolicies(NameOfPreparedChangeTable,
		NameOfCurrentAccountingPoliciesTable) + ";";
	TemporaryTableNames = NameOfPreparedChangeTable + ", " + NameOfCurrentAccountingPoliciesTable;

	RequestTextsCombiningTasks = New Array;
	QueryTextForChangeTable = "SELECT DISTINCT
									 |	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
									 |	VALUE(Catalog.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments) AS Operation,
									 |	Dimension.Organization,
									 |	ChangesTable.Recorder AS Document
									 |FROM
									 |	ChangesTableFinancialInstrumentsARAP AS ChangesTable
									 |		INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
									 |		ON ChangesTable.AccountingDimensionByPartners = Dimension.DimensionKey
									 |WHERE
									 |	(VALUETYPE(ChangesTable.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
									 |			OR ChangesTable.Contract.ARAPCurrency <> &CurrencyOfMan
									 |			OR ChangesTable.Contract.ARAPCurrency <> Dimension.Organization.LocalAccountingCurrency)
									 |	AND VALUETYPE(ChangesTable.Contract) <> TYPE(Catalog.LeaseContract)
									 |	AND VALUETYPE(ChangesTable.Recorder) <> TYPE(Document.OBEntry)
									 |	AND (ChangesTable.Sum <> 0 OR ChangesTable.SumMan <> 0
									 |		OR ChangesTable.SumCompl <> 0)";

	RequestTextsCombiningTasks.Add(QueryTextForChangeTable);

	QueryTextAccountingPolicies = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(
		NameOfCurrentAccountingPoliciesTable);
	RequestTextsCombiningTasks.Add(QueryTextAccountingPolicies);

	QueryText = StrConcat(RequestTextsCombiningTasks, TMCommonUse.QuerySeparatorInJoin(
		True));

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, TemporaryTableNames);
	Return StructureOfQueryTexts_;

EndFunction

Function QueryTextCustomersARAPAccountingByDocuments(Query)
	NameOfChangeTable = "SettlementsWithClientsOnDocumentsChanges";
	NameOfPreparedChangeTable = "_" + NameOfChangeTable;
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfPreparedChangeTable;

	TempTablesQueryText = TextOfChangeRequestForPartnerAccountingAnalytics(NameOfChangeTable,
		NameOfPreparedChangeTable) + RequestTextForCurrentAccountingPolicies(NameOfPreparedChangeTable,
		NameOfCurrentAccountingPoliciesTable) + ";";

	TemporaryTableNames = NameOfPreparedChangeTable + ", " + NameOfCurrentAccountingPoliciesTable;
	QueryText = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable);

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, TemporaryTableNames);
	Return StructureOfQueryTexts_;

EndFunction

Function QueryTextCustomersARAPAccountingByDueDates(Query)
	NameOfChangeTable = "ChangesTableCustomersARAPAccountingByDueDates";
	NameOfPreparedChangeTable = "_" + NameOfChangeTable;
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfPreparedChangeTable;

	TempTablesQueryText = TextOfChangeRequestForPartnerAccountingAnalytics(NameOfChangeTable,
		NameOfPreparedChangeTable, "DocumentRecorder") + RequestTextForCurrentAccountingPolicies(
		NameOfPreparedChangeTable, NameOfCurrentAccountingPoliciesTable) + ";";

	TemporaryTableNames = NameOfPreparedChangeTable + ", " + NameOfCurrentAccountingPoliciesTable;
	QueryText = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable);

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, TemporaryTableNames);
	Return StructureOfQueryTexts_;

EndFunction

Function QueryTextVendorsARAPAccountingByDocuments(Query)
	NameOfChangeTable = "SettlementsWithSuppliersBasedOnChangeDocuments";
	NameOfPreparedChangeTable = "_" + NameOfChangeTable;
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfPreparedChangeTable;

	TempTablesQueryText = TextOfChangeRequestForPartnerAccountingAnalytics(NameOfChangeTable,
		NameOfPreparedChangeTable) + RequestTextForCurrentAccountingPolicies(NameOfPreparedChangeTable,
		NameOfCurrentAccountingPoliciesTable) + ";";

	TemporaryTableNames = NameOfPreparedChangeTable + ", " + NameOfCurrentAccountingPoliciesTable;
	QueryText = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable);

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, TemporaryTableNames);
	Return StructureOfQueryTexts_;

EndFunction

Function QueryTextVendorsARAPAccountingByDueDates(Query)

	NameOfChangeTable = "ChangesTableVendorsARAPAccountingByDueDates";
	NameOfPreparedChangeTable = "_" + NameOfChangeTable;
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfPreparedChangeTable;

	TempTablesQueryText = TextOfChangeRequestForPartnerAccountingAnalytics(NameOfChangeTable,
		NameOfPreparedChangeTable, "DocumentRecorder") + RequestTextForCurrentAccountingPolicies(
		NameOfPreparedChangeTable, NameOfCurrentAccountingPoliciesTable) + ";";

	TemporaryTableNames = NameOfPreparedChangeTable + ", " + NameOfCurrentAccountingPoliciesTable;
	QueryText = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable);

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, TemporaryTableNames);
	Return StructureOfQueryTexts_;

EndFunction

Function QueryTextLossAllowance(Query, UndoPosting)

	NameOfChangeTable = "ChangesTableLossAllowance";
	NameOfPreparedChangeTable = "_" + NameOfChangeTable;
	NameOfCurrentAccountingPoliciesTable = "CurrentAccountingPolicies" + NameOfPreparedChangeTable;

	TempTablesQueryText =
	"SELECT DISTINCT
	|	DATEADD(BEGINOFPERIOD(ChangesTable.Period, MONTH), MONTH, CASE
	|			WHEN VALUETYPE(ChangesTable.Recorder) = TYPE(Document.AccrualAndWriteOffOfBadDebtAlowances) AND NOT &UndoPosting
	|				THEN 1
	|			ELSE 0
	|		END) AS Period,
	|	ChangesTable.AccountingDimensionByPartners.Organization AS Organization,
	|	ChangesTable.Recorder AS Document
	|INTO _ChangesTableLossAllowance
	|FROM
	|	ChangesTableLossAllowance AS ChangesTable
	|WHERE
	|	VALUETYPE(ChangesTable.Recorder) <> TYPE(Document.OBEntry)
	|;";

	TempTablesQueryText =  TempTablesQueryText + RequestTextForCurrentAccountingPolicies(
		NameOfPreparedChangeTable, NameOfCurrentAccountingPoliciesTable) + ";";

	TemporaryTableNames = NameOfPreparedChangeTable + ", " + NameOfCurrentAccountingPoliciesTable;
	QueryText = RequestTextForTasksToCloseMonthWhenCalculationsAreChanged(NameOfCurrentAccountingPoliciesTable);
	Query.SetParameter("UndoPosting", UndoPosting);

	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText,
		TempTablesQueryText, TemporaryTableNames);
	Return StructureOfQueryTexts_;

EndFunction

#EndRegion

Function RequestTextStateOfFormationOfProvisionsForDoubtfulDebts()

	QueryTexts = New Array;

#Region OrganizationsWithReserves
	
	// Organizations for which it is possible to accrue reserves for doubtful debts according to the accounting policy.

	QueryText = "SELECT ALLOWED
	|	CatCompanies.ParentCompany AS Organization,
	|	CatCompanies.Ref AS BranchOffice,
	|	CatCompanies.ParentCompany <> CatCompanies.Ref AS ThisIsSeparateUnit
	|INTO TTParentOrganizations
	|FROM
	|	Catalog.Companies AS CatCompanies
	|WHERE
	|	CatCompanies.Ref IN(&CompanyArray)
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTParentOrganizations.Organization AS Organization
	|INTO OnlyParentOrganizations
	|FROM
	|	TTParentOrganizations AS TTParentOrganizations
	|
	|INDEX BY
	|	Organization";
	QueryTexts.Add(QueryText);

	QueryTexts.Add(QueryTextAccountingPolicyOfMa());
	QueryTexts.Add(AccrualAndWriteOffOfBadDebtAlowancesLocalization.RequestTextAccountingPolicyTa());

	QueryText =
	"SELECT DISTINCT
	|	ParentOrganizations.BranchOffice AS Ref,
	|	ISNULL(TTAccountingPolicyTa.GenerateTA, FALSE) AS GenerateTA,
	|	ISNULL(TTAccountingPolicyTa.PeriodicityTa, FALSE) AS PeriodicityTa,
	|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FormingMa, FALSE) AS FormingMa,
	|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FrequencyOfMa, FALSE) AS FrequencyOfMa
	|INTO Tt_OrganizationsWithReserves
	|FROM
	|	TTParentOrganizations AS ParentOrganizations
	|		LEFT JOIN TTAccountingPolicyTa AS TTAccountingPolicyTa
	|		ON ParentOrganizations.Organization = TTAccountingPolicyTa.Organization
	|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
	|		ON ParentOrganizations.Organization = TTAccountingPolicyOfFinancialAccounting.Organization
	|WHERE
	|	ISNULL(TTAccountingPolicyTa.GenerateTA, FALSE) = TRUE
	|	OR ISNULL(TTAccountingPolicyOfFinancialAccounting.FormingMa, FALSE) = TRUE
	|
	|INDEX BY
	|	Ref";

	QueryTexts.Add(QueryText);

#EndRegion

#Region OrganizationsToReview
	
	// Organizations that have manual adjustments in the calculation of reserves and the conditions of debt have changed.
	// For such organizations, manual user verification is required.

	QueryText =
	"SELECT DISTINCT
	|	Companies.Ref AS Organization,
	|	Reserves.Ref AS Document
	|INTO TT_OrganizationsToReview
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances AS Reserves
	|		INNER JOIN Document.AccrualAndWriteOffOfBadDebtAlowances.AccountsReceivable AS Debt_
	|		ON Reserves.Ref = Debt_.Ref
	|			AND (Debt_.CheckRequired)
	|		INNER JOIN Tt_OrganizationsWithReserves AS Companies
	|		ON Reserves.Organization = Companies.Ref
	|			AND (Reserves.Date = &EndOfPeriod)
	|			AND (Reserves.Posted)";

	QueryTexts.Add(QueryText);

#EndRegion

#Region OrganizationsReflected

	TextsAssociation = New Array;

	QueryText =
	"SELECT DISTINCT
	|	Reserves.Organization AS Organization
	|INTO TT_OrganizationsReflected
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances AS Reserves
	|WHERE
	|	Reserves.Organization IN (&CompanyArray)
	|	AND Reserves.Date = &EndOfPeriod
	|	AND Reserves.Posted
	|";

	TextsAssociation.Add(QueryText);
	AccrualAndWriteOffOfBadDebtAlowancesLocalization.RequestTextReservesOld(TextsAssociation);
	
	QueryTemplate = "
	|%1
	|	
	|INDEX BY
	|	Organization";
	QueryText = StrConcat(TextsAssociation, TMCommonUse.QuerySeparatorInJoin(True));
	QueryText = StrTemplate(QueryTemplate, QueryText);
	QueryTexts.Add(QueryText);     
	
	QueryText =
	"SELECT DISTINCT
	|	Reserves.Organization AS Organization
	|INTO TT_OrganizationsPostedInPastPeriods
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances AS Reserves
	|WHERE
	|	Reserves.Organization IN (&CompanyArray)
	|	AND Reserves.Date <= &EndOfPeriod
	|	AND Reserves.Posted";

	QueryTexts.Add(QueryText);
#EndRegion

#Region OrganizationsWithoutDocument

	// Organizations for which the reserve calculation documents have not yet been generated.
	// for separate divisions, it is checked that reserves are already being accounted for, but there is no document in the Cur month yet.
	
	QueryText =
	"SELECT
	|	AccrualAndWriteOffOfBadDebtAlowances.Organization AS Organization,
	|	MIN(AccrualAndWriteOffOfBadDebtAlowances.Date) AS Date
	|INTO TT_DateOfCommencementOfDocumentManagementReserves
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances AS AccrualAndWriteOffOfBadDebtAlowances,
	|	TTParentOrganizations AS TTParentOrganizations
	|WHERE
	|	AccrualAndWriteOffOfBadDebtAlowances.Date < &EndOfPeriod
	|	AND AccrualAndWriteOffOfBadDebtAlowances.Posted
	|	AND AccrualAndWriteOffOfBadDebtAlowances.Organization IN
	|			(SELECT
	|				TTParentOrganizations.BranchOffice AS BranchOffice
	|			FROM
	|				TTParentOrganizations AS TTParentOrganizations
	|			WHERE
	|				TTParentOrganizations.ThisIsSeparateUnit = TRUE)
	|
	|GROUP BY
	|	AccrualAndWriteOffOfBadDebtAlowances.Organization
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Reserves.Ref AS Organization
	|INTO TT_OrganizationsWithoutDocument
	|FROM
	|	Tt_OrganizationsWithReserves AS Reserves
	|		LEFT JOIN TT_OrganizationsReflected AS OrganizationsReflected
	|		ON Reserves.Ref = OrganizationsReflected.Organization
	|		LEFT JOIN TT_DateOfCommencementOfDocumentManagementReserves AS TT_DateOfCommencementOfDocumentManagementReserves
	|		ON Reserves.Ref = TT_DateOfCommencementOfDocumentManagementReserves.Organization
	|		INNER JOIN TTParentOrganizations AS TTParentOrganizations
	|		ON Reserves.Ref = TTParentOrganizations.BranchOffice
	|WHERE
	|	Reserves.Ref IN(&CompanyArray)
	|	AND OrganizationsReflected.Organization IS NULL
	|	AND CASE
	|			WHEN TTParentOrganizations.ThisIsSeparateUnit
	|				THEN NOT TT_DateOfCommencementOfDocumentManagementReserves.Date IS NULL
	|						AND TT_DateOfCommencementOfDocumentManagementReserves.Date <= &EndOfPeriod
	|			ELSE TRUE
	|		END";

	QueryTexts.Add(QueryText);

#EndRegion

#Region OrganizationsToReflect
	
	// Organizations for which the documents for calculating reserves have not yet been formed, but they should.
	// A separate warning is issued for such documents.

	QueryText =
	"SELECT DISTINCT
	|	Companies.Ref AS Organization
	|INTO TT_OrganizationsToReflect
	|FROM
	|	Tt_OrganizationsWithReserves AS Companies
	|		LEFT JOIN TT_OrganizationsReflected AS OrganizationsReflected
	|		ON Companies.Ref = OrganizationsReflected.Organization
	|WHERE
	|	OrganizationsReflected.Organization IS NULL";

	QueryTexts.Add(QueryText);

#EndRegion

	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());

	Return QueryText;

EndFunction
Procedure UpdateDebtWriteOffRegisteredRecordsAgainstReserves(Companies, Period)

	Query = New Query;
	Query.Text =
	"SELECT
	|	ARAPAdjustment.Date AS Period,
	|	ARAPAdjustment.Ref AS Document,
	|	ARAPAdjustment.Organization AS Organization,
	|	BEGINOFPERIOD(ARAPAdjustment.Date, DAY) AS DateRecord
	|FROM
	|	Document.ARAPAdjustment AS ARAPAdjustment
	|WHERE
	|	ARAPAdjustment.Organization IN (&Companies)
	|	AND ARAPAdjustment.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ARAPAdjustment.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|	AND ARAPAdjustment.Posted";

	Query.SetParameter("Companies", Companies);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Period));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Period));

	DocumentForRecord = Query.Execute().Unload();
	Recorders = DocumentForRecord.UnloadColumn("Document");

	UpdateComposition = New Structure;
	UpdateComposition.Insert("OtherExpenses", AccumulationRegisters.OtherExpenses);
	UpdateComposition.Insert("RecordsCounterpartyIncomeExpenses", AccumulationRegisters.RecordsCounterpartyIncomeExpenses);
	UpdateComposition.Insert("RecordsCounterpartyCounterparty", AccumulationRegisters.RecordsCounterpartyCounterparty);
	UpdateComposition.Insert("LossAllowance", AccumulationRegisters.LossAllowance);

	For Each Ref In Recorders Do
		UpdateDocumentRegisteredRecords(Ref, UpdateComposition);
	EndDo;

	LocalAccntingServer.ReturnDocumentsToReflection(DocumentForRecord);
	FinancialAccountingPostingServer.ReturnDocumentsToReflection(DocumentForRecord);
	If GetFunctionalOption("UseBalanceSheetStatement") 
		And Not GetFunctionalOption("NewOnlineARAPAccounting") Then
			DataProcessors.FlowOfAssetsAndLiabilities.ReflectDocumentsInManagementBalanceSheet(Recorders);
	EndIf; // It is necessary to form an upr. balance

EndProcedure

Procedure UpdateDocumentRegisteredRecords(Ref, UpdateComposition)

	Var Table;

	BeginTransaction();
	Try
		Tables = DocumentsPosting.DocumentDataForPosting(Ref, UpdateComposition);

		Date = Common.ObjectAttributeValue(Ref, "Date");
		Document = DocumentsPosting.DocumentEmulation(Ref, Date);
		TempTableManager = New TempTablesManager;

		For Each UpdateDetails1 In UpdateComposition Do
			If Tables.Property("Table" + UpdateDetails1.Key, Table) Then
				Set = UpdateDetails1.Value.CreateRecordSet(); // AccumulationRegisterRecordSet - 
				Set.Filter.Recorder.Set(Ref);
				Set.Load(Table);
				DocumentsPosting.SetAdditionalRegisterProperties(Set, Document, TempTableManager);
				Set.Write(True);
			EndIf;
		EndDo;

		DocumentsPosting.CreateTasksForDeferredRegisteredRecords(Document, TempTableManager);

		CommitTransaction();
	Except
		RollbackTransaction();
		MessageText = NStr("vi = 'Không thể ghi lại các lưu chuyển %RefreshEnabled% do %Cause% ';
							|ru = 'Не удалось записать движения %RefreshEnabled% по причине %Cause%';
							|en = 'Cannot record register records %RefreshEnabled%. Reason: %Cause%'; fa = 'Cannot record register records %RefreshEnabled%. Reason: %Cause%';
							|it = 'Impossibile registrare i movimenti %RefreshEnabled% a causa %Cause%';
							|pl = 'Nie można zapisać ruchu %RefreshEnabled% z powodu %Cause%';
							|tr = '%Cause% nedeniyle %RefreshEnabled% hareketleri kaydedilemedi'",
			Common.DefaultLanguageCode());
		MessageText = StrReplace(MessageText, "%RefreshEnabled%", UpdateDetails1.Key);
		MessageText = StrReplace(MessageText, "%Cause%", ErrorDescription());
		WriteLogEvent(
			NStr("vi = 'Cập nhật một phần các bản ghi kết chuyển của chứng từ';
				|ru = 'Частичное обновление движений документа';
				|en = 'Partial update of document records'; fa = 'Partial update of document records';
				|it = 'Aggiornamento parziale dei movimenti del documento';
				|pl = 'Częściowa aktualizacja ruchów dokumentu';
				|tr = 'Belge kayıtlarının kısmi güncellenmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , MessageText);
		Raise;
	EndTry;

EndProcedure

#EndRegion

#EndRegion

