#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If TypeOf(FillingData) = Type("Structure")  Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	If Not IsFolder And Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
EndProcedure

#EndRegion

#EndIf