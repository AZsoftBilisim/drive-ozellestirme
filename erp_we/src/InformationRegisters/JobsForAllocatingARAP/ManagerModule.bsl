#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// Adds procedures to the list that handle updating information security
// data for all supported library versions or configurations.
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Value tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly Mode = False;
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.JobsForAllocatingARAP.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.23.17";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("1ff77d60-ecd2-11e4-92f1-0050568b35ac");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.JobsForAllocatingARAP.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Ghi nhận nhiệm vụ phân bổ hạch toán công nợ';
							|ru = 'Регистрация заданий к распределению взаиморасчетов';
							|en = 'Register jobs for allocating AR/AP'; fa = 'Register jobs for allocating AR/AP';
							|it = 'Register jobs for allocating AR/AP';
							|pl = 'Register jobs for allocating AR/AP';
							|tr = 'Alacak/Borç muhasebesi dağıtımı görevlerinin kaydı'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.JobsForAllocatingARAP.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.JobsForAllocatingARAP.FullName());
	Editable1.Add(Metadata.InformationRegisters.JobsForARAPAllocating.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.JobsForAllocatingARAP";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.JobsForAllocatingARAP");

	Query = New Query;
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	Query.Text =
	"SELECT
	|	JobsForAllocatingARAP.PaymentType_ AS PaymentType_,
	|	JobsForAllocatingARAP.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	JobsForAllocatingARAP.ARAPObject AS ARAPObject,
	|	JobsForAllocatingARAP.Currency AS Currency
	|FROM
	|	InformationRegister.JobsForAllocatingARAP AS JobsForAllocatingARAP
	|WHERE
	|	&NewOnlineARAPAccounting";
	
	Tuples = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Tuples, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "InformationRegister.JobsForAllocatingARAP";
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	AllocateARAPInBackgroundJob = Constants.AllocateARAPInBackgroundJob.Get();

	Query = New Query;
	Query.Text = "
	|SELECT
	|	Data.PaymentType_ AS PaymentType_,
	|	Data.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Data.ARAPObject AS ARAPObject,
	|	Data.Currency AS Currency
	|INTO TTDataToProcess
	|FROM
	|	&UpdatedData AS Data
	|
	|INDEX BY
	|	PaymentType_,
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataToProcess.PaymentType_ AS PaymentType_,
	|	TTDataToProcess.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTDataToProcess.ARAPObject AS ARAPObject,
	|	TTDataToProcess.Currency AS Currency,
	|	MIN(ISNULL(Jobs.RecountDate, DATETIME(3999, 12, 31, 23, 59, 59))) AS RecountDate
	|FROM
	|	TTDataToProcess AS TTDataToProcess
	|		LEFT JOIN InformationRegister.JobsForAllocatingARAP AS Jobs
	|		ON TTDataToProcess.PaymentType_ = Jobs.PaymentType_
	|		AND TTDataToProcess.AccountingDimensionByPartners = Jobs.AccountingDimensionByPartners
	|		AND TTDataToProcess.ARAPObject = Jobs.ARAPObject
	|		AND Jobs.Currency = TTDataToProcess.Currency
	|GROUP BY
	|	TTDataToProcess.PaymentType_,
	|	TTDataToProcess.AccountingDimensionByPartners,
	|	TTDataToProcess.ARAPObject,
	|	TTDataToProcess.Currency";
	Query.SetParameter("UpdatedData", UpdatedData);
	Selection = Query.Execute().Select();
		
	RequestSettlementsWithPartners = New Query;
	QueryTextCustomersARAPAccounting = "
	|SELECT
	|	MIN(CustomersARAPAccounting.Period) AS TaskPeriod,
	|	CustomersARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	CustomersARAPAccounting.Currency AS Currency,
	|	CustomersARAPAccounting.Recorder AS Document
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|	AND CustomersARAPAccounting.ARAPObject = &ARAPObject
	|	AND CustomersARAPAccounting.Currency = &Currency
	|	AND CustomersARAPAccounting.Active
	|	AND (CustomersARAPAccounting.Sum <> 0
	|	OR CustomersARAPAccounting.AmountDue <> 0
	|	OR CustomersARAPAccounting.ToShip <> 0)
	|	AND CustomersARAPAccounting.Period >= &Period
	|GROUP BY
	|	CustomersARAPAccounting.AccountingDimensionByPartners.Organization,
	|	CustomersARAPAccounting.AccountingDimensionByPartners,
	|	CustomersARAPAccounting.ARAPObject,
	|	CustomersARAPAccounting.Currency,
	|	CustomersARAPAccounting.Recorder";
	
	QueryTextVendorsARAPAccounting = "
	|SELECT
	|	MIN(VendorsARAPAccounting.Period) AS TaskPeriod,
	|	VendorsARAPAccounting.AccountingDimensionByPartners.Organization AS Organization,
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.Currency AS Currency,
	|	VendorsARAPAccounting.Recorder AS Document
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|WHERE
	|	VendorsARAPAccounting.AccountingDimensionByPartners = &AccountingDimensionByPartners
	|	AND VendorsARAPAccounting.ARAPObject = &ARAPObject
	|	AND VendorsARAPAccounting.Currency = &Currency
	|	AND VendorsARAPAccounting.Active
	|	AND (VendorsARAPAccounting.Sum <> 0
	|	OR VendorsARAPAccounting.AmountDue <> 0
	|	OR VendorsARAPAccounting.ToReceive <> 0)
	|	AND VendorsARAPAccounting.Period >= &Period
	|GROUP BY
	|	VendorsARAPAccounting.AccountingDimensionByPartners.Organization,
	|	VendorsARAPAccounting.AccountingDimensionByPartners,
	|	VendorsARAPAccounting.ARAPObject,
	|	VendorsARAPAccounting.Currency,
	|	VendorsARAPAccounting.Recorder";

	MaximumPeriod = Date(3999, 12, 31, 23, 59, 59);
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;

	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr(
			"vi = 'Không thể xử lý nhiệm vụ theo hàm sự kiện của biểu ghi thông tin ""Nhiệm vụ phân bổ hạch toán"".';
			|ru = 'Не удалось обработать задания по обработчику регистра сведений ""Задания к распределению расчетов"".';
			|en = 'Cannot process the jobs of the ""Jobs for allocating AR/AP"" information register handler:'; fa = 'Cannot process the jobs of the ""Jobs for allocating AR/AP"" information register handler:';
			|it = 'Cannot process the jobs of the ""Jobs for allocating AR/AP"" information register handler:';
			|pl = 'Cannot process the jobs of the ""Jobs for allocating AR/AP"" information register handler:';
			|tr = '""Hesaplamaların dağıtım görevleri"" bilgi kaydı işleyicisi kapsamında görevler işlenemedi.'"));
		
	While Selection.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
			
		BeginTransaction();
		
		Try
			
			RecordSet = CreateRecordSet();
			RecordSet.Filter.PaymentType_.Set(Selection.PaymentType_);
			RecordSet.Filter.AccountingDimensionByPartners.Set(Selection.AccountingDimensionByPartners);
			RecordSet.Filter.ARAPObject.Set(Selection.ARAPObject);
			RecordSet.Filter.Currency.Set(Selection.Currency);
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			// Blocking of the register "Tasks for the distribution of calculations".
			LockItem = Block.Add("InformationRegister.JobsForAllocatingARAP");
			LockItem.SetValue("PaymentType_", Selection.PaymentType_);
			LockItem.SetValue("AccountingDimensionByPartners", Selection.AccountingDimensionByPartners);
			LockItem.SetValue("ARAPObject", Selection.ARAPObject);
			LockItem.SetValue("Currency", Selection.Currency);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			ExceptionReason = 2; // Data processing
			RecommendationTemplate = NStr(
				"vi = 'Bắt đầu từ kỳ %1 theo đối tượng hạch toán: %2, cần thực hiện phân bổ hạch toán công nợ.';
				|ru = 'Начиная с периода %1 по объекту расчетов: %2 необходимо выполнить распределение взаиморасчетов.';
				|en = 'Allocate AR/AP for the ""%2"" AR/AP object starting from the period of %1.'; fa = 'Allocate AR/AP for the ""%2"" AR/AP object starting from the period of %1.';
				|it = 'Allocate AR/AP for the ""%2"" AR/AP object starting from the period of %1.';
				|pl = 'Allocate AR/AP for the ""%2"" AR/AP object starting from the period of %1.';
				|tr = '%1 döneminden itibaren Alacak/Borç nesnesine göre: %2 karşılıklı mutabakatların dağıtımını yapmak gerekmektedir.'");
			Recommendation =  StringFunctionsClientServer.SubstituteParametersToString(RecommendationTemplate,
				Selection.RecountDate, Selection.ARAPObject);

			If AllocateARAPInBackgroundJob Then
				
				If Not Selection.RecountDate = MaximumPeriod Then

					If Selection.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then

						RequestSettlementsWithPartners.Text = QueryTextCustomersARAPAccounting;
						
					Else

						RequestSettlementsWithPartners.Text = QueryTextVendorsARAPAccounting;

					EndIf;

					RequestSettlementsWithPartners.SetParameter("Period", Selection.RecountDate);
					RequestSettlementsWithPartners.SetParameter("AccountingDimensionByPartners",
						Selection.AccountingDimensionByPartners);
					RequestSettlementsWithPartners.SetParameter("ARAPObject", Selection.ARAPObject);
					RequestSettlementsWithPartners.SetParameter("Currency", Selection.Currency);
					SamplingSettlementsWithPartners = RequestSettlementsWithPartners.Execute().Select();

					SetOfJobRecords = InformationRegisters.JobsForARAPAllocating.CreateRecordSet();

					While SamplingSettlementsWithPartners.Next() Do
						CreateTasksForDocument(SetOfJobRecords, SamplingSettlementsWithPartners);
					EndDo;

					SetOfJobRecords.Write(False);

				EndIf;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			
			RecordSet.Write();
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();

		Except

			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.ARAPObject);

			If ExceptionReason = 2 Then

				IssueDetails = InfobaseUpdateTM.DataProblem(
						Selection.ARAPObject, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);

			ElsIf ExceptionReason = 3 Then

				InfobaseUpdateTM.RecordBadData(
						ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);

			EndIf;
			
		EndTry;

	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then

		ListOfDescriptions.Add(NStr("vi = 'Tổng số bỏ qua: %1';
									|ru = 'Всего пропущено: %1';
									|en = 'Total skipped: %1'; fa = 'Total skipped: %1';
									|it = 'Всего пропущено: %1';
									|pl = 'Total skipped: %1';
									|tr = 'Toplam atlanan: %1'"));
		MessageText = StrTemplate(StrConcat(ListOfDescriptions, Chars.LF), ObjectsWithIssuesCount);
		Raise MessageText;

	Else

		MessageTemplate = NStr("vi = 'Biểu ghi thông tin ""Nhiệm vụ cần phân bổ hạch toán"". Đã xử lý phần nhiệm vụ: %1';
								|ru = 'Регистр сведений ""Задания к распределению расчетов"". Обработана порция заданий: %1';
								|en = 'The ""Jobs for allocating AR/AP"" information register. A batch of jobs is processed: %1'; fa = 'The ""Jobs for allocating AR/AP"" information register. A batch of jobs is processed: %1';
								|it = 'The ""Jobs for allocating AR/AP"" information register. A batch of jobs is processed: %1';
								|pl = 'The ""Jobs for allocating AR/AP"" information register. A batch of jobs is processed: %1';
								|tr = '""Hesaplamaların dağıtım görevleri"" bilgi kaydı. Görevlerin bir kısmı işlenmiştir: %1'");
		MessageText = StrTemplate(MessageTemplate, ObjectsProcessed);
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(), EventLogLevel.Information, , ,
			MessageText);

	EndIf;

	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

Procedure CreateTasksForDocument(SetOfJobRecords, JobParameters)

	NewJob = SetOfJobRecords.Add();
	NewJob.Organization = JobParameters.Organization;
	NewJob.TaskPeriod = JobParameters.TaskPeriod;
	NewJob.RecordID = New UUID;
	NewJob.AccountingDimensionByPartners = JobParameters.AccountingDimensionByPartners;
	NewJob.ARAPObject = JobParameters.ARAPObject;
	NewJob.Currency = JobParameters.Currency;
	NewJob.Document = JobParameters.Document;
	NewJob.RecordDate = CurrentSessionDate();

EndProcedure

#EndRegion

#EndRegion

#EndIf
