#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	DefaultChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	If ValueIsFilled(DefaultChartOfAccounts) Then
		NewTableRow = ChartsOfAccounts.Add();
		NewTableRow.ChartOfAccounts = DefaultChartOfAccounts;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
