
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData = Undefined Then
		FillingData = New Structure();
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		If Not FillingData.Property("ChartOfAccounts") Then
			FillingData.Insert("ChartOfAccounts", Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts());
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	MethodOfAccountingForImproperValues = Common.ObjectAttributeValue(CopiedObject.ChartOfAccounts,
		"MethodOfNotOwnedControlledValuesAccounting");
	
	If MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.RecordedOnOffBalanceAccounts Then
		OffBalance = False;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Order) Then
		Order = TrimAll(StrReplace(Code, ".", ""));
	EndIf;
	
	If Not ValueIsFilled(QuickSelectionCode) Then
		QuickSelectionCode = TrimAll(StrReplace(Code, ".", ""));
	EndIf;
	
	If Not Currency1 Then
		ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency = False;
	EndIf;
	
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf