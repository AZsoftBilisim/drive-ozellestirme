
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter = New Structure("Owner", CommandParameter);
	FormParameters = New Structure("Filter", Filter);
	OpenForm("Catalog.OptionsOfLoansAndDepositsSchedules.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion