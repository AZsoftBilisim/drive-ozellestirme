#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Value Then
		Currency = Catalogs.Currencies.FindByCode("978");
		If ValueIsFilled(Currency) Then
			ProcessingOfExchangeRatesTM.CheckCorrectnessOfRelativeRateOn01_01_1980(Currency);
		Else
			ErrorText = NStr("vi = 'Không thể sử dụng tính năng này. Trong danh mục ""Tiền tệ"" không có Euro (EUR).';
							|ru = 'Включение функции невозможно. В справочнике ""Валюты"" отсутствует Евро (EUR).';
							|en = 'Cannot enable the function. There is no Euro (EUR) in the ""Currencies"" catalog.'; fa = 'Cannot enable the function. There is no Euro (EUR) in the ""Currencies"" catalog.';
							|it = 'Impossibile attivare la funzione. Nel catalogo ""Valute"" non è presente Euro (EUR).';
							|pl = 'Włączenie funkcji jest niemożliwe. W katalogu ""Waluty"" nie ma Euro (EUR).';
							|tr = 'Fonksiyon açılamıyor. ""Para birimleri"" kataloğunda Euro (EUR) yok.'");
			Common.MessageToUser(ErrorText,,,,Cancel);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf