
#Region Variables

&AtClient
Var Stages;

&AtClient
Var Products_1;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("CommandParameter")
		And TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionOrder2_2") Then
		ProductionOrder = Parameters.CommandParameter;
	Else
		ProductionOrder = Parameters.ProductionOrder;
	EndIf;
	
	GanttChart.AutoDetectWholeInterval = True;
	GanttChart.ScaleKeeping = GanttChartScaleKeeping.Auto;
	GanttChart.ShowLegend = False;
	GanttChart.VerticalScroll = True;
	GanttChart.ShowEmptyValues = False;
	GanttChart.ShowTitle = False;
	GanttChart.ValueTextRepresentation = GanttChartValueTextRepresentation.Right;
	
	WorkingDate = Common.CurrentUserDate();
	
	OnlyProducts = True;
	
	OutputParameters = New Structure();
	OutputParameters.Insert("StagesShow", True);
	OutputParameters.Insert("ShowMovements", True);
	OutputParameters.Insert("ShowContent", True);
	OutputParameters.Insert("ExpandFirstLevelAfterLoading", False);
	OutputParameters.Insert("WorkingDate", WorkingDate);
	
	If Common.ObjectAttributeValue(ProductionOrder, "ProductionProcessType") = Enums.ProductionProcessTypes.Disassembly Then
		Items.GroupUnavailabilityWarning.Visible = True;
		Return;
	EndIf;
	
	SetUpGanttChart();
	
	InitializeCurRowDataCache();
	
	// 60003872
	RedefineKeyFieldsOfDynamicListList();
	
	List.Parameters.SetParameterValue("ProductionOrder", ProductionOrder);
	
	SetSelectionByRowType();
	
	AdjustVisibilityAccessibilityOfItems();
	
	CalculateTotalsAndCacheProductionSchedule();
	
	UpdateFormByOrder();
	
EndProcedure

&AtServer
Procedure InitializeCurRowDataCache()
	
	EmptyLinkKey = New UUID("00000000-0000-0000-0000-000000000000");
	CurCurrentDataCacheLine = New Structure("KeyLot,KeyProducts", EmptyLinkKey, EmptyLinkKey);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TimeOffset = StandardSubsystemsClient.ClientRunParameters().StandardTimeOffset;
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ProductionOrderOnChange(Item)
	
	ProductionOrderWhenModifiedOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductionOrderWhenModifiedOnServer()
	
	Points.Clear();
	GanttChart.Clear();
	
	If Common.ObjectAttributeValue(ProductionOrder, "ProductionProcessType") = Enums.ProductionProcessTypes.Disassembly Then
		Items.GroupUnavailabilityWarning.Visible = True;
		List.Parameters.SetParameterValue("ProductionOrder", Undefined);
		Return;
	Else
		Items.GroupUnavailabilityWarning.Visible = False;
	EndIf;
	
	InitializeCurRowDataCache();
	
	List.Parameters.SetParameterValue("ProductionOrder", ProductionOrder);
	
	CalculateTotalsAndCacheProductionSchedule(); // displays the first level of the diagram based on the result
	
	UpdateFormByOrder();
	
EndProcedure

&AtClient
Procedure OnlyProductsOnChange(Item)
	
	SetSelectionByRowType();
	
EndProcedure

&AtClient
Procedure StagesShowOnChange(Item)
	
	OutputParameters.StagesShow = StagesShow;
	
	LoadFirstLevel();
	
EndProcedure

&AtClient
Procedure ShowMovementsOnChange(Item)
	
	OutputParameters.ShowMovements = ShowMovements;
	
	LoadFirstLevel();
	
EndProcedure

&AtClient
Procedure ShowContentOnChange(Item)
	
	OutputParameters.ShowContent = ShowContent;
	
	LoadFirstLevel();
	
EndProcedure

