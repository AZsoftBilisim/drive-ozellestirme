#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	Cancel = True;
	ShowMessageBox(, NStr("vi = 'Bộ xử lý không thể dùng trực tiếp';
							|ru = 'Обработка не предназначена для непосредственного использования.';
							|en = 'This data processor is not intended for manual use.'; fa = 'This data processor is not intended for manual use.';
							|it = 'L''elaborazione non è destinata all''uso diretto.';
							|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
							|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'"));
EndProcedure

#EndRegion