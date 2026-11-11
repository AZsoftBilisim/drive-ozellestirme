
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not AdditionalProperties.Property("ConstantIsCalculatedAfterLocking") Then
		
		Raise NStr("vi = 'Giá trị hằng ""Sử dụng quản lý điều chuyển hàng hóa đặt riêng"" phải được tính sau khi đặt phong tỏa riêng';
					|ru = 'Значение константы ""Использовать управление перемещением обособленных товаров"" должно вычисляться после установки исключительной блокировки';
					|en = 'Value of the ""Use management of assigned goods transfer"" constant should be calculated after exclusive lock is set'; fa = 'Value of the ""Use management of assigned goods transfer"" constant should be calculated after exclusive lock is set';
					|it = 'Il valore della costante ""Utilizzare la gestione della movimentazione delle merci separate"" deve essere calcolato dopo aver impostato un blocco eccezionale';
					|pl = 'Wartość stałej ""Używaj zarządzania przemieszczeniem oddzielnych towarów"" należy obliczyć po ustawieniu wyłącznej blokady';
					|tr = '""Ayrıştırılmış ürünlerin transfer yönetimini kullan"" sabitinin değeri, özel kilitleme ayarlandıktan sonra hesaplanmalıdır'");
		
	EndIf;
	
EndProcedure

#EndIf
