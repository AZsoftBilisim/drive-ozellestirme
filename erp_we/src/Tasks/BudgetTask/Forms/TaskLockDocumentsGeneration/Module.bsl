#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Xin vui lòng đợi...';
						|ru = 'Пожалуйста, подождите...';
						|en = 'Please wait...'; fa = 'لطفاً صبر کنید...';
						|it = 'Attendere prego...';
						|pl = 'Proszę czekać...';
						|tr = 'Lütfen bekleyin...'");
	If Not IsBlankString(Parameters.MessageText) Then
		MessageText = Parameters.MessageText + Chars.LF + MessageText;
		Items.TimeConsumingOperationNoteTextDecoration.Title = MessageText;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	
	Close(New Structure("CloseTheTask", True));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditTask(Command)
	Close(New Structure("CloseTheTask", False));
EndProcedure


&AtClient
Procedure CloseTheTask(Command)
	Close(New Structure("CloseTheTask", True));
EndProcedure

#EndRegion