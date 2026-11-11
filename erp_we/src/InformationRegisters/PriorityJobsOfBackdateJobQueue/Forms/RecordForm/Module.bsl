#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.Key.TaskPeriod) Then
		Record.TaskPeriod = BegOfMonth(CurrentSessionDate());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TaskPeriodOnChange(Item)
	
	Record.TaskPeriod = BegOfMonth(Record.TaskPeriod);

EndProcedure

#EndRegion

