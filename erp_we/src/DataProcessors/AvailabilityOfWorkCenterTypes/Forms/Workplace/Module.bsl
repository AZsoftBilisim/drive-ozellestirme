#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	DonTLoadSelectionParameters = "";
	If Not ProcessFormParameters(DonTLoadSelectionParameters) Then
		
		FilterParameters = FormDataSettingsStorage.Load("AvailabilityOfWorkCenterTypes", "FilterParameters");
		If ValueIsFilled(FilterParameters) Then
			FillPropertyValues(ThisForm, FilterParameters,, DonTLoadSelectionParameters);
		EndIf;
		
		SaveFilterParameters = True;
		
	EndIf; 
	
	Items.TypeOfWorkCentersAvailability.RowFilter = New FixedStructure("NotShow", False);
	
	CustomizeForm();
	
	If AccessManagement.ReadingAllowed(FilterDepartment) Then
		
		ReadDivisionParameters();
		
		// The dates must correspond to the interval
		BeginOfPeriod = PlanningIntervalStart(BeginOfPeriod, PlanningInterval);
		PeriodEnding = PlanningIntervalEnd(PeriodEnding, PlanningInterval);
		
		FillInData();
		
	EndIf;
	
	WhenChangingAccessibilityEditingMode();
	
	TheCurrentEditModeAvailability = AccessibilityEditingMode;
	CurrentDepartment = FilterDepartment;
	CurrentStartOfThePeriod = BeginOfPeriod;
	CurrentEndOfThePeriod_3 = PeriodEnding;
	
	ConfigureDependentFormElements(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If NeedToRecordSetting() Then
		
		Cancel = True;
		StandardProcessing = False;
		
		If Exit Then
			WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veriler değiştirildi. Tüm değişiklikler kaybolacaktır.'");
			Return;
		EndIf;
		
		ShowQuestionRecordSetting("RecordSettingAndClose");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionOrder" Then
		If Not NeedToRecordSetting() Then
			UpdateDataWhenFormBecomesActive();
		EndIf; 
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AccessibilityEditingModeOnChange(Item)
	
	If AccessibilityEditingMode <> TheCurrentEditModeAvailability Then
	 	ShowQuestionRecordSetting("RecordSettingAndChangeOperatingMode");
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	If FilterDepartment <> CurrentDepartment Then
	 	ShowQuestionRecordSetting("RecordSettingAndChangeDivision");
	EndIf;
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If BeginOfPeriod <> CurrentStartOfThePeriod Then
		ShowQuestionRecordSetting("RecordSettingAndChangeStartOfPeriod");
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If PeriodEnding <> CurrentEndOfThePeriod_3 Then
		ShowQuestionRecordSetting("RecordSettingAndChangeEndOfPeriod");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTypeOfWorkCentersAvailability

&AtClient
Procedure TypeOfWorkCentersAvailabilitySelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.TypeOfWorkCentersAvailability.CurrentData;
	
	If Field.Name = "TypeOfWorkCentersAvailabilityWorkCenterType" Then
		
		StandardProcessing = False;
		ShowValue(,CurrentData.WorkCenterType);
		
	ElsIf Left(Field.Name, 1) = "_" Then
		
		If StrFind(Field.Name, "Enabled") <> 0 Then
			
			NumberOfDisplayedAvailability = Number(Right(Field.Name, 1));
			
			If CurrentData["DisplayingAvailability" + NumberOfDisplayedAvailability] 
					= PredefinedValue("Enum.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule") Then
				PeriodDate_ = DateAssociatedWithColumn(Field.Name);
				EnterWorkCenterSchedules(PeriodDate_, NumberOfDisplayedAvailability);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure


// Pluggable event handler when Changing for the Accessory1..N props
// 
// Parameters:
// 	Item - FormField - field for entering the details Availability 
&AtClient
Procedure Attachable_AccessibilityOfRCTypesAccessibilityWhenChanging(Item)
	
	CurrentData = Items.TypeOfWorkCentersAvailability.CurrentData;
	PeriodDate_ = DateAssociatedWithColumn(Item.Name); // 
	PeriodColumnName = PeriodColumnName(PeriodDate_);
	NumberOfDisplayedAvailability = Number(Right(Item.Name, 1));
	CurrentData[PeriodColumnName + "AvailabilityOfSeconds" + NumberOfDisplayedAvailability] = CurrentData[PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability] * 3600;
	
	WhenChangingAvailabilityInRow(CurrentData, PeriodDate_, NumberOfDisplayedAvailability);
	
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	FillInTotalInLine(CurrentData, NumberOfDisplayedAvailability, DatesOfSelectedPeriod, ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TheCommandToSaveTheChanges(Command)
	
	SaveSettings1();
	
EndProcedure

&AtClient
Procedure TheTeamToFillInTheAvailabilityForTheFormationOfSchedules(Command)
	
	If Items.TypeOfWorkCentersAvailability.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn dạng nguồn lực sản xuất.';
								|ru = 'Необходимо выбрать виды рабочих центров.';
								|en = 'Select work center types.'; fa = 'Select work center types.';
								|it = 'È necessario selezionare i tipi dei centri di lavoro.';
								|pl = 'Należy wybrać rodzaje centrów roboczych.';
								|tr = 'İş merkezi türlerini seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	FillInAvailabilityToCreateATimetable();
	
EndProcedure

&AtClient
Procedure TheTeamToFillInTheAvailabilityForTheFormationOfGraphics(Command)
	
	FillInAvailabilityToGenerateSchedule();
	
EndProcedure

&AtClient
Procedure ShowWhereManualChangesAreMadeCommand(Command)
	
	ShowWhereManualChangesWereMade = Not ShowWhereManualChangesWereMade;
	
	Items.TypesOfRCShowWhereManualChangesWereMade1.Check = ShowWhereManualChangesWereMade;
	Items.TypesOfRCShowWhereManualChangesWereMade2.Check = ShowWhereManualChangesWereMade;

	ShowWhereManualChangesWereMadeOnServer();
	
EndProcedure

&AtClient
Procedure UpdateDataCommand(Command)
	
 	ShowQuestionRecordSetting("RecordSettingAndUpdateData");
		
EndProcedure

&AtClient
Procedure CommandToSetThePeriodForInputAvailability(Command)
	
 	ShowQuestionRecordSetting("RecordSettingAndSetPeriodForEnteringAvailability");
	
EndProcedure

#EndRegion

#Region Private

#Region DataFilling

&AtServer
Procedure FillInData(SaveSelectionParameters = False)

	If SaveSelectionParameters Then
		SaveSelectionParameters();
	EndIf;
	
	// Let's remember the current view of the RC in order to make the desired line active later
	If CurrentWorkCenterKindInLine.IsEmpty() Then
		CurrentRow = Items.TypeOfWorkCentersAvailability.CurrentRow;
		If CurrentRow <> Undefined Then
			CurrentData = TypeOfWorkCentersAvailability.FindByID(CurrentRow);
			CurrentWorkCenterKindInLine = CurrentData.WorkCenterType;
		EndIf; 
	EndIf; 
	
	ScheduleOfWorkSchedulesOfRC = DataProcessors.AvailabilityOfWorkCenterTypes.CreateTableScheduleOfRCWorkSchedules();
	DataAddressWCOperationSchedules = PutToTempStorage(ScheduleOfWorkSchedulesOfRC, UUID);
	
	AvailabilityIsShownByWorkCenterKind = False;
	AvailabilityIsShownAccordingToTheWCSchedule = False;
	AvailabilityByProductionScheduleIsShown = False;
	
	WCScheduleFilledInUntil = '000101010000';
	ScheduleAvailabilityIsFilledInTo = '000101010000';
	
	TypeOfWorkCentersAvailability.Clear();
	
	UpdateAvailabilityColumns();
	SetConditionalAppearanceOfTable();
	FillInAvailability();
	ShowWhereManualChangesWereMadeOnServer();
	
	If AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule
		And PlanningIntervalEnd(ScheduleAvailabilityIsFilledInTo, PlanningInterval) < ScheduleAvailabilityShouldBeFilledInTo Then
		
		WorkScheduleDetails = CaptionAvailabilityForScheduleFillInBy;
		
	ElsIf AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable 
		And PlanningIntervalEnd(WCScheduleFilledInUntil, PlanningInterval) < WCScheduleToBeFilledInUntil Then
		
		WorkScheduleDetails = CaptionWCScheduleFillInBy;
		
	Else
		WorkScheduleDetails = "";
	EndIf; 
	
	If Not CurrentWorkCenterKindInLine.IsEmpty() Then
		TheStructureOfTheSearch = New Structure("WorkCenterType", CurrentWorkCenterKindInLine);
		StringsList = TypeOfWorkCentersAvailability.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			Items.TypeOfWorkCentersAvailability.CurrentRow = StringsList[0].GetID();
		EndIf; 
		CurrentWorkCenterKindInLine = Catalogs.WorkCenterTypes.EmptyRef();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityColumns()

	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	
	ListOfNewDates = New Array;
	
	// Columns should be added in the order of their location on the form
	TypeOfWatch = New TypeDescription("Number", New NumberQualifiers(10, 2, AllowedSign.Nonnegative));
	SecondType = New TypeDescription("Number", New NumberQualifiers(10,0, AllowedSign.Nonnegative));
	ColumnsList = New Array;
	AddColumnDescription("Show", New TypeDescription("Boolean"), False, 3, ColumnsList);
	AddColumnDescription("ManualChangesMade", New TypeDescription("Boolean"), False, 3, ColumnsList);
	AddColumnDescription("AvailabilityShortage", New TypeDescription("Boolean"), True, 3, ColumnsList);
	AddColumnDescription("Enabled", TypeOfWatch, True, 3, ColumnsList);
	AddColumnDescription("AvailabilityOfSeconds", SecondType, False, 3, ColumnsList);
	AddColumnDescription("AvailabilityTypeOfRC", SecondType, False, 1, ColumnsList);
	AddColumnDescription("RCAvailability", SecondType, False, 1, ColumnsList);
	AddColumnDescription("AvailabilitySchedule", SecondType, False, 1, ColumnsList);
	AddColumnDescription("DataChanged1", New TypeDescription("Boolean"), False, 3, ColumnsList);
	AddColumnDescription("AvailabilityFilled", New TypeDescription("Boolean"), False, 3, ColumnsList);
	
	// We fill in the array of added details only with new columns.
	AttributesToAddArray = New Array;
	For Each PeriodDate_ In DatesOfSelectedPeriod Do
		
		If ListOfDisplayedDates.FindByValue(PeriodDate_) <> Undefined Then
			Continue;
		EndIf;
		
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		
		ListOfNewDates.Add(PeriodDate_);
		
		For Each ColumnDetails In ColumnsList Do
			For NumberOfDisplayedAvailability = 1 To ColumnDetails.CopiesCount Do
				ColumnName = PeriodColumnName + ColumnDetails.Name + NumberOfDisplayedAvailability;
				NewColumn = New FormAttribute(ColumnName, ColumnDetails.Type, "TypeOfWorkCentersAvailability");
				AttributesToAddArray.Add(NewColumn);
			EndDo; 
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
			For NumberOfDisplayedAvailability = 1 To ColumnDetails.CopiesCount Do
				ColumnName = PeriodColumnName + ColumnDetails.Name + NumberOfDisplayedAvailability;
				AttributesToDeleteArray.Add("TypeOfWorkCentersAvailability." + ColumnName);
				If ColumnDetails.AvailableOnForm Then
					Items.Delete(Items.Find(ColumnName));
				EndIf; 
			EndDo; 
		EndDo; 
		
		Items.Delete(Items.Find(PeriodColumnName + "GroupAvailability1"));
		Items.Delete(Items.Find(PeriodColumnName + "GroupAvailability2"));
		Items.Delete(Items.Find(PeriodColumnName + "GroupAvailability3"));
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
		
		// Find the column before which you need to add a new one
		ElementNextPeriod = Items.TypeOfWorkCentersAvailabilityLastEmptyColumn;
		For Each ExistingColumn In Items.TypeOfWorkCentersAvailability.ChildItems Do
			
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
											Items.TypeOfWorkCentersAvailability, 
											ElementNextPeriod);
											
		PeriodGroup_.Group = ColumnsGroup.Vertical;
		PeriodGroup_.ShowInHeader = True;
		PeriodGroup_.ShowTitle = True;
		
		// Adding elements
		For NumberOfDisplayedAvailability = 1 To 3 Do
			
			NameOfNewElement = PeriodColumnName + "GroupAvailability" + NumberOfDisplayedAvailability;
			AvailabilityGroup = Items.Add(NameOfNewElement, Type("FormGroup"), PeriodGroup_);
			AvailabilityGroup.Group = ColumnsGroup.InCell;
			
			For Each ColumnDetails In ColumnsList Do
				
				NameOfNewElement = PeriodColumnName + ColumnDetails.Name + NumberOfDisplayedAvailability;
				
				NewItem = Undefined;
				If ColumnDetails.Name = "Enabled" Then
					NewItem = Items.Add(NameOfNewElement, Type("FormField"), AvailabilityGroup);
					NewItem.Type = FormFieldType.InputField;
					NewItem.Width = 5;
					NewItem.SetAction("OnChange", "Attachable_AccessibilityOfRCTypesAccessibilityWhenChanging");
					
				ElsIf ColumnDetails.Name = "AvailabilityShortage" Then
					NewItem = Items.Add(NameOfNewElement, Type("FormField"), AvailabilityGroup);
					NewItem.Type = FormFieldType.PictureField;
					NewItem.ValuesPicture = PictureLib.AvailabilityShortage;
				EndIf; 
				
				// The same properties for all added elements
				If NewItem <> Undefined Then
					NewItem.DataPath = "TypeOfWorkCentersAvailability." + PeriodColumnName + ColumnDetails.Name + NumberOfDisplayedAvailability;
					NewItem.HorizontalStretch = False;
					NewItem.ShowInHeader = False;
				EndIf; 
				
			EndDo; 
			
		EndDo;
		
	EndDo;

	// Update the date headers
	For Each EData In ListOfDisplayedDates Do
		PeriodDate_ = EData.Value;
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		PeriodGroup_ = Items[PeriodColumnName + "PeriodGroup"]; // FormGroup
		PeriodGroup_.Title = PeriodColumnHeader(PeriodDate_);
	EndDo; 
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfTable()

	ConditionalAppearance.Items.Clear();
	
	// Hide fields if accessibility display is not filled in
	#Region HideIfAccessibilityDisplayIsNotFull
	For NumberOfDisplayedAvailability = 1 To 3 Do
		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("AvailabilityOfRCViewsDisplayingAvailabilityOfImage" + NumberOfDisplayedAvailability);

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("AccessibilityOfRCViewsDisplayingEditingAccessibility" + NumberOfDisplayedAvailability);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("AvailabilityOfRCTypesAvailabilityIsIntroducedBy" + NumberOfDisplayedAvailability);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("AvailabilityOfRCTypesTotalAvailable" + NumberOfDisplayedAvailability);
		
		For Each EData In ListOfDisplayedDates Do
			
			PeriodDate_ = EData.Value;
			
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			
			ItemField = Item.Fields.Items.Add();
			FieldName = PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability;
			ItemField.Field = New DataCompositionField(FieldName);
			
			ItemField = Item.Fields.Items.Add();
			FieldName = PeriodColumnName + "AvailabilityShortage" + NumberOfDisplayedAvailability;
			ItemField.Field = New DataCompositionField(FieldName);
			
		EndDo;	
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.DisplayingAvailability" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

		Item.Appearance.SetParameterValue("Visible", False);
	EndDo; 
	#EndRegion
	
	// Prohibition of editing fields where availability by RC and by production schedule is displayed.
	#Region FieldEditingIsProhibited
	For NumberOfDisplayedAvailability = 1 To 3 Do
	
		Item = ConditionalAppearance.Items.Add();

		For Each EData In ListOfDisplayedDates Do
			
			PeriodDate_ = EData.Value;
			
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			AvailabilityFieldName = PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability;
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(AvailabilityFieldName);
			
		EndDo;	
		
		FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.DisplayingAvailability" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.AvailabilityDisplayOptions.ByProductionSchedule;

		ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.DisplayingAvailability" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
	EndDo; 
	#EndRegion

	// Output of zeros in the fields where availability is entered
	#Region ShowZeroIfAvailabilityIsEntered
	For NumberOfDisplayedAvailability = 1 To 3 Do
	
		Item = ConditionalAppearance.Items.Add();
			
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.DisplayEditAvailability" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Format", "NFD=2; NZ=0");
		
		// In the date fields
		For Each EData In ListOfDisplayedDates Do
			
			PeriodDate_ = EData.Value;
			
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			AvailabilityFieldName = PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability;
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(AvailabilityFieldName);
			
		EndDo;	
		
		// Final availability
		AvailabilityFieldName = "AvailabilityOfRCTypesTotalAvailable" + NumberOfDisplayedAvailability;
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(AvailabilityFieldName);
		
	EndDo;
	#EndRegion
		
	// Highlighting in red the date of completion of availability when entering availability for the schedule
	#Region RedAvailabilityIsFilledWithSoftwareForSchedule
	For NumberOfDisplayedAvailability = 1 To 3 Do
		Item = ConditionalAppearance.Items.Add();

		FieldName = "AvailabilityOfRCTypesAvailabilityIsIntroducedBy" + NumberOfDisplayedAvailability;
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldName);
		
		// There must be an availability input mode for the graph
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("AccessibilityEditingMode");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.AvailabilityIntroducedBy" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
		ItemFilter.RightValue = New DataCompositionField("ScheduleAvailabilityShouldBeFilledInTo");
		
		GroupSelectionOR = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		GroupSelectionOR.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		// If accessibility is entered for the type of RC
		GroupSelectionAnd = GroupSelectionOR.Items.Add(Type("DataCompositionFilterItemGroup"));
		GroupSelectionAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = GroupSelectionAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.EnterAvailabilityForWorkCenterType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = GroupSelectionAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.DisplayingAvailability" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.AvailabilityDisplayOptions.ByWorkCenterType;
		
		// If availability is entered for RC
		GroupSelectionAnd = GroupSelectionOR.Items.Add(Type("DataCompositionFilterItemGroup"));
		GroupSelectionAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = GroupSelectionAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.EnterAvailabilityForWorkCenterType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = GroupSelectionAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.DisplayingAvailability" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	EndDo;
	#EndRegion
	
	// Highlighting in red the date of filling in availability when entering availability to generate a schedule.
	#Region RedAvailabilityIsFilledInForWriting
	For NumberOfDisplayedAvailability = 1 To 3 Do
		Item = ConditionalAppearance.Items.Add();

		FieldName = "AvailabilityOfRCTypesAvailabilityIsIntroducedBy" + NumberOfDisplayedAvailability;
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FieldName);
		
		// There must be an availability input mode for the schedule
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("AccessibilityEditingMode");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.AvailabilityIntroducedBy" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
		ItemFilter.RightValue = New DataCompositionField("WCScheduleToBeFilledInUntil");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability.DisplayingAvailability" + NumberOfDisplayedAvailability);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	EndDo;
	#EndRegion
	
	// Highlighting manual changes in bold
	#Region ManualChangesMade
	For NumberOfDisplayedAvailability = 1 To 3 Do
	
		// In the date fields
		For Each EData In ListOfDisplayedDates Do
			
			Item = ConditionalAppearance.Items.Add();
			
			PeriodDate_ = EData.Value;
			
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			AvailabilityFieldName = PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability;
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(AvailabilityFieldName);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("TypeOfWorkCentersAvailability." + PeriodColumnName + "ManualChangesMade" + NumberOfDisplayedAvailability);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			Item.Appearance.SetParameterValue("Font", New Font(,,True));
			
		EndDo;	
		
	EndDo;
	#EndRegion
	
EndProcedure

&AtServer
Procedure FillInAvailability()

	If FilterDepartment.IsEmpty() 
		Or BeginOfPeriod = '000101010000' 
		Or PeriodEnding = '000101010000' Then
		
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	WorkCenterTypes.Ref,
	|	WorkCenterTypes.EnterAvailabilityForWorkCenterType,
	|	WorkCenterTypes.PlanOperationsOfWorkCenters,
	|	WorkCenterTypes.UseAvailabilityAccordingToSchedule
	|FROM
	|	Catalog.WorkCenterTypes AS WorkCenterTypes
	|WHERE
	|	WorkCenterTypes.Department = &Department
	|	AND NOT WorkCenterTypes.IsFolder
	|	AND NOT WorkCenterTypes.DeletionMark
	|	AND (&AccessibilityEditingMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule)
	|				AND WorkCenterTypes.UseAvailabilityAccordingToSchedule
	|			OR &AccessibilityEditingMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable)
	|				AND WorkCenterTypes.PlanOperationsOfWorkCenters
	|			OR &AccessibilityEditingMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.ReadOnly))
	|
	|ORDER BY
	|	WorkCenterTypes.Description
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(AvailabilityOfWorkCenterTypesTurnovers.BusyTurnover) AS BusyTurnover,
	|	SUM(AvailabilityOfWorkCenterTypesTurnovers.WorkCenterTypeScheduleTurnover) AS WorkCenterTypeScheduleTurnover,
	|	SUM(AvailabilityOfWorkCenterTypesTurnovers.WorkCenterScheduleTurnover) AS WorkCenterScheduleTurnover,
	|	AvailabilityOfWorkCenterTypesTurnovers.WorkCenterType AS WorkCenterType,
	|	BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, DAY) AS IntervalDate
	|FROM
	|	AccumulationRegister.AvailabilityOfWorkCenterTypes.Turnovers(,,,
	|		IntervalDate BETWEEN &BeginOfPeriod AND &PeriodEnding
	|		AND WorkCenterType.Department = &Department) AS AvailabilityOfWorkCenterTypesTurnovers
	|GROUP BY
	|	AvailabilityOfWorkCenterTypesTurnovers.WorkCenterType,
	|	BEGINOFPERIOD(AvailabilityOfWorkCenterTypesTurnovers.IntervalDate, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MAX(AvailabilityDates.ScheduleAvailabilityIsFilledInTo), DATETIME(1, 1, 1)) AS ScheduleAvailabilityIsFilledInTo,
	|	ISNULL(MAX(AvailabilityDates.WCScheduleFilledInUntil), DATETIME(1, 1, 1)) AS WCScheduleFilledInUntil
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN AvailabilityOfWorkCenterTypes.WorkCenterType.EnterAvailabilityForWorkCenterType
	|						AND AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenterType
	|					OR NOT AvailabilityOfWorkCenterTypes.WorkCenterType.EnterAvailabilityForWorkCenterType
	|						AND AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenters
	|				THEN AvailabilityOfWorkCenterTypes.IntervalDate
	|			ELSE DATETIME(1, 1, 1)
	|		END AS ScheduleAvailabilityIsFilledInTo,
	|		CASE
	|			WHEN AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenters
	|				THEN AvailabilityOfWorkCenterTypes.IntervalDate
	|			ELSE DATETIME(1, 1, 1)
	|		END AS WCScheduleFilledInUntil
	|	FROM
	|		AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
	|	WHERE
	|		AvailabilityOfWorkCenterTypes.WorkCenterType.Department = &Department
	|		AND AvailabilityOfWorkCenterTypes.IsRecordOfWorkCentersCapacityChange) AS AvailabilityDates
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AvailabilityOfWorkCenters.ScheduleDate,
	|	AvailabilityOfWorkCenters.WorkCenterType
	|FROM
	|	Document.AvailabilityOfWorkCenters AS AvailabilityOfWorkCenters
	|WHERE
	|	AvailabilityOfWorkCenters.Posted
	|	AND AvailabilityOfWorkCenters.ScheduleDate BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND AvailabilityOfWorkCenters.WorkCenterType.Department = &Department
	|	AND AvailabilityOfWorkCenters.ManualChangesMade";
	
	Query.SetParameter("Department", FilterDepartment);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", EndOfDay(PeriodEnding));
	Query.SetParameter("AccessibilityEditingMode", AccessibilityEditingMode);
	
	Result = Query.ExecuteBatch();
	SelectionOfRCTypes = Result[0].Select();
	
	TableAvailabilityOfRCTypes = Result[1].Unload();
	TableAvailabilityOfRCTypes.Indexes.Add("WorkCenterType");
	
	TableManualChanges = Result[3].Unload();
	TableManualChanges.Indexes.Add("WorkCenterType");
	
	AvailabilityDates = Result[2].Select();
	AvailabilityDates.Next();
	ScheduleAvailabilityIsFilledInTo = AvailabilityDates.ScheduleAvailabilityIsFilledInTo;
	WCScheduleFilledInUntil = AvailabilityDates.WCScheduleFilledInUntil;
	
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	
	While SelectionOfRCTypes.Next() Do
		
		AvailabilityLine_ = TypeOfWorkCentersAvailability.Add();
		AvailabilityLine_.WorkCenterType = SelectionOfRCTypes.Ref;
		AvailabilityLine_.EnterAvailabilityForWorkCenterType = SelectionOfRCTypes.EnterAvailabilityForWorkCenterType;
		
		// Let's determine which accessibility needs to be shown
		If SelectionOfRCTypes.UseAvailabilityAccordingToSchedule 
			And SelectionOfRCTypes.PlanOperationsOfWorkCenters
			And SelectionOfRCTypes.EnterAvailabilityForWorkCenterType Then
			
			AvailabilityLine_.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.ByWorkCenterType;
			AvailabilityLine_.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByProductionSchedule;
			AvailabilityLine_.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
			
			AvailabilityIsShownByWorkCenterKind = True;
			AvailabilityIsShownAccordingToTheWCSchedule = True;
			AvailabilityByProductionScheduleIsShown = True;
			
		ElsIf SelectionOfRCTypes.UseAvailabilityAccordingToSchedule
			And Not SelectionOfRCTypes.EnterAvailabilityForWorkCenterType Then

			AvailabilityLine_.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
			AvailabilityLine_.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByProductionSchedule;
			
			AvailabilityIsShownAccordingToTheWCSchedule = True;
			AvailabilityByProductionScheduleIsShown = True;
			
		ElsIf SelectionOfRCTypes.UseAvailabilityAccordingToSchedule
			And SelectionOfRCTypes.EnterAvailabilityForWorkCenterType Then

			AvailabilityLine_.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.ByWorkCenterType;
			AvailabilityLine_.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByProductionSchedule;
			
			AvailabilityIsShownByWorkCenterKind = True;
			AvailabilityByProductionScheduleIsShown = True;
			
		Else
			
			AvailabilityLine_.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule;
			
			AvailabilityIsShownAccordingToTheWCSchedule = True;
			
		EndIf; 
		
		FillInImageNumber(AvailabilityLine_, 1);
		FillInImageNumber(AvailabilityLine_, 2);
		FillInImageNumber(AvailabilityLine_, 3);
		
		// Filling in availability
		TheStructureOfTheSearch = New Structure("WorkCenterType", AvailabilityLine_.WorkCenterType);
		AvailabilityOfRCType = TableAvailabilityOfRCTypes.FindRows(TheStructureOfTheSearch);
		For Each DataOnAvailabilityOfRCType In AvailabilityOfRCType Do
			FillInAvailabilityLine(DataOnAvailabilityOfRCType.IntervalDate, 1, DataOnAvailabilityOfRCType, AvailabilityLine_);
			FillInAvailabilityLine(DataOnAvailabilityOfRCType.IntervalDate, 2, DataOnAvailabilityOfRCType, AvailabilityLine_);
			FillInAvailabilityLine(DataOnAvailabilityOfRCType.IntervalDate, 3, DataOnAvailabilityOfRCType, AvailabilityLine_);
		EndDo;
		
		// Filling in manual changes
		TheStructureOfTheSearch = New Structure("WorkCenterType", AvailabilityLine_.WorkCenterType);
		ManualChangesToRCView = TableManualChanges.FindRows(TheStructureOfTheSearch);
		For Each DataAboutManualChanges In ManualChangesToRCView Do
			IntervalDate = PlanningIntervalStart(DataAboutManualChanges.ScheduleDate, PlanningInterval);
			FillInManualChangesToLine(IntervalDate, 1, True, AvailabilityLine_);
			FillInManualChangesToLine(IntervalDate, 2, True, AvailabilityLine_);
			FillInManualChangesToLine(IntervalDate, 3, True, AvailabilityLine_);
		EndDo;
		
		FillInTotalInLine(AvailabilityLine_, 1, DatesOfSelectedPeriod, ThisForm);
		FillInTotalInLine(AvailabilityLine_, 2, DatesOfSelectedPeriod, ThisForm);
		FillInTotalInLine(AvailabilityLine_, 3, DatesOfSelectedPeriod, ThisForm);
		
	EndDo;

EndProcedure
 
&AtServer
Function ProcessFormParameters(DonTLoadSelectionParameters)

	ParametersProcessed = False;
	
	If Parameters.Property("WorkMode") Then
		
		AccessibilityEditingMode = Parameters.WorkMode;
		
	EndIf;
	
	If Parameters.Property("QuickFilterStructure")
		And Parameters.QuickFilterStructure.Property("Department") Then
		
		// Opening a form from the "Current Affairs" form
		FilterDepartment = Parameters.QuickFilterStructure.Department;
		AccessibilityEditingMode = Parameters.QuickFilterStructure.WorkMode;
		
		FillInPeriodForEnteringMissingAvailability();
		
		ParametersProcessed = True;
		
	ElsIf Parameters.Property("Department") Then
		
		FilterDepartment = Parameters.Department;
		AccessibilityEditingMode = Parameters.WorkMode;
		
		If Parameters.Property("EnteringMissingAvailability")
			And Parameters.EnteringMissingAvailability Then
			
			FillInPeriodForEnteringMissingAvailability();
		EndIf;
		
		ParametersProcessed = True;
		
	ElsIf Parameters.Property("WorkCenterType") Then
		
		// Opening a form for entering accessibility by type of RC
		CurrentWorkCenterKindInLine = Parameters.WorkCenterType;
		
		DetailsOfDivision = New Structure;
		DetailsOfDivision.Insert("Department", "Department");
		DetailsOfDivision.Insert("PlanningInterval", "Department.PlanningInterval");
		SetPrivilegedMode(True);
		DetailsOfDivision = Common.ObjectAttributesValues(CurrentWorkCenterKindInLine, DetailsOfDivision);
		SetPrivilegedMode(False);
		FilterDepartment = DetailsOfDivision.Department;
		PlanningInterval = DetailsOfDivision.PlanningInterval;
		
		BeginOfPeriod = PlanningIntervalStart(Parameters.BeginOfPeriod, PlanningInterval);
		PeriodEnding = PlanningIntervalEnd(BeginOfPeriod, PlanningInterval);
		
		ParametersProcessed = True;
		
	EndIf;
		
	Return ParametersProcessed;

EndFunction

&AtClientAtServerNoContext
Function DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval)
	
	DatesOfSelectedPeriod = New Array;
	
	If BeginOfPeriod = '000101010000' Or PeriodEnding = '000101010000' Then
		Return DatesOfSelectedPeriod;
	EndIf;
	
	PeriodDate_ = BeginOfPeriod;
	While PeriodDate_ <= PeriodEnding Do
		
		DatesOfSelectedPeriod.Add(PeriodDate_);
		PeriodDate_ = EndOfDay(ProductionPlanningClientServer.PlanningIntervalEnd(PeriodDate_, PlanningInterval)) + 1;
		
	EndDo;
	
	Return DatesOfSelectedPeriod;
	
EndFunction

&AtClientAtServerNoContext
Function PeriodColumnName(CurrentPeriod)

	Return "_" + Format(CurrentPeriod, "DF=yyyyMMdd");

EndFunction

&AtServer
Function PeriodColumnHeader(PeriodDate_)
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour
		Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Return ProductionAccounting.LineSchedulingInterval(PeriodDate_, Enums.ProductionScheduleAccuracy.Day);
	Else
		Return ProductionAccounting.LineSchedulingInterval(PeriodDate_, PlanningInterval);
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function DateAssociatedWithColumn(ColumnName)

	Return Date(Mid(ColumnName,2,8));

EndFunction

&AtServer
Procedure AddColumnDescription(ColumnName, TypeDetails, AvailableOnForm, CopiesCount, ListOfAdditionalColumns)

	ColumnDetails = New Structure;
	ColumnDetails.Insert("Name", ColumnName);
	ColumnDetails.Insert("Type", TypeDetails);
	ColumnDetails.Insert("AvailableOnForm", AvailableOnForm);
	ColumnDetails.Insert("CopiesCount", CopiesCount); 
	ListOfAdditionalColumns.Add(ColumnDetails);

EndProcedure

&AtServer
Procedure FillInImageNumber(AvailabilityLine_, NumberOfDisplayedAvailability)

	FieldName = "DisplayingAvailability" + NumberOfDisplayedAvailability;
	EditingAccessibility = False;
	
	If AvailabilityLine_[FieldName] = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
		PictureNumber = 1;
		If AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule Then
			EditingAccessibility = True;
		EndIf;
	ElsIf AvailabilityLine_[FieldName] = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
		PictureNumber = 2;
		If AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable 
			Or AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule
				And Not AvailabilityLine_.EnterAvailabilityForWorkCenterType Then
			EditingAccessibility = True;
		EndIf; 
	ElsIf AvailabilityLine_[FieldName] = Enums.AvailabilityDisplayOptions.ByProductionSchedule Then
		PictureNumber = 3;
	Else
		PictureNumber = 0;
	EndIf; 

	AvailabilityLine_["DisplayingAvailabilityPicture" + NumberOfDisplayedAvailability] = PictureNumber;
	AvailabilityLine_["DisplayEditAvailability" + NumberOfDisplayedAvailability] = EditingAccessibility;
	
EndProcedure
 
&AtServer
Procedure FillInAvailabilityLine(IntervalDate, NumberOfDisplayedAvailability, DataOnAvailabilityOfRCType, AvailabilityLine_)

	If PlanningIntervalStart(IntervalDate, PlanningInterval) <> IntervalDate Then
		// The data in the register does not correspond to the planning interval
		// This could happen when changing the scheduling interval.
		Return;
	EndIf;
	
	PeriodColumnName = PeriodColumnName(IntervalDate);
	
	AvailabilityFieldName = PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability;
	NameOfSecondsAvailabilityField = PeriodColumnName + "AvailabilityOfSeconds" + NumberOfDisplayedAvailability;
	NameOfDisplayAvailabilityField = "DisplayingAvailability" + NumberOfDisplayedAvailability;
	
	LineAvailability = 0;
	
	If AvailabilityLine_[NameOfDisplayAvailabilityField] = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
		LineAvailability = DataOnAvailabilityOfRCType.WorkCenterTypeScheduleTurnover;
	ElsIf AvailabilityLine_[NameOfDisplayAvailabilityField] = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
		LineAvailability = DataOnAvailabilityOfRCType.WorkCenterScheduleTurnover;
	ElsIf AvailabilityLine_[NameOfDisplayAvailabilityField] = Enums.AvailabilityDisplayOptions.ByProductionSchedule Then
		LineAvailability = DataOnAvailabilityOfRCType.BusyTurnover;
	EndIf;
	
	If LineAvailability <> 0 Then
		AvailabilityLine_[AvailabilityFieldName] = LineAvailability / 3600;
		AvailabilityLine_[NameOfSecondsAvailabilityField] = LineAvailability;
	EndIf; 
	
	WhenChangingAvailabilityInRow(AvailabilityLine_, IntervalDate, NumberOfDisplayedAvailability, False);
	
EndProcedure

&AtServer
Procedure FillInManualChangesToLine(IntervalDate, NumberOfDisplayedAvailability, ManualChangesMade, AvailabilityLine_)

	PeriodColumnName = PeriodColumnName(IntervalDate);
	
	NameOfDisplayAvailabilityField = "DisplayingAvailability" + NumberOfDisplayedAvailability;
	
	If AvailabilityLine_[NameOfDisplayAvailabilityField] = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
		FieldName = PeriodColumnName + "ManualChangesMade" + NumberOfDisplayedAvailability;
		AvailabilityLine_[FieldName] = ManualChangesMade;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure FillInTotalInLine(AvailabilityLine_, NumberOfDisplayedAvailability, DatesOfSelectedPeriod, Form)

	TotalAvailable = 0;
	TotalAvailabilityTypeOfRC = 0;
	TotalAvailabilitySchedule = 0;
	TotalAvailabilityOfTheRC = 0;
	AvailabilityIntroducedBy = '000101010000';
	
	For Each PeriodDate_ In DatesOfSelectedPeriod Do
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		
		NameOfSecondsAvailabilityField = PeriodColumnName + "AvailabilityOfSeconds" + NumberOfDisplayedAvailability;
		TotalAvailable = TotalAvailable + AvailabilityLine_[NameOfSecondsAvailabilityField];
		
		FieldName = PeriodColumnName + "AvailabilityTypeOfRC1";
		TotalAvailabilityTypeOfRC = TotalAvailabilityTypeOfRC + AvailabilityLine_[FieldName];
		
		FieldName = PeriodColumnName + "RCAvailability1";
		TotalAvailabilityOfTheRC = TotalAvailabilityOfTheRC + AvailabilityLine_[FieldName];
		
		FieldName = PeriodColumnName + "AvailabilitySchedule1";
		TotalAvailabilitySchedule = TotalAvailabilitySchedule + AvailabilityLine_[FieldName];
		
		If AvailabilityLine_[PeriodColumnName + "AvailabilityFilled" + NumberOfDisplayedAvailability] Then
			AvailabilityIntroducedBy = Max(PeriodDate_, AvailabilityIntroducedBy);
		EndIf;
	EndDo;
	
	AvailabilityLine_["TotalAvailable" + NumberOfDisplayedAvailability] = TotalAvailable / 3600;
	
	NameOfDisplayAvailabilityField = "DisplayingAvailability" + NumberOfDisplayedAvailability;
	AvailabilityFieldNameEnteredBy = "AvailabilityIntroducedBy" + NumberOfDisplayedAvailability;
	If AvailabilityLine_[NameOfDisplayAvailabilityField] = PredefinedValue("Enum.AvailabilityDisplayOptions.ByWorkCenterType") Then
		AvailabilityLine_[AvailabilityFieldNameEnteredBy] = Max(AvailabilityIntroducedBy, Form.ScheduleAvailabilityIsFilledInTo);
	ElsIf AvailabilityLine_[NameOfDisplayAvailabilityField] = PredefinedValue("Enum.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule") Then
		AvailabilityLine_[AvailabilityFieldNameEnteredBy] = Max(AvailabilityIntroducedBy, Form.WCScheduleFilledInUntil);
	Else
		AvailabilityLine_[AvailabilityFieldNameEnteredBy] = AvailabilityIntroducedBy;
	EndIf; 
	
	AvailabilityLine_.TotalAvailabilityTypeOfRC = TotalAvailabilityTypeOfRC;
	AvailabilityLine_.TotalAvailabilitySchedule = TotalAvailabilitySchedule;
	AvailabilityLine_.TotalAvailabilityOfTheRC = TotalAvailabilityOfTheRC;
	
EndProcedure

&AtServer
Procedure ReadDivisionParameters()

	PlanningInterval = Enums.ProductionScheduleAccuracy.EmptyRef();
	ScheduleAvailabilityShouldBeFilledInTo = '000101010000';
	WCScheduleToBeFilledInUntil = '000101010000';
	CaptionAvailabilityForScheduleFillInBy = "";
	CaptionWCScheduleFillInBy = "";
	
	If FilterDepartment.IsEmpty() Then
		Return;
	EndIf;
	
	AttributesList = "PlanningInterval";
	DetailsOfDivision = Common.ObjectAttributesValues(FilterDepartment, AttributesList);	
	PlanningInterval = DetailsOfDivision.PlanningInterval;
	
	// Let's determine by what date you need to fill in the availability
	AvailabilityYouNeedToFillInSoftware = Catalogs.BusinessStructure.AvailabilityYouNeedToFillInSoftware(FilterDepartment);
	ScheduleAvailabilityShouldBeFilledInTo = AvailabilityYouNeedToFillInSoftware.ScheduleAvailabilityShouldBeFilledInTo;
	If ScheduleAvailabilityShouldBeFilledInTo <> '000101010000' Then
		ScheduleAvailabilityShouldBeFilledInTo = PlanningIntervalEnd(
			ScheduleAvailabilityShouldBeFilledInTo, PlanningInterval);
		CaptionAvailabilityForScheduleFillInBy = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("vi = '(bắt buộc phải điền vào %1)';
													|ru = '(требуется заполнить по %1)';
													|en = '(required to fill in by %1)'; fa = '(required to fill in by %1)';
													|it = '(necessario compilare fino a %1)';
													|pl = '(wymaga wypełnienia do %1)';
													|tr = '(%1''e kadar doldurmanız gerekmektedir)'"),
												Format(ScheduleAvailabilityShouldBeFilledInTo, "DLF=D"));
	EndIf;

	WCScheduleToBeFilledInUntil = AvailabilityYouNeedToFillInSoftware.WCScheduleToBeFilledInUntil;
	If WCScheduleToBeFilledInUntil <> '000101010000' Then
		WCScheduleToBeFilledInUntil = PlanningIntervalEnd(
			WCScheduleToBeFilledInUntil, PlanningInterval);
		CaptionWCScheduleFillInBy = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("vi = '(bắt buộc phải điền vào %1)';
													|ru = '(требуется заполнить по %1)';
													|en = '(required to fill in by %1)'; fa = '(required to fill in by %1)';
													|it = '(necessario compilare fino a %1)';
													|pl = '(wymaga wypełnienia do %1)';
													|tr = '(%1''e kadar doldurmanız gerekmektedir)'"),
												Format(WCScheduleToBeFilledInUntil, "DLF=D"));
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.1, True);

EndProcedure

&AtServer
Procedure FillInPeriodForEnteringMissingAvailability()

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	DatesOfFilling.PlanningInterval AS PlanningInterval,
	|	ISNULL(MIN(DatesOfFilling.FilledInTo), &CurrentDate) AS BeginOfPeriod,
	|	ISNULL(MAX(DatesOfFilling.NumberOfIntervals_), 0) AS NumberOfIntervals_
	|FROM
	|	(SELECT
	|		BusinessStructure.PlanningInterval AS PlanningInterval,
	|		CASE
	|			WHEN &WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule)
	|				THEN WorkCenterTypes.Department.FillInAvailabilityForProductionScheduleIntervalQuantity
	|			ELSE WorkCenterTypes.Department.FillInAvailabilityForWorkCenterTimetableNumberOfIntervals
	|		END AS NumberOfIntervals_,
	|		ISNULL(MAX(AvailabilityOfWorkCenterTypes.IntervalDate), &CurrentDate) AS FilledInTo
	|	FROM
	|		Catalog.BusinessStructure AS BusinessStructure
	|			LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
	|			ON (WorkCenterTypes.Department = BusinessStructure.Ref)
	|				AND (&WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule)
	|						AND WorkCenterTypes.UseAvailabilityAccordingToSchedule
	|					OR &WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable)
	|						AND WorkCenterTypes.PlanOperationsOfWorkCenters)
	|				AND (NOT WorkCenterTypes.DeletionMark)
	|				AND (NOT WorkCenterTypes.IsFolder)
	|				AND (WorkCenterTypes.Department = &Department)
	|				AND (&WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule)
	|						AND BusinessStructure.FillInAvailabilityForProductionScheduleIntervalQuantity <> 0
	|					OR &WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable)
	|						AND BusinessStructure.FillInAvailabilityForWorkCenterTimetableNumberOfIntervals <> 0)
	|			LEFT JOIN AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
	|			ON (AvailabilityOfWorkCenterTypes.WorkCenterType = WorkCenterTypes.Ref)
	|				AND (AvailabilityOfWorkCenterTypes.IsRecordOfWorkCentersCapacityChange)
	|				AND (&WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule)
	|						AND (WorkCenterTypes.EnterAvailabilityForWorkCenterType
	|								AND AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenterType
	|							OR NOT WorkCenterTypes.EnterAvailabilityForWorkCenterType
	|								AND AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenters)
	|					OR &WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable)
	|						AND AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenters)
	|	WHERE
	|		BusinessStructure.Ref = &Department
	|	
	|	GROUP BY
	|		CASE
	|			WHEN &WorkMode = VALUE(Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule)
	|				THEN WorkCenterTypes.Department.FillInAvailabilityForProductionScheduleIntervalQuantity
	|			ELSE WorkCenterTypes.Department.FillInAvailabilityForWorkCenterTimetableNumberOfIntervals
	|		END,
	|		WorkCenterTypes.Ref,
	|		BusinessStructure.PlanningInterval) AS DatesOfFilling
	|
	|GROUP BY
	|	DatesOfFilling.PlanningInterval";
	
	CurrentDate = CurrentSessionDate();
	
	Query.SetParameter("Department", FilterDepartment);
	Query.SetParameter("WorkMode", AccessibilityEditingMode);
	Query.SetParameter("CurrentDate", CurrentDate);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;

	Selection = Result.Select();
	Selection.Next();
	
	BeginOfPeriod = Max(Selection.BeginOfPeriod, CurrentSessionDate());
	
	If Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour
		Or Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift
		Or Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		
		BeginOfPeriod = BegOfDay(BeginOfPeriod);
		PeriodEnding = EndOfDay(CurrentDate + Selection.NumberOfIntervals_ * 86400);
		
	ElsIf Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		
		BeginOfPeriod = BegOfWeek(BeginOfPeriod);
		PeriodEnding = EndOfWeek(CurrentDate + Selection.NumberOfIntervals_ * 86400 * 7);
		
	ElsIf Selection.PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		
		BeginOfPeriod = BegOfMonth(BeginOfPeriod);
		PeriodEnding = EndOfMonth(AddMonth(CurrentDate, Selection.NumberOfIntervals_));
		
	EndIf;
	
	PeriodEnding = Max(PeriodEnding, PlanningIntervalEnd(BeginOfPeriod, PlanningInterval));
	
	CurrentStartOfThePeriod = BeginOfPeriod;
	CurrentEndOfThePeriod_3 = PeriodEnding;
	
EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() Then
		FillInData();
		ConfigureDependentFormElements(ThisObject, "WorkScheduleDetails");
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf; 

EndProcedure

#EndRegion

#Region RecordAvailability

&AtClient
Function NeedToRecordSetting()

	Return (Modified And TypeOfWorkCentersAvailability.Count() <> 0);

EndFunction