&AtClient
Procedure GanttChartOnChange(Item)
	
	If Not ValueIsFilled(Points) Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
		"Report.MonitorProductionOrder.ReportForm.FinishTree");
	
	ChartSeries = ChartSeries();
	
	For PointIndex = -Points.Count() + 1 To 0 Do
		
		Point = Points[-PointIndex];
		
		ChartPoint = GanttChart.SetPoint(Point.Value);
		
		IsExpanded = GanttChart.PointExpanded(ChartPoint);
		
		If Not Point.Imported1 And IsExpanded Then
			UploadPoint(Point, ChartPoint)
		EndIf;
		
		If Point.IsExpanded <> IsExpanded Then
			ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, IsExpanded, ChartSeries);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure GanttChartDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	
	StandardProcessing = False;
	
	ListOfActions = New ValueList();
	
	If TypeOf(Decryptions) = Type("Array") Then
		ListOfTranscripts = Decryptions;
	Else
		ListOfTranscripts = New Array();
		ListOfTranscripts.Add(Decryptions);
	EndIf;
	
	For Each Details In ListOfTranscripts Do
		
		If Not TypeOf(Details) = Type("Structure")Then
			Continue;
		EndIf;
		
		RowType = Details.Type;
		
		If RowType = "Stage" Then
			AddAction(ListOfActions, "ShowValue", Details.Value.Stage);
		EndIf;
		
		If RowType = "Product" Then
			AddAction(ListOfActions, "ShowValue", Details.Value.Products);
		EndIf;
		
		State = Details.State;
		
		If RowType = "Stage" And Not State = 3 Then
		
			FilterStructure1 = New Structure();
			
			FilterStructure1.Insert("ProductionOrder", ProductionOrder);
			FilterStructure1.Insert("Stage", Details.Value.Stage);
			FilterStructure1.Insert("KeyLot", Details.Value.KeyLot);
			
			AddAction(ListOfActions, "ShowSoftware", FilterStructure1);
			
		EndIf;
		
		If (RowType = "Product" And State = 2)
			And ValueIsFilled(Details.Value.ReceiptOrder) Then
			
			AddAction(ListOfActions, "ShowValue", Details.Value.ReceiptOrder);
			
		EndIf;
		
		If (RowType = "Product" And State = 2)
			And TypeOf(Details.Value.ReceiptOrder) = Type("DocumentRef.ProductionOrder2_2") Then
			
			AddAction(ListOfActions, "GoToMonitoring", Details.Value.ReceiptOrder);
			
		EndIf;
		
		Break;
		
	EndDo;
	
	If ListOfActions.Count() > 0 Then
		DescriptionOfSelectionNotificationFromList = New CallbackDescription("SelectionFromListOfActionsEnd", ThisObject);
		ShowChooseFromList(DescriptionOfSelectionNotificationFromList, ListOfActions);
	EndIf;

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	OutputParameters.StagesShow = StagesShow;
	OutputParameters.ShowMovements = ShowMovements;
	OutputParameters.ShowContent = ShowContent;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	CurrentData = Items.List.CurrentData;
	
	If Not CurrentData = Undefined Then
		FillPropertyValues(CurCurrentDataCacheLine, Items.List.CurrentData);
	Else
		Return;
	EndIf;
	
	AttachIdleHandler("LoadFirstLevel", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	Points.Clear();
	GanttChart.Clear();
	
	List.Parameters.SetParameterValue("ProductionOrder", ProductionOrder);
	
	CalculateTotalsAndCacheProductionSchedule(True); // displays the first level of the diagram based on the result
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	Done = UploadEverythingToServer(500);
	
	If Not Done Then
		ShowQuestionExpandAllContinueOutput();
	EndIf;
	
	ExpandAllPoints();
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	CollapseAllPoints();
	
EndProcedure

#EndRegion

#Region Private

#Region Cache

&AtServer
Procedure CalculateTotalsAndCacheProductionSchedule(CompleteCalculation = False)
	
	ScheduleIsLoaded = False;
	
	CancelLongRunningOperation();
	
	Result = MonitorProductionOrder.StartCalculatingResultsOfProductionOrder(ProductionOrder, CompleteCalculation);
	
	JobID = Result.JobID;
	
	If Result.UpdateDate > '00010101'
		Or ValueIsFilled(JobID) And Result.RunResult.Status = "Completed2" Then
		
		LoadFirstLevelAfterCalculationOnServer();
		
		StartAwaitingLongAction = False;
		BackgroundJobResult = Undefined;
		
	Else
		
		StartAwaitingLongAction = True;
		BackgroundJobResult = Result.RunResult;
		
	EndIf;
	
	Items.RelevanceOfText.Title = StrTemplate(NStr("vi = 'vào ngày: %1';
													|ru = 'на дату: %1';
													|en = 'as of date: %1'; fa = 'as of date: %1';
													|it = 'на дату: %1';
													|pl = 'Na dzień: %1';
													|tr = 'tarihinde: %1'"), Result.UpdateDate + TimeOffset);
	Items.RelevanceOfText.Visible = Result.UpdateDate > '00010101';
	
EndProcedure

#EndRegion

#Region DynamicOutput

&AtServerNoContext
Procedure DownloadNextLevel(Filter, Stages, Products_1, WorkingDate, DesiredDate, OutputParameters)
	
	StagesShow = OutputParameters.StagesShow;
	ShowMovements = OutputParameters.ShowMovements;
	ShowContent = OutputParameters.ShowContent;
	
	Query = New Query;
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("ShowMovements", ShowMovements);
	Query.SetParameter("StagesShow", StagesShow);
	Query.SetParameter("ShowContent", ShowContent);
	Query.SetParameter("DesiredDate", DesiredDate);
	Query.SetParameter("WorkingDate", WorkingDate);
	Query.SetParameter("MainCalendar", Constants.MainEnterpriseCalendar.Get());
	Query.Text = 
	"SELECT
	|	
	|	Products_1.Products        AS Products,
	|	Products_1.Characteristic      AS Characteristic,
	|	Products_1.Warehouse               AS Warehouse,
	|	Products_1.Purpose          AS Purpose,
	|	Products_1.ProductionOrder AS ProductionOrder,
	|	Products_1.KeyProducts    AS KeyProducts,
	|	Products_1.KeyLot          AS KeyLot,
	|
	|	MIN(Products_1.Stage) AS Stage,
	|	MIN(Products_1.Stage) AS ProductionStage,
	|
	|	SUM(Products_1.ToSupply) + SUM(Products_1.Ordered) - SUM(Products_1.Replaced) AS Required2,
	|	SUM(Products_1.Done)    AS Done
	|
	|INTO ProductsIntermediateTable
	|FROM
	|	InformationRegister.OrderStructure AS Products_1
	|
	|WHERE
	|	&Filter
	|	AND Products_1.LineKind IN (
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
	|
	|GROUP BY
	|	Products_1.Products,
	|	Products_1.Characteristic,
	|	Products_1.Warehouse,
	|	Products_1.Purpose,
	|	Products_1.ProductionOrder,
	|	Products_1.KeyProducts,
	|	Products_1.KeyLot
	|
	|HAVING
	|	SUM(Products_1.ToSupply - Products_1.Replaced) > 0 OR SUM(Products_1.Ordered) > 0 OR SUM(Products_1.Done) > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder,
	|	KeyProducts,
	|	KeyLot
	|;";
	
	If Not ShowMovements Then
		
		Query.Text = StrReplace(Query.Text, "INTO ProductsIntermediateTable", "INTO ProductsTemporaryTable");
		Query.Text = Query.Text +
		"SELECT DISTINCT
		|	
		|	Products_1.Products        AS Products,
		|	Products_1.Characteristic      AS Characteristic,
		|	DD.Warehouse                    AS Warehouse,
		|	Products_1.Purpose          AS Purpose,
		|	Products_1.ProductionOrder AS ProductionOrder,
		|	Products_1.KeyProducts    AS KeyProducts
		|
		|INTO ProductsAndWarehousesForCalculatingChainOfMovements
		|FROM
		|	ProductsTemporaryTable AS Products_1
		|
		|	INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS DD
		|	ON Products_1.ProductionOrder = DD.ProductionOrder
		|	 AND Products_1.Products        = DD.Products
		|	 AND Products_1.Characteristic      = DD.Characteristic
		|	 AND Products_1.Purpose          = DD.Purpose
		|
		|	INNER JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
		|	ON Products_1.Products        = NSICache.Products
		|	 AND Products_1.Characteristic      = NSICache.Characteristic
		|	 AND Products_1.Warehouse               = NSICache.Warehouse
		|	 AND Products_1.Purpose          = NSICache.Purpose
		|	 AND Products_1.ProductionOrder = NSICache.ProductionOrder
		|	 AND NSICache.ToPlan
		|	 AND NSICache.SupplyType = VALUE(Enum.SupplyTypes.Move)
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
		|SELECT
		|	
		|	Products_1.Products        AS Products,
		|	Products_1.Characteristic      AS Characteristic,
		|	Products_1.Warehouse               AS Warehouse,
		|	Products_1.Purpose          AS Purpose,
		|	Products_1.ProductionOrder AS ProductionOrder,
		|	Products_1.KeyProducts    AS KeyProducts,
		|	Products_1.KeyLot          AS KeyLot,
		|	Products_1.ConnectionKeyTransfer AS ConnectionKeyTransfer,
		|
		|	MIN(Products_1.Stage) AS Stage,
		|
		|	SUM(Products_1.ToSupply - Products_1.Replaced) AS Required2,
		|	SUM(Products_1.Done)    AS Done
		|	
		|INTO ChainsOfTansfers
		|FROM
		|	InformationRegister.OrderStructure AS Products_1
		|
		|WHERE
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			ProductsAndWarehousesForCalculatingChainOfMovements AS DD
		|		WHERE
		|			DD.Products = Products_1.Products
		|			AND DD.Characteristic = Products_1.Characteristic
		|			AND DD.Warehouse = Products_1.Warehouse
		|			AND DD.Purpose = Products_1.Purpose
		|			AND DD.ProductionOrder = Products_1.ProductionOrder
		|			AND DD.KeyProducts = Products_1.ConnectionKeyTransfer)
		|
		|	AND Products_1.LineKind IN (
		|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))
		|
		|GROUP BY
		|
		|	Products_1.Products,
		|	Products_1.Characteristic,
		|	Products_1.Warehouse,
		|	Products_1.Purpose,
		|	Products_1.ProductionOrder,
		|	Products_1.ConnectionKeyTransfer,
		|	Products_1.KeyProducts,
		|	Products_1.KeyLot
		|
		|HAVING
		|	SUM(Products_1.ToSupply - Products_1.Replaced) > 0 OR SUM(Products_1.Done) > 0
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
		|SELECT
		|
		|	Products_1.Products        AS Products,
		|	Products_1.Characteristic      AS Characteristic,
		|	Products_1.Warehouse               AS Warehouse,
		|	Products_1.Purpose          AS Purpose,
		|	Products_1.ProductionOrder AS ProductionOrder,
		|	Products_1.KeyProducts    AS KeyProducts,
		|	Products_1.KeyLot          AS KeyLot,
		|	Products_1.Stage                AS Stage,
		|	Products_1.ProductionStage    AS ProductionStage,
		|	Products_1.Required2           AS Required2,
		|	Products_1.Done              AS Done
		|
		|INTO ProductsIntermediateTable
		|FROM
		|	ProductsTemporaryTable AS Products_1
		|
		|UNION ALL
		|
		|SELECT
		|
		|	Products_1.Products           AS Products,
		|	Products_1.Characteristic         AS Characteristic,
		|	Transfers.Warehouse              AS Warehouse,
		|	Products_1.Purpose             AS Purpose,
		|	Products_1.ProductionOrder    AS ProductionOrder,
		|	Transfers.KeyProducts   AS KeyProducts,
		|	Transfers.KeyLot         AS KeyLot,
		|	Transfers.Stage               AS Stage,
		|	Products_1.ProductionStage       AS ProductionStage,
		|	Transfers.Required2          AS Required2,
		|	Transfers.Done             AS Done
		|
		|FROM
		|	ProductsTemporaryTable AS Products_1
		|
		|	INNER JOIN ChainsOfTansfers AS Transfers
		|	ON Products_1.KeyProducts = Transfers.ConnectionKeyTransfer
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder,
		|	KeyProducts,
		|	KeyLot
		|;
		|DROP ProductsAndWarehousesForCalculatingChainOfMovements; DROP ChainsOfTansfers;
		|";
		
	EndIf;

	Query.Text = Query.Text +
	"SELECT
	|
	|	Products_1.Products        AS Products,
	|	Products_1.Characteristic      AS Characteristic,
	|	Products_1.Warehouse               AS Warehouse,
	|	Products_1.Purpose          AS Purpose,
	|	Products_1.ProductionOrder AS ProductionOrder,
	|	Products_1.KeyProducts    AS KeyProducts,
	|	Products_1.KeyLot          AS KeyLot,
	|	Products_1.ProductionStage    AS Stage,
	|
	|	ISNULL(Schedule.Begin, &DesiredDate) AS DesiredDate,
	|	BEGINOFPERIOD(ISNULL(Schedule.Begin, &DesiredDate), DAY) AS StartingDate,
	|
	|	CASE
	|		WHEN TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|			WHERE
	|				NSICache.ProductionOrder = Products_1.ProductionOrder
	|				AND NSICache.Products = Products_1.Products
	|				AND NSICache.Characteristic = Products_1.Characteristic
	|				AND NSICache.ToPlan
	|				AND NSICache.SupplyType = VALUE(Enum.SupplyTypes.Production))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsASemiFinishedProduct,
	|	Products_1.Products.ItemsType AS ItemsType,
	|
	|	ISNULL(NSICache.SupplyMethod.OrderFulfillmentPeriod, 1) AS OrderFulfillmentPeriod,
	|	ISNULL(NSICache.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)) AS BillOfMaterials,
	|
	|	Products_1.Required2 AS Required2,
	|	Products_1.Done    AS Done
	|	
	|INTO Products_1
	|FROM
	|	ProductsIntermediateTable AS Products_1
	| 
	|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
	|	ON Products_1.ProductionOrder = Schedule.ProductionOrder
	|	 AND Products_1.KeyLot          = Schedule.KeyLot
	|	 AND Products_1.Stage                = Schedule.Stage
	|
	|	LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|	ON Products_1.Products        = NSICache.Products
	|	 AND Products_1.Characteristic      = NSICache.Characteristic
	|	 AND Products_1.Warehouse               = NSICache.Warehouse
	|	 AND Products_1.Purpose          = NSICache.Purpose
	|	 AND Products_1.ProductionOrder = NSICache.ProductionOrder
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder,
	|	KeyProducts,
	|	KeyLot,
	|	Stage
	|;
	|
	|SELECT
	|	
	|	Plan.Products           AS Products,
	|	Plan.Characteristic         AS Characteristic,
	|	Plan.Warehouse                  AS Warehouse,
	|	Plan.Purpose             AS Purpose,
	|	Plan.ProductionOrder    AS ProductionOrder,
	|	Plan.KeyProducts       AS KeyProducts,
	|	Plan.KeyLot             AS KeyLot,
	|	Plan.LineKind              AS LineKind,
	|	MIN(CASE WHEN Plan.ReceiptOrder REFS Document.ProductionStage2_2
	|			THEN CAST(Plan.ReceiptOrder AS Document.ProductionStage2_2).ReferenceOrder
	|			ELSE Plan.ReceiptOrder
	|		END)                    AS ReceiptOrder,
	|	MIN(Plan.DateOfReceipt) AS DateOfReceipt,
	|
	|	SUM(Plan.Scheduled
	|			+ Plan.AllocatedFromAvailableInventory
	|			+ Plan.AllocatedFromAvailableInventoryWithAssignment
	|			+ Plan.AllocatedInFreeProductionLots
	|			+ Plan.AllocatedInAssignedProductionLots) AS Count
	|
	|INTO Plan
	|FROM
	|
	|	Products_1 AS Products_1
	|	
	|	INNER JOIN InformationRegister.OrderStructure AS Plan
	|	ON Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.Warehouse               = Plan.Warehouse
	|	 AND Products_1.Purpose          = Plan.Purpose
	|	 AND Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.KeyProducts    = Plan.KeyProducts
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.KeyLot,
	|	Plan.LineKind,
	|	Plan.ReceiptOrder,
	|	Plan.DateOfReceipt
	|
	|HAVING
	|	SUM(Plan.Scheduled) > 0
	|		OR SUM(Plan.AllocatedFromAvailableInventory + Plan.AllocatedFromAvailableInventoryWithAssignment) > 0
	|		OR SUM(Plan.AllocatedInFreeProductionLots  + Plan.AllocatedInAssignedProductionLots)  > 0
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
	|SELECT
	|	Plan.Products        AS Products,
	|	Plan.Characteristic      AS Characteristic,
	|	Plan.Warehouse               AS Warehouse,
	|	Plan.Purpose          AS Purpose,
	|	Plan.ProductionOrder AS ProductionOrder,
	|	Plan.KeyProducts    AS KeyProducts,
	|	SUM(Plan.Count)   AS Count
	|INTO MaterialsSupply
	|FROM
	|	Plan AS Plan
	|WHERE
	|	&ShowContent
	|	AND Plan.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Move))
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts
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
	|SELECT DISTINCT
	|	&MainCalendar           AS Calendar,
	|	Products_1.OrderFulfillmentPeriod AS NumberOfDays,
	|	Products_1.StartingDate          AS StartingDate
	|INTO TTSearchParameters
	|FROM
	|	Products_1 AS Products_1
	|	
	|	LEFT JOIN Plan AS Plan
	|	ON Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.Warehouse               = Plan.Warehouse
	|	 AND Products_1.Purpose          = Plan.Purpose
	|	 AND Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.KeyProducts    = Plan.KeyProducts
	|
	|WHERE
	|	(Plan.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved)
	|		AND Plan.ReceiptOrder <> UNDEFINED)
	|	OR (&ShowContent AND NOT Products_1.ThisIsASemiFinishedProduct)
	|
	|;
	|"
	+ ProductionServer.QueryTextForDatesByCalendar(False) + "
	|
	|SELECT
	|	Schedule.Stage AS Stage,
	|	Schedule.KeyLot AS KeyLot,
	|	Schedule.Begin AS Begin,
	|	Schedule.Ending AS Ending,
	|	Schedule.LeftLimit AS LeftLimit,
	|	CASE 
	|		WHEN Schedule.Stage REFS Catalog.ProductionStages THEN
	|			CAST(Schedule.Stage AS Catalog.ProductionStages).StageNumber
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2 THEN
	|			CAST(Schedule.Stage AS Document.ProductionStage2_2).StageNumber
	|		ELSE
	|			0
	|	END AS StageNumber,
	|	CASE 
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS StageCreated,
	|	CASE
	|		WHEN Schedule.ItIsTransfer THEN
	|			VALUE(Enum.SupplyTypes.Move)
	|		WHEN Schedule.Stage REFS Catalog.ProductionStages THEN
	|			CAST(Schedule.Stage AS Catalog.ProductionStages).Description
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2 THEN
	|			CAST(Schedule.Stage AS Document.ProductionStage2_2).StageName
	|				 + "" ("" + CAST(Schedule.Stage AS Document.ProductionStage2_2).Number + "")""
	|		ELSE
	|			""-""
	|	END AS StagePresentation,
	|	CASE
	|		WHEN Schedule.Stage REFS Catalog.ProductionStages
	|			AND Schedule.Stage <> VALUE(Catalog.ProductionStages.EmptyRef) THEN
	|			CAST(Schedule.Stage AS Catalog.ProductionStages).WorkPlanning
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2
	|			AND Schedule.Stage <> VALUE(Document.ProductionStage2_2.EmptyRef) THEN
	|			CAST(Schedule.Stage AS Document.ProductionStage2_2).WorkPlanning
	|		ELSE
	|			FALSE
	|	END AS WorkPlanning,
	|	CASE
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2
	|		  AND CAST(Schedule.Stage AS
	|			Document.ProductionStage2_2).Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|			THEN 3
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2
	|		  AND CAST(Schedule.Stage AS
	|			Document.ProductionStage2_2).Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|			THEN 2
	|		ELSE 1
	|	END AS State
	|FROM
	|	InformationRegister.OrderMonitoringFullTargetScheduleInterval AS Schedule
	|
	|WHERE
	|	Schedule.KeyLot = &KeyLot
	|	AND (Schedule.ItIsTransfer AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|		 OR NOT Schedule.ItIsTransfer AND Schedule.Stage <> VALUE(Catalog.ProductionStages.EmptyRef))
	|	AND &StagesShow
	|
	|ORDER BY
	|	StageNumber DESC
	|
	|;
	|
	|// Production and relocation
	|SELECT
	|
	|	&LinePresentation,
	|
	|	Products_1.Stage                 AS Stage,
	|
	|	Products_1.Products         AS Products,
	|	Products_1.Characteristic       AS Characteristic,
	|	Products_1.Warehouse                AS Warehouse,
	|	Products_1.Purpose           AS Purpose,
	|	Products_1.ProductionOrder  AS ProductionOrder,
	|	Products_1.KeyProducts     AS KeyProducts,
	|
	|	Plan.KeyLot              AS KeyLot,
	|
	|	CASE
	|		WHEN Schedule.LeftLimit IS NOT NULL
	|		THEN
	|			Schedule.LeftLimit
	|		ELSE
	|			DATEADD(Products_1.DesiredDate, DAY, -Products_1.OrderFulfillmentPeriod)
	|	END AS LeftLimit,
	|	CASE
	|		WHEN Schedule.Begin IS NOT NULL
	|		THEN
	|			Schedule.Begin
	|		ELSE
	|			DATEADD(Products_1.DesiredDate, DAY, -Products_1.OrderFulfillmentPeriod)
	|	END AS Begin,
	|	CASE
	|		WHEN Schedule.Ending IS NOT NULL
	|		THEN
	|			Schedule.Ending
	|		ELSE
	|			Products_1.DesiredDate
	|	END AS Ending,
	|
	|	NULL                    AS ReceiptOrder,
	|	1                       AS State,
	|	TRUE                  AS OutputStage,
	|	Products_1.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	Products_1.ItemsType AS ItemsType,
	|	Plan.Count         AS Count,
	|
	|	ISNULL(Schedule.RequestedSupplyDateIsViolated, FALSE) AS RequestedSupplyDateIsViolated
	|FROM
	|	Products_1 AS Products_1
	|	
	|	INNER JOIN Plan AS Plan
	|	ON Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.Warehouse               = Plan.Warehouse
	|	 AND Products_1.Purpose          = Plan.Purpose
	|	 AND Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.KeyProducts    = Plan.KeyProducts
	|	
	|	LEFT JOIN InformationRegister.OrderMonitoringFullTargetScheduleInterval AS Schedule
	|	ON Schedule.KeyLot = Plan.KeyLot
	|	 AND Schedule.Stage       = VALUE(Catalog.ProductionStages.EmptyRef)
	|
	|WHERE
	|	Plan.LineKind IN (
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
	|	OR &ShowMovements
	|			AND Plan.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|			AND (Products_1.ThisIsASemiFinishedProduct OR &ShowContent)
	|
	|UNION ALL
	|
	|// Reserve from the balance and receipt schedule
	|SELECT
	|
	|	&LinePresentation,
	|
	|	Products_1.Stage                 AS Stage,
	|
	|	Products_1.Products         AS Products,
	|	Products_1.Characteristic       AS Characteristic,
	|	Products_1.Warehouse                AS Warehouse,
	|	Products_1.Purpose           AS Purpose,
	|	Products_1.ProductionOrder  AS ProductionOrder,
	|	Products_1.KeyProducts     AS KeyProducts,
	|
	|	NULL                         AS KeyLot,
	|
	|	CASE
	|		WHEN Plan.ReceiptOrder = UNDEFINED
	|			THEN DATEADD(Products_1.DesiredDate, DAY, -1)
	|		WHEN Plan.DateOfReceipt <> DATETIME(1,1,1)
	|			THEN Plan.DateOfReceipt
	|		WHEN Schedule.Begin IS NOT NULL
	|			THEN Schedule.Begin
	|		WHEN ScheduleDates.Date IS NOT NULL
	|			THEN ScheduleDates.Date
	|		ELSE DATEADD(Products_1.DesiredDate, DAY, -Products_1.OrderFulfillmentPeriod)
	|	END AS LeftLimit,
	|	CASE
	|		WHEN Plan.ReceiptOrder = UNDEFINED
	|			THEN DATEADD(Products_1.DesiredDate, DAY, -1)
	|		WHEN Plan.DateOfReceipt <> DATETIME(1,1,1)
	|			THEN Plan.DateOfReceipt
	|		WHEN Schedule.Begin IS NOT NULL
	|			THEN Schedule.Begin
	|		WHEN ScheduleDates.Date IS NOT NULL
	|			THEN ScheduleDates.Date
	|		ELSE DATEADD(Products_1.DesiredDate, DAY, -Products_1.OrderFulfillmentPeriod)
	|	END AS Begin,
	|	CASE
	|		WHEN Plan.ReceiptOrder = UNDEFINED
	|			OR Plan.DateOfReceipt <> DATETIME(1,1,1)
	|			THEN Products_1.DesiredDate
	|		ELSE ISNULL(Schedule.Ending, Products_1.DesiredDate)
	|	END AS Ending,
	|
	|	Plan.ReceiptOrder AS ReceiptOrder,
	|
	|	CASE
	|		WHEN Plan.ReceiptOrder <> UNDEFINED
	|		THEN 2
	|		ELSE 3
	|	END                   AS State,
	|
	|	FALSE                    AS OutputStage,
	|	Products_1.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	Products_1.ItemsType AS ItemsType,
	|	Plan.Count         AS Count,
	|
	|	CASE
	|		WHEN Plan.ReceiptOrder = UNDEFINED
	|			THEN FALSE
	|		WHEN Plan.DateOfReceipt <> DATETIME(1,1,1)
	|			THEN Plan.DateOfReceipt > Products_1.DesiredDate
	|		WHEN Schedule.Ending IS NOT NULL
	|			THEN Schedule.Ending > Products_1.DesiredDate
	|		ELSE FALSE
	|	END AS RequestedSupplyDateIsViolated
	|FROM
	|	Products_1 AS Products_1
	|	
	|	INNER JOIN Plan AS Plan
	|	ON Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.Warehouse               = Plan.Warehouse
	|	 AND Products_1.Purpose          = Plan.Purpose
	|	 AND Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.KeyProducts    = Plan.KeyProducts
	|
	|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
	|	ON Plan.ReceiptOrder = Schedule.ProductionOrder
	|	 AND Schedule.KeyLot       = &EmptyLinkKey
	|	 AND Schedule.Stage             = VALUE(Catalog.ProductionStages.EmptyRef)
	|
	|	LEFT JOIN TTScheduleDates AS ScheduleDates
	|	ON Products_1.OrderFulfillmentPeriod = ScheduleDates.NumberOfDays
	|	 AND Products_1.StartingDate = ScheduleDates.StartingDate
	|
	|WHERE
	|	Plan.LineKind IN (
	|			VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
	|	AND (&ShowMovements
	|		OR NOT (Plan.ReceiptOrder REFS Document.TransferOrder
	|				OR Plan.ReceiptOrder REFS Document.OrderOfMaterialsForProduction))
	|	AND (Products_1.ThisIsASemiFinishedProduct OR &ShowContent)
	|
	|
	|UNION ALL
	|
	|// Materials to provide
	|SELECT
	|
	|	&LinePresentation,
	|
	|	Products_1.Stage                 AS Stage,
	|
	|	Products_1.Products         AS Products,
	|	Products_1.Characteristic       AS Characteristic,
	|	Products_1.Warehouse                AS Warehouse,
	|	Products_1.Purpose           AS Purpose,
	|	Products_1.ProductionOrder  AS ProductionOrder,
	|	Products_1.KeyProducts     AS KeyProducts,
	|
	|	NULL                         AS KeyLot,
	|
	|	ISNULL(ScheduleDates.Date,
	|		DATEADD(Products_1.DesiredDate, DAY, -Products_1.OrderFulfillmentPeriod)) AS LeftLimit,
	|	ISNULL(ScheduleDates.Date,
	|		DATEADD(Products_1.DesiredDate, DAY, -Products_1.OrderFulfillmentPeriod)) AS Begin,
	|	Products_1.DesiredDate AS Ending,
	|
	|	NULL AS ReceiptOrder,
	|	1    AS State,
	|	FALSE AS OutputStage,
	|	FALSE AS ThisIsASemiFinishedProduct,
	|	Products_1.ItemsType AS ItemsType,
	|
	|	Products_1.Required2 - ISNULL(MaterialsSupply.Count, 0) AS Count,
	|
	|	FALSE AS RequestedSupplyDateIsViolated
	|FROM
	|	Products_1 AS Products_1
	|	
	|	LEFT JOIN MaterialsSupply AS MaterialsSupply
	|	ON Products_1.Products        = MaterialsSupply.Products
	|	 AND Products_1.Characteristic      = MaterialsSupply.Characteristic
	|	 AND Products_1.Warehouse               = MaterialsSupply.Warehouse
	|	 AND Products_1.Purpose          = MaterialsSupply.Purpose
	|	 AND Products_1.ProductionOrder = MaterialsSupply.ProductionOrder
	|	 AND Products_1.KeyProducts    = MaterialsSupply.KeyProducts
	|
	|	LEFT JOIN TTScheduleDates AS ScheduleDates
	|	ON Products_1.OrderFulfillmentPeriod = ScheduleDates.NumberOfDays
	|	 AND Products_1.StartingDate = ScheduleDates.StartingDate
	|
	|WHERE
	|	&ShowContent
	|	AND NOT Products_1.ThisIsASemiFinishedProduct
	|	AND Products_1.Required2 - ISNULL(MaterialsSupply.Count, 0) > 0
	|
	|
	|UNION ALL
	|
	|// Manufactured products or material reserved in stock
	|SELECT
	|
	|	&LinePresentation,
	|
	|	Products_1.Stage                 AS Stage,
	|
	|	Products_1.Products         AS Products,
	|	Products_1.Characteristic       AS Characteristic,
	|	Products_1.Warehouse                AS Warehouse,
	|	Products_1.Purpose           AS Purpose,
	|	Products_1.ProductionOrder  AS ProductionOrder,
	|	Products_1.KeyProducts     AS KeyProducts,
	|
	|	NULL                         AS KeyLot,
	|
	|	DATEADD(Products_1.DesiredDate, DAY, -1) AS LeftLimit,
	|	DATEADD(Products_1.DesiredDate, DAY, -1) AS Begin,
	|	Products_1.DesiredDate                          AS Ending,
	|
	|	UNDEFINED            AS ReceiptOrder,
	|
	|	3                       AS State,
	|
	|	FALSE                    AS OutputStage,
	|	Products_1.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	Products_1.ItemsType AS ItemsType,
	|	Products_1.Done          AS Count,
	|
	|	FALSE AS RequestedSupplyDateIsViolated
	|FROM
	|	Products_1 AS Products_1
	|WHERE
	|	Products_1.Done > 0
	|		AND (Products_1.ThisIsASemiFinishedProduct OR &ShowContent)
	|
	|ORDER BY
	|	ThisIsASemiFinishedProduct DESC, Products, Characteristic, Warehouse, State, Ending, Count DESC
	|	AUTOORDER
	|";
	
	If TypeOf(Filter) = Type("UUID") Then
		
		Query.Text = StrReplace(Query.Text, "&Filter", "Products_1.KeyLot = &KeyLot");
		Query.SetParameter("KeyLot", Filter);
		
	Else
		
		FilterText1 = "";
		
		For Each KeyValue In Filter Do
			
			FilterText1 = 
				FilterText1
				+ ?(IsBlankString(FilterText1), "", " And ")
				+ "Products_1."
				+ KeyValue.Key
				+ " IN(&"
				+ KeyValue.Key
				+ ")";
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
			
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "&Filter", ?(IsBlankString(FilterText1), "FALSE", FilterText1));
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&LinePresentation,", "
		|PRESENTATION(Products_1.Products)                  AS ProductsPresentation,
		|PRESENTATION(Products_1.Characteristic)                AS CharacteristicPresentation,
		|PRESENTATION(Products_1.Products.UnitOfMeasure) AS UnitOfMeasurePresentation,
		|");
		
	QueryResult = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	LoadQueryResultIntoArray(QueryResult[NumberOfPackages_-2], Stages);
	LoadQueryResultIntoArray(QueryResult[NumberOfPackages_-1], Products_1);
	
EndProcedure

&AtClient
Procedure UploadPoint(Point, ChartPoint)
	
	KeyLot = New UUID(Left(Point.Value, 36));
	DownloadNextLevel(KeyLot, Stages, Products_1, WorkingDate, RequestedCompletionDate, OutputParameters);
	PrintPoints(GanttChart, Stages, Products_1, ChartPoint, Points, OutputParameters);
	Point.Imported1 = True;
	
EndProcedure

&AtServer
Procedure UploadPointToServer(Point, ChartPoint, Stages, Products_1)
	
	KeyLot = New UUID(Left(Point.Value, 36));
	DownloadNextLevel(KeyLot, Stages, Products_1, WorkingDate, RequestedCompletionDate, OutputParameters);
	PrintPoints(GanttChart, Stages, Products_1, ChartPoint, Points, OutputParameters);
	Point.Imported1 = True;
	
EndProcedure

&AtServer
Function UploadEverythingToServer(Batch = -1)
	
	Stages = New Array();
	Products_1 = New Array();
	
	InitialNumberOfPoints = Points.Count();
	
	NotLoadedPoints = Points.FindRows(New Structure("Imported1", False));
	
	Boundary = NotLoadedPoints.UBound();
	
	While Boundary >= 0 Do

		Point = NotLoadedPoints[0];
		
		ChartPoint = GanttChart.SetPoint(Point.Value);
		
		UploadPointToServer(Point, ChartPoint, Stages, Products_1);
		
		NotLoadedPoints.Delete(0);
		
		Boundary = Boundary - 1;
		
		If Boundary = -1 Then
			NotLoadedPoints = Points.FindRows(New Structure("Imported1", False));
			Boundary = NotLoadedPoints.UBound();
		EndIf;
		
		If Batch > 0 And Points.Count() - InitialNumberOfPoints > Batch Then
			Break;
		EndIf;
		
	EndDo;
	
	Return Boundary = -1;
	
EndFunction

&AtClient
Procedure ExpandPoint(IndexOf)
	
	ChartSeries = ChartSeries();
	
	Point = Points[IndexOf];
	
	ChartPoint = GanttChart.SetPoint(Point.Value);
	
	GanttChart.ExpandPoint(ChartPoint, False);
	
	UploadPoint(Point, ChartPoint);
	
	ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, True, ChartSeries);
	
