////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions for processing user actions
// in the process of working with prices.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines whether version 2.5 pricing is used on the specified date.
//
// Parameters:
//	Date - Date - the date to set the pricing mode for.
//
// Returns:
//	Boolean - indicates that version 2.5 pricing is being used as of the specified date
//	if no date is specified, then it is equated to the Cur current one.
Function UsePriceManagementSystem25(Date = Undefined) Export

	Return PriceManagementSystemServerCall.UsePriceManagementSystem25(Date);

EndFunction

// Determines whether the price needs to be recalculated when the batch or package changes.
// 
// Parameters:
//  Products - CatalogRef.Products - verification nomenclature
//  AttributeName - String - "Series" or "Packaging". the name of the changed props
//  Date - Undefined, Date - Date of verification
// 
// Returns:
//  Boolean - True, It is necessary to recalculate the prices
Function ItIsNecessaryToRecalculatePriceWhenChanging(Products, AttributeName, Date = Undefined) Export

	If Products.IsEmpty() Then
		Return False;
	EndIf;
	
	Result = PriceManagementSystemServerCall.ItIsNecessaryToRecalculatePriceWhenChanging(Products, AttributeName, Date);
	
	Return Result;
	
EndFunction

#Region ProceduresAndFunctionsForCheckingAbilityToPerformActions

// Checks whether the Bank details required for conversion from currency to currency are filled in.
//
// Parameters:
//  Document	 - DocumentObject			 - The document that checks are performed for.
//  OldCurrency - CatalogRef.Currencies	 - The previous currency of the document.
//  TSName		 - String					 - name of the table part.
//  NameOfPriceField	 - String					 - Name of the field containing the amount that depends on the currency.
// 
// Returns:
//  Boolean - True if currency conversion is required.
//
Function CurrencyConversionRequired(Document, OldCurrency, TSName="Goods", NameOfPriceField = "Price") Export

	If Not ValueIsFilled(Document.Currency) Then
		Document.Currency = OldCurrency;
		Return False;
	ElsIf Not ValueIsFilled(OldCurrency) Then
		Return False;
	ElsIf OldCurrency = Document.Currency Then
		Return False;
	ElsIf Document[TSName].Total(NameOfPriceField) = 0 Then
		Return False;
	EndIf;
	
	Return True;

EndFunction

// Checks whether the details required for recalculation of settlement amounts are filled in
//
// Parameters:
// 		Document 		- DocumentObject 			- Document object for which checks are performed
// 		OldCurrency 	- CatalogRef.Currencies	- The previous currency of mutual settlements
// 		TSName 			- String 					- name of the table part.
//
// Returns:
// 		Boolean - It is false if you need to recalculate the amounts of mutual settlements.
//
Function ItIsNecessaryToRecalculateAmountOfSettlements(Document, OldCurrency, TSName="Goods") Export

	If Not ValueIsFilled(Document.ARAPCurrency) Then
		Document.ARAPCurrency = OldCurrency;
		Return False;
	ElsIf Not ValueIsFilled(OldCurrency) Then
		Return True;
	ElsIf OldCurrency = Document.ARAPCurrency Then
		Return False;
	ElsIf Document[TSName].Total("AmountARAP") = 0 Then
		Return False;
	EndIf;
	
	Return True;

EndFunction

#EndRegion

#Region ProceduresForNotifyingUserOfCompletedActions

// Displays a notification to the user about the end of converting amounts from currency to currency.
//
// Parameters:
// CurrencySource - CatalogRef.Currencies - the currency from which the conversion was carried out
// CurrencyReceiver - CatalogRef.Currencies - currency to be converted to.
//
Procedure NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrencySource, CurrencyReceiver) Export

	MessageString = NStr("vi = 'Số tiền trong chứng từ được tính lại từ tiền tệ %CurrencySource% sang tiền tệ %CurrencyReceiver%';
						|ru = 'Суммы в документе пересчитаны из валюты %CurrencySource% в валюту %CurrencyReceiver%';
						|en = 'Amounts in the document are converted from currency %CurrencySource% to currency %CurrencyReceiver%'; fa = 'Amounts in the document are converted from currency %CurrencySource% to currency %CurrencyReceiver%';
						|it = 'Gli importi nel documento sono ricalcolati dalla valuta %CurrencySource% nella valuta %CurrencyReceiver%';
						|pl = 'Kwoty w dokumencie przeliczone z waluty %CurrencySource% na walutę %CurrencyReceiver%';
						|tr = 'Belgedeki tutarlar %CurrencySource% para biriminden %CurrencyReceiver% para birimine yeniden hesaplandı'");
	MessageString = StrReplace(MessageString, "%CurrencySource%", CurrencySource);
	MessageString = StrReplace(MessageString, "%CurrencyReceiver%", CurrencyReceiver);
	
	ShowUserNotification(
		NStr("vi = 'Số tiền tính lại';
			|ru = 'Суммы пересчитаны';
			|en = 'Amounts are recalculated'; fa = 'Amounts are recalculated';
			|it = 'Importi ricalcolati';
			|pl = 'Wartości zostały przeliczone';
			|tr = 'Tutarlar yeniden hesaplandı'"),
		,
		MessageString,
		PictureLib.Information32);

EndProcedure

#EndRegion

#EndRegion
