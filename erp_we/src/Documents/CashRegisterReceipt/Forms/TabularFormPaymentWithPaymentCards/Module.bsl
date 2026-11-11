
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TablePaymentByPaymentCards = GetFromTempStorage(Parameters.AddressInStorage);
	PaymentWithPaymentCards.Load(TablePaymentByPaymentCards);
	
	AmountOfOutstandingPaymentsByPaymentCards = 0;
	SelectionOfPaymentsByPaymentCards = New Structure;
	SelectionOfPaymentsByPaymentCards.Insert("PaymentKind_", Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);
	SelectionOfPaymentsByPaymentCards.Insert("PaymentIsCanceled", False);
	LinesOfNonCancelledPayments = PaymentWithPaymentCards.FindRows(SelectionOfPaymentsByPaymentCards);
	NumberOfOutstandingPayments = LinesOfNonCancelledPayments.Count();
	For Each PaymentLine_ In LinesOfNonCancelledPayments Do
		AmountOfOutstandingPaymentsByPaymentCards = AmountOfOutstandingPaymentsByPaymentCards + PaymentLine_.Sum;
	EndDo;
	
	If PaymentWithPaymentCards.FindRows(New Structure("PaymentIsCanceled", False)).Count() = 0 Then
		Items.PaymentCancel.Enabled = False;
		Items.FormCancelPaymentsSequentially.Enabled = False;
	EndIf;
	
	ShowCancelPaymentButton = Undefined;
	If Parameters.Property("ShowCancelPaymentButton", ShowCancelPaymentButton) Then
		Items.PaymentCancel.Visible = ShowCancelPaymentButton;
	EndIf;
	
	DocumentAmount = 0;
	If Parameters.Property("DocumentAmount") Then
		DocumentAmount = Parameters.DocumentAmount;
	EndIf;
		
	ShowCancelPaymentsButtonSequentially = Undefined;
	If Parameters.Property("ShowCancelPaymentsButtonSequentially", ShowCancelPaymentsButtonSequentially) Then
		Items.FormCancelPaymentsSequentially.Visible = ShowCancelPaymentsButtonSequentially;
	EndIf;

	If DocumentAmount < AmountOfOutstandingPaymentsByPaymentCards 
		Or NumberOfOutstandingPayments <= 1 Then
		Items.FormCancelPaymentsSequentially.Visible = False;
	EndIf;
		
	ShowPaymentCanceledColumn = Undefined;
	If Parameters.Property("ShowPaymentCanceledColumn", ShowPaymentCanceledColumn) Then
		Items.PaymentWithPaymentCardsPaymentIsCanceled.Visible = ShowPaymentCanceledColumn;
	EndIf;
	
	Items.PaymentWithPaymentCards.RowFilter = Undefined;
	If Parameters.Property("ShowOnlyPaymentsWithPaymentCards") And Parameters.ShowOnlyPaymentsWithPaymentCards = True Then
		SelectingLinesByPaymentType = New Structure;
		SelectingLinesByPaymentType.Insert("PaymentKind_", Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);
		Items.PaymentWithPaymentCards.RowFilter = New FixedStructure(SelectingLinesByPaymentType);
	EndIf;
	
	If Parameters.Property("ThisIsReturn", ThisIsReturn) And ThisIsReturn = True Then
		Title = NStr("vi = 'Thanh toán bằng thẻ thanh toán theo phiếu bán hàng';
					|ru = 'Оплаты платежными картами по чеку продажи';
					|en = 'Payments by payment cards by sales receipt'; fa = 'پرداخت‌ها با کارت‌های پرداخت بر اساس رسید فروش';
					|it = 'Annullare i pagamenti con le carte di pagamento';
					|pl = 'Payments by payment cards by sales receipt';
					|tr = 'Satış fişi doğrultusunda ödeme kartlarıyla yapılan ödemeler'");

		ThisIsFullReturnOnSalesShift = (Parameters.Property("ThisIsFullReturnOnSalesShift") And Parameters.ThisIsFullReturnOnSalesShift = True);
		SetButtonTitles(ThisIsFullReturnOnSalesShift);
		
	Else
		ThisIsReturn = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PaymentCancel(Command)
	
	CurrentData = Items.PaymentWithPaymentCards.CurrentData;
	If CurrentData <> Undefined Then
		
		ReturnValue = New Structure;
		ReturnValue.Insert("Action", "PaymentCancel");
		ReturnValue.Insert("RowSelected", Items.PaymentWithPaymentCards.CurrentData);
		
		Close(ReturnValue);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelPaymentsSequentially(Command)
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Action", "CancelPaymentsSequentially");
	RowsSelected = PaymentWithPaymentCards.FindRows(New Structure("PaymentIsCanceled", False));
	ReturnValue.Insert("RowsSelected", RowsSelected);
	
	Close(ReturnValue);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentWithPaymentCards

&AtClient
Procedure PaymentWithPaymentCardsOnActivateRow(Item)
	
	If ThisIsReturn Then
		CurrentRow = Items.PaymentWithPaymentCards.CurrentData;
		If Not CurrentRow = Undefined Then
			YouCanCancelPayment = (CurrentRow.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard") 
									And CurrentRow.PaymentIsCanceled = False 
									And DocumentAmount >= CurrentRow.Sum);
			Items.PaymentCancel.Enabled = YouCanCancelPayment;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetButtonTitles(ThisIsFullReturnOnSalesShift)
	
	TextOfCancelPaymentHint = NStr("vi = 'Trả lại thanh toán đã chọn vào thẻ thanh toán';
									|ru = 'Вернуть выделенную оплату на платежную карту';
									|en = 'Return the selected payment to the payment card'; fa = 'Return the selected payment to the payment card';
									|it = 'Вернуть выделенную оплату на платежную карту';
									|pl = 'Return the selected payment to the payment card';
									|tr = 'Tahsis edilen ödemeyi ödeme kartına iade et'");
	TextOfCancelPaymentHeader = NStr("vi = 'Hoàn tiền';
									|ru = 'Вернуть оплату';
									|en = 'Return payment'; fa = 'Return payment';
									|it = 'Вернуть оплату';
									|pl = 'Return payment';
									|tr = 'Ödemeyi iade et'");
	HintTextCancelPaymentSequentially = NStr("vi = 'Trả lại tất cả các khoản thanh toán vào thẻ thanh toán một cách tuần tự';
											|ru = 'Вернуть все оплаты на платежные карты последовательно';
											|en = 'Return all payments to payment cards sequentially'; fa = 'Return all payments to payment cards sequentially';
											|it = 'Вернуть все оплаты на платежные карты последовательно';
											|pl = 'Return all payments to payment cards sequentially';
											|tr = 'Tüm ödemeleri sıralı olarak ödeme kartlarına iade et'");
	HeaderTextCancelPaymentSequentially = NStr("vi = 'Hủy bỏ thanh toán theo trình tự';
												|ru = 'Вернуть оплаты последовательно';
												|en = 'Return payments sequentially'; fa = 'Return payments sequentially';
												|it = 'Вернуть оплаты последовательно';
												|pl = 'Return payments sequentially';
												|tr = 'Ödemeleri sırayla iade et'");
	
	If Not ThisIsReturn Or ThisIsFullReturnOnSalesShift Then
		TextOfCancelPaymentHint = NStr("vi = 'Hủy thanh toán đã chọn bằng thẻ thanh toán';
										|ru = 'Отменить выделенную оплату платежной картой';
										|en = 'Cancel the selected payment by payment card'; fa = 'Cancel the selected payment by payment card';
										|it = 'Отменить выделенную оплату платежной картой';
										|pl = 'Cancel the selected payment by payment card';
										|tr = 'Ödeme kartıyla tahsis edilen ödemeyi iptal et'");
		TextOfCancelPaymentHeader = NStr("vi = 'Hủy bỏ thanh toán';
										|ru = 'Отменить оплату';
										|en = 'Void payment'; fa = 'ابطال پرداخت';
										|it = 'Annullare il pagamento';
										|pl = 'Anuluj płatność';
										|tr = 'Ödemeyi iptal et'");
		HintTextCancelPaymentSequentially = NStr("vi = 'Hủy bỏ tất cả thanh toán bằng thẻ thanh toán theo trình tự';
												|ru = 'Отменить все оплаты платежной картой последовательно';
												|en = 'Cancel all payments by payment card sequentially'; fa = 'Cancel all payments by payment card sequentially';
												|it = 'Отменить все оплаты платежной картой последовательно';
												|pl = 'Cancel all payments by payment card sequentially';
												|tr = 'Tüm ödeme kartı ödemelerini sırayla iptal et'");
		HeaderTextCancelPaymentSequentially = NStr("vi = 'Hủy bỏ thanh toán theo trình tự';
													|ru = 'Отменить оплаты последовательно';
													|en = 'Cancel payments sequentially'; fa = 'لغو پرداخت‌ها به ترتیب';
													|it = 'Отменить оплаты последовательно';
													|pl = 'Cancel payments sequentially';
													|tr = 'Ödemeleri sırayla iptal et'");
	EndIf;
	
	Commands.PaymentCancel.Title = TextOfCancelPaymentHeader;
	Commands.PaymentCancel.ToolTip = TextOfCancelPaymentHint;
	Commands.CancelPaymentsSequentially.Title = HeaderTextCancelPaymentSequentially;
	Commands.CancelPaymentsSequentially.ToolTip = HintTextCancelPaymentSequentially;
	
EndProcedure

#EndRegion
