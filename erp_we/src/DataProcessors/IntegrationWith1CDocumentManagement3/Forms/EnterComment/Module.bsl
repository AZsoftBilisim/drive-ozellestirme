#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Comment = Parameters.Comment;
	
	If ValueIsFilled(Parameters.Title) Then
		Title = Parameters.Title;
		AutoTitle = False;
	EndIf;
	
	If Parameters.ReadOnly Then
		Items.Comment.ReadOnly = True;
		Items.FormOK.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Close(Comment);
	
EndProcedure

#EndRegion