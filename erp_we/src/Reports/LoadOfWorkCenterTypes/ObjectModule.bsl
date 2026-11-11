#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);
	
	If DataSelectionValues.BeginOfPeriod = '000101010000' 
		Or DataSelectionValues.PeriodEnding = '000101010000' Then
		
		MessageText = NStr("vi = 'Trường ""Kỳ"" chưa điền.';
							|ru = 'Поле ""Период"" не заполнено.';
							|en = '""Period"" is not filled in.'; fa = '""Period"" is not filled in.';
							|it = 'Il campo ""periodo"" non è compilato.';
							|pl = 'Pole ""Okres"" nie jest wypełnione.';
							|tr = '""Dönem"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel); 
	EndIf;

	If DataSelectionValues.ReportFrequency = Undefined Then
		
		MessageText = NStr("vi = 'Chưa điền trường ""Định kỳ báo cáo"".';
							|ru = 'Поле ""Периодичность отчета"" не заполнено.';
							|en = '""Generate every"" is required.'; fa = '""Generate every"" is required.';
							|it = '""Generate every"" is required.';
							|pl = '""Generate every"" is required.';
							|tr = '""Rapor dönemselliği"" alanı doldurulmadı.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;

EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	ExternalDataSets = GenerateExternalDatasets(MainCircuitSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);	
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);	
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Function GenerateExternalDatasets(MainCircuitSettings)
	
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.ProductionStage2_2"));
	TypesArray.Add(Type("DocumentRef.ProductionOrder2_2"));
	FromMe = New TypeDescription(TypesArray);
	
	DownloadData_ = New ValueTable;
	DownloadData_.Columns.Add("Department",              New TypeDescription("CatalogRef.BusinessStructure"));
	DownloadData_.Columns.Add("WorkCenterType",          New TypeDescription("CatalogRef.WorkCenterTypes"));
	DownloadData_.Columns.Add("SetupSettings",             New TypeDescription("CatalogRef.SetupOptions"));
	DownloadData_.Columns.Add("Available",                   New TypeDescription("Number", New NumberQualifiers(15)));
	DownloadData_.Columns.Add("Busy",                     New TypeDescription("Number", New NumberQualifiers(15)));
	DownloadData_.Columns.Add("AvailableInSummary",             New TypeDescription("Number", New NumberQualifiers(15)));
	DownloadData_.Columns.Add("BusySummary",               New TypeDescription("Number", New NumberQualifiers(15)));
	DownloadData_.Columns.Add("Products",               New TypeDescription("CatalogRef.Products"));
	DownloadData_.Columns.Add("Characteristic",             New TypeDescription("CatalogRef.ItemsCharacteristics"));
	DownloadData_.Columns.Add("Count",                 New TypeDescription("Number", New NumberQualifiers(15,3)));
	DownloadData_.Columns.Add("SchedulePeriod",              New TypeDescription("Date"));
	DownloadData_.Columns.Add("SchedulePeriodPresentation", New TypeDescription("String"));
	DownloadData_.Columns.Add("ParallelLoad",       New TypeDescription("Boolean"));
	DownloadData_.Columns.Add("ConsiderAvailability",       New TypeDescription("Boolean"));
	DownloadData_.Columns.Add("Stage",                       New TypeDescription("DocumentRef.ProductionStage2_2, CatalogRef.ProductionStages"));
	DownloadData_.Columns.Add("ReferenceOrder",        	   FromMe);
	
	Query = New Query;
	Query.Text = 
	//0
	"SELECT ALLOWED
	|	AvailabilityOfWorkCenterTypesTurnovers.WorkCenterType AS WorkCenterType,
	|	CASE &ReportFrequency
	|		WHEN VALUE(Enum.Periodicity.DAY) THEN
	|			BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, DAY)
	|		WHEN VALUE(Enum.Periodicity.WEEK) THEN
	|			BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, WEEK)
	|		ELSE
	|			BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, MONTH)
	|	END AS SchedulePeriod,	
	|	WorkCenterTypes.ParallelLoad AS ParallelLoad,
	|	WorkCenterTypes.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
	|	SUM(CASE
	|			WHEN WorkCenterTypes.EnterAvailabilityForWorkCenterType
	|				THEN AvailabilityOfWorkCenterTypesTurnovers.WorkCenterTypeScheduleTurnover
	|			ELSE AvailabilityOfWorkCenterTypesTurnovers.WorkCenterScheduleTurnover
	|		END) AS Available
	|FROM
	|	AccumulationRegister.AvailabilityOfWorkCenterTypes.Turnovers(
	|			,
	|			,
	|			,
	|			IntervalDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				AND (&AnyKindOfWorkCenter
	|					OR WorkCenterType IN (&ListOfTypesOfWorkCenters))) AS AvailabilityOfWorkCenterTypesTurnovers
	|	LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
	|	ON WorkCenterTypes.Ref = AvailabilityOfWorkCenterTypesTurnovers.WorkCenterType
	|WHERE
	|	(&AnyDivision
	|			OR WorkCenterTypes.Department IN (&DepartmentList))
	|	AND CASE
	|			WHEN (WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|					OR WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|					OR WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY))
	|					AND (AvailabilityOfWorkCenterTypesTurnovers.IntervalDate BETWEEN &BegOfDay AND &EndOfDay)
	|				THEN TRUE
	|			WHEN WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|					AND (AvailabilityOfWorkCenterTypesTurnovers.IntervalDate BETWEEN &BegOfWeek AND &EndOfWeek)
	|				THEN TRUE
	|			WHEN WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
	|					AND (AvailabilityOfWorkCenterTypesTurnovers.IntervalDate BETWEEN &BegOfMonth AND &EndOfMonth)
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	
	|
	|GROUP BY
	|	AvailabilityOfWorkCenterTypesTurnovers.WorkCenterType,
	|	WorkCenterTypes.ParallelLoad,
	|	WorkCenterTypes.UseAvailabilityAccordingToSchedule,
	|	CASE &ReportFrequency
	|		WHEN VALUE(Enum.Periodicity.DAY) THEN
	|			BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, DAY)
	|		WHEN VALUE(Enum.Periodicity.WEEK) THEN
	|			BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, WEEK)
	|		ELSE
	|			BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, MONTH)
	|	END	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionScheduleRecorder
	|			THEN TableOfEmploymentTypesOfWorkCenters.ReferenceOrder
	|		WHEN TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionStage2_2
	|			THEN TableOfEmploymentTypesOfWorkCenters.Recorder
	|	END AS ReferenceOrder,
	|	CASE
	|		WHEN TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionScheduleRecorder
	|			THEN TableOfEmploymentTypesOfWorkCenters.Stage
	|		ELSE UNDEFINED
	|	END AS Stage,
	|	TableOfEmploymentTypesOfWorkCenters.RowCodeProducts AS RowCodeProducts,
	|	TableOfEmploymentTypesOfWorkCenters.WorkCenterType AS WorkCenterType,
	|	TableOfEmploymentTypesOfWorkCenters.SetupSettings AS SetupSettings,
	|	TableOfEmploymentTypesOfWorkCenters.IntervalDate AS IntervalDate,
	|	WorkCenterTypes.ParallelLoad AS ParallelLoad,
	|	WorkCenterTypes.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
	|	SUM(TableOfEmploymentTypesOfWorkCenters.Busy) AS Busy
	|INTO OccupancyOfWorkCenterTypes
	|FROM
	|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS TableOfEmploymentTypesOfWorkCenters
	|	LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
	|	ON WorkCenterTypes.Ref = TableOfEmploymentTypesOfWorkCenters.WorkCenterType
	|WHERE
	|	(TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionStage2_2
	|			OR TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionScheduleRecorder
	|	)
	|	AND (&AnyKindOfWorkCenter
	|			OR TableOfEmploymentTypesOfWorkCenters.WorkCenterType IN (&ListOfTypesOfWorkCenters))
	|	AND CASE
	|			WHEN (WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|					OR WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|					OR WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY))
	|					AND (TableOfEmploymentTypesOfWorkCenters.IntervalDate BETWEEN &BegOfDay AND &EndOfDay)
	|				THEN TRUE
	|			WHEN WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|					AND (TableOfEmploymentTypesOfWorkCenters.IntervalDate BETWEEN &BegOfWeek AND &EndOfWeek)
	|				THEN TRUE
	|			WHEN WorkCenterTypes.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.MONTH)
	|					AND (TableOfEmploymentTypesOfWorkCenters.IntervalDate BETWEEN &BegOfMonth AND &EndOfMonth)
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|
	|GROUP BY
	|	CASE
	|		WHEN TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionScheduleRecorder
	|			THEN TableOfEmploymentTypesOfWorkCenters.ReferenceOrder
	|		WHEN TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionStage2_2
	|			THEN TableOfEmploymentTypesOfWorkCenters.Recorder
	|	END,
	|	CASE
	|		WHEN TableOfEmploymentTypesOfWorkCenters.Recorder REFS Document.ProductionScheduleRecorder
	|			THEN TableOfEmploymentTypesOfWorkCenters.Stage
	|		ELSE UNDEFINED
	|	END,
	|	TableOfEmploymentTypesOfWorkCenters.RowCodeProducts,
	|	TableOfEmploymentTypesOfWorkCenters.WorkCenterType,
	|	TableOfEmploymentTypesOfWorkCenters.SetupSettings,
	|	WorkCenterTypes.ParallelLoad,
	|	WorkCenterTypes.UseAvailabilityAccordingToSchedule,
	|	TableOfEmploymentTypesOfWorkCenters.IntervalDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfEmploymentTypesOfWorkCenters.ReferenceOrder AS ReferenceOrder,
	|	TableOfEmploymentTypesOfWorkCenters.Stage AS Stage,
	|	TableOfEmploymentTypesOfWorkCenters.WorkCenterType AS WorkCenterType,
	|	TableOfEmploymentTypesOfWorkCenters.SetupSettings AS SetupSettings,
	|	TableOfEmploymentTypesOfWorkCenters.WorkCenterType.Department AS Department,
	|	TableOfEmploymentTypesOfWorkCenters.ParallelLoad AS ParallelLoad,
	|	TableOfEmploymentTypesOfWorkCenters.ConsiderAvailability AS ConsiderAvailability,
	|	CASE
	|		WHEN TableOfEmploymentTypesOfWorkCenters.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|				OR TableOfEmploymentTypesOfWorkCenters.WorkCenterType.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|		ELSE TableOfEmploymentTypesOfWorkCenters.WorkCenterType.Department.PlanningInterval
	|	END AS PlanningInterval,
	|	CASE &ReportFrequency
	|		WHEN VALUE(Enum.Periodicity.DAY) THEN
	|			BEGINOFPERIOD(TableOfEmploymentTypesOfWorkCenters.IntervalDate, DAY)
	|		WHEN VALUE(Enum.Periodicity.WEEK) THEN
	|			BEGINOFPERIOD(TableOfEmploymentTypesOfWorkCenters.IntervalDate, WEEK)
	|		ELSE
	|			BEGINOFPERIOD(TableOfEmploymentTypesOfWorkCenters.IntervalDate, MONTH)
	|	END AS SchedulePeriod,	
	|	UNDEFINED AS Products,
	|	UNDEFINED AS Characteristic,
	|	0 AS Count,
	|	TableOfEmploymentTypesOfWorkCenters.Busy AS Busy
	|FROM
	|	OccupancyOfWorkCenterTypes AS TableOfEmploymentTypesOfWorkCenters
	|WHERE
	|	TableOfEmploymentTypesOfWorkCenters.ReferenceOrder REFS Document.ProductionStage2_2
	|	OR TableOfEmploymentTypesOfWorkCenters.ReferenceOrder REFS Document.ProductionOrder2_2
	|
	|";
	
	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);
	
	Query.SetParameter("AnyDivision",        DataSelectionValues.DepartmentList.Count() = 0);
	Query.SetParameter("AnyKindOfWorkCenter",    DataSelectionValues.ListOfTypesOfWorkCenters.Count() = 0);
	Query.SetParameter("DepartmentList",       DataSelectionValues.DepartmentList);
	Query.SetParameter("ListOfTypesOfWorkCenters", DataSelectionValues.ListOfTypesOfWorkCenters);
	Query.SetParameter("ReportFrequency",  DataSelectionValues.ReportFrequency); 
	
	// Depending on the planning interval, the desired period is used
	Query.SetParameter("BegOfDay",    BegOfDay(DataSelectionValues.BeginOfPeriod));
	Query.SetParameter("EndOfDay",     EndOfDay(DataSelectionValues.PeriodEnding));
	Query.SetParameter("BegOfWeek", BegOfWeek(DataSelectionValues.BeginOfPeriod));
	Query.SetParameter("EndOfWeek",  EndOfWeek(DataSelectionValues.PeriodEnding));
	Query.SetParameter("BegOfMonth", BegOfMonth(DataSelectionValues.BeginOfPeriod));
	Query.SetParameter("EndOfMonth",  EndOfMonth(DataSelectionValues.PeriodEnding));
	Query.SetParameter("BeginOfPeriod",
		Min(BegOfWeek(DataSelectionValues.BeginOfPeriod), BegOfMonth(DataSelectionValues.BeginOfPeriod)));
	Query.SetParameter("EndOfPeriod",
		Max(EndOfWeek(DataSelectionValues.PeriodEnding), EndOfMonth(DataSelectionValues.PeriodEnding)));
	
	Result = Query.ExecuteBatch();  
	
	WCKAvailability = Result[0].Unload();
	WCKAvailability.Indexes.Add("WorkCenterType,SchedulePeriod");
	
	VRCEmployment = Result[2].Unload();
	VRCEmployment.Indexes.Add("WorkCenterType,SchedulePeriod");

	SummaryVRCAvailability = WCKAvailability.Copy();
	SummaryVRCAvailability.GroupBy("WorkCenterType, SchedulePeriod", "Available");
	SummaryVRCAvailability.Indexes.Add("WorkCenterType,SchedulePeriod");
	
	SummaryEmploymentOfVRC = VRCEmployment.Copy();
	SummaryEmploymentOfVRC.GroupBy("WorkCenterType, SchedulePeriod", "Busy");
	SummaryEmploymentOfVRC.Indexes.Add("WorkCenterType,SchedulePeriod");
	
	ListOfTypesOfRC = VRCEmployment.Copy(,"Department,WorkCenterType,PlanningInterval,ParallelLoad,ConsiderAvailability");
	ListOfTypesOfRC.GroupBy("Department,WorkCenterType,PlanningInterval,ParallelLoad,ConsiderAvailability");
	
	For Each RowViewRC In ListOfTypesOfRC Do
		
		PlanningIntervalBasedOnFrequencyOfReport = PlanningIntervalBasedOnFrequencyOfReport(DataSelectionValues.ReportFrequency);
		CurrentPeriod = ProductionPlanningClientServer.PlanningIntervalStart(
										DataSelectionValues.BeginOfPeriod, 
										PlanningIntervalBasedOnFrequencyOfReport);
										
		While CurrentPeriod <= DataSelectionValues.PeriodEnding Do
			
			TheStructureOfTheSearch = New Structure("WorkCenterType,SchedulePeriod", RowViewRC.WorkCenterType, CurrentPeriod);
		 	VRCEmploymentFound = VRCEmployment.FindRows(TheStructureOfTheSearch);
		 	VRCAvailabilityFound = WCKAvailability.FindRows(TheStructureOfTheSearch);
		 	FoundSummaryEmploymentOfVRC = SummaryEmploymentOfVRC.FindRows(TheStructureOfTheSearch);
		 	FoundSummaryVRCAvailability = SummaryVRCAvailability.FindRows(TheStructureOfTheSearch);
			
			If VRCEmploymentFound.Count() <> 0 Then
				
				For Each SampleEmploymentOfVRC In VRCEmploymentFound Do
					DataString = DownloadData_.Add();
					FillPropertyValues(DataString, SampleEmploymentOfVRC);
					DataString.SchedulePeriod = CurrentPeriod;
					
					DataString.SchedulePeriodPresentation = ProductionAccounting.LineSchedulingInterval(
																					DataString.SchedulePeriod, 
																					PlanningIntervalBasedOnFrequencyOfReport);
					If VRCAvailabilityFound.Count() <> 0 Then
						DataString.Available = VRCAvailabilityFound[0].Available;
					EndIf;
					
					If FoundSummaryEmploymentOfVRC.Count() <> 0 Then
						DataString.BusySummary = FoundSummaryEmploymentOfVRC[0].Busy;
					EndIf; 

					If FoundSummaryVRCAvailability.Count() <> 0 Then
						DataString.AvailableInSummary = FoundSummaryVRCAvailability[0].Available;
					EndIf; 

				EndDo;
				
			EndIf;
			
			DataString = DownloadData_.Add();
			DataString.WorkCenterType = RowViewRC.WorkCenterType;
			DataString.Department = RowViewRC.Department;
			DataString.SchedulePeriod = CurrentPeriod;
			DataString.ParallelLoad = RowViewRC.ParallelLoad;
			DataString.ConsiderAvailability = RowViewRC.ConsiderAvailability;
			
			DataString.SchedulePeriodPresentation = ProductionAccounting.LineSchedulingInterval(
																			DataString.SchedulePeriod, 
																			PlanningIntervalBasedOnFrequencyOfReport);
			If VRCAvailabilityFound.Count() <> 0 Then
				DataString.Available = VRCAvailabilityFound[0].Available;
			EndIf; 

			If FoundSummaryEmploymentOfVRC.Count() <> 0 Then
				DataString.BusySummary = FoundSummaryEmploymentOfVRC[0].Busy;
			EndIf; 

			If FoundSummaryVRCAvailability.Count() <> 0 Then
				DataString.AvailableInSummary = FoundSummaryVRCAvailability[0].Available;
			EndIf; 
			
			CurrentPeriod = ProductionPlanningClientServer.PlanningIntervalEnd(CurrentPeriod, PlanningIntervalBasedOnFrequencyOfReport) + 1;
			
		EndDo;
		
	EndDo;

	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("DownloadData_", DownloadData_);
	
	Return ExternalDataSets;

