
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ReadOnly = Not CommonClientServer.DebugMode();
	
EndProcedure

#EndRegion
