&AtServer
Function CheckWhetherInvoicesCanBeCreated(Contract)
	
	ARAPObjectSettings = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings");
	Return ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice;
	
EndFunction

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not CheckWhetherInvoicesCanBeCreated(CommandParameter) Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập hóa đơn thanh toán trên cơ sở hợp đồng %1. Việc hạch toán được thực hiện theo đơn hàng / hóa đơn.';
				|ru = 'Не требуется вводить счет на оплату на основании договора %1. Расчеты ведутся по заказам / накладным.';
				|en = 'It is not required to enter a commercial invoice based on document %1. Settlements are made based on orders / invoices.'; fa = 'It is not required to enter a commercial invoice based on document %1. Settlements are made based on orders / invoices.';
				|it = 'Non è necessario inserire la fattura di pagamento in base al contratto. %1 I regolamenti si effettuano in base agli ordini / bolle.';
				|pl = 'Nie jest wymagane wprowadzanie rachunku do zapłaty na podstawie umowy %1. Rozliczenia są wykonywane na podstawie zamówień / listów przewozowych.';
				|tr = 'Ticari faturanın sözleşme esasında girilmesine gerek yoktur %1. Ödemeler sipariş / irsaliyelere göre yapılmakta.'"),
			CommandParameter);
		Raise Text;
	EndIf;
	
	FormParameters = New Structure("Basis", CommandParameter);
	
	OpenForm(
		"Document.CustomerCommercialInvoice.Form.DocumentForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
