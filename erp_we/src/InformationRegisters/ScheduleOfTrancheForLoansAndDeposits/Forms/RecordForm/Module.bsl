
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
