
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Partner, Title", CommandParameter, NStr("vi = 'Hợp đồng với bạn hàng';
																			|ru = 'Договоры с партнером';
																			|en = 'Contracts with partner'; fa = 'Contracts with partner';
																			|it = 'Accordi con il partner';
																			|pl = 'Umowy z partnerem';
																			|tr = 'İş ortağıyla yapılan sözleşmeler'"));
	
	OpenForm("Catalog.CounterpartyContracts.ListForm",
				 FormParameters,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
	
EndProcedure
