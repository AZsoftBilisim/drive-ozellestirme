#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Items.Organization.Visible = Not Parameters.Filter.Property("Organization");
	
EndProcedure

#EndRegion