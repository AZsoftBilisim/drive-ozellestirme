
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
	
	AmountDue           = PaymentInformation.AmountToPay;
	ReceivedInCash = Format(PaymentInformation.CashPayment, ReceivedInCashFormatOfRepresentationOfIntegers);
	PaidByCertificates = PaymentInformation.GiftCertificates;
	PaidWithBonusPoints = PaymentInformation.BonusPoints;
	
	WindowOptionsKey = "377c7c49-b1da-44f8-bcc6-8f35916a4354";

	ThisIsFullPaymentByCreditCard = False;
	ThisIsFullPaymentWithGiftCertificates = False;
	ThisIsFullPaymentViaSBP = False;
	
	ThisIsReturn = False;
	ThisIsFullReturnOnSalesShift = False;
	If TypeOf(Document) = Type("DocumentRef.CashRegisterReceiptReturn")
		Or TypeOf(Document) = Type("DocumentRef.ReturnOfGiftCards") Then
		WindowOptionsKey = "e5abb7c5-8718-44b7-9eaf-728457d19608";
		ThisIsReturn = True;
		PaidWithPaymentCards = PaymentInformation.PaymentCardsCanceled;
		If Parameters.Property("ThisIsFullReturnOnSalesShift") 
			And Parameters.ThisIsFullReturnOnSalesShift = True Then
			ThisIsFullReturnOnSalesShift = True;
		EndIf;
		
		If Parameters.Property("StatusOfSBPPaymentOfSalesReceipt") Then
			StatusOfSBPPaymentOfSalesReceipt = Parameters.StatusOfSBPPaymentOfSalesReceipt;
		EndIf;
	Else
		PaidWithPaymentCards = PaymentInformation.PaymentCards;
	EndIf;
	If AmountDue = PaidWithPaymentCards Then
		WindowOptionsKey = "06cf07e4-6da2-4e18-910e-e9eb70d61006";
		ThisIsFullPaymentByCreditCard = True;
	ElsIf AmountDue = PaidByCertificates Then
		WindowOptionsKey = "2c9507fb-3fc6-4175-bbd9-1a05f3aded5c";
		ThisIsFullPaymentWithGiftCertificates = True;
	EndIf;
	OnCreateAtServerLocalization(PaymentInformation);
	
	AdjustElementVisibility(PaymentInformation);
	
	Items.GroupSendingAnElectronicReceipt.Visible = True;
	FieldSelectionBackColor = StyleColors.SelectionBackColor;
	
	Partner = Parameters.Partner;
	RetailSales.FillInParametersForSendingElectronicReceiptToPartner(ThisObject);
	
	RetailSalesClientServer.SetActiveElement(ThisObject, Items.FieldReceivedInCash);
	RetailSalesClientServer.SetAccessibilityOfKeyboardButtonsOfMixedPaymentForm(ThisObject);
	Phone = RetailSalesClientServer.FormatPhoneNumber(PhoneNumber10Characters);
	
	CalculateTotals(ThisObject, PaymentInformation);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	CrntNotification = CallbackDescriptionOnClose;
	If Exit 
		And TypeOf(CrntNotification) = Type("CallbackDescription")
		And TypeOf(CrntNotification.AdditionalParameters) = Type("Structure")Then
		
		CrntNotification.AdditionalParameters.Insert("Exit", Exit);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	AttachIdleHandler("SetElementActivity", 1, False);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Or Exit Then
		Return;
	EndIf;
	
	BeforeClosingOnClient(Cancel);
	
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
	
	If ActiveField = Items.FieldReceivedInCash.Name Then
		
		If ReceivedInCash = "" Then
			ReceivedInCash = "0";
		EndIf;
		
		If Not ReceivedInCashIsFractionalNumber Then
			ReceivedInCashIsFractionalNumber = True;
			ReceivedInCash = ReceivedInCash + SeparatorOfWholeAndFractionalParts;
		EndIf;
		
		CalculateTotals(ThisObject);
		AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
		
	Else
		
		PhoneNumber10Characters = "";
		
	EndIf;
	
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
	
	ForceCloseTheForm = True;
	Close(PaymentResult);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	BeforeClosingOnClient(True);
	
