#Region FormCommandsEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	Cancel = True;
	ShowMessageBox(, NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
							|ru = 'Обработка не предназначена для непосредственного использования.';
							|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
							|it = 'L''elaborazione non è destinata all''uso diretto.';
							|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
							|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'"));
	
EndProcedure

#EndRegion