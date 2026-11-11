
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("PrintObjects") Then
		Raise NStr("vi = 'Chưa điền giá trị tham số ""Đối tượng in""';
					|ru = 'Не заполнено значение параметра ""Объекты печати""';
					|en = 'Parameter ""Print objects"" is required'; fa = 'Parameter ""Print objects"" is required';
					|it = 'Il valore del parametro ""Oggetti della stampa"" non è compilato';
					|pl = 'Nie wypełniono wartość parametru ""Obiekty wydruku""';
					|tr = '""Yazdırma Nesneleri"" parametresinin değeri doldurulmadı'"); 
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Items.Employees.Enabled = PrintWorkers;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PrintPerformersWhenChanging(Item)
	
	Items.Employees.Enabled = PrintWorkers;
	
	If Not PrintWorkers Then
		ClearTable();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersEmployees

&AtClient
Procedure EmployeesOnStartEdit(Item, NewRow, Copy)
	
EndProcedure

&AtClient
Procedure EmployeesEmployeeStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure EmployeesEmployeeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
EndProcedure

&AtClient
Procedure EmployeesEmployeeAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
EndProcedure

&AtClient
Procedure EmployeesEmployeeChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
EndProcedure

&AtClient
Procedure EmployeesEmployeeOnChange(Item)
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Print(Command)
	
	ListOfObjects = New Array();
	
	For Each Ref In Parameters.PrintObjects Do
		ListOfObjects.Add(Ref);
	EndDo;
	
	If PrintWorkers Then
		
		
		For Each String In Employees Do
			
				ListOfObjects.Add(String.Employee_);
		EndDo;
		
		
	EndIf;
	
	TemplatesNames = New Array();
	TemplatesNames.Add("WorkingCenterLabelElement");
	
	PrintManagementClient.ExecutePrintCommand(
			"Catalog.WorkCenters",
			TemplatesNames,
			ListOfObjects,
			FormOwner,
			PrintParameterValues());
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function PrintParameterValues()
	
	Result = New Structure;
	
	Result.Insert("PrintIndividuals", PrintWorkers);
	
	Return Result;
	
EndFunction

&AtServer
Procedure ClearTable()
	Employees.Clear();
EndProcedure


#EndRegion
