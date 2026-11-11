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

	// The register "Inventory distribution" is filled in by this processor according to the current data of the register "Inventory and needs". 
	// If it is necessary to update the Inventory distribution in connection with the update of data in the Inventory and Needs register,
	// a separate handler of a lower queue is required.
	
	Handler.Procedure = "InformationRegisters.InventoryAllocation.ProcessStorageFormatChanges";
	Handler.Version = "11.5.26.65";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a14ede29-84e0-43a5-8a5a-e86839420447");
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.InventoryAllocation.RegisterDataForChangingStorageFormat";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền lại biểu ghi thông tin ""Phân bổ tồn kho"" theo dữ liệu của biểu ghi tích lũy ""Tồn kho và nhu cầu""
	|do sự thay đổi cấu trúc dữ liệu của biểu ghi thông tin ""Phân bổ tồn kho"".';
	|ru = 'Перезаполняет регистр сведений ""Распределение запасов"" по данным регистра накопления ""Запасы и потребности""
	| в связи с изменением структуры данных регистра сведений ""Распределение запасов"".';
	|en = 'Refills the ""Inventory allocation"" information register according to the ""Inventory and demands"" accumulation register data
	| due to a change in the data structure of the ""Inventory allocation"" information register.'; fa = 'Refills the ""Inventory allocation"" information register according to the ""Inventory and demands"" accumulation register data
	| due to a change in the data structure of the ""Inventory allocation"" information register.';
	|it = 'Refills the ""Inventory allocation"" information register according to the ""Inventory and demands"" accumulation register data
	| due to a change in the data structure of the ""Inventory allocation"" information register.';
	|pl = 'Refills the ""Inventory allocation"" information register according to the ""Inventory and demands"" accumulation register data
	| due to a change in the data structure of the ""Inventory allocation"" information register.';
	|tr = 'Stok dağıtımı'' bilgi kaydının veri yapısındaki değişiklik nedeniyle, stok dağıtımı'' bilgi kaydını, ""Stoklar ve gereksinimler"" birikim kaydı verilerine göre yeniden doldurur. 
	| '");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.InventoryAllocation.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.InventoryAllocation.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	// A feature of the RS is "Inventory distribution". It does not migrate directly, but is recalculated during the migration of the PH "Inventory and needs".
	// The current handler is not related to changes in the PH of "Inventory and needs", so it needs to be executed directly in a subordinate node.
	Handler.ExecuteInMasterNodeOnly = False;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	
	ToLock = New Array;
	// To determine whether a controlled lock is needed, when calculating the register, after the interactive execution of documents.
	ToLock.Add(Metadata.InformationRegisters.InventoryAllocation.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.InventoryAllocation.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.41";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("5b78b66c-b22d-499d-94a7-9e485346f7c6");
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.InventoryAllocation.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật trong biểu ghi thông tin ""Phân bổ hàng tồn kho"" dữ liệu về số dư và lịch biểu tiếp nhận hàng hóa và công việc
	| có trong các chứng từ đã được lập ""Biên bản chênh lệch sau khi tiếp nhận"", khi lập chứng từ mua hàng riêng,
	|""Điều chỉnh mua hàng"", ""Mua hàng hóa và dịch vụ"", khi lập chứng từ mua hàng riêng hoặc có nội dung công việc.
	| Sửa lỗi bút toán của chứng từ ""Kiểm đếm hàng hóa"" theo các vị trí hàng hóa.';
	|ru = 'Обновляет в регистре сведений ""Распределение запасов"" данные об остатке и графике поступления товаров и работ
	| содержащихся в оформленных документах ""Акт о расхождениях после приемки"", при раздельном оформлении закупок,
	| ""Корректировка приобретения"", ""Приобретение товаров и услуг"" при раздельном оформлении закупок, либо содержащих работы.
	| Исправляет ошибку движений документов ""Пересчет товаров"" по товарным местам.';
	|en = 'Updates data in the ""Inventory allocation"" information register on the balance and schedule of receipt of goods and works
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" and ""Vendor invoice"" documents with separate registration of purchases or with works.
	| Corrects the error in ""Inventory count sheet"" document register records by cargo items.'; fa = 'Updates data in the ""Inventory allocation"" information register on the balance and schedule of receipt of goods and works
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" and ""Vendor invoice"" documents with separate registration of purchases or with works.
	| Corrects the error in ""Inventory count sheet"" document register records by cargo items.';
	|it = 'Updates data in the ""Inventory allocation"" information register on the balance and schedule of receipt of goods and works
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" and ""Vendor invoice"" documents with separate registration of purchases or with works.
	| Corrects the error in ""Inventory count sheet"" document register records by cargo items.';
	|pl = 'Updates data in the ""Inventory allocation"" information register on the balance and schedule of receipt of goods and works
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" and ""Vendor invoice"" documents with separate registration of purchases or with works.
	| Corrects the error in ""Inventory count sheet"" document register records by cargo items.';
	|tr = '""Stok dağıtımı"" bilgi kaydında; ayrı satın alma işlemlerinde düzenlenen 
	| ""Teslim alma sonrası stok farkları raporu"" belgeleri ile, 
	| ayrı satın alma işlemlerinde veya iş içeren ""Satın alma düzeltmesi"" ve ""Satın alma faturası"" belgelerinde yer alan ürün ve işlerin bakiye ve giriş takvimi verilerini günceller. 
	| ""Stok sayımı"" belgelerinin ürün yeri hareketlerindeki hatayı düzeltir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.InventoryAllocation.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.InventoryAndDemands.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.InventoryAllocation.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.InventoryAndDemands.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "InformationRegisters.InventoryAllocation.ProcessStorageFormatChanges";
	NewRow.Order = "After";
	
	ToLock = New Array;
	// To determine whether a controlled lock is needed, when calculating the register, after the interactive execution of documents.
	ToLock.Add(Metadata.InformationRegisters.InventoryAllocation.FullName()); 
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

Procedure RegisterDataForChangingStorageFormat(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.InventoryAllocation";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.InventoryAllocation");
	
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
		|	Table.InventoryState = VALUE(Enum.InventoryStates.EmptyRef)";
	
	RecordedMeasurements = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, RecordedMeasurements, AdditionalParameters);
	