EndFunction
 
Function GetDataSelectionValues(MainCircuitSettings)

	Period = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Period").Value; // StandardPeriod - 
	ReportFrequency = DataCompositionClientServer.GetParameter(MainCircuitSettings, "ReportFrequency").Value;
	
	FilterItems1 = MainCircuitSettings.Filter.Items;
	
	DepartmentList = New ValueList;
	ListOfTypesOfWorkCenters = New ValueList;
	
	If FilterItems1 <> Undefined Then
		Department  = FilterValue("Department", FilterItems1);
		If Department <> Undefined And TypeOf(Department) = Type("ValueList") Then
			DepartmentList.LoadValues(Department.UnloadValues());
		ElsIf Department <> Undefined Then
			DepartmentList.Add(Department);
		EndIf;
		
		WorkCenterType = FilterValue("WorkCenterType", FilterItems1);
		If WorkCenterType <> Undefined And TypeOf(WorkCenterType) = Type("ValueList") Then
			ListOfTypesOfWorkCenters.LoadValues(WorkCenterType.UnloadValues());
		ElsIf WorkCenterType <> Undefined Then
			ListOfTypesOfWorkCenters.Add(WorkCenterType);
		EndIf;
	EndIf; 
	
	DataSelectionValues = New Structure;
	DataSelectionValues.Insert("DepartmentList",          DepartmentList);
	DataSelectionValues.Insert("ListOfTypesOfWorkCenters",    ListOfTypesOfWorkCenters);
	DataSelectionValues.Insert("BeginOfPeriod",                Period.StartDate);
	DataSelectionValues.Insert("PeriodEnding",             Period.EndDate);
	DataSelectionValues.Insert("ReportFrequency", 		  ReportFrequency);
	
	Return DataSelectionValues;
	
EndFunction

Function FilterValue(FieldName, FilterItems1)

	Field = New DataCompositionField(FieldName);
	
	For Each CollectionItem In FilterItems1 Do
		If TypeOf(CollectionItem) = Type("DataCompositionFilterItem") 
			And CollectionItem.LeftValue = Field 
			And CollectionItem.Use Then
			
			Return CollectionItem.RightValue;
		EndIf; 
	EndDo; 
	
	Return Undefined;

EndFunction

Function PlanningIntervalBasedOnFrequencyOfReport(Periodicity)
	
	Result = Enums.ProductionScheduleAccuracy.Day;
	If Periodicity = Enums.Periodicity.Week Then
		Result = Enums.ProductionScheduleAccuracy.Week;
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Result = Enums.ProductionScheduleAccuracy.Month;
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Result = Enums.ProductionScheduleAccuracy.Month;
	Else
		Result = Enums.ProductionScheduleAccuracy.Day;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
