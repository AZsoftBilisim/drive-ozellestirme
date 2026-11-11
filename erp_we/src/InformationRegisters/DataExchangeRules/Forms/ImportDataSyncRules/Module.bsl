///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var ExternalResourcesAllowed;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Verify that the form is opened with the required parameters
	If Not ValueIsFilled(Parameters.ExchangePlanName) Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	ExchangePlanName = Parameters.ExchangePlanName;
	
	If Not ValueIsFilled(ExchangePlanName) Then
		Return;
	EndIf;
	
	Title = StrReplace(Title, "%1", Metadata.ExchangePlans[ExchangePlanName].Synonym);
	
	UpdateRuleInfo();
	
	Items.DebugGroup.Enabled = (RulesSource = "RuelsImportedFromFile");
	Items.DebugSettingsGroup.Enabled = DebugMode;
	Items.RulesSourceFile.Enabled = (RulesSource = "RuelsImportedFromFile");
	
	DataExchangeRulesImportEventLogEvent = DataExchangeServer.DataExchangeRulesImportEventLogEvent();
	
	ApplicationName = Metadata.ExchangePlans[ExchangePlanName].Synonym;
	RuleSetLocation = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, 
								"PathToRulesSetFileOnUserSite, PathToRulesSetFileInTemplateDirectory");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TooltipTemplate = NStr("vi = 'Có thể tải bộ quy tắc từ %1
		|hoặc tìm kiếm trong %2';
		|ru = 'Комплект правил можно скачать с %1
		|или найти в %2';
		|en = 'You can download a rule set from %1 
		|or find in %2'; fa = 'You can download a rule set from %1 
		|or find in %2';
		|it = 'Il set di regole può essere scaricato da %1
		| o trovato in %2';
		|pl = 'Zestaw zasad można pobrać z %1
		|lub znaleźć w %2';
		|tr = 'Kurallar kümesin 
		|den %1 içe aktarılabilir veya %2 ''de bulunabilir'");
	
	UpdateDirectoryPattern = NStr("vi = 'thư mục chứa bộ cài chương trình ""%1""';
									|ru = 'каталоге поставки программы ""%1""';
									|en = 'the %1 application directory'; fa = 'the %1 application directory';
									|it = 'catalogo di consegna del programma ""%1""';
									|pl = 'katalogu dostawy programu ""%1""';
									|tr = '""%1"" uygulama tesliminin dizini'");
	UpdateDirectoryPattern = StringFunctionsClientServer.SubstituteParametersToString(UpdateDirectoryPattern, ApplicationName);
	
	UserSitePattern = NStr("vi = 'trang hỗ trợ người sử dụng hệ thống ""1C:Enterprise""';
							|ru = 'сайта поддержки пользователей системы ""1С:Предприятие 8""';
							|en = '1C:Enterprise support website'; fa = '1C:Enterprise support website';
							|it = 'Sito di supporto degli utenti del sistema ""1C:Enterprise 8""';
							|pl = 'strony wsparcia użytkowników systemu ""1C:Enterprise 8""';
							|tr = '1C:Enterprise 8 kullanıcıları için destek sitesi'");
	If Not IsBlankString(RuleSetLocation.PathToRulesSetFileOnUserSite) Then
		UserSitePattern = New FormattedString(UserSitePattern,,,, RuleSetLocation.PathToRulesSetFileOnUserSite);
	EndIf;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("TooltipTemplate",            TooltipTemplate);
	AdditionalParameters.Insert("UpdateDirectoryPattern",    UpdateDirectoryPattern);
	AdditionalParameters.Insert("UserSitePattern", UserSitePattern);
	
	If Not IsBlankString(RuleSetLocation.PathToRulesSetFileInTemplateDirectory)
		And CommonClient.IsWindowsClient() Then
		AdditionalParameters.Insert("DefaultDirectory",                AppDataDirectory() + "1C\1Cv8\tmplts\");
		AdditionalParameters.Insert("UserTemplateSettings", AppDataDirectory() + "1C\1CEStart\1CEStart.cfg");
		AdditionalParameters.Insert("FileLocation1",                 "");
		
		SuggestionText = NStr("vi = 'Để mở thư mục, cần cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
								|ru = 'Для открытия каталога необходимо необходимо установить расширение для работы с 1С:Предприятием.';
								|en = 'To open the directory, install 1C:Enterprise Extension.'; fa = 'To open the directory, install 1C:Enterprise Extension.';
								|it = 'Per aprire la directory è necessario installare l''estensione di lavoro con 1C:Enterprise.';
								|pl = 'W celu otwarcia katalogu należy zainstalować rozszerzenie do pracy z 1C:Enterprise.';
								|tr = 'Kataloğu açmak için 1C:Enterprise ile çalışma uzantısını kurmanız gerekir.'");
		Notification = New CallbackDescription("AfterCheckFileSystemExtension", ThisObject, AdditionalParameters);
		FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText);
	Else
		SetInformationTitleOnReceive(AdditionalParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure AfterCheckFileSystemExtension(Result, AdditionalParameters) Export
	
	If Result Then
		File = New File(AdditionalParameters.UserTemplateSettings);
		
		Notification = New CallbackDescription("DetermineFileExists", ThisObject, AdditionalParameters);
		File.BeginCheckingExistence(Notification);
		
	Else
		SetInformationTitleOnReceive(AdditionalParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure DetermineFileExists(Exists, AdditionalParameters) Export

#If WebClient Then
	
	Raise NStr("vi = 'Không cho phép thao tác trên Web-client';
				|ru = 'Операция в веб-клиенте не предусмотрена';
				|en = 'The operation is not available in web client'; fa = 'The operation is not available in web client';
				|it = 'Operazioni web-client non previste';
				|pl = 'Operacja w kliencie sieciowym nie jest przewidziana';
				|tr = 'Web istemcide işlem öngörülmedi'");
	
#Else
	
	FoundDirectory = Undefined;
	
	If Exists Then
		
		Text = New TextReader(AdditionalParameters.UserTemplateSettings, TextEncoding.UTF16);
		Page1 = "";
		
		While Page1 <> Undefined Do
			Page1 = Text.ReadLine();
			If Page1 = Undefined Then
				Break;
			EndIf;
			If StrFind(Upper(Page1), Upper("ConfigurationTemplatesLocation")) = 0 Then
				Continue;
			EndIf;
			SeparatorPosition = StrFind(Page1, "=");
			If SeparatorPosition = 0 Then
				Continue;
			EndIf;
			FoundDirectory = CommonClientServer.AddLastPathSeparator(TrimAll(Mid(Page1, SeparatorPosition + 1)));
			Break;
		EndDo;
		
	EndIf;
	
	If FoundDirectory <> Undefined Then
		AdditionalParameters.FileLocation1 = FoundDirectory + RuleSetLocation.PathToRulesSetFileInTemplateDirectory;
	Else
		AdditionalParameters.FileLocation1 = AdditionalParameters.DefaultDirectory + RuleSetLocation.PathToRulesSetFileInTemplateDirectory
	EndIf;
	
	File = New File(AdditionalParameters.FileLocation1);
	
	Notification = New CallbackDescription("DetermineDirectoryExists", ThisObject, AdditionalParameters);
	File.BeginCheckingExistence(Notification);
	
#EndIf
	
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure DetermineDirectoryExists(Exists, AdditionalParameters) Export
	
	If Exists Then
		AdditionalParameters.UpdateDirectoryPattern = New FormattedString(AdditionalParameters.UpdateDirectoryPattern,,,,
			AdditionalParameters.FileLocation1);
	EndIf;
	
	SetInformationTitleOnReceive(AdditionalParameters);
	
EndProcedure

// Continuation of the procedure (see above).
&AtClient
Procedure SetInformationTitleOnReceive(AdditionalParameters)
	ToolTipText = SubstituteParametersInFormattedString(AdditionalParameters.TooltipTemplate, 
		AdditionalParameters.UserSitePattern,
		AdditionalParameters.UpdateDirectoryPattern);
	Items.RulesImportInfoDecoration.Title = ToolTipText;
EndProcedure

&AtClient
Function CheckFillingAtClient()
	
	HasBlankFields = False;
	
	If DebugMode Then
		
		If ExportDebugMode Then
			
			FileNameStructure = CommonClientServer.ParseFullFileName(ExportDebuggingDataProcessorFileName);
			FileName = FileNameStructure.BaseName;
			
			If Not ValueIsFilled(FileName) Then
				
				MessageString = NStr("vi = 'Chưa đặt tên tệp bộ xử lý ngoài.';
									|ru = 'Не задано имя файла внешней обработки.';
									|en = 'External data processor file name is not specified'; fa = 'External data processor file name is not specified';
									|it = 'Il nome del file di elaborazione esterno non è specificato.';
									|pl = 'Nazwa zewnętrznego pliku przetwarzania nie została określona.';
									|tr = 'Harici veri işlemci dosyasının adı belirtilmemiş.'");
				CommonClient.MessageToUser(MessageString,, "ExportDebuggingDataProcessorFileName",, HasBlankFields);
				
			EndIf;
			
		EndIf;
		
		If ImportDebugMode Then
			
			FileNameStructure = CommonClientServer.ParseFullFileName(ImportDebuggingDataProcessorFileName);
			FileName = FileNameStructure.BaseName;
			
			If Not ValueIsFilled(FileName) Then
				
				MessageString = NStr("vi = 'Chưa đặt tên tệp bộ xử lý ngoài.';
									|ru = 'Не задано имя файла внешней обработки.';
									|en = 'External data processor file name is not specified'; fa = 'External data processor file name is not specified';
									|it = 'Il nome del file di elaborazione esterno non è specificato.';
									|pl = 'Nazwa zewnętrznego pliku przetwarzania nie została określona.';
									|tr = 'Harici veri işlemci dosyasının adı belirtilmemiş.'");
				CommonClient.MessageToUser(MessageString,, "ImportDebuggingDataProcessorFileName",, HasBlankFields);
				
			EndIf;
			
		EndIf;
		
		If DataExchangeLoggingMode Then
			
			FileNameStructure = CommonClientServer.ParseFullFileName(ExchangeProtocolFileName);
			FileName = FileNameStructure.BaseName;
			
			If Not ValueIsFilled(FileName) Then
				
				MessageString = NStr("vi = 'Chưa đặt tên tệp giao thức trao đổi.';
									|ru = 'Не задано имя файла протокола обмена.';
									|en = 'Exchange protocol file name is not specified.'; fa = 'Exchange protocol file name is not specified.';
									|it = 'Il nome del file del protocollo di scambio non è specificato.';
									|pl = 'Nazwa pliku protokołu wymiany nie została określona.';
									|tr = 'Alışveriş protokolü dosya adı belirtilmemiş.'");
				CommonClient.MessageToUser(MessageString,, "ExchangeProtocolFileName",, HasBlankFields);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Not HasBlankFields;
	
EndFunction

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RulesSourceOnChange(Item)
	
	Items.DebugGroup.Enabled = (RulesSource = "RuelsImportedFromFile");
	Items.RulesSourceFile.Enabled = (RulesSource = "RuelsImportedFromFile");
	
	If RulesSource = "StandardRulesFromConfiguration" Then
		
		DebugMode = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableExportDebugOnChange(Item)
	
	DebuggingSettingsChanged = True;
	Items.ExternalDataProcessorForExportDebug.Enabled = ExportDebugMode;
	
EndProcedure

&AtClient
Procedure ExternalDataProcessorForExportDebugStartChoice(Item, ChoiceData, StandardProcessing)
	
	DebuggingSettingsChanged = True;
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter", NStr("vi = 'Bộ xử lý ngoài (*.epf)';
										|ru = 'Внешняя обработка (*.epf)';
										|en = 'External data processor (*.epf)'; fa = 'External data processor (*.epf)';
										|it = 'Elaborazione esterna (*.epf)';
										|pl = 'Przetwarzanie zewnętrzne (*.epf)';
										|tr = 'Harici işleme (*.epf)'") + "|*.epf" );
	
	DataExchangeClient.FileSelectionHandler(ThisObject, "ExportDebuggingDataProcessorFileName", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure ExternalDataProcessorForImportDebugStartChoice(Item, ChoiceData, StandardProcessing)
	
	DebuggingSettingsChanged = True;
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter", NStr("vi = 'Bộ xử lý ngoài (*.epf)';
										|ru = 'Внешняя обработка (*.epf)';
										|en = 'External data processor (*.epf)'; fa = 'External data processor (*.epf)';
										|it = 'Elaborazione esterna (*.epf)';
										|pl = 'Przetwarzanie zewnętrzne (*.epf)';
										|tr = 'Harici işleme (*.epf)'") + "|*.epf" );
	
	StandardProcessing = False;
	DataExchangeClient.FileSelectionHandler(ThisObject, "ImportDebuggingDataProcessorFileName", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure EnableImportDebugOnChange(Item)
	
	DebuggingSettingsChanged = True;
	Items.ExternalDataProcessorForImportDebug.Enabled = ImportDebugMode;
	
EndProcedure

&AtClient
Procedure EnableDataExchangeLoggingOnChange(Item)
	
	DebuggingSettingsChanged = True;
	Items.ExchangeProtocolFile.Enabled = DataExchangeLoggingMode;
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	DebuggingSettingsChanged = True;
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter", NStr("vi = 'Văn bản thuần (*.txt)';
										|ru = 'Текстовый документ (*.txt)';
										|en = 'Text document (*.txt)'; fa = 'Text document (*.txt)';
										|it = 'Documento di testo (*.txt)';
										|pl = 'Dokument tekstowy (*.txt)';
										|tr = 'Metin belgesi (*.txt)'")+ "|*.txt" );
	DialogSettings.Insert("CheckFileExist", False);
	
	DataExchangeClient.FileSelectionHandler(ThisObject, "ExchangeProtocolFileName", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileOpening(Item, StandardProcessing)
	
	DataExchangeClient.FileOrDirectoryOpenHandler(ThisObject, "ExchangeProtocolFileName", StandardProcessing);
	
EndProcedure

&AtClient
Procedure EnableDebuggingOnChange(Item)
	
	DebuggingSettingsChanged = True;
	Items.DebugSettingsGroup.Enabled = DebugMode;
	
EndProcedure

&AtClient
Procedure NotStopByMistakeOnChange(Item)
	DebuggingSettingsChanged = True;
EndProcedure

&AtClient
Procedure RulesImportInfoDecorationURLProcessing(
		Item, FormattedStringURL, StandardProcessing)
	
	AdditionalParameters = New Structure;	
	AdditionalParameters.Insert("FormattedStringURL", FormattedStringURL);
		
	Notification = New CallbackDescription("DecorationRuleReceiptInformationURLProcessingAfterFinish",
		ThisObject, AdditionalParameters);
		
	StandardProcessing = False;
	FileSystemClient.OpenURL(FormattedStringURL, Notification);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportRules(Command)
	
	// Importing from file on the client
	NameParts = CommonClientServer.ParseFullFileName(RulesFileName);
	
	DialogParameters = New Structure;
	DialogParameters.Insert("Title", NStr("vi = 'Hãy chỉ ra tệp nén có quy tắc trao đổi';
											|ru = 'Укажите архив с правилами обмена';
											|en = 'Select an exchange rule archive'; fa = 'Select an exchange rule archive';
											|it = 'Indicare archivio con regole di scambio';
											|pl = 'Określ archiwum z zasadami wymiany';
											|tr = 'Değişim kuralları ile bir arşiv belirtin'"));
	DialogParameters.Insert("Filter", NStr("vi = 'Tệp nén ZIP (*.zip)';
											|ru = 'Архивы ZIP (*.zip)';
											|en = 'ZIP archive (*.zip)'; fa = 'ZIP archive (*.zip)';
											|it = 'Archivi ZIP (*.zip)';
											|pl = 'Archiwa ZIP (*.zip)';
											|tr = 'ZIP arşivleri (*.zip)'") + "|*.zip");
	DialogParameters.Insert("FullFileName", NameParts.FullName);
	
	Notification = New CallbackDescription("ImportRulesCompletion", ThisObject);
	DataExchangeClient.SelectAndSendFileToServer(Notification, DialogParameters, UUID);
	
EndProcedure

&AtClient
Procedure UnloadRules(Command)
	
	NameParts = CommonClientServer.ParseFullFileName(RulesFileName);

	// Export to an archive.
	StorageAddress = GetRuleArchiveTempStorageAddressAtServer();
	
	If IsBlankString(StorageAddress) Then
		Return;
	EndIf;
	
	If IsBlankString(NameParts.BaseName) Then
		FullFileName = NStr("vi = 'Quy tắc chuyển đổi';
							|ru = 'Правила конвертации';
							|en = 'Conversion rules'; fa = 'Conversion rules';
							|it = 'Regole di conversione';
							|pl = 'Zasady konwersji';
							|tr = 'Dönüşüm kuralları'");
	Else
		FullFileName = NameParts.BaseName;
	EndIf;
	
	DialogParameters = New Structure;
	DialogParameters.Insert("Mode", FileDialogMode.Save);
	DialogParameters.Insert("Title", NStr("vi = 'Hãy chỉ ra tệp mà quy tắc kết xuất vào đó';
											|ru = 'Укажите в какой файл выгрузить правила';
											|en = 'Select a file to export rules to'; fa = 'Select a file to export rules to';
											|it = 'Specifica da quale file caricare le regole';
											|pl = 'Określ, do którego pliku mają być przesłane reguły';
											|tr = 'Kuralların dışa aktarılacağı bir dosya belirtin'") );
	DialogParameters.Insert("FullFileName", FullFileName);
	DialogParameters.Insert("Filter", NStr("vi = 'Tệp nén ZIP (*.zip)';
											|ru = 'Архивы ZIP (*.zip)';
											|en = 'ZIP archive (*.zip)'; fa = 'ZIP archive (*.zip)';
											|it = 'Archivi ZIP (*.zip)';
											|pl = 'Archiwa ZIP (*.zip)';
											|tr = 'ZIP arşivleri (*.zip)'") + "|*.zip");
	
	FileToReceive = New Structure("Name, Location", FullFileName, StorageAddress);
	
	DataExchangeClient.SelectAndSaveFileAtClient(FileToReceive, DialogParameters);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
		
	If RulesSource = "StandardRulesFromConfiguration" Then
		BeforeRuleImport(Undefined, "");
	Else
		If ConversionRuleSource = PredefinedValue("Enum.DataExchangeRulesSources.ConfigurationTemplate") Then
			
			ErrorDescription = NStr("vi = 'Chưa kết nhập quy tắc từ tệp. Khi đóng lại sẽ dẫn đến sử dụng các quy tắc chuyển đổi mẫu.
			|Sử dụng quy tắc chuyển đổi mẫu?';
			|ru = 'Правила из файла не загружены. Закрытие приведет к использованию типовых правил конвертации.
			|Использовать типовые правила конвертации?';
			|en = 'Rules are not imported. If you close the form, the default conversion rules will apply.
			|Apply the default rules?'; fa = 'Rules are not imported. If you close the form, the default conversion rules will apply.
			|Apply the default rules?';
			|it = 'Le regole dal file non vengono caricate. La chiusura comporterà l''utilizzo di regole di conversione standard.
			| Utilizza regole di conversione standard?';
			|pl = 'Reguły z pliku nie są wczytane. Zamknięcie doprowadzi do użycia standardowych reguł konwersji.
			|Chcesz użyć standardowych reguł konwersji?';
			|tr = 'Dosyadaki kurallar içe aktarılmaz. Kapatma, tipik dönüşüm kurallarının kullanılmasına yol açacaktır. 
			|Tipik dönüşüm kurallar kullanılsın mı?'");
			
			Notification = New CallbackDescription("CloseRuleImportForm", ThisObject);
			
			Buttons = New ValueList;
			Buttons.Add("Use", NStr("vi = 'Sử dụng';
									|ru = 'Использовать';
									|en = 'Use'; fa = 'استفاده';
									|it = 'Utilizza';
									|pl = 'Use';
									|tr = 'Kullanmak'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
			
			FormParameters = StandardSubsystemsClient.QuestionToUserParameters();
			FormParameters.DefaultButton = "Use";
			FormParameters.PromptDontAskAgain = False;
			
			StandardSubsystemsClient.ShowQuestionToUser(Notification, ErrorDescription, Buttons, FormParameters);
		Else
			If DebuggingSettingsChanged Then
				ImportDebugModeSettingsAtServer();
			EndIf;
			Close();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DecorationRuleReceiptInformationURLProcessingAfterFinish(ApplicationStarted, AdditionalParameters) Export
	
	If ApplicationStarted Then
		Return;
	EndIf;
	
	FileSystemClient.OpenExplorer(AdditionalParameters.FormattedStringURL);
	
EndProcedure

&AtClient
Procedure ImportRulesCompletion(Val PutFilesResult, Val AdditionalParameters) Export
	
	PutFileAddress = PutFilesResult.Location;
	ErrorText           = PutFilesResult.ErrorDescription;
	
	If IsBlankString(ErrorText) And IsBlankString(PutFileAddress) Then
		ErrorText = NStr("vi = 'Lỗi truyền tệp tùy chỉnh đồng bộ dữ liệu lên máy chủ';
						|ru = 'Ошибка передачи файла настроек синхронизации данных на сервер';
						|en = 'An error occurred while sending a file of data synchronization settings to the server.'; fa = 'An error occurred while sending a file of data synchronization settings to the server.';
						|it = 'Errore durante l''invio del file delle impostazioni di sincronizzazione dei dati al server';
						|pl = 'Błąd podczas przekazania pliku ustawień synchronizacji danych na serwer';
						|tr = 'Veri senkronizasyon ayarları dosyasını sunucuya aktarırken bir hata oluştu'");
	EndIf;
	
	If Not IsBlankString(ErrorText) Then
		CommonClient.MessageToUser(ErrorText);
		Return;
	EndIf;
		
	// The file is successfully transferred, importing the file to the server.
	NameParts = CommonClientServer.ParseFullFileName(PutFilesResult.Name);
	
	If Lower(NameParts.Extension) <> ".zip" Then
		CommonClient.MessageToUser(NStr("vi = 'Sai định dạng tệp bộ quy tắc. Định dạng mong muốn là tệp nén zip chứa ba tệp:
			|ExchangeRules.xml - quy tắc chuyển đổi đối với chương trình này;
			|CorrespondentExchangeRules.xml - quy tắc chuyển đổi đối với chương trình trao đổi;
			|RegistrationRules.xml - quy tắc ghi nhận đối với chương trình này.';
			|ru = 'Некорректный формат файла комплекта правил. Ожидается zip архив, содержащий три файла:
			|ExchangeRules.xml - правила конвертации для текущей программы;
			|CorrespondentExchangeRules.xml - правила конвертации для программы-корреспондента;
			|RegistrationRules.xml - правила регистрации для текущей программы.';
			|en = 'Invalid rules file. Expected a ZIP archive with three files:
			|ExchangeRules.xml. Contains conversion rules for this application.
			|CorrespondentExchangeRules.xml. Contains conversion rules for the peer application.
			|RegistrationRules.xml. Contains registration rules for this application.'; fa = 'Invalid rules file. Expected a ZIP archive with three files:
			|ExchangeRules.xml. Contains conversion rules for this application.
			|CorrespondentExchangeRules.xml. Contains conversion rules for the peer application.
			|RegistrationRules.xml. Contains registration rules for this application.';
			|it = 'Formato file ruleset non valido. Archivio zip atteso contenente tre file:
			| ExchangeRules.xml - regole di conversione per il programma corrente;
			| CorrespondentExchangeRules.xml - regole di conversione per il programma corrispondente; 
			|RegistrationRules.xml - regole di registrazione per il programma corrente.';
			|pl = 'Nieodpowiedni format pliku zestawu reguł. Spodziewany jest archiwum zip, liczba plików w archiwum – to trzy pliki:
			|ExchangeRules.xml – zasady konwersji do bieżącego programu;
			|CorrespondentExchangeRules.xml – zasady konwersji do do programu-korespondenta;
			|RegistrationRules.xml – zasady rejestracji do bieżącego programu.';
			|tr = 'Kural kümesi dosyasının yanlış biçimi. 
			|Üç dosya içeren zip arşivi bekleniyor: ExchangeRules.xml - 
			|geçerli uygulama için dönüşüm kuralları; CorrespondentExchangeRules.xml - 
			|uygulama muhabiri için dönüşüm kuralları; RegistrationRules.xml - mevcut uygulama için kayıt kuralları.'"));
	EndIf;
	
	BeforeRuleImport(PutFileAddress, NameParts.Name);
	
EndProcedure

&AtClient
Procedure PerformRuleImport(Val PutFileAddress, Val FileName, ErrorDescription = Undefined)
	
	Cancel = False;
	DebuggingSettingsChanged = False;
	
	ImportRulesAtServer(Cancel, PutFileAddress, FileName, ErrorDescription);
	
	If TypeOf(ErrorDescription) <> Type("Boolean") And ErrorDescription <> Undefined Then
		
		Buttons = New ValueList;
		
		If ErrorDescription.ErrorKind = "InvalidConfiguration" Then
			Buttons.Add("Cancel", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Close';
										|tr = 'Kapat'"));
		Else
			Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
										|ru = 'Продолжить';
										|en = 'Continue'; fa = 'ادامه';
										|it = 'Continuare';
										|pl = 'Kontynuuj';
										|tr = 'Devam'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Anuluj';
										|tr = 'İptal'"));
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("PutFileAddress", PutFileAddress);
		AdditionalParameters.Insert("FileName", FileName);
		Notification = New CallbackDescription("AfterConversionRulesCheckForCompatibility", ThisObject, AdditionalParameters);
		
		FormParameters = StandardSubsystemsClient.QuestionToUserParameters();
		FormParameters.DefaultButton = "Cancel";
		FormParameters.Picture = ErrorDescription.Picture;
		FormParameters.PromptDontAskAgain = False;
		If ErrorDescription.ErrorKind = "InvalidConfiguration" Then
			FormParameters.Title = NStr("vi = 'Không thể kết nhập quy tắc';
										|ru = 'Правила не могут быть загружены';
										|en = 'Cannot import rules'; fa = 'Cannot import rules';
										|it = 'Le regole non possono essere scaricate';
										|pl = 'Reguły nie można wczytać';
										|tr = 'Kurallar içe aktarılamıyor'");
		Else
			FormParameters.Title = NStr("vi = 'Đồng bộ dữ liệu có thể làm việc không chính xác';
										|ru = 'Синхронизация данных может работать некорректно';
										|en = 'Data synchronization might be performed incorrectly'; fa = 'Data synchronization might be performed incorrectly';
										|it = 'La sincronizzazione dei dati potrebbe essere non lavorare correttamente';
										|pl = 'Synchronizacja danych może nie działać poprawnie.';
										|tr = 'Veri senkronizasyonu yanlış yürütülebilir'");
		EndIf;
		
		StandardSubsystemsClient.ShowQuestionToUser(Notification, ErrorDescription.ErrorText, Buttons, FormParameters);
		
	ElsIf Cancel Then
		ErrorText = NStr("vi = 'Trong quá trình kết nhập quy tắc đã tìm thấy lỗi.
			|Chuyển đến nhật ký sự kiện?';
			|ru = 'В процессе загрузки правил были обнаружены ошибки.
			|Перейти в журнал регистрации?';
			|en = 'Errors occurred when importing the rules.
			|Go to the event log?'; fa = 'Errors occurred when importing the rules.
			|Go to the event log?';
			|it = 'Durante il download delle regole si sono verificati degli errori. 
			| Passare al registro?';
			|pl = 'Błędy wykryto podczas pobierania reguł.
			|Przejdź do dziennika rejestracji?';
			|tr = 'Kurallar içe aktarılırken hatalar oluştu.
			|Olay günlüğüne gitmek istiyor musunuz?'");
		Notification = New CallbackDescription("ShowEventLogWhenErrorOccurred", ThisObject);
		ShowQueryBox(Notification, ErrorText, QuestionDialogMode.YesNo, ,DialogReturnCode.No);
	Else
		ShowUserNotification(,, NStr("vi = 'Đã kết nhập thành công quy tắc vào cơ sở thông tin.';
									|ru = 'Правила успешно загружены в информационную базу.';
									|en = 'The rules are imported to the infobase.'; fa = 'The rules are imported to the infobase.';
									|it = 'Le regole sono state scaricate correttamente nel database.';
									|pl = 'Reguły pomyślnie wczytane do bazy informacyjnej.';
									|tr = 'Kurallar, infobase''e başarıyla aktarıldı.'"));
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowEventLogWhenErrorOccurred(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Filter = New Structure;
		Filter.Insert("EventLogEvent", DataExchangeRulesImportEventLogEvent);
		OpenForm("DataProcessor.EventLog.Form", Filter, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportRulesAtServer(Cancel, TempStorageAddress, RulesFileName, ErrorDescription)
	
	SetRuleSource = ?(RulesSource = "StandardRulesFromConfiguration",
		Enums.DataExchangeRulesSources.ConfigurationTemplate, Enums.DataExchangeRulesSources.File);
	
	CovnersionRuleWriting                               = InformationRegisters.DataExchangeRules.CreateRecordManager();
	CovnersionRuleWriting.RulesKind                     = Enums.DataExchangeRulesTypes.ObjectsConversionRules;
	CovnersionRuleWriting.RulesTemplateName               = ConversionRuleTemplateName;
	CovnersionRuleWriting.CorrespondentRulesTemplateName = CorrespondentRulesTemplateName;
	CovnersionRuleWriting.RulesInformation           = ConversionRulesInformation;
	
	FillPropertyValues(CovnersionRuleWriting, ThisObject);
	CovnersionRuleWriting.RulesSource = SetRuleSource;
	
	RegistrationRuleWriting                     = InformationRegisters.DataExchangeRules.CreateRecordManager();
	RegistrationRuleWriting.RulesKind           = Enums.DataExchangeRulesTypes.ObjectsRegistrationRules;
	RegistrationRuleWriting.RulesTemplateName     = RegistrationRuleTemplateName;
	RegistrationRuleWriting.RulesInformation = RegistrationRulesInformation;
	RegistrationRuleWriting.RulesFileName      = RulesFileName;
	RegistrationRuleWriting.ExchangePlanName      = ExchangePlanName;
	RegistrationRuleWriting.RulesSource      = SetRuleSource;
	
	RegisterRecordStructure = New Structure();
	RegisterRecordStructure.Insert("CovnersionRuleWriting", CovnersionRuleWriting);
	RegisterRecordStructure.Insert("RegistrationRuleWriting", RegistrationRuleWriting);
	
	InformationRegisters.DataExchangeRules.ImportRulesSet(Cancel, RegisterRecordStructure,
		ErrorDescription, TempStorageAddress, RulesFileName);
	
	If Not Cancel Then
		
		CovnersionRuleWriting.Write();
		RegistrationRuleWriting.Write();
		
		Modified = False;
		
		// Open session cache for the registration mechanism has become obsolete.
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
		RefreshReusableValues();
		UpdateRuleInfo();
		
	EndIf;
	
EndProcedure

&AtServer
Function GetRuleArchiveTempStorageAddressAtServer()
	
	// Create the temporary directory at the server and generate file paths.
	TempDirectoryName = GetTempFileName("");
	CreateDirectory(TempDirectoryName);
	
	PathToFile               = CommonClientServer.AddLastPathSeparator(TempDirectoryName) + "ExchangeRules";
	CorrespondentFilePath = CommonClientServer.AddLastPathSeparator(TempDirectoryName) + "CorrespondentExchangeRules";
	RegistrationFilePath    = CommonClientServer.AddLastPathSeparator(TempDirectoryName) + "RegistrationRules";
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DataExchangeRules.XMLRules,
		|	DataExchangeRules.XMLCorrespondentRules,
		|	DataExchangeRules.RulesKind
		|FROM
		|	InformationRegister.DataExchangeRules AS DataExchangeRules
		|WHERE
		|	DataExchangeRules.ExchangePlanName = &ExchangePlanName";
	
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		NString = NStr("vi = 'Không thể nhận quy tắc trao đổi.';
						|ru = 'Не удалось получить правила обмена.';
						|en = 'Cannot receive exchange rules.'; fa = 'Cannot receive exchange rules.';
						|it = 'Non è stato possibile ricevere le regole di scambio.';
						|pl = 'Nie udało się uzyskać reguł wymiany.';
						|tr = 'Değişim kuralları alınamıyor.'");
		DataExchangeServer.ReportError(NString);
		DeleteFiles(TempDirectoryName);
		Return "";
		
	Else
		
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			If Selection.RulesKind = Enums.DataExchangeRulesTypes.ObjectsConversionRules Then
				
				// Get, save to, and archive the conversion rules file in a temporary directory.
				RuleBinaryData = Selection.XMLRules.Get(); // BinaryData
				RuleBinaryData.Write(PathToFile + ".xml");
				
				// Get, save to, and archive peer's conversion rules file in a temporary directory.
				CorrespondentRulesBinaryData = Selection.XMLCorrespondentRules.Get(); // BinaryData
				CorrespondentRulesBinaryData.Write(CorrespondentFilePath + ".xml");
				
			Else
				// Get, save to, and archive the registration rules file in a temporary directory.
				RegistrationRulesBinaryData = Selection.XMLRules.Get(); // BinaryData
				RegistrationRulesBinaryData.Write(RegistrationFilePath + ".xml");
			EndIf;
			
		EndDo;
		
		FilesPackingMask = CommonClientServer.AddLastPathSeparator(TempDirectoryName) + "*.xml";
		DataExchangeServer.PackIntoZipFile(PathToFile + ".zip", FilesPackingMask);
		
		// Placing the ZIP archive with the rules in the storage.
		RuleArchiveBinaryData = New BinaryData(PathToFile + ".zip");
		TempStorageAddress = PutToTempStorage(RuleArchiveBinaryData);
		DeleteFiles(TempDirectoryName);
		
		Return TempStorageAddress;
		
	EndIf;
	
EndFunction

&AtServer
Procedure UpdateRuleInfo()
	
	RulesInformation();
	
	RulesSource = ?(RegistrationRuleSource = Enums.DataExchangeRulesSources.File
		Or ConversionRuleSource = Enums.DataExchangeRulesSources.File,
		"RuelsImportedFromFile", "StandardRulesFromConfiguration");
	
	CommonRulesInformation = "[UsageInformation]
		|
		|[RegistrationRulesInformation]
		|
		|[ConversionRulesInformation]";
	
	If RulesSource = "RuelsImportedFromFile" Then
		UsageInformation = NStr("vi = 'Đang sử dụng quy tắc được kết nhập từ tệp.';
								|ru = 'Используются правила загруженные из файла.';
								|en = 'Exchange rules imported from a file are applied.'; fa = 'Exchange rules imported from a file are applied.';
								|it = 'Sono utilizzate le regole di download dal file.';
								|pl = 'Używa się reguł pobranych z pliku.';
								|tr = 'Dosyadan içe aktarılan kurallar kullanıldı.'");
	Else
		UsageInformation = NStr("vi = 'Đang sử dụng quy tắc mẫu từ thành phần cấu hình.';
								|ru = 'Используются типовые правила из состава конфигурации.';
								|en = 'Default configuration exchange rules are used.'; fa = 'Default configuration exchange rules are used.';
								|it = 'Sono utilizzate regole standard dalla composizione della configurazione.';
								|pl = 'Używane są typowe reguły ze składu konfiguracji.';
								|tr = 'Yapılandırmadan standart kurallar kullanıldı.'");
	EndIf;
	
	CommonRulesInformation = StrReplace(CommonRulesInformation, "[UsageInformation]", UsageInformation);
	CommonRulesInformation = StrReplace(CommonRulesInformation, "[ConversionRulesInformation]", ConversionRulesInformation);
	CommonRulesInformation = StrReplace(CommonRulesInformation, "[RegistrationRulesInformation]", RegistrationRulesInformation);
	
EndProcedure

&AtServer
Procedure RulesInformation()
	
	Query = New Query;
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	
	Query.Text = "SELECT
		|	DataExchangeRules.RulesTemplateName AS ConversionRuleTemplateName,
		|	DataExchangeRules.CorrespondentRulesTemplateName AS CorrespondentRulesTemplateName,
		|	DataExchangeRules.ExportDebuggingDataProcessorFileName,
		|	DataExchangeRules.ImportDebuggingDataProcessorFileName,
		|	DataExchangeRules.RulesFileName AS ConversionRuleFileName,
		|	DataExchangeRules.ExchangeProtocolFileName,
		|	DataExchangeRules.RulesInformation AS ConversionRulesInformation,
		|	DataExchangeRules.RulesSource AS ConversionRuleSource,
		|	DataExchangeRules.NotStopByMistake,
		|	DataExchangeRules.DebugMode,
		|	DataExchangeRules.ExportDebugMode,
		|	DataExchangeRules.ImportDebugMode,
		|	DataExchangeRules.DataExchangeLoggingMode
		|FROM
		|	InformationRegister.DataExchangeRules AS DataExchangeRules
		|WHERE
		|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
		|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsConversionRules)";
		
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
	Query.Text = "SELECT
		|	DataExchangeRules.RulesTemplateName AS RegistrationRuleTemplateName,
		|	DataExchangeRules.RulesFileName AS RegistrationRuleFileName,
		|	DataExchangeRules.RulesInformation AS RegistrationRulesInformation,
		|	DataExchangeRules.RulesSource AS RegistrationRuleSource
		|FROM
		|	InformationRegister.DataExchangeRules AS DataExchangeRules
		|WHERE
		|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
		|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsRegistrationRules)";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeRuleImport(Val PutFileAddress, Val FileName)
	
	If Not CheckFillingAtClient() Then
		Return;
	EndIf;
	
	If ExternalResourcesAllowed <> True Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("PutFileAddress", PutFileAddress);
		AdditionalParameters.Insert("FileName", FileName);
		ClosingNotification1 = New CallbackDescription("AllowExternalResourceCompletion", ThisObject, AdditionalParameters);
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			Queries = CreateRequestToUseExternalResources();
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification1);
		Else
			RunCallback(ClosingNotification1, DialogReturnCode.OK);
		EndIf;
		Return;
		
	EndIf;
	ExternalResourcesAllowed = False;
	
	PerformRuleImport(PutFileAddress, FileName);
	
EndProcedure

&AtClient
Procedure AllowExternalResourceCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		ExternalResourcesAllowed = True;
		BeforeRuleImport(AdditionalParameters.PutFileAddress, AdditionalParameters.FileName);
	EndIf;
	
EndProcedure

&AtServer
Function CreateRequestToUseExternalResources()
	
	PermissionsRequests = New Array;
	RegistrationRulesFromFile = (RulesSource <> "StandardRulesFromConfiguration");
	RecordStructure = New Structure;
	RecordStructure.Insert("ExchangePlanName", ExchangePlanName);
	RecordStructure.Insert("DebugMode", DebugMode);
	RecordStructure.Insert("ExportDebugMode", ExportDebugMode);
	RecordStructure.Insert("ImportDebugMode", ImportDebugMode);
	RecordStructure.Insert("DataExchangeLoggingMode", DataExchangeLoggingMode);
	RecordStructure.Insert("ExportDebuggingDataProcessorFileName", ExportDebuggingDataProcessorFileName);
	RecordStructure.Insert("ImportDebuggingDataProcessorFileName", ImportDebuggingDataProcessorFileName);
	RecordStructure.Insert("ExchangeProtocolFileName", ExchangeProtocolFileName);
	InformationRegisters.DataExchangeRules.RequestToUseExternalResources(PermissionsRequests, RecordStructure, True, RegistrationRulesFromFile);
	Return PermissionsRequests;
	
EndFunction

&AtClient
// Returns a formatted string based on a template (for example, "%1 moved to %2").
//
// Parameters:
//     Template - String - Generation template.
//     String1 - String
//             - FormattedString
//             - Picture
//             - Undefined - Value to set.
//     String2 - String
//             - FormattedString
//             - Picture
//             - Undefined - Value to set.
//
// Returns:
//     FormattedString - Generated from input parameters.
//
Function SubstituteParametersInFormattedString(Val Template,
	Val String1 = Undefined, Val String2 = Undefined)
	
	StringParts1 = New Array;
	AllowedTypes = New TypeDescription("String, FormattedString, Picture");
	Begin = 1;
	
	While True Do
		
		Particle = Mid(Template, Begin);
		
		Position = StrFind(Particle, "%");
		
		If Position = 0 Then
			
			StringParts1.Add(Particle);
			
			Break;
			
		EndIf;
		
		Next = Mid(Particle, Position + 1, 1);
		
		If Next = "1" Then
			
			Value = String1;
			
		ElsIf Next = "2" Then
			
			Value = String2;
			
		ElsIf Next = "%" Then
			
			Value = "%";
			
		Else
			
			Value = Undefined;
			
			Position  = Position - 1;
			
		EndIf;
		
		StringParts1.Add(Left(Particle, Position - 1));
		
		If Value <> Undefined Then
			
			Value = AllowedTypes.AdjustValue(Value);
			
			If Value <> Undefined Then
				
				StringParts1.Add( Value );
				
			EndIf;
			
		EndIf;
		
		Begin = Begin + Position + 1;
		
	EndDo;
	
	Return New FormattedString(StringParts1);
	
EndFunction

// Determining the "My Documents" directory of the current Windows user.
//
&AtClient
Function AppDataDirectory()
	
#If MobileClient Then
	Return "";
#Else
	Application = New COMObject("Shell.Application");
	Directory = Application.Namespace(26);
	Result = Directory.Self.Path;
	Return CommonClientServer.AddLastPathSeparator(Result);
#EndIf

EndFunction

&AtClient
Procedure AfterConversionRulesCheckForCompatibility(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Result.Value = "Continue" Then
		
		ErrorDescription = True;
		PerformRuleImport(AdditionalParameters.PutFileAddress, AdditionalParameters.FileName, ErrorDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseRuleImportForm(Result, AdditionalParameters) Export
	If Result <> Undefined And Result.Value = "Use" Then
		Close();
	EndIf;
EndProcedure

&AtServer
Procedure ImportDebugModeSettingsAtServer()
	
	BeginTransaction();
	Try
	    Block = New DataLock;
	    LockItem = Block.Add("InformationRegister.DataExchangeRules");
	    LockItem.SetValue("ExchangePlanName", ExchangePlanName);
		LockItem.SetValue("RulesKind",      Enums.DataExchangeRulesTypes.ObjectsConversionRules);
	    Block.Lock();
	    
		ConversionRulesRecords = InformationRegisters.DataExchangeRules.CreateRecordSet();
		ConversionRulesRecords.Filter.RulesKind.Set(Enums.DataExchangeRulesTypes.ObjectsConversionRules);
		ConversionRulesRecords.Filter.ExchangePlanName.Set(ExchangePlanName);
		
		ConversionRulesRecords.Read();
		If ConversionRulesRecords.Count() > 0 Then
			RulesRecord = ConversionRulesRecords[0];
			RulesRecord.ExportDebuggingDataProcessorFileName = ExportDebuggingDataProcessorFileName;
			RulesRecord.ImportDebuggingDataProcessorFileName = ImportDebuggingDataProcessorFileName;
			RulesRecord.ExchangeProtocolFileName = ExchangeProtocolFileName;
			RulesRecord.NotStopByMistake = NotStopByMistake;
			RulesRecord.DebugMode = DebugMode;
			RulesRecord.ExportDebugMode = ExportDebugMode;
			RulesRecord.ImportDebugMode = ImportDebugMode;
			RulesRecord.DataExchangeLoggingMode = DataExchangeLoggingMode;
			
			ConversionRulesRecords.Write(True);
		EndIf;

	    CommitTransaction();
	Except
	    RollbackTransaction();
	    Raise;
	EndTry;
	
EndProcedure

#EndRegion