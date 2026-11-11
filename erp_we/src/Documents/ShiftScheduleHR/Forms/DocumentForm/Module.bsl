#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	TimeTrackingServer.CreatePeriodTable(ThisObject, "TimeIntervals");

	If Not ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(Parameters.CopyingValue) Then
			TimeTrackingServer.FillInSelectedDimensions(
			Parameters.CopyingValue.DataOnTime, SelectedMeasurements, "WorkScheduleCalendar");
		EndIf;

		OnReadCreateAtServer();
		SetVisibilityAvailabilityServer();
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	DocumentsPayrollAndHumanResourcesServer.SetBanOnEditingItems(ThisObject, False);
	
	DocumentsPayrollAndHumanResourcesServer.ShowHideBanner(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands  

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	TimeTrackingServer.FillInSelectedDimensions(Object.DataOnTime, SelectedMeasurements, "WorkScheduleCalendar");

	TimeTrackingServer.CreatePeriodTable(ThisObject, "TimeIntervals");
	OnReadCreateAtServer();
	SetVisibilityAvailabilityServer();
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates    
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.OnReadAtServer(ThisObject, CurrentObject);

	// Handler of the "Date-change" mechanism
	CurrentObject.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", True);

	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.DataOnTime.Clear();
	TimeTrackingServer.CopyFromCrossTable(CurrentObject, ThisObject);
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		ObjectData = New Structure("Organization, BeginningDateOfPeriod, EndingDateOfPeriod");
		ObjectData.Insert("Ref", Object.Ref);
		FillPropertyValues(ObjectData, Object);
		ObjectData.Insert("EmployeeTable", CurrentObject.DataOnTime.Unload( ,"Employee, Date"));
		ObjectData.Insert("ObjectName", "ShiftScheduleHR");
		ObjectData.Insert("ObjectPresentation", NStr("ru = 'Сменный график';
													|vi = 'Shift schedule';
													|en = 'Shift schedule'; fa = 'برنامه شیفت';
													|it = 'Shift schedule';
													|pl = 'Shift schedule';
													|tr = 'Vardiya takvimi'"));
		If TimeTrackingServer.CheckIntersectionWithOtherDocuments(ObjectData) Then
			Cancel = True;
			Return;
		EndIf;
	EndIf;

	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.BeforeWriteAtServer(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	SetVisibilityAvailabilityServer();

	FormEventDocumentsPayrollAndHumanResourcesServerOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.AfterWrite(ThisObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	FormEventDocumentsPayrollAndHumanResourcesClientOverridable.NotificationProcessing(ThisObject, Object.Ref, EventName, Parameter,
		Source);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InputOptionOnChange(Item)

	SaveUpdateDataATServer(False);

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)

	UpdateDataOnServer();

EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)

	UpdateDataOnServer();

EndProcedure

&AtClient
Procedure SelectedMeasurementsONChange(Item)

	UpdateDataOnServer();

EndProcedure

&AtClient
Procedure Approved_1OnChange(Item)
	ApprovedOnChangeAtServer();
EndProcedure

&AtClient
Procedure BeginningDateOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	WhenChangingPeriodsOnClient();
EndProcedure

&AtClient
Procedure EndingDateOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	WhenChangingPeriodsOnClient();
EndProcedure

&AtClient
Procedure BannerTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenPayroll" Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Organization", Object.Organization);
		FormParameters.Insert("Department", Object.Department);
		FormParameters.Insert("CalculationPeriod", BegOfMonth(Object.BeginningDateOfPeriod));
		
		OpenForm("DataProcessor.PayrollCalculationHR.Form.Form", FormParameters, ThisObject,,,,);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScheduleByDate

&AtClient
Procedure ScheduleByDateOnChange(Item)
	Modified = True;
EndProcedure

&AtClient
Procedure ScheduleByDateBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	DocumentsPayrollAndHumanResourcesClient.TableOfValuesOnFormBeforeAdding(ThisObject, Item, Cancel, Copy,
		Parent, Var_Group);
EndProcedure

&AtClient
Procedure ScheduleByDateAfterDeleteRow(Item)
	RecalculateTotalsOnClient();
EndProcedure

&AtClient
Procedure ScheduleByDateBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)

	If NewRow Then
		Item.CurrentData.LineNumber = ScheduleByDate.Count();
	EndIf;
	RecalculateTotalsOnClient();

EndProcedure

&AtClient
Procedure ScheduleByDateChoiceProcessing(Item, ValueSelected, StandardProcessing)

	If Not ValueSelected = Undefined Then
		If TypeOf(ValueSelected) = Type("Array") Then
			SelectionProcessingATServer(ValueSelected);
		ElsIf TypeOf(ValueSelected) = Type("CatalogRef.EmployeesHR") Then
			Item.CurrentData.Employee = ValueSelected;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ScheduleByDateDrag(Item, DragParameters, StandardProcessing, String, Field)

	StandardProcessing = False;
	If ByDays Then
		CurrentItemName = Item.CurrentItem.Name;
		FieldName = "ScheduleByDate";
		Prefix = FieldName + "Dimension"+"1";
		If Field <> Undefined And StrFind(CurrentItemName, Prefix) > 0 And StrFind(Field.Name, Prefix) > 0 Then

			CurrentColumn = StrReplace(CurrentItemName, FieldName, "");
			TargetColumn = StrReplace(Field.Name, FieldName, "");

			TargetString = ScheduleByDate.FindByID(String);
			TargetString[TargetColumn] = Item.CurrentData[CurrentColumn];
			Item.CurrentData[CurrentColumn] = "";

			RecalculateTotalsOnClient();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ScheduleByDateEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Department", Object.Department);
	ParametersForOpeningSelection.Insert("WorkingForPeriod", True);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", Object.BeginningDateOfPeriod);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfDay(Object.EndingDateOfPeriod));
	ParametersForOpeningSelection.Insert("MultipleChoice", False);
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.ScheduleByDate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostDocument(Command)

	TMCommonUseClient.Post(ThisObject, True);

EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)

	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);

