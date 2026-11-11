&AtServer
Function CheckWhetherInvoicesCanBeCreated(Contract)
	
	ARAPObjectSettings = Common.ObjectAttributeValue(Contract, "ARAPObjectSettings");
	Return ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts;
	
EndFunction

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not CheckWhetherInvoicesCanBeCreated(CommandParameter) Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhập hóa đơn để thanh toán trên cơ sở hợp đồng %1 chỉ có thể với các chi tiết của các khu Thanh toán theo hợp đồng.';
				|ru = 'Ввод счета на оплату на основании договора %1 возможен только при детализации расчетов ""По договорам"".';
				|en = 'Enter of commercial invoice on the basis of the contract %1 can be added only if ""Under contracts"" is chosen.'; fa = 'Enter of commercial invoice on the basis of the contract %1 can be added only if ""Under contracts"" is chosen.';
				|it = 'L''inserimento della fattura proforma sulla base del contratto %1 è possibile solo con impostazione di calcoli con specifica ""Per contratti"".';
				|pl = 'Wprowadzanie rachunku na płatność na podstawie kontraktu %1 jest możliwe tylko ze szczegółowymi obliczeniami ""Według kontraktów"".';
				|tr = '%1 sözleşmesi temelinde ticari fatura girilmesi, yalnızca ""Sözleşmelere göre"" ödemeler detaylandırılırken mümkündür.'"),
			CommandParameter);
		Raise Text;
	EndIf;
	
	FormParameters = New Structure("DocumentBasis", CommandParameter);
	
	OpenForm(
		"Document.CustomerCommercialInvoice.Form.CommercialInvoiceCreationForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
