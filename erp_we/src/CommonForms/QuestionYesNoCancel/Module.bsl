#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Parameters.QuestionTitle;
	Items.QueryText.Title = Parameters.QueryText;
	Items.Button1.Visible = Parameters.ButtonsList.Count() > 0;
	Items.Button2.Visible = Parameters.ButtonsList.Count() > 1;
	Items.Button3.Visible = Parameters.ButtonsList.Count() > 2;
	If Parameters.ButtonsList.Count() > 0 Then
		Items.Button1.Title = Parameters.ButtonsList[0].Presentation;
	EndIf;
	If Parameters.ButtonsList.Count() > 1 Then
		Items.Button2.Title = Parameters.ButtonsList[1].Presentation;
	EndIf;
	If Parameters.ButtonsList.Count() > 2 Then
		Items.Button3.Title = Parameters.ButtonsList[2].Presentation;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
	
&AtClient
Procedure Button1(Command)
	
	Result = Parameters.ButtonsList[0].Value;
	Close(Result);
	
EndProcedure

&AtClient
Procedure Button2(Command)
	
	Result = Parameters.ButtonsList[1].Value;
	Close(Result);
	
EndProcedure

&AtClient
Procedure Button3(Command)
	
	Result = Parameters.ButtonsList[2].Value;
	Close(Result);
	
EndProcedure
	
#EndRegion
