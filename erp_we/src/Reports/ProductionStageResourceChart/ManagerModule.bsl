#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a report.
//
// Parameters:
//  Parameters  - Structure - report generation parameters. Contains:
//		* Stage - DocumentRef.ProductionStage2_2 - the stage being diagnosed.
//		* ScheduleStatus - Number - status of the graph being diagnosed.
//		* SpreadsheetDocument - SpreadsheetDocument - table document.
//  StorageAddress - String - address of the storage where the report generation result will be placed.
//
Procedure GenerateReport(Parameters, StorageAddress) Export
	
	SpreadsheetDocument = Parameters.SpreadsheetDocument;
	SpreadsheetDocument.Clear();
	DecipheringAlternatives = New Array;
	
	Data_Stage = Data_Stage(Parameters.Stage, Parameters.ScheduleStatus, Parameters.KeyLot);
	
	AppearanceTemplate = Reports.ProductionStageResourceChart.GetTemplate("StageResourceChart");
	
	If Data_Stage <> Undefined Then
		OutputHeader(SpreadsheetDocument, Data_Stage, AppearanceTemplate);
		OutputAdjacentStages(SpreadsheetDocument, Data_Stage, AppearanceTemplate);
		OutputLeftBorder(SpreadsheetDocument, Data_Stage, AppearanceTemplate);
		OutputPerformers(SpreadsheetDocument, Data_Stage, AppearanceTemplate, DecipheringAlternatives);
		OutputMaterials(SpreadsheetDocument, Data_Stage, AppearanceTemplate);
		OutlineStageBoundaries(SpreadsheetDocument, Data_Stage);
	EndIf;
	
	Result = New Structure;
	Result.Insert("SpreadsheetDocument", SpreadsheetDocument);
	Result.Insert("DecipheringAlternatives", DecipheringAlternatives);
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddProductionStageScheduleDiagnosticsCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ProductionStageResourceChart)
		And ProductionManagementCached.TheProductionScheduleIsUsed() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id      = Metadata.Reports.ProductionStageResourceChart.FullName();
		ReportCommand.Presentation      = NStr("vi = 'Chẩn đoán lịch';
												|ru = 'Диагностика графика';
												|en = 'Schedule adjustment'; fa = 'Schedule adjustment';
												|it = 'Diagnostica del grafico';
												|pl = 'Diagnostyka harmonogramu';
												|tr = 'Program tanılama'");
		ReportCommand.FormName           = "Report.ProductionStageResourceChart.Form";
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance           = "Ordinary";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionStageResourceChart);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region AdjacentStages

