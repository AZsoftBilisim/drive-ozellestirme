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
			Parameters.CopyingValue.DataOnTime, SelectedMeasurements, "TimeKind");
		EndIf;

		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

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

	SetVisibilityAvailabilityOnClient();

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	TimeTrackingServer.FillInSelectedDimensions(Object.DataOnTime, SelectedMeasurements, "TimeKind");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DataOnTime.Employee AS Employee
		|INTO EmployeesHR
		|FROM
		|	&DataOnTime AS DataOnTime
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT EmployeesHR.Employee) AS EmployeesCount
		|FROM
		|	EmployeesHR AS EmployeesHR";
	Query.SetParameter("DataOnTime", CurrentObject.DataOnTime.Unload(,"Employee") );
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	If Selection.Next() And Selection.EmployeesCount = 1 Then
		OneEmployeeHasBeenSelected = Selection.EmployeesCount = 1;
		CacheOneEmployee = OneEmployeeHasBeenSelected;
		Employee = CurrentObject.DataOnTime[0].Employee;
	EndIf;

	TimeTrackingServer.CreatePeriodTable(ThisObject, "TimeIntervals");
	OnReadCreateAtServer();
	
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
		
		If Not CheckFilling() Then
			Cancel = True;
			Return;
		EndIf;
		
		ObjectData = New Structure("Organization, BeginningDateOfPeriod, EndingDateOfPeriod");
		ObjectData.Insert("Ref", Object.Ref);
		FillPropertyValues(ObjectData, Object);
		ObjectData.Insert("EmployeeTable", CurrentObject.DataOnTime.Unload(,"Employee, Date"));
		ObjectData.Insert("ObjectName", "TimesheetHR");
		ObjectData.Insert("ObjectPresentation", "TimeCard");
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

	If Object.InputOption = PredefinedValue("Enum.TimesheetInputOptions.Overall")
		And Object.EndingDateOfPeriod > EndOfMonth(Object.BeginningDateOfPeriod) Then
		Object.EndingDateOfPeriod = EndOfMonth(Object.BeginningDateOfPeriod);
	EndIf;
	UpdateDataOnServer(False);
	RecalculateTotalsOnClient();
	SetVisibilityAvailabilityOnClient();

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

	SetVisibilityAvailabilityOnClient();
	UpdateDataOnServer();

EndProcedure

&AtClient
Procedure Approved_1OnChange(Item)
	ApprovedOnChangeAtServer();
EndProcedure

&AtClient
Procedure EmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	EmployeeBeginningOfSelectionOnClient(StandardProcessing, Items.Employee);
EndProcedure

&AtClient
Procedure EmployeeOnChange(Item)

	OneEmployeeHasBeenSelected = ValueIsFilled(Employee);
	If Not OneEmployeeHasBeenSelected Then
		For Each TimeDataLine In Object.DataOnTime Do
			TimeDataLine.LineNumberEmployee = 0;
		EndDo;
	EndIf;
	UpdateStructure = Not OneEmployeeHasBeenSelected = CacheOneEmployee;
	UpdateDataOnServer(False, UpdateStructure);
	CacheOneEmployee = OneEmployeeHasBeenSelected;
	SetVisibilityAvailabilityOnClient();

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
			If Not Item.CurrentData.Employee = ValueSelected Then
				Item.CurrentData.Employee = ValueSelected;
				ClearServerRowData(Item.CurrentRow);
			EndIf;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ScheduleByDateEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)

	EmployeeBeginningOfSelectionOnClient(StandardProcessing, Items.ScheduleByDate);

EndProcedure

&AtClient
Procedure ScheduleByDateEmployeeChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding,
	StandardProcessing)

	If Not ValueSelected = Undefined Then
		If ScheduleByDate.FindRows(New Structure("Employee", ValueSelected)).Count() = 0 Then
			CurrentData = Items.ScheduleByDate.CurrentData;
			For CounterOfDimensions = 1 To SelectedMeasurements.Count() Do
				CurrentData["Dimension" + CounterOfDimensions] = SelectedMeasurements.Get(CounterOfDimensions - 1).Value;
			EndDo;
		Else
			StandardProcessing = False;
			MessageText = NStr("ru = 'Выбранный сотрудник уже добавлен в документ ранее';
								|vi = 'The selected employee is already added to the document';
								|en = 'The selected employee is already added to the document'; fa = 'The selected employee is already added to the document';
								|it = 'The selected employee is already added to the document';
								|pl = 'The selected employee is already added to the document';
								|tr = 'Seçilen çalışan daha önce belgeye eklenmiş.'");
			CommonClient.MessageToUser(MessageText);
		EndIf;
	EndIf;

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
Procedure Fill(Command)

	If CheckFilling() Then
		FillAtServer();
	EndIf;

EndProcedure

&AtClient
Procedure SetDateInterval(Command)

	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);

	TMCommonUseClient.EditPeriod(
		Object, New Structure("StartDate, EndDate", "BeginningDateOfPeriod", "EndingDateOfPeriod"), Notification);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure EmployeeBeginningOfSelectionOnClient(StandardProcessing, FormItem)
	
	StandardProcessing = False;
	ParametersForOpeningSelection = New Structure();
	ParametersForOpeningSelection.Insert("Organization", Object.Organization);
	ParametersForOpeningSelection.Insert("Department", Object.Department);
	ParametersForOpeningSelection.Insert("WorkingForPeriod", True);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodStart", Object.BeginningDateOfPeriod);
	ParametersForOpeningSelection.Insert("FilterApplyPeriodEnd", EndOfDay(Object.EndingDateOfPeriod));
	ParametersForOpeningSelection.Insert("MultipleChoice", False);
	DocumentsPayrollAndHumanResourcesClient.EmployeeRecruitment(ThisObject, ParametersForOpeningSelection, FormItem);
	
EndProcedure

&AtServer
Function AddressOfListOfSelectedEmployees()

	Selected_Employees = CommonClientServer.CollapseArray(ScheduleByDate.Unload( ,
		"Employee").UnloadColumn("Employee"));
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
Procedure UpdateDataOnServer(ClearTimeData = True, ToUpdateStructure = True)

	NumberOfMeasurements = SelectedMeasurements.Count();
	ByDays = Object.InputOption = Enums.TimesheetInputOptions.ByDays;
	MeasurementsData.Clear();

	For Each Dimension In SelectedMeasurements Do
		DimensionData = Common.ObjectAttributesValues(Dimension.Value,
			"Ref, Presentation, UnitOfMeasure, NumberOfHoursPerDay, WorkingTime");
		Dimension.Presentation = DimensionData.Presentation;
		NwRw = MeasurementsData.Add();
		FillPropertyValues(NwRw, DimensionData);
	EndDo;

	If ClearTimeData Then
		Object.DataOnTime.Clear();
	EndIf;

	ScheduleByDate.Clear();
	If ToUpdateStructure Then
		WhenChangingPeriodsOnServer();
	EndIf;
	TimeTrackingServer.CopyToCrossTable(Object, ThisObject);
	ApprovedOnChangeAtServer();

EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOnClient()

	Items.InputOption.Enabled = Not SelectedMeasurements.Count() = 1;
	Items.ScheduleByDateGroupTotal.FixingInTable = ?(OneEmployeeHasBeenSelected, FixingInTable.None,
		FixingInTable.Right);
	Items.ScheduleByDateGroupSelectedMeasurements.Group = ?(OneEmployeeHasBeenSelected,
		ColumnsGroup.Horizontal, ColumnsGroup.Vertical);

	Items.ScheduleByDatesGroupFixedColumns.FixingInTable = ?(ByDays, FixingInTable.Left,
		FixingInTable.None);

	Items.ScheduleByDateDate.Visible			= OneEmployeeHasBeenSelected And Not Object.InputOption
		= Enums.TimesheetInputOptions.Overall;
	Items.ScheduleByDateLineNumber.Visible		= Not OneEmployeeHasBeenSelected;
	Items.ScheduleByDateEmployee.Visible 		= Not OneEmployeeHasBeenSelected;
	Items.ScheduleByDate.ChangeRowOrder 	= Not OneEmployeeHasBeenSelected;
	Items.ScheduleByDate.ChangeRowSet 		= Not OneEmployeeHasBeenSelected;
	Items.ScheduleByDatePickup.Enabled 		= Not OneEmployeeHasBeenSelected;
	Items.ScheduleByDateFind.Enabled 		= Not OneEmployeeHasBeenSelected;
	Items.ScheduleByDate.ContextMenu.ChildItems.ScheduleByDateContextMenuDelete.Enabled 
	= Not OneEmployeeHasBeenSelected;

