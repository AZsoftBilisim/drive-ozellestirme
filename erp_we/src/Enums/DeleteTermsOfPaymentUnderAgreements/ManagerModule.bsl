#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function defines the default payment order.
//
// Parameters:
//  Currency             - CatalogRef.Currencies - The currency of the agreement
//  VATTaxation - EnumRef.VATTaxationTypes - Optional, type of VAT taxation of the document
//  CurrencyOfPayment       - CatalogRef.Currencies - Optional, the currency of the intended payment.
//
// Returns:
//  EnumRef.DeleteTermsOfPaymentUnderAgreements - the default payment order.
//
Function GetDefaultPaymentOrder(Currency, VATTaxation = Undefined, Val CurrencyOfPayment = Undefined) Export
	
	LocalAccountingCurrency = Constants.DefaultBaseCurrency.Get();
	If Not ValueIsFilled(CurrencyOfPayment) Then
		CurrencyOfPayment = LocalAccountingCurrency;
	EndIf;
	
	If Currency = LocalAccountingCurrency Then
		If VATTaxation = Enums.VATTaxationTypes.ExportSale
			Or Not CurrencyOfPayment = LocalAccountingCurrency Then
			PaymentProcedure = Enums.DeleteTermsOfPaymentUnderAgreements.ARAPInRublesPaymentInCurrency;
		Else
			PaymentProcedure = Enums.DeleteTermsOfPaymentUnderAgreements.ARAPInRublesPaymentInRubles;
		EndIf;
	Else
		If VATTaxation = Enums.VATTaxationTypes.ExportSale 
			Or Not CurrencyOfPayment = LocalAccountingCurrency Then
			PaymentProcedure = Enums.DeleteTermsOfPaymentUnderAgreements.ARAPInCurrencyPaymentInCurrency;
		Else
			PaymentProcedure = Enums.DeleteTermsOfPaymentUnderAgreements.ARAPInCurrencyPaymentInRubles;
		EndIf;
	EndIf;
	
	Return PaymentProcedure;

EndFunction // Get an order of payment for Silence()

// Fills in possible payment orders
//
// Parameters:
//  SettlementsCurrency - CatalogRef.Currencies - Settlement currency.
//  FormItem   - FormField - field on the form to fill in the selection list.
//  PaymentProcedure  - EnumRef.DeleteTermsOfPaymentUnderAgreements - the current payment procedure.
//
Procedure FillInPossiblePaymentOrders(SettlementsCurrency, FormItem, PaymentProcedure) Export
	
	ComplCurrency = Constants.DefaultBaseCurrency.Get();
	
	List = FormItem.ChoiceList;
	List.Clear();
	
	TextInRubles = NStr("vi = 'Thanh toán bằng đồng';
						|ru = 'Оплата в рублях';
						|en = 'Payment in rubles'; fa = 'Payment in rubles';
						|it = 'Pagamento in rubli';
						|pl = 'Płatność w złotówkach';
						|tr = 'Ruble cinsinden ödeme'");
	TextInCurrency = NStr("vi = 'Thanh toán bằng ngoại tệ';
							|ru = 'Оплата в валюте';
							|en = 'Payment in currency'; fa = 'پرداخت ارزی';
							|it = 'Pagamento in valuta';
							|pl = 'Płatność w walucie';
							|tr = 'Para birimindeki ödeme'");
	
	If SettlementsCurrency = ComplCurrency Then
		List.Add(ARAPInRublesPaymentInRubles, TextInRubles);
		List.Add(ARAPInRublesPaymentInCurrency, TextInCurrency);
	ElsIf ValueIsFilled(SettlementsCurrency) Then
		List.Add(ARAPInCurrencyPaymentInRubles, TextInRubles);
		List.Add(ARAPInCurrencyPaymentInCurrency, TextInCurrency);
	EndIf;
	
	If ValueIsFilled(PaymentProcedure) And List.FindByValue(PaymentProcedure) = Undefined Then
	
		List.Add(PaymentProcedure);
	
	EndIf; 
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	
	StandardProcessing = False;
	ChoiceData = New ValueList();
	For Each CurItem In Enums.DeleteTermsOfPaymentUnderAgreements Do
		
		If CurItem <> Enums.DeleteTermsOfPaymentUnderAgreements.ARAPInRublesPaymentInRubles
			And Not UseMultipleCurrencies Then
			Continue;
		EndIf;

		ChoiceData.Add(CurItem);
		
	EndDo;
	
EndProcedure

#EndRegion
