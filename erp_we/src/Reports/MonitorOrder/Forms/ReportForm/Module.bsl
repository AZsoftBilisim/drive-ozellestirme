
#Region Variables

&AtClient
Var Stages;

&AtClient
Var Lots;

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	GenerateOnOpen = False;
	
	If Parameters.Property("CommandParameter", ProductionOrder) Then
		
		GenerateOnOpen = True;
		
	ElsIf Parameters.Property("ProductionOrder", ProductionOrder) Then
		
		GenerateOnOpen = True;
		
		If Not ProductionOrder.IsEmpty() And Parameters.ToHideOrder Then
			Items.ProductionOrder.Visible = False; // Form navigation bar
		EndIf;
		
	EndIf;
	
	If Not Parameters.Property("ScheduleStatus", ScheduleStatus) Then
		ScheduleStatus = StatusWorkingSchedule();
	EndIf;
	
	GanttChart.AutoDetectWholeInterval = False;
	GanttChart.ScaleKeeping = GanttChartScaleKeeping.AllData;
	GanttChart.Outline = False;
	GanttChart.ShowLegend = False;
	GanttChart.VerticalScroll = True;
	GanttChart.ShowEmptyValues = False;
	GanttChart.ShowTitle = False;
	GanttChart.ValueTextRepresentation = GanttChartValueTextRepresentation.None;
	GanttChart.IntervalTextRepresentation = GanttChartIntervalTextRepresentation.DontShow;
	GanttChart.PlotArea.Right = 1;
	
	WorkingDate = Common.CurrentUserDate();
	
	OutputParameters = New Structure();
	OutputParameters.Insert("BackColors", BackColors());
	OutputParameters.Insert("ScheduleStatus", ScheduleStatus);
	OutputParameters.Insert("StagesShow", True);
	OutputParameters.Insert("ShowLinks", True);
	OutputParameters.Insert("ExpandFirstLevelAfterLoading", False);
	OutputParameters.Insert("WorkingDate", WorkingDate);
	OutputParameters.Insert("TheseAreRAndMRepairs", ValueIsFilled(ProductionOrder)
		And Common.ObjectAttributeValue(ProductionOrder, "ProductionProcessType") = Enums.ProductionProcessTypes.PerformRM);
	
	UploadFormSettings();
	
	Modes = Reports.MonitorOrder.ViewModes();
	FillInListOfDisplayModes();
	
	ReadOrderAttributes();
	
	SetFormHeader();
	
	AdjustVisibilityAccessibilityOfItems();
	
	If GenerateOnOpen Then
		
		GenerateReportOnServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TimeOffset = StandardSubsystemsClient.ClientRunParameters().StandardTimeOffset;
	
	If StartAwaitingLongAction Then
		StartAwaitingLongAction();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation();
	EndIf;
	
	SaveFormSettings();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductionOrderOnChange(Item)
	
	ProductionOrderWhenModifiedOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductionOrderWhenModifiedOnServer()
	
	ReadOrderAttributes();
	
	SetFormHeader();
	
	AdjustVisibilityAccessibilityOfItems();
	
	GanttChart.Clear(); // 60010106
	Points.Clear();
	
	GenerateReportOnServer();
	
EndProcedure

&AtClient
Procedure ViewModeOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm);

	GanttChart.Clear(); // 60010106
	Points.Clear();
	
	AttachIdleHandler("GenerateReport", 0.1, True);
	
EndProcedure

&AtClient
Procedure StagesShowOnChange(Item)
	
	OutputParameters.StagesShow = StagesShow;
	
	ConfigureDependentFormElements(ThisForm);
	
	GanttChart.Clear(); // 60010106
	Points.Clear();
	
	AttachIdleHandler("GenerateReport", 0.1, True);

EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	GanttChart.Clear(); // 60010106
	Points.Clear();
	
	AttachIdleHandler("GenerateReport", 0.1, True);

EndProcedure

&AtClient
Procedure GanttChartTableBeforeUnfolding(Item, String, Cancel)
	
	If Not ValueIsFilled(Points) Or String = Undefined Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
		"Report.MonitorOrder.ReportForm.ExpandPoint");
	
	ChartSeries = ChartSeries();
	
	ChartValue = GanttChart.FindValueByID(String);
	
	ChartPoint = ChartValue.Point;
	Point = Points.FindRows(New Structure("Value", ChartPoint.Value))[0];

	If Not Point.Imported1 Then
		UploadPoint(Point, ChartPoint)
	EndIf;
	
	GanttChart.ExpandPoint(ChartPoint, False);

	ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, True, ChartSeries);

EndProcedure

&AtClient
Procedure GanttChartTableBeforeFolding(Item, String, Cancel)
	
	If Not ValueIsFilled(Points) Or String = Undefined Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
		"Report.MonitorOrder.ReportForm.CollapsePoint");
	
	ChartSeries = ChartSeries();
	
	ChartValue = GanttChart.FindValueByID(String);
	
	ChartPoint = ChartValue.Point;
	Point = Points.FindRows(New Structure("Value", ChartPoint.Value))[0];
	
	GanttChart.CollapsePoint(ChartPoint, False);

	ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, False, ChartSeries);

EndProcedure

&AtClient
Procedure GanttChartDetailProcessing(Item, Decryptions, StandardProcessing, Date)
	
	StandardProcessing = False;
	
	If TypeOf(Decryptions) = Type("Array")
		And Decryptions.Count() > 1 Then
		
		DetailsValue = Decryptions[1];
		
		If TypeOf(DetailsValue) = Type("Structure") And DetailsValue.Type = "Lot" Then
			
			FormParameters = New Structure();
			
			If DetailsValue.Property("ProductionLot") Then
				FormParameters.Insert("CommandParameter", DetailsValue.ProductionLot);
			Else
				FormParameters.Insert("KeyLot", DetailsValue.KeyLot);
			EndIf;
			
			FormParameters.Insert("ScheduleStatus", ScheduleStatus);
			FormParameters.Insert("ProductionOrder", ProductionOrder);
			
			OpenForm(
				"Report.StartingLotProductionChart.ObjectForm",
				FormParameters,
				ThisObject,
				New UUID);
				
		ElsIf TypeOf(DetailsValue) = Type("Structure") And DetailsValue.Type = "Stage" Then
			
			FormParameters = New Structure;
			FormParameters.Insert("ScheduleStatus", ScheduleStatus);
			If TypeOf(DetailsValue.Stage) = Type("DocumentRef.ProductionStage2_2") Then
				FormParameters.Insert("CommandParameter", DetailsValue.Stage);
			Else
				FormParameters.Insert("Stage", DetailsValue.Stage);
				FormParameters.Insert("KeyLot", DetailsValue.KeyLot);
				FormParameters.Insert("ProductionOrder", ProductionOrder);
			EndIf;
			
			OpenForm(
				"Report.ProductionStageResourceChart.ObjectForm",
				FormParameters,
				ThisObject,
				New UUID);
			
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	GanttChart.Clear(); // 60010106
	Points.Clear();
	
	AttachIdleHandler("GenerateReport_FullCalculation", 0.1, True);
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	Done = UploadEverythingToServer(100);
	
	If Not Done Then
		
		ShowQueryBox(
			New CallbackDescription("QuestionExpandEverythingContinueOutputEnd", ThisForm),
			StrTemplate(NStr("vi = 'Hiển thị %1 phần tử. Tiếp tục hiển thị?';
							|ru = 'Выведено %1 элементов. Продолжить вывод?';
							|en = '%1 items are displayed. Continue?'; fa = '%1 items are displayed. Continue?';
							|it = 'Выведено %1 элементов. Продолжить вывод?';
							|pl = 'Wyprowadzono %1 elementów. Kontynuować wyprowadzenie?';
							|tr = '""%1"" öğe çıkarıldı. Çıkarmaya devam edilsin mi?'"), 100),
			QuestionDialogMode.YesNo,,
			DialogReturnCode.No);
			
		Return;
		
	EndIf;
	
	ExpandAllPoints();
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	CollapseAllPoints();
	
EndProcedure

&AtClient
Procedure ShowLinks(Command)
	
	ShowLinks = Not ShowLinks;
	OutputParameters.ShowLinks = ShowLinks;
	
	ConfigureDependentFormElements(ThisForm);

	GanttChart.Clear(); // 60010106
	Points.Clear();
	
	AttachIdleHandler("GenerateReport", 0.1, True);

EndProcedure

#EndRegion

#Region Private

#Region Mode_OfManufacturingProducts_DynamicStructure

#Region DynamicOutput

&AtServerNoContext
Procedure DownloadNextLevel(Filter, Stages, Lots, WorkingDate, OutputParameters)
	
	ScheduleStatus = OutputParameters.ScheduleStatus;
	StagesShow = OutputParameters.StagesShow;
	
	Query = New Query;
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("StagesShow", StagesShow);
	Query.SetParameter("WorkingDate", WorkingDate);
	Query.SetParameter("ScheduleStatus", ScheduleStatus);
	Query.SetParameter("Filter", Filter);
	Query.Text =
	"SELECT
	|	
	|	MAX(Products_1.Stage) AS Stage,
	|	
	|	Plan.Products           AS Products,
	|	Plan.Characteristic         AS Characteristic,
	|	Plan.Warehouse                  AS Warehouse,
	|	Plan.Purpose             AS Purpose,
	|	Plan.ProductionOrder    AS ProductionOrder,
	|	Plan.KeyProducts       AS KeyProducts
	|
	|INTO MovableProducts
	|FROM
	|
	|	InformationRegister.OrderStructure AS Products_1
	|
	|	LEFT JOIN InformationRegister.OrderStructure AS Plan
	|	ON Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.KeyProducts    = Plan.ConnectionKeyTransfer
	|
	|WHERE
	|	Products_1.KeyLot IN (&Filter)
	|	AND Products_1.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.KeyLot
	|
	|HAVING
	|	SUM(Plan.ToSupply - Plan.Replaced)  > 0
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
	|	Products_1.Products        AS Products,
	|	Products_1.Characteristic      AS Characteristic,
	|	Products_1.Warehouse               AS Warehouse,
	|	Products_1.Purpose          AS Purpose,
	|	Products_1.ProductionOrder AS ProductionOrder,
	|	Products_1.KeyProducts    AS KeyProducts,
	|	Products_1.Stage                AS Stage
	|INTO TTWares
	|FROM
	|	InformationRegister.OrderStructure AS Products_1
	|WHERE
	|	Products_1.KeyLot IN (&Filter)
	|	AND Products_1.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|
	|GROUP BY
	|	Products_1.Products,
	|	Products_1.Characteristic,
	|	Products_1.Warehouse,
	|	Products_1.Purpose,
	|	Products_1.ProductionOrder,
	|	Products_1.KeyProducts,
	|	Products_1.Stage
	|
	|HAVING
	|	SUM(Products_1.ToSupply - Products_1.Replaced) > 0
	|
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts
	|;
	|
	|SELECT
	|	
	|	MAX(Products_1.Stage) AS Stage,
	|	
	|	Plan.Products           AS Products,
	|	Plan.Characteristic         AS Characteristic,
	|	Plan.Warehouse                  AS Warehouse,
	|	Plan.Purpose             AS Purpose,
	|	Plan.ProductionOrder    AS ProductionOrder,
	|	Plan.KeyProducts       AS KeyProducts,
	|	Plan.KeyLot             AS KeyLot, 
	|
	|	SUM(Plan.Scheduled + Plan.ReverseKittingScheduled + Plan.AllocatedInAssignedProductionLots + Plan.AllocatedInFreeProductionLots) AS Count
	|
	|INTO Plan
	|FROM
	|
	|	TTWares AS Products_1
	|
	|	LEFT JOIN InformationRegister.OrderStructure AS Plan
	|	ON Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.Warehouse               = Plan.Warehouse
	|	 AND Products_1.Purpose          = Plan.Purpose
	|	 AND Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.KeyProducts    = Plan.KeyProducts
	|	 AND Plan.LineKind IN (
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.KeyLot
	|
	|HAVING
	|	SUM(Plan.Scheduled + Plan.ReverseKittingScheduled + Plan.AllocatedInAssignedProductionLots + Plan.AllocatedInFreeProductionLots)  > 0
	|
	|UNION ALL
	|
	|SELECT
	|	
	|	MAX(Products_1.Stage) AS Stage,
	|	
	|	Plan.Products           AS Products,
	|	Plan.Characteristic         AS Characteristic,
	|	Plan.Warehouse                  AS Warehouse,
	|	Plan.Purpose             AS Purpose,
	|	Plan.ProductionOrder    AS ProductionOrder,
	|	Plan.KeyProducts       AS KeyProducts,
	|	Plan.KeyLot             AS KeyLot, 
	|
	|	SUM(Plan.Scheduled + Plan.ReverseKittingScheduled + Plan.AllocatedInAssignedProductionLots + Plan.AllocatedInFreeProductionLots) AS Count
	|
	|FROM
	|
	|	MovableProducts AS Products_1
	|
	|	LEFT JOIN InformationRegister.OrderStructure AS Plan
	|	ON Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.Warehouse               = Plan.Warehouse
	|	 AND Products_1.Purpose          = Plan.Purpose
	|	 AND Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.KeyProducts    = Plan.KeyProducts
	|	 AND Plan.LineKind IN (
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.KeyLot
	|
	|HAVING
	|	SUM(Plan.Scheduled + Plan.ReverseKittingScheduled + Plan.AllocatedInAssignedProductionLots + Plan.AllocatedInFreeProductionLots)  > 0
	|
	|INDEX BY
	|	KeyLot
	|;
	|SELECT
	|	Schedule.Stage AS Stage,
	|	Schedule.KeyLot AS KeyLot,
	|	CASE 
	|		WHEN Schedule.Stage REFS Catalog.ProductionStages THEN
	|			CAST(Schedule.Stage AS Catalog.ProductionStages).StageNumber
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2 THEN
	|			CAST(Schedule.Stage AS Document.ProductionStage2_2).StageNumber
	|		ELSE
	|			0
	|	END AS StageNumber,
	|	CASE 
	|		WHEN Schedule.Stage REFS Catalog.ProductionStages THEN
	|			CAST(Schedule.Stage AS Catalog.ProductionStages).NextStageNo
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2 THEN
	|			CAST(Schedule.Stage AS Document.ProductionStage2_2).NextStageNo
	|		ELSE
	|			0
	|	END AS NextStageNo,
	|	CASE 
	|		WHEN Schedule.Stage REFS Document.ProductionStage2_2 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS StageCreated,
	|	CASE
	|		WHEN VALUETYPE(Schedule.Stage) = TYPE(Catalog.ProductionStages) THEN
	|			CAST(Schedule.Stage AS Catalog.ProductionStages).Description
	|		WHEN VALUETYPE(Schedule.Stage) = TYPE(Document.ProductionStage2_2) THEN
	|			CAST(Schedule.Stage AS Document.ProductionStage2_2).Number + "", "" + CAST(Schedule.Stage AS Document.ProductionStage2_2).StageName
	|		ELSE
	|			""-""
	|	END AS StagePresentation,
	|
	|	Schedule.Begin AS LeftLimit,
	|	Schedule.Begin AS Begin,
	|	Schedule.Ending AS Ending,
	|
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
	|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|
	|WHERE
	|	Schedule.KeyLot IN (&Filter)
	|	AND NOT Schedule.Stage IN (UNDEFINED, VALUE(Catalog.ProductionStages.EmptyRef), VALUE(Document.ProductionStage2_2.EmptyRef))
	|	AND Schedule.ScheduleStatus = &ScheduleStatus
	|	AND &StagesShow
	|
	|ORDER BY
	|	StageNumber DESC
	|;
	|
	|SELECT
	|
	|	Plan.Stage AS Stage,
	|
	|	Plan.Products         AS Products,
	|	Plan.Characteristic       AS Characteristic,
	|	Plan.Warehouse                AS Warehouse,
	|	Plan.Purpose           AS Purpose,
	|	Plan.ProductionOrder  AS ProductionOrder,
	|	Plan.KeyProducts     AS KeyProducts,
	|	Plan.KeyLot           AS KeyLot,
	|
	|	PRESENTATION(Plan.Products)                  AS ProductsPresentation,
	|	PRESENTATION(Plan.Characteristic)                AS CharacteristicPresentation,
	|	PRESENTATION(Plan.Products.UnitOfMeasure) AS UnitOfMeasurePresentation,
	|
	|	Schedule.Begin AS LeftLimit,
	|	Schedule.Begin AS Begin,
	|	Schedule.Ending AS Ending,
	|
	|	1 AS State,
	|	Plan.Count AS Count,
	|
	|	TRUE AS ThereAreSubordinateLines
	|
	|FROM
	|	Plan AS Plan
	|	
	|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|	ON Schedule.KeyLot = Plan.KeyLot
	|	 AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|	 AND Schedule.ScheduleStatus = &ScheduleStatus
	|
	|ORDER BY
	|	Ending DESC, Products, Characteristic, Count DESC
	|";
	Query.TempTablesManager = New TempTablesManager;
	QueryResult = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	LoadQueryResultIntoArray(QueryResult[NumberOfPackages_-2], Stages);
	LoadQueryResultIntoArray(QueryResult[NumberOfPackages_-1], Lots);
	
EndProcedure

&AtClient
Procedure UploadPoint(Point, ChartPoint)
	
	KeyLot = New UUID(Left(Point.Value, 36));
	DownloadNextLevel(KeyLot, Stages, Lots, WorkingDate, OutputParameters);
	PrintPoints(GanttChart, Stages, Lots, ChartPoint, Points, OutputParameters);
	Point.Imported1 = True;
	
EndProcedure

&AtServer
Procedure UploadPointToServer(Point, ChartPoint, Stages, Lots)
	
	KeyLot = New UUID(Left(Point.Value, 36));
	DownloadNextLevel(KeyLot, Stages, Lots, WorkingDate, OutputParameters);
	PrintPoints(GanttChart, Stages, Lots, ChartPoint, Points, OutputParameters);
	Point.Imported1 = True;
	
EndProcedure

&AtServer
Procedure LoadFirstLevel()
	
	Stages = New Array();
	Lots = New Array();
	
	Query = New Query;
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("EmptyStage", Catalogs.ProductionStages.EmptyRef());
	Query.SetParameter("WorkingDate", WorkingDate);
	Query.SetParameter("ScheduleStatus", ScheduleStatus);
	Query.Text =
	"SELECT
	|	Products_1.Products        AS Products,
	|	Products_1.Characteristic      AS Characteristic,
	|	Products_1.Warehouse               AS Warehouse,
	|	Products_1.Purpose          AS Purpose,
	|	Products_1.ProductionOrder AS ProductionOrder,
	|	Products_1.KeyProducts    AS KeyProducts
	|INTO TTWares
	|FROM
	|	InformationRegister.OrderStructure AS Products_1
	|WHERE
	|	&GettingCondition
	|
	|GROUP BY
	|	Products_1.Products,
	|	Products_1.Characteristic,
	|	Products_1.Warehouse,
	|	Products_1.Purpose,
	|	Products_1.ProductionOrder,
	|	Products_1.KeyProducts
	|
	|HAVING
	|	SUM(Products_1.ToSupply + Products_1.Ordered - Products_1.Replaced) > 0
	|
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts
	|;
	|
	|SELECT
	|	
	|	&EmptyStage AS Stage,
	|	
	|	Plan.Products         AS Products,
	|	Plan.Characteristic       AS Characteristic,
	|	Plan.Warehouse                AS Warehouse,
	|	Plan.Purpose           AS Purpose,
	|	Plan.ProductionOrder  AS ProductionOrder,
	|	Plan.KeyProducts     AS KeyProducts,
	|	Plan.KeyLot           AS KeyLot,
	|
	|	PRESENTATION(Plan.Products)                  AS ProductsPresentation,
	|	PRESENTATION(Plan.Characteristic)                AS CharacteristicPresentation,
	|	PRESENTATION(Plan.Products.UnitOfMeasure) AS UnitOfMeasurePresentation,
	|
	|	MAX(Schedule.Begin) AS LeftLimit,
	|	MAX(Schedule.Begin) AS Begin,
	|	MAX(Schedule.Ending) AS Ending,
	|
	|	1 AS State,
	|	TRUE AS ThereAreSubordinateLines,
	|
	|	SUM(Plan.Scheduled + Plan.ReverseKittingScheduled + Plan.AllocatedInAssignedProductionLots + Plan.AllocatedInFreeProductionLots) AS Count
	|
	|FROM
	|
	|	TTWares AS Products_1
	|
	|	LEFT JOIN InformationRegister.OrderStructure AS Plan
	|	ON Products_1.Products        = Plan.Products
	|	 AND Products_1.Characteristic      = Plan.Characteristic
	|	 AND Products_1.Warehouse               = Plan.Warehouse
	|	 AND Products_1.Purpose          = Plan.Purpose
	|	 AND Products_1.ProductionOrder = Plan.ProductionOrder
	|	 AND Products_1.KeyProducts    = Plan.KeyProducts
	|	 AND Plan.LineKind IN (
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct),
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
	|
	|	INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|	ON Schedule.KeyLot = Plan.KeyLot
	|	 AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|	 AND Schedule.ScheduleStatus = &ScheduleStatus
	|
	|GROUP BY
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Warehouse,
	|	Plan.Purpose,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.KeyLot
	|
	|HAVING
	|	SUM(Plan.Scheduled + Plan.ReverseKittingScheduled + Plan.AllocatedInAssignedProductionLots + Plan.AllocatedInFreeProductionLots) > 0
	|
	|;";
	
	If Products.IsEmpty() Then
		
		Query.Text = StrReplace(Query.Text, "&GettingCondition", "
			|Products_1.ProductionOrder = &ProductionOrder
			|AND Products_1.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)");
		Query.SetParameter("ProductionOrder", ProductionOrder);
		
	Else
		
		FilterText1 = "";
		
		Filter = New Structure();
		Filter.Insert("ProductionOrder", ProductionOrder);
		Filter.Insert("Products", Products);
		
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
		
		Query.Text = StrReplace(Query.Text, "&GettingCondition", ?(IsBlankString(FilterText1), "FALSE", FilterText1));
		
	EndIf;
	
	LoadQueryResultIntoArray(Query.Execute(), Lots);
	PrintPoints(GanttChart, Stages, Lots, GanttChart, Points, OutputParameters);
	
EndProcedure

&AtServer
Function UploadEverythingToServer(Batch = -1)
	
	Stages = New Array();
	Lots = New Array();
	
	InitialNumberOfPoints = Points.Count();
	
	NotLoadedPoints = Points.FindRows(New Structure("Imported1", False));
	
	Boundary = NotLoadedPoints.UBound();
	
	While Boundary >= 0 Do

		Point = NotLoadedPoints[0];
		
		ChartPoint = GanttChart.SetPoint(Point.Value);
		
		UploadPointToServer(Point, ChartPoint, Stages, Lots);
		
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

&AtClientAtServerNoContext
Procedure PrintPoints(GanttChart, Stages, Lots, Val PointParent, Points, OutputParameters)
	
	Series = GanttChart.SetSeries("Occupation");
	PointsAndStages = New Map(); 
	
	If PointParent.Points.Count() = 1 And PointParent.Points[0].Value = 0 Then
		PointParent.Points.Delete(PointParent.Points[0]);
	EndIf;

	For Each String In Stages Do
		
		Point = PointParent.Points.Add();
		
		DetailsValue = New Structure("Type, Stage, KeyLot", "Stage", String.Stage, String.KeyLot);
		
		Point.Value    = "" + String.KeyLot + "/" + New UUID();
		Point.Text       = String.StagePresentation;
		Point.Details = DetailsValue;
		Point.Picture = ?(String.StageCreated,
			PictureLib.ManufacturingProcessProductionStageCreated, PictureLib.ManufacturingProcessProductionStage);
		
		GanttChartInterval = OutputIntervals(GanttChart, String, Point, Series, OutputParameters);
		
		If OutputParameters.ShowLinks
			And String.NextStageNo <> 0 Then
			
			For Each Follower In Stages Do
				
				If Follower.StageNumber = String.NextStageNo Then
					DeriveIntervalRelationships(GanttChart, GanttChartInterval, PointsAndStages[Follower.Stage], Series);
				ElsIf Follower.StageNumber < String.NextStageNo Then
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		PointsAndStages.Insert(String.Stage, Point);
		
		CachePoint(Points, Point, True);
		
	EndDo;
	
	For Each String In Lots Do
		
		If ValueIsFilled(PointsAndStages) Then
			PointParent = PointsAndStages.Get(String.Stage);
		EndIf;
		
		Point = PointParent.Points.Add();
		
		DetailsValue = New Structure("Type, KeyLot", "Lot", String.KeyLot);
		
		Presentation = StrTemplate("%1, %2 %3", ProductsClientServer.ProductPresentation(String.ProductsPresentation, String.CharacteristicPresentation), 
			Format(String.Count, "NZ=; NG="),
			String.UnitOfMeasurePresentation);
		
		Point.Value    = "" + String.KeyLot + "/" + New UUID();
		Point.Text       = Presentation;
		Point.Details = DetailsValue;
		
		GanttChartInterval = OutputIntervals(GanttChart, String, Point, Series, OutputParameters);
		
		If OutputParameters.ShowLinks And OutputParameters.StagesShow
			And Not (String.Property("Products") And OutputParameters.TheseAreRAndMRepairs) Then
			DeriveIntervalRelationships(GanttChart, GanttChartInterval, PointParent, Series);
		EndIf;
		
		If String.ThereAreSubordinateLines Then
			CachePoint(Points, Point);
			DummyPoint = Point.Points.Add();
			DummyPoint.Value = 0;
			GanttChart.GetValue(DummyPoint, Series).Add();
		EndIf;
		
	EndDo;

EndProcedure

&AtClientAtServerNoContext
Function OutputIntervals(GanttChart, String, Point, Series, OutputParameters)
	
	GanttChartValues = GanttChart.GetValue(Point, Series);
	
	// Output of the interval according to the data of the current line
	GanttChartInterval = GanttChartValues.Add();

	IntervalColor = ?(String.State = 3, OutputParameters.BackColors.TheStepIsCompleted, OutputParameters.BackColors.StageIsNotCompletedScheduledAutomatically);
	
	If String.Property("Products") And String.Property("Stage")
		And ValueIsFilled(String.Products) And ValueIsFilled(String.Stage) Then
		IntervalColor = OutputParameters.BackColors.Products;
	EndIf;
	
	If String.Begin <= String.Ending Then
		GanttChartInterval.Begin = String.Begin;
		GanttChartInterval.End = String.Ending;
	Else
		GanttChartInterval.Begin = String.Begin - 86400;
		GanttChartInterval.End = String.Begin;
	EndIf;
	GanttChartInterval.Details = Point.Details;
	GanttChartInterval.Color        = IntervalColor;
	
	Return GanttChartInterval;
	
EndFunction

&AtClientAtServerNoContext
Procedure DeriveIntervalRelationships(GanttChart, GanttChartInterval, Point, Series)
	
	If Not TypeOf(Point) = Type("GanttChartPoint") Then
		Return;
	EndIf;
	
	For Each Interval In GanttChart.GetValue(Point, Series) Do
		
		Item = GanttChartInterval.Add(Interval);
		
		If Item.Begin.End > Item.End.Begin Then
			Item.Color = WebColors.Red;
		Else
			Item.Color = New Color();
		EndIf;
		
		Break;
	
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CachePoint(Points, Point, Imported1 = False)
	Cache = Points.Add();
	Cache.Value = Point.Value;
	Cache.Imported1 = Imported1;
	Cache.Level = Point.Level();
EndProcedure

#EndRegion

#Region ExpandAll

&AtClientAtServerNoContext
Procedure ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, Expand, Series)

	Intervals = GanttChart.GetValue(ChartPoint, Series);
	
	If Intervals.Count() > 1 Then
		
		Interval1 = Undefined; // GanttChartInterval
		Interval2 = Undefined; // GanttChartInterval
		
		For Each Interval In Intervals Do
			
			Interval1 = ?(Interval1 <> Undefined And Interval1.Begin < Interval.Begin, Interval1, Interval);
			Interval2 = ?(Interval2 <> Undefined And Interval2.Begin > Interval.Begin, Interval2, Interval);
			
		EndDo;
		
		Interval1.End = ?(Expand, '00010101', Interval2.Begin - 1);
		
	EndIf;
	
	Point.IsExpanded = Expand;
	
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
	
	LoadedPoints = Points.FindRows(New Structure("Imported1", True)); // expand all uploaded points
	
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
	
	For IndexOf = -Points.Count() + 1 To 0 Do
		
		Point = Points[-IndexOf];
		
		ChartPoint = GanttChart.SetPoint(Point.Value);
		
		GanttChart.CollapsePoint(ChartPoint, False);
		
		ExpandOrCollapsePoint(GanttChart, Point, ChartPoint, False, ChartSeries);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Settings

&AtServer
Procedure UploadFormSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		FormKey(),
		FormSettingsKey());
	
	If TypeOf(Settings) = Type("Structure") Then
		
		Settings.Property("ViewMode", ViewMode);
		Settings.Property("StagesShow", StagesShow);
		Settings.Property("ShowLinks", ShowLinks);
		
		OutputParameters.StagesShow = StagesShow;
		OutputParameters.ShowLinks = ShowLinks;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveFormSettings()
	
	Settings = New Structure;
	
	Settings.Insert("ViewMode", ViewMode);
	Settings.Insert("StagesShow", StagesShow);
	Settings.Insert("ShowLinks", ShowLinks);
	
	SaveFormSettingsServer(Settings);
	
EndProcedure

&AtServerNoContext
Procedure SaveFormSettingsServer(Settings)
	
	Common.CommonSettingsStorageSave(
		FormKey(),
		FormSettingsKey(),
		Settings);
	
EndProcedure
	
&AtClientAtServerNoContext
Function FormKey()
	
	Return "Report.MonitorOrder.ReportForm";
	
EndFunction

&AtClientAtServerNoContext
Function FormSettingsKey()
	
	Return "Main_";
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure FillInListOfDisplayModes()
	
	ListOfModes = Items.ViewMode.ChoiceList;
		
	ListOfModes.Add(
		Modes.ByProducts,
		NStr("vi = 'Theo sản phẩm';
			|ru = 'По продукции';
			|en = 'By products'; fa = 'بر اساس محصولات';
			|it = 'По продукции';
			|pl = 'Wg produkcji';
			|tr = 'İmal edilen ürünlere göre'"));
	
	ListOfModes.Add(
		Modes.ByBusinessUnits,
		NStr("vi = 'Theo bộ phận';
			|ru = 'По подразделениям';
			|en = 'By business units'; fa = 'بر اساس واحدهای تجاری';
			|it = 'По подразделениям';
			|pl = 'Wg działów';
			|tr = 'Departmanlara göre'"));
	
	ListOfModes.Add(
		Modes.ByTypeOfWorkCenters,
		NStr("vi = 'Theo các dạng nguồn lực sản xuất';
			|ru = 'По видам рабочих центров';
			|en = 'By work center types'; fa = 'By work center types';
			|it = 'По видам рабочих центров';
			|pl = 'Wg rodzajów centrów pracy';
			|tr = 'İş merkezi türlerine göre'"));
		
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If ScheduleStatus = StatusWorkingSchedule() Then
		
		Template = NStr("vi = 'Màn hình theo dõi đơn hàng %1';
						|ru = 'Мониторинг заказа %1';
						|en = '%1 order monitoring'; fa = '%1 order monitoring';
						|it = 'Мониторинг заказа %1';
						|pl = 'Monitorowanie zamówienia %1';
						|tr = '%1 sipariş takibi'");
		
	ElsIf ScheduleStatus = StatusPreliminarySchedule() Then
		
		Template = NStr("vi = 'Màn hình theo dõi đơn hàng (dự tính) %1';
						|ru = 'Мониторинг заказа (планирование) %1';
						|en = '%1 order monitoring (planning)'; fa = '%1 order monitoring (planning)';
						|it = 'Мониторинг заказа (планирование) %1';
						|pl = '%1 order monitoring (planning)';
						|tr = 'Мониторинг заказа (планирование) %1'");
		
	ElsIf ScheduleStatus = StatusChartModel() Then
		
		Template = NStr("vi = 'Màn hình theo dõi đơn hàng (mô hình) %1';
						|ru = 'Мониторинг заказа (модель) %1';
						|en = '%1 order monitoring (model)'; fa = '%1 order monitoring (model)';
						|it = 'Мониторинг заказа (модель) %1';
						|pl = '%1 order monitoring (model)';
						|tr = 'Мониторинг заказа (модель) %1'");
		
	EndIf;
	
	Title = StrTemplate(Template, ?(Not Items.ProductionOrder.Visible, "", // Form navigation bar
		BriefPresentationOfOrder));
	
EndProcedure

&AtServer
Procedure ReadOrderAttributes()
	
	OrderDetails = Common.ObjectAttributesValues(ProductionOrder, "DynamicStructure, Status, Number, Date");
	
	FillPropertyValues(ThisForm, OrderDetails);
	
	If ProductionOrder.IsEmpty() Then
		BriefPresentationOfOrder = "";
	Else
		BriefPresentationOfOrder = Documents.ProductionOrder2_2.OrderPresentation(ProductionOrder, "", OrderDetails);
	EndIf;
	
	CurrentOrderStatus = OrderDetails.Status;
	
EndProcedure

&AtServer
Procedure AdjustVisibilityAccessibilityOfItems()
	
	Items.WarningOrderIsClosed.Visible = CurrentOrderStatus = Enums.ProductionOrderStatuses2_2.Closed;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(ThisForm)
	
	DynamicStructure = ThisForm.DynamicStructure;
	
	Modes = ThisForm.Modes;
	ViewMode = ThisForm.ViewMode;
	
	Items = ThisForm.Items;
	Items.Products.Visible = DynamicStructure And ViewMode = Modes.ByProducts;
	Items.StagesShow.Visible = DynamicStructure And ViewMode = Modes.ByProducts;
	Items.ShowLinks.Visible = DynamicStructure And ViewMode = Modes.ByProducts;
	Items.ExpandAll.Visible = False; // 60010106
	Items.CollapseAll.Visible = False;
	
	If DynamicStructure And ViewMode = Modes.ByProducts Then
		Items.GanttChartTableDot.ShowInHeader = True;
	Else
		
		Items.GanttChartTableDot.ShowInHeader = False;
	EndIf;
	
	Items.ShowLinks.Check = ThisForm.ShowLinks;
	
EndProcedure

&AtServer
Procedure AdjustChartTimeline()

	// Full Interval
	
	Period = InformationRegisters.ScheduleOfProductionStages2_2.FullInterval(ProductionOrder); 
	
	If Not ValueIsFilled(Period.Begin) Or Period.Begin > Period.Ending Then
		Return;
	EndIf;
	
	ScaleSettings = ProductionManagementClientServer.GanttChartScaleSettingsInAllDataMode(
		Period.Begin, Period.Ending, 9);
	
	TimelineElements = GanttChart.PlotArea.TimeScale.Items;
	
	For IndexOf = 1 To TimelineElements.Count()-1 Do
		TimelineElements.Delete(TimelineElements[IndexOf]);
	EndDo;
	
	ScaleElement = TimelineElements.Add();
	ScaleElement.Unit = ScaleSettings.Unit;
	ScaleElement.Format = ScaleSettings.Format;
	
	If TimelineElements.Count() = 2 Then
		TimelineElements.Delete(TimelineElements[0]);
	EndIf;
	
	GanttChart.SetWholeInterval(
		ScaleSettings.BeginOfWholeInterval,
		ScaleSettings.EndOfFullInterval);

	// Output allocation 
	
	GanttChart.BackgroundIntervals.Clear();
	
	Schedules = New Array();
	Schedules.Add(Constants.MainEnterpriseCalendar.Get());
	
	WorkSchedules1 = ProductionPlanning.ScheduleOfWorkOnSchedule(Schedules, ScaleSettings.BeginOfWholeInterval, ScaleSettings.EndOfFullInterval);
	WorkSchedules1.GroupBy("ScheduleDate");
	WorkSchedules1.Indexes.Add("ScheduleDate");
	
	PeriodsOfUnavailability = New ValueTable();
	PeriodsOfUnavailability.Columns.Add("Begin",    New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	PeriodsOfUnavailability.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	
	CurrentPeriod = ScaleSettings.BeginOfWholeInterval;
	While CurrentPeriod <= ScaleSettings.EndOfFullInterval Do
		
		If WorkSchedules1.Find(CurrentPeriod, "ScheduleDate") = Undefined Then
			NewPeriod = PeriodsOfUnavailability.Add();
			NewPeriod.Begin = CurrentPeriod;
			NewPeriod.Ending = EndOfDay(NewPeriod.Begin);
		EndIf;
		
		CurrentPeriod = CurrentPeriod + 86400;
	EndDo;
	
	For Each UnavailabilityData In PeriodsOfUnavailability Do
		
		GanttChart.BackgroundIntervals.Add(UnavailabilityData.Begin, UnavailabilityData.Ending);
		
	EndDo;
	
EndProcedure

&AtServer
Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

&AtServer
Function StatusPreliminarySchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusPreliminarySchedule();
	
EndFunction

&AtServer
Function StatusChartModel()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel();
	
EndFunction

&AtClient
Function ChartSeries()
	Series = GanttChart.SetSeries("Occupation");
	Return Series;
EndFunction

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
	
	TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);

EndProcedure

&AtClient
Procedure StartAwaitingLongAction()
	
	StartAwaitingLongAction = False;
	
	If ValueIsFilled(TimeConsumingOperation) Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("ProcessResultOfNotificationReportGeneration", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	Else
		ProcessReportGenerationResult();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessResultOfNotificationReportGeneration(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessReportGenerationResult();
	EndIf;
		
EndProcedure

&AtClient
Procedure GenerateReport()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	GenerateReportOnServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateReport_FullCalculation()
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	GenerateReportOnServer(True);
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateReportOnServer(CompleteCalculation = False)
	
	ScheduleIsLoaded = False;
	UpdateDate = '00010101';
	
	If Not TimeConsumingOperation = Undefined Then
		CancelLongRunningOperation();
	EndIf;
	
	If DynamicStructure And ViewMode = Modes.ByProducts Then
		
		TimeConsumingOperation = Undefined
		
	Else
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("ProductionOrder", ProductionOrder);
		ProcedureParameters.Insert("ScheduleStatus", ScheduleStatus);
		ProcedureParameters.Insert("ViewMode", ViewMode);
		ProcedureParameters.Insert("GanttChart", GanttChart);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo báo cáo ""Màn hình theo dõi đơn hàng sản xuất""';
															|ru = 'Формирование отчета ""Мониторинг заказа на производство""';
															|en = 'Generate the ""Production order monitoring"" report'; fa = 'Generate the ""Production order monitoring"" report';
															|it = 'Формирование отчета ""Мониторинг заказа на производство""';
															|pl = 'Generate the ""Production order monitoring"" report';
															|tr = '""Üretim Emri Takibi"" raporunun düzenlenmesi'");
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
			"Reports.MonitorOrder.GenerateReport",
			ProcedureParameters,
			ExecutionParameters);
		
	EndIf;
	
	If ValueIsFilled(TimeConsumingOperation)
		And TimeConsumingOperation.Status = "Completed2" Then
		
		ProcessReportGenerationResult();
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	Else
		
		StartAwaitingLongAction = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessReportGenerationResult()

	If ValueIsFilled(TimeConsumingOperation) And TimeConsumingOperation.Status = "Completed2" Then
		
		GanttChart = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
		TimeConsumingOperation = Undefined;
		
	Else
		
		If DynamicStructure And ViewMode = Modes.ByProducts Then
			
			ScheduleIsLoaded = True;
			LoadFirstLevel();
			
		EndIf;
		
	EndIf;
	
	AdjustChartTimeline();
	
	Items.WarningItIsRequiredToCalculateSchedule.Visible = InformationRegisters.ScheduleOfProductionStages2_2.ItIsRequiredToCalculateSchedule(ProductionOrder);
	
EndProcedure

&AtServer
Function BackColors()
	
	BackColors = New Structure();
	
	BackColors.Insert("TheStepIsCompleted",                            StyleColors.BackgroundColorStageIsCompleted);
	BackColors.Insert("StageIsNotCompletedScheduledAutomatically", StyleColors.BackgroundColorStageIsNotCompletedPlannedAutomatically);
	BackColors.Insert("StageIsNotCompletedScheduledManually",       StyleColors.BackgroundColorStageIsNotCompletedPlannedManually);
	BackColors.Insert("Products",                             StyleColors.BackgroundColorItem);
	
	Return BackColors;

EndFunction

#EndRegion

#EndRegion

#Region Initialize

Stages = New Array();
Lots = New Array();

#EndRegion