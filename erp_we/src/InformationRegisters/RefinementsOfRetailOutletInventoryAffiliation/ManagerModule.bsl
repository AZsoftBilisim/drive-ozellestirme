#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal
	
// Fills in the details of the type of inventory belonging to retail outlets
// Parameters:
//	Recipient - ExchangePlanRef.DataSynchronizationViaUniversalFormat
Procedure FillingOutSpecificationOfInventoryBelongingToRetailOutlets(Recipient) Export
	
	// Here there is a adjustment of the register of clarification of the ownership of stock trading cards according to the actual calculated data.
	If TypeOf(Recipient) <> Type("ExchangePlanRef.DataSynchronizationViaUniversalFormat") Then
		Return;
	EndIf;
	
	// let's check whether the node accepts the data of the "Clarification of the ownership of stock trading cards"
	RecordingSettings = InformationRegisters.XDTODataExchangeSettings.CreateRecordManager();
	RecordingSettings.InfobaseNode = Recipient;
	RecordingSettings.Read();
	StorageValue = RecordingSettings.CorrespondentSettings.Get();
	SavedData = Undefined;
	If Not TypeOf(StorageValue) = Type("Structure")
		Or Not  StorageValue.Property("SupportedObjects", SavedData) Then
		
		Return;
		
	EndIf;
	CurrFormatVersion = Common.ObjectAttributeValue(Recipient, "ExchangeFormatVersion");
	RowFilter = New Structure();
	RowFilter.Insert("Version", CurrFormatVersion);
	RowFilter.Insert("Object", "Catalog.RefinementsOfRetailOutletInventoryAffiliation");
	RowFilter.Insert("Receive", True);
	If SavedData.FindRows(RowFilter).Count() = 0 Then
		
		Return;
		
	EndIf;
	
	MeasurementStart = PerformanceMonitor.StartTimeMeasurement();
	
	Query = New Query;
	QueryTexts = New Array;
	QueryTexts.Add(QueryTextTTInventoryOfOperation());
	
	QueryTextForSelectingInventoryOfOperations = 
	"SELECT DISTINCT
	|	InventoryOfOperations.Organization AS Organization,
	|	InventoryOfOperations.Warehouse AS Warehouse,
	|	TRUE AS Clear
	|FROM
	|	InventoryOfOperations AS InventoryOfOperations
	|		INNER JOIN InformationRegister.RefinementsOfRetailOutletInventoryAffiliation AS InventoryClarification
	|		ON InventoryOfOperations.Warehouse = InventoryClarification.Warehouse
	|			AND InventoryOfOperations.Organization = InventoryClarification.CompanyCustomer
	|WHERE
	|	NOT InventoryOfOperations.FillInInventoryData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryOfOperations.Organization AS Organization,
	|	InventoryOfOperations.Warehouse AS Warehouse,
	|	TRUE AS ShouldRecalculate
	|FROM
	|	InventoryOfOperations AS InventoryOfOperations
	|WHERE
	|	InventoryOfOperations.FillInInventoryData";
	
	QueryTexts.Add(QueryTextForSelectingInventoryOfOperations);
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.Parameters.Insert("ExchangeNode", Recipient);
	
	Results = Query.ExecuteBatch();
	PackageRequests = Results.Count();
	TuplesToCleanUp = Results[PackageRequests - 2].Unload();
	TuplesToRecalculate = Results[PackageRequests - 1].Unload();
	
	For Each Tuple In TuplesToRecalculate Do
		// Recalculate committee data by warehouse
		UpdateDetailsOfInventoryBelongingToRetailOutlets(Tuple.Organization, Tuple.Warehouse); 
	EndDo;
	
	DeletedRecords = 0;
	For Each Tuple In TuplesToCleanUp Do
		
		// clear data on tuples that are no longer relevant
		RequestForCleanup = New Query;
		RequestForCleanup.Parameters.Insert("Warehouse", Tuple.Warehouse);
		RequestForCleanup.Parameters.Insert("Organization", Tuple.Organization);
		RequestForCleanup.Text = 
		"SELECT
		|	InventoryClarification.Warehouse AS Warehouse,
		|	InventoryClarification.Products AS Products,
		|	InventoryClarification.Characteristic AS Characteristic,
		|	InventoryClarification.Series AS Series,
		|	InventoryClarification.CompanyCustomer AS CompanyCustomer
		|FROM
		|	InformationRegister.RefinementsOfRetailOutletInventoryAffiliation AS InventoryClarification
		|WHERE
		|	InventoryClarification.Warehouse = &Warehouse
		|	AND InventoryClarification.CompanyCustomer = &Organization";
		QueryResult = RequestForCleanup.Execute();
		If QueryResult.IsEmpty() Then
			Continue;
		EndIf;
		Selection = QueryResult.Select();
		RecordSet = InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation.CreateRecordSet();
		RecordSet.ExtendedReplaceMode = True;
		While Selection.Next() Do
			NewString = RecordSet.Add();
			FillPropertyValues(NewString, Selection);
		EndDo;
		DeletedRecords = DeletedRecords + Selection.Count();
		RecordSet.Write(ReplacementMode.Delete);
	EndDo;
	
	MeasurementKeys = New Structure;
	MeasurementKeys.Insert("Node", String(Recipient));
	PerformanceMonitor.EndTimeMeasurement("FillingOutSpecificationOfInventoryBelongingToRetailOutletsTuples",
		MeasurementStart, TuplesToRecalculate.Count()+TuplesToCleanUp.Count(), WriteJSONValue(MeasurementKeys),);
	PerformanceMonitor.EndTimeMeasurement("FillingOutClarificationOfInventoryBelongingToOutletsOfRemoval",
		MeasurementStart, DeletedRecords, WriteJSONValue(MeasurementKeys), );
		
EndProcedure

// Performs deletion from the register of unused data on the ownership of types of inventory of outlets
//
Procedure DeleteUnusedDataOnInventoryOwnershipOfRetailOutlets() Export
	
	DeleteUnusedInventoryAffiliationDataOfRetailOutlets();
	
EndProcedure

#EndRegion

#Region Private

#Region RetailSales

// Returns the Query Text for the formation of a temporary table of operations and inventory records, which is used when filling
// out the clarification of the inventory ownership of retail outlets and when clearing unused data from the information register.
//
// Parameters:
//  UseNodeSelection - Boolean - If the parameter is set to True, the Node exchange parameter must be set in the request.
//
// Returns:
//  String -
//
Function QueryTextTTInventoryOfOperation(UseNodeSelection = True) Export
	
	QueryText = 
	"SELECT DISTINCT
	|	TS.ProductPricesType AS ProductPricesType
	|INTO TypesOfPrices
	|FROM
	|	ExchangePlan.DataSynchronizationViaUniversalFormat AS ExchangeNode
	|		INNER JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.ProductPricesTypes AS TS
	|		ON ExchangeNode.Ref = TS.Ref
	|WHERE
	|	NOT ExchangeNode.ThisNode
	|	AND ExchangeNode.UploadProductPrices
	|	AND NOT TS.ProductPricesType.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ExchangeNode.Ref AS Node,
	|	TS.Organization AS Organization
	|INTO Companies
	|FROM
	|	ExchangePlan.DataSynchronizationViaUniversalFormat AS ExchangeNode
	|		INNER JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.Companies AS TS
	|		ON ExchangeNode.Ref = TS.Ref
	|WHERE
	|	NOT ExchangeNode.ThisNode
	|	AND ExchangeNode.UseFilterByCompanies
	|	AND NOT TS.Organization.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	ExchangeNode.Ref,
	|	CatCompanies.Ref
	|FROM
	|	Catalog.Companies AS CatCompanies,
	|	ExchangePlan.DataSynchronizationViaUniversalFormat AS ExchangeNode
	|WHERE
	|	NOT ExchangeNode.ThisNode
	|	AND NOT ExchangeNode.UseFilterByCompanies
	|	AND (ExchangeNode.UnloadManagementCompany OR 
	|		CatCompanies.Ref <> VALUE(Catalog.Companies.ManagementCompany))
	|	AND NOT CatCompanies.DeletionMark
	|INDEX BY
	|	Node
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ExchangeNode.Ref AS Node,
	|	TS.Warehouse AS Warehouse,
	|	TS.Warehouse.RetailPriceType AS RetailPriceType,
	|	TS.Warehouse.WarehouseStore AS WarehouseTypeOfWarehouse
	|INTO Warehouses
	|FROM
	|	ExchangePlan.DataSynchronizationViaUniversalFormat AS ExchangeNode
	|		INNER JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.Warehouses AS TS
	|		ON ExchangeNode.Ref = TS.Ref
	|WHERE
	|	NOT ExchangeNode.ThisNode
	|	AND ExchangeNode.UseFilterByWarehouses
	|	AND NOT TS.Warehouse.DeletionMark
	|	AND NOT TS.Warehouse.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	ExchangeNode.Ref,
	|	CatAboutWarehouses.Ref,
	|	CatAboutWarehouses.RetailPriceType,
	|	CatAboutWarehouses.WarehouseStore
	|FROM
	|	Catalog.Warehouses AS CatAboutWarehouses,
	|	ExchangePlan.DataSynchronizationViaUniversalFormat AS ExchangeNode
	|WHERE
	|	NOT ExchangeNode.ThisNode
	|	AND NOT ExchangeNode.UseFilterByWarehouses
	|	AND NOT CatAboutWarehouses.DeletionMark
	|	AND NOT CatAboutWarehouses.IsFolder
	|INDEX BY
	|	Node
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Companies.Organization AS Organization,
	|	Warehouses.Warehouse AS Warehouse,
	|	MAX(Warehouses.WarehouseTypeOfWarehouse = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|		AND TypesOfPrices.ProductPricesType IS NOT NULL) AS FillInInventoryData
	|INTO InventoryOfOperations
	|FROM
	|	Companies AS Companies
	|	INNER JOIN Warehouses AS Warehouses
	|		LEFT JOIN TypesOfPrices AS TypesOfPrices
	|		ON Warehouses.RetailPriceType = TypesOfPrices.ProductPricesType
	|	ON Warehouses.Node = Companies.Node
	|WHERE &SelectionConditionByNode
	|
	|GROUP BY
	|	Companies.Organization,
	|	Warehouses.Warehouse
	|INDEX BY
	|	Warehouse,
	|	Organization
	|";
	
	SelectionConditionByNode = "TRUE";
	If UseNodeSelection Then
		SelectionConditionByNode = "Warehouses.Node = &ExchangeNode";
	EndIf;
	QueryText = StrReplace(QueryText, "&SelectionConditionByNode", SelectionConditionByNode);
	
	Return QueryText;
EndFunction

Procedure DeleteUnusedInventoryAffiliationDataOfRetailOutlets()

	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"InformationRegister.RefinementsOfRetailOutletInventoryAffiliation.DeleteUnusedInventoryAffiliationDataOfRetailOutlets");
	
	NumberOfProcessedData = 0;
	CommentOnMeasuringLongOfOperation = "";
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	QueryTexts = New Array();
	
	// Getting data about current tuples of Organization, Warehouse
	QueryTexts.Add(QueryTextTTInventoryOfOperation(False));
	
	// Getting unused tuples
	QueryTextForGettingUnusedTuples = "SELECT DISTINCT
	|	InventoryClarification.CompanyCustomer AS CompanyCustomer,
	|	InventoryClarification.Warehouse AS Warehouse
	|INTO KeysForSpecifyingInventoryOwnership
	|FROM
	|	InformationRegister.RefinementsOfRetailOutletInventoryAffiliation AS InventoryClarification
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	KeysForSpecifyingInventoryOwnership.CompanyCustomer AS CompanyCustomer,
	|	KeysForSpecifyingInventoryOwnership.Warehouse AS Warehouse
	|FROM
	|	KeysForSpecifyingInventoryOwnership AS KeysForSpecifyingInventoryOwnership
	|		LEFT JOIN InventoryOfOperations AS InventoryOfOperations
	|		ON InventoryOfOperations.Warehouse = KeysForSpecifyingInventoryOwnership.Warehouse
	|		AND InventoryOfOperations.Organization = KeysForSpecifyingInventoryOwnership.CompanyCustomer
	|WHERE
	|	InventoryOfOperations.Warehouse IS NULL";
	
	QueryTexts.Add(QueryTextForGettingUnusedTuples);
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	QueryResult = Query.Execute();
	
	// Removing unused data from the register
	If Not QueryResult.IsEmpty() Then
		AcceptableNumberOfErrors = 3;
		Selection = QueryResult.Select();
		RecordSet = InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation.CreateRecordSet();
		While Selection.Next() Do
		
			NumberOfProcessedData = NumberOfProcessedData + 1;
			RecordSet.Filter.Warehouse.Set(Selection.Warehouse);
			RecordSet.Filter.CompanyCustomer.Set(Selection.CompanyCustomer);
			
			Try
				RecordSet.Write(True);
			Except
				DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				ErrorTextLines = New Array;
				ErrorTextLines.Add(NStr("vi = 'Đã xảy ra lỗi, khi xóa định kỳ dữ liệu không sử dụng về quyền sở hữu hàng tồn kho của các điểm bán lẻ.';
										|ru = 'Во время регламентного удаления неиспользуемых данных о принадлежности запасов торговых точек произошла ошибка.';
										|en = 'An error occurred during scheduled deletion of unused inventory affiliation data of retail outlets.'; fa = 'An error occurred during scheduled deletion of unused inventory affiliation data of retail outlets.';
										|it = 'An error occurred during scheduled deletion of unused inventory affiliation data of retail outlets.';
										|pl = 'An error occurred during scheduled deletion of unused inventory affiliation data of retail outlets.';
										|tr = 'Kullanılmayan satış noktası stok verilerinin rutin olarak silinmesi sırasında bir hata oluştu.'", Common.DefaultLanguageCode()));
				TupleDescriptionTemplate = NStr("vi = 'Cặp giá trị [Kho bãi, Doanh nghiệp] = [%1, %2]';
												|ru = 'Кортеж [Склад, Организация] = [%1, %2]';
												|en = 'Tuples [Warehouse, Company] = [%1, %2]'; fa = 'Tuples [Warehouse, Company] = [%1, %2]';
												|it = 'Tuples [Warehouse, Company] = [%1, %2]';
												|pl = 'Tuples [Warehouse, Company] = [%1, %2]';
												|tr = 'Küme [Ambar, İş yeri] = [%1, %2]'", Common.DefaultLanguageCode());
				ErrorTextLines.Add(StrTemplate(TupleDescriptionTemplate, Selection.Warehouse, Selection.CompanyCustomer));
				ErrorTextLines.Add(DetailErrorDescription);
				
				WriteLogEvent(NStr("vi = 'Xóa dữ liệu không sử dụng về quyền sở hữu hàng tồn kho của các điểm bán lẻ';
									|ru = 'Удаление неиспользуемых данных о принадлежности запасов торговых точек';
									|en = 'Delete unused inventory affiliation data of retail outlets'; fa = 'حذف داده‌های استفاده‌نشده تعلق موجودی فروشگاه‌های خرده‌فروشی';
									|it = 'Delete unused inventory affiliation data of retail outlets';
									|pl = 'Delete unused inventory affiliation data of retail outlets';
									|tr = 'Satış noktası stoklarına ait kullanılmayan verileri sil'", Common.DefaultLanguageCode()),
				                         EventLogLevel.Error, , ,
				                         StrConcat(ErrorTextLines,Chars.LF));
			
				CommentOnMeasuringLongOfOperation = NStr("vi = 'Đã xảy ra lỗi, khi thực hiện đo lường. Xem thông tin chi tiết trong nhật ký sự kiện.';
														|ru = 'При выполнении замера возникли ошибки. Подробная информация в журнале регистрации.';
														|en = 'Errors occurred while sampling. For more information, see the event log.'; fa = 'Errors occurred while sampling. For more information, see the event log.';
														|it = 'Errors occurred while sampling. For more information, see the event log.';
														|pl = 'Errors occurred while sampling. For more information, see the event log.';
														|tr = 'Ölçüm sırasında hatalar oluştu. Daha fazla ayrıntı için olay günlüğüne bakın.'", Common.DefaultLanguageCode());
				
				AcceptableNumberOfErrors = AcceptableNumberOfErrors - 1;
				If AcceptableNumberOfErrors = 0 Then
					Break;
				EndIf;
			EndTry;
			
		EndDo;
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData,, CommentOnMeasuringLongOfOperation);
	
EndProcedure

Procedure UpdateDetailsOfInventoryBelongingToRetailOutlets(Val Organization, Val Warehouse);
	
	MeasurementStart = PerformanceMonitor.StartTimeMeasurement();
	
	QueryModel = RetailSalesLocalization.RequestingConsignorsGoodsData(Organization, Warehouse,, "_Exchange_");
	QueryBatch = QueryModel.QueryBatch;
	
	FinalQueryText = 
	"
	|SELECT
	|	Tab.Products AS Products, 
	|	Tab.Characteristic AS Characteristic, 
	|	Tab.Series AS Series, 
	|	CASE WHEN Tab.Consignor IS NULL OR Tab.Consignor IN (&EmptyConsignor) THEN
	|		UNDEFINED
	|	ELSE
	|		Tab.Consignor
	|	END AS Consignor 
	|INTO DataOnConsignors
	|FROM #TableOfCalculation AS Tab
	|INDEX BY 
	|	Products,
	|	Characteristic,
	|	Series
	|
	|;
	|SELECT
	|	Reg.Products AS Products, 
	|	Reg.Characteristic AS Characteristic, 
	|	Reg.Series AS Series, 
	|	Reg.Consignor AS Consignor
	|INTO SavedExchangeData
	|FROM InformationRegister.RefinementsOfRetailOutletInventoryAffiliation AS Reg
	|WHERE
	|	Reg.Warehouse = &SelectionOfSellerSStorageLocation_Exchange
	|	AND Reg.CompanyCustomer = &SelectionCompanySeller_Exchange
	|INDEX BY 
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|SELECT
	|	ISNULL(SavedData.Products, PaymentData.Products) AS Products,
	|	ISNULL(SavedData.Characteristic, PaymentData.Characteristic) AS Characteristic,
	|	ISNULL(SavedData.Series, PaymentData.Series) AS Series,
	|	&SelectionOfSellerSStorageLocation_Exchange AS Warehouse,
	|	&SelectionCompanySeller_Exchange AS CompanyCustomer,
	|	PaymentData.Consignor AS Consignor,
	|	CASE
	|		WHEN PaymentData.Consignor IS NULL THEN
	|			""Delete""
	|		ELSE
	|			""Merging""
	|	END AS Action
	|	FROM SavedExchangeData AS SavedData
	|	FULL OUTER JOIN DataOnConsignors AS PaymentData
	|
	|		ON SavedData.Products = PaymentData.Products
	|		AND SavedData.Characteristic = PaymentData.Characteristic
	|		AND SavedData.Series = PaymentData.Series
	|WHERE
	|	SavedData.Consignor IS NULL
	|	OR PaymentData.Consignor IS NULL
	|	OR SavedData.Consignor <> PaymentData.Consignor
	|TOTALS BY 
	|	Action
	|";
	FinalQueryText = StrReplace(FinalQueryText, "#TableOfCalculation", QueryBatch[QueryBatch.Count()-1].Presentation);
	
	QueryBatch.Add(FinalQueryText);
	
	QueryText = StrConcat(QueryBatch.UnloadValues(), Chars.LF + ";" + Chars.LF);
	
	Query = New Query(QueryText);
	For Each Itm In QueryModel.QueryOptions Do
		Query.Parameters.Insert(Itm.Key, Itm.Value);
	EndDo;
	EmptyConsignor = New Array;
	EmptyConsignor.Add(Undefined);
	EmptyConsignor.Add(Catalogs.Counterparties.EmptyRef());
	EmptyConsignor.Add(Catalogs.Companies.EmptyRef());
	Query.Parameters.Insert("EmptyConsignor", EmptyConsignor);
	Query.Parameters.Insert("SelectionOfSellerSStorageLocation_Exchange", Warehouse);
	Query.Parameters.Insert("SelectionCompanySeller_Exchange", Organization);
	
	MeasurementStart = PerformanceMonitor.StartTimeMeasurement();
	MeasurementKeys = New Structure;
	MeasurementKeys.Insert("Organization", String(Organization));
	MeasurementKeys.Insert("Warehouse", String(Warehouse));
	
	Results = Query.ExecuteBatch();
	
	PerformanceMonitor.EndTimeMeasurement("FillingOutSpecificationOfInventoryBelongingToRetailOutletsTuplePackage",
		MeasurementStart, , WriteJSONValue(MeasurementKeys), );
	MeasurementStart = PerformanceMonitor.StartTimeMeasurement();
	
	ProcessedRows_ = 0;
	SelectionAction = Results[Results.Count()-1].Select(QueryResultIteration.ByGroups);
	While SelectionAction.Next() Do
		
		Current_Set = InformationRegisters.RefinementsOfRetailOutletInventoryAffiliation.CreateRecordSet();
		Current_Set.ExtendedReplaceMode = True;
		
		DetailsSelection = SelectionAction.Select();
		ProcessedRows_ = ProcessedRows_ + DetailsSelection.Count();
		While DetailsSelection.Next() Do
			NewRecord1 = Current_Set.Add();
			FillPropertyValues(NewRecord1, DetailsSelection);
		EndDo;
		If SelectionAction.Action = "Delete" Then
			CurrentSubstitutionMode = ReplacementMode.Delete;
		Else
			CurrentSubstitutionMode = ReplacementMode.Merge;
		EndIf;
		
		Current_Set.Write(CurrentSubstitutionMode);
		
	EndDo;
	
	PerformanceMonitor.EndTimeMeasurement("FillingInClarificationOfInventoryOfOutletsUpdating",
		MeasurementStart, ProcessedRows_, WriteJSONValue(MeasurementKeys), );
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
