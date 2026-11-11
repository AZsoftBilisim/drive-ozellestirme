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
	
	If Not ValueIsFilled(Parameters.Key) Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	UpdateExchangePlanChoiceList();
	
	UpdateRuleTemplateChoiceList();
	
	UpdateRuleInfo();
	
	RulesSource = ?(Record.RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate,
		"StandardRulesFromConfiguration", "RuelsImportedFromFile");
	Items.ExchangePlanGroup.Visible = IsBlankString(Record.ExchangePlanName);
	
	Items.DebugGroup.Enabled = (RulesSource = "RuelsImportedFromFile");
	Items.DebugSettingsGroup.Enabled = Record.DebugMode;
	Items.RulesSourceFile.Enabled = (RulesSource = "RuelsImportedFromFile");
	
	DataExchangeRulesImportEventLogEvent = DataExchangeServer.DataExchangeRulesImportEventLogEvent();
	
EndProcedure

&AtClient
Function CheckFillingAtClient()
	
	HasBlankFields = False;
	
	If RulesSource = "RuelsImportedFromFile" And IsBlankString(Record.RulesFileName) Then
		
		MessageString = NStr("vi = 'Chưa đặt tệp quy tắc trao đổi.';
							|ru = 'Не задан файл правил обмена.';
							|en = 'Exchange rule file is not specified.'; fa = 'Exchange rule file is not specified.';
							|it = 'Nessun file delle regole di scambio specificato.';
							|pl = 'Nie określono pliku zasad wymiany.';
							|tr = 'Değişim kuralları dosyası belirlenmedi.'");
		CommonClient.MessageToUser(MessageString,,,, HasBlankFields);
		
	EndIf;
	
	If Record.DebugMode Then
		
		If Record.ExportDebugMode Then
			
			FileNameStructure = CommonClientServer.ParseFullFileName(Record.ExportDebuggingDataProcessorFileName);
			FileName = FileNameStructure.BaseName;
			
			If Not ValueIsFilled(FileName) Then
				
				MessageString = NStr("vi = 'Chưa đặt tên tệp bộ xử lý ngoài.';
									|ru = 'Не задано имя файла внешней обработки.';
									|en = 'External data processor file name is not specified'; fa = 'External data processor file name is not specified';
									|it = 'Il nome del file di elaborazione esterno non è specificato.';
									|pl = 'Nazwa zewnętrznego pliku przetwarzania nie została określona.';
									|tr = 'Harici veri işlemci dosyasının adı belirtilmemiş.'");
				CommonClient.MessageToUser(MessageString,, "Record.ExportDebuggingDataProcessorFileName",, HasBlankFields);
				
			EndIf;
			
		EndIf;
		
		If Record.ImportDebugMode Then
			
			FileNameStructure = CommonClientServer.ParseFullFileName(Record.ImportDebuggingDataProcessorFileName);
			FileName = FileNameStructure.BaseName;
			
			If Not ValueIsFilled(FileName) Then
				
				MessageString = NStr("vi = 'Chưa đặt tên tệp bộ xử lý ngoài.';
									|ru = 'Не задано имя файла внешней обработки.';
									|en = 'External data processor file name is not specified'; fa = 'External data processor file name is not specified';
									|it = 'Il nome del file di elaborazione esterno non è specificato.';
									|pl = 'Nazwa zewnętrznego pliku przetwarzania nie została określona.';
									|tr = 'Harici veri işlemci dosyasının adı belirtilmemiş.'");
				CommonClient.MessageToUser(MessageString,, "Record.ImportDebuggingDataProcessorFileName",, HasBlankFields);
				
			EndIf;
			
		EndIf;
		
		If Record.DataExchangeLoggingMode Then
			
			FileNameStructure = CommonClientServer.ParseFullFileName(Record.ExchangeProtocolFileName);
			FileName = FileNameStructure.BaseName;
			
			If Not ValueIsFilled(FileName) Then
				
				MessageString = NStr("vi = 'Chưa đặt tên tệp giao thức trao đổi.';
									|ru = 'Не задано имя файла протокола обмена.';
									|en = 'Exchange protocol file name is not specified.'; fa = 'Exchange protocol file name is not specified.';
									|it = 'Il nome del file del protocollo di scambio non è specificato.';
									|pl = 'Nazwa pliku protokołu wymiany nie została określona.';
									|tr = 'Alışveriş protokolü dosya adı belirtilmemiş.'");
				CommonClient.MessageToUser(MessageString,, "Record.ExchangeProtocolFileName",, HasBlankFields);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Not HasBlankFields;
	
EndFunction

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If WriteParameters.Property("WriteAndClose") Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExchangePlanNameOnChange(Item)
	
	Record.RulesTemplateName = "";
	
	// Server call.
	UpdateRuleTemplateChoiceList();
	
EndProcedure

&AtClient
Procedure RulesSourceOnChange(Item)
	
	Items.DebugGroup.Enabled = (RulesSource = "RuelsImportedFromFile");
	Items.RulesSourceFile.Enabled = (RulesSource = "RuelsImportedFromFile");
	
	If RulesSource = "StandardRulesFromConfiguration" Then
		
		Record.DebugMode = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableExportDebugOnChange(Item)
	
	Items.ExternalDataProcessorForExportDebug.Enabled = Record.ExportDebugMode;
	
EndProcedure

&AtClient
Procedure ExternalDataProcessorForExportDebugStartChoice(Item, ChoiceData, StandardProcessing)
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter", NStr("vi = 'Bộ xử lý ngoài (*.epf)';
										|ru = 'Внешняя обработка (*.epf)';
										|en = 'External data processor (*.epf)'; fa = 'External data processor (*.epf)';
										|it = 'Elaborazione esterna (*.epf)';
										|pl = 'Przetwarzanie zewnętrzne (*.epf)';
										|tr = 'Harici işleme (*.epf)'") + "|*.epf" );
	
	DataExchangeClient.FileSelectionHandler(Record, "ExportDebuggingDataProcessorFileName", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure ExternalDataProcessorForImportDebugStartChoice(Item, ChoiceData, StandardProcessing)
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter", NStr("vi = 'Bộ xử lý ngoài (*.epf)';
										|ru = 'Внешняя обработка (*.epf)';
										|en = 'External data processor (*.epf)'; fa = 'External data processor (*.epf)';
										|it = 'Elaborazione esterna (*.epf)';
										|pl = 'Przetwarzanie zewnętrzne (*.epf)';
										|tr = 'Harici işleme (*.epf)'") + "|*.epf" );
	
	StandardProcessing = False;
	DataExchangeClient.FileSelectionHandler(Record, "ImportDebuggingDataProcessorFileName", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure EnableImportDebugOnChange(Item)
	
	Items.ExternalDataProcessorForImportDebug.Enabled = Record.ImportDebugMode;
	
EndProcedure

&AtClient
Procedure EnableDataExchangeLoggingOnChange(Item)
	
	Items.ExchangeProtocolFile.Enabled = Record.DataExchangeLoggingMode;
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter", NStr("vi = 'Văn bản thuần (*.txt)';
										|ru = 'Текстовый документ (*.txt)';
										|en = 'Text document (*.txt)'; fa = 'Text document (*.txt)';
										|it = 'Documento di testo (*.txt)';
										|pl = 'Dokument tekstowy (*.txt)';
										|tr = 'Metin belgesi (*.txt)'")+ "|*.txt" );
	DialogSettings.Insert("CheckFileExist", False);
	
	StandardProcessing = False;
	DataExchangeClient.FileSelectionHandler(Record, "ExchangeProtocolFileName", StandardProcessing, DialogSettings);
	
EndProcedure

&AtClient
Procedure ExchangeProtocolFileOpening(Item, StandardProcessing)
	
	DataExchangeClient.FileOrDirectoryOpenHandler(Record, "ExchangeProtocolFileName", StandardProcessing);
	
EndProcedure

&AtClient
Procedure RulesTemplateNameOnChange(Item)
	Record.CorrespondentRulesTemplateName = Record.RulesTemplateName + "Correspondent";
EndProcedure

&AtClient
Procedure EnableDebuggingOnChange(Item)
	
	Items.DebugSettingsGroup.Enabled = Record.DebugMode;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportRules(Command)
	
	// Importing from file on the client
	NameParts = CommonClientServer.ParseFullFileName(Record.RulesFileName);
	
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
	
	NameParts = CommonClientServer.ParseFullFileName(Record.RulesFileName);

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

	If Not CheckFillingAtClient() Then
		Cancel = True;
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteAndClose");
	AllowExternalResource(WriteParameters)
	
EndProcedure

&AtClient
Procedure WriteRules(Command)

	If Not CheckFillingAtClient() Then
		Cancel = True;
	EndIf;
	
	WriteParameters = New Structure;
	AllowExternalResource(WriteParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateExchangePlanChoiceList()
	
	ExchangePlansList = DataExchangeCached.SSLExchangePlansList();
	
	FillList(ExchangePlansList, Items.ExchangePlanName.ChoiceList);
	
EndProcedure

&AtServer
Procedure UpdateRuleTemplateChoiceList()
	
	If IsBlankString(Record.ExchangePlanName) Then
		
		Items.MainGroup2.Title = NStr("vi = 'Quy tắc chuyển đổi';
										|ru = 'Правила конвертации';
										|en = 'Conversion rules'; fa = 'Conversion rules';
										|it = 'Regole di conversione';
										|pl = 'Zasady konwersji';
										|tr = 'Dönüşüm kuralları'");
		
	Else
		
		Items.MainGroup2.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.MainGroup2.Title, Metadata.ExchangePlans[Record.ExchangePlanName].Synonym);
		
	EndIf;
	
	TemplatesList = DataExchangeCached.ConversionRulesForExchangePlanFromConfiguration(Record.ExchangePlanName);
	
	ChoiceList = Items.RulesTemplateName.ChoiceList;
	ChoiceList.Clear();
	
	FillList(TemplatesList, ChoiceList);
	
	Items.SourceConfigurationTemplate.CurrentPage = ?(TemplatesList.Count() = 1,
		Items.SingleTemplatePage, Items.SeveralTemplatesPage);
	
EndProcedure

&AtServer
Procedure FillList(SourceList, DestinationList)
	
	For Each Item In SourceList Do
		
		FillPropertyValues(DestinationList.Add(), Item);
		
	EndDo;
	
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
	
	PerformRuleImport(PutFileAddress, NameParts.Name, Lower(NameParts.Extension) = ".zip");
	
EndProcedure

&AtClient
Procedure PerformRuleImport(Val PutFileAddress, Val FileName, Val IsArchive)
	Cancel = False;
	
	ImportRulesAtServer(Cancel, PutFileAddress, FileName, IsArchive);
	
	If Not Cancel Then
		ShowUserNotification(,, NStr("vi = 'Đã kết nhập thành công quy tắc vào cơ sở thông tin.';
									|ru = 'Правила успешно загружены в информационную базу.';
									|en = 'The rules are imported to the infobase.'; fa = 'The rules are imported to the infobase.';
									|it = 'Le regole sono state scaricate correttamente nel database.';
									|pl = 'Reguły pomyślnie wczytane do bazy informacyjnej.';
									|tr = 'Kurallar, infobase''e başarıyla aktarıldı.'"));
		Return;
	EndIf;
	
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
Procedure ImportRulesAtServer(Cancel, TempStorageAddress, RulesFileName, IsArchive)
	
	Record.RulesSource = ?(RulesSource = "StandardRulesFromConfiguration",
		Enums.DataExchangeRulesSources.ConfigurationTemplate, Enums.DataExchangeRulesSources.File);
	
	Object = FormAttributeToValue("Record");
	
	InformationRegisters.DataExchangeRules.ImportRules(Cancel, Object, TempStorageAddress, RulesFileName, IsArchive);
	
	If Not Cancel Then
		
		Object.Write();
		
		Modified = False;
		
		// Open session cache for the registration mechanism has become obsolete.
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
		RefreshReusableValues();
	EndIf;
	
	ValueToFormAttribute(Object, "Record");
	
	UpdateRuleInfo();
	
EndProcedure

&AtServer
Function GetRuleArchiveTempStorageAddressAtServer()
	
	// Create the temporary directory at the server and generate file paths.
	TempDirectoryName = GetTempFileName("");
	CreateDirectory(TempDirectoryName);
	PathToFile = CommonClientServer.AddLastPathSeparator(TempDirectoryName) + "ExchangeRules";
	CorrespondentFilePath = CommonClientServer.AddLastPathSeparator(TempDirectoryName) + "CorrespondentExchangeRules";
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataExchangeRules.XMLRules,
	|	DataExchangeRules.XMLCorrespondentRules
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesKind = &RulesKind";
	Query.SetParameter("ExchangePlanName", Record.ExchangePlanName); 
	Query.SetParameter("RulesKind", Record.RulesKind);
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
		Selection.Next();
		
		// Get, save to, and archive the rules file in a temporary directory.
		RuleBinaryData = Selection.XMLRules.Get(); // BinaryData
		RuleBinaryData.Write(PathToFile + ".xml");
		
		CorrespondentRulesBinaryData = Selection.XMLCorrespondentRules.Get(); // BinaryData
		CorrespondentRulesBinaryData.Write(CorrespondentFilePath + ".xml");
		
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
	
	If Record.RulesSource = Enums.DataExchangeRulesSources.File Then
		
		RulesInformation = NStr("vi = 'Việc sử dụng quy tắc được kết nhập từ tệp,
		|có thể dẫn đến lỗi khi chuyển sang phiên bản mới của chương trình.
		|
		|[RulesInformation]';
		|ru = 'Использование правил, загруженных из файла,
		|может привести к ошибкам при переходе на новую версию программы.
		|
		|[RulesInformation]';
		|en = 'Using rules imported from the file
		|might cause errors when migrating to a new version of the application.
		|
		|[RulesInformation]'; fa = 'Using rules imported from the file
		|might cause errors when migrating to a new version of the application.
		|
		|[RulesInformation]';
		|it = 'L''utilizzo delle regole scaricate da un file 
		| può causare errori durante l''aggiornamento a una nuova versione del programma.
		|
		|[RulesInformation]';
		|pl = 'Używanie reguł, pobranych z pliku,
		|może prowadzić do błędów podczas aktualizacji do nowej wersji programu.
		|
		|[RulesInformation]';
		|tr = 'Bir dosyadan yüklenen kuralların kullanılması, 
		|uygulamanın yeni bir sürümüne geçilirken hatalara yol açabilir.
		|
		|[RulesInformation]'");
		
		RulesInformation = StrReplace(RulesInformation, "[RulesInformation]", Record.RulesInformation);
		
	Else
		
		RulesInformation = Record.RulesInformation;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AllowExternalResource(WriteParameters)
	
	ClosingNotification1 = New CallbackDescription("AllowExternalResourceCompletion", ThisObject, WriteParameters);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Record);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification1);
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtClient
Procedure AllowExternalResourceCompletion(Result, WriteParameters) Export
	
	If Result = DialogReturnCode.OK Then
				
		If RulesSource = "StandardRulesFromConfiguration" Then
			// From configuration.
			PerformRuleImport(Undefined, "", False);
		EndIf;
		
		Write(WriteParameters);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CreateRequestToUseExternalResources(Val Record)
	
	PermissionsRequests = New Array;
	RegistrationRulesFromFile = InformationRegisters.DataExchangeRules.RegistrationRulesFromFile(Record.ExchangePlanName);
	InformationRegisters.DataExchangeRules.RequestToUseExternalResources(PermissionsRequests, Record, True, RegistrationRulesFromFile);
	Return PermissionsRequests;
	
EndFunction


#EndRegion