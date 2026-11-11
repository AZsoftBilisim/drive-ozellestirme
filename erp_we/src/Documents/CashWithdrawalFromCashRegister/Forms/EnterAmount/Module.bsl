
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If ValueIsFilled(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	Currency = Parameters.Currency;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Sum) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa nhập số tiền nhận';
				|ru = 'Не введена сумма выемки';
				|en = 'Enter cash amount to be taken out'; fa = 'مبلغ وجه نقد برای برداشت را وارد کنید';
				|it = 'L''importo di prelievo non è inserito';
				|pl = 'Nie wprowadzono wartości wyjęcia';
				|tr = 'Para çekme tutarı girilmemiş'"),,,"Sum");
		Return;
	EndIf;
	
	Close(Sum);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
