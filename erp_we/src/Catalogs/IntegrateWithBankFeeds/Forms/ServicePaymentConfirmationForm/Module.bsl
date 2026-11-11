	
#Region FormEventHandlers
	
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	ArrayOfLinksToPaymentConfirmation	= Parameters.ArrayOfPaymentConfirmationLinks;  
	LinkToPaymentConfirmation = ArrayOfLinksToPaymentConfirmation[0].LinkToPaymentConfirmation; 
	AddressBankAccounts = Parameters.AddressBankAccounts;
	AddressDocumentsToBeUploaded = Parameters.AddressDocumentsToBeUploaded;
	UploadIsPerformedWhenSyncing = Parameters.UploadIsPerformedWhenSyncing;  
	BankAccount = Parameters.BankAccount;
	
	For Each CurLineArrayOfPaymentConfirmationLinks In ArrayOfLinksToPaymentConfirmation Do
		
		PaymentDocumentData = CurLineArrayOfPaymentConfirmationLinks.PaymentDocumentData;
		
		PresentationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1, đối với số tiền %2 (%3)';
					|ru = '%1, на сумму %2 (%3)';
					|en = '%1, in the amount of %2 (%3)'; fa = '%1, in the amount of %2 (%3)';
					|it = '%1, на сумму %2 (%3)';
					|pl = '%1, in the amount of %2 (%3)';
					|tr = '%1, %2 (%3) tutarında'"),
				PaymentDocumentData.DocumentKind,
				PaymentDocumentData.Sum,
				PaymentDocumentData.Currency);
					
		NewRow = PaymentTableForPaymentConfirmation.Add();			
		NewRow.ConfirmText = PresentationText;
		NewRow.PaymentDocument = PaymentDocumentData.Ref;
		NewRow.DocumentKind = PaymentDocumentData.DocumentKind;
		NewRow.Sum = PaymentDocumentData.Sum;
		NewRow.Currency = PaymentDocumentData.Currency;
		NewRow.Number = PaymentDocumentData.Number;
		NewRow.Date = PaymentDocumentData.Date;
		NewRow.LinkToPaymentConfirmation = 
			CurLineArrayOfPaymentConfirmationLinks.LinkToPaymentConfirmation; 
		NewRow.Service = CurLineArrayOfPaymentConfirmationLinks.FillParameters.Service;
		
	EndDo;	

	If PaymentTableForPaymentConfirmation.Count() > 0 Then
		CurrentData = PaymentTableForPaymentConfirmation[0];
		
		GenerateDisplayOfPaymentConfirmationTextOnServer(
						CurrentData.PaymentDocument,
						CurrentData.DocumentKind, 
						CurrentData.Number,
						CurrentData.Date,
						CurrentData.Sum,
						CurrentData.Currency,
						CurrentData.Service,
						CurrentData.LinkToPaymentConfirmation);
	EndIf;	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdatePaymentStatuses(Command)

	ExchangeWithBankFeedsServiceClient.CheckStatusOfPaymentsAfterSending(ThisObject);	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentTableForPaymentConfirmation

