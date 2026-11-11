#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	Cancel = True;
	ShowMessageBox(, NStr("vi = 'Biểu mẫu không được dùng để sử dụng trực tiếp.';
							|ru = 'Форма не предназначена для непосредственного использования.';
							|en = 'Form is not intended for direct usage.'; fa = 'Form is not intended for direct usage.';
							|it = 'Il modello non è destinato per l''uso diretto.';
							|pl = 'Formularz nie jest przeznaczony dla bezpośredniego użycia.';
							|tr = 'Form doğrudan kullanım için uygun değildir.'"));
EndProcedure

#EndRegion
