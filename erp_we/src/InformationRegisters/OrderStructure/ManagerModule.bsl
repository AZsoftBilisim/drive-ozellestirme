#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function MetadataStructure() Export
	
	Result = OrderStructureCached.RegisterMetadataStructure("OrderStructure");
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.OrderStructure.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.14";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("33afef3a-b18d-4e63-81a6-0d0ec5e8e1b3");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.OrderStructure.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Tái cấu trúc cơ chế lưu trữ dữ liệu nhằm hỗ trợ các quy trình tháo rời và sửa chữa';
							|ru = 'Реструктуризация хранения данных для поддержки разборочных и ремонтных процессов';
							|en = 'Data storage restructuring to support disassembly and R&M processes'; fa = 'Data storage restructuring to support disassembly and R&M processes';
							|it = 'Data storage restructuring to support disassembly and R&M processes';
							|pl = 'Data storage restructuring to support disassembly and R&M processes';
							|tr = 'Demontaj ve bakım onarım süreçlerini desteklemek için veri depolamanın yeniden yapılandırılması'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.OrderStructure.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.OrderStructure.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	// Filling in the dimension Keynomenclature
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.OrderStructure.ProcessDataToUpgradeToNewVersionFillingIn";
	Handler.Version = "2.5.26.88";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("22afef2a-b18d-4e62-81a6-0d0ec5e8e1b3");
	Handler.UpdateDataFillingProcedure = "InformationRegisters.OrderStructure.RegisterDataForProcessingToSwitchToNewVersionFillingIn";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền biểu ghi ""Cấu trúc đơn hàn sản xuất"" theo dữ liệu chứng từ ""Giai đoạn sản xuất"".';
							|ru = 'Заполняет регистр ""Структура заказа на производство"" по данным документов ""Этап производства"".';
							|en = 'Fills the ""Production order structure"" register by data of the ""Production stage"" documents'; fa = 'Fills the ""Production order structure"" register by data of the ""Production stage"" documents';
							|it = 'Заполняет регистр ""Структура заказа на производство"" по данным документов ""Этап производства"".';
							|pl = 'Fills the ""Production order structure"" register by data of the ""Production stage"" documents';
							|tr = '""Üretim aşaması"" belgelerine göre ""Üretim emri yapısı"" kaydını doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.ProductionStage2_2.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.OrderStructure.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.OrderStructure.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	// Cleaning up unnecessary RegisteredRecords
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.OrderStructure.ProcessDataToUpgradeToNewVersion";
	Handler.Version = "2.5.27.17";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("71291306-ffe5-49c7-ac05-ea01e77089a5");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.OrderStructure.RegisterDataForProcessingToUpgradeToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Xóa các bản ghi thừa trong biểu ghi thông tin ""Cấu trúc đơn hàng sản xuất""';
							|ru = 'Очистка лишних движений в регистре сведений ""Структура заказа на производство""';
							|en = 'Clear excessive records in the ""Production order structure"" information register'; fa = 'Clear excessive records in the ""Production order structure"" information register';
							|it = 'Clear excessive records in the ""Production order structure"" information register';
							|pl = 'Clear excessive records in the ""Production order structure"" information register';
							|tr = '""Üretim emri yapısı"" bilgi kaydındaki gereksiz hareketlerin temizlenmesi'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.OrderStructure.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.OrderStructure.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export 
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.OrderStructure";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("ProductionOrder ASC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("ProductionOrder ASC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	SelectionParameters.NameOfTheDimensionToSelect = "KeySet";
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.OrderStructure");
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Plan.KeySet AS KeySet
	|FROM
	|	InformationRegister.OrderStructure AS Plan
	|WHERE
	|	Plan.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)
	|		AND Plan.ToSupply <> 0";
	
	Data = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Data, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.OrderStructure";
	
	TempTablesManager = New TempTablesManager;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	AdditionalParameters.TempTableName = "DataForProcessing";
	
	Result = InfobaseUpdate.CreateTemporaryTableOfStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue,
		FullRegisterName,
		TempTablesManager,
		AdditionalParameters);
		
	If Not Result.HasDataToProcess Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	If Not Result.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;

	RequestVerification = New Query;
	RequestVerification.Text =
		"SELECT DISTINCT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.Purpose     AS Purpose
		|FROM
		|	InformationRegister.OrderStructure AS Table
		|WHERE
		|	(Table.Products, Table.Characteristic, Table.Warehouse, Table.Purpose, Table.ProductionOrder,
		|		Table.KeyProducts) IN
		|		(SELECT
		|			DD.Products AS Products,
		|			DD.Characteristic AS Characteristic,
		|			DD.Warehouse AS Warehouse,
		|			DD.Purpose AS Purpose,
		|			DD.ProductionOrder AS ProductionOrder,
		|			DD.KeyProducts AS KeyProducts
		|		FROM
		|			InformationRegister.OrderStructure AS DD
		|		WHERE
		|			DD.KeySet = &KeySet
		|			AND DD.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct))
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose,
		|	Table.ProductionOrder,
		|	Table.KeyProducts
		|HAVING
		|	SUM(Table.Ordered) <> SUM(Table.Scheduled + Table.AllocatedInAssignedProductionLots + Table.AllocatedInFreeProductionLots)";
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
		"SELECT DISTINCT
		|	Table.KeySet AS KeySet,
		|	Table.ProductionOrder AS ProductionOrder
		|FROM
		|	InformationRegister.OrderStructure AS Table
		|WHERE
		|	Table.KeySet IN
		|		(SELECT
		|			DataForProcessing.KeySet
		|		FROM
		|			DataForProcessing AS DataForProcessing)";
		
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		
		BeginTransaction();
		Try

			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.OrderStructure");
			LockItem.SetValue("KeySet", Selection.KeySet);
			Block.Lock();

			RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
			RecordSet.Filter.KeySet.Set(Selection.KeySet);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				
				If Record.LineKind = Enums.KindsOfProductionOrderStructureLines.ManufacturedProduct And Record.ToSupply <> 0 Then
					Record.Ordered = Record.Ordered + Record.ToSupply;
					Record.ToSupply = 0;
				EndIf;
				
			EndDo;
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			RequestVerification.SetParameter("KeySet", Selection.KeySet);
			CheckResult = RequestVerification.Execute(); //@skip-check query-in-loop
			If Not CheckResult.IsEmpty() Then
				InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(CheckResult.Unload());
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.ProductionOrder);
			
		EndTry;
			
	EndDo;

	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
	If Parameters.ProcessingCompleted Then
		OrderStructure.StartCalculation();
	EndIf;
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataForProcessingToSwitchToNewVersionFillingIn(Parameters) Export
	
	FullRegisterName  = "InformationRegister.OrderStructure";
	FullDocumentName = "Document.ProductionStage2_2";
	
	UnusedFields = New Array;
	UnusedFields.Add("Separator");
	UnusedFields.Add("AllocatedFromAvailableInventoryWithAssignment");
	UnusedFields.Add("AllocatedFromAvailableInventory");
	UnusedFields.Add("AllocatedInAssignedProductionLots");
	UnusedFields.Add("AllocatedInFreeProductionLots");
	UnusedFields.Add("Scheduled");
	UnusedFields.Add("AdditionalRecord");
	UnusedFields.Add("DataVersionID");
	UnusedFields.Add("QuantityForLaunchLotUnit");
	UnusedFields.Add("CommunicationKeyBillOfMaterialsRow");
	UnusedFields.Add("ConnectionKeyTransfer");
	UnusedFields.Add("SemiFinishedProductBOM");
	UnusedFields.Add("ProductItemsGroup");
	
	FieldsNotCompatibleWithUndefinedType = New Array;
	FieldsNotCompatibleWithUndefinedType.Add("KeyProducts");
	FieldsNotCompatibleWithUndefinedType.Add("KeyLot");
	FieldsNotCompatibleWithUndefinedType.Add("KeySet");
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName",             FullRegisterName);
	
	SampleRequest = InfobaseUpdateTM.RequestForReflectionOfDocumentsInIndependentRegister(
						Documents.ProductionStage2_2.AdaptedCaseSensitiveQueryText("OrderStructure"),
						FullRegisterName,
						FullDocumentName,
						UnusedFields);
	
	QueryTextSamples = SampleRequest.Text;
	
	For Each Field In FieldsNotCompatibleWithUndefinedType Do
		QueryTextSamples = StrReplace(QueryTextSamples,
											StrReplace("OR NestedQuery.Field = UNDEFINED", "Field", Field),
											"");
	EndDo;
	
	QueryTextSamples = StrReplace(QueryTextSamples,
										"RegisterTable.Ref REFS Document.ProductionStage2_2",
										"TRUE");
	QueryTextSamples = StrReplace(QueryTextSamples,
										"RegisterTable.Ref = DocumentRecorder.Ref",
										"RegisterTable.Stage = DocumentRecorder.Ref
										|				AND RegisterTable.KeySet = UUID(DocumentRecorder.Ref)");
	
	QueryText = 
	"
	|SELECT DISTINCT
	|	WrongRegisteredRecords.KeySet AS KeySet
	|FROM
	|	&QueryTextSamples AS WrongRegisteredRecords";
	
	SampleRequest.Text = StrReplace(QueryText, "&QueryTextSamples", "(" + QueryTextSamples + ")");
	
	Data = SampleRequest.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Data, AdditionalParameters);
 		
