#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	ValueSelected = Value;
	If Item.SelectedRows.Count() > 1 Then
		ValueSelected = Item.SelectedRows;
	EndIf;
	Value = New Structure("OperationTemplate", ValueSelected);
	NotifyChoice(Value);
		
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

