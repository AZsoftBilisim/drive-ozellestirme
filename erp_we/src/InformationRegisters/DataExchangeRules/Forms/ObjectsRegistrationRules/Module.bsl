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
	
	UpdateRuleSource();
	
	DataExchangeRulesImportEventLogEvent = DataExchangeServer.DataExchangeRulesImportEventLogEvent();
	
	ConfiguringFormElements();
	
EndProcedure

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
	
	If RulesSource = PredefinedValue("Enum.DataExchangeRulesSources.ConfigurationTemplate") Then
		Record.DebugMode = False;
	EndIf;
	
	Items.RegistrationManagerName.Enabled = 
		RulesSource = PredefinedValue("Enum.DataExchangeRulesSources.CustomManager");
		
	Items.FormSaveRegistrationRulesToFile.Enabled = Record.RulesAreImported;
	
	UpdateInformationAboutUnwrittenRules();
	
EndProcedure

&AtClient
Procedure RegistrationManagerNameOnChange(Item)
	
	UpdateInformationAboutUnwrittenRules();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportRules(Command)
	
	ClearMessages();
	
	// Importing from file on the client
	NameParts = CommonClientServer.ParseFullFileName(Record.RulesFileName);
	
	DialogParameters = New Structure;
	DialogParameters.Insert("Title", NStr("vi = 'Hãy chỉ ra tệp mà từ đó quy tắc kết nhập';
											|ru = 'Укажите, из какого файла загрузить правила';
											|en = 'Select a file to import rules from'; fa = 'Select a file to import rules from';
											|it = 'Indicare da quale file scaricare le regole';
											|pl = 'Określ, z którego pliku chcesz pobrać reguły';
											|tr = 'Kuralları içe aktarmak için bir dosya belirtin.'"));
	DialogParameters.Insert("Filter",
		  NStr("vi = 'Tệp quy tắc ghi nhận (*.xml)';
				|ru = 'Файлы правил регистрации (*.xml)';
				|en = 'Registration rule files (*.xml)'; fa = 'Registration rule files (*.xml)';
				|it = 'File delle regole di registrazione (*.xml)';
				|pl = 'Pliki reguł rejestracji (*.xml)';
				|tr = 'Kayıt kural dosyaları (* .xml)'") + "|*.xml|"
		+ NStr("vi = 'Tệp nén ZIP (*.zip)';
				|ru = 'Архивы ZIP (*.zip)';
				|en = 'ZIP archive (*.zip)'; fa = 'ZIP archive (*.zip)';
				|it = 'Archivi ZIP (*.zip)';
				|pl = 'Archiwa ZIP (*.zip)';
				|tr = 'ZIP arşivleri (*.zip)'")   + "|*.zip");
	
	DialogParameters.Insert("FullFileName", NameParts.FullName);
	DialogParameters.Insert("FilterIndex", ?( Lower(NameParts.Extension) = ".zip", 1, 0) ); 
	
	Notification = New CallbackDescription("ImportRulesCompletion", ThisObject);
	DataExchangeClient.SelectAndSendFileToServer(Notification, DialogParameters, UUID);
EndProcedure

&AtClient
Procedure UnloadRules(Command)
	
	If Not Record.RulesAreImported Then
		
		MessageText = NStr("vi = 'Chưa kết nhập quy tắc ghi nhận';
							|ru = 'Правила регистрации незагружены';
							|en = 'Registration rules are not imported'; fa = 'Registration rules are not imported';
							|it = 'Regole di registrazione non scaricate';
							|pl = 'Registration rules are not imported';
							|tr = 'Kayıt kuralları yüklenmedi'");
		CommonClient.MessageToUser(MessageText);
		Return;
		
	EndIf;
	
	NameParts = CommonClientServer.ParseFullFileName(Record.RulesFileName);
	
	StorageAddress = GetURLAtServer();
	NameFilter = NStr("vi = 'Tệp quy tắc (*.xml)';
						|ru = 'Файлы правил (*.xml)';
						|en = 'Rule files (*.xml)'; fa = 'Rule files (*.xml)';
						|it = 'File delle regole (*.xml)';
						|pl = 'Pliki reguł (*.xml)';
						|tr = 'Kural dosyaları (*.xml)'") + "|*.xml";
	
	If IsBlankString(StorageAddress) Then
		Return;
	EndIf;
	
	If IsBlankString(NameParts.BaseName) Then
		FullFileName = NStr("vi = 'Quy tắc ghi nhận';
							|ru = 'Правила регистрации';
							|en = 'Registration rules'; fa = 'Registration rules';
							|it = 'Regole di registrazione';
							|pl = 'Zasady rejestracji';
							|tr = 'Kayıt Kuralları'");
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
	DialogParameters.Insert("Filter", NameFilter);
	
	FileToReceive = New Structure("Name, Location", FullFileName, StorageAddress);
	
	DataExchangeClient.SelectAndSaveFileAtClient(FileToReceive, DialogParameters);
	
EndProcedure

&AtClient
Procedure SaveRegistrationRulesFromTemplate(Command)
	
	List = Items.RulesTemplateName.ChoiceList;
	
	If List.Count() = 0 Then
		
		Template = NStr("vi = 'Đối với sơ đồ trao đổi ""%1"" không tìm thấy khuôn in quy tắc ghi nhận nào';
						|ru = 'Для плана обмена ""%1"" не обнаружено ни одного макета правил регистрации';
						|en = 'Cannot find a registration rule template for the ""%1"" exchange plan'; fa = 'Cannot find a registration rule template for the ""%1"" exchange plan';
						|it = 'Per il piano di scambio ""%1"" non è stato rilevato alcun modello di regole di registrazione';
						|pl = 'Cannot find a registration rule template for the ""%1"" exchange plan';
						|tr = '""%1"" değişim planı için hiçbir kayıt kuralları şablonu bulunamadı'", 
			CommonClient.DefaultLanguageCode());
			
		Text = StrTemplate(Template, Record.ExchangePlanName);
		
		CommonClient.MessageToUser(Text);
		
	ElsIf List.Count() = 1 Then
		
		SaveRegistrationRulesFromTemplateCompletion(List[0].Value);
		
	Else
		
		Notification = New CallbackDescription("TemplateSelectionEnds", ThisObject);
		List.ShowChooseItem(Notification, NStr("vi = 'Hãy chọn khuôn in quy tắc ghi nhận';
												|ru = 'Выберите макет правил регистрации';
												|en = 'Select a registration rule template'; fa = 'Select a registration rule template';
												|it = 'Selezionare il modello di regole di registrazione';
												|pl = 'Select a registration rule template';
												|tr = 'Kayıt kuralları şablonu seçin'"));
	
	EndIf;
	
EndProcedure

&AtClient
Procedure TemplateSelectionEnds(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	SaveRegistrationRulesFromTemplateCompletion(Result.Value);
	
EndProcedure

&AtClient
Procedure SaveRegistrationRulesFromTemplateCompletion(TemplateName)
	
	NameParts = CommonClientServer.ParseFullFileName(Record.RulesFileName);
	
	If IsBlankString(NameParts.BaseName) Then
		FullFileName = NStr("vi = 'Quy tắc ghi nhận';
							|ru = 'Правила регистрации';
							|en = 'Registration rules'; fa = 'Registration rules';
							|it = 'Regole di registrazione';
							|pl = 'Zasady rejestracji';
							|tr = 'Kayıt Kuralları'");
	Else
		FullFileName = NameParts.BaseName;
	EndIf;
		
	FileAddress = PrepareFileOnServer(TemplateName);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("vi = 'Hãy chỉ ra tệp mà quy tắc kết xuất vào đó';
										|ru = 'Укажите в какой файл выгрузить правила';
										|en = 'Select a file to export rules to'; fa = 'Select a file to export rules to';
										|it = 'Specifica da quale file caricare le regole';
										|pl = 'Określ, do którego pliku mają być przesłane reguły';
										|tr = 'Kuralların dışa aktarılacağı bir dosya belirtin'");
	SavingParameters.Dialog.Filter = NStr("vi = 'Tệp quy tắc (*.xml)';
											|ru = 'Файлы правил (*.xml)';
											|en = 'Rule files (*.xml)'; fa = 'Rule files (*.xml)';
											|it = 'File delle regole (*.xml)';
											|pl = 'Pliki reguł (*.xml)';
											|tr = 'Kural dosyaları (*.xml)'") + "|*.xml";
	
	FileSystemClient.SaveFile(Undefined, FileAddress, FullFileName, SavingParameters);
	
EndProcedure

&AtServer
Function PrepareFileOnServer(TemplateName)

	TempFileName = GetTempFileName("xml");
	Template = ExchangePlans[Record.ExchangePlanName].GetTemplate(TemplateName);
	Template.Write(TempFileName);
	
	BinaryData = New BinaryData(TempFileName);
	
	DeleteFiles(TempFileName);
	
	Return PutToTempStorage(BinaryData);
		
EndFunction

&AtClient
Procedure WriteAndClose(Command)
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteAndClose");
	AllowExternalResource(WriteParameters);
	
EndProcedure

&AtClient
Procedure WriteRules(Command)
	
	WriteParameters = New Structure;
	AllowExternalResource(WriteParameters)
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowEventLogWhenErrorOccurred(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		Filter = New Structure;
		Filter.Insert("EventLogEvent", DataExchangeRulesImportEventLogEvent);
		OpenForm("DataProcessor.EventLog.Form", Filter, ThisObject, , , , , FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

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
	
	TemplatesList = DataExchangeCached.RegistrationRulesForExchangePlanFromConfiguration(Record.ExchangePlanName);
	
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

&AtServer
Procedure ImportRulesAtServer(Cancel, TempStorageAddress, RulesFileName, IsArchive)
	
	Record.RulesSource = RulesSource;
	
	Object = FormAttributeToValue("Record");
	
	If RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate
		Or RulesSource = Enums.DataExchangeRulesSources.File Then
		
		InformationRegisters.DataExchangeRules.ImportRules(Cancel, Object, TempStorageAddress, RulesFileName, IsArchive);
		
	Else
		
		Object.RulesFileName = "";
		Object.RulesAreRead = Undefined;
		
		If RulesSource = Enums.DataExchangeRulesSources.StandardManager Then
			Object.RegistrationManagerName = DataExchangeCached.RegistrationManagerName(Object.ExchangePlanName);
		EndIf;
			
		Manager = Common.CommonModule(Object.RegistrationManagerName);
		Object.RulesInformation = Manager.RulesInformation();
		
	EndIf;
	
	If Not Cancel Then
		
		Object.Write();
		
		Modified = False;
		
		// Open session cache for the registration mechanism has become obsolete.
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
		RefreshReusableValues();
	EndIf;
	
	ValueToFormAttribute(Object, "Record");
	
	UpdateRuleInfo();
	Items.ExchangePlanGroup.Visible = IsBlankString(Record.ExchangePlanName);
	
EndProcedure

&AtServer
Function GetURLAtServer()
	
	Filter = New Structure;
	Filter.Insert("ExchangePlanName", Record.ExchangePlanName);
	Filter.Insert("RulesKind",      Record.RulesKind);
	
	RecordKey = InformationRegisters.DataExchangeRules.CreateRecordKey(Filter);
	
	Return GetURL(RecordKey, "XMLRules");
	
EndFunction

&AtServer
Procedure UpdateRuleInfo()
	
	If Record.RulesSource = Enums.DataExchangeRulesSources.File Then
		
		StringPattern = NStr("vi = 'Việc sử dụng quy tắc được kết nhập từ tệp,
                             |có thể dẫn đến lỗi khi chuyển sang phiên bản mới của chương trình.
                             |
                             |%1';
                             |ru = 'Использование правил, загруженных из файла,
                             |может привести к ошибкам при переходе на новую версию программы.
                             |
                             |%1';
                             |en = 'Using rules imported from the file
                             |might cause errors when migrating to a new version of the application.
                             |
                             |%1'; fa = 'Using rules imported from the file
                             |might cause errors when migrating to a new version of the application.
                             |
                             |%1';
                             |it = 'L''utilizzo delle regole scaricate da file
                             | può provocare errori di trasferimento alla nuova versione del programma.
                             |
                             |%1';
                             |pl = 'Użycie reguł, wczytanych z pliku,
                             |może prowadzić do błędów podczas aktualizacji do nowej wersji programu.
                             |
                             |%1';
                             |tr = 'Bir dosyadan yüklenen kuralların kullanılması,
                             | uygulamanın yeni bir sürümüne geçilirken hatalara yol açabilir.
                             |
                             |%1'");
			
	ElsIf Record.RulesSource = Enums.DataExchangeRulesSources.CustomManager Then
		
		StringPattern = NStr("vi = 'Việc sử dụng quy tắc từ mô-đun tự tạo,
                             |có thể dẫn đến lỗi khi chuyển sang phiên bản mới của chương trình.
                             |
                             |%1';
                             |ru = 'Использование правил, из пользовательского модуля,
                             |может привести к ошибкам при переходе на новую версию программы.
                             |
                             |%1';
                             |en = 'Using rules imported from a user module
                             |might cause errors when migrating to a new version of the application.
                             |
                             |%1'; fa = 'Using rules imported from a user module
                             |might cause errors when migrating to a new version of the application.
                             |
                             |%1';
                             |it = 'L''utilizzo delle regole dal modulo utente
                             | può provocare errori durante il passaggio alla nuova versione del programma.
                             |
                             |%1';
                             |pl = 'Użycie reguł, z modułu użytkowniczego,
                             |może doprowadzić do błędów podczas przejścia na nową wersję programu.
                             |
                             |%1';
                             |tr = 'Kullanıcı modülden kurallar kullanmak,
                             | programın yeni bir sürümüne geçerken hatalara neden olabilir.
                             |
                             |%1'");	
	Else
		
		StringPattern = "%1";
		
	EndIf;
	
	RulesInformation = StringFunctions.FormattedString(StringPattern, Record.RulesInformation);
	
EndProcedure

&AtServer
Procedure UpdateInformationAboutUnwrittenRules()
	
	If RulesSource = Record.RulesSource
		And (RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate
		Or RulesSource = Enums.DataExchangeRulesSources.File)Then

		UpdateRuleInfo();
	
	ElsIf RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate Then
		
		RulesInformation = NStr("vi = 'Thông tin về quy tắc sẽ khả dụng sau khi ghi lại';
								|ru = 'Информация о правилах будет доступна после записи';
								|en = 'Save changes to view rule details'; fa = 'Save changes to view rule details';
								|it = 'Le informazioni sulle regole saranno disponibili dopo la registrazione';
								|pl = 'Informacje o regułach będą dostępne po zapisywaniu';
								|tr = 'Kurallar hakkında bilgi kayıttan sonra sunulacaktır'");
		
	ElsIf RulesSource = Enums.DataExchangeRulesSources.File Then
		
		RulesInformation = NStr("vi = 'Thông tin về quy tắc sẽ khả dụng sau khi kết nhập từ tệp';
								|ru = 'Информация о правилах будет доступна после загрузки из файла';
								|en = 'Finish importing to view rule details'; fa = 'Finish importing to view rule details';
								|it = 'Le informazioni sulle regole saranno disponibili dopo il download da file';
								|pl = 'Informacje o regułach będą dostępne po wczytywaniu z pliku';
								|tr = 'Kurallarla ilgili bilgiler, bir dosyadan yüklendikten sonra mevcut olacaktır'");
		
	Else
		
		If RulesSource = Enums.DataExchangeRulesSources.StandardManager Then
			
			RegistrationManagerName = DataExchangeCached.RegistrationManagerName(Record.ExchangePlanName);	
			StringPattern = "%1";
			
		ElsIf RulesSource = Enums.DataExchangeRulesSources.CustomManager Then
			
			RegistrationManagerName = Record.RegistrationManagerName;
			StringPattern = NStr("vi = 'Việc sử dụng quy tắc từ mô-đun tự tạo,
									|có thể dẫn đến lỗi khi chuyển sang phiên bản mới của chương trình.
									|
									|%1';
									|ru = 'Использование правил, из пользовательского модуля,
									|может привести к ошибкам при переходе на новую версию программы.
									|
									|%1';
									|en = 'Using rules imported from a user module
									|might cause errors when migrating to a new version of the application.
									|
									|%1'; fa = 'Using rules imported from a user module
									|might cause errors when migrating to a new version of the application.
									|
									|%1';
									|it = 'L''utilizzo delle regole dal modulo utente
									| può provocare errori durante il passaggio alla nuova versione del programma.
									|
									|%1';
									|pl = 'Użycie reguł, z modułu użytkowniczego,
									|może doprowadzić do błędów podczas przejścia na nową wersję programu.
									|
									|%1';
									|tr = 'Kullanıcı modülden kurallar kullanmak,
									| programın yeni bir sürümüne geçerken hatalara neden olabilir.
									|
									|%1'");
			
		EndIf;	
		
		Try
			
			Manager = Common.CommonModule(RegistrationManagerName);
			RulesInformation = StringFunctions.FormattedString(StringPattern, Manager.RulesInformation());
			
		Except
			
			MessageText = NStr("vi = 'Khi nhận thông tin về quy tắc ghi nhận, đã xảy ra lỗi:
                                   |%1';
                                   |ru = 'При получении информации о правилах регистрации произошла ошибка:
                                   |%1';
                                   |en = 'Error getting registration rules details:
                                   |%1'; fa = 'Error getting registration rules details:
                                   |%1';
                                   |it = 'Durante la ricezione delle informazioni sulle regole di registrazione si è verificato un errore:
                                   |%1';
                                   |pl = 'Podczas otrzymania informacji o regułach rejestracji wystąpił błąd:
                                   |%1';
                                   |tr = 'Kayıt kuralları hakkında bilgi alınırken bir hata oluştu:
                                   |%1'");
			RulesInformation = StringFunctions.FormattedString(MessageText, ErrorInfo().Description);
			
		EndTry;
		
	EndIf;
		
EndProcedure	
	
&AtServer
Procedure UpdateRuleSource()
	
	RulesSource = Record.RulesSource;
	
EndProcedure

&AtServer
Procedure ConfiguringFormElements()

	Items.ExchangePlanGroup.Visible = IsBlankString(Record.ExchangePlanName);
	
	If DataExchangeCached.RulesForRegisteringInManager(Record.ExchangePlanName) Then
		
		Items.StandardRulesGroup.Visible = False;
		Items.RegistrationManagerName.Enabled = RulesSource = Enums.DataExchangeRulesSources.CustomManager;
		Items.FormSaveRegistrationRulesToFile.Enabled = Record.RulesAreImported;
		Items.RulesFromFileActionsGroup.Visible = False;
		Items.ActionGroupWithRulesFromFileManager.Visible = True;
		Items.FormSaveRegistrationRulesToFile.Visible = False;
		Items.FormSaveRegistrationRulesFromTemplate.Visible = True;
		
		NameOfTypicalRegistrationManager = DataExchangeCached.RegistrationManagerName(Record.ExchangePlanName);
		
	Else
		
		Items.GroupRulesManagerTypical.Visible = False;
		Items.GroupRulesManager.Visible = False;
		Items.RulesFromFileActionsGroup.Visible = True;
		Items.ActionGroupWithRulesFromFileManager.Visible = False;
		Items.FormSaveRegistrationRulesFromTemplate.Visible = False;
		
	EndIf;

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
Procedure ImportRulesCompletion(Val PutFilesResult, Val AdditionalParameters) Export
	
	PutFileAddress = PutFilesResult.Location;
	ErrorText           = PutFilesResult.ErrorDescription;
	
	If IsBlankString(ErrorText) And IsBlankString(PutFileAddress) Then
		ErrorText = NStr("vi = 'Lỗi truyền tệp đến máy chủ';
						|ru = 'Ошибка передачи файла на сервер';
						|en = 'An error occurred when transferring the file to the server'; fa = 'An error occurred when transferring the file to the server';
						|it = 'Errore di trasferimento file sul server';
						|pl = 'Błąd przesyłania pliku na serwer';
						|tr = 'Dosya sunucuya aktarılırken bir hata oluştu'");
	EndIf;
	
	If Not IsBlankString(ErrorText) Then
		CommonClient.MessageToUser(ErrorText);
		Return;
	EndIf;
	
	RulesSource = PredefinedValue("Enum.DataExchangeRulesSources.File");
	
	// The file is successfully transferred, importing the file to the server.
	NameParts = CommonClientServer.ParseFullFileName(PutFilesResult.Name);
	
	PerformRuleImport(PutFileAddress, NameParts.Name, Lower(NameParts.Extension) = ".zip");
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
		
		If RulesSource = PredefinedValue("Enum.DataExchangeRulesSources.ConfigurationTemplate") Then
			// From configuration.
			PerformRuleImport(Undefined, "", False);
		ElsIf RulesSource = PredefinedValue("Enum.DataExchangeRulesSources.StandardManager")
			Or RulesSource = PredefinedValue("Enum.DataExchangeRulesSources.CustomManager") Then
			Record.RulesSource = RulesSource;
			Record.RulesFileName = "";
		EndIf;
		
		Write(WriteParameters);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CreateRequestToUseExternalResources(Val Record)
	
	PermissionsRequests = New Array;
	ConversionRulesFromFile = InformationRegisters.DataExchangeRules.ConversionRulesFromFile(Record.ExchangePlanName);
	HasConvertionRules = (ConversionRulesFromFile <> Undefined);
	RegistrationRulesFromFile = (Record.RulesSource = Enums.DataExchangeRulesSources.File);
	InformationRegisters.DataExchangeRules.RequestToUseExternalResources(PermissionsRequests,
		?(HasConvertionRules, ConversionRulesFromFile, Record), HasConvertionRules, RegistrationRulesFromFile);
	Return PermissionsRequests;
	
EndFunction


#EndRegion
