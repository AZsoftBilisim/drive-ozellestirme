
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Or Users.IsFullUser() Then
		Return;
	EndIf;

	ReadOnly = True;

EndProcedure

#EndRegion
