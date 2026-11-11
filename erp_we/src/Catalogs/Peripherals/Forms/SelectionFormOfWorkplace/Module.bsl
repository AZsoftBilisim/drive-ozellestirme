
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	
	ClientID = Parameters.ClientID;
	
	If Not IsBlankString(ClientID) Then
		NewArray = New Array();
		NewArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
		NewArray.Add(New ChoiceParameter("Filter.Code", ClientID));
		NewFixedArray = New FixedArray(NewArray);
		Items.Workplace.ChoiceParameters = NewFixedArray;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangedCurSessionWorkplace" Then
		Workplace = EquipmentManagerClient.CustomerWorkplace();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAndClose(Command)
	
	ClearMessages();
		
	If ValueIsFilled(Workplace) Then
		Parameters.Workplace = Workplace;
		ClearMessages();
		ReturnStructure = New Structure("Workplace", Workplace);
		Close(ReturnStructure);
	Else
		
		CommonCELClient.MessageToUser(NStr("vi = 'Hãy chọn chỗ làm việc';
											|ru = 'Выберите рабочее место';
											|en = 'Select workplace'; fa = 'Select workplace';
											|it = 'Scegliete un posto di lavoro';
											|pl = 'Wybierz miejsce pracy';
											|tr = 'Çalışma alanı seç'"), Workplace, "Workplace");
		
	EndIf;
	
EndProcedure

#EndRegion