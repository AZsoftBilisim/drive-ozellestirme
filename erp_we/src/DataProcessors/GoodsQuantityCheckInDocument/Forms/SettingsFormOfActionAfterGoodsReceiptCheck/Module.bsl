
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	OptionOfNoteCheckEnd = ?(ValueIsFilled(Parameters.OptionOfNoteCheckEnd),
		Parameters.OptionOfNoteCheckEnd, "RequestActionSelectionAfterVerification");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Notify("ChangedOptionForCompletingOrderVerification", OptionOfNoteCheckEnd, ThisForm.FormName);
	
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion
