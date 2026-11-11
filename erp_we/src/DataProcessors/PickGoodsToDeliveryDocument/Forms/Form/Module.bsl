// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Raise NStr("ru = 'Обработка не предназначена для непосредственного использования.';
				|vi = 'The data processor cannot be opened manually.';
				|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
				|it = 'L''elaborazione non è destinata all''uso diretto.';
				|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
				|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
		
EndProcedure

#EndRegion