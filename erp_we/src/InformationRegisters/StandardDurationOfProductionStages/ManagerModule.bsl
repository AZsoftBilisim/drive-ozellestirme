#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the standard duration of production stages
//
// Parameters:
//  BillOfMaterials - CatalogRef.BillsOfMaterials - the object of the calculation.
//  ErrorText  - String - text of the error that occurred
// 
// Returns:
//  Boolean - the result of the calculation (True if the calculation is successful).
//
Function Calculate(BillOfMaterials, ErrorText = "") Export
	
	SetPrivilegedMode(True);
	
	HasErrors = False;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.StandardDurationOfProductionStages");
		LockItem.SetValue("BillOfMaterials", BillOfMaterials);
		
		Block.Lock();
		
		CalculationResult2 = CalculateBySpecification(BillOfMaterials);
		RecordCalculationResult(BillOfMaterials, CalculationResult2);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		EventLogEvent = ProductionServer.EventCalculationOfNormativeDuration();
		
		ErrorText = StrTemplate(NStr("vi = 'Không thể tính thời lượng của các công đoạn sản xuất theo bảng kê chi tiết các nguồn lực sản xuất: %1 do: %2';
									|ru = 'Не удалось рассчитать длительность этапов производства по спецификации: %1 по причине: %2';
									|en = 'Cannot calculate production stage duration by BOM: %1. Reason: %2'; fa = 'Cannot calculate production stage duration by BOM: %1. Reason: %2';
									|it = 'Non è stato possibile calcolare la lunghezza delle fasi di produzione in base alla specifica: %1 a causa di: %2';
									|pl = 'Nie można obliczyć czasu trwania etapów produkcji zgodnie ze specyfikacją: %1 ze względu na: %2';
									|tr = 'Ürün reçetesine göre üretim aşamalarının süresi hesaplanamadı: %1 çünkü: %2'"),
										BillOfMaterials,
										ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Error,
			BillOfMaterials.Metadata(),
			BillOfMaterials,
			ErrorText);
		
		HasErrors = True;
		
	EndTry;
	
	SetPrivilegedMode(False);
	
	Return Not HasErrors;
	
EndFunction

#EndRegion

#Region Private

#Region CalculationOfDuration

Function CalculateBySpecification(BillOfMaterials)
	
	DataForCalculation = DataForCalculation(BillOfMaterials);
	
	StageList = DataForCalculation.StageList;
	TermsOfRepairs = DataForCalculation.TermsOfRepairs;
	
	NormsOfHours = New Map;
	
	TempTablesManager = New TempTablesManager;
	ProductionServer.CreateTTDivisionSchedules(
		StageList.UnloadColumn("Department"), TempTablesManager, "TTWorkSchedules_");
	
	Query = New Query(
		"SELECT
		|	TTWorkSchedules_.Ref AS Department,
		|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleCalendar
		|FROM
		|	TTWorkSchedules_ AS TTWorkSchedules_
		|TOTALS BY
		|	Department");
	Query.TempTablesManager = TempTablesManager;
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SampleResults.Next() Do
		
		ReferencesArrray = New Array;
		Selection = SampleResults.Select();
		While Selection.Next() Do
			ReferencesArrray.Add(Selection.WorkScheduleCalendar);
		EndDo;
		
		NormsOfHours.Insert(
			SampleResults.Department,
			ProductDataManagement.CollapsedAverageHoursByWorkSchedule(ReferencesArrray));
			
	EndDo;
	
	CalculateDuration_(StageList, NormsOfHours);
	CalculateResourcesByEnd(StageList, TermsOfRepairs, NormsOfHours);
	CalculateResourcesFromBeginning(StageList, TermsOfRepairs, NormsOfHours);
	
	Return StageList;
	
EndFunction

Procedure RecordCalculationResult(BillOfMaterials, CalculationResult2, CallingFromUpdateHandler = False)
	
	Set = InformationRegisters.StandardDurationOfProductionStages.CreateRecordSet();
	
	Set.Filter.BillOfMaterials.Set(BillOfMaterials);
	
	Set.Load(CalculationResult2);
	
	SetPrivilegedMode(True);
	
	If CallingFromUpdateHandler Then
		InfobaseUpdate.WriteData(Set);
	Else
		Set.Write(True);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function DataForCalculation(BillOfMaterials)
	
	//StageList
	Query = New Query(
		"SELECT
		|	Table.Ref AS Stage,
		|	Table.Owner AS BillOfMaterials,
		|	Table.StageNumber AS StageNumber,
		|	Table.NextStageNo AS NextStageNo,
		|	CASE
		|		WHEN Table.Department.WorkScheduleCalendar = VALUE(Catalog.Calendars.EmptyRef)
		|			THEN MainEnterpriseCalendar.Value
		|		ELSE Table.Department.WorkScheduleCalendar
		|	END AS WorkScheduleCalendar,
		|	Table.Department AS Department,
		|	Table.StageDuration AS Duration,
		|	(CASE Table.UnitOfMeasureOfStageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN 86400
		|		WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|			THEN 86400
		|		ELSE 1
		|	END * Table.StageDuration) AS DurationInSeconds,
		|	Table.UnitOfMeasureOfStageDuration AS UnitOfMeasure
		|FROM
		|	Catalog.ProductionStages AS Table
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON (TRUE)
		|WHERE
		|	Table.Owner = &BillOfMaterials
		|	AND NOT Table.DeletionMark
		|;
		|
		|
		|
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.SourceOfSemiFinishedProduct AS Stage,
		|	Table.Stage AS RecipientStage,
		|	MAX(CASE
		|		WHEN Table.AlternateType
		|			THEN 0
		|		ELSE ISNULL(Standards.PlannedProductionDurationDays, 0)
		|	END) AS Duration,
		|	MAX(ISNULL(Standards.MaximumProductionDurationDays, 0)) AS DurationMax
		|FROM
		|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
		|		LEFT JOIN InformationRegister.StandardProductionDuration AS Standards
		|		ON Table.BillOfMaterialsRM = Standards.BillOfMaterials
		|WHERE
		|	Table.Ref = &BillOfMaterials
		|	AND Table.ProducedInProcess
		|	AND Table.BillOfMaterialsRM <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|GROUP BY
		|	Table.SourceOfSemiFinishedProduct,
		|	Table.Stage");
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	ResultsArray = Query.ExecuteBatch(); 
	
	StageList = ResultsArray[0].Unload();
	
	TypeDetails = New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative));
	StageList.Columns.Add("ProductionDurationDays", TypeDetails);
	StageList.Columns.Add("DaysBeforeEnd", TypeDetails);
	StageList.Columns.Add("DaysBeforeEnd" + "Max", TypeDetails);
	StageList.Columns.Add("DaysFromBeginning", TypeDetails);
	StageList.Columns.Add("DaysFromBeginning" + "Max", TypeDetails);
	StageList.Columns.Add("Ending", TypeDetails);
	StageList.Columns.Add("Ending" + "Max", TypeDetails);
	
	TypeDetails = New TypeDescription("Number", New NumberQualifiers(10, 3, AllowedSign.Nonnegative));
	StageList.Columns.Add("ProductionDurationHours", TypeDetails);
	StageList.Columns.Add("BalanceInHours", TypeDetails); // rolling balance (in hours)
	StageList.Columns.Add("BalanceInHours" + "Max", TypeDetails); // rolling balance (in hours)
	
	TypeDetails = New TypeDescription("Number", New NumberQualifiers(14, 4, AllowedSign.Nonnegative));
	StageList.Columns.Add("DurationBeforeProductionIssue", TypeDetails);
	
	StageList.Columns.Add("Version", New TypeDescription("Number", New NumberQualifiers(2, 0, AllowedSign.Nonnegative)));
	StageList.FillValues(Version(), "Version");
	
	StageList.Indexes.Add("Stage");
	StageList.Indexes.Add("StageNumber");
	StageList.Indexes.Add("NextStageNo");
	
	TermsOfRepairs = ?(ResultsArray[1].IsEmpty(), Undefined, ResultsArray[1].Unload());
	
	Return New Structure("StageList, TermsOfRepairs", StageList, TermsOfRepairs);
	
EndFunction

Procedure CalculateDuration_(StageList, NormsOfHours)
	
	For Each ObjectOfARAP In StageList Do
		
		If ObjectOfARAP.Duration = 0 Then
			Continue;
		EndIf;
		
		ProductionDurationDays = 0;
		ProductionDurationHours = 0;
		
		If ObjectOfARAP.UnitOfMeasure <> Enums.TimeMeasureUnits.Day Then
		
			If ( ObjectOfARAP.UnitOfMeasure = Enums.TimeMeasureUnits.Hour
					Or ObjectOfARAP.UnitOfMeasure = Enums.TimeMeasureUnits.Minute
					Or ObjectOfARAP.UnitOfMeasure = Enums.TimeMeasureUnits.Second
				) Then
				
				ProductionDurationHours = ProductionPlanningClientServer.GetTimeInSeconds(
					ObjectOfARAP.Duration,
					ObjectOfARAP.UnitOfMeasure) / 3600;
				NormOfHours = NormsOfHours[ObjectOfARAP.Department];
				
				ProductionDurationDays = Int(ProductionDurationHours/NormOfHours) + ?(ProductionDurationHours % NormOfHours > 0,1,0);
				
			Else
				
				ProductionDurationDays = ProductionPlanningClientServer.GetTimeInUnit(
					ProductionPlanningClientServer.GetTimeInSeconds(
						ObjectOfARAP.Duration,
						ObjectOfARAP.UnitOfMeasure),
					Enums.TimeMeasureUnits.Day);
			EndIf;
			
		Else
			
			ProductionDurationDays = ObjectOfARAP.Duration;
			
		EndIf;
		
		ObjectOfARAP.ProductionDurationDays = ProductionDurationDays;
		ObjectOfARAP.ProductionDurationHours = ProductionDurationHours;
		
	EndDo;
	
EndProcedure

Procedure CalculateResourcesByEnd(StageList, TermsOfRepairs, NormsOfHours)
	
	StageList.FillValues(0, "BalanceInHours");
	StageList.FillValues(0, "BalanceInHours" + "Max");
	
	Filter = New Structure("NextStageNo", 0);
	Queue = StageList.FindRows(Filter);
	
	While Queue.Count() > 0 Do
		
		Vertex = Queue[0];
		
		If Vertex.NextStageNo = 0 Then
			
			CalculateResourceDaysToEnd(
				Vertex,
				NormsOfHours[Vertex.Department]);
			
			Vertex["DaysBeforeEnd" + "Max"] = Vertex.DaysBeforeEnd;
			Vertex["BalanceInHours" + "Max"]   = Vertex.BalanceInHours;
			
		EndIf;
		
		DurationBeforeProductionIssue = ?(Vertex.DurationInSeconds > 0,
			Vertex.DurationBeforeProductionIssue + Vertex.DurationInSeconds, Vertex.DurationBeforeProductionIssue + 0.0001);
		
		Filter.NextStageNo = Vertex.StageNumber;
		
		For Each Node In StageList.FindRows(Filter) Do
			
			Deadlines = TermsOfRepairBeforeEnd(StageList, TermsOfRepairs, Node, Vertex);
			
			CalculateResourceDaysToEnd(
				Node,
				NormsOfHours[Node.Department],
				Vertex,
				Deadlines.Duration,
				"");
			
			If Deadlines.Duration = Deadlines.DurationMax Then
				
				Node["DaysBeforeEnd" + "Max"] = Node.DaysBeforeEnd;
				Node["BalanceInHours" + "Max"] = Node.BalanceInHours;
				
			Else
				
				CalculateResourceDaysToEnd(
					Node,
					NormsOfHours[Node.Department],
					Vertex,
					Deadlines.DurationMax,
					"Max");
				
			EndIf;
			
			Node.DurationBeforeProductionIssue = Max(DurationBeforeProductionIssue, Node.DurationBeforeProductionIssue);
			
			If Queue.Find(Node) = Undefined Then
				Queue.Add(Node);
			EndIf;
			
		EndDo;
		
		Queue.Delete(0);
		
	EndDo;
	
EndProcedure

Function TermsOfRepairBeforeEnd(StageList, TermsOfRepairs, Stage, NextStage)
	
	Result = New Structure("Duration, DurationMax", 0, 0);
	
	If TermsOfRepairs = Undefined Then
		Return Result;
	EndIf;
	
	StageRepairs = TermsOfRepairs.FindRows(New Structure("Stage", Stage.Stage));
	For Each LineRepair In StageRepairs Do
		
		RecipientStage = StageList.Find(LineRepair.RecipientStage, "Stage");
		
		PeriodOfRepair = RecipientStage.DaysBeforeEnd + LineRepair.Duration;
		If PeriodOfRepair > NextStage.DaysBeforeEnd Then
			Result.Duration = Max(Result.Duration,
				(PeriodOfRepair - NextStage.DaysBeforeEnd));
		EndIf;
		
		PeriodOfRepair = RecipientStage["DaysBeforeEnd" + "Max"] + LineRepair.DurationMax;
		If PeriodOfRepair > NextStage["DaysBeforeEnd" + "Max"] Then
			Result.DurationMax = Max(Result.DurationMax,
				(PeriodOfRepair - NextStage["DaysBeforeEnd" + "Max"]));
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CalculateResourceDaysToEnd(ObjectOfARAP, NormOfHours, Follower = Undefined, DelayInDays = 0, Postfix = "")
	
	DaysBeforeEnd = 0;
	If Follower <> Undefined Then
		If (Follower <> Undefined
				And Follower.BalanceInHours > 0
				And ObjectOfARAP.ProductionDurationHours > 0
				And ObjectOfARAP.Department = Follower.Department
				And DelayInDays = 0) Then
			TotalDurationInHours = Max(ObjectOfARAP.ProductionDurationHours - Follower.BalanceInHours, 0);
			TotalDurationInDays = Int(TotalDurationInHours/NormOfHours) + ?(TotalDurationInHours % NormOfHours > 0,1,0);
		Else
			TotalDurationInDays = ObjectOfARAP.ProductionDurationDays;
		EndIf;
		DaysBeforeEnd = Max(ObjectOfARAP["DaysBeforeEnd" + Postfix],
			TotalDurationInDays + Follower["DaysBeforeEnd" + Postfix] + DelayInDays);
	Else
		DaysBeforeEnd = ObjectOfARAP.ProductionDurationDays;
	EndIf;
	ObjectOfARAP["DaysBeforeEnd" + Postfix] = DaysBeforeEnd;
	
	BalanceInHours = 0;
	If ObjectOfARAP.ProductionDurationHours > 0 Then
		If (Follower <> Undefined
				And Follower["BalanceInHours" + Postfix] > 0
				And ObjectOfARAP.ProductionDurationHours > 0
				And ObjectOfARAP.Department = Follower.Department
				And DelayInDays = 0) Then
			
			If ObjectOfARAP.ProductionDurationHours > Follower["BalanceInHours" + Postfix] Then
				BalanceInHours = (ObjectOfARAP["DaysBeforeEnd" + Postfix] - Follower["DaysBeforeEnd" + Postfix])
					* NormOfHours - (ObjectOfARAP.ProductionDurationHours - Follower["BalanceInHours" + Postfix]);
			Else
				BalanceInHours = Follower["BalanceInHours" + Postfix] - ObjectOfARAP.ProductionDurationHours;
			EndIf;
			
		Else
			BalanceInHours = (ObjectOfARAP.ProductionDurationDays * NormOfHours) - ObjectOfARAP.ProductionDurationHours;
		EndIf;
	EndIf;
	ObjectOfARAP["BalanceInHours" + Postfix] = BalanceInHours;
	
EndProcedure

Procedure CalculateResourcesFromBeginning(StageList, TermsOfRepairs, NormsOfHours)
	
	StageList.FillValues(0, "BalanceInHours");
	StageList.FillValues(0, "BalanceInHours" + "Max");
	
	Queue = New Array;
	
	For Each Stage In StageList Do
		
		FoundRow = StageList.Find(Stage.StageNumber, "NextStageNo");
		If FoundRow = Undefined Then
			
			CalculateResourceDaysFromStart(
				Stage,
				NormsOfHours[Stage.Department]);
			
			Stage["Ending" + "Max"]     = Stage.Ending;
			Stage["BalanceInHours" + "Max"] = Stage.BalanceInHours;
			
			Queue.Add(Stage);
			
		EndIf;
		
	EndDo;
	
	While Queue.Count() > 0 Do
		
		Vertex = Queue[0];
		
		Filter = New Structure("StageNumber", Vertex.NextStageNo);
		
		For Each Node In StageList.FindRows(Filter) Do
			
			Deadlines = TermsOfRepairFromBeginning(StageList, TermsOfRepairs, Vertex, Node);
			
			CalculateResourceDaysFromStart(
				Node,
				NormsOfHours[Node.Department],
				Vertex,
				Deadlines.Duration,
				"");
				
			If Deadlines.Duration = Deadlines.DurationMax Then
				
				Node["DaysFromBeginning" + "Max"]  = Node.DaysFromBeginning;
				Node["Ending" + "Max"]     = Node.Ending;
				Node["BalanceInHours" + "Max"] = Node.BalanceInHours;
				
			Else
				
				CalculateResourceDaysFromStart(
					Node,
					NormsOfHours[Node.Department],
					Vertex,
					Deadlines.DurationMax,
					"Max");
				
			EndIf;
			
			If Queue.Find(Node) = Undefined Then
				Queue.Add(Node);
			EndIf;
			
		EndDo;
		
		Queue.Delete(0);
		
	EndDo;
	
EndProcedure

Function TermsOfRepairFromBeginning(StageList, TermsOfRepairs, Stage, NextStage)
	
	Result = New Structure("Duration, DurationMax", 0, 0);
	
	If TermsOfRepairs = Undefined Then
		Return Result;
	EndIf;
	
	StageRepairs = TermsOfRepairs.FindRows(New Structure("RecipientStage", NextStage.Stage));
	For Each LineRepair In StageRepairs Do
		
		StageSender = StageList.Find(LineRepair.Stage, "Stage");
		
		PeriodOfRepair = StageSender.Ending + LineRepair.Duration;
		If PeriodOfRepair > Stage.Ending Then
			Result.Duration = Max(Result.Duration,
				(PeriodOfRepair - Stage.Ending));
		EndIf;
		
		PeriodOfRepair = StageSender["Ending" + "Max"] + LineRepair.DurationMax;
		If PeriodOfRepair > Stage["Ending" + "Max"] Then
			Result.DurationMax = Max(Result.DurationMax,
				(PeriodOfRepair - Stage["Ending" + "Max"]));
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CalculateResourceDaysFromStart(ObjectOfARAP, NormOfHours, Predecessor = Undefined, DelayInDays = 0, Postfix = "")
	
	OffsettingPredecessorSHours = Predecessor <> Undefined
		And Predecessor["BalanceInHours" + Postfix] > 0
		And ObjectOfARAP.ProductionDurationHours > 0
		And ObjectOfARAP.Department = Predecessor.Department
		And DelayInDays = 0;
	
	DaysFromBeginning = 0;
	If Predecessor <> Undefined Then
		
		If OffsettingPredecessorSHours Then
			Begin = Predecessor["Ending" + Postfix] - 1;
		Else
			Begin = Predecessor["Ending" + Postfix] + DelayInDays;
		EndIf;
		
		DaysFromBeginning = Max(ObjectOfARAP["DaysFromBeginning" + Postfix], Begin);
		
	EndIf;
	ObjectOfARAP["DaysFromBeginning" + Postfix] = DaysFromBeginning;
	
	Ending = ObjectOfARAP["DaysFromBeginning" + Postfix] + ObjectOfARAP.ProductionDurationDays;
	If OffsettingPredecessorSHours And ObjectOfARAP.ProductionDurationHours > Predecessor["BalanceInHours" + Postfix] Then
		Ending = Ending + 1;
	EndIf;
	ObjectOfARAP["Ending" + Postfix] = Ending;
	
	BalanceInHours = 0;
	If ObjectOfARAP.ProductionDurationHours > 0 Then
		
		If OffsettingPredecessorSHours Then
			
			If ObjectOfARAP.ProductionDurationHours > Predecessor["BalanceInHours" + Postfix] Then
				BalanceInHours = (ObjectOfARAP["Ending" + Postfix] - Predecessor["DaysFromBeginning" + Postfix] - 1)
					* NormOfHours - (ObjectOfARAP.ProductionDurationHours - Predecessor["BalanceInHours" + Postfix]);
			Else
				BalanceInHours = Predecessor["BalanceInHours" + Postfix] - ObjectOfARAP.ProductionDurationHours;
			EndIf;
			
		Else
			BalanceInHours = (ObjectOfARAP.ProductionDurationDays * NormOfHours) - ObjectOfARAP.ProductionDurationHours;
		EndIf;
		
	EndIf;
	ObjectOfARAP["BalanceInHours" + Postfix] = BalanceInHours;
	
EndProcedure

Function Version()
	
	Return 1;
	
EndFunction

#EndRegion

#EndRegion

#EndIf