EndProcedure

&AtClient
Procedure PaymentPaymentCard(Command)
	
	ClearMessages();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationToPaymentForm", New CallbackDescription("PaymentCompletion", ThisObject));
	AdditionalParameters.Insert("ReceivedInCash", RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash));
	AdditionalParameters.Insert("Form", ThisObject);
	
	If TypeOf(Document) = Type("DocumentRef.CashRegisterReceipt")
		Or TypeOf(Document) = Type("DocumentRef.GiftCertificateSale") Then
		
		If TheAmountOfTheSurcharge <= 0 Then
			CommonClient.MessageToUser(NStr("vi = 'Phiếu tính tiền đã thanh toán';
											|ru = 'Чек оплачен';
											|en = 'The Receipt is paid'; fa = 'The Receipt is paid';
											|it = 'Scontrino pagato';
											|pl = 'Paragon został opłacony';
											|tr = 'Ödenen makbuz'"));
			Return;
		EndIf;
		
		RunCallback(
			New CallbackDescription("AddCardPayment", FormOwner, AdditionalParameters),
			True);
	Else
		
		If TheAmountOfTheSurcharge <= 0 Then
			CommonClient.MessageToUser(NStr("vi = 'Phiếu tính tiền đã thanh toán';
											|ru = 'Чек оплачен';
											|en = 'The Receipt is paid'; fa = 'The Receipt is paid';
											|it = 'Scontrino pagato';
											|pl = 'Paragon został opłacony';
											|tr = 'Ödenen makbuz'"));
			Return;
		EndIf;
		
		RunCallback(
			New CallbackDescription("PaymentCancel", FormOwner, AdditionalParameters),
			True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PayForSBP(Command)
	
	PayForSBPLocalization();
	
EndProcedure

&AtClient
Procedure PaymentGiftCertificate(Command)
	
	ClearMessages();
	
	If TypeOf(Document) = Type("DocumentRef.CashRegisterReceipt")
		Or TypeOf(Document) = Type("DocumentRef.GiftCertificateSale") Then
		
		If TheAmountOfTheSurcharge <= 0 Then
			CommonClient.MessageToUser(NStr("vi = 'Phiếu tính tiền đã thanh toán';
											|ru = 'Чек оплачен';
											|en = 'The Receipt is paid'; fa = 'The Receipt is paid';
											|it = 'Scontrino pagato';
											|pl = 'Paragon został opłacony';
											|tr = 'Ödenen makbuz'"));
			Return;
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationToPaymentForm", New CallbackDescription("PaymentCompletion", ThisObject));
	AdditionalParameters.Insert("ReceivedInCash", RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash));
	
	RunCallback(
		New CallbackDescription("AddGiftCertificatePayment", FormOwner, AdditionalParameters),
		True);
	
EndProcedure

&AtClient
Procedure PaymentBonusPoints(Command)
	
	ClearMessages();
	
	If TypeOf(Document) = Type("DocumentRef.CashRegisterReceipt")
		Or TypeOf(Document) = Type("DocumentRef.GiftCertificateSale") Then
		
		If TheAmountOfTheSurcharge <= 0 Then
			CommonClient.MessageToUser(NStr("vi = 'Phiếu tính tiền đã thanh toán';
											|ru = 'Чек оплачен';
											|en = 'The Receipt is paid'; fa = 'The Receipt is paid';
											|it = 'Scontrino pagato';
											|pl = 'Paragon został opłacony';
											|tr = 'Ödenen makbuz'"));
			Return;
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationToPaymentForm", New CallbackDescription("PaymentCompletion", ThisObject));
	AdditionalParameters.Insert("ReceivedInCash", RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash));
	
	RunCallback(
		New CallbackDescription("AddPaymentWithBonusPoints", FormOwner, AdditionalParameters),
		True);
	
EndProcedure

&AtClient
Procedure TheStornoTeam(Command)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationToPaymentForm", New CallbackDescription("PaymentCompletion", ThisObject));
	AdditionalParameters.Insert("ReceivedInCash", RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash));
	
	RunCallback(
		New CallbackDescription("CancelPaymentsByPaymentCards", FormOwner, AdditionalParameters),
		True);
	
EndProcedure

&AtClient
Procedure SendSMSCommand(Command)
	
	RetailSalesClientServer.SetActiveElement(ThisObject, Items.Phone);
	RetailSalesClientServer.SetAccessibilityOfKeyboardButtonsOfMixedPaymentForm(ThisObject);
	RetailSalesClientServer.SetOptionToSendElectronicReceipt(
		ThisObject,
		PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS"));
	
EndProcedure

&AtClient
Procedure SendEmailCommand(Command)
	
	RetailSalesClientServer.SetActiveElement(ThisObject, Items.Email);
	RetailSalesClientServer.SetAccessibilityOfKeyboardButtonsOfMixedPaymentForm(ThisObject);
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

&AtClientAtServerNoContext
Procedure CalculateTotals(Form, PaymentInformation = Undefined)
	
	ReceivedInCashByNumber = RetailSalesClientServer.Convert_String_To_Number(Form.ReceivedInCash);
	Form.PayAmount = ReceivedInCashByNumber
	                  + Form.PaidWithBonusPoints
	                  + Form.PaidWithPaymentCards
	                  + Form.PaidByCertificates
	                  + Form.PaidBySBP;
	
	If Form.PayAmount >= Form.AmountDue Then
		Form.TheAmountOfTheSurcharge = 0;
		Form.ChangeAmount   = Form.PayAmount - Form.AmountDue;
		
		// It is necessary to adjust the return amount of cash payment if it exceeds the deposit amount.
		If Form.ThisIsReturn And Form.ChangeAmount > 0 And Form.ChangeAmount <= ReceivedInCashByNumber Then
			ReceivedInCashByNumber = ReceivedInCashByNumber - Form.ChangeAmount;
			Form.PayAmount = Form.PayAmount - Form.ChangeAmount;
			Form.ChangeAmount = 0;
			Form.ReceivedInCash = Format(ReceivedInCashByNumber, Form.ReceivedInCashFormatOfRepresentationOfIntegers);
		EndIf;
		
		Form.Items.GroupInTotal.CurrentPage = Form.Items.DeliveryGroup_;
		Form.Items.CommandIssueReceipt.Enabled = True;
		
		Form.CurrentItem = Form.Items.CommandIssueReceipt;
		
	Else
		
		Form.ChangeAmount   = 0;
		Form.TheAmountOfTheSurcharge = Form.AmountDue - Form.PayAmount;
		
		Form.Items.GroupInTotal.CurrentPage = Form.Items.GroupSurcharge;
		Form.Items.CommandIssueReceipt.Enabled = False;
		
	EndIf;
	
	If Form.ThisIsReturn And TypeOf(PaymentInformation) = Type("Structure") Then
		Form.Items.PaymentPaymentCard.Enabled = (Form.PayAmount < PaymentInformation.AmountToPay);
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentCompletion(PaymentInformation, AdditionalParameters) Export
	
	AmountDue = PaymentInformation.AmountToPay;
	
	PaidByCertificates = PaymentInformation.GiftCertificates;
	PaidWithBonusPoints = PaymentInformation.BonusPoints;
	
	If ThisIsReturn Then
		PaidWithPaymentCards = PaymentInformation.PaymentCardsCanceled;
	Else
		PaidWithPaymentCards = PaymentInformation.PaymentCards;
	EndIf;
	PaymentCompletionLocalization(PaymentInformation);
	
	CalculateTotals(ThisObject, PaymentInformation);
	AdjustElementVisibility(PaymentInformation);
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	If ForceCloseTheFormIfPaymentIsCanceledSuccessfully Then
		
		If PaymentInformation.TotalPaid_ = 0 
			Or PostponeReceiptLocalization(PaymentInformation) Then
			ForceCloseTheForm = True;
			Close(FormClosingParameters().Cancel);
		Else
			ForceCloseTheFormIfPaymentIsCanceledSuccessfully = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "PaymentCancel" Then
		
		ForceCloseTheFormIfPaymentIsCanceledSuccessfully = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("NotificationToPaymentForm", New CallbackDescription("PaymentCompletion", ThisObject));
		AdditionalParameters.Insert("ReceivedInCash", RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash));
		
		RunCallback(
			New CallbackDescription("PaymentCancel", FormOwner, AdditionalParameters),
			True);
			
	ElsIf UserAnswer = "CloseForm" Then
		
		ForceCloseTheFormIfPaymentIsCanceledSuccessfully = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("NotificationToPaymentForm", New CallbackDescription("PaymentCompletion", ThisObject));
		AdditionalParameters.Insert("ReceivedInCash", RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash));
		
		RunCallback(
			New CallbackDescription("CancelPaymentReverse", FormOwner, AdditionalParameters),
			True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AdjustElementVisibility(PaymentInformation)
	
	AvailablePaymentMethods = PaymentInformation.AvailablePaymentMethods;
	
	Items.FieldPaidWithPaymentCards.Visible = AvailablePaymentMethods.PaymentCards;
	Items.PaymentPaymentCard.Visible          = AvailablePaymentMethods.PaymentCards;
	Items.TheStornoTeam.Visible                 = AvailablePaymentMethods.PaymentCards;
	
	Items.TheFieldIsPaidForWithCertificates.Visible     = AvailablePaymentMethods.GiftCertificates;
	Items.PaymentGiftCertificate.Visible    = AvailablePaymentMethods.GiftCertificates;
	
	Items.TheFieldIsPaidForWithBonusPoints.Visible  = AvailablePaymentMethods.BonusPoints;
	Items.PaymentBonusPoints.Visible           = AvailablePaymentMethods.BonusPoints;
	
	If ThisIsReturn Then
		
		Title = NStr("vi = 'Hoàn tiền thanh toán hỗn hợp';
					|ru = 'Возврат смешанной оплаты';
					|en = 'Return mixed payment'; fa = 'Return mixed payment';
					|it = 'Rimborso del pagamento misto';
					|pl = 'Zwrot mieszanej płatności.';
					|tr = 'Karma ücretlerin iadesi'");
		
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

		PayByCreditCardHeader       = NStr("vi = 'Trả lại thanh toán vào thẻ thanh toán';
											|ru = 'Вернуть оплату на платежную карту';
											|en = 'Return the payment to the payment card'; fa = 'برگشت پرداخت به کارت پرداخت';
											|it = 'Annullare il pagamento con le carte di pagamento';
											|pl = 'Return the payment to the payment card';
											|tr = 'Ücreti ödeme kartına iade et'");
		PayWithPaymentCardHint       = NStr("vi = 'Trả lại thanh toán vào thẻ thanh toán';
											|ru = 'Вернуть оплату на платежную карту';
											|en = 'Return the payment to the payment card'; fa = 'برگشت پرداخت به کارت پرداخت';
											|it = 'Annullare il pagamento con le carte di pagamento';
											|pl = 'Return the payment to the payment card';
											|tr = 'Ücreti ödeme kartına iade et'");
		If ThisIsFullReturnOnSalesShift And PaymentInformation.PaymentCards > 0 Then
			PayByCreditCardHeader       = NStr("vi = 'Hủy thanh toán bằng thẻ';
												|ru = 'Отменить оплату платежными картами';
												|en = 'Void payment by cards'; fa = 'ابطال پرداخت با کارت‌ها';
												|it = 'Annullare il pagamento con le carte di pagamento';
												|pl = 'Anuluj płatność kartami płatniczymi';
												|tr = 'Ödeme kartıyla ödemeyi iptal et'");
			PayWithPaymentCardHint       = NStr("vi = 'Hủy thanh toán bằng thẻ';
												|ru = 'Отменить оплату платежными картами';
												|en = 'Void payment by cards'; fa = 'ابطال پرداخت با کارت‌ها';
												|it = 'Annullare il pagamento con le carte di pagamento';
												|pl = 'Anuluj płatność kartami płatniczymi';
												|tr = 'Ödeme kartıyla ödemeyi iptal et'");
		EndIf;
		Commands.PayByPaymentCard.Title = PayByCreditCardHeader;
		Commands.PayByPaymentCard.ToolTip = PayWithPaymentCardHint;
		Commands.PayUsingGiftCertificate.Title = NStr("vi = 'Trả lại khoản thanh toán bằng phiếu quà tặng';
														|ru = 'Вернуть оплату подарочным сертификатом';
														|en = 'Return payment made with a gift card'; fa = 'Return payment made with a gift card';
														|it = 'Restituire il pagamento trmite buono regalo';
														|pl = 'Zwróć płatność certyfikatem podarunkowym';
														|tr = 'Hediye kuponu ödemesini iade et'");
		Commands.PayUsingGiftCertificate.ToolTip = NStr("vi = 'Trả lại khoản thanh toán bằng phiếu quà tặng';
														|ru = 'Вернуть оплату подарочным сертификатом';
														|en = 'Return payment made with a gift card'; fa = 'Return payment made with a gift card';
														|it = 'Restituire il pagamento trmite buono regalo';
														|pl = 'Zwróć płatność certyfikatem podarunkowym';
														|tr = 'Hediye kuponu ödemesini iade et'");
		Commands.PayUsingBonusPoints.Title = NStr("vi = 'Hủy thanh toán với điểm thưởng';
													|ru = 'Отменить оплату бонусными баллами';
													|en = 'Void payment with bonus points'; fa = 'ابطال پرداخت با امتیازهای جایزه';
													|it = 'Annullare pagamento con punti bonus';
													|pl = 'Anuluj płatność punktami bonusowymi.';
													|tr = 'Bonus puan ödemesini iptal et'");
		Commands.PayUsingBonusPoints.ToolTip = NStr("vi = 'Hủy thanh toán với điểm thưởng';
													|ru = 'Отменить оплату бонусными баллами';
													|en = 'Void payment with bonus points'; fa = 'ابطال پرداخت با امتیازهای جایزه';
													|it = 'Annullare pagamento con punti bonus';
													|pl = 'Anuluj płatność punktami bonusowymi.';
													|tr = 'Bonus puan ödemesini iptal et'");
		
		Items.TheStornoTeam.Visible = False;
		
	EndIf;
	
	If ThisIsFullPaymentByCreditCard Then
		
		If ThisIsReturn Then
			Title = NStr("vi = 'Trả lại khoản thanh toán qua thẻ thanh toán';
						|ru = 'Возврат оплаты платежной картой';
						|en = 'Refund by payment card'; fa = 'Refund by payment card';
						|it = 'Reso del pagamento tramite carte di pagamento';
						|pl = 'Zwrot płatności kartą płatniczą';
						|tr = 'Ödeme kartı ödemesini iade et'");
			If ThisIsFullReturnOnSalesShift Then
				Title = NStr("vi = 'Hủy bỏ thanh toán bằng thẻ thanh toán';
							|ru = 'Отмена оплаты платежной картой';
							|en = 'Cancel payment by payment card'; fa = 'لغو پرداخت با کارت پرداخت';
							|it = 'Отмена оплаты платежной картой';
							|pl = 'Cancel payment by payment card';
							|tr = 'Ödeme kartıyla yapılan ödemenin iptali'");
            EndIf;
		Else
			Title = NStr("vi = 'Thanh toán bằng thẻ';
						|ru = 'Оплата платежной картой';
						|en = 'Payment by payment card'; fa = 'پرداخت با کارت پرداخت';
						|it = 'Pagamento con la carta di pagamento';
						|pl = 'Płatność kartą płatniczą';
						|tr = 'Ödeme kartıyla ödeme'");
		EndIf;

		Items.CloseButton.Title = NStr("vi = 'Hủy thanh toán';
										|ru = 'Отменить оплату';
										|en = 'Void payment'; fa = 'ابطال پرداخت';
										|it = 'Annullare il pagamento';
										|pl = 'Anuluj płatność';
										|tr = 'Ödeme iptali'");

		Items.FieldReceivedInCash.Visible = False;
		Items.TheFieldIsPaidForWithCertificates.Visible = False;
		Items.TheFieldIsPaidForWithBonusPoints.Visible = False;
		Items.FieldWasPaidForBySBP.Visible = False;
		Items.GroupPaymentTypes.Visible = False;
		
	ElsIf ThisIsFullPaymentWithGiftCertificates Then
		
		Title = NStr("vi = 'Thanh toán bằng phiếu quà tặng';
					|ru = 'Оплата подарочными сертификатами';
					|en = 'Payment with gift cards'; fa = 'پرداخت با کارت‌های هدیه';
					|it = 'Pagamento con certificati regalo';
					|pl = 'Płatność za pomocą certyfikatów podarunkowych';
					|tr = 'Hediye kuponuyla ödeme'");

		Items.CloseButton.Title = NStr("vi = 'Hủy thanh toán';
										|ru = 'Отменить оплату';
										|en = 'Void payment'; fa = 'ابطال پرداخت';
										|it = 'Annullare il pagamento';
										|pl = 'Anuluj płatność';
										|tr = 'Ödeme iptali'");
		
		Items.FieldReceivedInCash.Visible = False;
		Items.FieldPaidWithPaymentCards.Visible = False;
		Items.TheFieldIsPaidForWithBonusPoints.Visible = False;
		Items.FieldWasPaidForBySBP.Visible = False;
		Items.GroupPaymentTypes.Visible = False;
		
	EndIf;
	
	AdjustElementVisibilityLocalization(PaymentInformation);
	
EndProcedure

&AtClient
Procedure DisplayInformationOnBuyerSDisplay()
	
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	FormatString = "NFD=2; NGS=' '; NZ=0.00; NG=0";
	TextLength = 20;
	
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
	RetailSalesClientServer.SetAccessibilityOfKeyboardButtonsOfMixedPaymentForm(ThisObject);
	
EndProcedure

&AtServer
Function ProcessElectronicReceiptData()
	
	Return RetailSales.ProcessElectronicReceiptData(ThisObject);
	
EndFunction

&AtClient
Function FormClosingParameters()
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("Cancel", "Cancel");
	
	Return ClosingParameters;
	
EndFunction

&AtClient
Procedure BeforeClosingOnClient(Cancel)
	
	If RetailSalesClientServer.Convert_String_To_Number(ReceivedInCash) <> 0
		Or PaidWithPaymentCards <> 0
		Or PaidByCertificates <> 0
		Or PaidWithBonusPoints
		Or PaidBySBP <> 0 Then
		
		Cancel = True;
		
		If ThisIsReturn Then
			
			Buttons = New ValueList;
			Buttons.Add("CloseForm", NStr("vi = 'Đóng cửa sổ';
											|ru = 'Закрыть окно';
											|en = 'Close window'; fa = 'Close window';
											|it = 'Chiudere la finestra';
											|pl = 'Zamknij okno dialogowe';
											|tr = 'Pencereyi kapat'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
			
			
			QuestionTextArray = New Array();
			If PaidWithPaymentCards <> 0 Then
				QueryText = NStr("vi = 'Dữ liệu hủy trả lại qua thẻ thanh toán được gửi đến ngân hàng.';
								|ru = 'Данные об отмене возврата на платежную карту отправлены в банк.';
								|en = 'Details of voiding the payment card refund are sent to the bank.'; fa = 'Details of voiding the payment card refund are sent to the bank.';
								|it = 'I dati sull''annullamento della restituzione sulla carta di pagamento sono stati inviati alla banca.';
								|pl = 'Dane o anulowaniu zwrotu na kartę płatniczą zostały wysłane do banku.';
								|tr = 'Kredi kartına iade iptali bilgileri bankaya gönderilmiştir.'");
				QuestionTextArray.Add(QueryText);
			EndIf;
			If PaidBySBP <> 0 Then
				QueryText = NStr("vi = 'Dữ liệu trả lại khoản thanh toán qua hệ thống thanh toán nhanh được gửi đến ngân hàng và giao dịch đã được ngân hàng xác nhận.';
								|ru = 'Данные о возврате оплаты СБП отправлены в банк и банком подтверждена операция.';
								|en = 'Details of Faster Payments System refund are sent to the bank. The bank confirmed the transaction.'; fa = 'Details of Faster Payments System refund are sent to the bank. The bank confirmed the transaction.';
								|it = 'I dati sulla restituzione del pagamento SBP sono stati inviati alla banca, l''operazione è stata confermata dalla banca.';
								|pl = 'Dane o zwrocie płatności przez system szybkich płatności zostały wysłane do banku i operacja została potwierdzona przez bank.';
								|tr = 'HÖS iade ibrazının ayrıntıları bankaya gönderilmiş ve banka işlemi onaylamıştır.'");
				QuestionTextArray.Add(QueryText);
			EndIf;
			
			QueryText = NStr("vi = 'Bạn muốn đóng cửa sổ đồng thời dữ liệu đã nhập sẽ bị mất?';
							|ru = 'Хотите закрыть окно с потерей введенных данных?';
							|en = 'Entered data will be lost. Are you sure you want to close the window?'; fa = 'Entered data will be lost. Are you sure you want to close the window?';
							|it = 'Chiudere la finestra perdendo i dati inseriti?';
							|pl = 'Czy chcesz zamknąć okno dialogowe z utratą wprowadzonych danych?';
							|tr = 'Kayıp verilerin girildiği pencereyi kapatmak istiyor musunuz?'");
			QuestionTextArray.Add(QueryText);
			
			FullTextOfQuestion = "";
			For Each QueryText In QuestionTextArray Do
				If FullTextOfQuestion <> "" Then
					FullTextOfQuestion = FullTextOfQuestion + Chars.LF;
				EndIf;
				
				FullTextOfQuestion = FullTextOfQuestion + QueryText;
			EndDo;
			
			ShowQueryBox(
				New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
				FullTextOfQuestion, Buttons);
			
		Else
			
			Buttons = New ValueList;
			Buttons.Add("PaymentCancel", NStr("vi = 'Hủy thanh toán';
												|ru = 'Отменить оплату';
												|en = 'Void payment'; fa = 'ابطال پرداخت';
												|it = 'Annullare il pagamento';
												|pl = 'Anuluj płatność';
												|tr = 'Ödeme iptali'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
			
			QueryText = NStr("vi = 'Trước khi đóng hình thức thanh toán, cần hủy khoản thanh toán đã thực hiện.';
							|ru = 'Перед закрытием формы оплаты требуется отменить произведенную оплату.';
							|en = 'Cancel the performed payment before closing the payment form.'; fa = 'Cancel the performed payment before closing the payment form.';
							|it = 'Prima di chiudere il metodo di pagamento è necessario annullare il pagamento effettuato.';
							|pl = 'Przed zamknięciem formy płatności należy anulować wykonaną płatność.';
							|tr = 'Ödeme formu kapatılmadan önce ödeme iptal edilmelidir.'");
			If PaidBySBP <> 0 Then
				QueryText = NStr("vi = 'Phiếu đã được thanh toán bởi hệ thống thanh toán nhanh. Không thể hủy thanh toán bởi hệ thống thanh toán nhanh, cần đánh phiếu.
				                          |Chỉ có thể hoãn phiếu trong trường hợp thiết bị bị hỏng đến khi khôi phục công việc.
				                          |Khi hoãn phiếu, cần hủy các hình thức thanh toán đã thực hiện khác.';
				                          |ru = 'По чеку проведена оплата СБП. Оплату СБП отменить нельзя, требуется пробить чек.
				                          |Отложить чек только в случае отказа оборудования до восстановления работы.
				                          |Откладывая чек другие произведенные формы оплаты потребуется отменить.';
				                          |en = 'Faster Payments System payment is posted using the receipt. You cannot void the Faster Payments System payment.
				                          |You can put the receipt on hold only if the hardware has failed and till the time it is fixed.
				                          |If you put the receipt on hold, void other performed payment methods.'; fa = 'Faster Payments System payment is posted using the receipt. You cannot void the Faster Payments System payment.
				                          |You can put the receipt on hold only if the hardware has failed and till the time it is fixed.
				                          |If you put the receipt on hold, void other performed payment methods.';
				                          |it = 'Lo scontrino è pagato tramite SBP. Il pagamento SBP non può essere annullato, lo scontrino deve essere emesso.
				                          |Rinviare l''emissione solo in caso di malfunzionamento delle attrezzature fino al ripristino del regolare funzionamento.
				                          |Rinviando lo scontrino, altre forme di pagamento eseguite devono essere annullate.';
				                          |pl = 'Według paragonu dokonano płatności przez system szybkich płatności. Płatność przez system szybkich płatności nie można anulować, należy wydać paragon.
				                          |Odłożyć paragon tylko w przypadku awarii sprzętu do przywrócenia pracy.
				                          |Odkładając paragon inne dokonane metody płatności trzeba będzie anulować.';
				                          |tr = 'Fiş üzerinde bir HÖS ödemesi yapılmıştır. HÖS ödemesi iptal edilemez ve çekin takas edilmesi gerekir.
				                          | Fişi yalnızca ekipman arızası durumunda çalışma yeniden sağlanana kadar erteleyin.
				                          | Fişin ertelenmesiyle birlikte yapılan diğer ödeme şekillerinin de iptal edilmesi gerekecektir.'");
				Buttons[0].Presentation = NStr("vi = 'Hoãn phiếu';
												|ru = 'Отложить чек';
												|en = 'Put receipt on hold'; fa = 'Put receipt on hold';
												|it = 'Rinviare lo scontrino';
												|pl = 'Odłóż paragon';
												|tr = 'Makbuzu ertele'");
			EndIf;
			
			ShowQueryBox(
				New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
				QueryText, Buttons);
				
		EndIf;
		
	Else
		
		Close(FormClosingParameters().Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Localization

&AtServer
Procedure AdjustElementVisibilityLocalization(PaymentInformation)
	
	
EndProcedure

&AtClient
Procedure PaymentCompletionLocalization(PaymentInformation)
	
	
EndProcedure

&AtClient
Procedure PayForSBPLocalization()
	
	
EndProcedure

&AtClient
Function PostponeReceiptLocalization(PaymentInformation)
	
	PostponeReceipt = False;
	
	
	Return PostponeReceipt;
	
EndFunction

&AtServer
Procedure OnCreateAtServerLocalization(PaymentInformation)
	
	
EndProcedure

#EndRegion


