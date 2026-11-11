#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AccountNumber = Upper(StrReplace(StrReplace(TrimAll(AccountNumber), " ", ""), ".", ""));
	
	CounterpartyBankAccountsLocalization.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	AccountNumber = "";
	DigitalRoubleAccountID = "";
	Description = "";
	
	CounterpartyBankAccountsLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("CashCurrency") Then
		SpecifiedCurrency = True;
	Else
		SpecifiedCurrency = False;
	EndIf;
	
	If Not SpecifiedCurrency And Not ValueIsFilled(CashCurrency) Then
		CashCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Bank") Then
		Bank = FillingData.Bank;
	EndIf;
	
	CounterpartyBankAccountsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	If Not DigitalRoubleAccount Then
		AttributesNotToCheck.Add("DigitalRoubleAccountID");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	CounterpartyBankAccountsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

#EndRegion

#EndIf