EndProcedure

&AtClient
Procedure PostAndClose(Command)

	TMCommonUseClient.PostAndClose(ThisObject);

EndProcedure

&AtClient
Procedure WriteDocument(Command)

	TMCommonUseClient.Write(ThisObject);

EndProcedure

&AtClient
Procedure SetDateInterval(Command)

	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);

	TMCommonUseClient.EditPeriod(
		Object, New Structure("StartDate, EndDate", "BeginningDateOfPeriod", "EndingDateOfPeriod"), Notification);

EndProcedure

&AtClient
Procedure Pickup(Command)

	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Department", Object.Department);
	ParametersForOpeningSelection.Insert("WorkingForPeriod", True);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", Object.BeginningDateOfPeriod);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfDay(Object.EndingDateOfPeriod));
	ParametersForOpeningSelection.Insert("MultipleChoice", True);
	ParametersForOpeningSelection.Insert("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedEmployees());
	
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, Items.ScheduleByDate);

EndProcedure

&AtClient
Procedure FillInEmployees(Command)

	FillEmployeesOnServer();
	RecalculateTotalsOnClient();

EndProcedure

&AtClient
Procedure FillInFollowingDays(Command)

	CurrentItem = Items.ScheduleByDate.CurrentItem;
	If Not CurrentItem = Undefined And StrFind(Items.ScheduleByDate.CurrentItem.Name,
		"ScheduleByDate"+"Dimension") > 0 Then
		TagName = Items.ScheduleByDate.CurrentItem.Name;
		PeriodName = Right(TagName, 8);
		DimensionNumber = StrReplace(TagName, "ScheduleByDate"+"Dimension", "");
		DimensionNumber = StrReplace(DimensionNumber, "_" + PeriodName, "");
		DimensionNumber = StringFunctionsClientServer.StringToNumber(DimensionNumber);
		SelectedRows = Items.ScheduleByDate.SelectedRows;

		DataForAutoFilling = GetDataForAutocompletionClient();
		For Each SelectedRow In SelectedRows Do
			CurrentData 	= ScheduleByDate.FindByID(SelectedRow);
			CurrentValue = CurrentData["Dimension" + DimensionNumber + "_" + PeriodName];
			CurrentCalendar = ?(ByDays, CurrentValue, SelectedMeasurements[DimensionNumber - 1].Value);
			PeriodAcc = 0;
			For Each PeriodRow In ThisObject.TimeIntervals Do
				If PeriodRow.ColumnName = PeriodName Then
					PeriodAcc = 1;
					Continue;
				EndIf;
				If PeriodAcc > 0 Then
					PeriodAcc = PeriodAcc + 1;
					ColumnNameProcess = "Dimension" + DimensionNumber + "_" + Right(PeriodRow.ColumnName, 8);
					If AutoCompleteDaysOption = 0 Then
						DataByCalendar = DataForAutoFilling.Get(CurrentCalendar);
						If Not DataByCalendar = Undefined Then
							If DataByCalendar[PeriodRow.Date] = True Then
								CurrentData[ColumnNameProcess] = ?(ByDays, CurrentValue, True);
							Else
								CurrentData[ColumnNameProcess] = "";
							EndIf;
						Else
							CurrentData[ColumnNameProcess] = "";
						EndIf;
					ElsIf AutoCompleteDaysOption = 1 Then
						CheckResult = Check2h2Mode(PeriodAcc);
						CurrentData[ColumnNameProcess] = ?(CheckResult, CurrentValue, "");

					ElsIf AutoCompleteDaysOption = 2 Then
						CheckResult = CheckMode1And3(PeriodAcc);
						CurrentData[ColumnNameProcess] = ?(CheckResult, CurrentValue, "");
					EndIf;
				EndIf;
			EndDo;
		EndDo;
		RecalculateTotalsOnClient();
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Function Check2h2Mode(IncomingValue)
	
	// Check that the input value is a positive integer
	If Not Number(IncomingValue) Or Not Int(IncomingValue) Or IncomingValue < 1 Then
		Return False;
	EndIf;
	Balance = IncomingValue % 4;
	Return Balance = 1 Or Balance = 2;

