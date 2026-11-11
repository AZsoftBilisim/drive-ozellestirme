
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	For Each State In Enums.StatusesOfProductionStages2_2 Do
		StageStatuses.Add(State);
	EndDo;
	
	If Parameters.Property("SelectedValues") And ValueIsFilled(Parameters.SelectedValues) Then
		For Each Item In StageStatuses Do
			If Not Parameters.SelectedValues.FindByValue(Item.Value) = Undefined Then
				Item.Check = True;
			EndIf;
		EndDo;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Result = New ValueList;
	For Each Item In StageStatuses Do
		If Item.Check Then
			Result.Add(Item.Value, Item.Presentation);
		EndIf;
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion