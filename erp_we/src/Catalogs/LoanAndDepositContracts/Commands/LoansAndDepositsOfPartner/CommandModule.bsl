
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Partner, Title", CommandParameter, NStr("vi = 'Tín dụng và tiền gửi (deposit) của bạn hàng';
																			|ru = 'Кредиты и депозиты партнера';
																			|en = 'Credits and deposits of partner'; fa = 'Credits and deposits of partner';
																			|it = 'Prestiti e depositi del partner';
																			|pl = 'Kredyty i depozyty partnera';
																			|tr = 'İş ortağı kredi ve mevduatları'"));
	
	OpenForm("Catalog.LoanAndDepositContracts.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion