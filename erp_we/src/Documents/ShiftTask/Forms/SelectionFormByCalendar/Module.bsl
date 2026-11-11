
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Department       = Parameters.Department;
	ProductionArea             = Parameters.ProductionArea;
	Statuses             = Parameters.Statuses;
	PreviouslySelectedShifts = Parameters.PreviouslySelectedShifts;
	MultipleChoice  = Parameters.MultipleChoice;
	
	If Statuses.Count() = 0 Then
		// A selection of documents in all statuses is available
		Statuses.Add(Enums.ShiftTaskStatuses.BeingGenerated);
		Statuses.Add(Enums.ShiftTaskStatuses.Generated_);
		Statuses.Add(Enums.ShiftTaskStatuses.Closed);
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Department", Department));
	UseAreas = GetFormFunctionalOption("UseProductionSites");
	
	Items.Decoration1.Visible = UseAreas;
	If Not UseAreas Or ThereArePlotsAtSubdivision(Department) Then
		Items.NoPlotsCreatedGroup.Visible = False;
	Else
		Items.NoPlotsCreatedGroup.Visible = True;
	EndIf;
	Items.Presentation.Title = ?(UseAreas,
		NStr("vi = 'Ca làm việc, Khu';
			|ru = 'Смена, Участок';
			|en = 'Shift, Site'; fa = 'Shift, Site';
			|it = 'Turno, Reparto';
			|pl = 'Zmiana, Działka';
			|tr = 'Vardiya, Saha'"),
		NStr("vi = 'Ca làm việc';
			|ru = 'Смена';
			|en = 'Shift'; fa = 'شیفت';
			|it = 'Turno';
			|pl = 'Shift';
			|tr = 'Vardiya'"));
	
	CountOfRows = 10;
	SeveralShiftsInDepartment = ProductionServer.DivisionWorkSchedules(Department).Count() > 1;
	
	InitializeShifts();
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductionAreaOnChange(Item)
	
	DisplayVisibleShiftsFromBeginning();
	
EndProcedure

&AtClient
Procedure ProductionAreaStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm(
		"DataProcessor.GenerateShiftTasks.Form.SelectAreas",
		New Structure("Department, SelectedValues", Department, ProductionArea),
		Item,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WarningNoPlotsCreatedURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#OpenStructureOfRC" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Department", Department);
		FormParameters.Insert("EditSections", True);
		
		CallbackDescription = New CallbackDescription("CreatingPlotsCompletion", ThisObject);
		
		OpenForm(
			"Catalog.WorkCenters.Form.WorkCenterStructure",
			FormParameters,
			ThisForm,,,,
			CallbackDescription);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVisibleShifts

&AtClient
Procedure VisibleShiftsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = VisibleShifts.FindByID(RowSelected);
	
	If CurrentData.CanBeSelected Then
		
		CurrentData.Selected_5 = Not CurrentData.Selected_5;
		WhenSelectingShift(CurrentData);
		
		If Not MultipleChoice Then
			ExecuteSelection();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Selected_5OnChange(Item)
	
	CurrentData = Items.VisibleShifts.CurrentData;
	WhenSelectingShift(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ExecuteSelection();
	
EndProcedure

&AtClient
Procedure Up(Command)
	
	CurrentRow = VisibleShifts[0];
	
	IndexOf = IndexOfNextShift(ThisForm, True, CurrentRow.OwnerIndex-1);
	
	If IndexOf <> Undefined Then
		AddRowToVisibleShifts(ThisObject, AllShifts[IndexOf], True);
	Else
		
		Ending = BegOfDay(AllShifts[CurrentRow.OwnerIndex].Date) - 1;
		
		ReadShifts(AddMonth(Ending, -1), Ending, True);
		
		IndexOf = IndexOfNextShift(ThisForm, True, CurrentRow.OwnerIndex-1);
		
		If IndexOf <> Undefined Then
			AddRowToVisibleShifts(ThisObject, AllShifts[IndexOf], True);
		Else
			ShowMessageBox(, NStr("vi = 'Dữ liệu biểu đồ không được điền';
									|ru = 'Данные графика не заполнены';
									|en = 'Schedule data is not filled in'; fa = 'Schedule data is not filled in';
									|it = 'Dati dell''orario non sono compilati';
									|pl = 'Dane harmonogramu nie są wypełnione';
									|tr = 'Program verileri doldurulmadı'"));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Down(Command)
	
	CurrentRow = VisibleShifts[CountOfRows-1];
	
	IndexOf = IndexOfNextShift(ThisForm, False, CurrentRow.OwnerIndex+1);
	
	If IndexOf <> Undefined Then
		AddRowToVisibleShifts(ThisObject, AllShifts[IndexOf], False);
	Else
		
		Begin = EndOfDay(AllShifts[CurrentRow.OwnerIndex].Date) + 1;
		
		ReadShifts(Begin, AddMonth(Begin, 1), False);
		
		IndexOf = IndexOfNextShift(ThisForm, False, CurrentRow.OwnerIndex+1);
		
		If IndexOf <> Undefined Then
			AddRowToVisibleShifts(ThisObject, AllShifts[IndexOf], False);
		Else
			ShowMessageBox(, NStr("vi = 'Dữ liệu biểu đồ không được điền';
									|ru = 'Данные графика не заполнены';
									|en = 'Schedule data is not filled in'; fa = 'Schedule data is not filled in';
									|it = 'Dati dell''orario non sono compilati';
									|pl = 'Dane harmonogramu nie są wypełnione';
									|tr = 'Program verileri doldurulmadı'"));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelSelect(Command)
	
	DeselectOnServer();
	
EndProcedure

&AtServer
Procedure DeselectOnServer()
	
	For Each String In AllShifts Do
		String.Selected_5 = False;
	EndDo;
	
	For Each String In VisibleShifts Do
		String.Selected_5 = False;
	EndDo;
	
	PreviouslySelectedShifts.Clear();
	
	NumberOfSelectedShifts = 0;
	
	CustomizeHintSelectedShift(ThisObject);
	
EndProcedure

&AtClient
Procedure GoToTheBeginningOfTheList(Command)
	
	DisplayVisibleShiftsFromBeginning();
	
EndProcedure

&AtClient
Procedure OpenJob(Command)
	
	CurrentData = Items.VisibleShifts.CurrentData;
	If CurrentData <> Undefined Then
		
		If Not AllShifts[CurrentData.OwnerIndex].ShiftTask.IsEmpty() Then
			ShowValue(, AllShifts[CurrentData.OwnerIndex].ShiftTask);
		Else
			ShowMessageBox(, NStr("vi = 'Nhiệm vụ không được tạo ra';
									|ru = 'Задание не создано';
									|en = 'Job is not created'; fa = 'Job is not created';
									|it = 'Il task non è stato creato';
									|pl = 'Zadanie nie utworzono';
									|tr = 'Görev oluşturulmadı'"));
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Gray font
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.VisibleShifts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VisibleShifts.ShiftTask");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// Explanation "the task has not been created"
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.JobStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VisibleShifts.ShiftTask");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tác vụ không được tạo>';
													|ru = '<задание не создано>';
													|en = '<task is not created>'; fa = '<task is not created>';
													|it = '<il task non è stato creato>';
													|pl = '<zadanie nie utworzono>';
													|tr = '<görev oluşturulmadı>'"));
	
	// Prohibition of shift selection
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Selected_5.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VisibleShifts.CanBeSelected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("Show", False);
	
EndProcedure

&AtServer
Procedure InitializeShifts()
	
	AllShifts.Clear();
	IndexListStart = -1;
	
	CurrentDate = BegOfDay(CurrentSessionDate());
	Begin = AddMonth(CurrentDate, -1);
	Ending = AddMonth(CurrentDate, 1);
	NumberOfSelectedShifts = 0;
	
	If PreviouslySelectedShifts.Count() > 0 Then
		
		Query = New Query(
			"SELECT
			|	MIN(BEGINOFPERIOD(ShiftTask.Date, DAY)) AS DateMin,
			|	MAX(ENDOFPERIOD(ShiftTask.Date, DAY)) AS DateMax,
			|	COUNT(ShiftTask.Ref)                 AS Count
			|FROM
			|	Document.ShiftTask AS ShiftTask
			|WHERE
			|	ShiftTask.Department = &Department
			|	AND ShiftTask.Ref IN(&PreviouslySelectedShifts)
			|	AND ShiftTask.Status IN(&Statuses)
			|	AND ShiftTask.Posted
			|
			|HAVING
			|	COUNT(ShiftTask.Ref) > 0");
		Query.SetParameter("Department", Department);
		Query.SetParameter("PreviouslySelectedShifts", PreviouslySelectedShifts.UnloadValues());
		Query.SetParameter("Statuses", Statuses.UnloadValues());
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			
			Begin = Min(Begin, Selection.DateMin);
			Ending = Max(Ending, Selection.DateMax);
			NumberOfSelectedShifts = Selection.Count;
			
		EndIf;
		
	EndIf;
	
	ReadShifts(Begin, Ending, False);
	
	ScrollingIsAvailable = AllShifts.Count() > CountOfRows;
	
	If AllShifts.Count() <> 0 Then
		
		For IndexOf = 0 To AllShifts.Count()-1 Do
			If AllShifts[IndexOf].Date >= CurrentDate Then
				IndexListStart = IndexOf;
				Break;
			EndIf;
		EndDo;
		
		If ScrollingIsAvailable And IndexListStart > AllShifts.Count()-CountOfRows Then
			IndexListStart = AllShifts.Count()-CountOfRows; // the list of visible shifts must contain the specified number of lines
		ElsIf IndexListStart = -1 Then
			IndexListStart = ?(ScrollingIsAvailable, AllShifts.Count()-CountOfRows, 0);
		EndIf;
		
		DisplayVisibleShiftsFromBeginning();
		
	EndIf;
	
	If ScrollingIsAvailable Then
		ListStartDate_ = AllShifts[IndexListStart].Date;
		If BegOfDay(ListStartDate_) = CurrentDate Then
			Items.GoToTheBeginningOfTheList.Title = StrTemplate(NStr("vi = '%1 hôm nay';
																	|ru = '%1 сегодня';
																	|en = '%1 today'; fa = '%1 today';
																	|it = '%1 oggi';
																	|pl = '%1 dzisiaj';
																	|tr = '%1 bugün'"), Format(ListStartDate_, "DLF=DD"));
		Else
			Items.GoToTheBeginningOfTheList.Title = Format(ListStartDate_, "DLF=DD");
		EndIf;
	EndIf;
	
	Items.GoToTheBeginningOfTheList.Visible = ScrollingIsAvailable;
	Items.Up.Enabled              = ScrollingIsAvailable;
	Items.Down.Enabled               = ScrollingIsAvailable;
	
	CustomizeHintSelectedShift(ThisObject);
	
EndProcedure

&AtServer
Procedure ReadShifts(Begin, Ending, AddToTop)
	
	Selection = SelectShiftsForPeriod(Begin, Ending);
	If Selection.Count() < CountOfRows Then
		
		If AllShifts.Count() = 0 Then
			Begin = '00010101';
			Ending = '39991231';
		ElsIf AddToTop Then
			Begin = '00010101';
		Else
			Ending = '39991231';
		EndIf;
		
		Selection = SelectShiftsForPeriod(Begin, Ending);
		
	EndIf;
	
	Reindexing = New Map;
	LineStartOfList = Undefined;
	If AddToTop Then
		
		For Each String In VisibleShifts Do
			Reindexing.Insert(VisibleShifts.IndexOf(String), AllShifts[String.OwnerIndex]);
		EndDo;
		
		If IndexListStart <> -1 Then
			LineStartOfList = AllShifts[IndexListStart];
		EndIf;
		
	EndIf;
	
	IndexOf = 0;
	While Selection.Next() Do
		
		If AddToTop Then
			NewRow = AllShifts.Insert(IndexOf);
			IndexOf = IndexOf + 1;
		Else
			NewRow = AllShifts.Add();
		EndIf;
		
		FillPropertyValues(NewRow, Selection);
		
	EndDo;
	
	If AddToTop Then
		
		For Each KeyAndValue In Reindexing Do
			VisibleShifts[KeyAndValue.Key].OwnerIndex = AllShifts.IndexOf(KeyAndValue.Value);
		EndDo;
		
		If IndexListStart <> -1 Then
			IndexListStart = AllShifts.IndexOf(LineStartOfList);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function SelectShiftsForPeriod(Begin, Ending)
	
	TempTablesManager = New TempTablesManager;
	Schedules = ProductionServer.DivisionWorkSchedules(Department).UnloadColumn("WorkScheduleCalendar");
	
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(
		TempTablesManager, Schedules, Begin, Ending, False);
	
	Query = New Query(
		"SELECT
		|	ProductionSites.Ref AS Ref
		|INTO TTPlots
		|FROM
		|	Catalog.ProductionSites AS ProductionSites
		|WHERE
		|	&UseAreas
		|	AND ProductionSites.Owner = &Department
		|	AND NOT ProductionSites.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Schedule.WorkScheduleCalendar AS Shift,
		|	ISNULL(TTPlots.Ref, VALUE(Catalog.ProductionSites.EmptyRef)) AS ProductionArea,
		|	MIN(
		|		CASE
		|			WHEN NOT &UseShifts
		|				THEN Schedule.ScheduleDate
		|			ELSE DATEADD(Schedule.ScheduleDate, MINUTE,
		|					HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))) * 60
		|					+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))
		|		END) AS Begin,
		|	MAX(
		|		CASE
		|			WHEN NOT &UseShifts
		|					OR Schedule.EndTime IS NULL
		|					OR Schedule.EndTime = DATETIME(1, 1, 1)
		|				THEN ENDOFPERIOD(Schedule.ScheduleDate, DAY)
		|			ELSE DATEADD(Schedule.ScheduleDate, MINUTE,
		|					HOUR(Schedule.EndTime) * 60
		|					+ MINUTE(Schedule.EndTime))
		|		END) AS Ending
		|INTO TTShifts
		|FROM
		|	TTWorkSchedules AS Schedule
		|		LEFT JOIN TTPlots AS TTPlots
		|		ON (TRUE)
		|WHERE
		|	(NOT &UseAreas
		|		OR TTPlots.Ref IS NOT NULL )
		|
		|GROUP BY
		|	Schedule.WorkScheduleCalendar,
		|	Schedule.Period,
		|	ISNULL(TTPlots.Ref, VALUE(Catalog.ProductionSites.EmptyRef))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ShiftTask.Ref                          AS Ref,
		|	ShiftTask.Status                          AS Status,
		|	ShiftTask.Date                            AS Date,
		|	ShiftTask.Shift                           AS Shift,
		|	ShiftTask.ProductionArea                         AS ProductionArea,
		|	ShiftTask.Ref IN (&PreviouslySelectedShifts)
		|		AND ShiftTask.Status IN (&Statuses)       AS Selected_5,
		|	ShiftTask.Status IN (&Statuses)             AS CanBeSelected
		|INTO TTJobs
		|FROM
		|	Document.ShiftTask AS ShiftTask
		|WHERE
		|	ShiftTask.Department = &Department
		|	AND ShiftTask.Posted
		|	AND ShiftTask.Date BETWEEN &Begin AND &Ending
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT                          
		|	TTShifts.Shift                                                  AS Shift,
		|	CAST(TTShifts.Shift AS Catalog.Calendars).Presentation AS ShiftPresentation,
		|	TTShifts.Begin                                                 AS Date,
		|	TTShifts.ProductionArea                                                AS ProductionArea,
		|	TTShifts.ProductionArea.Presentation                                  AS ProductionAreaPresentation,
		|	TTJobs.Ref                                               AS ShiftTask,
		|	TTJobs.Status                                               AS JobStatus,
		|	ISNULL(TTJobs.Selected_5, FALSE)                              AS Selected_5,
		|	ISNULL(TTJobs.CanBeSelected, TRUE)                      AS CanBeSelected
		|FROM
		|	TTShifts AS TTShifts
		|		LEFT JOIN TTJobs AS TTJobs
		|		ON TTShifts.Shift = TTJobs.Shift
		|			AND TTShifts.ProductionArea = TTJobs.ProductionArea
		|			AND TTJobs.Date BETWEEN TTShifts.Begin AND TTShifts.Ending
		|
		|UNION ALL
		|
		|SELECT
		|	TTJobs.Shift,
		|	TTJobs.Shift.Presentation,
		|	TTJobs.Date,
		|	TTJobs.ProductionArea,
		|	TTJobs.ProductionArea.Presentation,
		|	TTJobs.Ref,
		|	TTJobs.Status,
		|	TTJobs.Selected_5,
		|	TTJobs.CanBeSelected
		|FROM
		|	TTJobs AS TTJobs
		|		LEFT JOIN TTShifts AS TTShifts
		|		ON TTJobs.Shift = TTShifts.Shift
		|			AND TTJobs.ProductionArea = TTShifts.ProductionArea
		|			AND TTJobs.Date BETWEEN TTShifts.Begin AND TTShifts.Ending
		|WHERE
		|	TTShifts.Shift IS NULL
		|
		|ORDER BY
		|	Date,
		|	Shift,
		|	ProductionArea");
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	UseShifts = DivisionParameters.UseShifts;
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Department", Department);
	Query.SetParameter("Begin", Begin);
	Query.SetParameter("Ending", Ending);
	Query.SetParameter("PreviouslySelectedShifts", PreviouslySelectedShifts.UnloadValues());
	Query.SetParameter("Statuses", Statuses.UnloadValues());
	Query.SetParameter("UseAreas", UseAreas);
	Query.SetParameter("UseShifts", UseShifts);
	
	Return Query.Execute().Select();
	
EndFunction

&AtServer
Procedure DisplayVisibleShiftsFromBeginning()
	
	VisibleShifts.Clear();
	
	IndexOf = IndexOfNextShift(ThisForm, False, IndexListStart);
	
	While IndexOf <> Undefined Do
		
		AddRowToVisibleShifts(ThisObject, AllShifts[IndexOf], False);
		
		If VisibleShifts.Count() = CountOfRows Then
			Break;
		EndIf;
		
		IndexOf = IndexOfNextShift(ThisForm, False, IndexOf+1);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function IndexOfNextShift(Form, Up, Val IndexOf)
	
	If IndexOf < 0 Or IndexOf >= Form.AllShifts.Count() Then
		
		Return Undefined;
		
	ElsIf Not Form.UseAreas Or Form.ProductionArea.Count() = 0 Then
		
		Return IndexOf;
		
	Else
		
		Result = Undefined;
		
		If Up Then
			
			While IndexOf >= 0 Do
				
				If Form.ProductionArea.FindByValue(Form.AllShifts[IndexOf].ProductionArea) <> Undefined Then
					
					Result = IndexOf;
					Break;
					
				EndIf;
				
				IndexOf = IndexOf - 1;
				
			EndDo;
			
		Else
			
			While IndexOf < Form.AllShifts.Count() Do
				
				If Form.ProductionArea.FindByValue(Form.AllShifts[IndexOf].ProductionArea) <> Undefined Then
					
					Result = IndexOf;
					Break;
					
				EndIf;
				
				IndexOf = IndexOf + 1;
				
			EndDo;
			
		EndIf;
		
		Return Result;
		
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddRowToVisibleShifts(Form, Owner, AddToTop)
	
	VisibleShifts = Form.VisibleShifts;
	
	If AddToTop Then
		NewRow = VisibleShifts.Insert(0);
	Else
		NewRow = VisibleShifts.Add();
	EndIf;
	
	FillPropertyValues(NewRow, Owner, "ShiftTask, JobStatus, Selected_5, CanBeSelected");
	
	NewRow.Presentation = ProductionManagementClientServer.ShiftTaskPresentation_(
		Owner.ShiftPresentation,
		Owner.Date,
		Owner.ProductionAreaPresentation,
		Form.SeveralShiftsInDepartment);
	
	NewRow.OwnerIndex = Form.AllShifts.IndexOf(Owner);
	
	If VisibleShifts.Count() > Form.CountOfRows Then
		If AddToTop Then
			VisibleShifts.Delete(VisibleShifts.Count()-1);
		Else
			VisibleShifts.Delete(0);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenSelectingShift(CurrentData)
	
	AllShifts[CurrentData.OwnerIndex].Selected_5 = CurrentData.Selected_5;
	
	NumberOfSelectedShifts = NumberOfSelectedShifts + ?(CurrentData.Selected_5, 1, -1);
	
	CustomizeHintSelectedShift(ThisObject);
	
EndProcedure

&AtClient
Procedure ExecuteSelection()
	
	ClearMessages();
	
	Jobs = CreateAndGetSelectedTasks();
	
	If Jobs <> Undefined Then
		Close(New Structure("Jobs, ProductionArea", Jobs, ProductionArea));
	EndIf;
	
EndProcedure

&AtServer
Function CreateAndGetSelectedTasks()
	
	RowsSelected = AllShifts.FindRows(New Structure("Selected_5", True));
	
	If RowsSelected.Count() = 0 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không có ca làm việc được đánh dấu để lựa chọn';
												|ru = 'Не отмечены смены для выбора';
												|en = 'Shifts are not marked for selection'; fa = 'Shifts are not marked for selection';
												|it = 'Non sono specificati i turni per la selezione';
												|pl = 'Nie zaznaczono zmiany dla wyboru';
												|tr = 'Seçim için vardiya işaretlenmedi'"),, "VisibleShifts");
		Return Undefined;
	EndIf;
	
	References = New Array;
	ArrayOfFillInData = New Array;
	
	For Each String In RowsSelected Do
		
		If String.ShiftTask.IsEmpty() Then
			
			FillingData = Documents.ShiftTask.FillingData();
			FillingData.Department = Department;
			FillingData.FillInPerformersFromPreviousShift = FillInAssigneesFromThePreviousShift;
			
			FillPropertyValues(FillingData, String, "Date, Shift, ProductionArea");
			
			ArrayOfFillInData.Add(FillingData);
			
		Else
			References.Add(String.ShiftTask);
		EndIf;
		
	EndDo;
	
	If ArrayOfFillInData.Count() <> 0 Then
		
		NewLinks_ = Documents.ShiftTask.CreateJobs(ArrayOfFillInData);
		For Each Ref In NewLinks_ Do
			References.Add(Ref);
		EndDo;
		
	EndIf;
	
	Return References;
	
EndFunction

&AtClientAtServerNoContext
Procedure CustomizeHintSelectedShift(Form)
	
	If Form.NumberOfSelectedShifts <> 0 Then
		Form.Items.HintSelectedTasks.Title = StrTemplate(
			NStr("vi = 'Công việc được chọn: %1';
				|ru = 'Выбрано заданий: %1';
				|en = 'Selected jobs: %1'; fa = 'Selected jobs: %1';
				|it = 'Task selezionati: %1';
				|pl = 'Wybrano zadań: %1';
				|tr = 'Seçilen görevler: %1'"),
			Format(Form.NumberOfSelectedShifts, "NG=0"));
	EndIf;
	
	Form.Items.HintSelectedTasks.Visible = Form.NumberOfSelectedShifts <> 0;
	
EndProcedure

&AtServerNoContext
Function ThereArePlotsAtSubdivision(Department)
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Catalog.ProductionSites AS ProductionSites
		|WHERE
		|	ProductionSites.Owner = &Department
		|	AND NOT ProductionSites.DeletionMark");
	
	Query.SetParameter("Department", Department);
		
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtClient
Procedure CreatingPlotsCompletion(Result, Var_Parameters) Export
	
	If ThereArePlotsAtSubdivision(Department) Then
		
		Items.NoPlotsCreatedGroup.Visible = False;
		
		InitializeShifts();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	If Common.IsMobileClient() Then
		
		Items.CommandGroup.Visible                       = False;
		Items.Department.Visible                       = False;
		Items.GroupLot.Visible                       = False;
		Items.GoToTheBeginningOfTheList.Visible                = False;
		Items.FillInAssigneesFromThePreviousShift.Visible = False;
		
		Items.GroupShifts.Group     = ChildFormItemsGroup.Vertical;
		Items.GroupUpDown.Group = ChildFormItemsGroup.AlwaysHorizontal;
		
		Items.Up.HorizontalStretch = True;
		Items.Down.HorizontalStretch  = True;
		
	EndIf;
	
	Items.Selected_5.Visible                 = MultipleChoice;
	Items.CancelSelect.Visible           = MultipleChoice;
	Items.HintSelectedTasks.Visible = MultipleChoice;
	
EndProcedure

#EndRegion
