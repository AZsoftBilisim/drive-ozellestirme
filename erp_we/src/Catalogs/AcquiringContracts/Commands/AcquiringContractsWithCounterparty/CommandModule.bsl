
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure("Counterparty", CommandParameter);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("Title", NStr("vi = 'Hợp đồng với đối tác';
										|ru = 'Договоры с контрагентом';
										|en = 'Contracts'; fa = 'قراردادها';
										|it = 'Accordi con la controparte';
										|pl = 'Umowy z kontrahentem';
										|tr = 'Cari hesap sözleşmeleri'"));
	
	OpenForm("Catalog.AcquiringContracts.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
