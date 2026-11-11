#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteOperationCompletion(ExecutionResult, Var_Parameters) Export
	
	Enabled = True;
	
	If ExecutionResult.Result Then
		MessageText = NStr("vi = 'Đã thực hiện giao dịch thành công.';
							|ru = 'Операция выполнена успешно.';
							|en = 'Operation has been successfully installed.'; fa = 'Operation has been successfully installed.';
							|it = 'Operazione completata con successo.';
							|pl = 'Operacja została wykonana pomyślnie.';
							|tr = 'İşlem başarıyla tamamlandı.'");
	Else
		MessageText = ExecutionResult.ErrorDescription;
	EndIf;
	
	CommonCELClient.MessageToUser(MessageText);
	
EndProcedure

&AtClient
Procedure PerformPaymentCardOperation(TransactionType)
	
	ClearMessages();
	OperationParametersList = New Structure();
	OperationParametersList.Insert("TransactionType"               , TransactionType);
	OperationParametersList.Insert("SpecifyAdditionalData" , True);
	OperationParametersList.Insert("NoAmountEditingAllowed"   , False);
	
	CallbackDescription = New CallbackDescription("PerformPaymentCardOperationCompletion", ThisObject, OperationParametersList);
	OpenForm("Catalog.Peripherals.Form.POSTerminalAuthorizationForm", OperationParametersList,,,  ,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PerformPaymentCardOperationCompletion(Result, Var_Parameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Not Var_Parameters.Property("TransactionType") Then
			MessageText = NStr("vi = 'Chưa chỉ định kiểu giao tác.';
								|ru = 'Не указан тип транзакции.';
								|en = 'Transaction type is not specified.'; fa = 'Transaction type is not specified.';
								|it = 'Tipo di transazione non indicato.';
								|pl = 'Nie wskazano typu transakcji.';
								|tr = 'İşlem türü belirtilmemiş.'");
			CommonCELClient.MessageToUser(MessageText);
			Return;
		EndIf;
		
		Enabled = False;
		OperationParametersList = PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation();
		OperationParametersList.TransactionType  = Var_Parameters.TransactionType;
		OperationParametersList.TransactionAmount  = Result.Sum;
		OperationParametersList.ReceiptNumber      = ?(Result.Property("ReceiptNumber")  , Result.ReceiptNumber, "");
		OperationParametersList.POSTerminalReceiptNumber    = ?(Result.Property("POSTerminalReceiptNumber"), Result.POSTerminalReceiptNumber, "");

		OperationParametersList.ReferenceNumber = Result.ReferenceNumber;
		
		Notification = New CallbackDescription("ExecuteOperationCompletion", ThisObject);
		PeripheralsPaymentSystemsServerClient.StartOperationOnAcquiringTerminal(Notification, UUID, Undefined, OperationParametersList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PayByPaymentCard(Command)
	
	PerformPaymentCardOperation("AuthorizeSales");
	
EndProcedure

&AtClient
Procedure PaymentReturnByCard(Command)
	
	PerformPaymentCardOperation("AuthorizeRefund");
	
EndProcedure

&AtClient
Procedure CancelPaymentByCard(Command)
	
	PerformPaymentCardOperation("AuthorizeVoid");
	
EndProcedure

&AtClient
Procedure RunPreauthorization(Command)
	
	PerformPaymentCardOperation("AuthorizePreSales");
	
EndProcedure

&AtClient
Procedure AuthConfirmation(Command)
	
	PerformPaymentCardOperation("AuthorizeCompletion");
	
EndProcedure

&AtClient
Procedure CancelAuthorisation(Command)
	
	PerformPaymentCardOperation("AuthorizeVoidPreSales");
	
EndProcedure

&AtClient
Procedure RunTotalsRevision(Command)
	
	ClearMessages();
	Enabled = False;
	
	CallbackDescription = New CallbackDescription("ExecuteOperationCompletion", ThisObject);
	PeripheralsPaymentSystemsServerClient.StartReconciliationOfTotalsAtAcquiringTerminal(CallbackDescription, UUID)
	
EndProcedure

&AtClient
Procedure PrintTheLastSalesSlip(Command)
	
	ClearMessages();
	LastSlipCheck = PeripheralsPaymentSystemsServerClient.LastSlipCheck();
	If Not IsBlankString(LastSlipCheck) Then
		Enabled = False;
		OperationParametersList = New Structure("LinesOfText", LastSlipCheck);
		Notification = New CallbackDescription("ExecuteOperationCompletion", ThisObject);
		PeripheralsReceiptPrintersClient.Start_PrintingText(Notification, UUID, Undefined, OperationParametersList);
	Else
		MessageText = NStr("vi = 'Không có phiếu cuối.';
							|ru = 'Отсутствует последний слип чек.';
							|en = 'There is no last sales slip.'; fa = 'There is no last sales slip.';
							|it = 'Ultimo scontrino fiscale mancante.';
							|pl = 'Brak ostatniego paragonu karty płatniczej.';
							|tr = 'Son slip fişi yok.'");
		CommonCELClient.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

#EndRegion