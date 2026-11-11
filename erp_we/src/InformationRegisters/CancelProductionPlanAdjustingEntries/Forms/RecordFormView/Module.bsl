
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Items.Purpose.Visible = Parameters.ShowAssignment;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Record.Comment);
	
EndProcedure

#EndRegion
