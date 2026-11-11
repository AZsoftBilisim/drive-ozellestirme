
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ListOfActions = Parameters.ListOfActions;
	NumberOfActions = Parameters.NumberOfActions;
	
	AccompanyingText1 = NStr("vi = 'Xin vui lòng đợi...';
							|ru = 'Пожалуйста, подождите...';
							|en = 'Please wait...'; fa = 'لطفاً صبر کنید...';
							|it = 'Attendere prego...';
							|pl = 'Proszę czekać...';
							|tr = 'Lütfen bekleyin...'");
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Completed2 Then 
		Cancel = True;
	Else
		CheckInterval = 3;
		AttachIdleHandler("CheckExecution", CheckInterval, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	
	QueryText = NStr("vi = 'Chứng từ vẫn chưa được lập.';
					|ru = 'Документы еще не сформированы.';
					|en = 'Documents have not been generated yet.'; fa = 'Documents have not been generated yet.';
					|it = 'Documenti non ancora creati.';
					|pl = 'Jeszcze nie utworzono dokumentów.';
					|tr = 'Belgeler henüz oluşturulmadı.'");
	
	Buttons = New ValueList;
	Buttons.Add(1, NStr("vi = 'Tiếp tục chờ';
						|ru = 'Подождать еще';
						|en = 'Continue waiting'; fa = 'Continue waiting';
						|it = 'Attendere';
						|pl = 'Poczekaj jeszcze';
						|tr = 'Biraz daha bekleyin'"));
	Buttons.Add(DialogReturnCode.Abort);
	
	DetachIdleHandler("CheckExecution");
	
	Handler = New CallbackDescription("CancelCompletion", ThisObject);
	ShowQueryBox(Handler, QueryText, Buttons, 60,1);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckExecution()
	
	AllActionsCompleted = AllActionsCompleted();
	
	If Not AllActionsCompleted Then
		AttachIdleHandler("CheckExecution", CheckInterval, True);
	Else
		ClosingConfirmed = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelCompletion(Response, AdditionalParameters) Export
	
	AbortIfNotExecuted = (Response = DialogReturnCode.Abort);
	If AbortIfNotExecuted Then
		Notify("ToCancelTheBatchFormation");
		ClosingConfirmed = True;
		Close();
	EndIf;

	AttachIdleHandler("CheckExecution", CheckInterval, True);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		ClosingConfirmed = True;
	EndIf;
	
	If Not ClosingConfirmed Then

		If Not Completed2 Then
			StandardProcessing = False;
			Cancel = True;
			Cancel(Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "AddedNewAction" Then
		
		ListOfActions = Parameter.ListOfActions;
		NumberOfActions = Parameter.NumberOfActions;
		
		If Not NumberOfActions = 0 Then
			Indicator = Round(Parameter.CurActionNumber / NumberOfActions * 100, 0);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function AllActionsCompleted()

	AllActionsCompleted = False;

	If ListOfActions.Count() = NumberOfActions Then
		AllActionsCompleted = True;
		For Each Action In ListOfActions Do
			If Not Action.Value.Status = "Completed2" Then
				JobCompleted = TimeConsumingOperations.JobCompleted(Action.Value.JobID);
				If Not JobCompleted Then
					Return False;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Return AllActionsCompleted;
	
EndFunction

#EndRegion
