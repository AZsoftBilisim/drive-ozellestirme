#Region Private

// Returns a string Presentation of the Status.
//
// Returns:
//   String
//
Function StatusDoubleReplace() Export
	Return NStr("ru = 'Дубль, заменить ссылки и удалить';
				|vi = 'Duplicate, replace links and delete';
				|en = 'Duplicate, replace links and delete'; fa = 'تکراری، جایگزینی پیوندها و حذف';
				|it = 'Duplicate, replace links and delete';
				|pl = 'Duplicate, replace links and delete';
				|tr = 'Yinelenen öğe, bağlantıları değiştir ve sil'");
EndFunction

// Returns a string Presentation of the Status.
//
// Returns:
//   String
//
Function DoNotDeleteDoubleStatus() Export
	Return NStr("ru = 'Дубль, не удалять';
				|vi = 'Duplicate, do not delete';
				|en = 'Duplicate, do not delete'; fa = 'تکراری، حذف نشود';
				|it = 'Duplicate, do not delete';
				|pl = 'Duplicate, do not delete';
				|tr = 'Yinelenen öğe, silme'");
EndFunction

// Returns a string Presentation of the Status.
//
// Returns:
//   String
//
Function StatusConfirmationRequired() Export
	Return NStr("ru = 'Требуется подтверждение';
				|vi = 'Confirmation is required';
				|en = 'Confirmation is required'; fa = 'تأیید الزامی است';
				|it = 'Conferma richiesta';
				|pl = 'Wymagane jest potwierdzenie';
				|tr = 'Onaylama gerekli'");
EndFunction

// Returns a string Presentation of the Status.
//
// Returns:
//   String
//
Function StatusOriginal() Export
	Return NStr("ru = 'Оригинал';
				|vi = 'Original';
				|en = 'Original'; fa = 'اصل';
				|it = 'Original';
				|pl = 'Original';
				|tr = 'Orijinal'");
EndFunction

// Returns a string Presentation of the Status.
//
// Returns:
//   String
//
Function StatusIsNotDouble() Export
	Return NStr("ru = 'Не является дублем';
				|vi = 'Not duplicate';
				|en = 'Not duplicate'; fa = 'تکراری نیست';
				|it = 'Not duplicate';
				|pl = 'Not duplicate';
				|tr = 'Yinelenen öğe değil'");
EndFunction

Procedure SetStateOfReportField(ReportField, Visible) Export
	
	StatePresentation = ReportField.StatePresentation;
	
	If Visible Then
		StatePresentation.Text = NStr("ru = 'Изменились настройки. Нажмите ""Сформировать"" для получения отчета.';
										|vi = 'Settings changed. To run the report, click ""Generate"".';
										|en = 'Settings changed. To run the report, click ""Generate"".'; fa = 'Settings changed. To run the report, click ""Generate"".';
										|it = 'Impostazioni modificate. Fate clic su ""Genera"" per generare un report.';
										|pl = 'Zmieniono ustawienia. Kliknij ""Utwórz"", aby wygenerować raport.';
										|tr = 'Ayarlar değiştirildi. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'");
		StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Else
		StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	EndIf;
	StatePresentation.Visible = Visible;
	
EndProcedure

#EndRegion