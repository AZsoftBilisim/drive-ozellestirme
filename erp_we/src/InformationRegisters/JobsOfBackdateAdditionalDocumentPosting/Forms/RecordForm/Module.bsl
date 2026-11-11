#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.Key.RecordID) Then
		Record.RecordID = New UUID();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not ValueIsFilled(Record.RecordID) Then
		Record.RecordID = New UUID();
	EndIf;
	
EndProcedure

#EndRegion