EndProcedure

Procedure ProcessDataToUpgradeToNewVersionFillingIn(Parameters) Export
	
	FullRegisterName = "InformationRegister.OrderStructure";
	RegisterName = "OrderStructure";
	
	TempTablesManager = New TempTablesManager;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	AdditionalParameters.TempTableName = "DataForProcessing";
	
	Result = InfobaseUpdate.CreateTemporaryTableOfStandaloneInformationRegisterDimensionsToProcess(
		Parameters.Queue,
		FullRegisterName,
		TempTablesManager,
		AdditionalParameters);
		
	If Not Result.HasDataToProcess Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	If Not Result.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	DataSamplingParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	DataSamplingParameters.TempTableName = "BlockedData";
	
	InfobaseUpdate.CreateTemporaryTableOfRefsProhibitedFromReadingAndEditing(
		Undefined,
		"Document.ProductionStage2_2",
		TempTablesManager,
		DataSamplingParameters);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text = 
	"SELECT DISTINCT
	|	DataForProcessing.KeySet AS KeySet
	|FROM
	|	DataForProcessing AS DataForProcessing
	|WHERE 
	|	NOT DataForProcessing.KeySet IN
	|		(SELECT
	|			UUID(BlockedData.Ref)
	|		FROM
	|			BlockedData AS BlockedData)
	|";  
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			CurrentDocument = Documents.ProductionStage2_2.GetRef(Selection.KeySet);
			
			Block = New DataLock;
			
			LockItem = Block.Add("InformationRegister.OrderStructure");
			LockItem.SetValue("KeySet", Selection.KeySet);
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add("Document.ProductionStage2_2");
			LockItem.SetValue("Ref", CurrentDocument);
			LockItem.Mode = DataLockMode.Shared;
			
			Block.Lock();
			
			RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
			RecordSet.Filter.KeySet.Set(Selection.KeySet);
			RecordSet.Read();
			
			If ValueIsFilled(CurrentDocument) And Common.ObjectAttributeValue(CurrentDocument, "Posted") = True Then
				RegisterTable = Undefined;
				TablesForRegisteredRecords = Documents.ProductionStage2_2.DocumentDataForPosting(CurrentDocument, RegisterName);
				TablesForRegisteredRecords.Property("Table" + RegisterName, RegisterTable);
				RecordSet.Load(RegisterTable);
			Else
				RecordSet.Clear();
			EndIf;
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();   
						
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), CurrentDocument);
			
			ErrorTemplate = NStr("vi = 'Không thể ghi lại dữ liệu vào biểu ghi ""Cấu trúc đơn hàng sản xuất"" theo giai đoạn ""%1"":
									   |
									   |%2';
									   |ru = 'Не удалось записать данные в регистр ""Структура заказа на производство"" по этапу ""%1"":
									   |
									   |%2';
									   |en = 'Cannot write the data to the ""Production order structure"" register for the ""%1"" stage:
									   |
									   |%2'; fa = 'Cannot write the data to the ""Production order structure"" register for the ""%1"" stage:
									   |
									   |%2';
									   |it = 'Не удалось записать данные в регистр ""Структура заказа на производство"" по этапу ""%1"":
									   |
									   |%2';
									   |pl = 'Cannot write the data to the ""Production order structure"" register for the ""%1"" stage:
									   |
									   |%2';
									   |tr = '""%1"" aşaması kapsamında ""Üretim emri yapısı"" kaydına veriler kaydedilemedi:
									   |
									   |%2'");
			
			ErrorText = StrTemplate(ErrorTemplate,
										CurrentDocument,
										ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				Metadata.InformationRegisters.OrderStructure,
				CurrentDocument,
				ErrorText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
										Parameters.Queue,
										FullRegisterName);
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataForProcessingToUpgradeToNewVersion(Parameters) Export 
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.OrderStructure";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.OrderStructure");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	OrderStructure.KeyProducts AS KeyProducts,
	|	OrderStructure.Products AS Products,
	|	OrderStructure.Characteristic AS Characteristic,
	|	OrderStructure.Warehouse AS Warehouse,
	|	OrderStructure.Purpose AS Purpose,
	|	OrderStructure.ProductionOrder AS ProductionOrder,
	|	OrderStructure.KeyLot AS KeyLot,
	|	OrderStructure.LineKind AS LineKind,
	|	OrderStructure.ReceiptOrder AS ReceiptOrder,
	|	OrderStructure.DateOfReceipt AS DateOfReceipt,
	|	OrderStructure.KeySet AS KeySet,
	|	SUM(OrderStructure.ToSupply) AS ToSupply
	|INTO RegisterRecordTable
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|WHERE
	|	OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|	AND OrderStructure.PermissionToReplace <> VALUE(Document.EngineeringChangeOrder.EmptyRef)
	|	AND OrderStructure.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|GROUP BY
	|	OrderStructure.Products,
	|	OrderStructure.Characteristic,
	|	OrderStructure.Warehouse,
	|	OrderStructure.Purpose,
	|	OrderStructure.ProductionOrder,
	|	OrderStructure.KeyProducts,
	|	OrderStructure.KeyLot,
	|	OrderStructure.LineKind,
	|	OrderStructure.ReceiptOrder,
	|	OrderStructure.DateOfReceipt,
	|	OrderStructure.KeySet
	|
	|HAVING
	|	SUM(OrderStructure.ToSupply) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder,
	|	KeyProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderStructure.ConnectionKeyTransfer AS ConnectionKeyTransfer,
	|	OrderStructure.Products AS Products,
	|	OrderStructure.Characteristic AS Characteristic,
	|	OrderStructure.Warehouse AS Warehouse,
	|	OrderStructure.Purpose AS Purpose,
	|	OrderStructure.ProductionOrder AS ProductionOrder,
	|	OrderStructure.KeyProducts AS KeyProducts,
	|	OrderStructure.KeyLot AS KeyLot,
	|	OrderStructure.LineKind AS LineKind,
	|	OrderStructure.ReceiptOrder AS ReceiptOrder,
	|	OrderStructure.DateOfReceipt AS DateOfReceipt,
	|	OrderStructure.KeySet AS KeySet,
	|	SUM(OrderStructure.Scheduled) AS Scheduled,
	|	SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) AS AllocatedFromAvailableInventoryWithAssignment,
	|	SUM(OrderStructure.AllocatedFromAvailableInventory) AS AllocatedFromAvailableInventory,
	|	SUM(OrderStructure.AllocatedInAssignedProductionLots) AS AllocatedInAssignedProductionLots,
	|	SUM(OrderStructure.AllocatedInFreeProductionLots) AS AllocatedInFreeProductionLots
	|INTO RegisteredRecordsWithProvisionOf
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				RegisterRecordTable AS RegisterRecordTable
	|			WHERE
	|				RegisterRecordTable.Products = OrderStructure.Products
	|				AND RegisterRecordTable.Characteristic = OrderStructure.Characteristic
	|				AND RegisterRecordTable.Warehouse = OrderStructure.Warehouse
	|				AND RegisterRecordTable.Purpose = OrderStructure.Purpose
	|				AND RegisterRecordTable.ProductionOrder = OrderStructure.ProductionOrder
	|				AND RegisterRecordTable.KeyProducts = OrderStructure.ConnectionKeyTransfer)
	|
	|GROUP BY
	|	OrderStructure.Products,
	|	OrderStructure.Characteristic,
	|	OrderStructure.Warehouse,
	|	OrderStructure.Purpose,
	|	OrderStructure.ProductionOrder,
	|	OrderStructure.KeyProducts,
	|	OrderStructure.KeyLot,
	|	OrderStructure.LineKind,
	|	OrderStructure.ReceiptOrder,
	|	OrderStructure.DateOfReceipt,
	|	OrderStructure.KeySet,
	|	OrderStructure.ConnectionKeyTransfer
	|
	|HAVING
	|	(SUM(OrderStructure.Scheduled) <> 0
	|		OR SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) <> 0
	|		OR SUM(OrderStructure.AllocatedFromAvailableInventory) <> 0
	|		OR SUM(OrderStructure.AllocatedInAssignedProductionLots) <> 0
	|		OR SUM(OrderStructure.AllocatedInFreeProductionLots) <> 0)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder,
	|	ConnectionKeyTransfer
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterRecordTable.KeyProducts AS KeyProducts,
	|	RegisterRecordTable.Products AS Products,
	|	RegisterRecordTable.Characteristic AS Characteristic,
	|	RegisterRecordTable.Warehouse AS Warehouse,
	|	RegisterRecordTable.Purpose AS Purpose,
	|	RegisterRecordTable.ProductionOrder AS ProductionOrder,
	|	RegisterRecordTable.KeyLot AS KeyLot,
	|	RegisterRecordTable.LineKind AS LineKind,
	|	RegisterRecordTable.ReceiptOrder AS ReceiptOrder,
	|	RegisterRecordTable.DateOfReceipt AS DateOfReceipt,
	|	RegisterRecordTable.KeySet AS KeySet,
	|	&EmptyKey AS Separator
	|FROM
	|	RegisterRecordTable AS RegisterRecordTable
	|WHERE
	|	NOT TRUE IN
	|				(SELECT
	|					TRUE
	|				FROM
	|					RegisteredRecordsWithProvisionOf AS RegisteredRecordsWithProvisionOf
	|				WHERE
	|					RegisteredRecordsWithProvisionOf.Products = RegisterRecordTable.Products
	|					AND RegisteredRecordsWithProvisionOf.Characteristic = RegisterRecordTable.Characteristic
	|					AND RegisteredRecordsWithProvisionOf.Warehouse = RegisterRecordTable.Warehouse
	|					AND RegisteredRecordsWithProvisionOf.Purpose = RegisterRecordTable.Purpose
	|					AND RegisteredRecordsWithProvisionOf.ProductionOrder = RegisterRecordTable.ProductionOrder
	|					AND RegisteredRecordsWithProvisionOf.ConnectionKeyTransfer = RegisterRecordTable.KeyProducts)";
	
	Query.SetParameter("EmptyKey", CommonClientServer.BlankUUID());
	
	Data = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Data, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataToUpgradeToNewVersion(Parameters) Export
	
	RegisterMetadata = CreateRecordSet().Metadata();
	FullObjectName = "InformationRegister.OrderStructure";
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Products.Set(Selection.Products);
			RecordSet.Filter.Characteristic.Set(Selection.Characteristic);
			RecordSet.Filter.Warehouse.Set(Selection.Warehouse);
			RecordSet.Filter.Purpose.Set(Selection.Purpose);
			RecordSet.Filter.ProductionOrder.Set(Selection.ProductionOrder);
			RecordSet.Filter.KeyProducts.Set(Selection.KeyProducts);
			RecordSet.Filter.KeyLot.Set(Selection.KeyLot);
			RecordSet.Filter.LineKind.Set(Selection.LineKind);
			RecordSet.Filter.ReceiptOrder.Set(Selection.ReceiptOrder);
			RecordSet.Filter.DateOfReceipt.Set(Selection.DateOfReceipt);
			RecordSet.Filter.KeySet.Set(Selection.KeySet);
			RecordSet.Filter.Separator.Set(Selection.Separator);
			
			Block = New DataLock;
			
			// Register lock
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Products", Selection.Products);
			LockItem.SetValue("Characteristic", Selection.Characteristic);
			LockItem.SetValue("Warehouse", Selection.Warehouse);
			LockItem.SetValue("Purpose", Selection.Purpose);
			LockItem.SetValue("ProductionOrder", Selection.ProductionOrder);
			LockItem.SetValue("KeyProducts", Selection.KeyProducts);
			LockItem.SetValue("KeyLot", Selection.KeyLot);
			LockItem.SetValue("LineKind", Selection.LineKind);
			LockItem.SetValue("ReceiptOrder", Selection.ReceiptOrder);
			LockItem.SetValue("DateOfReceipt", Selection.DateOfReceipt);
			LockItem.SetValue("KeySet", Selection.KeySet);
			LockItem.SetValue("Separator", Selection.Separator);
			
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			RecordSet.Read();
			RecordSet.Clear();
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();

		Except

			RollbackTransaction();
			
			FilterAsString = String(RecordSet.Filter);
			
			MessageText = NStr("vi = 'Không thể xử lý tập hợp bản ghi %Set% của biểu ghi 
										|""Cấu trúc đơn hàng sản xuất"" do: %Cause%';
										|ru = 'Не удалось обработать набор записей %Set% регистра 
										|""Структура заказа на производство"" по причине:  по причине: %Cause%';
										|en = 'Cannot process the %Set% record set of the 
										|""Production order structure"" register. Reason: %Cause%'; fa = 'Cannot process the %Set% record set of the 
										|""Production order structure"" register. Reason: %Cause%';
										|it = 'Cannot process the %Set% record set of the 
										|""Production order structure"" register. Reason: %Cause%';
										|pl = 'Cannot process the %Set% record set of the 
										|""Production order structure"" register. Reason: %Cause%';
										|tr = '
										|""Üretim emri yapısı"" kaydının %Set% kayıt kümesi şu nedenle işlenemedi:  %Cause%'");
			MessageText = StrReplace(MessageText, "%Set%", FilterAsString);
			MessageText = StrReplace(MessageText, "%Cause%", 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
									EventLogLevel.Warning,
									RegisterMetadata,
									FilterAsString,
									MessageText);
			
		EndTry;

	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

