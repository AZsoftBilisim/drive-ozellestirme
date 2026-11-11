
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	RetailSales.SignHotkeysOnButtons(ThisObject);
	Displays.LoadValues(EquipmentManagerServerCall.EquipmentByParameters("CustomerDisplay"));
	AutomaticallyCreatePartners = Constants.AutomaticallyCreatePartnersWhenSendingElectronicReceiptToCustomer.Get();
	AutomaticallyUpdatePartnerContacts = Constants.UpdatePartnersContactDetailsWhenSendingElectronicReceipts.Get();
	
	

	DecimalPlaces = 2;
	SeparatorOfWholeAndFractionalParts = Mid(Format(1.1, "ND=2; NFD=1"),2,1);
	ReceivedInCashFormatOfRepresentationOfIntegers = "NZ=0; NG=3,0";
	
	PaymentInformation = Parameters.PaymentInformation;
	Document = PaymentInformation.Document;
	
	If TypeOf(Document) = Type("DocumentRef.CashRegisterReceiptReturn")
		Or TypeOf(Document) = Type("DocumentRef.ReturnOfGiftCards") Then
		
		Title = NStr("vi = 'Hoàn tiền mặt';
					|ru = 'Возврат оплаты наличными';
					|en = 'Return payment in cash'; fa = 'Return payment in cash';
					|it = 'Restituzione del pagamento in contanti';
					|pl = 'Zwrot płatności gotówką';
					|tr = 'Nakit ödemelerin iadesi'");
		
		Items.AmountDue.Title      = NStr("vi = 'Cần trả lại';
											|ru = 'К возврату';
											|en = 'For return'; fa = 'برای برگشت';
											|it = 'In restituzione';
											|pl = 'Do zwrotu';
											|tr = 'İade edilmek üzere'");
		Items.ChangeAmount.Title   = NStr("vi = 'Nhận tiền thừa';
											|ru = 'Получить сдачу';
											|en = 'Get change'; fa = 'Get change';
											|it = 'Ricevere resto';
											|pl = 'Otrzymać resztę';
											|tr = 'Para üstünü al'");
		Items.TheAmountOfTheSurcharge.Title = NStr("vi = 'Số còn lại hoàn trả';
													|ru = 'Осталось вернуть';
													|en = 'Remains to return'; fa = 'Remains to return';
													|it = 'Da restiture';
													|pl = 'Pozostało do zwrócenia';
													|tr = 'Kalanlar geri getirilecek'");
		
	EndIf;
	
	AmountDue           = PaymentInformation.AmountToPay;
	ReceivedInCash = Format(PaymentInformation.CashPayment, ReceivedInCashFormatOfRepresentationOfIntegers);
	
	Items.GroupSendingAnElectronicReceipt.Visible = True;
	FieldSelectionBackColor = StyleColors.SelectionBackColor;
	
	Partner = Parameters.Partner;
	RetailSales.FillInParametersForSendingElectronicReceiptToPartner(ThisObject);
	
	RetailSalesClientServer.SetActiveElement(ThisObject, Items.FieldReceivedInCash);
	Phone = RetailSalesClientServer.FormatPhoneNumber(PhoneNumber10Characters);
	
	CalculateTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 1, True);
	
	AttachIdleHandler("SetElementActivity", 1, False);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	CrntNotification = CallbackDescriptionOnClose;
	
	If Exit Then
		PaymentResult = Undefined;
		If TypeOf(CrntNotification) = Type("CallbackDescription") 
			And TypeOf(CrntNotification.AdditionalParameters) = Type("Structure") Then
			CrntNotification.AdditionalParameters.Insert("Exit", True);
		EndIf;
	Else 
		If PaymentResult = Undefined Then
			PaymentResult = "Cancel";
		EndIf;
	EndIf;
	
	Close(PaymentResult);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PhoneOnChange(Item)
	
	PhoneNumber10Characters = RetailSalesClientServer.PhoneNumberIn10CharactersFormat(Phone);
	
EndProcedure

&AtClient
Procedure EmailOnChange(Item)
	
	RetailSalesClientServer.SetOptionToSendElectronicReceipt(
		ThisObject,
		PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail"));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Command0(Command)
	
	AddDigit("0")
	
EndProcedure

&AtClient
Procedure Command1(Command)
	
	AddDigit("1")
	
EndProcedure

&AtClient
Procedure Command2(Command)
	
	AddDigit("2")
	
EndProcedure

&AtClient
Procedure Command3(Command)
	
	AddDigit("3")
	
EndProcedure

&AtClient
Procedure Command4(Command)
	
	AddDigit("4")
	
EndProcedure

&AtClient
Procedure Command5(Command)
	
	AddDigit("5")
	
EndProcedure

&AtClient
Procedure Command6(Command)
	
	AddDigit("6")
	
EndProcedure

&AtClient
Procedure Command7(Command)
	
	AddDigit("7")
	
EndProcedure

&AtClient
Procedure Command8(Command)
	
	AddDigit("8")
	
EndProcedure

&AtClient
Procedure Command9(Command)
	
	AddDigit("9")
	
EndProcedure

&AtClient
Procedure Command0RightKeyboard(Command)
	
	AddDigit("0")
	
EndProcedure

&AtClient
Procedure Command1RightKeyboard(Command)
	
	AddDigit("1")
	
EndProcedure

&AtClient
Procedure Command2RightKeyboard(Command)
	
	AddDigit("2")
	
EndProcedure

&AtClient
Procedure Command3RightKeyboard(Command)
	
	AddDigit("3")
	
EndProcedure

&AtClient
Procedure Command4RightKeyboard(Command)
	
	AddDigit("4")
	
EndProcedure

&AtClient
Procedure Command5RightKeyboard(Command)
	
	AddDigit("5")
	
EndProcedure

&AtClient
Procedure Command6RightKeyboard(Command)
	
	AddDigit("6")
	
EndProcedure

&AtClient
Procedure Command7RightKeyboard(Command)
	
	AddDigit("7")
	
EndProcedure

&AtClient
Procedure Command8RightKeyboard(Command)
	
	AddDigit("8")
	
EndProcedure

&AtClient
Procedure Command9RightKeyboard(Command)
	
	AddDigit("9")
	
EndProcedure

&AtClient
Procedure CommandPoint(Command)
	
	If ReceivedInCash = "" Then
		ReceivedInCash = "0";
	EndIf;
	
	If Not ReceivedInCashIsFractionalNumber Then
		ReceivedInCashIsFractionalNumber = True;
		ReceivedInCash = ReceivedInCash + SeparatorOfWholeAndFractionalParts;
	EndIf;
	
	CalculateTotals(ThisObject);
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
EndProcedure

&AtClient
Procedure DeleteCommand_(Command)
	
	If ActiveField = Items.FieldReceivedInCash.Name Then
		
		ReceivedInCash = "0";
		ReceivedInCashIsFractionalNumber = False;
		
		CalculateTotals(ThisObject);
		AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
		
	ElsIf ActiveField = Items.Phone.Name Then
		
		PhoneNumber10Characters = "";
		Phone = RetailSalesClientServer.FormatPhoneNumber(PhoneNumber10Characters);
		
	ElsIf ActiveField = Items.Email.Name Then
		
		Email = "";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandIssueReceipt(Command)
	
	PaymentAmountNumber = RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash);
	
	ElectronicReceiptData = RetailSalesClientServer.ElectronicReceiptData(ThisObject);
	NeedForDataProcessing = RetailSalesClientServer.CheckWhetherElectronicReceiptDataNeedsToBeProcessed(ThisObject);
	If NeedForDataProcessing.NeedToUpdateContactInformation
		Or NeedForDataProcessing.YouNeedToCreatePartner
		Or NeedForDataProcessing.YouNeedToUpdateOptionForSendingPartnerSElectronicReceipt Then
		ElectronicReceiptData = ProcessElectronicReceiptData();
	EndIf;
	
	If ElectronicReceiptData = Undefined Then
		Return;
	EndIf;
	
	RetailSalesClient.LockForm(ThisObject);
	
	PaymentResult = RetailSalesClientServer.PaymentResultStructure();
	PaymentResult.ReceivedInCash      = PaymentAmountNumber;
	PaymentResult.ElectronicReceiptData = ElectronicReceiptData;
	
	Close(PaymentResult);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure SendSMSCommand(Command)
	
	RetailSalesClientServer.SetActiveElement(ThisObject, Items.Phone);
	RetailSalesClientServer.SetOptionToSendElectronicReceipt(
		ThisObject,
		PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS"));
	
EndProcedure

&AtClient
Procedure SendEmailCommand(Command)
	
	RetailSalesClientServer.SetActiveElement(ThisObject, Items.Email);
	RetailSalesClientServer.SetOptionToSendElectronicReceipt(
		ThisObject,
		PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail"));
	
EndProcedure

&AtClient
Procedure TheSendCommandIsNotRequired(Command)
	
	RetailSalesClientServer.SetOptionToSendElectronicReceipt(
		ThisObject,
		PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend"));
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure CalculateTotals(Form)
	
	Form.PayAmount = RetailSalesClientServer.Convert_String_To_Number(Form.ReceivedInCash);
	
	If Form.PayAmount >= Form.AmountDue Then
		
		Form.ChangeAmount   = Form.PayAmount - Form.AmountDue;
		Form.TheAmountOfTheSurcharge = 0;
		
		Form.Items.GroupInTotal.CurrentPage = Form.Items.DeliveryGroup_;
		Form.Items.CommandIssueReceipt.Enabled = True;
		
		Form.CurrentItem = Form.Items.CommandIssueReceipt;
		
	Else
		
		Form.ChangeAmount   = 0;
		Form.TheAmountOfTheSurcharge = Form.AmountDue - Form.PayAmount;
		
		Form.Items.GroupInTotal.CurrentPage = Form.Items.GroupSurcharge;
		Form.Items.CommandIssueReceipt.Enabled = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddDigit(EnteredDigitIsString)
	
	If ActiveField = Items.FieldReceivedInCash.Name Then
		
		Comma = Mid(ReceivedInCash, StrLen(ReceivedInCash) - DecimalPlaces, 1);
		CommaAtEndOfLine = Right(ReceivedInCash,1) = SeparatorOfWholeAndFractionalParts;
		
		ReceivedInCashWholePartByNumber = Int(RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash));
		ReceivedInCashWholePart = Format(ReceivedInCashWholePartByNumber, "NZ=0; NG=0");
		ReceivedInCashFractionalPart = Right(ReceivedInCash, StrLen(ReceivedInCash) - StrLen(Format(ReceivedInCashWholePartByNumber, ReceivedInCashFormatOfRepresentationOfIntegers)));
		
		If ReceivedInCashIsFractionalNumber Then
			If Not Comma = SeparatorOfWholeAndFractionalParts Then
				ReceivedInCashFractionalPart = ReceivedInCashFractionalPart + EnteredDigitIsString;
			Else
				Return;
			EndIf;
		Else
			ReceivedInCashWholePart = ReceivedInCashWholePart + EnteredDigitIsString;
		EndIf;
		
		ReceivedInCash = Format(Number(ReceivedInCashWholePart), ReceivedInCashFormatOfRepresentationOfIntegers) + ReceivedInCashFractionalPart;
		
		CalculateTotals(ThisObject);
		AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
		
	ElsIf ActiveField = Items.Phone.Name Then
		
		PhoneNumber10Characters = PhoneNumber10Characters + EnteredDigitIsString;
		Phone = RetailSalesClientServer.FormatPhoneNumber(PhoneNumber10Characters);
		
		If StrLen(PhoneNumber10Characters) = 10 Then
			CurrentItem = Items.CommandIssueReceipt;
		EndIf;
		
		RetailSalesClientServer.SetOptionToSendElectronicReceipt(
			ThisObject,
			PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS"));
		
	ElsIf ActiveField = Items.Email.Name Then
		
		Email = TrimAll(Email) + EnteredDigitIsString;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DisplayInformationOnBuyerSDisplay()
	
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	Display = Undefined;
	
	If TypeOf(Document) = Type("DocumentRef.CashRegisterReceipt")
		Or TypeOf(Document) = Type("DocumentRef.GiftCertificateSale") Then
		TextForPayment = NStr("vi = 'Cần thanh toán';
								|ru = 'К оплате';
								|en = 'Amount due'; fa = 'مبلغ سررسیدشده';
								|it = 'Da pagare';
								|pl = 'Do płatności';
								|tr = 'Ödenecek'")  + ":";
		TextDelivery   = NStr("vi = 'Tiền thừa';
								|ru = 'Сдача';
								|en = 'Change'; fa = 'تغییر';
								|it = 'Resto';
								|pl = 'Reszta';
								|tr = 'Para üstü'")     + ":";
		TextSurcharge = NStr("vi = 'Trả thêm';
							|ru = 'Доплатить';
							|en = 'Pay in addition'; fa = 'پرداخت مابه‌التفاوت';
							|it = 'Completare pagamento';
							|pl = 'Dopłacić';
							|tr = 'Ek ödeme yap'") + ":";
	Else
		TextForPayment = NStr("vi = 'Cần trả lại';
								|ru = 'К возврату';
								|en = 'For return'; fa = 'برای برگشت';
								|it = 'In restituzione';
								|pl = 'Do zwrotu';
								|tr = 'İade edilmek üzere'") + ":";
		TextDelivery   = NStr("vi = 'Tiền thừa';
								|ru = 'Сдача';
								|en = 'Change'; fa = 'تغییر';
								|it = 'Resto';
								|pl = 'Reszta';
								|tr = 'Para üstü'")      + ":";
		TextSurcharge = NStr("vi = 'Quay lại';
							|ru = 'Вернуть';
							|en = 'Return'; fa = 'مرجوعی';
							|it = 'Torna indietro';
							|pl = 'Przywróć';
							|tr = 'İade'")    + ":";
	EndIf;
	
	Dptext1 = RetailSalesClient.PrepareLineForDisplay(TextForPayment, AmountDue);
	
	If TheAmountOfTheSurcharge > 0 Then
		Dptext2 = RetailSalesClient.PrepareLineForDisplay(TextSurcharge, TheAmountOfTheSurcharge);
	ElsIf ChangeAmount > 0 Then
		Dptext2 = RetailSalesClient.PrepareLineForDisplay(TextDelivery, ChangeAmount);
	Else
		Dptext2 = "";
	EndIf;
	
	RetailSalesClient.DisplayTextOnBuyerSDisplays(
		FormOwner,
		Displays,
		Dptext1 + Chars.LF + Dptext2);
	
EndProcedure

&AtClient
Procedure SetElementActivity()
	
	RetailSalesClientServer.SetElementActivity(ThisObject);
	
EndProcedure

&AtServer
Function ProcessElectronicReceiptData()
	
	Return RetailSales.ProcessElectronicReceiptData(ThisObject);
	
EndFunction

#EndRegion