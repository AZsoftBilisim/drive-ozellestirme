#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Filter.Property("WorkingForPeriod") Then
		List.QueryText = QueryTextWorkingForPeriod();
	EndIf;
	
	If Parameters.Filter.Property("ItWorks") Then
		CommonClientServer.SetDynamicListFilterItem(
		List, "ItWorks", Parameters.Filter.ItWorks, DataCompositionComparisonType.Equal,, True);
	Else
		CommonClientServer.SetDynamicListFilterItem(
		List, "ItWorks", True, DataCompositionComparisonType.Equal,, False);
	EndIf;
	
	If Parameters.Filter.Property("Organization") Then
		CommonClientServer.SetDynamicListParameter(
		List, "Organization", Parameters.Filter.Organization);
	Else
		CommonClientServer.SetDynamicListParameter(
		List, "Organization", Catalogs.Companies.EmptyRef());
	EndIf;
	
	If Parameters.Filter.Property("Department") Then
		CommonClientServer.SetDynamicListFilterItem(
		List, "Department", Parameters.Filter.Department, DataCompositionComparisonType.InHierarchy,, True);
	Else
		CommonClientServer.SetDynamicListFilterItem(
		List, "Department", Catalogs.BusinessStructure.EmptyRef(), DataCompositionComparisonType.InHierarchy,, False);
	EndIf; 
	
	If Parameters.Filter.Property("Period") Then
		CommonClientServer.SetDynamicListParameter(
		List, "Period", Parameters.Filter.Period);
	EndIf;
	
	If Parameters.Filter.Property("FilterApplyPeriodStart") Then
		CommonClientServer.SetDynamicListParameter(
		List, "StartDate", BegOfDay(Parameters.Filter.FilterApplyPeriodStart));
		PeriodOfWork.StartDate = BegOfDay(Parameters.Filter.FilterApplyPeriodStart);
	EndIf;
	
	If Parameters.Filter.Property("FilterApplyPeriodEnd") Then
		CommonClientServer.SetDynamicListParameter(
		List, "EndDate", EndOfDay(Parameters.Filter.FilterApplyPeriodEnd));
		PeriodOfWork.EndDate = EndOfDay(Parameters.Filter.FilterApplyPeriodEnd);
	EndIf;
	
	// Selection of employees in the archive
	If Parameters.Filter.Property("InArchive") And Parameters.Filter.InArchive = False Then
		VisibilityToHideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed = True;
		SetSelectionOfEmployeesInArchive(ThisObject, True);
		HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed = True;
		Parameters.Filter.Delete("InArchive");
	Else
		VisibilityToHideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed = False;
	EndIf;
	
	PeriodOfWork.Variant = StandardPeriodVariant.Custom;
	If Parameters.Property("AllowSelectionOfWorkingPeriod") Then
		CommonClientServer.SetFormItemProperty(
		Items, "PeriodOfWorkGroup", "Visible", Parameters.AllowSelectionOfWorkingPeriod);
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
	Items,
	"HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed",
	"Visible",
	VisibilityToHideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed);
	
	// Initializing the list of selected employees	
	AddressOfListOfSelectedEmployees = "";
	If Parameters.Property("AddressOfListOfSelectedEmployees", AddressOfListOfSelectedEmployees) Then
		If Not IsBlankString(AddressOfListOfSelectedEmployees) Then
			ListOfSelected.LoadValues(GetFromTempStorage(AddressOfListOfSelectedEmployees));
		EndIf;
	EndIf;
	
	SetListOfSelectedEmployees();
	
	If Parameters.MultipleChoice = True Then
		Items.List.MultipleChoice = True;
		Items.List.SelectionMode = TableSelectionMode.MultiRow;
	Else
		Items.List.SelectionMode = TableSelectionMode.SingleRow;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SelectedEmployees.Count() > 0 Then
		NotifyChoice(SelectedEmployees.UnloadValues());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformedOnChange(Item)
	
	SetSelectionOfEmployeesInArchive(ThisObject, HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed);
	
EndProcedure

&AtClient
Procedure PeriodOfWorkStartDateOnChange(Item)
	
	If PeriodOfWork.EndDate < PeriodOfWork.StartDate Then
		PeriodOfWork.EndDate = PeriodOfWork.StartDate;
	EndIf; 
	SetSelectionParametersByPeriod();
	
EndProcedure

&AtClient
Procedure PeriodOfWorkEndDateOnChange(Item)
	
	If PeriodOfWork.StartDate > PeriodOfWork.EndDate Then
		PeriodOfWork.StartDate = PeriodOfWork.EndDate;
	EndIf; 
	SetSelectionParametersByPeriod();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	PerformanceMonitorClient.TimeMeasurement("SelectionOfEmployeeInFormOfSelectingEmployeesDirectory");
	
	StandardProcessing = False;
	
	ArrayOfSelected = New Array;
	For Each IDOfSelectedRow In Items.List.SelectedRows Do
		RowSelected = Items.List.RowData(IDOfSelectedRow);
		ArrayOfSelected.Add(RowSelected.Ref);
	EndDo;
	
	If ArrayOfSelected.Count() > 0 Then
		
		If Items.List.MultipleChoice Then
			
			UpdateListOfSelected(ArrayOfSelected);
			If ArrayOfSelected.Count() > 1 Then
				Close();
			EndIf;
			
		Else
			
			If ListOfSelected.FindByValue(ArrayOfSelected[0]) = Undefined Then
				NotifyChoice(ArrayOfSelected[0]);
			Else
				Close();
			EndIf;
			
		EndIf;
		
	EndIf;
