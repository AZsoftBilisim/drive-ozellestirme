////////////////////////////////////////////////////////////////////////////////
// OUP: Procedures of the subsystem of operational accounting of production
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ScheduleOfWorkCenters

// Generates a string representation of the planning interval
//
// Parameters:
//  Period					- Date - start of the planning interval
//  PlanningInterval	- EnumRef.ProductionScheduleAccuracy - The planning interval.
//
// Returns:
//   String   - representation of the planning interval.
//
Function LineSchedulingInterval(Period, PlanningInterval) Export

	PeriodString = "";
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		
		PeriodString = Format(Period, NStr("vi = 'ДФ=''дд ММММ''';
											|ru = 'ДФ=''dd MMMM''';
											|en = 'DF=''dd MMMM'''; fa = 'DF=''dd MMMM''';
											|it = 'ДФ=''дд ММММ''';
											|pl = 'DF=''dd MMMM''';
											|tr = 'DF=''dd MMMM'''")) + " (" 
												+ Format(Period, NStr("vi = 'ДФ=''ЧЧ:00''';
																		|ru = 'ДФ=''ЧЧ:00''';
																		|en = 'DF=''HH:00'''; fa = 'DF=''HH:00''';
																		|it = 'ДФ=''ЧЧ:00''';
																		|pl = 'DF=''HH:00''';
																		|tr = 'DF=''HH:00'''")) + " - " 
												+ Format(Period + 3600, NStr("vi = 'ДФ=''ЧЧ:00''';
																			|ru = 'ДФ=''ЧЧ:00''';
																			|en = 'DF=''HH:00'''; fa = 'DF=''HH:00''';
																			|it = 'ДФ=''ЧЧ:00''';
																			|pl = 'DF=''HH:00''';
																			|tr = 'DF=''HH:00'''")) + ")";
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		PeriodString = Format(Period, NStr("vi = 'ДФ=''дд ММММ ЧЧ:мм''';
											|ru = 'ДФ=''dd MMMM HH:mm''';
											|en = 'DF=''dd MMMM HH:mm'''; fa = 'DF=''dd MMMM HH:mm''';
											|it = 'ДФ=''дд ММММ ЧЧ:мм''';
											|pl = 'DF=''dd MMMM HH:mm''';
											|tr = 'DF=""gg AAAA SS:dd""'"));
		
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		PeriodString = Format(Period, NStr("vi = 'ДФ=''дд ММММ (ддд)''';
											|ru = 'ДФ=''dd MMMM (ddd)''';
											|en = 'DF=''dd MMMM (ddd)'''; fa = 'DF=''dd MMMM (ddd)''';
											|it = 'ДФ=''дд ММММ (ддд)''';
											|pl = 'DF=''dd MMMM (ddd)''';
											|tr = 'DF=''dd MMMM (ddd)'''"));
		
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		PeriodString = Format(Period, NStr("vi = 'ДФ=''дд.ММ.гг''';
											|ru = 'ДФ=''dd.MM.yy''';
											|en = 'DF=''MM.dd.yy'''; fa = 'DF=''MM.dd.yy''';
											|it = 'ДФ=''дд.ММ.гг''';
											|pl = 'DF=''dd.MM.yy''';
											|tr = 'DF=''dd.MM.yy'''")) + " - " + Format(EndOfWeek(Period), NStr("vi = 'ДФ=''дд.ММ.гг''';
																												|ru = 'ДФ=''dd.MM.yy''';
																												|en = 'DF=''MM.dd.yy'''; fa = 'DF=''MM.dd.yy''';
																												|it = 'ДФ=''дд.ММ.гг''';
																												|pl = 'DF=''dd.MM.yy''';
																												|tr = 'DF=''dd.MM.yy'''"));
		
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		PeriodString = Format(Period, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
											|ru = 'ДФ=''MMMM yyyy''';
											|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
											|it = 'ДФ=''ММММ гггг''';
											|pl = 'DF=''MMMM yyyy''';
											|tr = 'DF=''MMMM yyyy'''"));
	EndIf;

	Return PeriodString; 
	
EndFunction


#EndRegion

#Region OperationalManagement

// Sets the document object lock of operation
// 
// Parameters:
//  DocumentObject - DocumentObject.ProductionOperation2_2
Procedure BlockProductionOperation(DocumentObject) Export
	
	ExceptionPattern = NStr("vi = 'Không thể khóa giao dịch sản xuất %1 ngày %2 (%3). Có thể chứng từ hiện đang được chỉnh sửa.';
							|ru = 'Не удалось заблокировать производственную операцию %1 от %2 (%3). Возможно документ в настоящий момент редактируется.';
							|en = 'Cannot lock the %1 routing operations dated %2 (%3). The document is probably locked for editing.'; fa = 'Cannot lock the %1 routing operations dated %2 (%3). The document is probably locked for editing.';
							|it = 'Cannot lock the %1 routing operations dated %2 (%3). The document is probably locked for editing.';
							|pl = 'Cannot lock the %1 routing operations dated %2 (%3). The document is probably locked for editing.';
							|tr = '%2 (%3) üzerinden %1 rota işlemi engellenemedi. Belge şu anda düzenleniyor olabilir.'");
	
	Try
		DocumentObject.Lock();
	Except
		MessageText = StrTemplate(ExceptionPattern, DocumentObject.Number, DocumentObject.Date, DocumentObject.Description);
		Common.MessageToUser(MessageText);
		Raise MessageText;
	EndTry;
	
EndProcedure

#EndRegion


#EndRegion

#Region Private


#Region AttributesOfWorkCenter

// Attributes of the work center.
// 
// Parameters:
//  WorkCenter - CatalogRef.WorkCenters,CatalogRef.WorkCenterTypes
// 
// Returns:
//  See ProductionAccountingClientServer.AttributesOfWorkCenterConstructor
Function AttributesOfWorkCenter(WorkCenter) Export
	
	Result = ProductionAccountingClientServer.AttributesOfWorkCenterConstructor();
	
	If ValueIsFilled(WorkCenter) Then
	
		Attributes = New Structure;
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters") Then
			Attributes.Insert("WorkCenter", "Ref");
			Attributes.Insert("WorkCenterType", "WorkCenterType");
			Attributes.Insert("UseSetupSettings", "WorkCenterType.SetupSettingsAreUsed");
			Attributes.Insert("WorkTimeFactor", "WorkTimeFactor");
			Attributes.Insert("ParallelLoad", "WorkCenterType.ParallelLoad");
			Attributes.Insert("UnitOfMeasureOfLoad", "WorkCenterType.UnitOfMeasureOfLoad");
		Else
			Attributes.Insert("WorkCenterType", "Ref");
			Attributes.Insert("UseSetupSettings", "SetupSettingsAreUsed");
			Attributes.Insert("ParallelLoad", "ParallelLoad");
			Attributes.Insert("UnitOfMeasureOfLoad", "UnitOfMeasureOfLoad");
		EndIf;
		FillPropertyValues(Result, Common.ObjectAttributesValues(WorkCenter, Attributes));
	
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ExecutionAndControlOfProductionOperations

Procedure SetStatusRegistrationInListOfProductionOperations(Rows) Export
	
	RunningStatus = Enums.ProductionOperationStatuses.Running;
	StatusCompleted   = Enums.ProductionOperationStatuses.Executed;
	
	KeysList = Rows.GetKeys();
	
	For Each Var_Key In KeysList Do
		
		ListLine = Rows[Var_Key];
		Status       = ListLine.Data.Status;
		
		If ListLine.Data.QuantityUnderRevision > 0
			And Status = RunningStatus Then
				
			ListLine.Appearance["Status"].SetParameterValue(
				"Text", StrTemplate(NStr("vi = '%1, đang hoàn thiện';
										|ru = '%1, на доработке';
										|en = '%1, on revision'; fa = '%1, on revision';
										|it = '%1, in completamento';
										|pl = '%1, na dopracowaniu';
										|tr = '%1, revizyonda'"), RunningStatus));
		
		ElsIf ListLine.Data.FollowUp > 0
			And Status = StatusCompleted Then
				
			ListLine.Appearance["Status"].SetParameterValue(
				"Text", StrTemplate(NStr("vi = '%1, đang kiểm soát';
										|ru = '%1, на контроле';
										|en = '%1, under control'; fa = '%1, under control';
										|it = '%1, in controllo';
										|pl = '%1, na kontroli';
										|tr = '%1, kontrolde'"), StatusCompleted));
				
		ElsIf ListLine.Data.DefectiveGoodsCount > 0
			And Status = StatusCompleted Then
				
			ListLine.Appearance["Status"].SetParameterValue(
				"Text", StrTemplate(NStr("vi = '%1, là hàng hỏng';
										|ru = '%1, есть брак';
										|en = '%1, there is nonconformity'; fa = '%1, there is nonconformity';
										|it = '%1, c''è uno spazio';
										|pl = '%1, są wady';
										|tr = '%1, uygunsuzluk mevcut'"), StatusCompleted));
				
		EndIf;
		
	EndDo;
	
EndProcedure

Function ThereIsRightOfIndependentControlOfOperation(OperationObject) Export
	
	If Users.IsFullUser() Then
		Return True;
	EndIf;
	
	Individual = Common.ObjectAttributeValue(
		Users.CurrentUser(), "Individual");
	
	Return (Individual = OperationObject.Performer)
		And Users.RolesAvailable("ControlExecutedOperationsIndependently");
	
EndFunction

#EndRegion

#Region Other

Function CurShift(Department) Export

	CurrentDate = CurrentSessionDate();
	
	TempTablesManager = New TempTablesManager;
	
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(
	TempTablesManager,
	ProductionServer.DivisionWorkSchedules(Department).UnloadColumn("WorkScheduleCalendar"),
	BegOfDay(CurrentDate),
	CurrentDate);
	
	Query = New Query(
	"SELECT DISTINCT
	|	Schedules1.WorkScheduleCalendar AS Shift,
	|	MIN(DATEADD(Schedules1.ScheduleDate, MINUTE, HOUR(ISNULL(Schedules1.BeginTime, DATETIME(1, 1, 1))) * 60 + MINUTE(ISNULL(Schedules1.BeginTime, DATETIME(1, 1, 1))))) AS Date
	|FROM
	|	TTWorkSchedules AS Schedules1
	|
	|GROUP BY
	|	Schedules1.WorkScheduleCalendar,
	|	Schedules1.ScheduleDate
	|ORDER BY
	|	MIN(DATEADD(Schedules1.ScheduleDate, MINUTE, HOUR(ISNULL(Schedules1.BeginTime, DATETIME(1, 1, 1))) * 60 + MINUTE(ISNULL(Schedules1.BeginTime, DATETIME(1, 1, 1))))) DESC");
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Department", Department);
	
	Result = Query.Execute().Select();
	
	ShiftData = New Structure();
	
	While Result.Next() Do
	
		If Result.Date < CurrentSessionDate() Then
			
			ShiftData.Insert("Shift",Result.Shift);
			ShiftData.Insert("Date",Result.Date);
			
			Break;
		
		EndIf;
	
	EndDo;
	
	Return ShiftData;
EndFunction

// Calculating the workload of the work center and / or artist in hours.
//
// Parameters:
//  WorkCenter - CatalogRef.WorkCenters - The work center for which you want to calculate the download.
//  Performer - CatalogRef.Persons - The performer to calculate the download for.
//              - CatalogRef.Teams - The team for which you need to calculate the load.
//  Department - CatalogRef.BusinessStructure - Division for calculating the load for the current shift.
//
// Returns:
//   Structure - contains the result of the load calculation.
//
Function CalculateDownload(WorkCenter, Performer, Department) Export
	
	Load = New Structure("WorkCenter,Performer");
	
	If ValueIsFilled(WorkCenter) Then
		
		Query = RequestUpload(Department);
		
		Query.Text = StrReplace(Query.Text,"&RedefinedSelection","Operations.WorkCenter = &WorkCenter");
		
		Query.SetParameter("WorkCenter", WorkCenter);
		
		Result = Query.Execute().Select();
	
		If Result.Next() Then
			Load.WorkCenter = ?(Result.Load = NULL, 0, Round(Result.Load, 2));
		EndIf;
		
	Else
		Load.WorkCenter = 0;
	EndIf;
	
	If ValueIsFilled(Performer) Then
		
		Query = RequestUpload(Department);
		
		Query.Text = StrReplace(Query.Text,"&RedefinedSelection","Operations.Performer = &Performer");
		
		Query.SetParameter("Performer", Performer);
		
		Result = Query.Execute().Select();
	
		If Result.Next() Then
			Load.Performer = ?(Result.Load = NULL, 0, Round(Result.Load, 2));
		EndIf;
		
	Else
		Load.Performer = 0;
	EndIf;
	
	Return Load;
	
EndFunction

// Returns a request for calculating the workload of the work center and / or performer
Function RequestUpload(Department)
	
	Query = New Query(
	"SELECT
	|	SUM(CASE Operations.ExecutionTimeUnitOfMeasure
	|			WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
	|				THEN Operations.RunTime * 60
	|			WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
	|				THEN Operations.RunTime * 3600
	|			WHEN VALUE(Enum.TimeMeasureUnits.DAY)
	|				THEN Operations.RunTime * 86400
	|			WHEN VALUE(Enum.TimeMeasureUnits.Days1)
	|				THEN Operations.RunTime * 86400
	|			ELSE Operations.RunTime
	|		END) / 3600 AS Load
	|FROM
	|	Document.ProductionOperation2_2 AS Operations
	|WHERE
	|	&RedefinedSelection
	|	AND &ShiftSelection
	|	AND 	Operations.Status IN (
	|		VALUE(Enum.ProductionOperationStatuses.CreatedOn_),
	|		VALUE(Enum.ProductionOperationStatuses.Running))
	|	AND NOT Operations.DeletionMark");
	
	If Common.ObjectAttributeValue(Department, "UseShiftTasks") Then
		
		ShiftData = ProductionAccounting.CurShift(Department);
		
		If ValueIsFilled(ShiftData) Then
			Query.Text = StrReplace(Query.Text,"AND &ShiftSelection","AND Operations.ShiftTask.Date = &DATE");
		
			Query.SetParameter("Date",ShiftData.Date);
		Else
			Query.Text = StrReplace(Query.Text,"AND &ShiftSelection","AND FALSE");
		EndIf;
		
	Else
		Query.Text = StrReplace(Query.Text,"AND &ShiftSelection","");
	EndIf;
	
	Return Query;
	
EndFunction


#EndRegion

#EndRegion