&AtClient
Procedure PaymentTableForPaymentConfirmationWhenFieldIsActivated(Item)
	
	CurrentData = Items.PaymentTableForPaymentConfirmation.CurrentData;
	
	If CurrentData <> Undefined Then
		
		GenerateDisplayOfPaymentConfirmationTextOnServer(
						CurrentData.PaymentDocument,
						CurrentData.DocumentKind, 
						CurrentData.Number,
						CurrentData.Date,
						CurrentData.Sum,
						CurrentData.Currency,
						CurrentData.Service,
						CurrentData.LinkToPaymentConfirmation);
						
	Else
		
		Items.PaymentConfirmationDecoration.Title = New FormattedString(
		    					NStr("vi = 'Đã gửi tất cả chứng từ thanh toán';
									|ru = 'Все платежные документы отправлены';
									|en = 'All payment documents are sent'; fa = 'All payment documents are sent';
									|it = 'Все платежные документы отправлены';
									|pl = 'All payment documents are sent';
									|tr = 'Tüm ödeme belgeleri gönderildi'"));
			
	EndIf;					
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FormControl()
	
	If PaymentTableForPaymentConfirmation.Count() = 1 Then
		Title = NStr("vi = 'Xác nhận thanh toán trong dịch vụ';
					|ru = 'Подтверждение платежа в сервисе';
					|en = 'Payment processing and confirmation'; fa = 'Payment processing and confirmation';
					|it = 'Подтверждение платежа в сервисе';
					|pl = 'Payment processing and confirmation';
					|tr = 'Hizmetteki ödemenin onayı'");
		
		Items.PaymentTableForPaymentConfirmation.Visible = False;
		
		Items.ConfirmationForm.ToolTip = NStr("vi = 'Sau khi xác nhận thanh toán, hãy đóng cửa sổ này';
												|ru = 'После подтверждения платежей, закройте это окно';
												|en = 'Close this window once payments are processed'; fa = 'پس از پردازش پرداخت‌ها این پنجره را ببندید';
												|it = 'После подтверждения платежей, закройте это окно';
												|pl = 'Close this window once payments are processed';
												|tr = 'Ödemelerin onayından sonra bu pencereyi kapatın'");
	EndIf;	
	
EndProcedure	

&AtClient
Procedure UpdatePaymentList() Export
	
	UpdateListOfPaymentsOnServer();
	
	If PaymentTableForPaymentConfirmation.Count() > 0 Then
		CurrentData = PaymentTableForPaymentConfirmation[0];
		
		GenerateDisplayOfPaymentConfirmationTextOnServer(
						CurrentData.PaymentDocument,
						CurrentData.DocumentKind, 
						CurrentData.Number,
						CurrentData.Date,
						CurrentData.Sum,
						CurrentData.Currency,
						CurrentData.Service,
						CurrentData.LinkToPaymentConfirmation);
	EndIf;	
	
EndProcedure	

&AtServer
Procedure UpdateListOfPaymentsOnServer()
	
	PaymentArray = New Array();
	For Each CurCurrentRowPaymentTableForPaymentConfirmation In PaymentTableForPaymentConfirmation Do
		
		PaymentArray.Add(CurCurrentRowPaymentTableForPaymentConfirmation.PaymentDocument);
		
	EndDo;	
	
	Query = New Query(); 
	Query.SetParameter("PaymentArray", PaymentArray);
	Query.Text = 
	"SELECT
	|	BankFeedsTransactionStatuses.Object AS PaymentDocument,
	|	BankFeedsTransactionStatuses.Status AS Status
	|FROM
	|	InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|WHERE
	|	BankFeedsTransactionStatuses.Object IN(&PaymentArray)";
	
	Result = Query.Execute().Select();
	PaymentFilter = New Structure("PaymentDocument");
	
	While Result.Next() Do
		
		If Result.Status = Enums.BankFeedsPaymentDocumentStatuses.NotShipped_5 Then
			Continue;
		EndIf;	
		
	    PaymentFilter.PaymentDocument = Result.PaymentDocument;
		
		FoundRows = PaymentTableForPaymentConfirmation.FindRows(PaymentFilter);
		
		If FoundRows.Count() > 0 Then
			
			PaymentTableForPaymentConfirmation.Delete(FoundRows[0]);				
	
		EndIf;	
		
	EndDo;
	
EndProcedure	
	
&AtServer
Procedure GenerateDisplayOfPaymentConfirmationTextOnServer(PaymentDocument,DocumentKind,Number,Date,Sum,Currency,Service,LinkToPaymentConfirmation)
	
	Items.PaymentConfirmationDecoration.Title = StringFunctions.FormattedString(
		NStr("vi = 'Theo yêu cầu của nhà cung cấp, <a href = ""%1"">%2 </a> %3 cần xác nhận trên trang web dịch vụ %4
				|Hãy chuyển đến <a href = ""%5"">Liên kết</a> và xác nhận thanh toán';
				|ru = 'Согласно требованиям провайдера, <a href = ""%1"">%2 </a> %3 необходимо подтвердить на сайте сервиса %4
				|Перейдите по <a href = ""%5"">Ссылке</a> и подтвердите платеж';
				|en = 'According to the provider requirements, <a href = ""%1"">%2 </a> %3 must be confirmed on the service website %4
				|Click the <a href = ""%5"">Link</a> and confirm the payment'; fa = 'According to the provider requirements, <a href = ""%1"">%2 </a> %3 must be confirmed on the service website %4
				|Click the <a href = ""%5"">Link</a> and confirm the payment';
				|it = 'Согласно требованиям провайдера, <a href = ""%1"">%2 </a> %3 необходимо подтвердить на сайте сервиса %4
				|Перейдите по <a href = ""%5"">Ссылке</a> и подтвердите платеж';
				|pl = 'According to the provider requirements, <a href = ""%1"">%2 </a> %3 must be confirmed on the service website %4
				|Click the <a href = ""%5"">Link</a> and confirm the payment';
				|tr = 'Sağlayıcının gereksinimlerine göre<a href = ""%1"">%2 </a> %3hizmetinin web sitesinde %4
				|onaylanmalıdır. <a href = ""%5"">Bağlantıya</a> gidin ve ödemeyi onaylayın'"),
		GetURL(PaymentDocument), DocumentKind + NStr("vi = ' Số';
													|ru = ' №';
													|en = ' No.'; fa = ' No.';
													|it = ' №';
													|pl = ' No.';
													|tr = ' №'") + ObjectsPrefixesClientServer.NumberForPrinting(Number) 
			+" dated: "+ Format(Date, "DF=dd.MM.yyyy; DLF=D"), 
			NStr("vi = 'với số tiền';
				|ru = 'на сумму';
				|en = 'in the amount of'; fa = 'به مبلغ';
				|it = 'на сумму';
				|pl = 'na kwotę';
				|tr = 'tutarında'") + " " + Sum + " "+ Currency, 
		Service,	LinkToPaymentConfirmation);
	
EndProcedure

#EndRegion
