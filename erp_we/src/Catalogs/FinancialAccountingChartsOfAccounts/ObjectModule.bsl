#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	If Not FinancialAccountingOfGeneralPurpose.SettingUpTransactionsForAccountingObjectsOrLocalAccounting() Then
		MethodOfNotOwnedControlledValuesAccounting = Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If Not ValueIsFilled(MethodOfNotOwnedControlledValuesAccounting) Then
		MethodOfNotOwnedControlledValuesAccounting = Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts;
	EndIf;
	
	If Not ValueIsFilled(AccountsPresentation) Then
		AccountsPresentation = Enums.PresentationOfFinancialAccountingAccounts.AsCodeAndName;
	EndIf;
	
EndProcedure
	
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TransactionsWithoutCorrespondence = OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence;
	TransactionsWithCorrespondence = OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence;
	
EndProcedure

#EndRegion

#EndIf