EndProcedure

&AtServer
Procedure ClearServerRowData(LineID)
	
	CurrentRow = ScheduleByDate.FindByID(LineID);
	If Not CurrentRow = Undefined Then
		TableAttributes = GetAttributes("ScheduleByDate");
		For Each Attribute In TableAttributes Do
			If StrFind(Attribute.Name, "Dimension")>0 Or StrFind(Attribute.Name, "Total")>0 Then
				CurrentRow[Attribute.Name] = "";
			EndIf;
		EndDo;
	EndIf;
	For CounterOfDimensions = 1 To NumberOfMeasurements Do
		CurrentRow["Dimension" + CounterOfDimensions] = SelectedMeasurements[CounterOfDimensions - 1].Value;
	EndDo;
	
EndProcedure

&AtClient
Procedure RecalculateTotalsOnClient()

	TableName = "ScheduleByDate";
	NumberOfLines_1 =0;
	For Each ScheduleStr In ScheduleByDate Do
		NumberOfLines_1 = NumberOfLines_1 + 1;
		ScheduleStr.LineNumber = NumberOfLines_1;
		For CounterOfDimensions = 1 To SelectedMeasurements.Count() Do
			DimensionData = MeasurementsData.Get(CounterOfDimensions - 1);
			If ByDays And Not OneEmployeeHasBeenSelected Then
				NameWatch = "LineSummary"+1+"_Dimension" + CounterOfDimensions;
				NameDays  = "LineSummary"+2+"_Dimension" + CounterOfDimensions;
				ScheduleStr[NameWatch] = 0;
				ScheduleStr[NameDays] = 0;
				For Each PeriodString_ In ThisObject.TimeIntervals Do
					PeriodName = PeriodString_.ColumnName;
					If DimensionData.WorkingTime Then
						ValueAdd = ScheduleStr["Dimension" + CounterOfDimensions + "_" + PeriodName];
						If DimensionData.UnitOfMeasure = PredefinedValue(
							"Enum.TimeMeasureUnits.Hour") Then
							ScheduleStr[NameWatch] = ScheduleStr[NameWatch] + ValueAdd;
							If ValueAdd <> 0 Then
								ScheduleStr[NameDays] = ScheduleStr[NameDays] + 1;
							EndIf;
						Else
							ScheduleStr[NameWatch] = ScheduleStr[NameWatch] + DimensionData.NumberOfHoursPerDay
								* ValueAdd;
							ScheduleStr[NameDays] = ScheduleStr[NameDays] + ValueAdd;
						EndIf;
					EndIf;
				EndDo;
			Else
				NameWatch = "LineSummary"+1;
				NameDays  = "LineSummary"+2;
				If CounterOfDimensions = 1 Then
					ScheduleStr[NameWatch] = 0;
					ScheduleStr[NameDays] = 0;
				EndIf;
				If DimensionData.WorkingTime Then
					ValueAdd = ScheduleStr["Dimension" + CounterOfDimensions];
					If DimensionData.UnitOfMeasure = PredefinedValue(
						"Enum.TimeMeasureUnits.Hour") Then
						ScheduleStr[NameWatch] = ScheduleStr[NameWatch] + ScheduleStr["Dimension" + CounterOfDimensions];
					Else
						ScheduleStr[NameWatch] = ScheduleStr[NameWatch] + DimensionData.NumberOfHoursPerDay
							* ValueAdd;
						ScheduleStr[NameDays] = ScheduleStr[NameDays] + ValueAdd;
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndDo;

	For CounterOfDimensions = 1 To NumberOfMeasurements Do
		If ByDays And Not OneEmployeeHasBeenSelected Then
			ThisObject[TableName+"OverallTotalByLine"+1+"_Dimension" + CounterOfDimensions] 
			= ScheduleByDate.Total("LineSummary"+1+"_Dimension" + CounterOfDimensions);
			ThisObject[TableName+"OverallTotalByLine"+2+"_Dimension" + CounterOfDimensions] 
			= ScheduleByDate.Total("LineSummary"+2+"_Dimension" + CounterOfDimensions);
			For Each PeriodString_ In ThisObject.TimeIntervals Do
				PeriodName = PeriodString_.ColumnName;
				ThisObject[TableName+"ColumnSummary_"+"_Dimension" + CounterOfDimensions + "_"
					+ PeriodName] = ScheduleByDate.Total("Dimension" + CounterOfDimensions + "_" + PeriodName);
			EndDo;
		Else
			ThisObject[TableName+"OverallTotalByLine"+1] = ScheduleByDate.Total("LineSummary"+1);
			ThisObject[TableName+"OverallTotalByLine"+2] = ScheduleByDate.Total("LineSummary"+2);
			ThisObject[TableName+"ColumnSummary_"+"_Dimension" + CounterOfDimensions] = ScheduleByDate.Total(
				"Dimension" + CounterOfDimensions);
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure FillAtServer()

	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("Department", Object.Department);
	FilterStructure1.Insert("Employee", Employee);
	FilterStructure1.Insert("BeginOfPeriod", Object.BeginningDateOfPeriod);
	FilterStructure1.Insert("PeriodEnding", EndOfDay(Object.EndingDateOfPeriod));

	EmployeeTable = TimeTrackingServer.GetWorkingEmployees(FilterStructure1);

	Query = New Query;
	Query.Text =
	"SELECT
	|	CalendarsWorkSchedule.Ref AS WorkScheduleCalendar
	|INTO AvailableCharts
	|FROM
	|	Catalog.Calendars.WorkSchedule AS CalendarsWorkSchedule
	|WHERE
	|	CalendarsWorkSchedule.TimeKind IN(&SelectedTypesOfTime)
	|	AND NOT CalendarsWorkSchedule.Ref.DeletionMark
	|
	|GROUP BY
	|	CalendarsWorkSchedule.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0 AS Key
	|INTO Orders_
	|
	|UNION ALL
	|
	|SELECT
	|	1
	|
	|UNION ALL
	|
	|SELECT
	|	2
	|
	|UNION ALL
	|
	|SELECT
	|	3
	|
	|UNION ALL
	|
	|SELECT
	|	4
	|
	|UNION ALL
	|
	|SELECT
	|	5
	|
	|UNION ALL
	|
	|SELECT
	|	6
	|
	|UNION ALL
	|
	|SELECT
	|	7
	|
	|UNION ALL
	|
	|SELECT
	|	8
	|
	|UNION ALL
	|
	|SELECT
	|	9
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DATEADD(BEGINOFPERIOD(&BeginOfPeriod, DAY), DAY, P1.Key + P2.Key * 10 + P3.Key * 100) AS Period
	|INTO PeriodsList
	|FROM
	|	Orders_ AS P1
	|		INNER JOIN Orders_ AS P2
	|		ON (TRUE)
	|		INNER JOIN Orders_ AS P3
	|		ON (TRUE)
	|WHERE
	|	P1.Key + P2.Key * 10 + P3.Key * 100 <= DATEDIFF(&BeginOfPeriod, &PeriodEnding, DAY)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmploymentRecordSliceLast.Period AS Period,
	|	EmploymentRecordSliceLast.Employee AS Employee,
	|	EmploymentRecordSliceLast.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	CASE
	|		WHEN EmploymentRecordSliceLast.EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal)
	|			THEN FALSE
	|		WHEN EmploymentRecordSliceLast.EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Move)
	|			THEN EmploymentRecordSliceLast.WorksInBusinessUnit
	|		ELSE TRUE
	|	END AS ItWorks
	|INTO ChartsForPeriod
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(
	|			&BeginOfPeriod,
	|			Organization = &Organization
	|				AND CASE
	|					WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|						THEN TRUE
	|					ELSE Department = &Department
	|				END
	|				AND Employee IN (&SelectedEmployees)) AS EmploymentRecordSliceLast
	|WHERE
	|	EmploymentRecordSliceLast.WorksInBusinessUnit
	|
	|UNION ALL
	|
	|SELECT
	|	EmploymentRecord.Period,
	|	EmploymentRecord.Employee,
	|	EmploymentRecord.WorkScheduleCalendar,
	|	CASE
	|		WHEN EmploymentRecord.EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Dismissal)
	|			THEN FALSE
	|		WHEN EmploymentRecord.EventKind = VALUE(Enum.HREventKindsPayrollAndHumanResources.Move)
	|			THEN EmploymentRecord.WorksInBusinessUnit
	|		ELSE TRUE
	|	END
	|FROM
	|	InformationRegister.EmploymentRecord AS EmploymentRecord
	|WHERE
	|	EmploymentRecord.Period > &BeginOfPeriod
	|	AND EmploymentRecord.Period <= &PeriodEnding
	|	AND EmploymentRecord.Organization = &Organization
	|	AND CASE
	|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN TRUE
	|			ELSE EmploymentRecord.Department = &Department
	|		END
	|	AND EmploymentRecord.Employee IN(&SelectedEmployees)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChartsForPeriod_Beginning.Employee AS Employee,
	|	ChartsForPeriod_Beginning.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	ChartsForPeriod_Beginning.Period AS BeginOfPeriod,
	|	ISNULL(MIN(ChartsForPeriod_End.Period), &PeriodEnding) AS PeriodEnding,
	|	ChartsForPeriod_Beginning.ItWorks AS ItWorks
	|INTO ChartPeriods
	|FROM
	|	ChartsForPeriod AS ChartsForPeriod_Beginning
	|		LEFT JOIN ChartsForPeriod AS ChartsForPeriod_End
	|		ON ChartsForPeriod_Beginning.Employee = ChartsForPeriod_End.Employee
	|			AND ChartsForPeriod_Beginning.Period < ChartsForPeriod_End.Period
	|
	|GROUP BY
	|	ChartsForPeriod_Beginning.Employee,
	|	ChartsForPeriod_Beginning.Period,
	|	ChartsForPeriod_Beginning.WorkScheduleCalendar,
	|	ChartsForPeriod_Beginning.ItWorks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodsList.Period AS Period,
	|	EmployeesHR.Ref AS Employee
	|INTO EmployeesByPeriod
	|FROM
	|	PeriodsList AS PeriodsList
	|		INNER JOIN Catalog.EmployeesHR AS EmployeesHR
	|		ON (TRUE)
	|WHERE
	|	EmployeesHR.Ref IN(&SelectedEmployees)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmployeesByPeriod.Period AS Period,
	|	EmployeesByPeriod.Employee AS Employee,
	|	ISNULL(ChartPeriods.WorkScheduleCalendar, VALUE(Catalog.Calendars.EmptyRef)) AS WorkScheduleCalendar,
	|	ISNULL(ChartPeriods.ItWorks, FALSE) AS ItWorks
	|INTO PersonnelDataByDay
	|FROM
	|	EmployeesByPeriod AS EmployeesByPeriod
	|		FULL JOIN ChartPeriods AS ChartPeriods
	|		ON EmployeesByPeriod.Period >= ChartPeriods.BeginOfPeriod
	|			AND EmployeesByPeriod.Period < ChartPeriods.PeriodEnding
	|			AND EmployeesByPeriod.Employee = ChartPeriods.Employee
	|WHERE
	|	ISNULL(ChartPeriods.ItWorks, FALSE) = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShiftScheduleHRDataOnTime.Employee AS Employee,
	|	ShiftScheduleHRDataOnTime.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	ShiftScheduleHRDataOnTime.Date AS Date
	|INTO ShiftScheduleData
	|FROM
	|	Document.ShiftScheduleHR.DataOnTime AS ShiftScheduleHRDataOnTime
	|		INNER JOIN PersonnelDataByDay AS PersonnelDataByDay
	|		ON ShiftScheduleHRDataOnTime.Employee = PersonnelDataByDay.Employee
	|			AND ShiftScheduleHRDataOnTime.Date = PersonnelDataByDay.Period
	|WHERE
	|	ShiftScheduleHRDataOnTime.Ref.Organization = &Organization
	|	AND CASE
	|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN TRUE
	|			ELSE ShiftScheduleHRDataOnTime.Ref.Department = &Department
	|		END
	|	AND ShiftScheduleHRDataOnTime.Employee IN(&SelectedEmployees)
	|	AND ShiftScheduleHRDataOnTime.Date BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND ShiftScheduleHRDataOnTime.Ref.Posted
	|	AND ShiftScheduleHRDataOnTime.WorkScheduleCalendar IN
	|			(SELECT
	|				AvailableCharts.WorkScheduleCalendar
	|			FROM
	|				AvailableCharts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShiftScheduleData.Employee AS Employee
	|INTO AllEmployeesShiftSchedules
	|FROM
	|	ShiftScheduleData AS ShiftScheduleData
	|
	|GROUP BY
	|	ShiftScheduleData.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmployeesByPeriod.Period AS Period,
	|	EmployeesByPeriod.Employee AS Employee,
	|	CASE
	|		WHEN AllEmployeesShiftSchedules.Employee IS NULL
	|			THEN PersonnelSchedulesByDay.WorkScheduleCalendar
	|		ELSE ISNULL(ShiftScheduleData.WorkScheduleCalendar, VALUE(Catalog.Calendars.EmptyRef))
	|	END AS WorkScheduleCalendar
	|INTO SummaryDataCalendarsCharts
	|FROM
	|	EmployeesByPeriod AS EmployeesByPeriod
	|		LEFT JOIN PersonnelDataByDay AS PersonnelSchedulesByDay
	|		ON EmployeesByPeriod.Period = PersonnelSchedulesByDay.Period
	|			AND EmployeesByPeriod.Employee = PersonnelSchedulesByDay.Employee
	|		LEFT JOIN ShiftScheduleData AS ShiftScheduleData
	|		ON EmployeesByPeriod.Period = ShiftScheduleData.Date
	|			AND EmployeesByPeriod.Employee = ShiftScheduleData.Employee
	|		LEFT JOIN AllEmployeesShiftSchedules AS AllEmployeesShiftSchedules
	|		ON EmployeesByPeriod.Employee = AllEmployeesShiftSchedules.Employee
	|WHERE
	|	ISNULL(PersonnelSchedulesByDay.ItWorks, FALSE)
	|	AND NOT CASE
	|				WHEN AllEmployeesShiftSchedules.Employee IS NULL
	|					THEN PersonnelSchedulesByDay.WorkScheduleCalendar
	|				ELSE ISNULL(ShiftScheduleData.WorkScheduleCalendar, VALUE(Catalog.Calendars.EmptyRef))
	|			END = VALUE(Catalog.Calendars.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryDataCalendarsCharts.Period AS Period,
	|	SummaryDataCalendarsCharts.Employee AS Employee,
	|	SummaryDataCalendarsCharts.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	CalendarsWorkSchedule.DayNumber AS DayNumber,
	|	CalendarsWorkSchedule.BeginTime AS BeginTime,
	|	CalendarsWorkSchedule.EndTime AS EndTime,
	|	CalendarsWorkSchedule.TimeKind AS TimeKind,
	|	DATEDIFF(CalendarsWorkSchedule.BeginTime, CalendarsWorkSchedule.EndTime, HOUR) AS Hours1,
	|	CASE
	|		WHEN CalendarsWorkSchedule.TimeKind.UnitOfMeasure = VALUE(Enum.TimeMeasureUnits.DAY)
	|			THEN 1
	|		ELSE 1
	|	END AS Days
	|INTO ByWeeks
	|FROM
	|	SummaryDataCalendarsCharts AS SummaryDataCalendarsCharts
	|		FULL JOIN Catalog.Calendars.WorkSchedule AS CalendarsWorkSchedule
	|			INNER JOIN Catalog.Calendars.FillingTemplate AS CalendarsFillingTemplate
	|			ON CalendarsWorkSchedule.DayNumber = CalendarsFillingTemplate.LineNumber
	|				AND CalendarsWorkSchedule.Ref = CalendarsFillingTemplate.Ref
	|		ON SummaryDataCalendarsCharts.WorkScheduleCalendar = CalendarsWorkSchedule.Ref
	|			AND (WEEKDAY(SummaryDataCalendarsCharts.Period) = CalendarsWorkSchedule.DayNumber)
	|WHERE
	|	SummaryDataCalendarsCharts.WorkScheduleCalendar.FillingMethod = VALUE(Enum.WorkScheduleFillingMethods.ByWeeks)
	|	AND CalendarsFillingTemplate.DayAddedToSchedule
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryDataCalendarsCharts.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	MAX(CalendarsFillingTemplate.LineNumber) AS Periodicity
	|INTO PeriodsOfArbitrarySchedules
	|FROM
	|	SummaryDataCalendarsCharts AS SummaryDataCalendarsCharts
	|		INNER JOIN Catalog.Calendars.FillingTemplate AS CalendarsFillingTemplate
	|		ON (SummaryDataCalendarsCharts.WorkScheduleCalendar.FillingMethod = VALUE(Enum.WorkScheduleFillingMethods.ByArbitraryLengthPeriods))
	|			AND SummaryDataCalendarsCharts.WorkScheduleCalendar = CalendarsFillingTemplate.Ref
	|
	|GROUP BY
	|	SummaryDataCalendarsCharts.WorkScheduleCalendar
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryDataCalendarsCharts.Period AS Period,
	|	SummaryDataCalendarsCharts.Employee AS Employee,
	|	SummaryDataCalendarsCharts.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	PeriodsOfArbitrarySchedules.Periodicity AS Periodicity,
	|	1 + DATEDIFF(SummaryDataCalendarsCharts.WorkScheduleCalendar.StartingDate, SummaryDataCalendarsCharts.Period, DAY) - INT(DATEDIFF(SummaryDataCalendarsCharts.WorkScheduleCalendar.StartingDate, SummaryDataCalendarsCharts.Period, DAY) / PeriodsOfArbitrarySchedules.Periodicity) * PeriodsOfArbitrarySchedules.Periodicity AS Position
	|INTO ByArbitraryCycles
	|FROM
	|	SummaryDataCalendarsCharts AS SummaryDataCalendarsCharts
	|		FULL JOIN PeriodsOfArbitrarySchedules AS PeriodsOfArbitrarySchedules
	|		ON SummaryDataCalendarsCharts.WorkScheduleCalendar = PeriodsOfArbitrarySchedules.WorkScheduleCalendar
	|		INNER JOIN InformationRegister.CalendarSchedules AS CalendarSchedules
	|		ON SummaryDataCalendarsCharts.Period = CalendarSchedules.ScheduleDate
	|			AND (YEAR(SummaryDataCalendarsCharts.Period) = CalendarSchedules.Year)
	|			AND SummaryDataCalendarsCharts.WorkScheduleCalendar = CalendarSchedules.Calendar
	|WHERE
	|	SummaryDataCalendarsCharts.WorkScheduleCalendar.FillingMethod = VALUE(Enum.WorkScheduleFillingMethods.ByArbitraryLengthPeriods)
	|	AND CalendarSchedules.DayAddedToSchedule
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ByArbitraryCycles.Period AS Date,
	|	ByArbitraryCycles.Employee AS Employee,
	|	ByArbitraryCycles.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	CalendarsWorkSchedule.TimeKind AS TimeKind,
	|	SUM(CASE
	|			WHEN HOUR(CalendarsWorkSchedule.EndTime) = 0
	|					AND MINUTE(CalendarsWorkSchedule.EndTime) = 0
	|				THEN 24 - HOUR(CalendarsWorkSchedule.BeginTime)
	|			ELSE HOUR(CalendarsWorkSchedule.EndTime) - HOUR(CalendarsWorkSchedule.BeginTime)
	|		END) AS Hours1,
	|	SUM(CASE
	|			WHEN CalendarsWorkSchedule.TimeKind.UnitOfMeasure = VALUE(Enum.TimeMeasureUnits.DAY)
	|				THEN 1
	|			ELSE 1
	|		END) AS Days
	|INTO AllDataWithGraphs
	|FROM
	|	ByArbitraryCycles AS ByArbitraryCycles
	|		INNER JOIN Catalog.Calendars.WorkSchedule AS CalendarsWorkSchedule
	|		ON ByArbitraryCycles.WorkScheduleCalendar = CalendarsWorkSchedule.Ref
	|			AND ByArbitraryCycles.Position = CalendarsWorkSchedule.DayNumber
	|WHERE
	|	CalendarsWorkSchedule.TimeKind IN(&SelectedTypesOfTime)
	|
	|GROUP BY
	|	ByArbitraryCycles.Employee,
	|	ByArbitraryCycles.WorkScheduleCalendar,
	|	ByArbitraryCycles.Period,
	|	CalendarsWorkSchedule.TimeKind
	|
	|UNION ALL
	|
	|SELECT
	|	ByWeeks.Period,
	|	ByWeeks.Employee,
	|	ByWeeks.WorkScheduleCalendar,
	|	ByWeeks.TimeKind,
	|	SUM(ByWeeks.Hours1),
	|	SUM(ByWeeks.Days)
	|FROM
	|	ByWeeks AS ByWeeks
	|WHERE
	|	ByWeeks.TimeKind IN(&SelectedTypesOfTime)
	|
	|GROUP BY
	|	ByWeeks.Employee,
	|	ByWeeks.TimeKind,
	|	ByWeeks.WorkScheduleCalendar,
	|	ByWeeks.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllDataWithGraphs.Employee AS Employee
	|INTO EmployeesWith_Data
	|FROM
	|	AllDataWithGraphs AS AllDataWithGraphs
	|
	|GROUP BY
	|	AllDataWithGraphs.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllDataWithGraphs.Date AS Date,
	|	AllDataWithGraphs.Employee AS Employee,
	|	AllDataWithGraphs.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	AllDataWithGraphs.TimeKind AS TimeKind,
	|	AllDataWithGraphs.Hours1 AS Hours1,
	|	AllDataWithGraphs.Days AS Days
	|FROM
	|	AllDataWithGraphs AS AllDataWithGraphs
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod,
	|	EmployeesHR.Ref,
	|	VALUE(Catalog.Calendars.EmptyRef),
	|	PayCodesHR.Ref,
	|	0,
	|	0
	|FROM
	|	Catalog.EmployeesHR AS EmployeesHR
	|		LEFT JOIN EmployeesWith_Data AS EmployeesWith_Data
	|		ON EmployeesHR.Ref = EmployeesWith_Data.Employee
	|		LEFT JOIN Catalog.PayCodesHR AS PayCodesHR
	|		ON (TRUE)
	|WHERE
	|	EmployeesHR.Ref IN(&SelectedEmployees)
	|	AND PayCodesHR.Ref IN(&SelectedTypesOfTime)
	|	AND EmployeesWith_Data.Employee IS NULL
	|
	|ORDER BY
	|	Employee,
	|	Date
	|TOTALS BY
	|	Employee";

	If OneEmployeeHasBeenSelected Then
		ArrayOfEmployees = New Array;
		ArrayOfEmployees.Add(Employee);
		Query.SetParameter("SelectedEmployees", ArrayOfEmployees);
	Else
		Query.SetParameter("SelectedEmployees", EmployeeTable.UnloadColumn("Employee"));
	EndIf;
	Query.SetParameter("SelectedTypesOfTime", SelectedMeasurements.UnloadValues());
	Query.SetParameter("Organization",   Object.Organization);
	Query.SetParameter("Department", Object.Department);
	Query.SetParameter("BeginOfPeriod", Object.BeginningDateOfPeriod);
	Query.SetParameter("PeriodEnding", EndOfDay(Object.EndingDateOfPeriod));
	QueryResult = Query.Execute();

	Object.DataOnTime.Clear();
	EmployeeCounter = 0;
	SampleEmployees = QueryResult.Select(QueryResultIteration.ByGroups);
	While SampleEmployees.Next() Do
		Selection = SampleEmployees.Select();
		While Selection.Next() Do
			NewString = Object.DataOnTime.Add();
			NewString.LineNumberEmployee = EmployeeCounter;
			FillPropertyValues(NewString, Selection);
		EndDo;
		EmployeeCounter = EmployeeCounter + 1;
	EndDo;
	TimeTrackingServer.CopyToCrossTable(Object, ThisObject);

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
