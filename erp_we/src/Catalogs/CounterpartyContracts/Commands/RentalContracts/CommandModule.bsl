#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	HeaderTextParameter = NStr("vi = 'Hợp đồng chuyển cho thuê';
								|ru = 'Договоры передачи в аренду';
								|en = 'Rental contracts'; fa = 'قراردادهای اجاره';
								|it = 'Договоры передачи в аренду';
								|pl = 'Rental contracts';
								|tr = 'Kira devir sözleşmeleri'");
	TypesOfTransferContractsForLease = LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts();
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("ContractType", TypesOfTransferContractsForLease));
	FormParameters.Insert("Title", HeaderTextParameter);
	
	OpenForm("Catalog.CounterpartyContracts.ListForm",
				 FormParameters,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);

EndProcedure

#EndRegion