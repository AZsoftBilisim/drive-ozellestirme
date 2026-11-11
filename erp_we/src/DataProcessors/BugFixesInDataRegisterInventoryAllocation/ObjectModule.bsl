#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure ErrorsCheckingCorrectnessOfInformationRegisterEntriesInventoryAllocationInBackground(Parameters, ResultAddress) Export
	
	ErrorTableIsTemporary = New ValueTable();
	ErrorTableIsTemporary.Columns.Add("Products");
	ErrorTableIsTemporary.Columns.Add("Characteristic");
	ErrorTableIsTemporary.Columns.Add("Warehouse");
	ErrorTableIsTemporary.Columns.Add("Purpose");
	Package = InventoryAllocation.ErrorsInCheckingCorrectnessOfInformationRegisterEntriesInventoryAllocation();
	For Counter = 1 To Package.Count() Do
		Table = Package[Counter - 1].Unload();
		For Each String In Table Do
			FillPropertyValues(ErrorTableIsTemporary.Add(), String);
		EndDo;
	EndDo;
	ErrorTableIsTemporary.GroupBy("Products,Characteristic,Warehouse,Purpose");
	PutToTempStorage(ErrorTableIsTemporary, ResultAddress);
	
EndProcedure

Procedure CorrectInformationRegisterErrorsInventoryAllocationInBackground(Parameters, ResultAddress) Export
	
	Table = Parameters.Analysts;
	
	ProcessingMessages = New Array();
	Query = New Query();
	Query.Text =
		"SELECT DISTINCT
		|	Table.ShipmentOrder AS Ref
		|FROM
		|	InformationRegister.InventoryAllocation AS Table
		|WHERE
		|	Table.Products = &Products
		|		AND Table.Characteristic = &Characteristic
		|		AND Table.Warehouse = &Warehouse
		|		AND Table.Purpose = &Purpose
		|		AND Table.ShipmentOrder <> UNDEFINED";
	
	For Each TableRow In Table Do
		
		TransactionCommitted = True;
		BeginTransaction();
		Try
			
			GetAvailableBalances = TypeOf(TableRow.Warehouse) = Type("CatalogRef.Warehouses")
				And ValueIsFilled(TableRow.Warehouse);
			
			Block = New DataLock();
			InventoryAllocation.AddLocks(Block, TableRow, Undefined, Undefined);
			Block.Lock();
			
			ValueInTable = Table.Copy(CommonClientServer.ValueInArray(TableRow));
			Query.SetParameter("Products", TableRow.Products);
			Query.SetParameter("Characteristic", TableRow.Characteristic);
			Query.SetParameter("Warehouse", TableRow.Warehouse);
			Query.SetParameter("Purpose", TableRow.Purpose);
			Orders = Query.Execute().Unload().UnloadColumn("Ref");
			
			AllocationResult = InventoryAllocation.UpdatingInformationSecurityByProduct(
				ValueInTable, "InventoryAllocation,AvailableStockBalances");
			
			Set = InformationRegisters.InventoryAllocation.CreateRecordSet();
			Set.Filter.Products.Set(TableRow.Products);
			Set.Filter.Characteristic.Set(TableRow.Characteristic);
			Set.Filter.Warehouse.Set(TableRow.Warehouse);
			Set.Filter.Purpose.Set(TableRow.Purpose);
			Set.Load(AllocationResult.InventoryAllocation.Copy(New Structure("IsEmpty", False)));
			
			Set.Write();
			
			If GetAvailableBalances Then
				Set = InformationRegisters.AvailableStockBalances.CreateRecordSet();
				Set.Filter.Products.Set(TableRow.Products);
				Set.Filter.Characteristic.Set(TableRow.Characteristic);
				Set.Filter.Warehouse.Set(TableRow.Warehouse);
				Set.Filter.Purpose.Set(TableRow.Purpose);
				
				For Each ResultString1 In AllocationResult.AvailableStockBalances Do
					
					If Not TableRow.Purpose.IsEmpty() And ResultString1.Purpose.IsEmpty() Then
						// The calculation result for non-empty assignments includes summary records for an empty assignment
						// (all assignments). There is no need to write such entries to the set,
						// they will be calculated and recorded when processing goods with an empty destination.
						Continue;
					EndIf;
					
					If ResultString1.InStock = 0 And ResultString1.Available = 0 Then
						Continue;
					EndIf;
					
					FillPropertyValues(Set.Add(), ResultString1);
					
				EndDo;
				Set.Write();
			EndIf;
			
			InventoryAllocation.ExcludeLinksThatRequireDeferredUpdates(Orders);
			
			RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
			RegistersToBeReflected.SalesOrderStates    = True;
			RegistersToBeReflected.StatusesOfInternalOrders  = True;
			RegistersToBeReflected.ProductionStageStates = True;
			DocumentsStates.AddTasksToStateOfOrders(Undefined, Orders,, RegistersToBeReflected);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			TransactionCommitted = False;
			MessageText = NStr("vi = 'Nhiệm vụ phân bổ vật tư đã kết thúc không thành công do nguyên nhân: %Cause%';
								|ru = 'Задание распределения запасов завершилось неудачно по причине: %Cause%';
								|en = 'Inventory allocation job failed. Reason: %Cause%'; fa = 'Inventory allocation job failed. Reason: %Cause%';
								|it = 'Task di distribuzione delle scorte non è riuscito a causa di: %Cause%';
								|pl = 'Zadanie przydzielenia zapasów zakończyło się nieudanie z powodu: %Cause%';
								|tr = 'Stok dağıtım görevi şu nedenle başarısız oldu: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			LogEvent = NStr("vi = 'Phân bổ vật tư';
							|ru = 'Распределение запасов';
							|en = 'Inventory allocation'; fa = 'تسهیم موجودی';
							|it = 'Distribuzione delle scorte';
							|pl = 'Przydzielenie zapasów';
							|tr = 'Stok dağıtımı'", Common.DefaultLanguageCode());
			WriteLogEvent(LogEvent,
			                         EventLogLevel.Error,
			                         Metadata.InformationRegisters.InventoryAllocation,
			                         ,
			                         MessageText);
			
		EndTry;
		
		If TransactionCommitted Then
			
			MessageText = StrTemplate(NStr("vi = 'Đã xử lý. Hàng hóa: %1, %2, Kho bãi: %3, Mục đích: %4';
											|ru = 'Обработан. Товар: %1, %2, Склад: %3, Назначение:%4';
											|en = 'Processed. Goods item: %1, %2, Warehouse: %3, Purpose:%4'; fa = 'Processed. Goods item: %1, %2, Warehouse: %3, Purpose:%4';
											|it = 'Elaborato. Prodotto: %1, %2, Magazzino: %3, Assegnazione: %4';
											|pl = 'Przetw. Towar: %1, %2, Magazyn: %3, Przeznaczenie:%4';
											|tr = 'İşlendi. Ürün: %1, %2, Ambar: %3, Atama:%4'"),
				TableRow.Products,
				TableRow.Characteristic,
				TableRow.Warehouse,
				TableRow.Purpose);
			ProcessingMessages.Add(MessageText);
			
		Else
			
			MessageText = StrTemplate(NStr("vi = 'Lỗi xử lý. Hàng hóa: %1, %2, Kho bãi: %3, Mục đích:%4';
											|ru = 'Ошибка обработки. Товар: %1, %2, Склад: %3, Назначение:%4';
											|en = 'Processing error. Goods item: %1, %2, Warehouse: %3, Purpose:%4'; fa = 'Processing error. Goods item: %1, %2, Warehouse: %3, Purpose:%4';
											|it = 'Errore di elaborazione. Prodotto: %1, %2, Magazzino: %3, Assegnazione: %4';
											|pl = 'Błąd przetwarzania. Towar: %1, %2, Magazyn: %3, Przeznaczenie:%4';
											|tr = 'İşleme hatası. Ürün: %1, %2, Ambar: %3, Atama:%4'"),
				TableRow.Products,
				TableRow.Characteristic,
				TableRow.Warehouse,
				TableRow.Purpose);
			ProcessingMessages.Add(MessageText);
			
		EndIf;
		
	EndDo;
	
	Result = New Structure("Messages", ProcessingMessages);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure



#EndRegion

#EndIf