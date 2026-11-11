#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.PlannedOtherCosts.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("ec824f00-607b-4cd5-8280-d6233d6b55e4");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.PlannedOtherCosts.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Chuyển đổi kiểu cột ""Khóa lô hàng"" trong biểu ghi tích lũy ""Chi phí dự tính khác"".';
							|ru = 'Конвертация типа колонки ""Ключ партия"" регистра накопления ""Плановые прочие затраты"".';
							|en = 'Conversion of the ""Key lot"" column type of the ""Planned other costs"" accumulation register.'; fa = 'Conversion of the ""Key lot"" column type of the ""Planned other costs"" accumulation register.';
							|it = 'Conversion of the ""Key lot"" column type of the ""Planned other costs"" accumulation register.';
							|pl = 'Conversion of the ""Key lot"" column type of the ""Planned other costs"" accumulation register.';
							|tr = '""Planlanan Diğer Giderler"" birikim kayıt tablosunun ""Anahtar Lot"" sütun tipinin dönüştürülmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.PlannedOtherCosts.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.PlannedOtherCosts.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.PlannedOtherCosts.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();

	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.PlannedOtherCosts.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.PlannedOtherCosts";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	QueryText = "SELECT DISTINCT
	|	DD.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.PlannedOtherCosts AS DD
	|
	|WHERE
	// It makes sense to convert column values only for those documents that have the Keyparty value filled in at least one line.
	|	DD.DeleteKeyLot IS NOT NULL
	|	AND DD.DeleteKeyLot <> &EmptyUID";
	
	Query = New Query(QueryText);
	Query.SetParameter("EmptyUID", CommonClientServer.BlankUUID());
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(
		Parameters,
		Recorders,
		FullRegisterName);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.PlannedOtherCosts";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			DataLock = New DataLock;
			
			LockItem = DataLock.Add("AccumulationRegister.PlannedOtherCosts.RecordSet");
			LockItem.SetValue("Recorder", Selection.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();
			
			RecordSet = AccumulationRegisters.PlannedOtherCosts.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				Record.KeyLot = String(Record.DeleteKeyLot);
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StrTemplate(
					NStr("vi = 'Không thể ghi dữ liệu vào biểu ghi tích lũy ""Chi phí nguyên vật liệu dự tính"" theo bảng giá thành dự tính ""%1"", do nguyên nhân: %2';
						|ru = 'Не удалось записать данные в регистр накопления ""Плановые прочие затраты"" по плановой калькуляции ""%1"", по причине: %2';
						|en = 'Cannot write data to the ""Planned other costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2'; fa = 'Cannot write data to the ""Planned other costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2';
						|it = 'Cannot write data to the ""Planned other costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2';
						|pl = 'Cannot write data to the ""Planned other costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2';
						|tr = '""%1"" standart ürün maliyeti için ""Planlanan Diğer Giderler"" birikim kayıt tablosuna şu nedenden dolayı veri yazılamadı: %2'"),
					Selection.Recorder,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				Metadata.AccumulationRegisters.PlannedOtherCosts,,
				MessageText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
		Parameters.Queue,
		FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf