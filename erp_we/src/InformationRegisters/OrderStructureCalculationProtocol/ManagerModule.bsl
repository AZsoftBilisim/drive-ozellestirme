
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Adds error messages to the calculation protocol.
// 
// Parameters:
//  ErrorsStructure - Structure - Error logging parameters:
//		* Errors - Array - a list of errors found.
//		* ErrorType - EnumRef.ErrorsTypesOfProductionOrderStructureCalculation - type of error.
//
Procedure RegisterErrors(ErrorsStructure) Export
	
	SetPrivilegedMode(True);
	
	ErrorType = ErrorsStructure.ErrorType;
	Errors    = ErrorsStructure.Errors;
	
	RecordSet = InformationRegisters.OrderStructureCalculationProtocol.CreateRecordSet();
	
	For Each Error In Errors Do
		
		RecordSet.Filter.ErrorType.Set(ErrorType); // service selection - we specify the fields in the lock space
		RecordSet.Filter.ErrorID.Set(Error.ErrorID);
		
		ThereAreEntriesInProtocol = ValueIsFilled(Error.Protocol);
		
		If ThereAreEntriesInProtocol Then
			NewRecord = RecordSet.Add();
			FillPropertyValues(NewRecord, Error);
			NewRecord.ErrorType = ErrorType;
		EndIf;
		
		RecordSet.Write(True);
		
		If ThereAreEntriesInProtocol Then
			RecordSet.Clear();
		EndIf;
		
	EndDo;
	
EndProcedure

// Deleting the error record from the calculation protocol.
// 
// Parameters:
//  ErrorsStructure - Structure - Error logging parameters:
//		* Errors - Array - list of error ids.
//		* ErrorType - EnumRef.ErrorsTypesOfProductionOrderStructureCalculation - type of error.
//
Procedure RemoveErrors(ErrorsStructure) Export
	
	SetPrivilegedMode(True);
	
	ErrorType = ErrorsStructure.ErrorType;
	Errors    = ErrorsStructure.Errors;
	
	RecordSet = InformationRegisters.OrderStructureCalculationProtocol.CreateRecordSet();
	
	For Each ErrorID In Errors Do
		
		RecordSet.Filter.ErrorType.Set(ErrorType); // service selection - we specify the fields in the lock space
		RecordSet.Filter.ErrorID.Set(ErrorID);
		RecordSet.Write(True);
		
	EndDo;
	
EndProcedure

// Clears the protocol for the production order
// 
// Parameters:
// 	ProductionOrders - Array, DocumentRef.ProductionOrder2_2	- a production order or a list of production orders.
//
Procedure ClearProtocol(Val ProductionOrders) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(ProductionOrders) = Type("Array") Then
		ProductionOrders = CommonClientServer.CollapseArray(ProductionOrders);
	Else
		ProductionOrders = CommonClientServer.ValueInArray(ProductionOrders);
	EndIf;
	
	For Each ProductionOrder In ProductionOrders Do
		
		RecordSet = InformationRegisters.OrderStructureCalculationProtocol.CreateRecordSet();
		RecordSet.Filter.ProductionOrder.Set(ProductionOrder);
		RecordSet.Write(True);
		
	EndDo;
	
EndProcedure

// Protocol constructor.
// 
// Returns:
//  Structure - Protocol Template:
// * Code - Number - error code
// * Data - ValueTable, Structure -  data in any format
// * ErrorText - String - detailed description of the error
Function ProtocolTemplate() Export

	Template = New Structure();
	
	Template.Insert("Code", 0);
	Template.Insert("Data"); // data in any format
	Template.Insert("MessageText", "");
	
	Return Template;
	
EndFunction

#EndRegion
	
#Region Private

#Region AllErrors

Function CheckOrderQueueErrors() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.OrderStructureCalculationProtocol AS OrderStructureCalculationProtocol
	|WHERE
	|	OrderStructureCalculationProtocol.ErrorType IN (
	|			VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError),
	|			VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError))";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure RecalculateErrorsFromOrderQueue() Export
	
	Query = New Query;
	
	#Region ExplosionError
	
	Query.Text = 
	"SELECT TOP 1000
	|	OrderStructureCalculationProtocol.Protocol AS Protocol,
	|	OrderStructureCalculationProtocol.ErrorID AS ErrorID
	|FROM
	|	InformationRegister.OrderStructureCalculationProtocol AS OrderStructureCalculationProtocol
	|WHERE
	|	OrderStructureCalculationProtocol.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError)";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		ErrorsStructure = New Structure();
		ErrorsStructure.Insert("ErrorType", Enums.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError);
		ErrorsStructure.Insert("Errors", New Array());
		
		Table = InformationRegisters.TasksOfBOMOrderStructureCalculation.CreateRecordSet().UnloadColumns();
		
		Selection = QueryResult.Select();
		
		ThereAreRecordsInSelection = Selection.Next();
		
		While ThereAreRecordsInSelection Do
			
			ErrorsStructure.Errors.Add(Selection.ErrorID);
			
			ProtocolStorage = Selection.Protocol; //ValueStorage
			Protocol = ProtocolStorage.Get();
			
			If Not TypeOf(Protocol) = Type("Structure") Or Not Protocol.Property("Data") Then
				Raise NStr("vi = 'Sai định dạng lưu dữ liệu vào giao thức';
							|ru = 'Не правильный формат хранения данных в протоколе.';
							|en = 'Incorrect format of data storage in the protocol.'; fa = 'Incorrect format of data storage in the protocol.';
							|it = 'Formato non corretto di salvataggio dati nel protocollo.';
							|pl = 'Nie prawidłowy format przechowywania danych w protokole.';
							|tr = 'Protokolde yanlış veri depolama formatı.'");
			EndIf;
			
			For Each CurrentRow In Protocol.Data Do
				FillPropertyValues(Table.Add(), CurrentRow, "ProductionOrder");
			EndDo;
			
			ThereAreRecordsInSelection = Selection.Next();
			
			If ThereAreRecordsInSelection Then
				Continue;
			EndIf;
			
			InformationRegisters.OrderStructureCleanupTasks.AddTasks(TMCommonUse.UnloadColumnValues(Table, "ProductionOrder"));
			
			RemoveErrors(ErrorsStructure);
			
			Table.Clear();
			
			QueryResult = Query.Execute();
			Selection = QueryResult.Select();
			
			ThereAreRecordsInSelection = Selection.Next();
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region InventoryAllocationError
	
	Query.Text = 
	"SELECT TOP 1000
	|	OrderStructureCalculationProtocol.Protocol AS Protocol,
	|	OrderStructureCalculationProtocol.ErrorID AS ErrorID
	|FROM
	|	InformationRegister.OrderStructureCalculationProtocol AS OrderStructureCalculationProtocol
	|WHERE
	|	OrderStructureCalculationProtocol.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError)";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		ErrorsStructure = New Structure();
		ErrorsStructure.Insert("ErrorType", Enums.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError);
		ErrorsStructure.Insert("Errors", New Array());
		
		Table = InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.CreateRecordSet().UnloadColumns();
		
		Selection = QueryResult.Select();
		
		ThereAreRecordsInSelection = Selection.Next();
		
		While ThereAreRecordsInSelection Do
			
			ErrorsStructure.Errors.Add(Selection.ErrorID);
			
			ProtocolStorage = Selection.Protocol; //ValueStorage
			Protocol = ProtocolStorage.Get();
			
			If Not TypeOf(Protocol) = Type("Structure") Or Not Protocol.Property("Data") Then
				Raise NStr("vi = 'Sai định dạng lưu dữ liệu vào giao thức';
							|ru = 'Не правильный формат хранения данных в протоколе.';
							|en = 'Incorrect format of data storage in the protocol.'; fa = 'Incorrect format of data storage in the protocol.';
							|it = 'Formato non corretto di salvataggio dati nel protocollo.';
							|pl = 'Nie prawidłowy format przechowywania danych w protokole.';
							|tr = 'Protokolde yanlış veri depolama formatı.'");
			EndIf;
			
			For Each CurrentRow In Protocol.Data Do
				FillPropertyValues(Table.Add(), CurrentRow, "Products,Characteristic,Warehouse,Purpose");
			EndDo;
			
			ThereAreRecordsInSelection = Selection.Next();
			
			If ThereAreRecordsInSelection Then
				Continue;
			EndIf;
			
			InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(Table);
			
			RemoveErrors(ErrorsStructure);
			
			Table.Clear();
			
			QueryResult = Query.Execute();
			Selection = QueryResult.Select();
			
			ThereAreRecordsInSelection = Selection.Next();
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	OrderStructure.StartCalculation();
	
EndProcedure

#EndRegion

#Region ErrorsInSelectionOfSpecificationsInProductionOrders

Procedure PickUpSpecificationsOnHold(Parameters, StorageAddress) Export
	
	TypeOfProduction = Common.ObjectAttributeValue(Parameters.ProductionOrder, "ProductionProcessType");
	
	If TypeOfProduction = Enums.ProductionProcessTypes.PerformRM Then
		BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingBillOfMaterialsForRepairWork();
	Else
		BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	EndIf;
	
	SpecificationRequestParameters = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
	SpecificationRequestParameters.NameOfInputTable            = "OrderSpecifications";
	SpecificationRequestParameters.OutputTableName           = "CurrentSpecifications";
	SpecificationRequestParameters.PriorityOnly           = True;
	SpecificationRequestParameters.DestroyTemporaryTables   = True;
	SpecificationRequestParameters.FinalPackageSeparator   = True;
	
	Query = New Query;
	Query.SetParameter("ProductionOrder", Parameters.ProductionOrder);
	Query.SetParameter("EmptySpecification", Catalogs.BillsOfMaterials.EmptyRef());
	Query.Text = 
	"SELECT
	|
	|	NSICache.Products AS Products,
	|	NSICache.Characteristic AS Characteristic,
	|	NSICache.Warehouse AS Warehouse,
	|	NSICache.Purpose AS Purpose,
	|	NSICache.ProductionOrder AS ProductionOrder
	|
	|INTO Positions
	|FROM
	|	InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|
	|WHERE
	|
	|	NSICache.ErrorID IN (
	|		SELECT
	|			Errors.ErrorID AS ErrorID
	|		FROM
	|			InformationRegister.OrderStructureCalculationProtocol AS Errors
	|		WHERE
	|			Errors.ProductionOrder = &ProductionOrder
	|			AND Errors.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenSelectingBOMs))
	|
	|	AND NSICache.ProductionOrder = &ProductionOrder
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder
	|;
	|SELECT
	|
	|	Plan.Products AS Products,
	|	Plan.Characteristic AS Characteristic,
	|	Plan.Warehouse AS Warehouse,
	|	Plan.Purpose AS Purpose,
	|	Plan.ProductionOrder AS ProductionOrder,
	|
	|	MAX(Plan.BillOfMaterials) AS ParentSpecification, // Restriction
	|	MAX(Plan.CommunicationKeyBillOfMaterialsRow) AS LinkKeyIsBillOfMaterialsStringOfParent
	|
	|INTO Plan
	|FROM
	|
	|	Positions AS Positions
	|
	|		INNER JOIN InformationRegister.OrderStructure AS Plan
	|		ON Positions.Products        = Plan.Products
	|		 AND Positions.Characteristic      = Plan.Characteristic
	|		 AND Positions.Warehouse               = Plan.Warehouse
	|		 AND Positions.Purpose          = Plan.Purpose
	|		 AND Positions.ProductionOrder = Plan.ProductionOrder
	|		 AND Plan.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder
	|;
	|SELECT
	|
	|	RECORDAUTONUMBER() AS TheIndexOfTheData,
	|
	|	Plan.Products AS Products,
	|	Plan.Characteristic AS Characteristic,
	|	Plan.Warehouse AS Warehouse,
	|	Plan.Purpose AS Purpose,
	|	Plan.ProductionOrder AS ProductionOrder,
	|
	|	Plan.Products.ProductKind AS ProductKind,
	|
	|	Plan.ProductionOrder.Department AS ProductionDispatcherBusinessUnit,
	|	Plan.ProductionOrder.LineOfBusiness AS LineOfBusiness,
	|	Plan.ProductionOrder.EarliestStartDate AS ProductionStart,
	|
	|	ISNULL(WorksToPerform.UnderRepairProduct, VALUE(Catalog.Products.EmptyRef)) AS UnderRepairProduct,
	|	ISNULL(WorksToPerform.UnderRepairVariant, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS UnderRepairVariant
	|
	|INTO OrderSpecifications
	|FROM
	|	Plan AS Plan
	|
	|		LEFT JOIN Catalog.BillsOfMaterials.WorksToPerform AS WorksToPerform
	|		ON Plan.ParentSpecification = WorksToPerform.Ref
	|		 AND Plan.LinkKeyIsBillOfMaterialsStringOfParent = WorksToPerform.ConnectionKey
	|
	|INDEX BY
	|	TheIndexOfTheData
	|;
	|
	|" + ProductDataManagement.RequestTextForProductItemsSpecifications(SpecificationRequestParameters, BOMSelectionParameters)
	 + "
	|SELECT
	|
	|	OrderSpecifications.Products        AS Products,
	|	OrderSpecifications.Characteristic      AS Characteristic,
	|	OrderSpecifications.Warehouse               AS Warehouse,
	|	OrderSpecifications.Purpose          AS Purpose,
	|	OrderSpecifications.ProductionOrder AS ProductionOrder,
	|	CurrentSpecifications.BillOfMaterials   AS BillOfMaterials
	|
	|FROM
	|	OrderSpecifications AS OrderSpecifications
	|
	|		INNER JOIN CurrentSpecifications AS CurrentSpecifications
	|		ON OrderSpecifications.TheIndexOfTheData = CurrentSpecifications.TheIndexOfTheData
	|";
	ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(Query, BOMSelectionParameters);
	
	ReplacementData = Query.Execute().Unload();
	ProcessedItemsCount = OrderStructureInternal.ReplaceSpecifications(ReplacementData);
	Result = New Structure("ProcessedItemsCount", ProcessedItemsCount);
	OrderStructure.StartCalculation();
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure CheckAndOutputSpecificationSelectionErrors(Parameters, StorageAddress) Export

	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ProductionOrder", Parameters.ProductionOrder);
	Query.Text = "
	|SELECT
	|	Errors.Protocol AS Protocol
	|FROM
	|	InformationRegister.OrderStructureCalculationProtocol AS Errors
	|WHERE
	|	Errors.ProductionOrder = &ProductionOrder
	|	AND Errors.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenSelectingBOMs)
	|";
	
	Errors = New ValueTable();

	Errors.Columns.Add("Products", Metadata.InformationRegisters.CacheOfOrderStructureMasterData.Dimensions.Products.Type);
	Errors.Columns.Add("Characteristic", Metadata.InformationRegisters.CacheOfOrderStructureMasterData.Dimensions.Characteristic.Type);
	Errors.Columns.Add("Warehouse", Metadata.InformationRegisters.CacheOfOrderStructureMasterData.Dimensions.Warehouse.Type);
	Errors.Columns.Add("Purpose", Metadata.InformationRegisters.CacheOfOrderStructureMasterData.Dimensions.Purpose.Type);
	Errors.Columns.Add("ProductionOrder", Metadata.InformationRegisters.CacheOfOrderStructureMasterData.Dimensions.ProductionOrder.Type);
	Errors.Columns.Add("BillOfMaterials", Metadata.InformationRegisters.CacheOfOrderStructureMasterData.Dimensions.BillOfMaterials.Type);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ProtocolStorage = Selection.Protocol; //ValueStorage
		FillPropertyValues(Errors.Add(), ProtocolStorage.Get());
	EndDo;
	
	Query.SetParameter("Errors", Errors);
	
	Query.Text = "
	|SELECT
	|
	|	Errors.Products        AS Products,
	|	Errors.Characteristic      AS Characteristic,
	|	Errors.Warehouse               AS Warehouse,
	|	Errors.Purpose          AS Purpose,
	|	Errors.ProductionOrder AS ProductionOrder
	|
	|INTO Errors
	|FROM 
	|	&Errors AS Errors
	|
	|INDEX BY
	|
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder
	|;
	|
	|SELECT
	|
	|	Errors.Products        AS Products,
	|	Errors.Characteristic      AS Characteristic,
	|	Errors.Warehouse               AS Warehouse,
	|	Errors.Purpose          AS Purpose,
	|	Errors.ProductionOrder AS ProductionOrder,
	|
	|	CASE
	|		WHEN COUNT(DISTINCT RegisterRecords.SemiFinishedProductBOM) > 1 THEN &T2
	|		ELSE &T1
	|	END AS Cause
	|
	|FROM
	|	Errors AS Errors
	|
	|	LEFT JOIN InformationRegister.OrderStructure AS RegisterRecords
	|	ON RegisterRecords.Products        = Errors.Products
	|	 AND RegisterRecords.Characteristic      = Errors.Characteristic
	|	 AND RegisterRecords.Warehouse               = Errors.Warehouse
	|	 AND RegisterRecords.Purpose          = Errors.Purpose
	|	 AND RegisterRecords.ProductionOrder = Errors.ProductionOrder
	|	 AND RegisterRecords.SemiFinishedProductBOM <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|GROUP BY
	|	Errors.Products,
	|	Errors.Characteristic,
	|	Errors.Warehouse,
	|	Errors.Purpose,
	|	Errors.ProductionOrder
	|";
	
	Query.SetParameter("T1", NStr("vi = 'Không tìm thấy bảng kê chi tiết';
									|ru = 'Не найдена спецификация';
									|en = 'Bill of materials is not found'; fa = 'Bill of materials is not found';
									|it = 'Non è stata trovata la specifica';
									|pl = 'Nie znaleziono specyfikacji';
									|tr = 'Ürün reçetesi bulunmadı'"));
	Query.SetParameter("T2", NStr("vi = 'Không được phép chỉ định các bảng kê chi tiết khác nhau đối với một đối tượng phân tích kế toán mặt hàng';
									|ru = 'Не допускается указание различных спецификаций для одной аналитики учета номенклатуры';
									|en = 'You cannot specify different bills of materials for the same inventory location attributes'; fa = 'You cannot specify different bills of materials for the same inventory location attributes';
									|it = 'Non è concessa l''indicazione di diverse specifiche per una analitica di contabilità di nomenclatura';
									|pl = 'Nie jest dopuszczalne podanie różnych specyfikacji dla jednaj analityki ewidencji produktu';
									|tr = 'Aynı öğe muhasebe boyutu için farklı ürün reçetelerinin belirtilmesine izin verilmemektedir'"));

	DataSets = New Structure("ErrorLog", Query.Execute().Unload());

	DataCompositionSchema = InformationRegisters.OrderStructureCalculationProtocol.GetTemplate("CompositionTemplateToDisplayErrorsOfSelectionOfBOMs");
	
	DetailsData = New DataCompositionDetailsData;
	
	DataCompositionSettings = DataCompositionSchema.SettingVariants.Find("Main").Settings; // DataCompositionSettings
	TemplateComposer = New DataCompositionTemplateComposer;
	
	LayoutTemplateParameter = DataCompositionSettings.OutputParameters.Items.Find("AppearanceTemplate");
	LayoutTemplateParameter.Value = "ReportingBeige";
	LayoutTemplateParameter.Use = True;
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		DataCompositionSettings,
		DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	
	CompositionProcessor.Initialize(
		CompositionTemplate,
		DataSets,
		DetailsData,
		True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(SpreadsheetDocument);
	OutputProcessor.Output(CompositionProcessor, True);
	
	Result = New Structure();
	
	Result.Insert("SpreadsheetDocument", SpreadsheetDocument);
	Result.Insert("DataCompositionSchema", DataCompositionSchema);
	Result.Insert("DetailsData", DetailsData);

	PutToTempStorage(Result, StorageAddress);

EndProcedure

#EndRegion

#Region ProductSeparationErrors

Procedure RecalculateSpecificationsDeferred(Parameters, StorageAddress) Export
	
	Errors = ProductSeparationErrors(Parameters.ProductionOrder);
	
	Jobs = Errors.Copy(,"BillOfMaterials,ProductionOrder");
	Jobs.GroupBy("BillOfMaterials,ProductionOrder");
	
	InformationRegisters.TasksOfBOMOrderStructureCalculation.AddTasksFullCalculation(Jobs);
	
	OrderStructure.StartCalculation();
	
EndProcedure

Procedure CheckAndDeduceProductSeparationErrors(Parameters, StorageAddress) Export

	ErrorLog = ProductSeparationErrors(Parameters.ProductionOrder);
	
	DataSets = New Structure("ErrorLog", ErrorLog);

	DataCompositionSchema = InformationRegisters.OrderStructureCalculationProtocol.GetTemplate("CompositionTemplateToDisplayProductStructureExplosionErrors");
	
	DetailsData = New DataCompositionDetailsData;
	
	DataCompositionSettings = DataCompositionSchema.SettingVariants.Find("Main").Settings; // DataCompositionSettings
	TemplateComposer = New DataCompositionTemplateComposer;
	
	LayoutTemplateParameter = DataCompositionSettings.OutputParameters.Items.Find("AppearanceTemplate");
	LayoutTemplateParameter.Value = "ReportingBeige";
	LayoutTemplateParameter.Use = True;
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		DataCompositionSettings,
		DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	
	CompositionProcessor.Initialize(
		CompositionTemplate,
		DataSets,
		DetailsData,
		True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(SpreadsheetDocument);
	OutputProcessor.Output(CompositionProcessor, True);
	
	Result = New Structure();
	
	Result.Insert("ErrorsTypes", TMCommonUse.UniqueValuesFromTableColumn(ErrorLog, "ErrorType"));
	
	Result.Insert("SpreadsheetDocument", SpreadsheetDocument);
	Result.Insert("DataCompositionSchema", DataCompositionSchema);
	Result.Insert("DetailsData", DetailsData);

	PutToTempStorage(Result, StorageAddress);

EndProcedure

Function ProductSeparationErrors(ProductionOrder)

	Query = New Query;
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.Text = "
	|SELECT
	|	Errors.ErrorType AS ErrorType,
	|	Errors.Protocol AS Protocol,
	|	Errors.ShortDescription AS ShortDescription
	|FROM
	|	InformationRegister.OrderStructureCalculationProtocol AS Errors
	|WHERE
	|	Errors.ProductionOrder = &ProductionOrder
	|	AND Errors.ErrorType IN (VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError),
	|						  VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenFillingTheBOMData))
	|";
	
	ErrorLog = New ValueTable();
	ErrorLog.Columns.Add("ErrorType", New TypeDescription("EnumRef.ErrorsTypesOfProductionOrderStructureCalculation"));
	ErrorLog.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	ErrorLog.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	ErrorLog.Columns.Add("MessageText", New TypeDescription("String"));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ProtocolStorage = Selection.Protocol; //ValueStorage
		Protocol = ProtocolStorage.Get();
		
		If Not TypeOf(Protocol) = Type("Structure") Then
			Continue;
		EndIf;
		
		If Selection.ErrorType = Enums.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError Then
		
			If TMCommonUseClientServer.HasObjectAttribute(Protocol.Data[0], "BillOfMaterials") Then
		
				Template = NStr("vi = 'Khi tách bảng kê chi tiết %1 đã xảy ra lỗi không thể khắc phục do nguyên nhân: %2';
								|ru = 'При разузловании спецификации %1 возникла неразрешимая ошибка по причине: %2';
								|en = 'An irresolvable error occurred when exploding the %1 bill of materials due to: %2'; fa = 'An irresolvable error occurred when exploding the %1 bill of materials due to: %2';
								|it = 'Durante l''esplosione delle specifiche %1 si è verificato un errore irrisolvibile a causa di: %2';
								|pl = 'Podczas rozdzielenia specyfikacji %1 wystąpił błąd z powodu: %2';
								|tr = '%1 ürün reçetesi ayrıştırılırken çözülemeyen bir hata oluşmasının nedeni: %2'");
				NewRow = ErrorLog.Add();
				NewRow.ErrorType = Selection.ErrorType;
				NewRow.BillOfMaterials = Protocol.Data[0].BillOfMaterials;
				NewRow.ProductionOrder = Protocol.Data[0].ProductionOrder;
				NewRow.MessageText = StrTemplate(Template, NewRow.BillOfMaterials, Selection.ShortDescription);
			
			Else
				
				Template = NStr("vi = 'Khi tách đơn hàng đã xảy ra lỗi không thể khắc phục do nguyên nhân: %1';
								|ru = 'При разузловании заказа возникла неразрешимая ошибка по причине: %1';
								|en = 'An irresolvable error occurred when exploding the order due to: %1'; fa = 'An irresolvable error occurred when exploding the order due to: %1';
								|it = 'Durante l''esplosione dell''ordine si è verificato un errore irrisolvibile a causa di: %1';
								|pl = 'Podczas rozdzielenia zamówienia wystąpił nierozwiązywalny błąd z powodu: %1';
								|tr = 'Sipariş ayrıştırılırken çözülemeyen bir hata oluşmasının nedeni: %1'");
				NewRow = ErrorLog.Add();
				NewRow.ErrorType = Selection.ErrorType;
				NewRow.BillOfMaterials = Undefined;
				NewRow.ProductionOrder = Protocol.Data[0].ProductionOrder;
				NewRow.MessageText = StrTemplate(Template, Selection.ShortDescription);
				
			EndIf;
			
		EndIf;
		
		If Selection.ErrorType = Enums.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenFillingTheBOMData Then
			
			MessageTexts_ = StrSplit(Protocol.MessageText, ";");
			
			For Each MessageText In MessageTexts_ Do
				
				NewRow = ErrorLog.Add();
				NewRow.ErrorType = Selection.ErrorType;
				NewRow.BillOfMaterials = Protocol.Data.BillOfMaterials;
				NewRow.ProductionOrder = Protocol.Data.ProductionOrder;
				NewRow.MessageText = MessageText;
				
			EndDo;
			
		EndIf;

	EndDo;
	
	Return ErrorLog;
	
EndFunction

#EndRegion

#EndRegion

#EndIf