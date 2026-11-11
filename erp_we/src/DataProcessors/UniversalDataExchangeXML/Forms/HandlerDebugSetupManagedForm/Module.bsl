///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// First of all, checking the access rights.
	If Not AccessRight("Administration", Metadata) Then
		Raise NStr("vi = 'Chỉ có người quản trị có thể sử dụng bộ xử lý trong chế độ trực tác.';
					|ru = 'Использование обработки в интерактивном режиме доступно только администратору.';
					|en = 'Only administrators can run the data processor manually.'; fa = 'Only administrators can run the data processor manually.';
					|it = 'L''utilizzo dell''elaborazione in modalità interattiva è disponibile solo per l''amministratore.';
					|pl = 'Używanie przetwarzania w trybie interaktywnym jest dostępne tylko dla administratora.';
					|tr = 'Etkileşimli modda veri işlemcisi kullanımı sadece yönetici için kullanılabilir.'");
	EndIf;
	
	Object.ExchangeFileName = Parameters.ExchangeFileName;
	Object.ExchangeRulesFileName = Parameters.ExchangeRulesFileName;
	Object.EventHandlerExternalDataProcessorFileName = Parameters.EventHandlerExternalDataProcessorFileName;
	Object.AlgorithmsDebugMode = Parameters.AlgorithmsDebugMode;
	Object.ReadEventHandlersFromExchangeRulesFile = Parameters.ReadEventHandlersFromExchangeRulesFile;
	
	If Parameters.ReadEventHandlersFromExchangeRulesFile Then
		Title = NStr("vi = 'Tùy chỉnh gỡ rối hàm sự kiện khi kết xuất dữ liệu';
					|ru = 'Настройка отладки обработчиков при выгрузке данных';
					|en = 'Set up handler debugging on data export'; fa = 'Set up handler debugging on data export';
					|it = 'Impostazione debug elaboratori durante il caricamento dati';
					|pl = 'Ustawienie debugowania procedur przetwarzania podczas eksportu danych';
					|tr = 'Verileri dışa aktarırken işleyicilerin hata ayıklamasını ayarlama'");
		ButtonTitle = NStr("vi = 'Tạo mô-đun gỡ rối kết xuất';
							|ru = 'Сформировать модуль отладки выгрузки';
							|en = 'Generate export debugging module'; fa = 'ایجاد ماژول اشکال‌زدایی خروج اطلاعات';
							|it = 'Genera il modulo debug dello scaricamento';
							|pl = 'Utwórz moduł debugowania przesyłania';
							|tr = 'Dışa aktarma hata ayıklama motoru oluştur'");
	Else
		Title = NStr("vi = 'Tùy chỉnh gỡ rối hàm sự kiện khi kết nhập dữ liệu';
					|ru = 'Настройка отладки обработчиков при загрузке данных';
					|en = 'Set up handler debugging on data import'; fa = 'Set up handler debugging on data import';
					|it = 'Impostazione debug elaboratori durante il download di dati';
					|pl = 'Ustawienie debugowania procedur przetwarzania podczas pobierania danych';
					|tr = 'Veri dışa aktarırken hata ayıklama işleyicilerini ayarlama'");
		ButtonTitle = NStr("vi = 'Tạo mô-đun gỡ rối kết nhập';
							|ru = 'Сформировать модуль отладки загрузки';
							|en = 'Generate import debugging module'; fa = 'Generate import debugging module';
							|it = 'Creare modulo di debug del download';
							|pl = 'Utwórz moduł debugowania pobierania';
							|tr = 'İçe aktarmada hata ayıklama modülü oluştur'");
	EndIf;		
	Items.ExportHandlersCode.Title = ButtonTitle;
	
	SpecialTextColor = StyleColors.SpecialTextColor;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetVisibility1();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AlgorithmsDebugOnChange(Item)
	
	OnChangeOfChangeDebugMode();
	
EndProcedure

&AtClient
Procedure EventHandlerExternalDataProcessorFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	
	FileDialog.Filter     = NStr("vi = 'Tệp bộ xử lý ngoài của hàm sự kiện (*.epf)|*.epf';
								|ru = 'Файл внешней обработки обработчиков событий (*.epf)|*.epf';
								|en = 'External data processor file (*.epf)|*.epf'; fa = 'External data processor file (*.epf)|*.epf';
								|it = 'Il file di elaborazione esterna di elaboratori eventi (*.epf)|*.epf';
								|pl = 'Plik zewnętrznego przetwarzania wydarzeń (*.epf)|*.epf';
								|tr = 'Olay işleyicilerinin dış veri işlemci dosyası (*.epf) |*.epf'");
	FileDialog.DefaultExt = "epf";
	FileDialog.Title = NStr("vi = 'Hãy chọn tệp';
							|ru = 'Выберите файл';
							|en = 'Select file'; fa = 'انتخاب فایل';
							|it = 'Selezionare un file';
							|pl = 'Wybierz plik';
							|tr = 'Dosya seç'");
	FileDialog.Preview = False;
	FileDialog.FilterIndex = 0;
	FileDialog.FullFileName = Item.EditText;
	FileDialog.CheckFileExistence = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	
	Notification = New CallbackDescription("NameOfExternalDataProcessorFileOfEventHandlersChoiceProcessing", ThisObject, AdditionalParameters);
	FileDialog.Show(Notification);
	
EndProcedure

// Parameters:
//   SelectedFiles - Array of String
//                  - Undefined - a file choice result.
//   AdditionalParameters - Structure:
//     * Item - FormField - a source of the file choice.
//
&AtClient
Procedure NameOfExternalDataProcessorFileOfEventHandlersChoiceProcessing(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Object.EventHandlerExternalDataProcessorFileName = SelectedFiles[0];
	
	EventHandlerExternalDataProcessorFileNameOnChange(AdditionalParameters.Item);
	
EndProcedure

&AtClient
Procedure EventHandlerExternalDataProcessorFileNameOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure CheckAvailability(Command)
	CheckAvailabilityOnServer();
EndProcedure

&AtServer
Procedure CheckAvailabilityOnServer()
	
	File = New File(Object.EventHandlerExternalDataProcessorFileName);
	
	If File.Exists() Then
		
		MessageText = NStr("vi = 'Xử lý được phép';
							|ru = 'Обработка доступна';
							|en = 'Data processor is available'; fa = 'Data processor is available';
							|it = 'Обработка доступна';
							|pl = 'Data processor is available';
							|tr = 'Veri işlemcisi mevcut'");
		
	Else
		
		MessageText = NStr("vi = 'Xử lý không được phép';
							|ru = 'Обработка не доступна';
							|en = 'Data processor is unavailable'; fa = 'Data processor is unavailable';
							|it = 'Обработка не доступна';
							|pl = 'Data processor is unavailable';
							|tr = 'Veri işlemcisi mevcut değil'");
		
	EndIf;
	
	MessageToUser(MessageText);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	ClearMessages();
	
	If IsBlankString(Object.EventHandlerExternalDataProcessorFileName) Then
		
		MessageToUser(NStr("vi = 'Hãy chỉ ra tên tệp bộ xử lý ngoài.';
							|ru = 'Укажите имя файла внешней обработки.';
							|en = 'Please specify an external data processor file name.'; fa = 'Please specify an external data processor file name.';
							|it = 'Specificare il nome del file di elaborazione esterna.';
							|pl = 'Wskaż nazwę pliku zewnętrznego przetwarzania.';
							|tr = 'Harici veri işlemcisi dosyasının adını girin.'"), "EventHandlerExternalDataProcessorFileName");
		Return;
		
	EndIf;
	
	EventHandlerExternalDataProcessorFile = New File(Object.EventHandlerExternalDataProcessorFileName);
	
	Notification = New CallbackDescription("EventHandlerExternalDataProcessorFileExistanceCheckCompletion", ThisObject);
	EventHandlerExternalDataProcessorFile.BeginCheckingExistence(Notification);
	
EndProcedure

&AtClient
Procedure EventHandlerExternalDataProcessorFileExistanceCheckCompletion(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		MessageToUser(NStr("vi = 'Không tồn tại tệp bộ xử lý ngoài đã chỉ ra.';
							|ru = 'Указанный файл внешней обработки не существует.';
							|en = 'The specified external data processor file does not exist.'; fa = 'The specified external data processor file does not exist.';
							|it = 'Il file di elaborazione esterna specificato non esiste.';
							|pl = 'Wskazany plik zewnętrznego przetwarzania nie istnieje.';
							|tr = 'Belirtilen harici veri işlemcisi dosyası mevcut değil.'"),
			"EventHandlerExternalDataProcessorFileName");
		Return;
	EndIf;
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("EventHandlerExternalDataProcessorFileName", Object.EventHandlerExternalDataProcessorFileName);
	ClosingParameters.Insert("AlgorithmsDebugMode", Object.AlgorithmsDebugMode);
	ClosingParameters.Insert("ExchangeRulesFileName", Object.ExchangeRulesFileName);
	ClosingParameters.Insert("ExchangeFileName", Object.ExchangeFileName);
	
	Close(ClosingParameters);
	
EndProcedure

&AtClient
Procedure OpenFile(Command)
	
	ShowEventHandlersInWindow();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetVisibility1()
	
	OnChangeOfChangeDebugMode();
	
	Items.OpenFile.Enabled = Not IsBlankString(Object.EventHandlersTempFileName);
	
EndProcedure

&AtClient
Procedure ExportHandlersCode(Command)
	
	// Data was exported earlier...
	If Not IsBlankString(Object.EventHandlersTempFileName) Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Kết xuất lại';
													|ru = 'Выгрузить повторно';
													|en = 'Repeat export'; fa = 'Repeat export';
													|it = 'Scaricare di nuovo';
													|pl = 'Eksportuj ponownie';
													|tr = 'Tekrar dışa aktarmak'"));
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Mở mô-đun';
													|ru = 'Открыть модуль';
													|en = 'Open module'; fa = 'Open module';
													|it = 'Aprire il modulo';
													|pl = 'Otwórz moduł';
													|tr = 'Modül aç'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		
		CallbackDescription = New CallbackDescription("ExportHandlersCodeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, NStr("vi = 'Đã kết xuất mô-đun gỡ rối với mã hàm sự kiện.';
												|ru = 'Модуль отладки с кодом обработчиков уже выгружен.';
												|en = 'The debugging module with the handler code is already exported.'; fa = 'The debugging module with the handler code is already exported.';
												|it = 'Il modulo di debug con il codice di elaboratori è già scaricato.';
												|pl = 'Moduł debugowania z kodem procedur przetwarzania już jest eksportowany.';
												|tr = 'İşleyici koduyla hata ayıklama motoru zaten dışa aktarılıyor.'"), ButtonsList,,DialogReturnCode.No);
		
	Else
		
		ExportHandlersCodeCompletion(DialogReturnCode.Yes, Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportHandlersCodeCompletion(Result, AdditionalParameters) Export
	
	HasExportErrors = False;
	
	If Result = DialogReturnCode.Yes Then
		
		ExportedWithErrors = False;
		ExportEventHandlersAtServer(ExportedWithErrors);
		
	ElsIf Result = DialogReturnCode.Cancel Then
		
		Return;
		
	EndIf;
	
	If Not HasExportErrors Then
		
		SetVisibility1();
		
		ShowEventHandlersInWindow();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowEventHandlersInWindow()
	
	EventHandlers = EventHandlers();
	If EventHandlers <> Undefined Then
		EventHandlers.Show(NStr("vi = 'Mô-đun gỡ rối hàm sự kiện';
								|ru = 'Модуль отладки обработчиков';
								|en = 'Handler debugging module'; fa = 'Handler debugging module';
								|it = 'Il modulo di debug di elaboratori';
								|pl = 'Moduł debugowania procedur przetwarzania';
								|tr = 'İşleyici hata ayıklama modülü'"));
	EndIf;
	
	
	ExchangeProtocol = ExchangeProtocol();
	If ExchangeProtocol <> Undefined Then
		ExchangeProtocol.Show(NStr("vi = 'Lỗi kết xuất mô-đun hàm sự kiện';
									|ru = 'Ошибки выгрузки модуля обработчиков';
									|en = 'Errors occurred while exporting an event handler module'; fa = 'Errors occurred while exporting an event handler module';
									|it = 'Errore di upload del modulo di debug';
									|pl = 'Błędy eksportowania modułu procedur przetwarzania';
									|tr = 'İşleyici modülünü dışa aktarırken bir hata oluştu'"));
	EndIf;
	
EndProcedure

&AtServer
Function EventHandlers()
	
	EventHandlers = Undefined;
	
	HandlerFile = New File(Object.EventHandlersTempFileName);
	If HandlerFile.Exists() And HandlerFile.Size() <> 0 Then
		EventHandlers = New TextDocument;
		EventHandlers.Read(Object.EventHandlersTempFileName);
	EndIf;
	
	Return EventHandlers;
	
EndFunction

&AtServer
Function ExchangeProtocol()
	
	ExchangeProtocol = Undefined;
	
	ErrorLogFile = New File(Object.ExchangeProtocolTempFileName);
	If ErrorLogFile.Exists() And ErrorLogFile.Size() <> 0 Then
		ExchangeProtocol = New TextDocument;
		ExchangeProtocol.Read(Object.EventHandlersTempFileName);
	EndIf;
	
	Return ExchangeProtocol;
	
EndFunction

&AtServer
Procedure ExportEventHandlersAtServer(Cancel)
	
	ObjectForServer = FormAttributeToValue("Object");
	FillPropertyValues(ObjectForServer, Object);
	ObjectForServer.ExportEventHandlers(Cancel);
	ValueToFormAttribute(ObjectForServer, "Object");
	
EndProcedure

&AtClient
Procedure OnChangeOfChangeDebugMode()
	
	ToolTip = Items.AlgorithmsDebugTooltip;
	
	ToolTip.CurrentPage = ToolTip.ChildItems["Group_"+Object.AlgorithmsDebugMode];
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

#EndRegion