EndProcedure

#EndRegion

#Region Private

#Region MaintenanceOfListOfSelectedEmployees

&AtClientAtServerNoContext
Procedure SetSelectionOfEmployeesInArchive(Form, Use)
	
	If Use Then
		CommonClientServer.SetDynamicListFilterItem(
		Form.List, "InArchive", False);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(
		Form.List, "InArchive");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionParametersByPeriod()
	
	SelectionStartDate = BegOfDay(?(ValueIsFilled(PeriodOfWork.StartDate), PeriodOfWork.StartDate, '00010101'));
	EndDateInFilter = EndOfDay(?(ValueIsFilled(PeriodOfWork.EndDate), PeriodOfWork.EndDate, Common.CurrentUserDate()));
	
	CommonClientServer.SetDynamicListParameter(
	List, "StartDate", SelectionStartDate, True);
	
	CommonClientServer.SetDynamicListParameter(
	List, "EndDate", EndDateInFilter, True);
	
EndProcedure

&AtServer
Procedure SetListOfSelectedEmployees()
	
	ConditionalAppearanceItem = Undefined;
	For Each AppearanceItem In ConditionalAppearance.Items Do
		If AppearanceItem.Presentation = NStr("vi = 'Chọn nhân viên đã chọn';
												|ru = 'Выделение подобранных';
												|en = 'Select the picked'; fa = 'انتخاب موارد برگزیده';
												|it = 'Select the picked';
												|pl = 'Select the picked';
												|tr = 'Seçilenleri işaretleme'") Then
			ConditionalAppearanceItem = AppearanceItem;
			Break;
		EndIf;
	EndDo;
	
	If ConditionalAppearanceItem <> Undefined Then
		ConditionalAppearanceItem.Filter.Items[0].RightValue = ListOfSelected;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateListOfSelected(Val Value)
	
	If TypeOf(Value) = Type("Array") Then
		ValueList = Value;
	Else
		ValueList = CommonClientServer.ValueInArray(Value);
	EndIf;
	
	For Each ValueSelected In ValueList Do
		If ListOfSelected.FindByValue(ValueSelected) = Undefined Then
			ListOfSelected.Add(ValueSelected);
			SelectedEmployees.Add(ValueSelected);
		EndIf;
	EndDo;
	
	SetListOfSelectedEmployees();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SelectedValueTextHR);
	Item.Presentation = NStr("vi = 'Chọn nhân viên đã chọn';
							|ru = 'Выделение подобранных';
							|en = 'Select the picked'; fa = 'انتخاب موارد برگزیده';
							|it = 'Select the picked';
							|pl = 'Select the picked';
							|tr = 'Seçilenleri işaretleme'");
	
EndProcedure

#EndRegion

&AtServer
Function QueryTextWorkingForPeriod()

	Return "SELECT ALLOWED
			|	StatusAtBeginningOfPeriod.Employee AS Employee,
			|	MAX(StatusAtBeginningOfPeriod.Period) AS Period
			|INTO HighsAtBeginningOfPeriod
			|FROM
			|	InformationRegister.EmploymentRecord.SliceLast(&StartDate, Organization = &Organization) AS StatusAtBeginningOfPeriod
			|
			|GROUP BY
			|	StatusAtBeginningOfPeriod.Employee
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	HighsAtBeginningOfPeriod.Employee AS Employee,
			|	StatusAtBeginningOfPeriod.Department AS Department,
			|	StatusAtBeginningOfPeriod.JobTitle AS JobTitle,
			|	StatusAtBeginningOfPeriod.EmploymentKind AS EmploymentKind,
			|	CASE
			|		WHEN StatusAtBeginningOfPeriod.WorksInBusinessUnit
			|			THEN StatusAtBeginningOfPeriod.Period
			|		ELSE DATETIME(1, 1, 1)
			|	END AS DateOfAdmission
			|INTO WorkingAtBeginningOfPeriod
			|FROM
			|	HighsAtBeginningOfPeriod AS HighsAtBeginningOfPeriod
			|		INNER JOIN InformationRegister.EmploymentRecord.SliceLast(&StartDate, Organization = &Organization) AS StatusAtBeginningOfPeriod
			|		ON HighsAtBeginningOfPeriod.Period = StatusAtBeginningOfPeriod.Period
			|			AND HighsAtBeginningOfPeriod.Employee = StatusAtBeginningOfPeriod.Employee
			|WHERE
			|	StatusAtBeginningOfPeriod.WorksInBusinessUnit
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	EmploymentRecord.Employee AS Employee,
			|	EmploymentRecord.Department AS Department,
			|	EmploymentRecord.JobTitle AS JobTitle,
			|	EmploymentRecord.Period AS DateOfAdmission,
			|	EmploymentRecord.EmploymentKind AS EmploymentKind
			|INTO TechniquesForMovingInPeriod
			|FROM
			|	InformationRegister.EmploymentRecord AS EmploymentRecord
			|WHERE
			|	EmploymentRecord.Organization = &Organization
			|	AND EmploymentRecord.WorksInBusinessUnit
			|	AND EmploymentRecord.Period >= &StartDate
			|	AND EmploymentRecord.Period <= &EndDate
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	EmploymentRecord.Employee AS Employee,
			|	MAX(EmploymentRecord.Period) AS DateOfDismissal
			|INTO LayoffsInPeriod
			|FROM
			|	InformationRegister.EmploymentRecord AS EmploymentRecord
			|WHERE
			|	EmploymentRecord.Organization = &Organization
			|	AND NOT EmploymentRecord.WorksInBusinessUnit
			|	AND EmploymentRecord.Period >= &StartDate
			|	AND EmploymentRecord.Period <= &EndDate
			|
			|GROUP BY
			|	EmploymentRecord.Employee
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	WorkingAtBeginningOfPeriod.Employee AS Employee,
			|	WorkingAtBeginningOfPeriod.Department AS Department,
			|	WorkingAtBeginningOfPeriod.JobTitle AS JobTitle,
			|	WorkingAtBeginningOfPeriod.DateOfAdmission AS DateOfAdmission,
			|	WorkingAtBeginningOfPeriod.EmploymentKind AS EmploymentKind
			|INTO StartAndEndData
			|FROM
			|	WorkingAtBeginningOfPeriod AS WorkingAtBeginningOfPeriod
			|
			|UNION ALL
			|
			|SELECT
			|	TechniquesForMovingInPeriod.Employee,
			|	TechniquesForMovingInPeriod.Department,
			|	TechniquesForMovingInPeriod.JobTitle,
			|	TechniquesForMovingInPeriod.DateOfAdmission,
			|	TechniquesForMovingInPeriod.EmploymentKind
			|FROM
			|	TechniquesForMovingInPeriod AS TechniquesForMovingInPeriod
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	StartAndEndData.Employee AS Employee,
			|	StartAndEndData.Department AS Department,
			|	StartAndEndData.JobTitle AS JobTitle,
			|	MAX(StartAndEndData.DateOfAdmission) AS DateOfAdmission,
			|	StartAndEndData.EmploymentKind AS EmploymentKind
			|INTO DataAtBeginningAndEndAreGrouped
			|FROM
			|	StartAndEndData AS StartAndEndData
			|
			|GROUP BY
			|	StartAndEndData.Employee,
			|	StartAndEndData.Department,
			|	StartAndEndData.JobTitle,
			|	StartAndEndData.EmploymentKind
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	EmployeesHR.Ref AS Ref,
			|	DataAtBeginningAndEndAreGrouped.Department AS Department,
			|	DataAtBeginningAndEndAreGrouped.JobTitle AS JobTitle,
			|	DataAtBeginningAndEndAreGrouped.EmploymentKind AS EmploymentKind,
			|	DataAtBeginningAndEndAreGrouped.DateOfAdmission AS DateOfAdmission,
			|	ISNULL(LayoffsInPeriod.DateOfDismissal, DATETIME(1, 1, 1)) AS DateOfDismissal,
			|	EmployeesHR.Ref.Code AS Code,
			|	EmployeesHR.Ref.Individual AS Individual,
			|	TRUE AS ItWorks,
			|	EmployeesHR.Ref.Description AS Description,
			|	EmployeesHR.Ref.NameClarification AS NameClarification,
			|	EmployeesHR.Ref.InArchive AS InArchive,
			|	EmployeesHR.Ref.DataVersion AS DataVersion,
			|	EmployeesHR.Ref.ParentCompany AS ParentCompany,
			|	CASE
			|		WHEN EmployeesHR.Ref.HeadEmployee = VALUE(Catalog.EmployeesHR.EmptyRef)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS IsHeadEmployee,
			|	EmployeesHR.Ref.DeletionMark AS DeletionMark,
			|	CASE
			|		WHEN EmployeesHR.Ref.DeletionMark
			|			THEN 4
			|		ELSE 3
			|	END AS Pictogram
			|FROM
			|	Catalog.EmployeesHR AS EmployeesHR
			|		INNER JOIN DataAtBeginningAndEndAreGrouped AS DataAtBeginningAndEndAreGrouped
			|		ON EmployeesHR.Ref = DataAtBeginningAndEndAreGrouped.Employee
			|		LEFT JOIN LayoffsInPeriod AS LayoffsInPeriod
			|		ON EmployeesHR.Ref = LayoffsInPeriod.Employee
			|";

EndFunction

#EndRegion