
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ParametersStructure = GetParameters(Parameters);
	ParametersStructure.Insert("Counterparty",            Parameters.Counterparty);
	ParametersStructure.Insert("ReadOnly",        Parameters.ReadOnly);
	FillPropertyValues(ThisForm, ParametersStructure);
	
	If ReadOnly Then
		
		ItemArray = New Array();
		ItemArray.Add("CounterpartyBankAccount");
		ItemArray.Add("AdditionalInformationOfHeader");
		ItemArray.Add("AdditionalInformation");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Modified And Not SaveParameters And Not Exit Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		Cancel = True;
		AdditionalParameters = New Structure;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject, AdditionalParameters),
			NStr("vi = 'Chi tiết về con dấu của giấy chứng nhận hoàn thành đã được thay đổi. Đóng mà không lưu chi tiết?';
				|ru = 'Реквизиты печати акта выполненных работ были изменены. Закрыть без сохранения реквизитов?';
				|en = '""Customer invoice — Services"" print options were changed. Close without saving the options?'; fa = '""Customer invoice — Services"" print options were changed. Close without saving the options?';
				|it = 'Requisiti della stampa dell''atto di consegna dei lavori sono stati modificati. Chiudere senza salvare i requisiti?';
				|pl = 'Szczegóły drukowania certyfikatu ukończenia zostały zmienione. Zamknij bez zapisywania szczegółów?';
				|tr = 'Gerçekleştirilen işler raporu baskı öznitelikleri değiştirildi. Öznitelikler kaydedilmeden kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "NotClose" Then
		SaveParameters = False;
		
	Else
		
		ForceCloseTheForm = True;
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters And Not Exit Then
		
		ParametersStructure = GetParameters(ThisForm);
		NotifyChoice(ParametersStructure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		SaveParameters = True;
	EndIf;
	
	Close();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClientAtServerNoContext
Function GetParameters(Source)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("CounterpartyBankAccount",     Source.CounterpartyBankAccount);
	ParametersStructure.Insert("AdditionalInformation",      Source.AdditionalInformation);
	ParametersStructure.Insert("AdditionalInformationOfHeader", Source.AdditionalInformationOfHeader);
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#EndRegion
