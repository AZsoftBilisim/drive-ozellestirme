#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter = New Structure("Organization", CommandParameter);
	FormParameters = New Structure("Filter", Filter);
	OpenForm("InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.Form.ListForm",
				 FormParameters,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion