#Region FormEventHandlers

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_FinancialAccountingChartsOfAccountsForCompanies",  WriteParameters, ThisObject);
EndProcedure

#EndRegion