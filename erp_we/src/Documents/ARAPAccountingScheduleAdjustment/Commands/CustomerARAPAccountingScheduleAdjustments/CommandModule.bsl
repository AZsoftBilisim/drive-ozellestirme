#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure();
	ListBT = New ValueList;
	ListBT.Add(PredefinedValue("Enum.BusinessTransactions.AdjustCustomerPaymentSchedule"));
	ListBT.Add(PredefinedValue("Enum.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule"));
	Filter = New Structure("BusinessOperation", ListBT);
	FormParameters.Insert("Filter", Filter);
	OpenForm("Document.ARAPAccountingScheduleAdjustment.Form.CustomerListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion //EventHandlers