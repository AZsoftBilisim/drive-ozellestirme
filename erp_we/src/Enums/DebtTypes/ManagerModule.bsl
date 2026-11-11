
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a synonym for the counterparty by debt type.
// 
// Parameters:
//   DebtType - EnumRef.DebtTypes - Type of debt.
//
// Returns:
//	String - Synonym of the counterparty.
//
Function SynonymOfCounterparty(DebtType) Export
	
	If DebtType=Enums.DebtTypes.AccountsReceivableType Then
		SynonymText = NStr("vi = 'Người vay nợ';
							|ru = 'Дебитор';
							|en = 'Debtor'; fa = 'بدهکار';
							|it = 'Debitore';
							|pl = 'Dłużnik';
							|tr = 'Borçlu'");
	ElsIf DebtType=Enums.DebtTypes.AccountsPayableType Then
		SynonymText = NStr("vi = 'Người cho vay';
							|ru = 'Кредитор';
							|en = 'Creditor'; fa = 'بستانکار';
							|it = 'Creditore';
							|pl = 'Wierzyciel';
							|tr = 'Alacaklı'");
	Else
		SynonymText = NStr("vi = 'Đối tác';
							|ru = 'Контрагент';
							|en = 'Counterparty'; fa = 'طرف حساب';
							|it = 'Controparte';
							|pl = 'Kontrahent';
							|tr = 'Cari hesap'");
	EndIf;
	
	Return SynonymText;
	
EndFunction

#EndRegion

#EndIf