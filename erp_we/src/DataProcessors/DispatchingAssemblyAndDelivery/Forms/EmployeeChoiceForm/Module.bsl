#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, EmployeesHR);
	
	EmployeesHR.Parameters.SetParameterValue("Warehouse", Parameters.Warehouse);
	
	If Parameters.ThisIsCourier Then
		Title = NStr("vi = 'Chọn người giao hàng';
					|ru = 'Выбор курьера';
					|en = 'Select courier'; fa = 'Select courier';
					|it = 'Selezione corriere';
					|pl = 'Wybór kuriera';
					|tr = 'Kurye seçimi'");
	Else
		Title = NStr("vi = 'Chọn bộ đóng gói';
					|ru = 'Выбор сборщика';
					|en = 'Select picker'; fa = 'Select picker';
					|it = 'Selezione assemblatore';
					|pl = 'Wybór zbieracza';
					|tr = 'Montajcı seçimi'");
		ListProperties.QueryText = StrReplace(EmployeesHR.QueryText, "Courier", "Picker");
	EndIf;
	
	Common.SetDynamicListProperties(Items.EmployeesHR, ListProperties);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployeesHR


// Processing the " Select "event for the "Employees" table field"
// 
// Parameters:
// 	Item - FormTable - List of employees
// 	RowSelected - CatalogRef.Persons
// 	Field - FormField
// 	StandardProcessing - Boolean
&AtClient
Procedure EmployeesHRSelection(Item, RowSelected, Field, StandardProcessing)
	Close(RowSelected);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	Close(Items.EmployeesHR.CurrentRow);
EndProcedure

#EndRegion

#Region Private

#EndRegion