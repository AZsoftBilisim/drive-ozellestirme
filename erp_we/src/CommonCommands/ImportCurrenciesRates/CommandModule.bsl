///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	CallbackDescription = New CallbackDescription("ImportCurrencyRatesClient", ThisObject);
	ShowQueryBox(CallbackDescription, 
		NStr("vi = 'Một tệp có thông tin đầy đủ về tỷ giá của tất cả các đơn vị tiền tệ cho mọi thời điểm sẽ được tải xuống từ trình quản lý dịch vụ.
              |Tỷ giá của các đơn vị tiền tệ được đánh dấu trong vùng dữ liệu để tải xuống từ Internet sẽ được thay thế trong nhiệm vụ nền. Tiếp tục?';
              |ru = 'Будет произведена загрузка файла с полной информацией по курсами всех валют за все время из менеджера сервиса.
              |Курсы валют, помеченных в областях данных для загрузки из сети Интернет, будут заменены в фоновом задании. Продолжить?';
              |en = 'You are about to import a file with full exchange rates data for all the periods from the service manager.
              |The exchange rates that are marked to be imported from the Internet in specific data areas will be replaced in a background job. Do you want to continue?'; fa = 'You are about to import a file with full exchange rates data for all the periods from the service manager.
              |The exchange rates that are marked to be imported from the Internet in specific data areas will be replaced in a background job. Do you want to continue?';
              |it = 'Il file verrà scaricato con le informazioni complete sui tassi di cambio di tutte le valute per tutto il tempo dal gestore del servizio.
              | I tassi di cambio nelle aree dati per il download da Internet verranno sostituite nell''attività in background. Continuare?';
              |pl = 'Zostanie przeprowadzone pobieranie pliku z pełną informacją o kursach wszystkich walut za cały okres z menedżera serwisu.
              |Kursy walut, zaznaczonych w obszarach danych do pobierania z Internetu zostaną zamienione w zadaniu w tle. Kontynuować?';
              |tr = 'Dosyalar, tüm dönem için tüm döviz kurlarına ilişkin tam verilerle servis yöneticisinden alınır. 
              |İnternet''ten içe aktarılacak veri alanlarında işaretlenen döviz kurları arka plan görevinde değiştirilecektir. Devam edilsin mi?'"), 
		QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportCurrencyRatesClient(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ImportCurrencyRates();
	
	ShowUserNotification(
		NStr("vi = 'Đã dự kiến kết nhập.';
			|ru = 'Загрузка запланирована.';
			|en = 'The import is scheduled.'; fa = 'The import is scheduled.';
			|it = 'Download pianificato.';
			|pl = 'Pobieranie jest zaplanowane.';
			|tr = 'İçe aktarma planlandı.'"), ,
		NStr("vi = 'Sẽ kết nhập tỷ giá ở chế độ nền qua thời gian ngắn.';
			|ru = 'Курсы будут загружены в фоновом режиме через непродолжительное время.';
			|en = 'The exchange rates will soon be imported in background mode.'; fa = 'The exchange rates will soon be imported in background mode.';
			|it = 'I tassi di cambio verranno scaricati nella modalità in background a breve.';
			|pl = 'Kursy zostaną pobrane w tle po pewnym czasie.';
			|tr = 'Kurlar bir süre sonra arka planda içe aktarılacaktır.'"),
		PictureLib.DialogInformation);
	
EndProcedure

&AtServer
Procedure ImportCurrencyRates()
	
	CurrencyRateOperationsInternal.ImportCurrencyRates();
	
EndProcedure

#EndRegion
