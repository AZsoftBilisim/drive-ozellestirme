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
	|	ValueAllowed(Warehouse)";
	
	Restriction.TextForExternalUsers1 = Restriction.Text;

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();

	// The register "Available Balances of items" is filled in by this processor according to the current data of the register "Inventories and needs". 
	// If it is necessary to update the data in connection with the update of the data in the register "Inventory and needs",
	// a separate handler of a lower queue is required.
	
	Handler.Procedure = "InformationRegisters.AvailableStockBalances.ProcessDataForInitialFilling";
	Handler.Version = "11.5.26.65";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("9bdc859a-f917-11f0-8de9-0242ac120002");
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.AvailableStockBalances.RegisterInitialFillingData";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền biểu ghi thông tin ""Tồn kho hàng hóa khả dụng"" theo dữ liệu của biểu ghi tích lũy ""Tồn kho và nhu cầu"".
		|Dữ liệu của biểu ghi này được sử dụng, đặc biệt, để hiển thị tồn kho khi chọn hàng hóa trong các chứng từ bán hàng.';
		|ru = 'Заполняет регистр сведений ""Доступные остатки товаров"" по данным регистра накопления ""Запасы и потребности"".
		|Данные регистра используются, в частности, для отображения остатков при подборе товаров в документы продажи.';
		|en = 'Fills the ""Available stock balances"" information register according to the ""Inventory and demands"" accumulation register data.
		|The register data is used to display balances when picking goods in sales documents.'; fa = 'Fills the ""Available stock balances"" information register according to the ""Inventory and demands"" accumulation register data.
		|The register data is used to display balances when picking goods in sales documents.';
		|it = 'Fills the ""Available stock balances"" information register according to the ""Inventory and demands"" accumulation register data.
		|The register data is used to display balances when picking goods in sales documents.';
		|pl = 'Fills the ""Available stock balances"" information register according to the ""Inventory and demands"" accumulation register data.
		|The register data is used to display balances when picking goods in sales documents.';
		|tr = '""Mevcut ürün bakiyeleri"" bilgi kaydını, ""Stoklar ve gereksinimler"" birikim kaydı verilerine göre doldurur. 
		| Kayıt verileri, özellikle satış belgelerine ürün seçilirken bakiyelerin görüntülenmesi için kullanılır.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.AvailableStockBalances.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.AvailableStockBalances.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	// The peculiarity of the PC is "Affordable cost of goods". It does not migrate directly, but is recalculated during the migration of the PH "Inventory and needs".
	// The current handler is not related to changes in the PH of "Inventory and needs", so it needs to be executed directly in a subordinate node.
	Handler.ExecuteInMasterNodeOnly = False;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.AvailableStockBalances.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

Procedure RegisterInitialFillingData(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.AvailableStockBalances";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.AvailableStockBalances");
	
	// Previously, Balance data was stored in the Inventory allocation information register.
	Query = New Query();
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose
		|FROM
		|	InformationRegister.InventoryAllocation AS Table
		|WHERE
		|	Table.InventoryState = VALUE(Enum.InventoryStates.EmptyRef)
		|		AND Table.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND VALUETYPE(Table.Warehouse) = TYPE(Catalog.Warehouses)
		|		AND Table.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)";
	
	RecordedMeasurements = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, RecordedMeasurements, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForInitialFilling(Parameters) Export
	
	FullRegisterName = "InformationRegister.AvailableStockBalances";
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	TableUpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	BatchProcessingFailed = False;
	
	Set = CreateRecordSet();
	Set.Filter.Products.Use = True;
	Set.Filter.Characteristic.Use = True;
	Set.Filter.Warehouse.Use = True;
	Set.Filter.Purpose.Use = True;
	
	BeginTransaction();
	Try
		Block = New DataLock();
		InventoryAllocation.AddLocks(Block, Undefined, TableUpdatedData, TableUpdatedData);
		Block.Lock();
		AllocationResult = InventoryAllocation.UpdatingInformationSecurityByProduct(TableUpdatedData, "AvailableStockBalances");
		TotalRows = AllocationResult.AvailableStockBalances.Count();
		AnalyticsAreInCalculationTasks = True;
		For IndexOf = 0 To TotalRows - 1 Do
			TableRow = AllocationResult.AvailableStockBalances[IndexOf];
			If Set.Filter.Products.Value <> TableRow.Products
					Or Set.Filter.Characteristic.Value <> TableRow.Characteristic
					Or Set.Filter.Warehouse.Value <> TableRow.Warehouse
					Or Set.Filter.Purpose.Value <> TableRow.Purpose Then
						
						If IndexOf > 0 Then
							
							If AnalyticsAreInCalculationTasks Then
								InfobaseUpdate.WriteRecordSet(Set, True, False);
							EndIf;
							Set.Clear();
						EndIf;
						
						Set.Filter.Products.Value = TableRow.Products;
						Set.Filter.Characteristic.Value = TableRow.Characteristic;
						Set.Filter.Warehouse.Value = TableRow.Warehouse;
						Set.Filter.Purpose.Value = TableRow.Purpose;
						
			EndIf;
			
			AnalyticsAreInCalculationTasks = TableRow.AnalyticsAreInCalculationTasks;
			If TableRow.InStock = 0 And TableRow.Available = 0 Then
				Continue;
			EndIf;
			
			FillPropertyValues(Set.Add(), TableRow);
			
		EndDo;
		If TotalRows > 0 Then
			If AnalyticsAreInCalculationTasks Then
				InfobaseUpdate.WriteRecordSet(Set, True, False);
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		BatchProcessingFailed = True;
	EndTry;
	
	If BatchProcessingFailed Then
		For Each String In TableUpdatedData Do
			
			Set = Undefined;
			
			BeginTransaction();
			Try
				
				Block = New DataLock();
				InventoryAllocation.AddLocks(Block, String, Undefined, Undefined);
				Block.Lock();
				
				ValueInTable = TableUpdatedData.Copy(CommonClientServer.ValueInArray(String));
				AllocationResult = InventoryAllocation.UpdatingInformationSecurityByProduct(ValueInTable, "AvailableStockBalances");
				
				Set = InformationRegisters.AvailableStockBalances.CreateRecordSet();
				Set.Filter.Products.Set(String.Products);
				Set.Filter.Characteristic.Set(String.Characteristic);
				Set.Filter.Warehouse.Set(String.Warehouse);
				Set.Filter.Purpose.Set(String.Purpose);
				
				For Each ResultString1 In AllocationResult.AvailableStockBalances Do
					
					If Not String.Purpose.IsEmpty() And ResultString1.Purpose.IsEmpty() Then
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
				
				// The third parameter is "False", since the current handler is not related to correcting the Balance data,
				// but is related to changing the data storage format.
				InfobaseUpdate.WriteRecordSet(Set, True, False);
				CommitTransaction();
				
			Except
				RollbackTransaction();
				If Set = Undefined Then
					Set = CreateRecordSet();
					Set.Filter.Products.Set(String.Products);
					Set.Filter.Characteristic.Set(String.Characteristic);
					Set.Filter.Warehouse.Set(String.Warehouse);
					Set.Filter.Purpose.Set(String.Purpose);
				EndIf;
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Set);
			EndTry;
			
		EndDo;
	EndIf;
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
