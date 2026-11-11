
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	HeaderTextParameter = NStr("vi = 'Hợp đồng với đối tác';
								|ru = 'Договоры с контрагентом';
								|en = 'Contracts'; fa = 'قراردادها';
								|it = 'Accordi con la controparte';
								|pl = 'Umowy z kontrahentem';
								|tr = 'Cari hesap sözleşmeleri'");
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("Counterparty", CommandParameter));
	FormParameters.Insert("Title", HeaderTextParameter);
	
	OpenForm("Catalog.CounterpartyContracts.ListForm",
				 FormParameters,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
	
EndProcedure