EndProcedure

&AtServer
Procedure ExpandPointOnServer(IndexOf)
	
	Stages = New Array();
	Products_1 = New Array();
	
	ChartSeries = ChartSeriesOnServer();
	
	Point = Points[IndexOf];
	
	ChartPoint = GanttChart.SetPoint(Point.Value);
	
	GanttChart.ExpandPoint(ChartPoint, False);
	
	UploadPointToServer(Point, ChartPoint, Stages, Products_1);
	
	ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, True, ChartSeries);
	
EndProcedure

&AtClient
Procedure LoadFirstLevel()
	
	Points.Clear();
	GanttChart.Clear();
	
	OutputParametersCopy = CommonClient.CopyRecursive(OutputParameters);
	OutputParametersCopy.StagesShow = False;
	
	If ScheduleIsLoaded Then
		DownloadNextLevel(CurCurrentDataCacheLine, Stages, Products_1, WorkingDate, RequestedCompletionDate, OutputParametersCopy);
		PrintPoints(GanttChart, Stages, Products_1, GanttChart, Points, OutputParameters);
	EndIf;
	
	If Points.Count() > 0 And OutputParameters.ExpandFirstLevelAfterLoading Then
		ExpandPoint(0);
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadFirstLevelAfterCalculationOnServer()
	
	KeyOperation = "Report.MonitorProductionOrder.ReportForm.Generation1";
	BeginTime = PerformanceMonitor.StartTimeMeasurement();
	
	ScheduleIsLoaded = True;
	
	Stages = New Array();
	Products_1 = New Array();
	
	SetUpGanttChart();
	
	OutputParametersCopy = Common.CopyRecursive(OutputParameters);
	OutputParametersCopy.StagesShow = False;
	
	DownloadNextLevel(CurCurrentDataCacheLine, Stages, Products_1, WorkingDate, RequestedCompletionDate, OutputParametersCopy);
	PrintPoints(GanttChart, Stages, Products_1, GanttChart, Points, OutputParameters);
	
	If Points.Count() > 0 And OutputParameters.ExpandFirstLevelAfterLoading Then
		ExpandPointOnServer(0);
	EndIf;
	
	PerformanceMonitor.EndTimeMeasurement(KeyOperation, BeginTime);
	
EndProcedure

&AtClientAtServerNoContext
Procedure PrintPoints(GanttChart, Stages, Products, Val PointParent, Points, OutputParameters)
	
	MatchingPointAndStage = New Map();
	StagePointForCommunication = Undefined;
	
	If PointParent.Points.Count() = 1 And (PointParent.Points[0].Value = 0 Or PointParent.Points[0].Value = 1) Then
		PointParent.Points.Delete(PointParent.Points[0]);
	EndIf;
	
	For Each String In Stages Do
		
		Point = PointParent.Points.Add();
		
		StructureOfValues = New Structure("Stage, KeyLot", String.Stage, String.KeyLot);
		DetailsValue = New Structure("Type,State,Value","Stage",String.State,StructureOfValues);
		
		Point.Value    = "" + String.KeyLot + "/" + New UUID();
		Point.Text       = String.StagePresentation;
		Point.Details = DetailsValue;
		Point.TextColor = ?(String.Ending < OutputParameters.WorkingDate
								Or String.LeftLimit < OutputParameters.WorkingDate And String.State <> 3 Or String.State > 3, WebColors.Red, New Color());
		Point.SecondColor = WebColors.LightGray;
		
		If String.WorkPlanning Then
			Point.Picture = ?(String.StageCreated,
				PictureLib.WorkPlanningStageCreated, PictureLib.ManufacturingProcessWorkPlanningStage);
		Else
			Point.Picture = ?(String.StageCreated,
				PictureLib.ManufacturingProcessProductionStageCreated, PictureLib.ManufacturingProcessProductionStage);
		EndIf;
		
		OutputIntervals(GanttChart, String, Point, StagePointForCommunication, OutputParameters);
		
		StagePointForCommunication = Point;
		
		MatchingPointAndStage.Insert(String.Stage, Point.Value);
		
		CachePoint(Points, Point, True);
		
	EndDo;
	
	For Each String In Products Do
		
		If ValueIsFilled(MatchingPointAndStage) Then
			PointParent = GanttChart.SetPoint(MatchingPointAndStage.Get(String.Stage))
		EndIf;
		
		Point = PointParent.Points.Add();
		
		ValueStructureKeys = "Products,Characteristic,Warehouse,Purpose,ReceiptOrder";
		DetailsValue = New Structure("Type,State,Value","Product",String.State, New Structure(ValueStructureKeys));
		FillPropertyValues(DetailsValue.Value, String);
		
		Presentation = StrTemplate("%1, %2 %3", ProductsClientServer.ProductPresentation(String.ProductsPresentation, String.CharacteristicPresentation), 
			Format(String.Count, "NZ=; NG="),
			String.UnitOfMeasurePresentation);
		
		Point.Value    = "" + String.KeyLot + "/" + New UUID();
		Point.Text       = Presentation;
		Point.Details = DetailsValue;
		If OutputParameters.StagesShow Or OutputParameters.ShowContent Then
			If String.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				Point.Picture = PictureLib.OrderStructureWork;
			ElsIf String.ThisIsASemiFinishedProduct Then
				Point.Picture = PictureLib.SemiFinishedProduct;
			Else
				Point.Picture = PictureLib.OrderStructureMaterial;
			EndIf; 
		EndIf;
		Point.TextColor = ?(String.Begin < OutputParameters.WorkingDate
								Or String.LeftLimit < OutputParameters.WorkingDate And String.State <> 3
								Or String.RequestedSupplyDateIsViolated
								Or String.State > 3, WebColors.Red, New Color());
		Point.SecondColor = WebColors.LightGray;
		
		OutputIntervals(GanttChart, String, Point, PointParent, OutputParameters);
		
		If String.OutputStage Then
			CachePoint(Points, Point);
			DummyPoint = Point.Points.Add();
			DummyPoint.Value = 0;
			Series = GanttChart.SetSeries("Occupation");
			GanttChart.GetValue(DummyPoint, Series).Add();
		EndIf;
		
	EndDo;

EndProcedure

&AtClientAtServerNoContext
Procedure OutputIntervals(GanttChart, String, Point, StagePointForCommunication, OutputParameters)
	
	Series = GanttChart.SetSeries("Occupation");
	
	GanttChartValues = GanttChart.GetValue(Point, Series);
	
	// Output of the interval according to the data of the current line
	GanttChartInterval = GanttChartValues.Add();

	IntervalColor = ?(String.State = 1, WebColors.Gray,                            // - the stage is planned
					?(String.State = 2, WebColors.SteelBlue,          // - the stage has begun
					?(String.State = 3, WebColors.MediumGreen, New Color))); // - the stage is completed
	
	If String.Begin <= String.Ending Then
		GanttChartInterval.Begin = String.Begin;
		GanttChartInterval.End = String.Ending;
	Else
		GanttChartInterval.Begin = String.Begin - 86400;
		GanttChartInterval.End = String.Begin;
	EndIf;
	GanttChartInterval.Details = Point.Details;
	GanttChartInterval.Color        = IntervalColor;
	
	// Adding links to stages
	If TypeOf(StagePointForCommunication) = Type("GanttChartPoint") Then
		
		For Each Interval In GanttChart.GetValue(StagePointForCommunication, Series) Do
			
			Item = GanttChartInterval.Add(Interval);
			
			If Item.Begin.End > Item.End.Begin Then
				Item.Color = WebColors.Red;
			Else
				Item.Color = WebColors.Blue;
			EndIf;
			
			Break;
		
		EndDo;
		
	EndIf;
	
	// Output of the interval based on the totals of the current row
	If String.Begin > String.LeftLimit Then
		GanttChartInterval = GanttChartValues.Add();
		GanttChartInterval.Begin      = String.LeftLimit;
		GanttChartInterval.End       = String.Begin - 1;
		GanttChartInterval.Color        = WebColors.Gainsboro;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayPeriodsOfUnavailability(GanttChart, PeriodsOfUnavailability)
	
	GanttChart.BackgroundIntervals.Clear();
	
	For Each UnavailabilityData In PeriodsOfUnavailability Do
		
		GanttChart.BackgroundIntervals.Add(UnavailabilityData.Begin, UnavailabilityData.Ending);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustTimeScale(GanttChart, BeginOfPeriod, EndOfPeriod)
	
	TimelineElements = GanttChart.PlotArea.TimeScale.Items;
	
	ThereWereElements = TimelineElements.Count();
	
	If (EndOfPeriod - BeginOfPeriod > 50 * 86400) Then
		TimelineElements.Add().Unit = TimeScaleUnitType.Month;
		TimelineElements.Add().Unit = TimeScaleUnitType.Day;
	Else
		TimelineElements.Add().Unit = TimeScaleUnitType.Week;
		TimelineElements.Add().Unit = TimeScaleUnitType.Day;
	EndIf;
	
	If ThereWereElements > 0 Then
		For Cnt = 0 To ThereWereElements - 1 Do
			TimelineElements.Delete(TimelineElements[0]);
		EndDo;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CachePoint(Points, Point, Imported1 = False)
	Cache = Points.Add();
	Cache.Value = Point.Value;
	Cache.Imported1 = Imported1;
EndProcedure

#EndRegion

#Region Details

&AtClient
Procedure AddAction(ListOfActions, ActionName, TheseActions)
	
	If ActionName = "ShowValue" Then
		ListOfActions.Add(New Structure("ActionName, TheseActions", ActionName, TheseActions), "" + TheseActions);
	EndIf;
	
	If ActionName = "ShowProblems" Then
		ListOfActions.Add(New Structure("ActionName, TheseActions", ActionName, TheseActions), NStr("vi = 'Hiển thị vấn đề...';
																									|ru = 'Показать проблемы...';
																									|en = 'Show issues...'; fa = 'Show issues...';
																									|it = 'Показать проблемы...';
																									|pl = 'Pokaż problemy...';
																									|tr = 'Problemleri göster...'"));
	EndIf;
	
	If ActionName = "ShowSoftware" Then
		ListOfActions.Add(New Structure("ActionName, TheseActions", ActionName, TheseActions), NStr("vi = 'Hiển thị đảm bảo...';
																									|ru = 'Показать обеспечение...';
																									|en = 'Show supply...'; fa = 'Show supply...';
																									|it = 'Показать обеспечение...';
																									|pl = 'Pokaż zaopatrzenie...';
																									|tr = 'Sipariş karşılama göster...'"));
	EndIf;
	
	If ActionName = "GoToMonitoring" Then
		ListOfActions.Add(New Structure("ActionName, TheseActions", ActionName, TheseActions), NStr("vi = 'Màn hình kiểm soát đơn hàng';
																									|ru = 'Мониторинг заказа';
																									|en = 'Monitor order'; fa = 'پایش سفارش';
																									|it = 'Мониторинг заказа';
																									|pl = 'Monitorowanie zamówienia';
																									|tr = 'Sipariş takibi'") + " " + BriefPresentation(TheseActions));
	EndIf;

EndProcedure

&AtClient
Procedure SelectionFromListOfActionsEnd(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement = Undefined Then
		Return;
	EndIf;
	
	Result = SelectedElement.Value;
	
	If Result.ActionName = "ShowValue" Then
		
		ShowValue(,Result.TheseActions);
		
	EndIf;
	
	If Result.ActionName = "ShowSoftware" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("VariantKey"			 , "ByOrder");
		FormParameters.Insert("Filter"					 , New Structure);
		If Not ValueIsFilled(Result.TheseActions.Stage) Then
			FormParameters.Insert("KeyLot"			 , Result.TheseActions.KeyLot);
		EndIf;
		
		FormParameters.Filter.Insert("ProductionOrder", Result.TheseActions.ProductionOrder);
		FormParameters.Filter.Insert("Stage",				 Result.TheseActions.Stage);
		
		OpenForm("Report.OrderCompleteness.Form", FormParameters, ThisObject);
		
	EndIf;
	
	If Result.ActionName = "GoToMonitoring" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("ProductionOrder", Result.TheseActions);
		
		OpenForm("Report.MonitorProductionOrder.Form", FormParameters, ThisObject);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function BriefPresentation(Val Ref)
	
	TypeOf = TypeOf(Ref);
	
	If TypeOf = Type("DocumentRef.ProductionOrder2_2") Then
		
		Presentation = Documents.ProductionOrder2_2.OrderPresentation(Ref, "");
		
	ElsIf TypeOf = Type("DocumentRef.ProductionStage2_2") Then
		
		Presentation = Documents.ProductionStage2_2.PresentationStage(Ref);
		
	Else
		
		Presentation = "" + Ref;
		
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion

#Region ExpandAll

&AtClient
Procedure ShowQuestionExpandAllContinueOutput()
	
	ShowQueryBox(
		 New CallbackDescription("QuestionExpandEverythingContinueOutputEnd", ThisForm),
		 StrTemplate(NStr("vi = 'Hiển thị %1 phần tử. Tiếp tục hiển thị?';
							|ru = 'Выведено %1 элементов. Продолжить вывод?';
							|en = '%1 items are displayed. Continue?'; fa = '%1 items are displayed. Continue?';
							|it = 'Выведено %1 элементов. Продолжить вывод?';
							|pl = 'Wyprowadzono %1 elementów. Kontynuować wyprowadzenie?';
							|tr = '""%1"" öğe çıkarıldı. Çıkarmaya devam edilsin mi?'"), 500),
		 QuestionDialogMode.YesNo,,
		 DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure QuestionExpandEverythingContinueOutputEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		UploadEverythingToServer();
	EndIf;
	
	ExpandAllPoints();
	
EndProcedure

&AtClient
Procedure ExpandAllPoints()
	
	LoadedPoints = Points.FindRows(New Structure("Imported1", True));
	
	ChartSeries = ChartSeries();
	
	For Each Point In LoadedPoints Do
		
		ChartPoint = GanttChart.SetPoint(Point.Value);
		
		GanttChart.ExpandPoint(ChartPoint, False);
		
		ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, True, ChartSeries);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseAllPoints()
	
	ChartSeries = ChartSeries();
	
	For Each Point In Points Do
		
		ChartPoint = GanttChart.SetPoint(Point.Value);
		
		GanttChart.CollapsePoint(ChartPoint, False);
		
		ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, False, ChartSeries);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, IsExpanded, Series)

	Intervals = GanttChart.GetValue(ChartPoint, Series);
	
	If Intervals.Count() > 1 Then
		
		Interval1 = Undefined; // GanttChartInterval
		Interval2 = Undefined; // GanttChartInterval
		
		For Each Interval In Intervals Do
			
			Interval1 = ?(Interval1 <> Undefined And Interval1.Begin < Interval.Begin, Interval1, Interval);
			Interval2 = ?(Interval2 <> Undefined And Interval2.Begin > Interval.Begin, Interval2, Interval);
			
		EndDo;
		
		Interval1.End = ?(IsExpanded, '00010101', Interval2.Begin - 1);
		
	EndIf;
	
	Point.IsExpanded = IsExpanded;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure AdjustVisibilityAccessibilityOfItems()
	
	Return; // no additional actions are provided in the current configuration
	
EndProcedure

&AtServer
Procedure SetUpGanttChart()
	
	// Period
	Period = MonitorProductionOrder.FullIntervalOfProductionSchedule(ProductionOrder);
	
	BeginOfPeriod = BegOfDay(?(Period.LeftLimit = '00010101', WorkingDate, Period.LeftLimit)) - 86400;
	EndOfPeriod = EndOfDay(?(Period.Ending = '00010101', WorkingDate, Period.Ending)) + 86400;
	
	// Time scale
	AdjustTimeScale(GanttChart, BeginOfPeriod, EndOfPeriod);
	
	If GanttChart.PlotArea.TimeScale.Items[0].Unit = TimeScaleUnitType.Month Then
		BeginOfPeriod = BegOfMonth(BeginOfPeriod);
		EndOfPeriod  = EndOfMonth(EndOfPeriod);
	Else
		BeginOfPeriod = BegOfWeek(BeginOfPeriod);
		EndOfPeriod  = EndOfWeek(EndOfPeriod);
	EndIf;
	
	// Output allocation
	Schedules= New Array();
	Schedules.Add(Constants.MainEnterpriseCalendar.Get());
	
	WorkSchedules1 = ProductionPlanning.ScheduleOfWorkOnSchedule(Schedules, BeginOfPeriod, EndOfPeriod);
	WorkSchedules1.GroupBy("ScheduleDate");
	WorkSchedules1.Indexes.Add("ScheduleDate");
	
	TablePeriodsOfUnavailability = New ValueTable();
	TablePeriodsOfUnavailability.Columns.Add("Begin",    New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	TablePeriodsOfUnavailability.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	
	CurrentPeriod = BeginOfPeriod;
	While CurrentPeriod <= EndOfPeriod Do
		
		If WorkSchedules1.Find(CurrentPeriod, "ScheduleDate") = Undefined Then
			NewPeriod = TablePeriodsOfUnavailability.Add();
			NewPeriod.Begin = CurrentPeriod;
			NewPeriod.Ending = EndOfDay(NewPeriod.Begin);
		EndIf;
		
		CurrentPeriod = CurrentPeriod + 86400;
	EndDo;
	
	DisplayPeriodsOfUnavailability(GanttChart, TablePeriodsOfUnavailability);
	
EndProcedure

// Load the query result into the array.
// 
// Parameters:
//  Result - QueryResult - Result
//  Array - Array - Array
&AtServerNoContext
Procedure LoadQueryResultIntoArray(Result, Array)
	
	Array.Clear();
	
	If Not
		Result.IsEmpty() Then
		
		Selection = Result.Select();
		
		StructureString = "";
		CommaRequired = False;
		For Each Column In Result.Columns Do
			If CommaRequired Then
				StructureString = StructureString + ",";
			EndIf;
			StructureString = StructureString + Column.Name;
			CommaRequired = True;
		EndDo;
		
		While Selection.Next() Do
			NewRow = New Structure(StructureString);
			FillPropertyValues(NewRow, Selection);
			Array.Add(NewRow);
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelLongRunningOperation()
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction()
	
	StartAwaitingLongAction = False;

	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("ProcessProductionScheduleNotification", ThisObject);

	TimeConsumingOperationsClient.WaitCompletion(
		BackgroundJobResult, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure ProcessProductionScheduleNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		LoadFirstLevelAfterCalculationOnServer();
	EndIf;
		
EndProcedure

&AtServer
Procedure SetSelectionByRowType()

	StringsList = New Array();
	
	If OnlyProducts Then
		StringsList.Add(Enums.KindsOfProductionOrderStructureLines.ManufacturedProduct);
		StringsList.Add(Enums.KindsOfProductionOrderStructureLines.ManufactureOfProducts);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "LineKind", StringsList, DataCompositionComparisonType.InList,, StringsList.Count() > 0);
	
EndProcedure

&AtServer
Procedure UpdateFormByOrder()
	
	OrderDetails = Common.ObjectAttributesValues(ProductionOrder, "Number,Date,Status");
	
#Region FormCaption
	
	AutoTitle = False;
	
	If ProductionOrder.IsEmpty() Then
		Title = NStr("vi = 'Màn hình đơn hàng sản xuất';
					|ru = 'Мониторинг заказа на производство';
					|en = 'Production order monitoring'; fa = 'Production order monitoring';
					|it = 'Мониторинг заказа на производство';
					|pl = 'Monitorowanie zlecenia produkcyjnego';
					|tr = 'Üretim emri takibi'");
	Else
		Title = StrTemplate(NStr("vi = 'Màn hình theo dõi đơn hàng %1';
								|ru = 'Мониторинг заказа %1';
								|en = '%1 order monitoring'; fa = '%1 order monitoring';
								|it = 'Мониторинг заказа %1';
								|pl = 'Monitorowanie zamówienia %1';
								|tr = '%1 sipariş takibi'"), Documents.ProductionOrder2_2.OrderPresentation(ProductionOrder, "", OrderDetails));
	EndIf;
	
#EndRegion

#Region TheClosedStatus

	Items.OrderInformationGroupIsClosed.Visible = OrderDetails.Status = Enums.ProductionOrderStatuses2_2.Closed;
	
#EndRegion

EndProcedure

&AtClient
Function ChartSeries()
	Series = GanttChart.SetSeries("Occupation");
	Return Series;
EndFunction

&AtServer
Function ChartSeriesOnServer()
	Series = GanttChart.SetSeries("Occupation");
	Return Series;
EndFunction

// 60003872
&AtServer
Procedure RedefineKeyFieldsOfDynamicListList()
	
	If GetFunctionalOption("UseItemVariants") Then
		Return;
	EndIf;
	
	KeyFields = New Array;
	
	FieldsCount = List.KeyFields.Count();
	IndexField      = 0;
	While IndexField < FieldsCount Do
		
		KeyField = List.KeyFields.Get(IndexField);
		If KeyField <> "Characteristic" Then
			KeyFields.Add(KeyField);
		EndIf;
		
		IndexField = IndexField + 1;
		
	EndDo;
	
	List.KeyFields = New FixedArray(KeyFields);
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

Stages = New Array();
Products_1 = New Array();

#EndRegion