EndProcedure

Procedure ProcessStorageFormatChanges(Parameters) Export
	
	FullRegisterName = "InformationRegister.InventoryAllocation";
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	TableUpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	TableUpdatedDataForWarehousesOnly = TableUpdatedData.Copy();
	TotalRows = TableUpdatedDataForWarehousesOnly.Count();
	For Counter = 1 To TotalRows Do
		IndexOf = TotalRows - Counter;
		ValueInString = TableUpdatedDataForWarehousesOnly[IndexOf].Warehouse;
		If TypeOf(ValueInString) <> Type("CatalogRef.Warehouses") Or Not ValueIsFilled(ValueInString) Then
			TableUpdatedDataForWarehousesOnly.Delete(IndexOf);
		EndIf;
	EndDo;
	
	BatchProcessingFailed = False;
	
	Set = CreateRecordSet();
	Set.Filter.Products.Use = True;
	Set.Filter.Characteristic.Use = True;
	Set.Filter.Warehouse.Use = True;
	Set.Filter.Purpose.Use = True;
	
	BeginTransaction();
	Try
		Block = New DataLock();
		InventoryAllocation.AddLocks(Block, Undefined,
			TableUpdatedData, TableUpdatedDataForWarehousesOnly);
		Block.Lock();
		AllocationResult = InventoryAllocation.UpdatingInformationSecurityByProduct(TableUpdatedData, "InventoryAllocation");
		TotalRows = AllocationResult.InventoryAllocation.Count();
		For IndexOf = 0 To TotalRows - 1 Do
			TableRow = AllocationResult.InventoryAllocation[IndexOf];
			If Set.Filter.Products.Value <> TableRow.Products
					Or Set.Filter.Characteristic.Value <> TableRow.Characteristic
					Or Set.Filter.Warehouse.Value <> TableRow.Warehouse
					Or Set.Filter.Purpose.Value <> TableRow.Purpose Then
						
						If IndexOf > 0 Then
							InfobaseUpdate.WriteRecordSet(Set, True, False);
							Set.Clear();
						EndIf;
						
						Set.Filter.Products.Value = TableRow.Products;
						Set.Filter.Characteristic.Value = TableRow.Characteristic;
						Set.Filter.Warehouse.Value = TableRow.Warehouse;
						Set.Filter.Purpose.Value = TableRow.Purpose;
						
			EndIf;
			If Not TableRow.IsEmpty Then
				FillPropertyValues(Set.Add(), TableRow);
			EndIf;
		EndDo;
		If TotalRows > 0 Then
			InfobaseUpdate.WriteRecordSet(Set, True, False);
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
				AllocationResult = InventoryAllocation.UpdatingInformationSecurityByProduct(ValueInTable, "InventoryAllocation");
				
				Set = CreateRecordSet();
				Set.Filter.Products.Set(String.Products);
				Set.Filter.Characteristic.Set(String.Characteristic);
				Set.Filter.Warehouse.Set(String.Warehouse);
				Set.Filter.Purpose.Set(String.Purpose);
				Set.Load(AllocationResult.InventoryAllocation.Copy(New Structure("IsEmpty", False)));
				
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

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.InventoryAllocation";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.InventoryAllocation");
	
	RegisterNameInventoryAndNeeds = "InventoryAndDemands";
	FullNameOfRegisterInventoryAndNeeds = "AccumulationRegister.InventoryAndDemands";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.GetQueryTexts = True;
	
	QueryTexts = Documents.DiscrepancyReportFollowingReceipt.DocumentDataForPosting(
		Undefined,
		RegisterNameInventoryAndNeeds,
		AddlParameters);
	
	RecordersCertificatesAfterAcceptance = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullNameOfRegisterInventoryAndNeeds,
		"Document.DiscrepancyReportFollowingReceipt",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	QueryTexts = Documents.PurchaseAdjustment.DocumentDataForPosting(
		Undefined,
		RegisterNameInventoryAndNeeds,
		AddlParameters);
	
	AcquisitionAdjustmentRecorders = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullNameOfRegisterInventoryAndNeeds,
		"Document.PurchaseAdjustment",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	QueryTexts = Documents.VendorInvoice.DocumentDataForPosting(
		Undefined,
		RegisterNameInventoryAndNeeds,
		AddlParameters);
	
	AcquisitionRecorders = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullNameOfRegisterInventoryAndNeeds,
		"Document.VendorInvoice",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	QueryTexts = Documents.InventoryRecount.DocumentDataForPosting(
		Undefined,
		RegisterNameInventoryAndNeeds,
		AddlParameters);
	
	RecordersRecalculationsOfGoods = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullNameOfRegisterInventoryAndNeeds,
		"Document.InventoryRecount",
		Undefined,
		"CloseReceiptSchedule,CloseScheduleShipping",
		"RegisterTable.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)");
	
	Query = New Query();
	Query.SetParameter("RecordersCertificatesAfterAcceptance", RecordersCertificatesAfterAcceptance);
	Query.SetParameter("AcquisitionAdjustmentRecorders", AcquisitionAdjustmentRecorders);
	Query.SetParameter("AcquisitionRecorders", AcquisitionRecorders);
	Query.SetParameter("RecordersRecalculationsOfGoods", RecordersRecalculationsOfGoods);
	Query.Text =
		"SELECT DISTINCT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose
		|INTO AnalyticsForUpdates
		|FROM(
			// The transfer of RegisteredRecords to reflect discrepancies in the acquisition adjustment.
		|	SELECT
		|		DocumentGoods.Products AS Products,
		|		DocumentGoods.Characteristic AS Characteristic,
		|		DocumentGoods.Warehouse AS Warehouse,
		|		DocumentGoods.Purpose AS Purpose
		|	FROM
		|		Document.DiscrepancyReportFollowingReceipt AS DocumentTable
		|			INNER JOIN Document.DiscrepancyReportFollowingReceipt.Goods AS DocumentGoods
		|			ON DocumentGoods.Ref = DocumentTable.Ref
		|	WHERE
		|		DocumentTable.Posted
		|		AND DocumentTable.Ref IN (&RecordersCertificatesAfterAcceptance)
		|		AND DocumentTable.BusinessOperation IN(
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|			VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
		|
		|	UNION ALL
		|	
			// The transfer of RegisteredRecords to reflect discrepancies in the acquisition adjustment.
			// Also, the addition of Registered Records for work in a two-way.
			// Deleting Registered Records based on the availability of one-way jobs for the option to reflect Reflect on income/ Write off expenses
		|	SELECT
		|		DocumentGoods.Products AS Products,
		|		DocumentGoods.Characteristic AS Characteristic,
		|		DocumentGoods.Warehouse AS Warehouse,
		|		DocumentGoods.Purpose AS Purpose
		|	FROM
		|		Document.PurchaseAdjustment AS DocumentTable
		|			INNER JOIN Document.PurchaseAdjustment.Discrepancies AS DocumentGoods
		|			ON DocumentGoods.Ref = DocumentTable.Ref
		|	WHERE
		|		DocumentTable.Posted
		|		AND DocumentTable.Ref IN (&AcquisitionAdjustmentRecorders)
		|
		|UNION ALL
		|
		// The Registered Records for the works of documents that do not support two-way works (under old Contracts)
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Warehouse AS Warehouse,
		|	DocumentGoods.Purpose AS Purpose
		|FROM
		|	Document.VendorInvoice AS DocumentTable
		|		INNER JOIN Document.VendorInvoice.Goods AS DocumentGoods
		|		ON DocumentGoods.Ref = DocumentTable.Ref
		|WHERE
		|	DocumentTable.Posted
		|	AND DocumentTable.Ref IN (&AcquisitionRecorders)
		|	AND DocumentGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND DocumentTable.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|
		|	UNION ALL
		|
		// Incorrect Registered Records of recalculations of goods by packages of goods items.
		|	SELECT
		|		DocumentGoods.Products AS Products,
		|		DocumentGoods.Characteristic AS Characteristic,
		|		DocumentTable.Warehouse AS Warehouse,
		|		DocumentGoods.Purpose AS Purpose
		|	FROM
		|		Document.InventoryRecount AS DocumentTable
		|			INNER JOIN Document.InventoryRecount.Goods AS DocumentGoods
		|			ON DocumentGoods.Ref = DocumentTable.Ref
		|	WHERE
		|		DocumentTable.Posted
		|		AND DocumentTable.Ref IN (&RecordersRecalculationsOfGoods)) AS Set
		|;
		|
		|/////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose
		|FROM
		|	AnalyticsForUpdates AS Table";
	
	RecordedMeasurements = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, RecordedMeasurements, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.InventoryAllocation";
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	If InfobaseUpdate.HasDataLockedByPreviousQueues(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Undefined, "AccumulationRegister.InventoryAndDemands") Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	TableUpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	For Each String In TableUpdatedData Do
		
		Set = Undefined;
		
		BeginTransaction();
		Try
			
			Block = New DataLock();
			InventoryAllocation.AddLocks(Block, String, Undefined, Undefined);
			Block.Lock();
			
			ValueInTable = TableUpdatedData.Copy(CommonClientServer.ValueInArray(String));
			AllocationResult = InventoryAllocation.UpdatingInformationSecurityByProduct(ValueInTable, "InventoryAllocation");
			
			Set = CreateRecordSet();
			Set.Filter.Products.Set(String.Products);
			Set.Filter.Characteristic.Set(String.Characteristic);
			Set.Filter.Warehouse.Set(String.Warehouse);
			Set.Filter.Purpose.Set(String.Purpose);
			Set.Load(AllocationResult.InventoryAllocation.Copy(New Structure("IsEmpty", False)));
			
			InfobaseUpdate.WriteRecordSet(Set, True);
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
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
