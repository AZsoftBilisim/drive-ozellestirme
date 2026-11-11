
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	If ThisIsTradeManagement() Then
		ReportsOptionsClient.ShowReportBar("Planning", CommandExecuteParameters);
	Else
		ReportsOptionsClient.ShowReportBar("BudgetingAndPlanning", CommandExecuteParameters);
	EndIf;
EndProcedure

&AtServer 
Function ThisIsTradeManagement()
	Return GetFunctionalOption("TradeManagement");
EndFunction
