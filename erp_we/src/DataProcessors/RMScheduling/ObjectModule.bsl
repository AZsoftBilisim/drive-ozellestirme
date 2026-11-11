#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var MaximumRMCode; // Number - A counter of repair work numbers used as unique identifiers of repairs within a single planning procedure.
Var StartPlanning; // Date - Start date of repair planning.

#EndRegion

#Region Public

// Calculates the repair work plan-fills in the table parts "Orders for repair" and "Repairs"
// 		according to the table part "Objects for repair planning".
//
Procedure CalculateRepairPlan() Export
	
	SetPrivilegedMode(True);
	
	RMOrders.Clear();
	RM.Clear();
	MaterialsAndWorks.Clear();
	LaborCosts.Clear();
	
	StartPlanning = BegOfDay(EndOfDay(CurrentSessionDate())+1);
	EndOfPlanning = StartPlanning;
	
	QueryResults = DataForCalculatingRepairPlan();
	
	If QueryResults.PlanningObjects.IsEmpty() Then
		Return;
	EndIf;
	
	TempTablesManager = New TempTablesManager();
	ListOfGraphs = QueryResults.WorkSchedules.Unload().UnloadColumn("WorkScheduleCalendar");
	
	QueryResult = QueryResults.MaximumRepairDate; // QueryResult
	SelectionEndDate = QueryResult.Select();
	If SelectionEndDate.Next() Then
		EndOfPlanning = SelectionEndDate.MaximumRepairDate;
	EndIf;
	
	QueryResult = QueryResults.MaximumDurationOfRepair; // QueryResult
	SampleDuration = QueryResult.Select();
	If SampleDuration.Next() Then
		EndOfPlanning = EndOfPlanning + Int(SampleDuration.Duration) * 86400;
	EndIf;
	
	RMManagement.CreateScheduleByMinute(
		TempTablesManager, ListOfGraphs, StartPlanning, EndOfDay(EndOfDay(EndOfPlanning) + 1));
	
	CachedValues = New Structure;
	CachedValues.Insert("TempTablesManager", TempTablesManager);
	
	CachedValues.Insert("Samples", New Structure);
	
	QueryResult = QueryResults.PreviousRepairs; // QueryResult
	CachedValues.Samples.Insert("PreviousRepairs", QueryResult.Select());
	
	QueryResult = QueryResults.RunningTime; // QueryResult
	CachedValues.Samples.Insert("RunningTime", QueryResult.Select());
	
	QueryResult = QueryResults.PlanningObjects; // QueryResult
	CachedValues.Samples.Insert("PlanningObjects", QueryResult.Select());
	
	QueryResult = QueryResults.RepairCycles; // QueryResult
	CachedValues.Samples.Insert("RepairCycles", QueryResult.Select());
	
	QueryResult = QueryResults.OtherRMActivities; // QueryResult
	CachedValues.Samples.Insert("OtherRMActivities", QueryResult.Select());
	
	QueryResult = QueryResults.AfterRepairs; // QueryResult
	CachedValues.Samples.Insert("AfterRepairs", QueryResult.Select());
	
	MaximumRMCode = 1;
	
	SelectionOfPlanningObjects = CachedValues.Samples.PlanningObjects;
	While SelectionOfPlanningObjects.Next() Do
		
		CompleteRepairsOnCycle(SelectionOfPlanningObjects, CachedValues);
		CompleteOtherRepairs(SelectionOfPlanningObjects, CachedValues);
		
	EndDo;
	
EndProcedure

// Creates and fills out documents for repair orders
// 		according to the table parts "orders for Repair", "Repairs", "materials and Works", "labor Costs", "work Centers".
//
// Parameters:
// 		TheOrdersToBeDeleted - Array - Array of links to orders marked for deletion that can be used when filling out new orders.
//
// Returns:
// 		Structure - Structure with the fields:
// 			"Array of repair orders" - Array of created orders
// 			"Redefined messages" - Matching error arrays with links to created documents.
//
Function GenerateRepairOrders(TheOrdersToBeDeleted) Export
	
	ReturnValueStructure = New Structure();
	
	ReturnValueStructure.Insert("ArrayOfRepairOrders", New Array);
	ReturnValueStructure.Insert("OverriddenMessages", New Map);
	
	
	StructureOfDocumentDetailsValues = New Structure;
	StructureOfDocumentDetailsValues.Insert("Date", CurrentSessionDate());
	StructureOfDocumentDetailsValues.Insert("Status", Enums.RMOrderStatuses.Created);
	
	For Each RepairOrderLine In RMOrders Do
		
		If RM.FindRows(New Structure("RMOrderCode", RepairOrderLine.RMOrderCode)).Count() = 0 Then
			// If there are no planned repairs for this order
			Continue;
		EndIf;
		
		ThisDocument = True;
		ImplementationCompleted = True;
		
		If TheOrdersToBeDeleted.Count() = 0 Then
			DocumentObject_ = Documents.RMOrder.CreateDocument();
		Else
			DocumentObject_ = TheOrdersToBeDeleted[0].GetObject();
			DocumentObject_.DeletionMark = False;
			TheOrdersToBeDeleted.Delete(0);
		EndIf;
		DocumentObject_.RM.Clear();
		DocumentObject_.MaterialsAndWorks.Clear();
		DocumentObject_.LaborCosts.Clear();
		DocumentObject_.WorkCenters.Clear();
		DocumentObject_.RemovedDefects.Clear();
		DocumentObject_.Fill(StructureOfDocumentDetailsValues);
		
		FillPropertyValues(
			DocumentObject_, 
			RepairOrderLine, 
			"Asset, StartDate, CompletedOn, Department, RMActivity, GeneralRMType");
		
		FillInTabularPartsOfDocumentObject(DocumentObject_, RepairOrderLine.RMOrderCode);
		Documents.RMOrder.FillOutWarehouseByContentTransferSettings(DocumentObject_);
		
		ThisDocument = DocumentObject_.CheckFilling();
		
		If ThisDocument Then
			Try
				DocumentObject_.Write(DocumentWriteMode.Posting);
			Except
				ImplementationCompleted = False;
			EndTry;
		Else
			ImplementationCompleted = False;
		EndIf;
		
		If Not ImplementationCompleted Then
			Try
				DocumentObject_.Write(DocumentWriteMode.Write);
			Except
				ReturnValueStructure.ArrayOfRepairOrders.Clear();
				Raise NStr("vi = 'Lỗi khi cố gắng tạo chứng từ đặt hàng điều chỉnh:';
							|ru = 'Ошибка при попытке создания документа заказа на ремонт:';
							|en = 'An error occurred while trying to create the R&M order'; fa = 'An error occurred while trying to create the R&M order';
							|it = 'Errore durante il tentativo di creare un documento dell''ordine di manutenzione:';
							|pl = 'Błąd podczas próby utworzenia dokumentu zlecenia naprawy:';
							|tr = 'Bir onarım siparişi belgesi oluşturmaya çalışırken hata:'") + " " + ErrorInfo().Description;
			EndTry;
		EndIf;
		
		ReturnValueStructure.ArrayOfRepairOrders.Add(DocumentObject_.Ref);
		
		ErrorsArray = New Array;
		ReturnValueStructure.OverriddenMessages.Insert(DocumentObject_.Ref, ErrorsArray);
		DocumentGenerationErrors = GetUserMessages(True);
		For Each DocumentGenerationError In DocumentGenerationErrors Do
			DocumentGenerationError.DataKey = DocumentObject_.Ref;
			ErrorsArray.Add(DocumentGenerationError);
		EndDo;
		
	EndDo;
	
	Return ReturnValueStructure;
	
EndFunction

#EndRegion

#Region Private

// 
// Returns:
// 	Structure - See TMCommonUse.GetQueryResults
Function DataForCalculatingRepairPlan()
	
	Query = New Query;
	Query.SetParameter("StartPlanning", StartPlanning);
	Query.SetParameter("LastDateOfYear", BegOfDay(EndOfYear(StartPlanning)));
	Query.SetParameter("CurrentYear", Year(StartPlanning));
	Query.SetParameter("NextYear", Year(StartPlanning) + 1);
	Query.SetParameter("ArrayOfObjectsToRepair", ObjectsForRMScheduling.UnloadColumn("Asset"));
	Query.SetParameter("GeneralRMTypes", GeneralRMTypesForPlanning.UnloadColumn("GeneralRMType"));
	Query.SetParameter("SchedulingFrequencies", PlanningFrequency_.UnloadColumn("PlanningFrequency"));
	Query.SetParameter("MainEnterpriseCalendar", Constants.MainEnterpriseCalendar.Get());
	
	ListOfRequests = New ValueList();
	
	QueryText =
	"SELECT
	|	RepairFacilities.Ref AS Asset,
	|
	|	CASE 
	|		WHEN RepairFacilities.RMBusinessUnit.WorkScheduleSetupMethod = VALUE(Enum.MethodsOfConfiguringBusinessUnitWorkSchedule.MainEnterpriseCalendar)
	|			THEN &MainEnterpriseCalendar
	|		WHEN RepairFacilities.RMBusinessUnit.WorkScheduleSetupMethod = VALUE(Enum.MethodsOfConfiguringBusinessUnitWorkSchedule.PersonalSchedule)
	|			THEN ISNULL(DivisionSchedules.WorkScheduleCalendar, VALUE(Catalog.Calendars.EmptyRef))
	|		ELSE UNDEFINED
	|	END AS WorkScheduleCalendar,
	|
	|	CASE
	|		WHEN RepairFacilities.Class.UseOfSubclasses
	|			THEN RepairFacilities.Subclass
	|		ELSE RepairFacilities.Class
	|	END AS PPRStorage,
	|
	|	RepairFacilities.DateOfProduction AS CommissioningDate
	|
	|INTO PlanningObjects
	|FROM
	|	Catalog.Assets AS RepairFacilities
	|
	|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS DivisionSchedules
	|		ON DivisionSchedules.Ref = RepairFacilities.RMBusinessUnit
	|			AND DivisionSchedules.LineNumber = 1
	|WHERE
	|	RepairFacilities.Ref IN(&ArrayOfObjectsToRepair)
	|
	|UNION ALL
	|
	|SELECT
	|	RepairFacilities.Ref,
	|
	|	CASE 
	|		WHEN RepairFacilities.RMBusinessUnit.WorkScheduleSetupMethod = VALUE(Enum.MethodsOfConfiguringBusinessUnitWorkSchedule.MainEnterpriseCalendar)
	|			THEN &MainEnterpriseCalendar
	|		WHEN RepairFacilities.RMBusinessUnit.WorkScheduleSetupMethod = VALUE(Enum.MethodsOfConfiguringBusinessUnitWorkSchedule.PersonalSchedule)
	|			THEN ISNULL(DivisionSchedules.WorkScheduleCalendar, VALUE(Catalog.Calendars.EmptyRef))
	|		ELSE UNDEFINED
	|	END AS WorkScheduleCalendar,
	|
	|	CASE
	|		WHEN RepairFacilities.Class.UseOfSubclasses
	|			THEN RepairFacilities.Subclass
	|		ELSE RepairFacilities.Class
	|	END,
	|
	|	RepairFacilities.Owner.DateOfProduction
	|FROM
	|	Catalog.SubAssets AS RepairFacilities
	|
	|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS DivisionSchedules
	|		ON DivisionSchedules.Ref = RepairFacilities.RMBusinessUnit
	|			AND DivisionSchedules.LineNumber = 1
	|WHERE
	|	RepairFacilities.Ref IN(&ArrayOfObjectsToRepair)
	|
	|INDEX BY
	|	Asset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RMTypes.Ref AS RMType,
	|	CASE
	|		WHEN NOT RepairsInCurYear.ScheduleDate IS NULL
	|			THEN RepairsInCurYear.ScheduleDate
	|		WHEN NOT RenovationNextYear.ScheduleDate IS NULL
	|			THEN RenovationNextYear.ScheduleDate
	|		ELSE DATEADD(CAST(&StartPlanning AS DATE), DAY, RMTypes.Lookahead)
	|	END AS MaximumRepairDate,
	|	RMTypes.Duration,
	|	RMTypes.UnitOfMeasureOfDuration
	|INTO PermittedTypesOfRepairs
	|FROM
	|	Catalog.RMTypes AS RMTypes
	|
	|		LEFT JOIN InformationRegister.CalendarSchedules AS StartPlanning
	|		ON StartPlanning.Calendar = &MainEnterpriseCalendar
	|			AND StartPlanning.Year = &CurrentYear
	|			AND StartPlanning.ScheduleDate = &StartPlanning
	|
	|		LEFT JOIN InformationRegister.CalendarSchedules AS RepairsInCurYear
	|		ON RepairsInCurYear.Calendar = &MainEnterpriseCalendar
	|		 AND RepairsInCurYear.DayAddedToSchedule
	|		 AND RepairsInCurYear.Year = &CurrentYear
	|		 AND RepairsInCurYear.DaysCountInScheduleSinceBegOfYear
	|			= StartPlanning.DaysCountInScheduleSinceBegOfYear
	|			+ RMTypes.Lookahead
	|			+ CASE
	|				WHEN StartPlanning.DayAddedToSchedule THEN 0
	|				ELSE 1
	|			END
	|
	|		LEFT JOIN InformationRegister.CalendarSchedules AS LastDateOfYear
	|		ON RepairsInCurYear.ScheduleDate IS NULL
	|			AND LastDateOfYear.Calendar = &MainEnterpriseCalendar
	|			AND LastDateOfYear.Year = &CurrentYear
	|			AND LastDateOfYear.ScheduleDate = &LastDateOfYear
	|
	|		LEFT JOIN InformationRegister.CalendarSchedules AS RenovationNextYear
	|		ON RenovationNextYear.Calendar = &MainEnterpriseCalendar
	|			AND RenovationNextYear.DayAddedToSchedule
	|			AND RenovationNextYear.Year = &NextYear
	|			AND RenovationNextYear.DaysCountInScheduleSinceBegOfYear
	|				= RMTypes.Lookahead
	|				- (LastDateOfYear.DaysCountInScheduleSinceBegOfYear
	|					- StartPlanning.DaysCountInScheduleSinceBegOfYear)
	|				+ CASE
	|					WHEN StartPlanning.DayAddedToSchedule THEN 0
	|					ELSE 1
	|				END
	|WHERE
	|	RMTypes.GeneralRMType IN(&GeneralRMTypes)
	|	AND RMTypes.PlanningFrequency IN(&SchedulingFrequencies)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ClassesRepairCycle.Ref AS PPRStorage,
	|	ClassesRepairCycle.LineNumber,
	|	ClassesRepairCycle.RMType,
	|	ClassesRepairCycle.Ref.RMIntervalByActivityRecords,
	|	ClassesRepairCycle.TimeInterval,
	|	ClassesRepairCycle.TimeUnit,
	|	ClassesRepairCycle.RunningTimeInterval,
	|	ClassesRepairCycle.RunningTimeValue,
	|	CASE
	|		WHEN PermittedTypesOfRepairs.RMType IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Allowed_1,
	|	ISNULL(PermittedTypesOfRepairs.MaximumRepairDate, UNDEFINED) AS MaximumRepairDate,
	|	ISNULL(PermittedTypesOfRepairs.Duration, 0) AS Duration,
	|	ISNULL(PermittedTypesOfRepairs.UnitOfMeasureOfDuration, UNDEFINED) AS UnitOfMeasureOfDuration
	|INTO RepairCycles
	|FROM
	|	Catalog.MaintenanceSchemes.RMCycle AS ClassesRepairCycle
	|		LEFT JOIN PermittedTypesOfRepairs AS PermittedTypesOfRepairs
	|		ON ClassesRepairCycle.RMType = PermittedTypesOfRepairs.RMType
	|WHERE
	|	ClassesRepairCycle.Ref IN
	|			(SELECT
	|				PlanningObjects.PPRStorage
	|			FROM
	|				PlanningObjects AS PlanningObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	SubclassesRepairCycle.Ref,
	|	SubclassesRepairCycle.LineNumber,
	|	SubclassesRepairCycle.RMType,
	|	SubclassesRepairCycle.Ref.RMIntervalByActivityRecords,
	|	SubclassesRepairCycle.TimeInterval,
	|	SubclassesRepairCycle.TimeUnit,
	|	SubclassesRepairCycle.RunningTimeInterval,
	|	SubclassesRepairCycle.RunningTimeValue,
	|	CASE
	|		WHEN PermittedTypesOfRepairs.RMType IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	ISNULL(PermittedTypesOfRepairs.MaximumRepairDate, UNDEFINED),
	|	ISNULL(PermittedTypesOfRepairs.Duration, 0),
	|	ISNULL(PermittedTypesOfRepairs.UnitOfMeasureOfDuration, UNDEFINED)
	|FROM
	|	Catalog.MaintenanceSchemeOptions.RMCycle AS SubclassesRepairCycle
	|		LEFT JOIN PermittedTypesOfRepairs AS PermittedTypesOfRepairs
	|		ON SubclassesRepairCycle.RMType = PermittedTypesOfRepairs.RMType
	|WHERE
	|	SubclassesRepairCycle.Ref IN
	|			(SELECT
	|				PlanningObjects.PPRStorage
	|			FROM
	|				PlanningObjects AS PlanningObjects)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ClassesOtherRepairs.Ref AS PPRStorage,
	|	ClassesOtherRepairs.LineNumber,
	|	ClassesOtherRepairs.RMType,
	|	ClassesOtherRepairs.ByAssetActivity,
	|	ClassesOtherRepairs.TimeInterval,
	|	ClassesOtherRepairs.TimeUnit,
	|	ClassesOtherRepairs.RunningTimeInterval,
	|	ClassesOtherRepairs.RunningTimeValue,
	|	PermittedTypesOfRepairs.MaximumRepairDate,
	|	PermittedTypesOfRepairs.Duration,
	|	PermittedTypesOfRepairs.UnitOfMeasureOfDuration
	|INTO OtherRMActivities
	|FROM
	|	Catalog.MaintenanceSchemes.OtherRMActivities AS ClassesOtherRepairs
	|		INNER JOIN PermittedTypesOfRepairs AS PermittedTypesOfRepairs
	|		ON ClassesOtherRepairs.RMType = PermittedTypesOfRepairs.RMType
	|WHERE
	|	ClassesOtherRepairs.Ref IN
	|			(SELECT
	|				PlanningObjects.PPRStorage
	|			FROM
	|				PlanningObjects AS PlanningObjects)
	|
	|UNION ALL
	|
	|SELECT
	|	SubclassesOtherRepairs.Ref,
	|	SubclassesOtherRepairs.LineNumber,
	|	SubclassesOtherRepairs.RMType,
	|	SubclassesOtherRepairs.ByAssetActivity,
	|	SubclassesOtherRepairs.TimeInterval,
	|	SubclassesOtherRepairs.TimeUnit,
	|	SubclassesOtherRepairs.RunningTimeInterval,
	|	SubclassesOtherRepairs.RunningTimeValue,
	|	PermittedTypesOfRepairs.MaximumRepairDate,
	|	PermittedTypesOfRepairs.Duration,
	|	PermittedTypesOfRepairs.UnitOfMeasureOfDuration
	|FROM
	|	Catalog.MaintenanceSchemeOptions.OtherRMActivities AS SubclassesOtherRepairs
	|		INNER JOIN PermittedTypesOfRepairs AS PermittedTypesOfRepairs
	|		ON SubclassesOtherRepairs.RMType = PermittedTypesOfRepairs.RMType
	|WHERE
	|	SubclassesOtherRepairs.Ref IN
	|			(SELECT
	|				PlanningObjects.PPRStorage
	|			FROM
	|				PlanningObjects AS PlanningObjects)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(RMPlan.Period) AS Period,
	|	RMPlan.Asset AS Asset
	|INTO RecentRepairsPeriod
	|FROM
	|	InformationRegister.RMPlan AS RMPlan
	|		INNER JOIN PlanningObjects AS PlanningObjects
	|		ON RMPlan.Asset = PlanningObjects.Asset
	|WHERE
	|	RMPlan.RMCycle
	|		
	|GROUP BY
	|	RMPlan.Asset
	|
	|INDEX BY
	|	Period,
	|	Asset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RMPlan.Asset AS Asset,
	|	RMPlan.RMType AS RMType,
	|	RMPlan.RMCycle AS RMCycle,
	|	RMPlan.Period AS RepairDate
	|INTO RecentRepairs
	|FROM
	|	InformationRegister.RMPlan AS RMPlan
	|		INNER JOIN RecentRepairsPeriod AS Last
	|		ON RMPlan.Period = Last.Period
	|			AND RMPlan.Asset = Last.Asset
	|
	|UNION ALL
	|
	|SELECT
	|	RMPlanSliceLast.Asset,
	|	RMPlanSliceLast.RMType,
	|	RMPlanSliceLast.RMCycle,
	|	RMPlanSliceLast.Period
	|FROM
	|	InformationRegister.RMPlan.SliceLast(
	|			,
	|			NOT RMCycle
	|				AND Asset IN
	|					(SELECT
	|						PlanningObjects.Asset
	|					FROM
	|						PlanningObjects AS PlanningObjects)) AS RMPlanSliceLast";
	ListOfRequests.Add(QueryText);

	QueryText =
	"SELECT DISTINCT
	|	PlanningObjects.WorkScheduleCalendar AS WorkScheduleCalendar
	|FROM
	|	PlanningObjects AS PlanningObjects";
	ListOfRequests.Add(QueryText, "WorkSchedules");
	
	QueryText =
	"SELECT
	|	ISNULL(MAX(PermittedTypesOfRepairs.MaximumRepairDate), &StartPlanning) AS MaximumRepairDate
	|FROM
	|	PermittedTypesOfRepairs AS PermittedTypesOfRepairs";
	ListOfRequests.Add(QueryText, "MaximumRepairDate");
	
	QueryText =
	"SELECT
	|	ISNULL(MAX(RM.Duration), 0) AS Duration
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN RM.UnitOfMeasureOfDuration = VALUE(Enum.TimeMeasureUnits.DAY)
	|				THEN RM.Duration
	|			WHEN RM.UnitOfMeasureOfDuration = VALUE(Enum.TimeMeasureUnits.HOUR)
	|				THEN RM.Duration / 24
	|			WHEN RM.UnitOfMeasureOfDuration = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|				THEN RM.Duration / 24 / 60
	|			ELSE 0
	|		END AS Duration
	|	FROM
	|		RepairCycles AS RM
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE
	|			WHEN RM.UnitOfMeasureOfDuration = VALUE(Enum.TimeMeasureUnits.DAY)
	|				THEN RM.Duration
	|			WHEN RM.UnitOfMeasureOfDuration = VALUE(Enum.TimeMeasureUnits.HOUR)
	|				THEN RM.Duration / 24
	|			WHEN RM.UnitOfMeasureOfDuration = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|				THEN RM.Duration / 24 / 60
	|			ELSE 0
	|		END
	|	FROM
	|		OtherRMActivities AS RM) AS RM";
	ListOfRequests.Add(QueryText, "MaximumDurationOfRepair");
	
	QueryText =
	"SELECT
	|	RecentRepairs.Asset AS Asset,
	|	RecentRepairs.RMType AS RMType,
	|	RecentRepairs.RepairDate AS Period
	|FROM
	|	RecentRepairs AS RecentRepairs
	|WHERE
	|	NOT RecentRepairs.RMCycle";
	ListOfRequests.Add(QueryText, "PreviousRepairs");
	
	QueryText =
	"SELECT
	|	DevelopmentsCut.Asset AS Asset,
	|	DevelopmentsCut.RunningTimeValue AS RunningTimeValue,
	|	DevelopmentsCut.Period AS Period,
	|	DevelopmentsCut.Value AS Value,
	|	DevelopmentsCut.AverageDailyValue AS AverageDailyValue
	|FROM
	|	InformationRegister.AssetActivityRecords.SliceLast(
	|			&StartPlanning,
	|			(Asset, RunningTimeValue) IN
	|				(SELECT
	|					PlanningObjects.Asset AS Asset,
	|					RepairCycles.RunningTimeValue
	|				FROM
	|					PlanningObjects AS PlanningObjects
	|						INNER JOIN RepairCycles AS RepairCycles
	|						ON
	|							PlanningObjects.PPRStorage = RepairCycles.PPRStorage
	|				WHERE
	|					RepairCycles.RMIntervalByActivityRecords
	|			
	|				UNION ALL
	|			
	|				SELECT
	|					PlanningObjects.Asset AS Asset,
	|					OtherRMActivities.RunningTimeValue
	|				FROM
	|					PlanningObjects AS PlanningObjects
	|						INNER JOIN OtherRMActivities AS OtherRMActivities
	|						ON
	|							PlanningObjects.PPRStorage = OtherRMActivities.PPRStorage
	|				WHERE
	|					OtherRMActivities.ByAssetActivity)) AS DevelopmentsCut";
	ListOfRequests.Add(QueryText, "RunningTime");
	
	QueryText =
	"SELECT
	|	ISNULL(CatalogObjects_.Ref, NodeCatalog.Owner) AS Asset,
	|	ISNULL(NodeCatalog.Ref, VALUE(Catalog.SubAssets.EmptyRef)) AS Node,
	|	ISNULL(CatalogObjects_.RMBusinessUnit, NodeCatalog.RMBusinessUnit) AS Department,
	|	PlanningObjects.CommissioningDate AS CommissioningDate,
	|	PlanningObjects.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	PlanningObjects.PPRStorage AS PPRStorage,
	|	ISNULL(RecentRepairs.RMType, VALUE(Catalog.RMTypes.EmptyRef)) AS PreviousCycleRepairs,
	|	ISNULL(RecentRepairs.RepairDate, DATETIME(1, 1, 1, 0, 0, 0)) AS DateOfPreviousCycleRepair
	|FROM
	|	PlanningObjects AS PlanningObjects
	|		LEFT JOIN Catalog.Assets AS CatalogObjects_
	|		ON PlanningObjects.Asset = CatalogObjects_.Ref
	|		LEFT JOIN Catalog.SubAssets AS NodeCatalog
	|		ON PlanningObjects.Asset = NodeCatalog.Ref
	|		LEFT JOIN RecentRepairs AS RecentRepairs
	|		ON PlanningObjects.Asset = RecentRepairs.Asset
	|			AND (RecentRepairs.RMCycle)";
	ListOfRequests.Add(QueryText, "PlanningObjects");
	
	QueryText =
	"SELECT
	|	RepairCycles.PPRStorage AS PPRStorage,
	|	RepairCycles.LineNumber AS LineNumber,
	|	RepairCycles.RMType,
	|	RepairCycles.RMType.GeneralRMType AS GeneralRMType,
	|	RepairCycles.RMType.ConsiderWorkSchedule AS ConsiderWorkSchedule,
	|	RepairCycles.RMIntervalByActivityRecords AS ByAssetActivity,
	|	RepairCycles.TimeInterval,
	|	RepairCycles.TimeUnit,
	|	RepairCycles.RunningTimeInterval,
	|	RepairCycles.RunningTimeValue,
	|	RepairCycles.Allowed_1,
	|	RepairCycles.MaximumRepairDate,
	|	RepairCycles.Duration,
	|	RepairCycles.UnitOfMeasureOfDuration,
	|	RepairCycles.RMType.Lookahead AS AnticipatingRepairs
	|FROM
	|	RepairCycles AS RepairCycles
	|
	|ORDER BY
	|	PPRStorage,
	|	LineNumber";
	ListOfRequests.Add(QueryText, "RepairCycles");

	QueryText =
	"SELECT
	|	OtherRMActivities.PPRStorage AS PPRStorage,
	|	OtherRMActivities.LineNumber AS LineNumber,
	|	OtherRMActivities.RMType,
	|	OtherRMActivities.RMType.GeneralRMType AS GeneralRMType,
	|	OtherRMActivities.RMType.ConsiderWorkSchedule AS ConsiderWorkSchedule,
	|	OtherRMActivities.ByAssetActivity,
	|	OtherRMActivities.TimeInterval,
	|	OtherRMActivities.TimeUnit,
	|	OtherRMActivities.RunningTimeInterval,
	|	OtherRMActivities.RunningTimeValue,
	|	OtherRMActivities.MaximumRepairDate,
	|	OtherRMActivities.Duration,
	|	OtherRMActivities.UnitOfMeasureOfDuration,
	|	FALSE AS RepairCycleRule,
	|	OtherRMActivities.RMType.Lookahead AS AnticipatingRepairs
	|FROM
	|	OtherRMActivities AS OtherRMActivities
	|
	|ORDER BY
	|	PPRStorage,
	|	LineNumber";
	ListOfRequests.Add(QueryText, "OtherRMActivities");
	
	QueryText =
	"SELECT
	|	DevelopmentsOfLastRepairs.Asset,
	|	DevelopmentsOfLastRepairs.RMType,
	|	DevelopmentsOfLastRepairs.RMCycle,
	|	DevelopmentsOfLastRepairs.RunningTimeValue,
	|	RecentDevelopments.Value - RunningTime.Value AS Value
	|FROM
	|	(SELECT
	|		RecentRepairs.Asset AS Asset,
	|		RecentRepairs.RMType AS RMType,
	|		RecentRepairs.RMCycle AS RMCycle,
	|		RunningTime.RunningTimeValue AS RunningTimeValue,
	|		MAX(RunningTime.Period) AS Period
	|	FROM
	|		RecentRepairs AS RecentRepairs
	|			LEFT JOIN InformationRegister.AssetActivityRecords AS RunningTime
	|			ON RecentRepairs.Asset = RunningTime.Asset
	|				AND RecentRepairs.RepairDate > RunningTime.Period
	|	
	|	GROUP BY
	|		RecentRepairs.Asset,
	|		RecentRepairs.RMType,
	|		RecentRepairs.RMCycle,
	|		RunningTime.RunningTimeValue) AS DevelopmentsOfLastRepairs
	|		LEFT JOIN InformationRegister.AssetActivityRecords AS RunningTime
	|		ON DevelopmentsOfLastRepairs.Asset = RunningTime.Asset
	|			AND DevelopmentsOfLastRepairs.RunningTimeValue = RunningTime.RunningTimeValue
	|			AND DevelopmentsOfLastRepairs.Period = RunningTime.Period
	|		LEFT JOIN InformationRegister.AssetActivityRecords.SliceLast(&StartPlanning, ) AS RecentDevelopments
	|		ON DevelopmentsOfLastRepairs.Asset = RecentDevelopments.Asset
	|			AND DevelopmentsOfLastRepairs.RunningTimeValue = RecentDevelopments.RunningTimeValue";
	ListOfRequests.Add(QueryText, "AfterRepairs");
	
	QueryResults = TMCommonUse.GetQueryResults(Query, ListOfRequests);
	
	Return QueryResults;
	
EndFunction

// Returns the date of the previous repair of the item
//
// Parameters:
// 		Asset - CatalogRef.Assets, CatalogRef.SubAssets - Link to the object of operation for which you need to find the date of the last repair
// 		RMType - CatalogRef.RMTypes - Type of repair for which you need to find the date
// 		Samples - Structure - The structure with the cached samples.
//
// Returns:
// 		Date - The date of the previous repair.
//
Function GetPreviousRepairDate(Asset, RMType, Samples)
	
	PreviousRepairs = Samples.PreviousRepairs;
	
	PreviousRepairs.Reset();
	If PreviousRepairs.FindNext(New Structure("Asset, RMType", Asset, RMType)) Then
		
		Return PreviousRepairs.Period;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns the value of the operating time indicator from the date of the specified repair
//
// Parameters:
// 		Asset - CatalogRef.Assets, CatalogRef.SubAssets - Reference to the operational object to get the operating time for
// 		RMType - CatalogRef.RMTypes - Type of repair for which you need to get the operating time
// 		RMCycle - Boolean - Indicates whether it is necessary to get the operating time on the date of the last repair for the cycle
// 		RunningTimeValue - CatalogRef.RunningTimeValues - Link to the operating time indicator to get the values for
// 		Samples - Structure - The structure with the cached samples.
//
// Returns:
// 		Number - The difference between the values of the operating time from the cut of the last on the date of the specified repair and from the cut of the last on the current date.
//
Function GetRunningTimeFromDateOfLastRepair(Asset, RMType, RMCycle, RunningTimeValue, Samples)
	
	AfterRepairs = Samples.AfterRepairs;
	TheStructureOfTheSearch = New Structure(
		"Asset, RunningTimeValue",
		Asset,
		RunningTimeValue);
	
	If RMCycle Then
		TheStructureOfTheSearch.Insert("RMCycle", True);
	Else
		TheStructureOfTheSearch.Insert("RMType", RMType);
	EndIf;
	
	AfterRepairs.Reset();
	If AfterRepairs.FindNext(TheStructureOfTheSearch) Then
		Return Max(AfterRepairs.Value, 0);
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns the structure of the repair object's operating time values
//
// Parameters:
// 		Asset - CatalogRef.Assets, CatalogRef.SubAssets - Reference to the operational object to get the operating time for
// 		RunningTimeValue - CatalogRef.RunningTimeValues - Link to the operating time indicator to get the values for
// 		Samples - Structure - The structure with the cached samples.
//
// Returns:
// 		Structure - Structure of operating time values.
//
Function GetOperatingTime(Asset, RunningTimeValue, Samples)
	
	RunningTime = Samples.RunningTime;
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Asset", Asset);
	ReturnStructure.Insert("RunningTimeValue", RunningTimeValue);
	ReturnStructure.Insert("Period", Date(1, 1, 1, 0, 0, 0));
	ReturnStructure.Insert("Value", 0);
	ReturnStructure.Insert("AverageDailyValue", 0);

	RunningTime.Reset();
	If RunningTime.FindNext(New Structure("Asset, RunningTimeValue", Asset, RunningTimeValue)) Then
		FillPropertyValues(ReturnStructure, RunningTime);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Returns a table of values of the repair cycle
//
// Parameters:
// 		PPRStorage - CatalogRef.MaintenanceSchemes, CatalogRef.MaintenanceSchemeOptions - Link to the object with the rules of the repair cycle
// 		Samples - Structure - The structure with the cached samples.
//
// Returns:
// 		ValueTable - Table of the repair cycle.
//
Function GetRepairCycle(PPRStorage, Samples)
	
	RMCycle = New ValueTable;
	RMCycle.Columns.Add("LineNumber");
	RMCycle.Columns.Add("PreviousTypeOfRepair");
	RMCycle.Columns.Add("RMType");
	RMCycle.Columns.Add("GeneralRMType");
	RMCycle.Columns.Add("ByAssetActivity");
	RMCycle.Columns.Add("TimeInterval");
	RMCycle.Columns.Add("TimeUnit");
	RMCycle.Columns.Add("RunningTimeInterval");
	RMCycle.Columns.Add("RunningTimeValue");
	RMCycle.Columns.Add("Allowed_1");
	RMCycle.Columns.Add("MaximumRepairDate");
	RMCycle.Columns.Add("Duration");
	RMCycle.Columns.Add("UnitOfMeasureOfDuration");
	RMCycle.Columns.Add("WorkScheduleCalendar");
	RMCycle.Columns.Add("ConsiderWorkSchedule");
	RMCycle.Columns.Add("AnticipatingRepairs");
	RMCycle.Columns.Add("RepairCycleRule");
	
	PreviousTypeOfRepair = Catalogs.RMTypes.EmptyRef();
	
	RepairCycles = Samples.RepairCycles;
	RepairCycles.Reset();
	TheStructureOfTheSearch = New Structure("PPRStorage", PPRStorage);
	While RepairCycles.FindNext(TheStructureOfTheSearch) Do
		
		RepairCycleRule = RMCycle.Add();
		RepairCycleRule.PreviousTypeOfRepair = PreviousTypeOfRepair;
		FillPropertyValues(RepairCycleRule, RepairCycles);
		
		PreviousTypeOfRepair = RepairCycles.RMType;
		
	EndDo;
	
	If RMCycle.Count() <> 0 Then
		RMCycle[0].PreviousTypeOfRepair = PreviousTypeOfRepair;
	EndIf;
	
	RMCycle.FillValues(True, "RepairCycleRule");
	
	Return RMCycle;
	
EndFunction

// Fills in the table "Repairs" according to the data of the current object of operation according to the rules of the repair cycle.
//
// Parameters:
// 		SelectionOfPlanningObjects - QueryResultSelection - The current row of the selection from the query result for the planned objects
// 		CachedValues - Structure - The structure with the cached samples.
//
Procedure CompleteRepairsOnCycle(SelectionOfPlanningObjects, CachedValues)
	
	Samples = CachedValues.Samples;
	PreviousCycleRepairs = SelectionOfPlanningObjects.PreviousCycleRepairs;
	EndDateOfPreviousRepair = SelectionOfPlanningObjects.DateOfPreviousCycleRepair;
	
	RMCycle = GetRepairCycle(SelectionOfPlanningObjects.PPRStorage, Samples);
	
	If RMCycle.Count() = 0 Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(EndDateOfPreviousRepair) Then
		EndDateOfPreviousRepair = SelectionOfPlanningObjects.CommissioningDate;
	EndIf;
	
	LoopTraversalIndex = 0;
	If PreviousCycleRepairs <> Catalogs.RMTypes.EmptyRef() Then
		FoundRows = RMCycle.FindRows(New Structure("PreviousTypeOfRepair", PreviousCycleRepairs));
		If FoundRows.Count() <> 0 Then
			LoopTraversalIndex = FoundRows[0].LineNumber - 1;
		EndIf;
	EndIf;
	
	While True Do
		
		Rule = RMCycle[LoopTraversalIndex];
		If Not Rule.Allowed_1 Then
			Break;
		EndIf;
				
		NextRepair = FollowingRepairByRule(
			SelectionOfPlanningObjects, Rule, EndDateOfPreviousRepair, CachedValues);
		
		If NextRepair.Cancel Then
			Break;
		EndIf;
			
		NewRenovation = RM.Add();
		FillPropertyValues(NewRenovation, SelectionOfPlanningObjects, "Asset, Node, Department");
		FillPropertyValues(NewRenovation, NextRepair, "RMType, GeneralRMType, StartDate, CompletedOn, Duration, UnitOfMeasureOfDuration");
		
		NewRenovation.RMCycle = True;
		NewRenovation.RMCode = MaximumRMCode;
		MaximumRMCode = MaximumRMCode + 1;
		
		GetRepairOrder(NewRenovation);
		
		PreviousCycleRepairs = NextRepair.RMType;
		
		EndDateOfPreviousRepair = NextRepair.CompletedOn;
			
		LoopTraversalIndex = LoopTraversalIndex + 1;
		If LoopTraversalIndex = RMCycle.Count() Then
			LoopTraversalIndex = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the table "Repairs" according to the data of the current repair object according to the rules of other repairs.
//
// Parameters:
// 		SelectionOfPlanningObjects - QueryResultSelection - The current row of the selection from the query result for the planned objects
// 		CachedValues - Structure - The structure with the cached samples.
//
Procedure CompleteOtherRepairs(SelectionOfPlanningObjects, CachedValues)
	
	Samples = CachedValues.Samples;
	SelectionOfOtherRepairs = Samples.OtherRMActivities;
	SelectionOfOtherRepairs.Reset();
	FilterStructure1 = New Structure("PPRStorage", SelectionOfPlanningObjects.PPRStorage);
	
	ObjectUnderRepair = ?(ValueIsFilled(SelectionOfPlanningObjects.Node), 
		SelectionOfPlanningObjects.Node, 
		SelectionOfPlanningObjects.Asset);
	
	While SelectionOfOtherRepairs.FindNext(FilterStructure1) Do
		
		Rule = SelectionOfOtherRepairs;
		RMType = Rule.RMType;
		
		EndDateOfPreviousRepair = GetPreviousRepairDate(ObjectUnderRepair, RMType, Samples);
		If Not ValueIsFilled(EndDateOfPreviousRepair) Then
			EndDateOfPreviousRepair = SelectionOfPlanningObjects.CommissioningDate;
		EndIf;
		
		While True Do
			
			NextRepair = FollowingRepairByRule(
				SelectionOfPlanningObjects, Rule, EndDateOfPreviousRepair, CachedValues);
			
			If NextRepair.Cancel Then
				Break;
			EndIf;
				
			NewRenovation = RM.Add();
			FillPropertyValues(NewRenovation, SelectionOfPlanningObjects, "Asset, Node, Department");
			FillPropertyValues(NewRenovation, NextRepair, "RMType, GeneralRMType, StartDate, CompletedOn, Duration, UnitOfMeasureOfDuration");
			NewRenovation.RMCycle = False;
			NewRenovation.RMCode = MaximumRMCode;
			MaximumRMCode = MaximumRMCode + 1;
			
			GetRepairOrder(NewRenovation);
			
			EndDateOfPreviousRepair = NextRepair.CompletedOn;
				
		EndDo;
		
	EndDo;
	
EndProcedure

// Fills in the details "code Zakazanaremont" in the passed line of the table part "Repairs".
//
Procedure GetRepairOrder(RepairLine)
	
	CreateNewOrder = True;
	
	RepairSearchStructure = New Structure("RMOrderCode, Asset, Node, RMType");
	FillPropertyValues(RepairSearchStructure, RepairLine);
	
	TheStructureOfTheSearch = New Structure("Asset, Department");
	FillPropertyValues(TheStructureOfTheSearch, RepairLine);
	FoundRows = RMOrders.FindRows(TheStructureOfTheSearch);
	
	If FoundRows.Count() <> 0 Then
		
		For Each RMOrder In FoundRows Do
			
			RepairSearchStructure.RMOrderCode = RMOrder.RMOrderCode;
			If RM.FindRows(RepairSearchStructure).Count() <> 0 Then
				Continue; // If the order already has a repair of this type for this repaired object
			EndIf;
			
			OrderDuration = TMCommonUseClientServer.TimeInSeconds(RMOrder.Duration, RMOrder.UnitOfMeasureOfDuration);
			DurationOfRepair = TMCommonUseClientServer.TimeInSeconds(RepairLine.Duration, RepairLine.UnitOfMeasureOfDuration);
			
			If RMOrder.StartDate <= RepairLine.StartDate Then
				
				If RMOrder.CompletedOn >= RepairLine.StartDate Then
					
					CreateNewOrder = False;
					RepairLine.RMOrderCode = RMOrder.RMOrderCode;
					
					If DurationOfRepair > OrderDuration Then
						RMOrder.Duration = RepairLine.Duration;
						RMOrder.UnitOfMeasureOfDuration = RepairLine.UnitOfMeasureOfDuration;
					EndIf;
					
					Break;
				
				EndIf;
				
			ElsIf RepairLine.StartDate <= RMOrder.StartDate Then
				
				If RepairLine.CompletedOn >= RMOrder.StartDate Then
					
					CreateNewOrder = False;
					RepairLine.RMOrderCode = RMOrder.RMOrderCode;
					RMOrder.StartDate = RepairLine.StartDate;
					
					If DurationOfRepair > OrderDuration Then
						RMOrder.Duration = RepairLine.Duration;
						RMOrder.UnitOfMeasureOfDuration = RepairLine.UnitOfMeasureOfDuration;
					EndIf;
					
					Break;
				
				EndIf;
			
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If CreateNewOrder Then
		
		RMOrderCode = RMOrders.Count() + 2;
		RMOrder = RMOrders.Add();
		RMOrder.RMOrderCode = RMOrderCode;
		FillPropertyValues(
			RMOrder, 
			RepairLine, 
			"Asset, StartDate, CompletedOn, Department, Duration, UnitOfMeasureOfDuration, GeneralRMType");
		
		RepairLine.RMOrderCode = RMOrderCode;
		
	EndIf;
	
EndProcedure

// Returns the structure of the next repair according to the planning rule
//
// Parameters:
// 		SelectionOfPlanningObjects - QueryResultSelection - The current row of the selection from the query result for the planned objects
// 		Rule - ValueTableRow, QueryResultSelection - Planning rule description string
// 		EndDateOfPreviousRepair - Date - The date of the previous repair for the repair cycle or for the current rule for other repairs.
// 		CachedValues - Structure - The structure with the cached samples.
//
// Returns:
// 	Structure - Contains:
// 		* RMType - CatalogRef.RMTypes -
// 		* GeneralRMType - CatalogRef.GeneralRMTypes - 
// 		* StartDate - Date -
// 		* Duration - Number -
// 		* UnitOfMeasureOfDuration - EnumRef.TimeMeasureUnits - 
// 		* Cancel - Boolean - 
Function FollowingRepairByRule(SelectionOfPlanningObjects, Rule, EndDateOfPreviousRepair, CachedValues)
	
	RepairStructure = New Structure("RMType, GeneralRMType, StartDate, CompletedOn, Duration, UnitOfMeasureOfDuration, Cancel");
	RepairStructure.RMType = Rule.RMType;
	RepairStructure.GeneralRMType = Rule.GeneralRMType;
	RepairStructure.Duration = Rule.Duration;
	RepairStructure.UnitOfMeasureOfDuration = Rule.UnitOfMeasureOfDuration;
	RepairStructure.Cancel = False;
	
	If Rule.ByAssetActivity Then
		
		ObjectUnderRepair = ?(ValueIsFilled(SelectionOfPlanningObjects.Node), 
				SelectionOfPlanningObjects.Node, 
				SelectionOfPlanningObjects.Asset);
		
		OperatingTimeStructure = GetOperatingTime(ObjectUnderRepair, Rule.RunningTimeValue, CachedValues.Samples);
		OperatingTimeSinceLastRepair = 0;
		
		If EndDateOfPreviousRepair < StartPlanning Then
			
			OperatingTimeSinceLastRepair = GetRunningTimeFromDateOfLastRepair(
				ObjectUnderRepair,
				RepairStructure.RMType,
				Rule.RepairCycleRule,
				Rule.RunningTimeValue,
				CachedValues.Samples);
			
			If OperatingTimeSinceLastRepair = Undefined Then
				
				OperatingTimeSinceLastRepair = OperatingTimeStructure.Value;
				
			EndIf;
			
		EndIf;
		
		If OperatingTimeSinceLastRepair >= Rule.RunningTimeInterval Then
			
			RepairStructure.StartDate = StartPlanning;
			
		Else
			
			If OperatingTimeStructure.AverageDailyValue = 0
				Or (Rule.RunningTimeInterval - OperatingTimeSinceLastRepair) = 0 Then
				
				RepairStructure.Cancel = True;
				
			Else
				
				FromDate_ = ?(OperatingTimeSinceLastRepair = 0,
					EndDateOfPreviousRepair,
					BegOfDay(OperatingTimeStructure.Period));
				
				TimeInterval = (Rule.RunningTimeInterval - OperatingTimeSinceLastRepair) / OperatingTimeStructure.AverageDailyValue;
				If TimeInterval <> Int(TimeInterval) Then
					TimeInterval = Int(TimeInterval) + 1;
				EndIf;
							
				RepairStructure.StartDate = RMManagement.AddTimeToDateBasedOnWorkSchedule(
					FromDate_, 
					TimeInterval, 
					Enums.TimeMeasureUnits.Day,
					SelectionOfPlanningObjects.WorkScheduleCalendar);
				 
			EndIf;
			
		EndIf;
		
	Else
		
		If ValueIsFilled(EndDateOfPreviousRepair) Then
			RepairStructure.StartDate = RMManagement.AddTimeToDateBasedOnWorkSchedule(
				EndDateOfPreviousRepair, 
				Rule.TimeInterval, 
				Rule.TimeUnit,
				SelectionOfPlanningObjects.WorkScheduleCalendar);
		Else
			RepairStructure.StartDate = StartPlanning;
		EndIf;
		
	EndIf;
	
	If RepairStructure.Cancel Then
		Return RepairStructure;
	EndIf;
	
	If RepairStructure.StartDate < StartPlanning Then
		RepairStructure.StartDate = StartPlanning;
	EndIf;
	
	// A date is needed, taking into account the work schedule.
	RepairStructure.StartDate = RMManagement.AddTimeToDateBasedOnWorkSchedule_(
			RepairStructure.StartDate, 
			0, 
			Enums.TimeMeasureUnits.Hour, 
			SelectionOfPlanningObjects.WorkScheduleCalendar, 
			CachedValues.TempTablesManager);
	
	// Checking the occurrence in the planning interval
	If RepairStructure.StartDate > Rule.MaximumRepairDate Then
		RepairStructure.Cancel = True;
		Return RepairStructure;
	EndIf;
	
	If RepairStructure.UnitOfMeasureOfDuration = Enums.TimeMeasureUnits.Day Then
		
		RepairStructure.CompletedOn = RMManagement.AddTimeToDateBasedOnWorkSchedule(
			RepairStructure.StartDate, 
			?(RepairStructure.Duration <> 0, RepairStructure.Duration - 1, 0),
			RepairStructure.UnitOfMeasureOfDuration,
			SelectionOfPlanningObjects.WorkScheduleCalendar);
			
		RepairStructure.CompletedOn = RMManagement.EndOfWorkingDay(
			RepairStructure.CompletedOn,
			SelectionOfPlanningObjects.WorkScheduleCalendar,
			CachedValues.TempTablesManager)
		
	Else
		
		RepairStructure.CompletedOn = RMManagement.AddTimeToDateBasedOnWorkSchedule_(
			RepairStructure.StartDate,
			RepairStructure.Duration,
			RepairStructure.UnitOfMeasureOfDuration,
			SelectionOfPlanningObjects.WorkScheduleCalendar, 
			CachedValues.TempTablesManager);
			
	EndIf;
	
	Return RepairStructure;
	
EndFunction

// Fills in the table parts of the document "custom repair" according to the data of the table parts of processing.
//
// Parameters:
// 		DocumentObject_ - DocumentObject.RMOrder - Order document object
// 		RMOrderCode - Number - Order code that you want to transfer to the document.
//
Procedure FillInTabularPartsOfDocumentObject(DocumentObject_, RMOrderCode)
	
	StructureOfSelectionByOrder = New Structure("RMOrderCode", RMOrderCode);
	
	For Each Repair In RM.FindRows(StructureOfSelectionByOrder) Do
		
		RepairFromDocument = DocumentObject_.RM.Add();
		FillPropertyValues(RepairFromDocument, Repair, "Node, RMType, RMCycle");
		DocumentObject_.MaximumRMCode = DocumentObject_.MaximumRMCode + 1;
		RepairFromDocument.RMCode = DocumentObject_.MaximumRMCode;
		
		RepairSelectionStructure = New Structure("RMCode", Repair.RMCode);
		
		FoundRows = MaterialsAndWorks.FindRows(RepairSelectionStructure);
		If FoundRows.Count() = 0 Then
			FillInRepairWorkMaterials_(DocumentObject_, RepairFromDocument);
		Else
			For Each LineOfMaterialsAndWorks In FoundRows Do
				NewRow = DocumentObject_.MaterialsAndWorks.Add();
				FillPropertyValues(NewRow, LineOfMaterialsAndWorks);
				FillPropertyValues(NewRow, RepairFromDocument, "RMCode");
			EndDo;
		EndIf;

		FoundRows = WorkCenters.FindRows(RepairSelectionStructure);
		If FoundRows.Count() = 0 Then
			FillOutRepairCenters(DocumentObject_, RepairFromDocument);
		Else
			For Each StringOfWorkCenters In FoundRows Do
				If DocumentObject_.WorkCenters.FindRows(New Structure("WorkCenter", StringOfWorkCenters.WorkCenter)).Count()=0 Then
					NewRow = DocumentObject_.WorkCenters.Add();
					FillPropertyValues(NewRow, StringOfWorkCenters);
					FillPropertyValues(NewRow, DocumentObject_, "StartDate, CompletedOn");
				EndIf;
			EndDo;
		EndIf;
		
	EndDo;
	
	FillInExpenseItems(DocumentObject_);
	
	Documents.RMOrder.FillOutWarehouseByContentTransferSettings(DocumentObject_);
	
EndProcedure

// Fills in the table part of materials/works for the repair line
//
// Parameters:
// 		DocumentObject_ - DocumentObject.RMOrder - Object of the repair order document
// 		Repair - LineOfATabularSection - Repair table row
//
Procedure FillInRepairWorkMaterials_(DocumentObject_, Repair)
	
	Query = New Query(
		"SELECT
		|	RMTypesMaterialsAndWorks.Products,
		|	RMTypesMaterialsAndWorks.Characteristic,
		|	RMTypesMaterialsAndWorks.Package,
		|	RMTypesMaterialsAndWorks.NumberOfPackages,
		|	RMTypesMaterialsAndWorks.Count
		|FROM
		|	Catalog.RMTypes.MaterialsAndWorks AS RMTypesMaterialsAndWorks
		|WHERE
		|	RMTypesMaterialsAndWorks.Ref = &RMType");
	
	Query.SetParameter("RMType", Repair.RMType);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	FillingStructure = New Structure("RMCode");
	FillPropertyValues(FillingStructure, Repair);
	
	StructureOfActions = New Structure();
	AddCollateralActionsOnServer(StructureOfActions, DocumentObject_);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	Selection = Result.Select();
	While Selection.Next() Do
		
		NewRow = DocumentObject_.MaterialsAndWorks.Add();
		FillPropertyValues(NewRow, Selection);
		FillPropertyValues(NewRow, FillingStructure);
		RowsToProcess.Add(NewRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		DocumentObject_.MaterialsAndWorks,
		CachedValues);
		
EndProcedure

// Fills in the table part of the work centers for the repair line
//
//
// Parameters:
// 		DocumentObject_ - DocumentObject.RMOrder - Object of the repair order document
// 		Repair - LineOfATabularSection - Row in the repair table.
//
Procedure FillOutRepairCenters(DocumentObject_, Repair)
	
	Query = New Query(
		"SELECT
		|	WorkCenters.WorkCenter
		|FROM
		|	Catalog.Assets.WorkCenters AS WorkCenters
		|WHERE
		|	WorkCenters.Ref = &Asset
		|	AND (&ThisIsRepairOfObject
		|			OR CAST(&Node AS Catalog.SubAssets).InfluenceOnWorkCenterAvailability)
		|	AND NOT WorkCenters.WorkCenter IN (&WorkCenters)");
	
	Query.SetParameter("ThisIsRepairOfObject", Not ValueIsFilled(Repair.Node));
	Query.SetParameter("Asset", DocumentObject_.Asset);
	Query.SetParameter("Node", Repair.Node);
	Query.SetParameter("WorkCenters", DocumentObject_.WorkCenters.Unload(,"WorkCenter"));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		NewRow = DocumentObject_.WorkCenters.Add();
		FillPropertyValues(NewRow, Selection);
		FillPropertyValues(NewRow, DocumentObject_, "StartDate, CompletedOn");
	EndDo;
	
EndProcedure

// Fills in expense items by setting up expense reflection
//
Procedure FillInExpenseItems(DocumentObject_)
	
	Query = New Query(
		"SELECT
		|	CAST(FillingData.LineNumber AS NUMBER) AS LineNumber,
		|	CAST(&Asset AS Catalog.Assets) AS Asset,
		|	CAST(FillingData.Node AS Catalog.SubAssets) AS Node,
		|	CAST(FillingData.RMType AS Catalog.RMTypes) AS RMType
		|INTO FillingData
		|FROM
		|	&FillingData AS FillingData
		|
		|INDEX BY
		|	RMType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FillingData.LineNumber - 1 AS RowIndex,
		|	ISNULL(GeneralRMTypes.ExpenseItem, ISNULL(Nodes.ExpenseItem, FillingData.Asset.ExpenseItem)) AS ExpenseItem
		|FROM
		|	FillingData AS FillingData
		|		LEFT JOIN Catalog.GeneralRMTypes AS GeneralRMTypes
		|		ON FillingData.RMType.GeneralRMType = GeneralRMTypes.Ref
		|			AND (GeneralRMTypes.DefaultExpenseItem)
		|		LEFT JOIN Catalog.SubAssets AS Nodes
		|		ON FillingData.Node = Nodes.Ref
		|			AND (Nodes.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))");
	Query.SetParameter("FillingData", DocumentObject_.RM.Unload());
	Query.SetParameter("Asset", DocumentObject_.Asset);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		FillPropertyValues(DocumentObject_.RM[Selection.RowIndex], Selection);
	EndDo;
	
EndProcedure

Procedure AddCollateralActionsOnServer(StructureOfActions, Object)
	
	DocumentParameters = Documents.RMOrder.DocumentParametersForSoftwareActions(Object);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, "SupplyOption", DocumentParameters);
	
EndProcedure

#EndRegion

#EndIf
