#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("ConstantIsCalculatedAfterLocking") Then
		
		Raise NStr("vi = 'Cần chú ý giá trị của hằng ""Sử dụng đặt trước mà không có đơn hàng"" sau khi thiết lập khóa đọc ghi';
					|ru = 'Значение константы ""Не использовать назначения без заказа"" должно вычисляться после установки исключительной блокировки';
					|en = 'Value of the ""Do not use assignments without order"" constant should be calculated after exclusive lock is set'; fa = 'Value of the ""Do not use assignments without order"" constant should be calculated after exclusive lock is set';
					|it = 'Il valore della costante ""Non utilizzare assegnazioni senza ordine"" deve essere calcolato dopo aver impostato blocco esclusivo';
					|pl = 'Wartość stałej ""Nie używaj przeznaczenia bez zamówienia"" należy obliczyć po ustawieniu wyłącznej blokady';
					|tr = '""Atamaları siparişsiz kullanma"" sabitinin değeri, özel bir kilit ayarlandıktan sonra değerlendirilmelidir'");
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
