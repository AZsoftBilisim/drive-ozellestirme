
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("FinancialAccountingGroup", CommandParameter);
	OpenForm("InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting.Form.ConfigureAccountSpecification",
				 FormParameters,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion