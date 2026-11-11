#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	AccessibilityEditingMode = Parameters.AccessibilityEditingMode;
	
	DataAddressWCOperationSchedules = Parameters.DataAddressWCOperationSchedules;
	
	PeriodDate_ = Parameters.PeriodDate_;
	WorkCenterType = Parameters.WorkCenterType;
	PlanningInterval = Parameters.PlanningInterval;
	
	WorkplacePeriodStart = Parameters.BeginOfPeriod;
	WorkplacePeriodEnd = Parameters.PeriodEnding;
	
	BeginOfPeriod = PeriodDate_;
	PeriodEnding = ProductionPlanningClientServer.PlanningIntervalEnd(BeginOfPeriod, PlanningInterval);
	
	// Fill in the availability data entered in the workplace
	AvailabilityInformation_ = Parameters.AvailabilityInformation_;
	For Each PeriodAvailability In AvailabilityInformation_.AvailabilityForPeriod Do
		OwnerAvailability = AvailabilityInformationOwner.Add();
		OwnerAvailability.WorkCenterType = WorkCenterType;
		OwnerAvailability.IntervalDate = PeriodAvailability.PeriodDate_;
		
		If AvailabilityInformation_.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
			WorkCenterTypeScheduleTurnover = PeriodAvailability.Enabled1;
		ElsIf AvailabilityInformation_.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
			WorkCenterTypeScheduleTurnover = PeriodAvailability.Enabled2;
		ElsIf AvailabilityInformation_.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
			WorkCenterTypeScheduleTurnover = PeriodAvailability.Enabled3;
		Else
			WorkCenterTypeScheduleTurnover = 0;
		EndIf;
		If AvailabilityInformation_.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
			WorkCenterScheduleTurnover = PeriodAvailability.Enabled1;
		ElsIf AvailabilityInformation_.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
			WorkCenterScheduleTurnover = PeriodAvailability.Enabled2;
		ElsIf AvailabilityInformation_.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
			WorkCenterScheduleTurnover = PeriodAvailability.Enabled3;
		Else
			WorkCenterScheduleTurnover = 0;
		EndIf;
		If AvailabilityInformation_.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.ByProductionSchedule Then
			BusyTurnover = PeriodAvailability.Enabled1;
		ElsIf AvailabilityInformation_.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByProductionSchedule Then
			BusyTurnover = PeriodAvailability.Enabled2;
		ElsIf AvailabilityInformation_.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.ByProductionSchedule Then
			BusyTurnover = PeriodAvailability.Enabled3;
		Else
			BusyTurnover = 0;
		EndIf;
		
		OwnerAvailability.WorkCenterTypeScheduleTurnover = WorkCenterTypeScheduleTurnover;
		OwnerAvailability.WorkCenterScheduleTurnover = WorkCenterScheduleTurnover;
		OwnerAvailability.BusyTurnover = BusyTurnover;
		OwnerAvailability.AvailabilityShortage = BusyTurnover - WorkCenterScheduleTurnover;
	EndDo;
	
	// Create a copy of the work schedules
	NewScheduleOfRCWorkSchedules = DataProcessors.AvailabilityOfWorkCenterTypes.CreateTableScheduleOfRCWorkSchedules();
	ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(DataAddressWCOperationSchedules);
	TheStructureOfTheSearch = New Structure("WorkCenterType", WorkCenterType);
	StringsList = ScheduleOfWorkSchedulesOfRC.FindRows(TheStructureOfTheSearch);
	For Each ScheduleLine In StringsList Do
		FillPropertyValues(NewScheduleOfRCWorkSchedules.Add(), ScheduleLine);
	EndDo;
	NewDataAddressWCOperationSchedules = PutToTempStorage(NewScheduleOfRCWorkSchedules, UUID);
	
	TotalsAreDisplayedInTheTableFooter = (PlanningInterval = Enums.ProductionScheduleAccuracy.Day
										Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift
										Or PlanningInterval = Enums.ProductionScheduleAccuracy.Hour);
	
	ConfigureFormAccordingToParametersOfRCType();
	
	If TotalsAreDisplayedInTheTableFooter Then
		
		Items.TotalAvailable1.Visible = False;
		Items.TotalAvailable2.Visible = False;
		Items.TotalAvailable3.Visible = False;
		Items.TotalAvailable4.Visible = False;
		
		TotalWorkCenterKindAvailability.Load(AvailabilityInformationOwner.Unload());
		
	Else
		
		Items.BeginOfPeriod.Type = FormFieldType.LabelField;
		Items.BeginOfPeriod.Font = New Font(Items.BeginOfPeriod.Font,,, True);
		
		Items.PeriodEnding.Type = FormFieldType.LabelField;
		Items.PeriodEnding.Font = New Font(Items.PeriodEnding.Font,,, True);
		
		For Each OwnerAvailability In AvailabilityInformationOwner Do
			If OwnerAvailability.IntervalDate >= BeginOfPeriod
				And OwnerAvailability.IntervalDate <= PeriodEnding Then
				FillPropertyValues(TotalWorkCenterKindAvailability.Add(), OwnerAvailability);
			EndIf; 
		EndDo; 
		
	EndIf; 
	
	FillInData();
	
	OnlyChartView = AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule 
								And Not UserRightsCached.RightToEnterAvailabilityOfTypesOfRC() 
							Or AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable 
								And Not UserRightsCached.RightToEnterWorkSchedulesOfRC() 
							Or AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.ReadOnly;
		
	If OnlyChartView Then
		Items.CompleteEditing.Visible = False;
		Items.FillInTheScheduleAccordingToTheWorkCenterSchedule.Visible = False;
		Items.WCData.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		StandardProcessing = False;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Lịch trình đã được thay đổi. Lưu thay đổi?';
						|ru = 'Графики работы были изменены. Сохранить изменения?';
						|en = 'Work schedules were changed. Save the changes?'; fa = 'Work schedules were changed. Save the changes?';
						|it = 'Gli orari di lavoro sono stati modificati. Salvare le modifiche?';
						|pl = 'Harmonogramy wykonania pracy zostały zmienione. Zapisać zmiany?';
						|tr = 'Çalışma takvimleri değiştirildi. Değişiklikler kaydedilsin mi?'");
		
		CommonClient.ShowFormClosingConfirmation(ClosingNotification_, Cancel, Exit, QueryText,
			WarningText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If BeginOfPeriod < WorkplacePeriodStart Then
		BeginOfPeriod = WorkplacePeriodStart;
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Ngày bắt đầu không thể sớm hơn ngày %1';
										|ru = 'Дата начала не может быть раньше даты %1';
										|en = 'Start date cannot be earlier than date %1'; fa = 'Start date cannot be earlier than date %1';
										|it = 'La data dell''inizio non può essere inferiore alla data %1';
										|pl = 'Data rozpoczęcia nie może być wcześniejsza od daty %1';
										|tr = 'Başlangıç tarihi, %1 tarihinden önce olamaz'"),
									Format(WorkplacePeriodStart, "DLF=D"));
									
		CallbackDescription = New CallbackDescription("BeginOfPeriodOnChangeCompletion", ThisObject);
		ShowMessageBox(CallbackDescription, WarningText);
		Return;
		
	ElsIf BeginOfPeriod > WorkplacePeriodEnd Then
		BeginOfPeriod = WorkplacePeriodEnd;
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Ngày bắt đầu không thể muộn hơn ngày %1';
										|ru = 'Дата начала не может быть позже даты %1';
										|en = 'Start date cannot be later than date %1'; fa = 'Start date cannot be later than date %1';
										|it = 'La data dell''inizio non può essere superiore alla data %1';
										|pl = 'Data rozpoczęcia nie może być późniejsza od %1';
										|tr = 'Başlangıç tarihi, %1 tarihinden sonra olamaz'"),
									Format(WorkplacePeriodEnd, "DLF=D"));
									
		CallbackDescription = New CallbackDescription("BeginOfPeriodOnChangeCompletion", ThisObject);
		ShowMessageBox(CallbackDescription, WarningText);
		Return;
		
	EndIf;
	
	BeginOfPeriodOnChangeCompletion(Undefined);
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If PeriodEnding > WorkplacePeriodEnd Then
		PeriodEnding = WorkplacePeriodEnd;
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Ngày kết thúc không thể muộn hơn ngày %1';
										|ru = 'Дата окончания не может быть позже даты %1';
										|en = 'End date cannot be later than date %1'; fa = 'End date cannot be later than date %1';
										|it = 'La data del termine non può essere superiore alla data %1';
										|pl = 'Data zakończenia nie może być późniejsza daty %1';
										|tr = 'Bitiş tarihi, %1 tarihinden sonra olamaz'"),
									Format(WorkplacePeriodEnd, "DLF=D"));
									
		CallbackDescription = New CallbackDescription("PeriodEndingOnChangeCompletion", ThisObject);
		ShowMessageBox(CallbackDescription, WarningText);
		Return;
		
	ElsIf PeriodEnding < WorkplacePeriodStart Then
		PeriodEnding = WorkplacePeriodStart;
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Ngày kết thúc không thể sớm hơn ngày %1';
										|ru = 'Дата окончания не может быть раньше даты %1';
										|en = 'End date cannot be earlier than date %1'; fa = 'End date cannot be earlier than date %1';
										|it = 'La data del termine non può essere inferiore alla data %1';
										|pl = 'Data zakończenia nie może być wcześniejsza od daty %1';
										|tr = 'Bitiş tarihi, %1 tarihinden önce olamaz'"),
									Format(WorkplacePeriodStart, "DLF=D"));
									
		CallbackDescription = New CallbackDescription("PeriodEndingOnChangeCompletion", ThisObject);
		ShowMessageBox(CallbackDescription, WarningText);
		Return;
		
	EndIf;
	
	PeriodEndingOnChangeCompletion(Undefined);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWCData

// Plug-in event for the initial Selection
//
// Parameters:
//  Item - FormField -
//  ChoiceData - ValueList
//  StandardProcessing - Boolean -
//
&AtClient
Procedure Attachable_AccessibilityBeginningOfChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.WCData.CurrentData;
	
	ScheduleDate = DateAssociatedWithColumn(Item.Name);
	PeriodColumnName = PeriodColumnName(ScheduleDate);
	
	FormParameters = New Structure;
	FormParameters.Insert("ScheduleDate",                ScheduleDate);
	FormParameters.Insert("WorkCenterType",          WorkCenterType);
	FormParameters.Insert("WorkCenter",               CurrentData.WorkCenter);
	FormParameters.Insert("Shift",                      CurrentData.Shift);
	FormParameters.Insert("WorkSchedules",              GetWorkSchedules(CurrentData));
	FormParameters.Insert("DataAddressWCOperationSchedules", NewDataAddressWCOperationSchedules);
	FormParameters.Insert("ManualChangesMade",     CurrentData[PeriodColumnName + "ManualChangesMade"]);
	FormParameters.Insert("DataChanged1",             CurrentData[PeriodColumnName + "DataChanged1"]);
	FormParameters.Insert("OnlyChartView",      OnlyChartView);
	FormParameters.Insert("PlanningInterval",       PlanningInterval);
	
	ParametersOfPeriodToEdit = New Structure("ScheduleDate,Id", ScheduleDate, CurrentData.GetID());
	CallbackDescription = New CallbackDescription("SetScheduleCompletion", ThisObject, ParametersOfPeriodToEdit);
	OpenForm("DataProcessor.AvailabilityOfWorkCenterTypes.Form.WorkSchedule", FormParameters, ThisForm,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure Attachable_AccessibilityCleaning(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishEditingCommand(Command)
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure FillInTheScheduleAccordingToTheWorkCenterSchedule(Command)
	
	RCData = GetDataOnRC();
	
	If RCData <> Undefined And RCData.Count() > 0 Then
		FillInScheduleAccordingToScheduleOfWorkCenterOnServer(RCData);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region DataFilling

&AtServer
Procedure FillInData()

	WCData.Clear();
	
	UpdateAvailabilityColumns();
	SetConditionalAppearanceOfTable();
	FillInAvailability();
	ReflectOverlaysWithRepairs();
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityColumns()

	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding);
	
	ListOfNewDates = New Array;
	
	// Columns should be added in the order of their location on the form
	ColumnsList = New Array;
	AddColumnDescription("ManualChangesMade", 
							New TypeDescription("Boolean"), 
							False,
							ColumnsList);
							
	AddColumnDescription("Enabled", 
							New TypeDescription("Number", New NumberQualifiers(10, 2, AllowedSign.Nonnegative)), 
							True,
							ColumnsList);
							
	AddColumnDescription("AvailabilityOfSeconds", 
							New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)), 
							False,
							ColumnsList);
							
	// Service field, used when getting a schedule
	AddColumnDescription("DataChanged1", 
							New TypeDescription("Boolean"), 
							False,
							ColumnsList);
							
	AddColumnDescription("PlannedRepairs", 
							New TypeDescription("Boolean"), 
							False,
							ColumnsList);
							
	// We fill in the array of added details only with new columns.
	AttributesToAddArray = New Array;
	For Each PeriodDate_ In DatesOfSelectedPeriod Do
		
		If ListOfDisplayedDates.FindByValue(PeriodDate_) <> Undefined Then
			Continue;
		EndIf;
		
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		
		ListOfNewDates.Add(PeriodDate_);
		
		For Each ColumnDetails In ColumnsList Do
			ColumnName = PeriodColumnName + ColumnDetails.Name;
			NewColumn = New FormAttribute(ColumnName, ColumnDetails.Type, "WCData");
			AttributesToAddArray.Add(NewColumn);
		EndDo; 
		
	EndDo;
	
	// Delete unnecessary dates
	AttributesToDeleteArray = New Array;
	ListOfUnnecessaryDates = New Array;
	For Each EData In ListOfDisplayedDates Do
		PeriodDate_ = EData.Value;
		
		If DatesOfSelectedPeriod.Find(PeriodDate_) <> Undefined Then
			Continue;
		EndIf;
		
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		
		For Each ColumnDetails In ColumnsList Do
			ColumnName = PeriodColumnName + ColumnDetails.Name;
			AttributesToDeleteArray.Add("WCData." + ColumnName);
			If ColumnDetails.AvailableOnForm Then
				Items.Delete(Items.Find(ColumnName));
			EndIf; 
		EndDo; 
		Items.Delete(Items.Find(PeriodColumnName + "GroupAvailability"));
		
		Items.Delete(Items.Find(PeriodColumnName + "PeriodGroup"));
		
		ListOfUnnecessaryDates.Add(EData);
	EndDo;
	
	For Each EData In ListOfUnnecessaryDates Do
		ListOfDisplayedDates.Delete(EData);
	EndDo; 
	
	// We delete and add the details of the form.
	If AttributesToAddArray.Count() > 0 Or AttributesToDeleteArray.Count() > 0 Then
		ChangeAttributes(AttributesToAddArray, AttributesToDeleteArray);
	EndIf;
	
	// We add form elements, if there are none yet.
	For Each NewDate In ListOfNewDates Do
		
		ListOfDisplayedDates.Add(NewDate);
		
		PeriodColumnName = PeriodColumnName(NewDate);
		CurColumnTitle = PeriodColumnHeader(NewDate);
		
		// Find the column before which you need to add a new one
		ElementNextPeriod = Items.WCDataLastEmptyColumn;
		For Each ExistingColumn In Items.WCData.ChildItems Do
			
			If StrFind(ExistingColumn.Name, "PeriodGroup") = 0 Then
				Continue;
			EndIf;
			
			ExistingDateColumn = DateAssociatedWithColumn(ExistingColumn.Name);
			If ExistingDateColumn > NewDate Then
				
				ElementNextPeriod = ExistingColumn;
				Break;
				
			EndIf;
			
		EndDo;
		
		// Let's add a group in which new elements will be placed
		PeriodGroup_ = Items.Insert(PeriodColumnName + "PeriodGroup", 
											Type("FormGroup"), 
											Items.WCData, 
											ElementNextPeriod);
											
		PeriodGroup_.Title = CurColumnTitle;
		PeriodGroup_.Group = ColumnsGroup.Vertical;
		PeriodGroup_.ShowInHeader = True;
		PeriodGroup_.ShowTitle = True;
		
		// Adding elements
		NameOfNewElement = PeriodColumnName + "GroupAvailability";
		AvailabilityGroup = Items.Add(NameOfNewElement, Type("FormGroup"), PeriodGroup_);
		AvailabilityGroup.Group = ColumnsGroup.InCell;
		
		For Each ColumnDetails In ColumnsList Do
			
			NameOfNewElement = PeriodColumnName + ColumnDetails.Name;
			
			NewItem = Undefined;
			If ColumnDetails.Name = "Enabled" Then
				NewItem = Items.Add(NameOfNewElement, Type("FormField"), AvailabilityGroup);
				NewItem.Type = FormFieldType.InputField;
				NewItem.Width = 3;
				
				NewItem.SetAction("StartChoice", "Attachable_AccessibilityBeginningOfChoice");
				NewItem.SetAction("Clearing", "Attachable_AccessibilityCleaning");
				NewItem.ChoiceButtonPicture = PictureLib.Select;
				NewItem.TextEdit = False;
				NewItem.FooterHorizontalAlign = ItemHorizontalLocation.Right;
			EndIf; 
			
			// The same properties for all added elements
			If NewItem <> Undefined Then
				NewItem.DataPath = "WCData." + PeriodColumnName + ColumnDetails.Name;
				NewItem.HorizontalStretch = False;
				NewItem.ShowInHeader = False;
			EndIf; 
			
		EndDo; 
		
	EndDo;

EndProcedure

&AtServer
Procedure FillInAvailability()

	If BeginOfPeriod = '000101010000' 
		Or PeriodEnding = '000101010000' Then
		Return;
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	ProductionServer.CreateTTRTSSchedules(WorkCenterType, TempTablesManager, False, "TTWorkSchedules_");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
		"SELECT ALLOWED
		|	WorkCenters.Ref AS WorkCenter,
		|	WorkCenters.WorkTimeFactor AS WorkTimeFactor,
		|	ISNULL(WorkSchedules.WorkScheduleCalendar, VALUE(Catalog.Calendars.EmptyRef)) AS Shift,
		|	ISNULL(CAST(WorkSchedules.WorkScheduleCalendar AS Catalog.Calendars).Description, """") AS WorkScheduleCalendarPresentation
		|FROM
		|	Catalog.WorkCenters AS WorkCenters
		|
		|	LEFT JOIN TTWorkSchedules_ AS WorkSchedules
		|	ON WorkCenters.Ref = WorkSchedules.Ref
		|		AND &IntervalChange
		|WHERE
		|	WorkCenters.WorkCenterType = &WorkCenterType
		|	AND NOT WorkCenters.DeletionMark
		|
		|ORDER BY
		|	WorkCenters.Description,
		|	WorkScheduleCalendarPresentation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailabilityOfWorkCentersEnabled.WorkCenter AS WorkCenter,
		|	AvailabilityOfWorkCentersEnabled.Ref.ScheduleDate AS ScheduleDate,
		|	AvailabilityOfWorkCentersEnabled.Count AS Count,
		|	AvailabilityOfWorkCentersEnabled.ManualChangesMade AS ManualChangesMade,
		|	AvailabilityOfWorkCentersEnabled.Shift AS Shift
		|FROM
		|	Document.AvailabilityOfWorkCenters.Enabled AS AvailabilityOfWorkCentersEnabled
		|WHERE
		|	AvailabilityOfWorkCentersEnabled.Ref.WorkCenterType = &WorkCenterType
		|	AND AvailabilityOfWorkCentersEnabled.Ref.Posted
		|	AND AvailabilityOfWorkCentersEnabled.Ref.ScheduleDate BETWEEN &BeginOfPeriod AND &PeriodEnding
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WorkSchedules.Ref AS WorkCenter,
		|	WorkSchedules.WorkScheduleCalendar AS WorkScheduleCalendar,
		|	CAST(WorkSchedules.WorkScheduleCalendar AS Catalog.Calendars).Description AS WorkScheduleCalendarPresentation
		|FROM
		|	TTWorkSchedules_ AS WorkSchedules";
	
	Query.SetParameter("WorkCenterType", WorkCenterType);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("IntervalChange", PlanningInterval = Enums.ProductionScheduleAccuracy.Shift);
	
	Result = Query.ExecuteBatch();
	SampleRc = Result[0].Select();
	
	RCAvailability = Result[1].Unload();
	RCAvailability.Indexes.Add("WorkCenter, Shift");
	
	Schedules = Result[2].Unload();
	ValueToFormAttribute(Schedules, "WorkCenterSchedules");
	
	ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(NewDataAddressWCOperationSchedules);
	NewRCAvailability = ScheduleOfWorkSchedulesOfRC.Copy();
	NewRCAvailability.GroupBy("WorkCenter,Shift,ScheduleDate,ManualChangesMade", "Count");
	
	SearchStructureWorkCenterShift = New Structure("WorkCenter, Shift");
	SearchStructureWorkCenter = New Structure("WorkCenter");
	
	While SampleRc.Next() Do
		
		AvailabilityLine_ = WCData.Add();
		FillPropertyValues(AvailabilityLine_, SampleRc);
		
		FillPropertyValues(SearchStructureWorkCenterShift, SampleRc);
		
		// First let's take the new data
		StringsList = NewRCAvailability.FindRows(SearchStructureWorkCenterShift);
		For Each AvailabilityData In StringsList Do
			If AvailabilityData.ScheduleDate < BeginOfPeriod
				Or AvailabilityData.ScheduleDate > PeriodEnding Then
				// This is a different period
				Continue;
			EndIf; 
			
			PeriodColumnName = PeriodColumnName(AvailabilityData.ScheduleDate);
			AvailabilityLine_[PeriodColumnName + "Enabled"] = AvailabilityData.Count / 3600;
			AvailabilityLine_[PeriodColumnName + "AvailabilityOfSeconds"] = AvailabilityData.Count;
			AvailabilityLine_[PeriodColumnName + "ManualChangesMade"] = AvailabilityData.ManualChangesMade;
			AvailabilityLine_[PeriodColumnName + "DataChanged1"] = True;
		EndDo; 
		
		// Now let's take the data from the database
		StringsList = RCAvailability.FindRows(SearchStructureWorkCenterShift);
		For Each AvailabilityData In StringsList Do
			PeriodColumnName = PeriodColumnName(AvailabilityData.ScheduleDate);
			If AvailabilityLine_[PeriodColumnName + "DataChanged1"] Then
				Continue;
			EndIf;
			AvailabilityLine_[PeriodColumnName + "Enabled"] = AvailabilityData.Count / 3600;
			AvailabilityLine_[PeriodColumnName + "AvailabilityOfSeconds"] = AvailabilityData.Count;
			AvailabilityLine_[PeriodColumnName + "ManualChangesMade"] = AvailabilityData.ManualChangesMade;
		EndDo; 
		
		// Presentation of graphs
		If Not ValueIsFilled(AvailabilityLine_.WorkScheduleCalendarPresentation) Then
			FillPropertyValues(SearchStructureWorkCenter, SampleRc);
			StringsList = Schedules.FindRows(SearchStructureWorkCenter);
			For Each String In StringsList Do
				AvailabilityLine_.WorkScheduleCalendarPresentation = AvailabilityLine_.WorkScheduleCalendarPresentation
					+ ?(AvailabilityLine_.WorkScheduleCalendarPresentation = "", "", ", ")
					+ String.WorkScheduleCalendarPresentation;
			EndDo;
		EndIf;
		
	EndDo;
	
	FillInResults_();
	
EndProcedure

&AtServer
Procedure FillInResults_()

	// Updating the total for the RC and the deficit
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding);
	For Each PeriodDate_ In DatesOfSelectedPeriod Do
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		AvailabilityOfSeconds = 0;
		For Each AvailabilityLine_ In WCData Do
			AvailabilityOfSeconds = AvailabilityOfSeconds 
									+ AvailabilityLine_[PeriodColumnName + "AvailabilityOfSeconds"] 
									/ AvailabilityLine_.WorkTimeFactor;
		EndDo;
		
		TheStructureOfTheSearch = New Structure("IntervalDate", PeriodDate_);
	 	StringsList = TotalWorkCenterKindAvailability.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			LineTotal_ = TotalWorkCenterKindAvailability.Add();
			LineTotal_.IntervalDate = PeriodDate_;
			LineTotal_.WorkCenterType = WorkCenterType;
		Else
			LineTotal_ = StringsList[0];
		EndIf; 
		LineTotal_.WorkCenterScheduleTurnover = AvailabilityOfSeconds / 3600;
		LineTotal_.AvailabilityShortage = LineTotal_.BusyTurnover - LineTotal_.WorkCenterScheduleTurnover;
	EndDo; 
	
	// Output of results
	If TotalsAreDisplayedInTheTableFooter Then
		
		For Each DataOnAvailabilityOfRCType In TotalWorkCenterKindAvailability Do
			If DataOnAvailabilityOfRCType.IntervalDate < BeginOfPeriod
				Or DataOnAvailabilityOfRCType.IntervalDate > PeriodEnding Then
				Continue;
			EndIf;
			
			PeriodColumnName = PeriodColumnName(DataOnAvailabilityOfRCType.IntervalDate);
			
			FooterText = "";
			If Not DisplayingAvailability1.IsEmpty() Then
				FooterText = String(AccessibilityValue(DisplayingAvailability1, DataOnAvailabilityOfRCType));
			EndIf; 
			If Not DisplayingAvailability2.IsEmpty() Then
				FooterText = FooterText + ?(FooterText <> "", Chars.LF, "") + String(AccessibilityValue(DisplayingAvailability2, DataOnAvailabilityOfRCType));
			EndIf; 
			If Not DisplayingAvailability3.IsEmpty() Then
				FooterText = FooterText + ?(FooterText <> "", Chars.LF, "") + String(AccessibilityValue(DisplayingAvailability3, DataOnAvailabilityOfRCType));
			EndIf; 
			If Not DisplayingAvailability4.IsEmpty() Then
				FooterText = FooterText + ?(FooterText <> "", Chars.LF, "") + String(AccessibilityValue(DisplayingAvailability4, DataOnAvailabilityOfRCType));
			EndIf; 
			
			Items[PeriodColumnName + "Enabled"].FooterText = FooterText;
		EndDo;
		
	Else
		
		TotalAvailabilityOfRCTypeTotal = TotalWorkCenterKindAvailability.Unload();
		TotalAvailabilityOfRCTypeTotal.GroupBy("WorkCenterType", "BusyTurnover,WorkCenterTypeScheduleTurnover,WorkCenterScheduleTurnover,AvailabilityShortage");
		
		If TotalAvailabilityOfRCTypeTotal.Count() <> 0 Then
			DataOnAvailabilityOfRCType = TotalAvailabilityOfRCTypeTotal[0];
			TotalAvailable1 = AccessibilityValue(DisplayingAvailability1, DataOnAvailabilityOfRCType);
			TotalAvailable2 = AccessibilityValue(DisplayingAvailability2, DataOnAvailabilityOfRCType);
			TotalAvailable3 = AccessibilityValue(DisplayingAvailability3, DataOnAvailabilityOfRCType);
			TotalAvailable4 = AccessibilityValue(DisplayingAvailability4, DataOnAvailabilityOfRCType);
		Else
			TotalAvailable1 = 0;
			TotalAvailable2 = 0;
			TotalAvailable3 = 0;
			TotalAvailable4 = 0;
		EndIf; 
		
	EndIf; 
	
EndProcedure

&AtServer
Procedure ConfigureFormAccordingToParametersOfRCType()

	AttributesList = "UseAvailabilityAccordingToSchedule,PlanOperationsOfWorkCenters,EnterAvailabilityForWorkCenterType,AvailabilityReserve";
	DetailsOfRCType = Common.ObjectAttributesValues(WorkCenterType, AttributesList);
	
	AvailabilityReserve = DetailsOfRCType.AvailabilityReserve;
	If AvailabilityReserve = 0 Then
		Items.AvailabilityReserve.Visible = False;
		Items.SceneryAvailabilityReserve.Visible = False;
	EndIf; 
	
	// Let's determine which accessibility needs to be shown
	If DetailsOfRCType.UseAvailabilityAccordingToSchedule 
		And DetailsOfRCType.PlanOperationsOfWorkCenters
		And DetailsOfRCType.EnterAvailabilityForWorkCenterType Then
		
		DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.ByWorkCenterType;
		DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByProductionSchedule;
		DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
		DisplayingAvailability4 = Enums.AvailabilityDisplayOptions.AvailabilityShortage;
		
		If TotalsAreDisplayedInTheTableFooter Then
			
			// Availability totals are displayed in the table's basement
			Items.WCData.FooterHeight = 4;
			FooterText = String(Enums.AvailabilityDisplayOptions.ByWorkCenterType)
							+ Chars.LF + String(Enums.AvailabilityDisplayOptions.ByProductionSchedule)
							+ Chars.LF + String(Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule)
							+ Chars.LF + String(Enums.AvailabilityDisplayOptions.AvailabilityShortage);
			Items.WCDataWorkCenter.FooterText = FooterText;
		EndIf; 
	
	ElsIf DetailsOfRCType.UseAvailabilityAccordingToSchedule
		And Not DetailsOfRCType.EnterAvailabilityForWorkCenterType Then

		DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
		DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByProductionSchedule;
		DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.AvailabilityShortage;
		
		If TotalsAreDisplayedInTheTableFooter Then
			
			Items.WCData.FooterHeight = 3;
			FooterText = String(Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule)
							+ Chars.LF + String(Enums.AvailabilityDisplayOptions.ByProductionSchedule)
							+ Chars.LF + String(Enums.AvailabilityDisplayOptions.AvailabilityShortage);
			Items.WCDataWorkCenter.FooterText = FooterText;
		EndIf;
															
	Else
		
		DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
		
		If TotalsAreDisplayedInTheTableFooter Then
			Items.WCData.FooterHeight = 1;
			FooterText = String(Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule);
			Items.WCDataWorkCenter.FooterText = FooterText;
		EndIf; 
		
	EndIf; 

	If Not TotalsAreDisplayedInTheTableFooter Then
		
		// Hide the results under the table or set the necessary headers
		If Not DisplayingAvailability1.IsEmpty() Then
			Items.TotalAvailable1.Title = DisplayingAvailability1;
		Else
			Items.TotalAvailable1.Visible = False;
		EndIf; 
		If Not DisplayingAvailability2.IsEmpty() Then
			Items.TotalAvailable2.Title = DisplayingAvailability2;
		Else
			Items.TotalAvailable2.Visible = False;
		EndIf; 
		If Not DisplayingAvailability3.IsEmpty() Then
			Items.TotalAvailable3.Title = DisplayingAvailability3;
		Else
			Items.TotalAvailable3.Visible = False;
		EndIf; 
		If Not DisplayingAvailability4.IsEmpty() Then
			Items.TotalAvailable4.Title = DisplayingAvailability4;
		Else
			Items.TotalAvailable4.Visible = False;
		EndIf; 
		
		// Availability totals are displayed under the table
		Items.WCData.FooterHeight = 1;
		Items.WCDataWorkCenter.FooterText = NStr("vi = 'Tổng số:';
												|ru = 'Итого:';
												|en = 'Total:'; fa = 'جمع:';
												|it = 'Totale:';
												|pl = 'Total:';
												|tr = 'Toplam:'");
		
	EndIf; 
	
EndProcedure
 
&AtClientAtServerNoContext
Function DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding)
	
	DatesOfSelectedPeriod = New Array;
	
	If BeginOfPeriod = '000101010000' Or PeriodEnding = '000101010000' Then
		Return DatesOfSelectedPeriod;
	EndIf;
	
	PeriodDate_ = BeginOfPeriod;
	While PeriodDate_ <= PeriodEnding Do
		
		DatesOfSelectedPeriod.Add(PeriodDate_);
		PeriodDate_ = EndOfDay(PeriodDate_) + 1;
		
	EndDo;
	
	Return DatesOfSelectedPeriod;
	
EndFunction

&AtClientAtServerNoContext
Function DateAssociatedWithColumn(ColumnName)

	Return Date(Mid(ColumnName,2,8));

EndFunction

&AtServer
Procedure AddColumnDescription(ColumnName, TypeDetails, AvailableOnForm, ListOfAdditionalColumns)

	ColumnDetails = New Structure("Name,Type,AvailableOnForm", ColumnName, TypeDetails, AvailableOnForm);
	ListOfAdditionalColumns.Add(ColumnDetails);

EndProcedure

&AtClientAtServerNoContext
Function PeriodColumnName(CurrentPeriod)

	Return "_" + Format(CurrentPeriod, "DF=yyyyMMdd");

EndFunction

&AtServer
Function PeriodColumnHeader(PeriodDate_)
	
	Return ProductionAccounting.LineSchedulingInterval(PeriodDate_, Enums.ProductionScheduleAccuracy.Day);
	
EndFunction

&AtServer
Function AccessibilityValue(DisplayingAvailability, DataOnAvailabilityOfRCType)

	LineAvailability = 0;
	
	If DisplayingAvailability = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
		LineAvailability = DataOnAvailabilityOfRCType.WorkCenterTypeScheduleTurnover;
	ElsIf DisplayingAvailability = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
		LineAvailability = DataOnAvailabilityOfRCType.WorkCenterScheduleTurnover;
	ElsIf DisplayingAvailability = Enums.AvailabilityDisplayOptions.ByProductionSchedule Then
		LineAvailability = DataOnAvailabilityOfRCType.BusyTurnover;
	ElsIf DisplayingAvailability = Enums.AvailabilityDisplayOptions.AvailabilityShortage Then
		LineAvailability = DataOnAvailabilityOfRCType.AvailabilityShortage;
	EndIf;

	Return LineAvailability;
	
EndFunction

&AtServer
Procedure SetConditionalAppearanceOfTable()

	ConditionalAppearance.Items.Clear();
	
	// Highlighting manual changes in bold
	#Region ManualChangesMade
	For Each EData In ListOfDisplayedDates Do
		
		Item = ConditionalAppearance.Items.Add();
		
		PeriodDate_ = EData.Value;
		
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		AvailabilityFieldName = PeriodColumnName + "Enabled";
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(AvailabilityFieldName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("WCData." + PeriodColumnName + "ManualChangesMade");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Font", New Font(,,True));
		
	EndDo;	
	#EndRegion
	
	// Highlighting repairs in red
	#Region RM
	For Each EData In ListOfDisplayedDates Do
		
		Item = ConditionalAppearance.Items.Add();
		
		PeriodDate_ = EData.Value;
		
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		AvailabilityFieldName = PeriodColumnName + "Enabled";
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(AvailabilityFieldName);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("WCData." + PeriodColumnName + "PlannedRepairs");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
		
	EndDo;	
	#EndRegion
	
	
EndProcedure

&AtServer
Procedure ReflectOverlaysWithRepairs(ForTabularPart = False)
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	WorkCenterRM.WorkCenter,
	|	WorkCenterRM.StartDate,
	|	WorkCenterRM.CompletedOn
	|FROM
	|	InformationRegister.WorkCenterRM AS WorkCenterRM
	|WHERE
	|	WorkCenterRM.WorkCenter IN(&ListOfWorkCenters)
	|	AND WorkCenterRM.StartDate <= &PeriodEnding
	|	AND WorkCenterRM.CompletedOn >= &BeginOfPeriod";
	
	Query.SetParameter("BeginOfPeriod", BegOfDay(BeginOfPeriod));
	Query.SetParameter("PeriodEnding", EndOfDay(PeriodEnding));
	
	ListOfWorkCenters = WCData.Unload().UnloadColumn("WorkCenter");
	Query.SetParameter("ListOfWorkCenters", ListOfWorkCenters);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure("WorkCenter", Selection.WorkCenter);
		StringsList = WCData.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			Continue;
		EndIf;
		
		// We will determine the dates of the period for which the repair is planned
		DatesOfSelectedPeriod = DatesOfSelectedPeriod(
									Max(BegOfDay(Selection.StartDate), BeginOfPeriod), 
									Min(BegOfDay(Selection.CompletedOn), PeriodEnding));
									
		For Each ScheduleDate In DatesOfSelectedPeriod Do
			PeriodColumnName = PeriodColumnName(ScheduleDate);
			For Each RowData In StringsList Do
				RowData[PeriodColumnName + "PlannedRepairs"] = True;
			EndDo;
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region EditingWorkSchedules

// This is a description of the notification about the completion of the pluggable_availability procedure at the beginning of the Selection
//
// Parameters:
//  ClosingResult - Structure
//  AdditionalParameters - Structure - Contains:
//
&AtClient
Procedure SetScheduleCompletion(ClosingResult, AdditionalParameters) Export

	If Not OnlyChartView And ClosingResult <> Undefined Then
		SetCompletionScheduleOnServer(ClosingResult, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetCompletionScheduleOnServer(ClosingResult, AdditionalParameters)

	RCAvailabilityLine = WCData.FindByID(AdditionalParameters.Id);
	If RCAvailabilityLine = Undefined Then
		Return;
	EndIf;
	
	PeriodColumnName = PeriodColumnName(AdditionalParameters.ScheduleDate);
	
	ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(NewDataAddressWCOperationSchedules);
	
	// Delete the old data
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("WorkCenter", RCAvailabilityLine.WorkCenter);
	TheStructureOfTheSearch.Insert("Shift", RCAvailabilityLine.Shift);
	TheStructureOfTheSearch.Insert("ScheduleDate", AdditionalParameters.ScheduleDate);
	
	OldRCData = ScheduleOfWorkSchedulesOfRC.FindRows(TheStructureOfTheSearch);
	For Each ScheduleLine In OldRCData Do
		ScheduleOfWorkSchedulesOfRC.Delete(ScheduleLine);
	EndDo; 
	
	// Adding new data
	AvailabilityOfSeconds = 0;
	For Each IntervalData In ClosingResult.DaySchedule Do
		ScheduleLine = ScheduleOfWorkSchedulesOfRC.Add();
		ScheduleLine.WorkCenterType = WorkCenterType;
		ScheduleLine.WorkCenter = RCAvailabilityLine.WorkCenter;
		ScheduleLine.Shift = RCAvailabilityLine.Shift;
		ScheduleLine.ScheduleDate = AdditionalParameters.ScheduleDate;
		ScheduleLine.BeginTime = IntervalData.BeginTime;
		ScheduleLine.EndTime = IntervalData.EndTime;
		ScheduleLine.Count = IntervalData.Duration;
		ScheduleLine.ManualChangesMade = ClosingResult.ManualChangesMade;
		
		AvailabilityOfSeconds = AvailabilityOfSeconds + ScheduleLine.Count;
	EndDo; 
	
	// Update the data on the form
	RCAvailabilityLine[PeriodColumnName + "AvailabilityOfSeconds"] = AvailabilityOfSeconds;
	RCAvailabilityLine[PeriodColumnName + "Enabled"] = AvailabilityOfSeconds / 3600;
	RCAvailabilityLine[PeriodColumnName + "ManualChangesMade"] = ClosingResult.ManualChangesMade;
	RCAvailabilityLine[PeriodColumnName + "DataChanged1"] = True;
	
	PutToTempStorage(ScheduleOfWorkSchedulesOfRC, NewDataAddressWCOperationSchedules);
	
	FillInResults_();
	
	Modified = True;

EndProcedure

#EndRegion

#Region FillingInScheduleAccordingToSchedule

&AtClient
Function GetDataOnRC()

	SelectedRows = Items.WCData.SelectedRows;
	
	ClearMessages();
	
	If SelectedRows.Count() = 0 Then
		ErrorText = NStr("vi = 'Cần chọn nguồn lực sản xuất.';
						|ru = 'Необходимо выбрать рабочие центры.';
						|en = 'Select work centers.'; fa = 'Select work centers.';
						|it = 'È necessario selezionare i centri di lavoro.';
						|pl = 'Należy wybrać centra robocze.';
						|tr = 'İş merkezlerini seçmeniz gerekmektedir.'");
		CommonClientServer.MessageToUser(ErrorText, , "WCData");
		Return Undefined;
	EndIf;
	
	RCData = New Array;
	
	For Each String In SelectedRows Do
		
		SelectedRow = WCData.FindByID(String);
		
		If SelectedRow <> Undefined Then
			
			Cancel = False;
			
			LineNumber = WCData.IndexOf(SelectedRow) + 1;
			
			Schedules = GetWorkSchedules(SelectedRow);
			
			If Schedules = Undefined Then
				
				ErrorText = StrTemplate(NStr("vi = 'Dòng %1 không có lịch trình.';
											|ru = 'В строке %1 не указан график работы.';
											|en = 'Work schedule is not specified in line %1.'; fa = 'Work schedule is not specified in line %1.';
											|it = 'Nella riga %1 non è indicato l''orario di lavoro.';
											|pl = 'W wierszu %1 nie został podany harmonogram pracy.';
											|tr = '%1 satırında çalışma takvimi belirtilmedi.'"), LineNumber);
				CommonClientServer.MessageToUser(
					ErrorText,
					,
					CommonClientServer.PathToTabularSection("WCData", LineNumber, "WorkScheduleCalendar"),
					,
					Cancel);
				
			EndIf;
			If Not ValueIsFilled(SelectedRow.WorkCenter) Then
				
				ErrorText = StrTemplate(NStr("vi = 'Trong dòng %1 chưa chỉ định nguồn lực sản xuất.';
											|ru = 'В строке %1 не указан рабочий центр.';
											|en = 'Work center is not specified in line %1.'; fa = 'Work center is not specified in line %1.';
											|it = 'Nella riga %1 non è indicato il centro di lavoro.';
											|pl = 'W wierszu %1 nie zostało podane centrum robocze.';
											|tr = '%1 satırında iş merkezi belirtilmedi.'"), LineNumber);
				CommonClientServer.MessageToUser(
					ErrorText,
					,
					CommonClientServer.PathToTabularSection("WCData", LineNumber, "WorkCenter")
					,
					Cancel);
				
			EndIf;
			
			If Not Cancel Then
				
				DataElement = New Structure;
				DataElement.Insert("WorkCenter", SelectedRow.WorkCenter);
				DataElement.Insert("Shift", SelectedRow.Shift);
				DataElement.Insert("WorkSchedules", Schedules);
				DataElement.Insert("WorkTimeFactor", SelectedRow.WorkTimeFactor);
				
				RCData.Add(DataElement);
				
			EndIf;
			
		EndIf;
		
	EndDo;

	Return RCData;
	
EndFunction

&AtServer
Procedure FillInScheduleAccordingToScheduleOfWorkCenterOnServer(RCData)
	
	ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(NewDataAddressWCOperationSchedules);
	
	InformationAboutNewAvailabilityTable = DataProcessors.AvailabilityOfWorkCenterTypes.FillInWorkSchedulesOfRC(
										WorkCenterType, 
										RCData, 
										BeginOfPeriod, 
										PeriodEnding, 
										ScheduleOfWorkSchedulesOfRC,
										PlanningInterval);
	If InformationAboutNewAvailabilityTable = Undefined Then
		Return;
	EndIf;
	
	InformationAboutNewAvailabilityTable.GroupBy("WorkCenter,ScheduleDate,Shift", "Count");
	TheStructureOfTheSearch = New Structure("WorkCenter, Shift");
	
	// Update the data on the form
	For Each RCString In RCData Do
		
		FillPropertyValues(TheStructureOfTheSearch, RCString);
		
		StringsList = WCData.FindRows(TheStructureOfTheSearch);
		RCAvailabilityLine = StringsList[0];
		
		StringsList = InformationAboutNewAvailabilityTable.FindRows(TheStructureOfTheSearch);
		For Each NewAvailability In StringsList Do
			PeriodColumnName = PeriodColumnName(NewAvailability.ScheduleDate);
			RCAvailabilityLine[PeriodColumnName + "AvailabilityOfSeconds"] = NewAvailability.Count;
			RCAvailabilityLine[PeriodColumnName + "Enabled"] = NewAvailability.Count / 3600;
			RCAvailabilityLine[PeriodColumnName + "DataChanged1"] = True;
			RCAvailabilityLine[PeriodColumnName + "ManualChangesMade"] = False;
		EndDo;
		
	EndDo; 
	
	PutToTempStorage(ScheduleOfWorkSchedulesOfRC, NewDataAddressWCOperationSchedules);
	
	FillInResults_();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChangeCompletion(AdditionalParameters) Export
	
	If PeriodEnding < BeginOfPeriod Then
		BeginOfPeriod = PlanningIntervalStart(PeriodEnding, PlanningInterval);
	EndIf; 
	
	FillInData();
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChangeCompletion(AdditionalParameters) Export
	
	If BeginOfPeriod > PeriodEnding Then
		PeriodEnding = PlanningIntervalEnd(BeginOfPeriod, PlanningInterval);
	EndIf; 
	
	FillInData();
	
EndProcedure

&AtClient
Procedure CompleteEditing()
	
	ClearMessages();
	
	Cancel = False;
	SaveScheduleOfRCWorkSchedules(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	Close(NewAvailabilityDetails);
	
EndProcedure

&AtServer
Procedure SaveScheduleOfRCWorkSchedules(Cancel)

	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding);
	
	ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(DataAddressWCOperationSchedules);
	ScheduleOfWorkSchedulesOfRCCopy = ScheduleOfWorkSchedulesOfRC.Copy();
	
	NewScheduleOfRCWorkSchedules = GetFromTempStorage(NewDataAddressWCOperationSchedules);
	
	For Each AvailabilityLine_ In WCData Do
		For Each PeriodDate_ In DatesOfSelectedPeriod Do
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			
			// We will generate information about the new availability, which we will transmit to the workplace
			NewAvailability = NewAvailabilityDetails.Add();
			NewAvailability.ScheduleDate = PeriodDate_;
			NewAvailability.Count = AvailabilityLine_[PeriodColumnName + "AvailabilityOfSeconds"] / AvailabilityLine_.WorkTimeFactor;
			NewAvailability.ManualChangesMade = AvailabilityLine_[PeriodColumnName + "ManualChangesMade"];
			
			If Not AvailabilityLine_[PeriodColumnName + "DataChanged1"] Then
				Continue;
			EndIf;
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("WorkCenter", AvailabilityLine_.WorkCenter);
			TheStructureOfTheSearch.Insert("Shift", AvailabilityLine_.Shift);
			TheStructureOfTheSearch.Insert("ScheduleDate", PeriodDate_);
			
			// Delete the old data 
			OldRCData = ScheduleOfWorkSchedulesOfRC.FindRows(TheStructureOfTheSearch);
			For Each ScheduleLine In OldRCData Do
				ScheduleOfWorkSchedulesOfRC.Delete(ScheduleLine);
			EndDo; 
			
			// Let's add new ones
			NewDataOnRC = NewScheduleOfRCWorkSchedules.FindRows(TheStructureOfTheSearch);
			If NewDataOnRC.Count() <> 0 Then
				For Each ScheduleLine In NewDataOnRC Do
					NewSchedule = ScheduleOfWorkSchedulesOfRC.Add();
					FillPropertyValues(NewSchedule, ScheduleLine);
					NewSchedule.ManualChangesMade = AvailabilityLine_[PeriodColumnName + "ManualChangesMade"];
				EndDo; 
			Else
				NewSchedule = ScheduleOfWorkSchedulesOfRC.Add();
				NewSchedule.WorkCenterType = WorkCenterType;
				NewSchedule.WorkCenter = AvailabilityLine_.WorkCenter;
				NewSchedule.Shift = AvailabilityLine_.Shift;
				NewSchedule.ScheduleDate = PeriodDate_;
				NewSchedule.ManualChangesMade = AvailabilityLine_[PeriodColumnName + "ManualChangesMade"];
				NewSchedule.Count = 0;
			EndIf; 
			
		EndDo;
	EndDo;
	
	// Checking the intersection of intervals
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Shift
		And ScheduleOfWorkSchedulesOfRC.Count() > 0 Then
		ShiftsData = New ValueTable;
		ShiftsData.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
		ShiftsData.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
		ShiftsData.Columns.Add("ScheduleDate", New TypeDescription("Date"));
		ShiftsData.Columns.Add("RollingSchedule", New TypeDescription("Boolean"));
		ShiftsData.Columns.Add("EndDay", New TypeDescription("Date"));
		ShiftsData.Indexes.Add("WorkCenter, Shift, ScheduleDate");
		TheStructureOfTheSearch = New Structure("WorkCenter, Shift, ScheduleDate");
		
		Schedule = New ValueTable;
		Schedule.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
		Schedule.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
		Schedule.Columns.Add("ScheduleDate", New TypeDescription("Date"));
		Schedule.Columns.Add("BeginTime", New TypeDescription("Date"));
		Schedule.Columns.Add("EndTime", New TypeDescription("Date"));
		
		For IndexOf = 0 To ScheduleOfWorkSchedulesOfRC.Count()-1 Do
			ScheduleLine = ScheduleOfWorkSchedulesOfRC[IndexOf];
			If ScheduleLine.Count = 0 Then
				Continue;
			EndIf;
			FillPropertyValues(Schedule.Add(), ScheduleLine);
		EndDo;
		
		Query = New Query(
			"SELECT
			|	Schedule.WorkCenter AS WorkCenter,
			|	Schedule.Shift AS Shift,
			|	Schedule.ScheduleDate AS ScheduleDate
			|INTO TTSchedule
			|FROM
			|	&Schedule AS Schedule
			|
			|INDEX BY
			|	WorkCenter, Shift, ScheduleDate
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Intervals.WorkCenter AS WorkCenter,
			|	Intervals.Shift AS Shift,
			|	Intervals.ScheduleDate AS ScheduleDate,
			|	CAST(Intervals.BeginTime AS DATE) AS BeginTime,
			|	CAST(Intervals.EndTime AS DATE) AS EndTime
			|FROM
			|	Document.AvailabilityOfWorkCenters.Intervals AS Intervals
			|WHERE
			|	Intervals.Ref.Posted
			|	AND (Intervals.WorkCenter, Intervals.ScheduleDate) IN
			|		(SELECT
			|			T.WorkCenter AS WorkCenter,
			|			T.ScheduleDate AS ScheduleDate
			|		FROM
			|			TTSchedule AS T)
			|	AND (Intervals.WorkCenter, Intervals.ScheduleDate, Intervals.Shift) NOT IN
			|		(SELECT
			|			T.WorkCenter AS WorkCenter,
			|			T.ScheduleDate AS ScheduleDate,
			|			T.Shift AS Shift
			|		FROM
			|			TTSchedule AS T)
			|ORDER BY
			|	Intervals.WorkCenter,
			|	Intervals.LineNumber");
		Query.SetParameter("Schedule", ScheduleOfWorkSchedulesOfRC);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			FillPropertyValues(Schedule.Add(), Selection);
		EndDo;
		
		CheckingIntervals = New ValueTable;
		CheckingIntervals.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
		CheckingIntervals.Columns.Add("Begin", New TypeDescription("Date"));
		CheckingIntervals.Columns.Add("Ending", New TypeDescription("Date"));
		
		For IndexOf = 0 To Schedule.Count()-1 Do
			ScheduleLine = Schedule[IndexOf];
			
			FillPropertyValues(TheStructureOfTheSearch, ScheduleLine);
			FoundRows = ShiftsData.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() = 0 Then
				LineChange = ShiftsData.Add();
				FillPropertyValues(LineChange, ScheduleLine);
			Else
				LineChange = FoundRows[0];
			EndIf;
			
			VerificationLine = CheckingIntervals.Add();
			VerificationLine.WorkCenter = ScheduleLine.WorkCenter;
			VerificationLine.Begin = ScheduleLine.ScheduleDate
				+ Hour(ScheduleLine.BeginTime) * 3600
				+ Minute(ScheduleLine.BeginTime) * 60;
			
			If LineChange.RollingSchedule
					Or ScheduleLine.BeginTime < LineChange.EndDay Then
				// This schedule interval is completely located in the rolling shift
				If Not LineChange.RollingSchedule Then
					LineChange.RollingSchedule = True;
				EndIf;
				
				VerificationLine.Begin = VerificationLine.Begin + 86400;
				
				If ValueIsFilled(ScheduleLine.EndTime) Then
					VerificationLine.Ending = ScheduleLine.ScheduleDate
						+ Hour(ScheduleLine.EndTime) * 3600
						+ Minute(ScheduleLine.EndTime) * 60
						+ 86400;
				Else
					VerificationLine.Ending = EndOfDay(VerificationLine.Begin) + 1;
				EndIf;
			Else
				If Not ValueIsFilled(ScheduleLine.EndTime) Then
					LineChange.RollingSchedule = True;
					VerificationLine.Ending = EndOfDay(VerificationLine.Begin) + 1;
				ElsIf ScheduleLine.BeginTime = ScheduleLine.EndTime
					Or ScheduleLine.BeginTime > ScheduleLine.EndTime Then
					LineChange.RollingSchedule = True;
					VerificationLine.Ending = ScheduleLine.ScheduleDate
						+ Hour(ScheduleLine.EndTime) * 3600
						+ Minute(ScheduleLine.EndTime) * 60
						+ 86400;
				Else
					VerificationLine.Ending = ScheduleLine.ScheduleDate
						+ Hour(ScheduleLine.EndTime) * 3600
						+ Minute(ScheduleLine.EndTime) * 60;
				EndIf;
			EndIf;
			
			LineChange.EndDay = ScheduleLine.EndTime;
		EndDo;
		
		CheckingIntervals.Sort("WorkCenter, Begin, Ending");
		For IndexOf = 1 To CheckingIntervals.Count()-1 Do
			If CheckingIntervals[IndexOf].WorkCenter = CheckingIntervals[IndexOf-1].WorkCenter
				And CheckingIntervals[IndexOf].Begin < CheckingIntervals[IndexOf-1].Ending Then
				MessageText = StrTemplate(NStr("vi = 'Lịch trình của Năng lực sản xuất (Work Centers) ""%1"" trùng lặp %2.';
												|ru = 'Графики работы рабочего центра ""%1"" пересекаются %2.';
												|en = 'Work schedules of the ""%1"" work center overlap %2.'; fa = 'Work schedules of the ""%1"" work center overlap %2.';
												|it = 'Графики работы рабочего центра ""%1"" пересекаются %2.';
												|pl = 'Harmonogramy wykonania pracy centrum roboczego ""%1"" pokrywają się %2.';
												|tr = '""%1"" iş merkezinin çalışma programı %2 çakışmaktadır.'"),
					CheckingIntervals[IndexOf].WorkCenter,
					Format(CheckingIntervals[IndexOf].Begin, "DLF=D"));
				Common.MessageToUser(MessageText, CheckingIntervals[IndexOf].WorkCenter,,, Cancel);
				
				PutToTempStorage(ScheduleOfWorkSchedulesOfRCCopy, DataAddressWCOperationSchedules);
				NewAvailabilityDetails.Clear();
				
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	PutToTempStorage(ScheduleOfWorkSchedulesOfRC, DataAddressWCOperationSchedules);
	
EndProcedure

&AtClientAtServerNoContext
Function PlanningIntervalStart(PeriodDate_, PlanningInterval)

	If PeriodDate_ <> '000101010000' Then
		Return BegOfDay(ProductionPlanningClientServer.PlanningIntervalStart(PeriodDate_, PlanningInterval));
	Else
		Return '000101010000';
	EndIf;

EndFunction

&AtClientAtServerNoContext
Function PlanningIntervalEnd(PeriodDate_, PlanningInterval)

	If PeriodDate_ <> '000101010000' Then
		Return EndOfDay(ProductionPlanningClientServer.PlanningIntervalEnd(PeriodDate_, PlanningInterval));
	Else
		Return '000101010000';
	EndIf;

EndFunction

&AtClient
Function GetWorkSchedules(String)
	
	Result = Undefined;
	
	If String.Shift.IsEmpty() Then
		TheStructureOfTheSearch = New Structure("WorkCenter", String.WorkCenter);
		FoundRows = WorkCenterSchedules.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() <> 0 Then
			Result = New Array;
			For Each LineOfGraphics In FoundRows Do
				Result.Add(LineOfGraphics.WorkScheduleCalendar);
			EndDo;
		EndIf;
	Else
		Result = CommonClientServer.ValueInArray(String.Shift);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_PeriodEnding" Then
		PeriodEndingOnChange(Items.PeriodEnding);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