&AtClient
Procedure ShowQuestionRecordSetting(NameOfProcedureToProcessResult)

	If NeedToRecordSetting() Then
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("ShowQuestionRecordSettingCompletion", ThisForm, NameOfProcedureToProcessResult);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		Modified = False;
		CallbackDescription = New CallbackDescription(NameOfProcedureToProcessResult, ThisForm);
		RunCallback(CallbackDescription, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQuestionRecordSettingCompletion(QuestionResult, NameOfProcedureToProcessResult) Export

	RecordingResult = True;
	
	If QuestionResult = DialogReturnCode.Yes Then
		RecordingResult = SaveSettings1();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
	ElsIf QuestionResult = DialogReturnCode.Cancel Then
		RecordingResult = False
	EndIf;
	
	CallbackDescription = New CallbackDescription(NameOfProcedureToProcessResult, ThisForm);
	RunCallback(CallbackDescription, RecordingResult);

EndProcedure

&AtClient
Function SaveSettings1()

	ClearMessages();
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	If Not RecordSettingOnServer() Then
		ShowMessageBox(,NStr("vi = 'Không thể ghi cài đặt.';
							|ru = 'Не удалось записать настройку.';
							|en = 'Cannot save the settings.'; fa = 'Cannot save the settings.';
							|it = 'Non è stato possibile registrare la configurazione.';
							|pl = 'Nie udało się zapisać ustawienie.';
							|tr = 'Ayar kaydedilemedi.'"));
		Return False;
	EndIf; 
	
	Notify("Write_AvailabilityOfWorkCenterTypes");
	
	Return True;

EndFunction

&AtServer
Function RecordSettingOnServer()
	
	QueryTexts = New Array;
	TempTablesManager = New TempTablesManager();
	
	References = TypeOfWorkCentersAvailability.Unload(, "WorkCenterType").UnloadColumn("WorkCenterType");
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		ProductionServer.CreateTTSchedulesForRCTypes(References, TempTablesManager, "TTWorkSchedules_");
	Else
		QueryText = 
			"SELECT TOP 0
			|	VALUE(Catalog.WorkCenterTypes.EmptyRef) AS Ref,
			|	VALUE(Catalog.Calendars.EmptyRef)          AS WorkScheduleCalendar
			|INTO TTWorkSchedules_";
		QueryTexts.Add(QueryText);
	EndIf;
	
	QueryText = 
		"SELECT
		|	AvailabilityOfWorkCenters.Ref AS Ref,
		|	AvailabilityOfWorkCenters.WorkCenterType AS WorkCenterType,
		|	AvailabilityOfWorkCenters.ScheduleDate AS ScheduleDate
		|INTO TTAvailabilityOfRC
		|FROM
		|	Document.AvailabilityOfWorkCenters AS AvailabilityOfWorkCenters
		|WHERE
		|	AvailabilityOfWorkCenters.Posted
		|	AND AvailabilityOfWorkCenters.WorkCenterType IN (&WorkCenterTypes)
		|	AND AvailabilityOfWorkCenters.ScheduleDate IN (&ScheduleDates)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailabilityOfWorkCenterType.Ref AS Ref,
		|	AvailabilityOfWorkCenterType.WorkCenterType AS WorkCenterType,
		|	AvailabilityOfWorkCenterType.IntervalDate AS IntervalDate
		|FROM
		|	Document.AvailabilityOfWorkCenterType AS AvailabilityOfWorkCenterType
		|WHERE
		|	AvailabilityOfWorkCenterType.Posted
		|	AND AvailabilityOfWorkCenterType.WorkCenterType IN (&WorkCenterTypes)
		|	AND AvailabilityOfWorkCenterType.IntervalDate IN (&DatesOfInterval)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailabilityOfWorkCenters.Ref AS Ref,
		|	AvailabilityOfWorkCenters.WorkCenterType AS WorkCenterType,
		|	AvailabilityOfWorkCenters.ScheduleDate AS ScheduleDate
		|FROM
		|	TTAvailabilityOfRC AS AvailabilityOfWorkCenters
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AvailabilityOfWorkCenters.Ref AS Ref,
		|	TabularSection.Shift AS Shift
		|FROM
		|	TTAvailabilityOfRC AS AvailabilityOfWorkCenters
		|
		|	INNER JOIN Document.AvailabilityOfWorkCenters.Enabled AS TabularSection
		|	ON AvailabilityOfWorkCenters.Ref = TabularSection.Ref
		|WHERE
		|	NOT TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTWorkSchedules_ AS Schedules
		|		WHERE
		|			Schedules.Ref = AvailabilityOfWorkCenters.WorkCenterType
		|			AND Schedules.WorkScheduleCalendar = TabularSection.Shift)
		|	AND TabularSection.Shift <> VALUE(Catalog.Calendars.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TabularSection.Ref       AS Ref,
		|	TabularSection.WorkCenter AS WorkCenter
		|FROM
		|	Document.AvailabilityOfWorkCenters.Enabled AS TabularSection
		|WHERE
		|	TabularSection.Ref IN (
		|		SELECT
		|			T.Ref
		|		FROM
		|			TTAvailabilityOfRC AS T)
		|	AND TabularSection.WorkCenter IN (
		|		SELECT
		|			T.Ref
		|		FROM
		|			Catalog.WorkCenters AS T
		|		WHERE
		|			T.WorkCenterType IN (&WorkCenterTypes)
		|			AND T.DeletionMark)";
	QueryTexts.Add(QueryText);
	
	QueryText = ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("WorkCenterTypes", References);
	Query.SetParameter("DatesOfInterval",
		DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval));
	
	ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(DataAddressWCOperationSchedules); // See DataProcessors.AvailabilityOfWorkCenterTypes.CreateTableScheduleOfRCWorkSchedules
	ScheduleDates = ScheduleOfWorkSchedulesOfRC.Copy(, "ScheduleDate");
	ScheduleDates.GroupBy("ScheduleDate");
	Query.SetParameter("ScheduleDates", ScheduleDates.UnloadColumn("ScheduleDate"));
	
	QueryResults = Query.ExecuteBatch();
	NumberOfResults = QueryResults.Count();
	
	AvailabilityOfWorkCenterTypes = QueryResults[NumberOfResults - 4].Unload();
	AvailabilityOfWorkCenterTypes.Indexes.Add("WorkCenterType, IntervalDate");
	
	AvailabilityOfWorkCenters = QueryResults[NumberOfResults - 3].Unload();
	AvailabilityOfWorkCenters.Indexes.Add("WorkCenterType, ScheduleDate");
	
	ShiftsToDelete = QueryResults[NumberOfResults - 2].Unload();
	ShiftsToDelete.Indexes.Add("Ref");
	
	WorkCentersToBeRemoved = QueryResults[NumberOfResults - 1].Unload();
	WorkCentersToBeRemoved.Indexes.Add("Ref");
	
	// Record availability by type of RC
	For Each AvailabilityLine_ In TypeOfWorkCentersAvailability Do
		If Not RecordAvailabilityByRCType(AvailabilityLine_, 1, AvailabilityOfWorkCenterTypes) 
			Or Not RecordAvailabilityByRCType(AvailabilityLine_, 2, AvailabilityOfWorkCenterTypes)
			Or Not RecordAvailabilityByRCType(AvailabilityLine_, 3, AvailabilityOfWorkCenterTypes) Then
			Return False
		EndIf;
	EndDo;
	
	// Recording the work schedule
	ScheduleByDate = ScheduleOfWorkSchedulesOfRC.Copy(); 
	ScheduleByDate.GroupBy("WorkCenterType,ScheduleDate");
	
	SearchTypeDate = New Structure("WorkCenterType, ScheduleDate");
	SearchForSmenaShoppingCenter = New Structure("WorkCenter, Shift");
	SearchForRC = New Structure("WorkCenter");
	SearchShift = New Structure("Shift");
	SearchARef = New Structure("Ref");
	
	ManualChanges = New ValueTable();
	ManualChanges.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	ManualChanges.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
	
	TableAvailability = New ValueTable();
	TableAvailability.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	TableAvailability.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
	TableAvailability.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers()));
	
	For Each DateAndTypeOfRC In ScheduleByDate Do
		WorkCenterType = DateAndTypeOfRC.WorkCenterType;
		ScheduleDate = DateAndTypeOfRC.ScheduleDate;
		
		SearchTypeDate.WorkCenterType = WorkCenterType;
		SearchTypeDate.ScheduleDate = ScheduleDate;
		
		AvailabilityOfRCType = AvailabilityOfWorkCenters.FindRows(SearchTypeDate);
		RCViewSchedule = ScheduleOfWorkSchedulesOfRC.FindRows(SearchTypeDate);
		
		Try
			If AvailabilityOfRCType.Count() <> 0 Then
				LineDocument = AvailabilityOfRCType[0]; // ValueTableRow
				DocumentObject = LineDocument.Ref.GetObject();
				DocumentObject.Lock();
				
				// Deleting old data
				For Each ScheduleLine In RCViewSchedule Do
					FillPropertyValues(SearchForSmenaShoppingCenter, ScheduleLine);
					
					For Each LineInterval In DocumentObject.Intervals.FindRows(SearchForSmenaShoppingCenter) Do
						DocumentObject.Intervals.Delete(LineInterval);
					EndDo;
					
					For Each AvailabilityLine_ In DocumentObject.Enabled.FindRows(SearchForSmenaShoppingCenter) Do
						DocumentObject.Enabled.Delete(AvailabilityLine_);
					EndDo;
				EndDo;
				
				SearchARef.Ref = DocumentObject.Ref;
				For Each LineChange In ShiftsToDelete.FindRows(SearchARef) Do
					SearchShift.Shift = LineChange.Shift;
					
					For Each LineInterval In DocumentObject.Intervals.FindRows(SearchShift) Do
						DocumentObject.Intervals.Delete(LineInterval);
					EndDo;
					
					For Each AvailabilityLine_ In DocumentObject.Enabled.FindRows(SearchShift) Do
						DocumentObject.Enabled.Delete(AvailabilityLine_);
					EndDo;
				EndDo;
				For Each LineWorkCenter In WorkCentersToBeRemoved.FindRows(SearchARef) Do
					SearchForRC.WorkCenter = LineWorkCenter.WorkCenter;
					
					For Each LineInterval In DocumentObject.Intervals.FindRows(SearchForRC) Do
						DocumentObject.Intervals.Delete(LineInterval);
					EndDo;
					
					For Each AvailabilityLine_ In DocumentObject.Enabled.FindRows(SearchForRC) Do
						DocumentObject.Enabled.Delete(AvailabilityLine_);
					EndDo;
				EndDo;
			Else
				DocumentObject = Documents.AvailabilityOfWorkCenters.CreateDocument();
				DocumentObject.Date = ScheduleDate;
				DocumentObject.WorkCenterType = WorkCenterType;
				DocumentObject.ScheduleDate = ScheduleDate;
			EndIf; 
			
			ManualChanges.Clear();
			TableAvailability.Clear();
			
			For Each ScheduleLine In RCViewSchedule Do
				If ScheduleLine.Count <> 0 Then
					LineInterval = DocumentObject.Intervals.Add();
					FillPropertyValues(LineInterval, ScheduleLine);
					LineInterval.ScheduleDate = ScheduleDate;
				EndIf;
				
				FillPropertyValues(TableAvailability.Add(), ScheduleLine);
				
				If ScheduleLine.ManualChangesMade Then
					FillPropertyValues(ManualChanges.Add(), ScheduleLine);
				EndIf;
			EndDo;
			
			TableAvailability.GroupBy("WorkCenter, Shift", "Count");
			
			For Each AvailabilityLine_ In TableAvailability Do
				NewRow = DocumentObject.Enabled.Add();
				FillPropertyValues(NewRow, AvailabilityLine_);
				
				FillPropertyValues(SearchForSmenaShoppingCenter, AvailabilityLine_);
				If ManualChanges.FindRows(SearchForSmenaShoppingCenter).Count() > 0 Then
					NewRow.ManualChangesMade = True;
				EndIf;
			EndDo;
			
			LineManualChanges = DocumentObject.Enabled.Find(True, "ManualChangesMade");
			DocumentObject.ManualChangesMade = LineManualChanges <> Undefined;
			
			DocumentObject.Write(DocumentWriteMode.Posting);
			If DocumentObject.IsLocked() Then
				DocumentObject.Unlock();
			EndIf;
		Except
			WriteLogEvent(NStr("vi = 'Nhập mức độ khả dụng của dạng nguồn lực làm việc';
								|ru = 'Ввод доступности видов рабочих центров';
								|en = 'Enter capacity of work center types'; fa = 'Enter capacity of work center types';
								|it = 'Ввод доступности видов рабочих центров';
								|pl = 'Enter capacity of work center types';
								|tr = 'İş merkezi türleri kapasitelerin girişi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return False;
		EndTry;
	EndDo;
	
	// Control of the feasibility of the existing production schedule
	If AccessibilityEditingMode =
		Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule Then
		CheckDownloadDoesNotExceedScheduleAvailability();
	EndIf;
	
	Modified = False;
	
	Return True;
	
EndFunction

&AtServer
Function RecordAvailabilityByRCType(AvailabilityLine_, NumberOfDisplayedAvailability, DocumentsTable)
	
	NameOfDisplayAvailabilityField = "DisplayingAvailability" + NumberOfDisplayedAvailability;
	If AvailabilityLine_[NameOfDisplayAvailabilityField] <> Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
		Return True;
	EndIf;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("WorkCenterType", AvailabilityLine_.WorkCenterType);
	TheStructureOfTheSearch.Insert("IntervalDate");
	
	For Each EData In ListOfDisplayedDates Do
		PeriodDate_ = EData.Value;
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		
		If Not AvailabilityLine_[PeriodColumnName + "DataChanged1" + NumberOfDisplayedAvailability] Then
			Continue;
		EndIf; 
		
		TheStructureOfTheSearch.IntervalDate = PeriodDate_;
		FoundRows = DocumentsTable.FindRows(TheStructureOfTheSearch);
		
		Try
			If FoundRows.Count() <> 0 Then
				DocumentTableRow = FoundRows[0]; // ValueTableRow
				DocumentObject = DocumentTableRow.Ref.GetObject();
				DocumentObject.Lock();
			Else
				DocumentObject = Documents.AvailabilityOfWorkCenterType.CreateDocument();
				DocumentObject.Date = PeriodDate_;
				DocumentObject.WorkCenterType = AvailabilityLine_.WorkCenterType;
				DocumentObject.IntervalDate = PeriodDate_;
			EndIf;
			
			DocumentObject.Count = AvailabilityLine_[PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability];
			DocumentObject.Write(DocumentWriteMode.Posting);
			If DocumentObject.IsLocked() Then
				DocumentObject.Unlock();
			EndIf;
		Except
			WriteLogEvent(NStr("vi = 'Nhập mức độ khả dụng của dạng nguồn lực làm việc';
								|ru = 'Ввод доступности видов рабочих центров';
								|en = 'Enter capacity of work center types'; fa = 'Enter capacity of work center types';
								|it = 'Ввод доступности видов рабочих центров';
								|pl = 'Enter capacity of work center types';
								|tr = 'İş merkezi türleri kapasitelerin girişi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return False;
		EndTry;
	EndDo;
	
	AvailabilityLine_[PeriodColumnName + "DataChanged1" + NumberOfDisplayedAvailability] = False;
	
	Return True;
	
EndFunction

&AtClient
Procedure RecordSettingAndClose(RecordingResult, AdditionalParameters = Undefined) Export

	If RecordingResult Then
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure RecordSettingAndUpdateData(RecordingResult, AdditionalParameters = Undefined) Export

	ClearMessages();
	
	If RecordingResult And CheckFilling() Then
		FillInData();
		ConfigureDependentFormElements(ThisObject, "WorkScheduleDetails");
	EndIf;

EndProcedure

&AtClient
Procedure RecordSettingAndChangeOperatingMode(RecordingResult, AdditionalParameters = Undefined) Export

	If RecordingResult Then
		ModeOfOperationWhenChangingOnServer();
	Else
		AccessibilityEditingMode = TheCurrentEditModeAvailability;
	EndIf;

EndProcedure

&AtClient
Procedure RecordSettingAndChangeDivision(RecordingResult, AdditionalParameters = Undefined) Export

	If RecordingResult Then
		FilterDivisionWhenChangedOnServer();
	Else
		FilterDepartment = CurrentDepartment;
	EndIf;

EndProcedure

&AtServer
Procedure ModeOfOperationWhenChangingOnServer()

	SaveSelectionParameters();
	
	FillInPeriodForEnteringMissingAvailability();
	
	FillInData();
	
	WhenChangingAccessibilityEditingMode();
	
	TheCurrentEditModeAvailability = AccessibilityEditingMode;
	
	ConfigureDependentFormElements(ThisObject, "WorkScheduleDetails");
	
EndProcedure

&AtServer
Procedure FilterDivisionWhenChangedOnServer()

	ReadDivisionParameters();
	
	FillInPeriodForEnteringMissingAvailability();
	
	SaveSelectionParameters();
	FillInData();
	CurrentDepartment = FilterDepartment;
	ConfigureDependentFormElements(ThisObject, "WorkScheduleDetails");
	
EndProcedure

&AtClient
Procedure RecordSettingAndChangeStartOfPeriod(RecordingResult, AdditionalParameters = Undefined) Export

	If RecordingResult Then
		
		BeginOfPeriod = PlanningIntervalStart(BeginOfPeriod, PlanningInterval);
		If BeginOfPeriod > PeriodEnding Then
			PeriodEnding = PlanningIntervalEnd(BeginOfPeriod, PlanningInterval);
		EndIf; 
		
		CallbackDescription = New CallbackDescription("BeginOfPeriodOnChangeCompletion", ThisObject);
		CheckForTooLongPeriod("BeginOfPeriod", CallbackDescription);
		
	Else
		BeginOfPeriod = CurrentStartOfThePeriod;
		PeriodEnding = CurrentEndOfThePeriod_3;
	EndIf;

EndProcedure

&AtClient
Procedure RecordSettingAndChangeEndOfPeriod(RecordingResult, AdditionalParameters = Undefined) Export

	If RecordingResult Then
		
		PeriodEnding = PlanningIntervalEnd(PeriodEnding, PlanningInterval);
		If PeriodEnding < BeginOfPeriod Then
			BeginOfPeriod = PlanningIntervalStart(PeriodEnding, PlanningInterval);
		EndIf;
		
		CallbackDescription = New CallbackDescription("PeriodEndingOnChangeCompletion", ThisObject);
		CheckForTooLongPeriod("PeriodEnding", CallbackDescription);
		
	Else
		BeginOfPeriod = CurrentStartOfThePeriod;
		PeriodEnding = CurrentEndOfThePeriod_3;
	EndIf;

EndProcedure

&AtClient
Procedure RecordSettingAndSetPeriodForEnteringAvailability(RecordingResult, AdditionalParameters = Undefined) Export

	If RecordingResult Then
		SetPeriodForEnteringAvailabilityOnServer();
	EndIf;

EndProcedure

&AtServer
Procedure CheckDownloadDoesNotExceedScheduleAvailability()
	
	Intervals = New ValueTable;
	Intervals.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	Intervals.Columns.Add("IntervalDate", New TypeDescription("Date"));
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		ShiftsData = New ValueTable;
		ShiftsData.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
		ShiftsData.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
		ShiftsData.Columns.Add("ScheduleDate", New TypeDescription("Date"));
		ShiftsData.Indexes.Add("WorkCenter, Shift, ScheduleDate");
		TheStructureOfTheSearch = New Structure("WorkCenter, Shift, ScheduleDate");
		
		Schedule = GetFromTempStorage(DataAddressWCOperationSchedules);
		For IndexOf = 0 To Schedule.Count()-1 Do
			String = Schedule[IndexOf];
			
			FillPropertyValues(TheStructureOfTheSearch, String);
			If ShiftsData.FindRows(TheStructureOfTheSearch).Count() > 0 Then
				Continue;
			EndIf;
			
			NewRow = Intervals.Add();
			NewRow.WorkCenterType = String.WorkCenterType;
			NewRow.IntervalDate = String.ScheduleDate
				+ Hour(String.BeginTime) * 3600
				+ Minute(String.BeginTime) * 60;
			
			FillPropertyValues(ShiftsData.Add(), String);
		EndDo;
		
		Intervals.GroupBy("WorkCenterType, IntervalDate");
	Else
		For Each String In TypeOfWorkCentersAvailability Do
			For Each Item In ListOfDisplayedDates Do
				If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
					For Hour = 0 To 23 Do
						NewRow = Intervals.Add();
						NewRow.WorkCenterType = String.WorkCenterType;
						NewRow.IntervalDate = Item.Value + (3600 * Hour);
					EndDo;
				Else
					NewRow = Intervals.Add();
					NewRow.WorkCenterType = String.WorkCenterType;
					NewRow.IntervalDate = Item.Value;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	AccumulationRegisters.AvailabilityOfWorkCenterTypes.CheckDownloadDoesNotExceedScheduleAvailability(Intervals);
	
EndProcedure

#EndRegion

#Region EnteringAvailabilityOfWorkCenters

&AtClient
Procedure EnterWorkCenterSchedules(PeriodDate_, NumberOfDisplayedAvailability)

	CurrentData = Items.TypeOfWorkCentersAvailability.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("PeriodDate_", PeriodDate_);
	FormParameters.Insert("PlanningInterval", PlanningInterval);
	FormParameters.Insert("WorkCenterType", CurrentData.WorkCenterType);
	FormParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	FormParameters.Insert("PeriodEnding", PeriodEnding);
	FormParameters.Insert("DataAddressWCOperationSchedules", DataAddressWCOperationSchedules);
	FormParameters.Insert("AvailabilityInformation_", AvailabilityInformationInCurLine());
	FormParameters.Insert("AccessibilityEditingMode", AccessibilityEditingMode);
	FormParameters.Insert("ReadOnly", ReadOnly);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NumberOfDisplayedAvailability", NumberOfDisplayedAvailability);
	AdditionalParameters.Insert("Id", CurrentData.GetID());
	CallbackDescription = New CallbackDescription("EnteringAvailabilityOfWorkCentersCompletion", ThisObject, AdditionalParameters);
	OpenForm("DataProcessor.AvailabilityOfWorkCenterTypes.Form.EnterWorkCenterSchedules", FormParameters,,,,, CallbackDescription);

EndProcedure

&AtClient
Function AvailabilityInformationInCurLine()

	AvailabilityForPeriod = New Array;
	
	CurrentData = Items.TypeOfWorkCentersAvailability.CurrentData;
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	For Each PeriodDate_ In DatesOfSelectedPeriod Do
		PeriodAvailability = New Structure;
		PeriodAvailability.Insert("PeriodDate_", PeriodDate_);
		
		PeriodColumnName = PeriodColumnName(PeriodDate_);
		For NumberOfDisplayedAvailability = 1 To 3 Do
			ColumnNameAvailability = PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability;
			PeriodAvailability.Insert("Enabled" + NumberOfDisplayedAvailability, CurrentData[ColumnNameAvailability]);
		EndDo;
		AvailabilityForPeriod.Add(PeriodAvailability);
	EndDo;
	
	AvailabilityInformation_ = New Structure;
	AvailabilityInformation_.Insert("AvailabilityForPeriod", AvailabilityForPeriod);
	AvailabilityInformation_.Insert("DisplayingAvailability1", CurrentData.DisplayingAvailability1);
	AvailabilityInformation_.Insert("DisplayingAvailability2", CurrentData.DisplayingAvailability2);
	AvailabilityInformation_.Insert("DisplayingAvailability3", CurrentData.DisplayingAvailability2);
	
	Return AvailabilityInformation_;
	
EndFunction


// The completion handler input of availability of the work centers
// 
// Parameters:
// 	NewAvailabilityDetails - ValueTable - information about the new availability
// 	AdditionalParameters - Structure - Contains:
//  * NumberOfDisplayedAvailability - Number - column number.
//  * Id - Number - id of the line.
&AtClient
Procedure EnteringAvailabilityOfWorkCentersCompletion(NewAvailabilityDetails, AdditionalParameters) Export

	If NewAvailabilityDetails <> Undefined Then
		EnteringAvailabilityOfWorkCentersCompletionOnServer(NewAvailabilityDetails, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure EnteringAvailabilityOfWorkCentersCompletionOnServer(NewAvailabilityDetails, AdditionalParameters)

	AvailabilityLine_ = TypeOfWorkCentersAvailability.FindByID(AdditionalParameters.Id);
	If AvailabilityLine_ = Undefined Then
		Return;
	EndIf;
	
	// The data needs to be collapsed
	InformationAboutNewAvailabilityTable = NewAvailabilityDetails.Unload();
	For Each NewAvailability In InformationAboutNewAvailabilityTable Do
		NewAvailability.ScheduleDate = PlanningIntervalStart(NewAvailability.ScheduleDate, PlanningInterval);
	EndDo;
	TableManualChanges = InformationAboutNewAvailabilityTable.Copy();
	
	InformationAboutNewAvailabilityTable.GroupBy("ScheduleDate", "Count");
	TableManualChanges.GroupBy("ScheduleDate,ManualChangesMade");
	
	For Each NewAvailability In InformationAboutNewAvailabilityTable Do
		PeriodColumnName = PeriodColumnName(NewAvailability.ScheduleDate);
		AvailabilityLine_[PeriodColumnName + "Enabled" + AdditionalParameters.NumberOfDisplayedAvailability] = NewAvailability.Count / 3600;
		AvailabilityLine_[PeriodColumnName + "AvailabilityOfSeconds" + AdditionalParameters.NumberOfDisplayedAvailability] = NewAvailability.Count;
		
		// Let's determine if there are manual schedule changes
		ManualChangesMade = False;
		TheStructureOfTheSearch = New Structure("ScheduleDate",NewAvailability.ScheduleDate);
		ManualDateChanges = TableManualChanges.FindRows(TheStructureOfTheSearch);
		For Each DataAboutManualChanges In ManualDateChanges Do
			If DataAboutManualChanges.ManualChangesMade Then
				ManualChangesMade = True;
				Break;
			EndIf;
		EndDo;
		FillInManualChangesToLine(NewAvailability.ScheduleDate, AdditionalParameters.NumberOfDisplayedAvailability, ManualChangesMade, AvailabilityLine_);
		
		WhenChangingAvailabilityInRow(AvailabilityLine_, NewAvailability.ScheduleDate, AdditionalParameters.NumberOfDisplayedAvailability);
	EndDo; 
	
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	FillInTotalInLine(AvailabilityLine_, AdditionalParameters.NumberOfDisplayedAvailability, DatesOfSelectedPeriod, ThisForm);
	
	Modified = True;

EndProcedure

#EndRegion

#Region FillingInScheduleAccordingToSchedule

&AtClient
Procedure FillInAvailabilityToCreateATimetable()

	If Items.TypeOfWorkCentersAvailability.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	FillInAvailabilityForSchedulingOnServer();

EndProcedure

&AtServer
Procedure FillInAvailabilityForSchedulingOnServer()

	// We will get the selected types of RC
	ListOfTypesOfRC = New Array;
	For Each RowID In Items.TypeOfWorkCentersAvailability.SelectedRows Do
		RowViewRC = TypeOfWorkCentersAvailability.FindByID(RowID);
		
		If RowViewRC.DisplayingAvailability1 <> Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule
			And RowViewRC.DisplayingAvailability2 <> Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule 
			And RowViewRC.DisplayingAvailability3 <> Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
			
			Continue;
		EndIf;
		
		ListOfTypesOfRC.Add(RowViewRC.WorkCenterType);
		
	EndDo; 
	
	FillInAvailabilityByOpeningHours(ListOfTypesOfRC);
	
EndProcedure

&AtServer
Procedure FillInAvailabilityByOpeningHours(ListOfTypesOfRC)

	If ListOfTypesOfRC.Count() = 0 Then
		Return;
	EndIf; 
	
	ScheduleOfWorkSchedulesOfRC = GetFromTempStorage(DataAddressWCOperationSchedules);

	// We will get the data of the selected types of RC
	
	SchedulesOfWorkCenters = ProductionServer.WorkCenterSchedules(ListOfTypesOfRC, False);
	
	Query = New Query(
		"SELECT ALLOWED
		|	WorkCenters.WorkCenterType AS WorkCenterType,
		|	WorkCenters.Ref AS WorkCenter,
		|	WorkCenters.Description AS WorkCenterPresentation,
		|	WorkCenters.WorkTimeFactor AS WorkTimeFactor
		|FROM
		|	Catalog.WorkCenters AS WorkCenters
		|WHERE
		|	WorkCenters.WorkCenterType IN(&ListOfTypesOfRC)
		|	AND NOT WorkCenters.DeletionMark");
	Query.SetParameter("ListOfTypesOfRC", ListOfTypesOfRC);
	DataFromWorkCenters = Query.Execute().Unload();
	
	// Fill in the work schedules
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	For Each WorkCenterType In ListOfTypesOfRC Do
		
		TheStructureOfTheSearch = New Structure("WorkCenterType", WorkCenterType);
		RowViewRC = TypeOfWorkCentersAvailability.FindRows(TheStructureOfTheSearch)[0];
		
		If RowViewRC.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
			NumberOfDisplayedAvailability = 1;
		ElsIf RowViewRC.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
			NumberOfDisplayedAvailability = 2;
		ElsIf RowViewRC.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule Then
			NumberOfDisplayedAvailability = 3;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("WorkCenterType", WorkCenterType);
		StringsList = DataFromWorkCenters.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			MessageText = StrTemplate(NStr("vi = 'Chưa nhập nguồn lực sản xuất đối với dạng nguồn lực sản xuất ""%1"".';
											|ru = 'Для вида рабочих центров ""%1"" не введены рабочие центры.';
											|en = 'No work centers are specified for the ""%1"" work center type.'; fa = 'No work centers are specified for the ""%1"" work center type.';
											|it = 'Per il tipo di centri di lavoro ""%1"" non sono stati immessi i centri di lavoro.';
											|pl = 'Dla rodzaju centrów roboczych ""%1"" nie wprowadzono  centrów roboczych.';
											|tr = '""%1"" iş merkezi türüne ilişkin iş merkezleri girilmedi.'"),
				WorkCenterType);
			CommonClientServer.MessageToUser(MessageText, WorkCenterType); 
			Continue;
		EndIf;
		
		RCData = New Array;
		For Each WCData In StringsList Do
			
			ArrayOfGraphs = New Array;
			
			TheStructureOfTheSearch = New Structure("Ref", WCData.WorkCenter);
			LinesOfGraphics = SchedulesOfWorkCenters.FindRows(TheStructureOfTheSearch);
			
			For Each LineGraph In LinesOfGraphics Do
				If ValueIsFilled(LineGraph.WorkScheduleCalendar) Then
					ArrayOfGraphs.Add(LineGraph.WorkScheduleCalendar);
				EndIf;
			EndDo;
			
			If ArrayOfGraphs.Count() > 0 Then
				DescriptionOfRC = New Structure;
				DescriptionOfRC.Insert("WorkCenter", WCData.WorkCenter);
				DescriptionOfRC.Insert("WorkSchedules", ArrayOfGraphs);
				DescriptionOfRC.Insert("WorkTimeFactor", WCData.WorkTimeFactor);
				RCData.Add(DescriptionOfRC);
			Else
				MessageText = StrTemplate(NStr("vi = 'Chưa chỉ định lịch biểu làm việc đối với nguồn lực sản xuất ""%1"".';
												|ru = 'Для рабочего центра ""%1"" не указан график работы.';
												|en = 'Schedule is not specified for work center ""%1"".'; fa = 'Schedule is not specified for work center ""%1"".';
												|it = 'Per il centro di lavoro ""%1"" non è specificato alcun orario di lavoro.';
												|pl = 'Dla centrum roboczego ""%1"" nie określono harmonogramu pracy.';
												|tr = '""%1"" iş merkezine ilişkin çalışma takvimi belirtilmedi.'"),
					WCData.WorkCenterPresentation);
				CommonClientServer.MessageToUser(MessageText, WCData.WorkCenter); 
			EndIf;
			
		EndDo;
		
		If RCData.Count() = 0 Then
			Continue;
		EndIf;
		
		NewAvailabilityDetails = DataProcessors.AvailabilityOfWorkCenterTypes.FillInWorkSchedulesOfRC(
											WorkCenterType, 
											RCData, 
											BeginOfPeriod, 
											PeriodEnding, 
											ScheduleOfWorkSchedulesOfRC,
											PlanningInterval);
		If NewAvailabilityDetails = Undefined Then
			Continue;
		EndIf;
		
		// Update the data on the form
		For Each NewAvailability In NewAvailabilityDetails Do
			NewAvailability.ScheduleDate = PlanningIntervalStart(NewAvailability.ScheduleDate, PlanningInterval);
		EndDo;
		TablePeriodDate = NewAvailabilityDetails.Copy();
		TablePeriodDate.GroupBy("ScheduleDate");
		ListOfPeriodDate = TablePeriodDate.UnloadColumn("ScheduleDate");
		
		For Each PeriodDate_ In ListOfPeriodDate Do
			
			AvailabilityOfSeconds = 0;
			TheStructureOfTheSearch = New Structure("ScheduleDate", PeriodDate_);
			StringsList = NewAvailabilityDetails.FindRows(TheStructureOfTheSearch);
			For Each NewAvailability In StringsList Do
				AvailabilityOfSeconds = AvailabilityOfSeconds + NewAvailability.Count / NewAvailability.WorkTimeFactor;
			EndDo;
			
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			
			RowViewRC[PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability] = AvailabilityOfSeconds / 3600;
			RowViewRC[PeriodColumnName + "AvailabilityOfSeconds" + NumberOfDisplayedAvailability] = AvailabilityOfSeconds;
			
			FillInManualChangesToLine(PeriodDate_, NumberOfDisplayedAvailability, False, RowViewRC);
			
			WhenChangingAvailabilityInRow(RowViewRC, PeriodDate_, NumberOfDisplayedAvailability);
			
		EndDo;
		
		FillInTotalInLine(RowViewRC, NumberOfDisplayedAvailability, DatesOfSelectedPeriod, ThisForm);
		
	EndDo; 
	
	PutToTempStorage(ScheduleOfWorkSchedulesOfRC, DataAddressWCOperationSchedules);

EndProcedure

#EndRegion

#Region FillingInAvailabilityByStandards

&AtClient
Procedure FillInAvailabilityToGenerateSchedule()

	If Items.TypeOfWorkCentersAvailability.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	FillInFieldForCreatingScheduleOnServer();

EndProcedure

&AtServer
Procedure FillInFieldForCreatingScheduleOnServer()
	
	// We will get the selected types of RC
	RCTypesFillingInAvailabilityByRCType = New Array;
	TypesOfRCFillingInAvailabilityAccordingToWorkSchedule = New Array;
	For Each RowID In Items.TypeOfWorkCentersAvailability.SelectedRows Do
		
		RowViewRC = TypeOfWorkCentersAvailability.FindByID(RowID);
		
		If RowViewRC.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.ByWorkCenterType
			Or RowViewRC.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByWorkCenterType 
			Or RowViewRC.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
			
			RCTypesFillingInAvailabilityByRCType.Add(RowViewRC.WorkCenterType);
		
		ElsIf Not RowViewRC.EnterAvailabilityForWorkCenterType
			And (RowViewRC.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule
				Or RowViewRC.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule 
				Or RowViewRC.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule) Then
			
			TypesOfRCFillingInAvailabilityAccordingToWorkSchedule.Add(RowViewRC.WorkCenterType);
		
		EndIf;
		
	EndDo; 
	
	FillInAvailabilityByRCType(RCTypesFillingInAvailabilityByRCType);
	FillInAvailabilityByOpeningHours(TypesOfRCFillingInAvailabilityAccordingToWorkSchedule);
	
EndProcedure

&AtServer
Procedure FillInAvailabilityByRCType(ListOfTypesOfRC)

	If ListOfTypesOfRC.Count() = 0 Then
		Return;
	EndIf; 
	
	// We will get the data of the selected types of RC
	TempTablesManager = New TempTablesManager;
	ProductionServer.CreateTTSchedulesForRCTypes(ListOfTypesOfRC, TempTablesManager, "TTWorkSchedules_");
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		"SELECT
		|	WorkCenterTypes.Ref AS WorkCenterType,
		|	WorkCenterTypes.NumberOfWorkCenters AS NumberOfWorkCenters,
		|	CASE WorkCenterTypes.UnitOfMeasureOfWorkCenterSchedule
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN 3600
		|		ELSE 86400
		|	END * WorkCenterTypes.MaximumWorkCenterAvailability AS MaximumWorkCenterAvailability
		|FROM
		|	Catalog.WorkCenterTypes AS WorkCenterTypes
		|WHERE
		|	WorkCenterTypes.Ref IN(&ListOfTypesOfRC)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTWorkSchedules_.Ref AS WorkCenterType,
		|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleCalendar
		|FROM
		|	TTWorkSchedules_ AS TTWorkSchedules_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleCalendar
		|FROM
		|	TTWorkSchedules_ AS TTWorkSchedules_";
	
	Query.SetParameter("ListOfTypesOfRC", ListOfTypesOfRC);
	
	ResultsArray = Query.ExecuteBatch();
	DataFromRCTypes = ResultsArray[0].Unload();
	GraphsOfTypesOfRC = ResultsArray[1].Unload();
	
	WorkSchedules1 = WorkSchedules.WorkSchedulesForPeriod(
		ResultsArray[2].Unload().UnloadColumn("WorkScheduleCalendar"),
		BeginOfPeriod,
		PeriodEnding,
		PlanningInterval = Enums.ProductionScheduleAccuracy.Shift);
	WorkSchedules1.GroupBy("WorkScheduleCalendar,ScheduleDate");
	WorkSchedules1.Indexes.Add("WorkScheduleCalendar,ScheduleDate");
	
	// Fill in the availability
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	For Each WorkCenterType In ListOfTypesOfRC Do
		
		TheStructureOfTheSearch = New Structure("WorkCenterType", WorkCenterType);
		
		RowViewRC = TypeOfWorkCentersAvailability.FindRows(TheStructureOfTheSearch)[0];
		DetailsOfRCType = DataFromRCTypes.FindRows(TheStructureOfTheSearch)[0];
		GraphsOfRCType = GraphsOfTypesOfRC.FindRows(TheStructureOfTheSearch);
		
		If DetailsOfRCType.NumberOfWorkCenters = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Chưa chỉ định số lượng nguồn lực sản xuất đối với dạng nguồn lực sản xuất ""%1"".';
											|ru = 'У вида рабочих центров ""%1"" не указано количество рабочих центров.';
											|en = 'Number of the work centers is not specified for the ""%1"" work center type.'; fa = 'Number of the work centers is not specified for the ""%1"" work center type.';
											|it = 'Per il tipo di centri di lavoro ""%1"" non è specificato il numero di centri di lavoro.';
											|pl = 'U rodzaju centrów roboczych ""%1"" nie podano ilość centrów roboczych.';
											|tr = '""%1"" iş merkezi türünde iş merkezi miktarı belirtilmedi.'"),
										WorkCenterType);
			CommonClientServer.MessageToUser(MessageText, WorkCenterType); 
			Continue;
		EndIf;
		
		If RowViewRC.DisplayingAvailability1 = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
			NumberOfDisplayedAvailability = 1;
		ElsIf RowViewRC.DisplayingAvailability2 = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
			NumberOfDisplayedAvailability = 2;
		ElsIf RowViewRC.DisplayingAvailability3 = Enums.AvailabilityDisplayOptions.ByWorkCenterType Then
			NumberOfDisplayedAvailability = 3;
		EndIf;
		
		For Each PeriodDate_ In DatesOfSelectedPeriod Do
			
			ThereAreWorkingDaysInPeriod = False;
			If PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
				
				For Each LineGraph In GraphsOfRCType Do
					
					TheStructureOfTheSearch = New Structure("ScheduleDate,WorkScheduleCalendar", PeriodDate_, LineGraph.WorkScheduleCalendar);
					StringsList = WorkSchedules1.FindRows(TheStructureOfTheSearch);
					If StringsList.Count() <> 0 Then
						ThereAreWorkingDaysInPeriod = True;
						Break;
					EndIf;
					
				EndDo;
				
			Else
				
				If PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
					IntervalDates = DatesOfSelectedPeriod(PeriodDate_, EndOfWeek(PeriodEnding), Enums.ProductionScheduleAccuracy.Day);
				Else
					IntervalDates = DatesOfSelectedPeriod(PeriodDate_, EndOfMonth(PeriodEnding), Enums.ProductionScheduleAccuracy.Day);
				EndIf;
				
				For Each IntervalDate In IntervalDates Do
					
					For Each LineGraph In GraphsOfRCType Do
						
						TheStructureOfTheSearch = New Structure("ScheduleDate,WorkScheduleCalendar", IntervalDate, LineGraph.WorkScheduleCalendar);
						StringsList = WorkSchedules1.FindRows(TheStructureOfTheSearch);
						If StringsList.Count() <> 0 Then
							ThereAreWorkingDaysInPeriod = True;
							Break;
						EndIf;
					
					EndDo;
				
					If ThereAreWorkingDaysInPeriod Then
						Break;
					EndIf;
					
				EndDo;
				
			EndIf; 
			
			If ThereAreWorkingDaysInPeriod Then
				AvailabilityOfSeconds = DetailsOfRCType.NumberOfWorkCenters * DetailsOfRCType.MaximumWorkCenterAvailability;
			Else
				AvailabilityOfSeconds = 0;
			EndIf;
			
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			
			RowViewRC[PeriodColumnName + "Enabled" + NumberOfDisplayedAvailability] = AvailabilityOfSeconds / 3600;
			RowViewRC[PeriodColumnName + "AvailabilityOfSeconds" + NumberOfDisplayedAvailability] = AvailabilityOfSeconds;
			
			WhenChangingAvailabilityInRow(RowViewRC, PeriodDate_, NumberOfDisplayedAvailability);
			
		EndDo;
		
		FillInTotalInLine(RowViewRC, NumberOfDisplayedAvailability, DatesOfSelectedPeriod, ThisForm);
		
	EndDo;	

EndProcedure
 
#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Then
		Items.SaveChanges.Enabled = Form.AccessibilityEditingMode <> PredefinedValue(
			"Enum.ModesOfEditingTypeOfWorkCentersAvailability.ReadOnly");
	EndIf;
	
	If AttributesStructure1.Property("WorkScheduleDetails")
		Or Initialize Then
		Items.SetAPeriodForEnteringAvailability.Visible = ValueIsFilled(Form.WorkScheduleDetails);
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	OperatingModeSelectionList = Items.AccessibilityEditingMode.ChoiceList;
	OperatingModeSelectionList.Clear();
	
	If UserRightsCached.RightToEnterAvailabilityOfTypesOfRC() Then
		OperatingModeSelectionList.Add(Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule,
											NStr("vi = 'Để tạo lịch biểu sản xuất';
												|ru = 'Для формирования графика производства';
												|en = 'To generate a production schedule'; fa = 'To generate a production schedule';
												|it = 'Для формирования графика производства';
												|pl = 'Dla tworzenia harmonogramu produkcji';
												|tr = 'Üretim programının düzenlenmesi için'"));
	EndIf;
	
	If UserRightsCached.RightToEnterWorkSchedulesOfRC() And ProductionManagementCached.UseWorkCenterWorkPlanning() Then
		OperatingModeSelectionList.Add(Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable,
											NStr("vi = 'Để tạo lịch biểu làm việc của NLSX';
												|ru = 'Для формирования расписания работы РЦ';
												|en = 'To generate a work center schedule'; fa = 'To generate a work center schedule';
												|it = 'Для формирования расписания работы РЦ';
												|pl = 'Do tworzenia harmonogramu pracy CR';
												|tr = 'İM çalışma çizelgesinin düzenlenmesi için'"));
	EndIf;

	If OperatingModeSelectionList.Count() = 0 Then
		ThisForm.CommandBarLocation = FormCommandBarLabelLocation.None;
		
		Items.TypeOfWorkCentersAvailability.ReadOnly = True;
		
		Items.ListCommandPages.CurrentPage = Items.TeamPageViewOnly;
		
		AccessibilityEditingMode = 0;
		OperatingModeSelectionList.Add(Enums.ModesOfEditingTypeOfWorkCentersAvailability.ReadOnly);
	EndIf;
	
	If OperatingModeSelectionList.FindByValue(AccessibilityEditingMode) = Undefined Then
		AccessibilityEditingMode = OperatingModeSelectionList[0].Value;
	EndIf;
	
	If OperatingModeSelectionList.Count() = 1 Then
		Items.AccessibilityEditingMode.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingAccessibilityEditingMode()

	If AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule Then
		Items.ListCommandPages.CurrentPage = Items.PageCommandsAvailabilityInputForSchedule;
	ElsIf AccessibilityEditingMode = Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable Then
		Items.ListCommandPages.CurrentPage = Items.PageCommandsAvailabilityForTimetable;
	EndIf;

EndProcedure

&AtServer
Procedure SaveSelectionParameters()
	
	FilterParameters = New Structure("FilterDepartment,PeriodEnding,BeginOfPeriod");
										
	FillPropertyValues(FilterParameters, ThisForm);
	FormDataSettingsStorage.Save("AvailabilityOfWorkCenterTypes", "FilterParameters", FilterParameters);
	
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

&AtClientAtServerNoContext
Procedure WhenChangingAvailabilityInRow(CurrentData, PeriodDate_, NumberOfDisplayedAvailability, DataChanged1 = True)
	
	PeriodColumnName = PeriodColumnName(PeriodDate_);
	
	If DataChanged1 Then
		CurrentData[PeriodColumnName + "DataChanged1" + NumberOfDisplayedAvailability] = True;
	EndIf;
	
	CurrentData[PeriodColumnName + "AvailabilityFilled" + NumberOfDisplayedAvailability] = True;
	
	AvailabilityOfSeconds = CurrentData[PeriodColumnName + "AvailabilityOfSeconds" + NumberOfDisplayedAvailability];
	If CurrentData["DisplayingAvailability" + NumberOfDisplayedAvailability] = PredefinedValue("Enum.AvailabilityDisplayOptions.ByWorkCenterType") Then
		CurrentData[PeriodColumnName + "AvailabilityTypeOfRC1"] = AvailabilityOfSeconds;
	ElsIf CurrentData["DisplayingAvailability" + NumberOfDisplayedAvailability] = PredefinedValue("Enum.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule") Then
		CurrentData[PeriodColumnName + "RCAvailability1"] = AvailabilityOfSeconds;
	ElsIf CurrentData["DisplayingAvailability" + NumberOfDisplayedAvailability] = PredefinedValue("Enum.AvailabilityDisplayOptions.ByProductionSchedule") Then
		CurrentData[PeriodColumnName + "AvailabilitySchedule1"] = AvailabilityOfSeconds;
	EndIf;
	
	For Cnt = 1 To 3 Do
		NameOfDeficitField = PeriodColumnName + "AvailabilityShortage" + Cnt;
	
		If CurrentData["DisplayingAvailability" + Cnt] = PredefinedValue("Enum.AvailabilityDisplayOptions.ByWorkCenterType") Then
			CurrentData[NameOfDeficitField] = (CurrentData[PeriodColumnName + "AvailabilityTypeOfRC1"] < CurrentData[PeriodColumnName + "AvailabilitySchedule1"]);
			
		ElsIf CurrentData["DisplayingAvailability" + Cnt] = PredefinedValue("Enum.AvailabilityDisplayOptions.AccordingToWorkCenterSchedule") Then
			CurrentData[NameOfDeficitField] = (CurrentData[PeriodColumnName + "RCAvailability1"] < CurrentData[PeriodColumnName + "AvailabilitySchedule1"]);
			
		EndIf;
	EndDo; 
	
EndProcedure

&AtServer
Procedure ShowWhereManualChangesWereMadeOnServer()

	If BeginOfPeriod = '000101010000' Or PeriodEnding = '000101010000' Then
		Return
	EndIf;
	
	DatesOfSelectedPeriod = DatesOfSelectedPeriod(BeginOfPeriod, PeriodEnding, PlanningInterval);
	
	If ShowWhereManualChangesWereMade Then
		
		// Let's determine which columns need to be shown
		For Each PeriodDate_ In DatesOfSelectedPeriod Do
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			
			PeriodVisibility = False;
			For Each AvailabilityLine_ In TypeOfWorkCentersAvailability Do
				If AvailabilityLine_[PeriodColumnName + "ManualChangesMade1"]
					Or AvailabilityLine_[PeriodColumnName + "ManualChangesMade2"]
					Or AvailabilityLine_[PeriodColumnName + "ManualChangesMade3"] Then
					PeriodVisibility = True;
					Break;
				EndIf;
			EndDo;
			
			If Items[PeriodColumnName + "PeriodGroup"].Visible <> PeriodVisibility Then
				Items[PeriodColumnName + "PeriodGroup"].Visible = PeriodVisibility;
			EndIf;
			
		EndDo; 
		
		// Let's determine whether to show the line
		For Each AvailabilityLine_ In TypeOfWorkCentersAvailability Do
			ManualChangesMade = False;
			For Each PeriodDate_ In DatesOfSelectedPeriod Do
				PeriodColumnName = PeriodColumnName(PeriodDate_);
				If AvailabilityLine_[PeriodColumnName + "ManualChangesMade1"]
					Or AvailabilityLine_[PeriodColumnName + "ManualChangesMade2"]
					Or AvailabilityLine_[PeriodColumnName + "ManualChangesMade3"] Then
					ManualChangesMade = True;
					Break;
				EndIf;
			EndDo;
			AvailabilityLine_.NotShow = Not ManualChangesMade;
		EndDo; 
		
	Else

		// All columns need to be shown
		For Each PeriodDate_ In DatesOfSelectedPeriod Do
			PeriodColumnName = PeriodColumnName(PeriodDate_);
			If Not Items[PeriodColumnName + "PeriodGroup"].Visible Then
				Items[PeriodColumnName + "PeriodGroup"].Visible = True;
			EndIf;
		EndDo; 
		
		// All lines need to be shown
		For Each AvailabilityLine_ In TypeOfWorkCentersAvailability Do
			AvailabilityLine_.NotShow = False;
		EndDo; 
		
	EndIf; 

EndProcedure

&AtServer
Procedure SetPeriodForEnteringAvailabilityOnServer()
	
	PeriodEnding = ?(AccessibilityEditingMode
			= Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule,
		ScheduleAvailabilityShouldBeFilledInTo,
		WCScheduleToBeFilledInUntil);
	
	RecommendedPeriod = RecommendedPeriod("PeriodEnding", BeginOfPeriod, PeriodEnding, PlanningInterval);
	
	If BeginOfPeriod > PeriodEnding
		Or BeginOfPeriod < RecommendedPeriod.BeginOfPeriod Then
		BeginOfPeriod = PlanningIntervalStart(CurrentSessionDate(), PlanningInterval);
	EndIf;
	
	FillInData();
	ConfigureDependentFormElements(ThisObject, "WorkScheduleDetails");
	
EndProcedure

&AtClient
Procedure CheckForTooLongPeriod(NameOfDateToChange, DescriptionOfCompletionAlert)

	If Not PlanningInterval.IsEmpty() 
		And BeginOfPeriod <> '000101010000'
		And PeriodEnding <> '000101010000' Then
		
		RecommendedPeriod = RecommendedPeriod(NameOfDateToChange, BeginOfPeriod, PeriodEnding, PlanningInterval);
		If BeginOfPeriod < RecommendedPeriod.BeginOfPeriod
			Or PeriodEnding > RecommendedPeriod.PeriodEnding Then
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("DescriptionOfCompletionAlert", DescriptionOfCompletionAlert);
			AdditionalParameters.Insert("RecommendedPeriod", RecommendedPeriod);
			CallbackDescription = New CallbackDescription("CheckForTooLongPeriodCompletion", ThisObject, AdditionalParameters);
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Có thể mất nhiều thời gian để nhận dữ liệu trong khoảng thời gian đã chọn. 
													| Nên chọn kỳ %1.
													|Tiếp tục?';
													|ru = 'Получение данных за выбранный период может занять длительное время.
													|Рекомендуется выбрать период %1.
													|Продолжить?';
													|en = 'Data receipt for the selected period may take a long time.
													|It is recommended that you select a period %1.
													|Continue?'; fa = 'Data receipt for the selected period may take a long time.
													|It is recommended that you select a period %1.
													|Continue?';
													|it = 'Acquisizione dei dati per il periodo selezionato può richiedere del tempo.
													|Si consiglia di scegliere il periodo%1.
													|Continuare?';
													|pl = 'Pobieranie danych za wybrany okres może trwać dłuższy czas.
													|Zaleca się wybrać okres%1.
													|Kontynuować?';
													|tr = 'Seçilen dönem için verilerin alınması uzun zaman alabilir.
													|%1 döneminin seçilmesi önerilmektedir.
													|Devam edilsin mi?'"),
										RecommendedPeriod.RecommendedPeriodString);
										
			ButtonsList = New ValueList;
			ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
														|ru = 'Продолжить';
														|en = 'Continue'; fa = 'ادامه';
														|it = 'Continuare';
														|pl = 'Continue';
														|tr = 'Devam et'"));
			ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Chọn kỳ đề xuất';
														|ru = 'Выбрать рекомендуемый период';
														|en = 'Select the recommended period'; fa = 'Select the recommended period';
														|it = 'Selezionare il periodo consigliato';
														|pl = 'Wybierz zalecany okres';
														|tr = 'Önerilen dönemi seç'"));
			ButtonsList.Add(DialogReturnCode.Cancel);
			ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
			Return;
		EndIf; 
	EndIf;

	RunCallback(DescriptionOfCompletionAlert, Undefined);
	
EndProcedure

&AtClientAtServerNoContext
Function RecommendedPeriod(NameOfDateToChange, BeginOfPeriod, PeriodEnding, PlanningInterval)

	RecommendedPeriod = New Structure;
	If PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Hour")
		Or PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Shift")
		Or PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Day") Then
		
		// Two months
		If NameOfDateToChange = "BeginOfPeriod" Then
			RecommendedStartOfPeriod = BeginOfPeriod;
			RecommendedEndOfPeriod = AddMonth(RecommendedStartOfPeriod, 2);
		Else
			RecommendedEndOfPeriod = PeriodEnding;
			RecommendedStartOfPeriod = AddMonth(RecommendedEndOfPeriod, -2);
		EndIf;
		
	ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Week") Then
		
		// 60 weeks
		If NameOfDateToChange = "BeginOfPeriod" Then
			RecommendedStartOfPeriod = PlanningIntervalStart(BeginOfPeriod, PlanningInterval);
			RecommendedEndOfPeriod = PlanningIntervalEnd(RecommendedStartOfPeriod + 86400 * 420, PlanningInterval);
		Else
			RecommendedEndOfPeriod = PlanningIntervalEnd(PeriodEnding, PlanningInterval);
			RecommendedStartOfPeriod = PlanningIntervalStart(RecommendedEndOfPeriod - (86400 * 420), PlanningInterval);
		EndIf;
		
	ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Month") Then
		
		// 24 months
		If NameOfDateToChange = "BeginOfPeriod" Then
			RecommendedStartOfPeriod = PlanningIntervalStart(BeginOfPeriod, PlanningInterval);
			RecommendedEndOfPeriod = PlanningIntervalEnd(AddMonth(RecommendedStartOfPeriod, 24), PlanningInterval);
		Else
			RecommendedEndOfPeriod = PlanningIntervalEnd(PeriodEnding, PlanningInterval);
			RecommendedStartOfPeriod = PlanningIntervalStart(AddMonth(RecommendedEndOfPeriod, -24), PlanningInterval);
		EndIf;
		
	EndIf; 
	
	RecommendedPeriod.Insert("BeginOfPeriod", RecommendedStartOfPeriod);
	RecommendedPeriod.Insert("PeriodEnding", RecommendedEndOfPeriod);
	
	RecommendedPeriodString = Format(RecommendedStartOfPeriod, "DF=MM/dd/yy") 
								+ " - " 
								+ Format(RecommendedEndOfPeriod, "DF=MM/dd/yy");
								
	RecommendedPeriod.Insert("RecommendedPeriodString", RecommendedPeriodString);
	
	Return RecommendedPeriod;

EndFunction

&AtClient
Procedure CheckForTooLongPeriodCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		RunCallback(AdditionalParameters.DescriptionOfCompletionAlert);
	ElsIf QuestionResult = DialogReturnCode.No Then
	 	BeginOfPeriod = AdditionalParameters.RecommendedPeriod.BeginOfPeriod;
	 	PeriodEnding = AdditionalParameters.RecommendedPeriod.PeriodEnding;
		RunCallback(AdditionalParameters.DescriptionOfCompletionAlert);
	Else
		BeginOfPeriod = CurrentStartOfThePeriod;
		PeriodEnding = CurrentEndOfThePeriod_3;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChangeCompletion(QuestionResult, AdditionalParameters = Undefined) Export
	
	FillInData(True);
	CurrentStartOfThePeriod = BeginOfPeriod;
	CurrentEndOfThePeriod_3 = PeriodEnding;
	ConfigureDependentFormElements(ThisObject, "WorkScheduleDetails");
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChangeCompletion(QuestionResult, AdditionalParameters = Undefined) Export
	
	FillInData(True);
	CurrentStartOfThePeriod = BeginOfPeriod;
	CurrentEndOfThePeriod_3 = PeriodEnding;
	ConfigureDependentFormElements(ThisObject, "WorkScheduleDetails");
	
EndProcedure

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
