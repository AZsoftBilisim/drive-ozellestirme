#Region FormEventHandlers
#EndRegion

#Region FormTableItemsEventHandlersEmployeesHR

&AtClient
Procedure EmployeesHRSelection(Item, RowSelected, Field, StandardProcessing)
	Close(ArrayOfEmployees());
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	Close(ArrayOfEmployees());
EndProcedure

#EndRegion

#Region Private

&AtClient
Function ArrayOfEmployees()
	
	Array = New Array;
	For Each ListLine In Items.EmployeesHR.SelectedRows Do
		Array.Add(Items.EmployeesHR.RowData(ListLine).Ref);
	EndDo;
	
	Return Array;
	
EndFunction

#EndRegion