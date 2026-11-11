#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	Items.GroupWarehouses.Visible     = Not EditModeWarehouses;
	Items.GroupEmployees.Visible = EditModeWarehouses;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWarehouses

&AtClient
Procedure WarehousesOnActivateRow(Item)
	FillInEmployees(Item.CurrentRow);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployeesHR

&AtClient
Procedure EmployeesHRBeforeDeleteRow(Item, Cancel)
	
	Warehouse = Items.Warehouses.CurrentRow;
	
	For Each RowIndex In Item.SelectedRows Do
		EmployeeLine = EmployeesHR.FindByID(RowIndex);
		DeleteEmployeeInformation(EmployeeLine.Employee, Warehouse);
	EndDo;
	
EndProcedure

&AtClient
Procedure EmployeesHROnEditEnd(Item, NewRow, CancelEdit)
	
	Warehouse = Items.Warehouses.CurrentRow;
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentData.Employee <> CurrentEmployee Then
		DeleteEmployeeInformation(CurrentEmployee, Warehouse);
	EndIf;
	
	RecordEmployeeInformation(Items.EmployeesHR.CurrentRow, Warehouse);
	
EndProcedure

&AtClient
Procedure EmployeesHROnActivateRow(Item)
	
	Try
		CurrentEmployee = Item.CurrentData.Employee;
	Except
	EndTry;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployeesHR2

&AtClient
Procedure EmployeesHR2OnActivateRow(Item)
	FillWarehouses_(Item.CurrentRow);
EndProcedure

&AtClient
Procedure Warehouses2OnActivateRow(Item)
	
	Try
		CurrentWarehouse = Item.CurrentData.Warehouse;
	Except
	EndTry;
	
EndProcedure

&AtClient
Procedure Warehouses2BeforeDeleteRow(Item, Cancel)
	
	Employee = Items.EmployeesHR2.CurrentRow;
	
	For Each RowIndex In Item.SelectedRows Do
		WarehouseLine = Warehouses2.FindByID(RowIndex);
		DeleteEmployeeInformation(Employee, WarehouseLine.Warehouse);
	EndDo;

EndProcedure

&AtClient
Procedure Warehouses2OnEditEnd(Item, NewRow, CancelEdit)
	
	Employee = Items.EmployeesHR2.CurrentRow;
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentData.Warehouse <> CurrentWarehouse Then
		DeleteEmployeeInformation(Employee, CurrentWarehouse);
	EndIf;
	
	RecordInformationAboutWarehouses(Items.Warehouses2.CurrentRow, Employee);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditModeOnChange(Item)
	
	Items.GroupWarehouses.Visible     = Not EditModeWarehouses;
	Items.GroupEmployees.Visible = EditModeWarehouses;
	
EndProcedure

