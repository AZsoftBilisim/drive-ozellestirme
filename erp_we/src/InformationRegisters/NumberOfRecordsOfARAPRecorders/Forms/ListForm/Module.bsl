#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsFullUser = Users.IsFullUser();
	CommandBar.ChildItems.FormUpdateRegisterData.Visible = IsFullUser;
	
	If Parameters.Property("AutoTest_2") Or IsFullUser Then
		Return;
	EndIf;
	
	ReadOnly = True;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateRegisterData(Command)
	UpdateRegisterDataAtServer();
	Items.List.Refresh();
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure UpdateRegisterDataAtServer()

	DocumentsForProcessing_ = New ValueTable;
	DocumentsForProcessing_.Columns.Add("Document", New TypeDescription("DocumentRef.ARAPAccountingRecorder"));

	QueryDocuments = New Query;
	QueryDocuments.Text = "
	|SELECT
	|	SettlementRegistrars.Ref AS Document
	|FROM
	|	Document.ARAPAccountingRecorder AS SettlementRegistrars";

	SelectionOfDocuments = QueryDocuments.Execute().Select();
	NumberOfRecordsToBeProcessed = 0;

	While SelectionOfDocuments.Next() Do

		NumberOfRecordsToBeProcessed = NumberOfRecordsToBeProcessed + 1;
		FillPropertyValues(DocumentsForProcessing_.Add(), SelectionOfDocuments);

		If NumberOfRecordsToBeProcessed = 1000 Then
			ProcessRegisterData(DocumentsForProcessing_);
			DocumentsForProcessing_.Clear();
			NumberOfRecordsToBeProcessed = 0;
		EndIf;

	EndDo;

	If DocumentsForProcessing_.Count() > 0 Then
		ProcessRegisterData(DocumentsForProcessing_);
	EndIf;

EndProcedure

// Process a portion of documents and write the data to the register.
// 
// Parameters:
//  DocumentsForProcessing_ - ValueTable - Documents For Processing:
// * Document - DocumentRef.ARAPAccountingRecorder - 
//
&AtServerNoContext
Procedure ProcessRegisterData(DocumentsForProcessing_)
	
	Query = New Query;

	RequestSettlementsWithPartners = New Query;
	QueryTextCustomersARAPAccounting = "
	|SELECT
	|	Register.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Register.ARAPObject AS ARAPObject,
	|	Register.Currency AS Currency,
	|	""CustomersARAPAccountingByDueDates"" AS TableName,
	|	BEGINOFPERIOD(Register.Period, DAY) AS RecordPeriod,
	|	Register.Recorder AS Document,
	|	COUNT(Register.LineNumber) AS RecordsCount
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Register
	|WHERE
	|	Register.Recorder = &Recorder
	|GROUP BY
	|	Register.AccountingDimensionByPartners,
	|	Register.ARAPObject,
	|	Register.Currency,
	|	""CustomersARAPAccountingByDueDates"",
	|	BEGINOFPERIOD(Register.Period, DAY),
	|	Register.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	Register.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Register.ARAPObject AS ARAPObject,
	|	Register.Currency AS Currency,
	|	""CustomersARAPAccountingCashFlowPlan"" AS TableName,
	|	BEGINOFPERIOD(Register.Period, DAY) AS RecordPeriod,
	|	Register.Recorder AS Document,
	|	COUNT(Register.LineNumber) AS RecordsCount
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS Register
	|WHERE
	|	Register.Recorder = &Recorder
	|GROUP BY
	|	Register.AccountingDimensionByPartners,
	|	Register.ARAPObject,
	|	Register.Currency,
	|	""CustomersARAPAccountingCashFlowPlan"",
	|	BEGINOFPERIOD(Register.Period, DAY),
	|	Register.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	Register.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Register.ARAPObject AS ARAPObject,
	|	Register.Currency AS Currency,
	|	""CustomersARAPAccountingPlannedShipments"" AS TableName,
	|	BEGINOFPERIOD(Register.Period, DAY) AS RecordPeriod,
	|	Register.Recorder AS Document,
	|	COUNT(Register.LineNumber) AS RecordsCount
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingPlannedShipments AS Register
	|WHERE
	|	Register.Recorder = &Recorder
	|GROUP BY
	|	Register.AccountingDimensionByPartners,
	|	Register.ARAPObject,
	|	Register.Currency,
	|	""CustomersARAPAccountingPlannedShipments"",
	|	BEGINOFPERIOD(Register.Period, DAY),
	|	Register.Recorder";
	
	QueryTextVendorsARAPAccounting = "
	|SELECT
	|	Register.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Register.ARAPObject AS ARAPObject,
	|	Register.Currency AS Currency,
	|	""VendorsARAPAccountingByDueDates"" AS TableName,
	|	BEGINOFPERIOD(Register.Period, DAY) AS RecordPeriod,
	|	Register.Recorder AS Document,
	|	COUNT(Register.LineNumber) AS RecordsCount
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS Register
	|WHERE
	|	Register.Recorder = &Recorder
	|GROUP BY
	|	Register.AccountingDimensionByPartners,
	|	Register.ARAPObject,
	|	Register.Currency,
	|	""VendorsARAPAccountingByDueDates"",
	|	BEGINOFPERIOD(Register.Period, DAY),
	|	Register.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	Register.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Register.ARAPObject AS ARAPObject,
	|	Register.Currency AS Currency,
	|	""VendorsARAPAccountingCashFlowPlan"" AS TableName,
	|	BEGINOFPERIOD(Register.Period, DAY) AS RecordPeriod,
	|	Register.Recorder AS Document,
	|	COUNT(Register.LineNumber) AS RecordsCount
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan AS Register
	|WHERE
	|	Register.Recorder = &Recorder
	|GROUP BY
	|	Register.AccountingDimensionByPartners,
	|	Register.ARAPObject,
	|	Register.Currency,
	|	""VendorsARAPAccountingCashFlowPlan"",
	|	BEGINOFPERIOD(Register.Period, DAY),
	|	Register.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	Register.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Register.ARAPObject AS ARAPObject,
	|	Register.Currency AS Currency,
	|	""VendorsARAPAccountingPlannedDeliveries"" AS TableName,
	|	BEGINOFPERIOD(Register.Period, DAY) AS RecordPeriod,
	|	Register.Recorder AS Document,
	|	COUNT(Register.LineNumber) AS RecordsCount
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingPlannedDeliveries AS Register
	|WHERE
	|	Register.Recorder = &Recorder
	|GROUP BY
	|	Register.AccountingDimensionByPartners,
	|	Register.ARAPObject,
	|	Register.Currency,
	|	""VendorsARAPAccountingPlannedDeliveries"",
	|	BEGINOFPERIOD(Register.Period, DAY),
	|	Register.Recorder";

	Query = New Query();
	Query.Text = "
	|SELECT
	|	Data.Document AS Document
	|INTO TTDataToProcess
	|FROM
	|	&DocumentsForProcessing_ AS Data
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataToProcess.Document AS Document,
	|	ISNULL(ARAPAccountingRecorder.PaymentType_, VALUE(Enum.PartnersARAPAccountingTypes.EmptyRef)) AS PaymentType_
	|FROM
	|	TTDataToProcess AS TTDataToProcess
	|		LEFT JOIN Document.ARAPAccountingRecorder AS ARAPAccountingRecorder
	|		ON ARAPAccountingRecorder.Ref = TTDataToProcess.Document";
	Query.SetParameter("DocumentsForProcessing_", DocumentsForProcessing_);
	Selection = Query.Execute().Select();

	While Selection.Next() Do

		If Not ValueIsFilled(Selection.PaymentType_) Then
			Continue;
		EndIf;

		BeginTransaction();

		Try
			RecordSet = InformationRegisters.NumberOfRecordsOfARAPRecorders.CreateRecordSet();
			RecordSet.Filter.Document.Set(Selection.Document);

			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.NumberOfRecordsOfARAPRecorders");
			LockItem.SetValue("Document", Selection.Document);
			LockItem.Mode = DataLockMode.Exclusive;

			If Selection.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then

				RequestSettlementsWithPartners.Text = QueryTextCustomersARAPAccounting;

				LockItem = Block.Add("AccumulationRegister.CustomersARAPAccountingByDueDates.RecordSet");
				LockItem.SetValue("Recorder", Selection.Document);
				LockItem.Mode = DataLockMode.Exclusive;

				LockItem = Block.Add("AccumulationRegister.CustomersARAPAccountingCashFlowPlan.RecordSet");
				LockItem.SetValue("Recorder", Selection.Document);
				LockItem.Mode = DataLockMode.Exclusive;

				LockItem = Block.Add("AccumulationRegister.CustomersARAPAccountingPlannedShipments.RecordSet");
				LockItem.SetValue("Recorder", Selection.Document);
				LockItem.Mode = DataLockMode.Exclusive;

			Else

				RequestSettlementsWithPartners.Text = QueryTextVendorsARAPAccounting;

				LockItem = Block.Add("AccumulationRegister.VendorsARAPAccountingByDueDates.RecordSet");
				LockItem.SetValue("Recorder", Selection.Document);
				LockItem.Mode = DataLockMode.Exclusive;

				LockItem = Block.Add("AccumulationRegister.VendorsARAPAccountingCashFlowPlan.RecordSet");
				LockItem.SetValue("Recorder", Selection.Document);
				LockItem.Mode = DataLockMode.Exclusive;

				LockItem = Block.Add(
					"AccumulationRegister.VendorsARAPAccountingPlannedDeliveries.RecordSet");
				LockItem.SetValue("Recorder", Selection.Document);
				LockItem.Mode = DataLockMode.Exclusive;

			EndIf;

			Block.Lock();

			RequestSettlementsWithPartners.SetParameter("Recorder", Selection.Document);
			SamplingSettlementsWithPartners = RequestSettlementsWithPartners.Execute().Select();

			While SamplingSettlementsWithPartners.Next() Do
				Record = RecordSet.Add();
				FillPropertyValues(Record, SamplingSettlementsWithPartners);
			EndDo;

			RecordSet.Write();

			CommitTransaction();

		Except

			RollbackTransaction();
			MessageText = NStr("vi = 'Không thể cập nhật dữ liệu của biểu ghi ""Số lượng bản ghi của nguồn ghi hạch toán"": %Cause%';
								|ru = 'Не удалось обновить данные регистра ""Количество записей регистраторов расчетов"": %Cause%';
								|en = 'Cannot update data of the ""Number of records of AR/AP recorders"" register: %Cause%'; fa = 'Cannot update data of the ""Number of records of AR/AP recorders"" register: %Cause%';
								|it = 'Не удалось обновить данные регистра ""Количество записей регистраторов расчетов"": %Cause%';
								|pl = 'Cannot update data of the ""Number of records of AR/AP recorders"" register: %Cause%';
								|tr = '""Alacak/borç muhasebesi kaydedici girişlerinin sayısı"" kaydının verileri güncellenemedi: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(NStr("vi = 'Cập nhật dữ liệu của biểu ghi ""Số lượng bản ghi của nguồn ghi hạch toán""';
								|ru = 'Обновление данных регистра ""Количество записей регистраторов расчетов""';
								|en = 'Updating data of the ""Number of records of AR/AP recorders"" register'; fa = 'Updating data of the ""Number of records of AR/AP recorders"" register';
								|it = 'Обновление данных регистра ""Количество записей регистраторов расчетов""';
								|pl = 'Updating data of the ""Number of records of AR/AP recorders"" register';
								|tr = '""Alacak/borç muhasebesi kaydedici girişlerinin sayısı"" kayıt verilerinin güncellenmesi'"),
				EventLogLevel.Error, Metadata.InformationRegisters.NumberOfRecordsOfARAPRecorders,
				MessageText);

			Raise MessageText;

		EndTry;

	EndDo;

EndProcedure

#EndRegion

