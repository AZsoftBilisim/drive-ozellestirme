#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers
	
Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	ChartOfAccountsObject = Catalogs.FinancialAccountingChartsOfAccounts.International.GetObject();
	If Not ValueIsFilled(ChartOfAccountsObject.PresentationCurrency) Then
		ChartOfAccountsObject.PresentationCurrency = ThisObject.Value;
		ChartOfAccountsObject.Write();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