&AtClient
Procedure AssignRoles(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ThisAppointment", True);
	
	OpenForm(
	"DataProcessor.DispatchingAssemblyAndDelivery.Form.RoleChoiceForm", FormOpenParameters
	,
	ThisObject,,,, New CallbackDescription("AssignRolesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ToRemoveTheRole(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ThisAppointment", False);
	
	OpenForm(
	"DataProcessor.DispatchingAssemblyAndDelivery.Form.RoleChoiceForm", FormOpenParameters
	,
	ThisObject,,,, New CallbackDescription("ToRemoveTheRoleCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AssignRolesToTheWarehouse(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ThisAppointment", True);
	
	OpenForm(
	"DataProcessor.DispatchingAssemblyAndDelivery.Form.RoleChoiceForm", FormOpenParameters
	,
	ThisObject,,,, New CallbackDescription("AssignRolesToTheWarehouseCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ToRemoveTheRoleOfTheWarehouse(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ThisAppointment", False);
	
	OpenForm(
	"DataProcessor.DispatchingAssemblyAndDelivery.Form.RoleChoiceForm", FormOpenParameters
	,
	ThisObject,,,, New CallbackDescription("ToRemoveTheRoleOfTheWarehouseCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Pickup(Command)
	
	CallbackDescription = New CallbackDescription("CompleteEmployeeRecruitment", ThisObject);
	
	OpenForm(
	"DataProcessor.DispatchingAssemblyAndDelivery.Form.EmployeePickingForm",,
	ThisObject,,,,CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInEmployees(Warehouse)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StoreEmployees.Employee AS Employee,
		|	StoreEmployees.Courier AS Courier,
		|	StoreEmployees.Picker AS Picker,
		|	StoreEmployees.Dispatcher AS Dispatcher
		|FROM
		|	InformationRegister.StoreEmployees AS StoreEmployees
		|WHERE
		|	StoreEmployees.Warehouse = &Warehouse";
	
	Query.SetParameter("Warehouse", Warehouse);
	
	QueryResult = Query.Execute().Unload();
	EmployeesHR.Load(QueryResult);
	
EndProcedure

&AtServer
Procedure FillWarehouses_(Employee)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StoreEmployees.Warehouse AS Warehouse,
		|	StoreEmployees.Courier AS Courier,
		|	StoreEmployees.Picker AS Picker,
		|	StoreEmployees.Dispatcher AS Dispatcher
		|FROM
		|	InformationRegister.StoreEmployees AS StoreEmployees
		|WHERE
		|	StoreEmployees.Employee = &Employee";
	
	Query.SetParameter("Employee", Employee);
	
	QueryResult = Query.Execute().Unload();
	Warehouses2.Load(QueryResult);
	
EndProcedure

&AtClient
Procedure AssignRolesCompletion(Result, TT) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Warehouse = Items.Warehouses.CurrentRow;
	
	For Each RowIndex In Items.EmployeesHR.SelectedRows Do
		
		EmployeeLine = EmployeesHR.FindByID(RowIndex);
		
		If Result.Dispatcher Then
			EmployeeLine.Dispatcher = True;
		EndIf;
		
		If Result.Picker Then
			EmployeeLine.Picker = True;
		EndIf;
		
		If Result.Courier Then
			EmployeeLine.Courier = True;
		EndIf;
		
		RecordEmployeeInformation(RowIndex, Warehouse);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ToRemoveTheRoleCompletion(Result, TT) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Warehouse = Items.Warehouses.CurrentRow;
	
	For Each RowIndex In Items.EmployeesHR.SelectedRows Do
		
		EmployeeLine = EmployeesHR.FindByID(RowIndex);
		
		If Result.Dispatcher Then
			EmployeeLine.Dispatcher = False;
		EndIf;
		
		If Result.Picker Then
			EmployeeLine.Picker = False;
		EndIf;
		
		If Result.Courier Then
			EmployeeLine.Courier = False;
		EndIf;
		
		RecordEmployeeInformation(RowIndex, Warehouse);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AssignRolesToTheWarehouseCompletion(Result, TT) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Employee = Items.EmployeesHR2.CurrentRow;
	
	For Each RowIndex In Items.Warehouses2.SelectedRows Do
		
		WarehouseLine = Warehouses2.FindByID(RowIndex);
		
		If Result.Dispatcher Then
			WarehouseLine.Dispatcher = True;
		EndIf;
		
		If Result.Picker Then
			WarehouseLine.Picker = True;
		EndIf;
		
		If Result.Courier Then
			WarehouseLine.Courier = True;
		EndIf;
		
		RecordInformationAboutWarehouses(RowIndex, Employee);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ToRemoveTheRoleOfTheWarehouseCompletion(Result, TT) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Employee = Items.EmployeesHR2.CurrentRow;
	
	For Each RowIndex In Items.Warehouses2.SelectedRows Do
		
		WarehouseLine = Warehouses2.FindByID(RowIndex);
		
		If Result.Dispatcher Then
			WarehouseLine.Dispatcher = False;
		EndIf;
		
		If Result.Picker Then
			WarehouseLine.Picker = False;
		EndIf;
		
		If Result.Courier Then
			WarehouseLine.Courier = False;
		EndIf;
		
		RecordInformationAboutWarehouses(RowIndex, Employee);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RecordEmployeeInformation(RowIndex, Warehouse)
	
	EmployeeLine = EmployeesHR.FindByID(RowIndex);
	
	If EmployeeLine.Employee.IsEmpty() Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.StoreEmployees.CreateRecordSet();
	RecordSet.Filter.Employee.Set(EmployeeLine.Employee);
	RecordSet.Filter.Warehouse.Set(Warehouse);
	
	NewRecord = RecordSet.Add();
	
	NewRecord.Employee = EmployeeLine.Employee;
	NewRecord.Warehouse     = Warehouse;
	NewRecord.Courier    = EmployeeLine.Courier;
	NewRecord.Picker   = EmployeeLine.Picker;
	NewRecord.Dispatcher = EmployeeLine.Dispatcher;
	
	RecordSet.Write();
	
EndProcedure

&AtServer
Procedure RecordInformationAboutWarehouses(RowIndex, Employee)
	
	WarehouseLine = Warehouses2.FindByID(RowIndex);
	
	If WarehouseLine.Warehouse.IsEmpty() Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.StoreEmployees.CreateRecordSet();
	RecordSet.Filter.Employee.Set(Employee);
	RecordSet.Filter.Warehouse.Set(WarehouseLine.Warehouse);
	
	NewRecord = RecordSet.Add();
	
	NewRecord.Employee = Employee;
	NewRecord.Warehouse     = WarehouseLine.Warehouse;
	NewRecord.Courier    = WarehouseLine.Courier;
	NewRecord.Picker   = WarehouseLine.Picker;
	NewRecord.Dispatcher = WarehouseLine.Dispatcher;
	
	RecordSet.Write();
	
EndProcedure

&AtServer
Procedure RecordInformationAboutNewEmployee(Employee, Warehouse)
	
	RecordSet = InformationRegisters.StoreEmployees.CreateRecordSet();
	RecordSet.Filter.Employee.Set(Employee);
	RecordSet.Filter.Warehouse.Set(Warehouse);
	
	NewRecord = RecordSet.Add();
	
	NewRecord.Employee = Employee;
	NewRecord.Warehouse     = Warehouse;
	
	RecordSet.Write();
	
EndProcedure

&AtServer
Procedure DeleteEmployeeInformation(Employee, Warehouse)
	
	RecordSet = InformationRegisters.StoreEmployees.CreateRecordSet();
	RecordSet.Filter.Employee.Set(Employee);
	RecordSet.Filter.Warehouse.Set(Warehouse);
	
	RecordSet.Write();
	
EndProcedure

&AtClient
Procedure CompleteEmployeeRecruitment(ArrayOfEmployees, TT) Export
	
	Warehouse = Items.Warehouses.CurrentRow;
	
	If ArrayOfEmployees = Undefined Then
		Return;
	EndIf;
	
	For Each EmployeeElement In ArrayOfEmployees Do
		
		FilterParameters = New Structure("Employee", EmployeeElement);
		If EmployeesHR.FindRows(FilterParameters).Count() > 0 Then
			Continue;
		EndIf;
		
		NewRow = EmployeesHR.Add();
		NewRow.Employee = EmployeeElement;
		
		RecordInformationAboutNewEmployee(EmployeeElement, Warehouse);
		
	EndDo;

EndProcedure

#EndRegion