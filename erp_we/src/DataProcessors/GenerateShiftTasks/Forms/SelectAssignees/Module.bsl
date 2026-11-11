
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Department = Parameters.Department;
	DepartmentFilter = Parameters.Department;
	ShiftTask = Parameters.ShiftTask;
	ProductionArea = Parameters.ProductionArea;
	MultipleChoice = Parameters.MultipleChoice;
	AdditionalParameters = Parameters.AdditionalParameters;
	
	DateOfWork = Parameters.Date;
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	
	ChoiceMode = ?(DivisionParameters.UsePersonalWorkOrders, "Employees", "Teams");
	
	Items.ChoiceMode.Visible = DivisionParameters.UsePersonalWorkOrders
		And DivisionParameters.UseTeamWorkOrders;
		
	UsePersonalWorkOrders = DivisionParameters.UsePersonalWorkOrders;
	
	Items.ShiftsGroup.Title = ?(DivisionParameters.UseAreas,
		NStr("vi = 'Ca làm việc, Khu, Người thực hiện';
			|ru = 'Смена, Участок, Исполнитель';
			|en = 'Shift, Site, Assignee'; fa = 'Shift, Site, Assignee';
			|it = 'Turno, Reparto, Esecutore';
			|pl = 'Zmiana, Działka, Wykonawca';
			|tr = 'Vardiya, Saha, Atanan'"),
		NStr("vi = 'Ca làm việc, Người thực hiện';
			|ru = 'Смена, Исполнитель';
			|en = 'Shift, Assignee'; fa = 'شیفت، مجری';
			|it = 'Turno, Esecutore';
			|pl = 'Zmiana, Wykonawca';
			|tr = 'Vardiya, Atanan'"));
	
	ConfigureFormBySelectionMode(ThisObject);
	
	ShiftsNumber = ProductionServer.DivisionWorkSchedules(Department).Count();
	SeveralShiftsInDepartment = ShiftsNumber > 1;
	
	UsePayroll = GetFunctionalOption("UsePayroll");
	
	Items.GroupIsWorkingOnly.Visible = UsePayroll;
	Items.GroupWorkingOnDate.Visible = False;
	Items.CompanyGroup.Visible = False;
	
	
	ProductionAccountingLocalization.AddDataForEmployeeRecruitment(ThisObject, DateOfWork);
	
	ReadShifts(ShiftTask, ShiftsNumber + 1);
	
	SetSelectionByDivision();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChoiceModeOnChange(Item)
	
	ConfigureFormBySelectionMode(ThisObject);
	
EndProcedure

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	SetSelectionByDivision();
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	SetSelectionByOrganization();
	
EndProcedure

&AtClient
Procedure OnlyWorkingOnChange(Item)
	CommonClientServer.SetDynamicListParameter(Employees, "OnlyWorking", OnlyWorking);
EndProcedure

&AtClient
Procedure WorkingOnDateOnChange(Item)
	CommonClientServer.SetDynamicListParameter(
		Employees,
		"WorkingOnDate",
		Boolean(WorkingOnDate));
	
	CommonClientServer.SetDynamicListParameter(
		Employees,
		"DateOfWork",
		?(ValueIsFilled(DateOfWork), DateOfWork, CommonClient.SessionDate()));
	
	Items.DateOfWork.Enabled = Boolean(WorkingOnDate);
EndProcedure

&AtClient
Procedure DateOfWorkOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	CommonClientServer.SetDynamicListParameter(Employees, "DateOfWork", ?(ValueIsFilled(DateOfWork), DateOfWork, CommonClient.SessionDate()));
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersShifts

&AtClient
Procedure ShiftsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceProcessing();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployees

&AtClient
Procedure EmployeesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceProcessing();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTeams

&AtClient
Procedure TeamsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceProcessing();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ChoiceProcessing();
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	For Each String In Shifts.GetItems() Do
		Items.Shifts.Collapse(String.GetID());
	EndDo;
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	For Each String In Shifts.GetItems() Do
		Items.Shifts.Expand(String.GetID());
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Shifts - show hyperlink
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.ThisIsAnAction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	// Shifts - hide the row view
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.ThisIsAnAction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Shifts - hide hyperlink
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.ThisIsAnAction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
		
	// Shifts - show the row view
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.ThisIsAnAction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureFormBySelectionMode(Form)
	
	Items = Form.Items;
	
	Items.TeamsEmployees.CurrentPage = ?(Form.ChoiceMode = "Employees",
		Items.PageEmployees, Items.PageTeams);
	
	Items.CommandsEmployees.Visible = Form.ChoiceMode = "Employees";
	
	Items.CommandsTeams.Visible = Form.ChoiceMode <> "Employees";
	
	Items.OnlyWorking.Visible = Form.ChoiceMode = "Employees";
	
	Items.WorkingOnDate.Visible = Form.ChoiceMode = "Employees";
	
	Items.DateOfWork.Visible = Form.ChoiceMode = "Employees";
	
	Items.CompanyFilter.Visible = Form.ChoiceMode = "Employees";
	
EndProcedure

&AtClient
Procedure ChoiceProcessing()
	
	References = New Array;
	
	If Items.Pages.CurrentPage = Items.PreviousShifts Then
		
		Selected_Action = False;
		NewLineKey = -1;
		
		ProcessShiftSelectionOnServer(References, Selected_Action, NewLineKey);
		
		If References.UBound() = -1 And Not Selected_Action Then
			ShowMessageBox(, NStr("vi = 'Không có mục nào để chọn';
									|ru = 'Не выделены элементы для выбора';
									|en = 'Items for selection are not highlighted'; fa = 'Items for selection are not highlighted';
									|it = 'Nessun elemento selezionato per la selezione';
									|pl = 'Nie wydzielono elementów do wyboru';
									|tr = 'Seçim için öğeler belirtilmedi'"));
		EndIf;
		
		If NewLineKey <> -1 Then
			Items.Shifts.Expand(NewLineKey);
		EndIf;
		
	Else
		
		List = Items[ChoiceMode];
		GroupSelected = False;
		
		For Each String In List.SelectedRows Do
			If TypeOf(String) <> Type("DynamicListGroupRow") Then
				
				
				References.Add(String);
			Else
				GroupSelected = True;
			EndIf;
		EndDo;
		
		If References.UBound() = -1 Then
			
			If GroupSelected Then
				WarningText = NStr("vi = 'Lệnh không thể được thực thi cho chuỗi nhóm danh sách';
									|ru = 'Команда не может быть выполнена для строки группировки списка';
									|en = 'Cannot execute the command for the list grouping row'; fa = 'Cannot execute the command for the list grouping row';
									|it = 'Il comando non può essere eseguito per la riga di raggruppamento dell''elenco';
									|pl = 'Polecenie nie może być wykonane dla wiersza grupowania listy';
									|tr = 'Liste gruplandırma satırı için komut gerçekleştirilemez'");
			Else
				WarningText = NStr("vi = 'Không có mục nào để chọn';
									|ru = 'Не выделены элементы для выбора';
									|en = 'Items for selection are not highlighted'; fa = 'Items for selection are not highlighted';
									|it = 'Nessun elemento selezionato per la selezione';
									|pl = 'Nie wydzielono elementów do wyboru';
									|tr = 'Seçim için öğeler belirtilmedi'");
			EndIf;
			ShowMessageBox(, WarningText);
		EndIf;
		
	EndIf;
	
	If References.Count() > 1 And Not MultipleChoice Then
		
		ShowMessageBox(, NStr("vi = 'Chỉ có một người thực hiện có thể được chọn.';
								|ru = 'Может быть выбран лишь один исполнитель';
								|en = 'Only one assignee can be selected'; fa = 'Only one assignee can be selected';
								|it = 'È possibile selezionare solo un esecutore';
								|pl = 'Może być wybrany tylko jeden wykonawca';
								|tr = 'Sadece bir atanan seçilmiş olabilir'"));
		
	ElsIf References.UBound() <> -1 Then
		
		SelectionValue = New Structure;
		SelectionValue.Insert("ShiftTask", ShiftTask);
		SelectionValue.Insert("References", References);
		SelectionValue.Insert("AdditionalParameters", AdditionalParameters);
		
		NotifyChoice(SelectionValue);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessShiftSelectionOnServer(References, Selected_Action, NewLineKey)
	
	StringAction = Undefined;
	
	For Each String In Items.Shifts.SelectedRows Do
		
		RowData = Shifts.FindByID(String);
		
		If RowData.ThisIsAnAction Then
			
			Selected_Action = True;
			StringAction = RowData;
			
		ElsIf TypeOf(RowData.Ref) = Type("DocumentRef.ShiftTask") Then
			
			For Each DescendantData In RowData.GetItems() Do
				
				If References.Find(DescendantData.Ref) = Undefined Then
					References.Add(DescendantData.Ref);
				EndIf;
				
			EndDo;
			
		Else
			
			If References.Find(RowData.Ref) = Undefined Then
				References.Add(RowData.Ref);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If References.UBound() = -1 And Selected_Action Then
		
		Rows = Shifts.GetItems();
		
		ReadShifts(Rows[Rows.IndexOf(StringAction) - 1].Ref, 1);
		
		Rows.Delete(StringAction);
		
		For IndexOf = -Rows.Count()+1 To 0 Do
			
			If Not Rows[-IndexOf].ThisIsAnAction Then
				NewLineKey = Rows[-IndexOf].GetID();
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadShifts(PointOfReference, Count)
	
	QueryText =
		"SELECT TOP 10000
		|	ShiftTask.Ref  AS Ref,
		|	ShiftTask.Shift   AS Shift,
		|	ShiftTask.Date    AS Date,
		|	ShiftTask.ProductionArea AS ProductionArea
		|INTO ttRefs
		|FROM
		|	Document.ShiftTask AS PointOfReference
		|		INNER JOIN Document.ShiftTask AS ShiftTask
		|		ON PointOfReference.Department = ShiftTask.Department
		|			AND PointOfReference.ProductionArea = ShiftTask.ProductionArea
		|			AND PointOfReference.Date > ShiftTask.Date
		|			AND ShiftTask.Posted
		|WHERE
		|	PointOfReference.Ref = &PointOfReference
		|	AND TRUE IN (SELECT TOP 1 TRUE FROM Document.ShiftTask.Assignees AS T WHERE T.Ref = ShiftTask.Ref)
		|
		|ORDER BY
		|	ShiftTask.Date DESC
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ShiftTask.Ref                 AS Ref,
		|	ShiftTask.Shift                  AS Shift,
		|	ShiftTask.Date                   AS Date,
		|	ShiftTask.ProductionArea                AS ProductionArea,
		|	ShiftTaskAssignees.Performer AS Performer,
		|	ShiftTaskAssignees.Performer.Description AS PerformerPresentation
		|FROM
		|	ttRefs AS ShiftTask
		|		LEFT JOIN Document.ShiftTask.Assignees AS ShiftTaskAssignees
		|		ON ShiftTask.Ref = ShiftTaskAssignees.Ref
		|
		|ORDER BY
		|	Date DESC,
		|	PerformerPresentation
		|TOTALS BY
		|	Ref";
	
	QueryText = StrReplace(QueryText, "10000", Format(Count + 1, "NG=0;"));
	
	Query = New Query(QueryText);
	Query.SetParameter("Department", Department);
	Query.SetParameter("ProductionArea", ProductionArea);
	Query.SetParameter("PointOfReference", PointOfReference);
	
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	Cnt = 1;
	
	While SampleResults.Next() Do
		
		Selection = SampleResults.Select();
		Selection.Next();
		
		LineChange = Shifts.GetItems().Add();
		LineChange.Ref = Selection.Ref;
		LineChange.Presentation = ProductionManagementClientServer.ShiftTaskPresentation_(
			Selection.Shift, Selection.Date, Selection.ProductionArea, SeveralShiftsInDepartment);
		
		Selection.Reset();
		While Selection.Next() Do
			
			LinePerformer = LineChange.GetItems().Add();
			LinePerformer.Ref = Selection.Performer;
			LinePerformer.Presentation = Selection.PerformerPresentation;
			
		EndDo;
		
		If Cnt = Count Then
			Break;
		EndIf;
		Cnt = Cnt + 1;
		
	EndDo;
	
	If SampleResults.Count() > Count Then
		
		StringAction = Shifts.GetItems().Add();
		StringAction.Action = NStr("vi = '<hiển thị thêm>';
									|ru = '<показать еще>';
									|en = '<show more>'; fa = '<show more>';
									|it = '<mostrare di più>';
									|pl = '<pokaż jeszcze>';
									|tr = '<daha fazla göster>'");
		StringAction.ThisIsAnAction = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(
		Teams, 
		"Department", 
		DepartmentFilter, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(DepartmentFilter));
	
	If (GetFunctionalOption("UsePayroll")
		Or ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate()))
		And UsePersonalWorkOrders Then

		CommonClientServer.SetDynamicListFilterItem(
			Employees, 
			"Department", 
			DepartmentFilter,
			DataCompositionComparisonType.Equal,
			, // Presentation - automatically
			ValueIsFilled(DepartmentFilter));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByOrganization()
	
	If UsePersonalWorkOrders Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Employees, 
			"Organization", 
			CompanyFilter,
			DataCompositionComparisonType.Equal,
			, // Presentation - automatically
			ValueIsFilled(CompanyFilter));
		
	EndIf;
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_DateOfWork" Then
		DateOfWorkOnChange(Items.DateOfWork);
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