EndFunction

&AtClient
Function CheckMode1And3(IncomingValue)
	
	// Check that the input value is a positive integer
	If Not Number(IncomingValue) Or Not Int(IncomingValue) Or IncomingValue < 1 Then
		Return False;
	EndIf;
	Balance = IncomingValue % 4;
	Return Balance = 1;

EndFunction

&AtServer
Function AddressOfListOfSelectedEmployees()

	Selected_Employees = CommonClientServer.CollapseArray(
	ScheduleByDate.Unload( , "Employee").UnloadColumn("Employee"));
	Return PutToTempStorage(Selected_Employees, UUID);

EndFunction

&AtServer
Procedure SelectionProcessingATServer(EmployeesHR)

	TimeTrackingServer.ScheduleByDateSelectionProcessing(ThisObject, EmployeesHR);

EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export

	WhenChangingPeriodsOnClient();

EndProcedure

&AtClient
Procedure WhenChangingPeriodsOnClient()

	WhenChangingPeriodsOnServer();

EndProcedure

&AtServer
Procedure WhenChangingPeriodsOnServer()

	TimeTrackingServer.WhenChangingPeriodsOnServer(ThisObject);

EndProcedure

&AtServer
Procedure ApprovedOnChangeAtServer()

	If Not ValueIsFilled(Object.Organization) Or Not ValueIsFilled(Object.Approved_1) Then
		ApprovedJobTitle = Catalogs.JobTitles.EmptyRef();
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	EmploymentRecordSliceLast.JobTitle AS JobTitle
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(&Period, Organization = &Organization
	|	AND Employee.Individual = &Approved_1) AS EmploymentRecordSliceLast";

	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Approved_1", Object.Approved_1);

	QueryResult = Query.Execute();
	Selection = QueryResult.Select();

	If Selection.Next() Then
		ApprovedJobTitle = Selection.JobTitle;
	Else
		ApprovedJobTitle = Catalogs.JobTitles.EmptyRef();
	EndIf;

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	UpdateDataOnServer(False);

EndProcedure

&AtServer
Procedure UpdateDataOnServer(ClearingObject = True)

	NumberOfMeasurements = SelectedMeasurements.Count();
	If NumberOfMeasurements = 1 Then
		Object.InputOption = Enums.OptionsForEnteringShiftSchedules.ByShifts;
	EndIf;

	ByDays = Object.InputOption = Enums.OptionsForEnteringShiftSchedules.ByDays;
	If ByDays And NumberOfMeasurements > 1 Then
		NumberOfMeasurements = 1;
	EndIf;

	MeasurementsData.Clear();
	For Each Dimension In SelectedMeasurements Do
		DimensionData = Common.ObjectAttributesValues(Dimension.Value, "Ref, Presentation");
		Dimension.Presentation = DimensionData.Presentation;
		NwRw = MeasurementsData.Add();
		FillPropertyValues(NwRw, DimensionData);
	EndDo;

	If ClearingObject Then
		Object.DataOnTime.Clear();
	EndIf;

	ScheduleByDate.Clear();
	WhenChangingPeriodsOnServer();
	TimeTrackingServer.CopyToCrossTable(Object, ThisObject);
	ApprovedOnChangeAtServer();
	SetVisibilityAvailabilityServer();

EndProcedure

&AtServer
Procedure SaveDataATServer()

	Object.DataOnTime.Clear();
	TimeTrackingServer.CopyFromCrossTable(Object, ThisObject);

EndProcedure

&AtServer
Procedure SaveUpdateDataATServer(ClearingObject = True)

	SaveDataATServer();
	UpdateDataOnServer(ClearingObject);

EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityServer()

	Items.InputOption.Enabled = Not SelectedMeasurements.Count() = 1;

EndProcedure

&AtClient
Function GetDataForAutocompletionClient()

	If AutoCompleteDaysOption = 0 Then
		Return GetCalendarScheduleDataServer();
	Else
		Return Undefined;
	EndIf;

EndFunction

&AtServer
Function GetCalendarScheduleDataServer()

	Query = New Query;
	Query.Text =
	"SELECT
	|	CalendarSchedules.Calendar AS Calendar,
	|	CalendarSchedules.ScheduleDate AS ScheduleDate,
	|	CalendarSchedules.DayAddedToSchedule AS DayAddedToSchedule,
	|	CalendarSchedules.DaysCountInScheduleSinceBegOfYear AS DaysCountInScheduleSinceBegOfYear
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|WHERE
	|	CalendarSchedules.Calendar IN(&SelectedCalendars)
	|	AND CalendarSchedules.ScheduleDate BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND CalendarSchedules.DayAddedToSchedule
	|TOTALS BY
	|	Calendar";

	Query.SetParameter("SelectedCalendars", SelectedMeasurements.UnloadValues());
	Query.SetParameter("BeginOfPeriod", Object.BeginningDateOfPeriod);
	Query.SetParameter("PeriodEnding", Object.EndingDateOfPeriod);

	DataByCalendars = New Map;
	SelectionByCalendars = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionByCalendars.Next() Do
		ScheduleDates = New Map;
		Selection = SelectionByCalendars.Select();
		While Selection.Next() Do
			ScheduleDates.Insert(Selection.ScheduleDate, Selection.DayAddedToSchedule);
		EndDo;
		DataByCalendars.Insert(SelectionByCalendars.Calendar, ScheduleDates);
	EndDo;
	Return DataByCalendars;

EndFunction

&AtClient
Procedure RecalculateTotalsOnClient()

	TableName = "ScheduleByDate";
	For CounterOfDimensions = 1 To NumberOfMeasurements Do
		NumberOfLines_1 =0;
		Postfix = ?(ByDays, "", "_Dimension" + CounterOfDimensions);
		ThisObject[TableName + "OverallTotalByLine"+"1" + Postfix] = 0;
		For Each ScheduleStr In ScheduleByDate Do
			ScheduleStr["LineSummary"+"1" + Postfix] = 0;
			NumberOfLines_1 = NumberOfLines_1 + 1;
			ScheduleStr.LineNumber = NumberOfLines_1;
			For Each PeriodString_ In ThisObject.TimeIntervals Do
				PeriodName = PeriodString_.ColumnName;
				CurrentValue = ScheduleStr["Dimension" + CounterOfDimensions + "_" + PeriodName];
				ValueAdd = ?(ByDays, ?(ValueIsFilled(CurrentValue), 1, 0), ?(CurrentValue, 1, 0));
				ScheduleStr["LineSummary"+"1" + Postfix] = ScheduleStr["LineSummary"+"1" + Postfix] + ValueAdd;

				If NumberOfLines_1 = 1 Then
					ThisObject[TableName + "ColumnSummary_"+"_"+"Dimension" + CounterOfDimensions + "_" + PeriodName] = 0;
				EndIf;
				ThisObject[TableName + "ColumnSummary_"+"_"+"Dimension" + CounterOfDimensions + "_"
					+ PeriodName] = ThisObject[TableName + "ColumnSummary_"+"_"+"Dimension" + CounterOfDimensions + "_" + PeriodName]
					+ ValueAdd;
			EndDo;
			ThisObject[TableName + "OverallTotalByLine"+"1" + Postfix] = ThisObject[TableName + "OverallTotalByLine"+"1"
				+ Postfix] + ScheduleStr["LineSummary"+"1" + Postfix];
		EndDo;
	EndDo;

EndProcedure

&AtServer
Procedure FillEmployeesOnServer()

	ScheduleByDate.Clear();
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("Department", Object.Department);
	FilterStructure1.Insert("Employee", Catalogs.EmployeesHR.EmptyRef());
	FilterStructure1.Insert("BeginOfPeriod", Object.BeginningDateOfPeriod);
	FilterStructure1.Insert("PeriodEnding", EndOfDay(Object.EndingDateOfPeriod));
	EmployeeTable = TimeTrackingServer.GetWorkingEmployees(FilterStructure1);

	NumberOfLines_1 = 1;
	For Each EmployeeLine In EmployeeTable Do
		NwRw = ScheduleByDate.Add();
		FillPropertyValues(NwRw, EmployeeLine);
		NwRw.LineNumber = NumberOfLines_1;
		NumberOfLines_1 = NumberOfLines_1 + 1;
	EndDo;

EndProcedure

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)

	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);

EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()

	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);

EndProcedure
// End StandardSubsystems.AttachableCommands

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
	If Item.Name = "sh_ShamsiInput_BeginningDateOfPeriod" Then
		BeginningDateOfPeriodOnChange(Items.BeginningDateOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_EndingDateOfPeriod" Then
		EndingDateOfPeriodOnChange(Items.EndingDateOfPeriod);
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
