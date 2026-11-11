
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
				|ru = 'Обработка не предназначена для непосредственного использования.';
				|en = 'This data processor is not intended for manual use.'; fa = 'This data processor is not intended for manual use.';
				|it = 'L''elaborazione non è destinata all''uso diretto.';
				|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
				|tr = 'Veri işlemcisi, doğrudan kullanıma yönelik değildir.'");
	
EndProcedure

#EndRegion