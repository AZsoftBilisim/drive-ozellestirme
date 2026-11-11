
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Counterparty, Title", CommandParameter, NStr("vi = 'Tín dụng và tiền gửi (deposit) của đối tác';
																				|ru = 'Кредиты и депозиты контрагента';
																				|en = 'Credits and deposits of counterparty'; fa = 'Credits and deposits of counterparty';
																				|it = 'Prestiti e depositi del contraente';
																				|pl = 'Kredyty i depozyty kontrahenta';
																				|tr = 'Cari hesabın kredi ve mevduatları'"));
	
	OpenForm("Catalog.LoanAndDepositContracts.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion