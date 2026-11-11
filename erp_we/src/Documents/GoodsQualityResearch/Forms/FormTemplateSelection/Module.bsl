
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ListOfSamples.LoadValues(Parameters.Patterns);
	
EndProcedure 

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Modified = False;
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompleteEditing()
	
	If Items.ListOfSamples.CurrentRow <> Undefined Then
		Close(New Structure("Pattern", Items.ListOfSamples.CurrentData.Value));
	EndIf;
	
EndProcedure

#EndRegion
