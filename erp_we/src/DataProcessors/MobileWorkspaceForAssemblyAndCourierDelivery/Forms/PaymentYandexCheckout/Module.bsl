
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReferenceOrder", ReferenceOrder);
	Parameters.Property("AmountToPay", AmountToPay);
	Parameters.Property("Currency", Currency);
	Parameters.Property("Warehouse", Warehouse);
	
	UpdateFormData();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DecorationSendLinkBySMSClick(Item)
	
#If MobileClient Then
	
	If Not TelephonyTools.SMSSendingSupported(True) Then
		Return;
	EndIf;
		
	SMS = New SMSMessage();
	SMS.Text = StrTemplate(NStr("vi = 'Tham chiếu đến thanh toán đơn hàng: %1';
								|ru = 'Ссылка на оплату заказа: %1';
								|en = 'Order payment link: %1'; fa = 'Order payment link: %1';
								|it = 'Collegamento al pagamento dell''ordine: %1';
								|pl = 'Odnośnik do opłaty zamówienia: %1';
								|tr = 'Sipariş ödemesi için bağlantı: %1'"), PaymentLink);
	PhoneNumber = PhoneNumberOfContactPersonFromDocument(ReferenceOrder);
	
	If PhoneNumber <> "" Then
		SMS.To.Add(PhoneNumber);
		TelephonyTools.SendSMS(SMS, True);
	Else
		ErrorText = NStr("vi = 'Chưa chỉ ra số điện thoại.';
						|ru = 'Не указан номер телефона.';
						|en = 'The phone number is not specified.'; fa = 'The phone number is not specified.';
						|it = 'Numero di telefono non indicato.';
						|pl = 'Nie podano numeru telefonu.';
						|tr = 'Telefon numarası belirtilmedi.'");
		CommonClient.MessageToUser(ErrorText);
		Error = True;
	EndIf;
	
#EndIf
	
EndProcedure

&AtClient
Procedure DecorationUpdatePaymentStatusClick(Item)
	
	GetPaymentStatus();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAProcessCommand(Command)
	
	If PaymentStatus = 0 Then
		CallbackDescription = New CallbackDescription("StatusQuestionEnd", ThisForm);
		QueryText = NStr("vi = 'Chưa tạo chứng từ thanh toán. Tiếp tục?';
						|ru = 'Платежный документ не создан. Продолжить?';
						|en = 'The payment document has not been created. Continue?'; fa = 'The payment document has not been created. Continue?';
						|it = 'Documento di pagamento non creato. Continuare?';
						|pl = 'Nie utworzono dokumentu płatniczego. Kontynuować?';
						|tr = 'Ödeme belgesi oluşturulmadı. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	Cancel = False;
	AcceptPaymentAndIssueReceipt(Cancel);
	
	If Not Cancel Then
		Close(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusQuestionEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Cancel = False;
		AcceptPaymentAndIssueReceipt(Cancel);
		
		If Not Cancel Then
			Close(True);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFormData()
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	AmountToPayPresentation = Module.AmountToPayPresentation(ThisForm);


	PaymentStatusPresentation = Module.PaymentStatusPresentation(ThisForm);
	
	Items.DecorationAmountToBePaid.Title = New FormattedString(AmountToPayPresentation,
		StyleFonts.EnlargedTextFontSelectedAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationPaymentStatus.Title =  New FormattedString(PaymentStatusPresentation,
		StyleFonts.TextFontSelectedAssemblyAndDelivery,
		?(PaymentStatus = 0, StyleColors.InProgressStatusTextColorAssemblyAndDelivery,
			StyleColors.ReadyStatusTextColorAssemblyAndDelivery));
		
	OverrideCurProcessCommand();
		
EndProcedure

&AtServer
Function PhoneNumberOfContactPersonFromDocument(ReferenceOrder)
	
	Return DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.PhoneNumberOfContactPersonFromDocument(ReferenceOrder);
	
EndFunction

&AtServer
Procedure GetPaymentStatus()
	

	UpdateFormData();
	
EndProcedure

#Region ProcessActions

&AtServer
Procedure OverrideCurProcessCommand()
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.OverrideCurProcessCommand(ThisForm);
	
EndProcedure

&AtServer
Procedure AcceptPaymentAndIssueReceipt(Cancel = False) 
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	
	If StrFind(CurrentAction1, "IssueReceipt") Then
		Module.IssueReceipt(ReferenceOrder, Cancel);
	EndIf;
	
	If Not Cancel Then
		Module.CompleteDelivery(ReferenceOrder);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
