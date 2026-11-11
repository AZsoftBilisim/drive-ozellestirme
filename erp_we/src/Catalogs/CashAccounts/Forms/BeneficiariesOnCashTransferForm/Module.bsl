
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	For Each PaymentBeneficiary In Parameters.ListOfPaymentRecipients Do
		PayeeLine = RecipientOfCashTransfer.Add();
		PayeeLine.PaymentBeneficiary = PaymentBeneficiary.Value;
	EndDo;
	CashCurrency = Parameters.CashCurrency;
	Owner = Parameters.Owner;
	CashAccount = Parameters.CashAccount;
	
	InstructionText = StrTemplate(NStr("vi = 'Được sử dụng để thêm quỹ tiền mặt doanh nghiệp %1. Tiền tệ: %2.';
										|ru = 'Доступны для добавления кассы организации %1. Валюта: %2.';
										|en = 'Cash accounts of the %1 company are available for adding. Currency: %2.'; fa = 'Cash accounts of the %1 company are available for adding. Currency: %2.';
										|it = 'Disponibili per l''aggiunta della cassa aziendale %1. Valuta: %2.';
										|pl = 'Możliwe do dodania kasy firmy %1. Waluta: %2.';
										|tr = '%1 iş yerinin kasasını eklemek için kullanılabilir. Para birimi: %2.'"),
		Owner, CashCurrency);
	Items.DecorationInstructions.Title = InstructionText;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If Modified Then
		NotfDescr = New CallbackDescription("TransferData_Completion", ThisForm, New Structure("Cancel", Cancel));
		ShowQueryBox(NotfDescr, NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
									|ru = 'Данные были изменены. Сохранить изменения?';
									|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
									|it = 'I dati sono stati modificati. Salvare le modifiche?';
									|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
									|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"), QuestionDialogMode.YesNoCancel);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferData_Completion(QuestionResult, AdditionalParameters) Export
	
	Cancel = AdditionalParameters.Cancel;
	
	Response = QuestionResult;
	If Response = DialogReturnCode.Yes Then
		TransferData_(Cancel);
	ElsIf Response = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RecipientOfCashTransferOnChange(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	TransferData_();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure TransferData_(Cancel = False)
	
	ClearMessages();
	
	ListOfPaymentRecipients = New ValueList;
	For IndexOf = 0 To RecipientOfCashTransfer.Count() - 1 Do
		
		PayeeLine = RecipientOfCashTransfer[IndexOf];
		
		If Not ValueIsFilled(PayeeLine.PaymentBeneficiary) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong dòng %1 chưa điền quỹ tiền mặt nhận.';
					|ru = 'В строке %1 не заполнена касса-получатель.';
					|en = 'Receiving cash account is required in line %1.'; fa = 'Receiving cash account is required in line %1.';
					|it = 'Nella riga %1 non è compilata la cassa-destinatario.';
					|pl = 'W wierszu %1 nie wypełniono kasy odbiorcy.';
					|tr = '%1 satırında, alan kasa doldurulmadı.'"),
				IndexOf + 1);
			CommonClientServer.MessageToUser(
				Text,
				,
				"RecipientOfCashTransfer["+IndexOf+"].PaymentBeneficiary",
				,
				Cancel);
		EndIf;
		
		If PayeeLine.PaymentBeneficiary = CashAccount Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong dòng %1 để làm quỹ tiền mặt nhận đã chỉ ra quỹ tiền mặt gửi %2. Hãy chọn quỹ tiền mặt nhận khác với quỹ tiền mặt gửi.';
					|ru = 'В строке %1 в качестве кассы-получателя указана касса-отправитель %2. Выберите кассу-получателя, отличную от кассы-отправителя.';
					|en = 'Withdrawing cash account %2 is specified in line %1 as a receiving cash account. Select a receiving cash account different from the withdrawing cash account.'; fa = 'Withdrawing cash account %2 is specified in line %1 as a receiving cash account. Select a receiving cash account different from the withdrawing cash account.';
					|it = 'Nella riga %1, come cassa-destinatario, è indicata invece la cassa-mittente %2. Scegliete una cassa-destinatario differente dalla cassa-mittente.';
					|pl = 'W wierszu %1 jako kasa odbiorca została wskazana kasa nadawca %2. Wybierz kasę odbiorcę, inną niż kasa nadawca.';
					|tr = '%1 satırında, gönderen kasa %2, alıcı kasa olarak belirtildi. Gönderen kasadan farklı bir alıcı kasa seç.'"),
				IndexOf + 1,
				CashAccount);
			CommonClientServer.MessageToUser(
				Text,
				,
				"RecipientOfCashTransfer["+IndexOf+"].PaymentBeneficiary",
				,
				Cancel);
		EndIf;
		
		If ListOfPaymentRecipients.FindByValue(PayeeLine.PaymentBeneficiary) <> Undefined
		 And ValueIsFilled(PayeeLine.PaymentBeneficiary) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong dòng %1 để làm quỹ tiền mặt nhận đã chỉ định trùng quỹ tiền mặt %2';
					|ru = 'В строке %1 в качестве кассы-получателя повторно указана касса %2.';
					|en = 'Cash account %2 is repeatedly specified as a receiving cash account in line %1.'; fa = 'Cash account %2 is repeatedly specified as a receiving cash account in line %1.';
					|it = 'Nella riga %1, come cassa-destinatario, è nuovamente indicata la cassa %2.';
					|pl = 'W wierszu %1 jako kasę odbiorcę ponownie wskazano kasę %2.';
					|tr = '%1 satırında, kasa %2 alıcı kasa olarak tanımlandı.'"),
				IndexOf + 1,
				PayeeLine.PaymentBeneficiary);
			CommonClientServer.MessageToUser(
				Text,
				,
				"RecipientOfCashTransfer["+IndexOf+"].PaymentBeneficiary",
				,
				Cancel);
		EndIf; 
		
		ListOfPaymentRecipients.Add(PayeeLine.PaymentBeneficiary);
	EndDo;
	
	If Not Cancel Then
		Modified = False;
		NotifyChoice(ListOfPaymentRecipients);
	EndIf; 
	
EndProcedure

#EndRegion

#EndRegion
