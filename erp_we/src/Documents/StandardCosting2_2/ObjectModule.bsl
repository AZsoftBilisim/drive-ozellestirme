#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
	If TypeOf(FillingData) = Type("Array") Then
		
		If FillingData.Count() = 0 Then
			Return;
		EndIf;
		
		CheckPossibilityOfEnteringBasedOn(FillingData);
		
		If TypeOf(FillingData[0]) = Type("CatalogRef.BillsOfMaterials") Then
			FillInWithBOMs(FillingData);
		ElsIf TypeOf(FillingData[0]) = Type("DocumentRef.ProductionOrder2_2") Then
			FillInFromOrder(FillingData, False);
		ElsIf TypeOf(FillingData[0]) = Type("DocumentRef.ProductionStage2_2") Then
			FillInByStage(FillingData);
		ElsIf TypeOf(FillingData[0]) = Type("DocumentRef.ProductionPlan") Then
			FillInAccordingToProductionPlan(FillingData);
		EndIf;
		
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "CostObjects";
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		CheckParameters);
		
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "CostObjects";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	If CostObject = Enums.CostObjects.ProductionOrder Then
		ProductionOrders = CommonClientServer.CollapseArray(CostObjects.UnloadColumn("Object"));
		CheckPossibilityOfCalculatingProductStandardCost(Ref, ProductionOrders,
			Cancel);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If DocumentsPosting.DocumentProperties(ThisObject).WriteMode = DocumentWriteMode.UndoPosting Then
		ThisIsHolding = False;
		RecordBackgroundEventQueue(ThisIsHolding);
		StartBackgroundMotionProcessing(Ref, ThisIsHolding);
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	ThisIsHolding = True;
	RecordBackgroundEventQueue(ThisIsHolding);
	StartBackgroundMotionProcessing(Ref, ThisIsHolding);
		
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Checks the possibility of calculating the product standard cost for production orders
// 
// Parameters:
//  ProductStandardCostLink - DocumentRef.StandardCosting2_2
//  ProductionOrders - Array of DocumentRef.ProductionOrder2_2 - an array of links to orders for production, 
//   for which it is necessary to check the readiness of the data for the calculation of the planned calculation.
//  Cancel - Boolean
// 
Procedure CheckPossibilityOfCalculatingProductStandardCost(ProductStandardCostLink, ProductionOrders, Cancel) Export

	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("ReferencesArrray", ProductionOrders);
	Query.Text = "SELECT
	|	ProductionOrder2_2.Ref AS Ref,
	|	ProductionOrder2_2.DynamicStructure AS DynamicStructure,
	|	ProductionOrder2_2.Posted AS Posted,
	|	ProductionOrder2_2.Status AS Status
	|INTO ProductionOrders
	|FROM
	|	Document.ProductionOrder2_2 AS ProductionOrder2_2
	|WHERE
	|	ProductionOrder2_2.Ref IN(&ReferencesArrray)
	|
	|INDEX BY
	|	DynamicStructure
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Table.DynamicStructure) AS ThereAreOrdersDynamicStructure,
	|	MAX(NOT Table.DynamicStructure) AS ThereAreOrdersStaticStructure
	|FROM
	|	ProductionOrders AS Table
	|HAVING
	|	MAX(Table.DynamicStructure) IS NOT NULL
	|";
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		MessageText = NStr("vi = 'Để tính giá thành dự kiến, cần chọn ít nhất một đơn hàng sản xuất trong phần bảng ""Đơn hàng sản xuất"".';
							|ru = 'Для выполнения расчета плановой калькуляции необходимо выбрать как минимум один заказ на производство, в табличной части ""Заказы на производство"".';
							|en = 'To calculate the product standard cost, select at least one production order in the ""Production orders"" table.'; fa = 'To calculate the product standard cost, select at least one production order in the ""Production orders"" table.';
							|it = 'To calculate the product standard cost, select at least one production order in the ""Production orders"" table.';
							|pl = 'To calculate the product standard cost, select at least one production order in the ""Production orders"" table.';
							|tr = 'Planlı maliyetlendirme muhasebesini yapabilmek için, ""Üretim siparişleri"" tablosundan en az bir üretim siparişi seçilmelidir.'");
		Common.MessageToUser(MessageText, ProductStandardCostLink, , , Cancel);
		Return;
	EndIf;
	
	SelectionOrderTypes = QueryResult.Select();
	SelectionOrderTypes.Next();
	
	QueryTexts = New Array();
	QueryTexts.Add(Documents.ProductionOrder2_2.QueryTextTTStageGenerationIsRequired(SelectionOrderTypes));
	// Parameters for the request above
	Query.SetParameter("StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	Query.SetParameter("TheProductionScheduleIsUsed", TheProductionScheduleIsUsed);
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());

	QueryText = "
	|SELECT
	|	DD.Ref AS ProductionOrder,
	|	1 AS ErrorCode,
	|	UNDEFINED AS ErrorObject
	|FROM TTIsRequiredToFormStages AS DD
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionOrders.Ref AS ProductionOrder,
	|	2 AS ErrorCode,
	|	UNDEFINED AS ErrorObject
	|FROM
	|	ProductionOrders AS ProductionOrders
	|WHERE
	|	TRUE IN (SELECT TOP 1
	|				TRUE
	|			FROM Document.ProductionStage2_2 AS Stages
	|			WHERE ProductionOrders.Posted
	|				AND Stages.ReferenceOrder = ProductionOrders.Ref
	|				AND Stages.Posted
	|				AND Stages.Status = VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated)
	|			)
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionOrders.Ref AS ProductionOrder,
	|	3 AS ErrorCode,
	|	UNDEFINED AS ErrorObject
	|FROM
	|	ProductionOrders AS ProductionOrders
	|WHERE
	|	ProductionOrders.DynamicStructure
	|	AND ProductionOrders.Status <> VALUE(Enum.ProductionOrderStatuses2_2.BeingGenerated)
	|	AND ProductionOrders.Posted
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationProtocol AS OrderStructureCalculationProtocol
	|		WHERE
	|			ProductionOrders.Ref = OrderStructureCalculationProtocol.ProductionOrder
	|			AND OrderStructureCalculationProtocol.ErrorType IN (&VerifiableTypesOfErrorsDinProductionOrders)
	|		)
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Ref AS ProductionOrder,
	|	4 AS ErrorCode,
	|	UNDEFINED AS ErrorObject
	|FROM ProductionOrders AS DD
	|WHERE
	|	DD.Posted
	|	AND DD.DynamicStructure
	|	AND (
	|		TRUE IN (SELECT TOP 1
	|				TRUE
	|				FROM
	|					InformationRegister.TasksOfBOMOrderStructureCalculation AS T
	|				WHERE
	|					T.ProductionOrder = DD.Ref)
	|		OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation AS T
	|				WHERE
	|					T.ProductionOrder = DD.Ref)
	|		OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS T
	|				WHERE
	|					T.ProductionOrder = DD.Ref)
	|		OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS T
	|				WHERE
	|					T.ProductionOrder = DD.Ref)
	|		OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.OrderStructureCleanupTasks AS T
	|				WHERE
	|					T.ProductionOrder = DD.Ref)
	|		OR &ProductionSchedulesAreUsed
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Ref AS ProductionOrder,
	|	5 AS ErrorCode,
	|	UNDEFINED AS ErrorObject
	|FROM ProductionOrders AS DD
	|WHERE
	|	NOT DD.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	DD.Ref AS ProductionOrder,
	|	6 AS ErrorCode,
	|	UNDEFINED AS ErrorObject
	|FROM ProductionOrders AS DD
	|WHERE
	|	DD.Status = VALUE(Enum.ProductionOrderStatuses2_2.BeingGenerated)
	|";
	
	If TheProductionScheduleIsUsed Then
		QueryText = StrReplace(QueryText, "OR &ProductionSchedulesAreUsed", "");
	Else
		QueryText = StrReplace(QueryText, "OR &ProductionSchedulesAreUsed", "OR TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					InformationRegister.OrderStructureCalculationJobsProductionSchedule AS T
		|				WHERE
		|					T.ProductionOrder = DD.Ref)");
	EndIf;
	
	ErrorCodes = New Map();
	ErrorCodes.Insert(1, NStr("vi = 'Để hạch toán tính giá thành kế hoạch, cần lập kế hoạch chứng từ %1 - tạo công đoạn sản xuất.';
								|ru = 'Для расчета плановой калькуляции, требуется запланировать документ %1 - создать этапы производства.';
								|en = 'To calculate the product standard cost, schedule the %1 document: create production stages.'; fa = 'To calculate the product standard cost, schedule the %1 document: create production stages.';
								|it = 'To calculate the product standard cost, schedule the %1 document: create production stages.';
								|pl = 'To calculate the product standard cost, schedule the %1 document: create production stages.';
								|tr = 'Standart ürün maliyetinin hesaplanması için %1 belgesinin planlanması gerekmektedir; üretim aşamaları oluştur.'"));
	ErrorCodes.Insert(2, NStr("vi = 'Trong cấu trúc chứng từ %1, có công đoạn/các công đoạn ở trạng thái ""Đang lập"" thì việc hạch toán tính giá thành kế hoạch có thể không chính xác.';
								|ru = 'В структуре документа %1, есть этап/этапы в статусе ""Формируется"", расчет плановой калькуляции может быть некорректен.';
								|en = 'The structure of the ""%1"" document contains a stage/stages with the ""Created"" status. The product standard cost may be calculated incorrectly.'; fa = 'The structure of the ""%1"" document contains a stage/stages with the ""Created"" status. The product standard cost may be calculated incorrectly.';
								|it = 'The structure of the ""%1"" document contains a stage/stages with the ""Created"" status. The product standard cost may be calculated incorrectly.';
								|pl = 'The structure of the ""%1"" document contains a stage/stages with the ""Created"" status. The product standard cost may be calculated incorrectly.';
								|tr = '%1 belgesinin yapısındaki ""Oluşturuluyor"" durumunda aşama/aşamalar mevcut, standart ürün  maliyetinin hesaplaması yanlış olabilir.'"));
	ErrorCodes.Insert(3, NStr("vi = 'Có lỗi trong tính toán cấu trúc động của chứng từ %1, việc hạch toán tính giá thành kế hoạch có thể không chính xác.';
								|ru = 'Есть ошибки в расчете динамической структуры документа %1, расчет плановой калькуляции может быть некорректен.';
								|en = 'There are errors in calculating the dynamic structure of the ""%1"" document. The product standard cost may be calculated incorrectly.'; fa = 'There are errors in calculating the dynamic structure of the ""%1"" document. The product standard cost may be calculated incorrectly.';
								|it = 'There are errors in calculating the dynamic structure of the ""%1"" document. The product standard cost may be calculated incorrectly.';
								|pl = 'There are errors in calculating the dynamic structure of the ""%1"" document. The product standard cost may be calculated incorrectly.';
								|tr = '%1 belgesinin dinamik yapısının hesaplanmasında hatalar mevcut, standart ürün maliyetinin hesaplaması yanlış olabilir.'"));
	ErrorCodes.Insert(4, NStr("vi = 'Để hạch toán tính giá thành kế hoạch, cần tính cấu trúc động của chứng từ %1.';
								|ru = 'Для расчета плановой калькуляции, требуется рассчитать динамическую структуру документа %1.';
								|en = 'To calculate the product standard cost, calculate the dynamic structure of the ""%1"" document.'; fa = 'To calculate the product standard cost, calculate the dynamic structure of the ""%1"" document.';
								|it = 'To calculate the product standard cost, calculate the dynamic structure of the ""%1"" document.';
								|pl = 'To calculate the product standard cost, calculate the dynamic structure of the ""%1"" document.';
								|tr = 'Standart ürün maliyetinin hesaplanması için %1 belgesinin dinamik yapısının hesaplanması gerekmektedir.'"));
	ErrorCodes.Insert(5, NStr("vi = 'Để hạch toán tính giá thành kế hoạch, cần kết chuyển chứng từ %1.';
								|ru = 'Для расчета плановой калькуляции, документ %1, должен быть проведен.';
								|en = 'To calculate the product standard cost, post the ""%1"" document.'; fa = 'To calculate the product standard cost, post the ""%1"" document.';
								|it = 'To calculate the product standard cost, post the ""%1"" document.';
								|pl = 'To calculate the product standard cost, post the ""%1"" document.';
								|tr = 'Standart ürün maliyetinin hesaplanması için %1 belgesinin kaydedilmesi gerekmektedir.'"));
	ErrorCodes.Insert(6, NStr("vi = 'Để hạch toán tính giá thành kế hoạch, chứng từ %1 cần ở trạng thái ""Để sản xuất"" hoặc ""Đã đóng"".';
								|ru = 'Для расчета плановой калькуляции, документ %1, должен быть в статусе ""К производству"" или ""Закрыт"".';
								|en = 'To calculate the product standard cost, the ""%1"" document status must be set to ""For production"" or ""Closed"".'; fa = 'To calculate the product standard cost, the ""%1"" document status must be set to ""For production"" or ""Closed"".';
								|it = 'To calculate the product standard cost, the ""%1"" document status must be set to ""For production"" or ""Closed"".';
								|pl = 'To calculate the product standard cost, the ""%1"" document status must be set to ""For production"" or ""Closed"".';
								|tr = 'Standart ürün maliyetinin hesaplanması için %1 belgesi ""Üretilecek"" veya ""Kapalı"" durumunda olmalıdır.'"));
	
	QueryTexts.Add(QueryText);
	Query.Text = ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	
	VerifiableTypesOfErrorsDinProductionOrders = New Array();
	ErrorsTypes = Enums.ErrorsTypesOfProductionOrderStructureCalculation;
	VerifiableTypesOfErrorsDinProductionOrders.Add(ErrorsTypes.ExplosionError);
	VerifiableTypesOfErrorsDinProductionOrders.Add(ErrorsTypes.AnErrorOccurredWhenFillingTheBOMData);
	VerifiableTypesOfErrorsDinProductionOrders.Add(ErrorsTypes.AnErrorOccurredWhenSelectingBOMs);
	Query.SetParameter("VerifiableTypesOfErrorsDinProductionOrders",
		VerifiableTypesOfErrorsDinProductionOrders);
	
	QueryBackup = Query.Execute();
	If QueryBackup.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryBackup.Select();
	While Selection.Next() Do
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorCodes.Get(Selection.ErrorCode),
			Selection.ProductionOrder,
			Selection.ErrorObject);
		Common.MessageToUser(MessageText, ProductStandardCostLink, , , Cancel);
	EndDo;

	SetPrivilegedMode(False);
	
EndProcedure

Procedure InitializeDocument()
	
	Organization 	= SettingsValueCached.GetDefaultOrganization(Organization);
	Author			= Users.CurrentUser();
	
EndProcedure

Procedure RecordBackgroundEventQueue(ThisIsHolding)
	
	Queue = New ValueTable;
	Queue.Columns.Add("StandardCostEstimate", New TypeDescription("DocumentRef.StandardCosting2_2"));
	Queue.Columns.Add("UndoPosting", New TypeDescription("Boolean"));
	
	If ThisIsHolding Then
		InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(Ref);
	EndIf;
	LineQueue = Queue.Add();
	LineQueue.StandardCostEstimate = Ref;
	LineQueue.UndoPosting = Not ThisIsHolding;
	
	InformationRegisters.CalculationQueueOfStandardCostEstimates.WriteQueue(Queue, Ref);
	NewState = ?(ThisIsHolding,
			Enums.StatesOfStandardCostEstimateCalculation.Calculating,
			Enums.StatesOfStandardCostEstimateCalculation.NotCalculated);
	InformationRegisters.StatesOfStandardCostEstimates.SetState(Ref, NewState);
	
EndProcedure

Procedure StartBackgroundMotionProcessing(StandardCostEstimate, ThisIsHolding)
	
	Documents.StandardCosting2_2.StartingBackgroundJob(StandardCostEstimate, ThisIsHolding);
	
EndProcedure

Procedure FillInWithBOMs(ObjectsArray)
	
	QueryText = 
		"SELECT
		|	Products_1.Products AS Products,
		|	Products_1.Characteristic AS Characteristic,
		|	SUM(CAST(Products_1.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15,3))) AS Count,
		|	SUM(Products_1.NumberOfPackages) AS NumberOfPackages,
		|	Products_1.Package AS Package,
		|	Products_1.Ref AS Object
		|FROM
		|	Catalog.BillsOfMaterials.ManufacturedProducts AS Products_1
		|WHERE
		|	Products_1.Ref IN(&ObjectsArray)
		|
		|GROUP BY
		|	Products_1.Products,
		|	Products_1.Package,
		|	Products_1.Characteristic,
		|	Products_1.Ref";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Products_1.Package",
			"Products_1.Products"));
	
	Query = New Query(QueryText);
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	CostObjects.Load(Query.Execute().Unload());
	Basis = ObjectsArray[0];
	
EndProcedure

Procedure FillInFromOrder(FillingData, FillingInByStage)
	
	CostObject = Enums.CostObjects.ProductionOrder;
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductionOrder2_2ManufacturedProduct.Products AS Products,
		|	ProductionOrder2_2ManufacturedProduct.Characteristic AS Characteristic,
		|	ProductionOrder2_2ManufacturedProduct.Package AS Package,
		|	SUM(ProductionOrder2_2ManufacturedProduct.NumberOfPackages) AS NumberOfPackages,
		|	SUM(ProductionOrder2_2ManufacturedProduct.Count) AS Count,
		|	ProductionOrder2_2.Ref AS Object,
		|	ProductionOrder2_2.Department AS ProductionDispatcherBusinessUnit,
		|	ProductionOrder2_2ManufacturedProduct.Purpose AS Purpose,
		|	ProductionOrder2_2.Organization AS Organization
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS ProductionOrder2_2ManufacturedProduct
		|		LEFT JOIN Document.ProductionOrder2_2 AS ProductionOrder2_2
		|		ON ProductionOrder2_2ManufacturedProduct.Ref = ProductionOrder2_2.Ref
		|			AND (NOT ProductionOrder2_2ManufacturedProduct.Canceled)
		|WHERE
		|	ProductionOrder2_2.Ref IN(&ObjectsArray)
		|
		|GROUP BY
		|	ProductionOrder2_2ManufacturedProduct.Characteristic,
		|	ProductionOrder2_2ManufacturedProduct.Package,
		|	ProductionOrder2_2.Ref,
		|	ProductionOrder2_2ManufacturedProduct.Products,
		|	ProductionOrder2_2ManufacturedProduct.Purpose,
		|	ProductionOrder2_2.Department,
		|	ProductionOrder2_2.Organization";
	
	Query.SetParameter("ObjectsArray", FillingData);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		ProductionDispatcherBusinessUnit = Selection.ProductionDispatcherBusinessUnit;
		Organization = Selection.Organization;
		NewObject = CostObjects.Add();
		FillPropertyValues(NewObject, Selection);
		
	EndDo;
	
	If Not FillingInByStage Then
		Basis = FillingData[0];
	EndIf;
	
EndProcedure

Procedure FillInByStage(FillingData)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductionStage2_2.ReferenceOrder
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage2_2
		|WHERE
		|	ProductionStage2_2.Ref IN(&ObjectsArray)";
	
	Query.SetParameter("ObjectsArray", FillingData);
	
	FillInFromOrder(Query.Execute().Unload().UnloadColumn("ReferenceOrder"), True);
	Basis = FillingData[0];
	
EndProcedure

Procedure FillInAccordingToProductionPlan(FillingData)
	
	CostObject = Enums.CostObjects.BillOfMaterial;
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DPP.Products AS Products,
	|	DPP.Characteristic AS Characteristic,
	|	DPP.Package AS Package,
	|	SUM(DPP.NumberOfPackages) AS NumberOfPackages,
	|	SUM(DPP.Count) AS Count,
	|	DD.Department AS ProductionDispatcherBusinessUnit,
	|	DD.Purpose AS Purpose,
	|	DPP.BillOfMaterials AS Object
	|FROM
	|	Document.ProductionPlan AS DD
	|		INNER JOIN Document.ProductionPlan.ManufacturedProduct AS DPP
	|		ON DD.Ref IN (&ObjectsArray)
	|			AND DD.Ref = DPP.Ref
	|			AND NOT DPP.SemiFinishedProduct
	|			AND NOT DPP.Canceled
	|
	|GROUP BY
	|	DPP.Products,
	|	DPP.Characteristic,
	|	DPP.Package,
	|	DD.Department,
	|	DD.Purpose,
	|	DPP.BillOfMaterials";
	
	Query.SetParameter("ObjectsArray", FillingData);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		ProductionDispatcherBusinessUnit = Selection.ProductionDispatcherBusinessUnit;
		NewObject = CostObjects.Add();
		FillPropertyValues(NewObject, Selection);
		
	EndDo;

	MessageTemplate = NStr("vi = 'Từ chứng từ %1, đã chuyển chỉ sản phẩm, số lượng và giá trị bán thành phẩm, sẽ tính toán dựa trên bảng kê chi tiết nguồn lực của sản phẩm.';
							|ru = 'Из документа %1, перенесена только продукция, количество и стоимость полуфабрикатов, будет рассчитано на основании ресурсных спецификаций продукции.';
							|en = 'Only manufactured products are transferred from the ""%1"" document. The quantity and cost of semi-finished products will be calculated based on the product BOMs.'; fa = 'Only manufactured products are transferred from the ""%1"" document. The quantity and cost of semi-finished products will be calculated based on the product BOMs.';
							|it = 'Only manufactured products are transferred from the ""%1"" document. The quantity and cost of semi-finished products will be calculated based on the product BOMs.';
							|pl = 'Only manufactured products are transferred from the ""%1"" document. The quantity and cost of semi-finished products will be calculated based on the product BOMs.';
							|tr = '%1 belgesinden sadece imal edilen ürünler aktarılmıştır, yarı mamul ürünlerin miktarı ve maliyeti, imal edilen ürünlerin kaynak ürün reçeteleri temelinde hesaplanacaktır.'");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		MessageTemplate,
		FillingData[0]);
	Common.MessageToUser(MessageText, Ref);
	Basis = FillingData[0];
	
EndProcedure

Procedure CheckPossibilityOfEnteringBasedOn(Basis1)
	
	If TypeOf(Basis1[0]) = Type("CatalogRef.BillsOfMaterials") Then
		QueryText = 
			"SELECT TOP 1
			|	Attributes.Ref AS Ref,
			|	CASE
			|		WHEN Attributes.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
			|			THEN 0
			|		ELSE
			|			1
			|	END AS ErrorNumber
			|FROM
			|	Catalog.BillsOfMaterials AS Attributes
			|WHERE
			|	(Attributes.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
			|		OR Attributes.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind))
			|	AND Attributes.Ref IN(&Basis1)";
	ElsIf TypeOf(Basis1[0]) = Type("DocumentRef.ProductionOrder2_2") Then
		QueryText = 
			"SELECT TOP 1
			|	ProductionOrder2_2.Ref AS Ref,
			|	0 AS ErrorNumber
			|FROM
			|	Document.ProductionOrder2_2 AS ProductionOrder2_2
			|WHERE
			|	ProductionOrder2_2.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
			|	AND ProductionOrder2_2.Ref IN(&Basis1)";
	Else
		QueryText = 
			"SELECT TOP 1
			|	ProductionOrder2_2.Ref AS Ref,
			|	0 AS ErrorNumber
			|FROM
			|	Document.ProductionStage2_2 AS ProductionStage2_2
			|		INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder2_2
			|		ON ProductionStage2_2.ReferenceOrder = ProductionOrder2_2.Ref
			|WHERE
			|	ProductionOrder2_2.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
			|	AND ProductionStage2_2.Ref IN(&Basis1)";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Basis1", Basis1);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Not Selection.Next() Then
		Return;
	EndIf;
	
	If Selection.ErrorNumber = 0 Then
		ExceptionText = NStr("vi = 'Tính giá thành tháo gỡ, xử lý không được hỗ trợ.';
							|ru = 'Калькуляция разборки, утилизации не поддерживается.';
							|en = 'Disassembly and disposal costing is not supported.'; fa = 'Disassembly and disposal costing is not supported.';
							|it = 'Il calcolo di smontaggio, recupero non è supportato.';
							|pl = 'Kalkulacja kosztów demontażu, recyklingu nie jest obsługiwana.';
							|tr = 'Demontaj, geri dönüşüm maliyetlendirmesi desteklenmemektedir.'");
	Else
		ExceptionText = NStr("vi = 'Trên cơ sở bảng kê chi tiết các nguồn lực sản xuất cho dạng mặt hàng, nhập tính giá thành không có sẵn.';
							|ru = 'На основании спецификации для вида номенклатуры ввод калькуляции недоступен.';
							|en = 'Costing entry based on bill of materials is not available for the item kind.'; fa = 'Costing entry based on bill of materials is not available for the item kind.';
							|it = 'In base alla specifica per il tipo di articolo inserimento del calcolo non è disponibile';
							|pl = 'Na podstawie specyfikacji dla rodzaju nomenklatury wprowadzenie kalkulacji jest niedostępne.';
							|tr = 'Öğe türünün ürün reçetesi temelinde maliyetlendirme girişi mevcut değildir.'");
	EndIf;
	
	Raise ExceptionText;
	
EndProcedure

#EndRegion

#EndIf
