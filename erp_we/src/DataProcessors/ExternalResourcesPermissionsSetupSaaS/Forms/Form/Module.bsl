#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Raise NStr("vi = 'Xử lý không dành cho sử dụng tương tác.';
				|ru = 'Обработка не предназначена для интерактивного использования';
				|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
				|it = 'L''elaborazione non è disponibile per l''utilizzo interattivo';
				|pl = 'Przetwarzanie nie jest przeznaczone dla stosowania interaktywnego';
				|tr = 'Veri işlemcisi etkileşimli kullanıma yönelik değil.'");
	
EndProcedure

#EndRegion