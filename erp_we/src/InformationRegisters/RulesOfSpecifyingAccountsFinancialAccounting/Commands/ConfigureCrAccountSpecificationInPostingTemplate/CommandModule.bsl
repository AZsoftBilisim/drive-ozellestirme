
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure();
	FormParameters.Insert("PostingTemplate", CommandParameter);
	FormParameters.Insert("RecordType", PredefinedValue("Enum.AccountingMovementKinds.Credit"));
	
	OpenForm("InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting.Form.ConfigureAccountSpecificationInPostingTemplate",
				 FormParameters,
				 CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion