
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	If Record.SourceRecordKey.IsEmpty() Then
		Record.Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

#EndRegion