Procedure OutputAdjacentStages(SpreadsheetDocument, Data_Stage, AppearanceTemplate)
	
	Stages = AdjacentStages(Data_Stage);
	If Stages.Count() = 0 Then
		Return;
	EndIf;
	
	HeaderArea_ = AppearanceTemplate.GetArea("RelatedStagesHeader");
	If Data_Stage.GoBackToBeginning Then
		HeaderArea_.Area("R1C1").Text = NStr("vi = 'Tiền nhiệm';
											|ru = 'Предшественники';
											|en = 'Predecessors stages'; fa = 'Predecessors stages';
											|it = 'Predecessori';
											|pl = 'Predecessors stages';
											|tr = 'Öncüller'");
	Else
		HeaderArea_.Area("R1C1").Text = NStr("vi = 'Người theo dõi';
											|ru = 'Последователи';
											|en = 'Successors'; fa = 'مراحل بعدی';
											|it = 'Successori';
											|pl = 'Successors';
											|tr = 'Ardıllar'");
	EndIf;
	
	SpreadsheetDocument.Put(HeaderArea_);
	
	DesignFeatures = OtherPerformers(AppearanceTemplate);
	
	AreaStage = AppearanceTemplate.GetArea("Stage");
	ScopeStageData = AppearanceTemplate.GetArea("StageData_");
	
	For Each Stage In Stages Do
		
		AreaStage.Parameters.ProductionStage = Stage.ProductionStage;
		AreaStage.Parameters.PresentationStage = Stage.PresentationStage;
		SpreadsheetDocument.Put(AreaStage);
		
		For IndexOf = 0 To Data_Stage.Intervals.Count()-1 Do
			Interval = Data_Stage.Intervals[IndexOf]; // ValueTableRow
			Begin = Interval.Begin;
			
			If Data_Stage.GoBackToBeginning Then
				
				If Begin < Stage.StageEnd Then
					SetAreaLayout(ScopeStageData.Areas.StageData_, DesignFeatures.IntervalBusy);
				Else
					SetAreaLayout(ScopeStageData.Areas.StageData_, DesignFeatures.IntervalAvailable);
				EndIf;
				
			Else
				
				Ending = Interval.Ending - 1;
				If Ending >= Stage.StageStart And ValueIsFilled(Stage.StageStart) Then
					SetAreaLayout(ScopeStageData.Areas.StageData_, DesignFeatures.IntervalBusy);
				Else
					SetAreaLayout(ScopeStageData.Areas.StageData_, DesignFeatures.IntervalAvailable);
				EndIf;
				
			EndIf;
			
			AddedArea = SpreadsheetDocument.Join(ScopeStageData);
			
			Details = New Structure;
			Details.Insert("AreaView", "OpenAdjacentStageDiagnostics");
			Details.Insert("ProductionStage", Stage.ProductionStage);
			Details.Insert("KeyLot", Stage.KeyLot);
			
			AddedArea.Details = Details;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function AdjacentStages(Data_Stage)
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ProductionStage", Data_Stage.Stage);
	Query.SetParameter("KeyLot", Data_Stage.KeyLot);
	Query.SetParameter("ScheduleStatus", Data_Stage.ScheduleStatus);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	Query.Text =
		"SELECT
		|	&ProductionStage AS ProductionStage,
		|	&KeyLot       AS KeyLot
		|INTO Data_Stage";
	
	Query.Execute();
	
	ProductionManagement.CreateVTLinksOfStages(TempTablesManager, "Data_Stage", "ProductionStage", "KeyLot", True, True);
	
	BatchQueryText = New Array;
	
	If Data_Stage.GoBackToBeginning Then
		BatchQueryText.Add(
			"SELECT DISTINCT
			|	Links.Stage AS ProductionStage,
			|	Links.KeyLot AS KeyLot
			|INTO TTStages
			|FROM
			|	TTCommunicationStages AS Links
			|WHERE
			|	Links.NextStage = &ProductionStage
			|	AND Links.NextStageIsKeyLotReference IN (&KeyLot, &EmptyLinkKey)");
	Else
		BatchQueryText.Add(
			"SELECT DISTINCT
			|	Links.NextStage AS ProductionStage,
			|	Links.NextStageIsKeyLotReference AS KeyLot
			|INTO TTStages
			|FROM
			|	TTCommunicationStages AS Links
			|WHERE
			|	Links.Stage = &ProductionStage
			|	AND Links.KeyLot IN (&KeyLot, &EmptyLinkKey)");
	EndIf;
	
	BatchQueryText.Add(
		InformationRegisters.ScheduleOfProductionStages2_2.QueryTextTTTermsOfStages(
			"TTStages",
			"ProductionStage"));
	
	BatchQueryText.Add(
		"SELECT
		|	Stages.ProductionStage AS ProductionStage,
		|	Stages.KeyLot AS KeyLot,
		|	&PresentationStage AS PresentationStage,
		|	ISNULL(Deadlines.StageStart, DATETIME(1, 1, 1)) AS StageStart,
		|	ISNULL(Deadlines.StageEnd, DATETIME(1, 1, 1)) AS StageEnd
		|FROM
		|	TTStages AS Stages
		|		LEFT JOIN TTTermsOfStages AS Deadlines
		|		ON Stages.ProductionStage = Deadlines.ProductionStage
		|		 AND Stages.KeyLot = Deadlines.KeyLot
		|
		|ORDER BY
		|	StageStart,
		|	StageEnd");
	
	QueryText = StrConcat(BatchQueryText, ";");
	
	QueryText = StrReplace(
		QueryText,
		"&PresentationStage",
		ProductionManagement.QueryTextPresentationStage("Stages.ProductionStage"));
	
	Query.Text = QueryText;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region Assignees

Procedure OutputPerformers(SpreadsheetDocument, Data_Stage, AppearanceTemplate, DecipheringAlternatives)
	
	DisplayTitlePerformers(SpreadsheetDocument, Data_Stage, AppearanceTemplate);
	
	If ThisIsUBBVStage(Data_Stage) Then
		DisplayDivisionSchedule(SpreadsheetDocument, Data_Stage, AppearanceTemplate);
	Else
		For Each Performer In Data_Stage.Assignees Do
			If Not Performer.AlternateType Then
				OutputArtist(SpreadsheetDocument, Data_Stage, Performer, AppearanceTemplate, DecipheringAlternatives);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure DisplayTitlePerformers(SpreadsheetDocument, Data_Stage, AppearanceTemplate)
	
	HeaderArea_ = AppearanceTemplate.GetArea("AvailabilityOfTypesOfWorkCenters");
	
	If ThisIsUBBVStage(Data_Stage) Then
		TitlePerformers = NStr("vi = 'Bộ phận sẵn có';
								|ru = 'Доступность подразделения';
								|en = 'Shop floor capacity'; fa = 'Shop floor capacity';
								|it = 'Disponibilità di reparto';
								|pl = 'Dostępność działu';
								|tr = 'Üretim atölyesi kapasitesi'");
	Else
		TitlePerformers = NStr("vi = 'Mức độ khả dụng của các dạng nguồn lực sản xuất';
								|ru = 'Доступность видов рабочих центров';
								|en = 'Capacity of work center types'; fa = 'ظرفیت انواع مرکز کاری';
								|it = 'Disponibilità dei tipi di centri di lavoro';
								|pl = 'Dostępność typów stanowisk pracy';
								|tr = 'İş merkezi türleri kapasitesi'");
	EndIf;
	
	HeaderArea_.Parameters.TitlePerformers = TitlePerformers;
	
	SpreadsheetDocument.Put(HeaderArea_);
	
EndProcedure

Procedure DisplayDivisionSchedule(SpreadsheetDocument, Data_Stage, AppearanceTemplate)
	
	// Header output.
	HeaderArea_ = AppearanceTemplate.GetArea("Performer");
	HeaderArea_.Parameters.Performer = Data_Stage.Department;
	HeaderArea_.Parameters.Required2 = GetTimeByString(
		Data_Stage.StageDuration, Data_Stage.UnitOfMeasureOfStageDuration);
	SpreadsheetDocument.Put(HeaderArea_);
	
	// Schedule output.
	PerformerAreaNoAvailability = AppearanceTemplate.GetArea("PerformerData");
	PerformerAreaHasAccessibility = AppearanceTemplate.GetArea("PersonalDataWithoutAvailabilityRestriction");
	
	DesignFeatures = OtherPerformers(AppearanceTemplate);
	
	Schedule = DivisionSchedule(Data_Stage);
	
	For IndexOf = 0 To Data_Stage.Intervals.Count()-1 Do
		Interval = Data_Stage.Intervals[IndexOf]; // ValueTableRow
		Begin = Interval.Begin;
		Ending = Interval.Ending;
		
		IntervalBusy = False;
		
		If Schedule.Find(Begin, "ScheduleDate") = Undefined Then
			
			AreaData = PerformerAreaNoAvailability;
			
			SetAreaLayout(
				AreaData.Areas.PerformerData,
				DesignFeatures.IntervalUnavailable);
			
		Else
			
			AreaData = PerformerAreaHasAccessibility;
			
			If (Data_Stage.StageStart >= Begin And Data_Stage.StageStart < Ending)
				Or (Begin >= Data_Stage.StageStart And Begin < Data_Stage.StageEnd) Then
				
				Appearance = DesignFeatures.IntervalIsOccupiedByDiagnosedStage;
				IntervalBusy = True;
				
			Else
				
				Appearance = DesignFeatures.IntervalAvailable;
				
			EndIf;
			
			SetAreaLayout(
				AreaData.Areas.PersonalDataWithoutAvailabilityRestriction,
				Appearance);
			
		EndIf;
		
		AddedArea = SpreadsheetDocument.Join(AreaData);
		
		If IntervalBusy Then
			FillStageBoundaries(Data_Stage, AddedArea);
		EndIf;
		
	EndDo;
	
EndProcedure

Function DivisionSchedule(Data_Stage)
	
	If Data_Stage.ProductionByThirdParty Then
		
		Schedules = New ValueTable;
		Schedules.Columns.Add("WorkScheduleCalendar", New TypeDescription("Number", New NumberQualifiers));
		Schedules.Columns.Add("WorkScheduleLink", New TypeDescription("CatalogRef.Calendars"));
		
		NewRow = Schedules.Add();
		NewRow.WorkScheduleCalendar = 1;
		NewRow.WorkScheduleLink = Constants.MainEnterpriseCalendar.Get();
	
	Else
		
		TempTablesManager = New TempTablesManager;
		ProductionServer.CreateTTDivisionSchedules(
			Data_Stage.Department, TempTablesManager, "TTWorkSchedules_");
		
		Query = New Query(
			"SELECT
			|	&WorkScheduleCalendar                AS WorkScheduleCalendar,
			|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleLink
			|FROM
			|	TTWorkSchedules_ AS TTWorkSchedules_");
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("WorkScheduleCalendar", 1);
		Schedules = Query.Execute().Unload();
		
	EndIf;
	
	Result = DataProcessors.ProductionSchedulePlanning2_2.UbbwSchedule(
		Schedules, Data_Stage.FullIntervalStart, Data_Stage.FullIntervalEnding);
	
	Result.Indexes.Add("ScheduleDate");
	
	Return Result;
	
EndFunction

Function BBVSchedule(Data_Stage, Assignees)
	
	Parameters = New Structure;
	Parameters.Insert("StagePerformers_", Assignees);
	Parameters.Insert("BBVSchedule", Undefined);
	
	DataProcessors.ProductionSchedulePlanning2_2.ReadBBVSchedule(
		Parameters,
		Data_Stage.FullIntervalStart,
		Data_Stage.FullIntervalEnding);
	
	Return Parameters.BBVSchedule;
	
EndFunction

Function LoadingVRCWithoutRestrictions(Data_Stage, References)
	
	If Data_Stage.ScheduleStatus = StatusWorkingSchedule() Then
		
		QueryText = 
		"SELECT
		|	AvailabilityOfWorkCenterTypes.WorkCenterType,
		|	AvailabilityOfWorkCenterTypes.IntervalDate,
		|	SUM(AvailabilityOfWorkCenterTypes.Busy) AS OccupiedByCur
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
		|	
		|	LEFT JOIN Catalog.WorkCenterTypes AS TypesOfRC
		|	ON AvailabilityOfWorkCenterTypes.WorkCenterType = TypesOfRC.Ref
		|
		|WHERE
		|	AvailabilityOfWorkCenterTypes.WorkCenterType IN (&WorkCenterTypes)
		|	AND (IntervalDate BETWEEN &Begin AND &Ending)
		|	AND AvailabilityOfWorkCenterTypes.ReferenceOrder = &ReferenceOrder
		|	AND AvailabilityOfWorkCenterTypes.Stage = &Stage
		|	AND (VALUETYPE(AvailabilityOfWorkCenterTypes.Stage) = TYPE(Document.ProductionStage2_2)
		|	OR AvailabilityOfWorkCenterTypes.KeyLot = &KeyLot)
		|
		|GROUP BY
		|	AvailabilityOfWorkCenterTypes.WorkCenterType,
		|	AvailabilityOfWorkCenterTypes.IntervalDate,
		|	TypesOfRC.ParallelLoad,
		|	TypesOfRC.MaximumLoad";
		
	Else
		
		QueryText =
		"SELECT
		|	CreatingScheduleForWorkCenterTypes.WorkCenterType,
		|	CreatingScheduleForWorkCenterTypes.IntervalDate,
		|	SUM(CASE
		|			WHEN CreatingScheduleForWorkCenterTypes.Stage = &Stage
		|				THEN CreatingScheduleForWorkCenterTypes.Busy
		|			ELSE 0
		|		END)
		|FROM
		|	InformationRegister.CreatingScheduleForWorkCenterTypes AS CreatingScheduleForWorkCenterTypes
		|	
		|	LEFT JOIN Catalog.WorkCenterTypes AS TypesOfRC
		|	ON CreatingScheduleForWorkCenterTypes.WorkCenterType = TypesOfRC.Ref
		|
		|WHERE
		|	CreatingScheduleForWorkCenterTypes.ScheduleStatus = &ScheduleStatus
		|	AND CreatingScheduleForWorkCenterTypes.WorkCenterType IN(&WorkCenterTypes)
		|	AND CreatingScheduleForWorkCenterTypes.IntervalDate BETWEEN &Begin AND &Ending
		|
		|GROUP BY
		|	CreatingScheduleForWorkCenterTypes.WorkCenterType,
		|	CreatingScheduleForWorkCenterTypes.IntervalDate,
		|	TypesOfRC.ParallelLoad,
		|	TypesOfRC.MaximumLoad";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("ScheduleStatus", Data_Stage.ScheduleStatus);
	Query.SetParameter("ReferenceOrder", Data_Stage.ReferenceOrder);
	Query.SetParameter("WorkCenterTypes", References);
	Query.SetParameter("Begin", Data_Stage.FullIntervalStart);
	Query.SetParameter("Ending", Data_Stage.FullIntervalEnding);
	Query.SetParameter("Stage", Data_Stage.Stage);
	Query.SetParameter("KeyLot", Data_Stage.KeyLot);
	
	Result = Query.Execute().Unload();
	Result.Indexes.Add("WorkCenterType, IntervalDate");
	
	Return Result;
	
EndFunction

Function WCKAvailability(Data_Stage, References)
	
	TempTablesManager = New TempTablesManager;
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("ReferenceOrder", Data_Stage.ReferenceOrder);
	Query.SetParameter("Stage", Data_Stage.Stage);
	Query.SetParameter("ScheduleStatus", Data_Stage.ScheduleStatus);
	Query.SetParameter("KeyLot", Data_Stage.KeyLot);
	
	ArrayOfStages = New Array;
	CreateTTUploadOrderAndFillInExclusionSteps(Data_Stage, Query, ArrayOfStages);
	
	Parameters = New Structure("Queue, PriorityNumber, DivisionNumber");
	FillPropertyValues(Parameters, Data_Stage);
	Parameters.Insert("ProductionOrder", Data_Stage.ReferenceOrder);
	Parameters.Insert("GoBackToBeginning", False);
	Parameters.Insert("NoOtherOrders", False);
	Parameters.Insert("CancelManualChangesOfSchedule", False);
	Parameters.Insert("RoundTheClockWorkSevenDaysAWeek", False);
	Parameters.Insert("KeyLot", Data_Stage.KeyLot);
	
	DataProcessors.ProductionSchedulePlanning2_2.CreateTTAvailabilityOfRCTypes(
		TempTablesManager,
		"TTAvailability",
		References,
		ArrayOfStages,
		Data_Stage.FullIntervalStart, 
		Data_Stage.FullIntervalEnding,
		Parameters);
	
	QueryText = 
	"SELECT
	|	TTAvailability.Performer AS WorkCenterType,
	|	TTAvailability.IntervalDate,
	|	ISNULL(TTLoading.OccupiedByCur, 0) AS OccupiedByCur,
	|	TTAvailability.CountExpense + ISNULL(TTLoading.OccupiedByOthers, 0) AS OccupiedByOthers,
	|	TTAvailability.CountReceipt - (ISNULL(TTLoading.OccupiedByCur, 0) + TTAvailability.CountExpense + ISNULL(TTLoading.OccupiedByOthers, 0)) AS FreeWithReserve,
	|	TTAvailability.CountReceipt AS CommonAvailability,
	|	CAST(&Reserve AS NUMBER(15, 0)) AS GeneralReserve,
	|	&AvailableForCurWithReserve AS AvailableForCurWithReserve,
	|	CASE
	|		WHEN NOT TTAvailability.AvailabilityReserve = 0
	|			THEN CASE
	|					WHEN &Reserve <= &AvailableForCurWithReserve
	|						THEN CAST(&Reserve AS NUMBER(15, 0))
	|					ELSE &AvailableForCurWithReserve
	|				END
	|		ELSE 0
	|	END AS ReserveAvailableForCur
	|FROM
	|	TTAvailability AS TTAvailability
	|		LEFT JOIN TTLoading AS TTLoading
	|		ON TTAvailability.Performer = TTLoading.WorkCenterType
	|			AND TTAvailability.IntervalDate = TTLoading.IntervalDate";
	
	QueryText = StrReplace(QueryText, "&AvailableForCurWithReserve",
		"TTAvailability.CountReceipt - (TTAvailability.CountExpense + ISNULL(TTLoading.OccupiedByOthers, 0))");
	
	QueryText = StrReplace(QueryText, "&Reserve",
		"TTAvailability.CountReceipt * (TTAvailability.AvailabilityReserve / 100)");
	
	Query.Text = QueryText;
	Result = Query.Execute().Unload();
	Result.Indexes.Add("WorkCenterType, IntervalDate");
	
	Return Result;
	
EndFunction

Procedure CreateTTUploadOrderAndFillInExclusionSteps(Data_Stage, Query, EliminationStages)
	
	If Data_Stage.ScheduleStatus = StatusWorkingSchedule() Then
		
		Query.Text =
		"SELECT
		|	AvailabilityOfWorkCenterTypes.WorkCenterType AS WorkCenterType,
		|	AvailabilityOfWorkCenterTypes.IntervalDate,
		|	SUM(AvailabilityOfWorkCenterTypes.Busy) AS OccupiedByCur,
		|	SUM(0) AS OccupiedByOthers
		|INTO TTLoading
		|FROM
		|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
		|
		|	LEFT JOIN Catalog.WorkCenterTypes AS TypesOfRC
		|	ON AvailabilityOfWorkCenterTypes.WorkCenterType = TypesOfRC.Ref
		|
		|WHERE
		|	AvailabilityOfWorkCenterTypes.ReferenceOrder = &ReferenceOrder
		|	AND AvailabilityOfWorkCenterTypes.Stage = &Stage
		|	AND (VALUETYPE(AvailabilityOfWorkCenterTypes.Stage) = TYPE(Document.ProductionStage2_2)
		|	OR AvailabilityOfWorkCenterTypes.KeyLot = &KeyLot)
		|
		|GROUP BY
		|	AvailabilityOfWorkCenterTypes.WorkCenterType,
		|	AvailabilityOfWorkCenterTypes.IntervalDate,
		|	TypesOfRC.ParallelLoad,
		|	TypesOfRC.MaximumLoad";
		
		Query.Execute();
		
		EliminationStages.Add(Data_Stage.Stage);
		
	Else
		
		Query.Text =
		"SELECT
		|	CreatingScheduleForWorkCenterTypes.WorkCenterType,
		|	CreatingScheduleForWorkCenterTypes.IntervalDate,
		|	CreatingScheduleForWorkCenterTypes.Stage,
		|	CreatingScheduleForWorkCenterTypes.Busy AS Busy
		|INTO TTPlanningResults
		|FROM
		|	InformationRegister.CreatingScheduleForWorkCenterTypes AS CreatingScheduleForWorkCenterTypes
		|
		|	LEFT JOIN Catalog.WorkCenterTypes AS TypesOfRC
		|	ON CreatingScheduleForWorkCenterTypes.WorkCenterType = TypesOfRC.Ref
		|
		|WHERE
		|	CreatingScheduleForWorkCenterTypes.ScheduleStatus = &ScheduleStatus
		|	AND CreatingScheduleForWorkCenterTypes.ReferenceOrder = &ReferenceOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTPlanningResults.WorkCenterType,
		|	TTPlanningResults.IntervalDate,
		|	SUM(CASE
		|			WHEN TTPlanningResults.Stage = &Stage
		|				THEN TTPlanningResults.Busy
		|			ELSE 0
		|		END) AS OccupiedByCur,
		|	SUM(CASE
		|			WHEN NOT TTPlanningResults.Stage = &Stage
		|				THEN TTPlanningResults.Busy
		|			ELSE 0
		|		END) AS OccupiedByOthers
		|INTO TTLoading
		|FROM
		|	TTPlanningResults AS TTPlanningResults
		|
		|GROUP BY
		|	TTPlanningResults.WorkCenterType,
		|	TTPlanningResults.IntervalDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TTPlanningResults.Stage
		|FROM
		|	TTPlanningResults AS TTPlanningResults";
		
		EliminationStages = Query.Execute().Unload().UnloadColumn("Stage");
		
	EndIf;
	
EndProcedure

Procedure OutputArtist(SpreadsheetDocument, Data_Stage, Performer, AppearanceTemplate, DecipheringAlternatives)
	
	DisplayArtistTitle(SpreadsheetDocument, Performer, Data_Stage, AppearanceTemplate, DecipheringAlternatives);
	
	If Performer.ConsiderAvailability Then
		DisplayAvailabilityOfServicesWithRestrictions(SpreadsheetDocument, Data_Stage, Performer, AppearanceTemplate);
	Else
		DisplayAvailabilityOfServicesWithoutRestrictions(SpreadsheetDocument, Data_Stage, Performer, AppearanceTemplate);
	EndIf;
	
	AlternativePerformers = AlternativePerformers(Performer, Data_Stage.Assignees);
	If AlternativePerformers <> Undefined Then
		For Each AlternateArtist In AlternativePerformers Do
			OutputArtist(
				SpreadsheetDocument, Data_Stage, AlternateArtist, AppearanceTemplate, DecipheringAlternatives);
		EndDo;
	EndIf;
	
EndProcedure

Procedure DisplayArtistTitle(SpreadsheetDocument, Performer, Data_Stage, AppearanceTemplate, DecipheringAlternatives)
	
	AlternativePerformers = AlternativePerformers(Performer, Data_Stage.Assignees);
	
	DisplayAlternativePerformers = TypeOf(Data_Stage.Stage) = Type("DocumentRef.ProductionStage2_2");
	
	If Performer.AlternateType And Not DisplayAlternativePerformers Then
		Return;
	EndIf;
	
	OutputUsage = DisplayAlternativePerformers
		And (Performer.AlternateType
		Or (Not AlternativePerformers = Undefined
		And Not AlternativePerformers.Count() = 0));
	
	If OutputUsage Then
		
		If Not Performer.AlternateType Then
			
			ScopeOfApplication_ = AppearanceTemplate.GetArea("Performer_Performer");
			ScopeOfApplication_.Areas.Performer_Performer.Details = Performer.WorkCenterType;
			ScopeOfUse = AppearanceTemplate.GetArea("Performer_Use");
			AreaRequired = AppearanceTemplate.GetArea("Performer_Required2");
			
		Else
			
			ScopeOfApplication_ = AppearanceTemplate.GetArea("PerformerAlternative_Performer");
			ScopeOfApplication_.Areas.PerformerAlternative_Performer.Details = Performer.WorkCenterType;
			ScopeOfUse = AppearanceTemplate.GetArea("PerformerAlternative_Usage");
			AreaRequired = AppearanceTemplate.GetArea("AlternativeExecutor_Required");
		
		EndIf;
		
	Else
		
		ScopeOfApplication_ = AppearanceTemplate.GetArea("Performer");
		ScopeOfApplication_.Areas.Performer.Details = Performer.WorkCenterType;
		AreaRequired = ScopeOfApplication_;
		
	EndIf;
	
	Required2 = 0;
	WorkCenterType = "";
	If Performer.ParallelLoad Then
		Required2 = StrTemplate("%1 %2", Performer.Load, Performer.UnitOfMeasureOfLoad);
		WorkCenterType = StrTemplate("%1, %%", Performer.WorkCenterType);
	Else
		WorkCenterType = Performer.WorkCenterType;
		TimeInSeconds = GetTimeInSeconds(Performer.OperationTime, Performer.UnitOfMeasure);
		Required2 = GetTimeByString(TimeInSeconds);
	EndIf;
	
	ScopeOfApplication_.Parameters.Performer = WorkCenterType;
	
	AreaRequired.Parameters.Required2 = Required2;
	
	If OutputUsage Then
		
		SpreadsheetDocument.Put(ScopeOfApplication_);
		
		If Not Performer.AlternateType Then
			ScopeOfUse.Areas.Performer_Use.Text = NStr("vi = 'hiển thị thay thế';
														|ru = 'показать альтернативы';
														|en = 'show alternatives'; fa = 'show alternatives';
														|it = 'visualizzare alternative';
														|pl = 'pokaż alternatywy';
														|tr = 'alternatifleri göster'");
			ScopeOfUse.Areas.Performer_Use.Hyperlink = True;
			ScopeOfUse.Areas.Performer_Use.Font = New Font(,,,, True);
		Else
			ScopeOfUse.Areas.PerformerAlternative_Usage.Text = NStr("vi = 'sử dụng';
																	|ru = 'использовать';
																	|en = 'use'; fa = 'use';
																	|it = 'utilizza';
																	|pl = 'use';
																	|tr = 'kullan'");
			ScopeOfUse.Areas.PerformerAlternative_Usage.Hyperlink = True;
			ScopeOfUse.Areas.PerformerAlternative_Usage.Font = New Font(,,,, True);
		EndIf;
		
		AddedArea = SpreadsheetDocument.Join(ScopeOfUse);
		
		If Not Performer.AlternateType Then
			DecryptionOfSignature = New Structure;
			DecryptionOfSignature.Insert("AreaView", "ManagingVisibilityOfAlternativeRCViews");
			DecryptionOfSignature.Insert("WorkCenterType", Performer.WorkCenterType);
			DecryptionOfSignature.Insert("ConnectionKey", Performer.ConnectionKey);
			DecryptionOfSignature.Insert("NumberOfAlternatives", AlternativePerformers.Count());
			DecryptionOfSignature.Insert("TableHeight", SpreadsheetDocument.TableHeight);
			DecryptionOfSignature.Insert("Left", AddedArea.Left);
			DecryptionOfSignature.Insert("Top", AddedArea.Top);
			AddedArea.Details = DecryptionOfSignature;
			
			DecipheringAlternatives.Add(DecryptionOfSignature);
		Else
			DecryptionAlternativeArtist = New Structure;
			DecryptionAlternativeArtist.Insert("AreaView", "UseRCView");
			DecryptionAlternativeArtist.Insert("WorkCenterType", Performer.WorkCenterType);
			DecryptionAlternativeArtist.Insert("ConnectionKey", ?(ValueIsFilled(Performer.KeyArray),
																							Performer.KeyArray,
																							Performer.ConnectionKey));
			AddedArea.Details = DecryptionAlternativeArtist;
		EndIf;
		
		AddedArea = SpreadsheetDocument.Join(AreaRequired);
		
	Else
		
		SpreadsheetDocument.Put(ScopeOfApplication_);
		
	EndIf;
	
EndProcedure

Function AlternativePerformers(Performer, Assignees)
	
	Result = Assignees.CopyColumns();
	
	For Each Var_Key In Performer.KeyArray Do
		If Not Performer.AlternateType Then
			TheStructureOfTheSearch = New Structure("ConnectionKey, AlternateType", Var_Key, True);
			SearchResult = Assignees.FindRows(TheStructureOfTheSearch);
			For Each VRC In SearchResult Do
				String = Result.Add();
				FillPropertyValues(String, VRC);
			EndDo;
		EndIf;
	EndDo;
	
	Return CollapsePerformers(Result, True);
	
EndFunction

Procedure DisplayAvailabilityOfServicesWithRestrictions(SpreadsheetDocument, Data_Stage, Performer, AppearanceTemplate)
	
	ScopeOfApplication_ = AppearanceTemplate.GetArea("PerformerData");
	DesignFeatures = OtherPerformers(AppearanceTemplate);
	
	TheStructureOfTheSearch = New Structure("WorkCenterType, IntervalDate", Performer.WorkCenterType);
	BlankValues = New Structure("CommonAvailability, AvailableForCur, OccupiedByCur", "", "", "");
	
	For IndexOf = 0 To Data_Stage.Intervals.Count()-1 Do
		Interval = Data_Stage.Intervals[IndexOf]; // ValueTableRow
		IntervalDate = Interval.Begin;
		
		TheStructureOfTheSearch.IntervalDate = IntervalDate;
		FoundRows = Data_Stage.WCKAvailability.FindRows(TheStructureOfTheSearch);
		
		IntervalBusy = False;
		
		If FoundRows.Count() = 0 Then
			
			FillPropertyValues(ScopeOfApplication_.Parameters, BlankValues);
			Appearance = DesignFeatures.IntervalUnavailable;
			
		Else
			
			FillingValues = FoundRows[0];
			
			If Performer.ParallelLoad And FillingValues.CommonAvailability > 0 Then
				
				If FillingValues.GeneralReserve > 0 Then
					
					AvailableWithoutReserve = (FillingValues.CommonAvailability - FillingValues.GeneralReserve)
										/ FillingValues.CommonAvailability * 100;
					Reserve = FillingValues.GeneralReserve / FillingValues.CommonAvailability * 100;
					CommonAvailability = Format(AvailableWithoutReserve, "NFD=2;")
						+ " (+"
						+ Format(Reserve, "NFD=2;")
						+ ")";
					
				Else
					CommonAvailability = 100;
				EndIf;
				
				If FillingValues.ReserveAvailableForCur > 0 Then
					
					AvailableForCurWithoutReserve = (FillingValues.AvailableForCurWithReserve
						- FillingValues.ReserveAvailableForCur) / FillingValues.CommonAvailability * 100;
					ReserveForCurrent = FillingValues.ReserveAvailableForCur
										/ FillingValues.CommonAvailability * 100;
					AvailableForCur = Format(AvailableForCurWithoutReserve, "NFD=2;")
						+ " (+"
						+ Format(ReserveForCurrent, "NFD=2;")
						+ ")";
						
				Else
					AvailableForCur = Format(FillingValues.AvailableForCurWithReserve
												/ FillingValues.CommonAvailability * 100, "NFD=2;");
				EndIf;
				
				OccupiedByCur = Format(FillingValues.OccupiedByCur
										/ FillingValues.CommonAvailability * 100, "NFD=2;");
			Else
				
				If FillingValues.GeneralReserve > 0 Then
					
					AvailableWithoutReserve = FillingValues.CommonAvailability - FillingValues.GeneralReserve;
					CommonAvailability = GetTimeByString(AvailableWithoutReserve)
						+ " (+"
						+ GetTimeByString(FillingValues.GeneralReserve)
						+ ")";
					
				Else
					CommonAvailability = GetTimeByString(FillingValues.CommonAvailability);
				EndIf;
				
				If FillingValues.ReserveAvailableForCur > 0 Then
					
					AvailableForCurWithoutReserve = FillingValues.AvailableForCurWithReserve
						- FillingValues.ReserveAvailableForCur;
					AvailableForCur = GetTimeByString(AvailableForCurWithoutReserve)
						+ " (+"
						+ GetTimeByString(FillingValues.ReserveAvailableForCur)
						+ ")";
						
				Else
					AvailableForCur = GetTimeByString(FillingValues.AvailableForCurWithReserve);
				EndIf;
				
				OccupiedByCur = GetTimeByString(FillingValues.OccupiedByCur);
				
			EndIf;
			
			ScopeOfApplication_.Parameters.CommonAvailability = CommonAvailability;
			ScopeOfApplication_.Parameters.AvailableForCur = AvailableForCur;
			ScopeOfApplication_.Parameters.OccupiedByCur = OccupiedByCur;
			
			If FillingValues.FreeWithReserve < 0 Then
				Appearance = DesignFeatures.IntervalOverloaded;
			ElsIf FillingValues.OccupiedByCur > 0 Then
				Appearance = DesignFeatures.IntervalIsOccupiedByDiagnosedStage;
			ElsIf FillingValues.OccupiedByOthers > 0 And FillingValues.FreeWithReserve = 0 Then
				Appearance = DesignFeatures.IntervalBusy;
			ElsIf FillingValues.OccupiedByOthers > 0 Then
				Appearance = DesignFeatures.IntervalPartiallyAvailable;
			ElsIf FillingValues.CommonAvailability = 0 Then
				Appearance = DesignFeatures.IntervalUnavailable;
			Else
				Appearance = DesignFeatures.IntervalAvailable;
			EndIf;
			
			If FillingValues.OccupiedByCur > 0 Then
				IntervalBusy = True;
			EndIf;
			
		EndIf;
		
		SetAreaLayout(ScopeOfApplication_.Areas.PerformerData, Appearance);
		
		AddedArea = SpreadsheetDocument.Join(ScopeOfApplication_);
		
		If IntervalBusy Then
			FillStageBoundaries(Data_Stage, AddedArea);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DisplayAvailabilityOfServicesWithoutRestrictions(SpreadsheetDocument, Data_Stage, Performer, AppearanceTemplate)
	
	PerformerAreaNoAvailability = AppearanceTemplate.GetArea("PerformerData");
	PerformerAreaHasAccessibility = AppearanceTemplate.GetArea("PersonalDataWithoutAvailabilityRestriction");
	DesignFeatures = OtherPerformers(AppearanceTemplate);
	
	Enabled = Data_Stage.BBVSchedule;
	SearchStructureAccessibility = New Structure;
	SearchStructureAccessibility.Insert("WorkScheduleCalendar", Performer.WorkScheduleCalendar);
	
	Load = Data_Stage.LoadingVRCWithoutRestrictions;
	SearchStructureLoading = New Structure("WorkCenterType, IntervalDate");
	FillPropertyValues(SearchStructureLoading, Performer);
	
	BlankValues = New Structure("OccupiedByCur", "");
	
	For IndexOf = 0 To Data_Stage.Intervals.Count()-1 Do
		Interval = Data_Stage.Intervals[IndexOf]; // ValueTableRow
		IntervalDate = Interval.Begin;
		
		SearchStructureAccessibility.Insert("IntervalDate", IntervalDate);
		FoundRows = Enabled.FindRows(SearchStructureAccessibility);
		
		IntervalBusy = False;
		
		If FoundRows.Count() = 0 Then
			
			ScopeOfApplication_ = PerformerAreaNoAvailability;
			SetAreaLayout(
				ScopeOfApplication_.Areas.PerformerData,
				DesignFeatures.IntervalUnavailable);
			
		Else
			
			ScopeOfApplication_ = PerformerAreaHasAccessibility;
			
			SearchStructureLoading.IntervalDate = IntervalDate;
			FoundStringsLoading = Load.FindRows(SearchStructureLoading);
			
			If FoundStringsLoading.Count() = 0 Then
				
				FillPropertyValues(ScopeOfApplication_.Parameters, BlankValues);
				Appearance = DesignFeatures.IntervalAvailable;
				
			Else
				
				FillingValues = FoundStringsLoading[0];
				
				If Performer.ParallelLoad Then
					OccupiedByCur = Format(FillingValues.OccupiedByCur
											/ FillingValues.CommonAvailability * 100, "NFD=2;");
				Else
					OccupiedByCur = GetTimeByString(FillingValues.OccupiedByCur);
				EndIf;
				
				ScopeOfApplication_.Parameters.OccupiedByCur = OccupiedByCur;
				
				If FillingValues.OccupiedByCur > 0 Then
					Appearance = DesignFeatures.IntervalIsOccupiedByDiagnosedStage;
					IntervalBusy = True;
				Else
					Appearance = DesignFeatures.IntervalAvailable;
				EndIf;
				
			EndIf;
			
			SetAreaLayout(
				ScopeOfApplication_.Areas.PersonalDataWithoutAvailabilityRestriction,
				Appearance);
			
		EndIf;
		
		AddedArea = SpreadsheetDocument.Join(ScopeOfApplication_);
		
		If IntervalBusy Then
			FillStageBoundaries(Data_Stage, AddedArea);
		EndIf;
		
	EndDo;
	
EndProcedure

Function OtherPerformers(AppearanceTemplate)
	
	Result = New Structure;
	
	Result.Insert("IntervalIsOccupiedByDiagnosedStage",
		AppearanceTemplate.GetArea("IntervalIsOccupiedByDiagnosedStage").Areas.IntervalIsOccupiedByDiagnosedStage);
		
	Result.Insert("IntervalBusy",
		AppearanceTemplate.GetArea("IntervalBusy").Areas.IntervalBusy);
	
	Result.Insert("IntervalUnavailable",
		AppearanceTemplate.GetArea("IntervalUnavailable").Areas.IntervalUnavailable);
	
	Result.Insert("IntervalAvailable",
		AppearanceTemplate.GetArea("IntervalAvailable").Areas.IntervalAvailable);
	
	Result.Insert("IntervalPartiallyAvailable",
		AppearanceTemplate.GetArea("IntervalPartiallyAvailable").Areas.IntervalPartiallyAvailable);
	
	Result.Insert("IntervalOverloaded",
		AppearanceTemplate.GetArea("IntervalOverloaded").Areas.IntervalOverloaded);
	
	Return Result;
	
EndFunction

Procedure FillStageBoundaries(Data_Stage, AddedArea)
	
	If ValueIsFilled(Data_Stage.LeftBorderOfStage) Then
		
		Data_Stage.LeftBorderOfStage = Min(
			Data_Stage.LeftBorderOfStage,
			AddedArea.Left);
			
	Else
		
		Data_Stage.LeftBorderOfStage = AddedArea.Left;
		
	EndIf;
	
	Data_Stage.RightStageBoundary = Max(
		Data_Stage.RightStageBoundary,
		AddedArea.Right);
	
EndProcedure

#EndRegion

#Region UsedMaterials

Procedure OutputMaterials(SpreadsheetDocument, Data_Stage, AppearanceTemplate)
	
	UsedMaterials = StageMaterials(Data_Stage);
	If UsedMaterials = Undefined Then
		Return;
	EndIf;
	
	HeaderArea_ = AppearanceTemplate.GetArea("MaterialsHeader");
	SpreadsheetDocument.Put(HeaderArea_);
	
	DesignFeatures = OtherPerformers(AppearanceTemplate);
	
	AreaMaterial       = AppearanceTemplate.GetArea("Material");
	ScopeMaterialData = AppearanceTemplate.GetArea("MaterialData_");
	
	For Each String In UsedMaterials Do
		
		AreaMaterial.Parameters.Material = ProductsClientServer.ProductPresentation(
			String.ProductsPresentation,
			String.CharacteristicPresentation,
			String.UnitOfMeasurePresentation);
		AreaMaterial.Parameters.DecryptionMaterial = String.Products;
		AreaMaterial.Parameters.Required2 = String.Count;
		
		SpreadsheetDocument.Put(AreaMaterial);
		
		For IndexOf = 0 To Data_Stage.Intervals.Count()-1 Do
			Interval = Data_Stage.Intervals[IndexOf]; // ValueTableRow
			Begin = Interval.Begin;
			
			If Begin < String.AvailabilityDate Then
				SetAreaLayout(ScopeMaterialData.Areas.MaterialData_, DesignFeatures.IntervalBusy);
			Else
				SetAreaLayout(ScopeMaterialData.Areas.MaterialData_, DesignFeatures.IntervalAvailable);
			EndIf;
			
			AddedArea = SpreadsheetDocument.Join(ScopeMaterialData);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function StageMaterials(Data_Stage)

	SetPrivilegedMode(True);

	TempTablesManager = New TempTablesManager;
	
	If Data_Stage.DynamicStructure Then
		
		ConditionsOfReceipt = New Structure;
		ConditionsOfReceipt.Insert("ProductionOrder", Data_Stage.ReferenceOrder);
		ConditionsOfReceipt.Insert("Stage", Data_Stage.Stage);
		ConditionsOfReceipt.Insert("KeyLot", Data_Stage.KeyLot);
		ProductionManagement.CreateTTConstraintsOfProductionScheduleBasedOnMaterialsDynamicStructure(
			TempTablesManager, ConditionsOfReceipt, True, False, Data_Stage.ScheduleStatus);
		
		Query = New Query(
			"SELECT
			|	UsedMaterials.Products                                AS Products,
			|	UsedMaterials.Products.Presentation                  AS ProductsPresentation,
			|	UsedMaterials.Characteristic                              AS Characteristic,
			|	UsedMaterials.Characteristic.Presentation                AS CharacteristicPresentation,
			|	CASE &PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, HOUR)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, HOUR)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, DAY)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, MONTH)
			|	END                                                 AS AvailabilityDate,
			|	DATETIME(1,1,1)                                      AS StartDateOfMove,
			|	UsedMaterials.Products.UnitOfMeasure               AS UnitOfMeasure,
			|	UsedMaterials.Products.UnitOfMeasure.Presentation AS UnitOfMeasurePresentation,
			|	SUM(UsedMaterials.ToSupply + UsedMaterials.Ordered - UsedMaterials.Replaced) AS Count
			|FROM
			|	TTProductionScheduleRestrictionsOnMaterials AS DatesOfProvision
			|		INNER JOIN InformationRegister.OrderStructure AS UsedMaterials
			|		ON DatesOfProvision.KeyLot = UsedMaterials.KeyLot
			|			AND DatesOfProvision.Stage = UsedMaterials.Stage
			|			AND DatesOfProvision.Products = UsedMaterials.Products
			|			AND DatesOfProvision.Characteristic = UsedMaterials.Characteristic
			|WHERE
			|	DatesOfProvision.AvailabilityDate > &FullIntervalStart
			|
			|GROUP BY
			|	UsedMaterials.Products,
			|	UsedMaterials.Characteristic,
			|	UsedMaterials.Products.Presentation,
			|	UsedMaterials.Characteristic.Presentation,
			|	DatesOfProvision.AvailabilityDate
			|
			|ORDER BY
			|	AvailabilityDate DESC,
			|	Products");
		Query.SetParameter("FullIntervalStart", Data_Stage.FullIntervalStart);
		Query.SetParameter("PlanningInterval", Data_Stage.PlanningInterval);
		
	Else
		
		ProductionManagement.CreateTTProductionScheduleConstraintsOnMaterials(
			TempTablesManager, CommonClientServer.ValueInArray(Data_Stage.Stage), True, False);
			
		Query = New Query(
			"SELECT
			|	UsedMaterials.Products                 AS Products,
			|	UsedMaterials.Products.Presentation   AS ProductsPresentation,
			|	UsedMaterials.Characteristic               AS Characteristic,
			|	UsedMaterials.Characteristic.Presentation AS CharacteristicPresentation,
			|	CASE &PlanningInterval
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, HOUR)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, HOUR)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, DAY)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, WEEK)
			|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
			|			THEN BEGINOFPERIOD(DatesOfProvision.AvailabilityDate, MONTH)
			|	END                                  AS AvailabilityDate,
			|	DATETIME(1,1,1)                       AS StartDateOfMove,
			|	&QueryTextUnitOfMeasure          AS UnitOfMeasure,
			|	&QueryTextPresentation             AS UnitOfMeasurePresentation,
			|	SUM(CASE
			|			WHEN &DisplayBasicUnitsOfMeasureInPrintForms
			|				THEN UsedMaterials.Count
			|			ELSE UsedMaterials.NumberOfPackages
			|		END)                                 AS Count
			|FROM
			|	TTProductionScheduleRestrictionsOnMaterials AS DatesOfProvision
			|		INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS UsedMaterials
			|		ON DatesOfProvision.ProductionStage = UsedMaterials.Ref
			|			AND DatesOfProvision.Products = UsedMaterials.Products
			|			AND DatesOfProvision.Characteristic = UsedMaterials.Characteristic
			|			AND NOT UsedMaterials.Canceled
			|
			|GROUP BY
			|	UsedMaterials.Products,
			|	UsedMaterials.Characteristic,
			|	UsedMaterials.Products.Presentation,
			|	UsedMaterials.Characteristic.Presentation,
			|	DatesOfProvision.AvailabilityDate,
			|	&QueryTextUnitOfMeasure,
			|	&QueryTextPresentation
			|
			|ORDER BY
			|	AvailabilityDate DESC,
			|	Products");
		
		Query.Text = StrReplace(
			Query.Text,
			"&QueryTextUnitOfMeasure",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
				"Ref",
				"UsedMaterials.Package",
				"UsedMaterials.Products"));
			
		Query.Text = StrReplace(
			Query.Text,
			"&QueryTextPresentation",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
				"Description",
				"UsedMaterials.Package",
				"UsedMaterials.Products"));
			
		Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms", Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
		Query.SetParameter("PlanningInterval", Data_Stage.PlanningInterval);
	
	EndIf;
	
	Query.TempTablesManager = TempTablesManager;
	
	QueryResult = Query.Execute();
	
	Return ?(QueryResult.IsEmpty(), Undefined, QueryResult.Unload());
	
EndFunction

#EndRegion

#Region OtherRestrictions

Procedure OutputLeftBorder(SpreadsheetDocument, Data_Stage, AppearanceTemplate)
	
	If Not ValueIsFilled(Data_Stage.PlanNotEarlierThan) Then
		Return;
	EndIf;
	
	HeaderArea_ = AppearanceTemplate.GetArea("PlanNotEarlierThan");
	SpreadsheetDocument.Put(HeaderArea_);
	
	ScheduleDateFormat = ProductionManagement.FormatStringForProductionScheduleDate();
	TextShouldNotBePlannedEarlier = Format(Data_Stage.PlanNotEarlierThan, ScheduleDateFormat);
	
	AreaStage = AppearanceTemplate.GetArea("Stage");
	AreaStage.Parameters.ProductionStage   = Data_Stage.Stage;
	AreaStage.Parameters.PresentationStage = TextShouldNotBePlannedEarlier;
	SpreadsheetDocument.Put(AreaStage);
	
	DesignFeatures = OtherPerformers(AppearanceTemplate);
	ScopeStageData = AppearanceTemplate.GetArea("StageData_");
	
	For IndexOf = 0 To Data_Stage.Intervals.Count()-1 Do
		Interval = Data_Stage.Intervals[IndexOf]; // ValueTableRow
		Begin = Interval.Begin;
		
		If Begin < Data_Stage.PlanNotEarlierThan Then
			SetAreaLayout(ScopeStageData.Areas.StageData_, DesignFeatures.IntervalBusy);
		Else
			SetAreaLayout(ScopeStageData.Areas.StageData_, DesignFeatures.IntervalAvailable);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function Data_Stage(Stage, ScheduleStatus, KeyLot)
	
	// Stage Details
	QueryText = 
		"SELECT
		|	ProductionSchedule.ProductionOrder AS ReferenceOrder,
		|	ProductionSchedule.Stage AS Stage,
		|	ProductionSchedule.BillOfMaterials AS BillOfMaterials,
		|	CASE
		|		WHEN VALUETYPE(ProductionSchedule.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN ProductionSchedule.Stage.DynamicStructure
		|		ELSE TRUE
		|	END AS DynamicStructure,
		|	CASE
		|		WHEN VALUETYPE(ProductionSchedule.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN &PresentationStage
		|		ELSE ProductionSchedule.Stage.Description
		|	END AS PresentationStage,
		|	ProductionSchedule.Stage.Department AS Department,
		|	CASE
		|		WHEN NOT ProductionSchedule.Stage.PlanOperationsOfWorkCenterTypes
		|			OR ProductionSchedule.Stage.ProductionByThirdParty
		|			THEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|		ELSE ProductionSchedule.Stage.Department.PlanningInterval
		|	END AS PlanningInterval,
		|	CASE
		|		WHEN VALUETYPE(ProductionSchedule.Stage) = TYPE(Document.ProductionStage2_2)
		|				AND VALUETYPE(ProductionSchedule.Stage.PlanNotEarlierThan) = TYPE(DATE)
		|			THEN ProductionSchedule.Stage.PlanNotEarlierThan
		|		ELSE DATETIME(1, 1, 1)
		|	END AS PlanNotEarlierThan,
		|	ProductionSchedule.Begin AS StageStart,
		|	ProductionSchedule.Ending AS StageEnd,
		|	CASE
		|		WHEN VALUETYPE(ProductionSchedule.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN ProductionSchedule.Stage.StageName
		|		ELSE ProductionSchedule.Stage.Description
		|	END AS StageName,
		|	CASE
		|		WHEN VALUETYPE(ProductionSchedule.Stage) = TYPE(Document.ProductionStage2_2)
		|			THEN ProductionSchedule.Stage.Number
		|		ELSE ProductionSchedule.Stage.StageNumber
		|	END AS StageNumber,
		|	ProductionSchedule.Stage.PlanOperationsOfWorkCenterTypes AS PlanOperationsOfWorkCenterTypes,
		|	ProductionSchedule.Stage.ProductionByThirdParty AS ProductionByThirdParty,
		|	ProductionSchedule.ProductionOrder.Queue AS Queue,
		|	ProductionSchedule.ProductionOrder.Priority.AddlOrderingAttribute AS PriorityNumber,
		|	ProductionSchedule.ProductionOrder.Department.AddlOrderingAttribute AS DivisionNumber,
		|	ProductionSchedule.Stage.StageDuration AS StageDuration,
		|	CASE
		|		WHEN ProductionSchedule.Stage.UnitOfMeasureOfStageDuration = VALUE(Enum.TimeMeasureUnits.EmptyRef)
		|			THEN &TheBasicUnitOfTimeForTheDurationOfTheUBBWStage
		|		ELSE ProductionSchedule.Stage.UnitOfMeasureOfStageDuration
		|	END AS UnitOfMeasureOfStageDuration,
		|	CASE
		|		WHEN NOT ProductionSchedule.ProductionScheduling = VALUE(Enum.WayOfLinkingProductionOperations.ToFinish)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS GoBackToBeginning,
		|	ProductionSchedule.QuantityOfBatches AS QuantityOfBatches,
		|	&ScheduleStatus AS ScheduleStatus,
		|	ProductionSchedule.KeyLot AS KeyLot
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS ProductionSchedule
		|WHERE
		|	ProductionSchedule.Stage = &Stage
		|	AND ProductionSchedule.ScheduleStatus = &ScheduleStatus
		|	AND (VALUETYPE(ProductionSchedule.Stage) = TYPE(Document.ProductionStage2_2)
		|	OR ProductionSchedule.KeyLot = &KeyLot)";
		
	QueryText = StrReplace(
		QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("ProductionSchedule.Stage"));
	
	Query = New Query(QueryText);
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("ScheduleStatus", ScheduleStatus);
	Query.SetParameter("KeyLot", KeyLot);
	Query.SetParameter("TheBasicUnitOfTimeForTheDurationOfTheUBBWStage",
		Catalogs.ProductionStages.TheBasicUnitOfTimeForTheDurationOfTheUBBWStage());
	
	QueryResult = Query.Execute().Unload();
	
	If QueryResult.Count() <> 1 Then
		Return Undefined;
	EndIf;
	
	FillingValues = QueryResult[0];
	
	Data_Stage = New Structure;
	For Each Column In QueryResult.Columns Do
		Data_Stage.Insert(Column.Name, FillingValues[Column.Name]);
	EndDo;
	
	Data_Stage.Insert("LeftBorderOfStage", 0);
	Data_Stage.Insert("RightStageBoundary", 0);
	
	// Full Interval
	FullIntervalStart = '00010101';
	FullIntervalEnding = '00010101';
	
	If Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		FullIntervalStart = BegOfDay(Data_Stage.StageStart) - 86400;
		FullIntervalEnding = EndOfDay(Data_Stage.StageEnd) + 86400;
	ElsIf Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		FullIntervalStart = BegOfDay(Data_Stage.StageStart) - (86400 * 4);
		FullIntervalEnding = EndOfDay(Data_Stage.StageEnd) + (86400 * 4);
	ElsIf Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		FullIntervalStart = BegOfWeek(Data_Stage.StageStart) - (86400 * 7);
		FullIntervalEnding = EndOfWeek(Data_Stage.StageEnd) + (86400 * 7);
	ElsIf Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		FullIntervalStart = BegOfWeek(Data_Stage.StageStart) - (86400 * 7);
		FullIntervalEnding = EndOfWeek(Data_Stage.StageEnd) + (86400 * 7);
	ElsIf Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		FullIntervalStart = BegOfMonth(BegOfMonth(Data_Stage.StageStart) - 1);
		FullIntervalEnding = EndOfMonth(EndOfMonth(Data_Stage.StageEnd) + 1);
	EndIf;
	
	Data_Stage.Insert("FullIntervalStart", FullIntervalStart);
	Data_Stage.Insert("FullIntervalEnding", FullIntervalEnding);
	
	Data_Stage.Insert("Assignees", Undefined);
	Data_Stage.Insert("BBVSchedule", Undefined);
	Data_Stage.Insert("LoadingVRCWithoutRestrictions", Undefined);
	Data_Stage.Insert("WCKAvailability", Undefined);
	
	ShiftSchedules = New Array;
	
	If Not ThisIsUBBVStage(Data_Stage) Then
		// Assignees
		QueryText = 
			"SELECT
			|	TypesOfRC.WorkCenterType AS WorkCenterType,
			|	TypesOfRC.OperationTime AS OperationTime,
			|	TypesOfRC.UnitOfMeasure AS UnitOfMeasure,
			|	TypesOfRC.Load AS Load,
			|	TypesOfRC.WorkCenterType.UnitOfMeasureOfLoad AS UnitOfMeasureOfLoad,
			|	TypesOfRC.WorkCenterType.ParallelLoad AS ParallelLoad,
			|	TypesOfRC.ConnectionKey AS ConnectionKey,
			|	NOT TypesOfRC.Use AS AlternateType,
			|	TypesOfRC.LineNumber AS LineNumber,
			|	TypesOfRC.WorkCenterType.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
			|	TypesOfRC.Ref.Department.PlanningInterval AS PlanningInterval,
			|	0 AS WorkScheduleCalendar,
			|	FALSE AS ThereIsCalculationAccordingToFormula
			|FROM
			|	Document.ProductionStage2_2.WorkCenterTypes AS TypesOfRC
			|WHERE
			|	TypesOfRC.Ref = &Stage
			|
			|UNION ALL
			|
			|SELECT
			|	AlternativeTypesOfRC.WorkCenterType AS WorkCenterType,
			|	AlternativeTypesOfRC.OperationTime AS OperationTime,
			|	AlternativeTypesOfRC.UnitOfMeasure AS UnitOfMeasure,
			|	AlternativeTypesOfRC.Load AS Load,
			|	AlternativeTypesOfRC.WorkCenterType.UnitOfMeasureOfLoad AS UnitOfMeasureOfLoad,
			|	AlternativeTypesOfRC.WorkCenterType.ParallelLoad AS ParallelLoad,
			|	AlternativeTypesOfRC.LinkKeyWorkCenterTypes AS ConnectionKey,
			|	NOT AlternativeTypesOfRC.Use AS AlternateType,
			|	ISNULL(TypesOfRC.LineNumber, 0) AS LineNumber,
			|	AlternativeTypesOfRC.WorkCenterType.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
			|	AlternativeTypesOfRC.Ref.Department.PlanningInterval AS PlanningInterval,
			|	0 AS WorkScheduleCalendar,
			|	FALSE AS ThereIsCalculationAccordingToFormula
			|FROM
			|	Document.ProductionStage2_2.AlternateWorkCenterTypes AS AlternativeTypesOfRC
			|	
			|	LEFT JOIN Document.ProductionStage2_2.WorkCenterTypes AS TypesOfRC
			|	ON AlternativeTypesOfRC.Ref = TypesOfRC.Ref
			|		AND AlternativeTypesOfRC.LinkKeyWorkCenterTypes = TypesOfRC.ConnectionKey
			|WHERE
			|	AlternativeTypesOfRC.Ref = &Stage
			|
			|UNION ALL
			|
			|SELECT
			|	TypesOfRC.WorkCenterType AS WorkCenterType,
			|	CASE
			|		WHEN TypesOfRC.WorkCenterType.ParallelLoad THEN
			|			
			|			0
			|		
			|		WHEN Stages.QuantityOfProductUnitsLotsProducedSimultaneously <> 0
			|				AND Stages.Owner.ProductionIssueByCustomPortions THEN
			|			
			|			CASE
			|				WHEN INT(&QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously)
			|					= &QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously
			|					THEN &QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously * TypesOfRC.OperationTime
			|				ELSE (INT(&QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously) + 1) * TypesOfRC.OperationTime
			|			END
			|			
			|		WHEN Stages.QuantityOfProductUnitsLotsProducedSimultaneously <> 0
			|				AND NOT Stages.Owner.ProductionIssueByCustomPortions THEN
			|			
			|			CASE
			|				WHEN INT(ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously)
			|						= ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously
			|					THEN ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously * TypesOfRC.OperationTime
			|				ELSE (INT(ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously) + 1) * TypesOfRC.OperationTime
			|			END
			|			
			|		ELSE &QuantityOfBatches * TypesOfRC.OperationTime
			|	END AS OperationTime,
			|	TypesOfRC.UnitOfMeasure AS UnitOfMeasure,
			|	CASE
			|		WHEN TypesOfRC.WorkCenterType.ParallelLoad THEN
			|			&QuantityOfBatches * TypesOfRC.Load
			|		ELSE 0
			|	END AS Load,
			|	TypesOfRC.WorkCenterType.UnitOfMeasureOfLoad AS UnitOfMeasureOfLoad,
			|	TypesOfRC.WorkCenterType.ParallelLoad AS ParallelLoad,
			|	TypesOfRC.ConnectionKey AS ConnectionKey,
			|	FALSE AS AlternateType,
			|	TypesOfRC.LineNumber AS LineNumber,
			|	TypesOfRC.WorkCenterType.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
			|	TypesOfRC.Ref.Department.PlanningInterval AS PlanningInterval,
			|	0 AS WorkScheduleCalendar,
			|	STRINGLENGTH(TRIML(TypesOfRC.QuantityCalculationAlgorithm)) <> 0 AS ThereIsCalculationAccordingToFormula
			|FROM
			|	Catalog.ProductionStages.WorkCenterTypes AS TypesOfRC
			|
			|	INNER JOIN Catalog.ProductionStages AS Stages
			|	ON Stages.Ref = TypesOfRC.Ref
			|		AND Stages.Ref = &Stage
			|
			|	INNER JOIN Catalog.BillsOfMaterials AS Specifications
			|	ON Stages.Owner = Specifications.Ref
			|
			|UNION ALL
			|
			|SELECT
			|	AlternativeTypesOfRC.WorkCenterType AS WorkCenterType,
			|	CASE
			|		WHEN AlternativeTypesOfRC.WorkCenterType.ParallelLoad THEN
			|			
			|			0
			|		
			|		WHEN Stages.QuantityOfProductUnitsLotsProducedSimultaneously <> 0
			|				AND Stages.Owner.ProductionIssueByCustomPortions THEN
			|			
			|			CASE
			|				WHEN INT(&QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously)
			|					= &QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously
			|					THEN &QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously * AlternativeTypesOfRC.OperationTime
			|				ELSE (INT(&QueryTextNumberOfProducts / Stages.QuantityOfProductUnitsLotsProducedSimultaneously) + 1) * AlternativeTypesOfRC.OperationTime
			|			END
			|		
			|		WHEN Stages.QuantityOfProductUnitsLotsProducedSimultaneously <> 0
			|				AND NOT Stages.Owner.ProductionIssueByCustomPortions THEN
			|			
			|			CASE
			|				WHEN INT(ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously)
			|						= ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously
			|					THEN ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously * AlternativeTypesOfRC.OperationTime
			|				ELSE (INT(ISNULL(&QuantityOfBatches, 0) / Stages.QuantityOfProductUnitsLotsProducedSimultaneously) + 1) * AlternativeTypesOfRC.OperationTime
			|			END
			|			
			|		ELSE &QuantityOfBatches * AlternativeTypesOfRC.OperationTime
			|	END AS OperationTime,
			|	AlternativeTypesOfRC.UnitOfMeasure AS UnitOfMeasure,
			|	CASE
			|		WHEN AlternativeTypesOfRC.WorkCenterType.ParallelLoad THEN
			|			&QuantityOfBatches * AlternativeTypesOfRC.Load
			|		ELSE 0
			|	END AS Load,
			|	AlternativeTypesOfRC.WorkCenterType.UnitOfMeasureOfLoad AS UnitOfMeasureOfLoad,
			|	AlternativeTypesOfRC.WorkCenterType.ParallelLoad AS ParallelLoad,
			|	AlternativeTypesOfRC.LinkKeyWorkCenterTypes AS ConnectionKey,
			|	TRUE AS AlternateType,
			|	AlternativeTypesOfRC.LineNumber AS LineNumber,
			|	AlternativeTypesOfRC.WorkCenterType.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
			|	AlternativeTypesOfRC.Ref.Department.PlanningInterval AS PlanningInterval,
			|	0 AS WorkScheduleCalendar,
			|	STRINGLENGTH(TRIML(AlternativeTypesOfRC.QuantityCalculationAlgorithm)) <> 0 AS ThereIsCalculationAccordingToFormula
			|FROM
			|	Catalog.ProductionStages.AlternateWorkCenterTypes AS AlternativeTypesOfRC
			|
			|	INNER JOIN Catalog.ProductionStages AS Stages
			|	ON Stages.Ref = AlternativeTypesOfRC.Ref
			|		AND Stages.Ref = &Stage
			|
			|	INNER JOIN Catalog.BillsOfMaterials AS Specifications
			|	ON Stages.Owner = Specifications.Ref
			|WHERE
			|	AlternativeTypesOfRC.Ref = &Stage
			|
			|ORDER BY
			|	LineNumber";
		
		QueryTextNumberOfProducts =
			"&QuantityOfBatches * Specifications.MainProductNumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1)";
		QueryTextNumberOfProducts = StrReplace(QueryTextNumberOfProducts,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"Specifications.MainProductPackage",
				"Specifications.MainProductProducts"));
		QueryText = StrReplace(QueryText, "&QueryTextNumberOfProducts", QueryTextNumberOfProducts);
		
		Query.Text = QueryText;
		Query.SetParameter("QuantityOfBatches", Data_Stage.QuantityOfBatches);
		
		Assignees = Query.Execute().Unload();
		
		TheStructureOfTheSearch = New Structure("ThereIsCalculationAccordingToFormula", True);
		LinesForCalculatingFormulas = Assignees.FindRows(TheStructureOfTheSearch);
		If LinesForCalculatingFormulas.Count() > 0 Then
			QueryText = 
				"SELECT
				|	ProductsBOM.Products                    AS Products,
				|	ProductsBOM.Characteristic                  AS Characteristic,
				|	ProductsBOM.BillOfMaterials                    AS BillOfMaterials,
				|	ProductsBOM.NumberOfPackagesPerStartingLotUnit
				|		* &QuantityOfBatches
				|		* ISNULL(&QueryTextPackagingFactor, 1) AS Count
				|FROM
				|	InformationRegister.ProductsBOM AS ProductsBOM
				|WHERE
				|	ProductsBOM.BillOfMaterials = &BillOfMaterials
				|	AND ProductsBOM.Order = 1";
				
			QueryText = StrReplace(QueryText,
				"&QueryTextPackagingFactor",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"ProductsBOM.Package",
					"ProductsBOM.Products"));
			
			Query.Text = QueryText;
			Query.SetParameter("BillOfMaterials", Data_Stage.BillOfMaterials);
			Query.SetParameter("QuantityOfBatches", Data_Stage.QuantityOfBatches);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ItemData_3 = Catalogs.BillsOfMaterials.ItemData_3();
				FillPropertyValues(ItemData_3, Selection);
				SpecificationData = Catalogs.BillsOfMaterials.SpecificationDataByProducts(
					ItemData_3,
					Catalogs.BillsOfMaterials.DataSamplingParameters("WorkCenterTypes, AlternateWorkCenterTypes"),
					New Structure("Stage", Stage));
				
				For Each String In LinesForCalculatingFormulas Do
					FoundRow = ?(String.AlternateType,
						SpecificationData.AlternateWorkCenterTypes.Find(String.WorkCenterType, "WorkCenterType"),
						SpecificationData.WorkCenterTypes.Find(String.WorkCenterType, "WorkCenterType"));
					If FoundRow <> Undefined Then
						String.OperationTime = FoundRow.OperationTime;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		
		Assignees = CollapsePerformers(Assignees, False);
		Data_Stage.Insert("Assignees", Assignees);
		
		// Schedule and availability
		References = New Array;
		TheStructureOfTheSearch = New Structure("ConsiderAvailability", False);
		For Each String In Assignees.FindRows(TheStructureOfTheSearch) Do
			References.Add(String.WorkCenterType);
		EndDo;
		If References.Count() > 0 Then
			Data_Stage.Insert("BBVSchedule", BBVSchedule(Data_Stage, Assignees));
			Data_Stage.Insert("LoadingVRCWithoutRestrictions", LoadingVRCWithoutRestrictions(Data_Stage, References));
			
			If Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
				Schedules = ProductionServer.WorkSchedulesOfRCTypes(References);
				For Each String In Schedules Do
					ShiftSchedules.Add(String.WorkScheduleCalendar);
				EndDo;
			EndIf;
		EndIf;
		
		References.Clear();
		TheStructureOfTheSearch.ConsiderAvailability = True;
		For Each String In Assignees.FindRows(TheStructureOfTheSearch) Do
			References.Add(String.WorkCenterType);
		EndDo;
		If References.Count() > 0 Then
			Data_Stage.Insert("WCKAvailability", WCKAvailability(Data_Stage, References));
			
			If Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
				Schedules = ProductionServer.WorkCenterSchedules(References, False);
				For Each String In Schedules Do
					ShiftSchedules.Add(String.WorkScheduleCalendar);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	// Intervals
	Intervals = Undefined;
	
	If Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		TempTablesManager = New TempTablesManager;
		CalendarSchedules.CreateTTWorkSchedulesForPeriod(
			TempTablesManager, ShiftSchedules, FullIntervalStart, FullIntervalEnding, False);
		
		Query = New Query(
			"SELECT
			|	CAST(Schedule.WorkScheduleCalendar AS Catalog.Calendars).Description AS Shift,
			|	MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
			|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
			|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) AS Begin,
			|	MAX(
			|		CASE
			|			WHEN Schedule.EndTime IS NULL 
			|				OR Schedule.EndTime = DATETIME(1, 1, 1)
			|				THEN DATEADD(Schedule.ScheduleDate, DAY, 1)
			|			ELSE DATEADD(Schedule.ScheduleDate, MINUTE,
			|				HOUR(Schedule.EndTime)*60 + MINUTE(Schedule.EndTime))
			|		END) AS Ending
			|FROM
			|	TTWorkSchedules AS Schedule
			|WHERE
			|	Schedule.Period >= &Begin
			|
			|GROUP BY
			|	Schedule.WorkScheduleCalendar,
			|	Schedule.Period,
			|	CAST(Schedule.WorkScheduleCalendar AS Catalog.Calendars).Description
			|
			|UNION ALL
			|
			|SELECT
			|	"""" AS Shift,
			|	CalendarSchedules.ScheduleDate AS Begin,
			|	DATEADD(CalendarSchedules.ScheduleDate, DAY, 1) AS Ending
			|FROM
			|	InformationRegister.CalendarSchedules AS CalendarSchedules
			|WHERE
			|	CalendarSchedules.Calendar = &MainCalendar
			|	AND CalendarSchedules.ScheduleDate BETWEEN &Begin AND &Ending
			|	AND NOT TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTWorkSchedules AS T
			|		WHERE
			|			T.Period = CalendarSchedules.ScheduleDate)
			|
			|ORDER BY
			|	Begin");
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Begin", FullIntervalStart);
		Query.SetParameter("Ending", FullIntervalEnding);
		Query.SetParameter("MainCalendar", Constants.MainEnterpriseCalendar.Get());
		
		Intervals = Query.Execute().Unload();
	Else
		Intervals = New ValueTable;
		Intervals.Columns.Add("Begin", New TypeDescription("Date"));
		Intervals.Columns.Add("Ending", New TypeDescription("Date"));
		Intervals.Columns.Add("Shift", New TypeDescription("String"));
		
		CurrentInterval = FullIntervalStart;
		While CurrentInterval < FullIntervalEnding Do
			StartOfRange = CurrentInterval;
			If Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
				CurrentInterval = EndOfHour(CurrentInterval) + 1;
			ElsIf Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
				CurrentInterval = EndOfDay(CurrentInterval) + 1;
			ElsIf Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
				CurrentInterval = EndOfWeek(CurrentInterval) + 1;
			ElsIf Data_Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
				CurrentInterval = EndOfMonth(CurrentInterval) + 1;
			EndIf;
			
			NewRow = Intervals.Add();
			NewRow.Begin = StartOfRange;
			NewRow.Ending = CurrentInterval;
		EndDo;
	EndIf;
	
	Data_Stage.Insert("Intervals", Intervals);
	
	Return Data_Stage;
	
EndFunction

Procedure OutputHeader(SpreadsheetDocument, Data_Stage, AppearanceTemplate)
	
	PlanningInterval = Data_Stage.PlanningInterval;
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		AreaInterval = AppearanceTemplate.GetArea("IntervalHour");
		AreaIntervalHeader = AppearanceTemplate.GetArea("IntervalHourHeader");
		
		ParametersStructure1 = New Structure("HourBeginningOfDay");
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		AreaInterval = AppearanceTemplate.GetArea("IntervalDay");
		AreaIntervalHeader = AppearanceTemplate.GetArea("IntervalDayHeader");
		
		ParametersStructure1 = New Structure("DayBeginningOfWeek, Day1, Day2,
			|Day3, Day4, Day5, Day6, Day7");
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		AreaInterval = AppearanceTemplate.GetArea("IntervalWeek");
		AreaIntervalHeader = AppearanceTemplate.GetArea("IntervalWeekHeader");
	
		ParametersStructure1 = New Structure("DayBeginningOfWeek");
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		AreaInterval = AppearanceTemplate.GetArea("IntervalMonth");
		AreaIntervalHeader = AppearanceTemplate.GetArea("IntervalMonthHeader");
		
		ParametersStructure1 = New Structure("DayBeginningOfMonth");
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		AreaInterval = AppearanceTemplate.GetArea("IntervalChange");
		AreaIntervalHeader = AppearanceTemplate.GetArea("IntervalChangeTitle");
		
		ParametersStructure1 = New Structure("DayShiftStarts");
	EndIf;
	
	AreaIntervalHeader.Parameters.ProductionStage = Data_Stage.Stage;
	AreaIntervalHeader.Parameters.PresentationStage = Data_Stage.PresentationStage;
	SpreadsheetDocument.Put(AreaIntervalHeader);
	
	For IndexOf = 0 To Data_Stage.Intervals.Count()-1 Do
		Interval = Data_Stage.Intervals[IndexOf]; // ValueTableRow
		CurrentInterval = Interval.Begin;
		
		If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
			If BegOfHour(CurrentInterval) = BegOfDay(CurrentInterval) Then
				ParametersStructure1.HourBeginningOfDay = CurrentInterval;
			EndIf;
			If EndOfHour(CurrentInterval) = EndOfDay(CurrentInterval) Then
				AreaInterval.Parameters.Fill(ParametersStructure1);
				SpreadsheetDocument.Join(AreaInterval);
			EndIf;
		ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
			If BegOfDay(CurrentInterval) = BegOfWeek(CurrentInterval) Then
				ParametersStructure1.DayBeginningOfWeek = CurrentInterval;
				WeekDay = 0;
			EndIf;
			
			ThisIsCurDay = CurrentInterval = BegOfDay(CurrentSessionDate());
			
			WeekDay = WeekDay + 1;
			If WeekDay = 1 Then
				ParametersStructure1.Day1 = CurrentInterval;
				AreaInterval.Areas.Day1.Font = New Font(
					AreaInterval.Areas.Day1.Font,,, ThisIsCurDay);
			ElsIf WeekDay = 2 Then
				ParametersStructure1.Day2 = CurrentInterval;
				AreaInterval.Areas.Day2.Font = New Font(
					AreaInterval.Areas.Day2.Font,,, ThisIsCurDay);
			ElsIf WeekDay = 3 Then
				ParametersStructure1.Day3 = CurrentInterval;
				AreaInterval.Areas.Day3.Font = New Font(
					AreaInterval.Areas.Day3.Font,,, ThisIsCurDay);
			ElsIf WeekDay = 4 Then
				ParametersStructure1.Day4 = CurrentInterval;
				AreaInterval.Areas.Day4.Font = New Font(
					AreaInterval.Areas.Day4.Font,,, ThisIsCurDay);
			ElsIf WeekDay = 5 Then
				ParametersStructure1.Day5 = CurrentInterval;
				AreaInterval.Areas.Day5.Font = New Font(
					AreaInterval.Areas.Day5.Font,,, ThisIsCurDay);
			ElsIf WeekDay = 6 Then
				ParametersStructure1.Day6 = CurrentInterval;
				AreaInterval.Areas.Day6.Font = New Font(
					AreaInterval.Areas.Day6.Font,,, ThisIsCurDay);
			ElsIf WeekDay = 7 Then
				ParametersStructure1.Day7 = CurrentInterval;
				AreaInterval.Areas.Day7.Font = New Font(
					AreaInterval.Areas.Day7.Font,,, ThisIsCurDay);
			EndIf;
			
			If EndOfDay(CurrentInterval) = EndOfWeek(CurrentInterval) Then
				AreaInterval.Parameters.Fill(ParametersStructure1);
				SpreadsheetDocument.Join(AreaInterval);
			EndIf;
		ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
			ParametersStructure1.DayBeginningOfWeek = CurrentInterval;
			AreaInterval.Parameters.Fill(ParametersStructure1);
		
			SpreadsheetDocument.Join(AreaInterval);
		ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
			ParametersStructure1.DayBeginningOfMonth = CurrentInterval;
			AreaInterval.Parameters.Fill(ParametersStructure1);
		
			SpreadsheetDocument.Join(AreaInterval);
		ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
			ParametersStructure1.DayShiftStarts = Format(Interval.Begin, "DF='dd MMM HH:mm'")
				+ Chars.LF
				+ Interval.Shift;
			AreaInterval.Parameters.Fill(ParametersStructure1);
			
			SpreadsheetDocument.Join(AreaInterval);
		EndIf;
	EndDo;
	
	SpreadsheetDocument.FixedTop = AreaInterval.TableHeight;
	SpreadsheetDocument.FixedLeft  = AreaIntervalHeader.TableWidth;
	
EndProcedure

Procedure SetAreaLayout(Receiver, Source)
	
	Receiver.BackColor   = Source.BackColor;
	Receiver.TextColor = Source.TextColor;
	Receiver.PatternColor  = Source.PatternColor;
	Receiver.Pattern       = Source.Pattern;
	
EndProcedure

Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

Function ThisIsUBBVStage(Data_Stage)
	
	Return Not Data_Stage.PlanOperationsOfWorkCenterTypes Or Data_Stage.ProductionByThirdParty;
	
EndFunction

Function GetTimeInSeconds(OperationTime, UnitOfMeasure)
	
	Return ProductionPlanningClientServer.GetTimeInSeconds(
		OperationTime, UnitOfMeasure);
	
EndFunction

Function GetTimeByString(OperationTime, UnitOfMeasure = Undefined)
	
	Return ProductionPlanningClientServer.GetTimeByString(
		OperationTime, UnitOfMeasure);
	
EndFunction

Procedure OutlineStageBoundaries(SpreadsheetDocument, Data_Stage)
	
	If Not ValueIsFilled(Data_Stage.LeftBorderOfStage)
		Or Not ValueIsFilled(Data_Stage.RightStageBoundary) Then
		Return;
	EndIf;
	
	Line = New Line(SpreadsheetDocumentCellLineType.Solid,2);
	AreaCurStage = SpreadsheetDocument.Area(
		4, 
		Data_Stage.LeftBorderOfStage, 
		SpreadsheetDocument.TableHeight, 
		Data_Stage.RightStageBoundary);
													
	AreaCurStage.Outline(Line, Line, Line, Line);
	AreaCurStage.BorderColor = WebColors.LightGreen;
	
EndProcedure

Function CollapsePerformers(Assignees, CollapseAlternative = False)
	
	If Assignees.Columns.Find("KeyArray") = Undefined Then
		Assignees.Columns.Add("KeyArray", New TypeDescription("Array"));
	EndIf;
	
	If Assignees.Count() < 2 Then
		Return Assignees;
	EndIf;
	
	Map = New Map();
	For IndexOf = -Assignees.Count() + 1 To 0 Do
		
		Item = Assignees[-IndexOf];
		
		If Not ValueIsFilled(Item.KeyArray) Then
			Item.KeyArray.Add(Item.ConnectionKey);
		EndIf;
		
		If Not CollapseAlternative And Item.AlternateType = True Then
			Continue;
		EndIf;
		
		If Map.Count() = 0 Then
			Map.Insert(Item.WorkCenterType, Item);
			Continue;
		EndIf;
		
		Duplicate1 = Map.Get(Item.WorkCenterType);
		
		If Not ValueIsFilled(Duplicate1) Then
			Map.Insert(Item.WorkCenterType, Item);
			Continue;
		EndIf;
		
		Duplicate1.OperationTime = Duplicate1.OperationTime + Item.OperationTime;
		Duplicate1.KeyArray.Add(Item.ConnectionKey);
		
		Assignees.Delete(Item);
	EndDo;
	
	Return Assignees;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
