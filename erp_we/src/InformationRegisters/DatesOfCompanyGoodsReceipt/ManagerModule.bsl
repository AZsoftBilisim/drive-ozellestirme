#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.DatesOfCompanyGoodsReceipt.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.3";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("93c9920d-a0c8-42bc-91d7-e956bc1cd320");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DatesOfCompanyGoodsReceipt.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	CommentText1 = New Array;
	CommentText1.Add(NStr("vi = 'Cập nhật dữ liệu trong biểu ghi thông tin ""Ngày tiếp nhận hàng hóa của doanh nghiệp"" theo dữ liệu từ các chứng từ:';
							|ru = 'Актуализирует данные в регистре сведений ""Даты поступления товаров организаций"" по данным документов:';
							|en = 'Updates data in the ""Dates of company goods receipt"" information register based on document data:'; fa = 'Updates data in the ""Dates of company goods receipt"" information register based on document data:';
							|it = 'Updates data in the ""Dates of company goods receipt"" information register based on document data:';
							|pl = 'Updates data in the ""Dates of company goods receipt"" information register based on document data:';
							|tr = '""İş yerinin ürün giriş tarihleri"" bilgi kayıt defterindeki verileri, şu belgelere dayanarak günceller:'"));
	CommentText1.Add(NStr("vi = '- ""Tiếp nhận hàng hóa từ bên bảo quản"" với giao dịch ""Tiếp nhận từ người nhận gia công"";';
							|ru = '- ""Поступление товаров от хранителя"" с операцией ""Поступление от переработчика"";';
							|en = '-  VMI return with the ""Goods receipt — External subcontracting"" transaction'; fa = '-  VMI return with the ""Goods receipt — External subcontracting"" transaction';
							|it = '-  VMI return with the ""Goods receipt — External subcontracting"" transaction';
							|pl = '-  VMI return with the ""Goods receipt — External subcontracting"" transaction';
							|tr = '- ""Fason üreticiden irsaliye"" işlemi ile ""Malların VMI''dan teslim alınması"";'"));
	CommentText1.Add(NStr("vi = '- ""Điều chỉnh mục đích hàng hóa"".';
							|ru = '- ""Корректировка назначения товаров"".';
							|en = '- Inventory assignment adjustment'; fa = '- Inventory assignment adjustment';
							|it = '- Inventory assignment adjustment';
							|pl = '- Inventory assignment adjustment';
							|tr = '- ""Stok atama düzeltmesi"".'"));
	
	Handler.Comment = StrConcat(CommentText1, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CompanyGoods.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.DatesOfCompanyGoodsReceipt.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.DatesOfCompanyGoodsReceipt.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.DatesOfCompanyGoodsReceipt.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Performs registration of data for updating.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export 
	
	FullRegisterName = Metadata.InformationRegisters.DatesOfCompanyGoodsReceipt.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	RegisterComparison.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	RegisterComparison.Products AS Products,
	|	RegisterComparison.Characteristic AS Characteristic,
	|	RegisterComparison.Series AS Series,
	|	RegisterComparison.Purpose AS Purpose,
	|	RegisterComparison.CCDNumber AS CCDNumber
	|FROM
	|	(SELECT
	|		CompanyGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		CompanyGoods.ItemsLocationAttributes.Products AS Products,
	|		CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		CompanyGoods.ItemsLocationAttributes.Series AS Series,
	|		CompanyGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|		CompanyGoods.CCDNumber AS CCDNumber,
	|		NULL AS CurrentDateOfReceipt,
	|		CompanyGoods.Period AS DateOfReceipt
	|	FROM
	|		AccumulationRegister.CompanyGoods AS CompanyGoods
	|			LEFT JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptOfGoodsFromCustodian
	|			ON CompanyGoods.Recorder = ReceiptOfGoodsFromCustodian.Ref
	|	WHERE 
	|		CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND (CompanyGoods.Recorder REFS Document.InventoryAssignmentAdjustment
	|					OR CompanyGoods.Recorder REFS Document.ReceiptOfGoodsFromCustodian
	|					)
	|
	// Receipt of goods from the custodian carries out the Registered Records on the dates of receipt only from the household. of operation "Receipt of processer2_5":
	|		AND ISNULL(
	|			ReceiptOfGoodsFromCustodian.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|			TRUE)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute,
	|		DatesOfCompanyGoodsReceipt.Products,
	|		DatesOfCompanyGoodsReceipt.Characteristic,
	|		DatesOfCompanyGoodsReceipt.Series,
	|		DatesOfCompanyGoodsReceipt.Purpose,
	|		DatesOfCompanyGoodsReceipt.CCDNumber,
	|		DatesOfCompanyGoodsReceipt.DateOfReceipt,
	|		NULL
	|	FROM
	|		InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfCompanyGoodsReceipt) AS RegisterComparison
	|
	|GROUP BY
	|	RegisterComparison.InventoryOwnerAttribute,
	|	RegisterComparison.Products,
	|	RegisterComparison.Characteristic,
	|	RegisterComparison.Series,
	|	RegisterComparison.Purpose,
	|	RegisterComparison.CCDNumber
	|
	|HAVING
	|	ISNULL(MAX(RegisterComparison.DateOfReceipt), DATETIME(1, 1, 1)) > ISNULL(MAX(RegisterComparison.CurrentDateOfReceipt), DATETIME(1, 1, 1))";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload(), AdditionalParameters);
	
EndProcedure

// Performs processing of data registered for updating.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.InformationRegisters.DatesOfCompanyGoodsReceipt.FullName();
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																							FullRegisterName);
		
		Return;
	EndIf;
		
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("UpdatedData", UpdatedData);
	
	// Find the analytics keys that are included in the processing portion:
	Query.Text =
	"SELECT
	|	UpdatedData.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	UpdatedData.Products   AS Products,
	|	UpdatedData.Characteristic AS Characteristic,
	|	UpdatedData.Series          AS Series,
	|	UpdatedData.Purpose     AS Purpose,
	|	UpdatedData.CCDNumber       AS CCDNumber
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	UpdatedData.Products   AS Products,
	|	UpdatedData.Characteristic AS Characteristic,
	|	UpdatedData.Series          AS Series,
	|	UpdatedData.Purpose     AS Purpose,
	|	UpdatedData.CCDNumber       AS CCDNumber,
	|	ItemsLocationAttributes.DimensionKey         AS ItemsLocationAttributes
	|INTO UpdatedKeys
	|FROM
	|	UpdatedData AS UpdatedData
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS ItemsLocationAttributes
	|		ON UpdatedData.Products      = ItemsLocationAttributes.Products
	|			AND UpdatedData.Characteristic = ItemsLocationAttributes.Characteristic
	|			AND UpdatedData.Series          = ItemsLocationAttributes.Series
	|			AND UpdatedData.Purpose     = ItemsLocationAttributes.Purpose
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	UpdatedKeys.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	UpdatedKeys.Products               AS Products,
	|	UpdatedKeys.Characteristic             AS Characteristic,
	|	UpdatedKeys.Series                      AS Series,
	|	UpdatedKeys.Purpose                 AS Purpose,
	|	UpdatedKeys.CCDNumber                   AS CCDNumber,
	|	UpdatedKeys.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM UpdatedKeys";
	
	QueryResult = Query.Execute();
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		
		LockItem = Block.Add(FullRegisterName);
		LockItem.DataSource = UpdatedData;
		LockItem.UseFromDataSource("InventoryOwnerAttribute",     "InventoryOwnerAttribute");
		LockItem.UseFromDataSource("Products",   "Products");
		LockItem.UseFromDataSource("Characteristic", "Characteristic");
		LockItem.UseFromDataSource("Series",          "Series");
		LockItem.UseFromDataSource("Purpose",     "Purpose");
		LockItem.UseFromDataSource("CCDNumber",       "CCDNumber");
		
		LockItem = Block.Add(Metadata.AccumulationRegisters.CompanyGoods.FullName());
		LockItem.Mode = DataLockMode.Shared;
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("ItemsLocationAttributes", "ItemsLocationAttributes");
		LockItem.UseFromDataSource("InventoryOwnerAttribute",                 "InventoryOwnerAttribute");
		LockItem.UseFromDataSource("CCDNumber",                   "CCDNumber");
		
		Block.Lock();
		
		Query.Text = 
		"SELECT
		|	RegisterComparison.InventoryOwnerAttribute                       AS InventoryOwnerAttribute,
		|	RegisterComparison.Products                     AS Products,
		|	RegisterComparison.Characteristic                   AS Characteristic,
		|	RegisterComparison.Series                            AS Series,
		|	RegisterComparison.Purpose                       AS Purpose,
		|	RegisterComparison.CCDNumber                         AS CCDNumber,
		|	MAX(RegisterComparison.DateOfReceipt)        AS DateOfReceipt,
		|	MAX(RegisterComparison.CurDateOfReceipt) AS CurDateOfReceipt
		|FROM
		|	(SELECT
		|		UpdatedKeys.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
		|		UpdatedKeys.Products   AS Products,
		|		UpdatedKeys.Characteristic AS Characteristic,
		|		UpdatedKeys.Series          AS Series,
		|		UpdatedKeys.Purpose     AS Purpose,
		|		UpdatedKeys.CCDNumber       AS CCDNumber,
		|		CompanyGoods.Period        AS DateOfReceipt,
		|		NULL                            AS CurDateOfReceipt
		|	FROM
		|		AccumulationRegister.CompanyGoods AS CompanyGoods
		|			INNER JOIN UpdatedKeys AS UpdatedKeys
		|			ON CompanyGoods.ItemsLocationAttributes = UpdatedKeys.ItemsLocationAttributes
		|				AND CompanyGoods.InventoryOwnerAttribute              = UpdatedKeys.InventoryOwnerAttribute
		|				AND CompanyGoods.CCDNumber                = UpdatedKeys.CCDNumber
		|				AND CompanyGoods.RecordType            = VALUE(AccumulationRecordType.Receipt)
		|				AND (CompanyGoods.Recorder REFS Document.InventoryAssignmentAdjustment
		|					OR CompanyGoods.Recorder REFS Document.ReceiptOfGoodsFromCustodian
		|					)
		|			LEFT JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptOfGoodsFromCustodian
		|			ON CompanyGoods.Recorder = ReceiptOfGoodsFromCustodian.Ref
		|	WHERE
		// Receipt of goods from the custodian carries out the Registered Records on the dates of receipt only from the household. of operation "Receipt of processer2_5":
		|		ISNULL(
		|			ReceiptOfGoodsFromCustodian.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
		|			TRUE)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		UpdatedKeys.InventoryOwnerAttribute                       AS InventoryOwnerAttribute,
		|		UpdatedKeys.Products                     AS Products,
		|		UpdatedKeys.Characteristic                   AS Characteristic,
		|		UpdatedKeys.Series                            AS Series,
		|		UpdatedKeys.Purpose                       AS Purpose,
		|		UpdatedKeys.CCDNumber                         AS CCDNumber,
		|		NULL                                              AS DateOfReceipt,
		|		DatesOfCompanyGoodsReceipt.DateOfReceipt AS CurDateOfReceipt
		|	FROM
		|		InformationRegister.DatesOfCompanyGoodsReceipt AS DatesOfCompanyGoodsReceipt
		|			LEFT JOIN UpdatedKeys AS UpdatedKeys
		|			ON DatesOfCompanyGoodsReceipt.InventoryOwnerAttribute        = UpdatedKeys.InventoryOwnerAttribute
		|				AND DatesOfCompanyGoodsReceipt.Products   = UpdatedKeys.Products
		|				AND DatesOfCompanyGoodsReceipt.Characteristic = UpdatedKeys.Characteristic
		|				AND DatesOfCompanyGoodsReceipt.Series          = UpdatedKeys.Series
		|				AND DatesOfCompanyGoodsReceipt.Purpose     = UpdatedKeys.Purpose
		|				AND DatesOfCompanyGoodsReceipt.CCDNumber       = UpdatedKeys.CCDNumber) AS RegisterComparison
		|
		|GROUP BY
		|	RegisterComparison.InventoryOwnerAttribute,
		|	RegisterComparison.Products,
		|	RegisterComparison.Characteristic,
		|	RegisterComparison.Series,
		|	RegisterComparison.Purpose,
		|	RegisterComparison.CCDNumber
		|
		|HAVING
		|	ISNULL(MAX(RegisterComparison.DateOfReceipt), DATETIME(1, 1, 1)) > ISNULL(MAX(RegisterComparison.CurDateOfReceipt), DATETIME(1, 1, 1))";
		
		QueryResults = Query.Execute();
		
		RecordSet = CreateRecordSet();
		RecordSet.Load(QueryResults.Unload());
		RecordSet.Write(ReplacementMode.Merge);
		
		AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
		AdditionalParameters.IsIndependentInformationRegister = True;
		AdditionalParameters.FullRegisterName = FullRegisterName;
		InfobaseUpdate.MarkProcessingCompletion(UpdatedData, AdditionalParameters);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
			
		MessageText = NStr("vi = 'Không thể cập nhật dữ liệu trong biểu ghi %1 do nguyên nhân: %2';
							|ru = 'Не удалось обновить данные в регистре %1 по причине: %2';
							|en = 'Cannot update data in the %1 register due to: %2'; fa = 'Cannot update data in the %1 register due to: %2';
							|it = 'Cannot update data in the %1 register due to: %2';
							|pl = 'Cannot update data in the %1 register due to: %2';
							|tr = '%1 kaydındaki veriler şu nedenden dolayı güncellenemedi: %2'");
		MessageText = StrTemplate(MessageText,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			FullRegisterName);
			
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			Metadata.InformationRegisters.DatesOfCompanyGoodsReceipt,
			,
			MessageText);
		
	EndTry;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																						FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
