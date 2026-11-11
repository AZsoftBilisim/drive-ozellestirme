#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	If Not FinancialAccountingOfGeneralPurpose.SettingUpTransactionsForAccountingObjectsOrLocalAccounting() Then
		MethodOfCancelingTransactions = Enums.MethodsOfCancelingPostingsInFinancialAccounting.ReverseByPostings;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
		StandardProcessing = False;
	EndIf;
	
	If Not ValueIsFilled(Owner) Then
		Owner = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	
	If Not ValueIsFilled(MethodOfCancelingTransactions) Then
		MethodOfCancelingTransactions = Enums.MethodsOfCancelingPostingsInFinancialAccounting.ReverseByPostings;
	EndIf;
	
	If Not ValueIsFilled(ClosingOfIncomeAndExpenseAccounts) Then
		ClosingOfIncomeAndExpenseAccounts = Enums.ClosingOfIncomeAndExpenseAccounts.Monthly;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

#EndRegion

#EndIf