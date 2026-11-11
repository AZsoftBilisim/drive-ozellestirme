#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Filter.Property("ItWorks") Then
		CommonClientServer.SetDynamicListFilterItem(
		List, "ItWorks", Parameters.Filter.ItWorks, DataCompositionComparisonType.Equal,, True);
	Else
		CommonClientServer.SetDynamicListFilterItem(
		List, "ItWorks", True, DataCompositionComparisonType.Equal,, False);
	EndIf;
	//
	If Parameters.Filter.Property("Organization") Then
		CommonClientServer.SetDynamicListParameter(
		List, "Organization", Parameters.Filter.Organization);
	Else
		CommonClientServer.SetDynamicListParameter(
		List, "Organization", Catalogs.Companies.EmptyRef());
	EndIf;
	//
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
	Else
		CommonClientServer.SetDynamicListParameter(
		List, "Period", EndOfDay(CurrentSessionDate()));
	EndIf;
	
	// Selection of employees in the archive
	If Parameters.Filter.Property("InArchive") And Parameters.Filter.InArchive = False Then
		If Parameters.Filter.InArchive = False Then
			SetSelectionOfEmployeesInArchive(ThisObject, True);
			HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed = True;
		EndIf;
		
		Parameters.Filter.Delete("InArchive");
	EndIf;

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
	
	If SelectedIndividuals.Count() > 0 Then
		NotifyChoice(SelectedIndividuals.UnloadValues());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformedOnChange(Item)
	
	SetSelectionOfEmployeesInArchive(ThisObject, HideEmployeesForWhomNoOperationsAreAlreadyBeingPerformed);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
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
			SelectedIndividuals.Add(ValueSelected);
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
	Item.Presentation = "Select selected2";
	
EndProcedure

#EndRegion


#EndRegion