
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Record.Interests + Record.Fee = 0 Then
		
		Text  = NStr("vi = 'Trong dòng cần chỉ ra ít nhất một trong các số tiền của lịch biểu!';
					|ru = 'В строке должна быть указана хотя бы одна из сумм графика!';
					|en = 'At least one of the schedule amounts should be specified in the line.'; fa = 'At least one of the schedule amounts should be specified in the line.';
					|it = 'Nella riga deve essere indicato almeno uno degli importi del grafico!';
					|pl = 'W wierszu musi podana co najmniej jedną z kwot wykresu!';
					|tr = 'Satır, program toplamlarından en az birini içermelidir!'");
		CommonClientServer.MessageToUser(Text);
		Cancel = True;
		
	EndIf;
	
	If ContractIsClosed(Record.ScheduleOption) Then
		Cancel = True;
		Text = NStr("vi = 'Cấm thay đổi lịch biểu theo hợp đồng đã đóng!';
					|ru = 'Изменения графика по закрытому договору запрещены!';
					|en = 'Changing schedule for a closed contract is not allowed.'; fa = 'Changing schedule for a closed contract is not allowed.';
					|it = 'Le modifiche al programma per un contratto chiuso sono proibite!';
					|pl = 'Zmiany w harmonogramie zamkniętej umowy są zabronione!';
					|tr = 'Kapalı sözleşme kapsamında program değişiklikleri yasaktır!'");
		CommonClientServer.MessageToUser(Text);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ContractIsClosed(ScheduleOption)
	
	Return Common.ObjectAttributeValue(ScheduleOption, "Owner")
		= Enums.CounterpartyContractStatuses.Closed;
	
EndFunction

#EndRegion
