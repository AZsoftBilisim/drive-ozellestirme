
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.53";
	Handler.ExecutionMode = "Deferred";
	Handler.Multithreaded = True;
	Handler.Id = New UUID("e6b0c3d6-5441-4a70-bf31-ff8d2dc640cf");
	Handler.UpdateDataFillingProcedure = "InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = 
		NStr("vi = 'Đang cập nhật biểu ghi ""Quy trình hạch toán TSCĐ vô hình (KTDN)"":
			 |- thiết lập trạng thái ""Chưa nhận vào kế toán"" trong KTTh, nếu doanh nghiệp không phải là đối tượng nộp thuế thu nhập.';
			 |ru = 'Обновляет регистр ""Порядок учета НМА (БУ)"":
			 |- устанавливает состояние ""Не принят к учету"" в НУ, если организация не является плательщиком налога на прибыль';
			 |en = 'Updates the ""Intangible assets accounting procedure (LA)"" register:
			 |- Sets the ""Not recognized"" state in TA if the company is not an income tax payer'; fa = 'Updates the ""Intangible assets accounting procedure (LA)"" register:
			 |- Sets the ""Not recognized"" state in TA if the company is not an income tax payer';
			 |it = 'Updates the ""Intangible assets accounting procedure (LA)"" register:
			 |- Sets the ""Not recognized"" state in TA if the company is not an income tax payer';
			 |pl = 'Updates the ""Intangible assets accounting procedure (LA)"" register:
			 |- Sets the ""Not recognized"" state in TA if the company is not an income tax payer';
			 |tr = '""Maddi olmayan varlıkların muhasebe prosedürü (Genel muhasebe)"" kaydını günceller:
			 |- İş yeri gelir vergisi mükellefi değilse, vergi sistemindeki durumu ""Muhasebeye kabul edilmedi"" olarak ayarlar'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullObjectName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();

	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			DataLock = New DataLock;
			
			LockItem = DataLock.Add("InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.RecordSet");
			LockItem.SetValue("Recorder", Selection.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();
			
			RecordSet = InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				Record.StateTa = Enums.IntangibleAssetsStates.NotPostedInFinancialAccounting;
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StrTemplate(
					NStr("vi = 'Không thể ghi lại dữ liệu vào biểu ghi ""Quy trình hạch toán TSCĐ vô hình (kế toán doanh nghiệp và kế toán thuế)"" theo chứng từ ""%1"", do: %2';
						|ru = 'Не удалось записать данные в регистр ""Порядок учета НМА (бухгалтерский и налоговый учет)"" по документу ""%1"", по причине: %2';
						|en = 'Cannot record the %1 document data to the ""Intangible assets accounting procedure (local and tax accounting)"" register. Reason: %2'; fa = 'Cannot record the %1 document data to the ""Intangible assets accounting procedure (local and tax accounting)"" register. Reason: %2';
						|it = 'Cannot record the %1 document data to the ""Intangible assets accounting procedure (local and tax accounting)"" register. Reason: %2';
						|pl = 'Cannot record the %1 document data to the ""Intangible assets accounting procedure (local and tax accounting)"" register. Reason: %2';
						|tr = '""%1"" belgesi için ""Maddi olmayan varlıkların muhasebe prosedürü (genel muhasebe ve vergi muhasebesi)"" kaydına veri yazma işlemi şu nedenden dolayı başarısız oldu: %2'"),
					Selection.Recorder,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				Metadata.InformationRegisters.IABookkeepingProcedureBookkeepingAndTaxAccounting,,
				MessageText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
