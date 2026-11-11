#Region Private

// Displays the corresponding notification.
//
Procedure NotifyRatesAreUpdated() Export
	
	ShowUserNotification(
		NStr("vi = 'Đã cập nhật thành công tỷ giá hối đoái';
			|ru = 'Курсы валют успешно обновлены';
			|en = 'Exchange rates are updated'; fa = 'Exchange rates are updated';
			|it = 'Tassi di cambio aggiornati con successo';
			|pl = 'Kursy walut pomyślnie zaktualizowane';
			|tr = 'Döviz kurları güncellendi'"),
		,
		NStr("vi = 'Đã cập nhật tỷ giá hối đoái';
			|ru = 'Курсы валют обновлены';
			|en = 'The exchange rates are updated.'; fa = 'The exchange rates are updated.';
			|it = 'Tassi di cambio aggiornati';
			|pl = 'Kursy walut zaktualizowane';
			|tr = 'Döviz kurları güncellendi'"),
		PictureLib.Information32);
	
EndProcedure

// Displays the corresponding notification.
//
Procedure NotifyRatesUpToDate() Export
	
	ShowMessageBox(,NStr("vi = 'Đã cập nhật tỷ giá hối đoái.';
						|ru = 'Курсы валют актуальны.';
						|en = 'The exchange rates are up-to-date.'; fa = 'The exchange rates are up-to-date.';
						|it = 'I tassi di cambio sono attuali.';
						|pl = 'Kursy walut aktualne.';
						|tr = 'Döviz kurları güncel.'"));
	
EndProcedure

#EndRegion