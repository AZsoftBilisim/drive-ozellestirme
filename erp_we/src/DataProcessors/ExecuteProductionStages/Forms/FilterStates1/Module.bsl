#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	For Each State In Enums.ShopfloorLevelStagesStates Do
		ExecutionStates.Add(State);
	EndDo;
	
	If Parameters.Property("SelectedValues") And ValueIsFilled(Parameters.SelectedValues) Then
		For Each Item In ExecutionStates Do
			If Not Parameters.SelectedValues.FindByValue(Item.Value) = Undefined Then
				Item.Check = True;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Result = New ValueList;
	For Each Item In ExecutionStates Do
		If Item.Check Then
			Result.Add(Item.Value, Item.Presentation);
		EndIf;
	EndDo;
	
	Close(Result);
	
EndProcedure

#EndRegion